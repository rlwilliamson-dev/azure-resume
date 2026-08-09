---
title: "The restore is the part nobody tests"
description: "Every organisation has backups. Rather fewer have restores. What the three backup types actually cost, the rsync flag that decides whether you copied a directory or its contents, and why a backup you have not restored is a hypothesis."
track: "linux-plus"
level: "working"
order: 240
objectives:
  - "Choose between full, incremental, and differential from a stated requirement"
  - "Copy a tree with rsync and predict where it lands"
  - "Say what --delete will remove before running it"
  - "Verify a restore, and explain why RAID and snapshots are not backups"
prerequisites: ["archiving-and-compression"]
tags: ["linux", "linux-plus", "backup", "rsync", "dd"]
updated: 2026-08-07
draft: false
examObjectives:
  - exam: "xk0-006"
    domain: "1.0"
    objective: "1.6"
sources:
  - title: "rsync(1)"
    url: "https://manpages.debian.org/stable/rsync/rsync.1.en.html"
    publisher: "Debian Project"
    accessed: 2026-08-07
    tier: 1
  - title: "dd(1)"
    url: "https://man7.org/linux/man-pages/man1/dd.1.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "sha256sum(1)"
    url: "https://man7.org/linux/man-pages/man1/sha256sum.1.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "GNU ddrescue manual"
    url: "https://www.gnu.org/software/ddrescue/manual/ddrescue_manual.html"
    publisher: "GNU Project"
    accessed: 2026-08-07
    tier: 1
  - title: "rsnapshot"
    url: "https://rsnapshot.org/rsnapshot/docs/docbook/rest.html"
    publisher: "rsnapshot project"
    accessed: 2026-08-07
    tier: 2
symptoms:
  - symptom: "rsync created a directory inside the destination instead of copying its contents"
    anchor: "1-the-trailing-slash"
  - symptom: "rsync --delete removed files from the wrong side"
    anchor: "2-delete-pointed-the-wrong-way"
---

> **Before you read.** Ask an organisation whether it has backups and the answer
> is always yes. Ask when somebody last restored one and the answer is usually a
> pause.
>
> Those are different questions, and only one of them matters, because the
> backup is not the deliverable. The **restore** is. Everything before it is
> preparation for an event that has not been rehearsed.
>
> So: **what could be wrong with a backup that runs every night, reports success,
> and has done for two years?**

Quite a lot, and none of it is visible from the backup side. The archive could be
empty. It could be missing the database because that file was locked. It could be
missing SELinux contexts, so it restores and does not work. It could be fine and
take eleven hours to restore, which for a four-hour outage target is the same as
being broken.

Every one of those is discovered by restoring, and by nothing else.

### Some words you will need

<dl class="terms">
<dt>full backup</dt>
<dd>A complete copy of everything. Slow to make, simple to restore.</dd>
<dt>incremental</dt>
<dd>Only what changed since the <em>last backup of any kind</em>. Small, and a restore needs the whole chain.</dd>
<dt>differential</dt>
<dd>Everything changed since the last <em>full</em>. Grows daily, and a restore needs only two pieces.</dd>
<dt>RPO</dt>
<dd>Recovery point objective: how much data you can afford to lose. Decides backup frequency.</dd>
<dt>RTO</dt>
<dd>Recovery time objective: how long you can afford to be down. Decides backup <em>type</em>.</dd>
</dl>

## What breaks without this

**The restore fails on the day it matters**, which is the only day it is attempted.

**You copy the wrong thing.** `rsync` with and without a trailing slash do
different things, and `--delete` pointed the wrong way removes the data you were
protecting.

**You trust something that is not a backup.** RAID, snapshots, and replication all
feel like safety and none of them survives the thing that actually happens, which
is somebody deleting the wrong directory.

## The three types

| | Full | Incremental | Differential |
| --- | --- | --- | --- |
| Copies | Everything | Changes since the last backup of any kind | Changes since the last **full** |
| Time to back up | Longest | Shortest | Grows through the week |
| Space | Largest | Smallest | Middle |
| Pieces needed to restore | 1 | Full **plus every** incremental | Full **plus one** differential |
| Fails if one piece is corrupt |, | Everything after it is lost | Only that one |

A week, concretely. Full on Sunday, then daily:

- **Incremental:** Monday holds Monday's changes, Tuesday holds Tuesday's. To
  restore Thursday you need Sunday, Monday, Tuesday, Wednesday, Thursday, five
  pieces, in order, all intact.
- **Differential:** Monday holds Monday, Tuesday holds Monday and Tuesday,
  Thursday holds everything since Sunday. To restore Thursday you need Sunday and
  Thursday. **Two pieces.**

**The choice is RTO against storage.** Incremental is cheapest to run and slowest
and riskiest to restore. Differential costs more space each day and restores from
two files. If nobody has stated an RTO, that conversation is the actual task and
the backup design follows from it.

## rsync

`rsync` copies a tree, and copies only what changed. That second part is why it
beats `cp` for anything repeated: the second run transfers almost nothing.

```
rsync -av /srv/data/ /backup/data/
```

| Flag | Does |
| --- | --- |
| `-a` | Archive: recursive, and preserves permissions, times, symlinks, ownership |
| `-v` | Verbose |
| `-z` | Compress in transit. For networks, not local disks. |
| `-P` | Progress, and resume partial transfers |
| `--delete` | Remove things from the destination that are gone from the source |
| `--dry-run` / `-n` | Change nothing, report what would happen |
| `--exclude=` | Skip matching paths |
| `--link-dest=` | Hard-link unchanged files to a previous backup |

**`-a` is the one to use by default.** Without it you get files with today's
timestamps and your ownership, which makes the copy useless as a backup and
useless for incremental comparison, because rsync decides what changed partly
from timestamps.

### The trailing slash

<details class="predict">
<summary><code>rsync -a source dest/</code> and <code>rsync -a source/ dest/</code> differ by one character. What does each produce?</summary>

```bash
# Debian 13 (trixie), x86_64
$ cd /tmp; echo '--- without a trailing slash ---'; rsync -a source dest-a/; find dest-a; echo '--- with one ---'; rsync -a source/ dest-b/; find dest-b
--- without a trailing slash ---
dest-a
dest-a/source
dest-a/source/reports
dest-a/source/reports/q3.txt
dest-a/source/reports/q4.txt
dest-a/source/index.txt
--- with one ---
dest-b
dest-b/reports
dest-b/reports/q3.txt
dest-b/reports/q4.txt
dest-b/index.txt
```

**Without the slash, you copied the directory.** `dest-a` now contains a
`source` directory, and the files are one level deeper than you probably wanted.

**With the slash, you copied the contents.** `dest-b` holds `reports/` and
`index.txt` directly.

The rule: **a trailing slash on the source means "the contents of", and no slash
means "this directory".** The destination's trailing slash makes no difference at
all, which is why people assume the source's does not either.

Neither is wrong and both are useful. It matters because the mistake is silent
and compounds: a nightly job without the slash creates
`/backup/data/data/data/...` one level deeper each night, or, much worse,
combined with `--delete` it deletes everything already in the destination
because none of it matches the new, deeper layout.

The habit that removes the problem: **`--dry-run` the first time you write any
rsync command**, and read where the paths land.

</details>

### `--delete`, safely

`--delete` makes the destination match the source exactly, which means removing
anything the source no longer has. The destination below contains `old.txt`, which
the source does not.

<details class="predict">
<summary>The command carries <code>--delete</code> **and** <code>--dry-run</code>. What does <code>ls dest-a</code> show afterwards, and what does the first line of output warn you about?</summary>

```bash
# Debian 13 (trixie), x86_64
$ cd /tmp; printf 'stale\n' > dest-a/old.txt; echo '--- what WOULD --delete remove? ---'; rsync -a --delete --dry-run --itemize-changes source/ dest-a/; echo '--- nothing has changed yet ---'; ls dest-a
--- what WOULD --delete remove? ---
*deleting   old.txt
>f+++++++++ index.txt
cd+++++++++ reports/
>f+++++++++ reports/q3.txt
>f+++++++++ reports/q4.txt
--- nothing has changed yet ---
old.txt
```

</details>

**`--dry-run` with `--itemize-changes` is the whole safety story.** It lists
`*deleting old.txt` before anything happens, and `ls` afterwards confirms nothing
did.

The itemize codes are worth a glance: `>f` means a file is being sent, `cd` means
a directory is being created, `*deleting` is self-explanatory. The `+++++++++`
means every attribute is new, so this is a first copy.

