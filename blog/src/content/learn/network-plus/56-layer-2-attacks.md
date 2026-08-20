---
title: "Layer 2 attacks"
description: "Everything still works and somebody is reading all of it. MAC flooding that turns a switch back into a hub, ARP poisoning that puts an attacker in the middle, and VLAN hopping that crosses a boundary the tagging was supposed to hold, each one captured."
deck: "Everything still works and somebody is reading all of it"
track: "network-plus"
level: "working"
order: 570
objectives:
  - "Explain MAC flooding and why it returns a switch to flooding every frame"
  - "Explain ARP poisoning and why the protocol has no defence against it"
  - "Explain VLAN hopping by double tagging and what makes it possible"
  - "Say what each attack gives an attacker and what evidence it leaves"
  - "Say why all three need access to the local segment"
prerequisites: ["how-a-switch-learns", "trunking-and-802-1q-tagging"]
tags: ["network-plus", "networking", "security", "attacks"]
updated: 2026-08-15
draft: false
examObjectives:
  - exam: "n10-009"
    domain: "4.0"
    objective: "4.2"
sources:
  - title: "RFC 826, An Ethernet Address Resolution Protocol"
    url: "https://www.rfc-editor.org/rfc/rfc826"
    publisher: "IETF"
    accessed: 2026-08-15
    tier: 1
  - title: "IEEE 802.1Q-2022, Bridges and Bridged Networks"
    url: "https://standards.ieee.org/ieee/802.1Q/7096/"
    publisher: "IEEE"
    accessed: 2026-08-15
    tier: 1
  - title: "RFC 4949, Internet Security Glossary, Version 2"
    url: "https://www.rfc-editor.org/rfc/rfc4949"
    publisher: "IETF"
    accessed: 2026-08-15
    tier: 1
symptoms:
  - symptom: "A switch is flooding unicast traffic to every port"
    anchor: "mac-flooding"
  - symptom: "Two hosts are communicating and the traffic passes through a third"
    anchor: "arp-poisoning"
  - symptom: "A frame arrives in a VLAN its sender was never on"
    anchor: "vlan-hopping"
---

> **Before you read.** A network is behaving perfectly. Nothing is slow, nothing
> is down, no alert has fired, and every application works. On one of the ports, a
> laptop is reading a copy of traffic between two machines it has no business
> seeing.
>
> Nothing was exploited in the sense of a bug being triggered. The switch is doing
> exactly what topic 14 said it does, and so is address resolution, and so is VLAN
> tagging.
>
> **How can everything be working and everything be readable?**

The attacks in this topic share a shape, and it is worth naming before the detail:
none of them breaks the protocol. Each one uses a protocol exactly as designed, in
a way the design did not anticipate, from a position on the local segment. That
last part is the theme of the whole topic and the reason segmentation and physical
security matter as much as they do.

### Some words you will need

<dl class="terms">
<dt>forwarding table</dt>
<dd>The switch's map of which MAC address is on which port, built by learning, from topic 14. Also called the CAM table or MAC address table.</dd>
<dt>flooding</dt>
<dd>Sending a frame out every port because the switch does not know which one the destination is on.</dd>
<dt>ARP cache</dt>
<dd>A host's map of IP address to MAC address, so it knows where to send a frame. Filled by asking and believing the answer.</dd>
<dt>on-path attack</dt>
<dd>An attacker positioned so that traffic between two parties passes through them. Once called man-in-the-middle.</dd>
<dt>gratuitous ARP</dt>
<dd>An ARP message nobody asked for, announcing an address. Legitimate for a few purposes and the vehicle for poisoning.</dd>
<dt>double tagging</dt>
<dd>Putting two VLAN tags on a frame so the first switch strips one and the second reads the other.</dd>
</dl>

## What breaks without this

**A switch quietly becomes a hub.** MAC flooding does not break the switch, it
fills the one table the switch depends on, and a switch that cannot place a
destination floods it. Everyone on the segment reads everyone else.

**A host is happy to be lied to.** ARP has no way to check an answer, so a host
sends its traffic wherever the most recent reply told it to, which an attacker can
be.

**A tag is trusted because a switch put it there.** VLAN separation rests on
switches honouring tags, and a frame that arrives with a tag on it is trusted to
be in that VLAN, whoever wrote the tag.

## MAC flooding

