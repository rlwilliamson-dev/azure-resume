---
title: "The OSI model"
description: "The OSI model names the parts of a system you have already seen working. What each layer adds, why encapsulation is the mechanism behind it, which model the protocols on your machine actually follow, and the two layers nothing you will meet implements separately."
deck: "Seven layers, and the four that actually shipped"
track: "network-plus"
level: "intro"
order: 40
objectives:
  - "Name the seven OSI layers in order and say what each one adds"
  - "Point at three separate headers in one captured frame and name the layer each belongs to"
  - "Explain encapsulation without using the word abstraction"
  - "Say which model the protocols on a real machine actually match, and why both are taught"
  - "Say what a device at each layer looks at, and what it ignores"
prerequisites: ["macs-ips-and-ports"]
tags: ["network-plus", "networking", "beginner"]
updated: 2026-08-10
draft: false
examObjectives:
  - exam: "n10-009"
    domain: "1.0"
    objective: "1.1"
sources:
  - title: "ITU-T X.200, Open Systems Interconnection Basic Reference Model"
    url: "https://www.itu.int/rec/T-REC-X.200-199407-I/en"
    publisher: "ITU-T"
    accessed: 2026-08-10
    tier: 1
  - title: "RFC 1122, Requirements for Internet Hosts, Communication Layers"
    url: "https://www.rfc-editor.org/rfc/rfc1122"
    publisher: "IETF"
    accessed: 2026-08-10
    tier: 1
  - title: "RFC 3439, Some Internet Architectural Guidelines and Philosophy"
    url: "https://www.rfc-editor.org/rfc/rfc3439"
    publisher: "IETF"
    accessed: 2026-08-10
    tier: 1
  - title: "RFC 791, Internet Protocol"
    url: "https://www.rfc-editor.org/rfc/rfc791"
    publisher: "IETF"
    accessed: 2026-08-10
    tier: 1
  - title: "tcpdump(1)"
    url: "https://www.tcpdump.org/manpages/tcpdump.1.html"
    publisher: "tcpdump.org"
    accessed: 2026-08-10
    tier: 1
  - title: "RFC 826, An Ethernet Address Resolution Protocol"
    url: "https://www.rfc-editor.org/rfc/rfc826"
    publisher: "IETF"
    accessed: 2026-08-10
    tier: 1
  - title: "RFC 3031, Multiprotocol Label Switching Architecture"
    url: "https://www.rfc-editor.org/rfc/rfc3031"
    publisher: "IETF"
    accessed: 2026-08-10
    tier: 1
symptoms: []
---

> **Before you read.** You have already watched a frame carry a MAC address, an
> IP address and a port number, all at once, nested inside each other.
>
> Somebody now tells you that networking has seven layers, and hands you a list
> of them.
>
> **How many of those seven can you point at in the frame you have already
> seen?**

The honest answer is three, and the gap between three and seven is the most
useful thing in this topic.

The model is worth learning, and the exam names it in objective 1.1, so it gets
taught properly here. It is also worth learning accurately, because a lot of
material presents seven layers as though all seven are things running on your
machine, and that is not true and creates confusion later.

### Some words you will need

<dl class="terms">
<dt>layer</dt>
<dd>One job in the stack, doing something specific and handing the result to the layer below.</dd>
<dt>header</dt>
<dd>Information a layer adds in front of what it was given. Reading a capture is reading headers.</dd>
<dt>encapsulation</dt>
<dd>Each layer wrapping what came from above. It is the mechanism that makes layering real rather than a diagram.</dd>
<dt>protocol data unit</dt>
<dd>The name for the whole bundle at a given layer. Frame at layer 2, packet at layer 3, segment at layer 4.</dd>
<dt>reference model</dt>
<dd>A shared vocabulary for describing systems. Not a specification anybody implements exactly.</dd>
<dt>protocol stack</dt>
<dd>The actual software on a machine that does this work.</dd>
</dl>

## What breaks without this

**You cannot describe a fault to anybody else.** "It is a layer 2 problem" tells
a colleague which half of the possibilities to ignore. "It is not working" does
not.

