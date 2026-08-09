---
title: "Two people, one file, at the same time"
description: "Branches, merges, and the conflict markers Git writes into your file when it cannot decide. Plus the difference between reset and revert, which decides whether you can safely undo something everybody else already has."
track: "linux-plus"
level: "working"
order: 570
objectives:
  - "Create a branch, switch between branches, and merge one into another"
  - "Read conflict markers and resolve a conflict by hand"
  - "Distinguish fetch from pull and say what each one changes"
  - "Choose between reset and revert based on whether the commit was shared"
  - "Explain what rebase does to history and when it is unsafe"
prerequisites: ["git-the-basics"]
tags: ["linux", "linux-plus", "git", "version-control", "automation"]
updated: 2026-08-08
draft: false
examObjectives:
  - exam: "xk0-006"
    domain: "4.0"
    objective: "4.4"
sources:
  - title: "git-branch(1)"
    url: "https://git-scm.com/docs/git-branch"
    publisher: "Git project"
    accessed: 2026-08-08
    tier: 1
  - title: "git-merge(1)"
    url: "https://git-scm.com/docs/git-merge"
    publisher: "Git project"
    accessed: 2026-08-08
    tier: 1
  - title: "git-rebase(1)"
    url: "https://git-scm.com/docs/git-rebase"
    publisher: "Git project"
    accessed: 2026-08-08
    tier: 1
  - title: "git-revert(1)"
    url: "https://git-scm.com/docs/git-revert"
    publisher: "Git project"
    accessed: 2026-08-08
    tier: 1
  - title: "git-fetch(1)"
    url: "https://git-scm.com/docs/git-fetch"
    publisher: "Git project"
    accessed: 2026-08-08
    tier: 1
  - title: "git-stash(1)"
    url: "https://git-scm.com/docs/git-stash"
    publisher: "Git project"
    accessed: 2026-08-08
    tier: 1
symptoms:
  - symptom: "CONFLICT (content): Merge conflict in a file"
    anchor: "when-git-cannot-decide"
  - symptom: "Conflict markers left in a config file"
    anchor: "when-git-cannot-decide"
  - symptom: "Updates were rejected because the tip of your current branch is behind"
    anchor: "working-with-a-remote"
---

> **Before you read.** You are changing `nginx.conf` to move the site to port 8080
> for a new proxy. A colleague is changing the same file, at the same time, to
> enable TLS on 443.
>
> Both changes are correct. Both are wanted. They touch the same line.
>
> **Somebody has to decide what that line ends up saying, and it cannot be a
> program, because the answer depends on what you are both trying to achieve.**

That is the whole of this lesson. Git is extremely good at combining changes that
do not overlap, and it is honest about the ones that do: it stops, writes both
versions into the file, and hands the decision to a person.

Everything else here (branches, remotes, rebase, revert) exists to make that
situation rarer and to make the recovery predictable when it happens anyway.

### Some words you will need

<dl class="terms">
<dt>branch</dt>
<dd>A movable name pointing at a commit. Not a copy of anything.</dd>
<dt>merge</dt>
<dd>Combining two branches, producing a commit with two parents.</dd>
<dt>conflict</dt>
<dd>Two branches changing the same lines, so Git cannot choose.</dd>
<dt>remote</dt>
<dd>Another copy of the repository, usually on a server. <code>origin</code> by convention.</dd>
<dt>fast-forward</dt>
<dd>A merge that needs no commit, because one branch is simply ahead of the other.</dd>
<dt>rebase</dt>
<dd>Replaying commits onto a different base, producing new commits with new hashes.</dd>
</dl>

## What breaks without this

**Everybody edits the same copy.** Two people saving the same file over each other
loses one set of changes with no record that it happened.

**Unfinished work blocks finished work.** Without branches, a half-done change sits
in the only copy there is, so nothing else can ship until it is done or discarded.

**You cannot undo a published change safely.** Rewriting a commit somebody else
already has makes their history disagree with yours, and the repair is worse than
the original problem.

**And conflict markers end up in production.** `<<<<<<< HEAD` in a config file is a
syntax error in every configuration language there is, and it happens when somebody
resolves a conflict by ignoring half of it.

## A branch is a pointer, not a copy

This is the idea that makes everything else cheap.

