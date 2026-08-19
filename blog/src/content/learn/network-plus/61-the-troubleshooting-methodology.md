---
title: "The troubleshooting methodology"
description: "Everything is broken and you have to start somewhere. CompTIA's seven steps in order, what each one is actually guarding against, why testing the theory can send you back a step, and why the step everyone skips is the one that pays next time."
deck: "Everything is broken and you have to start somewhere"
track: "network-plus"
level: "working"
order: 620
objectives:
  - "List CompTIA's seven troubleshooting steps in order"
  - "Say what each step is guarding against"
  - "Explain why testing a theory can send you back rather than forward"
  - "Say why duplicating the problem and questioning the obvious come first"
  - "Explain why documenting the outcome is the step that pays later"
prerequisites: ["network-documentation-and-diagrams"]
tags: ["network-plus", "networking", "troubleshooting", "methodology"]
updated: 2026-08-19
draft: false
examObjectives:
  - exam: "n10-009"
    domain: "5.0"
    objective: "5.1"
sources:
  - title: "CompTIA Network+ N10-009 Exam Objectives"
    url: "https://www.comptia.org/certifications/network"
    publisher: "CompTIA"
    accessed: 2026-08-19
    tier: 1
  - title: "ITILv4 Foundation, incident management guidance"
    url: "https://www.axelos.com/certifications/itil-service-management"
    publisher: "Axelos"
    accessed: 2026-08-19
    tier: 2
symptoms:
  - symptom: "A fault is fixed and returns because nobody recorded what was done"
    anchor: "step-7-document-and-why-it-is-skipped"
  - symptom: "A theory is tested, disproved, and the work stalls"
    anchor: "the-loop-hiding-in-a-list"
---

> **Before you read.** A call comes in: "the network is down." You have no more
> than that. Fifteen things could produce it, two of them are in another team's
> equipment, and the person who called cannot tell you anything more specific
> than that something they need is not working.
>
> **You have to start somewhere, and where you start decides how long this takes.
> Where do you start?**

Troubleshooting has a method, and the reason it is on the exam as its own
objective is that the method is what separates fixing a fault from changing things
until the symptom goes away. The second one works often enough to be a habit and
it is how a small fault becomes an outage. This topic is the method, in CompTIA's
order, with what each step is actually for.

### Some words you will need

<dl class="terms">
<dt>symptom</dt>
<dd>What is observed. Not the fault, and often several steps away from it.</dd>
<dt>theory of probable cause</dt>
<dd>A specific guess about what is wrong, made so it can be tested and disproved.</dd>
<dt>discriminating test</dt>
<dd>A test whose result rules candidates in or out, rather than one that just gathers more detail.</dd>
<dt>escalation</dt>
<dd>Handing a problem to someone with the access or knowledge you lack, without losing what you have found.</dd>
<dt>duplicate the problem</dt>
<dd>Reproducing the fault yourself, so you are working on the thing rather than on a description of it.</dd>
</dl>

## What breaks without this

**You fix the symptom and not the fault.** Changing things until the symptom
clears leaves the cause in place, and it comes back, usually worse and usually
when you are not there.

**You work on two problems as if they were one.** Two faults with one symptom will
not respond to any single fix, and treating them together is how an afternoon
disappears.

**The fix is not recorded, so the next person starts from nothing.** The most
expensive part of a recurring fault is that each occurrence is solved from scratch,
because the last solution was never written down.

## The seven steps, and what each one guards against

CompTIA's methodology is seven steps, and the value is not in memorising the list
but in knowing what each one is protecting you from. Here they are in order, with
the mistake each one exists to prevent.

