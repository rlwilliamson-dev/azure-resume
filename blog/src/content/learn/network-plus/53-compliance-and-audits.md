---
title: "Compliance and audits"
description: "Why a payment standard and a data protection regulation reach all the way down to how you wire a network, what data locality actually constrains, and why an audit asks you to prove a control works rather than that it exists."
deck: "The audit asks you to prove the control works, not that it exists"
track: "network-plus"
level: "working"
order: 540
objectives:
  - "Say why regulation reaches the network and not just the application"
  - "Explain what data locality constrains and what it costs to get wrong"
  - "Describe what the payment card standard asks of a network and how segmentation changes it"
  - "Name what an audit asks for and what counts as evidence"
  - "Tell the difference between a written policy and a running configuration"
prerequisites: ["security-vocabulary-and-the-cia-triad"]
tags: ["network-plus", "networking", "security", "compliance"]
updated: 2026-08-15
draft: false
examObjectives:
  - exam: "n10-009"
    domain: "4.0"
    objective: "4.1"
sources:
  - title: "PCI DSS v4.0.1, Payment Card Industry Data Security Standard"
    url: "https://www.pcisecuritystandards.org/document_library/"
    publisher: "PCI Security Standards Council"
    accessed: 2026-08-15
    tier: 1
  - title: "Regulation (EU) 2016/679 (General Data Protection Regulation)"
    url: "https://eur-lex.europa.eu/eli/reg/2016/679/oj"
    publisher: "Official Journal of the European Union"
    accessed: 2026-08-15
    tier: 1
  - title: "NIST SP 800-53A Rev. 5, Assessing Security and Privacy Controls"
    url: "https://csrc.nist.gov/pubs/sp/800/53/a/r5/final"
    publisher: "NIST"
    accessed: 2026-08-15
    tier: 1
symptoms:
  - symptom: "A control is written in the policy and not present on the device"
    anchor: "policy-is-not-configuration"
  - symptom: "An audit puts a device in scope that nobody expected"
    anchor: "why-regulation-reaches-the-network"
---

> **Before you read.** A policy document says that the payment systems are
> isolated from the rest of the network. It is signed, it is current, and it has
> been signed off for three years running.
>
> The auditor does not read it. They ask you to show them, from the switch, that
> a packet from a desk in accounts cannot reach the card database.
>
> **The policy says one thing. What decides whether you pass?**

Most of this track is about making a network work. This topic is about proving,
to somebody who does not trust you, that it works the way you say it does. That
is a different job, and the thing worth carrying out of it is that the proof
lives in the configuration, not in the document that describes it.

### Some words you will need

<dl class="terms">
<dt>compliance</dt>
<dd>Meeting a rule set by somebody with the power to penalise you for not meeting it: a regulator, a card scheme, a contract.</dd>
<dt>audit</dt>
<dd>Somebody checking that the rule is met, and asking for evidence rather than assurances.</dd>
<dt>data locality</dt>
<dd>A requirement that data stay in, or not leave, a particular country or region. Also called data residency or sovereignty.</dd>
<dt>PCI DSS</dt>
<dd>The payment card industry's data security standard, which applies to anyone who stores, processes or transmits card data.</dd>
<dt>GDPR</dt>
<dd>The European Union's data protection regulation, which applies by whose data it is rather than by where you are.</dd>
<dt>scope</dt>
<dd>The set of systems an audit examines. Shrinking it is the single most useful thing a network can do for a compliance programme.</dd>
</dl>

## What breaks without this

**A device you forgot about is in scope.** Compliance frameworks pull in every
system that can reach the regulated data, and a flat network means that is every
system. The audit is then larger, slower and more likely to find something.

**You pass the paperwork and fail the check.** A policy that describes a control
the network does not actually enforce is worse than no policy, because it
records that you knew what was required and did not do it.

**Data ends up somewhere it is not allowed to be.** A backup that replicates to
another region, a content network that caches in the wrong country, a support
tool that copies records to a laptop. None of these looks like a breach and each
one can be one.

## Why regulation reaches the network

The instinct is that compliance is an application problem, or a paperwork
problem, and that the network sits underneath it and is not involved. That is
wrong in a specific and testable way: the frameworks define their scope by
reachability, and reachability is a property of the network.

Take the payment card standard. It applies to the systems that handle card data,
which it calls the cardholder data environment, and then it applies to every
system that can reach those, because a system that can reach the card database is
a system that can be used to attack it. On a flat network, everything can reach
everything, so the whole estate is in scope. The audit has to cover all of it,
and every workstation and printer is now a thing you are certifying.

