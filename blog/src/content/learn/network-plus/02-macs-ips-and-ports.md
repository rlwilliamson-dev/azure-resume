---
title: "MACs, IPs and ports"
description: "A MAC address, an IP address and a port number identify the same machine at the same moment, and they are not competing answers. What each one is for, how all three travel inside one frame, and which of them survives a trip through a router."
deck: "One machine, three addresses, all of them correct"
track: "network-plus"
level: "intro"
order: 30
objectives:
  - "Say what each of the three identifiers is for, without using the word address for all of them"
  - "Point at the MAC, the IP and the port in a single captured frame"
  - "Predict which identifiers change when a packet crosses a router and which do not"
  - "Explain why a firewall rule written against a MAC address stops working one hop away"
  - "Tell local delivery from routed delivery by looking at the destination"
prerequisites: ["what-a-network-actually-is"]
tags: ["network-plus", "networking", "beginner"]
updated: 2026-08-10
draft: false
examObjectives:
  - exam: "n10-009"
    domain: "1.0"
    objective: "1.1"
  - exam: "n10-009"
    domain: "1.0"
    objective: "1.4"
sources:
  - title: "RFC 791, Internet Protocol"
    url: "https://www.rfc-editor.org/rfc/rfc791"
    publisher: "IETF"
    accessed: 2026-08-10
    tier: 1
  - title: "RFC 9293, Transmission Control Protocol"
    url: "https://www.rfc-editor.org/rfc/rfc9293"
    publisher: "IETF"
    accessed: 2026-08-10
    tier: 1
  - title: "IEEE 802 numbers, including the local and universal administration bit"
    url: "https://standards.ieee.org/products-programs/regauth/"
    publisher: "IEEE Registration Authority"
    accessed: 2026-08-10
    tier: 1
  - title: "Service Name and Transport Protocol Port Number Registry"
    url: "https://www.iana.org/assignments/service-names-port-numbers/service-names-port-numbers.xhtml"
    publisher: "IANA"
    accessed: 2026-08-10
    tier: 1
  - title: "ss(8)"
    url: "https://man7.org/linux/man-pages/man8/ss.8.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-10
    tier: 1
  - title: "tcpdump(1)"
    url: "https://www.tcpdump.org/manpages/tcpdump.1.html"
    publisher: "tcpdump.org"
    accessed: 2026-08-10
    tier: 1
  - title: "ip-route(8)"
    url: "https://man7.org/linux/man-pages/man8/ip-route.8.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-10
    tier: 1
symptoms:
  - symptom: "A MAC-based firewall rule works locally and not from another subnet"
    anchor: "what-survives-a-hop-and-what-does-not"
  - symptom: "Two machines have the same IP address"
    anchor: "three-identifiers-one-machine"
---

> **Before you read.** A machine is sitting on a network doing one thing: serving
> a web page. At this moment it can be correctly identified by
> `02:00:01:00:00:02`, by `10.0.1.2`, and by `8080`.
>
> Three answers to "which machine, and what on it". All three are right, all
> three are in use at the same instant, and one of them is about to be thrown
> away and replaced.
>
> **Which one, and who throws it away?**

Topic 01 introduced two of these and showed one machine learning another's MAC
address. This topic is about why there are three, what each is for, and what
happens to them on a journey longer than one cable.

That last part is where the useful knowledge is. A lot of networking confusion
comes from assuming that because two things are both called an address, they
behave the same way. They do not, and one captured packet settles it.

### Some words you will need

<dl class="terms">
<dt>frame</dt>
<dd>What actually travels on a cable. It carries the MAC addresses and everything else nested inside it.</dd>
<dt>packet</dt>
<dd>The part inside the frame that carries the IP addresses. It survives the whole journey.</dd>
<dt>port</dt>
<dd>A number identifying which program on a machine a conversation is for.</dd>
<dt>socket</dt>
<dd>One end of a conversation, identified by an address and a port together.</dd>
<dt>hop</dt>
<dd>One step of a journey, from one device to the next. A router sits between two hops.</dd>
<dt>encapsulation</dt>
<dd>Wrapping data in a header so the next layer down can carry it. It is why one frame holds all three identifiers.</dd>
<dt>default gateway</dt>
<dd>The router a machine sends to when the destination is not local.</dd>
</dl>

