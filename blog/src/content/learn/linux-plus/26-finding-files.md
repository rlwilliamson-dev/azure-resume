---
title: "It is on this machine somewhere"
description: "Something exists on this server and nobody knows where. One command searches by name, size, age, owner, and permission, runs another command on what it finds, and is one flag away from deleting all of it."
track: "linux-plus"
level: "working"
order: 270
objectives:
  - "Search a filesystem by name, type, size, age, and permission"
  - "Run a command against every match, efficiently and safely"
  - "Say why locate can be wrong and find never is"
  - "Identify a file by its contents rather than its name"
prerequisites: ["links-hard-and-symbolic"]
tags: ["linux", "linux-plus", "find", "search", "filesystem"]
updated: 2026-08-07
draft: false
examObjectives:
  - exam: "xk0-006"
    domain: "2.0"
    objective: "2.1"
sources:
  - title: "find(1)"
    url: "https://man7.org/linux/man-pages/man1/find.1.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "xargs(1)"
    url: "https://man7.org/linux/man-pages/man1/xargs.1.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "stat(1)"
    url: "https://man7.org/linux/man-pages/man1/stat.1.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "file(1)"
    url: "https://man7.org/linux/man-pages/man1/file.1.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "locate(1)"
    url: "https://manpages.debian.org/stable/plocate/plocate.1.en.html"
    publisher: "Debian Project"
    accessed: 2026-08-07
    tier: 1
  - title: "GNU Findutils manual"
    url: "https://www.gnu.org/software/findutils/manual/find.html"
    publisher: "GNU Project"
    accessed: 2026-08-07
    tier: 1
symptoms:
  - symptom: "locate finds a file that no longer exists"
    anchor: "2-locate-is-out-of-date"
  - symptom: "find with -exec is extremely slow on a large tree"
    anchor: "3-exec-with-a-semicolon-on-a-large-tree"
---

> **Before you read.** A colleague says the application reads its configuration
> from "a conf file somewhere under `/etc` or maybe `/opt`". A monitoring alert
> says a filesystem is full and nobody knows what filled it. An auditor asks for
> every world-writable file on the machine.
>
> Three questions, and none can be answered by knowing where to look, because
> that is precisely what is missing.
>
> **What would one command have to be able to do to answer all three?**

Search by attribute rather than by location. Not "show me this file" but "show me
every file that is a certain size, or a certain age, or has a certain permission",
starting anywhere and going all the way down.

That is `find`, and it is one of the two or three commands worth genuinely
learning rather than looking up each time. It also has a `-delete` flag, which is
why a good part of this lesson is about looking before acting.

### Some words you will need

<dl class="terms">
<dt>test</dt>
<dd>A condition applied to each file: <code>-name</code>, <code>-size</code>, <code>-mtime</code>. Several combine.</dd>
<dt>action</dt>
<dd>What happens to a match: print it, run a command, delete it. Printing is the default.</dd>
<dt>descend</dt>
<dd>To walk into a directory and everything below it. <code>find</code> does this by default; most commands do not.</dd>
<dt>index</dt>
<dd>A database of filenames built in advance, which <code>locate</code> searches instead of the disk.</dd>
</dl>

## What breaks without this

**Disk-full incidents take an hour instead of a minute.** "Which files are large
and old" is one command, and without it you are clicking down through
directories.

**You cannot audit anything.** Every hardening check — world-writable files,
setuid binaries, files owned by a deleted account — is a `find` expression.

**Cleanup jobs get written by hand and get it wrong.** Deleting logs older than
30 days is a one-liner that is also one typo away from deleting everything.

## The shape of the command

```
find WHERE  TESTS  ACTION
find /var/log  -name '*.log' -mtime +30  -delete
```

**Read it left to right, because that is how it evaluates.** Where to start, then
conditions, then what to do. Conditions are ANDed by default, so more tests means
fewer results.

### By name, type, and size

The tree below is `/srv/app`, containing a `logs` directory with three `.log`
files, plus `conf` and `cache`. The starting point given to `find` is `.`, the
current directory.

<details class="predict">
<summary>`find . -type d` lists directories under `.`. There are three subdirectories. How many lines does it print, and why is that not three?</summary>

