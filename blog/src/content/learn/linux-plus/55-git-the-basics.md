---
title: "You changed a config, it broke, and the old version is gone"
description: "Version control for people who administer systems rather than write software. The three places a file can be, what a commit actually contains, and the command that gets your work back after you thought you destroyed it."
track: "linux-plus"
level: "intro"
order: 560
objectives:
  - "Explain the three states a file moves through and where staging fits"
  - "Make, inspect, and read a commit"
  - "Use .gitignore and say why some files must never be committed"
  - "Write a commit message somebody can use six months later"
  - "Recover a commit after a reset appears to have destroyed it"
prerequisites: ["reading-and-editing-files"]
tags: ["linux", "linux-plus", "git", "version-control", "automation"]
updated: 2026-08-08
draft: false
examObjectives:
  - exam: "xk0-006"
    domain: "4.0"
    objective: "4.4"
sources:
  - title: "git(1)"
    url: "https://git-scm.com/docs/git"
    publisher: "Git project"
    accessed: 2026-08-08
    tier: 1
  - title: "gitignore(5)"
    url: "https://git-scm.com/docs/gitignore"
    publisher: "Git project"
    accessed: 2026-08-08
    tier: 1
  - title: "git-reflog(1)"
    url: "https://git-scm.com/docs/git-reflog"
    publisher: "Git project"
    accessed: 2026-08-08
    tier: 1
  - title: "git-reset(1)"
    url: "https://git-scm.com/docs/git-reset"
    publisher: "Git project"
    accessed: 2026-08-08
    tier: 1
  - title: "Git Internals: Git Objects"
    url: "https://git-scm.com/book/en/v2/Git-Internals-Git-Objects"
    publisher: "Git project"
    accessed: 2026-08-08
    tier: 1
symptoms:
  - symptom: "git reset --hard threw away a commit"
    anchor: "getting-it-back"
  - symptom: "Committed a file that should not be in version control"
    anchor: "gitignore-and-the-files-that-must-never-go-in"
---

> **Before you read.** You edited `nginx.conf`, restarted the service, and it
> failed to start. You want the previous version back.
>
> There is no previous version. You edited the file in place, and the copy you
> made first, `nginx.conf.bak`, was from two changes ago, or possibly three.
> You are not sure which, because it has no date on it that means anything.
>
> **What would you need to have done differently, and how much work is it?**

Almost none, which is the point of this lesson. Version control is not a
programmer's tool that administrators can borrow. It is a way of keeping every
version of a file along with who changed it, when, and **why**, and the last
one is the part that `nginx.conf.bak` was never going to give you.

Git is the one everybody uses, and about eight commands cover everything in this
lesson. The rest of Git exists for collaboration, which is the next one.

### Some words you will need

<dl class="terms">
<dt>repository</dt>
<dd>A directory Git is tracking, plus the hidden <code>.git</code> holding its history.</dd>
<dt>commit</dt>
<dd>A snapshot of the whole tree at one moment, with an author, a time, and a message.</dd>
<dt>staging area</dt>
<dd>Where you assemble the next commit. Also called the index.</dd>
<dt>working tree</dt>
<dd>The files as they exist on disk right now.</dd>
<dt>HEAD</dt>
<dd>The commit you are currently on.</dd>
<dt>hash</dt>
<dd>The 40-character identifier of a commit. Usually abbreviated to seven.</dd>
</dl>

## What breaks without this

**You cannot answer "what changed".** A service that worked on Tuesday and fails on
Thursday is a question about the difference, and without history there is no
difference to look at.

**You cannot answer "why".** `nginx.conf.bak` records that somebody changed
something. It does not record that the change was for the certificate renewal, or
that it was reverted once already because it broke the health check.

**Rollback is manual and uncertain.** Restoring from backup gets the whole machine
to a point in time, which is a much bigger operation than undoing one line.

**And the directory fills with `.bak`, `.old`, `.orig`, and `.conf.20260803`**,
which is version control implemented badly by hand.

