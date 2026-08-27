---
title: "The incident response process"
description: "Seven phases and the decision waiting at each boundary, why containment comes before eradication and what it costs, what a tabletop finds that a plan cannot, and the lesson that gets written and never implemented."
deck: "The alert fired at two in the morning. The first question is not what happened"
track: "security-plus"
level: "working"
order: 610
objectives:
  - "Name the phases and say what decision each boundary poses"
  - "Explain why containment precedes eradication and what each costs"
  - "Say what preparation covers and why it is the phase that decides the rest"
  - "Distinguish a tabletop exercise from a simulation by what each tests"
  - "Say what root cause analysis is looking for and when to stop"
  - "Describe threat hunting and how it differs from responding"
prerequisites: ["what-to-monitor-and-what-to-do-when-it-fires"]
tags: ["security-plus", "security", "operations", "incident-response"]
updated: 2026-08-25
draft: false
examObjectives:
  - exam: "sy0-701"
    domain: "4.0"
    objective: "4.8"
sources:
  - title: "SP 800-61 Rev. 3, Incident Response Recommendations and Considerations"
    url: "https://csrc.nist.gov/pubs/sp/800/61/r3/final"
    publisher: "NIST"
    accessed: 2026-08-25
    tier: 1
  - title: "SP 800-84, Guide to Test, Training, and Exercise Programs for IT Plans and Capabilities"
    url: "https://csrc.nist.gov/pubs/sp/800/84/final"
    publisher: "NIST"
    accessed: 2026-08-25
    tier: 1
  - title: "SP 800-86, Guide to Integrating Forensic Techniques into Incident Response"
    url: "https://csrc.nist.gov/pubs/sp/800/86/final"
    publisher: "NIST"
    accessed: 2026-08-25
    tier: 1
  - title: "The Cyber Security Body of Knowledge, Security Operations and Incident Management"
    url: "https://www.cybok.org/knowledgebase1_1/"
    publisher: "CyBOK"
    accessed: 2026-08-25
    tier: 2
symptoms:
  - symptom: "The machine was cleaned before anybody knew how the attacker got in"
    anchor: "containment-before-eradication"
  - symptom: "The same incident happens again with a different name"
    anchor: "the-lesson-that-gets-written"
---

> **Before you read.** An alert fires at two in the morning. A senior engineer is
> awake, capable, and looking at a machine that is doing something it should not.
>
> **What is the first question, and why is it not what happened?**

The first question is who else needs to be awake, because everything after it is
faster with the right people and slower without them. What happened is the second
question, and the most common failure in incident response is a competent person
answering it alone for three hours.

### Some words you will need

<dl class="terms">
<dt>preparation</dt>
<dd>Everything done before an incident that makes the response possible. The phase that decides the others.</dd>
<dt>detection</dt>
<dd>Noticing. Frequently from outside the organisation rather than from a monitoring system.</dd>
<dt>analysis</dt>
<dd>Establishing what is happening and how far it goes.</dd>
<dt>containment</dt>
<dd>Stopping the spread without necessarily removing the cause.</dd>
<dt>eradication</dt>
<dd>Removing the cause. Destructive, and it takes the evidence with it.</dd>
<dt>recovery</dt>
<dd>Restoring service, and deciding whether it is safe to.</dd>
<dt>lessons learned</dt>
<dd>What changes as a result. The phase with the worst completion rate.</dd>
<dt>tabletop exercise</dt>
<dd>A discussion of a scenario. Tests the plan and the people, not the systems.</dd>
<dt>threat hunting</dt>
<dd>Looking for an intrusion nobody has alerted on. The proactive counterpart.</dd>
</dl>

## What breaks without this

**One person investigates for three hours.** Nobody else knows, the people who
should be deciding are asleep, and the response starts when they wake up.

**The machine is cleaned before anybody knows how it was reached.** The incident
is over and the way in is still open, so it happens again with a different
hostname.

**Containment is delayed by an approval nobody can give at that hour.** The
decision needed an authority level nobody had assigned, so the spread continued
while somebody looked for a phone number.

