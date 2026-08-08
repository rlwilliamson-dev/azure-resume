---
title: "From a bare disk to somewhere you can save a file"
description: "A new disk is attached and nothing can use it. Three separate steps stand between a lump of storage and a directory you can write to, and skipping any of them produces a different confusing error."
track: "linux-plus"
level: "working"
order: 130
objectives:
  - "Name the four layers between a disk and a directory, and the command that creates each"
  - "Choose between MBR and GPT, and say what forces the choice"
  - "Create a partition and a filesystem, and prove each one worked"
  - "Choose between ext4, XFS, and Btrfs for a given job"
prerequisites: ["hardware-and-device-discovery"]
tags: ["linux", "linux-plus", "storage", "filesystems", "partitions"]
updated: 2026-08-07
draft: false
examObjectives:
  - exam: "xk0-006"
    domain: "1.0"
    objective: "1.3"
sources:
  - title: "lsblk(8)"
    url: "https://man7.org/linux/man-pages/man8/lsblk.8.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "blkid(8)"
    url: "https://man7.org/linux/man-pages/man8/blkid.8.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "fdisk(8)"
    url: "https://man7.org/linux/man-pages/man8/fdisk.8.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "mkfs.ext4 / mke2fs(8)"
    url: "https://man7.org/linux/man-pages/man8/mke2fs.8.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "mkfs.xfs(8)"
    url: "https://man7.org/linux/man-pages/man8/mkfs.xfs.8.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "sgdisk(8)"
    url: "https://manpages.debian.org/stable/gdisk/sgdisk.8.en.html"
    publisher: "Debian Project"
    accessed: 2026-08-07
    tier: 1
  - title: "parted(8)"
    url: "https://manpages.debian.org/stable/parted/parted.8.en.html"
    publisher: "Debian Project"
    accessed: 2026-08-07
    tier: 1
symptoms:
  - symptom: "New disk attached but it does not appear anywhere usable"
    anchor: "1-the-disk-is-there-and-i-cannot-write-to-it"
  - symptom: "wrong fs type, bad option, bad superblock"
    anchor: "2-wrong-fs-type-bad-option-bad-superblock"
---

> **Before you read.** A new 4 TB disk is fitted. You log in, and the system
> carries on as though nothing has changed. No new drive letter, because there
> are no drive letters. No prompt asking what to do with it. Nothing.
>
> `lsblk` shows it. So the machine knows it is there.
>
> **What is missing between "the kernel can see this disk" and "I can save a file
> on it"?**

Three things, in a specific order, and each one is a separate command. Windows
and macOS collapse them into a single wizard, which is convenient right up until
something goes wrong and you have no idea which of the three steps failed.

Linux keeps them separate. That is more work the first time and considerably less
work every time afterwards, because each step has its own error and its own fix.

### Some words you will need

<dl class="terms">
<dt>disk</dt>
<dd>The whole physical (or virtual) device. A long row of numbered blocks and nothing else. <code>/dev/sda</code>.</dd>
<dt>partition table</dt>
<dd>A small record at the start of the disk saying how it is divided up. MBR or GPT.</dd>
<dt>partition</dt>
<dd>A numbered region of the disk, described by the table. <code>/dev/sda1</code>.</dd>
<dt>filesystem</dt>
<dd>The structure written inside a partition that turns raw blocks into files and directories. ext4, XFS, Btrfs.</dd>
<dt>mount point</dt>
<dd>The directory where a filesystem is attached to the tree, so you can reach it.</dd>
</dl>

## What breaks without this

**You cannot add storage.** Every "the disk is full" ends with adding capacity,
and adding capacity ends here.

**You reach for the wrong fix.** "Wrong fs type" and "no such device" and "no
space left" all look like storage problems and have nothing to do with each other.
Knowing the layers tells you which one you are in.

**You destroy data with a command that looked harmless.** `mkfs` takes about two
seconds and does not ask. Every one of these commands acts on the device you
named, immediately, with no undo.

## The four layers

