---
title: "The day the addresses ran out"
description: "IPv4 ran dry in February 2011 and the internet carried on, which is the fact worth explaining. What 128 bits buys, how to read and shorten a hex address, the link-local address your machine configured without being asked, and the three ways networks run both protocols at once."
track: "network-plus"
level: "working"
order: 90
objectives:
  - "Say what ran out in 2011 and what the internet did instead of stopping"
  - "Read a 128 bit address written in hexadecimal"
  - "Apply both shortening rules, including the one that may only be used once"
  - "Recognise a link-local address and say where it came from"
  - "Describe dual stack, tunnelling and NAT64 and say which problem each solves"
prerequisites: ["ipv4-addresses-and-the-mask"]
tags: ["network-plus", "networking", "ipv6"]
updated: 2026-08-10
draft: false
examObjectives:
  - exam: "n10-009"
    domain: "1.0"
    objective: "1.8"
sources:
  - title: "RFC 4291, IP Version 6 Addressing Architecture"
    url: "https://www.rfc-editor.org/rfc/rfc4291"
    publisher: "IETF"
    accessed: 2026-08-10
    tier: 1
  - title: "RFC 5952, A Recommendation for IPv6 Address Text Representation"
    url: "https://www.rfc-editor.org/rfc/rfc5952"
    publisher: "IETF"
    accessed: 2026-08-10
    tier: 1
  - title: "RFC 4193, Unique Local IPv6 Unicast Addresses"
    url: "https://www.rfc-editor.org/rfc/rfc4193"
    publisher: "IETF"
    accessed: 2026-08-10
    tier: 1
  - title: "RFC 3849, IPv6 Address Prefix Reserved for Documentation"
    url: "https://www.rfc-editor.org/rfc/rfc3849"
    publisher: "IETF"
    accessed: 2026-08-10
    tier: 1
  - title: "RFC 4213, Basic Transition Mechanisms for IPv6 Hosts and Routers"
    url: "https://www.rfc-editor.org/rfc/rfc4213"
    publisher: "IETF"
    accessed: 2026-08-10
    tier: 1
  - title: "RFC 6146, Stateful NAT64"
    url: "https://www.rfc-editor.org/rfc/rfc6146"
    publisher: "IETF"
    accessed: 2026-08-10
    tier: 1
  - title: "RFC 8981, Temporary Address Extensions for SLAAC in IPv6"
    url: "https://www.rfc-editor.org/rfc/rfc8981"
    publisher: "IETF"
    accessed: 2026-08-10
    tier: 1
  - title: "RFC 7217, Semantically Opaque Interface Identifiers with SLAAC"
    url: "https://www.rfc-editor.org/rfc/rfc7217"
    publisher: "IETF"
    accessed: 2026-08-10
    tier: 1
  - title: "Free Pool of IPv4 Address Space Depleted"
    url: "https://www.nro.net/ipv4-free-pool-depleted/"
    publisher: "Number Resource Organization"
    accessed: 2026-08-10
    tier: 1
symptoms:
  - symptom: "An interface has an fe80 address that nobody configured"
    anchor: "the-address-nobody-configured"
  - symptom: "A ping to a link-local address fails without a zone or interface"
    anchor: "the-address-nobody-configured"
---

> **Before you read.** On 3 February 2011 the global pool of IPv4 addresses was
> declared empty. Every remaining block had been handed to a regional registry
> and there were no more to give out.
>
> That was fifteen years ago. The internet did not stop, IPv4 is still what most
> traffic uses, and you have probably never been told you cannot have an address.
>
> **If they genuinely ran out, how is any of that true?**

The answer to that question is most of what this topic is for. IPv6 is the
designed solution and it is only part of the story, and understanding the other
part explains why a protocol finalised in the 1990s is still being described as
the future.

### Some words you will need

<dl class="terms">
<dt>hexadecimal</dt>
<dd>Counting in sixteens, using 0 to 9 and then a to f. One hex digit is exactly four bits.</dd>
<dt>field</dt>
<dd>One of the eight groups in an IPv6 address, each 16 bits, written as up to four hex digits.</dd>
<dt>global unicast</dt>
<dd>An IPv6 address that is routable on the internet, the equivalent of a public IPv4 address.</dd>
<dt>link-local</dt>
<dd>An IPv6 address valid on one segment only. Every IPv6 interface has one automatically.</dd>
<dt>dual stack</dt>
<dd>Running IPv4 and IPv6 at the same time on the same interface.</dd>
<dt>interface identifier</dt>
<dd>The last 64 bits of most IPv6 addresses, which name the interface within its network.</dd>
</dl>

## What breaks without this

**You cannot read half the output your tools produce.** Every capture in this
track so far has shown an `fe80::` address next to the IPv4 one. If those are
noise to you, you are ignoring part of every diagnostic you run.