## What breaks without this

**Firewall rules that work in testing and fail in production.** A rule written
against a MAC address does exactly what you expect from a machine on the same
segment and silently matches nothing from anywhere else.

**Diagnosis stalls at "it's a network problem".** Without knowing which
identifier is which, you cannot say whether a failure is on this segment, at the
far end, or in one specific program.

**The word address stops meaning anything.** Three different things are called
addresses, they are chosen by three different parties for three different
reasons, and treating them as interchangeable is the single most common
beginner misconception in this subject.

## Three identifiers, one machine

Take one interface on one machine and ask it three separate questions.

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology one-router
# commands run on h1
# identifier one: the interface, burned in
$ ip -brief link show h1eth0
h1eth0@if3       UP             02:00:01:00:00:02 <BROADCAST,MULTICAST,UP,LOWER_UP> 
# identifier two: the address, assigned
$ ip -brief addr show h1eth0
h1eth0@if3       UP             10.0.1.2/24 fe80::1ff:fe00:2/64 
# identifier three: the port, claimed by a program while it runs
$ (nc -l -p 9000 >/dev/null 2>&1 &)
$ sleep 1
$ ss -tlnp
State  Recv-Q Send-Q Local Address:Port Peer Address:PortProcess                    
LISTEN 0      1            0.0.0.0:9000      0.0.0.0:*    users:(("nc",pid=44,fd=3))
```

Three commands, three answers, and the differences between them are the whole
topic.

| | Who assigns it | How long it lasts | How far it means anything |
| --- | --- | --- | --- |
| MAC `02:00:01:00:00:02` | The manufacturer, at the factory | The life of the hardware | This cable segment |
| IP `10.0.1.2` | Whoever runs the network | Until somebody changes it | The whole internet |
| Port `9000` | The program, when it starts | While that program runs | Only on this machine |

**Read the last column twice.** It is the one that explains everything else.

<figure class="learn-figure">
<svg viewBox="0 0 720 274" role="img" aria-labelledby="scope-title" style="width:100%;height:auto;">
<title id="scope-title">How far each of the three identifiers means anything, drawn as three bars over the same distance</title>
<g font-family="ui-monospace, monospace" fill="currentColor">
<text x="17" y="22" font-size="11.5" fill-opacity="0.75">the same distance, measured outward from one interface</text>
<g font-size="10.5">
<rect x="17" y="30" width="180" height="34" rx="3" fill="currentColor" fill-opacity="0.04" stroke="currentColor" stroke-opacity="0.3" stroke-dasharray="5 4"/>
<text x="107" y="51" text-anchor="middle">this machine</text>
<rect x="197" y="30" width="200" height="34" rx="3" fill="currentColor" fill-opacity="0.04" stroke="currentColor" stroke-opacity="0.3" stroke-dasharray="5 4"/>
<text x="297" y="51" text-anchor="middle">this cable segment</text>
<rect x="397" y="30" width="306" height="34" rx="3" fill="currentColor" fill-opacity="0.04" stroke="currentColor" stroke-opacity="0.3" stroke-dasharray="5 4"/>
<text x="550" y="51" text-anchor="middle">everywhere past the first router</text>
</g>
<rect x="17" y="86" width="180" height="38" rx="3" fill="currentColor" fill-opacity="0.18" stroke="currentColor" stroke-width="1.6"/>
<text x="107" y="110" text-anchor="middle" font-size="11">port 9000</text>
<text x="207" y="110" font-size="10.5" fill-opacity="0.85">stops at the edge of the machine, so another machine can use 9000 too</text>
<rect x="17" y="134" width="380" height="38" rx="3" fill="currentColor" fill-opacity="0.14" stroke="currentColor" stroke-width="1.6"/>
<text x="207" y="158" text-anchor="middle" font-size="11">MAC 02:00:01:00:00:02</text>
<text x="407" y="158" font-size="10.5" fill-opacity="0.85">stops at the router, which writes a new one</text>
<rect x="17" y="182" width="686" height="38" rx="3" fill="currentColor" fill-opacity="0.1" stroke="currentColor" stroke-width="1.6"/>
<text x="140" y="206" text-anchor="middle" font-size="11">IP 10.0.1.2</text>
<text x="688" y="206" text-anchor="end" font-size="10.5" fill-opacity="0.85">unchanged the whole way</text>
<text x="17" y="248" font-size="11">Three identifiers on one interface, and three different distances over which they mean anything.</text>
<text x="17" y="266" font-size="11" fill-opacity="0.85">Almost everything else about them follows from the length of their bar.</text>
</g>
</svg>
<figcaption>The bars start at the same place and end in three different ones. A port never leaves the machine, which is why two machines can both hold 9000 and neither is wrong. A MAC address reaches the far end of one cable segment and no further, which is why it does not need to be organised by location and is not. An IP address has to survive the whole journey, which is why it is structured with a network part a router can hold one entry for. The next section watches all three of these in a single frame, and then watches which ones survive a hop.</figcaption>
</figure>

A MAC address means nothing beyond the segment it is on, so it does not need to
be organised by location and it is not. An IP address has to work from anywhere,
so it is structured: the leading part names the network, which is what lets a
router hold one entry for a whole network instead of one per machine. A port
means nothing outside the machine, so two machines can both be using 9000 with
no conflict whatsoever.

The `ss` output also shows the piece people miss. **A port belongs to a running
program, not to the machine.** `users:(("nc",pid=44,fd=3))` names the process
holding it. Stop that process and port 9000 belongs to nobody. Nothing about the
hardware or the address changed.

<details class="deeper">
<summary>If you already work on networks: what the bits inside a MAC address mean, and why this one is not from a factory</summary>

A MAC address is 48 bits, usually written as six hex pairs. The first three
bytes are the Organisationally Unique Identifier, assigned by the IEEE
Registration Authority to whoever built the hardware, and the last three are
chosen by that manufacturer. That is the sense in which it is burned in.

Two bits in the first byte carry meaning of their own. The least significant bit
of the first byte is the individual or group bit, and when it is set the frame is
multicast, which is why every broadcast address is `ff:ff:ff:ff:ff:ff` and why it
is odd in the first byte. The next bit along is the universal or local bit, and
when it is set the address is locally administered, meaning nobody registered it
and no manufacturer owns it.

That second bit is why the addresses in this track start with `02`. Hex `02` is
binary `00000010`, so the local bit is set and the multicast bit is not. These
addresses are deliberately outside the registered space, and the topology files
set them explicitly so a transcript can be reproduced. A kernel-generated random
MAC does the same thing, which is why virtual machines and containers usually
have addresses in this range too.

Worth knowing because it kills a common assumption. **A MAC address is not
reliably a fingerprint of a physical device.** It can be set in software on
essentially any modern operating system, which is one reason MAC filtering is
weak as a security control, and it is why a laptop that reports a different MAC
on every wifi network it joins is behaving normally rather than suspiciously.

</details>

## All three, inside one frame

The three identifiers are not alternatives. They travel together, nested, in
every frame that leaves the machine.

<details class="predict">
<summary>A program on h1 opens a connection to port 8080 on another machine. In the very first frame, how many of the three identifiers appear, and in what order?</summary>

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology one-router
$ (ip netns exec h2 timeout 10 nc -l -p 8080 > /dev/null 2>&1 &)
$ (ip netns exec h2 timeout 10 tcpdump -i h2eth0 -n -e -c 1 "tcp[tcpflags] & tcp-syn != 0" > /tmp/syn.txt 2>/dev/null &)
$ sleep 2
$ ip netns exec h1 sh -c "echo hello | nc -w 2 10.0.2.2 8080" > /dev/null 2>&1
$ sleep 3
# one frame, carrying all three identifiers at once
$ cat /tmp/syn.txt
13:46:50.445991 02:00:02:00:00:01 > 02:00:02:00:00:02, ethertype IPv4 (0x0800), length 74: 10.0.1.2.51282 > 10.0.2.2.8080: Flags [S], seq 1805300020, win 64240, options [mss 1460,sackOK,TS val 3629384030 ecr 0,nop,wscale 8], length 0
```

