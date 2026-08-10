---
title: "The boxes on a network"
description: "Routers, switches, firewalls, load balancers, proxies and the rest, sorted by the one question that actually separates them: how far into a frame does this thing read before it acts."
deck: "The cupboard full of boxes nobody can name"
track: "network-plus"
level: "intro"
order: 50
objectives:
  - "Sort any network device by how far into a frame it reads"
  - "Say what a switch cannot do, and why that is a design choice rather than a limitation"
  - "Tell an IDS from an IPS by where it sits rather than by what it detects"
  - "Say which of these are boxes and which are jobs a box performs"
  - "Explain what changes and what does not when an appliance becomes software"
prerequisites: ["the-osi-model"]
tags: ["network-plus", "networking", "beginner"]
updated: 2026-08-10
draft: false
examObjectives:
  - exam: "n10-009"
    domain: "1.0"
    objective: "1.2"
sources:
  - title: "RFC 3234, Middleboxes: Taxonomy and Issues"
    url: "https://www.rfc-editor.org/rfc/rfc3234"
    publisher: "IETF"
    accessed: 2026-08-10
    tier: 1
  - title: "RFC 1812, Requirements for IP Version 4 Routers"
    url: "https://www.rfc-editor.org/rfc/rfc1812"
    publisher: "IETF"
    accessed: 2026-08-10
    tier: 1
  - title: "RFC 7230, HTTP/1.1 Message Syntax and Routing, on proxies"
    url: "https://www.rfc-editor.org/rfc/rfc7230"
    publisher: "IETF"
    accessed: 2026-08-10
    tier: 1
  - title: "RFC 2663, IP Network Address Translator Terminology"
    url: "https://www.rfc-editor.org/rfc/rfc2663"
    publisher: "IETF"
    accessed: 2026-08-10
    tier: 1
  - title: "IEEE 802.1D, MAC Bridges"
    url: "https://standards.ieee.org/ieee/802.1D/3387/"
    publisher: "IEEE"
    accessed: 2026-08-10
    tier: 1
symptoms:
  - symptom: "An IDS reported the attack and did not stop it"
    anchor: "the-boxes-that-read-further"
---

> **Before you read.** A cupboard in a small office holds six devices. Nobody
> who works there can tell you what any of them do. They were installed by a
> contractor, they have blinking lights, and one of them is warm.
>
> You are asked which one to unplug to stop a machine reaching the internet.
>
> **What would you need to know about each box to answer that?**

Not what it is called. What it reads.

Every device on a network receives a frame and has to decide what to do with it,
and the decisive difference between one box and the next is how far into that
frame it looks before deciding. A device that reads two fields is fast and
ignorant. A device that reads the whole thing can make decisions the first one
could not express, and pays for it.

Sort the cupboard that way and the names stop being a vocabulary test.

### Some words you will need

<dl class="terms">
<dt>appliance</dt>
<dd>A device built for one network job. It may be a physical box or software doing the same work.</dd>
<dt>inline</dt>
<dd>Sitting in the traffic path, so everything passes through it and it can stop something.</dd>
<dt>out of band</dt>
<dd>Sitting beside the traffic path, receiving a copy. It can see and report, and it cannot stop anything.</dd>
<dt>middlebox</dt>
<dd>The standards term for any device between two hosts that does more than forward.</dd>
<dt>forwarding</dt>
<dd>Moving a frame towards its destination. What switches and routers do.</dd>
<dt>proxy</dt>
<dd>Something that makes a connection on your behalf, so the far end talks to it rather than to you.</dd>
<dt>broadcast domain</dt>
<dd>The set of machines a broadcast frame reaches.</dd>
</dl>

## What breaks without this

**You unplug the wrong thing.** The example above is real, and the answer
depends entirely on which box is in the path rather than which one has the most
alarming name.

**You buy a device that cannot do what you needed.** A switch cannot filter on an
IP address. Nothing is broken; it never reads that far.

**You misread an incident.** "The IDS caught it" and "the IPS stopped it" describe
different outcomes, and the difference is where the box was plugged in.

