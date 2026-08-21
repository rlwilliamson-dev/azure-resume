---
title: "Security vocabulary and the CIA triad"
description: "Five words everybody uses and half of them mean something else. Risk, vulnerability, threat and exploit as four distinct things, why availability is a security property rather than an operations one, and what the triad is for."
deck: "Everyone uses these five words and half of them mean something else"
track: "network-plus"
level: "intro"
order: 340
objectives:
  - "Distinguish risk, vulnerability, threat and exploit"
  - "State the three properties of the CIA triad and give a network example of each"
  - "Explain why availability belongs in a security model"
  - "Say what risk is a function of, and why that makes it comparable"
  - "Recognise where the triad helps and where it stops"
prerequisites: ["the-boxes-on-a-network"]
tags: ["network-plus", "networking", "security", "beginner"]
updated: 2026-08-11
draft: false
examObjectives:
  - exam: "n10-009"
    domain: "4.0"
    objective: "4.1"
sources:
  - title: "RFC 4949, Internet Security Glossary, Version 2"
    url: "https://www.rfc-editor.org/rfc/rfc4949"
    publisher: "IETF"
    accessed: 2026-08-11
    tier: 1
  - title: "NIST SP 800-30 Rev. 1, Guide for Conducting Risk Assessments"
    url: "https://csrc.nist.gov/pubs/sp/800/30/r1/final"
    publisher: "NIST"
    accessed: 2026-08-11
    tier: 1
  - title: "FIPS 199, Standards for Security Categorization of Federal Information and Information Systems"
    url: "https://csrc.nist.gov/pubs/fips/199/final"
    publisher: "NIST"
    accessed: 2026-08-11
    tier: 1
symptoms:
  - symptom: "A scan result is treated as an incident"
    anchor: "four-words-that-are-not-synonyms"
  - symptom: "An outage is not treated as a security problem"
    anchor: "why-availability-is-in-there"
---

> **Before you read.** A scanner reports two hundred findings. A manager asks
> which of them are risks. An engineer says all of them, a consultant says none
> of them without more information, and both are being reasonable.
>
> **What is the question actually asking, and why can two competent people
> answer it opposite ways?**

This is a vocabulary topic, which usually means it is dull and skippable. It is
neither, because these particular words are used loosely everywhere including by
people who should know better, and the looseness has consequences: it is how a
list of findings becomes a list of emergencies, and how an outage gets treated as
somebody else's department.

### Some words you will need

<dl class="terms">
<dt>vulnerability</dt>
<dd>A weakness. A property of your own system, present whether or not anybody has noticed it.</dd>
<dt>threat</dt>
<dd>Something that could cause harm. A person, a program, a flood. It exists independently of you.</dd>
<dt>exploit</dt>
<dd>The specific means of using a vulnerability. A technique or a piece of code.</dd>
<dt>risk</dt>
<dd>What you get when a threat meets a vulnerability, weighed by how likely it is and how much it would cost.</dd>
<dt>confidentiality</dt>
<dd>Only the people who should read it can.</dd>
<dt>integrity</dt>
<dd>It has not been altered, and you can tell.</dd>
<dt>availability</dt>
<dd>It is there when it is needed.</dd>
</dl>

## What breaks without this

**Every finding becomes an emergency.** A list of vulnerabilities with no
weighting is a list somebody will work through in the order it was printed, which
is not the order that matters.

**Outages get treated as an operations problem and nothing else.** Availability is
in the triad for a reason, and the reason is that an attack which makes something
unavailable has attacked it.

**You cannot answer the question a manager is actually asking.** Which of these
matters is a different question from which of these is true, and answering the
second one when asked the first is how security teams get ignored.

## Four words that are not synonyms

The four get used interchangeably in conversation, and pulling them apart is the
whole of this section.

A **vulnerability** is a weakness in something you own. An unpatched service, a
default password, a switch port in a meeting room. It is a fact about your system
and it is true whether or not anybody is interested in it.

A **threat** is something that might do harm. Somebody scanning the internet, a
piece of malware, a contractor with a grudge, a burst pipe. It exists whether or
not you are weak.

An **exploit** is the specific means of getting from one to the other. Not the
weakness and not the attacker, but the technique.