**The lessons are written and nothing changes.** A document is produced, filed and
never converted into work, so the next incident is the same one.

## Seven phases and the decision at each boundary

<figure class="learn-figure">
<svg viewBox="0 0 720 348" role="img" aria-labelledby="ir-title" style="width:100%;height:auto;">
<title id="ir-title">Seven incident response phases against elapsed time, with the decision each boundary poses and the two that cannot be undone</title>
<g fill="currentColor">
<text x="14" y="20" font-size="11">seven phases, and the decision waiting at each boundary</text>
<text x="176" y="44" font-size="9" fill-opacity="0.7">when</text>
<text x="300" y="44" font-size="9" fill-opacity="0.7">the decision at this boundary</text>
<text x="620" y="44" font-size="9" fill-opacity="0.7">reversible</text>
<rect x="14" y="54" width="150" height="28" rx="4" fill="var(--accent)" fill-opacity="0.10" stroke="var(--accent)" stroke-opacity="0.7" stroke-width="1.2"/>
<text x="89" y="72" text-anchor="middle" font-size="8.5">preparation</text>
<text x="176" y="72" font-size="8" fill-opacity="0.75">before</text>
<text x="300" y="72" font-size="8" fill-opacity="0.9">everything you did not do now costs you</text>
<text x="626" y="72" font-size="8" fill="var(--accent)" fill-opacity="0.95">yes</text>
<rect x="14" y="90" width="150" height="28" rx="4" fill="var(--accent)" fill-opacity="0.10" stroke="var(--accent)" stroke-opacity="0.7" stroke-width="1.2"/>
<text x="89" y="108" text-anchor="middle" font-size="8.5">detection</text>
<text x="176" y="108" font-size="8" fill-opacity="0.75">minute 0</text>
<text x="300" y="108" font-size="8" fill-opacity="0.9">is this real</text>
<text x="626" y="108" font-size="8" fill="var(--accent)" fill-opacity="0.95">yes</text>
<rect x="14" y="126" width="150" height="28" rx="4" fill="var(--accent)" fill-opacity="0.10" stroke="var(--accent)" stroke-opacity="0.7" stroke-width="1.2"/>
<text x="89" y="144" text-anchor="middle" font-size="8.5">analysis</text>
<text x="176" y="144" font-size="8" fill-opacity="0.75">minutes to hours</text>
<text x="300" y="144" font-size="8" fill-opacity="0.9">what is the scope</text>
<text x="626" y="144" font-size="8" fill="var(--accent)" fill-opacity="0.95">yes</text>
<rect x="14" y="162" width="150" height="28" rx="4" fill="var(--red)" fill-opacity="0.16" stroke="var(--red)" stroke-opacity="0.7" stroke-width="1.6"/>
<text x="89" y="180" text-anchor="middle" font-size="8.5">containment</text>
<text x="176" y="180" font-size="8" fill-opacity="0.75">the decision point</text>
<text x="300" y="180" font-size="8" fill-opacity="0.9">stop the spread, or keep watching</text>
<text x="626" y="180" font-size="8" fill="var(--red)" fill-opacity="0.95">no</text>
<rect x="14" y="198" width="150" height="28" rx="4" fill="var(--red)" fill-opacity="0.16" stroke="var(--red)" stroke-opacity="0.7" stroke-width="1.6"/>
<text x="89" y="216" text-anchor="middle" font-size="8.5">eradication</text>
<text x="176" y="216" font-size="8" fill-opacity="0.75">hours to days</text>
<text x="300" y="216" font-size="8" fill-opacity="0.9">remove it, and the evidence with it</text>
<text x="626" y="216" font-size="8" fill="var(--red)" fill-opacity="0.95">no</text>
<rect x="14" y="234" width="150" height="28" rx="4" fill="var(--accent)" fill-opacity="0.10" stroke="var(--accent)" stroke-opacity="0.7" stroke-width="1.2"/>
<text x="89" y="252" text-anchor="middle" font-size="8.5">recovery</text>
<text x="176" y="252" font-size="8" fill-opacity="0.75">days</text>
<text x="300" y="252" font-size="8" fill-opacity="0.9">is it safe to bring back</text>
<text x="626" y="252" font-size="8" fill="var(--accent)" fill-opacity="0.95">yes</text>
<rect x="14" y="270" width="150" height="28" rx="4" fill="var(--accent)" fill-opacity="0.10" stroke="var(--accent)" stroke-opacity="0.7" stroke-width="1.2"/>
<text x="89" y="288" text-anchor="middle" font-size="8.5">lessons learned</text>
<text x="176" y="288" font-size="8" fill-opacity="0.75">weeks later</text>
<text x="300" y="288" font-size="8" fill-opacity="0.9">and does anything change</text>
<text x="626" y="288" font-size="8" fill="var(--accent)" fill-opacity="0.95">yes</text>
<text x="14" y="322" font-size="10" fill-opacity="0.85">containment is the first decision with a real cost either way</text>
<text x="14" y="342" font-size="9" fill-opacity="0.7">and eradication destroys the thing an investigation would have wanted, which is why it comes after</text>
</g></svg>
<figcaption>The phases against elapsed time, with the question each boundary actually poses. Most of them are reversible: a wrong judgement in analysis is corrected by more analysis, and a premature recovery can be undone by taking the service down again. Two are not. Containment has a real cost whichever way it goes, because isolating a system is an outage you caused and not isolating it lets the spread continue. Eradication removes the thing an investigation would have examined, which is why it sits after analysis rather than being the first instinct. The accented rows are where the plan should say who decides, because those are the decisions somebody will otherwise make alone at two in the morning.</figcaption>
</figure>