<figure class="learn-figure">
<svg viewBox="0 0 720 350" role="img" aria-labelledby="stack-title stack-desc" style="width:100%;height:auto;">
  <title id="stack-title">The four layers between a disk and a directory</title>
  <desc id="stack-desc">A disk such as /dev/sda is a row of blocks with no structure. Partitioning it with fdisk, gdisk, or parted creates a partition such as /dev/sda1, a labelled region. Running mkfs on that partition writes a filesystem such as ext4 inside it, giving files, directories, and a UUID. Mounting that filesystem attaches it to a directory such as /srv/data, which is the first point at which anything can be saved. Each step has its own command and its own way of failing.</desc>

  <g font-family="ui-monospace, monospace">
    <rect x="24" y="20" width="200" height="52" rx="4" fill="currentColor" fill-opacity="0.06" stroke="currentColor" stroke-opacity="0.3"/>
    <text x="124" y="42" text-anchor="middle" font-size="13" fill="currentColor">disk</text>
    <text x="124" y="60" text-anchor="middle" font-size="11" fill="currentColor" fill-opacity="0.6">/dev/sda</text>
    <text x="248" y="38" font-size="11" fill="currentColor" fill-opacity="0.75">A row of blocks. No structure at all.</text>
    <text x="248" y="56" font-size="10" fill="currentColor" fill-opacity="0.5">lsblk sees it. Nothing can write a file to it.</text>

    <rect x="24" y="112" width="200" height="52" rx="4" fill="currentColor" fill-opacity="0.06" stroke="currentColor" stroke-opacity="0.3"/>
    <text x="124" y="134" text-anchor="middle" font-size="13" fill="currentColor">partition</text>
    <text x="124" y="152" text-anchor="middle" font-size="11" fill="currentColor" fill-opacity="0.6">/dev/sda1</text>
    <text x="248" y="130" font-size="11" fill="currentColor" fill-opacity="0.75">A labelled region, recorded in the partition table.</text>
    <text x="248" y="148" font-size="10" fill="currentColor" fill-opacity="0.5">Still no files. Still nothing you can save to.</text>

    <rect x="24" y="204" width="200" height="52" rx="4" fill="currentColor" fill-opacity="0.06" stroke="currentColor" stroke-opacity="0.3"/>
    <text x="124" y="226" text-anchor="middle" font-size="13" fill="currentColor">filesystem</text>
    <text x="124" y="244" text-anchor="middle" font-size="11" fill="currentColor" fill-opacity="0.6">ext4, with a UUID</text>
    <text x="248" y="222" font-size="11" fill="currentColor" fill-opacity="0.75">Structure inside the region: files, directories, free space.</text>
    <text x="248" y="240" font-size="10" fill="currentColor" fill-opacity="0.5">Now blkid has something to report.</text>

    <rect x="24" y="296" width="200" height="52" rx="4" fill="currentColor" fill-opacity="0.06" stroke="currentColor" stroke-opacity="0.3"/>
    <text x="124" y="318" text-anchor="middle" font-size="13" fill="currentColor">mount point</text>
    <text x="124" y="336" text-anchor="middle" font-size="11" fill="currentColor" fill-opacity="0.6">/srv/data</text>
    <text x="248" y="314" font-size="11" fill="currentColor" fill-opacity="0.75">Attached to the directory tree. You can finally save a file.</text>
    <text x="248" y="332" font-size="10" fill="currentColor" fill-opacity="0.5">df and findmnt report it from here on.</text>
  </g>

  <g stroke="currentColor" stroke-opacity="0.45" fill="none" stroke-width="1.2">
    <path d="M124 72 L124 108 M119 101 L124 109 L129 101"/>
    <path d="M124 164 L124 200 M119 193 L124 201 L129 193"/>
    <path d="M124 256 L124 292 M119 285 L124 293 L129 285"/>
  </g>
  <g font-family="ui-monospace, monospace" font-size="10.5" fill="currentColor" fill-opacity="0.8">
    <text x="134" y="94">fdisk / gdisk / parted</text>
    <text x="134" y="186">mkfs</text>
    <text x="134" y="278">mount</text>
  </g>
</svg>
<figcaption>Three commands, three layers. Skip one and you get a different error each time.</figcaption>
</figure>

