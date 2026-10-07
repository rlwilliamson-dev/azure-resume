# Splunk certification track: teaching design

How the material for five Splunk exams gets presented, and specifically where it
must differ from the three CompTIA tracks rather than inheriting their shape.
Companion to [splunk-certification-research.md](splunk-certification-research.md),
which covers what is on the exams and what may be reproduced, and
`splunk-topic-plan.md`, which covers what gets written.

[linux-plus-teaching-design.md](linux-plus-teaching-design.md) still governs
everything not contradicted here: the audience decision, progressive disclosure,
concrete before abstract, defining the word before using it, the voice, and the
rules about analogies and dry wit. The Network+ and Security+ documents govern
their own deltas where those generalised. This one records only what changes for a
vendor product, and it exists because four of the five things it changes look like
they transfer and do not.

Written 2026-08-25, against blueprints read on the same date.

- [The thesis, and how the candidate one was tested](#the-thesis-and-how-the-candidate-one-was-tested)
- [What Prove it becomes](#what-prove-it-becomes)
- [What Try it becomes](#what-try-it-becomes)
- [The SPL distractor rule](#the-spl-distractor-rule)
- [Capturing wrong answers](#capturing-wrong-answers)
- [The comparison axis](#the-comparison-axis)
- [Diagrams](#diagrams)
- [Photographs](#photographs)
- [Version and provenance labelling](#version-and-provenance-labelling)
- [What the objective descriptions have to do](#what-the-objective-descriptions-have-to-do)
- [Cross-track duplication](#cross-track-duplication)
- [Question design](#question-design)
- [Within-track scope drift](#within-track-scope-drift)
- [What we are deliberately not building](#what-we-are-deliberately-not-building)
- [Decisions taken](#decisions-taken)
- [Open questions](#open-questions)

## The thesis, and how the candidate one was tested

The build prompt offered a candidate and asked for it to be tested rather than
adopted:

> Splunk teaches you to turn a question into a search, and to know what the search
> left out. Every topic ends in a result somebody could act on, and says what would
> have to be true for that result to be wrong.

It also predicted where it would fail: "It may hold for User and Power User and
fail for Admin, where the subject is a platform rather than a question."

**That prediction is wrong, and the way it is wrong is the most useful thing this
test produced.**

Every domain across the five in-scope blueprints was classified by asking what its
content ends in. Three answers were possible. It ends in a result you read. It ends
in a configuration or an object whose proof is a search. Or it ends in a definition,
a comparison or a choice, with no result at all.

| Exam | Ends in a result | Proof is a search | Conceptual |
| --- | --- | --- | --- |
| Core User | 84% | 11% | 5% |
| Core Power User | 30% | 70% | 0% |
| Enterprise Admin | 0% | 90% | 10% |
| Cybersecurity Defense Analyst | 30% | 20% | 50% |
| Cybersecurity Defense Engineer | 50% | 30% | 20% |
| **Mean across the five** | **38.8%** | **44.2%** | **17.0%** |

**The thesis holds on 83 percent by weight and fails on 17.** Weights are the
blueprints' own; the classification is a judgement applied one domain at a time and
is reproduced above so it can be disagreed with.

**Enterprise Admin is where it holds most uniformly, not least.** Nothing on that
exam ends in a search result, and 90 percent of it is proved by one. That is not a
strained reading, it is how the product works: you prove data arrived by searching
for it, you prove a sourcetype parsed by looking at the events, you prove a role is
right by seeing what that user can see, you prove a transform fired by finding the
field masked. Splunk's own verification mechanism is search, so the admin's proof
and the analyst's answer are the same kind of object. The two 5 percent domains
that fail, admin basics and license management, are the exam's smallest.

**Where it actually fails is Cybersecurity Defense Analyst**, at 50 percent
conceptual: the cyber landscape and frameworks domain at 10 percent, threat and
attack types at 20, and defenses, data sources and SIEM best practices at 20. That
is half of one exam and it is a coherent group rather than scattered exceptions. It
is also the exam that was added after the build prompt was written, which is why
the prompt could not have predicted it.

So the thesis widens rather than being replaced, and the widening is the part that
makes it true:

> **Linux+ teaches you to change a system and prove the change took. Network+
> teaches you to read a network you did not build and prove what it is doing.
> Security+ teaches you to pick the right one from a set of things that are all
> real, and to say what the rejected ones cost. Splunk teaches you to turn a
> question into a search, and to know what the search left out.**
>
> Every topic ends in something checkable, in one of three forms: a result you can
> read, a configuration whose proof is a search, or a concept turned into the
> search you would run to find it. Every one of them says what would have to be
> true for the answer to be wrong.

Three reasons that is the right sentence.

**It names the failure mode the product actually has.** Splunk does not fail with
an error. It returns a number, promptly and plausibly, computed over the wrong time
range, the wrong index, a sourcetype whose fields never extracted, or rows that
`stats` collapsed before you saw them. A subsearch hits its limit and truncates
without saying so, and the outer search is quietly wrong afterwards. Nothing about
any of that is visible in the output. A dashboard built on it is confidently wrong
for months. No other resource for these exams is organised around that, because
you can only teach it if you run the wrong version too.

**It gives the conceptual 17 percent an obligation rather than an exemption**,
which is the move that made the Network+ and Security+ theses work. The Defense
Analyst vocabulary objectives exist so that a threat concept can become a search.
Knowing what command and control traffic is means knowing to look for beaconing at
a regular interval. Knowing what exfiltration is means knowing which data source
would show it and which would not. A page that ends by defining the term has
stopped one step early. A page that ends with the search you would run, and the
data source you would need to have been collecting, has not.

**And it fixes the distractor rule before the first question is written**, which is
the largest thing this track would otherwise get wrong. See
[the SPL distractor rule](#the-spl-distractor-rule).

**One thing the thesis is not.** It is not an instruction to bolt a section headed
"what this left out" onto every page. The template already has the places this
lives: **Prove it** carries the result, and **What trips people up** is where the
silent wrongness belongs. What changes is that the reasoning has to land on
something checkable, and that a topic which finishes by restating what a command
does has not landed.

## What Prove it becomes

**The three forms carry over**: run it, work it out, look it up. Every topic uses
at least one and the provenance line at the foot says which. Nothing about this
track argues for a fourth form.

What changes is a mandatory second half.

> **Every Prove it on this track ends with the counterfactual.** Having shown the
> result, name the one change that would make it different and wrong: the time
> range that excludes the events, the index that was never in scope, the field that
> does not exist yet at that point in the pipeline, the rows the transforming
> command removed.

That is the thesis made structural rather than aspirational, and it is cheap
because the container makes it cheap. The counterfactual is not a hypothetical: it
is a second capture, and it goes on the page next to the first. See
[capturing wrong answers](#capturing-wrong-answers).

The mix of the three forms is different from every previous track:

| Form | Share | What it holds here |
| --- | --- | --- |
| Run it | Most of the track | A search, its output, and the version and dataset it ran against |
| Work it out | Smaller than Security+, larger than zero | Licence volume against daily ingest, retention arithmetic in seconds, bucket sizing, rows surviving each pipe |
| Look it up | Concentrated in two places | Enterprise Security objects that cannot be run, and the Defense Analyst conceptual domains |

**Run it is a stronger claim on this track than on any previous one, and it should
be stated as a standard rather than an aspiration.** If a topic shows SPL, the SPL
was run and the output is what came back. No hand-written result tables anywhere,
including in figures, including in a table that merely illustrates a shape. The
existing tracks could not always meet that bar, because Network+ could not run a
Cisco switch and Security+ cannot run an enterprise. This one has the vendor's own
product on the machine and has no excuse.

**Work it out is smaller than it looks and should not be inflated.** Splunk has
real arithmetic but not much of it, and the temptation is to invent some to match
the Security+ shape. Retention in `frozenTimePeriodInSecs` is genuinely a number a
reader gets wrong by a factor of 60 or 86,400, and that is worth a topic. Licence
volume against ingest is arithmetic with a consequence. Rows surviving each pipe is
arithmetic the reader can check against the job inspector, which is the best of the
three because the answer is on screen.

**Look it up carries the Enterprise Security material**, and it stays what it is on
the other tracks: a named document, a named page, and a question that only that page
answers. Never a reading list. It also carries the honesty rule below.

### The Enterprise Security honesty rule

Enterprise Security has no free licence and no self-serve trial, and the decision
recorded in the research document is to run the detection logic and document the
wrapper. That creates a split that runs through the middle of individual topics
rather than between topics, which is new and which is the thing most likely to be
got wrong under time pressure.

> **A topic never implies that a documented Enterprise Security behaviour was
> observed.** In a topic where the search ran and the object that would wrap it did
> not, the page says so at the point where the two meet, not only in the provenance
> line at the foot.

The detection SPL runs, against a Creative Commons Zero dataset, and returns real
rows. What that search becomes when Enterprise Security schedules it, what a
finding looks like in the analyst queue, what a risk modifier adds to a risk object:
all of that is sourced from Splunk's documentation at a pinned version and is
labelled as sourced. The Network+ track handled a vendor CLI it could not run
exactly this way, and the rule generalised.

## What Try it becomes

The Linux+ form is a completion problem framed as "if you have a VM handy". The
Network+ forms are a committed topology with one thing removed, arithmetic checkable
against a named tool, or a document to go and read.

**This track gets a form none of the others could have**, and it is worth naming
because it is the single best thing the frozen dataset buys:

> **Change one thing in a working search. Predict the new row count before you run
> it. Then run it.**

That works only because the dataset does not move. A search over Boss of the SOC
version 3 returns the same number today and in a year, because the archive has not
changed since 2020 and its checksum is published. So a reader can be told the
answer is 1,482 rows, be asked what happens when the `by` clause is removed, and
find out whether they were right. No previous track could set an exercise whose
answer is a specific number the reader can verify, except in the subnetting topics,
and that is the closest analogue: a procedure with one right answer and a small set
of nameable wrong ones.

Three forms, chosen by what the topic is:

| Topic kind | Try it is |
| --- | --- |
| Anything with a search in it | A committed search against the pinned dataset, with one element changed and the row count to predict |
| The Admin platform topics | A configuration to make in the container, and the search that proves it took |
| The conceptual Defense Analyst topics, and the Enterprise Security material | A named document page, and a question only that page answers |

The committed searches are what make the first form real, and they belong in the
repository for the same reason the netlab topologies do: an exercise whose answer
cannot be reproduced is not an exercise.

**The reader without a container is not abandoned.** The row count is on the page.
Somebody revising on a train gets the prediction exercise as a thought experiment
with the answer underneath, which is worth doing on its own, and somebody at a
keyboard gets to be wrong in public and find out.

## The SPL distractor rule

This is the most valuable thing this track can do that no other Splunk resource
does, and it is only possible because the wrong answers can be run.

The Network+ precedent is objective 1.7, where every distractor must be the product
of a named arithmetic error, and the explanation names which. That rule was narrow
because it only applied to subnetting. **The SPL version applies to most of two
exams and it is stronger:**

> **Every SPL distractor is real SPL that runs, returns the wrong thing, and does
> so for a reason with a name. The explanation names it.**

A distractor that is syntactically invalid teaches nothing, because a reader
eliminates it on sight and learns only that they can spot a typo. A distractor that
runs and returns 1,482 rows where the right answer returns 1,208 is a question about
whether you understand the pipeline.

The named error classes, which are the taxonomy the explanations draw on. Each one
is a mistake somebody has actually made:

| Error | What it does | Why it looks right |
| --- | --- | --- |
| `stats` where `eventstats` was needed | Collapses the events into the aggregate and loses the rows you were going to filter | The number in the aggregate is correct |
| A missing `by` clause | Aggregates across everything instead of per group | Returns one plausible row instead of an obviously empty result |
| `where` against `search` | Different evaluation points and different comparison semantics against literals | Both are filters and both read like English |
| A time range that excludes the events | Returns fewer rows, or none | An empty result reads as "there is nothing there" rather than "I asked wrongly" |
| No index specified | Searches whatever the role's default indexes are, which is not the same as all of them | Returns results, just not the right population |
| A field referenced before it exists | The field is null at that point in the pipeline, so the filter drops everything | The field name is spelled correctly and exists later |
| A subsearch at its limit | Silently truncated, so the outer search filters against a partial list | The outer search returns rows and reports no error |
| `join` where `stats` would do | Row limits and different join semantics quietly drop rows | It is the SQL-shaped answer, which is why people reach for it |
| `transaction` where `stats` would do | Different grouping, a maximum event count, and much worse performance | It is named after the thing being asked for |
| A non-streaming command placed early | Forces work onto the search head that could have run on the indexers | The result is correct, so nothing signals the mistake |

The last one is the interesting case, because the answer is right and the search is
still wrong. That belongs in the search efficiency material rather than in a
correctness question, and the distractor rule needs the distinction: a distractor is
either wrong in its result or wrong in its cost, and the question stem has to make
clear which is being asked.

**Where the rule does not apply.** The Admin exam's questions are mostly not about
SPL, and a configuration distractor obeys the older rule instead: it is a real
mistake somebody has made, drawn from the failure modes already documented in the
topic. Forcing SPL distractors onto a question about `props.conf` precedence would
be the rule wearing the wrong hat.

## Capturing wrong answers

The distractor rule creates a capture category no existing track has, and the
tooling has to support it directly rather than leaving it to be done by hand. A
hand-run wrong answer is exactly the kind of thing that gets retyped from memory,
and retyping a capture has already shipped one fake transcript on this repository.

What `splunk.sh` needs, beyond running a search:

- A mode that runs several searches over the same pinned dataset in one invocation
  and emits them labelled, so the right answer and its distractors are captured
  together and cannot drift apart.
- The row count as a first-class output, because for a distractor the count is
  usually the entire point and the rows themselves are noise.
- The Splunk version and the dataset checksum on every emitted block, the way every
  Linux capture carries its distribution.

**The wrong output goes on the page**, in the topic, not only in the question bank.
A reader who sees that removing the `by` clause turns 1,208 rows into 1 has learned
something a sentence cannot teach them.

## The comparison axis

The build prompt proposes Splunk Enterprise against Splunk Cloud as the recurring
`COMPARE_META` table. **That axis is not supported by the five in-scope
blueprints.** Splunk Cloud is named once across all five, in the Defense Engineer
document, and the Enterprise Admin blueprint does not name it at all. It is
genuinely examinable on the Splunk Cloud Certified Admin exam, whose objective 1.3
is exactly that comparison, and that exam is out of scope.

The axis that does recur across all five is **index time against search time**.

It is the central irreversible decision in the product, and every exam in scope
tests part of it. Core User consumes fields extracted at search time without being
told that is what they are. Power User creates them, at search time, and the whole
knowledge-object model depends on knowing that. Enterprise Admin configures the
index-time transforms, where the same operation costs differently and cannot be
undone. Defense Engineer normalises across both and has to know which side a given
field landed on.

It is also the thing this product is hardest to learn, and the place where a
plausible mental model produces expensive mistakes for years.

```
COMPARE_META entry, proposed:
  heading:  'Across index time and search time'
  slug:     'index-time-and-search-time'
  command:  'diff index-time search-time'
  columns:  At index time | At search time | Decided by | Cost of changing it later
```

The heading begins with "Across", which the compare-tables integration requires.

The fourth column is the one that earns the table. A comparison of two moments is a
diagram; a comparison of two moments with the price of changing your mind in each is
revision material.

**Confirm the column set against three written topics before committing to it.**
The Network+ table went through two shapes before the "To check that" column was
recognised as the row label rather than a comparison, and a table configured in
`tracks.ts` before any topic uses it is a guess with a schema.

## Diagrams

**Same floor as Security+: every lesson carries at least one figure**, with a keyed
exempt list and a test behind it. The test exists in `blog/test/platforms.test.mjs`
under `describe('figure floor')` and needs `'splunk'` added to its `DIRS` array. The
other exempt lists in that file are keyed `track/slug`, and this one is too.

Every existing figure rule applies unchanged and none is restated here. The two
that will bite hardest on this track:

**Draw the insight, not the layout.** Splunk's subjects are structural, which makes
this track unusually easy to illustrate and unusually easy to illustrate
uselessly. A drawing of the data pipeline as four labelled boxes with arrows between
them is the generic version, and it is what every Splunk resource already has. The
figure has to carry an argument.

**A figure with two insights in it is two figures.** The pipeline figure is the
obvious offender, because it wants to show the stages and the irreversibility and
the parsing detail at once.

The starter list, with the argument each figure makes rather than its subject,
adapted from the build prompt and corrected where the blueprints moved:

| Subject | The argument |
| --- | --- |
| The data pipeline | One event from input to parsing to indexing to search, with the point marked after which each decision cannot be changed without re-indexing |
| Index time against search time | The same field extracted twice, with what each costs and when each is decided |
| Buckets | Hot, warm, cold and frozen on one time axis with real sizes, and the moment data stops being searchable |
| The search pipeline | One SPL string with the row count after each pipe, drawn to scale, so the reader sees where the data actually goes |
| `stats` against `eventstats` | The same events through both, with the rows one of them removes |
| Subsearch limits | A subsearch hitting its cap and the silently wrong outer result that follows |
| Time ranges | The same search over three ranges, three different answers, all correct |
| Knowledge object scope | One field extraction at private, app and global scope, and who sees which |
| Configuration precedence | Four files setting the same attribute and the one that wins, with `btool` output next to it |
| Distributed search | A search head fanning out, and what the answer looks like when one peer does not reply |
| Roles and capabilities | One user's effective permissions assembled from inherited roles |
| Data model acceleration | One search with and without it, with real elapsed times |
| Detection to finding | One detection firing, with everything between the raw event and the analyst's queue, and the ES 8 and pre-8 names on the same object |

The last one carries an obligation the other twelve do not: it has to label both
vocabularies, because the Defense Engineer blueprint uses both and a reader arriving
from either generation of documentation has to find their own word on the drawing.

**The pipeline figure has a second obligation**, recorded in the research document
and repeated here because this is where somebody would draw it: Security+ planned
topic 49 promises a figure walking one syslog line from raw to parsed to enriched to
correlated to alert. That figure and this one are the same drawing with different
labels unless this one commits to irreversibility as its argument. If the Splunk
pipeline figure ends up teaching what parsing adds, it has drifted into topic 49 and
should be redrawn.

## Photographs

Asked, per the Network+ rule that the question gets asked of every topic rather than
the obvious ones. **The answer is no, and unusually it is no for the whole track.**

The test is whether a topic names a physical object the reader may never have held.
Across five blueprints the physical objects are a forwarder, which is software; an
indexer, which is software on a server indistinguishable from any other server; and
a deployment server, likewise. The Network+ track needed photographs because a
transceiver, a punch-down tool and an OTDR are objects with detail on them. Nothing
in Splunk is.

No `images/` directory, no `credits.json` entry, and the photograph rules do not
apply. If a topic later argues for one, the rules are in the Network+ document and
they are unchanged: a licence that permits display, a local file, a credits entry,
and never a hotlink.

## Version and provenance labelling

Version rot is worse here than on any CompTIA exam and the research document records
the pinned versions. Three rules follow for the topics themselves.

**Objective numbers live in frontmatter and question metadata, never in prose.**
Carried over from Security+ unchanged. It cost nothing there and it is worth more
here, because Splunk changes blueprints without notice and says so on every one of
them.

**Every capture carries its Splunk version and its dataset**, the way every Linux
capture carries its distribution. The label is emitted by the tooling rather than
typed, for the same reason.

**A statement about Splunk Cloud carries a date.** Anything true of Splunk Cloud is
true of a release channel rather than of a product, and the version numbering is not
even the same shape as Enterprise's. The Search Tutorial is currently published at
Cloud version 10.5.2605 and Enterprise version 10.4 in parallel, which is the
problem in miniature.

**The vocabulary rule for Enterprise Security.** ES 8.0 renamed notable events to
findings and risk events to intermediate findings. The Defense Engineer blueprint
uses both vocabularies in the same document. A topic introduces the object once,
gives both names at that point, and then uses one consistently. It never silently
switches, and it never teaches only the newer name, because the blueprint a reader
is being examined against still says correlation search.

## What the objective descriptions have to do

The decision recorded in the research document is that `src/config/exams.ts` holds
the track's own one-line description of each objective rather than Splunk's
statement. That is 157 lines to write and it is worth saying what makes one good,
because the failure mode is writing 157 paraphrases that are worse than the
originals.

A description answers what a reader would have to be able to do. Splunk's "Splunk
components" becomes what the components are and which one does what. Splunk's
"Understand fields" becomes where a field comes from and when it exists. The test is
whether somebody reading only the coverage page could tell what to study.

Two rules that keep it honest:

**Never make the description a claim about the exam.** "Candidates are often tested
on" is a statement about a test nobody has seen. What is examinable is a statement
about the document, and that is the permitted form.

**Expect convergence on the short ones, and do not fight it.** Where the objective
is a bare feature name, the description will match Splunk's wording because there is
no other way to write it, and a bare feature name is not protectable expression.
Writing "the command that produces the most common values" to avoid saying "the top
command" makes the page worse and protects nothing.

## Cross-track duplication

Measured in full in the research document, and the summary is that this is the
smallest overlap of any track added to this site: four existing topics and roughly
28,000 words, with the word Splunk appearing zero times across 967,762 words of
existing content.

The Network+ rule applies unchanged and costs almost nothing here. Write
self-contained, link at the foot as further depth, never send a reader elsewhere
mid-explanation. Three links now, and three more when Security+ blocks D and E land.

The one link worth designing rather than adding: the search pipeline topic links to
`linux-plus/19-shell-redirection-and-pipes`, and the framing matters. A reader who
knows shell pipes arrives with a model that is right about the shape and wrong about
the unit. A shell pipe carries bytes and an SPL pipe carries rows, so `head` in a
shell truncates a stream and `head` in SPL removes rows from a table that later
commands then cannot see. That is a productive collision rather than a duplication,
and the topic should use it rather than avoid it.

## Question design

The Linux+ authoring standard governs. Its input rules are unchanged and are not
restated: never read a braindump, never write from memory of a real exam, cite the
source of the fact being tested, walk every option in the explanation, no trick
questions, no "all of the above".

Six amendments, all specific to these exams, and all baked in from the first
question rather than measured at the end.

**Banks are per exam, and per domain within an exam.** Five exams means five
coverage pages and five sets of banks, which is the structural change the research
document describes for `EXAM_FOR_TRACK`.

**The SPL distractor rule**, above. This is the one that matters.

**A person in the stem.** An analyst, an admin, a knowledge manager, a detection
engineer. Carried from Security+ where it was baked in from the first question.

**Named things as the options, not four explanatory clauses.** On an SPL question
the options are searches, which satisfies this automatically. On the Admin exam the
options are file names, stanza names, capability names and command names.

**A multiple-response floor wherever a blueprint compares things.** The obvious
sites are the transaction against `stats` objective, the acceleration options, and
anywhere the index-time against search-time table appears. Splunk publishes nothing
about whether its exams use multiple-response items, so this is matching what the
material demands rather than matching the exam format, and the exam page should say
so.

**A `learnAnchor` resolving to a heading that holds a figure**, for the visual
objectives, with stems answerable only by having read it. The pipeline, buckets,
precedence, distributed search and detection-to-finding figures are the five that
earn this.

**Cognitive level, and the thing to check rather than assume.** `quiz-validate.ts`
carries a hardcoded warning asserting that the exam is scenario-based, which is
false for Network+ Domain 1 and was fixed there. It is false again here for Core
User Domain 1 and for the Defense Analyst vocabulary domains. Whatever shape that
fix took for Network+ needs extending rather than re-deriving.

**Off-syllabus material takes `beyondExam: true` and gets no questions**, enforced
by `quiz-validate.ts` rather than by convention. This track has more off-syllabus
temptation than any previous one, because the product is much larger than the exams.
Two named cases: **SPL2 appears in none of the five blueprints** and is off-syllabus
in full, and the Advanced Power User material is off-syllabus even though it is the
most useful cross-check on whether the SPL coverage is sane.

## Within-track scope drift

The Network+ rule applies and is restated because this track is more exposed to it
than either of the others: **before writing topic N, check its row against what
topic N-1 shipped, not against what topic N-1's row promised.**

The exposure is specific. Five exams that assume each other and never re-test each
other means the foundation topics are written once and consumed four times, so a
foundation topic that quietly annexes the next block's material will not be noticed
until that block is written, which could be forty topics later. The search pipeline
topic is the likeliest offender: everything in the product is downstream of it and
almost anything can be justified as belonging there.

Split by direction rather than by subtopic where the split is not obvious, which is
the Network+ ruling and generalises cleanly here: reading a search somebody handed
you against writing one from a question; consuming a field against creating one;
proving data arrived against configuring the input that brings it.

## What we are deliberately not building

Stated so it does not get relitigated.

- **An SPL drill or query generator.** The Network+ reasoning was that five free
  generators already existed and were better than anything we would build. That
  reasoning does not transfer, because no equivalent free SPL practice tool turned
  up. The decision rests on something else: the frozen dataset already gives a
  better exercise than a generator could, because a generator produces synthetic
  questions with computed answers while a pinned dataset produces real questions
  whose answers the reader can verify. Building a generator would be building a
  worse version of what
  [Try it](#what-try-it-becomes) already is.
- **A live Splunk instance on the site.** The container is 1.8 GB and needs a
  licence acceptance per instance.
- **A glossary route.** Ruled out on Network+ and the reasons have not changed.
- **A separate track per exam.** Measured and rejected in the research document.
- **An SPL syntax highlighter beyond what the existing code fences do**, unless a
  written block proves unreadable without one.
- **Anything reproducing a blueprint end to end.** Decided in the research document
  and repeated here because the coverage page is where it would happen by accident.

## Decisions taken

| Question | Decision | Date |
| --- | --- | --- |
| Does the candidate thesis hold | Holds on 83% by weight. Widened, not replaced. Fails on Defense Analyst domains 1 to 3 | 2026-08-25 |
| Does it fail on Admin, as predicted | No. Admin is where it holds most uniformly, at 90% proved by search | 2026-08-25 |
| Prove it forms | The three carry over. A mandatory counterfactual is added to each | 2026-08-25 |
| Try it | Predict the row count, then run it. New form, only possible with a frozen dataset | 2026-08-25 |
| Distractor rule | Every SPL distractor runs and is wrong for a named reason, from a ten-class taxonomy | 2026-08-25 |
| Comparison axis | Index time against search time. Not Enterprise against Cloud, which these blueprints do not test | 2026-08-25 |
| Figure floor | Every lesson, keyed exempt list, `'splunk'` added to `DIRS` in the figure floor test | 2026-08-25 |
| Photographs | None on this track. The question was asked of the whole subject and the answer is no | 2026-08-25 |
| SPL2 | Off syllabus in full. `beyondExam: true`, no questions | 2026-08-25 |

## Open questions

**Does the counterfactual belong in Prove it or in its own section?** Written into
Prove it here, on the argument that a separate heading would make it skippable. If
three written topics show the two halves fighting for the same space, split it.

**Whether the row-count prediction survives a dataset that has to change.** The
whole exercise rests on Boss of the SOC version 3 being static, which it has been
since 2020. If a topic needs data that dataset does not contain, the fallback is the
Search Tutorial data, which is regenerated daily and would break every printed row
count. No topic should be planned against tutorial data without knowing that.

**Whether Splunk 10.4 will mount Boss of the SOC buckets written by 7.1.7.** This
is the largest untested assumption in the plan and it is step 7's first job, before
any topic depends on it.

**How the four blocks divide the foundation.** Six shared foundation topics are
estimated, and which exam each is filed under for coverage purposes is not decided.
A topic can declare objectives from more than one exam, which is probably the
answer, but it has not been tried.
