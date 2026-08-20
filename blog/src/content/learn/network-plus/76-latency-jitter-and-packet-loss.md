---
title: "Latency, jitter and packet loss"
description: "The call breaks up and the file transfer is fine. Why a packet that arrives late is a packet that is lost when something is waiting for it, why one percent loss costs a TCP transfer most of its speed, and why the same path can be excellent and unusable at the same time."
deck: "The call breaks up and the file transfer is fine"
track: "network-plus"
level: "deep"
order: 770
objectives:
  - "Say where latency comes from and which part of it you can change"
  - "Explain why latency limits throughput even on a fast link"
  - "Tell jitter from latency and say why a call cares about the difference"
  - "Say what one percent loss does to TCP and what it does to UDP"
  - "Match each of the three impairments to the applications that suffer from it"
prerequisites: ["tcp-udp-and-the-handshake"]
tags: ["network-plus", "networking", "troubleshooting", "performance"]
updated: 2026-08-19
draft: false
examObjectives:
  - exam: "n10-009"
    domain: "5.0"
    objective: "5.4"
sources:
  - title: "RFC 3550, RTP: A Transport Protocol for Real-Time Applications"
    url: "https://www.rfc-editor.org/rfc/rfc3550"
    publisher: "IETF"
    accessed: 2026-08-19
    tier: 1
  - title: "RFC 5681, TCP Congestion Control"
    url: "https://www.rfc-editor.org/rfc/rfc5681"
    publisher: "IETF"
    accessed: 2026-08-19
    tier: 1
  - title: "iperf3 user documentation"
    url: "https://software.es.net/iperf/invoking.html"
    publisher: "ESnet"
    accessed: 2026-08-19
    tier: 1
symptoms:
  - symptom: "Voice or video breaks up while file transfers are unaffected"
    anchor: "jitter-is-variation-and-variation-is-what-breaks-a-call"
  - symptom: "A fast link delivers a fraction of its rated speed over long distance"
    anchor: "why-latency-limits-throughput"
  - symptom: "A transfer is slow and no counter shows an error"
    anchor: "one-percent"
---

> **Before you read.** A call between two offices breaks up. Words drop out,
> people talk over each other, and everybody agrees the network is bad.
>
> At the same time, and across the same link, a large file copies between the two
> sites at close to full speed with no errors at all.
>
> **One path, two applications, opposite verdicts. Who is right?**

Both of them. A network path has more than one quality, and the three that matter
are almost independent of each other. A path can have plenty of capacity and be
unusable for a call. A path can have low delay and destroy a file transfer. This
topic is the three measurements and which applications care about which.

Everything here is measured, and every impairment is created in the captured
command on a link built for it.

### Some words you will need

<dl class="terms">
<dt>latency</dt>
<dd>How long a packet takes to get there. Usually quoted as a round trip, out and back.</dd>
<dt>jitter</dt>
<dd>How much the latency varies between packets. A separate number from the average, and often the more important one.</dd>
<dt>packet loss</dt>
<dd>The proportion of packets that never arrive. Measured as a percentage, and a percentage far smaller than you would guess is enough to matter.</dd>
<dt>bandwidth delay product</dt>
<dd>Capacity multiplied by round trip. How much data has to be in flight to keep a link busy.</dd>
<dt>jitter buffer</dt>
<dd>A small store at the receiver that smooths out variation by holding packets briefly before playing them. It costs delay to buy steadiness.</dd>
</dl>

## What breaks without this

**The wrong metric gets reported.** A link is described as good because it has
capacity, and the application that is failing does not care about capacity at all.

**A path is upgraded and nothing improves.** More bandwidth does not reduce delay,
does not reduce variation, and does not fix loss. Three of the four things people buy
capacity to fix are unaffected by it.

**A tiny loss rate is dismissed.** One percent sounds negligible and is enough to
take most of the speed off a bulk transfer, which is why "we only lose a bit" is one
of the more expensive sentences in networking.

## Latency, and where it comes from

Latency has four contributors and only one of them is negotiable.

**Distance** is a hard floor. Light in fibre covers roughly two hundred kilometres
per millisecond, so London to New York cannot be faster than about twenty-eight
milliseconds each way whatever anybody sells you. No equipment reduces this.

