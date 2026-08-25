---
title: "Control categories and control types"
description: "Why a locked door, a policy about locking it, a camera watching it and a sign saying so are four different controls, what the two axes actually measure, and why a compensating control is defined by the one it stands in for."
deck: "Four controls, one door, and none of them is doing the same job"
track: "security-plus"
level: "intro"
order: 30
objectives:
  - "Name the four control categories and say what each one describes"
  - "Name the six control types and place four of them against the moment of an incident"
  - "Explain why the two axes are independent, and what that means for an exam item"
  - "Say what makes a control compensating, and what has to be recorded with it"
  - "Choose a control for a stated gap and name what the rejected options would have missed"
prerequisites: ["what-security-actually-protects"]
tags: ["security-plus", "security", "controls", "fundamentals"]
updated: 2026-08-25
draft: false
examObjectives:
  - exam: "sy0-701"
    domain: "1.0"
    objective: "1.1"
sources:
  - title: "NIST SP 800-53 Rev. 5, Security and Privacy Controls for Information Systems and Organizations"
    url: "https://csrc.nist.gov/pubs/sp/800/53/r5/upd1/final"
    publisher: "NIST"
    accessed: 2026-08-25
    tier: 1
  - title: "NIST SP 800-53B, Control Baselines for Information Systems and Organizations"
    url: "https://csrc.nist.gov/pubs/sp/800/53/b/upd1/final"
    publisher: "NIST"
    accessed: 2026-08-25
    tier: 1
  - title: "NIST SP 800-12 Rev. 1, An Introduction to Information Security"
    url: "https://csrc.nist.gov/pubs/sp/800/12/r1/final"
    publisher: "NIST"
    accessed: 2026-08-25
    tier: 1
  - title: "PCI DSS v4.0.1, Payment Card Industry Data Security Standard"
    url: "https://www.pcisecuritystandards.org/document_library/"
    publisher: "PCI Security Standards Council"
    accessed: 2026-08-25
    tier: 1
symptoms:
  - symptom: "An auditor rejects a control that is working"
    anchor: "compensating-is-a-relationship-not-a-kind"
---

> **Before you read.** A server room has a locked door. It has a policy saying the
> door must be locked. It has a camera pointed at the door. And it has a sign
> saying the area is monitored.
>
> Somebody asks you to remove one of the four to save money.
>
> **Which one, and what stops working when you do?**

Four controls, one door, and each one is doing a job the other three do not. The
exam has two words for the difference and they measure different things.

### Some words you will need

<dl class="terms">
<dt>control</dt>
<dd>Anything put in place to reduce risk. A device, a rule, a habit, or a wall.</dd>
<dt>category</dt>
<dd>What implements the control. Technical, managerial, operational or physical.</dd>
<dt>type</dt>
<dd>What the control does about an event, and when. Six of them, below.</dd>
<dt>preventive</dt>
<dd>Stops the thing happening.</dd>
<dt>deterrent</dt>
<dd>Makes somebody decide not to try.</dd>
<dt>detective</dt>
<dd>Notices that it happened. Prevents nothing.</dd>
<dt>corrective</dt>
<dd>Puts things back afterwards.</dd>
<dt>compensating</dt>
<dd>Stands in for a control you wanted and could not have.</dd>
<dt>directive</dt>
<dd>Tells people what they are supposed to do.</dd>
</dl>

## What breaks without this

**Four controls get cut to one.** Somebody notices the door is locked and asks why
the camera, the sign and the policy are also being paid for. Without the
vocabulary to say what each one does, the answer is a feeling.

**An exam item looks ambiguous when it is not.** Half the questions on this
objective give you a control and ask for the category or the type, and reading
them as the same question makes both answers look defensible.

**A compensating control is deployed and not recorded.** It works, the auditor
rejects it anyway, and nobody understands why, because what makes a control
compensating is a piece of paperwork rather than a property of the thing itself.

## Two axes, and they do not constrain each other

