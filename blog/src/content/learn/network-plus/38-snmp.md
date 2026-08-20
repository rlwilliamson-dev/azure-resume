---
title: "SNMP"
description: "A protocol from 1988 that most networks still run, and the two ways it delivers information. Polling against traps, what an object identifier actually is, and why the community string in a version 2c poll is not a password."
deck: "The switch has been telling you for six months and nobody was listening"
track: "network-plus"
level: "working"
order: 390
objectives:
  - "Say what an agent, a manager and a management information base each are"
  - "Read an object identifier as a path rather than as a serial number"
  - "Explain what polling misses and what a trap misses"
  - "Say why a version 2c community string is not a password"
  - "Describe what version 3 adds and what it still leaves visible"
prerequisites: ["ports-and-the-protocols-that-use-them"]
tags: ["network-plus", "networking", "monitoring"]
updated: 2026-08-12
draft: false
examObjectives:
  - exam: "n10-009"
    domain: "3.0"
    objective: "3.2"
sources:
  - title: "RFC 3410, Introduction and Applicability Statements for Internet Standard Management Framework"
    url: "https://www.rfc-editor.org/rfc/rfc3410"
    publisher: "IETF"
    accessed: 2026-08-12
    tier: 1
  - title: "RFC 3416, Version 2 of the Protocol Operations for SNMP"
    url: "https://www.rfc-editor.org/rfc/rfc3416"
    publisher: "IETF"
    accessed: 2026-08-12
    tier: 1
  - title: "RFC 3414, User-based Security Model for SNMPv3"
    url: "https://www.rfc-editor.org/rfc/rfc3414"
    publisher: "IETF"
    accessed: 2026-08-12
    tier: 1
  - title: "RFC 2578, Structure of Management Information Version 2"
    url: "https://www.rfc-editor.org/rfc/rfc2578"
    publisher: "IETF"
    accessed: 2026-08-12
    tier: 1
  - title: "Service Name and Transport Protocol Port Number Registry"
    url: "https://www.iana.org/assignments/service-names-port-numbers/service-names-port-numbers.xhtml"
    publisher: "IANA"
    accessed: 2026-08-12
    tier: 1
symptoms:
  - symptom: "A fault happened and the monitoring system shows nothing wrong"
    anchor: "two-ways-to-find-out"
  - symptom: "A device sends traps and the receiver never records any"
    anchor: "two-ways-to-find-out"
  - symptom: "An OID means nothing until somebody loads a file"
    anchor: "what-an-agent-actually-holds"
---

> **Before you read.** A switch lost one of its two power supplies in March. It
> has been sending a notification about it every few minutes ever since, and the
> monitoring system has never recorded one.
>
> The switch is configured correctly. The monitoring system is running. Nothing
> is broken in the sense anybody would recognise.
>
> **Where did five months of notifications go, and what would have caught this?**

SNMP is old. The first version is from 1988 and the third is from 2002, and the
protocol carries the shape of both. It is worth learning properly rather than as
a list of three version numbers, because almost every device in a rack speaks it
and because the way it fails is quiet.

### Some words you will need

<dl class="terms">
<dt>agent</dt>
<dd>The software on the device being watched. It answers questions and it can raise an alarm.</dd>
<dt>manager</dt>
<dd>The station doing the watching. Frequently called a network management system, or NMS.</dd>
<dt>MIB</dt>
<dd>Management information base. A file describing what an agent can be asked, and what the answers mean.</dd>
<dt>OID</dt>
<dd>Object identifier. A dotted number naming one thing an agent holds.</dd>
<dt>poll</dt>
<dd>The manager asks the agent a question, on a schedule it chooses.</dd>
<dt>trap</dt>
<dd>The agent tells the manager something happened, without being asked.</dd>
<dt>community string</dt>
<dd>The shared word a version 1 or version 2c message carries in place of a credential.</dd>
</dl>

## What breaks without this

**A fault is invisible for months.** The device knew. It said so. Nothing was
listening on the right port, or the destination was never set, and the
information existed the whole time.

**A monitoring system reports everything healthy through an outage.** Because it
asked before and asks again afterwards, and the outage happened in between.

**A read-only community string turns out to be a way in.** It was chosen once, in
2014, and it is on every device, and it goes past in plain text on every poll.

## Two ways to find out

There are exactly two directions information can travel here, and the exam cares
about the difference because their failure modes are opposites.