</details>

All three, and reading that line left to right is reading the frame from the
outside in.

`02:00:02:00:00:01 > 02:00:02:00:00:02` is the outermost wrapper, the MAC
addresses, which is what the cable and any switch in the path actually look at.

`ethertype IPv4 (0x0800)` is a label saying what is inside. Without it the
receiving machine would have a pile of bits and no idea which piece of software
should look at them.

`10.0.1.2.51282 > 10.0.2.2.8080` is two things printed as one. `10.0.1.2` and
`10.0.2.2` are the IP addresses, and `51282` and `8080` are the ports. tcpdump
joins them with a dot, which is compact and does trip people up the first time.

`Flags [S]` is the connection being opened, which the topic on TCP and UDP
picks up later in the track.

**The order is not arbitrary.** Each layer wraps the one above it, so the
information a device needs earliest sits furthest out. A switch only ever needs
the MAC addresses, so those are first and it can forward without reading any
further. Only the destination machine cares about the port, so that sits deepest.

Note the source port, `51282`. Nobody chose it. The operating system picked an
unused high number for the outgoing side of this conversation, which is why the
reply knows where to come back to. Only the destination port, `8080`, was
deliberate.

<details class="deeper">
<summary>If you already work on networks: the port ranges, and what really makes a connection unique</summary>

