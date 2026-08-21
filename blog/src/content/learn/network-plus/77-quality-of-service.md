---
title: "Quality of service"
description: "The call breaks up every afternoon and the link is not full for the other twenty-three hours. What a marking is, where the queue that acts on it lives, the difference between shaping and policing, and why your marks stop meaning anything the moment traffic leaves your estate."
deck: "The calls break up at four, and the link is fine at five"
track: "network-plus"
level: "working"
order: 780
beyondExam: true
objectives:
  - "Say why a quality of service policy does nothing on a link that is not full"
  - "Read a DSCP value out of a packet capture and say what it names"
  - "Name the three steps a policy is made of and say where each one happens"
  - "Tell shaping from policing and say which one costs delay and which costs packets"
  - "Explain what a trust boundary is and why the marks arriving from a host are not evidence"
  - "Say what happens to your markings when the traffic reaches somebody else's network"
prerequisites: ["latency-jitter-and-packet-loss", "bandwidth-congestion-and-bottlenecks"]
tags: ["network-plus", "networking", "performance", "beyond-the-exam"]
updated: 2026-08-20
draft: false
examObjectives: []
sources:
  - title: "RFC 2474, Definition of the Differentiated Services Field (DS Field) in the IPv4 and IPv6 Headers"
    url: "https://www.rfc-editor.org/rfc/rfc2474"
    publisher: "IETF"
    accessed: 2026-08-20
    tier: 1
  - title: "RFC 2475, An Architecture for Differentiated Services"
    url: "https://www.rfc-editor.org/rfc/rfc2475"
    publisher: "IETF"
    accessed: 2026-08-20
    tier: 1
  - title: "RFC 3246, An Expedited Forwarding PHB (Per-Hop Behavior)"
    url: "https://www.rfc-editor.org/rfc/rfc3246"
    publisher: "IETF"
    accessed: 2026-08-20
    tier: 1
  - title: "RFC 2597, Assured Forwarding PHB Group"
    url: "https://www.rfc-editor.org/rfc/rfc2597"
    publisher: "IETF"
    accessed: 2026-08-20
    tier: 1
  - title: "RFC 4594, Configuration Guidelines for DiffServ Service Classes"
    url: "https://www.rfc-editor.org/rfc/rfc4594"
    publisher: "IETF"
    accessed: 2026-08-20
    tier: 1
  - title: "RFC 3168, The Addition of Explicit Congestion Notification (ECN) to IP"
    url: "https://www.rfc-editor.org/rfc/rfc3168"
    publisher: "IETF"
    accessed: 2026-08-20
    tier: 1
  - title: "RFC 8290, The Flow Queue CoDel Packet Scheduler and Active Queue Management Algorithm"
    url: "https://www.rfc-editor.org/rfc/rfc8290"
    publisher: "IETF"
    accessed: 2026-08-20
    tier: 1
  - title: "ITU-T G.114, One-way transmission time"
    url: "https://www.itu.int/rec/T-REC-G.114-200305-I/en"
    publisher: "ITU-T"
    accessed: 2026-08-20
    tier: 1
  - title: "tc-htb(8)"
    url: "https://man7.org/linux/man-pages/man8/tc-htb.8.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-20
    tier: 1
symptoms:
  - symptom: "Voice calls break up at the same time every day and the link is fine outside that window"
    anchor: "nothing-happens-until-the-link-is-full"
  - symptom: "Quality of service was enabled and nothing measurably changed"
    anchor: "where-the-queue-actually-forms"
  - symptom: "Markings applied on the internal network do not survive the internet"
    anchor: "the-marks-stop-at-the-edge-of-what-you-own"
---

> **Before you read.** A company's calls break up between four and five in the
> afternoon. Somebody enables quality of service on the switches, the calls still
> break up, and the graphs show the internal links running at eleven per cent.
>
> **What has gone wrong, and where is the queue that is actually hurting them?**

This topic is not on the Network+ exam. The objectives mention quality of service
once, as a function rather than a device, and none of the mechanisms below appear
anywhere in the document. It is here because the three troubleshooting topics
before it teach a reader to measure latency, jitter and loss, and then stop at the
point where somebody asks what to do about it.

### Some words you will need

