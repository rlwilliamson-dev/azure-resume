# Azure Cloud Resume

My implementation of [Forrest Brazeal's Cloud Resume Challenge](https://cloudresumechallenge.dev) on Microsoft Azure, taken several steps past the base spec.

**Live site:** [rlwilliamson.dev](https://rlwilliamson.dev)
**Blog:** [rlwilliamson.dev/blog](https://rlwilliamson.dev/blog)
**Security headers:** [A on securityheaders.com](https://securityheaders.com/?q=https%3A%2F%2Frlwilliamson.dev%2F&followRedirects=on)

A static resume site backed by a real serverless visitor counter, an Astro-powered blog at `/blog`, a handful of custom subpages (`/now`, `/uses`, `/whoami`), and a custom 404 page that runs a small canvas-based terminal runner game. The resume itself is hand-built single-file HTML with a terminal-themed hero, a typing animation, a click-to-zoom photo lightbox, expandable experience entries, light/dark theming, and a built-in print-to-PDF view. The blog is Astro 6 with the Content Layer API, Tokyo Night syntax highlighting, tags, RSS, and reading times. The counter is a Python Azure Function backed by Cosmos DB serverless, called from the frontend over an `/api` route that Azure Static Web Apps proxies into the same domain. Everything is defined as code and deploys automatically through GitHub Actions on every push to `main`, with a pytest gate that blocks deploys when the API tests fail.

---

## How this differs from the standard Cloud Resume Challenge

The [original challenge](https://cloudresumechallenge.dev/docs/the-challenge/azure/) is 16 steps: cert, HTML, CSS, static site, HTTPS, DNS, JavaScript, database, API, Python, tests, IaC, source control, CI/CD (backend + frontend), and a blog post. This repo does all of that and then keeps going:

| Beyond the base challenge | Why |
|---|---|
| **Astro 6 blog at `/blog`** with Content Layer API, tags, RSS, reading times, syntax highlighting | The challenge ends with "write one blog post about it." I wanted a real ongoing blog with proper tooling instead of a single Medium post |
| **Custom subpages**: `/now`, `/uses`, `/whoami` | A resume is one snapshot of one person; these pages add depth and personality |
| **Terminal-themed design** with boot sequence and typing hero | Wanted the site to feel like *me* (DevOps, terminals, dark mode), not a corporate template |
| **Custom 404 page with a playable terminal runner game** | The 404 doesn't have to be a dead end. Canvas-based, vanilla JS, persistent high score, mobile-friendly |
| **A grade security headers** (COOP, COEP, CORP, CSP, HSTS, X-Frame-Options) | The base challenge doesn't touch security headers; I wanted [an A on securityheaders.com](https://securityheaders.com/?q=https%3A%2F%2Frlwilliamson.dev%2F&followRedirects=on) |
| **`security.txt` (RFC 9116)** | Standard practice for any publicly-facing site to declare a security contact |
| **`robots.txt` + `sitemap.xml`** | Proper SEO hygiene; `robots.txt` points at both the static sitemap and the Astro-generated blog sitemap |
| **Open Graph + Schema.org Person markup** | Makes shared links render as preview cards on LinkedIn / Slack / iMessage; feeds Google's Knowledge Graph |
| **Inline animated architecture diagram** showing live data flow browser to Cosmos | Helps recruiters who skim by giving them something visual to grasp |
| **Boot animation and a few easter eggs** | Discoverable surprises for engineers who poke at the site. I won't spoil what's in there |
| **`prefers-reduced-motion` support** (CSS + JS) | The boot sequence and typing animation are JS-driven, so CSS-only motion reduction isn't enough |
| **Photo lightbox, expandable roles, theme toggle, print-to-PDF** | Small UX wins that don't ship in a vanilla HTML resume |
| **OIDC auth on the SWA close-PR job** | Default SWA workflow leaves PR preview environments stranded if the close job's static token rotates; OIDC makes cleanup bulletproof |
| **Pytest gating in CI** with `needs: test` | The standard challenge mentions tests but doesn't enforce them as a deploy gate |
| **SSH commit signing** with a dedicated signing key | Verified-commit badges on every push, separate from the SSH auth key |

If you're working through the challenge yourself, the base implementation is in here too. Feel free to fork and rip out the additions you don't want.

---

## Architecture

```
                                                rlwilliamson.dev
                                                       |
                          +----------------------------+----------------------------+
                          |                                                         |
                          v                                                         v
                  +-----------------+                                       +---------------+
                  |  static resume  |                                       |     /blog     |
                  |  (HTML/CSS/JS)  |                                       | (Astro 6      |
                  |  /now /uses     |                                       |  static site) |
                  |  /whoami        |                                       +---------------+
                  |  /404 (runner)  |
                  +-----------------+
                          |
                          v
                  +-----------------+
                  |  /api/counter   |
                  | Python Function |
                  |   (V2 model)    |
                  +-----------------+
                          |
                          v
                  +---------------------+
                  |   Azure Cosmos DB   |
                  |   serverless, SQL   |
                  |   AzureResume /     |
                  |   Counter container |
                  +---------------------+

All served by a single Azure Static Web App (Free tier) at rlwilliamson.dev,
with the blog built into ./frontend/blog/ at CI time and shipped as part of
the same deploy.
```

| Layer | Tech |
|---|---|
| Static resume | Single-file HTML with inline CSS/JS, `counter.js`, `ryan.js`, `staticwebapp.config.json`, `me.jpg`, SVG favicon |
| Blog | Astro 6.3 with Content Layer API, Tokyo Night Shiki, `@astrojs/rss`, `@astrojs/sitemap` |
| Custom pages | `/now`, `/uses`, `/whoami`, custom `/404` runner |
| Hosting | Azure Static Web Apps (Free tier) |
| API | Python 3.13 Azure Function (V2 programming model) on Managed Functions |
| Database | Azure Cosmos DB for NoSQL (Serverless capacity mode) |
| Security headers | `staticwebapp.config.json` (COOP, COEP, CORP, CSP, HSTS, X-Frame-Options, Permissions-Policy) |
| Infrastructure as Code | Bicep (in [`/infra`](./infra)) |
| CI/CD | GitHub Actions: pytest gate, Node 22 + Astro build, SWA deploy with OIDC |
| Tests | pytest with mocked Cosmos client, gated via `needs: test` |
| Custom domain | Namecheap DNS to Azure SWA, DigiCert-issued SSL, CAA record |
| Commit signing | SSH signing with a dedicated `id_ed25519_signing` key |
| Cost | $0/month plus $12/year for the domain |

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
│   ├── staticwebapp.config.json              # routing, security headers, 404 override
│   ├── favicon.svg                           # single-file SVG favicon
│   ├── me.jpg                                # headshot
│   ├── logos/                                # company logos (theme-aware SVGs)
│   ├── robots.txt                            # crawler directives + sitemap pointer
│   ├── sitemap.xml                           # static pages sitemap
│   └── .well-known/
│       └── security.txt                      # RFC 9116 security contact
├── blog/
│   ├── astro.config.mjs                      # base: '/blog', sitemap integration
│   ├── package.json                          # Astro 6.3 + integrations
│   ├── src/
│   │   ├── content.config.ts                 # content collection schema (Zod)
│   │   ├── content/posts/*.md                # blog posts
│   │   ├── layouts/                          # BaseLayout, PostLayout
│   │   ├── components/                       # Header, Footer, PostCard
│   │   ├── pages/                            # index, [slug], tags/, rss.xml.js
│   │   ├── styles/global.css                 # shared variables matching main site
│   │   └── utils/                            # readingTime, dates
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

### Blog

The blog lives in [`/blog`](./blog) and is built at CI time:

1. CI installs Node 22 and runs `npm ci` in `blog/`
2. `npm run build` produces a static site at `blog/dist/`
3. The CI step copies `blog/dist/*` into `frontend/blog/`
4. The existing SWA deploy action ships `frontend/` (which now includes the built blog)

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

1. **`test` job**. Python 3.13, installs `requirements-dev.txt`, runs `pytest` against the API
2. **`build_and_deploy_job`** has `needs: test`; checks out, sets up Node 22, builds the Astro blog into `frontend/blog/`, then deploys the whole `frontend/` directory plus the Python Function to Azure Static Web Apps (preview environment on PRs, production on `main`)
3. **`close_pull_request_job`** runs when a PR closes; uses OIDC auth (same as the build job) to delete the preview environment

If the test job fails, deploy doesn't run. Period.

### Infrastructure as Code

The Cosmos DB account, database, and container are defined in [`infra/main.bicep`](./infra/main.bicep). Running `az deployment group create` against the template recreates the entire database side from scratch. The Static Web App itself is managed via the GitHub integration rather than Bicep (typical pattern for SWA + GitHub).

---

## Running locally

### Frontend (resume)

```bash
cd frontend
python3 -m http.server 8000
```

Open http://localhost:8000. The visitor counter will hit the production API, so the count will increment for real.

### Blog

```bash
cd blog
npm install
npm run dev
```

Open http://localhost:4321/blog. Draft posts (`draft: true` in frontmatter) show up in dev mode only; they're excluded from production builds.

### API

```bash
cd api
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements-dev.txt
```

Copy your Cosmos connection string into `api/local.settings.json` (gitignored):

```json
{
  "IsEncrypted": false,
  "Values": {
    "AzureWebJobsStorage": "",
    "FUNCTIONS_WORKER_RUNTIME": "python",
    "CosmosDbConnectionString": "AccountEndpoint=https://...;AccountKey=..."
  }
}
```

Then:

```bash
func start
curl http://localhost:7071/api/counter
```

### Tests

```bash
cd api
source .venv/bin/activate
pytest -v
```

All tests mock the Cosmos client, so no live connection is required.

---

## Cost

Runs at **$0/month** within Azure's free tiers:

- Azure Static Web Apps Free tier covers static hosting, API hosting, and SSL
- Cosmos DB serverless costs fractions of a cent per request at this volume
- GitHub Actions is free for public repos
- Custom domain ($12/year from Namecheap) is the only recurring cost

---

## What I learned

This project ran a lot deeper than "make a website with a hit counter." A few of the chapters worth remembering:

### Infrastructure surprises

- **Cosmos DB's serverless vs. provisioned billing modes are massively different at low scale.** Picking serverless was the difference between "pennies a month" and "~$24/month minimum."
- **Azure's `EnableCanary` subscription feature** silently filtered every region dropdown in the portal to two EUAP regions where Cosmos isn't even supported. Unregistering the feature flag fixed it.
- **Static Web Apps' `/api` proxy is the cleanest way to wire a Function to a frontend.** No CORS, no separate hostname, no cookie domain weirdness.
- **DigiCert CAA records matter.** Without `0 issue "digicert.com"` in your DNS, Azure can't issue SSL for a custom domain and validation hangs forever with no useful error.

### The Static Web Apps `close_pull_request_job` saga

This one ate a full debugging session and is worth its own subsection.

- **The default SWA workflow has two jobs (`build_and_deploy_job` and `close_pull_request_job`) that authenticate to Azure differently.** Build uses both a static deployment token AND an OIDC `github_id_token`. Close uses only the static token. When the static token is rotated or invalidated, build keeps working via OIDC while close silently fails.
- **A broken close job means preview environments never get cleaned up.** They accumulate on every PR until you hit the 10-environment limit on Free tier, at which point new PR builds start failing too.
- **`skip_deploy_on_missing_secrets: true` silences the close job's red X but doesn't fix the underlying problem.** Cleanup still doesn't run. Anti-pattern: hiding the symptom while the disease progresses.
- **The fix is to add OIDC auth to the close job, mirroring the build job exactly.** This requires three parts: a `permissions: id-token: write` block on the job, an `Install OIDC Client from Core Package` step (`npm install @actions/core@1.6.0 @actions/http-client`), and a `Get Id Token` step using `actions/github-script@v6` whose result is passed to the deploy action as `github_id_token`.
- **The `Install OIDC Client` step is non-obvious but mandatory.** Without it, `actions/github-script`'s `require('@actions/core')` throws `MODULE_NOT_FOUND` because the package isn't bundled with the action. The build job has this step too, which is easy to overlook when copy-pasting workflows.
- **Once OIDC is wired through the close job, preview cleanup is automatic and bulletproof.** Every PR you close auto-deletes its preview environment. The 10-env limit becomes a non-issue.

### Adding a blog to an existing SWA project

- **The trick is to build the blog in CI and copy `dist/` into the SWA `app_location`.** No need for a separate SWA, a separate domain, or any SWA config changes. Two extra steps in the workflow (Setup Node + Build Astro blog) and the existing deploy action ships the combined output.
- **Astro 6 dropped legacy content collections entirely.** The migration from Astro 5 isn't a version bump. You have to convert `type: 'content'` collections to the Content Layer API with a `glob()` loader, switch `post.slug` to `post.id`, and replace `await post.render()` with `await render(post)` imported from `astro:content`. Required reading: [the v6 upgrade guide](https://docs.astro.build/en/guides/upgrade-to/v6/).
- **`trailingSlash: 'never'` in dev mode shows a confirmation page whenever you visit a slashed URL.** It's helpful behavior in theory ("we caught a broken internal link") but constantly nags you in practice. `trailingSlash: 'ignore'` (the default) accepts both forms and is what you want for a SWA deployment that serves both transparently.
- **Astro 6 requires Node 22+.** Update the workflow's `setup-node` step accordingly; Node 20 will fail with cryptic ESM errors.

### GitHub / Git mechanics

- **SSH signing keys are separate from SSH auth keys on GitHub.** Same key can't be both; GitHub rejects the duplicate fingerprint. The fix is generating a dedicated signing key (`ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_signing`).
- **Local signature verification needs `gpg.ssh.allowedSignersFile` configured.** Without it, `git log --show-signature` shows an error and prints "No signature" even on commits that are correctly signed. Purely a display issue, GitHub still verifies them.
- **Branch-protection rulesets have a "Require approval of the most recent reviewable push" setting that's a deadlock for solo developers.** Required-approvals = 0 isn't enough; that specific setting blocks you from merging your own PRs and even `--admin` doesn't bypass it. Uncheck it explicitly for solo work.
- **`gh pr merge` doesn't wait for checks to start.** If you run it immediately after `gh pr create`, the protection rule rejects the merge because no checks have reported yet. Always `gh pr checks --watch` first.
- **zsh treats square brackets in paths as glob patterns.** Astro's dynamic route filenames (`[slug].astro`, `[tag].astro`) trigger "no matches found" errors on `cp`, `grep`, and `git` commands unless you quote the destination paths or `setopt nonomatch` in your `.zshrc`.

### Frontend craft

- **Inline CSS isn't a sin for a single-page personal site.** One file, one network request, no FOUC, no build step. The "every page should have one external stylesheet" rule is for big sites.
- **CSS `overflow: hidden` on an avatar container will clip a status-dot pseudo-element if the dot extends past the parent's bounding box.** Better to apply `border-radius: 50%` directly to the image and leave the container un-clipped.
- **`object-position` lets you fine-tune how a `cover`-fit image is cropped without re-cropping the source file.** Setting `object-position: center 15%` shifts the visible window upward and leaves headroom above a portrait subject.
- **A built-in print stylesheet beats a separate "download PDF" service.** `window.print()` triggers the browser's native print dialog, which includes "Save as PDF" on every platform. Combine with a `@media print` block that hides decorative elements and tightens spacing, and you get a clean traditional resume PDF for free.
- **A canvas runner game is a surprisingly good 404.** The 404 is one of the few pages where users land already mildly frustrated. Giving them something to do for thirty seconds, instead of a dead end, costs ~500 lines of vanilla JS and zero dependencies. Keep the framing copy above the canvas so they don't lose the "what happened" context.

### SEO, social previews, and accessibility

- **Open Graph tags are what make LinkedIn (and Slack, Discord, iMessage, WhatsApp) generate a pretty preview card when your URL is shared.** Without `og:title`, `og:description`, and especially `og:image`, the link appears as bare text. Skipping `twitter:` tags is fine if you don't use Twitter; every modern messenger consumes the Open Graph standard.
- **LinkedIn's Post Inspector caches scrape results.** After deploying new OG tags, you sometimes have to use the "Refresh / Re-fetch" option in the Inspector to see the update. Initial inspections may show your previous (or empty) preview state.
- **`Person` schema isn't a "rich result" type in Google's Rich Results Test.** The test reports "no items detected" / "page not eligible," which looks like a failure but is the expected output. Person markup feeds Google's Knowledge Graph and AI-mode citations instead. For validation use https://validator.schema.org or Google's Structured Data Testing Tool rather than the Rich Results Test.
- **`prefers-reduced-motion` deserves both a CSS rule AND a JS check.** The CSS handles transitions and `@keyframes`-driven animations. The JS check (`window.matchMedia('(prefers-reduced-motion: reduce)').matches`) handles anything driven by `setTimeout` or `requestAnimationFrame` (like a typing animation or a boot sequence) that CSS can't reach. Both are needed for full accessibility compliance.
- **A custom favicon as a single SVG file works on every modern browser.** No need to generate the historical zoo of `.ico`, `apple-touch-icon.png`, `android-chrome-192.png`, etc. Reference it with `<link rel="icon" type="image/svg+xml" href="favicon.svg">` and fall back to a JPEG for iOS via `<link rel="apple-touch-icon" href="me.jpg">`.
- **Static Web Apps' default 404 behavior returns a 200 status with `/index.html`**, which is wrong for non-SPA sites (search engines and crawlers see it as a duplicate of the homepage). Override it in `staticwebapp.config.json` with `responseOverrides: { "404": { "rewrite": "/404.html", "statusCode": 404 } }` so unknown URLs serve a real 404 page with the correct status code.
- **Cross-origin isolation headers (COOP, COEP, CORP) are required for an A grade on securityheaders.com.** They also enable `SharedArrayBuffer` and high-resolution timers if you ever need them. The COEP gotcha: it blocks external resources that don't send `Cross-Origin-Resource-Policy: cross-origin`, so you have to add `crossorigin="anonymous"` to every external `<img>` and `<script>` tag.

### Operational surprises

- **A squash-merge doesn't always trigger a `push` event workflow run.** Rare but real; sometimes GitHub's webhook delivery for the resulting push event drops, and your production deploy silently doesn't happen. Symptom: `gh run list --event=push --branch=main` doesn't show a recent entry matching your last merge, and the live site doesn't reflect the new code. Fix: push an empty commit via another PR (`git commit --allow-empty -m "chore: retrigger deploy"`) to force a fresh push event.
- **Azure Front Door (the CDN in front of Static Web Apps) caches HTML for several minutes.** After a deploy, `curl` against your URL may return the old HTML even though the deploy succeeded. Use a cache-busting query string like `curl "https://yoursite.dev/?nocache=$(date +%s)"` to bypass the CDN and confirm the deploy actually shipped.

---

## Built with

`Azure`, `Bicep`, `Python`, `Azure Functions`, `Cosmos DB`, `Azure Static Web Apps`, `GitHub Actions`, `Astro 6`, `Shiki`, `Zod`, `pytest`, `Namecheap DNS`, `JetBrains Mono`, and a lot of `gh pr checks --watch`.

---

## About me

[**Ryan Williamson**](https://linkedin.com/in/rlwilliamson), Lead DevOps Engineer at Deloitte Technology US with 8+ years building Azure platforms and the security controls that govern them: identity and RBAC, policy-as-code with Azure Policy, Key Vault-backed secrets, DevSecOps pipelines, and compliance-driven delivery in regulated environments. Multi-cloud across Azure, AWS, and GCP, including a multi-year data center migration.

Open to technical security, risk, and assessment roles alongside senior DevOps and platform engineering work, full-time and contract.
**Contact:** ryan@rlwilliamson.dev

---

## License

[MIT](./LICENSE)
