---
title: "Flow data, capture and port mirroring"
description: "Counters tell you how much. Flow data tells you who. Packet capture tells you what, at a price you cannot pay for long. Plus where a mirror sits, what that means it cannot show you, and the half of a conversation people lose without noticing."
deck: "You need to know who is using the bandwidth, not how much is being used"
track: "network-plus"
level: "working"
order: 400
objectives:
  - "Say what a flow record contains and what it discards"
  - "Choose between flow data and packet capture for a given question"
  - "Explain where a tap sits and where a mirror sits, and what follows from that"
  - "Say why a mirror can show half a conversation"
  - "Describe what sampling gains and what it hides"
prerequisites: ["snmp"]
tags: ["network-plus", "networking", "monitoring"]
updated: 2026-08-12
draft: false
examObjectives:
  - exam: "n10-009"
    domain: "3.0"
    objective: "3.2"
sources:
  - title: "RFC 7011, Specification of the IPFIX Protocol"
    url: "https://www.rfc-editor.org/rfc/rfc7011"
    publisher: "IETF"
    accessed: 2026-08-12
    tier: 1
  - title: "RFC 3954, Cisco Systems NetFlow Services Export Version 9"
    url: "https://www.rfc-editor.org/rfc/rfc3954"
    publisher: "IETF"
    accessed: 2026-08-12
    tier: 1
  - title: "RFC 5475, Sampling and Filtering Techniques for IP Packet Selection"
    url: "https://www.rfc-editor.org/rfc/rfc5475"
    publisher: "IETF"
    accessed: 2026-08-12
    tier: 1
  - title: "tcpdump and libpcap"
    url: "https://www.tcpdump.org/manpages/tcpdump.1.html"
    publisher: "The Tcpdump Group"
    accessed: 2026-08-12
    tier: 1
symptoms:
  - symptom: "The link is full and nobody knows what is filling it"
    anchor: "one-conversation-kept-two-ways"
  - symptom: "A capture shows requests and no replies"
    anchor: "where-each-one-sits"
  - symptom: "A monitoring report misses a burst that definitely happened"
    anchor: "sampling"
---

> **Before you read.** A 1 Gbit link between two sites has been running at 94
> per cent since Tuesday. The graph is unambiguous and it has been unambiguous
> for three days.
>
> Nobody can say what the traffic is. The graph is built from interface
> counters, and a counter is one number.
>
> **What would you have needed to be collecting before Tuesday, and what would
> you turn on now?**

Topic 38 covered how a device is asked how much. This topic is about the harder
question, which is who and what, and the two answers to it that cost very
different amounts.

### Some words you will need

<dl class="terms">
<dt>flow</dt>
<dd>One conversation, identified by its addresses, ports and protocol.</dd>
<dt>flow record</dt>
<dd>A summary row for one flow: who, to whom, how many packets, how many bytes.</dd>
<dt>packet capture</dt>
<dd>Every byte of every frame, written down.</dd>
<dt>port mirror</dt>
<dd>A switch copying traffic from one port to another so something can watch it.</dd>
<dt>tap</dt>
<dd>A device in the cable itself, passing traffic through and sending a copy sideways.</dd>
<dt>sampling</dt>
<dd>Recording one packet in every n rather than all of them.</dd>
</dl>

## What breaks without this

**A full link stays unexplained.** The counter says 94 per cent and no counter has
ever said what the traffic was.

**A capture answers the wrong question.** Somebody records four hours of a busy
link to find out who the top talker is, fills a disk, and gets an answer that a
flow record would have given from data already collected.

**A capture shows half a conversation.** Requests and no replies, which reads as a
broken server and is a mirror configured in one direction.

## One conversation, kept two ways

Both methods watch the same traffic. What separates them is what they throw away.

