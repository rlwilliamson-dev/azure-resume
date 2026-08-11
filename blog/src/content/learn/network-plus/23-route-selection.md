---
title: "Route selection"
description: "Two routes to the same place and only one goes in the table. The order the three tiebreaks are applied in, why prefix length beats everything including a much better metric, and what administrative distance is actually comparing."
deck: "Two routes to the same place. Only one gets used"
track: "network-plus"
level: "working"
order: 240
objectives:
  - "State the order in which prefix length, administrative distance and metric are applied"
  - "Say why a longer prefix wins regardless of any other value"
  - "Explain what administrative distance compares and what it does not"
  - "Read a routing table and say which route will be used"
  - "Recognise equal cost multipath and say what a router does with it"
prerequisites: ["dynamic-routing-protocols"]
tags: ["network-plus", "networking", "routing"]
updated: 2026-08-10
draft: false
examObjectives:
  - exam: "n10-009"
    domain: "2.0"
    objective: "2.1"
sources:
  - title: "RFC 4632, Classless Inter-domain Routing (CIDR)"
    url: "https://www.rfc-editor.org/rfc/rfc4632"
    publisher: "IETF"
    accessed: 2026-08-10
    tier: 1
  - title: "RFC 1812, Requirements for IP Version 4 Routers"
    url: "https://www.rfc-editor.org/rfc/rfc1812"
    publisher: "IETF"
    accessed: 2026-08-10
    tier: 1
  - title: "ip-route(8)"
    url: "https://man7.org/linux/man-pages/man8/ip-route.8.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-10
    tier: 1
symptoms:
  - symptom: "Traffic takes a route that is obviously worse than another in the table"
    anchor: "prefix-length-beats-everything"
  - symptom: "A static route added to fix something silently overrode a learned one"
    anchor: "administrative-distance"
---

> **Before you read.** A router's table contains two routes that both match the
> destination you care about. One goes across a ten gigabit link and one goes
> across a backup line.
>
> Traffic is taking the backup line.
>
> **What decided that, and in what order were the decisions made?**

The last two topics filled the table from two directions. Static routes are typed
and dynamic routes are learned, and nothing has stopped both from producing an
entry for the same destination. This topic is the arbitration, and the order it
happens in is the part people get wrong.

### Some words you will need

<dl class="terms">
<dt>administrative distance</dt>
<dd>How much a router trusts the source of a route. Lower is more trusted.</dd>
<dt>metric</dt>
<dd>How good a route is according to the protocol that produced it. Lower is better.</dd>
<dt>equal cost multipath</dt>
<dd>Two routes that tie completely, both installed and both used.</dd>
<dt>floating static route</dt>
<dd>A static route given a deliberately high administrative distance so it is only used if something better disappears.</dd>
</dl>

## What breaks without this

**A route you added does nothing, or does far too much.** Adding a static route
to fix one destination can silently override everything a protocol worked out,
and it will keep doing so after the original problem is gone.

**Traffic takes a path you can see is wrong.** The table plainly contains a better
route and the router is ignoring it, which makes no sense until you know the
order.

**Backup links either never engage or take over permanently.** Both are the same
misunderstanding of what the numbers mean.

## Three tests, in a fixed order

A router with several matching routes applies three tests, and the order is the
whole subject.

**First, prefix length.** The most specific match wins. This is not a tiebreak,
it is the first filter, and nothing later can override it.

**Then administrative distance**, among routes of equal prefix length. This
compares where the route came from rather than anything about the path.

**Then metric**, among routes of equal prefix length from the same source. This
compares the paths themselves.