The **category** says what kind of thing the control is.

**Technical** controls are implemented by a machine: a firewall rule, disk
encryption, a password requirement enforced by software. **Managerial** controls
are decisions and oversight: a risk assessment, a policy, an approval step.
**Operational** controls are carried out by people as part of running things:
training, access reviews, following a procedure. **Physical** controls are in the
world: locks, walls, cameras, guards.

The **type** says what the control does about an event, which is a completely
separate question.

<figure class="learn-figure">
<svg viewBox="0 0 720 322" role="img" aria-labelledby="grid-title" style="width:100%;height:auto;">
<title id="grid-title">A grid of four control categories against six control types, with a real control named in every one of the twenty-four cells, showing that the two axes are independent of each other</title>
<g fill="currentColor">
<text x="14" y="20" font-size="11">every cell has something in it, which is the answer to "is a firewall preventive"</text>
<text x="14" y="44" font-size="9.5" fill-opacity="0.7">what implements it, down. when it acts, across.</text>
<text x="166" y="66" text-anchor="middle" font-size="9">preventive</text>
<text x="266" y="66" text-anchor="middle" font-size="9">deterrent</text>
<text x="366" y="66" text-anchor="middle" font-size="9">detective</text>
<text x="466" y="66" text-anchor="middle" font-size="9">corrective</text>
<text x="566" y="66" text-anchor="middle" font-size="9">compensating</text>
<text x="666" y="66" text-anchor="middle" font-size="9">directive</text>
<text x="14" y="93" font-size="9.5">technical</text>
<rect x="118" y="74" width="96" height="30" rx="3" fill="currentColor" fill-opacity="0.05" stroke="currentColor" stroke-opacity="0.6" stroke-width="1.1"/>
<text x="166" y="93" text-anchor="middle" font-size="8.5">firewall rule</text>
<rect x="218" y="74" width="96" height="30" rx="3" fill="currentColor" fill-opacity="0.05" stroke="currentColor" stroke-opacity="0.6" stroke-width="1.1"/>
<text x="266" y="93" text-anchor="middle" font-size="8.5">login banner</text>
<rect x="318" y="74" width="96" height="30" rx="3" fill="currentColor" fill-opacity="0.05" stroke="currentColor" stroke-opacity="0.6" stroke-width="1.1"/>
<text x="366" y="87" text-anchor="middle" font-size="8.5">intrusion</text>
<text x="366" y="99" text-anchor="middle" font-size="8.5">detection</text>
<rect x="418" y="74" width="96" height="30" rx="3" fill="currentColor" fill-opacity="0.05" stroke="currentColor" stroke-opacity="0.6" stroke-width="1.1"/>
<text x="466" y="93" text-anchor="middle" font-size="8.5">auto quarantine</text>
<rect x="518" y="74" width="96" height="30" rx="3" fill="currentColor" fill-opacity="0.05" stroke="currentColor" stroke-opacity="0.6" stroke-width="1.1"/>
<text x="566" y="93" text-anchor="middle" font-size="8.5">jump host</text>
<rect x="618" y="74" width="96" height="30" rx="3" fill="currentColor" fill-opacity="0.05" stroke="currentColor" stroke-opacity="0.6" stroke-width="1.1"/>
<text x="666" y="93" text-anchor="middle" font-size="8.5">forced banner</text>
<text x="14" y="131" font-size="9.5">managerial</text>
<rect x="118" y="112" width="96" height="30" rx="3" fill="currentColor" fill-opacity="0.05" stroke="currentColor" stroke-opacity="0.6" stroke-width="1.1"/>
<text x="166" y="131" text-anchor="middle" font-size="8.5">risk assessment</text>
<rect x="218" y="112" width="96" height="30" rx="3" fill="currentColor" fill-opacity="0.05" stroke="currentColor" stroke-opacity="0.6" stroke-width="1.1"/>
<text x="266" y="131" text-anchor="middle" font-size="8.5">stated sanctions</text>
<rect x="318" y="112" width="96" height="30" rx="3" fill="currentColor" fill-opacity="0.05" stroke="currentColor" stroke-opacity="0.6" stroke-width="1.1"/>
<text x="366" y="131" text-anchor="middle" font-size="8.5">internal audit</text>
<rect x="418" y="112" width="96" height="30" rx="3" fill="currentColor" fill-opacity="0.05" stroke="currentColor" stroke-opacity="0.6" stroke-width="1.1"/>
<text x="466" y="125" text-anchor="middle" font-size="8.5">post-incident</text>
<text x="466" y="137" text-anchor="middle" font-size="8.5">review</text>
<rect x="518" y="112" width="96" height="30" rx="3" fill="currentColor" fill-opacity="0.05" stroke="currentColor" stroke-opacity="0.6" stroke-width="1.1"/>
<text x="566" y="125" text-anchor="middle" font-size="8.5">documented</text>
<text x="566" y="137" text-anchor="middle" font-size="8.5">exception</text>
<rect x="618" y="112" width="96" height="30" rx="3" fill="currentColor" fill-opacity="0.05" stroke="currentColor" stroke-opacity="0.6" stroke-width="1.1"/>
<text x="666" y="131" text-anchor="middle" font-size="8.5">the policy</text>
<text x="14" y="169" font-size="9.5">operational</text>
<rect x="118" y="150" width="96" height="30" rx="3" fill="currentColor" fill-opacity="0.05" stroke="currentColor" stroke-opacity="0.6" stroke-width="1.1"/>
<text x="166" y="163" text-anchor="middle" font-size="8.5">awareness</text>
<text x="166" y="175" text-anchor="middle" font-size="8.5">training</text>
<rect x="218" y="150" width="96" height="30" rx="3" fill="currentColor" fill-opacity="0.05" stroke="currentColor" stroke-opacity="0.6" stroke-width="1.1"/>
<text x="266" y="163" text-anchor="middle" font-size="8.5">published</text>
<text x="266" y="175" text-anchor="middle" font-size="8.5">monitoring</text>
<rect x="318" y="150" width="96" height="30" rx="3" fill="currentColor" fill-opacity="0.05" stroke="currentColor" stroke-opacity="0.6" stroke-width="1.1"/>
<text x="366" y="169" text-anchor="middle" font-size="8.5">access review</text>
<rect x="418" y="150" width="96" height="30" rx="3" fill="currentColor" fill-opacity="0.05" stroke="currentColor" stroke-opacity="0.6" stroke-width="1.1"/>
<text x="466" y="163" text-anchor="middle" font-size="8.5">incident</text>
<text x="466" y="175" text-anchor="middle" font-size="8.5">response</text>
<rect x="518" y="150" width="96" height="30" rx="3" fill="currentColor" fill-opacity="0.05" stroke="currentColor" stroke-opacity="0.6" stroke-width="1.1"/>
<text x="566" y="169" text-anchor="middle" font-size="8.5">manual checking</text>
<rect x="618" y="150" width="96" height="30" rx="3" fill="currentColor" fill-opacity="0.05" stroke="currentColor" stroke-opacity="0.6" stroke-width="1.1"/>
<text x="666" y="169" text-anchor="middle" font-size="8.5">the runbook</text>
<text x="14" y="207" font-size="9.5">physical</text>
<rect x="118" y="188" width="96" height="30" rx="3" fill="var(--accent)" fill-opacity="0.16" stroke="var(--accent)" stroke-opacity="0.6" stroke-width="1.6"/>
<text x="166" y="207" text-anchor="middle" font-size="8.5">door lock</text>
<rect x="218" y="188" width="96" height="30" rx="3" fill="currentColor" fill-opacity="0.05" stroke="currentColor" stroke-opacity="0.6" stroke-width="1.1"/>
<text x="266" y="201" text-anchor="middle" font-size="8.5">fencing and</text>
<text x="266" y="213" text-anchor="middle" font-size="8.5">lighting</text>
<rect x="318" y="188" width="96" height="30" rx="3" fill="currentColor" fill-opacity="0.05" stroke="currentColor" stroke-opacity="0.6" stroke-width="1.1"/>
<text x="366" y="207" text-anchor="middle" font-size="8.5">camera</text>
<rect x="418" y="188" width="96" height="30" rx="3" fill="currentColor" fill-opacity="0.05" stroke="currentColor" stroke-opacity="0.6" stroke-width="1.1"/>
<text x="466" y="207" text-anchor="middle" font-size="8.5">fire suppression</text>
<rect x="518" y="188" width="96" height="30" rx="3" fill="currentColor" fill-opacity="0.05" stroke="currentColor" stroke-opacity="0.6" stroke-width="1.1"/>
<text x="566" y="207" text-anchor="middle" font-size="8.5">posted guard</text>
<rect x="618" y="188" width="96" height="30" rx="3" fill="currentColor" fill-opacity="0.05" stroke="currentColor" stroke-opacity="0.6" stroke-width="1.1"/>
<text x="666" y="207" text-anchor="middle" font-size="8.5">signage</text>
<text x="14" y="252" font-size="10" fill-opacity="0.85">a door lock is physical and preventive, and those are two independent facts about it</text>
<text x="14" y="274" font-size="10" fill-opacity="0.85">so an item asking for the category and one asking for the type are different questions</text>
<text x="14" y="296" font-size="10" fill-opacity="0.85">and one control can occupy two cells at once, which is where the arguing starts</text>
</g></svg>
<figcaption>Four categories by six types, and the useful thing about the grid is that it fills up. The category says what implements the control: a machine, a manager, a procedure, or a wall. The type says when it acts and what it does about the event. Those are independent, which is why "is a firewall preventive" is the wrong shape of question: a firewall is technical, and a firewall rule is preventive, and neither fact constrains the other. The accented cell is the one everybody reaches for first, and it is worth noticing how much of the grid is nowhere near it. Cells do get argued about, because a camera nobody watches deters rather than detects and a banner does both, and an exam item resolves that by telling you what the control is there for.</figcaption>
</figure>