<dl class="terms">
<dt>DS field</dt>
<dd>The byte in the IP header that carries the marking. It used to be called the type of service byte.</dd>
<dt>DSCP</dt>
<dd>Differentiated services code point. The top six bits of that byte, giving 64 possible values.</dd>
<dt>EF</dt>
<dd>Expedited forwarding. The code point conventionally used for voice, recommended by RFC 3246 as 101110, which is 46.</dd>
<dt>classification</dt>
<dd>Deciding which category a packet belongs to, by port, address, protocol or existing marking.</dd>
<dt>queue</dt>
<dd>Where packets wait when they arrive faster than the interface can send them.</dd>
<dt>shaping</dt>
<dd>Holding traffic back to a rate by buffering it, so the excess is delayed.</dd>
<dt>policing</dt>
<dd>Holding traffic to a rate by discarding or re-marking the excess, so it is not delayed because it is gone.</dd>
<dt>trust boundary</dt>
<dd>The point where you stop believing the marking a packet arrived with and set it yourself.</dd>
</dl>

## What breaks without this

**A call is unusable and every link looks healthy.** Averages are five minute
numbers and a queue that ruins a call is a two second event, so the graph that
would show the problem does not exist at the resolution anybody is looking at.

**Money gets spent on capacity that was never the problem.** Doubling a link
that is eleven per cent used buys nothing, and it is the most common purchase
made in response to a complaint about call quality.

**A policy is configured and quietly does nothing.** Configuration exists,
somebody ticked the box in the change record, and no packet on the network was
ever treated differently because of it.

## Nothing happens until the link is full

Everything in this topic is dormant on a link with spare capacity. If packets
leave the interface as fast as they arrive there is no queue, nothing is waiting,
and there is no order to change. Configure the most careful policy you like and
you can measure exactly no difference, because a decision about who goes first
only exists when somebody has to go second.

That single sentence resolves most arguments about whether a policy is working.
It also explains the scenario at the top of the page. Eleven per cent on the
internal links is a real number and it is measured in the wrong place: the queue
is at whatever interface is narrowest along the path, which for a call leaving the
building is almost always the internet circuit, and for a call inside the building
is almost always the wireless.

<figure class="learn-figure">
<svg viewBox="0 0 720 214" role="img" aria-labelledby="qos-where-title" style="width:100%;height:auto;">
<title id="qos-where-title">A fast link feeding a slow one through a router, with the queue drawn at the router's outbound interface, which is the only point on the path where packets wait</title>
<g fill="currentColor">
<text x="14" y="24" font-size="11">the only place a priority decision can be taken</text>
<rect x="24" y="76" width="86" height="38" rx="3" fill="currentColor" fill-opacity="0.08" stroke="currentColor" stroke-opacity="0.5"/>
<text x="67" y="100" text-anchor="middle" font-size="10.5">h1</text>
<rect x="306" y="76" width="86" height="38" rx="3" fill="currentColor" fill-opacity="0.08" stroke="currentColor" stroke-opacity="0.5"/>
<text x="349" y="100" text-anchor="middle" font-size="10.5">r1</text>
<rect x="598" y="76" width="86" height="38" rx="3" fill="currentColor" fill-opacity="0.08" stroke="currentColor" stroke-opacity="0.5"/>
<text x="641" y="100" text-anchor="middle" font-size="10.5">h2</text>
<line x1="110" y1="95" x2="306" y2="95" stroke="currentColor" stroke-opacity="0.3" stroke-width="9"/>
<line x1="392" y1="95" x2="598" y2="95" stroke="currentColor" stroke-opacity="0.55" stroke-width="1.6"/>
<text x="208" y="62" text-anchor="middle" font-size="10">1 gigabit</text>
<text x="495" y="62" text-anchor="middle" font-size="10">2 megabits</text>
<text x="208" y="140" text-anchor="middle" font-size="10" fill-opacity="0.75">no queue</text>
<rect x="398" y="126" width="11" height="15" rx="1.5" fill="var(--accent)" fill-opacity="0.35" stroke="var(--accent)" stroke-width="1.2"/>
<rect x="413" y="126" width="11" height="15" rx="1.5" fill="var(--accent)" fill-opacity="0.35" stroke="var(--accent)" stroke-width="1.2"/>
<rect x="428" y="126" width="11" height="15" rx="1.5" fill="var(--accent)" fill-opacity="0.35" stroke="var(--accent)" stroke-width="1.2"/>
<rect x="443" y="126" width="11" height="15" rx="1.5" fill="var(--accent)" fill-opacity="0.35" stroke="var(--accent)" stroke-width="1.2"/>
<rect x="458" y="126" width="11" height="15" rx="1.5" fill="var(--accent)" fill-opacity="0.35" stroke="var(--accent)" stroke-width="1.2"/>
<rect x="473" y="126" width="11" height="15" rx="1.5" fill="var(--accent)" fill-opacity="0.35" stroke="var(--accent)" stroke-width="1.2"/>
<text x="398" y="166" font-size="10" fill="var(--accent)">packets waiting for r1eth1</text>
</g>
</svg>
<figcaption>A queue forms where a fast input meets a slow output, and nowhere else. Both hosts and the inbound side of r1 can be configured to their owner's heart's content without a single packet being reordered, because on those interfaces nothing is ever waiting. This is why a policy written on the switches makes no difference to a call crossing an internet circuit, and why the first question about any quality of service problem is which interface is the narrow one.</figcaption>
</figure>

