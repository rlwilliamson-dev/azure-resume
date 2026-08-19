---
title: "Bandwidth, congestion and bottlenecks"
description: "The link is at 40 percent and everything is slow. Why a five minute average hides a link that was completely full, why contention shares a link rather than slowing it, and why one bulk transfer punishes every other user on the path."
deck: "The link is at 40 percent and everything is slow"
track: "network-plus"
level: "deep"
order: 760
objectives:
  - "Tell bandwidth from throughput and say where the difference goes"
  - "Explain why an averaged graph hides a saturated interface"
  - "Recognise contention as sharing rather than as a fault"
  - "Find the bottleneck on a path rather than the busiest link"
  - "Say what one bulk transfer does to every other flow on the path"
prerequisites: ["tcp-udp-and-the-handshake"]
tags: ["network-plus", "networking", "troubleshooting", "performance"]
updated: 2026-08-19
draft: false
examObjectives:
  - exam: "n10-009"
    domain: "5.0"
    objective: "5.4"
sources:
  - title: "iperf3 user documentation"
    url: "https://software.es.net/iperf/invoking.html"
    publisher: "ESnet"
    accessed: 2026-08-19
    tier: 1
  - title: "tc-netem(8)"
    url: "https://man7.org/linux/man-pages/man8/tc-netem.8.html"
    publisher: "man7.org"
    accessed: 2026-08-19
    tier: 1
  - title: "RFC 8290, The FlowQueue-CoDel Packet Scheduler"
    url: "https://www.rfc-editor.org/rfc/rfc8290"
    publisher: "IETF"
    accessed: 2026-08-19
    tier: 1
symptoms:
  - symptom: "A monitoring graph shows a link well under capacity while users report slowness"
    anchor: "forty-percent-and-completely-full"
  - symptom: "Everyone on a site is slow while one person transfers a large file"
    anchor: "what-a-full-link-does-to-everything-behind-it"
  - symptom: "A link rated at a speed never delivers that speed"
    anchor: "bandwidth-is-a-rating-throughput-is-a-measurement"
---

> **Before you read.** The site is slow. Everybody says so, all day, for anything
> that touches head office. The obvious suspect is the link between the two, so
> you open the graph for it.
>
> The graph says the link averages forty percent. It has never touched its
> capacity. There is, by that measurement, more than half of it going spare.
>
> **The link has plenty of room and everything crossing it is slow. How?**

Performance complaints are the hardest kind to act on because everybody agrees
something is wrong and nobody can point at anything broken. Nothing errors, no
counter climbs, and every device reports itself healthy. This topic is the small
number of measurements that turn "it is slow" into a specific link.

Every number on this page was measured on a link built for it, and every impairment
is created in the captured command, so nothing is asserted that was not observed.

### Some words you will need

<dl class="terms">
<dt>bandwidth</dt>
<dd>What a link is rated at. A property of the link, quoted by whoever sold it.</dd>
<dt>throughput</dt>
<dd>What actually gets through, measured. Always less than the bandwidth, and sometimes far less.</dd>
<dt>bottleneck</dt>
<dd>The narrowest link on a path. It sets the throughput of the whole path and nothing else on the path matters.</dd>
<dt>contention</dt>
<dd>Several flows wanting one link at once. They share it, which is not the same as the link slowing down.</dd>
<dt>utilisation</dt>
<dd>Traffic as a fraction of capacity. The only useful way to compare two links of different sizes.</dd>
</dl>

## What breaks without this

**The wrong link gets upgraded.** A path is as fast as its narrowest point, and the
link that carries the most traffic is frequently not that point, so money goes to
the link with the biggest number on the graph.

**A saturated link is declared healthy.** Averages hide saturation, and every
monitoring system averages. A link that is full for four seconds in ten looks
comfortable in every graph anybody will ever look at.

**One user's transfer becomes everybody's outage.** A single bulk copy fills the
queue on the narrowest link, and every other flow on the path pays for it in delay,
without any of them sending more than they did yesterday.

## Bandwidth is a rating, throughput is a measurement

