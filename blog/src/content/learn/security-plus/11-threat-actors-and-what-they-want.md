---
title: "Threat actors and what they want"
description: "Six categories placed on the two axes the exam uses, why motivation predicts what happens after the intrusion better than technique does, why attribution is hard and still changes your response, and the actor nobody calls an actor."
deck: "Two intrusions, identical technique, and the right response to each is completely different"
track: "security-plus"
level: "intro"
order: 120
objectives:
  - "Name the actor categories and the attributes that distinguish them"
  - "Say why motivation predicts what happens after access is gained"
  - "Explain how resources and sophistication come apart"
  - "Say why attribution is hard and why it still changes the response"
  - "Recognise shadow IT as a threat actor rather than a policy failure"
  - "Say what the two axes cannot tell you"
prerequisites: ["what-security-actually-protects"]
tags: ["security-plus", "security", "threats"]
updated: 2026-08-26
draft: false
examObjectives:
  - exam: "sy0-701"
    domain: "2.0"
    objective: "2.1"
sources:
  - title: "SP 800-30 Rev. 1, Guide for Conducting Risk Assessments"
    url: "https://csrc.nist.gov/pubs/sp/800/30/r1/final"
    publisher: "NIST"
    accessed: 2026-08-26
    tier: 1
  - title: "MITRE ATT&CK Groups"
    url: "https://attack.mitre.org/groups/"
    publisher: "MITRE"
    accessed: 2026-08-26
    tier: 1
  - title: "SP 800-160 Vol. 2 Rev. 1, Developing Cyber-Resilient Systems"
    url: "https://csrc.nist.gov/pubs/sp/800/160/v2/r1/final"
    publisher: "NIST"
    accessed: 2026-08-26
    tier: 1
  - title: "Verizon Data Breach Investigations Report"
    url: "https://www.verizon.com/business/resources/reports/dbir/"
    publisher: "Verizon"
    accessed: 2026-08-26
    tier: 2
symptoms:
  - symptom: "An intrusion is contained and the same access appears again a month later"
    anchor: "motivation-predicts-what-happens-next"
  - symptom: "A department is running a system nobody in technology knows about"
    anchor: "the-actor-nobody-calls-an-actor"
---

> **Before you read.** Two organisations are compromised the same week, by the same
> technique, through the same kind of flaw. One of them is back to normal in three
> days. The other is still finding the attacker eight months later.
>
> **What differs, and it is not the technique.**

What differs is who was on the other end and what they wanted, because that
decides what happens after access is obtained. This block is about reading
evidence rather than choosing controls, and this topic is the vocabulary the rest
of it uses.

### Some words you will need

<dl class="terms">
<dt>threat actor</dt>
<dd>Whoever is on the other end. A category rather than a person, for planning purposes.</dd>
<dt>sophistication</dt>
<dd>How capable they are. Whether they can develop their own tools or use somebody else's.</dd>
<dt>resources</dt>
<dd>What they can spend: money, people, time, and patience.</dd>
<dt>motivation</dt>
<dd>What they want. The attribute that predicts what happens after they are in.</dd>
<dt>attribution</dt>
<dd>Deciding who was responsible. Hard, frequently wrong, and worth attempting anyway.</dd>
<dt>insider threat</dt>
<dd>Somebody who already has legitimate access. Not necessarily malicious.</dd>
<dt>shadow IT</dt>
<dd>Systems and services bought or built outside the technology function.</dd>
<dt>persistence</dt>
<dd>Keeping access after the initial route is closed. What separates a patient actor from an opportunistic one.</dd>
</dl>

## What breaks without this

**The response is planned against the wrong opponent.** An incident treated as
opportunistic is closed after the malware is removed, and the actor who wanted
access rather than a payout is still there.

**Attribution is treated as impossible and therefore skipped.** Nobody asks what
kind of actor this was, so nothing about the response is adjusted.

**Shadow IT is handled as a policy violation.** The department is told off, the
system stays, and the organisation now has an unmanaged asset and an adversarial
relationship with the people who run it.