The lever that changes this is segmentation, which is the next topic and is worth
previewing here because it is the reason compliance people care about VLANs.

<figure class="learn-figure">
<svg viewBox="0 0 720 316" role="img" aria-labelledby="scope-title" style="width:100%;height:auto;">
<title id="scope-title">The same five systems on a flat network, where all of them are inside the audit boundary, and on a segmented network, where only the two card systems are</title>
<g fill="currentColor">
<text x="14" y="20" font-size="11">the boundary is what the audit examines, and segmentation moves it</text>
<text x="24" y="46" font-size="10.5">one flat network</text>
<rect x="90" y="56" width="150" height="196" rx="5" fill="var(--red)" fill-opacity="0.07" stroke="var(--red)" stroke-width="1.8" stroke-dasharray="6 4"/>
<rect x="105" y="70" width="120" height="26" rx="3" fill="currentColor" fill-opacity="0.14" stroke="currentColor" stroke-opacity="0.7"/>
<text x="165" y="87" text-anchor="middle" font-size="10">card server</text>
<rect x="105" y="102" width="120" height="26" rx="3" fill="currentColor" fill-opacity="0.14" stroke="currentColor" stroke-opacity="0.7"/>
<text x="165" y="119" text-anchor="middle" font-size="10">card database</text>
<rect x="105" y="134" width="120" height="26" rx="3" fill="currentColor" fill-opacity="0.08" stroke="currentColor" stroke-opacity="0.7"/>
<text x="165" y="151" text-anchor="middle" font-size="10">till</text>
<rect x="105" y="166" width="120" height="26" rx="3" fill="currentColor" fill-opacity="0.08" stroke="currentColor" stroke-opacity="0.7"/>
<text x="165" y="183" text-anchor="middle" font-size="10">staff laptop</text>
<rect x="105" y="198" width="120" height="26" rx="3" fill="currentColor" fill-opacity="0.08" stroke="currentColor" stroke-opacity="0.7"/>
<text x="165" y="215" text-anchor="middle" font-size="10">vending machine</text>
<text x="94" y="270" font-size="10" fill="var(--red)" fill-opacity="0.95">all five in scope</text>
<text x="404" y="46" font-size="10.5">the card systems on their own segment</text>
<rect x="470" y="56" width="150" height="66" rx="5" fill="var(--red)" fill-opacity="0.07" stroke="var(--red)" stroke-width="1.8" stroke-dasharray="6 4"/>
<rect x="485" y="66" width="120" height="22" rx="3" fill="currentColor" fill-opacity="0.14" stroke="currentColor" stroke-opacity="0.7"/>
<text x="545" y="81" text-anchor="middle" font-size="10">card server</text>
<rect x="485" y="92" width="120" height="22" rx="3" fill="currentColor" fill-opacity="0.14" stroke="currentColor" stroke-opacity="0.7"/>
<text x="545" y="107" text-anchor="middle" font-size="10">card database</text>
<text x="474" y="140" font-size="10" fill="var(--red)" fill-opacity="0.95">two in scope</text>
<rect x="470" y="168" width="150" height="84" rx="5" fill="currentColor" fill-opacity="0.04" stroke="currentColor" stroke-opacity="0.55"/>
<rect x="485" y="178" width="120" height="20" rx="3" fill="currentColor" fill-opacity="0.08" stroke="currentColor" stroke-opacity="0.7"/>
<text x="545" y="192" text-anchor="middle" font-size="10">till</text>
<rect x="485" y="200" width="120" height="20" rx="3" fill="currentColor" fill-opacity="0.08" stroke="currentColor" stroke-opacity="0.7"/>
<text x="545" y="214" text-anchor="middle" font-size="10">staff laptop</text>
<rect x="485" y="222" width="120" height="20" rx="3" fill="currentColor" fill-opacity="0.08" stroke="currentColor" stroke-opacity="0.7"/>
<text x="545" y="236" text-anchor="middle" font-size="10">vending machine</text>
<path d="M 600 122 V 168" stroke="currentColor" stroke-opacity="0.6" stroke-width="1.4"/>
<rect x="582" y="137" width="36" height="16" rx="3" fill="currentColor" fill-opacity="0.12" stroke="currentColor" stroke-opacity="0.7"/>
<text x="600" y="149" text-anchor="middle" font-size="9.5">filter</text>
<text x="474" y="268" font-size="10" fill-opacity="0.75">outside the boundary entirely</text>
</g></svg>
<figcaption>Scope is the set of systems an audit examines, and it is drawn by what can reach the regulated data. On a flat network that is everything, so all five systems are certified, tested and documented. Put the card systems on their own segment with a filter controlling what crosses, and the till, the laptop and the vending machine are no longer able to reach the card data, so they leave the audit. The work of certifying them does not get easier, it disappears. That is why a segmentation project pays for itself the first time an audit is scoped.</figcaption>
</figure>

