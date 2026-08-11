---
title: "How a switch learns"
description: "A switch is told nothing and works out where everything is by watching. How the forwarding table fills, what happens to a frame whose destination it has not learned yet, why entries expire, and what all of that means for anyone with a packet capture running."
deck: "Plug in a new machine and the switch finds it"
track: "network-plus"
level: "working"
order: 150
objectives:
  - "Explain how a switch builds its forwarding table without being configured"
  - "Say what a switch does with a frame whose destination it has not learned"
  - "Read a forwarding table and say what each entry proves"
  - "Explain why entries age out and what the timer interacts with"
  - "Say what a switch gives you that a hub did not"
prerequisites: ["the-boxes-on-a-network"]
tags: ["network-plus", "networking", "switching"]
updated: 2026-08-10
draft: false
examObjectives:
  - exam: "n10-009"
    domain: "2.0"
    objective: "2.2"
sources:
  - title: "IEEE 802.1Q, Bridges and Bridged Networks"
    url: "https://standards.ieee.org/ieee/802.1Q/10323/"
    publisher: "IEEE Standards Association"
    accessed: 2026-08-10
    tier: 1
  - title: "bridge(8)"
    url: "https://man7.org/linux/man-pages/man8/bridge.8.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-10
    tier: 1
  - title: "RFC 826, An Ethernet Address Resolution Protocol"
    url: "https://www.rfc-editor.org/rfc/rfc826"
    publisher: "IETF"
    accessed: 2026-08-10
    tier: 1
symptoms:
  - symptom: "Traffic for one machine appears on a port it has nothing to do with"
    anchor: "what-happens-to-a-frame-it-cannot-place"
  - symptom: "A machine is unreachable for a few seconds after moving to another port"
    anchor: "entries-do-not-last-forever"
---

> **Before you read.** Take a switch out of a box, plug it in, and connect four
> machines to it. Configure nothing. Within seconds it is delivering traffic to
> the right ports rather than shouting everything everywhere.
>
> Nobody told it which machine is on which port, and no machine announced
> itself.
>
> **How does it know, and what does it do in the moment before it knows?**

Topic 04 said a switch reads the destination MAC address and forwards on it.
That leaves the interesting half unanswered, which is how the switch came to know
where any MAC address is. The answer is one rule, applied to every frame, and
almost everything else about switching follows from it.

### Some words you will need

<dl class="terms">
<dt>forwarding table</dt>
<dd>The switch's list of which MAC address is reachable through which port. Also called the MAC address table.</dd>
<dt>flooding</dt>
<dd>Sending a frame out of every port except the one it arrived on.</dd>
<dt>unknown unicast</dt>
<dd>A frame addressed to one machine whose port the switch has not learned.</dd>
<dt>ageing</dt>
<dd>Removing an entry that has not been seen for a while, so the table reflects where things are now.</dd>
<dt>ingress port</dt>
<dd>The port a frame arrived on. The switch learns from this and never forwards back out of it.</dd>
</dl>

## What breaks without this

**You cannot reason about who can see your traffic.** A switch's whole security
value is that it delivers a frame to one port. Knowing the cases where it does
not is the difference between assuming that and knowing it.

**A machine that moves ports becomes a mystery.** Unplug a laptop and move it,
and it may be unreachable for a while for reasons entirely inside the switch,
with nothing wrong at either end.

**Half of the switching topics ahead make no sense.** VLANs, spanning tree and
the layer 2 attacks are all modifications to, or exploits of, the one mechanism
on this page.

## One rule, applied to every frame

A switch does two things with every frame it receives, in this order.

**It learns.** It reads the source MAC address and records that this address is
reachable through the port the frame arrived on. Not the destination, the source.
A frame arriving is evidence about where the sender is.

**It forwards.** It reads the destination MAC address and looks it up in the
table. A hit means send it out of that one port. A miss means flood.

