---
title: "Disaster recovery"
description: "Two objectives measured from the same moment in opposite directions, three kinds of standby site that differ only in what is already switched on, and the failover step nobody has ever run with users on it."
deck: "The building has no power and the business needs to keep trading"
track: "network-plus"
level: "working"
order: 420
objectives:
  - "Distinguish recovery point objective from recovery time objective"
  - "Say which of the two is a data decision and which is a money decision"
  - "Compare cold, warm and hot sites by what each one already has running"
  - "Explain what active-active buys that active-passive does not"
  - "Say what a tabletop exercise finds that a validation test does not"
prerequisites: ["lifecycle-change-and-configuration-management"]
tags: ["network-plus", "networking", "operations"]
updated: 2026-08-12
draft: false
examObjectives:
  - exam: "n10-009"
    domain: "3.0"
    objective: "3.3"
sources:
  - title: "NIST SP 800-34 Rev. 1, Contingency Planning Guide for Federal Information Systems"
    url: "https://csrc.nist.gov/pubs/sp/800/34/r1/upd1/final"
    publisher: "NIST"
    accessed: 2026-08-12
    tier: 1
  - title: "NIST SP 800-84, Guide to Test, Training, and Exercise Programs for IT Plans and Capabilities"
    url: "https://csrc.nist.gov/pubs/sp/800/84/final"
    publisher: "NIST"
    accessed: 2026-08-12
    tier: 1
  - title: "ISO 22301, Security and resilience, business continuity management systems"
    url: "https://www.iso.org/standard/75106.html"
    publisher: "ISO"
    accessed: 2026-08-12
    tier: 2
symptoms:
  - symptom: "Nobody can say how much work would be lost"
    anchor: "two-numbers-measured-in-opposite-directions"
  - symptom: "A standby site exists and nobody has ever served from it"
    anchor: "the-step-nobody-has-taken"
  - symptom: "The recovery plan names people who left"
    anchor: "testing-the-plan-rather-than-the-hardware"
---

> **Before you read.** A substation fault takes out power to an office at
> 09:40 on a Tuesday. The generator starts. Forty minutes later it stops, because
> the fuel contract lapsed in 2023.
>
> The finance system was last backed up at 02:00. Nobody knows how long it takes
> to bring it up somewhere else, because nobody has done it.
>
> **How much work has been lost, and how long will the business be down? Notice
> that those are two separate questions with two separate answers.**

This topic is about two numbers and what they cost. It reads as management
vocabulary and it is not: both numbers are decisions somebody in this job makes,
usually by default, usually without anybody noticing a decision was made.

### Some words you will need

<dl class="terms">
<dt>RPO</dt>
<dd>Recovery point objective. How far back the last usable copy of the data may be.</dd>
<dt>RTO</dt>
<dd>Recovery time objective. How long the service may be unavailable.</dd>
<dt>MTBF</dt>
<dd>Mean time between failures. How long a thing runs before it breaks.</dd>
<dt>MTTR</dt>
<dd>Mean time to repair. How long it takes to fix once it has.</dd>
<dt>failover</dt>
<dd>Moving service from the thing that broke to the thing that did not.</dd>
<dt>tabletop exercise</dt>
<dd>Walking through the plan in a room, without touching anything.</dd>
</dl>

## What breaks without this

**Work disappears and nobody expected it to.** Everything since the last backup
is gone, and the number of hours that represents was never agreed with anybody.

**A standby site turns out not to work.** It was bought, it was paid for monthly,
and the first time anybody tried to serve from it was during the incident.

**The recovery takes as long as it takes.** Which is a fine answer until somebody
asks why the shop was shut for two days.

## Two numbers measured in opposite directions

These two get taught as a pair and confused constantly, and the confusion is easy
to remove by noticing that they point in different directions from the same
moment.

