---
title: "Automating the boring and dangerous parts"
description: "What automation actually buys, why the same property that makes it safe to re-run makes a mistake arrive everywhere at once, which step in a provisioning flow should stay human, and what a guard rail is that a policy is not."
deck: "Forty new starters in one week, each needing eleven accounts"
track: "security-plus"
level: "working"
order: 590
objectives:
  - "Name the use cases this objective lists and say what each one removes"
  - "Explain idempotence and why it is what makes automation safe to re-run"
  - "Say why an automated mistake is worse than a manual one"
  - "Decide which step in a flow should stay a human decision"
  - "Distinguish a guard rail from a policy"
  - "Say what an API key automates beyond what was intended"
prerequisites: ["accounts-from-joiner-to-leaver"]
tags: ["security-plus", "security", "operations", "automation"]
updated: 2026-08-25
draft: false
examObjectives:
  - exam: "sy0-701"
    domain: "4.0"
    objective: "4.7"
sources:
  - title: "SP 800-204C, Implementation of DevSecOps for a Microservices-based Application"
    url: "https://csrc.nist.gov/pubs/sp/800/204/c/final"
    publisher: "NIST"
    accessed: 2026-08-25
    tier: 1
  - title: "SP 800-128, Guide for Security-Focused Configuration Management"
    url: "https://csrc.nist.gov/pubs/sp/800/128/upd1/final"
    publisher: "NIST"
    accessed: 2026-08-25
    tier: 1
  - title: "SP 800-53 Rev. 5, Security and Privacy Controls"
    url: "https://csrc.nist.gov/pubs/sp/800/53/r5/upd1/final"
    publisher: "NIST"
    accessed: 2026-08-25
    tier: 1
  - title: "useradd manual page"
    url: "https://man7.org/linux/man-pages/man8/useradd.8.html"
    publisher: "man7.org"
    accessed: 2026-08-25
    tier: 1
symptoms:
  - symptom: "A configuration error reached every machine at once"
    anchor: "the-same-property-both-ways"
  - symptom: "An integration key can do far more than the integration needs"
    anchor: "the-key-that-automates-more-than-intended"
---

> **Before you read.** Forty people start on the same Monday. Each one needs
> eleven accounts across eleven systems, each created by a different team, each
> with its own request form.
>
> Somebody proposes automating it.
>
> **What does that fix, and what does it make worse?**

It fixes the four hundred and forty manual operations and the errors in them. What
it makes worse is the consequence of getting the rule wrong, because the rule is
now applied four hundred and forty times without anybody looking at any individual
result.

### Some words you will need

<dl class="terms">
<dt>idempotence</dt>
<dd>Running something twice produces the same result as running it once. The property that makes automation safe to re-run.</dd>
<dt>guard rail</dt>
<dd>A constraint the automation cannot violate, enforced by the system rather than by intention.</dd>
<dt>provisioning</dt>
<dd>Creating accounts and resources with the access a role needs.</dd>
<dt>orchestration</dt>
<dd>Running a sequence of steps across several systems in the right order.</dd>
<dt>continuous integration</dt>
<dd>Building and testing every change automatically as it is proposed.</dd>
<dt>API key</dt>
<dd>A credential a program uses to act on a system. Frequently long-lived and broadly scoped.</dd>
<dt>escalation</dt>
<dd>Passing something to a person or a higher tier when the automation cannot decide.</dd>
<dt>ticket creation</dt>
<dd>Automation raising a record so the work is visible and attributable.</dd>
</dl>

## What breaks without this

**People do the same thing four hundred times.** Some of those four hundred are
wrong, and the errors are individually small and collectively invisible.

**A leaver is missed because the process is manual.** Eleven systems, eleven
people to remember, and the failure is one of them being on holiday.

**A mistake reaches everywhere at once.** The automation was correct in testing
and the input was wrong, and it applied the wrong rule perfectly.

**An integration key can do anything.** It was created broadly because narrowing
it was fiddly, and it is now the most powerful credential in the estate.

## What automation actually removes