**Preparation is the phase that decides the others** and it is the only one that
happens when nobody is under pressure. What it covers is unglamorous: a contact
list that is current, an agreed definition of what counts as an incident, stated
authority to take systems offline, somewhere to communicate that does not depend
on the systems being investigated, and access to whatever tooling the response
needs, granted in advance.

That last one is worth dwelling on. A response frequently stalls because the
person who needs to look at something does not have access to it, and the access
request goes through a process designed for ordinary weeks. Preparation means the
responders already hold what they will need, which is a standing privilege that
has to be justified and monitored, and it is worth the argument.

**Detection is frequently external.** A supplier, a customer, a researcher or a
law enforcement notification, rather than an alert. That is not a failure of the
monitoring so much as a fact about how intrusions surface, and it means the plan
has to work when the first news arrives by email from a stranger.

**Analysis is where scope is established**, and the question that matters is not
what this machine is doing but how many machines are doing it. An incident scoped
to one host and actually covering forty is the most expensive kind of mistake,
because containment is planned against the wrong number.
<details class="deeper">
<summary>If you write the plan: the four decisions to name in advance, and why naming the person beats naming the rule</summary>

Most incident response plans describe a process well and leave the decisions
implicit, which is the wrong way round: the process is recoverable from a
reasonable person's judgement and the authority is not.

Four decisions are worth naming explicitly with a person or role against each.

**Who declares an incident.** Until somebody does, the response is a person
looking at something odd, and none of the plan's authorities are in effect.
Setting the bar low is right, because a declaration that turns out to be
unnecessary costs an hour and the reverse costs a night.

**Who may take production offline.** This is the containment decision and it is
the one most likely to be needed at an hour when the usual approver is asleep. The
plan should name a role that is genuinely on call, and it should say what happens
if that person cannot be reached, because otherwise the default answer is nobody
and the spread continues.

**Who talks to whom outside.** Customers, regulators, insurers, law enforcement,
the press. Getting this wrong is expensive in ways that are hard to undo, and it
is the decision most likely to be made accidentally by somebody sending a helpful
email.

**Who decides it is over.** Incidents end by fading rather than by a decision, and
the phase that follows is the one with the worst completion rate, so a named
person declaring the end is what triggers it happening at all.

Naming a person rather than a rule matters because rules require interpretation
and interpretation requires a person, so a rule without an owner is a decision
nobody makes. The plan can say what should usually happen, and it has to say who
decides when the situation is not usual, because the situation is never usual.

One practical detail: name roles, keep a separate current list of who holds each,
and review that list on a schedule rather than editing the plan. Plans get
reviewed annually and people change jobs more often than that.

