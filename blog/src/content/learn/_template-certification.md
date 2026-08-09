---
title: "Short and specific, under 120 characters"
description: "One sentence on what this covers and who it is for. Under 300 characters. Appears on the track index and in search results."
track: "linux-plus"
level: "working"
order: 10
objectives:
  - "Start each with a verb: explain, choose, predict, diagnose"
  - "Three or four. If you cannot write three, the topic is not scoped yet"
prerequisites: []
tags: ["linux", "linux-plus"]
updated: 2026-08-07
draft: true
examObjectives:
  - exam: "xk0-006"
    domain: "1.0"
    objective: "1.1"
sources:
  - title: "Exact page title"
    url: "https://man7.org/linux/man-pages/man1/example.1.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
symptoms:
  - symptom: "The error text a reader would paste into a search engine"
    anchor: "1-first-thing-that-trips-people-up"
---

> **Before you read.** One question the reader cannot answer yet. A symptom, a
> command output, or a scenario. Do not answer it here; the body earns it.

Open on the situation, not the definition. One or two paragraphs on what is
actually going on, written for somebody who already administers systems and has
hit this.

## What breaks without this

The consequences, concretely. Not "this is important" but what fails, how long
it takes to notice, and what the wrong first move costs.

## The mental model

Only when the concept is structural. Inline SVG, never a raster image, wrapped
so it themes correctly and reads to a screen reader:

<figure class="learn-figure">
<svg viewBox="0 0 720 300" role="img" aria-labelledby="d-title d-desc">
  <title id="d-title">What the diagram shows</title>
  <desc id="d-desc">A prose description conveying the same information, for anyone who cannot see it.</desc>
  <!-- Use stroke="currentColor" and fill="currentColor" with fill-opacity
       so the diagram follows the light and dark themes. Never hardcode a hex. -->
</svg>
<figcaption>One line on what to take from it.</figcaption>
</figure>

Delete this section if the topic is not structural. A diagram of a command list
is decoration.

## Minimum working example

The smallest thing that runs. Fully worked, because it is the anchor.

## How it actually behaves

The real semantics. Captured output, produced with `blog/scripts/capture.sh`:

```bash
# AlmaLinux 10.2, x86_64
$ command --here
real output, pasted, never retyped
```

A block with a `# Distro, arch` header was captured. A block without one was
sourced from documentation, and the prose around it says which distribution it
applies to. Never write output from memory.

Two or three times per topic, hide the output behind a prediction. Use it on the
blocks that carry the teaching, not on every one, or it becomes furniture. The
blank lines around the fence are required: without them the code block is not
parsed as Markdown.

**The reader must be able to answer it from what they have just read.** This is
the rule that is easy to get wrong. "What does this print?" is a bad prompt if
the answer depends on knowing a command they have never met. State the rule
first, then ask them to apply it. If the honest answer is "you would have to be
sitting at a terminal to know", the prompt is wrong, not the reader.

<details class="predict">
<summary>A specific question about what this prints, and why.</summary>

```bash
# AlmaLinux 10.2, x86_64
$ command --here
real output
```

</details>

Then explain why the answer is what it is. A reader who guessed wrong is now
paying attention; that is the whole point of hiding it.

## Across distributions

A table, not prose. Delete only if behavior genuinely does not diverge, which is
rarer than it looks.

| | RPM family | dpkg family |
| --- | --- | --- |
| Command | | |

## Prove it

The commands that show the change took effect, and what the output looks like
when it did not. Required. A topic that stops at "now restart the service" is
not finished.

## What trips people up

Three or four. Each with the real error text, what it means, and what produces
it. These are the searchable strings that bring people to the page.

### 1. First thing

### 2. Second thing

### 3. Third thing

## Work it through

A scenario reasoned out on the page. Required, and readable with nothing to run,
because most studying happens away from a keyboard. State the situation, ask the
reader to think, then walk the reasoning and name what each outcome rules out.

Somewhere in the body, ask one focused self-explanation question: not "explain
this in your own words" but a specific question about a specific causal step,
such as "why does `rpm -qf` follow the symlink when `dpkg -S` does not?".
Focused prompts beat open-ended ones, and this is one of the cheapest things on
the page that actually works.

## Try it

Optional and marked as such. A completion problem: most of a working
configuration with the discriminating step removed.

**Verification step.** How the reader knows they got it, without being told the
answer.

## Check yourself

Three to five retrieval questions, each hiding its answer behind a click. The
click is the mechanism, not a convenience: answering first and then checking is
retrieval practice, reading the answer immediately is not.

Answers are not one-liners. Say why, name the near-miss the reader probably
picked, and add the thing they did not ask about but will need.

<details class="qa">
<summary>A question that requires applying the topic rather than recalling a definition.</summary>

The answer, then why, then the tempting wrong answer and why it is wrong.

</details>

<details class="qa">
<summary>A question about a failure mode.</summary>

The answer, plus what the error would actually have said.

</details>

<details class="qa">
<summary>A question that forces a choice between two plausible commands.</summary>

The answer, plus the rule for telling them apart next time.

</details>

## References

- [Exact page title](https://man7.org/linux/man-pages/man1/example.1.html) - Publisher. Accessed 2026-08-07.

Every block above with a distribution and architecture header was captured by
running the command on an AlmaLinux 10.2 container. Blocks without one are
illustrative.

Name the real machine the reader would recognise - the distribution and version,
and whether it was a container or a virtual machine. Do not name files in this
repository; the reader has no reason to go looking at them.

<!--
Filename: NN-slug.md, matching `order` numbered in tens. The NN- prefix is
stripped from the URL.

Section numbers on the page come from a CSS counter, so never number a heading
by hand. Reordering sections renumbers them automatically.

Every topic claiming an exam objective must have at least one `sources` entry or
the build fails. Check the URLs resolve with `npm run check:links`.

This file starts with an underscore, so the collection glob skips it and it
never builds. Copy it, do not edit it in place.
-->
