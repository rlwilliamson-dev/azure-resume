---
title: "FHRP, virtual IPs and subinterfaces"
description: "The default gateway is a single point of failure that every machine on the network is configured to use. First hop redundancy as a concept, the virtual address two routers share, and the subinterfaces that let one physical link carry several networks."
deck: "The default gateway is a single point of failure"
track: "network-plus"
level: "working"
order: 270
objectives:
  - "Say why the default gateway is a single point of failure that redundant links do not fix"
  - "Explain what a virtual IP and virtual MAC are and why both are needed"
  - "Describe active and standby operation and what failover looks like to a host"
  - "Configure and read subinterfaces on one physical link"
  - "Explain router on a stick and when it is the right answer"
prerequisites: ["trunking-and-802-1q-tagging"]
tags: ["network-plus", "networking", "routing", "redundancy"]
updated: 2026-08-10
draft: false
examObjectives:
  - exam: "n10-009"
    domain: "2.0"
    objective: "2.1"
sources:
  - title: "RFC 5798, Virtual Router Redundancy Protocol (VRRP) Version 3"
    url: "https://www.rfc-editor.org/rfc/rfc5798"
    publisher: "IETF"
    accessed: 2026-08-10
    tier: 1
  - title: "IEEE 802.1Q, Bridges and Bridged Networks"
    url: "https://standards.ieee.org/ieee/802.1Q/10323/"
    publisher: "IEEE Standards Association"
    accessed: 2026-08-10
    tier: 1
  - title: "ip-link(8)"
    url: "https://man7.org/linux/man-pages/man8/ip-link.8.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-10
    tier: 1
symptoms:
  - symptom: "A router fails and every machine on the segment loses its default route"
    anchor: "the-gateway-problem"
  - symptom: "One VLAN can reach the internet and another cannot on the same router"
    anchor: "subinterfaces-and-router-on-a-stick"
---

> **Before you read.** A network has two uplinks, two switches, redundant power
> and a maintenance contract. Every machine on it is configured with one default
> gateway address.
>
> That router reboots.
>
> **How much of the redundancy helps, and what are those machines doing?**

Everything in this block so far made the network resilient between routers. This
topic is about the last hop, where a host has exactly one address written into its
configuration and no mechanism for changing its mind.

### Some words you will need

<dl class="terms">
<dt>FHRP</dt>
<dd>First hop redundancy protocol. The general name for making a default gateway survive a failure.</dd>
<dt>virtual IP</dt>
<dd>An address shared by two or more routers, held by whichever is currently active.</dd>
<dt>virtual MAC</dt>
<dd>A MAC address shared the same way, so hosts do not have to re-learn anything.</dd>
<dt>active and standby</dt>
<dd>One router answering for the virtual address and another waiting to take over.</dd>
<dt>subinterface</dt>
<dd>A logical interface on a physical one, carrying one VLAN with its own address.</dd>
<dt>router on a stick</dt>
<dd>Routing between VLANs over a single trunked link using subinterfaces.</dd>
</dl>

## What breaks without this

**All the other redundancy stops mattering.** Two uplinks and two switches
protect everything except the one address every host was configured with.

**Failover takes as long as somebody's arrival at the office.** A host does not
retry a different gateway, because it does not know one exists.

**Inter-VLAN routing needs a physical interface per VLAN, which does not scale.**
Twelve VLANs and a router with four ports is a problem subinterfaces solve.

## The gateway problem

A host sends anything off its own network to its default gateway. That is one
address, configured by DHCP or by hand, and topic 21 established that it is just
a route: `0.0.0.0/0 via` that address.

The host has no fallback. If the router holding that address stops answering, the
host keeps sending to it, keeps getting nothing, and has no mechanism for trying
anything else. Adding a second router with a different address does nothing,
because no host has been told about it.

Changing every host is not a solution either. DHCP could hand out a different
gateway, but only when leases renew, which is hours.

**So the redundancy has to happen without the host knowing.** Two routers, one
address between them, and whichever is alive answers for it. That is first hop
redundancy, and every protocol that does it works the same way at this level of
detail.

