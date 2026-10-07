---
title: "Comparing architectures"
description: "The considerations list used as a scoring frame rather than a vocabulary list, what each additional nine of availability actually buys, why two components in parallel beat one better component, and the single column that decides a comparison nobody wrote down."
deck: "Two designs, both correct, and the one you pick is decided by something nobody wrote down"
track: "security-plus"
level: "working"
order: 310
objectives:
  - "Use the architecture considerations as a frame for comparing designs"
  - "Convert an availability target into permitted downtime"
  - "Explain why redundancy changes availability more than component quality does"
  - "Distinguish resilience from ease of recovery"
  - "Find the requirement that decides a comparison"
  - "Explain why risk transference is a legitimate answer and what it does not transfer"
prerequisites: ["the-systems-you-cannot-patch"]
tags: ["security-plus", "security", "architecture"]
updated: 2026-10-07
draft: false
examObjectives:
  - exam: "sy0-701"
    domain: "3.0"
    objective: "3.1"
sources:
  - title: "SP 800-160 Vol. 2 Rev. 1, Developing Cyber-Resilient Systems: A Systems Security Engineering Approach"
    url: "https://csrc.nist.gov/pubs/sp/800/160/v2/r1/final"
    publisher: "NIST"
    accessed: 2026-10-07
    tier: 1
  - title: "SP 800-34 Rev. 1, Contingency Planning Guide for Federal Information Systems"
    url: "https://csrc.nist.gov/pubs/sp/800/34/r1/upd1/final"
    publisher: "NIST"
    accessed: 2026-10-07
    tier: 1
symptoms:
  - symptom: "Two architecture proposals are argued about without agreement on what matters"
    anchor: "the-column-that-decides-it"
  - symptom: "An availability target was agreed and nobody knows what it permits"
    anchor: "the-considerations-are-a-scoring-frame"
---

> **Before you read.** Two architects bring two designs for the same system. Both
> are secure, both are within budget, and both have been reviewed. The meeting to
> choose between them has run for an hour and nobody has changed their mind.
>
> **What is missing from the meeting?**

The requirement that decides it. Two correct designs differ in what they are good
at, and the choice depends on which of those strengths this system needs. If
nobody has written that down, each architect is scoring against a different
unstated requirement, and the meeting cannot end because the two of them are not
disagreeing about the designs at all.

The objective gives a list of considerations for comparing architecture models.
This topic uses it the way it is most useful: as a set of columns to score designs
against, so that the deciding requirement has to be named.

### Some words you will need

<dl class="terms">
<dt>availability</dt>
<dd>The share of time a system is usable, usually stated as a percentage over a year.</dd>
<dt>resilience</dt>
<dd>The ability to keep working while something is failing.</dd>
<dt>ease of recovery</dt>
<dd>How quickly and simply a system returns to normal after it has failed.</dd>
<dt>responsiveness</dt>
<dd>How quickly the system answers under normal load.</dd>
<dt>scalability</dt>
<dd>How readily capacity can be added when demand grows.</dd>
<dt>risk transference</dt>
<dd>Moving the consequence of a risk to another party, by contract or insurance.</dd>
<dt>series</dt>
<dd>Components that must all work for the system to work.</dd>
<dt>parallel</dt>
<dd>Components where any one working is enough.</dd>
</dl>

## The considerations are a scoring frame

The considerations fall into a few groups, and each group asks a different kind of
question.

**Availability, resilience and ease of recovery are about failure.** How often the
system is down, whether it keeps working while something breaks, and how quickly it
comes back. They sound like one thing and they are three, as the panel further
down explains.

**Cost, ease of deployment, scalability and responsiveness are about running it.**
What it costs to build and operate, how hard it is to stand up, how it grows, and
how fast it answers.

**Patch availability and inability to patch are about maintenance over time**,
which topic 29 covered from the hard end. A design built on a platform with a
long, predictable support life scores differently from one built on equipment that
will never receive another update.

**Power and compute are physical limits.** A design that needs more electricity or
processing than the site can supply is not a design for that site, however good it
looks on paper.

**Risk transference is the odd one out**, and it has its own section below.

Availability is the consideration most often stated as a number and least often
converted into what the number permits.

<details class="predict">
<summary>Two components, each available 99.9 percent of the time. Predict the availability of the system when both are needed, and when either one is enough.</summary>

