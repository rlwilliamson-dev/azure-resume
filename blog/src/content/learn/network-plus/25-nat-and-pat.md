---
title: "NAT and PAT"
description: "Fifty machines behind one public address and everything works. What is actually being rewritten, the table that keeps the conversations apart, why incoming connections are the hard direction, and the reasons NAT is not the security control people believe it is."
deck: "Fifty machines, one public address, and it all works"
track: "network-plus"
level: "working"
order: 260
objectives:
  - "Say what NAT rewrites and where in the packet"
  - "Explain how one public address serves many private ones"
  - "Tell source translation from destination translation and say what each is for"
  - "Explain why inbound connections need explicit configuration"
  - "Say why NAT is not a security control"
prerequisites: ["address-classes-private-ranges-and-apipa"]
tags: ["network-plus", "networking", "routing", "nat"]
updated: 2026-08-10
draft: false
examObjectives:
  - exam: "n10-009"
    domain: "2.0"
    objective: "2.1"
sources:
  - title: "RFC 3022, Traditional IP Network Address Translator"
    url: "https://www.rfc-editor.org/rfc/rfc3022"
    publisher: "IETF"
    accessed: 2026-08-10
    tier: 1
  - title: "RFC 2663, IP Network Address Translator Terminology and Considerations"
    url: "https://www.rfc-editor.org/rfc/rfc2663"
    publisher: "IETF"
    accessed: 2026-08-10
    tier: 1
  - title: "RFC 6598, IANA-Reserved IPv4 Prefix for Shared Address Space"
    url: "https://www.rfc-editor.org/rfc/rfc6598"
    publisher: "IETF"
    accessed: 2026-08-10
    tier: 1
  - title: "nft(8)"
    url: "https://www.netfilter.org/projects/nftables/manpage.html"
    publisher: "netfilter project"
    accessed: 2026-08-10
    tier: 1
symptoms:
  - symptom: "An inbound connection to a service behind a router never arrives"
    anchor: "the-hard-direction"
  - symptom: "Many users appear to a remote service as one address"
    anchor: "one-address-many-conversations"
---

> **Before you read.** An office has fifty machines, all with private addresses,
> and one public address from its provider. Every machine reaches the internet
> at the same time and nothing collides.
>
> Topic 07 established that no router on the internet will carry a route to a
> private address, so none of those machines is reachable and none of their
> replies has anywhere to go.
>
> **What makes it work anyway?**

This is the mechanism that let IPv4 survive its own exhaustion, and it is worth
understanding precisely rather than as "it shares an address", because almost
everything people believe about its security properties is wrong.

### Some words you will need

<dl class="terms">
<dt>NAT</dt>
<dd>Network address translation. Rewriting addresses in packets as they cross a boundary.</dd>
<dt>PAT</dt>
<dd>Port address translation. Rewriting the port too, which is what lets many machines share one address.</dd>
<dt>masquerade</dt>
<dd>Source translation onto whatever address the outgoing interface currently has.</dd>
<dt>translation table</dt>
<dd>The record of which inside conversation corresponds to which outside one.</dd>
<dt>port forwarding</dt>
<dd>A rule sending traffic arriving at one outside port to a specific inside machine.</dd>
</dl>

## What breaks without this

**You cannot explain why inbound is different.** Outbound works with no
configuration and inbound needs an explicit rule, and the asymmetry confuses
people until they know what the table is.

**Somebody treats NAT as a firewall.** It has a side effect that resembles one
and provides none of the guarantees, which is a dangerous thing to be wrong about.

**Logs name the wrong machine.** Fifty users behind one address means a remote
service sees one address, and tracing an event back to a person requires
information only the translating device has.

## One address, many conversations

The rewriting itself is simple. A packet leaves an inside machine with a private
source address, the gateway replaces that source address with its own public one,
and sends it on. The reply comes back to the public address, the gateway looks up
which inside machine it belongs to, rewrites the destination, and delivers it.

The question that mechanism does not answer is how the gateway knows which inside
machine a reply belongs to when fifty of them are sharing one address.

<details class="predict">
<summary>Two private hosts ping the same server at the same time. What does the server see, and how does the gateway tell the replies apart?</summary>

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology nat-gateway
# two private hosts, one public address on the gateway
$ ip -n h1 addr show h1eth0 | grep "inet "
    inet 10.0.0.11/24 scope global h1eth0
$ ip -n h2 addr show h2eth0 | grep "inet "
    inet 10.0.0.12/24 scope global h2eth0
