---
title: "Addressing faults"
description: "Two machines, one address, and connectivity that comes and goes. Why a duplicate address produces intermittent failure rather than an error, why a wrong mask fails one way down the wire and looks like broken hardware, and why an empty DHCP pool looks identical to four other faults from the client."
deck: "Two machines, one address, and connectivity that comes and goes"
track: "network-plus"
level: "deep"
order: 720
objectives:
  - "Detect a duplicate address from two replies to one request"
  - "Explain why a wrong mask puts part of your own subnet out of reach"
  - "Recognise the one-way failure two disagreeing masks produce"
  - "Tell pool exhaustion from the four faults that look the same at the client"
  - "Say which evidence lives on the host and which lives on the server"
prerequisites: ["ipv4-addresses-and-the-mask"]
tags: ["network-plus", "networking", "troubleshooting", "addressing"]
updated: 2026-08-19
draft: false
examObjectives:
  - exam: "n10-009"
    domain: "5.0"
    objective: "5.3"
sources:
  - title: "RFC 826, Address Resolution Protocol"
    url: "https://www.rfc-editor.org/rfc/rfc826"
    publisher: "IETF"
    accessed: 2026-08-19
    tier: 1
  - title: "RFC 2131, Dynamic Host Configuration Protocol"
    url: "https://www.rfc-editor.org/rfc/rfc2131"
    publisher: "IETF"
    accessed: 2026-08-19
    tier: 1
  - title: "RFC 5227, IPv4 Address Conflict Detection"
    url: "https://www.rfc-editor.org/rfc/rfc5227"
    publisher: "IETF"
    accessed: 2026-08-19
    tier: 1
symptoms:
  - symptom: "Connectivity to one host works sometimes and not others"
    anchor: "two-replies-to-one-question"
  - symptom: "Some hosts on the same wire are reachable and others are not"
    anchor: "a-mask-decides-what-counts-as-here"
  - symptom: "A client ends up with a 169.254 address and no lease"
    anchor: "the-pool-is-empty-and-the-client-cannot-tell"
---

> **Before you read.** A file server is reachable and then it is not. Somebody
> reports it as slow, somebody else says it is fine, and a third person cannot
> log in at all. Ten minutes later they all swap positions.
>
> The server is up. It has not been rebooted, its cable has not moved, and its
> counters are clean. A workstation was set up in the same office on Monday.
>
> **What is happening on Monday's workstation?**

Addressing faults are the ones that produce the least helpful symptoms available.
Nothing errors, nothing logs, and the failure moves between users, which reads as
an application problem or a flaky server. Every one of them is deterministic once
you know which evidence to look at.

## Some words you will need

<dl class="terms">
<dt>address resolution</dt>
<dd>Asking a segment which hardware address owns an IP address. One question broadcast to everybody, and normally exactly one answer.</dd>
<dt>duplicate address</dt>
<dd>Two devices claiming the same IP address on one segment. Both answer, and whoever answered last wins.</dd>
<dt>neighbour cache</dt>
<dd>What a host remembers about who owns which address on its own subnet. Where the winner of a duplicate is recorded.</dd>
<dt>on-link</dt>
<dd>An address the host believes it can reach directly, without a router. The mask, and only the mask, decides which addresses those are.</dd>
<dt>pool</dt>
<dd>The range of addresses a DHCP server is allowed to hand out. Smaller than the subnet, and finite.</dd>
</dl>

## What breaks without this

**A working server is investigated for weeks.** Intermittent, user-dependent
failure with clean logs at both ends is the signature of an addressing fault, and
it is also what a badly behaved application looks like, so the wrong team gets the
ticket.

**A one-way fault is diagnosed as a cable.** Traffic arriving and no traffic
returning is exactly what a damaged pair produces, so the cable gets replaced and
the fault stays.

**A client with no address gets rebuilt.** The five different causes of "no lease"
produce one symptom, and only one of them is on the client.

## Two replies to one question

Start with the fault in the hook, because its evidence is unambiguous and takes one
command.

