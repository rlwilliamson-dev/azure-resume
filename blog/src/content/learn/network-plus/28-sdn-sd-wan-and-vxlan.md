---
title: "SDN, SD-WAN and VXLAN"
description: "Two hundred branch offices and one policy change. What separating the control plane from the data plane actually buys, what SD-WAN does that a router does not, and VXLAN as layer 2 carried over layer 3 with the byte cost that comes with it."
deck: "Two hundred branch offices and one policy change"
track: "network-plus"
level: "working"
order: 285
objectives:
  - "Explain the control plane and data plane split and what separating them buys"
  - "Say what software-defined networking means in practice"
  - "Describe SD-WAN and what application-aware and transport-agnostic mean"
  - "Explain what VXLAN carries and why anybody wants it"
  - "State the MTU cost an overlay imposes and where it comes from"
prerequisites: ["topologies-and-architectures"]
tags: ["network-plus", "networking", "design", "overlay"]
updated: 2026-08-11
draft: false
examObjectives:
  - exam: "n10-009"
    domain: "1.0"
    objective: "1.8"
sources:
  - title: "RFC 7348, Virtual eXtensible Local Area Network (VXLAN)"
    url: "https://www.rfc-editor.org/rfc/rfc7348"
    publisher: "IETF"
    accessed: 2026-08-11
    tier: 1
  - title: "RFC 7426, Software-Defined Networking (SDN): Layers and Architecture Terminology"
    url: "https://www.rfc-editor.org/rfc/rfc7426"
    publisher: "IETF"
    accessed: 2026-08-11
    tier: 1
  - title: "RFC 1191, Path MTU Discovery"
    url: "https://www.rfc-editor.org/rfc/rfc1191"
    publisher: "IETF"
    accessed: 2026-08-11
    tier: 1
  - title: "ip-link(8)"
    url: "https://man7.org/linux/man-pages/man8/ip-link.8.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-11
    tier: 1
symptoms:
  - symptom: "Traffic across a tunnel works for small packets and fails for large ones"
    anchor: "what-an-overlay-costs"
  - symptom: "A policy change has to be made on every device individually"
    anchor: "two-planes-in-every-device"
---

> **Before you read.** Two hundred branch offices, each with a router, each
> configured by hand over the years by whoever was available.
>
> The business wants one change: video conferencing should take the broadband
> circuit and everything else should take the leased line.
>
> **How long does that take, and what is the actual obstacle?**

The obstacle is not the change. Any one of those routers can be configured to do
it in a few minutes. The obstacle is that there are two hundred of them, each
holding its own copy of its own configuration, and nothing knows what all of them
currently say.

Every idea in this topic is an answer to that.

### Some words you will need

<dl class="terms">
<dt>data plane</dt>
<dd>The part of a device that forwards packets. Fast, simple, and doing the same thing millions of times a second.</dd>
<dt>control plane</dt>
<dd>The part that decides what the data plane should do. Routing protocols, policy, adjacency.</dd>
<dt>software-defined networking</dt>
<dd>Moving the control plane off the devices and into something central that programs them.</dd>
<dt>SD-WAN</dt>
<dd>The same idea applied to the links between sites, choosing paths by what the traffic is.</dd>
<dt>overlay</dt>
<dd>A network built on top of another network, whose devices are unaware of it.</dd>
<dt>underlay</dt>
<dd>The real network carrying the overlay. Usually ordinary routed IP.</dd>
<dt>VXLAN</dt>
<dd>An encapsulation that carries Ethernet frames inside UDP, so a segment can span a routed network.</dd>
</dl>

## What breaks without this

**A change costs the same as the number of devices.** Anything configured
per device scales linearly in effort and does not scale at all in confidence,
because nobody can say what all of them currently do.

**Tunnels break large packets and nothing reports it.** Every encapsulation takes
bytes from the same budget, and the symptom is topic 20's, arriving from a
direction people do not expect.

**The vocabulary is unreadable.** This part of the syllabus is mostly words, and
they are words you will meet in procurement documents rather than on a command
line.

## Two planes in every device

Every router and switch does two separate jobs, and separating them in your head
makes this whole topic straightforward.

**The data plane forwards.** A packet arrives, a table is consulted, the packet
leaves. This happens millions of times a second, usually in hardware, and it is
deliberately simple.

**The control plane decides what goes in that table.** Routing protocols run
here. So does policy, and adjacency, and every configuration decision.