Ports are 16 bits, so 0 to 65535, and IANA splits the range three ways. 0 to
1023 are the system or well-known ports, 1024 to 49151 are registered, and 49152
to 65535 are dynamic, also called ephemeral.

Implementations do not have to use IANA's dynamic range for their own outgoing
ports, and Linux does not. `cat /proc/sys/net/ipv4/ip_local_port_range` on the
machine that produced the captures on this page returns `32768 60999`, which is
where the `51282` above came from. The registered range is a registry of what
services have claimed, not a reservation the kernel honours when it picks a
source port.

On Unix systems, binding a port below 1024 requires privilege. That is why a web
server is often started as root and immediately drops to an unprivileged user:
the only thing it needed root for was claiming port 80.

**A connection is not identified by a port. It is identified by four numbers**,
the source address, source port, destination address and destination port,
together with the protocol. That tuple is why one web server on one port can hold
thousands of simultaneous connections without confusion: every client contributes
a different source address or a different ephemeral port, so no two tuples
collide.

It is also why the ephemeral range is a real capacity limit rather than a
detail. A machine making very many outbound connections to the same destination
can exhaust its own source ports, and the symptom is connection failures under
load with nothing wrong at the far end.

</details>

## What survives a hop, and what does not

Now the question from the top of the page. Two hosts, on two different networks,
with a router between them. One ping is sent, and it is captured on both sides of
the router at the same time.

