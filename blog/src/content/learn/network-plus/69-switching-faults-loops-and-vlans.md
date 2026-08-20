---
title: "Switching faults, loops and VLANs"
description: "The network is saturated and no host is sending anything. What one extra cable does to a switched network in a second, why the root bridge election decides every path in the network, and why a VLAN fault looks exactly like a broken host."
deck: "The network is saturated and no host is sending anything"
track: "network-plus"
level: "deep"
order: 700
objectives:
  - "Explain why a layer 2 loop saturates a network rather than slowing it"
  - "Say what changes when the wrong switch wins the root bridge election"
  - "Recognise the outage a topology change causes while tables catch up"
  - "Diagnose a wrong access port VLAN and a missing VLAN on a trunk"
  - "Find the access list rule that is blocking traffic nobody meant to block"
prerequisites: ["spanning-tree"]
tags: ["network-plus", "networking", "troubleshooting", "switching"]
updated: 2026-08-19
draft: false
examObjectives:
  - exam: "n10-009"
    domain: "5.0"
    objective: "5.3"
sources:
  - title: "IEEE 802.1Q, Bridges and Bridged Networks"
    url: "https://standards.ieee.org/ieee/802.1Q/10323/"
    publisher: "IEEE Standards Association"
    accessed: 2026-08-19
    tier: 1
  - title: "bridge(8)"
    url: "https://man7.org/linux/man-pages/man8/bridge.8.html"
    publisher: "man7.org"
    accessed: 2026-08-19
    tier: 1
  - title: "nft(8)"
    url: "https://www.netfilter.org/projects/nftables/manpage.html"
    publisher: "Netfilter"
    accessed: 2026-08-19
    tier: 1
symptoms:
  - symptom: "The network is saturated and no host is sending much traffic"
    anchor: "one-cable-and-the-network-stops"
  - symptom: "Traffic between two hosts takes a longer path than it used to"
    anchor: "the-election-decides-every-path"
  - symptom: "A host has the right address and mask and cannot be reached"
    anchor: "a-vlan-fault-looks-like-a-broken-host"
---

> **Before you read.** Every link light on the switch is solid. The uplink is at
> capacity. Applications have stopped, phones have dropped, and the monitoring
> system went quiet twenty seconds ago because it cannot reach anything either.
>
> You check what is generating the traffic and the answer is that almost nothing
> is. The hosts are idle. One person plugged a cable in about a minute ago.
>
> **Where is all the traffic coming from?**

Switching faults are the fastest and the most total failures on a network. A
routing fault breaks one path. A switching fault can take an entire site off the
air in under a second, from one frame, and this topic is what that looks like when
it happens and what the two subtler versions look like when it does not.

### Some words you will need

<dl class="terms">
<dt>broadcast storm</dt>
<dd>One broadcast frame circulating forever in a loop, multiplying at every switch. Not a lot of traffic: one frame, copied without end.</dd>
<dt>root bridge</dt>
<dd>The switch every other switch measures its distance to. Spanning tree elects one, and every path in the network is decided relative to it.</dd>
<dt>blocked port</dt>
<dd>A port that is up, has a link, and forwards nothing. That is spanning tree holding a loop open.</dd>
<dt>access port</dt>
<dd>A switch port carrying one VLAN, untagged, to one device. Which VLAN it carries is configuration, not something the device chooses.</dd>
<dt>allowed VLAN list</dt>
<dd>Which VLANs a trunk carries. A VLAN missing from it stops at the switch.</dd>
<dt>access list</dt>
<dd>An ordered set of permit and deny rules. First match wins, and what does not match hits whatever the default is.</dd>
</dl>

## What breaks without this

**One cable takes down a site.** Layer 2 has no counter that kills a looping frame,
so a loop is not a slowdown. It is a total, immediate outage that spreads to every
switch in the broadcast domain.

**A switch nobody planned for changes every path in the building.** The root bridge
election has a winner whether or not anybody chose it, and every path is measured
from that winner.

**A working host is declared broken.** A machine on the wrong VLAN has the right
address, the right mask, a link light, and no connectivity, which reads as a fault
in the machine and is a fault in a switch port.

## One cable, and the network stops

Start with the fastest failure available, because seeing the number is what makes
the rest of it obvious.