<figure class="learn-figure">
<svg viewBox="0 0 720 262" role="img" aria-labelledby="flowrec-title" style="width:100%;height:auto;">
<title id="flowrec-title">One TCP conversation of ten packets and 40528 bytes, reduced by flow accounting to a single row of seven fields, and kept by packet capture as all ten packets and every byte</title>
<g fill="currentColor">
<text x="14" y="22" font-size="11">one conversation, kept two ways</text>
<text x="14" y="52" font-size="10.5" fill-opacity="0.8">on the wire</text>
<rect x="110" y="42" width="9" height="24" fill="currentColor" fill-opacity="0.5"/>
<rect x="119" y="42" width="29" height="24" fill="currentColor" fill-opacity="0.12" stroke="currentColor" stroke-opacity="0.4"/>
<rect x="154" y="42" width="9" height="24" fill="currentColor" fill-opacity="0.5"/>
<rect x="163" y="42" width="29" height="24" fill="currentColor" fill-opacity="0.12" stroke="currentColor" stroke-opacity="0.4"/>
<rect x="198" y="42" width="9" height="24" fill="currentColor" fill-opacity="0.5"/>
<rect x="207" y="42" width="29" height="24" fill="currentColor" fill-opacity="0.12" stroke="currentColor" stroke-opacity="0.4"/>
<rect x="242" y="42" width="9" height="24" fill="currentColor" fill-opacity="0.5"/>
<rect x="251" y="42" width="29" height="24" fill="currentColor" fill-opacity="0.12" stroke="currentColor" stroke-opacity="0.4"/>
<rect x="286" y="42" width="9" height="24" fill="currentColor" fill-opacity="0.5"/>
<rect x="295" y="42" width="29" height="24" fill="currentColor" fill-opacity="0.12" stroke="currentColor" stroke-opacity="0.4"/>
<rect x="330" y="42" width="9" height="24" fill="currentColor" fill-opacity="0.5"/>
<rect x="339" y="42" width="29" height="24" fill="currentColor" fill-opacity="0.12" stroke="currentColor" stroke-opacity="0.4"/>
<rect x="374" y="42" width="9" height="24" fill="currentColor" fill-opacity="0.5"/>
<rect x="383" y="42" width="29" height="24" fill="currentColor" fill-opacity="0.12" stroke="currentColor" stroke-opacity="0.4"/>
<rect x="418" y="42" width="9" height="24" fill="currentColor" fill-opacity="0.5"/>
<rect x="427" y="42" width="29" height="24" fill="currentColor" fill-opacity="0.12" stroke="currentColor" stroke-opacity="0.4"/>
<rect x="462" y="42" width="9" height="24" fill="currentColor" fill-opacity="0.5"/>
<rect x="471" y="42" width="29" height="24" fill="currentColor" fill-opacity="0.12" stroke="currentColor" stroke-opacity="0.4"/>
<rect x="506" y="42" width="9" height="24" fill="currentColor" fill-opacity="0.5"/>
<rect x="515" y="42" width="29" height="24" fill="currentColor" fill-opacity="0.12" stroke="currentColor" stroke-opacity="0.4"/>
<text x="560" y="50" font-size="10.5">10 packets</text>
<text x="560" y="66" font-size="10.5">40 528 bytes</text>
<text x="14" y="132" font-size="10.5" fill-opacity="0.8">flow data</text>
<rect x="110" y="112" width="84" height="30" rx="2" fill="currentColor" fill-opacity="0.1" stroke="currentColor" stroke-opacity="0.45"/>
<text x="152" y="104" text-anchor="middle" font-size="9.5" fill-opacity="0.7">src</text>
<text x="152" y="132" text-anchor="middle" font-size="10">10.0.0.11</text>
<rect x="194" y="112" width="84" height="30" rx="2" fill="currentColor" fill-opacity="0.1" stroke="currentColor" stroke-opacity="0.45"/>
<text x="236" y="104" text-anchor="middle" font-size="9.5" fill-opacity="0.7">dst</text>
<text x="236" y="132" text-anchor="middle" font-size="10">203.0.113.9</text>
<rect x="278" y="112" width="84" height="30" rx="2" fill="currentColor" fill-opacity="0.1" stroke="currentColor" stroke-opacity="0.45"/>
<text x="320" y="104" text-anchor="middle" font-size="9.5" fill-opacity="0.7">sport</text>
<text x="320" y="132" text-anchor="middle" font-size="10">52764</text>
<rect x="362" y="112" width="84" height="30" rx="2" fill="currentColor" fill-opacity="0.1" stroke="currentColor" stroke-opacity="0.45"/>
<text x="404" y="104" text-anchor="middle" font-size="9.5" fill-opacity="0.7">dport</text>
<text x="404" y="132" text-anchor="middle" font-size="10">80</text>
<rect x="446" y="112" width="84" height="30" rx="2" fill="currentColor" fill-opacity="0.1" stroke="currentColor" stroke-opacity="0.45"/>
<text x="488" y="104" text-anchor="middle" font-size="9.5" fill-opacity="0.7">proto</text>
<text x="488" y="132" text-anchor="middle" font-size="10">tcp</text>
<rect x="530" y="112" width="84" height="30" rx="2" fill="currentColor" fill-opacity="0.1" stroke="currentColor" stroke-opacity="0.45"/>
<text x="572" y="104" text-anchor="middle" font-size="9.5" fill-opacity="0.7">packets</text>
<text x="572" y="132" text-anchor="middle" font-size="10">10</text>
<rect x="614" y="112" width="84" height="30" rx="2" fill="currentColor" fill-opacity="0.1" stroke="currentColor" stroke-opacity="0.45"/>
<text x="656" y="104" text-anchor="middle" font-size="9.5" fill-opacity="0.7">bytes</text>
<text x="656" y="132" text-anchor="middle" font-size="10">40528</text>
<text x="110" y="164" font-size="10" fill-opacity="0.75">one row, about 60 bytes. header fields only, and the payload is gone</text>
<text x="14" y="222" font-size="10.5" fill-opacity="0.8">capture</text>
<rect x="110" y="202" width="9" height="24" fill="currentColor" fill-opacity="0.5"/>
<rect x="119" y="202" width="29" height="24" fill="currentColor" fill-opacity="0.35" stroke="currentColor" stroke-opacity="0.4"/>
<rect x="154" y="202" width="9" height="24" fill="currentColor" fill-opacity="0.5"/>
<rect x="163" y="202" width="29" height="24" fill="currentColor" fill-opacity="0.35" stroke="currentColor" stroke-opacity="0.4"/>
<rect x="198" y="202" width="9" height="24" fill="currentColor" fill-opacity="0.5"/>
<rect x="207" y="202" width="29" height="24" fill="currentColor" fill-opacity="0.35" stroke="currentColor" stroke-opacity="0.4"/>
<rect x="242" y="202" width="9" height="24" fill="currentColor" fill-opacity="0.5"/>
<rect x="251" y="202" width="29" height="24" fill="currentColor" fill-opacity="0.35" stroke="currentColor" stroke-opacity="0.4"/>
<rect x="286" y="202" width="9" height="24" fill="currentColor" fill-opacity="0.5"/>
<rect x="295" y="202" width="29" height="24" fill="currentColor" fill-opacity="0.35" stroke="currentColor" stroke-opacity="0.4"/>
<rect x="330" y="202" width="9" height="24" fill="currentColor" fill-opacity="0.5"/>
<rect x="339" y="202" width="29" height="24" fill="currentColor" fill-opacity="0.35" stroke="currentColor" stroke-opacity="0.4"/>
<rect x="374" y="202" width="9" height="24" fill="currentColor" fill-opacity="0.5"/>
<rect x="383" y="202" width="29" height="24" fill="currentColor" fill-opacity="0.35" stroke="currentColor" stroke-opacity="0.4"/>
<rect x="418" y="202" width="9" height="24" fill="currentColor" fill-opacity="0.5"/>
<rect x="427" y="202" width="29" height="24" fill="currentColor" fill-opacity="0.35" stroke="currentColor" stroke-opacity="0.4"/>
<rect x="462" y="202" width="9" height="24" fill="currentColor" fill-opacity="0.5"/>
<rect x="471" y="202" width="29" height="24" fill="currentColor" fill-opacity="0.35" stroke="currentColor" stroke-opacity="0.4"/>
<rect x="506" y="202" width="9" height="24" fill="currentColor" fill-opacity="0.5"/>
<rect x="515" y="202" width="29" height="24" fill="currentColor" fill-opacity="0.35" stroke="currentColor" stroke-opacity="0.4"/>
<text x="560" y="210" font-size="10.5">10 packets</text>
<text x="560" y="226" font-size="10.5">40 528 bytes</text>
<text x="110" y="248" font-size="10" fill-opacity="0.75">every frame kept whole, headers and payload together</text>
</g></svg>
<figcaption>The same forty kilobytes, recorded two ways. The dark block at the front of each frame is the header and the lighter block behind it is the payload, and flow accounting keeps only the first: the addresses, the ports, the protocol, and a running count of what went past. Everything else is discarded as it arrives, which is what makes the method affordable. A year of flow records for a busy network fits on one disk, and an hour of full capture on the same link frequently does not. That is the whole trade, and it decides the method before any question about accuracy does.</figcaption>
</figure>

