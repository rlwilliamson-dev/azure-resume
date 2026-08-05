# Engineering notes

Things this project taught me that I did not expect going in. Kept because the
surprises are more useful than the happy path, and because most of them cost me
an afternoon each.

---

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
- **Astro 6 requires Node 22+.** Update the workflow's `setup-node` step accordingly; Node 20 will fail with cryptic ESM errors. Astro 7 raises the floor to Node 22.12+, so the workflow now runs Node 24 LTS.
- **Astro 7's headline breaking changes were a no-op here, and that was worth verifying rather than assuming.** The v7 notes look alarming (Rust compiler rejects unclosed tags, `compressHTML` defaults to `'jsx'` and strips whitespace between inline elements, the markdown pipeline moved off remark/rehype). None of it bit, because this blog registers no custom remark or rehype plugins. The way to know that is to diff the build, not read the changelog: capture the `dist/` file list and the rendered text of a post before upgrading, then compare after. The file set matched and the post text came out byte-identical.

### Version ceilings are set by the platform, not by PyPI

- **Azure Static Web Apps managed functions cap Python at 3.11.** The [configuration docs](https://learn.microsoft.com/en-us/azure/static-web-apps/configuration) list `python:3.9`, `3.10`, and `3.11` as the only supported `apiRuntime` values; there is no 3.12 or 3.13. "Upgrade everything to latest" has a hard ceiling here, and it is on the hosting platform rather than in `requirements.txt`.
- **That ceiling cascades into dependency choices.** `azure-functions` 2.x requires Python >= 3.13, which makes it unusable on SWA managed functions no matter how current it is. The newest version that actually runs here is 1.24.0. Latest-that-works beats latest.
- **Leaving `apiRuntime` unset means Oryx picks the version for you.** With no `platform` block, the build log showed Oryx detecting and installing 3.11.15 on its own. That works right up until the default moves, at which point the production runtime changes with no commit to point at. Pin it explicitly.
- **CI testing on a different Python than production is silent drift.** The test job was pinned to 3.13 while the deployed Function ran 3.11.15, so pytest never once executed against the version serving traffic. Nothing failed, which is exactly what makes it easy to miss. Read the deploy log (`Detected following platforms: python: ...`) rather than inferring the runtime from the workflow file.

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