A branch is a file containing one 40-character hash. Creating one writes 41 bytes.
It does not copy the working tree, does not duplicate history, and takes the same
time on a repository of four files or four hundred thousand.

```
git switch -c add-tls        # create and switch to it
git switch main              # go back
git branch -v                # what exists, and where each one points
git branch -d add-tls        # delete it once merged
```

**`git switch` and `git restore` are the modern commands**, split out of
`git checkout` because one command doing both branch-switching and file-discarding
caused too many accidents. `checkout` still works and still does both, and you will
see it everywhere.

Two branches, each with a commit the other does not have. Both were made from the
same starting commit.

<details class="predict">
<summary><code>git log --all</code> shows every branch at once. Given both branches grew from one shared commit, how many commits will the graph show in total, four, or three?</summary>

```bash
# Debian 13 (trixie), x86_64
$ cd /root/site; git branch -v; echo "--- the two histories ---"; git log --oneline --graph --all
  add-tls b64415a Serve TLS on 443
* main    0fa0412 Move to port 8080 for the proxy
--- the two histories ---
* b64415a Serve TLS on 443
| * 0fa0412 Move to port 8080 for the proxy
|/  
* 544ed7e Add the initial nginx config
```

</details>

**Three, because the shared commit is shared rather than copied.** `544ed7e`
is one object that both branches point back to through their own history.
Branching duplicated nothing, which is the practical meaning of "a branch is a
pointer", and why a repository with forty branches is not forty times the
size.

**The `|/` on the fourth line is where they diverge.**

**The `*` marks the branch you are on.** The graph shows the shape: one shared
commit at the bottom, then the history splits. Both branches are real, both are
complete, and neither knows about the other's commit.

**`git log --oneline --graph --all` is the command worth memorising.** It is the
only way to see the shape of a repository rather than one linear list, and it makes
merges, rebases, and divergence immediately visible.

## When Git cannot decide

Merging pulls the other branch's work into this one.

<details class="predict">
<summary>Both branches changed the <code>listen</code> line of the same file, to different values. Git cannot know which is right. What does <code>git merge</code> do, pick one, refuse, or something else?</summary>

```bash
# Debian 13 (trixie), x86_64
$ cd /root/site; git merge add-tls; echo "rc=$?"
Auto-merging nginx.conf
CONFLICT (content): Merge conflict in nginx.conf
Automatic merge failed; fix conflicts and then commit the result.
rc=1
```

</details>

**It stops, exits 1, and leaves the merge half-finished.** That non-zero status
matters: a script or a CI pipeline can detect it, which is why automated merges are
possible at all.

**`Auto-merging nginx.conf` on the line above is not a failure.** Git merges
files line by line, so a change to line 2 and a change to line 40 of the same
file combine without any trouble. Only the overlapping lines conflict, which
is why "we both edited the same file" is usually fine and "we both edited the
same line" is not.

Now look at what it did to the file:

```bash
# Debian 13 (trixie), x86_64
$ cd /root/site; git merge add-tls >/dev/null 2>&1; echo "--- what git wrote into the file ---"; cat nginx.conf; echo "--- and what status says ---"; git status --short
--- what git wrote into the file ---
server {
<<<<<<< HEAD
  listen 8080;
=======
  listen 443 ssl;
>>>>>>> add-tls
  root /var/www;
}
--- and what status says ---
UU nginx.conf
```

**Git edited your file and put both versions in it**, marked up so you can see
which came from where:

| Marker | Means |
| --- | --- |
| `<<<<<<< HEAD` | Everything below is **your** current branch's version |
| `=======` | The divider |
| `>>>>>>> add-tls` | Everything above is from **that** branch |

`root /var/www;` is outside the markers because both branches agree on it.
Only the disputed lines are wrapped, which is how you see the scope of the
disagreement at a glance.

`UU` in `git status --short` means unmerged on both sides. That is the state
to recognise: the merge is in progress and will not complete until you resolve
it.

Resolving means editing the file until it says what you want, then removing
all three marker lines. There is no command that does it, because there is no
rule that could. The answer here is "TLS on 443, and route the proxy
differently", which is a decision about the system rather than about the text.