**A flow record is a summary of one conversation.** The five fields that identify
it are the source and destination addresses, the source and destination ports and
the protocol, which topic 09 introduced as the four-tuple with the protocol added.
Alongside them the device keeps counters.

Linux keeps exactly this table on any machine doing connection tracking, and it
prints in the same shape a flow exporter would send.

<details class="predict">
<summary>One conversation, kept as flow records instead of packets. What does a record hold, and what has been thrown away to make it that small?</summary>

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology nat-gateway
# byte and packet counters are off by default, and they have to be on before the
# conversation starts, because the counter is allocated with the entry
$ ip netns exec nat sh -c "echo 1 > /proc/sys/net/netfilter/nf_conntrack_acct"
$ (ip netns exec srv timeout 14 nc -l -k -p 80 > /dev/null 2>&1 &)
$ sleep 1
$ ip netns exec h1 sh -c "head -c 40000 /dev/zero | nc -w 2 -q 1 203.0.113.9 80"
$ ip netns exec h2 sh -c "head -c 900 /dev/zero | nc -w 2 -q 1 203.0.113.9 80"
$ ip netns exec h1 ping -c 3 -q 203.0.113.9 > /dev/null
# every conversation the gateway has seen, and what each one moved
$ ip netns exec nat conntrack -L 2>/dev/null | grep -v unknown | sed "s/ secctx=[^ ]*//"
tcp      6 116 TIME_WAIT src=10.0.0.12 dst=203.0.113.9 sport=51108 dport=80 packets=5 bytes=1168 src=203.0.113.9 dst=203.0.113.1 sport=80 dport=51108 packets=3 bytes=164 [ASSURED] mark=0 use=1
tcp      6 115 TIME_WAIT src=10.0.0.11 dst=203.0.113.9 sport=52764 dport=80 packets=10 bytes=40528 src=203.0.113.9 dst=203.0.113.1 sport=80 dport=52764 packets=8 bytes=424 [ASSURED] mark=0 use=1
icmp     1 29 src=10.0.0.11 dst=203.0.113.9 type=8 code=0 id=70 packets=3 bytes=252 src=203.0.113.9 dst=203.0.113.1 type=0 code=0 id=70 packets=3 bytes=252 mark=0 use=1
```

</details>

Three conversations, three rows. The second one moved 40 528 bytes in ten packets
one way and 424 bytes in eight the other, which is the shape of somebody uploading
something. The first moved 1 168 bytes. The third is a ping.

**That is enough to answer the question at the top of the page** and it is not
enough to answer the next one. There is no indication of what was uploaded, which
is what a capture would have. Each row also carries both the inside and the
outside form of the addresses, because this gateway is doing the translation topic
25 covered, and a flow exporter on a device doing NAT has the same choice to make
about which pair it reports.

**Two things the exam's vocabulary is worth being precise about.** The objectives
say flow data, and name no product. NetFlow, sFlow and IPFIX are the three names
you will meet in the field, and none of them appear in the objectives text, so a
question is far more likely to describe what flow data is for than to ask which
vendor invented which. The other is that a flow is a one way thing in most
implementations, so a conversation is normally two records, which is why the
capture above shows the counters for each direction separately.

## Where each one sits

Getting traffic to a machine that can record it is the part people skip, and it is
where the mistakes are.

<figure class="learn-figure">
<svg viewBox="0 0 720 328" role="img" aria-labelledby="tapmirror-title" style="width:100%;height:auto;">
<title id="tapmirror-title">A tap drawn in the cable between two devices, passing every bit through to the analyser, against a mirror drawn inside a switch, which can only copy the frames the switch chose to forward</title>
<g fill="currentColor">
<text x="14" y="22" font-size="11">where each one sits, which is what decides what it can miss</text>
<text x="14" y="56" font-size="10.5" fill-opacity="0.85">tap</text>
<rect x="70" y="68" width="76" height="34" rx="2" fill="currentColor" fill-opacity="0.1" stroke="currentColor" stroke-opacity="0.55"/>
<text x="108" y="89" text-anchor="middle" font-size="10.5">device a</text>
<rect x="560" y="68" width="76" height="34" rx="2" fill="currentColor" fill-opacity="0.1" stroke="currentColor" stroke-opacity="0.55"/>
<text x="598" y="89" text-anchor="middle" font-size="10.5">device b</text>
<line x1="146" y1="85" x2="300" y2="85" stroke="currentColor" stroke-opacity="0.6" stroke-width="1.6"/>
<line x1="380" y1="85" x2="560" y2="85" stroke="currentColor" stroke-opacity="0.6" stroke-width="1.6"/>
<rect x="300" y="70" width="80" height="30" rx="2" fill="currentColor" fill-opacity="0.2" stroke="currentColor" stroke-opacity="0.8" stroke-width="1.6"/>
<text x="340" y="89" text-anchor="middle" font-size="10">tap</text>
<line x1="340" y1="100" x2="340" y2="136" stroke="currentColor" stroke-opacity="0.6" stroke-width="1.4"/>
<path d="M 340 140 l -4 -8 l 8 0 z" fill="currentColor"/>
<rect x="286" y="140" width="108" height="28" rx="2" fill="none" stroke="currentColor" stroke-opacity="0.55" stroke-dasharray="5 3"/>
<text x="340" y="158" text-anchor="middle" font-size="10">analyser</text>
<text x="410" y="128" font-size="10" fill-opacity="0.8">no power, no configuration,</text>
<text x="410" y="144" font-size="10" fill-opacity="0.8">nothing to oversubscribe</text>
<text x="14" y="212" font-size="10.5" fill-opacity="0.85">mirror</text>
<rect x="70" y="224" width="76" height="34" rx="2" fill="currentColor" fill-opacity="0.1" stroke="currentColor" stroke-opacity="0.55"/>
<text x="108" y="245" text-anchor="middle" font-size="10.5">device a</text>
<rect x="560" y="224" width="76" height="34" rx="2" fill="currentColor" fill-opacity="0.1" stroke="currentColor" stroke-opacity="0.55"/>
<text x="598" y="245" text-anchor="middle" font-size="10.5">device b</text>
<line x1="146" y1="241" x2="304" y2="241" stroke="currentColor" stroke-opacity="0.6" stroke-width="1.6"/>
<line x1="376" y1="241" x2="560" y2="241" stroke="currentColor" stroke-opacity="0.6" stroke-width="1.6"/>
<circle cx="340" cy="241" r="36" fill="currentColor" fill-opacity="0.1" stroke="currentColor" stroke-opacity="0.6"/>
<path d="M 322 232 L 358 232 M 350 226 L 358 232 L 350 238" fill="none" stroke="currentColor" stroke-opacity="0.75" stroke-width="1.3"/>
<path d="M 358 250 L 322 250 M 330 244 L 322 250 L 330 256" fill="none" stroke="currentColor" stroke-opacity="0.75" stroke-width="1.3"/>
<line x1="340" y1="277" x2="340" y2="288" stroke="var(--red)" stroke-width="1.4" stroke-dasharray="4 3"/>
<path d="M 340 292 l -4 -8 l 8 0 z" fill="var(--red)"/>
<rect x="286" y="292" width="108" height="26" rx="2" fill="none" stroke="currentColor" stroke-opacity="0.55" stroke-dasharray="5 3"/>
<text x="340" y="309" text-anchor="middle" font-size="10">analyser</text>
<text x="410" y="278" font-size="10" fill="var(--red)">a copy of what the switch forwarded,</text>
<text x="410" y="294" font-size="10" fill="var(--red)">in the direction you configured,</text>
<text x="410" y="310" font-size="10" fill="var(--red)">dropped first when the port is full</text>
</g></svg>
<figcaption>The tap is part of the cable and the mirror is part of the switch, and every difference between them follows from those two positions. A tap sees the signal, so a frame with a bad checksum reaches the analyser as a frame with a bad checksum. A mirror sees the switch's decisions, so that frame was discarded at ingress and no copy of it was ever made. The same logic explains the oversubscription problem: two gigabit ports mirrored into one gigabit port is two gigabits arriving at a one gigabit exit, and the copies are what the switch drops, silently, because they were never anybody's traffic.</figcaption>
</figure>

**A tap goes in the cable.** The link is broken and the tap is inserted into it, so
everything passing between the two devices passes through the tap, and a copy goes
out of a monitor port. On fibre it is a piece of glass that splits the light with
no power supply and no software, which is why a tap in place is one fewer thing
that can be misconfigured during an incident.

<figure class="learn-figure photo">

![An opened white fibre optic splitter tray sitting on a wooden bench. Two black spools of coiled fibre are mounted inside the tray, with thin fibres routed around them and into the back of six blue SC connectors mounted in a row along the front edge. Orange and yellow patch leads plug into three of the six ports and coil away across the bench. The tray has no power connector.](./images/fibre-optic-tap.jpg)

<figcaption>A passive optical tap with its lid off. The two spools are splitters: light arriving on the input port is divided, most of it continuing out to the far end and a fraction diverted to the monitor port. The six ports are two independent taps, one for each direction of a fibre pair, which is why monitoring a single duplex link uses two of them and why a tap gives you both directions without anybody configuring anything. Note what is not in the picture. There is no power lead, no management port and no processor, so there is nothing here to fail during an incident, nothing to log into, and nothing that can decide not to copy something. The trade is written into the physics: the light going to the monitor port is light that no longer reaches the far end, so a tap is chosen with a split ratio and the link has to have the loss budget for it. Photograph by Roens, <a href="https://creativecommons.org/licenses/by-sa/4.0/">CC BY-SA 4.0</a>.</figcaption>
</figure>

**A mirror is a switch feature.** The switch is told to copy traffic from one or
more ports to another port, and the analyser plugs into that. Nothing is inserted
into a cable and nothing goes down, which is why this is what people actually use.

The cost is that a mirror is a copy of a decision. It shows what the switch chose
to forward, in the direction you asked for, when it had capacity to make the copy.

**That middle clause is the one that catches people.** Mirroring is configured per
direction on most equipment, and configuring one of them is easy to do without
realising.

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology managed-lan
# mirror one direction only: frames arriving from the user port
$ ip netns exec sw1 tc qdisc add dev sw1-user handle ffff: ingress
$ ip netns exec sw1 tc filter add dev sw1-user parent ffff: matchall action mirred egress mirror dev sw1-collector
$ (ip netns exec collector timeout 6 tcpdump -i collector0 -n -c 8 icmp > /tmp/one.txt 2>/dev/null &)
$ sleep 1
$ ip netns exec user ping -c 2 -i 0.3 -q 10.0.0.20 | tail -2
2 packets transmitted, 2 received, 0% packet loss, time 307ms
rtt min/avg/max/mdev = 0.096/0.140/0.184/0.044 ms
$ sleep 6
$ cat /tmp/one.txt
16:49:21.551024 IP 10.0.0.30 > 10.0.0.20: ICMP echo request, id 83, seq 1, length 64
16:49:21.858371 IP 10.0.0.30 > 10.0.0.20: ICMP echo request, id 83, seq 2, length 64


# now mirror the other direction as well: frames the switch sends to the user port
$ ip netns exec sw1 tc qdisc add dev sw1-user handle 1: root prio
$ ip netns exec sw1 tc filter add dev sw1-user parent 1: matchall action mirred egress mirror dev sw1-collector
$ (ip netns exec collector timeout 6 tcpdump -i collector0 -n -c 8 icmp > /tmp/two.txt 2>/dev/null &)
$ sleep 1
$ ip netns exec user ping -c 2 -i 0.3 -q 10.0.0.20 | tail -2
2 packets transmitted, 2 received, 0% packet loss, time 302ms
rtt min/avg/max/mdev = 0.074/0.092/0.110/0.018 ms
$ sleep 6
$ cat /tmp/two.txt
16:49:28.885673 IP 10.0.0.30 > 10.0.0.20: ICMP echo request, id 100, seq 1, length 64
16:49:28.885710 IP 10.0.0.20 > 10.0.0.30: ICMP echo reply, id 100, seq 1, length 64
16:49:29.187642 IP 10.0.0.30 > 10.0.0.20: ICMP echo request, id 100, seq 2, length 64
16:49:29.187685 IP 10.0.0.20 > 10.0.0.30: ICMP echo reply, id 100, seq 2, length 64
```