## Three places a file can be

This is the model, and it is the only genuinely unfamiliar idea in the lesson.

```
working tree  ->  staging area  ->  repository
   (on disk)         (index)          (commits)
        git add            git commit
```

**The staging area is what makes Git feel strange at first**, and it exists for one
reason: **a commit should be one logical change, and your working tree usually
contains two.** Staging lets you commit the certificate change now and leave the
half-finished logging tweak for later, from the same set of edited files.

`git status` shows where everything currently is.

<details class="predict">
<summary>The repository has a `.gitignore` containing `*.log`. The command creates `debug.log` and then runs `git status`. Does the new file appear?</summary>

```bash
# Debian 13 (trixie), x86_64
$ cd /root/site; touch debug.log; git status
On branch main
Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	modified:   nginx.conf

no changes added to commit (use "git add" and/or "git commit -a")
```

</details>

**No mention of it at all.** `.gitignore` does not merely stop the file being
committed; it stops Git talking about it. That is what makes `git status`
usable, without it, a directory containing logs, caches, and temporary files
would bury the one line that matters.

**Read what `git status` is actually telling you.** It names the branch,
groups files by which of the three places they are in, and, usefully for a
beginner, prints the command that moves them. `git restore` to discard, `git
add` to stage. Those hints are the fastest way to learn the model.

## What actually changed

`git status` says a file is modified. `git diff` says how.

```bash
# Debian 13 (trixie), x86_64
$ cd /root/site; git diff
diff --git a/nginx.conf b/nginx.conf
index e86be34..bf8e348 100644
--- a/nginx.conf
+++ b/nginx.conf
@@ -1,3 +1,3 @@
 server {
-  listen 80;
+  listen 443 ssl;
 }
```

**Read the last four lines and ignore the rest at first.** A leading `-` is a line
removed, `+` is a line added, and a space is context shown so you can see where you
are. One line changed, from `listen 80` to `listen 443 ssl`.

`@@ -1,3 +1,3 @@` is the hunk header, meaning "three lines starting at line 1,
before and after". On a large file there are several hunks and the numbers are
how you find each one.

The one thing to remember about `git diff` is which comparison it makes:

| Command | Compares |
| --- | --- |
| `git diff` | Working tree against **staging** |
| `git diff --staged` | Staging against the **last commit** |
| `git diff HEAD` | Working tree against the last commit |

So `git diff` showing nothing after you have staged everything is not a bug.
It is answering the question "what have I changed since staging", and the
answer is nothing. `git diff --staged` is the one to run before committing,
because it shows exactly what is about to go in.

## Staging and committing

```bash
# Debian 13 (trixie), x86_64
$ cd /root/site; git add nginx.conf; git status --short; echo "--- commit it ---"; git commit -q -m "Switch nginx to TLS on 443"; git log --oneline
M  nginx.conf
--- commit it ---
ac4d1c4 Switch nginx to TLS on 443
8de8496 Add the initial nginx config
```

**`git status --short` is the form worth using daily.** Two columns: the left is the
staging area, the right is the working tree. `M ` with the M on the **left** means
staged; ` M` with it on the right means modified and not staged; `MM` means both,
which happens when you stage and then edit again. `??` is untracked.

**`git log --oneline` gives the seven-character hash and the subject line**, and
that is the view you want most of the time. The full `git log` adds author, date,
and the full message.

Those seven characters are the start of a 40-character SHA-1 of the commit's
contents, and seven is enough to be unambiguous in any repository you are likely to
run by hand.

## Writing a message somebody can use

This is the part with the most value per second spent, and it is almost entirely
about answering **why** rather than what.

The diff already records what changed. A message saying "updated nginx.conf" adds
nothing at all.

| Instead of | Write |
| --- | --- |
| `updated config` | `Switch nginx to TLS on 443` |
| `fix` | `Stop the health check following redirects, which made it always pass` |
| `changes` | `Raise worker_connections to 4096 after the Black Friday timeouts` |
| `wip` | Do not commit work in progress to a shared branch |

