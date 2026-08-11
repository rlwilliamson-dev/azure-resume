---
title: "Topologies and architectures"
description: "The shapes networks are built in, why the data centre abandoned the one every textbook teaches, and what north-south and east-west actually describe. Star, mesh, hub and spoke, three-tier and spine and leaf, with the arithmetic that decides between them."
deck: "Two buildings, four hundred desks, and a drawing to make"
track: "network-plus"
level: "intro"
order: 280
objectives:
  - "Name the physical topologies and say what each costs in links"
  - "Explain the three-tier hierarchical model and what a collapsed core is"
  - "Say what spine and leaf is and why data centres moved to it"
  - "Tell north-south traffic from east-west and say why the distinction matters"
  - "Choose a shape for a given site and defend it"
prerequisites: ["the-boxes-on-a-network"]
tags: ["network-plus", "networking", "design", "beginner"]
updated: 2026-08-11
draft: false
examObjectives:
  - exam: "n10-009"
    domain: "1.0"
    objective: "1.6"
sources:
  - title: "RFC 7938, Use of BGP for Routing in Large-Scale Data Centers"
    url: "https://www.rfc-editor.org/rfc/rfc7938"
    publisher: "IETF"
    accessed: 2026-08-11
    tier: 1
  - title: "RFC 3439, Some Internet Architectural Guidelines and Philosophy"
    url: "https://www.rfc-editor.org/rfc/rfc3439"
    publisher: "IETF"
    accessed: 2026-08-11
    tier: 1
  - title: "IEEE 802.1Q, Bridges and Bridged Networks"
    url: "https://standards.ieee.org/ieee/802.1Q/10323/"
    publisher: "IEEE Standards Association"
    accessed: 2026-08-11
    tier: 1
symptoms:
  - symptom: "One switch fails and a whole floor goes down"
    anchor: "the-shapes-and-what-each-one-costs"
  - symptom: "Traffic between two servers in the same rack crosses the core"
    anchor: "north-south-and-east-west"
---

> **Before you read.** Two buildings, four hundred desks, a server room in one of
> them, and somebody has asked you for a drawing before anything is ordered.
>
> Every shape you could choose will work. They differ in what they cost, what
> happens when one box dies, and which of them you can still afford to extend in
> five years.
>
> **Which shape, and what is the argument for it?**

This topic is vocabulary with consequences. The words are easy and the exam tests
them directly, so most material stops at the definitions. The part worth having
is the arithmetic underneath, because it explains both why one shape won and why
the shape every textbook still teaches first has quietly been abandoned in the
place it was invented for.

### Some words you will need

<dl class="terms">
<dt>topology</dt>
<dd>The shape of the connections. Physical topology is the cabling, logical topology is how traffic actually flows, and they are frequently different.</dd>
<dt>hub and spoke</dt>
<dd>Many sites each connected back to one central site, and to nothing else.</dd>
<dt>mesh</dt>
<dd>Devices connected to each other directly. Full mesh means every one to every other; partial mesh means some of them.</dd>
<dt>three-tier</dt>
<dd>Core, distribution and access as three layers of switching, each with a different job.</dd>
<dt>collapsed core</dt>
<dd>The same design with core and distribution done by one pair of devices.</dd>
<dt>spine and leaf</dt>
<dd>Two layers, where every leaf connects to every spine and leaves never connect to each other.</dd>
<dt>oversubscription</dt>
<dd>The ratio between what the edge can offer and what the layer above can carry.</dd>
</dl>

## What breaks without this

**You cannot read a diagram somebody hands you.** Every network you inherit
arrives as a drawing using these words, and the words are load bearing: calling
something a collapsed core tells the next person where the routing happens.

**A design gets chosen by accident.** Nobody sits down and picks a hub and spoke.
It happens by adding sites to whichever one had the internet connection, and it
is only a problem the day two branches need to talk to each other.

**You buy the wrong number of uplinks.** Oversubscription is arithmetic that can
be done on paper before anything is ordered, and it is the single most common
thing missing from a design that later gets described as slow.