**Sophistication is inferred from damage.** A crude technique that worked well
gets attributed to a capable actor, and the response is scaled to a threat that is
not there.

## Six categories, and the two axes

<figure class="learn-figure">
<svg viewBox="0 0 720 322" role="img" aria-labelledby="act-title" style="width:100%;height:auto;">
<title id="act-title">Six threat actor categories placed by resources against sophistication, with the motivation that dominates each and the pair the two axes cannot tell apart</title>
<g fill="currentColor">
<text x="14" y="20" font-size="11">what each actor has, and what each one wants</text>
<path d="M 190 250 H 630" stroke="currentColor" stroke-opacity="0.4" stroke-width="1.2"/>
<path d="M 190 250 V 48" stroke="currentColor" stroke-opacity="0.4" stroke-width="1.2"/>
<text x="190" y="268" font-size="8" fill-opacity="0.7">few resources</text>
<text x="630" y="268" text-anchor="end" font-size="8" fill-opacity="0.7">state budget</text>
<text x="180" y="254" text-anchor="end" font-size="8" fill-opacity="0.7">low</text>
<text x="180" y="52" text-anchor="end" font-size="8" fill-opacity="0.7">sophistication</text>
<circle cx="223" cy="220" r="6" fill="var(--accent)" fill-opacity="0.35" stroke="var(--accent)" stroke-width="1.5"/>
<text x="234" y="216" font-size="8.5">unskilled attacker</text>
<text x="234" y="227" font-size="7.5" fill-opacity="0.7">disruption, or curiosity</text>
<circle cx="223" cy="167" r="6" fill="var(--red)" fill-opacity="0.35" stroke="var(--red)" stroke-width="1.5"/>
<text x="234" y="169" font-size="8.5">shadow IT</text>
<text x="234" y="180" font-size="7.5" fill-opacity="0.7">getting the job done</text>
<circle cx="313" cy="194" r="6" fill="var(--accent)" fill-opacity="0.35" stroke="var(--accent)" stroke-width="1.5"/>
<text x="324" y="190" font-size="8.5">hacktivist</text>
<text x="324" y="201" font-size="7.5" fill-opacity="0.7">a message</text>
<circle cx="313" cy="115" r="6" fill="var(--red)" fill-opacity="0.35" stroke="var(--red)" stroke-width="1.5"/>
<text x="324" y="111" font-size="8.5">insider threat</text>
<text x="324" y="122" font-size="7.5" fill-opacity="0.7">grievance, or money</text>
<circle cx="469" cy="137" r="6" fill="var(--accent)" fill-opacity="0.35" stroke="var(--accent)" stroke-width="1.5"/>
<text x="480" y="133" font-size="8.5">organised crime</text>
<text x="480" y="144" font-size="7.5" fill-opacity="0.7">money</text>
<circle cx="571" cy="77" r="6" fill="var(--accent)" fill-opacity="0.35" stroke="var(--accent)" stroke-width="1.5"/>
<text x="560" y="75" text-anchor="end" font-size="8.5">nation-state</text>
<text x="560" y="87" text-anchor="end" font-size="7.5" fill-opacity="0.7">access, kept</text>
<path d="M 223 177 Q 256 141 313 125" fill="none" stroke="var(--red)" stroke-opacity="0.4" stroke-width="1.2" stroke-dasharray="4 3"/>
<text x="14" y="284" font-size="10" fill="var(--red)" fill-opacity="0.9">the two accented points are both already inside, and the axes cannot separate them</text>
<text x="14" y="302" font-size="10" fill-opacity="0.85">one of them intends harm and the other is somebody solving a problem</text>
<text x="14" y="318" font-size="9" fill-opacity="0.7">which is why position on this chart does not tell you what to do about either</text>
</g></svg>
<figcaption>The six categories on the axes the objective names. Position is useful for planning: an actor with a state budget can sustain an operation for years and one without cannot, which changes what your detection has to survive. What the chart cannot do is separate the two accented points. An insider and a shadow IT deployment both start from inside with legitimate access, and neither axis distinguishes somebody who intends harm from somebody solving a problem the organisation did not solve for them. That distinction is the whole of what you do about each, which is why the chart is a starting point rather than an answer.</figcaption>
</figure>

