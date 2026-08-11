---
title: "Dynamic routing protocols"
description: "Forty routers and a link that failed at three in the morning. Why dynamic routing exists, what distinguishes the three protocols this exam names, what an adjacency is, and what convergence looks like when you watch a network repair itself."
deck: "Forty routers, and a link that just failed at 3am"
track: "network-plus"
level: "working"
order: 230
objectives:
  - "Say why static routing stops scaling and where the limit is"
  - "Name the three protocols the exam names and what distinguishes them"
  - "Tell interior from exterior routing and say which problem each solves"
  - "Explain what an adjacency is and what it means when one is not Full"
  - "Describe convergence and what happens during it"
prerequisites: ["the-routing-table-and-static-routes"]
tags: ["network-plus", "networking", "routing"]
updated: 2026-08-10
draft: false
examObjectives:
  - exam: "n10-009"
    domain: "2.0"
    objective: "2.1"
sources:
  - title: "RFC 2328, OSPF Version 2"
    url: "https://www.rfc-editor.org/rfc/rfc2328"
    publisher: "IETF"
    accessed: 2026-08-10
    tier: 1
  - title: "RFC 4271, A Border Gateway Protocol 4 (BGP-4)"
    url: "https://www.rfc-editor.org/rfc/rfc4271"
    publisher: "IETF"
    accessed: 2026-08-10
    tier: 1
  - title: "RFC 7868, Cisco's Enhanced Interior Gateway Routing Protocol (EIGRP)"
    url: "https://www.rfc-editor.org/rfc/rfc7868"
    publisher: "IETF"
    accessed: 2026-08-10
    tier: 1
  - title: "FRRouting documentation"
    url: "https://docs.frrouting.org/en/latest/"
    publisher: "FRRouting"
    accessed: 2026-08-10
    tier: 2
symptoms:
  - symptom: "A neighbour relationship never reaches Full and no routes are exchanged"
    anchor: "neighbours-and-adjacency"
  - symptom: "Traffic takes a longer path after a link failure and nobody changed anything"
    anchor: "convergence-watched-rather-than-described"
---

> **Before you read.** Forty routers. A link between two of them fails at three
> in the morning and there is a perfectly good path the other way round.
>
> Every router that needs to know is asleep, and so is everybody who could type
> a route.
>
> **What makes the traffic take the other path, and how long does it take?**

The previous topic ended on the argument for this one. Static routes are correct,
they are directional, and somebody has to write both halves of every one of them
and remember to do it again when anything changes. That works at three routers.

### Some words you will need

<dl class="terms">
<dt>dynamic routing</dt>
<dd>Routers telling each other what they can reach, so tables build themselves.</dd>
<dt>neighbour</dt>
<dd>Another router running the same protocol that this one has found and is talking to.</dd>
<dt>adjacency</dt>
<dd>A neighbour relationship that has progressed far enough to exchange routing information.</dd>
<dt>convergence</dt>
<dd>Every router agreeing again on the topology after something changed.</dd>
<dt>interior gateway protocol</dt>
<dd>A protocol for routing inside one organisation's network.</dd>
<dt>autonomous system</dt>
<dd>One organisation's routing domain, with a number, as far as the internet is concerned.</dd>
</dl>

## What breaks without this

**Every change is a manual change, in two directions, on every router.** Adding
one subnet at one site means editing routers that have nothing to do with it, and
missing one produces the fault the previous topic worked through.

**A failure stays a failure until somebody wakes up.** The redundant path exists
and nothing uses it, which makes the redundancy decorative.

**You cannot read the output.** Routes learned by a protocol appear in the same
table as everything else, marked with where they came from, and the next topic is
about choosing between them.

## Three protocols, and what separates them

The exam names three, and the research for this track found that RIP and IS-IS
appear in the acronym list and nowhere in the objectives, so these are the three
to know.

| | Type | Scope | Chooses by |
| --- | --- | --- | --- |
| OSPF | Link state | Interior, open standard | Cost, derived from bandwidth |
| EIGRP | Advanced distance vector | Interior, originally Cisco | A composite of bandwidth and delay |
| BGP | Path vector | Exterior, between organisations | Policy, not distance |

The first division that matters is interior against exterior.

**Interior protocols run inside one organisation** and their job is to find the
best path. Everybody involved is on the same side, trusts each other, and wants
traffic to take the shortest route. OSPF and EIGRP are both this.