Topic 14 built the forwarding table: a switch learns which MAC is on which port by
watching source addresses, and it uses that map to send each frame only to the
port it belongs on. That is the entire reason a switch is better than a hub, and it
depends on the table being able to hold the addresses that matter.

The table is finite. An attacker sends a flood of frames with thousands of
invented source addresses, the table fills with them, and there is no room to learn
or keep the real ones. A switch that cannot find a destination in its table does
the only safe thing it can: it floods the frame to every port, exactly as it would
for a genuinely unknown address. The attack does not make the switch misbehave. It
makes every destination unknown, and a switch handling an unknown destination
behaves like a hub.

<figure class="learn-figure">
<svg viewBox="0 0 720 274" role="img" aria-labelledby="flood-title" style="width:100%;height:auto;">
<title id="flood-title">A switch forwarding table filled with invented addresses so that real ones cannot be learned, which returns the switch to flooding every frame</title>
<g fill="currentColor">
<text x="14" y="20" font-size="11">the table from topic 14, and what happens when it is full</text>
<rect x="14" y="40" width="320" height="150" rx="4" fill="currentColor" fill-opacity="0.05" stroke="currentColor" stroke-opacity="0.5"/>
<text x="28" y="62" font-size="11">a healthy table</text>
<text x="28" y="88" font-size="10.5">02:..:01</text>
<text x="200" y="88" font-size="10.5" fill-opacity="0.8">sw-h1</text>
<text x="28" y="110" font-size="10.5">02:..:02</text>
<text x="200" y="110" font-size="10.5" fill-opacity="0.8">sw-h2</text>
<text x="28" y="132" font-size="10.5">02:..:03</text>
<text x="200" y="132" font-size="10.5" fill-opacity="0.8">sw-h3</text>
<text x="28" y="156" font-size="10" fill-opacity="0.65">room for thousands more</text>
<text x="28" y="180" font-size="10.5">a frame for h2 leaves one port</text>
<rect x="386" y="40" width="320" height="150" rx="4" fill="var(--red)" fill-opacity="0.07" stroke="var(--red)" stroke-width="1.8"/>
<text x="400" y="62" font-size="11" fill="var(--red)">the same table, flooded</text>
<text x="400" y="88" font-size="10.5" fill="var(--red)">02:00:9f:3c:a1:00</text>
<text x="600" y="88" font-size="10.5" fill="var(--red)" fill-opacity="0.8">sw-h4</text>
<text x="400" y="110" font-size="10.5" fill="var(--red)">02:01:9f:3c:a1:01</text>
<text x="600" y="110" font-size="10.5" fill="var(--red)" fill-opacity="0.8">sw-h4</text>
<text x="400" y="132" font-size="10.5" fill="var(--red)">02:02:9f:3c:a1:02</text>
<text x="600" y="132" font-size="10.5" fill="var(--red)" fill-opacity="0.8">sw-h4</text>
<text x="400" y="156" font-size="10" fill="var(--red)" fill-opacity="0.9">and thousands more, all invented</text>
<text x="400" y="180" font-size="10.5" fill="var(--red)">a frame for h2 leaves every port</text>
<text x="14" y="224" font-size="10.5">nothing here is exploited. the switch is doing what topic 14 said it does: learning from what it</text>
<text x="14" y="240" font-size="10.5" fill-opacity="0.85">hears and flooding what it cannot place. the attacker made it unable to place anything.</text>
<text x="14" y="264" font-size="10.5">so it behaves like a hub, and everyone attached reads everyone else.</text>
</g></svg>
<figcaption>The forwarding table is finite, and the attack fills it with addresses that lead nowhere. A real destination can no longer be found, and a switch that cannot find a destination floods the frame to every port, which is what it is supposed to do for an address it has never seen. The switch is not broken and no rule is bypassed. It has simply been made to treat every address as unknown, and an unknown address is flooded.</figcaption>
</figure>