Traditionally both live in every device. Each router runs its own control plane,
forms its own adjacencies, and reaches its own conclusions. That is robust, and
it has one consequence: intent lives in two hundred places, expressed two hundred
times, and drifts.

**Software-defined networking moves the control plane out.** One controller holds
the intent and programs the forwarding tables of the devices, which keep their
data planes and lose their independence. The change the business wanted becomes
one change, made once.

<figure class="learn-figure">
<svg viewBox="0 0 720 296" role="img" aria-labelledby="planes-title" style="width:100%;height:auto;">
<title id="planes-title">Three routers each running their own control plane, next to the same three taking their forwarding tables from one controller above them</title>
<g fill="currentColor">
<text x="14" y="20" font-size="11.5">a control plane in every device</text>
<text x="344" y="20" text-anchor="end" font-size="10" fill="var(--accent)">intent in 3 places</text>
<text x="378" y="20" font-size="11.5">one control plane above them</text>
<text x="708" y="20" text-anchor="end" font-size="10" fill="var(--accent)">intent in 1</text>
<rect x="30" y="150" width="92" height="34" rx="3" fill="var(--accent)" fill-opacity="0.22" stroke="var(--accent)" stroke-width="1.8"/>
<text x="76" y="165" text-anchor="middle" font-size="9.5" fill="var(--accent)">control</text>
<text x="76" y="177" text-anchor="middle" font-size="9.5" fill="var(--accent)">plane</text>
<rect x="30" y="192" width="92" height="34" rx="3" fill="currentColor" fill-opacity="0.1" stroke="currentColor" stroke-opacity="0.55"/>
<text x="76" y="207" text-anchor="middle" font-size="9.5">data</text>
<text x="76" y="219" text-anchor="middle" font-size="9.5">plane</text>
<rect x="146" y="150" width="92" height="34" rx="3" fill="var(--accent)" fill-opacity="0.22" stroke="var(--accent)" stroke-width="1.8"/>
<text x="192" y="165" text-anchor="middle" font-size="9.5" fill="var(--accent)">control</text>
<text x="192" y="177" text-anchor="middle" font-size="9.5" fill="var(--accent)">plane</text>
<rect x="146" y="192" width="92" height="34" rx="3" fill="currentColor" fill-opacity="0.1" stroke="currentColor" stroke-opacity="0.55"/>
<text x="192" y="207" text-anchor="middle" font-size="9.5">data</text>
<text x="192" y="219" text-anchor="middle" font-size="9.5">plane</text>
<rect x="262" y="150" width="92" height="34" rx="3" fill="var(--accent)" fill-opacity="0.22" stroke="var(--accent)" stroke-width="1.8"/>
<text x="308" y="165" text-anchor="middle" font-size="9.5" fill="var(--accent)">control</text>
<text x="308" y="177" text-anchor="middle" font-size="9.5" fill="var(--accent)">plane</text>
<rect x="262" y="192" width="92" height="34" rx="3" fill="currentColor" fill-opacity="0.1" stroke="currentColor" stroke-opacity="0.55"/>
<text x="308" y="207" text-anchor="middle" font-size="9.5">data</text>
<text x="308" y="219" text-anchor="middle" font-size="9.5">plane</text>
<text x="14" y="252" font-size="10.5" fill-opacity="0.85">each reaches its own conclusions,</text>
<text x="14" y="268" font-size="10.5" fill-opacity="0.85">and no one place holds all of them</text>
<rect x="470" y="54" width="150" height="40" rx="4" fill="var(--accent)" fill-opacity="0.22" stroke="var(--accent)" stroke-width="2"/>
<text x="545" y="79" text-anchor="middle" font-size="11.5" fill="var(--accent)">one control plane</text>
<rect x="394" y="192" width="92" height="34" rx="3" fill="currentColor" fill-opacity="0.1" stroke="currentColor" stroke-opacity="0.55"/>
<text x="440" y="207" text-anchor="middle" font-size="9.5">data</text>
<text x="440" y="219" text-anchor="middle" font-size="9.5">plane</text>
<rect x="510" y="192" width="92" height="34" rx="3" fill="currentColor" fill-opacity="0.1" stroke="currentColor" stroke-opacity="0.55"/>
<text x="556" y="207" text-anchor="middle" font-size="9.5">data</text>
<text x="556" y="219" text-anchor="middle" font-size="9.5">plane</text>
<rect x="626" y="192" width="92" height="34" rx="3" fill="currentColor" fill-opacity="0.1" stroke="currentColor" stroke-opacity="0.55"/>
<text x="672" y="207" text-anchor="middle" font-size="9.5">data</text>
<text x="672" y="219" text-anchor="middle" font-size="9.5">plane</text>
<g stroke="var(--accent)" stroke-width="1.6" fill="none">
<path d="M 545 94 C 545 140, 440 140, 440 186"/>
<path d="M 435 178 l 5 8 l 5 -8"/>
<path d="M 545 94 C 545 140, 556 140, 556 186"/>
<path d="M 551 178 l 5 8 l 5 -8"/>
<path d="M 545 94 C 545 140, 672 140, 672 186"/>
<path d="M 667 178 l 5 8 l 5 -8"/>
</g>
<text x="378" y="252" font-size="10.5" fill-opacity="0.85">the same tables, programmed from one place,</text>
<text x="378" y="268" font-size="10.5" fill-opacity="0.85">which is now a thing that can be unreachable</text>
</g></svg>
<figcaption>The same three devices under both arrangements. On the left each keeps its own control plane, so each reaches its own conclusions and the intent exists in three places that can disagree. At two hundred branches that is two hundred places, and the practical problem is less that they drift than that no single place holds all of them. On the right the data planes are unchanged, still forwarding at the same speed in the same silicon, and only the deciding has moved. What the drawing adds is the new line: three arrows to one box, which is now something that can be unreachable, and the panel below is about what happens then.</figcaption>
</figure>

