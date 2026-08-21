---
title: "Deciding what to do about a risk"
description: "The four things you can do about a risk and what each one leaves behind, why accepting one needs a name and a date, the difference between appetite and tolerance and where each is set, and what a risk register is actually for."
deck: "Accepting a risk is a decision somebody has to sign"
track: "security-plus"
level: "working"
order: 690
objectives:
  - "Name the four risk treatments and say what each one leaves behind"
  - "Explain why every accepted risk needs an owner and a review date"
  - "Distinguish risk appetite from risk tolerance, and say where each is set"
  - "Describe what a risk register holds and what makes one useless"
  - "Tell an exception from an exemption"
  - "Choose a treatment for a stated risk and defend the rejection of the others"
prerequisites: []
tags: ["security-plus", "security", "risk", "governance"]
updated: 2026-08-21
draft: false
examObjectives:
  - exam: "sy0-701"
    domain: "5.0"
    objective: "5.2"
sources:
  - title: "NIST SP 800-39, Managing Information Security Risk"
    url: "https://csrc.nist.gov/pubs/sp/800/39/final"
    publisher: "NIST"
    accessed: 2026-08-21
    tier: 1
  - title: "NIST IR 8286, Integrating Cybersecurity and Enterprise Risk Management"
    url: "https://csrc.nist.gov/pubs/ir/8286/final"
    publisher: "NIST"
    accessed: 2026-08-21
    tier: 1
  - title: "NIST SP 800-30 Rev. 1, Guide for Conducting Risk Assessments"
    url: "https://csrc.nist.gov/pubs/sp/800/30/r1/final"
    publisher: "NIST"
    accessed: 2026-08-21
    tier: 1
  - title: "NIST SP 800-37 Rev. 2, Risk Management Framework for Information Systems and Organizations"
    url: "https://csrc.nist.gov/pubs/sp/800/37/r2/final"
    publisher: "NIST"
    accessed: 2026-08-21
    tier: 1
symptoms:
  - symptom: "A risk was accepted years ago by somebody who has left"
    anchor: "accepting-is-a-decision-somebody-signs"
  - symptom: "The register has three hundred rows and nobody reads it"
    anchor: "the-register-and-what-makes-one-useless"
---

> **Before you read.** A finding says an internet-facing service is running an
> unsupported database. Patching it means rewriting the application, which is
> nine months of work nobody has.
>
> The team writes "risk accepted" in the tracker and closes the ticket.
>
> **Name three things wrong with that, without arguing about the database.**

There are four things you can do about a risk and one of them is to do nothing on
purpose. That last one is a real answer, it is the one people reach for most, and
it is the one they get wrong most, because doing nothing on purpose and doing
nothing are indistinguishable from the outside unless somebody writes down which
it was.

### Some words you will need

<dl class="terms">
<dt>risk treatment</dt>
<dd>What you decide to do about a risk. Also called a risk response or a course of action.</dd>
<dt>residual risk</dt>
<dd>What is left after the treatment. Always something, except when you removed the activity entirely.</dd>
<dt>risk appetite</dt>
<dd>How much risk the organisation is willing to take in pursuit of its objectives. Set at the top, once.</dd>
<dt>risk tolerance</dt>
<dd>How much variation from that is acceptable for a particular system or programme. Set below the appetite, per thing.</dd>
<dt>risk threshold</dt>
<dd>The specific number at which a tolerance is crossed and somebody has to act.</dd>
<dt>risk register</dt>
<dd>The list of identified risks, with an owner, a treatment and a date against each.</dd>
<dt>key risk indicator</dt>
<dd>A measurement that reports whether you are inside a tolerance or outside it. Abbreviated KRI.</dd>
<dt>risk owner</dt>
<dd>The named person who is accountable for the treatment. Never a team, never a job title with nobody in it.</dd>
</dl>

## What breaks without this