</details>

<details class="predict">
<summary>An organisation has a written plan, a trained team, and good tooling. Predict which of the seven phases is most likely to fail anyway.</summary>

**Preparation, and it fails invisibly because it already happened.**

The other six are performed during an incident by people paying attention.
Preparation was done at some point in the past, by somebody who may have left, and
nothing about it announces that it has stopped being true.

The specific decays are consistent across organisations. The contact list names
two people who have left and one whose number changed. The out-of-band
communication channel was chosen and never tested. The responders' standing access
was granted, then removed during an access review by somebody correctly applying
least privilege to accounts that had not been used in six months. And the
definition of what counts as an incident was agreed by a team that has since
turned over.

Every one of those is discovered during the response, at the point where it costs
the most, and none of them would be discovered by reading the plan, because the
plan still says the right thing. The plan is not what decayed.

The check that finds it takes an hour and almost nobody schedules it: call the
numbers, log in to the out-of-band channel, and have a responder try to access one
of the systems they would need. Three tests, quarterly, and they fail more often
than anybody expects.

The deeper point is one this track keeps arriving at from different directions. A
control that was correct when it was created and is never re-examined is
indistinguishable from a working one right up until it is needed, and the
distinguishing test is always cheap and always unscheduled.

</details>


## Containment before eradication

The ordering is the part of the process that gets argued about, and the argument
is real rather than a matter of following the list.

**Containment stops the spread.** Isolating the machine, disabling an account,
blocking an address, taking a segment off the network. It buys time and it is an
outage you caused, deliberately, on the strength of an assessment that may be
incomplete.

**Eradication removes the cause.** Rebuilding the machine, removing the software,
closing the route. It is the satisfying step and it destroys the machine's state,
which is the thing an investigation needs to establish how the attacker got in.

**Doing them in the wrong order is the classic failure**, and it is completely
understandable: the instinct when you find something bad is to remove it. The
consequence is an organisation that has cleaned a machine, restored the service,
and cannot say how the attacker arrived, which means it cannot say whether they
are still inside.

The judgement inside containment is subtler and worth naming. Containing
immediately stops the damage and tells the attacker they have been seen, at which
point a competent one accelerates, destroys evidence, or activates a second route
you have not found. Watching for longer builds a fuller picture and lets the
damage continue while you do.

**There is no general answer**, and the plan should say who decides rather than
what the answer is. Some organisations can afford to watch and some cannot, and
the same organisation will answer differently on a payroll system and on a test
environment.

## What a tabletop finds

**A tabletop exercise is a discussion**, and its value is not in testing whether
the technology works.

It tests whether the people can do the thing the plan describes, and what it
reliably finds is the gap between a plan and a decision. Who declares an incident.
Who may take production offline. What is said to customers and by whom. Whether
the person named in the plan still works here. Those are answerable in a meeting
room, in two hours, and none of them requires a system.

**A simulation exercises the systems**, injecting something real and watching the
detection, the tooling and the response actually operate. It is more expensive, it
finds a different class of problem, and it is worth doing after a tabletop rather
than instead of one, because a simulation of a plan nobody agrees on tests the
wrong thing.

The finding a tabletop produces most often is neither technical nor dramatic: two
people in the room have different understandings of who is in charge. That is
free to discover on a Tuesday and expensive to discover at two in the morning.
<details class="deeper">
<summary>If you run the exercise: how to design a scenario that finds something, and the two that waste an afternoon</summary>

A tabletop exercise either surfaces a real gap or produces a pleasant discussion
in which everybody performs competence, and the difference is almost entirely in
how the scenario was written.

Two designs waste the afternoon reliably.

**The scenario the team has already planned for.** Ransomware on a file server,
walked through by a team that rehearsed ransomware last year. Everybody knows
their lines, the plan is followed correctly, and the exercise confirms what was
already known.

**The scenario with an obvious answer.** If the right response is clear from the
first sentence, the discussion is about execution rather than about judgement, and
execution is what a simulation tests better anyway.