**IPv6 problems get misdiagnosed as DNS problems.** A dual stack machine tries
IPv6 first for a name that resolves both ways. When the IPv6 path is broken, the
symptom is a slow or failing connection to one site, and the cause is nowhere
near the name resolution people start with.

**A whole exam domain stays hazy.** Objective 1.8 is explicit about IPv6, and it
is the material candidates most often decide to skip because it feels distant.
It is on the paper regardless.

## Why four billion was not enough

An IPv4 address is 32 bits, which gives 4,294,967,296 combinations. In 1981 that
was an absurd surplus. It stopped being one, and the arithmetic is less
interesting than the way it stopped.

The exhaustion was not one event but a sequence of them. The Number Resource
Organization announced on 3 February 2011 that the central pool held by IANA was
empty, its last five blocks having been distributed to the five regional
registries at once under a policy written for exactly that moment. Each registry
then ran through its own allocation on its own timetable.

Three things kept the internet running afterwards, and only one of them is IPv6.

**Private addressing and NAT**, from the previous topic, mean an organisation of
ten thousand machines can consume a handful of public addresses. That is why you
have never been refused an address: you were not being given a public one.

**Address transfers.** Blocks allocated generously in the 1980s became valuable,
and registries built policies for selling and transferring them. Public IPv4
space now has a market price.

**IPv6**, which is the only one of the three that fixes the underlying problem
rather than rationing around it.

<details class="deeper">
<summary>If you already work on networks: what running out actually cost, since the lights stayed on</summary>

The absence of a visible failure is why IPv6 adoption took decades, and it is
worth being concrete about what was paid instead.

The bill mostly went to carrier grade NAT, which appeared in the previous topic
as the 100.64.0.0/10 range. Providers who could not get enough public addresses
put many customers behind one, and the consequences land on the customer.
Inbound connections stop working, so port forwarding does nothing and hosting
anything from home becomes impossible. Anything identifying a user by IP address
sees thousands of unrelated people as one, which breaks reputation systems, rate
limits and abuse handling. And troubleshooting gets a layer harder, because the
address a service sees is not the address the customer has.

The second cost is structural rather than technical. A new organisation cannot
get a meaningful IPv4 allocation, so entering the market means buying addresses
or accepting NAT, which is a barrier that did not exist before and which favours
whoever was already there.

None of this shows up as an outage, which is the point. The internet did not
break. It got more centralised, less symmetric, and worse at the thing it was
designed for, and none of those changes generated a single support ticket that
said so.

</details>

## 128 bits, written in hexadecimal

IPv6 uses 128 bits. Writing that in dotted decimal would need sixteen numbers, so
the notation changed to hexadecimal.

Hex counts in sixteens: 0 through 9, then a, b, c, d, e, f for the values ten to
fifteen. One hex digit is exactly four bits, which is the reason it was chosen.
Four hex digits are 16 bits, and that is one field.

An address is eight fields of 16 bits, separated by colons.

```
2001:0db8:0000:0000:0000:0000:0000:0001
 ^    ^                              ^
 |    |                              one field, 16 bits, four hex digits
 |    eight of these
 first field
```

Eight fields of 16 bits is 128 bits. The number of combinations is 2 to the power
128, which is about 340 undecillion and not a number worth trying to feel. The
useful comparison is that IPv6 gives every /64 network more addresses than the
whole of IPv4, and hands those /64s out by the billion.

<details class="deeper">
<summary>If you already work on networks: what the 128 bits are actually divided into, and why /64 is everywhere</summary>

The address is not one flat number in practice. A global unicast address is
conventionally read as three parts.

The first 48 bits are the routing prefix, which is what a provider or registry
allocates to an organisation. The next 16 bits are the subnet identifier, which
the organisation uses to number its own networks. The last 64 bits are the
interface identifier, which names one interface within its network.

That split explains the two prefix lengths you see constantly. A site is
typically given a /48, which leaves 16 bits of subnet identifier, so 65,536
networks. Each of those networks is a /64.

**The /64 is close to mandatory rather than conventional**, and that is the part
that surprises people coming from IPv4. Stateless address autoconfiguration
generates the interface identifier from 64 bits, so a network with a longer
prefix cannot use it. Some point to point links are configured as /127 for the
same reason IPv4 links use /31, but a subnet where hosts live is a /64 and
subnetting it further breaks things rather than saving anything.

Which is a genuine adjustment. In IPv4 the prefix length is a resource decision
and getting it wrong wastes addresses that matter. In IPv6 the host part is
always 64 bits, and the design question moves entirely to how you allocate
subnets out of the 16 bits above it. An organisation with 65,536 networks
available does not need to be careful in the way the previous two topics were
careful. It needs to be organised.

</details>

## Two rules for writing them down

Nobody types the full form. RFC 4291 gives two rules for shortening, and between
them they turn the address above into something you can say out loud.

**Leading zeros in a field may be dropped.** The field `0db8` is written `db8`,
and `0001` is written `1`. The rule stops short of removing everything: a field of
all zeros still needs one digit, so `0000` becomes `0`.

