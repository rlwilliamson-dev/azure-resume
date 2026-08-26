---
title: "What automation costs"
description: "The payback arithmetic done properly, why the maintenance slope decides the answer and nobody estimates it, when not to automate, and the script that becomes the only way to do the thing after the person who wrote it leaves."
deck: "The script that provisions accounts has been running for two years. The person who wrote it left"
track: "security-plus"
level: "working"
order: 600
objectives:
  - "Name the benefits this objective lists and say which are measurable"
  - "Compute a payback period and say which input decides it"
  - "Say when not to automate something"
  - "Explain what technical debt means when the debt is a security control"
  - "Identify a single point of failure created by automation"
  - "Say what makes an automation supportable after its author leaves"
prerequisites: ["automating-the-boring-and-dangerous-parts"]
tags: ["security-plus", "security", "operations", "automation"]
updated: 2026-08-25
draft: false
examObjectives:
  - exam: "sy0-701"
    domain: "4.0"
    objective: "4.7"
sources:
  - title: "SP 800-128, Guide for Security-Focused Configuration Management"
    url: "https://csrc.nist.gov/pubs/sp/800/128/upd1/final"
    publisher: "NIST"
    accessed: 2026-08-25
    tier: 1
  - title: "SP 800-160 Vol. 1 Rev. 1, Engineering Trustworthy Secure Systems"
    url: "https://csrc.nist.gov/pubs/sp/800/160/v1/r1/final"
    publisher: "NIST"
    accessed: 2026-08-25
    tier: 1
  - title: "SP 800-204C, Implementation of DevSecOps"
    url: "https://csrc.nist.gov/pubs/sp/800/204/c/final"
    publisher: "NIST"
    accessed: 2026-08-25
    tier: 1
symptoms:
  - symptom: "An automation nobody can modify is the only way a process runs"
    anchor: "the-script-that-became-the-process"
  - symptom: "An automation project was justified on savings that never appeared"
    anchor: "the-slope-decides-the-answer"
---

> **Before you read.** A script provisions accounts. It has run every day for two
> years, it works, and the person who wrote it left eighteen months ago. Nobody
> currently employed has read it.
>
> **Is that a problem, and if so, what exactly is the problem?**

It is, and the problem is not the script. It is that the process it performs no
longer exists anywhere else, so the organisation's ability to provision accounts
is bounded by a program nobody understands and cannot safely change.

### Some words you will need

<dl class="terms">
<dt>payback period</dt>
<dd>How long until the effort saved exceeds the effort spent building it.</dd>
<dt>maintenance cost</dt>
<dd>The ongoing hours an automation consumes after it works. The input that decides the answer.</dd>
<dt>technical debt</dt>
<dd>Work deferred that accrues interest, in the form of everything later being harder.</dd>
<dt>supportability</dt>
<dd>Whether somebody other than the author can understand, change and fix it.</dd>
<dt>single point of failure</dt>
<dd>Something whose failure stops everything depending on it, with no alternative path.</dd>
<dt>workforce multiplier</dt>
<dd>The claim that automation lets a given team cover more. True, and it changes what the team does.</dd>
<dt>standard configuration</dt>
<dd>Machines built the same way, which is the benefit that compounds rather than saving hours.</dd>
</dl>

## What breaks without this

**A project is approved on savings it will never deliver.** The build cost was
estimated and the maintenance was not, and the maintenance is what decides.

**The automation becomes the only route.** The manual process is forgotten,
nobody has performed it in three years, and when the automation fails the
organisation cannot do the thing at all.

**A security control degrades quietly.** The automation still runs and the thing
it enforces has drifted from what anybody would now choose, and nothing prompts a
review.

**The author leaves.** The code has no tests, no documentation and no second
reader, and every change afterwards is made nervously or not at all.

## The slope decides the answer

Here is the payback calculation for a piece of automation, done three times with
one number changed.

<details class="predict">
<summary>Eighty hours to build, replacing forty runs a month at twenty five minutes each. Predict the payback period.</summary>

```bash
# AlmaLinux 10.2, x86_64
$ payback 80 4; echo; echo "the same build, maintained at eight hours a month:"; payback 80 8 | tail -2; echo; echo "and at seventeen, which is roughly what the manual work cost:"; payback 80 17 | tail -2
40 runs a month at 25 minutes each
build cost 80 hours, maintenance 4 hours a month

 month     manual   automated   saved so far
     1        17h         84h           -67h
     6       100h        104h            -4h
    12       200h        128h            72h
    24       400h        176h           224h
    36       600h        224h           376h

the automated line drops below the manual one in month 7

the same build, maintained at eight hours a month:

the automated line drops below the manual one in month 10

and at seventeen, which is roughly what the manual work cost:

the automated line never drops below the manual one in three years
```