The shared address is the virtual IP, and it is what hosts are configured with.
Neither router uses it as its own; it is a third address they both know about, and
the active one answers for it.

**The virtual MAC is the part people miss and it is the part that makes failover
fast.** A host does not send to an IP address, it sends to the MAC address it
learned by ARP. If failover only moved the IP, every host would keep sending
frames to the dead router's MAC until its ARP cache expired, which is minutes.
Sharing a MAC address as well means the new active router answers to the same
layer 2 address, and no host has to notice anything.

That is also why the switches recover quickly. Topic 14 established that a frame
arriving from a known MAC on a different port updates the forwarding table
immediately, so the first frame the new active router sends moves the entry.

<figure class="learn-figure">
<svg viewBox="0 0 720 340" role="img" aria-labelledby="fhrp-title" style="width:100%;height:auto;">
<title id="fhrp-title">Two routers sharing one virtual address and one virtual MAC, with every host on the segment configured to use it as their gateway</title>
<g font-family="ui-monospace, monospace" fill="currentColor">
<rect x="250" y="18" width="220" height="62" rx="4" fill="currentColor" fill-opacity="0.16" stroke="currentColor" stroke-width="1.8" stroke-dasharray="6 4"/>
<text x="360" y="38" text-anchor="middle" font-size="11.5">the shared identity</text>
<text x="360" y="55" text-anchor="middle" font-size="10.5" fill-opacity="0.85">one virtual IP, 10.0.0.1</text>
<text x="360" y="71" text-anchor="middle" font-size="10.5" fill-opacity="0.85">and one virtual MAC</text>
<path d="M 300 80 L 200 108" stroke="currentColor" stroke-width="1.8" fill="none"/>
<path d="M 420 80 L 520 108" stroke="currentColor" stroke-width="1.6" stroke-dasharray="5 4" fill="none"/>
<text x="196" y="100" text-anchor="end" font-size="10.5">held here</text>
<text x="524" y="100" font-size="10.5" fill-opacity="0.8">not held here, yet</text>
<rect x="90" y="110" width="170" height="62" rx="3" fill="currentColor" fill-opacity="0.14" stroke="currentColor" stroke-width="1.8"/>
<text x="175" y="130" text-anchor="middle" font-size="11.5">R1</text>
<text x="175" y="146" text-anchor="middle" font-size="10.5" fill-opacity="0.85">its own address 10.0.0.2</text>
<text x="175" y="162" text-anchor="middle" font-size="10.5" fill-opacity="0.85">active, and answering</text>
<rect x="460" y="110" width="170" height="62" rx="3" fill="currentColor" fill-opacity="0.06" stroke="currentColor" stroke-opacity="0.5"/>
<text x="545" y="130" text-anchor="middle" font-size="11.5">R2</text>
<text x="545" y="146" text-anchor="middle" font-size="10.5" fill-opacity="0.8">its own address 10.0.0.3</text>
<text x="545" y="162" text-anchor="middle" font-size="10.5" fill-opacity="0.8">standby, and silent</text>
<g stroke="currentColor" stroke-opacity="0.5">
<line x1="175" y1="172" x2="175" y2="214"/>
<line x1="545" y1="172" x2="545" y2="214"/>
<line x1="110" y1="214" x2="110" y2="246"/>
<line x1="360" y1="214" x2="360" y2="246"/>
<line x1="610" y1="214" x2="610" y2="246"/>
</g>
<line x1="40" y1="214" x2="680" y2="214" stroke="currentColor" stroke-width="2.4"/>
<text x="40" y="206" font-size="10.5" fill-opacity="0.7">one segment</text>
<g font-size="10.5">
<rect x="45" y="246" width="130" height="44" rx="3" fill="currentColor" fill-opacity="0.1" stroke="currentColor" stroke-opacity="0.5"/>
<text x="110" y="264" text-anchor="middle" font-size="11">host</text>
<text x="110" y="280" text-anchor="middle" fill-opacity="0.85">gateway 10.0.0.1</text>
<rect x="295" y="246" width="130" height="44" rx="3" fill="currentColor" fill-opacity="0.1" stroke="currentColor" stroke-opacity="0.5"/>
<text x="360" y="264" text-anchor="middle" font-size="11">host</text>
<text x="360" y="280" text-anchor="middle" fill-opacity="0.85">gateway 10.0.0.1</text>
<rect x="545" y="246" width="130" height="44" rx="3" fill="currentColor" fill-opacity="0.1" stroke="currentColor" stroke-opacity="0.5"/>
<text x="610" y="264" text-anchor="middle" font-size="11">host</text>
<text x="610" y="280" text-anchor="middle" fill-opacity="0.85">gateway 10.0.0.1</text>
</g>
<text x="12" y="314" font-size="11">Every host points at 10.0.0.1, and neither router owns that address.</text>
<text x="12" y="332" font-size="11" fill-opacity="0.85">If R1 stops, the dashed line becomes the solid one and no host changes anything at all.</text>
</g>
</svg>
<figcaption>The dashed box at the top is not a device. It is an address and a MAC address that exist between the two routers, and the lines below say which router is currently answering for them. Each router also keeps its own address, which is what you use to log in to it and what it uses to talk to the other one. The hosts know none of that. They were given one gateway address and they will keep using it through a failover, an upgrade, or a router being physically replaced, because as far as they can tell nothing happened.</figcaption>
</figure>