RFC 7426 is the free document that gives this vocabulary carefully. It is worth
knowing about mainly because the term is used loosely by vendors, and the RFC
defines the layers precisely enough to tell you what a given product is actually
claiming.

<details class="deeper">
<summary>If you already work on networks: what centralising the control plane costs, and the question to ask any vendor</summary>

Central control is not free, and the costs are the same shape as every other
centralisation in this track.

The controller becomes a dependency. What happens when it is unreachable is the
question that separates products, and the answers vary from "the network keeps
forwarding exactly as it was and you lose the ability to change it" through to
"new flows fail". The first is fine. The second means a controller outage is a
network outage, which is a much bigger claim than it sounds when written in a
datasheet.

Scale moves the problem rather than removing it. A controller programming two
hundred devices holds two hundred devices' worth of state and has to reconcile it
continuously against what those devices actually have. Reconciliation is where
these systems are hard, not in the programming.

And the failure mode changes character. A distributed control plane fails
partially: one router with a bad configuration is one router. A central one fails
globally, because one bad intent is pushed everywhere in seconds. That is the
same trade as any configuration management system, and it is why the good ones
grow staged rollouts.

The question worth asking, of any product in this space: what does the data plane
do when the controller is gone, and how long can it do it for? Everything else
follows from the answer.

</details>

## SD-WAN

SD-WAN is that idea pointed at the links between sites, and it is best understood
by what it replaced.

A branch office traditionally had a router with a leased line, and sometimes a
second circuit for backup. Which traffic took which circuit was a routing
decision, made per destination, configured by hand.

SD-WAN changes the unit of decision from destination to application. Two terms
carry most of its meaning.

**Application aware** means the device identifies what the traffic is, not just
where it is going, and applies policy on that basis. The change at the top of this
page, video on the broadband and everything else on the leased line, is a single
policy expressed once and distributed.

**Transport agnostic** means the underlying circuits are interchangeable. Leased
line, broadband, cellular: the overlay runs across whichever are available, and
the policy decides which to use for what. Adding a cellular backup becomes
plugging it in rather than redesigning the routing.

**Zero-touch provisioning** is the deployment consequence. A device arrives at a
branch, is plugged in, finds the controller, and receives its configuration. It
matters at two hundred sites because the alternative is either a competent person
at each one or a lot of pre-staging.

The honest summary is that none of this does anything a sufficiently determined
engineer could not configure by hand at one site. Its value is entirely in the
two hundred, and in the fact that the two hundred stay consistent.

