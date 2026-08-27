---
title: "Start here"
description: "What the CompTIA Security+ exam is, why three quarters of it is not a scenario, how these lessons are built, why the reading order is not CompTIA's numbering, what you can practise on without a lab, and what is in the track."
deck: "Three quarters of this exam asks you to choose, not to configure"
track: "security-plus"
level: "intro"
order: 10
objectives:
  - "Decide whether this exam is the right one for you to sit, and whether to sit it now"
  - "Say where your study time should go, from the published domain weights"
  - "Work through a topic the way it was designed to be worked through"
  - "Practise on a machine you already own, without installing anything"
  - "Find the study plan, the coverage report, and the practice sets"
prerequisites: []
tags: ["security-plus", "security", "orientation"]
updated: 2026-08-21
draft: false
orientation: true
examObjectives: []
sources:
  - title: "CompTIA Security+ certification page"
    url: "https://www.comptia.org/en-us/certifications/security/"
    publisher: "CompTIA"
    accessed: 2026-08-21
    tier: 1
  - title: "CompTIA Security+ SY0-701 Certification Exam Objectives, version 6.0"
    url: "https://comptiacdn.azureedge.net/webcontent/docs/default-source/exam-objectives/comptia-security-sy0-701-exam-objectives-(6-0).pdf"
    publisher: "CompTIA"
    accessed: 2026-08-21
    tier: 1
  - title: "Performance-Based Questions Explained"
    url: "https://www.comptia.org/en-us/resources/test-policies/exam-development/performance-based-questions-explained/"
    publisher: "CompTIA"
    accessed: 2026-08-21
    tier: 1
  - title: "Certification Renewal Policy"
    url: "https://www.comptia.org/en-us/resources/test-policies/continuing-education-policies/certification-renewal-policy/"
    publisher: "CompTIA"
    accessed: 2026-08-21
    tier: 1
  - title: "Renewing CompTIA Security+"
    url: "https://www.comptia.org/en-us/resources/ce/renew-options/renewing-security-single/"
    publisher: "CompTIA"
    accessed: 2026-08-21
    tier: 1
  - title: "CompTIA Candidate Agreement"
    url: "https://www.comptia.org/en-us/resources/test-policies/comptia-candidate-agreement/"
    publisher: "CompTIA"
    accessed: 2026-08-21
    tier: 1
symptoms: []
---

This page teaches no security. It covers what the exam is, where your time should
go, how these lessons are built, and how to practise when you have no lab and no
budget. The security starts on the next page.

## What the CompTIA Security+ exam is

A vendor-neutral certification covering security concepts, threats, architecture,
operations, and the governance and risk work that surrounds all three. It is the
most widely sat security certification there is, and it is the one that appears
in job adverts by name.

| | |
| --- | --- |
| Code | SY0-701, also labelled V7 |
| Launched | 7 November 2023 |
| Questions | Maximum of 90, multiple-choice and performance-based |
| Time | 90 minutes |
| Passing score | 750 on a scale of 100 to 900 |
| Languages | English, Japanese, Portuguese, Spanish, Thai |
| Valid for | Three years, renewable with 50 CEUs |

**The pass mark is 750, and it is not a percentage.** 750 out of 900 is not 83
percent, because the scale starts at 100, and CompTIA does not publish how raw
answers map onto it. Any tool showing you a scaled score, this site included, is
approximating. Worth knowing if you have come from Network+ or Linux+, where the
bar is 720: this exam asks for thirty points more on the same scale.

**CompTIA gives two different answers on experience.** The objectives document
asks for "A minimum of 2 years of experience in IT administration with a focus on
security, hands-on experience with technical information security, and broad
knowledge of security concepts". The certification page asks for CompTIA Network+
and two years in a security or systems administrator role. Neither is a gate,
nobody checks, and this track is written for somebody at zero. If you want the
networking that the second statement assumes, it is a track on this site.

The certification page also maps this exam to a list of DoD 8140 work roles,
naming cyber defense analyst, incident responder, vulnerability analyst and
security control assessor among others. That is why a large share of the people
sitting it are sitting it: somebody's contract requires it.

### A note on timing, because the version matters

SY0-701 launched in November 2023 and CompTIA's own page says an exam retires
"usually three years after launch (estimated 2026)", naming no date. Training
providers have circulated a launch in late 2026 for a successor and a retirement
around mid-2027, and several of them say plainly that CompTIA has confirmed
neither. What is checkable is that **the successor's objectives document was not
published as of 21 August 2026**, and CompTIA publishes objectives ahead of a
launch.

So: if you have a date booked, sit SY0-701. If you are starting from zero today,
you have time, and most of what you learn survives a version change anyway,
because cryptography, identity, logging and risk do not get replaced. What gets
replaced is which number the objective is filed under.

### Where your time should go

Five domains, sorted by weight rather than by number, because that ordering is the
one that should decide what you study.