## The shapes, and what each one costs

Start with the two extremes, because everything in production sits between them.

**A star** puts one device in the middle and everything else on a spoke. Every
switch you have ever seen is a star: the switch is the middle and the desks are
the points. It is cheap, it is easy to reason about, and the middle is a single
point of failure for everything attached to it.

**A full mesh** connects every device directly to every other. Nothing has a
single point of failure and the link count is the problem. Six devices need
fifteen links. Ten devices need forty-five. The count grows as the square of the
device count, which is why a full mesh of anything larger than a handful of sites
exists in exam questions and almost nowhere else.

Between them sit the two that are actually built.

**Hub and spoke** is a star drawn at the scale of buildings: branches connect to
head office and not to each other. Traffic between two branches goes via the
middle, which is fine for branches that mostly talk to head office and painful
the day they need to talk to each other.

**Partial mesh** adds direct links only where the traffic justifies them. That is
what most wide area networks actually are, and the design work is deciding which
handful of extra links to buy.

**Point to point** is the degenerate case, two devices and one link, and it is
worth naming because the exam does. A leased line between two buildings is a
point to point link whatever runs over it.

<figure class="learn-figure">
<svg viewBox="0 0 720 428" role="img" aria-labelledby="topo-title" style="width:100%;height:auto;">
<title id="topo-title">Star, full mesh, three-tier and spine and leaf drawn at the same scale, showing how the link count grows in each</title>
<g fill="currentColor">
<rect x="12" y="30" width="340" height="182" rx="4" fill="currentColor" fill-opacity="0.03" stroke="currentColor" stroke-opacity="0.3"/>
<text x="28" y="52" font-size="11.5">star</text>
<text x="336" y="52" text-anchor="end" font-size="10" fill-opacity="0.7">5 links</text>
<g stroke="currentColor" stroke-opacity="0.55" stroke-width="1.3">
<line x1="182" y1="140" x2="182" y2="88"/>
<line x1="182" y1="140" x2="241" y2="121"/>
<line x1="182" y1="140" x2="218" y2="190"/>
<line x1="182" y1="140" x2="146" y2="190"/>
<line x1="182" y1="140" x2="123" y2="121"/>
</g>
<g stroke="currentColor" stroke-opacity="0.6" fill="currentColor" fill-opacity="0.12">
<circle cx="182" cy="88" r="10"/>
<circle cx="241" cy="121" r="10"/>
<circle cx="218" cy="190" r="10"/>
<circle cx="146" cy="190" r="10"/>
<circle cx="123" cy="121" r="10"/>
</g>
<circle cx="182" cy="140" r="13" fill="currentColor" fill-opacity="0.25" stroke="currentColor" stroke-width="1.8"/>
<text x="28" y="68" font-size="10" fill-opacity="0.75">the middle is every failure</text>
<rect x="368" y="30" width="340" height="182" rx="4" fill="currentColor" fill-opacity="0.03" stroke="currentColor" stroke-opacity="0.3"/>
<text x="384" y="52" font-size="11.5">full mesh</text>
<text x="692" y="52" text-anchor="end" font-size="10" fill-opacity="0.7">15 links</text>
<g stroke="currentColor" stroke-opacity="0.45" stroke-width="1.1">
<line x1="600" y1="140" x2="569" y2="194"/><line x1="600" y1="140" x2="507" y2="194"/>
<line x1="600" y1="140" x2="476" y2="140"/><line x1="600" y1="140" x2="507" y2="86"/>
<line x1="600" y1="140" x2="569" y2="86"/><line x1="569" y1="194" x2="507" y2="194"/>
<line x1="569" y1="194" x2="476" y2="140"/><line x1="569" y1="194" x2="507" y2="86"/>
<line x1="569" y1="194" x2="569" y2="86"/><line x1="507" y1="194" x2="476" y2="140"/>
<line x1="507" y1="194" x2="507" y2="86"/><line x1="507" y1="194" x2="569" y2="86"/>
<line x1="476" y1="140" x2="507" y2="86"/><line x1="476" y1="140" x2="569" y2="86"/>
<line x1="507" y1="86" x2="569" y2="86"/>
</g>
<g stroke="currentColor" stroke-opacity="0.6" fill="currentColor" fill-opacity="0.12">
<circle cx="600" cy="140" r="10"/><circle cx="569" cy="194" r="10"/><circle cx="507" cy="194" r="10"/>
<circle cx="476" cy="140" r="10"/><circle cx="507" cy="86" r="10"/><circle cx="569" cy="86" r="10"/>
</g>
<text x="384" y="68" font-size="10" fill-opacity="0.75">no single failure, and it grows as the square</text>
<rect x="12" y="228" width="340" height="186" rx="4" fill="currentColor" fill-opacity="0.03" stroke="currentColor" stroke-opacity="0.3"/>
<text x="28" y="250" font-size="11.5">three-tier</text>
<text x="336" y="250" text-anchor="end" font-size="10" fill-opacity="0.7">8 links</text>
<g stroke="currentColor" stroke-opacity="0.55" stroke-width="1.3">
<line x1="140" y1="280" x2="110" y2="330"/><line x1="140" y1="280" x2="254" y2="330"/>
<line x1="224" y1="280" x2="110" y2="330"/><line x1="224" y1="280" x2="254" y2="330"/>
<line x1="110" y1="330" x2="66" y2="384"/><line x1="110" y1="330" x2="134" y2="384"/>
<line x1="254" y1="330" x2="230" y2="384"/><line x1="254" y1="330" x2="298" y2="384"/>
</g>
<g stroke="currentColor" stroke-opacity="0.6" fill="currentColor" fill-opacity="0.12">
<circle cx="140" cy="280" r="10"/><circle cx="224" cy="280" r="10"/>
<circle cx="110" cy="330" r="10"/><circle cx="254" cy="330" r="10"/>
<circle cx="66" cy="384" r="10"/><circle cx="134" cy="384" r="10"/>
<circle cx="230" cy="384" r="10"/><circle cx="298" cy="384" r="10"/>
</g>
<g font-size="9.5" fill-opacity="0.7">
<text x="344" y="284" text-anchor="end">core</text>
<text x="344" y="334" text-anchor="end">distribution</text>
<text x="344" y="388" text-anchor="end">access</text>
</g>
<rect x="368" y="228" width="340" height="186" rx="4" fill="currentColor" fill-opacity="0.03" stroke="currentColor" stroke-opacity="0.3"/>
<text x="384" y="250" font-size="11.5">spine and leaf</text>
<text x="692" y="250" text-anchor="end" font-size="10" fill-opacity="0.7">8 links</text>
<g stroke="currentColor" stroke-opacity="0.55" stroke-width="1.3">
<line x1="486" y1="300" x2="420" y2="374"/><line x1="486" y1="300" x2="496" y2="374"/>
<line x1="486" y1="300" x2="572" y2="374"/><line x1="486" y1="300" x2="648" y2="374"/>
<line x1="596" y1="300" x2="420" y2="374"/><line x1="596" y1="300" x2="496" y2="374"/>
<line x1="596" y1="300" x2="572" y2="374"/><line x1="596" y1="300" x2="648" y2="374"/>
</g>
<g stroke="currentColor" stroke-opacity="0.6" fill="currentColor" fill-opacity="0.12">
<circle cx="486" cy="300" r="10"/><circle cx="596" cy="300" r="10"/>
<circle cx="420" cy="374" r="10"/><circle cx="496" cy="374" r="10"/>
<circle cx="572" cy="374" r="10"/><circle cx="648" cy="374" r="10"/>
</g>
<g font-size="9.5" fill-opacity="0.7">
<text x="692" y="304" text-anchor="end">spine</text>
<text x="692" y="378" text-anchor="end">leaf</text>
</g>
<text x="384" y="400" font-size="10" fill-opacity="0.75">one spine between any two leaves</text>
</g>
</svg>
<figcaption>The top two are the extremes, drawn with six devices each so the link counts can be compared honestly: five against fifteen. The interesting number is not the difference, it is how each grows. Add a seventh device to the star and you add one link. Add a seventh to the mesh and you add six, because it has to reach everything already there. The bottom two are the designs actually built, and the thing to look at is the hop count rather than the link count. In three-tier, two machines on different access switches are three hops apart if they share a distribution pair and five if they do not. In spine and leaf every leaf is exactly one spine away from every other leaf, so every pair of machines is the same distance apart. That property is the whole reason the second design exists.</figcaption>
</figure>