**`--delete` makes the destination match the source**, which is what you want for
a mirror and is dangerous in exactly one situation: if the source is empty or
unmounted, "match the source" means "delete everything". A backup job whose source
is an unmounted NFS share will faithfully empty the backup.

Two protections worth having: `--max-delete=100`, which aborts if the run would
remove more than expected, and checking that the source is mounted before the job
runs at all.

<details class="deeper">
<summary>If you already administer Linux: how rsync decides what changed, and cheap versioned backups</summary>

**By default rsync compares size and modification time**, not contents. That
is fast and it is why a second run is nearly instant. It also means a file
changed without its mtime moving (restored from an archive, touched by a badly
behaved tool, or deliberately) is not copied. `-c` forces a checksum
comparison, which is correct and much slower, and is what belongs in a
periodic verification run rather than the nightly one.

**`--link-dest` is the feature that makes rsync a real backup tool.** Point it at
the previous backup and unchanged files become **hard links** to it rather than
copies:

```
rsync -a --delete --link-dest=/backup/2026-08-06 /srv/data/ /backup/2026-08-07/
```

Every dated directory looks like a complete full backup and browses like one, but
only changed files consume space. Thirty daily snapshots of a mostly-static tree
cost barely more than one. `rsnapshot` automates the rotation around exactly this.

The caveat that matters: hard links mean the copies **share inodes**, so changing
permissions on a file in one snapshot changes them in all of them, and a
filesystem corruption affecting one block affects every snapshot containing that
file. It is space-efficient versioning, not independent copies.

**Over SSH**, rsync uses it by default for remote paths, and `-e 'ssh -i
/root/.keys/backup'` picks a specific key. On the far side, a `command=`
restriction in `authorized_keys` limits that key to running rsync only, which
is how you give a backup server pull access without giving it a shell.

**`--partial --append-verify`** for large files over unreliable links, so an
interrupted transfer resumes rather than restarting. `-P` is shorthand for
`--partial --progress`.

**Bandwidth and load:** `--bwlimit=5000` caps throughput in KB/s, which stops a
backup saturating the link during business hours.

</details>

<details class="deeper">
<summary>If you already administer Linux: what a backup of a running database is worth, and the two ways to make it worth something</summary>

`rsync` copies files one at a time, over a period. If the data changes while
it runs, the result is a set of files that never existed together in that
state, and for a database that is not a slow backup, it is a corrupt one.

**The failure is specific and worth being able to describe.** A database keeps a
data file and a write-ahead log, and consistency depends on their relationship. Copy
the data file at 02:00 and the log at 02:04 and you have a data file from before a
transaction and a log from after it. The restore either refuses to start or, worse,
starts and is subtly wrong.

Two mechanisms fix it, and they are not interchangeable.

**Ask the application.** `pg_dump`, `mysqldump`, `mongodump` and their equivalents
produce a point-in-time consistent export because the database itself coordinates
it. This is the correct answer for anything under a few hundred gigabytes: the
output is portable across versions and platforms, and it is verifiable by restoring
it.

Freeze the filesystem underneath. An LVM or filesystem snapshot is atomic, so
everything in it is from the same instant. The sequence is:

```
psql -c "SELECT pg_backup_start('nightly');"
lvcreate -s -n dbsnap -L 20G /dev/vg0/dbdata
psql -c "SELECT pg_backup_stop();"
mount -o ro /dev/vg0/dbsnap /mnt/snap && rsync -a /mnt/snap/ /backup/
```

The database call brackets the snapshot so the engine knows to flush and to expect
a copy. **`fsfreeze -f /path` does the filesystem-level equivalent** for
applications with no such hook, and must be held for as little time as possible
because writes block for the duration.

**The snapshot is not the backup.** It lives on the same volume group, so it dies
with the disk, the controller, or the machine. It is a consistent *source* to copy
from, and the copy is the backup. Treating a snapshot as a backup is the same
category error as treating RAID as one.

**And the part that decides whether any of this worked:** restore it. Not
"check the file exists", restore into a scratch instance and run a query. A
backup nobody has restored is a hypothesis, and the failure modes above all
produce files of plausible size that fail only at restore time.

</details>

## dd, and block-level copies