The same reasoning runs the other way for the European data protection
regulation. It applies by whose personal data you are handling, not by where your
servers are, so a company outside Europe handling data about people in Europe is
inside it. And it carries teeth: a breach of personal data has to be reported to
the regulator within 72 hours of becoming aware of it, and the penalties reach
the higher of 20 million euro or four percent of a company's total worldwide
annual turnover. Those numbers are why a network team gets asked where the data
goes.

<details class="deeper">
<summary>If you already scope these: how segmentation shrinks an audit, and how it silently grows one</summary>

Scope is the most valuable thing to control in any compliance regime, and it is a network
decision more than a paperwork one.

A framework applies to systems that handle the regulated data and to anything that can
reach them. So a flat network puts everything in scope, including the printer in
reception, and every device in scope has to meet the standard and be evidenced. Segment
the regulated systems behind an enforced boundary and the scope becomes those systems
plus the boundary, which is a fraction of the estate and a fraction of the audit.

The trap is that scope grows back quietly. A firewall rule opened for a project, a
monitoring system given access to everything, a jump host that can reach both sides, an
administrator's laptop that connects to the regulated segment and to the internet: each
one is a path that pulls something new into scope, and none of them arrives labelled as a
compliance change.

Which is why the scope diagram belongs next to the change process rather than in a folder
for the auditor. The question worth asking on any change touching the boundary is whether
it puts something new in scope, and that question is cheap when asked in advance and
expensive when asked by somebody with a clipboard eleven months later.

</details>

## Data locality, and what it constrains

Data locality is the requirement that data stay inside a jurisdiction, or not
leave one. It sounds like a storage decision and it is a network decision,
because data moves.

The constraints it puts on a network are concrete. A backup target has to be in
the permitted region, which rules out the convenient one in another. A content
delivery network caches copies close to users, which is the whole point of it and
exactly the behaviour a locality rule forbids without care. A cloud region is a
choice with legal weight rather than a latency preference. And traffic that
merely transits another country can matter, because interception is a risk
wherever the packets are.

<details class="deeper">
<summary>If you already work on networks: why this is a routing and replication question, not just a placement one</summary>

Placing the primary database in the right country is the easy half, and the half
that gets audited last. The parts that leak are the ones added for reliability and
speed, which is to say the parts a good engineer adds without being asked.

Replication is the first. A database configured to replicate to a standby for
resilience will happily replicate across a border, and the standby holds a full
copy of the regulated data in a place the rule does not allow. The replication is
correct engineering and a compliance failure at the same time, which is the
uncomfortable shape a lot of this takes.

Caching is the second. A content network's job is to put a copy near the user,
and near can be across a border. The cache is a copy of the data outside the
region, held by a third party, created automatically. Turning it off for
regulated paths is possible and is a decision somebody has to make on purpose.

Backups and disaster recovery are the third, and topic 41 is the reason: a
recovery site in another region is a good idea for every reason except this one,
and reconciling the two is a real piece of design rather than a checkbox.

The pattern across all three is that the leak is added by a mechanism whose job is
resilience or speed, so the review has to look at where data is copied to and not
only where it is served from.

</details>

## Policy is not configuration

Here is the gap the scenario at the top of the page is built on, and it is the
single most useful idea in this topic.

A policy is a statement of intent. It says what should be true. A configuration is
what is actually running on the device, and it says what is true. An audit that is
worth anything checks the second, because the first is a description and
descriptions can be wrong, out of date, or aspirational.

The failure mode is not dishonesty. It is drift. The policy was written when the
network matched it, and then somebody made a change under pressure, at two in the
morning, to fix an outage, and never came back to it. The rule permitting the
accounts desk to reach the card database for one afternoon of troubleshooting is
still there a year later. The policy still says the two are isolated. Both
statements were true when written and only one of them is checked.

**So the useful habit is to treat the policy and the configuration as two things
that have to be reconciled, and to reconcile them with something that reads the
device rather than the document.** That is what topic 60's drift detection is for,
and it is why the last topic in this block is about infrastructure as code: the
whole argument for it is closing this exact gap.

<details class="deeper">
<summary>If you already sit through audits: what evidence actually is, and why screenshots fail</summary>

The gap between intent and configuration is closed by evidence, and most organisations
produce the wrong kind.