## The design every textbook teaches

The **three-tier hierarchical model** divides switching into layers with
different jobs, and for twenty years it was simply how enterprise networks were
drawn.

**Access** is where things plug in. Ports for desks, phones and access points,
and this layer is where the port count lives.

**Distribution** aggregates the access switches for an area, usually a floor or a
building. It is where routing between VLANs happens, and where policy gets
applied, because it is the first layer that sees traffic from more than one
access switch.

**Core** connects the distribution layers to each other at speed and does as
little else as possible. The design rule everyone quotes is that the core should
switch and route and nothing more: no access lists, no policy, nothing that
requires it to think.

**A collapsed core** merges core and distribution into one pair of devices. That
is the right answer for most buildings, because the three-layer version exists to
solve a scale problem that a single site with four hundred desks does not have.
Calling it a collapsed core rather than a two-tier network tells the next person
that the distribution layer's jobs still happen, they just happen on the same
boxes as the core.

<details class="deeper">
<summary>If you already work on networks: why the layers exist at all, and the argument RFC 3439 makes against being clever</summary>

The hierarchy is usually justified with the word scalability, which explains
nothing. The real argument is about failure domains and about how much any one
device has to know.

A flat switched network is one broadcast domain and one spanning tree. Every
switch participates in every topology change, every broadcast reaches every port,
and the failure domain is the whole site. Splitting it into layers puts a routing
boundary between areas, which bounds all three: a topology change at the access
layer stays there, and a broken switch takes out a floor rather than a building.