**Every other document assumes it.** Vendor documentation, error messages, job
adverts and this exam all use layer numbers as shorthand. Not knowing them is a
reading problem, not just a knowledge gap.

**You look for the fault in the wrong place.** Given a symptom, the model narrows
where to look. Without it, troubleshooting is a list of things to try in no
particular order.

## The seven layers

Bottom to top, because that is the direction data is wrapped and the direction
this track has been building.

| # | Layer | What it adds | Something you have already seen |
| --- | --- | --- | --- |
| 1 | Physical | Bits as signals on a medium | The cable, and `LOWER_UP` meaning carrier |
| 2 | Data link | Delivery across one link, using MAC addresses | `02:00:01:00:00:02 > 02:00:01:00:00:01` |
| 3 | Network | Delivery across networks, using IP addresses | `10.0.1.2 > 10.0.2.2` surviving a router |
| 4 | Transport | Which program, and whether delivery is checked | Port `8080`, and `Flags [S]` opening a connection |
| 5 | Session | Setting up and tearing down a dialogue | Nothing separate, in practice |
| 6 | Presentation | Encoding, so both ends agree what bytes mean | Nothing separate, in practice |
| 7 | Application | The thing the user actually wanted | The web page, the file, the email |

The last column is the point of this table. **Layers 1 through 4 and layer 7 are
things you have seen or will see directly.** Layers 5 and 6 are the two that
appear in every diagram and correspond to nothing you can point at on a running
machine.

That is not a trick of the model. It is what happened historically, and it is
covered honestly further down rather than left as a puzzle.

There are mnemonics for the order and they are all equally silly. Pick one, or
learn the order by understanding that each layer needs the one under it: you
cannot address a network before you can move bits across one link, and you cannot
choose a program before you have reached the machine it runs on.

<details class="deeper">
<summary>If you already work on networks: the protocols that refuse to sit on one layer, and how to answer anyway</summary>

The table above implies every protocol has a home. Several of the ones you use
most do not, and knowing which is more useful than the layer number itself.

