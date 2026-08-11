---
title: "Unicast, multicast, anycast and broadcast"
description: "One packet and four different answers to who gets it. What each delivery type means on the wire, where the boundary of a broadcast actually sits, how multicast avoids sending the same thing twice, and the one that puts a single address in several countries at once."
deck: "One packet, and four answers to who gets this"
track: "network-plus"
level: "working"
order: 160
objectives:
  - "Name the four delivery types and say who receives each"
  - "Identify a delivery type from a destination address"
  - "Say where a broadcast stops and what defines that boundary"
  - "Explain what multicast saves and what has to cooperate for it to work"
  - "Explain how one anycast address can exist in many places at once"
prerequisites: ["how-a-switch-learns"]
tags: ["network-plus", "networking", "switching"]
updated: 2026-08-10
draft: false
examObjectives:
  - exam: "n10-009"
    domain: "1.0"
    objective: "1.4"
sources:
  - title: "RFC 919, Broadcasting Internet Datagrams"
    url: "https://www.rfc-editor.org/rfc/rfc919"
    publisher: "IETF"
    accessed: 2026-08-10
    tier: 1
  - title: "RFC 1112, Host Extensions for IP Multicasting"
    url: "https://www.rfc-editor.org/rfc/rfc1112"
    publisher: "IETF"
    accessed: 2026-08-10
    tier: 1
  - title: "RFC 4786, Operation of Anycast Services"
    url: "https://www.rfc-editor.org/rfc/rfc4786"
    publisher: "IETF"
    accessed: 2026-08-10
    tier: 1
  - title: "IANA IPv4 Multicast Address Space Registry"
    url: "https://www.iana.org/assignments/multicast-addresses/multicast-addresses.xhtml"
    publisher: "IANA"
    accessed: 2026-08-10
    tier: 1
symptoms:
  - symptom: "Traffic for one machine is reaching every machine on the segment"
    anchor: "broadcast-and-where-it-stops"
  - symptom: "Video or discovery traffic floods a network that is not expecting it"
    anchor: "multicast-and-the-cooperation-it-needs"
---

> **Before you read.** A machine sends a packet. Depending on one field in the
> header, that packet reaches exactly one machine, every machine on the segment,
> some self-selected subset of machines, or the nearest of several machines
> sharing an address in different cities.
>
> Nothing else about the packet changes. The same wire, the same switch, the
> same protocol.
>
> **What is that field, and what are the four answers?**

The previous topic covered what a switch does with a frame once it has one. This
one is about the four things a destination address can mean, because a switch's
behaviour is different for each and only one of them is the case people picture.

### Some words you will need

<dl class="terms">
<dt>unicast</dt>
<dd>One sender, one recipient. The default and the overwhelming majority of traffic.</dd>
<dt>broadcast</dt>
<dd>One sender, everybody on the segment, whether they want it or not.</dd>
<dt>multicast</dt>
<dd>One sender, and whoever has asked to receive that particular group.</dd>
<dt>anycast</dt>
<dd>One address configured in several places, and the routing system delivers to the nearest.</dd>
<dt>broadcast domain</dt>
<dd>The set of machines a broadcast reaches. The boundary is a router or a VLAN.</dd>
<dt>group</dt>
<dd>A multicast address that receivers subscribe to, rather than a machine that owns it.</dd>
</dl>

## What breaks without this

**You cannot explain why a network gets slower as it grows.** Broadcast traffic
reaches every machine and every machine has to look at it. The cost scales with
the number of machines and nothing about it is visible from any single one.

**Multicast arrives and floods everything.** Cameras, media systems and discovery
protocols use it, and on a switch that has not been told to be careful it behaves
like a broadcast. That surprises people at the worst possible moment.

**You misread a capture.** Destination addresses tell you the delivery type at a
glance, and reading `ff:ff:ff:ff:ff:ff` as just another address means missing what
kind of conversation you are looking at.

## Four answers, and one field

The delivery type is not a setting. It is a property of the destination address,
and both layers carry it.