```bash
# Debian 13 (trixie), x86_64
$ cd /srv/app; echo '--- by name ---'; find . -name '*.log'; echo '--- directories only ---'; find . -type d; echo '--- bigger than 100k ---'; find . -type f -size +100k
--- by name ---
./logs/app.log
./logs/big.log
./logs/archive.log
--- directories only ---
.
./logs
./conf
./cache
--- bigger than 100k ---
./logs/big.log
```

</details>

**Four, because `find` tests the starting point too.** `.` is itself a directory
and it matches `-type d`, so it is printed like anything else. That is not a quirk;
it follows from `find` walking the tree *including its root*, and it is why
`find . -type f -delete` in the wrong directory is so destructive and why
`find /tmp -name '*' -exec rm -rf {} +` tries to remove `/tmp` itself.

`-mindepth 1` excludes the starting point when that matters.

**Quote the pattern.** `find . -name '*.log'` works; `find . -name *.log` lets the
*shell* expand `*.log` first, against the current directory, and `find` receives
something else entirely. If the current directory happens to hold exactly one
`.log` file the command appears to work, which is worse than failing.

`-iname` is the case-insensitive version and worth reaching for by default on
somebody else's filesystem.

| Test | Matches |
| --- | --- |
| `-name 'x*'` | Name matches the glob |
| `-iname 'x*'` | Ignoring case |
| `-path '*/conf/*'` | The whole path matches |
| `-type f` / `d` / `l` | Regular file, directory, symlink |
| `-size +100M` / `-100k` | Larger / smaller. The sign matters. |
| `-empty` | Zero bytes, or an empty directory |

### By age and permission

```bash
# Debian 13 (trixie), x86_64
$ cd /srv/app; echo '--- not touched in 30 days ---'; find . -type f -mtime +30; echo '--- world-writable, which is a finding ---'; find . -type f -perm -o+w; echo '--- and combining tests ---'; find . -type f -name '*.conf' -perm -o+w
--- not touched in 30 days ---
./logs/archive.log
--- world-writable, which is a finding ---
./conf/creds.conf
--- and combining tests ---
./conf/creds.conf
```

**`-mtime +30` means more than 30 days ago**, `-30` means within the last 30, and
a bare `30` means exactly the 24-hour window 30 days back — which is almost never
what anyone wants and is why some cleanup jobs have never deleted anything.

`-mmin` is the same in minutes, which is the one for "what changed during the
incident".

**The `-perm` forms are not interchangeable:**

| Form | Means |
| --- | --- |
| `-perm 644` | Exactly this mode and nothing else |
| `-perm -o+w` | **At least** these bits: anything world-writable |
| `-perm -4000` | At least setuid |
| `-perm /u+w` | **Any** of these bits |

The leading `-` is what you want nearly always: "has at least this bit", whatever
else is set.

Three expressions worth memorising, because they are standard audit checks:

```
sudo find / -perm -4000 -type f 2>/dev/null    # every setuid binary
sudo find / -type f -perm -o+w 2>/dev/null     # every world-writable file
sudo find / -nouser -o -nogroup 2>/dev/null    # owned by a deleted account
```

`2>/dev/null` because searching from `/` produces a permission error for every
directory you cannot enter, and those drown the results.

<details class="deeper">
<summary>If you already administer Linux: pruning a subtree, and getting find to print what you actually want</summary>

Two things turn `find` from a search tool into something you can build on.

**`-prune` stops it descending, and the syntax is genuinely strange** because
`-prune` is an *action* that returns true, not a test. The idiom is:

```
find /var -path /var/lib/docker -prune -o -name '*.log' -print
```

Read it as an OR: for each entry, either it is `/var/lib/docker` — in which case
prune it and stop, having matched — or try the name test and print. **The trailing
`-print` is not optional here.** Without it `find`'s implicit print applies to the
whole expression including the pruned branch, and the directory you meant to skip
gets listed. That single missing word is why most copied `-prune` incantations
behave oddly.

`-xdev` is the blunter version and is often what you actually wanted: it refuses to
cross filesystem boundaries, so `find / -xdev` skips `/proc`, `/sys`, network
mounts, and anything else mounted underneath, without naming any of them. On a
machine with an NFS mount, `find /` without `-xdev` will walk the whole server.