Both pings succeeded. Two packets sent, two received, zero loss, in both halves of
that transcript.

**The first capture shows requests and no replies.** The replies existed, the
sender got them, and the analyser never saw one, because the mirror was watching
frames arriving at that port and not frames leaving it. The second capture, after
the other direction is added, shows the conversation as it always was.

Read that first block cold, without the ping result next to it, and it describes a
server that is not answering. That is the diagnosis it invites, it is wrong, and
the fault is in the instrument.

<details class="deeper">
<summary>If you already work on networks: sampling, what it does to a burst, and why an oversubscribed mirror lies in the direction that matters</summary>

Flow accounting on a busy device costs something per packet, so most
implementations offer sampling: look at one packet in every n, and multiply.
RFC 5475 is the framework for describing which packets get selected.

The arithmetic works and the intuition does not. At one in a thousand, a
conversation of ten million packets is estimated from ten thousand samples and the
estimate is good. A conversation of two hundred packets is estimated from zero
samples about eighty per cent of the time, and from one sample, reported as a
thousand packets, most of the rest.

So sampling is accurate for exactly the traffic that was already obvious and
useless for the traffic somebody is usually hunting. A port scan is small packets
to many destinations, a beacon is a few hundred bytes every few minutes, and
neither survives being sampled. If the question is which application is filling
the link, sample freely. If the question is whether anything unusual is talking to
the internet, sampling is what will hide it.