**The grid fills up, and that is the finding.** Every combination has something
real in it, because what implements a control tells you nothing about when it acts.
A door lock is physical and preventive. A firewall rule is technical and
preventive. Both of those are preventive and they have nothing else in common.

That is why "is a firewall a preventive control" is not quite the right question.
A firewall is technical. A firewall rule that blocks traffic is preventive. Ask
which axis the question is on before answering it, because the exam asks about
both and they are different items.

<details class="deeper">
<summary>If you already map controls: how these four relate to a real catalogue, and where they do not</summary>

The four categories are a teaching device rather than a structure you will find in
the standards, and knowing that saves an argument later.

NIST SP 800-53 organises its controls into twenty families by subject matter:
access control, audit and accountability, configuration management, and so on. A
family is not a category in the sense used here. Some map cleanly, most contain
controls that would land in two or three of the four, and the catalogue is
deliberately silent about which are technical and which are managerial because it
is describing outcomes rather than implementations.

The place where a real catalogue does use something like this axis is in who is
responsible. A control implemented by a machine is verified by looking at the
machine. One implemented by a person is verified by watching them or by reading
what they produced. That distinction is what an assessor cares about and it is
the durable version of the technical against operational split.

So use the four as a prompt for coverage, which is what they are good for: a
programme made entirely of technical controls has no answer for the person who is
authorised and careless, and one made entirely of policy has no answer for
anything at all.