```bash
# AlmaLinux 10.2, x86_64
$ availability
target      downtime a year    a month
99%                  3d 15h     7h 18m
99.9%                8h 45m    43m 49s
99.95%               4h 22m    21m 54s
99.99%              52m 35s     4m 22s
99.999%              5m 15s        26s

two components, each 99.9% available
  in series, both needed:     99.8001%   17h 31m a year
  in parallel, either works:  99.9999%       31s a year
```

**Two components in series are worse than either one. Two in parallel are better
than any single component on the list above.**

The table first. Each extra nine divides the permitted downtime by ten, so the
difference between 99.9 and 99.99 percent is the difference between almost nine
hours of outage a year and under an hour. Those targets get agreed in contracts
without anybody translating them, and the translation is what an operations team
has to deliver.

Then the two arrangements. In series, where both components must work, the
availabilities multiply, and two components that are each down for nine hours a
year produce a system that is down for seventeen and a half. Every component added
in series makes the system less available than its weakest part.

In parallel, where either component is enough, the system is only down when both
fail at the same moment, and the result is about thirty seconds a year. Two
ordinary components arranged so that either can carry the load beat any single
component you could buy.

**One assumption is hiding in that last line.** The calculation treats the two
failures as independent. If both components share a power supply, a network link,
a building or a software bug, they fail together and the parallel figure is
fiction. Topic 38 is about that assumption.

</details>

<details class="deeper">
<summary>Resilience and ease of recovery are different columns, and a design can score well on one and badly on the other</summary>

Both describe how a system behaves around failure, which is why they get merged.
They measure different moments.

**Resilience is about the failure itself.** A resilient system keeps working while
a component is broken: a second server takes the load, a second link carries the
traffic, and users notice nothing. It is measured by whether the service continued.

**Ease of recovery is about afterwards.** Once something has failed, how long does
it take to get back to normal, and how hard is it? Restoring from backup, rebuilding
a server from a template, failing back to the primary site. It is measured in time
and effort.

**A design can be highly resilient and hard to recover.** A tightly clustered
database survives a node failure without interruption, and if the cluster itself is
corrupted, rebuilding it is a long specialist job. Another design can be fragile
and easy to recover: a single stateless server that falls over often and is
replaced from a template in two minutes.

**Which one matters depends on the system.** A payment service needs resilience,
because any interruption is visible and costly. An internal reporting tool may be
better served by ease of recovery, because an hour of downtime is tolerable and a
simple rebuild is cheaper than redundancy. Scoring both columns separately is what
makes that trade visible.

</details>

## The column that decides it

Scoring designs against every consideration produces a table, and most tables have
a winner on points. The useful question is whether any single column overrides the
points.

