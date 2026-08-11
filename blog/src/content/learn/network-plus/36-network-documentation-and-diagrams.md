---
title: "Network documentation and diagrams"
description: "The person who built it left in 2019. Physical against logical drawings, why layer 2 is the diagram nobody has, what an asset inventory needs beyond a list of boxes, and what makes documentation survive contact with change."
deck: "The person who built it left in 2019"
track: "network-plus"
level: "working"
order: 370
objectives:
  - "Distinguish physical, layer 2 and layer 3 diagrams and say what each answers"
  - "Say what an asset inventory needs beyond a list of hardware"
  - "Explain what IP address management is for"
  - "Read a service level agreement as a set of numbers rather than a promise"
  - "Say what makes documentation survive change"
prerequisites: ["vlans"]
tags: ["network-plus", "networking", "operations", "documentation"]
updated: 2026-08-11
draft: false
examObjectives:
  - exam: "n10-009"
    domain: "3.0"
    objective: "3.1"
sources:
  - title: "RFC 2350, Expectations for Computer Security Incident Response"
    url: "https://www.rfc-editor.org/rfc/rfc2350"
    publisher: "IETF"
    accessed: 2026-08-11
    tier: 1
  - title: "NIST SP 800-53 Rev. 5, Security and Privacy Controls"
    url: "https://csrc.nist.gov/pubs/sp/800/53/r5/upd1/final"
    publisher: "NIST"
    accessed: 2026-08-11
    tier: 1
  - title: "IEEE 802.1Q, Bridges and Bridged Networks"
    url: "https://standards.ieee.org/ieee/802.1Q/10323/"
    publisher: "IEEE Standards Association"
    accessed: 2026-08-11
    tier: 1
symptoms:
  - symptom: "A change breaks something nobody knew was connected"
    anchor: "three-drawings-of-one-site"
  - symptom: "Nobody can say which VLAN a port is in without logging in to check"
    anchor: "three-drawings-of-one-site"
---

> **Before you read.** You inherit a network. There is a diagram on the wall, it
> is beautifully drawn, and it is from 2019. There is a spreadsheet of equipment
> that lists forty devices, of which about thirty still exist.
>
> A change is scheduled for Tuesday.
>
> **What do you actually have, and what is missing?**

Documentation is the topic everybody agrees about and nobody funds. The useful
version of it is narrower than the aspiration: not a complete description of the
network, which is never current, but a small number of things that are worth
keeping accurate because a change goes wrong without them.

### Some words you will need

<dl class="terms">
<dt>physical diagram</dt>
<dd>What is plugged into what. Racks, ports, cables, labels.</dd>
<dt>logical diagram</dt>
<dd>How traffic flows. Which is a different drawing, and usually two of them.</dd>
<dt>asset inventory</dt>
<dd>What you own, where it is, and what state it is in.</dd>
<dt>IPAM</dt>
<dd>IP address management. The record of which addresses and subnets are in use and by what.</dd>
<dt>service level agreement</dt>
<dd>A contract stating numbers: availability, response time, and what happens when they are missed.</dd>
<dt>heat map</dt>
<dd>A drawing of measured wireless coverage over a floor plan.</dd>
</dl>

## What breaks without this

**Every change is exploratory.** Without a current picture, a Tuesday change
begins with an hour of finding out, and the finding out is done on a live
network.

**Faults take longer than they should.** Topic 21 and topic 16 both produce
symptoms that are trivial to diagnose with the right drawing and slow without one.

**Nobody can answer what else uses this.** Which is the question that decides
whether a change is safe, and the one an out of date diagram answers confidently
and wrongly.

## Three drawings of one site

Physical and logical is the distinction the exam draws, and it is too coarse,
because logical is two different drawings that answer different questions.

