# Splunk certification: what the programme is, and what is on the four exams

What Splunk's certification programme currently contains, taken from Splunk's own
blueprints, candidate handbook and legal pages rather than from anybody's summary.
Companion to `splunk-teaching-design.md` and `splunk-topic-plan.md`, neither of
which should be written before this document is read.

Research date: 2026-08-25. Every URL in [Sources](#sources) returned 200 on that
date. Where a page is served only to a browser user agent, that is recorded next
to it.

- [Why this document exists](#why-this-document-exists)
- [The programme, confirmed](#the-programme-confirmed)
- [The exam table, every cell checked](#the-exam-table-every-cell-checked)
- [The fifth exam, and the sixth](#the-fifth-exam-and-the-sixth)
- [The retirement position](#the-retirement-position)
- [What is on each of the four exams](#what-is-on-each-of-the-four-exams)
- [The prerequisite graph](#the-prerequisite-graph)
- [Copyright, trademark, and what this repo may reproduce](#copyright-trademark-and-what-this-repo-may-reproduce)
- [Where the documentation now lives, and the version to pin](#where-the-documentation-now-lives-and-the-version-to-pin)
- [Term extraction](#term-extraction)
- [What can be captured, and what cannot](#what-can-be-captured-and-what-cannot)
- [The overlap audit](#the-overlap-audit)
- [The structure decision](#the-structure-decision)
- [Resources worth using, measured](#resources-worth-using-measured)
- [What this changes about the build prompt](#what-this-changes-about-the-build-prompt)
- [Sources](#sources)

## Why this document exists

The build prompt states that its exam table is unverified and that step one is
confirming or correcting every cell. Every cell has now been checked against
Splunk's published blueprints. Four of the twelve cells were right, five were
incomplete, and three facts that decide the shape of the whole track were absent
from the table because nobody had looked for them.

The three that matter most, stated here because they change the plan rather than
decorating it:

**Splunk Enterprise Certified Admin has a prerequisite exam.** Splunk Core
Certified Power User is required, and it is printed on the Admin blueprint. A
reading order that treats the four exams as independent is wrong about the one
place Splunk itself says they are not.

**Enterprise Security has no free licence and no self-serve trial.** Trials are
issued by a sales representative. That removes the capture route for most of the
fourth exam and it is the single largest correction to the build prompt.

**The documentation has moved.** `docs.splunk.com` now redirects individual
manual pages to `help.splunk.com`, and the new URL carries the version number in
the path. The primary source named in the build prompt is a redirect.

## The programme, confirmed

Splunk publishes fourteen certifications. The build prompt names four of them and
asks whether there is a fifth. There are ten others.

| Certification | Level | Products |
| --- | --- | --- |
| Splunk Core Certified User | Entry | Splunk Enterprise, Splunk Cloud |
| Splunk Core Certified Power User | Entry | Splunk Enterprise, Splunk Cloud |
| Splunk Core Certified Advanced Power User | Intermediate | Splunk Enterprise, Splunk Cloud |
| Splunk Cloud Certified Admin | Professional | Splunk Cloud |
| Splunk Enterprise Certified Admin | Professional | Splunk Enterprise |
| Splunk Enterprise Certified Architect | Professional | Splunk Enterprise |
| Splunk Core Certified Consultant | Expert | Splunk Enterprise |
| Splunk Certified Cybersecurity Defense Analyst | Intermediate | Splunk Enterprise, Splunk Enterprise Security |
| Splunk Certified Cybersecurity Defense Engineer | Professional | Splunk Enterprise, Splunk Enterprise Security |
| Splunk Certified Cybersecurity Defense Architect | Expert | Splunk Enterprise, Splunk Enterprise Security, Splunk SOAR |
| Splunk O11y Cloud Certified Metrics User | not stated | Splunk Observability Cloud |
| Splunk Enterprise Security Certified Admin (Legacy) | not stated | Splunk Enterprise Security |
| Splunk IT Service Intelligence Certified Admin (Legacy) | not stated | Splunk ITSI |
| Splunk SOAR Certified Automation Developer (Legacy) | not stated | Splunk SOAR |

Levels are taken from the blueprints, which print them next to the question count.
The certification landing page groups the certifications without printing a level,
and the three legacy entries have no current blueprint to read one from.

Programme administration has moved to Cisco. The candidate handbook gives
`splunk_certification@cisco.com` as the contact for accommodations, voucher
conversion and recertification questions, and the certification landing page
carries a "Splunk is now a Cisco company" note. Trademarks are held by Splunk LLC,
not Splunk Inc.

Facts that apply across the programme, from the candidate handbook:

- Every certification is valid for three years from the date earned.
- A 90-day grace period follows the cycle end date. Missing it sets the
  certification inactive and the candidate restarts.
- Each attempt costs $130 USD, or $500 USD for five registrations.
- Delivery is through Pearson VUE, in a test centre or online proctored.
- Candidates must be 18, or 13 to 17 with a countersigned parental consent form.

## The exam table, every cell checked

The build prompt's table, with every cell either confirmed or corrected. The
"moved" column is what the brief asked for.

| Cell | What the prompt believed | What the blueprint says | Moved |
| --- | --- | --- | --- |
| Core User, code | SPLK-1001 | SPLK-1001, but Splunk does not print it | Qualified |
| Core User, audience | Never run a search | Entry level, no prerequisite | Confirmed |
| Power User, code | SPLK-1002 | SPLK-1002, same qualification | Qualified |
| Power User, audience | Builds knowledge objects for other people | Knowledge objects, correlation, data models, CIM | Confirmed |
| Enterprise Admin, code | SPLK-1003 | SPLK-1003, same qualification | Qualified |
| Enterprise Admin, audience | Runs the platform | Runs the platform, **and Power User is a required prerequisite** | Corrected |
| Defense Engineer, code | SPLK-5002 | SPLK-5002, same qualification | Qualified |
| Defense Engineer, audience | Builds detections in Enterprise Security | Detections in Enterprise Security, plus SOAR automation at 20 percent | Corrected |

**On the codes.** SPLK-1001, SPLK-1002, SPLK-1003 and SPLK-5002 are correct, and
they are corroborated across Splunk Community threads and the blueprint file
names. They appear on none of Splunk's own certification pages, on none of the
ten blueprint PDFs, and not in the candidate handbook. The Pearson VUE Splunk
landing page does not print them either; it links to a registration catalogue
behind a login. Treat the codes as usable identifiers with a named provenance
rather than as published facts, and do not put them anywhere a reader would take
them for Splunk's own labelling.

What the table did not carry, and what the blueprints do:

| | Core User | Power User | Enterprise Admin | Defense Engineer |
| --- | --- | --- | --- | --- |
| Questions | 60 | 65 | 56 | 60 |
| Minutes | 60 | 60 | 60 | 75 |
| Level | Entry | Entry | Professional | Professional |
| Domains | 8 | 10 | 17 | 5 |
| Objectives | 38 | 30 | 50 | 19 |
| Prerequisite exam | none | none | Core Certified Power User | none |

Total exam time includes three minutes to review the certification agreement, on
all four. Domain weights sum to 100 on all four, checked arithmetically.

Two things follow from that grid that no summary of this programme mentions.

**The Admin exam has the fewest questions and the most objectives.** Fifty
objectives across seventeen domains, tested by 56 questions in 60 minutes. Twelve
of its seventeen domains carry 5 percent, which is between two and three questions
each. A track that gives every Admin objective equal depth will be wrong about
where the exam actually spends its marks.

**The Defense Engineer exam is the opposite shape.** Five domains, nineteen
objectives, and one domain carrying 40 percent on its own. Detection engineering
is not one topic among five, it is nearly half the paper.

## The fifth exam, and the sixth

The build prompt asks whether Cybersecurity Defense Analyst exists, whether it is
a prerequisite, and whether the four named exams are still the four.

**It exists.** Splunk Certified Cybersecurity Defense Analyst, SPLK-5001, 66
questions, Intermediate level, 75 minutes, six domains, 20 objectives.

**It is not a prerequisite for Defense Engineer.** The Defense Engineer blueprint
states that there are no prerequisite exams, and recommends Power User level
knowledge of Splunk Enterprise plus familiarity with administrator tasks. Several
widely circulated third-party study guides state that SPLK-5001 is required. The
blueprint contradicts them.

**There is also a sixth.** Splunk Certified Cybersecurity Defense Architect, 67
questions, Expert level, 75 minutes, no prerequisite exam. Its blueprint is the
only one of the ten that describes the candidate's experience, giving five to
seven years.

The four named in the build prompt are still four current exams. They are not,
however, the natural four, and this is worth putting in front of a decision rather
than burying:

The Defense Analyst blueprint carries a domain called SPL and Efficient Searching
at 20 percent, and another on SIEM concepts and the interaction between the common
information model, data models and acceleration at 20 percent. That is the bridge
between the core line and the security line, and the Defense Engineer blueprint
assumes it: its own preparation list begins "in addition to the courses listed for
Splunk Certified Cybersecurity Defense Analyst". Covering Engineer without Analyst
means teaching detection engineering to a reader who has not been taught the
investigation vocabulary the detections produce.

**Decided 2026-08-25: the track covers five exams.** Core User, Core Power User,
Enterprise Admin, Cybersecurity Defense Analyst, Cybersecurity Defense Engineer.
The build prompt's four is the one combination that leaves a gap in the middle,
because Defense Engineer assumes an investigation vocabulary that only the Analyst
blueprint tests. Adding it costs about 14 topics and 79,000 words. See
[the structure decision](#the-structure-decision).

Advanced Power User, Cloud Admin, Architect, Consultant, the observability
certification and the three legacy ones are out of scope. Advanced Power User
stays useful as a cross-check on SPL coverage rather than as a target, for the
reason in [term extraction](#term-extraction).

## The retirement position

Checked the way the Security+ track checked for SY0-801, and the answer is more
interesting than a version bump.

**None of the four exams is retired or scheduled for retirement.** All four have
current blueprints served from Splunk's own PDF path, all four are listed on the
certification landing page without a legacy marker, and all four are bookable.

**Splunk introduced a legacy category on 1 January 2026.** Three certifications
were reclassified: Enterprise Security Certified Admin, SOAR Certified Automation
Developer, and IT Service Intelligence Certified Admin. A legacy certification
remains valid and bookable; what stops is content maintenance against product
releases. The certification landing page and the candidate handbook both carry the
marker, and the handbook's next-level table gives all three "(none)".

**The recertification policy changed on 1 March 2026.** Renewal through coursework
was removed. Two routes remain: retake the same exam within the final year of the
window, or pass a higher-level exam in the same track, which also renews
downstream certifications. The certification agreement carries the same date as
its last modification.

This matters for the fourth exam specifically. Splunk names Cybersecurity Defense
Analyst and Cybersecurity Defense Engineer as what to pursue instead of the now
legacy Enterprise Security Certified Admin. The exam this track would cover is the
replacement for a retired one, which is the healthiest possible position to build
against and is worth knowing before committing to it.

A frequently asked questions document about these changes is served publicly from
`splunk.com/en_us/pdfs/training/splunk-certification-changes.pdf` and carries a
"Cisco Confidential" footer on every page. Nothing in this document rests on it.
Every fact in this section is also on the public certification landing page or in
the public candidate handbook, both of which are cited below.

## What is on each of the four exams

Domain titles and weights are reproduced, because they are short factual labels
and the weights are numbers. Objective statements are paraphrased rather than
quoted, for the reason in
[copyright](#copyright-trademark-and-what-this-repo-may-reproduce).

### Splunk Core Certified User, 8 domains

| | Domain | Weight |
| --- | --- | --- |
| 1.0 | Splunk Basics | 5% |
| 2.0 | Basic Searching | 22% |
| 3.0 | Using Fields in Searches | 20% |
| 4.0 | Search Language Fundamentals | 15% |
| 5.0 | Using Basic Transforming Commands | 15% |
| 6.0 | Creating Reports and Dashboards | 12% |
| 7.0 | Creating and Using Lookups | 6% |
| 8.0 | Creating Scheduled Reports and Alerts | 5% |

Searching is 57 percent across domains 2 to 4 before a single transforming command
appears. The objectives under domain 2 cover time range, the timeline, refining a
search, controlling a search job and saving results, which is a description of the
search interface rather than of the language. Domain 4 names five commands
directly. Domain 5 names three.

### Splunk Core Certified Power User, 10 domains

| | Domain | Weight |
| --- | --- | --- |
| 1.0 | Using Transforming Commands for Visualizations | 5% |
| 2.0 | Filtering and Formatting Results | 10% |
| 3.0 | Correlating Events | 15% |
| 4.0 | Creating and Managing Fields | 10% |
| 5.0 | Creating Field Aliases and Calculated Fields | 10% |
| 6.0 | Creating Tags and Event Types | 10% |
| 7.0 | Creating and Using Macros | 10% |
| 8.0 | Creating and Using Workflow Actions | 10% |
| 9.0 | Creating Data Models | 10% |
| 10.0 | Using the Common Information Model (CIM) Add-On | 10% |

Seven of ten domains sit at exactly 10 percent, so this exam is flatter than any
of the others and a reading order derived from weight alone will not produce one.
Domain 3 is the heaviest and its last objective is the comparison between
transactions and `stats`, which is the classic place a Splunk answer looks right
and is wrong.

### Splunk Enterprise Certified Admin, 17 domains

| | Domain | Weight | | Domain | Weight |
| --- | --- | --- | --- | --- | --- |
| 1.0 | Splunk Admin Basics | 5% | 10.0 | Configuring Forwarders | 5% |
| 2.0 | License Management | 5% | 11.0 | Forwarder Management | 10% |
| 3.0 | Splunk Configuration Files | 5% | 12.0 | Monitor Inputs | 5% |
| 4.0 | Splunk Indexes | 10% | 13.0 | Network and Scripted Inputs | 5% |
| 5.0 | Splunk User Management | 5% | 14.0 | Agentless Inputs | 5% |
| 6.0 | Splunk Authentication Management | 5% | 15.0 | Fine Tuning Inputs | 5% |
| 7.0 | Getting Data In | 5% | 16.0 | Parsing Phase and Data | 5% |
| 8.0 | Distributed Search | 10% | 17.0 | Manipulating Raw Data | 5% |
| 9.0 | Getting Data In, Staging | 5% | | | |

Three domains carry 10 percent: indexes, distributed search and forwarder
management. Everything else is 5 percent. Getting data in is split across domains
7, 9, 10, 11, 12, 13, 14 and 15, which is 45 percent of the exam under eight
headings, and no single heading looks important on its own. That split is the most
consequential thing on this blueprint and the reason an objective-order reading
sequence would be unreadable here.

The Admin blueprint is the only one of the four that names configuration files.
It names `indexes.conf`, `props.conf` and `transforms.conf`, and it names `btool`
and `SEDCMD`.

### Splunk Certified Cybersecurity Defense Engineer, 5 domains

| | Domain | Weight |
| --- | --- | --- |
| 1.0 | Data Engineering | 10% |
| 2.0 | Detection Engineering | 40% |
| 3.0 | Building Effective Security Processes and Programs | 20% |
| 4.0 | Automation and Efficiency | 20% |
| 5.0 | Auditing and Reporting on Security Programs | 10% |

Domain 2 covers creating and tuning detections, adding context to them,
risk-based modifiers, generating notable events, and maintaining a detection
lifecycle. Domain 4 covers automation for standard operating procedures, case
management, REST APIs, SOAR playbooks, and comparing what Enterprise Security and
SOAR each provide.

**The blueprint uses two vocabularies at once**, and this is the most useful thing
on it for anybody writing teaching material. Objective 2.1 says detections and
then names correlation searches in the same breath. Objective 2.4 says "Notable
Events/findings". Enterprise Security 8.0 and later renamed notable events to
findings and renamed risk events to intermediate findings, and split what was one
correlation search concept into event-based and finding-based detections. A
candidate arriving from documentation written before that change and a candidate
arriving from documentation written after it have different words for the same
objects. A track that teaches only one set leaves half its readers unable to
match the blueprint to what is in front of them.

## The prerequisite graph

From the candidate handbook's next-level table, which is also the recertification
upgrade path. The four exams in scope are in bold.

```
Core Certified User
        |
        v
Core Certified Power User  ------> Core Certified Advanced Power User
        |            |                         |
        |            |                         v
        |            +---------------> Cloud Certified Admin
        v
Enterprise Certified Admin ------> Enterprise Certified Architect
                                            |
                                            v
                                   Core Certified Consultant

Certified Cybersecurity Defense Analyst      (no next level)
Certified Cybersecurity Defense Engineer     (no next level)
Certified Cybersecurity Defense Architect    (no next level)
```

Two facts in that graph decide the track structure.

**The core line is a chain and Splunk enforces one link of it.** Power User is
required before Enterprise Admin. Nothing requires User before Power User, though
the Power User blueprint assumes the search skills the User blueprint tests and
never re-tests them.

**The security line is not attached to the chain at all.** None of the three
cybersecurity certifications has a next-level option, none is a prerequisite for
any other, and none appears anywhere else in the table. They are a separate
branch that recommends Power User knowledge without requiring it.

## Copyright, trademark, and what this repo may reproduce

Researched from scratch, as the build prompt requires, and the answer does not
transfer from the CompTIA position. **It is materially stricter.** This section is
not legal advice; it is a reading of Splunk's published terms, quoted so the
reasoning can be checked.

### The three documents that govern this

**Splunk Websites Terms and Conditions of Use**, effective 8 May 2024, is the one
that bites. It grants a narrow licence:

> you may (a) view any Content on any single computer solely for personal,
> informational, non-commercial purposes, and (b) download and print one (1) copy

and then prohibits essentially everything else without written authorisation:

> you may not use, download, upload, copy, print, display, perform, reproduce,
> publish, license, post, transmit, rent, lease, modify, loan, sell, distribute,
> or create derivative works based on, the Site or any Content

CompTIA's trademark guidance offers, as an approved example, a sentence describing
third-party training materials for a named certification. **Splunk publishes no
equivalent permission.** The absence is a fact about the documents; nothing here
claims to know why.

**Splunk Certification Agreement**, last modified 1 March 2026, covers exam
content rather than published material. It prohibits disclosing, publishing,
reproducing or transmitting any exam or exam-related information, and the
enumerated list includes questions, answers, screenshots, diagrams, and the length
or number of exam segments or questions. Section 4.1 binds a candidate not to
disseminate actual exam content, and not to have sought unauthorised access to
exam content or answers in preparing.

There is no equivalent of CompTIA's "reconstruction through memorization" clause
by that name, but section 2.1 reaches the same conduct: reproducing exam content
in any form by any means, for any purpose.

**Splunk Trademark Usage Guidelines**, last updated March 2023, permits referential
use and attaches conditions. Third parties may reference Splunk trademarks other
than logos and taglines to identify products and services, using the full product
name on first reference, with the trademark symbol, and carrying this legend:

> Splunk, Splunk>, and Turn Data Into Doing are trademarks or registered
> trademarks of Splunk LLC in the United States and other countries.

The prohibitions that touch this repo: no Splunk trademark in a product name or a
domain name, no logo without prior written consent, no shortening or abbreviating
a Splunk trademark, no implying sponsorship or affiliation, and the trademark must
not be the most prominent visual element.

### What the field actually does

The terms above describe permission. This describes practice, which is a different
question and was measured rather than assumed. Each page's text was diffed against
the blueprint PDF instead of being read for an impression.

| Publisher | What it is | Objectives | Disclaimer |
| --- | --- | --- | --- |
| `certfun.com` | Syllabus aggregator | 48 of 50 Enterprise Admin objectives verbatim, with domain names and weights | Disclaims affiliation with any certification provider, asserts its own copyright over the page |
| `ravikirans.com` | Personal study guide | 19 of 19 Defense Engineer objectives verbatim as section headings, each linked onward to Splunk documentation | None |
| ONLC | Training company | Redistributes Splunk's own certification study guide PDF, an older 10-page edition against Splunk's current 32 | Not applicable |
| Apress, *Splunk Certified Study Guide*, Deep Mehta, 2021 | Published book covering User, Power User and Enterprise Admin | **Does not reproduce the blueprint.** Eighteen chapters organised by subject in reading order | Not applicable |

**Verbatim reproduction is the norm among free Splunk study resources**, and no
enforcement against any of them turned up. **The one publisher in that list with
institutional legal review did not reproduce the blueprint at all**, and organised
by subject instead, which is what this site already does.

Splunk's certification team has stated its position in public. Replying on
2023-12-05 to a request for dumps, the `exam-dev-staff2` Splunk Employee account
wrote:

> Splunk dump websites are illegal representations of Splunk's intellectual
> property, which our legal team takes quite seriously. Violation of the Splunk
> Certification Exam Agreement can result in revocation of certifications and
> disqualification from any future certification exams.
>
> Blueprints for all of our exams can be found on the Training & Certification
> pages

That is the same line CompTIA draws, drawn by Splunk in public. Dumps are the
violation and the blueprints are where candidates are sent. It is not an
affirmative permission to reproduce blueprint text, and it is not nothing: it is
Splunk naming the blueprints as the material to prepare from.

That post gives `certification@splunk.com` as the contact. The candidate handbook
gives `splunk_certification@cisco.com`. Both are current on their respective pages.

### What follows for this track

Nine rules. The first is the one that differs most from the three existing tracks.

1. **Write the objective descriptions rather than reproducing Splunk's
   statements.** `src/config/exams.ts` holds a one-line description of what each
   objective asks for, in the track's own words. Objective numbers, domain titles
   and weights are exact, because those are facts and they are the join key a
   reader uses against the blueprint. Every coverage page links to the blueprint
   PDF so Splunk's own wording is one click away.

   **The main reason is that Splunk's statements do not work as coverage-page
   labels.** Eighty-two of the 157 are five words or fewer, and a page listing
   "Splunk components", "Edit reports" and "Use the timeline" tells a reader
   nothing about what to study. Lower exposure is a side benefit rather than the
   argument, given what the norm turned out to be.

   Expect convergence on the short ones. Where an objective is a bare feature name
   like "The stats command", the description will match Splunk's wording because
   there is no other way to write it, and a bare feature name is not protectable
   expression. What matters is that no page on this site is a reproduction of a
   Splunk blueprint, and the coverage page is the only place that could happen.

   This document paraphrases the objectives for the same reason.
2. **Domain titles and weights are reproduced.** A domain title is a short factual
   label and a weight is a number. Both are needed for a candidate to know what
   they booked, and neither is expressive enough to be worth an argument.
3. **Question counts, durations, prices, levels and prerequisites are facts and
   are stated with a citation.** They are also what the certification agreement
   protects when a candidate reports them from inside an exam. These come from
   Splunk's own published blueprints, so the confidentiality clause is not
   engaged.
4. **Do not quote the documentation.** State the behaviour, cite the page, pin the
   version. The existing tracks quote standards documents freely because those
   licences permit it. This one does not have that licence.
5. **A capture is not a quotation.** Output produced by running the software on
   this machine is a fact about what the software did. That is the whole argument
   for the capture toolchain, and it is stronger here than on any existing track.
6. **The track name must not read as a product name.** "Splunk certification study
   notes" is a description of content. Anything shaped like "Splunk Certification
   Course" is a product name containing a trademark.
7. **Use the full product name with the symbol on first reference on a page**, for
   example Splunk® Enterprise, and plain thereafter. Never abbreviate to a short
   form Splunk does not use.
8. **Carry the trademark legend and a disclaimer** on the track index, coverage,
   plan and practice pages, in the same place the CompTIA legend sits:

   > Splunk, Splunk>, and Turn Data Into Doing are trademarks or registered
   > trademarks of Splunk LLC in the United States and other countries. This site
   > is not affiliated with, endorsed by, or sponsored by Splunk or Cisco. All
   > practice questions are original work written from Splunk's published exam
   > blueprints.

9. **No Splunk logo anywhere.** The simplest way to comply with a written-consent
   requirement is to need no consent.

The input rules from the Linux+ authoring standard carry over unchanged and need
no restatement: never read a braindump, never write from memory of a real exam,
every distractor is a real mistake, and never label anything as actual exam
content.

## Where the documentation now lives, and the version to pin

**The primary source named in the build prompt is a redirect.** Requesting
`docs.splunk.com/Documentation/Splunk/latest/SearchReference/WhatsInThisManual`
follows two redirects and lands on
`help.splunk.com/en/splunk-enterprise/search/spl-search-reference/10.4/introduction/welcome-to-the-search-reference`.
The `docs.splunk.com/Documentation` landing page still returns 200 and still
serves content.

Both hosts return 403 to a default user agent and 200 to a browser one. That is
the same pattern already recorded for Ofcom, ISO and Cisco in the link-checker
notes, and `check-links.mjs` will need Splunk added to whatever list already
carries them.

**The new URL shape is better for this track than the old one**, because the
version is a path segment rather than the word `latest`. The build prompt's rule
to cite a pinned version rather than `latest` is now cheap to follow and cheap to
verify.

Versions offered on the Splunk Enterprise documentation as of the research date:
10.4, 10.2, 10.0, 9.4, 9.3, 9.2, 9.1 and 9.0.

| Decision | Value | Why |
| --- | --- | --- |
| Documentation version to cite | **10.4** | Newest offered, and what `latest` currently resolves to |
| Container image | **`splunk/splunk:10.4.2`** | Matches the cited documentation |
| Image digest | `sha256:22474424c789484cdeef5fd85047d3d9949ce9084908f62565df0c67acc41b61` | Manifest digest, pinned the way `distros.json` pins the Linux images |
| Platform digest | `sha256:f97629abda2ad188ff1448a085db9a7cebe15cefdec7d78aa9366b7f8cc145f0` | linux/amd64, 1828 MB |
| Enterprise Security version | **8.6** | Newest documented, and the version whose vocabulary the Defense Engineer blueprint straddles |

**Two version traps to record now.**

The Search Tutorial is no longer a Splunk Enterprise document at a single address.
Requesting the tutorial's old URL lands on the Splunk Cloud Platform copy, at
version 10.5.2605, which is a Cloud release channel number rather than an
Enterprise version. An Enterprise copy exists in parallel at 10.4. Citing the
tutorial means choosing which of the two, and saying so.

The same manual appears under more than one path. The administration manual is
served both as `splunk-enterprise/administer/admin-manual/10.4/...` and as
`data-management/splunk-enterprise-admin-manual/10.4/...`. Both resolve. A
citation should be captured once and checked rather than pattern-matched from
another one.

## Term extraction

The build prompt asks for a term extraction, and `blog/scripts/term-coverage.py`
needs a Splunk entry in its `EXAMS` map. The result is a warning about that script
rather than a list to feed it.

Distinctive technical terms named in the four blueprints, counted from the
blueprint text:

| | SPL commands named | Configuration files named | Named features |
| --- | --- | --- | --- |
| Core User | 9 | 0 | 0 |
| Power User | 8 | 0 | 3 |
| Enterprise Admin | 3 | 3 | 3 |
| Defense Engineer | 1 | 0 | 3 |

The union of SPL commands named across all four blueprints is sixteen: `btool`,
`chart`, `dedup`, `eval`, `fields`, `fillnull`, `lookup`, `rare`, `rename`,
`search`, `SEDCMD`, `sort`, `stats`, `timechart`, `top`, `where`.

**Sixteen commands is not the SPL surface these exams test, and the term-coverage
script will be actively misleading if pointed at these blueprints unmodified.**
On Linux+ and Network+ the objectives document is close to an inventory: CompTIA
names the commands, the protocols and the acronyms, and a term with no match in
the track is a real gap. Splunk's blueprints are written at a level above that.
Core User objective 4.4 names five commands explicitly and then domain 2 describes
searching in prose that names none. Defense Engineer names `search` once and
nothing else, while asking for detection engineering at 40 percent.

Two consequences.

**The Splunk term list has to be assembled rather than extracted**, from the
blueprint text plus the Search Reference command index plus the configuration file
reference, with the source of each term recorded. That is a build step this track
needs and the existing tracks did not.

**Term coverage cannot be the completeness check here.** On the CompTIA tracks a
term with no match is evidence of a hole. On this one, a term list derived from
the blueprint would report full coverage on a track that never taught
`eventstats`, `tstats`, `rex`, `spath`, `mvexpand` or subsearches, none of which
any of the four blueprints names, and several of which are unavoidable in teaching
what the blueprints do ask for. Coverage has to be checked against the objectives
themselves, one at a time.

The Advanced Power User blueprint, which is not in scope, names 88 objectives and
is close to an SPL inventory. It is the best available cross-check on whether the
track's SPL coverage is sane, and it should be used that way rather than as a
scope.

## What can be captured, and what cannot

The build prompt's position is that nearly everything runs and the hard part will
be discipline. That holds for three of the four exams and fails for the fourth.

### The container, and two constraints the plan has to absorb

`splunk/splunk` is on Docker Hub, 613 tags, actively published. `latest` was
10.4.2 on 2026-08-12.

**The image is amd64 only.** Every tag checked, from 9.4 through 10.4.2, publishes
a single `linux/amd64` image and no arm64 one. This machine is arm64. `capture.sh`
already runs amd64 images under emulation and defaults to it, so the route exists,
but a 1.8 GB emulated Splunk instance is a different proposition from an emulated
`almalinux:10`.

**The podman machine is too small.** It is currently running with 2 GiB of memory.
Splunk Enterprise will not run usefully in that, and the first job in step 7 of the
build order is resizing the machine and proving a container starts, before any
topic depends on it.

The container is podman, not docker, matching `capture.sh` and `netlab.sh`. The
build prompt's `docker run` framing should be read as shorthand.

Licence facts, from the Splunk Enterprise administration manual: installation
gives a 60-day Enterprise Trial, convertible to a Free licence at 500 MB per day.
Exceeding it produces a licence violation warning, and three warnings in a rolling
30-day window stop searching. No topic on this track will approach 500 MB a day
through ordinary ingestion.

### The datasets, and the reproducibility claim

**The Search Tutorial dataset is regenerated.** The archive at
`docs.splunk.com/images/Tutorial/tutorialdata.zip` was built at 03:30 on the
research date, and its newest events are seven days old. Downloading it tomorrow
produces different timestamps and therefore different results for any search with
a time range, which is nearly all of them.

That directly contradicts the build prompt's claim that "the same search over the
same frozen dataset reproduces exactly". It can be made true, but only by freezing
a copy, and a copy of Splunk's dataset committed to a public repository is
redistribution of Content under the terms of use quoted above. The honest options
are to keep a local unversioned copy and label captures with its checksum and
download date, or to prefer a dataset that may be redistributed.

**The Boss of the SOC datasets may be redistributed.** All three are published
under Creative Commons Zero 1.0 Universal, which is a public domain dedication.
They are also genuinely static:

| Dataset | Size | Fixed since | Integrity |
| --- | --- | --- | --- |
| BOTS v3 | 335,251,397 bytes | 2020-06-01 | MD5 published in the repository |
| BOTS v1, full | 6.1 GB compressed | published 2017 | in repository |
| BOTS v1, attack only | 135 MB compressed | published 2017 | in repository |

One line in the BOTS v3 README is worth more than its length suggests: the data is
distributed pre-indexed, so there are no volume-based licensing limits to worry
about. A pre-indexed dataset is copied into place as buckets rather than ingested,
which means a 320 MB dataset does not touch the 500 MB daily licence at all.

**One thing to test rather than assume.** BOTS v3 was built on Splunk Enterprise
7.1.7. Whether 10.4 will mount buckets written by 7.1.7 is a question for step 7,
not an assumption for step 5. If it will not, the fallback is an older pinned
image for the security captures, labelled honestly, or re-ingesting the raw data
against the licence.

### Free applications the exams name

Both are Splunk-supported, licensed under the Splunk General Terms, and support
Splunk Enterprise 10.4 and 10.5. Both need a splunk.com account to download.

| Application | Splunkbase | Needed for |
| --- | --- | --- |
| Splunk Common Information Model Add-on | app 1621 | Power User domain 10, all 10 percent of it |
| Splunk Security Essentials | app 3435 | Defense Analyst 3.3 and 5.3, and useful for Engineer |

### What cannot be captured

**Enterprise Security, which is most of the fourth exam.** Enterprise Security is
a premium application requiring a separate licence on top of Splunk Enterprise or
Splunk Cloud. Two tiers exist, ES Essentials and ES Premier. Trials are 30 days and
90 days respectively and are issued by a Splunk sales representative. There is no
free tier, no perpetual option and no self-serve download. A sandbox exists behind
a request form.

That removes the capture route for correlation searches, notable events and
findings, risk-based alerting, the analyst queue, adaptive response actions, and
the built-in dashboards. It is the single largest correction to the build prompt
and it changes what the Defense Engineer block can honestly promise.

**What survives.** The blueprint splits more usefully than "Enterprise Security or
nothing":

| Domain | Weight | Capture position |
| --- | --- | --- |
| 1.0 Data Engineering | 10% | Runs. Indexing, normalisation and the common information model are all plain Splunk Enterprise |
| 2.0 Detection Engineering | 40% | Detection logic runs against BOTS data on plain Splunk. The correlation search wrapper, risk modifiers and findings do not |
| 3.0 Security Processes and Programs | 20% | Documented only, and conceptual on the blueprint too |
| 4.0 Automation and Efficiency | 20% | REST API runs. SOAR needs its own trial |
| 5.0 Auditing and Reporting | 10% | Runs. Dashboards and metrics are plain Splunk Enterprise |

**Decided 2026-08-25: run the detection logic, document the Enterprise Security
wrapper.** No trial is being pursued and the block carries no schedule dependency
on one.

`splunk/security_content` is Apache-2.0 licensed, was last pushed on the research
date, and holds Splunk's own detection definitions as SPL. That is the route to
making domain 2 real without Enterprise Security: the detection logic is openly
licensed, it can be run against a CC0 dataset, and the output is a capture.
Everything that is specifically an Enterprise Security object has to be sourced
from documentation and labelled as such, exactly the way the Network+ track
handled a vendor CLI it could not run.

The honesty rule that comes with it, and it should be in the teaching design as
well as here: **a topic never implies that a documented Enterprise Security
behaviour was observed.** The per-topic provenance line carries the distinction the
way it already does on the other tracks, and the split inside a single topic is
between the search, which ran, and the object that would wrap it, which did not.

**Also out of reach**, and worth stating so nobody plans against it: real indexer
clustering and search head clustering, licence manager behaviour at scale,
deployment server against a real fleet, and anything about performance at volume.
Distributed search at 10 percent of the Admin exam can be shown in a small
multi-container topology, which is a `netlab.sh`-shaped problem rather than a
`capture.sh`-shaped one.

### What the wrong answer route buys

The build prompt proposes capturing distractors: SPL that runs and returns the
wrong thing. Nothing blocks it, and the container makes it nearly free once the
tooling exists. It should be a first-class mode in `splunk.sh` rather than
something done by hand, because the value depends on the wrong output being real,
and a hand-run wrong answer is exactly the thing that gets retyped and invented.

## The overlap audit

The build prompt asks for two measurements: between the four blueprints, because
it decides the track structure, and against the existing 164 topics.

### Between the four blueprints

Objective vocabulary from each blueprint, stopwords and instruction verbs removed,
compared pairwise. Jaccard similarity, and the count of shared terms.

| | Core User | Power User | Enterprise Admin | Defense Analyst | Defense Engineer |
| --- | --- | --- | --- | --- | --- |
| **Core User** | | 12.5%, 12 | 6.6%, 10 | 2.1%, 4 | 3.4%, 4 |
| **Power User** | | | 4.9%, 7 | 5.2%, 9 | 3.7%, 4 |
| **Enterprise Admin** | | | | 2.6%, 6 | 3.1%, 5 |
| **Defense Analyst** | | | | | 7.7%, 14 |

**The blueprints barely intersect, and most of the shared terms are not subject
matter.** The largest overlap, Core User against Power User, is twelve terms:
add, command, commands, events, fields, report, results, search, splunk, stats,
time, uses. The Admin against Engineer overlap is five: data, optimize, search,
splunk, validate. Those are the words any two documents about the same product
share.

**One pair is different, and it is the pair that justified adding a fifth exam.**
Defense Analyst against Defense Engineer shares fourteen terms and every one of
them is substantive: analysis, analytics, based, dashboards, data, detection,
enterprise, management, notable, risk, security, soar, splunk, threat. That is two
documents about the same subject at two levels, which is what none of the other
nine pairs are. Defense Analyst also shares nine with Power User, including eval,
event, action and data, and only four with Core User. It sits where the
[fifth exam](#the-fifth-exam-and-the-sixth) section said it does: between the core
line and the security line, closer to both than they are to each other.

**That number is a lower bound and taking it at face value would be the mistake
this audit exists to prevent.** Vocabulary overlap measures whether two blueprints
use the same words. It does not measure whether one assumes the other. Reading the
objectives against each other, the real relationship is different in kind:

| Concept | Where it is tested | Relationship |
| --- | --- | --- |
| `stats` | Core User 5.3, Power User 3.6 | Power User tests choosing it over transactions. It never re-tests what it does |
| Fields | Core User 3.0 at 20%, Power User 4.0 and 5.0 | Core User tests using extracted fields. Power User tests creating them |
| Data models | Power User 9.0 | Named nowhere else in the four, and assumed by the common information model domain next to it |
| Common information model | Power User 10.0, Engineer 1.3 | Same subject, no shared vocabulary. Engineer calls it normalisation |
| Field extraction | Power User 4.0, Admin 16.0 and 17.0 | The same operation at opposite ends of the pipeline, and the exams never say so |
| Dashboards | Core User 6.0, Engineer 5.3 | Engineer assumes the Core User skill entirely |
| Search pipeline | Core User 4.2 | Assumed by all three others, tested by one |

**The overlap is prerequisite-shaped, not content-shaped.** Four disjoint
objective sets sitting on one shared foundation, where each exam tests its own
layer and silently assumes the ones underneath. That is a different problem from
the one the build prompt anticipated, and it points at a different answer.

The one place the exams themselves confirm it: Power User is a required
prerequisite for Enterprise Admin, and the Admin blueprint tests none of the Power
User material.

### Against the existing topics

Measured across all 172 topic files in `src/content/learn`, 967,762 words. The
build prompt's figure of 164 is stale; the Security+ block B topics have landed
since it was written.

| Track | Topics | Words |
| --- | --- | --- |
| Linux+ | 81 | 503,100 |
| Network+ | 83 | 424,735 |
| Security+ | 7 of a planned 77 | 38,216 |
| Bicep | 1 | 1,711 |

Searching for the terms that would indicate genuine collision, SIEM, log
aggregation, centralised logging and Splunk itself:

| Topic | Words | What it already carries |
| --- | --- | --- |
| `network-plus/40-baselines-alerting-and-monitoring-solutions` | 6,770 | The only substantial treatment. Defines SIEM against a syslog server, correlation as the distinguishing feature, and a named pitfall about confusing the two |
| `linux-plus/39-logging-and-auditing` | 9,545 | syslog, journald, log formats, audit |
| `linux-plus/65-reading-logs-to-find-a-cause` | 5,496 | Method for reading logs to a conclusion |
| `linux-plus/53-scripts-that-do-real-work` | 6,091 | One passing mention |

**The word "Splunk" appears zero times in 967,762 words of existing content**, and
none of the seven written Security+ topics names SIEM either.

**Measured against what exists, this is the smallest overlap of any track added to
this site.** Network+ collided with nine Linux+ topics and accepted roughly 40,000
words of it. Security+ collided with forty topics and 250,744 words. Splunk
collides with four topics and roughly 28,000 words, only one of which is really
about the subject.

**Measured against what is planned, that number is wrong, and this is the finding
that matters.** Security+ has 7 of 77 topics written. Its plan declares objective
4.9 across four topics that read logs, and three of the four are on ground this
track has to cover:

| Planned Security+ topic | What its plan row promises | Collision |
| --- | --- | --- |
| 23 | Correlates three sources onto one timeline | The reason correlation needs normalised time and a common field name |
| 48 | Follows one alert from fire to disposition | Defense Engineer 2.4 and the analyst queue, arrived at from the other side |
| 49 `the-monitoring-tools` | One real syslog line at each stage from raw to parsed to enriched to correlated to alert | **Nearly the same figure as the Splunk data pipeline diagram** the build prompt asks for |
| 61 | Acquisition and the order of volatility | Little collision. Different subject |

Topic 49's figure argument and the Splunk track's first proposed figure are the
same drawing with different labels. Neither is written yet, which is the only
reason this is a decision rather than a repair.

**The rule, decided now rather than at topic forty.** The two figures divide by
which question they answer, the same way the three existing tracks divide:

- **Security+ asks what a SIEM adds at each stage**, and its answer is
  vendor-neutral: parsing adds structure, enrichment adds context, correlation
  adds the thing no single line contains. The line is syslog because syslog is
  what every product ingests.
- **Splunk asks where each decision becomes irreversible**, which is a different
  drawing: the same event through input, parsing and indexing, marking the point
  after which a sourcetype cannot be changed without re-indexing, and the point
  after which a field can still be added for free.

The second is not a vendor version of the first. It is the question a
vendor-neutral treatment cannot ask, because irreversibility is a property of a
specific product's pipeline. If the Splunk figure ends up teaching what parsing
adds, it has drifted into topic 49 and should be redrawn.

Whichever track reaches its topic first writes it, and the other links to it. That
ordering is not knowable yet, so the check belongs in both plan rows in bold,
which is where the Network+ scope-drift rule put it.

The Network+ rule applies unchanged and costs almost nothing: write self-contained,
link at the foot. Three see-also links, and they are all worth making in both
directions:

| Splunk topic | Links to | Why |
| --- | --- | --- |
| Whatever teaches the search pipeline | `linux-plus/19-shell-redirection-and-pipes` | The reader who already has the pipe model needs to be told this one is different, because SPL pipes rows rather than bytes and the difference is where beginners come unstuck |
| Whatever teaches data sources | `linux-plus/39-logging-and-auditing` | Where the events come from before Splunk sees them |
| Whatever teaches detection and correlation | `network-plus/40-baselines-alerting-and-monitoring-solutions` | Already defines SIEM correlation vendor-neutrally, and already uses "finding" for a correlated result |

The third one is a small gift. A vendor-neutral definition of what correlation is
for, written without Splunk in view, is the right thing to hand a reader before
teaching them the vendor's version.

Three more links become available when Security+ block D and block E land, and
they should be added then rather than promised now: topics 23, 48 and 49 above.
Links go both ways, which neither existing track does today and both should.

## The structure decision

The build prompt lists four options and rules that none may be picked without
measuring the overlap first. The overlap has been measured.

**Decision: one track, five exams, with per-topic exam mapping.** Option two from
the build prompt's list, with the fourth option's mechanism inside it.

The measurement that decides it is not the 2 to 12 percent vocabulary overlap; on
its own that argues for separate tracks. It is what the overlap turned out to be
made of. Exams that assume each other and never re-test each other is precisely the
case where separate tracks fail, because each track after the first would have to
either repeat the foundation or start in mid-air, and the exams give no guidance on
which because they simply do not mention it.

Separate tracks priced honestly:

| Cost | Detail |
| --- | --- |
| Five track cards, five coverage pages, five plan pages | Five entries in `TRACK_META`, no code change |
| The foundation written five times or four times omitted | Search pipeline, fields, time ranges and the index-time against search-time split are assumed by every blueprint and tested by one |
| No reading order across the progression | Which is how somebody actually learns this, and the one thing this site can offer that Splunk's own learning paths do not |
| A reader on the Admin track cannot see that Splunk requires Power User first | The prerequisite is real and enforced at booking |
| The Analyst and Engineer split lands badly | They share fourteen substantive terms. Two tracks would duplicate the risk and detection vocabulary or leave one of them assuming it |

One synthetic exam is rejected for the reason the build prompt already gives, which
survives contact with the blueprints: a reader cannot tell which pages are on the
exam they booked, and with weights this different between the four, a merged
blueprint would misreport every one of them.

### What the platform has to change

`EXAM_FOR_TRACK` in `src/config/exams.ts` is `Record<string, string>` and
everything downstream assumes one exam per track. The change is one-to-many, and
the consumers to follow are `STRICT_TRACKS` in `quiz-validate.ts`, the coverage,
plan and exam routes, and `weightedShares`.

The smallest change that works, and it is worth stating precisely because the
build prompt leaves it open: **make the value `string | string[]` and normalise on
read**. Every existing track keeps its current entry untouched, `examFor` gains a
sibling `examsFor` that always returns an array, and the three routes build one
page per exam for a track that has several. That is additive rather than a
migration, which matters given three finished tracks depend on the current shape.

Per-topic mapping is the second half. A topic already declares objectives in
frontmatter; it gains the exam each objective belongs to. That gives the coverage
page per exam for free, gives the reader a filter, and gives `quiz-validate.ts`
something to check a question's `learnRef` against.

The `hidden` flag now exists in `src/config/tracks.ts` and the track carries it
from the first commit.

### Scale, stated honestly

The build prompt asks for the estimate, because the Security+ plan's estimate is
what made its authoring order defensible.

Observed cost of a finished track on this site:

| | Topics | Words | Words per topic |
| --- | --- | --- | --- |
| Linux+ | 81 | 503,101 | 6,211 |
| Network+ | 83 | 424,736 | 5,117 |
| Mean | | | 5,664 |

Estimating topics from objective count and weight concentration, not from domain
count, because the Admin blueprint's seventeen domains are not seventeen topics:

| Block | Exam | Topics | Words |
| --- | --- | --- | --- |
| Foundation | shared | 6 | 34,000 |
| A | Core User | 18 | 102,000 |
| B | Power User | 17 | 96,000 |
| C | Enterprise Admin | 26 | 147,000 |
| D | Defense Analyst | 14 | 79,000 |
| E | Defense Engineer | 18 | 102,000 |
| | | **99** | **560,000** |

**Roughly 99 topics and 560,000 words.** That is larger than any finished track on
this site: Linux+ plus a further 11 percent, or Network+ plus a third again.

Two things keep the number honest rather than alarming. The estimate is far lower
than a naive five-times-a-track figure and higher than a single track, which is
what the prerequisite-shaped overlap predicts: the foundation is written once and
each exam's own objectives are written in full. And blocks A to C are a shippable
track on their own, at 67 topics and 379,000 words, covering the three exams
Splunk chains together. If the security blocks slip, what exists is coherent
rather than truncated.

Block D precedes block E because Analyst is Intermediate level to Engineer's
Professional, and because the Engineer blueprint's preparation list begins by
referring to the Analyst course list.

## Resources worth using, measured

Measured the way Professor Messer was measured for the Security+ track: as a
coverage benchmark and as a signal of what a reader already believes when they
arrive. **None of these is an input to write from.** Every topic and every question
comes from the blueprint and the primary documentation.

| Resource | What it is | Use |
| --- | --- | --- |
| `help.splunk.com` | The product documentation, versioned per release | The primary source. Cite pinned, never `latest` |
| Splunk Lantern | Splunk's customer success centre, published by Splunk, © 2005-2026 Splunk LLC | Named in the Defense Analyst blueprint at 5.3, so it is examinable that it exists. Use as a coverage check on use cases |
| `splunk/security_content` | Splunk's detection library, Apache-2.0, actively maintained | The only openly licensed source of real detection SPL. Runnable, which makes it a capture route rather than a reading reference |
| `splunk/attack_range` | Attack simulation environment, Apache-2.0 | A way to generate data for detections that BOTS does not cover. Heavy, and probably out of scope |
| BOTS v1 and v3 | CC0 datasets, static, pre-indexed | The capture foundation for the security material |
| Splunk free courses | 40+ free courses on the training site, registration required | The coverage benchmark. Several are named directly in the blueprints' preparation lists |
| Splunk Community | Forum and blogs | Where the exam codes are corroborated. Cloudflare-protected, so not fetchable by the link checker |
| Splunk Certification Exams Study Guide | Splunk's own study guide PDF, © 2023 Splunk Inc., 32 pages | Carries sample questions, which makes it the one document to read for question shape rather than content |

**The free courses are the sharpest benchmark**, because the blueprints name them.
Core User's preparation list names Intro to Splunk, Using Fields, Scheduling
Reports and Alerts, Visualizations, Working with Time, Statistical Processing,
Leveraging Lookups and Subsearches, and Search Optimization. Several of those are
on the free list. A reader who has done the free courses arrives knowing the
interface and not the pipeline, which is a specific gap this track can aim at.

Two things worth noting about what is not here. There is no Splunk equivalent of
the five free subnetting generators that decided the Network+ drill question, so
the SPL practice decision is genuinely open rather than settled by what already
exists. And the Splunk Academic Alliance provides free training and certification
to students and faculty at participating institutions, which is worth a sentence
on the track's start page for readers who qualify.

## What this changes about the build prompt

Collected, so the teaching design and the topic plan are written against the
corrected version rather than the original.

| Build prompt says | Corrected to |
| --- | --- |
| Four exams, believed independent | Enterprise Admin requires Power User. The security line is a separate branch with no next level |
| A fifth may exist | Defense Analyst exists and is not a prerequisite. A sixth exists. Covering Engineer without Analyst leaves a gap |
| Primary source is `docs.splunk.com/Documentation` | Manual pages redirect to `help.splunk.com`, which carries the version in the path. Both need a browser user agent |
| Enterprise Security may be licensable | It is not. Sales-issued trials only. 40 percent of the fourth exam loses its capture route and gains an openly licensed substitute |
| The same search over the same frozen dataset reproduces exactly | Only if the dataset is frozen locally. The tutorial data is regenerated daily. BOTS is CC0 and static |
| Splunk runs free in a container | It does, amd64 only, on a podman machine that currently has 2 GiB and needs more |
| The comparison axis is Splunk Enterprise against Splunk Cloud | Not supported by these four blueprints. Enterprise Admin names Splunk Cloud zero times. See below |
| Reproduce blueprint objective statements, never sub-bullets | Reproduce numbers, weights and domain titles. Write the objective descriptions. Splunk's blueprints have no sub-bullets to exclude |
| Four exams | Five. Defense Analyst is in scope, as block D |
| Term coverage per block, using the committed script | The script needs an assembled term list, not an extracted one, and cannot be the completeness check here |

**On the comparison axis specifically.** The build prompt proposes Splunk
Enterprise against Splunk Cloud as the recurring `COMPARE_META` table and calls it
examinable. It is examinable, on the Splunk Cloud Certified Admin exam, whose
objective 1.3 is exactly that comparison. Across the four exams in scope, Splunk
Cloud is named once, in the Defense Engineer blueprint, and the Enterprise Admin
blueprint does not name it at all.

The axis that does recur across all four is **index time against search time**. It
is the central decision in the Splunk data model, it is where the irreversible
choices live, and every one of the four exams tests part of it: Core User uses
fields extracted at search time, Power User creates them, Admin configures the
index-time transforms, Engineer normalises across both. A table with the columns
"at index time", "at search time", "decided by" and "cost of changing it later"
recurs genuinely and teaches the thing this product is hardest to learn. Proposed
heading, satisfying the integration's requirement that it begin with "Across":
**Across index time and search time**.

## Sources

Every URL checked on 2026-08-25. Where a browser user agent was required, that is
noted.

| Claim | Source | URL |
| --- | --- | --- |
| The fourteen certifications, legacy markers, Cisco note | Splunk Certifications | https://www.splunk.com/en_us/training/certification.html |
| Certification skills and products, per certification | Splunk certification tracks | https://www.splunk.com/en_us/training/certification-track.html |
| Core User: 60 questions, 60 minutes, entry level, no prerequisite, 8 domains and weights | Splunk Test Blueprint, User | https://www.splunk.com/content/dam/splunk2/en_us/pdfs/training/splunk-test-blueprint-user.pdf |
| Power User: 65 questions, 60 minutes, entry level, no prerequisite, 10 domains and weights | Splunk Test Blueprint, Power User | https://www.splunk.com/content/dam/splunk2/en_us/pdfs/training/splunk-test-blueprint-power-user.pdf |
| Enterprise Admin: 56 questions, 60 minutes, professional level, Power User prerequisite, 17 domains and weights | Splunk Test Blueprint, Enterprise Admin | https://www.splunk.com/content/dam/splunk2/en_us/pdfs/training/splunk-test-blueprint-enterprise-admin.pdf |
| Defense Engineer: 60 questions, 75 minutes, professional level, no prerequisite, 5 domains and weights, dual vocabulary | Splunk Test Blueprint, Cybersecurity Defense Engineer | https://www.splunk.com/content/dam/splunk2/en_us/pdfs/training/splunk-test-blueprint-cybersecurity-defense-engineer.pdf |
| Defense Analyst: 66 questions, 75 minutes, intermediate, no prerequisite, SPL domain at 20% | Splunk Test Blueprint, Cybersecurity Defense Analyst | https://www.splunk.com/content/dam/splunk2/en_us/pdfs/training/splunk-test-blueprint-cybersecurity-defense-analyst.pdf |
| Defense Architect: 67 questions, expert level, five to seven years | Splunk Test Blueprint, Cybersecurity Defense Architect | https://www.splunk.com/content/dam/splunk2/en_us/pdfs/training/splunk-test-blueprint-cybersecurity-defense-architect.pdf |
| Advanced Power User: 70 questions, 22 domains, Power User prerequisite | Splunk Test Blueprint, Advanced Power User | https://www.splunk.com/content/dam/splunk2/en_us/pdfs/training/splunk-test-blueprint-advanced-power-user.pdf |
| Cloud Admin: Enterprise against Cloud is objective 1.3, Power User prerequisite | Splunk Test Blueprint, Cloud Admin | https://www.splunk.com/content/dam/splunk2/en_us/pdfs/training/splunk-test-blueprint-cloud-admin.pdf |
| Three-year lifecycle, 90-day grace, next-level table, prices, Cisco contact | Splunk Certification Candidate Handbook | https://www.splunk.com/content/dam/splunk2/en_us/pdfs/training/splunk-certification-candidate-handbook.pdf |
| Exam confidentiality, intellectual property, candidate code of conduct, last modified 1 March 2026 | Splunk Certification Agreement | https://www.splunk.com/en_us/pdfs/training/splunk-certification-exam-agreement.pdf |
| Legacy category from 1 January 2026, recertification change from 1 March 2026 | Upcoming Splunk Certification Changes FAQ. Publicly served, carries a Cisco Confidential footer. Nothing here rests on it | https://www.splunk.com/en_us/pdfs/training/splunk-certification-changes.pdf |
| Licence grant and reproduction prohibition, effective 8 May 2024 | Splunk Websites Terms and Conditions of Use | https://www.splunk.com/en_us/legal/terms/terms-of-use.html |
| Referential use, required legend, prohibitions, Splunk LLC, March 2023 | Splunk Trademark Usage Guidelines | https://www.splunk.com/en_us/legal/trademark-usage-guidelines.html |
| Documentation definition and use restrictions, May 2026 | Splunk General Terms | https://www.splunk.com/en_us/legal/splunk-general-terms.html |
| Search Reference at 10.4 after redirect. Browser user agent required | Splunk Enterprise, Search Reference | https://help.splunk.com/en/splunk-enterprise/search/spl-search-reference/10.4/introduction/welcome-to-the-search-reference |
| 60-day Enterprise Trial, 500 MB per day Free licence, three warnings in 30 days | Splunk Enterprise, About Splunk Free | https://help.splunk.com/en/splunk-enterprise/administer/admin-manual/10.4/configure-splunk-licenses/about-splunk-free |
| ES Essentials and ES Premier, 30-day and 90-day trials from a sales representative, no free tier | Licensing for Splunk Enterprise Security 8.6 | https://help.splunk.com/en/splunk-enterprise-security-8/user-guide/8.6/introduction/licensing-for-splunk-enterprise-security |
| Findings replace notable events in ES 8.0 and later | Splunk Enterprise Security, findings | https://help.splunk.com/en/splunk-enterprise-security-8/administer/8.0/findings/monitor-your-security-operations-center-with-findings-in-splunk-enterprise-security |
| Tutorial data location and prerequisites, at 10.4 | Splunk Enterprise, Search Tutorial | https://help.splunk.com/en/splunk-enterprise/get-started/search-tutorial/10.4/part-1-getting-started/what-you-need-for-this-tutorial |
| Tutorial archive regenerated daily | Tutorial dataset | https://docs.splunk.com/images/Tutorial/tutorialdata.zip |
| 613 tags, `latest` is 10.4.2, amd64 only, digests | Docker Hub, splunk/splunk | https://hub.docker.com/r/splunk/splunk |
| Required environment variables for a standalone container | docker-splunk setup | https://splunk.github.io/docker-splunk/SETUP.html |
| CC0 licence, 320 MB pre-indexed, MD5, no volume licensing impact | Boss of the SOC v3 | https://github.com/splunk/botsv3 |
| CC0 licence, full and attack-only archives | Boss of the SOC v1 | https://github.com/splunk/botsv1 |
| Apache-2.0 detection library | Splunk Security Content | https://github.com/splunk/security_content |
| Common Information Model add-on, Splunk supported, 10.4 and 10.5 | Splunkbase app 1621 | https://splunkbase.splunk.com/app/1621 |
| Splunk Security Essentials, Splunk supported | Splunkbase app 3435 | https://splunkbase.splunk.com/app/3435 |
| 40+ free courses, registration required | Splunk free training courses | https://www.splunk.com/en_us/training/free-courses/overview.html |
| Free training and certification for students and faculty | Splunk Academic Alliance | https://www.splunk.com/en_us/resources/splunk-academic-alliance.html |
| Sample questions, © 2023 Splunk Inc. | Splunk Certification Exams Study Guide | https://www.splunk.com/en_us/pdfs/training/splunk-certification-exams-study-guide.pdf |
| Splunk publishes no exam codes; codes come from the Pearson catalogue | Pearson VUE, Splunk | https://www.pearsonvue.com/us/en/splunk.html |
| Publisher and copyright of Splunk Lantern | Splunk Lantern | https://lantern.splunk.com/ |
| Splunk certification team on dumps against blueprints, 2023-12-05. Cloudflare-protected, read in a browser | Splunk Community, Training and Certification | https://community.splunk.com/t5/Training-Certification/Help-with-blueprint-and-samples-questions-of-power-user-and/m-p/670793 |
| 48 of 50 Admin objectives verbatim, affiliation disclaimer, own copyright claim | CertFun, Splunk Enterprise Admin syllabus | https://www.certfun.com/splunk/splunk-enterprise-admin-exam-syllabus |
| 19 of 19 Defense Engineer objectives verbatim, no disclaimer | Ravikiran Srinivasulu, Defense Engineer study guide | https://ravikirans.com/splunk-certified-cybersecurity-defense-engineer-study-guide/ |
| Eighteen chapters by subject, no blueprint reproduction | Deep Mehta, *Splunk Certified Study Guide*, Apress, 2021 | https://link.springer.com/book/10.1007/978-1-4842-6669-4 |
| Third-party redistribution of Splunk's own study guide PDF | ONLC | https://www.onlc.com/splunk-exam/Splunk-Certification-Exams-Study-Guide.pdf |

**This document is not legal advice.** The copyright and trademark section is a
reading of Splunk's published terms, quoted so the reasoning can be checked. If a
question arises about whether specific material is acceptable, the certification
programme's published contact is `splunk_certification@cisco.com`.