$ ip -n nat addr show nat-out | grep "inet "
    inet 203.0.113.1/24 scope global nat-out
# both talk to the same server at the same time
$ (ip netns exec srv timeout 8 tcpdump -i srv-in -n -U icmp > /tmp/srv.txt 2>/dev/null &)
$ sleep 2
$ ip netns exec h1 ping -c 1 203.0.113.9 > /dev/null 2>&1
$ ip netns exec h2 ping -c 1 203.0.113.9 > /dev/null 2>&1
$ sleep 7
# what the server saw
$ cat /tmp/srv.txt
23:39:25.625055 IP 203.0.113.1 > 203.0.113.9: ICMP echo request, id 69, seq 1, length 64
23:39:25.625063 IP 203.0.113.9 > 203.0.113.1: ICMP echo reply, id 69, seq 1, length 64
23:39:25.628663 IP 203.0.113.1 > 203.0.113.9: ICMP echo request, id 71, seq 1, length 64
23:39:25.628670 IP 203.0.113.9 > 203.0.113.1: ICMP echo reply, id 71, seq 1, length 64

# and the table on the gateway that keeps the two apart
$ ip netns exec nat conntrack -L 2>/dev/null | grep icmp
icmp     1 22 src=10.0.0.11 dst=203.0.113.9 type=8 code=0 id=69 src=203.0.113.9 dst=203.0.113.1 type=0 code=0 id=69 mark=0 secctx=system_u:object_r:unlabeled_t:s0 use=1
icmp     1 22 src=10.0.0.12 dst=203.0.113.9 type=8 code=0 id=71 src=203.0.113.9 dst=203.0.113.1 type=0 code=0 id=71 mark=0 secctx=system_u:object_r:unlabeled_t:s0 use=1
```

</details>

The server sees `203.0.113.1` twice, which is the gateway's address. Both hosts
have vanished as far as it is concerned.

What distinguishes them is in the same output: `id 69` and `id 71`. Those are ICMP
identifiers, and the gateway is rewriting them so that each inside conversation
gets a unique one. For TCP and UDP it rewrites the source port instead, which is
where the name port address translation comes from.

**That is the whole trick.** The gateway keeps a table mapping each inside
conversation, identified by inside address and port, to an outside conversation
identified by its own address and a port it chose. A reply arriving for that
outside port is looked up and rewritten back.

<figure class="learn-figure">
<svg viewBox="0 0 720 184" role="img" aria-labelledby="nat-title" style="width:100%;height:auto;">
<title id="nat-title">Two private hosts reaching one server through a gateway, with the translation table that tells their replies apart</title>
<defs>
<marker id="nat-arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse">
<path d="M 0 0 L 10 5 L 0 10 z" fill="currentColor"/>
</marker>
</defs>
<g fill="currentColor">
<rect x="12" y="52" width="126" height="38" rx="3" fill="currentColor" fill-opacity="0.1" stroke="currentColor" stroke-opacity="0.5"/>
<text x="75" y="68" text-anchor="middle" font-size="11">h1</text>
<text x="75" y="83" text-anchor="middle" font-size="10.5" fill-opacity="0.8">10.0.0.11</text>
<rect x="12" y="112" width="126" height="38" rx="3" fill="currentColor" fill-opacity="0.1" stroke="currentColor" stroke-opacity="0.5"/>
<text x="75" y="128" text-anchor="middle" font-size="11">h2</text>
<text x="75" y="143" text-anchor="middle" font-size="10.5" fill-opacity="0.8">10.0.0.12</text>
<rect x="196" y="30" width="330" height="140" rx="4" fill="var(--accent)" fill-opacity="0.07" stroke="var(--accent)" stroke-width="1.8"/>
<text x="361" y="50" text-anchor="middle" font-size="11.5">gateway</text>
<text x="361" y="66" text-anchor="middle" font-size="10.5" fill-opacity="0.8">public address 203.0.113.1</text>
<text x="208" y="92" font-size="10" fill-opacity="0.7">inside conversation</text>
<text x="368" y="92" font-size="10" fill-opacity="0.7">what leaves the gateway</text>
<line x1="208" y1="100" x2="514" y2="100" stroke="currentColor" stroke-opacity="0.3"/>
<text x="208" y="122" font-size="10">10.0.0.11  id 69</text>
<text x="368" y="122" font-size="10">203.0.113.1  id 69</text>
<text x="208" y="146" font-size="10">10.0.0.12  id 71</text>
<text x="368" y="146" font-size="10">203.0.113.1  id 71</text>
<rect x="584" y="78" width="124" height="44" rx="3" fill="currentColor" fill-opacity="0.1" stroke="currentColor" stroke-opacity="0.5"/>
<text x="646" y="96" text-anchor="middle" font-size="11">server</text>
<text x="646" y="112" text-anchor="middle" font-size="10.5" fill-opacity="0.8">203.0.113.9</text>
<g stroke="currentColor" stroke-width="1.6" fill="none" marker-end="url(#nat-arrow)">
<line x1="138" y1="71" x2="190" y2="86"/>
<line x1="138" y1="131" x2="190" y2="114"/>
<line x1="526" y1="100" x2="578" y2="100"/>
</g>
</g>
</svg>
<figcaption>The two table rows are the two lines of conntrack output above, with the destination left out because it is 203.0.113.9 in both. Reading left to right is the outbound rewrite and reading right to left is the inbound one, and the table is the only thing that makes the second direction possible. That is also the uncomfortable part: this is a forwarding device that now has to remember things, and the panel below is about what happens when it forgets or runs out of room. Lose the table and the replies match nothing, which is why restarting a gateway cuts every conversation through it at once.</figcaption>
</figure>

Since a port number is 16 bits, one public address supports tens of thousands of
simultaneous conversations, which is why fifty machines fit behind one address
without noticing.

Strictly, translating only the address is NAT and translating the port as well is
PAT, sometimes called NAT overload. Almost everything anybody calls NAT today is
PAT, because one address per inside machine defeats the purpose.

<details class="deeper">
<summary>If you already work on networks: the table is state, and state runs out</summary>

The translation table is the part that makes NAT work and the part that makes it
a liability, because a stateless forwarding device has just become a stateful one.

Every conversation occupies an entry, and entries persist after the conversation
finishes, because the gateway cannot always tell that it has. TCP has a close it
can watch for, and UDP has nothing at all, so entries are aged out on a timer.
Those timers are long for established TCP, because a connection can be legitimately
idle for hours, and short for UDP.

Three consequences.

**The table is finite and can fill.** A machine opening very many connections,
whether through malware, a misconfigured application or a scan, can exhaust it,
and when it is full new conversations for everybody fail. That is a denial of
service affecting the whole office caused by one machine, with no packet loss and
no link problem to find.

**Idle connections die silently.** A long-lived TCP connection with no traffic can
have its entry aged out, and neither end is told. The next packet arrives at the
gateway with no matching entry and is dropped, so both ends believe the connection
exists and it does not. That is why SSH sessions left overnight are dead in the
morning, and why keepalives exist.

**The gateway is now a single point of failure with memory.** Restart it and every
conversation through it breaks, because the table is gone and the replies coming
back match nothing. Failing over to a second gateway means replicating that state
or accepting the same break.

The counter to look at, when a network is behaving oddly under load and nothing
else explains it, is the number of entries against the maximum. On the topology
behind this page that is `conntrack -L`, and on any real gateway it is a number
somewhere in the interface. Full is not a subtle failure once you know to check.

</details>

## The hard direction

Outbound works with no configuration at all. Inbound does not work at all without
it, and the reason is the table.

A packet arriving from outside, unsolicited, has a destination of the gateway's

<figure class="learn-figure">
<svg viewBox="0 0 720 236" role="img" aria-labelledby="inb-title" style="width:100%;height:auto;">
<title id="inb-title">An outbound packet creating a translation table entry that the reply matches, and an unsolicited inbound packet arriving with no entry to match</title>
<g fill="currentColor">
<text x="14" y="20" font-size="11">the table is built by traffic leaving. nothing builds it on the way in.</text>
<rect x="250" y="44" width="220" height="120" rx="4" fill="var(--accent)" fill-opacity="0.07" stroke="var(--accent)" stroke-width="1.8"/>
<text x="360" y="64" text-anchor="middle" font-size="11.5">the translation table</text>
<text x="262" y="90" font-size="10" fill-opacity="0.7">created by</text>
<text x="262" y="110" font-size="10.5">10.0.0.11 to 203.0.113.9</text>
<text x="262" y="128" font-size="10.5">10.0.0.12 to 203.0.113.9</text>
<text x="262" y="152" font-size="10" fill-opacity="0.7">and nothing else</text>
<g stroke="var(--accent)" stroke-width="2" fill="none">
<path d="M 120 78 H 244"/><path d="M 237 73 l 8 5 l -8 5"/>
</g>
<text x="14" y="74" font-size="10.5">a host inside</text>
<text x="14" y="90" font-size="10" fill-opacity="0.8">sends first</text>
<g stroke="var(--accent)" stroke-width="2" fill="none">
<path d="M 600 100 H 478"/><path d="M 485 95 l -8 5 l 8 5"/>
</g>
<text x="706" y="82" text-anchor="end" font-size="10.5">the reply</text>
<text x="706" y="98" text-anchor="end" font-size="10" fill-opacity="0.8">matches a row</text>
<text x="706" y="114" text-anchor="end" font-size="10" fill="var(--accent)">delivered</text>
<g stroke="var(--red)" stroke-width="2" fill="none"><path d="M 600 148 H 500"/></g>
<path d="M 484 140 l 16 16 M 500 140 l -16 16" stroke="var(--red)" stroke-width="2.2"/>
<text x="706" y="164" text-anchor="end" font-size="10.5" fill="var(--red)">an unsolicited packet</text>
<text x="706" y="180" text-anchor="end" font-size="10" fill="var(--red)">matches nothing</text>
<text x="14" y="200" font-size="10.5">outbound works with no configuration because the packet leaving is what creates the row.</text>
<text x="14" y="216" font-size="10.5" fill-opacity="0.85">inbound has no row to match, so it needs one written by hand. that is port forwarding.</text>
</g></svg>
<figcaption>The asymmetry drawn, because it feels arbitrary until you see where the rows come from. Every entry in that table was created by a packet leaving. The reply matches a row because the row was written on the way out. An unsolicited packet arriving from outside matches nothing, and the gateway has no basis on which to guess which of fifty inside machines it was meant for, so it discards it. Port forwarding is not a security exception. It is the row somebody has to write by hand, because no traffic exists to write it automatically.</figcaption>
</figure>
public address and some port. The gateway looks it up in the translation table and
finds nothing, because no inside machine started a conversation that matches.
There is no rule saying which of the fifty inside machines it should go to, so it
is dropped.

That is not a security decision. It is an absence of information.

Making inbound work means supplying the missing information in advance, which is
port forwarding: a static rule saying traffic arriving on this outside port goes
to this inside address and port. It is destination translation rather than source
translation, and it is the same mechanism pointed the other way.

The exam's terms for the two directions are worth keeping straight. Source NAT
rewrites where a packet came from, which is the outbound case, and it is what
lets many share one address. Destination NAT rewrites where it is going, which is
the inbound case, and it is what port forwarding and many load balancers do.

**Carrier grade NAT is where this gets painful.** Topic 07 introduced the
100.64.0.0/10 range, and a customer behind it has no public address of their own
at all. Port forwarding is not available because the outside address is the
provider's and shared, so hosting anything, or any protocol that needs an inbound
connection, simply does not work.

<details class="deeper">
<summary>If you already work on networks: what NAT breaks, and why it is not a firewall</summary>

Two things worth being precise about, and the second is the one people get wrong
in a way that matters.

**What NAT breaks** is any protocol that carries an address inside its payload.
NAT rewrites headers, and it has no general way to know that bytes deeper in the
packet are also an address. FTP in its active mode tells the server which address
and port to connect back to, and that address is the private one. SIP does the
same for voice. Various peer to peer protocols do too.

The fix was application layer gateways: code in the NAT device that understands
particular protocols, inspects their payloads and rewrites the addresses inside.
That works, it is a layering violation of the kind topic 03's panel described, and
it has been a reliable source of subtle bugs for thirty years. The other fix is
protocols working out their own public address by asking a server on the outside,
which is what STUN does and is how most voice and video now cope.

**Why it is not a firewall** is the important half.

The property people rely on is real: unsolicited inbound traffic is dropped
because there is no table entry for it. That is a side effect of not knowing where
to send something.

What makes it not a security control is what it does not do. It has no policy, so
you cannot express what should be allowed, only what happens to be in the table.
It inspects nothing, so anything an inside machine invites in is delivered
whatever it is, which covers essentially all malware, since it connects outward
first. It fails open in the sense that a port forwarding rule added for
convenience punches a hole with no rules attached to it. And it protects nothing
between inside machines, since they reach each other directly without passing
through it.

The clearest way to see the difference: a firewall denies traffic it has been
told to deny, and NAT drops traffic it cannot place. One is a decision and the
other is ignorance.

IPv6 makes this concrete. Every machine gets a globally routable address and there
is no translation, so the thing people thought was protecting them is gone. What
replaces it is a stateful firewall doing the job explicitly, and networks that were
relying on NAT discover during an IPv6 rollout that they had no inbound policy at
all.

</details>

## Prove it

You have this when you can look at a translation table and match an outside
conversation to the inside machine that started it.

```bash
./blog/scripts/netlab.sh --topo topologies/nat-gateway.sh -- \
  '(ip netns exec srv timeout 6 tcpdump -i srv-in -n -U icmp > /tmp/s.txt 2>/dev/null &); sleep 2; ip netns exec h1 ping -c 1 203.0.113.9 > /dev/null 2>&1; ip netns exec h2 ping -c 1 203.0.113.9 > /dev/null 2>&1; sleep 5; cat /tmp/s.txt; ip netns exec nat conntrack -L 2>/dev/null | grep icmp'