<figure class="learn-figure">
<svg viewBox="0 0 720 264" role="img" aria-labelledby="docs-title" style="width:100%;height:auto;">
<title id="docs-title">The same site drawn as a physical diagram of cables, a layer two diagram of VLANs and a layer three diagram of subnets, none of which substitutes for the others</title>
<g fill="currentColor">
<text x="14" y="20" font-size="11">one site, three drawings, and no two of them answer the same question</text>
<rect x="14" y="40" width="220" height="140" rx="4" fill="currentColor" fill-opacity="0.04" stroke="currentColor" stroke-opacity="0.45"/>
<text x="28" y="64" font-size="11.5">physical</text>
<text x="28" y="86" font-size="10" fill-opacity="0.75">answers</text>
<text x="28" y="102" font-size="10.5">what is plugged into what</text>
<text x="28" y="128" font-size="10" fill-opacity="0.75">a line on it means</text>
<text x="28" y="144" font-size="10.5">a cable, a port, a label</text>
<text x="28" y="168" font-size="9.5" fill-opacity="0.7">rack 3 port 12 to rack 1 port 4</text>
<rect x="250" y="40" width="220" height="140" rx="4" fill="currentColor" fill-opacity="0.04" stroke="currentColor" stroke-opacity="0.45"/>
<text x="264" y="64" font-size="11.5">layer 2</text>
<text x="264" y="86" font-size="10" fill-opacity="0.75">answers</text>
<text x="264" y="102" font-size="10.5">which VLANs are where</text>
<text x="264" y="128" font-size="10" fill-opacity="0.75">a line on it means</text>
<text x="264" y="144" font-size="10.5">a broadcast domain</text>
<text x="264" y="168" font-size="9.5" fill-opacity="0.7">VLAN 20 spans sw1 and sw2</text>
<rect x="486" y="40" width="220" height="140" rx="4" fill="currentColor" fill-opacity="0.04" stroke="currentColor" stroke-opacity="0.45"/>
<text x="500" y="64" font-size="11.5">layer 3</text>
<text x="500" y="86" font-size="10" fill-opacity="0.75">answers</text>
<text x="500" y="102" font-size="10.5">which subnets exist</text>
<text x="500" y="128" font-size="10" fill-opacity="0.75">a line on it means</text>
<text x="500" y="144" font-size="10.5">a routing boundary</text>
<text x="500" y="168" font-size="9.5" fill-opacity="0.7">10.0.20.0/24 gatewayed on r1</text>
<text x="14" y="212" font-size="10.5">the middle one is the drawing almost nobody has, and it is the one a switching fault needs.</text>
<text x="14" y="228" font-size="10.5" fill-opacity="0.85">a physical diagram cannot show a VLAN, because a VLAN has no cable to draw.</text>
<text x="14" y="252" font-size="10.5">so the honest question about any diagram is not is it current, it is which of the three is it.</text>
</g></svg>
<figcaption>Three drawings of the same building. Each answers a question the other two cannot, which is why having one of them does not mean the site is documented. The middle one is the interesting case: almost nobody has it, and it is the one a switching fault needs, because a VLAN has no cable and therefore cannot appear on a physical drawing at all. When somebody says the network is documented, the useful question is which of these three they mean.</figcaption>
</figure>

**The physical diagram** answers what is plugged into what. It is the one people
draw, because it is the one you can produce by walking around with a torch.

**The layer 2 diagram** answers which VLANs exist and where they reach. It cannot
be produced by looking at anything, only by reading configuration, which is why it
is the one nobody has.

**The layer 3 diagram** answers which subnets exist and where the routing
boundaries are. It is the one that survives longest, because addressing changes
less often than cabling.

The practical consequence is that a change affecting a VLAN cannot be assessed
from the drawing on the wall. That is not a criticism of the drawing. It is a
statement about what a physical drawing is capable of containing.

## Inventory, and the fields people leave out

An asset inventory that lists hardware is a start and it will not answer the
questions asked of it. Four things belong alongside the device.

**Software and firmware version**, because half of the questions asked of an
inventory are which of these is affected by this advisory.

**Licensing**, because features stop working when a licence lapses and the failure
looks like a fault.

**Warranty and support status**, which is the next topic's subject and is the
field most often absent.

**What it is for**, in a sentence. The single most valuable field in any inventory
is the one that says what breaks if this is switched off, and it is the one no
tool populates automatically.

**IP address management** is the same idea for addresses: which subnets exist,
which are in use, what lives at which address. Its value is not tidiness. It is
that allocating a subnet without it means somebody eventually allocates it twice,
and topic 24's planning becomes guesswork three years later.

## Reading a service level agreement