## How far does it read

Take one frame, the same shape as the one in the previous topic, and ask how much
of it each device actually opens.

<figure class="learn-figure">
<svg viewBox="0 0 720 400" role="img" aria-labelledby="reach-title" style="width:100%;height:auto;">
  <title id="reach-title">How far into a frame each type of device reads before it acts</title>
  <g font-family="ui-monospace, monospace">
    <text x="12" y="22" font-size="12" fill="currentColor" fill-opacity="0.75">one frame, outermost field on the left</text>
    <rect x="12" y="34" width="150" height="42" rx="3" fill="currentColor" fill-opacity="0.10" stroke="currentColor" stroke-opacity="0.45"/>
    <text x="87" y="53" text-anchor="middle" font-size="12" fill="currentColor">MAC</text>
    <text x="87" y="68" text-anchor="middle" font-size="10.5" fill="currentColor" fill-opacity="0.7">layer 2</text>
    <rect x="162" y="34" width="150" height="42" rx="3" fill="currentColor" fill-opacity="0.10" stroke="currentColor" stroke-opacity="0.45"/>
    <text x="237" y="53" text-anchor="middle" font-size="12" fill="currentColor">IP</text>
    <text x="237" y="68" text-anchor="middle" font-size="10.5" fill="currentColor" fill-opacity="0.7">layer 3</text>
    <rect x="312" y="34" width="150" height="42" rx="3" fill="currentColor" fill-opacity="0.10" stroke="currentColor" stroke-opacity="0.45"/>
    <text x="387" y="53" text-anchor="middle" font-size="12" fill="currentColor">port</text>
    <text x="387" y="68" text-anchor="middle" font-size="10.5" fill="currentColor" fill-opacity="0.7">layer 4</text>
    <rect x="462" y="34" width="246" height="42" rx="3" fill="currentColor" fill-opacity="0.10" stroke="currentColor" stroke-opacity="0.45"/>
    <text x="585" y="53" text-anchor="middle" font-size="12" fill="currentColor">the data itself</text>
    <text x="585" y="68" text-anchor="middle" font-size="10.5" fill="currentColor" fill-opacity="0.7">layer 7</text>
  </g>
  <g font-family="ui-monospace, monospace" font-size="12" fill="currentColor">
    <text x="12" y="118">hub</text>
    <text x="12" y="166">switch</text>
    <text x="12" y="214">router</text>
    <text x="12" y="262">basic firewall</text>
    <text x="12" y="310">proxy, IDS, IPS</text>
    <text x="12" y="358">load balancer</text>
  </g>
  <g stroke="currentColor" fill="none" stroke-width="7" stroke-linecap="round">
    <path d="M150 112 L156 112" stroke-opacity="0.75" stroke-dasharray="1 6"/>
    <path d="M150 160 L162 160" stroke-opacity="0.75"/>
    <path d="M150 208 L312 208" stroke-opacity="0.75" stroke-dasharray="14 6"/>
    <path d="M150 256 L462 256" stroke-opacity="0.75" stroke-dasharray="2 7"/>
    <path d="M150 304 L708 304" stroke-opacity="0.75"/>
    <path d="M150 352 L462 352" stroke-opacity="0.75" stroke-dasharray="2 7"/>
    <path d="M150 352 L708 352" stroke-opacity="0.35" stroke-dasharray="1 9"/>
  </g>
  <g font-family="ui-monospace, monospace" font-size="10.5" fill="currentColor" fill-opacity="0.72">
    <text x="166" y="116">reads nothing, repeats the signal</text>
    <text x="176" y="164">reads the destination MAC and stops</text>
    <text x="322" y="212">reads the IP header</text>
    <text x="472" y="260">reads addresses and ports</text>
    <text x="486" y="308" fill-opacity="0.9">opens the payload</text>
    <text x="472" y="356">layer 4, or layer 7 if asked</text>
  </g>
  <g stroke="currentColor" stroke-opacity="0.25" stroke-width="1" stroke-dasharray="3 4">
    <path d="M162 84 L162 372"/>
    <path d="M312 84 L312 372"/>
    <path d="M462 84 L462 372"/>
  </g>