<figure class="learn-figure">
<svg viewBox="0 0 720 250" role="img" aria-labelledby="sdwan-title" style="width:100%;height:auto;">
<title id="sdwan-title">A branch office with two circuits, where policy sends video conferencing over the broadband and everything else over the leased line</title>
<g fill="currentColor">
<text x="14" y="20" font-size="11">one policy, expressed once, applied at every branch</text>
<rect x="14" y="46" width="150" height="120" rx="4" fill="currentColor" fill-opacity="0.1" stroke="currentColor" stroke-opacity="0.55"/>
<text x="89" y="70" text-anchor="middle" font-size="11">a branch office</text>
<text x="26" y="92" font-size="10" fill="var(--accent)">video call</text>
<text x="26" y="118" font-size="10" fill="currentColor" fill-opacity="0.8">file sync</text>
<text x="26" y="144" font-size="10" fill="currentColor" fill-opacity="0.8">everything else</text>
<rect x="286" y="46" width="150" height="46" rx="4" fill="var(--accent)" fill-opacity="0.2" stroke="var(--accent)" stroke-width="1.8"/>
<text x="361" y="66" text-anchor="middle" font-size="10.5" fill="var(--accent)">broadband</text>
<text x="361" y="82" text-anchor="middle" font-size="10" fill="var(--accent)">cheap, variable</text>
<rect x="286" y="120" width="150" height="46" rx="4" fill="currentColor" fill-opacity="0.1" stroke="currentColor" stroke-opacity="0.55"/>
<text x="361" y="140" text-anchor="middle" font-size="10.5">leased line</text>
<text x="361" y="156" text-anchor="middle" font-size="10" fill-opacity="0.8">dear, predictable</text>
<path d="M 164 88 C 220 88, 230 70, 280 70" stroke="var(--accent)" stroke-width="2.2" fill="none"/>
<path d="M 273 65 l 8 5 l -8 5" stroke="var(--accent)" stroke-width="2.2" fill="none"/>
<path d="M 164 124 C 220 124, 230 142, 280 142" stroke="currentColor" stroke-opacity="0.6" stroke-width="1.8" fill="none"/>
<path d="M 273 137 l 8 5 l -8 5" stroke="currentColor" stroke-opacity="0.6" stroke-width="1.8" fill="none"/>
<text x="200" y="60" font-size="10" fill="var(--accent)">by what it is</text>
<rect x="556" y="82" width="150" height="46" rx="4" fill="currentColor" fill-opacity="0.1" stroke="currentColor" stroke-opacity="0.55"/>
<text x="631" y="110" text-anchor="middle" font-size="10.5">head office</text>
<path d="M 436 70 C 500 70, 500 100, 550 100" stroke="var(--accent)" stroke-width="2" fill="none"/>
<path d="M 436 142 C 500 142, 500 110, 550 110" stroke="currentColor" stroke-opacity="0.6" stroke-width="1.8" fill="none"/>
<text x="14" y="208" font-size="10.5">traditional routing chooses by destination, and every one of these has the same destination.</text>
<text x="14" y="224" font-size="10.5" fill-opacity="0.85">deciding by what the traffic is, rather than where it is going, is what application aware means.</text>
<text x="14" y="240" font-size="10.5" fill-opacity="0.85">transport agnostic is the other half: swap either circuit and the policy is unchanged.</text>
</g></svg>
<figcaption>The same branch, the same head office, and three kinds of traffic with the same destination. That is what makes this hard for traditional routing, which decides by where a packet is going and therefore cannot separate these at all. Deciding by what the traffic is rather than where it is heading is what application aware means, and it is the only way to express the policy at the top of this page. The second half is quieter and matters as much: neither circuit is named in the policy, so replacing the broadband with cellular changes nothing about it.</figcaption>
</figure>

<details class="deeper">
<summary>If you already run branch links: what the measurement costs, and what happens when both paths are bad</summary>

Two things about a per-application decision are worth knowing before it is sold to
you as automatic.

The first is that the decision needs measurements, and measurements are traffic. The
devices probe each path continuously to know its current loss and delay, which is
modest bandwidth and constant. More importantly it is a measurement of the path
between the two SD-WAN devices, so what it can see is what those two endpoints
experience, and a problem affecting one application at one end is invisible to it.

The second is what happens when every path is degraded at once, which is the case
people assume is handled. Choosing the best path is meaningful when one path is good.
When both are congested, the device picks the less bad one and the traffic is still
bad, because moving traffic between paths does not create capacity. That is worth
saying plainly because the technology is often bought as an alternative to buying
enough capacity, and it is a way of using capacity well rather than a substitute for
having it.

Where it genuinely earns its price is the case in the middle: paths that are usually
fine and intermittently are not, at different times, for different reasons. Steering
a call away from the circuit that is briefly losing packets is something no
per-destination routing decision can do, and it happens far more often than a total
failure does.

</details>

## VXLAN, and why layer 2 over layer 3

Now the mechanism, which is the part with something to run.

The problem: two machines need to be on the same layer 2 segment, and they are in
different places with routed network in between. Routers do not forward broadcasts
and do not carry Ethernet frames between subnets, so on the face of it this is not
possible.

