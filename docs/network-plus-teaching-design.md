# CompTIA Network+ track: teaching design

How the N10-009 material gets presented, and specifically where it must differ
from the Linux+ track rather than inheriting its shape. Companion to
[network-plus-n10-009-research.md](network-plus-n10-009-research.md), which
covers what is on the exam, and
[network-plus-topic-plan.md](network-plus-topic-plan.md), which covers what gets
written.

[linux-plus-teaching-design.md](linux-plus-teaching-design.md) still governs
everything not contradicted here: the audience decision, progressive disclosure,
concrete before abstract, defining the word before using it, the voice, and the
rules about analogies and dry wit. This document records only the deltas, and it
exists because the first Network+ plan was written by adapting the Linux+ shape
and several of those adaptations turned out to be wrong.

Researched 2026-08-09.

- [The thesis, and why the Linux+ one does not transfer](#the-thesis-and-why-the-linux-one-does-not-transfer)
- [The evidence for the change](#the-evidence-for-the-change)
- [What Prove it becomes](#what-prove-it-becomes)
- [What Try it becomes](#what-try-it-becomes)
- [Cross-track duplication](#cross-track-duplication)
- [Within-track scope drift](#within-track-scope-drift)
- [Diagrams](#diagrams)
- [Subnetting](#subnetting)
- [Question design](#question-design)
- [What we are deliberately not building](#what-we-are-deliberately-not-building)
- [Decisions taken](#decisions-taken)
- [Open questions](#open-questions)
- [Sources](#sources)

## The thesis, and why the Linux+ one does not transfer

Linux+ is organised around one sentence: **every topic teaches the configuration
and the proof that the configuration took.** It is load-bearing on that track
because almost every Linux+ scenario ends in a system state you produced, and
because verification is the thing nearly every competing resource skips.

It does not survive the move. Twenty-three of the seventy-six planned Network+
topics have no configuration to make and no state to inspect: cabling,
connectors, topologies, cloud service models, disaster recovery metrics, physical
installation, wireless radio behaviour, and most of the security concepts. The
plan nevertheless makes **Prove it** a required section, so a third of the track
would have shipped with the template's strongest section empty. That is precisely
the failure the section was added to prevent.

The replacement:

> **Linux+ teaches you to change a system and prove the change took. Network+
> teaches you to read a network you did not build and prove what it is actually
> doing.** Every topic carries evidence of one of three kinds, observed on the
> wire, derived by arithmetic, or sourced from a standard, and says on the page
> which kind it is.

Three reasons that is the right sentence rather than a softer restatement of the
old one.

It matches the exam's own bias. Compare and contrast, Explain and Summarize
account for 55.7 percent of N10-009 by weight, and every one of those verbs asks
for evidence rather than for a procedure.

It gives the conceptual third of the track an obligation instead of an exemption.
A cable category has a distance limit in a standard. A recovery point objective is
arithmetic. A screened subnet has a shape. None of those is a command and all of
them are checkable, which means the honesty rule can apply to every topic instead
of to fifty-three of them.

And it moves the honesty rule to where it actually bites. The Linux+ question is
"is this block captured". The better question, on a track where a third of the
content is conceptual, is "does this claim have anything behind it at all".

## The evidence for the change

The verb profile of the two objectives documents, counted rather than estimated:

| | XK0-006 | N10-009 |
| --- | --- | --- |
| Objectives | 29 | 25 |
| "Given a scenario" objectives | 18 | 10 |
| Scenario share by exam weight | 63.5% | 44.3% |
| "Compare and contrast" share by weight | none | 12.4% |

The per-domain spread matters more than the total. Domain 1 has seven of its
eight objectives on Explain, Compare and contrast, or Summarize. Domain 5 has four
of five on Given a scenario. **The two ends of this exam ask for different things,
and a uniform house style across all five domains would be wrong at both ends.**

The Linux+ banks sit at 11.6 percent recall, and `quiz-validate.ts` carries a
hardcoded warning string asserting "This exam is scenario-based". That string is
false for N10-009 Domain 1.

## What Prove it becomes

**Prove it stays exactly as written for the fifty-three topics that carry
captured output.** No change there.

For the twenty-three documented-only topics the heading stays and the content
widens. **Prove it takes one of three forms, and every topic uses at least one:**

| Form | What the section holds | Typical topic |
| --- | --- | --- |
| Run it | Commands, and what their output shows | Anything with a capture |
| Work it out | Arithmetic the reader can reproduce | Subnetting, DR metrics, power budgets |
| Look it up | A named clause in a standard or vendor document, and the question it answers | Cabling, connectors, wireless, physical installation |

The third form is the one that makes the section survive a topic with nothing to
run. It is not a reading list. It names the document, the clause, and a question
that only that clause answers, so a reader can go and check the page rather than
believe it.

What this does not become is per-claim provenance labelling in the prose. That is
a UI pattern with no design behind it and no precedent across the 77 existing
topics. The per-topic provenance line at the foot of the page already carries the
observed-versus-sourced distinction and it stays the only place that distinction
is drawn.

One correction to keep the framing honest: twenty-three of seventy-six is 30
percent of the topic count. Those objectives do not carry 30 percent of the exam
weight, and the document should not imply they do.

## What Try it becomes

The Linux+ form is a completion problem framed as "if you have a VM handy". The
Network+ reader has no switch, no access point, no fibre, no PoE injector and no
second building, so that framing fails for a large part of the track.

Three forms, chosen by what the topic actually is:

| Topic kind | Try it is |
| --- | --- |
| The 43 netlab topics | A committed topology file the reader can run, with one thing removed |
| Addressing and subnetting | Arithmetic to do, with the answer checkable against a named tool |
| The physical and conceptual topics | A specific document to go and read, with the clause named and a question only that clause answers |

The committed topology files are what make the first form real. They are in the
repository anyway, because a transcript that cannot be reproduced is not a
transcript.

## Cross-track duplication

The single largest thing the first plan did not decide. The Linux+ track already
carries roughly 60,000 words on ground the Network+ plan re-covers:

| Linux+ topic | Words | Network+ topics on the same ground |
| --- | --- | --- |
| `16-network-basics-addresses-and-routes` | 5,673 | 03, 07, 28 |
| `17-configuring-networking` | 5,210 | 25, 74 |
| `18-name-resolution-and-dns` | 4,941 | 45, 73 |
| `40-firewall-concepts-and-netfilter` | 7,068 | 60 |
| `41-firewalld-ufw-and-nftables` | 9,451 | 31, 60 |
| `43-ssh-and-secure-remote-access` | 9,690 | 50 |
| `47-cryptography-basics`, `48-tls-certificates-and-acme` | 21,733 | 52 |
| `63-how-to-troubleshoot` | 5,221 | 61, 62 |
| `71-network-connectivity-troubleshooting`, `72-dns-and-routing-problems` | 9,904 | 67, 68, 72, 73 |

The rule, decided 2026-08-09: **a Network+ topic is written complete, and carries
a see-also link to the Linux+ treatment where one exists.** Nobody is sent
elsewhere mid-explanation. Somebody studying for Network+ is sitting a different
exam and may never open the other track, so a topic that stops halfway and points
at a Linux page has failed them. The link goes at the foot, framed as further
depth rather than as a missing piece.

That costs roughly 40,000 words of overlap and it buys a track that stands on its
own. It also creates the obvious hazard, which is two pages that can drift apart
and eventually contradict each other in public. Two things keep that in check. The
overlap is concentrated in nine Linux+ topics rather than scattered, so the
surface is small enough to check by hand. And the two treatments are answering
different questions: Linux+ asks how you configure this on a RHEL or Debian
machine, Network+ asks what the protocol does and how you would know. Where they
overlap they should agree on the protocol and diverge on everything else, which is
easier to hold than a rule about not repeating yourself.

The linking itself is free. Both `prerequisites` and a question's `learnRef`
already resolve a qualified `track/slug` across tracks, and the build fails on a
reference that does not land. Neither track uses that today.

Worth doing in the other direction once the Network+ topics exist. A Linux+ reader
who arrives at the DNS topic from a search should be told the vendor-neutral
treatment is there.

## Within-track scope drift

The rule above governs two tracks colliding. This one governs a track colliding
with itself, which turned out to be the more likely of the two.

Topic 05 was scoped to teach the eight legal mask octet values and the powers of
two. What got written also included a boundary walkthrough, six named pitfalls,
and a worked block-size example. All of that was good for the reader and none of
it was wrong. It was also most of topic 06, and the plan row for topic 06 went on
saying it would teach the block-size method to fluency, because nothing updates a
row when the previous topic quietly annexes it.

Caught by rereading both before starting to write. That is not a control, it is
luck, so the rule is:

**Before writing topic N, check its row against what topic N-1 shipped, not
against what topic N-1's row promised.** Read the previous topic's headings. If
the next row asks for something already taught, the row is stale and gets fixed
before a word of the topic is written, not after.

Two things follow from that.

Fix the row rather than the finished topic. The written page is the better
evidence of what a reader needs, and the earlier topic is already published and
linked. Rewriting it to protect a plan that was drafted before either page
existed gets the authority backwards.

Where the split is not obvious, split by direction rather than by subtopic. Topic
05 and topic 06 both live in objective 1.7 and both do arithmetic on masks, so
any list of subtopics divided between them would have been arbitrary and would
have leaked. Reading a prefix you were handed against creating prefixes from a
requirement is a line a writer can apply to a sentence they have not written yet.
The same shape is available elsewhere: reading a capture against producing one,
diagnosing a symptom against designing so it cannot happen.

The plan carries the ownership note in topic 06's own row, in bold, rather than
only here. A rule in this document is read once during planning. The row is the
thing open on screen at the moment the mistake would be made.

## Diagrams

Twenty-one planned diagrams becomes about twenty-nine, and the count is not the
interesting part. Three rules are.

**Floors, committed as constants rather than as prose.** Text fill-opacity floor
of 0.65, which measures 5.31:1 in light and 6.97:1 in dark. Minimum font size of
11 user units. A stroke-opacity floor above 0.5, because 0.5 measures 3.31:1
against a 3:1 requirement and leaves no margin. Eighty-nine text nodes in the
existing Linux+ diagrams sit below the opacity floor, so this is a real number
rather than a theoretical one.

**Colour is never the only channel.** Every distinction a diagram draws must also
be carried by a dash pattern, a label, or a shape. This track's diagrams are
distinctions in a way the Linux+ ones are not: forwarding against blocking,
tagged against untagged, inside against outside, split against full tunnel,
trusted against untrusted. Each of those is a place an author reaches for red and
green, and roughly one man in twelve cannot read that pair. It cannot be linted,
which is exactly why it belongs next to the numbers that can be.

**The long description moves out of `<desc>` and into the `<figcaption>`.** Of 78
pagefind fragments, the figcaption string appears in one and the tested `<desc>`
phrase in none, so roughly 2,300 words of diagram description are currently
invisible to the site's own search. A visually-hidden div is the cheaper
alternative and should be tested first, since pagefind indexes the built DOM
without evaluating CSS.

Hand-author, do not generate. A primitive library spanning swimlanes, byte
strips, bit rulers, orthogonal routing and a frequency chart is 1,200 to 2,500
lines against a repository whose largest non-test file is 188, and only four of
the twenty-one planned diagrams are topology graphs at all. Reuse beats
generation: topic 07's bit ruler serves 08 and 09, and the OSI ladder is drawn
once and reused in 02, 03, 24 and 62 with different parts signalled.

No animation and no interactivity. The honest number for animation is a small
positive effect, Hedges g = 0.226 across 140 comparisons, significantly weaker for
abstract representations. That is not nothing, and it is not worth a video
pipeline on a static site.

## Subnetting

**Do not build a generator.** The instinct was to build one, because subnetting is
the one genuinely procedural skill on this exam and the site has no way to give a
reader repetition. Five free unlimited generators already exist, none requires an
account, and the best of them validates five fields independently and ships a
free worked-solution video series. The project already ruled the same way on labs
in `linux-plus-study-tool-research.md`: SadServers does it better, link to it.

What replaces it is an authoring rule with teeth. **Every objective 1.7 question
must have all distractors be the product of a named arithmetic error**: mask
boundary off by one bit, network address given instead of first usable, broadcast
instead of last usable, host count computed with or without the two reserved
addresses. The explanation names which error each distractor represents. That
kills elimination as a strategy, which is the actual failure mode of a
badly-written subnetting item, and it is enforceable by review.

Teach one method to fluency, the magic number. Comparison across methods helps a
learner who already knows one and needs the pace slowed for a novice who knows
neither.

Binary moves out of a DEEPER panel and into the main flow of topic 07. It is not
optional depth on this exam; it is how the mask is read.

Two claims in the first plan were unsourced and are struck. CompTIA publishes no
per-objective performance data, so "the single most reliable place candidates lose
marks" cannot be supported. And "without a calculator under time pressure"
overstates what is known: for online-proctored delivery CompTIA provides a digital
whiteboard and prohibits physical writing materials, and publishes nothing about a
calculator either way.

## Question design

The authoring standard does not apply unchanged, which is what the first plan
claimed. Five amendments, all specific to this exam:

**Per-domain difficulty targets, seeded from topic allocation rather than from
objective counts.** Objective count gives Domain 1 a 12.5 percent scenario share,
topic count gives 19 percent, and applying both produces a validator that cannot
satisfy its own targets. Topic count wins because it reflects the teaching that
actually gets written. The document must say that objective verb is being used as
a proxy for item cognitive level and that CompTIA publishes no such mapping.

**Fix the hardcoded warning string** in `quiz-validate.ts` that asserts the exam
is scenario-based. It is false for Domain 1 of this exam.

**A multiple-response floor**, concentrated on the four Compare and contrast
objectives. CompTIA states for Network+ specifically that the multiple-choice
questions are single- and multiple-response. That path is exercised by two of 276
Linux+ questions and has no test coverage at all.

**The objective 1.7 distractor rule** above.

**A diagram-anchor requirement** for the objectives whose content is visual:
questions on 1.2, 1.5, 1.6, 3.5 and 3.1 carry a `learnAnchor` resolving to a
heading that contains a diagram, with a stem answerable only by having read it.

The banks themselves are unchanged: five, one per domain, 273 questions, pool
multiple of three. One footnote is needed on the plan's table, because the
per-domain shares sum to 91 and the exam is 90 questions. See
[the plan's infrastructure section](network-plus-topic-plan.md) for the
`weightedShares` fix that follows from it.

## What we are deliberately not building

Stated so it does not get relitigated.

- **A subnetting drill.** Covered above.
- **A diagram generator**, in either proposed form.
- **A `figure` field on the question schema.** The bank is serialised through
  `JSON.stringify` into a script tag with every text field escaped, so this is not
  a schema field plus a render line. `learnRef` and `learnAnchor` already deep-link
  a wrong answer to the heading that holds the diagram.
- **A constructed-response or numeric question type.** CompTIA's Network+
  statement names multiple choice, drag-and-drop and performance-based, and does
  not name fill in the blank. Free-text subnet grading is a false-negative machine
  across notation variants.
- **An ordering or matching item type.** Say on the exam page that the real exam
  includes drag-and-drop activities this engine does not reproduce.
- **A `/ports` route.** Putting CompTIA's own two-column protocol and port table
  on a standalone page stripped of teaching is much closer to the thing this repo
  forbids than the same table inside topic 13 is.
- **A `/glossary` route.** 490 entries with 48 duplicate terms and no
  disambiguation policy, and the acronym-coverage check it promised needs the
  appendix the repo already refuses to store.
- **Mnemonics**, and no paragraph explaining why not. The keyword method is rated
  for keyword-friendly verbal material; port numbers are numeric.
- **A print stylesheet, yet.** A real gap, and dead work until a page exists to
  hang it on.

## Decisions taken

| Question | Decision | Date |
| --- | --- | --- |
| Does the Linux+ thesis transfer | No. Replaced with the three-kinds-of-evidence framing above | 2026-08-09 |
| Prove it on documented-only topics | Same heading, three forms: run it, work it out, look it up | 2026-08-10 |
| Try it without hardware | Three forms: run the topology, do the arithmetic, read the named clause | 2026-08-09 |
| Cross-track duplication | Write Network+ self-contained, with a see-also link to the Linux+ treatment at the foot | 2026-08-09 |
| Within-track scope drift | Check row N against what topic N-1 shipped, and fix the row rather than the written topic | 2026-08-10 |
| Subnetting generator | Do not build. Link out, and enforce the distractor rule instead | 2026-08-09 |
| Diagram production | Hand-author with committed constants and lint assertions. No generator | 2026-08-09 |
| Diagram descriptions | Into the figcaption, out of `<desc>` | 2026-08-09 |
| Windows column in comparison tables | Captured on a GitHub Actions windows-latest runner, not sourced. Overturned 2026-08-10 | 2026-08-10 |
| Question authoring standard | Amended per track, not applied unchanged | 2026-08-09 |
| Animation and interactivity | Neither | 2026-08-09 |

## The Windows column

The research concluded that the Windows column in every comparison table would
have to be sourced from documentation, because this project has no Windows
machine and none is reachable from an arm64 Mac without a licence question.

That was wrong, and it was wrong because nobody checked whether a Windows host
was available rather than owned. **A GitHub Actions windows-latest runner is a
real Windows host**, it is free on a public repository, and its image version is
published. So a Windows transcript can be pinned and reproduced on the same terms
as a Linux one.

`blog/scripts/hostcap.sh` triggers the capture and prints a pasteable block. The
commands live in committed scripts under `blog/scripts/windows/`, so a reader can
see exactly what produced the output, and editing one regenerates its transcript
rather than leaving a stale one behind.

Proven on 2026-08-10 against Windows Server 2025, runner image 20260803.193.1:
`ipconfig`, `ipconfig /all`, `arp -a`, `route print`, `netstat -ano`, and the
`Get-Net*` cmdlets all returned real output.

Three limits, and topics have to respect them.

The runner is one machine with no second host and no control over its own
topology, so anything needing two machines, a switch, or a chosen address plan
stays on `netlab.sh`. The Windows column gets host-tool output; it does not get
scenarios.

The transcripts are not byte-reproducible. The runner's hostname, its Azure DNS
suffix and its MAC address differ on every run, unlike the namespace captures
where the topology fixes them. A topic quoting a Windows block should not build a
point on a value that varies.

And `workflow_dispatch` only works once the workflow is on the default branch, so
until this merges, captures run through the push trigger scoped to the capture
paths.

## Two rules the reorder taught

**Never reference a topic by its position.** Topic 02 shipped saying a subject was
"the next topic's business", and it stopped being true the moment the reading
order changed, because the topic that had been next moved seven places. Name the
subject, or say later in the track. The reorder moved seventy of seventy-six
topics, and a positional promise is guaranteed to rot.

**Across platforms has two shapes, not one.** The plan fixed the columns as Task,
Vendor CLI, Linux, Windows. That is right for a switching or routing topic, where
the comparison genuinely is a device command against a host command. It is wrong
for a host-tool topic, where the vendor column would be empty and the interesting
comparison is between operating systems. So:

| Topic kind | Columns |
| --- | --- |
| Host tools | Task, Linux, Windows, macOS |
| Device commands | Task, Vendor CLI, Linux, Windows |

Four columns either way, which keeps the shared geometry the convention exists
for. What changes is which four, and the exam contains both comparisons, so
forcing them into one table produces empty cells rather than consistency.

macOS earns its column in the first shape because it is BSD and differs from
Linux in a way that bites: `ifconfig` is deprecated on Linux and is the current
tool on macOS, so the exam's own named command behaves opposite to the Linux
habit this track otherwise teaches.

## Open questions

**Where the question-authoring amendments live.** The shared document is called
`linux-plus-question-authoring-standard.md` and ten of its lines are
Linux-specific, but its copyright, trademark and prohibited-input sections
genuinely are shared and must not drift into two copies. Either rename it and add
a per-track appendix, or add a delta document that cites it. Not deciding means
they drift.

**`mac80211_hwsim`.** The kernel's software radio simulator is the only thing that
could move any of the five wireless topics off documented-only. `modinfo` says it
is not present on the podman machine today, and whether Fedora CoreOS can layer it
is unexplored. Worth an hour before block C.

**Objective 1.3.** A namespace with an nftables NAT gateway and an nftables set is
arguably a demonstration of an internet gateway and a security group, which would
move cloud off documented-only. Untested, and worth twenty minutes.

**Topic 57 and the attack-demonstration rule.** The research document says the
track will not demonstrate ARP poisoning. The plan marks topic 57 netlab and
promises a poisoned neighbour table in its DEEPER panel, which cannot be captured
without doing the thing. The resolution is that the capture is the evidence half
only, a neighbour table showing two addresses on one MAC, produced with a static
entry rather than with an attack, and the attack stays described. Confirm that.

## Sources

| Claim | Source | URL | Accessed |
| --- | --- | --- | --- |
| Simulation PBQs can be skipped and revisited; work is saved; partial credit may be given | CompTIA, Performance-Based Questions Explained | https://www.comptia.org/en-us/resources/test-policies/exam-development/performance-based-questions-explained/ | 2026-08-09 |
| Objective verbs and domain weights | CompTIA Network+ N10-009 Exam Objectives, version 4.0 | https://comptiacdn.azureedge.net/webcontent/docs/default-source/exam-objectives/comptia-network-n10-009-exam-objectives-(4-0)-(1).pdf | 2026-08-09 |
| Animation against static graphics, Hedges g = 0.226 | Berney and Betrancourt, Does animation enhance learning? Computers and Education 101, 150-167 (2016) | https://doi.org/10.1016/j.compedu.2016.06.005 | 2026-08-09 |
| Colour must not be the only visual means of conveying information | W3C, WCAG 2.2 Success Criterion 1.4.1 Use of Color | https://www.w3.org/WAI/WCAG22/Understanding/use-of-color.html | 2026-08-09 |
| Long descriptions belong in visible text near the image | W3C WAI, Complex Images tutorial | https://www.w3.org/WAI/tutorials/images/complex/ | 2026-08-09 |
| Free unlimited subnetting practice with worked solutions | subnetipv4.com | https://subnetipv4.com/ | 2026-08-09 |
