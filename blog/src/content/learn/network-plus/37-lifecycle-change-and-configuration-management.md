---
title: "Lifecycle, change and configuration management"
description: "The switch stopped getting firmware updates two years ago and nothing changed on the day it happened. End of life against end of support, what change management is protecting, and why a backup config nobody has restored is not a backup."
deck: "The switch stopped getting firmware updates two years ago"
track: "network-plus"
level: "working"
order: 380
objectives:
  - "Distinguish end of sale, end of life and end of support"
  - "Say why an unsupported device produces no symptom on the day it becomes one"
  - "Explain what change management is protecting against"
  - "Describe configuration drift and how it is detected"
  - "Say what makes a configuration backup a real one"
prerequisites: ["network-documentation-and-diagrams"]
tags: ["network-plus", "networking", "operations"]
updated: 2026-08-11
draft: false
examObjectives:
  - exam: "n10-009"
    domain: "3.0"
    objective: "3.1"
sources:
  - title: "NIST SP 800-128, Guide for Security-Focused Configuration Management of Information Systems"
    url: "https://csrc.nist.gov/pubs/sp/800/128/final"
    publisher: "NIST"
    accessed: 2026-08-11
    tier: 1
  - title: "NIST SP 800-53 Rev. 5, Security and Privacy Controls"
    url: "https://csrc.nist.gov/pubs/sp/800/53/r5/upd1/final"
    publisher: "NIST"
    accessed: 2026-08-11
    tier: 1
  - title: "RFC 6241, Network Configuration Protocol (NETCONF)"
    url: "https://www.rfc-editor.org/rfc/rfc6241"
    publisher: "IETF"
    accessed: 2026-08-11
    tier: 1
symptoms:
  - symptom: "A vulnerability has no fix available for the device it affects"
    anchor: "two-dates-that-get-used-as-one-word"
  - symptom: "Two devices configured identically behave differently"
    anchor: "drift-and-how-it-is-found"
---

> **Before you read.** A switch has been in a comms room for seven years. It
> works. It has never dropped a packet anybody noticed.
>
> An advisory arrives describing a serious flaw in its software. There is no fix,
> and there will not be one.
>
> **When did this become a problem, and why did nobody notice at the time?**

This topic is about dates and process rather than about mechanism, which makes it
easy to skim. It is on the exam because the failures it describes are the ones
that produce an incident with no technical cause, and those are the hardest to
argue about afterwards.

### Some words you will need

<dl class="terms">
<dt>end of sale</dt>
<dd>The date you can no longer buy one. Says nothing about the ones you have.</dd>
<dt>end of support</dt>
<dd>The date fixes stop. Frequently written end of life, which is why the two get confused.</dd>
<dt>configuration drift</dt>
<dd>Devices that should be identical becoming different, one small change at a time.</dd>
<dt>golden configuration</dt>
<dd>The version everything of a given type is supposed to match.</dd>
<dt>change management</dt>
<dd>The process by which a change is proposed, assessed, approved and recorded.</dd>
<dt>rollback</dt>
<dd>The plan for putting it back, written before the change rather than during it.</dd>
</dl>

## What breaks without this

**A vulnerability arrives with no fix.** That is not a surprise on the day it
happens if somebody tracked the dates, and a complete surprise if nobody did.

**Two identical devices behave differently.** Which produces a fault that appears
on one path and not the other, and resists every diagnosis aimed at the traffic.

**A change cannot be undone.** The rollback that was going to be obvious at the
time turns out not to be, at eleven at night, with nobody available.

## Two dates that get used as one word

