---
title: "Trunking and 802.1Q tagging"
description: "One cable between two switches carrying eight VLANs. Where the tag sits in the frame, the four bytes it costs, what the native VLAN is and why it causes arguments, and what happens when the two ends of a trunk disagree about any of it."
deck: "One cable between two switches, carrying eight VLANs"
track: "network-plus"
level: "working"
order: 180
objectives:
  - "Say where the 802.1Q tag sits in a frame and what it contains"
  - "State what a tag costs and what that does to the maximum frame size"
  - "Explain the difference between an access port and a trunk port"
  - "Say what the native VLAN is and why untagged traffic on a trunk is contentious"
  - "Predict what happens when the two ends of a trunk are configured differently"
prerequisites: ["vlans"]
tags: ["network-plus", "networking", "switching", "vlans"]
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
  - title: "IEEE 802.3 Standard for Ethernet"
    url: "https://standards.ieee.org/ieee/802.3/10422/"
    publisher: "IEEE Standards Association"
    accessed: 2026-08-10
    tier: 1
  - title: "tcpdump(1)"
    url: "https://www.tcpdump.org/manpages/tcpdump.1.html"
    publisher: "tcpdump.org"
    accessed: 2026-08-10
    tier: 1
symptoms:
  - symptom: "Some VLANs work across a link between switches and others do not"
    anchor: "when-the-two-ends-disagree"
  - symptom: "Traffic appears in the wrong VLAN after crossing a switch"
    anchor: "the-native-vlan-and-the-argument-about-it"
---

> **Before you read.** Two switches in two comms rooms, one fibre between them,
> and eight VLANs that all need to reach both buildings.
>
> Running eight cables is not an option, and a frame carries no field saying
> which VLAN it belongs to.
>
> **So how does the far switch know which VLAN an arriving frame is in?**

The previous topic left one thing unexplained. VLAN membership is decided by the
port a frame arrives on, which works beautifully until a frame has to leave the
switch. A port that carries several VLANs cannot use that rule, so something else
has to travel with the frame.

### Some words you will need

<dl class="terms">
<dt>trunk</dt>
<dd>A port carrying several VLANs, with a tag on each frame saying which.</dd>
<dt>tag</dt>
<dd>Four bytes inserted into the Ethernet header, containing the VLAN ID.</dd>
<dt>native VLAN</dt>
<dd>The one VLAN on a trunk whose frames travel untagged.</dd>
<dt>allowed VLAN list</dt>
<dd>Which VLANs a given trunk is permitted to carry. Everything else is dropped.</dd>
<dt>802.1Q</dt>
<dd>The IEEE standard that defines the tag. Sometimes said as "dot1q".</dd>
</dl>

## What breaks without this

**Half your VLANs work between buildings and half do not.** An allowed list that
does not match at both ends produces exactly that, and nothing logs an error.

**Traffic ends up in the wrong VLAN.** A native VLAN mismatch silently moves
untagged frames from one VLAN into another, which is a separation failure that
looks like everything working.

**You cannot read a capture from an uplink.** Every frame on a trunk looks
different from every frame you have seen so far, and not recognising the tag
means misreading the whole capture.

## The tag, and where it goes

The tag is four bytes, inserted into the Ethernet header after the source
address and before the field that says what the payload is.

It holds two things worth knowing. The VLAN ID is 12 bits, giving the 1 to 4094
range from the previous topic. Three bits carry a priority value, which is where
layer 2 quality of service lives, and it is the reason the same four bytes get
used on links with no VLANs at all.

Rather than describe it, here is the same ping seen twice: once on the trunk
between the switches, and once on the access port where it comes out at the far
end.

