---
title: "Interface configuration and link aggregation"
description: "Speed and duplex, what auto-negotiation does when only one end is playing, why a duplex mismatch produces a slow link rather than a broken one, and what bonding two cables together actually buys you, which is not what most people expect."
deck: "The link is up at 100 Mb on a gigabit switch"
track: "network-plus"
level: "working"
order: 190
objectives:
  - "Say what speed and duplex are negotiated and what happens when one end cannot"
  - "Explain why a duplex mismatch is slow rather than dead"
  - "Recognise late collisions as the signature of that mismatch"
  - "Say what link aggregation gives you and what it does not"
  - "Explain why a single transfer does not get faster across a bonded pair"
prerequisites: ["how-a-switch-learns"]
tags: ["network-plus", "networking", "switching"]
updated: 2026-08-10
draft: false
examObjectives:
  - exam: "n10-009"
    domain: "2.0"
    objective: "2.2"
sources:
  - title: "IEEE 802.3 Standard for Ethernet"
    url: "https://standards.ieee.org/ieee/802.3/10422/"
    publisher: "IEEE Standards Association"
    accessed: 2026-08-10
    tier: 1
  - title: "IEEE 802.1AX, Link Aggregation"
    url: "https://standards.ieee.org/ieee/802.1AX/7469/"
    publisher: "IEEE Standards Association"
    accessed: 2026-08-10
    tier: 1
  - title: "Linux Ethernet Bonding Driver HOWTO"
    url: "https://www.kernel.org/doc/Documentation/networking/bonding.txt"
    publisher: "Linux kernel documentation"
    accessed: 2026-08-10
    tier: 1
symptoms:
  - symptom: "A gigabit link negotiates at 100 Mb"
    anchor: "speed-duplex-and-what-negotiation-actually-does"
  - symptom: "A link is up and throughput is a fraction of what it should be"
    anchor: "the-mismatch-and-why-it-is-slow-rather-than-dead"
  - symptom: "Two bonded links and a single transfer is no faster"
    anchor: "aggregation-and-what-it-does-not-give-you"
---

> **Before you read.** A server is plugged into a gigabit switch with a
> gigabit card and a cable rated well past gigabit. The link is up and everything
> works.
>
> The interface reports 100 Mb, half duplex.
>
> **Nothing is broken and nobody configured it that way. What happened?**

Most of this track is about what happens after a link works. This topic is about
the link itself: the two things every Ethernet connection agrees before it
carries anything, what happens when the agreement goes wrong, and why the wrong
answer is a slow network rather than a dead one.

### Some words you will need

<dl class="terms">
<dt>duplex</dt>
<dd>Whether both ends may transmit at once. Full duplex means yes, half means take turns.</dd>
<dt>auto-negotiation</dt>
<dd>Two interfaces exchanging what they support and settling on the best both can do.</dd>
<dt>parallel detection</dt>
<dd>What an interface falls back to when the other end does not negotiate at all.</dd>
<dt>late collision</dt>
<dd>A collision detected after the first 64 bytes of a frame. On a modern link, a symptom rather than an event.</dd>
<dt>link aggregation</dt>
<dd>Treating several physical links between two devices as one logical link.</dd>
<dt>LACP</dt>
<dd>Link Aggregation Control Protocol. How two devices agree to form a bond.</dd>
</dl>

## What breaks without this

**A slow network with nothing wrong in it.** A duplex mismatch leaves everything
up and working, at a fraction of the throughput, and no tool reports an error
unless you go and read the counters.

**Somebody bonds two links and reports that it did not help.** Aggregation
behaves in a way that surprises people, and knowing what it is for before
promising it to anybody saves an awkward conversation.

**A port is disabled and nobody can say why.** Administrative state and link
state are different things reported side by side, and reading them the wrong way
sends people to the wrong end of the cable.

## Speed, duplex, and what negotiation actually does

Two interfaces have to agree on two things before a link carries anything: how
fast, and whether both may talk at once.