</details>

## Four of the six are positions on a timeline

The six types are usually taught as a list to memorise, which is why they are hard
to keep apart. Four of them are the same idea at four different moments.

<figure class="learn-figure">
<svg viewBox="0 0 720 344" role="img" aria-labelledby="tl-title" style="width:100%;height:auto;">
<title id="tl-title">The six control types placed against the moment of an incident, with three acting before it, one during, one after, and two that sit outside the timeline entirely</title>
<g fill="currentColor">
<text x="14" y="20" font-size="11">why there are six types, and not one list of good ideas</text>
<path d="M 40 118 H 680" stroke="currentColor" stroke-opacity="0.45" stroke-width="1.2"/>
<path d="M 360 92 V 144" stroke="var(--red)" stroke-opacity="0.9" stroke-width="2"/>
<text x="360" y="160" text-anchor="middle" font-size="10" fill="var(--red)" fill-opacity="0.95">the attempt</text>
<text x="60" y="106" font-size="9.5" fill-opacity="0.7">before</text>
<text x="640" y="106" text-anchor="end" font-size="9.5" fill-opacity="0.7">after</text>
<rect x="46" y="52" width="130" height="26" rx="3" fill="currentColor" fill-opacity="0.08" stroke="currentColor" stroke-opacity="0.65" stroke-width="1.3"/>
<text x="111" y="69" text-anchor="middle" font-size="9.5">deterrent</text>
<text x="46" y="42" font-size="8.5" fill-opacity="0.75">changes their mind</text>
<rect x="196" y="52" width="130" height="26" rx="3" fill="currentColor" fill-opacity="0.08" stroke="currentColor" stroke-opacity="0.65" stroke-width="1.3"/>
<text x="261" y="69" text-anchor="middle" font-size="9.5">preventive</text>
<text x="196" y="42" font-size="8.5" fill-opacity="0.75">stops them succeeding</text>
<rect x="330" y="182" width="130" height="26" rx="3" fill="currentColor" fill-opacity="0.08" stroke="currentColor" stroke-opacity="0.65" stroke-width="1.3"/>
<text x="395" y="199" text-anchor="middle" font-size="9.5">detective</text>
<text x="330" y="224" font-size="8.5" fill-opacity="0.75">notices it happened</text>
<rect x="520" y="52" width="130" height="26" rx="3" fill="currentColor" fill-opacity="0.08" stroke="currentColor" stroke-opacity="0.65" stroke-width="1.3"/>
<text x="585" y="69" text-anchor="middle" font-size="9.5">corrective</text>
<text x="520" y="42" font-size="8.5" fill-opacity="0.75">puts it back</text>
<path d="M 14 258 H 706" stroke="currentColor" stroke-opacity="0.3" stroke-width="1" stroke-dasharray="4 4"/>
<rect x="46" y="266" width="180" height="26" rx="3" fill="var(--accent)" fill-opacity="0.16" stroke="var(--accent)" stroke-width="1.5"/>
<text x="136" y="283" text-anchor="middle" font-size="9.5">directive</text>
<text x="240" y="283" font-size="8.5" fill-opacity="0.8">tells people what to do, at any point</text>
<rect x="46" y="302" width="180" height="26" rx="3" fill="var(--accent)" fill-opacity="0.16" stroke="var(--accent)" stroke-width="1.5"/>
<text x="136" y="319" text-anchor="middle" font-size="9.5">compensating</text>
<text x="240" y="319" font-size="8.5" fill-opacity="0.8">stands in for one of the four above</text>
</g></svg>
<figcaption>Four of the six are positions on one timeline and that is the easiest way to keep them apart. A deterrent works before the attempt and only on somebody capable of changing their mind, which is why it does nothing against automation. A preventive control works at the moment of the attempt and does not care about intent. A detective control produces knowledge afterwards and stops nothing, which is not a criticism: the alternative is not knowing. A corrective control restores the state the incident took away. The other two are not points on the line at all. A directive control tells a person what they are supposed to do, and can sit anywhere. A compensating control is defined by its relationship to a different control rather than to the event: it is what you deploy when the one you wanted is not available, and it inherits whichever position that one had.</figcaption>
</figure>