**Risk** is what you have when a threat and a vulnerability meet, weighted by how
likely that is and what it would cost.

<figure class="learn-figure">
<svg viewBox="0 0 720 286" role="img" aria-labelledby="risk-title" style="width:100%;height:auto;">
<title id="risk-title">A weakness with nothing that would use it and something that would with no weakness to use, neither of which is a risk, next to the case where both are present</title>
<g fill="currentColor">
<text x="14" y="20" font-size="11">the same four words in three arrangements, and only one of them is a risk</text>
<rect x="14" y="40" width="220" height="176" rx="4" fill="currentColor" fill-opacity="0.04" stroke="currentColor" stroke-width="1" stroke-opacity="0.45"/>
<text x="124" y="64" text-anchor="middle" font-size="11.5" fill="currentColor">a vulnerability</text>
<rect x="34" y="82" width="180" height="34" rx="3" fill="currentColor" fill-opacity="0.1" stroke="currentColor" stroke-opacity="0.5"/>
<text x="124" y="104" text-anchor="middle" font-size="10">an unpatched service</text>
<rect x="34" y="126" width="180" height="34" rx="3" fill="currentColor" fill-opacity="0.03" stroke="currentColor" stroke-opacity="0.3" stroke-dasharray="5 4"/>
<text x="124" y="148" text-anchor="middle" font-size="10" fill-opacity="0.6">nothing is trying it</text>
<text x="124" y="192" text-anchor="middle" font-size="12" fill="currentColor">no risk</text>
<rect x="250" y="40" width="220" height="176" rx="4" fill="currentColor" fill-opacity="0.04" stroke="currentColor" stroke-width="1" stroke-opacity="0.45"/>
<text x="360" y="64" text-anchor="middle" font-size="11.5" fill="currentColor">a threat</text>
<rect x="270" y="82" width="180" height="34" rx="3" fill="currentColor" fill-opacity="0.1" stroke="currentColor" stroke-opacity="0.5"/>
<text x="360" y="104" text-anchor="middle" font-size="10">somebody scanning</text>
<rect x="270" y="126" width="180" height="34" rx="3" fill="currentColor" fill-opacity="0.03" stroke="currentColor" stroke-opacity="0.3" stroke-dasharray="5 4"/>
<text x="360" y="148" text-anchor="middle" font-size="10" fill-opacity="0.6">nothing here is weak</text>
<text x="360" y="192" text-anchor="middle" font-size="12" fill="currentColor">no risk</text>
<rect x="486" y="40" width="220" height="176" rx="4" fill="var(--red)" fill-opacity="0.09" stroke="var(--red)" stroke-width="2"/>
<text x="596" y="64" text-anchor="middle" font-size="11.5" fill="var(--red)">both at once</text>
<rect x="506" y="82" width="180" height="34" rx="3" fill="currentColor" fill-opacity="0.1" stroke="currentColor" stroke-opacity="0.5"/>
<text x="596" y="104" text-anchor="middle" font-size="10">an unpatched service</text>
<rect x="506" y="126" width="180" height="34" rx="3" fill="currentColor" fill-opacity="0.1" stroke="currentColor" stroke-opacity="0.5"/>
<text x="596" y="148" text-anchor="middle" font-size="10" fill-opacity="1">and somebody scanning</text>
<text x="596" y="192" text-anchor="middle" font-size="12" fill="var(--red)">risk</text>
<text x="14" y="248" font-size="10.5">a weakness nobody is interested in is a finding. something interested in a weakness you do not</text>
<text x="14" y="264" font-size="10.5" fill-opacity="0.85">have is somebody else problem. risk needs both, which is why the words are not interchangeable.</text>
<text x="14" y="282" font-size="10.5">and the exploit is the fourth word: the specific means of getting from the second to the first.</text>
</g></svg>
<figcaption>The reason two competent people can answer the manager's question opposite ways. A vulnerability with nothing interested in it is a finding, worth recording and worth fixing eventually. A threat with nothing to attack is somebody else's problem. Neither on its own is a risk, and the word only applies when both are present, which is why a scanner cannot tell you what your risks are. It can only tell you the first column. The consultant who said none of them without more information was asking for the second column, and the engineer who said all of them was reading the first one correctly.</figcaption>
</figure>