**A risk gets accepted by somebody with no authority to accept it.** An engineer
closing a ticket has accepted an exposure on behalf of the organisation. If the
organisation later loses money on it, the question asked is who decided, and the
honest answer is nobody senior enough.

**Nothing is ever reviewed.** A risk accepted in 2023 was accepted against a
system, a threat and a business that have all changed. Without a review date it
stays accepted forever, which is not a decision anybody made.

**The register becomes an archive.** Three hundred rows, no owners, no dates,
nobody reads it, and the one risk that mattered is on line 214 between two that
have been closed for years.

**Money gets spent on the wrong risk.** Without a comparison between what a
treatment costs and what it leaves behind, spending goes where the noise is
rather than where the exposure is.

## The four risk management strategies, and what each one leaves

Take one risk and put it through all four. The arithmetic here is the arithmetic
from the previous topic, so the numbers are checkable rather than illustrative.

<figure class="learn-figure">
<svg viewBox="0 0 720 336" role="img" aria-labelledby="treat-title" style="width:100%;height:auto;">
<title id="treat-title">One risk with an annualised loss expectancy of sixty thousand, shown under the four treatments, with the residual exposure and the annual spend drawn to the same scale for each</title>
<g fill="currentColor">
<text x="14" y="20" font-size="11">one risk, ALE 60,000 a year, drawn four ways to the same scale</text>
<rect x="190" y="34" width="12" height="10" rx="2" fill="var(--accent)" fill-opacity="0.35" stroke="var(--accent)" stroke-width="1.4"/>
<text x="208" y="43" font-size="10" fill-opacity="0.8">exposure still carried</text>
<rect x="360" y="34" width="12" height="10" rx="2" fill="currentColor" fill-opacity="0.14" stroke="currentColor" stroke-opacity="0.7" stroke-dasharray="3 2"/>
<text x="378" y="43" font-size="10" fill-opacity="0.8">spent to get there</text>
<text x="14" y="82" font-size="10">accept</text>
<rect x="190" y="70" width="300" height="16" rx="2" fill="var(--accent)" fill-opacity="0.35" stroke="var(--accent)" stroke-width="1.6"/>
<text x="500" y="82" font-size="10">60,000 left, 0 spent</text>
<text x="14" y="126" font-size="10">avoid</text>
<rect x="190" y="114" width="180" height="16" rx="2" fill="none" stroke="currentColor" stroke-opacity="0.7" stroke-width="1.4" stroke-dasharray="3 3"/>
<text x="198" y="126" font-size="9.5" fill-opacity="0.85">service switched off</text>
<text x="500" y="126" font-size="10">0 left, the capability is gone</text>
<text x="14" y="170" font-size="10">transfer</text>
<rect x="190" y="158" width="25" height="16" rx="2" fill="var(--accent)" fill-opacity="0.35" stroke="var(--accent)" stroke-width="1.6"/>
<rect x="217" y="158" width="90" height="16" rx="2" fill="currentColor" fill-opacity="0.14" stroke="currentColor" stroke-opacity="0.7" stroke-dasharray="4 3"/>
<text x="500" y="170" font-size="10">5,000 left, 18,000 spent</text>
<text x="14" y="214" font-size="10">mitigate</text>
<rect x="190" y="202" width="60" height="16" rx="2" fill="var(--accent)" fill-opacity="0.35" stroke="var(--accent)" stroke-width="1.6"/>
<rect x="252" y="202" width="125" height="16" rx="2" fill="currentColor" fill-opacity="0.14" stroke="currentColor" stroke-opacity="0.7" stroke-dasharray="4 3"/>
<text x="500" y="214" font-size="10">12,000 left, 25,000 spent</text>
<path d="M 190 236 V 62" stroke="currentColor" stroke-opacity="0.3" stroke-width="1"/>
<text x="14" y="266" font-size="10" fill-opacity="0.85">only avoid removes the exposure, and it removes the thing that created it</text>
<text x="14" y="288" font-size="10" fill-opacity="0.85">transfer is cheapest in total and leaves the part no policy pays for</text>
<text x="14" y="310" font-size="10" fill-opacity="0.85">every row needs an owner and a date, including the first</text>
</g></svg>
<figcaption>The arithmetic behind each bar is reproducible: an asset worth 400,000 with an exposure factor of 0.3 gives a single loss expectancy of 120,000, and an annualised rate of occurrence of 0.5 gives an ALE of 60,000. Accept carries all of it and spends nothing. Avoid removes it by removing the service, which is why its row has no exposure bar and no money in it either. Transfer buys a policy at 18,000 a year with a 10,000 excess, so half an incident a year leaves 5,000 of retained loss. Mitigate spends 25,000 on a control that cuts the rate from 0.5 to 0.1, which leaves an ALE of 12,000. Transfer wins on total cost and is not obviously the right answer, because the residue it leaves is the part an insurer does not pay for: the regulator, the customers who leave, and the fact that the incident still happened.</figcaption>
</figure>