**A deterrent works before the attempt and only on somebody who can reconsider.**
That is the property worth carrying: a sign saying the area is monitored does
nothing to a script, and quite a lot to a person weighing whether to try.

**A preventive control works at the moment of the attempt** and does not care
about intent. The lock does not know whether you meant well.

**A detective control produces knowledge afterwards and stops nothing.** People
say that as a criticism and it is a description. The alternative to a camera
nobody watches in real time is not knowing what happened, which is worse.

**A corrective control restores what the incident took.** A backup restore, a
rebuilt server, a fire suppression system.

The last two are not points on the line.

**Directive** controls tell a person what they are supposed to do. The policy on
the server room door is directive: it does not lock anything and it establishes
what the expectation was, which is what makes a later breach of it a breach.

**Compensating** is the odd one and it is the one the exam likes, so it gets its
own section.

<details class="deeper">
<summary>If you place controls for a living: the cell people argue about, and how to settle it</summary>

The camera is the classic argument. Is it detective or deterrent?

It is detective, because it records. It is also deterrent, but only in company
with the sign, and only against somebody who reads the sign and cares. A camera
in a ceiling dome that nobody knows about deters nothing at all, and a
conspicuous dummy camera deters without detecting anything.

The way an exam item resolves this is by telling you what the control is there
for. "A camera is installed to record who enters the server room" is detective.
"Signs are posted warning that the area is under surveillance" is deterrent, and
notice that the second sentence is about the sign rather than the camera.

