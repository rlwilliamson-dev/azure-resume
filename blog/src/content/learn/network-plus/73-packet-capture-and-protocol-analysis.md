---
title: "Packet capture and protocol analysis"
description: "The two teams disagree and the packets settle it. The two decisions to make before you start a capture, why a reset and a silence mean opposite things, how two captures at two points name the device that is dropping traffic, and what a capture of nothing still proves."
deck: "The two teams disagree and the packets settle it"
track: "network-plus"
level: "deep"
order: 740
objectives:
  - "Choose a capture point and a filter before starting a capture"
  - "Read a handshake, a reset and a retransmission out of a capture"
  - "Say what a reset proves and what silence does not"
  - "Locate a dropping device by capturing at more than one point"
  - "Explain why a capture tool resolving names costs you packets"
prerequisites: ["flow-data-capture-and-port-mirroring"]
tags: ["network-plus", "networking", "troubleshooting", "tools"]
updated: 2026-08-19
draft: false
examObjectives:
  - exam: "n10-009"
    domain: "5.0"
    objective: "5.5"
sources:
  - title: "tcpdump(1)"
    url: "https://www.tcpdump.org/manpages/tcpdump.1.html"
    publisher: "The Tcpdump Group"
    accessed: 2026-08-19
    tier: 1
  - title: "pcap-filter(7)"
    url: "https://www.tcpdump.org/manpages/pcap-filter.7.html"
    publisher: "The Tcpdump Group"
    accessed: 2026-08-19
    tier: 1
  - title: "RFC 9293, Transmission Control Protocol"
    url: "https://www.rfc-editor.org/rfc/rfc9293"
    publisher: "IETF"
    accessed: 2026-08-19
    tier: 1
  - title: "Packet Monitor (Pktmon)"
    url: "https://learn.microsoft.com/en-us/windows-server/networking/technologies/pktmon/pktmon"
    publisher: "Microsoft"
    accessed: 2026-08-19
    tier: 1
symptoms:
  - symptom: "A connection is refused immediately rather than timing out"
    anchor: "three-answers-a-port-can-give"
  - symptom: "Traffic leaves one machine and never arrives at the other"
    anchor: "when-nothing-is-on-the-wire"
  - symptom: "Two teams disagree about whether traffic was sent"
    anchor: "the-two-decisions-before-you-start"
---

> **Before you read.** The application team says their server never receives the
> request. The network team says the network is not blocking anything. Both have
> looked at their own logs and both are certain.
>
> This has been going on for two days and nobody has produced any evidence that
> the other side accepts.
>
> **How do you end this argument today?**

A packet capture is the only tool in this track that produces evidence nobody can
argue with. Every other measurement is a device reporting on itself. A capture is
what actually crossed a wire, and it settles questions of the form "did it get
there" permanently, which is why it is worth being able to take one and read the
four things that matter.

### Some words you will need

<dl class="terms">
<dt>capture point</dt>
<dd>Where you are listening. A capture only ever shows what passed one interface, which is the single most important thing about it.</dd>
<dt>capture filter</dt>
<dd>What you tell the tool to keep. Applied before anything is stored, which is what makes a capture on a busy machine possible at all.</dd>
<dt>reset</dt>
<dd>A packet meaning "there is nothing here". An answer, sent by the far end, and therefore proof it was reached.</dd>
<dt>retransmission</dt>
<dd>The same data sent again because nothing acknowledged it. Visible as repeats with the same sequence number.</dd>
<dt>silence</dt>
<dd>Nothing coming back at all. Ambiguous on its own, which is why it needs a second capture point.</dd>
</dl>

## What breaks without this

**An argument runs for days.** Two teams reading their own logs will never agree,
because each set of logs is a device's opinion of itself and neither covers the
space between them.

**A capture is taken and shows nothing useful.** On a busy machine an unfiltered
capture fills a disk in minutes and is unreadable afterwards, so the tool gets
blamed for a decision the operator made.

**Silence gets read as a firewall.** No reply is the most ambiguous result
available and it is routinely reported as proof of blocking, which is a guess
wearing evidence's clothes.

## The two decisions before you start

Two things decide whether a capture is useful and both are made before the tool
runs.

**Where you capture** is the first, and it is the one people think about least. A
capture shows what crossed one interface. Capture on the client and you learn what
the client sent and what came back, which is exactly the half of the argument the
client's own logs already told you. Capture on the server and you learn what
arrived. **The useful captures are the ones that answer a question neither side can
answer alone**, and the shape of that is almost always more than one capture point,
which is the section after next.

**What you filter** is the second. A capture filter is applied before packets are
stored, so it is what makes capturing on a busy machine possible: filter to one
host, one port, or one protocol, and a capture that would have been gigabytes is a
few hundred packets you can read. Filtering afterwards does not help, because by
then you have already dropped packets you could not store fast enough.

