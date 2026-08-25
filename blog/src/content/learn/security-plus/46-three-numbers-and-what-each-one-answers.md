---
title: "Three numbers, and what each one answers"
description: "What a CVSS base score measures and what it deliberately leaves out, why an exploitation probability and a severity score disagree by two orders of magnitude, what the known exploited catalogue observes rather than predicts, and why prioritisation is the actual job."
deck: "The scanner says 9.9. Nobody has ever used it. Both of those are true"
track: "security-plus"
level: "working"
order: 470
objectives:
  - "Say what a CVSS base score measures and what it excludes by design"
  - "Read a CVSS vector string field by field"
  - "Explain what EPSS estimates and over what period"
  - "Say what the KEV catalogue records and why it is an observation"
  - "Use all three to order a remediation queue and defend the order"
  - "Explain why environmental metrics exist and why almost nobody sets them"
prerequisites: ["finding-vulnerabilities"]
tags: ["security-plus", "security", "operations", "vulnerability-management"]
updated: 2026-08-25
draft: false
examObjectives:
  - exam: "sy0-701"
    domain: "4.0"
    objective: "4.3"
sources:
  - title: "CVSS v3.1 Specification Document"
    url: "https://www.first.org/cvss/v3.1/specification-document"
    publisher: "FIRST"
    accessed: 2026-08-25
    tier: 1
  - title: "Exploit Prediction Scoring System"
    url: "https://www.first.org/epss/"
    publisher: "FIRST"
    accessed: 2026-08-25
    tier: 1
  - title: "Known Exploited Vulnerabilities Catalog"
    url: "https://www.cisa.gov/known-exploited-vulnerabilities-catalog"
    publisher: "CISA"
    accessed: 2026-08-25
    tier: 1
  - title: "NVD API documentation"
    url: "https://nvd.nist.gov/developers/vulnerabilities"
    publisher: "NIST"
    accessed: 2026-08-25
    tier: 1
  - title: "Stakeholder-Specific Vulnerability Categorization (SSVC)"
    url: "https://www.cisa.gov/stakeholder-specific-vulnerability-categorization-ssvc"
    publisher: "CISA"
    accessed: 2026-08-25
    tier: 1
symptoms:
  - symptom: "Two vulnerabilities with the same severity get the same priority"
    anchor: "two-vulnerabilities-that-look-identical"
  - symptom: "A remediation queue sorted by severity never gets shorter"
    anchor: "prioritisation-is-the-actual-job"
---

> **Before you read.** A scanner reports a vulnerability with a base score of 9.9,
> which is as bad as its scale goes short of ten. The vendor's advisory notes that
> no exploitation has been observed since it was published two years ago.
>
> **Which of those two statements should decide when you patch it?**

Neither on its own, and the reason is that they are answers to different
questions. The exam names three numbers for this objective and the useful skill is
knowing which question each one answers, because a queue sorted by the wrong one
never gets shorter.

### Some words you will need

<dl class="terms">
<dt>CVE</dt>
<dd>An identifier for one vulnerability. Not a score, not a severity, just a name everybody agrees on.</dd>
<dt>CVSS</dt>
<dd>Common Vulnerability Scoring System. A severity score from characteristics of the flaw itself.</dd>
<dt>base score</dt>
<dd>The part of CVSS that does not change with your environment or with time. What almost everybody quotes.</dd>
<dt>vector string</dt>
<dd>The base score's inputs written out, so the score can be recomputed and argued with.</dd>
<dt>environmental metrics</dt>
<dd>CVSS fields you set for your own deployment. Almost never set.</dd>
<dt>EPSS</dt>
<dd>Exploit Prediction Scoring System. A probability that the flaw will be exploited in the next 30 days.</dd>
<dt>percentile</dt>
<dd>Where that probability sits relative to every other scored vulnerability.</dd>
<dt>KEV</dt>
<dd>Known Exploited Vulnerabilities. A catalogue of flaws observed being used, with the date each was added.</dd>
<dt>exposure factor</dt>
<dd>How much of an asset's value a given event would destroy. From the risk arithmetic rather than from any of the above.</dd>
</dl>