</svg>
<figcaption>Each bar shows how far into the frame that device reads before it acts, measured against the fields drawn along the top. A hub reads nothing and repeats the electrical signal. A switch reads the destination MAC address and stops there. A router opens the IP header. A basic firewall reads addresses and ports. A proxy, an intrusion detection system and an intrusion prevention system read all the way into the data. A load balancer reads to layer 4 by default and to layer 7 when configured to, which is why the same product is sold as both. Bar length is the measurement; the dash patterns only distinguish adjacent rows.</figcaption>
</figure>

Two consequences fall straight out of that picture, and both are examinable.

**Reading further costs more and buys more specific decisions.** A switch forwards
in microseconds because it barely looks. A proxy can make a decision a switch
could not express, such as allowing one URL on a site and refusing another, and
it pays in latency and in state it has to keep.

**A device cannot act on what it never reads.** This is the sentence that answers
the cupboard question. A switch cannot block a machine from the internet by IP
address, because it never opens the IP header. Asking it to is not a
configuration problem.

<details class="deeper">
<summary>If you already work on networks: what the standards call these, and the one that admits the whole category is awkward</summary>

The IETF has a word for most of the devices on this page, and a document
complaining about them. RFC 3234 defines a middlebox as "any intermediary device
performing functions other than the normal, standard functions of an IP router on
the datagram path between a source host and destination host", then catalogues
twenty-two kinds and works through what each one breaks.

The complaint is worth understanding because it explains a category of fault you
will meet. The internet was designed so that the network forwards and the
endpoints do everything else, which is what makes end to end checksums and end to
end encryption meaningful. A middlebox is by definition something that violates
that, and RFC 3234 is candid that this introduces new failure modes: a device
that holds state can lose it, and a device that rewrites packets can be wrong in
ways neither endpoint can see or fix.

By contrast, a router's job is specified rather than complained about. RFC 1812
lists what an IPv4 router must do, and it is longer than most people expect,
covering forwarding, TTL handling, ICMP generation, and how to behave when a
packet is too large. Bridging is specified separately, by IEEE rather than the
IETF, in 802.1D.

That split explains the vocabulary you will meet in vendor documentation. Routing
and bridging are standardised behaviours with documents behind them. Load
balancing, deep inspection and application filtering are product categories, so
what any two vendors mean by them can differ, and the exam stays vendor-neutral
precisely because it cannot rely on them agreeing.

</details>

## The two that forward

These are the only devices here whose whole job is moving traffic onward.

A **switch** connects machines on one network. It reads the destination MAC
address, looks it up in a table it built by watching traffic, and sends the frame
out of one port. It never opens the IP header, which is why it can forward
protocols it has never heard of and why it cannot make any decision based on an
IP address.

A **router** connects different networks. It reads the IP header, decides which
interface that network is reachable through, and builds a new frame around the
same packet, which is the rewriting topic 02 captured on both sides of a router.

The distinction people actually need is what each one contains. **A switch does
not separate broadcast domains and a router does.** A broadcast sent by any
machine on a switch reaches every other machine on that switch. Cross a router
and it stops. That single fact is behind VLANs, behind most network design, and
behind a lot of performance problems in flat networks.

Hubs belong to history and appear here only because the exam may name one. A hub
reads nothing, repeats every signal out of every other port, and makes all its
ports share one collision domain. Switches replaced them and the reason is in the
diagram: a hub cannot even read a destination address, so it cannot forward
anything anywhere in particular.

<details class="deeper">
<summary>If you already work on networks: counting collision and broadcast domains, which is a question you will be asked</summary>

Two domains, two different devices drawing the boundary, and exam questions that
hand you a diagram and ask for both counts.

A collision domain is a set of ports whose traffic can interfere with each other.
On a hub every port is in the same one, because a hub is an electrical repeater
and two machines transmitting at once produce a collision. A switch gives every
port its own, because it buffers a frame and forwards it rather than repeating a
signal. So a five-port switch has five collision domains and a five-port hub has
one.