`dd` copies bytes, knowing nothing about files or filesystems. That makes it
the tool for whole devices, boot sectors, and disk images, and a poor tool for
anything rsync can do.

```bash
# AlmaLinux 10.2, aarch64
$ echo '--- dd reports what it did ---'; dd if=/dev/zero of=$DEV0 bs=1M count=64
--- dd reports what it did ---
64+0 records in
64+0 records out
67108864 bytes (67 MB, 64 MiB) copied, 0.0590037 s, 1.1 GB/s
```

`if=` input file, `of=` output file, `bs=` block size, `count=` how many blocks.

**`bs` matters for speed.** The default is 512 bytes, which means one system call
per half-kilobyte. `bs=4M` is dramatically faster on any real transfer.

**`status=progress`** prints a running total, which for a multi-hour disk clone is
the difference between watching a progress figure and wondering whether it has
hung.

And the verification that makes it a backup rather than a hope:

```bash
# AlmaLinux 10.2, aarch64
$ mkfs.ext4 -q -L payroll $DEV0; echo '--- clone the whole device ---'; dd if=$DEV0 of=$DEV1 bs=4M status=none; echo '--- do the two match? ---'; sha256sum $DEV0 $DEV1
--- clone the whole device ---
--- do the two match? ---
b92836ae943988944dcf3daa909c1078515f6ba1c5d599106a69e36439aac002  /dev/loop0
b92836ae943988944dcf3daa909c1078515f6ba1c5d599106a69e36439aac002  /dev/loop1
```

**Identical checksums, so the copy is provably byte-for-byte.** That is the shape
of every verification in this lesson: produce a number from the original, produce
a number from the copy, compare. Anything less is an assumption.

`dd` has no undo and no confirmation. `if=` and `of=` are two characters apart
and reversing them overwrites the source with the destination. The old
nickname is "disk destroyer" and it is earned. Read the line twice, and prefer
`lsblk` to confirm the device names immediately before.

`ddrescue` rather than `dd` for a failing disk. `dd` stops or stalls on a read
error; `ddrescue` skips, records what it could not read in a map file, and
comes back for the bad regions afterwards with retries. On a dying disk that
difference is most of your data.

<details class="deeper">
<summary>If you already administer Linux: what a consistent backup actually requires</summary>

Copying a file that something is writing gives you a file that was never in that
state. For a database, that is a backup that restores into corruption, and it is
the most common way a backup that "works" turns out not to.

**Use the application's own tool where one exists.** `pg_dump`, `mysqldump`,
`mongodump` produce a consistent view while the service runs, because the database
knows how to give you one and the filesystem does not. A `tar` of
`/var/lib/postgresql` on a running server is not a backup of that database.

**Or freeze the filesystem underneath.** An LVM snapshot from lesson 14 gives you
a frozen block-level view to copy at leisure:

```
lvcreate -s -n db-snap -L 20G /dev/vg/db
mount -o ro /dev/vg/db-snap /mnt/snap
# back up /mnt/snap, then
lvremove -f /dev/vg/db-snap
```

The snapshot is instant; the backup takes as long as it takes; the database never
stops. Two caveats from that lesson apply directly: size the snapshot for the
write volume during the window, because a full snapshot is **dropped** and takes
your backup with it, and remove it as soon as you are done.

`fsfreeze -f /mount` flushes and freezes a filesystem for the moment a
hypervisor or SAN takes its own snapshot, and `-u` thaws it. Anything writing
blocks until you do, so the window is measured in seconds.

**Application-aware ordering matters too.** A web application's files and its
database are one system; backing them up hours apart gives you a restore where
the schema and the code disagree. Quiesce, snapshot both, release.

**Encryption and the key.** An encrypted offsite backup is correct and creates a
new single point of failure: the key. A key stored only on the machine being
backed up is not a key you have. Escrow it somewhere the disaster does not reach,
and test decrypting with the escrowed copy rather than the local one.

</details>

## What is not a backup

This deserves saying plainly, because all three feel like protection.

**RAID is not a backup.** It replicates writes, so a deletion is replicated
instantly to every member. It protects against a disk failing and nothing
else, which is the point made at length in lesson 15.

Snapshots are not backups. They live on the same storage as the original, so
they do not survive the array failing, the machine being stolen, or the
filesystem corrupting. They are excellent for "I deleted that an hour ago" and
useless for "the data centre flooded".