**Risk is a function of likelihood and impact**, which is the sentence that makes
the whole vocabulary useful. It turns a list into an ordering. Two hundred
findings become a small number that would be expensive and are being actively
tried, and a large number that would be cheap or that nothing can reach, and the
first group is where the week goes.

NIST SP 800-30 is the free document behind this, and it is worth knowing exists
because it treats risk assessment as a procedure rather than a judgement call. The
useful thing to take from it at this level is that the inputs are separable: you
can assess how bad something would be without knowing how likely it is, and
somebody else can assess the likelihood.

<details class="deeper">
<summary>If you already write risk assessments: why the four words only become useful when they are multiplied</summary>

Pulling the words apart is the first half. The second half is that none of them means
much alone, and the work is in combining them.

A vulnerability with no threat interested in it is a fact you can record and defer. A
threat with no matching vulnerability is somebody else's problem. Risk is the
combination, weighted by what it would cost if it happened, which is why two
organisations can reasonably reach opposite conclusions about the same unpatched
service. One of them has it exposed to the internet carrying payment data; the other
has it on an isolated segment serving a test system.

That is what makes a list of vulnerabilities a poor basis for deciding anything. Every
scanner produces hundreds and ranks them by severity, which is a property of the
weakness in the abstract rather than of your network. Reordering that list by what the
thing actually does, and who can reach it, changes the top of it completely, and it is
the step that turns a scan report into a plan.

The vocabulary earns its precision at the moment somebody asks why a high severity
finding is not being fixed this week. Answering that the threat cannot reach it and
the impact is contained is a defensible position. Answering that it did not seem
important is not, and the difference between those two sentences is entirely whether
the four words were kept separate.

</details>

## The triad

Three properties, and the exam wants all three named. The useful way to hold them
is by what their failure looks like on a network.

**Confidentiality** fails when somebody reads what they should not. Topic 10's
capture of a plaintext password on port 443 is a confidentiality failure with no
attacker in the story at all.

**Integrity** fails when something is altered and you cannot tell. This is the one
people underrate, because it has no obvious symptom. A configuration that has been
changed, a file that has been modified in transit, a routing table with an entry
somebody inserted: none of those announce themselves.

**Availability** fails when the thing is not there. An outage, a saturated link, a
device that has been switched off.

<details class="deeper">
<summary>If you already design controls: the trades between the three, and which one loses by default</summary>

The three properties pull against each other, and most real arguments about a control
are arguments about which one is being traded away.

Encrypting everything raises confidentiality and costs availability, because a lost
key is now data nobody can read, including you. Strict integrity checking rejects
anything altered, which is correct and means a single corrupted record can stop a
process rather than degrade it. Aggressive availability measures, such as failing open
when a check cannot be completed, are a decision to prefer service over the other two,
and it is a decision even when nobody notices making it.

Availability is the one that wins in practice and loses in documentation. When a
control is causing an outage it gets disabled, at speed, by whoever is on call, and it
frequently does not come back. That is not a failure of discipline so much as an honest
statement of what the organisation actually values, and a security design that has not
planned for it will be dismantled during the first incident.

Which suggests writing the trade down rather than pretending it is not there. A control
with a documented fail-open behaviour, agreed in advance, survives an incident. One
that fails closed unexpectedly gets turned off permanently by somebody at three in the
morning who had no time to consider the alternatives.

</details>

## Why availability is in there

The first two are obviously security properties. The third gets argued about, and
the argument is worth having once because it changes how outages get handled.

The case against including it is that an outage is an operations problem. Things
break, and treating a failed power supply as a security incident helps nobody.

The case for it, which is the one the models take, is that **the attacker gets to
choose which property to attack**. If confidentiality and integrity are defended
and availability is not, then denial of service is simply the cheapest way in, and
declaring it out of scope does not make it less effective. Topic 57 is about
exactly that family of attack.

There is a second reason that matters more day to day. **Security controls destroy
availability more often than attackers do.** A filter that blocks legitimate
traffic, a certificate nobody renewed, an authentication server that is
unreachable: every one of those is a control causing the outage. Holding
availability inside the security model is what makes that a security team's
problem rather than something they caused and handed over.