<details class="predict">
<summary>One echo request crosses a trunk and arrives at a host. How does the frame differ at the two points, and by how much?</summary>

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology vlan-switch
# watch the trunk while a VLAN 10 host talks across it
$ (ip netns exec sw1 timeout 9 tcpdump -i sw1-trunk -n -e -U icmp > /tmp/trunk.txt 2>/dev/null &)
$ (ip netns exec sw2 timeout 9 tcpdump -i sw2-h3 -n -e -U icmp > /tmp/access.txt 2>/dev/null &)
$ sleep 2
$ ip netns exec h1 ping -c 1 10.0.10.3 > /dev/null 2>&1
$ sleep 9
# on the trunk, tagged
$ cat /tmp/trunk.txt
23:29:40.104454 02:00:00:00:00:01 > 02:00:00:00:00:03, ethertype 802.1Q (0x8100), length 102: vlan 10, p 0, ethertype IPv4 (0x0800), 10.0.10.1 > 10.0.10.3: ICMP echo request, id 122, seq 1, length 64
23:29:40.104461 02:00:00:00:00:03 > 02:00:00:00:00:01, ethertype 802.1Q (0x8100), length 102: vlan 10, p 0, ethertype IPv4 (0x0800), 10.0.10.3 > 10.0.10.1: ICMP echo reply, id 122, seq 1, length 64