The exam names first hop redundancy as a concept and, per the research for this
track, names no specific protocol. HSRP, VRRP and GLBP appear nowhere in the
objectives, and VRRP was dropped from the acronym list between exam versions. Know
what the mechanism is for.

<details class="deeper">
<summary>If you already work on networks: preemption, and the failover that flaps</summary>

Two configuration decisions cause most of the real trouble with these protocols,
and neither is about the failover itself.

**Preemption** decides what happens when the original active router comes back. On,
and it takes the role back immediately. Off, and the current active router keeps
it until it fails.

Preemption on sounds right, because the primary is usually the better router. It
also means every recovery is a second failover, and every failover interrupts
traffic briefly. A router that is flapping, rebooting repeatedly, or recovering
while its uplink is still down, causes an outage on every cycle. With preemption
off, one failover happens and things stay stable until somebody decides otherwise.

The usual answer is preemption on with a delay, long enough for the returning
router to have finished booting, established its routing adjacencies and actually
be able to forward, rather than merely being able to answer.

**Tracking** is the other one, and its absence produces the most confusing failure
in this material. The protocol watches whether the active router is alive. By
default it does not watch whether that router can still reach anything.

So a router whose uplink has failed is perfectly healthy from the protocol's point
of view. It keeps the virtual address, keeps answering for it, and every host on
the segment keeps sending traffic to a router that has nowhere to send it. The
standby router is fine, has a working uplink, and is doing nothing.

Interface tracking fixes it: the active router lowers its own priority when a
watched interface goes down, which lets the standby take over. Configuring it is
one line and forgetting it is common, and the symptom is a total outage with two
healthy routers and a failover mechanism that never engaged.

</details>

## Subinterfaces and router on a stick

The second half of this topic is a different way of making one physical thing
serve several logical ones.

Topic 16 ended on the fact that VLANs cannot talk without something that routes,
and the obvious implementation is a router interface per VLAN. That works and it
runs out of ports: twelve VLANs needs twelve interfaces, and routers do not have
twelve interfaces.

The alternative is one link carrying all the VLANs as a trunk, with the router
splitting it logically.