That is the entire algorithm, and it is worth noticing what it does not include.
No configuration, no announcement protocol, no negotiation. The switch is
eavesdropping on traffic it has to handle anyway and taking notes.

Here is a switch with three machines on it and nothing yet said between them.

<details class="predict">
<summary>Nobody has sent anything. One ping goes from h1 to h2. How many entries appear in the switch's table, and which?</summary>

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology one-switch
# the switch, before anybody has said anything
$ ip netns exec sw bridge fdb show br br0 | grep -v permanent
# h1 pings h2
$ ip netns exec h1 ping -c 1 10.0.0.2 > /dev/null 2>&1
# and now the switch knows where both of them are
$ ip netns exec sw bridge fdb show br br0 | grep -v permanent
02:00:00:00:00:01 dev sw-h1 master br0 
02:00:00:00:00:02 dev sw-h2 master br0 
```

</details>

Two entries, not three.

`h1` is there because it sent the echo request. `h2` is there because it sent the
reply. **`h3` is absent because h3 has not spoken**, and a switch learns from
speech and not from presence. A machine can be plugged in, powered on and
perfectly healthy, and be entirely unknown to the switch until it transmits
something.

That last point is worth sitting with, because it is the thing people expect to
work the other way round. The switch has no idea what is connected to a port. It
knows what has spoken through it.

<figure class="learn-figure">
<svg viewBox="0 0 720 366" role="img" aria-labelledby="learn-title" style="width:100%;height:auto;">
<title id="learn-title">A switch forwarding table filling up over the two frames of a single ping</title>
<g font-family="ui-monospace, monospace" fill="currentColor">
<rect x="270" y="18" width="180" height="46" rx="3" fill="currentColor" fill-opacity="0.1" stroke="currentColor" stroke-opacity="0.5"/>
<text x="360" y="46" text-anchor="middle" font-size="11.5">switch</text>
<g stroke="currentColor" stroke-opacity="0.45">
<line x1="300" y1="64" x2="78" y2="110"/>
<line x1="360" y1="64" x2="360" y2="110"/>
<line x1="420" y1="64" x2="642" y2="110"/>
</g>
<g font-size="10.5" fill-opacity="0.7">
<text x="189" y="80" text-anchor="middle">sw-h1</text>
<text x="370" y="92">sw-h2</text>
<text x="531" y="80" text-anchor="middle">sw-h3</text>
</g>
<g font-size="11">
<rect x="30" y="110" width="96" height="32" rx="3" fill="currentColor" fill-opacity="0.1" stroke="currentColor" stroke-opacity="0.5"/>
<text x="78" y="131" text-anchor="middle">h1</text>
<rect x="312" y="110" width="96" height="32" rx="3" fill="currentColor" fill-opacity="0.1" stroke="currentColor" stroke-opacity="0.5"/>
<text x="360" y="131" text-anchor="middle">h2</text>
<rect x="594" y="110" width="96" height="32" rx="3" fill="currentColor" fill-opacity="0.1" stroke="currentColor" stroke-opacity="0.5"/>
<text x="642" y="131" text-anchor="middle">h3</text>
</g>
<text x="12" y="180" font-size="11">1. before anybody speaks</text>
<rect x="12" y="188" width="220" height="86" rx="3" fill="currentColor" fill-opacity="0.05" stroke="currentColor" stroke-opacity="0.45"/>
<text x="24" y="208" font-size="10.5" fill-opacity="0.7">address</text>
<text x="168" y="208" font-size="10.5" fill-opacity="0.7">port</text>
<line x1="24" y1="216" x2="220" y2="216" stroke="currentColor" stroke-opacity="0.3"/>
<text x="24" y="238" font-size="10.5" fill-opacity="0.7">no entries</text>
<text x="12" y="298" font-size="10.5" fill-opacity="0.8">Three machines are plugged in,</text>
<text x="12" y="313" font-size="10.5" fill-opacity="0.8">powered on and healthy. The</text>
<text x="12" y="328" font-size="10.5" fill-opacity="0.8">switch knows about none of them.</text>
<text x="250" y="180" font-size="11">2. h1 sends to h2</text>
<rect x="250" y="188" width="220" height="86" rx="3" fill="currentColor" fill-opacity="0.05" stroke="currentColor" stroke-opacity="0.45"/>
<text x="262" y="208" font-size="10.5" fill-opacity="0.7">address</text>
<text x="406" y="208" font-size="10.5" fill-opacity="0.7">port</text>
<line x1="262" y1="216" x2="458" y2="216" stroke="currentColor" stroke-opacity="0.3"/>
<text x="262" y="238" font-size="10">02:00:00:00:00:01</text>
<text x="406" y="238" font-size="10">sw-h1</text>
<text x="250" y="298" font-size="10.5" fill-opacity="0.8">Learned from the source address.</text>
<text x="250" y="313" font-size="10.5" fill-opacity="0.8">The destination is still unknown,</text>
<text x="250" y="328" font-size="10.5" fill-opacity="0.8">so this frame goes to h2 and h3.</text>
<text x="488" y="180" font-size="11">3. h2 replies to h1</text>
<rect x="488" y="188" width="220" height="86" rx="3" fill="currentColor" fill-opacity="0.05" stroke="currentColor" stroke-opacity="0.45"/>
<text x="500" y="208" font-size="10.5" fill-opacity="0.7">address</text>
<text x="644" y="208" font-size="10.5" fill-opacity="0.7">port</text>
<line x1="500" y1="216" x2="696" y2="216" stroke="currentColor" stroke-opacity="0.3"/>
<text x="500" y="238" font-size="10">02:00:00:00:00:01</text>
<text x="644" y="238" font-size="10">sw-h1</text>
<text x="500" y="258" font-size="10">02:00:00:00:00:02</text>
<text x="644" y="258" font-size="10">sw-h2</text>
<text x="488" y="298" font-size="10.5" fill-opacity="0.8">Learned from the source again.</text>
<text x="488" y="313" font-size="10.5" fill-opacity="0.8">h1 is known now, so the reply</text>
<text x="488" y="328" font-size="10.5" fill-opacity="0.8">leaves by sw-h1 and nowhere else.</text>
</g>
</svg>
<figcaption>The same table at three moments, matching the capture above. It starts empty, gains one entry from the echo request and a second from the reply, and never gains a third. h3 is connected the whole time and appears nowhere, because nothing about being plugged in puts an address in this table. Notice also that each entry is created by a frame arriving, not by a frame being sent: the switch is reading the source address of traffic it has to handle anyway.</figcaption>
</figure>

<details class="deeper">
<summary>If you already work on networks: CAM, and the acronym the exam lists and never uses</summary>

The forwarding table has more names than it needs, and one of them is on the
exam's acronym list.

CAM stands for content addressable memory, and it is a description of the
hardware rather than of the table. Ordinary memory takes an address and returns
the contents. Content addressable memory does the reverse: you hand it a value,
it searches every location simultaneously, and it returns where that value was
found. Handing it a MAC address and getting back a port number in a single clock
cycle is exactly the operation a switch needs to perform for every frame at line
rate.

So "CAM table" and "MAC address table" and "forwarding table" mostly name the
same thing, with CAM naming the silicon that makes the lookup fast. CompTIA lists
the acronym and the objectives never use it, which is the pattern the research
for this track found repeatedly. Know what it expands to and do not expect a
question built on it.

The consequence that does matter is the one topic 04 introduced: that memory is a
fixed physical size, so a switch holds a stated number of addresses and no more.
Filling it deliberately is an attack, and topic 56 covers what happens next. The
short version is in this page's last section, because it is a direct consequence
of the flooding rule rather than a separate subject.

One term worth keeping straight while the names are on the table. TCAM, with a
T for ternary, is the related hardware that allows a "don't care" bit in a
lookup, which is what access lists and longest prefix matching need. That is a
routing and filtering component rather than a switching one, and it is why a
switch can have plenty of room for MAC addresses and still run out of space for
access list entries.

</details>

## What happens to a frame it cannot place

The miss case is the interesting one, and it has a consequence people rarely
think through.

A frame addressed to a MAC the switch has not learned is an unknown unicast. The
switch cannot drop it, because the destination may well exist and simply not have
spoken yet. It cannot guess. So it does the only safe thing and sends it out of
every port except the one it came in on.

Which means the frame reaches machines it was not addressed to.

<details class="predict">
<summary>h1 sends three pings to h2, and h3 has nothing to do with any of it. How many of those does h3 receive?</summary>

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology one-switch
# tell h1 where h2 is by hand, so no ARP is needed and the only frames are pings
$ ip -n h1 neigh add 10.0.0.2 lladdr 02:00:00:00:00:02 dev h1eth0
# nothing has been sent yet, so the switch has learned nothing
$ ip netns exec sw bridge fdb show br br0 | grep -v permanent
# watch h3, which is not part of this conversation at all
$ (ip netns exec h3 timeout 9 tcpdump -i h3eth0 -n -e -U icmp > /tmp/h3.txt 2>/dev/null &)
$ sleep 2
$ ip netns exec h1 ping -c 3 10.0.0.2 > /dev/null 2>&1
$ sleep 9
# three pings were sent. how many did h3 see?
$ cat /tmp/h3.txt
23:10:39.825294 02:00:00:00:00:01 > 02:00:00:00:00:02, ethertype IPv4 (0x0800), length 98: 10.0.0.1 > 10.0.0.2: ICMP echo request, id 66, seq 1, length 64
```

