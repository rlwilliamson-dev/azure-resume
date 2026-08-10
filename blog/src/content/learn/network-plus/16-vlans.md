---
title: "VLANs"
description: "One switch, two companies, and traffic that must never mix. What a VLAN separates and what it deliberately does not, why a VLAN is exactly a broadcast domain, and the demonstration that separates VLAN membership from subnet membership once and for all."
deck: "One switch, two companies, and traffic that must never mix"
track: "network-plus"
level: "working"
order: 170
objectives:
  - "Say what a VLAN separates and at which layer"
  - "Explain why two hosts in the same subnet can be unable to reach each other"
  - "Read a VLAN configuration and say which port carries what"
  - "Explain what has to exist before two VLANs can talk"
  - "Say why a VLAN is a broadcast domain rather than merely containing one"
prerequisites: ["unicast-multicast-anycast-broadcast"]
tags: ["network-plus", "networking", "switching", "vlans"]
updated: 2026-08-10
draft: false
examObjectives:
  - exam: "n10-009"
    domain: "2.0"
    objective: "2.2"
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
  - symptom: "Two machines in the same subnet cannot reach each other"
    anchor: "the-demonstration-that-settles-it"
  - symptom: "A machine gets no DHCP address on a port that used to work"
    anchor: "access-ports-and-the-port-vlan-id"
---

> **Before you read.** A building is shared by two companies. There is one
> switch. Traffic from one company must never reach the other, and buying a
> second switch is not on the table.
>
> Both companies are told to use whatever addresses they like.
>
> **What separates them, and what happens if they both pick 192.168.1.0/24?**

Everything in the last two topics assumed one switch means one network. A VLAN
is the feature that breaks that assumption, and the reason it is worth its own
topic is that people learn what it does and then quietly believe it does
something slightly different.

### Some words you will need

<dl class="terms">
<dt>VLAN</dt>
<dd>Virtual LAN. A set of switch ports treated as though they were a separate switch.</dd>
<dt>VLAN ID</dt>
<dd>A number from 1 to 4094 naming one VLAN. Also called a VID.</dd>
<dt>access port</dt>
<dd>A port belonging to exactly one VLAN, carrying untagged traffic to and from one device.</dd>
<dt>PVID</dt>
<dd>Port VLAN ID. The VLAN an access port puts untagged traffic into.</dd>
<dt>SVI</dt>
<dd>Switch virtual interface. An IP address on the switch, inside one VLAN, so the switch can route or be managed.</dd>
<dt>inter-VLAN routing</dt>
<dd>Getting traffic from one VLAN to another, which needs a router or a layer 3 switch.</dd>
</dl>

## What breaks without this

**You put two things on one network that should never have met.** A VLAN is the
main tool for keeping a guest network, a camera network and a payroll department
apart on shared hardware. Getting it wrong is a security failure rather than an
outage.

**Same-subnet machines that cannot see each other look like broken hardware.**
It is a diagnosis that never occurs to people, because everything on both
machines is correct.

**Every remaining switching topic assumes it.** Trunking, spanning tree per
VLAN, and the layer 2 attacks are all built on this.

## A VLAN divides one switch into several

A switch has one forwarding table and floods broadcasts to every port. A VLAN
changes that: the switch keeps its ports in labelled groups, and every rule from
the previous topics applies within a group and stops at its edge.

Learning happens per VLAN. Flooding reaches only ports in the same VLAN.
Broadcasts reach only ports in the same VLAN. A port in VLAN 10 and a port in
VLAN 20 are, for every purpose the switch has, on different switches.

**So a VLAN is a broadcast domain.** Not a thing that contains one, not a thing
that resembles one. Drawing a VLAN boundary and drawing a broadcast domain
boundary are the same act, which is why the previous topic's answer to "where
does a broadcast stop" was a router or a VLAN.

That is the whole idea. What people then get wrong is what it has to do with
addresses.

## The demonstration that settles it

Two hosts. Same subnet, same mask, same switch, both configured correctly. One is
in VLAN 10 and one is in VLAN 20.