<figure class="learn-figure">
<svg viewBox="0 0 720 452" role="img" aria-labelledby="steps-title" style="width:100%;height:auto;">
<title id="steps-title">The seven troubleshooting steps as a vertical flow, where step three loops back to step two when a theory is not confirmed, so the process is a loop rather than a straight line</title>
<g fill="currentColor">
<text x="14" y="22" font-size="11">seven steps, and the one loop that makes it a method rather than a list</text>
<rect x="150" y="40" width="330" height="34" rx="4" fill="currentColor" fill-opacity="0.06" stroke="currentColor" stroke-opacity="0.7"/>
<text x="166" y="61" font-size="10.5">1  identify the problem</text>
<rect x="150" y="92" width="330" height="34" rx="4" fill="var(--accent)" fill-opacity="0.1" stroke="var(--accent)" stroke-opacity="0.85" stroke-width="1.4"/>
<text x="166" y="113" font-size="10.5">2  establish a theory of probable cause</text>
<rect x="150" y="144" width="330" height="34" rx="4" fill="var(--accent)" fill-opacity="0.1" stroke="var(--accent)" stroke-opacity="0.85" stroke-width="1.4"/>
<text x="166" y="165" font-size="10.5">3  test the theory</text>
<rect x="150" y="196" width="330" height="34" rx="4" fill="currentColor" fill-opacity="0.06" stroke="currentColor" stroke-opacity="0.7"/>
<text x="166" y="217" font-size="10.5">4  plan the fix, and its side effects</text>
<rect x="150" y="248" width="330" height="34" rx="4" fill="currentColor" fill-opacity="0.06" stroke="currentColor" stroke-opacity="0.7"/>
<text x="166" y="269" font-size="10.5">5  implement the fix, or escalate</text>
<rect x="150" y="300" width="330" height="34" rx="4" fill="currentColor" fill-opacity="0.06" stroke="currentColor" stroke-opacity="0.7"/>
<text x="166" y="321" font-size="10.5">6  verify, and prevent a repeat</text>
<rect x="150" y="352" width="330" height="34" rx="4" fill="currentColor" fill-opacity="0.06" stroke="currentColor" stroke-opacity="0.7"/>
<text x="166" y="373" font-size="10.5">7  document findings and outcomes</text>
<g stroke="currentColor" stroke-opacity="0.6" stroke-width="1.4" fill="none">
<path d="M 315 74 V 92"/>
<path d="M 315 126 V 144"/>
<path d="M 315 178 V 196"/>
<path d="M 315 230 V 248"/>
<path d="M 315 282 V 300"/>
<path d="M 315 334 V 352"/>
</g>
<path d="M 150 161 C 96 161 96 109 144 109" stroke="var(--accent)" stroke-width="1.8" fill="none"/>
<path d="M 150 103 l -8 6 l 3 -9" stroke="var(--accent)" stroke-width="1.8" fill="none"/>
<text x="20" y="139" font-size="9.5" fill="var(--accent)">theory not</text>
<text x="20" y="151" font-size="9.5" fill="var(--accent)">confirmed</text>
<text x="496" y="165" font-size="9.5" fill-opacity="0.7">confirmed:</text>
<text x="496" y="177" font-size="9.5" fill-opacity="0.7">go on</text>
</g></svg>
<figcaption>The steps run top to bottom, but step three is a fork, not a waypoint. Testing a theory either confirms it, and you go on to plan the fix, or disproves it, and you go back to step two for a new theory. Drawing it as a straight line of seven boxes hides the one feature that makes it a method: it expects to be wrong and has a defined way to be wrong without losing the thread. The two accented steps are where the actual thinking happens; the rest is discipline around them.</figcaption>
</figure>

**1. Identify the problem.** The guard here is against working on a description
instead of the thing. You gather what changed, question the user for specifics,
and, wherever you can, duplicate the problem so you are watching it yourself. Two
habits live in this step and both are on the exam. Ask what changed, because most
faults follow a change and the change is the fastest route to the cause. And if
there is more than one problem, split them, because two faults sharing one symptom
will defeat any single fix.

**2. Establish a theory of probable cause.** A theory is a specific, testable
guess, and the guard is against the vague one that cannot be wrong. The first move
inside this step is to question the obvious: the cable, the power, the link light,
the thing so simple nobody checks it. The three named approaches to forming a
theory, working down the layers from the application, up the layers from the
physical, or splitting the stack in the middle, are topic 65, and choosing one on
purpose is the difference between a method and a poke.

**3. Test the theory to determine the cause.** This is the step that makes the
whole thing a loop. If the test confirms the theory, you move on. If it does not,
you go back to step two and form another, or you escalate, and the important part
is that a disproved theory is progress, not failure. It has removed a candidate.
The mistake this guards against is deciding the theory was right and looking for
evidence to fit it.

**4. Establish a plan of action, and identify potential effects.** Before touching
anything, decide what you will do and what else it will touch. The guard is against
the fix that solves this and breaks something adjacent, which on a network is
common because everything is connected. A change that reboots a switch fixes one
port and drops forty others, and the plan is where you notice that first.

**5. Implement the solution, or escalate.** Do the thing, or hand it to someone who
can. Escalation is a legitimate outcome of this step, not an admission, and the
skill in it is handing over everything you have found so the next person does not
start over.

**6. Verify full system functionality, and prevent a repeat.** Confirm the fault
is actually gone, from the user's side and not just yours, and where you can, stop
it recurring. The guard is against declaring victory on your own screen while the
user still cannot work.

**7. Document findings, actions, and outcomes.** Write down what was wrong, what you
did, and what happened. This is the step everyone skips and the one that pays,
which is the next section.

## The loop hiding in a list

The single most useful thing to understand about the seven steps is that they are
not a straight line, and the figure above is drawn to make that one point.