</details>

One. Read the destination address on it: `02:00:00:00:00:02`, which is h2, on a
frame that arrived at h3.

That is the flood. The switch had learned nothing, the first echo request was
addressed to a MAC it could not place, so it went everywhere. h2 replied, the
switch learned h2's port from that reply, and the second and third pings were
delivered to h2 alone. h3 never saw them.

Two things follow, and the second is the one worth carrying.

**h3's network stack discarded the frame**, because the destination address was
not its own. Nothing was harmed and no application saw anything. The delivery was
wrong and the outcome was correct.

**Unless h3 was listening.** A machine with an interface in promiscuous mode, or
running a packet capture, keeps everything that arrives regardless of the
address on it. So an unknown unicast flood puts somebody else's traffic in front
of anyone who happens to be capturing, without any attack taking place at all.

The ARP request that would normally precede this is a broadcast, and broadcasts
are flooded by definition, every time, to every port. The capture above skips
that by telling h1 h2's address in advance, which is why the only frames on the
wire are the pings themselves.

<details class="deeper">
<summary>If you already work on networks: the two timers that have to agree, and the flooding that happens when they do not</summary>

There are two caches involved in getting a frame from h1 to h2, they live on
different machines, and their default lifetimes are not the same. When they
disagree you get continuous flooding, and the symptom is strange enough to be
worth recognising.