<details class="predict">
<summary>The same packet is captured leaving h1 and arriving at h2, with a router in between. Which parts of the two lines are identical, and which are completely different?</summary>

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology one-router
# capture on both segments at once, then send one ping across the router
$ (ip netns exec h1 timeout 8 tcpdump -i h1eth0 -n -e -c 1 icmp > /tmp/left.txt 2>/dev/null &)
$ (ip netns exec h2 timeout 8 tcpdump -i h2eth0 -n -e -c 1 icmp > /tmp/right.txt 2>/dev/null &)
$ sleep 2
$ ip netns exec h1 ping -c 1 -W 2 10.0.2.2 > /dev/null
$ sleep 3
# the frame as it leaves h1, on the 10.0.1.0/24 segment
$ cat /tmp/left.txt
13:46:17.617901 02:00:01:00:00:02 > 02:00:01:00:00:01, ethertype IPv4 (0x0800), length 98: 10.0.1.2 > 10.0.2.2: ICMP echo request, id 49, seq 1, length 64
# the same packet arriving at h2, on the 10.0.2.0/24 segment
$ cat /tmp/right.txt
13:46:17.617919 02:00:02:00:00:01 > 02:00:02:00:00:02, ethertype IPv4 (0x0800), length 98: 10.0.1.2 > 10.0.2.2: ICMP echo request, id 49, seq 1, length 64
```

</details>

Put the two lines next to each other and the answer is stark.

| | Leaving h1 | Arriving at h2 |
| --- | --- | --- |
| MAC source | `02:00:01:00:00:02` | `02:00:02:00:00:01` |
| MAC destination | `02:00:01:00:00:01` | `02:00:02:00:00:02` |
| IP source | `10.0.1.2` | `10.0.1.2` |
| IP destination | `10.0.2.2` | `10.0.2.2` |
| ICMP id and sequence | `id 49, seq 1` | `id 49, seq 1` |

**The IP addresses are identical. Both MAC addresses have been replaced.**

The `id 49, seq 1` on both lines is what proves this is one packet and not two
similar ones. The router did not generate anything new. It received a frame,
stripped the outer wrapper, looked at the IP destination, decided which interface
that network was on, and built a completely new frame around the same packet.

So the MAC addresses were never about the journey. They are about one step of it.
On the first segment the conversation is "h1 to the router". On the second
segment it is "the router to h2". Two separate conversations, carrying the same
letter.

That is what a router does, stated as precisely as it can be: **it is a device
that discards the outer wrapper and writes a new one.** Everything else about
routing is detail on top of that.

Two consequences worth carrying forward.

A MAC address is useless as an identity beyond the local segment, because by the
time a packet reaches anywhere else, the original is gone. A firewall three hops
away could not filter on it even if it wanted to.

An IP address is the thing that travels, which is why it is what firewalls,
access lists and logs are written against, and why an IP address in a log tells
you something about a machine that might be anywhere on earth.

<details class="deeper">
<summary>If you already work on networks: what the router changed that this capture does not show</summary>

The IP addresses survived, but the packet is not byte for byte identical, and
the difference matters for two later topics.

The time to live field was decremented. Every router that forwards a packet
subtracts one, and a packet arriving with a TTL of one is discarded rather than
forwarded, with an ICMP message sent back to the sender. That mechanism exists to
stop a routing loop circulating a packet forever, and it is also exactly what
traceroute exploits: send packets with deliberately small TTLs and collect the
complaints. Add `-v` to tcpdump and the field is visible, which the topic on
the OSI model does.

Because the TTL changed, the IP header checksum had to be recalculated too, so
the header is genuinely rewritten on every hop even though the addresses in it
are not.

**What is not touched is anything above the IP header.** The TCP or ICMP payload
passes through untouched, which is what makes end-to-end checksums and end-to-end
encryption meaningful: the routers in the middle are handling the envelope and
cannot read the letter.

The exception to that is a device doing network address translation, which
deliberately rewrites the IP addresses and often the ports as well, and which
therefore breaks the tidy rule this section just taught. That is a whole topic of
its own later in the track, and it is worth knowing now that it is the exception
rather than the rule.

</details>

## Local or routed, and how a machine decides

The machine makes this decision before it sends anything, using only the
destination address and its own subnet mask, which topic 01 covered.

If the destination is on its own network, it delivers directly. It needs the
destination's MAC address, asks for it with ARP if it does not have it, and puts
the frame on the wire addressed to that machine.

If the destination is not on its own network, it does something that surprises
people the first time they see it. **It puts the router's MAC address on the
frame and the final destination's IP address in the packet.** The frame says
"give this to the router". The packet inside says "this is for 10.0.2.2".

That mismatch is not a mistake, it is the mechanism. Once you have seen it, the
capture above stops being surprising and becomes obvious.

<details class="deeper">
<summary>If you already work on networks: the mask comparison is a simplification, and the kernel will show you the real answer</summary>

What is written above gets the right answer nearly every time, and it is not what
the machine does.

A host does not hold one mask and compare against it. It looks the destination up
in a routing table and takes the most specific entry that matches, which is the
same longest prefix match a router performs. On a machine with one address and
one default route the two procedures agree, and that agreement is why the
simplified version survives being taught.

You can ask the kernel to run the real lookup and print what it decided.

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology one-router
# ask the kernel to show the decision rather than working it out yourself
$ ip -n h1 route
default via 10.0.1.1 dev h1eth0 
10.0.1.0/24 dev h1eth0 proto kernel scope link src 10.0.1.2 
$ ip netns exec h1 ip route get 10.0.1.9
10.0.1.9 dev h1eth0 src 10.0.1.2 uid 0 
    cache 
$ ip netns exec h1 ip route get 10.0.2.2
10.0.2.2 via 10.0.1.1 dev h1eth0 src 10.0.1.2 uid 0 
    cache 
```

The first lookup returns a device and nothing else, which is the kernel saying it
will deliver this one directly. The second returns `via 10.0.1.1`, which is it
saying the packet goes to the router. Same command, same machine, and the
difference is entirely which table entry matched.