**Each layer is invisible to the one two below it.** A filesystem does not know or
care whether it is on a partition, a whole disk, an LVM volume, or a RAID array.
That indifference is what makes the next three lessons possible.

## Layer one: a disk with nothing on it

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ sudo lsblk $DEV0; echo "--- any filesystem on it? ---"; sudo blkid $DEV0; echo "blkid exit status: $?"
NAME  MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
loop0   7:0    0  512M  0 loop 
--- any filesystem on it? ---
blkid exit status: 2
```

(`$DEV0` is a real, disposable disk provisioned for these captures. On your
machine substitute the actual device — `/dev/sdb`, `/dev/nvme0n1`. Naming the
wrong one here is how people destroy data, so the variable is doing real work.)

The disk exists: 512 MiB, no mount point, no partitions underneath it. **`blkid`
prints nothing and exits 2**, which is its way of saying it found no filesystem
signature at all.

Those two commands together are the fast first question about any device: `lsblk`
for "is it there and how big", `blkid` for "is there anything on it". A blank
`blkid` on a disk you are about to format is exactly what you want to see, and on
a disk you inherited it means you are about to overwrite something you have not
identified.

## Layer two: a partition

Every partitioning tool writes the same two kinds of table.

| | MBR | GPT |
| --- | --- | --- |
| Age | 1983 | Late 1990s, part of UEFI |
| Maximum disk | 2 TB | Effectively unlimited |
| Partitions | 4 primary, more via an extended partition | 128 by default |
| Redundancy | One copy, at the start | Two copies, start and end, with checksums |
| Firmware | BIOS, and UEFI in compatibility mode | UEFI |
| Use it when | An old system requires it | Everything else |

**Use GPT.** The only reasons to choose MBR are a machine that boots BIOS-only and
cannot be changed, or compatibility with something ancient. The 2 TB limit alone
settles most arguments, and a single disk larger than that cannot be fully used
with MBR at all.

Three tools do the job:

| Tool | Handles | Style |
| --- | --- | --- |
| `fdisk` | MBR and GPT | Interactive, menu-driven |
| `gdisk` / `sgdisk` | GPT | Interactive; `sgdisk` is the scriptable one |
| `parted` | Both | Interactive or one-shot; `-s` for scripts |

Creating one partition filling the disk:

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ sudo sgdisk -n 1:0:0 -t 1:8300 -c 1:data $DEV0; echo "--- now what does the kernel see? ---"; sudo lsblk $DEV0
Creating new GPT entries in memory.
The operation has completed successfully.
--- now what does the kernel see? ---
NAME      MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
loop0       7:0    0  512M  0 loop 
└─loop0p1 259:1    0  511M  0 part 
```

`-n 1:0:0` means partition 1, default start, default end — that is, all of it.
`-t 1:8300` sets the type code to Linux filesystem. `-c 1:data` names it.

**A new device appeared.** `loop0p1`, `TYPE part`, nested under the disk. On a
normal disk it would be `sda1` under `sda`. That nesting in `lsblk` is how you
read the whole storage stack at a glance, and it gets more useful in the LVM and
RAID lessons.

Note the size: 511 MiB from a 512 MiB disk. The table itself takes space, and the
first partition starts at 1 MiB by convention for alignment. Losing a megabyte is
the price of the arrangement.

The table is readable afterwards:

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ sudo sgdisk -n 1:0:0 -t 1:8300 $DEV0 >/dev/null; sudo mkfs.xfs -q ${DEV0}p1; sudo blkid ${DEV0}p1; echo "--- and fdisk sees the table ---"; sudo fdisk -l $DEV0
/dev/loop0p1: UUID="fbf7f3e0-4853-44e6-b6b7-5d19bb121c3f" BLOCK_SIZE="512" TYPE="xfs" PARTUUID="3de9bc91-a24c-4802-8577-b8b4c5e6b680"
--- and fdisk sees the table ---
Disk /dev/loop0: 512 MiB, 536870912 bytes, 1048576 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: gpt
Disk identifier: 3CEBC37D-BCFF-4E56-AED5-BFE95C34ECF6