A screenshot proves that something was true at the moment it was taken, by somebody with
an interest in it being true, on a system nobody else can check. Auditors know this, which
is why a folder of screenshots produces more questions rather than fewer. What satisfies
is evidence generated by a system rather than by a person: a configuration export with a
timestamp, a report from a tool that read the devices itself, a log the device wrote.

That preference has a useful consequence. Building the evidence generation into the
routine means the audit costs a fraction of what it otherwise does, because the evidence
already exists continuously rather than being assembled in a panic each year. It also
means the organisation finds out about drift when it happens rather than at audit time,
which topic 37 covers and which is worth more than the audit.

The related trap is a policy written to describe what the auditor wants to hear rather
than what the organisation does. That guarantees a finding, since the evidence will
contradict it, and it is worse than a policy honestly describing a weaker control. A
documented exception with a reason and a date is an ordinary thing in an audit. A policy
that is not followed is a finding every time.

</details>

## What an audit actually asks for

An audit does not ask whether you have a control. It asks you to demonstrate that
the control operates, and there is a real difference between the two.

Demonstrating that a control exists is showing the rule in the configuration.
Demonstrating that it operates is showing that the rule does what it is supposed
to: that the traffic it is meant to block is actually blocked, tested from the
side it is meant to be blocked from. The first is a screenshot. The second is a
packet that does not arrive, captured, with the date on it.

The evidence that survives an auditor has a few properties worth knowing before
you are asked for it. It is dated, because a control that worked at some
unspecified time is not evidence it works now. It is attributable, so the change
that introduced it has an author and a reason, which is most of the argument for
keeping network configuration under version control. And it is reproducible, so
the auditor can watch you produce it rather than take a document you prepared
earlier. A test run in front of them beats a screenshot every time, because the
screenshot could be of anything.

## Prove it

Nothing here is captured, because compliance is a set of documents and the useful
skill is reading them rather than watching a lab. Both of the documents that
matter are free.

**PCI DSS.** Download the standard from the PCI Security Standards Council's
document library. Read the guidance on network segmentation and answer one
question: does the standard require segmentation, and what does it say happens to
your scope if you do not use it? The answer is the whole reason a compliance team
funds VLANs, argued in the standard's own words rather than asserted here.

**The GDPR.** Read Article 33 on breach notification and Article 83 on penalties,
both short and both on EUR-Lex. The question to answer is how long you have to
report a breach and what the maximum penalty is tied to. Knowing that the penalty
scales with a company's global turnover is what makes the network team's answer to
"where does the data go" matter to the people who sign the cheques.

**NIST SP 800-53A.** This is the assessment companion to the controls catalogue,
and it is the clearest free statement of the difference between examine, interview
and test as ways of assessing a control. Read the description of the test method
and note that it is the one that produces evidence a control operates rather than
exists.

## What trips people up

### 1. Treating compliance as an application concern

The frameworks scope themselves by reachability, and reachability is the
network's job. A flat network puts the whole estate in scope, which is a network
decision with a compliance bill attached.

### 2. Showing the rule instead of the effect

A rule in the configuration proves the control exists. An auditor wants to see it
operate, which means the blocked traffic actually failing to arrive, tested from
the right side and dated.

### 3. Believing the policy describes the network

The policy describes what the network was meant to be. Drift is normal, silent,
and exactly what an audit exists to find. The configuration is the fact.

### 4. Forgetting that data moves

Locality is not only about where the primary copy sits. Replication, caching and
backups all create copies elsewhere, added by mechanisms whose job is resilience
or speed, and each one is a place the data now lives.

### 5. Thinking the European regulation stops at Europe

It applies by whose data it is. A company handling data about people in Europe is
inside it regardless of where the company or its servers are.

### 6. Preparing evidence you cannot reproduce

A screenshot prepared in advance could be of anything. Evidence you can generate
live, in front of the auditor, is worth more precisely because it cannot have been
staged.

## Work it through

Back to the scenario, and the order to take it in.

First, stop reaching for the policy. It says the payment systems are isolated, and
whether that is true is not something the document can answer. The auditor is
right to ask for the network instead, and the investigation starts there.

Then reproduce the test the auditor asked for, from the side that matters. A
packet from a desk in accounts to the card database, and whether it arrives. If it
does not, you have your evidence, and it is a demonstration rather than an
assertion. If it does, you have found a real problem before the auditor wrote it
down, which is the good outcome even though it does not feel like one.

Then find out why, if it arrived. Almost always it is drift: a rule added for a
reason that has passed, never removed, quietly widening what can reach the
regulated data. The rule has an age and, if the configuration is under version
control, an author and a stated reason, and reading those turns "how did this
happen" into a specific answer.