**One run of all-zero fields may be replaced by a double colon.** The six zero
fields in the middle collapse to `::`, and the reader restores them by counting
how many are missing.

Applied together, `2001:0db8:0000:0000:0000:0000:0000:0001` is `2001:db8::1`.

**The second rule may be used once per address and no more.** That restriction is
the whole reason the notation works. An address with two double colons would be
ambiguous, because there would be no way to know how many zero fields belonged to
each, so `2001:db8::1::2` is not a shortened address, it is an invalid one.

You do not have to take that on faith either. Type the long form and read back
what the machine stored.

<details class="predict">
<summary>The address is typed out in full, all thirty two hex digits. What does the kernel print when asked for it back?</summary>

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology two-hosts
# type the long form, and read back what the kernel stored
$ ip -n h1 addr add 2001:0db8:0000:0000:0000:0000:0000:0001/64 dev h1eth0
$ ip -n h2 addr add 2001:db8::2/64 dev h2eth0
$ ip -n h1 -6 addr show h1eth0 scope global
4: h1eth0@if3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000 link-netns h2
    inet6 2001:db8::1/64 scope global tentative 
       valid_lft forever preferred_lft forever
$ ip -n h1 -6 route
2001:db8::/64 dev h1eth0 proto kernel metric 256 pref medium
fe80::/64 dev h1eth0 proto kernel metric 256 pref medium
$ sleep 2
$ ip netns exec h1 ping -c 2 2001:db8::2
PING 2001:db8::2 (2001:db8::2) 56 data bytes
64 bytes from 2001:db8::2: icmp_seq=1 ttl=64 time=0.051 ms
64 bytes from 2001:db8::2: icmp_seq=2 ttl=64 time=0.082 ms

--- 2001:db8::2 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1011ms
rtt min/avg/max/mdev = 0.051/0.066/0.082/0.015 ms
```

</details>

Both rules applied without being asked, and the route it derived is written the
same way. The address you type and the address the machine displays are the same
128 bits, and the shortening is presentation only, exactly as dotted decimal was
in topic 05.

Notice also `2001:db8::/64` in the route table and `fe80::/64` underneath it. The
prefix length works the way it did for IPv4: a number of leading bits that name
the network. Nothing about the mask concept changed, only its size.

<details class="deeper">
<summary>If you already work on networks: why your tools rewrite addresses you typed correctly</summary>

RFC 4291 permits more than one correct spelling of the same address, and that
turned out to be a problem for anyone comparing addresses as text: log searches
miss entries, access lists have gaps, and two configuration lines that mean the
same thing do not look the same.

RFC 5952 exists to settle it. It recommends a single canonical form and its rules
are the ones your tools apply. Use lower case for the hex digits. Do not shorten a
single zero field to `::`, because writing `0` is no longer and the double colon
should be saved for a real run. When there is a choice of runs to compress, take
the longest, and if two runs tie, take the first.

That last rule is the one that catches people. In `2001:db8:0:0:1:0:0:1` there
are two runs of two zero fields. The canonical form compresses the first, giving
`2001:db8::1:0:0:1`, and a tool that rewrites your `2001:db8:0:0:1::1` into that
is not correcting an error. It is normalising a legal alternative.

The practical habit worth forming: let the machine print the address and copy
what it printed. Comparing addresses you typed against addresses a tool produced
is how a firewall rule ends up not matching traffic it was written for.

</details>

## The address nobody configured

Every capture in this track has shown an `fe80::` address that no command
created. That is a link-local address, IPv6 configures one on every interface
that comes up, and it is not optional.

The prefix is `fe80::/10`, and in practice everything you meet uses `fe80::/64`
with the remaining 54 bits of the prefix zero. Its scope is one segment. Routers
do not forward it, which makes it the IPv6 counterpart of the 169.254 range from
the previous topic, except that IPv6 hosts have one whether or not anything else
worked.

Where does the rest of the address come from? On the two-host topology this track
uses, from the MAC address, by a procedure worth doing once by hand.

The interface has MAC `02:00:00:00:01:01`. The capture shows its link-local
address as `fe80::ff:fe00:101`. Four steps connect them.

| Step | Result |
| --- | --- |
| Split the 48 bit MAC in half | `02:00:00` and `00:01:01` |
| Insert `ff:fe` between the halves, making 64 bits | `02:00:00:ff:fe:00:01:01` |
| Invert the universal/local bit, the one worth 2 in the first byte | `00:00:00:ff:fe:00:01:01` |
| Write as four hex fields, prepend `fe80::` | `fe80::00ff:fe00:0101` |

Apply the shortening rules to that last line and you get `fe80::ff:fe00:101`,
which is exactly what the machine reported. The `ff:fe` in the middle is the
signature: an address with those four hex digits sitting at that position was
almost certainly built from a MAC address.

That procedure is EUI-64, and it has a consequence covered in the panel below.

The other thing link-local addresses are for is finding neighbours, and IPv6 does
not use ARP for it.

<details class="predict">
<summary>One host pings another on the same cable. IPv6 has no ARP, so what does it send first, and who is it addressed to?</summary>

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology two-hosts
# IPv6 has no ARP. watch what it uses instead
$ ip -n h1 addr add 2001:db8::1/64 dev h1eth0
$ ip -n h2 addr add 2001:db8::2/64 dev h2eth0
$ sleep 3
$ (ip netns exec h1 timeout 7 tcpdump -i h1eth0 -n -e icmp6 > /tmp/nd.txt 2>/dev/null &)
$ sleep 2
$ ip netns exec h1 ping -c 1 2001:db8::2 > /dev/null 2>&1
$ sleep 6
$ cat /tmp/nd.txt
20:52:12.793770 02:00:00:00:01:01 > 33:33:ff:00:00:02, ethertype IPv6 (0x86dd), length 86: 2001:db8::1 > ff02::1:ff00:2: ICMP6, neighbor solicitation, who has 2001:db8::2, length 32
20:52:12.793793 02:00:00:00:01:02 > 02:00:00:00:01:01, ethertype IPv6 (0x86dd), length 86: 2001:db8::2 > 2001:db8::1: ICMP6, neighbor advertisement, tgt is 2001:db8::2, length 32
20:52:12.793797 02:00:00:00:01:01 > 02:00:00:00:01:02, ethertype IPv6 (0x86dd), length 118: 2001:db8::1 > 2001:db8::2: ICMP6, echo request, id 35, seq 1, length 64
20:52:12.793803 02:00:00:00:01:02 > 02:00:00:00:01:01, ethertype IPv6 (0x86dd), length 118: 2001:db8::2 > 2001:db8::1: ICMP6, echo reply, id 35, seq 1, length 64
20:52:14.094469 02:00:00:00:01:01 > 33:33:00:00:00:02, ethertype IPv6 (0x86dd), length 70: fe80::ff:fe00:101 > ff02::2: ICMP6, router solicitation, length 16
20:52:14.094482 02:00:00:00:01:02 > 33:33:00:00:00:02, ethertype IPv6 (0x86dd), length 70: fe80::ff:fe00:102 > ff02::2: ICMP6, router solicitation, length 16

$ ip -n h1 -6 neigh show
2001:db8::2 dev h1eth0 lladdr 02:00:00:00:01:02 REACHABLE 
fe80::ff:fe00:102 dev h1eth0 lladdr 02:00:00:00:01:02 DELAY 
```