# on the access port at the far end, untagged
$ cat /tmp/access.txt
23:29:40.104455 02:00:00:00:00:01 > 02:00:00:00:00:03, ethertype IPv4 (0x0800), length 98: 10.0.10.1 > 10.0.10.3: ICMP echo request, id 122, seq 1, length 64
23:29:40.104460 02:00:00:00:00:03 > 02:00:00:00:00:01, ethertype IPv4 (0x0800), length 98: 10.0.10.3 > 10.0.10.1: ICMP echo reply, id 122, seq 1, length 64
```

</details>

Read the two `length` values first. **102 on the trunk and 98 on the access
port**, and the difference is the four bytes of tag, added on the way onto the
trunk and stripped on the way off it.

<figure class="learn-figure">
<svg viewBox="0 0 720 278" role="img" aria-labelledby="tag-title" style="width:100%;height:auto;">
<title id="tag-title">A byte ruler over the same frame on an access port and on a trunk, showing the four byte 802.1Q tag inserted at offset 12 and everything after it displaced four bytes</title>
<g font-family="ui-monospace, monospace" fill="currentColor">
<text x="40" y="20" font-size="11">on the access port, which is everything a host ever sees</text>
<g stroke="currentColor" stroke-opacity="0.45">
<line x1="40" y1="44" x2="40" y2="56"/>
<line x1="184" y1="44" x2="184" y2="56"/>
<line x1="328" y1="44" x2="328" y2="56"/>
<line x1="376" y1="44" x2="376" y2="56"/>
</g>
<g font-size="10" fill-opacity="0.7" text-anchor="middle">
<text x="40" y="38">0</text>
<text x="184" y="38">6</text>
<text x="328" y="38">12</text>
<text x="376" y="38">14</text>
</g>
<g stroke="currentColor" stroke-opacity="0.55" fill="none">
<rect x="40" y="56" width="144" height="42"/>
<rect x="184" y="56" width="144" height="42"/>
<rect x="328" y="56" width="48" height="42"/>
</g>
<path d="M 376 56 H 520 M 376 98 H 520" stroke="currentColor" stroke-opacity="0.55" fill="none"/>
<path d="M 520 56 l 10 10 l -10 11 l 10 10 l -10 11" stroke="currentColor" stroke-opacity="0.55" fill="none"/>
<g text-anchor="middle">
<text x="112" y="76" font-size="10.5">destination MAC</text>
<text x="112" y="91" font-size="10" fill-opacity="0.7">6 bytes</text>
<text x="256" y="76" font-size="10.5">source MAC</text>
<text x="256" y="91" font-size="10" fill-opacity="0.7">6 bytes</text>
<text x="352" y="76" font-size="10.5">type</text>
<text x="352" y="91" font-size="10" fill-opacity="0.7">0x0800</text>
<text x="448" y="76" font-size="10.5" fill-opacity="0.75">payload</text>
<text x="448" y="91" font-size="10" fill-opacity="0.7">84 bytes</text>
</g>
<text x="546" y="81" font-size="10.5">98 bytes</text>
<text x="40" y="142" font-size="11">on the trunk between the two switches</text>
<g stroke="currentColor" stroke-opacity="0.45">
<line x1="40" y1="166" x2="40" y2="178"/>
<line x1="184" y1="166" x2="184" y2="178"/>
<line x1="328" y1="166" x2="328" y2="178"/>
<line x1="424" y1="166" x2="424" y2="178"/>
<line x1="472" y1="166" x2="472" y2="178"/>
</g>
<g font-size="10" fill-opacity="0.7" text-anchor="middle">
<text x="40" y="160">0</text>
<text x="184" y="160">6</text>
<text x="328" y="160">12</text>
<text x="424" y="160" fill="var(--accent)" fill-opacity="1">16</text>
<text x="472" y="160">18</text>
</g>
<g stroke="currentColor" stroke-opacity="0.55" fill="none">
<rect x="40" y="178" width="144" height="42"/>
<rect x="184" y="178" width="144" height="42"/>
<rect x="424" y="178" width="48" height="42"/>
</g>
<rect x="328" y="178" width="96" height="42" fill="var(--accent)" fill-opacity="0.22" stroke="var(--accent)" stroke-width="2"/>
<path d="M 472 178 H 616 M 472 220 H 616" stroke="currentColor" stroke-opacity="0.55" fill="none"/>
<path d="M 616 178 l 10 10 l -10 11 l 10 10 l -10 11" stroke="currentColor" stroke-opacity="0.55" fill="none"/>
<g text-anchor="middle">
<text x="112" y="198" font-size="10.5">destination MAC</text>
<text x="112" y="213" font-size="10" fill-opacity="0.7">unchanged</text>
<text x="256" y="198" font-size="10.5">source MAC</text>
<text x="256" y="213" font-size="10" fill-opacity="0.7">unchanged</text>
<text x="376" y="198" font-size="10.5" fill="var(--accent)">802.1Q</text>
<text x="376" y="213" font-size="10" fill="var(--accent)" fill-opacity="0.85">0x8100</text>
<text x="448" y="198" font-size="10.5">type</text>
<text x="448" y="213" font-size="10" fill-opacity="0.7">0x0800</text>
<text x="544" y="198" font-size="10.5" fill-opacity="0.75">payload</text>
<text x="544" y="213" font-size="10" fill-opacity="0.7">unchanged</text>
</g>
<text x="642" y="203" font-size="10.5">102 bytes</text>
<path d="M 376 104 V 172" stroke="var(--accent)" stroke-width="1.6" stroke-dasharray="4 3"/>
<path d="M 340 234 L 356 226" stroke="var(--accent)" stroke-opacity="0.7" fill="none"/>
<text x="334" y="238" text-anchor="end" font-size="10.5" fill="var(--accent)">vlan 10, p 0</text>
<g stroke="var(--accent)" stroke-width="1.6" fill="none">
<path d="M 424 244 H 472"/>
<path d="M 424 244 l 7 -5 M 424 244 l 7 5"/>
<path d="M 472 244 l -7 -5 M 472 244 l -7 5"/>
</g>
<line x1="424" y1="236" x2="424" y2="252" stroke="var(--accent)" stroke-opacity="0.5"/>
<line x1="472" y1="236" x2="472" y2="252" stroke="var(--accent)" stroke-opacity="0.5"/>
<text x="486" y="242" font-size="10.5">4 bytes, and everything</text>
<text x="486" y="257" font-size="10.5">after it moves right</text>
</g>
</svg>
<figcaption>Both rows are drawn to one scale, so the four byte tag is four bytes wide and the move from offset 14 to offset 18 is a measurement rather than a claim. Nothing to the left of offset 12 changes, which is why the two captures print identical MAC addresses. The tag carries the VLAN ID and the priority, and the ethertype it displaced still says IPv4: a tagged frame has two of those fields, and the first one exists only to announce that the second has been pushed along.</figcaption>
</figure>

The trunk lines say `ethertype 802.1Q (0x8100), length 102: vlan 10, p 0,
ethertype IPv4`. That is the tag doing its job: the first ethertype announces
that a tag follows, the tag carries `vlan 10` and priority `p 0`, and then the
real ethertype says the payload is IPv4. A tagged frame has two ethertype fields
and the first one exists only to say the second one has been pushed along.

The access port lines have one ethertype and no VLAN. **The host never sees a
tag.** Everything about VLANs is a conversation between switches, and the devices
at the edges are deliberately kept out of it.

The MAC addresses are identical in both captures, which is the reassuring part.
Tagging does not change who the frame is for. It adds a label saying which
virtual switch it belongs to, and the label is removed before delivery.

<details class="deeper">
<summary>If you already work on networks: the four bytes, and the MTU problem nobody notices until they build a tunnel</summary>

A standard Ethernet frame carries a maximum payload of 1500 bytes, which is the
MTU everybody quotes. Adding a tag makes the frame four bytes longer, and the
question of where those bytes come from has two possible answers.

The good answer, and the one modern equipment gives, is that the frame is
allowed to be four bytes longer. 802.1Q calls this an envelope frame, the maximum
grows from 1518 to 1522 bytes including headers, and the payload stays at 1500.
Nothing has to change on any host.

The bad answer is that the switch cannot do that, so a full-sized tagged frame is
too big and gets dropped or fragmented. This was a real problem on older
equipment and it is largely history, which is why most people never think about
the four bytes at all.

Where it stops being history is when tags start stacking. QinQ, which 802.1Q
calls provider bridging, puts a second tag outside the first so a provider can
carry a customer's tagged traffic without caring what the customer's VLAN numbers
are. Two tags is eight bytes. Add a tunnel and you are subtracting header after
header from the same 1500.

That is the topic 20 problem arriving from a direction people do not expect. The
symptom is always the same and always confusing: small packets work, large ones
vanish, and nothing reports an error. Worth carrying the general form, which is
that every encapsulation costs bytes out of the same budget, and the budget is
not renegotiated automatically.

For the exam, know that the tag is four bytes and that QinQ exists. The research
for this track found no QinQ detail in the objectives beyond the name.

</details>

## Access port against trunk port

Two port types, and the difference is one question: does this port carry more
than one VLAN?

| | Access port | Trunk port |
| --- | --- | --- |
| VLANs carried | One | Several |
| Frames on the wire | Untagged | Tagged, except the native VLAN |
| What plugs in | A host, printer, camera, access point | Another switch, a router, a hypervisor |
| Membership decided by | The port's PVID | The tag on each frame |
| Believes a tag from the device | No | Yes |

That last row is the security one from the previous topic, stated as a
configuration difference. An access port ignores tags a host sends and stamps its
own. A trunk believes them, because believing them is the entire purpose.

The allowed VLAN list is the other thing a trunk has. A trunk carries the VLANs
it has been told to and drops the rest, and configuring it as everything is
common, lazy, and the reason a compromised switch reaches more than it should.
Listing only the VLANs a link genuinely needs costs one line and limits the blast
radius.

Both ends of a trunk have to agree about all of this, and nothing enforces that.

## The native VLAN and the argument about it

One VLAN on a trunk travels untagged, and it is called the native VLAN.

The reason it exists is historical and reasonable. Trunks had to work with
devices that did not understand tags at all, so one VLAN was left untagged for
them. A frame arriving on a trunk with no tag is placed into the native VLAN,
which is exactly the PVID rule from the previous topic applied to a trunk port.

It causes two problems, and they are the main reason people configure it
deliberately rather than leaving it.

**A mismatch silently joins two VLANs.** If one end treats VLAN 1 as native and
the other treats VLAN 99 as native, frames leaving untagged from VLAN 1 arrive
and get placed into VLAN 99. Nothing errors. Two VLANs that were supposed to be
separate now leak into each other in one direction, which is a separation failure
that presents as things mysteriously working.

**It is the basis of an attack.** A device that sends a frame with a tag for
another VLAN, on a port whose native VLAN matches the outer situation, can get
that frame delivered into a VLAN it has no access to. The general name is VLAN
hopping, and the double tagging variant relies on the first switch stripping the
outer tag because it matches the native VLAN, and forwarding the frame with the
inner tag still on it.

The defences are all configuration rather than protocol. Set the native VLAN to
something unused on every trunk, so no real traffic is ever untagged. Do not use
VLAN 1 for it. And where equipment supports it, tag the native VLAN too, which
removes the exception entirely.

<details class="deeper">
<summary>If you already work on networks: why double tagging only works in one direction, and what that tells you</summary>

Double tagging is worth understanding properly rather than memorising, because
the mechanism explains both why it works and why it is easier to defend against
than it sounds.

The attacker sends a frame with two tags. The outer tag names the native VLAN of
the port they are on, and the inner tag names the VLAN they want to reach.

The first switch does what it always does with an incoming frame on a trunk: it
reads the outer tag, sees the native VLAN, and strips it, because native VLAN
traffic travels untagged. The frame continues on with the inner tag still
attached, and now it looks like an ordinary tagged frame for the target VLAN. The
second switch reads that inner tag and delivers it accordingly.

Two things follow.

It is one way only. The attacker can send a frame into the target VLAN and there
is no return path, because replies go to a machine in the target VLAN and get
forwarded normally, which does not lead back through the same trick. So this is
useful for injection and denial of service rather than for a conversation, which
substantially limits what it buys.

And it depends entirely on the native VLAN matching. If the port's native VLAN is
something the attacker cannot guess, or if the native VLAN is tagged like every
other, the outer tag is not stripped and the frame is either dropped or delivered
to a VLAN nobody cares about.

Which is why the defence is a configuration decision rather than a feature you
buy. Set the native VLAN to an unused number, never leave it as VLAN 1, and put
user-facing ports into access mode explicitly so they are never trunks in the
first place. Topic 56 covers this as an attack alongside the rest.

</details>

## When the two ends disagree

A trunk is configured independently at both ends and nothing checks that the
two configurations match. Three ways they diverge, in rough order of how often
you meet them.

**One end is a trunk and the other is an access port.** The access port stamps
everything into one VLAN and strips tags on the way out, so tagged frames arriving
from the trunk are either dropped or dumped into a single VLAN. The link comes up.
Some traffic works.

**The allowed lists differ.** VLANs on both lists work. VLANs on only one list
are sent by one end and dropped by the other, which produces the fault where some
VLANs cross a building and others do not, with no error anywhere.

**The native VLANs differ.** Untagged traffic changes VLAN as it crosses, as
above. This is the quietest of the three and the most serious.

The pattern to take from all three is that a trunk misconfiguration almost never
takes the link down. The interfaces are up, the cable is fine, and the fault is
selective: this VLAN works and that one does not. When somebody reports that some
things work between two sites and others do not, the trunk configuration at both
ends is the first thing to compare, and comparing means looking at both rather
than checking that one is correct.

Some vendors have a protocol that negotiates trunking automatically, so two ports
work out between themselves whether to become a trunk. It saves configuration and
it is the reason a device plugged into the wrong port can sometimes talk its way
into becoming a trunk. Serious configurations turn the negotiation off and state
what each port is.

## Prove it

You have this when you can look at a capture and tell immediately whether you are
on a trunk.

The topology is committed, so you can produce both views:

```bash
# on the trunk between the two switches
./blog/scripts/netlab.sh --topo topologies/vlan-switch.sh -- \
  '(ip netns exec sw1 timeout 6 tcpdump -i sw1-trunk -n -e -U icmp > /tmp/t.txt 2>/dev/null &); sleep 2; ip netns exec h1 ping -c 1 10.0.10.3 > /dev/null 2>&1; sleep 5; cat /tmp/t.txt'