**ARP** exists to hand layer 3 a layer 2 address. It is asked for by IP and it is
carried in a bare Ethernet frame with its own type code, so it is not inside an
IP packet at all. Both halves of that are visible in one capture.

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology two-hosts
# ARP and ICMP, printed with the link-layer header shown
$ ip -n h1 addr add 10.0.0.1/24 dev h1eth0
$ ip -n h2 addr add 10.0.0.2/24 dev h2eth0
$ (ip netns exec h1 timeout 6 tcpdump -i h1eth0 -n -e arp or icmp > /tmp/s.txt 2>/dev/null &)
$ sleep 2
$ ip netns exec h1 ping -c 1 10.0.0.2 > /dev/null 2>&1
$ sleep 5
$ cat /tmp/s.txt
20:25:38.193795 02:00:00:00:01:01 > ff:ff:ff:ff:ff:ff, ethertype ARP (0x0806), length 42: Request who-has 10.0.0.2 tell 10.0.0.1, length 28
20:25:38.193806 02:00:00:00:01:02 > 02:00:00:00:01:01, ethertype ARP (0x0806), length 42: Reply 10.0.0.2 is-at 02:00:00:00:01:02, length 28
20:25:38.193807 02:00:00:00:01:01 > 02:00:00:00:01:02, ethertype IPv4 (0x0800), length 98: 10.0.0.1 > 10.0.0.2: ICMP echo request, id 33, seq 1, length 64
20:25:38.193833 02:00:00:00:01:02 > 02:00:00:00:01:01, ethertype IPv4 (0x0800), length 98: 10.0.0.2 > 10.0.0.1: ICMP echo reply, id 33, seq 1, length 64
```

`ethertype ARP (0x0806)` on the first two lines and `ethertype IPv4 (0x0800)` on
the last two. The request goes to the broadcast address because the sender does
not yet know who to ask. Then the ping rides inside IP like anything else. So ARP
is carried at layer 2 and works for layer 3, which is why you will see it called
layer 2, layer 3, and layer 2.5 by three sources on the same afternoon.

**ICMP** is the mirror case. The capture shows it inside an IPv4 packet, which
would make it look like a layer 4 protocol sitting where TCP sits. It is
classified as layer 3, because what it carries is IP's own control and error
signalling rather than anybody's application data. Ping and traceroute are built
on it, and both appear later in the track.

**MPLS** inserts a label between the frame header and the packet header, which is
where the nickname layer 2.5 comes from. Nothing was wrong with the model. The
protocol was designed to fit in a gap the model does not name.

**TLS** sits above TCP and below the application. Sources place it at 5, 6, or 7
and all three arguments are reasonable, which tells you the question is about
convention rather than about mechanism.

The practical position: layer numbers for these are learned, not derived. Learn
the one the exam uses, and hold on to what the protocol actually does, because
that is the part that survives contact with a real fault.

</details>

## Encapsulation is the mechanism

Layering would be a diagram if nothing enforced it. What enforces it is that each
layer physically wraps what it was handed.

Take the same connection from the previous topic and ask tcpdump to open the
headers up rather than summarising them.

<details class="predict">
<summary>One frame, printed with the headers expanded. How many distinct headers are visible, and which field shows that this packet has already crossed a router?</summary>

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology one-router
$ (ip netns exec h2 timeout 10 nc -l -p 8080 > /dev/null 2>&1 &)
$ (ip netns exec h2 timeout 10 tcpdump -i h2eth0 -n -e -v -c 1 "tcp[tcpflags] & tcp-syn != 0" > /tmp/v.txt 2>/dev/null &)
$ sleep 2
$ ip netns exec h1 sh -c "echo hello | nc -w 2 10.0.2.2 8080" > /dev/null 2>&1
$ sleep 3
$ cat /tmp/v.txt
13:47:23.197184 02:00:02:00:00:01 > 02:00:02:00:00:02, ethertype IPv4 (0x0800), length 74: (tos 0x0, ttl 63, id 55999, offset 0, flags [DF], proto TCP (6), length 60)
    10.0.1.2.58984 > 10.0.2.2.8080: Flags [S], cksum 0x1732 (incorrect -> 0xeb05), seq 4072719318, win 64240, options [mss 1460,sackOK,TS val 4013727543 ecr 0,nop,wscale 8], length 0
```

</details>

Three headers, one inside the next, and tcpdump prints them in that order.

**The Ethernet header, layer 2.** `02:00:02:00:00:01 > 02:00:02:00:00:02,
ethertype IPv4 (0x0800)`. Two MAC addresses and a label saying what is inside.
That label is how layering is actually implemented: each header names the thing it
is wrapping, so the receiver knows which piece of software to hand it to.

**The IP header, layer 3.** Everything in the brackets. `ttl 63` is the answer to
the question above, because a host sends with 64 and this packet has been through
one router. `proto TCP (6)` is the same naming trick again, one layer down.
`length 60` is the packet size, and `flags [DF]` says do not fragment.

**The TCP header, layer 4.** The indented line. Ports, sequence number, window
size, and `Flags [S]` marking this as the first packet of a connection.

Now count the sizes and the wrapping becomes arithmetic rather than metaphor. The
frame is 74 bytes. The IP header says the packet inside it is 60. So the Ethernet
header accounts for 14 bytes, which is exactly what it is: six bytes of
destination MAC, six of source, two of ethertype.