**The unskilled attacker** uses tools other people wrote, against whatever is
reachable, without a particular target in mind. Low resources, low sophistication,
and genuinely dangerous because the tools are good and the internet is large.

**The hacktivist** wants a message delivered. Defacement, leaks, disruption timed
to an event. Sophistication varies enormously and the motivation is public, which
makes this the one category that frequently announces itself.

**The insider threat** already has access. That is the whole of the distinction:
no perimeter to cross, no credential to steal, and every action inside the range
of things they are permitted to do. Motivation is usually grievance or money, and
sometimes neither.

**Organised crime** is a business. Well resourced, competent, and rational about
cost: it goes where the return is, it negotiates, and it stops when the
arithmetic stops working. That predictability is useful.

**The nation-state** has resources that do not run out and time that does not
matter. What distinguishes it is not cleverness but patience: an operation
measured in years, with an objective that is access itself rather than anything
you can pay to make go away.

**Shadow IT** is in the list and it is not an attacker, which is discussed below
because it is the category people argue about.

<details class="predict">
<summary>Two intrusions, both using the same publicly available tool. One turns out to be an unskilled attacker and one a nation-state. Predict what in the evidence distinguishes them.</summary>

**Not the tool, and probably not anything about the initial access.** What
distinguishes them is what happened afterwards.

A capable actor using a common tool is doing so deliberately, and the reasons are
worth knowing. Common tools blend into the noise. They cost nothing to develop.
And using one that thousands of unskilled attackers also use makes attribution
harder, which is a benefit somebody with an interest in not being identified will
pay attention to.

So the distinguishing evidence is in the pattern after access. An opportunistic
actor takes what is immediately available and moves on, and the activity is
short, noisy and undirected. A patient one establishes a second way in before
doing anything else, moves toward a specific objective, avoids the systems that
would raise alarms, and is still present after the first route is closed.

The practical consequence for a response: the question that changes what you do
is not what tool was used but whether the actor has persistence. An intrusion
closed by removing the malware and patching the flaw is complete if the answer is
no and is the beginning of a longer engagement if the answer is yes.

That is why the first three days of an investigation look for additional access
rather than for more malware, and it is the single most useful thing this topic
has to offer.

</details>

## Motivation predicts what happens next

Technique tells you how they got in. Motivation tells you what to expect now, and
it is the more useful of the two for planning a response.

**Financial gain** produces ransomware, fraud and theft of anything saleable, and
it produces an actor who wants to be paid, which means they will make contact, and
who will leave when the transaction concludes or fails.

**Espionage** produces the opposite: an actor who wants to remain unnoticed
indefinitely, takes copies rather than destroying, and treats being detected as
the failure state. Nothing about the intrusion is loud because loudness is the
enemy of the objective.

**Disruption** produces damage as the goal rather than as a side effect.
Availability is the target, the timing usually matters to somebody, and the actor
does not need to remain afterwards.

**Philosophical or political beliefs** produce a message: leaks chosen for
embarrassment, defacement, a claim of responsibility. Publicity is part of the
objective, which is why this category identifies itself.

**Revenge** produces targeted harm to a specific person or organisation, usually
by somebody with prior knowledge, and it frequently overlaps with the insider
category.

**Blackmail** is theft followed by a threat rather than by a sale, and the leverage
is embarrassment rather than encryption.

**War** and state-directed action produce objectives that are not commercial at
all, which is what makes them hard to reason about with commercial intuitions.

**Service disruption and data exfiltration** appear in the objective as motivations
in their own right, and they are worth separating because the response differs:
one is an availability incident with a clear end and the other may have no
observable end at all.

