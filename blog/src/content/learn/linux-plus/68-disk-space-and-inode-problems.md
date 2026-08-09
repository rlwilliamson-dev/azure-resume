---
title: "The disk is full and du disagrees with df"
description: "Two commands answer the question differently because they are measuring different things. Learning which one to believe, and why a filesystem that is one percent full can refuse to create a file, is most of what disk-space troubleshooting is."
track: "linux-plus"
level: "working"
order: 690
objectives:
  - "Explain why df and du disagree, and which one is right"
  - "Find a deleted-but-open file and reclaim its space without a reboot"
  - "Recognise inode exhaustion from an ENOSPC on a nearly empty filesystem"
  - "Find what is actually consuming space, by size and by count"
  - "Explain reserved blocks and why root can write when nobody else can"
prerequisites: ["disks-partitions-and-filesystems", "finding-files"]
tags: ["linux", "linux-plus", "troubleshooting", "storage", "filesystems"]
updated: 2026-08-09
draft: false
examObjectives:
  - exam: "xk0-006"
    domain: "5.0"
    objective: "5.2"
sources:
  - title: "df(1)"
    url: "https://man7.org/linux/man-pages/man1/df.1.html"
    publisher: "man7.org"
    accessed: 2026-08-09
    tier: 1
  - title: "du(1)"
    url: "https://man7.org/linux/man-pages/man1/du.1.html"
    publisher: "man7.org"
    accessed: 2026-08-09
    tier: 1
  - title: "lsof(8)"
    url: "https://man7.org/linux/man-pages/man8/lsof.8.html"
    publisher: "man7.org"
    accessed: 2026-08-09
    tier: 1
  - title: "unlink(2)"
    url: "https://man7.org/linux/man-pages/man2/unlink.2.html"
    publisher: "man7.org"
    accessed: 2026-08-09
    tier: 1
  - title: "tune2fs(8)"
    url: "https://man7.org/linux/man-pages/man8/tune2fs.8.html"
    publisher: "man7.org"
    accessed: 2026-08-09
    tier: 1
symptoms:
  - symptom: "df reports the disk full but du finds nothing using the space"
    anchor: "the-space-that-is-not-in-any-file"
  - symptom: "No space left on device on a filesystem with free space"
    anchor: "running-out-of-inodes-instead-of-space"
  - symptom: "Deleting a log file does not free any space"
    anchor: "the-space-that-is-not-in-any-file"
---

> **Before you read.** The alert says the disk is full. You log in, run `df`,
> and it agrees: 80% used, climbing. You run `du` to find the culprit and it
> reports that the filesystem contains almost nothing.
>
> **Both commands are working correctly.** They are answering different
> questions, and the gap between the two answers is the diagnosis.

Disk-space problems are common, and they are one of the few troubleshooting
areas where the tools will hand you the answer in about thirty seconds if you
know which two to run and in what order. The reason people find them
frustrating is that the obvious command is often the wrong one.

### Some words you will need

<dl class="terms">
<dt>inode</dt>
<dd>The structure holding a file's metadata and the pointers to its data. Every file uses exactly one.</dd>
<dt>link count</dt>
<dd>How many directory entries point at an inode. When it reaches zero and nothing has it open, the space is freed.</dd>
<dt>file descriptor</dt>
<dd>A process's open handle to a file. Keeps the inode alive regardless of directory entries.</dd>
<dt>unlink</dt>
<dd>What <code>rm</code> actually does: remove the name, not the data.</dd>
<dt>reserved blocks</dt>
<dd>A percentage of the filesystem only the superuser may write into.</dd>
<dt>sparse file</dt>
<dd>A file with holes: it reports a large size but only occupies the blocks actually written.</dd>
<dt>ENOSPC</dt>
<dd>The error behind "No space left on device". Means out of blocks <em>or</em> out of inodes.</dd>
</dl>

## What breaks without this

**Writes fail everywhere at once.** A full filesystem is not a gradual
degradation. Databases stop committing, logs stop being written, and package
operations abort partway.

**Deleting the obvious file changes nothing.** The space stays gone, so the
next instinct is to reboot, which does work and teaches you nothing.

**The machine boots into emergency mode.** A full `/` can prevent services
starting at all, which turns a disk problem into an outage.

