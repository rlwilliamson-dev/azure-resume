---
title: "Discovery tools and device commands"
description: "You inherit a network and no documentation. Finding what is on a segment and what it is running, getting the devices to describe each other so a diagram builds itself, the four questions a device command answers, and why scanning is a permission question before it is a technical one."
deck: "You inherit a network and no documentation"
track: "network-plus"
level: "working"
order: 750
objectives:
  - "Find which addresses are in use on a segment and what they are running"
  - "Read a neighbour discovery table and rebuild a diagram from it"
  - "Name the four questions a device command answers and the command for each"
  - "Say which hardware tool answers which physical question"
  - "Treat a scan as something to be authorised before it is run"
prerequisites: ["network-documentation-and-diagrams"]
tags: ["network-plus", "networking", "troubleshooting", "tools"]
updated: 2026-08-19
draft: false
examObjectives:
  - exam: "n10-009"
    domain: "5.0"
    objective: "5.5"
sources:
  - title: "Nmap reference guide"
    url: "https://nmap.org/book/man.html"
    publisher: "Nmap Project"
    accessed: 2026-08-19
    tier: 1
  - title: "IEEE 802.1AB, Link Layer Discovery Protocol"
    url: "https://standards.ieee.org/ieee/802.1AB/7822/"
    publisher: "IEEE Standards Association"
    accessed: 2026-08-19
    tier: 1
  - title: "FRRouting user guide"
    url: "https://docs.frrouting.org/en/latest/"
    publisher: "The FRRouting Project"
    accessed: 2026-08-19
    tier: 2
symptoms:
  - symptom: "Nobody knows what is connected to a network or what it does"
    anchor: "what-is-on-this-segment"
  - symptom: "There is no diagram and nobody remembers how the devices are wired"
    anchor: "asking-the-devices-about-each-other"
  - symptom: "A device is reachable and nobody knows what it is running"
    anchor: "and-what-is-that-machine-running"
---

> **Before you read.** You have taken over a network. There is no diagram, the
> spreadsheet is four years old, and the person who built it left before you
> arrived. Two of the addresses in the spreadsheet do not answer and three
> devices are answering that are not in it.
>
> Nobody can tell you what is connected to what.
>
> **Where do you start, and what can you find out without touching anything?**

Most networks are inherited rather than built, and the first job on an inherited
network is to find out what it is. This topic is the tools for that: the ones that
ask the network, the ones that ask the devices, and the physical ones for the
questions software cannot answer.

### Some words you will need

<dl class="terms">
<dt>host discovery</dt>
<dd>Finding which addresses on a range have something answering at them. A list of what exists, before any question about what it does.</dd>
<dt>port scan</dt>
<dd>Asking one host which of its ports accept connections. What a machine offers, rather than whether it is there.</dd>
<dt>neighbour discovery</dt>
<dd>Devices announcing themselves on each link so their neighbours know what is on the other end. Layer 2, and it does not cross a router.</dd>
<dt>management address</dt>
<dd>The address a device says to reach it on, which is often not the address you found it at.</dd>
<dt>toner probe</dt>
<dd>Two pieces: one puts a signal on a cable, the other finds which cable is making the noise. The answer to "which of these four hundred is it".</dd>
</dl>

## What breaks without this

**Work is done blind.** A change to a network nobody has mapped is a change whose
blast radius is unknown, which is how a small maintenance window becomes an
incident.

**The documentation stays wrong.** A diagram nobody can rebuild is a diagram that
only ever gets further from the truth, and every person who inherits it after you
starts from the same place.

**A scan becomes an incident.** Discovery tools look exactly like reconnaissance,
because they are the same thing done by somebody with permission, and running one
without that permission is how a routine afternoon becomes a conversation with
security.

## What is on this segment