**`-printf` replaces a pipeline.** The default output is a path and nothing else,
so people reach for `-exec ls -l` and pay a process per file. `-printf` formats
directly from the stat data `find` already has:

```
find /var/log -type f -printf '%s\t%p\n' | sort -rn | head
find /home -type f -printf '%u %m %p\n'
find . -newermt '2026-08-01' -printf '%TY-%Tm-%Td %p\n'
```

`%s` size in bytes, `%p` path, `%u` owner, `%m` octal mode, `%T` with a strftime
letter for the modification time, `%d` depth. The first line there is the fastest
"what is filling this directory" one-liner there is, and it forks nothing.

**The portability caveat:** `-printf` is a GNU extension. It is on every Linux
distribution and absent on macOS and the BSDs, where `-exec stat` is the fallback.
A script that must run on both should use `stat` and accept the cost.

</details>

## Doing something with the matches

```bash
# Debian 13 (trixie), x86_64
$ cd /srv/app; echo '--- -exec runs a command per match ---'; find . -name '*.log' -exec ls -l {} +; echo '--- and file identifies by content, not by name ---'; file run.sh conf/app.conf logs/big.log
--- -exec runs a command per match ---
-rw-r--r--. 1 root root      9 Aug  8 03:19 ./logs/app.log
-rw-r--r--. 1 root root      4 Jun 29 03:19 ./logs/archive.log
-rw-r--r--. 1 root root 200000 Aug  8 03:19 ./logs/big.log
--- and file identifies by content, not by name ---
/bin/sh: 13: file: not found
```

`{}` is replaced by each match, and the terminator decides how:

| Ending | Behaviour |
| --- | --- |
| `-exec cmd {} +` | Batches many files into one invocation. **Fast.** |
| `-exec cmd {} \;` | One invocation per file. Slow, occasionally necessary. |
| `-ok cmd {} \;` | As `\;`, but asks first |

**Use `+` unless the command can only take one argument at a time.** On ten
thousand files that is one process against ten thousand.

That last line is a real capture and a real lesson from topic 05 arriving again:
`file` is not installed on a minimal Debian image. With it present:

```bash
# Debian 13 (trixie), x86_64
$ cd /srv/app; file run.sh app.conf mystery
run.sh:   POSIX shell script, ASCII text executable
app.conf: ASCII text
mystery:  ELF 64-bit LSB pie executable, x86-64, version 1 (SYSV), dynamically linked, interpreter /lib64/ld-linux-x86-64.so.2, BuildID[sha1]=0243f2a3ad64d635299a574bbc8ef951ddde9b21, for GNU/Linux 3.2.0, stripped
```

**`file` reads the contents, not the name.** `mystery` has no extension and is
correctly identified as a 64-bit executable, with its architecture and whether it
was stripped. On Linux an extension is a human convention that nothing enforces,
so `file` is how you find out what something actually is — and a file called
`notes.txt` that reports `gzip compressed data` is a common and useful discovery.

`stat` is the companion for metadata. `stat -c '%s %U %a %y %n' file` gives size,
owner, mode, modification time, and name on one line: `ls -l` with fields you
chose.

<details class="predict">
<summary>`find /var/log -name '*.log' -mtime +30 -delete` clears old logs. Somebody writes `find /var/log -delete -name '*.log' -mtime +30` instead. What happens?</summary>

**It deletes everything under `/var/log`**, directories included, and the tests
never meaningfully apply.

`find` evaluates left to right, and `-delete` is an **action**, not a filter.
Placed first, it runs on every file the traversal reaches, before `-name` or
`-mtime` have any say. Each deletion also returns true, so evaluation continues
to the tests, which then match against files that no longer exist.

No confirmation, no undo.

This is the same left-to-right rule that makes `find / -name '*.log' -mtime +30`
faster than `find / -mtime +30 -name '*.log'` — order controls what gets
evaluated against what. The difference is that here the consequence is
destructive rather than slow.

**Two habits prevent it.** Run the expression with no action first, read the
list, then add the action:

```
find /var/log -name '*.log' -mtime +30            # look
find /var/log -name '*.log' -mtime +30 -delete    # then act
```

And put the action **last**, always, as a matter of form. GNU `find` does warn
about this particular ordering — but a warning printed above a screen of output
is not a defence worth relying on.

