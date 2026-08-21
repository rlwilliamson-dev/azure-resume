---
title: "How big networks actually break"
description: "Three of the largest failures of recent years, read as faults rather than as news. A backbone that withdrew itself from the internet, a DNS record that automation emptied, and a filter deleted during a tidy-up. All three organisations employ excellent engineers, and none of the causes are exotic."
deck: "Excellent engineers, ordinary causes"
track: "network-plus"
level: "working"
order: 830
beyondExam: true
objectives:
  - "Read a published incident report and identify which layer actually failed"
  - "Explain how a correct health check can remove a working service from the internet"
  - "Say why an empty answer is a worse failure than a wrong one"
  - "Describe what overload protection on a control plane is for"
  - "Recognise a recovery path that depends on the thing that has failed"
prerequisites: ["the-hour-after-it-breaks", "managing-devices-remotely"]
tags: ["network-plus", "networking", "operations", "beyond-the-exam"]
updated: 2026-08-20
draft: false
examObjectives: []
sources:
  - title: "More details about the October 4 outage"
    url: "https://engineering.fb.com/2021/10/05/networking-traffic/outage-details/"
    publisher: "Meta"
    accessed: 2026-08-20
    tier: 1
  - title: "Summary of the Amazon DynamoDB Service Disruption in the Northern Virginia (US-EAST-1) Region"
    url: "https://aws.amazon.com/message/101925/"
    publisher: "Amazon Web Services"
    accessed: 2026-08-20
    tier: 1
  - title: "Assessment of Rogers Networks for Resiliency and Reliability Following the 8 July 2022 Outage"
    url: "https://crtc.gc.ca/eng/publications/reports/xonarp2023.htm"
    publisher: "Canadian Radio-television and Telecommunications Commission"
    accessed: 2026-08-20
    tier: 1
symptoms:
  - symptom: "A service is running and unreachable, and nothing is wrong with the service"
    anchor: "october-2021-withdrawing-yourself-from-the-internet"
  - symptom: "Recovery is blocked because the tools to fix it are behind the thing that broke"
    anchor: "the-shape-all-three-share"
---

> **Before you read.** Three of the largest network failures of recent years,
> at three organisations that employ some of the best engineers in the industry
> and can afford any equipment they want.
>
> **In each one, was the fault in the thing that broke, or in something that was
> working exactly as designed?**

Every incident on this page has a published account written by the organisation
involved or by its regulator. That is the reason these three were chosen over
better-known ones: the facts are on the record rather than reconstructed, and each
account is worth reading in full. What follows reads them as faults, using the
same vocabulary the rest of this track uses, and none of it is examinable.

### Some words you will need

<dl class="terms">
<dt>post-event summary</dt>
<dd>The published account of an incident. Different organisations call it a postmortem, an incident report, or a summary.</dd>
<dt>control plane</dt>
<dd>The part of a device that decides where traffic goes, as opposed to the part that moves it.</dd>
<dt>out-of-band</dt>
<dd>A management path that does not depend on the network being managed.</dd>
<dt>cascading failure</dt>
<dd>A failure whose consequences trigger further failures, each of which was a designed response to the last.</dd>
<dt>redistribution</dt>
<dd>Taking routes learned by one routing protocol and injecting them into another.</dd>
<dt>blast radius</dt>
<dd>Everything a change can affect if it goes wrong, as opposed to everything it was meant to affect.</dd>
</dl>

## What breaks without this

**Failures get attributed to the wrong thing.** Reading an outage as bad luck or
as somebody's incompetence produces no change, and the actual cause is usually a
mechanism that behaved correctly in a situation nobody had considered.

**The same design gets built again.** Every one of these has a lesson that costs
almost nothing to apply beforehand and is very expensive to learn afterwards.

**Nobody checks their own recovery path.** The most consistent finding across
published accounts is not what caused the outage. It is what made it last hours
instead of minutes.

## October 2021: withdrawing yourself from the internet

During routine maintenance on Meta's backbone, a command intended to assess
available capacity took down every connection on that backbone at once. An audit
tool existed to prevent exactly this kind of command from executing, and a bug in
it meant the command ran.

