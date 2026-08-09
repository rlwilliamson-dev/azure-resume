---
title: "The deploy happens because you merged"
description: "A pipeline is a script that runs on somebody else's machine and is trusted to be honest about failure. GitOps goes one step further and makes the repository the thing reality is compared against. Both ideas are simpler than the tooling around them suggests."
track: "linux-plus"
level: "working"
order: 610
objectives:
  - "Describe the stages of a pipeline and what each one is for"
  - "Explain why exit codes are the entire contract between a script and a runner"
  - "Say what shift-left and DevSecOps mean without reaching for the marketing"
  - "Explain what makes an approach GitOps rather than merely automated"
  - "Describe how drift is detected and corrected by a reconciler"
  - "Identify why a pipeline is one of the most privileged things in an estate"
prerequisites: ["git-branching-and-collaboration", "infrastructure-as-code-concepts"]
tags: ["linux", "linux-plus", "ci-cd", "gitops", "devsecops", "automation"]
updated: 2026-08-09
draft: false
examObjectives:
  - exam: "xk0-006"
    domain: "4.0"
    objective: "4.1"
sources:
  - title: "githooks(5)"
    url: "https://git-scm.com/docs/githooks"
    publisher: "Git"
    accessed: 2026-08-09
    tier: 1
  - title: "Git Book, chapter 8.3: Git Hooks"
    url: "https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks"
    publisher: "Git"
    accessed: 2026-08-09
    tier: 1
  - title: "Bash Reference Manual, the set builtin"
    url: "https://www.gnu.org/software/bash/manual/bash.html#The-Set-Builtin"
    publisher: "GNU"
    accessed: 2026-08-09
    tier: 1
  - title: "OpenGitOps principles"
    url: "https://opengitops.dev/"
    publisher: "CNCF OpenGitOps"
    accessed: 2026-08-09
    tier: 1
  - title: "SLSA supply chain framework"
    url: "https://slsa.dev/spec/v1.0/levels"
    publisher: "OpenSSF"
    accessed: 2026-08-09
    tier: 1
symptoms:
  - symptom: "Pipeline reports success but the tests inside it failed"
    anchor: "the-contract-is-the-exit-code"
  - symptom: "Configuration changed on a server keeps reverting by itself"
    anchor: "gitops-the-repository-is-the-source-of-truth"
  - symptom: "Commit rejected locally by a hook before it reaches the server"
    anchor: "catching-it-before-it-leaves-your-machine"
---

> **Before you read.** Your team has infrastructure as code, a Git repository,
> and Ansible. Everything is version controlled. And every release still
> involves somebody with production credentials on their laptop running
> `ansible-playbook` from a terminal at 6pm on a Thursday.
>
> **Nothing about that is version controlled.** Not the moment it ran, not who
> ran it, not which branch they had checked out, and not whether the tests
> passed first.

The gap between "our configuration is in Git" and "our deployments come from
Git" is where this lesson lives. Closing it is what CI/CD is for.

The vocabulary is heavier than the ideas. A pipeline is a script that runs
somewhere else. A stage is one part of that script. GitOps is the observation
that if the repository already describes the desired state, something ought to
be continuously checking whether reality matches, and fixing it when it does
not.

### Some words you will need

<dl class="terms">
<dt>continuous integration (CI)</dt>
<dd>Every change is merged into a shared branch often, and automatically built and tested when it is.</dd>
<dt>continuous delivery</dt>
<dd>Every change that passes CI is <em>ready</em> to release. A human still chooses when.</dd>
<dt>continuous deployment</dt>
<dd>Every change that passes CI <em>is</em> released, with no human gate. Same acronym, different promise.</dd>
<dt>pipeline</dt>
<dd>The ordered set of automated steps a change passes through on its way to production.</dd>
<dt>stage</dt>
<dd>One step in a pipeline. Lint, build, test, scan, deploy.</dd>
<dt>runner / agent</dt>
<dd>The machine that actually executes the pipeline. Usually a container, started fresh.</dd>
<dt>artefact</dt>
<dd>The output of a build, a tarball, a package, a container image. The thing that gets promoted.</dd>
<dt>promotion</dt>
<dd>Moving one already-built artefact through environments, rather than rebuilding per environment.</dd>
<dt>shift left</dt>
<dd>Moving checks earlier, toward the developer, where a failure is cheap.</dd>
<dt>GitOps</dt>
<dd>The repository is the source of truth, and an agent continuously reconciles reality to it.</dd>
<dt>reconciliation</dt>
<dd>Comparing actual state against desired state and correcting the difference.</dd>
<dt>drift</dt>
<dd>Reality having diverged from the declared desired state.</dd>
</dl>