**Accept.** Carry it. This is correct when the cost of every other option exceeds
the exposure, and it is the treatment people apply by default rather than by
decision. Nothing changes, the residual is the whole of the original risk, and
the only artefact is a record saying somebody chose this.

**Avoid.** Stop doing the thing that creates the risk. This is the only treatment
that removes the exposure rather than reducing it, and it removes the capability
with it. Switching off the file transfer service that nobody could secure is
avoidance, and it is a real answer rather than an admission of defeat.

**Transfer.** Move the financial consequence to somebody else, usually an insurer
or a contract. The important word is financial: the incident still happens, the
regulator still writes to you, and the customers still leave. What moves is the
part of the loss that can be written on a cheque.

**Mitigate.** Reduce the likelihood or the impact with a control. This is what
most of security is, and the thing to keep in view is that it never reaches zero.
A control that cuts the rate of occurrence by four fifths still leaves a fifth,
and that fifth is what you are then accepting.

Those four are what the objectives call risk management strategies, and the
useful thing about the list is what it does not contain. **Every route except
avoidance ends in acceptance.** You mitigate down to a
residual and accept the residual. You transfer the insurable part and accept the
rest. So the accept decision is not one of four options, it is the last step of
three of them, which is why the record of it matters more than the label.

<details class="deeper">
<summary>If you already write treatment plans: what CompTIA's four leave out, and where the fifth one lives</summary>

NIST SP 800-39 is worth reading next to the four, because it names five. Task 3-1
lists risk acceptance, risk avoidance, risk mitigation, **risk sharing**, risk
transfer, or a combination of the above.

Sharing and transfer are separated there for a reason that matters in practice.
Transfer moves the consequence to somebody else, and the classic instrument is
insurance. Sharing distributes it across parties who each carry part, which is
what a consortium, a mutual, or a contract with liability caps on both sides
actually does. In a shared arrangement you still hold some of the loss by design,
and the arrangement usually comes with obligations you have to meet to keep it.

The other word in that clause is the useful one. **A combination of the above** is
the normal case and the exam's four-way choice makes it sound exceptional. A
realistic treatment for a serious risk mitigates what is cheap to mitigate,
insures what is insurable, and accepts what is left, all at once, with three
different owners and three different review dates.

</details>

## Accepting is a decision somebody signs

Go back to the scenario. Three things are wrong with it and none of them is about
the database.

**There is no owner.** "The team" accepted it. When the incident happens, the
question is who made that call, and a ticket closed by whoever picked it up is
not an answer. An owner is a named person senior enough that accepting this
exposure is within their authority, which for an internet-facing unsupported
database is usually not an engineer.

**There is no date.** An acceptance without a review date is permanent, and the
conditions it was based on are not. The database gets a new critical
vulnerability, the service gets more exposed, the company takes on a regulated
customer, and the acceptance made in reasonable circumstances is still sitting
there being cited.

**There is no residual figure.** Nobody wrote down what is being accepted. "Risk
accepted" records the verb and not the object, so the next person cannot tell
whether the decision was that this is a small exposure or that it is a large one
somebody decided to live with.

