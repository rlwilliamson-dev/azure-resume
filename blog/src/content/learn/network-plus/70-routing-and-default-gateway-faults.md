---
title: "Routing and default gateway faults"
description: "Local traffic is perfect and nothing leaves the building. How the error message tells you how far the packet got, why a missing route and a wrong gateway fail differently, and why traffic taking a path nobody expected is usually one line somebody left behind."
deck: "Local traffic is perfect and nothing leaves the building"
track: "network-plus"
level: "deep"
order: 710
objectives:
  - "Read an error message as a statement about how far the packet got"
  - "Tell a missing default route from a gateway that does not answer"
  - "Find the route actually being used rather than the one you expected"
  - "Recognise asymmetric routing and say when it becomes a fault"
  - "Compare a broken host against a working one on the same segment"
prerequisites: ["the-routing-table-and-static-routes"]
tags: ["network-plus", "networking", "troubleshooting", "routing"]
updated: 2026-08-19
draft: false
examObjectives:
  - exam: "n10-009"
    domain: "5.0"
    objective: "5.3"
sources:
  - title: "RFC 792, Internet Control Message Protocol"
    url: "https://www.rfc-editor.org/rfc/rfc792"
    publisher: "IETF"
    accessed: 2026-08-19
    tier: 1
  - title: "ip-route(8)"
    url: "https://man7.org/linux/man-pages/man8/ip-route.8.html"
    publisher: "man7.org"
    accessed: 2026-08-19
    tier: 1
  - title: "RFC 1812, Requirements for IP Version 4 Routers"
    url: "https://www.rfc-editor.org/rfc/rfc1812"
    publisher: "IETF"
    accessed: 2026-08-19
    tier: 1
symptoms:
  - symptom: "A host reaches its own subnet and nothing beyond it"
    anchor: "the-error-tells-you-how-far-it-got"
  - symptom: "Traffic takes a longer path than the routing table suggests"
    anchor: "the-route-being-used-is-not-the-one-you-read"
  - symptom: "A connection works until a firewall is added on one path"
    anchor: "asymmetric-routing-and-when-it-becomes-a-fault"
---

> **Before you read.** One machine cannot reach anything outside its own subnet.
> It pings its neighbours perfectly. It pings the printer down the hall. It cannot
> reach the file server, the internet, or anything with a different first three
> octets.
>
> The machine next to it, on the same switch, on the same subnet, is fine.
>
> **Everything local works and nothing leaves. Where do you look?**

Almost every routing fault a host experiences produces the same headline symptom:
local works, remote does not. What separates them is not the symptom, it is what
comes back, and the difference between silence and a specific error is worth more
than any amount of guessing.

## Some words you will need

<dl class="terms">
<dt>default route</dt>
<dd>Where a host or router sends anything it has no more specific route for. Written as a destination of 0.0.0.0/0, and printed as <code>default</code>.</dd>
<dt>next hop</dt>
<dd>The address of the device a route hands the packet to. It has to be on a subnet this machine is already on.</dd>
<dt>longest prefix match</dt>
<dd>The rule that decides between two routes covering the same address: the one with more bits in its mask wins, whatever else is true of it.</dd>
<dt>asymmetric routing</dt>
<dd>Traffic taking one path out and a different path back. Legal, common, and fatal in the presence of anything that keeps state.</dd>
<dt>neighbour entry</dt>
<dd>What a host has learned about an address on its own subnet. Marked incomplete when it asked and nothing answered.</dd>
</dl>

## What breaks without this

**The host gets rebuilt.** A machine that reaches nothing outside its subnet looks
comprehensively broken, and reimaging it takes an afternoon and fixes nothing when
the fault was one wrong address in one setting.

**Traffic quietly takes the wrong path for months.** Nothing fails, so nothing is
reported, and a link somebody sized for a fraction of the load carries all of it
until the day it does not.

**A firewall gets blamed for a routing problem.** Adding a stateful device to a
network with asymmetric paths breaks connections that worked a minute earlier, and
the device that broke them is not the device that caused it.

## The error tells you how far it got

Three faults produce "cannot reach anything outside my subnet" and they are
distinguishable from the host, in one command, without touching a switch.