**Serialisation** is the time to clock the bits out of an interface, and it shrinks as
links get faster. On modern links it is small enough to ignore for anything but the
largest frames.

**Processing** is what each device spends looking at the packet. On hardware
forwarding it is microseconds. On a device doing inspection, decryption or address
translation, it is not.

**Queueing** is the one that varies, the one that gets large, and the one you can do
something about. It is time spent waiting behind other packets, and topic 75's
measurement of a round trip going from a fifth of a millisecond to two hundred was
entirely this.

Here it is added deliberately, which is the only way to see its effect cleanly.

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology wan-link
# a 100 Mb link with no delay on it
$ ip netns exec r1 tc qdisc replace dev r1-r2 root netem rate 100mbit
$ ip netns exec r2 tc qdisc replace dev r2-r1 root netem rate 100mbit
$ ip netns exec h2 iperf3 -s -D --logfile /tmp/s.log
$ sleep 1
$ ip netns exec h1 ping -c3 -W1 10.0.2.2 2>&1 | tail -1
rtt min/avg/max/mdev = 0.143/0.175/0.232/0.040 ms
$ ip netns exec h1 iperf3 -c 10.0.2.2 -t 5 -f m 2>&1 | grep receiver
[  5]   0.00-5.24   sec  59.6 MBytes  95.4 Mbits/sec                  receiver
# 50 ms is added in each direction, which is a hundred millisecond round trip.
# the capacity of the link does not change
$ ip netns exec r1 tc qdisc replace dev r1-r2 root netem rate 100mbit delay 50ms
$ ip netns exec r2 tc qdisc replace dev r2-r1 root netem rate 100mbit delay 50ms
$ ip netns exec h1 ping -c3 -W2 10.0.2.2 2>&1 | tail -1
rtt min/avg/max/mdev = 105.252/106.163/107.037/0.729 ms
$ ip netns exec h1 iperf3 -c 10.0.2.2 -t 5 -f m 2>&1 | grep receiver
[  5]   0.00-5.23   sec  51.8 MBytes  83.1 Mbits/sec                  receiver
```

Fifty milliseconds each direction becomes a hundred and six milliseconds round trip,
and throughput falls from 95.4 to 83.1 megabits on a link whose capacity did not
change. That drop is modest because the operating system tuned its send window up to
compensate. When it cannot, the effect is much larger, which is the next section.

<details class="deeper">
<summary>If you already budget latency: the round trip you cannot see from either end</summary>

The four contributors are per hop and there is a fifth that belongs to the application
rather than the network, and it dominates more often than any of them.

An application that makes several sequential requests, each waiting for the previous
response, multiplies the round trip by the number of requests. Ten dependent requests over a
hundred millisecond path is a second before anything appears, and no amount of network work
changes it, because the network delivered each request promptly and the application waited
in between.

That is why the same application feels fine in the office and unusable from another
continent while every network measurement looks healthy. The network contributed one round
trip and the application chose to pay for it ten times.

The consequence for anybody investigating is that measuring the network is only half the
answer, and the other half is counting round trips rather than measuring them. A capture
shows this immediately as a sequence of small exchanges with gaps between them, each gap one
round trip wide. When that pattern appears, the fix is in the application's request
behaviour, and reporting it as a network problem sends the work to the wrong team for a
month.

</details>

## Why latency limits throughput

The connection between delay and speed is the least intuitive thing in this topic and
it is arithmetic rather than opinion.

A sender may only have so much data outstanding before it has to stop and wait for an
acknowledgement. Whatever that limit is, the sender can transmit it once per round
trip and no faster. So **throughput is at most the window divided by the round trip
time**, and on a long path that number can be far below the link's capacity.

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology wan-link
# a 100 Mb link with a hundred millisecond round trip on it
$ ip netns exec r1 tc qdisc replace dev r1-r2 root netem rate 100mbit delay 50ms
$ ip netns exec r2 tc qdisc replace dev r2-r1 root netem rate 100mbit delay 50ms
$ ip netns exec h2 iperf3 -s -D --logfile /tmp/s.log
$ sleep 1
$ ip netns exec h1 ping -c3 -W2 10.0.2.2 2>&1 | tail -1
rtt min/avg/max/mdev = 100.270/141.785/214.845/51.821 ms
# a sender allowed to keep 64 kB in flight before it has to wait for an
# acknowledgement, which is what plenty of software still asks for
$ ip netns exec h1 iperf3 -c 10.0.2.2 -t 5 -w 64K -f m 2>&1 | grep receiver
[  5]   0.00-5.12   sec  4.00 MBytes  6.56 Mbits/sec                  receiver
# the same link, the same delay, with the sender allowed to keep 4 MB in flight
$ ip netns exec h1 iperf3 -c 10.0.2.2 -t 5 -w 4M -f m 2>&1 | grep receiver
[  5]   0.00-5.35   sec  53.1 MBytes  83.2 Mbits/sec                  receiver
```