An SLA is not a promise that things will work. It is a set of numbers and a
statement of what happens when they are not met, and reading it as the first thing
leads to unpleasant surprises.

Three numbers matter. **Availability**, usually as a percentage, and worth
converting into minutes before agreeing to it, because 99.9 percent is about
forty-three minutes a month and 99.99 is about four. **Response time**, which is
how quickly somebody will begin, and is frequently confused with resolution time,
which is a different number and often absent. And **the remedy**, which is what
you get when they miss, and is usually a service credit rather than compensation
for what the outage cost you.

The habit worth having is to read the remedy first. It tells you what the
agreement is actually worth, and it is the section nobody reads.

## Surveys and heat maps

A wireless survey measures coverage and produces a heat map over a floor plan.
Topics 29 and 30 explain why it exists: coverage cannot be calculated reliably
from a drawing, because walls, metal and reflections do things no model predicts
exactly, so somebody walks the building with an instrument.

Two kinds are worth telling apart. A predictive survey is modelled before anything
is installed, and it is a plan. A validation survey is measured afterwards, and it
is evidence. Buying the first and calling it the second is a common shortcut.

## What makes documentation survive

The reason documentation rots is not laziness. It is that keeping it current is
work that competes with everything else, and it loses.

Three things help, and they are all about reducing the work rather than
increasing the discipline.

**Document what changes slowly.** Addressing, VLAN numbering, the site layout, and
what each thing is for. Port-level detail rots in a week and is better read from
the device.

**Generate what can be generated.** A diagram produced from configuration is
current by construction. A drawing maintained by hand is current for as long as
somebody remembers.

**Put the documentation where the change happens.** A change process that requires
a diagram update in order to close the ticket produces current diagrams. A wiki
that people are asked to remember does not.

## Prove it

Nothing here is captured. Documentation is a practice, and a transcript of a
diagram would be a screenshot of somebody else's work.

**NIST SP 800-53.** Free. Find the configuration management family and read the
control on baseline configuration. Answer one question: does it treat the
documented baseline as a description of what exists, or as the thing changes are
measured against? The answer is the argument for keeping it current.

**Then audit one diagram.** Take whatever drawing you have and pick three things
on it at random. Check each against the live network. Three checks take ten
minutes and give you a defensible statement about how much of the rest to trust.

**And write the one sentence.** Pick any device you are responsible for and write
down what breaks if it is switched off. If that sentence is hard to write, you
have found something more interesting than a documentation gap.

## What trips people up

### 1. Treating physical and logical as two drawings

Logical is two: a layer 2 view and a layer 3 view, answering different questions.
The layer 2 one is the one nobody has and the one switching faults need.

### 2. Expecting a physical diagram to show VLANs

It cannot. A VLAN has no cable, so there is nothing on a physical drawing for it
to be.

### 3. An inventory of hardware only

Version, licensing, support status and purpose are what the inventory is asked
about. A list of model numbers answers none of those questions.

### 4. Reading an SLA percentage without converting it

Convert to minutes per month before agreeing. The difference between 99.9 and
99.99 is the difference between three quarters of an hour and four minutes.

### 5. Confusing response time with resolution time

Response is when somebody starts. Resolution is when it works again. Many
agreements commit to the first and say nothing about the second.

### 6. Calling a predictive survey a validation

One is modelled before installation and is a plan. The other is measured
afterwards and is evidence.

## Work it through

The 2019 diagram and the Tuesday change.

Start by working out what kind of drawing it is, because that determines what it
can be wrong about. If it is physical, it can be wrong about cabling and it was
never able to tell you about VLANs, so a VLAN change gets nothing from it either
way.

Then establish what the change actually touches, in the terms the change is
expressed in. If it is a VLAN change, you need the layer 2 view, and if that does
not exist then the honest answer is that it has to be read from the devices before
Tuesday. That reading is the work, and it should be scheduled rather than
discovered on the night.

Then spot-check rather than verify everything. Pick three items on the drawing and
check them. If all three are right, the drawing is probably usable with care. If
one is wrong, treat the whole thing as a sketch. That check costs ten minutes and
it is the difference between trusting a document and assuming one.