<figure class="learn-figure">
<svg viewBox="0 0 720 322" role="img" aria-labelledby="select-title" style="width:100%;height:auto;">
<title id="select-title">The three route selection tests applied in order, with what each one discards</title>
<defs>
<marker id="sel-arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse">
<path d="M 0 0 L 10 5 L 0 10 z" fill="currentColor"/>
</marker>
</defs>
<g font-family="ui-monospace, monospace" fill="currentColor">
<rect x="17" y="28" width="330" height="58" rx="3" fill="currentColor" fill-opacity="0.16" stroke="currentColor" stroke-width="1.8"/>
<text x="33" y="52" font-size="11.5">1. longest prefix</text>
<text x="33" y="70" font-size="10.5" fill-opacity="0.85">the most specific match wins</text>
<rect x="17" y="118" width="330" height="58" rx="3" fill="currentColor" fill-opacity="0.1" stroke="currentColor" stroke-opacity="0.55"/>
<text x="33" y="142" font-size="11.5">2. lowest administrative distance</text>
<text x="33" y="160" font-size="10.5" fill-opacity="0.85">where the route came from</text>
<rect x="17" y="208" width="330" height="58" rx="3" fill="currentColor" fill-opacity="0.07" stroke="currentColor" stroke-opacity="0.55"/>
<text x="33" y="232" font-size="11.5">3. lowest metric</text>
<text x="33" y="250" font-size="10.5" fill-opacity="0.85">the path itself, measured</text>
<g stroke="currentColor" stroke-width="1.6" fill="none" marker-end="url(#sel-arrow)">
<line x1="182" y1="86" x2="182" y2="114"/>
<line x1="182" y1="176" x2="182" y2="204"/>
<line x1="347" y1="57" x2="362" y2="57"/>
<line x1="347" y1="147" x2="362" y2="147"/>
<line x1="347" y1="237" x2="362" y2="237"/>
</g>
<g font-size="10" fill-opacity="0.8">
<text x="196" y="104">only if two or more tie</text>
<text x="196" y="194">only if they still tie</text>
</g>
<g font-size="10.5">
<text x="370" y="52">anything less specific is out,</text>
<text x="370" y="68" fill-opacity="0.8">whatever its metric says</text>
<text x="370" y="142">anything from a less trusted</text>
<text x="370" y="158" fill-opacity="0.8">source is out</text>
<text x="370" y="232">of what survived, the lowest</text>
<text x="370" y="248" fill-opacity="0.8">metric is installed</text>
</g>
<text x="17" y="294" font-size="11">Most wrong answers start at the third test, because the metric is the number</text>
<text x="17" y="312" font-size="11" fill-opacity="0.85">that looks like it means quality. It is never consulted until the first two have tied.</text>
</g>
</svg>
<figcaption>Read it strictly downwards. A route that loses on prefix length is gone, and no metric anywhere can bring it back, which is the fact that makes almost every question in this material answerable. The second test only exists when two routes are equally specific, and the third only when they also came from the same protocol. Three separate comparisons, applied in one order, and the order is the entire subject.</figcaption>
</figure>

Most exam questions are built on candidates skipping straight to the third one,
because metric is the number that looks like it means quality.

## Prefix length beats everything

Here are two routes to the same network with very different metrics, and then a
third that is more specific and much worse.

<details class="predict">
<summary>Metric 10 against metric 200, then a /32 with a metric of 500 is added. Which route does traffic for 10.0.2.2 take?</summary>

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology three-routers
# two ways to reach the same network, added with different metrics
$ ip -n r1 route add 10.0.2.0/24 via 10.0.12.2 metric 10
$ ip -n r1 route add 10.0.2.0/24 via 10.0.13.2 metric 200
$ ip -n r1 route
10.0.1.0/24 dev r1-h1 proto kernel scope link src 10.0.1.1 
10.0.2.0/24 via 10.0.12.2 dev r1-r2 metric 10 
10.0.2.0/24 via 10.0.13.2 dev r1-r3 metric 200 
10.0.12.0/30 dev r1-r2 proto kernel scope link src 10.0.12.1 
10.0.13.0/30 dev r1-r3 proto kernel scope link src 10.0.13.1 
# the kernel picks one, and will say which
$ ip netns exec r1 ip route get 10.0.2.2
10.0.2.2 via 10.0.12.2 dev r1-r2 src 10.0.12.1 uid 0 
    cache 
# now add something more specific by one bit, with a worse metric
$ ip -n r1 route add 10.0.2.2/32 via 10.0.13.2 metric 500
$ ip netns exec r1 ip route get 10.0.2.2
10.0.2.2 via 10.0.13.2 dev r1-r3 src 10.0.13.1 uid 0 
    cache 