<figure class="learn-figure">
<svg viewBox="0 0 720 258" role="img" aria-labelledby="poll-title" style="width:100%;height:auto;">
<title id="poll-title">A timeline of five SNMP polls at sixty second intervals, all reporting the link up, against a twenty five second outage that falls between two of them and the trap sent at the moment it happened</title>
<g fill="currentColor">
<text x="14" y="22" font-size="11">a poll answers the question you asked, at the moment you asked it</text>
<line x1="60" y1="78" x2="700" y2="78" stroke="currentColor" stroke-opacity="0.35" stroke-width="1"/>
<line x1="60" y1="168" x2="700" y2="168" stroke="currentColor" stroke-opacity="0.35" stroke-width="1"/>
<text x="14" y="82" font-size="10.5" fill-opacity="0.8">manager</text>
<text x="14" y="172" font-size="10.5" fill-opacity="0.8">agent</text>
<line x1="90" y1="84" x2="90" y2="162" stroke="currentColor" stroke-opacity="0.55" stroke-width="1.4"/>
<circle cx="90" cy="78" r="3.5" fill="currentColor" fill-opacity="0.7"/>
<text x="90" y="66" text-anchor="middle" font-size="10">up</text>
<line x1="230" y1="84" x2="230" y2="162" stroke="currentColor" stroke-opacity="0.55" stroke-width="1.4"/>
<circle cx="230" cy="78" r="3.5" fill="currentColor" fill-opacity="0.7"/>
<text x="230" y="66" text-anchor="middle" font-size="10">up</text>
<line x1="370" y1="84" x2="370" y2="162" stroke="currentColor" stroke-opacity="0.55" stroke-width="1.4"/>
<circle cx="370" cy="78" r="3.5" fill="currentColor" fill-opacity="0.7"/>
<text x="370" y="66" text-anchor="middle" font-size="10">up</text>
<line x1="510" y1="84" x2="510" y2="162" stroke="currentColor" stroke-opacity="0.55" stroke-width="1.4"/>
<circle cx="510" cy="78" r="3.5" fill="currentColor" fill-opacity="0.7"/>
<text x="510" y="66" text-anchor="middle" font-size="10">up</text>
<line x1="650" y1="84" x2="650" y2="162" stroke="currentColor" stroke-opacity="0.55" stroke-width="1.4"/>
<circle cx="650" cy="78" r="3.5" fill="currentColor" fill-opacity="0.7"/>
<text x="650" y="66" text-anchor="middle" font-size="10">up</text>
<text x="90" y="52" font-size="10" fill-opacity="0.8">udp/161</text>
<text x="160" y="126" text-anchor="middle" font-size="10" fill-opacity="0.75">60 s</text>
<line x1="98" y1="122" x2="140" y2="122" stroke="currentColor" stroke-opacity="0.4" stroke-width="1"/>
<line x1="180" y1="122" x2="222" y2="122" stroke="currentColor" stroke-opacity="0.4" stroke-width="1"/>
<line x1="70" y1="214" x2="700" y2="214" stroke="currentColor" stroke-opacity="0.5" stroke-width="2.5"/>
<rect x="272" y="209" width="58" height="10" fill="var(--red)" fill-opacity="0.85"/>
<text x="14" y="218" font-size="10.5" fill-opacity="0.8">the link</text>
<text x="301" y="240" text-anchor="middle" font-size="10" fill="var(--red)">down 25 s</text>
<line x1="272" y1="204" x2="272" y2="86" stroke="var(--accent)" stroke-width="2"/>
<path d="M 272 82 l -4 8 l 8 0 z" fill="var(--accent)"/>
<text x="278" y="112" font-size="10.5" fill="var(--accent)">trap</text>
<text x="278" y="128" font-size="10" fill="var(--accent)">udp/162</text>
<text x="278" y="60" font-size="10">linkDown</text>
</g></svg>
<figcaption>Five polls, five answers of up, and a link that was down for twenty five seconds. Nothing here is misconfigured: the manager asked at the times it was told to ask, the agent answered honestly each time, and the outage fell in a gap. That gap is the polling interval, and it is a blind window by construction. Shortening it narrows the window and never closes it, and shortening it far enough turns a monitoring system into a load generator. The trap is the answer to that specific problem, because it leaves when the event happens rather than when the schedule comes round. The two ports are worth committing: the agent listens on 161, the receiver listens on 162, and they are different because the two roles sit on different machines.</figcaption>
</figure>

**A poll is the manager asking.** It sends a request to udp/161 on the device and
gets an answer back. Every graph of interface traffic anybody has ever looked at
is built from these, taken every minute or every five minutes for years.

**A trap is the agent telling.** It sends to udp/162 on the manager, unprompted,
at the moment something happens. Nothing is requested and nothing is confirmed.

The failure modes are mirror images. A poll cannot see anything that started and
finished between two polls. A trap arrives at the right moment and can be lost
without either end noticing, because it is a single UDP datagram with no
acknowledgement.

**Which is the answer to the question at the top.** Five months of notifications
went to a destination that was not listening, or to one that was and dropped
them, and nothing about a trap tells the sender either happened. A poll would
have caught this on the first interval after March, because a failed power supply
is a state rather than an event, and states are what polling is good at.

That is the useful way to hold the two apart. **Poll for things that are true or
false right now.** Fan speed, power supply present, interface up, disk full.
**Trap for things that happen at an instant** and would be gone by the next poll.

<details class="deeper">
<summary>If you already run a poller: why traps alone are a trap, and the pairing that works</summary>

The two directions have opposite failure modes, and that is the argument for running
both rather than choosing.

A trap is fast and unreliable. It travels over UDP with no acknowledgement, so a trap
sent while a link is failing may never arrive, which is precisely the trap you most
wanted. Worse, a device that has crashed sends nothing at all, so silence means either
everything is fine or the device is gone, and traps cannot distinguish those.

