---
title: "What a write actually guarantees"
description: "This track covers filesystems, journals, LVM, RAID and backups, and never says what write() promises. It promises less than everybody assumes: the call returns while the data is still in memory, and four layers can still lose it."
deck: "The script said it wrote the file"
track: "linux-plus"
level: "deep"
order: 790
beyondExam: true
objectives:
  - "Say what write() guarantees and what it does not"
  - "Name the four tunables that decide how long data sits in memory"
  - "Tell fsync, fdatasync and O_DSYNC apart and say what each costs"
  - "Explain what a filesystem journal protects and what it leaves exposed"
  - "Say why a durable file can still have no name after a crash"
prerequisites: ["disks-partitions-and-filesystems", "backup-and-restore"]
tags: ["linux", "linux-plus", "storage", "filesystems", "beyond-the-exam"]
updated: 2026-08-21
draft: false
examObjectives: []
sources:
  - title: "write(2)"
    url: "https://man7.org/linux/man-pages/man2/write.2.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-21
    tier: 1
  - title: "fsync(2)"
    url: "https://man7.org/linux/man-pages/man2/fsync.2.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-21
    tier: 1
  - title: "open(2)"
    url: "https://man7.org/linux/man-pages/man2/open.2.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-21
    tier: 1
  - title: "Documentation for /proc/sys/vm"
    url: "https://docs.kernel.org/admin-guide/sysctl/vm.html"
    publisher: "The kernel development community"
    accessed: 2026-08-21
    tier: 1
  - title: "ext4 general information"
    url: "https://docs.kernel.org/admin-guide/ext4.html"
    publisher: "The kernel development community"
    accessed: 2026-08-21
    tier: 1
symptoms:
  - symptom: "A file written seconds before a power cut is empty or missing afterwards"
    anchor: "write-returns-before-anything-reaches-a-disk"
  - symptom: "A job that writes many small records is far slower than the disk should allow"
    anchor: "what-durability-costs"
---

> **Before you read.** A script writes a configuration file, checks that the
> command succeeded, logs that it is done, and the machine loses power four
> seconds later.
>
> **Is the file there when it comes back, and does anything the script did tell
> you the answer?**

This track spends nine topics on storage: partitions, filesystems, mounting, LVM,
RAID, backup, and the failures of each. None of them says what actually happens
when a program writes a file, and the answer is less reassuring than the amount
of surrounding machinery suggests. It is not on the exam either, which is why it
is here.

### Some words you will need

<dl class="terms">
<dt>page cache</dt>
<dd>The kernel's copy of file contents in memory. Nearly every read and write goes through it.</dd>
<dt>dirty page</dt>
<dd>A page of the cache that has been modified and not yet written to storage.</dd>
<dt>writeback</dt>
<dd>The background work of sending dirty pages to the device.</dd>
<dt>fsync</dt>
<dd>A request that the data and metadata of one file be on persistent storage before the call returns.</dd>
<dt>fdatasync</dt>
<dd>The same, without waiting for metadata that is not needed to read the data back.</dd>
<dt>journal</dt>
<dd>A log a filesystem writes before changing its structures, so an interrupted change can be finished or undone.</dd>
<dt>durable</dt>
<dd>Survives losing power at this instant. A much stronger claim than written.</dd>
</dl>

## What breaks without this

**A file reported as written is missing after a crash.** The program did nothing
wrong by its own lights, and neither did the filesystem.

**A backup is not a backup.** Copying files and reporting success does not mean
the copy is on the destination media, and the window is longer than people
expect.

**A workload is a hundred times slower than the hardware allows**, because
something in it is asking for durability on every record when it needs it once
per batch.

## write() returns before anything reaches a disk

A successful `write()` means the kernel has taken your data. It says nothing at
all about storage.

<details class="predict">
<summary>Five hundred megabytes written to a file on a machine whose storage cannot possibly absorb that in the time available. How long does the write take, and where is the data when it returns?</summary>