<details class="predict">
<summary>h1 is 10.0.10.1/24 and h5 is 10.0.10.5/24. They are plugged into the same switch. Can they reach each other?</summary>

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology vlan-switch
# h1 and h3 are both in VLAN 10, on different switches, across a trunk
$ ip netns exec h1 ping -c 1 -W 2 10.0.10.3 | tail -3
--- 10.0.10.3 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 0.153/0.153/0.153/0.000 ms
# h5 is in VLAN 20 and holds an address inside VLAN 10's subnet
$ ip -n h5 addr show h5eth0 | grep "inet "
    inet 10.0.10.5/24 scope global h5eth0
# so h1 believes h5 is a neighbour on its own segment
$ ip netns exec h1 ping -c 2 -W 1 10.0.10.5
PING 10.0.10.5 (10.0.10.5) 56(84) bytes of data.

--- 10.0.10.5 ping statistics ---
2 packets transmitted, 0 received, 100% packet loss, time 1007ms

$ ip -n h1 neigh show
10.0.10.3 dev h1eth0 lladdr 02:00:00:00:00:03 REACHABLE 
10.0.10.5 dev h1eth0 INCOMPLETE 
```

</details>

No. And look at how it fails.

`h1` reaches `h3` perfectly, and h3 is on a different physical switch at the far
end of a trunk. Distance is irrelevant; VLAN membership is not.

`h1` cannot reach `h5`, which is plugged into the same switch as it is. The
neighbour table says `INCOMPLETE`, which topic 05 met in the mask mismatch
capture and which means the same thing here: h1 sent an ARP request and nothing
came back.

**h1 is behaving perfectly correctly.** Its mask says 10.0.10.5 is a neighbour,
so it does what a host does with a neighbour, which is ARP for it. The ARP
request is a broadcast. The broadcast is confined to VLAN 10. h5 is in VLAN 20
and never hears it, so it never answers.

Two things worth carrying away, and the second is the one that catches people out
in a real building.

**Addresses have nothing to do with it.** The two hosts share a subnet and it
changes nothing, because a VLAN separates at layer 2 and the mask is a layer 3
idea. Nothing on either host can see the boundary.

**The symptom is indistinguishable from several other faults.** An `INCOMPLETE`
neighbour entry is what you get from a wrong mask, a VLAN mismatch, a dead
machine, a bad cable, or a port that is down. The fix in each case is completely
different, which is why the troubleshooting topics later spend their time on
telling them apart rather than on any one of them.

<details class="deeper">
<summary>If you already work on networks: why the separation cannot be beaten from a host, and where it can</summary>

The useful property of VLAN separation is that a host cannot opt out of it. It is
worth knowing exactly why, and then knowing the two places that stops being true.

A frame arriving on an access port is tagged by the switch, on entry, with that
port's VLAN. The host does not choose. It cannot request a different VLAN, cannot
send a tagged frame and have the tag believed, and has no way to see which VLAN it
is in. Every forwarding decision from that point uses a label the switch applied.
So a compromised machine on the guest VLAN cannot reach the payroll VLAN by
reconfiguring itself, whatever it does to its own addresses.

That is a genuinely strong property and it is why VLANs are used for separation
rather than merely for tidiness.

The two places it weakens are both about trust in the wrong direction.

A trunk port does believe tags, because believing tags is what a trunk is for. A
device plugged into a port that is configured as a trunk, or that can be
persuaded to become one, can place itself in any VLAN by tagging its own frames.
That is why ports facing users are configured as access ports explicitly and why
automatic trunk negotiation is turned off in serious configurations. The next
topic covers the attack in detail.

The second is the router. VLANs separate at layer 2, and the moment somebody adds
inter-VLAN routing to make two of them talk, the separation becomes whatever the
access list on that router says. This is the common real-world hole: the VLANs
are correct, the router joins them all, and nobody wrote the rules. The
separation was never removed, it was just routed around.

So the accurate summary is that a VLAN is a strong layer 2 boundary and says
nothing at all about layer 3 policy. Topic 55 covers building the second half.

</details>

## Access ports and the port VLAN ID

The configuration on the switch is short, and reading it is most of what the exam
asks.

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology vlan-switch
# what each port on this switch is allowed to carry
$ ip netns exec sw1 bridge vlan show
port              vlan-id  
sw1-h1            10 PVID Egress Untagged
sw1-h2            20 PVID Egress Untagged
sw1-h5            20 PVID Egress Untagged
sw1-trunk         10
                  20
```

