---
title: "Start here"
description: "What the CompTIA Network+ exam is, why the subject is worth certifying when every other exam assumes it, how these lessons are built, how to get something to practise on when you cannot buy a switch, and what is in the track."
track: "network-plus"
level: "intro"
order: 10
objectives:
  - "Decide whether this exam is the right one for you to sit"
  - "Say where your study time should go, from the published domain weights"
  - "Work through a topic the way it was designed to be worked through"
  - "Get a network you can break, without owning any network hardware"
  - "Find the study plan, the coverage report, and the practice sets"
prerequisites: []
tags: ["network-plus", "networking", "orientation"]
updated: 2026-08-09
draft: false
orientation: true
examObjectives: []
sources:
  - title: "CompTIA Network+ certification page"
    url: "https://www.comptia.org/en-us/certifications/network/"
    publisher: "CompTIA"
    accessed: 2026-08-09
    tier: 1
  - title: "CompTIA Network+ N10-009 Certification Exam Objectives, version 4.0"
    url: "https://comptiacdn.azureedge.net/webcontent/docs/default-source/exam-objectives/comptia-network-n10-009-exam-objectives-(4-0)-(1).pdf"
    publisher: "CompTIA"
    accessed: 2026-08-09
    tier: 1
  - title: "Performance-Based Questions Explained"
    url: "https://www.comptia.org/en-us/resources/test-policies/exam-development/performance-based-questions-explained/"
    publisher: "CompTIA"
    accessed: 2026-08-09
    tier: 1
  - title: "Certification Renewal Policy"
    url: "https://www.comptia.org/en-us/resources/test-policies/continuing-education-policies/certification-renewal-policy/"
    publisher: "CompTIA"
    accessed: 2026-08-09
    tier: 1
  - title: "Renewing CompTIA Network+"
    url: "https://www.comptia.org/en-us/resources/ce/renew-options/renewing-network-single/"
    publisher: "CompTIA"
    accessed: 2026-08-09
    tier: 1
  - title: "ip-netns(8)"
    url: "https://man7.org/linux/man-pages/man8/ip-netns.8.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-09
    tier: 1
  - title: "GNS3 network emulator"
    url: "https://www.gns3.com/"
    publisher: "GNS3"
    accessed: 2026-08-09
    tier: 2
  - title: "Cisco Packet Tracer"
    url: "https://www.netacad.com/cisco-packet-tracer"
    publisher: "Cisco Networking Academy"
    accessed: 2026-08-09
    tier: 2
  - title: "subnetting practice"
    url: "https://subnetipv4.com/"
    publisher: "subnetipv4.com"
    accessed: 2026-08-09
    tier: 2
symptoms: []
---

This page teaches no networking. It covers what the exam is, where your time
should go, how these lessons are built, and how to get a network you can break
when you do not own any network hardware. The networking starts on the next page.

## What the CompTIA Network+ exam is

A vendor-neutral certification covering the design, implementation, operation and
troubleshooting of networks. Vendor-neutral is doing real work in that sentence.
The exam names a routing protocol without naming whose implementation, and asks
about a switch command family without committing to one vendor's syntax, because
it is testing whether you understand the mechanism rather than whether you have
memorised a menu.

| | |
| --- | --- |
| Code | N10-009, also labelled V9 |
| Launched | 20 June 2024 |
| Questions | Maximum of 90, multiple-choice and performance-based |
| Time | 90 minutes |
| Passing score | 720 on a scale of 100 to 900 |
| Languages | English, German, Japanese, Portuguese, Spanish |
| Valid for | Three years, renewable with 30 CEUs |

The scale is not a percentage. 720 out of 900 is not 80 percent, because the
scale starts at 100, and CompTIA does not publish how raw answers map onto it.
Any tool showing you a scaled score, this site included, is approximating.

**CompTIA gives two different answers on experience**, and it is worth knowing
both before you decide you are not ready. The objectives document asks for "A
minimum of 9–12 months of experience in the IT networking field" and stops there.
The certification page asks for A+ as well, phrased as "CompTIA A+ certification,
with 9 to 12 months of hands-on experience in a junior network administrator or
network support technician role". Neither is a gate. Nobody checks, and this
track is written for somebody at zero.

### Where your time should go

Five domains, sorted by weight rather than by number, because that ordering is
the one that should decide what you study.

