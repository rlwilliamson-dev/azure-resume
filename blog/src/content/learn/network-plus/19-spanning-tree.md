---
title: "Spanning tree"
description: "Two switches, two cables between them, and the whole network stops. Why a layer 2 loop is fatal rather than merely wasteful, how the root bridge is elected, what the port states mean, and what running the protocol costs you."
deck: "Two switches, two cables, and everything stops"
track: "network-plus"
level: "working"
order: 200
objectives:
  - "Explain why a loop at layer 2 is fatal and a loop at layer 3 is not"
  - "Read a bridge id and say which switch wins an election"
  - "Name the port states and say what a port does in each"
  - "Identify which port a switch will block and why"
  - "Say what enabling spanning tree costs"
prerequisites: ["how-a-switch-learns"]
tags: ["network-plus", "networking", "switching"]
updated: 2026-08-10
draft: false
examObjectives:
  - exam: "n10-009"
    domain: "2.0"
    objective: "2.2"
  - exam: "n10-009"
    domain: "5.0"
    objective: "5.3"
sources:
  - title: "IEEE 802.1Q, Bridges and Bridged Networks"
    url: "https://standards.ieee.org/ieee/802.1Q/10323/"
    publisher: "IEEE Standards Association"
    accessed: 2026-08-10
    tier: 1
  - title: "bridge(8)"
    url: "https://man7.org/linux/man-pages/man8/bridge.8.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-10
    tier: 1
symptoms:
  - symptom: "A network becomes completely unusable within seconds of a cable being added"
    anchor: "why-a-loop-is-fatal"
  - symptom: "A port stays down for half a minute after a device is plugged in"
    anchor: "the-port-states-and-what-they-cost"
---

> **Before you read.** Somebody adds a second cable between two switches, meaning
> to add resilience. Within a few seconds nothing on the network works at all.
> Not slow. Nothing.
>
> Both cables are good and both switches are healthy.
>
> **Why did adding a redundant path destroy the network rather than protect it?**

Every other failure in this track degrades something. This one is different, and
the difference is worth understanding before the protocol that prevents it, since
the protocol only makes sense as an answer to how bad the problem is.

### Some words you will need

<dl class="terms">
<dt>loop</dt>
<dd>A path at layer 2 that leads back to where it started.</dd>
<dt>bridge id</dt>
<dd>A priority followed by a MAC address. The number the root election compares.</dd>
<dt>root bridge</dt>
<dd>The switch every other switch measures its distance from. There is exactly one.</dd>
<dt>root port</dt>
<dd>The port on a non-root switch that faces the root by the cheapest path.</dd>
<dt>blocking</dt>
<dd>A port that is up and deliberately not forwarding, held in reserve.</dd>
<dt>BPDU</dt>
<dd>Bridge protocol data unit. The message switches exchange to run the election.</dd>
</dl>

## What breaks without this

**One cable takes down everything.** Not one segment, not one VLAN. A layer 2
loop saturates the broadcast domain in seconds and the switches stop being able
to forward anything, including the traffic you would use to fix it.

**You cannot build a redundant layer 2 network at all.** Two paths between
switches is what redundancy means, and without something to manage it, two paths
is the fault above.

**A port that takes 30 seconds to come up looks broken.** It is the protocol
being careful, and knowing that saves a support call every time somebody plugs in
a laptop.

## Why a loop is fatal

An IP packet that loops eventually dies, because the TTL field counts down at
every router and the packet is discarded at zero. Topic 03 saw that field at 63
after one hop.

**An Ethernet frame has no TTL.** There is no field to decrement, no hop count,
and nothing anywhere in the frame that ages. A frame that finds a circular path
goes round it forever.

Now add flooding. Topic 14 established that a switch floods a broadcast, and an
unknown unicast, out of every port except the one it arrived on. Put those two
facts together on a network with a loop:

One broadcast arrives at a switch. It is flooded out of every other port. It
travels round the loop and arrives back, on a different port, where it is a
broadcast again, so it is flooded again. Meanwhile the copy going the other way
round the loop does the same thing.

