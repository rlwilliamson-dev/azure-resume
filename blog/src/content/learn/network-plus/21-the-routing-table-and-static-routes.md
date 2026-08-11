---
title: "The routing table and static routes"
description: "A packet arrives for a network this machine is not on. The routing table is the list of decisions that answers what happens next: connected routes nobody typed, static routes somebody did, longest prefix match, and the default route as the answer of last resort."
deck: "The packet is not for anyone here. Now what"
track: "network-plus"
level: "working"
order: 220
objectives:
  - "Read a routing table and say where a given packet goes"
  - "Tell connected, static and default routes apart"
  - "Apply longest prefix match to choose between two candidate routes"
  - "Add a static route and predict its effect"
  - "Explain why a default gateway is the least specific route rather than a special setting"
prerequisites: ["ipv4-addresses-and-the-mask"]
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
  - symptom: "Network is unreachable for a destination that should be routed"
    anchor: "connected-static-and-default"
  - symptom: "Traffic reaches a destination and nothing comes back"
    anchor: "the-return-path-nobody-configures"
---

> **Before you read.** A router receives a packet. The destination is not on any
> network the router is attached to, and it is not the router's own address.
>
> The router has three interfaces and no idea what is beyond them except what it
> has been told.
>
> **What does it do, and what would have to be true for it to do the right
> thing?**

Topic 02 covered how a host decides between delivering directly and handing a
packet to a router. This is the other half: what the router does when it gets it.
Every routing topic after this one is a different way of filling in the same
table.

### Some words you will need

<dl class="terms">
<dt>routing table</dt>
<dd>A list of destination prefixes and where to send traffic for each.</dd>
<dt>connected route</dt>
<dd>A route the kernel created because an interface has an address on that network.</dd>
<dt>static route</dt>
<dd>A route somebody typed, which stays until somebody removes it.</dd>
<dt>next hop</dt>
<dd>The address of the router to hand the packet to, on the way to somewhere further.</dd>
<dt>default route</dt>
<dd>0.0.0.0/0, matching everything, used when nothing more specific does.</dd>
<dt>longest prefix match</dt>
<dd>The rule that the most specific matching route wins, whatever else is true.</dd>
</dl>

## What breaks without this

**Network is unreachable, and you cannot say why.** It is the router announcing
it has no route, which is a completely different fault from a timeout, and
telling them apart is most of routing troubleshooting.

**Traffic goes out and nothing comes back.** A route in one direction is not a
route in both, and a missing return path is the single most common static routing
mistake.

**You cannot read the output of every tool in the next five topics.** Dynamic
routing, route selection and NAT all produce entries in this table, and they are
read the same way.

## The table is a list of decisions

A router receives a packet, reads the destination address, and finds the most
specific route that matches. That is the whole algorithm, and everything else is
about how entries get there.

Here is a router that has only what its own interfaces gave it.

