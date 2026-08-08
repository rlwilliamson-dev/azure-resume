---
title: "Troubleshooting permission denied"
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

1. A file is `-rw-rw-rw-` and an unprivileged user still cannot read it. Name the
   most likely cause and the one command that confirms it.
2. What is the difference in meaning between `Permission denied` and
   `Operation not permitted`, and which one implicates the mode bits?
3. You run `chmod 640` on a file that has ACLs. What did you change besides the
   owner, group, and other bits?
4. `id alice` shows her in the `deploy` group, but her running shell cannot write
   to a `deploy`-owned directory. Nothing on disk is wrong. Why?
5. Why does running the failing command as root tell you almost nothing?

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