Start with the two words people use interchangeably, because the difference is
measurable in one command.

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology wan-link
# the link between the two routers is given 100 Mb of capacity. that number is
# its bandwidth: what it is rated at
$ ip netns exec r1 tc qdisc replace dev r1-r2 root tbf rate 100mbit burst 32kbit latency 50ms
$ ip netns exec r2 tc qdisc replace dev r2-r1 root tbf rate 100mbit burst 32kbit latency 50ms
$ ip netns exec h2 iperf3 -s -D --logfile /tmp/s.log
$ sleep 1
# and this is what one host actually gets through it, which is its throughput
$ ip netns exec h1 iperf3 -c 10.0.2.2 -t 5 -f m 2>&1 | grep -E "sender|receiver"
[  5]   0.00-5.00   sec  59.5 MBytes  99.8 Mbits/sec   22            sender
[  5]   0.00-5.04   sec  57.4 MBytes  95.5 Mbits/sec                  receiver
```

The link is rated at 100 megabits and one host gets 95.5 through it. The missing
4.5 percent is not a fault: it is the Ethernet, IP and TCP headers on every packet,
which are carried by the link and are not carried by your data. **Bandwidth is what
the link moves and throughput is what your application moves**, and the gap between
them is protocol overhead you cannot remove.

That is the small version of the difference. The large version is when the two are
nowhere near each other, and that is what the rest of the topic is about, because
none of the remaining causes is overhead.

## Forty percent, and completely full

Now the hook, which is a measurement problem rather than a network problem.

A link is read once a second while one transfer crosses it, and then the same ten
seconds are reduced to one number, which is what a monitoring system stores.

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology wan-link
# a 100 Mb link, and one transfer that runs for four seconds out of ten
$ ip netns exec r1 tc qdisc replace dev r1-r2 root tbf rate 100mbit burst 32kbit latency 50ms
$ ip netns exec h2 iperf3 -s -D --logfile /tmp/s.log
$ sleep 1
$ ip netns exec h1 iperf3 -c 10.0.2.2 -t 4 -f m > /tmp/b.txt 2>&1 &
# the link counter read once a second while that happens, then the whole window
# as the single average a monitoring graph would plot
$ ip netns exec r1 sh -c "p=0; i=0; f=0; while [ \$i -lt 11 ]; do c=\$(cat /sys/class/net/r1-r2/statistics/tx_bytes); [ \$i -eq 0 ] && f=\$c; [ \$i -gt 0 ] && echo \"second \$i: \$(( (c-p)*8/1000000 )) Mb\"; p=\$c; i=\$((i+1)); sleep 1; done; echo \"ten second average: \$(( (p-f)*8/10/1000000 )) Mb per second\""
second 1: 100 Mb
second 2: 100 Mb
second 3: 100 Mb
second 4: 100 Mb
second 5: 9 Mb
second 6: 0 Mb
second 7: 0 Mb
second 8: 0 Mb
second 9: 0 Mb
second 10: 0 Mb
ten second average: 40 Mb per second
```

**Four seconds at a hundred megabits on a hundred megabit link, and an average of
forty.** Both numbers are correct. During those four seconds the link was completely
full, every queue behind it was filling, and anything else trying to cross was
waiting. The graph shows a comfortable forty percent because it was asked for an
average and it gave one.

Real monitoring is worse than this, not better. A five minute average over a link
that is saturated for thirty seconds at a time reports around ten percent, and there
is no combination of colours or thresholds that recovers the information, because it
was thrown away when the sample was taken.

So the number to ask for is not the average. **It is the peak, or better, the
proportion of samples above some threshold**, and the sampling interval has to be
short enough to see the bursts you care about. A graph is not evidence that a link
has headroom. It is evidence about the intervals somebody chose to average over.

<details class="deeper">
<summary>If you already read capacity graphs: what to ask a monitoring system for, and the queue that makes a full link worse than it needs to be</summary>

Two things follow from the block above, and the second is the more surprising.