That is the general method and it works on every contested cell. The control's
type is a statement about the job it was deployed to do, not about everything it
incidentally achieves. A login banner warning about monitoring is deterrent by
intent and directive in effect, and an item will say which one it is asking about.

The habit worth building is to read the sentence for the purpose rather than for
the noun. Most disagreements about these six come from two people classifying two
different jobs the same device happens to perform.

</details>

## Compensating is a relationship, not a kind

Every other type describes what the control does. Compensating describes what it
is standing in for, which means **you cannot tell whether a control is
compensating by looking at it.**

A jump host with session recording is a technical control. Whether it is
preventive or compensating depends entirely on the story: if you deployed it
because it is a good idea, it is preventive. If you deployed it because the
application cannot do multifactor authentication and something had to cover that
gap, it is compensating, and the thing that makes it so is the requirement it did
not meet.

Three things have to be recorded with one, and an auditor will ask for all three.

**The control that was wanted.** Named specifically, as a requirement rather than
as a product.

**Why it could not be used.** A technical reason, not a preference. "The vendor
does not support it" is a reason. "It would be inconvenient" is not.

**What is still uncovered.** This is the one people skip and the one that matters.
A compensating control that fully replaced the original would not need the word;
the whole point is that it covers most of the gap, and somebody has to write down
which part it does not.

That last item is why compensating controls have expiry dates in every framework
that takes them seriously. The residual is real, and an arrangement that made
sense as a temporary measure becomes a permanent hole nobody is looking at.

<details class="deeper">
<summary>If you have taken one to an assessor: what "equivalent" is judged against</summary>

The standard that spells this out most usefully is the payment card one, because
it has to deal with a large number of organisations that genuinely cannot meet a
requirement and need a defensible route through.

The test it applies is not whether the compensating control is a good control. It
is whether the control meets the intent and rigour of the original requirement,
addresses the additional risk created by not meeting it, and is at least as
stringent. That is a higher bar than it sounds, and it is why so many submitted
compensating controls are rejected: they are reasonable security measures that
do not happen to address the specific thing the requirement was written for.

The practical consequence is that the argument has to start from the original
requirement's purpose rather than from your control's benefits. If the requirement
exists to stop a stolen credential being reused, a control that improves logging
is not equivalent no matter how good the logging is, because a stolen credential
is still reusable and you now merely know about it.

The other half is that it is documented per requirement rather than per system.
One compensating control covering four requirements is four pieces of
justification, and each one has to stand on its own.

</details>

## Prove it