Identical link, identical delay, and 6.56 megabits against 83.2. The only difference
is how much the sender was allowed to keep in flight. With 64 kilobytes and a hundred
millisecond round trip the sender spends most of its time waiting, and a hundred
megabit link delivers less than seven.

That is why a transfer between continents can be slow on a fast connection while the
same transfer across the building saturates it, and why the fix is a window setting or
a protocol that keeps more in flight rather than a bigger link. Buying more capacity
for a path limited this way changes nothing at all.

<details class="deeper">
<summary>If you already tune this: the number to compute before you buy anything, and why one big transfer is the wrong test</summary>

The useful habit is to compute the bandwidth delay product before proposing any
capacity change on a long path. Multiply the link's capacity by the round trip and
you have the amount of data that must be in flight to keep it busy. A gigabit link
with a hundred millisecond round trip needs about twelve and a half megabytes
outstanding. If the software at either end will not keep that much outstanding, the
link cannot be filled by that software and its size is irrelevant.

That single calculation resolves a lot of arguments, because it converts "the link is
too small" into a testable claim. It also explains why the answer is often several
parallel transfers rather than one: each connection has its own window, so ten
connections fill a pipe that one connection cannot, which is why download accelerators
and parallel copy tools exist and why a single-stream test understates a path.

Which is the caution about testing. **A single stream measures the stream, not the
path.** A single TCP connection over a long path with any loss on it will report a
number well below what the path can carry, and reporting that number as the path's
capacity is how a perfectly adequate link gets replaced. Test with several streams in
parallel as well as one, and the gap between the two results is itself diagnostic: a
large gap means the constraint is the transport rather than the link.

</details>

## Jitter is variation, and variation is what breaks a call