The habit worth building is to write the filter as narrowly as the question allows.
"Anything to or from that server, on that port" is nearly always narrow enough, and
it is specific enough to hand to somebody else.

<details class="deeper">
<summary>If you already capture on production systems: the third decision, which is when to stop</summary>

Where and what are the two decisions people know about. The one that causes trouble is how
long, because a capture left running is a capture that fills something.

An unbounded capture writing to a file on the machine you are debugging will eventually fill
its disk, and a full disk on a production system is a larger incident than the one you were
investigating. That is a genuinely common way to turn a performance problem into an outage,
and it happens because the capture was started during an urgent moment and nobody set a
limit.

Every capture tool offers bounds and they are worth using by default rather than by
exception: a maximum file size, a maximum number of packets, a ring of files that overwrites
the oldest, or a duration after which it stops. A ring buffer is the right answer for an
intermittent fault, because it keeps the most recent window continuously and can be left
running for days without growing.

The related discipline is to write somewhere other than the system disk, and to know how
much the interface can generate. A busy link filling a file at line rate produces gigabytes
per minute, and the difference between a bounded capture and an unbounded one on that link
is a few minutes.

</details>

## Reading a handshake

Here is a capture of a working connection, taken on the client, filtered to one
host. The topology is
[`trace-path.sh`](https://github.com/rlwilliamson-dev/azure-resume/blob/main/blog/scripts/topologies/trace-path.sh).

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology trace-path
# a capture on the client, watching one conversation with a port that is listening
$ ip netns exec h1 timeout 6 tcpdump -l -n -i h1-r1 "tcp and host 10.0.4.2" > /tmp/ok.txt 2>&1 &
$ sleep 1
$ ip netns exec h1 curl -s -o /dev/null -m 3 http://10.0.4.2:8000/
$ sleep 6
$ grep -v "^tcpdump\|^listening\|packets \|^$" /tmp/ok.txt | head -5 | sed -E "s/, options.*//"
15:43:55.494524 IP 10.0.1.2.45392 > 10.0.4.2.8000: Flags [S], seq 1710909388, win 64240
15:43:55.494630 IP 10.0.4.2.8000 > 10.0.1.2.45392: Flags [S.], seq 1266292120, ack 1710909389, win 65160
15:43:55.494643 IP 10.0.1.2.45392 > 10.0.4.2.8000: Flags [.], ack 1, win 251
15:43:55.494722 IP 10.0.1.2.45392 > 10.0.4.2.8000: Flags [P.], seq 1:78, ack 1, win 251
15:43:55.494738 IP 10.0.4.2.8000 > 10.0.1.2.45392: Flags [.], ack 78, win 255
```

Five lines and the whole shape of a TCP connection is in them. The flags are the
part to read.

**`[S]`** is a connection request. The client is asking.

**`[S.]`** is that request being accepted. The dot is an acknowledgement, so this
single packet both accepts and asks in return, which is why the handshake is three
packets rather than four.

**`[.]`** on its own is a bare acknowledgement. The third packet of the handshake
is one, and so is most of what follows in any transfer.

**`[P.]`** is data, with the push flag set. Line four is 77 bytes leaving the
client, which is the request itself, and line five is the server acknowledging it.

Once those four are familiar, a capture stops being a wall of text. Topic 09 covered
what the handshake is for; this is what it looks like when you are the one holding
the evidence.

<details class="deeper">
<summary>If you already read captures: the fields that tell you about the path rather than the hosts</summary>

The flags describe the conversation and two other fields describe the path it crossed,
which is where a capture answers questions no log can.

The time to live on arriving packets is set by the sender to a standard value and
decremented per hop, so the value you see says how many routers the packet crossed. That
is useful twice: a value that changes between packets in one conversation means the path
changed mid-flow, and a value nowhere near the usual starting points suggests something is
rewriting it.

The window field, and how it changes, describes the receiver rather than the network, and
the two together diagnose the throughput problem in topic 76. A sender that has filled the
advertised window and is waiting is limited by the receiver, not the link, and that is
visible directly as a window that shrinks to nothing and stays there. No throughput test
distinguishes those two causes and the capture does.

Timestamps are the third. The gap between a request and its response is the round trip plus
the far end's thinking time, and comparing a captured gap at the client with one at the
server separates the network from the application in a single measurement. That is the
question two teams argue about most often, and it is answerable from two captures taken at
the same moment.

</details>

## Three answers a port can give

Now the reason a capture settles arguments. The same client, the same server, three
ports, and one capture running across all of it.

<details class="predict">
<summary>One client tries three ports on one server: one with a service listening, one with nothing on it, and one that is filtered. What comes back in each case?</summary>

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology trace-path
# one client, one server, three ports, and one capture running over all of it.
# 9000 is filtered on the server, and nothing is listening on 8080
$ ip netns exec h2 iptables -A INPUT -p tcp --dport 9000 -j DROP
$ ip netns exec h1 timeout 12 tcpdump -l -n -i h1-r1 "tcp[tcpflags] & (tcp-syn|tcp-rst) != 0" > /tmp/c.txt 2>&1 &
$ sleep 1
$ ip netns exec h1 curl -s -o /dev/null -m 2 http://10.0.4.2:8000/ ; echo "port 8000, curl exit $?"
port 8000, curl exit 0
$ ip netns exec h1 curl -s -o /dev/null -m 2 http://10.0.4.2:8080/ ; echo "port 8080, curl exit $?"
port 8080, curl exit 7
$ ip netns exec h1 curl -s -o /dev/null -m 4 http://10.0.4.2:9000/ ; echo "port 9000, curl exit $?"
port 9000, curl exit 28
$ sleep 6
$ grep -v "^tcpdump\|^listening\|packets \|^$" /tmp/c.txt | sed -E "s/(seq|ack) [0-9]+/\1 ../g; s/, win.*//" 
15:41:15.162122 IP 10.0.1.2.52208 > 10.0.4.2.8000: Flags [S], seq ..
15:41:15.162238 IP 10.0.4.2.8000 > 10.0.1.2.52208: Flags [S.], seq .., ack ..
15:41:15.176734 IP 10.0.1.2.42242 > 10.0.4.2.8080: Flags [S], seq ..
15:41:15.176783 IP 10.0.4.2.8080 > 10.0.1.2.42242: Flags [R.], seq .., ack ..
15:41:15.185341 IP 10.0.1.2.48254 > 10.0.4.2.9000: Flags [S], seq ..
15:41:16.235711 IP 10.0.1.2.48254 > 10.0.4.2.9000: Flags [S], seq ..
15:41:17.256218 IP 10.0.1.2.48254 > 10.0.4.2.9000: Flags [S], seq ..
15:41:18.282524 IP 10.0.1.2.48254 > 10.0.4.2.9000: Flags [S], seq ..
```

</details>

Three completely different results and each one is conclusive about something
different.

<figure class="learn-figure">
<svg viewBox="0 0 720 215" role="img" aria-labelledby="ans-title" style="width:100%;height:auto;">
<title id="ans-title">Three outcomes of the same connection attempt: a handshake completing, a reset arriving, and nothing coming back at all, with what each one proves about the far end</title>
<g fill="currentColor">
<text x="14" y="20" font-size="11">the same request, three answers, and only two of them are conclusive</text>
<g fill="currentColor" fill-opacity="0.08" stroke="currentColor" stroke-opacity="0.7">
<rect x="20" y="45" width="60" height="26" rx="4"/>
<rect x="300" y="45" width="70" height="26" rx="4"/>
<rect x="20" y="103" width="60" height="26" rx="4"/>
<rect x="300" y="103" width="70" height="26" rx="4"/>
<rect x="20" y="161" width="60" height="26" rx="4"/>
<rect x="300" y="161" width="70" height="26" rx="4"/>
</g>
<text x="50" y="62" text-anchor="middle" font-size="9.5">client</text>
<text x="50" y="120" text-anchor="middle" font-size="9.5">client</text>
<text x="50" y="178" text-anchor="middle" font-size="9.5">client</text>
<text x="335" y="62" text-anchor="middle" font-size="9.5">server</text>
<text x="335" y="120" text-anchor="middle" font-size="9.5">server</text>
<text x="335" y="178" text-anchor="middle" font-size="9.5">server</text>
<g stroke="currentColor" stroke-opacity="0.7" stroke-width="1.4" fill="none">
<path d="M 84 49 H 292 M 286 45 l 8 4 l -8 4"/>
<path d="M 84 107 H 292 M 286 103 l 8 4 l -8 4"/>
<path d="M 84 165 H 292 M 286 161 l 8 4 l -8 4"/>
<path d="M 296 67 H 88 M 94 63 l -8 4 l 8 4"/>
</g>
<g stroke="var(--red)" stroke-width="1.6" fill="none">
<path d="M 296 125 H 88 M 94 121 l -8 4 l 8 4"/>
<path d="M 244 176 l 12 14 M 256 176 l -12 14"/>
</g>
<text x="188" y="42" text-anchor="middle" font-size="9">SYN</text>
<text x="188" y="84" text-anchor="middle" font-size="9">SYN, ACK</text>
<text x="188" y="100" text-anchor="middle" font-size="9">SYN</text>
<text x="188" y="142" text-anchor="middle" font-size="9" fill="var(--red)">RST</text>
<text x="188" y="158" text-anchor="middle" font-size="9">SYN, and again, and again</text>
<text x="150" y="202" text-anchor="middle" font-size="9" fill="var(--red)">nothing comes back</text>
<text x="400" y="52" font-size="9.5" fill-opacity="0.9">the path works both ways</text>
<text x="400" y="66" font-size="9.5" fill-opacity="0.9">and something is listening</text>
<text x="400" y="110" font-size="9.5" fill-opacity="0.9">the path works both ways</text>
<text x="400" y="124" font-size="9.5" fill-opacity="0.9">and nothing is on that port</text>
<text x="400" y="168" font-size="9.5" fill-opacity="0.9">a filter, a dead host or a</text>
<text x="400" y="182" font-size="9.5" fill-opacity="0.9">broken path. this cannot say</text>
</g></svg>
<figcaption>The middle row is the one worth internalising, because a reset feels like a failure and is actually the most informative of the three. Something at that address received the request, decided nothing was listening on that port, and said so, which means the whole path works in both directions and the fault is one service on one machine. The bottom row is the opposite: repeated requests with no answer at all is the least informative outcome available, consistent with a filter, with a host that is switched off, and with a path that is broken somewhere in the middle. Reading silence as proof of a firewall is the most common wrong conclusion drawn from a capture.</figcaption>
</figure>

Read the capture against the figure and the exit codes line up. Port 8000 answered
with `[S.]` and `curl` exited zero. Port 8080 answered with `[R.]`, a reset, and
`curl` exited 7, which is its code for a refused connection. Port 9000 produced four
identical requests over four seconds and no reply at all, and `curl` exited 28, which
is its code for a timeout.

**The client's exit code was telling you the same thing the whole time.** Refused
means something answered. Timed out means nothing did. The capture is what makes that
distinction impossible to argue with, and it is also what tells you that the four
requests to port 9000 were retransmissions of one request rather than four attempts:
same source port, same conversation, sent again because nothing acknowledged the
first.

## When nothing is on the wire

Silence at one end is ambiguous, and the way out of the ambiguity is more capture
points. This is the technique that ends the argument in the hook.

<details class="predict">
<summary>Something on the path is dropping this traffic. Four captures at four points, taken together. Where do the packets stop?</summary>

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology trace-path
# something on the path is dropping this traffic and nobody will admit to it.
# four captures at four points, all running over the same few seconds
$ ip netns exec r2 iptables -A FORWARD -p tcp --dport 8000 -j DROP
$ ip netns exec h1 timeout 8 tcpdump -l -n -i h1-r1 "tcp port 8000" > /tmp/p1.txt 2>&1 &
$ ip netns exec r2 timeout 8 tcpdump -l -n -i r2-r1 "tcp port 8000" > /tmp/p2.txt 2>&1 &
$ ip netns exec r2 timeout 8 tcpdump -l -n -i r2-r3 "tcp port 8000" > /tmp/p3.txt 2>&1 &
$ ip netns exec h2 timeout 8 tcpdump -l -n -i h2-r3 "tcp port 8000" > /tmp/p4.txt 2>&1 &
$ sleep 1
$ ip netns exec h1 curl -s -o /dev/null -m 3 http://10.0.4.2:8000/ ; echo "curl exit $?"
curl exit 28
$ sleep 8
$ echo "packets leaving h1:      $(grep -c Flags /tmp/p1.txt)"
packets leaving h1:      3
$ echo "packets arriving at r2:  $(grep -c Flags /tmp/p2.txt)"
packets arriving at r2:  3
$ echo "packets leaving r2:      $(grep -c Flags /tmp/p3.txt)"
packets leaving r2:      0
$ echo "packets arriving at h2:  $(grep -c Flags /tmp/p4.txt)"
packets arriving at h2:  0
```

</details>

Four numbers and the fault has a name. Three packets left the client. Three packets
arrived at the middle router. **Nothing left that router**, and nothing arrived at
the server. The traffic entered a device and did not come out of it, so the device is
where it stopped, and nothing else on the path is implicated.

That is the whole method and it generalises to any number of points. **Capture at
two places and the fault is between them. Add points and the gap gets smaller.** With
enough points it is a single device, and at that stage the conversation stops being
about whether the network is blocking anything and starts being about which rule on
which box.

Two practical notes make it work in the real world.

**The captures have to overlap in time**, which sounds obvious and is the usual
mistake. A capture taken at one end on Tuesday and the other on Wednesday cannot be
compared, because the fault may be intermittent and the traffic certainly differed.
Start them together and run the test once.

**Filter both the same way**, so that the counts are comparable. Different filters at
different points produce two numbers that cannot be subtracted, and the entire value
of the technique is in the subtraction.

<details class="deeper">
<summary>If you already take captures: the filter that keeps one usable, and why the tool resolving names costs you packets</summary>

Two habits separate a capture you can read from one that fills a disk.

The first is where the filter goes. A capture filter is applied by the kernel before
anything reaches the tool, so packets that do not match are never copied, never
buffered and never written. A display filter, applied afterwards in a graphical
analyser, hides packets you have already paid to store. On an idle lab machine the
difference does not show. On a busy server the difference is between a capture and
an outage, because an unfiltered capture on a loaded interface will drop packets it
could not write fast enough, and the packets it drops are not marked in any way. So
a capture taken without a filter on a busy host is not merely large, it is
incomplete in a way you cannot see.

The second is the tool's own name resolution, which is on by default and is a
genuinely bad default for troubleshooting. Here is the same conversation captured
twice, once with resolution off and once with it on.

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology trace-path
# the same conversation captured twice. first with names switched off
$ ip netns exec h1 timeout 6 tcpdump -l -n -i h1-r1 "tcp port 8000" > /tmp/a.txt 2>&1 &
$ sleep 1
$ ip netns exec h1 curl -s -o /dev/null -m 3 http://10.0.4.2:8000/
$ sleep 6
$ echo "packets seen with -n:      $(grep -c Flags /tmp/a.txt)"
packets seen with -n:      12
# and again with the tool left to resolve names, which is what it does by default
$ ip netns exec h1 timeout 6 tcpdump -l -i h1-r1 "tcp port 8000" > /tmp/b.txt 2>&1 &
$ sleep 1
$ ip netns exec h1 curl -s -o /dev/null -m 3 http://10.0.4.2:8000/
$ sleep 6
$ echo "packets seen without it:   $(grep -c Flags /tmp/b.txt)"
packets seen without it:   1
```

Twelve packets against one. The same traffic, the same filter, the same three second
window, and the capture with name resolution left on saw one packet and missed the
rest of the conversation, because it stopped to look up an address and the traffic
did not wait.

The lab shows the extreme version, since there is no resolver here for it to ask.
On a network with a working resolver the failure is different and still bad in two
ways. The tool's own lookups are themselves network traffic, so they appear in the
capture you are trying to read, which is a genuinely confusing thing to find when you
are counting packets. And a name is a claim about an address that was true when
somebody last updated a record, so a capture labelled with names can attribute
traffic to a machine that has not had that address for a year. Numbers do not go
stale. Turn resolution off, always, and look up anything you need afterwards.

</details>

## Across platforms

The same job on three platforms, and only Linux and macOS agree on the tool.

| Task | Linux | Windows | macOS |
| --- | --- | --- | --- |
| Capture with a filter | `tcpdump -n -i <if> "<filter>"` | `pktmon filter add` then `pktmon start --capture` | `sudo tcpdump -n -i <if> "<filter>"` |
| Read the capture back | prints as it goes, or `tcpdump -r <file>` | `pktmon etl2txt <file>` | prints as it goes, or `tcpdump -r <file>` |
| Stop resolving names | `-n` | not applicable, it prints addresses | `-n` |

**On macOS** the tool is the same one the lab captures use, with a different interface
name and a `sudo` in front of it. The filter syntax is identical, which means a filter
written for one is a filter for the other.

```bash
# macOS 26.5.2, arm64
$ (for i in 1 2 3 4 5 6 7 8; do curl -s -o /dev/null -m 4 https://1.1.1.1 >/dev/null 2>&1; sleep 1; done) &

# Handshake and reset packets only, which is the filter that answers "did the
# connection open". Eight of them and it stops
$ sudo tcpdump -n -i en0 -c 8 "tcp[tcpflags] & (tcp-syn|tcp-rst) != 0" 2>/dev/null
15:43:57.020447 IP 192.168.64.12.49164 > 1.1.1.1.443: Flags [SEW], seq 1662033679, win 65535, options [mss 1460,nop,wscale 6,nop,nop,TS val 3450124029 ecr 0,sackOK,eol], length 0
15:43:57.035035 IP 1.1.1.1.443 > 192.168.64.12.49164: Flags [S.E], seq 2575838462, ack 1662033680, win 65535, options [mss 1460,sackOK,TS val 3372437157 ecr 3450124029,nop,wscale 13], length 0
15:43:58.169315 IP 192.168.64.12.49165 > 1.1.1.1.443: Flags [SEW], seq 890113573, win 65535, options [mss 1460,nop,wscale 6,nop,nop,TS val 2462889751 ecr 0,sackOK,eol], length 0
15:43:58.180106 IP 1.1.1.1.443 > 192.168.64.12.49165: Flags [S.E], seq 1656354173, ack 890113574, win 65535, options [mss 1460,sackOK,TS val 1894362733 ecr 2462889751,nop,wscale 13], length 0
15:43:58.505263 IP 192.168.64.12.53192 > 17.253.5.153.443: Flags [SEW], seq 3603543061, win 65535, options [mss 1460,nop,wscale 6,nop,nop,TS val 4126454459 ecr 0,sackOK,eol], length 0
15:43:58.532693 IP 192.168.64.12.53193 > 23.199.20.245.443: Flags [SEW], seq 3214318143, win 65535, options [mss 1460,nop,wscale 6,nop,nop,TS val 1704272969 ecr 0,sackOK,eol], length 0
15:43:58.551827 IP 17.253.5.153.443 > 192.168.64.12.53192: Flags [S.E], seq 2386461280, ack 3603543062, win 64980, options [mss 1456,sackOK,TS val 263992222 ecr 4126454459,nop,wscale 9], length 0
15:43:58.576684 IP 23.199.20.245.443 > 192.168.64.12.53193: Flags [S.E], seq 4032555315, ack 3214318144, win 65160, options [mss 1460,sackOK,TS val 214066569 ecr 1704272969,nop,wscale 7], length 0

# The same filter written by name rather than by flag bits, which is what most
# people type and what the manual documents
$ sudo tcpdump -n -i en0 -c 4 "tcp[tcpflags] & tcp-syn != 0 and port 443" 2>/dev/null
15:43:59.098380 IP 192.168.64.12.53194 > 17.253.5.138.443: Flags [SEW], seq 2638729578, win 65535, options [mss 1460,nop,wscale 6,nop,nop,TS val 1161542129 ecr 0,sackOK,eol], length 0
15:43:59.139888 IP 17.253.5.138.443 > 192.168.64.12.53194: Flags [S.E], seq 4161596069, ack 2638729579, win 64980, options [mss 1456,sackOK,TS val 1049265996 ecr 1161542129,nop,wscale 9], length 0
15:43:59.191002 IP 192.168.64.12.53195 > 17.253.5.138.443: Flags [SEW], seq 1604224980, win 65535, options [mss 1460,nop,wscale 6,nop,nop,TS val 3087445655 ecr 0,sackOK,eol], length 0
15:43:59.191315 IP 192.168.64.12.53196 > 17.253.5.138.443: Flags [SEW], seq 2021187143, win 65535, options [mss 1460,nop,wscale 6,nop,nop,TS val 531476540 ecr 0,sackOK,eol], length 0
```

**On Windows** the built-in capture is `pktmon`, which Microsoft documents as
available in the box from build 19041, and which is driven from the command line
rather than from a window. It works differently from tcpdump in a way worth knowing:
filters are added as named objects first, the capture is written to a binary file,
and the file is converted to text afterwards.

```powershell
# Microsoft Windows Server 2025 Datacenter, version 10.0.26100.0
> pktmon filter remove
Removed all filters.

# One filter, so the capture holds a conversation rather than everything
> pktmon filter add WebTraffic -t TCP -p 443
Filter added.

> pktmon filter list
Packet Filters:
     # Name       Protocol Port
     - ----       -------- ----
     1 WebTraffic TCP       443

# Capture to a file, small packets only, because the headers are the interesting part
> pktmon start --capture --pkt-size 128 --file-name $env:TEMP\np.etl --file-size 8
Logger Parameters:
    Logger name:        PktMon
    Logging mode:       Circular
    Log file:           C:\Users\RUNNER~1\AppData\Local\Temp\np.etl
    Max file size:      8 MB
    Memory used:        128 MB
Collected Data:
    Packet counters, packet capture
Capture Type:
    All packets
Monitored Components:
    All
Packet Filters:
     # Name       Protocol Port
     - ----       -------- ----
     1 WebTraffic TCP       443

# Something for it to capture
> Invoke-WebRequest -Uri https://1.1.1.1 -UseBasicParsing -TimeoutSec 10 | Out-Null

> pktmon stop
Flushing logs...
Merging metadata...
Log file: C:\Users\RUNNER~1\AppData\Local\Temp\np.etl (No events lost)

# Turn the binary capture into text
> pktmon etl2txt $env:TEMP\np.etl --out $env:TEMP\np.txt
Processing...
Events formatted:    419
Formatted file:      C:\Users\RUNNER~1\AppData\Local\Temp\np.txt

# The packet lines only, without the trace file's own header. Each packet appears
# once per component it passed through on its way out of the stack
> Get-Content $env:TEMP\np.txt | Select-String "PktMon\]|ethertype" | Select-Object -First 8
[00]0000.0000::2026-08-19 15:48:45.963348000 [Microsoft-Windows-PktMon] PktGroupId 1, PktNumber 1, Appearance 0, Direction Rx , Type Ethernet , Component 4, Edge 1, Filter 1, OriginalSize 66, LoggedSize 66
	12-34-56-78-9A-BC > 7C-1E-52-18-C0-A5, ethertype IPv4 (0x0800), length 66: 1.1.1.1.443 > 10.1.0.132.50037: Flags [S.], seq 41154943, ack 300280912, win 65535, options [mss 1460,nop,nop,sackOK,nop,wscale 13], length 0
[00]0000.0000::2026-08-19 15:48:45.963352800 [Microsoft-Windows-PktMon] PktGroupId 2, PktNumber 1, Appearance 0, Direction Rx , Type Ethernet , Component 24, Edge 1, Filter 1, OriginalSize 66, LoggedSize 66
	12-34-56-78-9A-BC > 7C-1E-52-18-C0-A5, ethertype IPv4 (0x0800), length 66: 1.1.1.1.443 > 10.1.0.132.50037: Flags [S.], seq 41154943, ack 300280912, win 65535, options [mss 1460,nop,nop,sackOK,nop,wscale 13], length 0
[00]0000.0000::2026-08-19 15:48:45.963390600 [Microsoft-Windows-PktMon] PktGroupId 3, PktNumber 1, Appearance 0, Direction Tx , Type Ethernet , Component 24, Edge 1, Filter 1, OriginalSize 54, LoggedSize 54
	7C-1E-52-18-C0-A5 > 12-34-56-78-9A-BC, ethertype IPv4 (0x0800), length 54: 10.1.0.132.50037 > 1.1.1.1.443: Flags [.], ack 41154944, win 255, length 0
[00]0000.0000::2026-08-19 15:48:45.963391700 [Microsoft-Windows-PktMon] PktGroupId 4, PktNumber 1, Appearance 0, Direction Tx , Type Ethernet , Component 4, Edge 1, Filter 1, OriginalSize 54, LoggedSize 54
	7C-1E-52-18-C0-A5 > 12-34-56-78-9A-BC, ethertype IPv4 (0x0800), length 54: 10.1.0.132.50037 > 1.1.1.1.443: Flags [.], ack 41154944, win 255, length 0
```

The exam names "protocol analyzer" as a category rather than naming a product, and
these are two of them. What transfers between platforms is not the tool, it is the
reading: a handshake, a reset, a retransmission and a silence look the same whatever
printed them.

## Prove it

You have this when you can produce, on request, evidence that a specific packet did
or did not cross a specific wire.

```bash
# one conversation, on one interface, with names off
tcpdump -n -i <interface> "host <address> and port <port>"

# just the packets that open and refuse connections, which is the fastest
# way to answer "did it connect"
tcpdump -n -i <interface> "tcp[tcpflags] & (tcp-syn|tcp-rst) != 0"

# to a file, for handing to somebody else or reading in an analyser
tcpdump -n -i <interface> -w /tmp/one-flow.pcap "host <address>"
```

Then check that you can answer three questions from a capture without hedging. Did
the request leave this machine. Did anything answer. And if something answered, was
it an acceptance or a refusal. Those three cover most of what a capture is asked for,
and the second and third are where the argument in the hook actually ends.

## What trips people up

### 1. Capturing in one place

A capture shows one interface. Capturing on the machine whose logs you already have
tells you what those logs told you, which is why the useful captures are the ones with
a second point.

### 2. Reading silence as a firewall

No reply is consistent with a filter, a switched-off host and a broken path. It is the
least informative outcome available and it gets reported as the most specific one.

### 3. Treating a reset as a failure

A reset is an answer, so it proves the whole path works in both directions and narrows
the fault to one service on one machine. It is the best news in this topic.

### 4. Capturing without a filter on a busy machine

The capture will drop packets it could not write fast enough, and nothing marks which
ones. An unfiltered capture on a loaded host is incomplete in a way you cannot detect.

### 5. Leaving name resolution on

It costs packets, adds the tool's own lookups to the capture, and labels addresses with
names that may be a year out of date. In the lab it cost eleven of twelve packets.

### 6. Comparing captures taken at different times

The technique of comparing two points only works if the two captures cover the same
moment and use the same filter. Otherwise the two counts cannot be subtracted, and the
subtraction is the entire point.

## Work it through

The two teams who cannot agree.

Start by refusing to look at either side's logs, because two days of that is what
produced the stalemate. Each set of logs is one device's account of itself, and the
disagreement is about the space between them, which neither device can see. What is
needed is evidence from that space.

Then agree the test before taking it, which is the part that makes the result binding.
One request, at an agreed moment, with an agreed filter, captured at both ends
simultaneously. Both teams know what will be run and what would count as an answer,
so nobody gets to reinterpret the result afterwards.

Then read the two counts. If the request left the client and arrived at the server,
the network has been eliminated and the application team has a server that received
something and did not act on it. If it left and did not arrive, the network is in it
and the next step is to add points until the gap is one device. Either way the
argument ends in one test rather than another day of assertions.

And if the client's capture shows a reset coming back, the answer arrived before you
started: something at that address is reachable and is refusing that port, which is
neither team's original theory and is checkable in a minute on the server itself.

## Try it

**Capture your own handshake.** Any machine, any connection you can make on purpose,
filtered to that one host. Watching `[S]`, `[S.]` and `[.]` go past on something you
initiated is what makes the flags stick.

**Make a reset happen.** Connect to a port on a machine you control with nothing
listening on it. The reset comes back immediately, and seeing it once permanently
separates refused from timed out in your head.

**Run the four point capture.** In
[`trace-path.sh`](https://github.com/rlwilliamson-dev/azure-resume/blob/main/blog/scripts/topologies/trace-path.sh)
the drop is one rule on the middle router. Capturing at four points and counting
packets is a technique you will use on a real network within a month of learning it.

## Check yourself

<details class="qa">
<summary>Two teams disagree about whether requests are reaching a server. What ends it?</summary>

A capture at both ends, taken simultaneously, with the same filter, around one agreed
test. Each team's logs are one device's account of itself and the disagreement is about
the space between the two, which neither device can see.

Agreeing the test before running it is what makes the result binding, because both
sides have said in advance what would count as an answer. If the packet left one end
and arrived at the other, the network is eliminated. If it left and did not arrive,
adding capture points narrows the gap until it is one device.

</details>

<details class="qa">
<summary>A connection attempt gets an immediate reset. What does that prove?</summary>

That the path works in both directions and something at that address is alive and
reachable. A reset is an answer, so it could only have been produced by a device that
received the request and sent a reply that got back.

What it narrows the fault to is one service on one machine: nothing is listening on
that port. That is much better news than it sounds, and it is why a refused connection
is more informative than a timeout even though it feels more like a failure.

</details>

<details class="qa">
<summary>A connection attempt gets nothing back at all. What does that prove?</summary>

Very little on its own, which is the point. Silence is consistent with a filter
dropping the traffic, with a host that is switched off, and with a path that is broken
somewhere in the middle, and one capture cannot tell you which.

The repeats are worth noticing: several identical requests from the same source port
are one connection attempt being retransmitted rather than several attempts. Getting
from silence to an answer means capturing at a second point, and the fault is between
the last point that saw the packet and the first that did not.

</details>

<details class="qa">
<summary>Why capture with a filter rather than capturing everything and filtering later?</summary>

Because a capture filter is applied by the kernel before packets are stored, so
anything that does not match is never copied or written. Filtering afterwards only
hides packets you have already paid to keep.

On a busy machine that difference decides whether the capture is complete. An
unfiltered capture on a loaded interface drops packets it could not write fast enough,
and nothing in the resulting file marks which ones went missing, so you get a capture
that looks whole and is not.

</details>

<details class="qa">
<summary>Why turn off name resolution in a capture tool?</summary>

Three reasons and the first is the one that surprises people. Looking up a name takes
time, and while the tool is waiting the traffic does not. In the lab the same three
second window produced twelve packets with resolution off and one with it on.

The other two matter on real networks. The tool's own lookups are network traffic, so
they turn up in the capture you are trying to read. And a name reflects whatever a
record said when somebody last updated it, so a capture labelled with names can
confidently attribute traffic to a machine that gave up that address a year ago.

</details>

## References

- [tcpdump(1)](https://www.tcpdump.org/manpages/tcpdump.1.html) - The Tcpdump Group, for the flags in the output and the options that control name resolution and output detail. Free. Accessed 2026-08-19.
- [pcap-filter(7)](https://www.tcpdump.org/manpages/pcap-filter.7.html) - The Tcpdump Group, the filter language every capture on this page uses, and the same language on macOS. Free. Accessed 2026-08-19.
- [RFC 9293](https://www.rfc-editor.org/rfc/rfc9293) - IETF, TCP, for what the flags mean and why a reset is an answer rather than a failure. Free. Accessed 2026-08-19.
- [Packet Monitor](https://learn.microsoft.com/en-us/windows-server/networking/technologies/pktmon/pktmon) - Microsoft, for what the Windows built-in capture does and which build ships it. Free. Accessed 2026-08-19.

**Where the numbers came from.** Four captured blocks through `netlab.sh` on the kernel
named in each header, on
[`trace-path.sh`](https://github.com/rlwilliamson-dev/azure-resume/blob/main/blog/scripts/topologies/trace-path.sh),
with every fault created in the captured command by an iptables rule so the block that
produces the symptom is on the page next to it. The Windows and macOS blocks are real
machines through the capture workflow. One line in the handshake capture is trimmed with
`sed` to drop the TCP options, which is shown in the command rather than done afterwards.

**If you also work on Linux systems.** The tool here is the same `tcpdump` the Linux+
track uses, and the filter language is shared with macOS. What is specific to this topic is
the technique rather than the tool: two capture points and one subtraction, which is how a
question about the network stops being a matter of opinion.