The first is a practical request to make of whatever is collecting your counters.
Averages are what get stored because storing every sample forever is expensive, and
the compromise most systems make is to average on the way in, which destroys the
peaks permanently. What you want kept alongside the mean is the maximum within each
interval, and if the system will do it, a count of samples above a threshold. Then a
link that hits capacity for thirty seconds every hour is visible as a line that
touches the top, rather than as a mean that never leaves the floor. Where the choice
is not available, the fallback is to shorten the interval on the links that matter,
which is a small number of links.

The second is what happens in the moment the link is full, and it is not simply that
packets wait their turn. Equipment ships with generous queues, on the reasonable
theory that a buffered packet is better than a dropped one, and that theory breaks
when the queue is deep and the link is saturated for any length of time. The queue
fills, and every packet entering it waits for everything already in it. On a link
that is full for a whole second, a queue holding a second's worth of traffic adds a
second of delay to everything, including the small interactive flows that were not
causing the problem.

That is bufferbloat, and the capture in the section below is a direct measurement of
it: a round trip that is a fifth of a millisecond when the link is idle and two
hundred milliseconds when one other host is copying a file. Nothing is lost, no
counter moves, and the network is unusable for anything interactive. The fix is a
queue management algorithm that keeps the queue short rather than a bigger queue,
which is what CoDel and its relatives in RFC 8290 do, and which is why "just add more
buffer" is the wrong instinct.

</details>

## Contention is sharing, not slowing

The next thing people get wrong is what happens when two people use a link at once.

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology wan-link
# the same 100 Mb link, and two hosts behind it instead of one
$ ip netns exec r1 tc qdisc replace dev r1-r2 root tbf rate 100mbit burst 32kbit latency 50ms
$ ip netns exec r2 tc qdisc replace dev r2-r1 root tbf rate 100mbit burst 32kbit latency 50ms
$ ip netns exec h2 iperf3 -s -D -p 5201 --logfile /tmp/a.log
$ ip netns exec h2 iperf3 -s -D -p 5202 --logfile /tmp/b.log
$ sleep 1
# h1 with the link to itself
$ ip netns exec h1 iperf3 -c 10.0.2.2 -p 5201 -t 4 -f m 2>&1 | grep receiver
[  5]   0.00-4.05   sec  46.1 MBytes  95.5 Mbits/sec                  receiver
# now both hosts, started together, for the same five seconds
$ ip netns exec h1 iperf3 -c 10.0.2.2 -p 5201 -t 5 -f m > /tmp/h1.txt 2>&1 &
$ ip netns exec h3 iperf3 -c 10.0.2.2 -p 5202 -t 5 -f m > /tmp/h3.txt 2>&1 &
$ sleep 8
$ grep receiver /tmp/h1.txt /tmp/h3.txt
/tmp/h1.txt:[  5]   0.00-5.05   sec  28.1 MBytes  46.8 Mbits/sec                  receiver
/tmp/h3.txt:[  5]   0.00-5.05   sec  29.2 MBytes  48.6 Mbits/sec                  receiver
```

One host alone gets 95.5 megabits. Two hosts at once get 46.8 and 48.6, which sum to
95.4. **The link did not get slower. It got divided.** Nothing is broken, nothing is
misconfigured, and each user experiences half the speed they had yesterday because
somebody else is also using the thing they share.

That distinction is worth being precise about, because it changes what you tell
people. A fault is something to fix. Contention is a capacity decision that somebody
already made, and the options are to buy more capacity, to move some traffic
elsewhere, or to prioritise so that the traffic that matters gets served first when
the link is full. None of those is a repair.

The diagnostic signature is that **the total is constant while the individual shares
move.** If two users report half speed and the link's total is unchanged, they are
sharing. If two users report half speed and the total has also halved, something is
wrong with the link itself and that is a different investigation.

## What a full link does to everything behind it

The last piece is why a full link is not merely slow for whoever filled it.

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology wan-link
# a 100 Mb link with a large queue behind it, which is what most equipment ships
$ ip netns exec r1 tc qdisc replace dev r1-r2 root tbf rate 100mbit burst 32kbit latency 300ms
$ ip netns exec h2 iperf3 -s -D --logfile /tmp/s.log
$ sleep 1
# the link is idle. this is what a small interactive flow experiences
$ ip netns exec h3 ping -c3 -W1 10.0.2.2 2>&1 | tail -2
3 packets transmitted, 3 received, 0% packet loss, time 2062ms
rtt min/avg/max/mdev = 0.148/0.281/0.496/0.153 ms
# h1 starts one bulk transfer. h3 is not sending anything at all
$ ip netns exec h1 iperf3 -c 10.0.2.2 -t 8 -f m > /tmp/bulk.txt 2>&1 &
$ sleep 2
# the same three pings from the host that is not transferring anything
$ ip netns exec h3 ping -c3 -W2 10.0.2.2 2>&1 | tail -2
3 packets transmitted, 3 received, 0% packet loss, time 2004ms
rtt min/avg/max/mdev = 100.779/151.247/201.793/41.238 ms
$ sleep 8
$ grep receiver /tmp/bulk.txt
[  5]   0.00-8.25   sec  94.0 MBytes  95.6 Mbits/sec                  receiver
```