The distinction stops being academic the moment a machine has more than one route,
which happens sooner than people expect: a VPN client adds routes, a container
runtime adds routes, and a laptop on wifi and ethernet at once has two of
everything. At that point "is it on my network" has no single answer and
`ip route get` is the only thing worth trusting. Topic 21 builds the table
properly and topic 23 covers how the winner is chosen.

</details>

## Across platforms

The three identifiers are the same everywhere. The commands are not, and
objective 5.5 names three of them side by side, so this is examinable rather
than trivia.

| Task | Linux | Windows | macOS |
| --- | --- | --- | --- |
| Interface and MAC | `ip link show` | `ipconfig /all` | `ifconfig` |
| Address and mask | `ip addr show` | `ipconfig` | `ifconfig` |
| Neighbour table | `ip neigh show` | `arp -a` | `arp -a` |
| Routing table | `ip route` | `route print` | `netstat -rn` |
| Listening ports | `ss -tlnp` | `netstat -ano` | `netstat -an` |

**The trap in that table is `ifconfig`.** On Linux it is deprecated, frequently
not installed, and this track uses `ip` instead. On macOS it is the current tool
and shows the address and the MAC together. So a Mac reader following Linux
instructions, or a Linux engineer sitting down at a Mac, both meet the same
surprise from opposite directions.

Here is the same machine question answered on macOS.

```bash
# macOS 26.5.2, arm64
$ ifconfig en0
en0: flags=8863<UP,BROADCAST,SMART,RUNNING,SIMPLEX,MULTICAST> mtu 1500
	options=400<CHANNEL_IO>
	ether 42:3e:ed:70:37:01
	inet6 fe80::864:272a:f0fa:51d%en0 prefixlen 64 secured scopeid 0x7 
	inet 192.168.64.7 netmask 0xffffff00 broadcast 192.168.64.255
	nd6 options=201<PERFORMNUD,DAD>
	media: autoselect <full-duplex,flow-control>
	status: active
```

`ether` is the MAC and `inet` is the address, in one command rather than two,
which is the whole difference from Linux. Note `netmask 0xffffff00`, which is
`255.255.255.0` written in hex, and which catches everybody once.

And on Windows, where the two identifiers are split across two commands and the
MAC is called something else again.

```powershell
# Microsoft Windows Server 2025 Datacenter, version 10.0.26100.0
> ipconfig
Windows IP Configuration
Ethernet adapter Ethernet 3:
   Connection-specific DNS Suffix  . : q5iesetv2pde5bsb0z011qd44h.xx.internal.cloudapp.net
   Link-local IPv6 Address . . . . . : fe80::e70c:960f:9087:19ba%14
   IPv4 Address. . . . . . . . . . . : 10.1.0.129
   Subnet Mask . . . . . . . . . . . : 255.255.240.0
   Default Gateway . . . . . . . . . : 10.1.0.1
```

`ipconfig` on its own gives the address, the mask and the gateway and no MAC at
all. **`ipconfig /all` is the one that shows it, and Windows calls it the
Physical Address rather than the MAC address.** Same 48 bits, third name for it.

Three platforms, three vocabularies, one set of facts underneath. The exam is
vendor-neutral and will use whichever name fits the question, so the thing worth
holding is what you are asking for rather than which command you happen to know.

## Prove it

Given any two machines, you can answer the three questions that matter.

```bash
# Which identifiers does this machine have?
ip -brief link show          # the MAC, burned in
ip -brief addr show          # the IP and the mask
ss -tlnp                     # the ports, and which program holds each

# Is this destination local, or does it go to the router?
ip route get 10.0.2.2        # the kernel answers, showing the interface and source

# What actually went on the wire?
tcpdump -i eth0 -n -e icmp   # -e prints the MAC addresses, which are the part
                             # that changes hop to hop. Name a real interface:
                             # -i any is a cooked capture with no Ethernet
                             # header, so it shows one address, never the pair
```

**`-e` is the flag that makes tcpdump answer this topic's question.** Without it
tcpdump prints the IP addresses and hides the MAC addresses, so a capture on two
segments looks identical and the thing you are trying to see is invisible.

## What trips people up

### 1. Treating MAC and IP as two names for the same thing

