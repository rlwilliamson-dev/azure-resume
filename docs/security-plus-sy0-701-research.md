# CompTIA Security+ SY0-701: what is actually on the exam

What the current Security+ exam is, taken from CompTIA's released objectives
document and certification page rather than from anybody's summary of them.
Companion to [security-plus-teaching-design.md](security-plus-teaching-design.md),
which covers how the material gets presented, and
[security-plus-topic-plan.md](security-plus-topic-plan.md), which covers what
gets written.

Research date: 2026-08-21. Every URL in [Sources](#sources) was checked for a
200 response on that date, with the one exception noted there.

- [Why this document exists](#why-this-document-exists)
- [The exam, confirmed](#the-exam-confirmed)
- [Is SY0-701 still the current exam](#is-sy0-701-still-the-current-exam)
- [Domains and weights](#domains-and-weights)
- [The twenty-eight objectives](#the-twenty-eight-objectives)
- [The verb profile, and why it decides the shape of the track](#the-verb-profile-and-why-it-decides-the-shape-of-the-track)
- [The vocabulary load](#the-vocabulary-load)
- [The acronym list](#the-acronym-list)
- [What the primary document says that summaries do not](#what-the-primary-document-says-that-summaries-do-not)
- [The hardware and software list](#the-hardware-and-software-list)
- [Measuring the default free resource](#measuring-the-default-free-resource)
- [Where output can come from](#where-output-can-come-from)
- [What cannot be captured](#what-cannot-be-captured)
- [Bank sizing](#bank-sizing)
- [Copyright and what this repo reproduces](#copyright-and-what-this-repo-reproduces)
- [How the counts in this document were produced](#how-the-counts-in-this-document-were-produced)
- [Sources](#sources)

## Why this document exists

Two tracks have now been built this way, and both times reading the primary
document changed the scope in ways no third-party summary mentioned. On Linux+
it was AppArmor, which is not on the exam. On Network+ it was the absence of
every 802.11 letter standard, and a numerical error in CompTIA's own blog post
about its own exam.

This one had a third reason to start from the PDF. A prompt written before the
work began carried a set of pre-measured numbers, and the instruction attached
to them was to confirm or correct every one rather than build on them. Most held
exactly. Two did not, and both were counts of the objectives document itself,
which is the sort of thing that gets quoted onward once it is written down.

## The exam, confirmed

| | |
| --- | --- |
| Code | SY0-701, labelled V7 |
| Objectives document | Version 6.0, copyright 2023, print code 10179-Jan2023, 21 pages, 191,989 bytes |
| Launched | 7 November 2023 |
| Questions | Maximum of 90, multiple-choice and performance-based |
| Time | 90 minutes |
| Passing score | **750** on a scale of 100 to 900 |
| Languages | English, Japanese, Portuguese, Spanish, Thai |
| Recommended experience | Objectives document: "A minimum of 2 years of experience in IT administration with a focus on security, hands-on experience with technical information security, and broad knowledge of security concepts" |
| Estimated retirement | "usually three years after launch (estimated 2026)", per CompTIA's own page |

**The passing score is 750, not 720.** Both existing tracks are 720 and the value
is per-exam in `src/config/exams.ts`, so this is a one-line difference that is
silently wrong if the entry gets copied from an existing one. Nothing on the site
would fail; the scaled score on every practice attempt would simply be graded
against the wrong bar.

The passing score is not in the objectives document. It is on the certification
page, and the scale behaves the way it does on the other two exams: 750 out of
900 is not 83 percent, because the scale starts at 100 and CompTIA publishes no
scaling function. The orientation page has to say that out loud, the way the
Linux+ and Network+ pages do.

Two statements of recommended experience exist and they do not say the same
thing. The objectives document asks for two years in IT administration with a
security focus. The certification page asks for "CompTIA Network+ and two years
of experience working in a security/ systems administrator job role". Both are
CompTIA's, and a reader arriving from the Network+ track is entitled to know that
the prerequisite named on the web page is the exam they just sat.

The certification page also maps the certification to DoD 8140 work roles, naming
cyber defense analyst, incident responder, vulnerability analyst, security control
assessor and others. That is worth one sentence on the orientation page, because
it is the reason a large share of candidates are sitting this exam at all.

## Is SY0-701 still the current exam

Yes, and the successor is close enough that the answer needs a date on it.

CompTIA's certification page states that an exam retires "usually three years
after launch (estimated 2026)" and names no date. Training providers and threads
on instructor forums put SY0-801 at a launch in late 2026, with figures of
17 November 2026 and a partner preview around 20 October 2026 in circulation, and
SY0-701 retiring roughly six months later. Several of those pages say plainly
that CompTIA has confirmed neither an exam code nor a date, which is the honest
position and the one this repository takes.

What is checkable rather than reported: **the SY0-801 objectives document is not
on CompTIA's CDN as of 2026-08-21.** Three URLs following the naming pattern that
resolves for SY0-701, N10-009 and XK0-006 all return 404. CompTIA publishes
objectives ahead of a launch, so a document that is not there is evidence about
timing in a way a forum post is not.

The track is built against SY0-701. Most of what gets written survives a version
bump, because the material is cryptography, identity, logging, risk and
governance rather than a numbered list. The parts that do not survive are
concentrated in three mechanical places: the `exams.ts` entry, the
`examObjectives` block in each topic's frontmatter, and the `objective` field on
each question.

That produces one authoring rule, and it costs nothing now:

> **Objective numbers live in frontmatter and in question metadata. They do not
> go in prose.** A sentence reading "objective 4.3 names five activities" is a
> sentence somebody has to find and rewrite. Say what the thing is.

Check the CDN again before the verification pass. If the 801 objectives have
appeared, the decision gets made again with the document in hand.

## Domains and weights

Straight from the objectives document, which prints them as a table totalling
100 percent.

| Domain | Weight | Objectives |
| --- | --- | --- |
| 1.0 General Security Concepts | 12% | 4 |
| 2.0 Threats, Vulnerabilities, and Mitigations | 22% | 5 |
| 3.0 Security Architecture | 18% | 4 |
| 4.0 Security Operations | 28% | 9 |
| 5.0 Security Program Management and Oversight | 20% | 6 |

Twenty-eight objectives across five domains. Domain 4 is the largest at 28
percent and carries nine objectives, so an objective there is worth about 3.1
points of exam. Domain 1 is the smallest at 12 percent across four objectives, so
an objective there is worth 3.0. **The per-objective weight is almost flat across
this exam**, ranging only from 3.0 to 4.5 points, which is unusual and useful: it
means objective count is a fair proxy for how much of the track each domain
should occupy, and a plan balanced by objective is close to a plan balanced by
weight.

## The twenty-eight objectives

CompTIA's own statements, which is what gets reproduced in `exams.ts`. The
sub-bullet content under each is copyrighted and is not reproduced anywhere in
this repository.

### 1.0 General Security Concepts, 12%

```
1.1 Compare and contrast various types of security controls.
1.2 Summarize fundamental security concepts.
1.3 Explain the importance of change management processes and the impact to security.
1.4 Explain the importance of using appropriate cryptographic solutions.
```

### 2.0 Threats, Vulnerabilities, and Mitigations, 22%

```
2.1 Compare and contrast common threat actors and motivations.
2.2 Explain common threat vectors and attack surfaces.
2.3 Explain various types of vulnerabilities.
2.4 Given a scenario, analyze indicators of malicious activity.
2.5 Explain the purpose of mitigation techniques used to secure the enterprise.
```

### 3.0 Security Architecture, 18%

```
3.1 Compare and contrast security implications of different architecture models.
3.2 Given a scenario, apply security principles to secure enterprise infrastructure.
3.3 Compare and contrast concepts and strategies to protect data.
3.4 Explain the importance of resilience and recovery in security architecture.
```

### 4.0 Security Operations, 28%

```
4.1 Given a scenario, apply common security techniques to computing resources.
4.2 Explain the security implications of proper hardware, software, and data asset management.
4.3 Explain various activities associated with vulnerability management.
4.4 Explain security alerting and monitoring concepts and tools.
4.5 Given a scenario, modify enterprise capabilities to enhance security.
4.6 Given a scenario, implement and maintain identity and access management.
4.7 Explain the importance of automation and orchestration related to secure operations.
4.8 Explain appropriate incident response activities.
4.9 Given a scenario, use data sources to support an investigation.
```

### 5.0 Security Program Management and Oversight, 20%

```
5.1 Summarize elements of effective security governance.
5.2 Explain elements of the risk management process.
5.3 Explain the processes associated with third-party risk assessment and management.
5.4 Summarize elements of effective security compliance.
5.5 Explain types and purposes of audits and assessments.
5.6 Given a scenario, implement security awareness practices.
```

## The verb profile, and why it decides the shape of the track

The opening verb of an objective is the closest thing CompTIA publishes to a
statement about what the item will ask for, and this exam's distribution is not
the one either existing track was built around.

| | XK0-006 | N10-009 | SY0-701 |
| --- | --- | --- | --- |
| Objectives | 29 | 25 | 28 |
| "Given a scenario" objectives | 18 | 10 | **7** |
| Scenario share by exam weight | 63.5% | 44.3% | **24.7%** |
| Everything else, by weight | 36.5% | 55.7% | **75.3%** |

Broken out for this exam, weighting each objective at its domain's share divided
by the number of objectives in that domain:

| Verb | Objectives | Share by weight |
| --- | --- | --- |
| Explain | 14 | 49.3% |
| Compare and contrast | 4 | 16.4% |
| Summarize | 3 | 9.7% |
| Given a scenario | 7 | 24.7% |

The seven scenario objectives are 2.4, 3.2, 4.1, 4.5, 4.6, 4.9 and 5.6. Four of
the seven are in domain 4, which is where the captured output also is, and that
is not a coincidence: the objectives that ask you to do something are the ones
with something to run.

**Explain alone is half this exam.** The Linux+ thesis is change a system and
prove the change took. The Network+ thesis is read a network you did not build
and prove what it is doing. Neither survives at 24.7 percent scenario weight, and
a track that inherits either produces pages that keep promising to run something.
What replaces it is the business of the teaching design rather than this
document, but the number is the reason the question gets asked.

One boundary worth stating, because it was stated for Network+ and the same
temptation exists here. The objective verb is being used as a proxy for the
cognitive level of the items, and CompTIA publishes no mapping between the two.
It is a reasonable proxy and it is not evidence.

## The vocabulary load

Counted from the objectives document, using the extraction described in
[how the counts were produced](#how-the-counts-in-this-document-were-produced).
The same extractor was run against N10-009 so the comparison is like for like.

| | N10-009 | SY0-701 |
| --- | --- | --- |
| Bullet term lines | 512 | **797** |
| Unique terms | 499 | **743** |
| Acronym appendix entries | 161 | **334** |

**This is the largest vocabulary of the three exams and it is not close.** Half
again as many terms as Network+, and roughly twice the acronyms.

Two corrections to the pre-work, both in the same direction. The figures carried
into this work were 845 bullet term lines and 788 unique. The counts above are
797 and 743, from an extractor that reads the PDF's three-column layout by
coordinate rather than by reading order, joins a term that wraps onto a second
line back into one term, and excludes the four bullets in the "About the Exam"
preamble. The ratio against Network+ is unchanged at about 1.5 to 1, which is the
part the plan actually rests on.

Terms per objective, which is the number that decides how long a topic is:

| Obj | Terms | Obj | Terms | Obj | Terms | Obj | Terms |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1.1 | 12 | 2.3 | 29 | 3.4 | 30 | 4.7 | 24 |
| 1.2 | 36 | 2.4 | 47 | 4.1 | 41 | 4.8 | 21 |
| 1.3 | 21 | 2.5 | 20 | 4.2 | 12 | 4.9 | 13 |
| 1.4 | 42 | 3.1 | 35 | 4.3 | 38 | 5.1 | 36 |
| 2.1 | 22 | 3.2 | 34 | 4.4 | 23 | 5.2 | 38 |
| 2.2 | 32 | 3.3 | 30 | 4.5 | 33 | 5.3 | 20 |
| | | | | 4.6 | 41 | 5.4 | 24 |
| | | | | | | 5.5 | 21 |
| | | | | | | 5.6 | 22 |

The spread runs from 12 to 47, and it does not track exam weight. Objective 2.4
carries 47 terms for 4.4 points of exam. Objective 4.2 carries 12 for 3.1. **Term
count is the better predictor of how many topics an objective needs**, and the
plan is built on it rather than on weight alone.

The `dl.terms` list in section 2 of the topic template is the mechanism that
already exists for this, and it carries more weight on this track than on either
other one.

## The acronym list

The appendix holds **334 entries under 328 distinct abbreviations**, and it
instructs candidates to "attain a working knowledge of all listed acronyms".

Five abbreviations appear more than once with different expansions, which is a
real feature of the list rather than a parsing artefact:

| Abbreviation | Expansions |
| --- | --- |
| MAC | Mandatory Access Control, Media Access Control, Message Authentication Code |
| PAM | Privileged Access Management, Pluggable Authentication Modules |
| RA | Recovery Agent, Registration Authority |
| RBAC | Role-based Access Control, Rule-based Access Control |
| SAN | Storage Area Network, Subject Alternative Name |

Those five are worth teaching as collisions rather than as entries. MAC in
particular means three different things across three different domains of this
exam, and a candidate who has only met one of them will read a stem wrongly.

**The appendix and the objectives text have drifted apart badly.** Matching each
abbreviation against the objectives text:

| | Entries |
| --- | --- |
| The abbreviation appears in the objectives text | 77 |
| The expansion appears, the abbreviation does not | 16 |
| Neither appears in any form | **241** |

Seventy-two percent of the acronym list names something the objectives never ask
about. The same shape appeared on both other exams, at 22 entries on XK0-006 and
a comparable share on N10-009, so the pattern is not new. The scale is.

Reading the 241 shows what they are. A large block is superseded technology:
3DES, DES, RC4, WEP, TKIP, SHTTP, WTLS, MD5, PPTP, LEAP. Another is networking
vocabulary a Network+ candidate already owns: BGP, OSPF, MPLS, VLAN, VLSM, MTU,
NAT, PAT, CSU, DSL, POTS, PBX. A third is job titles and organisational
furniture: CIO, CSO, CTO, DBA, DPO, ISSO, CERT, CIRT. A fourth is cryptographic
mode and primitive detail the objectives do not name: CBC, CFB, ECB, CTM, GCM,
IDEA, RIPEMD, PBKDF2, ECDSA, ECDHE, DHE.

**The policy that follows, decided here so it is not decided at topic 40:** an
abbreviation whose concept the track teaches gets the abbreviation printed once,
in the topic that teaches the concept, and nothing more. An abbreviation naming
something genuinely off the objectives gets nothing, because a page written to
cover a list rather than to teach is the failure mode this whole track exists to
avoid. Two hundred and forty-one sentences added to satisfy an appendix would be
exactly that page, repeated.

The exception is the five collisions above, which earn real treatment because
they are a way to get a question wrong rather than a word to recognise.

## What the primary document says that summaries do not

**The bulleted lists are explicitly not exhaustive.** The document states that
other examples of technologies, processes or tasks pertaining to each objective
may also appear on the exam although not listed. That is a statement about the
lists, and it is the reason a track cannot be a transcription of them.

**Physical security is objective 1.2, not a domain of its own, and it is
specific.** It names bollards, access control vestibules, fencing, video
surveillance, security guards, access badges and lighting, plus four sensor types:
infrared, pressure, microwave and ultrasonic. Every one of those is an object a
reader may never have seen, which is the test the Network+ design set for whether
a topic wants a photograph.

**Zero Trust is broken into a control plane and a data plane**, and the split is
named down to the component: adaptive identity, threat scope reduction,
policy-driven access control, Policy Administrator and Policy Engine on one side;
implicit trust zones, subject/system and Policy Enforcement Point on the other.
That is SP 800-207's vocabulary, and it is examinable at that level of detail.

**Deception technology gets four named artefacts**: honeypot, honeynet, honeyfile
and honeytoken. Three of them are files or records rather than machines, which is
the distinction most summaries collapse into "honeypot".

**The arithmetic is named.** Objective 5.2 names SLE, ALE and ARO, plus RPO, RTO,
MTTR and MTBF. Objective 4.3 names CVSS and CVE. Nothing else on this exam has a
right answer you can compute, which makes those the natural home for the "work it
out" form of Prove it.

**Objective 4.9 is thirteen terms and almost all of them are log sources.**
Firewall logs, application logs, endpoint logs, OS-specific security logs, IPS
and IDS logs, network logs, metadata, vulnerability scans, automated reports,
dashboards and packet captures. It is the smallest objective in domain 4 by term
count and the one most obviously served by real captured output.

**Objective 2.4's indicators are a separate list from its attacks.** Account
lockout, concurrent session usage, blocked content, impossible travel, resource
consumption, resource inaccessibility, out-of-cycle logging, published or
documented, and missing logs. Those are what a defender sees, as opposed to what
an attacker did, and the distinction is the whole argument for the
attack-demonstration rule in the teaching design.

**Certificate handling is named to the field.** Certificate authorities, CRLs,
OCSP, self-signed, third-party, root of trust, CSR generation and wildcard. A
reader is expected to know what a wildcard certificate is and what a CSR
contains, not just that PKI exists.

## The hardware and software list

The document closes with a sample list of hardware and software for building a
lab, which is the closest thing to a statement about what candidates are expected
to have touched. It names, among the software: Windows OS, Linux OS, Kali Linux,
packet capture software, penetration testing software, static and dynamic
analysis tools, a vulnerability scanner, network emulators, sample code, a code
editor, SIEM, keyloggers, MDM software, VPN, DHCP service and DNS service. Under
"Other" it names access to cloud environments, sample network documentation and
diagrams, and sample logs.

Two things follow. **Sample logs are on CompTIA's own list**, which supports the
decision to hand readers real captured log output rather than describing it. And
a full lab is a large ask, which is the argument for the track carrying the
captures rather than asking the reader to reproduce them.

## Measuring the default free resource

Professor Messer's SY0-701 videos are free, cover every objective, and are what a
large share of candidates actually use. Counting them is not an argument with
them. It is how you find out where a written track is worth somebody's time.

Counted from his own course page on 2026-08-21: **121 videos, 15 hours 11
minutes**, ordered strictly by CompTIA's objective numbering. One is an exam
overview, leaving 120 mapped to objectives.

| Domain | Videos | Share of the 120 | Exam weight |
| --- | --- | --- | --- |
| 1.0 | 18 | 15.0% | 12% |
| 2.0 | 38 | 31.7% | 22% |
| 3.0 | 18 | 15.0% | 18% |
| 4.0 | 29 | 24.2% | 28% |
| 5.0 | 17 | 14.2% | 20% |

Video count is a proxy for coverage and not the same as minutes, so the gaps read
as directional. The direction is consistent: threats and vulnerabilities gets
about ten points more attention than its weight, and governance, risk and
compliance gets about six points less on the second-largest domain of the exam.

At objective level the thin spots are sharper. **Objective 4.9, using data
sources to support an investigation, has one video.** So do 4.2, 4.7, 2.1 and
1.1. Objectives 2.3 and 2.4 have 14 and 15.

Three differences a written track can claim, and each is a decision rather than
an assumption:

**Order.** His course follows CompTIA's numbering, so change management arrives
at 1.3 before a reader has seen a control operating. Both existing tracks are
written in reading order with objectives mapped in, and the Network+ reorder
moved 70 of 76 topics. The orientation page has to say why the order differs,
because a reader arriving from his course will notice immediately.

**Captured evidence.** Objective 4.9 is a log-reading objective on a 28 percent
domain with one video behind it. A page handing over real `journalctl`, real
`Get-WinEvent` and real `log show` output for the same event is a thing video
does badly and this repository already has the tooling for.

**Revisability.** A fact that changes needs a re-recorded video or an edited
paragraph. That argues for putting dated, checkable numbers on pages rather than
avoiding them, the way Network+ topic 08 carries measured IPv6 adoption.

**One boundary, and it matters.** His course is a benchmark for coverage and a
signal of the mental model a reader arrives with. It is not an input to write
from. Every topic and every question comes from the objectives document and
primary documentation, and somebody else's course is neither. Where his framing
of a concept is the one a reader arrives with, the useful move is to say what
that framing leaves out.

## Where output can come from

The existing toolchain is unchanged. What is new is which parts of it reach this
exam, and six routes that were unproven when the plan was drafted.

Proven on 2026-08-21, from this machine:

| Route | Result |
| --- | --- |
| CISA Known Exploited Vulnerabilities catalogue JSON | 200, 1,596,534 bytes |
| FIRST EPSS API | 200, a real score for CVE-2021-44228 dated the day of the query |
| NVD CVE API 2.0 | 200, 87,139 bytes for one CVE |
| MITRE ATT&CK enterprise STIX bundle | 200, 53,835,637 bytes |
| crt.sh JSON | **200**, real certificate transparency entries for a real domain |
| `oscap` with the SCAP Security Guide, in a container | Real profile list and real per-rule pass, fail and notapplicable results |
| `cryptsetup` under `capture.sh --block 1` | Real LUKS2 header with real salts, cipher and PBKDF parameters |
| `auditd` on the `capture.sh vm` target | Real `auditctl -s` status and a real audit log of PAM records |
| `auditd` under `capture.sh --privileged` | **Fails.** "Operation not permitted" on the audit netlink socket |
| `lynis` in a container | Runs, and needs `procps` installed or every process test errors |

Three of those change the plan.

**crt.sh works.** The pre-work recorded 502 on two attempts and flagged it for a
retry. The retry returned real certificate transparency log entries, including
issuer, subject, serial and validity window for a domain this project owns. A
topic on certificates and revocation can therefore show a reader every
certificate ever issued for a name, which is the observable half of a whole class
of attack.

**auditd is a `vm` capture, not a `--privileged` one.** The audit netlink socket
refuses a container regardless of privilege, and `capture.sh --privileged` returns
"Operation not permitted" for status, rule addition and rule listing alike. On the
podman machine itself the same commands return real status and the log carries
genuine `USER_ACCT`, `USER_CMD`, `CRED_REFR` and `USER_START` records with SELinux
contexts and login UIDs on them. One limit found and worth respecting: adding a
syscall watch rule was accepted and listed, and produced no file-access records in
this test, so a topic must not promise a file-watch demonstration from this route
without proving that specific capture first.

**oscap is the strongest new route on the track.** It produces a named profile
list including CIS, ANSSI, HIPAA and the Australian Essential Eight against one
datastream, and evaluating a single rule returns a real result. The result of one
rule in a container came back `notapplicable`, which is not a failure of the route
but the most teachable outcome it has: a benchmark written for a server says
nothing useful about a machine that is not one, and a compliance score computed
without noticing that is the thing this exam is asking candidates to see through.

**Where the captures are.** Objective 1.4 is cryptography and almost all of it
runs. In domain 4, objective 4.1 is applying security techniques to computing
resources, 4.3 is vulnerability management with three public APIs behind it, 4.4
is alerting and monitoring, 4.6 is identity and access management, and 4.9 is log
analysis. That is most of a 28 percent domain plus a 12 percent one.

## What cannot be captured

**Domain 5 is 20 percent of the exam with essentially nothing to run.**
Governance, risk, third-party management, compliance, audits and awareness. Those
topics use the other two forms of evidence, and each says so in its provenance
line rather than dressing a hand-written block as a capture.

**Domain 2 is mostly conceptual** on threat actors and vulnerability types, and
**domain 3** on architecture models. Both carry places where the observable
evidence of something can be captured even though the thing itself cannot, and
that distinction is a rule in the teaching design rather than a judgement made
per topic.

**Nothing on this track runs an attack.** The rule is stated hard in the teaching
design and its short form is that the evidence gets captured and the technique
gets described.

## Bank sizing

Rounding each domain weight against 90 questions gives 11, 20, 16, 25 and 18,
which totals exactly 90. The `weightedShares` helper built for Network+ does
largest-remainder reconciliation and arrives at the same five numbers, so this
exam has nothing to reconcile.

| Bank | Weight | Weighted share | Pool target at POOL_MULTIPLE 3 |
| --- | --- | --- | --- |
| Domain 1 | 12% | 11 | 33 |
| Domain 2 | 22% | 20 | 60 |
| Domain 3 | 18% | 16 | 48 |
| Domain 4 | 28% | 25 | 75 |
| Domain 5 | 20% | 18 | 54 |
| **Total** | | **90** | **270** |

## Copyright and what this repo reproduces

The position is the one set out in
[linux-plus-question-authoring-standard.md](linux-plus-question-authoring-standard.md)
and nothing about this exam changes it. The objectives document's own authorized
materials policy names brain dumps as the target and directs questions to
`examsecurity@comptia.org`.

What this repository reproduces from the objectives document: the exam code, the
domain names and weights, the test details, and the twenty-eight objective
statements. Those are how the exam is referenced and they are reproduced in
`src/config/exams.ts` and in topic frontmatter.

What it does not reproduce: the sub-bullet content under any objective, and the
acronym appendix. Terms from the bullets are taught in the topic that owns the
idea, in this project's own words, and the coverage check that walks them is a
build-time script rather than a stored copy of the list.

The trademark rule applies as it does to both other tracks. The track name is
"CompTIA Security+", never "Security+" alone, and the disclaimer line goes on the
track index, coverage, plan and practice pages.

## How the counts in this document were produced

Recorded because two of the figures inherited from the pre-work turned out to be
wrong, and because a number nobody can reproduce is worth less than one nobody
has checked.

The objectives PDF is a three-column layout with an objective's bullets flowing
across all three columns inside a vertical band under its statement. Reading the
extracted text in stream order interleaves objectives, which is why a first pass
attributed 47 terms to 2.5 and none to 2.4. The extractor used here reads each
text run with its coordinates, clusters runs into lines within a column with a
four-point tolerance so that a bullet glyph and its text join up, splits the page
at x=220 and x=400, bands by the y position of each objective statement, and then
walks column zero, one and two in order. A line that does not start with a bullet
glyph is joined to the term above it.

That reproduces 797 bullet lines and 743 unique terms, which agrees exactly with
a naive line-based count of the same region taken independently, and it assigns
every one of them to the right objective. Objective 1.2 comes out at 36 terms,
which matches a count done by hand from the page.

Acronym entries are parsed by treating a line as a new entry when its first token
has two or more capitals or contains a digit, which separates `IaaS`, `SoC`,
`SQLi`, `VoIP` and `DDoS` from continuation lines such as "Common Knowledge". Three
entries are two tokens long and are special-cased: `USB OTG`, `PCI DSS` and
`SE Linux`.

Word counts of existing topics exclude frontmatter and include figure markup and
code fences, which overstates prose by a margin that is roughly constant across
topics.

## Sources

| Claim | Source | URL | Result |
| --- | --- | --- | --- |
| Objectives, domains, weights, test details, acronym appendix, hardware list | CompTIA Security+ SY0-701 Certification Exam Objectives, version 6.0 | `https://comptiacdn.azureedge.net/webcontent/docs/default-source/exam-objectives/comptia-security-sy0-701-exam-objectives-(6-0).pdf` | 200, 191,989 bytes, 21 pages |
| Passing score, languages, launch date, estimated retirement, DoD 8140 roles | CompTIA Security+ certification page | https://www.comptia.org/en-us/certifications/security/ | 200 |
| SY0-801 objectives not yet published | Three CDN URLs following the established naming pattern | see above | 404 |
| PBQ formats, skippability, partial credit | CompTIA, Performance-Based Questions Explained | https://www.comptia.org/en-us/resources/test-policies/exam-development/performance-based-questions-explained/ | 200 |
| Confidentiality, reconstruction through memorization | CompTIA Candidate Agreement | https://www.comptia.org/en-us/resources/test-policies/comptia-candidate-agreement/ | 200 |
| Certification naming and logo rules | CompTIA, Using CompTIA Trademarks | https://www.comptia.org/en-us/legal/trademarks/ | 200 |
| 121 videos, 15h11m, per-domain and per-objective split | professormesser.com SY0-701 course page | https://www.professormesser.com/security-plus/sy0-701/sy0-701-video/sy0-701-comptia-security-plus-course/ | 200 |
| SY0-801 timing, reported and unconfirmed | Training provider articles, none citing a CompTIA statement | various | read 2026-08-21 |
| Zero Trust control and data plane vocabulary | NIST SP 800-207 | https://csrc.nist.gov/pubs/sp/800/207/final | 200 |
| Authentication and password guidance | NIST SP 800-63B | https://csrc.nist.gov/pubs/sp/800/63/b/upd2/final | 200 |
| Incident response lifecycle | NIST SP 800-61r3 | https://csrc.nist.gov/pubs/sp/800/61/r3/final | 200 |
| Post-quantum key encapsulation | FIPS 203 | https://csrc.nist.gov/pubs/fips/203/final | 200 |
| Control catalogue | NIST SP 800-53 Rev. 5 | https://csrc.nist.gov/pubs/sp/800/53/r5/upd1/final | 200 |
| Risk assessment method | NIST SP 800-30 Rev. 1 | https://csrc.nist.gov/pubs/sp/800/30/r1/final | 200 |
| Adversary tactics and techniques | MITRE ATT&CK | https://attack.mitre.org/ | 200 |
| Web application risks | OWASP Top Ten | https://owasp.org/www-project-top-ten/ | 200 |
| Vulnerability scoring | FIRST CVSS v4.0 specification | https://www.first.org/cvss/v4.0/specification-document | 200 |
| Exploit prediction scoring | FIRST EPSS | https://www.first.org/epss/ | 200 |
| Exploited in the wild | CISA Known Exploited Vulnerabilities catalogue | https://www.cisa.gov/known-exploited-vulnerabilities-catalog | 200 |
| Payment card requirements | PCI Security Standards Council document library | https://www.pcisecuritystandards.org/document_library/ | 200 |
| Security vocabulary | RFC 4949, Internet Security Glossary version 2 | https://www.rfc-editor.org/rfc/rfc4949.html | 200 |
| Information security management systems | ISO/IEC 27001 | https://www.iso.org/standard/27001 | **403.** Known robot block, already recorded for this project. Cite without fetching |

One claim carried in the pre-work is deliberately absent. A retrieval-practice
meta-analysis was cited there at Hedges g = 0.61, marked as not fetched. The
publisher's copy returns 403 and no accessible copy was found, so it is not cited
here and the learning-science position stays the one recorded in
[linux-plus-teaching-design.md](linux-plus-teaching-design.md), which rests on
sources that were fetched.