**BGP runs between organisations** and its job is different in kind. It is how
the internet's routing works, between autonomous systems, and the best path there
is not the shortest one. It is the one your contracts, your peering agreements and
your commercial preferences say it is. A route through a cheaper transit provider
may be longer and still be the one you want.

That is why BGP is described as a policy protocol rather than a shortest-path
one, and it is the single most useful thing to know about it at this level.

The second division is how a protocol learns.

**Distance vector** routers tell their neighbours what they can reach and how far
away it is. Each router knows distances and directions and has no picture of the
topology. It is simple, and it converges slowly, because information propagates
router by router.

**Link state** routers describe their own links to everybody, and each router
independently builds a complete map of the network and calculates the best paths
across it. That costs memory and processing and converges faster, because a change
is flooded to everyone rather than passed along.

<figure class="learn-figure">
<svg viewBox="0 0 720 300" role="img" aria-labelledby="dvls-title" style="width:100%;height:auto;">
<title id="dvls-title">What one router ends up knowing under a distance vector protocol and under a link state protocol</title>
<defs>
<marker id="dvls-arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse">
<path d="M 0 0 L 10 5 L 0 10 z" fill="currentColor"/>
</marker>
</defs>
<g font-family="ui-monospace, monospace" fill="currentColor">
<rect x="12" y="34" width="340" height="256" rx="4" fill="currentColor" fill-opacity="0.03" stroke="currentColor" stroke-opacity="0.3"/>
<text x="28" y="56" font-size="11.5">distance vector</text>
<text x="28" y="72" font-size="10" fill-opacity="0.75">the neighbours tell A what they can reach</text>
<circle cx="90" cy="112" r="16" fill="currentColor" fill-opacity="0.1" stroke="currentColor" stroke-opacity="0.55"/>
<text x="90" y="116" text-anchor="middle" font-size="11">B</text>
<circle cx="90" cy="182" r="16" fill="currentColor" fill-opacity="0.1" stroke="currentColor" stroke-opacity="0.55"/>
<text x="90" y="186" text-anchor="middle" font-size="11">C</text>
<circle cx="200" cy="147" r="18" fill="currentColor" fill-opacity="0.2" stroke="currentColor" stroke-width="1.8"/>
<text x="200" y="151" text-anchor="middle" font-size="11">A</text>
<circle cx="300" cy="147" r="16" fill="currentColor" fill-opacity="0.03" stroke="currentColor" stroke-opacity="0.35" stroke-dasharray="4 3"/>
<text x="300" y="151" text-anchor="middle" font-size="11" fill-opacity="0.7">D</text>
<g stroke="currentColor" stroke-width="1.6" fill="none" marker-end="url(#dvls-arrow)">
<line x1="106" y1="118" x2="180" y2="140"/>
<line x1="106" y1="176" x2="180" y2="154"/>
</g>
<text x="146" y="104" text-anchor="middle" font-size="10">D, 1 away</text>
<text x="146" y="202" text-anchor="middle" font-size="10">D, 1 away</text>
<text x="300" y="182" text-anchor="middle" font-size="10" fill-opacity="0.65">never seen</text>
<text x="28" y="238" font-size="10.5">what A holds: two distances and two directions,</text>
<text x="28" y="254" font-size="10.5" fill-opacity="0.85">and no picture of the network at all. A change</text>
<text x="28" y="270" font-size="10.5" fill-opacity="0.85">reaches it only when a neighbour passes it on.</text>
<rect x="368" y="34" width="340" height="256" rx="4" fill="currentColor" fill-opacity="0.03" stroke="currentColor" stroke-opacity="0.3"/>
<text x="384" y="56" font-size="11.5">link state</text>
<text x="384" y="72" font-size="10" fill-opacity="0.75">every router describes its own links to everybody</text>
<g stroke="currentColor" stroke-opacity="0.55" stroke-width="1.4">
<line x1="438" y1="112" x2="544" y2="112"/>
<line x1="420" y1="130" x2="420" y2="161"/>
<line x1="560" y1="128" x2="560" y2="161"/>
<line x1="436" y1="179" x2="544" y2="179"/>
</g>
<circle cx="420" cy="112" r="18" fill="currentColor" fill-opacity="0.2" stroke="currentColor" stroke-width="1.8"/>
<text x="420" y="116" text-anchor="middle" font-size="11">A</text>
<circle cx="560" cy="112" r="16" fill="currentColor" fill-opacity="0.1" stroke="currentColor" stroke-opacity="0.55"/>
<text x="560" y="116" text-anchor="middle" font-size="11">B</text>
<circle cx="420" cy="179" r="16" fill="currentColor" fill-opacity="0.1" stroke="currentColor" stroke-opacity="0.55"/>
<text x="420" y="183" text-anchor="middle" font-size="11">C</text>
<circle cx="560" cy="179" r="16" fill="currentColor" fill-opacity="0.1" stroke="currentColor" stroke-opacity="0.55"/>
<text x="560" y="183" text-anchor="middle" font-size="11">D</text>
<text x="696" y="150" text-anchor="end" font-size="10" fill-opacity="0.7">A has all of this</text>
<text x="384" y="238" font-size="10.5">what A holds: the whole map, built from</text>
<text x="384" y="254" font-size="10.5" fill-opacity="0.85">descriptions flooded to every router, and it runs</text>
<text x="384" y="270" font-size="10.5" fill-opacity="0.85">the shortest path calculation over it itself.</text>
</g>
</svg>
<figcaption>The same four routers, and the difference is what A ends up with. On the left it holds two numbers and two directions, and D is a name it has been told about rather than a router it has any picture of. On the right it holds the map and does the arithmetic itself. That is the whole trade: the left costs almost nothing to run and takes time to react, because news travels router by router, and the right costs memory and processor and reacts quickly, because a change is flooded to everybody at once.</figcaption>
</figure>