The objective lists a set of use cases and they are worth grouping by what each
one removes rather than reading as a list.

**Provisioning and de-provisioning** remove the delay and the omission. A leaver
handled by automation is handled on the day, in every system in scope, whether or
not anybody remembered.

**Guard rails** remove the possibility rather than the intention. A policy says
storage should not be public. A guard rail refuses to create public storage. The
difference is that one of them survives somebody being in a hurry.

**Security groups and access changes** remove the transcription. The role decides
the groups, the automation applies them, and nobody types a group name.

**Ticket creation and escalation** remove the invisibility. Work that happens
automatically without a record is work nobody can audit, and raising a ticket for
an automated action is what makes it attributable afterwards.

**Enabling and disabling services** removes the drift. A service that should not
be running is stopped every time the automation runs, rather than the once
somebody noticed.

**Continuous integration and testing** remove the gap between the change and the
check, which is the cost argument from the application security topic.

**Integrations and APIs** are what make all of the above possible and they are
also the part with the security consequence, which is the last section of this
page.
<details class="deeper">
<summary>If you automate the leaver side: the ordering that matters, and the reversal you will need</summary>

Joiner automation saves effort and leaver automation removes risk, which is why
the second one is worth building first and almost never is.

The ordering inside a leaver run is the part that repays thought. Disable
authentication first, everywhere, because that is the step that stops new access
and it is cheap to reverse. Terminate existing sessions second, since the account
topic showed that disabling alone leaves whatever is already running. Remove group
memberships third. And leave deletion for much later, or never, because deleted
accounts take their audit history with them and an investigation six months later
will want it.

The reversal is the part that gets discovered rather than designed. Leaver
automation will eventually run against somebody who has not left: a wrong date in
the system of record, a contractor whose extension was approved late, somebody who
resigned and withdrew it. When that happens the person cannot work, they are
usually distressed, and somebody is going to fix it in a hurry.

Design the reversal in advance and it is a button. Do not, and it is an afternoon
of somebody manually reconstructing group memberships from memory, which is how
privilege creep gets a fresh start.

Two details that make the reversal possible. Record what was removed rather than
only that removal happened, so restoring is a replay rather than a reconstruction.
And make the automation act on a state change rather than on a date, so a
correction in the system of record propagates the same way the original did.

The wider point is the one worth carrying: any automation that removes access will
occasionally remove it wrongly, and the quality of a leaver process is measured as
much by how quickly a mistake is undone as by how reliably it fires.

</details>


<details class="deeper">
<summary>If you build the pipeline: where a guard rail belongs, and why the earlier one is weaker</summary>

Guard rails can sit at several points and the instinct is to put them as early as
possible, which is right for cost and wrong for guarantees.

A check in the pipeline runs when a change is proposed, catches the problem while
it is cheap, and gives immediate feedback to the person who wrote it. That is
where most checks belong and it is genuinely valuable. It is also bypassable: the
pipeline is one route to the platform, and anybody with credentials can reach the
platform directly, which during an incident is exactly what happens.

A control at the platform is enforced by the thing being changed. A policy engine
that refuses to create public storage refuses regardless of how the request
arrived, including from somebody typing commands at two in the morning. It cannot
be bypassed by taking a different route because there is no different route.

The distinction matters most for the failure people actually meet. Nobody
deliberately circumvents the pipeline to do something forbidden. They circumvent
it because production is down and the pipeline takes eleven minutes, and whatever
the pipeline would have caught is not caught.

So the arrangement that holds is both, with different jobs. The pipeline check is
the fast feedback that keeps mistakes cheap and teaches the team. The platform
control is the guarantee, and it should be short, because every platform-level
rule is one that cannot be worked around and will therefore eventually block
something legitimate at an inconvenient moment.

The corollary worth writing into a design: a platform guard rail needs a
documented way to be lifted deliberately, by somebody with authority, with an
alert. Without one, the first time it blocks something urgent, somebody with
administrative access removes it entirely and it does not come back.

</details>

## The same property both ways

