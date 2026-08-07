# Local development

Running the resume, the blog, and the API on your own machine.

Requirements: Python 3.11 (matching the deployed Function runtime), Node 24,
and the Azure Functions Core Tools if you want to run the API locally.

---

### Frontend (resume)

```bash
cd frontend
python3 -m http.server 8000
```

Open http://localhost:8000. The visitor counter will hit the production API, so the count will increment for real.

### Blog and learn

One Astro project serves both sections.

```bash
cd blog
npm install
npm run dev
```

Open http://localhost:4321/blog or http://localhost:4321/learn. Drafts (`draft: true` in frontmatter) show up in dev mode only; they're excluded from production builds.

Search on `/learn` is powered by Pagefind, which indexes the built output. It does not work in `npm run dev` and will say so. To exercise it:

```bash
cd blog
npm run build
npm run preview
```

Authoring guide for the learn section: [CONTRIBUTING-learn.md](../CONTRIBUTING-learn.md).

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

API tests:

```bash
cd api
source .venv/bin/activate
pytest -v
```

All tests mock the Cosmos client, so no live connection is required.

Route tests for the built site. These assert against `blog/dist/`, so build first (this is what CI does before deploying):

```bash
cd blog
npm run build && npm test
```

---