A poll is slow and reliable in the opposite sense. It cannot tell you about an event
between polls, so a link that flapped for thirty seconds inside a five minute interval
leaves no trace in the graph. What it does do is notice absence: a device that stops
answering is visibly not answering, every interval, until somebody looks.

So the pairing is traps for promptness and polling for certainty, with the polling
providing the thing traps structurally cannot, which is knowing that a device is still
there. A monitoring design built on traps alone will be quiet during the outage it was
bought for, and the quiet will look like health.

</details>

## What an agent actually holds

An agent is not a program you send commands to. It is a tree of values, and every
value in it has an address.

<figure class="learn-figure">
<svg viewBox="0 0 720 300" role="img" aria-labelledby="oid-title" style="width:100%;height:auto;">
<title id="oid-title">The object identifier tree from iso down to sysUpTime, showing that the dotted number is the path taken through the tree, and the separate branch where vendors register their own objects</title>
<g fill="currentColor">
<text x="14" y="22" font-size="11">an OID is not a name, it is the route you took to get there</text>
<rect x="40" y="52" width="72" height="34" rx="3" fill="currentColor" fill-opacity="0.07" stroke="currentColor" stroke-opacity="0.45"/>
<text x="76" y="65" text-anchor="middle" font-size="10.5">iso</text>
<text x="76" y="81" text-anchor="middle" font-size="10.5" fill-opacity="0.75">1</text>
<line x1="112" y1="69" x2="128" y2="69" stroke="currentColor" stroke-opacity="0.45" stroke-width="1.2"/>
<rect x="128" y="52" width="72" height="34" rx="3" fill="currentColor" fill-opacity="0.07" stroke="currentColor" stroke-opacity="0.45"/>
<text x="164" y="65" text-anchor="middle" font-size="10.5">org</text>
<text x="164" y="81" text-anchor="middle" font-size="10.5" fill-opacity="0.75">3</text>
<line x1="200" y1="69" x2="216" y2="69" stroke="currentColor" stroke-opacity="0.45" stroke-width="1.2"/>
<rect x="216" y="52" width="72" height="34" rx="3" fill="currentColor" fill-opacity="0.07" stroke="currentColor" stroke-opacity="0.45"/>
<text x="252" y="65" text-anchor="middle" font-size="10.5">dod</text>
<text x="252" y="81" text-anchor="middle" font-size="10.5" fill-opacity="0.75">6</text>
<line x1="288" y1="69" x2="304" y2="69" stroke="currentColor" stroke-opacity="0.45" stroke-width="1.2"/>
<rect x="304" y="52" width="72" height="34" rx="3" fill="currentColor" fill-opacity="0.07" stroke="currentColor" stroke-opacity="0.45"/>
<text x="340" y="65" text-anchor="middle" font-size="10.5">internet</text>
<text x="340" y="81" text-anchor="middle" font-size="10.5" fill-opacity="0.75">1</text>
<line x1="392" y1="69" x2="420" y2="69" stroke="currentColor" stroke-opacity="0.45" stroke-width="1.2"/>
<line x1="420" y1="69" x2="420" y2="195" stroke="currentColor" stroke-opacity="0.45" stroke-width="1.2"/>
<line x1="420" y1="111" x2="440" y2="111" stroke="currentColor" stroke-opacity="0.45" stroke-width="1.2"/>
<line x1="420" y1="195" x2="440" y2="195" stroke="currentColor" stroke-opacity="0.45" stroke-width="1.2"/>
<rect x="440" y="94" width="60" height="34" rx="3" fill="currentColor" fill-opacity="0.07" stroke="currentColor" stroke-opacity="0.45"/>
<text x="470" y="107" text-anchor="middle" font-size="10">mgmt</text>
<text x="470" y="123" text-anchor="middle" font-size="10" fill-opacity="0.75">2</text>
<line x1="500" y1="111" x2="510" y2="111" stroke="currentColor" stroke-opacity="0.45" stroke-width="1.2"/>
<rect x="510" y="94" width="60" height="34" rx="3" fill="currentColor" fill-opacity="0.07" stroke="currentColor" stroke-opacity="0.45"/>
<text x="540" y="107" text-anchor="middle" font-size="10">mib-2</text>
<text x="540" y="123" text-anchor="middle" font-size="10" fill-opacity="0.75">1</text>
<line x1="570" y1="111" x2="580" y2="111" stroke="currentColor" stroke-opacity="0.45" stroke-width="1.2"/>
<rect x="580" y="94" width="60" height="34" rx="3" fill="currentColor" fill-opacity="0.07" stroke="currentColor" stroke-opacity="0.45"/>
<text x="610" y="107" text-anchor="middle" font-size="10">system</text>
<text x="610" y="123" text-anchor="middle" font-size="10" fill-opacity="0.75">1</text>
<line x1="640" y1="111" x2="650" y2="111" stroke="currentColor" stroke-opacity="0.45" stroke-width="1.2"/>
<rect x="650" y="94" width="60" height="34" rx="3" fill="var(--accent)" fill-opacity="0.16" stroke="var(--accent)" stroke-opacity="0.9" stroke-width="1.8"/>
<text x="680" y="107" text-anchor="middle" font-size="10">sysUpTime</text>
<text x="680" y="123" text-anchor="middle" font-size="10" fill-opacity="0.75">3</text>
<rect x="440" y="178" width="60" height="34" rx="3" fill="currentColor" fill-opacity="0.07" stroke="currentColor" stroke-opacity="0.45"/>
<text x="470" y="191" text-anchor="middle" font-size="10">private</text>
<text x="470" y="207" text-anchor="middle" font-size="10" fill-opacity="0.75">4</text>
<line x1="500" y1="195" x2="510" y2="195" stroke="currentColor" stroke-opacity="0.45" stroke-width="1.2"/>
<rect x="510" y="178" width="72" height="34" rx="3" fill="currentColor" fill-opacity="0.07" stroke="currentColor" stroke-opacity="0.45"/>
<text x="546" y="191" text-anchor="middle" font-size="10">enterprises</text>
<text x="546" y="207" text-anchor="middle" font-size="10" fill-opacity="0.75">1</text>
<line x1="582" y1="195" x2="592" y2="195" stroke="currentColor" stroke-opacity="0.45" stroke-width="1.2"/>
<rect x="592" y="178" width="100" height="34" rx="3" fill="currentColor" fill-opacity="0.07" stroke="currentColor" stroke-opacity="0.45" stroke-dasharray="4 3"/>
<text x="642" y="191" text-anchor="middle" font-size="10">one number</text>
<text x="642" y="207" text-anchor="middle" font-size="10" fill-opacity="0.75">per vendor</text>
<text x="40" y="252" font-size="10.5" fill-opacity="0.8">the accented path, written out</text>
<text x="40" y="270" font-size="11" fill="var(--accent)">.1.3.6.1.2.1.1.3</text>
<text x="380" y="252" font-size="10.5" fill-opacity="0.8">everything a vendor invents starts here</text>
<text x="380" y="270" font-size="11">.1.3.6.1.4.1</text>
</g></svg>
<figcaption>Why OIDs look the way they do. The tree is a global registry, and the number is the route down it, so the first four arcs are the same on every device in the world and carry no information at all. The fork is the part worth knowing: everything standardised lives under mgmt, and everything a manufacturer invents for its own hardware lives under private, each vendor holding one number of their own. That is why a temperature sensor on one manufacturer's switch has a long unmemorable OID and system uptime has a short one, and why loading a vendor's MIB file is what turns their branch from numbers into words.</figcaption>
</figure>