Replication is not a backup. It is RAID over a longer wire. Corruption
replicates faithfully and quickly.

The framing that survives: *3-2-1*. Three copies of the data, on two different
kinds of media, one of them offsite. The offsite copy is the one that answers
the question the other two cannot.

Worth adding a modern fourth: **one copy the production system cannot delete.**
Ransomware that takes the machine takes everything the machine can write to,
which includes the backup share it has credentials for. Immutable or
write-once storage, or a pull-based backup where the backup server reaches in
rather than the host pushing out.

<details class="deeper">
<summary>If you already administer Linux: testing a restore properly, and what to measure</summary>

A restore test that consists of extracting one file proves the archive is not
empty. It does not prove much else. What to actually verify, in rough order of
how often each one is the thing that fails:

**Does the restored system work**, not merely exist? Restore to a scratch
machine or VM, start the service, and exercise it. A web root restored without
SELinux contexts, a database restored without its ownership, a config restored
with the wrong permissions on a private key, all of these produce files that
are present and a service that does not run.

How long did it take? Time it. This is the number nobody has and everybody is
asked for during an incident, and it is frequently a large multiple of what
people assume. A restore that takes eleven hours does not meet a four-hour
RTO, and the backup design has to change rather than the expectation.

**What was missing?** Compare file counts and a checksum manifest:

```
find /srv/data -type f | wc -l
find /restore/data -type f | wc -l
cd /srv/data && find . -type f -exec sha256sum {} + | sort > /tmp/orig.sha
cd /restore/data && find . -type f -exec sha256sum {} + | sort > /tmp/rest.sha
diff /tmp/orig.sha /tmp/rest.sha
```

Generating the manifest **at backup time** and storing it alongside the
archive is better still, because then you can verify a restore without access
to the original, which is the situation you will actually be in.

**Was anything excluded that mattered?** Read the exclude list during the test,
not during the incident. `/var/lib/docker` and `/proc` are excluded for good
reasons; the application's upload directory that somebody added to the list in
2023 is not.

**Write down the result with a date.** "Last successful restore test: 12 June,
took 3h40m, database and web root verified" is the sentence that makes a backup
programme real, and it is what an auditor is asking for when they ask about
backups.

</details>

## Across distributions

The tools are the same everywhere; only the packaging differs.

| | RHEL family | Debian family |
| --- | --- | --- |
| rsync | `rsync` | `rsync` |
| ddrescue | `ddrescue`, via EPEL | `gddrescue` |
| Common backup tools | `bacula`, `amanda`, `restic`, `borgbackup` | same |
| Snapshot source | LVM, or Btrfs on SUSE | LVM, or Btrfs |

**`gddrescue` on Debian is a real trap**: the package is `gddrescue` and the
command is `ddrescue`, and there is a different, older, worse tool called `dd_rescue`
with an underscore. Install `gddrescue`, run `ddrescue`.

For anything beyond a single machine, **`restic` and `borgbackup`** are what most
people should reach for now: deduplicating, encrypted, verifiable, and with a real
`check` command. Neither is on the objective list and both are worth knowing.

## Prove it

Before trusting any backup:

```bash
# Does the archive contain what you think
tar -tzf backup.tar.gz | wc -l
tar -tzf backup.tar.gz | grep -c 'important/'

# Is it intact
gzip -t backup.tar.gz && echo "checksum ok"

# Restore it somewhere harmless and compare
mkdir /tmp/verify && tar -xzf backup.tar.gz -C /tmp/verify
diff -r /srv/data /tmp/verify/srv/data | head

# And the one that counts
# ... start the service against the restored data and use it
```

**The last line has no command because it is not one.** Everything above proves
bytes survived; only running the thing proves the backup is useful. Put it in the
calendar, do it quarterly, write down how long it took.

## What trips people up

### 1. The trailing slash

`rsync -a source dest/` copies the directory; `rsync -a source/ dest/` copies its
contents. The source's slash is what matters and the destination's is ignored.

`--dry-run` the first time, every time. The failure is silent and it compounds
nightly.

### 2. `--delete` pointed the wrong way

`rsync -a --delete /backup/ /srv/data/` makes production match the backup, which
is a restore. Swap the arguments and it makes the backup match production, which
is a mirror. They look almost identical on the command line.