</details>

A neighbour solicitation, carried in ICMPv6 rather than in its own ethertype, and
addressed to `ff02::1:ff00:2` rather than to a broadcast. That destination is a
solicited-node multicast address, derived from the last 24 bits of the address
being looked for, and the Ethernet destination `33:33:ff:00:00:02` is the
multicast MAC that goes with it.

The difference from ARP is worth holding on to. An ARP request is a broadcast, so
every machine on the segment has to look at it and decide it is not interested. A
neighbour solicitation goes to a multicast group that only a small number of
machines have joined, so most interfaces filter it out in hardware and never
interrupt their own processor. Same job, considerably less noise, and the
neighbour table it fills in reads exactly like the IPv4 one.

<details class="deeper">
<summary>If you already work on networks: why your own machine's address probably does not match that derivation</summary>

Work through the EUI-64 steps on a laptop and there is a fair chance the answer
comes out wrong. That is not an error in the procedure. It is a deliberate change
made because of what the procedure implies.

An interface identifier derived from a MAC address is stable and globally unique,
and it is carried in every packet the machine sends. So a laptop taking that
identifier to a coffee shop, an office and a hotel presents the same last 64 bits
on three different networks, and anyone observing them can link the three
together. The network prefix changes and the tracking token does not.

Two mechanisms replaced it. RFC 8981 defines temporary addresses with randomised
interface identifiers, generated alongside the stable one, deprecated after
roughly a day and replaced. Outbound connections use the temporary address, so
the identifier a remote server sees changes regularly. RFC 7217 addresses the
other half: it generates a stable identifier that is different for every network
the machine joins, so the address stays constant while you are on one network,
which servers and firewall rules need, and reveals nothing when you move to
another.

Most desktop and mobile operating systems now do both, which is why a machine
frequently holds several IPv6 addresses on one interface at once: a link-local, a
stable global one, and one or more temporary ones in various states of expiry.

The capture on this page shows a plain EUI-64 address because the namespace has
no router advertisements and the kernel's default generation mode applies. That
makes the derivation visible, which is the reason to show it, and it is not what
your own machine is likely doing.

</details>

## Both at once, and the ways off IPv4

IPv6 is not backward compatible with IPv4. An IPv6 host cannot speak to an IPv4
host by trying harder, because the header formats and the addresses are different
sizes. So the transition needs mechanisms, and the objective names three.