**The convention is a short subject line, then a blank line, then detail:**

```
Raise nginx worker_connections to 4096

The 512 default was reached during the sale on 2026-08-03 and new
connections were refused for about eleven minutes. 4096 is what the
current memory budget supports; see the capacity note in ticket OPS-4412.

Reverting this is safe. It costs about 40 MB of RAM.
```

Everything after the blank line is for the person doing the archaeology, which
is usually you in eight months. The three things worth including are why the
change was made, what evidence supported it, and whether reverting it is safe,
because that last one is what somebody needs at 3am.

Fifty characters for the subject is the convention, and it is not arbitrary:
`git log --oneline` and most tooling truncate around there.

## `.gitignore`, and the files that must never go in

`.gitignore` is a list of patterns, one per line, and it is itself committed so that
everybody working on the repository gets the same rules.

```
*.log
*.tmp
*.swp
__pycache__/
.env
secrets.yml
node_modules/
```

**The security case is the important one.** A private key, a password, or an
API token committed to a repository is not fixed by deleting it in a later
commit, the old commit still contains it, and anybody who has cloned the
repository has a copy. Removing it properly means rewriting history and
rotating the secret, and the rotation is the part that actually matters.

Which is why the rule is: secrets never enter version control. Configuration
that *refers* to a secret is fine; the secret itself belongs in a secrets
manager, a file outside the repository, or an environment variable supplied at
deploy time.

`.gitignore` only affects untracked files. A file already being tracked keeps
being tracked no matter what you add to the ignore list, which surprises
people who add `*.log` and find `app.log` still showing up. `git rm --cached
app.log` stops tracking it while leaving it on disk.

<details class="deeper">
<summary>If you already administer Linux: what a commit actually is, and why that makes history tamper-evident</summary>

Git is not storing diffs. Each commit is a complete snapshot, and the reason
that is not wasteful is worth understanding, it explains the performance, the
hashes, and the guarantees.

Look at what a commit contains:

```bash
# Debian 13 (trixie), x86_64
$ cd /root/site; git status --short; echo "--- what git actually stores ---"; git cat-file -t HEAD; git cat-file -p HEAD
 M nginx.conf
--- what git actually stores ---
commit
tree 426c87713fc2cbac48317ffe57de3c928f1cd94d
author Sam Reeve <sam@example.com> 1786233572 +0000
committer Sam Reeve <sam@example.com> 1786233572 +0000

Add the initial nginx config
```

**That is the entire commit object.** A pointer to a `tree`, an author, a
committer, and a message. No diff anywhere. The tree is a directory listing naming
files and the hash of each one's contents; a subdirectory is another tree.

Four object types, and every one is content-addressed:

| Object | Holds |
| --- | --- |
| `blob` | A file's contents. No name, no permissions. |
| `tree` | A directory: names, modes, and the hashes they point to |
| `commit` | One tree, the parent commit or commits, author, message |
| `tag` | An annotated tag pointing at a commit |

Content-addressed means the hash is computed from the contents, so two
identical files anywhere in history are one blob stored once. That is why a
repository with a thousand commits touching one file in a large tree is small:
each commit's tree reuses the unchanged blobs and only the changed ones are
new.

And it is why history is tamper-evident. A commit's hash covers its tree and
its **parent's hash**. Change anything in an old commit and its hash changes,
which changes its child's hash, and so on to the tip, so every subsequent
commit visibly changes. You cannot quietly alter a commit from last March; you
can only rewrite everything after it, which is obvious to anyone who has the
old history.

That property is why Git is acceptable as an audit trail for infrastructure code,
and it is the technical foundation under the GitOps idea in lesson 60: the
repository can be the source of truth precisely because its history cannot be
edited without evidence.

**`git cat-file` is the tool for poking at this**, and `git log --format=raw` shows
commits in the same form. Neither is needed day to day, and both make the model
concrete in a way no diagram does.