The second argument is about device roles. An access switch needs many cheap
ports and very little intelligence. A core switch needs few ports, enormous
throughput, and no features at all. Those are different products with different
prices, and a design that mixes the roles ends up buying core-class hardware for
desk ports.

RFC 3439 is worth reading here even though it is about the internet rather than
about campus design, because it names the underlying principle and does it
bluntly. Its Simplicity Principle argues that complexity is the thing that limits
scaling, and that the cost of a system grows faster than its complexity does.
The document is unusually direct for an RFC and contains a section called
"Architectural Component Proportionality Law". The reason to bring it into a
campus discussion is that the strongest argument for the three-tier model is not
that it is fast. It is that each layer is simple enough to be reasoned about
alone.

Which is also the argument against applying it everywhere. Three layers in a
building that needs two is complexity bought for nothing, and the same RFC would
say so.

</details>

## The design that replaced it, and where

**Spine and leaf** has two layers and one rule: every leaf connects to every
spine, and leaves never connect to each other. Traffic from any leaf to any other
leaf crosses exactly one spine, so every pair of devices is the same distance
apart. That property has a name, which is equidistance, and it is the entire
point.

It is not a new idea. The structure is a Clos network, described by Charles Clos
at Bell Labs in 1953 for telephone switching, and rediscovered when data centres
started having the same problem: how to build a large non-blocking fabric from
small elements.

The reason it displaced three-tier in the data centre is a change in what the
traffic does, which the next section is about. The reason it has not displaced
three-tier in office buildings is that an office does not have that problem. Four
hundred desks talking to a handful of servers and the internet is exactly the
traffic pattern three-tier was designed around.

**RFC 7938 is the document to know exists.** It describes running BGP as the
routing protocol inside a large data centre fabric, and its early sections
explain why the Clos topology was chosen and what properties it has. It is free,
it is readable, and it is a primary source for a subject that is otherwise
covered entirely by vendor marketing.

