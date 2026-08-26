---
title: "Zero day, and the window before the patch"
description: "What the term actually claims, why the window is not the same length for you as for the vendor, two real timelines drawn to scale, and what you can genuinely do about a vulnerability with no fix."
deck: "The patch came out on a Tuesday. The exploit came out on the Thursday before"
track: "security-plus"
level: "working"
order: 190
objectives:
  - "State what zero day claims and what it does not"
  - "Describe the lifecycle from discovery to remediation"
  - "Say why your exposure window differs from the vendor's"
  - "Read two real timelines and compare them"
  - "Say what you can actually do about a vulnerability with no patch"
  - "Explain what coordinated disclosure is and what clock it runs"
prerequisites: ["misconfiguration-and-the-supply-chain"]
tags: ["security-plus", "security", "threats", "vulnerabilities"]
updated: 2026-08-26
draft: false
examObjectives:
  - exam: "sy0-701"
    domain: "2.0"
    objective: "2.3"
sources:
  - title: "SP 800-216, Recommendations for Federal Vulnerability Disclosure Guidelines"
    url: "https://csrc.nist.gov/pubs/sp/800/216/final"
    publisher: "NIST"
    accessed: 2026-08-26
    tier: 1
  - title: "Known Exploited Vulnerabilities Catalog"
    url: "https://www.cisa.gov/known-exploited-vulnerabilities-catalog"
    publisher: "CISA"
    accessed: 2026-08-26
    tier: 1
  - title: "NVD API documentation"
    url: "https://nvd.nist.gov/developers/vulnerabilities"
    publisher: "NIST"
    accessed: 2026-08-26
    tier: 1
  - title: "SP 800-40 Rev. 4, Guide to Enterprise Patch Management Planning"
    url: "https://csrc.nist.gov/pubs/sp/800/40/r4/final"
    publisher: "NIST"
    accessed: 2026-08-26
    tier: 1
symptoms:
  - symptom: "A vulnerability is public and there is no patch"
    anchor: "what-you-can-actually-do"
  - symptom: "A product is described as protecting against zero days"
    anchor: "what-the-term-actually-claims"
---

> **Before you read.** A vendor publishes a patch on a Tuesday. Working exploit
> code for the same flaw was published the previous Thursday, and the flaw itself
> had been reported to the vendor ninety days earlier.
>
> **For how long were you exposed?**

The answer depends on which question you are asking, and the four candidate answers
differ by months. That ambiguity is why the term in this topic's title gets used
for three different things, and sorting them out is most of the work.

### Some words you will need

<dl class="terms">
<dt>zero day</dt>
<dd>A vulnerability the party who could fix it does not know about. A claim about knowledge.</dd>
<dt>discovery</dt>
<dd>Somebody finds the flaw. Who that somebody is decides everything after.</dd>
<dt>disclosure</dt>
<dd>Telling somebody. To the vendor privately, or to the public.</dd>
<dt>coordinated disclosure</dt>
<dd>Reporting to the vendor with an agreed period before publication.</dd>
<dt>exploit</dt>
<dd>Working code that uses the flaw. Its existence is a separate fact from the flaw's.</dd>
<dt>in the wild</dt>
<dd>Observed being used against real targets, as opposed to demonstrated.</dd>
<dt>window of exposure</dt>
<dd>The period during which you were vulnerable and could not have fixed it.</dd>
<dt>remediation</dt>
<dd>The patch reaching your systems, which is later than the patch existing.</dd>
</dl>

## What breaks without this

**A product is bought on a claim about zero days.** The claim is about a category
that is defined by nobody knowing, and what the product actually does is something
else.

**The exposure window is measured from publication.** That is the vendor's window,
and yours starts when the flaw was created and ends when your systems are patched.

**Nothing is done because there is no patch.** There is usually something, and it
is the mitigations from block E rather than a fix.

**Disclosure deadlines are treated as aggressive.** The clock exists because
without one a report can sit indefinitely, which is the outcome it was designed to
prevent.

## What the term actually claims

**Zero day is a statement about knowledge, not about severity.** It says the party
who could issue a fix does not know the flaw exists, and therefore has had zero
days to work on it. That is the whole of the definition.

Three things follow that people get wrong.