```

Two things to confirm. The server sees one address for both hosts. And the
gateway's table has an entry per conversation, showing the inside address
alongside the outside one it was translated to.

On a home router the same table is usually visible somewhere in the status pages,
often called active connections or the NAT table, and it is worth looking at once
to see how many entries an ordinary household generates.

## What trips people up

### 1. Believing NAT is a security control

It drops unsolicited inbound traffic because it has no idea where to send it, not
because it decided to. It has no policy, inspects nothing, allows anything an
inside machine invites in, and does nothing between inside machines.

### 2. Confusing NAT and PAT

NAT rewrites the address. PAT rewrites the port as well, which is what lets many
machines share one address. Nearly everything called NAT in practice is PAT.

### 3. Expecting inbound to work like outbound

Outbound creates a table entry as a side effect. Inbound has no entry to match, so
it needs an explicit rule saying which inside machine it belongs to.

### 4. Forgetting the table is finite

One machine opening enough conversations can fill it, and when it is full new
conversations fail for everybody. There is no packet loss and no link fault to
find.

### 5. Assuming an idle connection survives

Entries age out, and neither end is told. Both believe the connection exists and
the next packet is dropped, which is why long SSH sessions die overnight without
keepalives.

### 6. Promising port forwarding behind carrier grade NAT

The outside address belongs to the provider and is shared, so there is nothing to
forward from. Seeing a 100.64 address on the outside interface is the sign.

## Work it through

A company's monitoring system reports that their public address is generating an
unusual volume of connections, and the provider has sent an abuse notice naming
that address. Internally, users report that new websites sometimes fail to load
for a minute and then work.

Two symptoms and one cause.

The abuse notice names the public address, which is every machine in the building
as far as anybody outside is concerned. That is the identification problem NAT
creates: the provider can see one address behaving badly and cannot see which of
the fifty machines behind it is responsible. Only the gateway knows, and only
while the entries exist.

The intermittent failures are the second symptom of the same event. Something is
opening a very large number of conversations, the translation table is filling,
and when it is full there is no entry available for a new conversation so it fails.
Entries age out, space frees, and it works again. That is exactly the pattern
users described.

So the immediate task is to find the inside machine, and the gateway's table is
where to do it. Listing the entries and counting by inside address finds the one
generating thousands where everything else has tens, which takes about a minute if
you know the table exists.

Two things for afterwards. Logging the translations, so that an abuse notice can
be traced back to a machine and a time rather than to a building, which is the
only way to answer this kind of notice at all. And a limit on how many entries one
inside address may occupy, so that one machine can no longer take the office
offline by exhausting a shared resource.

The thing worth saying in the report: the network was not attacked and nothing was
broken. A shared finite resource was consumed by one participant, and the design
had no per-participant limit.

## Try it

**Watch a translation happen.** Run the **Prove it** command. Seeing two hosts
arrive at a server as one address, with the gateway's table holding both, makes
the mechanism concrete.

**Count your own.** On a home router, find the active connection or NAT table.
The number of entries an ordinary household generates is usually surprising, and
it is the same table that fills in the scenario above.

**Find your public address.** Any site that reports the address it sees is
showing you the outside of your own NAT. Compare it to the address on your
machine, and if the one you see starts 100.64 then you are behind carrier grade
NAT and topic 07's panel applies to you.

## Check yourself

<details class="qa">
<summary>Fifty machines share one public address. How does the gateway know which one a reply belongs to?</summary>

From a table it built when each conversation started.

For each outbound conversation the gateway records the inside address and port,
and assigns an outside port of its own. A reply arriving for that outside port is
looked up and rewritten back to the inside address and port.

Because a port is 16 bits, one address supports tens of thousands of simultaneous
conversations. Rewriting the port as well as the address is what PAT means, and it
is why one address serves fifty machines.

</details>

<details class="qa">
<summary>Why does outbound need no configuration and inbound need an explicit rule?</summary>

Because outbound creates the table entry as it goes and inbound has nothing to
match.

An unsolicited packet arriving from outside has a destination of the gateway's
address and some port, and no entry says which of the inside machines it belongs
to. There is nothing to look up, so it is dropped.

Port forwarding supplies that information in advance: a static rule saying traffic
on this outside port goes to this inside address. It is destination translation
rather than source translation.

</details>

<details class="qa">
<summary>Why is NAT not a firewall?</summary>

Because dropping traffic you cannot place is not the same as deciding to deny it.

NAT has no policy, so there is no way to express what should be allowed. It
inspects nothing, so anything an inside machine connects out to can send whatever
it likes back, which covers essentially all malware. A port forwarding rule opens
a hole with no rules attached. And it does nothing at all between inside machines,
which reach each other directly.

A firewall denies what it has been told to deny. NAT drops what it does not
understand.

</details>

<details class="qa">
<summary>An SSH session left open overnight is dead in the morning, with no error at either end. Why?</summary>

The translation table entry aged out.

Entries are removed after a period without traffic, because the gateway cannot
always tell that a conversation has finished, and an idle connection looks
identical to an abandoned one.

Neither end is told. Both still believe the connection exists, and the next packet
arrives at the gateway with nothing matching it and is dropped. Keepalives exist
to prevent exactly this by making sure the conversation is never idle long enough.

</details>

<details class="qa">
<summary>New connections intermittently fail for everybody in an office, with no packet loss and no link fault. What would you check?</summary>

The number of entries in the gateway's translation table against its maximum.

The table is finite. One machine opening very many conversations can fill it, and
while it is full there is no entry available for anybody's new conversation, so
new connections fail while established ones continue. Entries age out, space
frees, and it works again.

It presents as intermittent because it is, and nothing about it looks like a
network fault, which is why the counter is the thing to look at.

</details>

<details class="qa">
<summary>What kind of protocol does NAT break, and what are the two fixes?</summary>

Anything that carries an address inside its payload rather than only in the
header. NAT rewrites headers and has no general way to know that bytes further in
are also an address. Active mode FTP and SIP are the standard examples.

The first fix is an application layer gateway, which is code in the NAT device
that understands the protocol and rewrites the addresses inside it. It works and
it is a layering violation that has produced subtle bugs for decades.

The second is the application discovering its own public address by asking a
server outside, which is what STUN does and how most voice and video handle it
now.

</details>

## References

- [RFC 3022, Traditional IP Network Address Translator](https://www.rfc-editor.org/rfc/rfc3022) - IETF, which defines NAT and the port translation variant. Accessed 2026-08-10.
- [RFC 2663, NAT Terminology and Considerations](https://www.rfc-editor.org/rfc/rfc2663) - IETF, on what NAT breaks. Accessed 2026-08-10.
- [RFC 6598, Shared Address Space](https://www.rfc-editor.org/rfc/rfc6598) - IETF, the carrier grade NAT range. Accessed 2026-08-10.
- [nft(8)](https://www.netfilter.org/projects/nftables/manpage.html) - netfilter project, the tool that configures the masquerade rule in the topology. Accessed 2026-08-10.

**Where the output came from.** The captured block was produced on
`blog/scripts/topologies/nat-gateway.sh` through `blog/scripts/netlab.sh`. The
gateway runs a real masquerade rule in nftables, so the rewriting is the kernel's
and the identifiers the server sees are what it actually received. The outside
network uses `203.0.113.0/24`, which RFC 5737 reserves for documentation.

The scenario in **Work it through** describes a table filling up, which is not
captured. Exhausting a translation table would work and would take several minutes
of generating junk to produce one number, so the page describes the counter to look
at instead.

**If you also work on Linux.** [Firewall concepts and netfilter](/learn/linux-plus/firewall-concepts-and-netfilter)
on the Linux+ track covers the same nftables machinery from the administration
side, including where the NAT hooks sit relative to the filtering ones.