**Month seven at four hours of maintenance a month, month ten at eight, and never
at seventeen.**

The build cost is the same eighty hours in all three. What changes is the ongoing
figure, and it moves the answer from a good investment to one that has still not
paid for itself after three years.

Seventeen hours a month is not an absurd number. It is roughly what the manual
work cost in the first place, and it is what an automation acquires when it
touches several systems whose interfaces change, when it needs somebody to
investigate its failures each week, and when it has become the thing people ask
questions about.

**Nobody estimates the slope**, and the reason is structural rather than careless.
At the point of deciding, there is nothing to maintain: the automation does not
exist, so the maintenance figure is a guess about a thing that has not been built.
The build cost, by contrast, is an engineer's estimate of work they can picture,
which is why it appears in every business case and the other number does not.

The practical correction is not better estimation. It is to record an actual
maintenance figure once the thing is running, for a year, and use it on the next
proposal. Most organisations automate repeatedly and have never measured what any
of it costs to keep.

</details>

<figure class="learn-figure">
<svg viewBox="0 0 720 300" role="img" aria-labelledby="pay-title" style="width:100%;height:auto;">
<title id="pay-title">Cumulative hours over three years for doing the work by hand against automating it, at two different maintenance costs, one of which never pays back</title>
<g fill="currentColor">
<text x="14" y="20" font-size="11">cumulative hours over three years, from the model in the capture</text>
<path d="M 60 240 H 660" stroke="currentColor" stroke-opacity="0.4" stroke-width="1.2"/>
<path d="M 60 240 V 46" stroke="currentColor" stroke-opacity="0.4" stroke-width="1.2"/>
<text x="60" y="256" text-anchor="middle" font-size="8" fill-opacity="0.7">month 1</text>
<text x="249" y="256" text-anchor="middle" font-size="8" fill-opacity="0.7">month 12</text>
<text x="454" y="256" text-anchor="middle" font-size="8" fill-opacity="0.7">month 24</text>
<text x="660" y="256" text-anchor="middle" font-size="8" fill-opacity="0.7">month 36</text>
<text x="52" y="180" text-anchor="end" font-size="8" fill-opacity="0.7">200h</text>
<text x="52" y="118" text-anchor="end" font-size="8" fill-opacity="0.7">400h</text>
<text x="52" y="55" text-anchor="end" font-size="8" fill-opacity="0.7">600h</text>
<polyline points="60.0,234.8 77.1,229.6 94.3,224.4 111.4,219.1 128.6,213.9 145.7,208.7 162.9,203.5 180.0,198.3 197.1,193.1 214.3,187.8 231.4,182.6 248.6,177.4 265.7,172.2 282.9,167.0 300.0,161.8 317.1,156.6 334.3,151.3 351.4,146.1 368.6,140.9 385.7,135.7 402.9,130.5 420.0,125.3 437.1,120.1 454.3,114.8 471.4,109.6 488.6,104.4 505.7,99.2 522.9,94.0 540.0,88.8 557.1,83.5 574.3,78.3 591.4,73.1 608.6,67.9 625.7,62.7 642.9,57.5 660.0,52.3" fill="none" stroke="currentColor" stroke-opacity="0.75" stroke-width="1.8"/>
<polyline points="60.0,213.7 77.1,212.5 94.3,211.2 111.4,210.0 128.6,208.7 145.7,207.5 162.9,206.2 180.0,205.0 197.1,203.7 214.3,202.5 231.4,201.2 248.6,199.9 265.7,198.7 282.9,197.4 300.0,196.2 317.1,194.9 334.3,193.7 351.4,192.4 368.6,191.2 385.7,189.9 402.9,188.7 420.0,187.4 437.1,186.2 454.3,184.9 471.4,183.7 488.6,182.4 505.7,181.2 522.9,179.9 540.0,178.7 557.1,177.4 574.3,176.2 591.4,174.9 608.6,173.7 625.7,172.4 642.9,171.2 660.0,169.9" fill="none" stroke="var(--accent)" stroke-opacity="0.95" stroke-width="1.8"/>
<polyline points="60.0,209.6 77.1,204.3 94.3,199.0 111.4,193.7 128.6,188.4 145.7,183.1 162.9,177.7 180.0,172.4 197.1,167.1 214.3,161.8 231.4,156.5 248.6,151.1 265.7,145.8 282.9,140.5 300.0,135.2 317.1,129.9 334.3,124.5 351.4,119.2 368.6,113.9 385.7,108.6 402.9,103.3 420.0,97.9 437.1,92.6 454.3,87.3 471.4,82.0 488.6,76.7 505.7,71.3 522.9,66.0 540.0,60.7 557.1,55.4 574.3,50.1 591.4,44.7 608.6,39.4 625.7,34.1 642.9,28.8 660.0,23.5" fill="none" stroke="var(--red)" stroke-opacity="0.9" stroke-width="1.8" stroke-dasharray="5 3"/>
<circle cx="162.9" cy="203.5" r="3.5" fill="var(--accent)"/>
<text x="171" y="197" font-size="8" fill="var(--accent)" fill-opacity="0.95">month 7, the lines cross</text>
<text x="656" y="46" text-anchor="end" font-size="8" fill-opacity="0.8">by hand, 600h</text>
<text x="656" y="17" text-anchor="end" font-size="8" fill="var(--red)" fill-opacity="0.9">automated, 17h a month to keep: 692h</text>
<text x="656" y="184" text-anchor="end" font-size="8" fill="var(--accent)" fill-opacity="0.95">automated, 4h a month to keep: 224h</text>
<text x="14" y="276" font-size="10" fill-opacity="0.85">the build cost is the step at the start. the maintenance is the slope, and the slope decides</text>
<text x="14" y="294" font-size="9" fill-opacity="0.7">nobody estimates the slope, because at the point of deciding there is nothing to maintain yet</text>
</g></svg>
<figcaption>The same automation under two maintenance costs, plotted against doing the work by hand. The step at the start is the build, which is the number everybody estimates. The slope after it is the maintenance, which is the number nobody does, and it decides the outcome: at four hours a month the lines cross in month seven and three years saves nearly four hundred hours, and at seventeen the automated line never comes down at all and finishes ninety two hours worse off than doing it by hand. Both lines describe the same piece of software. The difference is entirely in what it costs to keep running.</figcaption>
</figure>
<details class="predict">
<summary>An automated control has run successfully every night for two years with no failures. Predict what an audit of it would find.</summary>