Step three, testing the theory, has two exits. One goes forward to the fix. The
other goes back to step two, because the theory was wrong. A methodology that did
not have that loop would be a method for the lucky, useful only when the first
guess is right. The loop is what makes it a method for everyone else: it expects
the first theory to fail sometimes and gives failure a defined next move, which is
another theory or an escalation, rather than a stall.

So a disproved theory is not a setback. Testing whether the gateway is the problem
and finding it is not has removed the gateway from the list, which is exactly the
progress the whole process is made of. The engineers who are slow at this are the
ones who treat a disproved theory as a dead end and stop, or who refuse to let go
of a theory the test just disproved.

<details class="deeper">
<summary>If you already troubleshoot for a living: escalating without dropping the thread, and the change nobody mentioned</summary>

Two things separate an escalation that helps from one that just moves the problem.

The first is that escalation carries context or it wastes everyone's time. Handing
a problem up with "the network is broken" restarts the whole method from step one
in someone else's chair. Handing it up with what you have established, the theories
you have already disproved, and the discriminating test that pointed at their area,
lets them start from where you got to. The work in an escalation is the handover,
not the decision to escalate.

The second is the change nobody admits to. Step one asks what changed, and the
honest answer is frequently unavailable, because the change that caused the fault
was made by someone who did not connect it to the symptom, or who is not saying. A
firewall rule added last night, a switch replaced on the weekend, a certificate
that expired on a schedule set two years ago. The methodology cannot force the
information out, but knowing that most faults follow a change turns the question
from a formality into the most valuable one you ask, and it is why the topics ahead
lean so hard on comparing a broken thing against a working one: the difference
between them is usually the change.

The wider frame for this is incident management, which ITIL and similar frameworks
formalise, and the network methodology is a compatible subset of it. The exam wants
the seven steps; the practice is the same discipline at a larger scale, with the
documentation step feeding a record that outlives any one incident.

</details>

## Step 7, document, and why it is skipped

The last step is the one left undone, and the reason is not laziness. It is that by
step seven the fault is fixed, the pressure is off, the next thing is already
waiting, and writing it up feels like tidying after the work rather than part of it.

That instinct is exactly backwards, and the cost lands on the next person, who is
often you. A fault that recurs is solved from scratch every time it appears, because
each solution evaporated the moment the symptom cleared. The value of documenting is
not to the incident you just closed, which is over. It is to the identical incident
in four months, which becomes a five-minute lookup instead of a fresh afternoon.

What is worth recording is small and specific: what the symptom actually was, what
the cause turned out to be, what fixed it, and anything you disproved on the way, so
the next person does not re-test a theory you already killed. That is the record that
makes topic 37's change management and this methodology the same discipline seen
twice, and it is why documentation keeps appearing in this track next to the work
rather than after it.

## Prove it

Nothing here is captured, because the methodology is a process rather than a command,
and the topics that follow are where it gets run against real faults. Two documents
are worth reading behind it.

**The CompTIA objectives, 5.1.** Read the seven steps in the source and note that the
sub-points under step two are the three approaches topic 65 covers, and that step three
explicitly branches on whether the theory was confirmed. The exam tests the order and
the branch, not a definition.

**An incident management summary.** ITIL or any equivalent framework describes the same
loop at organisational scale, and reading one is the fastest way to see that the seven
steps are not a networking invention but the local form of a general discipline. The
part worth noting is that documentation there feeds a knowledge base, which is the
recurring-fault problem solved by making step seven mandatory rather than optional.

## What trips people up

### 1. Working on the description instead of the fault

Until you have duplicated the problem, you are working on what somebody told you, which
is filtered through their understanding. Reproducing it yourself is step one's real
content.

### 2. A theory that cannot be wrong

"Something is misconfigured" is not a theory, because no test disproves it. A theory
names a specific cause so that a specific test can rule it in or out.

### 3. Treating a disproved theory as failure

Disproving a theory removes a candidate, which is the progress the method is made of.
The stall comes from refusing to let go of a theory the test just killed.

### 4. Skipping the plan and its side effects

On a network everything is connected, so the fix that solves one thing frequently
touches others. Step four is where you notice the reboot that fixes one port and drops
forty.

### 5. Verifying on your own screen

The fault is gone when the user can work, not when your test passes. Verification that
does not check the user's side declares victory too early.

### 6. Escalating without the context

Handing a problem up with only the symptom restarts the method in someone else's chair.
Carrying what you found and what you ruled out is the whole value of an escalation.

## Work it through

The call that says only "the network is down", worked through the method.

First, refuse to accept the symptom as stated, because "down" is a description and you
need the thing. Ask what specifically does not work, what changed, and whether it is one
person or many, and if you can, reproduce it yourself. Half the time this step alone
turns "the network is down" into "one application cannot reach one server", which is a
different and much smaller problem.