**The practical consequence:** `git gc` packs loose objects and
delta-compresses similar ones, so the on-disk format *does* eventually store
deltas, as an optimisation, invisibly, and never as the logical model.

</details>

## Making a change and reading it back

The full record of a commit, and who last touched each line:

```bash
# Debian 13 (trixie), x86_64
$ cd /root/site; git add nginx.conf; git commit -q -m "Switch nginx to TLS on 443"; echo "--- what changed, and by whom ---"; git log --stat -1; echo "--- who last touched each line ---"; git blame nginx.conf
--- what changed, and by whom ---
commit 8d4440b9f26216e6f9ac8c63cc7e031d55ac2f95
Author: Sam Reeve <sam@example.com>
Date:   Sat Aug 8 23:59:50 2026 +0000

    Switch nginx to TLS on 443

 nginx.conf | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
--- who last touched each line ---
^8de8496 (Sam Reeve 2026-08-08 23:59:32 +0000 1) server {
8d4440b9 (Sam Reeve 2026-08-08 23:59:50 +0000 2)   listen 443 ssl;
^8de8496 (Sam Reeve 2026-08-08 23:59:32 +0000 3) }
```

**`git blame` is the command that changes how you work.** Every line carries
the commit that last changed it, the author, and the date. So the question
"why is this setting 4096" becomes `git blame nginx.conf`, then `git show
<hash>` to read the message, which is exactly the reasoning that message was
written for.

**The `^` prefix means the line is from the repository's first commit**, unchanged
since.

`git log --stat` adds the file-level summary (one file, one insertion, one
deletion) which is a fast way to see the shape of a change before reading the
diff.

## Getting it back

The single most useful thing to know about Git, and the reason to be less afraid of
it than people are.

<details class="predict">
<summary>`git reset --hard HEAD~1` moves the branch back one commit and discards the working tree. The commit is gone from `git log`. Is it gone from the repository?</summary>

```bash
# Debian 13 (trixie), x86_64
$ cd /root/site; git add nginx.conf; git commit -q -m "Switch to TLS"; echo "--- now throw the commit away ---"; git reset --hard HEAD~1 | cat; git log --oneline; echo "--- but git remembers ---"; git reflog | head -4
--- now throw the commit away ---
HEAD is now at 8de8496 Add the initial nginx config
8de8496 Add the initial nginx config
--- but git remembers ---
8de8496 HEAD@{0}: reset: moving to HEAD~1
f1712f7 HEAD@{1}: commit: Switch to TLS
8de8496 HEAD@{2}: commit (initial): Add the initial nginx config
```

</details>

**`git log` shows one commit and the reflog shows the discarded one, `f1712f7`,
still there.** Getting it back is one command:

```
git reset --hard f1712f7
```

The reflog records every movement of `HEAD`, including the ones that erased
things: commits, resets, checkouts, merges, rebases. It is local to your
clone, it is not pushed anywhere, and it keeps entries for 90 days by default.

What that means in practice is that a committed change is very hard to lose.
The dangerous operations are the ones that touch things you never committed:

| Operation | Recoverable |
| --- | --- |
| `git reset --hard` after committing | **Yes**, via reflog |
| A bad rebase or merge | **Yes**, via reflog |
| Deleting a branch | **Yes**, if it was committed |
| `git reset --hard` with **uncommitted** changes | **No** |
| `git clean -fd` | **No** |
| Editing a file and not committing | **No** |

The pattern is clear enough to act on: commit early, and commit often. A
commit is cheap, local, and reversible; an uncommitted edit is the only thing
Git cannot protect. "I will commit when it is finished" is what puts work in
the one category that can be destroyed.

<details class="deeper">
<summary>If you already administer Linux: the three resets, and which one you actually want</summary>

`git reset` does three different jobs depending on a flag, and the difference is
which of the three places from the top of this lesson it touches.