```bash
# Debian 13 (trixie), aarch64
$ sync; grep -E "^Dirty:" /proc/meminfo; echo "--- 500 MB written, nothing asked to wait for it ---"; perf stat -e task-clock dd if=/dev/zero of=/tmp/a bs=1M count=500 status=none 2>&1 | grep elapsed; grep -E "^Dirty:" /proc/meminfo; echo "--- now ask the kernel to actually put it somewhere ---"; sync; grep -E "^Dirty:" /proc/meminfo
Dirty:                 0 kB
--- 500 MB written, nothing asked to wait for it ---
       0.084269908 seconds time elapsed
Dirty:            106696 kB
--- now ask the kernel to actually put it somewhere ---
Dirty:                 0 kB
```

</details>

**Eighty four milliseconds for five hundred megabytes**, which is faster than the
storage underneath, and afterwards a hundred and four megabytes are sitting in
memory marked dirty. The `Dirty` line in `/proc/meminfo` is the amount of your
data that exists in exactly one place, and that place loses its contents when the
power does.

The rest had already been written out by background writeback while `dd` was
still running, which is why the number is a hundred and four rather than five
hundred. There is no moment at which a program can look at that figure and
conclude it is safe, because it is a property of the whole machine rather than of
your file.

<figure class="learn-figure">
<svg viewBox="0 0 720 232" role="img" aria-labelledby="write-title" style="width:100%;height:auto;">
<title id="write-title">The five stages data passes through between a program and persistent storage, with write returning at the second stage and fsync returning at the fifth</title>
<g fill="currentColor">
<text x="14" y="24" font-size="11">where the data is, and where each call decides it is finished</text>
<text x="220" y="52" text-anchor="middle" font-size="10.5">write() returns here</text>
<line x1="220" y1="60" x2="220" y2="94" stroke="currentColor" stroke-opacity="0.5" stroke-width="1.4"/>
<rect x="20" y="96" width="124" height="52" rx="3" fill="currentColor" fill-opacity="0.08" stroke="currentColor" stroke-opacity="0.45"/>
<text x="82" y="118" text-anchor="middle" font-size="10.5">your program</text>
<text x="82" y="134" text-anchor="middle" font-size="10" fill-opacity="0.75">calls write()</text>
<rect x="158" y="96" width="124" height="52" rx="3" fill="currentColor" fill-opacity="0.08" stroke="currentColor" stroke-opacity="0.45"/>
<text x="220" y="118" text-anchor="middle" font-size="10.5">page cache</text>
<text x="220" y="134" text-anchor="middle" font-size="10" fill-opacity="0.75">dirty, in RAM</text>
<rect x="296" y="96" width="124" height="52" rx="3" fill="currentColor" fill-opacity="0.08" stroke="currentColor" stroke-opacity="0.45"/>
<text x="358" y="118" text-anchor="middle" font-size="10.5">block layer</text>
<text x="358" y="134" text-anchor="middle" font-size="10" fill-opacity="0.75">queued</text>
<rect x="434" y="96" width="124" height="52" rx="3" fill="currentColor" fill-opacity="0.08" stroke="currentColor" stroke-opacity="0.45"/>
<text x="496" y="118" text-anchor="middle" font-size="10.5">device cache</text>
<text x="496" y="134" text-anchor="middle" font-size="10" fill-opacity="0.75">RAM on the drive</text>
<rect x="572" y="96" width="124" height="52" rx="3" fill="var(--accent)" fill-opacity="0.18" stroke="var(--accent)" stroke-width="1.6"/>
<text x="634" y="118" text-anchor="middle" font-size="10.5" fill="var(--accent)">the media</text>
<text x="634" y="134" text-anchor="middle" font-size="10" fill="var(--accent)">actually durable</text>
<line x1="634" y1="150" x2="634" y2="186" stroke="var(--accent)" stroke-opacity="0.7" stroke-width="1.4"/>
<text x="634" y="202" text-anchor="middle" font-size="10.5" fill="var(--accent)">fsync() returns here</text>
<text x="14" y="224" font-size="10" fill-opacity="0.75">three stages between them, each of which loses its contents when the power does</text>
</g>
</svg>
<figcaption>Everything to the left of the accented box is volatile. A program that writes and exits has handed its data to the second box and told you nothing about the other three, which is correct behaviour and is the source of most of the surprise. The device cache is the one people forget exists: even after the kernel has sent the data to the drive, a drive with a write cache has it in its own memory and will report success before it is on the media, which is why a durability request has to travel the whole way and ask the device to flush.</figcaption>
</figure>

## The policy that decides when it does reach the disk

Nothing above is a race the kernel is losing. It is a policy, and the policy has
four numbers.