The switch's forwarding table maps a MAC address to a port, and it ages entries
out after a period of silence. The sending host's ARP cache maps an IP address to
a MAC address, and it has its own separate timer.

Consider a machine that is quiet: a printer, a camera, a backup target that is
only spoken to. Its ARP entry on the sender is fresh, because the sender keeps
using it. Its forwarding table entry on the switch has aged out, because the
device itself has not transmitted anything in a while.

Now the sender transmits. It does not need to ARP, because its cache is valid, so
it sends a unicast frame straight to a MAC address the switch has forgotten.
Unknown unicast, so the frame is flooded to every port. The device answers, the
switch relearns, and the conversation proceeds normally until the next silence.

The result is a device whose traffic is quietly flooded across the whole segment
every time somebody talks to it after a pause. Nothing is broken, nothing logs an
error, and on a busy network it is a measurable amount of traffic going to ports
that have no use for it. It is also a small information leak, for the reason in
the section above.

The fix is not a clever one, and it is the reason network equipment tends to be
configured with an ARP timeout shorter than the switch's ageing time rather than
the other way round. Keeping the host cache shorter than the switch table means
the host re-ARPs, which is a broadcast, which refreshes the switch's entry.

Worth knowing mostly because the symptom, unexplained flooding of one device's
traffic, points at timers rather than at anything obviously wrong.