Auto-negotiation is how they agree. Each end advertises what it supports, both
pick the best they have in common, and the link comes up. When both ends
negotiate, this works and nobody thinks about it, which is why the failure is
confusing when it arrives.

The failure is one end not negotiating. Somebody has hard-set the speed and
duplex on a switch port, usually years ago, for a reason nobody remembers. A
hard-set interface stops advertising, so the other end has nothing to negotiate
with.

What it does then is a rule worth knowing, because it produces the exact symptom
at the top of this page. The negotiating end falls back to parallel detection: it
can still sense the link's signalling and work out the speed, but there is no way
to detect duplex from the signal. So it guesses, and the specified guess is half
duplex.

**One end hard-set to full, the other guessing half.** Both ends are up. Neither
is misconfigured in any way a tool will complain about. And the speed drop in the
opening scenario is the same story a step further, where the fallback also failed
to sense the higher speed.

The rule that follows: hard-set both ends or negotiate on both ends, never one of
each. Setting one end to be certain is the thing that causes the problem it was
meant to prevent.

<details class="deeper">
<summary>If you already work on networks: why a duplex mismatch is slow rather than broken, and what a late collision means</summary>

A duplex mismatch does not break a link, which is exactly what makes it hard to
find. Understanding why needs the two ends' assumptions side by side.

The full duplex end believes it may transmit whenever it likes, because on a full
duplex link nobody collides. It ignores carrier sense entirely.

The half duplex end believes it must listen before transmitting and must watch
for collisions while it does. That is CSMA/CD, the access method half duplex
Ethernet has always used.

Now put them together. The full duplex end sends whenever it wants, including
while the half duplex end is mid-frame. The half duplex end detects that as a
collision, aborts its own frame, and backs off. Meanwhile the frame it aborted is
lost, and the full duplex end has no idea anything happened.

So the link works, and it drops frames whenever both ends happen to talk at once.
TCP handles the loss by retransmitting, which topic 09 showed collapses the
congestion window, so throughput falls off a cliff under load and looks fine when
idle. That combination, fine when tested and terrible when used, is the
fingerprint.

The counter that names it is the late collision. An ordinary collision on a
correct half duplex segment is detected within the first 64 bytes, because the
segment is short enough that a collision at the far end propagates back before
the frame finishes. A collision detected after 64 bytes means the other end
started transmitting long after it should have known the wire was busy, and on a
correctly configured link that cannot happen.

**Late collisions on a link that should be full duplex are close to diagnostic of
a duplex mismatch.** Topic 14's panel made the point that the collision counter
outlived the thing it measured and became a troubleshooting tool. This is the
case it became a tool for. Late collisions appear at the half duplex end, and
frame check sequence errors usually appear at the other, so the two ends report
different symptoms of the same fault.

</details>

## Enabling and disabling an interface

Two independent states, reported together, and reading them the wrong way round
wastes an afternoon.

Topic 01 introduced both without naming the distinction. `UP` is administrative:
somebody enabled the interface, and it stays that way whether or not anything is
plugged in. `LOWER_UP` is physical: the driver can see something at the other end
of the cable.

| What you see | What it means |
| --- | --- |
| UP, LOWER_UP | Enabled, and something is there |
| UP, no LOWER_UP | Enabled, and nothing is plugged in or the far end is off |
| No UP | Somebody disabled it. The cable is irrelevant |

An interface that is administratively down does not care about the cable, and
that is the case people misdiagnose: hours spent on a cable that was never the
problem, because the port was shut and nobody looked at the first flag.

The reverse also matters for security work. Disabling unused ports is standard
hardening, so an unused socket in a meeting room grants nothing, and topic 45's
material on reducing what is exposed applies directly here.

## Aggregation, and what it does not give you

