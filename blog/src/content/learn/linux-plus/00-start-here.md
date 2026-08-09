---
title: "Start here"
description: "What the CompTIA Linux+ exam is, where Linux came from and why it ended up everywhere, how to work through these lessons, how to set up a machine to practise on, and what is in the track."
track: "linux-plus"
level: "intro"
order: 10
objectives:
  - "Decide whether this exam is the right one for you to sit"
  - "Explain in one paragraph why Linux skills are worth certifying"
  - "Work through a topic the way it was designed to be worked through"
  - "Set up a virtual machine to practise on, and snapshot it before breaking it"
  - "Find the study plan, the coverage report, and the practice sets"
prerequisites: []
tags: ["linux-plus", "orientation"]
updated: 2026-08-09
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
  - title: "UTM: virtual machines for macOS"
    url: "https://docs.getutm.app/"
    publisher: "UTM"
    accessed: 2026-08-09
    tier: 1
  - title: "Oracle VirtualBox user manual"
    url: "https://www.virtualbox.org/manual/"
    publisher: "Oracle"
    accessed: 2026-08-09
    tier: 1
  - title: "Advanced settings configuration in WSL"
    url: "https://learn.microsoft.com/en-us/windows/wsl/wsl-config"
    publisher: "Microsoft"
    accessed: 2026-08-09
    tier: 1
symptoms: []
---

This page teaches no Linux. It tells you what the exam is, why the subject is
worth your evenings, how these lessons are built, how to get a machine to
practise on, and what is in the track. The Linux starts on the next page.

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
track gives it fourteen topics. And **automation is not a footnote**: seventeen
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
| **Some words you will need** | The vocabulary the rest of the topic assumes |
| **What breaks without this** | The consequence of not knowing it |
| **Predict** | Captured output hidden behind a question. Answer first, then open. |
| **If you already administer Linux** | Depth for readers who have done this before. Safe to skip. |
| **Across distributions** | Where the RHEL and Debian families diverge |
| **Prove it** | The commands that show the change took effect |
| **What trips people up** | The failures you will actually hit, with the real error text |
| **Work it through** | A scenario reasoned out on the page |
| **Try it** | Optional, if you have a machine handy |
| **Check yourself** | Retrieval questions, for next week rather than now |
| **References** | Every source, with the date it was checked |

The troubleshooting topics carry two more. **For the exam** is the compressed
version worth taking into the test centre, and **Where this sits** places the
topic against the objectives. Diagrams turn up wherever a concept is structural
rather than in a section of their own.

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

## Getting a machine to practise on

Do this before the next page. Most topics here end with a **Try it** section that
assumes you have somewhere to type, and the exam assumes twelve months of doing
exactly that.

**Start with one distribution and add the second around topic 08.** The exam is
vendor-neutral and tests where the two families diverge, so you eventually want
one of each: AlmaLinux or Rocky on the RHEL side, Debian or Ubuntu Server on the
other. Which one you begin with matters far less than beginning.

How to run it depends on what you are sitting at:

| Host | What to use |
| --- | --- |
| Mac, Apple Silicon | UTM, which is free and open source. Download the distribution's arm64 image. |
| Mac, Intel | UTM or VirtualBox |
| Windows | VirtualBox, or Hyper-V if you have Pro or Enterprise |
| Windows, quick option | `wsl --install`, with the caveat below |
| Linux | virt-manager over KVM, which is already in your package manager |
| Nothing local | The smallest instance any cloud provider sells |

Two vCPUs, 2 GB of memory, and 20 GB of disk carry you through the whole track.
Choose the server or minimal install rather than a desktop, because that is what
the exam is written against and it boots in seconds.

**WSL is the fast route and it cannot teach you everything.** It runs a Microsoft
kernel with no bootloader and no real disks attached by default, so the boot
topic, most of the kernel module topic, and everything from disks through RAID
will not behave. Use it for the shell, scripting, text processing, and
permissions. Use a real virtual machine for the rest. If you go this way,
`systemd` needs turning on deliberately: put `[boot]` and `systemd=true` into
`/etc/wsl.conf` and run `wsl --shutdown`.

**Take a snapshot the moment the install finishes, before you have done
anything.** This is the habit that makes the rest of the track work. You are
about to deliberately break things: fill a disk, corrupt an `fstab` entry, lock
an account out, misconfigure a firewall until you cannot reach the machine. All
of that is the point, and it is only the point if getting back costs you thirty
seconds rather than an evening. Snapshot again before any topic that changes
system state.

One practical note. Work over `ssh` from your own terminal rather than in the
hypervisor's console window, because copy and paste works properly and scrollback
survives. Topic 43 covers `ssh` properly; for now, `ssh yourname@the-vm-address`
is the whole of it.

Running on arm64 changes nothing that matters here. Every distribution on that
list publishes arm64 images, and the commands are identical.

## References

- [Linux+ (V8) exam details](https://www.comptia.org/en-us/certifications/linux/v8/) - CompTIA. Accessed 2026-08-07.
- [About Linux Kernel](https://www.kernel.org/category/about.html) - kernel.org. Accessed 2026-08-07.
- [Linux and the GNU System](https://www.gnu.org/gnu/linux-and-gnu.html) - GNU Project. Accessed 2026-08-07.
- [TOP500 operating system family statistics](https://www.top500.org/statistics/details/osfam/1/) - TOP500. Accessed 2026-08-07.
- [A guide to the Kernel Development Process](https://www.kernel.org/doc/html/latest/process/development-process.html) - kernel.org. Accessed 2026-08-07.
- [SadServers scenarios](https://sadservers.com/scenarios) - SadServers. Accessed 2026-08-07.
- [OverTheWire: Bandit](https://overthewire.org/wargames/bandit/) - OverTheWire. Accessed 2026-08-07.
- [Linux Upskill Challenge](https://linuxupskillchallenge.org/) - Linux Upskill Challenge. Accessed 2026-08-07.
- [UTM documentation](https://docs.getutm.app/) - UTM. Accessed 2026-08-09.
- [Oracle VirtualBox user manual](https://www.virtualbox.org/manual/) - Oracle. Accessed 2026-08-09.
- [Advanced settings configuration in WSL](https://learn.microsoft.com/en-us/windows/wsl/wsl-config) - Microsoft. Accessed 2026-08-09.

Domain weightings and exam details are CompTIA's published figures. The
objectives document itself is copyright CompTIA and is not reproduced here.