The `.1.3.6.1.2.1.1.3` in that drawing is not an arbitrary identifier. Reading it
from left to right walks the tree, and the definition the agent's own MIB carries
says so in as many words.

```bash
# Debian 13 (trixie), x86_64
$ snmptranslate -Td SNMPv2-MIB::sysUpTime
SNMPv2-MIB::sysUpTime
sysUpTime OBJECT-TYPE
  -- FROM	SNMPv2-MIB
  SYNTAX	TimeTicks
  MAX-ACCESS	read-only
  STATUS	current
  DESCRIPTION	"The time (in hundredths of a second) since the
            network management portion of the system was last
            re-initialized."
::= { iso(1) org(3) dod(6) internet(1) mgmt(2) mib-2(1) system(1) 3 }
```

The last line is the OID with the names still attached. Strip the words and you
have the number.

**The MIB is a dictionary, not part of the protocol.** The agent sends numbers.
The manager translates them, if it has the file. Debian keeps the standard MIB
files in a separate package for licensing reasons, which makes the difference
visible: the same walk, run twice, once with the files and once without.

```bash
# Debian 13 (trixie), x86_64
$ snmpd -Lf /dev/null; sleep 2; snmpwalk -v2c -c s3cr3t-ro 127.0.0.1 SNMPv2-MIB::system | head -6; echo; snmpwalk -v2c -c s3cr3t-ro -On 127.0.0.1 SNMPv2-MIB::system | head -6
SNMPv2-MIB::sysDescr.0 = STRING: Linux 3262ace91ba8 7.1.3-200.fc44.aarch64 #1 SMP PREEMPT_DYNAMIC Sat Jul  4 19:23:52 UTC 2026 x86_64
SNMPv2-MIB::sysObjectID.0 = OID: NET-SNMP-MIB::netSnmpAgentOIDs.10
DISMAN-EVENT-MIB::sysUpTimeInstance = Timeticks: (233) 0:00:02.33
SNMPv2-MIB::sysContact.0 = STRING: netops@example.com
SNMPv2-MIB::sysName.0 = STRING: 3262ace91ba8
SNMPv2-MIB::sysLocation.0 = STRING: Comms room 2, rack 4

.1.3.6.1.2.1.1.1.0 = STRING: Linux 3262ace91ba8 7.1.3-200.fc44.aarch64 #1 SMP PREEMPT_DYNAMIC Sat Jul  4 19:23:52 UTC 2026 x86_64
.1.3.6.1.2.1.1.2.0 = OID: .1.3.6.1.4.1.8072.3.2.10
.1.3.6.1.2.1.1.3.0 = Timeticks: (246) 0:00:02.46
.1.3.6.1.2.1.1.4.0 = STRING: netops@example.com
.1.3.6.1.2.1.1.5.0 = STRING: 3262ace91ba8
.1.3.6.1.2.1.1.6.0 = STRING: Comms room 2, rack 4
```