Link aggregation combines several physical links between the same two devices
into one logical link. Two cables, one interface as far as everything above it is
concerned.

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology one-switch
# two devices, one logical link built from the physical ones between them
$ ip -n h1 link add bond0 type bond mode 802.3ad
$ ip -n h1 link set h1eth0 down
$ ip -n h1 link set h1eth0 master bond0
$ ip -n h1 addr add 10.0.0.1/24 dev bond0
$ ip -n h1 link set bond0 up
$ ip -n h1 link set h1eth0 up
# what it negotiated, and how it decides which member carries a given flow
$ ip -d -n h1 link show bond0 | grep -oE "mode 802[0-9a-z.]*|xmit_hash_policy [a-z0-9+]+|lacp_active [a-z]+|lacp_rate [a-z]+"
mode 802.3ad
xmit_hash_policy layer2
lacp_active on
lacp_rate slow
# the member is now a slave and the bond holds the address
$ ip -n h1 -br link show
lo               UNKNOWN        00:00:00:00:00:00 <LOOPBACK,UP,LOWER_UP> 
bond0            UP             02:00:00:00:00:01 <BROADCAST,MULTICAST,MASTER,UP,LOWER_UP> 
h1eth0@if3       UP             02:00:00:00:00:01 <BROADCAST,MULTICAST,SLAVE,UP,LOWER_UP> 
```

Three fields in that output are the vocabulary.

`mode 802.3ad` is LACP, the protocol the two ends use to agree that they are
forming a bond and which links are in it. The alternative is configuring both
ends statically, which works and has no way to notice when one end disagrees.
LACP exchanges keepalives, so a member that is up but not actually passing
traffic can be taken out of the bond.

`lacp_rate slow` is how often those keepalives go, and slow means every 30
seconds. Fast means every second, and detects a failure much quicker at the cost
of more chatter.

`xmit_hash_policy layer2` is the important one, and it is where the surprise
lives.

**A bond does not split a conversation across its members.** It hashes something
from each frame, here the MAC addresses, and uses the result to pick one member.
Every frame with the same hash takes the same link, which is deliberate: splitting
one conversation across two links of slightly different latency would deliver
frames out of order, and TCP reads out of order delivery as loss.

<figure class="learn-figure">
<svg viewBox="0 0 720 264" role="img" aria-labelledby="bond-title" style="width:100%;height:auto;">
<title id="bond-title">Two physical links bonded into one logical link, with each conversation pinned to a single member</title>
<g font-family="ui-monospace, monospace" fill="currentColor">
<text x="17" y="26" font-size="11.5" fill-opacity="0.75">two cables between the same two devices, presented upward as one interface</text>
<rect x="157" y="74" width="406" height="112" rx="4" fill="currentColor" fill-opacity="0.05" stroke="currentColor" stroke-opacity="0.45" stroke-dasharray="6 4"/>
<text x="360" y="94" text-anchor="middle" font-size="11">bond0, one logical link</text>
<g stroke="currentColor" stroke-width="2.6">
<line x1="157" y1="126" x2="222" y2="126"/>
<line x1="318" y1="126" x2="336" y2="126"/>
<line x1="416" y1="126" x2="563" y2="126"/>
<line x1="157" y1="164" x2="222" y2="164"/>
<line x1="318" y1="164" x2="563" y2="164"/>
</g>
<text x="171" y="120" font-size="10" fill-opacity="0.75">member 1</text>
<text x="171" y="158" font-size="10" fill-opacity="0.75">member 2</text>
<rect x="222" y="112" width="96" height="26" rx="3" fill="currentColor" fill-opacity="0.2" stroke="currentColor" stroke-width="1.6"/>
<text x="270" y="129" text-anchor="middle" font-size="10">file copy</text>
<rect x="336" y="112" width="80" height="26" rx="3" fill="currentColor" fill-opacity="0.12" stroke="currentColor" stroke-opacity="0.55"/>
<text x="376" y="129" text-anchor="middle" font-size="10">web</text>
<rect x="222" y="150" width="96" height="26" rx="3" fill="currentColor" fill-opacity="0.12" stroke="currentColor" stroke-opacity="0.55"/>
<text x="270" y="167" text-anchor="middle" font-size="10">backup</text>
<rect x="17" y="88" width="140" height="84" rx="3" fill="currentColor" fill-opacity="0.1" stroke="currentColor" stroke-opacity="0.5"/>
<text x="87" y="135" text-anchor="middle" font-size="11.5">switch A</text>
<rect x="563" y="88" width="140" height="84" rx="3" fill="currentColor" fill-opacity="0.1" stroke="currentColor" stroke-opacity="0.5"/>
<text x="633" y="135" text-anchor="middle" font-size="11.5">switch B</text>
<text x="17" y="212" font-size="11">Each conversation is hashed once and lives on one member for its whole life.</text>
<text x="17" y="230" font-size="11" fill-opacity="0.85">Across many conversations that is two gigabits. For the file copy on its own it is one.</text>
<text x="17" y="248" font-size="11" fill-opacity="0.85">Lose a member and the bond stays up with half the capacity, which is often the real reason to build one.</text>
</g>
</svg>
<figcaption>Two cables, drawn inside the logical link they add up to. The three labelled blocks are conversations, and the thing to notice is that none of them straddles both lines. A frame's addresses are hashed, the hash picks a member, and every later frame of that conversation hashes to the same answer and takes the same cable. That is not a limitation somebody forgot to lift: sending half a conversation down each link would deliver frames out of order, and TCP reads out of order arrival as loss.</figcaption>
</figure>

So two bonded gigabit links give two gigabits of aggregate capacity across many
conversations, and any single transfer still runs at one gigabit. Somebody
copying one large file sees no improvement whatsoever, and this is the promise
that gets made and broken.

What aggregation genuinely buys is capacity in aggregate, and redundancy: lose one
member and the bond stays up with less capacity, which is often the real reason
to build one.

<details class="deeper">
<summary>If you already work on networks: choosing a hash, and the case where it makes everything worse</summary>

The hash policy decides which member a flow lands on, and the default is
frequently wrong for the traffic you actually have.

Hashing on MAC addresses is the simplest and it fails in the most common topology
there is. Consider a bonded uplink from an access switch to a router. Every frame
going upstream has the same destination MAC, the router's, and every frame coming
back has the same source. So the hash produces the same answer for nearly
everything, every flow lands on one member, and the second link carries almost
nothing while the first saturates.

The measurement is bleak and the diagnosis is easy: interface counters on a bond
whose members are wildly unequal are telling you the hash is not distributing.

Hashing on IP addresses fixes the router case, because the addresses differ per
conversation even when the MACs do not. Hashing on addresses and ports
distributes better still, and separates multiple conversations between the same
pair of machines, which matters for a backup server or a database replica talking
to one peer.

The limit nobody escapes is that a single flow is a single flow. No hash policy
splits one TCP connection, because doing so would reorder it. If one transfer
needs more than one link's worth of bandwidth, aggregation is not the answer and
a faster link is.

Two practical notes. Both ends should agree on a policy, and they do not have to,
since the hash decides only which member this end transmits on. Asymmetric
policies work and produce traffic distributed one way and not the other, which is
a confusing thing to measure.

And there is a specific failure worth naming: a bond configured on one end and
not the other. LACP prevents it by refusing to bring members up without a partner,
which is a good argument for LACP over static configuration. Statically bonded on
one end and separate ports on the other gives you two switch ports carrying the
same MAC address, which is a loop, and topic 19 is about what a loop does.

</details>

## Prove it

You have this when you can look at an interface and say what was negotiated and
whether both ends agreed.

```bash
# Linux: speed, duplex and whether negotiation happened
ethtool <interface> | grep -E "Speed|Duplex|Auto-negotiation"