Three switches, two cables between them, no spanning tree anywhere, and one host on
each of two of them. That is a healthy network with no loop in it, until somebody
plugs in the third cable. The topology is
[`switch-loop.sh`](https://github.com/rlwilliamson-dev/azure-resume/blob/main/blog/scripts/topologies/switch-loop.sh),
which builds that cable and leaves it down so the capture can be the moment it goes
in.

<details class="predict">
<summary>Three switches, two cables, and somebody plugs in a third. One host then sends a single ARP broadcast. How much traffic crosses one link in the second that follows?</summary>

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology switch-loop
# three switches, two cables, no loop and no spanning tree. h1 reaches h2
$ ip netns exec h1 ping -c2 -W1 10.0.0.2 2>&1 | tail -2
2 packets transmitted, 2 received, 0% packet loss, time 1002ms
rtt min/avg/max/mdev = 0.089/0.099/0.109/0.010 ms
# somebody plugs in the third cable. nothing is configured, nothing is typed
$ ip netns exec sw1 ip link set sw1-sw3 up
$ ip netns exec sw3 ip link set sw3-sw1 up
$ ip netns exec sw1 ip -s link show sw1-sw2 | grep -A1 "TX:"
    TX:  bytes packets errors dropped carrier collsns           
           292       4      0       0       0       0 
# h1 asks for an address nobody has. that is one arp broadcast, one frame
$ ip netns exec h1 ping -c1 -W1 10.0.0.99 > /dev/null 2>&1
$ sleep 1
# the same link, one second later
$ ip netns exec sw1 ip -s link show sw1-sw2 | grep -A1 "TX:"
    TX:  bytes packets errors dropped carrier collsns           
      33070546  787391      0       0       0       0 
# and the network h1 was using a moment ago
$ ip netns exec h1 ping -c2 -W1 10.0.0.2 2>&1 | tail -2
2 packets transmitted, 0 received, 100% packet loss, time 1037ms
```

</details>

**Four packets, then 787,391 packets, one second apart.** Thirty-three megabytes
across one link in one second, produced by a single ARP request from an idle host
asking for an address that does not exist. And the ping that worked at the top of
the block is now losing every packet, because there is no capacity left for it.

The mechanism is worth stating precisely because it is the whole reason a layer 2
loop is different in kind from a layer 3 one. An IP packet carries a TTL that every
router decrements, so a routing loop kills its own traffic after a few dozen hops.
**An Ethernet frame has no such field.** A switch that receives a broadcast floods
it out of every other port, forever, and in a triangle each switch's copy arrives at
the other two, each of which floods it again. One frame becomes two, two become four,
and the growth stops only when the links are full, which takes about as long as it
took here.

That is also why the hosts look innocent. They are innocent. The traffic is one old
frame being copied by the switches, and every host on the segment is receiving all of
it, which is why the machines get slow as well as the network.

<details class="deeper">
<summary>If you already run switched networks: why the helpful person is always the cause, and what to do in the first thirty seconds</summary>

The loop is almost never built by somebody configuring a network. It is built by
somebody solving a small problem.

The two spare ports on the wall plate turn out to be the same cable run. A meeting
room gets a small unmanaged switch so four people can plug in, and somebody later
patches its second uplink because the first one looked loose. A cleaner tidies a
cabinet and a cable that had been hanging loose ends up in a port. In every case the
person had no reason to think about spanning tree, and in every case the network they
took down was fine a second earlier.

Which is the argument for the protections rather than for the protocol. Spanning tree
prevents the loop from being fatal and takes tens of seconds to do it. The features
that stop the loop being created at all sit on the access ports: refusing to accept a
switch's own protocol frames on a port that should have a desktop on it, and shutting
a port that starts behaving like a switch. Those are configuration on the ports nobody
thinks about, which is exactly where the cable goes in.

In the first thirty seconds of a live storm, the useful moves are ordered by what you
can do without reaching anything over the network, because the network is the thing
that has stopped. Console access rather than SSH. Then look at which ports are running
at line rate with no application behind them, and unplug the newest cable in the room,
which is usually the one somebody mentions once you ask. Reading counters is faster
than reasoning here: a storm shows up as every port on a switch transmitting the same
enormous number, which no real traffic pattern ever produces.

</details>

## The election decides every path

Spanning tree stops the storm above by holding one port open, and which port it picks
follows entirely from which switch is the root. That makes the election worth more
attention than it usually gets, because it is not choosing a title. It is choosing
every path in the network.

<figure class="learn-figure">
<svg viewBox="0 0 720 250" role="img" aria-labelledby="root-title" style="width:100%;height:auto;">
<title id="root-title">The same three switches with two different root bridges, showing that the blocked link moves and with it the path between two hosts, which goes from one hop to two</title>
<g fill="currentColor">
<text x="14" y="22" font-size="11">the same three switches, the same three cables, two different roots</text>
<text x="175" y="48" text-anchor="middle" font-size="10">root sw2, the one somebody chose</text>
<text x="535" y="48" text-anchor="middle" font-size="10">root sw3, the one that arrived</text>
<g stroke="currentColor" stroke-opacity="0.45" stroke-width="1.2" fill="none">
<path d="M 103 100 H 247"/>
<path d="M 96 115 L 158 172"/>
<path d="M 254 115 L 192 172"/>
<path d="M 463 100 H 607"/>
<path d="M 456 115 L 518 172"/>
<path d="M 614 115 L 552 172"/>
</g>
<g stroke="var(--accent)" stroke-width="2.6" fill="none">
<path d="M 103 100 H 247"/>
<path d="M 456 115 L 518 172"/>
<path d="M 614 115 L 552 172"/>
</g>
<g stroke="var(--red)" stroke-width="2" stroke-dasharray="4 3" fill="none">
<path d="M 96 115 L 158 172"/>
<path d="M 463 100 H 607"/>
</g>
<g stroke="var(--red)" stroke-width="2" fill="none">
<path d="M 120 137 l 14 13 M 134 137 l -14 13"/>
<path d="M 528 92 l 14 16 M 542 92 l -14 16"/>
</g>
<g fill="currentColor" fill-opacity="0.08" stroke="currentColor" stroke-opacity="0.75">
<circle cx="85" cy="100" r="18"/>
<circle cx="265" cy="100" r="18"/>
<circle cx="175" cy="185" r="18"/>
<circle cx="445" cy="100" r="18"/>
<circle cx="625" cy="100" r="18"/>
<circle cx="535" cy="185" r="18"/>
</g>
<text x="85" y="104" text-anchor="middle" font-size="10">sw1</text>
<text x="265" y="104" text-anchor="middle" font-size="10">sw2</text>
<text x="175" y="189" text-anchor="middle" font-size="10">sw3</text>
<text x="445" y="104" text-anchor="middle" font-size="10">sw1</text>
<text x="625" y="104" text-anchor="middle" font-size="10">sw2</text>
<text x="535" y="189" text-anchor="middle" font-size="10">sw3</text>
<text x="85" y="74" text-anchor="middle" font-size="9.5" fill-opacity="0.85">h1</text>
<text x="265" y="74" text-anchor="middle" font-size="9.5" fill-opacity="0.85">h2</text>
<text x="445" y="74" text-anchor="middle" font-size="9.5" fill-opacity="0.85">h1</text>
<text x="625" y="74" text-anchor="middle" font-size="9.5" fill-opacity="0.85">h2</text>
<text x="265" y="134" text-anchor="middle" font-size="9.5" fill-opacity="0.85">root</text>
<text x="535" y="219" text-anchor="middle" font-size="9.5" fill-opacity="0.85">root</text>
<text x="175" y="240" text-anchor="middle" font-size="9.5">h1 to h2: one hop</text>
<text x="535" y="240" text-anchor="middle" font-size="9.5">h1 to h2: two hops</text>
</g></svg>
<figcaption>Nothing physical differs between the two halves. Three switches, three cables, two hosts, and one number changed on sw3. Because spanning tree blocks the link furthest from the root, moving the root moves the blocked link, and the traffic between the two hosts that used to cross one cable now crosses two and passes through a switch that has nothing to do with either of them. Multiply that across a building and an unplanned election is not a cosmetic result: it is every conversation on the network taking a route nobody designed, usually through the smallest switch in the estate.</figcaption>
</figure>

Here it is happening. sw2 was given the lowest priority on purpose so that it wins,
and then a switch arrives whose priority is lower still. The topology is
[`stp-triangle.sh`](https://github.com/rlwilliamson-dev/azure-resume/blob/main/blog/scripts/topologies/stp-triangle.sh).

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology stp-triangle
# sw2 was given the lowest priority deliberately, so sw2 is the root
$ ip -d -n sw1 link show br0 | grep -oE "designated_root [0-9a-f.:]+"
designated_root 1000.2:0:0:0:2:0
$ ip netns exec h1 ping -c2 -W1 10.0.0.2 > /dev/null 2>&1
# the port sw1 uses to reach h2, and the state of each of sw1 ports
$ ip netns exec sw1 bridge fdb show br br0 | grep "02:00:00:00:00:02"
02:00:00:00:00:02 dev sw1-sw2 master br0 
$ ip netns exec sw1 bridge link show | grep -oE "^[0-9]+: [a-z0-9-]+|state [a-z]+"
7: sw1-sw2
state forwarding
11: sw1-sw3
state forwarding
12: sw1-h1
state forwarding
# a switch is added with its priority left lower than the one somebody chose
$ ip netns exec sw3 ip link set br0 type bridge priority 0
$ sleep 45
$ ip -d -n sw1 link show br0 | grep -oE "designated_root [0-9a-f.:]+"
designated_root 0000.2:0:0:0:3:0
$ ip netns exec sw1 bridge link show | grep -oE "^[0-9]+: [a-z0-9-]+|state [a-z]+"
7: sw1-sw2
state blocking
11: sw1-sw3
state forwarding
12: sw1-h1
state forwarding
# the same two hosts, immediately after the new tree settles
$ ip netns exec h1 ping -c3 -W1 10.0.0.2 2>&1 | tail -2
3 packets transmitted, 0 received, 100% packet loss, time 2080ms

$ ip netns exec sw1 bridge fdb show br br0 | grep "02:00:00:00:00:02"
02:00:00:00:00:02 dev sw1-sw2 master br0 stale
# and again once the forwarding table has aged out what it learned
$ sleep 35
$ ip netns exec h1 ping -c3 -W1 10.0.0.2 2>&1 | tail -2
3 packets transmitted, 3 received, 0% packet loss, time 2059ms
rtt min/avg/max/mdev = 0.088/0.113/0.134/0.019 ms
$ ip netns exec sw1 bridge fdb show br br0 | grep "02:00:00:00:00:02"
02:00:00:00:00:02 dev sw1-sw3 master br0 
```

Read the root identifier at the top and the bottom. `1000.2:0:0:0:2:0` is priority
4096 followed by sw2's address, which is the root somebody chose. `0000.2:0:0:0:3:0`
is priority 0 followed by sw3's, which is the root that turned up. Lowest wins, and
nothing about that decision consults anybody's intentions.

Three consequences appear in the block, in order of how much they cost.

**The blocked link moved.** sw1's direct link to sw2 was forwarding and is now
blocking, so the shortest path between the two hosts has been withdrawn.

**Traffic stopped for half a minute.** The ping immediately after the new tree
settled lost every packet, and the reason is in the forwarding table underneath it:
sw1 still believes h2 is reached through `sw1-sw2`, which is now a blocked port. The
entry is marked `stale` and it is still being used. A topology change does not
instantly correct every table that depended on the old topology, and traffic falls
into the gap.

**Then it recovers, on a worse path.** Once the entry ages out, sw1 floods, relearns,
and finds h2 through `sw1-sw3`. The hosts are talking again and every frame between
them now crosses an extra switch.

So an unplanned root election costs an outage and leaves a worse network behind. That
is the argument for setting bridge priorities deliberately on the switches you intend
to be the root and the backup, rather than leaving the election to whichever device
happens to have the lowest address, which is frequently the oldest and slowest thing
in the building.

## A VLAN fault looks like a broken host

The next two faults produce the single most misleading symptom in switching: a host
that is configured perfectly and cannot be reached.

Two switches, a trunk between them, and hosts in VLAN 10 and VLAN 20 on each. h1 and
h3 are both in VLAN 10 and talk to each other across the trunk. Then h3's patch lead
is moved to a port that was set up for a different VLAN. The topology is
[`vlan-switch.sh`](https://github.com/rlwilliamson-dev/azure-resume/blob/main/blog/scripts/topologies/vlan-switch.sh).

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology vlan-switch
# h1 and h3 are both in VLAN 10, on two different switches, and reach each other
$ ip netns exec h1 ping -c2 -W1 10.0.10.3 2>&1 | tail -2
2 packets transmitted, 2 received, 0% packet loss, time 1043ms
rtt min/avg/max/mdev = 0.133/0.133/0.134/0.000 ms
$ ip netns exec sw2 bridge vlan show dev sw2-h3
port              vlan-id  
sw2-h3            10 PVID Egress Untagged
# h3 patch lead is moved to a port somebody set up for VLAN 20. its address,
# its mask and its cable are untouched
$ ip netns exec sw2 bridge vlan del dev sw2-h3 vid 10
$ ip netns exec sw2 bridge vlan add dev sw2-h3 vid 20 pvid untagged
$ ip netns exec sw2 bridge vlan show dev sw2-h3
port              vlan-id  
sw2-h3            20 PVID Egress Untagged
$ ip netns exec h1 ping -c2 -W1 10.0.10.3 2>&1 | tail -2
2 packets transmitted, 0 received, 100% packet loss, time 1061ms

$ ip netns exec h3 ip -br addr show h3eth0
h3eth0@if10      UP             10.0.10.3/24 
```

The last line is the point. h3's interface is `UP` with `10.0.10.3/24` on it, which
is a correct address in the right subnet with the right mask, and it is unreachable.
Nothing you can run on the host will show you why, because from the host's side
nothing is wrong. The fault is one number on a switch port and the host cannot see it.

That is worth turning into a habit: **when a host looks perfect and cannot be reached,
the next place to look is the port it is plugged into, not the host.** The specific
question is which VLAN that access port carries, and the answer is one command on the
switch.

**The trunk is the other half of the same fault**, and it produces a stranger version.
Here every access port is left alone and one VLAN is taken off the trunk on one switch.

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology vlan-switch
# the trunk carries both VLANs, so both pairs reach each other across it
$ ip netns exec sw1 bridge vlan show dev sw1-trunk
port              vlan-id  
sw1-trunk         10
                  20
$ ip netns exec h1 ping -c1 -W1 10.0.10.3 2>&1 | grep "packet loss"
1 packets transmitted, 1 received, 0% packet loss, time 0ms
$ ip netns exec h2 ping -c1 -W1 10.0.20.4 2>&1 | grep "packet loss"
1 packets transmitted, 1 received, 0% packet loss, time 0ms
# VLAN 10 is taken off the trunk on one switch. every access port is untouched
# and both switches still agree about which port belongs to which VLAN
$ ip netns exec sw1 bridge vlan del dev sw1-trunk vid 10
$ ip netns exec sw1 bridge vlan show dev sw1-trunk
port              vlan-id  
sw1-trunk         20
$ ip netns exec h1 ping -c1 -W1 10.0.10.3 2>&1 | grep "packet loss"
1 packets transmitted, 0 received, 100% packet loss, time 0ms
$ ip netns exec h2 ping -c1 -W1 10.0.20.4 2>&1 | grep "packet loss"
1 packets transmitted, 1 received, 0% packet loss, time 0ms
```

One VLAN broke and the other did not, across the same cable, between the same two
switches. That signature is close to diagnostic on its own: **if some VLANs cross a
link and others do not, the link is a trunk and its allowed list is wrong.** No cable
fault behaves selectively by VLAN, and no host configuration produces it either.

The fault also survives being looked at from the wrong end. Everything on sw2 is
correct, every access port on both switches is correct, and the hosts are correct.
The one wrong thing is a list on one end of one link.

<details class="deeper">
<summary>If you already configure switches: the native VLAN, and why both ends of a trunk have to be read</summary>

Two details make trunk faults harder than they look.

The first is that a trunk has an untagged VLAN as well as a tagged list, and the two
ends have to agree about it. Frames arriving on a trunk with no tag are put into
whatever that end calls its native or untagged VLAN, so if the two ends disagree,
traffic from one VLAN silently arrives in another. That is not a link failure, it is
a leak, and the symptom is two networks that were supposed to be separate turning out
not to be, which is worse than an outage and much quieter. Topic 17 covered the
tagging; the fault is that the untagged case is a per-end configuration and nothing
checks that the two ends match.

The second is that the allowed list is per end. The capture above removed VLAN 10
from one end only, and that was enough. So reading the trunk on the switch nearest
the complaint is half a diagnosis, and the habit worth building is to read both ends
and compare, in the same way that reading interface counters at both ends of a link
is what makes a duplex mismatch visible.

The general shape of both is worth naming, because it recurs: a link between two
devices has configuration on two devices, and a fault can live in the disagreement
rather than in either one. Nothing is wrong with either end taken alone. Reading only
one is how a trunk fault survives an afternoon.

</details>

## The rule that blocks more than it names

The last of the three is an access list doing exactly what it says and not what
somebody meant.

A router with three segments behind it. Corp is permitted to reach the payment
segment and does. Then somebody decides the vending machine on the IoT segment should
be kept away from payment and writes a rule for it, naming the destination and
forgetting to name the source. The topology is
[`segmented-lan.sh`](https://github.com/rlwilliamson-dev/azure-resume/blob/main/blog/scripts/topologies/segmented-lan.sh).

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology segmented-lan
# corp is allowed to reach the payment segment, and does
$ ip netns exec corp ping -c1 -W1 10.10.0.9 2>&1 | grep "packet loss"
1 packets transmitted, 1 received, 0% packet loss, time 0ms
# somebody wants the vending machine kept away from payment and writes a rule
# for it. the rule names the destination and forgets to name the source
$ ip netns exec rtr nft insert rule inet seg forward ip daddr 10.10.0.0/24 counter drop
$ ip netns exec iot ping -c1 -W1 10.10.0.9 2>&1 | grep "packet loss"
1 packets transmitted, 0 received, 100% packet loss, time 0ms
# and now the thing that was working
$ ip netns exec corp ping -c1 -W1 10.10.0.9 2>&1 | grep "packet loss"
1 packets transmitted, 0 received, 100% packet loss, time 0ms
# which rule is doing it. the counter names it, and its position explains it
$ ip netns exec rtr nft list chain inet seg forward
table inet seg {
	chain forward {
		type filter hook forward priority filter; policy drop;
		ip daddr 10.10.0.0/24 counter packets 2 bytes 168 drop
		ct state established,related accept
		ip saddr 10.30.0.0/24 ip daddr 10.10.0.0/24 accept comment "corp may reach payment"
		ip daddr 203.0.113.0/24 accept comment "any segment may reach the internet"
	}
}
```

The new rule matched two packets: the one from the vending machine, which was the
intention, and the one from corp, which was not. It sits above the rule permitting
corp to reach payment, and since first match wins, the permit below it never runs.

**The counter is the diagnosis.** A list of rules is a hypothesis about what is
happening; a counter next to each rule is a measurement of what happened. Two packets
against that line, at the moment two pings failed, removes any argument about which
rule is responsible. Every switch and firewall worth using offers this, and the habit
of putting counters on rules before you need them is the difference between reading a
list and reading evidence.

Two things make this fault common enough to expect. **A rule that names only a
destination matches every source**, which is easy to write and easy to read past,
because the sentence in your head had the source in it. And **the rule was
unnecessary**: the vending machine could not reach payment anyway, since the chain's
default is drop and nothing permitted it. Topic 54 covered that implicit deny. A rule
added to enforce something already enforced is pure risk, and it is exactly the kind
of rule that gets added because somebody wanted the intent written down.

## Prove it

You have this when you can look at a symptom and name which of the three it is before
touching anything.

```bash
# is a port forwarding, or blocking, and what does this switch think the root is
bridge link show
ip -d link show br0 | grep -oE "designated_root [0-9a-f.:]+"

# which VLAN does this access port carry, and what does the trunk allow
bridge vlan show dev <port>

# which rule matched, and how many times
nft list chain inet <table> <chain>
```

Then check that you can tell the three signatures apart. Saturation with idle hosts is
a loop. Traffic taking a longer path than it used to, or an outage nobody deployed for,
is a topology change. Some VLANs crossing a link while others do not is a trunk. A host
with a perfect configuration that nothing can reach is its access port. And a single
flow that stopped when nothing else did is a rule, which a counter will confirm in one
command.

## What trips people up

### 1. Looking for the host generating the storm

There is not one. A loop is one old frame being copied by switches, so every host looks
busy receiving it and none of them is sending it. Time spent finding the culprit machine
is time the network is down.

### 2. Expecting a loop to be slow rather than fatal

An Ethernet frame has no TTL, so nothing kills a looping broadcast. It doubles at every
switch and fills the links in about a second, which is why this is an outage and not a
performance problem.

### 3. Leaving the root bridge election to chance

Somebody wins it whether or not anybody chose. Left to default priorities it falls
through to the lowest address, which has no relationship to which switch should be at
the centre of the network.

### 4. Assuming a topology change is free

The tree reconverges and the forwarding tables that depended on the old tree do not
update at the same moment. The capture above lost every packet for half a minute while
a stale entry pointed at a port that had just been blocked.

### 5. Diagnosing a VLAN fault on the host

A host on the wrong VLAN has the right address, the right mask and a link light.
Everything you can run on it says it is fine, because it is. The evidence is on the
switch port.

### 6. Reading only one end of a trunk

The allowed VLAN list is configured per end, and removing a VLAN from one end is enough
to break it. The switch nearest the complaint can be entirely correct.

### 7. Reading an access list instead of its counters

A rule list tells you what somebody intended. The counters tell you what matched. When
they disagree, the counters are right.

## Work it through

The saturated network from the top of the page.

The first thing that matters is that the hosts are idle, because it eliminates almost
everything. A denial of service, a backup job, a misbehaving application and a virus
all involve something sending. Nothing is sending, and the links are full, so the
traffic is being generated by the network itself. On a switched segment there is one
thing that does that.

The second thing is the timing. A cable went in about a minute ago and the network
stopped about a minute ago, and the methodology in topic 61 says most faults follow a
change. This one follows it by seconds.

So the move is to find the newest link and remove it, and the fastest way to find it is
not to reason but to read: on a switch in a storm, the ports carrying the loop all show
the same implausible counter, and the port that appeared most recently is the one that
closed the circle. Get to a switch by console rather than over the network, because the
network is what has failed.

Then, once it is up, do the part that stops it happening again, which is not a cable
policy. Spanning tree on every switch that carries a link to another switch, so a loop
is held open instead of being fatal. Protection on the access ports so that a port with
a desktop on it refuses to become part of the switching topology. And a root bridge
chosen deliberately, with a backup chosen too, so that the next switch somebody adds
under a desk cannot quietly become the centre of the network.

## Try it

**Run the loop and watch the number.** In
[`switch-loop.sh`](https://github.com/rlwilliamson-dev/azure-resume/blob/main/blog/scripts/topologies/switch-loop.sh)
the third cable is built and left down. Bring it up, send one broadcast, and read the
counter a second later. Nothing else in this track produces a number like it, and doing
it yourself is what makes a loop stop being an abstraction.

**Move the root and follow the path.** In
[`stp-triangle.sh`](https://github.com/rlwilliamson-dev/azure-resume/blob/main/blog/scripts/topologies/stp-triangle.sh),
change a bridge priority and then watch which port blocks and which port the forwarding
table uses to reach the far host. The gap between those two events is the outage.

**Break one VLAN and not the other.** In
[`vlan-switch.sh`](https://github.com/rlwilliamson-dev/azure-resume/blob/main/blog/scripts/topologies/vlan-switch.sh),
remove one VLAN from one end of the trunk. Then try to diagnose it from a host, and
notice that you cannot.

## Check yourself

<details class="qa">
<summary>The network is saturated and every host is idle. What is happening, and why so fast?</summary>

A layer 2 loop, and the traffic is one broadcast frame being copied endlessly by the
switches rather than anything a host is sending.

It is fast because an Ethernet frame has no time to live field. A router decrements the
TTL on an IP packet, so a routing loop kills its own traffic after a few dozen hops.
Nothing does that at layer 2, so a broadcast flooded into a loop is copied at every
switch, doubles on each pass, and fills the links in about a second. In the lab, one ARP
request produced 787,391 packets across one link in the first second.

</details>

<details class="qa">
<summary>A new switch is added and traffic between two unrelated hosts starts taking a longer path. Why?</summary>

It won the root bridge election. Spanning tree measures every path from the root, and
the blocked link is the one furthest from it, so changing which switch is the root
changes which link is blocked and therefore which paths exist.

The election goes to the lowest bridge priority, and falls through to the lowest address
when priorities tie. A switch that arrives with a low default wins against a switch
somebody configured, unless somebody configured it low enough. That is the argument for
setting the priority deliberately on the intended root and its backup rather than
leaving the outcome to whichever device has the lowest address.

</details>

<details class="qa">
<summary>Why does a topology change cause an outage even after the new tree has settled?</summary>

Because the forwarding tables still describe the old tree. In the capture, sw1 had
learned that h2 was reached through the port to sw2, that port was then blocked by the
new tree, and the entry stayed in the table and kept being used. Every frame for h2 went
at a blocked port and was discarded.

It recovered only when the entry aged out, after which the switch flooded, relearned, and
found h2 through the other port. The lesson is that reconvergence is two events rather
than one: the tree settles, and then the tables that depended on the old tree catch up,
and traffic is lost in between.

</details>

<details class="qa">
<summary>A host has the right address, the right mask, a link light, and nothing can reach it. Where do you look?</summary>

The switch port it is plugged into, specifically which VLAN that access port carries.

A host on the wrong VLAN is in a different broadcast domain from everything it expects
to talk to, and nothing about that is visible from the host. Its interface is up, its
address is correct, and every test you run on the machine passes. The evidence exists in
one place, which is the switch, and the fix is one number on one port.

</details>

<details class="qa">
<summary>Across one link between two switches, one VLAN works and another does not. What does that tell you?</summary>

That the link is a trunk and its allowed VLAN list is wrong on at least one end. Nothing
else behaves selectively by VLAN: a cable fault, a duplex problem or a failing
transceiver would break every VLAN on the link equally, and a host configuration cannot
produce it at all.

The list is configured per end, so removing a VLAN from one end is enough to break it,
and the switch nearest whoever complained may be entirely correct. Read both ends and
compare.

</details>

<details class="qa">
<summary>A flow that worked yesterday is blocked and the access list looks correct. How do you settle it?</summary>

Read the counters rather than the rules. A rule list describes what somebody intended and
a counter describes what actually matched, and when a permit sits below a broader deny,
the list can read perfectly while the permit never runs.

In the capture, a rule intended to block one segment named only a destination, so it
matched every source, and its counter showed two packets at the moment two different
pings failed. That is a measurement rather than an argument. The related lesson is that
the rule was unnecessary in the first place: the traffic it was written to block was
already covered by the chain's default deny.

</details>

## References

- [IEEE 802.1Q](https://standards.ieee.org/ieee/802.1Q/10323/) - IEEE Standards Association, which defines both spanning tree and VLAN tagging, so the loop and the trunk in this topic come from one document. Accessed 2026-08-19.
- [bridge(8)](https://man7.org/linux/man-pages/man8/bridge.8.html) - man7.org, for `bridge link show`, `bridge vlan show` and `bridge fdb show`, which are the three commands every capture here reads. Free. Accessed 2026-08-19.
- [nft(8)](https://www.netfilter.org/projects/nftables/manpage.html) - Netfilter, for rule ordering and the counter statement the access list capture depends on. Free. Accessed 2026-08-19.

**Where the numbers came from.** Five captured blocks, all through `netlab.sh` on the
kernel named in each header. The storm is from
[`switch-loop.sh`](https://github.com/rlwilliamson-dev/azure-resume/blob/main/blog/scripts/topologies/switch-loop.sh),
which exists because the blocked port on the spanning tree topology cannot be forced
open: the kernel keeps a port that the protocol put into blocking in that state even
after the protocol is switched off. So the loop topology is one whose switches never ran
spanning tree, with the third cable built and left down so the capture creates the loop
rather than inheriting it. The root bridge, VLAN and trunk faults are made in the
captured commands on the existing topologies, and the access list fault is one rule
inserted at the moment shown.

**If you also work on Linux systems.** The bridge here is a Linux bridge, so `bridge
link`, `bridge vlan` and `bridge fdb` are the same commands on any Linux machine that is
switching. What differs on real equipment is only the spelling: the port states, the root
election and the allowed VLAN list are the same mechanism with a vendor's words on top.
