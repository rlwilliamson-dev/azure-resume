# Prompt: build the CompTIA Security+ track

Hand this to a fresh session. It carries the pre-work done on 2026-08-21 so the
research step starts from verified numbers rather than from scratch, and it names
the five places where the Security+ track has to differ from the two that already
exist.

Everything in the "verified" tables below was checked on 2026-08-21. Re-check
anything you are about to build on. Nothing here is a source; the sources are
listed at the foot.

## The task

Build a CompTIA Security+ track at `/learn/security-plus`, to the standard the
Network+ and Linux+ tracks already set: topics written in reading order with exam
objectives mapped in, captured output rather than invented transcripts, cited
primary sources, per-domain question banks that link back to the material, and a
verification pass at the end that executes or re-checks every claim.

Two things the reader of this prompt asked for specifically:

**Diagrams on everything that can carry one.** Security+ is three quarters
conceptual by exam weight, so almost every topic can. Treat that as a floor with a
test behind it rather than as an aspiration. See [Diagrams](#diagrams).

**Cross-platform captures wherever a capture exists at all.** The premise that
Security+ is not capture-heavy is right for domains 2, 3 and 5 and wrong for 1.4
and most of domain 4. See [Captures](#captures-and-what-is-actually-runnable).

## Read these first, and treat them as binding

| Document | What it governs |
| --- | --- |
| `docs/linux-plus-teaching-design.md` | Audience, progressive disclosure, concrete before abstract, voice, analogies, the nine design decisions |
| `docs/network-plus-teaching-design.md` | Everything the Linux+ document got wrong for a second track: Prove it, Try it, cross-track duplication, platform triggers, diagram rules, claims wording, photographs, question shape |
| `docs/network-plus-topic-plan.md` | The topic template, the balance check, capture feasibility, bank sizing, authoring order |
| `docs/linux-plus-question-authoring-standard.md` | Question input rules, copyright, trademark, prohibited inputs |
| `/Users/ryan/.claude/CLAUDE.md` | No em dashes. No attribution trailers on commits. Commit and PR text in Ryan's voice |

The Network+ design document is the important one. It exists because the first
Network+ plan was written by adapting the Linux+ shape and several of those
adaptations were wrong. Expect the same to be true here, and expect the failures
to be in different places.

Rules that carry over without argument, so nobody relitigates them:

- Never attribute intent to CompTIA or to a standards body. Say what a document
  contains and what it omits.
- Never cite your own research process. Name the document or state the thing
  plainly.
- A capture is real or it is not in the track. No invented transcripts, ever.
- Reproduce CompTIA's objective numbers and statements. Never the sub-bullet text.
- Refer to other topics by number in prose. Name a topic only where the name is
  doing work, which is mostly the cross-track see-also links.
- Never reference a topic by its position. The reading order will change.
- A photograph needs a licence that permits display, a local file, and an entry in
  `images/credits.json`. Attribution is not a licence.

## The exam, verified 2026-08-21

| | Value | Where from |
| --- | --- | --- |
| Code and version | SY0-701, V7 | CompTIA certification page |
| Objectives document | Version 6.0, 21 pages, dated Jan 2023 | CDN PDF, downloaded and parsed |
| Questions | Maximum of 90 | CompTIA |
| Length | 90 minutes | CompTIA |
| Passing score | **750** on 100 to 900 | CompTIA |
| Question types | Multiple choice and performance-based | CompTIA |
| Launched | 7 November 2023 | CompTIA |
| Domains | 5 | |
| Objectives | 28 | Parsed from the PDF |

**The passing score is 750, not 720.** Both existing tracks are 720 and the value
is per-exam in `src/config/exams.ts`, so this is a one-line difference that will
be silently wrong if it gets copied.

Domain weights, and the objectives under each. Objective statements are CompTIA's
own, which is what gets reproduced in `exams.ts`.

| Domain | Weight | Objectives |
| --- | --- | --- |
| 1.0 General Security Concepts | 12% | 1.1 to 1.4 |
| 2.0 Threats, Vulnerabilities, and Mitigations | 22% | 2.1 to 2.5 |
| 3.0 Security Architecture | 18% | 3.1 to 3.4 |
| 4.0 Security Operations | 28% | 4.1 to 4.9 |
| 5.0 Security Program Management and Oversight | 20% | 5.1 to 5.6 |

The 28 statements, extracted from the PDF and checked against CompTIA's own
headings:

```
1.1 Compare and contrast various types of security controls.
1.2 Summarize fundamental security concepts.
1.3 Explain the importance of change management processes and the impact to security.
1.4 Explain the importance of using appropriate cryptographic solutions.
2.1 Compare and contrast common threat actors and motivations.
2.2 Explain common threat vectors and attack surfaces.
2.3 Explain various types of vulnerabilities.
2.4 Given a scenario, analyze indicators of malicious activity.
2.5 Explain the purpose of mitigation techniques used to secure the enterprise.
3.1 Compare and contrast security implications of different architecture models.
3.2 Given a scenario, apply security principles to secure enterprise infrastructure.
3.3 Compare and contrast concepts and strategies to protect data.
3.4 Explain the importance of resilience and recovery in security architecture.
4.1 Given a scenario, apply common security techniques to computing resources.
4.2 Explain the security implications of proper hardware, software, and data asset management.
4.3 Explain various activities associated with vulnerability management.
4.4 Explain security alerting and monitoring concepts and tools.
4.5 Given a scenario, modify enterprise capabilities to enhance security.
4.6 Given a scenario, implement and maintain identity and access management.
4.7 Explain the importance of automation and orchestration related to secure operations.
4.8 Explain appropriate incident response activities.
4.9 Given a scenario, use data sources to support an investigation.
5.1 Summarize elements of effective security governance.
5.2 Explain elements of the risk management process.
5.3 Explain the processes associated with third-party risk assessment and management.
5.4 Summarize elements of effective security compliance.
5.5 Explain types and purposes of audits and assessments.
5.6 Given a scenario, implement security awareness practices.
```

Bank sizing falls out of the weights. Rounding each weight against 90 gives
11 + 20 + 16 + 25 + 18, which totals exactly 90, so the `weightedShares` helper
built for Network+ has nothing to reconcile here. At `POOL_MULTIPLE = 3` the pool
targets are 33, 60, 48, 75 and 54, for **270 questions**.

## The version problem, which is a decision before anything else

SY0-701 has a successor coming and the timing is awkward.

CompTIA's own certification page says the exam retires "usually three years after
launch (estimated 2026)" and names no date. Third-party training providers and
threads on CompTIA's instructor network put SY0-801 at a November 2026 launch with
SY0-701 retiring around May 2027. None of that is a CompTIA statement on a CompTIA
page, so treat it as unconfirmed. What is checkable: **the SY0-801 objectives PDF
is not on CompTIA's CDN as of 2026-08-21.** Two candidate URLs following the
established naming pattern both return 404, and CompTIA publishes objectives ahead
of a launch, so the launch is not imminent this week.

The recommendation is to build against SY0-701 now, for two reasons. Most of what
gets written survives a version bump, because the material is cryptography,
identity, logging, risk and governance rather than a numbered list that CompTIA
reshuffles. And the parts that do not survive are concentrated in three places
that are cheap to remap: the `exams.ts` entry, the `examObjectives` block in each
topic's frontmatter, and the `objective` field on each question.

What follows from that is an authoring rule, and it is worth stating because it
costs nothing now and a great deal later:

> **Objective numbers live in frontmatter and in question metadata. They do not go
> in prose.** A sentence that reads "objective 4.3 names five activities" is a
> sentence somebody has to find and rewrite in 2027. Say what the thing is.

Check the CDN for the 801 objectives at the start of the work and again before the
verification pass. If they have appeared, stop and re-decide.

## What the pre-work found, and what each finding changes

Five things came out of parsing the objectives document and measuring the existing
tracks. Each one changes the plan rather than decorating it.

### 1. This is the least scenario-driven of the three exams, by a wide margin

Verb profile, counted from the objective statements and weighted by domain share
divided evenly across each domain's objectives:

| | XK0-006 | N10-009 | SY0-701 |
| --- | --- | --- | --- |
| Objectives | 29 | 25 | 28 |
| "Given a scenario" objectives | 18 | 10 | **7** |
| Scenario share by exam weight | 63.5% | 44.3% | **24.7%** |
| Explain, Compare and contrast, Summarize, by weight | 36.5% | 55.7% | **75.3%** |

Broken out: Explain alone is 14 of 28 objectives and 49.3% of the exam. Compare
and contrast is 16.4%. Summarize is 9.7%.

The Linux+ thesis was "change a system and prove the change took". The Network+
thesis was "read a network you did not build and prove what it is doing". Neither
survives at 24.7% scenario weight, and a track that inherits either will produce
pages that keep promising to run something.

**A candidate thesis, offered to be tested rather than adopted:**

> Security+ teaches you to choose a control and defend the choice. Every topic
> ends in a decision, names the alternative that was rejected, and says what the
> rejection cost.

The argument for it is that the exam's real difficulty is discrimination, not
recall. Four options are all real security controls and one fits the scenario. A
track built on definitions rehearses the wrong skill, which is the failure mode of
every glossary-shaped resource for this exam. If that thesis holds, it also fixes
the distractor rule for the banks, which is the second-largest thing this track
gets wrong if nobody decides it early.

Test it against the objectives document before committing. If it does not hold,
say so and write the sentence that does.

### 2. The vocabulary load is the largest of the three, and it is not close

Counted from the SY0-701 objectives PDF:

- **845 bullet term lines, 788 unique.** N10-009 carries 536.
- **328 acronyms** in the appendix, against 162 for N10-009 and fewer for XK0-006.

The repo has already refused a `/glossary` route once, for Network+, at 490 terms
with 48 duplicates and no disambiguation policy. That refusal was right and it
gets harder to hold here. Decide the answer in the teaching design rather than
discovering it at topic 40:

- Every term a candidate will see on screen appears somewhere on a page, in the
  topic that already teaches the idea. That is the term-level check that found
  seven gaps on Network+ after the bank was finished.
- **Run the term-level check during authoring, per block, not once at the end.**
  On Network+ it ran last and found a case where the bank asked for a word the
  topic taught under a different name, so a reader could get a question wrong
  having read the page it links to. At 788 terms that will not be one case.
- The acronym appendix drifts from the objectives text on both other exams.
  Expect entries here that the objectives never ask about. Each of those is worth
  one sentence in the topic where it belongs, and nothing more.

The `dl.terms` list in section 2 of the template is the mechanism that already
exists for this. It will be carrying more weight on this track than on either
other one.

### 3. There are already 204,000 words of security material in this repository

This is the largest single design problem and it has no precedent in either
existing track.

| Track | Security-adjacent topics | Words |
| --- | --- | --- |
| Linux+ | 17 (permissions, PAM, logging and auditing, netfilter, firewalld, SSH, SELinux, hardening, cryptography, TLS and ACME, encryption at rest, compliance and auditing, backup, and four troubleshooting topics) | 133,297 |
| Network+ | 15 (CIA triad, encryption and PKI, DNS security, VPNs, physical security, ACLs and zones, segmentation, layer 2 attacks, attacks on services and people, device hardening, cloud, zero trust and SASE, monitoring, wireless security, troubleshooting method) | 70,697 |
| | | **203,994** |

Network+ accepted roughly 40,000 words of overlap with Linux+ under the rule
"write self-contained, link out at the foot for depth". Applied unchanged here
that is a five-fold cost, and it would produce three pages on TLS that can drift
apart in public.

**The recommended resolution, to be confirmed by an actual overlap audit before
topic one:** keep the self-contained rule and change what self-contained means,
because the three tracks are answering different questions about the same
subject.

- Linux+ asks how you configure this on a RHEL or a Debian machine.
- Network+ asks what the protocol does and how you would know.
- Security+ asks which one you should choose, and what it costs when you are
  wrong.

So a Security+ topic on cryptography owes the reader a complete treatment of the
decision: symmetric against asymmetric, key length against lifetime, what a cipher
choice buys, when you rotate, what happens when the key is lost. It does not owe
another TLS handshake walkthrough, because SY0-701 does not ask for one. That is
scoping to the exam, not stopping halfway and pointing elsewhere, and the
see-also link at the foot stays what it is on Network+: further depth for somebody
who wants it.

Write that audit as a table in the teaching design, topic by topic, and say for
each overlap which of the three questions the Security+ page is answering. Nine
Linux+ topics were a small enough surface to check by hand. Thirty-two is not, so
the table is the control.

### 4. The default free resource for this exam is measurably lopsided

Professor Messer's SY0-701 videos are free, cover every objective, and are what a
large share of candidates actually use. The content is good, and the point of
measuring it is not to argue with it. It is to find where a written track is worth
somebody's time. The videos are free; the 96-page course notes and the practice
exams are a paid bundle.

Counted from his own course page on 2026-08-21: **121 videos, 15 hours 11 minutes,
organised strictly by CompTIA's objective numbering.**

| Domain | Videos | Share of videos | Exam weight |
| --- | --- | --- | --- |
| 1.0 | 18 | 15.0% | 12% |
| 2.0 | 38 | 31.7% | 22% |
| 3.0 | 18 | 15.0% | 18% |
| 4.0 | 29 | 24.2% | 28% |
| 5.0 | 17 | 14.2% | 20% |

Video count is a proxy for coverage and not the same as minutes, so read the gaps
as directional. The direction is consistent though: threats and vulnerabilities
gets ten points more attention than its weight, and governance, risk and
compliance gets six points less, on the exam's second-largest domain.

At objective level the thin spots are sharper. Objective 4.9, "use data sources to
support an investigation", has one video. So do 4.2, 4.7, 2.1 and 1.1. Meanwhile
2.3 and 2.4 have 14 and 15.

Three differences a written track can actually claim, and they should be decided
rather than assumed:

**Order.** His course follows CompTIA's numbering, so change management arrives at
1.3 before a reader has seen a control operating. The existing tracks are written
in reading order with objectives mapped in, and the Network+ reorder moved 70 of
76 topics. Do the same work here and say in the orientation page why the order
differs from the objectives document, because a reader arriving from his course
will notice.

**Captured evidence.** Objective 4.9 is a log-reading objective on a
28% domain with one video behind it. A page that hands over real `journalctl`,
real `Get-WinEvent` and real `log show` output for the same event is a thing video
does badly and this repository already has the tooling for.

**Revisability.** A fact that changes needs a re-recorded video or an edited
paragraph. That is an argument for putting dated, checkable numbers on pages, the
way Network+ topic 08 carries measured IPv6 adoption, rather than avoiding them.

**One boundary, and it matters.** His course is a benchmark for coverage and a
signal of where candidates form their mental model. It is not an input to write
from. The authoring standard already says every topic and every question comes
from the objectives document and primary documentation, and somebody else's
course is neither. Where his framing of a concept is the one a reader arrives
with, the useful move is to say what that framing leaves out, not to restate it.

His monthly study group replays are the exception worth mining, because the
questions people ask in them are evidence of what actually confuses candidates.
That belongs in "What trips people up", phrased as the confusion rather than as a
citation.

### 5. Captures exist, and they are concentrated

Verified working on 2026-08-21 from this machine, without the podman machine
running:

| Source | Result |
| --- | --- |
| CISA Known Exploited Vulnerabilities catalogue JSON | 200, 1.6 MB |
| FIRST EPSS API | 200, real score for CVE-2021-44228 dated the day of the query |
| NVD CVE API 2.0 | 200, 87 KB for one CVE |
| MITRE ATT&CK enterprise STIX bundle | 200, 54 MB |
| `dig TXT _dmarc.<domain>`, SPF, and `dig DS` for DNSSEC | real records returned |
| `curl -I` for HSTS, CSP, X-Frame-Options | real headers returned |
| crt.sh JSON | 502 on two attempts. Retry before planning a topic on it |

Not verified and worth an hour before the plan is written: `oscap` with the SCAP
Security Guide, `lynis`, `aide`, `auditd` under `capture.sh --privileged`, and
`cryptsetup` under `capture.sh --block`. All four are plausible and none is proven.

## Captures, and what is actually runnable

The existing toolchain, unchanged:

| Tool | What it does | Relevant here |
| --- | --- | --- |
| `capture.sh <distro>` | One command in a container pinned by digest, with outbound internet | openssl, gpg, hashing, `dig`, `curl`, nmap, password hashing, TOTP |
| `capture.sh --privileged` | Host kernel, CAP_PERFMON and CAP_BPF | auditd, seccomp, anything reading kernel state |
| `capture.sh --block N` | Real loop devices | LUKS, dm-crypt, secure erase |
| `capture.sh vm` | The podman machine itself | boot, kernel modules, firmware, Secure Boot state |
| `netlab.sh --topo` | A namespace topology, 27 committed | firewall evidence, TLS between two hosts, IDS, segmentation |
| `hostcap.sh` plus `.github/workflows/capture-hosts.yml` | Windows Server 2025 and macOS runners | the third and fourth columns of every platform table |

**Where the captures are.** Objective 1.4 is cryptography and almost all of it
runs. Objective 4.1 is applying security techniques to computing resources, 4.3 is
vulnerability management with three public APIs behind it, 4.4 is alerting and
monitoring, 4.6 is identity and access management, and 4.9 is log analysis. That
is most of a 28% domain plus a 12% domain.

**Where they are not.** Domain 5 is governance, risk, third-party management,
compliance, audits and awareness. Twenty percent of the exam with essentially
nothing to run. Domain 2 is threat actors and vulnerability types, and domain 3 is
architecture models. Say so in each provenance line rather than dressing a
hand-written block as a capture. Those topics use the other two Prove it forms.

**Keep the three Prove it forms unchanged.** Run it, work it out, look it up. The
arithmetic form has more to do here than it did on Network+, and it is where
Security+ hides its equivalent of subnetting:

- ALE, SLE and ARO, against the annual cost of the control
- RPO, RTO, MTTR and MTBF on one outage timeline
- CVSS base score from a vector string, and the same CVE's EPSS percentile
- Password entropy in bits, and what a bit buys
- Key length against expected lifetime

Every one of those is checkable arithmetic with a named tool a reader can verify
against, which is exactly the shape the Network+ subnetting rule wanted.

### Cross-platform captures

The trigger rule from Network+ applies and needs extending, because the Linux-only
tools on this track are different ones. **A topic owes Windows and macOS columns
if it tells a reader to run any of:** `openssl`, `sha256sum`, `gpg`, `ssh-keygen`,
`journalctl`, `ausearch` or `auditctl`, `getenforce`, `ss`, `iptables` or `nft`,
`dig`, `passwd` or `chage`, `last` or `lastb`, `stat`, or anything reading a
certificate store.

The counterparts, to be captured rather than sourced:

| Task | Linux | Windows | macOS |
| --- | --- | --- | --- |
| Hash a file | `sha256sum` | `Get-FileHash`, `certutil -hashfile` | `shasum -a 256` |
| Read the security log | `journalctl`, `ausearch` | `Get-WinEvent` | `log show --predicate` |
| List local accounts | `/etc/passwd`, `getent` | `Get-LocalUser` | `dscl . -list /Users` |
| Inspect a certificate | `openssl x509 -text` | `Get-PfxCertificate`, `certutil` | `security find-certificate` |
| Full-disk encryption state | `cryptsetup status` | `Get-BitLockerVolume` | `fdesetup status` |
| Host firewall state | `nft list ruleset`, `firewall-cmd` | `Get-NetFirewallProfile` | `socketfilterfw --getglobalstate` |
| Code signature | `rpm -V`, `dpkg -V` | `Get-AuthenticodeSignature` | `codesign -dv`, `spctl -a` |
| Malware protection state | varies | `Get-MpComputerStatus` | `system_profiler SPConfigurationProfileDataType` |

One gotcha found on 2026-08-21 that belongs in a topic: **macOS ships LibreSSL, not
OpenSSL.** `openssl version` returned LibreSSL 3.3.6 on macOS 26.5.2 here, and
several subcommands a Linux reader takes for granted are missing or behave
differently.
That is a real cross-platform difference on the exam's cryptography objective, and
it is the same shape as the `ifconfig` finding that earned macOS its column on
Network+.

Scripts go in `blog/scripts/windows/` and `blog/scripts/macos/`, one per topic
rather than one per platform, joining the 30 PowerShell and 29 shell scripts
already there.

### The attack-demonstration rule, stated hard

Network+ hit this once, with ARP poisoning, and resolved it in an open question
rather than a rule. Security+ hits it on most of domain 2, so decide it first:

> **Capture the evidence, not the attack.** A topic may show what an attack looks
> like from the defender's side, produced by arranging the observable state
> directly. It does not run the attack. A neighbour table with two addresses on
> one MAC comes from a static entry. A brute-force pattern in an auth log comes
> from failed logins somebody made. A malicious indicator comes from a published
> sample's hash, not from the sample.

Everything in the track is written for the person defending the system. Where a
technique cannot be shown without doing the thing, it stays described, and the
topic says the evidence half is what was captured.

## Diagrams

This is the part the reader of this prompt asked for most directly, and it is the
right instinct for an exam that is 75% conceptual by weight. The existing rules
already say how to draw. What is missing is a floor.

**Every lesson carries at least one figure.** Exemptions are a keyed list with a
reason, tested the way `platforms.test.mjs` tests the predict and deeper panel
floors and the exempt lists themselves. That is roughly 70 figures against the 29
Network+ built, and it is the single largest new cost in this plan. Budget for it
in the authoring order rather than discovering it in block E.

All the existing figure rules apply unchanged and the two that will bite hardest
are these. **Draw the insight, not the layout**: a detailed picture of an
arrangement is still decoration with a footnote, and security material is full of
diagrams that show boxes where the argument was about failure. **A figure with two
insights in it is two figures.** Detail earns its place when it carries data, so
put the real vector string, the real digest, the real timestamp in the drawing and
the reason it matters in the caption.

Colour is never the only channel, which matters more here than on Network+ because
every distinction on this track is trusted against untrusted, allowed against
blocked, before against after.

A starter list, with the argument named rather than the subject, because a plan
row that says "diagram: PKI" produces the generic version:

| Topic area | The figure, and what it argues |
| --- | --- |
| Control types | The 4 categories by 6 types grid with a real control in each populated cell and the empty cells left empty. The axes are independent, which is why "is a firewall preventive" is the wrong question |
| Compensating controls | The control that was wanted, why it could not be used, what covers the gap, and the part of the gap still uncovered |
| Zero Trust | An SP 800-207 request crossing the policy enforcement point, with the engine and administrator off the data path. The decision point is not where the data goes |
| Hashing and salting | Two identical passwords, two different digests, one rainbow table failing |
| Work factor | bcrypt cost against measured wall-clock time. The defence is the cost, and it is tunable |
| Signing against encrypting | One key pair used twice in opposite directions |
| Certificate chain | Real fields from a captured `openssl x509`: subject, issuer, validity, SAN, and the signature binding each link |
| Revocation | CRL, OCSP and stapling drawn as who asks whom, and what the client concludes when no answer arrives |
| RADIUS against TACACS+ | The same login twice, with the encrypted portion shaded. One protects the password, the other the whole body |
| SAML against OIDC | The same browser redirect chain, different token, different trust anchor |
| TOTP | The shared secret, the time step, and the drift window on a clock axis, with real computed codes |
| SIEM pipeline | One real syslog line at each stage, raw to parsed to enriched to correlated to alert. The value is added by the parse |
| Correlation | Three log sources on one time axis, one incident, and the identifier that ties them |
| CVSS, EPSS and KEV | One real CVE scored three ways. Three numbers answering three different questions, one of which is about exploitation in the wild |
| Vulnerability window | Discovery to disclosure to patch to exploitation, with real dates from one CVE, drawn to scale |
| RPO and RTO | An outage timeline with the last backup, the failure and the restore, drawn to scale. Data lost and time down are set independently |
| Backup strategies | Full, incremental and differential over a fortnight, with the restore chain each one needs |
| Order of volatility | A stack with real lifetimes against it |
| Data states | At rest, in transit and in use, with the control for each and the one control that covers none of them |
| Tokenisation against masking against encryption | The same record three ways, and what an attacker who steals the store gets in each case |
| Shared responsibility | Layers by service model, with the boundary line moving across IaaS, PaaS and SaaS |
| Defence in depth | One intrusion crossing four controls, three of which fail. It works because controls fail independently, not because there are many |
| Policy hierarchy | One real requirement traced from policy to standard to procedure to guideline |
| Risk treatment | The same risk under accept, avoid, transfer and mitigate, with the residual drawn each time |
| ALE arithmetic | Annualised loss against the annual cost of the control, and the crossover |
| Supply chain | One dependency update reaching production, with every point it could have been caught |

**Photographs are back on the table and the physical objectives need them.**
Objective 1.2 names bollards, access control vestibules, fencing, video
surveillance, badges, lighting, and four sensor types. Objective 4.2 covers asset
management including disposal. Every one of those is an object a reader may never
have held, which is the test the Network+ design set. Research images at the same
time as sources for those topics, not afterwards, and the licence rule applies.

## Questions

270 questions across five banks in `src/data/quizzes/security-plus/`, ids
`sp-<domain>-NNN`.

**There is already a legacy bank there.** `fundamentals.json`, eight questions,
dated 7 August 2026, ids `sp-001` upward, `domain` holding a display name instead
of an objective number, no `learnRef`. It predates the current schema and it is
not wired to an exam. Decide what happens to it in the plan. The questions
themselves are not bad, so rewriting the eight into the new shape is probably
cheaper than deleting them.

Amendments to the authoring standard, specific to this exam. The Network+ mistake
was measuring the bank against the exam after it was finished and then reframing
64 stems. Bake these in from the first question:

**A person in the stem.** CompTIA's house style puts a technician, an analyst or
an administrator in almost every item. Six of 273 Network+ questions had one
before the fix.

**Named things as the options, not explanatory clauses.** Seventy-seven percent of
the Network+ bank offered four explanations. Those teach better and rehearse the
wrong skill, because the exam tests recognise and eliminate.

**Every distractor is a real control that is wrong for a nameable reason**, and
the explanation names the reason. This is the Security+ version of the objective
1.7 distractor rule, it follows directly from the candidate thesis above, and it
is the single most important thing in this section. An item where three options
are obviously not security controls teaches elimination, which is the failure mode
of a badly written Security+ question.

**Situational coverage on the seven scenario objectives**, measured while writing
rather than at the end. Network+ drifted from 84 to 93 percent
situational in the domain written last down to as low as 7 in the ones written
first, and only counting found it.

**A multiple-response floor** on the four Compare and contrast objectives.

**A diagram-anchor requirement** for the objectives whose content is visual, with
`learnAnchor` resolving to a heading that holds a figure and a stem answerable only
by having read it.

**Performance-based questions are not reproduced.** Say so on the exam page. The
nearest honest thing, and Network+ has eleven of them, is handing over a real
capture from a topic and asking what it proves. The two build checks that keep
exhibits honest already exist.

## Beyond the exam

`beyondExam: true` works and is tested. Off-syllabus material lists in its own
section, takes no lesson number, and the build fails if a question links to it.
That last part is not a convention, it is `quiz-validate.ts`.

Ask the opposite question at the end of the term-level pass, the way Network+ did:
what does a reader of this track want that the certification never tests. On a
security track the candidates are obvious enough to name now and worth testing
against the finished content rather than assuming: how a real detection gets
written and tuned, what a threat model looks like on paper, what actually happens
in the first hour of a breach that has a regulator attached to it, and the
published post-incident accounts where the abstract lessons acquire a date and a
cost.

None of it gets questions. That rule came from Ryan directly and the reason is
that a question in the bank is a claim that the thing is examinable.

## Infrastructure changes this track needs

Smaller than the Network+ list, because Network+ did most of the generalisation.

| Change | Why | Risk |
| --- | --- | --- |
| Add `sy0-701` to `src/config/exams.ts`, point `security-plus` at it in `EXAM_FOR_TRACK` | Everything derives from it | None. Watch the 750 pass mark |
| Rewrite the `security-plus` entry in `src/config/tracks.ts` | It exists already with a placeholder description written before either real track | None |
| Decide the fate of `src/data/quizzes/security-plus/fundamentals.json` | Legacy shape, no `learnRef`, ids that collide with the new convention | Low |
| Per-track comparison page slug, `/learn/security-plus/platforms` | Same shape Network+ needed | Low. The component is already extracted |
| A per-topic figure floor test | The diagram requirement above is otherwise a preference | Low, and it is the thing that makes the ask real |
| Term-level coverage script that runs per block | 788 terms is too many to check once at the end | Low. The Network+ pass was a throwaway script; this one should be committed |

## Order of work

Follows the order that worked twice, with two changes. The overlap audit moves to
the front because it decides scope, and figures move earlier because there are
more of them.

1. **`docs/security-plus-sy0-701-research.md`.** What is on the exam, from the
   objectives PDF and CompTIA's own pages. Include the acronym-appendix drift
   check, the term extraction, and the copyright position. Confirm or correct
   every number in this prompt.
2. **The overlap audit**, as a table, against all 32 existing security-adjacent
   topics. This decides how much gets written.
3. **`docs/security-plus-teaching-design.md`.** The thesis, tested rather than
   assumed. What Prove it and Try it become. The glossary decision. The
   attack-demonstration rule. The figure floor. The question amendments.
4. **`docs/security-plus-topic-plan.md`.** Topics in reading order, balanced
   against weight, with zero hook, deeper panels, capture route and figure
   argument per row. Objective coverage table. Capture feasibility table.
5. **Exam entry, track entry, empty content directory.** One commit. The coverage
   route starts working.
6. **Prove the unproven capture routes** before writing anything that depends on
   them: `oscap`, `lynis`, `aide`, `auditd` privileged, `cryptsetup --block`, and
   crt.sh.
7. **Two topics as the pattern, then stop and review.** Recommend one from
   objective 1.4 with heavy captured output and one from domain 5 with none, since
   those are the two extremes the template has to survive. Not two adjacent
   topics.
8. **Blocks in order**, captures first while the tooling is fresh.
9. **Question banks per domain**, after that domain's topics exist.
10. **The term-level pass**, per block as you go, and again at the end.
11. **The verification pass.** Every claim executed or checked against upstream,
    every citation fetched. It found eleven errors on Linux+ and seven on
    Network+, all the same two shapes: the right idea stated a notch wider than it
    should have been, or a version out of date.

Write the topics solo. Subagent fan-out on Linux+ block D cost two session limits
and the output needed rewriting.

## Sources checked 2026-08-21

| Claim | Source | Result |
| --- | --- | --- |
| Exam code, version, questions, minutes, pass mark, weights | CompTIA Security+ certification page | 200 |
| 28 objectives, 788 terms, 328 acronyms | SY0-701 objectives PDF v6.0, `comptiacdn.azureedge.net/webcontent/docs/default-source/exam-objectives/comptia-security-sy0-701-exam-objectives-(6-0).pdf` | 200, 191,989 bytes, 21 pages |
| SY0-801 objectives not yet published | Two CDN URLs following the established pattern | 404 |
| PBQ behaviour, partial credit, skip and revisit | CompTIA, Performance-Based Questions Explained | 200 |
| 121 videos, 15h11m, per-domain split | professormesser.com SY0-701 course page | 200, counted from the page |
| Retrieval practice, Hedges g = 0.61 | Adesope, Trevisan and Sundararajan, Review of Educational Research 87(3), 2017 | cited, not fetched. Verify before use |
| NIST SP 800-63B, 800-207, 800-61r3, FIPS 203 | csrc.nist.gov | 200 |
| MITRE ATT&CK, OWASP Top Ten, FIRST CVSS v4.0, CIS Controls, PCI SSC, Verizon DBIR, CISA KEV, RFC 4949 | respective sites | 200 |
| ISO 27001 | iso.org | **403.** Known robot block, already recorded. Cite it without fetching |