**It is not a severity.** A zero-day vulnerability can be trivial. A vulnerability
with a patch available for three years can be catastrophic. The term describes the
vendor's state of knowledge and says nothing about impact.

**It stops being one.** The moment the vendor knows, the clock starts and the term
no longer applies, whatever the marketing says. A flaw that has been public for six
months with no patch is not a zero day; it is an unpatched known vulnerability,
which is a different and usually worse situation.

**And the term is used for three different things.** A vulnerability nobody has
reported. An exploit for a vulnerability nobody has reported. And, loosely, any
attack the speaker's product did not recognise, which is the marketing usage and is
not the same claim at all.

<details class="deeper">
<summary>If you evaluate products: what a zero-day protection claim can honestly mean</summary>

A product cannot detect a vulnerability nobody knows about, because detection
requires knowing what to look for. So a claim about zero-day protection has to mean
something else, and there are three honest versions worth distinguishing from the
dishonest one.

**Behavioural detection.** Rather than recognising the flaw, recognise what
exploitation of any flaw tends to produce: a service process spawning a shell,
memory being made executable, a sequence that no legitimate operation performs.
That is a real capability, it is the EDR argument from block E, and it detects
consequences rather than causes.

**Exploit mitigation.** Rather than detecting anything, make the class harder to
turn into control: non-executable memory, address randomisation, control flow
integrity, guard values. Those work against vulnerabilities nobody has found yet
because they do not depend on knowing about any particular one, which is the
strongest honest version of the claim.

**Virtual patching.** Blocking the specific input pattern at a proxy or an
intrusion prevention device once the flaw is known but before you can patch. That
is genuinely useful and it is not zero-day protection, because it needs the flaw
to be known first.

The dishonest version is a signature-based product describing its ability to catch
anything it has a signature for as zero-day protection, on the grounds that the
signature arrived before the customer patched. That is fast signature delivery,
which is worth having and is a different claim.

The question that separates them in a demonstration: ask what the product would do
against a flaw discovered tomorrow, in a component it has never analysed. The
honest answers are about behaviour and about mitigation. Anything about updates
arriving quickly is answering a different question.

</details>

## Two real timelines

The lifecycle is usually drawn as a neat sequence. Here are two actual ones, from
the public record.

<details class="predict">
<summary>A serious vulnerability becomes public. Predict how long before somebody is observed using it against real targets.</summary>

```bash
# AlmaLinux 10.2, x86_64
$ cve-timeline CVE-2021-44228; echo; cve-timeline CVE-2023-4966
CVE-2021-44228
  published to the public record   2021-12-10
  observed being exploited, added  2021-12-10   (+0 days from publication)
  remediation date set for         2021-12-24   (14 days allowed)
  record last modified             2026-08-11

CVE-2023-4966
  published to the public record   2023-10-10
  observed being exploited, added  2023-10-18   (+8 days from publication)
  remediation date set for         2023-11-08   (21 days allowed)
  record last modified             2026-07-31
```

**Zero days for the first one, and eight for the second.**

The first is the interesting number and it is not a rounding artefact. The flaw was
published to the public record and added to the exploited catalogue on the same
date, which means exploitation was already being observed when it became public.
For that one, there was never a period during which defenders knew and attackers
did not.

The second is closer to what people expect and it is still short. Eight days
between publication and observed exploitation, against a remediation date twenty-one
days after that, which means the required fix date is nearly a month after somebody
was already using it.

Two things worth taking from the pair.

The gap between public and exploited is measured in days rather than in the months
patch cycles assume. Any planning that treats publication as the start of a
comfortable window is planning against a threat model that has not applied for
years.

And the last line of each record is a date in the recent past, because these
records are still being modified years later. A vulnerability's entry is not
finished when it is published, which matters if your process reads it once.

</details>