<details class="deeper">
<summary>If you already run links near capacity: why the five minute average hides exactly the traffic this is for</summary>

Interface counters are polled, and the number a monitoring system stores is bytes
divided by the polling interval. At five minutes, a link that was completely full
for twelve seconds and idle for the rest averages four per cent.

Twelve seconds of full is a ruined call. Nothing in the graph shows it, and the
graph is what gets shown to the person deciding whether to spend money, which is
how a capacity problem that is real at the second scale gets classified as
imaginary.

Three things get you out of it. Poll faster on the links that matter, which is
cheap and buys resolution rather than history. Read the queue counters rather than
the throughput counters, because drops and overlimits are events rather than
averages and a single drop is recorded as a drop no matter how briefly the link
was full. And measure with traffic rather than counters: a small constant stream
of packets across the path, reporting its own delay and variation, sees what a
call sees. Topic 76 is the measurement half of this and it is worth reading first.

The general form is worth keeping. Any metric that is an average over a window
longer than the event you care about will hide it, and this is the same reason
that ninety-fifth percentile billing and a satisfied user are unrelated
quantities.

</details>

## Six bits in a header that nobody has to respect

The marking lives in one byte of the IP header. RFC 2474 redefined that byte as
the differentiated services field: the top six bits are the code point, and RFC
3168 took the bottom two for congestion notification, which is a separate
mechanism this topic does not need.

Here is the same host sending two packets across the same link, one marked and one
not, read off the wire by the router in the middle.

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology congested-link
# mark one packet and leave the next alone, then read the link they both crossed
$ ip netns exec r1 timeout 8 tcpdump -n -v -i r1eth1 "icmp and src 10.0.1.2" > /tmp/cap.txt 2>/dev/null &
$ sleep 1
$ ip netns exec h1 ping -c 1 10.0.2.2 > /dev/null
$ ip netns exec h1 ping -c 1 -Q 0xb8 10.0.2.2 > /dev/null
$ sleep 7
$ sed "s/^[0-9:.]* //" /tmp/cap.txt
IP (tos 0x0, ttl 63, id 26768, offset 0, flags [DF], proto ICMP (1), length 84)
   10.0.1.2 > 10.0.2.2: ICMP echo request, id 56, seq 1, length 64
IP (tos 0xb8, ttl 63, id 26771, offset 0, flags [DF], proto ICMP (1), length 84)
   10.0.1.2 > 10.0.2.2: ICMP echo request, id 58, seq 1, length 64