## What breaks without this

**Everything critical is equally urgent.** A queue with four hundred items marked
critical is a queue with no order in it, and the order gets supplied by whoever
shouts.

**The flaw that is being used right now waits behind one that never will be.** The
severity score does not know the difference, and it is the field most queues are
sorted on.

**A percentage is quoted as a probability of something it does not describe.** A
number meaning "more likely than 97 percent of other vulnerabilities" gets read as
"97 percent likely", and those are not close.

**A patch window is negotiated on a number nobody can explain.** Somebody asks why
this one is a 9.9 and the answer is that the scanner said so.

## Two vulnerabilities that look identical

Here are three public services asked about two CVEs.

<details class="predict">
<summary>Both of these score 9.9 or 10.0 on severity. Predict how far apart their exploitation probabilities are.</summary>

```bash
# AlmaLinux 10.2, x86_64
$ three-numbers CVE-2021-44228; echo; three-numbers CVE-2024-36393
CVE-2021-44228
  CVSS   10.0 CRITICAL   CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:C/C:H/I:H/A:H
  EPSS   99.999% chance in the next 30 days, 100th percentile
  KEV    listed 2021-12-10, ransomware use: Known

CVE-2024-36393
  CVSS   9.9 CRITICAL   CVSS:3.1/AV:N/AC:L/PR:L/UI:N/S:C/C:H/I:H/A:H
  EPSS   0.419% chance in the next 30 days, 34.7th percentile
  KEV    not listed
```

**A factor of about 239.** One is essentially certain to be attacked this month.
The other has a roughly one in two hundred and forty chance, and sits below the
median of all scored vulnerabilities.

Look at the two vector strings while they are next to each other. They differ in
exactly one field: `PR:N` against `PR:L`, meaning one needs no privileges and the
other needs low ones. That single difference is the whole of the 0.1 between them.

So the severity score is doing its job correctly and its job is not the one people
use it for. It describes the flaw. It has no information about whether anybody is
interested, whether exploit code exists, whether the affected product is common,
or whether the thing has been used against anybody. Those are the other two
columns.

A remediation queue sorted by severity puts these two side by side, and any
organisation running both products should treat them completely differently.

</details>

