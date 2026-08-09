---
title: "Start here"
description: "What the CompTIA Linux+ exam is, where Linux came from and why it ended up everywhere, how to work through these lessons, and what is in the track."
track: "linux-plus"
level: "intro"
order: 10
objectives:
  - "Decide whether this exam is the right one for you to sit"
  - "Explain in one paragraph why Linux skills are worth certifying"
  - "Work through a topic the way it was designed to be worked through"
  - "Find the study plan, the coverage report, and the practice sets"
prerequisites: []
tags: ["linux-plus", "orientation"]
updated: 2026-08-07
draft: false
orientation: true
examObjectives: []
sources:
  - title: "Linux+ (V8) exam details"
    url: "https://www.comptia.org/en-us/certifications/linux/v8/"
    publisher: "CompTIA"
    accessed: 2026-08-07
    tier: 1
  - title: "About Linux Kernel"
    url: "https://www.kernel.org/category/about.html"
    publisher: "kernel.org"
    accessed: 2026-08-07
    tier: 1
  - title: "Linux and the GNU System"
    url: "https://www.gnu.org/gnu/linux-and-gnu.html"
    publisher: "GNU Project"
    accessed: 2026-08-07
    tier: 1
  - title: "TOP500 supercomputer operating system family statistics"
    url: "https://www.top500.org/statistics/details/osfam/1/"
    publisher: "TOP500"
    accessed: 2026-08-07
    tier: 1
  - title: "A guide to the Kernel Development Process"
    url: "https://www.kernel.org/doc/html/latest/process/development-process.html"
    publisher: "kernel.org"
    accessed: 2026-08-07
    tier: 1
  - title: "SadServers: troubleshooting scenarios on real machines"
    url: "https://sadservers.com/scenarios"
    publisher: "SadServers"
    accessed: 2026-08-07
    tier: 2
  - title: "OverTheWire: Bandit"
    url: "https://overthewire.org/wargames/bandit/"
    publisher: "OverTheWire"
    accessed: 2026-08-07
    tier: 2
  - title: "Linux Upskill Challenge"
    url: "https://linuxupskillchallenge.org/"
    publisher: "Linux Upskill Challenge"
    accessed: 2026-08-07
    tier: 2
symptoms: []
---

This page teaches nothing. It tells you what the exam is, why the subject is
worth your evenings, how these lessons are built, and what is in the track. The
Linux starts on the next page.

## What the CompTIA Linux+ exam is

A vendor-neutral certification covering the administration of Linux servers:
managing them, securing them, automating them, and fixing them when they break.
Vendor-neutral matters here. It is not a Red Hat exam or an Ubuntu exam, so it
tests the split between distribution families rather than the habits of one.

| | |
| --- | --- |
| Code | XK0-006, also labelled V8 |
| Questions | Maximum of 90, multiple-choice and performance-based |
| Time | 90 minutes |
| Passing score | 720 on a scale of 100 to 900 |
| Languages | English |
| Delivery | Pearson VUE, at a test centre or online through OnVUE |
| Valid for | Three years, renewable with 50 CEUs |
| Recommended experience | 12 months of hands-on work with Linux servers |

Five domains, sorted here by weight rather than by number, because that ordering
is the one that should decide where your time goes:

| Domain | Weight |
| --- | --- |
| 1.0 System Management | 23% |
| 5.0 Troubleshooting | 22% |
| 2.0 Services and User Management | 20% |
| 3.0 Security | 18% |
| 4.0 Automation, Orchestration, and Scripting | 17% |

Two things follow from that table. **Troubleshooting is within a point of the
largest domain**, and most study material treats it as a closing chapter; this
track gives it seven topics. And **automation is not a footnote**: seventeen
percent covers configuration management, orchestration, two languages, and
version control.

The scale is not a percentage. 720 out of 900 is not 80 percent, because the
scale starts at 100, and CompTIA does not publish how raw answers map onto it.
Any tool showing you a scaled score, this site included, is approximating.

**Performance-based questions** drop you into a simulated tool or a real virtual
machine and score the state you leave behind. They are why twelve months of
hands-on experience is the recommendation rather than a formality, and they are
the reason this site alone is not enough. More on that below.

## Where Linux came from, and why it is everywhere

Worth five minutes, because it explains why the exam is shaped the way it is.

In 1983 the GNU Project set out to build a complete free operating system, and
by the end of the decade had most of one: the compiler, the shell, the core
utilities, the text tools. What it did not have was a working kernel.

In 1991 a student in Helsinki, Linus Torvalds, started a kernel as a personal
project and released it under a licence that let anyone use, modify, and
redistribute it, provided derivative work carried the same freedoms. The GNU
tools and that kernel fit together, and the combination was a complete operating
system that nobody owned.

That licensing decision is the whole story. Because no single company controlled
it, hardware vendors, universities, and eventually every large technology company
could adopt it, modify it for their own purposes, and contribute back. The result
is a kernel developed at a scale that no single organisation funds.

Where it ended up:

- **All 500 of the world's fastest supercomputers run Linux.** Not most. All of
  them, and that has been true for years.