Here is a provisioning run, twice.

<details class="predict">
<summary>The same provisioning script is run twice against the same manifest. Predict what the second run does.</summary>

```bash
# AlmaLinux 10.2, x86_64
$ echo "first run:"; provision; echo "second run, same manifest:"; provision; echo; echo "which is the property that makes automation safe to re-run:"; for u in avery blake casey devon ellis; do printf "  %-7s %s\n" "$u" "$(id -Gn $u)"; done
first run:
created 5, already present 0
second run, same manifest:
created 0, already present 5

which is the property that makes automation safe to re-run:
  avery   avery staff engineering
  blake   blake staff finance
  casey   casey staff sales
  devon   devon staff support
  ellis   ellis staff engineering
```

**Nothing, and reporting that it did nothing is the point.** Five created on the
first run, five already present on the second, and the group memberships are
identical.

That property is idempotence, and it is what separates automation you can run from
a script you have to be careful with. A script that is not idempotent has to be
run exactly once, which means somebody has to know whether it ran, which means the
thing you automated now needs a human to track it.

Idempotence is also what makes automation usable as a control rather than as a
convenience. If the run is safe to repeat, it can be scheduled, and a scheduled
run means drift is corrected continuously rather than discovered at an audit. The
service somebody enabled by hand on Tuesday is disabled again on Wednesday, and
nobody had to notice.

The habit worth carrying into any automation you write: make the operation check
the current state before acting, so that running it against a machine already in
the right state is a no-op that says so. That single design choice converts a
one-shot script into something that can be run every hour forever.

</details>

Now the same script with one argument wrong.

```bash
# AlmaLinux 10.2, x86_64
$ echo "the same script, run with one argument set by mistake:"; provision finance; echo; echo "and the result, five accounts later:"; for u in avery blake casey devon ellis; do printf "  %-7s %s\n" "$u" "$(id -Gn $u)"; done; echo; echo "how many accounts the finance group now holds:"; getent group finance | cut -d: -f4 | tr "," "\n" | grep -c .
the same script, run with one argument set by mistake:
created 5, already present 0

and the result, five accounts later:
  avery   avery staff finance
  blake   blake staff finance
  casey   casey staff finance
  devon   devon staff finance
  ellis   ellis staff finance

how many accounts the finance group now holds:
5
```

**Five accounts, all in finance, in one command.** The script is not broken. It did
exactly what it was told, correctly, repeatably, and quickly.

**That is the risk automation introduces and it is the same property viewed from
the other side.** A person creating five accounts by hand would probably notice
that the sales hire was being put in finance, because a person reads each one.
Automation reads none of them, applies the rule uniformly, and finishes before
anybody could intervene.

Scale it. This example is five accounts because a demonstration needs to be small.
The real case is the forty from the top of the page, or four thousand machines
receiving a configuration change, and the difference between a manual mistake and
an automated one is that the manual one affects the record somebody was looking at
when they made it.