<figure class="learn-figure">
<svg viewBox="0 0 720 268" role="img" aria-labelledby="encap-title" style="width:100%;height:auto;">
<title id="encap-title">The same bytes drawn three times, gaining a header at each layer on the way down</title>
<g fill="currentColor">
<text x="217" y="44" font-size="11">what TCP handed down: the segment</text>
<rect x="217" y="50" width="150" height="44" rx="3" fill="currentColor" fill-opacity="0.09" stroke="currentColor" stroke-opacity="0.5"/>
<text x="292" y="70" text-anchor="middle" font-size="10.5">TCP header</text>
<text x="292" y="85" text-anchor="middle" font-size="10" fill-opacity="0.7">Flags [S]</text>
<rect x="367" y="50" width="336" height="44" rx="3" fill="currentColor" fill-opacity="0.03" stroke="currentColor" stroke-opacity="0.5" stroke-dasharray="5 4"/>
<text x="535" y="70" text-anchor="middle" font-size="10.5">data</text>
<text x="535" y="85" text-anchor="middle" font-size="10" fill-opacity="0.7">length 0</text>
<text x="107" y="106" font-size="11">what IP made of it: the packet, length 60</text>
<rect x="107" y="112" width="110" height="44" rx="3" fill="currentColor" fill-opacity="0.11" stroke="currentColor" stroke-opacity="0.5"/>
<text x="162" y="132" text-anchor="middle" font-size="10.5">IP header</text>
<text x="162" y="147" text-anchor="middle" font-size="10" fill-opacity="0.7">ttl 63</text>
<rect x="217" y="112" width="150" height="44" rx="3" fill="currentColor" fill-opacity="0.09" stroke="currentColor" stroke-opacity="0.5"/>
<text x="292" y="132" text-anchor="middle" font-size="10.5">TCP header</text>
<text x="292" y="147" text-anchor="middle" font-size="10" fill-opacity="0.7">Flags [S]</text>
<rect x="367" y="112" width="336" height="44" rx="3" fill="currentColor" fill-opacity="0.03" stroke="currentColor" stroke-opacity="0.5" stroke-dasharray="5 4"/>
<text x="535" y="132" text-anchor="middle" font-size="10.5">data</text>
<text x="535" y="147" text-anchor="middle" font-size="10" fill-opacity="0.7">length 0</text>
<text x="17" y="168" font-size="11">what Ethernet made of that: the frame, length 74</text>
<rect x="17" y="174" width="90" height="44" rx="3" fill="currentColor" fill-opacity="0.14" stroke="currentColor" stroke-opacity="0.5"/>
<text x="62" y="194" text-anchor="middle" font-size="10.5">Ethernet</text>
<text x="62" y="209" text-anchor="middle" font-size="10" fill-opacity="0.7">14 bytes</text>
<rect x="107" y="174" width="110" height="44" rx="3" fill="currentColor" fill-opacity="0.11" stroke="currentColor" stroke-opacity="0.5"/>
<text x="162" y="194" text-anchor="middle" font-size="10.5">IP header</text>
<text x="162" y="209" text-anchor="middle" font-size="10" fill-opacity="0.7">ttl 63</text>
<rect x="217" y="174" width="150" height="44" rx="3" fill="currentColor" fill-opacity="0.09" stroke="currentColor" stroke-opacity="0.5"/>
<text x="292" y="194" text-anchor="middle" font-size="10.5">TCP header</text>
<text x="292" y="209" text-anchor="middle" font-size="10" fill-opacity="0.7">Flags [S]</text>
<rect x="367" y="174" width="336" height="44" rx="3" fill="currentColor" fill-opacity="0.03" stroke="currentColor" stroke-opacity="0.5" stroke-dasharray="5 4"/>
<text x="535" y="194" text-anchor="middle" font-size="10.5">data</text>
<text x="535" y="209" text-anchor="middle" font-size="10" fill-opacity="0.7">length 0</text>
<text x="17" y="242" font-size="11">74 minus 60 is 14, and 14 is exactly the Ethernet header: six bytes of destination,</text>
<text x="17" y="260" font-size="11" fill-opacity="0.85">six of source, two of ethertype. The wrapping is arithmetic rather than metaphor.</text>
</g>
</svg>
<figcaption>The same bytes three times, each row one layer further down. Nothing is rewritten between rows and nothing is copied: the segment TCP produced is still there, unchanged, in the middle of the frame that goes on the wire. Each header sits in front of what it was handed and names it, which is what the ethertype and proto fields in the capture are doing. Reading the diagram upwards is what the receiving machine does, one header at a time.</figcaption>
</figure>

**Each layer adds a fixed amount of overhead to carry somebody else's data.**
That is encapsulation, and it is why the model describes something real.

<details class="deeper">
<summary>If you already work on networks: where layering costs you, and the RFC that says so out loud</summary>

Layering is a design choice with a price, and the IETF wrote the price down.