The reasons anybody wants it are practical. Virtual machines that move between
hosts keep their addresses. Clustering software that expects its peers to be
adjacent. And a data centre design where the physical network is routed, which
topic 27 explained is what spine and leaf demands, while the tenants on top of it
still want segments.

**VXLAN's answer is to wrap the whole Ethernet frame in UDP** and send it across
the routed network as ordinary traffic. The devices in the middle see UDP between
two addresses and forward it like anything else. RFC 7348 defines it.

<details class="predict">
<summary>Two hosts separated by a router are given overlay addresses on a VXLAN interface. What does the router in the middle see when one pings the other?</summary>

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology vxlan-overlay
# watch the middle of the network while the two hosts talk on the overlay
$ (ip netns exec r timeout 8 tcpdump -i r-h1 -n -c 2 "udp port 4789" > /tmp/mid.txt 2>/dev/null &)
$ sleep 2
$ ip netns exec h1 ping -c 1 10.200.0.2 | head -2
PING 10.200.0.2 (10.200.0.2) 56(84) bytes of data.
64 bytes from 10.200.0.2: icmp_seq=1 ttl=64 time=0.161 ms
$ sleep 7
# what the router in the middle saw
$ cat /tmp/mid.txt
20:12:22.298114 IP 192.168.100.1.47176 > 192.168.200.2.4789: VXLAN, flags [I] (0x08), vni 100
ARP, Request who-has 10.200.0.2 tell 10.200.0.1, length 28
20:12:22.298177 IP 192.168.200.2.47176 > 192.168.100.1.4789: VXLAN, flags [I] (0x08), vni 100
ARP, Reply 10.200.0.2 is-at 02:00:00:00:aa:02, length 28
```

</details>

Read the two lines of each pair together, because that is the whole idea.

The outer line is ordinary routed traffic: an IP packet from one underlay address
to another, UDP, destination port 4789. Any router forwards that without knowing
or caring what is inside.

The inner line is **an ARP request**. A broadcast. The one thing that definitively
cannot cross a router, crossing a router, because it is cargo rather than traffic.
And `vni 100` is the VXLAN network identifier, which is what keeps one overlay
separate from another over the same underlay, exactly as a VLAN ID does on a trunk.

Notice also what the two hosts believe. h1 ARPed for h2, which is what a machine
does for something on its own segment. It has no idea there is a router in the
path, and the router has no idea there is a segment.

<details class="deeper">
<summary>If you already run an overlay: what the underlay still has to do, and the failure that looks like nothing</summary>

An overlay is only as good as the routed network beneath it, and the two are usually
looked after by people thinking about different things.

The underlay owes the overlay three things. Reachability between every pair of
endpoints, since a tunnel is just traffic and stops when the route does. Enough MTU to
carry an encapsulated frame, because the outer headers are added to a frame that was
already full size, and an underlay left at the default silently drops the largest
packets while small ones pass. And stable routing, since every reconvergence beneath
is felt by everything above it.

The second of those is the one that bites, and it produces the black hole topic 20
covers. Everything works, small transfers succeed, and anything that fills a frame
disappears. The fix is to raise the underlay MTU, and the reason it is missed is that
the overlay is where the new configuration went and the underlay is where the problem
is.

The wider caution is that an overlay hides the physical network from whoever is using
it, which is the point, and it also hides it from whoever is troubleshooting it. Two
machines that appear adjacent may be in different buildings across a path with its own
problems. When something on an overlay behaves strangely, the useful question is what
the traffic is actually crossing, and answering it means looking underneath.

</details>

## What an overlay costs

Wrapping a frame in another frame costs bytes, and this is where topic 20 arrives
from an unexpected direction.

<figure class="learn-figure">
<svg viewBox="0 0 720 268" role="img" aria-labelledby="vx-title" style="width:100%;height:auto;">
<title id="vx-title">A frame the host believes it is sending, and the same frame on the wire wrapped in fourteen bytes of outer Ethernet, twenty of outer IP, eight of UDP and eight of VXLAN</title>
<g fill="currentColor">
<text x="14" y="20" font-size="11">what h1 believes it is putting on a local segment</text>
<rect x="214" y="34" width="380" height="44" rx="3" fill="currentColor" fill-opacity="0.08" stroke="currentColor" stroke-opacity="0.55"/>
<text x="404" y="54" text-anchor="middle" font-size="11">inner frame</text>
<text x="404" y="69" text-anchor="middle" font-size="10" fill-opacity="0.75">1450 bytes at most</text>
<path d="M 594 34 l 10 11 l -10 11 l 10 11 l -10 11" stroke="currentColor" stroke-opacity="0.55" fill="none"/>
<text x="14" y="112" font-size="11">what the router in the middle actually carries</text>
<rect x="14" y="126" width="56" height="44" rx="2" fill="var(--accent)" fill-opacity="0.22" stroke="var(--accent)" stroke-width="1.6"/>
<text x="42" y="146" text-anchor="middle" font-size="9.5" fill="var(--accent)">Ethernet</text>
<text x="42" y="160" text-anchor="middle" font-size="9.5" fill="var(--accent)" fill-opacity="0.85">14</text>
<rect x="70" y="126" width="80" height="44" rx="2" fill="var(--accent)" fill-opacity="0.22" stroke="var(--accent)" stroke-width="1.6"/>
<text x="110" y="146" text-anchor="middle" font-size="9.5" fill="var(--accent)">IP</text>
<text x="110" y="160" text-anchor="middle" font-size="9.5" fill="var(--accent)" fill-opacity="0.85">20</text>
<rect x="150" y="126" width="32" height="44" rx="2" fill="var(--accent)" fill-opacity="0.22" stroke="var(--accent)" stroke-width="1.6"/>
<text x="166" y="146" text-anchor="middle" font-size="9.5" fill="var(--accent)">UDP</text>
<text x="166" y="160" text-anchor="middle" font-size="9.5" fill="var(--accent)" fill-opacity="0.85">8</text>
<rect x="182" y="126" width="32" height="44" rx="2" fill="var(--accent)" fill-opacity="0.22" stroke="var(--accent)" stroke-width="1.6"/>
<text x="198" y="146" text-anchor="middle" font-size="9.5" fill="var(--accent)">VXLAN</text>
<text x="198" y="160" text-anchor="middle" font-size="9.5" fill="var(--accent)" fill-opacity="0.85">8</text>
<rect x="214" y="126" width="380" height="44" rx="3" fill="currentColor" fill-opacity="0.08" stroke="currentColor" stroke-opacity="0.55"/>
<text x="404" y="146" text-anchor="middle" font-size="11">the whole inner frame, untouched</text>
<text x="404" y="161" text-anchor="middle" font-size="10" fill-opacity="0.75">including its own MAC addresses</text>
<path d="M 594 126 l 10 11 l -10 11 l 10 11 l -10 11" stroke="currentColor" stroke-opacity="0.55" fill="none"/>
<path d="M 14 180 V 190 H 214 V 180" stroke="var(--accent)" stroke-width="1.6" fill="none"/>
<text x="107" y="206" text-anchor="middle" font-size="11" fill="var(--accent)">50 bytes, on every packet</text>
<text x="14" y="240" font-size="11">1500 on the underlay, minus 50, leaves 1450 for the overlay.</text>
<text x="14" y="256" font-size="11" fill-opacity="0.85">the kernel worked that out and set the interface itself.</text>
</g></svg>
<figcaption>The inner frame is not modified, examined or unwrapped by anything between the two ends. It is payload. What it gains is four outer headers, drawn here to scale against each other so the 50 adds up visibly: fourteen bytes of outer Ethernet, twenty of outer IP, eight of UDP and eight of VXLAN itself. Every one of those bytes comes out of the same 1500 the underlay offers, which is why the overlay interface ends up at 1450. The capture below shows the kernel reaching that number on its own.</figcaption>
</figure>

<details class="predict">
<summary>The underlay carries a normal 1500 byte MTU. What did the kernel set the overlay interface to, and what happens one byte past it?</summary>

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology vxlan-overlay
# the underlay carries a normal 1500 byte MTU
$ ip -n h1 link show h1eth0 | grep -o "mtu [0-9]*"
mtu 1500
# and the kernel sized the overlay itself
$ ip -n h1 link show vx0 | grep -o "mtu [0-9]*"
mtu 1450
# 1422 payload plus 20 IP plus 8 ICMP is exactly the overlay MTU
$ ip netns exec h1 ping -c 1 -M do -s 1422 10.200.0.2 | tail -2
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 0.086/0.086/0.086/0.000 ms
# one byte more
$ ip netns exec h1 ping -c 1 -M do -s 1423 10.200.0.2 2>&1 | head -2
PING 10.200.0.2 (10.200.0.2) 1423(1451) bytes of data.
ping: sendmsg: Message too long
```