<figure class="learn-figure">
<svg viewBox="0 0 720 296" role="img" aria-labelledby="num-title" style="width:100%;height:auto;">
<title id="num-title">Two vulnerabilities with almost identical CVSS scores, shown against their exploitation probability and their presence in the known exploited catalogue, which differ enormously</title>
<g fill="currentColor">
<text x="14" y="20" font-size="11">two vulnerabilities, near-identical severity, and everything else different</text>
<text x="225" y="46" text-anchor="middle" font-size="9.5">CVSS 3.1</text>
<text x="225" y="62" text-anchor="middle" font-size="8" fill-opacity="0.7">how bad would it be</text>
<text x="225" y="74" text-anchor="middle" font-size="8" fill-opacity="0.7">if somebody used it</text>
<text x="415" y="46" text-anchor="middle" font-size="9.5">EPSS</text>
<text x="415" y="62" text-anchor="middle" font-size="8" fill-opacity="0.7">how likely is anybody</text>
<text x="415" y="74" text-anchor="middle" font-size="8" fill-opacity="0.7">to use it, this month</text>
<text x="610" y="46" text-anchor="middle" font-size="9.5">CISA KEV</text>
<text x="610" y="62" text-anchor="middle" font-size="8" fill-opacity="0.7">has anybody actually</text>
<text x="610" y="74" text-anchor="middle" font-size="8" fill-opacity="0.7">used it, and when</text>
<text x="14" y="112" font-size="9">CVE-2021-44228</text>
<rect x="140" y="92" width="170" height="32" rx="4" fill="currentColor" fill-opacity="0.05" stroke="currentColor" stroke-opacity="0.5" stroke-width="1.1"/>
<text x="225" y="112" text-anchor="middle" font-size="8.5">10.0 CRITICAL</text>
<rect x="330" y="92" width="170" height="32" rx="4" fill="var(--red)" fill-opacity="0.16" stroke="var(--red)" stroke-opacity="0.75" stroke-width="1.6"/>
<text x="415" y="112" text-anchor="middle" font-size="8.5">99.999%, 100th pct</text>
<rect x="520" y="92" width="180" height="32" rx="4" fill="var(--red)" fill-opacity="0.16" stroke="var(--red)" stroke-opacity="0.75" stroke-width="1.6"/>
<text x="610" y="112" text-anchor="middle" font-size="8.5">listed 2021-12-10</text>
<text x="14" y="160" font-size="9">CVE-2024-36393</text>
<rect x="140" y="140" width="170" height="32" rx="4" fill="currentColor" fill-opacity="0.05" stroke="currentColor" stroke-opacity="0.5" stroke-width="1.1"/>
<text x="225" y="160" text-anchor="middle" font-size="8.5">9.9 CRITICAL</text>
<rect x="330" y="140" width="170" height="32" rx="4" fill="var(--accent)" fill-opacity="0.12" stroke="var(--accent)" stroke-opacity="0.7" stroke-width="1.4"/>
<text x="415" y="160" text-anchor="middle" font-size="8.5">0.419%, 34.7th pct</text>
<rect x="520" y="140" width="180" height="32" rx="4" fill="var(--accent)" fill-opacity="0.12" stroke="var(--accent)" stroke-opacity="0.7" stroke-width="1.4"/>
<text x="610" y="160" text-anchor="middle" font-size="8.5">not listed</text>
<text x="14" y="204" font-size="10" fill-opacity="0.85">the first column says these two are the same problem. they are not</text>
<text x="14" y="226" font-size="10" fill-opacity="0.85">one is 239 times more likely to be used in the next month, and has been used already</text>
<text x="14" y="256" font-size="10" fill="var(--red)" fill-opacity="0.9">a queue sorted by the first column puts them next to each other</text>
<text x="14" y="278" font-size="10" fill-opacity="0.85">which is why the severity score is an input to prioritisation rather than the answer</text>
</g></svg>
<figcaption>Two vulnerabilities whose severity scores are a tenth of a point apart, and whose other two numbers are not close. The middle column is a probability of exploitation within thirty days, which for the first one is effectively certainty and for the second is below the median of everything scored. The right column is not a prediction at all: it records that somebody observed the first being used, on a stated date, and says nothing about the second beyond the fact that nobody has reported it. A queue sorted by the left column alone treats these as the same job, which is the failure mode the other two columns exist to correct.</figcaption>
</figure>

<details class="deeper">
<summary>If you have to defend a score: reading the vector string field by field</summary>

The vector is the argument and the score is the conclusion, which is why quoting
the score alone leaves you unable to answer a challenge.

Take the first one: `CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:C/C:H/I:H/A:H`.

**AV:N** is attack vector, network. Reachable from anywhere routable, as opposed
to adjacent, local, or physical. This is usually the field with the largest effect
and the one your architecture most often changes.

**AC:L** is attack complexity, low. No special conditions, no race, no
prerequisite knowledge of the target's configuration.

**PR:N** is privileges required, none. The attacker does not need an account. The
second CVE has `PR:L`, meaning they need a low-privileged one, and that is the
only difference between the two vectors on this page.

**UI:N** is user interaction, none. Nobody has to click anything.

**S:C** is scope, changed. The flaw lets the attacker affect resources beyond the
vulnerable component's own security authority. This field is subtle, frequently
argued about, and has a large effect on the score.

**C:H/I:H/A:H** are the three impact metrics, all high: confidentiality, integrity
and availability, each fully lost.