## What breaks without this

**The release depends on a person remembering.** Steps get skipped under
pressure, and the steps that get skipped are the boring ones, which is to say
the tests.

**"Works on my machine" survives to production.** If the build only ever
happens on a laptop, the laptop's installed versions are an undeclared part of
your build environment.

**Nobody can say what is deployed.** Without an artefact and a record of what
was promoted, "which version is in production" becomes an act of archaeology.

**Testing happens last, where it costs most.** A bug found by a developer costs
minutes. The same bug found in production costs an incident, a rollback, and a
postmortem.

**Credentials live on laptops.** If deployment is manual, every person who
might deploy needs production credentials permanently. If it is automated, the
pipeline needs them and people do not.

**Drift is permanent.** Somebody fixes production by hand during an incident,
the fix never reaches the repository, and the repository is now a lie that
everybody still trusts.

## The contract is the exit code

Before any of the tooling, understand the thing every CI system on earth is
built on: **a stage succeeds if its command exits zero and fails if it does
not.** That is the whole interface. GitHub Actions, GitLab CI, Jenkins, and a
`for` loop in a shell script all agree on this and nothing else.

Which means a pipeline is only as honest as its exit codes. Here is a pipeline
that looks completely reasonable:

```bash
#!/bin/bash
set -e
echo "stage: lint"
grep -q 'version' config.ini
echo "stage: test"
./run-tests.sh | tee test.log
echo "stage: deploy"
echo "shipped"
```

`set -e` says "stop at the first command that fails", which is exactly what a
pipeline should do. The test script genuinely fails, it prints a failure and
exits 1. Watch what happens anyway:

```bash
# AlmaLinux 10.2, x86_64
$ ./pipeline.sh; echo "pipeline exit status: $?"
stage: lint
stage: test
3 tests run, 1 failed
stage: deploy
shipped
pipeline exit status: 0
```

**It shipped.** The tests failed in plain English on the screen, the deploy
stage ran anyway, and the pipeline reported success to whatever was watching.

The cause is `| tee test.log`. **The exit status of a pipeline in the shell is
the exit status of the *last* command in it**, and `tee` succeeded. `run-tests.sh`
returning 1 was discarded the moment somebody added a pipe to capture the log.

<details class="predict">
<summary>One word is added to the <code>set</code> line: <code>set -e -o pipefail</code>. Nothing else in the script changes. What does the pipeline do now?</summary>

```bash
# AlmaLinux 10.2, x86_64
$ sed -i "s/^set -e$/set -e -o pipefail/" pipeline.sh; echo "--- same pipeline, one word added to set ---"; ./pipeline.sh; echo "pipeline exit status: $?"
--- same pipeline, one word added to set ---
stage: lint
stage: test
3 tests run, 1 failed
pipeline exit status: 1
```

</details>

**`pipefail` makes a shell pipeline return the status of the last command that
failed**, rather than only the last command. The deploy stage never runs, and
the pipeline correctly reports failure.

The two versions of that script are one word apart. One ships broken code
silently, forever, and looks green while doing it.

**This is why nearly every well-written CI script begins:**

```bash
set -euo pipefail
```

| Option | What it does | Why it matters in CI |
| --- | --- | --- |
| `-e` | Exit on any command that returns non-zero | Without it the script runs to the end regardless and always exits 0 |
| `-u` | Error on an undefined variable | A typo'd `$IMAGE_TAGG` becomes empty string, and you deploy `myapp:` |
| `-o pipefail` | A pipeline fails if any stage of it fails | The failure above |

<details class="deeper">
<summary>If you already administer Linux: where <code>set -e</code> quietly does not save you</summary>

`set -e` is necessary and it is not sufficient. It has documented exceptions,
and every one of them is a place a real pipeline has reported a false success.

**A command in a condition is never fatal.** This is by design: `if` needs to
see the failure:

```bash
if ./run-tests.sh; then echo ok; fi     # -e does not trigger
./run-tests.sh && echo ok               # nor here
./run-tests.sh || echo "tests failed"   # nor here
```

That last one is the trap. `cmd || echo "..."` looks like error handling and is
in fact error *suppression*: the `||` makes the whole thing succeed. If you want
to log and still fail, you need `cmd || { echo "..."; exit 1; }`.

