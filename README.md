# Azure Cloud Resume

My implementation of [Forrest Brazeal's Cloud Resume Challenge](https://cloudresumechallenge.dev) on Microsoft Azure, taken several steps past the base spec.

**Live site:** [rlwilliamson.dev](https://rlwilliamson.dev)
**Blog:** [rlwilliamson.dev/blog](https://rlwilliamson.dev/blog)
**Learn:** [rlwilliamson.dev/learn](https://rlwilliamson.dev/learn)
**Security headers:** [A on securityheaders.com](https://securityheaders.com/?q=https%3A%2F%2Frlwilliamson.dev%2F&followRedirects=on)

A static resume site backed by a real serverless visitor counter, an Astro-powered blog at `/blog`, a library of technical learning notes at `/learn`, a handful of custom subpages (`/now`, `/uses`, `/whoami`), and a custom 404 page that runs a small canvas-based terminal runner game. The resume itself is hand-built single-file HTML with a terminal-themed hero, a typing animation, a click-to-zoom photo lightbox, expandable experience entries, light/dark theming, and a built-in print-to-PDF view. The blog is Astro 7 with the Content Layer API, Tokyo Night syntax highlighting, tags, RSS, and reading times. `/learn` is a growing set of learning notes organized into tracks, with navigation, ordering, and prev/next links all derived from the content collection at build time, client-side full-text search via Pagefind, and a practice test engine with per-domain scoring. The counter is a Python Azure Function backed by Cosmos DB serverless, called from the frontend over an `/api` route that Azure Static Web Apps proxies into the same domain. Everything is defined as code and deploys automatically through GitHub Actions on every push to `main`, with a pytest gate that blocks deploys when the API tests fail.

---

---

## How this differs from the standard Cloud Resume Challenge

The [original challenge](https://cloudresumechallenge.dev/docs/the-challenge/azure/) is 16 steps: cert, HTML, CSS, static site, HTTPS, DNS, JavaScript, database, API, Python, tests, IaC, source control, CI/CD (backend + frontend), and a blog post. This repo does all of that and then keeps going:

| Beyond the base challenge | Why |
|---|---|
| **Astro 7 blog at `/blog`** with Content Layer API, tags, RSS, reading times, syntax highlighting | The challenge ends with "write one blog post about it." I wanted a real ongoing blog with proper tooling instead of a single Medium post |
| **Learning library at `/learn`** with tracks, Pagefind search, and a practice test engine | Adding a topic is one Markdown file. Navigation, ordering, and prev/next all derive from the content collection, so the section scales without hand-maintained indexes. See [CONTRIBUTING-learn.md](./CONTRIBUTING-learn.md) |
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
                  |  (HTML/CSS/JS)  |                                       | (Astro 7      |
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
| Blog | Astro 7.1 with Content Layer API, Tokyo Night Shiki, `@astrojs/rss`, `@astrojs/sitemap` |
| Learn | Same Astro project, second content collection; Pagefind for static search, sharp for AVIF variants |
| Custom pages | `/now`, `/uses`, `/whoami`, custom `/404` runner |
| Hosting | Azure Static Web Apps (Free tier) |
| API | Python 3.11 Azure Function (V2 programming model) on Managed Functions, pinned via `platform.apiRuntime` |
| Database | Azure Cosmos DB for NoSQL (Serverless capacity mode) |
| Security headers | `staticwebapp.config.json` (COOP, COEP, CORP, CSP, HSTS, X-Frame-Options, Permissions-Policy) |
| Infrastructure as Code | Bicep (in [`/infra`](./infra)) |
| CI/CD | GitHub Actions: pytest gate, Node 24 + Astro build, Pagefind index, route tests, SWA deploy with OIDC |
| Tests | pytest with mocked Cosmos client gated via `needs: test`, plus `node:test` route coverage against the built output |
| Custom domain | Namecheap DNS to Azure SWA, DigiCert-issued SSL, CAA record |
| Commit signing | SSH signing with a dedicated `id_ed25519_signing` key |
| Cost | $0/month plus $12/year for the domain |

---

---

## Documentation

| Document | What's in it |
|---|---|
| [Architecture](./docs/architecture.md) | How the visitor counter, 404 game, blog, CI/CD, and IaC actually work, plus the repo layout |
| [Engineering notes](./docs/engineering-notes.md) | The surprises: Cosmos billing modes, the SWA close-PR job saga, platform version ceilings, and the rest of what cost me an afternoon |
| [Local development](./docs/local-development.md) | Running the resume, blog, API, and tests on your own machine |
| [Authoring learn content](./CONTRIBUTING-learn.md) | Adding a topic or a track, every frontmatter field, image rules, quiz banks, previewing drafts |
| [Security policy](./SECURITY.md) | How to report something you find |

---

## Cost

Runs at **$0/month** within Azure's free tiers:

- Azure Static Web Apps Free tier covers static hosting, API hosting, and SSL
- Cosmos DB serverless costs fractions of a cent per request at this volume
- GitHub Actions is free for public repos
- Custom domain ($12/year from Namecheap) is the only recurring cost

---

---

## Built with

`Azure`, `Bicep`, `Python`, `Azure Functions`, `Cosmos DB`, `Azure Static Web Apps`, `GitHub Actions`, `Astro 7`, `Shiki`, `Zod`, `pytest`, `Namecheap DNS`, `JetBrains Mono`, and a lot of `gh pr checks --watch`.

---

---

## About me

[**Ryan Williamson**](https://linkedin.com/in/rlwilliamson), Lead DevOps Engineer at Deloitte Technology US with 8+ years building Azure platforms and the security controls that govern them: identity and RBAC, policy-as-code with Azure Policy, Key Vault-backed secrets, DevSecOps pipelines, and compliance-driven delivery in regulated environments. Multi-cloud across Azure, AWS, and GCP, including a multi-year data center migration.

Open to technical security, risk, and assessment roles alongside senior DevOps and platform engineering work, full-time and contract.
**Contact:** ryan@rlwilliamson.dev

---

---

## License

[MIT](./LICENSE)