**Nobody can log in.** Session setup needs to write, so a full `/` or `/home`
can lock out the people who would fix it.

**And the same alert fires again next week**, because the file that filled the
disk is still being written to by something nobody identified.

## Two commands, two questions

Start here, because everything else in this lesson follows from it.

**`df` asks the filesystem how many blocks are allocated.** It reads the
filesystem's own accounting, so it counts every block in use whether or not a
name points at it.

**`du` walks the directory tree and adds up the files it finds.** It counts
what it can see by name.

Most of the time those produce the same number:

```bash
# AlmaLinux 10.2, aarch64
$ mkfs.ext4 -q $DEV0; mkdir -p /mnt/d; mount $DEV0 /mnt/d; dd if=/dev/zero of=/mnt/d/big.log bs=1M count=40 status=none; echo "--- df and du agree ---"; df -h /mnt/d | tail -1; du -sh /mnt/d
--- df and du agree ---
/dev/loop0       55M   41M   11M  80% /mnt/d
41M	/mnt/d
```

41M by both counts. Nothing to explain.

## The space that is not in any file

Now the same filesystem, except a process opens the log file before it is
deleted. This is not a contrived situation: it is precisely what happens when
somebody clears a log that a running daemon still has open.

<details class="predict">
<summary>A 40 MB file is opened by a running process, then deleted with <code>rm</code>. What does <code>du</code> report, and what does <code>df</code> report?</summary>

```bash
# AlmaLinux 10.2, aarch64
$ mkfs.ext4 -q $DEV0; mkdir -p /mnt/d; mount $DEV0 /mnt/d; dd if=/dev/zero of=/mnt/d/big.log bs=1M count=40 status=none; sleep 300 < /mnt/d/big.log & sleep 1; rm /mnt/d/big.log; echo "--- du now sees an empty filesystem ---"; du -sh /mnt/d; echo "--- but df still says the space is gone ---"; df -h /mnt/d | tail -1
--- du now sees an empty filesystem ---
13K	/mnt/d
--- but df still says the space is gone ---
/dev/loop0       55M   41M   11M  80% /mnt/d
```

</details>

**13K against 41M.** That is the entire phenomenon, and both numbers are
correct.

**`rm` does not delete a file.** The system call is called `unlink`, and the
name is accurate: it removes a directory entry. The kernel frees the data only
when **both** the link count is zero **and** no process has the file open.

Here the link count is zero, so `du` cannot find the file: there is no name to
walk to. But a process still holds a descriptor, so the inode and all 40 MB of
its blocks remain allocated, which is what `df` reports.

**The rule that follows:** when `df` and `du` disagree, `df` is right about the
space and `du` is right about the files. The difference is space held by
something with no name.

### Finding it

`lsof` lists open files, and `+L1` restricts that to files with a link count
below 1, which is exactly the set you want:

```bash
# AlmaLinux 10.2, aarch64
$ mkfs.ext4 -q $DEV0; mkdir -p /mnt/d; mount $DEV0 /mnt/d; dd if=/dev/zero of=/mnt/d/big.log bs=1M count=40 status=none; sleep 300 < /mnt/d/big.log & sleep 1; rm /mnt/d/big.log; echo "--- lsof names the process still holding it ---"; lsof +L1 /mnt/d 2>/dev/null
--- lsof names the process still holding it ---
COMMAND PID USER   FD   TYPE DEVICE SIZE/OFF NLINK NODE NAME
sleep    41 root    0r   REG    7,0 41943040     0   12 /mnt/d/big.log (deleted)
```

Read the columns, because each one is part of the answer:

| Column | Value | Means |
| --- | --- | --- |
| `COMMAND` / `PID` | `sleep` / `41` | The process to deal with |
| `FD` | `0r` | File descriptor 0, open for reading |
| `SIZE/OFF` | `41943040` | 40 MB, still allocated |
| `NLINK` | `0` | No name points at it. This is why `du` cannot see it |
| `NAME` | `... (deleted)` | The path it had when it was opened |

**`NLINK 0` and `(deleted)` are the confirmation.** If `lsof +L1` returns
nothing, this is not your problem and you should be looking elsewhere.

### Getting the space back

The obvious fix is to restart the process holding the descriptor, and usually
that is the right one: the space is released the moment the last descriptor
closes.