</details>

## Entries do not last forever

A forwarding table that only ever gained entries would be wrong the first time
anybody moved a cable. So entries expire.

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology one-switch
# entries do not last forever. this is how long, in hundredths of a second
$ ip -d -n sw link show br0 | grep -o "ageing_time [0-9]*"
ageing_time 30000
$ ip netns exec h1 ping -c 1 10.0.0.2 > /dev/null 2>&1
$ sleep 4
# how long since each entry was last used and last refreshed
$ ip netns exec sw bridge -s fdb show br br0 | grep -v permanent
02:00:00:00:00:01 dev sw-h1 used 4/4 master br0 
02:00:00:00:00:02 dev sw-h2 used 4/4 master br0 
```

`ageing_time 30000` is in hundredths of a second, so 300 seconds, five minutes.
That is the long-standing default and it is the number worth knowing. An entry
untouched for five minutes is discarded, and the address becomes unknown again
until its owner next transmits.

The `used 4/4` on each entry is the age in seconds: how long since the entry was
last used to forward something, and how long since it was last refreshed by a
frame arriving from that address.

Five minutes is a compromise between two failures. Too short and the table
forgets machines that are merely quiet, and their traffic gets flooded
constantly. Too long and a machine that moves to a different port is unreachable
until the old entry expires, because the switch keeps confidently sending its
traffic to a port it left.

That second case is the one you meet. Move a laptop from one switch port to
another without it transmitting anything, and traffic to it goes to the old port
until something updates the table. In practice the laptop sends something almost
immediately and the entry is corrected in milliseconds, which is why this is
usually invisible. When it is not invisible, this is the mechanism.

<details class="deeper">
<summary>If you already work on networks: what actually fixes the table when a machine moves, and why it is usually instant</summary>

The five minute timer suggests a machine that moves ports is unreachable for up
to five minutes, and that plainly does not happen. Something corrects the table
faster, and it is worth knowing what.

A switch does not only add entries, it moves them. A frame arriving from a known
MAC address on a *different* port than the table says updates the entry
immediately. The switch trusts the most recent evidence, because the most recent
evidence is usually right.

So the ageing timer is not what fixes a move. What fixes a move is the machine
transmitting anything at all from its new location, and a machine that has just
had its link go down and come up transmits almost immediately: an ARP for its
gateway, a DHCP renewal, whatever background chatter it runs. The correction
takes one frame.

Which turns the ageing timer into a fallback rather than a mechanism, covering
the case where a machine leaves and does not come back.

The same property is what makes MAC spoofing straightforward at layer 2, and it
is the honest reason the flooding rule matters for security. A switch believes
the source address of every frame, with no authentication of any kind. Send a
frame claiming to be somebody else's MAC address and the switch updates its table
and starts delivering their traffic to you. Nothing in the mechanism on this page
can detect that, which is why the defences are elsewhere: port security limiting
what a port may claim, and 802.1X authenticating the device before it is allowed
to send at all. Both appear later in the track.

</details>

## Why this is not a hub

A hub had no table and made no decisions. It repeated an incoming electrical
signal out of every other port, so every machine received every frame and sorted
out what was theirs.

Switching replaces that with the mechanism on this page, and the differences that
follow are worth stating precisely because the exam asks for them.

| | Hub | Switch |
| --- | --- | --- |
| Reads the frame | No, repeats a signal | Yes, the destination MAC |
| Where a frame goes | Every other port | One port, once learned |
| Collision domains | One, shared by all ports | One per port |
| Broadcast domains | One | One, unchanged |
| Duplex | Half | Full |

The row that catches people is the last two. **A switch divides collision domains
and does not divide broadcast domains.** A broadcast is flooded to every port by
definition, so every machine on a switch is in one broadcast domain, exactly as
they were on a hub. Dividing broadcast domains needs a router, or a VLAN, which
is the next few topics.

Topic 04's panel counts these from a diagram, which is the form the exam asks the
question in.

The flooding rule is also the honest limit on the security claim. A switch
delivers a unicast frame to one port most of the time, and the exceptions are
broadcasts, multicast without snooping, unknown unicast, and a table that has
been deliberately filled. That last one is an attack, and it works precisely
because a switch's response to not knowing is to flood: overwhelm the table with
invented addresses, force out the real entries, and the switch degrades into a
hub that shows you everything. Topic 56 covers it as an attack. It belongs here
as a consequence.

<details class="deeper">
<summary>If you already work on networks: what "one collision domain per port" is actually worth now</summary>

Collision domains are taught as a headline benefit of switching and the benefit
has largely become historical, which is worth knowing so you can answer the
question without believing the emphasis.

A collision happens when two devices transmit on a shared medium at the same
time. On a hub, every port shares one medium, so as machines are added the
collision rate rises and usable throughput falls well before the wire is full.
That was a real and severe limit.

Full duplex removed it. A switch port with a modern link runs transmit and
receive on separate pairs, so the two ends can send simultaneously by design.
There is no shared medium and there is nothing to collide. CSMA/CD, the access
method that detected and recovered from collisions, is effectively dormant on a
switched full duplex link.

So the accurate framing is that switching divided collision domains and full
duplex then made the division moot. You will still be asked to count them,
because the counting exercise is on the syllabus, and topic 04 covers how.

Where a collision counter genuinely still matters is as a fault signal rather
than a design measure. A port reporting collisions on a link that should be full
duplex is telling you the two ends disagree about duplex, which is the mismatch
topic 18 covers, and late collisions specifically are close to diagnostic of it.
So the counter outlived the thing it was built to measure and became a
troubleshooting tool, which is a fair description of a lot of Ethernet.

</details>

## Prove it

You have this on any machine that can run a bridge, which on Linux is any
machine at all. The topology file is committed, so the whole thing is three
commands.

```bash
# Build the switch and the three hosts, then look at an empty table.
./blog/scripts/netlab.sh --topo topologies/one-switch.sh -- \
  'ip netns exec sw bridge fdb show br br0 | grep -v permanent'