<figure class="learn-figure">
<svg viewBox="0 0 720 205" role="img" aria-labelledby="gw-title" style="width:100%;height:auto;">
<title id="gw-title">Three ways traffic fails to leave a subnet, each failing at a different point along the path and each producing a different piece of evidence at the host</title>
<g fill="currentColor">
<text x="14" y="20" font-size="11">where it stopped is written in what came back</text>
<g fill="currentColor" fill-opacity="0.08" stroke="currentColor" stroke-opacity="0.7">
<rect x="24" y="42" width="52" height="26" rx="4"/>
<rect x="24" y="97" width="52" height="26" rx="4"/>
<rect x="24" y="152" width="52" height="26" rx="4"/>
<rect x="244" y="42" width="52" height="26" rx="4"/>
<rect x="244" y="97" width="52" height="26" rx="4"/>
<rect x="244" y="152" width="52" height="26" rx="4"/>
</g>
<g fill="currentColor" fill-opacity="0.06" stroke="currentColor" stroke-opacity="0.7">
<circle cx="164" cy="55" r="15"/>
<circle cx="164" cy="110" r="15"/>
<circle cx="164" cy="165" r="15"/>
</g>
<g stroke="currentColor" stroke-opacity="0.5" stroke-width="1.3" fill="none">
<path d="M 76 55 H 149"/>
<path d="M 179 55 H 244"/>
<path d="M 76 110 H 149"/>
<path d="M 179 110 H 244"/>
<path d="M 76 165 H 149"/>
<path d="M 179 165 H 244"/>
</g>
<g stroke="var(--red)" stroke-width="2" fill="none">
<path d="M 84 48 l 12 14 M 96 48 l -12 14"/>
<path d="M 138 103 l 12 14 M 150 103 l -12 14"/>
<path d="M 200 158 l 12 14 M 212 158 l -12 14"/>
</g>
<text x="50" y="59" text-anchor="middle" font-size="9">host</text>
<text x="50" y="114" text-anchor="middle" font-size="9">host</text>
<text x="50" y="169" text-anchor="middle" font-size="9">host</text>
<text x="164" y="59" text-anchor="middle" font-size="9">gw</text>
<text x="164" y="114" text-anchor="middle" font-size="9">gw</text>
<text x="164" y="169" text-anchor="middle" font-size="9">gw</text>
<text x="270" y="59" text-anchor="middle" font-size="9">rest</text>
<text x="270" y="114" text-anchor="middle" font-size="9">rest</text>
<text x="270" y="169" text-anchor="middle" font-size="9">rest</text>
<text x="320" y="49" font-size="10">no route on this host</text>
<text x="320" y="65" font-size="9.5" fill-opacity="0.85">network is unreachable, instantly, nothing sent</text>
<text x="320" y="104" font-size="10">gateway address nobody answers</text>
<text x="320" y="120" font-size="9.5" fill-opacity="0.85">silence, and the neighbour entry stays incomplete</text>
<text x="320" y="159" font-size="10">gateway fine, no route past it</text>
<text x="320" y="175" font-size="9.5" fill-opacity="0.85">the router answers: destination net unreachable</text>
</g></svg>
<figcaption>The three faults are indistinguishable by symptom and trivially distinguishable by evidence, which is why the first move is to read what came back rather than to start changing settings. Instant refusal means the packet never left, so the fault is the host's own table. Silence means the host sent an address resolution request into its own subnet and nothing replied, so the next hop is not there. A message from a router means the packet reached that router and got no further, so the host is correct and the fault is one hop away. Each answer eliminates the other two.</figcaption>
</figure>