The frame count doubles on every pass, and the passes take microseconds. This is
a broadcast storm, and within seconds the links are saturated with copies of a
handful of original frames.

The second effect is worse in a subtler way. Each copy arrives with the same
source MAC address on a different port every time, so every switch's forwarding
table is rewritten continuously, thrashing between ports. Even traffic that has
nothing to do with the storm cannot be delivered, because no switch has a stable
idea of where anything is.

**So the failure is total rather than partial**, and it takes out the management
path with everything else. That is why the answer is a protocol that runs
constantly rather than a monitoring alert that tells you afterwards.

## The election, and the tree

Spanning tree's job is to take a physical topology that has loops and produce a
logical topology that does not, by deliberately switching some ports off.

It starts by electing a root bridge. Every switch has a bridge id, which is a
priority followed by its MAC address, and **the lowest bridge id wins.** The
priority is configurable and the MAC is the tiebreak, which means an election
that nobody configures is decided by whichever switch happens to have the lowest
MAC address, and that is very often the oldest switch in the building.

Here are three switches wired in a triangle, so every one of them has two paths
to the others.

<details class="predict">
<summary>Three switches, each connected to both others. Which one becomes root, and how many ports get switched off?</summary>

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology stp-triangle
# a bridge id is a priority followed by a MAC address, and lowest wins
$ ip -d -n sw1 link show br0 | grep -oE "(root_id|bridge_id) [0-9a-f.:]+"
bridge_id 8000.2:0:0:0:1:0
$ ip -d -n sw2 link show br0 | grep -oE "(root_id|bridge_id) [0-9a-f.:]+"
bridge_id 1000.2:0:0:0:2:0
$ ip -d -n sw3 link show br0 | grep -oE "(root_id|bridge_id) [0-9a-f.:]+"
bridge_id a000.2:0:0:0:3:0
# and the ports, which is where the loop got broken
$ ip netns exec sw1 bridge link show | grep -oE "^[0-9]+: [a-z0-9-]+|state [a-z]+"
4: sw1-sw2
state forwarding
8: sw1-sw3
state forwarding
9: sw1-h1
state forwarding
$ ip netns exec sw2 bridge link show | grep -oE "^[0-9]+: [a-z0-9-]+|state [a-z]+"
3: sw2-sw1
state forwarding
6: sw2-sw3
state forwarding
11: sw2-h2
state forwarding
$ ip netns exec sw3 bridge link show | grep -oE "^[0-9]+: [a-z0-9-]+|state [a-z]+"
5: sw3-sw2
state forwarding
7: sw3-sw1
state blocking
```

</details>

One port. `sw3-sw1` is `blocking` and every other port is `forwarding`.

The bridge ids are the election in one line. Priority is printed in hex, so
`1000` is 4096 on sw2, `8000` is 32768 on sw1, and `a000` is 40960 on sw3. Lowest
wins, so sw2 is root, and the port that got switched off belongs to sw3, which
lost by the widest margin.

<figure class="learn-figure">
<svg viewBox="0 0 720 252" role="img" aria-labelledby="stp-title" style="width:100%;height:auto;">
<title id="stp-title">Three switches in a triangle with the lowest bridge id elected root, two root ports forwarding, and one end of the third link blocked</title>
<defs>
<g id="sw-glyph" stroke="currentColor" stroke-width="1.3" fill="none" stroke-opacity="0.8">
<path d="M -11 -4 H 7 M 4 -7 l 3 3 l -3 3"/>
<path d="M 11 4 H -7 M -4 1 l -3 3 l 3 3"/>
</g>
</defs>
<g fill="currentColor">
<text x="16" y="20" font-size="11" fill-opacity="0.75">lowest bridge id wins, and a bridge id is a priority then a MAC address</text>
<line x1="300" y1="98" x2="182" y2="186" stroke="currentColor" stroke-width="2"/>
<line x1="420" y1="98" x2="538" y2="186" stroke="currentColor" stroke-width="2"/>
<line x1="212" y1="218" x2="508" y2="218" stroke="currentColor" stroke-width="1.6" stroke-opacity="0.4" stroke-dasharray="7 5"/>
<g font-size="10" fill-opacity="0.7">
<text x="252" y="142" text-anchor="end">forwarding</text>
<text x="468" y="142">forwarding</text>
</g>
<rect x="286" y="46" width="148" height="52" rx="4" fill="var(--accent)" fill-opacity="0.16" stroke="var(--accent)" stroke-width="2.2"/>
<use href="#sw-glyph" x="308" y="72"/>
<text x="352" y="68" text-anchor="middle" font-size="12">sw2</text>
<text x="352" y="84" text-anchor="middle" font-size="10" fill-opacity="0.8">priority 4096</text>
<rect x="286" y="37" width="52" height="18" rx="2" fill="var(--accent)" fill-opacity="0.95"/>
<text x="312" y="50" text-anchor="middle" font-size="10" fill="var(--bg)">ROOT</text>
<rect x="64" y="186" width="148" height="52" rx="4" fill="currentColor" fill-opacity="0.07" stroke="currentColor" stroke-opacity="0.6"/>
<use href="#sw-glyph" x="86" y="212"/>
<text x="130" y="208" text-anchor="middle" font-size="12">sw1</text>
<text x="130" y="224" text-anchor="middle" font-size="10" fill-opacity="0.8">priority 32768</text>
<rect x="508" y="186" width="148" height="52" rx="4" fill="currentColor" fill-opacity="0.07" stroke="currentColor" stroke-opacity="0.6"/>
<use href="#sw-glyph" x="530" y="212"/>
<text x="574" y="208" text-anchor="middle" font-size="12">sw3</text>
<text x="574" y="224" text-anchor="middle" font-size="10" fill-opacity="0.8">priority 40960</text>
<circle cx="196" cy="174" r="5" fill="currentColor"/>
<circle cx="524" cy="174" r="5" fill="currentColor"/>
<text x="186" y="172" text-anchor="end" font-size="10">root port</text>
<text x="534" y="172" font-size="10">root port</text>
<circle cx="228" cy="218" r="5" fill="currentColor"/>
<text x="240" y="206" font-size="10">sw1-sw3</text>
<text x="240" y="234" font-size="10" fill-opacity="0.7">forwarding</text>
<circle cx="492" cy="218" r="9" fill="var(--bg)" stroke="var(--red)" stroke-width="2.2"/>
<path d="M 486 212 l 12 12 M 498 212 l -12 12" stroke="var(--red)" stroke-width="2.2"/>
<text x="478" y="206" text-anchor="end" font-size="10">sw3-sw1</text>
<text x="478" y="234" text-anchor="end" font-size="10" fill="var(--red)">blocking</text>
</g>
</svg>
<figcaption>The link between sw1 and sw3 is drawn dashed because one end of it is switched off, and only one end. sw1 forwards on its side while sw3 blocks on the other, which is what breaks the loop without taking a cable out of service. Which end lost is not arbitrary: sw3 has the highest priority of the three, so when the two of them compared themselves for that segment, sw3 gave way. The blocked port stays up and keeps receiving, ready to take over the moment a forwarding path fails. One loop, one blocked end, and five of the six ports still carrying traffic.</figcaption>
</figure>

That is the whole outcome. Three switches and three links form one loop, and
breaking a loop takes exactly one port. The other five ports carry traffic
normally, so the redundancy is still there: the blocked port is up, receiving,
and ready to take over if a forwarding path fails.

The election chose sw2 as root because it was given the lowest priority. Every
other switch then works out its cheapest path to the root and marks that port as
its root port. Ports that are neither the root port nor the best path for a
segment are the ones that get blocked, which is how sw3's link to sw1 lost.

Notice what did not happen. Nothing was unplugged, no cable was removed, and no
administrator chose which link to sacrifice. The switches agreed among themselves,
and they will agree again differently the moment something changes.

<details class="deeper">
<summary>If you already work on networks: reading a bridge id, and why the default election is usually wrong</summary>

A bridge id is 8 bytes: 2 of priority and 6 of MAC address, and the comparison is
across the whole thing as one number. So priority decides it unless two switches
have the same priority, and then the MAC address breaks the tie.

The default priority on essentially everything is 32768, which is the middle of
the range. Since every switch ships with the same default, an unconfigured
network elects its root purely on MAC address.

That is almost always the wrong switch. MAC addresses are assigned at
manufacture, and lower ones tend to be older hardware, so the default election
has a mild bias toward electing the oldest and slowest switch in the building as
the centre of the topology. Every path is then measured from a switch that was
never intended to carry the traffic.

The fix is to set the priority deliberately on the switch you want as root,
usually a core switch, and set a second one slightly higher as the backup. The
value moves in steps of 4096, which is a detail that catches people out the first
time an arbitrary number is rejected.

The capture on this page sets all three explicitly, at 4096, 32768 and 40960, so
the election has a predictable winner. Left at defaults, all three would tie and
the result would depend on MAC addresses the kernel assigns at random, so the
transcript would name a different root every time it was produced. That is also
why the topology file pins the bridge MAC addresses.

A practical habit worth taking: on any network you inherit, find out which switch
is root before changing anything. If the answer is a switch in a cupboard that
nobody remembers installing, that is a finding.

</details>

## The port states, and what they cost

A port does not go straight to forwarding. Classic spanning tree moves it through
states, and the delay is deliberate.

| State | What the port does |
| --- | --- |
| Blocking | Listens to protocol messages. Forwards nothing, learns nothing |
| Listening | Participating in the election. Still forwards nothing, still learns nothing |
| Learning | Building the forwarding table from what it sees. Still forwards nothing |
| Forwarding | Normal operation |
| Disabled | Administratively off, not participating at all |

The two middle states have timers, and the total is around 30 seconds from link
up to carrying traffic. That is the cost, and it buys certainty: a port that
started forwarding immediately might complete a loop before the protocol had
worked out that it should not.

**Thirty seconds is a long time when it is a laptop.** A machine plugged in, or a
port that flaps, waits half a minute before anything works. DHCP requests are sent
into a port that is not forwarding yet and go unanswered, which is why a
workstation on a spanning tree port sometimes ends up with the link-local address
from topic 07 and no network at all.

The answer to that is to tell the switch that a given port will never lead to
another switch, so it can skip the waiting and forward immediately. That is a
standard feature on access ports, and its counterpart is a guard that shuts the
port down if a switch ever does appear on it.

Rapid spanning tree reduces the delay in the general case, from tens of seconds
to typically under a second, by having switches negotiate directly rather than
waiting out timers. It is the version essentially everything runs now. The
research for this track found that N10-009 names spanning tree once as a feature
and once as a fault, and names no variant at all, so know the mechanism and do
not spend time memorising which acronym belongs to which revision.

<details class="deeper">
<summary>If you already work on networks: what actually happens when a link fails, and the case spanning tree cannot save you from</summary>

The reason to run spanning tree is not that it prevents loops in a correct
design. It is that it converts a failure into a delay.

When a forwarding link goes down, the switches that were relying on it stop
hearing protocol messages through it, recalculate, and a port that was blocking
becomes a root port and starts forwarding. The redundant path was there the whole
time, held down deliberately, and it takes over without anybody doing anything.
With the classic protocol that transition takes tens of seconds and with rapid
spanning tree it is usually under a second.

The case it cannot save you from is the one that produces the outage at the top
of this page anyway, and it is worth knowing because it is the one you will meet.

Spanning tree depends on switches hearing each other's messages. Anything that
creates a path where those messages do not flow creates a loop the protocol
cannot see. A cheap unmanaged switch plugged into two wall sockets is the classic:
it does not participate, it forwards the protocol messages as ordinary traffic or
drops them, and the loop it completes is invisible to the switches that would
otherwise have blocked something. Somebody plugging both ends of a patch lead into
the same wall plate does the same thing.

That is why access ports get configured with a guard that shuts the port down on
seeing a protocol message it should never have received, and why unused ports get
disabled. Both are admissions that the protocol protects against loops between
switches that are talking to each other, and not against whatever somebody plugs
into a meeting room.

The other case worth naming is a unidirectional link, usually fibre where one
strand has failed. One end can transmit and not receive, so it stops hearing the
messages that told it to block, unblocks, and forms a loop while the other end
still believes the topology is fine. There are protocols specifically for
detecting that, and the general lesson is the same: spanning tree is only as good
as the assumption that a link works in both directions.

</details>

## Prove it

You have this when you can look at a switch and say which port is not forwarding
and why.

```bash
./blog/scripts/netlab.sh --topo topologies/stp-triangle.sh -- \
  'ip netns exec sw3 bridge link show; ip -d -n sw2 link show br0 | grep -oE "(root_id|bridge_id) [0-9a-f.:]+"'