**A function called in a condition disables `-e` for everything inside it.**

```bash
deploy() {
  build_image        # if this fails...
  push_image         # ...this still runs
}
if deploy; then ...  # because deploy was called in a condition
```

This one surprises people who have read the manual, and it is why long CI
scripts prefer explicit `|| exit 1` at each step over trusting `-e` alone.

**Only the last command's status survives a command substitution.**

```bash
export VERSION=$(get_version)   # get_version failing does not stop the script
```

The assignment succeeds, `export` returned 0, so `-e` sees nothing wrong, and
`$VERSION` is empty. Combined with `-u` not helping (the variable *is*
defined, just empty) this is a reliable way to deploy a container image tagged
with nothing at all. Split it:

```bash
VERSION=$(get_version)   # a plain assignment does propagate the failure
export VERSION
```

**`set -u` and arrays.** In older Bash, `"${array[@]}"` on an empty array trips
`-u`. Bash 4.4 and later are fine, but a pipeline running on an older runner
image will fail in a way that looks like your code and is not.

**The habit that actually works:** treat `set -euo pipefail` as a safety net,
not as error handling. Check the things you care about explicitly, and use
`trap 'echo "failed at line $LINENO" >&2' ERR` so that when a stage does fail,
the log says where.

</details>

## The stages, and what each is really for

Stage names vary by tool. The *sequence* is stable, because it is ordered by
cost: cheap and fast checks first, so an obviously broken change fails in
seconds rather than after a twenty-minute build.

| Stage | Question it answers | Typical duration |
| --- | --- | --- |
| **Lint / static analysis** | Is this even well-formed? | Seconds |
| **Unit test** | Do the pieces behave? | Seconds to minutes |
| **Build** | Does it compile, and what artefact comes out? | Minutes |
| **Scan** | Does the artefact contain known-vulnerable components or secrets? | Minutes |
| **Integration test** | Do the pieces work together, against real dependencies? | Minutes to tens of minutes |
| **Deploy to staging** | Does it install and start in a realistic environment? | Minutes |
| **Acceptance / smoke test** | Does the running thing actually serve traffic? | Minutes |
| **Deploy to production** |, | Minutes |

**Build once, deploy many.** The single most important structural rule: the
artefact built in the build stage is the artefact that goes to staging, and the
same one goes to production. Rebuilding per environment means the thing you
tested is not the thing you shipped, and every difference between them is
unaudited.

**Configuration is what varies between environments, not the artefact.** Same
container image, different environment variables, different secrets, different
database endpoint.

<details class="deeper">
<summary>If you already administer Linux: why the tag you deploy is not the identity of what you deployed</summary>

A container image has two names and they behave completely differently.

**A tag is a mutable label.** `myapp:1.4.2` points at an image today and can
point at a different image tomorrow, anybody with push access can move it.
`myapp:latest` is a tag that is *expected* to move, and deploying it means you
cannot say what is running.

**A digest is the content hash.** `myapp@sha256:9f86d0…` names exactly one
image, permanently, because the name *is* the hash of the content. It cannot be
moved, only orphaned.

This matters more than it sounds:

- **Rollback is only meaningful against a digest.** "Redeploy 1.4.2" is a
  request to redeploy whatever `1.4.2` currently points at.
- **Scanning is only meaningful against a digest.** A vulnerability report says
  "this image is clean". If the tag has since moved, the report is about a
  different image and nobody knows.
- **Your deployment record should store the digest**, even if a human typed a
  tag. Resolve the tag once, in the pipeline, and pin the digest downstream.
  Kubernetes deployments and OpenTofu configurations can both hold a digest.

**`imagePullPolicy` interacts with this.** A tag with `IfNotPresent` means a
node that already cached that tag never re-pulls, so two nodes can run different
images under the same tag indefinitely. With a digest that cannot happen.

**Signing goes one step further.** `cosign` and the Sigstore ecosystem sign
the digest, so a deployment can require that the image was produced by your
pipeline and not merely that it exists in your registry. That closes the gap
where an attacker with registry write access pushes a malicious image under a
legitimate tag. The SLSA framework in the sources describes the levels of
assurance this builds toward (provenance, signed provenance, hardened builds)
and it is worth skimming if supply chain is in your remit.

</details>

## Shift left, and DevSecOps