What finds something is a scenario with an uncomfortable decision in it, and the
best ones share a shape: incomplete information, a cost either way, and a
constraint that makes the textbook answer unavailable. The intrusion appears to
involve a system you cannot take offline. The evidence points at a named employee.
The notification clock has started and you do not yet know the scope. The obvious
containment action would breach a customer commitment.

Two techniques improve any scenario. Inject new information partway through, so
the team has to revise a decision rather than making one, which is what actually
happens. And ask each person individually to write their answer before discussing,
because a group converges on whoever speaks first and the disagreement is the
finding.

Record the disagreements rather than the conclusions. A tabletop's output is not a
decision about the scenario, which will not recur, it is the list of things two
competent people understood differently, and each of those is a paragraph missing
from the plan.

</details>


## Root cause, and when to stop

Root cause analysis asks why, repeatedly, past the first satisfying answer.

The malicious code ran. Why? Somebody opened an attachment. Why did that work? The
attachment type was not filtered. Why not? The filter was configured three years
ago against a different threat and nobody reviewed it. Why not? No review existed
for that control.

Each answer is a candidate for a fix and they are not equally useful. Stopping at
the first produces awareness training. Stopping at the last produces a control
review process, which is more work and prevents a class rather than an instance.

**Stop when the next answer leaves the organisation's control.** "Because
attackers send phishing emails" is true, it is the state of the world, and it is
not something you can change. The last answer inside your control is where the
remediation belongs.

**And resist the single cause.** Most incidents have several contributing factors
and it is comfortable to identify one, especially if it is a person. An analysis
naming an individual has usually stopped early, because the interesting question
is what let one person's mistake become an incident.

## The lesson that gets written

The final phase has the worst completion rate of the seven, and the reason is
structural rather than a failure of will.

The other six happen under pressure with everybody's attention. Lessons learned
happens two weeks later when the crisis has passed, the people involved have
returned to their actual jobs, and the document has no deadline attached to it.

**A lesson that is not converted into work is not a lesson.** The test is whether
each item has an owner, a date and a place in somebody's queue, which means the
output of the phase should be tickets rather than a report. A report is evidence
that the phase happened. Tickets are evidence that something changes.

**Threat hunting is the proactive counterpart** to all of this and it belongs in
the same objective for a reason. Response begins when something alerts. Hunting
begins with a hypothesis and no alert: if an attacker were using this technique in
our estate, what would be visible, and is it there? It finds what the detection
missed, and it produces new detections as a by-product, which is how a response
capability improves between incidents rather than only after them.
<details class="predict">
<summary>A lessons learned meeting produces fourteen recommendations. Predict how many are implemented, and which ones.</summary>

**Few, and the ones that are cheap rather than the ones that matter.**

The mechanism is not laziness. It is that the recommendations leave the meeting as
sentences in a document while every other demand on the same people leaves their
meetings as tickets in a queue with dates on them. Work that is in a queue gets
done and work that is in a document does not, and nothing about the document's
contents changes that.

Which ones survive is predictable too. "Add an alert for this pattern" is a
morning's work owned by somebody who was in the room, and it happens. "Review the
control that let this through" needs a person, a decision about scope and somebody
else's time, and it does not. So the implemented subset is the technical, local,
cheap end, which is exactly the end that prevents this incident recurring rather
than the class it belongs to.

Two changes fix most of it and neither is cultural. Convert every recommendation
into a ticket before the meeting ends, with an owner who is present and a date
they agreed to out loud, and accept that fewer, real commitments beat fourteen
aspirational ones. Then review the list at the next incident rather than never,
which takes ten minutes and is the only feedback the process ever gets.

The measure worth tracking, because it is the one that says whether any of this
works: at the next incident, how many of the previous recommendations would have
made a difference, and how many of those had been implemented. Most organisations
have never asked, and the answer is available.

</details>

<details class="deeper">
<summary>If you are starting threat hunting: what a hypothesis looks like, and why the failures are the output</summary>

Threat hunting sounds like a senior activity requiring rare skill, and the useful
version of it is a repeatable exercise a competent team can run monthly.