```

The second packet says `tos 0xb8`. That is the whole marking, and the arithmetic
to read it is the only arithmetic in this topic.

<figure class="learn-figure">
<svg viewBox="0 0 720 190" role="img" aria-labelledby="qos-ds-title" style="width:100%;height:auto;">
<title id="qos-ds-title">The byte 0xb8 split into its six code point bits, which read as 46, and the two congestion notification bits below it</title>
<g fill="currentColor">
<text x="14" y="24" font-size="11">reading tos 0xb8 out of a capture</text>
<text x="14" y="104" font-size="11">0xb8</text>
<text x="268" y="54" text-anchor="middle" font-size="10">DSCP, six bits</text>
<text x="520" y="54" text-anchor="middle" font-size="10">ECN, two bits</text>
<path d="M100 70 L100 64 L436 64 L436 70" fill="none" stroke="var(--accent)" stroke-opacity="0.8" stroke-width="1.4"/>
<path d="M436 70 L436 64 L548 64 L548 70" fill="none" stroke="currentColor" stroke-opacity="0.45" stroke-width="1.4"/>
<rect x="100" y="76" width="56" height="44" rx="2" fill="var(--accent)" fill-opacity="0.16" stroke="var(--accent)" stroke-width="1.4"/>
<rect x="156" y="76" width="56" height="44" rx="2" fill="var(--accent)" fill-opacity="0.16" stroke="var(--accent)" stroke-width="1.4"/>
<rect x="212" y="76" width="56" height="44" rx="2" fill="var(--accent)" fill-opacity="0.16" stroke="var(--accent)" stroke-width="1.4"/>
<rect x="268" y="76" width="56" height="44" rx="2" fill="var(--accent)" fill-opacity="0.16" stroke="var(--accent)" stroke-width="1.4"/>
<rect x="324" y="76" width="56" height="44" rx="2" fill="var(--accent)" fill-opacity="0.16" stroke="var(--accent)" stroke-width="1.4"/>
<rect x="380" y="76" width="56" height="44" rx="2" fill="var(--accent)" fill-opacity="0.16" stroke="var(--accent)" stroke-width="1.4"/>
<rect x="436" y="76" width="56" height="44" rx="2" fill="currentColor" fill-opacity="0.06" stroke="currentColor" stroke-opacity="0.4"/>
<rect x="492" y="76" width="56" height="44" rx="2" fill="currentColor" fill-opacity="0.06" stroke="currentColor" stroke-opacity="0.4"/>
<text x="128" y="104" text-anchor="middle" font-size="12">1</text>
<text x="184" y="104" text-anchor="middle" font-size="12">0</text>
<text x="240" y="104" text-anchor="middle" font-size="12">1</text>
<text x="296" y="104" text-anchor="middle" font-size="12">1</text>
<text x="352" y="104" text-anchor="middle" font-size="12">1</text>
<text x="408" y="104" text-anchor="middle" font-size="12">0</text>
<text x="464" y="104" text-anchor="middle" font-size="12">0</text>
<text x="520" y="104" text-anchor="middle" font-size="12">0</text>
<text x="100" y="148" font-size="10.5">101110 = 46 = EF</text>
<text x="436" y="148" font-size="10.5" fill-opacity="0.7">not set</text>
</g>
</svg>
<figcaption>One byte, two unrelated mechanisms. A capture prints the whole byte, so every code point looks four times larger than the number people quote: 46 appears as 0xb8 because it has been shifted up two places to make room for the congestion bits underneath. Dividing by four, or shifting right by two, converts what tcpdump shows into what a configuration guide calls it.</figcaption>
</figure>

The named values are conventions rather than rules. RFC 3246 recommends 101110 for
expedited forwarding and RFC 2597 defines twelve assured forwarding values with a
drop preference built into each, and RFC 4594 collects them into a set of service
classes with a suggested use for each. None of that obliges any device to do
anything. A code point is a number in a field, and it changes a packet's fate only
where somebody has configured a queue to read it.

<details class="deeper">
<summary>If you already configure this: what a per-hop behaviour is, and why the standards define behaviour rather than treatment</summary>

The specifications are careful about a distinction that gets lost in practice. They
define per-hop behaviours, meaning the externally observable forwarding treatment a
node applies to packets carrying a given code point. They deliberately do not define
how a device implements one.

That is why two vendors can both claim to support expedited forwarding and produce
different results with the same configuration. One implements it as a strict
priority queue that will starve everything else, the other as a priority queue with
a rate limiter on it so that it cannot. Both satisfy the definition, and the second
is what RFC 3246 has in mind when it discusses the need to bound the EF rate.

The practical consequence is that a policy is not portable. The code points travel
between vendors because they are a number in a header. The behaviour does not,
because it is an implementation of a description, and the description was written
loosely on purpose so that implementations could differ.

This is also the honest answer to why so many quality of service designs are
described as working when nobody has measured them. The configuration is the same
words on both devices. Nothing about the words guarantees the same queue.

</details>

## What a full queue does to a call

The demonstration below is a two megabit link with one sender that will not stop.
Everything leaves by the same interface and there is one queue for all of it,
which is the default state of any interface anybody has not configured.

<details class="predict">
<summary>A probe from a second host was answered in a twentieth of a millisecond a moment ago. The link is now full. What does the same probe read?</summary>

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology congested-link
# one queue for everything, on a link narrow enough to fill
$ ip netns exec r1 tc qdisc replace dev r1eth1 root tbf rate 2mbit burst 32kb latency 300ms

# h3 starts sending and does not wait for anyone
$ ip netns exec h3 ping -f -s 1400 -l 200 -w 12 10.0.2.2 > /dev/null 2>&1 &
$ sleep 2

# what a voice call from h1 would be experiencing right now
$ ip netns exec h1 ping -c 5 -i 0.5 -Q 0xb8 10.0.2.2 | tail -2
5 packets transmitted, 5 received, 0% packet loss, time 2001ms
rtt min/avg/max/mdev = 422.135/424.036/426.008/1.490 ms
$ sleep 11

# what the interface did with all of it
$ ip netns exec r1 tc -s qdisc show dev r1eth1
qdisc tbf 8025: root refcnt 6 rate 2Mbit burst 32Kb lat 300ms 
 Sent 3138932 bytes 2190 pkt (dropped 3528, overlimits 10000 requeues 0) 
 backlog 0b 0p requeues 0
```