**Dual stack** is the main one and it is exactly what it sounds like: both
protocols configured on the same interface, both working, and the application
choosing per connection.

<details class="predict">
<summary>One interface, given both an IPv4 address and an IPv6 address. How many of them work?</summary>

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology two-hosts
# one interface, both address families, at the same time
$ ip -n h1 addr add 10.0.0.1/24 dev h1eth0
$ ip -n h2 addr add 10.0.0.2/24 dev h2eth0
$ ip -n h1 addr add 2001:db8::1/64 dev h1eth0
$ ip -n h2 addr add 2001:db8::2/64 dev h2eth0
$ sleep 2
$ ip -n h1 -brief addr show
lo               UNKNOWN        127.0.0.1/8 ::1/128 
h1eth0@if3       UP             10.0.0.1/24 2001:db8::1/64 fe80::ff:fe00:101/64 
$ ip netns exec h1 ping -c 1 10.0.0.2
PING 10.0.0.2 (10.0.0.2) 56(84) bytes of data.
64 bytes from 10.0.0.2: icmp_seq=1 ttl=64 time=0.063 ms

--- 10.0.0.2 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 0.063/0.063/0.063/0.000 ms
$ ip netns exec h1 ping -c 1 2001:db8::2
PING 2001:db8::2 (2001:db8::2) 56 data bytes
64 bytes from 2001:db8::2: icmp_seq=1 ttl=64 time=0.051 ms

--- 2001:db8::2 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 0.051/0.051/0.051/0.000 ms
```

</details>

Both, independently, with no interaction between them. Read the `ip -brief addr`
line and the interface is carrying three addresses at once: an IPv4 address, an
IPv6 global address, and the link-local that arrived on its own. The two pings
take entirely separate paths through the stack and neither knows the other
exists.

That independence is the strength and the weakness. Nothing is translated, so
nothing is lost, and a dual stack network is two networks that happen to share
cabling. Both need addressing, both need routing, both need firewall rules, and a
mistake in one is invisible from the other. The classic symptom is a site that
loads slowly for some users, because their machines prefer IPv6, the IPv6 path is
broken, and they are waiting for it to fail before falling back.

**Tunnelling** carries one protocol inside the other, so IPv6 traffic crosses an
IPv4-only network wrapped in IPv4 packets. It is what you use when the network
between two IPv6 islands has not been upgraded, and its costs are the ones any
tunnel has: another header inside the same frame, and a path that is harder to
troubleshoot because the visible addresses are not the real endpoints.

**NAT64** translates rather than encapsulating. An IPv6-only client can reach an
IPv4-only server through a translator that rewrites between the two, usually
paired with DNS64, which synthesises IPv6 answers for names that only have IPv4
addresses. This is how IPv6-only mobile networks reach the parts of the internet
that never moved.

The right way to hold the three: dual stack when you control both ends and can
run both, tunnelling when the network in between is the obstacle, NAT64 when one
end simply does not speak IPv6 and never will.

<details class="deeper">
<summary>If you already work on networks: why NAT is not the answer, and why NAT66 exists anyway</summary>

The obvious question, having spent the previous topic on NAT, is why IPv6 does
not simply keep it. There is enough address space that it is unnecessary, but
unnecessary and undesirable are different claims, and the second one is the
interesting one.

NAT breaks the assumption that an address means the same thing everywhere. Any
protocol that carries an address inside its payload gets it wrong, which is why
FTP, SIP and various peer to peer protocols need specific helpers in the NAT
device. Inbound connections stop working without explicit configuration, which is
why running a service at home is a project. And the device holds state for every
conversation, so it is a thing that can fill up, and it is a single point of
failure that a router forwarding packets statelessly is not.

IPv6 gives every device a globally unique address, so none of that is needed. End
to end addressing returns, and what decides whether a connection is allowed goes
back to being a firewall rule, which is a policy statement rather than a side
effect of running out of numbers.

The part worth knowing anyway: NAT66 and NPTv6 exist, and people use them.
Usually for provider independence, so that renumbering when you change ISP
touches the translator rather than every device. Opinion on whether that is a
reasonable trade is genuinely divided, and the argument has not ended. For the
exam, the position to hold is that NAT in IPv6 is a choice made for specific
reasons and never a necessity, which is the opposite of its role in IPv4.

Unique local addresses, from RFC 4193, are the other thing people reach for when
they want the IPv4 private range feeling. The prefix is `fc00::/7`, and in
practice the half that is defined for use is `fd00::/8` with a random 40 bit
identifier after it. They are legitimate for networks that genuinely should not be
globally reachable, and they are not a substitute for global addresses on machines
that need to reach the internet.

</details>

## Across platforms

The panel above predicted that working the EUI-64 steps backwards on a real
machine would probably fail, because most systems stopped generating interface
identifiers that way. Two real machines, to check.

| Task | Linux | Windows | macOS |
| --- | --- | --- | --- |
| List the IPv6 addresses | `ip -6 addr` | `Get-NetIPAddress -AddressFamily IPv6` | `ifconfig en0` |
| Scope a link-local address | `%eth0`, named | `%14`, a zone index | `%en0`, named |
| See how the identifier was made | look for `ff:fe` in it | the `SuffixOrigin` column | the `secured` flag |

```powershell
# Microsoft Windows Server 2025 Datacenter, version 10.0.26100.0
> Get-NetIPAddress -AddressFamily IPv6 | Format-Table InterfaceAlias, IPAddress, PrefixLength, SuffixOrigin, AddressState -AutoSize
InterfaceAlias              IPAddress                    PrefixLength SuffixOrigin AddressState
--------------              ---------                    ------------ ------------ ------------
vEthernet (nat)             fe80::b11d:632d:c090:61c7%11           64         Link    Preferred
Ethernet 3                  fe80::601e:c935:937a:4b13%14           64         Link    Preferred
Loopback Pseudo-Interface 1 ::1                                   128    WellKnown    Preferred