**That it enforces the policy as it stood two years ago, correctly and without
interruption.**

The failure people expect from long-running automation is that it stops. That one
is easy: it announces itself, somebody investigates, and the process gets fixed or
performed by hand. It is a visible problem with a visible owner.

The failure that actually accumulates is the opposite. It never stops. The rules
it applies were correct when written, the policy has since changed in three small
ways, and nothing about a successful nightly run asks whether those rules are
still the ones anybody would choose. Every monitoring signal is green because
every monitoring signal measures execution rather than correctness.

Two years is roughly the point at which the gap becomes findable. A group has been
renamed and the automation quietly skips it. A new system was added to the estate
and is not in scope because the scope is a list in the code. A threshold was
loosened during an incident and never restored.

The check that finds it is not a monitor and cannot be. It is somebody comparing
what the automation does against what the current policy says, on a schedule,
which is why a review date belongs on an automated control for the same reason it
belongs on an exception.

The uncomfortable version, worth saying to anybody proposing to automate a
control: automating it removes the recurring human contact that would otherwise
have noticed the policy drifting, so the automation has to bring its own
replacement for that contact.

</details>

<details class="deeper">
<summary>If you are estimating the slope: where maintenance hours actually go, and the one that surprises people</summary>

Maintenance sounds like fixing bugs and it mostly is not. Breaking it down is the
only way to estimate it, and four categories cover almost all of it.

**Upstream change.** Every system the automation touches changes its interface,
its authentication, or its data format eventually, and each change is unscheduled
work arriving on somebody else's timetable. An automation touching six systems is
exposed to six release cadences it does not control.

**Failure investigation.** Not fixing, investigating. A run fails, somebody has to
determine whether it was the automation, the network, a system being down, or bad
input, and most of those investigations end in it was not the automation. That
time is still spent.

**Scope drift.** New systems get added to the estate, new roles are created, and
each one needs the automation extended. This is the category that grows with the
organisation rather than staying flat.