**Work it out.** Take the four controls on the server room door from the top of
this page. For each, name its category and its type. Then remove each one in turn
and write down what specifically stops working. You should find that the sign and
the policy look like the cheapest cuts and that removing the policy is the one
that changes what happens after an incident.

**Work it out again.** Take one control you can see from where you are sitting.
Place it on both axes. Then change one thing about how it is deployed, not what it
is, and see whether the type moves. A camera with and without a sign is the
easiest one to try.

**Look it up.** NIST SP 800-53 Rev. 5 organises controls into families. Open the
list of families and answer one question: is there a family called "preventive",
and if not, what are the families organised by instead? The answer tells you what
these four categories are for and what they are not.

## What trips people up

### 1. Treating the two axes as one question

Category is what implements it. Type is what it does about an event. An item asks
about one of them, and answering the other produces a confident wrong answer.

### 2. Calling every technical control preventive

A firewall rule is preventive, an intrusion detection system is detective, and
both are technical. The category constrains nothing about the type.

### 3. Deciding a camera is deterrent

It is detective, and it becomes deterrent when somebody knows it is there, which
is usually the sign's job rather than the camera's. Read the item for what the
control was deployed to do.

### 4. Thinking a control is compensating because it is a substitute

It is compensating because a specific requirement could not be met and this
covers the gap. Without the named requirement and the reason, it is just a
control, and an assessor will treat it as one.

### 5. Skipping the residual

The part the compensating control does not cover is the part that matters, and
leaving it out is what turns a temporary measure into a permanent unexamined
hole.

### 6. Dismissing directive controls as paperwork

A policy locks nothing. It also establishes what was expected, which is what makes
a deviation a deviation rather than a surprise, and it is the only control that
works on somebody who has not been given any other.

## Work it through

An application holds customer records and cannot support multifactor
authentication. The vendor confirms it and there is no version that will. The
requirement you are subject to says administrative access to systems holding
customer data requires a second factor.

**First, notice which axis the problem is on.** The requirement asks for a
technical, preventive control. That is what is unavailable, and it is worth saying
out loud, because it constrains what a substitute has to do.

**Then take the obvious substitutes and reject them out loud.** More logging is
detective and the requirement is preventive, so it addresses knowing rather than
stopping. A stronger password policy is technical and preventive and it is the
same factor, so it does not address the thing a second factor exists for. A policy
saying administrators must be careful is directive and stops nothing.

**Then find one that does the original's job.** Put the application behind a jump
host that does require a second factor, and permit administrative access only from
it. The second factor now exists, at a different point in the path, and a stolen
application credential on its own is no longer sufficient.

**Then write down the three things.** The requirement was multifactor on
administrative access. It could not be met because the vendor does not implement
it. What is still uncovered is that anybody already on the jump host reaches the
application with one factor, and that the application's own accounts remain
single-factor for anything that does not traverse the jump host.

**Then put a date on it.** The vendor position can change, the application can be
replaced, and a compensating control with no review date is a permanent exception
nobody re-examined.

The decision, written the way it should be written down: jump host with enforced
second factor and session recording, as a compensating control for the multifactor
requirement, reviewed in six months. The rejected options are additional logging,
which is the wrong type, and a password policy, which is the wrong factor. The
cost of the rejection is that the gap between the jump host and the application is
uncovered and has to be stated rather than quietly carried.

## Try it

**Classify the controls in the room you are in.** The lock, the badge reader, the
window, the fire alarm, the sign about propping doors open. Two axes each, ten
minutes, and the ones that are hard are the ones worth thinking about.

**Find a compensating control where you work.** There is one. Look for a system
that cannot do something a policy requires, and see whether the three pieces of
paperwork exist. In most places at least one of the three is missing, and it is
usually the residual.

**Take one control and try to move it on the grid.** Not to a different cell by
changing the control, but by changing how it is deployed or described. Doing that
once makes the difference between the two axes permanent.