```

</details>

Two answers, and the second is the point.

With two /24s in the table, the router picks metric 10 over metric 200. That is
the third test doing its job between routes that tie on the first two.

Then a /32 arrives with a metric of 500, fifty times worse, and it wins
immediately. `ip route get` changes its answer and traffic goes out of the other
interface entirely.

**The metric was never compared.** Prefix length is checked first, a /32 is more
specific than a /24, and the arbitration ended there. A route can be arbitrarily
bad by every measure a protocol has and still win by being more specific.

That is worth having as a reflex, because it is the single most reliable exam
trap in this material, and because it is the arithmetic behind real events.
Announcing a more specific prefix than somebody else diverts their traffic, and no
amount of better metric on their side changes it.

<details class="deeper">
<summary>If you already work on networks: equal cost multipath, and what actually happens to a flow</summary>

Look at `10.0.23.0/30` in the previous topic's capture. It has two next hops,
because both paths through the triangle cost exactly the same and neither test
could separate them.

A router presented with a true tie installs both and uses both, which is equal
cost multipath. It is free capacity and free resilience, and it works the same way
link aggregation does, which means it has the same surprise attached.

Traffic is not alternated packet by packet. A router hashes fields from each
packet, typically the source and destination addresses and often the ports, and
sends everything with the same hash down the same path. That keeps a single
conversation on one route, because splitting it would deliver packets out of order
and topic 09 showed what TCP does with reordering.

So the same rule as bonding: many conversations share the capacity, and one large
transfer gets one path's worth.

Two consequences worth knowing. Traceroute across an equal cost multipath section
can produce confusing output, because each probe may hash differently and take a
different path, so the same hop number reports different routers on different
runs. Some traceroute implementations have a mode specifically for this.

And troubleshooting an intermittent fault becomes genuinely hard when only one of
two equal paths is broken. Half the flows work perfectly and half fail, based on a
hash nobody can see, which presents as a fault that depends on which machine you
test from.

</details>

## Administrative distance

The second test compares sources rather than paths, and it exists because a
router can learn about the same network from things that do not share a metric.

A metric from OSPF and a metric from EIGRP are not comparable numbers. They are
computed differently, from different inputs, on different scales. Comparing them
directly would be meaningless, so the router compares how much it trusts each
source first, and only compares metrics within one source.

Lower is more trusted. The conventional values put a directly connected route at
the top, a static route next, then the interior protocols, with an externally
learned route below them. The specific numbers vary by vendor and the research for
this track found no table of them in the objectives, so know what the concept
compares and do not memorise a vendor's list.

**The consequence people meet is static routes winning.** A static route is
trusted more than almost anything a protocol produces, because somebody typed it
deliberately. So adding one to work around a problem overrides whatever the
protocol had worked out, and keeps overriding it after the problem is fixed,
including after the path it points at has failed. The protocol knows about the
failure. The static route does not care.

<details class="deeper">
<summary>If you already work on networks: floating static routes, which is what to do instead</summary>

The fix for a static route that outranks everything is to make it outrank nothing,
which is what a floating static route is.

Give the static route an administrative distance higher than the protocol's, and
it sits in the configuration doing nothing at all while the learned route exists.
The moment the protocol withdraws its route, because the path failed, the static
route is the best remaining candidate and gets installed. When the protocol
recovers, the learned route wins again and the static goes back to sleep.

That is the standard way to configure a backup path, and it is much better than
the alternatives. A static route with default distance would override the primary
permanently. A route installed by hand during an outage requires somebody to be
awake and to remember to remove it.

The classic use is a backup WAN link that costs money per byte. Routing runs over
the primary, a floating static points at the backup, and traffic uses the
expensive link only when the cheap one is gone.

Two things worth checking when building one. The distance has to be higher than
whatever the protocol uses, so a floating static above OSPF and one above BGP are
different numbers, and getting it wrong produces a backup route that is either
always on or never on.

And the route only floats away when the primary is actually withdrawn. If the
primary path fails in a way that leaves the route installed, such as a link that
stays up while the far end is dead, nothing withdraws anything and the backup
never engages. That is what link failure detection protocols exist for, and it is
the same class of problem as the unidirectional link in topic 19.

</details>

## Reading a table and predicting the answer

The practical skill is looking at a table and saying what will happen, and it goes
in the same order.

Find every route that matches the destination. Discard everything that is not the
longest prefix among them. If more than one remains, compare administrative
distance. If more than one still remains, compare metric. If they tie completely,
both are used.

Then check yourself against the router, because `ip route get` runs the real
lookup rather than your reading of it, and the times it disagrees with you are the
times worth understanding.

The habit that catches the most real problems: when traffic is taking a route you
did not expect, look for a more specific one before looking at anything else. It
is the first test, it is invisible if you are scanning for the good metric, and it
is usually the answer.

## Prove it

You have this when you can look at two routes and say which wins without running
anything.

```bash
./blog/scripts/netlab.sh --topo topologies/three-routers.sh -- \
  'ip -n r1 route add 10.0.2.0/24 via 10.0.12.2 metric 10