Here are the first two, in the lab, on a host three hops away from the far end. The
topology is
[`trace-path.sh`](https://github.com/rlwilliamson-dev/azure-resume/blob/main/blog/scripts/topologies/trace-path.sh).

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology trace-path
# h1 reaches its own router and the far host three hops away
$ ip netns exec h1 ping -c1 -W1 10.0.1.1 2>&1 | grep "packet loss"
1 packets transmitted, 1 received, 0% packet loss, time 0ms
$ ip netns exec h1 ping -c1 -W1 10.0.4.2 2>&1 | grep "packet loss"
1 packets transmitted, 1 received, 0% packet loss, time 0ms
$ ip netns exec h1 ip route show
default via 10.0.1.1 dev h1-r1 
10.0.1.0/24 dev h1-r1 proto kernel scope link src 10.0.1.2 
# the default route is removed. nothing else about h1 changes
$ ip netns exec h1 ip route del default
$ ip netns exec h1 ip route show
10.0.1.0/24 dev h1-r1 proto kernel scope link src 10.0.1.2 
$ ip netns exec h1 ping -c1 -W1 10.0.1.1 2>&1 | grep "packet loss"
1 packets transmitted, 1 received, 0% packet loss, time 0ms
$ ip netns exec h1 ping -c1 -W1 10.0.4.2 2>&1 | tail -2
ping: connect: Network is unreachable
```

Two things in that block matter. The local ping keeps working the whole time, which
is what makes this fault look like a machine problem rather than a network one: the
subnet route is still there and still connected. And **the failure is instant and
worded**, `Network is unreachable`, because the host consulted its own table, found
nothing that covered the destination, and refused to send. That message never comes
from the network. It comes from the machine you typed on.

Now a default route that exists and points at nothing.

<details class="predict">
<summary>The default route is removed, and then replaced with an address on the right subnet that no device owns. Do those two faults fail the same way?</summary>

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology trace-path
# no default route at all. the host itself refuses to send
$ ip netns exec h1 ip route del default
$ ip netns exec h1 ping -c1 -W1 10.0.4.2 2>&1 | tail -2
ping: connect: Network is unreachable
# a default route pointing at an address on the right subnet that nobody has
$ ip netns exec h1 ip route add default via 10.0.1.9
$ ip netns exec h1 ip route show
default via 10.0.1.9 dev h1-r1 
10.0.1.0/24 dev h1-r1 proto kernel scope link src 10.0.1.2 
$ ip netns exec h1 ping -c2 -W1 10.0.4.2 2>&1 | tail -2
2 packets transmitted, 0 received, 100% packet loss, time 1055ms

# what the host tried, and never got an answer to
$ ip netns exec h1 ip neigh show
10.0.1.9 dev h1-r1 INCOMPLETE 
```

</details>

The same headline symptom and a completely different failure. No instant error: the
ping times out, because the host does have a route and is trying to use it. The last
line is the diagnosis. `10.0.1.9 dev h1-r1 INCOMPLETE` is the host saying it asked
its own subnet who owns that address and nothing replied, so it never got as far as
sending the packet.

**The pair is worth memorising because it is the fastest split available.** An
instant `unreachable` is a host with no route. A timeout with an incomplete
neighbour entry is a host with a route to a device that is not there. Neither
requires touching a switch, and between them they cover most of what "cannot reach
anything" turns out to be.

<details class="deeper">
<summary>If you already troubleshoot routing: comparing against a working host, and the routing policy nobody mentioned</summary>

The single most efficient technique for a host that cannot reach anything is not to
examine the broken host. It is to put its configuration next to a working one on the
same segment and read the differences.

That works because the two machines should be identical in the only three things
that matter here: the address and mask, the default route, and the resolver. One of
those differs, and the diff finds it in seconds where reading the broken host alone
means knowing what every value ought to be. The habit generalises beyond routing,
and it is why the two-host comparison keeps appearing in this block: a difference is
easier to see than an error.

What the comparison can miss is a routing policy, and it is worth knowing it exists
because it produces a fault that survives everything above. A host or a router can
be configured to choose a route by something other than the destination: the source
address, the incoming interface, a mark applied by a firewall rule. On Linux that is
multiple routing tables plus rules that select between them, and the reason it bites
is that the ordinary command to print the routing table prints one table. Traffic is
being steered by a rule you have not read, and everything you have read is correct.

The tell is that the route lookup and the observed behaviour disagree with no
explanation. When that happens, the question to ask is whether there are other
tables, and on any platform the answer to "which route is actually being used for
this destination" is a specific query rather than a printout. That query is in the
next section and it is the one to reach for whenever a table looks right and traffic
does not.

</details>

## The route being used is not the one you read

The third fault has no error message at all, because nothing fails. Traffic simply
goes somewhere other than where the table appears to send it.

Three routers in a triangle, so there are two ways from r1 to r2. Everything is
routed across the direct link, and then somebody adds a more specific route while
testing something and leaves it in. The topology is
[`three-routers.sh`](https://github.com/rlwilliamson-dev/azure-resume/blob/main/blog/scripts/topologies/three-routers.sh).

<details class="predict">
<summary>Somebody adds a more specific route while testing and leaves it behind. Does the table still look correct, and where does traffic actually go?</summary>

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology three-routers
# a complete routing table on all three routers. h1 reaches h2 across the direct
# r1 to r2 link, which is what everybody who reads the table expects
$ ip -n r1 route add 10.0.2.0/24 via 10.0.12.2
$ ip -n r1 route add 10.0.23.0/30 via 10.0.13.2
$ ip -n r2 route add 10.0.1.0/24 via 10.0.12.1
$ ip -n r2 route add 10.0.13.0/30 via 10.0.12.1
$ ip -n r3 route add 10.0.1.0/24 via 10.0.13.1
$ ip -n r3 route add 10.0.2.0/24 via 10.0.23.1
$ ip netns exec h1 traceroute -n -q1 -w2 -z 1 -m5 10.0.2.2
traceroute to 10.0.2.2 (10.0.2.2), 5 hops max, 60 byte packets
 1  10.0.1.1  0.048 ms
 2  10.0.12.2  0.031 ms
 3  10.0.2.2  0.025 ms
# somebody adds a more specific route while testing something, and leaves it in
$ ip -n r1 route add 10.0.2.0/25 via 10.0.13.2
$ ip netns exec h1 traceroute -n -q1 -w2 -z 1 -m5 10.0.2.2
traceroute to 10.0.2.2 (10.0.2.2), 5 hops max, 60 byte packets
 1  10.0.1.1  0.010 ms
 2  10.0.13.2  0.029 ms
 3  10.0.12.2  0.024 ms
 4  10.0.2.2  0.030 ms
# the route everybody expects is still in the table, and it is not the one used
$ ip -n r1 route show
10.0.1.0/24 dev r1-h1 proto kernel scope link src 10.0.1.1 
10.0.2.0/25 via 10.0.13.2 dev r1-r3 
10.0.2.0/24 via 10.0.12.2 dev r1-r2 
10.0.12.0/30 dev r1-r2 proto kernel scope link src 10.0.12.1 
10.0.13.0/30 dev r1-r3 proto kernel scope link src 10.0.13.1 
10.0.23.0/30 via 10.0.13.2 dev r1-r3 
$ ip -n r1 route get 10.0.2.2
10.0.2.2 via 10.0.13.2 dev r1-r3 src 10.0.13.1 uid 0 
    cache 
```

</details>

The path went from three hops to four and every packet between those two hosts now
crosses a third router. Nothing is broken. Nothing logs anything. Throughput drops,
latency rises, and a link that was carrying nothing is carrying everything.

Look at the table. **Both routes are in it**, `10.0.2.0/25 via 10.0.13.2` and
`10.0.2.0/24 via 10.0.12.2`, and reading it top to bottom is not how the decision is
made. The destination `10.0.2.2` falls inside both, and longest prefix match takes
the one with more bits, which is the /25 somebody left behind. Topic 23 covered that
rule; this is the fault it produces.

Which is why the last command in the block matters more than the table above it.
`route get` asks the machine to run the decision rather than to print the inputs,
and it answers with the route it will actually use. **A table is a set of candidates
and a lookup is the answer.** On any platform, when a table looks right and traffic
disagrees, the lookup is the command that settles it.

<details class="deeper">
<summary>If you already hunt these: how a temporary route becomes permanent</summary>

A leftover specific route is the fault above, and the interesting question is why they
survive, because nobody intends to leave one.

They survive because they work. A route added to test a theory or to steer traffic during an
incident does its job, the incident closes, and nothing about the network subsequently
complains. There is no expiry, no log entry a year later, and no monitoring check that
notices a route exists which nobody can justify. It is invisible in exactly the way a
misconfiguration that breaks something is not.

Two habits close it. The first is to record temporary changes as temporary at the moment of
making them, in the change record, with the removal as its own item rather than a note. The
second is to compare the running routing configuration against source, which is topic 60's
drift check applied to routing, and which finds every static route nobody declared.

The third, for estates without that tooling, is a periodic read of the static routes on the
core devices with somebody asking what each is for. It is dull and it reliably finds
several, and each one found is a path that traffic has been taking for reasons nobody
remembers.

</details>

## Asymmetric routing, and when it becomes a fault

Traffic does not have to take the same path in both directions, and frequently does
not. That is not automatically a problem, which is exactly why it goes unnoticed
until something makes it one.

Here the routing is written deliberately one way round: out across the direct link,
back the long way through the third router.

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology three-routers
# every router knows every prefix. the only asymmetry is deliberate: r1 sends to
# h2 across the direct link and r2 sends the answers back the long way, via r3
$ ip -n r1 route add 10.0.2.0/24 via 10.0.12.2
$ ip -n r1 route add 10.0.23.0/30 via 10.0.13.2
$ ip -n r2 route add 10.0.1.0/24 via 10.0.23.2
$ ip -n r3 route add 10.0.1.0/24 via 10.0.13.1
$ ip -n r3 route add 10.0.2.0/24 via 10.0.23.1
$ ip netns exec h1 ping -c1 -W2 10.0.2.2 2>&1 | grep "packet loss"
1 packets transmitted, 1 received, 0% packet loss, time 0ms
# the path out
$ ip netns exec h1 traceroute -n -q1 -w2 -z 1 -m5 10.0.2.2
traceroute to 10.0.2.2 (10.0.2.2), 5 hops max, 60 byte packets
 1  10.0.1.1  0.015 ms
 2  10.0.23.1  0.035 ms
 3  10.0.2.2  0.027 ms
# and the path back, asked from the other end
$ ip netns exec h2 traceroute -n -q1 -w2 -z 1 -m5 10.0.1.2
traceroute to 10.0.1.2 (10.0.1.2), 5 hops max, 60 byte packets
 1  10.0.2.1  0.009 ms
 2  10.0.23.2  0.024 ms
 3  10.0.12.1  0.037 ms
 4  10.0.1.2  0.038 ms
# r3 is given a stateful rule: replies to flows it has already seen are fine and
# anything else is not. no route changes
$ ip netns exec r3 nft add table inet fw
$ ip netns exec r3 nft add chain inet fw forward { type filter hook forward priority 0 \; policy drop \; }
$ ip netns exec r3 nft add rule inet fw forward ct state established,related counter accept
$ ip netns exec h1 ping -c2 -W2 10.0.2.2 2>&1 | grep "packet loss"
2 packets transmitted, 0 received, 100% packet loss, time 1012ms
```

Read the two traceroutes. Out is three hops and back is four, through a router that
is nowhere in the outbound path, and the ping at the top succeeds without complaint.
That is asymmetric routing working exactly as designed.

Then a stateful rule is added on the router that only ever sees the return traffic,
and everything stops. The rule is not wrong: it accepts replies to connections it
has seen and drops everything else, which is what a firewall is for. The problem is
that the connection's outbound half never crossed that router, so from its point of
view the replies are unsolicited traffic arriving from nowhere, and it drops them
correctly.

**That is the whole reason asymmetric routing matters.** On its own it costs nothing
but a confusing traceroute. Add anything that keeps state, a firewall, a load
balancer, a device doing address translation, an intrusion prevention sensor, and
traffic that worked for years stops on the day the device is installed. The device
gets blamed, is entirely correct, and the actual fault is a routing design that
predates it by a decade.

The diagnostic signature is worth naming: **a connection that fails only in one
direction, or only after a device was added, with clean routing tables everywhere.**
The test is to trace from both ends, which the block above does, because a
one-directional trace cannot show you an asymmetry by definition.

<details class="deeper">
<summary>If you already design networks: the second thing asymmetry breaks, and why the traceroute looked odd</summary>

Stateful inspection is the famous casualty of asymmetric routing and it is not the
only one. Reverse path filtering is the other, and it fails more quietly.

A router doing reverse path filtering checks the source address of an arriving
packet and asks whether it would send traffic back to that address out of the
interface it arrived on. In strict mode, anything that fails the check is dropped,
which on an asymmetric path is normal traffic. Loose mode only asks whether any
route to that source exists at all, which is gentler and still drops traffic whose
source address the router has no route to.

The lab hit exactly that while it was being built. An earlier version of the
asymmetric capture had one router with no route to the subnet between the other two,
and a hop went missing from the traceroute for that reason alone: the time-exceeded
message came back with a source address the router could not route to, so it was
discarded on the way. Adding the missing route made the hop appear. The lesson is
one that shows up on real networks constantly: **an incomplete routing table can
break diagnostic messages while leaving the traffic they describe working**, so a
strange traceroute is sometimes a statement about the error path rather than the
data path.

The other thing that came out of building it is worth carrying. In the outbound
trace, the middle hop answers from the address on its link to the third router, not
from the address the packet arrived on. A router sources its own messages from the
interface it would use to reach you, and on an asymmetric path that is a different
interface from the one you sent to. So a hop showing an address you did not expect is
not necessarily a wrong path. It can be the same router answering from its other
face.

</details>

## Prove it

You have this when three commands answer the three questions in order.

```bash
# does this machine have a route for that destination, and which one wins
ip route get <destination>

# is the next hop actually there
ip neigh show

# and where does traffic really go, from both ends
traceroute -n <destination>
```

The order matters. `route get` runs the decision rather than printing the table, so
it answers what will happen rather than what might. The neighbour table says whether
the next hop that route names is a real device or an address nobody owns. And a
traceroute from each end is the only way to see an asymmetry, since one direction
cannot show you that the other differs.

Then read the failure, because the failure is evidence. `Network is unreachable`
arrives instantly and means nothing was sent. A timeout means something was sent and
nothing came back. A message naming a router means the packet reached that router,
which has just told you your host and the path to it are fine.

## Across platforms

Every platform can answer the same three questions and they spell them differently.
The exam names `route` and `tracert` on Windows, which are the older forms and the
ones still shipped.

| Task | Linux | Windows | macOS |
| --- | --- | --- | --- |
| Show the routing table | `ip route show` | `route print`, `Get-NetRoute` | `netstat -rn` |
| Ask which route wins | `ip route get <dest>` | `Find-NetRoute -RemoteIPAddress <dest>` | `route -n get <dest>` |
| Read the neighbour table | `ip neigh show` | `arp -a`, `Get-NetNeighbor` | `arp -an` |
| Trace the path | `traceroute -n` | `tracert -d` | `traceroute -n` |

Two things about that table are worth carrying rather than memorising. The middle row
is the one people do not know exists on their own platform, and it is the one that
answers the question that matters. And the trace tools differ in the protocol they
probe with, which topic 62 covered: Windows `tracert` sends ICMP echo, Linux and macOS
`traceroute` send UDP by default, so a path can trace on one platform and time out on
another with nothing wrong with it.

## What trips people up

### 1. Reading the symptom instead of the message

Local works and remote fails is the same symptom for at least three different faults.
What came back separates them, and it takes one command to look.

### 2. Treating an instant refusal as a network problem

`Network is unreachable` is the host talking, not the network. Nothing was transmitted.
No amount of investigating switches will change it.

### 3. Ignoring an incomplete neighbour entry

A host that timed out with an incomplete entry for its own gateway has told you
precisely what is wrong: the address in its default route belongs to nobody on that
subnet.

### 4. Reading a routing table instead of running the lookup

A table is a list of candidates and longest prefix match decides between them, so a
route you can see is not necessarily the route in use. The lookup command runs the
decision for you.

### 5. Leaving a more specific route behind

A route added while testing outranks the general one permanently and silently, because
nothing about it fails. Traffic just goes the wrong way until somebody measures a link.

### 6. Blaming the new firewall

A stateful device installed on a network with asymmetric paths breaks connections it
never saw the other half of. The device is behaving correctly and the routing predates
it.

## Work it through

The machine that reaches nothing outside its subnet.

Start by reading the failure rather than the symptom, because there are three
candidates and the failure names one of them. Ping something remote and watch what
comes back. Instant `unreachable` means the host has no route and never sent anything,
so the fault is on the machine and you are already finished looking elsewhere. A
timeout means it tried, so ask the neighbour table whether the gateway it tried to
reach answered: an incomplete entry means the gateway address is wrong. And a message
from a router means the packet got that far, which clears the host entirely and moves
the whole investigation one hop away.

Then, if it is the host, compare rather than inspect. The machine next to it works and
is on the same segment, so put the two side by side: address and mask, default route,
resolver. One of those three differs and the difference is the fault. That is faster
than knowing what each value should be, and it is right more often, because the working
host is the specification.

Then, if the host is correct and the router has answered, the question changes from
whether traffic can leave to where it goes. Ask the router which route it will use for
that destination rather than reading its table, because a more specific route hides
inside a table that looks correct, and the lookup is what exposes it.

And if everything is reachable but something intermittent or one-directional is
happening, trace from both ends before doing anything else. Two different paths is not
a fault by itself and it is the precondition for one, so finding it early is what stops
the next firewall change from becoming an outage nobody can explain.

## Try it

**Break your own default route, carefully.** On a machine you can restore, remove the
default route and ping something remote, then put it back and point it at an address on
your subnet that nothing owns. The two failures look nothing alike and doing it once
makes the difference permanent.

**Run the lookup on a destination you use daily.** Whichever platform you are on, ask
which route wins for an address rather than printing the table. Most people have never
run that command and it is the one that answers the question.

**Trace from both ends of something.** Any two machines you can reach. If the paths
differ, you have found asymmetric routing on a live network, which is far more common
than most people expect and is worth knowing about before somebody installs a firewall.

## Check yourself

<details class="qa">
<summary>A host reaches its own subnet and gets an instant "network is unreachable" for anything else. What is wrong?</summary>

It has no route covering that destination, almost always a missing default route. The
error is instant and it comes from the host itself: it consulted its own table, found
nothing, and refused to transmit.

That single fact eliminates the entire network. No packet left the machine, so no
switch, router, cable or firewall can be responsible. The subnet route is still there,
which is why local traffic keeps working and the fault looks like a broken machine.

</details>

<details class="qa">
<summary>Same symptom, but the pings time out instead of failing instantly. What changed?</summary>

The host has a route now, and the next hop it names is not there. It tried, which is
why there is a timeout rather than a refusal.

The evidence is in the neighbour table: an entry for the gateway address marked
incomplete means the host asked its own subnet who owns that address and nothing
answered. The default route points at an address on the right subnet that no device
has, which is what a typo in a gateway setting looks like from the inside.

</details>

<details class="qa">
<summary>The routing table clearly sends traffic via one router and the traceroute shows it going via another. Who is lying?</summary>

Neither. The table holds candidates and longest prefix match decides between them, so a
more specific route elsewhere in the table is winning over the one you read. In the lab
a /25 added during testing outranked the /24 everybody expected, permanently and
silently.

The way to settle it is to run the lookup rather than read the table: ask the machine
which route it would use for that exact destination and it will tell you. That is
`ip route get` on Linux, `Find-NetRoute` on Windows, and `route -n get` on macOS.

</details>

<details class="qa">
<summary>Why is asymmetric routing not a fault, and when does it become one?</summary>

On its own it costs nothing. Traffic taking one path out and another back is legal,
common, and produces a working connection with a confusing traceroute.

It becomes a fault the moment anything on either path keeps state. A firewall, a load
balancer, a device doing address translation or an intrusion prevention sensor sees only
half of each connection, so the half it does see arrives unsolicited and gets dropped as
it should. The device is correct, the traffic worked yesterday, and the actual cause is a
routing design that was there long before the device was.

</details>

<details class="qa">
<summary>Why should the second thing you check be a working host rather than the broken one?</summary>

Because a difference is easier to find than an error. Reading the broken host alone
requires knowing what every value ought to be. Putting it next to a machine on the same
segment that works reduces the job to spotting which of three things differs: the address
and mask, the default route, or the resolver.

The working host is the specification, and it is already on your network. This is the same
move that makes counters useful at both ends of a link and traceroutes useful from both
ends of a path.

</details>

## References

- [RFC 792](https://www.rfc-editor.org/rfc/rfc792) - IETF, which defines the destination unreachable messages a router sends and the codes that distinguish network from host. Free. Accessed 2026-08-19.
- [RFC 1812](https://www.rfc-editor.org/rfc/rfc1812) - IETF, requirements for IPv4 routers, including when a router must generate an unreachable rather than discard silently. Free. Accessed 2026-08-19.
- [ip-route(8)](https://man7.org/linux/man-pages/man8/ip-route.8.html) - man7.org, for `route get`, which runs the lookup instead of printing the table. Free. Accessed 2026-08-19.

**Where the numbers came from.** Four captured blocks through `netlab.sh` on the kernel in
each header. The two gateway faults are on
[`trace-path.sh`](https://github.com/rlwilliamson-dev/azure-resume/blob/main/blog/scripts/topologies/trace-path.sh)
and the route selection and asymmetry are on
[`three-routers.sh`](https://github.com/rlwilliamson-dev/azure-resume/blob/main/blog/scripts/topologies/three-routers.sh),
whose package list gained nftables so the stateful rule in the last block could be applied.
Every route and every fault is created in the captured commands, so nothing is hidden in the
topology.

**If you also work on Linux systems.** [DNS and routing problems](/learn/linux-plus/dns-and-routing-problems)
covers the same ground from a single host's point of view, where the question is usually
whether this machine can reach a service. This topic is the network-side version, where the
question is which path the traffic took and whether both directions agree.