<figure class="learn-figure">
<svg viewBox="0 0 720 292" role="img" aria-labelledby="zd-title" style="width:100%;height:auto;">
<title id="zd-title">Two real vulnerabilities on one thirty-day axis, showing publication, first observed exploitation and the remediation date each was given</title>
<g fill="currentColor">
<text x="14" y="20" font-size="11">two real vulnerabilities, drawn on the same thirty-day scale</text>
<text x="14" y="80" font-size="9">CVE-2021-44228</text>
<path d="M 152 76 H 668" stroke="currentColor" stroke-opacity="0.4" stroke-width="1.2"/>
<path d="M 152 63 V 89" stroke="var(--red)" stroke-opacity="0.9" stroke-width="1.8"/>
<text x="158" y="58" font-size="7.5" fill-opacity="0.85">published and exploited</text>
<text x="158" y="100" font-size="7" fill-opacity="0.6">day 0</text>
<path d="M 393 63 V 89" stroke="var(--accent)" stroke-opacity="0.9" stroke-width="1.8"/>
<text x="399" y="58" font-size="7.5" fill-opacity="0.85">remediate by</text>
<text x="399" y="100" font-size="7" fill-opacity="0.6">day 14</text>
<text x="14" y="176" font-size="9">CVE-2023-4966</text>
<path d="M 152 172 H 668" stroke="currentColor" stroke-opacity="0.4" stroke-width="1.2"/>
<rect x="152" y="162" width="138" height="20" fill="var(--red)" fill-opacity="0.20" stroke="var(--red)" stroke-opacity="0.55" stroke-width="1"/>
<path d="M 152 159 V 185" stroke="currentColor" stroke-opacity="0.9" stroke-width="1.8"/>
<text x="158" y="154" font-size="7.5" fill-opacity="0.85">published</text>
<text x="158" y="196" font-size="7" fill-opacity="0.6">day 0</text>
<path d="M 290 159 V 185" stroke="var(--red)" stroke-opacity="0.9" stroke-width="1.8"/>
<text x="296" y="154" font-size="7.5" fill-opacity="0.85">exploited</text>
<text x="296" y="196" font-size="7" fill-opacity="0.6">day 8</text>
<path d="M 651 159 V 185" stroke="var(--accent)" stroke-opacity="0.9" stroke-width="1.8"/>
<text x="657" y="154" font-size="7.5" fill-opacity="0.85">remediate by</text>
<text x="657" y="196" font-size="7" fill-opacity="0.6">day 29</text>
<text x="152" y="238" text-anchor="middle" font-size="7.5" fill-opacity="0.55">0</text>
<text x="324" y="238" text-anchor="middle" font-size="7.5" fill-opacity="0.55">10</text>
<text x="496" y="238" text-anchor="middle" font-size="7.5" fill-opacity="0.55">20</text>
<text x="668" y="238" text-anchor="middle" font-size="7.5" fill-opacity="0.55">30</text>
<path d="M 152 228 H 668" stroke="currentColor" stroke-opacity="0.25" stroke-width="1"/>
<text x="14" y="238" font-size="7.5" fill-opacity="0.55">days elapsed</text>
<text x="14" y="264" font-size="10" fill-opacity="0.85">the shaded strip is the gap between the flaw becoming public and somebody using it</text>
<text x="14" y="284" font-size="9" fill-opacity="0.7">the top row has no strip, because both happened on the same date</text>
</g></svg>
<figcaption>The same two vulnerabilities on one thirty-day axis so the shapes can be compared. The shaded strip is the interval between the flaw becoming public and somebody being observed using it, and on the top row it has no width at all: publication and exploitation are the same date. The third mark on each row is the remediation date the catalogue assigns, which is the deadline for the organisations bound by it, and on both rows it falls well after the exploitation had begun. Drawing them to the same scale is the point, because the second row's eight-day gap looks generous in isolation and does not next to the first.</figcaption>
</figure>

## Your window is not the vendor's

The lifecycle has several clocks running and they measure different periods.

**The vendor's window** runs from being told to shipping a fix. That is the number
disclosure deadlines are about and it is the one the vendor controls.

**The research window** runs from the flaw being created to somebody finding it,
and it is frequently years. Nobody was protected during it, and nobody knew.

**The exploitation window** runs from working exploit code existing to a fix being
available. Whether that is negative, zero or positive depends entirely on who found
the flaw first.

**And your window** is the one that matters operationally. It runs from the flaw
existing in software you run to your systems being patched, and it ends
substantially after the patch ships, because a patch existing and a patch being
applied are separated by your change process.

That last gap is the one you control, and it is the reason a patch that has been
available for three months is a worse exposure than a zero day: the zero day had no
fix and this one did.

<details class="deeper">
<summary>If you run coordinated disclosure: the clock, why it exists, and what happens when it expires</summary>