The fix is not a longer form. It is four fields: what is being accepted, by whom,
until when, and what would make us revisit it sooner.

<details class="deeper">
<summary>If you have chased acceptances: the trigger condition, and why the date alone is not enough</summary>

The review date is the field everybody adds and it is the weaker half of the
control, because it fires on the calendar rather than on the world changing.

The stronger field is the trigger: the specific event that reopens the decision
before the date. For the unsupported database it might be a critical
vulnerability with a public exploit, the service being made available to a new
customer segment, or the vendor announcing the end of security updates. Each of
those is checkable and each one changes the arithmetic the acceptance rested on.

The reason this matters more than the date is availability of attention. Nobody
reviews a register on the day the calendar says. They review it when something
prompts them, and a written trigger is the thing that turns a prompt into a
review rather than into a shrug.

Two triggers are worth writing on almost every acceptance. One is a change in the
threat, which is what a KEV listing or a public exploit represents. The other is
a change in exposure, which is what happens when a service moves from internal to
internet-facing and nobody thinks of it as a security change.

</details>

## Exception, exemption, and why the words are not swapped

The objectives print both and they are not synonyms.

An **exception** is permission to depart from a policy or a standard in a
specific case, for a stated reason, for a stated period. The policy still
applies; this instance is outside it, temporarily and on the record.

An **exemption** is a case the policy does not cover. The requirement is not
being departed from, it was never applicable, and the artefact is a statement of
scope rather than a piece of permission.

The practical difference is what happens next. An exception has an expiry and a
compensating control attached: you are outside the rule, so something else has to
cover the gap while you are. An exemption has neither, because there is no gap to
cover.

**The failure is filing one as the other.** An exemption issued where an exception
was meant removes the expiry and the compensating control at a stroke, and it does
it in a way that looks like paperwork rather than like a decision. A register full
of exemptions where exceptions belong is an organisation that has quietly stopped
applying its own policy.

<details class="deeper">
<summary>If you sit on an exceptions board: what an exception actually has to carry, and the six-month problem</summary>

An exception that is worth granting carries five things: the requirement being
departed from, the reason it cannot be met, the compensating control covering the
gap, the residual that the compensating control does not cover, and the date it
ends.

The fifth is where these go wrong, and the failure has a shape. An exception is
granted for six months because the fix is six months of work. The work does not
start, the six months pass, and the exception is renewed rather than closed,
because refusing the renewal breaks a service that is now in production. The
second renewal is easier than the first, and by the fourth nobody remembers it was
meant to be temporary.

Two things break the cycle and both are process rather than technology. Renewal
goes to a higher authority each time, so the third renewal lands on somebody
senior enough to fund the fix. And the register reports the age of an exception
rather than its expiry date, so a two-year-old temporary measure reads as what it
is.

</details>

## Appetite, tolerance, and the number that reports on both

These two get used interchangeably and they are set in different places by
different people.

