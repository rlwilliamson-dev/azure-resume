---
title: "Hello, world"
description: "First post on this blog. Setting expectations for what'll show up here."
publishDate: 2026-05-18
tags: ["meta"]
---

Most of the Azure and DevOps content online is tutorial-shaped: clean inputs,
happy paths, things working as documented. This blog is for the other kind —
the "the docs say X but the real behavior is Y" moments that only show up after
you've already wasted an afternoon on them.

I'll be writing here about Azure, DevOps, infrastructure as code, and
cybersecurity. Also, occasionally, the kind of rabbit holes that have nothing
to do with my job but are too interesting to ignore.

## What you'll find here

Roughly in order of likelihood:

- **Real Azure war stories** — issues I've actually hit, with the workarounds
  that actually work
- **AZ-400 study notes** as I work through the cert
- The **pfSense home-router build** handling a gigabit line with full IDS/IPS
  inspection — the one I keep meaning to document
- **LoRa radio + MeshCore**, because off-grid mesh networking is its own
  delightful rabbit hole and I can't stop thinking about it
- Whatever else seems worth writing down

## How this blog is built (if you care)

Open source, Astro static site, deployed to Azure Static Web Apps from the
same monorepo as [rlwilliamson.dev](/). Posts are plain markdown. Images run
through Astro's `<Image>` component for automatic resize and WebP conversion.
Syntax highlighting via Shiki with Tokyo Night.

```bash
# typical post workflow
$ cd blog/src/content/posts
$ touch my-new-post.md
$ npm run dev   # local preview
$ git commit && git push
# CI builds, copies dist to frontend/blog/, deploys to SWA
```

[RSS is here](/blog/rss.xml) if that's your thing.

This one's still marked draft. When there's something real to publish, it'll
show up. Shouldn't be long.