<details class="predict">
<summary>One physical link between two routers. Two subinterfaces are created for VLANs 10 and 20. What does the router see?</summary>

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology three-routers
# one physical link, two VLANs, one router: subinterfaces
$ ip -n r1 link add link r1-r2 name r1-r2.10 type vlan id 10
$ ip -n r1 link add link r1-r2 name r1-r2.20 type vlan id 20
$ ip -n r1 addr add 10.0.10.1/24 dev r1-r2.10
$ ip -n r1 addr add 10.0.20.1/24 dev r1-r2.20
$ ip -n r1 link set r1-r2.10 up
$ ip -n r1 link set r1-r2.20 up
$ ip -n r1 -br addr show | grep r1-r2
r1-r2.10@r1-r2   UP             10.0.10.1/24 fe80::9c54:f4ff:fe23:b16b/64 
r1-r2.20@r1-r2   UP             10.0.20.1/24 fe80::9c54:f4ff:fe23:b16b/64 
r1-r2@if3        UP             10.0.12.1/30 fe80::9c54:f4ff:fe23:b16b/64 
# each one is a separate network on the same cable
$ ip -n r1 route | grep "10.0.[12]0"
10.0.10.0/24 dev r1-r2.10 proto kernel scope link src 10.0.10.1 
10.0.20.0/24 dev r1-r2.20 proto kernel scope link src 10.0.20.1 
# and a second address on an interface, which is how a virtual IP is held
$ ip -n r1 addr add 10.0.1.254/24 dev r1-h1
$ ip -n r1 -br addr show r1-h1
r1-h1@if10       UP             10.0.1.1/24 10.0.1.254/24 fe80::74cc:64ff:fe9c:3bd3/64 
```

</details>

Three interfaces where there is one cable. `r1-r2` is the physical link with its
own address, and `r1-r2.10` and `r1-r2.20` are logical interfaces on top of it,
each tagged into its VLAN and each with an address in a different network.

Look at the routing table underneath. Two connected routes, `10.0.10.0/24` and
`10.0.20.0/24`, each pointing at a different subinterface. As far as routing is
concerned these are two separate networks on two separate interfaces, and topic
21's rules apply unchanged. The fact that they share a cable is invisible above
the link layer.

**That is router on a stick.** One trunked link, a subinterface per VLAN, and the
router routes between them by ordinary means. Traffic from VLAN 10 to VLAN 20
arrives tagged for 10, goes up to the router, comes back down tagged for 20, and
crosses the same cable twice.

Which is the limitation, and it is worth stating plainly. All inter-VLAN traffic
traverses one link in both directions, so that link's capacity is shared by
everything. It is fine for a small network and it is the reason layer 3 switches
exist: a switch that routes internally moves traffic between VLANs at switching
speed without any of it leaving the box.

The last capture line shows a second address added to an existing interface, which
is the mechanism a virtual IP uses. One interface, more than one address, and
nothing about that is special.

<details class="deeper">
<summary>If you already work on networks: where the exam's terms map onto what you will configure</summary>

The vocabulary in this area is unusually vendor-flavoured, and it is worth knowing
which words are concepts and which are somebody's product name.

**FHRP** is the concept and the exam's term. It is not a protocol. The
implementations are HSRP, which is Cisco's, VRRP, which is the open standard in
RFC 5798, and GLBP, which is Cisco's again and additionally load balances rather
than keeping a standby idle. The research for this track found that none of the
three appears anywhere in the N10-009 objectives, so the examinable thing is what
the mechanism does.

**Subinterface** is the general term and what most vendors call it. On Linux the
same thing is a VLAN interface, created as a child of a physical one, which is
what the capture shows. Same construct, and the naming convention with a dot and
the VLAN number is close to universal.

**Switch virtual interface**, from topic 16, is the layer 3 switch version of the
same idea. Rather than a subinterface on a router, it is an address on the switch
inside a VLAN, and the switch routes between its own VLANs internally. For a
network of any size this has replaced router on a stick almost entirely, because
it removes the shared link.

One thing worth carrying into a design conversation: a virtual IP is not only for
routers. The same idea, one address held by whichever member of a pair is
currently active, is how firewalls, load balancers and clustered services present
themselves. The mechanism differs and the property is the same, which is that
clients are configured with an address that outlives any individual machine.

</details>

## Prove it

You have this when you can look at an interface list and say how many networks
are on one cable.

```bash
./blog/scripts/netlab.sh --topo topologies/three-routers.sh -- \
  'ip -n r1 link add link r1-r2 name r1-r2.10 type vlan id 10