<figure class="learn-figure">
<svg viewBox="0 0 720 276" role="img" aria-labelledby="reg-title" style="width:100%;height:auto;">
<title id="reg-title">A risk appetite set once at the top of an organisation, two different tolerances derived from it for two different systems, and the key risk indicator that reports when one of those tolerances is crossed</title>
<g fill="currentColor">
<text x="14" y="20" font-size="11">appetite is set once, tolerance is set per system, and the indicator is what tells you</text>
<rect x="230" y="38" width="250" height="34" rx="4" fill="var(--accent)" fill-opacity="0.14" stroke="var(--accent)" stroke-width="1.8"/>
<text x="244" y="59" font-size="10">appetite, set by the board, one line</text>
<path d="M 300 96 V 74" stroke="currentColor" stroke-opacity="0.7" stroke-width="1.4"/>
<path d="M 410 96 V 74" stroke="currentColor" stroke-opacity="0.7" stroke-width="1.4"/>
<rect x="150" y="96" width="220" height="52" rx="4" fill="none" stroke="currentColor" stroke-opacity="0.7" stroke-width="1.4"/>
<text x="164" y="116" font-size="10">payments: tolerance is zero</text>
<text x="164" y="136" font-size="10">unpatched criticals over 7 days</text>
<rect x="386" y="96" width="220" height="52" rx="4" fill="none" stroke="currentColor" stroke-opacity="0.7" stroke-width="1.4" stroke-dasharray="4 3"/>
<text x="400" y="116" font-size="10">the wiki: tolerance is 30</text>
<text x="400" y="136" font-size="10">unpatched criticals over 7 days</text>
<path d="M 260 178 V 150" stroke="currentColor" stroke-opacity="0.7" stroke-width="1.4"/>
<path d="M 496 178 V 150" stroke="currentColor" stroke-opacity="0.7" stroke-width="1.4"/>
<rect x="150" y="178" width="456" height="34" rx="4" fill="currentColor" fill-opacity="0.07" stroke="currentColor" stroke-opacity="0.7" stroke-width="1.4"/>
<text x="164" y="199" font-size="9.5">indicator: unpatched criticals older than 7 days, counted weekly</text>
<text x="14" y="240" font-size="10" fill-opacity="0.85">one number, two thresholds, and the same measurement means different things on each side</text>
<text x="14" y="262" font-size="10" fill-opacity="0.85">a breach of tolerance is a decision to make, not an incident to declare</text>
</g></svg>
<figcaption>Appetite and tolerance are not two words for the same thing, and the difference is where each one is set. NIST IR 8286 puts appetite at the most senior level of the enterprise, as the guidepost for strategy, and tolerance at the programme, objective or component level below it. So one appetite statement produces different tolerances for different systems: the payment path tolerates nothing, the internal wiki tolerates thirty, and both are consistent with the same sentence from the board. The key risk indicator is the measurement that reports against both, and IR 8286's own framing is the useful one: an indicator demonstrates where tolerances have been exceeded, or validates that the enterprise is operating within its appetite. It is a reporting instrument rather than an alarm, which is why crossing a tolerance produces a conversation rather than a page.</figcaption>
</figure>

**Appetite is set at the top and it is one statement.** NIST IR 8286 puts it at
the most senior level of the enterprise, as the guidepost for setting strategy and
selecting objectives. It sounds like a sentence rather than a number, and that is
correct: it is the frame everything below is derived from.

**Tolerance is set below it, per system or per programme**, and it is a number. IR
8286 places it at the programme, objective or component level. Two systems can
have completely different tolerances and both be consistent with one appetite,
which is the whole reason the two words exist.

The three kinds of appetite the objectives name describe where the sentence sits.
**Expansionary** accepts more risk to move faster or reach further, which is where
a company entering a new market usually is. **Conservative** accepts less and pays
for it in speed, which is where a company under a consent order usually is.
**Neutral** is the middle, and it is worth saying out loud that most organisations
claim neutral and behave expansionary.

**Key risk indicators are the measurements that report against the tolerance.** IR
8286's framing is the useful one: an indicator demonstrates where tolerances have
been exceeded, or validates that the enterprise is operating within the defined
appetite. That is a reporting instrument, not an alarm, and the distinction
matters because a crossed tolerance produces a conversation rather than a page.

<details class="deeper">
<summary>If you report to a board: what makes an indicator useful, and the three that never are</summary>

A useful indicator has three properties. It moves before the loss rather than
after it, so it is a leading measure. It is a number somebody already produces,
so nobody has to do work to report it. And a change in it means one thing, so the
conversation is about what to do rather than about what happened.

Three that fail those tests and appear on almost every dashboard.

**Number of blocked attacks.** It measures how much the internet is doing to you,
which you do not control, and it goes up when you deploy a new sensor. Nothing
follows from a change in it.