FIPS 199 is the short document here, four pages of actual content, and it defines
the three properties and what low, moderate and high impact mean for each. It is
the clearest statement of the triad in print and it takes ten minutes.

<details class="deeper">
<summary>If you already work on networks: where the triad stops being enough, and the words that got added</summary>

The triad is a checklist rather than a theory, and it is worth knowing what it
does not cover, because the gaps have their own vocabulary and the exam's acronym
list carries some of it.

**Authenticity** is knowing who something came from. It sits close to integrity
and is not the same: a message can be unaltered and still be from somebody
pretending to be your bank. Integrity says the bytes did not change. Authenticity
says the sender is who they claim.

**Non-repudiation** is the sender being unable to deny it afterwards. That is a
property nobody needs until there is a dispute, and then it is the only property
anybody cares about. It is why signatures exist as a separate idea from
encryption.

Both are usually described as extensions to the triad, and the honest framing is
that the triad was never trying to be complete. It is three questions that catch
most of what goes wrong, which is a useful thing to have and a poor thing to
mistake for a model of security.

The place this bites in practice is design review. A design that satisfies all
three can still be one where nobody can prove who did what, and the question that
finds it is not on the checklist. Asking who could deny this afterwards is worth
adding to your own version.

</details>

## Prove it

Nothing to capture, and for once the reason is not the lab. These are definitions,
and a transcript cannot demonstrate a definition. What it can do is show you the
documents, which are unusually good for this subject.

**FIPS 199.** Free, four pages, and it defines the three properties precisely. Read
it and answer one question: does it define impact in terms of what an attacker
gains, or in terms of what the organisation loses? The answer is why risk is
assessable without knowing who the attacker is.

**RFC 4949.** Look up threat, vulnerability, risk and exploit, and read the four
entries next to each other. Doing that once fixes the distinction better than any
explanation, because the glossary is precise in a way conversation is not.

**Then take a real finding and put it in the grid.** Pick anything from a scan
report you have access to. Ask what the weakness is, what would have to exist to
use it, whether that thing exists, and what it would cost if it worked. Four
questions, and the answer to the manager's question falls out of them.

## What trips people up

### 1. Calling a scan result a risk

It is a vulnerability. Whether it is a risk depends on what could reach it and
what it would cost, and the scanner knows neither.

### 2. Treating threat and threat actor as the same word

A threat can be a flood. Loose usage has made threat mean attacker in
conversation, and the documents do not use it that way.

### 3. Leaving availability out of security

The attacker chooses which property to attack, so a defended pair and an
undefended third is a route in rather than a gap in scope. And most availability
failures caused by security are caused by controls.

### 4. Confusing integrity with confidentiality

Confidentiality is who can read it. Integrity is whether it has changed and
whether you would know. Encryption gives the first and does not automatically give
the second.

### 5. Treating the triad as complete

It is three useful questions. Authenticity and non-repudiation sit outside it, and
a design can satisfy all three properties and still leave nobody able to prove who
did what.

### 6. Assessing risk without impact

Likelihood alone ranks nothing useful. Something almost certain and harmless
outranks nothing, and something unlikely and fatal outranks most of the list.

## Work it through

Two hundred findings, and the question of which are risks.

The engineer is describing the first column. Every one of those findings is a real
weakness in a real system, and saying so is accurate. If the question had been
which of these are true, that answer would be complete.

The consultant is pointing at the second column. Without knowing what could reach
each weakness and what it would cost if used, the list cannot be ordered, and an
unordered list of two hundred is not actionable. That answer is also accurate.

The manager asked which of them are risks, which is the question the vocabulary
exists to make answerable, and it needs three things per finding rather than one.
What is the weakness. What would have to exist to use it, and does that exist
here. What would it cost if it worked.

Work an example. A default password on a switch in a locked comms room, on a
management VLAN reachable from two workstations, is a serious weakness with a
small population of things that could reach it. The same default password on a
device reachable from the internet is the same weakness with a very different
answer to the second question, and the two belong in different weeks.

That is the whole method, and it is why the ordering is not derivable from the
scan. The scanner sees the device. It does not see the comms room, the VLAN, or
who has a workstation.