That alone would have been an internal problem. What turned it into a global
outage was a second mechanism, working precisely as designed.

Meta's authoritative DNS servers were built to check their own health by testing
whether they could reach the data centres behind them. A name server that cannot
reach what it is advertising is not much use, so on failing that check it
withdraws its BGP advertisements, which removes it from the internet and lets
another site answer instead. Sensible. When the backbone disappeared, every one of
those servers failed the check at the same moment, every one of them withdrew, and
the addresses of Meta's entire name service vanished from the global routing
table.

Read that as a fault and the interesting sentence is this: **the DNS servers were
running the whole time.** Nothing was wrong with them. They were unreachable
because they had correctly concluded they should be, and there was nobody left to
tell them otherwise.

Recovery then met the second problem. With the backbone down, the normal way in
was gone, so engineers had to go to the buildings in person, and data centres are
designed to be difficult to get into. The delay was not diagnosis. Meta knew what
had happened fairly quickly. The delay was physical access to equipment that could
no longer be reached any other way.

<details class="deeper">
<summary>If you run anycast services: why the withdrawal design is still right, and what has to sit alongside it</summary>

The instinct after reading this is that a server should not be able to remove
itself from the internet. That instinct produces a worse system.

The alternative is a name server that keeps advertising while unable to answer
usefully, which means every query that lands on it fails and no other site gets a
chance. Withdrawal is how anycast heals: the unhealthy instance steps back, the
routing system sends the traffic to the next nearest instance, and users see
nothing. It is the same argument as a load balancer taking a failed member out of
a pool, and it works thousands of times a day without anybody noticing.

What it needs alongside it is a floor. The check that withdraws an instance has to
know how many instances are left, and refuse to withdraw the last ones. A
mechanism that is correct per instance can be catastrophic in aggregate when every
instance evaluates the same condition at the same moment, and correlated failure
is exactly what a shared dependency like a backbone produces.

The general form is worth carrying beyond DNS. Any automatic step-back needs an
answer to the question of what happens when everything decides to step back
together. Health checks, failover, circuit breakers and load shedding all have
this property, and the failure mode is invisible in testing because testing
usually breaks one instance at a time.

</details>

## October 2025: the record that went empty

Amazon's account of the October 2025 disruption in its Northern Virginia region
describes a race between two pieces of its own automation.

The DNS records for a regional database endpoint are maintained by components that
apply update plans. Two were working at once on different plans. One ran unusually
slowly. The other finished, and its completion triggered a cleanup that removes
older plans. Meanwhile the slow one, still holding a plan that was now out of
date, applied it over the newer one. The check designed to stop precisely that had
itself gone stale during the delay.

The cleanup then deleted the plan the slow component had just applied, and with it
every address for the regional endpoint. The name did not resolve to something
wrong. It resolved to nothing.

Worse, the state left behind blocked any further updates from being applied by any
of the components, so the system that maintains those records could not repair
them. A human had to intervene.

The dependency chain underneath is the part worth studying. An enormous number of
services inside and outside that region reach that database by name, so a name
with no addresses is indistinguishable, from their point of view, from the
database not existing. Recovery brought its own second act: as capacity came back,
a load balancer's health checking began failing new instances that had been put
into service before their network configuration had finished propagating, so
health flapped between failing and passing while everything else was still
recovering.

<details class="deeper">
<summary>If you operate DNS: why an empty answer is harder to survive than a wrong one</summary>

A wrong address fails immediately and loudly. Something connects to the wrong
place, gets refused or times out, and every layer above has an error to work with.
It is bad, and it is legible.

An empty answer is different in three ways. Resolution itself succeeds, so the
failure surfaces as "no such host" rather than as a connection problem, and the
first instinct of everybody reading that message is to suspect their own
configuration. Retry logic frequently does not help, because a resolver with a
negative answer will keep returning it for as long as the negative caching
interval says, and that interval is set by the zone rather than by the client. And
the failure arrives everywhere at once rather than gradually, because a name is
consulted at the start of every connection rather than being held open.

