# CompTIA Linux+ track: teaching design

How the XK0-006 material gets presented so it teaches, rather than restating what
CompTIA already published. Companion to
[linux-plus-xk0-006-research.md](linux-plus-xk0-006-research.md), which covers
what is on the exam. This document covers what to do about it.

A second research pass, covering the competitive landscape and what to change,
is in [linux-plus-study-tool-research.md](linux-plus-study-tool-research.md).
Read that one for the ranked list of additions; this one for how a topic is
written.

The topic-by-topic plan, all 77 of them, is in
[linux-plus-topic-plan.md](linux-plus-topic-plan.md).

- [The thesis](#the-thesis)
- [What is wrong with the existing material](#what-is-wrong-with-the-existing-material)
- [What the evidence supports](#what-the-evidence-supports)
- [Nine design decisions](#nine-design-decisions)
- [Where output comes from](#where-output-comes-from)
- [The topic page](#the-topic-page)
- [Practice design](#practice-design)
- [Routes this implies](#routes-this-implies)
- [What not to build](#what-not-to-build)
- [Voice](#voice)
- [Build order](#build-order)
- [Sources](#sources)

## Who this is written for

**Somebody who has never opened a terminal.** Not a practitioner. That is a
change from the first version of this document, made deliberately on 2026-08-07,
and it revises several decisions below rather than sitting alongside them.

The test: Ryan should be able to send a topic to a family member who has never
touched Linux, and they should be able to follow it. Everything else is
secondary to that.

Experienced administrators are served by **progressive disclosure**, not by
writing to them in the main flow. Depth goes behind a `DEEPER` panel that a
beginner can skip and an admin opens. The evidence here is unusually strong and
unusually old: roughly four decades of it says novices learn faster and make
fewer errors under progressive disclosure while experts pay a single click.

### What this reverses

| Earlier decision | Now |
| --- | --- |
| "Completion problems, not worked examples," on the expertise reversal effect | **Backwards for this audience.** Expertise reversal says worked examples help novices and stop helping experts. A beginner needs the fully worked example in the main flow. The completion problem moves to the optional "Try it", where the reader has self-selected as more capable. |
| "Nothing gets explained twice, and nothing gets explained down to" | Wrong framing. Nothing gets explained *condescendingly*. Everything gets explained *once, properly*, including the words. |
| "Audience is a practitioner" | The audience is a beginner. The practitioner is a second reader served by panels. |

The tension worth naming: CompTIA recommends twelve months of hands-on
experience for this exam. Writing for somebody at zero means the track has to
carry them the whole distance, which is more content than a cram guide. That is
the trade, and it is the right one for something described as a teaching tool
rather than an exam summary.

### The rules that follow

**Concrete first, then the general rule.** Concreteness fading is well supported:
learners who go concrete-to-abstract outperform those given either alone. So
never open a section with the abstraction. Open with one specific case somebody
can picture, then generalise from it. The filesystem topic now starts with where
a web server puts its three files, not with "static versus variable".

**Define the word before you use it.** Expert blind spot is largely a vocabulary
problem: experts compress steps and skip terms that have become invisible to
them. A `terms` list at the top of a topic, or an inline definition on first use,
costs a line and removes the most common reason somebody quietly gives up.

**Analogies get a stated limit.** They measurably help novices and are described
in the literature as double-edged: a misaligned analogy creates misconceptions
that are hard to detect later. So an analogy is always followed by where it
breaks down. "Like Program Files, except nothing on the running machine writes to
it" is safe. "It's basically Program Files" is not.

**Explain the mechanics of the shell once, early.** New users are reliably
tripped by option syntax being inconsistent: `-l`, `--long`, and commands that
accept neither. Say that out loud once rather than letting it be a recurring
small confusion.

**Assume no Windows knowledge either, but use it when it helps.** A comparison to
Windows is a useful bridge for many readers and meaningless to others, so it can
illustrate but never carry the explanation.

## The thesis

From your own resume:

> Building and operating controls is one half of security engineering.
> Validating that they actually work is the other, and that is where I am headed.

That sentence is the organizing principle for the whole track. **Every topic
teaches the configuration and the proof that the configuration took.** Not "here
is how to set up firewalld" but "here is how to set up firewalld, here is the
command that proves the rule is live rather than staged, and here is what the
output looks like when it is not."

This is not a stylistic preference. It is load-bearing in three directions at
once:

1. **It matches how XK0-006 tests.** Performance-based questions ask you to do a
   thing and then are scored on system state. A reader trained to check state has
   been trained for the question format.
2. **It matches your background.** The FedEx line ran inside ISO 9001: certified
   procedures, documented actions, routine audits. You already think in terms of
   "the procedure exists" versus "the procedure is being followed" being two
   different facts.
3. **It is the gap in the market.** Every Linux+ resource teaches configuration.
   Almost none teach verification, because verification is boring to write and
   requires actually running the thing.

D3CYPH3R already encodes the same instinct: commands are evaluated rather than
answer-matched, so a malformed payload returns the genuine MySQL error.

**This track is not a second D3CYPH3R.** No interactive terminal, no evaluated
commands, no lab environment, no simulated shell. It is study material: prose you
read and questions you answer. The thing borrowed from D3CYPH3R is the standard
of honesty about output, not the machinery.

## What is wrong with the existing material

Worth naming, because the design decisions below are all responses to it.

| Failure | What it looks like | Why it persists |
| --- | --- | --- |
| Objective restatement | The page is CompTIA's bullet list with each bullet expanded into a paragraph | It is fast to write and looks like coverage |
| One-distro monoculture | Everything is Ubuntu, or everything is RHEL, and the exam is neither | Author only has one lab |
| Invented output | Terminal blocks that were typed by hand, not pasted from a session | Nobody checks, and real output is untidy |
| Version rot | Commands that were right in 2019 | No date, no distro, no way to tell |
| Configuration without verification | Ends at "now restart the service" | Verification requires a working system |
| Blocked practice only | Domain-by-domain question sets, never mixed | Easier to organise, and it feels better to the reader |
| Answer-key explanations | "B is correct because B is the definition" | Writing a real explanation takes longer than writing the question |

The last two are the ones the practice engine can fix structurally rather than by
being careful.

## What the evidence supports

Six findings from the learning-science literature that actually change what gets
built. Full citations in [Sources](#sources).

**Retrieval beats rereading.** Roediger and Karpicke: repeated testing produces
substantially better retention than repeated study at delays of days to weeks,
even though rereading feels more productive at the time. Practice cannot be an
appendix at the end of the track.

**Failing a question before you learn the answer helps.** The pretesting effect:
attempting retrieval before instruction improves later encoding *even when the
attempt fails*. The error primes attention and binds the correction to it. This
is nearly free to implement and almost nobody does it.

**Worked examples stop helping once you have experience.** The expertise reversal
effect: heavy worked examples help novices and become redundant or actively
counterproductive as prior knowledge grows. XK0-006 assumes twelve months of
hands-on Linux. Your audience is people who already run production systems. Fully
worked examples are the wrong default here; completion problems are the right
one.

**Mixed practice teaches discrimination; blocked practice hides it.** Rohrer and
Taylor: when every problem in a set uses the same procedure, the learner never
has to *choose* a procedure, so the set trains execution and not selection. In
one study interleaved practice produced 77 percent against 38 percent for blocked
practice on a delayed test. Domain-by-domain question banks are blocked practice.

**Feedback timing does not matter much.** A 2026 meta-analysis across 51 studies
and 160 effect sizes found feedback timing did not significantly influence
learning outcomes on average. The existing immediate-versus-review choice is
fine. Do not spend engineering effort tuning it and do not claim either mode is
better.

**Experts reason forward from symptoms; novices run checklists.** The diagnostic
reasoning literature is consistent: experts pattern-match from a small number of
salient findings and then confirm, while novices work exhaustively through
procedure. Teaching a linear troubleshooting methodology trains novice behavior.
Given Troubleshooting is 22 percent of the exam, this is the single most
important finding in the list.

**Mixing documentation modes on one page hurts the reader.** Diataxis separates
tutorial, how-to, reference, and explanation on two axes: action versus
cognition, and study versus work. A study note is legitimately explanation plus
tutorial, but reference-shaped content (option tables, command lists, distro
matrices) still needs to be visually separate from prose rather than woven
through it.

## Nine design decisions

### 1. Verification is a required section, not a nice-to-have

Every topic ends its instructional body with **"Prove it"**: the commands that
show the change took effect, with real output for both the working and the
not-yet-working state. A topic without one does not ship.

### 2. Every transcript is labeled with the distro it came from

See [where output comes from](#where-output-comes-from). Captured output gets a
real distro and architecture label; output that could not be captured is sourced
from documentation and says so.

### 3. Open with a question the reader cannot answer yet

A short block before the body: a symptom, a command output, or a scenario, and
one question. The answer is not adjacent. It surfaces in the body where it is
earned. This is the pretesting effect, and it costs about four lines per topic.

It also happens to be how you already write. Your resume does not open with a
definition of DevOps; it opens with what the job actually is.

### 4. Two exercises: one to read, one to run

Every topic ends with both, because the track has to work for someone reading on
a phone and for someone sitting at a terminal.

**Work it through** is readable and required. A scenario, the reasoning walked
out on the page, and the answer. Nothing to install. This is the one that carries
the load, because most study happens away from a keyboard.

**Try it** is a completion problem and explicitly optional. Most of a working
configuration, the discriminating step removed, and the verification command that
tells you whether you got it. Framed as "if you have a VM handy". Expertise
reversal says a completion problem beats another fully worked example for an
audience that already administers systems.

The reader who skips every "Try it" still gets a complete topic.

### 5. Troubleshooting topics are organised by symptom, not by procedure

Not "the seven steps of troubleshooting". Instead, for each symptom:

- **What you see** - the actual error text or metric
- **What it could be** - the two to four hypotheses that produce that symptom
- **The one command that tells them apart** - the discriminating test
- **What each outcome means** - and where to go next

This is forward reasoning made explicit, which is the thing novices lack and
cannot get from a checklist.

### 6. Failure modes carry real error text

Three or four per topic, each with the message as it actually appears, what it
means, and what produces it. Searchable error strings are also the single highest
value thing a page can contain: somebody pastes an error into a search engine and
lands on the explanation.

### 7. Reference content is visually separate from prose

Option tables, command matrices, and cross-distribution comparisons render as
tables with their own treatment, not as sentences. Diataxis: reference and
explanation serve different needs and blending them degrades both.

### 8. Retrieval questions render on the topic page

The `learnRef` field you specified points a question at a topic. Invert that index
at build time and a topic page can render its own three-to-five questions at the
end, drawn from the same bank that feeds the practice sets. One authoring effort,
two placements, and retrieval stops being something the reader has to navigate to.

### 9. Mixed practice is the default; per-domain practice is labeled diagnostic

The domain banks stay, because they are how you find a weak area. But the landing
copy should send a reader who is studying toward a mixed set, and the per-domain
sets should say plainly what they are for. The interleaving evidence is strong
enough that shipping only blocked practice would be a defect.

## Where output comes from

No fictional hostnames, no narrative environment. Transcripts are labeled with
the distribution and architecture they actually came from, which is what the
brief asked for and is simpler than inventing a setting.

Output has two provenances, and a topic never blurs them.

**Captured.** Run in a pinned container and pasted in verbatim. Tooling lives in
`blog/scripts/`: `distros.json` pins four images by digest, `capture.sh` runs a
command and emits a ready-to-paste block labeled with the distro and arch.

| Key | Distribution | Covers |
| --- | --- | --- |
| `alma` | AlmaLinux 10 | RHEL family: `dnf`, `rpm`, SELinux userspace |
| `debian` | Debian 13 (trixie) | `apt`, `dpkg`, and everywhere Debian is not Ubuntu |
| `ubuntu` | Ubuntu 24.04 LTS | `apt` plus the Ubuntu-only pieces: netplan, ufw |
| `suse` | openSUSE Leap 16.0 | `zypper`, the third package manager |

Captures default to x86_64, because that is the context the exam assumes and
because architecture leaks into output. `--arch arm64` is there when the
aarch64 answer is the point.

This reaches further than it sounds: package management, users and groups,
permissions and ACLs, file and directory tooling, processes, text processing,
shell scripting, Python, Git, and most of the systemd command surface all work.

**Documented.** Everything needing a real kernel, boot, block devices, or
hardware: the boot chain, kernel modules, LVM and RAID, filesystem repair,
hardware discovery, firewalld and nftables against a live netfilter, virtual
machines. These get output sourced from man pages and vendor documentation, and
the block says which distribution it applies to without claiming a capture.

The rule that matters: **nothing gets typed into a code fence from memory.** A
block is either captured or sourced. If it is neither, it does not ship.

That rule earns its keep immediately. `dpkg -S /bin/ls` fails on Debian 13
because usr-merge means the package database records `/usr/bin/ls`. Written from
memory, that example would have been wrong and would have taught a reader
something false.

## The topic page

Revised from your nine-part list, with the research folded in. Changes from your
original are marked.

| # | Section | Notes |
| --- | --- | --- |
| 1 | **Before you read** | *New.* One question the reader cannot yet answer. Pretesting effect. |
| 2 | **What breaks without this** | Your "what this solves", framed as consequence. Opens on the situation, not the definition. |
| 3 | **The mental model** | *New, for structural topics only.* The SVG diagram plus the two paragraphs that make it readable. |
| 4 | **Minimum working example** | Unchanged. Stays fully worked; it is the anchor. |
| 5 | **How it actually behaves** | Unchanged. Real transcribed output. |
| 6 | **Across distributions** | Promoted to its own section. Table, not prose. |
| 7 | **Prove it** | *New, required.* The verification commands and their output. |
| 8 | **What trips people up** | Three or four, each with real error text. |
| 9 | **Work it through** | *New.* A scenario reasoned out on the page. Readable, required, nothing to run. |
| 10 | **Try it** | Your exercise, now a completion problem with a verification step, and explicitly optional. |
| 11 | **Check yourself** | *New.* Three to five retrieval questions rendered from the bank. |
| 12 | **References** | Unchanged. Deep links, access dates. |

Troubleshooting topics substitute a symptom table for sections 4 through 8, since
the subject is diagnosis rather than configuration.

Section 3 is the one to be disciplined about. A diagram earns its place when the
concept is structural and the reader cannot hold it in their head: the LVM stack,
Netfilter hook order, the boot chain, permission bit layout. It does not earn its
place for a list of commands.

## Practice design

Everything you specified in phase 3 stands. Four additions from the research:

**A mixed set is the default entry point.** `/learn/linux-plus/practice/mixed`
samples across all five domains without the weighting or the timer. It is the set
a studying reader should be doing most days. The weighted 90-question exam is for
readiness checks, not daily practice, because a 90-minute timer is a poor daily
habit.

**Per-domain sets carry a one-line frame.** Something like: "Domain sets are for
finding weak areas. Once you know where you are weak, mixed practice is what
fixes it." Honest, short, and it stops the reader from mistaking a comfortable
85 percent on a blocked set for readiness.

**Explanations answer "why not the others".** The existing Security+ bank already
does this well; it is the standard to hold. An explanation that only justifies
the correct answer teaches one fact. One that walks each distractor teaches four.
This is where distractor quality and explanation quality are the same problem.

**"Drill this objective" nudges back to mixed.** The drill is remediation and it
is deliberately blocked practice, which is correct for closing a specific gap.
The results screen for a drill should end by pointing back at mixed practice
rather than at another drill.

On the scaled score: state plainly that it is a linear approximation, because
CompTIA does not publish its scaling function. A reader who takes 720 as gospel
and misses by 30 points will trust nothing else on the site.

## Routes this implies

Beyond `/learn/linux-plus/coverage`, which is already specified.

| Route | What it does | Derived from | Priority |
| --- | --- | --- | --- |
| `/learn/linux-plus/symptoms` | Symptom index: observable symptom to the topic that explains it | A `symptoms` frontmatter array | High. This is the forward-reasoning artifact and nothing else in the Linux+ space has one. |
| `/learn/linux-plus/practice/mixed` | Interleaved set across all domains | Existing banks | High. The interleaving evidence makes this close to mandatory. |
| `/learn/linux-plus/commands` | Command index: which topic teaches `lvextend`? | A `commands` frontmatter array | Medium. Genuinely useful, cheap once the array exists, but it is schema growth. |

The symptom index deserves the most thought. It is the page a reader lands on at
2am when something is broken, and it is the page that makes the track useful to
somebody who never intends to sit the exam. That is the difference between study
notes and a tool.

Both new frontmatter arrays should default to empty so nothing existing breaks,
same pattern as `sources` and `examObjectives`.

## What not to build

Stated explicitly so it does not get relitigated:

- **Spaced repetition scheduling.** Requires persistence. You ruled out storage,
  accounts, and a backend, and those are the right calls for this site.
- **Progress tracking or completion state.** Same reason.
- **Anything keyed to learning styles.** No evidential support.
- **Feedback-timing experiments.** The meta-analysis says the effect is not there.
  Keep both modes because readers prefer having the choice, not because one wins.
- **Video.** Wrong medium for command output, and it cannot be searched, cited,
  or corrected in a pull request.
- **A confidence slider on questions.** Adds authoring burden and UI surface for a
  signal the miss-count already gives you.

## Voice

Drawn from the resume, which is the best sample of how you actually write.

**The signature construction is the contrast.** You use it constantly, and it is
the thing that makes the writing sound like a decision rather than a description:

> treating security and governance as first-class engineering concerns **rather
> than** late-stage afterthoughts

> reducing repeat incidents through systemic fixes **rather than** tactical
> patches

> Treated safety and consistency as defaults **rather than** afterthoughts

> The accuracy bar was set by the end customer, **not by us**.

**You correct a likely misreading head-on rather than hedging around it:**

> The security work is not a side interest. It has been part of the day job for
> years, done without a security title.

That is exactly the register for the moment in a topic where the reader is about
to believe something wrong. Not "it is worth noting that" - just the correction,
flat.

**Concrete over abstract, always.** The resume never says "improved quality". It
says "reduced rework on cosmetic defects" and "down to the BIOS settings, the
white-label branding, and the cosmetic inspection". Applied to Linux: not "this
can cause problems" but "the mount succeeds, the service starts, and the data
lands on the root filesystem instead of the volume you built for it."

**Stakes get named plainly, once, without drama:**

> all operated in a regulated environment where tax data raises the stakes

**Ownership verbs.** Owned, built, operated, drove, designed, partnered. In
instructional prose this becomes the second person doing the same: you run, you
check, you get back.

**Audience is a practitioner.** D3CYPH3R is "built for DevOps engineers, SREs,
and sysadmins who already run production systems and need the security half of
the job." Same audience here. Nothing gets explained twice, and nothing gets
explained down to.

### Dry wit, in small doses

The resume is deliberately flat because it is a resume. Teaching prose can carry
more, and should: a page with no human in it reads like generated filler, which
is exactly what this track is trying not to be.

The register is **dry understatement about the situation**, never a joke
interrupting the explanation. It works best pointed at the failure, the tooling,
or your own past mistakes. Never at the reader.

What it looks like:

> `chmod 777` on the file changes nothing when the denial came from a directory,
> so the next escalation is `chmod -R 777` on the tree, and now you have a
> permissions problem *and* a security finding.

> There is a version of this topic that lists twenty directories and what they
> hold, and you would forget it by Thursday.

> The file being world-readable is true and irrelevant.

> If you find it set, ask what set it before you clear it.

The shape is usually a flat sentence that lands one beat after you expect it to
stop. It is the ISO 9001 auditor's sense of humour: nothing is exaggerated, the
funny part is that the situation is genuinely like that.

What it is not: exclamation marks, "fun fact", winking asides, self-deprecation
as filler, or a joke that has to be read twice. If a line makes the technical
point *and* raises an eyebrow, keep it. If it only raises an eyebrow, cut it.

Rough dose: one or two per topic, and none at all in a section where somebody is
actively debugging something broken.

### Rules

- No "simply", "just", "easy", "obviously", "of course". If it were easy the
  reader would not be reading.
- No exclamation marks. No emoji. No Unicode arrows. ASCII only, enforced by the
  route tests.
- Second person, present tense, active voice.
- Sentences carry one idea. The resume's longest sentences are lists of specifics,
  not stacked clauses.
- Comments inside code blocks do teaching work, not narration. `# staged, not
  live - this is the line people miss` beats `# run the command`.
- Numbers are exact or absent. No "significantly faster".
- Never claim something was verified that was not. If a command was not run on
  `db01`, it does not get a `db01` prompt.

## Build order

Phase 2 as you scoped it, with one reordering.

1. Capture tooling. **Done**: `blog/scripts/distros.json` and
   `blog/scripts/capture.sh`, four images pinned by digest.
2. Schema extension (`examObjectives`, `sources`, plus `symptoms`), the
   cite-if-you-claim build rule, and `CONTRIBUTING-learn.md` updates.
3. Coverage page and link checker.
4. Two topics as the pattern. Recommend `01-linux-fundamentals-and-the-fhs` and
   one troubleshooting topic, not two adjacent ones. The troubleshooting topic
   uses the symptom structure, which is the part of this design most likely to
   need revision once it exists on a page.

Then stop, as planned.

## Sections or separate topics?

An objective's sub-parts are **headings inside one topic** by default. A topic is
a page, and a page can hold several `##` sections without becoming a different
document. The table of contents already makes a long page navigable, and keeping
related material together is worth more than a tidy one-page-per-idea rule.

Split into a second topic only when one of these is true:

1. **The subjects are genuinely unrelated.** Objective 2.4 pairs package
   management with "basic configurations of common services". Those share an
   objective number and nothing else.
2. **One page would run past roughly 3,000 words.** Past that it stops being a
   study page and becomes a chapter, and the reader loses the sense of finishing
   something.
3. **The reading order differs.** Permissions belongs early, next to files.
   SELinux belongs late, after sudo and services. Both are objective 3.3, and
   forcing them into one page puts one of them in the wrong place in the track.

Applied to the six large objectives:

| Objective | Split? | Why |
| --- | --- | --- |
| 1.1 | Sections | FHS, architectures, distributions, GUI, licensing all sit under "what a Linux system is". Boot moves to its own topic because it has its own diagram and its own failure modes. |
| 1.3 | Split | Filesystems and mounts is one mental model; LVM and RAID is another, with its own stack diagram. |
| 2.4 | Split | Packages and services are unrelated (reason 1). |
| 3.3 | Split | Reading order (reason 3), and the combined page would be enormous. |
| 4.1 | Split | Config management and orchestration are different tools for different jobs. |
| 5.2 | Sections, mostly | Hardware, storage, and OS failures share a diagnostic approach. Boot recovery splits out because it is the one you read when you cannot boot. |
| 5.4 | Sections | SELinux, certificates, repositories, and ciphers are all "security things that deny you", and they share the diagnostic ladder. |

That last row is the correction to what I said earlier. Objective 5.4's other
subjects become `##` sections in the existing troubleshooting topic rather than
new topics, which also removes the partial-coverage problem: one topic claims
5.4 and actually covers it.

## Scope decisions taken

| Question | Decision | Date |
| --- | --- | --- |
| Topic count | 40, and more if a topic needs splitting. Depth over tidiness; Ryan is studying from this himself. | 2026-08-07 |
| Objective sub-parts | Headings inside one topic by default. Split into a second topic only when the objective spans genuinely unrelated subjects, or when one page would run past roughly 3,000 words. See below. | 2026-08-07 |
| Kubernetes | Enough to understand objective 4.1 and no more. No deep dive; a separate Kubernetes track may come later and should keep that material. | 2026-08-07 |
| Interactive lab | No. No terminal emulator, no evaluated commands, no simulated shell. Study material only. | 2026-08-07 |
| Command output | Captured in pinned containers where possible, sourced from documentation otherwise, never written from memory. | 2026-08-07 |
| Exercises | Both: a readable worked scenario (required) and an optional hands-on completion problem. | 2026-08-07 |

## The term-by-term pass, and what followed it

Run 2026-08-21, after the Network+ track had the same treatment. Every previous
coverage check on this track worked at the level of an objective. This one
extracted the bullet terms from the XK0-006 objectives document and matched each
against all 77 topics, then checked every command name the objectives print.

**Fourteen strings CompTIA prints did not appear anywhere in the track**, and
none of them is a subject the track fails to teach. The largest cluster is LVM:
`pvs`, `vgs` and `lvs` were all present and none of the `display` counterparts,
no `lvchange`, and no `lvresize`. The last of those matters beyond vocabulary,
because `lvresize -r` resizes the volume and the filesystem together, which is
the answer to the pitfall the topic is built around and was missing from the
topic that explains the pitfall.

The rest were one or two lines each in the topic that already covered the idea:
`groupmod`, `pstree`, `atop`, `unalias`, `sdiff`, `nmap`, `tracepath`, `ping6`,
`badblocks`, `mkinitrd`, macvlan and ipvlan, PAT, TFTP, MAC spoofing, and PTP.
Sixteen questions cover them, because all of it is examinable.

**Two of them earned more than a line.** `atop` got a paragraph because
recording samples to disk is the one thing `top` and `htop` cannot do and it is
the tool for the question people actually ask after an incident. `nmap` got a
short section in the hardening topic, as the outside view of the question `ss`
answers from inside, with the note that authorisation comes before technique.

The lesson is about the granularity of a check. An objective-level check answers
whether a topic exists, which stopped being the risk once the plan was written.
A term-level check answers whether the words a candidate meets on screen appear
on the page.

## Material that is not on the exam

The same pass asked the opposite question. Four topics came out of it, marked
`beyondExam`, which puts them in their own section on the track index, outside
the lesson numbering, and makes the build refuse any practice question that links
to them.

| Topic | The gap it fills |
| --- | --- |
| Where the time actually goes | The objectives name `top`, `htop`, `atop`, `mpstat`, `pidstat`, `ps` and `strace`, and nothing that profiles or traces. Topics 75 and 76 establish that a machine is busy and stop |
| What a write actually guarantees | Nine storage topics, and none of them says what `write()` promises or what a journal protects |
| How upstream becomes your distribution | Objective 3.6 names backporting in a list, and it is the largest recurring argument between security teams and the people who run the servers |
| The system you cannot change | The machine behind a third of this track's captures is image-based, and the track had never said so |

**Three of the four are demonstrable**, which is why they were chosen over other
candidates. The profiling topic needed a new `--privileged` mode in `capture.sh`,
because `perf` and BPF need real privileges against the host kernel and asking
for a loop device to obtain them would have been a lie in the flag name; it
forces the podman machine's architecture for the same reason `--block` does. The
durability topic measures the cost of `fsync` at a factor of a hundred and forty
on the same machine writing the same bytes. The backporting topic reads two real
changelogs. The fourth is the capture host describing its own layout.

**One candidate was deliberately not written.** Incident conduct, the roles and
the communication cadence during a live fault, exists as a Network+ topic and
would have been a near-duplicate here. Topic 63 links to it instead, which is the
cross-track rule this project already had.

Two candidates were rejected on inspection rather than on principle. Reading the
kernel's documentation would have been thin, because topic 02 already owns the
manual page half thoroughly and 28 topics already cite `docs.kernel.org`. Memory
accounting was already covered across topics 11 and 75, including PSS and the
page cache.

**The predict panel test now walks both tracks.** It had only ever checked
Network+, and widening it found exactly one topic below the floor, which is what
a rule people are already following looks like when the test finally catches up.

## Sources

| Claim | Source | URL |
| --- | --- | --- |
| Retrieval practice beats restudy at delay | Karpicke, *Retrieval-Based Learning: A Decade of Progress*, in Learning and Memory: A Comprehensive Reference, 2nd ed., Elsevier (2017). Reviews Roediger and Karpicke's original testing-effect work, `doi:10.1111/j.1745-6916.2006.00012.x`, whose publisher copy is bot-blocked. | https://files.eric.ed.gov/fulltext/ED599273.pdf |
| Pretesting effect: failed retrieval before instruction aids encoding | Richland, Kornell, and Kao, *The pretesting effect: Do unsuccessful retrieval attempts enhance learning?* | https://learninglab.uchicago.edu/Pre-Testing_files/RichlandKornellKao.pdf |
| Worked example effect and expertise reversal | Kalyuga et al., *Cognitive Load and Expertise Reversal*, Cambridge Handbook of Expertise and Expert Performance ch. 40 | https://www.cambridge.org/core/books/cambridge-handbook-of-expertise-and-expert-performance/cognitive-load-and-expertise-reversal/03F656FD334F23214426ACB4118FEBF9 |
| Interleaving improves discrimination between problem types | Taylor and Rohrer, *The Effects of Interleaved Practice* | https://digitalcommons.usf.edu/psy_facpub/1760/ |
| Feedback timing has no significant average effect | *A Meta-Analysis of the Impact of Feedback Timing on Learning Outcomes in Computer-Assisted Learning*, Educational Psychology Review (2026) | https://link.springer.com/article/10.1007/s10648-026-10117-8 |
| Experts reason forward from findings; novices work exhaustively | Cognitive schemes and strategies in diagnostic and therapeutic decision making, PMC3824754 | https://pmc.ncbi.nlm.nih.gov/articles/PMC3824754/ |
| Separating documentation modes | Diataxis framework | https://diataxis.fr/ |

Accessed 2026-08-07, and every URL above was checked for a 200 response on that
date. These are tier 2 by your source hierarchy: they inform how the material is
presented, and none of them are cited in topic content, which cites only Linux
and CompTIA primary sources.