**Shift left** is one idea stated in a slightly annoying way: **the earlier a
problem is found, the cheaper it is to fix**, so move the checks toward the
start of the process.

Follow that arrow all the way and you arrive somewhere useful, the cheapest
place to catch a problem is not the pipeline at all. It is the developer's
machine, before the commit exists.

| Where it is caught | Roughly what it costs |
| --- | --- |
| Editor / on save | Seconds. Nobody else ever sees it. |
| Pre-commit hook | Seconds. Nothing leaves the machine. |
| Pipeline, on push | Minutes. One person is interrupted. |
| Code review | Hours to days. Two people are interrupted. |
| Staging | Days. The change is already integrated with others. |
| Production | An incident, a rollback, and a customer. |

**DevSecOps** applies the same arrow to security specifically. The traditional
model was a security review at the end, as a gate, which meant it happened
when changing anything was most expensive, and so it became a negotiation
about what to accept rather than what to fix.

**In practice DevSecOps is a set of pipeline stages**, not a philosophy:

- **Secret scanning**, does this change contain a credential? (`gitleaks`,
  `trufflehog`)
- **SAST**, static application security testing, does the source contain a
  known-dangerous pattern? (`semgrep`, `bandit`, and for shell, `shellcheck`)
- **Dependency scanning / SCA**, do the libraries you pulled in have known
  CVEs? (`grype`, `trivy`, `osv-scanner`)
- **Image scanning**, does the built container have vulnerable OS packages?
  (`trivy`, `clair`)
- **IaC scanning**, does the Terraform or Kubernetes YAML declare something
  insecure, like a public bucket or a privileged container? (`checkov`,
  `tfsec`)
- **SBOM generation**, produce a software bill of materials so that when the
  next Log4Shell happens you can answer "are we affected?" in minutes rather
  than weeks. (`syft`)

Each is a command that exits non-zero when it finds something. That is the
entire integration.

<details class="deeper">
<summary>If you already administer Linux: why most security stages end up switched off, and how to avoid it</summary>

Adding the scanners is an afternoon. Having them still be useful in six months
is the actual problem, and it fails in a predictable sequence.

**Week one:** you enable a dependency scanner on a mature codebase. It reports
four hundred findings, most of them in transitive dependencies, most rated high
because the scoring is context-free.

**Week two:** the pipeline is red permanently. Nobody can merge anything. So
somebody sets it to warn instead of fail.

**Month six:** the warnings scroll past in every build log, nobody reads them,
and the genuinely critical finding arrives in exactly the same font as the four
hundred that do not matter. You now have the cost of the scanner and none of the
benefit, plus a compliance checkbox that is technically true and practically
false.

**What actually works:**

**Baseline on introduction.** Record the findings that exist on the day you
turn the tool on, and fail the build only on findings *not* in that baseline.
New problems block; the existing backlog becomes scheduled work rather than an
emergency. Most scanners support this directly: `.semgrepignore`, grype's
ignore lists, `checkov --baseline`.

**Fail on new, report on old.** Same principle, stated as a rule you can defend
in a review: the pipeline's job is to stop the codebase getting worse.

**Differentiate blocking from advisory deliberately, per tool:**

| Finding | Block the build? | Why |
| --- | --- | --- |
| Secret detected in diff | **Yes, always** | Zero false-positive tolerance is appropriate; the cost of a leak is rotation at best |
| New critical CVE with a fix available | Yes | There is an action to take |
| Critical CVE with no fix available | No, report | Blocking achieves nothing except teaching people to bypass |
| Medium or low severity | No, report, review on a cadence | Otherwise the noise buries the criticals |
| IaC misconfiguration on a new resource | Yes | Cheap to fix at authoring time |

**Reachability matters more than severity.** A critical CVE in a code path your
application never calls is less urgent than a medium in your authentication
flow, and CVSS scores cannot tell you which is which. Tools that do reachability
analysis are worth the money precisely because they cut the volume enough that
people read the output.

**Make suppression explicit, expiring, and reviewed.** An ignore entry should
carry who added it, why, and a date it lapses. A permanent unexplained
suppression is how a known vulnerability lives in a codebase for three years
with a green build the whole time.

**Fast checks in the pipeline, slow ones out of band.** A full image scan and
a DAST run against staging do not belong in the path between commit and merge.
Run them nightly against `main`, and file findings as work. The pipeline
should stay fast enough that nobody wants to route around it, a pipeline
people wait twenty minutes for is a pipeline people learn to skip.