Read the two round trip figures. **0.281 milliseconds when the link is idle, and
151 milliseconds average with a peak of 201, while a different host copies a file.**
The host being measured is not sending anything except three pings. It has done
nothing, changed nothing, and its experience of the network is now five hundred
times worse.

That is the answer to almost every "the whole site is slow" report. One transfer
fills the narrowest link on the path, the queue in front of that link fills behind
it, and every packet from every other user joins the back of that queue. Interactive
work is destroyed by this long before file transfers notice, because a file transfer
measures itself in megabits and a login, a database query or a voice call measures
itself in milliseconds.

Which is also why **the bottleneck is not the same thing as the busiest link.**

<figure class="learn-figure">
<svg viewBox="0 0 720 185" role="img" aria-labelledby="bneck-title" style="width:100%;height:auto;">
<title id="bneck-title">Three links on one path each carrying the same 95 megabits, drawn as utilisation bars, where the two gigabit links are almost empty and the hundred megabit link is nearly full</title>
<g fill="currentColor">
<text x="14" y="20" font-size="11">the same 95 Mb through all three. only one of them is full</text>
<text x="14" y="59" font-size="10">office to core, 1 Gb</text>
<text x="14" y="99" font-size="10">core to branch, 100 Mb</text>
<text x="14" y="139" font-size="10">branch to server, 1 Gb</text>
<g fill="none" stroke="currentColor" stroke-opacity="0.6" stroke-width="1.2">
<rect x="210" y="44" width="400" height="20" rx="3"/>
<rect x="210" y="84" width="400" height="20" rx="3"/>
<rect x="210" y="124" width="400" height="20" rx="3"/>
</g>
<rect x="210" y="44" width="38" height="20" rx="3" fill="currentColor" fill-opacity="0.22"/>
<rect x="210" y="124" width="38" height="20" rx="3" fill="currentColor" fill-opacity="0.22"/>
<rect x="210" y="84" width="380" height="20" rx="3" fill="var(--accent)" fill-opacity="0.3" stroke="var(--accent)" stroke-opacity="0.9" stroke-width="1.6"/>
<text x="624" y="59" font-size="10">9%</text>
<text x="624" y="99" font-size="10" fill="var(--accent)">95%</text>
<text x="624" y="139" font-size="10">9%</text>
<text x="14" y="173" font-size="9.5" fill-opacity="0.85">ranked by bytes carried all three are equal. ranked by how full they are, one of them decides the path</text>
</g></svg>
<figcaption>Every link on a path carries the same traffic, so counting bytes ranks them all identically and tells you nothing. Utilisation is the measurement that separates them, and it is the one that identifies which link is deciding the speed of everything crossing it. The gigabit links here are not fine because they are fast, they are fine because the flow they carry is a small fraction of what they could carry. Upgrading either of them changes nothing at all, which is how capacity budgets get spent on the wrong link.</figcaption>
</figure>

So the order of work for a slow path is: find the links on it, express each one's
traffic as a percentage of its own capacity, and look at the largest percentage
rather than the largest number. That sounds obvious written down and it is the step
that gets skipped, because monitoring systems sort by traffic and the human eye goes
to the biggest graph.