Device       Start     End Sectors  Size Type
/dev/loop0p1  2048 1048542 1046495  511M Linux filesystem
```

`Disklabel type: gpt` confirms which table. `Start 2048` is that 1 MiB alignment
in 512-byte sectors. And that `blkid` line now reports both a `UUID` and a
`PARTUUID` — **two different identifiers for two different layers**, which is a
distinction worth holding onto: the PARTUUID belongs to the partition and
survives reformatting; the UUID belongs to the filesystem and is replaced by it.


<details class="deeper">
<summary>If you already administer Linux: partition type codes, and why the kernel ignores your new table</summary>

**The type code is a hint, not enforcement.** `sgdisk -t 1:8300` marks a
partition Linux filesystem, `8e00` marks it LVM, `fd00` Linux RAID, `ef00` an EFI
System Partition. Nothing stops you putting an ext4 filesystem in a partition
typed `8e00`, and it will mount perfectly. The codes exist so that other
software — installers, `blkid`, firmware, and the tools that auto-assemble RAID —
can guess correctly, and getting them wrong produces confusion rather than
failure. `sgdisk -L` lists them all.

**`Device or resource busy` after repartitioning** means the kernel's in-memory
partition table and the one on disk now disagree. The kernel refuses to re-read
it while anything on that disk is in use, which on a system disk is always.
`partprobe /dev/sdb` or `partx -u /dev/sdb` asks for a re-read; if either
refuses, the remaining options are unmounting everything on the device or
rebooting. This is why partitioning a live system disk is a maintenance-window
job and partitioning a fresh data disk is not.

**`wipefs -n /dev/sdb`** is the right first move on any disk you did not
provision. It lists every filesystem, partition table, and RAID signature it can
find without removing anything. A disk that reports an `linux_raid_member`
signature is a disk somebody pulled out of an array, and `mkfs` on it will
succeed and produce something that behaves oddly later.

</details>

## Layer three: a filesystem

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ sudo sgdisk -n 1:0:0 -t 1:8300 $DEV0 >/dev/null; sudo mkfs.ext4 ${DEV0}p1
mke2fs 1.47.3 (8-Jul-2025)
Discarding device blocks:      0/523244             done                            
Creating filesystem with 523244 1k blocks and 130560 inodes
Filesystem UUID: c4ea209c-651c-4bd3-8cda-f0b4bf075b87
Superblock backups stored on blocks: 
	8193, 24577, 40961, 57345, 73729, 204801, 221185, 401409

Allocating group tables:  0/64     done                            
Writing inode tables:  0/64     done                            
Creating journal (8192 blocks): done
Writing superblocks and filesystem accounting information:  0/64     done
```

Read three things out of that.

**`523244 1k blocks and 130560 inodes`.** An inode holds a file's metadata, and
the count is fixed at creation on ext4. Run out of inodes and you get "no space
left on device" with `df` showing plenty of room, because you have run out of the
*other* thing. `df -i` is what shows it.

**`Filesystem UUID`.** Generated now, written into the filesystem, and the stable
name you should use everywhere afterwards. Reformat and it changes.

**`Superblock backups stored on blocks: 8193, 24577, ...`.** The superblock
describes the whole filesystem, and copies of it are scattered through the disk.
When `fsck` says the primary superblock is corrupt, those numbers are what you
feed to `fsck -b 8193` to recover.