| Domain | Weight |
| --- | --- |
| 5.0 Network Troubleshooting | 24% |
| 1.0 Networking Concepts | 23% |
| 2.0 Network Implementation | 20% |
| 3.0 Network Operations | 19% |
| 4.0 Network Security | 14% |

**Troubleshooting is the largest domain on this exam.** Not joint largest.
Larger than concepts, and ten points larger than security. Nearly every book and
course on the market opens with the OSI model and closes with a troubleshooting
chapter that reads like an afterthought, which is exactly backwards from where
the marks are. This track gives troubleshooting sixteen topics and puts the
diagnostic thinking into the earlier topics too.

The security domain is the other surprise, in the other direction. Fourteen
percent, three objectives. If you have come from Security+ or you work in
security, the temptation is to spend your evenings there. Resist it.

### Performance-based questions, and one piece of good news

PBQs drop you into a simulated tool and score what you leave behind. They are
why hands-on time matters more than reading time.

The good news is specific to this exam. CompTIA delivers PBQs either as
simulations or inside a virtual environment, and **Network+ uses simulations
only.** That means you can skip a hard one and come back to it, and CompTIA says
your work is saved as you go and when you move to another item. The advice you
will read elsewhere about being unable to leave a PBQ applies to the virtual
kind, which this exam does not use.

Partial credit may be given, and scoring anticipates more than one valid
approach. "May" is CompTIA's word and it is worth keeping: partial credit exists,
and how it is apportioned is not published.

## Why bother certifying this

Every other certification you might sit assumes it. Security+ talks about
segmentation and expects you to know what a broadcast domain is. Cloud exams talk
about a virtual private cloud and expect subnetting to be reflex. Linux+ has you
configure an interface and read a routing table in the middle of a system
administration exam. Networking is the layer underneath the thing you actually
want to do, and it is the one people skip and then quietly work around for years.

There is a second reason, which is what this track is organised around. Most
networking problems are not solved by knowing more facts. They are solved by
being able to say what a network is currently doing, as opposed to what somebody
believes it is doing, and then proving it. That skill transfers to every job that
touches infrastructure, and it happens to be exactly what a 24 percent
troubleshooting domain is testing.

## How to work through these lessons

Every topic has the same shape, so once you have read two you know where to look
in the third.

| Section | What it is for |
| --- | --- |
| **Before you read** | A question you cannot yet answer. Attempt it anyway. |
| **Some words you will need** | The vocabulary the rest of the topic assumes |
| **What breaks without this** | The consequence of not knowing it |
| **Predict** | Captured output hidden behind a question. Answer first, then open. |
| **If you already work on networks** | Depth for readers who have done this before. Safe to skip. |
| **Across platforms** | The same task on a switch, on Linux, and on Windows |
| **Prove it** | The evidence: a command to run, arithmetic to do, or a named clause in a standard to go and read |
| **What trips people up** | The failures you will hit, with the real error text |
| **Work it through** | A scenario reasoned out on the page |
| **Try it** | Optional, and it does not need hardware |
| **Check yourself** | Retrieval questions, for next week rather than now |
| **References** | Every source, with the date it was checked |

Troubleshooting topics carry two more. **For the exam** is the compressed version
worth taking into the test centre, and **Where this sits** places the topic
against the objectives.

Three habits make the difference between reading this and learning it.

Attempt the Before you read prompt. Getting it wrong is not a failure mode, it is
the mechanism. An answer you guessed at and missed sticks better than one you
were handed, and that is a measured effect rather than encouragement.

Commit before you open a Predict block. Some output is hidden behind a question
on purpose. Decide on your answer first. Output you have already been shown
teaches you very little, and reading it feels productive, which is the problem.

Answer last week's Check yourself questions from memory before you reread
anything. This is the step people skip and the one carrying most of the benefit.
Rereading feels like progress because the words come easily the second time. That
feeling is fluency, not knowledge, and it is the most reliable way to walk into
an exam confident and underprepared.

### Where the output comes from

Every block of command output in this track is one of two things, and the page
always says which.

**Captured** means it was produced by running the command on a real network built
out of Linux network namespaces, and pasted in unedited. The routers route, the
switches learn MAC addresses and run spanning tree, and when a topic shows you a
blocked port it is because the protocol blocked it.