| Command | Moves the branch | Staging | Working tree |
| --- | --- | --- | --- |
| `git reset --soft HEAD~1` | Yes | **Untouched** | Untouched |
| `git reset HEAD~1` (mixed, the default) | Yes | Reset | Untouched |
| `git reset --hard HEAD~1` | Yes | Reset | **Discarded** |

**`--soft` undoes the commit and keeps everything staged**, which is the one to
use when you committed too early or wrote a bad message and have not pushed.
Everything is exactly as it was a second before you typed `git commit`.

Mixed is the default and unstages as well, so the changes are still on disk
but no longer marked for the next commit. That is what you want when the
commit contained two unrelated things and you want to re-stage them
separately.

`--hard` is the only destructive one, and it is the only one that can lose
work that was never committed.

For a bad message specifically, none of these is the tool. `git commit
--amend` replaces the last commit in place:

```
git commit --amend -m "Switch nginx to TLS on 443, per the audit finding"
git commit --amend --no-edit          # add staged changes to the last commit
```

Everything here rewrites history, so it applies to commits you have not
pushed. Once a commit is shared, rewriting it means everyone else's history
disagrees with yours. The tool for undoing a *published* commit is `git
revert`, which adds a new commit reversing it, visible, safe, and the right
answer on any shared branch.

And the one that is not a reset at all: `git restore` is the modern command
for discarding working-tree changes to a file, and `git restore --staged` for
unstaging one. They were split out of `git checkout` precisely because `git
checkout` doing both branch-switching and file-discarding was the source of so
many accidents.

```
git restore nginx.conf              # discard my edits to this file
git restore --staged nginx.conf     # unstage it, keep the edits
```

`git status` prints both of these as hints, which is the fastest way to remember
which is which.

</details>

## Setting it up

Three commands, once per machine:

```
git config --global user.name "Sam Reeve"
git config --global user.email "sam@example.com"
git config --global init.defaultBranch main
```

**The name and email are recorded in every commit you make** and cannot be changed
afterwards without rewriting history. Setting them before your first commit saves a
tedious cleanup.

Then, in any directory you want to track:

```
git init
git add .
git commit -m "Initial import of the nginx configuration"
```

**`/etc` under version control is a genuinely good idea** and there is a tool
for it: `etckeeper` hooks into the package manager and commits automatically
before and after every install, so `git log` in `/etc` tells you which update
changed which file. On a machine you administer by hand, that alone is worth
the setup.

<details class="deeper">
<summary>If you already administer Linux: putting /etc under version control, and the two things that go wrong</summary>

Tracking `/etc` with Git is one of the higher-value hours an administrator can
spend, and there is a tool that does it properly rather than a bare `git init`.

**`etckeeper` hooks into the package manager.** It commits automatically before
and after every `apt` or `dnf` transaction, so `git log` in `/etc` tells you which
update changed which file, and `git show` gives the diff. That answers "what did
last night's patching actually change" in one command, which is otherwise a
genuinely hard question.

```
apt install etckeeper        # or dnf install etckeeper
etckeeper init
etckeeper commit "Initial import"
```

It also commits daily via a timer, so changes made by hand between updates are
captured too.

**The first thing that goes wrong is permissions.** `/etc` contains `shadow`,
`gshadow`, and private keys, all mode 600 or 640 and owned by root. Git
records the executable bit and nothing else (it does not preserve ownership or
the full mode) so a naive `git checkout` of an old version can restore
`/etc/shadow` world-readable. `etckeeper` handles this by storing the metadata
in a `.etckeeper` file it commits alongside, and restoring it on checkout. A
hand-rolled `git init` in `/etc` does not, which is why it is worth using the
tool.

The second is that the repository itself becomes sensitive. `/etc/.git`
contains every version of `shadow` your machine has ever had. It must be mode
700, it must never be pushed to a shared remote, and it is now something a
backup has to protect properly. If you do want it off the machine, push to a
private repository over SSH and treat it as credential material.