Which is why the negative caching value in a zone's start of authority record,
covered in topic 46, is worth setting deliberately rather than leaving at whatever
was copied from an example. It is the length of time a mistake keeps being
believed after it has been corrected, and a comfortable value for a stable zone is
an uncomfortable one during an incident.

The operational habit that follows is to alarm on a record returning no answers,
separately from alarming on a service being unreachable. They are different
conditions with different causes, and the first one is invisible to a monitor that
only checks whether the service responds.

</details>

## July 2022: the filter somebody tidied away

The Canadian regulator's assessment of the Rogers outage describes a change made
during the sixth phase of a seven-phase upgrade. Staff removed an access control
list policy filter from the configuration of the distribution routers, as part of
tidying those configurations up.

That filter was the thing preventing the full internet routing table, learned by
BGP, from being redistributed into the interior routing protocol. With it gone,
that redistribution happened. The interior protocol flooded the resulting updates
through the core, the core routers' processors and memory could not keep up, and
they crashed within minutes.

The report is direct about what was missing: the core routers had no overload
protection configured, and industry practice calls for it precisely so that a
flood of routing information cannot exhaust a router.

Then the recovery problem, which by now should look familiar. Staff working
remotely could not reach the management network, because the management network
depended on the core that had just crashed. Technicians had to be sent to sites in
person. And because the network carried emergency calling, connectivity to the 911
providers was severed, which is what moved this from a commercial failure to a
regulatory one.

<details class="deeper">
<summary>If you configure routers: what overload protection actually looks like, and why it feels like paranoia until it does not</summary>

Two mechanisms do most of the work and both are unglamorous.

The first is a limit on how many prefixes a session will accept. A BGP neighbour
that suddenly starts sending a million routes when it has always sent forty is
either misconfigured or compromised, and a session that shuts itself down at a
threshold turns a network-wide event into one dead session and an alarm. The
threshold does not have to be clever. Anything within an order of magnitude of
normal is enough to catch the case that matters.

The second is protecting the control plane from the traffic aimed at it. A router
forwards packets in hardware and thinks in software, and anything the software has
to look at competes for the same processor that runs the routing protocols. Rate
limiting what reaches the control plane means a flood costs you the flood rather
than costing you the routing.

Neither is interesting to configure and neither shows any benefit on a normal day,
which is why both are so often absent. The way to get them in place is to treat
them as part of the build rather than as a hardening exercise, because a hardening
exercise is scheduled and a build is done.

And the general principle underneath is worth stating plainly. Redistribution
between routing protocols is one of the sharpest tools in networking. It moves
information between two systems that have different assumptions about scale, and
the filter on it is not a detail of the configuration. It is the thing standing
between one protocol's normal and another protocol's catastrophe.

</details>

## The shape all three share

Read together rather than separately, the three have two things in common, and
neither of them is a mistake anybody made.

**In every case the damage was done by a mechanism working as designed.** The
health check that withdrew the name servers was correct. The cleanup that deleted
the stale plan was correct. Redistributing routes between protocols is a normal
thing to do. None of the three failures required a component to malfunction, only
to be given a situation nobody had thought about, and that is why they were not
caught in testing.

**In every case the way to fix it ran through the thing that had failed.** Meta's
engineers could not reach the data centres because the backbone was the way in.
Rogers staff could not reach the management network because it depended on the
core. Amazon's automation could not repair the records because the broken state
blocked the mechanism that would have repaired them.