<figure class="learn-figure">
<svg viewBox="0 0 720 248" role="img" aria-labelledby="rporto-title" style="width:100%;height:auto;">
<title id="rporto-title">A timeline with the incident in the middle, the recovery point objective measured backwards to the last good backup, and the recovery time objective measured forwards to service restored</title>
<g fill="currentColor">
<text x="14" y="22" font-size="11">both are measured from the same moment, in opposite directions</text>
<line x1="40" y1="148" x2="690" y2="148" stroke="currentColor" stroke-opacity="0.45" stroke-width="1.4"/>
<line x1="366" y1="70" x2="366" y2="166" stroke="var(--red)" stroke-width="2.2"/>
<text x="366" y="62" text-anchor="middle" font-size="11" fill="var(--red)">the incident</text>
<line x1="152" y1="134" x2="152" y2="162" stroke="currentColor" stroke-opacity="0.7" stroke-width="1.6"/>
<text x="152" y="126" text-anchor="middle" font-size="10.5">last good backup</text>
<line x1="596" y1="134" x2="596" y2="162" stroke="currentColor" stroke-opacity="0.7" stroke-width="1.6"/>
<text x="596" y="126" text-anchor="middle" font-size="10.5">service restored</text>
<rect x="152" y="170" width="214" height="22" rx="2" fill="var(--accent)" fill-opacity="0.18" stroke="var(--accent)" stroke-opacity="0.9" stroke-width="1.6"/>
<text x="259" y="185" text-anchor="middle" font-size="10.5" fill="var(--accent)">RPO</text>
<rect x="366" y="170" width="230" height="22" rx="2" fill="currentColor" fill-opacity="0.12" stroke="currentColor" stroke-opacity="0.7" stroke-width="1.6"/>
<text x="481" y="185" text-anchor="middle" font-size="10.5">RTO</text>
<text x="358" y="214" text-anchor="end" font-size="10" fill="var(--accent)">work done since, and lost</text>
<text x="358" y="230" text-anchor="end" font-size="10" fill-opacity="0.8">bought by saving more often</text>
<text x="374" y="214" font-size="10">time the business is not trading</text>
<text x="374" y="230" font-size="10" fill-opacity="0.8">bought by keeping somewhere else switched on</text>
<path d="M 156 148 l 10 -5 l 0 10 z" fill="currentColor" fill-opacity="0.6"/>
<path d="M 592 148 l -10 -5 l 0 10 z" fill="currentColor" fill-opacity="0.6"/>
<text x="40" y="140" font-size="10" fill-opacity="0.7">earlier</text>
<text x="690" y="140" text-anchor="end" font-size="10" fill-opacity="0.7">later</text>
</g></svg>
<figcaption>Why the two get confused and how to stop. Both start at the incident, and one looks backwards while the other looks forwards, so they are answers to different questions and are bought from different budgets. The recovery point objective is a statement about data: everything between the last good copy and the failure is work that happened and was never written down anywhere that survived. Shortening it means copying more often, and at the short end it means continuous replication. The recovery time objective is a statement about money: it is how long the business is not trading, and shortening it means paying to keep capacity somewhere else that is doing nothing most of the time. Neither number has a right answer, and the failure mode is not choosing a bad one. It is never choosing at all and finding out what they were during the incident.</figcaption>
</figure>

The scenario at the top has an RPO of seven hours and forty minutes, because the
last backup was at 02:00 and the failure was at 09:40. Nobody chose that. It is
the consequence of a backup schedule somebody set years ago, and it is the answer
to "how much work has been lost" whether or not anybody has ever said it out loud.

The RTO is unknown, which is worse than a bad number. An organisation that says
"four hours" and misses it by two has a problem. One that has no figure at all
cannot tell whether the recovery is going well.

**A useful way to keep them apart.** RPO is a decision about data, and its unit is
work. RTO is a decision about money, and its unit is trading. Whenever you cannot
remember which is which, ask whether the sentence is about what was lost or about
how long it took.

<details class="deeper">
<summary>If you already set these: why the numbers are a business decision that keeps arriving as a technical one</summary>