EIGRP sits between the two, which is why it gets called advanced distance vector:
it keeps neighbour-based distance information and adds enough state to converge
quickly.

<details class="deeper">
<summary>If you already work on networks: why BGP works the way it does, and why that is a security problem</summary>

BGP looks primitive next to OSPF until you understand what it is being asked to
do, and then it looks like the only thing that could work.

An interior protocol assumes everyone participating is cooperative and wants the
same outcome. BGP cannot assume any of that. It connects competing companies
whose commercial interests conflict, who do not want to reveal their internal
topology, and who need to enforce different policies toward each other.

So BGP exchanges paths rather than distances. An announcement carries the list of
autonomous systems the route passes through, which does two things: it lets a
router apply policy based on who the path crosses, and it prevents loops, because
a router seeing its own number in a path knows it has been here before.

Path length is a tiebreak rather than the decision. Which route wins is decided
by attributes an operator sets to express preference, and "shortest" is well down
the list.

The security consequence is the one worth carrying. BGP was built on the
assumption that participants tell the truth, and there is no inherent
verification that an organisation announcing a prefix is entitled to it. Announce
somebody else's addresses, more specifically than they do, and the previous
topic's longest prefix match sends the traffic to you. That is a BGP hijack, and
it happens, sometimes by accident through a configuration error and sometimes
not.

The mitigations are bolted on rather than built in: filtering what you accept
from customers, registries recording who owns what, and cryptographic route origin
validation which is being deployed slowly. For this exam, know that BGP is the
exterior protocol, that it chooses on policy, and that it takes what it is told on
trust.

</details>

## Neighbours and adjacency

Before any routes move, two routers have to find each other and agree to talk.
That relationship has states, and the states are where troubleshooting starts.

Here is OSPF running on three routers that were given addresses and nothing else.

<details class="predict">
<summary>Nobody configured a route. What does r1 know about its neighbours, and what is in its table?</summary>

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology three-routers-ospf
# nobody configured a route. these were learned
$ ip netns exec r1 vtysh --vty_socket /var/run/frr-r1 -c "show ip ospf neighbor"

Neighbor ID     Pri State           Up Time         Dead Time Address         Interface                        RXmtL RqstL DBsmL
10.10.10.2        1 Full/-          15.071s           34.952s 10.0.12.2       r1-r2:10.0.12.1                      0     0     0
10.10.10.3        1 Full/-          15.071s           34.977s 10.0.13.2       r1-r3:10.0.13.1                      0     0     0

$ ip -n r1 route | grep -A2 ospf
10.0.2.0/24 nhid 21 via 10.0.12.2 dev r1-r2 proto ospf metric 20 
10.0.12.0/30 dev r1-r2 proto kernel scope link src 10.0.12.1 
10.0.13.0/30 dev r1-r3 proto kernel scope link src 10.0.13.1 
10.0.23.0/30 nhid 22 proto ospf metric 20 
	nexthop via 10.0.13.2 dev r1-r3 weight 1 
	nexthop via 10.0.12.2 dev r1-r2 weight 1 
