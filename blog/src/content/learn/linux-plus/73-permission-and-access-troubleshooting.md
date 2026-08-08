---
title: "Permission denied, and what it is really telling you"
description: "Why a world-readable file still refuses to open, how to read the whole path instead of the last component, and the four causes that produce the same three words."
track: "linux-plus"
level: "deep"
order: 740
objectives:
  - "Walk a full path to find which component actually denied access"
  - "Tell a directory traversal failure apart from a file permission failure"
  - "Read an ACL mask and explain why an effective permission is lower than the granted one"
  - "Choose the one command that discriminates between the four common causes"
prerequisites: ["linux-fundamentals-and-the-fhs"]
tags: ["linux", "linux-plus", "troubleshooting", "permissions", "acl"]
updated: 2026-08-07
draft: false
examObjectives:
  - exam: "xk0-006"
    domain: "5.0"
    objective: "5.4"
sources:
  - title: "path_resolution(7)"
    url: "https://man7.org/linux/man-pages/man7/path_resolution.7.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "namei(1)"
    url: "https://man7.org/linux/man-pages/man1/namei.1.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "acl(5)"
    url: "https://man7.org/linux/man-pages/man5/acl.5.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "getfacl(1)"
    url: "https://man7.org/linux/man-pages/man1/getfacl.1.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "setfacl(1)"
    url: "https://man7.org/linux/man-pages/man1/setfacl.1.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "lsattr(1)"
    url: "https://man7.org/linux/man-pages/man1/lsattr.1.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "getenforce(8)"
    url: "https://man7.org/linux/man-pages/man8/getenforce.8.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "id(1)"
    url: "https://man7.org/linux/man-pages/man1/id.1.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
symptoms:
  - symptom: "cat: /path/to/file: Permission denied, but ls -l shows the file as world-readable"
    anchor: "cause-1-a-directory-in-the-path-blocks-traversal"
  - symptom: "getfacl shows user:name:rw- with #effective:r--"
    anchor: "cause-2-an-acl-mask-is-cutting-the-granted-permission-down"
  - symptom: "ls -l shows a trailing plus sign on the permission string"
    anchor: "cause-2-an-acl-mask-is-cutting-the-granted-permission-down"
  - symptom: "Operation not permitted when writing as root"
    anchor: "cause-3-the-file-is-immutable"
  - symptom: "A group was added to a user but access still fails"
    anchor: "cause-4-the-group-membership-is-not-in-the-running-process"
---

> **Before you read.** A file is `-rw-r--r--`, owned by `root:root`. An
> unprivileged user runs `cat` against it and gets `Permission denied`. Nothing
> about the file has changed and no security module is enforcing anything.
> Where is the denial coming from?

`Permission denied` is three words covering at least four unrelated causes, and
the instinct it produces is the wrong one. Almost everyone runs `ls -l` on the
file, sees permissions that clearly allow the access, and concludes something
exotic is happening.

Nothing exotic is happening. `ls -l` on the file answers a question you did not
ask.

### Some words you will need

<dl class="terms">
<dt>path resolution</dt>
<dd>How the kernel turns a path into a file: one component at a time, left to right, checking each.</dd>
<dt>traversal</dt>
<dd>Execute permission on a <em>directory</em>. It means "may pass through", not "may run".</dd>
<dt>ACL</dt>
<dd>Access control list. Per-user and per-group permissions beyond the three sets in <code>ls -l</code>.</dd>
<dt>mask</dt>
<dd>A ceiling on every named ACL entry. It occupies the group position in <code>ls -l</code> once an ACL exists.</dd>
<dt>effective permission</dt>
<dd>What an ACL entry grants after the mask has been applied. Frequently less than what it says.</dd>
<dt>EACCES / EPERM</dt>
<dd>The two errno values behind "Permission denied" and "Operation not permitted". They mean different things.</dd>
<dt>supplementary groups</dt>
<dd>The group list attached to a process when it starts. Not re-read afterwards.</dd>
</dl>

## What breaks without this

The cost here is not that the problem is hard. It is that the wrong first move
sends you somewhere expensive.

