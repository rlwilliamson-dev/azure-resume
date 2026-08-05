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