# The same addresses through the tool the exam names, with the zone index
> ipconfig | Select-String -Pattern "IPv6 Address"
   Link-local IPv6 Address . . . . . : fe80::601e:c935:937a:4b13%14
   Link-local IPv6 Address . . . . . : fe80::b11d:632d:c090:61c7%11
```

Neither link-local address contains `ff:fe`. `fe80::601e:c935:937a:4b13` has no
MAC address hidden in it, and Windows says so in the `SuffixOrigin` column:
`Link` rather than anything mentioning the hardware. The identifier is generated
per interface and per network, which is the RFC 7217 behaviour rather than the
RFC 4291 one.

The `%14` on the end is the zone index, and it is Windows doing what the
`%interface` suffix does on Linux. Same idea, numbered rather than named, and it
is why a link-local address copied off a Windows machine has a number on the end
that means nothing anywhere else.

macOS says the same thing in one word.

```bash
# macOS 26.5.2, arm64
$ ifconfig en0 | grep -E "inet6 "
	inet6 fe80::1404:26e8:479c:9da%en0 prefixlen 64 secured scopeid 0x7 

# Whether this machine can reach the IPv6 internet at all
$ netstat -rn -f inet6 | head -6
Routing tables

Internet6:
Destination                             Gateway                                 Flags               Netif Expire
default                                 fe80::%utun0                            UGcIg               utun0       
default                                 fe80::%utun1                            UGcIg               utun1       
```

`secured` is Apple's marker for an interface identifier generated the RFC 7217
way. Again no `ff:fe`, again nothing recoverable about the hardware.

The second command is a reminder of how much of this is theoretical on a given
machine. That Mac's only IPv6 default routes point at tunnel interfaces, so
there is no native IPv6 on the network it is attached to. A machine can hold
correct IPv6 addresses, follow every rule on this page, and still have nowhere
to send an IPv6 packet.


## Prove it

You have this when you can move between the long form and the short form in both
directions, without a tool.

Shorten these three, applying both rules and the once-only restriction:

```
2001:0db8:0000:0000:0000:ff00:0042:8329
fe80:0000:0000:0000:0204:61ff:fe9d:f156
2001:0db8:0000:0001:0000:0000:0000:0001
```

Then expand these two back to all eight fields:

```
2001:db8::8a2e:370:7334
::1
```

The third one in the first list is the interesting one, because it has two runs
of zeros and only one of them may be compressed. Decide which before reading RFC
5952's rule, then check whether you agree with it.

Check any of them by assigning the address on a machine and reading it back, the
way the capture above does:

```bash
ip addr add <your answer>/64 dev lo
ip -6 addr show lo
ip addr del <your answer>/64 dev lo
```

If the machine prints something different from what you typed, the difference is
the lesson.

## What trips people up

### 1. Using the double colon twice

`2001:db8::1::1` is invalid, not merely bad style. With two of them there is no
way to work out how many zero fields belong to each, so the address cannot be
expanded to 128 bits. One per address, always.

### 2. Dropping trailing zeros in a field

The rule removes leading zeros only. The field `db80` is not `db8`, and the field
`1000` is not `1`. Getting this backwards changes the address, which is why the
exam offers both spellings as options.

### 3. Assuming an fe80 address means something is wrong

In IPv4, a link-local address means DHCP failed. In IPv6, every interface has a
link-local address all the time, working or not, and a machine with a perfectly
good global address still has one. The two situations look similar and mean
opposite things.

### 4. Assuming a link-local address is enough on its own

A link-local address is unique on one segment and nowhere else, so the same
address can legitimately exist on two of a machine's interfaces. That is what the
`%interface` suffix is for.

The reason this bites people is that it works fine until it does not.

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology two-hosts
$ sleep 3
# the same link-local address, asked for with and without naming an interface
$ ip netns exec h1 ping -c 1 -W 1 fe80::ff:fe00:102
PING fe80::ff:fe00:102 (fe80::ff:fe00:102) 56 data bytes
64 bytes from fe80::ff:fe00:102%h1eth0: icmp_seq=1 ttl=64 time=0.055 ms

--- fe80::ff:fe00:102 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 0.055/0.055/0.055/0.000 ms
$ echo "exit status $?"
exit status 0
$ ip netns exec h1 ping -c 1 -W 1 fe80::ff:fe00:102%h1eth0
PING fe80::ff:fe00:102%h1eth0 (fe80::ff:fe00:102%h1eth0) 56 data bytes
64 bytes from fe80::ff:fe00:102%h1eth0: icmp_seq=1 ttl=64 time=0.017 ms

--- fe80::ff:fe00:102%h1eth0 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 0.017/0.017/0.017/0.000 ms
$ echo "exit status $?"
exit status 0
```