<details class="deeper">
<summary>If you already work on networks: oversubscription, and the number that decides whether a design works</summary>

Oversubscription is the ratio between what a layer could receive and what it can
forward, and it is the arithmetic that separates a design from a drawing.

Take one access switch: 48 ports at 1 Gbps, so 48 Gbps of edge capacity, with two
10 Gbps uplinks, so 20 Gbps upward. That is 48 to 20, which reduces to roughly
2.4 to 1. If every port transmitted at line rate simultaneously, more than half
of it would have nowhere to go.

That is not a fault. Oversubscription is deliberate, because desks do not all
transmit at once and building for the worst case would cost several times more
for capacity that is never used. The design question is what ratio is acceptable,
and the honest answer is that it depends entirely on what the ports do. Desks
running email and web tolerate a high ratio comfortably. A rack of servers
replicating storage does not tolerate one at all.

The published conventions, and they are conventions rather than standards, put
access to distribution around 20 to 1 and distribution to core around 4 to 1 in a
campus. Data centre fabrics aim considerably lower, frequently 3 to 1 and
sometimes 1 to 1 for storage, which is what non-blocking means when a vendor says
it.

Two things make this worth doing on paper before ordering. The ratio changes when
port speeds change, so upgrading desks from 1 to 2.5 Gbps multiplies the
oversubscription by 2.5 without anybody touching the uplinks. And the symptom of
a bad ratio is not an error anywhere. It is a network that is fine most of the
time and slow during backups, which gets diagnosed as almost anything else first.

</details>

## North-south and east-west

The two terms describe direction of travel relative to a drawing where the
outside world is at the top.

**North-south** is traffic between a client and something outside its own layer:
a desk reaching the internet, a laptop reaching a server, anything that goes up
through the hierarchy and back down.

**East-west** is traffic between devices at the same level: server to server,
one virtual machine to another, one storage node to its replica.

The distinction matters because the three-tier model was built when almost
everything was north-south. Users at the edge, servers in the middle, and very
little reason for two servers to talk to each other. Under that pattern a design
that funnels traffic upward is exactly right.

Then applications stopped being one program on one server. A single request now
fans out across services, each on a different machine, each with a database and a
cache and a message queue, and every one of those hops is east-west. In a
three-tier design two servers on different access switches talk to each other by
going up to distribution and possibly to core and back down, which means the
layer built to be simple and fast is now carrying the majority of the traffic and
adding hops to all of it.

Spine and leaf answers that directly. Every leaf is one spine from every other
leaf, so east-west traffic takes the same path length wherever it goes, and
adding capacity means adding a spine rather than redesigning a hierarchy.

**Which is the answer to the question at the top of this page.** Two buildings and
four hundred desks is a north-south problem, and the right drawing is a collapsed
core in each building with a link between them. Nothing about that site benefits
from a spine and leaf fabric, and proposing one would be answering a question
nobody asked.

## Prove it

This topic has nothing to capture. Topology is a property of how things are
cabled, and a namespace has no cabling worth the name. So the evidence takes the
form the cabling topics used: read a named document and answer a question only
that document answers.

**RFC 7938, sections 3 and 4.** Free from the RFC editor. Read the discussion of
why a Clos topology was chosen for large data centres and answer one question:
what property does the document say the topology gives you that a hierarchical
design does not, and which layer of a Clos fabric do you add to when you need
more capacity between servers?

**RFC 3439, section 2.** Read the Simplicity Principle and answer a narrower
question: does the document argue that complexity should be minimised because it
is expensive, or because it limits how far a system can scale? The distinction is
the whole argument and most summaries get it backwards.

Then do the thing that costs nothing. Find the network diagram for wherever you
work. Count the layers between a desk and a server. If the answer is more than
three, ask why, and if the answer is that nobody knows, you have found something
worth writing down.

## What trips people up

### 1. Confusing physical topology with logical topology

The cabling and the traffic flow are different drawings and frequently disagree.
A network cabled as a star can behave as a logical ring, and a wireless network
with no cables at all still has a topology. When a question says topology, check
which one it means.