<figure class="learn-figure">
<svg viewBox="0 0 720 232" role="img" aria-labelledby="eol-title" style="width:100%;height:auto;">
<title id="eol-title">A timeline showing the date a product stops being sold, the date it stops receiving fixes, and the gap between them where equipment is still running</title>
<g fill="currentColor">
<text x="14" y="20" font-size="11">two dates that get used as one word, and the years between them</text>
<line x1="40" y1="120" x2="690" y2="120" stroke="currentColor" stroke-opacity="0.5" stroke-width="1.6"/>
<line x1="120" y1="106" x2="120" y2="134" stroke="currentColor" stroke-opacity="0.6" stroke-width="1.6"/>
<text x="120" y="98" text-anchor="middle" font-size="10.5">bought</text>
<text x="120" y="152" text-anchor="middle" font-size="9.5" fill-opacity="0.75">it goes into a rack</text>
<line x1="330" y1="106" x2="330" y2="134" stroke="currentColor" stroke-opacity="0.6" stroke-width="1.6"/>
<text x="330" y="98" text-anchor="middle" font-size="10.5">end of sale</text>
<text x="330" y="152" text-anchor="middle" font-size="9.5" fill-opacity="0.75">you can no longer buy one</text>
<line x1="540" y1="106" x2="540" y2="134" stroke="currentColor" stroke-opacity="0.6" stroke-width="1.6"/>
<text x="540" y="98" text-anchor="middle" font-size="10.5">end of support</text>
<text x="540" y="152" text-anchor="middle" font-size="9.5" fill-opacity="0.75">no more fixes, ever</text>
<rect x="330" y="62" width="210" height="26" rx="3" fill="currentColor" fill-opacity="0.1" stroke="currentColor" stroke-opacity="0.5"/>
<text x="435" y="80" text-anchor="middle" font-size="10">still supported, still fine</text>
<rect x="540" y="62" width="150" height="26" rx="3" fill="var(--red)" fill-opacity="0.2" stroke="var(--red)" stroke-width="1.8"/>
<text x="615" y="80" text-anchor="middle" font-size="10" fill="var(--red)">still running, unfixable</text>
<text x="14" y="192" font-size="10.5">nothing happens to the device on either date. it keeps forwarding exactly as it did the day before,</text>
<text x="14" y="208" font-size="10.5" fill-opacity="0.85">which is why the second date passes unnoticed and the red stretch is measured in years.</text>
<text x="14" y="228" font-size="10.5">the useful question is not what is unsupported, it is what will be unsupported before we replace it.</text>
</g></svg>
<figcaption>The reason nobody noticed. Neither date does anything to the device: it forwards on the day after end of support exactly as it did the day before, at the same speed, with the same configuration. There is no alarm, no log line and no counter. The only thing that changed is that the manufacturer has stopped writing fixes, which is invisible until the day one is needed, and by then the red stretch has usually been running for years.</figcaption>
</figure>

**End of sale** means you cannot buy a new one. It has no effect on the ones you
own and it is frequently the only date anybody notices, because it arrives as a
sales conversation.

**End of support** means no more fixes. That is the date that matters, and it is
usually years after the first one, which is why treating them as the same word
produces both false alarms and genuine surprises.

The answer to the question at the top is that the switch became a problem on the
end of support date, and nobody noticed because nothing happened. A device does
not change behaviour when its support ends. It carries on working perfectly, and
the only difference is one that is invisible until an advisory arrives.

**So the useful question is not what is unsupported.** It is what will be
unsupported before we plan to replace it, which is a question about a spreadsheet
rather than about the network, and which is why the support status field belongs
in the inventory from the previous topic.

<details class="deeper">
<summary>If you already plan replacements: the third date nobody publishes, and how to find it</summary>

Two published dates and one unpublished one decide when equipment actually has to go.

The unpublished one is when the vendor stops caring in practice, and it arrives before
the formal date. Software releases slow, then stop except for the most serious fixes,
then a fix comes with a note that the platform is no longer being validated. Support
cases start attracting a suggestion to upgrade before anybody looks at the problem.
None of that is announced and all of it is visible if somebody is watching.

The way to see it is the release history rather than the roadmap. A platform receiving
maintenance releases every couple of months and then nothing for a year is finished,
whatever the published date says, and the gap is measurable from the vendor's own
download page.