One related detail: **`-delete` implies `-depth`**, processing a directory's
contents before the directory itself. That is what allows it to remove
directories at all, and it is why `-delete` and `-prune` do not combine the way
people expect.

</details>

## locate, and why it lies

`locate` searches a pre-built index rather than the disk, which makes it
essentially instant across a whole filesystem where `find /` takes minutes.

```
locate nginx.conf
sudo updatedb        # rebuild the index
```

**The index is rebuilt on a schedule**, typically daily by a systemd timer. So a
file created this morning is not in it, a file deleted this morning still is, and
anything under a directory excluded by `/etc/updatedb.conf` never appears.

That makes `locate` excellent for "where does this distribution keep that
program" and unsuitable for anything about the current state of the machine.
`find` reads the actual filesystem and is never stale.

Three narrower tools, none of which is a general search:

| Command | Answers |
| --- | --- |
| `which cmd` | The path `PATH` would resolve. Misses builtins and functions. |
| `type -a cmd` | Everything, in resolution order. Better. |
| `whereis cmd` | Binary, source, and manual page locations |

<details class="deeper">
<summary>If you already administer Linux: xdev, pruning, and printf</summary>

**`find /` on a real server is slower and more hazardous than it looks**, and two
flags fix most of it.

**`-xdev`** keeps the search on one filesystem. Without it, `find /` descends into
`/proc`, `/sys`, every bind mount, every container overlay, and — worst — any NFS
mount, where an unresponsive server hangs the search with no timeout. On a machine
with network mounts this is not an optimisation, it is what stops the command
hanging.

**`-prune` skips a subtree before descending**, which is different from filtering
it out of the results:

```
find / -path /proc -prune -o -name '*.conf' -print
```

The `-o` is required and so is the explicit `-print` — once you use `-o` the
default action no longer covers the whole expression. It reads as "either prune
this, or match and print", and getting it wrong gives you either no output or
unpruned output.

**`-printf` selects exactly the fields you want**, which turns `find` into a
reporting tool with no forking at all:

```
find /var -type f -printf '%s %p\n' | sort -rn | head -20
```

Twenty largest files under `/var` in one pass. `%s` size, `%p` path, `%u` owner,
`%M` the mode string, `%TY-%Tm-%Td` a date. Far faster than `-exec ls -l`.

**`-print0` with `xargs -0`** for filenames containing spaces, quotes, or
newlines. `-exec ... +` avoids the problem entirely and is usually simpler.

**`-newer`** compares against a file's timestamp rather than an interval:
`touch -d '2026-08-01' /tmp/marker; find /srv -newer /tmp/marker` is the readable
way to ask what changed since a deployment.

</details>

<details class="deeper">
<summary>If you already administer Linux: the three timestamps, and why atime is usually a lie</summary>

Every inode carries three times and `-mtime` is only one of them.

**mtime** — when the contents last changed. The one you usually want.
**ctime** — when the *inode* last changed: contents, permissions, owner, or link
count. **atime** — when it was last read.

`stat` shows all three, labelled Modify, Change, and Access.

**`-ctime` is what catches tampering.** `touch -d` can set mtime to anything and
cannot backdate ctime, because the kernel updates ctime whenever the inode is
written — including by the `touch` that faked the mtime. A file whose mtime is a
year old and whose ctime is yesterday has been changed by someone who did not
want it visible. `sudo find /bin /usr/bin -ctime -1` after a suspected incident
is cheap and genuinely useful.

**atime is mostly not recorded.** Updating it means a write on every read, so
nearly every filesystem is mounted `relatime` — atime updates only if it is older
than mtime or more than a day stale — and some are `noatime` and never update it.
So "this file has not been read in a year" is a claim worth checking `findmnt`
before making.

**`-newerXY`** is the general form: `-newermt '2026-08-01'` compares mtime against
a date, `-newerct` uses ctime. More precise than counting days and it accepts
anything `date` understands.

</details>

## Across distributions

| | RHEL family | Debian family |
| --- | --- | --- |
| `find`, `xargs` | `findutils` | `findutils` |
| `locate` implementation | `plocate`, or `mlocate` | `plocate` |
| `file` | `file` | `file`, often not installed |
| Exclusions | `/etc/updatedb.conf` | `/etc/updatedb.conf` |