Both figures are frequently produced by whoever runs the infrastructure, and both are
properly decisions for whoever carries the loss.

Asked directly, a business will say it can tolerate no data loss and no downtime,
because the question sounds free. It stops being free when the arrangements are costed:
near-zero data loss means synchronous replication and the write latency that comes with
it, and near-zero downtime means running the second site hot. Presenting the number
alongside its price turns an aspiration into a choice, and the number that comes back is
usually far more relaxed than the first answer.

The second thing that gets skipped is that the figures differ by system. One recovery
objective for the whole estate is either unaffordable, because it is set by the most
critical thing, or inadequate, because it is set by the average. Tiering is the
practical answer: a handful of systems with tight numbers, most with relaxed ones, and
the tier recorded in the inventory alongside what each system is for.

Which is where this connects back to topic 36. A recovery plan needs to know what breaks
if a given system is gone, and that is the inventory field automatic discovery cannot
fill. Organisations that cannot tier their recovery objectives are usually not short of
recovery expertise. They are short of anybody who can say what the systems do.

</details>

## Two more numbers, about the equipment rather than the plan

**MTBF is how long a thing runs before it breaks.** It comes from the
manufacturer, it is a statistical figure across a population rather than a
promise about your unit, and it feeds into how much redundancy you buy.

**MTTR is how long it takes to fix once it has broken.** This one is yours rather
than the manufacturer's, and it is the number people under-estimate, because it
includes noticing, finding the spare, getting somebody to site, and the part
where the replacement needs a firmware version you do not have.

The relationship worth carrying: **MTTR is part of RTO.** If you have promised a
four hour recovery time and your mean time to repair a failed switch is six hours
because the spare is in another building, you have not promised anything.

<details class="deeper">
<summary>If you already quote these: what the manufacturer's figure does and does not promise</summary>

The reliability figure is the one most often misread, and the misreading is
understandable because the number is enormous.

A quoted mean time between failures of several hundred thousand hours does not mean a
unit is expected to last that long. It is derived from a population: run a large number
of units for a short period, count the failures, and extrapolate. It describes the
failure rate during the flat part of the life curve, after early failures and before
wear-out, and it says nothing about either end of that curve.

Which is why it is useful for one thing and useless for another. Useful: estimating how
many failures a fleet of two hundred identical devices will produce in a year, which is
a stocking and staffing question with a real answer. Useless: predicting whether the
specific switch in that rack will fail this year, which the figure was never about.

The repair figure is more actionable and is the one people underestimate, because they
time the repair rather than the outage. The clock starts when the thing broke, not when
somebody noticed, and it includes detection, diagnosis, finding a spare, getting somebody
to the site, and verifying afterwards. A four hour hardware contract does not deliver a
four hour recovery, and the gap between those two numbers is where availability
calculations quietly become fiction.

</details>

## What is already switched on

The three kinds of standby site are usually taught as a list of definitions.
They are better understood as one question asked three times.