Which matters because budget cycles are annual and replacement projects take months.
Discovering in March that a platform quietly stopped receiving fixes last summer means
running unsupported equipment until the next budget round, and the alternative is
noticing the pattern a year earlier when the decision was still cheap. That is a
recurring calendar entry to check release histories rather than a technical control,
which is exactly why it does not get done.

</details>

## Patching, and the three cycles that are not one

Operating system, firmware and application updates are separate cycles on network
equipment, and the exam separates them because they behave differently.

Firmware is the one people neglect, because updating it usually means a reboot,
which means an outage, which means a change window. So the update that fixes the
serious flaw waits for a window, and windows are scarce, and the wait becomes
permanent.

That is worth naming as a pattern rather than a failing. **The cost of applying an
update is visible and immediate, and the cost of not applying it is invisible
until it is enormous.** Any process that relies on somebody choosing the second
will drift towards not patching, which is why scheduled windows exist.

<details class="deeper">
<summary>If you already fight for change windows: why the argument is about risk direction, not risk</summary>

The window problem is usually argued as a choice between the risk of patching and the
risk of not patching, and framing it that way is what loses the argument.

The risk of patching is immediate, visible and attributable. Something breaks during
the window, somebody is on the call, and the person who approved it is named. The risk
of not patching is deferred, invisible and diffuse, and if it lands the cause is an
attacker rather than a decision. Any process that weighs those two by how they feel
will defer indefinitely, and most do.

What changes the conversation is making the second risk as concrete as the first.
Not the severity score, which is abstract, but the specific sentence: this flaw is
being exploited, on this class of device, and we have forty of them reachable from
here. That converts a deferred abstraction into something with a date on it, and it is
usually available from the vendor advisory and from national cyber centres.

The other half is reducing what a window costs, since a cheap window gets approved.
Redundant pairs patched one at a time, tested rollback, and a maintenance period
already agreed in the calendar rather than negotiated each time all move firmware
patching from an event into a routine. The organisations that patch firmware promptly
are almost never the ones with the best arguments. They are the ones for whom it stopped
requiring an argument.

</details>

## Change management, and what it is protecting

Change management gets described as bureaucracy, and it is worth being precise
about what it is buying, because a process nobody can justify gets worked around.

It buys three things.

**Somebody other than the author looked at it.** Most changes that break things
break them in a way that is obvious to a second person and invisible to the
person who wrote it.

**There is a record of what changed and when.** Which is the first question asked
after any unexplained fault, and the only reliable answer is a change log rather
than anybody's memory.

**There is a rollback plan written before the change.** This is the part most
often skipped and the part that matters at eleven at night. A rollback thought
through in advance is a procedure. One improvised during an incident is a guess.

The failure mode of heavy change processes is that people route around them, and a
change made outside the process is worse than a change made badly inside it,
because nothing records it. That trade is the actual design problem, and the
answer is usually that routine low risk changes need a lighter path so that the
heavy one is reserved for changes that deserve it.

## Drift, and how it is found

Twelve switches configured identically at installation are not identical three
years later. Somebody fixed something on one at two in the morning. Somebody
enabled a feature on another for a trial that never ended. None of it was recorded
because each was small.

**Configuration drift is that accumulation**, and its symptom is a fault that
appears on one path and not another, with no difference visible in the traffic.

Finding it is mechanical. Keep a golden configuration for each device type, pull
the running configuration regularly, and compare. The comparison is the whole
control, and the interesting output is not that a device differs but which lines
differ, because those lines are a list of undocumented decisions somebody made.

NETCONF is worth knowing exists here. It is a protocol for retrieving and applying
device configuration in a structured form, which is what makes the comparison
reliable rather than a text diff full of timestamps and counters.

<details class="deeper">
<summary>If you already work on networks: why a backup nobody has restored is not a backup, and the three ways config backups fail</summary>

Every organisation backs up device configurations. A smaller number have ever put
one back, and the gap between those two is where the surprises live.