<figure class="learn-figure">
<svg viewBox="0 0 720 272" role="img" aria-labelledby="score-title" style="width:100%;height:auto;">
<title id="score-title">Four architecture models scored against six considerations for a clinic appointment system, with the one deciding column outlined and one irrelevant column faded</title>
<g fill="currentColor">
<text x="14" y="20" font-size="11">one requirement, four architecture models, six columns</text>
<text x="14" y="42" font-size="9" fill-opacity="0.85">a clinic's appointment system, which must keep working when the building loses its internet link</text>
<text x="195" y="72" font-size="8" text-anchor="middle" fill-opacity="0.8">with the link down</text>
<text x="285" y="72" font-size="8" text-anchor="middle" fill-opacity="0.8">cost</text>
<text x="375" y="72" font-size="8" text-anchor="middle" fill-opacity="0.45">scalability</text>
<text x="465" y="72" font-size="8" text-anchor="middle" fill-opacity="0.8">ease of deployment</text>
<text x="555" y="72" font-size="8" text-anchor="middle" fill-opacity="0.8">risk transference</text>
<text x="645" y="72" font-size="8" text-anchor="middle" fill-opacity="0.8">ease of recovery</text>
<text x="14" y="100" font-size="9.5">on-premises</text>
<rect x="153" y="84" width="84" height="24" rx="2" fill="var(--accent)" fill-opacity="0.3"/>
<text x="195" y="100" font-size="8.5" text-anchor="middle" fill-opacity="0.9">yes</text>
<rect x="243" y="84" width="84" height="24" rx="2" fill="currentColor" fill-opacity="0.06"/>
<text x="285" y="100" font-size="8.5" text-anchor="middle" fill-opacity="0.9">fair</text>
<rect x="333" y="84" width="84" height="24" rx="2" fill="currentColor" fill-opacity="0.06"/>
<text x="375" y="100" font-size="8.5" text-anchor="middle" fill-opacity="0.4">poor</text>
<rect x="423" y="84" width="84" height="24" rx="2" fill="var(--red)" fill-opacity="0.14"/>
<text x="465" y="100" font-size="8.5" text-anchor="middle" fill-opacity="0.9">poor</text>
<rect x="513" y="84" width="84" height="24" rx="2" fill="var(--red)" fill-opacity="0.14"/>
<text x="555" y="100" font-size="8.5" text-anchor="middle" fill-opacity="0.9">poor</text>
<rect x="603" y="84" width="84" height="24" rx="2" fill="var(--red)" fill-opacity="0.14"/>
<text x="645" y="100" font-size="8.5" text-anchor="middle" fill-opacity="0.9">poor</text>
<text x="14" y="128" font-size="9.5">IaaS</text>
<rect x="153" y="112" width="84" height="24" rx="2" fill="var(--red)" fill-opacity="0.14"/>
<text x="195" y="128" font-size="8.5" text-anchor="middle" fill-opacity="0.9">no</text>
<rect x="243" y="112" width="84" height="24" rx="2" fill="currentColor" fill-opacity="0.06"/>
<text x="285" y="128" font-size="8.5" text-anchor="middle" fill-opacity="0.9">fair</text>
<rect x="333" y="112" width="84" height="24" rx="2" fill="currentColor" fill-opacity="0.06"/>
<text x="375" y="128" font-size="8.5" text-anchor="middle" fill-opacity="0.4">good</text>
<rect x="423" y="112" width="84" height="24" rx="2" fill="currentColor" fill-opacity="0.06"/>
<text x="465" y="128" font-size="8.5" text-anchor="middle" fill-opacity="0.9">fair</text>
<rect x="513" y="112" width="84" height="24" rx="2" fill="currentColor" fill-opacity="0.06"/>
<text x="555" y="128" font-size="8.5" text-anchor="middle" fill-opacity="0.9">fair</text>
<rect x="603" y="112" width="84" height="24" rx="2" fill="currentColor" fill-opacity="0.06"/>
<text x="645" y="128" font-size="8.5" text-anchor="middle" fill-opacity="0.9">fair</text>
<text x="14" y="156" font-size="9.5">PaaS</text>
<rect x="153" y="140" width="84" height="24" rx="2" fill="var(--red)" fill-opacity="0.14"/>
<text x="195" y="156" font-size="8.5" text-anchor="middle" fill-opacity="0.9">no</text>
<rect x="243" y="140" width="84" height="24" rx="2" fill="var(--accent)" fill-opacity="0.3"/>
<text x="285" y="156" font-size="8.5" text-anchor="middle" fill-opacity="0.9">good</text>
<rect x="333" y="140" width="84" height="24" rx="2" fill="currentColor" fill-opacity="0.06"/>
<text x="375" y="156" font-size="8.5" text-anchor="middle" fill-opacity="0.4">good</text>
<rect x="423" y="140" width="84" height="24" rx="2" fill="var(--accent)" fill-opacity="0.3"/>
<text x="465" y="156" font-size="8.5" text-anchor="middle" fill-opacity="0.9">good</text>
<rect x="513" y="140" width="84" height="24" rx="2" fill="var(--accent)" fill-opacity="0.3"/>
<text x="555" y="156" font-size="8.5" text-anchor="middle" fill-opacity="0.9">good</text>
<rect x="603" y="140" width="84" height="24" rx="2" fill="var(--accent)" fill-opacity="0.3"/>
<text x="645" y="156" font-size="8.5" text-anchor="middle" fill-opacity="0.9">good</text>
<text x="14" y="184" font-size="9.5">SaaS</text>
<rect x="153" y="168" width="84" height="24" rx="2" fill="var(--red)" fill-opacity="0.14"/>
<text x="195" y="184" font-size="8.5" text-anchor="middle" fill-opacity="0.9">no</text>
<rect x="243" y="168" width="84" height="24" rx="2" fill="var(--accent)" fill-opacity="0.3"/>
<text x="285" y="184" font-size="8.5" text-anchor="middle" fill-opacity="0.9">good</text>
<rect x="333" y="168" width="84" height="24" rx="2" fill="currentColor" fill-opacity="0.06"/>
<text x="375" y="184" font-size="8.5" text-anchor="middle" fill-opacity="0.4">good</text>
<rect x="423" y="168" width="84" height="24" rx="2" fill="var(--accent)" fill-opacity="0.3"/>
<text x="465" y="184" font-size="8.5" text-anchor="middle" fill-opacity="0.9">good</text>
<rect x="513" y="168" width="84" height="24" rx="2" fill="var(--accent)" fill-opacity="0.3"/>
<text x="555" y="184" font-size="8.5" text-anchor="middle" fill-opacity="0.9">good</text>
<rect x="603" y="168" width="84" height="24" rx="2" fill="var(--accent)" fill-opacity="0.3"/>
<text x="645" y="184" font-size="8.5" text-anchor="middle" fill-opacity="0.9">good</text>
<rect x="150" y="80" width="90" height="116" rx="3" fill="none" stroke="var(--red)" stroke-width="1.6"/>
<text x="150" y="214" font-size="8.5" fill-opacity="0.6">scalability does not matter here: a clinic does not grow tenfold overnight</text>
<text x="14" y="242" font-size="10">SaaS wins five of six columns and loses the one the requirement cares about</text>
<text x="14" y="262" font-size="9" fill-opacity="0.75">the frame decided nothing on its own. It made the deciding requirement impossible to leave unwritten</text>
</g></svg>
<figcaption>Four models scored for one requirement. Counted column by column, software as a service is the clear winner: cheapest, easiest to deploy, easiest to recover, and the provider carries most of the risk. It loses the outlined column, and that column is the requirement: when the clinic's internet link fails, a service that lives elsewhere is unreachable, and the reception desk cannot see who is booked. The faded column is the opposite case, a consideration that is real in general and irrelevant to this system. Most architecture arguments that will not end are two people weighting different columns without saying so.</figcaption>
</figure>