The first question is the simplest: which addresses have something answering at
them. The topology is
[`sockets.sh`](https://github.com/rlwilliamson-dev/azure-resume/blob/main/blog/scripts/topologies/sockets.sh).

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology sockets
# who is on this segment. no documentation, no inventory, one command
$ ip netns exec h2 nmap -sn 10.0.0.0/29
Starting Nmap 7.95 ( https://nmap.org ) at 2026-08-19 15:53 UTC
Nmap scan report for 10.0.0.1
Host is up (0.00011s latency).
MAC Address: 02:00:00:00:00:01 (Unknown)
Nmap scan report for 10.0.0.3
Host is up (0.000032s latency).
MAC Address: 02:00:00:00:00:03 (Unknown)
Nmap scan report for 10.0.0.2
Host is up.
Nmap done: 8 IP addresses (3 hosts up) scanned in 27.31 seconds
```

Eight addresses asked, three answering, and each one reported with its hardware
address. That last detail is worth more than it looks on an inherited network,
because the first three bytes of a hardware address are assigned to a manufacturer,
so a list of them is a rough inventory of who made what before anybody logs into
anything.

Note the third entry has no hardware address next to it. That is the scanning
machine itself, which knows it is up without asking, and it is a small reminder that
a scan is taken from somewhere and the result depends on where.

The exam names Nmap directly rather than describing a category, which is unusual for
this objectives document and worth knowing: it is the tool the questions can assume.

## And what is that machine running

The second question is what one of those devices offers.

<details class="predict">
<summary>A single host on that segment, scanned for open ports. It runs one service. What does the scan say about the other thousand ports it tried?</summary>

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology sockets
# and what is one of them running
$ ip netns exec h2 nmap -Pn 10.0.0.1
Starting Nmap 7.95 ( https://nmap.org ) at 2026-08-19 15:54 UTC
Nmap scan report for 10.0.0.1
Host is up (0.0000040s latency).
Not shown: 999 closed tcp ports (reset)
PORT     STATE SERVICE
8000/tcp open  http-alt
MAC Address: 02:00:00:00:00:01 (Unknown)

Nmap done: 1 IP address (1 host up) scanned in 13.12 seconds
```

</details>

One open port out of a thousand, and the line above it is the interesting one.
**"999 closed tcp ports (reset)"** is topic 73's lesson arriving from the other
direction: the scanner learned those ports were closed because each one answered with
a reset, and a reset is an answer. A port that had been filtered rather than closed
would have produced silence, and the scanner would have reported it differently
because it means something different.

So a port scan is not a list of doors. It is a list of answers, and the three
possible answers are the same three from the capture topic: something accepted,
something refused, or nothing came back at all.

The service name next to the port, `http-alt`, is a guess. It comes from a local file
mapping port numbers to the service conventionally found on them, and nothing verifies
it. Anything can listen on any port, so treat the name as a hint about what somebody
probably intended and not as a fact about what is running.

<details class="deeper">
<summary>Before you run any of this: the permission question, and what a scan can do by accident</summary>

Discovery tools and reconnaissance tools are the same tools. What separates the two is
authorisation, and that is not a formality.

**Get it in writing, from somebody who can give it.** On a network you administer, your
own change process is usually enough. On a customer's network, or a network your
employer does not own, or a cloud provider's address space, permission has to come from
the party that operates it, and "I assumed it was fine" is not a defence. Many
jurisdictions treat unauthorised scanning as an offence in its own right regardless of
whether anything was harmed, and cloud providers publish their own rules about testing
inside their platforms.

**Scan windows and scope belong in that authorisation too.** Which ranges, which ports,
which hours, and who to call if something goes wrong. That paperwork exists because of
the second reason, which is technical.

**A scan can break things.** Most modern equipment shrugs it off. Older embedded
devices, industrial controllers, building management systems, medical equipment and
printers frequently do not, and a full port scan against one of them can hang it or
reboot it. A network with unknown devices on it, which is exactly the network this topic
is about, is the worst case: you cannot know which of them is fragile until after you
find out.

**And it will be noticed.** Any monitoring worth having flags a host that opens
connections to a thousand ports on a thousand addresses, so an unannounced scan
generates a security incident, wastes somebody's evening, and makes your own team's
detection look untrustworthy the next time it fires. Telling the security team before you
start costs one message and turns an alert into a confirmation that their tooling works.

The practical version of all of this: announce it, scope it, start gently on ranges you
know, and treat a device that stops responding during a scan as your responsibility.

</details>

## Asking the devices about each other

Scanning tells you what exists. It does not tell you what is plugged into what, and
that is the part a diagram needs.

The devices already know. Every switch and router can announce itself on each of its
links, saying what it is, which of its own ports the announcement came out of, and how
to manage it. A neighbour reading those announcements knows exactly what is on the
other end of each cable, and the union of everybody's view is the map.

<figure class="learn-figure">
<svg viewBox="0 0 720 200" role="img" aria-labelledby="nbr-title" style="width:100%;height:auto;">
<title id="nbr-title">Three routers in a line, each reporting only its own neighbours, with each report naming both ends of one cable so the reports can be joined into a diagram</title>
<g fill="currentColor">
<text x="14" y="20" font-size="11">no device knows the network. each one knows both ends of its own cables</text>
<g stroke="currentColor" stroke-opacity="0.55" stroke-width="1.4" fill="none">
<path d="M 168 72 H 342"/>
<path d="M 378 72 H 552"/>
</g>
<g fill="currentColor" fill-opacity="0.07" stroke="currentColor" stroke-opacity="0.75">
<circle cx="150" cy="72" r="18"/>
<circle cx="360" cy="72" r="18"/>
<circle cx="570" cy="72" r="18"/>
</g>
<text x="150" y="76" text-anchor="middle" font-size="10">r1</text>
<text x="360" y="76" text-anchor="middle" font-size="10">r2</text>
<text x="570" y="76" text-anchor="middle" font-size="10">r3</text>
<text x="190" y="60" font-size="9" fill-opacity="0.85">r1-r2</text>
<text x="320" y="60" text-anchor="end" font-size="9" fill-opacity="0.85">r2-r1</text>
<text x="400" y="60" font-size="9" fill-opacity="0.85">r2-r3</text>
<text x="530" y="60" text-anchor="end" font-size="9" fill-opacity="0.85">r3-r2</text>
<g fill="none" stroke="currentColor" stroke-opacity="0.45" stroke-width="1.1">
<rect x="30" y="110" width="200" height="56" rx="4"/>
<rect x="260" y="110" width="200" height="56" rx="4"/>
<rect x="490" y="110" width="200" height="56" rx="4"/>
</g>
<text x="130" y="128" text-anchor="middle" font-size="9" fill-opacity="0.75">r1 reports</text>
<text x="360" y="128" text-anchor="middle" font-size="9" fill-opacity="0.75">r2 reports</text>
<text x="590" y="128" text-anchor="middle" font-size="9" fill-opacity="0.75">r3 reports</text>
<text x="130" y="146" text-anchor="middle" font-size="9">on r1-r2 I see r2-r1</text>
<text x="360" y="146" text-anchor="middle" font-size="9">on r2-r1 I see r1-r2</text>
<text x="360" y="160" text-anchor="middle" font-size="9">on r2-r3 I see r3-r2</text>
<text x="590" y="146" text-anchor="middle" font-size="9">on r3-r2 I see r2-r3</text>
<text x="14" y="190" font-size="9.5" fill-opacity="0.85">every line names one cable from both ends, so the lines join up without anybody drawing anything</text>
</g></svg>
<figcaption>Each report is one edge of a graph with both of its endpoints named, which is the property that makes the reports joinable. Nothing in the picture required a diagram to exist first, and no device holds more than its own two lines. Walk round the estate collecting them and the topology assembles itself, which is why this is the first thing to run on an inherited network and why the output is worth storing next to whatever documentation you inherit. The limit is in the drawing too: these announcements do not cross a router, so what you get is a map of each broadcast domain rather than of the whole network.</figcaption>
</figure>

Here is the middle router being asked what it can see, after the three of them have
been left to announce themselves for half a minute. The topology is
[`trace-path.sh`](https://github.com/rlwilliamson-dev/azure-resume/blob/main/blog/scripts/topologies/trace-path.sh).

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology trace-path
# each router runs the discovery daemon, each with its own run directory so that
# three of them on one kernel do not share a control socket
$ ip netns exec r1 unshare --mount sh -c "mkdir -p /run/lldp/r1; mount --bind /run/lldp/r1 /run; lldpd -I r1-r2; sleep 40" &
$ ip netns exec r3 unshare --mount sh -c "mkdir -p /run/lldp/r3; mount --bind /run/lldp/r3 /run; lldpd -I r3-r2; sleep 40" &
$ sleep 2
# and the middle router is asked what it can see, without anybody telling it
$ ip netns exec r2 unshare --mount sh -c "mkdir -p /run/lldp/r2; mount --bind /run/lldp/r2 /run; lldpd -I r2-r1,r2-r3; sleep 30; lldpcli show neighbors summary"
-------------------------------------------------------------------------------
LLDP neighbors:
-------------------------------------------------------------------------------
Interface:    r2-r1, via: LLDP
  Chassis:     
    ChassisID:    mac 3a:cd:c1:d1:b5:af
    SysName:      2b28e0679782
  Port:        
    PortID:       mac 3a:cd:c1:d1:b5:af
    PortDescr:    r1-r2
    TTL:          120
-------------------------------------------------------------------------------
Interface:    r2-r3, via: LLDP
  Chassis:     
    ChassisID:    mac 26:01:4a:3b:90:b8
    SysName:      2b28e0679782
  Port:        
    PortID:       mac 26:01:4a:3b:90:b8
    PortDescr:    r3-r2
    TTL:          120
-------------------------------------------------------------------------------
```

Two neighbours, one on each side, and each entry names the far device's port:
`r1-r2` on the interface facing r1 and `r3-r2` on the one facing r3. Nobody
configured that and nobody drew it. The devices said it.

Two honest limits on this lab. **The system name is the same in both entries**,
because every namespace here shares one container hostname, and on real equipment each
device reports its own. And **these announcements are layer 2**, so they stop at a
router and you get one map per broadcast domain rather than one map of an estate.

The exam names the neighbour discovery protocols as a category. What matters for a
question is what they reveal, which is the device on the other end, the port it used,
its capabilities and its management address, and what they do not, which is anything
beyond the next hop.

## The four questions a device command answers

The exam names a family of vendor-neutral commands and it is worth learning them as
questions rather than as syntax, because the syntax differs by vendor and the questions
do not.

Here they are against a real routing stack, which answers them the same way a switch or
router would. The topology is
[`three-routers-ospf.sh`](https://github.com/rlwilliamson-dev/azure-resume/blob/main/blog/scripts/topologies/three-routers-ospf.sh).

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology three-routers-ospf
# the vendor neutral commands, asked of a real routing stack. what interfaces
# does this device have, and what state is each one in
$ ip netns exec r1 vtysh --vty_socket /var/run/frr-r1 -c "show interface brief"
Interface       Status  VRF             Addresses
---------       ------  ---             ---------
erspan0         down    default         
gre0            down    default         
gretap0         down    default         
lo              up      default         
r1-h1           up      default         10.0.1.1/24
                                        fe80::6cac:9eff:fe1f:ee27/64
r1-r2           up      default         10.0.12.1/30
                                        fe80::c8ff:67ff:fe16:7b96/64
r1-r3           up      default         10.0.13.1/30
                                        fe80::4c3d:efff:fe2d:657d/64

# what does it know how to reach, and how did it learn each one
$ ip netns exec r1 vtysh --vty_socket /var/run/frr-r1 -c "show ip route"
Codes: K - kernel route, C - connected, L - local, S - static,
       R - RIP, O - OSPF, I - IS-IS, B - BGP, E - EIGRP, N - NHRP,
       T - Table, v - VNC, V - VNC-Direct, A - Babel, F - PBR,
       f - OpenFabric, t - Table-Direct,
       > - selected route, * - FIB route, q - queued, r - rejected, b - backup
       t - trapped, o - offload failure

IPv4 unicast VRF default:
O   10.0.1.0/24 [110/10] is directly connected, r1-h1, weight 1, 00:00:25
C>* 10.0.1.0/24 is directly connected, r1-h1, weight 1, 00:00:26
L>* 10.0.1.1/32 is directly connected, r1-h1, weight 1, 00:00:26
O>* 10.0.2.0/24 [110/20] via 10.0.12.2, r1-r2, weight 1, 00:00:10
O   10.0.12.0/30 [110/10] is directly connected, r1-r2, weight 1, 00:00:25
C>* 10.0.12.0/30 is directly connected, r1-r2, weight 1, 00:00:26
L>* 10.0.12.1/32 is directly connected, r1-r2, weight 1, 00:00:26
O   10.0.13.0/30 [110/10] is directly connected, r1-r3, weight 1, 00:00:25
C>* 10.0.13.0/30 is directly connected, r1-r3, weight 1, 00:00:26
L>* 10.0.13.1/32 is directly connected, r1-r3, weight 1, 00:00:26
O>* 10.0.23.0/30 [110/20] via 10.0.12.2, r1-r2, weight 1, 00:00:05
  *                       via 10.0.13.2, r1-r3, weight 1, 00:00:05
# and which other routers is it talking to
$ ip netns exec r1 vtysh --vty_socket /var/run/frr-r1 -c "show ip ospf neighbor"

Neighbor ID     Pri State           Up Time         Dead Time Address         Interface                        RXmtL RqstL DBsmL
10.10.10.2        1 Full/-          15.092s           34.919s 10.0.12.2       r1-r2:10.0.12.1                      0     0     0
10.10.10.3        1 Full/-          15.092s           34.943s 10.0.13.2       r1-r3:10.0.13.1                      0     0     0
```

**What does this device have, and is it working?** The interface summary: every
interface, its state, and its addresses. That is the first command to run on a device
you have never seen, and it answers the question topic 67 spent a page on in one screen.

**What does it know how to reach, and how did it learn it?** The routing table, with a
letter on each line naming the source. `C` is connected, `L` is a local address, and `O`
is OSPF. The `>` marks the route actually selected, which is topic 23's rule applied and
printed.

**Who is it talking to?** The protocol neighbour list. Two adjacencies, both `Full`,
which means these three routers have agreed on a view of the network and are exchanging
it. An adjacency that is not full is a routing problem that has not become a symptom yet.

**And what is it configured to do?** The running configuration, which is the fourth of
the family and is not shown here because it is long and mostly not interesting. It is the
one to capture into a file before you change anything.

Four commands and you know a device you have never logged into: what it has, what it
knows, who it talks to, and what somebody told it to do.

## The tools that are not software

Some questions cannot be answered from a terminal, and the exam names hardware for them.

**A cable tester** answers whether each conductor reaches the right pin at the other end.
Topic 11 has a photograph of one and topic 66 covers what it can and cannot see, which is
the more useful half: continuity yes, crosstalk and marginal performance no.

**A toner probe** answers "which of these is it". One half injects a signal into a cable
and the other half is a wand that squeals when it finds it, which is how a cable is
identified in a bundle of four hundred at a patch panel with no labels. On an inherited
network this is the tool that turns a spreadsheet full of guesses into a map, and there is
no software equivalent.

**A speed tester** answers what a link actually delivers rather than what it is rated at,
which is topics 75 and 76 in a box. The principle is the same whether the tester is a
handheld unit or `iperf3` on two laptops: measure both directions, and measure the path
rather than the link.

**A Wi-Fi analyser** answers what is on the air, which topic 30 covers and which no wired
tool can tell you.

The pattern across all four is that they answer physical questions, and a physical
question is exactly the kind that a device's own reports cannot settle, because a device
can only tell you about the world as it perceives it through the fault you are chasing.

## Across platforms

Host and port discovery is one tool everywhere. The rest differ.

| Task | Linux | Windows | macOS |
| --- | --- | --- | --- |
| Find hosts on a range | `nmap -sn <range>` | `nmap -sn <range>`, `Test-NetConnection` | `nmap -sn <range>` |
| Find open ports on a host | `nmap <host>` | `nmap <host>`, `Test-NetConnection -Port` | `nmap <host>` |
| Read neighbour announcements | `lldpcli show neighbors` | `Get-NetNeighbor` for addresses only | `tcpdump` filtered to the protocol |

Two things about that table matter more than the commands. Nmap is not installed by
default on any of the three, so on a machine you did not build the fallback is the
built-in connection tester, which answers one host and one port at a time and is enough
for a handful of checks. And **only Linux ships a general neighbour discovery client**,
so on the other two the practical answer is to read the announcements off the wire with a
capture, which topic 73 covers, or to ask the switch rather than the host.

## Prove it

You have this when you can walk into an undocumented network and produce three things by
the end of the day.

```bash
# what exists on this range
nmap -sn 10.0.0.0/24

# what one of them offers
nmap -Pn <address>

# what each device says is on the other end of its cables
lldpcli show neighbors summary
```

The three artefacts are a list of addresses in use with their manufacturers, a list of
what each interesting one is running, and a set of neighbour reports that join into a
diagram. None of them requires a password on any device, and all of them are worth
storing next to the documentation you inherited rather than in a terminal you will close.

Then, on any device you can log into, run the four questions: what have you got, what do
you know, who are you talking to, and what were you told to do. Written down for each
device, that is the documentation topic 36 says should have existed.

## What trips people up

### 1. Scanning before asking

A discovery tool and a reconnaissance tool are the same tool, and the difference is
written authorisation. Unannounced scans generate security incidents and, on networks
you do not administer, can be an offence.

### 2. Assuming a scan is harmless

Older embedded devices, controllers, printers and medical equipment can hang or reboot
under a full port scan, and an undocumented network is exactly where you cannot know
which ones those are.

### 3. Reading the service name as a fact

The name next to a port comes from a local file mapping numbers to conventional
services. Anything can listen on any port, so the name is a hint about intent and not a
statement about what is running.

### 4. Expecting neighbour discovery to cross a router

The announcements are layer 2 and stop at the first router, so what you get is one map
per broadcast domain. An estate-wide diagram is several of these joined by hand.

### 5. Trusting the address you found a device at

A device reports a management address and it need not be the one that answered your
scan. Multi-homed devices and out-of-band management ports are both common.

### 6. Forgetting the physical tools exist

No amount of software identifies which of four hundred cables at a patch panel is the
one you want. A toner probe does, in a minute, and there is no substitute.

## Work it through

The network you have just inherited.

Start by asking permission, even of yourself, and by telling whoever watches the alerts
what you are about to do. That costs one message and it is the difference between a
discovery exercise and an incident. Agree the ranges and the hours while you are there.

Then find what exists before asking what anything does. A host discovery sweep of the
ranges you believe are in use produces a list of addresses that answer, with
manufacturer information attached, and it immediately contradicts the spreadsheet in
both directions: addresses that do not answer and devices that are not listed. That
contradiction is the most valuable output of the first hour, because it tells you how
much of the inherited documentation to trust, which is usually less than you hoped.

Then ask the devices about each other rather than scanning harder. Neighbour discovery
on the switches gives you the wiring, which is the part no scan can produce, and it
gives it to you in a form that joins up: every report names both ends of a cable. Do
that per broadcast domain and stitch the results.

Then log into the devices you can and ask the four questions, capturing the running
configuration of each before touching anything. At that point you have a network you can
reason about, and you have it without having changed a single setting, which is the
right order: understand first, and let the first change you make be one you can predict
the effect of.

And keep the physical tools in mind for the questions that survive all of that. A device
answering at an address you cannot find in any rack is a toner probe problem, not a
software one.

## Try it

**Scan a network you own, and only one you own.** Your own home network is the honest
place to practise. Compare the list of things that answer against the list of things you
thought were on it, and note that the two differ, because they always do.

**Read the service names critically.** Pick an open port on something you control and
check what is actually listening against what the scanner named it. The gap between those
two is the lesson.

**Ask a switch what it can see.** If you have any managed switch, its neighbour discovery
table is one command and it will name the device on the other end of each cable. Doing
this once is what makes the case for turning the protocol on across an estate.

## Check yourself

<details class="qa">
<summary>What do you do before running any discovery scan?</summary>

Get authorisation from somebody who can give it, in writing, with the ranges, the ports
and the hours in it, and tell whoever watches the security alerts that it is happening.

Discovery tools and reconnaissance tools are the same tools, and the only thing that
separates the two is permission. On a network your employer does not own, unauthorised
scanning can be an offence regardless of whether anything was harmed. And a scan is
loud: any monitoring worth having will flag a host opening connections to a thousand
ports, so an unannounced one costs somebody an evening.

</details>

<details class="qa">
<summary>A scan reports "999 closed tcp ports (reset)" and one open port. What does the word reset tell you?</summary>

That those 999 ports answered. A reset is a reply, so the scanner did not guess they were
closed, it was told, and being told means the path to that host works in both directions
for all of them.

A port that was filtered rather than closed would have produced no answer at all, and the
scanner reports that differently because it means something different: it cannot tell a
filter from a dead host from a broken path. Closed and filtered are two results, not two
words for one.

</details>

<details class="qa">
<summary>How do you get a diagram of an undocumented network without drawing one?</summary>

Collect the neighbour discovery reports from the devices. Every switch and router
announces itself on each link, saying what it is, which of its own ports the announcement
left by, and how to manage it, so a neighbour reading those knows exactly what is on the
other end of each cable.

Each report names one cable from both ends, which is what lets the reports be joined into
a graph without any prior diagram. The limit is that these announcements are layer 2 and
do not cross a router, so what assembles is one map per broadcast domain.

</details>

<details class="qa">
<summary>What are the four questions to ask a device you have never logged into?</summary>

What have you got, what do you know, who are you talking to, and what were you told to do.

In commands: the interface summary, which lists every interface with its state and
addresses; the routing table, where a letter on each line names how the route was learned
and a marker shows which one was selected; the protocol neighbour list, which shows the
adjacencies and whether they are fully established; and the running configuration, which
is the one to capture into a file before changing anything.

</details>

<details class="qa">
<summary>Which question can no software tool answer, and what answers it?</summary>

Which physical cable is which. No amount of scanning or querying identifies one lead out
of four hundred at an unlabelled patch panel.

A toner probe does. One half injects a signal onto the cable and the other half is a wand
that finds it, and there is no software substitute. The general shape is worth holding:
physical questions need physical tools, because a device can only report the world as it
sees it through the fault you are chasing.

</details>

## References

- [Nmap reference guide](https://nmap.org/book/man.html) - Nmap Project, for the scan types used above and for what closed and filtered mean in its output. Free. Accessed 2026-08-19.
- [IEEE 802.1AB](https://standards.ieee.org/ieee/802.1AB/7822/) - IEEE Standards Association, the link layer discovery protocol, which defines what a neighbour announcement carries and why it stops at a router. Accessed 2026-08-19.
- [FRRouting user guide](https://docs.frrouting.org/en/latest/) - The FRRouting Project, for the show commands in the device capture and what each column of the routing table means. Free. Accessed 2026-08-19.

**Where the numbers came from.** Four captured blocks through `netlab.sh` on the kernel
named in each header. The two scans are on
[`sockets.sh`](https://github.com/rlwilliamson-dev/azure-resume/blob/main/blog/scripts/topologies/sockets.sh),
whose package list gained nmap for them. The neighbour discovery is on
[`trace-path.sh`](https://github.com/rlwilliamson-dev/azure-resume/blob/main/blog/scripts/topologies/trace-path.sh),
which gained lldpd, and each router runs the daemon inside its own mount namespace with its
own run directory, which is visible in the captured command and is what stops three
daemons on one kernel from sharing a control socket. The device commands are FRRouting on
[`three-routers-ospf.sh`](https://github.com/rlwilliamson-dev/azure-resume/blob/main/blog/scripts/topologies/three-routers-ospf.sh),
which is a real routing stack rather than a transcript written to look like one. The
hardware tools are described rather than shown, because none of them exists in software.

**If you also work on Linux systems.** The scanning and neighbour tools here are the same
ones a Linux engineer uses, and what is specific to this topic is the order: find what
exists, ask the devices about each other, then log in. Doing it that way produces a map
before the first change rather than after the first incident.