```

Two things to confirm. The frames say `802.1Q (0x8100)` and name a VLAN. And the
length is four bytes more than the same frame on an access port.

On real equipment the check is the same and the tooling differs. Capturing from a
trunk port, or from a mirror of one, shows tagged frames in any packet analyser,
and the VLAN column is usually there and empty on ordinary captures. When it has
numbers in it, you are looking at a trunk.

## What trips people up

### 1. Thinking hosts see VLAN tags

They do not, on an access port. The switch strips the tag before the frame
leaves. Tags exist between switches, and a host that does see them is plugged
into a trunk, which is worth investigating.

### 2. Forgetting the native VLAN has to match at both ends

Nothing checks it, nothing errors, and a mismatch moves untagged traffic from one
VLAN into another. It is the quietest serious misconfiguration on this page.

### 3. Assuming a trunk carries every VLAN

It carries what its allowed list permits. A VLAN missing from one end's list is
sent by one switch and dropped by the other, which is why some VLANs cross a
link and others do not.

### 4. Expecting a trunk mismatch to break the link

It almost never does. The interfaces stay up and the fault is selective, which is
why people spend a long time on the cable and the optics before comparing the two
configurations.

### 5. Reading the tag as part of the payload

It sits in the header, between the source address and the ethertype, which is why
a tagged frame has two ethertype fields. The payload is untouched.

### 6. Leaving user-facing ports able to negotiate trunking

A port that can be talked into becoming a trunk will believe tags from whatever
is plugged into it. Access ports should be configured as access ports explicitly
and negotiation turned off.

## Work it through

Two buildings, one fibre between them, eight VLANs. Users in building B report
that the office network and the phones work, the guest wireless works, and the
building management VLAN does not reach building A at all. The fibre is fine and
both switches show the link up.

The shape of the fault does most of the diagnosis. Some VLANs cross and one does
not, on a link that is up. That rules out the physical layer entirely: a fibre
problem or a duplex problem does not pick one VLAN out of eight. It also rules
out anything at layer 3, because this is one VLAN failing to cross a switch to
switch link rather than a routing problem.

So it is the trunk, and specifically something that treats VLANs differently
from each other. The allowed list is the candidate that fits exactly: the
management VLAN is on one end's list and not the other's, so frames are sent and
dropped.

The thing to do is compare both ends rather than check one. That distinction
matters more than it sounds, because a trunk configuration always looks correct
in isolation. Somebody added the management VLAN when it was created, added it to
the switch they were logged into, and did not do the other end.

Two more things worth checking while you are in there, since you are looking at
trunk configuration anyway. Whether the native VLANs match, because a mismatch is
worse than what was reported and nobody would have noticed it. And whether the
allowed list is an explicit list or set to everything, because if it is set to
everything on one end then the fault is on the other end and the explicit list is
missing an entry.

Notice what nobody needs to do here: no reboot, no cable test, and no involvement
from the users who reported it. The symptom named the layer, the layer named the
device, and the comparison names the line.

## Check yourself

<details class="qa">
<summary>A frame on a trunk is 102 bytes and the same frame on an access port is 98. What are the four bytes?</summary>

The 802.1Q tag, added when the frame entered the trunk and stripped when it left.

The tag sits in the header after the source MAC address, so a tagged frame has
two ethertype fields: the first is `0x8100`, saying a tag follows, and the second
is the real one saying what the payload is.

Twelve of the tag's bits are the VLAN ID and three are a priority value used for
layer 2 quality of service.

</details>

<details class="qa">
<summary>The two ends of a trunk have different native VLANs. What happens, and why is it hard to notice?</summary>

Untagged frames change VLAN as they cross. One switch sends the native VLAN
untagged, the other receives an untagged frame and places it into its own native
VLAN, which is a different one.

It is hard to notice because nothing fails. The link is up, no error is logged,
and traffic flows. What has happened is that two VLANs that were supposed to be
separate are now joined in one direction, which is a separation failure presenting
as things working.

The defence is to set the native VLAN explicitly to an unused number on every
trunk, so no real traffic ever travels untagged.

</details>

<details class="qa">
<summary>Seven of eight VLANs cross a link between two switches and one does not. The link is up. Where do you look?</summary>

The allowed VLAN list on the trunk, at both ends.

A fault that picks one VLAN out of eight cannot be physical, because a cable or
an optic does not distinguish between VLANs. The link being up rules out most of
the rest.

A VLAN present on one end's allowed list and missing from the other's is sent by
one switch and dropped by the other, which is exactly this symptom. The usual
cause is somebody adding the VLAN to the switch they were logged into and not the
far end.

Compare both configurations rather than verifying one, because each looks correct
on its own.

</details>

<details class="qa">
<summary>Why does an access port ignore a tag sent by the device plugged into it, and why does a trunk not?</summary>

Because they answer the question of VLAN membership differently.

An access port belongs to one VLAN, and membership is decided by the port. The
switch stamps arriving frames with the port's PVID and does not consider anything
the device claims, which is what makes VLAN separation something a host cannot opt
out of.

A trunk carries several VLANs and has no other way to tell them apart, so the tag
is the only information available and it has to be believed.

That is why user-facing ports are configured as access ports explicitly, and why
a port that can negotiate itself into a trunk is a hole.

</details>

<details class="qa">
<summary>In a double tagging attack, why does the first switch strip only one tag?</summary>

Because the outer tag names the native VLAN, and native VLAN traffic travels
untagged on a trunk.

The switch reads the outer tag, recognises it as the native VLAN, removes it, and
forwards the frame. The inner tag was never examined and is still attached, so
the next switch reads it as an ordinary tag and delivers the frame into the VLAN
the attacker chose.

It only works in one direction, since replies are forwarded normally and do not
come back through the same trick, and it depends entirely on the native VLAN
matching what the attacker guessed.

</details>

<details class="qa">
<summary>Does adding a VLAN tag reduce the amount of data a frame can carry?</summary>

On modern equipment, no. The maximum frame size grows by four bytes to accommodate
the tag, so the payload stays at 1500 and nothing on any host has to change.

On older equipment that could not accept the larger frame it did, and a
full-sized tagged frame would be dropped or fragmented.

Where it becomes a live problem again is stacking. A second tag, or a tunnel on
top, takes bytes out of the same budget, and the symptom is the one topic 20
covers: small packets work and large ones disappear with nothing logged.

</details>

## References

- [IEEE 802.1Q, Bridges and Bridged Networks](https://standards.ieee.org/ieee/802.1Q/10323/) - IEEE Standards Association, which defines the tag, the native VLAN and provider bridging. The scope is readable without purchase. Accessed 2026-08-10.
- [IEEE 802.3 Standard for Ethernet](https://standards.ieee.org/ieee/802.3/10422/) - IEEE Standards Association, for the frame format the tag is inserted into. Accessed 2026-08-10.
- [tcpdump(1)](https://www.tcpdump.org/manpages/tcpdump.1.html) - tcpdump.org, on the `-e` flag that makes the tag visible. Accessed 2026-08-10.

**Where the output came from.** The captured block was produced on
`blog/scripts/topologies/vlan-switch.sh` through `blog/scripts/netlab.sh`, with
two captures running at once so the same frame is shown at two points on its
path. The four byte difference between them is the kernel adding and removing a
real tag rather than an illustration of one.

**If you also work on Linux.** Tagged interfaces are how a Linux host attaches to
several VLANs over one physical link, which is the same subinterface idea topic
26 covers for routers. The Linux+ track does not cover it, because its exam does
not ask.