Two habits that make it useful rather than merely present:

Commit *before* you change something, with a message saying what you are about to
do and why. The automatic commits record what happened; only you can record the
intent, and the intent is the thing worth having in six months.

And check `git status` in `/etc` when a machine behaves oddly. A file modified
by something you did not run (a vendor script, a misbehaving package, a
colleague) shows up immediately, and that is a question that is otherwise very
hard to ask.

**The same idea scales up.** Once `/etc` is in Git, the natural next question is
why the machine is being configured by hand at all, which is the configuration
management lesson later in this block. `etckeeper` on a hand-managed machine and
Ansible on a fleet are answers to the same problem at different sizes.

</details>

## Across distributions

Git is the same program everywhere. What differs is the packaging.

| | RHEL family | Debian family |
| --- | --- | --- |
| Package | `git` | `git` |
| `/etc` tracking | `etckeeper` | `etckeeper` |
| Default branch name | `main`, if you set it | `main`, if you set it |
| Credential helper | `git-credential-libsecret` | `git-credential-libsecret` |

**The default branch name is worth setting explicitly.** Git still defaults to
`master` and prints a hint about it on every `git init` until you choose;
`init.defaultBranch main` matches what every hosting provider now uses.

## Prove it

```
# Where is everything
git status --short

# What is about to be committed
git diff --staged

# What happened here
git log --oneline -10
git log --stat -3

# Why is this line the way it is
git blame path/to/file

# And the one that gets you out of trouble
git reflog
```

**`git diff --staged` before every commit** is the habit worth building. It is the
last chance to notice that a debug line, a password, or an unrelated file is about
to go in.

## What trips people up

### 1. `git add` on everything, every time

`git add .` stages whatever happens to be in the directory, including files you did
not mean to commit. `git add -p` walks through the changes hunk by hunk and asks.

At minimum, `git diff --staged` before committing.

### 2. Committing a secret

Deleting it in a later commit does not remove it from history, and anybody who has
cloned has it. Rewriting history is possible; **rotating the credential is the part
that matters**, and it is not optional.

`.gitignore` the file, and keep secrets outside the repository entirely.

### 3. `.gitignore` not ignoring a file

It only applies to **untracked** files. A file already tracked stays tracked.

`git rm --cached app.log` stops tracking it while leaving it on disk.

### 4. `git diff` showing nothing after staging

It compares the working tree to **staging**, and you just made those identical.
`git diff --staged` is the one you wanted.

### 5. Messages that say what the diff already says

"updated config" is noise. The message is for why, and for whether reverting is
safe.

### 6. Believing `reset --hard` destroyed the work

If it was committed, the reflog has it for 90 days. If it was never committed,
nothing has it.

## Work it through

A web server broke after a config change on Wednesday. The change was made by a
colleague who is on holiday. `/etc` is under `etckeeper`, so there is history.

Reason it out before reading on.

**First, what changed and when:**

```
cd /etc
git log --oneline --since='7 days ago' -- nginx/
```

That narrows a week of commits to the ones touching nginx. Suppose it shows one on
Wednesday afternoon.

**Second, what exactly:**

```
git show <hash>
```

The diff plus the message. If the message is good, the *why* is answered here and
you may not need anything else.

**Third, if the message is not good**, and on a machine where `etckeeper`
commits automatically, many messages are just "committing changes in /etc", so
this is likely:

```
git blame nginx/nginx.conf
git log --stat <hash>
```

`blame` gives per-line attribution and `--stat` shows what else was in the same
commit, which frequently reveals that the change was part of a package update rather
than a deliberate edit.

**Fourth, and this is the decision people rush:** do you revert?

```
git revert <hash>          # a new commit undoing that one. Safe, keeps history.
git checkout <hash>~1 -- nginx/nginx.conf   # restore just that file
```

`git revert` rather than `reset`, because the history is shared and somebody
else may have it. `revert` adds a commit that undoes the change, which is
transparent; `reset` rewrites, which is not.