Coordinated disclosure is a finder telling a vendor privately, with an agreed
period before the finding is published. The period varies and ninety days is a
common convention.

The clock exists because the alternative was demonstrated repeatedly. Without a
deadline, a report can sit unacknowledged indefinitely: the vendor has no
commercial incentive to prioritise a flaw nobody knows about, the finder has no
leverage, and users remain exposed to something two parties know about and they do
not. The deadline converts an open-ended request into a scheduled event.

What happens when it expires is the part people find uncomfortable, and it is
deliberate. The finder publishes, patch or no patch. That looks like harming users
to punish a vendor, and the argument for it is that the flaw was already known to
at least two parties and possibly more, that users could take mitigating action if
they knew, and that without the credible threat of publication the report is
ignored.

Extensions are normal where a vendor is engaging and the fix is genuinely hard,
which is the usual outcome. The deadline is a floor for the unresponsive case
rather than a target.

The other half worth knowing is the receiving side. An organisation without a
published route for reports receives them through whatever channel the finder can
reach: a support ticket that gets closed, a sales contact, a social media message,
or a journalist. Publishing a security contact and a stated response time costs
nothing and is the difference between hearing about your own flaw first and reading
about it.

The clock also has a variant worth being aware of: where a flaw is already being
exploited, disclosure is frequently immediate, because the users' interest in
knowing outweighs the vendor's interest in time. That is the case the first
timeline on this page describes.

</details>
<details class="predict">
<summary>Two flaws affect you: one with no patch and no observed exploitation, one patched three months ago and in the exploited catalogue. Predict which is the more urgent.</summary>

**The patched one, by a wide margin, and the intuition runs the other way.**

The unpatched one feels worse because there is nothing you can do about it, and the
feeling is about your own helplessness rather than about the exposure. Work through
what each actually costs.

The unpatched flaw has no fix and also no observed use. Nobody has been seen
turning it into an attack, which means either it is hard, or it is not worth the
effort, or nobody has bothered yet. You cannot patch it and you can segment around
it, disable the affected feature, and watch for attempts, and having done those the
residual is a flaw that nobody is currently using.

The patched one has a fix that has existed for three months and is not applied, and
it is being used against real targets right now. There is no cleverness required
from an attacker and no uncertainty about whether anybody will try, because they
are trying. The only thing between you and it is a change you have been able to
make since May.

The awkward part is that the second case is the one organisations are worst at,
because it is not news. It arrived through the ordinary patch queue, it has no
advisory attracting attention, and it competes for a change window with everything
else. The first case gets a meeting.

The ordering from block E holds: anything in the exploited catalogue first, then
high exploitation probability on reachable assets, then everything else by
severity. A patched-and-exploited flaw is at the top of that list and a novel
unpatched one with no observed use is not.

</details>


## What you can actually do

The honest answer to a vulnerability with no patch is that you cannot fix it, and
the useful answer is that fixing is one of five responses from block E rather than
the only one.

**Reduce what can reach it.** Segmentation is the strongest of the alternatives
because it does not depend on recognising an attempt. A flaw reachable from
anywhere becomes a flaw reachable from three places you control, and that is a
change you can make today.

**Disable the affected feature.** Many advisories name a specific function,
protocol or module, and turning it off removes the exposure entirely at whatever
functional cost that carries. This is the most complete answer available before a
patch and it is skipped because the cost is visible and immediate.

**Deploy a detection for the attempt.** Weaker, because it depends on recognising
the pattern and the pattern can change, and worth having because it is cheap and
because it tells you whether anybody is trying.

**Watch the exploited catalogue.** A flaw with no patch that has not been observed
in use is a different priority from one that has, and the catalogue is the thing
that distinguishes them.

**And accept the rest with a record.** Which is the exception machinery from block
E, with a trigger written in: revisit immediately if this appears in the catalogue.

**Defence in depth is what this topic is actually about.** Every layer that assumes
the one above it will eventually fail is a layer that works against a vulnerability
nobody has discovered yet, because it does not need to know which one. That is a
less satisfying answer than a patch and it is the only one available before one
exists.
<details class="deeper">
<summary>If you brief on an unpatched advisory: what to say, and the three questions that decide the response</summary>