The third measurement is the one people meet last and it explains the hook.

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology wan-link
# a steady 20 ms path, and a voice sized stream across it: small packets sent at
# a constant rate, which is what a call is
$ ip netns exec r1 tc qdisc replace dev r1-r2 root netem rate 100mbit delay 10ms
$ ip netns exec r2 tc qdisc replace dev r2-r1 root netem rate 100mbit delay 10ms
$ ip netns exec h2 iperf3 -s -D --logfile /tmp/s.log
$ sleep 1
$ ip netns exec h1 ping -c5 -W2 10.0.2.2 2>&1 | tail -1
rtt min/avg/max/mdev = 20.196/29.862/51.629/11.371 ms
$ ip netns exec h1 iperf3 -c 10.0.2.2 -u -b 1M -l 160 -t 5 2>&1 | grep -E "Jitter|receiver"
[ ID] Interval           Transfer     Bitrate         Jitter    Lost/Total Datagrams
[  5]   0.00-5.03   sec   611 KBytes   995 Kbits/sec  0.178 ms  0/3908 (0%)  receiver
# the same average delay, now varying by 10 ms either side of it. the average
# hardly moves
$ ip netns exec r1 tc qdisc replace dev r1-r2 root netem rate 100mbit delay 10ms 10ms
$ ip netns exec h1 ping -c5 -W2 10.0.2.2 2>&1 | tail -1
rtt min/avg/max/mdev = 24.129/28.801/34.157/3.382 ms
$ ip netns exec h1 iperf3 -c 10.0.2.2 -u -b 1M -l 160 -t 5 2>&1 | grep -E "Jitter|receiver"
[ ID] Interval           Transfer     Bitrate         Jitter    Lost/Total Datagrams
[  5]   0.00-5.03   sec   611 KBytes   994 Kbits/sec  1.968 ms  0/3908 (0%)  receiver
```

Read what changed and what did not. The average round trip went from 20 to 28
milliseconds, which nobody would notice. The throughput is identical. **Not one
packet was lost.** And the jitter went from 0.178 milliseconds to 1.968, an
eleven-fold increase, which is the number a call cares about.

The reason is that voice has a deadline and a file does not.

<figure class="learn-figure">
<svg viewBox="0 0 720 205" role="img" aria-labelledby="jit-title" style="width:100%;height:auto;">
<title id="jit-title">Six packets sent at even intervals arriving at uneven ones, with the last arriving after the moment it was needed for playback and therefore discarded</title>
<g fill="currentColor">
<text x="14" y="20" font-size="11">sent evenly, arriving unevenly, and one of them arrives after it was needed</text>
<text x="16" y="59" font-size="10" fill-opacity="0.85">sent</text>
<text x="16" y="129" font-size="10" fill-opacity="0.85">heard</text>
<g stroke="currentColor" stroke-opacity="0.4" stroke-width="1.2" fill="none">
<path d="M 70 55 H 660"/>
<path d="M 70 125 H 660"/>
</g>
<g stroke="currentColor" stroke-opacity="0.35" stroke-width="1" fill="none">
<path d="M 120 60 L 135 120"/>
<path d="M 200 60 L 225 120"/>
<path d="M 280 60 L 292 120"/>
<path d="M 360 60 L 380 120"/>
<path d="M 440 60 L 452 120"/>
</g>
<g stroke="var(--red)" stroke-opacity="0.8" stroke-width="1.2" stroke-dasharray="3 3" fill="none">
<path d="M 520 60 L 600 120"/>
</g>
<g fill="currentColor" fill-opacity="0.55">
<circle cx="120" cy="55" r="4"/>
<circle cx="200" cy="55" r="4"/>
<circle cx="280" cy="55" r="4"/>
<circle cx="360" cy="55" r="4"/>
<circle cx="440" cy="55" r="4"/>
<circle cx="520" cy="55" r="4"/>
<circle cx="135" cy="125" r="4"/>
<circle cx="225" cy="125" r="4"/>
<circle cx="292" cy="125" r="4"/>
<circle cx="380" cy="125" r="4"/>
<circle cx="452" cy="125" r="4"/>
</g>
<circle cx="600" cy="125" r="4" fill="var(--red)" fill-opacity="0.8"/>
<g stroke="var(--red)" stroke-width="1.4" stroke-dasharray="4 3" fill="none">
<path d="M 545 100 V 150"/>
</g>
<text x="545" y="94" text-anchor="middle" font-size="9" fill="var(--red)">its slot</text>
<text x="600" y="166" text-anchor="middle" font-size="9.5" fill="var(--red)">arrives after it, so silence</text>
<text x="14" y="194" font-size="9.5" fill-opacity="0.85">a jitter buffer absorbs some of this, and what it absorbs it pays for in delay</text>
</g></svg>
<figcaption>A call plays audio out at a fixed rate, so every packet has a moment it is needed and being late is the same as never arriving. Nothing was lost on the network in the drawing above and the listener still hears a gap. That is why an average round trip time says almost nothing about call quality: the average can be excellent while the variation around it is enough to miss slots. A receiver defends itself with a buffer, holding packets briefly so late ones still land in time, but every millisecond of buffer is a millisecond added to the conversation, so the defence has a hard limit before people start talking over each other.</figcaption>
</figure>

A file transfer has no such deadline. Packets arriving unevenly are reassembled in
order by the receiver, which does not care when they turned up, and the file that
comes out is identical. **The same jitter is invisible to one application and fatal
to the other**, on the same path, at the same moment, which is exactly the hook.

<details class="deeper">
<summary>If you already tune voice: what the buffer costs, and the number that decides a conversation</summary>

A jitter buffer trades delay for steadiness, and the exchange rate is what decides whether a
call is usable rather than merely audible.

The buffer holds packets briefly so late ones still arrive in time to play, so a deeper
buffer tolerates more variation and adds its own depth to the end-to-end delay. That is fine
until the total one-way delay reaches the point where people start talking over each other,
because each is waiting for the other to finish and hearing the pause too late.

Which is why a call can be perfectly clear and still be exhausting. No audio is missing, no
packets were lost, and the conversation is awkward because the turn-taking has broken. Users
report that as a quality problem and it is a delay problem, and the two have different fixes:
audio quality wants a bigger buffer and turn-taking wants a smaller one.

So the useful measurement for voice is one-way delay including the buffer rather than
jitter alone, and the useful intervention is usually to reduce the variation so the buffer
can be shallower, rather than to accommodate the variation with more buffer. That points at
queueing, which points at topic 75, and it is the reason these two topics keep arriving at
the same place from different directions.

</details>

## One percent

The last measurement is the one whose scale surprises people.

<details class="predict">
<summary>One packet in a hundred is dropped. What does that cost a bulk TCP transfer, and what does it cost a UDP stream on the same link at the same moment?</summary>

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology wan-link
# a 100 Mb link with a 40 ms round trip and nothing wrong with it
$ ip netns exec r1 tc qdisc replace dev r1-r2 root netem rate 100mbit delay 20ms
$ ip netns exec r2 tc qdisc replace dev r2-r1 root netem rate 100mbit delay 20ms
$ ip netns exec h2 iperf3 -s -D --logfile /tmp/s.log
$ sleep 1
$ ip netns exec h1 iperf3 -c 10.0.2.2 -t 5 -f m 2>&1 | grep receiver
[  5]   0.00-5.20   sec  46.4 MBytes  74.7 Mbits/sec                  receiver
$ ip netns exec h1 iperf3 -c 10.0.2.2 -u -b 5M -l 160 -t 5 2>&1 | grep receiver
[  5]   0.00-5.04   sec  2.98 MBytes  4.96 Mbits/sec  0.056 ms  0/19535 (0%)  receiver
# one packet in a hundred is dropped. one percent
$ ip netns exec r1 tc qdisc replace dev r1-r2 root netem rate 100mbit delay 20ms loss 1%
$ ip netns exec h1 iperf3 -c 10.0.2.2 -t 5 -f m 2>&1 | grep receiver
[  5]   0.00-5.05   sec  3.00 MBytes  4.99 Mbits/sec                  receiver
$ ip netns exec h1 iperf3 -c 10.0.2.2 -u -b 5M -l 160 -t 5 2>&1 | grep receiver
[  5]   0.00-5.05   sec  2.95 MBytes  4.91 Mbits/sec  0.059 ms  189/19535 (0.97%)  receiver
```