And the thing to do before any of that: check whether the config is even the
cause. `nginx -t` validates it in one command, and if it passes, the change
may be correct and the fault elsewhere, a certificate that expired the same
day, a port now blocked by a firewall change. History tells you what changed;
it does not tell you what broke.

The point worth extracting: **the value of the history was almost entirely in
answering "what changed on Wednesday" in one command.** Everything after that is
ordinary troubleshooting. Without it, the same question is a conversation with
somebody who is on holiday.

## Try it

Optional, and entirely local, nothing here touches a network.

1. `mkdir /tmp/demo && cd /tmp/demo && git init`.
2. `git config user.name "You"` and `git config user.email "you@example.com"`.
3. Create a file, `git status`, `git add`, `git status --short`, `git commit -m`.
4. Edit it. Run `git diff`, then `git add`, then `git diff` again. Note it is
   empty, then run `git diff --staged`.
5. Commit, then `git log --oneline` and `git blame` the file.
6. `echo '*.log' > .gitignore`, create `x.log`, and run `git status`.
7. `git reset --hard HEAD~1`, confirm with `git log`, then `git reflog` and get it
   back.
8. `git cat-file -p HEAD` and find the tree hash.

**Verification step.** You have it when you can destroy a commit with
`reset --hard` and recover it without looking anything up.

## Check yourself

<details class="qa">
<summary>What is the staging area for, given you could commit the working tree directly?</summary>

**It lets one commit be one logical change, when your working tree contains two.**

That situation is the normal one: you set out to fix the TLS configuration, noticed
a logging setting while you were there, and now three files are modified for two
unrelated reasons. Committing everything makes a single commit that cannot be
reverted without undoing both, and whose message has to describe both.

Staging lets you pick:

```
git add nginx/nginx.conf
git commit -m "Switch nginx to TLS on 443"
git add rsyslog.conf
git commit -m "Send auth logs to the central collector"
```

Two commits, each revertible on its own, each with a message that is about one
thing.

**`git add -p` is where this becomes genuinely useful**, because it goes
further than whole files, it walks the change hunk by hunk and asks about
each, so two unrelated edits in the *same file* can go in separate commits.

**The other thing staging buys you is a review step.** `git diff --staged` shows
exactly what is about to be committed, which is the last chance to notice a debug
line or a credential.

`git commit -a` skips staging for tracked files, and is fine when the working tree
genuinely is one change. It does not add untracked files, which surprises people.

</details>

<details class="qa">
<summary>You ran `git reset --hard HEAD~1` and the commit is gone from `git log`. Is the work lost, and what is the general rule?</summary>

**Not if it was committed.** `git reflog` records every movement of `HEAD`,
including the reset itself, and the discarded commit is still in the object
database:

```
git reflog
git reset --hard f1712f7
```

The reflog keeps entries for 90 days by default, is local to your clone, and is
never pushed.

**The general rule is that Git protects committed work and cannot protect anything
else.** The dividing line is exactly that:

**Recoverable:** a `reset --hard` after committing, a bad rebase, a bad merge,
a deleted branch, anything where the objects still exist and only a reference
moved.

**Not recoverable:** `reset --hard` with **uncommitted** changes in the working
tree, `git clean -fd`, and any edit you never committed. Those were never written to
the object database, so there is nothing to find.

Which is the argument for committing early and often. A commit is local,
cheap, and reversible, and it moves your work from the category Git cannot
protect into the one where it is very hard to lose. Waiting until something is
"finished" before committing keeps it in the dangerous category for as long as
possible.

Tidying up a messy series of commits afterwards is easy; recovering an uncommitted
edit is impossible.

</details>

<details class="qa">
<summary>You accidentally committed a file containing an API token. Deleting it in the next commit is not enough. Why, and what do you actually do?</summary>