**The measure of success is not findings, it is time-to-fix.** Any tool can
produce findings. The question worth asking at the six-month mark is how long a
newly introduced critical finding survives, and whether anybody had to be
chased about it.

</details>

## Catching it before it leaves your machine

Git will run scripts of yours at defined moments. They live in `.git/hooks/`,
they are ordinary executables, and **a hook that exits non-zero aborts the
operation.** Same contract as everything else in this lesson.

```bash
#!/bin/sh
if git diff --cached | grep -qE 'AKIA[0-9A-Z]{16}|BEGIN [A-Z ]*PRIVATE KEY'; then
  echo "pre-commit: refusing this commit, the staged diff contains a credential" >&2
  exit 1
fi
```

`git diff --cached` is the staged change, precisely what is about to be
committed. Now somebody appends an access key to a config file and commits it:

```bash
# AlmaLinux 10.2, x86_64
$ echo "aws_key = AKIAIOSFODNN7EXAMPLE" >> config.ini; git add config.ini; git commit -m "add deploy credentials"; echo "git commit exit status: $?"
pre-commit: refusing this commit, the staged diff contains a credential
git commit exit status: 1
```

<details class="predict">
<summary>The commit was refused. Was anything recorded? What state is the working tree in?</summary>

```bash
# AlmaLinux 10.2, x86_64
$ echo "aws_key = AKIAIOSFODNN7EXAMPLE" >> config.ini; git add config.ini; git commit -m "x" 2>/dev/null; echo "--- the change is still staged, and nothing was recorded ---"; git status --short; git log --oneline
--- the change is still staged, and nothing was recorded ---
M  config.ini
f550218 initial commit
```

</details>

**Nothing was recorded and nothing was lost.** The history still has one commit,
and the change is still sitting in the index where the author can fix it. That
is the ideal shape for a check: refuse, explain, and leave the work intact.

**The hooks worth knowing:**

| Hook | Runs | Commonly used for |
| --- | --- | --- |
| `pre-commit` | Before the commit message is requested | Linting, formatting, secret scanning |
| `commit-msg` | After the message is written | Enforcing a message convention or ticket reference |
| `pre-push` | Before objects are sent to a remote | Running the test suite |
| `pre-receive` | On the **server**, before refs are updated | Policy that must not be bypassable |
| `update` | On the server, once per ref | Per-branch protection rules |
| `post-receive` | On the server, after refs update | Triggering a deployment or notification |

<details class="deeper">
<summary>If you already administer Linux: a client hook is a convenience, never a control</summary>

Everything above is genuinely useful and none of it is a security boundary. Be
precise about why, because people do get this wrong in audits.

**`.git/hooks/` is not in the repository.** Clone a repo and you get the sample
hooks and none of the real ones. Hooks are per-clone local configuration by
design, so a hook you wrote protects you and nobody else.

**And it is trivially skipped.** `git commit --no-verify` bypasses
`pre-commit` and `commit-msg`; `git push --no-verify` bypasses `pre-push`. No
privilege needed, and the flag exists for legitimate reasons, you sometimes
must commit work in progress that fails the linter.

**So the same check has to exist twice**, and understanding why is the point:

- **On the client**, for speed and kindness. The developer gets the answer in
  half a second instead of after a push and a four-minute pipeline.
- **On the server or in the pipeline**, for enforcement. A `pre-receive` hook or
  a required status check cannot be bypassed with a flag, because it does not
  run on a machine the committer controls.

**Distributing client hooks.** Because they are not versioned, teams use one of:

- `git config core.hooksPath .githooks`, points Git at a directory that *is*
  in the repository. One command, and it is still opt-in per clone.
- The `pre-commit` framework (a widely used tool that confusingly shares its
  name with the hook), which manages hook definitions in a versioned
  `.pre-commit-config.yaml` and installs them.

**The one that actually matters for secrets.** A pre-commit secret scan
prevents the credential entering history. That is worth a great deal, because
**once a secret is committed and pushed, rotating it is the only real
remediation.** Rewriting history does not help: the object may already be
fetched, cached by the forge, referenced by a pull request, or sitting in
somebody's reflog. Treat "it was in a commit on a branch for ten minutes" as
"it is public". Delete the branch by all means, then go and rotate the key.

**A note on the regex.** The one above matches AWS access key IDs and PEM
headers, which catches the common cases and will miss plenty. Real scanners
carry hundreds of patterns plus entropy heuristics. A hand-rolled grep is a
speed bump, and a speed bump in the right place still stops most of what walks
into it.