```bash
# Debian 13 (trixie), x86_64
$ cd /root/site; git merge add-tls >/dev/null 2>&1; printf "server {\n  listen 443 ssl;\n  root /var/www;\n}\n" > nginx.conf; git add nginx.conf; git commit -q -m "Merge add-tls, keeping TLS on 443"; git log --oneline --graph | head -6
*   3ae907c Merge add-tls, keeping TLS on 443
|\  
| * b64415a Serve TLS on 443
* | 0fa0412 Move to port 8080 for the proxy
|/  
* 544ed7e Add the initial nginx config
```

`git add` is how you say "resolved". It stages the file and tells Git the
conflict is settled; then `git commit` completes the merge.

The graph now shows the join. The merge commit at the top has **two parents**,
which is what a merge commit is, the two lines converge back into one, and the
history permanently records that these were separate pieces of work.

If it goes wrong, `git merge --abort` returns everything to how it was before
the merge started. That is worth knowing before you need it, because a
conflict in an unfamiliar repository is exactly when people panic.

<details class="deeper">
<summary>If you already administer Linux: conflict markers reaching production, and the three things that stop it</summary>

`<<<<<<< HEAD` in a deployed config file is a real outage cause, and it is more
common than it should be because every step that would catch it is optional.

**How it happens:** somebody resolves a conflict by editing the parts they
care about and misses a second conflict lower in the file, or resolves it in
an editor that folded the markers out of sight. `git add` accepts the file
regardless, Git does not check that the markers are gone, because they are
legal text.

Three things that catch it, in increasing order of reliability:

A check before committing. `git diff --check` is built in and reports conflict
markers alongside whitespace errors, which is the least-effort version:

```
git diff --cached --check
```

**A pre-commit hook**, so it is not something anybody has to remember:

```bash
#!/bin/bash
# .git/hooks/pre-commit
if ! git diff --cached --check; then
    echo "conflict markers or whitespace errors in staged changes" >&2
    exit 1
fi
```

Validating the file itself, which is the one that actually protects production
because it catches everything rather than just this:

```
nginx -t
sshd -t
visudo -c
named-checkconf
python3 -c "import yaml,sys; yaml.safe_load(open(sys.argv[1]))" file.yml
```

Every serious configuration format has a syntax checker, and a pipeline that runs
the relevant one on every change makes conflict markers a build failure rather than
an outage.

**The version that bites hardest is a merge nobody knew happened.** A `git
pull` that auto-merges cleanly needs no attention, and one that conflicts
leaves the working tree half-merged, which a subsequent scripted deploy will
happily copy to a server. Any deploy script starting with `git pull` should
check that `git status --porcelain` is empty before it copies anything.

</details>

## Working with a remote

A remote is another copy of the repository. `origin` is the conventional name for
the one you cloned from.

| Command | Does |
| --- | --- |
| `git clone <url>` | Copy a repository, setting `origin` |
| `git fetch` | Download new commits. **Changes nothing locally.** |
| `git pull` | `fetch` **and then** merge into your branch |
| `git push` | Send your commits to the remote |
| `git remote -v` | What remotes exist |

**`fetch` and `pull` differ in exactly one way and it matters.** `fetch` updates
your knowledge of what the remote has, leaving your branch alone; `pull` does that
and immediately merges. So `fetch` is always safe, and `pull` can produce a conflict
in your working tree at a moment you did not choose.

**The habit worth having:**

```
git fetch
git log --oneline HEAD..origin/main     # what did they do that I do not have
git merge origin/main                   # now, deliberately
```

That separates "find out" from "act", which is the same reason `--dry-run` exists
for `rsync`.

**`git push` failing with "the tip of your current branch is behind"** means
somebody pushed while you were working. The fix is to integrate their work
first: `git pull` and resolve anything that conflicts, then push again.

**`git push --force` is how people lose other people's commits**, because it
replaces the remote branch with yours and discards whatever was there.
`--force-with-lease` refuses if the remote has moved since you last fetched, which
turns a silent overwrite into an error message. If you must force, use the lease
version.

## Undoing things other people have

The rule is short and it is the most consequential thing in this lesson.

| Situation | Use | Because |
| --- | --- | --- |
| Commit is only local | `git reset` | History is yours to rewrite |
| Commit has been pushed | **`git revert`** | Everybody else already has it |