**Sourced** means it came from a standard or from vendor documentation, with the
document named. About a third of this exam is cabling, connectors, radio,
physical installation and process, and none of that can be captured honestly by
software. Those topics say so instead of dressing up a hand-written block as a
transcript.

A block is one or the other. Nothing here is typed into a code fence from memory.

### The three things alongside the topics

| | What it is for |
| --- | --- |
| [Study plan](/learn/network-plus/plan) | Topics across weeks, each week's reading returning the following week. Start here if you have a date booked. |
| [Objective coverage](/learn/network-plus/coverage) | Every objective, which topics cover it, how many questions target it. This is where you find gaps, including gaps in this site. |
| Full practice exam | Weighted to the real domain percentages and timed. It appears once the question banks exist; the coverage report is the honest picture until then. |

Practice sets cover one domain at a time. They are good for finding a weak area
and deliberately not much use for anything else: a set where every question comes
from the same domain never makes you choose an approach, so it flatters you.

## Getting something to practise on

Here is the awkward part of studying for this exam. You cannot buy the lab. A
managed switch, a router, an access point and the cabling to join them is real
money and a cupboard you do not have, and the exam expects you to have touched
all of it.

Two useful things follow from that.

The first is that most of what the exam tests about switching and routing is
reproducible in software, on any Linux machine, for free. Network namespaces give
you isolated hosts; virtual Ethernet pairs are the cables between them; a Linux
bridge is a switch that genuinely learns MAC addresses, filters VLANs and runs
spanning tree. That is how the captured output in this track is made, and the
topologies are committed alongside it so you can run the same thing. You need a
Linux virtual machine and nothing else.

The second is that the parts you cannot reproduce are also the parts that are
cheapest to learn from documentation. A connector is a shape. A cable category is
a table of distances and speeds. You do not need to hold an LC connector to
answer a question about one, and pretending otherwise would just be an excuse to
put off starting.

If you want a graphical network simulator on top of that:

| | What it is, and the catch |
| --- | --- |
| [GNS3](https://www.gns3.com/) | Free and open source. It emulates the topology; you supply the device images, so the genuinely free path is open-source routers rather than vendor ones. |
| [Cisco Packet Tracer](https://www.netacad.com/cisco-packet-tracer) | Free to Networking Academy students, instructors and alumni, which means enrolling in a free course to get it. Apple Silicon support is not something I can confirm from Cisco's own pages, so check before you plan around it. |
| [subnetipv4.com](https://subnetipv4.com/) | Not a simulator. Unlimited subnetting problems with worked solutions, which is the one skill on this exam that only volume fixes. |

Subnetting deserves that last row. It is arithmetic under time pressure, and no
amount of reading substitutes for having done a hundred of them. This track
teaches why the arithmetic works and gives you the method. Getting fast is
repetition, and somebody else already built the tool for that.

## References

- [CompTIA Network+ certification page](https://www.comptia.org/en-us/certifications/network/) - CompTIA. Accessed 2026-08-09.
- [CompTIA Network+ N10-009 Certification Exam Objectives, version 4.0](https://comptiacdn.azureedge.net/webcontent/docs/default-source/exam-objectives/comptia-network-n10-009-exam-objectives-(4-0)-(1).pdf) - CompTIA. Accessed 2026-08-09.
- [Performance-Based Questions Explained](https://www.comptia.org/en-us/resources/test-policies/exam-development/performance-based-questions-explained/) - CompTIA. Accessed 2026-08-09.
- [Certification Renewal Policy](https://www.comptia.org/en-us/resources/test-policies/continuing-education-policies/certification-renewal-policy/) - CompTIA. Accessed 2026-08-09.
- [Renewing CompTIA Network+](https://www.comptia.org/en-us/resources/ce/renew-options/renewing-network-single/) - CompTIA. Accessed 2026-08-09.
- [ip-netns(8)](https://man7.org/linux/man-pages/man8/ip-netns.8.html) - Linux man-pages project. Accessed 2026-08-09.
- [GNS3](https://www.gns3.com/) - GNS3. Accessed 2026-08-09.
- [Cisco Packet Tracer](https://www.netacad.com/cisco-packet-tracer) - Cisco Networking Academy. Accessed 2026-08-09.
- [subnetipv4.com](https://subnetipv4.com/) - subnetipv4.com. Accessed 2026-08-09.

Domain weightings and exam details are CompTIA's published figures. The
objectives document itself is copyright CompTIA and is not reproduced here.