## Prove it

You have this when you can turn "it is slow" into a named link and a number.

```bash
# what actually gets through, in each direction, between two points
iperf3 -s                       # on one end
iperf3 -c <server> -t 10        # on the other

# what a link is doing right now, sampled rather than averaged
ip -s link show <interface>     # read twice, subtract, divide by the interval

# and what the delay does under load, which is what users feel
ping -c 10 <host>               # while the transfer is running
```

The three together are the whole method. A throughput measurement between two points
tells you the path's capacity, which is the bottleneck's capacity. Sampling a
counter yourself rather than reading a graph tells you whether that link is
saturated now, at an interval you chose. And a ping during a transfer tells you what
everybody else on that path is experiencing, which is the number that generates the
complaints.

## What trips people up

### 1. Reading an average as a measurement of capacity

A five minute average over a link that is full for thirty seconds at a time reports
around ten percent. The information was destroyed when the sample was taken and no
amount of looking at the graph recovers it.

### 2. Expecting throughput to equal bandwidth

Headers are carried by the link and not by your data, so a 100 megabit link delivers
about 95 megabits of payload. That gap is normal and any gap much larger than it is
not overhead.

### 3. Treating contention as a fault

Two users sharing a link get half each and the link's total is unchanged. That is the
system working. The fix is capacity or prioritisation, not repair.

### 4. Upgrading the busiest link

Every link on a path carries the same flow, so the busiest by bytes is not
necessarily the narrowest. Only utilisation separates them, and only the narrowest one
sets the speed.

### 5. Measuring throughput and ignoring delay

A transfer that gets its full speed while every other user waits two hundred
milliseconds is not a healthy link. Latency under load is a separate measurement and
it is the one users report.

### 6. Adding buffer to a congested link

A deeper queue turns loss into delay, which for interactive traffic is worse. The
answer to a full queue is to keep it short, not to make it bigger.

## Work it through

The site that is slow while its link reports forty percent.

Start by refusing the graph, politely. Forty percent is an average over whatever
interval the system stores, and the question you need answered is not what the mean
was but whether the link ever reached capacity. Sample the interface counter yourself,
once a second for a minute, during a period somebody has complained about. That
single measurement either shows seconds at capacity, in which case the link is the
problem and the graph was hiding it, or it does not, in which case the link is
genuinely fine and you have eliminated the obvious suspect properly rather than by
argument.

Then measure the path rather than the link, because the link you were shown is not
necessarily the narrow one. A throughput test between a machine at each end gives you
the capacity of the whole path in one number, and it is the bottleneck's capacity
whatever that bottleneck turns out to be. If that number is far below the link's
rating, the constraint is somewhere else on the path.

Then measure delay under load, because that is what people are actually reporting.
Ping across the path while a transfer is running, from a machine that is not part of
the transfer. If the round trip goes from a fraction of a millisecond to hundreds,
you have found why everything interactive feels broken while the file copy reports
excellent speed, and you can say so in a sentence rather than as an intuition.

And then separate contention from a fault before proposing anything. If the total
across the link is unchanged and only the per-user share has fallen, nobody has broken
anything and the conversation is about capacity or priority. If the total has fallen
too, something is wrong with the link and the counters from topic 67 are where to look
next.

## Try it

**Sample a counter yourself.** Read an interface's byte counter once a second for
thirty seconds while you copy something large, and work out the per-second rate. Then
compare the peak against the average. The gap between them is the entire content of
this topic.

**Run a throughput test in both directions.** Many paths are asymmetric by design and
some are asymmetric by accident. Testing one direction and assuming the other is a
mistake that survives for years.

**Ping during a transfer.** From a machine that is not transferring anything. Watch
what happens to the round trip while somebody else fills the link, and note that
nothing anywhere reports an error while it happens.

## Check yourself

<details class="qa">
<summary>A link's graph averages forty percent and users say everything crossing it is slow. Is the graph wrong?</summary>