A broadcast domain is a set of machines that receive each other's broadcasts. A
switch does not divide them, however many ports it has, because a broadcast is
flooded out of every port. A router does divide them, because it does not forward
broadcasts at all.

Counting from a diagram, then, is mechanical. Collision domains are switch ports,
plus one for each hub in the picture. Broadcast domains are router interfaces,
and one VLAN counts the same as one router interface, which is the point of the
VLAN topics later on.

The collision half is close to a historical exercise. Every switch port in a
modern network runs full duplex, transmit and receive on separate pairs, and a
full duplex link cannot have a collision at all. The counting still gets asked,
and the honest framing is that you are counting a thing that mostly stopped
happening when hubs disappeared.

</details>

## The boxes that read further

Everything else in the cupboard reads past the IP header, and they are best told
apart by two questions: how deep do they read, and are they in the path.

| Device | Reads to | In the path | What it is for |
| --- | --- | --- | --- |
| Firewall | Layer 4, or layer 7 | Yes | Allowing and blocking traffic by rule |
| IDS | Layer 7 | No, sees a copy | Detecting and alerting |
| IPS | Layer 7 | Yes | Detecting and blocking |
| Proxy | Layer 7 | Yes, by configuration | Making requests on a client's behalf |
| Load balancer | Layer 4, or layer 7 | Yes | Spreading connections over several servers |

**An IDS and an IPS can run identical detection logic. The difference is the
cabling.** An IDS sits out of band, receiving a copy of the traffic, so it can
tell you an attack happened and it cannot stop it. An IPS sits inline, so it can
drop the traffic, and it can also drop traffic it should not have and take a
service down on a false positive. One is a smoke alarm, the other is a sprinkler,
and the trade is the same trade.

That is the answer to the incident you will eventually read: "the IDS caught it
and it still succeeded" is not a failure of the IDS. It is what an IDS is.

**A proxy is defined by who the far end thinks it is talking to.** A forward proxy
makes requests on behalf of clients, so the websites see the proxy rather than
the staff. A reverse proxy sits in front of servers, so the clients see it rather
than the servers. Same mechanism, opposite direction, and the words describe
which side is being hidden.

**A load balancer is sold at two depths, which is why its layer number keeps
changing.** At layer 4 it chooses a server from the address and port, which is
fast and knows nothing about the request. At layer 7 it reads the HTTP request and
can send `/images` to one pool and `/api` to another. The exam names both, and
the deciding question is the one this whole topic runs on: how far did it read.

Two more that store rather than forward. **NAS** is storage that speaks file
protocols over the ordinary network, so a machine mounts a share. **SAN** is
storage that presents raw block devices over a network usually built for that
purpose, so a machine sees what looks like a local disk. File against block is
the distinction to keep.

You will also meet **UTM**, unified threat management, which is one box combining
firewall, intrusion prevention, content filtering and usually antivirus. It is a
packaging decision rather than a new capability, and it is the last thing in
CompTIA's acronym list that has no other home in this track.

<details class="deeper">
<summary>If you already work on networks: why placement, not capability, is what you are usually buying</summary>

Every device in the table above can be bought as a physical box, run as a virtual
machine, or consumed as a service, and the capability is largely the same in all
three. What changes is where it sits, and that is what determines what it can do.

The clearest case is the IDS and IPS pair, because it is the same software. Give
it a mirrored port and it is a detector. Put it in the path and it is a
preventer. Nothing about the detection changed.

The same reasoning runs through the rest. A firewall that is not in the path
filters nothing. A proxy nobody is configured to use is an idle server. A load
balancer with a route around it is decoration. When a design review asks "is this
inline", it is asking the only question that decides whether the box can act.

There is a reliability consequence worth carrying. **Anything inline is a
potential single point of failure**, which is why inline devices are usually
deployed in pairs and why some ship with a hardware bypass that shorts the two
ports together when the box loses power. An out of band device that dies stops
telling you things. An inline device that dies can stop the business.