**`git revert` makes a new commit that undoes an old one.** The original stays in
history, the undo is visible, and anybody who pulls simply gets one more commit.
Nothing anybody has is invalidated.

```
git revert 0fa0412
git revert HEAD
git revert --no-commit HEAD~3..HEAD     # undo three, in one commit
```

**`git reset` moves the branch pointer**, which changes what the history *is*.
On a shared branch that means everyone else's copy now disagrees with the
remote, and their next push either fails or, if somebody forces, restores the
commits you removed.

**The audit argument matters here too.** On infrastructure code, a `revert` records
that a change was made and then withdrawn, with both commits and both messages. A
`reset` records that it never happened. When the question is "why did production
change at 14:00 and change back at 14:20", only one of those can answer it.

<details class="deeper">
<summary>If you already administer Linux: what rebase actually does, and the one rule that keeps it safe</summary>

Rebase produces a tidier history than merge and does it by **creating new commits**,
which is the whole of both its value and its danger.

**Merge** joins two lines and records that they were separate. **Rebase** takes your
commits, replays them one at a time onto the tip of another branch, and throws the
originals away. The result is a straight line, as though you had started from the
newer base.

```
git switch add-tls
git rebase main          # replay my commits on top of current main
```

**Every replayed commit gets a new hash**, because a commit's hash covers its
parent, so changing the parent changes the commit, necessarily. That is the
mechanism, and it explains the rule.

**The rule: never rebase commits that other people have.** If a commit has
been pushed and somebody has pulled it, rebasing creates a different commit
with the same content. Their history has the old one, yours has the new one,
and the next merge brings both back, the change appears twice, and untangling
it is genuinely unpleasant.

**Where rebase is right** is your own unpushed work, and the payoff is real: a
feature branch rebased onto current `main` before merging produces a history that
reads as a sequence of complete changes rather than a braid.

**Interactive rebase is where most of the practical value is:**

```
git rebase -i HEAD~4
```

That opens an editor listing four commits, each with a verb you can change:

| Verb | Does |
| --- | --- |
| `pick` | Keep it as is |
| `reword` | Keep it, edit the message |
| `squash` | Combine into the previous commit, keeping both messages |
| `fixup` | Combine, discarding this message |
| `drop` | Remove it |
| `edit` | Stop here so you can amend it |

**`fixup` is the one that earns its place.** Four commits of "fix typo", "fix typo
again", "actually fix it" collapse into the one commit that should have existed,
before anybody else sees them.

**A rebase that goes wrong is recoverable**, which is worth knowing before
trying one. `git rebase --abort` returns to the starting state, and if you
have already finished a bad rebase, the reflog still has the original commits,
the same recovery as the previous lesson.

**The team-level version of this argument** is that "merge or rebase" is a policy
decision rather than a technical one. Merge preserves what actually happened; rebase
preserves readability. Most teams rebase their own feature branches and merge into
the shared one, which gets both.

</details>

<details class="deeper">
<summary>If you already administer Linux: branching strategies, and why the simplest one usually wins</summary>

Teams argue about this, and the argument is mostly about deployment frequency
rather than about Git.

**Trunk-based development.** One long-lived branch. Feature branches live hours or
days and merge back constantly. Anything incomplete is hidden behind a feature flag
rather than held on a branch.

**GitHub Flow.** `main` is always deployable. Every change is a short-lived branch
and a pull request, merged when it passes review and checks. Effectively
trunk-based with a review gate.

**Git Flow.** Long-lived `develop` and `main`, plus `feature/`, `release/`, and
`hotfix/` branches. Designed in 2010 for software with versioned releases shipped
to customers who install them.

**The reason to know Git Flow is mainly to know when not to use it.** Its own
author added a note years later saying it is the wrong choice for continuously
delivered web software, which is most of what an administrator deals with. Its
complexity buys you the ability to support several released versions at once,
real value for a product with customers on version 3.2, and pure overhead for
a service where production is whatever is on `main`.

**For infrastructure code specifically, the deciding constraint is different from
software.** You usually cannot have two versions live at once, so long-lived
branches accumulate drift against a reality that keeps moving. A branch that is
three weeks old has been written against a world that no longer exists, and merging
it is a bigger risk than the change it contains.

**Which points at short-lived branches and frequent merges**, plus the thing that
makes that safe: a pipeline that can tell you the change works before it is merged.
That is the next lesson.