**Answering questions.** The one that surprises people, and frequently the
largest. Once something is automated, it becomes the thing people ask about: why
did this account get that group, why did this run skip that machine, can you check
whether it processed my request. Each question is ten minutes and there are
several a week, and none of it appears in anybody's model.

That last category also explains a pattern worth recognising. Maintenance hours
tend to rise for the first year rather than falling, because usage grows and the
questions grow with it, and an organisation that measured the slope in month three
will have measured the wrong number.

The estimate that has held up in practice is to take the build cost and assume
somewhere between a tenth and a fifth of it per year, ongoing, with the higher end
for anything touching several systems. That is a rough figure and it is a great
deal better than the zero that appears in most business cases.

</details>


## The benefits, and which of them are measurable

The objective lists seven benefits and they are not equally solid.

**Efficiency** is the hours in the arithmetic above. Measurable, and the one that
depends on the slope.

**Enforcing baselines** and **standard infrastructure configurations** are the
benefits that compound, and they are worth more than the hours. Machines built the
same way can be reasoned about, patched together, and compared against a baseline
meaningfully, which is what the baselines topic depends on.

**Scaling securely** is the observation that a manual process degrades as volume
rises and an automated one does not. Real, and it is the argument for automating
before you need it rather than after.

**Reaction time** is the strongest security-specific claim. A control applied in
seconds rather than in days closes a window that an attacker is inside, and for
containment actions this is the whole case.

**Employee retention** is in the objective and is worth taking seriously rather
than dismissing as filler. People leave jobs that consist of repeating the same
operation four hundred times a month, and the cost of replacing an engineer is
larger than most automation projects.

**Workforce multiplier** is the claim that a given team covers more. True, and
worth being precise about what it changes: the team stops performing operations
and starts maintaining the thing that performs them, which is different work
requiring different skills, and pretending otherwise is how a team ends up
maintaining software it was not hired to write.
<details class="deeper">
<summary>If you write the business case: which benefits survive scrutiny, and the one to lead with</summary>

Automation business cases are usually built on hours saved, which is the benefit
most vulnerable to the maintenance slope and the easiest for a sceptical finance
person to discount.

Three of the seven survive scrutiny better and it is worth knowing which.

**Reaction time** is the strongest security-specific claim and it is not about
efficiency at all. A containment action applied in seconds rather than in hours
closes a window an attacker is inside, and the value is the difference between an
incident contained at one machine and one contained at forty. That argument does
not depend on anybody's hourly rate.

**Standard configuration** compounds rather than saving. Machines built the same
way can be compared against a baseline meaningfully, patched as a set, and
reasoned about, which is what every other control on this exam quietly assumes. It
is difficult to put a number on and it is the benefit that makes the rest of a
security programme possible.

**Consistency at scale** is the observation that a manual process degrades as
volume rises while an automated one does not. That is why the case is strongest
before the volume arrives, and why it is usually made after.

The one to lead with depends on the audience and it is rarely hours. For a
security committee, reaction time. For an infrastructure leader, standard
configuration. For finance, the hours, with a maintenance figure attached, because
presenting a payback without one invites the discount they will apply anyway.

The claim to avoid overstating is headcount. Automation changes what a team does
rather than how many people it needs, and a case built on reducing headcount tends
to be tested against that promise later, at which point the team is maintaining
software with fewer people than before.

</details>


## When not to automate

The objective's second list is unusual in naming costs explicitly, and the useful
form of it is a set of conditions under which the answer is no.

**When it runs rarely.** Something performed twice a year does not repay eighty
hours, and the automation will have rotted between uses anyway.

**When the process is still changing.** Automating a process that is being
redesigned means rewriting the automation each time, and it also freezes a design
that was not finished.

**When the failure mode is worse than the manual one.** Anything destructive
applied uniformly is a category worth pausing on. A manual deletion removes one
thing. An automated one removes everything matching a pattern, and the pattern was
wrong.

**When nobody will own it.** An automation with no owner is a liability with a
schedule, and this is the condition that produces the script in the hook.
<details class="deeper">
<summary>If automation is your only route: what a single point of failure looks like here, and the cheap insurance</summary>

Automation creates dependencies that are invisible while everything works, and the
single point of failure is rarely the script itself.

Work outward from a nightly provisioning job and count what it depends on. The
scheduler that runs it. The machine it runs on. The credential it authenticates
with. The network path to each system it touches. The system of record it reads
from. Any one of those failing stops the process, and only the first two are
things anybody thinks of as the automation.