**The mirror oversubscription case has the same shape and is worse**, because
nothing reports it. Mirroring two ports carrying six hundred megabits each into
one gigabit port asks the switch to send 1.2 gigabits out of a one gigabit
interface. It sends what fits and discards the rest, and the discards are copies
rather than traffic, so no counter anybody watches goes up and no alarm fires.

The result is a capture that is quietly incomplete, and it is incomplete in the
worst possible way: it drops most heavily during the busiest moments, which are
the moments somebody set up the capture to look at. A capture taken during an
incident on an oversubscribed mirror will under-report exactly the traffic that
caused the incident. This is the strongest argument for a tap on any link that
genuinely matters, and it is worth being able to make in a meeting, because the
mirror is free and the tap is not.

One practical consequence: check the mirror destination port's speed against the
sum of the speeds of everything you mirrored into it, and if the sum is larger,
say so in writing before anybody draws conclusions from the capture.

</details>

## Choosing, in one page

The three methods answer different questions, and the mistake is nearly always
reaching for the heaviest one first.

**Counters answer how much.** They come from the interface itself over SNMP, they
cost almost nothing, and they are what every bandwidth graph is made of. They can
never say who.

**Flow data answers who and how much.** It is a summary per conversation, it is
cheap enough to keep for a year, and it is the right answer to almost every
question that starts with what is filling the link. It cannot say what was in the
traffic, and increasingly it could not tell you anyway, because the contents are
encrypted.