<details class="predict">
<summary>r1 has three interfaces with addresses. What does it know, and can it reach a network two hops away?</summary>

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology three-routers
# r1 knows only what it is directly attached to
$ ip -n r1 route
10.0.1.0/24 dev r1-h1 proto kernel scope link src 10.0.1.1 
10.0.12.0/30 dev r1-r2 proto kernel scope link src 10.0.12.1 
10.0.13.0/30 dev r1-r3 proto kernel scope link src 10.0.13.1 
# so it has no idea how to reach the network behind r2
$ ip netns exec r1 ping -c 1 -W 1 10.0.2.2
ping: connect: Network is unreachable
# tell it, once
$ ip -n r1 route add 10.0.2.0/24 via 10.0.12.2
$ ip -n r1 route
10.0.1.0/24 dev r1-h1 proto kernel scope link src 10.0.1.1 
10.0.2.0/24 via 10.0.12.2 dev r1-r2 
10.0.12.0/30 dev r1-r2 proto kernel scope link src 10.0.12.1 
10.0.13.0/30 dev r1-r3 proto kernel scope link src 10.0.13.1 
$ ip netns exec r1 ping -c 1 -W 1 10.0.2.2 | tail -3
--- 10.0.2.2 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 0.041/0.041/0.041/0.000 ms
```

</details>

Three routes before anybody typed anything, and they came from the addresses. An
interface configured with `10.0.12.1/30` tells the kernel two things: this machine
holds that address, and the whole `10.0.12.0/30` network is reachable directly out
of that interface. `proto kernel` is the kernel saying so, and `scope link` means
the destinations are on the wire rather than beyond another router.

**So a connected route is a consequence of an address, not a configuration.**
Nobody adds them and nobody should have to.

Then the ping to `10.0.2.2` fails with `Network is unreachable`, and the wording
is exact. The router is not saying the destination is down. It is saying it
searched the table, found nothing that matches, and did not send anything. Topic
01 met the same message from a host, and it means the same thing at every scale:
no route, so no attempt.

One `ip route add` fixes it. `10.0.2.0/24 via 10.0.12.2` says traffic for that
network goes to that neighbour, and the neighbour's problem is what happens next.
That is the whole of routing: each router knows the next step and none of them
knows the whole path.

<details class="deeper">
<summary>If you already work on networks: the return path nobody configures</summary>

The single most common static routing mistake is doing half of it, and the reason
it is so common is that half of it feels like all of it.

A route is directional. Adding `10.0.2.0/24 via 10.0.12.2` on r1 tells r1 how to
send traffic toward that network. It says nothing whatsoever about how the replies
get back, and the routers at the far end have their own tables with their own
gaps.

So the classic result is a ping that fails while the request is arriving
perfectly. The echo request crosses the network, the destination receives it and
generates a reply, and the reply hits a router with no route back to the sender's
network and is discarded. From the sender it looks identical to the destination
being down.

The way to catch it quickly is to test from both ends, or to capture at the
destination. A destination that is receiving requests and answering them, while
the sender sees nothing, is a return path problem and nothing else.

This is also the strongest practical argument for dynamic routing, which topic 22
covers. A protocol that advertises networks does both directions by construction,
because every router tells every other router what it can reach. Static routes are
two configurations that a person has to remember are related, and people forget.

One more asymmetry worth knowing. It is possible for traffic to work in both
directions by different paths, which is asymmetric routing and is not by itself a
fault. It becomes one the moment a stateful firewall is involved, because a
firewall that saw the request expects to see the reply, and a reply arriving by
another path hits a firewall with no record of the connection and gets dropped.

</details>

## Connected, static, and default

Three ways an entry gets into the table, and the exam names all three.

| Kind | Where it comes from | Changes when |
| --- | --- | --- |
| Connected | An address on an interface | The interface goes down or the address changes |
| Static | Somebody typed it | Somebody types something else |
| Default | Typed or learned, and matches everything | The same as whichever it is |

**The default route is not a special mechanism.** It is written `0.0.0.0/0`, a
prefix of zero bits, which matches every address in existence. It is used only
when nothing more specific matches, and that is not a rule about defaults, it is
longest prefix match doing its ordinary job on the least specific possible entry.

That is worth internalising because it demystifies the default gateway setting on
every device you have ever configured. Setting a default gateway adds one route,
`0.0.0.0/0 via <that address>`, and the reason it is the last resort is
arithmetic rather than policy.

A router with a default route will never say `Network is unreachable`, because
something always matches. Whether the traffic gets anywhere is a different
question, and that difference is why a router with a default route can silently
send traffic into a hole rather than reporting a problem.

<details class="deeper">
<summary>If you already work on networks: longest prefix match, and why it is a feature rather than a tiebreak</summary>

Longest prefix match sounds like a tiebreaking rule and it is better understood
as the mechanism that makes the whole internet's routing tractable.

The rule: among all routes that match a destination, the one with the most
network bits wins. A /32 beats a /24, a /24 beats a /16, and `0.0.0.0/0` loses to
everything.

What that buys is the ability to state a general case and then carve exceptions
out of it without rewriting anything. A default route says send everything this
way. A single more specific route says except this network. A /32 says except this
one machine. Each addition overrides the broader statement automatically, and none
of them has to know the others exist.

That is how a provider carries a summarised block and a customer's more specific
announcement at the same time, and it is why route summarisation, which topic 24
covers, works without breaking anything: the summary is the general case and the
specifics still win where they exist.

The exam asks it directly, and the trap in the question is always the same. Two
routes match, one has a better metric or a lower administrative distance, and the
other has a longer prefix. **The longer prefix wins regardless.** Prefix length is
checked first, and the other tiebreaks only ever apply between routes of the same
length. Topic 23 has a capture where a route with a metric of 500 beats one with a
metric of 10 for exactly this reason.

The security consequence is worth carrying too. Because a longer prefix always
wins, announcing a more specific route than somebody else's is how traffic gets
diverted, and BGP hijacks work on precisely this arithmetic.

</details>

## Reading a table without guessing

The other thing worth having is the habit of asking the kernel rather than
working it out. Topic 02's panel introduced `ip route get`, and it is the same
tool at router scale: it runs the real lookup and prints the decision, including
which route matched and which interface the packet leaves by.

That matters more on a router than on a host because there are more candidates.
A host with one address and a default route has two possible answers. A router
with a dozen interfaces, static routes and a default has many, and reading them
off the screen and comparing prefixes in your head is where mistakes happen.

Two habits that go with it. Check the table on the router you think is wrong, and
then check it on the next one along, because the packet is only ever one hop into
its journey. And when a route looks right and traffic still fails, test the return
direction before touching anything.

## Prove it

You have this when you can predict the effect of a route before adding it.

```bash
./blog/scripts/netlab.sh --topo topologies/three-routers.sh -- \
  'ip -n r1 route; ip netns exec r1 ip route get 10.0.2.2'
