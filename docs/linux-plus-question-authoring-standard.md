# Writing practice questions for the Linux+ track: the standard

What CompTIA actually prohibits, what it permits, and the item-writing rules the
`linux-plus` banks follow. Read this before writing a question.

Research date: 2026-08-07. Every URL was checked for a 200 response on that date.

- [The bottom line](#the-bottom-line)
- [What CompTIA prohibits](#what-comptia-prohibits)
- [What CompTIA permits](#what-comptia-permits)
- [Trademark rules](#trademark-rules)
- [What a PBQ actually is](#what-a-pbq-actually-is)
- [Item-writing rules](#item-writing-rules)
- [The authoring standard](#the-authoring-standard)
- [What the build should enforce](#what-the-build-should-enforce)
- [Two corrections to existing content](#two-corrections-to-existing-content)
- [Sources](#sources)

## The bottom line

**Writing original practice questions from the published objectives is
permitted.** CompTIA's own trademark guidance gives, as an approved example of
acceptable third-party use, the sentence "We create our own training materials
and courses to help students prepare for the CompTIA A+ certification." That is
precisely what this track is.

**The prohibition is on their items, not on the subject matter.** Every clause
below is scoped to *actual exam content*. Nothing prohibits testing the same
objective, the same command, or the same concept. What is prohibited is
reproducing, paraphrasing, or reconstructing the questions CompTIA wrote.

**The risk to manage is "substantially similar", not "identical".** The standard
CompTIA applies to unauthorized material is content "exactly the same or
substantially similar to what's on the certification exam". You cannot
accidentally violate that by writing independently from documentation; you can
violate it by looking at leaked material first. So the controlling rule is about
inputs, not outputs: never read a braindump, and there is nothing to
accidentally reproduce.

**Getting the feel right is a format problem, not a content problem.** Matching
the exam means matching its question shapes, its cognitive level, its weighting,
and its clock. All of that is public.

## What CompTIA prohibits

From the Candidate Agreement, section 8, verbatim:

> Any disclosure of the contents of any CompTIA certification examination is
> strictly prohibited.

The prohibited activities are enumerated, and one phrase in particular matters
for anyone writing study material:

> Disseminating actual exam content by any means, including, but not limited to,
> web postings, formal or informal test preparation or discussion groups, chat
> rooms, **reconstruction through memorization**, study guides, or any other
> method.

"Reconstruction through memorization" is the clause that catches well-meaning
people. Sitting the exam and then writing questions from what you remember is
explicitly prohibited, even if you never copy anything. It is the single most
likely way an honest author gets into trouble.

Also prohibited:

> Copying, publishing, selling, offering to sell, distributing in any way, or
> otherwise transferring, modifying, making derivative works of, reverse
> engineering, decompiling, disassembling, or translating any Exam or any part
> thereof.

And on ownership:

> Examination Materials are the proprietary, confidential, and copyrighted
> materials of CompTIA.

The Unauthorized Training Materials policy defines the target as "copies of real
CompTIA exam questions and answers", brain dump sites sharing real test content,
and resources that break copyright.

The educator policy adds a duty for anyone publishing study material: ensure
what you provide "do[es] not include unauthorized training materials, exam
dumps, or brain dumps", and educate people on using legitimate resources.

There is also a **reporting obligation**. If you become aware you have been
exposed to unauthorized material, before, during, or after testing, intentional
or accidental, you are expected to report it to `examsecurity@comptia.org`.

## What CompTIA permits

Neither the FAQ nor the educator policy explicitly says "original questions
written from published objectives are fine", and it is worth being honest that
no CompTIA page states that in those words. What they do state:

- Legitimate third-party training materials are acceptable, provided you do not
  create, post, or share real exam questions or answers.
- The trademark guidance explicitly approves describing your own materials as
  preparation for a named CompTIA certification.
- CompTIA publishes the objectives, the domain weightings, the question count,
  the duration, the scoring scale, and a description of PBQ formats. Material
  published for candidates to study from is material candidates may study from.

The line is clean once you see what is on each side of it. Their items are
confidential. Their objectives are published. Write from the second.

## Trademark rules

Concrete, and one of them changes what we already do.

| Rule | What it means here |
| --- | --- |
| "The name of any CompTIA certification must not be without the word 'CompTIA'" | The track name **must** be "CompTIA Linux+", not "Linux+". Current naming is correct and must stay that way. |
| No logo distortion; no logo in another mark | Do not use any CompTIA logo at all. Simplest compliance is to use none. |
| "No CompTIA Logo or Trademark may be used as a domain name or as a part of a domain name" | `rlwilliamson.dev` is fine. Never register anything with "comptia" or "linuxplus" in it. |
| "You may not use CompTIA's trademarks to promote any products or services not created by CompTIA" | Do not imply endorsement, affiliation, or official status anywhere. |
| Third parties cannot name products misleadingly | Do not title anything "CompTIA Linux+ Certification Course" or similar. "Study notes for the CompTIA Linux+ exam" is the safe construction. |
| Include a trademark notice | Add an attribution and disclaimer line. |

**Action:** add a footer line to the track index, coverage, plan, and practice
pages:

> CompTIA and Linux+ are trademarks of CompTIA, Inc. This site is not
> affiliated with, endorsed by, or sponsored by CompTIA. All practice questions
> are original work written from CompTIA's published exam objectives.

## What a PBQ actually is

CompTIA publishes this, and it is more specific than most people assume.

> Performance-based questions (PBQs) are exam items designed to test a
> candidate's ability to solve problems in real-world settings and are delivered
> as either simulations or within virtual environments.

Two delivery types, and they behave differently:

| | Simulation | Virtual environment |
| --- | --- | --- |
| What it is | "An approximation of an environment or tool, such as a firewall, network diagram, terminal window, or operating system" | "Virtual machines/systems running select operating systems and software in a production environment" |
| Functionality | Restricted, but "designed to allow for multiple possible responses or paths" | Full, so "all manner of incorrect steps or paths may be pursued" |
| Can you skip and return? | **Yes** | **No.** You must complete it then, and a warning screen says so first |
| Partial credit | Yes | Yes |

Two facts here matter for both our content and our practice engine:

1. **Partial credit exists**, for both types. "Partial credit may be given to
   virtual PBQs, as it is for simulation PBQs."
2. **Multiple correct approaches are anticipated.** "There can be multiple ways
   to solve a question or challenge posed in a PBQ. Scoring addresses different
   possible approaches."

What we can legitimately emulate: the *shape*. A scenario preamble, a system in
a described state, and a task with several requirements. That is what the
`scenario` field in the bank schema is for. What we cannot emulate is an
interactive terminal, and we have already decided not to try.

## Item-writing rules

The standard reference is Haladyna, Downing, and Rodriguez, whose revised
taxonomy sets out 31 guidelines validated against both textbook consensus and
empirical research. The ones that bite for a Linux+ bank:

**Content**

- Use novel material to test higher-level learning; paraphrase rather than
  lifting phrasing, so an item tests understanding rather than recognition.
- Base each item on important content. Avoid trivia.
- **Avoid trick items.** A question that hinges on a misread is not difficulty,
  it is noise.
- Keep items independent. One question must not answer another.

**The stem**

- Put the central idea in the stem, not spread across the choices. A reader
  should be able to answer before seeing the options.
- Word the stem positively. Avoid NOT and EXCEPT; if unavoidable, capitalise
  and bold them.
- Minimise reading. Cut window dressing. A scenario should carry only what the
  question needs, which is a discipline, not a word count.

**The choices**

- **Make every distractor plausible**, and preferably derive it from a real
  mistake. Guideline 30 is explicit: use typical errors to write distractors.
  For this track that means the failure modes already documented in each topic
  are the distractor source. A wrong option should be something somebody has
  actually typed.
- Keep choices homogeneous in content and grammatical structure.
- **Keep the length of choices about equal.** This is the one most likely to
  catch us: the correct answer tends to be longest because it is most precise,
  and length is a giveaway.
- Place choices in logical or numerical order.
- **Avoid "all of the above".** Use "none of the above" sparingly if at all; the
  evidence is that it mostly increases difficulty without improving measurement.
- Avoid clueing: specific determiners ("always", "never"), words echoed from the
  stem, grammatical mismatches, a conspicuously detailed correct answer, paired
  options that give the game away, and absurd throwaway options.
- Research suggests three good options beat four with one obvious filler. We use
  four to match the exam's feel, so the fourth has to earn its place. If you
  cannot write a fourth plausible distractor, the question is not ready.

Option order is shuffled on every attempt by the existing engine, which handles
the "vary the position of the correct answer" guideline for free.

## The authoring standard

Rules for every `linux-plus` question. These are the ones to hold yourself to.

1. **Write from the objectives and primary documentation only.** The objective
   list in `src/config/exams.ts`, man pages, and vendor documentation.
2. **Never consult a braindump, an "actual exam questions" site, or any dump of
   remembered items.** Not for inspiration, not to check coverage, not at all.
   This is the input rule that makes the output rule automatic.
3. **Never write from memory of a real exam**, yours or anyone else's.
   Reconstruction through memorisation is named in the Candidate Agreement.
4. **Cite the source of the fact being tested.** If you cannot point to
   documentation, you are testing folklore.
5. **Every distractor is a real mistake.** Preferably one already documented in
   the topic's "What trips people up" section.
6. **The explanation walks every option.** Why the right one is right and why
   each wrong one is tempting. An explanation that only justifies the answer
   teaches one fact; one that walks the distractors teaches four.
7. **No trick questions, no "all of the above", no negative stems** without
   capitalisation.
8. **Weight toward application and analysis.** The `difficulty` field exists for
   this. A bank that is mostly `recall` is not preparing anyone for a
   scenario-based exam.
9. **Never label anything as real, actual, leaked, or "seen on the exam".**
10. **Disclaim on every practice page.** Original items, written against the
    published objectives, not exam questions.

## What the build should enforce

Mechanical checks are worth more than good intentions. On top of the validators
already specified for phase 3:

| Rule | Check |
| --- | --- |
| No "all of the above" or "none of the above" | Fail on an option matching that text |
| Distractor length is not a tell | Warn when the correct option is more than roughly 1.5 times the mean length of the others |
| No negative stem without emphasis | Warn on a stem containing lowercase " not " or " except " |
| Explanations address distractors | Warn when an explanation is shorter than a floor, or does not mention any incorrect option |
| Cognitive level | Warn when a `linux-plus` bank is more than half `recall` |
| Banned phrasing | Fail on "actual exam", "real exam question", "braindump", "dump" in any field |

The last one is cheap and it makes the integrity rule structural rather than a
promise in a document.

## Two corrections to existing content

This research contradicted two things I had written about performance-based
questions. Both are corrected, and that material now lives in a collapsible
panel on the full practice exam page rather than in the teaching sequence, since
it is exam-day technique rather than Linux:

1. **I wrote that a partly-completed PBQ "can be nothing".** CompTIA states
   partial credit may be given, for both simulation and virtual PBQs. The
   correct framing is that partial credit exists but you should not rely on how
   it is apportioned.
2. **I advised flagging a PBQ and coming back.** That works for simulation PBQs
   only. Virtual PBQs cannot be revisited; you are warned first and must finish
   at that point. The advice has to distinguish the two.

Worth noting because both errors came from plausible secondary sources, and both
were caught by reading CompTIA's own page. That is the whole argument for the
source hierarchy.

## Sources

| Claim | Source | URL |
| --- | --- | --- |
| Confidentiality, reconstruction through memorization, ownership of exam materials | CompTIA Candidate Agreement | https://www.comptia.org/en-us/resources/test-policies/comptia-candidate-agreement/ |
| Definition of unauthorized materials; reporting obligation | CompTIA, Unauthorized Training Materials | https://www.comptia.org/en/resources/test-policies/unauthorized-training-materials/ |
| Unauthorized materials FAQ | CompTIA | https://www.comptia.org/en-us/resources/test-policies/unauthorized-training-materials-faq/ |
| Duties of educators publishing study material | CompTIA, Responsibility of Educators | https://www.comptia.org/en/resources/test-policies/educator-policy/ |
| Certification name must carry "CompTIA"; logo and domain restrictions; approved descriptive use | CompTIA, Using CompTIA Trademarks | https://www.comptia.org/en-us/legal/trademarks/ |
| PBQ formats, skippability, partial credit, multiple solution paths | CompTIA, Performance-Based Questions Explained | https://www.comptia.org/en-us/resources/test-policies/exam-development/performance-based-questions-explained/ |
| The 31-guideline item-writing taxonomy | Haladyna, Downing and Rodriguez, *A Review of Multiple-Choice Item-Writing Guidelines for Classroom Assessment* | https://site.ufvjm.edu.br/fammuc/files/2016/05/item-writing-guidelines.pdf |

Accessed 2026-08-07.

**This document is not legal advice.** It is a reading of CompTIA's published
policies, quoted so the reasoning can be checked. If a question ever arises
about whether specific material is acceptable, CompTIA directs people to
`examsecurity@comptia.org`, and asking is cheap.