**Capture answers what.** It is the only method that shows the actual bytes, it is
the only method that can prove a protocol did something specific, and it is far
too expensive to leave running. It is a tool you point at a problem you have
already narrowed down.

The order matters because it is the order of cost. Counters find the link, flow
data finds the conversation, and a capture is what you take once you know which
conversation to record.

## Across platforms

Capturing packets needs no purchase on any of the three, which surprises people
who have been told to install something.

**On Linux**, `tcpdump` is a package away and is what every capture on this page
used. Wireshark's `tshark` is the same job with more decoding.

**On macOS**, tcpdump is part of the base system, and the kernel offers something
Linux does not.

```bash
# macOS 26.5.2, arm64
$ tcpdump --version 2>&1 | head -2
tcpdump version 4.99.1 -- Apple version 158
libpcap version 1.10.1

# The interfaces it can be pointed at
$ sudo tcpdump -D | head -3
1.en0 [Up, Running, Connected]
2.utun0 [Up, Running]
3.utun1 [Up, Running]

# And the one that is not an interface, straight out of the shipped manual
$ man tcpdump 2>/dev/null | col -b | grep -i "pktap" | head -3
	      one may use "pktap" as the interface parameter followed by an
		     tcpdump -i pktap,lo0,en0
	      An interface argument of "all" or "pktap,all" can be used to
```