One interface, so there is nothing ambiguous, and the bare address is accepted.
Notice that ping put the scope back in its reply line anyway. Do the same thing on
a router or a laptop that is on wifi and ethernet at once and the kernel has no
basis for choosing, so the suffix stops being optional. Writing it every time
costs nothing and saves the day you are on the multi-interface machine.

### 5. Treating dual stack as a fallback arrangement

Both protocols run all the time and neither is a backup for the other. A machine
does not use IPv4 because IPv6 failed; it picks per connection, usually
preferring IPv6, and a broken IPv6 path produces a delay rather than a clean
switch.

### 6. Expecting to subnet below a /64

Almost every IPv6 network is a /64, and address autoconfiguration depends on the
interface identifier being 64 bits. Carving a /64 into /68s to save addresses is
applying IPv4 instincts to a problem that no longer exists, and it stops
autoconfiguration working.

## Work it through

A company is adding IPv6 to a network that currently runs IPv4 with NAT. Their
provider has allocated them `2001:db8:acad::/48`. Somebody asks how many networks
that gives them and how big each one is.

Start with the /48 and the /64, because everything follows from those two
numbers. The provider allocated 48 bits. Subnets are /64. The difference is 16
bits, which is the subnet identifier, so they have 2 to the power 16 networks,
which is 65,536.

Now the second half of the question, and this is where IPv4 habits mislead. Each
of those /64s has 64 host bits, so 2 to the power 64 addresses, which is roughly
18 quintillion. Nobody sizes a /64 against a machine count, because no plausible
machine count changes the answer.

So the planning conversation is entirely different from the one in topic 06.
There is no arithmetic to do about how many machines fit. What there is instead
is a numbering scheme: which subnet identifier belongs to which site, which
building, which VLAN. Organisations typically encode structure into those 16 bits
deliberately, so that `2001:db8:acad:0012::/64` can be read as a particular VLAN
in a particular place, and firewall rules can be written against ranges of subnet
identifiers rather than against a list.

The other thing to settle early is that both protocols now need everything. Two
sets of routes, two sets of firewall rules, two sets of monitoring. A rule that
blocks something over IPv4 and was never written for IPv6 is a hole, and it is a
hole that the IPv4 rule's existence hides, because the intent looks covered.

Nothing about the address plan is hard. Remembering that every control needs
doing twice is the part that gets missed.

## Try it

**Look at your own addresses.** Run `ip -6 addr` on Linux, `ifconfig` on macOS or
`ipconfig` on Windows, and count how many IPv6 addresses each interface has.
Expect at least a link-local. On a network with IPv6 you will probably see a
global address and one or more temporary ones, which is the privacy mechanism from
the panel above, visible on a real machine.

**Work the EUI-64 derivation backwards.** Take your machine's link-local address.
If it contains `ff:fe` in the middle, run the four steps in reverse and see
whether you arrive at the interface's MAC address. If it does not contain
`ff:fe`, your system is using an opaque identifier instead, which is the answer
the panel predicted.

**Find out whether you have IPv6 at all.** Open a site that reports it, or run
`ping -6 ipv6.google.com` and see whether it resolves and answers. A surprising
number of home connections have working IPv6 that nobody has ever looked at, and
a similar number have it half configured, which is worth knowing before it
becomes a fault.

## Check yourself

<details class="qa">
<summary>Shorten 2001:0db8:0000:0000:0000:ff00:0042:8329 as far as the rules allow.</summary>

`2001:db8::ff00:42:8329`.

Leading zeros go from every field: `0db8` becomes `db8`, `0042` becomes `42`. The
three consecutive all-zero fields are the only run, so they collapse to `::`.

`ff00` and `8329` are unchanged, because neither has a leading zero.

</details>

<details class="qa">
<summary>Why is 2001:db8::1::4 invalid?</summary>

Because the double colon appears twice, and an address may contain it at most
once.

Each `::` stands for an unknown number of all-zero fields. With two of them the
address cannot be expanded, since there is no way to decide how many of the
missing fields belong to the first and how many to the second. One occurrence is
unambiguous because the count is whatever makes the total eight.

</details>