Seeing permissive bits on the file and stopping there leads people to suspect
SELinux, then a mount option, then the application, then a bug. Each of those
takes real time to rule out. The actual cause is usually two directories up the
path and would have taken one command to find.

The second cost is the fix that makes it worse. `chmod 777` on the file changes
nothing when the denial came from a directory, so the next escalation is `chmod
-R 777` on the tree, and now you have a permissions problem *and* a security
finding.

## Start with the whole path, not the file

To open `/srv/data/reports/q3.csv`, the kernel resolves the path one component
at a time. Reaching `q3.csv` requires **execute** permission on `/`, `srv`,
`data`, and `reports` first. Execute on a directory means "may traverse", and
without it the kernel stops before it ever looks at the file's own permissions.

That is the whole trick: **the file's mode is the last thing checked, so it is
the last thing you should look at.**

`namei -l` resolves a path and prints the permissions of every component, which
turns a guess into a reading.

## The four causes

Ordered by how often they are the answer. The rightmost column is what tells
them apart in one command.

| Symptom | Likely cause | The discriminating command |
| --- | --- | --- |
| `ls -l` on the file looks permissive | A directory in the path denies traversal | `namei -l <path>` |
| `ls -l` shows a trailing `+` | An ACL, and probably its mask | `getfacl <path>` |
| Denial hits **root**, and reads `Operation not permitted` | The immutable attribute | `lsattr <path>` |
| User is in the right group but still denied | The group is not in the running process | `id <user>` against the process's own `id` |

If none of those four explain it, that is when SELinux becomes worth checking,
not before.

## Cause 1: a directory in the path blocks traversal

The reported failure:

```bash
# AlmaLinux 10.2, x86_64
$ runuser -u app -- cat /srv/data/reports/q3.csv
cat: /srv/data/reports/q3.csv: Permission denied
```

The instinctive check, which is the one that misleads:

```bash
# AlmaLinux 10.2, x86_64
$ ls -l /srv/data/reports/q3.csv
-rw-r--r--. 1 root root 18 Aug  7 19:42 /srv/data/reports/q3.csv
```

World-readable. Owned by root, but `other` has `r`. By that reading the user
should be able to open it, and this is exactly where people start suspecting the
wrong things.

Read the whole path instead:

<details class="predict">
<summary>Four directories and a file. Before you look: which line is the one that denied the read?</summary>

```bash
# AlmaLinux 10.2, x86_64
$ namei -l /srv/data/reports/q3.csv
f: /srv/data/reports/q3.csv
dr-xr-xr-x root root /
drwxr-xr-x root root srv
drwxr-xr-x root root data
drwxr-x--- root root reports
-rw-r--r-- root root q3.csv
```

</details>

There it is. `reports` is `drwxr-x---`: owner root, group root, and **nothing for
other**. The `app` user is neither, so it has no execute bit on that directory,
so it cannot traverse into it. The kernel denied the request at `reports` and
never evaluated `q3.csv` at all.

The file being world-readable is true and irrelevant.

The fix depends on intent. If `app` is supposed to have access, the correct move
is to give it group membership and set the directory's group appropriately, not
to open the directory to everyone:

```bash
chgrp appdata /srv/data/reports
chmod 750 /srv/data/reports
usermod -aG appdata app
```

Note what is not in that fix: no `chmod 777`, and no recursive change. One
directory, one group.

<details class="deeper">
<summary>If you already administer Linux: r and x on a directory are independent, and the combinations are all useful</summary>

A directory's read and execute bits do genuinely different jobs, and every one of
the four combinations means something you will meet.

| Mode | `ls` the directory | `cd` into it | Open a file whose name you know |
| --- | --- | --- | --- |
| `r-x` | Yes | Yes | Yes |
| `--x` | **No** | Yes | **Yes** |
| `r--` | Names only, no details | **No** | **No** |
| `---` | No | No | No |