</details>

## The ones that are jobs, not boxes

Four things the objective lists alongside the devices are not devices at all, and
the exam expects you to know the difference.

| | What it actually is | Where it lives |
| --- | --- | --- |
| VPN | An encrypted tunnel between two points across a network you do not trust | Terminates on a firewall, a router, a concentrator, or software on a laptop |
| QoS | Rules for which traffic gets preference when a link is congested | A feature configured on switches and routers. Uncongested, it does nothing |
| TTL | A field in the IP header, counted down by every router | The packet itself. Topic 03 saw it at 63 after one hop |
| CDN | Servers near users holding copies of somebody else's content | A service you buy, which is why the objective lists it as an application |

The pattern is worth naming. Each of these is a job performed by devices that
also do other things, or in TTL's case a number inside a packet. None is a box
you could point at in the cupboard.

Grouping these correctly is worth a mark, and more usefully it stops you looking
for a QoS appliance that does not exist.

<details class="deeper">
<summary>If you already work on networks: why enabling QoS often changes nothing, and why that is the correct outcome</summary>

QoS is the one in that table that generates support tickets, because what it does
is easy to state and easy to misread.

Quality of service decides which traffic is served first when there is more
traffic than the link can carry. On a link that is not full there is no queue to
reorder, every packet leaves as it arrives, and the configuration has no effect
that anyone can measure. So "we turned on QoS and the calls still break up" is
usually not a QoS fault. It is evidence that the problem was never contention on
that link, and the next thing to look at is the path, the wireless, or the far
end.

The second thing that surprises people is scope. QoS markings live in the packet
header, and they mean whatever each device along the path has been configured to
think they mean. A device that has not been told to honour a marking will ignore
it, and most providers rewrite or clear markings at the boundary of their
network. Marking traffic on your own switch does not make anybody else treat it
as important. The policy has to exist on every hop that might queue, which is why
QoS is a design decision rather than a setting.

The same test applies to the other three. A VPN needs somewhere to terminate. A
CDN needs the DNS answer to point at it. TTL is not configurable policy at all,
it is a counter. Ask where each one is enforced, and the ones that are jobs stop
blurring into the ones that are boxes.

</details>

## Physical or virtual, and what actually changes

Every appliance here also exists as software. A firewall can be a rack unit or a
virtual machine; a load balancer can be a service in a cloud provider's console.

What stays the same is the reading depth, which is the whole basis of this topic.
A virtual firewall reads exactly as far as a physical one.

What changes is worth knowing in three places. Throughput becomes a property of
the host and its network rather than of purpose built silicon. Placement becomes
a configuration decision rather than a cabling one, which is faster to change and
easier to get silently wrong. And failure domains move: ten virtual appliances on
one host share that host's fate, in a way ten separate boxes did not.

<details class="deeper">
<summary>If you already work on networks: the split that explains the difference, and the vocabulary it gives you</summary>

Every forwarding device does two separate things, and they are worth naming
because the rest of this track uses the names.

The **data plane** is the part that moves a frame or packet from one port to
another. It runs for every packet, so it has to be fast and it has to be
uninteresting. The **control plane** is the part that works out what the data
plane should do: learning MAC addresses, running spanning tree, exchanging routes
with neighbours. It runs occasionally and it is allowed to be slow, because it is
producing tables rather than moving traffic.

In a physical switch these live in different hardware. The data plane is a
dedicated chip that forwards at the speed of the ports, and the control plane is
an ordinary processor on the same board. In a virtual appliance both are the same
CPU, and every forwarded packet competes with the work of deciding how to forward
it. That is the honest version of the throughput sentence above.

The split explains a limit that catches people out. A hardware forwarding table
is physical memory of a fixed size, so a switch holds a stated number of MAC
addresses and no more. Fill it and the switch cannot learn any others, which is a
real failure mode and also a real attack, and topic 56 covers what happens next.
Software forwarding has no equivalent hard edge, and instead degrades as the
table grows.