When restarting is expensive, there is another way. The descriptor is reachable
through `/proc/<pid>/fd/`, and truncating it frees the blocks while the process
keeps running:

<details class="predict">
<summary>The process is left running and its descriptor is truncated with <code>: &gt; /proc/&lt;pid&gt;/fd/0</code>. What does <code>df</code> say afterwards?</summary>

```bash
# AlmaLinux 10.2, aarch64
$ mkfs.ext4 -q $DEV0; mkdir -p /mnt/d; mount $DEV0 /mnt/d; dd if=/dev/zero of=/mnt/d/big.log bs=1M count=40 status=none; sleep 300 < /mnt/d/big.log & P=$!; sleep 1; rm /mnt/d/big.log; echo "--- space still held ---"; df -h /mnt/d | tail -1; echo "--- truncate the descriptor without killing the process ---"; : > /proc/$P/fd/0; df -h /mnt/d | tail -1
--- space still held ---
/dev/loop0       55M   41M   11M  80% /mnt/d
--- truncate the descriptor without killing the process ---
/dev/loop0       55M   14K   51M   1% /mnt/d
```

</details>

**41M to 14K, and the process never stopped.** 80% to 1% in one command.

**Understand what this does before you reach for it.** The data is discarded
immediately. If the process is a database writing its journal, you have just
destroyed the journal. It is the correct move for a log file that has already
been rotated and is being written to by mistake, and the wrong move for
anything you might have wanted to read.

<details class="deeper">
<summary>If you already administer Linux: why this keeps happening, and the fix that stops it recurring</summary>

The deleted-but-open file is nearly always the same story told about a
different service, and the story is worth knowing because the real fix is
upstream of the symptom.

**The classic sequence:** a log file grows, somebody notices the disk filling,
they run `rm /var/log/something.log` or `> /var/log/something.log` badly, and
the daemon that had it open keeps writing to the same descriptor. The daemon
does not know or care that the name is gone: it holds an inode, and it keeps
appending at its current offset.

Why `truncate` and `> file` behave differently here is worth being precise
about:

- `rm file` unlinks the name. The daemon writes on into an inode nobody can
  reach, and the space is unrecoverable until the descriptor closes.
- `> file` or `truncate -s 0 file` empties the file **in place**. The name
  survives, the inode survives, the daemon's descriptor stays valid, and the
  space is genuinely freed. This is the safe version.
- Except for a daemon that opened the file with `O_APPEND` versus one that
  tracks its own offset: a non-append writer that is 2 GB into a file you just
  truncated will write its next record at offset 2 GB, producing a **sparse
  file** that reports 2 GB and occupies almost nothing. Confusing, mostly
  harmless, and the reason `ls -l` and `du` disagree afterwards.

The actual fix is log rotation, configured properly. `logrotate` handles this
with two mechanisms and it is worth knowing which you have:

- **`create`** (the default): rename the old file, create a new one, then signal
  the daemon to reopen. Requires `postrotate` to send the signal, usually
  `HUP`. If the signal is missing or the daemon ignores it, you get exactly the
  problem in this lesson, on a schedule.
- **`copytruncate`**: copy the file's contents aside, then truncate the original
  in place. No signal needed, works with daemons that cannot reopen, and races
  with anything written between the copy and the truncate. Use it when you have
  no choice.

Journald sidesteps the whole class of problem by managing its own storage with
`SystemMaxUse=` in `journald.conf` and vacuuming itself. If your logs are in
the journal, `journalctl --vacuum-size=500M` is the supported way to reclaim
space, and manually deleting files under `/var/log/journal/` is not.

One more source of nameless space, since `lsof +L1` will not find it: a file
hidden underneath a mount point. If something wrote to `/var/log` before the
real `/var/log` filesystem was mounted over it, those files still occupy the
parent filesystem and no ordinary walk can see them. Bind-mount the parent
somewhere else to look:

```bash
mount --bind / /mnt/root-real
du -sh /mnt/root-real/var/log
umount /mnt/root-real
```

That is a genuinely obscure cause and it accounts for a small number of
extremely baffling tickets.

</details>

## Running out of inodes instead of space

The second way a filesystem refuses to write has nothing to do with space at
all.

**Every file consumes one inode**, and on ext4 the number of inodes is fixed
when the filesystem is created. Run out of them and the filesystem is full in
the only sense that matters, whatever `df` says about blocks.