```bash
# Debian 13 (trixie), aarch64
$ sysctl vm.dirty_background_ratio vm.dirty_ratio vm.dirty_expire_centisecs vm.dirty_writeback_centisecs
vm.dirty_background_ratio = 10
vm.dirty_ratio = 20
vm.dirty_expire_centisecs = 3000
vm.dirty_writeback_centisecs = 500
```

`vm.dirty_background_ratio` is the point at which writeback threads start working
in the background, expressed as a percentage of available memory. `vm.dirty_ratio`
is the point at which a process doing a write is made to do the writeback itself
before its call returns, which is where a machine starts feeling slow.
`vm.dirty_expire_centisecs` is how old a dirty page has to be before writeback
takes it anyway, thirty seconds here. And `vm.dirty_writeback_centisecs` is how
often the kernel wakes up to look, five seconds.

Read those together and the window is clear. On a machine with plenty of memory
and a light write load, your data can sit in RAM for up to thirty seconds before
anything tries to store it, and nothing in your program will have been told.

<details class="deeper">
<summary>If you tune these: why raising dirty_ratio makes a machine feel worse rather than better</summary>

The intuition is that a bigger buffer absorbs more, so raising the limit should
smooth things out. What it actually does is make the eventual stall longer.

Below `dirty_background_ratio` nothing is waiting: writeback happens in the
background and applications proceed at memory speed. Between the two ratios,
writeback is working and applications still proceed. At `dirty_ratio` the kernel
stops the writing process and makes it wait, and now the application's latency is
the storage's latency, arriving all at once after a period of it being far
better.

So the effect of a large `dirty_ratio` on a slow device is a machine that is
extremely fast and then stops. Twenty per cent of a 64 GB machine is nearly 13 GB
of dirty pages, and flushing that to a device doing 200 MB a second is over a
minute during which the writer is blocked and, because writeback competes for the
same device, everything else is slow too. That is the sawtooth people describe as
the machine periodically hanging.

The direction that helps is usually downward, and on machines that mostly write
it is often better to set the byte-valued forms, `vm.dirty_background_bytes` and
`vm.dirty_bytes`, because a percentage of memory is a strange way to size a
buffer whose drain rate is a property of the disk. Sizing it at a couple of
seconds of the device's real throughput keeps the stalls short enough not to be
noticed.

</details>

## The three ways to ask for durability

A program that cares has to say so, and there are three ways of saying it that
look different in a system call trace.

```bash
# Debian 13 (trixie), aarch64
$ for m in "" "conv=fsync" "oflag=dsync"; do printf -- "--- dd ... %s\n" "${m:-(nothing)}"; strace -e trace=openat,fsync,fdatasync -o /tmp/s dd if=/dev/zero of=/tmp/out bs=4k count=3 $m status=none; grep -E "tmp/out|fsync" /tmp/s; done
--- dd ... (nothing)
openat(AT_FDCWD, "/tmp/out", O_WRONLY|O_CREAT|O_TRUNC, 0666) = 3
--- dd ... conv=fsync
openat(AT_FDCWD, "/tmp/out", O_WRONLY|O_CREAT|O_TRUNC, 0666) = 3
fsync(1)                                = 0
--- dd ... oflag=dsync
openat(AT_FDCWD, "/tmp/out", O_WRONLY|O_CREAT|O_TRUNC|O_DSYNC, 0666) = 3
```

The first `dd` never asks. The second calls `fsync` once when it has finished,
which is the right shape for writing a whole file: do the work at memory speed,
then pay once. The third sets `O_DSYNC` at open time, which makes every single
write wait, and is the right shape only when each record has to survive
independently, which is what a database journal or a message queue needs.

`fsync` and `fdatasync` differ in what metadata they wait for. `fsync` flushes
the file's metadata as well as its contents. `fdatasync` skips metadata that is
not required to read the data back, so a size change is still flushed and a
modification timestamp is not. For a file being appended to at high rate, that is
a real saving and it is the call most databases actually use.

## What durability costs

<details class="predict">
<summary>Two thousand four-kilobyte writes, buffered, and then the identical two thousand with each one made durable before the next begins. How far apart are the two?</summary>

