---
title: "Short, specific, under 120 characters"
description: "One sentence on what this topic covers and who it is for. Under 300 characters. Shows up on the track index and in search results."
track: "bicep"
level: "working"
order: 10
objectives:
  - "Start each one with a verb: explain, write, choose, debug"
  - "Two to four of these. If you cannot name them, the topic is not scoped yet"
prerequisites: []
tags: ["azure", "iac"]
updated: 2026-08-07
draft: true
---

Open with the problem, not the definition. One or two paragraphs on what goes
wrong without this knowledge, written for someone who has already hit the wall.

## The problem this solves

What breaks, and why the obvious approach does not work.

## Minimum working example

The smallest thing that runs. Not a toy, not a full production module.

```bicep
// keep this short enough to read in one screen
```

## How it actually behaves

The real semantics, with code. This is the section people came for.

## Three things that trip people up

### 1. First one

What people expect, what actually happens, and how to tell which you are hitting.

### 2. Second one

### 3. Third one

## Exercise

Something concrete and checkable, small enough to finish in fifteen minutes.

## References

- [Page title](https://learn.microsoft.com/...)

<!--
Filename: NN-slug.md, for example 01-what-bicep-solves.md.
The NN- prefix keeps files sorted on disk and is stripped from the URL, so this
file would publish at /learn/<track>/slug. The `order` field, not the prefix, is
what actually controls ordering.

This file starts with an underscore, so the collection glob skips it and it
never builds. Copy it, do not edit it in place.

Images: put them in src/content/learn/<track>/images/ and reference them
relatively, for example ![alt text](./images/thing.png). Downscale before
committing: 1600px wide maximum, 1200px is plenty for a screenshot.
-->