<details class="predict">
<summary>The clinic chooses software as a service anyway, because of cost. Predict what has to be added to the design to meet the requirement.</summary>

**Something that works locally when the link is down.**

There are several shapes it can take. An offline mode in the application that
keeps a copy of today's appointments on the reception machines and synchronises
when the link returns. A second internet link from a different provider, so that
one failed connection is not an outage, which turns the link into two components in
parallel. Or a printed copy of each day's schedule produced every morning, which
sounds primitive and is entirely adequate for a few hours of outage.

Each of these is a cost, and each one should be added to the software option's
column before the comparison is finished. The point of naming the deciding
requirement is that the cheaper option is no longer cheaper once it has been made
to meet it.

And one of the answers is not technical at all. If the clinic's owner decides that
a few hours without the schedule is acceptable, the requirement changes and the
comparison changes with it. That is a legitimate outcome, provided somebody with
the authority to accept it says so.

</details>

<details class="deeper">
<summary>Finding the requirement that decides, when nobody has written it down</summary>

Deciding requirements are rarely in the specification. They are in people's heads,
and they come out when the right question is asked.

**Ask what failure is unacceptable.** Not what would be inconvenient, but what
would make the system pointless or dangerous. For the clinic it is not knowing who
is booked. For a trading system it might be a delay of a second. For an archive it
might be any loss of data, at any speed.

**Ask who loses most if it goes wrong.** The people who carry the consequences of
a failure usually know the deciding requirement, and they are often not in the
architecture meeting. Reception staff, operators and customer service know what
breaks their day.

**Look for the constraint nobody can change.** Regulation, physical location, the
power available in a building, a contract already signed. These decide
comparisons quietly, and they are easy to discover after the design is chosen.

**Then write it down and score against it first.** Any design that fails the
deciding requirement is out, regardless of how it scores elsewhere. The remaining
columns choose between the designs that pass.

</details>

## Risk transference is a real answer

Risk transference appears in the list beside technical considerations, and it is
easy to treat it as an evasion. It is a legitimate choice with a specific limit.

**Transferring a risk moves its consequence, not its occurrence.** A provider that
runs the infrastructure takes on the work of keeping it available, and a contract
may pay compensation when it is not. Insurance pays for some of the cost of an
incident. In both cases the event still happens to you; somebody else bears part of
the cost.