The credential is the one worth checking first, because it fails in a way that
looks like something else. An expired or revoked key produces authentication
errors from several systems at once, which reads as an outage in those systems
rather than as an automation problem, and the investigation goes to the wrong
place.

The cheap insurance is a documented manual path, and it is cheap only if it is
written before it is needed. Not a full runbook: a page saying what the process
does, which systems it touches, and what a person would type. It takes an hour to
write while the automation is being built and while the author still remembers,
and it is close to impossible to write afterwards from a codebase under time
pressure.

The second piece of insurance is to exercise it. A manual path nobody has ever
followed is an assumption in the same way an untested archive is, and the failure
mode is identical: it is discovered to be wrong at the moment it is needed. Once a
year, run the process by hand for one case and time it. That number is what the
organisation should assume about its recovery, and it is usually a surprise.

</details>


## The script that became the process

Two years of daily runs, no current employee has read it, and it works. The
interesting question is what happens next, and there are three answers, all bad.

**It fails.** Something it depends on changes, it stops, and the process it
performs has to be done by hand by people who have never done it. The knowledge of
how the process works is inside the program, expressed in code, and reading it
under pressure is not the same as knowing it.

**It needs to change.** A new system is added, a group is renamed, a policy
changes. Modifying code nobody understands is either avoided, which means the
policy is not applied, or attempted nervously, which is how the wrong-argument
failure from the previous topic happens.

**It keeps working and drifts.** Nothing fails, nothing needs changing, and the
rules it enforces are the rules of two years ago. It is a security control
executing yesterday's policy perfectly, and nothing about a working automation
prompts anybody to ask whether the policy is still right.

**That third one is technical debt with a security label on it**, and it is the
hardest to notice, because every observable signal says the control is healthy.

What makes an automation supportable is unglamorous and short. Somebody's name on
it. A second person who has read it. A test that fails loudly when it breaks
rather than silently doing nothing. A written description of what it is supposed
to do, separate from the code, so that its behaviour can be compared against its
intent. And a review date, for the same reason an exception has one.

## Prove it

**Run it.** Compute the payback for something you have automated or are proposing
to. Then compute it again with the maintenance figure doubled, which is the
sensitivity that matters.

**Work it out.** Take an automation your organisation depends on and answer three
questions: who owns it, who else has read it, and how you would perform the
process if it stopped this afternoon. If any answer is uncomfortable, that is the
finding.

**Look it up.** Open SP 800-128 and find what it says about automated tooling
needing to be under configuration management itself. The recursion is the point
and it is the part most home-grown automation skips.

## What trips people up

### 1. Estimating the build and not the maintenance

The build is a step and the maintenance is a slope, and over three years the slope
decides. The same eighty-hour build pays back in month seven or never, depending
on a number nobody wrote down.

### 2. Automating something that runs twice a year

The payback arithmetic does not close, and the automation rots between uses, so
the rare thing you automated is broken on the rare occasion you need it.

### 3. Treating a working automation as a healthy control

It enforces the rules it was given. Nothing about it running successfully asks
whether those are still the rules you want, which is why a review date matters as
much as a monitor.

### 4. Letting the manual process be forgotten

When the automation fails, the process has to happen anyway, performed by people
who have never done it, from knowledge that exists only as code.

### 5. Automating a destructive action without a narrower blast radius

A manual mistake removes one thing. An automated one removes everything matching
the pattern, and the pattern is the part that was wrong.

### 6. Counting the workforce multiplier without changing the job

The team stops performing operations and starts maintaining software. That is
different work, it needs different skills, and pretending it is the same is how
people end up maintaining a system nobody hired them to write.

## Work it through

An automation runs a nightly access reconciliation. It works, it has run for two
years, its author left, and a new compliance requirement means it needs changing.
Nobody wants to touch it.

**The tempting move is to write a new one.** Greenfield is more pleasant than
reading somebody else's code, the requirements are clearer now, and the estimate
will be optimistic because the hard parts of the original are invisible from
outside.

**The move that works reads the old one first, deliberately, as a task with time
allocated.** Not to modify it: to write down what it actually does, including the
special cases, which are where the accumulated knowledge lives. Every unexplained
condition in it is a lesson somebody learned the hard way, and a rewrite that does
not know about them will rediscover each one in production.

**Then the decision is informed.** Perhaps the original is fine and needs one
addition. Perhaps it is genuinely unmaintainable and a rewrite is right, and now
the rewrite has a specification derived from a working system rather than from
what people remember the requirements to have been.