```

Three things to check. Exactly one port is blocking. The bridge ids read as a
priority in hex followed by a MAC, so `1000.2:0:0:0:2:0` is priority 4096 and
`a000.2:0:0:0:3:0` is 40960. And the blocked port belongs to the switch with the
highest of those, which is what losing an election looks like.

On real equipment the command differs and the concepts are identical. Every
managed switch will tell you its bridge id, which switch it believes is root, and
the state of each port. Finding the root on a network you have inherited is the
single most useful thing on this page.

## What trips people up

### 1. Expecting a loop to be slow rather than fatal

A frame has no TTL, so a looping frame never dies, and flooding doubles it on
every pass. Within seconds the links are saturated and the forwarding tables are
thrashing, so nothing works at all, including your access to the switches.

### 2. Thinking the highest priority wins

The lowest bridge id wins, and priority is the first part of it. Lower is better
throughout, which reads backwards to most people the first time.

### 3. Believing an unconfigured election picks something sensible

Every switch ships with the same default priority, so the tie falls to the MAC
address, which tends to favour the oldest switch in the building.

### 4. Reading a blocking port as broken

A blocking port is up, receiving protocol messages, and deliberately not
forwarding. It is the redundancy, waiting. It takes over automatically when a
forwarding path fails.

### 5. Blaming the switch for a slow port

A classic spanning tree port takes about 30 seconds to reach forwarding, and DHCP
requests sent during that window go unanswered. Access ports need to be told they
will never lead to a switch so they can skip it.

### 6. Assuming spanning tree prevents all loops

It prevents loops between switches that exchange its messages. An unmanaged
switch, or a patch lead plugged into two sockets, creates a loop nothing can see,
which is why access ports get a guard and unused ports get disabled.

## Work it through

An office loses its network completely at 14:20 on a Tuesday. Everything: no
internet, no file server, no printing. The switches are unreachable over the
network. Nothing was scheduled, and the last change was a week ago.

Total and instant is the diagnosis, before any evidence. Almost nothing takes out
a whole layer 2 network at once. A failed uplink loses one path, a dead switch
loses one area, a bad DHCP scope affects new leases only, and a routing problem
leaves local traffic working. Losing everything simultaneously, including
management access, is the signature of a broadcast storm.

The management access being gone is confirmation rather than an obstacle. The
switch's own management interface is reachable through the same saturated
broadcast domain as everything else, which is exactly why serious designs put
management in its own VLAN and keep an out-of-band path.

So the question becomes what changed at 14:20 on a network where nobody made a
change. Somebody plugged something in. The candidates are a patch lead into two
wall sockets, an unmanaged desk switch with two uplinks, or a device with two
network ports bridging them, which some laptops do by default when sharing a
connection.

Working out where is the practical problem, because the tool you would use is on
the network. Two approaches: switch port link lights on a storm are distinctive,
with everything blinking in unison rather than independently, and unplugging
uplinks one at a time until the storm stops isolates the segment. Neither is
elegant and both work.

Afterwards is where the real work is, because the fault was a person with a
cable and that will happen again. Access ports get the guard that shuts a port
down on seeing a protocol message. Unused ports get disabled. Management gets its
own VLAN so the next outage leaves you a way in.

## Check yourself

<details class="qa">
<summary>Why does a loop at layer 2 destroy a network when a loop at layer 3 does not?</summary>

Because an Ethernet frame has no TTL and an IP packet does.

A packet that loops between routers has its TTL decremented at each hop and is
discarded at zero. Nothing in an Ethernet frame ages, so a frame on a circular
path travels it indefinitely.

Combine that with flooding and it gets worse than merely persistent. A broadcast
is flooded out of every other port, comes back round the loop, and is flooded
again, so the number of copies doubles on each pass. Within seconds the links are
saturated and every forwarding table is thrashing between ports, so nothing can be
delivered at all.

</details>

<details class="qa">
<summary>Three switches have priorities 4096, 32768 and 40960. Which becomes root?</summary>

The one with 4096. The lowest bridge id wins, and the priority is the first part
of that id.

If two switches shared a priority, the MAC address in the rest of the id would
break the tie, again lowest wins.

That is why an unconfigured network elects on MAC address alone: every switch has
the same default priority of 32768, so the tie always falls through.

</details>

<details class="qa">
<summary>A port shows as blocking. Is something wrong?</summary>

No. That is spanning tree working.

A blocking port is up and receiving protocol messages, and deliberately not
forwarding traffic, because forwarding it would complete a loop. It is the
redundant path being held in reserve.

If a forwarding path fails, the switches recalculate and that port starts
forwarding, which is the entire reason for having a second cable in the first
place.

</details>

<details class="qa">
<summary>A laptop plugged into a switch port takes 30 seconds before it has a network, and often ends up with a 169.254 address. Why?</summary>

The port is moving through the spanning tree states before it forwards anything.
Listening and learning have timers, and the total is around 30 seconds.

The laptop does not wait. It sends DHCP requests into a port that is not
forwarding yet, gets no answer, and eventually configures a link-local address,
which is the topic 07 diagnosis arriving from an unexpected direction.

The fix is to configure access ports to skip the waiting, since they will never
lead to another switch, and to pair that with a guard that shuts the port down if
one ever appears.

</details>

<details class="qa">
<summary>What kind of loop can spanning tree not prevent?</summary>

One created by something that does not participate in it.

An unmanaged switch plugged into two wall sockets completes a loop while
forwarding or dropping the protocol messages that would have revealed it. The
managed switches never learn there is a second path, so nothing gets blocked.

A unidirectional link does the same thing differently: one end transmits and
cannot receive, so it stops hearing the messages telling it to block, unblocks,
and forms a loop the other end does not know about.

Both are why access ports get a guard and unused ports get disabled.

</details>

<details class="qa">
<summary>Why is finding the root bridge the first thing to do on a network you have inherited?</summary>

Because every path in the topology is calculated from it, and nobody may have
chosen it.

If the priorities were never configured, the election fell through to MAC
addresses, which mildly favours older hardware. The centre of the topology can
easily be a switch that was never meant to carry the traffic, sitting in a
cupboard somebody forgot about.

Knowing which switch is root tells you what the traffic flows look like and
whether the design anyone described to you is the design that is running.

</details>

## References

- [IEEE 802.1Q, Bridges and Bridged Networks](https://standards.ieee.org/ieee/802.1Q/10323/) - IEEE Standards Association, which now carries the spanning tree specification. Accessed 2026-08-10.
- [bridge(8)](https://man7.org/linux/man-pages/man8/bridge.8.html) - Linux man-pages project, the tool used for the capture. Accessed 2026-08-10.

**Where the output came from.** The captured block was produced on
`blog/scripts/topologies/stp-triangle.sh` through `blog/scripts/netlab.sh`. A
Linux bridge runs spanning tree when told to, so the election, the port states
and the blocked port are the protocol's own decisions on a real loop.

Two things in that topology are pinned rather than left to chance, and both for
the same reason. The bridge priorities are set explicitly, and so are the bridge
MAC addresses, because a bridge id is a priority followed by a MAC and the kernel
generates a random one. Left alone, all three switches would tie on the default
priority and the election would be decided by addresses that differ on every run,
so the page would name a different root each time it was rebuilt.

The storm itself is not captured. Producing one would work and would take the
lab down rather than showing anything a reader could read, which is a fair
description of why the protocol exists.

**If you also work on Linux.** Nothing here has a Linux+ counterpart. Spanning
tree is a switch protocol, and a Linux host running a bridge for containers or
virtual machines is usually a leaf rather than part of a loop.