Read that way, a base score becomes something you can disagree with specifically.
"AV:N is wrong for us because this component is not reachable from the network" is
a defensible statement that changes the number. "It is only a 7 for us" without
naming a field is not.

The habit worth building: when somebody quotes a score, ask for the vector. When
somebody disputes a score, ask which field.

</details>

## What the record does not contain

CVSS has three metric groups. Base, temporal, and environmental. Ask a real record
which of them are populated.

```bash
# AlmaLinux 10.2, x86_64
$ curl -s "https://services.nvd.nist.gov/rest/json/cves/2.0?cveId=CVE-2021-44228" | jq -r ".vulnerabilities[0].cve.metrics | keys[]"; echo; echo "the fourth answer, published by CISA rather than by NIST:"; curl -s "https://services.nvd.nist.gov/rest/json/cves/2.0?cveId=CVE-2021-44228" | jq -r ".vulnerabilities[0].cve.metrics.ssvcV203[0].ssvcData | \"  role: \" + .role, (.options[] | to_entries[] | \"  \" + .key + \": \" + .value)"
cvssMetricV2
cvssMetricV31
ssvcV203

the fourth answer, published by CISA rather than by NIST:
  role: CISA Coordinator
  exploitation: active
  automatable: yes
  technicalImpact: total
```

**Base scores, and nothing else.** Two versions of CVSS, both base, plus something
that is not CVSS at all.

**Environmental metrics are the ones missing, and they are the ones designed for
you.** The specification provides fields to say that this asset matters more or
less than average to your organisation, that confidentiality is what you care
about and availability is not, or that a mitigating control changes one of the
base fields. Setting them produces a score for your deployment rather than for the
world.

Almost nobody sets them. The reason is arithmetic rather than laziness: doing it
properly means a per-asset judgement for every vulnerability on every system, which
is more work than the prioritisation it feeds. So the field exists, the tooling
supports it, and the number everybody quotes remains the one computed for a
generic organisation that does not exist.

The `ssvcV203` entry is worth noticing because it is a different answer to the
same problem. Rather than a number, it records three decisions: exploitation is
active, the attack is automatable, and the technical impact is total. Those feed a
decision tree that outputs an action rather than a score, and the reason CISA
publishes it is precisely that a score does not tell anybody what to do.

<details class="deeper">
<summary>If you report on EPSS: what a percentile is, and the mistake that makes the number useless</summary>

EPSS gives two numbers and they are constantly confused.

The **probability** is an estimate that the vulnerability will be exploited in the
wild during the next thirty days. It is a probability in the ordinary sense, so
0.419 percent means roughly one chance in two hundred and forty.

The **percentile** says where that probability sits among every scored
vulnerability. The 34.7th percentile means about 35 percent of scored
vulnerabilities have a lower probability, so this one is below the median.

The mistake is quoting the percentile as if it were the probability. A
vulnerability at the 97th percentile is not 97 percent likely to be exploited. It
may be around two or three percent likely, and still be in the top three percent
of everything, because the distribution is extremely skewed: the great majority of
vulnerabilities have probabilities well under one percent.

That skew is the useful property. It is what lets a threshold do real work: a rule
like "anything above the 95th percentile gets treated as urgent" selects a small
number of items, and those items are where nearly all the observed exploitation
happens.

Three further things to carry. The score is recomputed daily, so it is a
perishable number and a report that quotes it without a date is quoting a
measurement of an unknown day. It is a prediction about the world rather than
about you, so it knows nothing about whether you run the affected product. And it
covers a thirty-day horizon, which means a low score is not a statement that
something is safe, only that this month is probably quiet.

</details>

## What the catalogue observes

The third number is not a number and not a prediction.

The Known Exploited Vulnerabilities catalogue is a list of vulnerabilities that
have been observed being used against real targets, each with the date it was
added and a required remediation date for the agencies bound by it. The entry for
the first CVE above also carries a flag saying it has been used in ransomware
campaigns.