`plocate` has replaced `mlocate` on both families and is much faster. Neither is
installed by default on a minimal server, which is one more reason `find` is the
one to know properly.

## Prove it

Before any destructive `find`:

```bash
# 1. What does it match, with no action at all
find /var/log -name '*.log' -mtime +30

# 2. Count it, so a surprising number is obvious
find /var/log -name '*.log' -mtime +30 | wc -l

# 3. Sizes and dates, so you know what you are losing
find /var/log -name '*.log' -mtime +30 -printf '%TY-%Tm-%Td %10s %p\n' | sort

# 4. Only now add the action
find /var/log -name '*.log' -mtime +30 -delete
```

**Step 2 is the one that catches the mistake.** A cleanup expected to remove forty
files that reports 40,000 has something wrong with it, and the count takes no
longer than the deletion would have.

## What trips people up

### 1. Forgetting to quote the pattern

`find . -name *.log` is expanded by the shell first. With one matching file in the
current directory it appears to work; with several it is a syntax error.

Quote it: `-name '*.log'`.

### 2. `locate` is out of date

It searches an index rebuilt daily. New files are missing, deleted files are still
listed, excluded directories never appear.

`sudo updatedb` refreshes it. Use `find` for anything about the current state.

### 3. `-exec` with a semicolon on a large tree

`\;` forks once per file. On a large tree that is minutes rather than seconds.

`+` batches. Use it unless the command genuinely takes one argument at a time.

### 4. Searching from `/` without `-xdev`

Descends into `/proc`, `/sys`, container overlays, and NFS mounts, where an
unresponsive server hangs the command indefinitely.

`-xdev` stays on one filesystem; `2>/dev/null` suppresses the permission noise.

### 5. `-mtime 30` when you meant `+30`

A bare number is *exactly* that day. A cleanup job that has never deleted anything
is usually a missing `+`.

## Work it through

A monitoring alert says `/var` is at 96%. The server is live.

Reason through the order before reading on.

**First, confirm it is space and not inodes.** `df -h /var` and `df -i /var`. If
inodes are exhausted and blocks are not, you are looking for millions of tiny
files rather than a few large ones, and the search is a different one.

**Second, find the weight, not the files.** Directories before files:

```
du -h --max-depth=1 /var 2>/dev/null | sort -h | tail
```

which names the branch, then descend one level at a time. `du` is the right tool
here because it **aggregates**, and the answer to "what is using the space" is
usually a directory rather than any single file.

**Third, once you have the branch, ask `find` for specifics:**

```
find /var/log -type f -printf '%s %TY-%Tm-%Td %p\n' | sort -rn | head -20
```

Twenty largest files with dates, one pass, no forking. The dates matter as much
as the sizes: they tell you whether this is slow accumulation or something that
started on Tuesday.

**Fourth — the step people skip — check for deleted-but-open files:**

```
sudo lsof +L1
```

Straight from the last lesson. If `du` totals far less than `df` reports used,
the difference is a file somebody already deleted that a process still holds
open. No search will find it by name, because it has none.

**Only then clean up**, with the look-first sequence from Prove it.

Now the point worth extracting. **`du` and `find` answer different questions and
the order matters.** `du` tells you *where* the space went by aggregating upward;
`find` tells you *which files*, once you know where to look. Starting with
`find /` gives you a list too long to read and takes a long time producing it.

And the habit: **the count before the deletion, every time.** It costs nothing, it
runs the exact expression you are about to act on, and a number that surprises you
is the only warning you are going to get.

## Try it

Optional, on any machine.

1. `find /etc -name '*.conf' | head`, then try it without the quotes.
2. `find /var/log -type f -size +1M 2>/dev/null`.
3. `find /etc -type f -mtime -7 2>/dev/null` — what changed this week.
4. `sudo find /usr -perm -4000 -type f` and read the setuid list.
5. `find /var -type f -printf '%s %p\n' 2>/dev/null | sort -rn | head -10`.
6. `file` on a few things in `/usr/bin` and on a config file.
7. `stat /etc/passwd` and find all three timestamps.