**Number of open findings.** It moves when the scanner changes, when a new
subnet is added to the scope, and when somebody tunes out a rule. It is a
measure of the tool as much as of the estate.

**Training completion rate.** It measures attendance. The thing it is a proxy
for, behaviour under a real attempt, is measurable directly and generally is not.

The pattern in all three is that they measure activity rather than exposure.
A useful indicator answers how much of the thing we are afraid of is currently
possible, and the good ones tend to be uncomfortable to report.

</details>

## The register, and what makes one useless

A risk register is a list, and what makes it work or not is what each row carries
rather than how many rows there are.

A row that does its job holds the risk stated as a scenario rather than a
category, an owner who is a person, the current treatment, the residual after
that treatment, the date it is next reviewed, and the indicator that would tell
you it has changed. Risk owners are the field that decides whether any of the
others get maintained.

Three things make a register useless and all three are common.

**Rows that are categories rather than scenarios.** "Cyber attack" is not a risk,
it is a heading. "An attacker uses a stolen contractor credential to reach the
payments database, because that account has standing access and no second factor"
is a risk: it has a mechanism, so it has a treatment, and you can tell whether it
has been treated.

**Owners who are teams.** A risk owned by "Infrastructure" is owned by nobody.
The test is whether a specific person would be surprised to hear they own it.

**No closure path.** Rows go in and never come out, so the register grows until
its size defeats reading it. A row leaves when the risk is avoided, when the
residual is accepted with a signature, or when the thing it describes no longer
exists.

**Risk reporting is the part that makes the rest real.** A register nobody reports
from is a document. Reporting turns it into a mechanism, because it forces somebody to
say out loud, on a schedule, which risks are being carried and by whom, and that
is the moment an acceptance made quietly two years ago gets looked at.

<details class="deeper">
<summary>If you maintain a register: how the assessment cadence changes what belongs in it</summary>

The objectives name four assessment cadences and they produce different registers.

**Ad hoc** assessment happens because something prompted it, usually an incident
or an acquisition. It produces a deep register on a narrow scope, and its risk is
that the scope was chosen by whatever prompted it rather than by where the
exposure is.

**One-time** assessment is scoped to a project or a change. It has a natural end,
and its failure mode is that the register is archived with the project while the
system it described stays in production.

**Recurring** assessment is the annual or quarterly pass. It is the one most
organisations do, it is the easiest to fund, and it measures a moving system at
fixed points, so it is always describing a state that has already changed.

**Continuous** assessment feeds from the tooling rather than from a review, and
its register is a live view rather than a document. It is the only one that keeps
up, and the reason most organisations do not have it is that it requires the
inventory to be accurate, which brings the problem back to asset management.

The useful combination is continuous for the things a tool can see, which is
patch state, configuration drift and exposure, and recurring for the things it
cannot, which is process, people and third parties.

</details>

## Prove it

**Work it out.** Take the risk in the figure: asset value 400,000, exposure factor
0.3, annualised rate of occurrence 0.5. Confirm the single loss expectancy and the
annualised loss expectancy. Then price the mitigation: a control costing 25,000 a
year that cuts the rate of occurrence to 0.1. What is the new annualised loss
expectancy, what is the total annual cost of choosing that treatment, and at what
control cost would you rather accept the risk instead?

**Work it out again, with the transfer.** A policy costs 18,000 a year and carries
a 10,000 excess per claim. At an occurrence rate of 0.5, what do you expect to pay
in a year, all in? Compare it with the accept figure and the mitigate figure, and
then say what the arithmetic has left out.

**Look it up.** NIST SP 800-39, Task 3-1, names the courses of action for
responding to risk. Read it and answer two questions: how many does it list, and
which one does it name that CompTIA's four do not? The answer to the second is the
distinction between two words most people use as synonyms, and it will change how
you read a contract.

## What trips people up

### 1. Treating acceptance as the absence of a decision

Closing a ticket with "risk accepted" records that nothing was done. It does not
record who decided, what exactly was accepted, or when it gets looked at again.
Without those, it is indistinguishable from having missed it.