**Two mechanics worth knowing whichever strategy applies:**

**A pull request is a hosting-provider feature, not a Git one.** There is no
`git pull-request`. It is a merge with a review step and a place to hang
automated checks bolted on by GitHub, GitLab, and the rest, which is why the
same repository works identically without one.

**Protected branches are how the policy is enforced rather than agreed.** Requiring
a review, requiring checks to pass, and forbidding force-push are server-side rules;
without them, a branching strategy is a convention that holds until somebody is in a
hurry at 3am.

</details>

## Putting work aside

`git stash` takes your uncommitted changes, saves them, and gives you a clean
working tree, for the case where something urgent arrives mid-change.

```
git stash                    # put changes aside
git stash list               # what is stashed
git stash pop                # bring the most recent back and remove it
git stash apply              # bring it back and keep it stashed
git stash -u                 # include untracked files
```

**`pop` and `apply` differ in whether the stash is kept**, and `apply` is the safer
default when you are not certain the changes will apply cleanly.

Stash is a convenience, not storage. It is local, it has no message worth
reading unless you supply one with `git stash push -m`, and a stash from three
weeks ago is a mystery. For anything you might want tomorrow, a branch and a
commit are better, which is the same argument as the previous lesson's "commit
early", applied to a different symptom.

The `-u` is the part people get caught by. A plain `git stash` leaves
untracked files where they are, so switching branches afterwards carries them
along and they appear to belong to the new branch.

## Across distributions

Git behaves identically everywhere; what differs is what your hosting provider
expects.

| | RHEL family | Debian family |
| --- | --- | --- |
| Package | `git` | `git` |
| Default branch name | `main`, once you set it | `main`, once you set it |
| Credential storage | `git-credential-libsecret` | `git-credential-libsecret` |
| SSH agent | `ssh-agent`, from lesson 43 | The same |

**Authentication is the practically variable part**, and it is not
distribution specific: every major host has dropped password authentication
for HTTPS. The two working options are an SSH key (the same key material from
lesson 43, with `ssh-agent` holding it) or a personal access token stored by a
credential helper. `git config --global credential.helper libsecret` stops it
asking every time.

## Prove it

```
# The shape of things, not just a list
git log --oneline --graph --all

# What is on the remote that I do not have
git fetch
git log --oneline HEAD..origin/main

# What have I got that the remote does not
git log --oneline origin/main..HEAD

# Am I mid-merge right now
git status

# Did any conflict markers survive
git diff --check
```

**`git log --oneline HEAD..origin/main` and its reverse are the two questions**
worth asking before any push or merge. The first is what you are about to receive,
the second is what you are about to send.

## What trips people up

### 1. Conflict markers committed into a file

Git does not check that you removed them; they are legal text. `git diff
--check` finds them, and a syntax check on the file (`nginx -t`, `visudo -c`)
catches everything including them.

### 2. `pull` when you meant `fetch`

`pull` merges immediately, so it can drop a conflict into your working tree at a
moment you did not choose. `fetch`, look, then merge deliberately.

### 3. `push --force` on a shared branch

It replaces the remote with your copy and discards anything else that was there.
`--force-with-lease` refuses when the remote has moved, turning a silent loss into
an error.

### 4. Rebasing published commits

Every replayed commit gets a new hash, so your history and theirs disagree and the
same change comes back twice at the next merge.

Rebase your own unpushed work; merge everything else.

### 5. `reset` on something already pushed

Rewrites what the history *is*. Use `revert`, which adds a commit undoing it
and leaves the record intact, which is also the answer an auditor needs.

### 6. `git stash` without `-u`

Untracked files are left behind and follow you to the next branch, where they look
like they belong.

## Work it through

You are on a branch fixing a monitoring script. An urgent request arrives: a
certificate expires in an hour and the renewal needs deploying from `main`. Your
current work is half finished and does not run.

Reason it out before reading on.

**Do not stash.** It is the obvious answer and the weaker one. A stash has no
message, is invisible in `git log`, and is easy to forget, and this
interruption will last longer than you think.

**Commit it on the branch instead:**

```
git add -A
git commit -m "WIP: half-finished retry logic, does not run"
git switch main
```