<details class="deeper">
<summary>If you have to write the response plan: what each motivation implies about what you do next</summary>

Motivation is not an intellectual exercise. It changes four practical decisions,
and working through them in advance is what makes an incident faster.

**Whether to negotiate.** Only one category expects a conversation. An actor after
money will make contact and there is a decision to have prepared: who talks, what
is said, whether payment is ever on the table, and who has to approve it. An actor
after access will not contact you and any message purporting to be from them
deserves suspicion.

**How long to look.** An opportunistic intrusion is bounded and the investigation
can conclude. An espionage-motivated one should be assumed to include persistence
you have not found, which means the investigation continues after the visible
problem is fixed, and that is a resourcing decision somebody has to make on day
two rather than week six.

**What to prioritise restoring.** A disruption-motivated actor has chosen your
availability as the target, so restoration is the contest and speed matters more
than understanding. An espionage-motivated one does not care whether you are
running, so taking time to understand costs nothing operationally.

**Who else to tell.** Some motivations imply the actor is working through a
supplier or toward a customer, which means the notification question is wider than
your own organisation.

The awkward part is that motivation is inferred from evidence you gather during
the response, so these decisions are made under uncertainty and revised. The value
of thinking about it in advance is having the decisions identified, so that when
the evidence arrives you know which questions it just answered.

</details>
<details class="deeper">
<summary>If you brief non-technical people: which of the six actually threatens this organisation, and how to work it out</summary>

The six categories are a teaching device, and a board wants to know which of them
applies here. That question is answerable and the method is not intuitive.

Do not start from the actor. Start from what the organisation holds and ask, for
each thing, who would want it and what they would do with it. Customer payment
details have a resale market, which points at organised crime. A design that took
four years and represents a competitive position points at espionage. A service
people depend on being available points at disruption, which could be crime
seeking leverage or an actor with a grievance. Nothing at all of external interest
points at opportunism and at insiders, which is where most organisations actually
sit.

Then ask a second question that people skip: who is upstream and downstream of us.
An organisation with nothing worth taking may still be a route to somebody who
has, and being a supplier to an interesting target makes you interesting by
association. That is the supply chain vector from later in this block, arriving as
an actor question.

Two things worth saying plainly in the briefing. First, that opportunistic activity
is continuous and is not aimed at you: it is aimed at everything, and the defence
against it is being unexceptional rather than being fortified. Second, that the
insider category is the one nobody wants on the slide and it is the one with the
highest base rate, and most of it is carelessness rather than malice.

The output that is useful is short. One or two categories named as the realistic
case, with the reasoning attached, and an explicit statement of which categories
the organisation is choosing not to optimise against. That last sentence is the
valuable one, because it converts an unlimited problem into a bounded one that a
budget can address, and it is the sentence people avoid writing.

</details>


## Why attribution is hard, and why it still matters

**Attribution is hard for structural reasons rather than because investigators are
insufficiently clever.** Infrastructure is rented and shared. Tools are public,
stolen and deliberately reused. Everything about a technique can be imitated by
somebody wanting it attributed elsewhere. Time zones and language artefacts are
easy to fake and frequently faked.

Confident public attribution to a named group usually rests on evidence that is
not in your logs, and an organisation reading its own telemetry should be
correspondingly humble about naming anybody.

**And it still matters**, because the useful question is not the name. It is the
category, and the category is inferable from behaviour with much more confidence
than an identity is. Whether the actor was patient. Whether they established
persistence. Whether they moved toward something specific. Whether they wanted to
be noticed. Every one of those is visible in your own evidence and every one
changes what you do.

The distinction worth carrying: **naming the group is intelligence work you
probably cannot do, and characterising the actor is investigation work you can.**

<details class="deeper">
<summary>If you read threat intelligence: how sophistication and resources come apart, and what that means for defence</summary>

The two axes are drawn together and they are genuinely independent, which produces
two combinations worth understanding.