</details>

Four hundred and twenty four milliseconds, on a link where the same measurement
was a twentieth of a millisecond a moment earlier. Three and a half thousand
packets discarded. Nothing is broken, no device is faulty, and the marking on
those probe packets was set correctly: the queue was simply full and the marking
had nothing to act on it.

That number is worth holding on to. ITU-T G.114 puts the planning limit for a
voice path at 150 milliseconds one way for most applications, and calls anything
past 400 milliseconds unacceptable for general planning. This is 424 milliseconds
of round trip, so a little over 200 each way, which lands in the band the
recommendation says only works when everyone involved understands what they are
accepting.

## Giving the marked traffic somewhere to go

The fix is not a bigger buffer. It is a second queue and a rule that puts some
packets in it.

<details class="predict">
<summary>Same link, same flood, same two megabits. One queue becomes two and the probe is marked. How far apart can the marked and unmarked probes be?</summary>

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology congested-link
# same link, same two megabits, but now with somewhere for marked traffic to go
$ ip netns exec r1 tc qdisc replace dev r1eth1 root handle 1: htb default 20
$ ip netns exec r1 tc class add dev r1eth1 parent 1: classid 1:1 htb rate 2mbit ceil 2mbit
$ ip netns exec r1 tc class add dev r1eth1 parent 1:1 classid 1:10 htb rate 500kbit ceil 2mbit prio 0
$ ip netns exec r1 tc class add dev r1eth1 parent 1:1 classid 1:20 htb rate 1500kbit ceil 2mbit prio 1

# the classifier: top six bits of the DS field equal to 46, which is EF
$ ip netns exec r1 tc filter add dev r1eth1 parent 1: protocol ip prio 1 u32 match ip dsfield 0xb8 0xfc flowid 1:10

# h3 fills the link again
$ ip netns exec h3 ping -f -s 1400 -l 200 -w 14 10.0.2.2 > /dev/null 2>&1 &
$ sleep 2

# marked, and then unmarked, through the same router at the same moment
$ ip netns exec h1 ping -c 5 -i 0.5 -Q 0xb8 10.0.2.2 | tail -2
5 packets transmitted, 5 received, 0% packet loss, time 2020ms
rtt min/avg/max/mdev = 0.020/0.050/0.077/0.019 ms
$ ip netns exec h1 ping -c 5 -i 0.5 10.0.2.2 | tail -2
5 packets transmitted, 5 received, 0% packet loss, time 2015ms
rtt min/avg/max/mdev = 1154.660/1157.547/1159.795/2.127 ms, pipe 3
$ sleep 8

# where the packets went
$ ip netns exec r1 tc -s class show dev r1eth1 | grep -A1 "class htb 1:[12]0"
class htb 1:10 parent 1:1 prio 0 rate 500Kbit ceil 2Mbit burst 1600b cburst 1600b
 Sent 490 bytes 5 pkt (dropped 0, overlimits 0 requeues 0) 