**Reading it as a prediction is the common mistake and it inverts the meaning.**
Absence from the catalogue does not mean a vulnerability will not be exploited. It
means nobody has reported observing it, which for something published last week is
the expected state regardless of how dangerous it is.

So the catalogue is close to a floor rather than a ranking. Anything on it is
being used, has been used, and needs treating as such. Anything not on it needs
one of the other two numbers to say anything at all.

Its second use is the one that ends arguments. A vulnerability on this list is not
theoretical, which removes the most common objection to an emergency patch window:
that nobody has ever actually done this.

<details class="predict">
<summary>A vulnerability sits at the 97th EPSS percentile. Roughly what is the chance it gets exploited in the next thirty days?</summary>

**Low. Probably a few percent, and certainly not ninety-seven.**

This is the single most common misreading of the number and it goes in the
dangerous direction, because it makes a genuinely urgent item sound like a
certainty and then makes the next one sound like nothing.

The percentile is a rank. It says roughly 97 percent of scored vulnerabilities are
less likely to be exploited than this one. The underlying probability is a separate
field, and because the distribution is heavily skewed, the great majority of
vulnerabilities sit well below one percent. A few percent is genuinely near the top
of that distribution.

The skew is what makes the percentile useful rather than a defect in it. A rule
like "treat anything above the 95th percentile as urgent" picks a small, workable
number of items, and those items are where nearly all observed exploitation
happens. A rule phrased on the raw probability would need a threshold most people
cannot pick sensibly, because they have no intuition for what 0.4 percent means
against 4 percent.

The reporting discipline that follows: quote both numbers, or quote the percentile
and say the word percentile out loud. A report carrying "97%" with no further
qualification will be read as a probability by everybody who did not write it.

</details>

## Prioritisation is the actual job

Everything above exists to answer one question, which is what to fix first.

**Severity alone produces a queue that does not move.** Sort four hundred findings
by base score, and the top of the list is a large block of nines that stays a
large block of nines, because new nines arrive at the rate old ones are cleared.

**Exploitation probability alone ignores what the thing would cost you.** A flaw
with a high chance of being used against a test system nobody can reach from
anywhere is not the first job.

**The catalogue alone is too short.** It covers what has been observed, which is a
small fraction of what exists.

The combination people actually use, in roughly this order: anything in the
catalogue, then anything with a high exploitation probability on an asset that
matters, then everything else by severity. That third bucket is where a base score
earns its place, as a tiebreak among things nobody is currently attacking.

Two words from the objective belong here and they come from the risk side rather
than the scoring side. **Exposure factor** is how much of an asset's value a given
event destroys, and **risk tolerance** is how much of that the organisation has
already agreed to live with. Neither is in any of the three numbers, and both
belong in the decision, which is why a prioritisation policy is an organisational
document rather than a scanner setting.

**False positives and false negatives complete the picture.** A false positive
costs the time somebody spends proving software is patched, which the previous
topic showed can be most of a queue. A false negative costs nothing until it
costs everything, and it is invisible by definition. Any threshold that reduces
one raises the other, which is the same trade the sensor pairing made in the
physical security topic, met again in a report.

<details class="deeper">
<summary>If you set patch deadlines: why a policy keyed on severity ages badly, and what to key it on instead</summary>

Most patching policies are written as a table: critical in seven days, high in
thirty, medium in ninety. It is easy to write, easy to audit, and it degrades in a
specific way worth understanding before you inherit one.

The degradation comes from where critical findings come from. Scanners get better,
scoring gets more generous over time, and the proportion of findings scored nine or
above rises without the estate getting worse. A policy keyed on that band therefore
demands more emergency work every year in response to a measurement change, and
the team responds the only way it can, by not meeting the deadline. Once a deadline
is routinely missed, it stops functioning as a deadline for anything, including
the cases that mattered.

