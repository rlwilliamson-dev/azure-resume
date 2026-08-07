# Architecture

How each part of the site is built and why. For the high-level diagram and
tech table, see the [README](../README.md). For setup instructions, see
[local development](./local-development.md).

---

## How it works

### Visitor counter

The footer of every page contains a `<span id="visitor-count">` element. On load, `counter.js` makes a `POST` request to `/api/counter`. Azure Static Web Apps' built-in proxy routes that to the Function App's `counter` endpoint without CORS configuration. The Function increments a single document in Cosmos DB, returns the new count as JSON, and the JS animates the value into the span.

Cosmos DB's serverless capacity mode means there's no provisioned RU/s and the cost is fractions of a cent per request. The `Counter` container is partitioned by `/id` and stores exactly one document. If that document is missing on cold start, `db.py` self-heals by creating it on the fly.

### The 404 page

Instead of a static "not found" message, `/404` runs a small canvas-based terminal runner. The player is a green `>` prompt with a blinking cursor. Obstacles are 32 different glyphs across three categories:

- **HTTP errors and signals** (red): 500, 503, 502, 401, 403, 429, 504, OOM, panic, SIGSEGV, SIGKILL, EACCES, ENOENT
- **Curiosities and lore** (yellow): 404, 418, NaN, null, undef, void, 0xDEAD, 0xBEEF, 0xCAFE
- **Syntax and lint noise** (muted): `;;`, `};`, `};;`, `=>`, `??`, `?.`, TODO, FIXME, HACK, core

Uptime is the score and persists across visits in `localStorage`. Difficulty ramps with score: speed picks up, spawn gaps tighten, and past the early game the spawner queues tight clusters and re-jump bursts.

Controls are `space` / `↑` / `w` to jump, tap on mobile, and the game pauses when the tab is hidden. The whole thing is vanilla JavaScript on a 2D canvas, around 500 lines including styles, no dependencies. The existing 404 framing (the big "404" header and the "this route does not exist" line) stays above the game shell.

### Blog and learn

One Astro project in [`/blog`](../blog) builds both `/blog` and `/learn`. It is
named for what it originally was; it now serves two sections from one dependency
tree and one stylesheet. The project builds with `base: '/'`, and each section
lives in its own `src/pages` subdirectory. Section prefixes are constants in
`blog/src/config/site.ts` rather than `import.meta.env.BASE_URL`, since one base
cannot describe two sections.

It is built at CI time:

1. CI installs Node 24 and runs `npm ci` in `blog/`
2. `npm run build` runs `astro build` and then Pagefind, producing a static site plus a search index at `blog/dist/`
3. `npm test` asserts the route surface against `blog/dist/`, failing the job before deploy if a route regressed
4. The CI step copies `dist/blog`, `dist/learn`, `dist/_astro`, `dist/pagefind`, and the sitemaps into `frontend/`
5. The existing SWA deploy action ships `frontend/` (which now includes both built sections)

Authoring for the learn section is documented separately in
[CONTRIBUTING-learn.md](../CONTRIBUTING-learn.md). The short version: tracks are
directories, topics are Markdown files, and navigation, ordering, and prev/next
are all derived from the collection at build time.

Pagefind indexes only learn topic pages, using `data-pagefind-body` on the
content column. Its WebAssembly core needs `'wasm-unsafe-eval'` in `script-src`,
which is scoped to `/learn` and `/learn/*` in `staticwebapp.config.json` so the
rest of the site keeps the stricter policy.

Posts are plain markdown in `blog/src/content/posts/*.md` with type-safe frontmatter validated at build time via a Zod schema. The schema supports `title`, `description`, `publishDate`, `updatedDate`, `tags`, `heroImage`, `heroImageAlt`, `canonicalUrl`, and `draft`. Drafts are visible in `npm run dev` and excluded from production.

To add a post:

```bash
cd blog/src/content/posts
# create a new markdown file with the frontmatter
npm run dev       # preview locally at http://localhost:4321/blog
# when ready, set draft: false (or remove the line), commit, push
```

Existing tag pages auto-update, RSS feed regenerates, sitemap rebuilds.

### Frontend design (resume)