Each host port carries one VLAN and is marked `PVID Egress Untagged`, which is
two statements bundled together.

**PVID** is what the port does to arriving traffic. A device sends an ordinary
untagged frame, and the switch stamps it into the port's VLAN. That is where
membership is decided.

**Egress Untagged** is what the port does on the way out. It strips the tag
before the frame reaches the device, so the device never learns any of this
happened. A printer, a laptop or a camera plugged into an access port sees
ordinary Ethernet.

The trunk is the exception and it is listed with two VLANs and no untagged
marking, because it carries both with their tags intact. That is the next topic.

Two practical notes the exam likes. VLAN 1 is the default on essentially every
switch, so a port nobody configured is in VLAN 1, and leaving anything important
there is discouraged for that exact reason. And a port with no VLAN assigned is
not isolated, it is in the default VLAN, which is a different and more dangerous
thing.

<details class="deeper">
<summary>If you already work on networks: voice VLANs, which are the exception to one port one VLAN</summary>

An access port carries one VLAN, and then desk phones broke that rule for a
practical reason worth understanding.

A desk phone has a switch built into it. The phone plugs into the wall and the
computer plugs into the phone, so one cable serves both. But voice and data want
different treatment: voice wants its own subnet, its own quality of service
handling, and usually its own security policy, while the computer wants the
ordinary data network.

The voice VLAN is the compromise. The port is configured with a data VLAN and a
voice VLAN, and the phone tags its own traffic into the voice VLAN while the
computer's untagged traffic falls into the data VLAN by the PVID rule above. So
the port is an access port for the computer and something close to a trunk for
the phone.

The phone learns which VLAN to tag with from the switch, usually over LLDP or
CDP, which is why a phone plugged into a correctly configured port picks up its
settings without anybody typing anything into it.

Two things follow that are worth knowing before you meet them.

This is a documented exception to the one-VLAN rule and it is also a small hole
in the argument in the panel above, because the port now accepts tagged frames
for at least one VLAN. Anything plugged in where a phone was expected can use
that.

And it is the usual reason a desk has one cable and two networks, which surprises
people looking at a patch panel and counting ports against devices.

</details>

## What a VLAN does not do

The separation is real and it is only at layer 2. Three consequences.

**Two VLANs cannot talk without something that routes.** They are different
broadcast domains, and moving between broadcast domains is what a router does.
On dedicated hardware that is a router interface per VLAN, or a single trunked
interface with subinterfaces, which topic 26 covers as router on a stick. On a
layer 3 switch it is a switch virtual interface per VLAN, and the switch routes
between them itself.

**A VLAN is not encryption.** Anything with access to a port in a VLAN sees that
VLAN's broadcast and flooded traffic, exactly as topic 14 described. The
separation is from other VLANs, not from other machines in the same one.

**A VLAN does not imply a subnet, and a subnet does not imply a VLAN.** They are
independent, as the capture above demonstrates. Every sane design maps one to one
because anything else is confusing, and that is a convention rather than a rule.

The SVI is worth naming properly because it is the thing that makes a switch
manageable. A switch with no IP address is unreachable, and giving it one means
putting it in a VLAN: the SVI is an address on the switch, inside a chosen VLAN,
usually a dedicated management one. That is why "which VLAN is the switch
management interface in" is a real design question and why the answer is almost
never VLAN 1.

<details class="deeper">
<summary>If you already work on networks: how many VLANs there are, and where the number goes</summary>

The VLAN ID field is 12 bits, so 4096 values, and two of them are reserved: 0
means priority tagging with no VLAN, and 4095 is reserved. That gives 1 to 4094
usable, which is the number to quote.

Four thousand sounds generous until you meet the two places it is not.

A cloud or hosting provider that gives each customer a VLAN runs out at a few
thousand customers per switching domain, which is nothing at that scale. That
limit is the direct reason VXLAN exists, adding a 24 bit identifier for about
sixteen million segments by carrying layer 2 frames inside UDP. Topic 28 covers
it, and the short version is that the number of tenants outgrew the field.

The second is spanning tree. A switch running one spanning tree instance per VLAN
is doing real work per VLAN, and several hundred VLANs on modest hardware is a
control plane load rather than a configuration detail. That is what the multiple
spanning tree variants exist to solve, by mapping many VLANs onto a few
instances. Topic 19 covers spanning tree and the research for this track found
that N10-009 names no variant at all, so know the mechanism and do not memorise
the acronyms.

