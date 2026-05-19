---
title: "Hello, world"
description: "First post on this blog. Setting expectations for what'll show up here."
publishDate: 2026-05-18
tags: ["meta"]
draft: true
---

This is the first post on this blog. I'll be writing here about Azure, DevOps,
infrastructure as code, cybersecurity, and the occasional home-lab or
radio-frequency rabbit hole.

## What you'll find here

Things I'm planning to write about, roughly in order of likelihood:

- Walkthroughs of real Azure issues I've actually hit — the kind of "the docs
  say X but the real behavior is Y" stories that don't show up in tutorials
- Notes from studying for **AZ-400** as I go
- The **pfSense home-router build** that handles a gigabit line with full
  IDS/IPS inspection
- Adventures with **LoRa radio + MeshCore**, because off-grid mesh networking
  is its own delightful rabbit hole
- Whatever else seems worth writing down

## The blog itself

This blog is open source. It's an Astro static site, deployed to Azure Static
Web Apps from the same monorepo as the rest of [rlwilliamson.dev](/). Posts are
plain markdown. Images go through Astro's optimized `<Image>` component for
automatic resize and WebP conversion. Code blocks use Shiki for syntax
highlighting with the Tokyo Night theme to match the rest of the site.

```bash
# typical post workflow
$ cd blog/src/content/posts
$ touch my-new-post.md
# write the post
$ npm run dev   # local preview
$ git commit && git push
# CI builds the blog, copies dist to frontend/blog/, deploys to SWA
```

You can [subscribe via RSS](/blog/rss.xml) or just check back when you remember.

This post is marked as a draft — once I have something real to publish, this
will get replaced. Until then, hi.
