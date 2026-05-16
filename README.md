# Azure Cloud Resume

My implementation of [Forrest Brazeal's Cloud Resume Challenge](https://cloudresumechallenge.dev) on Microsoft Azure.

**Live site:** [rlwilliamson.dev](https://rlwilliamson.dev)

A static resume site backed by a real serverless visitor counter. The site itself is a hand-built HTML page with a terminal-themed hero, a typing animation, a click-to-zoom photo lightbox, expandable experience entries, light/dark theming, and a built-in print-to-PDF view. The counter is a Python Azure Function backed by Cosmos DB serverless, called from the frontend over an `/api` route that Azure Static Web Apps proxies into the same domain. Everything is defined as code and deploys automatically through GitHub Actions on every push to `main`, with a pytest gate that blocks deploys when the API tests fail.

---

## Architecture

```
                                                  rlwilliamson.dev
                                                         |
                                                         v
                          +------------------------------------------------------------+
                          |             Azure Static Web Apps (Free tier)              |
                          |                                                            |
                          |   /                          /api/counter                  |
                          |   |                              |                         |
                          |   v                              v                         |
                          |  static frontend           Python Azure Function           |
                          |  (HTML + CSS + JS)         (HTTP trigger, V2 model)        |
                          |  + me.jpg                  function_app.py + db.py         |
                          +------------------------------------------------------------+
                                                                  |
                                                                  v
                                                       +---------------------+
                                                       |   Azure Cosmos DB   |
                                                       |   serverless, SQL   |
                                                       |   AzureResume /     |
                                                       |   Counter container |
                                                       +---------------------+
```

| Layer | Tech |
|---|---|
| Frontend | Single-file HTML with inline CSS/JS, `counter.js`, `staticwebapp.config.json`, `me.jpg` |
| Hosting | Azure Static Web Apps (Free tier) |
| API | Python 3.11 Azure Function (V2 programming model) on Managed Functions |
| Database | Azure Cosmos DB for NoSQL (Serverless capacity mode) |
| Identity & security headers | `staticwebapp.config.json` (CSP, X-Frame-Options, Permissions-Policy) |
| Infrastructure as Code | Bicep (in [`/infra`](./infra)) |
| CI/CD | GitHub Actions (`.github/workflows/azure-static-web-apps-*.yml`) |
| Tests | pytest with mocked Cosmos client, gated via `needs: test` in CI |
| Custom domain | Namecheap DNS → Azure SWA, DigiCert-issued SSL |
| Cost | $0/month |

---

## Repo layout

```
azure-resume/
├── .github/
│   └── workflows/
│       └── azure-static-web-apps-*.yml      # CI/CD: tests, then deploy
├── frontend/
│   ├── index.html                            # the resume site
│   ├── 404.html                              # custom 404 page (terminal-themed)
│   ├── counter.js                            # client-side visitor counter
│   ├── staticwebapp.config.json              # routing + security headers + 404 override
│   ├── favicon.svg                           # SVG favicon (initials on gradient)
│   └── me.jpg                                # headshot
├── api/
│   ├── function_app.py                       # HTTP-triggered counter
│   ├── db.py                                 # Cosmos DB access layer
│   ├── host.json                             # Functions host config
│   ├── requirements.txt                      # runtime dependencies
│   ├── requirements-dev.txt                  # dev deps (pytest)
│   └── tests/
│       ├── conftest.py                       # shared fixtures
│       └── test_counter.py                   # unit tests for the counter
├── infra/
│   ├── main.bicep                            # Cosmos resources as code
│   └── main.bicepparam                       # parameters for prod
├── .gitignore
└── README.md
```

---

## How it works

### Visitor counter

The footer of every page contains a `<span id="visitor-count">` element. On load, `counter.js` makes a `POST` request to `/api/counter`. Azure Static Web Apps' built-in proxy routes that to the Function App's `counter` endpoint without CORS configuration. The Function increments a single document in Cosmos DB, returns the new count as JSON, and the JS animates the value into the span.

The Function uses Cosmos DB's serverless capacity mode, which means there's no provisioned RU/s and the cost is fractions of a cent per request. The `Counter` container is partitioned by `/id` and stores exactly one document. If that document is missing on a cold start, `db.py` self-heals by creating it on the fly.

### Frontend design

- **Boot animation** on first paint — Linux-style kernel log lines print rapidly, then the page fades in
- **Terminal hero** that types through `whoami`, `cat current-role.txt`, `ls -la skills/`, `history | grep migration`, `contact --short` in a loop with a 45-second hold between cycles
- **Photo lightbox** — clicking the avatar opens the full uncropped photo in a modal
- **Expandable experience entries** — each role shows a one-line summary that expands to full bullets on click
- **Print mode** — a "↓ PDF" button toggles browser print, with a dedicated print stylesheet that produces a clean 1-2 page traditional resume
- **Dynamic years** — anywhere the page mentions years at Deloitte (stat, summary, boot text) the number self-calculates from a single start date constant
- **Auto-updating copyright year** in the footer
- **Light/dark theme toggle** with default dark mode
- **Console easter egg** for anyone who opens DevTools
- **Custom 404 page** matching the terminal aesthetic — shows the requested path inside a fake shell session and offers a return-to-home button
- **Inline animated architecture diagram** in the project section showing live data flow from browser to Cosmos DB

### CI/CD

GitHub Actions workflow at `.github/workflows/azure-static-web-apps-*.yml` runs on every push to `main` and on every PR:

1. **`test` job** — Python 3.11, installs `requirements-dev.txt`, runs `pytest` against the API
2. **`build_and_deploy_job`** — `needs: test`; builds the static frontend and the Python Function, deploys both to Azure Static Web Apps (preview environment on PRs, production on `main`)

If the test job fails, deploy doesn't run. Period.

### Infrastructure as Code

The Cosmos DB account, database, and container are defined in [`infra/main.bicep`](./infra/main.bicep). Running `az deployment group create` against the template recreates the entire database side from scratch. The Static Web App itself is managed via the GitHub integration rather than Bicep (typical pattern for SWA + GitHub).

---

## Running locally

### Frontend

```bash
cd frontend
python3 -m http.server 8000
```

Open http://localhost:8000. Note: the visitor counter will hit the production API, so the count will increment for real.

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

- Azure Static Web Apps Free tier covers frontend, API hosting, and SSL
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
- **The `Install OIDC Client` step is non-obvious but mandatory.** Without it, `actions/github-script`'s `require('@actions/core')` throws `MODULE_NOT_FOUND` because the package isn't bundled with the action. The build job has this step too — easy to overlook when copy-pasting workflows.
- **Once OIDC is wired through the close job, preview cleanup is automatic and bulletproof.** Every PR you close auto-deletes its preview environment. The 10-env limit becomes a non-issue.

### GitHub / Git mechanics

- **SSH signing keys are separate from SSH auth keys on GitHub.** Same key can't be both; GitHub rejects the duplicate fingerprint. The fix is generating a dedicated signing key (`ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_signing`).
- **Local signature verification needs `gpg.ssh.allowedSignersFile` configured.** Without it, `git log --show-signature` shows an error and prints "No signature" even on commits that are correctly signed — purely a display issue, GitHub still verifies them.
- **Branch-protection rulesets have a "Require approval of the most recent reviewable push" setting that's a deadlock for solo developers.** Required-approvals = 0 isn't enough; that specific setting blocks you from merging your own PRs and even `--admin` doesn't bypass it. Uncheck it explicitly for solo work.
- **`gh pr merge` doesn't wait for checks to start.** If you run it immediately after `gh pr create`, the protection rule rejects the merge because no checks have reported yet. Always `gh pr checks --watch` first.

### Frontend craft

- **Inline CSS isn't a sin for a single-page personal site.** One file, one network request, no FOUC, no build step. The "every page should have one external stylesheet" rule is for big sites.
- **CSS `overflow: hidden` on an avatar container will clip a status-dot pseudo-element if the dot extends past the parent's bounding box.** Better to apply `border-radius: 50%` directly to the image and leave the container un-clipped.
- **`object-position` lets you fine-tune how a `cover`-fit image is cropped without re-cropping the source file.** Setting `object-position: center 15%` shifts the visible window upward and leaves headroom above a portrait subject.
- **A built-in print stylesheet beats a separate "download PDF" service.** `window.print()` triggers the browser's native print dialog, which includes "Save as PDF" on every platform. Combine with a `@media print` block that hides decorative elements and tightens spacing, and you get a clean traditional resume PDF for free.

### SEO, social previews, and accessibility

- **Open Graph tags are what make LinkedIn (and Slack, Discord, iMessage, WhatsApp) generate a pretty preview card when your URL is shared.** Without `og:title`, `og:description`, and especially `og:image`, the link appears as bare text. Skipping `twitter:` tags is fine if you don't use Twitter — every modern messenger consumes the Open Graph standard.
- **LinkedIn's Post Inspector caches scrape results.** After deploying new OG tags, you sometimes have to use the "Refresh / Re-fetch" option in the Inspector to see the update. Initial inspections may show your previous (or empty) preview state.
- **`Person` schema isn't a "rich result" type in Google's Rich Results Test.** The test reports "no items detected" / "page not eligible," which looks like a failure but is the expected output. Person markup feeds Google's Knowledge Graph and AI-mode citations instead — for validation use https://validator.schema.org or Google's Structured Data Testing Tool rather than the Rich Results Test.
- **`prefers-reduced-motion` deserves both a CSS rule AND a JS check.** The CSS handles transitions and `@keyframes`-driven animations. The JS check (`window.matchMedia('(prefers-reduced-motion: reduce)').matches`) handles anything driven by `setTimeout` / `requestAnimationFrame` — like a typing animation or a boot sequence — that CSS can't reach. Both are needed for full accessibility compliance.
- **A custom favicon as a single SVG file works on every modern browser.** No need to generate the historical zoo of `.ico`, `apple-touch-icon.png`, `android-chrome-192.png`, etc. Reference it with `<link rel="icon" type="image/svg+xml" href="favicon.svg">` and fall back to a JPEG for iOS via `<link rel="apple-touch-icon" href="me.jpg">`.
- **Static Web Apps' default 404 behavior returns a 200 status with `/index.html`**, which is wrong for non-SPA sites (search engines and crawlers see it as a duplicate of the homepage). Override it in `staticwebapp.config.json` with `responseOverrides: { "404": { "rewrite": "/404.html", "statusCode": 404 } }` so unknown URLs serve a real 404 page with the correct status code.

### Operational surprises

- **A squash-merge doesn't always trigger a `push` event workflow run.** Rare but real — sometimes GitHub's webhook delivery for the resulting push event drops, and your production deploy silently doesn't happen. Symptom: `gh run list --event=push --branch=main` doesn't show a recent entry matching your last merge, and the live site doesn't reflect the new code. Fix: push an empty commit via another PR (`git commit --allow-empty -m "chore: retrigger deploy"`) to force a fresh push event.
- **Azure Front Door (the CDN in front of Static Web Apps) caches HTML for several minutes.** After a deploy, `curl` against your URL may return the old HTML even though the deploy succeeded. Use a cache-busting query string — `curl "https://yoursite.dev/?nocache=$(date +%s)"` — to bypass the CDN and confirm the deploy actually shipped.

---

## Built with

`Azure`, `Bicep`, `Python`, `Azure Functions`, `Cosmos DB`, `Azure Static Web Apps`, `GitHub Actions`, `pytest`, `Namecheap DNS`, `JetBrains Mono`, and a lot of `gh pr checks --watch`.

---

## About me

[**Ryan Williamson**](https://linkedin.com/in/rlwilliamson) — Lead DevOps Engineer at Deloitte Technology US.
Currently on the iCMS Tax DevOps team building the Azure CI/CD, IaC, and DevSecOps practices behind Deloitte's tax software portfolio. Eight-plus years at the firm, including a multi-year data center migration across Azure, AWS, and GCP.

Open to senior DevOps and platform engineering opportunities, full-time and contract.
**Contact:** rlwilliamson@digital-ghost.net

---

## License

[MIT](./LICENSE)