</details>

**TCP fell from 74.7 megabits to 4.99.** One packet in a hundred was dropped and
ninety-three percent of the throughput went with it. The UDP stream over the same
link at the same moment kept its rate and lost exactly what was dropped, 0.97
percent.

That gap is the whole of why loss matters differently to different applications, and
the mechanism is congestion control doing its job. TCP treats a lost packet as
evidence of congestion, so it reduces its sending rate, then rebuilds slowly, and
another loss knocks it down again. On a path with steady loss the connection spends
its life recovering. Nothing is broken, no counter on any device records an error at
the sender, and the transfer is twenty times slower than the link allows.

UDP does none of that. It sends at the rate it was asked to, loses whatever the path
loses, and it is the application's problem. For a voice call that is the right
trade: a lost packet is a few milliseconds of audio, and a resend would arrive far
too late to play, so asking for one would be worse than useless.

**So the same loss rate is a catastrophe for one application and a minor annoyance
for the other**, which is the second half of the answer to the hook. Put it next to
the jitter result and the picture is complete: the call is destroyed by variation and
survives loss, and the file transfer ignores variation and is destroyed by loss.

| Impairment | The file transfer | The call |
| --- | --- | --- |
| Latency | Limits throughput through the window | Adds delay to the conversation |
| Jitter | Invisible | The main cause of breakup |
| Loss | Severe, through congestion control | Tolerable in small amounts |

## Prove it