# Send one frame and look again.
./blog/scripts/netlab.sh --topo topologies/one-switch.sh -- \
  'ip netns exec h1 ping -c 1 10.0.0.2 > /dev/null; ip netns exec sw bridge fdb show br br0 | grep -v permanent'
```

Three things to confirm. The table starts empty. One ping produces exactly two
entries. And the third host, which has done nothing, is in neither.

On real equipment the command differs and the output does not. Every managed
switch has a way to show the MAC address table, it lists addresses against ports,
and entries appear and expire on their own. If you have access to one, look at
it, then unplug something and watch the entry disappear five minutes later.

## What trips people up

### 1. Thinking the switch learns from the destination address

It learns from the source. A frame arriving is evidence of where the sender is,
and says nothing reliable about where the recipient is. The destination is used
for the lookup, never for learning.

### 2. Expecting a connected machine to be in the table

A switch knows what has spoken, not what is plugged in. A powered-on machine that
has transmitted nothing is invisible to the forwarding table, and its absence is
not a fault.

### 3. Believing a switch never sends your traffic elsewhere

Broadcasts always go everywhere. Unknown unicast goes everywhere until the
destination speaks. And a table that has been filled deliberately makes
everything unknown unicast. The usual case is one port and the exceptions are the
interesting part.

### 4. Reading ageing as the mechanism that handles a move

A frame from a known address arriving on a different port updates the entry
immediately. The timer only handles machines that leave and do not come back.

### 5. Thinking a switch divides broadcast domains

It divides collision domains and not broadcast domains. A broadcast reaches every
port on the switch. Dividing broadcast domains takes a router or a VLAN.

### 6. Treating collisions as a current concern

Full duplex made them largely historical. A collision counter incrementing on a
link that should be full duplex is now a symptom of a duplex mismatch rather than
a capacity measurement.

## Work it through

A user reports that a network printer is slow to respond the first time anybody
prints after lunch, and fine for the rest of the afternoon. A colleague running
Wireshark on an unrelated machine mentions in passing that they keep seeing print
jobs in their capture, which nobody can explain.

Two symptoms, and they are the same fault.

Start with the printer's behaviour. It is a device that receives and rarely
initiates. It answers when spoken to and otherwise says nothing, so it transmits
only in response to traffic. That is exactly the profile that ages out of a
forwarding table: five minutes of nobody printing and the switch forgets which
port it is on.

Now the second symptom. When somebody prints after that gap, their machine's ARP
cache still holds the printer's MAC address, so it sends a unicast frame without
asking anybody. That frame is addressed to an address the switch has forgotten,
which makes it an unknown unicast, which floods it to every port. The colleague
with a capture running receives it, because a capture keeps everything that
arrives regardless of who it was for.

So the print jobs in somebody else's capture are not a misconfiguration, a
security failure or a broken switch. They are the flooding rule doing exactly
what it is specified to do, on a device quiet enough to age out between uses.

The slowness is the same event seen from the other end, and it is worth being
careful here: flooding itself is fast. If the first job is genuinely slow, the
delay is more likely the printer waking from a sleep state than anything in the
switch, and it is worth separating the two rather than assuming one cause.

What to do about it depends on how much it matters. The mechanism is normal and
usually ignored. If the leak matters, the answers are shortening the ARP cache
timeout on the senders so they re-ARP and refresh the switch, or putting printers
in their own VLAN so the flood reaches a smaller set of ports. Both are covered
in the next few topics, and both are worth more than trying to stop the switch
from flooding, which is not a thing you can turn off without breaking it.

## Try it

**Watch a table fill.** Run the commands from **Prove it**. It takes about a
minute and seeing an empty table populate from one ping makes the mechanism
concrete in a way reading it does not.

**Reproduce the flood.** Use the flooding capture's command list against the same
topology, but change `ping -c 3` to `ping -c 10`, and confirm that h3 still sees
exactly one frame. The number of pings does not change the answer, which is the
point.

**Find the table on real equipment.** If you have a managed switch, a home router
with a web interface, or access to one at work, find the MAC address table. It is
usually under a status or monitoring menu. Count the entries and compare that to
how many devices you believe are connected. The gap is the machines that have not
spoken recently.

## Check yourself

<details class="qa">
<summary>Three machines are connected to a switch and one sends a single ping to another. How many entries are in the forwarding table afterwards, and why?</summary>

Two. The sender and the replier.

The switch learns from the source address of every frame it receives. The echo
request taught it where the sender is, and the echo reply taught it where the
responder is.

The third machine is absent because it has not transmitted anything. A switch
learns from traffic rather than from a machine being connected, so a powered-on
device that has said nothing does not appear.

</details>

<details class="qa">
<summary>Why does a frame addressed to one machine sometimes arrive at a machine it was not addressed to?</summary>

Because the switch had not learned which port the destination was on, so it
flooded the frame out of every port except the one it arrived on.

That is an unknown unicast. The switch cannot drop it, since the destination may
exist and simply not have transmitted yet, and it cannot guess a port, so
flooding is the only safe option.

The receiving machine normally discards it because the destination address is not
its own. A machine running a packet capture keeps it, which is how somebody else's
traffic ends up in your capture with no attack involved.

</details>

<details class="qa">
<summary>A device is moved from port 4 to port 12. The ageing time is five minutes. How long is it unreachable?</summary>

Usually milliseconds, not minutes.

A frame arriving from a known MAC address on a different port updates the entry
immediately, because the switch trusts the most recent evidence. A device that has
just been plugged in transmits almost at once, so the table is corrected by the
first frame it sends.

The ageing timer is a fallback for devices that leave and do not return. It is not
what handles a move.

</details>

<details class="qa">
<summary>A quiet device's traffic is being flooded across the segment every time somebody contacts it. Nothing is misconfigured. What is happening?</summary>

Two caches with different lifetimes have got out of step.

The device is quiet, so it transmits nothing, so its entry ages out of the
switch's forwarding table. The senders' ARP caches still hold its MAC address,
because they keep using it, so when somebody contacts it they send a unicast frame
without ARPing first.

That frame is addressed to a MAC the switch has forgotten, which makes it unknown
unicast, so it floods. The device replies, the switch relearns, and the pattern
repeats after the next silence.

The usual mitigation is keeping the host ARP timeout shorter than the switch
ageing time, so hosts re-ARP and the broadcast refreshes the switch's entry.

</details>

<details class="qa">
<summary>Does a switch divide collision domains, broadcast domains, or both?</summary>

Collision domains only. Each port is its own collision domain, where a hub had
one shared across all its ports.

Broadcast domains are unchanged. A broadcast is flooded to every port by
definition, so every machine on a switch remains in one broadcast domain.
Dividing those requires a router or a VLAN.

Worth adding that the collision half is largely historical. Full duplex means
there is no shared medium and nothing to collide, so the division that switching
introduced stopped mattering shortly afterwards.

</details>

<details class="qa">
<summary>Why does deliberately filling a switch's forwarding table turn it into something like a hub?</summary>

Because the switch's response to an address it cannot find is to flood.

The table is a fixed size in hardware. Fill it with invented source addresses and
the real entries are pushed out. Every subsequent frame is then addressed to
something the switch cannot place, so every frame is flooded to every port, and
anyone capturing sees the whole segment.

Nothing about the switch has broken. The flooding rule is behaving exactly as
specified, on a table that has been made useless. Topic 56 covers the attack and
the defences.

</details>

## References

- [IEEE 802.1Q, Bridges and Bridged Networks](https://standards.ieee.org/ieee/802.1Q/10323/) - IEEE Standards Association, which specifies learning, flooding and ageing. The scope is readable without purchase; the standard is not. Accessed 2026-08-10.
- [bridge(8)](https://man7.org/linux/man-pages/man8/bridge.8.html) - Linux man-pages project, the tool used for every capture on this page. Accessed 2026-08-10.
- [RFC 826, An Ethernet Address Resolution Protocol](https://www.rfc-editor.org/rfc/rfc826) - IETF, for the ARP cache half of the two-timer panel. Accessed 2026-08-10.

**Where the output came from.** All three captured blocks were produced on a new
namespace topology, `blog/scripts/topologies/one-switch.sh`, through
`blog/scripts/netlab.sh`. A Linux bridge is a real switch rather than a
simulation: it learns, floods, ages, and the numbers on this page are its own.

One thing about that topology is worth knowing, because it is the only place in
this track where a lab has been made deliberately quieter than a real network.
IPv6 is disabled on every node. A switch learns from any frame, and bringing an
IPv6 interface up generates duplicate address detection and multicast listener
traffic before anything has been asked to send anything, which filled the
forwarding table before the first ping and made learning impossible to observe.
On a real network that background chatter is present and the table fills the same
way, from whatever spoke first.

**If you also work on Linux.** The bridge used here is the same one behind
container networking, and [Container images, volumes and networks](/learn/linux-plus/container-images-volumes-and-networks)
on the Linux+ track covers it from that angle. The learning and flooding
behaviour is identical, because it is the same code.