It also gives you a compact way to describe things that arrive later. Software
defined networking, in topic 28, is control planes lifted off individual boxes
and centralised. A router that stays up while its routing protocol restarts is a
data plane surviving a control plane failure. Once you have the two words, a
surprising amount of network design turns out to be arguments about where the
control plane should live.

</details>

## Prove it

There is nothing to run here. Every device in this topic is a category rather
than a command, so the evidence is in the documents that define them, and each of
these answers a question the marketing does not.

| Go and read | For the answer to |
| --- | --- |
| [RFC 3234](https://www.rfc-editor.org/rfc/rfc3234), section 1, and the catalogue in section 2 | What counts as a middlebox, and how many kinds the IETF had already catalogued in 2002 |
| [RFC 1812](https://www.rfc-editor.org/rfc/rfc1812), the requirements list | What a router is obliged to do, beyond forwarding |
| [RFC 7230](https://www.rfc-editor.org/rfc/rfc7230), the section on intermediaries | Why a proxy, a gateway and a tunnel are three different things in the specification |
| [RFC 2663](https://www.rfc-editor.org/rfc/rfc2663) | The terminology a NAT device uses, which topic 25 needs |

**One question to take with you, because it is the one the documents answer and
the datasheets do not:** for any box you are shown, how far into the frame does
it read, and is it in the traffic path. Those two answers place it in the table
above without knowing the vendor.

## What trips people up

### 1. Thinking a switch can filter by IP address

It never reads the IP header. A device that does that is a router, a layer 3
switch, or a firewall. Buying a switch and expecting IP filtering is a category
error rather than a configuration problem.

### 2. Expecting an IDS to have stopped something

An IDS is out of band and sees a copy. It reports. If you needed it stopped, the
thing you needed was inline, and that is an IPS.

### 3. Treating layer 4 and layer 7 load balancing as the same product

They make different decisions from different information. A layer 4 balancer
cannot route on a URL because it never reads one.

### 4. Looking for a VPN box or a QoS box

Both are functions. They run on devices that also do other things, and a network
diagram with a box labelled QoS on it has been drawn by somebody guessing.

### 5. Assuming virtual means less capable

The reading depth is identical. What differs is throughput, how placement is
changed, and what fails together.

### 6. Reading a hub as an old switch

A hub reads nothing at all and repeats signals. It does not learn addresses and
it does not forward selectively. The exam may still name one.

## Work it through

Back to the cupboard. You are told a machine at `10.0.5.20` must not reach the
internet, and today it can. You may not touch the machine itself.

The six boxes are a switch, a router, a firewall, a wireless access point, a
device labelled IDS, and a NAS.

Reason it out before reading on.

**Eliminate on reading depth first, because it is quick.** The switch never reads
an IP address, so it cannot act on `10.0.5.20` as such. The NAS is storage and is
not in the path to anywhere. The access point is a way onto the network rather
than a way out of it, and blocking there would stop that machine reaching
everything, not the internet specifically.

That leaves three, and one of them disqualifies itself. The IDS is out of band by
definition, so whatever it can see, it cannot block.

**Now choose between the router and the firewall, and notice they would both
work.** The router is the path to the internet, so a rule there can stop the
traffic. The firewall is built for exactly this and will express the rule more
precisely and log it.

**The reason to pick the firewall is not capability.** It is that a filtering rule
on the router is a change to the thing that makes the network work, and a mistake
there affects everything. The firewall's job is already to allow and deny, so the
change sits where the blast radius is smallest.

**One thing to check before touching anything.** The box labelled IDS may be an
IPS that somebody labelled loosely, in which case it is inline and is a candidate
after all. The way to tell is not the label, it is whether traffic passes through
it or past it. Which is the question this topic has been asking throughout.

## Try it

Optional, and none of it needs equipment.

1. Find any network diagram, from your workplace or from a vendor's
   documentation. For each box on it, write down how far into a frame it reads
   and whether it is in the traffic path.
2. Open [RFC 3234](https://www.rfc-editor.org/rfc/rfc3234) and read the list of
   middlebox types in section 2. Count how many of them you had a name for
   already.
3. Take one device you use daily, a home router, and list every job in this topic
   that it performs. It will be more than three.
4. Look up any firewall product's datasheet and decide, from what it claims, what
   depth it reads to. Then check whether the datasheet says so plainly or leaves
   you to infer it.

**Verification step.** You have it when somebody can describe a box to you without
naming it, saying only what it reads and where it sits, and you can say what it
must be.

## Check yourself

<details class="qa">
<summary>What is the single question that separates a switch, a router and a proxy?</summary>

How far into the frame each one reads before it acts.

A switch reads the destination MAC address and stops. A router opens the IP
header. A proxy reads all the way into the data, which is what lets it make
decisions about a request rather than about a packet.

Reading further costs latency and state, and buys decisions the shallower device
could not express.

</details>

<details class="qa">
<summary>An IDS and an IPS are running identical detection software. What is different?</summary>

Where they are plugged in.

The IDS is out of band and receives a copy of the traffic, so it can alert and
cannot block. The IPS is inline, so everything passes through it and it can drop
what it does not like.

The cost of being inline is that a false positive takes down real traffic, and
that the device is now a point of failure in the path.

</details>

<details class="qa">
<summary>Why can a switch not block a machine by IP address?</summary>

Because it never reads the IP header. It makes its forwarding decision from the
destination MAC address and stops there.

That is a design choice rather than a shortcoming, and it is why a switch can
forward protocols it has never heard of. A device that filters on an IP address
is a router, a layer 3 switch, or a firewall.

</details>

<details class="qa">
<summary>Which of these are devices and which are functions: VPN, QoS, firewall, CDN, TTL, load balancer?</summary>

Devices: firewall and load balancer, though both also exist as software.

Functions or fields: VPN is an encrypted tunnel that terminates on some other
device, QoS is a feature configured on switches and routers, TTL is a field in
the IP header, and a CDN is a service made of servers somebody else operates.

Looking for a QoS appliance is the practical consequence of getting this wrong.

</details>

<details class="qa">
<summary>What is the difference between NAS and SAN?</summary>

NAS presents files over the ordinary network, so a machine mounts a share and
speaks a file protocol.

SAN presents raw block storage, usually over a network built for that purpose, so
a machine sees something that behaves like a local disk and puts its own
filesystem on it.

File against block is the distinction worth keeping.

</details>

<details class="qa">
<summary>A device is described to you as inline, reading to layer 7, in front of a group of web servers. What is it?</summary>

Either a reverse proxy or a layer 7 load balancer, and in practice frequently
both, because the same product usually does both jobs.

In front of servers rather than in front of clients makes it reverse. Reading to
layer 7 means it can make decisions from the request itself, such as sending one
path to one pool of servers.

</details>

## References

- [RFC 3234, Middleboxes: Taxonomy and Issues](https://www.rfc-editor.org/rfc/rfc3234) - IETF. Accessed 2026-08-10.
- [RFC 1812, Requirements for IP Version 4 Routers](https://www.rfc-editor.org/rfc/rfc1812) - IETF. Accessed 2026-08-10.
- [RFC 7230, HTTP/1.1 Message Syntax and Routing](https://www.rfc-editor.org/rfc/rfc7230) - IETF. Accessed 2026-08-10.
- [RFC 2663, IP Network Address Translator Terminology](https://www.rfc-editor.org/rfc/rfc2663) - IETF. Accessed 2026-08-10.
- [IEEE 802.1D, MAC Bridges](https://standards.ieee.org/ieee/802.1D/3387/) - IEEE. Accessed 2026-08-10.

**Where the material came from.** This topic has no captured output and says so
rather than dressing anything up as a transcript. Every device here is a category
rather than a command, so the evidence is the standards named under **Prove it**,
each cited to the document and the section that answers the question rather than
to a vendor page. The reading depths in the diagram follow from those documents
and from the frame captured in topic 02.
