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
│   ├── counter.js                            # client-side visitor counter
│   ├── staticwebapp.config.json              # routing + security headers
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

- **Cosmos DB's serverless vs. provisioned billing modes are massively different at low scale.** Picking serverless was the difference between "pennies a month" and "~$24/month minimum."
- **Azure's `EnableCanary` subscription feature** silently filtered every region dropdown in the portal to two EUAP regions where Cosmos isn't even supported. Unregistering the feature flag fixed it.
- **Static Web Apps' `/api` proxy is the cleanest way to wire a Function to a frontend.** No CORS, no separate hostname, no cookie domain weirdness.
- **DigiCert CAA records matter.** Without `0 issue "digicert.com"` in your DNS, Azure can't issue SSL for a custom domain and validation hangs forever with no useful error.
- **SSH signing keys are separate from SSH auth keys on GitHub.** Same key can't be both; GitHub rejects the duplicate. The fix is generating a dedicated signing key.
- **The `close_pull_request_job` in the SWA workflow uses a different auth path than the build/deploy job.** Silencing its red X with `skip_deploy_on_missing_secrets: true` quiets the error but doesn't actually clean up preview environments, which then accumulate and hit the per-account limit.
- **Inline CSS isn't a sin for a single-page personal site.** One file, one network request, no FOUC, no build step. The "every page should have one external stylesheet" rule is for big sites.

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
