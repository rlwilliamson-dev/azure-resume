---
title: "Narrowing a fault by layer"
description: "Fifteen candidates, two machines, and one afternoon. Top-down, bottom-up and divide-and-conquer as three named ways to search the stack, why the discriminating test is the only real unit of progress, and why one test in the middle beats ten in a row."
deck: "Fifteen candidates, two machines, and one afternoon"
track: "network-plus"
level: "working"
order: 660
objectives:
  - "Name the three approaches to searching the stack and pick one on purpose"
  - "Explain why the discriminating test is the unit of progress"
  - "Show how one test can eliminate half the candidates"
  - "Say when top-down, bottom-up and divide-and-conquer each fit"
  - "Explain why experts skip the ladder and why you should not yet"
prerequisites: ["the-osi-model", "ping-traceroute-and-what-they-prove"]
tags: ["network-plus", "networking", "troubleshooting", "methodology"]
updated: 2026-08-19
draft: false
examObjectives:
  - exam: "n10-009"
    domain: "5.0"
    objective: "5.1"
sources:
  - title: "CompTIA Network+ N10-009 Exam Objectives"
    url: "https://www.comptia.org/certifications/network"
    publisher: "CompTIA"
    accessed: 2026-08-19
    tier: 1
  - title: "RFC 1122, Requirements for Internet Hosts, Communication Layers"
    url: "https://www.rfc-editor.org/rfc/rfc1122"
    publisher: "IETF"
    accessed: 2026-08-19
    tier: 1
symptoms:
  - symptom: "A fault has many candidate causes and no obvious starting point"
    anchor: "the-three-approaches"
  - symptom: "Time is spent gathering detail that does not rule anything out"
    anchor: "the-discriminating-test"
---

> **Before you read.** A user cannot reach an internal web application. Between
> their keyboard and the server there is a cable, a switch, a VLAN, a router, a
> firewall, DNS, the server's network stack, and the application itself. Any one of
> them could be the fault, that is fifteen candidates, and you have an afternoon
> before it becomes an escalation.
>
> **You cannot check all fifteen. Which do you check first, and why that one?**

Topic 61 was the method as a whole. This is the one step inside it where most of the
skill lives: forming and testing a theory against a stack of layers, where the order
you test in decides whether the afternoon is enough. The idea that makes it tractable
is small and it is the whole topic: a good test does not gather detail, it eliminates
candidates.

### Some words you will need

<dl class="terms">
<dt>the stack</dt>
<dd>The layers a request passes through, from the physical cable up to the application, from topic 03. A fault lives at one of them.</dd>
<dt>top-down</dt>
<dd>Start at the application and work down toward the physical.</dd>
<dt>bottom-up</dt>
<dd>Start at the physical and work up toward the application.</dd>
<dt>divide and conquer</dt>
<dd>Test in the middle, and let the result throw away the half that cannot contain the fault.</dd>
<dt>discriminating test</dt>
<dd>A test whose result rules candidates in or out. The opposite of one that only gathers more detail.</dd>
</dl>

## What breaks without this

**You check candidates in the order they occur to you.** That order has nothing to do
with which is likely or which is quick to test, and it is how fifteen candidates take
fifteen tests instead of four.

**You gather detail that rules nothing out.** Collecting more information about the
symptom feels like progress and often is not, because it does not shrink the list of
possible causes. Only a test that eliminates candidates does that.

**You run the ladder from the wrong end.** Starting at the physical layer for a fault
that is obviously in the application, or the reverse, spends the afternoon climbing
past everything that was never the problem.

## The three approaches

The stack is an ordered list of layers, and a fault sits at one of them. That framing
is what makes the search tractable, because searching an ordered space has known good
strategies, and CompTIA names three.

**Top-down** starts at the application and works down. It fits when the symptom is
specific to one application and everything else on the machine works, because that
already suggests the fault is high up, so you start where it probably is.

**Bottom-up** starts at the physical layer and works up. It fits when nothing works at
all, a dead port, a machine that reaches nothing, because a total failure is usually low
in the stack, so you start at the bottom where it probably is.