**`--x` is the interesting one and it is a real technique.** You can traverse the
directory and open anything inside it *if you already know the name*, but you
cannot enumerate it. `/home` is often `755`, but a user's own directory at `701`
lets a web server reach `~/public_html` without being able to list what else is
there. It is how shared upload directories avoid leaking filenames.

**`r--` is the combination that surprises people.** `ls` appears to work and then
every entry shows as a question mark, because listing the *names* only needs read,
while getting each entry's metadata means a `stat` on it, which needs traversal:

```
$ ls -l /some/dir
ls: cannot access '/some/dir/file': Permission denied
total 0
-????????? ? ? ? ?            ? file
```

**That output is diagnostic.** A row of question marks with the name intact means
read without execute, precisely — not a corrupted filesystem, which is what it
looks like.

**Traversal is checked at every component, and only at the moment of resolution.**
A process that already holds an open file descriptor keeps its access even if you
remove traversal above it afterwards, because the check happened at `open` time.
That is why revoking access to a running service needs a restart, and why
`lsof` matters when you think you have locked something down.

</details>

## Cause 2: an ACL mask is cutting the granted permission down

This one is genuinely confusing the first time, because the ACL says one thing
and the effective permission is another.

The tell in `ls -l` is a single character:

```bash
# AlmaLinux 10.2, x86_64
$ ls -l /srv/app/settings.conf; runuser -u app -- sh -c "echo x >> /srv/app/settings.conf"
-rw-r--r--+ 1 root root 9 Aug  7 19:45 /srv/app/settings.conf
sh: line 1: /srv/app/settings.conf: Permission denied
```

That trailing `+` on `-rw-r--r--+` is the only thing in `ls -l` that tells you an
ACL exists. It is easy to read straight past.

The ACL on this file explicitly grants `app` read and write. The write above was
refused anyway.

<details class="predict">
<summary>A named ACL entry can grant more than the file's ordinary group bits allow, so something has to reconcile the two. Given `-rw-r--r--+`, what does `getfacl` report for `app`, and which line explains it?</summary>

```bash
# AlmaLinux 10.2, x86_64
$ getfacl /srv/app/settings.conf 2>/dev/null
# file: srv/app/settings.conf
# owner: root
# group: root
user::rw-
user:app:rw-	#effective:r--
group::r--
mask::r--
other::r--
```

</details>

`getfacl` does the work for you and annotates the line: `app` was granted `rw-`,
and the effective permission is `r--`. The `mask::r--` entry is why.

The mask is a ceiling. Every named user entry, every named group entry, and the
owning group entry are capped by it, so a grant above the mask is reduced rather
than applied. The mask exists because `chmod` has no way to express ACLs, and it
is what `chmod` writes to when a file has one: running `chmod 644` on a file with
ACLs sets the mask, silently shrinking every named grant.

That is the trap worth remembering. **`chmod` on an ACL'd file changes the mask,
not just the mode bits**, so a routine permission tidy-up can revoke access
nobody intended to touch.

The fix is to raise the mask, or to let `setfacl` recalculate it:

```bash
setfacl -m m::rw /srv/app/settings.conf
```

<details class="deeper">
<summary>If you already administer Linux: default ACLs, and why new files keep coming out wrong</summary>

The mask trap has a sibling that produces the opposite complaint: the ACL is
correct on the directory and every *new* file in it is still inaccessible.

**An ACL entry applies to the object it is on. Nothing inherits by default.** So
granting `setfacl -m u:backup:r-x /srv/data` covers the directory and none of the
files created in it afterwards. The application writes a new file, it gets the
creating process's ownership and umask, and the backup user is locked out again —
intermittently, on new data only, which is a miserable thing to reproduce.

**A default ACL is the fix**, set with `-d`, and it is a template rather than a
permission:

```
setfacl -m  d:u:backup:r-x /srv/data     # template for things created later
setfacl -Rm   u:backup:r-x /srv/data     # and fix what is already there
```

Both, in that order. The first changes nothing about existing files; the second
changes nothing about future ones. Doing only one is the usual mistake, and the
symptom differs depending on which you skipped.

`getfacl` shows defaults prefixed with `default:`, and they appear only on
directories.