And the last step is the one people skip: write down the ones you are choosing not
to fix, with the reason. A finding accepted deliberately and recorded is a
decision. The same finding left in a list is an oversight, and the difference only
becomes visible after something has happened.

## Try it

**Look up the four words in RFC 4949 and read them together.** Ten minutes, and
the distinction stops being slippery.

**Read FIPS 199.** Four pages, free, and it is the clearest statement of the triad
anywhere.

**Take one finding and answer the three questions.** Weakness, what could reach it,
what it would cost. Doing it once on something real is worth more than the
definitions.

## Check yourself

<details class="qa">
<summary>A scanner reports an unpatched service. Is that a risk?</summary>

It is a vulnerability. Whether it is a risk depends on two things the scanner does
not know.

Is there a threat that could reach it, meaning something that would try and a path
by which it could. And what would it cost if that worked.

A weakness nothing can reach is a finding worth recording and fixing in due
course. The same weakness reachable from the internet is a different item
entirely, and the vocabulary exists so those two can be told apart.

</details>

<details class="qa">
<summary>What is the difference between a vulnerability and a threat, and which one belongs to you?</summary>

A vulnerability is a weakness in your own system and it belongs to you. It is true
whether or not anybody has noticed.

A threat is something that could cause harm and it exists independently of you.
Somebody scanning the internet is a threat to everybody at once, and to nobody in
particular until it meets a weakness.

Risk is what you get where the two intersect, which is why neither on its own can
be ranked.

</details>

<details class="qa">
<summary>Why is availability a security property rather than an operations one?</summary>

Two reasons, and the second matters more day to day.

The attacker chooses which property to attack. If confidentiality and integrity
are defended and availability is not, denial of service becomes the cheapest
route, and calling it out of scope does not make it less effective.

And most availability failures caused by security are caused by controls: a filter
blocking legitimate traffic, an expired certificate, an unreachable authentication
server. Keeping availability inside the model is what makes those a security
team's problem rather than something they caused and handed to somebody else.

</details>

<details class="qa">
<summary>How does encryption relate to the three properties?</summary>

It gives confidentiality directly: only somebody with the key can read it.

It does not automatically give integrity. Whether an altered message is detectable
depends on what else is used alongside the encryption, and the two are separate
properties solved by separate mechanisms.

And it gives nothing at all for availability. An encrypted service that is
unreachable is unavailable, and the encryption has not helped.

</details>

<details class="qa">
<summary>What does the triad leave out?</summary>

Authenticity and non-repudiation.

Authenticity is knowing who something came from, which is close to integrity and
not the same: a message can be unaltered and still be from an impostor. Integrity
is about the bytes, authenticity is about the sender.

Non-repudiation is the sender being unable to deny it afterwards, which nobody
needs until there is a dispute and which is then the only thing anybody wants.

The triad is three questions that catch most of what goes wrong. It was never
trying to be a complete model, and treating it as one is how a design passes review
with nobody able to prove who did what.

</details>

## References

- [RFC 4949](https://www.rfc-editor.org/rfc/rfc4949) - IETF, the internet security glossary, which defines these four words precisely enough to keep them apart. Free. Accessed 2026-08-11.
- [NIST SP 800-30 Rev. 1](https://csrc.nist.gov/pubs/sp/800/30/r1/final) - NIST, on conducting risk assessments, and the source of risk as a function of likelihood and impact rather than as a judgement. Free. Accessed 2026-08-11.
- [FIPS 199](https://csrc.nist.gov/pubs/fips/199/final) - NIST, four pages defining the three properties and what impact means for each. Free. Accessed 2026-08-11.

**Where the numbers came from.** The two hundred findings in the scenario are the
scenario's number rather than a measurement, and there are no other numbers on this
page. Nothing is captured, because these are definitions and a transcript cannot
demonstrate one. The definitions themselves are from RFC 4949 and FIPS 199 rather
than from general usage, which differs from them in exactly the ways this page is
about.

**If you also work on Linux.** Nothing here is a command. The nearest thing is the
habit of asking, of any hardening change you make, which of the three properties it
is protecting and which of them it might cost, because a control that improves
confidentiality at the cost of availability is a trade rather than an improvement.