<figure class="learn-figure">
<svg viewBox="0 0 720 258" role="img" aria-labelledby="sites-title" style="width:100%;height:auto;">
<title id="sites-title">Cold, warm and hot standby sites shown by what each one already has running, against how long it takes to be serving from them</title>
<g fill="currentColor">
<text x="14" y="22" font-size="11">what is already switched on, which is the same question as how fast</text>
<text x="14" y="78" font-size="10" fill-opacity="0.75">power and space</text>
<text x="14" y="108" font-size="10" fill-opacity="0.75">hardware racked</text>
<text x="14" y="138" font-size="10" fill-opacity="0.75">software installed</text>
<text x="14" y="168" font-size="10" fill-opacity="0.75">data current</text>
<text x="14" y="198" font-size="10" fill-opacity="0.75">traffic on it</text>
<text x="215" y="52" text-anchor="middle" font-size="10.5">cold</text>
<rect x="140" y="63" width="150" height="22" rx="2" fill="currentColor" fill-opacity="0.35" stroke="currentColor" stroke-opacity="0.6"/>
<rect x="140" y="93" width="150" height="22" rx="2" fill="none" stroke="currentColor" stroke-opacity="0.35" stroke-dasharray="4 4"/>
<rect x="140" y="123" width="150" height="22" rx="2" fill="none" stroke="currentColor" stroke-opacity="0.35" stroke-dasharray="4 4"/>
<rect x="140" y="153" width="150" height="22" rx="2" fill="none" stroke="currentColor" stroke-opacity="0.35" stroke-dasharray="4 4"/>
<rect x="140" y="183" width="150" height="22" rx="2" fill="none" stroke="currentColor" stroke-opacity="0.35" stroke-dasharray="4 4"/>
<text x="215" y="240" text-anchor="middle" font-size="11">weeks</text>
<text x="405" y="52" text-anchor="middle" font-size="10.5">warm</text>
<rect x="330" y="63" width="150" height="22" rx="2" fill="currentColor" fill-opacity="0.35" stroke="currentColor" stroke-opacity="0.6"/>
<rect x="330" y="93" width="150" height="22" rx="2" fill="currentColor" fill-opacity="0.35" stroke="currentColor" stroke-opacity="0.6"/>
<rect x="330" y="123" width="150" height="22" rx="2" fill="currentColor" fill-opacity="0.35" stroke="currentColor" stroke-opacity="0.6"/>
<rect x="330" y="153" width="150" height="22" rx="2" fill="none" stroke="currentColor" stroke-opacity="0.35" stroke-dasharray="4 4"/>
<rect x="330" y="183" width="150" height="22" rx="2" fill="none" stroke="currentColor" stroke-opacity="0.35" stroke-dasharray="4 4"/>
<text x="405" y="240" text-anchor="middle" font-size="11">hours</text>
<text x="595" y="52" text-anchor="middle" font-size="10.5">hot</text>
<rect x="520" y="63" width="150" height="22" rx="2" fill="currentColor" fill-opacity="0.35" stroke="currentColor" stroke-opacity="0.6"/>
<rect x="520" y="93" width="150" height="22" rx="2" fill="currentColor" fill-opacity="0.35" stroke="currentColor" stroke-opacity="0.6"/>
<rect x="520" y="123" width="150" height="22" rx="2" fill="currentColor" fill-opacity="0.35" stroke="currentColor" stroke-opacity="0.6"/>
<rect x="520" y="153" width="150" height="22" rx="2" fill="currentColor" fill-opacity="0.35" stroke="currentColor" stroke-opacity="0.6"/>
<rect x="520" y="183" width="150" height="22" rx="2" fill="currentColor" fill-opacity="0.35" stroke="currentColor" stroke-opacity="0.6"/>
<text x="595" y="240" text-anchor="middle" font-size="11">minutes</text>
<text x="14" y="240" font-size="10" fill-opacity="0.7">to be serving</text>
</g></svg>
<figcaption>The three site types are not three products, they are one slider with three names on it. Every row that is already true at the moment of the disaster is a row you do not have to do during it, and the recovery time is the time to do the rest. That makes the cost obvious as well: the shaded rows are also the invoice, because keeping hardware racked, patched and holding current data costs money every month whether or not anything ever fails. Note the row that separates warm from hot. Everything above it is equipment, which somebody can buy in an afternoon; the data row is the one that needs a continuous connection and continuous attention, and it is the one that decides both the recovery time and the recovery point.</figcaption>
</figure>

**Cold** is space, power and a contract. Nothing is racked. Recovering means
buying or moving hardware, installing everything and restoring from backup, and
the honest unit is weeks.

**Warm** has the hardware and the software and does not have current data.
Recovery is a restore and a cutover, and the honest unit is hours.

**Hot** is running now, with data kept current, and can take traffic. Minutes,
and in some designs no interruption at all.

**The middle one is where most organisations actually are**, and where most of
the surprises live, because "we have a warm site" describes a wide range of
readiness. The useful question is not which word applies. It is which of those
rows is true today, and how anybody would know.

