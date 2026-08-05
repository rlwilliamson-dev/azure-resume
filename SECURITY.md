# Security policy

This repository backs a live site at [rlwilliamson.dev](https://rlwilliamson.dev). If you find something, I want to hear about it.

## Reporting

Email **ryan@rlwilliamson.dev**.

The machine-readable version of this policy lives at [`/.well-known/security.txt`](https://rlwilliamson.dev/.well-known/security.txt), per [RFC 9116](https://datatracker.ietf.org/doc/html/rfc9116).

- I respond within **48 hours**.
- I credit researchers in the [Hall of Fame](https://rlwilliamson.dev/hall-of-fame) unless you would rather stay anonymous.
- I do not pursue legal action against anyone acting in good faith under this policy.

There is no bug bounty. This is a personal site, so the only currency I have is credit and a genuine thank you.

## Scope

In scope:

- `rlwilliamson.dev` and its subpaths, including `/blog` and the `/api/counter` endpoint
- This repository: the Bicep templates, the GitHub Actions workflow, the Python Function, and the static frontend
- Anything in the deployed `staticwebapp.config.json`, including the security headers and routing rules

Out of scope:

- Findings against Azure Static Web Apps, Azure Functions, or Cosmos DB themselves. Report those to [Microsoft MSRC](https://msrc.microsoft.com/report).
- Denial of service, volumetric testing, or anything that degrades the site for other visitors. The visitor counter is a real Cosmos DB write; please do not hammer it.
- Social engineering, physical attacks, or anything targeting me rather than the system.
- Missing headers or best practices with no demonstrable impact. Tell me anyway if you like, but it is not a vulnerability.

## What I care about most

Secrets or tokens exposed in the repo or in build logs, anything that lets you write to Cosmos DB outside the counter's intended behaviour, a way to bypass the deploy gates in the GitHub Actions workflow, or a route that serves content it should not.

## A note on the easter eggs

There is a deliberate capture-the-flag trail hidden across the site, with flags meant to be found in places like `robots.txt`, `security.txt`, and the page source. **Those are intentional and are not vulnerabilities.** Finding them means the trail is working. If you are not sure whether something you found is part of the game or a real issue, email me and I will tell you.