```

</details>

Two neighbours, both `Full`, and routes marked `proto ospf` that nobody typed.

**`Full` is the state that matters.** It means the two routers have exchanged
their complete view of the topology and are ready to use each other. A
relationship stuck in any earlier state is the classic OSPF fault: the routers
can see each other, the protocol is running, and no routes are being exchanged.

That is worth recognising because it happened while building this page. The first
attempt left both neighbours at `2-Way`, which is a real state meaning the routers
have seen each other's messages and stopped there. The links were /30s with two
devices on them, and OSPF treated them as broadcast networks, where routers elect
a designated router and only form full adjacencies with it. All three elected
themselves as neither, so nobody went further and no route was ever exchanged.
Telling the interfaces they are point-to-point fixed it.

The general lesson is more useful than the specific fix. **A protocol that is
running, with neighbours visible, and no routes exchanged, is almost always a
mismatch between what the two ends think the link is.** Network type, area,
authentication, timers and MTU can all do this, and each produces a relationship
that stalls rather than one that fails outright.

Look also at `10.0.23.0/30` in that table. It has two next hops, one through each
neighbour, because both paths cost the same. That is equal cost multipath, and
the next topic covers what the router does with it.

<details class="deeper">
<summary>If you already work on networks: what an interior protocol actually measures, and why bandwidth is not it</summary>

OSPF picks the lowest total cost, and cost is calculated from interface bandwidth
by a formula with a reference value in it. The default reference has not kept up
with reality, and the consequence catches people out.

The classic formula divides a reference bandwidth by the interface bandwidth, with
the default reference set to 100 Mbps. Anything at or above 100 Mbps therefore
gets the minimum cost of 1. A gigabit link, a ten gigabit link and a hundred
megabit link all cost exactly the same, so OSPF cannot tell them apart and will
happily send traffic down the slowest of the three.

The fix is to raise the reference bandwidth, and to raise it identically on every
router, because a value that differs between routers produces inconsistent path
selection that is genuinely unpleasant to debug.

Two more things worth knowing about what these protocols do not measure.

Neither OSPF nor EIGRP measures load. Cost is derived from configured bandwidth
rather than from how busy the link is right now, so a saturated link keeps
attracting traffic because on paper it is still the best path. Load-aware routing
sounds obviously correct and turns out to oscillate, because moving traffic
changes the measurement that moved it.

And latency is only in the calculation for EIGRP, through its delay component.
OSPF has no notion of it at all, so a satellite link and a fibre link of the same
stated bandwidth look identical, which is exactly the case where they are not.

Which is why real designs set costs by hand on links that matter rather than
trusting the derived value.

</details>

## Convergence, watched rather than described

Now the question at the top. A link fails and nobody is awake.

<details class="predict">
<summary>The direct link between r1 and r2 is taken down. What happens to the route, and to the actual path traffic takes?</summary>

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology three-routers-ospf
# the way to h2 today, straight across the direct link
$ ip -n r1 route | grep "10.0.2.0"
10.0.2.0/24 nhid 21 via 10.0.12.2 dev r1-r2 proto ospf metric 20 
$ ip netns exec h1 traceroute -n -q 1 -w 1 10.0.2.2
traceroute to 10.0.2.2 (10.0.2.2), 30 hops max, 60 byte packets
 1  10.0.1.1  0.055 ms
 2  10.0.12.2  0.060 ms
 3  10.0.2.2  0.037 ms
# now break that link at three in the morning
$ ip -n r1 link set r1-r2 down
$ sleep 45
# nobody typed anything, and there is a new way there
$ ip -n r1 route | grep "10.0.2.0"
10.0.2.0/24 nhid 17 via 10.0.13.2 dev r1-r3 proto ospf metric 20 
$ ip netns exec h1 traceroute -n -q 1 -w 1 10.0.2.2
traceroute to 10.0.2.2 (10.0.2.2), 30 hops max, 60 byte packets
 1  10.0.1.1  0.047 ms
 2  10.0.13.2  0.078 ms
 3  10.0.23.1  0.022 ms
 4  10.0.2.2  0.019 ms
```

</details>

Before the failure, three hops, straight across the direct link.

After it, four hops, the long way round through r3. The route in the table now
points at a different neighbour, and the traceroute proves that traffic genuinely
takes the new path rather than the table merely claiming it would.

**Nobody typed anything.** The routers noticed the link was gone, told each
other, recalculated, and installed a different path. That is the whole argument
for dynamic routing in one capture, and it is the answer to the question at the
top: the traffic takes the other path because the routers worked it out, and it
takes as long as the protocol takes to notice and agree.