**Default ACLs and umask interact in a way worth knowing:** when a default ACL
exists, it supplies the initial ACL for a new file and **the umask is not applied**
to the entries it defines. That is deliberate — it is what makes shared directories
work regardless of each user's personal umask — and it means a directory with a
default ACL behaves differently from one without in a way no one documents locally.

**The other inheritance mechanism is setgid on the directory**, and it solves a
different half:

```
chmod g+s /srv/data
```

New files inherit the directory's *group* rather than the creator's primary group.
Setgid answers "who owns it"; the default ACL answers "what may they do". Shared
project directories usually want both, and people commonly set one, see it half
work, and conclude ACLs are broken.

</details>

## Cause 3: the file is immutable

The distinguishing feature: it denies **root**, and the wording is different.
`Operation not permitted` rather than `Permission denied`.

```
# Debian 13, root
# echo x >> /etc/resolv.conf
-bash: /etc/resolv.conf: Operation not permitted
```

Standard permissions never deny root a write. When root is refused, the cause is
outside the mode bits, and the immutable attribute is the usual answer.

```
# lsattr /etc/resolv.conf
----i---------e------- /etc/resolv.conf
```

The `i` is the immutable flag. While it is set, the file cannot be modified,
renamed, or deleted by anyone, root included. Remove it with `chattr -i`.

This is worth recognising because it is often deliberate: it is a common way to
stop something from rewriting a config file. If you find it set, ask what set it
before you clear it.

> Output in this section is from `chattr(1)` and `lsattr(1)` documentation
> rather than a capture. File attributes are a filesystem feature that
> containers do not expose, so there was no honest way to run it here.

## Cause 4: the group membership is not in the running process

You add a user to a group, the group has access, and access still fails.

```
# usermod -aG appdata app
# id app
uid=1000(app) gid=1000(app) groups=1000(app),1001(appdata)
```

`id app` reads the group database and reports the new membership immediately.
That is the trap: the database is correct, so it looks like the change took.

Group membership is attached to a process when it starts. An existing shell,
service, or session carries the group list it was given at login and does not
pick up new ones. So `id app` shows the group, and `id` inside the already
running process does not.

Compare the two. If they disagree, the change is fine and the process is stale:
log the session out and back in, or restart the service. `newgrp appdata` starts
a new shell with the group for a one-off check.

Nothing needs fixing on disk here, which is why chasing it as a permissions
problem wastes so much time.


<details class="deeper">
<summary>If you already administer Linux: watching the kernel refuse, rather than guessing</summary>

Everything above reasons from configuration. Two tools let you watch the refusal
happen instead, which turns a hypothesis into an observation.

**`strace` shows the failing system call and its errno.** Run the command that
fails under it and filter to the calls that matter:

```
strace -f -e trace=openat,stat,access -o /tmp/trace.txt thecommand
grep -E 'EACCES|EPERM|ENOENT' /tmp/trace.txt
```

The distinction between the three is the diagnosis. **`EACCES`** is permission
denied — the path resolved and the check failed. **`EPERM`** is operation not
permitted, which is usually a capability or an immutable flag rather than a mode.
**`ENOENT`** is no such file, and it appears for a path component you cannot
*traverse* as well as one that does not exist — which is why a traversal problem
can present as a missing file.

For a service rather than a command, `strace -f -p <pid>` attaches to a running
process, and `-y` prints the path each file descriptor refers to, which saves
correlating numbers by hand.

**The audit log records denials the kernel made a decision about.**
`ausearch -m AVC,USER_AVC -ts recent` for SELinux, and `ausearch -m
AVC,SYSCALL --success no -ts recent` more broadly. On a machine without auditd
running, `dmesg | grep -i denied` catches most of the same events.

The practical order: check the four causes above first, because they are free.
Reach for `strace` when the configuration all looks correct and the command still
fails, because at that point you need to know what the process is actually asking
for rather than what you assume it asks for.

</details>

## Across distributions

The mechanisms are kernel features, so they behave identically everywhere. What
differs is what is installed and what is switched on.