**Divide and conquer** ignores both ends and tests the middle. It fits when you have no
strong prior about where the fault is, which is most of the time, because a test in the
middle eliminates half the stack whichever way it comes out, and that is the fastest way
to search when you do not already suspect an end.

<figure class="learn-figure">
<svg viewBox="0 0 720 268" role="img" aria-labelledby="divide-title" style="width:100%;height:auto;">
<title id="divide-title">A stack of layers where a single test at the network layer, if it passes, eliminates the network and physical layers below it and leaves only the transport and application layers above to search</title>
<g fill="currentColor">
<text x="14" y="20" font-size="11">one test in the middle throws away half the stack, whichever way it comes out</text>
<rect x="250" y="40" width="220" height="40" rx="4" fill="var(--accent)" fill-opacity="0.1" stroke="var(--accent)" stroke-opacity="0.85" stroke-width="1.4"/>
<text x="360" y="64" text-anchor="middle" font-size="10.5">application</text>
<rect x="250" y="84" width="220" height="40" rx="4" fill="var(--accent)" fill-opacity="0.1" stroke="var(--accent)" stroke-opacity="0.85" stroke-width="1.4"/>
<text x="360" y="108" text-anchor="middle" font-size="10.5">transport</text>
<rect x="250" y="128" width="220" height="40" rx="4" fill="currentColor" fill-opacity="0.05" stroke="currentColor" stroke-opacity="0.55" stroke-dasharray="5 4"/>
<text x="360" y="152" text-anchor="middle" font-size="10.5" fill-opacity="0.6">network</text>
<rect x="250" y="172" width="220" height="40" rx="4" fill="currentColor" fill-opacity="0.05" stroke="currentColor" stroke-opacity="0.55" stroke-dasharray="5 4"/>
<text x="360" y="196" text-anchor="middle" font-size="10.5" fill-opacity="0.6">link and physical</text>
<path d="M 236 148 H 100" stroke="var(--accent)" stroke-width="1.8" fill="none"/>
<path d="M 108 143 l -8 5 l 8 5" stroke="var(--accent)" stroke-width="1.8" fill="none"/>
<text x="40" y="132" font-size="9.5" fill="var(--accent)">one test</text>
<text x="40" y="145" font-size="9.5" fill="var(--accent)">here:</text>
<text x="40" y="158" font-size="9.5" fill="var(--accent)">a ping</text>
<text x="486" y="58" font-size="9.5" fill="var(--accent)">still</text>
<text x="486" y="71" font-size="9.5" fill="var(--accent)">suspect:</text>
<text x="486" y="84" font-size="9.5" fill="var(--accent)">search here</text>
<text x="486" y="150" font-size="9.5" fill-opacity="0.6">proven good</text>
<text x="486" y="163" font-size="9.5" fill-opacity="0.6">by the ping:</text>
<text x="486" y="176" font-size="9.5" fill-opacity="0.6">eliminated</text>
</g></svg>
<figcaption>The fault is at one of the layers, and a ping is a test at the network layer. If it succeeds, everything at and below the network layer is proven to work, because a ping could not complete otherwise, so the whole bottom of the stack is eliminated in one test and the fault must be in the transport or application layer above. If the ping fails, the opposite: the top is eliminated and the fault is at or below the network layer. Either result throws away half the candidates, which is why divide and conquer is the default when you have no reason to suspect an end. Top-down and bottom-up are the same search started from a layer you already suspect.</figcaption>
</figure>

<details class="deeper">
<summary>If you already pick one instinctively: why naming the choice still helps</summary>

Experienced engineers do not consciously select an approach, and there are two situations
where naming it out loud earns its place anyway.

The first is when you are stuck. A fault that has resisted an hour of work has usually
resisted one approach applied repeatedly, and the reason it feels like there is nothing left
to try is that the approach has run out rather than the candidates. Saying which one you
have been using makes the alternative obvious: an hour of top-down that has found nothing
means the fault is probably below where you have been looking.