<figure class="learn-figure photo">

![An aerial view at dusk of two long rows of standby generators outside a data centre. Each generator sits in its own white weatherproof enclosure with an exhaust stack and a railed walkway on the roof, and the units are lined up end to end down both sides of a service road. Between and behind them stand fuel tanks and electrical switchgear cabinets, and the windowless wall of the data hall runs down the right of the frame.](./images/standby-generators.jpg)

<figcaption>Standby generation at a data centre, and the useful thing about the picture is the count. A building that needs this much of it does not have one generator with a spare; it has a set sized to carry the whole load with units to spare while some are being serviced, plus the fuel to run them and the switchgear to transfer the load without the machines inside noticing. That is what buying a short recovery time looks like in physical form, and it is also the reason the answer to "do we have a generator" is never the interesting question. The interesting questions are how long the fuel lasts, who is contracted to bring more, and when the transfer was last tested under load. Photograph by Rsparks3, released under <a href="https://creativecommons.org/publicdomain/zero/1.0/">CC0</a>.</figcaption>
</figure>

## The step nobody has taken

Once a second site exists, there is a further choice, and it is the one that
decides whether the site works when you need it.

<figure class="learn-figure">
<svg viewBox="0 0 720 282" role="img" aria-labelledby="active-title" style="width:100%;height:auto;">
<title id="active-title">Active-passive with all traffic on one site and a failover step that has never run, against active-active with traffic split across both sites at all times</title>
<g fill="currentColor">
<text x="14" y="22" font-size="11">the difference is whether the second site is being used, not whether it exists</text>
<text x="14" y="56" font-size="10.5" fill-opacity="0.85">active-passive</text>
<text x="30" y="94" font-size="10.5">users</text>
<line x1="88" y1="90" x2="240" y2="90" stroke="currentColor" stroke-opacity="0.7" stroke-width="2.4"/>
<path d="M 246 90 l -8 -5 l 0 10 z" fill="currentColor"/>
<rect x="250" y="69" width="120" height="42" rx="3" fill="currentColor" fill-opacity="0.22" stroke="currentColor" stroke-opacity="0.8"/>
<text x="310" y="95" text-anchor="middle" font-size="10.5">site a</text>
<rect x="470" y="69" width="120" height="42" rx="3" fill="currentColor" fill-opacity="0.06" stroke="currentColor" stroke-opacity="0.4" stroke-dasharray="5 3"/>
<text x="530" y="95" text-anchor="middle" font-size="10.5">site b</text>
<line x1="370" y1="90" x2="464" y2="90" stroke="var(--red)" stroke-width="1.6" stroke-dasharray="5 4"/>
<text x="417" y="82" text-anchor="middle" font-size="10" fill="var(--red)">failover</text>
<text x="600" y="94" font-size="10" fill-opacity="0.8">idle</text>
<text x="14" y="186" font-size="10.5" fill-opacity="0.85">active-active</text>
<text x="30" y="224" font-size="10.5">users</text>
<line x1="88" y1="220" x2="180" y2="220" stroke="currentColor" stroke-opacity="0.7" stroke-width="2.4"/>
<path d="M 180 220 L 240 200 M 180 220 L 240 240" fill="none" stroke="currentColor" stroke-opacity="0.7" stroke-width="2.4"/>
<path d="M 246 199 l -9 -3 l 2 10 z" fill="currentColor"/>
<path d="M 246 241 l -9 3 l 2 -10 z" fill="currentColor"/>
<rect x="250" y="178" width="120" height="42" rx="3" fill="currentColor" fill-opacity="0.22" stroke="currentColor" stroke-opacity="0.8"/>
<text x="310" y="204" text-anchor="middle" font-size="10.5">site a</text>
<rect x="250" y="226" width="120" height="42" rx="3" fill="currentColor" fill-opacity="0.22" stroke="currentColor" stroke-opacity="0.8"/>
<text x="310" y="252" text-anchor="middle" font-size="10.5">site b</text>
<text x="386" y="204" font-size="10" fill-opacity="0.8">both carrying users right now</text>
<text x="386" y="248" font-size="10" fill-opacity="0.8">no failover step to run</text>
</g></svg>
<figcaption>The dashed line in the top half is the whole argument. In active-passive, everything on the right of it is a procedure: a set of steps, written down at best, that has to run correctly under pressure at a moment nobody chose. It is the only part of the design that has never operated, which makes it the part most likely to fail, and the failures are dull rather than dramatic. A firewall rule that permits the primary and not the standby. A DNS record with a day-long time to live. A licence tied to a serial number. In active-active there is no equivalent step, because both sites are carrying users continuously and the configuration on each is being proved every minute of every day. The trade is not free: two live sites means the data has to be consistent across both while both are being written to, which is a genuinely hard problem and the reason active-passive still exists.</figcaption>
</figure>