<figure class="learn-figure">
<svg viewBox="0 0 720 322" role="img" aria-labelledby="auto-title" style="width:100%;height:auto;">
<title id="auto-title">A provisioning request end to end with six automated steps and one that stays a human decision, and what each step draws its input from</title>
<g fill="currentColor">
<text x="14" y="20" font-size="11">one new starter, seven steps, and the one that stays a person</text>
<rect x="14" y="40" width="188" height="28" rx="4" fill="var(--accent)" fill-opacity="0.11" stroke="var(--accent)" stroke-opacity="0.7" stroke-width="1.2"/>
<text x="108" y="58" text-anchor="middle" font-size="8.5">ticket raised</text>
<text x="216" y="58" font-size="8" fill-opacity="0.65">automated</text>
<text x="292" y="58" font-size="8" fill-opacity="0.8">a form, validated on submission</text>
<rect x="14" y="74" width="188" height="28" rx="4" fill="var(--red)" fill-opacity="0.20" stroke="var(--red)" stroke-opacity="0.7" stroke-width="1.6"/>
<text x="108" y="92" text-anchor="middle" font-size="8.5">manager approval</text>
<text x="216" y="92" font-size="8" fill-opacity="0.95">manual</text>
<text x="292" y="92" font-size="8" fill-opacity="0.8">the only human decision left</text>
<rect x="14" y="108" width="188" height="28" rx="4" fill="var(--accent)" fill-opacity="0.11" stroke="var(--accent)" stroke-opacity="0.7" stroke-width="1.2"/>
<text x="108" y="126" text-anchor="middle" font-size="8.5">account created</text>
<text x="216" y="126" font-size="8" fill-opacity="0.65">automated</text>
<text x="292" y="126" font-size="8" fill-opacity="0.8">from the approved fields</text>
<rect x="14" y="142" width="188" height="28" rx="4" fill="var(--accent)" fill-opacity="0.11" stroke="var(--accent)" stroke-opacity="0.7" stroke-width="1.2"/>
<text x="108" y="160" text-anchor="middle" font-size="8.5">groups assigned</text>
<text x="216" y="160" font-size="8" fill-opacity="0.65">automated</text>
<text x="292" y="160" font-size="8" fill-opacity="0.8">from the role, not from the request</text>
<rect x="14" y="176" width="188" height="28" rx="4" fill="var(--accent)" fill-opacity="0.11" stroke="var(--accent)" stroke-opacity="0.7" stroke-width="1.2"/>
<text x="108" y="194" text-anchor="middle" font-size="8.5">mailbox and licence</text>
<text x="216" y="194" font-size="8" fill-opacity="0.65">automated</text>
<text x="292" y="194" font-size="8" fill-opacity="0.8">provisioned by the same run</text>
<rect x="14" y="210" width="188" height="28" rx="4" fill="var(--accent)" fill-opacity="0.11" stroke="var(--accent)" stroke-opacity="0.7" stroke-width="1.2"/>
<text x="108" y="228" text-anchor="middle" font-size="8.5">access recorded</text>
<text x="216" y="228" font-size="8" fill-opacity="0.65">automated</text>
<text x="292" y="228" font-size="8" fill-opacity="0.8">written to the inventory</text>
<rect x="14" y="244" width="188" height="28" rx="4" fill="var(--accent)" fill-opacity="0.11" stroke="var(--accent)" stroke-opacity="0.7" stroke-width="1.2"/>
<text x="108" y="262" text-anchor="middle" font-size="8.5">welcome sent</text>
<text x="216" y="262" font-size="8" fill-opacity="0.65">automated</text>
<text x="292" y="262" font-size="8" fill-opacity="0.8">and the ticket closes itself</text>
<text x="14" y="296" font-size="10" fill-opacity="0.85">the approval is manual because it is the only step that requires judgement</text>
<text x="14" y="316" font-size="9" fill-opacity="0.7">everything below it is derived from the approved request, which is why it can be repeated safely</text>
</g></svg>
<figcaption>A provisioning flow with one step deliberately left manual. Everything below the approval is derived from the approved request rather than typed again, which is what makes the whole sequence repeatable and what removes the transcription errors. The approval stays human because it is the only step in the flow that requires judgement about whether this person should have this access at all, and it is the only place where a wrong answer is caught before it is applied everywhere. Automating it is possible and it converts the flow into one that cannot say no.</figcaption>
</figure>

## What stays human

The useful question is not how much of a flow can be automated but which step
would catch a mistake, and that step is almost always an approval.

**Automate the operations and keep the decision.** Creating an account, assigning
groups, provisioning a mailbox and recording the result are operations: given the
inputs, there is one right answer and no judgement. Whether this person should
have this access is a decision, and it is the only place in the flow where
somebody would notice the sales hire being put in finance.

**The test for whether a step should stay human** is whether a wrong answer at that
step is caught anywhere later. If not, it is the last line of defence and
automating it removes the last opportunity to disagree.