The second is when you are not alone. Two people troubleshooting without saying how are
duplicating each other, because both will start where their own experience points, which is
usually the same place. Ten seconds agreeing that one works down from the application while
the other works up from the physical covers twice the ground and meets in the middle, which
is the only version of divide and conquer that uses two people properly.

Both are cases where the value is in coordination rather than technique. The approaches
themselves are not sophisticated and the discipline of naming which one is running is what
turns a fast individual into a fast pair, and what stops an hour of instinct from becoming
two hours of the same instinct.

</details>

## The discriminating test

The three approaches are ways of ordering the search. What actually moves the search
forward is the individual test, and only a particular kind of test counts: one whose
result eliminates candidates. That is the discriminating test, and distinguishing it
from a test that merely gathers detail is the single most useful habit in
troubleshooting.

The lab shows one. A client cannot load a web application on a server, and the
candidate list is long. One ping settles half of it. The topology is
[`sockets.sh`](https://github.com/rlwilliamson-dev/azure-resume/blob/main/blog/scripts/topologies/sockets.sh).

<details class="predict">
<summary>One test taken in the middle of the stack rather than at either end. Whichever way it comes back, what has it ruled out?</summary>

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology sockets
# the report: the website on h1 will not load. fifteen things could cause that
$ ip netns exec h2 curl -s --max-time 3 -o /dev/null -w "curl to h1 port 80: %{http_code} (000 means no answer, exit 7)\n" http://10.0.0.1/
curl to h1 port 80: 000 (000 means no answer, exit 7)
# one test at layer 3 splits the stack in half: is the network the problem?
$ ip netns exec h2 ping -c1 -W1 10.0.0.1 | grep -E "bytes from|packet loss"
64 bytes from 10.0.0.1: icmp_seq=1 ttl=64 time=0.031 ms
1 packets transmitted, 1 received, 0% packet loss, time 0ms
# ping works, so cabling, addressing, gateway and routing are all fine. the fault
# is above layer 3, and the service is simply not on the port we asked for
$ ip netns exec h2 curl -s --max-time 3 -o /dev/null -w "curl to h1 port 8000: %{http_code}\n" http://10.0.0.1:8000/
curl to h1 port 8000: 200
```

</details>

Read it as three moves. The web request to port 80 fails, which is the symptom and
tells you nothing yet about where. The ping succeeds, and that is the discriminating
test: it proves the network layer and everything under it works, because the ping could
not have completed otherwise, so cabling, addressing, the switch, and routing are all
eliminated in one command. The fault is above the network layer. The third command
confirms it: the service is reachable on a different port, so the server, its stack, and
its reachability are all fine, and the fault is that the application is not on the port
the client asked for. Fifteen candidates down to one, in three commands, because the
middle one eliminated rather than gathered.

Compare that to the tempting alternative, which is to gather: check the cable, read the
interface, look at the switch, examine the routing table, one after another. Each of
those produces information and none of it rules the others out, so after five commands
you know a great deal and have eliminated nothing. The ping eliminated four layers at
once because its result was incompatible with the fault being in any of them.

<details class="deeper">
<summary>If you already troubleshoot for a living: why experts skip the ladder, and why you should climb it anyway</summary>

Watch an experienced engineer troubleshoot and they do not divide and conquer. They walk
up to the problem, glance at it, and test one specific thing near the actual fault,
usually getting it in one or two moves. It can look like they have skipped the method
entirely, and in a sense they have.

What they are actually doing is pattern matching against a large store of faults they
have seen before. "The website is down but ping works and it is refused rather than timed
out" is not fifteen candidates to them, it is a shape they recognise, and the shape points
at a small service problem directly. The method compressed into a reflex. They are not
searching the stack, they are recognising which fault this is.

The reason to run the ladder deliberately anyway, until you are one of them, is that the
store of recognised shapes is built by running the ladder. Every fault you narrow the slow
way, with a discriminating test that eliminated half the stack, becomes a shape you will
recognise the fast way next time. Skipping to the guess before you have the store means
guessing without the pattern behind it, which is not the expert's move, it is the beginner's
move that looks like it. The discipline is what builds the intuition that eventually
replaces it, and there is no shortcut that does not pass through it.

The other reason is that the reflex fails on the unfamiliar fault, and then the expert falls
back to exactly this: divide the stack, test the middle, eliminate half. The method is not
the scaffolding you throw away, it is what you return to when recognition runs out, which on
a hard enough fault is everyone.

</details>

## Prove it

The lab block is from
[`sockets.sh`](https://github.com/rlwilliamson-dev/azure-resume/blob/main/blog/scripts/topologies/sockets.sh),
and it is the divide-and-conquer approach in three commands: a symptom, a discriminating
test that halves the stack, and a confirmation. The tools in it, `ping` and a web request,
are topics 62 and 63; this topic is about the order to run them in and why the middle one is
worth ten of the others.

**The CompTIA objectives, 5.1.** The three approaches are named under the step about
establishing a theory. Read them and note that they are three ways to search the same ordered
stack, not three different methods, which is why the choice between them is about where you
already suspect the fault, not about which is correct.

**RFC 1122.** The host requirements document, for the layer model the search runs over.
Reading which layer owns which job is what lets you predict what a test at that layer proves,
which is the whole basis of a discriminating test.

## What trips people up

### 1. Testing in the order candidates occur to you

That order is not sorted by likelihood or by speed, so it wastes tests. Sort by what a single
test can eliminate, and check the thing that halves the list first.

### 2. Gathering detail instead of eliminating candidates

More information about the symptom feels like progress and usually is not. Only a test whose
result rules causes out shrinks the search, and that is the one to reach for.

### 3. Running the ladder from the wrong end

Top-down for a total failure, or bottom-up for a single-application fault, climbs past
everything that was never the problem. Start from the end you already suspect, or from the
middle when you suspect neither.

### 4. Forgetting that a passed test eliminates a whole region

A successful ping does not just say the network works, it says every layer under it works too,
because it could not have completed otherwise. One pass can clear four candidates.

### 5. Skipping to the guess without the pattern behind it

The expert's fast guess is pattern matching built from running the ladder slowly. Guessing
before you have the store of patterns is the beginner's move that looks like the expert's, and
it misses.

### 6. Confusing a refused connection with a timed-out one

Refused means the host is up and nothing is on that port, an application-layer answer. Timed out
means something dropped the packet, a lower-layer answer. The two point at different halves of
the stack, and reading which one you got is itself a discriminating test.

## Work it through

The user who cannot reach the web application, worked by layer.

First, decide which approach fits before running anything, because that decision is nearly free
and it saves the afternoon. Is it one application while everything else works? That suggests high
in the stack, so top-down. Does the machine reach nothing at all? That suggests low, so bottom-up.
No strong prior? Divide and conquer, and test the middle.

Then run the one test that eliminates the most, not the one that is easiest or occurs to you first.
For a reachability fault with no strong prior, that test is almost always a ping, because a pass
clears the entire bottom of the stack and a fail clears the top, and either way half the candidates
are gone in one command.

Then read the result for everything it eliminates, not just the layer it targeted. A ping that
succeeds has proven the network, the switch, the cabling, and the addressing all at once. Cross all
of them off, and do not test any of them again, because the ping already answered for them.

Then repeat on the half that is left, and keep halving. The refused-versus-timed-out distinction is
often the next discriminating test, splitting an application problem from a filtering one. Fifteen
candidates become one in about four tests when each test eliminates half, and the whole skill is
choosing tests that do.

## Try it

**Run the lab and name what the ping eliminated.** In
[`sockets.sh`](https://github.com/rlwilliamson-dev/azure-resume/blob/main/blog/scripts/topologies/sockets.sh)
the ping succeeds and the web request to port 80 fails. Write down every candidate the successful
ping ruled out, and notice it is most of them.

**Take your last fault and mark each test as discriminating or gathering.** Which tests eliminated
candidates and which only added detail? The gathering ones are the time you can get back by choosing
discriminating tests instead.

**Practise the middle test.** For a reachability problem, the middle test is a ping, and its result
tells you which half of the stack to search next. Do it first, deliberately, until reaching for it is
automatic, which is the intuition this topic is trying to build.

## Check yourself

<details class="qa">
<summary>What are the three approaches to narrowing a fault by layer, and when does each fit?</summary>

Top-down, from the application down, fits when one application fails and everything else works, which
suggests the fault is high in the stack. Bottom-up, from the physical up, fits when nothing works at
all, which suggests it is low. Divide and conquer, testing the middle, fits when you have no strong
prior, which is most of the time.

They are three ways to search the same ordered stack, not three different methods. The choice is about
where you already suspect the fault, and when you suspect neither end, testing the middle eliminates half
whichever way it comes out.

</details>

<details class="qa">
<summary>What makes a test discriminating, and why does it matter more than gathering detail?</summary>

A discriminating test has a result that rules candidates in or out. A gathering test only produces more
information about the symptom without shrinking the list of possible causes.

It matters because only elimination makes progress toward the fault. You can gather detail for an hour
and have removed nothing; one discriminating test can remove half the candidates. Choosing tests by how
much they eliminate, rather than by what they reveal, is the whole efficiency of the method.

</details>

<details class="qa">
<summary>A ping to a server succeeds. What has that one test eliminated?</summary>

Everything at and below the network layer: the cabling, the switch, the host's addressing, and the
routing between the two machines. A ping completes only if all of those work, so its success proves them
all at once and the fault must be above the network layer, in transport or the application.

That is why the ping is such a good middle test. Its result is incompatible with the fault being in any of
four lower candidates, so a single pass crosses all of them off and halves the search.

</details>

<details class="qa">
<summary>Why should a beginner run the ladder deliberately when experts appear to skip it?</summary>

Because the expert's fast guess is pattern matching built from having run the ladder many times. Each fault
narrowed the slow way, with a discriminating test, becomes a recognised shape that can be matched quickly
next time. The intuition is made of that experience.

Skipping to the guess before building the store of patterns is guessing without the pattern behind it, which
misses. The discipline builds the intuition that eventually replaces it, and there is no route to the expert's
speed that does not pass through the method.

</details>

<details class="qa">
<summary>A web request is refused on one attempt and times out on another. Why is that distinction a discriminating test?</summary>

Because the two results point at different halves of the stack. A refused connection means the host is up and
reachable and nothing is listening on that port, which is an application-layer answer. A timeout means
something dropped the packet, which is a lower-layer answer, filtering or a broken path.

So reading which one you got eliminates candidates: refused rules out the network and points at the service;
timed out rules out the service being the whole story and points at a filter or a path. The distinction itself
narrows the fault, which is what makes it a test rather than just an observation.

</details>

## References

- [CompTIA Network+ N10-009 objectives](https://www.comptia.org/certifications/network) - CompTIA, objective 5.1, which names top-down, bottom-up, and divide-and-conquer under establishing a theory. Accessed 2026-08-19.
- [RFC 1122](https://www.rfc-editor.org/rfc/rfc1122) - IETF, the host requirements and the layer model the search runs over, which is what lets a test at one layer prove things about the layers below it. Free. Accessed 2026-08-19.

**Where the numbers came from.** The lab block is from
[`sockets.sh`](https://github.com/rlwilliamson-dev/azure-resume/blob/main/blog/scripts/topologies/sockets.sh)
through `netlab.sh`, on the kernel in its header. The scenario is built so the ping succeeds and the port-80
request fails, which is the divide-and-conquer case where one discriminating test halves the stack; the figure
is drawn from the same idea, with a ping at the network layer eliminating everything below it.

**If you also troubleshoot Linux systems.** The approach is identical and the tools are the ones this track has
used throughout: a ping for the middle test, a connection attempt to tell refused from timed out, and the
socket tools to confirm what is listening. The method is platform-independent because the layer model is, which
is why this is a methodology topic rather than a tools one.