</details>

**1450, and the kernel worked it out without being asked.** Fifty bytes of outer
headers subtracted from 1500, and the interface sized accordingly.

That is the good case, and it is worth appreciating precisely because it is the
one that hides the problem. Here the encapsulation and the interface are on the
same machine, so the kernel knows what the overlay costs and sets the MTU to
match. Anything sending through `vx0` is told 1450 and behaves.

**The bad case is when the encapsulation happens somewhere the sender cannot see.**
A virtual machine with a 1500 byte interface, on a host that adds VXLAN on its
way out, has been told nothing. It sends 1500 bytes, and the result depends on
whether the path can tell it: with the don't fragment bit set and ICMP allowed
back, path MTU discovery corrects it, which is RFC 1191 doing its job. With ICMP
filtered, which topic 20 established is common, nothing comes back and large
packets simply vanish.

So the symptom is the one from topic 20, in a setting where nobody suspects an
MTU problem: small requests work, large transfers hang, and the tunnel was built
six months ago by a different team.

## Prove it

The captures above are the proof for the overlay half. For the rest, two
documents.

**RFC 7348.** Free, and readable. Read the section describing the frame format and
count the outer headers yourself. Then answer: does VXLAN specify how a device
learns which remote address to send a given inner MAC address to, or does it leave
that to something else? The answer explains why every vendor's control plane for
this is different.