Identical values, identical order, identical protocol on the wire. The only thing
that changed is whether the manager could put names to the numbers. That is worth
sitting with for a moment, because it explains the single most common SNMP
support question, which is why a monitoring system is showing a row of numbers
where a graph title should be.

**`sysLocation` deserves a second look too.** Somebody typed "Comms room 2, rack
4" into that switch, and now anything that can poll it can read where it is. The
same field is a gift to whoever inherits the network and a gift to anybody
mapping it from outside, and which of those matters depends entirely on the next
section.

<details class="deeper">
<summary>If you already write monitoring definitions: the counters that wrap, and the wider ones that fix it</summary>

Reading a value is easy and reading it correctly on a fast interface takes one extra
step that catches people out.

The original interface counters are 32 bits, which holds about four billion. At
gigabit speeds a byte counter passes that in roughly thirty seconds, so it wraps back
to zero and starts again. A poller taking the difference between two readings across a
wrap sees a large negative number, and depending on how it handles that it either
discards the sample, leaving a gap, or records something absurd, leaving a spike. Both
show up on graphs constantly and both are usually blamed on the network.

The fix is the high capacity counters, which are 64 bits and will not wrap in any
timescale that matters. They are defined alongside the originals rather than replacing
them, so a poller has to be told to use them, and plenty of older monitoring
configurations never were. That is worth checking on any graph of a fast link that has
unexplained gaps or spikes.

The general shape recurs beyond this protocol. A counter is a number that increases
until it cannot, and every system that reads one has to decide what a decrease means.
Topic 40 covers the other way a counter misleads, which is a reset rather than a wrap,
and the two look identical in the data.

</details>

## What a version 2c poll puts on the wire

The community string gets described as a password, and reading it that way is
what leads people to reuse a good one everywhere.