Always `--dry-run` first. `--max-delete=100` limits the damage from the case
nobody predicted.

### 3. A backup nobody has restored

Covered throughout. Two years of green ticks is evidence that a script exits
zero.

### 4. `dd` with `if` and `of` swapped

There is no confirmation and no undo. `lsblk` immediately before, read the line
twice, and be more careful than usual when tired.

### 5. Backing up a running database by copying its files

You get a file that was never in that state, which restores into corruption.

Use `pg_dump` or `mysqldump`, or snapshot the filesystem underneath, or stop the
service. Copying a live database's data directory is the classic backup that
passes every test except the one that matters.

## Work it through

A ransomware incident. A file server's data is encrypted. You are asked what can
be recovered.

The setup: RAID 6 on the server; hourly LVM snapshots kept for two days; nightly
rsync to a NAS mounted at `/mnt/backup` with `--delete`; monthly full backup to
tape, offsite, last taken eighteen days ago.

Work out what survives before reading on.

**RAID 6 gives you nothing.** It replicates writes. Every encrypted block was
written to all the members faithfully and immediately. The array is perfectly
healthy and perfectly encrypted.

The LVM snapshots may survive, and probably do not. They are on the same
volume group, so anything with root on that machine can remove them, and
ransomware routinely does exactly that, because it is a well-known recovery
route. If they were missed, hourly snapshots give you an excellent recovery
point. Check before assuming either way; this is the first thing to look at
because it is the cheapest win.

The NAS is the painful one. It was mounted, the server had write access, and
the nightly rsync ran with `--delete`. So either the ransomware encrypted it
directly over the mount, or the backup job ran after the encryption and
faithfully replicated the encrypted files, deleting the good ones to match. A
mounted, writable backup destination is inside the blast radius.

The tape is the answer, and it is eighteen days old. So the recovery point is
eighteen days of lost work, and the recovery time is however long a tape
restore takes, which nobody has measured.

Now the design conclusions, which are the point of the exercise.

Offsite mattered and offline mattered more. The tape survived because the
compromised machine could not reach it. That is the property doing the work,
not the medium.

A mounted backup share is not a backup. Anything the production system can
write to, an attacker on that system can write to. The fix is a **pull**
model, the backup server reaches in over SSH with a restricted key, or
immutable storage with a retention lock the client cannot override.

Retention decides the recovery point, and monthly is a policy decision nobody
made deliberately. Eighteen days of loss is the direct consequence of a tape
schedule that was probably set by how many tapes were in the budget.

And the number nobody has: how long does a full tape restore take? If it is
three days, the RTO conversation should have happened before the incident, not
during it.

The habit worth taking from all of this: **ask what could delete the backup.**
Not what could fail, what could *delete* it. RAID, snapshots, and a mounted
share all answer "the same thing that destroyed the original", and that is the
question that separates a copy from a backup.

## Try it

Optional, on any machine. Nothing here touches real data if you use `/tmp`.

1. `mkdir -p /tmp/src/sub && echo one > /tmp/src/a.txt && echo two >
   /tmp/src/sub/b.txt`.
2. `rsync -av /tmp/src /tmp/dest1/` then `find /tmp/dest1`. Note the extra level.
3. `rsync -av /tmp/src/ /tmp/dest2/` then `find /tmp/dest2`. Compare.
4. `echo stale > /tmp/dest2/old.txt`, then
   `rsync -a --delete --dry-run -i /tmp/src/ /tmp/dest2/`. Read the `*deleting`
   line, and confirm the file is still there afterwards.
5. Run it without `--dry-run` and confirm it is gone.
6. `dd if=/dev/urandom of=/tmp/orig.img bs=1M count=8`, copy it with `dd`, then
   `sha256sum` both and compare.
7. Time a restore of something real, and write the number down.

**Verification step.** You have it when you can write an rsync command for an
unfamiliar pair of paths, predict exactly where the files land, and prove it with
`--dry-run` before running it for real.

## Check yourself

<details class="qa">
<summary>What is the difference between incremental and differential, and which restores faster?</summary>

**Incremental** copies what changed since the last backup **of any kind**. So each
one is small, and restoring means applying the full plus *every* incremental since
it, in order.

**Differential** copies what changed since the last **full**. Each one grows
through the week, and restoring needs only two pieces: the full and the most
recent differential.