- **Boot animation** on first paint. Linux-style kernel log lines print rapidly, then the page fades in
- **Terminal hero** that types through `whoami`, `cat current-role.txt`, `ls -la skills/`, `history | grep migration`, `cat security.txt`, `contact --short` in a loop with a 45-second hold between cycles
- **Photo lightbox**. Clicking the avatar opens the full uncropped photo in a modal
- **Expandable experience entries**. Each role shows a one-line summary that expands to full bullets on click
- **Print mode**. A "↓ PDF" button toggles browser print, with a dedicated print stylesheet that produces a standalone 2-page traditional resume. `print-only` and `print-hide` classes curate what prints: the PDF opens on a professional summary instead of the site's conversational about copy, drops site-specific phrasing ("the website you're on right now!"), and trims lower-priority bullets, so it reads correctly for someone who has never seen the site
- **Dynamic years**. Anywhere the page mentions years at Deloitte (stat, summary, boot text) the number self-calculates from a single start date constant
- **Auto-updating copyright year** in the footer
- **Light/dark theme toggle** with default dark mode, persisted via `localStorage`
- **A few easter eggs** scattered around the site for engineers who poke at things. Try DevTools, try keyboard sequences, poke around the standard files at the root. I won't spoil them
- **Inline animated architecture diagram** in the project section showing live data flow from browser to Cosmos DB
- **Microsoft Learn cert badges**. Clickable, link to live verifiable credentials (not Credly; Microsoft moved off Credly in 2024)

### CI/CD

GitHub Actions workflow at `.github/workflows/azure-static-web-apps-*.yml` runs on every push to `main` and on every PR:

1. **`test` job**. Python 3.11 (matching the deployed runtime), installs `requirements-dev.txt`, runs `pytest` against the API
2. **`build_and_deploy_job`** has `needs: test`; checks out, sets up Node 24, builds the Astro blog into `frontend/blog/`, then deploys the whole `frontend/` directory plus the Python Function to Azure Static Web Apps (preview environment on PRs, production on `main`)
3. **`close_pull_request_job`** runs when a PR closes; uses OIDC auth (same as the build job) to delete the preview environment

If the test job fails, deploy doesn't run. Period.

### Infrastructure as Code

The Cosmos DB account, database, and container are defined in [`infra/main.bicep`](../infra/main.bicep). Running `az deployment group create` against the template recreates the entire database side from scratch. The Static Web App itself is managed via the GitHub integration rather than Bicep (typical pattern for SWA + GitHub).

---

---

## Repo layout

```
azure-resume/
├── .github/
│   └── workflows/
│       └── azure-static-web-apps-*.yml      # pytest, build blog, SWA deploy
├── frontend/
│   ├── index.html                            # the resume site
│   ├── 404.html                              # terminal runner game
│   ├── now.html                              # what I'm working on right now
│   ├── uses.html                             # hardware, software, services I use
│   ├── whoami.html                           # the longer-form bio
│   ├── counter.js                            # client-side visitor counter
│   ├── ryan.js                               # shared window.ryan console API
│   ├── staticwebapp.config.json              # routing, security headers, 404 override, API runtime pin
│   ├── favicon.svg                           # single-file SVG favicon
│   ├── me.jpg                                # headshot
│   ├── logos/                                # company logos (theme-aware SVGs)
│   ├── robots.txt                            # crawler directives + sitemap pointer
│   ├── sitemap.xml                           # static pages sitemap
│   └── .well-known/
│       └── security.txt                      # RFC 9116 security contact
├── blog/                                     # one Astro project, serves /blog and /learn
│   ├── astro.config.mjs                      # base: '/', sitemap + learn-images integrations
│   ├── package.json                          # Astro 7.1 + integrations, Pagefind
│   ├── integrations/learn-images.mjs         # post-build AVIF variants for learn images
│   ├── src/
│   │   ├── content.config.ts                 # content collection schemas (Zod)
│   │   ├── config/                           # site.ts (URL prefixes), tracks.ts (track metadata)
│   │   ├── content/posts/*.md                # blog posts
│   │   ├── content/learn/<track>/*.md        # learn topics, directory name is the track
│   │   ├── data/quizzes/<track>/*.json       # practice question banks
│   │   ├── lib/                              # learn.ts, quiz.ts (derivation and validation)
│   │   ├── layouts/                          # BaseLayout, PostLayout, LearnTopicLayout
│   │   ├── components/                       # Header, Footer, PostCard, learn/
│   │   ├── pages/blog/                       # index, [slug], tags/, rss.xml.js
│   │   ├── pages/learn/                      # index, [track]/, [track]/[slug], [track]/practice/[set]
│   │   ├── styles/global.css                 # shared variables matching main site
│   │   └── utils/                            # readingTime, dates
│   ├── test/routes.test.mjs                  # node:test route coverage against dist/
│   └── tsconfig.json
├── api/
│   ├── function_app.py                       # HTTP-triggered counter
│   ├── db.py                                 # Cosmos DB access layer (self-healing init)
│   ├── host.json
│   ├── requirements.txt
│   ├── requirements-dev.txt
│   └── tests/
│       ├── conftest.py
│       └── test_counter.py
├── infra/
│   ├── main.bicep                            # Cosmos resources as code
│   └── main.bicepparam
├── .gitignore
├── LICENSE
└── README.md
```

---