### 2. Treating full mesh as an aspiration

It is not the ideal that budget prevents. The link count grows as the square of
the device count, so a full mesh is unbuildable past a handful of sites and would
be a maintenance problem if it were not. Partial mesh is the answer, and choosing
which links to add is the actual design work.

### 3. Calling a two-tier network a collapsed core when it is not

A collapsed core does the distribution layer's jobs on the core devices: routing
between VLANs, policy, aggregation. Two switches in a row with no routing between
them is not a collapsed core, it is a flat network with an uplink, and the
distinction matters when somebody asks where a rule should go.

### 4. Assuming spine and leaf is simply better

It is better for east-west traffic in a fabric large enough to have that problem.
In a building where four hundred desks talk to the internet, it costs more, adds
no capability, and gives you more devices to maintain. The shape follows the
traffic.

### 5. Reading north-south and east-west as physical directions

They describe position in a hierarchy rather than geography. Two servers in
different buildings talking to each other is east-west traffic, even though the
packets travel between sites.

### 6. Ignoring oversubscription until it is a fault

The ratio is arithmetic anybody can do on paper before anything is bought, and
its symptom later is a network that is fine except when it is busy. Nothing
reports an error, which is why it is diagnosed last.

## Work it through

The site from the top of this page, and the reasoning in the order it should
happen.

Start with the traffic, not the shape. Four hundred desks, one server room, an
internet connection. Almost every packet goes from a desk to a server or to the
internet, which is north-south, and there is very little reason for two desks to
talk to each other at all. That single observation eliminates spine and leaf
before any cost is discussed.

Now the layers. Four hundred desks needs access switching in wiring closets on
each floor, which topic 13 established comes from the 100 metre limit rather than
from any design preference. Those access switches need aggregating. Whether that
aggregation layer is separate from the core is the only real question, and for one
site of this size it is not: a collapsed core, meaning a pair of switches doing
distribution and core together, is the defensible answer. A pair, not one,
because the whole point of the middle is that everything depends on it.

The second building changes one thing. It needs its own access switching and its
own aggregation, because the alternative is running desk cable between buildings,
which the distance limit forbids. So the shape is two collapsed cores with a link
between them, and that link is a point to point connection whatever technology
carries it.

Then the number nobody asks for. Twelve access switches at 48 ports each, uplinked
at 2 by 10 Gbps, gives roughly 2.4 to 1 per switch and 240 Gbps arriving at the
collapsed core if everything shouted at once. It will not, but the core pair has
to be sized against a plausible fraction of it rather than against the average,
and writing that number down is what turns a drawing into a design.

What is left is redundancy, and it is worth being explicit rather than assuming
it. Two core switches, two uplinks from each access switch, one to each core.
That is a partial mesh between the layers, and it means any single switch or any
single uplink can fail without taking a floor down. It also means spanning tree
has a loop to break, which is topic 19 arriving in a design conversation.

## Try it

**Draw your own network from memory, then check it.** Sketch the shape you think
it has, then find the real diagram. The difference between the two is the part
you did not understand, and it is worth more than the sketch.

**Do the oversubscription arithmetic for one switch.** Port count times port
speed, divided by uplink capacity. It takes a minute and most people have never
done it for equipment they own.

**Read RFC 7938's first four sections.** Twenty minutes, free, and it is the only
primary source most people will ever read on data centre topology.

## Check yourself

<details class="qa">
<summary>Why does a full mesh stop being buildable so quickly, and what replaces it?</summary>

Because the link count grows as the square of the number of devices. Connecting
every device to every other needs n times n minus one, over two, links: six
devices need fifteen, ten need forty-five, twenty need a hundred and ninety.

Partial mesh replaces it. Direct links are added only between the pairs whose
traffic justifies the cost, and everything else routes through them. Choosing
which pairs is the design work, and it is a traffic question rather than a
topology one.

</details>

<details class="qa">
<summary>What is a collapsed core, and when is it the right answer?</summary>