**Differential restores faster**, and more reliably, a corrupt incremental
invalidates everything after it in the chain, while a corrupt differential
costs you only that one.

The trade is storage and backup-window time, which incremental wins. Choose from
the RTO: if being down for a long time is expensive, buy the storage.

</details>

<details class="qa">
<summary><code>rsync -a /srv/data /backup/</code> and <code>rsync -a /srv/data/ /backup/</code>. What does each produce?</summary>

**Without the trailing slash**, `/backup/data/` is created and the files land
inside it. You copied the directory.

**With the trailing slash**, the files land directly in `/backup/`. You copied
the contents.

The **source's** trailing slash is what decides this; the destination's makes no
difference, which is why people assume neither matters.

The consequence of getting it wrong in a nightly job is worse than one extra
level: without the slash it nests a level deeper each run, and combined with
`--delete` it can remove everything already there because none of it matches the
new layout.

`--dry-run` the first time you write any rsync command.

</details>

<details class="qa">
<summary>Give three things RAID does not protect against, and say what does.</summary>

**Deletion.** RAID replicates writes, so removing a file removes it from every
member instantly.

**Corruption**, whether from a bug, a bad controller, or ransomware. It is
faithfully mirrored to every copy.

Anything affecting the whole machine or site, theft, fire, flood, a power
event that takes the backplane.

RAID protects against exactly one thing: **a disk failing**. It buys uptime
through a hardware fault.

What covers the rest is a backup that is separate from the machine, and
specifically one the machine cannot itself delete. 3-2-1 (three copies, two
media, one offsite) with a modern addition: one copy production has no write
access to.

</details>

<details class="qa">
<summary>Why is copying a running database's files not a backup, and what are two correct approaches?</summary>

**Because the files change while you copy them.** You get a set of files that
never existed together in that state (some from before a transaction, some
from after) and restoring them produces a database that is internally
inconsistent, which is corruption rather than an old copy.

Approach one: the application's own tool. `pg_dump`, `mysqldump`, and their
equivalents produce a consistent view while the service runs, because the
database knows how to give you one and the filesystem does not.

Approach two: freeze the storage. An LVM snapshot gives you an instant frozen
block-level view; back that up at leisure and remove it afterwards. `fsfreeze`
does the equivalent for the moment a hypervisor takes its own snapshot.

Stopping the service also works and is rarely acceptable.

The failure mode is what makes this dangerous: the backup completes, reports
success, and is worthless, and you find out during the restore.

</details>

<details class="qa">
<summary>A nightly rsync to a mounted NAS reports success for two years. Name two things that could still be wrong.</summary>

Several, and any two of these:

**The restore has never been tested.** Green ticks prove a script exited zero.
They say nothing about whether the data is complete, whether it restores into a
working system, or how long that takes.

The destination is writable by the source, so anything that compromises the
server, ransomware in particular, reaches the backup too. A mounted share with
`--delete` will also faithfully replicate an encryption event.

A wrong `--delete` or trailing slash could have quietly reshaped what is
stored, and nobody looks at a backup that reports success.

Exclusions nobody has re-read, so a directory added to the application in 2023
has never been backed up.

**Consistency**, if it includes a live database's files, it restores into
corruption.

**No offsite copy**, so it survives a disk failure and not a fire.

The test that catches nearly all of them is the same one: restore it somewhere
else, start the service, use it, and time how long that took.

</details>

## References

- [rsync(1)](https://manpages.debian.org/stable/rsync/rsync.1.en.html) - Debian Project. Accessed 2026-08-07.
- [dd(1)](https://man7.org/linux/man-pages/man1/dd.1.html) - Linux man-pages project. Accessed 2026-08-07.
- [sha256sum(1)](https://man7.org/linux/man-pages/man1/sha256sum.1.html) - Linux man-pages project. Accessed 2026-08-07.
- [GNU ddrescue manual](https://www.gnu.org/software/ddrescue/manual/ddrescue_manual.html) - GNU Project. Accessed 2026-08-07.
- [rsnapshot](https://rsnapshot.org/rsnapshot/docs/docbook/rest.html) - rsnapshot project. Accessed 2026-08-07.

Every block above with a distribution and architecture header was captured by running the command on a Debian 13 (trixie) container and an AlmaLinux 10.2 container. Blocks without one are illustrative.