<figure class="learn-figure">
<svg viewBox="0 0 720 212" role="img" aria-labelledby="shared-title" style="width:100%;height:auto;">
<title id="shared-title">An engineer with two paths towards the network, the normal one and the one used to repair it, both passing through the same component, so that a failure of that component removes both</title>
<g fill="currentColor">
<text x="14" y="24" font-size="11">two paths that turn out to be one path</text>
<rect x="20" y="82" width="112" height="42" rx="3" fill="currentColor" fill-opacity="0.08" stroke="currentColor" stroke-opacity="0.5"/>
<text x="76" y="107" text-anchor="middle" font-size="10.5">you, at 03:00</text>
<text x="232" y="66" text-anchor="middle" font-size="10">how you normally reach it</text>
<text x="232" y="158" text-anchor="middle" font-size="10">how you would repair it</text>
<line x1="132" y1="96" x2="336" y2="88" stroke="currentColor" stroke-opacity="0.45" stroke-width="1.4"/>
<line x1="132" y1="112" x2="336" y2="122" stroke="currentColor" stroke-opacity="0.45" stroke-width="1.4"/>
<rect x="340" y="74" width="164" height="58" rx="3" fill="var(--red)" fill-opacity="0.12" stroke="var(--red)" stroke-opacity="0.8" stroke-width="1.6"/>
<text x="422" y="97" text-anchor="middle" font-size="10.5" fill="var(--red)">the backbone, the core,</text>
<text x="422" y="115" text-anchor="middle" font-size="10.5" fill="var(--red)">the name service</text>
<line x1="504" y1="103" x2="576" y2="103" stroke="currentColor" stroke-opacity="0.45" stroke-width="1.4"/>
<rect x="580" y="82" width="112" height="42" rx="3" fill="currentColor" fill-opacity="0.08" stroke="currentColor" stroke-opacity="0.5"/>
<text x="636" y="107" text-anchor="middle" font-size="10.5">everything else</text>
<text x="14" y="196" font-size="10" fill-opacity="0.75">Meta 2021, Rogers 2022, and Amazon 2025 each contain a version of this drawing</text>
</g>
</svg>
<figcaption>Redundancy was not the problem in any of the three. All of them had plenty, and all of it was inside the failure. The question this drawing asks is the cheap one to answer on a quiet afternoon and the impossible one to answer at three in the morning: if the thing in the middle stops, what is left that reaches the equipment? A separate circuit from a different provider, a console server on a mobile connection, an address book that does not need DNS to be useful. Topic 51 covers what out-of-band actually means, and this is what it is for.</figcaption>
</figure>

There is a third pattern that is less about engineering. In all three published
accounts, the organisation knew what had happened well before service returned.
Diagnosis was not the long pole. Access was, in two cases physically, and that is
a design decision made years earlier by somebody who was not thinking about
outages at all.

## Prove it

**Read one of the three in full.** All three are linked below and none is long.
Meta's is the most readable, Amazon's is the most technically detailed, and the
regulator's report on Rogers is the only one written by somebody with no interest
in the organisation looking good, which makes it the most instructive of the
three.

**Trace your own recovery path on paper.** Pick the device you would least like to
lose. Write down how you would reach it if it stopped forwarding traffic. Then
check whether every step in that answer depends on the device. Most people find
one hop they had not thought about, and finding it costs an afternoon.

**Look up the negative caching value on a zone you own.** It is in the start of
authority record, covered in topic 46. Whatever it says is how long a mistake in
that zone stays believed after you fix it.

## What trips people up

### 1. Reading these as incompetence

Every one of these organisations employs excellent engineers and none of the
causes is exotic. Treating a published failure as somebody else's carelessness is
the reliable way to build the same thing again.

### 2. Looking for a single root cause

Each of these has several contributing factors, and removing any one of them
would have changed the outcome. Which one gets called the root cause is usually a
decision about emphasis rather than a finding.

### 3. Assuming redundancy covers this

All three had redundancy. In each case the redundant paths shared the component
that failed, which is the only kind of redundancy that is worth nothing.

### 4. Treating a health check as harmless

A check that withdraws an unhealthy instance is a good design that becomes a
catastrophe when every instance fails the same check at the same moment.

### 5. Removing a filter because nothing appears to use it

A filter with no hits is either useless or is the thing preventing something. The
Rogers filter had a very low hit rate right up until the moment it mattered.

### 6. Testing failures one at a time

Every mechanism in these accounts behaves correctly when one component fails. The
failures came from correlated events, which is exactly what a test plan built
around single failures cannot produce.

## Work it through

Your organisation runs two internet circuits from two providers, two firewalls,
two core switches, and a pair of internal DNS resolvers. Somebody asks you to
assess whether an incident of the kind described above could happen to you.

Start with the recovery path rather than the redundancy, because the redundancy is
the part that has already been paid for and thought about. If both cores were
down, how would you reach the equipment? If the answer involves a jump host, ask
where that jump host is and what it depends on. If the answer involves logging in
from home, ask what resolves the name you type and what authenticates you.

