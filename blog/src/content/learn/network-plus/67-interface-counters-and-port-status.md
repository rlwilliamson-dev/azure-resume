---
title: "Interface counters and port status"
description: "The interface is up and the counters are climbing. Why an error and a drop are different sentences about a frame, what each counter narrows the fault to, why a number is worthless until you read it twice, and how to tell a port that was switched off from one with nothing on the end of it."
deck: "The interface is up and the counters are climbing"
track: "network-plus"
level: "working"
order: 680
objectives:
  - "Read an interface counter as a total since the port appeared, not as a rate"
  - "Tell an error from a drop and say what each one narrows the fault to"
  - "Recognise frame check errors, runts, giants and drops by what they mean"
  - "Tell administratively down from down with nothing on the far end"
  - "Read a rising carrier transition count as a flapping link"
prerequisites: ["interface-configuration-and-link-aggregation"]
tags: ["network-plus", "networking", "troubleshooting", "interfaces"]
updated: 2026-08-19
draft: false
examObjectives:
  - exam: "n10-009"
    domain: "5.0"
    objective: "5.2"
sources:
  - title: "ip-link(8)"
    url: "https://man7.org/linux/man-pages/man8/ip-link.8.html"
    publisher: "man7.org"
    accessed: 2026-08-19
    tier: 1
  - title: "IEEE 802.3 Standard for Ethernet"
    url: "https://standards.ieee.org/ieee/802.3/10422/"
    publisher: "IEEE Standards Association"
    accessed: 2026-08-19
    tier: 1
  - title: "Get-NetAdapterStatistics"
    url: "https://learn.microsoft.com/powershell/module/netadapter/get-netadapterstatistics"
    publisher: "Microsoft"
    accessed: 2026-08-19
    tier: 1
  - title: "netstat(1), macOS"
    url: "https://keith.github.io/xcode-man-pages/netstat.1.html"
    publisher: "Apple"
    accessed: 2026-08-19
    tier: 2
symptoms:
  - symptom: "An interface is up and its error counters are non-zero"
    anchor: "a-counter-is-a-total-so-read-it-twice"
  - symptom: "A port is down and nothing was configured to make it so"
    anchor: "three-ports-three-different-kinds-of-down"
  - symptom: "A link keeps dropping and coming back"
    anchor: "the-port-that-will-not-stay-up"
---

> **Before you read.** A switch port has errors on it. The number is not zero, it
> is not small, and it has been sitting there in the monitoring system for weeks.
> The link is up. The user is working. Nobody has complained.
>
> **Is that number a fault you have not found yet, or is it history?**

Counters are the cheapest evidence on a network and the most misread. They are
free, they are already being collected, and they will tell you which layer to look
at before you touch a cable, as long as you know two things: what each one counts,
and that a single reading of any of them means almost nothing.

## Some words you will need

<dl class="terms">
<dt>counter</dt>
<dd>A running total since the port appeared. Not a rate, and not a measure of now.</dd>
<dt>error</dt>
<dd>A frame that arrived and was rejected because something was wrong with the frame itself.</dd>
<dt>drop</dt>
<dd>A frame that was refused or discarded although nothing was wrong with it. A statement about the port, not the frame.</dd>
<dt>frame check sequence</dt>
<dd>The checksum at the end of every Ethernet frame. If it does not match, the bits changed in transit.</dd>
<dt>runt, giant</dt>
<dd>A frame below the minimum legal size, and one above the maximum.</dd>
<dt>carrier transition</dt>
<dd>One change of link state. A count of how many times the port has come up or gone down.</dd>
</dl>

## What breaks without this

**Old damage gets investigated as a live fault.** A non-zero counter that has not
moved since a bad cable was replaced last year looks identical to one that is
climbing right now, and an afternoon disappears into the difference.

**A real fault is missed because the link is up.** Up is a very low bar. A port
passing traffic while discarding a percentage of it reports itself as healthy in
every summary view, and the only place the loss is visible is the counter nobody
opened.