You have this when you can produce three numbers for a path rather than one.

```bash
# latency and its variation, from the deviation figure
ping -c 20 <host>

# throughput, and separately with several streams
iperf3 -c <server> -t 10
iperf3 -c <server> -t 10 -P 4

# jitter and loss together, on a stream shaped like a call
iperf3 -c <server> -u -b 1M -l 160 -t 10
```

The `ping` summary already carries two of the three: the average is the latency and
the deviation figure is a usable proxy for jitter. The UDP test is the one worth
adding, because it reports jitter and loss as measurements rather than as
impressions, at a packet size and rate close to what a call actually sends.

And run the parallel throughput test alongside the single one. A single stream that
is far slower than four in parallel is telling you the constraint is the transport,
the window or the loss rate rather than the link.

## What trips people up

### 1. Reporting one number for a path

Capacity, delay, variation and loss are four different qualities and a path can be
excellent in some and unusable in others. A link described as "fine, it is a gigabit"
has answered one of the four questions.

### 2. Expecting more bandwidth to fix delay

It does not reduce distance, it does not reduce variation, and it does not fix loss.
Only queueing delay improves when a link stops being full, which is topic 75's
problem rather than this one.

### 3. Reading an average round trip as call quality

The average can be excellent while the variation around it is enough to miss playout
slots. Jitter is a separate number and it is the one voice cares about.

### 4. Treating a late packet as a slow packet

For anything with a deadline they are the same thing. A packet that arrives after the
moment it was needed is discarded, and the listener hears the same gap as if it had
never arrived.

### 5. Dismissing one percent loss

One percent took ninety-three percent of a TCP transfer's throughput in the
measurement above. The sender's own counters show nothing wrong, which is why this
one survives so long.

### 6. Measuring a path with a single stream

One TCP connection over a long or lossy path reports far less than the path can
carry. Testing with several in parallel separates a transport limit from a link
limit.

## Work it through

The call that breaks up while the file transfer is fine.

Start by accepting both reports, because they are both accurate and the instinct to
find out which user is wrong wastes the first hour. Two applications on one path can
disagree completely, and the fact that they disagree is itself the most useful clue
available: it eliminates every fault that would affect both, which is most of them. A
saturated link, a duplex mismatch, a failing transceiver and a routing problem all
hurt the file transfer too.

Then measure the three qualities separately rather than testing whether the network
works. Latency and its variation come from a long enough ping to be meaningful,
twenty packets rather than four. Loss and jitter come from a UDP stream shaped like
the traffic that is failing, small packets at a constant rate, which is what makes the
measurement relevant rather than merely present. Throughput comes from a bulk test,
and it will come back healthy, which confirms rather than contradicts everything else.

Then read the pattern. High jitter with low loss and healthy throughput is the
signature in the hook, and it points at variable queueing somewhere on the path,
which usually means a link that is congested part of the time rather than
consistently. Steady loss with healthy jitter points somewhere else entirely, at a
physical problem or a policer discarding traffic above a rate.

And then act on the right layer. Jitter caused by queueing is fixed by keeping the
queue short and by giving the call's packets priority when the link is full, not by
buying capacity that will fill up the same way. That is the same conclusion topic 75
reached from the other direction, and it is why these two topics are one subject seen
twice.

## Try it

**Ping something far away for a minute.** Twenty packets minimum, and read the
deviation as well as the average. Most people never look at the fourth number in that
line, and it is the one that predicts whether a call across that path will work.

**Run a UDP test at voice size.** Small packets at a constant low rate, and read the
jitter and loss it reports. It takes ten seconds and produces the two numbers that a
capacity test cannot.

