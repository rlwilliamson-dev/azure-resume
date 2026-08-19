---
title: "Ping, traceroute and what they prove"
description: "Ping fails and the server is serving traffic perfectly. What an echo actually tests and what it does not, how traceroute finds each hop by letting a packet die there, why loss at a hop is not loss to the end, and why a failed test proves far less than a successful one."
deck: "Ping fails and the server is serving traffic perfectly"
track: "network-plus"
level: "working"
order: 630
objectives:
  - "Say what ICMP echo tests and what it does not"
  - "Explain how traceroute finds each hop, and read its output honestly"
  - "Distinguish loss at a hop from loss to the end"
  - "Explain why a successful test proves more than a failed one"
  - "Recognise path MTU discovery and why traceroute differs by platform"
prerequisites: ["the-osi-model"]
tags: ["network-plus", "networking", "troubleshooting", "tools"]
updated: 2026-08-19
draft: false
examObjectives:
  - exam: "n10-009"
    domain: "5.0"
    objective: "5.5"
sources:
  - title: "RFC 792, Internet Control Message Protocol"
    url: "https://www.rfc-editor.org/rfc/rfc792"
    publisher: "IETF"
    accessed: 2026-08-19
    tier: 1
  - title: "RFC 1191, Path MTU Discovery"
    url: "https://www.rfc-editor.org/rfc/rfc1191"
    publisher: "IETF"
    accessed: 2026-08-19
    tier: 1
  - title: "traceroute(8)"
    url: "https://man7.org/linux/man-pages/man8/traceroute.8.html"
    publisher: "man7.org"
    accessed: 2026-08-19
    tier: 1
symptoms:
  - symptom: "Ping fails but the host is serving traffic normally"
    anchor: "what-ping-tests-and-what-it-does-not"
  - symptom: "A traceroute hop times out while later hops respond"
    anchor: "loss-at-a-hop-is-not-loss-to-the-end"
---

> **Before you read.** A monitoring alert says a server is down. Ping it and every
> packet is lost, a hundred percent. The server is up, logged in, and serving its
> application to thousands of users at that exact moment.
>
> **Ping says down and the server is up. Which one is lying?**

Neither. Ping answered the question it was asked, which is not the question you
thought you asked. This topic is the two tools everyone reaches for first and the
gap between what they seem to prove and what they actually prove, which is where
most wasted troubleshooting time goes.

### Some words you will need

<dl class="terms">
<dt>ICMP echo</dt>
<dd>The request and reply that ping uses. A separate protocol from the traffic an application sends, and filtered separately.</dd>
<dt>TTL</dt>
<dd>Time to live: a counter in every packet, decremented by one at each router. At zero the packet is dropped and the router says so.</dd>
<dt>time exceeded</dt>
<dd>The message a router sends back when it drops a packet whose TTL hit zero. Traceroute is built entirely on it.</dd>
<dt>round trip</dt>
<dd>Out and back. A successful ping proves the whole loop; a failed one does not say which half broke.</dd>
<dt>path MTU</dt>
<dd>The largest packet that fits through every link on a path, set by the smallest link on it.</dd>
</dl>

## What breaks without this

**A working service is declared down.** Ping tests ICMP echo, which a host or a
firewall can drop while serving everything else, so a failed ping is read as an
outage that is not happening.

**A traceroute hop is blamed for a fault it does not have.** A router that does not
answer traceroute still forwards traffic perfectly, and reading its star as the
problem sends you after the wrong device.

**A failed test is trusted like a passed one.** They are not equal. A successful
ping proves a great deal; a failed ping proves almost nothing on its own, and
treating them as symmetric is the core mistake this topic exists to remove.

## What ping tests, and what it does not

Ping sends an ICMP echo request and waits for an echo reply. That is the whole of
it, and the trap is in the word ICMP: echo is its own protocol, separate from the
TCP and UDP an application uses, and it is filtered separately. A host that drops
ICMP, or a firewall in front of it that does, will fail every ping while the
application behind it works perfectly, because the application is not made of
ICMP.