An advisory with no patch produces an urgent meeting where the natural question is
how bad it is, which is not answerable and not the useful question. Three others
are, and asking them in order usually resolves the situation in twenty minutes.

**Do we run it, and where.** Sounds trivial and is frequently the hardest part,
because the answer requires the inventory and the dependency resolution from the
previous topic. A surprising number of these meetings end here, either with relief
or with the discovery that nobody can say.

**Is the affected function one we use.** Advisories usually name a specific
component, protocol or feature. If you do not use it, disabling it removes the
exposure at zero functional cost, and this resolves more advisories than people
expect.

**What can reach it today.** Not in the architecture diagram: actually, from the
current firewall rules. If the answer is the internet, the response is urgent. If
it is three internal subnets, it is a scheduled change. That single question moves
most advisories from one category to the other.

What to say, having asked them, is short and specific: what we run, what we have
done, what remains exposed, and the trigger for revisiting. The trigger is the part
that closes the meeting, because without it the item stays open and gets discussed
again next week with no new information.

The trigger worth using is the exploited catalogue, since it is externally
maintained, it is short, and its appearance genuinely changes the situation. An
acceptance that says "revisit immediately if this is added" is monitoring the thing
most likely to invalidate the decision, and it does not require anybody to remember.

</details>


## Prove it

**Run it.** Query the NVD and the exploited catalogue for any CVE you have dealt
with and compare the publication date with the date it was added. The interval is
usually shorter than people expect.

**Work it out.** Take your own organisation's patch window for a critical
vulnerability. Compare it with the eight-day gap in the second timeline, and decide
what the difference means for a flaw of that kind.

**Look it up.** Open SP 800-216 and find what it says about disclosure timelines
and about what a receiving organisation should provide. The second half is the part
most organisations have not done.

## What trips people up

### 1. Reading zero day as a severity

It is a claim about the vendor's knowledge. A zero day can be trivial, and a flaw
patched three years ago can be catastrophic on a system that never applied it.

### 2. Calling something a zero day after it is known

Once the vendor knows, the term no longer applies. A flaw public for six months
with no patch is an unpatched known vulnerability, which is usually worse.

### 3. Measuring exposure from publication

That is the vendor's window. Yours starts when the flaw existed in software you run
and ends when your systems are patched, which is after the patch ships.

### 4. Assuming a comfortable gap after disclosure

One of the two timelines here has publication and observed exploitation on the same
date, and the other has eight days.

### 5. Doing nothing because there is no patch

Segmentation, disabling the affected feature, and a detection for the attempt are
all available before a fix, and the first two do not depend on recognising an
attempt.

### 6. Treating a disclosure deadline as hostile

Without one, a report can sit indefinitely while the flaw is known to at least two
parties. Extensions are normal where a vendor is engaging; the deadline is a floor
for the unresponsive case.

## Work it through

An advisory lands on a Friday afternoon for a product you run at the edge. There is
no patch, the vendor says one is coming, and proof-of-concept code is already
public.

**The tempting move is to wait for the patch.** It is coming, applying it will be
straightforward, and the weekend is not a good time for a change. That is a
decision to be exposed for an unknown number of days with public exploit code
available, taken by default rather than deliberately.

**The move that works reads the advisory for a feature name.** Most of them name
one, and if the affected function is one you do not use, disabling it removes the
exposure completely and costs nothing. That check takes ten minutes and resolves a
useful proportion of these.

**If the feature is needed, reduce the audience.** Restrict which sources can reach
the service to the set that genuinely needs it. That is a firewall change, it is
reversible, and it converts an internet-facing exposure into one requiring a
position you can enumerate.

**Then the acceptance is small enough to sign.** Named residual, named owner, and a
trigger: revisit immediately if this appears in the exploited catalogue, which is
the signal that the situation has changed.

**What this rejects is the framing that the only action is patching.** The patch is
the best answer and it is not available, and the interval between now and it is
where the decision lives.

The residual worth stating: proof-of-concept code being public means the difficulty
has already been removed for anybody who wants it, so the segmentation is doing the
work and it holds only against attackers outside the permitted set. If one of the
permitted sources is itself reachable from the internet, the mitigation is thinner
than it looks, and that is worth checking rather than assuming.

## Try it

**Look up a timeline.** Pick a CVE that affected you and query both services. The
gap between publication and the catalogue is the number worth knowing.