## Check yourself

<details class="qa">
<summary>A server room has a locked door, a policy requiring it to be locked, a camera, and a sign saying the area is monitored. Classify each by type.</summary>

The lock is preventive, the policy is directive, the camera is detective and the
sign is deterrent.

All four are also categorised separately: the lock and the camera are physical,
the policy is managerial, and the sign is physical by implementation while doing a
deterrent job. That is the point of two axes. Removing the sign costs you the
deterrent and leaves the recording intact, and removing the policy costs you the
ability to say afterwards that anything was expected.

</details>

<details class="qa">
<summary>Is a firewall a preventive control?</summary>

The question mixes the two axes. A firewall is a technical control, because a
machine implements it. A firewall rule that blocks traffic is preventive, because
it acts at the moment of the attempt.

Those are two independent facts and neither implies the other. An intrusion
detection system is equally technical and is detective, which is the quickest
demonstration that the category tells you nothing about the type.

</details>

<details class="qa">
<summary>Two organisations deploy the same jump host with session recording. In one it is a preventive control and in the other it is compensating. What differs?</summary>

The reason it was deployed. Compensating is a relationship to a requirement rather
than a property of the device, so nothing about the jump host itself distinguishes
the two cases.

The second organisation could not meet a specific requirement, named it, recorded
why, and deployed the jump host to cover that gap. The first just thought a jump
host was a good idea. You cannot tell which is which by looking at the
infrastructure, only by reading the paperwork.

</details>

<details class="qa">
<summary>What has to be recorded with a compensating control, and which part gets skipped?</summary>

The requirement that could not be met, the technical reason it could not be met,
and what remains uncovered.

The third is the one that gets skipped. A compensating control that covered the
gap completely would not need the word, so there is always a residual, and writing
it down is what stops a temporary measure becoming a permanent hole nobody looks
at. It is also why these carry review dates in any framework that takes them
seriously.

</details>

<details class="qa">
<summary>A deterrent control is deployed against an automated attack. What happens?</summary>

Nothing. A deterrent works by changing somebody's mind before they try, and a
script has no mind to change. Warning banners, signs and published penalties all
depend on a person weighing the attempt.

That is the useful thing about placing the types on a timeline: it makes visible
which controls need a human on the other end and which do not. Preventive,
detective and corrective controls all work regardless of who or what is attacking.

</details>

## References

- [NIST SP 800-53 Rev. 5](https://csrc.nist.gov/pubs/sp/800/53/r5/upd1/final) - NIST, the control catalogue, organised into families by subject rather than into these four categories, which is the point of the Prove it question. Free. Accessed 2026-08-25.
- [NIST SP 800-53B](https://csrc.nist.gov/pubs/sp/800/53/b/upd1/final) - NIST, the control baselines, and where the idea of tailoring a required control into something else is set out. Free. Accessed 2026-08-25.
- [NIST SP 800-12 Rev. 1](https://csrc.nist.gov/pubs/sp/800/12/r1/final) - NIST, an introduction to information security, and the plainest published statement of what each control type does. Free. Accessed 2026-08-25.
- [PCI DSS](https://www.pcisecuritystandards.org/document_library/) - PCI Security Standards Council, the source for what a compensating control has to demonstrate to be accepted, which is the strictest published version of that test. Free. Accessed 2026-08-25.

**Where the content came from.** Nothing on this page is captured, because a
control category is a way of describing a thing rather than a state a machine
holds, and there is no command that returns one. Both figures are built from the
categories and types the objectives name, with a real example placed in each of
the twenty-four cells; the examples are ordinary controls chosen to populate the
grid rather than an inventory of any particular organisation.

**If you also work on Linux.** The Linux+ track's
[hardening a system](/learn/linux-plus/hardening-a-system) topic is a page of
technical preventive controls being applied, and
[compliance, auditing and integrity](/learn/linux-plus/compliance-auditing-and-integrity)
covers the detective half on a real machine.