Confirm it took:

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ sudo sgdisk -n 1:0:0 -t 1:8300 $DEV0 >/dev/null; sudo mkfs.ext4 -q ${DEV0}p1; echo "--- blkid ---"; sudo blkid ${DEV0}p1; echo "--- lsblk -f ---"; sudo lsblk -f $DEV0
--- blkid ---
/dev/loop0p1: UUID="7d6556f0-9fef-4d5c-b7f6-a6553b27e5e1" BLOCK_SIZE="1024" TYPE="ext4" PARTUUID="c44fd7bc-cb7a-428e-b1ba-c4445f36a1a0"
--- lsblk -f ---
NAME      FSTYPE FSVER LABEL UUID                                 FSAVAIL FSUSE% MOUNTPOINTS
loop0                                                                            
└─loop0p1 ext4   1.0         7d6556f0-9fef-4d5c-b7f6-a6553b27e5e1                
```

The same `blkid` that printed nothing and exited 2 now reports a type and a UUID.
That before-and-after is the proof that layer three exists.

`MOUNTPOINTS` is still empty, though. **Three layers down and you still cannot
save a file**, which is the next lesson.

<details class="predict">
<summary>Somebody runs `mkfs.ext4 /dev/sdb` instead of `/dev/sdb1` on a disk that already has a partition and data. What happens, and what does `lsblk` show afterwards?</summary>

**It works, and that is the problem.** `mkfs` writes a filesystem to whatever
block device it is given, and a whole disk is a perfectly valid block device. It
does not check whether a partition table is in the way, because a filesystem
directly on a disk is a legitimate arrangement — the LVM and RAID lessons use it.

What it overwrites is the start of the disk, which is where the partition table
lives. So afterwards `lsblk` shows the disk with **no partitions under it at
all**, and `blkid` reports the disk itself as ext4.

The old partition is not securely erased; almost all of the data is still
physically there. But the table describing where it started and ended is gone,
and without it nothing knows how to find the filesystem inside. Recovery means
reconstructing the table by guessing at the original geometry, which `testdisk`
attempts and which is exactly as pleasant as it sounds.

The lesson is the one the earlier note flagged: **read the device name twice
before pressing Enter.** `mkfs` does not ask, does not warn, and takes two
seconds.

</details>

## Which filesystem

| | ext4 | XFS | Btrfs |
| --- | --- | --- | --- |
| Default on | Debian, Ubuntu | RHEL family | SUSE, Fedora Workstation |
| Grow | Yes, online | Yes, online | Yes |
| **Shrink** | **Yes, offline** | **No. Ever.** | Yes |
| Snapshots | No | No | Yes, built in |
| Best at | General use, small files, being unsurprising | Large files, parallel I/O, big filesystems | Snapshots, checksums, subvolumes |

**The row to memorise is shrink.** XFS cannot be made smaller, at all, by any
means. If you may need to reclaim space later, that decision is made at `mkfs`
time and cannot be revisited without backing up, reformatting, and restoring.

That is also why the RHEL family's default of XFS-on-LVM is less alarming than it
sounds: LVM lets you grow the volume, and you simply never plan to shrink.

Two others worth knowing by name:

- **tmpfs** lives in memory and is gone at reboot. `/run` and often `/tmp` are
  tmpfs. Fast, volatile, and it counts against your memory.
- **vfat / exFAT** for anything that has to be read by Windows or by firmware.
  The EFI System Partition is FAT for exactly this reason.

<details class="deeper">
<summary>If you already administer Linux: superblocks, inodes, alignment, and what `wipefs` is for</summary>

**Inode exhaustion** is the classic false "disk full". ext4 fixes the inode count
at `mkfs` time from the `-i` bytes-per-inode ratio, so a filesystem holding
millions of tiny files can run out of inodes at 20% disk usage. `df -i` shows it
instantly and `df` shows nothing. XFS allocates inodes dynamically and does not
have this failure mode, which is a genuine reason to prefer it for mail spools
and caches.

**`wipefs`** removes filesystem signatures without touching the data, and is the
right tool when `mkfs` or `pvcreate` refuses because it found an old signature.
`wipefs -n` shows what it would remove first. Reach for it instead of `dd
if=/dev/zero`, which is slower, less precise, and much easier to point at the
wrong device.

**Alignment** matters on SSDs and on any array with a stripe. Partitions starting
at 1 MiB are aligned for essentially every device in use; the tools do this by
default now, and the reason the default exists is that misaligned partitions on
4K-sector disks caused every write to become a read-modify-write. `parted`'s
`align-check optimal 1` verifies it.

**`fsck` and journals.** Journalling means a crash leaves a filesystem that can be
recovered by replaying the journal rather than by a full scan, which is why a
modern server reboots in seconds after a power loss instead of an hour. It does
not mean `fsck` is obsolete: it repairs structural damage a journal cannot,
and it must never be run on a mounted filesystem. `xfs_repair` for XFS, and note
XFS requires the log to be replayed by mounting once before a repair is possible.

**Filesystem labels** (`-L` at `mkfs`, or `e2label` / `xfs_admin -L` later) are a
friendlier alternative to UUIDs in `/etc/fstab` and are worth setting. They are
not unique, which is the trade: two disks labelled `data` in the same machine is
an ambiguity the UUID does not have.

</details>

## Across distributions

| | RPM family | dpkg family |
| --- | --- | --- |
| Default root filesystem | XFS | ext4 |
| ext tools | `e2fsprogs` | `e2fsprogs` |
| XFS tools | `xfsprogs`, installed | `xfsprogs`, often not |
| GPT tools | `gdisk`, `parted` | `gdisk`, `parted` |
| Default layout | LVM, usually | Plain partitions, usually |

The commands are identical. What differs is what is installed and what the
installer chose for you, and both of those are worth checking before you assume.


<details class="deeper">
<summary>If you already administer Linux: checking a filesystem, and why fsck on a mounted one is not a thing</summary>

**`fsck` is a front end.** It reads the type and dispatches to `e2fsck`,
`fsck.xfs`, or `fsck.btrfs`. That indirection hides a real asymmetry: `fsck.xfs`
does nothing at all and exits successfully, because XFS repairs are
`xfs_repair`'s job. A script that runs `fsck` across every filesystem and checks
the exit status will report XFS as healthy without having looked.

**Never run it on a mounted filesystem.** The tool assumes it is the only writer;
the kernel assumes the same. Running both at once corrupts a filesystem that was
previously fine, which is a memorable way to turn an investigation into an
incident. `e2fsck` refuses by default; some tools do not.

**XFS needs the log replayed before it can be repaired**, which means mounting it
once and unmounting cleanly. `xfs_repair` on a filesystem with a dirty log tells
you so and stops. `xfs_repair -L` zeroes the log and is a data-loss operation of
last resort, whatever the manual page's tone suggests.

**Superblock recovery** is what those backup block numbers in the `mkfs` output
were for. `e2fsck -b 8193 /dev/sdb1` uses the first backup when the primary is
unreadable, and `dumpe2fs /dev/sdb1 | grep -i superblock` lists them on an
existing filesystem. Worth knowing before you need it, because the moment you
need it the filesystem will not mount and `dumpe2fs` is how you find out where
the copies are.

</details>

## Prove it

After each layer, one command confirms it:

```bash
# Layer 1: is the disk there
lsblk /dev/sdb