**Active-passive** puts everything on one site and keeps the other ready. It is
simpler, it is cheaper, and it contains a failover.

**Active-active** runs both. Losing one is a capacity event rather than a
procedure, and the standby is being tested continuously because it is not a
standby.

**The reason this matters more than it sounds** is that a failover which has never
run is a plan rather than a capability, and the two are easy to confuse on a
diagram. Every organisation with an untested failover believes it has a second
site. Some of them do.

<details class="deeper">
<summary>If you already work on networks: what actually goes wrong during a failover, and why the network is usually the reason it took longer than the plan said</summary>

Recovery plans tend to be written by the people who run the applications, and
they tend to assume the network is a constant. It is not, and the same handful of
network problems turn up in incident reviews.

**Addresses.** If the standby site uses different addressing, then everything with
an address written into it has to change: firewall rules, application
configuration, allow lists at partners, monitoring, licences pinned to an
address. Stretching a subnet between sites avoids that and introduces a layer 2
failure domain spanning both, which is a decision with its own consequences and
should be made deliberately rather than discovered.

**Names.** The usual mechanism for moving traffic is DNS, which means the time to
live on the record is a hard floor under the recovery time. A record with a
twenty four hour TTL cannot move traffic in an hour, and lowering it during the
incident does not help, because the old value is already cached. Lowering it in
advance is free and is the single cheapest recovery time improvement available to
most organisations.

**Routing.** Anycast and dynamic routing move traffic faster than DNS and need the
addresses to be yours and the routing to be in place beforehand. This is the
mechanism behind most of the recoveries measured in seconds rather than hours.

**Capacity.** The standby link is frequently sized for replication rather than for
users, because that is all it has ever carried. Failing over then works perfectly
and the site is unusable, which reads as a failure of the standby site and is
arithmetic nobody did.

**The direction of the dependency.** Authentication, name resolution and time all
have to work before anything else does, and all three frequently live at the
primary site. A recovery plan that starts by restoring the application and
discovers halfway through that nothing can authenticate has the order wrong, and
the order is the part a tabletop exercise finds cheaply.

The pattern behind all five is the same. Each one is a thing that was true at the
primary site for so long that it stopped being visible, and none of them appear on
a diagram of the recovery design.

</details>

## Testing the plan rather than the hardware

The exam separates two kinds of exercise and the distinction is worth having,
because they find different faults.

**A tabletop exercise** is a discussion. The people who would run the recovery sit
in a room and walk through it, and nothing is touched. It is cheap, it can be run
in an afternoon, and what it finds is decisions and dependencies: who declares a
disaster, who authorises the failover, what order things come up in, and which
step nobody can explain.

**A validation test** actually does it. Failing over to the standby, running from
it, and failing back. It is expensive and disruptive, and what it finds is
reality: the firewall rule that was never created, the expired certificate, the
service that does not start because it looks for a licence server that is at the
other site.

Both are worth doing and they are not substitutes. A tabletop finds problems that
a technical test would never surface, because it exposes the gaps between people
rather than between systems. A validation test finds problems no discussion could,
because nobody knows they exist.