**High resources with modest sophistication** is more common than the diagrams
suggest. An actor with money can buy access from somebody who already has it, hire
capability, purchase tools and exploits, and sustain an operation for months
without developing anything. Their technical work may be unremarkable and their
persistence is the problem.

**High sophistication with few resources** is the individual researcher, the
capable insider, the small group with real skill and no budget. They can do things
that surprise you and they cannot sustain an operation, so the exposure is sharp
and bounded.

What this means for defence is that the two axes imply different things. Against
resources you need endurance: detection that still works in month eight, logging
retained long enough, and an investigation capability that does not exhaust
itself. Against sophistication you need depth: controls that do not all fail to
the same clever idea.

The category that worries defenders most is the one where both are high, and the
practical implication is uncomfortable. You will not prevent a well-resourced,
capable, patient actor from getting in. What you can do is detect them, and detect
them at a stage where it matters, which is why so much of this exam is about
evidence rather than about walls.

The corollary worth stating: a defence built entirely on prevention is a defence
that works against the bottom-left of the chart and fails silently against the
top-right, and it will look identical to a working defence right up until it
matters.

</details>
<details class="deeper">
<summary>If you assess insider risk: the three kinds, and why programmes built for one handle none of the others</summary>

The insider category collapses three quite different problems into one word, and a
programme built for whichever one somebody had in mind will handle the other two
badly.

**The malicious insider** intends harm: theft for sale, sabotage, taking material
to a competitor. This is the case everybody pictures and the rarest by count. It
is also the one where behavioural signals genuinely exist, because the person is
doing something they know is wrong and the concealment shows.

**The negligent insider** is somebody doing their job carelessly. The file sent to
the wrong address, the customer export copied to a personal drive to work on at
home, the password reused. No intent, no concealment, and by volume this is most
insider incidents. The controls that address it are the data loss prevention and
the guard rails from block E, and behavioural monitoring finds nothing because
there is nothing anomalous about somebody working.

**The compromised insider** is an outside actor using a legitimate account, which
is the same evidence as either of the other two depending on how careful they are.
This is the case that makes insider detection genuinely hard: every technical
signal says an authorised person did an authorised thing.

Programmes built for the malicious case tend to be surveillance-shaped, and they
generate suspicion of employees while missing the negligent case entirely, which
is the one actually costing money. Programmes built for the negligent case are
control-shaped and do not look for concealment.

What covers all three is unglamorous and it is the same thing this exam keeps
returning to: knowing what each account should be able to reach, reviewing that,
and detecting when an account does something outside its own history. That last
one is the behavioural analytics from block E, and its value here is that it does
not require deciding in advance which of the three kinds you are looking at.

</details>

<details class="predict">
<summary>An organisation buys a monitoring product to defend against nation-state activity. Predict whether that is the right purchase.</summary>

**Probably not, and the reason is the base rate rather than the product.**

Work out who is actually likely to be on the other end. For most organisations,
the overwhelming majority of incidents involve opportunistic actors taking what is
reachable, organised crime running a business, and people already inside making
mistakes. A well-resourced state operation is possible and it is not the case to
optimise for unless something about the organisation makes it the case.

The genuine question is what the organisation has that somebody would spend years
obtaining. Intellectual property with strategic value, a position in a supply
chain reaching somebody who has that, or a role that makes the organisation
interesting for political reasons. Those are real and they are a minority.

What makes this worth thinking about rather than dismissing is that the defences
differ. Against the common cases, the answers are the unglamorous ones this exam
spends most of its time on: patching, multifactor authentication, backups that
restore, and removing the shared credential. Against a patient well-funded actor,
those help and none of them is sufficient, and what you need instead is detection
that still works in month eight and logging retained long enough to reconstruct
one.

The uncomfortable version, worth saying to whoever is buying: a product marketed
against the top-right of the chart, bought by an organisation whose actual
exposure is the bottom-left, is money spent on the wrong axis. Deciding which
corner you are defending is a business question that has to be answered before
the procurement rather than during it.