Then the inventory, which is a different problem: forty listed, thirty existing.
The ten that do not exist are noise and are easy to remove. The dangerous number is
the one nobody has counted, which is the devices that exist and are not listed.
Those are the ones with no owner, no support status and no patching, and finding
them needs a scan rather than a spreadsheet.

And capture what you learn on Tuesday while you are in there. The change will
teach you several facts about the network that nobody wrote down. Writing them
down as you go costs minutes and is the only way documentation ever improves,
because there is never a project to fix it.

## Try it

**Check three things on your diagram.** Ten minutes, and it tells you how much of
the rest to believe.

**Convert your SLA percentage to minutes.** Then decide whether the number you
agreed to is the one you thought.

**Write down what breaks if one device is switched off.** If you cannot, that is
the finding.

## Check yourself

<details class="qa">
<summary>Why is a physical diagram unable to help with a VLAN problem?</summary>

Because a VLAN has no cable. A physical diagram records what is plugged into
what, and VLAN membership is configuration on a port rather than anything you can
see or trace.

That is a limit of the drawing rather than a fault in it. The drawing that answers
VLAN questions is a layer 2 diagram, which cannot be produced by walking around
and has to be read out of configuration, which is why it is the one most
organisations do not have.

</details>

<details class="qa">
<summary>What belongs in an asset inventory besides the hardware?</summary>

Software and firmware version, because most questions asked of an inventory are
about which devices an advisory affects. Licensing, because features stop when a
licence lapses and it looks like a fault. Support status, because that decides
whether a fix exists at all.

And what the thing is for, in one sentence. That last field is the most valuable
and the only one no tool can populate, because it records what breaks if the
device is switched off.

</details>

<details class="qa">
<summary>An SLA promises 99.9 percent availability. What have you actually agreed to?</summary>

About forty-three minutes of downtime a month, and whatever remedy the agreement
specifies when that is exceeded.

Converting the percentage into minutes is the step that makes it real. Reading the
remedy is the step that tells you what the agreement is worth, and it is usually a
service credit rather than compensation for the cost of the outage.

Also worth checking whether the response time committed is response or resolution.
Many agreements promise the first and say nothing about the second.

</details>

<details class="qa">
<summary>Why does documentation rot, and what actually helps?</summary>

Because keeping it current competes with other work and loses. Discipline is not
the lever.

Reducing the work is. Document what changes slowly, such as addressing, VLAN
numbering and what each thing is for, and read port-level detail from the device
rather than recording it. Generate what can be generated, because a diagram
produced from configuration is current by construction. And put the update inside
the change process, so a ticket cannot close without it.

</details>

<details class="qa">
<summary>What is the difference between a predictive survey and a validation survey?</summary>

A predictive survey is modelled from a floor plan before anything is installed. It
is a plan and it is useful for deciding where access points go.

A validation survey is measured by walking the building afterwards with an
instrument. It is evidence, and it is the only one that accounts for the walls,
metal and reflections that topics 29 and 30 describe.

Presenting the first as if it were the second is a common shortcut and the reason
coverage sometimes disagrees with the drawing.

</details>

## References

- [NIST SP 800-53 Rev. 5](https://csrc.nist.gov/pubs/sp/800/53/r5/upd1/final) - NIST, whose configuration management family covers baseline configuration and why it is maintained. Free. Accessed 2026-08-11.
- [RFC 2350](https://www.rfc-editor.org/rfc/rfc2350) - IETF, on what an organisation should be able to state about itself, which is a documentation requirement in a different vocabulary. Free. Accessed 2026-08-11.
- [IEEE 802.1Q](https://standards.ieee.org/ieee/802.1Q/10323/) - IEEE Standards Association, for the VLAN behaviour the layer 2 diagram records. Accessed 2026-08-11.

**Where the numbers came from.** The availability conversions are arithmetic:
99.9 percent of a thirty day month leaves roughly forty-three minutes and 99.99
leaves roughly four. The forty and thirty devices are the scenario's numbers.
Nothing is captured, because documentation is a practice rather than an output a
command produces.

**If you also work on Linux.** There is no counterpart topic in that track,
because this is a practice rather than a subsystem. The nearest habit is the one
this page ends on: record what a machine is for, in the machine, where the next
person will look for it.