How long is a real question with a design answer. A protocol notices a failure
either because the interface went down, which is immediate, or because it stopped
hearing from a neighbour, which takes as long as the dead timer. Those timers are
configurable and the trade is the usual one: shorter timers detect failure faster
and produce more false positives on a busy or lossy link.

During convergence the network is inconsistent. Some routers have the new
topology and some have the old, so traffic can loop or be dropped for the duration.
That window is the real cost of a failure, and shrinking it is most of what
routing design is about.

## Prove it

You have this when you can look at an adjacency and say whether routes should be
flowing.

```bash
./blog/scripts/netlab.sh --topo topologies/three-routers-ospf.sh -- \
  'ip netns exec r1 vtysh --vty_socket /var/run/frr-r1 -c "show ip ospf neighbor"; ip -n r1 route'
```

Three things to check. Both neighbours are `Full` rather than any earlier state.
The table contains routes marked `proto ospf` for networks r1 is not attached to.
And nothing anywhere was configured with a destination.

Then break something and run it again, which the second capture does. Watching a
table change on its own is the part that makes this stop feeling like magic.

## What trips people up

### 1. Reading a visible neighbour as a working one

Neighbours can be seen without being adjacent. A relationship stuck below `Full`
means the routers found each other and never got as far as exchanging routes,
which looks like the protocol working and produces no routes at all.

### 2. Thinking BGP finds the shortest path

It finds the path policy prefers. Path length is one attribute among several and
it is not the first one checked. A longer path through a cheaper provider is a
normal and intended outcome.

### 3. Expecting OSPF to distinguish fast links

With the default reference bandwidth, everything at or above 100 Mbps costs the
same, so a gigabit link and a hundred megabit link are indistinguishable. The
reference has to be raised, identically, on every router.

### 4. Assuming convergence is instant

There is a window where different routers have different views, and traffic can
loop or be dropped during it. How long depends on how the failure was detected
and on the timers.

### 5. Mixing static and dynamic without thinking about precedence

A static route and a learned route for the same prefix both exist, and which one
is used is the next topic's subject. Adding a static route to fix something can
silently override what the protocol worked out.

### 6. Treating a routing protocol as a substitute for a design

It distributes what it is told. Wrong areas, wrong costs or wrong summarisation
converge perfectly on a bad answer.

## Work it through

A company with six sites runs static routes between them, maintained by one
person who has just left. A new subnet at one site is unreachable from two of the
other five, and nobody can say which routers were supposed to have been updated.

The immediate fix is to find the missing entries, and that is a search rather
than a diagnosis: compare each router's table against the list of networks that
should exist, on all six. Tedious and finite.

The interesting question is whether to keep doing this, and the shape of the fault
answers it. Six sites means the person who left had to maintain routes in a mesh,
in both directions, and the failure mode is that nobody can now say what the
correct configuration even is. There is no source of truth except the tables
themselves, and two of them are wrong.

Dynamic routing removes the class of problem rather than this instance of it. Each
router advertises the networks it is attached to, every other router learns them,
and a new subnet appears everywhere the moment its interface comes up. Both
directions, automatically, because advertising is inherently bidirectional.

Which protocol is a smaller question than it sounds. This is one organisation's
internal network, so it is an interior protocol, which rules BGP out. Between OSPF
and EIGRP the deciding factor is usually the hardware: EIGRP began as a Cisco
protocol and OSPF is an open standard supported by everything, so a mixed-vendor
network points at OSPF.

What not to do is add a monitoring check that alerts when a route is missing. That
is building a detector for a problem that has a solution, and it leaves the
manual process in place with a faster way to find out it failed.

## Try it

**Watch a table build itself.** Run the command from **Prove it**. Routes appear
for networks nobody mentioned, which is worth seeing once.

**Break a link and watch it heal.** The second capture's commands do this, and the
traceroute before and after is the part to pay attention to, because it proves the
traffic moved rather than the table changing its mind.

**Look for the protocol on your own network.** If you have access to a router,
`show ip route` or the equivalent marks each entry with how it was learned.
Counting how many are connected, static and dynamic tells you a lot about how the
network is run.

## Check yourself

<details class="qa">
<summary>Two OSPF routers can see each other but no routes are exchanged. The adjacency shows 2-Way. What does that mean?</summary>

They have found each other and stopped short of exchanging topology information.

`Full` is the state where two routers have swapped their complete view and can use
each other's routes. Anything below it means the relationship formed and then
stalled.