Then form a theory you can disprove, and start with the obvious, because the obvious is
obvious for a reason and is unchecked for the same reason. If something changed, the
theory almost writes itself: the change is the cause until a test says otherwise.

Then test it, and take the loop seriously. If the theory holds, plan the fix and its side
effects before you touch anything. If it does not, you have not failed, you have removed a
candidate, so go back and form the next theory. Most of the elapsed time in a hard fault
is spent in this loop, and the engineers who are fast are the ones who move through
disproved theories quickly rather than the ones who guess right first.

Then fix or escalate, verify from the user's side, and write it down, in that order, and
do not let the pressure coming off at the fix talk you out of the last step. The version
of this fault that arrives in four months is either a five-minute lookup or a fresh
afternoon, and which one it is gets decided in the ninety seconds you spend on step seven
now.

## Try it

**Take your last real fault and write the seven steps against it, after the fact.** Where
did the theory come from, what test confirmed or killed it, and did you document the
outcome? The gaps you find are the steps you skip under pressure, and naming them is how
you stop.

**Practise the escalation handover.** Write the three sentences you would hand to another
team for a problem you cannot solve: what you have established, what you have ruled out,
and the one test that points at their area. That paragraph is the difference between an
escalation that helps and one that restarts the clock.

**Find one recurring fault and write its record.** Symptom, cause, fix, and what not to
re-test. The next occurrence proves whether step seven was worth it, and it always is.

## Check yourself

<details class="qa">
<summary>What are CompTIA's seven troubleshooting steps, in order?</summary>

Identify the problem; establish a theory of probable cause; test the theory to determine
the cause; establish a plan of action and identify potential effects; implement the
solution or escalate; verify full system functionality and, where possible, prevent a
repeat; document findings, actions, and outcomes.

The order matters and so does the branch at step three: a confirmed theory goes forward to
the plan, and a disproved one goes back to step two for a new theory or to escalation.

</details>

<details class="qa">
<summary>Why is the methodology a loop rather than a straight line?</summary>

Because step three, testing the theory, has two exits. If the test confirms the theory,
you proceed to the fix. If it disproves it, you return to step two and form another theory,
or you escalate.

A straight line would only serve the case where the first guess is right. The loop is what
makes the method work for everyone else: it expects theories to fail and gives failure a
defined next move, so a disproved theory is progress, having removed a candidate, rather
than a dead end.

</details>

<details class="qa">
<summary>Two users report one symptom. What does the methodology tell you to do?</summary>

Approach the problems individually, because two faults sharing one symptom will not respond
to any single fix. Step one includes splitting multiple problems apart precisely so you do
not spend the afternoon looking for the one cause that explains both when there are two.

Establishing whether it is one fault or two is part of identifying the problem, and getting
it wrong is one of the most common reasons a straightforward fault takes far longer than it
should.

</details>

<details class="qa">
<summary>Why is documenting the outcome the step that pays, and why is it skipped?</summary>

It pays because a fault that recurs is otherwise solved from scratch every time, each
solution having evaporated when the symptom cleared. A short record, the symptom, the cause,
the fix, and what you ruled out, turns the next occurrence into a lookup instead of a fresh
investigation.

It is skipped because by step seven the fault is fixed, the pressure is off, and writing it
up feels like tidying rather than work. The instinct is backwards: the value is not to the
incident you just closed but to the identical one months from now, which is usually you.

</details>

<details class="qa">
<summary>What makes an escalation useful rather than just moving the problem?</summary>

The handover. Escalating with only the symptom restarts the whole method in someone else's
chair. Escalating with what you have established, the theories you have already disproved,
and the discriminating test that points at their area lets them start from where you got to.

The decision to escalate is easy; the work is carrying the context across so none of what
you found has to be found again.

</details>

## References

- [CompTIA Network+ N10-009 objectives](https://www.comptia.org/certifications/network) - CompTIA, objective 5.1, the source of the seven-step order and the branch at step three. Accessed 2026-08-19.
- [ITIL service management](https://www.axelos.com/certifications/itil-service-management) - Axelos, incident management as the wider discipline the seven steps are a local form of. Accessed 2026-08-19.

**Where the numbers came from.** There are no measured numbers on this page. Nothing here is
captured, because the methodology is a process and the topics that follow are where it is run
against real faults; the figure is drawn from CompTIA's own seven-step list with the step-three
branch it defines, and the accent marks the two steps where the thinking happens.

**If you also troubleshoot Linux systems.** The same seven steps drive the Linux+
troubleshooting topics, and the discipline is identical: reproduce the fault, form a theory you
can disprove, test it, and document what you found. The tools differ by platform and the method
does not, which is why it is a methodology topic rather than a tools one.