It starts with a hypothesis, and the shape that works is narrow and falsifiable.
Not "are we compromised", which cannot be answered, but "if somebody were using
scheduled tasks for persistence on our Windows estate, there would be tasks
created outside the change window by accounts that do not normally create them,
and I can list those." That is a query, it returns a finite answer, and the answer
is either interesting or it is not.

Where hypotheses come from is the part people get stuck on, and there are three
reliable sources. A published technique somebody else observed, asked of your own
estate. An assumption in your defences, tested: we believe nothing reaches that
segment, so what does. And an anomaly somebody noticed and dismissed, taken
seriously for an hour.

**The failures are the output**, which is the thing that makes hunting worth
funding even when it finds nothing. A hunt that cannot be run because the data is
not collected has found a monitoring gap. One that returns ten thousand rows has
found a source that is collected and not usable. One that returns a clean answer
has established a fact you can rely on and can convert into a detection so nobody
has to hunt for it again.

That last conversion is what compounds. Every hunt should end with either a
finding or a new detection, and a team that does this monthly for a year has a
detection set built from questions somebody actually asked rather than from a
vendor's default rules.

The trap to avoid is treating a clean result as a waste. Most hunts find nothing,
and a hunt that finds nothing has still told you the technique would have been
visible, which is exactly what you did not know beforehand.

</details>


## Prove it

**Run it.** Find your organisation's incident response plan and check three
things: who declares an incident, who may take a production system offline, and
what the out-of-band communication channel is. If any is missing or names somebody
who left, that is the finding.

**Work it out.** Take the two in the morning scenario. Write down the order you
would do things in and mark which of your steps are irreversible. Then decide
which of those you have the authority to take without waking anybody.

**Look it up.** Open SP 800-61 Rev. 3 and compare its phase structure with the
seven this objective names. The differences are instructive and the underlying
sequence is the same.

## What trips people up

### 1. Answering what happened before who needs to know

A competent person investigating alone for three hours is the most common failure
in incident response. The people who need to decide are not awake and the clock is
running.

### 2. Eradicating before analysing

Rebuilding the machine removes the evidence of how it was reached, so the incident
ends without anybody knowing whether the route is closed.

### 3. Treating containment as obviously correct

It is an outage you caused, on an incomplete assessment, and it tells the attacker
they have been seen. It is usually right and it is a decision with costs on both
sides, which is why the plan should say who makes it.

### 4. Scoping to the machine in front of you

The question is how many hosts are affected, not what this one is doing.
Containment planned against the wrong number is planned wrong.

### 5. Stopping root cause analysis at the first answer

The first answer produces awareness training. The last one inside your control
produces a change that prevents a class of incident rather than an instance.

### 6. Producing a lessons learned document

The output should be tickets with owners and dates. A document is evidence the
phase occurred, and it is what gets produced when the phase has no deadline.

## Work it through

Two in the morning. A file server is encrypting its own contents. One engineer is
awake. The organisation has a plan, which nobody has read this year.

**The tempting move is to start fixing.** Kill the process, restore from backup,
get the service back. It is what an engineer is for, it addresses the visible
damage, and it will be done before anybody else knows, which means the decisions
about scope, about whether other machines are affected, and about whether this is
reportable are all made by implication rather than by anybody.

**The move that works spends the first two minutes on people.** Wake whoever the
plan names, or if it names nobody, wake a manager. That call costs two minutes,
and it converts a solo effort into an organisational one with authority attached
to it.

**Then contain rather than eradicate.** Take the server off the network, which
stops it reaching anything else and preserves everything about its state. That is
reversible, it is within an on-call engineer's authority in most organisations,
and it buys the time for the analysis that decides what to do next.

**What this rejects is the instinct to fix it.** The instinct is correct in an
outage and wrong in an incident, and telling those apart is the reason the first
question is who rather than what. If it turns out to be a failing disk rather than
an intrusion, waking a manager cost somebody twenty minutes of sleep.

The residual to name: containment stopped this server and said nothing about
whether the attacker is elsewhere. Nobody knows the scope yet, and the decision
taken here is deliberately the reversible one, which leaves the possibility that
the real answer is much larger. The next decision belongs to the people who have
now been woken up.