| | RHEL family | Debian family |
| --- | --- | --- |
| `namei` | `util-linux`, installed | `util-linux`, installed |
| `getfacl` / `setfacl` | `acl`, **not always installed** | `acl`, **not always installed** |
| ACLs enabled by default | Yes, on ext4 and xfs | Yes, on ext4 |
| Mandatory access control | SELinux, enforcing | AppArmor, and it denies differently |
| Denials logged to | `auditd`, `ausearch -m AVC` | `dmesg`, or `journalctl -k` |

**The row that matters when you are stuck** is the last one. On the RHEL family a
MAC denial is a structured audit record you can search by subject and object. Under
AppArmor it is a kernel message naming the profile and the operation, so
`journalctl -k | grep -i apparmor` is the equivalent first move — and `aa-status`
replaces `getenforce`.

**`acl` not being installed is worth checking early**, because `getfacl: command not
found` on a machine whose files show a `+` in `ls -l` means the ACLs are real and
you have no way to read them until you install the package.

## What trips people up

### 1. Reading `ls -l` on the file and stopping there

The file's mode is the **last** thing the kernel checks, so it is the last thing
worth looking at. `namei -l` reads the whole path in one command.

### 2. Escalating to `chmod -R 777`

It does not fix a traversal problem, because the problem is a directory's execute
bit and not the file's mode — and now you have a security finding on top of the
original fault. If the denial survives `chmod 777` on the file, the file was never
the cause.

### 3. Running the check as root

Root bypasses the discretionary checks entirely, so everything looks fine and you
learn nothing. `runuser -u <user> --` or `sudo -u <user>` reproduces it honestly.

### 4. `chmod` on a file that has ACLs

Once an ACL exists, the middle bits in `ls -l` are the **mask**, not the group
permission. `chmod 640` lowers the ceiling on every named entry at once, leaving
grants that are present and inert. Use `setfacl`, and treat a `+` in `ls -l` as a
warning that `chmod` will do something other than what it looks like.

### 5. Trusting `id <user>` over the process

`id <user>` reads the database. The kernel checks the credentials the process was
given when it started. A group added after login is in the first and not the
second, and only a new session fixes it.

### 6. Reaching for SELinux first

It is the fourth thing to check, not the first, because the ordinary permission
check runs before it. **No AVC in the audit log means SELinux was never consulted**,
which rules it out in one command rather than by disabling it.

## Prove it

Three commands, in this order, before touching anything:

```bash
# 1. Which component of the path actually denies it
namei -l /path/to/file

# 2. Is there an ACL, and is the mask cutting it down
getfacl /path/to/file

# 3. What identity is the failing process actually running as
ps -o user,group,pid,cmd -p <PID>
```

Run them as the user that is failing, not as root. Running the check as root is
the single most common way to conclude that "it works fine" while the reported
problem is still there.

```bash
runuser -u app -- namei -l /srv/data/reports/q3.csv
```

## Work it through

A backup job that has run nightly for a year starts failing. The log says:

```
tar: /srv/data/reports: Cannot open: Permission denied
tar: Error is not recoverable: exiting now
```

The job runs as `backup`. Nobody reports changing anything.

Reason it out before reading on.

**First, reproduce it as the right user.** As root everything works, which tells
you nothing:

```bash
runuser -u backup -- namei -l /srv/data/reports
```

Say that returns `drwxr-x--- root root reports`. The `backup` user has no
traversal. But this ran for a year, so the question is not "what are the
permissions" but **"what changed"**.

**Second, check whether an ACL was there and got flattened.** A year-old working
setup that breaks with no directory change is the signature of the mask trap:

```bash
getfacl /srv/data/reports
```

If it reports `user:backup:r-x` with `#effective:---`, somebody ran `chmod` on
the directory. The ACL is still there, the mask crushed it, and `ls -l` looks
unremarkable apart from a `+` nobody noticed.

**Third, confirm the timing** with the directory's change time, which `chmod`
updates:

```bash
stat -c '%n  ctime=%z  mtime=%y' /srv/data/reports
```