Then close the gap in the direction that lasts. Removing the rule fixes today.
Putting the configuration under version control with a drift check, which is
topic 60, is what stops the next rule from surviving a year unnoticed, and it is
what lets you answer the auditor's question next time by running a command rather
than by defending a document.

## Try it

**Read your own network's segmentation the way an auditor would.** Pick the most
sensitive system you can name and ask, from the switch or the firewall, what can
reach it. Not what the diagram says. What the configuration permits.

**Find one rule that outlived its reason.** In any filter edited by several people
over a couple of years, there is usually a permit added for a specific short-lived
purpose that nobody removed. Finding it is the drift this topic is about, made
concrete.

**Read Article 33 of the GDPR and time yourself.** Seventy-two hours from
awareness is less than you think once you account for a weekend. Knowing the clock
exists changes how an incident response plan is written.

## Check yourself

<details class="qa">
<summary>Why does a payment card standard care how a network is segmented?</summary>

Because it scopes itself by reachability. The systems that handle card data are in
scope, and so is everything that can reach them, on the reasoning that a system
which can reach the card database can be used to attack it.

On a flat network everything can reach everything, so the whole estate is in
scope and has to be certified. Segmentation removes the systems that cannot reach
the card data from the audit entirely, which is why it is the single most
effective thing a network can do for a compliance programme.

</details>

<details class="qa">
<summary>What is the difference between a control existing and a control operating, and why does an auditor care?</summary>

A control exists when the rule is in the configuration. A control operates when
the rule actually does its job: the traffic it should block is blocked, tested
from the side it is meant to be blocked from.

An auditor cares because a rule can be present and ineffective, shadowed by
another rule, applied to the wrong interface, or undone by a change elsewhere.
Showing the rule is a screenshot. Showing the effect is a test, dated and
reproducible, and only the second is evidence.

</details>

<details class="qa">
<summary>A signed, current policy says two networks are isolated. Why might that not be true?</summary>

Because a policy states intent and a configuration states fact, and they drift
apart. The isolation was real when the policy was written, and then a rule was
added under pressure and never removed. Both statements were true once; only the
configuration is true now.

The policy is not evidence of the network's state. The device is, which is why an
audit reads the configuration and why version control on that configuration is
what makes drift findable.

</details>

<details class="qa">
<summary>Your servers are all outside Europe. Why might the European data protection regulation still apply?</summary>

Because it applies by whose personal data you are processing, not by where you
process it. Handling data about people in Europe places you inside the regulation
regardless of where the company or its infrastructure sits.

That is also why data locality is a network question: knowing where regulated data
is stored, replicated, cached and backed up is the only way to answer whether it
has left a place it was required to stay.

</details>

<details class="qa">
<summary>Where does data locality most often leak, and why is it easy to miss?</summary>

In the mechanisms added for resilience and speed: replication to a standby,
caching near users, and backups to a recovery site. Each one creates a copy of the
data somewhere other than where it is served from.

It is easy to miss because each of those is correct engineering. A database that
replicates to a standby is doing exactly what it should; the standby just happens
to hold a full copy of regulated data in a place the rule does not allow. The
review has to follow where data is copied to, not only where it is placed.

</details>

## References

- [PCI DSS](https://www.pcisecuritystandards.org/document_library/) - PCI Security Standards Council, the payment card data security standard and the source of the segmentation-and-scope argument. Free. Accessed 2026-08-15.
- [Regulation (EU) 2016/679](https://eur-lex.europa.eu/eli/reg/2016/679/oj) - Official Journal of the European Union, the GDPR, including Article 33 on breach notification and Article 83 on penalties. Free. Accessed 2026-08-15.
- [NIST SP 800-53A Rev. 5](https://csrc.nist.gov/pubs/sp/800/53/a/r5/final) - NIST, the assessment companion that defines examine, interview and test as methods, and the source of the control-operates-versus-exists distinction. Free. Accessed 2026-08-15.

**Where the numbers came from.** The breach notification window of 72 hours is
GDPR Article 33 and the penalty ceiling of 20 million euro or four percent of
worldwide annual turnover is Article 83, both read from the regulation on EUR-Lex.
Nothing on this page is a lab capture, because compliance is documents and the
skill is reading them; the figure is illustrative and its five systems are chosen
to show scope shrinking rather than taken from a real audit.

**If you also work on Linux.** The reconciling-policy-with-configuration idea has
a direct Linux form in `nft list ruleset` against a committed rules file, and the
version-control habit is the same one topic 60 builds. There is no locality
setting to point at, because locality is a property of where you run things rather
than of a host.