</details>

## GitOps: the repository is the source of truth

Everything so far is push-based. Something happens, a pipeline runs, and it
pushes a change outward into your infrastructure.

**GitOps inverts the direction.** An agent runs *inside* the environment,
holds the repository as the statement of what should be true, and continuously
compares it against what actually is. When they differ, the agent corrects
reality, not the other way round.

Four principles, from the OpenGitOps project:

1. **Declarative**. The desired state is described, not scripted.
2. **Versioned and immutable**. It lives in Git, so it has history and
   identity.
3. **Pulled automatically**, agents pull the desired state; nobody pushes to
   prod.
4. **Continuously reconciled**, agents keep converging reality toward it.

A reconciler is conceptually tiny. This one compares a directory against the
committed state, and corrects it:

```bash
#!/bin/sh
cd /srv/desired
if git diff --quiet; then
  echo "reconcile: in sync, nothing to do"
else
  echo "reconcile: drift detected"
  git --no-pager diff --stat
  git checkout -- .
  echo "reconcile: actual state returned to desired state"
fi
```

Run it, then do the thing everybody does during an incident:

```bash
# AlmaLinux 10.2, x86_64
$ reconcile; echo "--- now somebody edits the server directly, at 2am, during an incident ---"; sed -i "s/max_connections = 200/max_connections = 5000/" app.conf; reconcile; echo "--- what does the file say now ---"; cat app.conf; reconcile
reconcile: in sync, nothing to do
--- now somebody edits the server directly, at 2am, during an incident ---
reconcile: drift detected
 app.conf | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
reconcile: actual state returned to desired state
--- what does the file say now ---
max_connections = 200
log_level = warn
reconcile: in sync, nothing to do
```

**Read the last two lines carefully, because they are the whole argument.** The
2am change is gone. Somebody raised `max_connections` to 5000 to get through an
incident, and the reconciler put it back to 200 without asking.

**That is the feature.** It is also, the first time it happens to you, deeply
annoying, and the annoyance is the point. There are exactly two honest
responses to a reconciler reverting your fix:

- The fix was right, so **commit it**, and now the repository and reality agree
  and the next server built from it also gets the fix.
- The fix was wrong, and it has been removed automatically.

What is no longer possible is the third outcome, which is the one that used to
happen every time: the fix stays on one server, nobody writes it down, and
eighteen months later that machine is subtly different from its fifty siblings
and nobody alive knows why.

**Real GitOps tooling**, Argo CD and Flux are the two you will hear named,
does exactly this against a Kubernetes cluster instead of a directory, and
adds a UI, health checks, and the ability to *report* drift rather than always
correcting it.

<details class="deeper">
<summary>If you already administer Linux: pull versus push, and the security argument that is the real reason</summary>

GitOps is usually sold on consistency. The stronger argument is about
credentials, and it is worth being able to make.

**In a push model, the pipeline must be able to reach production.** Which
means the CI system holds production credentials, a kubeconfig, a cloud role,
an SSH key. That system is on the internet, runs code from every branch
anybody pushes, and executes third-party actions and plugins. It is,
structurally, one of the most exposed things you own, and you have given it
the keys.

**In a pull model, nothing outside needs credentials to get in.** The agent runs
inside the cluster, and it makes *outbound* connections to the Git repository
and the registry. Production has no inbound path for deployment at all. The CI
system's most dangerous privilege shrinks to "can write to a Git repository",
which is a much smaller blast radius and one you already audit through code
review.

That inversion is why GitOps caught on in regulated environments, well ahead of
the developer-experience arguments.

**The genuine costs, which the marketing skips:**

**Secrets cannot go in the repository.** The declarative state is public to
everyone with repository access, so secrets need a separate mechanism,
sealed-secrets (encrypted to a key only the cluster holds), the External
Secrets Operator (the repository stores a *reference* into Vault or a cloud
secret manager), or SOPS-encrypted files. This is not optional and it is the
first thing every GitOps adoption trips over.

**Break-glass has to be designed deliberately.** During a severe incident you
may genuinely need to change something now and reconcile later. Both Argo CD
and Flux support suspending reconciliation for an application. Decide who may
do that, make it loud, and make resuming it part of the incident checklist, an
application left suspended is a server that has quietly left the estate.