A `ctime` from last Tuesday against an untouched `mtime` says the metadata
changed and the contents did not, which is exactly what a `chmod` does.

The reasoning that matters: the reported symptom was about a backup job, and none
of the diagnosis went near the backup software. The error named a path, so the
path is what got read, in the order the kernel reads it.

## Try it

Optional, and only worth doing if you have a VM or container to hand.

Build the first failure deliberately, then the second.

1. Create `/srv/data/reports/q3.csv`, world-readable, inside a directory that is
   `750` and owned by `root:root`. Confirm an unprivileged user gets
   `Permission denied` while `ls -l` on the file shows `r` for other.
2. Fix it with group membership rather than by widening `other`.
3. Now add an ACL granting that user `rw` on the file, then run `chmod 644` on
   it and watch the grant stop working.

**Verification step.** You have step 3 right when `getfacl` shows a `#effective:`
annotation lower than the granted permission, and you can name the single entry
that caused it without changing anything.

## Check yourself

<details class="qa">
<summary>A file is `-rw-rw-rw-` and an unprivileged user still cannot read it. Name the most likely cause and the one command that confirms it.</summary>

**A directory somewhere in the path denies traversal**, and `namei -l <path>`
confirms it in one command.

The kernel resolves a path one component at a time and needs **execute** on every
directory along the way before it ever looks at the file. A file that is
world-readable inside a directory that is `750` and owned by somebody else is
unreachable, and its own mode never gets consulted.

`namei -l` prints the mode, owner, and group of every component, so the offending
one is visible rather than inferred. Run it **as the failing user** —
`runuser -u app -- namei -l /path` — because as root every line will look fine.

The tempting wrong answer is SELinux, and it is worth ruling in properly rather
than guessing: a SELinux denial writes an AVC to the audit log, so
`ausearch -m AVC -ts recent` returning nothing means SELinux was never consulted.
Ordinary permissions are checked first, and if they refuse, the policy engine is
never asked.

The other near-miss is an ACL, which is worth checking second because `ls -l` shows
it only as a single `+` character that nobody notices.

</details>

<details class="qa">
<summary>What is the difference between `Permission denied` and `Operation not permitted`, and which one implicates the mode bits?</summary>

They are two different errno values and they point at different subsystems.

**`Permission denied` is `EACCES`.** The path resolved, a permission check ran, and
it failed. This is the mode bits, an ACL, or a directory in the path — the things
this lesson is about.

**`Operation not permitted` is `EPERM`.** The check that failed was not a mode
check. It usually means a **capability** the process lacks, or a **file attribute**
such as immutable. `EPERM` arriving when you are already root is the strong signal,
because root does not normally get refused by permissions at all — that is the cue
to run `lsattr`.

So **`EACCES` implicates the mode bits and `EPERM` does not**, and reading which
one you got saves checking the wrong thing entirely.

A third worth recognising: **`ENOENT`, no such file or directory**, appears for a
path component you cannot *traverse* as well as one that genuinely does not exist.
The kernel does not distinguish, deliberately — telling you a directory exists but
you may not enter it would leak its existence. So a traversal problem can present
as a missing file, which is a real source of confusion.

`strace -e trace=openat,stat` on the failing command shows the errno directly, which
turns all of this from inference into observation.

</details>

<details class="qa">
<summary>You run `chmod 640` on a file that has ACLs. What did you change besides the owner, group, and other bits?</summary>

**The ACL mask**, and that is why the file may now be inaccessible to people the
ACL still explicitly names.

When a file has an ACL, the middle set of bits in `ls -l` is no longer the group
permission — it is the **mask**, the ceiling on every named user, named group, and
the owning group. `chmod` writes to that position, so `chmod 640` sets the mask to
`r--`.

Every ACL entry survives untouched. `getfacl` still shows `user:backup:rw-`. But it
now carries `#effective:r--` beside it, because the mask caps it. The grant is
present, documented, and inert.

**This is the single nastiest failure in the topic**, because the change that broke
it looks unrelated. Somebody tightened a file's permissions, `ls -l` shows nothing
alarming apart from a `+`, and a job that ran for a year stops.