# the error counters that name a duplex mismatch
ip -s link show <interface>
```

Three things to look at. The negotiated speed and duplex. Whether
auto-negotiation is on. And whether the error counters are moving, because a
counter that is non-zero and static is history while one that climbs under load
is a live fault.

On Windows the same facts are in the adapter's advanced properties and in
`Get-NetAdapter`. On a switch, the interface status page reports speed, duplex
and whether each was negotiated or forced, and the forced ones are what to be
suspicious of.

The honest limit: this is the one topic in the block with nothing captured about
its main subject. Speed and duplex are properties of physical Ethernet hardware,
and the virtual interfaces this track's labs are built from have neither. The
bonding block above is real; there is no honest way to produce a duplex mismatch
in a namespace, so this page does not pretend to.

## What trips people up

### 1. Hard-setting one end to be certain

That is the cause rather than the cure. A hard-set interface stops advertising,
the other end falls back to guessing, and the specified guess for duplex is half.
Set both ends or negotiate on both.

### 2. Expecting a duplex mismatch to break the link

It does not. Both ends come up and work, and the link drops frames whenever both
transmit at once, so it is fine when idle and terrible under load.

### 3. Reading UP and LOWER_UP as one thing

`UP` is somebody having enabled the interface. `LOWER_UP` is something being
plugged in. An interface that is administratively down does not care about the
cable at all.

### 4. Promising that bonding makes a transfer faster

It does not. A bond hashes each flow onto one member to keep frames in order, so
a single transfer gets one link's worth. Aggregation buys capacity across many
conversations, and redundancy.

### 5. Leaving the hash policy at the default on an uplink

A bond to a router hashing on MAC addresses sends nearly everything down one
member, because the router's MAC is on every frame. Wildly unequal member
counters are the sign.

### 6. Static bonding instead of LACP

A static bond has no way to notice that the far end is not bonded. Configured on
one end only, it presents the same MAC on two switch ports, which is a loop.

## Work it through

A backup job that used to finish overnight now runs into the morning. The server
and the switch both report the link up at one gigabit. The network team confirms
no changes. The server team confirms no changes. Throughput measures about 30
megabits.

Start with the gap between reported and measured, because it is enormous.
Thirty megabits on a link reporting a gigabit is not congestion and not a slow
disk, both of which would land much closer to the line rate. A factor of thirty
means something is going wrong per packet.

Duplex mismatch fits the shape exactly. Both ends report up, the speed negotiated
correctly, and the duplex did not. Under a backup's sustained load both ends
transmit constantly, collisions happen continuously at the half duplex end, and
TCP's response to that loss is to collapse its window, which topic 09 showed
produces precisely this: no errors anywhere and throughput on the floor.

The check is the counters, at both ends, and they will disagree with each other.
Late collisions at the half duplex end, and frame errors at the other. Both ends
matter here: reading only one gives half the evidence and the half you get
depends on which end you logged into first.

The likely history is worth guessing at because it points at the fix. Somebody
hard-set that switch port years ago, the server was replaced, the new card
negotiates, and the mismatch arrived with the new hardware while everybody was
looking at the backup software.

Two things not to do. Do not conclude the network needs upgrading, because the
link is already fast enough and the problem is that it is not being used. And do
not fix it by hard-setting the server to match, which works and leaves the trap
armed for the next person. Set both ends to negotiate.

## Try it

**Read your own interface.** Run `ethtool` on any Linux machine with a wired
connection, or open the adapter properties on Windows. Note the speed, the
duplex, and whether negotiation is on. Most people have never looked.

**Look at the counters.** `ip -s link show` prints errors and drops per
interface. On a healthy link they are zero or a small static number from a cable
being moved. A counter climbing while you watch is a live fault.

**Find a bond if you have one.** Any server with two cables to a switch probably
has one. `cat /proc/net/bonding/bond0` on Linux gives the mode, the hash policy
and the state of each member, and comparing the byte counters of the two members
tells you whether the hash is actually distributing.

## Check yourself

<details class="qa">
<summary>A switch port is hard-set to 1000 full. The server negotiates. What does the server end up at, and why?</summary>

Probably 1000 half, or slower.

A hard-set interface stops sending negotiation advertisements, so the server has
nothing to negotiate with and falls back to parallel detection. That can sense
the speed from the signalling, and there is no way to detect duplex from the
signal, so the specified fallback is half duplex.

The result is one end full and one end half, both up, neither reporting a
configuration error.

</details>

<details class="qa">
<summary>Why does a duplex mismatch produce a slow link instead of a dead one?</summary>

Because both ends work, they just disagree about the rules.

The full duplex end transmits whenever it likes, including while the other end is
mid-frame. The half duplex end sees that as a collision, aborts its frame and
backs off, so frames are lost whenever both happen to transmit at once.

TCP retransmits the losses and cuts its congestion window in response, so
throughput collapses under load and looks perfectly fine when the link is idle.
That is why it survives testing and fails in production.

</details>

<details class="qa">
<summary>What is a late collision and why is it diagnostic?</summary>

A collision detected after the first 64 bytes of a frame.

On a correctly configured half duplex segment that cannot happen, because the
segment is short enough that a collision at the far end propagates back before
64 bytes have been sent. A collision arriving later means the other end started
transmitting long after it should have known the wire was busy.

The end that reports late collisions is the half duplex end of a duplex mismatch.
The other end usually reports frame check sequence errors instead, so the two
ends describe the same fault differently.

</details>

<details class="qa">
<summary>Two gigabit links are bonded between a server and a switch. How fast is a single large file copy?</summary>

One gigabit.

A bond hashes each flow onto one member and sends every frame of that flow down
the same link. That is deliberate: splitting one conversation across two links
would deliver frames out of order, and TCP reads reordering as loss.

Two gigabits is the aggregate across many conversations. A single transfer is a
single flow and gets one member's worth, which is why bonding disappoints anyone
who was promised a faster copy.

What it does buy is capacity across many flows, and redundancy when a member
fails.

</details>

<details class="qa">
<summary>A bonded uplink to a router shows one member carrying almost all the traffic. What is wrong?</summary>

The hash policy, most likely hashing on MAC addresses.

Every frame going up to the router has the router's MAC as its destination, and
everything coming back has it as the source. So the hash produces nearly the same
answer for all of it and picks the same member every time.

Hashing on IP addresses fixes it, because the addresses differ per conversation
even when the MACs do not. Hashing on addresses and ports distributes better again
and separates several conversations between the same pair of machines.

</details>

<details class="qa">
<summary>Why is LACP preferable to configuring a bond statically at both ends?</summary>

Because a static bond cannot tell whether the far end agrees.

LACP exchanges keepalives, so both ends confirm they are bonding, and a member
that is physically up but not passing traffic can be removed from the bond.

The failure a static bond allows is a bond configured on one end and not the
other. That presents the same MAC address on two separate switch ports, which is
a loop, and the next topic is about what a loop does to a network.

</details>

## References

- [IEEE 802.3 Standard for Ethernet](https://standards.ieee.org/ieee/802.3/10422/) - IEEE Standards Association, which specifies auto-negotiation, parallel detection and the half duplex fallback. Accessed 2026-08-10.
- [IEEE 802.1AX, Link Aggregation](https://standards.ieee.org/ieee/802.1AX/7469/) - IEEE Standards Association, which defines LACP. Accessed 2026-08-10.
- [Linux Ethernet Bonding Driver HOWTO](https://www.kernel.org/doc/Documentation/networking/bonding.txt) - Linux kernel documentation, on the modes and hash policies in the capture. Accessed 2026-08-10.

**Where the output came from.** The bonding block was produced on
`blog/scripts/topologies/one-switch.sh` through `blog/scripts/netlab.sh`, and the
bond, its mode and its hash policy are the kernel's own.

Everything about speed and duplex on this page is sourced rather than captured,
and that is a real gap rather than an oversight. Those are properties of physical
Ethernet hardware negotiating over copper, and a veth pair in a namespace has no
speed, no duplex and no negotiation to observe. Producing a duplex mismatch would
mean writing a transcript by hand, which this track does not do. The **Prove it**
section names the commands to run on hardware instead.

**If you also work on Linux.** [Configuring networking](/learn/linux-plus/configuring-networking)
on the Linux+ track covers interface state and making it persist across a reboot,
which is the administration half of the first part of this page.