```

The first command lists what r1 knows and the second asks what it would do with a
specific packet. Before running it, predict both: which three networks r1 has
connected routes for, and what `ip route get` says about a destination it has no
route to.

Then add the static route from the capture and run the second command again. The
value is in predicting first, because reading a routing table correctly is a skill
that only forms when you have been wrong about one.

## What trips people up

### 1. Reading "network unreachable" as the destination being down

It means the router found no matching route and did not send anything. A
destination that is down produces a timeout instead. The two point at completely
different causes.

### 2. Adding a route in one direction

A route is directional. Traffic reaching a destination whose router has no route
back produces silence at the sender that is indistinguishable from the destination
being off.

### 3. Thinking the default route is a special setting

It is `0.0.0.0/0`, an ordinary route with zero network bits, which matches
everything and therefore loses to everything more specific. Setting a default
gateway adds exactly that entry.

### 4. Expecting a better metric to beat a longer prefix

It does not. Prefix length is compared first and everything else only breaks ties
between routes of equal length.

### 5. Adding connected routes by hand

They already exist. Configuring an address creates one, and adding a duplicate
either fails or creates confusion for the next person reading the table.

### 6. Believing a router with a default route cannot have a routing problem

It can never report one, which is worse. Everything matches, so traffic is always
sent somewhere, and somewhere may be a hole.

## Work it through

A new subnet is added at a branch office, `192.168.40.0/24`, behind the branch
router. Head office can reach every other branch subnet and not this one. The
branch router can reach it perfectly. The WAN link is up.

The asymmetry between what the branch router can do and what head office can do
locates the fault immediately. The branch router reaches the new subnet because it
has a connected route: the interface has an address on it. Head office cannot,
because nobody has told it that the network exists.

So it is a missing route, and the question is where. Head office needs a route for
`192.168.40.0/24` pointing at the branch router. If the other branch subnets work,
there is already a route for each of those, which tells you two things: static
routing is being used, and somebody adds one entry per subnet by hand. Nobody
added this one.

Before adding it, look at how the existing ones are written, because there may be
a better answer than a fourth entry. If the branch's subnets are contiguous, one
summary route covers all of them and this problem stops recurring. If they are
scattered, that is a numbering decision worth revisiting, and topic 24 is about
making that possible.

Then check the return direction, because it is free to check and expensive to
miss. The branch router needs to know how to reach head office, and if the other
subnets work it probably has a default route pointing up the WAN link, in which
case the new subnet is covered without any further work.

The thing that would have prevented this is dynamic routing. A protocol running
between the two routers advertises the new subnet the moment its interface comes
up, in both directions, and nobody has to remember. That is the next topic, and
this fault is the argument for it.

## Try it

**Read your own table.** Run `ip route` on Linux, `netstat -rn` on macOS, or
`route print` on Windows. Find the connected route for your own network and the
default route, and confirm the default is written as a destination of zeros with
a mask of zeros.

**Ask for a decision.** Run `ip route get 8.8.8.8` and then `ip route get` for a
machine on your own network. The two answers differ in exactly one way: the local
one has no `via`, because there is no next hop to reach a neighbour.

**Break it deliberately.** On a spare machine or in the committed topology, delete
the default route and watch what changes. Local traffic keeps working and
everything else immediately reports network unreachable, which is the clearest
possible demonstration of what a default route is for.

## Check yourself

<details class="qa">
<summary>Where do connected routes come from, and why can you not remove them?</summary>

From addresses. Configuring `10.0.12.1/30` on an interface tells the kernel this
machine holds that address and that the whole `10.0.12.0/30` network is directly
reachable out of that interface.

They are marked `proto kernel` because the kernel created them rather than a
person, and `scope link` because the destinations are on the wire rather than
beyond a router.

Removing one means removing the address or downing the interface. The route is a
consequence of the configuration rather than a separate thing.

</details>

<details class="qa">
<summary>A ping returns "network unreachable" instantly. What does that rule out?</summary>

That anything was sent.

The router searched its table, found no route matching the destination, and
discarded the packet locally. Nothing went on the wire, so the destination, the
path and everything in between are all untested.

A destination that exists and is not answering produces a timeout instead. The
instant refusal is a local statement about the routing table.

</details>

<details class="qa">
<summary>Traffic reaches a server and the sender sees nothing come back. The route to the server is correct. What is likely?</summary>

A missing return route.

Routes are directional. The route added at the sender's end gets traffic there,
and the routers at the far end have their own tables, which may have no entry for
the sender's network. The reply is generated and then discarded on its way back.

From the sender it looks exactly like the destination being down, which is why the
test is to capture at the destination or test from both ends. A destination that is
receiving and replying, with nothing arriving back, is a return path problem.

</details>

<details class="qa">
<summary>A router has a default route and a route for 10.0.0.0/8. Where does a packet for 10.0.2.2 go, and where does one for 8.8.8.8 go?</summary>

The 10.0.2.2 packet takes the `10.0.0.0/8` route, because eight network bits is
more specific than the default's zero.

The 8.8.8.8 packet takes the default, because nothing else matches.

That is longest prefix match applied to the least specific possible entry.
`0.0.0.0/0` matches every address and loses to anything else that matches, which
is why it works as a last resort without needing to be treated as a special case.

</details>

<details class="qa">
<summary>Two routes match a destination. One is a /24 with a metric of 10 and one is a /32 with a metric of 500. Which wins?</summary>

The /32.

Prefix length is compared first and nothing overrides it. Metrics, administrative
distances and every other tiebreak only apply between routes of the same prefix
length.

This is worth having as a reflex because exam questions are built on it, and
because it is the arithmetic behind route hijacking: announcing a more specific
prefix than somebody else's diverts the traffic regardless of anything else.

</details>

<details class="qa">
<summary>Why can a router with a default route never report a routing failure?</summary>

Because the default matches everything, so the lookup always succeeds and the
packet is always sent somewhere.

That removes the useful error. Instead of an immediate network unreachable telling
you a route is missing, traffic leaves toward whatever the default points at, and
if that is wrong the failure appears somewhere else as a timeout.

Which is why a default route on a core router is a decision to think about rather
than a sensible thing to add everywhere.

</details>

## References

- [RFC 4632, Classless Inter-domain Routing (CIDR)](https://www.rfc-editor.org/rfc/rfc4632) - IETF, on prefixes and longest match. Accessed 2026-08-10.
- [RFC 1812, Requirements for IP Version 4 Routers](https://www.rfc-editor.org/rfc/rfc1812) - IETF, on what a router does with a packet it cannot route. Accessed 2026-08-10.
- [ip-route(8)](https://man7.org/linux/man-pages/man8/ip-route.8.html) - Linux man-pages project. Accessed 2026-08-10.

**Where the output came from.** The captured block was produced on
`blog/scripts/topologies/three-routers.sh` through `blog/scripts/netlab.sh`. The
three routers are separate namespaces with forwarding enabled and /30 links
between them, so the table shown is a real router's and the failure before the
static route is added is the kernel refusing to send rather than an illustration.

**If you also work on Linux.** [Network basics: addresses and routes](/learn/linux-plus/network-basics-addresses-and-routes)
on the Linux+ track reads the same table from a host's point of view, with more
attention to making a route persist across a reboot and less to what a router does
with one.