**And there is a third thing that is neither.** A plan that names a person who
left in 2022 has failed before the exercise starts. Contact details, escalation
paths and who has the authority to declare a disaster all go stale faster than the
technical content, and reviewing them costs an hour a year.

## Prove it

**Find your own RPO.** Not the one in a document. Look at when the last backup of
something important actually completed, and subtract that from now. That number
is your current recovery point objective whether or not anybody chose it.

**Then ask three people what the RTO is.** If you get three answers, that is the
finding. If you get three identical answers, ask what it is based on.

**Look up one TTL.** Find the DNS record that would have to change to move traffic
to a standby site and read its time to live. That number is a floor under the
recovery time and it is usually a surprise.

## What trips people up

### 1. Swapping the two objectives

RPO looks backwards from the incident and is about data lost. RTO looks forwards
and is about time down. Both start at the same moment.

### 2. Treating MTTR as somebody else's number

Mean time between failures comes from the manufacturer. Mean time to repair is
yours, it includes finding the spare and getting somebody to site, and it sits
inside the recovery time you have promised.

### 3. Calling a site hot because it exists

Hot means running now with current data and able to take traffic. A site with
hardware in it and a backup from last night is warm, and the difference is
measured in hours of recovery.

### 4. Believing an untested failover

The failover step is the only part of an active-passive design that has never
operated, which makes it the part most likely to fail.

### 5. Forgetting the network in the recovery plan

Addresses, DNS time to live, link capacity and the order that authentication and
name resolution come up in are all network decisions, and all four routinely turn
a planned recovery into a longer one.

### 6. Treating a tabletop and a validation test as the same exercise

One finds decisions and dependencies for the cost of an afternoon. The other finds
configuration that does not exist, and costs an outage. Neither substitutes.

## Work it through

The office with no power, a generator that ran out of fuel, and a backup from
02:00.

Start with the two numbers, because everything else follows from them and because
they are answerable immediately. The recovery point is seven hours and forty
minutes of work, and that is now a fact rather than a target. The recovery time is
unknown, and the first useful action is to stop treating it as unknown: pick
somebody to establish what bringing the finance system up elsewhere would actually
involve, and put a number on it, even a rough one, because you cannot manage an
outage against a blank.

**Then separate the incident from the finding.** The incident is that a building
has no power. The finding is that a fuel contract lapsed three years ago and
nothing noticed, which is a lifecycle failure of exactly the kind topic 37
described: a thing that stopped being true on a date and produced no symptom until
the day it mattered. The generator is not the only item in that category, and the
question worth asking afterwards is what else expired quietly.

For the immediate recovery, the order matters more than the speed. Authentication,
name resolution and time have to be available before the finance system is of any
use to anybody, and if those services are also in the dark building then restoring
the application first is wasted effort. That ordering is the single most common
thing a tabletop exercise finds, and this organisation has not had one.

**On the objectives themselves**, seven hours forty is either acceptable or it is
not, and that is a decision for whoever owns the finance system rather than for
the network team. What the network team owes them is the honest price list.
Halving the recovery point means backing up twice as often. Getting it under an
hour means something closer to continuous replication and a link sized to carry
it. Those cost money, and the conversation only works if somebody has already
established what a day of lost trading costs, which is the number that makes all
the others decidable.

Finally, the thing that will not appear in the incident report. Everybody in that
building assumed the generator meant the power problem was handled, and they were
right for as long as the fuel lasted. A control that works until a condition
changes, with nothing watching the condition, is a common shape, and it is worth
looking for the others before the next Tuesday.

## Try it

**Write down the recovery point and recovery time for one service.** Any service.
The exercise is not the writing, it is finding out that two people disagree.

**Walk one failover through on paper.** Twenty minutes, out loud, with somebody
who would be in the room. Note every step somebody has to guess at.

**Check a fuel or maintenance contract.** Any of the invisible dependencies. The
question is not whether it exists, it is when it expires and who would find out.