ip -n r1 route add 10.0.2.0/24 via 10.0.13.2 metric 200
ip netns exec r1 ip route get 10.0.2.2
ip -n r1 route add 10.0.2.2/32 via 10.0.13.2 metric 500
ip netns exec r1 ip route get 10.0.2.2'
```

Predict both answers before running it. The first is a metric comparison between
equals. The second is not a comparison at all, and getting that distinction right
is the whole topic.

## What trips people up

### 1. Comparing metrics first

Prefix length is the first test and nothing overrides it. A route with a terrible
metric wins if it is more specific, and the metric is never examined.

### 2. Comparing metrics between protocols

An OSPF cost and an EIGRP composite metric are not the same kind of number.
Administrative distance exists precisely so the router compares sources first and
only compares metrics within one source.

### 3. Thinking a higher administrative distance is better

Lower is more trusted throughout, as with most routing numbers. Connected is the
most trusted, static is next, and learned routes are below them.

### 4. Adding a static route to fix something and leaving it

A static route usually outranks whatever a protocol learned, so it overrides the
protocol permanently, including after the path it names has failed. The protocol
knows; the static route does not care.

### 5. Expecting equal cost multipath to speed up one transfer

It hashes each flow onto one path to keep packets in order, so a single
conversation gets one path's worth. It is capacity across many flows, like
bonding.

### 6. Reading inconsistent traceroute output as a fault

Across an equal cost multipath section, different probes can hash onto different
paths, so the same hop reports different routers between runs. That is the
mechanism rather than a problem.

## Work it through

A site has a fast fibre link and a backup connection billed by the gigabyte.
Routing runs over the fibre. During a maintenance window somebody adds a static
route pointing a particular network at the backup, to keep one application
working. The window ends, the fibre comes back, and three weeks later the bill for
the backup link is enormous.

The static route never went away and it never stopped winning.

Work the order. Both routes are for the same prefix, so the first test does not
separate them. The second test is administrative distance, and a static route is
trusted more than anything a protocol learns, so the static wins. The metric is
never reached. Every packet for that network has been going over the metered link
since the maintenance window, whether or not the fibre was up.

Nothing reported it, because nothing is wrong. Traffic is being delivered, the
application works, and the only visible symptom arrived on an invoice.

Two things to fix. Remove the route, obviously. And notice that the pattern will
recur, because the next outage will produce the same workaround under the same
time pressure.

The durable answer is a floating static route: the same route with an
administrative distance higher than the protocol's, so it sits inert while the
fibre is up and installs itself automatically when the protocol withdraws its
route. That converts a manual workaround somebody has to remember to undo into a
backup path that engages and disengages on its own.

Worth adding one check to whatever runbook covers the maintenance window: list the
static routes on the border routers afterwards. A configuration that differs from
last month and nobody can explain is worth a minute.

## Try it

**Predict, then check.** Run the **Prove it** commands one at a time, writing down
what you expect `ip route get` to say before each one. The one that will catch you
is the /32.

**Read your own table for specificity.** On any machine, `ip route` and look for
overlapping prefixes. Most hosts have a connected route and a default, which is
the simplest possible case of longest prefix match, and seeing it as the same rule
that runs the internet is worth a moment.

**Find the metrics.** `ip route show` prints a metric where one is set, and on
Windows `Get-NetRoute` shows one on every entry, as the capture in topic 21 does.
Compare a default route's metric against a connected route's and notice which is
lower.

## Check yourself

<details class="qa">
<summary>A table has 10.0.2.0/24 with metric 10 and 10.0.2.2/32 with metric 500. Which is used for traffic to 10.0.2.2?</summary>

The /32, despite its metric being fifty times worse.

Prefix length is the first test and nothing later overrides it. A /32 is more
specific than a /24, so the arbitration ends there and the metric is never
compared.

Metric only separates routes that already tie on prefix length and on
administrative distance.

</details>

<details class="qa">
<summary>Why does administrative distance exist when routes already have metrics?</summary>

Because metrics from different sources are not comparable.

An OSPF cost is computed from bandwidth against a reference. An EIGRP metric is a
composite of bandwidth and delay. They are different scales measuring different
things, so a router that compared them directly would be comparing nothing.

Administrative distance sorts by how much the router trusts the source, and the
metric is then only used between routes from the same source, where it means
something.

</details>

<details class="qa">
<summary>Somebody adds a static route during an outage and the workaround is still in effect months later. Why did nothing report it?</summary>

Because nothing is wrong. Traffic is delivered and the application works.

A static route has a lower administrative distance than almost anything a
protocol learns, so it wins the second test and the protocol's route is never
used. That remains true after the original problem is fixed, and after the path
the static route names has itself failed, because the static route has no way to
know.

A floating static route, given a distance higher than the protocol's, would have
sat inert while the primary was healthy and installed itself only when the
protocol withdrew its route.

</details>

<details class="qa">
<summary>Two routes tie on prefix length, source and metric. What does the router do?</summary>

Installs both and uses both. That is equal cost multipath.

Traffic is not alternated per packet. The router hashes fields from each packet,
usually addresses and often ports, and sends everything with the same hash down
the same path, so a single conversation stays on one route and packets are not
reordered.

The consequence is the same as link aggregation: capacity across many
conversations, and one path's worth for any single transfer.

</details>

<details class="qa">
<summary>Traffic is taking a route that is clearly worse than another one in the table. What do you check first?</summary>

Whether a more specific route exists for that destination.

Prefix length is the first test, and it is easy to miss when scanning a table for
the entry with the good metric. A /32 or a longer prefix somewhere else in the
table wins regardless of how much better the obvious route looks.

Only after ruling that out is it worth comparing administrative distance, and only
then metric.

</details>

<details class="qa">
<summary>Why does traceroute sometimes report different routers for the same hop on consecutive runs?</summary>

Equal cost multipath.

Each traceroute probe is a separate packet and can hash onto a different one of
two equal paths, so consecutive probes for the same hop number arrive at different
routers.

It is the mechanism working rather than a fault. It does make an intermittent
problem harder to pin down, because if only one of the two paths is broken then
roughly half the flows fail based on a hash nobody can see.

</details>

## References

- [RFC 4632, Classless Inter-domain Routing (CIDR)](https://www.rfc-editor.org/rfc/rfc4632) - IETF, on longest prefix match. Accessed 2026-08-10.
- [RFC 1812, Requirements for IP Version 4 Routers](https://www.rfc-editor.org/rfc/rfc1812) - IETF, on route selection. Accessed 2026-08-10.
- [ip-route(8)](https://man7.org/linux/man-pages/man8/ip-route.8.html) - Linux man-pages project, on metrics and on `ip route get`. Accessed 2026-08-10.

**Where the output came from.** The captured block was produced on
`blog/scripts/topologies/three-routers.sh` through `blog/scripts/netlab.sh`. Both
selections are the kernel's own: `ip route get` runs the real lookup rather than
reporting what the table says, so the change of answer when the /32 is added is
the arbitration happening rather than a description of it.

Administrative distance is described rather than captured. The Linux kernel does
not implement it as a separate concept in the way network equipment does, since it
uses metric for both jobs, so demonstrating it honestly would need a router
operating system this lab does not have. Equal cost multipath is captured, in the
previous topic's routing table.

**If you also work on Linux.** [Network basics: addresses and routes](/learn/linux-plus/network-basics-addresses-and-routes)
on the Linux+ track covers route metrics on a host, where the same longest prefix
rule applies to a much shorter table.