## Try it

**Read your plan for one number.** Find the phone number of whoever declares an
incident and check that it is current. It is a two-minute test that a surprising
proportion of plans fail.

**Run a tabletop in an hour.** Take six people, describe a scenario in three
sentences, and ask who decides each thing. Write down every disagreement. That is
a complete exercise and it will produce findings.

**Find your out-of-band channel.** Ask how the response team would communicate if
the corporate mail and chat systems were the thing being investigated. If the
answer is those systems, that is the finding.

**Ask a why five times.** Take the last incident, however small, and push past the
first answer. Notice where the chain leaves your control, because the step before
that is where the fix belongs.

## Check yourself

<details class="qa">
<summary>Why is the first question who rather than what?</summary>

Because a competent person investigating alone is the most common failure in
incident response. The decisions about scope, about taking systems offline and
about whether the incident is reportable belong to people who are not awake, and
every hour spent alone is an hour those decisions are made by implication.

Waking somebody costs two minutes and converts a solo effort into an
organisational one with authority attached.

</details>

<details class="qa">
<summary>Why does containment come before eradication?</summary>

Because eradication is destructive to the evidence. Rebuilding the machine or
removing the software takes away the state that would show how the attacker got
in, so the incident ends without anybody knowing whether the route is closed.

Containment stops the spread while preserving that state. It is also a decision
with a real cost on both sides: isolating is an outage you caused on an incomplete
assessment, and it tells the attacker they have been seen.

</details>

<details class="qa">
<summary>What does a tabletop exercise test that a simulation does not?</summary>

Whether the people can do what the plan describes. Who declares an incident, who
may take production offline, what is said to customers and by whom, and whether
the person named in the plan still works here.

A simulation exercises the systems and detection, which is a different and more
expensive class of problem. Running one against a plan nobody agrees on tests the
wrong thing, which is why the tabletop comes first.

</details>

<details class="qa">
<summary>When should root cause analysis stop?</summary>

When the next answer leaves the organisation's control. "Because attackers send
phishing emails" is true and unchangeable, so the last answer inside your control
is where the remediation belongs.

Stopping at the first answer produces awareness training. Continuing produces a
control review process, which prevents a class rather than an instance. An
analysis that names an individual has usually stopped early, because the
interesting question is what let one person's mistake become an incident.

</details>

<details class="qa">
<summary>Why does the lessons learned phase have the worst completion rate?</summary>

Because it happens weeks later, without pressure, without attention, and without a
deadline, while the other six happen during a crisis when everybody is watching.

The fix is to make the output tickets with owners and dates rather than a
document. A report is evidence that the phase occurred. Tickets are evidence that
something changes.

</details>

## References

- [SP 800-61 Rev. 3](https://csrc.nist.gov/pubs/sp/800/61/r3/final) - NIST, incident response recommendations, for the phase structure and what each covers. Free. Accessed 2026-08-25.
- [SP 800-84](https://csrc.nist.gov/pubs/sp/800/84/final) - NIST, test, training and exercise programmes, for what a tabletop is and how it differs from a simulation. Free. Accessed 2026-08-25.
- [SP 800-86](https://csrc.nist.gov/pubs/sp/800/86/final) - NIST, integrating forensic techniques, for why the containment and eradication ordering matters to evidence. Free. Accessed 2026-08-25.
- [CyBOK](https://www.cybok.org/knowledgebase1_1/) - the Security Operations and Incident Management knowledge area, for the wider framing. Free. Accessed 2026-08-25.

**Where the content came from.** Nothing on this page is captured, because an
incident response process is an arrangement between people rather than a state a
machine reports, and there is no command that returns one. The phase structure and
the exercise definitions are read from the NIST documents cited rather than from
summaries of them. The forensic consequences of the containment and eradication
ordering are the subject of the next topic, which does capture what a reboot
destroys.

**If you also work on networks.** The Network+ track's
[the hour after it breaks](/learn/network-plus/the-hour-after-it-breaks) covers
the same first hour from an availability point of view, where the instinct to
restore is correct rather than premature.