**The repository becomes production infrastructure.** If Git is down you cannot
deploy, and the branch protection rules on that repository are now access
control for production. Merge permissions are deployment permissions. Treat them
that way, require review, and require signed commits if your forge supports it.

**Drift correction can fight another controller.** Anything else that edits
the same resource (an autoscaler, a mutating webhook, an operator) produces an
endless correction loop. Both tools have ignore rules for exactly this, and
you will need them.

</details>

<details class="deeper">
<summary>If you already administer Linux: the pipeline is the most privileged thing you own</summary>

Work through what a CI runner has, because most estates never do.

**It holds every credential needed to deploy**, registry push, cloud roles,
Kubernetes access, signing keys, package repository tokens. Often for every
environment, in one place.

**It executes code from every branch.** Anybody who can open a pull request can
propose a change to the pipeline definition itself. If pipelines run on pull
requests from forks with access to secrets, an outsider can exfiltrate them by
opening a PR that echoes them.

**It pulls in third-party code at runtime.** Every `uses:
some-org/some-action@v3` is a dependency executing inside that privileged
context. `@v3` is a mutable tag, the same problem as image tags, with worse
consequences. Pin actions to a commit SHA.

**It is the ideal supply chain target.** Compromising one build server is
worth more than compromising one developer, because everything downstream trusts
its output by construction. This is the SolarWinds shape: not a vulnerability in
the product, a compromise of the thing that built it.

**What to actually do about it, roughly in order of value:**

- **Short-lived credentials over stored ones.** OIDC federation between your CI
  provider and your cloud gives the job a token valid for minutes, scoped to that
  repository, with nothing at rest to steal. This single change removes most of
  the risk.
- **Separate the deploy identity per environment**, so a compromised staging
  pipeline is not a production compromise.
- **Do not expose secrets to pull-request builds from forks.** Most forges make
  this configurable and the default is not always safe.
- **Pin third-party actions and images by digest**, and review them the way you
  review dependencies, because that is what they are.
- **Ephemeral runners.** A container started fresh per job and destroyed after
  cannot carry state, cached credentials, or an implant from one job to the next.
  Self-hosted persistent runners are the opposite of this and need real hardening.
- **Log what deployed what.** Artefact digest, commit SHA, who approved, when.
  This is the record that answers "what changed?" during an incident, which is
  the first question asked and often the hardest to answer.
- **Protect the branch that deploys.** If merging to `main` deploys to
  production, then merge permission on `main` *is* production access. Require
  review, require passing checks, and disallow force-push.

**The pattern underneath all of these:** the pipeline is production
infrastructure with production privileges. It usually gets treated as developer
tooling, and that gap between what it can do and how carefully it is guarded is
where the incidents come from.

</details>

## Putting the pieces in order

For an ordinary web service, a complete path looks like this:

1. Developer commits. **Pre-commit hook** lints and scans for secrets locally.
2. Push to a branch. **Pipeline runs** lint, unit tests, SAST, dependency scan.
3. Pull request opened. **Same checks run**, plus a build, and the results become
   required status checks a human reviewer can see.
4. **Review and approval.** Branch protection means this cannot be skipped.
5. Merge to `main`. **Build once**, producing an artefact addressed by digest.
6. **Scan the artefact**, sign it, publish it to the registry.
7. Pipeline commits the new digest to the **environment repository** for staging.
8. **The GitOps agent notices** and reconciles staging to it. Smoke tests run.
9. Promotion to production is **a commit to the production environment
   repository**, often itself a pull request, requiring an approval.
10. **The agent reconciles production.** The deploy happened because you merged.

Note where the human decisions are: reviewing code, and approving a promotion.
Everything else is a consequence.

**Rollback in this model is a `git revert`**, which is why keeping the
artefact addressed by digest matters, reverting the commit restores the
previous digest, and the previous digest is still exactly the bytes that were
running before.

<details class="deeper">
<summary>If you already administer Linux: environment promotion, and why two repositories</summary>

Step 7 above quietly introduced a second repository, which is the part people
find odd. It is worth explaining because the alternative is worse.

**The application repository holds source.** Its pipeline builds and tests, and
its output is an artefact.

**The environment repository holds desired state**, which artefact digests are
running where, with what configuration. It is what the GitOps agents watch.

**Why separate them:**

- **A deploy is not a code change.** Promoting the same artefact from staging to
  production changes nothing about the source, so it should not require a commit
  to the source repository.
- **The permission boundaries differ.** Many people may merge source. Far fewer
  should merge production desired state.