<details class="qa">
<summary>An interface has fe80::20c:29ff:fe4a:1b2c. What can you tell about it, and what is it not evidence of?</summary>

It is a link-local address, valid on that segment only, and every IPv6 interface
has one whether or not anything else is configured.

The `ff:fe` sitting in the middle of the interface identifier says it was
generated from the MAC address by the EUI-64 procedure, so the MAC can be
recovered from it: split around the `ff:fe`, drop them, and invert the seventh bit
of the first byte.

What it is not evidence of is a fault. Unlike a 169.254 address in IPv4, an fe80
address does not mean autoconfiguration failed. It means the interface came up.

</details>

<details class="qa">
<summary>A site is allocated 2001:db8:1234::/48 and uses /64 subnets. How many subnets, and how many addresses in each?</summary>

Sixteen bits sit between the /48 and the /64, so 2 to the power 16, which is
65,536 subnets.

Each /64 leaves 64 bits for the interface identifier, so 2 to the power 64
addresses, about 18 quintillion.

The second number is not a planning input. A /64 is the standard subnet size
whether it holds three machines or three thousand, and the design work is in
deciding what the 16 bits of subnet identifier mean.

</details>

<details class="qa">
<summary>An IPv6-only phone loads a website that has no IPv6 address at all. Which mechanism made that work, and what did it need alongside it?</summary>

NAT64, translating between the phone's IPv6 and the server's IPv4.

Alongside it, DNS64. The name has no AAAA record, so a plain lookup would return
nothing usable. DNS64 synthesises one, built from the IPv4 address and the
translator's prefix, so the phone gets an IPv6 address to connect to and the
traffic is translated at the NAT64 device.

Dual stack would not help here, because the phone has no IPv4 address. Tunnelling
would not either, because the problem is that the server does not speak IPv6, not
that the network in between does not.

</details>

<details class="qa">
<summary>Why does a laptop typically hold several IPv6 addresses on one interface, and what is each one for?</summary>

Because they have different jobs and different lifetimes.

The link-local, beginning `fe80`, is for talking to things on the same segment
including the router, and is always present.

A stable global address is what inbound connections and firewall rules need,
generated so that it stays the same on that network but differs on other
networks, per RFC 7217.

One or more temporary global addresses, per RFC 8981, are used as the source for
outbound connections and are replaced regularly, so a remote server sees a
changing identifier rather than one that follows the machine around.

Seeing several is normal, and seeing only a link-local means the network is not
providing IPv6.

</details>

## References

- [RFC 4291, IP Version 6 Addressing Architecture](https://www.rfc-editor.org/rfc/rfc4291) - IETF, the text representation rules and the link-local prefix. Accessed 2026-08-10.
- [RFC 5952, A Recommendation for IPv6 Address Text Representation](https://www.rfc-editor.org/rfc/rfc5952) - IETF, the canonical form tools apply. Accessed 2026-08-10.
- [RFC 4193, Unique Local IPv6 Unicast Addresses](https://www.rfc-editor.org/rfc/rfc4193) - IETF, the fc00::/7 range. Accessed 2026-08-10.
- [RFC 3849, IPv6 Address Prefix Reserved for Documentation](https://www.rfc-editor.org/rfc/rfc3849) - IETF, the source of the 2001:db8:: addresses used throughout this page. Accessed 2026-08-10.
- [RFC 4213, Basic Transition Mechanisms for IPv6 Hosts and Routers](https://www.rfc-editor.org/rfc/rfc4213) - IETF, dual stack and tunnelling. Accessed 2026-08-10.
- [RFC 6146, Stateful NAT64](https://www.rfc-editor.org/rfc/rfc6146) - IETF. Accessed 2026-08-10.
- [RFC 8981, Temporary Address Extensions for SLAAC in IPv6](https://www.rfc-editor.org/rfc/rfc8981) - IETF, which obsoletes RFC 4941. Accessed 2026-08-10.
- [RFC 7217, Semantically Opaque Interface Identifiers with SLAAC](https://www.rfc-editor.org/rfc/rfc7217) - IETF, stable per-network identifiers. Accessed 2026-08-10.
- [Free Pool of IPv4 Address Space Depleted](https://www.nro.net/ipv4-free-pool-depleted/) - Number Resource Organization, the 3 February 2011 announcement. Accessed 2026-08-10.

**Where the output came from.** All three captured blocks were produced on the
two-host namespace topology, `blog/scripts/topologies/two-hosts.sh`, through
`blog/scripts/netlab.sh`. The addresses used are from `2001:db8::/32`, which RFC
3849 reserves for documentation, so nothing on this page names a real network.
The EUI-64 derivation is checkable against the capture because that topology
fixes its MAC addresses rather than letting the kernel generate them, and the
panel under it explains why a reader's own machine will probably not match.

**If you also work on Linux.** The Linux+ track touches IPv6 only in passing,
because its exam does not weight it. There is no counterpart page worth sending
you to for this one.