**Verification step.** You have it when you can write, without looking anything
up, an expression that finds every file over 100 MB not modified in six months
under a given directory — and show the list before deleting any of it.

## Check yourself

<details class="qa">
<summary>Why must the pattern in `find . -name '*.log'` be quoted?</summary>

**Because the shell expands `*` before `find` runs.** Unquoted, the glob is
resolved against the *current directory* and `find` receives whatever that
produced rather than the pattern.

Three outcomes, all bad. With no match in the current directory most shells pass
the literal string through and it works by accident. With exactly one, `find`
searches for that specific filename everywhere and appears to work. With several,
`-name` gets multiple arguments and it is a syntax error.

Quoting passes the pattern through intact, so `find` applies it at every level of
the tree — which is the point of using `find` at all.

</details>

<details class="qa">
<summary>What is the difference between `-mtime 30`, `+30`, and `-30`?</summary>

**`+30`** is more than 30 days ago. This is the one for cleanup.

**`-30`** is within the last 30 days. This is the one for "what changed
recently".

**`30`** with no sign is *exactly* that day — the single 24-hour window between 30
and 31 days back. It is almost never what anyone intends.

A cleanup job that has quietly deleted nothing for a year is usually a missing
`+`.

`-mmin` gives the same three forms in minutes, which is what you want during an
incident where days are too coarse.

</details>

<details class="qa">
<summary>Why is `-exec cmd {} +` usually better than `-exec cmd {} \;`?</summary>

**`+` batches many filenames into one invocation; `\;` runs the command once per
file.**

On ten thousand matches that is a handful of processes against ten thousand —
seconds against minutes.

Use `\;` only when the command cannot accept multiple arguments, or when `{}`
must appear somewhere other than the end: `mv {} {}.bak` needs the per-file form.

`+` also handles filenames containing spaces correctly with no extra effort,
which is the other reason to prefer it over piping into `xargs`.

</details>

<details class="qa">
<summary>When is `locate` the right tool, and when is it actively misleading?</summary>

**Right when you want to know where a distribution keeps something** and speed
matters. It searches a pre-built index and answers instantly where `find /` reads
the whole filesystem.

**Misleading for anything about the current state.** The index is rebuilt on a
schedule, usually daily, so a file created this morning is absent, a file deleted
this morning is still listed, and anything excluded by `/etc/updatedb.conf` never
appears.

So `locate` for "where does nginx keep its config on this distribution", and
`find` for "what changed during the incident" or anything you intend to act on.

`sudo updatedb` refreshes the index when you need it current.

</details>

<details class="qa">
<summary>A file's mtime is a year old and its ctime is yesterday. What does that tell you?</summary>

**The inode was written yesterday** — permissions, ownership, link count, or the
contents followed by a backdated timestamp.

Why it matters: **mtime can be set to anything with `touch -d`; ctime cannot.**
The kernel updates ctime whenever the inode changes, including during the `touch`
that faked the mtime. The two disagreeing is evidence of a change somebody did
not want visible.

`stat` shows both, labelled Modify and Change. `sudo find /bin /usr/bin -ctime -1`
is a cheap check after a suspected incident.

The third timestamp, atime, is the least trustworthy: most filesystems are mounted
`relatime` or `noatime`, so "not read in a year" may just mean nobody recorded it.

</details>

## References

- [find(1)](https://man7.org/linux/man-pages/man1/find.1.html) - Linux man-pages project. Accessed 2026-08-07.
- [xargs(1)](https://man7.org/linux/man-pages/man1/xargs.1.html) - Linux man-pages project. Accessed 2026-08-07.
- [stat(1)](https://man7.org/linux/man-pages/man1/stat.1.html) - Linux man-pages project. Accessed 2026-08-07.
- [file(1)](https://man7.org/linux/man-pages/man1/file.1.html) - Linux man-pages project. Accessed 2026-08-07.
- [locate(1)](https://manpages.debian.org/stable/plocate/plocate.1.en.html) - Debian Project. Accessed 2026-08-07.
- [GNU Findutils manual](https://www.gnu.org/software/findutils/manual/find.html) - GNU Project. Accessed 2026-08-07.

Command output was captured on the images pinned in `blog/scripts/distros.json`.
Blocks without a distribution and architecture header are illustrative.