### 2. Believing transfer moves the risk

It moves the part of the loss somebody will write a cheque for. The incident still
happens, the notification obligation still applies, and the customers who leave
still leave. Insurance is a treatment for the financial impact and not for the
event.

### 3. Using appetite and tolerance as synonyms

Appetite is one statement from the top of the organisation. Tolerance is a number
set per system underneath it. Two systems with different tolerances can both be
inside one appetite, which is the point of having both words.

### 4. Filing an exemption where an exception belongs

An exception has an expiry and a compensating control because you are outside the
rule. An exemption has neither because the rule never applied. Choosing the wrong
one removes the expiry and the compensating control while looking like paperwork.

### 5. Registers full of categories

"Ransomware" is a heading. A risk has a mechanism, a target and a consequence, and
if it does not, nobody can tell you whether it has been treated.

### 6. Forgetting that mitigation ends in acceptance

A control reduces the risk and leaves a residual, and the residual is being
accepted whether or not anybody writes that down. The register row is not finished
when the control is deployed.

## Work it through

Back to the unsupported database, and the order to take it in.

**First, state the risk as a scenario rather than as a finding.** "Unsupported
database version" is a finding. The risk is that a vulnerability in an unsupported
component, on an internet-facing service, is exploited to reach the data behind
it, with no vendor patch available at the time. That version has a mechanism in
it, which means it has treatments.

**Then price the exposure well enough to compare.** Not precisely, because you
cannot. Well enough to know whether you are arguing about ten thousand a year or a
million, because the answer decides how much attention the decision deserves and
who has to make it.

**Then take the four in order and reject three out loud.** Avoidance means
switching the service off, which the business will not accept, and the cost of
rejecting it is that you are keeping an exposure the business wants. Transfer
means insurance, which pays for some of the loss and none of the notification, so
it is a partial answer at best and is worth pricing rather than dismissing.
Mitigation is the nine-month rewrite, which nobody has, but it is not the only
mitigation available: taking the service off the internet, putting it behind
authentication, segmenting it away from everything else and monitoring it are all
mitigations that cost weeks rather than months and reduce the rate of occurrence
rather than the impact.

**Then accept what is left, properly.** After the cheap mitigations there is still
an unsupported database holding data, and that residual is real. It gets accepted
by a named person with the authority to accept it, with a figure attached, with a
review date, and with a trigger that reopens it early: a public exploit for that
version, or the service taking on a new class of data.

The decision, written the way it should be written down: mitigate what is cheap,
accept the residual with a named owner and a six-month review, and reject
avoidance because the business needs the service. The cost of that rejection is
that we are carrying an unsupported component on the internet, and the trigger
that reopens it is a public exploit.

Notice what changed. The engineer's original answer and this one both leave the
database unpatched. One of them is a decision.

## Try it

**Write one register row properly, for a real risk you already know about.** State
it as a scenario with a mechanism, name a person, name the treatment, write down
what is left after it, and put a review date and a trigger on it. It takes about
ten minutes and it is the difference between a register and a list.

**Find an acceptance that has outlived its reasons.** Every organisation has one:
a decision made under pressure, still cited, on a system that has since changed.
Look for the oldest open exception or the oldest accepted risk and check whether
the conditions it rested on are still true.

**Read NIST SP 800-39 Task 3-1 and count.** Then read the definition of risk
sharing and decide whether the contract your organisation calls risk transfer
actually transfers anything.

## Check yourself

<details class="qa">
<summary>Name the four risk treatments and say which of them leaves no residual risk.</summary>

Accept, avoid, transfer and mitigate. Only avoidance leaves no residual, because
it removes the activity that created the exposure rather than reducing it.

Accept leaves the whole of the original risk. Transfer leaves everything that is
not financial, plus the retained portion such as an excess. Mitigate leaves
whatever the control did not reduce, and that residual is then accepted, which is
why three of the four end in an acceptance.