There is a related failure worth naming, because it defeats the design. An
approval step that is always approved is not a control, it is a delay, and
approvers who receive twenty requests a day with no context approve all of them.
That is the same shape as the attestation problem, and the same fixes apply:
enough information to decide, few enough requests to read, and a default that is
not approval.
<details class="predict">
<summary>An approval step receives twenty requests a day, each naming a group and nothing else. Predict the approval rate, and what the step is actually providing.</summary>

**Close to a hundred percent, and what it provides is delay.**

The approver is being asked a question they cannot answer. A request naming
`FIN-GL-POST` and a person's name contains no information about whether that
person should have it, so the honest answer is that they do not know. Twenty times
a day, alongside their actual job, with a queue that grows if they hesitate, the
only sustainable behaviour is to approve.

That is worth separating from a genuine control, because the two produce identical
records. An approval log showing twenty approvals a day for two years demonstrates
that the step ran. It demonstrates nothing about whether any request was ever
declined for a reason.

Three changes make the step real, and they are the same three as the access review
in the account topic, which is not a coincidence. Say what the entitlement permits
rather than naming a group. Route the request to somebody who knows the job rather
than to whoever owns the system. And reduce the volume so the remaining ones can
be read, by pre-approving the ordinary case through role definitions and sending
only the exceptions to a person.

The measure that tells you which kind you have is the decline rate. A step that
has never declined anything is not evaluating anything, and that number is
available in any workflow system and almost never looked at.

</details>

<details class="deeper">
<summary>If you decide what stays human: the two questions that settle it, and the trap in the second</summary>

Deciding which steps to automate produces long arguments and two questions settle
most of them.

**Does this step have one right answer given its inputs?** Creating an account
from an approved request does. Assigning groups from a role does. Deciding whether
somebody should have finance access does not, because the inputs do not contain
the answer: they contain a request, and the judgement is about whether the request
is reasonable.

**Would a wrong answer here be caught later?** If yes, automating it is low risk,
because something downstream is still looking. If no, this step is the last line
of defence and automating it removes the last opportunity to disagree.

The trap is in the second question, and it is worth naming because it produces
confident bad decisions. People answer it by describing what should happen rather
than what does. "A wrong group assignment would be caught in the quarterly access
review" is true in the sense that the review exists, and the account topic showed
what those reviews mostly are. If the downstream catch is a control that has never
declined anything, it is not a catch.

So the honest form of the second question is whether a wrong answer at this step
has ever actually been caught later, and the evidence is in the records. A team
that can point to three occasions when a review reversed a grant has a real
downstream control. A team that cannot has one step, and it is this one.

There is one more consideration that overrides both questions. A step that is
performed under time pressure during incidents should be automated even if it
requires judgement, because the judgement will be poor at three in the morning and
a consistent automated answer beats an inconsistent human one. What that step
needs instead is review afterwards, which is the same trade as self-service
elevation.

</details>


## The key that automates more than intended

Everything above runs as something. That something holds a credential, and the
credential is where automation's security consequence actually lands.

**An automation credential is usually broader than the automation.** The narrow
permission set was fiddly to work out, the broad one worked immediately, and the
credential that provisions accounts can typically also delete them, read every
account's attributes, and change anybody's password.

**It is usually long-lived**, because rotating it means coordinating with whatever
uses it, and nobody has the time.

**And it is frequently in a place people can read.** In a repository, in a
pipeline's environment, in a configuration file on a build server. Each of those
is available to more people than the automation is.

The result is that the most powerful credential in an estate is often the one
belonging to a script nobody thinks about. Three things reduce it and none is
exotic. Scope the credential to the operations the automation performs, which is
tedious once and permanent. Use short-lived credentials issued at run time where
the platform offers them, which removes the rotation problem by removing the
standing credential. And treat the automation's identity as a privileged identity
in the access review, because it usually holds more than any person in the
directory.
<details class="deeper">
<summary>If your automation holds credentials: the rotation problem, and what removes it</summary>

Automation credentials are long-lived for a mundane reason. Rotating one means
knowing everything that uses it, updating each, and coordinating so nothing breaks
in between, and nobody has an inventory of what uses a given key.