No, and neither are the users. The graph is reporting an average over whatever
interval it stores, and a link can be completely full for part of that interval and
idle for the rest while averaging forty percent.

In the lab a link was at capacity for four seconds out of ten and the ten second
average came out at forty. Real monitoring intervals are far longer, so a link
saturated for thirty seconds at a time can average around ten percent. The information
is destroyed at sampling time, so the fix is to ask for peaks rather than means, or to
sample the counter yourself at an interval short enough to see the bursts.

</details>

<details class="qa">
<summary>Two users each report half their usual speed. How do you tell contention from a fault?</summary>

Look at the total rather than the shares. If the two flows add up to what one flow got
on its own, the link is being shared and nothing is broken. In the lab one host got
95.5 megabits alone, and two hosts got 46.8 and 48.6, which is the same total.

If the total has fallen as well, the link itself has lost capacity and that is a
different investigation, starting with the interface counters and the negotiated speed
rather than with capacity planning.

</details>

<details class="qa">
<summary>Why does one person's file transfer make the network feel broken for everyone else?</summary>

Because it fills the queue in front of the narrowest link on the path, and every other
packet has to wait behind everything already in that queue.

The measurement is stark: a round trip of 0.281 milliseconds on an idle link became an
average of 151 milliseconds, with a peak of 201, for a host that was sending nothing
but three pings while another host copied a file. Nothing was lost and no counter
moved. File transfers barely notice added delay and anything interactive is destroyed
by it, which is why the complaints come from people who are not doing anything
demanding.

</details>

<details class="qa">
<summary>Three links on a path each carry 95 megabits. Which one is the bottleneck?</summary>

The one where 95 megabits is the largest fraction of its capacity. Every link on a path
carries the same flow, so ranking them by traffic ranks them identically and tells you
nothing.

A gigabit link carrying 95 megabits is at nine percent and has plenty of room. A hundred
megabit link carrying the same 95 megabits is at ninety five percent and is deciding the
speed of the entire path. Upgrading either gigabit link changes nothing, which is how
capacity money gets spent on the wrong equipment.

</details>

<details class="qa">
<summary>Why is a bigger buffer the wrong answer to a congested link?</summary>

Because a buffer converts loss into delay, and for the traffic that suffers most from
congestion, delay is the worse of the two.

A deep queue in front of a saturated link fills up and every arriving packet waits for
everything ahead of it, which is how a link that is merely full becomes a link where
interactive work is impossible. Bulk transfers keep getting their throughput while
everything latency-sensitive collapses. The answer is queue management that keeps the
queue short, which is what CoDel and its relatives do, rather than more queue.

</details>

## References

- [iperf3 documentation](https://software.es.net/iperf/invoking.html) - ESnet, for the throughput, window and UDP options every measurement here uses. Free. Accessed 2026-08-19.
- [tc-netem(8)](https://man7.org/linux/man-pages/man8/tc-netem.8.html) - man7.org, for the rate limiting and queue latency applied to the link in each capture. Free. Accessed 2026-08-19.
- [RFC 8290](https://www.rfc-editor.org/rfc/rfc8290) - IETF, FlowQueue-CoDel, which is the queue management the bufferbloat measurement above argues for. Free. Accessed 2026-08-19.

**Where the numbers came from.** Four captured blocks through `netlab.sh` on the kernel
named in each header, on
[`wan-link.sh`](https://github.com/rlwilliamson-dev/azure-resume/blob/main/blog/scripts/topologies/wan-link.sh),
a topology built for this block: two sites, one constrained link, and two hosts sharing
it. Nothing in the topology is impaired. Every rate limit and every queue depth is applied
in the captured command, so the constraint and the number it produced appear together.
Throughput, contention and latency under load are measured with `iperf3` and `ping`; the
per-second link samples are read straight from the interface counter.

**If you also work on Linux systems.** [I/O and network performance](/learn/linux-plus/io-and-network-performance)
approaches the same question from inside one machine, where the constraint may be the disk,
the CPU or the network stack rather than a link. The measurement discipline is identical:
sample rather than average, and measure the path rather than trusting a rating.