```bash
# Debian 13 (trixie), aarch64
$ echo "--- 2000 writes of 4 kB, buffered ---"; perf stat -e task-clock dd if=/dev/zero of=/tmp/c bs=4k count=2000 status=none 2>&1 | grep elapsed; echo "--- the same 2000 writes, each one durable before the next ---"; perf stat -e task-clock dd if=/dev/zero of=/tmp/d bs=4k count=2000 oflag=dsync status=none 2>&1 | grep elapsed
--- 2000 writes of 4 kB, buffered ---
       0.002801999 seconds time elapsed
--- the same 2000 writes, each one durable before the next ---
       0.405887716 seconds time elapsed
```

</details>

Two thousand identical writes. Buffered, the whole thing takes under three
milliseconds because none of it went anywhere. Asking for each one to be durable
before the next begins takes four hundred, which is a factor of a hundred and
forty on the same machine writing the same bytes.

That number is the reason this is a design decision rather than a setting.
Durability is not a checkbox to turn on for safety; it is a cost paid per
synchronisation point, and the engineering question is how many of those a
workload genuinely needs. A log shipper that fsyncs each line and a log shipper
that fsyncs each batch differ by two orders of magnitude in throughput and by a
few milliseconds in how much they can lose.

## What a journal protects

Every filesystem in this track's storage topics journals, and the thing people
assume it protects is not the thing it protects by default.

A journal exists so that the filesystem's own structures stay consistent. Before
changing metadata it writes what it is about to do, so a crash halfway through
leaves a record that recovery can either finish or discard, and the filesystem
comes back structurally sound. That is why `fsck` on a journalling filesystem
usually takes seconds rather than hours.

Your file's contents are a separate question, and ext4 gives three answers:

| Mode | What it does |
| --- | --- |
| `data=journal` | File data goes through the journal too, so contents are protected as well as structure |
| `data=ordered` | The default. Data is forced out to the filesystem before the metadata that describes it is committed |
| `data=writeback` | No ordering between the two |

The default is the middle one, and the ordering it guarantees is the reason it is
the default: metadata never points at blocks whose contents have not been written,
so you never read someone else's old data out of a file that was being extended
when the machine died. The kernel's own documentation is explicit that
`data=writeback` can leave stale data exposed in recently written files after an
unclean shutdown, which is a security property rather than only a correctness one.

**None of the three makes an unsynchronised write durable.** A journal orders
things and bounds the damage. It does not shorten the thirty second window in the
section above, and a file whose contents never left the page cache has nothing
for any mode to order.

<details class="deeper">
<summary>If you write software that saves files: the rename dance, and why fsync on the file is not enough</summary>

The standard way to replace a file safely is to write a new one, `fsync` it, and
`rename` it over the old one, because `rename` within a filesystem is atomic:
after a crash a reader sees either the old file or the new one and never a
half-written mixture.

There is a step in that sequence people leave out, and its absence produces a
fault that looks impossible. The `fsync` makes the new file's **contents**
durable. The `rename` changes a **directory**, and the directory is a file too,
with its own pages in the same cache, subject to the same thirty second window. A
crash in between leaves you with durable contents that no name points at, or with
the old name still in place. Fixing it means opening the directory and `fsync`ing
that as well.

The full sequence is therefore: write the temporary file, `fsync` it, close it,
`rename` it, then open the containing directory and `fsync` that. Every one of
those steps is in the manual pages and the last one is the one that gets skipped,
which is why "the config file was empty after the power cut" is a bug report that
predates most of us and keeps arriving.

The same logic applies to creating a file at all. A newly created file whose
directory has not been synchronised may not have a name after a crash, however
carefully its contents were flushed.

</details>

<details class="deeper">
<summary>If you run this on hardware or in a hypervisor: the layers that can lie about all of it</summary>

Everything above assumes that when the kernel asks the device to flush, the device
flushes. Three places that assumption has historically broken, in increasing order
of how much it will annoy you.

Drives with a volatile write cache report a write complete as soon as it is in
their own memory. That is legitimate and the kernel handles it by issuing an
explicit cache flush as part of `fsync`, which is what makes the operation
expensive. Consumer drives that acknowledge the flush without performing it exist,
and have been found by benchmarking a device as faster at synchronous writes than
its physics allows.