The version that ages better keys the shortest deadline on observation rather than
on severity. Anything in the known exploited catalogue gets the emergency window,
because that list is short, externally maintained, and does not inflate with
scoring changes. Anything above a high exploitation percentile gets the next tier.
Severity then sets the routine tier, where a missed date is a scheduling problem
rather than a crisis.

Two practical details. Write the thresholds as review points rather than
constants, with a named owner and an annual date, because the right percentile
cut-off depends on how many items your team can actually take. And measure the
policy by the age of the oldest outstanding item in each tier rather than by the
count, because a count can be improved by rescoping and an age cannot.

The uncomfortable part, worth saying to whoever owns the policy: a deadline the
organisation has never met is not a control, it is a statement of preference, and
an auditor who reads the exception log will work that out faster than you expect.

</details>

## Prove it

**Run it.** With `curl` and `jq`, ask the three services about any CVE you have
been arguing about. The NVD endpoint takes a `cveId` parameter, the EPSS one takes
`cve`, and CISA publishes the catalogue as a single JSON file.

**Work it out.** Take a vulnerability from your own estate with a base score above
nine. Look up its EPSS probability and its percentile, and check the catalogue.
Then say whether your current patch window for it is defensible, and on which of
the three numbers.

**Look it up.** Open the CVSS v3.1 specification and find the environmental metric
group. Read what each field lets you assert, then decide honestly whether your
organisation could populate them for one system, and how long it would take.

## What trips people up

### 1. Reading a percentile as a probability

The 97th percentile means 97 percent of scored vulnerabilities are less likely to
be exploited, not that this one is 97 percent likely. The distribution is heavily
skewed and most probabilities are well under one percent.

### 2. Sorting the queue by severity

The two CVEs above are 0.1 apart on severity and a factor of 239 apart on
exploitation probability. A severity sort puts them next to each other.

### 3. Treating absence from the catalogue as safety

It records observation, not prediction. Something published last week is absent
because nobody has reported seeing it used, which is the normal state and not
reassurance.

### 4. Quoting a score without the vector

The vector is the argument. Without it, a disagreement cannot be resolved, because
nobody can say which field they think is wrong.

### 5. Expecting the environmental metrics to be filled in

They are not, anywhere in the published record. The score you get is computed for
a generic organisation, and adjusting it for yours is work nobody has costed.

### 6. Quoting an EPSS number without a date

It is recomputed daily. A probability without the date it was computed is a
measurement of an unknown day.

## Work it through

Four hundred findings, all marked high or critical, and a change window that can
take twenty a month. The security team wants everything patched and the platform
team wants a defensible order.

**The tempting move is to sort by severity and start at the top.** It is simple,
it is what the tool does by default, and it will keep the team busy for eighteen
months while producing no discernible change in the number, because the queue
refills from the top at roughly the rate it is cleared.

**The move that works splits the queue by question rather than by score.** Pull
out everything in the known exploited catalogue first: that list is short, it is
not theoretical, and it is the easiest emergency window to justify. Then pull out
everything above a high exploitation percentile that sits on an asset that is
reachable and matters. What remains is genuinely the long tail, and it can be
ordered by severity because at that point severity is doing the job it is good
at.

**Then the number that gets reported changes.** Rather than four hundred, the
report says how many catalogue items are outstanding and for how long, which is a
number that can reach zero and stay there, and which somebody outside the team can
understand.

**What this rejects is completeness as the goal.** The queue will not reach zero,
and a programme built on the belief that it should is a programme that will be
judged as failing forever. Twenty a month against four hundred is a statement
about capacity, and the honest response is to choose which twenty rather than to
pretend the arithmetic is different.

The residual is explicit and it should be written down: everything below the
threshold is accepted for now, by name, with a review date. That is the risk
acceptance from the earlier topic, applied at scale, and doing it as a policy once
is far better than doing it four hundred times by not getting round to things.

## Check yourself

<details class="qa">
<summary>What does a CVSS base score measure, and what does it deliberately exclude?</summary>