It is a three-tier design with the core and distribution layers performing on the
same pair of devices, so routing between VLANs, policy and aggregation happen
there rather than on a separate layer.

It is right for a single site that does not have the scale problem the third
layer exists to solve, which covers most office buildings. Three layers in a
building that needs two buys complexity and no capability.

The word collapsed is doing real work. It says the distribution layer's jobs are
still happening, which tells the next engineer where to look for the routing.

</details>

<details class="qa">
<summary>Two servers in the same rack exchange a large amount of data. Why does that argue against a three-tier design?</summary>

Because that traffic is east-west, and three-tier funnels traffic upward.

Two servers on different access switches reach each other by going up to
distribution, possibly to core, and back down. The layers built to aggregate a
mostly north-south load are now carrying the bulk of the traffic and adding hops
to every bit of it.

Spine and leaf answers it directly: every leaf is exactly one spine away from
every other leaf, so any two servers are the same distance apart regardless of
which rack they are in.

</details>

<details class="qa">
<summary>An access switch has 48 ports at 1 Gbps and two 10 Gbps uplinks. What is the oversubscription ratio, and is it a problem?</summary>

Forty-eight gigabits of edge against twenty gigabits of uplink, so roughly 2.4 to
1.

Whether it is a problem depends entirely on what is plugged in. For desks it is
comfortable, because they do not all transmit at once and building for the worst
case would cost several times more for capacity nobody uses. For a rack of
servers replicating storage it is not acceptable at all.

The thing to watch is that the ratio moves when port speeds change. Upgrading
those desks to 2.5 Gbps multiplies the oversubscription by 2.5 without anybody
touching an uplink.

</details>

<details class="qa">
<summary>What does RFC 3439's Simplicity Principle actually argue, and why does it belong in a topology discussion?</summary>

That complexity is what limits scaling, rather than merely being expensive. The
document argues that the cost and difficulty of a system grow faster than its
complexity does, which makes simplicity a scaling property and not a preference.

It belongs here because the usual justification for the three-tier model is
scalability, stated as though more structure means more scale. The RFC's argument
is the opposite and it is the better one: the layers are worth having because
each is simple enough to be reasoned about on its own, and that is also the reason
not to add a third layer to a site that needs two.

</details>

<details class="qa">
<summary>Why is spine and leaf described as equidistant, and what does that buy?</summary>

Because every leaf connects to every spine and no leaf connects to another leaf,
so a packet from any leaf to any other crosses exactly one spine. Every pair of
devices is the same number of hops apart.

What it buys is predictability. Latency between two machines does not depend on
which rack they are in, so placing a workload becomes a capacity decision rather
than a topology one. Adding capacity means adding a spine, which increases the
bandwidth between every pair of leaves at once, instead of redesigning a
hierarchy.

</details>

## References

- [RFC 7938](https://www.rfc-editor.org/rfc/rfc7938) - IETF, on using BGP inside large data centres, whose early sections explain the Clos topology and why it was chosen. Free. Accessed 2026-08-11.
- [RFC 3439](https://www.rfc-editor.org/rfc/rfc3439) - IETF, on architectural guidelines, and the source of the Simplicity Principle quoted above. Free. Accessed 2026-08-11.
- [IEEE 802.1Q](https://standards.ieee.org/ieee/802.1Q/10323/) - IEEE Standards Association, for the bridging behaviour the access layer depends on. Scope readable without purchase. Accessed 2026-08-11.

**Where the numbers came from.** Nothing on this page is captured, because a
topology is a property of cabling and a namespace has none. The link count
arithmetic is arithmetic. The oversubscription ratios described as conventions are
exactly that: widely repeated design guidance from vendors rather than figures
from a standard, which is why the panel says so rather than presenting them as
requirements. The Clos attribution is to Charles Clos at Bell Labs in 1953, and
RFC 7938 is the free document that connects that work to what data centres build
now.

**If you also work on Linux.** Nothing here has a Linux counterpart. A machine
knows its own links and its own routes and has no visibility of the shape it sits
inside, which is precisely why topology has to be documented rather than
discovered.