The lab shows the effect directly. It builds one switch with four hosts, and the
question is whether a bystander on one port can read a conversation between two
others. The topology is
[`l2-attacks.sh`](https://github.com/rlwilliamson-dev/azure-resume/blob/main/blog/scripts/topologies/l2-attacks.sh).

First, a healthy switch that has learned where everyone is.

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology l2-attacks
# a healthy switch has learned where everyone is
$ ip netns exec bys ping -c1 -W1 -q 10.0.0.1 >/dev/null
$ ip netns exec h1  ping -c1 -W1 -q 10.0.0.9 >/dev/null
$ ip netns exec sw bridge fdb show br br0 | grep -E "02:00:00:00:00:(01|09) "
02:00:00:00:00:01 dev sw-h1 master br0 
02:00:00:00:00:09 dev sw-bys master br0 

# the attacker watches while h1 talks to bys, a conversation it is not part of
$ (ip netns exec atk timeout 3 tcpdump -i atk0 -n -c2 icmp > /tmp/base.txt 2>/dev/null &)
$ sleep 0.5
$ ip netns exec h1 ping -c2 -W1 -q 10.0.0.9 >/dev/null
$ sleep 1
$ echo "what the attacker saw:"
what the attacker saw:
$ cat /tmp/base.txt
$ echo "(nothing: the switch delivered it only to the port it belongs on)"
(nothing: the switch delivered it only to the port it belongs on)
```

The attacker saw nothing, because the switch delivered the conversation only to the
port it belonged on. Now the flooded condition. Filling a real table needs a flood
of thousands of frames; the lab reproduces the same end state directly, by turning
off learning so the switch can place no address at all, which is what a full table
amounts to.

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology l2-attacks
# reproduce an exhausted table: learning off on every port, before any traffic,
# so the switch can place no real address, which is what a full table amounts to
$ ip netns exec sw sh -c "for p in sw-h1 sw-gw sw-bys sw-atk; do bridge link set dev \$p learning off; done"

# the same watch, the same conversation
$ (ip netns exec atk timeout 3 tcpdump -i atk0 -n -c2 icmp > /tmp/flood.txt 2>/dev/null &)
$ sleep 0.5
$ ip netns exec h1 ping -c2 -W1 -q 10.0.0.9 >/dev/null
$ sleep 1
$ echo "what the attacker saw this time:"
what the attacker saw this time:
$ cat /tmp/flood.txt
22:59:23.675675 IP 10.0.0.1 > 10.0.0.9: ICMP echo request, id 86, seq 1, length 64
22:59:23.675689 IP 10.0.0.9 > 10.0.0.1: ICMP echo reply, id 86, seq 1, length 64
```

The same conversation, the same bystander, and this time it read all of it. That is
MAC flooding: not a switch that malfunctions, but a switch returned to the
behaviour it has whenever it cannot place a destination.

## ARP poisoning

Address resolution, from topic 02, is how a host turns an IP address into the MAC
address to send a frame to. A host that wants to reach an IP it has no MAC for
broadcasts a question, "who has this address", and believes the reply. There is no
step where the reply is checked against the question, and no field in it that
proves anything. RFC 826 describes a protocol that trusts what it is told, because
it was designed for a network where that was a safe assumption.

An attacker sends replies nobody asked for. It tells one host that the gateway's
address is at the attacker's MAC, and tells the gateway that the host's address is
at the attacker's MAC. Both update their caches, because updating a cache from an
ARP message is what the protocol says to do. Now each one sends to the attacker the
traffic it means for the other, and the attacker forwards it on so that nothing
appears to be wrong.

<figure class="learn-figure">
<svg viewBox="0 0 720 260" role="img" aria-labelledby="arp-title" style="width:100%;height:auto;">
<title id="arp-title">Two hosts whose address resolution caches have been given the attacker MAC address for each other, so traffic between them passes through the attacker</title>
<g fill="currentColor">
<text x="14" y="20" font-size="11">what each machine believes, and what is true
</text>
<rect x="14" y="42" width="180" height="58" rx="4" fill="currentColor" fill-opacity="0.12" stroke="currentColor" stroke-opacity="0.6"/>
<text x="104" y="64" text-anchor="middle" font-size="11">h1</text>
<text x="104" y="82" text-anchor="middle" font-size="10" fill="var(--red)">gateway is at 02:..:ee</text>
<rect x="526" y="42" width="180" height="58" rx="4" fill="currentColor" fill-opacity="0.12" stroke="currentColor" stroke-opacity="0.6"/>
<text x="616" y="64" text-anchor="middle" font-size="11">the gateway</text>
<text x="616" y="82" text-anchor="middle" font-size="10" fill="var(--red)">h1 is at 02:..:ee</text>
<rect x="270" y="152" width="180" height="58" rx="4" fill="var(--red)" fill-opacity="0.18" stroke="var(--red)" stroke-width="2"/>
<text x="360" y="174" text-anchor="middle" font-size="11" fill="var(--red)">the attacker</text>
<text x="360" y="192" text-anchor="middle" font-size="10" fill="var(--red)">02:..:ee, and it forwards</text>
<g stroke="var(--red)" stroke-width="2" fill="none">
<path d="M 104 100 V 130 H 270 V 158"/>
<path d="M 616 100 V 130 H 450 V 158"/>
</g>
<line x1="194" y1="71" x2="526" y2="71" stroke="currentColor" stroke-opacity="0.3" stroke-width="1.4" stroke-dasharray="6 5"/>
<text x="360" y="64" text-anchor="middle" font-size="10" fill-opacity="0.6">what both of them think is happening</text>
<text x="14" y="236" font-size="10.5">both caches were simply told, and neither protocol asks for proof. traffic still arrives,
</text>
<text x="14" y="252" font-size="10.5" fill-opacity="0.85">at normal speed, in both directions, which is why nothing at either end reports a problem.
</text>
</g></svg>
<figcaption>Each end believes the other is at the attacker's MAC address, because each was told so and address resolution has no way to disbelieve it. The dashed line is the path both machines think their traffic takes; the solid red path is where it actually goes. The attacker forwards everything on, so the conversation completes normally and neither end has any reason to suspect the detour.</figcaption>
</figure>

The lab poisons both ends and then checks two things: what the victim now believes,
and whether the attacker really sees the traffic. Modern Linux guards an already
known entry more tightly than older stacks, so the topology puts the victims on the
permissive footing that most other devices use, and the accompanying comment says
so.

<details class="predict">
<summary>A host forgets what it knew and asks the segment again who the gateway is. Which machine answers, and whose address does the host write down?</summary>

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology l2-attacks
# both caches cleared to stand in for entries that have aged out, which they do
# on their own within the minute while the attacker keeps broadcasting
$ ip netns exec h1 ip neigh flush all
$ ip netns exec gw ip neigh flush all

# the attacker announces both addresses as its own, to everyone
$ ip netns exec atk python3 /root/arp.py atk0 ff:ff:ff:ff:ff:ff 10.0.0.254 10.0.0.254
told 10.0.0.254 that 10.0.0.254 is at 02:00:00:00:00:66
$ ip netns exec atk python3 /root/arp.py atk0 ff:ff:ff:ff:ff:ff 10.0.0.1   10.0.0.1
told 10.0.0.1 that 10.0.0.1 is at 02:00:00:00:00:66
$ sleep 0.3

# what h1 now believes the gateway is
$ ip netns exec h1 ip neigh show 10.0.0.254
10.0.0.254 dev h10 lladdr 02:00:00:00:00:66 STALE 

# the attacker watches, then h1 pings the gateway, which still works
$ (ip netns exec atk timeout 3 tcpdump -i atk0 -n -c4 icmp > /tmp/mitm.txt 2>/dev/null &)
$ sleep 0.5
$ ip netns exec h1 ping -c2 -W1 10.0.0.254 | grep "bytes from"
64 bytes from 10.0.0.254: icmp_seq=1 ttl=63 time=0.154 ms
64 bytes from 10.0.0.254: icmp_seq=2 ttl=63 time=0.049 ms
$ sleep 1

# that traffic, arriving at a host that is neither end of it
$ cat /tmp/mitm.txt
22:58:42.689072 IP 10.0.0.1 > 10.0.0.254: ICMP echo request, id 92, seq 1, length 64
22:58:42.689139 IP 10.0.0.1 > 10.0.0.254: ICMP echo request, id 92, seq 1, length 64
22:58:42.689155 IP 10.0.0.254 > 10.0.0.1: ICMP echo reply, id 92, seq 1, length 64
22:58:42.689165 IP 10.0.0.254 > 10.0.0.1: ICMP echo reply, id 92, seq 1, length 64
```

</details>

Three things in that capture are worth stopping on. The victim's cache now maps the
gateway's address to the attacker's MAC. The ping still succeeds, so from the user's
side the network is working. And the reply arrives with a TTL of 63 rather than 64,
which is the one visible trace: the packet took an extra hop, through a host that is
not supposed to be a hop. The attacker sees the whole conversation, appearing twice
in its own capture because it receives each packet and then forwards it.

<details class="deeper">
<summary>If you already work on networks: reading a poisoned neighbour table, and why the fix is not on the host</summary>

The evidence a poisoning leaves is in the neighbour table, and it is quiet. The
tell is one MAC address appearing against two different IP addresses: the attacker's
MAC is now the answer for both the gateway and the victim, because it announced
itself as both. A neighbour table with two IPs resolving to one MAC, where those two
IPs are a host and its gateway, is a poisoning until proven otherwise.

The reason this is hard to fix on the host is that the host is behaving correctly.
It asked a question, got an answer, and believed it, which is the protocol. Static
entries defeat poisoning for a handful of critical addresses and do not scale to a
whole network. The real defences live on the switch and are the mirror image of the
attack: dynamic ARP inspection watches ARP messages and drops the ones that
contradict what the switch knows from DHCP, and the DHCP snooping that feeds it is
the switch keeping its own record of which address it handed to which port.

So the pattern is the same as MAC flooding. The host cannot defend itself, because
the attack is the protocol working, and the defence is a switch that has been given
enough independent knowledge to tell a true binding from a false one.

</details>

## VLAN hopping

VLAN separation, from topic 17, rests on tags. A frame in VLAN 20 carries a tag
saying so, a switch reads the tag and keeps the frame among the VLAN 20 ports, and
the separation is only as good as the switches honouring those tags. Double tagging
attacks the one place a tag gets removed.

A trunk carries many VLANs, each tagged, with one exception: the native VLAN, which
is sent untagged. That is a decision in the standard, and it means a switch putting
a native-VLAN frame onto a trunk has to strip a tag to do it. The attacker, on an
access port in the native VLAN, sends a frame with two tags: an outer one for the
native VLAN and an inner one for the VLAN it wants to reach. The first switch reads
the outer tag, accepts the frame as native-VLAN traffic, and strips that tag as it
forwards onto the trunk. What crosses the trunk is a frame carrying the inner tag,
and the next switch reads it as belonging to a VLAN the attacker was never on.

<figure class="learn-figure">
<svg viewBox="0 0 720 258" role="img" aria-labelledby="hop2-title" style="width:100%;height:auto;">
<title id="hop2-title">A frame carrying two VLAN tags, where the first switch strips the outer one and the second switch reads the inner one, delivering it into a VLAN the sender was never on</title>
<g fill="currentColor">
<text x="14" y="20" font-size="11">one frame, two tags, and two switches each doing exactly one correct thing
</text>
<text x="14" y="36" font-size="10" fill-opacity="0.75">as the attacker sends it, on an access port in VLAN 1</text>
<rect x="14" y="44" width="96" height="36" rx="3" fill="currentColor" fill-opacity="0.08" stroke="currentColor" stroke-width="1" stroke-opacity="0.5"/>
<text x="62" y="67" text-anchor="middle" font-size="10" fill="currentColor">MAC headers</text>
<rect x="118" y="44" width="96" height="36" rx="3" fill="currentColor" fill-opacity="0.08" stroke="currentColor" stroke-width="1" stroke-opacity="0.5"/>
<text x="166" y="67" text-anchor="middle" font-size="10" fill="currentColor">tag: vlan 1</text>
<rect x="222" y="44" width="96" height="36" rx="3" fill="var(--red)" fill-opacity="0.2" stroke="var(--red)" stroke-width="1.8"/>
<text x="270" y="67" text-anchor="middle" font-size="10" fill="var(--red)">tag: vlan 20</text>
<rect x="326" y="44" width="150" height="36" rx="3" fill="currentColor" fill-opacity="0.04" stroke="currentColor" stroke-opacity="0.4" stroke-dasharray="5 4"/>
<text x="401" y="67" text-anchor="middle" font-size="10" fill-opacity="0.7">payload</text>
<text x="14" y="118" font-size="10" fill-opacity="0.75">after the first switch strips the outer tag, because VLAN 1 is its native VLAN</text>
<rect x="14" y="126" width="96" height="36" rx="3" fill="currentColor" fill-opacity="0.08" stroke="currentColor" stroke-width="1" stroke-opacity="0.5"/>
<text x="62" y="149" text-anchor="middle" font-size="10" fill="currentColor">MAC headers</text>
<rect x="118" y="126" width="96" height="36" rx="3" fill="var(--red)" fill-opacity="0.2" stroke="var(--red)" stroke-width="1.8"/>
<text x="166" y="149" text-anchor="middle" font-size="10" fill="var(--red)">tag: vlan 20</text>
<rect x="222" y="126" width="150" height="36" rx="3" fill="currentColor" fill-opacity="0.04" stroke="currentColor" stroke-opacity="0.4" stroke-dasharray="5 4"/>
<text x="297" y="149" text-anchor="middle" font-size="10" fill-opacity="0.7">payload</text>
<text x="380" y="176" font-size="10.5" fill="var(--red)">the second switch now reads a frame</text>
<text x="380" y="192" font-size="10.5" fill="var(--red)">tagged for VLAN 20 and delivers it there</text>
<text x="14" y="228" font-size="10.5">neither switch is wrong. the first removed the native tag, which is what a trunk does, and the
</text>
<text x="14" y="244" font-size="10.5" fill-opacity="0.85">second trusted a tag, which is what a trunk does. the attacker supplied the second tag.
</text>
</g></svg>
<figcaption>The attacker sends a frame with two tags. The first switch reads the outer one, sees its own native VLAN, and removes it on the way onto the trunk, which is exactly what a trunk does with a native-VLAN frame. What is left is the inner tag, and the next switch has no way to know it was not put there legitimately. Each switch does one correct thing, and the sum of the two is a frame in a VLAN the attacker had no access to.</figcaption>
</figure>

The lab captures the decisive moment on the trunk itself, which is the only place
the frame changes shape. The topology is
[`vlan-hop.sh`](https://github.com/rlwilliamson-dev/azure-resume/blob/main/blog/scripts/topologies/vlan-hop.sh).

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology vlan-hop
# an ordinary vlan 1 frame, the access the attacker has. it leaves the native
# trunk with no tag at all, because that is what native means
$ (ip netns exec mon timeout 3 tcpdump -i t2 -e -n -c1 arp > /tmp/base.txt 2>/dev/null &)
$ sleep 0.5
$ ip netns exec atk python3 /root/dtag.py atk0 1 0 >/dev/null
$ sleep 1
$ cat /tmp/base.txt
22:59:51.339919 02:00:00:00:00:aa > ff:ff:ff:ff:ff:ff, ethertype ARP (0x0806), length 42: Request who-has 10.0.20.9 tell 10.0.20.66, length 28

# the same attacker, one extra tag. the switch strips the outer native tag, and
# what crosses the trunk is a vlan 20 frame
$ (ip netns exec mon timeout 3 tcpdump -i t2 -e -n -c1 vlan > /tmp/hop.txt 2>/dev/null &)
$ sleep 0.5
$ ip netns exec atk python3 /root/dtag.py atk0 1 20
sent a frame tagged outer vlan 1, inner vlan 20
$ sleep 1
$ cat /tmp/hop.txt
22:59:52.876530 02:00:00:00:00:aa > ff:ff:ff:ff:ff:ff, ethertype 802.1Q (0x8100), length 46: vlan 20, p 0, ethertype ARP (0x0806), Request who-has 10.0.20.9 tell 10.0.20.66, length 28
```

The first frame is an ordinary VLAN 1 frame, the access the attacker actually has,
and it crosses the trunk with no tag at all, because that is what native means. The
second frame is the same attacker with one extra tag, and it crosses the trunk
labelled for VLAN 20. The attacker had no access to VLAN 20 and a VLAN 20 frame is
now on the wire, put there by two switches each behaving correctly.

There is one honest limitation worth stating: double tagging sends a frame in one
direction only. The reply would have to cross back the same way, and there is no
native VLAN trick for the return path, so this is a way to inject traffic into a
VLAN rather than to hold a conversation with it. That is still enough to matter,
and the defence is the same small change either way, which is not using the native
VLAN for anything and not making it a VLAN any access port sits in.

## Prove it

Every capture on this page comes from the lab; the block above and the two before
it are the whole of it. The topologies are
[`l2-attacks.sh`](https://github.com/rlwilliamson-dev/azure-resume/blob/main/blog/scripts/topologies/l2-attacks.sh)
and
[`vlan-hop.sh`](https://github.com/rlwilliamson-dev/azure-resume/blob/main/blog/scripts/topologies/vlan-hop.sh),
and both are worth reading for one reason: the attacker's tools in them are a few
lines of Python writing raw frames, not a downloaded exploit. That is the point the
captures make together. None of these needs a vulnerability, because none of them
triggers a bug. They use address learning, address resolution and VLAN tagging
exactly as specified, from a port on the segment.

**RFC 826.** The address resolution protocol, four pages, and worth reading for a
single realisation: there is no authentication in it because there was no threat
model that needed one. The poisoning is not a flaw that was introduced. It is the
absence of a defence that was never designed in.

## What trips people up

### 1. Thinking MAC flooding breaks the switch

It does not. It fills the forwarding table, and a switch with a full table floods
unknown destinations, which is correct behaviour. The switch is working; it has
just been made unable to place any address.

### 2. Expecting a poisoned host to notice

The host asked a question and believed the answer, which is the protocol. Nothing
at either end reports a problem, because nothing went wrong from their point of
view. The only visible trace is the extra hop in the TTL.

### 3. Believing a VLAN tag proves where a frame came from

A tag says which VLAN a frame is in, not who put it there. Double tagging exploits
exactly that: the second switch trusts a tag the attacker supplied, because trusting
a tag is what a switch does.

### 4. Assuming these work from anywhere

All three need access to the local segment. MAC flooding needs a port on the switch,
poisoning needs to be on the same broadcast domain, and hopping needs an access port
in the native VLAN. Remote versions do not exist, which is why physical and
segmentation controls are the real defence.

### 5. Fixing poisoning on the host

A host cannot defend itself, because it is behaving correctly. The defences are on
the switch: DHCP snooping and dynamic ARP inspection, which give the switch enough
independent knowledge to reject a false binding.

### 6. Leaving the native VLAN in use

Double tagging depends on the native VLAN being untagged and on the attacker sitting
in it. Not using the native VLAN for any access port removes the foothold, and it is
the cheapest fix on this page.

## Work it through

The scenario at the top, worked as an investigation.

First, notice that nothing is broken, which is the clue rather than the absence of
one. Every one of these attacks is invisible to the machines involved, because each
is a protocol working. A network that is entirely healthy and in which someone is
reading traffic is exactly what these attacks produce, so "everything works" does
not rule them out, it is the symptom.

Then decide which of the three you are looking at by where the evidence would be. If
the switch is flooding unicast to every port, the forwarding table is the place to
look, and a table full of addresses that lead to one port is MAC flooding. If two
hosts are talking through a third, the neighbour tables are the place, and one MAC
answering for two IPs is poisoning. If a frame turned up in a VLAN its source has no
access to, the trunk configuration is the place, and a native VLAN shared with an
access port is the hopping foothold.

Then remember that all three start with access to the segment, so the containing
question is how the attacker got a port. That turns a layer-two incident into the
physical and segmentation question it actually is, which is topic 52 and topic 55,
and it is the reason those come before this one.

Then apply the switch-side defence that matches, because none of these is fixed on
the endpoint. Port security limits the addresses on a port and blunts flooding.
DHCP snooping and dynamic ARP inspection reject false bindings and stop poisoning.
Retiring the native VLAN closes hopping. Each defence lives where the attack does,
which is the switch.

## Try it

**Run the flooding lab and watch the table.** Add `bridge fdb show` before and
after turning learning off in
[`l2-attacks.sh`](https://github.com/rlwilliamson-dev/azure-resume/blob/main/blog/scripts/topologies/l2-attacks.sh),
and watch the switch lose its ability to place a destination.

**Read the poisoner.** The ARP sender in the same topology is about a dozen lines of
Python. Reading it is what makes "there is no authentication in ARP" stop being a
slogan: you can see there is no field it could put a proof in.

**Change the native VLAN in the hopping lab.** Give the trunk a native VLAN that no
access port sits in, in
[`vlan-hop.sh`](https://github.com/rlwilliamson-dev/azure-resume/blob/main/blog/scripts/topologies/vlan-hop.sh),
and watch the double-tagged frame stop crossing. That one change is the whole
defence.

## Check yourself

<details class="qa">
<summary>MAC flooding is running and the switch is fine. How is traffic being read?</summary>

The switch is fine and that is the point. The flood filled its forwarding table with
invented addresses, so it can no longer find the real ones, and a switch that cannot
place a destination floods the frame to every port.

That flooding is correct behaviour for an unknown address. The attacker did not make
the switch malfunction, it made every address unknown, and an unknown address goes
everywhere. The switch is behaving like a hub because it has been forced into the
one situation where a switch behaves like a hub.

</details>

<details class="qa">
<summary>Why can a host not defend itself against ARP poisoning?</summary>

Because the host is behaving correctly. It needed a MAC address for an IP, it asked,
and it believed the reply, which is exactly what address resolution specifies. There
is no field in the reply it could check and no step where it is meant to doubt.

The defence has to come from somewhere with independent knowledge, which is the
switch. DHCP snooping records which address it handed to which port, and dynamic ARP
inspection uses that record to drop ARP messages that contradict it. The host cannot
do this because it has nothing to check the answer against.

</details>

<details class="qa">
<summary>In a poisoned network, what single observation in a host's neighbour table gives it away?</summary>

One MAC address appearing as the answer for two different IP addresses, especially
when those two are a host and its gateway. The attacker announced its own MAC as
both, so both entries resolve to it.

A ping still working does not clear it, because the attacker forwards the traffic on.
The other quiet tell is a TTL one lower than expected on replies, because the packet
took an extra hop through the attacker.

</details>

<details class="qa">
<summary>Why does double tagging need the attacker to be in the trunk's native VLAN?</summary>

Because the native VLAN is the one a trunk sends untagged, so it is the one place a
switch removes a tag. The attacker's outer tag has to be the native VLAN, so that the
first switch strips it and exposes the inner tag.

If the attacker's VLAN were tagged on the trunk like any other, the first switch would
carry both tags across and the second would read the outer one, which is the
attacker's real VLAN, and nothing would hop. The untagged native VLAN is the whole
mechanism, which is why not using it is the whole defence.

</details>

<details class="qa">
<summary>What do all three attacks have in common, and why does it matter for defence?</summary>

None of them breaks a protocol. MAC learning, address resolution and VLAN tagging are
each used exactly as designed, and each attack needs access to the local segment: a
port on the switch, a place on the broadcast domain, an access port in the native
VLAN.

It matters because it tells you where the defences are. You cannot patch a bug that
does not exist. You control who gets a port, which is physical security and
segmentation, and you configure the switch to reject the specific abuse, which is
port security, DHCP snooping with dynamic ARP inspection, and retiring the native
VLAN.

</details>

## References

- [RFC 826](https://www.rfc-editor.org/rfc/rfc826) - IETF, the address resolution protocol, and the clearest evidence that it was never designed to authenticate a reply. Free. Accessed 2026-08-15.
- [IEEE 802.1Q-2022](https://standards.ieee.org/ieee/802.1Q/7096/) - IEEE, VLAN tagging and the native VLAN behaviour double tagging relies on. The standard is paywalled; the native-VLAN untagging it defines is what the lab captures. Accessed 2026-08-15.
- [RFC 4949](https://www.rfc-editor.org/rfc/rfc4949) - IETF, the internet security glossary, for on-path attack and the other vocabulary on this page. Free. Accessed 2026-08-15.

**Where the numbers came from.** Every terminal block is from
[`l2-attacks.sh`](https://github.com/rlwilliamson-dev/azure-resume/blob/main/blog/scripts/topologies/l2-attacks.sh)
or
[`vlan-hop.sh`](https://github.com/rlwilliamson-dev/azure-resume/blob/main/blog/scripts/topologies/vlan-hop.sh)
run through `netlab.sh`, on the kernel named in each block's header. The MAC
addresses are the lab's own `02:00:00:00:00:xx` range and the addresses are
documentation ranges. The flooded condition is reproduced by turning learning off
rather than by sending a real flood of thousands of frames, which reaches the same
end state; the topology comment says so, and the capture shows the effect either
way.

**If you also work on Linux.** The attacker's tools are standard Linux: a raw
`AF_PACKET` socket writing ARP replies and VLAN-tagged frames by hand, which is all
either attack needs. `ip neigh show` reads the poisoned cache, `bridge fdb show`
reads the switch table, and `bridge link set dev X learning off` is the switch
behaviour the flooding capture forces.