<details class="predict">
<summary>A filesystem is created with 256 inodes and then filled with empty files. It is 1% full by space. What happens, and what does <code>df -h</code> report?</summary>

```bash
# AlmaLinux 10.2, aarch64
$ mkfs.ext4 -q -N 256 $DEV0; mkdir -p /mnt/d; mount $DEV0 /mnt/d; i=0; while [ $i -lt 400 ]; do if ! (: > /mnt/d/f$i) 2>/dev/null; then break; fi; i=$((i+1)); done; echo "created $i files"; echo "--- space? plenty ---"; df -h /mnt/d | tail -1; echo "--- inodes? none ---"; df -i /mnt/d | tail -1
created 245 files
--- space? plenty ---
/dev/loop0      6.9M   18K  6.3M   1% /mnt/d
--- inodes? none ---
/dev/loop0        256   256     0  100% /mnt/d
```

</details>

**1% full by space. 100% full by inodes.** `df -h` alone would tell you
everything is fine.

And here is the error, which is the part that misleads people:

```bash
# AlmaLinux 10.2, aarch64
$ mkfs.ext4 -q -N 256 $DEV0; mkdir -p /mnt/d; mount $DEV0 /mnt/d; i=0; while [ $i -lt 400 ]; do if ! (: > /mnt/d/f$i) 2>/dev/null; then break; fi; i=$((i+1)); done; echo "--- and this is the error you get, on a filesystem that is 1% full ---"; touch /mnt/d/one-more
--- and this is the error you get, on a filesystem that is 1% full ---
touch: cannot touch '/mnt/d/one-more': No space left on device
```

**"No space left on device" on a filesystem with 6.3 MB free.** The kernel
returns `ENOSPC` for both conditions and the message only mentions one of them.

So `df -i` belongs in your reflexes right next to `df -h`. Any time you see
ENOSPC, run both. It costs nothing and it eliminates half the possibilities.

What exhausts inodes in real life: a mail queue, a session directory, a cache
with one file per key, a build system that never cleans up, PHP sessions, and
anything that writes one small file per event. The signature is a directory
containing hundreds of thousands of tiny files.

Finding the offender means counting rather than measuring:

```bash
# where are the files, by count rather than by size
sudo find /var -xdev -printf '%h\n' | sort | uniq -c | sort -rn | head -20
```

`-xdev` keeps `find` on one filesystem, which matters: without it you walk into
`/proc`, `/sys`, and every other mount, and the answer is nonsense.

<details class="deeper">
<summary>If you already administer Linux: inode allocation, and why XFS mostly does not have this problem</summary>

**ext4 allocates its inode table at `mkfs` time and never grows it.** The
default is roughly one inode per 16 KB of filesystem, set by `-i` (bytes per
inode) or `-N` (an absolute count). A 100 GB filesystem gets about 6.5 million
inodes, which is generous for ordinary data and nowhere near enough for a
maildir.

This cannot be fixed on a live filesystem. There is no `resize2fs` for the
inode count. Raising it means recreating the filesystem and restoring the
data, which is a genuinely painful discovery to make during an incident. If
you know a filesystem will hold millions of small files, set it at creation:

```bash
mkfs.ext4 -i 4096 /dev/sdb1     # one inode per 4 KB, four times the default
```

XFS allocates inodes dynamically from free space, so it does not have a fixed
ceiling and mostly does not run out until the disk itself is full. That is a
real operational advantage and part of why RHEL defaults to it.

XFS has its own version of the trap, though: by default `inode64` is the mount
option on modern kernels, but a filesystem mounted `inode32` restricts inodes
to the first terabyte, and a large filesystem can then report ENOSPC on inode
allocation with plenty of space free. `xfs_info` shows which you have.

**Both filesystems reserve space for the superuser**, and this catches people
from the other direction. ext4 reserves **5% by default**, which is why a
filesystem can report 100% used to an ordinary user while root can still write,
and why `df` sometimes shows used plus available adding up to less than the
total.

The reservation exists for two good reasons: it leaves room for root to fix a
full disk, and it gives the allocator space to avoid fragmentation. On a 4 TB
data volume, though, 5% is 200 GB set aside for a root user who will never
write there. Check and change it:

```bash
sudo tune2fs -l /dev/sdb1 | grep -i 'reserved block count'
sudo tune2fs -m 1 /dev/sdb1      # reduce to 1 percent
```

**Leave the reservation alone on the root filesystem.** That is the one place
it earns its keep, because it is what lets you log in and clean up rather than
booting from rescue media.

</details>

## Finding what is actually using the space

When `df` and `du` agree and the filesystem really is full, the job is
ordinary: find the big things.

| Command | Finds |
| --- | --- |
| `du -xh /var \| sort -rh \| head -20` | The 20 largest directories, one filesystem only |
| `du -xh --max-depth=1 /` | Where to descend next, one level at a time |
| `find / -xdev -type f -size +1G` | Individual large files |
| `find /var/log -type f -mtime +30 -size +100M` | Old, large, and probably rotatable |
| `ncdu -x /` | Interactive, if you can install it. Far the fastest way |
| `df -h` then `df -i` | Which kind of full it is |

**`-x` and `-xdev` are not optional.** Both mean "stay on this filesystem". A
`du` that wanders into `/proc`, `/sys`, and every network mount produces numbers
that mean nothing and takes minutes doing it.

Descend, do not guess. `du --max-depth=1` at each level, following the largest
number down, finds a directory in four or five steps without reading thousands
of lines.

The usual suspects, in rough order of likelihood: `/var/log`, a journal that
was never capped, `/var/lib/docker` or `/var/lib/containers`, a package
manager cache, a core dump in `/var/lib/systemd/coredump`, a developer's build
output, and a database's write-ahead log that stopped being checkpointed.

<details class="deeper">
<summary>If you already administer Linux: sparse files, apparent size, and the numbers that do not add up</summary>

Once you start comparing sizes across tools, you will meet cases where they
disagree even with nothing deleted and nothing hidden. Almost always this is
sparse files.

**A sparse file has holes.** Write one byte at offset 10 GB and the file's
*length* is 10 GB while its *allocation* is one block. The kernel stores the
holes as metadata rather than as zeros, and returns zeros on read.

**Which means "size" has two meanings**, and different tools default to
different ones:

| Tool | Reports |
| --- | --- |
| `ls -l` | Apparent size: the file's length |
| `du` | Allocated size: blocks actually used |
| `du --apparent-size` | Length, to match `ls` |
| `df` | Allocated, filesystem-wide |
| `stat` | Both: `Size` and `Blocks` |

`stat` is the one that settles arguments, because it shows the two side by
side. `Blocks` is in 512-byte units regardless of the filesystem's block size,
which trips people up.

**Where sparse files legitimately appear:** VM disk images (a 100 GB qcow2 that
occupies 8 GB), database files preallocated at a large size, `/var/log/lastlog`
which is indexed by UID and is famously enormous and nearly empty, and core
dumps.

Where they cause real trouble: copying one without preserving sparseness
inflates it to its full apparent size. `cp --sparse=always`, `rsync -S`, and
`tar -S` preserve it; a naive `cat a > b` does not. Backing up a fleet of VM
images without `-S` is a memorable way to fill a backup target.

Two more reasons the numbers may not add up, worth knowing so you do not chase
them:

- **Filesystem metadata.** The inode table, journal, and group descriptors are
  allocated at `mkfs` and are not in any file. A freshly created ext4 shows a
  few percent used with nothing on it.
- **`du` counts a hard-linked file once** per walk, so a tree full of hard links
  totals less than the sum of its parts. That is correct, and it is why a
  backup directory made with `cp -al` costs so little.

</details>

## The order to work in

When the disk is full, this sequence gets you to the cause quickly and does not
depend on a guess:

1. **`df -h`**: which filesystem, and how full.
2. **`df -i`**: blocks or inodes? These two together eliminate half the
   possibilities in two seconds.
3. **`du -xh --max-depth=1 <mountpoint>`**: descend toward the largest number.
4. **If `du` cannot account for it, `lsof +L1 <mountpoint>`**: deleted-but-open
   files, and the process to restart.
5. **If neither explains it, check for files under a mount point** by
   bind-mounting the parent.
6. **Fix the cause, not the symptom.** Something wrote all that. Rotation,
   retention, or a cap on the journal is the actual repair.

**And write down what you found**, per lesson 63, because a disk that filled
once will fill again and the next person deserves the four-line version rather
than the investigation.