The first failure is completeness. A configuration file is frequently not
sufficient to rebuild a device, because it does not include the software version
it was written for, any licences, or certificates and keys held separately. A
backup restored onto a device running different software can be rejected line by
line, and the lines it rejects are the ones you least want silently missing.

The second is that the backup captures the running configuration rather than the
saved one, or the reverse, and the two differ precisely when somebody made a
change and did not save it. Which version you hold is a question worth being able
to answer before you need it.

The third is access. The backup lives on a server reachable over the network the
device is part of. In the failure where you most need it, that network is the
thing that is broken, and a great many recovery plans contain that circle without
anybody noticing.

The test that resolves all three costs an afternoon: take a spare device of the
same type, restore a backup onto it, and see whether it comes up. Doing that once
a year is the difference between having backups and believing you do.

</details>

## Decommissioning

The end of the lifecycle, and it is the step that gets abandoned halfway, because
once a device is switched off nobody is chasing anything.

Two things are worth doing properly. **Remove the configuration before disposal**,
because a switch leaving the building carries the wireless key, the RADIUS shared
secret and any credentials in its configuration, and topic 52's argument about
physical access applies with the device in somebody else's van.

And **remove it from everything that references it**: the inventory, the
monitoring, the address management record, the diagram. A decommissioned device
that still exists in four systems is four future confusions, and the abandoned
cable topic 11 described is the same failure in a different material.

## Prove it

Nothing on this page is captured. It is process, and a transcript of a process is
a screenshot of a ticket.

**NIST SP 800-128.** Free, and it is the document behind the vocabulary here. Read
the section on configuration baselines and answer one question: does it treat the
baseline as documentation, or as something changes are measured against
mechanically? The distinction is the difference between a diagram and drift
detection.

**Then find one date.** Pick any device you are responsible for and find its end
of support date on the manufacturer's site. Most people have never looked one up,
and for older equipment the answer is frequently in the past.

**And find out whether a config restore has ever been tested.** Ask. The answer is
usually no, and it is a better use of an afternoon than most audits.

## What trips people up

### 1. Treating end of sale as end of support

The first says you cannot buy one. The second says fixes have stopped. Years
usually separate them, and only the second one matters for equipment you already
own.

### 2. Expecting a symptom on the day support ends

Nothing happens. The device behaves identically, which is why the date passes
unnoticed and the unsupported stretch is measured in years.

### 3. Deferring firmware because it needs a reboot

The cost of applying is visible and the cost of not applying is invisible until an
advisory arrives. A process that leaves the choice to a busy person drifts one way.

### 4. Treating change management as paperwork

It buys review by a second person, a record of what changed, and a rollback
written in advance. Where it is too heavy, people route around it, and an
unrecorded change is worse than a badly reviewed one.

### 5. Assuming identical devices are identical

Three years of small unrecorded fixes is drift, and its symptom is a fault on one
path and not another with nothing visible in the traffic.

### 6. Counting backups you have never restored

A configuration file may not include the software version, licences or keys
needed to rebuild the device, and the server holding it may be unreachable in the
failure where you need it.

## Work it through

The seven year old switch with an advisory and no fix.

First, separate the two questions, because they have different answers and
different timescales. What do we do about this device, and how did we get here
without knowing.

For the device, establish what the flaw actually requires. A flaw exploitable only
from the management interface on a management VLAN reachable by two workstations
is a different item from one exploitable from any port, and topic 33's vocabulary
is what makes that distinction sayable. There is no patch either way, so the
options are compensating controls or replacement, and knowing which flaw you have
decides which is proportionate.

For the compensating controls, the tools are earlier topics. Restrict what can
reach the management interface. Put it behind an access list. Segment it. None of
those fix the flaw and all of them reduce what can reach it, which is the only
lever available when no fix exists.

Then the second question, which is the one worth the effort. This device has been
unsupported for a while, and the reason nobody knew is that support status was not
a field anybody tracked. The fix is in the previous topic: put it in the inventory,
and review it on a schedule rather than when an advisory arrives.