RFC 3439 has a section titled "Layering Considered Harmful", which argues that
strict layering causes duplicated work between layers and hides information that
a lower layer needs. Its worked example is IP carried over ATM on a DS3 circuit,
where it subtracts three layers of overhead from the 44.736 Mbps line rate and
arrives at 30.960 Mbps of usable throughput. In its own words, "the total
overhead is about 31%", so roughly two thirds of the circuit survives the
stacking and the missing third pays for it.

You meet a smaller version of this constantly. Every tunnel, every VPN, and every
overlay adds another header inside the same maximum frame size, which leaves less
room for data and produces the fragmentation problems covered later in the track.

The second cost is cross-layer blindness. TCP at layer 4 interprets packet loss
as congestion, because on a wire that is what loss usually means. On a wireless
link, loss is frequently interference instead, and TCP slows down in response to a
condition that slowing down does not fix. Nothing in the layered design lets
layer 4 ask layer 1 what happened.

None of this means the model is wrong. It means it is a model, chosen because
independent layers can be replaced independently, and the cost of that
independence is real and occasionally visible in a throughput number.

</details>

## The model everybody uses, and the model everything implements

Here is the thing most study material leaves out.

The OSI model came from an international standards effort, published as ISO/IEC
7498-1 and republished word for word by the ITU as X.200. There was a matching set of OSI protocols intended to implement it. They
are not what the internet runs on.

What the internet runs on is the TCP/IP stack, described in RFC 1122, and it has
four layers.

| OSI | RFC 1122 | What runs there |
| --- | --- | --- |
| 7 Application, 6 Presentation, 5 Session | Application | HTTP, DNS, SSH, SMTP |
| 4 Transport | Transport | TCP, UDP |
| 3 Network | Internet | IP, ICMP |
| 2 Data link, 1 Physical | Link | Ethernet, wifi |

**That is why layers 5 and 6 have nothing to point at.** The protocols you use
put session handling and encoding inside the application, where in the OSI
scheme they would each have had a layer of their own. TLS is the awkward case
usually offered as a layer 6 example, and it does not fit tidily there either.

So why learn seven layers if four is what shipped? Because the seven-layer
vocabulary won. Firewalls are sold as layer 3 or layer 7. Switches are layer 2
devices and load balancers are layer 4 or layer 7. Every vendor, every error
message and this exam's first objective use the OSI numbers. The four-layer model
is what your machine does; the seven-layer model is how the industry talks about
it, and you need both.

Worth saying plainly: **the model is a description, not a component.** Nothing on
your machine is "doing layer 3" as a separate program. Layer 3 is a name for the
part of the network stack that deals in IP addresses.

<details class="deeper">
<summary>If you already work on networks: what a device at each layer looks at, and what it deliberately ignores</summary>

The most useful thing the model buys you is a precise statement of how much of a
frame a given device reads before acting.

A **hub**, layer 1, reads nothing. It repeats electrical signals out of every
other port. Everything on it hears everything, which is why they are gone.

A **switch**, layer 2, reads the destination MAC address and stops. It never
opens the IP header, which is why a switch can forward traffic for protocols it
has never heard of, and why it cannot make any decision based on an IP address
unless it is one of the layer 3 switches that deliberately looks further.

A **router**, layer 3, reads the IP header, which is why it can forward between
different networks and different link types. It ignores everything above, which
is what makes the packet contents private from it.

A **firewall** can be several things. A basic one filters on addresses and ports,
so layers 3 and 4. A next generation firewall inspects the application payload,
which is layer 7, and that is the actual difference behind the marketing.

A **load balancer** at layer 4 makes its decision from address and port. At layer
7 it reads the HTTP request and can route on the URL. Same box, different depth,
and very different capability.

The pattern is worth internalising: **reading further up costs more and buys more
specific decisions.** A layer 2 switch forwards in microseconds because it barely
looks. A layer 7 proxy can make decisions a switch could not express, and it pays
for that in latency and in state.

</details>

## Prove it

You can demonstrate the model on any machine with a packet capture, which is the
point: a model you can point at beats one you have memorised.