Worth also knowing that the usable range is conventionally split, with the lower
numbers used for ordinary VLANs and a higher range treated as extended, because
some older equipment handled the two differently. Modern kit largely does not
care, and you will still meet designs that respect the split for historical
reasons.

</details>

## Prove it

You have this when you can predict, from a configuration, whether two machines can
reach each other, and be right for the right reason.

The topology is committed, so the demonstration is one command:

```bash
./blog/scripts/netlab.sh --topo topologies/vlan-switch.sh -- \
  'ip netns exec sw1 bridge vlan show; ip netns exec h1 ping -c 1 -W 1 10.0.10.5'
```

Then answer three questions about the output. Which VLAN is each port in? Which
two hosts share a subnet but not a VLAN? And what would you change to make them
reach each other, given that changing an address would not help?

On real equipment the command is different and the output says the same things: a
list of ports, the VLAN each belongs to, and whether traffic leaves tagged or
untagged. If you have a managed switch, find that page and compare it to the
block above. The vocabulary transfers directly.

## What trips people up

### 1. Believing a shared subnet means reachable

The capture on this page is two hosts in the same subnet on the same switch that
cannot reach each other. The mask is a layer 3 idea and a VLAN separates at layer
2, so a host's own configuration cannot see the boundary.

### 2. Thinking a VLAN encrypts or hides traffic within itself

It separates one VLAN from another. Inside a VLAN, broadcasts and flooded frames
reach every port exactly as they would on a switch with no VLANs at all.

### 3. Expecting two VLANs to talk because they are on the same switch

They cannot without something that routes: a router interface per VLAN, a
trunked interface with subinterfaces, or a switch virtual interface on a layer 3
switch. Being in the same box changes nothing.

### 4. Treating an unconfigured port as isolated

A port nobody configured is in VLAN 1, the default, along with every other
unconfigured port. That is the opposite of isolated, and it is why leaving
anything sensitive in VLAN 1 is discouraged.

### 5. Reading PVID as a filter

PVID decides what VLAN untagged traffic is put into on the way in. It is an
assignment rather than a restriction, and the restriction is the separate
question of which VLANs the port is a member of.

### 6. Assuming the VLAN number means something elsewhere

A VLAN ID is local to the switching domain that agrees on it. VLAN 10 on one
site and VLAN 10 on another are unrelated unless somebody deliberately joined
them, and the number carries no meaning of its own.

## Work it through

A company takes over half a floor and inherits one 48 port switch. They need the
office network, a guest wireless network, a set of door controllers, and a
management network for the switch itself. Somebody suggests four switches.

Four VLANs on the one switch does the separation, and the interesting part is
what that decision leaves you still to decide.

Start with what the VLANs give you for free. Four broadcast domains, so guest
traffic and door controller traffic never reach the office network at layer 2,
and a compromised guest laptop cannot ARP its way to anything. That is the
security property that made this worth doing, and it holds without any further
configuration.

Now what it does not give you. The four VLANs cannot talk at all, which is
correct for guests and wrong for almost everything else: the office network needs
the internet, and somebody needs to reach the door controllers to administer
them. So there has to be a router, and the moment it exists the real policy work
begins, because a router with no access list has just undone the separation.

That is the step people skip. The VLANs get built, the router gets configured to
make things work, and nobody goes back to write the rules about what may cross.

Two smaller decisions worth making deliberately. The management VLAN should not
be VLAN 1, because VLAN 1 is where every unconfigured port lands and a mistake
elsewhere should not put somebody on the management network. And the door
controllers are the case for thinking about what happens if one of them is
compromised, since they are appliances nobody patches and they sit in a corridor.

Nothing here is about the switch's capability. All four VLANs are a few lines of
configuration. What takes the time is deciding what may cross between them, and
that is a document rather than a command.

## Check yourself

<details class="qa">
<summary>Two hosts are on the same switch with addresses 10.0.10.1/24 and 10.0.10.5/24 and cannot reach each other. Both are configured correctly. What is happening?</summary>

They are in different VLANs.