## For the exam

**`df` reports the filesystem's accounting. `du` walks the tree.** When they
disagree, suspect deleted-but-open files.

**`rm` unlinks a name.** Space is freed when the link count is zero *and* no
process holds the file open.

**`lsof +L1`** finds files with no remaining name.

**"No space left on device" can mean inodes.** Always run `df -i` as well as
`df -h`.

**ext4 fixes its inode count at `mkfs` time**; XFS allocates dynamically.

**ext4 reserves 5% for root by default**, changed with `tune2fs -m`.

**Use `-x` or `-xdev`** to keep `du` and `find` on one filesystem.

**Truncating in place (`> file`) is safe; `rm` on an open log is not.**

<details class="qa">
<summary>Check yourself</summary>

**`df` says 95% used, `du -sh /` says 40% of the disk. What is happening?**
Space held by files that have been unlinked but are still open. `du` cannot
see them because they have no name; `df` counts them because their blocks are
still allocated.

**How do you find them?**
`lsof +L1 <mountpoint>`. Look for `NLINK 0` and `(deleted)`.

**Two ways to reclaim that space?**
Restart the process holding the descriptor, or truncate the descriptor in place
with `: > /proc/<pid>/fd/<n>`. The second keeps the process running and
discards the data immediately.

**A colleague clears a growing log with `rm`. What happens?**
Nothing frees. The daemon keeps writing to the same inode, which now has no
name. `> file` would have emptied it in place and actually freed the space.

**`touch` fails with "No space left on device" but `df -h` shows 40% free.
What is your next command?**
`df -i`. That message covers inode exhaustion too.

**Which filesystem is more likely to hit that, ext4 or XFS, and why?**
ext4, because its inode count is fixed when the filesystem is created. XFS
allocates inodes dynamically.

**Can you increase the inode count on a live ext4 filesystem?**
No. It has to be recreated. Set it at `mkfs` time with `-i` or `-N` if you know
the workload is many small files.

**Why might `df` show used plus available adding up to less than the total?**
Reserved blocks, 5% by default on ext4, writable only by root. `tune2fs -m`
changes it.

**Why does `ls -l` report 100 GB for a file that `du` says is 8 GB?**
It is sparse. `ls` shows apparent length; `du` shows allocated blocks. `stat`
shows both.

**Why do `du` and `find` need `-x` or `-xdev`?**
To stay on one filesystem. Without it they descend into other mounts, `/proc`
and `/sys` included, and the totals become meaningless.

**A directory holds 900,000 tiny files. Which command finds it?**
Count rather than measure: `find /var -xdev -printf '%h\n' | sort | uniq -c |
sort -rn | head`.

**The disk filled, you truncated a log, and the alert cleared. Are you done?**
No. Something is writing that log and will do it again. The repair is rotation,
retention, or a journal cap.

</details>

## Where this sits

Lesson 12 built filesystems and lesson 13 mounted them; this is what to do when
one of them fills. Lesson 26's `find` is the tool for locating the offender, and
lesson 65's journal is usually where the evidence of what wrote it lives.

The next lesson takes the same posture toward a service that claims to be
running while the application behind it is not.


## References

- [df(1)](https://man7.org/linux/man-pages/man1/df.1.html) - man7.org. Accessed 2026-08-09.
- [du(1)](https://man7.org/linux/man-pages/man1/du.1.html) - man7.org. Accessed 2026-08-09.
- [lsof(8)](https://man7.org/linux/man-pages/man8/lsof.8.html) - man7.org. Accessed 2026-08-09.
- [unlink(2)](https://man7.org/linux/man-pages/man2/unlink.2.html) - man7.org. Accessed 2026-08-09.
- [tune2fs(8)](https://man7.org/linux/man-pages/man8/tune2fs.8.html) - man7.org. Accessed 2026-08-09.
> **The commands here were run on a real machine, not written from memory.** The
> transcripts come from AlmaLinux 10.2 on aarch64, with the filesystems built on
> loop devices so a 55 MB and an 8 MB filesystem could be filled quickly and
> thrown away. The deleted-but-open file really did hold 41 MB that `du` could
> not see, and truncating the descriptor really did return it without stopping
> the process. The inode filesystem was deliberately created with 256 inodes to
> reach exhaustion in a few hundred files rather than a few million.