</details>


## The actor nobody calls an actor

Shadow IT is in this list and it does not belong to the same kind of thing as the
other five, which is why it produces arguments.

**It is not an adversary.** It is a department that needed a thing, could not get
it through the technology function in an acceptable timeframe, and bought it with
a card. The person who did it was solving a business problem and frequently
solving it well.

**It is in the list because the effect is the same.** An unmanaged system holding
company data, outside the inventory, outside patching, outside monitoring, with
credentials nobody rotates and an account that will still work after its owner
leaves. Every failure the account and asset topics describe applies to it, and
none of the controls reaches it because nothing knows it exists.

**Treating it as a violation makes it worse**, and this is the part worth
internalising. The response that produces the best security outcome is not
enforcement. It is finding out why the official route was unusable, because the
department will keep needing the thing and the alternative to shadow IT is a
better-supported version of it rather than an absence.

The practical detection route is not technical either. Finance holds the record of
recurring payments to services nobody in technology has heard of, and that list is
the most reliable shadow IT inventory most organisations can produce.

## Prove it

**Work it out.** Take the two intrusions from the top of this page. List the
evidence you would look for to decide which kind of actor each involved, then mark
which items you could actually obtain from your own logging.

**Look it up.** Open the ATT&CK groups list and pick any entry. Read what the
attribution is based on and notice how much of it is not the kind of evidence an
ordinary organisation collects.

**Ask finance.** Request the list of recurring software payments and compare it
with the asset inventory. The difference is your shadow IT, and it takes one
email.

## What trips people up

### 1. Inferring sophistication from damage

A crude technique that worked produces the same damage as a clever one. What
distinguishes a capable actor is patience and persistence, not the initial method.

### 2. Closing an incident when the malware is gone

That is complete for an opportunistic actor and premature for a patient one. The
question is whether persistence exists, and it is the first thing to look for
rather than the last.

### 3. Naming a group from your own logs

Infrastructure is rented, tools are public and reused, and artefacts are easy to
fake. Characterise the actor from behaviour, which you can do, rather than naming
them, which you probably cannot.

### 4. Treating shadow IT as a discipline problem

The department was solving a real problem. Enforcement removes the system and not
the need, and the need returns as a better-hidden version.

### 5. Assuming an insider is malicious

The category is defined by already having access, not by intent. Most insider
incidents are somebody being careless or being deceived, and a programme built for
the malicious case handles neither.

### 6. Planning only for prevention

Prevention works against low resources and low sophistication. Against a patient,
well-funded actor it fails, and it fails silently, which is why the evidence half
of this exam exists.

## Work it through

A ransomware note appears on a file share. The encryption is complete, the note
gives a contact address, and the malware is a family that has been documented for
years.

**The tempting conclusion is organised crime, contain and restore.** The evidence
supports it, the family is known, the note is a business proposition, and the
priority is getting the business running.

**The step worth taking before accepting it is to ask how long they were there.**
Encryption is the last action, not the first, and the interval between initial
access and encryption is usually weeks. In that interval the actor was moving
around, and what they did tells you whether this was purely commercial.

**If the answer is three days and the movement was undirected**, the conclusion
stands, and the response is containment, restoration and closing the route.

**If the answer is four months, with credential collection and access to systems
that had nothing to do with the encryption**, then encryption may be the exit
rather than the objective, and the response has to include the assumption that
copies left and that access may persist. Those are different projects with
different budgets.

**What this rejects is treating the visible act as the incident.** The note is the
part designed to be seen. What it tells you about motivation is one hypothesis
among several, and the evidence that discriminates between them is in the weeks
before it.

The residual worth naming: if the investigation cannot establish how long the
actor was present, because the logs do not go back that far, then the question
cannot be answered and the safe assumption is the more expensive one. That is a
retention decision made months earlier, arriving as a constraint on today's
response.

## Try it

**Characterise a public incident.** Take any published breach report and, without
reading the attribution, decide from the described behaviour which category it
suggests. Then read the attribution.