Address resolution is a question broadcast to a whole segment: who owns this
address? On a correct network exactly one device answers. Give two devices the same
address and both answer, and the asker keeps whichever reply arrived last. The
topology is
[`one-switch.sh`](https://github.com/rlwilliamson-dev/azure-resume/blob/main/blog/scripts/topologies/one-switch.sh).

<details class="predict">
<summary>Two machines on one switch are given the same address, and a third asks the segment who owns it. How many answers come back, and which one gets remembered?</summary>

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology one-switch
# h3 is given the address h2 already has. one typo, one machine
$ ip netns exec h3 ip addr del 10.0.0.3/24 dev h3eth0
$ ip netns exec h3 ip addr add 10.0.0.2/24 dev h3eth0
$ sleep 1
# h1 asks the segment who owns 10.0.0.2, and everything is listened to
$ ip netns exec h1 ip neigh flush all
$ ip netns exec h1 timeout 4 tcpdump -n -i h1eth0 arp -c4 > /tmp/arp.txt 2>&1 &
$ sleep 1
$ ip netns exec h1 ping -c3 -W1 10.0.0.2 2>&1 | grep "packet loss"
3 packets transmitted, 3 received, 0% packet loss, time 2061ms
$ sleep 3
$ grep -v "^tcpdump\|^listening" /tmp/arp.txt
15:15:22.364419 ARP, Request who-has 10.0.0.2 tell 10.0.0.1, length 28
15:15:22.364555 ARP, Reply 10.0.0.2 is-at 02:00:00:00:00:03, length 28
15:15:22.364575 ARP, Reply 10.0.0.2 is-at 02:00:00:00:00:02, length 28

3 packets captured
3 packets received by filter
0 packets dropped by kernel
# and what h1 recorded out of that
$ ip netns exec h1 ip neigh show
10.0.0.2 dev h1eth0 lladdr 02:00:00:00:00:03 REACHABLE 
```

</details>

**One request, two replies, two different hardware addresses.** That is the whole
diagnosis and there is no other explanation for it. `02:00:00:00:00:02` is the
machine that has always had that address and `02:00:00:00:00:03` is the one somebody
set up on Monday, and both of them believe they are 10.0.0.2.

Two details in that block are worth dwelling on.

**The ping succeeds.** Every packet, no loss. Something answers, so a connectivity
test passes, which is why this fault survives the first round of troubleshooting.
What the test does not tell you is which of the two machines answered, and half the
time it is the wrong one.

**The neighbour cache records one winner.** `lladdr 02:00:00:00:00:03` is the last
answer to arrive, and it is the impostor. That entry then persists until it ages out
or another reply overtakes it, which is where the intermittency comes from: each host
on the segment independently caches whichever reply reached it last, so different
people reach different machines, and the same person reaches a different machine after
the cache expires. Nobody is imagining it and nothing is random. It is just a race
with two winners.

<details class="deeper">
<summary>If you already chase intermittent faults: what a duplicate does to a server, and the detection that was standardised for it</summary>

The symptom set above is the client's half. The server's half is stranger and is
worth recognising because it points at the fault from the other direction.

A machine sharing its address with another sees connections that make no sense.
Sessions that were established elsewhere arrive mid-conversation, so it sends resets
to hosts it has never spoken to. Half a transfer arrives. Its logs fill with
protocol errors from clients that are, from its point of view, behaving illegally.
Nothing in that picture says addressing, and the natural reading is that something
on the network is corrupting traffic.

The pairing of the two halves is the recognisable thing. Clients that reach the
right service sometimes, and a server logging protocol errors it cannot explain, at
the same time, on the same segment. Neither half is diagnostic alone and together
they are close to conclusive.

There is a standard mechanism for catching this at the moment it happens, in RFC
5227. A host coming up is meant to ask who owns the address it is about to use,
before using it, and to defend the address later if somebody else claims it. When
it works, the second machine refuses to bring the interface up and says why, which
turns a week of intermittent failure into an error message on the machine that
caused it. It is worth knowing it exists for two reasons: the message is a real
diagnosis when you see it, and plenty of devices do not implement it, which is why
the fault still happens.

The other detection worth knowing is on the switch rather than the host. A duplicate
address does not move a MAC address, so the forwarding table looks normal, but a
switch that logs MAC address moves will show flapping when the two machines have the
same address and share traffic. Topic 67's carrier and counter reading applies here:
the switch has evidence, and it is not in the place you would first look.

</details>

## A mask decides what counts as here

The second fault has nothing intermittent about it. It is completely deterministic
and it looks like hardware, which is worse.

A mask does one job: it decides which addresses this host believes are on its own
wire. Everything inside is sent directly. Everything outside is handed to a router.
Get the mask wrong and you have not broken anything, you have moved the boundary, and
part of your own segment is now on the far side of it.

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology one-switch
# three hosts on one switch and one subnet. h3 is readdressed higher up the range
$ ip netns exec h3 ip addr del 10.0.0.3/24 dev h3eth0
$ ip netns exec h3 ip addr add 10.0.0.200/24 dev h3eth0
$ ip netns exec h1 ping -c1 -W1 10.0.0.2 2>&1 | grep "packet loss"
1 packets transmitted, 1 received, 0% packet loss, time 0ms
$ ip netns exec h1 ping -c1 -W1 10.0.0.200 2>&1 | grep "packet loss"
1 packets transmitted, 1 received, 0% packet loss, time 0ms
# h1 mask is typed as /25 instead of /24. its address does not change, its cable
# does not change, and it is on the same switch as before
$ ip netns exec h1 ip addr del 10.0.0.1/24 dev h1eth0
$ ip netns exec h1 ip addr add 10.0.0.1/25 dev h1eth0
$ ip netns exec h1 ip -br addr show h1eth0
h1eth0@if6       UP             10.0.0.1/25 
$ ip netns exec h1 ping -c1 -W1 10.0.0.2 2>&1 | grep "packet loss"
1 packets transmitted, 1 received, 0% packet loss, time 0ms
$ ip netns exec h1 ping -c1 -W1 10.0.0.200 2>&1 | tail -2
ping: connect: Network is unreachable
```

Same cable, same switch, same address on h1. The only change is a mask, and
`10.0.0.2` still works while `10.0.0.200` is refused instantly. **The refusal is the
tell**: `Network is unreachable` comes from the host itself, which means it did not
send anything, which means it decided the destination was somewhere else and had no
route there.

So the signature of a wrong mask is **selective failure by address**, and it is a
signature no physical fault can produce. A bad cable, a failing transceiver, a duplex
mismatch and a dying switch port all break traffic without consulting the destination
address. If some hosts on one wire are reachable and others are not, and which ones
depends on arithmetic rather than on where they are plugged in, the mask is wrong
somewhere.

The harder version is when the two ends disagree.

<figure class="learn-figure">
<svg viewBox="0 0 720 195" role="img" aria-labelledby="mask-title" style="width:100%;height:auto;">
<title id="mask-title">Two hosts on one wire with different masks, so one believes the other is on the same segment and sends to it directly while the other believes the first is elsewhere and never sends a reply</title>
<g fill="currentColor">
<text x="14" y="22" font-size="11">one wire, two different ideas of where it ends</text>
<g stroke="currentColor" stroke-opacity="0.5" stroke-width="1.3" fill="none">
<path d="M 160 103 H 553"/>
</g>
<g fill="currentColor" fill-opacity="0.08" stroke="currentColor" stroke-opacity="0.75">
<rect x="50" y="88" width="110" height="30" rx="4"/>
<rect x="553" y="88" width="122" height="30" rx="4"/>
</g>
<text x="105" y="107" text-anchor="middle" font-size="10">10.0.0.1/24</text>
<text x="614" y="107" text-anchor="middle" font-size="10">10.0.0.200/25</text>
<g stroke="var(--accent)" stroke-width="2.2" fill="none">
<path d="M 160 80 C 300 48 420 48 549 78"/>
<path d="M 549 78 l -10 -1 l 4 8"/>
</g>
<text x="356" y="44" text-anchor="middle" font-size="9.5" fill="var(--accent)">sent, and arrives</text>
<g stroke="var(--red)" stroke-width="2.2" stroke-dasharray="5 3" fill="none">
<path d="M 549 126 C 500 146 460 150 420 150"/>
</g>
<g stroke="var(--red)" stroke-width="2" fill="none">
<path d="M 402 144 l 12 12 M 414 144 l -12 12"/>
</g>
<text x="330" y="154" text-anchor="end" font-size="9.5" fill="var(--red)">never sent</text>
<text x="105" y="140" text-anchor="middle" font-size="9.5" fill-opacity="0.85">its wire is .0 to .255</text>
<text x="614" y="140" text-anchor="middle" font-size="9.5" fill-opacity="0.85">its wire is .128 to .255</text>
<text x="14" y="182" font-size="9.5" fill-opacity="0.85">the mask is the only thing that decides which addresses a host will send to without a router</text>
</g></svg>
<figcaption>Each host is behaving correctly according to what it was told. The one on the left believes the whole range is local, so it sends directly and the frames arrive. The one on the right believes the bottom half of the range is somewhere else, so a reply to it needs a router, and there is no router. The result is traffic in one direction only, on one cable, between two machines that each look perfectly configured when examined on their own. That is the same shape a broken pair in a cable produces, which is why this fault survives a cable swap.</figcaption>
</figure>

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology one-switch
# h3 is readdressed to the top of the range, with the mask typed as /25
$ ip netns exec h3 ip addr del 10.0.0.3/24 dev h3eth0
$ ip netns exec h3 ip addr add 10.0.0.200/25 dev h3eth0
# h1 is correct: /24, so it believes 10.0.0.200 is on its own wire
$ ip netns exec h1 ip -br addr show h1eth0
h1eth0@if6       UP             10.0.0.1/24 
$ ip netns exec h1 ping -c2 -W1 10.0.0.200 2>&1 | grep "packet loss"
2 packets transmitted, 0 received, 100% packet loss, time 1034ms
# and the requests are arriving. h3 counts every one of them
$ ip netns exec h3 ip -s -s link show h3eth0 | sed -n "3,4p"
    RX:  bytes packets errors dropped  missed   mcast           
           138       3      0       0       0       0 
$ ip netns exec h3 ping -c1 -W1 10.0.0.1 2>&1 | tail -2
ping: connect: Network is unreachable
```

Read the middle of that block. h1 sends and gets nothing back, and h3's own counter
proves the requests arrived. Then h3, asked to reach h1, refuses instantly with the
same `Network is unreachable`, because from behind a /25 the address `10.0.0.1` is
not on its wire and it has no route to anywhere else.

**Traffic one way and not the other, with counters proving arrival, is a mask
disagreement until proved otherwise.** The reason it gets misdiagnosed is that it
matches the symptom of a cable with a damaged pair almost exactly, so the cable gets
replaced first, which costs an hour and changes nothing.

The move that settles it is to read the mask at both ends and compare. Not the
address, which is usually right, and not the gateway. The mask.

<details class="deeper">
<summary>If you already do this arithmetic in your head: which half of the mask is worth checking first, and the fault a wrong address does not produce</summary>

There is an asymmetry in mask mistakes that makes one direction more common and much
more confusing.

A mask that is too long, /25 where /24 was meant, shrinks the host's idea of its own
wire and pushes part of the segment out of reach. That is the case above, and it
fails selectively by address in a way that is at least visible once you notice which
addresses work.

A mask that is too short, /23 where /24 was meant, does the opposite and is quieter.
The host now believes a range it is not on is local, so instead of handing that
traffic to the router it tries to resolve it directly on the wire, asks who owns an
address that nobody on the segment has, and gets nothing. Traffic to the real subnet
next door fails while everything else works, and the failure is a timeout rather than
a refusal, so there is no message at all. Both are worth checking; the second is the
one people do not think of, because the address and the gateway are correct and the
mask looks nearly right.

Worth separating from both is the fault a wrong address produces, which is not the
same shape. A host given an address on a subnet nobody else is using is isolated
rather than selectively broken: nothing local works, and if the gateway address is
also outside its new idea of local, nothing at all works. The pattern to distinguish
them is how many things fail. A wrong address usually breaks everything, and a wrong
mask usually breaks some things, which is why the mask is the harder one to find and
the one worth suspecting when the failure list is strange rather than complete.

</details>

## The pool is empty and the client cannot tell

The last of the four is the one where the client has almost no useful information at
all, which is the whole reason it belongs in a troubleshooting topic rather than in
topic 42.

Two clients take a pool that is two addresses wide, and a third asks. The topology is
[`dhcp-lan.sh`](https://github.com/rlwilliamson-dev/azure-resume/blob/main/blog/scripts/topologies/dhcp-lan.sh).

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology dhcp-lan
# two clients take the whole pool, which is two addresses wide
$ ip netns exec h1 dhclient -v -1 h10 2>&1 | tail -1
bound to 10.0.0.101 -- renewal in 21529 seconds.
$ ip netns exec h4 dhclient -v -1 h40 2>&1 | tail -1
bound to 10.0.0.100 -- renewal in 18078 seconds.
# a third client asks, and this is everything it ever learns
$ ip netns exec h5 timeout 20 dhclient -v -1 h50 2>&1 | tail -3
DHCPDISCOVER on h50 to 255.255.255.255 port 67 interval 6
DHCPDISCOVER on h50 to 255.255.255.255 port 67 interval 13
DHCPDISCOVER on h50 to 255.255.255.255 port 67 interval 16
$ ip netns exec h5 ip -4 addr show h50 | grep inet
# the same moment, read on the server
$ ip netns exec srv cat /var/lib/misc/dnsmasq.leases
1787195737 02:00:00:00:00:14 10.0.0.100 26c3800bd92a *
1787195734 02:00:00:00:00:11 10.0.0.101 * *
```

The client asks, at increasing intervals, and hears nothing. There is no message in
the protocol meaning "there are none left", so an empty pool is silence, and silence
at a client is also what you get from a server that is switched off, a broken uplink,
a VLAN with no relay configured on it, and a firewall dropping the broadcast. Five
faults, one symptom, and the client's interface eventually configures itself with a
169.254 address which says only that DHCP did not work.

**The server settles it in one line.** Both pool addresses are leased, and the client
that is still asking is not among them. That is not an inference, it is the record,
and it separates exhaustion from the other four immediately.

Which is the general lesson of this section and worth stating plainly: **when a
protocol has no way to say no, the evidence is at the other end.** The client can
tell you that nothing answered. Only the server can tell you why. So the order of
work for any machine with no lease is to check the server's leases first, because
that one reading either confirms exhaustion or eliminates it and sends you to the
path between the two.

## Prove it

You have this when you can name which of the four faults you are looking at from the
evidence rather than from the symptom.

```bash
# who answers for this address, and how many of them
tcpdump -n -i <interface> arp
ip neigh show

# what this host believes its own wire is
ip -br addr show <interface>

# and on the server, whether there is anything left to hand out
cat /var/lib/misc/dnsmasq.leases
```

The four signatures, which do not overlap:

| What you see | What it is |
| --- | --- |
| Two replies to one address request | A duplicate address |
| Some addresses on one wire reachable, others refused instantly | A mask that is too long on this host |
| Traffic arrives and nothing returns, counters clean | The two ends disagree about the mask |
| No lease, no message, a 169.254 address | One of five, and the server's lease list decides which |

## Across platforms

Every platform answers the same three questions and the exam names the older tools on
Windows.

| Task | Linux | Windows | macOS |
| --- | --- | --- | --- |
| Read the address and mask | `ip -br addr show` | `ipconfig`, `Get-NetIPAddress` | `ifconfig <if>` |
| Read who owns an address locally | `ip neigh show` | `arp -a`, `Get-NetNeighbor` | `arp -an` |
| Read the current lease | `cat /var/lib/dhcp/dhclient.leases` | `ipconfig /all` | `ipconfig getpacket <if>` |

One difference worth knowing rather than memorising. Windows `ipconfig` prints the mask
in dotted decimal and the Linux and macOS tools print a prefix length, so the same fault
reads as `255.255.255.128` on one platform and `/25` on another. They are the same
number said two ways, and topic 05 covered the conversion. Reading a mask at both ends
of a link frequently means converting one of them.

## What trips people up

### 1. Treating a successful ping as proof of the right host

With a duplicate address something always answers. The test passes and tells you
nothing about which of the two machines it reached.

### 2. Calling an intermittent fault random

Each host caches whichever reply arrived last, so different people reach different
machines and the same person changes machines when the cache expires. It is a race,
not a random event, and it is repeatable if you flush the cache and watch.

### 3. Replacing the cable on a one-way fault

Traffic arriving with nothing returning is what a damaged pair produces and also what
two disagreeing masks produce. The counters at the far end tell you the frames arrived,
which rules out the cable before you touch it.

### 4. Checking the address and not the mask

The address is usually right. It is the number next to it that decides which of your
neighbours you believe you can talk to, and it is the one people read past.

### 5. Expecting DHCP to say no

There is no message for an empty pool. Silence at the client covers five different
faults, and the only one of them the client can see is none of them.

### 6. Reading 169.254 as the fault

A link-local address is the symptom of DHCP not working, not a cause. It tells you the
same thing in all five cases.

## Work it through

The file server that works for some people and not others.

Start by noticing the shape rather than the details. Intermittent, different for
different users, moving over time, with clean logs and clean counters at both ends. No
physical fault behaves that way, because a cable does not know who is asking. Something
that resolves differently for different askers does, and on one segment there is one
thing that resolves.

So ask the segment directly. Send an address resolution request for the server and
watch what comes back, on a machine that is currently having the problem. One reply is
one owner and the theory is dead. Two replies with different hardware addresses is the
diagnosis, complete, in one command, and the second address tells you which machine to
go and find.

Then check the timing against what changed, because it will match. A workstation set up
on Monday, a fault that started on Monday, and an address that was typed by hand rather
than leased. The fix is on that machine and it takes a minute.

And if there is only one reply, the shape was telling you something else. Move to the
masks at both ends, because the other fault that produces user-dependent behaviour is
two machines disagreeing about which addresses are local, and that one fails
consistently per pair of hosts rather than over time. Read both masks, convert if the
platforms print them differently, and compare. Between the duplicate and the mask, most
of what gets reported as a flaky server is accounted for.

## Try it

**Make a duplicate on purpose and watch the replies.** In
[`one-switch.sh`](https://github.com/rlwilliamson-dev/azure-resume/blob/main/blog/scripts/topologies/one-switch.sh),
give two hosts one address and run a packet capture filtered to address resolution while
you ping it. Seeing two replies to one question is what makes the diagnosis instant
forever after.

**Break a mask in one direction.** In the same topology, put a longer mask on one host
only and ping in both directions. Then read the counters at the end that is not replying
and confirm the frames arrived. That is the evidence that saves a cable swap.

**Do the arithmetic before you look.** Given a host at 10.0.0.1 with a /25 mask, write
down which of 10.0.0.2, 10.0.0.126, 10.0.0.129 and 10.0.0.200 it believes are local.
Then check yourself against the block above. This is topic 05's arithmetic used as a
diagnostic rather than as a design tool, which is most of what it is for.

## Check yourself

<details class="qa">
<summary>A server is reachable for some people and not others, and the pattern changes over time. What do you suspect?</summary>

A duplicate address on the segment. Two devices claiming one address both answer address
resolution requests, so each host on the wire independently caches whichever reply
reached it last and ends up talking to a different machine.

That is what produces user-dependent, time-varying behaviour with nothing wrong at
either end. It is a race rather than a random fault, and the confirmation is one packet
capture: send a request for the address and count the replies. Two replies with
different hardware addresses is conclusive.

</details>

<details class="qa">
<summary>Why does a duplicate address not simply break connectivity?</summary>

Because something always answers. A ping succeeds, a connection establishes, and a
monitoring check passes, all against whichever of the two machines won the last race.

That is precisely what makes it expensive. Every simple test passes, so the fault
survives the first round of troubleshooting and gets attributed to the application. The
server half of the symptom is the other half of the evidence: a machine sharing its
address sees connections it never started and logs protocol errors from hosts it has
never spoken to.

</details>

<details class="qa">
<summary>A host reaches some machines on its own wire and gets an instant refusal for others. What is wrong?</summary>

Its mask is too long. The mask decides which addresses the host believes are on its own
segment, so a /25 where /24 was meant puts the upper half of the range on the far side of
an imaginary boundary, and traffic to it needs a router the host does not have.

The instant `Network is unreachable` is the tell. It comes from the host, before anything
is transmitted, and it means the host consulted its own arithmetic and declined. Selective
failure by address is a signature no physical fault can produce, because a cable does not
read destination addresses.

</details>

<details class="qa">
<summary>Traffic goes one way between two hosts on one switch. The far end's counters show the frames arriving. Cable?</summary>

No. The counters have already ruled the cable out: frames are arriving in the direction
that supposedly does not work, so the physical path is intact both ways.

This is two masks disagreeing. The sender believes the destination is on its own wire and
sends directly, which is why the frames arrive. The receiver believes the sender is on a
different subnet, so its reply needs a router, and there is none. Each machine is correct
according to what it was told, and reading both masks and comparing them is the fix.

</details>

<details class="qa">
<summary>A client has a 169.254 address and no lease. What does that tell you, and where do you look?</summary>

That DHCP did not work, and nothing more. There is no message in the protocol meaning
"the pool is empty", so the client's experience of exhaustion is silence, which is
identical to a server that is off, a broken uplink, a VLAN with no relay, and a firewall
dropping the broadcast.

The evidence is on the server. Its lease list either shows the pool fully allocated,
which confirms exhaustion, or it does not, which eliminates it and sends you to the path
between the client and the server. When a protocol has no way to say no, the answer is
always at the other end.

</details>

## References

- [RFC 826](https://www.rfc-editor.org/rfc/rfc826) - IETF, address resolution, which is why one request gets one reply on a healthy segment and two on a broken one. Free. Accessed 2026-08-19.
- [RFC 5227](https://www.rfc-editor.org/rfc/rfc5227) - IETF, IPv4 address conflict detection, the mechanism for catching a duplicate at the moment it is configured rather than weeks later. Free. Accessed 2026-08-19.
- [RFC 2131](https://www.rfc-editor.org/rfc/rfc2131) - IETF, DHCP, which defines the messages a server can send and therefore the absence of one meaning the pool is empty. Free. Accessed 2026-08-19.

**Where the numbers came from.** Four captured blocks through `netlab.sh` on the kernel in
each header. The duplicate and the two mask faults are on
[`one-switch.sh`](https://github.com/rlwilliamson-dev/azure-resume/blob/main/blog/scripts/topologies/one-switch.sh)
and the exhaustion is on
[`dhcp-lan.sh`](https://github.com/rlwilliamson-dev/azure-resume/blob/main/blog/scripts/topologies/dhcp-lan.sh),
whose pool is deliberately two addresses wide so exhaustion happens on the third client.
Every fault is made in the captured commands. The conflict detection in the panel above is
described from RFC 5227 rather than shown, because the tooling here does not implement the
defence and inventing a transcript of it would be worse than saying so.

**If you also work on Linux systems.** [Network connectivity troubleshooting](/learn/linux-plus/network-connectivity-troubleshooting)
approaches the same faults from a single machine, where the question is whether this host
can reach a service. The addressing arithmetic is identical and the difference is that a
network view can compare two machines, which is what makes a duplicate and a mask
disagreement visible at all.