They are both called addresses and that is the entire reason for the confusion.
One is chosen by a manufacturer and means something on one cable. The other is
chosen by whoever runs the network and means something everywhere. When a packet
crosses a router, one of them is replaced and the other is not.

### 2. Expecting a MAC-based rule to work at a distance

MAC filtering and MAC-based access rules only ever see the address of the last
device to forward the frame. From another subnet, that is the router, for every
machine behind it.

### 3. Thinking a port belongs to the machine

A port is claimed by a program while it runs. `ss -tlnp` names the process
holding each one. Nothing is listening on a port when the program that was
listening has stopped, and the machine is otherwise unchanged.

### 4. Reading `10.0.2.2.8080` as an address

That is an address and a port joined by a dot, which is tcpdump's notation and
not something you would ever type. The address is `10.0.2.2` and the port is
`8080`. In most other places you would see `10.0.2.2:8080`.

### 5. Assuming the source port was chosen

Only the destination port is deliberate. The source port is picked by the
operating system from the ephemeral range, changes on every connection, and is
what lets replies find their way back to the right conversation.

## Work it through

A monitoring system reports that a server at `10.0.2.2` is being hammered by a
single client. You are asked to block that client, and you are told its MAC
address, because that is what somebody read off a label.

The server is in a different building, several hops away. Reason it out before
reading on.

**Start by asking whether the information can even reach you.** The MAC address
is rewritten at every hop. By the time this traffic reaches the server, the
source MAC on every frame is the last router's, and it is the same for every
client behind that router. A MAC-based block at the server would either match
nothing or match everything from that direction, and both outcomes are bad.

So what do you have instead? The IP address survives the journey. If the
monitoring system saw the traffic, it saw a source IP, and that is what a rule at
the server can be written against.

The MAC address is not useless, it is just useless here. On the client's own
segment it is exactly the right tool: a switch in that building can identify the
port that MAC is on, which is how you find the physical machine. So the MAC is the right tool for a completely
different question: not "how do I block this" but "where is this thing plugged
in".

**Predict the symptom if somebody applies the MAC rule anyway.** Nothing changes,
the traffic continues, and the next hypothesis is that the firewall is broken.
That is an hour lost to a rule that was never capable of matching.

**The habit worth taking:** before writing any rule, ask how far the thing you
are matching on travels. IP addresses cross the internet. MAC addresses cross one
cable. Ports mean something only on the machine that owns them.

## Try it

Optional, and the first three need nothing but the machine in front of you.

1. Run the three commands from the first capture on your own machine. Write down
   your MAC, your IP, and one port with a program holding it.
2. Run `ss -tlnp` and pick a listening port. Find the program that owns it, then
   consider what would happen to that port if you stopped the program.
3. Run `ip route get 8.8.8.8` and then `ip route get` an address on your own
   network. Compare the two answers and note that one names a gateway.
4. If you have a Linux machine or virtual machine, build
   `blog/scripts/topologies/one-router.sh` from this site's repository. Capture
   on both segments while sending one ping across, and confirm for yourself that
   the IP addresses match and the MAC addresses do not.
5. Run any capture twice, once with `-e` and once without, and note exactly what
   the flag adds.

**Verification step.** You have it when you can be shown a captured frame and say
which parts of it will still be there after the next router, without being told
anything about the network it is on.

## Check yourself

<details class="qa">
<summary>A packet crosses two routers on its way to a server. How many times are the MAC addresses rewritten, and how many times are the IP addresses?</summary>

The MAC addresses are rewritten at every hop, so three times: once by the sending
host as it builds the first frame, and once by each router. Each segment is a
separate conversation between two adjacent devices.

The IP addresses are not rewritten at all. They identify the original sender and
the final destination, and they are what makes the packet routable.

The one exception is a device performing network address translation, which
deliberately rewrites addresses and is covered later.

</details>

<details class="qa">
<summary>Why can two different machines both be using port 443 at the same time without any conflict?</summary>

Because a port only means something on the machine that owns it. It is not a
network-wide identifier and nothing coordinates port numbers between machines.

What has to be unique is the whole conversation, identified by source address,
source port, destination address and destination port, together with the
protocol. Two machines using 443 differ in their addresses, so the combinations
never collide.

</details>