Virtualisation adds a cache mode between the guest and the host file, and the
options mean exactly what this page has been describing. A guest disk configured
to let the host cache writes gives the guest excellent numbers and a durability
guarantee that stops at the host's page cache, so a host crash loses data the
guest was told was safe. This is a per-disk setting somebody chose, and it is
worth knowing which one before believing a guest's `fsync`.

And network and layered storage is its own conversation, because a flush has to
reach through every layer. An NFS client, an iSCSI target, a copy-on-write
snapshot layer, and a RAID controller with a battery-backed cache all have a
position on what a flush means, and the battery is the interesting one: a
controller with a working battery can honestly acknowledge a flush that is still
in its memory, and the same controller with a dead battery cannot and usually
does not know.

The test that settles it is unkind and conclusive. Write with `fsync` per record,
measure the rate, and compare it with the physical limit of the device. Anything
faster than the media can commit is a cache somewhere reporting success early.

</details>

## Across distributions

The page cache, the four tunables and the durability calls are kernel behaviour
and are the same everywhere. What differs is the filesystem underneath, and it
differs by default rather than by choice.

| | RHEL family | Debian family |
| --- | --- | --- |
| Default root filesystem | XFS | ext4 |
| `data=` journal modes | Not available. XFS journals metadata only | The three modes above, `ordered` by default |
| Read the journal configuration | `xfs_info /` | `tune2fs -l /dev/...` |
| Grow the filesystem | `xfs_growfs`, and shrinking is impossible | `resize2fs`, which can shrink offline |

**So the middle section of this page is about ext4 specifically.** XFS reaches a
similar guarantee by a different route: its log, which its manual page calls the
metadata journal, orders metadata operations and has no equivalent of
`data=journal` because file data does not go through it at all. The practical
consequence is the same in both cases and worth stating plainly, because it is
the point of the whole page: neither filesystem makes an unsynchronised write
durable, and no mount option available on either one shortens the window.

## Prove it

**Watch `Dirty` while you copy something.** `grep Dirty /proc/meminfo` before,
during, and after a large copy, then again after `sync`. Seeing the number rise
and fall makes the whole page concrete in about a minute.

**Read your own four numbers.** `sysctl vm.dirty_ratio vm.dirty_background_ratio
vm.dirty_expire_centisecs vm.dirty_writeback_centisecs` on a machine you care
about, and work out how many seconds of writes it will hold before anything
tries to store them.

**Trace something you rely on.** `strace -e trace=fsync,fdatasync,openat` against
a database, a log shipper, or your own scripts. Finding that a program you trusted
never calls either one is the fastest way to understand what its promises are
worth.

## What trips people up

### 1. Reading a successful write as a stored write

`write()` returning means the kernel accepted the data. It is a statement about a
buffer, not about a disk, and no return value from it will ever tell you the data
is safe.

### 2. Calling sync and assuming it is per file

`sync` flushes everything, which is both more than you asked for and untargeted.
`fsync` on a file descriptor is the per-file version and is the one to use in a
program.

### 3. Fsyncing the file and forgetting the directory

A durable file with no name is a real outcome. The rename dance has five steps
and the fifth is the one that is usually missing.

### 4. Expecting a journal to protect file contents

By default it orders data against metadata and keeps the filesystem structurally
sound. It does not make your unsynchronised data durable and it never promised
to.

### 5. Turning on synchronous writes everywhere for safety

A hundred and forty times slower is a real number and it will change what the
system can do. Decide where the synchronisation points belong instead.

### 6. Trusting a benchmark that beats the hardware

If synchronous writes are completing faster than the media can physically commit,
something between you and the media is acknowledging early, and the number is
measuring a cache rather than a disk.

## Work it through

A nightly job copies twelve gigabytes of files to a USB drive, reports success,
and unmounts. Once every few weeks the drive comes back with truncated files, and
the job's log always says it completed.

Start with the unmount, because that is the part that should have saved you.
Unmounting flushes, so a clean unmount really does make the data durable, and a
job that reports success after a successful unmount has a reasonable claim. So
the first question is whether the unmount actually succeeded or whether something
in the script ignored its exit status, which is a one-line check and is
frequently the whole answer.

If it did succeed, look at what is between the copy and the media. A USB drive is
several layers of somebody else's firmware, and cheap ones do acknowledge flushes
they have not completed. Pulling the drive the instant the unmount returns leaves
that firmware no time, and a device that lies about flushing plus a human who
unplugs immediately is exactly this fault.