</details>

<details class="qa">
<summary>An engineer closes a finding with the note "risk accepted". Name three things missing from that decision.</summary>

An owner with the authority to accept it, a review date, and a statement of what
is actually being accepted.

Without an owner, nobody is accountable and nobody senior agreed. Without a date,
the acceptance is permanent while the conditions it rested on are not. Without the
residual written down, the next person cannot tell whether the exposure was judged
small or judged large and carried deliberately. A fourth field is worth adding:
the trigger that reopens the decision before the date.

</details>

<details class="qa">
<summary>Two systems in one organisation have different thresholds for the same measurement. Is that a contradiction?</summary>

No. Appetite is set once at the top of the organisation and tolerance is set per
system underneath it, so one appetite statement produces different tolerances for
systems with different consequences.

A payment path can tolerate zero unpatched criticals while an internal wiki
tolerates thirty, and both can be consistent with the same sentence from the
board. The contradiction would be a tolerance that exceeds the appetite it was
derived from.

</details>

<details class="qa">
<summary>What is the difference between an exception and an exemption, and what does getting them the wrong way round remove?</summary>

An exception is permission to depart from a requirement that does apply, for a
stated reason and a stated period. An exemption is a statement that the
requirement does not apply at all.

Filing an exemption where an exception belongs removes the expiry date and the
compensating control, because neither is needed when nothing is being departed
from. The effect is that a temporary departure becomes permanent and uncovered,
and it happens in a form that looks like administration rather than like a
decision.

</details>

<details class="qa">
<summary>A dashboard reports the number of attacks blocked at the firewall each month. Why is that a poor key risk indicator?</summary>

Because it measures the volume of traffic arriving rather than the exposure you
carry, and nothing follows from a change in it. It rises when the internet gets
noisier and when you deploy another sensor, neither of which is a change in your
risk.

A useful indicator moves before the loss, comes from a number somebody already
produces, and means one thing when it changes. It answers how much of the thing
you are afraid of is currently possible, which tends to make it uncomfortable to
report.

</details>

## References

- [NIST SP 800-39](https://csrc.nist.gov/pubs/sp/800/39/final) - NIST, Managing Information Security Risk. Task 3-1 names the courses of action for responding to risk, and separates sharing from transfer. Free. Accessed 2026-08-21.
- [NIST IR 8286](https://csrc.nist.gov/pubs/ir/8286/final) - NIST, Integrating Cybersecurity and Enterprise Risk Management. The source for where appetite and tolerance are each set, and for what a key risk indicator reports. Free. Accessed 2026-08-21.
- [NIST SP 800-30 Rev. 1](https://csrc.nist.gov/pubs/sp/800/30/r1/final) - NIST, Guide for Conducting Risk Assessments. The likelihood and impact vocabulary the arithmetic rests on. Free. Accessed 2026-08-21.
- [NIST SP 800-37 Rev. 2](https://csrc.nist.gov/pubs/sp/800/37/r2/final) - NIST, the Risk Management Framework, for where a treatment decision sits in an authorisation process. Free. Accessed 2026-08-21.

**Where the numbers came from.** Nothing on this page is a lab capture, because
risk treatment is a decision rather than a system state and there is nothing to
run. The figures are arithmetic, and every number in both of them is reproducible
from the stated inputs: an asset value of 400,000 and an exposure factor of 0.3
give a single loss expectancy of 120,000, and an annualised rate of occurrence of
0.5 gives 60,000. The two definitions attributed to NIST IR 8286 were read from
the document rather than paraphrased from a summary, as was the list in SP 800-39
Task 3-1.

**If you also work on Linux.** The Linux+ track's
[compliance, auditing and integrity](/learn/linux-plus/compliance-auditing-and-integrity)
topic covers the scanning that produces the findings this page decides about, and
the Network+ treatment of
[compliance and audits](/learn/network-plus/compliance-and-audits) covers what an
auditor asks for when they read a register.