The usual causes are a mismatch in what the two ends think the link is: network
type, area, authentication, timers or MTU. On the topology behind this page it was
network type, because /30 links were being treated as broadcast networks where
routers only fully adjoin with an elected designated router, and all three had
elected nobody.

</details>

<details class="qa">
<summary>Why is BGP described as a policy protocol rather than a shortest-path one?</summary>

Because it runs between organisations whose interests differ, so the best path is
a commercial question rather than a geometric one.

An announcement carries the list of autonomous systems a route passes through,
which lets an operator apply preference based on who the path crosses, and
prevents loops because a router seeing its own number knows it has been here.

Path length is one attribute among several and not the first checked. A longer
path through a cheaper transit provider is a normal outcome rather than a fault.

</details>

<details class="qa">
<summary>What is the difference between distance vector and link state?</summary>

Distance vector routers tell their neighbours what they can reach and how far it
is. Each router knows directions and distances and has no picture of the topology,
so information propagates hop by hop and convergence is slower.

Link state routers describe their own links to everybody. Each one independently
builds a complete map and calculates paths across it, which costs memory and
processing and converges faster because a change is flooded to everyone at once.

OSPF is link state, BGP is path vector, and EIGRP sits between the first two,
which is why it is called advanced distance vector.

</details>

<details class="qa">
<summary>A link fails and traffic takes a longer path a few seconds later. Nobody logged in. What happened?</summary>

The protocol converged.

The routers either saw the interface go down or stopped hearing from the
neighbour across it, told each other, recalculated their paths and installed a new
next hop for the affected networks.

The capture on this page shows exactly that: three hops before, four hops after,
via a different neighbour, with no configuration change. During the gap between
the failure and everyone agreeing, the network is inconsistent and traffic can
loop or be dropped.

</details>

<details class="qa">
<summary>Why can OSPF fail to distinguish a gigabit link from a 100 megabit one?</summary>

Because cost is derived from bandwidth against a reference value, and the
traditional default reference is 100 Mbps.

Anything at or above that gets the minimum cost of 1, so a hundred megabit link,
a gigabit link and a ten gigabit link are identical as far as path selection is
concerned, and traffic can be sent down the slowest.

Raising the reference bandwidth fixes it, and it has to be raised to the same
value on every router, because inconsistent references produce inconsistent path
selection.

</details>

<details class="qa">
<summary>Why does dynamic routing solve the missing-return-route problem that static routing has?</summary>

Because advertising is inherently bidirectional.

A static route is one direction, written on one router, and the matching entry at
the far end is a separate act somebody has to remember. Forgetting it produces
traffic that arrives and replies that are discarded.

With a protocol, every router tells every other router which networks it can
reach, so both directions are established by the same mechanism. A new subnet
appears everywhere as soon as its interface comes up.

</details>

## References

- [RFC 2328, OSPF Version 2](https://www.rfc-editor.org/rfc/rfc2328) - IETF, including the adjacency states and the designated router election behind the 2-Way problem on this page. Accessed 2026-08-10.
- [RFC 4271, A Border Gateway Protocol 4](https://www.rfc-editor.org/rfc/rfc4271) - IETF, on path attributes and why length is a tiebreak. Accessed 2026-08-10.
- [RFC 7868, EIGRP](https://www.rfc-editor.org/rfc/rfc7868) - IETF, on the composite metric. Accessed 2026-08-10.
- [FRRouting documentation](https://docs.frrouting.org/en/latest/) - FRRouting, the implementation used for the captures. Accessed 2026-08-10.

**Where the output came from.** Both blocks were produced on
`blog/scripts/topologies/three-routers-ospf.sh` through `blog/scripts/netlab.sh`,
running FRRouting in each namespace. The adjacencies, the learned routes and the
reconvergence after the link is taken down are an actual routing implementation's
work rather than an illustration.

The 2-Way problem described in the adjacency section is not a story. The first
build of that topology produced exactly it, with both neighbours visible, the
protocol running and not one route exchanged, and the fix was declaring the /30
links point-to-point. It is in the topology file with a comment saying why.

BGP and EIGRP are described rather than captured. BGP needs two organisations to
be meaningful and EIGRP has no implementation available here, so this page shows
one of the three protocols working and is explicit about which.

**If you also work on Linux.** Nothing here has a Linux+ counterpart. A Linux host
runs static routes and a default gateway, and the moment it runs a routing
protocol it has stopped being a host and become a router.