**On Windows**, the capture engine has shipped in the operating system since
Windows 10 1809 and Windows Server 2019, and hardly anybody knows.

```powershell
# Microsoft Windows Server 2025 Datacenter, version 10.0.26100.0
> Get-Command pktmon | Select-Object Name, Version | Format-Table -AutoSize
Name       Version
----       -------
PktMon.exe 10.0.26100.7309

# What it can attach to, which is components rather than only interfaces
> pktmon list | Select-Object -First 8
Network Adapters:
   Id MAC Address       Name
   -- -----------       ----
    3 00-0D-3A-5C-45-AE Mellanox ConnectX-4 Lx Virtual Ethernet Adapter
   37 00-15-5D-31-44-75 vEthernet (nat)
   38 00-0D-3A-5C-45-AE Microsoft NetVsc Nic #3
```

The Windows one is worth a second look, because it attaches to components rather
than to interfaces. That includes virtual switches and the layers of the network
stack, so it can capture at a point inside a virtualised host where no cable
exists to put a tap on.

## Prove it

**Look at the flow table on a machine you own.** Any Linux box doing NAT has one:
`conntrack -L`, or `cat /proc/net/nf_conntrack`. Read a few rows and identify the
five fields that make each one a distinct conversation.

**Capture a conversation you started.** Run `tcpdump -i any -w /tmp/t.pcap port
443`, load one page, stop it, and look at the file size. Then work out what that
size becomes over a working day at a hundred times the traffic.

**Set up a mirror if you have a managed switch.** Then send a ping through it and
check whether you can see both directions. On a lot of equipment the default is
one direction and the menu does not make that obvious.

## What trips people up

### 1. Reaching for a capture when the question is who

Capture answers what was in the traffic. Who is sending it is a flow question, and
the flow data is frequently already being collected.

### 2. Believing a mirror shows everything the port saw

It shows what the switch forwarded, in the configured direction, when it had
capacity to copy. Frames dropped at ingress for errors were never copied.

### 3. Mirroring one direction and diagnosing the far end

Requests with no replies looks like a server not answering. Check the mirror
configuration before the server.

### 4. Oversubscribing the mirror destination

Two gigabit ports mirrored into one gigabit port drops copies during exactly the
busy periods somebody set the capture up to study, and nothing reports it.

### 5. Treating sampled flow data as complete

Sampling is accurate for large conversations and blind to small ones. Scans and
beacons are small, and they are usually what somebody is looking for.

### 6. Naming a product when the exam names a category

The objectives say flow data. NetFlow, sFlow and IPFIX are implementations of it,
and none of them appears in the objectives text.

## Work it through

The 1 Gbit link at 94 per cent since Tuesday.

The first thing worth saying out loud is that the graph is doing its job. An
interface counter answers how much and it has answered. The question that cannot
be answered from it is who, and no amount of staring at the graph will change
that, so the useful move is to stop looking at it.

**What you needed before Tuesday is flow data**, and it is worth checking whether
you already have it. Routers and firewalls frequently export flow records to
something that has been quietly collecting them for years, and a great many
organisations discover during an incident that they have three years of data
nobody has ever queried. If it exists, the answer is a report on the busy period
sorted by bytes, and it will take longer to find the login than to run.

**If it does not exist, turn it on now**, because it is cheap and because this
will happen again. Flow export on the device at either end of the link costs a
little processing and produces something you can keep.

**Then, and only then, consider a capture**, and be specific about what it is for.
Once flow data has told you that most of the traffic is between two addresses on
one port, a capture answers what those two are actually doing, and it is a
capture of one conversation for a few minutes rather than of a link for a day.

For the capture, where you attach matters. If the analyser hangs off a mirror on
the switch, check two things before believing the result: that both directions are
configured, and that the destination port is not slower than the sum of what is
being mirrored into it. At 94 per cent of a gigabit, mirroring both directions of
that link into a single gigabit port is already asking for 1.88 gigabits, and the
copies that do not fit are dropped without a word.

And there is a question worth asking that is not technical. The link has been at
94 per cent for three days and it is Friday. Something changed on Tuesday, and
change records are a faster route to what changed than any packet is.

## Try it

**Time two methods on the same question.** Take a busy interface and answer who is
using it, first from flow data and then from a capture. The point is not which is
correct, it is how long each takes and how much disk each costs.

**Break a mirror on purpose.** Configure one direction only, then run something
that requests and receives, and read the capture as though you did not know. It is
a useful five minutes because the wrong diagnosis is so plausible.