**Find your own insiders.** Count the accounts with access to your most sensitive
system. That number is the size of the insider category for that system, and it
is usually larger than expected.

**Test the shadow IT route.** Ask a colleague outside technology how they would
get a new tool approved, and how long it takes. The answer explains the shadow IT
you have.

**Ask about persistence.** For the last incident your organisation handled, find
out whether anybody looked for a second means of access. If not, the incident was
closed on an assumption.

## Check yourself

<details class="qa">
<summary>Two intrusions use the same public tool. What distinguishes an unskilled attacker from a capable one?</summary>

What happened after access, not the tool. A capable actor may use a common tool
deliberately, because it blends into noise, costs nothing and makes attribution
harder.

The distinguishing evidence is persistence and direction: whether a second way in
was established before anything else, whether movement was toward something
specific, and whether the actor is still present after the first route is closed.

</details>

<details class="qa">
<summary>Why does motivation matter more than technique when planning a response?</summary>

Because it predicts what happens after access. It decides whether there will be a
negotiation, how long the investigation should continue, whether restoration speed
or understanding matters more, and who else needs to be told.

An actor after money makes contact and leaves when the transaction ends. One after
access treats detection as the failure state and may have no observable end at
all, which changes the resourcing decision on day two.

</details>

<details class="qa">
<summary>Why is attribution hard, and what is worth attempting instead?</summary>

Infrastructure is rented and shared, tools are public and deliberately reused, and
language and timing artefacts are easy to fake. Confident public naming usually
rests on evidence an ordinary organisation does not have.

What is worth attempting is characterisation: whether the actor was patient,
established persistence, moved toward something specific, and wanted to be
noticed. All four are visible in your own evidence and all four change what you
do.

</details>

<details class="qa">
<summary>Why is shadow IT in a list of threat actors?</summary>

Because the effect is the same as an unmanaged system placed by an adversary: it
holds company data, sits outside the inventory, patching and monitoring, and its
accounts survive the departure of whoever created them.

The person responsible was solving a business problem, which is why enforcement
makes it worse. The need does not go away, and the reliable way to find the
existing instances is the list of recurring payments finance already holds.

</details>

<details class="qa">
<summary>How do resources and sophistication come apart, and what does each demand of a defence?</summary>

An actor with money can buy access, hire capability and sustain an operation for
months without developing anything, so high resources with modest sophistication
is common. The reverse, real skill with no budget, produces a sharp and bounded
exposure.

Resources demand endurance: detection that still works in month eight and logging
retained long enough to look back. Sophistication demands depth: controls that do
not all fail to the same idea.

</details>

## References

- [SP 800-30 Rev. 1](https://csrc.nist.gov/pubs/sp/800/30/r1/final) - NIST, risk assessment guidance, for threat sources and how capability and intent are assessed. Free. Accessed 2026-08-26.
- [MITRE ATT&CK Groups](https://attack.mitre.org/groups/) - MITRE, documented actor groups and what each attribution rests on. Free. Accessed 2026-08-26.
- [SP 800-160 Vol. 2 Rev. 1](https://csrc.nist.gov/pubs/sp/800/160/v2/r1/final) - NIST, cyber-resilient systems, for designing against an adversary you cannot keep out. Free. Accessed 2026-08-26.
- [Verizon DBIR](https://www.verizon.com/business/resources/reports/dbir/) - Verizon, annual breach analysis, for the relative frequency of actor categories and motivations. Free. Accessed 2026-08-26.

**Where the content came from.** Nothing on this page is captured. Threat actor
categories are a way of describing people rather than a state a machine reports,
and there is no command that returns one. The categories, attributes and
motivations are read from the objectives and from the NIST guidance cited, and the
observations about attribution are about what evidence exists rather than about
any particular incident.

**If you also work on networks.** The Network+ track's
[attacks on services and people](/learn/network-plus/attacks-on-services-and-people)
covers the techniques these actors use, from the network's point of view.