Then look for correlated dependencies rather than single points of failure. Two
providers is not two paths if both circuits enter the building through the same
duct, and two resolvers is not redundancy if both are virtual machines on the same
cluster. Neither of those shows up on a diagram that draws two of everything.

Then look for the mechanisms that step back automatically. Anything that removes
itself when unhealthy, fails over, or shuts down a session at a threshold. For
each, ask what happens if every instance of it decides to act at the same instant,
which is the specific question the Meta account answers.

And write down what you find rather than fixing it immediately, because the value
here is the list. Most of what turns up will be cheap, some of it will be a
project, and the argument for the project is much stronger when it arrives beside
the four cheap things you already did.

## Try it

**Pick the incident closest to your own environment and present it to your team.**
Fifteen minutes and the published account. It is a better use of a team meeting
than most things in one, and it produces the conversation about your own recovery
path without anybody having to raise it as a criticism.

**Test one out-of-band path this quarter.** Not a review of whether it exists. Use
it, from outside, with the main path unavailable to you. The number of console
servers that turn out to be behind the firewall they exist to survive is not small.

**Set an alert on a name returning no answers.** Separately from whether the
service responds. It is a different condition with a different cause and most
monitoring only checks the second one.

## Check yourself

<details class="qa">
<summary>Meta's DNS servers were running throughout the October 2021 outage. Why was the service unreachable?</summary>

They withdrew their own BGP advertisements. Each was designed to check whether it
could reach the data centres behind it and to step back if not, and when the
backbone failed they all failed that check simultaneously, so the addresses of the
name service left the global routing table.

</details>

<details class="qa">
<summary>What made the empty DNS record in the 2025 Amazon incident harder to recover from than a wrong one?</summary>

Resolution succeeded and returned nothing, so callers saw the name as
nonexistent rather than as unreachable, and the broken state prevented the
automation that maintains those records from applying any further updates. It
needed a person.

</details>

<details class="qa">
<summary>Removing one filter took down a national network. What was the filter doing?</summary>

Preventing the full BGP routing table from being redistributed into the interior
routing protocol. Without it, that redistribution flooded the core routers with
routing updates until their processors and memory were exhausted.

</details>

<details class="qa">
<summary>What did the three incidents have in common in their recovery, rather than in their cause?</summary>

The path to fix each one ran through the thing that had failed. Access was the
long pole in all three, and in two of them people had to travel to buildings
because no remaining path reached the equipment.

</details>

<details class="qa">
<summary>Why does testing failures one component at a time miss these?</summary>

Every mechanism involved behaves correctly when one thing fails. The damage came
from many instances evaluating the same condition at the same moment, which a test
plan built around single failures never produces.

</details>

## References

- [More details about the October 4 outage](https://engineering.fb.com/2021/10/05/networking-traffic/outage-details/) - Meta, the organisation's own account of the backbone command, the audit tool, and the DNS withdrawal. Free. Accessed 2026-08-20.
- [Summary of the Amazon DynamoDB service disruption in the Northern Virginia region](https://aws.amazon.com/message/101925/) - Amazon Web Services, the post-event summary describing the race between DNS components and the inconsistent state it left. Free. Accessed 2026-08-20.
- [Assessment of Rogers Networks for Resiliency and Reliability Following the 8 July 2022 Outage](https://crtc.gc.ca/eng/publications/reports/xonarp2023.htm) - Canadian Radio-television and Telecommunications Commission, the regulator's assessment, including the missing overload protection and the loss of emergency calling. Free. Accessed 2026-08-20.

**Where this came from.** Nothing on this page is captured. Every factual claim
about each incident comes from the account linked above it, written either by the
organisation involved or by its regulator, and the analysis alongside them is
this track applying its own vocabulary rather than anything those documents
assert. The figure is drawn to argue a pattern the three accounts share rather
than to report any measurement.

**Why this is not in the lesson count.** No exam asks about specific incidents.
This is here because the published accounts are the closest thing the industry has
to a shared body of case law, and reading them is how the abstract lessons in the
rest of this track acquire a date, a company and a cost.