--
class htb 1:20 parent 1:1 prio 1 rate 1500Kbit ceil 2Mbit burst 1600b cburst 1600b
 Sent 3792200 bytes 2644 pkt (dropped 0, overlimits 2630 requeues 0) 
```

</details>

Same link, same flood, same two megabits. The marked probe is answered in five
hundredths of a millisecond and the unmarked one takes over a second, in the same
router, at the same moment, on the same wire.

The counters underneath say where everything went: five packets down the priority
class and two and a half thousand down the default one. That ratio is the whole
design. Priority is only cheap because almost nothing is entitled to it, and a
policy that marks half the traffic as important has produced a link with two
queues and the same problem.

<details class="deeper">
<summary>If you already build these: why the priority class needs a ceiling, and what happens the day somebody marks a backup</summary>

A strict priority queue is served until it is empty. If the traffic entitled to it
can exceed the link, everything else stops completely, and the failure looks like a
total outage rather than a performance problem, which makes it slower to diagnose
than the thing it was meant to prevent.

So a real policy bounds it. In the capture above the priority class has a rate of
500 kilobits on a two megabit link, which is enough for several calls and cannot
starve the rest. The device is then doing something more subtle than "always
first": it serves the priority class first up to its rate and treats the excess as
ordinary traffic.

The day this matters is the day somebody points a backup or a file copy at the
marked class, usually by reusing a port number that the classifier matches. Without
a ceiling the entire link belongs to the backup and every call and every session
stops. With one, the backup gets 500 kilobits of priority and then queues like
everything else, the calls survive, and somebody notices the backup is slow, which
is a support ticket rather than an outage.

The general rule underneath is that any mechanism which grants unbounded precedence
will eventually be pointed at something that consumes all of it.

</details>

## Shaping and policing are different answers

Both measure a rate. What they do with the excess is opposite, and choosing wrongly
is one of the few quality of service mistakes that makes things worse rather than
merely doing nothing.

| | Shaping | Policing |
| --- | --- | --- |
| The excess is | Buffered and sent later | Dropped, or re-marked and sent |
| So the cost is | Delay, and memory on the device | Loss, and the retransmissions that follow |
| Bursts are | Smoothed out | Cut off at the limit |
| Usually applied | On the way out of an interface | On the way in |

The rule of thumb that survives contact with real traffic: shape what you send,
police what you receive. You can afford to delay your own traffic because delaying
it is cheaper than having somebody else discard it, and you cannot delay traffic
arriving from elsewhere in any useful way because by the time it reached you the
capacity was already spent.

There is a second half that catches people. Buffering is not free and a large
buffer is not generosity. A queue deep enough to hold a second of traffic converts
a loss problem into a delay problem, and for anything interactive that is a worse
outcome, because a lost packet is retransmitted in milliseconds and a second of
queue is a second of queue. That is the whole bufferbloat argument, and the modern
answer to it is a queue discipline that keeps itself short by dropping early, which
is what RFC 8290 describes.

## The marks stop at the edge of what you own

A code point is six bits any device can set. A laptop can write 46 into every
packet it sends, and nothing in the protocol prevents it, so a marking arriving
from a host is a claim rather than evidence.

That is what a trust boundary is for. At the edge of a network you decide which
sources are believed and rewrite the rest. A telephone that authenticated to the
network keeps its marking; a socket in a meeting room has everything reset to
zero and re-marked according to what the traffic actually is. RFC 2475 describes
this as the job of a boundary node, and it is the step that turns a set of
markings into something a policy can be built on.

The same logic applies to the far edge, and this is the fact worth taking away
from the whole topic. **When your traffic leaves for the internet, your markings
stop meaning anything.** A provider is under no obligation to honour a code point
it did not set, most clear them, and some use the same bits for their own purposes
so that yours arrive changed. Unless the contract says the markings are honoured,
and some do for a fee, everything in this topic applies to the portion of the path
you own and nothing else.

Which puts the scenario at the top of the page back together. The calls break at
four because the internet circuit is full at four. The internal links are at
eleven per cent because they are not the constraint, the policy on the switches
acts on queues that never form, and the only queue that matters is the one on the
outside interface of the router, on traffic whose markings the provider will
discard a hop later.

## Prove it

**Read a marking off your own machine.** Capture a few seconds of traffic and look
at the type of service byte on what leaves. Most of it will be zero. Video calling
software frequently is not, and finding a non-zero value in your own capture is the
fastest way to stop thinking of this as theoretical.

**Do the arithmetic in both directions.** Take 0xb8 from the capture above, shift
it right two places, and confirm you get 46. Then take AF41, which is 34, shift it
left two places, and confirm you would see 0x88 in a capture. The two forms are the
same number and every document you read will assume you can convert between them
without saying so.

**Read the recommended code point clause.** RFC 3246 section 2.7 is one sentence
long. Read it and note the word it uses: the code point is recommended, not
required, which is the difference between a convention and a protocol and is the
reason a policy has to be configured at every hop rather than announced once.

## What trips people up

### 1. Configuring the policy somewhere nothing queues

The commonest failure by a distance. A policy on a device whose outbound interfaces
are never full has no effect that any instrument can detect. Find the narrowest
interface on the path first, and configure that.

### 2. Reading a code point as a request

Nothing about a marked packet obliges any device to treat it differently. The
marking is read by devices that were configured to read it and is a number in a
field everywhere else, which is why a policy is a design across every hop rather
than a setting on one.

### 3. Trusting the marking a host arrived with

Any machine can set any value. Without a trust boundary that rewrites markings at
the edge, the policy is available to whoever configures their own workstation
first, and the first person to do that is not usually the one with the voice
traffic.

### 4. Confusing the two numbers

Configuration guides say 46. Packet captures say 0xb8. Somebody reads one, checks
for the other, does not find it, and concludes the marking is missing. Shift by
two and they are the same value.

### 5. Buying a deeper buffer to fix delay

A deeper buffer holds more packets, which means packets wait longer. It converts
drops into delay, and for a call the delay is the thing that was hurting. Short
queues that drop early are what interactive traffic wants.

### 6. Expecting the marks to survive the internet

They usually do not, and a design that assumes they do will work perfectly in
testing between two sites you own and fail on the path that actually carries the
calls.

## Work it through

A branch office has a 50 megabit circuit. Calls to head office are fine all morning
and unusable between two and three in the afternoon. Nothing is scheduled at two.
The circuit graph, polled every five minutes, peaks at 34 megabits.

Start with where the queue is. Fifty megabits at 34 average leaves room, but the
average is over five minutes and a call is ruined by two seconds, so the graph
cannot answer the question and should be set aside rather than argued with. The
queue counters on the router's outside interface can: if they show drops climbing
between two and three, the circuit is full in bursts and the average is hiding it.

Then ask what is generating the bursts. Something starts at two. Not a scheduled
job, because there is none, so it is behavioural: a shift change, a shared drive
that a team starts using after lunch, or a cloud backup client whose schedule is
set on the endpoints rather than centrally.

Now the design. Voice from the phones is marked at the phone, and that marking is
trusted only because the phones authenticate; everything from the desk sockets is
reset at the switch. The router shapes its own outbound traffic to slightly under
the circuit rate, which is what moves the queue from the provider's equipment,
where you cannot see it or influence it, onto your own interface where you can.
Inside that shaper the marked voice gets a bounded priority class.

And the honest caveat, which belongs in the change record rather than being
discovered later: this fixes the outbound direction. Traffic arriving from the
internet queues in the provider's equipment before it reaches you, and no
configuration on your router can reorder a queue that has already been served. If
the afternoon problem is inbound, the answer is a conversation with the provider or
a bigger circuit, and knowing which of the two directions is at fault is worth the
ten minutes it takes to measure.

## Try it

**Fill a link you own and watch a ping.** In
[`congested-link.sh`](https://github.com/rlwilliamson-dev/azure-resume/blob/main/blog/scripts/topologies/congested-link.sh)
the whole demonstration above is four commands. Applying the rate limit and then
pinging through it is the fastest way to feel the difference between a link that is
busy and a link that is full.

**Then add the second queue and repeat.** Watching the same ping go from four
hundred milliseconds to a twentieth of one, with nothing changed except which queue
its packets are put in, is worth more than the explanation.

**Look for a marking in your own traffic.** Start a video call, capture on your own
interface, and read the type of service byte. Whether you find one or not tells you
something about the software you use every day.

## Check yourself

<details class="qa">
<summary>A policy is configured on every switch in the building and call quality is unchanged. What is the most likely explanation?</summary>

The switch interfaces never fill, so no queue forms and the policy has nothing to
act on. The narrowest interface on the path is somewhere else, most likely the
internet circuit or the wireless, and that is where the queue that is hurting the
call exists.

</details>

<details class="qa">
<summary>A capture shows tos 0x88. What code point is that, and what is it usually called?</summary>

Shift right by two: 0x88 is 136, and 136 divided by 4 is 34. Thirty four is AF41,
one of the assured forwarding values from RFC 2597, conventionally used for
interactive video.

</details>

<details class="qa">
<summary>Why does a priority class need a rate limit on it?</summary>

A strict priority queue is served until empty, so traffic entitled to it can starve
everything else completely. Bounding the rate means that anything which is marked
wrongly, or marked deliberately by somebody who wants to go first, consumes its
share and then queues like everything else.

</details>

<details class="qa">
<summary>Shaping and policing both hold traffic to a rate. Which one should you apply to traffic you are sending, and why?</summary>

Shaping. Delaying your own traffic in your own buffer is cheaper than having it
discarded further along, because a drop costs a retransmission and the capacity
that carried the lost packet. Policing suits traffic arriving from elsewhere, where
the capacity has already been spent by the time you see it.

</details>

<details class="qa">
<summary>A workstation sets 46 on all of its traffic. What stops it from getting priority?</summary>

A trust boundary. The switch port it connects to is configured not to believe
arriving markings and rewrites them, so the value the workstation chose is replaced
before the traffic reaches any queue that would act on it. Without that step, the
policy is available to whoever configures their own machine.

</details>

## References

- [RFC 2474](https://www.rfc-editor.org/rfc/rfc2474) - IETF, which redefines the type of service byte as the differentiated services field and specifies the six bit code point. Free. Accessed 2026-08-20.
- [RFC 2475](https://www.rfc-editor.org/rfc/rfc2475) - IETF, the architecture, for boundary nodes and what a trust boundary is doing. Free. Accessed 2026-08-20.
- [RFC 3246](https://www.rfc-editor.org/rfc/rfc3246) - IETF, expedited forwarding, and section 2.7 for the recommended code point. Free. Accessed 2026-08-20.
- [RFC 2597](https://www.rfc-editor.org/rfc/rfc2597) - IETF, the assured forwarding values and the drop preference inside each class. Free. Accessed 2026-08-20.
- [RFC 4594](https://www.rfc-editor.org/rfc/rfc4594) - IETF, which collects the code points into service classes with a suggested use for each. Free. Accessed 2026-08-20.
- [RFC 3168](https://www.rfc-editor.org/rfc/rfc3168) - IETF, for the two bits at the bottom of the byte and why they are not part of the marking. Free. Accessed 2026-08-20.
- [RFC 8290](https://www.rfc-editor.org/rfc/rfc8290) - IETF, the flow queue and controlled delay scheduler, for the short queue argument. Free. Accessed 2026-08-20.
- [ITU-T G.114](https://www.itu.int/rec/T-REC-G.114-200305-I/en) - ITU-T, one-way transmission time, for the 150 and 400 millisecond planning bands quoted above. Abstract and scope readable without purchase. Accessed 2026-08-20.
- [tc-htb(8)](https://man7.org/linux/man-pages/man8/tc-htb.8.html) - Linux man-pages project, for the class hierarchy and the rate and ceiling used in the captures. Free. Accessed 2026-08-20.

**Where the output came from.** Three captured blocks through `netlab.sh` on the
kernel named in each header, on
[`congested-link.sh`](https://github.com/rlwilliamson-dev/azure-resume/blob/main/blog/scripts/topologies/congested-link.sh).
The rate limit, the class hierarchy and the classifier are applied inside the
captured command with `tc`, the marking is set by `ping -Q`, and every latency and
drop figure is the tool reporting what it observed. The code point values and the
names for them are from the RFCs above rather than from any measurement here.

**Why this is not in the lesson count.** The objectives name quality of service
once, in a list of functions, and none of the mechanisms on this page appear in
them. It is here because it is the answer to the question topics 75 and 76 raise
and cannot settle.