**What this rejects is the rewrite as the default response to unfamiliar code.**
Unfamiliarity is a property of the reader rather than of the code, and it is
cheaper to fix by reading than by rebuilding.

The residual worth writing down: whatever the outcome, the failure that produced
this situation is that one person wrote it and nobody else ever read it. If the
new version is written the same way, this conversation happens again in two years
with different names in it.

## Try it

**Compute a payback you already committed to.** Take something automated last year
and work out the actual figures. The gap between the estimate and the reality is
the most useful number available for the next proposal.

**Find the unowned automation.** Look at scheduled jobs on any system you run and
find one whose owner has left. Most estates have several.

**Ask how the process would run without it.** For one automation, ask whoever
depends on it how they would do the work if it stopped today. The quality of the
answer is a measure of the risk.

**Look for the drift.** Take one automated control and compare what it enforces
with what the current policy says. Two years is usually enough for them to differ.

## Check yourself

<details class="qa">
<summary>Which input decides an automation's payback period, and why is it usually missing?</summary>

The maintenance cost. In the capture, the same eighty-hour build pays back in
month seven at four hours a month, month ten at eight, and never at seventeen.

It is missing because at the point of deciding there is nothing to maintain, so
the figure is a guess about a thing that does not exist, while the build cost is
an estimate of work an engineer can picture. The correction is to measure the
actual maintenance of something already running and use it on the next proposal.

</details>

<details class="qa">
<summary>Name two situations where the right answer is not to automate.</summary>

When the process runs rarely, because the payback arithmetic does not close and
the automation rots between uses, so it is broken on the rare occasion it is
needed. And when the process is still being redesigned, because the automation
gets rewritten each time and freezes a design that was not finished.

Two more: when the automated failure mode is worse than the manual one, which
applies to anything destructive, and when nobody will own it.

</details>

<details class="qa">
<summary>What is the quietest failure mode of a long-running automation?</summary>

Drift. It keeps working, nothing fails, nothing needs changing, and the rules it
enforces are the rules from when it was written. It is a security control
executing an old policy perfectly.

Every observable signal says the control is healthy, which is why a review date
matters as much as monitoring. Nothing about successful execution asks whether the
policy is still the one you want.

</details>

<details class="qa">
<summary>What makes an automation supportable after its author leaves?</summary>

A named owner. A second person who has read it. A test that fails loudly rather
than the automation silently doing nothing. A written description of intent
separate from the code, so behaviour can be compared against what it was supposed
to do. And a review date.

None of that is technically difficult and all of it is skipped, because at the
time of writing the author understands it completely and the cost of the omission
lands on somebody else.

</details>

<details class="qa">
<summary>The workforce multiplier claim is true. What does it change?</summary>

What the team does. They stop performing operations and start maintaining software
that performs them, which is different work requiring different skills.

That is a real benefit and it needs to be stated when the automation is proposed,
because a team that was hired to run systems and now maintains a codebase without
that being acknowledged will maintain it badly, and the automation acquires the
maintenance slope that decides the payback.

</details>

## References

- [SP 800-128](https://csrc.nist.gov/pubs/sp/800/128/upd1/final) - NIST, security-focused configuration management, including automated tooling being under configuration management itself. Free. Accessed 2026-08-25.
- [SP 800-160 Vol. 1 Rev. 1](https://csrc.nist.gov/pubs/sp/800/160/v1/r1/final) - NIST, engineering trustworthy secure systems, for supportability and lifecycle cost as engineering properties. Free. Accessed 2026-08-25.
- [SP 800-204C](https://csrc.nist.gov/pubs/sp/800/204/c/final) - NIST, DevSecOps implementation, for automated controls in a pipeline and what maintaining them involves. Free. Accessed 2026-08-25.

**Where the content came from.** The payback figures are computed on an AlmaLinux
10.2 container by a short model whose inputs are stated in its own output: forty
runs a month at twenty five minutes each, an eighty-hour build, and a maintenance
figure passed as an argument. The three maintenance values are chosen to show the
sensitivity rather than measured from a real project, which the topic says
directly, and the numbers in the figure are the same model's output rather than a
drawing. There is no platform comparison on this page, because nothing here runs
against a machine.

**If you also work on networks.** The Network+ track's
[lifecycle, change and configuration management](/learn/network-plus/lifecycle-change-and-configuration-management)
covers the change process an automation has to live inside, which is where a
review date turns into an actual review.