A VLAN separates at layer 2, and the subnet mask is a layer 3 idea, so the two
are independent. Each host looks at its mask, concludes the other is a neighbour,
and sends an ARP request. That request is a broadcast, the broadcast is confined
to the sender's VLAN, and the other host never hears it.

The neighbour table shows `INCOMPLETE`, which means the request went out and
nothing came back. Changing addresses would not help, because addresses are not
what is separating them.

</details>

<details class="qa">
<summary>Why is a VLAN a broadcast domain rather than something that contains one?</summary>

Because the boundary is the same boundary. A broadcast is flooded to every port
in the VLAN and to no port outside it, which is precisely the definition of a
broadcast domain.

Before VLANs, a broadcast domain was everything on a switch, and the only way to
create another one was a router. A VLAN lets one switch hold several, so drawing
a VLAN and drawing a broadcast domain became the same act.

</details>

<details class="qa">
<summary>An access port is configured with PVID 20. What does that do to traffic in each direction?</summary>

On the way in, untagged traffic arriving from the device is placed into VLAN 20.
The device does not ask for this and cannot influence it.

On the way out, the tag is stripped before the frame reaches the device, so the
device sees ordinary untagged Ethernet and has no idea a VLAN exists.

That combination is what makes VLAN membership something the switch decides
rather than something the host can claim.

</details>

<details class="qa">
<summary>What has to exist before two VLANs can exchange traffic, and what is the risk once it does?</summary>

Something that routes. A router with an interface in each VLAN, a router with one
trunked interface carrying subinterfaces, or a layer 3 switch with a switch
virtual interface per VLAN.

The risk is that the layer 2 separation is now bypassable by design. VLANs
separate at layer 2 and say nothing about what a router will forward, so a router
joining all the VLANs with no access list has restored full connectivity between
them.

This is the common real-world hole. The VLANs are configured correctly, the
routing was added to make something work, and the policy was never written.

</details>

<details class="qa">
<summary>Why is it discouraged to use VLAN 1 for anything that matters?</summary>

Because it is the default on essentially every switch, so every port that nobody
has configured is already in it.

That makes VLAN 1 the destination for mistakes. A port reset to defaults, a new
switch out of the box, or a device plugged into a spare socket all land there. If
VLAN 1 is also the management network or an internal one, a configuration slip
becomes an access problem.

Putting management in a dedicated VLAN means an unconfigured port grants access
to nothing useful.

</details>

<details class="qa">
<summary>Can a host place itself in a different VLAN by changing its own configuration?</summary>

Not through an access port. The switch tags arriving frames with the port's VLAN
on entry, the host has no say in it, and a tag the host applies itself is not
believed.

That is what makes VLANs a real separation rather than a convention, and it holds
even against a fully compromised machine.

The exceptions are a port that is a trunk, or one that can be talked into becoming
one, because a trunk believes tags by design. That is why user-facing ports are
configured as access ports explicitly and automatic trunk negotiation is disabled,
and the next topic covers what happens when it is not.

</details>

## References

- [IEEE 802.1Q, Bridges and Bridged Networks](https://standards.ieee.org/ieee/802.1Q/10323/) - IEEE Standards Association, which defines VLANs and the 12 bit VLAN ID. The scope is readable without purchase; the standard is not. Accessed 2026-08-10.
- [bridge(8)](https://man7.org/linux/man-pages/man8/bridge.8.html) - Linux man-pages project, the tool behind both captures on this page. Accessed 2026-08-10.

**Where the output came from.** Both blocks were produced on
`blog/scripts/topologies/vlan-switch.sh` through `blog/scripts/netlab.sh`. A
Linux bridge with VLAN filtering enabled is a VLAN-capable switch, so the
separation shown is the kernel enforcing it rather than an illustration.

The fifth host in that topology exists purely for the capture on this page. Every
other host pair in the lab differs in both subnet and VLAN, which makes a failed
ping ambiguous: it could be either. h5 is in VLAN 20 holding an address inside
VLAN 10's subnet, so when h1 cannot reach it there is exactly one explanation
left.

**If you also work on Linux.** The same bridge VLAN filtering is what container
and virtual machine hosts use to put guests on separate networks, and
[Container images, volumes and networks](/learn/linux-plus/container-images-volumes-and-networks)
on the Linux+ track covers the bridge from that direction.