**Find a feature you could disable.** Take one advisory from the last year and see
whether it names a specific function. Then check whether you use it.

**Read your own patch clock.** Find how long a critical patch actually takes from
release to being applied in your estate, measured rather than in policy.

**Find your disclosure contact.** Check whether your organisation publishes a
security contact. If not, that is where somebody's report about you would fail to
arrive.

## Check yourself

<details class="qa">
<summary>What does zero day claim, and what does it not?</summary>

That the party who could issue a fix does not know the flaw exists, so they have
had zero days to work on it. It is a statement about knowledge.

It is not a severity: a zero day can be trivial. It also stops applying the moment
the vendor is told, so a flaw that has been public for six months without a patch
is an unpatched known vulnerability rather than a zero day, and that is usually a
worse position because a fix was possible and did not happen.

</details>

<details class="qa">
<summary>Two real vulnerabilities show gaps of zero days and eight days between publication and observed exploitation. What follows?</summary>

That any planning treating publication as the start of a comfortable window is
using a threat model that does not apply. On the first, exploitation was already
being observed when the flaw became public, so there was never a period when
defenders knew and attackers did not.

The remediation dates in both records fall well after the exploitation began, which
means even meeting the required deadline leaves a period of known exposure.

</details>

<details class="qa">
<summary>Why is your exposure window different from the vendor's?</summary>

Because they measure different intervals. The vendor's runs from being told to
shipping a fix, which is what disclosure deadlines are about. Yours runs from the
flaw existing in software you run to your systems being patched.

Yours ends after the patch ships, by however long your change process takes, which
is why a patch available for three months can be a worse exposure than a zero day:
that one had no fix and this one did.

</details>

<details class="qa">
<summary>What can you do about a vulnerability with no patch?</summary>

Reduce what can reach it, which does not depend on recognising an attempt and is
the strongest option. Disable the affected feature if the advisory names one and
you do not need it, which removes the exposure entirely. Deploy a detection for the
attempt, which is weaker and cheap. Watch the exploited catalogue, which
distinguishes theoretical from active. And accept the remainder with a named
residual and a trigger.

Underneath all of them is defence in depth, which works against flaws nobody has
found yet precisely because it does not depend on knowing which one.

</details>

<details class="qa">
<summary>Why does a disclosure deadline exist, and what happens when it expires?</summary>

Because without one a report can sit indefinitely. The vendor has no commercial
pressure from a flaw nobody knows about, the finder has no leverage, and users
remain exposed to something at least two parties know and they do not.

On expiry the finder publishes, patch or not. That is deliberate: users can act if
they know, and without a credible threat of publication the report is ignored.
Extensions are normal where the vendor is engaging, so the deadline functions as a
floor for the unresponsive case.

</details>

## References

- [SP 800-216](https://csrc.nist.gov/pubs/sp/800/216/final) - NIST, vulnerability disclosure guidelines, for the timeline and what a receiving organisation should provide. Free. Accessed 2026-08-26.
- [Known Exploited Vulnerabilities catalogue](https://www.cisa.gov/known-exploited-vulnerabilities-catalog) - CISA, the source of the exploitation dates and remediation deadlines in the capture. Free. Accessed 2026-08-26.
- [NVD API](https://nvd.nist.gov/developers/vulnerabilities) - NIST, the endpoint the capture queries for publication dates. Free. Accessed 2026-08-26.
- [SP 800-40 Rev. 4](https://csrc.nist.gov/pubs/sp/800/40/r4/final) - NIST, patch management planning, for the gap between a patch existing and being applied. Free. Accessed 2026-08-26.

**Where the content came from.** The timelines are assembled at capture time from
two public services on an AlmaLinux 10.2 container, and every date on this page and
in the figure comes from those records rather than from a narrative. The two
vulnerabilities were chosen because both are in the exploited catalogue with
different intervals, which is what makes the comparison worth drawing. Nothing on
this page exploits or demonstrates anything: the evidence is the published dates.
There is no platform comparison here, because a disclosure timeline is a property
of a vulnerability rather than of an operating system.

**If you also work on networks.** The Network+ track's
[lifecycle, change and configuration management](/learn/network-plus/lifecycle-change-and-configuration-management)
covers the change process that sits between a patch existing and being applied,
which is the half of the exposure window you control.
