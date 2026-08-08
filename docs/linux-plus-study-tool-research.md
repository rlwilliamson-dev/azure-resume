# Making the Linux+ track a better study tool: round two

A second research pass, covering what else exists for XK0-006 and what the
learning-science literature says about the specific format we have chosen. The
first pass ([linux-plus-teaching-design.md](linux-plus-teaching-design.md))
established how to write a topic. This one asks whether the thing we are
building is the right thing, and what is missing from it.

Research date: 2026-08-07. Every URL was checked for a 200 response on that
date.

- [The short version](#the-short-version)
- [What already exists](#what-already-exists)
- [The gap](#the-gap)
- [The biggest risk to this design](#the-biggest-risk-to-this-design)
- [Nine changes, ranked](#nine-changes-ranked)
- [What not to build](#what-not-to-build)
- [What I could not establish](#what-i-could-not-establish)
- [Sources](#sources)

## The short version

**The gap is real and it is specific.** The XK0-006 market is video and labs.
There is almost no written, current, free, citable reference. Professor Messer,
the most trusted free name in CompTIA prep, has no XK0-006 content at all; his
Linux+ page still covers LX0-101 and LPIC-1, with user comments dated 2012 and
2013. The written option is a paid study guide that CompTIA's own instructor
forum has a thread about skipping an entire objective.

**The biggest risk is that we are building a reading experience.** Reading is
the format most likely to produce confident, unprepared candidates, and the
literature on this is unambiguous. Several of the changes below exist to counter
our own format.

**The most valuable thing nobody is doing** is teaching how to answer a
performance-based question. PBQ failure is dominated by two behaviours, both
teachable, neither requiring a lab.

## What already exists

From CompTIA's own pages, a community-curated resource list, and the review
literature.

| Resource | Type | What it is good at | Where it stops |
| --- | --- | --- | --- |
| CompTIA CertMaster | Paid, official | Objective-aligned, official labs | Expensive, closed, no citations |
| Jason Dion (Udemy) | Paid video plus practice tests | Widely recommended, high volume of questions | Video; explanations are short |
| Sybex study guide | Paid book | The only substantial written treatment | CompTIA's instructor forum has a thread titled "Linux+ v8 guide from Sybex: skips a whole objective" |
| Professor Messer | Free video | The trusted free brand for CompTIA | **No XK0-006 content.** Linux+ page is LX0-101 and LPIC-1, comments from 2012 |
| YouTube courses | Free video | 7-hour lab course, 12-hour theory course exist | Not searchable, not citable, not correctable |
| SadServers | Free and paid labs | Break-fix VMs you troubleshoot for real | No explanation layer; you either know it or you do not |
| OverTheWire Bandit | Free labs | Command-line fluency through puzzles | Not exam-shaped |
| Linux Foundation LFS101x | Free course | Solid fundamentals | Not exam-aligned |
| KodeKloud | Freemium labs | Good hands-on DevOps path | Not Linux+ specific |
| Linux Upskill Challenge | Free, 20 days | Daily habit, real server | Not exam-aligned |
| Exercism Bash track | Free | 80+ scripting exercises | Scripting only |

The pattern in the community list is stark: it is **almost entirely video and
labs.** The written entries are books you buy.

The review literature on Linux certification guides names four recurring
complaints, and they are worth reading as a specification for what not to be:

1. Memorisation over context, with commands listed and never situated
2. Gaps, with objectives skipped or covered so briefly that exam questions come
   as a surprise
3. Typos and incorrect answer keys
4. Written to pass rather than to understand

## The gap

**A written, current, cited, free XK0-006 reference that is honest about where
its command output came from.** Nothing in the list above is all of those
things at once.

That is worth stating plainly because it also decides what we are *not*: we are
not competing with SadServers or KodeKloud, and we should stop thinking of the
absence of a lab as a weakness. They are better at hands-on than we would ever
be. The complementary position is the one that is empty.

Every one of the four complaints above maps onto something already built:

| Complaint | What answers it | Status |
| --- | --- | --- |
| Gaps and skipped objectives | The coverage report, generated from frontmatter | Built |
| Typos and wrong answers | Captured output, cited sources, link checker | Built |
| Memorisation over context | "What breaks without this", failure modes, worked scenarios | Built |
| Written to pass, not understand | "Prove it" in every topic | Built |

The problem is that none of that is **visible** to a first-time reader, which is
recommendation 8.

## The biggest risk to this design

The literature on metacognition is uncomfortable reading for anyone building a
prose study site.

Judgments of learning track **processing fluency**, not recall. Material that
reads smoothly produces confidence that does not predict performance. Rereading
in particular creates a strong sense of mastery while producing far less durable
learning than retrieval, and learners do not notice, which is why they are
surprised by their results.

Put bluntly: **the better this site reads, the more dangerous it is on its own.**
A well-written page is a fluency machine. Everything about our house style, the
short declarative sentences, the worked reasoning, the clean transcripts, makes
the material easier to process and therefore easier to overestimate.

This does not mean writing worse. It means the site cannot be only reading, and
the retrieval has to be unavoidable rather than optional at the end. Several
recommendations below follow directly from this.

## Nine changes, ranked

Ordered by value against effort. The first four are the ones I would actually do.

### 1. Make prediction mandatory before output is revealed

**Why:** Direct counter to the fluency problem, and it applies the pretesting
effect at the level of the individual transcript rather than once per topic.

Right now a reader scrolls to a captured block and reads the answer. Wrap the
important ones so the answer is one interaction away:

```html
<details class="predict">
<summary>What does this print, and why?</summary>
...captured output...
</details>
```

Static, no JavaScript, keyboard accessible, and it converts the single most
passive moment on the page into a retrieval attempt. Two or three per topic on
the outputs that carry the teaching, not all of them.

This is the highest-leverage change on the list and it costs almost nothing.

### 2. A study plan page

**Why:** Spacing is one of the best-evidenced effects in the literature, and we
cannot schedule anything without persistence. A published plan gets most of the
benefit with none of the storage.

The evidence gives a usable rule: the optimal gap before review is roughly 10 to
30 percent of how long you need to retain the material. For an exam eight weeks
out, that means revisiting a topic about a week after first reading it, not the
night before.

A static `/learn/linux-plus/plan` page: an eight-week schedule, topics allocated
by domain weight, with explicit review points and practice-set milestones. It is
also the single most-asked question by certification candidates, and no free
resource answers it in a way tied to actual content.

### 3. A topic on how to answer a performance-based question

**Why:** PBQ failure is dominated by two behaviours, both teachable, neither
needing a lab.

The reported failure modes are consistent: candidates **miss a requirement**
because they started working before reading the whole scenario, and they **do
not verify** before submitting, even though CompTIA's own guidance is that
practical questions generally let you check your work.

That is a technique topic, not a content topic, and nothing free teaches it:

- Read the entire scenario before touching anything
- Enumerate the requirements as a checklist; one missed requirement can lose the
  whole question
- Budget roughly 2 to 3 minutes for a multiple-choice item and 5 to 10 for a PBQ
- Verify before submitting, using the same commands as every "Prove it" section

It also closes the loop on the whole design. Every topic already ends by proving
the change took effect; this topic explains that the habit is worth marks.

### 4. Say what this site is not, and link to the other half

**Why:** Honesty, and it makes the site more useful rather than less.

The consensus in the PBQ material is that lab time is the preparation and video
lectures are not. We have deliberately not built a lab. Pretending otherwise
would be the one thing that could make this material actively harmful.

One short page: this is the understanding half, here is where to get the
hands-on half. SadServers for break-fix, OverTheWire Bandit for command-line
fluency, Linux Upskill Challenge for daily habit, Exercism for scripting. Cheap,
honest, and it positions the site accurately for anyone arriving from a search.

### 5. Focused self-explanation prompts

**Why:** A meta-analysis across 64 studies and roughly 6,000 participants puts
self-explanation at g = 0.66, which is a large effect for something this cheap.

The important detail is that **focused prompts beat open-ended ones**. Not
"explain this in your own words" but a specific question about a specific
causal link:

> Why does `rpm -qf` follow the symlink when `dpkg -S` does not? Answer before
> reading on.

One per major section, aimed at the causal step rather than the fact.

### 6. Respect the segmenting principle

**Why:** Learner-paced segments beat continuous presentation with a median
effect size around 0.98, one of the largest in Mayer's set.

This mostly validates decisions already taken: numbered sections, a contents
panel, the 3,000-word ceiling that triggers a topic split. The change is to
treat that ceiling as real rather than aspirational, and to resist the pull
toward consolidating everything into fewer, longer pages now that sections are
the default.

### 7. Name the parts before using them

**Why:** The pretraining principle. People learn a process better when they
already know the names and characteristics of its components.

Practically: where a topic's body uses terms the reader may not have, the mental
model section should name them first. This is a writing discipline more than a
feature, and it is worth adding to the template as a check.

### 8. Make the build discipline visible

**Why:** All four complaints about existing material are already answered by
things we built, and none of it is visible.

A short "how this is built" page: every claim cites a primary source, every URL
is checked weekly, command output is captured in pinned containers and labelled
with the distribution, coverage against all 29 objectives is generated rather
than asserted, and the build fails if a topic claims an objective without a
source.

That is a trust argument nobody else in this market can make. It is also, not
incidentally, an accurate description of how Ryan works.

### 9. Do not ask readers how ready they feel

**Why:** Self-assessment is exactly the signal the metacognition literature says
is unreliable.

The weighted practice exam with per-objective breakdown is the readiness signal,
and it should be framed as the only one. Avoid confidence sliders, "mark as
understood" checkboxes, and progress bars driven by pages viewed. Pages viewed
measures fluency, which is the thing that misleads people.

## What not to build

Reaffirmed or newly ruled out by this pass.

- **A lab or terminal emulator.** SadServers and KodeKloud already do this well.
  Link to them.
- **Video.** The gap is written material. YouTube already has a 7-hour lab
  course and a 12-hour theory course for XK0-006, both free.
- **Spaced repetition scheduling.** Needs persistence, which the site does not
  have. The study plan page gets most of the value.
- **Volume of practice questions as a goal.** The complaint about existing
  material is wrong answer keys, not too few questions. Fewer questions with
  real explanations beats more questions.
- **Progress tracking.** See recommendation 9.

## What I could not establish

- **Whether XK0-006 genuinely weights PBQs more heavily than XK0-005.** Multiple
  training vendors assert it; CompTIA publishes no per-question-type weighting
  for either exam. Still unverified, same as in the first research pass. Do not
  repeat it as fact in content.
- **Whether typing commands rather than reading them produces better retention
  for command-line skills specifically.** It is widely assumed and I did not
  find direct evidence either way. The recommendation to link out for hands-on
  practice rests on the PBQ-format argument, which is documented, rather than on
  a motor-learning claim, which is not.
- **How long candidates actually study for XK0-006.** No reliable data; the
  numbers in circulation are vendor marketing. The study plan page should
  present its eight weeks as a structure to adapt, not as a researched figure.

## Sources

| Claim | Source | URL |
| --- | --- | --- |
| Judgments of learning track fluency, not recall; learners overestimate after rereading | Bjork et al., *Metamemory and Education* | https://bjorklab.psych.ucla.edu/wp-content/uploads/sites/13/2016/04/Metamemory_and_Education.pdf |
| Spacing effect; optimal gap is a proportion of the retention interval | Cepeda et al., *Distributed Practice in Verbal Recall Tasks: A Review and Quantitative Synthesis* (254 studies) | https://augmentingcognition.com/assets/Cepeda2006.pdf |
| Spacing improves generalisation, not just recall | *Using Spacing to Enhance Diverse Forms of Learning* | https://files.eric.ed.gov/fulltext/ED536925.pdf |
| Spacing patterns hold across very different domains | *Very Similar Spacing-Effect Patterns in Very Different Learning/Practice Domains* | https://www.ncbi.nlm.nih.gov/pmc/articles/PMC3946552/ |
| Self-explanation, g = 0.66 across 64 studies | British Psychological Society research digest on the self-explanation meta-analysis | https://www.bps.org.uk/research-digest/self-explanation-powerful-learning-technique-according-meta-analysis-64-studies |
| Focused self-explanation prompts beat open-ended ones | Carnegie Mellon, *Focused Self-Explanations Lead to the Best Learning* | https://www.cs.cmu.edu/~hn1/papers/ICLS2022_FocusedSE.pdf |
| Segmenting, signaling, pretraining principles and effect sizes | Mayer, *Applying the Science of Learning* | https://pressbooks.pub/learningenvironmentsdesign/chapter/mayer-applying-the-science-of-learning-evidence-based-principles-for-the-design-of-multimedia-instruction/ |
| What a performance-based question is, and that candidates can generally check their work | CompTIA, *Performance-Based Questions Explained* | https://www.comptia.org/en-us/resources/test-policies/exam-development/performance-based-questions-explained/ |
| Professor Messer has no XK0-006 content | Professor Messer Linux+ training videos page (LX0-101 and LPIC-1, comments dated 2012 to 2013) | https://www.professormesser.com/linux-plus/linux-training-videos/ |
| Community-curated XK0-006 resource list, overwhelmingly video and labs | unixerius/XK0-006 | https://github.com/unixerius/XK0-006 |
| Break-fix troubleshooting labs | SadServers | https://sadservers.com/ |
| Command-line fluency wargame | OverTheWire Bandit | https://overthewire.org/wargames/bandit/ |
| Twenty-day daily server habit | Linux Upskill Challenge | https://linuxupskillchallenge.org/ |

Accessed 2026-08-07. Tier 2 by the project's source hierarchy: these inform how
the material is presented and are not cited inside topic content, which cites
only Linux and CompTIA primary sources.