- **It stops the loop.** If the pipeline commits a new digest back to the same
  repository it watches, the commit triggers the pipeline, which commits again.
  Everybody discovers this the hard way once.
- **The history becomes a deployment log.** `git log` on the environment
  repository is the literal, complete answer to "what was running in production
  on the 14th, and who approved it".

**How environments are usually separated:** by directory, not by branch.
`environments/staging/` and `environments/production/`, each with its own
agent. Using long-lived branches per environment sounds tidy and produces the
merge problem from lesson 56, the environments drift, cherry-picks accumulate,
and eventually staging contains something production never had.

**Promotion is then a small, reviewable diff:**

```text
-  image: registry.example.com/app@sha256:9f86d081...
+  image: registry.example.com/app@sha256:2c26b46b...
```

One line, in a pull request, with the pipeline's evidence attached, this
digest passed these tests and has been running in staging for four days. That
is a review a human can actually perform, which is more than can be said for
most deployment approvals.

</details>

## For the exam

**Know the three C-words apart.** Continuous integration is merge-and-test
often. Continuous *delivery* is always ready to release, human decides.
Continuous *deployment* is released automatically. Being asked to distinguish
delivery from deployment is common.

**Version control triggers the pipeline.** If a question describes the
trigger, it is a commit, a push, a tag, or a merge, not a schedule and not a
person.

**Shift left means testing earlier**, and the security flavour of it is
DevSecOps.

**GitOps is defined by the repository being the source of truth plus continuous
reconciliation.** Automated deployment alone is not GitOps; the distinguishing
feature is that an agent pulls and converges.

**Build once, promote the artefact.** Rebuilding per environment is the wrong
answer whenever it is offered.

**Exit codes are how stages report.** Zero is success.

<details class="qa">
<summary>Check yourself</summary>

**A pipeline stage runs `pytest | tee results.txt`. Tests fail. Does the stage
fail?**
Not unless `pipefail` is set. The status is `tee`'s, which succeeded. This is
the failure captured above.

**What is the difference between continuous delivery and continuous
deployment?**
Whether a human approves the release. Delivery means every passing change
*could* be released; deployment means it *is*, automatically.

**Why build the artefact once rather than per environment?**
So that the thing tested in staging is bit-for-bit the thing running in
production. Rebuilding introduces unaudited differences.

**A developer bypasses your pre-commit secret scanner. How?**
`git commit --no-verify`. Client hooks are a convenience; enforcement needs a
server-side hook or a required status check.

**A secret was committed and pushed, then the commit was amended away. What is
the remediation?**
Rotate the secret. History rewriting does not reliably remove it, and you must
assume it was fetched or cached.

**What makes an approach GitOps rather than just automated deployment?**
Declarative desired state in Git, pulled by an agent inside the environment,
continuously reconciled against reality.

**Someone changed a config file on a GitOps-managed server and it reverted. Is
that a bug?**
No, that is reconciliation. The correct response is to commit the change if it
was right.

**Why is a pull model considered more secure than a push model?**
Because production needs no inbound access and the CI system holds no
production credentials. The agent reaches out to Git rather than CI reaching
into production.

**Your GitOps repository cannot hold secrets. Name two ways round it.**
Encrypt them into the repository (sealed-secrets, SOPS), or store a reference
and fetch the value at runtime (External Secrets Operator, Vault).

**Why pin a third-party CI action to a commit SHA rather than a version tag?**
A tag is mutable. Whoever controls the action can move `v3` to different code,
which then executes inside your most privileged environment.

**Which container image identifier should a deployment record store, and why?**
The digest. A tag can be repointed, so it does not identify what actually ran.

</details>

## Where this sits

Lesson 56 gave you branches and merges; this lesson is what happens *because* of
a merge. Lesson 57 gave you declarative desired state, and GitOps is that idea
plus a loop that never stops running. Lessons 58 and 59 gave you the tools a
pipeline usually calls.

The next lesson takes the containers from lesson 35 and asks what happens when
there are forty of them that have to find each other.

> **The commands here were run on a real machine, not written from memory.** The
> pipeline, hook, and reconciler transcripts come from AlmaLinux 10.2 on x86_64.
> The pipeline that shipped failing tests really did exit 0; adding `pipefail`
> and changing nothing else really did stop it. If you want to see it for
> yourself, the scripts are short enough to retype in a scratch directory, and
> that is a better use of ten minutes than rereading this section.