| Type | IPv4 destination looks like | MAC destination looks like | Who receives it |
| --- | --- | --- | --- |
| Unicast | Any ordinary address | The recipient's own address | One machine |
| Broadcast | The last address in the subnet, or 255.255.255.255 | `ff:ff:ff:ff:ff:ff` | Everything on the segment |
| Multicast | 224.0.0.0 through 239.255.255.255 | Starts `01:00:5e` | Everything that joined the group |
| Anycast | An ordinary address, configured in several places | The nearest holder's address | The nearest one, only |

<figure class="learn-figure">
<svg viewBox="0 0 720 314" role="img" aria-labelledby="delivery-title" style="width:100%;height:auto;">
<title id="delivery-title">The four delivery types drawn on the same sender and four receivers, showing which receivers get a copy in each case</title>
<defs>
<marker id="deliver-arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse">
<path d="M 0 0 L 10 5 L 0 10 z" fill="currentColor"/>
</marker>
</defs>
<g font-family="ui-monospace, monospace" fill="currentColor">
<rect x="12" y="12" width="340" height="132" rx="4" fill="currentColor" fill-opacity="0.03" stroke="currentColor" stroke-opacity="0.3"/>
<text x="24" y="32" font-size="11.5">unicast</text>
<text x="24" y="48" font-size="10" fill-opacity="0.75">an ordinary destination address</text>
<path d="M 41 76 V 58 H 179" stroke="currentColor" stroke-width="1.5" fill="none"/>
<line x1="179" y1="58" x2="179" y2="78" stroke="currentColor" stroke-width="1.5" marker-end="url(#deliver-arrow)"/>
<rect x="22" y="76" width="38" height="32" rx="3" fill="currentColor" fill-opacity="0.14" stroke="currentColor" stroke-opacity="0.55"/>
<text x="41" y="97" text-anchor="middle" font-size="11">S</text>
<circle cx="124" cy="94" r="14" fill="currentColor" fill-opacity="0.04" stroke="currentColor" stroke-opacity="0.4" stroke-dasharray="4 3"/>
<text x="124" y="98" text-anchor="middle" font-size="10" fill-opacity="0.7">1</text>
<circle cx="179" cy="94" r="14" fill="currentColor" fill-opacity="0.2" stroke="currentColor" stroke-width="1.6"/>
<text x="179" y="98" text-anchor="middle" font-size="10">2</text>
<circle cx="234" cy="94" r="14" fill="currentColor" fill-opacity="0.04" stroke="currentColor" stroke-opacity="0.4" stroke-dasharray="4 3"/>
<text x="234" y="98" text-anchor="middle" font-size="10" fill-opacity="0.7">3</text>
<circle cx="289" cy="94" r="14" fill="currentColor" fill-opacity="0.04" stroke="currentColor" stroke-opacity="0.4" stroke-dasharray="4 3"/>
<text x="289" y="98" text-anchor="middle" font-size="10" fill-opacity="0.7">4</text>
<text x="24" y="130" font-size="10" fill-opacity="0.8">one address, and one recipient</text>
<rect x="368" y="12" width="340" height="132" rx="4" fill="currentColor" fill-opacity="0.03" stroke="currentColor" stroke-opacity="0.3"/>
<text x="380" y="32" font-size="11.5">broadcast</text>
<text x="380" y="48" font-size="10" fill-opacity="0.75">destination ff:ff:ff:ff:ff:ff</text>
<path d="M 397 76 V 58 H 645" stroke="currentColor" stroke-width="1.5" fill="none"/>
<g stroke="currentColor" stroke-width="1.5" marker-end="url(#deliver-arrow)">
<line x1="480" y1="58" x2="480" y2="78"/>
<line x1="535" y1="58" x2="535" y2="78"/>
<line x1="590" y1="58" x2="590" y2="78"/>
<line x1="645" y1="58" x2="645" y2="78"/>
</g>
<rect x="378" y="76" width="38" height="32" rx="3" fill="currentColor" fill-opacity="0.14" stroke="currentColor" stroke-opacity="0.55"/>
<text x="397" y="97" text-anchor="middle" font-size="11">S</text>
<circle cx="480" cy="94" r="14" fill="currentColor" fill-opacity="0.2" stroke="currentColor" stroke-width="1.6"/>
<text x="480" y="98" text-anchor="middle" font-size="10">1</text>
<circle cx="535" cy="94" r="14" fill="currentColor" fill-opacity="0.2" stroke="currentColor" stroke-width="1.6"/>
<text x="535" y="98" text-anchor="middle" font-size="10">2</text>
<circle cx="590" cy="94" r="14" fill="currentColor" fill-opacity="0.2" stroke="currentColor" stroke-width="1.6"/>
<text x="590" y="98" text-anchor="middle" font-size="10">3</text>
<circle cx="645" cy="94" r="14" fill="currentColor" fill-opacity="0.2" stroke="currentColor" stroke-width="1.6"/>
<text x="645" y="98" text-anchor="middle" font-size="10">4</text>
<text x="380" y="130" font-size="10" fill-opacity="0.8">everything on the segment takes a copy</text>
<rect x="12" y="170" width="340" height="132" rx="4" fill="currentColor" fill-opacity="0.03" stroke="currentColor" stroke-opacity="0.3"/>
<text x="24" y="190" font-size="11.5">multicast</text>
<text x="24" y="206" font-size="10" fill-opacity="0.75">destination in 224.0.0.0 to 239.255.255.255</text>
<path d="M 41 234 V 216 H 234" stroke="currentColor" stroke-width="1.5" fill="none"/>
<g stroke="currentColor" stroke-width="1.5" marker-end="url(#deliver-arrow)">
<line x1="124" y1="216" x2="124" y2="236"/>
<line x1="234" y1="216" x2="234" y2="236"/>
</g>
<rect x="22" y="234" width="38" height="32" rx="3" fill="currentColor" fill-opacity="0.14" stroke="currentColor" stroke-opacity="0.55"/>
<text x="41" y="255" text-anchor="middle" font-size="11">S</text>
<circle cx="124" cy="252" r="14" fill="currentColor" fill-opacity="0.2" stroke="currentColor" stroke-width="1.6"/>
<text x="124" y="256" text-anchor="middle" font-size="10">1</text>
<circle cx="179" cy="252" r="14" fill="currentColor" fill-opacity="0.04" stroke="currentColor" stroke-opacity="0.4" stroke-dasharray="4 3"/>
<text x="179" y="256" text-anchor="middle" font-size="10" fill-opacity="0.7">2</text>
<circle cx="234" cy="252" r="14" fill="currentColor" fill-opacity="0.2" stroke="currentColor" stroke-width="1.6"/>
<text x="234" y="256" text-anchor="middle" font-size="10">3</text>
<circle cx="289" cy="252" r="14" fill="currentColor" fill-opacity="0.04" stroke="currentColor" stroke-opacity="0.4" stroke-dasharray="4 3"/>
<text x="289" y="256" text-anchor="middle" font-size="10" fill-opacity="0.7">4</text>
<text x="24" y="288" font-size="10" fill-opacity="0.8">1 and 3 joined. 2 and 4 never asked</text>
<rect x="368" y="170" width="340" height="132" rx="4" fill="currentColor" fill-opacity="0.03" stroke="currentColor" stroke-opacity="0.3"/>
<text x="380" y="190" font-size="11.5">anycast</text>
<text x="380" y="206" font-size="10" fill-opacity="0.75">one ordinary address, configured in four places</text>
<path d="M 397 234 V 216 H 480" stroke="currentColor" stroke-width="1.5" fill="none"/>
<line x1="480" y1="216" x2="480" y2="236" stroke="currentColor" stroke-width="1.5" marker-end="url(#deliver-arrow)"/>
<rect x="378" y="234" width="38" height="32" rx="3" fill="currentColor" fill-opacity="0.14" stroke="currentColor" stroke-opacity="0.55"/>
<text x="397" y="255" text-anchor="middle" font-size="11">S</text>
<circle cx="480" cy="252" r="14" fill="currentColor" fill-opacity="0.2" stroke="currentColor" stroke-width="1.6"/>
<text x="480" y="256" text-anchor="middle" font-size="10">1</text>
<circle cx="535" cy="252" r="14" fill="currentColor" fill-opacity="0.1" stroke="currentColor" stroke-width="1.6"/>
<text x="535" y="256" text-anchor="middle" font-size="10">2</text>
<circle cx="590" cy="252" r="14" fill="currentColor" fill-opacity="0.1" stroke="currentColor" stroke-width="1.6"/>
<text x="590" y="256" text-anchor="middle" font-size="10">3</text>
<circle cx="645" cy="252" r="14" fill="currentColor" fill-opacity="0.1" stroke="currentColor" stroke-width="1.6"/>
<text x="645" y="256" text-anchor="middle" font-size="10">4</text>
<text x="380" y="288" font-size="10" fill-opacity="0.8">all four answer to it, and routing picks one</text>
</g>
</svg>
<figcaption>The same sender and the same four receivers, four times. An arrow means a copy arrives; a dashed outline means the machine is not a candidate at all. Read the panels against each other and anycast is the odd one out: every receiver has a solid outline, because all four are configured with the address and any of them would answer, and only one arrow is drawn because the routing system picked one. Nothing in the packet made that choice, which is why anycast cannot be seen in a capture the way the other three can.</figcaption>
</figure>