```bash
# Layer 2 and 3 together. -e shows the link header, which is otherwise hidden.
# Name a real interface. On Linux, -i any is a cooked capture with no Ethernet
# header, so it prints one address instead of a pair and adds bytes of its own.
tcpdump -i eth0 -n -e -c 1 icmp

# All the way up. -v opens the IP header, so ttl and proto become visible.
tcpdump -i eth0 -n -e -v -c 1 tcp

# Layer 4 from the machine's own point of view: which program holds which port.
ss -tlnp

# Layer 3 decision making, without sending anything.
ip route get 10.0.2.2
```

**Do the arithmetic once and the model stops being abstract.** Take a captured
frame, note its total length, note the packet length inside the IP header, and
subtract. Fourteen bytes of Ethernet header, every time.

That subtraction is also the fastest way to catch yourself capturing on `any`
rather than on an interface. A cooked capture has no Ethernet header and carries
a 16 byte one of its own, so the difference comes out at 20 and the model appears
to be wrong when the command was.

## What trips people up

### 1. Believing all seven layers exist as software

Five of them correspond to things you can observe. Session and presentation do
not, on anything you will meet, because the protocols that won put that work
inside the application. The model still names them, and the exam still asks.

### 2. Counting the layers from the wrong end

Physical is 1 and application is 7. Data is wrapped going down and unwrapped
going up. A common slip is to describe the sender as working up the stack, when
the sender works down it.

### 3. Treating the model as a specification

Nothing implements OSI exactly. It is vocabulary. When a real protocol does not
fit cleanly, the protocol is not broken and neither is your understanding.

### 4. Assuming a layer number describes a device permanently

A firewall is layer 3 or layer 7 depending on what it inspects. A switch is layer
2 unless it is a layer 3 switch. The number describes how deep something reads,
not what it is called.

### 5. Saying layer 8

It is a joke about the user, it is not part of the model, and it does not belong
in a written incident report.

## Work it through

A colleague says: "Users cannot reach the application. I have checked and it is
definitely a layer 7 problem."

You ask what they checked. They say the web server process is running and its
configuration file is correct.

Reason it out before reading on.

**Notice what has been proved and what has been assumed.** A running process with
a correct configuration is evidence about layer 7 on that one machine. It is not
evidence that anything below layer 7 works, and it is not evidence that anything
reaches the machine at all.

Use the model as a search order rather than a label. The claim is that the
top layer is at fault. The cheapest way to test that claim is to check whether
the lower layers are delivering anything, because if they are not, the
application cannot be the cause no matter how correct its configuration is.

**Pick the test that splits the problem hardest.** From a client machine, try to
open a connection to the application's port. If the connection is refused
instantly, the packet reached the server and something there said no, which
narrows the fault to layers 4 and above. If it times out with no reply at all,
the packet is not getting through, and layer 7 is not involved.

There is a trap in the original claim. "It is definitely a layer 7 problem"
is a conclusion dressed as an observation. The model is useful precisely because
it turns that into a question you can test: what is the lowest layer you have
positive evidence for?

**What the model bought you here.** Not the answer. An order of checking, and a
way of saying to a colleague which possibilities have been eliminated, which is
what makes the vocabulary worth having.

## Try it

Optional, and everything here works on the machine in front of you.

1. Find a real interface name with `ip -brief link show`, then capture one frame
   with `tcpdump -i <that interface> -n -e -c 1 icmp` while pinging something.
   Point at the layer 2 and layer 3 information in the output.
2. Capture again with `-v` added. Find the TTL and work out how many routers the
   packet has crossed, given hosts usually start at 64.
3. Note a frame's total length and the packet length inside its IP header, and
   subtract. Confirm you get 14. If you get 20, you captured on `any`, which is
   the point of step 1.
4. Run `ss -tlnp` and pick one listening port. Say which layer the port number
   belongs to and which layer the program belongs to.
5. Name the layer for each of these: a cut cable, a duplicate IP address, a
   service listening on the wrong port, a switch with a full MAC table, and a web
   page returning a 500 error.

**Verification step.** You have it when you can be given a symptom and name the
lowest layer that could produce it, and say what one test would rule that layer
in or out.