Then question the copy itself. `cp` and `rsync` write through the page cache and
do not synchronise unless asked, so the durability of the whole operation rests
entirely on the unmount. `rsync --fsync` and, on a filesystem that supports it,
mounting with `sync`, both move the guarantee earlier at a cost in speed, and for
twelve gigabytes once a night that cost is affordable.

And the reporting is worth fixing whatever the cause turns out to be. A job that
logs success before the data is durable is reporting on the wrong event. The
success message belongs after the unmount, with the unmount's status checked, and
until it is there every one of these investigations starts by disbelieving the
log.

## Try it

**Write a file, do not sync, and read `/proc/meminfo`.** The number is your data.

**Time the same write three ways**: plain, with `conv=fsync`, and with
`oflag=dsync`. The three numbers are the three positions on the trade-off and
seeing them on your own hardware is worth more than the ratio quoted here.

**Read the five steps of the rename dance in the manual pages.** `open`, `write`,
`fsync`, `rename`, and the directory `fsync`. Then look at whether the last one is
in any code you maintain.

## Check yourself

<details class="qa">
<summary>A program's write() returns 0 errors. What has it established?</summary>

That the kernel has accepted the data into the page cache. Nothing about storage.
The data may sit in memory for up to `vm.dirty_expire_centisecs` before anything
attempts to write it out, and a power loss in that window loses it.

</details>

<details class="qa">
<summary>Which of vm.dirty_ratio and vm.dirty_background_ratio makes an application wait?</summary>

`vm.dirty_ratio`. Below it, writeback happens in the background and the
application proceeds at memory speed. At it, the kernel makes the writing process
perform writeback itself before its call returns, which is where the machine
starts to feel like it has stalled.

</details>

<details class="qa">
<summary>What is the difference between fsync and fdatasync?</summary>

`fdatasync` skips metadata that is not needed for reading the data back, so
a size change is flushed and a timestamp is not. For an append-heavy workload
that removes a metadata write per operation, which is why databases commonly use
it.

</details>

<details class="qa">
<summary>You fsync a file and rename it over the old one. What can still go wrong?</summary>

The rename modified a directory, which is itself a file with dirty pages. Without
an `fsync` on the directory, a crash can leave the new contents durable with no
name pointing at them, or the old name still in place.

</details>

<details class="qa">
<summary>Synchronous writes on a device are completing faster than its media can commit. What does that mean?</summary>

Something between the kernel and the media is acknowledging a flush it has not
performed. A drive with a volatile cache that ignores flush commands, a hypervisor
caching the guest's disk in the host's page cache, or a controller whose
battery-backed cache is not what it claims.

</details>

## References

- [write(2)](https://man7.org/linux/man-pages/man2/write.2.html) - Linux man-pages project, and specifically what a successful return does and does not imply. Accessed 2026-08-21.
- [fsync(2)](https://man7.org/linux/man-pages/man2/fsync.2.html) - Linux man-pages project, the difference from `fdatasync` and the note about the containing directory. Accessed 2026-08-21.
- [open(2)](https://man7.org/linux/man-pages/man2/open.2.html) - Linux man-pages project, for `O_SYNC` and `O_DSYNC`. Accessed 2026-08-21.
- [Documentation for /proc/sys/vm](https://docs.kernel.org/admin-guide/sysctl/vm.html) - the kernel development community, the four dirty tunables and their byte-valued counterparts. Free. Accessed 2026-08-21.
- [ext4 general information](https://docs.kernel.org/admin-guide/ext4.html) - the kernel development community, the three data modes and the warning about stale data under `data=writeback`. Free. Accessed 2026-08-21.

**Where the output came from.** Four captured blocks through `capture.sh
--privileged` on the podman machine's kernel, named in each header. The timings
are that machine's virtual storage and the ratio between them is the point rather
than either figure: on real hardware the buffered number stays small and the
synchronous one gets worse. The `Dirty` figures are `/proc/meminfo` read before
and after, and the system call traces are `strace` reporting what `dd` asked for.

**Why this is not in the lesson count.** The objectives cover filesystems,
mounting, LVM, RAID and backup, and never mention the page cache, `fsync`, or what
a journal protects. Nothing here is examinable and all of it decides whether the
storage topics that are examinable actually keep your data.