## Check yourself

<details class="qa">
<summary>A failure happens at 09:40 and the last backup completed at 02:00. Which objective does that describe, and what does the other one describe?</summary>

It describes the recovery point: seven hours and forty minutes of work exists only
in the failed system, so that is how much has been lost. Recovery point is
measured backwards from the incident and is a statement about data.

The recovery time is the other direction: how long from the failure until the
service is usable again. It is a statement about how long the business is not
trading, and it is bought by keeping capacity elsewhere rather than by backing up
more often.

</details>

<details class="qa">
<summary>What separates a warm site from a hot one, and why is that the expensive row?</summary>

Current data. Both have hardware racked and software installed; a hot site also
holds data that is up to date and can take traffic now.

It is the expensive row because everything above it is equipment somebody can buy
once, while keeping data current needs a continuous connection, continuous
capacity and continuous attention. It is also the row that decides both objectives
at once, because it sets the recovery point as well as most of the recovery time.

</details>

<details class="qa">
<summary>Why is an active-active pair usually more trustworthy than an active-passive pair with the same equipment?</summary>

Because there is no untested step in it. Both sites carry users continuously, so
the configuration on each is proved every day, and losing one becomes a capacity
problem rather than a procedure that has to run correctly under pressure.

In active-passive the failover is the only part of the design that has never
operated. Its failures are usually mundane: a firewall rule that permits one site
and not the other, a licence pinned to a serial number, a DNS record with a long
time to live.

</details>

<details class="qa">
<summary>A recovery plan targets a two hour recovery time and traffic is moved by changing a DNS record with a 24 hour time to live. What is wrong?</summary>

The time to live is a floor under the recovery time. Resolvers that have cached
the old answer will keep using it for up to a day, so the change cannot take
effect within two hours no matter how quickly the standby comes up.

Lowering the value during the incident does not help, because the cached copies
already carry the old figure. Lowering it in advance costs nothing and is one of
the cheapest recovery time improvements available.

</details>

<details class="qa">
<summary>What does a tabletop exercise find that a full validation test does not?</summary>

The gaps between people rather than between systems. Who declares a disaster, who
authorises the failover, what order services have to come up in, and which step
nobody present can explain.

It costs an afternoon and no outage, which is why it can be run often enough to
keep the answers current. A validation test finds a different class of problem,
the configuration that does not exist, and neither one substitutes for the other.

</details>

## References

- [NIST SP 800-34 Rev. 1](https://csrc.nist.gov/pubs/sp/800/34/r1/upd1/final) - NIST, the contingency planning guide, and the source of the recovery objective vocabulary. Free. Accessed 2026-08-12.
- [NIST SP 800-84](https://csrc.nist.gov/pubs/sp/800/84/final) - NIST, on test, training and exercise programmes, including the difference between a tabletop discussion and a functional test. Free. Accessed 2026-08-12.
- [ISO 22301](https://www.iso.org/standard/75106.html) - ISO, the business continuity management standard the commercial vocabulary comes from. Paid. Accessed 2026-08-12.

**Pictures.** A freely licensed file from Wikimedia Commons, downloaded and served
from this site rather than linked across to somebody else's server. Resized and
otherwise unaltered.

- [Data center backup generators](https://commons.wikimedia.org/wiki/File:Data_center_backup_generators.jpg) by Rsparks3, [CC0](https://creativecommons.org/publicdomain/zero/1.0/).

**Where the output came from.** Nothing on this page is captured, and there is no
Across platforms section, because there is no command here to run on any of them.
Disaster recovery is decisions and rehearsal, and a transcript of a decision is a
screenshot of a meeting. The three figures carry what the prose would otherwise
have to assert, which is the honest substitute when a topic has no observable
behaviour to record.

**If you also work on Linux.** [Backup and restore](/learn/linux-plus/backup-and-restore)
on the Linux+ track covers the mechanism underneath the recovery point objective:
what gets copied, how often, and how you find out whether the copy is any good.