**Because the old commit still contains it.** History is a chain of snapshots, so
the commit where the token was added is unchanged by anything you do afterwards.
`git show <that hash>` prints it, and anybody who has cloned or fetched has the
whole chain.

The step that actually matters is rotating the credential. Assume it is
compromised the moment it was committed, and certainly if it was pushed
anywhere. Nothing you do to the repository changes that, and doing the
repository work while skipping the rotation is the common and dangerous
mistake.

Then, if you must clean the history: `git filter-repo` is the current tool for
removing a file from every commit. It rewrites every hash from the offending
commit onward, which means everyone with a clone has to discard and re-clone.
On a shared repository that is a coordinated operation, not a quick fix.

And then prevent it:

- `.gitignore` the file
- Keep secrets outside the repository entirely, a secrets manager, or a file
  supplied at deploy time
- Commit a `.env.example` with the keys and no values, so the structure is
  documented and the secret is not
- A pre-commit hook or a scanner such as `gitleaks` in CI

The related habit is `git diff --staged` before every commit, which is the
point at which a credential is still trivial to remove.

</details>

<details class="qa">
<summary>`git diff` shows nothing, but you know you changed the file. What is going on?</summary>

You have already staged the change, and `git diff` compares the working tree
against **staging**, not against the last commit. Those are now identical, so
there is nothing to report.

The three forms answer three different questions:

| Command | Compares | Answers |
| --- | --- | --- |
| `git diff` | Working tree to staging | What have I changed since staging |
| `git diff --staged` | Staging to last commit | **What am I about to commit** |
| `git diff HEAD` | Working tree to last commit | Everything I have changed |

**`git diff --staged` is the one to build a habit around**, because it is the review
step before committing.

`git status --short` is the fast way to see the same thing, and its two
columns are exactly this distinction: the left column is the staging area, the
right is the working tree. `M ` is staged, ` M` is unstaged, `MM` is both
(staged, then edited again) which is a state that catches people because `git
commit` will record the first version and not the second.

</details>

<details class="qa">
<summary>Why is "updated nginx.conf" a bad commit message, and what belongs in a good one?</summary>

Because the diff already says that. Git records exactly which lines changed in
which file; a message repeating it adds nothing, and the one thing Git
*cannot* recover is why anybody did it.

A good message answers three things:

**Why the change was made.** "Switch nginx to TLS on 443" is a start; "after the
audit finding about plaintext admin traffic" is better.

What evidence supported it. A ticket number, an incident date, a measurement.
"The 512 default was reached during the sale on 2026-08-03 and connections
were refused for eleven minutes" is a fact somebody can check.

Whether reverting is safe. This is the one people leave out and the one
somebody wants at 3am. "Reverting this is safe, it costs about 40 MB of RAM"
turns a risky decision into an easy one.

The format is a short subject, a blank line, then the detail. Around fifty
characters for the subject, because `git log --oneline` and most tooling
truncate there.

The reason to care as an administrator specifically: the audience is you, in
eight months, running `git blame` on a setting you do not recognise. The
message is the only place the reasoning can live, because the config file
itself will have been edited again by then.

</details>

## References

- [git(1)](https://git-scm.com/docs/git) - Git project. Accessed 2026-08-08.
- [gitignore(5)](https://git-scm.com/docs/gitignore) - Git project. Accessed 2026-08-08.
- [git-reflog(1)](https://git-scm.com/docs/git-reflog) - Git project. Accessed 2026-08-08.
- [git-reset(1)](https://git-scm.com/docs/git-reset) - Git project. Accessed 2026-08-08.
- [Git Internals: Git Objects](https://git-scm.com/book/en/v2/Git-Internals-Git-Objects) - Git project. Accessed 2026-08-08.

Every block above with a distribution and architecture header was captured by
running the command on a Debian 13 (trixie) container, in a repository created
from nothing for the purpose. Commit hashes differ between blocks because each
one built the repository fresh, which is also a demonstration that a hash is
computed from contents and time rather than assigned in sequence. Blocks without
a header are illustrative.