That produces the state most estates are in: keys created years ago, present in
several pipelines and configuration files, with no owner and no rotation, and a
strong reluctance to touch them because the blast radius of getting it wrong is
unknown.

What removes the problem is not a better rotation process. It is not having a
standing credential at all. Every major platform now offers a way for a workload
to obtain a short-lived credential at run time by proving what it is: a token from
the platform's own metadata service, a federated assertion from the pipeline's
identity, a certificate issued to the machine. The credential lasts minutes,
nothing is stored anywhere, and rotation stops being an operation because there is
nothing persistent to rotate.

Two practical notes for getting there. Migrate the highest-privilege credential
first rather than the easiest, because the value is concentrated there and the
easy ones tend to be the harmless ones. And when a long-lived key genuinely cannot
be removed, because a third party requires one, treat it as an exception with an
owner and a date rather than as the normal case, so it is visible rather than
merely tolerated.

The audit question worth being able to answer, because it is the one that reveals
the position: how many long-lived credentials exist, who owns each, and when was
each last used. Most organisations cannot answer the third part, and the ones that
can usually discover that a third of them have not been used in a year, which
makes the first removals easy.

</details>


## Prove it

**Run it.** Write a five-line provisioning script that checks whether an account
exists before creating it, and run it twice. The second run reporting no changes
is idempotence, and it is worth seeing rather than reading about.

**Work it out.** Take a piece of automation you rely on and list what its
credential can do beyond what the automation actually does. The gap is the part
somebody inherits if they obtain it.

**Look it up.** Open SP 800-128 and find what it says about automated configuration
management and about the record it produces. The record is the part most home-grown
automation omits.

## What trips people up

### 1. Writing automation that cannot be re-run

If it has to run exactly once, somebody has to track whether it ran, and the thing
you automated now needs a human minding it. Check state before acting.

### 2. Assuming a correct script means a correct outcome

The capture above put five people in finance because one argument was wrong. The
script was correct throughout and the input was not, and nothing in the path read
any individual result.

### 3. Confusing a policy with a guard rail

A policy says storage should not be public. A guard rail refuses to create public
storage. Only one of them survives somebody being in a hurry.

### 4. Automating the approval

It is the only step in most flows that requires judgement, and it is the only
place a wrong request is caught before it is applied. Automating it produces a
flow that cannot say no.

### 5. Leaving an approval step that is always approved

That is a delay rather than a control. It needs enough context to decide, few
enough requests to read, and a default that is not approval.

### 6. Scoping the automation's credential broadly

It was faster to create and it makes the automation's identity the most powerful
thing in the estate, held in a pipeline configuration more people can read than
can perform the operations by hand.

## Work it through

Forty starters a month, eleven systems, and four hundred and forty manual
operations. You have been asked to automate the joiner process and there is an
appetite for doing all of it.

**The tempting move is to automate end to end including the approval.** It removes
the last delay, the flow completes in minutes, and it produces a system that
grants whatever was requested. The first time a request is wrong, or a request is
submitted by somebody who should not be submitting it, there is nothing in the
path that would have noticed.

**The move that works automates every operation and keeps one decision.** The
request is a validated form, the approval is a person, and everything after the
approval is derived from the approved fields rather than typed again. That removes
the transcription errors, which is where most manual failures actually come from,
and keeps the step where judgement lives.

**Then the leaver side is where the value is.** Joiner automation saves effort.
Leaver automation removes a risk, because the failure it prevents is access
persisting after somebody has gone, and it is the half organisations postpone
because nobody is waiting for it.

**What this rejects is completeness as the goal.** A flow that is ninety percent
automated with a human approval is better than one that is a hundred percent
automated, and it is worth stating that in the design document rather than
defending it later as an omission.

The residual is the automation's own credential. It can now create accounts and
assign groups across eleven systems, which makes it more powerful than any
administrator, and it needs to appear in the access review as a privileged
identity with an owner. Leaving it out because it is not a person is how the most
powerful credential in an estate goes unreviewed.

## Try it