**A port that was deliberately switched off gets treated as a failure.** Somebody
shuts a port for a reason, the reason is not written down, and the next person
spends an hour looking for a broken cable that does not exist.

## What the counters actually are

Here is a switch port with nothing wrong with it, read in full. The switch is a
Linux bridge, which is a real switch rather than a drawing of one, and `sw-h3` is
one of its ports. The topology is
[`one-switch.sh`](https://github.com/rlwilliamson-dev/azure-resume/blob/main/blog/scripts/topologies/one-switch.sh).

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology one-switch
# commands run on sw
$ ip -s -s link show sw-h3
10: sw-h3@if11: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue master br0 state UP mode DEFAULT group default qlen 1000
    link/ether 86:ee:33:01:03:ba brd ff:ff:ff:ff:ff:ff link-netns h3
    RX:  bytes packets errors dropped  missed   mcast           
             0       0      0       0       0       0 
    RX errors:  length    crc   frame    fifo overrun
                     0      0       0       0       0 
    TX:  bytes packets errors dropped carrier collsns           
            54       1      0       0       0       0 
    TX errors: aborted   fifo  window heartbt transns
                     0      0       0       0       2 
```

Four rows, and they are two pairs. The `RX` and `TX` rows are the summary: bytes,
packets, and then two numbers that matter, errors and dropped. The `RX errors` and
`TX errors` rows break those summary numbers down into the reasons, and the reasons
are the diagnosis.

The vocabulary a switch uses is different from the vocabulary Linux prints, and the
exam uses the switch's. They line up:

| The exam's name | Where it is here | What it counts |
| --- | --- | --- |
| Frame check sequence errors | `crc` under RX errors | Frames whose checksum did not match |
| Runts and giants | `length` under RX errors | Frames below or above the legal size |
| Drops or discards | `dropped` under RX or TX | Frames refused, with nothing wrong with them |
| Alignment errors | `frame` under RX errors | Frames that did not end on a byte boundary |
| Buffer overruns | `fifo` and `overrun` | Frames that arrived faster than they could be taken in |

<details class="deeper">
<summary>If you already read switch counters for a living: the pair that names a duplex mismatch, and the reset that hides the evidence</summary>

Two things separate somebody who can read counters from somebody who can act on
them.

The first is that the useful signal is often a pair of counters at opposite ends of
one link rather than a single number at one end. Topic 18 explained why a duplex
mismatch is slow rather than broken: the half duplex end detects collisions the full
duplex end never knew it caused. The counter evidence follows directly from that.
**Late collisions appear at the half duplex end, and frame check sequence errors
appear at the other.** Neither end sees both. So a port with rising late collisions
is not telling you about itself, it is telling you about the far end's
configuration, and the confirmation is to go and read the other switch. A single
port's counters answer a question about a link, and a link has two ends.

The second is that counters are erasable and the evidence goes with them. They count
from the moment the port came into existence, which means a reboot, a line card
reseat, or somebody typing the command that clears them all take the history to
zero. That is fine when you know it happened and misleading when you do not: a port
with a genuine intermittent fault reads as perfectly clean for the first hour after
a reboot. The defence is the same one topic 40 built for bandwidth: sample the
counter on a schedule and keep the samples, so the record lives somewhere other than
the device. A monitoring system that has been polling this port every five minutes
for a year can tell you the errors started on a Tuesday. The device itself can only
ever tell you the total since it last forgot.

</details>

## A counter is a total, so read it twice

The single most common mistake with counters is treating one reading as a
measurement. It is not. It is a total accumulated since the port came up, which
could have been ten minutes ago or two years ago, so on its own it cannot tell you
whether anything is happening now.

Two readings can. Here the same port is read, then a fault is created, then it is
read again.

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology one-switch
# a working port at rest. every counter on it is zero
$ ip netns exec sw ip -s link show sw-h3 | grep -A1 "RX:"
    RX:  bytes packets errors dropped  missed   mcast           
             0       0      0       0       0       0 
# h3 is switched to jumbo frames and the switch port is not. one setting, one side
$ ip netns exec h3 ip link set h3eth0 mtu 9000
$ ip netns exec h3 ping -c5 -W1 -s 4000 10.0.0.1 2>&1 | tail -2
5 packets transmitted, 0 received, 100% packet loss, time 5101ms

# the same port, read a second time
$ ip netns exec sw ip -s link show sw-h3 | grep -A1 "RX:"
    RX:  bytes packets errors dropped  missed   mcast           
            42       1      0       6       0       0 
```

Zero, then six. Five pings and an ARP, and the port refused every oversized frame
that arrived while accepting the small one. The host thinks it can send nine thousand
byte frames and the port it is plugged into will take fifteen hundred, so everything
large is discarded and everything small gets through. That is why the ping fails at a
hundred percent and the machine looks connected: it is connected, for small things.

Note which counter moved. `dropped` went up and `errors` stayed at zero, because
nothing was wrong with those frames. They were well-formed, correctly addressed, and
too big for the port to accept, which is a fact about the port rather than the frame.
A hardware switch would call the same event a giant and file it under errors; this
kernel calls it a drop. The label differs between implementations and the reasoning
does not: a frame arrived, the port would not take it, and the number went up.

**Six is meaningless and the change from zero to six is not.** That is the whole
technique. Read, wait, read again, subtract. If the difference is zero, whatever
happened is history, whoever caused it has gone, and you are looking at a monument
rather than a fault.

## Where a frame dies decides which counter moves

The counters are not an arbitrary list. They are the sequence of checks a frame has
to survive, in order, and each one has a number attached to it that records how many
frames failed there. That is what makes a counter diagnostic instead of merely
informative.

<figure class="learn-figure">
<svg viewBox="0 0 720 200" role="img" aria-labelledby="gates-title" style="width:100%;height:auto;">
<title id="gates-title">A frame passing through three checks at a switch port: the frame check sequence, the size check, and whether there is room to queue it, each with the counter that records a frame failing there</title>
<g fill="currentColor">
<text x="14" y="20" font-size="11">a frame runs three checks. the one it fails is the one that names the fault</text>
<rect x="20" y="52" width="58" height="26" rx="4" fill="currentColor" fill-opacity="0.08" stroke="currentColor" stroke-opacity="0.7"/>
<text x="49" y="69" text-anchor="middle" font-size="10">frame</text>
<g stroke="currentColor" stroke-opacity="0.6" stroke-width="1.3" fill="none">
<path d="M 78 65 H 592"/>
<path d="M 160 46 V 84"/>
<path d="M 340 46 V 84"/>
<path d="M 520 46 V 84"/>
</g>
<rect x="600" y="52" width="100" height="26" rx="4" fill="currentColor" fill-opacity="0.08" stroke="currentColor" stroke-opacity="0.7"/>
<text x="650" y="69" text-anchor="middle" font-size="10">forwarded</text>
<text x="160" y="38" text-anchor="middle" font-size="10">checksum ok</text>
<text x="340" y="38" text-anchor="middle" font-size="10">size legal</text>
<text x="520" y="38" text-anchor="middle" font-size="10">room to queue</text>
<g stroke="var(--red)" stroke-opacity="0.9" stroke-width="1.6" fill="none">
<path d="M 160 84 V 112 M 154 106 l 6 8 l 6 -8"/>
<path d="M 340 84 V 112 M 334 106 l 6 8 l 6 -8"/>
<path d="M 520 84 V 112 M 514 106 l 6 8 l 6 -8"/>
</g>
<text x="160" y="132" text-anchor="middle" font-size="10" fill="var(--red)">fcs errors</text>
<text x="340" y="132" text-anchor="middle" font-size="10" fill="var(--red)">runts, giants</text>
<text x="520" y="132" text-anchor="middle" font-size="10" fill="var(--red)">drops</text>
<text x="160" y="150" text-anchor="middle" font-size="9.5" fill-opacity="0.8">shown as crc</text>
<text x="340" y="150" text-anchor="middle" font-size="9.5" fill-opacity="0.8">shown as length</text>
<text x="520" y="150" text-anchor="middle" font-size="9.5" fill-opacity="0.8">shown as dropped</text>
<text x="160" y="176" text-anchor="middle" font-size="9.5" fill-opacity="0.8">the bits changed</text>
<text x="340" y="176" text-anchor="middle" font-size="9.5" fill-opacity="0.8">the ends disagree</text>
<text x="520" y="176" text-anchor="middle" font-size="9.5" fill-opacity="0.8">there was no room</text>
</g></svg>
<figcaption>The three gates run in that order because each one is cheaper than the next and there is no point queueing a frame that failed its checksum. What the picture is for is the last row. A frame check failure means the bits arrived different from how they left, which is a statement about copper, connectors and interference and about nothing else. A size failure means the frame was legal where it came from and is not legal here, which is a statement about two configurations disagreeing. A drop means the frame was perfect and there was nowhere to put it, which is a statement about capacity or policy. Three counters, three different places to go and look, and no overlap between them.</figcaption>
</figure>

So the practical rule is to read the counter that moved rather than the total that
is largest. Frame check errors climbing sends you to the physical layer: the cable,
the connectors, the transceiver, the patch panel. Length errors climbing sends you
to a configuration disagreement between two devices, usually MTU, occasionally a
device sending malformed frames. Drops climbing sends you to capacity or to a rule
you wrote, and neither of those is fixed by replacing a cable.

## Three ports, three different kinds of down

A port that is not passing traffic can be in more than one state, and the states
have different causes and different fixes. Here are three ports on one switch, in
three different conditions, read the same way.

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology one-switch
# port 1 is shut on the switch. port 2 has nothing alive on the far end.
# port 3 is working. all three are read the same way
$ ip netns exec sw ip link set sw-h1 down
$ ip netns exec h2 ip link set h2eth0 down
$ sleep 1
$ ip netns exec sw ip -br link show type veth
sw-h1@if7        DOWN           b2:32:29:4e:57:e8 <BROADCAST,MULTICAST> 
sw-h2@if9        DOWN           82:56:0e:e5:f5:df <NO-CARRIER,BROADCAST,MULTICAST,UP> 
sw-h3@if11       UP             36:b7:93:b8:ff:9a <BROADCAST,MULTICAST,UP,LOWER_UP> 
```

All three say `DOWN` or `UP` in the second column and the flags at the end are where
the difference is.

**`sw-h1` has no `UP` flag at all.** Somebody told this port to be off and it is
being off. That is administratively down, and no cable will fix it because nothing
is broken. The fix is a command, and the interesting question is who ran the last
one and why.

**`sw-h2` has `UP` and `NO-CARRIER`.** The port is switched on and wants to work.
There is no link on the other end of it. The far device is off, the far port is
shut, the cable is unplugged, or the cable is broken. Everything on this switch is
correct and the fault is somewhere else entirely.

**`sw-h3` has `UP` and `LOWER_UP`.** Both halves agree: the port is enabled and
there is a link on it. That is a working port.

That distinction is worth more than it looks, because it splits the search space in
half before you leave your desk. Administratively down is a configuration question
with a person at the end of it. No carrier is a physical question with a cable or a
far-end device at the end of it. Getting them the wrong way round means either
walking to a rack to look at a port somebody switched off deliberately, or reading
change tickets about a cable that fell out.

**Two more states exist on real switches and not here**, and both are worth
recognising because they are the ones that surprise people. A port can be **error
disabled**, which is the switch having shut the port itself in response to something
it saw: a security violation, a loop, or a counter crossing a threshold. It looks
like administratively down and nobody typed anything, so it is worth knowing that a
switch will do this on its own and that the log entry saying why is usually the whole
diagnosis. And a port in an aggregation group can be **suspended**, which is the
bundle refusing to bring that member up because its configuration or its negotiation
does not match the others. Topic 18 covered why an aggregation would rather run a
member down than run it wrong. A Linux bridge port has neither state, so both of
those are described here rather than shown.

## The port that will not stay up

The last counter in that first block is the one people skip past, and it answers a
question the others cannot: not whether the port is up now, but how much time it has
spent changing its mind.

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology one-switch
# the last counter is carrier transitions: how many times the link has come up
# or gone down since the port appeared
$ ip netns exec sw ip -s -s link show sw-h2 | tail -2
    TX errors: aborted   fifo  window heartbt transns
                     0      0       0       0       2 
# the far end is unplugged and plugged back in four times
$ for i in 1 2 3 4; do ip netns exec h2 ip link set h2eth0 down; ip netns exec h2 ip link set h2eth0 up; done
$ sleep 1
$ ip netns exec sw ip -s -s link show sw-h2 | tail -2
    TX errors: aborted   fifo  window heartbt transns
                     0      0       0       0      10 
```

Two, then ten. Four unplug and replug cycles produced eight transitions, one for each
direction, and the port is up at the end of it exactly as it was at the start. Read
only the state and you would say nothing had happened.

That is what makes this counter worth knowing. A flapping link is the hardest kind to
catch, because by the time somebody looks it is up again, and the state tells you
nothing about the last hour. The transition count is a record of the flapping that
survives the flapping stopping. A port with hundreds of transitions and a current
state of up has a loose cable, a failing transceiver, a duplex or negotiation problem,
or a far end that keeps rebooting, and none of that is visible any other way.

It is also the counter that spanning tree cares about most, because every transition
on a link is a topology change and a network whose topology keeps changing spends its
time reconverging rather than forwarding. Topic 19 covered what that costs.

## Across platforms

The counters and the port state exist on every machine and each platform prints them
under different names. The exam names `netstat`, which is where Windows keeps the
error and discard totals, and macOS keeps them in `netstat` too but in a different
table.

| Task | Linux | Windows | macOS |
| --- | --- | --- | --- |
| Errors and drops on a port | `ip -s -s link show <if>` | `netstat -e`, `Get-NetAdapterStatistics` | `netstat -i` |
| Whether a port has a link | `ip link show <if>`, read `NO-CARRIER` | `Get-NetAdapter`, read `MediaConnectionState` | `ifconfig <if>`, read `status:` |
| The speed it settled on | `ethtool <if>` | `Get-NetAdapter`, read `LinkSpeed` | `ifconfig <if>`, read `media:` |

**On Windows**, `Get-NetAdapter` puts the status and the negotiated speed in one
table, `Get-NetAdapterStatistics` breaks the errors and discards out per adapter, and
`netstat -e` prints the same totals in the layout the exam's vocabulary comes from.

```powershell
# Microsoft Windows Server 2025 Datacenter, version 10.0.26100.0
> Get-NetAdapter | Format-Table Name, Status, LinkSpeed, MediaConnectionState -AutoSize
Name            Status LinkSpeed MediaConnectionState
----            ------ --------- --------------------
Ethernet 4      Up     50 Gbps              Connected
vEthernet (nat) Up     10 Gbps              Connected
Ethernet 3      Up     50 Gbps              Connected

# Including the ones Windows hides, so a disconnected or disabled adapter is
# visible next to a working one
> Get-NetAdapter -IncludeHidden | Select-Object -First 10 | Format-Table Name, Status, MediaConnectionState -AutoSize
Name                                  Status      MediaConnectionState
----                                  ------      --------------------
Teredo Tunneling Pseudo-Interface     Not Present              Unknown
vSwitch (nat)                         Up                     Connected
Microsoft IP-HTTPS Platform Interface Not Present              Unknown
Ethernet (Kernel Debugger)            Not Present              Unknown
Ethernet 4                            Up                     Connected
vEthernet (nat)                       Up                     Connected
Ethernet 3                            Up                     Connected
6to4 Adapter                          Not Present              Unknown

# The error and discard counters, which are separate numbers from the byte ones
> Get-NetAdapterStatistics | Format-List Name, ReceivedPacketErrors, ReceivedDiscardedPackets, OutboundPacketErrors, OutboundDiscardedPackets
Name                     : Ethernet 4
ReceivedPacketErrors     : 0
ReceivedDiscardedPackets : 0
OutboundPacketErrors     : 0
OutboundDiscardedPackets : 0
Name                     : vEthernet (nat)
ReceivedPacketErrors     : 0
ReceivedDiscardedPackets : 0
OutboundPacketErrors     : 0
OutboundDiscardedPackets : 0
Name                     : Ethernet 3
ReceivedPacketErrors     : 0
ReceivedDiscardedPackets : 0
OutboundPacketErrors     : 0
OutboundDiscardedPackets : 0

# The same counters through the tool the exam names, in its own layout
> netstat -e
Interface Statistics
                           Received            Sent
Bytes                      64302278        11903550
Unicast packets               26103           17600
Non-unicast packets               0             715
Discards                          0               0
Errors                            0               0
Unknown protocols                 0
```

`Discards` and `Errors` are the two rows that matter and Windows puts them side by
side, received against sent, which is the same split as the `RX` and `TX` rows in the
Linux block. The cmdlet above it says the same thing per adapter rather than for the
machine, which is the more useful of the two when a host has several. `Status` and `MediaConnectionState` together are the same distinction the
switch made above: whether the adapter is enabled, and separately whether anything is
plugged into it.

**On macOS**, one `netstat` table carries packets and errors together, and `ifconfig`
carries the link state.

```bash
# macOS 26.5.2, arm64
$ netstat -i | awk 'NR==1 || $1 ~ /^en0$/'
Name       Mtu   Network       Address            Ipkts Ierrs    Opkts Oerrs  Coll
en0        1500  <Link#7>    b2:22:14:7e:49:7a    35328     0    10044     0     0
en0        1500  sat12-bq159 fe80:7::4:14e7:b3    35328     -    10044     -     -
en0        1500  192.168.64    sat12-bq159-6e0    35328     -    10044     -     -

# The link state of one interface, and what it negotiated
$ ifconfig en0 | grep -E "flags|status|media"
en0: flags=8863<UP,BROADCAST,SMART,RUNNING,SIMPLEX,MULTICAST> mtu 1500
	media: autoselect <full-duplex,flow-control>
	status: active

# Every interface, and which of them have a link. inactive is a port with
# nothing plugged into it, which is a different thing from a port that is down
$ ifconfig -a | grep -E "^[a-z0-9]+: flags|status:" | head -14
lo0: flags=8049<UP,LOOPBACK,RUNNING,MULTICAST> mtu 16384
gif0: flags=8010<POINTOPOINT,MULTICAST> mtu 1280
stf0: flags=0<> mtu 1280
anpi0: flags=8863<UP,BROADCAST,SMART,RUNNING,SIMPLEX,MULTICAST> mtu 1500
	status: inactive
en1: flags=8863<UP,BROADCAST,SMART,RUNNING,SIMPLEX,MULTICAST> mtu 1500
	status: inactive
en0: flags=8863<UP,BROADCAST,SMART,RUNNING,SIMPLEX,MULTICAST> mtu 1500
	status: active
utun0: flags=8051<UP,POINTOPOINT,RUNNING,MULTICAST> mtu 1500
utun1: flags=8051<UP,POINTOPOINT,RUNNING,MULTICAST> mtu 1380
utun2: flags=8051<UP,POINTOPOINT,RUNNING,MULTICAST> mtu 2000
utun3: flags=8051<UP,POINTOPOINT,RUNNING,MULTICAST> mtu 1000
```

`Ierrs` and `Oerrs` are input and output errors, and macOS is the only one of the
three that puts them in the same row as the packet counts, which makes the ratio easy
to see. The last block is the three-way distinction again in BSD spelling: `en1` and
`anpi0` carry the `UP` flag and read `status: inactive`, which is the port enabled with
nothing plugged in, and `en0` reads `status: active`. The `utun` interfaces at the
foot have no status line at all, because a tunnel has no link to have. `media:
autoselect <full-duplex,flow-control>` is what negotiation settled on, which is the
fact topic 18 was about.

## Prove it

You have this when you can look at a port and say three things without guessing:
whether it is enabled, whether it has a link, and whether anything is going wrong on
it right now rather than at some point in the past.

```bash
# the whole picture for one port, errors broken out by reason
ip -s -s link show <interface>

# is it enabled, and does it have a link? the flags carry both
ip link show <interface>
```

Read it, wait a minute under real traffic, and read it again. The difference is the
only number that describes now. If the difference is zero, the counter is a record of
something that has already finished.

Then check that you can tell the three states apart in the output above without
reading the labels: no `UP` flag is administratively down, `UP` with `NO-CARRIER` is
enabled with nothing on the far end, and `UP` with `LOWER_UP` is working.

## What trips people up

### 1. Reading one number and calling it a fault

A counter is a total since the port came into existence. A large number could be a
storm last March. Two readings a minute apart tell you whether it is happening now,
and nothing else does.

### 2. Treating errors and drops as the same thing

An error means the frame was damaged, which points at the physical layer. A drop
means the frame was fine and there was no room or no permission for it, which points
at capacity or configuration. Chasing a cable because of a drop counter wastes the
afternoon.

### 3. Assuming a clean counter means a healthy port

Counters reset when a device reboots or when somebody clears them, so a port with a
genuine intermittent fault reads perfectly clean for the first hour afterwards. Only
a record kept off the device survives that.

### 4. Confusing administratively down with no carrier

They look alike in a summary and have nothing in common. One is a person and a
command, the other is a cable or a far-end device. The flags tell them apart and the
summary column does not.

### 5. Reading one end of a link and stopping

A duplex mismatch puts late collisions at one end and frame check errors at the other,
so neither port sees the whole fault. A link has two ends and the counters at both of
them are one piece of evidence.

### 6. Ignoring the transition count

A port that is up now can have flapped two hundred times today, and the state says
nothing about that. The transition counter is the only record of a fault that keeps
fixing itself before anybody looks.

## Work it through

The port with errors on it that nobody has complained about.

Start by reading it twice, a minute apart, under whatever traffic the link normally
carries. This costs a minute and it decides everything that follows. If the number has
not moved, the fault is over: something happened, it stopped, and the counter is the
only thing left of it. Write down what you found, note the date the port last came up,
and close it. If the number has moved, you have a live fault and the rest of the method
applies.

Then read which counter moved, not which is biggest. A port can carry a huge historic
frame check total from a cable that was replaced last year and be dropping frames right
now for a completely unrelated reason. The counter that is climbing is the one
describing the present, and it names the layer: frame check errors send you to the
copper, length errors send you to a configuration disagreement, drops send you to
capacity or to a rule.

Then go and read the other end. Counters describe a link from one side, and several
faults are only visible as a pattern across both. Late collisions here and frame check
errors there is a duplex mismatch, and neither port alone would have told you.

And before any of that, check the port is actually in the state you assume. If it is
down, the flags will tell you in one glance whether somebody switched it off or whether
there is nothing on the far end, and those two answers send you to completely different
places. Getting that wrong is how an afternoon goes into a cable that was never
connected to anything.

## Try it

**Read the counters on the machine in front of you, twice.** Any interface will do.
Read them, do something that generates traffic, read them again, and subtract. The
point is not the number, it is building the habit that a single reading is not
evidence.

**Run the lab and make the drops happen.** In
[`one-switch.sh`](https://github.com/rlwilliamson-dev/azure-resume/blob/main/blog/scripts/topologies/one-switch.sh)
the fault above is one MTU change on one host. Watching the drop counter move while the
error counters stay at zero is what makes the distinction between the two stick.

**Find the three states on your own kit.** Shut a port you are allowed to shut, unplug a
cable from another, and leave a third working. Then read all three the same way and see
that the summary column does not distinguish them and the flags do.

## Check yourself

<details class="qa">
<summary>A switch port shows 40,000 frame check errors. What do you do first?</summary>

Read it again a minute later and subtract. A counter is a total since the port came
into existence, so 40,000 could have accumulated during a bad cable last year and
stopped the day it was replaced.

If the difference is zero, it is history, and the useful output is a note saying so. If
the number is climbing, it is a live fault, and frame check errors specifically mean
frames are arriving damaged, which points at the cable, the connectors or the
transceiver rather than at any configuration.

</details>

<details class="qa">
<summary>What is the difference between an error and a drop on an interface?</summary>

An error is a frame that arrived and was rejected because something was wrong with the
frame itself: the checksum did not match, or the size was illegal. That is a statement
about what happened to it in transit.

A drop is a frame with nothing wrong with it that the port discarded anyway, because
there was no room in the queue or a rule said not to forward it. That is a statement
about the port. The two send you to completely different places, which is why the
distinction is worth more than either number.

</details>

<details class="qa">
<summary>Two ports are down. One has no UP flag, the other has UP and NO-CARRIER. What is the difference?</summary>

The first was switched off deliberately. It is administratively down, nothing is
broken, and no cable will change it. The next question is who ran that command and why.

The second is enabled and wants to work, and there is no link on the far end. The
device at the other end is off, its port is shut, the cable is unplugged, or the cable
is broken. Everything on this switch is correct and the fault is elsewhere. Getting
these the wrong way round sends you to the wrong building.

</details>

<details class="qa">
<summary>A port is up, users report intermittent problems, and the error counters are near zero. What else is worth reading?</summary>

The carrier transition count. It records how many times the link has gone down and come
back since the port appeared, and it is the only number that survives the flapping
stopping.

A port that is up now and has transitioned hundreds of times today has a loose cable, a
failing transceiver, or a far end that keeps rebooting. The current state cannot show
that and the error counters need not move at all, because each individual link
establishment is clean. Every transition is also a topology change for spanning tree,
so the cost is larger than the port.

</details>

<details class="qa">
<summary>Why can a duplex mismatch be invisible on the port you are looking at?</summary>

Because the two ends see different halves of it. The half duplex end detects collisions
after the point where a real collision could occur and counts late collisions. The full
duplex end never knows it interrupted anything and sees frames that ended up damaged,
which it counts as frame check sequence errors.

So each port reports a symptom that looks like something else on its own, and the fault
is only obvious with both in front of you. That is the general lesson rather than a
special case: a counter describes one end and a link has two.

</details>

## References

- [ip-link(8)](https://man7.org/linux/man-pages/man8/ip-link.8.html) - man7.org, for the statistics `-s` and `-s -s` print and what each column of the error breakdown is. Free. Accessed 2026-08-19.
- [IEEE 802.3 Standard for Ethernet](https://standards.ieee.org/ieee/802.3/10422/) - IEEE Standards Association, which defines the frame check sequence and the minimum and maximum frame sizes that make a runt and a giant. Accessed 2026-08-19.
- [Get-NetAdapterStatistics](https://learn.microsoft.com/powershell/module/netadapter/get-netadapterstatistics) - Microsoft, for the Windows counter names and what each one includes. Free. Accessed 2026-08-19.
- [netstat(1)](https://keith.github.io/xcode-man-pages/netstat.1.html) - Apple, for the BSD interface table and its `Ierrs` and `Oerrs` columns. Free. Accessed 2026-08-19.

**Where the numbers came from.** The four Linux blocks are from
[`one-switch.sh`](https://github.com/rlwilliamson-dev/azure-resume/blob/main/blog/scripts/topologies/one-switch.sh)
through `netlab.sh`, on the kernel named in each header, with every fault created by the
commands shown rather than built into the topology. The Windows and macOS blocks are real
machines through the capture workflow.

One honest limit. The drop counters here can be made to move and the physical error
counters cannot, because a frame check sequence error means the bits changed on a wire
and there is no wire in a namespace to change them on. Corrupting packets in software
produces loss with the interface error counters still reading zero, since the damage is
caught further up the stack. So the frame check, runt, giant and late collision numbers
on this page are described from the standard and from the tools' own documentation, and
the drops and the port states are captured.

**If you also work on Linux systems.** The same `ip -s -s link` output appears on the
Linux+ track from the host's point of view rather than the switch's, and the technique is
identical: read twice, subtract, and let the counter that moved choose the layer.
