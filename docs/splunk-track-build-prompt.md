# Prompt: build the Splunk certification track

Hand this to a fresh session. It carries what three finished certification tracks
taught, and it names the places where Splunk is a different problem from CompTIA
rather than the same problem with different words.

**Unlike the Security+ brief this is modelled on, the pre-work in here has not
been done.** Nothing below is a verified number. The exam table is what one
session believed on 2026-08-24 without checking, and it is in the document to
give the research a starting shape, not to be built on. Step 1 is to confirm or
correct every cell of it, and to say in the research document which cells moved.

The eight URLs in [Sources to start from](#sources-to-start-from) did return 200
on 2026-08-24. That is the only checked fact in this file.

## The task

Build a Splunk track covering four certifications, to the standard the Linux+,
Network+ and Security+ tracks already set: topics written in reading order with
exam objectives mapped in, captured output rather than invented transcripts,
cited primary sources, per-domain question banks that link back to the material,
and a verification pass at the end that executes or re-checks every claim.

The four exams, believed and unverified:

| Certification | Believed code | Believed audience |
| --- | --- | --- |
| Splunk Core Certified User | SPLK-1001 | Somebody who has never run a search |
| Splunk Core Certified Power User | SPLK-1002 | Builds knowledge objects for other people |
| Splunk Enterprise Certified Admin | SPLK-1003 | Runs the platform |
| Splunk Certified Cybersecurity Defense Engineer | SPLK-5002 | Builds detections in Enterprise Security |

There is believed to be a fifth, Cybersecurity Defense Analyst, adjacent to the
last one. Find out whether it exists, whether it is a prerequisite, and whether
the four above are still the four, because **Splunk's certification programme has
been through a Cisco acquisition and at least one restructure**, and a track
built against a retired blueprint is wasted work. Check the retirement position
for each exam before writing anything, the way the Security+ track checked for
SY0-801 on the CDN.

## Read these first, and treat them as binding

| Document | What it governs |
| --- | --- |
| `docs/linux-plus-teaching-design.md` | Audience, progressive disclosure, concrete before abstract, voice, the nine design decisions |
| `docs/network-plus-teaching-design.md` | Everything the Linux+ document got wrong for a second track: Prove it, Try it, cross-track duplication, triggered platform tables, diagram rules, how claims are worded, photographs, question shape |
| `docs/security-plus-teaching-design.md` | Everything the first two got wrong for a third: testing a thesis instead of adopting one, the overlap audit as a table, the figure floor, the attack rule, term coverage per block |
| `docs/network-plus-topic-plan.md` | The topic template, the balance check, capture feasibility, bank sizing, authoring order |
| `docs/security-plus-topic-plan.md` | The same, one iteration better, including the figure-argument column |
| `docs/linux-plus-question-authoring-standard.md` | Question input rules, copyright, trademark, prohibited inputs |
| `~/.claude/CLAUDE.md` | No em dashes. No attribution trailers. Commit and PR text in Ryan's voice |

**The Security+ design document is the one to read most carefully**, because it
is the third iteration and it records which of the first two documents' rules
turned out to be general and which were Linux-shaped or Network-shaped all along.

Rules that carry over without argument, so nobody relitigates them:

- Never attribute intent to a vendor or a standards body. Say what a document
  contains and what it omits.
- Never cite your own research process. Name the document or state the thing.
- A capture is real or it is not in the track. No invented transcripts, ever.
- Reproduce exam blueprint numbers and objective statements. Never the sub-bullet
  text, and check whether Splunk's terms even permit the statements.
- Refer to other topics by number in prose. Name a topic only where the name is
  doing work, which is mostly cross-track see-also links.
- Never reference a topic by its position. The reading order will change.
- A photograph needs a licence that permits display, a local file, and an entry
  in `images/credits.json`. Attribution is not a licence.
- Every capture is inserted into a topic programmatically from a file and then
  verified byte for byte. Retyping one shipped a fake transcript once already.

## What is different about this, and it is a lot

Six things, and each one changes the plan rather than decorating it. Expect the
usual failure: the previous track's shape will look like it fits, and several of
those fits will be wrong in ways that only show up at topic forty.

### 1. Four exams, and the platform assumes one

This is the largest structural difference and it is an infrastructure decision
before it is a teaching one.

`EXAM_FOR_TRACK` in `src/config/exams.ts` is a `Record<string, string>`: one exam
per track. Everything downstream assumes it. `STRICT_TRACKS` in
`quiz-validate.ts` derives from it. The coverage, plan and exam routes each build
one page per track from one exam. `weightedShares` samples one exam's domains.

Four options, and the answer decides the whole shape:

- **Four tracks.** `splunk-core-user`, `splunk-power-user`, `splunk-admin`,
  `splunk-cyber-defense`. Nothing in the platform changes. Costs: four track
  cards, four coverage pages, and enormous duplication, because Power User
  assumes User and Admin assumes both.
- **One track, four exams.** Needs `EXAM_FOR_TRACK` to become one-to-many and
  every consumer to follow. Buys one reading order across the whole progression,
  which is how somebody actually learns this.
- **One track, one synthetic exam** made of all four blueprints. Cheapest and
  dishonest, because a reader cannot tell which pages are on the exam they booked.
- **One track plus per-exam filtering** on the existing pages, with each topic
  declaring which exams it serves.

**Do not pick one from this list without measuring the overlap first.** The
Security+ overlap audit is the model: measure it, put it in a table, and let the
number decide. If Power User genuinely reuses eighty percent of User, four tracks
is absurd. If the four blueprints barely intersect, four tracks is obvious.

Whichever wins, **the `hidden` flag in `src/config/tracks.ts` exists now** and the
track should carry it from the first commit, so nothing half-written is on the
public site. That flag also keeps it out of the sitemap, out of search and marks
every page noindex, so it is genuinely safe to build in the open.

### 2. Nearly everything runs, which inverts the Security+ problem

Security+ was three quarters conceptual and the hard part was finding anything to
capture. Splunk is the opposite and the hard part will be discipline.

**Splunk Enterprise runs free in a container**, at a 500MB per day index volume
that no topic on this track will approach. `splunk/splunk` is on Docker Hub.
Splunk ships a tutorial dataset, and the Boss of the SOC datasets exist for
security content. So a search in a topic can be a search that was actually run,
against data the reader can load, returning results that are in the page.

That is a stronger position than any existing track has, and it is worth stating
as the standard rather than as an aspiration: **if a topic shows SPL, the SPL was
run and the output is what came back.** No hand-written result tables.

It needs new tooling, a sibling to `capture.sh` and `netlab.sh` rather than a mode
inside either, because the mental model is different again. Something like
`splunk.sh`, which:

- starts a Splunk container pinned by digest, the way `distros.json` pins the four
  Linux images
- loads a named dataset, itself pinned and checksummed
- runs a search and emits a paste-ready block labelled with the Splunk version and
  the dataset
- tears down, so the same command tomorrow gives the same answer

**Reproducibility here is better than netlab and worth claiming.** A namespace
capture reproduces except for kernel interface indices. The same search over the
same frozen dataset reproduces exactly, so a reader can check the numbers on the
page rather than trust them. Build the tooling before the topics, exactly as
Linux+ and Network+ did, because a topic written before the capture tooling exists
gets written from memory.

What will not run: anything needing a distributed deployment with real indexer
clustering and search head clustering, licence-manager behaviour at scale,
Enterprise Security if its licence does not permit it, and anything about
performance at volume. Check what Enterprise Security actually requires before
planning the fourth exam's captures, because that is the single biggest unknown
in this whole plan.

### 3. SPL is the subnetting of this track, and it is a whole language

Network+ ruled: do not build a subnetting generator, five free ones exist, teach
one method to fluency and enforce a distractor rule instead. The equivalent
question here is larger, because SPL is not one procedure, it is a language with
a pipeline model, and it is most of two of the four exams.

Three things to decide, and the Network+ ruling is the precedent rather than the
answer:

**Whether to build any drill.** Probably not, on the same reasoning, but check
what free SPL practice actually exists before ruling, because the Network+
decision rested on five specific generators being better than anything we would
build.

**How the distractor rule translates.** The Network+ rule was that every objective
1.7 distractor is the product of a named arithmetic error. The SPL version is
stronger and more useful: **every distractor is real SPL that runs and returns the
wrong thing for a nameable reason.** `stats` where `eventstats` was needed, a
missing `by` clause, `where` against `search`, a time range that silently excludes
the events, a field that does not exist at that point in the pipeline. Every one
of those is a mistake somebody has actually made, and the explanation names it.
This is the single most valuable thing this track can do that no other Splunk
resource does, because it is only possible if you run the wrong answer too.

**Whether the wrong answers get captured.** They should. A distractor that returns
zero results, or a plausible number that is wrong, is worth showing. That is a new
capture category and the tooling should support it.

### 4. The failure mode is a search that looks right

Each existing track has one sentence it is organised around:

- Linux+ teaches you to change a system and prove the change took.
- Network+ teaches you to read a network you did not build and prove what it is
  doing.
- Security+ teaches you to pick the right one from a set of things that are all
  real, and to say what the rejected ones cost.

**A candidate for this track, offered to be tested rather than adopted:**

> Splunk teaches you to turn a question into a search, and to know what the search
> left out. Every topic ends in a result somebody could act on, and says what
> would have to be true for that result to be wrong.

The argument for it is that Splunk's characteristic failure is not an error
message. It is a search that returns a number, plausibly, promptly, and wrongly:
the wrong time range, the wrong index, a sourcetype whose fields never extracted,
`stats` collapsing the rows you needed, a subsearch silently truncated at its
limit. A dashboard built on that is confidently wrong for months. Nothing about
that is visible from the output, which is exactly the shape the CompTIA tracks
kept finding and is much sharper here.

**Test it against the four blueprints before committing**, the way the Security+
thesis was tested and half rejected. It may hold for User and Power User and fail
for Admin, where the subject is a platform rather than a question. If it does,
widen it rather than replacing it, and say in the teaching design what the
widening was.

### 5. It is a vendor certification, which inverts several rules

Three of the existing rules exist because CompTIA is vendor-neutral, and they
flip:

**The comparison table.** Linux+ compares RHEL against Debian, Network+ compares a
vendor CLI against Linux against Windows. There is one Splunk, so neither axis
exists. The recurring axis that does exist is **Splunk Enterprise against Splunk
Cloud**, and it is examinable: what an admin can do on one and cannot on the
other, where configuration files live or do not, what is managed for you. That is
a real four-column table and probably the right `COMPARE_META` entry, with a
heading beginning "Across" as the integration requires. Consider a third column
for the deployment topology where it differs. Confirm the axis against the Admin
blueprint before building it.

**The copyright and trademark position has to be researched from scratch.** The
existing standard is a reading of CompTIA's candidate agreement, unauthorised
materials policy, educator policy and trademark guidance. Splunk has its own, and
Cisco now owns Splunk, so there may be two. Find and read: the certification
candidate agreement, the documentation's own terms of use, and the trademark
guidelines. Answer specifically whether objective statements from a blueprint may
be reproduced, whether documentation may be quoted and at what length, and what
the product name may be called in a track title. Do not assume the CompTIA
answers transfer.

**"Never present an invented vendor transcript" gets easier and stricter.** The
Network+ track could not run a Cisco switch, so its vendor column carried
CompTIA's own phrasing and said so. Here the vendor's product runs on the machine,
so there is no excuse for a single un-run command anywhere in the track.

### 6. Version rot is worse here than on any CompTIA exam

CompTIA reissues a blueprint every three years and the Security+ track handled
that with one rule: objective numbers live in frontmatter and question metadata
and never in prose.

Splunk ships several releases a year, the documentation is versioned per release,
and `docs.splunk.com/Documentation/Splunk/latest/...` moves under you. Three
consequences:

- **Cite a pinned version, not `latest`.** A citation to `latest` is a citation
  that will describe something else within a year. Decide the version to pin, cite
  that, and record the decision.
- **Every capture carries its Splunk version**, the way every Linux capture
  carries its distribution.
- **The Cloud and Enterprise split moves too.** Anything true of Splunk Cloud is
  true of a release channel rather than of a product, and dated statements need
  the date on the page.

Carry the objective-numbers-in-frontmatter rule over unchanged. It cost nothing on
Security+ and it is worth more here.

## Diagrams

Same floor as Security+: **every lesson carries at least one figure**, with a
keyed exempt list and a test behind it. The test exists now in
`blog/test/platforms.test.mjs` and needs the new track adding to its `DIRS`.

Splunk is unusually well served by figures because its central subjects are
genuinely structural, and the starter list below names the argument each figure
makes rather than its subject, because a plan row reading "diagram: the data
pipeline" produces the generic version.

| Topic area | The figure, and what it argues |
| --- | --- |
| The data pipeline | One event moving from input through parsing to indexing to search, with the point named at which each decision becomes irreversible |
| Index time against search time | The same field extracted two ways, with what each costs and when each is decided |
| Buckets | Hot, warm, cold and frozen on one time axis with real sizes, and the moment data stops being searchable |
| The search pipeline | One SPL string with the row count after each pipe, drawn to scale, so the reader sees where the data actually goes |
| `stats` against `eventstats` | The same events through both, side by side, with the rows one of them removes |
| Subsearch limits | A subsearch hitting its cap, and the silently wrong outer result that follows |
| Time ranges | The same search over three ranges with three different answers, all correct |
| Knowledge object scope | One field extraction at private, app and global scope, and who sees which |
| Distributed search | A search head fanning out to indexers and what happens when one does not answer |
| Roles and capabilities | One user's effective permissions assembled from inherited roles |
| Data models and acceleration | A search with and without the acceleration, with real times |
| Correlation search to notable | One detection firing, with everything between the raw event and the analyst's queue |

**Photographs are probably not relevant here**, unlike the physical security
objectives on Security+. Ask the question anyway, per the Network+ rule, and
expect the answer to be no.

Existing figure rules apply unchanged. The two that bite: draw the insight not the
layout, and a figure with two insights in it is two figures. Put the real search
string, the real row count, the real timestamp in the drawing and the reason it
matters in the caption. Colour is never the only channel.

## Questions

Bank sizing follows the blueprints once they are parsed. Ids follow the existing
convention, `<prefix>-<domain>-NNN`, and the prefix depends on the one-track or
four-tracks decision above.

The Security+ amendments were baked in from the first question rather than
measured at the end, which is the fix for the mistake Network+ made. Carry them,
and add one:

- A person in the stem: an analyst, an admin, a user.
- Named things as the options, not four explanatory clauses.
- **Every distractor is SPL that runs and returns the wrong thing for a nameable
  reason, and the explanation names it.** See above. This is the one that matters.
- Situational coverage on the scenario-shaped objectives, counted while writing.
- A multiple-response floor wherever the blueprint compares things.
- `learnAnchor` resolving to a heading that holds a figure, for the visual
  objectives, with stems answerable only by having read it.
- Off-syllabus material takes `beyondExam: true` and no questions, enforced by
  `quiz-validate.ts` rather than by convention.

## Order of work

 1. **`docs/splunk-certification-research.md`.** What is actually on each of the
    four exams, from Splunk's own blueprints and pages. Confirm or correct every
    cell of the exam table above and say which moved. Include the copyright and
    trademark position, the retirement position for each exam, the term
    extraction, and the version to pin.
 2. **The overlap audit**, as a table. Between the four blueprints first, because
    that decides the track structure, and then against the existing 164 topics,
    because Linux+ and Security+ both touch logging and search.
 3. **The structure decision**, written down with the measurement behind it. One
    track or four, and what the platform has to change either way.
 4. **`docs/splunk-teaching-design.md`.** The thesis, tested rather than assumed.
    What Prove it and Try it become when almost everything runs. The SPL
    distractor rule. The figure floor. The comparison axis.
 5. **`docs/splunk-topic-plan.md`.** Topics in reading order across all four
    exams, with zero hook, deeper panels, capture route and figure argument per
    row.
 6. **Exam entries, track entry with `hidden: true`, empty content directory.**
    One commit.
 7. **`splunk.sh` and the first dataset**, pinned and checksummed. Prove it end to
    end before writing a topic that depends on it.
 8. **Two topics as the pattern, then stop and review.** One heavy SPL topic from
    Core User and one platform topic from Admin, which are the two extremes the
    template has to survive. Not two adjacent topics.
 9. **Blocks in order**, captures first while the tooling is fresh.
10. **Question banks** per exam or per domain, after that material exists.
11. **The term-level pass**, per block as you go, and again at the end. The
    committed script for this is `blog/scripts/term-coverage.py`; it takes an
    exam's blueprint and reports terms with no match in the track, and it will
    need a Splunk entry in its `EXAMS` map.
12. **The verification pass.** Every claim executed or checked upstream, every
    citation fetched. It found eleven errors on Linux+, seven on Network+, and it
    is not optional.

Write the topics solo. Subagent fan-out on Linux+ block D cost two session limits
and the output needed rewriting.

## What the three finished tracks cost, so this one is planned honestly

Rough, from the repository as it stands on 2026-08-24:

| | Topics | Words |
| --- | --- | --- |
| Linux+ | 81 | ~482,000 |
| Network+ | 83 | ~404,000 |
| Security+ | 7 of a planned 77 | ~36,000 |

Words include figure markup and code fences. A finished certification track on
this site is roughly eighty topics and four hundred thousand words, and four
exams is not four times that but it is not one either. **Say what the estimate is
in the plan**, because the Security+ plan's estimate is what made its authoring
order defensible.

## Sources to start from

Every URL here returned 200 on 2026-08-24. Nothing else in this document has been
checked.

| What | URL |
| --- | --- |
| Splunk documentation, the primary source | https://docs.splunk.com/Documentation |
| Certification tracks | https://www.splunk.com/en_us/training/certification-track.html |
| Training and courses | https://www.splunk.com/en_us/training.html |
| The SPL search reference | https://docs.splunk.com/Documentation/Splunk/latest/SearchReference/WhatsInThisManual |
| The search tutorial, and its sample dataset | https://docs.splunk.com/Documentation/Splunk/latest/SearchTutorial/WelcometotheSearchTutorial |
| The container image | https://hub.docker.com/r/splunk/splunk |
| Boss of the SOC dataset, for the security exam | https://github.com/splunk/botsv3 |
| Splunk general terms | https://www.splunk.com/en_us/legal/splunk-general-terms.html |

Find and add: the individual exam blueprints as published PDFs or pages, the
certification candidate agreement, the documentation terms of use, the trademark
guidelines, and whatever Cisco now publishes about the programme. Those five are
what step 1 rests on and none of them is in the list above, because none of them
was checked.

**Deep research is wanted on what else is good.** Splunk has an unusually strong
community, and `.conf` talks, Splunk Lantern, the community wiki and a few
long-running blogs are likely to be better than most paid courses. Measure them
the way Professor Messer was measured for Security+: as a coverage benchmark and
as a signal of the mental model a reader arrives with, never as an input to write
from. Every topic and every question comes from the blueprint and the primary
documentation.