**RFC 7426.** Read the terminology section and answer a narrower question: does it
define software-defined networking as a product category or as an architecture
with named layers? The distinction is what makes the term readable in a
procurement document.

**And run the overlay yourself.** The topology behind this page is
`scripts/topologies/vxlan-overlay.sh` and it is thirty lines. Building an overlay
across a router with two commands per host is the fastest way to stop finding this
subject mysterious.

## What trips people up

### 1. Thinking SDN means a specific product

It names an architecture in which the control plane is separated from the data
plane. RFC 7426 defines the layers. Products implement some of it and market all
of it.

### 2. Believing an overlay removes the need for the network underneath

The underlay carries every overlay packet. If it is congested, lossy or
misconfigured, the overlay inherits all of it and is harder to troubleshoot,
because the problem is now one layer further away.

### 3. Forgetting the MTU cost

Fifty bytes for VXLAN, and more if there is a tunnel inside the tunnel. When the
encapsulating device is the sender, the kernel handles it. When it is not, nothing
tells the sender anything.

### 4. Expecting the middle of the network to understand the overlay

It sees UDP. That is the point. It also means the middle of the network cannot
help you diagnose an overlay problem, and its counters will look perfectly
healthy while the overlay is broken.

### 5. Confusing the VNI with a VLAN ID

They do the same job of separating overlays, and the VNI is 24 bits against
802.1Q's 12, which is the reason it exists: sixteen million rather than four
thousand.

### 6. Treating SD-WAN's value as technical

Anything it does can be configured by hand at one site. Its value is at two
hundred sites and in the fact that they stay consistent, which is an operations
argument rather than a networking one.

## Work it through

Two hundred branches, and one policy change.

The first thing to establish is why this is hard, because the answer determines
which of the ideas on this page is relevant. Configuring one router to prefer one
circuit for one kind of traffic is straightforward. Doing it two hundred times is
two hundred opportunities to differ, and the deeper problem is that nobody can
currently say what those two hundred configurations contain. The obstacle is
inconsistency and unknowability rather than difficulty.

That points at the control plane split. If intent lives centrally and the devices
are programmed from it, the change is expressed once and the two hundred are
consistent by construction rather than by discipline.

Then the specific requirement, which is about applications rather than
destinations. Traditional routing decides by destination address, and "video
conferencing" is not a destination, it is a kind of traffic that may go anywhere.
That is exactly the gap application awareness fills, and it is the honest reason
SD-WAN exists rather than a general preference for newer things.

Then the question to ask before agreeing to any of it: what happens at a branch
when the controller is unreachable. If the answer is that existing traffic keeps
flowing and you lose the ability to change things, that is an acceptable trade for
two hundred sites. If new sessions fail, then a controller outage is a two hundred
site outage, and that is a different risk than the one being bought.

And the unglamorous thing to check early, because it will otherwise appear months
later: what the overlay costs in bytes and whether anything downstream has been
told. If branch traffic is being encapsulated somewhere the sending machines
cannot see, the fifty bytes are already spent and nobody has adjusted for them.

## Try it

**Build the overlay.** The topology file is in the repository and takes one
command. Ping across it, then run `tcpdump` in the middle and watch an ARP request
cross a router.