<details class="predict">
<summary>A version 2c poll crosses the wire and somebody is capturing it. What can they read out of the packet?</summary>

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology managed-lan
# commands run on mon
# poll the agent with v2c, then with v3, and watch both go past on the wire
$ (timeout 12 tcpdump -i mon0 -n -A -s0 udp port 161 > /tmp/w.txt 2>/dev/null &)
$ sleep 2
$ snmpget -v2c -c s3cr3t-ro -On 10.0.0.20 1.3.6.1.2.1.1.6.0
.1.3.6.1.2.1.1.6.0 = STRING: "Comms room 2, rack 4"
$ snmpget -v3 -l authPriv -u netops -a SHA-512 -A authpassphrase -x AES -X privpassphrase -On 10.0.0.20 1.3.6.1.2.1.1.6.0
.1.3.6.1.2.1.1.6.0 = STRING: "Comms room 2, rack 4"
$ sleep 11
$ grep -a "IP 10" /tmp/w.txt
16:48:36.411001 IP 10.0.0.10.50884 > 10.0.0.20.161:  C="s3cr3t-ro" GetRequest(28)  .1.3.6.1.2.1.1.6.0
16:48:36.411374 IP 10.0.0.20.161 > 10.0.0.10.50884:  C="s3cr3t-ro" GetResponse(48)  .1.3.6.1.2.1.1.6.0="Comms room 2, rack 4"
16:48:36.419010 IP 10.0.0.10.38742 > 10.0.0.20.161:  F=r U="" E= C="" GetRequest(14) 
16:48:36.419196 IP 10.0.0.20.161 > 10.0.0.10.38742:  F= U="" E=_80_00_1f_88_80_ba_a1_1a_72_df_a3_7c_6a_00_00_00_00 C="" Report(31)  .1.3.6.1.6.3.15.1.1.4.0=1
16:48:36.419326 IP 10.0.0.10.38742 > 10.0.0.20.161:  F=apr U="netops" [!scoped PDU]4a_a4_56_f3_13_6b_19_50_6e_68_fa_7b_8b_f6_b3_9f_6a_9a_2f_8b_17_48_49_92_70_61_f9_8b_42_8a_85_cc_ea_3f_5e_e1_7b_b6_bf_13_9a_49_52_63_54_67_72_91_8b_cb_08_4f_de
16:48:36.419482 IP 10.0.0.20.161 > 10.0.0.10.38742:  F=ap U="netops" [!scoped PDU]4a_0a_7c_bb_8e_a8_77_e8_57_ad_77_37_0a_58_90_eb_55_15_8c_ff_b2_fc_4d_c1_b0_b3_7a_c0_18_b8_db_bf_f9_21_10_46_55_2a_4a_b4_f7_34_46_36_0c_37_f8_20_e3_f6_97_a0_db_98_ba_bc_20_c4_41_8f_e3_cf_86_5d_01_5f_eb_3b_ce_bb_29_a2_a4
```

</details>

Both polls returned the same answer. On the wire they could hardly be more
different.

**The version 2c pair is entirely readable.** `C="s3cr3t-ro"` is the community
string. The OID being asked for is there. So is the answer, in plain text,
including where the switch physically is. Anybody positioned to see the traffic
has the credential and the data in one datagram, and the credential is the same
one that works on every other device it is configured on.

**The version 3 pair took three messages instead of two.** The first exchange is
discovery: the manager asks with no user and no engine, and the agent replies
with a `Report` carrying its engine ID, which is the string of hex after `E=`.
Only then does the real request go, and its contents are the run of hex after
`[!scoped PDU]`. The OID is not visible. The answer is not visible.

**One thing is still visible in the version 3 exchange, and it is worth
noticing.** `U="netops"` is in the clear, as is the engine ID. The security model
encrypts the payload and not the identity, so an observer learns which account is
polling and which device is answering while learning nothing about what was
asked. That is a reasonable trade and it is not nothing.

<details class="deeper">
<summary>If you already work on networks: the three security levels, why there is no v3 without a user, and what a read-only string is worth to an attacker</summary>

Version 3 is not one thing. The user-based security model in RFC 3414 defines
three levels, and a device configured at the wrong one gives a false sense of
having been upgraded.

**noAuthNoPriv** identifies a user by name and does nothing else. No proof of
identity, no encryption. It is version 2c with extra configuration, and it exists
mostly so the message format is uniform.

**authNoPriv** proves the message came from somebody holding the authentication
passphrase and has not been altered. The contents are still readable. This is a
defensible choice on a management network you already trust, and it is the level
people end up on by accident when the privacy passphrase is left blank.

**authPriv** adds encryption of the payload, which is what the capture above
shows. RFC 7860 defines the SHA-2 authentication algorithms and RFC 3826 defines
AES for privacy, and both are worth naming because a device configured with MD5
and DES is technically running version 3.

The discovery exchange is not optional and it is not overhead somebody could
optimise away. The authentication key is derived from the passphrase combined
with the agent's engine ID, which means the same passphrase produces a different
key on every device, which is what stops a captured message from one device being
replayed at another. So the manager has to learn the engine ID before it can
compute anything, and that is what the first two messages are for.

**The last point is the one people argue about.** A read-only community string
gets treated as harmless because it cannot change anything. What it can do is
read the interface table, the ARP table, the routing table, the software version,
the serial number and the location, on every device that shares the string, which
in most networks is all of them. That is a map of the network, an inventory of
what version everything runs, and a list of which of those have known flaws. It
changes nothing and it is the most efficient reconnaissance available on an
internal network, which is why "read-only" is a statement about writes rather
than about risk.

</details>

## Not only switches

<figure class="learn-figure photo">

![An APC AP9606 Web SNMP Management Card removed from its slot, photographed at an angle. The green circuit board carries several chips, a lithium battery and a barcode. The black front panel is printed with a reset pinhole, a single 10Base-T Ethernet socket with link and status indicators either side of it, and the words AP9606 Web/SNMP Management Card. The board is stamped with a 1998 copyright.](./images/snmp-management-card.jpg)

<figcaption>A management card from an uninterruptible power supply, which is where a great deal of real SNMP lives. The card is a small computer in its own right, bolted into a slot on a device that has no networking of its own, and the only reason it exists is so that the UPS can be asked questions and can raise an alarm. Two details on the front panel are worth reading. The port is 10Base-T, which was already slow when the board was made and is entirely sufficient, because management traffic is a few hundred bytes every minute. And the copyright on the board is 1998, which is roughly when this protocol settled into the role it still has. Photograph by Dsimic, <a href="https://creativecommons.org/licenses/by-sa/4.0/">CC BY-SA 4.0</a>.</figcaption>
</figure>

The switch is the obvious agent and it is not the interesting one. Uninterruptible
power supplies, printers, air conditioning units, environmental sensors, door
controllers and rack PDUs all speak SNMP, frequently as the only management
protocol they have.

That is worth knowing for a practical reason. When a building loses power, the
thing that tells you first is usually a UPS, and it tells you with a trap. If
nothing is listening on udp/162, the first notification anybody gets is a person
noticing that the lights are off.

## Across platforms

Nothing on this page needs a Linux machine, and what each platform gives you
differs more than you would expect.

**On Linux**, the net-snmp tools come from a package: `snmp` on Debian and
Ubuntu, `net-snmp-utils` on the RHEL family. The agent is separate, in `snmpd` or
`net-snmp`, which is the split that matters, because polling something else and
being polled are different jobs.

**On macOS**, the client tools are already there.

```bash
# macOS 26.5.2, arm64
$ snmpwalk -V 2>&1
NET-SNMP version: 5.6.2.1