| Domain | Weight |
| --- | --- |
| 4.0 Security Operations | 28% |
| 2.0 Threats, Vulnerabilities, and Mitigations | 22% |
| 5.0 Security Program Management and Oversight | 20% |
| 3.0 Security Architecture | 18% |
| 1.0 General Security Concepts | 12% |

**Two of those will surprise you.** Security Operations is more than a quarter of
the paper, which is where the logs, the identity work, the vulnerability
management and the incident response live. And governance, risk and compliance is
a fifth of it, larger than architecture, despite being the part most candidates
skim because it has no commands in it. The free video course most people use gives
it about fourteen percent of its running time. That gap is worth six points, and
six points is the difference between 740 and 760.

General Security Concepts is the smallest domain and the one everything else is
written in. Twelve percent, and if you do not have it, the other eighty-eight
percent reads as a list of products.

### Three quarters of this exam is not a scenario

This is the single most useful thing to know before you start, and it is
countable rather than a matter of opinion. Of the twenty-eight objectives, seven
open with "Given a scenario". Weighted by domain, that is **24.7 percent of the
exam**. Explain alone is 49.3 percent.

Compare that with the other two certifications on this site. Linux+ is 63.5
percent scenario objectives; Network+ is 44.3 percent. Security+ is a different
kind of exam, and studying it the way you would study those two is a mistake.

What that means in practice: **the difficulty here is discrimination, not
recall.** You will be shown four options that are all real security controls, and
asked which one fits. Nothing about that is solved by knowing more definitions,
which is why a glossary-shaped resource feels productive and does not move your
score. Every topic in this track therefore ends in a decision, names the
alternative it rejected, and says what the rejection would have cost. That is the
skill the paper is testing.

### Performance-based questions

PBQs drop you into a simulated tool or a virtual environment and score what you
leave behind. CompTIA states that partial credit may be given for both kinds, and
that scoring anticipates more than one valid approach. Simulations can be skipped
and returned to; virtual environments cannot, and you are warned before one
starts.

**There are none on this site**, and there will not be. Simulating a firewall in a
browser is a different project, and a fake one would teach the wrong reflexes.
What this track does instead is hand you real captured output from a real system
and ask what it proves, which is the honest half of the same skill.

## How to work through these lessons

Every topic has the same shape, so once you have read two you know where to look
in the third.

| Section | What it is for |
| --- | --- |
| **Before you read** | A question you cannot yet answer. Attempt it anyway. |
| **Some words you will need** | The vocabulary the rest of the topic assumes |
| **What breaks without this** | The consequence of not knowing it |
| **Predict** | Captured output hidden behind a question. Answer first, then open. |
| **If you already work in security** | Depth for readers who have done this before. Safe to skip. |
| **Across platforms** | The same check on Linux, Windows and macOS |
| **Prove it** | The evidence: a command to run, arithmetic to do, or a named clause to go and read |
| **What trips people up** | The failures you will hit, and the decisions people get wrong |
| **Work it through** | A scenario reasoned to a decision, with the rejected option named |
| **Try it** | Optional, and most of it runs on the machine you are reading this on |
| **Check yourself** | Retrieval questions, for next week rather than now |
| **References** | Every source, with the date it was checked |

Three habits make the difference between reading this and learning it.

Attempt the Before you read prompt. Getting it wrong is not a failure mode, it is
the mechanism. An answer you guessed at and missed sticks better than one you were
handed.

Commit before you open a Predict block. Some output is hidden behind a question on
purpose. Decide on your answer first. Output you have already been shown teaches
you very little, and reading it feels productive, which is the problem.

Answer last week's Check yourself questions from memory before you reread
anything. This is the step people skip and the one carrying most of the benefit.
Rereading feels like progress because the words come easily the second time. That
feeling is fluency, not knowledge, and it is the most reliable way to walk into an
exam confident and underprepared.

### Why the order is not CompTIA's numbering

If you are also using a video course, you will notice immediately: almost all of
them follow the objectives document in order, 1.1 through 5.6. This track does
not, and the reason is that the numbering is a filing system rather than a
teaching order.

Two examples. Change management is objective 1.3, so a numbered course teaches
approval processes and backout plans in the first hour, before you have seen a
single control operating or know what the plan is protecting. Here it sits next to
policy and risk, near the end, where it makes sense on first reading.
Cryptography is objective 1.4, and then nothing uses it for two whole domains. Here
it is five consecutive topics early on, because certificates, data protection,
federation and code signing all assume it.

Every topic still declares the objectives it covers, so the
[coverage report](/learn/security-plus/coverage) shows the exam's own structure
even though the reading order does not.

### Where the output comes from

Every block of command output in this track is one of two things, and the page
always says which.

**Captured** means it was produced by running the command on a real system, in a
container pinned by digest, on a real virtual machine, against real loop devices,
or on a Windows or macOS runner, and pasted in unedited.