And the last step is the uncomfortable one. If this device is unsupported, others
are, and the useful output of this incident is a list rather than a fix. Producing
that list is a day of work and it is the only thing that stops the same afternoon
happening again in six months with a different box.

## Try it

**Look up one end of support date.** Any device you own. It takes two minutes and
the answer is sometimes startling.

**Diff two switches that should match.** Pull both configurations and compare
them. The differing lines are a list of decisions nobody wrote down.

**Ask whether a restore has ever been tested.** If the answer is no, that is worth
more attention than most of what is on the list this week.

## Check yourself

<details class="qa">
<summary>What is the difference between end of sale and end of support, and which one should be in your inventory?</summary>

End of sale means you cannot buy a new one, which has no effect on equipment you
already own. End of support means fixes have stopped, which is the date that
determines whether a future advisory has an answer.

Support status belongs in the inventory. Years usually separate the two dates, and
tracking the wrong one produces both false alarms and genuine surprises.

</details>

<details class="qa">
<summary>Why does nobody notice the day a device becomes unsupported?</summary>

Because nothing happens to it. It forwards exactly as it did the day before, at
the same speed, with the same configuration. No alarm, no log line, no counter.

The only change is that the manufacturer has stopped writing fixes, which is
invisible until one is needed. By the time an advisory makes it visible, the
device has usually been unsupported for years.

</details>

<details class="qa">
<summary>What does change management actually buy, and what is its failure mode?</summary>

Review by somebody other than the author, a record of what changed and when, and a
rollback plan written before the change rather than improvised during an incident.

Its failure mode is weight. A process heavy enough to be worth avoiding gets
avoided, and a change made outside the process is worse than one made carelessly
inside it, because nothing records it. Routine low risk changes usually need a
lighter path so the heavy one is reserved for changes that warrant it.

</details>

<details class="qa">
<summary>Twelve switches were configured identically three years ago and one behaves differently. How do you find out why?</summary>

Compare each running configuration against the golden configuration for that
device type. The comparison is the control, and the useful output is which lines
differ rather than that a device differs at all.

Those lines are a list of undocumented decisions: something fixed at two in the
morning, a feature enabled for a trial that never ended. Each was small enough not
to be recorded, and together they are the drift.

</details>

<details class="qa">
<summary>Why might a configuration backup fail to restore a device?</summary>

Three common reasons.

It may not be sufficient on its own, because the software version, licences and
any certificates or keys are held separately, and restoring onto a device running
different software can silently reject lines.

It may be the running configuration when you needed the saved one, or the reverse,
and those differ exactly when somebody made a change and did not save it.

And it may be unreachable, because it lives on a server behind the network that is
currently broken. Testing a restore onto spare hardware once a year is what turns
believing you have backups into having them.

</details>

## References

- [NIST SP 800-128](https://csrc.nist.gov/pubs/sp/800/128/final) - NIST, on security-focused configuration management, and the source of the baseline vocabulary. Free. Accessed 2026-08-11.
- [NIST SP 800-53 Rev. 5](https://csrc.nist.gov/pubs/sp/800/53/r5/upd1/final) - NIST, whose configuration management family covers change control. Free. Accessed 2026-08-11.
- [RFC 6241](https://www.rfc-editor.org/rfc/rfc6241) - IETF, NETCONF, which retrieves and applies configuration in a structured form and makes comparison reliable. Free. Accessed 2026-08-11.

**Where the numbers came from.** The seven years and two years in the scenario are
the scenario's numbers. Nothing else on this page is a measurement and nothing is
captured, because this is process rather than mechanism. The three failure modes
for configuration backups are described as common rather than counted, because
this page has no data on their frequency.

**If you also work on Linux.** [Puppet and
OpenTofu](/learn/linux-plus/puppet-and-opentofu) is the same argument with tooling
attached: a declared configuration that is applied repeatedly is drift detection
that runs itself, and the golden configuration stops being a document somebody
compares against by hand.