The work is now safe, named, and visible. `WIP` in the message says it is not
finished, and because the branch is not pushed you can tidy it later with
`git rebase -i` or `git commit --amend`.

**Then the urgent work, on its own branch:**

```
git fetch
git switch -c cert-renewal origin/main
```

Branching from `origin/main` rather than your local `main` matters, your local
copy may be days behind, and a certificate fix built on stale code is a second
incident.

After it is deployed and merged, go back:

```
git switch fix-monitoring
git rebase main            # replay onto the now-updated main
```

Rebase is safe here because nothing on this branch was ever pushed. If it had been,
`git merge main` is the equivalent that does not rewrite anything.

**And the failure mode worth naming:** doing the urgent fix on the monitoring branch
because switching seemed like a hassle. The renewal then cannot be merged without
also merging the half-finished script, and the choice at 3am is between shipping
broken code and unpicking two changes under time pressure.

The point worth extracting: **branches are cheap and interruptions are certain.** A
branch costs 41 bytes and one command, and its real value is that it makes the
answer to "can I ship this without that" always yes.

## Try it

Optional, and entirely local, nothing here needs a remote.

1. In a scratch repository, commit a file with three lines.
2. `git switch -c feature`, change line 2, commit.
3. `git switch main`, change line 2 differently, commit.
4. `git log --oneline --graph --all` and look at the split.
5. `git merge feature`. Read the conflict message and the exit status.
6. `cat` the file and identify all three markers.
7. `git merge --abort`, confirm the file is back, then merge again and resolve it
   properly.
8. `git log --oneline --graph` and find the merge commit's two parents.
9. Make three trivial commits, then `git rebase -i HEAD~3` and `fixup` two of them.

**Verification step.** You have it when you can look at `--graph` output and say
which commits are on which branch, and where they joined.

## Check yourself

<details class="qa">
<summary>Git stops a merge with <code>CONFLICT</code> and edits your file. What did it write, and which command tells Git you have resolved it?</summary>

**It wrote both versions into the file, wrapped in three markers:**

```
<<<<<<< HEAD
  listen 8080;
=======
  listen 443 ssl;
>>>>>>> add-tls
```

Everything between `<<<<<<< HEAD` and `=======` is your current branch's version;
everything between `=======` and `>>>>>>>` is the incoming branch's. Lines both
branches agree on are left outside the markers entirely, which shows you the scope
of the disagreement.

**`git add <file>` is how you declare it resolved**, and then `git commit`
completes the merge.

Git does not check your work. The markers are ordinary text, so `git add`
accepts a file that still contains them, which is how `<<<<<<< HEAD` ends up
in a deployed config. `git diff --check` finds them, and a syntax check on the
file itself is better.

`git merge --abort` undoes the whole thing and returns to the pre-merge state,
which is the command to know before you need it.

The near-miss worth naming: `Auto-merging <file>` immediately before the
conflict is not an error. Git merges line by line, so most changes to the same
file combine fine, only the overlapping lines conflict.

</details>

<details class="qa">
<summary>What is the difference between <code>git fetch</code> and <code>git pull</code>, and why does it matter which you run?</summary>

**`fetch` downloads and changes nothing locally. `pull` is `fetch` followed
immediately by a merge into your current branch.**

So `fetch` is always safe. It updates `origin/main`, your record of what the
remote has, and leaves your branch and working tree untouched. You can then
look before acting:

```
git fetch
git log --oneline HEAD..origin/main
git merge origin/main
```

**`pull` merges without asking**, which means it can drop a conflict into your
working tree at a moment you did not choose, while you are mid-edit, or in a
deploy script that then copies a half-merged file to a server.

The two-dot ranges are the useful part of doing it in stages.
`HEAD..origin/main` is what they have that you do not; `origin/main..HEAD` is
what you have that they do not. Those are the two questions before any push or
merge.

**`git pull --rebase`** is the third option, replaying your local commits on top of
theirs instead of making a merge commit. It produces a cleaner history for the
common case of "I committed locally while somebody else pushed", and it carries the
same rule as any rebase: fine for your own unpushed commits.

</details>

<details class="qa">
<summary>You need to undo a commit that is already on the shared branch. Why is <code>git reset</code> wrong here, and what does <code>git revert</code> do instead?</summary>