**Add loss to a link you own and watch TCP.** In
[`wan-link.sh`](https://github.com/rlwilliamson-dev/azure-resume/blob/main/blog/scripts/topologies/wan-link.sh)
one percent is a single argument to `tc`. Watching a transfer lose most of its speed to
a loss rate you would have called negligible is the fastest cure for calling it
negligible.

## Check yourself

<details class="qa">
<summary>A call breaks up and a file transfer across the same path is fine. Which of them is wrong?</summary>

Neither. A path has several qualities and the two applications care about different
ones. The measurements that matter for a call are jitter and, to a lesser extent,
loss. The measurement that matters for a bulk transfer is throughput, which depends on
capacity, on the window, and heavily on loss.

Variable delay is invisible to a file transfer, because the receiver reassembles in
order and does not care when packets arrived. It is fatal to a call, because audio is
played out at a fixed rate and a packet that misses its moment is discarded whether or
not it eventually turns up.

</details>

<details class="qa">
<summary>Why does a hundred megabit link between continents deliver a few megabits?</summary>

Because throughput is limited by how much data the sender may keep outstanding divided
by the round trip time, and on a long path that number can be far below the link's
capacity.

In the lab, a sender allowed 64 kilobytes in flight over a hundred millisecond round
trip got 6.56 megabits. The same link and the same delay with four megabytes in flight
got 83.2. Nothing about the link changed. Buying more capacity for a path limited this
way changes nothing; the fix is a larger window, more parallel connections, or a
protocol that keeps more outstanding.

</details>

<details class="qa">
<summary>The average round trip is excellent and users say the phones are unusable. What do you measure?</summary>

Jitter, which is the variation around that average and a separate number from it.

In the lab an average that moved from 20 to 28 milliseconds, with zero packet loss and
unchanged throughput, came with jitter rising from 0.178 to 1.968 milliseconds. A
receiver plays audio at a fixed rate, so packets that arrive outside their slot are
discarded even though the network delivered them. A jitter buffer absorbs some of the
variation and pays for it in added delay, so there is a limit to how much it can hide
before the conversation itself becomes awkward.

</details>

<details class="qa">
<summary>What does one percent packet loss do to a TCP transfer, and why?</summary>

It takes most of the throughput. In the measurement above a transfer fell from 74.7
megabits to 4.99, a loss of ninety-three percent of its speed, from dropping one packet
in a hundred.

The cause is congestion control working as designed. TCP treats loss as evidence of
congestion, cuts its sending rate, and rebuilds slowly, so on a path with steady loss it
spends its life recovering rather than transmitting. Nothing on the sending machine
reports an error, which is why a small loss rate survives investigation for so long.

</details>

<details class="qa">
<summary>Why does the same one percent barely affect a voice call?</summary>

Because UDP does not react to loss and the application would not want it to. The stream
keeps sending at its rate, loses whatever the path loses, and a lost packet costs a few
milliseconds of audio.

Asking for a retransmission would make it worse rather than better: the replacement
would arrive long after the moment it was needed, so it could not be played, and the
request would have added traffic to a path that is already dropping things. That is the
trade UDP exists to make, and it is why loss and jitter rank in opposite orders for the
two kinds of traffic.

</details>

## References

- [RFC 3550](https://www.rfc-editor.org/rfc/rfc3550) - IETF, RTP, which defines the jitter calculation that voice tooling reports and the playout model the figure above draws. Free. Accessed 2026-08-19.
- [RFC 5681](https://www.rfc-editor.org/rfc/rfc5681) - IETF, TCP congestion control, the reason a lost packet costs throughput rather than just a retransmission. Free. Accessed 2026-08-19.
- [iperf3 documentation](https://software.es.net/iperf/invoking.html) - ESnet, for the window, UDP and parallel stream options every measurement here uses. Free. Accessed 2026-08-19.

**Where the numbers came from.** Four captured blocks through `netlab.sh` on the kernel
named in each header, on
[`wan-link.sh`](https://github.com/rlwilliamson-dev/azure-resume/blob/main/blog/scripts/topologies/wan-link.sh).
Every delay, variation and loss figure is applied to the link inside the captured command
with `tc`, and every measurement is `ping` or `iperf3` reporting what it observed. The
distance figure for light in fibre is arithmetic on the speed of light in glass rather than
a measurement taken here, and the figure is drawn from RFC 3550's playout model rather than
from a capture.

**If you also work on Linux systems.** [I/O and network performance](/learn/linux-plus/io-and-network-performance)
covers the same three qualities as seen from one machine, where the same symptoms can come
from the disk or the scheduler rather than from the path. The separation of latency,
variation and loss into three measurements is the part that transfers unchanged.