**Sourced** means it came from a standard or from vendor documentation, with the
document named. Governance, risk and compliance is a fifth of this exam and there
is nothing to run in it, so those topics say so rather than dressing up a
hand-written block as a transcript.

A block is one or the other. Nothing here is typed into a code fence from memory.

**One rule specific to a security track, and it is worth stating plainly.**
Nothing in this track runs an attack. Where a topic shows you what an attack looks
like, you are seeing the defender's side, produced by arranging the observable
state directly: a failed-login pattern comes from failed logins somebody made, and
an indicator comes from a published advisory rather than from a sample. The
technique is described, the evidence is captured, and the page says which half you
are looking at.

### The three things alongside the topics

| | What it is for |
| --- | --- |
| [Study plan](/learn/security-plus/plan) | Topics across weeks, each week's reading returning the following week. Start here if you have a date booked. |
| [Objective coverage](/learn/security-plus/coverage) | Every objective, which topics cover it, how many questions target it. This is where you find gaps, including gaps in this site. |
| Full practice exam | Weighted to the real domain percentages and timed. It appears once the question banks exist; the coverage report is the honest picture until then. |

Practice sets cover one domain at a time. They are good for finding a weak area
and deliberately not much use for anything else: a set where every question comes
from the same domain never makes you choose between approaches, so it flatters
you.

## Getting something to practise on

Here is the good news about this exam, and it is genuinely different from the
other two on this site. **You already own most of the lab.**

The machine you are reading this on has full-disk encryption in some state, a
certificate store with a few hundred organisations in it, a host firewall, an
authentication log, a patch level, a screen lock policy and a code-signing
verifier. Every one of those is a Security+ subject and you have an instance of
each. Most of the Try it sections in this track are one read-only command against
your own machine, and the topics give you the Linux, the Windows and the macOS
version.

Two rules go with that, and they are not negotiable.

**Everything this track asks you to run is read-only.** No topic tells you to
change a firewall rule, turn off a control, or install a scanner. Where the
interesting command would change something, you get the command that reads the
current state instead, and the topic says what the change would have been. A study
page that gets your work laptop flagged has done you real harm.

**Nothing gets run against anything you do not own.** Scanning, probing and
enumerating are techniques with a legal dimension, and the authorisation comes
before the technique every time. Where this track queries something on the
internet, it is a service that publishes the data for that purpose: the national
vulnerability database, the exploit prediction scores, the exploited-vulnerability
catalogue, and the certificate transparency logs.

If you want more than your own machine, a Linux virtual machine and a container
runtime cover almost everything else, and both are free.

## About the practice questions

Every question in this track is original, written from CompTIA's published
objectives and from primary documentation. None of it comes from anybody's memory
of a real exam, and none of it comes from a dump.

That is not only a legal position, although it is that too: the Candidate
Agreement prohibits disclosing exam content, and reconstruction through
memorisation is named in it specifically. It is also the reason the questions are
worth doing. An item copied from a real exam teaches you that item. An item
written from the objective teaches you the discrimination the objective is
testing, and every distractor here is a real control that is wrong for a reason
the explanation names.

## References

- [CompTIA Security+ certification page](https://www.comptia.org/en-us/certifications/security/) - CompTIA. Accessed 2026-08-21.
- [CompTIA Security+ SY0-701 Certification Exam Objectives, version 6.0](https://comptiacdn.azureedge.net/webcontent/docs/default-source/exam-objectives/comptia-security-sy0-701-exam-objectives-(6-0).pdf) - CompTIA. Accessed 2026-08-21.
- [Performance-Based Questions Explained](https://www.comptia.org/en-us/resources/test-policies/exam-development/performance-based-questions-explained/) - CompTIA. Accessed 2026-08-21.
- [Certification Renewal Policy](https://www.comptia.org/en-us/resources/test-policies/continuing-education-policies/certification-renewal-policy/) - CompTIA. Accessed 2026-08-21.
- [Renewing CompTIA Security+](https://www.comptia.org/en-us/resources/ce/renew-options/renewing-security-single/) - CompTIA. Accessed 2026-08-21.
- [CompTIA Candidate Agreement](https://www.comptia.org/en-us/resources/test-policies/comptia-candidate-agreement/) - CompTIA. Accessed 2026-08-21.

**Where the numbers came from.** The exam code, question count, time, pass mark,
languages, launch date and estimated retirement are CompTIA's published figures.
The renewal figures are from the renewal policy and the Security+ renewal page.
The scenario shares were counted from the objectives documents of all three exams
by reading the opening verb of each objective and weighting it by its domain's
share. The objectives document itself is copyright CompTIA; its objective numbers
and statements are reproduced here because they are how the exam is referenced,
and its sub-bullet content is not reproduced anywhere on this site.

CompTIA and Security+ are trademarks of CompTIA, Inc. This site is not affiliated
with, endorsed by, or sponsored by CompTIA. All practice questions are original
work written from CompTIA's published exam objectives.