ip -n r1 addr add 10.0.10.1/24 dev r1-r2.10
ip -n r1 link set r1-r2.10 up
ip -n r1 -br addr show | grep r1-r2
ip -n r1 route | grep 10.0.10'
```

Two things to confirm. The subinterface appears as its own interface with its own
address, named after its parent and its VLAN. And it produces an ordinary
connected route, indistinguishable in the routing table from one on a physical
interface.

For the redundancy half, the honest position is in the provenance note below: this
lab can show a second address on an interface, which is the mechanism, and it
cannot show two routers negotiating who holds it.

## What trips people up

### 1. Thinking redundant links protect the default gateway

They protect everything except the one address every host was configured with. A
host has no fallback and no way to learn about a second router.

### 2. Forgetting the virtual MAC

Moving only the IP address would leave every host sending frames to the dead
router's MAC until its ARP cache expired. Sharing the MAC is what makes failover
fast enough to be useful.

### 3. Assuming the protocol watches the uplink

By default it watches whether the active router is alive, not whether it can reach
anything. A router with a dead uplink keeps the virtual address and every host
keeps sending traffic into a hole. Interface tracking is the fix and it is one
line people forget.

### 4. Leaving preemption on with no delay

Every recovery becomes a second interruption, and a flapping router produces one
per cycle. A delay long enough for the returning router to actually be able to
forward is the usual answer.

### 5. Expecting router on a stick to scale

All inter-VLAN traffic crosses the same link twice, so that link is a shared
bottleneck. A layer 3 switch routes internally and does not have this problem.

### 6. Looking for a named protocol in the objectives

FHRP is named as a concept and no implementation is. HSRP, VRRP and GLBP appear
nowhere in N10-009, so learn what the mechanism does rather than which vendor
calls it what.

## Work it through

A branch office has two routers, both connected to the same switch, both with
uplinks to head office, and a first hop redundancy protocol configured between
them. The primary router's uplink fails. Users lose all access to head office and
to the internet. Both routers are up and the failover never happened.

The mechanism did exactly what it was configured to do, and what it was configured
to do was not what anybody wanted.

The protocol watches whether the active router is alive. The active router is
alive: it is powered on, its interface to the switch is up, and it is sending its
messages normally. Nothing about its uplink being dead is visible to a mechanism
that only checks whether the peer is responding.

So the active router keeps the virtual address, keeps answering ARP for it, and
every host on the segment keeps sending its off-network traffic to a router with
nowhere to forward it. The standby router has a working uplink and is doing
nothing, because as far as it can tell there is no problem.

The fix is interface tracking: the active router watches its own uplink and lowers
its priority when that interface goes down, which lets the standby take over. One
line of configuration, and its absence is invisible until precisely this failure.

Two things worth checking at the same time. Whether preemption is configured and
whether it has a delay, because when the uplink comes back the primary should not
take the role until it can actually forward. And whether anything monitors that
the expected router is the active one, since a failover that happened silently
weeks ago leaves you running on the standby with no redundancy at all and nobody
aware of it.

The general shape is worth naming because it recurs: a redundancy mechanism that
monitors the wrong thing gives you the cost of the complexity and none of the
protection, and it tests perfectly, because unplugging the router is the failure
everybody rehearses.

## Try it

**Add a second address.** On any machine, add another address to an interface with
`ip addr add`, and confirm both answer. That is the mechanism a virtual IP uses,
without the negotiation.

**Build a subinterface.** Run the **Prove it** commands, or do the same on a spare
machine, and look at how the routing table treats it. It is an ordinary interface
in every way that matters above layer 2.

**Find out what your gateway is.** Check the default route on your own machine,
then look at the ARP entry for that address. On a network with first hop
redundancy the MAC will usually be a virtual one, and the ranges reserved for
those are documented and recognisable once you have seen one.

## Check yourself

<details class="qa">
<summary>Why does a network with two uplinks and two switches still lose everything when one router reboots?</summary>

Because every host is configured with one default gateway address and has no
fallback.

A host sends off-network traffic to that address. If the router holding it stops
answering, the host keeps sending and has no mechanism for trying another. A second
router with a different address helps nothing, because no host knows about it.

First hop redundancy solves it by putting one address between two routers, so the
host's configuration stays correct whichever router is alive.

</details>

<details class="qa">
<summary>Why is a virtual MAC needed as well as a virtual IP?</summary>

Because hosts send frames to a MAC address, not to an IP address.

If only the IP moved, every host on the segment would keep sending to the dead
router's MAC until its ARP cache expired, which is minutes. Sharing the MAC means
the new active router answers to the same layer 2 address and no host notices
anything.

The switches recover on their own, because a frame from a known MAC arriving on a
different port updates the forwarding table immediately.

</details>

<details class="qa">
<summary>An active router's uplink fails and the standby never takes over. Both routers are healthy. Why?</summary>

Because the protocol watches whether the peer is alive, not whether it can reach
anything.

The active router is alive: powered on, interface to the switch up, sending its
messages. Its uplink being dead is invisible to that check, so it keeps the
virtual address and every host keeps sending traffic to a router with nowhere to
forward it.

Interface tracking fixes it by having the active router lower its own priority when
a watched interface goes down. It is one line, and its absence is invisible until
this exact failure.

</details>

<details class="qa">
<summary>What is the argument against leaving preemption enabled with no delay?</summary>

Every recovery becomes a second interruption.

Preemption means the original active router takes the role back as soon as it
returns. That is a failover, and a failover interrupts traffic. A router that is
flapping causes one on every cycle, and a router that has booted but has not yet
established its routing adjacencies takes the role before it can actually forward.

The usual answer is preemption with a delay long enough for the returning router
to be genuinely ready, rather than preemption off entirely.

</details>

<details class="qa">
<summary>What is router on a stick, and what is its limitation?</summary>

Routing between VLANs over one trunked link, using a subinterface per VLAN on the
router. Each subinterface is tagged into its VLAN and has an address in that
VLAN's network, so the router routes between them by ordinary means.

It exists because a router interface per VLAN runs out of ports.

The limitation is that all inter-VLAN traffic crosses that single link twice,
inbound tagged for one VLAN and outbound tagged for another, so the link is a
shared bottleneck for everything. A layer 3 switch routes internally between its
own VLANs and avoids it, which is why it has largely replaced this design.

</details>

<details class="qa">
<summary>Why does the exam name FHRP and not HSRP, VRRP or GLBP?</summary>

Because it is testing the concept rather than an implementation.

FHRP is the general term for making a default gateway survive a router failure.
HSRP and GLBP are Cisco's, VRRP is the open standard, and none of the three appears
anywhere in the N10-009 objectives. VRRP was in the previous version's acronym list
and was dropped.

The examinable thing is what the mechanism does: one address shared between
routers, held by whichever is active, with a shared MAC so hosts do not have to
notice.

</details>

## References

- [RFC 5798, Virtual Router Redundancy Protocol Version 3](https://www.rfc-editor.org/rfc/rfc5798) - IETF, the open standard implementation of the concept this page describes. Accessed 2026-08-10.
- [IEEE 802.1Q, Bridges and Bridged Networks](https://standards.ieee.org/ieee/802.1Q/10323/) - IEEE Standards Association, for the tagging the subinterfaces rely on. Accessed 2026-08-10.
- [ip-link(8)](https://man7.org/linux/man-pages/man8/ip-link.8.html) - Linux man-pages project, on creating VLAN interfaces. Accessed 2026-08-10.

**Where the output came from.** The captured block was produced on
`blog/scripts/topologies/three-routers.sh` through `blog/scripts/netlab.sh`. The
subinterfaces are real VLAN interfaces on a real link, and the connected routes
they produce are the kernel's.

The redundancy half of this page is described rather than captured, and the reason
is worth stating. Demonstrating a first hop redundancy protocol needs two routers
negotiating which of them holds a shared address, and the exam names no protocol
to demonstrate, so a capture would have to pick an implementation the objectives
deliberately avoid naming. What the lab can show, and does in the last line of the
block, is a second address on an interface, which is the mechanism underneath
without the negotiation on top.

**If you also work on Linux.** [Configuring networking](/learn/linux-plus/configuring-networking)
on the Linux+ track covers VLAN interfaces and multiple addresses from the
administration side, including making them survive a reboot.