The row that does not fit the pattern is anycast, and that is the whole trick of
it. There is nothing in an anycast packet that says anycast. It is an ordinary
unicast packet, and the multiplicity lives in the routing system rather than in
the address.

IPv6 changes one thing worth noting now. **It has no broadcast at all.**
Everything IPv4 used a broadcast for, IPv6 does with a multicast group, which is
why topic 08's captures showed neighbour solicitations going to `ff02::1:ff00:2`
rather than to everybody. Dropping broadcast was a deliberate design decision and
the reason is in the next section.

## Broadcast, and where it stops

A broadcast is delivered to every machine in the broadcast domain, and every one
of them has to process it far enough to decide it is not interesting.

Here is what that looks like from a machine that has nothing to do with the
conversation. h1 sends one unicast ping to h2, then one broadcast, while h3
watches.

<details class="predict">
<summary>Two packets are sent and h3 is the recipient of neither. How many does h3 receive?</summary>

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology one-switch
# one host, three ways of addressing the same segment
$ ip netns exec h1 ping -c 1 10.0.0.2 > /dev/null 2>&1
$ (ip netns exec h3 timeout 8 tcpdump -i h3eth0 -n -e -U > /tmp/d.txt 2>/dev/null &)
$ sleep 2
# unicast to h2
$ ip netns exec h1 ping -c 1 10.0.0.2 > /dev/null 2>&1
# broadcast to the whole subnet
$ ip netns exec h1 ping -c 1 -b 10.0.0.255 > /dev/null 2>&1
$ sleep 7
$ cat /tmp/d.txt
23:29:15.832005 02:00:00:00:00:01 > ff:ff:ff:ff:ff:ff, ethertype IPv4 (0x0800), length 98: 10.0.0.1 > 10.0.0.255: ICMP echo request, id 65, seq 1, length 64
```

</details>

One. The unicast to h2 never reached h3, because the switch had learned h2's port
from the earlier ping and delivered it there alone. The broadcast reached h3
because a broadcast reaches everything, and there is no learning that can prevent
that.

Read the destination on the frame that arrived: `ff:ff:ff:ff:ff:ff`, all ones. A
switch has no choice with that address. It is not a machine, no machine will ever
have it as a source, so it can never be learned, so it is flooded every single
time by definition rather than by accident.

**The boundary is a router.** A router does not forward broadcasts, which is what
makes the broadcast domain the useful unit it is. Everything on one side of the
router hears the broadcast and nothing on the other side does. A VLAN draws the
same boundary without a separate router interface, which is the next topic.

Two broadcast addresses come up and they are not the same. `255.255.255.255` is
the limited broadcast, meaning this segment, and it is never forwarded. The
directed broadcast is the last address in a specific subnet, so `10.0.0.255` for
a /24, and it names one particular network's broadcast from outside it. Forwarding
directed broadcasts was how a whole class of amplification attacks worked, so
routers stopped doing it by default a long time ago.

<details class="deeper">
<summary>If you already work on networks: what broadcast actually costs, and why IPv6 removed it</summary>

The cost of a broadcast is not the bandwidth. It is the interrupt.

A unicast frame addressed to somebody else is discarded by the receiving network
card, in hardware, without waking the processor. A broadcast cannot be. Every
machine's card accepts it, raises an interrupt, and hands it up the stack to be
examined and usually thrown away. So a broadcast costs a small amount of CPU on
every machine in the domain, and the total cost scales with the number of
machines while the sender pays nothing extra.

At small scale this is invisible. At a few thousand machines in one broadcast
domain it becomes a real tax, and it is the practical reason large flat networks
are a bad idea rather than any bandwidth argument. It is also why the advice is
always to segment, and topic 55 covers doing that deliberately.

IPv6 removed broadcast entirely for this reason. Everything that used to be a
broadcast is now a multicast to a specific group: all-nodes is `ff02::1`,
all-routers is `ff02::2`, and neighbour discovery uses a solicited-node group
derived from the address being looked for. The gain is precise. A machine's card
can be programmed to accept only the groups it has joined, so a neighbour
solicitation for somebody else is filtered in hardware and never interrupts
anything.

Compare that to ARP, which is a broadcast, so every ARP request on a segment
interrupts every machine on it to ask about one address. On a busy network that is
a continuous low-level cost that IPv6 simply does not have.

The catch is that the hardware filter is imperfect. It matches on a hash rather
than exactly, so a machine can be woken by a group it did not join. Better than
broadcast, and not free.

</details>

## Multicast, and the cooperation it needs

Multicast solves a specific problem: one sender with the same data for many
receivers, where sending it separately to each would waste the sender's bandwidth
and the network's.

A multicast address is not a machine. It is a group, and receivers join it. The
sender transmits once to the group address and the network duplicates the traffic
only where the paths to different receivers diverge.

The IPv4 range is 224.0.0.0 through 239.255.255.255, which topic 07 met as class
D. Some addresses in it are permanently assigned and worth recognising:

| Address | Group |
| --- | --- |
| 224.0.0.1 | All hosts on this segment |
| 224.0.0.2 | All routers on this segment |
| 224.0.0.5 | All OSPF routers |
| 224.0.0.9 | RIP version 2 |
| 224.0.0.251 | mDNS, which is how devices find each other on a home network |

The MAC address is derived rather than chosen. A multicast IP maps onto a MAC
starting `01:00:5e`, with the low 23 bits of the IP copied in. That mapping is
lossy, since 28 bits of group address are being squeezed into 23, so several
groups share a MAC and a machine occasionally receives a group it did not join
and discards it in software.

**Here is the part that catches people.** A switch, by default, has no idea what
multicast means. The destination address is not a unicast it has learned, so it
does the only thing it knows and floods it to every port. Multicast that was
supposed to be efficient behaves exactly like broadcast, and a few video streams
can saturate a segment that had plenty of capacity.

The fix is IGMP snooping, in the panel below, and the reason it is worth knowing
is that it is a switch feature that has to be on and correct rather than something
that happens by itself.

<details class="deeper">
<summary>If you already work on networks: IGMP snooping, and the way it fails</summary>

IGMP is how a host tells the network it wants a group. It sends a membership
report, routers listen for it, and multicast is delivered toward segments that
asked.

IGMP snooping is a switch doing something it is not strictly entitled to do:
reading those layer 3 membership messages as they pass through, and using them to
build a table of which ports have asked for which group. With that table it can
forward multicast to the ports that want it rather than flooding.

It is worth being precise that this is a layer 2 device inspecting a layer 3
protocol to make a layer 2 decision, which topic 03's panel on layer boundaries
would call exactly the cross-layer shortcut the model was supposed to prevent. It
is also enormously effective, which is why everybody does it.

The failure mode is specific and worth recognising, because it produces a fault
that looks like the opposite of what it is.

Snooping needs somebody to send periodic IGMP queries, so that memberships are
refreshed and stale ones expire. On a segment with a multicast router that
happens naturally. On a segment with no router doing multicast, which is most
office VLANs carrying cameras or audio, nobody queries. The switch's snooping
table then empties, and switches differ in what they do about it: some fall back
to flooding, some stop forwarding the group at all.

The second behaviour is the nasty one. Multicast works when it is set up, and
stops a few minutes later with no change to anything. The fix is to configure an
IGMP querier on the switch, which is a checkbox with a name almost nobody
recognises until they have met this exact fault.

So the practical summary: multicast on a switched network without snooping is
broadcast, and multicast with snooping and no querier is a timer waiting to break
something. Both are configuration rather than protocol.

</details>

## Anycast, and one address in several places

Anycast is the one that sounds impossible and turns out to be simple.

Take a service, run it in twenty data centres around the world, and give every
one of those instances the same IP address. Then have each location advertise a
route to that address into the internet's routing system. Every router now has
several possible paths to the address and picks the best one by its own ordinary
rules, which usually means the nearest.

A client sends an ordinary unicast packet. Nothing in it is special. It arrives at
whichever instance was closest to it, and a client in Frankfurt and a client in
Sydney reach different machines without knowing there is more than one.

**Nothing about anycast happens at layer 2, and nothing about it happens in the
packet.** It is entirely a routing decision, which is why the exam groups it with
delivery types and it behaves nothing like the other three.

The obvious use is DNS. The root servers are anycast, which is why there are
thirteen root server addresses and vastly more than thirteen physical servers. So
are the well known public resolvers. Content delivery networks use it for the same
reason: shorter paths, lower latency, and load spread across locations without any
client doing anything clever.

The second benefit is unplanned. A location that fails stops advertising its
route, and the routing system sends traffic to the next nearest instance
automatically. There is no failover mechanism because there is nothing to fail
over; the absence of a route is the failover.

<details class="deeper">
<summary>If you already work on networks: why anycast suits DNS and not everything</summary>

The reason anycast is everywhere in DNS and rare elsewhere is about what happens
when the routing changes underneath a conversation.

Nothing guarantees that two consecutive packets from one client reach the same
instance. Routing can change between them, and when it does the second packet
arrives somewhere with no memory of the first. For a DNS query over UDP that is
irrelevant: one packet out, one packet back, and if the routing shifts in between
the query is simply retried. The protocol was already built to tolerate that.

For a TCP connection it is fatal. The new instance has no state for the
connection, has never seen the handshake, and responds with a reset. So an anycast
TCP service depends on the routing being stable for the life of every connection,
which is usually true and is not guaranteed, and the failure appears as
occasional inexplicable resets.

That is why the natural fit is short stateless exchanges, and why anycast for
long-lived connections needs more engineering: keeping paths stable, or putting
load balancers behind the anycast address that can hand a connection off.

The other thing worth knowing is what anycast does not do. It has no idea about
load. Routing picks the topologically nearest instance, not the least busy one, so
a popular region can overwhelm its nearest site while a quieter one sits idle. Real
deployments manage that by adjusting what each site advertises, which is a routing
policy problem, and topic 22 covers the protocol that expresses it.

</details>

## Prove it

You have this when you can name the delivery type from an address without
thinking, and say what a switch does with each.

Classify these seven, and for each say who receives it:

```
10.0.0.7
10.0.0.255      (on a /24)
255.255.255.255
224.0.0.5
239.1.1.1
ff:ff:ff:ff:ff:ff
01:00:5e:00:00:05
```

Then run one command on any machine and read the answer:

```bash
# every multicast group this machine has joined, per interface
ip maddr show
```

Expect more than you thought. An ordinary desktop has joined all-hosts, usually
mDNS for device discovery, and often several more. Every one of those is a group
the network card has been told to accept, and the list is the practical answer to
what multicast means on a machine you own.

## What trips people up

### 1. Thinking a switch handles multicast intelligently by default

It does not. Without IGMP snooping a multicast address is just an address the
switch cannot find in its table, so it floods. Multicast becomes broadcast, and
efficient becomes the opposite.

### 2. Expecting a broadcast to cross a router

It does not, and that is the definition of a broadcast domain. A router is the
boundary. A VLAN draws the same boundary without a separate router.

### 3. Confusing the two broadcast addresses

`255.255.255.255` is limited, meaning this segment, and is never forwarded. The
directed broadcast is the last address of a specific subnet, such as `10.0.0.255`,
and names that network's broadcast from elsewhere. Routers stopped forwarding
directed broadcasts because of amplification attacks.

### 4. Looking for anycast in the packet

There is nothing there. An anycast packet is an ordinary unicast packet, and the
several-places-at-once part lives entirely in routing. This is why it behaves
unlike the other three.

### 5. Assuming IPv6 has a broadcast address

It does not. Every job broadcast did in IPv4 is a multicast group in IPv6, which
lets network cards filter in hardware instead of interrupting every machine.

### 6. Reading a multicast MAC as a manufacturer prefix

`01:00:5e` is not a vendor. It is the reserved prefix for IPv4 multicast, with the
low bits of the group address copied in, so a MAC starting that way tells you the
delivery type rather than who made the card.

## Work it through

A building installs sixty IP cameras. The installer confirms each camera works.
Two weeks later the office network becomes unusable every weekday at nine, and
recovers by mid-morning. The cameras are on the same VLAN as everybody's desks.

Start with what changed, because nothing about the desks changed and the cameras
have been there a fortnight.

Cameras of this kind commonly stream over multicast, which is the sensible choice:
one stream and several viewers, so multicast is exactly the problem it was
designed for. The trouble is what a switch does with it. Without IGMP snooping,
multicast is an address the switch cannot place, so every camera's stream is
flooded to every port in the broadcast domain. Sixty streams reach sixty desks
that never asked for any of them.

That explains the shape of the failure. Each desktop's network card accepts the
frames, the stack examines and discards them, and the segment carries sixty times
the traffic it should. Nine in the morning is when everybody arrives and the
recording system starts pulling streams.

Two things to check, in order. Whether the switches have IGMP snooping enabled,
and if they do, whether anything on that VLAN is sending IGMP queries. Snooping
without a querier is the failure in the panel above, and it produces intermittent
behaviour rather than steady behaviour, which fits a fault that comes and goes.

The design answer is the same one the broadcast section implies and it is worth
saying even though it is not the immediate fix. Sixty cameras and every desk in
one broadcast domain is the underlying problem, and multicast is only what
revealed it. Cameras belong in their own VLAN, which puts their traffic in its own
broadcast domain and makes the whole class of problem somebody else's.

Notice what this is not. Nothing is misconfigured on any camera, nothing is
broken on any desktop, and no single device is at fault. It is a property of the
segment.

## Try it

**List your own groups.** Run `ip maddr show` on Linux, or `netstat -g` on macOS.
Count how many multicast groups your machine has joined without you asking. mDNS
alone accounts for several.

**Watch a broadcast arrive.** On any machine, run a capture filtered to broadcast
traffic: `sudo tcpdump -i <interface> -n "ether broadcast"`. Leave it for a
minute on an office or home network. ARP requests dominate, and every one of them
interrupted every machine on your segment.

**Find the multicast in your own capture.** Change the filter to `ether multicast`
and look at the destinations. Anything beginning `01:00:5e` is IPv4 multicast, and
`33:33` is the IPv6 equivalent, which topic 08's neighbour discovery capture showed
without naming.

## Check yourself

<details class="qa">
<summary>Two packets leave one host, a unicast to a second host and a broadcast. A third host is watching. What does it receive and why?</summary>

The broadcast only.

The unicast was addressed to a MAC the switch had already learned, so it was
delivered to that one port. The broadcast is addressed to `ff:ff:ff:ff:ff:ff`,
which is not a machine and can never be learned, so a switch floods it to every
port every time.

That is not a limitation of the switch. There is no port that could be the right
answer for an address every machine is supposed to receive.

</details>

<details class="qa">
<summary>Why does multicast sometimes behave exactly like broadcast on a switched network?</summary>

Because a switch with no IGMP snooping cannot find the multicast destination in
its forwarding table, so it treats it as an unknown address and floods it.

Multicast is efficient in principle: one transmission, delivered only where
receivers are. That efficiency depends on something in the network knowing where
the receivers are, and on a plain layer 2 switch nothing does.

IGMP snooping is the switch reading membership messages as they pass and building
that knowledge. It has to be enabled, and it needs something on the segment
sending periodic queries or the table expires.

</details>

<details class="qa">
<summary>What is different about an anycast packet compared with a unicast one?</summary>

Nothing in the packet.

Anycast is an ordinary unicast packet sent to an ordinary address. What makes it
anycast is that the same address is configured on several machines in different
places, and each location advertises a route to it, so the routing system delivers
to whichever is nearest to the sender.

No host does anything special and nothing at layer 2 is involved. It is entirely a
property of routing, which is why it behaves unlike the other three delivery
types.

</details>

<details class="qa">
<summary>Why did IPv6 drop broadcast, and what replaced it?</summary>

Because a broadcast has to be examined by every machine in the domain. A network
card can discard a unicast for somebody else in hardware, but it must accept a
broadcast and interrupt the processor, so the cost is paid by everybody and scales
with the size of the segment.

Multicast groups replaced it. All-nodes is `ff02::1`, all-routers is `ff02::2`,
and neighbour discovery uses a solicited-node group derived from the address being
sought.

The gain is that a card can be programmed to accept only the groups its host
joined, so a neighbour solicitation for another machine is filtered in hardware
rather than interrupting anything. ARP, being a broadcast, interrupts everybody
for every lookup.

</details>

<details class="qa">
<summary>A DNS root server address is reachable from everywhere and there are far more servers than addresses. How?</summary>

Anycast. The same address is configured at many sites, and each site advertises a
route to it, so every client reaches whichever instance is nearest by the routing
system's own measure.

DNS suits this particularly well because an ordinary query is one packet out and
one back over UDP. Even if routing changes between two queries and they land at
different instances, neither needs to know about the other.

It also gives failover for free. A site that goes down stops advertising its
route, and traffic follows the next best path without any failover mechanism
existing.

</details>

<details class="qa">
<summary>What is the difference between 255.255.255.255 and 10.0.0.255 on a /24?</summary>

`255.255.255.255` is the limited broadcast. It means this segment, it is never
forwarded by a router, and a host can use it before it knows what network it is
on, which is why DHCP uses it.

`10.0.0.255` is the directed broadcast for the 10.0.0.0/24 network specifically.
It names one particular network's broadcast address, so in principle it can be
sent from outside that network.

In practice routers do not forward directed broadcasts by default, because doing
so was the basis of amplification attacks where one packet became a reply from
every host on a subnet.

</details>

## References

- [RFC 919, Broadcasting Internet Datagrams](https://www.rfc-editor.org/rfc/rfc919) - IETF, on limited and directed broadcast. Accessed 2026-08-10.
- [RFC 1112, Host Extensions for IP Multicasting](https://www.rfc-editor.org/rfc/rfc1112) - IETF, which defines IP multicast and IGMP. Accessed 2026-08-10.
- [RFC 4786, Operation of Anycast Services](https://www.rfc-editor.org/rfc/rfc4786) - IETF, on running a service at many sites behind one address. Accessed 2026-08-10.
- [IANA IPv4 Multicast Address Space Registry](https://www.iana.org/assignments/multicast-addresses/multicast-addresses.xhtml) - IANA, the authority for the assigned group addresses in the table. Accessed 2026-08-10.

**Where the output came from.** The captured block was produced on the
`blog/scripts/topologies/one-switch.sh` namespace topology through
`blog/scripts/netlab.sh`, the same switch as the previous topic. As noted there,
that topology has IPv6 disabled so the wire is quiet enough to observe one thing
at a time, which is why the capture shows two frames rather than two frames
surrounded by neighbour discovery. The multicast group addresses in the table are
IANA assignments rather than observations, and anycast is not captured at all
because demonstrating it needs several sites and a routing system, which is the
honest limit of a namespace on one laptop.

**If you also work on Linux.** Nothing here has a direct Linux+ counterpart. The
delivery types are protocol behaviour rather than administration, and the Linux+
track meets multicast only in passing where a service happens to use it.