- **Cloud infrastructure runs on it.** The instances, the hypervisors underneath
  them, and the container images inside them.
- **Containers are a Linux feature.** Namespaces and cgroups are kernel
  facilities; Docker and Podman are interfaces to them. Container platforms on
  other operating systems run a Linux virtual machine to provide them.
- **Android is built on the Linux kernel**, which is why the most common consumer
  operating system on earth is a Linux one.

For someone administering systems, the practical version is simpler: the servers
are Linux, the pipelines run on Linux, the containers are Linux, and the security
controls you are asked to validate are Linux controls. That is what makes the
skill worth certifying, and it is why this exam leans on troubleshooting and
automation rather than on trivia.

## How to work through these lessons

Every topic has the same shape, so once you have read two you know where to look
in the third:

| Section | What it is for |
| --- | --- |
| **Before you read** | A question you cannot yet answer. Attempt it anyway. |
| **What breaks without this** | The consequence of not knowing it |
| **The mental model** | A diagram, when the concept is structural |
| **Minimum working example** | The smallest thing that runs |
| **How it actually behaves** | Real captured command output |
| **Across distributions** | Where the families diverge |
| **Prove it** | The commands that show the change took effect |
| **What trips people up** | Three or four failures, with the real error text |
| **Work it through** | A scenario reasoned out on the page |
| **Try it** | Optional, if you have a machine handy |
| **Check yourself** | Retrieval questions |
| **References** | Every source, with the date it was checked |

Three habits make the difference between reading this and learning it.

**Attempt the Before you read prompt.** Getting it wrong is not a failure mode,
it is the mechanism. An answer you guessed at and missed sticks better than one
you were handed, and that is a measured effect rather than a motivational
sentiment.

Commit before you open a Predict block. Some command output is hidden behind a
question. Decide on your answer first. Output you have already been shown
teaches you very little, and reading it feels productive, which is exactly the
problem.

Answer last week's Check yourself questions from memory before you reread
anything. This is the step people skip, and it is the one carrying most of the
benefit. Rereading feels like progress because the words come easily the
second time. That feeling is fluency, not knowledge, and it is the most
reliable way to walk into an exam confident and underprepared.

### The three things alongside the topics

| | What it is for |
| --- | --- |
| [Study plan](/learn/linux-plus/plan) | Topics across weeks, each week's reading returning the following week. Start here if you have a date booked. |
| [Objective coverage](/learn/linux-plus/coverage) | Every objective, which topics cover it, how many questions target it. This is where you find gaps, including gaps in this site. |
| [Full practice exam](/learn/linux-plus/exam) | Weighted to the real domain percentages and timed. The readiness check, and where the exam-day technique lives. |

Practice sets cover one domain at a time. They are useful for finding a weak
area and deliberately not much use for anything else: a set where every question
comes from the same domain never makes you choose an approach, so it flatters
you.

## This site is the reading half

Performance-based questions are scored on the state you leave a system in, and no
amount of reading produces that. Reading gets you the understanding; a machine
you can break and fix gets you the fluency.

This track does not simulate a terminal, and it should not. These do it better
than a study site could:

| Where | What it is good for |
| --- | --- |
| [SadServers](https://sadservers.com/scenarios) | Break-fix scenarios on real machines. The closest free thing to a Linux+ PBQ. |
| [OverTheWire: Bandit](https://overthewire.org/wargames/bandit/) | Command-line fluency through puzzles. Builds the speed that keeps you inside the clock. |
| [Linux Upskill Challenge](https://linuxupskillchallenge.org/) | Twenty days on a server you administer yourself. Builds the habit. |

A virtual machine of your own beats all of them, because you can break it in ways
a curated exercise will not. Any distribution on CompTIA's recommended list will
do: AlmaLinux, Debian, Fedora, openSUSE or SLES, Red Hat Enterprise Linux, Rocky,
or Ubuntu.

## References

- [Linux+ (V8) exam details](https://www.comptia.org/en-us/certifications/linux/v8/) - CompTIA. Accessed 2026-08-07.
- [About Linux Kernel](https://www.kernel.org/category/about.html) - kernel.org. Accessed 2026-08-07.
- [Linux and the GNU System](https://www.gnu.org/gnu/linux-and-gnu.html) - GNU Project. Accessed 2026-08-07.
- [TOP500 operating system family statistics](https://www.top500.org/statistics/details/osfam/1/) - TOP500. Accessed 2026-08-07.
- [A guide to the Kernel Development Process](https://www.kernel.org/doc/html/latest/process/development-process.html) - kernel.org. Accessed 2026-08-07.
- [SadServers scenarios](https://sadservers.com/scenarios) - SadServers. Accessed 2026-08-07.
- [OverTheWire: Bandit](https://overthewire.org/wargames/bandit/) - OverTheWire. Accessed 2026-08-07.
- [Linux Upskill Challenge](https://linuxupskillchallenge.org/) - Linux Upskill Challenge. Accessed 2026-08-07.

Domain weightings and exam details are CompTIA's published figures. The
objectives document itself is copyright CompTIA and is not reproduced here.