**Make something idempotent.** Take a script you have and add a state check before
each action. Then run it twice and confirm the second run changes nothing.

**Find your broadest automation credential.** Look at what your continuous
integration system authenticates as and what that identity can do. Compare it with
what the pipelines actually need.

**Look for a guard rail.** Try to do something your policy forbids in a system you
own. If it succeeds, you have a policy. If it refuses, you have a guard rail.

**Count the approvals.** For any automated flow with an approval step, find out
what proportion are approved. If it is close to all of them, the step is a delay.

## Check yourself

<details class="qa">
<summary>What is idempotence and why does it matter for automation?</summary>

Running the operation twice produces the same result as running it once. In the
capture on this page the second run creates nothing and reports five accounts
already present.

It matters because a script that must run exactly once needs somebody to track
whether it ran, which reintroduces the human the automation removed. An idempotent
run can be scheduled, which turns automation from a convenience into a control
that corrects drift continuously.

</details>

<details class="qa">
<summary>Why is an automated mistake worse than a manual one?</summary>

Because it is applied uniformly and quickly, with nobody reading any individual
result. The capture shows one wrong argument putting five people into finance, and
the script was correct throughout.

A person creating those accounts by hand reads each one and has a reasonable
chance of noticing that a sales hire is being put in finance. Automation reads
none of them and finishes before anybody could intervene.

</details>

<details class="qa">
<summary>What distinguishes a guard rail from a policy?</summary>

A policy states what should happen and relies on people following it. A guard rail
is enforced by the system, so the disallowed thing cannot be done regardless of
intention, urgency or seniority.

The practical test is to try the forbidden action. If it succeeds and you feel
guilty, that was a policy.

</details>

<details class="qa">
<summary>Which step in a provisioning flow should stay a human decision, and why?</summary>

The approval. Every other step is an operation with one right answer given the
inputs, and the approval is the only one requiring judgement about whether this
person should have this access at all.

It is also the only place a wrong request is caught before it is applied
everywhere. The caveat is that an approval which is always granted is a delay
rather than a control, and it needs context, volume low enough to read, and a
default that is not approval.

</details>

<details class="qa">
<summary>Why is an automation's credential often the most powerful in an estate?</summary>

Because it was scoped broadly to get the automation working, it is long-lived
because rotating it means coordinating with everything that uses it, and it is
stored where a pipeline can read it, which is a place more people can reach than
can perform the operations manually.

The three reductions are scoping it to the operations actually performed, using
short-lived credentials issued at run time where available, and including the
automation's identity in the privileged access review, which is usually omitted
because it is not a person.

</details>

## References

- [SP 800-204C](https://csrc.nist.gov/pubs/sp/800/204/c/final) - NIST, DevSecOps implementation, for automated checks in a pipeline and what they are placed to catch. Free. Accessed 2026-08-25.
- [SP 800-128](https://csrc.nist.gov/pubs/sp/800/128/upd1/final) - NIST, security-focused configuration management, for automated configuration and the record it produces. Free. Accessed 2026-08-25.
- [SP 800-53 Rev. 5](https://csrc.nist.gov/pubs/sp/800/53/r5/upd1/final) - NIST, for account management and least privilege as they apply to non-human identities. Free. Accessed 2026-08-25.
- [useradd(8)](https://man7.org/linux/man-pages/man8/useradd.8.html) - the command the provisioning script wraps, and its group handling. Free. Accessed 2026-08-25.

**Where the content came from.** Both blocks run the same provisioning script on an
AlmaLinux 10.2 container against a five-row manifest written for the topic. The
second block passes an argument that overrides the team, which is the mistake being
demonstrated, and the topic says so rather than presenting it as a bug that was
found. There is no platform comparison on this page, because the property being
shown is a property of how the automation is written rather than of the system it
runs against.

**If you also work on Linux.** The Linux+ track's
[scripts that do real work](/learn/linux-plus/scripts-that-do-real-work) covers
writing the kind of script this topic runs, including argument handling, which is
what went wrong in the second block.