# Layer 2: did the partition appear
lsblk /dev/sdb          # a nested entry, TYPE part
sudo partprobe /dev/sdb # if it did not, ask the kernel to re-read the table

# Layer 3: is there a filesystem
sudo blkid /dev/sdb1    # a UUID and a TYPE

# Layer 4: is it mounted and how big
findmnt /srv/data
df -h /srv/data
df -i /srv/data         # the one people forget
```

`partprobe` deserves the note. On a real disk, changing the partition table does
not always make the kernel notice, particularly if anything on that disk is in
use. `Device or resource busy` after partitioning means the table on disk and the
table in the kernel disagree, and `partprobe` or a reboot resolves it.

## What trips people up

### 1. "The disk is there and I cannot write to it"

You are between layers. `lsblk` sees a disk because a disk exists; that says
nothing about partitions or filesystems.

Walk down: `lsblk` for the partition, `blkid` for the filesystem, `findmnt` for
the mount. Whichever comes up empty first is the step you have not done.

### 2. "wrong fs type, bad option, bad superblock"

`mount` saying this almost always means **there is no filesystem there**. You
partitioned and skipped `mkfs`, or you are mounting the whole disk when the
filesystem is on the partition.

`blkid` settles it in one command. It also appears when the filesystem type
module is not loaded — mounting XFS on a Debian machine without `xfsprogs`, for
instance — which is the previous lesson wearing a storage costume.

### 3. Formatting the disk instead of the partition

`/dev/sdb` and `/dev/sdb1` are one character apart and mean entirely different
things. Covered in the prediction above, and it is worth a habit: run `lsblk` and
read the name out loud before any `mkfs`.

### 4. Expecting a partition where there is none

Not everything needs one. LVM physical volumes, RAID members, and encrypted
containers are frequently whole disks with no partition table at all, and that is
correct rather than an oversight.

`lsblk` showing a disk with something nested under it that is not a `part` — an
`lvm` or a `raid1` — is the tell.

### 5. Choosing XFS and later needing it smaller

There is no fix. Back up, `mkfs` something else, restore.

Decide at creation time, and if there is genuine doubt, ext4 on LVM keeps both
options open.

## Work it through

A 4 TB disk is fitted to a server to hold backups. A colleague partitions it,
formats it, mounts it, and reports that only 2 TB is available. `lsblk` shows the
disk as 3.7 TiB and the partition as 2.0 TiB.

Reason it out before reading on.

**The disk is fine.** `lsblk` reports 3.7 TiB for the device itself, which is the
expected figure — 4 TB in the manufacturer's decimal terabytes is 3.64 TiB in the
binary tebibytes the tools use. Nothing has been lost at layer one.

**The partition is the problem**, at exactly 2.0 TiB. That number is not a
coincidence. **MBR addresses partitions with 32 bits of 512-byte sectors, which
tops out at 2 TiB**, and a partitioning tool asked to make an MBR partition on a
larger disk will silently give you the largest one it can express.

**Confirm it.** `sudo fdisk -l /dev/sdb` and read the `Disklabel type` line. `dos`
means MBR; `gpt` means the theory is wrong and something else is going on.

**Why was there no error?** Because nothing invalid happened. The tool was asked
for a partition, it created the largest one the table format supports, and it
succeeded. The mistake was choosing MBR for a disk it cannot describe, and that
choice was made before the partition existed.

**The fix, and its cost.** Convert the table to GPT and repartition. The data has
to come off first, because rewriting the partition table on a disk holding a
filesystem is not a recoverable operation. On a disk with only a day of backups
that is cheap; the same mistake found six months later is not.

**Two things worth extracting.** The first is that **a suspiciously round number is
a limit, not a coincidence** — 2 TiB, 4 GiB, 65,536, and 255 are all worth
recognising on sight, because each names a specific format that ran out of bits.

The second is that layer-two decisions are hard to revisit. You can reformat a
filesystem in seconds and remount it in less; changing the partition table
underneath a filesystem means moving the data. **Get the table right first, and
when in doubt the answer is GPT.**

## Try it

Optional, and only on a disk you can afford to lose entirely. A spare USB stick
is ideal; a virtual machine with a second disk is better.

1. `lsblk` and `sudo blkid` on the device. Confirm it is what you think it is,
   twice, before continuing.
2. `sudo fdisk -l /dev/sdX` and read the `Disklabel type`.
3. Create a GPT table and one partition with `parted` or `sgdisk`. Confirm with
   `lsblk` that a nested `part` entry appeared.
4. `sudo blkid /dev/sdX1` before `mkfs` and after. Note the exit status of the
   first one.
5. `sudo mkfs.ext4 /dev/sdX1` and read the output for the inode count and the
   superblock backup locations.
6. `df -i` on any mounted filesystem. Compare the inode usage to the space usage.

**Verification step.** You have it when you can be shown a device name and say,
from `lsblk` and `blkid` alone, which of the four layers exist and which command
creates the next one.

## Check yourself

<details class="qa">
<summary>Name the four layers between a disk and a saved file, and the command that creates each transition.</summary>

**Disk** — the raw device, `/dev/sdb`. It exists as soon as the kernel sees the
hardware; no command creates it.

**Partition** — `/dev/sdb1`, created with `fdisk`, `gdisk`/`sgdisk`, or `parted`.

**Filesystem** — created with `mkfs` (`mkfs.ext4`, `mkfs.xfs`) on the partition.

**Mount point** — created with `mount`, attaching the filesystem to a directory.

Each layer is invisible to the one two below it, which is why a filesystem does
not care whether it sits on a partition, a whole disk, an LVM volume, or a RAID
array. That indifference is what the next three lessons are built on.

</details>

<details class="qa">
<summary>`blkid /dev/sdb1` prints nothing and exits 2. What does that tell you, and what does it not tell you?</summary>

**It tells you there is no filesystem signature there.** `blkid` reads the start
of the device looking for one, and found nothing it recognised.

So the partition exists — you named it and the command ran against it rather than
failing to find the device — and `mkfs` has not been run on it.

**What it does not tell you** is whether the device is empty. `blkid` reads
signatures, not data. A partition that held a filesystem which was then
overwritten at the start still contains almost all of its old contents; `blkid`
simply cannot see a header to identify it by.

That distinction matters when you inherit a disk: a blank `blkid` is not evidence
that nothing is on it, only that nothing is claiming it.

</details>

<details class="qa">
<summary>Why does a partition on a 4 TB disk come out at exactly 2 TiB, and what is the fix?</summary>

**The partition table is MBR.** MBR records partition sizes as a 32-bit count of
512-byte sectors, and that arithmetic runs out at 2 TiB. Asked for more, the tool
gives you the largest partition the format can express, and reports success
because nothing invalid happened.

`sudo fdisk -l` and read `Disklabel type`: `dos` means MBR.

The fix is **GPT**, which uses 64-bit addressing and is not going to be a
constraint in anyone's career. Converting requires rewriting the partition table,
so the data has to come off first.

The general habit: a suspiciously round limit is a format running out of bits.
2 TiB, 4 GiB, 65,536 and 255 are all worth recognising on sight.

</details>

<details class="qa">
<summary>Under what circumstances would you choose ext4 over XFS on a RHEL-family server, where XFS is the default?</summary>

**When you may need to shrink the filesystem.** XFS cannot be reduced by any
means, so a volume that might be over-provisioned and reclaimed later is the
clearest case for ext4.

Two others: **very small filesystems**, where XFS's metadata overhead is
proportionally larger; and **matching an existing estate**, where being able to
move a disk between machines that all expect ext4 is worth more than any technical
edge.

Going the other way, XFS is the better answer for large files, heavy parallel
I/O, and anything storing millions of small files — because it allocates inodes
dynamically and cannot suffer the ext4 failure where `df` shows free space and
`df -i` shows none.

</details>

<details class="qa">
<summary>`df` reports 40% used, and writes fail with "No space left on device". What is the likely cause and which command confirms it?</summary>

**Inode exhaustion.** On ext4 the number of inodes is fixed when the filesystem is
created, and each file consumes one regardless of its size. A filesystem holding
millions of tiny files — a mail queue, a session cache, a build directory —
runs out of inodes long before it runs out of blocks.

**`df -i`** reports inode usage rather than block usage, and will show 100%.

The fix is to delete files or move to a filesystem that allocates inodes
dynamically, which XFS and Btrfs both do. Recreating the ext4 filesystem with a
smaller `-i` ratio also works and means backing up and restoring.

The reason this catches people is that every symptom points at disk space, and
the one command everybody runs says disk space is fine.

</details>

## References

- [lsblk(8)](https://man7.org/linux/man-pages/man8/lsblk.8.html) - Linux man-pages project. Accessed 2026-08-07.
- [blkid(8)](https://man7.org/linux/man-pages/man8/blkid.8.html) - Linux man-pages project. Accessed 2026-08-07.
- [fdisk(8)](https://man7.org/linux/man-pages/man8/fdisk.8.html) - Linux man-pages project. Accessed 2026-08-07.
- [mkfs.ext4 / mke2fs(8)](https://man7.org/linux/man-pages/man8/mke2fs.8.html) - Linux man-pages project. Accessed 2026-08-07.
- [mkfs.xfs(8)](https://man7.org/linux/man-pages/man8/mkfs.xfs.8.html) - Linux man-pages project. Accessed 2026-08-07.
- [sgdisk(8)](https://manpages.debian.org/stable/gdisk/sgdisk.8.en.html) - Debian Project. Accessed 2026-08-07.
- [parted(8)](https://manpages.debian.org/stable/parted/parted.8.en.html) - Debian Project. Accessed 2026-08-07.

Command output was captured against real loop devices on the podman machine,
reproducible with `blog/scripts/capture.sh --block`. Blocks without a
distribution and architecture header are illustrative.