The fix is `setfacl -m m::rwx <path>` to restore the mask, and the habit is to use
`setfacl` rather than `chmod` on anything carrying ACLs. `getfacl` before and after
any `chmod` on a `+` file is the cheap check.

</details>

<details class="qa">
<summary>`id alice` shows her in the `deploy` group, but her running shell cannot write to a `deploy`-owned directory. Nothing on disk is wrong. Why?</summary>

**Group membership is attached to a process when it starts**, and her shell started
before the group was added.

`id alice` queries the group database, which is already correct — that is exactly
what makes this so misleading. The running shell carries the supplementary group
list it was handed at login, in its credentials, and nothing updates it in place.
The kernel checks *those*, not the database.

The confirming test is to compare the two:

```
id alice          # the database: shows deploy
id                # her own process: does not
```

Disagreement means the change is fine and the session is stale.

**The fix is a new session**, not a change on disk: log out and back in, or restart
the service if it is a daemon. `newgrp deploy` starts a subshell carrying the group
for a one-off check without a full logout.

The same shape catches people with services: adding a service account to a group and
not restarting the service leaves it running with the old credentials, sometimes for
months, until something restarts it and it mysteriously starts working.

Nothing needs fixing on disk, which is why chasing it as a permissions problem
wastes so much time.

</details>

<details class="qa">
<summary>Why does running the failing command as root tell you almost nothing?</summary>

**Because root bypasses nearly every check you are trying to test.**

`CAP_DAC_OVERRIDE` lets root ignore file read, write, and execute bits entirely, and
`CAP_DAC_READ_SEARCH` lets it traverse directories regardless of execute permission.
So a traversal failure, a mode problem, and an ACL mask all disappear when root
runs the command — and you conclude "it works fine" while the reported problem is
untouched.

Reproduce as the failing identity:

```
runuser -u app -- namei -l /srv/data/reports/q3.csv
sudo -u app cat /srv/data/reports/q3.csv
```

**The exceptions are the interesting part**, because they are the few things root
does *not* bypass, which makes them diagnostic. The immutable attribute stops root.
SELinux stops root, since it is a separate check that runs after the discretionary
one. And a read-only mount stops root. So a denial that persists under root has
already narrowed itself to those three.

For a service rather than a command, reproducing "as the failing user" means more
than the UID: a systemd unit may have `ProtectHome=`, `ReadOnlyPaths=`, or a
`CapabilityBoundingSet=` that your shell does not. `systemd-run --uid=app` gets
closer, and `systemctl show unit -p ...` tells you what the real one is running
under.

</details>

## References

- [path_resolution(7)](https://man7.org/linux/man-pages/man7/path_resolution.7.html) - Linux man-pages project. Accessed 2026-08-07.
- [namei(1)](https://man7.org/linux/man-pages/man1/namei.1.html) - Linux man-pages project. Accessed 2026-08-07.
- [acl(5)](https://man7.org/linux/man-pages/man5/acl.5.html) - Linux man-pages project. Accessed 2026-08-07.
- [getfacl(1)](https://man7.org/linux/man-pages/man1/getfacl.1.html) - Linux man-pages project. Accessed 2026-08-07.
- [setfacl(1)](https://man7.org/linux/man-pages/man1/setfacl.1.html) - Linux man-pages project. Accessed 2026-08-07.
- [lsattr(1)](https://man7.org/linux/man-pages/man1/lsattr.1.html) - Linux man-pages project. Accessed 2026-08-07.
- [getenforce(8)](https://man7.org/linux/man-pages/man8/getenforce.8.html) - Linux man-pages project. Accessed 2026-08-07.
- [id(1)](https://man7.org/linux/man-pages/man1/id.1.html) - Linux man-pages project. Accessed 2026-08-07.

Captured output was produced on the images pinned in `blog/scripts/distros.json`
and is reproducible with `blog/scripts/capture.sh`. Blocks not marked with a
distribution and architecture are from the documentation cited above.