**Do the subtraction on any tunnel you own.** Find its MTU and compare it to the
interface underneath. If the difference is not accounted for, you have found a
future fault.

**Read the VXLAN frame format.** RFC 7348 draws it. Counting the four outer
headers yourself makes the 50 stop being a number to memorise.

## Check yourself

<details class="qa">
<summary>What does separating the control plane from the data plane actually buy?</summary>

One place where intent lives.

The data plane forwards packets and the control plane decides what it should
forward. Traditionally both are in every device, so a network of two hundred
routers holds two hundred independent copies of the intent, which drift and which
nobody can inspect as a whole.

Moving the control plane out means a change is expressed once and the devices are
programmed from it. The cost is a new dependency, and the question that matters
about any such product is what the data plane does when the controller is gone.

</details>

<details class="qa">
<summary>An ARP request appears in a capture taken on a router. How?</summary>

It is not being routed, it is being carried. The router sees an ordinary UDP
packet between two addresses it has routes for, and inside that packet is an
Ethernet frame containing the ARP.

That is VXLAN: the whole inner frame is encapsulated and the middle of the network
forwards the outer one without knowing there is anything inside. The two hosts
believe they share a segment, which is why one ARPed for the other in the first
place.

</details>

<details class="qa">
<summary>Where does the 50 byte cost of VXLAN come from, and why is 1450 not always what a sender is told?</summary>

Fourteen bytes of outer Ethernet, twenty of outer IP, eight of UDP and eight of
VXLAN. Subtracted from a 1500 byte underlay it leaves 1450.

When the encapsulating device is the sender, the kernel knows and sets the
interface MTU itself, which is what the capture on this page shows. When the
encapsulation happens elsewhere, on a hypervisor or a WAN device, the sending
machine still has a 1500 byte interface and has been told nothing.

It then depends on path MTU discovery, which needs the don't fragment bit and
ICMP allowed back. With ICMP filtered, large packets vanish silently, which is
the fault from topic 20 arriving where nobody expects it.

</details>

<details class="qa">
<summary>What do application aware and transport agnostic mean, and why do they go together?</summary>

Application aware means policy is applied based on what the traffic is rather than
only where it is going. Transport agnostic means the underlying circuits are
interchangeable, so leased line, broadband and cellular are all just paths.

They go together because the first is useless without the second. Deciding that
video should take a different path only matters if there are several paths and
they can be chosen between freely, and that requires the overlay not to care what
each circuit is.

</details>

<details class="qa">
<summary>Why is a VNI 24 bits when a VLAN ID is 12?</summary>

Because four thousand was not enough. A 12 bit VLAN ID gives 4094 usable segments,
which is ample in one building and inadequate in a data centre serving many
tenants who each want their own.

A 24 bit VNI gives roughly sixteen million. The job is the same, keeping one
overlay's traffic separate from another's, and the number is the reason a new
encapsulation was defined rather than the existing tag being reused.

</details>

## References

- [RFC 7348](https://www.rfc-editor.org/rfc/rfc7348) - IETF, the VXLAN specification, including the frame format the 50 bytes come from. Free. Accessed 2026-08-11.
- [RFC 7426](https://www.rfc-editor.org/rfc/rfc7426) - IETF, which defines software-defined networking as an architecture with named layers rather than as a product category. Free. Accessed 2026-08-11.
- [RFC 1191](https://www.rfc-editor.org/rfc/rfc1191) - IETF, path MTU discovery, which is what corrects for an overlay's cost when the sender can be told. Free. Accessed 2026-08-11.
- [ip-link(8)](https://man7.org/linux/man-pages/man8/ip-link.8.html) - Linux man-pages project, for the vxlan link type used in the topology behind this page. Accessed 2026-08-11.

**Where the numbers came from.** The 1500, the 1450 and the failure at one byte
past it are captured on this page rather than quoted, and so is the encapsulated
ARP. The 50 byte figure is the sum of the four outer headers as RFC 7348 defines
them, and the capture confirms it indirectly by showing the interface the kernel
sized. The SD-WAN vocabulary is described rather than measured, because it is
vendor terminology that the objectives name and no standard defines.

**If you also work on Linux.** VXLAN is a link type like any other: `ip link add
vx0 type vxlan id 100 remote ... local ... dstport 4789`. Two commands per host
builds the overlay on this page. Note the `dstport`, which is worth setting
explicitly: Linux defaults to a port chosen before the RFC assigned one, so
leaving it out produces an overlay that works between Linux hosts and not with
anything else.