## Check yourself

<details class="qa">
<summary>Name the seven layers in order and what each adds.</summary>

Physical carries bits as signals. Data link delivers across one link using MAC
addresses. Network delivers between networks using IP addresses. Transport picks
the program and decides whether delivery is checked. Session manages a dialogue.
Presentation handles encoding. Application is the thing the user wanted.

Data is wrapped going down and unwrapped going up, so a sender works from layer 7
towards layer 1.

</details>

<details class="qa">
<summary>Which OSI layers have nothing separate to point at on a real machine, and why?</summary>

Session and presentation, layers 5 and 6.

The protocols the internet actually runs on follow the four-layer model in RFC
1122, which has a single application layer. Session handling and encoding are
done inside applications rather than by separate layers, so there is no component
to point at.

Both models get taught because the seven-layer vocabulary is what the industry
and this exam use, while the four-layer one is what your machine implements.

</details>

<details class="qa">
<summary>In a capture, the frame is 74 bytes and the IP header reports a length of 60. What does the difference tell you?</summary>

That the Ethernet header is 14 bytes: six for the destination MAC, six for the
source MAC, and two for the ethertype.

It also demonstrates encapsulation as arithmetic rather than metaphor. Each layer
adds a fixed header in front of what it was given, and the sizes add up.

</details>

<details class="qa">
<summary>A packet arrives with <code>ttl 63</code>. What does that tell you, and what mechanism is behind it?</summary>

That it has crossed one router, assuming the sender started at 64, which is the
common default.

Every router that forwards a packet decrements the time to live field. A packet
that reaches one is discarded rather than forwarded, which stops a routing loop
circulating traffic forever. Traceroute works by deliberately sending small TTLs
and collecting the resulting complaints.

</details>

<details class="qa">
<summary>Why can a switch forward traffic for a protocol it has never heard of?</summary>

Because it only reads the destination MAC address and stops. Everything above
layer 2 is opaque to it and it does not need to understand any of it to move the
frame to the right port.

That is also its limitation. Without opening the IP header it cannot make any
decision based on an IP address, which is what separates a plain switch from a
layer 3 switch or a router.

</details>

<details class="qa">
<summary>Somebody tells you a fault is "definitely layer 7" because the application process is running. What is wrong with that reasoning?</summary>

A running process is evidence about the application on that one machine. It says
nothing about whether traffic is reaching the machine at all.

The useful question is the lowest layer you have positive evidence for. Testing
whether a connection to the application's port is refused or times out splits the
problem: refused proves the packet arrived, and a timeout proves it did not.

</details>

## References

- [ITU-T X.200, Basic Reference Model](https://www.itu.int/rec/T-REC-X.200-199407-I/en) - ITU-T, the same text as ISO/IEC 7498-1. Accessed 2026-08-10.
- [RFC 1122, Requirements for Internet Hosts](https://www.rfc-editor.org/rfc/rfc1122) - IETF. Accessed 2026-08-10.
- [RFC 3439, Some Internet Architectural Guidelines and Philosophy](https://www.rfc-editor.org/rfc/rfc3439) - IETF. Accessed 2026-08-10.
- [RFC 791, Internet Protocol](https://www.rfc-editor.org/rfc/rfc791) - IETF. Accessed 2026-08-10.
- [tcpdump(1)](https://www.tcpdump.org/manpages/tcpdump.1.html) - tcpdump.org. Accessed 2026-08-10.

**Where the output came from.** The captured block was produced on the same
namespace topology as the previous topic,
`blog/scripts/topologies/one-router.sh`, so the frame it shows has genuinely
crossed a router and the TTL of 63 is the router's work rather than an
illustration. The layer tables are sourced from the OSI basic reference model and RFC 1122; the
throughput figure in the deeper panel is RFC 3439's own example.
- [RFC 826, An Ethernet Address Resolution Protocol](https://www.rfc-editor.org/rfc/rfc826) - IETF. Accessed 2026-08-10.
- [RFC 3031, Multiprotocol Label Switching Architecture](https://www.rfc-editor.org/rfc/rfc3031) - IETF. Accessed 2026-08-10.