`reset` moves the branch pointer, which changes what the history is. Your copy
no longer contains the commit; everybody else's still does. Their next push
either fails, or, if somebody resolves it by forcing, restores the commit you
removed. Either way, two people now disagree about what happened.

`git revert` adds a new commit that applies the inverse change. The original
commit stays in history, the undo is a visible event, and anybody who pulls
just receives one more commit. Nothing anybody already has becomes invalid.

```
git revert 0fa0412
git revert --no-commit HEAD~3..HEAD    # three commits undone in one
```

The rule is about publication, not preference: if the commit is only in your
clone, `reset` is fine and tidier. Once it has been pushed and anybody may
have pulled it, `revert` is the only safe option.

On infrastructure code there is a second argument. A revert records that a
change was made and then withdrawn, with both commits and both messages. A
reset records that it never happened. When somebody asks why production
changed at 14:00 and changed back at 14:20, only the revert can answer.

</details>

<details class="qa">
<summary>Why does rebasing a pushed branch cause problems, given the resulting code is identical?</summary>

Because rebase creates new commits, and a commit's identity is its hash.

Replaying a commit onto a different base changes its parent, and a commit's
hash is computed over its contents *and* its parent's hash, so the new commit
is a different object even though the diff is the same.

If somebody else has the old commits, their history now contains objects yours does
not, and yours contains objects theirs does not. The next merge brings both sets
back together and **the same change appears twice**, sometimes as a conflict against
itself. Untangling that is worse than whatever the rebase was tidying.

**The rule: rebase only commits nobody else has.** In practice that means your own
feature branch before you push it, or after pushing to a branch only you use.

Where it genuinely pays is `git rebase -i` for cleaning up before sharing,
collapsing "fix typo", "fix typo again", and "actually fix it" into the one
commit that should have existed, using `fixup`.

And it is recoverable if it goes wrong. `git rebase --abort` returns to the
start, and after a completed bad rebase the reflog still holds the original
commits.

Many teams settle on rebasing their own branches and merging into the shared one,
which gets a readable history without ever rewriting anything shared.

</details>

<details class="qa">
<summary>An urgent fix arrives while your branch is half finished and does not run. What do you do, and why is <code>git stash</code> the weaker answer?</summary>

**Commit the unfinished work on its branch with a message saying so**, then branch
for the urgent fix:

```
git add -A
git commit -m "WIP: half-finished retry logic, does not run"
git switch main
git fetch
git switch -c cert-renewal origin/main
```

**`git stash` is weaker for three reasons.** It has no useful message unless you
remember `git stash push -m`; it does not appear in `git log`, so it is invisible
to any review of what you were doing; and a stash from three weeks ago is a mystery
nobody wants to unpack. Interruptions last longer than expected, and a stash is
optimised for minutes.

A commit on a branch is named, visible, and safe, and because the branch is
not pushed, you can tidy it later with `git rebase -i` or `git commit
--amend`. Nothing is lost by committing early.

**The detail worth noticing is `git switch -c cert-renewal origin/main`.** Branching
from `origin/main` rather than your local `main`, after a `fetch`, means the urgent
fix is built on what is actually deployed. A local `main` that is days behind
produces a fix that quietly reverts somebody else's work.

**And the failure this avoids:** doing the urgent fix on the branch you were already
on. The renewal then cannot be merged without also merging the half-finished
script.

</details>

## References

- [git-branch(1)](https://git-scm.com/docs/git-branch) - Git project. Accessed 2026-08-08.
- [git-merge(1)](https://git-scm.com/docs/git-merge) - Git project. Accessed 2026-08-08.
- [git-rebase(1)](https://git-scm.com/docs/git-rebase) - Git project. Accessed 2026-08-08.
- [git-revert(1)](https://git-scm.com/docs/git-revert) - Git project. Accessed 2026-08-08.
- [git-fetch(1)](https://git-scm.com/docs/git-fetch) - Git project. Accessed 2026-08-08.
- [git-stash(1)](https://git-scm.com/docs/git-stash) - Git project. Accessed 2026-08-08.

Every block above with a distribution and architecture header was captured by
running the command on a Debian 13 (trixie) container, in a repository built from
nothing with two branches that deliberately change the same line. The conflict is a
real one. Blocks without a header are illustrative.