**That is valuable where the consequence is mainly financial.** A provider that
can run a data centre more reliably than you, and will refund you when it fails,
has genuinely reduced your exposure for a predictable fee.

**It does not transfer what cannot be paid for.** Customer trust, regulatory
responsibility for personal data, and the safety consequences of an industrial
process stay with the organisation whatever the contract says.

<details class="deeper">
<summary>What the scoring frame hides, and the three ways a tidy table misleads</summary>

A table of designs against considerations is useful because it forces comparison.
It also hides things worth knowing.

**It hides weights.** Every column looks equally important in a grid, and they
never are. Unless the deciding requirement is marked, the table invites counting,
and counting picks the design that is good at many things that do not matter.

**It hides correlation.** Two designs can score well on availability for the same
reason, a shared provider or a shared region, and fail together. The table shows
two good scores and no relationship between them.

**It hides time.** A score describes a design today. Patch availability changes as
platforms age, costs change as usage grows, and a design that scores well on ease
of deployment may score badly on ease of change in three years. The table needs a
date on it and a reason to revisit it.

**None of that is an argument against the table.** It is an argument for treating
it as the start of the decision rather than the decision, with the deciding
requirement written above it and the assumptions written below.

</details>

## Try it

**Translate your own availability targets.** Find an availability figure in a
contract or service description you rely on, and work out the downtime it permits
in a year and in a month.

**Find one series dependency.** Pick a service you run and list every component it
needs to be working at the same time. Multiply their availabilities and compare the
result with what the service promises.

**Score two designs.** Take any two options for a system you know, score them
against the considerations, then ask the people who use it what failure would be
unacceptable. See whether the answer changes the winner.

**Read one transfer.** Find a contract that transfers a risk to a provider and
identify what it pays for and what it cannot.

## Check yourself

<details class="qa">
<summary>How much downtime a year does 99.99 percent availability permit?</summary>

About 52 minutes, as the calculation on this page shows, against almost nine hours
for 99.9 percent and about five minutes for 99.999 percent. Each additional nine
divides the permitted downtime by ten.

</details>

<details class="qa">
<summary>Why are two components in parallel more available than one better component?</summary>

Because the system fails only when both fail at the same moment. Two components at
99.9 percent each give about 99.9999 percent in parallel, roughly thirty seconds of
downtime a year, while the same two in series give 99.8 percent, because either
failing stops the system.

The calculation assumes the failures are independent. Shared power, links,
buildings or software make them fail together.

</details>

<details class="qa">
<summary>What is the difference between resilience and ease of recovery?</summary>

Resilience is whether the system keeps working while something is failing. Ease of
recovery is how quickly and simply it returns to normal after it has failed.

A clustered database can be highly resilient and slow to rebuild if the cluster
itself is damaged. A single stateless server can be fragile and replaced in minutes.
Which matters more depends on the system.

</details>

<details class="qa">
<summary>How do you settle an argument between two correct designs?</summary>

By finding and writing down the requirement that decides it, usually by asking what
failure would be unacceptable and who carries the consequences. Score every design
against that requirement first, remove any that fail it, and let the remaining
considerations choose between the rest.

The clinic example on this page shows the cheapest and easiest option failing the
one requirement that mattered.

</details>

<details class="qa">
<summary>What does risk transference move, and what does it leave behind?</summary>

It moves the financial consequence of a risk to another party, through a contract
with a provider or through insurance. The event still happens to the organisation.

It cannot move what money does not repair: customer trust, regulatory
responsibility for personal data, and safety consequences remain with the
organisation whatever the contract says.

</details>

## References

- [SP 800-160 Vol. 2 Rev. 1](https://csrc.nist.gov/pubs/sp/800/160/v2/r1/final) - NIST, developing cyber-resilient systems, for resilience as a property distinct from recovery. Free. Accessed 2026-10-07.
- [SP 800-34 Rev. 1](https://csrc.nist.gov/pubs/sp/800/34/r1/upd1/final) - NIST, contingency planning, for availability requirements and recovery objectives. Free. Accessed 2026-10-07.

**Where the content came from.** The availability table is calculated in an
AlmaLinux 10.2 container by a short script that converts each target into
permitted downtime over a year of 365.25 days, and combines two components in
series and in parallel under the usual assumption that their failures are
independent. The clinic scores in the figure are a worked example rather than a
measurement. There is no platform comparison, because nothing here depends on an
operating system.