**Work out your own sampling threshold.** Pick a sampling rate and calculate how
many packets a conversation needs before you would expect to see even one sample.
That number is the size below which your flow data is fiction.

## Check yourself

<details class="qa">
<summary>A link is saturated and the bandwidth graph cannot say why. What is the graph made of, and what would answer the question?</summary>

The graph is made of interface counters, polled over SNMP. A counter is a single
number of bytes, so it can say how much traffic there was and can never say whose
it was or what it contained.

Flow data answers it. Each record identifies one conversation by its addresses,
ports and protocol, and carries packet and byte counts, so the busy period sorts
by bytes into a list of who. A capture would also answer it and costs orders of
magnitude more, which makes it the wrong first move.

</details>

<details class="qa">
<summary>A capture taken from a port mirror shows requests going to a server and no responses coming back, but users say the application works. What is the most likely explanation?</summary>

The mirror is copying one direction only. Most equipment configures ingress and
egress mirroring separately, and setting up one without the other is easy to do
without noticing.

The giveaway is that the application works. If the server genuinely were not
responding, the users would be the first to say so. Check the mirror before you
check the server.

</details>

<details class="qa">
<summary>Why can a tap show you a frame with a bad checksum when a mirror cannot?</summary>

Because of where each one sits. A tap is in the cable, so it copies the signal
before any device has judged it, and a corrupted frame reaches the analyser
corrupted.

A mirror is inside the switch and copies frames the switch has already accepted.
A frame failing its checksum is discarded at ingress, and there is nothing left to
mirror. That is why a tap is the instrument for suspected physical faults.

</details>

<details class="qa">
<summary>Two 1 Gbit ports are mirrored into one 1 Gbit port. What happens during the busiest hour, and how would you know?</summary>

The switch is being asked to send up to 2 Gbit out of a 1 Gbit interface, so it
discards whatever does not fit. The discards are copies rather than real traffic,
so nothing that anybody monitors increments and no alarm fires.

You would not know from the capture, which is the problem. It looks complete and
it is missing most heavily during the busiest moments, which are the ones the
capture was set up to examine. The check is arithmetic done in advance: compare
the destination port's speed with the sum of what is being mirrored into it.

</details>

<details class="qa">
<summary>Flow data is sampled at one in a thousand. Why might a port scan not appear in it at all?</summary>

Because a scan is a very large number of very small conversations. Each one is a
handful of packets, and at one in a thousand the chance that any given one
contributes a sample is small.

Sampling estimates large flows well and small ones not at all, so it is accurate
for the traffic that was already visible and blind to the traffic somebody is
usually looking for. Scans, beacons and small exfiltration all sit below the line.

</details>

## References

- [RFC 7011](https://www.rfc-editor.org/rfc/rfc7011) - IETF, the IPFIX protocol specification, which defines what a flow is and what a record carries. Free. Accessed 2026-08-12.
- [RFC 3954](https://www.rfc-editor.org/rfc/rfc3954) - IETF, the informational description of NetFlow version 9, which is where the flow record shape most people have seen comes from. Free. Accessed 2026-08-12.
- [RFC 5475](https://www.rfc-editor.org/rfc/rfc5475) - IETF, on sampling and filtering techniques for packet selection. Free. Accessed 2026-08-12.
- [tcpdump(1)](https://www.tcpdump.org/manpages/tcpdump.1.html) - The Tcpdump Group. Accessed 2026-08-12.
- [conntrack(8)](https://man7.org/linux/man-pages/man8/conntrack.8.html) - Linux man-pages project, on the connection tracking table the flow capture on this page reads. Accessed 2026-08-12.
- [tc-mirred(8)](https://man7.org/linux/man-pages/man8/tc-mirred.8.html) - Linux man-pages project, the action that performs the mirroring in the capture. Accessed 2026-08-12.

**Pictures.** A freely licensed file from Wikimedia Commons, downloaded and served
from this site rather than linked across to somebody else's server. Resized and
otherwise unaltered.

- [Fiber optic tap](https://commons.wikimedia.org/wiki/File:Fiber_optic_tap.png) by Roens, [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/).

**Where the output came from.** The flow table was captured on the `nat-gateway`
namespace topology and the mirroring session on `managed-lan`, both through
`blog/scripts/netlab.sh`. The mirror is a real one: a Linux bridge with a `tc`
filter copying frames from one bridge port to another, which is the same operation
a switch performs, so the missing replies in the first capture are a genuine
consequence of the configuration rather than an edited transcript. Connection
tracking is not the same thing as a flow exporter, and it is not presented as one.
It is used here because it keeps the same fields with the same meanings, on a
machine anybody can run, which makes the shape of a flow record checkable rather
than illustrated.

**If you also work on Linux.** [I/O and network performance](/learn/linux-plus/io-and-network-performance)
on the Linux+ track approaches the same measurements from inside one machine
rather than from the network, and the two are worth reading together: that page
asks why this host is slow, this one asks what is on the wire.