<details class="qa">
<summary>In <code>10.0.2.2.8080</code>, what is the address and what is the port?</summary>

The address is `10.0.2.2` and the port is `8080`. This is tcpdump's notation,
which appends the port to the address with a dot rather than a colon.

Most other tools and every configuration file you will write use `10.0.2.2:8080`.
The dot form is worth recognising because it appears in every packet capture and
it is confusing exactly once.

</details>

<details class="qa">
<summary>Somebody wants to block a specific client from reaching a server three hops away, and gives you the client's MAC address. What do you tell them?</summary>

That the MAC address cannot work at that distance. It is replaced at every hop,
so what arrives at the server is the last router's MAC, which is shared by every
machine behind it.

Ask for the source IP address instead, since that survives the whole journey and
is what a rule at the server can match.

The MAC address is still useful, for a different question. On the client's own
segment it identifies which switch port the machine is plugged into.

</details>

<details class="qa">
<summary>You capture traffic on two segments either side of a router and the two lines look identical. What flag are you missing, and why does it matter here?</summary>

`-e`, which tells tcpdump to print the link layer header.

Without it you see the IP addresses, which are the part that does not change, so
both captures genuinely look the same. The MAC addresses are the part that gets
rewritten, and they are exactly what `-e` adds.

</details>

<details class="qa">
<summary>A frame arrives carrying the router's MAC address as the destination but a completely different machine's IP address as the destination. Is something wrong?</summary>

No, that is routed delivery working correctly, and it is what every frame leaving
a machine for a non-local destination looks like.

The frame says "give this to the router" because the router is the next step. The
packet inside says "this is ultimately for that machine". The sender worked out
the destination was not local, so it addressed the wrapper to its gateway and
left the contents addressed to the real destination.

</details>

## References

- [RFC 791, Internet Protocol](https://www.rfc-editor.org/rfc/rfc791) - IETF. Accessed 2026-08-10.
- [RFC 9293, Transmission Control Protocol](https://www.rfc-editor.org/rfc/rfc9293) - IETF. Accessed 2026-08-10.
- [IEEE Registration Authority](https://standards.ieee.org/products-programs/regauth/) - IEEE. Accessed 2026-08-10.
- [Service Name and Transport Protocol Port Number Registry](https://www.iana.org/assignments/service-names-port-numbers/service-names-port-numbers.xhtml) - IANA. Accessed 2026-08-10.
- [ss(8)](https://man7.org/linux/man-pages/man8/ss.8.html) - Linux man-pages project. Accessed 2026-08-10.
- [tcpdump(1)](https://www.tcpdump.org/manpages/tcpdump.1.html) - tcpdump.org. Accessed 2026-08-10.

**Where the output came from.** Every terminal block on this page was captured
rather than written, from two places.

The Linux blocks come from three network namespaces wired as two segments with a
router between them, using the topology committed at
`blog/scripts/topologies/one-router.sh`. MAC addresses are fixed in that topology
and encode which segment they belong to, so the two halves of the hop capture can
be told apart on sight. The `@if3` suffix on the interface name is an artefact of
how namespaces are joined and would not appear on a physical machine.

The macOS and Windows blocks in **Across platforms** come from GitHub Actions
runners, driven by `blog/scripts/hostcap.sh` and the committed command lists
under `blog/scripts/macos/` and `blog/scripts/windows/`. A runner is used rather
than a personal machine because a capture from one would publish its hostname,
addresses and wifi network. Those two are the only blocks here that cannot be
reproduced exactly: a runner's addresses and hostname differ on every run, so
nothing on this page rests on a value from them that varies.

The block under **Prove it** is the exception to all of this. It is a command
list rather than a transcript, it has no output and no provenance header, and it
is there to be typed rather than read.

**If you also work on Linux.** [Network basics: addresses and routes](/learn/linux-plus/network-basics-addresses-and-routes) on the Linux+ track covers the same
three identifiers alongside the tools for changing them, and carries the
distribution-specific detail deliberately left out here. Where the two pages
overlap they should agree about the protocol and differ about the administration.
If you ever find them disagreeing about the protocol, one of them is wrong and I
would like to know which.
- [ip-route(8)](https://man7.org/linux/man-pages/man8/ip-route.8.html) - Linux man-pages project. Accessed 2026-08-10.