# All of them, so the reader can see what else arrived
$ ls /usr/bin/snmp* | sed "s|/usr/bin/||" | tr "\n" " "
snmp-bridge-mib snmpbulkget snmpbulkwalk snmpconf snmpdelta snmpdf snmpget snmpgetnext snmpinform snmpnetstat snmpset snmpstatus snmptable snmptest snmptranslate snmptrap snmpusm snmpvacm snmpwalk 
# The MIB files that came with them
$ ls /usr/share/snmp/mibs | wc -l
      63
```

**On Windows**, the answer is the opposite way round. There is an agent, shipped
as an optional feature, and there is no client at all.

```powershell
# Microsoft Windows Server 2025 Datacenter, version 10.0.26100.0
> Get-WindowsFeature -Name SNMP* | Format-Table Name, InstallState -AutoSize
Name              InstallState
----              ------------
SNMP-Service      Available
SNMP-WMI-Provider Available

# Is there anything here that can poll another device
> Get-Command snmpwalk, snmpget, snmpget.exe -ErrorAction SilentlyContinue | Measure-Object | Select-Object -ExpandProperty Count
0
```

So a Windows workstation can be polled once somebody enables the feature, and
cannot poll anything without software from elsewhere. Microsoft's own
documentation for the SNMP feature describes it as deprecated and points at
Common Information Model in its place, which is worth knowing when somebody asks
why the option is buried.

## Prove it

**Poll something you own.** A home router, a printer, a managed switch. Enable
read-only version 2c on it, point `snmpwalk` at `1.3.6.1.2.1.1`, and read what
comes back. Then walk `1.3.6.1.2.1.2.2.1.2` and count the interfaces.

**Then run the same poll through a capture.** Watch the community string go past
in the clear. It is one thing to be told and another to see it in a datagram you
produced.

**Find a trap destination that is not configured.** Look at any device you have
access to and check whether it has a trap receiver set at all. On a lot of
equipment the answer is that nothing was ever configured, which is the fault at
the top of this page waiting to happen.

## What trips people up

### 1. Treating a community string as a password

It is a shared word carried in plain text in every version 1 and version 2c
message. Anybody who can see the traffic has it, and the same string is usually
configured on every device.

### 2. Assuming a shorter polling interval eventually catches everything

It narrows the blind window and never removes it. An event shorter than the
interval can always land between two polls, and polling hard enough to close the
gap puts real load on the device and the network.

### 3. Assuming a trap that was sent was received

A trap is one UDP datagram with no acknowledgement. The sender learns nothing
about whether it arrived and the receiver has no idea one is missing.

### 4. Confusing the two ports

Agents listen on 161 for polls. Trap receivers listen on 162. A firewall rule that
permits 161 and forgets 162 produces monitoring that graphs everything and alerts
on nothing.

### 5. Thinking the MIB is part of the protocol

The agent sends numbers. The MIB is a file on the manager that turns those
numbers into names. A missing MIB never breaks a poll, it just makes the answer
unreadable.

### 6. Believing read-only is the same as harmless

A read-only poll returns the interface table, the ARP table, the routing table,
the software version and the physical location. That is a map of the network, and
it changes nothing while giving away a great deal.

## Work it through

The switch that lost a power supply in March.

Start by separating the two things that could have gone wrong, because they need
different fixes. Either the trap never left the switch, or it left and nothing
received it.

Check the switch first, since it is one command. Does it have a trap destination
configured at all, and is the destination address one that still exists? A device
configured years ago frequently points at a management station that has been
decommissioned, and nothing on the switch would ever say so.

If the destination is right, the next question is whether anything is listening.
Traps arrive on udp/162, and a monitoring system that polls perfectly can be
running with no trap receiver enabled, because the two are separate services in
most products. A firewall between the two is the other candidate, and it is the
common one, because 161 gets permitted when monitoring is set up and 162 does not
come up until somebody misses an alarm.

The deeper answer is that this fault should never have depended on a trap.
**A failed power supply is a state**, and it is still true five months later. Any
poll of the power supply table would have returned the fault on the first attempt,
which is the practical version of the split earlier on this page: traps are for
events, polls are for conditions, and a condition monitored only by trap is a
condition monitored by hope.

Finally, there is a question worth asking that is not about SNMP. Nobody noticed
for five months that a device with redundant power was running on one supply. The
monitoring gap is real, and so is the fact that no process ever compared what the
inventory said the rack contained against what the rack was doing.

## Try it

**Walk the system group of anything.** Then walk `1.3.6.1.2.1.2`, which is the
interface table, and find the counter for the port you are plugged into.

**Translate an OID both ways.** `snmptranslate -On SNMPv2-MIB::sysDescr.0` and
`snmptranslate .1.3.6.1.2.1.1.1.0`. Doing it in both directions is what makes the
tree stop feeling arbitrary.

**Read a vendor MIB.** Download one from any manufacturer whose equipment you have
and look at what they chose to expose under their own branch. It is frequently a
better description of what the device does than the datasheet.

## Check yourself

<details class="qa">
<summary>A link flaps for fifteen seconds. Polling runs every five minutes. What does the monitoring system show, and why?</summary>

Almost certainly nothing. The poll before the flap returned up, the poll after it
returned up, and no request was made in between.

This is not a fault in the monitoring system. A poll answers a question at the
moment it is asked, so anything shorter than the interval can fall entirely inside
a gap. Catching a fifteen second flap needs the agent to raise it as an event,
which is what a trap is for.

</details>

<details class="qa">
<summary>Why are there two port numbers, and what breaks if a firewall permits only one?</summary>

Because the two roles sit on different machines. The agent listens on udp/161 for
polls, and the manager listens on udp/162 for traps, so a device that both answers
questions and raises alarms is talking to a different listener each way.

Permitting 161 alone gives you graphs and no alarms. Every poll succeeds, every
dashboard fills in, and every notification the devices send is dropped on the way.
That failure looks exactly like healthy monitoring until something breaks.

</details>

<details class="qa">
<summary>Somebody argues that the read-only community string does not need changing because it cannot alter anything. What is the counterargument?</summary>

That reading is the attack. A read-only poll returns the interface table, the ARP
table, the routing table, the software version and whatever was typed into the
location field, and the same string is usually configured on every device.

So it yields a map of the network, an inventory of software versions, and a list
of which of those have published flaws, without changing a single setting. The
word read-only describes what it cannot write, not what it cannot expose.

</details>

<details class="qa">
<summary>A walk returns lines beginning .1.3.6.1.4.1.9 and a colleague says the monitoring system is broken. What is actually happening?</summary>

Nothing is broken. The agent has returned objects from a vendor's own branch, and
the manager does not have that vendor's MIB file loaded, so it has nothing to
translate the numbers with.

`.1.3.6.1.4.1` is the enterprises branch, and the number after it identifies the
manufacturer. Loading their MIB turns those lines into names. Until then the
values are correct and unreadable, which is a documentation problem rather than a
protocol one.

</details>

<details class="qa">
<summary>Why does a version 3 poll start with an exchange that carries no request?</summary>

Because the manager needs the agent's engine ID before it can compute a key.
Authentication keys are derived from the passphrase combined with that engine ID,
so the same passphrase produces a different key on every device.

The first request goes out with no user and no engine ID, and the agent answers
with a report containing its own. That is what makes a captured message from one
device useless when replayed at another, and it is why the exchange is three
messages rather than two.

</details>

## References

- [RFC 3410](https://www.rfc-editor.org/rfc/rfc3410) - IETF, the introduction to the standard management framework, including its account of what version 1 and version 2c provide in place of security. Free. Accessed 2026-08-12.
- [RFC 3416](https://www.rfc-editor.org/rfc/rfc3416) - IETF, which defines the request types, including the get, get-next and get-bulk operations a walk is built from. Free. Accessed 2026-08-12.
- [RFC 3414](https://www.rfc-editor.org/rfc/rfc3414) - IETF, the user-based security model, on the three security levels and on key derivation from the engine ID. Free. Accessed 2026-08-12.
- [RFC 2578](https://www.rfc-editor.org/rfc/rfc2578) - IETF, the structure of management information, which is what an OID and a MIB module actually are. Free. Accessed 2026-08-12.
- [RFC 3826](https://www.rfc-editor.org/rfc/rfc3826) - IETF, AES in the user-based security model. Free. Accessed 2026-08-12.
- [RFC 7860](https://www.rfc-editor.org/rfc/rfc7860) - IETF, the SHA-2 authentication protocols. Free. Accessed 2026-08-12.
- [Service Name and Transport Protocol Port Number Registry](https://www.iana.org/assignments/service-names-port-numbers/service-names-port-numbers.xhtml) - IANA, for 161 and 162. Accessed 2026-08-12.
- [net-snmp](https://www.net-snmp.org/docs/man/) - The manual pages for the tools every capture on this page used. Accessed 2026-08-12.

**Pictures.** A freely licensed file from Wikimedia Commons, downloaded and served
from this site rather than linked across to somebody else's server. Resized and
otherwise unaltered.

- [APC AP9606 Web-SNMP Management Card](https://commons.wikimedia.org/wiki/File:APC_AP9606_Web-SNMP_Management_Card.jpg) by Dsimic, [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/).

**Where the output came from.** The walks and the OID definition were captured in
a Debian 13 container through `blog/scripts/capture.sh`, using the setup script
`blog/scripts/setups/snmp-agent.sh`, which installs the agent and fetches the
standard MIB files. Debian keeps those files in a non-free package because the
IETF's licence on the MIB modules is not a free software licence, which is the
reason the two walks differ and is worth knowing rather than working around. The
wire capture ran on the `managed-lan` namespace topology through
`blog/scripts/netlab.sh`, with a real manager polling a real agent across a
bridge, so the version 2c and version 3 exchanges are genuine datagrams rather
than an illustration. The passphrases and the community string in every capture
exist only inside a container that is destroyed when the capture ends.

**If you also work on Linux.** [Logging and auditing](/learn/linux-plus/logging-and-auditing)
on the Linux+ track covers the other half of how a machine reports on itself.
SNMP is the question asked from outside; logs are what the machine says on its
own initiative, and a monitoring system that has one and not the other has a blind
spot in a predictable place.