The lab shows it directly. A host is told to drop ping and nothing else, and then
asked the two questions side by side. The topology is
[`trace-path.sh`](https://github.com/rlwilliamson-dev/azure-resume/blob/main/blog/scripts/topologies/trace-path.sh).

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology trace-path
# h2 drops ping, the way a hardened host or the firewall in front of one often
# does. nothing else about the host changes
$ ip netns exec h2 iptables -A INPUT -p icmp --icmp-type echo-request -j DROP
$ ip netns exec h1 ping -c2 -W1 10.0.4.2 | grep -E "bytes from|packet loss"
2 packets transmitted, 0 received, 100% packet loss, time 1005ms
$ ip netns exec h1 curl -s -o /dev/null -w "the web server on 10.0.4.2:8000 answered %{http_code}\n" http://10.0.4.2:8000/
the web server on 10.0.4.2:8000 answered 200
```

The ping is a hundred percent lost and the web server on the same host answers
`200` in the same breath. The host is not down. It is not answering ICMP, which is
a different sentence, and the alert that read the first as the second was wrong.
This is the single most common false alarm in network monitoring, and knowing that
ping tests only ICMP is the whole of the cure.

So a failed ping is not evidence a host is down. It is evidence that an ICMP echo
did not complete, which could be the host being down, or ICMP being filtered
anywhere on the path, or the reply being dropped on the way back. A successful ping,
by contrast, proves the whole round trip works: out, arrival, and back. That
asymmetry, a pass proving much and a fail proving little, is worth holding onto,
because it is true of almost every test in troubleshooting.

## Reading a traceroute honestly

Traceroute shows the path to a destination, one hop at a time, and it does it with
a trick worth understanding, because the trick is why its output can mislead.

Every packet carries a TTL, decremented by one at each router. When it reaches zero
the router drops the packet and sends back a time-exceeded message naming itself.
Traceroute abuses this on purpose: it sends a packet with a TTL of one, which dies
at the first router, and that router's complaint reveals hop one. Then a TTL of two,
which dies at the second router, revealing hop two. And so on, each probe dying one
router further along, until one reaches the destination.

<figure class="learn-figure">
<svg viewBox="0 0 720 262" role="img" aria-labelledby="ttl-title" style="width:100%;height:auto;">
<title id="ttl-title">Traceroute sending three probes with increasing TTL values, each dying one router further along the path and provoking a time-exceeded reply that names that hop</title>
<g fill="currentColor">
<text x="14" y="20" font-size="11">each hop is found by a packet dying exactly one router further along</text>
<rect x="24" y="40" width="70" height="30" rx="4" fill="currentColor" fill-opacity="0.1" stroke="currentColor" stroke-opacity="0.7"/>
<text x="59" y="59" text-anchor="middle" font-size="10">h1</text>
<circle cx="250" cy="55" r="16" fill="currentColor" fill-opacity="0.06" stroke="currentColor" stroke-opacity="0.7"/>
<text x="250" y="59" text-anchor="middle" font-size="10">r1</text>
<circle cx="430" cy="55" r="16" fill="currentColor" fill-opacity="0.06" stroke="currentColor" stroke-opacity="0.7"/>
<text x="430" y="59" text-anchor="middle" font-size="10">r2</text>
<rect x="600" y="40" width="90" height="30" rx="4" fill="currentColor" fill-opacity="0.1" stroke="currentColor" stroke-opacity="0.7"/>
<text x="645" y="59" text-anchor="middle" font-size="10">h2</text>
<line x1="94" y1="55" x2="234" y2="55" stroke="currentColor" stroke-opacity="0.4" stroke-width="1.2"/>
<line x1="266" y1="55" x2="414" y2="55" stroke="currentColor" stroke-opacity="0.4" stroke-width="1.2"/>
<line x1="446" y1="55" x2="600" y2="55" stroke="currentColor" stroke-opacity="0.4" stroke-width="1.2"/>
<text x="14" y="108" font-size="10" fill-opacity="0.8">ttl 1</text>
<path d="M 60 118 H 238" stroke="currentColor" stroke-opacity="0.75" stroke-width="1.6" fill="none"/>
<path d="M 250 112 l 8 6 l -8 6 M 244 112 l 12 6 l -12 6" stroke="var(--accent)" stroke-width="1.8" fill="none"/>
<text x="270" y="122" font-size="9.5" fill="var(--accent)">dies at r1, r1 answers: hop 1</text>
<text x="14" y="152" font-size="10" fill-opacity="0.8">ttl 2</text>
<path d="M 60 162 H 418" stroke="currentColor" stroke-opacity="0.75" stroke-width="1.6" fill="none"/>
<path d="M 430 156 l 8 6 l -8 6 M 424 156 l 12 6 l -12 6" stroke="var(--accent)" stroke-width="1.8" fill="none"/>
<text x="450" y="166" font-size="9.5" fill="var(--accent)">dies at r2, r2 answers: hop 2</text>
<text x="14" y="196" font-size="10" fill-opacity="0.8">ttl 3</text>
<path d="M 60 206 H 598" stroke="currentColor" stroke-opacity="0.75" stroke-width="1.6" fill="none"/>
<path d="M 600 200 l 8 6 l -8 6" stroke="currentColor" stroke-opacity="0.7" stroke-width="1.6" fill="none"/>
<text x="360" y="240" font-size="9.5" fill-opacity="0.8">reaches h2, which answers: the path is complete</text>
</g></svg>
<figcaption>Traceroute does not track a packet along the path. It sends one probe per hop, each with a TTL one larger than the last, so each dies a router further along and that router's time-exceeded reply names it. Hop one is found by a packet built to die at the first router. This is why a hop can go missing without the path breaking: if a router declines to send the time-exceeded that would reveal it, that hop shows nothing, and the probes for the hops beyond it sail straight through and answer normally.</figcaption>
</figure>

A clean run against the lab's four-hop path looks like the path itself.

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology trace-path
# every hop from h1 to h2, counted
$ ip netns exec h1 traceroute -n -q1 10.0.4.2
traceroute to 10.0.4.2 (10.0.4.2), 30 hops max, 60 byte packets
 1  10.0.1.1  0.105 ms
 2  10.0.12.2  0.042 ms
 3  10.0.23.2  0.042 ms
 4  10.0.4.2  0.038 ms
```

Four hops, each naming a router, then the destination. The times are the round trip
to that hop, not the time between hops, which is a common misreading: a jump in the
numbers is a slow link somewhere before that hop, not necessarily at it.

## Loss at a hop is not loss to the end

Here is the misreading the TTL trick sets up, and it is worth seeing on purpose.

A router can forward traffic perfectly and still decline to answer traceroute,
because generating time-exceeded messages is low-priority work a busy router
deprioritises or a policy suppresses. When that happens, its hop shows a star, and
the untrained read is that the path breaks there. It does not. The lab makes one
router drop exactly the message traceroute depends on, and changes nothing else.

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology trace-path
# r2 is told not to answer the probe traceroute relies on: the time-exceeded it
# sends when a packet ttl runs out. it still forwards every packet normally
$ ip netns exec r2 iptables -A OUTPUT -p icmp --icmp-type time-exceeded -j DROP
$ ip netns exec h1 traceroute -n -q1 -w1 10.0.4.2
traceroute to 10.0.4.2 (10.0.4.2), 30 hops max, 60 byte packets
 1  10.0.1.1  0.113 ms
 2  *
 3  10.0.23.2  0.035 ms
 4  10.0.4.2  0.033 ms
```

Hop two is a star and hops three and four answer normally. If the path were broken
at hop two, nothing beyond it could reply, because nothing beyond it could be
reached. The star is not a break, it is a router being quiet, and the proof is that
the hops behind it are fine. Loss at a single hop that clears by the next hop is the
signature of a router that does not answer traceroute, not of a fault. Loss that
starts at a hop and continues to the end is the one that matters.

<details class="deeper">
<summary>If you already work on networks: finding the narrow link with a forbidden-fragment ping, and why traceroute differs by platform</summary>

Two details separate someone who runs these tools from someone who reads them.

The first is path MTU, and ping can find it. A link narrower than the usual 1500
bytes, a tunnel or a carrier segment, will silently shrink the largest packet a path
can carry, and the symptom is maddening: small things work, large ones hang, because
a full-size packet cannot get through and nobody said so. Ping can locate it by
sending a large packet with the don't-fragment bit set, so that instead of being cut
up at the narrow link it is dropped, and the router that dropped it reports the size
that would have fit.

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology trace-path
# the r2-to-r3 link is narrowed to 1400 bytes, as a tunnel or a carrier link
# often is without anyone saying so
$ ip netns exec r2 ip link set r2-r3 mtu 1400
$ ip netns exec r3 ip link set r3-r2 mtu 1400
$ ip netns exec h1 ping -c1 -W1 10.0.4.2 | grep -E "bytes from"
64 bytes from 10.0.4.2: icmp_seq=1 ttl=61 time=0.131 ms
$ ip netns exec h1 ping -M do -s 1400 -c1 -W1 10.0.4.2
PING 10.0.4.2 (10.0.4.2) 1400(1428) bytes of data.
From 10.0.12.2 icmp_seq=1 Frag needed and DF set (mtu = 1400)

--- 10.0.4.2 ping statistics ---
1 packets transmitted, 0 received, +1 errors, 100% packet loss, time 0ms
```

The router says the packet must be no larger than 1400, which is the narrow link's
MTU, discovered rather than guessed. RFC 1191 is this mechanism, and a great deal of
"it works for small files and hangs on large ones" is a path MTU problem that this
one ping would have found.

The second is that traceroute is not one tool. The Linux and macOS versions send UDP
probes to high ports by default; the Windows tracert sends ICMP echo. That is not
cosmetic. A firewall that permits one and drops the other will let the same path
trace cleanly on one platform and time out completely on another, which the cross
platform section below shows happening for real. When a trace fails, the protocol it
used is part of the diagnosis, and running a second tool that probes differently is
often the fastest way to tell a real break from a filtered probe.

</details>

## Across platforms

The two tools are on every platform, spelled and flagged differently, and the
difference between a filtered probe and a dead host is the same everywhere.

**On Linux**, the tools are `ping` and `traceroute`, the second sending UDP probes
by default. The don't-fragment ping is `ping -M do -s <size>`, which is the form the
lab captures above use.

**On macOS**, `ping` and `traceroute` again, with BSD flags. traceroute still sends
UDP, so a path that traces on macOS traces the same way on Linux.

```bash
# macOS 26.5.2, arm64
$ ping -c 2 1.1.1.1
PING 1.1.1.1 (1.1.1.1): 56 data bytes
64 bytes from 1.1.1.1: icmp_seq=0 ttl=50 time=12.979 ms
64 bytes from 1.1.1.1: icmp_seq=1 ttl=50 time=13.518 ms

--- 1.1.1.1 ping statistics ---
2 packets transmitted, 2 packets received, 0.0% packet loss
round-trip min/avg/max/stddev = 12.979/13.248/13.518/0.270 ms

# The path to a host, hop by hop, not resolving names, capped so it stays short.
# traceroute sends UDP probes by default, unlike Windows tracert
$ traceroute -n -q 1 -m 8 1.1.1.1
traceroute to 1.1.1.1 (1.1.1.1), 8 hops max, 40 byte packets
 1  *
 2  100.83.129.106  0.946 ms
 3  100.83.129.29  0.770 ms
 4  10.9.16.109  0.643 ms
 5  100.83.229.77  0.914 ms
 6  10.106.0.66  0.642 ms
 7  51.10.15.37  11.383 ms
 8  51.10.39.217  67.070 ms
```

**On Windows**, the trace tool is `tracert`, not traceroute, and it probes with ICMP.
That difference is not academic: the machine below sits on a network that filters
ICMP, so ping and tracert fail on a host that is plainly up, and `Test-NetConnection`
proves it by reaching the same host over TCP.

```powershell
# Microsoft Windows Server 2025 Datacenter, version 10.0.26100.0
> ping -n 2 1.1.1.1
Pinging 1.1.1.1 with 32 bytes of data:
Request timed out.
Request timed out.
Ping statistics for 1.1.1.1:
    Packets: Sent = 2, Received = 0, Lost = 2 (100% loss),

# The same host, asked whether its TCP service answers. Ping and the TCP test can
# disagree, and this is where you find out they are different questions
> Test-NetConnection 1.1.1.1 -Port 443 | Format-List ComputerName, RemoteAddress, RemotePort, PingSucceeded, TcpTestSucceeded
ComputerName     : 1.1.1.1
RemoteAddress    : 1.1.1.1
RemotePort       : 443
PingSucceeded    : False
TcpTestSucceeded : True

# The path to a host, hop by hop, not resolving names, capped so it stays short
> tracert -d -h 8 1.1.1.1
Tracing route to 1.1.1.1 over a maximum of 8 hops
  1     *        *        *     Request timed out.
  2     *        *        *     Request timed out.
  3     *        *        *     Request timed out.
  4     *        *        *     Request timed out.
  5     *        *        *     Request timed out.
  6     *        *        *     Request timed out.
  7     *        *        *     Request timed out.
  8     *        *        *     Request timed out.
Trace complete.
```

That Windows capture is the whole topic in one screen. `PingSucceeded: False` and
`TcpTestSucceeded: True`, on the same host, at the same moment, because the network
filters the ICMP that ping and tracert use and permits the TCP the service runs on.
The macOS machine reaches `1.1.1.1` in thirteen milliseconds, so the host is not
down. The ping is answering a question about ICMP, and it always was.

## Prove it

The four terminal blocks against the lab are the whole of it, from
[`trace-path.sh`](https://github.com/rlwilliamson-dev/azure-resume/blob/main/blog/scripts/topologies/trace-path.sh),
and the cross platform captures come from real Windows and macOS machines through the
capture workflow. The pairing is the point: the netlab shows the fault built on
purpose, and the Windows runner shows the same lesson happening by accident on the
public internet.

**RFC 792.** The ICMP specification, and worth reading for one realisation: echo and
time-exceeded are the same protocol, which is why a firewall that filters ICMP breaks
ping and traceroute together while leaving TCP untouched.

**traceroute(8).** The manual, for the flag that changes the probe protocol. Knowing
that Linux and macOS default to UDP and Windows to ICMP, and that you can switch, is
what lets you tell a filtered probe from a real break by asking twice, differently.

## What trips people up

### 1. Reading a failed ping as a down host

Ping tests ICMP echo, which is filtered separately from everything else. A failed
ping means an echo did not complete, which includes the host being down and several
things that are not.

### 2. Trusting a fail as much as a pass

A successful ping proves the whole round trip. A failed one proves almost nothing on
its own. They are not symmetric, and treating them as equal is the core error.

### 3. Blaming a starred traceroute hop

A router that does not answer traceroute still forwards traffic. A single starred hop
whose neighbours answer is a quiet router, not a break.

### 4. Reading traceroute times as per-hop

Each time is the round trip to that hop, not the gap between hops. A jump is slowness
somewhere before that point, not proof the slow link is at it.

### 5. Missing a path MTU problem

Small things working and large ones hanging is the signature. A don't-fragment ping
finds the narrow link and reports its size; nothing else will tell you as directly.

### 6. Assuming traceroute is one tool

Linux and macOS send UDP, Windows sends ICMP. A firewall that treats them differently
makes the same path trace on one platform and fail on another, so the tool is part of
the result.

## Work it through

The alert that says a server is down, worked honestly.

First, ask what ping actually told you, which is that an ICMP echo did not complete.
That is not the same as the host being down, and the fastest way to find out which it
is takes one more test: reach the service the way its users do, over its real port and
protocol. If that works, as the lab's web server does while ping fails, the host is up
and the alert is wrong about what it measured.

Then, if the service is also unreachable, use traceroute to find where the path stops,
and read it honestly. A single starred hop with live neighbours is a quiet router, not
the fault. Loss that begins at a hop and continues to the end is the fault, and its
location is the last hop that answered.

Then, if small things work and large ones hang, suspect path MTU before anything
exotic, and settle it with a don't-fragment ping that reports the narrow link's size.
It is a five-second test for a problem that otherwise looks like intermittent
application failure.

Then remember the platform, because the tool is part of the answer. If a trace fails on
Windows, its ICMP probe may be filtered where a UDP probe would pass, and running the
other tool is often the difference between a filtered probe and a real break. A failed
test is a question, not a verdict.

## Try it

**Run the lab and drop ICMP yourself.** In
[`trace-path.sh`](https://github.com/rlwilliamson-dev/azure-resume/blob/main/blog/scripts/topologies/trace-path.sh)
the one command that makes ping fail while the service works is a single iptables rule.
Adding it and then reaching the web server is what makes "ping only tests ICMP" concrete.

**Trace the same public host on two platforms.** From a Mac or Linux box and from a
Windows one, trace the same address. If one succeeds and one times out, you have found a
network that filters ICMP, which is exactly the Windows capture above.

**Find a path's MTU.** Ping a distant host with the don't-fragment bit set and a large
size, and lower the size until it goes through. The largest size that passes, plus the
headers, is the path MTU, discovered the way RFC 1191 describes.

## Check yourself

<details class="qa">
<summary>Ping fails and the server is serving its application normally. How?</summary>

Ping tests ICMP echo, which is a separate protocol from the TCP or UDP the application
uses, and it is filtered separately. The host, or a firewall in front of it, is dropping
ICMP while forwarding everything else, so every ping is lost and every application request
succeeds.

The host is not down. The ping is answering a question about ICMP echo, not about the
service, which is why reaching the service over its real port, as the lab's web server
shows, settles it in one more test.

</details>

<details class="qa">
<summary>Why does a successful ping prove more than a failed one?</summary>

A successful ping completed the whole round trip: the request reached the host and the
reply came back, so the path works in both directions and the host answered. That is a lot
of information.

A failed ping only says an echo did not complete, which could be the host down, ICMP
filtered anywhere along the path, or the reply dropped on the way back. The pass is
specific and the fail is ambiguous, so trusting them equally is the mistake.

</details>

<details class="qa">
<summary>A traceroute shows a star at hop two, and hops three and four answer normally. What does that mean?</summary>

That the router at hop two is forwarding traffic but not answering traceroute. It means the
path is not broken there, because if it were, nothing beyond it could be reached and hops
three and four could not answer.

Generating the time-exceeded message traceroute depends on is low-priority or policy-suppressed
work that a router can decline while forwarding perfectly. A single quiet hop with live
neighbours is normal. Loss that starts at a hop and continues to the end is the real fault.

</details>

<details class="qa">
<summary>Small files transfer fine and large ones hang. What do you test, and how?</summary>

Path MTU. A link somewhere on the path is narrower than 1500 bytes, so full-size packets
cannot get through while small ones can, and nothing announces it.

Send a large ping with the don't-fragment bit set. Instead of being fragmented at the narrow
link, the packet is dropped, and the router that dropped it reports the size that would have
fit, which is the path MTU. The lab shows a router replying that the packet must be no larger
than 1400.

</details>

<details class="qa">
<summary>The same path traces cleanly on macOS and times out entirely on Windows. Why?</summary>

Because the tools probe with different protocols. Linux and macOS traceroute send UDP by
default; Windows tracert sends ICMP echo. A firewall on the path that permits UDP probes and
drops ICMP will let the trace complete on macOS and fail on Windows, with nothing wrong with
the path itself.

This is why the probe protocol is part of the diagnosis. A trace that fails with one tool and
succeeds with another has told you the path is fine and a filter is selective, not that the
path is broken.

</details>

## References

- [RFC 792](https://www.rfc-editor.org/rfc/rfc792) - IETF, the ICMP specification, and the source of the point that echo and time-exceeded are one protocol filtered as one. Free. Accessed 2026-08-19.
- [RFC 1191](https://www.rfc-editor.org/rfc/rfc1191) - IETF, path MTU discovery, the mechanism the don't-fragment ping uses. Free. Accessed 2026-08-19.
- [traceroute(8)](https://man7.org/linux/man-pages/man8/traceroute.8.html) - man7.org, the manual and the flag that changes the probe protocol. Free. Accessed 2026-08-19.

**Where the numbers came from.** The four lab blocks are from
[`trace-path.sh`](https://github.com/rlwilliamson-dev/azure-resume/blob/main/blog/scripts/topologies/trace-path.sh)
through `netlab.sh`, on the kernel in each header. The faults are made in the captured
commands with `iptables` and an MTU change, so the break is visible rather than baked in.
The Windows and macOS blocks are real machines through the capture workflow, headed with each
one's version; the Windows runner's network filters ICMP, which is why ping and tracert fail
there while `Test-NetConnection` reaches the host over TCP.

**If you also work on Linux.** Everything above is the Linux tools already: `ping` with `-M do`
for the don't-fragment probe, and `traceroute` sending UDP. The one thing to carry to the other
platforms is that the trace tool's default protocol changes, so a trace that fails is also a
statement about which protocol was filtered.