It measures the intrinsic characteristics of the flaw: how it is reached, how hard
it is, what privileges and interaction it needs, whether its effect crosses a
security boundary, and how much confidentiality, integrity and availability it
costs.

It excludes anything about you and anything about time. Whether the affected
product is deployed in your estate, whether exploit code exists, whether anybody
is using it, and how much the affected asset matters are all outside the base
group by design. Two of those are what the other two numbers supply.

</details>

<details class="qa">
<summary>Two vulnerabilities score 10.0 and 9.9. One has an EPSS of 99.999 percent and one 0.419 percent. What explains the gap?</summary>

Nothing in the severity score, because severity does not measure interest.

EPSS estimates the probability of exploitation in the next thirty days from
evidence about the world: whether exploit code is public, how widely the product
is deployed, what activity has been observed. The first CVE is one of the most
exploited in history and the second is a critical flaw in something few people
attack.

The two vectors differ in exactly one field, `PR:N` against `PR:L`, which is the
whole of the 0.1 between them.

</details>

<details class="qa">
<summary>A vulnerability is not in the KEV catalogue. What have you learned?</summary>

That nobody has reported observing it being used. The catalogue records
observation, so absence is the default state for anything recent and is not a
statement about danger.

Its presence is the strong signal. Something on the list is being used against
real targets, which removes the usual objection to an emergency patch window.

</details>

<details class="qa">
<summary>Why does the published CVSS record contain no environmental metrics?</summary>

Because they are meant to be set by the organisation using the software, not by
the party publishing the vulnerability. They let you assert that an asset matters
more or less than average, that one impact type matters and another does not, or
that a control changes a base field.

Almost nobody sets them, and the reason is cost: doing it properly means a
per-asset judgement for every vulnerability on every system, which exceeds the
value of the prioritisation it feeds.

</details>

<details class="qa">
<summary>Give an order for a remediation queue and defend it.</summary>

Anything in the known exploited catalogue first, because it is short, observed and
easy to justify. Then anything with a high exploitation percentile sitting on an
asset that is reachable and matters. Then the remainder, ordered by base score.

The defence is that each stage uses the number that answers the question at that
stage: has it been used, is it likely to be, and how bad would it be. Severity
comes last because it is the only one of the three that says nothing about
whether anybody is interested.

</details>

## References

- [CVSS v3.1 specification](https://www.first.org/cvss/v3.1/specification-document) - FIRST, for every field in the vector string and for the environmental metric group. Free. Accessed 2026-08-25.
- [EPSS](https://www.first.org/epss/) - FIRST, for what the probability estimates, over what period, and how the percentile relates to it. The [FAQ](https://www.first.org/epss/faq) is where the percentile is spelled out. Free. Accessed 2026-08-25.
- [Known Exploited Vulnerabilities catalogue](https://www.cisa.gov/known-exploited-vulnerabilities-catalog) - CISA, the catalogue itself and its inclusion criteria. Free. Accessed 2026-08-25.
- [NVD API](https://nvd.nist.gov/developers/vulnerabilities) - NIST, the endpoint the captures on this page query. Free. Accessed 2026-08-25.
- [SSVC](https://www.cisa.gov/stakeholder-specific-vulnerability-categorization-ssvc) - CISA, the decision tree that appears in the NVD record alongside the scores. Free. Accessed 2026-08-25.

**Where the content came from.** Every number on this page was fetched from NVD,
FIRST and CISA at the moment of capture, on an AlmaLinux 10.2 container, and the
EPSS figures are dated because they are recomputed daily. The two CVEs were
chosen by querying NVD for critical vulnerabilities published in one three-week
window and sorting the results by exploitation probability, so the pairing is a
real property of the data rather than two examples picked to make a point. There
is no comparison of platforms on this page, because nothing here runs against a
machine: all three services answer the same way from anywhere.

**If you also work on networks.** The Network+ track's
[compliance and audits](/learn/network-plus/compliance-and-audits) covers the
reporting side of the same programme, where these numbers end up as a figure
somebody has to explain.
