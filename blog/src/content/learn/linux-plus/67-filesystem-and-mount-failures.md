---
title: "Filesystem and mount failures"
description: "One error message covers a dozen unrelated causes, which is why mount failures feel arbitrary. Decoding what the message does and does not tell you, recovering a filesystem whose superblock is gone, and knowing when a repair tool is the wrong thing to reach for."
deck: "It will not mount, and the error names a filesystem you did not choose"
track: "linux-plus"
level: "deep"
order: 680
objectives:
  - "Decode a mount failure and say what it rules out"
  - "Find the real reason in the kernel log rather than the mount output"
  - "Recover a filesystem from a backup superblock"
  - "Say when running a repair tool is unsafe"
  - "Explain why a filesystem remounts itself read-only"
  - "Avoid an fstab entry that leaves the machine unbootable"
prerequisites: ["mounting-and-fstab", "disks-partitions-and-filesystems"]
tags: ["linux", "linux-plus", "troubleshooting", "filesystems", "storage"]
updated: 2026-08-09
draft: false
examObjectives:
  - exam: "xk0-006"
    domain: "5.0"
    objective: "5.2"
sources:
  - title: "mount(8)"
    url: "https://man7.org/linux/man-pages/man8/mount.8.html"
    publisher: "man7.org"
    accessed: 2026-08-09
    tier: 1
  - title: "e2fsck(8)"
    url: "https://man7.org/linux/man-pages/man8/e2fsck.8.html"
    publisher: "man7.org"
    accessed: 2026-08-09
    tier: 1
  - title: "xfs_repair(8)"
    url: "https://man7.org/linux/man-pages/man8/xfs_repair.8.html"
    publisher: "man7.org"
    accessed: 2026-08-09
    tier: 1
  - title: "fstab(5)"
    url: "https://man7.org/linux/man-pages/man5/fstab.5.html"
    publisher: "man7.org"
    accessed: 2026-08-09
    tier: 1
symptoms:
  - symptom: "mount reports wrong fs type or bad superblock"
    anchor: "one-message-many-causes"
  - symptom: "Filesystem became read-only while the system was running"
    anchor: "read-only-is-a-symptom-not-a-setting"
  - symptom: "Machine drops to emergency mode after an fstab edit"
    anchor: "the-fstab-entry-that-strands-a-machine"
---

> **Before you read.** A data volume will not mount. The command prints a
> sentence mentioning the wrong filesystem type, a bad option, a bad superblock,
> a missing codepage, and a helper program, and then suggests you look at
> `dmesg`.
>
> You chose none of those things. The filesystem is ext4 and it worked
> yesterday.

That message is the single most confusing thing in Linux storage, and the reason
is structural rather than sloppy: `mount` is reporting one error code that a
dozen unrelated conditions all produce. It is not telling you what went wrong.
It is telling you the kernel refused, and inviting you to find out why somewhere
else.

### Some words you will need

<dl class="terms">
<dt>superblock</dt>
<dd>The block describing the filesystem: size, block size, where the inode tables live. Without it nothing can be read.</dd>
<dt>backup superblock</dt>
<dd>A copy written at intervals when the filesystem was created. Your way back.</dd>
<dt>journal</dt>
<dd>A log of pending changes, replayed at mount so a crash does not corrupt the structure.</dd>
<dt>fsck</dt>
<dd>Filesystem check. A family of tools; the one that runs depends on the type.</dd>
<dt>dirty</dt>
<dd>Not cleanly unmounted, so the journal has unreplayed entries.</dd>
<dt>read-only remount</dt>
<dd>The kernel's response to an error it cannot tolerate: stop writing, keep serving reads.</dd>
<dt>UUID</dt>
<dd>The filesystem's own identifier. Stable across reboots and device renaming.</dd>
</dl>

## What breaks without this

**A repair tool gets run on a mounted filesystem**, which is one of the few ways
to turn recoverable damage into unrecoverable damage.

**The machine will not boot after an edit.** A single wrong `fstab` line drops
systemd into emergency mode, and the recovery needs a console.

**Read-only is mistaken for a configuration mistake.** Somebody remounts it
read-write, the writes fail again, and the underlying disk error goes
uninvestigated for another week.

**A recoverable filesystem gets reformatted.** The superblock was gone, three
backups existed, and nobody looked.

## One message, many causes

Start by seeing the same error come from two entirely different faults. First,
an ext4 filesystem mounted as XFS:

```bash
# AlmaLinux 10.2, aarch64
$ mkfs.ext4 -q $DEV0; mkdir -p /mnt/d; echo "--- mount it as the wrong type ---"; mount -t xfs $DEV0 /mnt/d; echo "exit status: $?"; echo "--- and with no type at all, letting it probe ---"; mount $DEV0 /mnt/d && echo "mounted fine"; findmnt -no FSTYPE /mnt/d
--- mount it as the wrong type ---
mount: /mnt/d: wrong fs type, bad option, bad superblock on /dev/loop0, missing codepage or helper program, or other error.
       dmesg(1) may have more information after failed mount system call.
exit status: 32
--- and with no type at all, letting it probe ---
mounted fine
ext4
```

Nothing was wrong with the filesystem. Omit `-t` and it mounts immediately,
because `mount` probes the type instead of being told a wrong one.

Now a genuinely damaged filesystem, with its primary superblock overwritten:

<details class="predict">
<summary>The first 8 KB of a healthy ext4 filesystem is overwritten with zeros. What does <code>mount</code> say?</summary>

```bash
# AlmaLinux 10.2, aarch64
$ mkfs.ext4 -q $DEV0; mkdir -p /mnt/d; echo "--- destroy the primary superblock ---"; dd if=/dev/zero of=$DEV0 bs=1k seek=1 count=8 conv=notrunc status=none; mount $DEV0 /mnt/d; echo "exit status: $?"
--- destroy the primary superblock ---
mount: /mnt/d: wrong fs type, bad option, bad superblock on /dev/loop0, missing codepage or helper program, or other error.
       dmesg(1) may have more information after failed mount system call.
exit status: 32
```

</details>

The same sentence, character for character, and the same exit status 32. One
case was a typo in a command and the other was destroyed metadata.

So treat that message as meaning "the kernel said no" and nothing more. What it
does tell you is that the failure happened inside the `mount` syscall rather
than in path resolution, which rules out a missing mount point or a
non-existent device: those produce their own specific errors.

**Where the real answer lives:**

| Question | Command |
| --- | --- |
| What did the kernel actually object to? | `dmesg \| tail -20` or `journalctl -k -n 20` |
| What type is it really? | `blkid <device>`, or `file -s <device>` |
| Does the device exist and have the size you expect? | `lsblk`, `blkid` |
| Is it already mounted somewhere else? | `findmnt <device>` |
| Is the mount point a directory that exists? | `ls -ld <dir>` |
| Is it in use by something? | `lsof +D <dir>`, `fuser -vm <dir>` |

<details class="deeper">
<summary>If you already administer Linux: the mount errors that are specific, and what each one narrows it to</summary>

The generic message gets the attention, and the useful thing to know is that
most other mount errors are precise. Recognising them saves the whole
investigation.

| Message | Means | Usual fix |
| --- | --- | --- |
| `unknown filesystem type 'xfs'` | The kernel has no driver for it | `modprobe xfs`, or install the package. Common on minimal images and custom kernels |
| `special device /dev/sdb1 does not exist` | The device node is not there | `lsblk`, `partprobe`, check the cable or the LUN |
| `mount point /mnt/data does not exist` | The directory is missing | `mkdir -p` |
| `/dev/sdb1 already mounted on /mnt/other` | Already in use | `findmnt <device>` |
| `target is busy` | Something is inside the mount point | `lsof +D`, `fuser -vm` |
| `permission denied` | Not root, or `user` is absent from the fstab options | Use sudo, or add `user` |
| `can't read superblock` | Damaged or wrong offset | The recovery in this lesson |
| `no such file or directory` on a network mount | The export path is wrong on the server | Check the server's exports |

**`target is busy` on unmount is the one that generates the most frustration**,
and the answer is nearly always a shell sitting in the directory. `fuser -vm
/mnt/data` names the processes and `lsof +D /mnt/data` lists the open files.

`umount -l` (lazy) detaches the mount from the tree immediately and cleans up
when the last user goes away. It makes the symptom disappear and leaves the
processes holding files on a filesystem that is no longer reachable, which is
occasionally what you want before a reboot and is not a fix.

**Two mount-time behaviours worth knowing**, because they look like faults:

**A mount over a non-empty directory hides its contents.** The files are still
there, unreachable, occupying space that `du` cannot see, exactly as in lesson
68. Nothing warns you.

**Options can silently do nothing.** `mount -o noexec` on a filesystem type that
does not support it, or a typo in an option name, is often accepted and ignored.
`findmnt -o TARGET,OPTIONS` shows what is genuinely in effect, which is not
always what you asked for.

**And for network filesystems the failure modes are different again.** An NFS
mount with default options hangs processes in uninterruptible sleep when the
server disappears, which is where the `D` state from lesson 69 comes from.
`soft` and `timeo=` make it return errors instead, at the cost of possible data
loss on write, which is why `hard` remains the default and why a dead NFS server
takes half a fleet with it.

</details>

`blkid` is the fastest of these and settles the commonest case outright. If it
prints a type, the superblock is readable and your problem is elsewhere. If it
prints nothing at all, the filesystem's identifying metadata is gone and you are
in the next section.

## When the superblock is gone

ext filesystems write copies of the superblock at intervals across the device
precisely so that losing the first one is survivable. The trick is knowing where
they are, and `mke2fs -n` will tell you without writing anything.

**The `-n` matters more than anything else on this page.** Without it, that
command creates a new filesystem and destroys your data. With it, `mke2fs`
calculates what it *would* do and prints the layout.

```bash
# AlmaLinux 10.2, aarch64
$ mkfs.ext4 -q $DEV0; dd if=/dev/zero of=$DEV0 bs=1k seek=1 count=8 conv=notrunc status=none; mkdir -p /mnt/d; mount $DEV0 /mnt/d 2>/dev/null; echo "--- where are the backup superblocks ---"; mke2fs -n $DEV0 2>/dev/null | tail -3
--- where are the backup superblocks ---
Superblock backups stored on blocks: 
	8193, 24577, 40961, 57345
```

Four copies on a 64 MB filesystem. The numbers depend on block size and
filesystem size, which is why guessing at the commonly quoted 32768 is unreliable:
on this filesystem there is no backup there at all.

<details class="predict">
<summary><code>e2fsck</code> is pointed at the first backup with <code>-b 8193</code>. Does the filesystem come back?</summary>

```bash
# AlmaLinux 10.2, aarch64
$ mkfs.ext4 -q $DEV0; dd if=/dev/zero of=$DEV0 bs=1k seek=1 count=8 conv=notrunc status=none; echo "--- repair using the first backup ---"; e2fsck -y -b 8193 $DEV0 2>&1 | tail -5; echo "--- can it mount now ---"; mkdir -p /mnt/d; mount $DEV0 /mnt/d && echo "mounted"; findmnt -no SOURCE,FSTYPE /mnt/d
--- repair using the first backup ---
Padding at end of inode bitmap is not set. Fix? yes


/dev/loop0: ***** FILE SYSTEM WAS MODIFIED *****
/dev/loop0: 11/16384 files (0.0% non-contiguous), 9513/65536 blocks
--- can it mount now ---
mounted
/dev/loop0 ext4
```

</details>

Recovered, and the summary line is worth reading: 11 files across 16384 inodes,
9513 of 65536 blocks used. `e2fsck` rebuilt the primary superblock from the
backup and the filesystem mounted normally.

The sequence, then, when a filesystem will not mount and `blkid` says nothing:

1. Confirm the device itself is readable. `dd if=<device> of=/dev/null bs=1M count=100`
2. Find the backups with `mke2fs -n <device>`, checking the `-n` twice.
3. Take an image first if the data matters: `dd if=<device> of=/backup/img bs=4M`
4. Repair against a backup: `e2fsck -b <block> <device>`
5. Mount read-only first to look before trusting it: `mount -o ro`

<details class="deeper">
<summary>If you already administer Linux: when a repair tool makes things worse</summary>

`fsck` has a reputation for fixing things, and it deserves a more careful one.
It is a tool that makes a damaged structure *consistent*, which is not the same
as making it correct. Given a choice between an inode with implausible contents
and no inode at all, it will happily choose no inode, and your file is in
`lost+found` under a number, or gone.

**Three situations where running it is the wrong move:**

**On a mounted filesystem.** The kernel has cached metadata that the repair tool
is editing underneath it, and the two disagree from the first write. This is the
reliable way to destroy a filesystem that was merely damaged. Modern `e2fsck`
refuses unless forced; `xfs_repair` refuses outright. Unmount first, or boot
from rescue media. For a root filesystem that means the second option.

**When the underlying device is failing.** Repair means writing, and writing to
a dying disk accelerates it while producing more corruption to repair. Check
first, with `dmesg` for I/O errors and `smartctl -H` for the drive's own
opinion. If the hardware is suspect, image the device with `ddrescue` and work
on the copy.

**When you have not taken a copy and the data matters.** Repair is destructive
by design. `e2fsck -n` answers "what is wrong" without touching anything, and
that report is what tells you whether to proceed or escalate.

**The tools differ more than people expect:**

| Filesystem | Check | Notes |
| --- | --- | --- |
| ext2/3/4 | `e2fsck` | `-n` for read-only, `-p` for automatic safe fixes, `-y` for yes to everything, `-b` for a backup superblock |
| XFS | `xfs_repair` | **No `-n` fixes**, `-n` reports only. `xfs_repair -L` zeroes the log and loses data. Last resort |
| Btrfs | `btrfs check` | Read-only by default. `--repair` is explicitly documented as dangerous |
| Any | `fsck` | A wrapper that picks the right tool from the type |

**On XFS specifically**, since it is the RHEL default and behaves differently. It
has no `fsck` in the ext sense: a dirty XFS filesystem replays its log at mount
time, and the fix for most problems is simply to mount it. If mount fails,
`xfs_repair` runs against an unmounted device. `xfs_repair -L` discards the log
entirely, which lets a filesystem mount that otherwise could not, at the cost of
whatever the log contained. Reach for it only when the alternative is restoring
from backup.

**The `lost+found` directory** exists for the output of this process. When
`e2fsck` finds an inode with valid content and no directory entry pointing at
it, the data goes there named by inode number. Recovering from that means
opening files to work out what they were, which is exactly as tedious as it
sounds and is still better than nothing.

**Boot-time checks** are governed by the sixth field in `/etc/fstab`: 0 to skip,
1 for the root filesystem, 2 for everything else. ext4 also tracks a mount count
and interval that trigger a check periodically, which is the cause of a machine
occasionally taking twenty minutes to boot for no apparent reason. `tune2fs -c`
and `-i` adjust it.

</details>

## Read-only is a symptom, not a setting

A filesystem that becomes read-only while the system is running has almost never
been configured that way. The kernel did it, deliberately, in response to an
error it could not safely ignore.

The default behaviour for ext4 is `errors=remount-ro`, and the reasoning is
sound: an error writing metadata means the filesystem's structure may already be
inconsistent, so continuing to write risks compounding the damage. Stopping
writes preserves what is there and makes the problem loud.

**So the diagnostic order is fixed.** Do not remount read-write first. Find out
what the kernel objected to:

```bash
findmnt -o TARGET,SOURCE,FSTYPE,OPTIONS /var    # confirm it is ro
journalctl -k --since "-2h" | grep -iE 'error|remount|I/O|ext4|xfs'
sudo smartctl -H /dev/sda                        # the drive's own view
```

Remounting read-write without understanding why it went read-only clears the
symptom and leaves the cause. If the cause was a failing disk, the next few
minutes of writes are making it worse.

The three causes worth distinguishing, because their fixes have nothing in
common. A **hardware error** shows I/O errors in `dmesg` and needs the disk
replaced. **Filesystem corruption** shows ext4 or XFS complaints and needs an
unmounted repair. And a **full or exhausted device**, including thin-provisioned
storage that ran out underneath you, needs space rather than repair.

<details class="deeper">
<summary>If you already administer Linux: the fstab entry that strands a machine</summary>

An `fstab` mistake is unusual among configuration errors because it can stop the
machine booting entirely, and the recovery needs console access that a remote
server may not conveniently have.

**What happens:** systemd generates a mount unit for every `fstab` line. A line
that fails, and that is not marked otherwise, blocks `local-fs.target`, which
most services depend on. The boot stops and drops to emergency mode asking for
the root password.

**The options that prevent it**, and they are worth using by default on anything
that is not essential:

- **`nofail`** is the important one. The mount is attempted, and if it fails the
  boot continues. Correct for every data volume, USB disk, and network mount
  whose absence should not stop the machine.
- **`x-systemd.device-timeout=10s`** caps the wait. The default is 90 seconds
  per device, so three missing disks is four and a half minutes of apparently
  hung boot.
- **`noauto`** means do not mount at boot at all, only on request.
- **`_netdev`** marks a mount as needing the network, so systemd orders it after
  the network is up rather than trying it too early and failing.

**Always identify by UUID rather than by device name.** `/dev/sdb1` is assigned
in discovery order, so adding a disk, changing a controller, or an unlucky boot
can rename it, and your data volume becomes your swap partition or worse.
`blkid` gives the UUID, and `LABEL=` is a readable alternative with the caveat
that labels are not guaranteed unique.

**Validate before rebooting.** This is the whole prevention:

```bash
sudo findmnt --verify --verbose      # checks fstab for errors without mounting
sudo mount -a                        # attempts every non-noauto entry now
```

If `mount -a` succeeds on a running machine, the boot will succeed. Rebooting an
edited `fstab` without running one of those is the single most avoidable way to
lose a remote machine.

**And if it is already stranded:** at the emergency prompt, the root filesystem
is mounted read-only, so `mount -o remount,rw /` comes first, then edit the file,
then reboot. Without console access this needs rescue media or the cloud
provider's serial console, which is why finding out where that console is
belongs on a quiet afternoon rather than at 2am.

</details>

## Across distributions

The kernel side is identical. What differs is which filesystem you will actually
meet by default, which decides which repair tool is the right one.

| | RHEL family | Debian family |
| --- | --- | --- |
| Default root filesystem | XFS | ext4 |
| Repair tool for the default | `xfs_repair`, unmounted only | `e2fsck` |
| Dry run that only reports | `xfs_repair -n` | `e2fsck -n` |
| Shrink supported | **No**, XFS cannot shrink | Yes, `resize2fs` when unmounted |
| Grow | `xfs_growfs`, while mounted | `resize2fs`, while mounted |
| Backup superblock locations | `xfs_db`, rarely needed | `mke2fs -n`, then `e2fsck -b` |
| Extra tooling | `xfsprogs`, installed | `e2fsprogs`, installed |

**Reaching for `fsck` on XFS is the mistake this table exists to prevent.**
`fsck.xfs` exists so the boot-time fsck sequence has something to call, and on
the path the boot uses, `-a` or `-p`, it prints one line and exits 0 without
looking at anything. Run it by hand with no options and it tells you to use
`xfs_repair` instead, then exits 0 as well. Either way a clean exit is not a
statement about the filesystem, which is the trap: a script that checks exit
codes across every mount reports XFS as healthy without having examined it.
`xfs_repair -n` is the command that actually inspects one, and it needs the
filesystem unmounted.

It is not quite a stub. Current versions carry a `-f` path that mounts the
device to replay the log, unmounts it, and runs `xfs_repair -e`, though it
refuses to do that from an interactive shell. So `fsck.xfs` can repair, and
never on the invocation people reach for.

The shrink row is the one that shapes a decision months in advance. XFS has never
supported shrinking and there is no sign that it will, so a volume you may need
to make smaller later should be ext4 from the start. The alternative is a backup,
a fresh `mkfs`, and a restore.

## Prove it

When a mount fails, the mount command's own output is nearly useless and the real
reason is one command away:

```bash
# The actual error, which mount only hinted at
dmesg | tail -20
journalctl -k -n 20

# Is there a filesystem there at all, and which one
sudo blkid /dev/sdb1
lsblk -f

# Does fstab match reality, without a reboot to find out
findmnt --verify
sudo mount -a

# What is mounted now, and with which options
findmnt /mnt/data
mount | grep ' / '        # is root read-only right now
```

**`blkid` returning nothing for a device that definitely holds a filesystem is a
finding, not a non-answer.** It means the superblock is unreadable, which
separates "the filesystem is damaged" from "the mount options were wrong", and
those two have completely different next steps.

Never run a repair tool against a mounted filesystem. `e2fsck` warns and can be
forced past the warning, which is worse than refusing; `xfs_repair` refuses
outright. Unmount first, or boot from rescue media if the filesystem in question
is root.

## What trips people up

### 1. Reading the generic mount error literally

`wrong fs type, bad option, bad superblock` lists everything the syscall could
have meant, and the message is printed identically whichever one applies. It is
not telling you the type is wrong. `dmesg` has the specific reason, and the mount
output says as much if you read to the end of it.

### 2. Running a repair on a mounted filesystem

The tool and the kernel both believe they own the metadata, and they will
disagree while writing to it. That turns a recoverable filesystem into an
unrecoverable one. Unmount, or use rescue media.

### 3. Guessing a backup superblock offset

`8193` and `32768` both appear in documentation because the correct offset
depends on the block size. Run `mke2fs -n` against the device to print the real
locations, and note that the `-n` is what makes it calculate rather than format.
Forgetting it destroys the filesystem you were repairing.

### 4. Remounting read-write to clear a read-only filesystem

The kernel dropped it to read-only because it hit an error, under
`errors=remount-ro`. Remounting read-write without reading `dmesg` resumes
writing to something the kernel just declared untrustworthy, and the underlying
fault is usually a failing disk that is about to do it again.

### 5. `xfs_repair -L` as an early move

It zeroes the log, discarding whatever transactions were in it, which is data
loss by definition. A dirty XFS filesystem normally recovers by being mounted,
which replays the log properly. `-L` is the last resort after that fails, not the
first thing to try.

### 6. Device names in fstab

`/dev/sdb1` is assigned in enumeration order, so adding a disk or changing a
controller can point an fstab line at the wrong volume. UUIDs follow the
filesystem itself. Combined with `nofail` on anything non-essential, that removes
most of the ways fstab breaks a boot.

## Work it through

A data volume fails to mount after a power loss. The command says:

```
mount: /mnt/data: wrong fs type, bad option, bad superblock on /dev/sdb1,
       missing codepage or helper program, or other error.
```

The volume is ext4 and was working the previous day.

Reason it out before reading on.

**The real error is one command away.** The message above lists five possibilities because
`mount` does not know which applied. The kernel does:

```bash
sudo dmesg | tail -20
```

Say it reports `EXT4-fs (sdb1): unable to read superblock`. That eliminates the
options and the filesystem type immediately, and points at damage.

**Confirm the damage rather than assuming it.** A second opinion costs
one command:

```bash
sudo blkid /dev/sdb1
```

Nothing returned means the primary superblock is genuinely unreadable, which is
consistent with a write interrupted by the power loss.

**Find the backups before touching anything.** Do not guess the offset:

```bash
sudo mke2fs -n /dev/sdb1
```

That prints the layout it would create, including where the backup superblocks
sit, without writing a byte. Read the offsets from the output.

**Repair from a backup, with the device unmounted:**

```bash
sudo e2fsck -b 32768 /dev/sdb1     # or whichever offset mke2fs -n printed
```

**The step people skip: ask whether the disk is failing.** A
superblock does not usually die from a clean power loss alone:

```bash
sudo dmesg | grep -i "I/O error"
sudo smartctl -a /dev/sdb | grep -iE "reallocated|pending|crc"
```

Repairing the filesystem on a dying disk buys you a few days. The reasoning that
matters here is that the mount error described a symptom, the kernel log
described the fault, and the SMART attributes describe whether it will happen
again, which is the only one of the three that changes what you do next.

## Try it

Optional, and use a loop device rather than a real disk so that nothing you care
about is in range.

1. Build a small filesystem in a file and mount it:
   `truncate -s 128M /tmp/test.img`, `mkfs.ext4 /tmp/test.img`,
   then mount it on a directory via `mount -o loop`.
2. Unmount it, then destroy the primary superblock deliberately:
   `dd if=/dev/zero of=/tmp/test.img bs=1k seek=1 count=8 conv=notrunc`.
   Try to mount it and read the exact error, then read `dmesg`.
3. Recover it. Run `mke2fs -n /tmp/test.img` to list the backup superblocks,
   then `e2fsck -b <offset> /tmp/test.img`, and mount it again.
4. Add a line to fstab for a UUID that does not exist, run `findmnt --verify` and
   `mount -a`, and read what each says. Remove the line afterwards.

**Verification step.** Step 3 is right when you took the offset from `mke2fs -n`
output rather than from memory, and you can say what would have happened had you
left the `-n` off.

## For the exam

**The generic mount error covers many causes.** It means the syscall failed, not
that the filesystem type is wrong.

**`dmesg` or `journalctl -k` has the real reason.** The mount output says so.

**`blkid` identifies the filesystem** and tells you whether the superblock is
readable.

**`mke2fs -n` prints backup superblock locations** without writing. The `-n` is
critical.

**`e2fsck -b <block>`** repairs from a backup.

**Never run a repair tool on a mounted filesystem.**

**XFS uses `xfs_repair`, not `fsck`**, and `-n` on `xfs_repair` reports rather
than fixes. A dirty XFS usually recovers by mounting, which replays its log.

**Read-only remount is the kernel reacting to an error.** Find the cause before
remounting read-write.

**`nofail` in fstab stops a missing volume blocking the boot**, and UUIDs stop
device renaming causing it.

**`findmnt --verify` and `mount -a` validate fstab before a reboot.**

<details class="qa">
<summary>Check yourself</summary>

**`mount` says "wrong fs type, bad option, bad superblock". What does that tell
you?**
That the syscall failed. It covers a wrong `-t`, a damaged superblock, a missing
kernel module, and several other causes. Read `dmesg` for the actual reason.

**A filesystem will not mount as XFS. What is the quickest check?**
`blkid`. If it reports ext4, you were simply telling `mount` the wrong type, and
omitting `-t` would have worked.

**`blkid` prints nothing for the device. What now?**
The superblock is unreadable. Find the backups with `mke2fs -n`, image the device
if the data matters, then `e2fsck -b <block>`.

**Why is the `-n` on `mke2fs` so important?**
Without it the command creates a new filesystem and destroys the data you are
trying to recover.

**Is 32768 always a backup superblock location?**
No. It depends on block size and filesystem size. On the 64 MB filesystem above
the backups were at 8193, 24577, 40961, and 57345.

**Why must a filesystem be unmounted before repair?**
The kernel caches metadata that the repair tool is rewriting underneath it, and
the two immediately disagree. It turns damage into destruction.

**Which tool checks XFS, and what does its `-n` do?**
`xfs_repair`, and `-n` reports without fixing. There is no ext-style `fsck` for
XFS.

**What does `xfs_repair -L` cost you?**
It zeroes the log, discarding whatever it held. It is a last resort before
restoring from backup.

**A filesystem went read-only overnight. First move?**
Find out why: `journalctl -k` for I/O or filesystem errors, and `smartctl -H`
for the drive. Remounting read-write first hides the cause and may make it
worse.

**Three causes of a read-only remount?**
Hardware I/O errors, filesystem corruption, and the device running out of space,
including thin provisioning exhausted underneath you.

**One fstab line is wrong and the machine will not boot. Which option would
have prevented it?**
`nofail`, so a failed mount does not block `local-fs.target`.

**Why use UUIDs in fstab?**
Device names are assigned in discovery order and can change when hardware
changes, so `/dev/sdb1` may not be the same disk next boot.

**How do you check an fstab edit without rebooting?**
`findmnt --verify --verbose`, and `mount -a` to attempt the entries now.

**What is in `lost+found`?**
Files a repair found with valid content and no directory entry, named by inode
number.

</details>

## Where this sits

Lesson 12 created filesystems and lesson 13 mounted them. This lesson is what to
do when one refuses. Lesson 68 covers the case where it mounts fine and has no
room, and lesson 70 picks up when `dmesg` starts naming the disk rather than the
filesystem.


## References

- [mount(8)](https://man7.org/linux/man-pages/man8/mount.8.html) - man7.org. Accessed 2026-08-09.
- [e2fsck(8)](https://man7.org/linux/man-pages/man8/e2fsck.8.html) - man7.org. Accessed 2026-08-09.
- [xfs_repair(8)](https://man7.org/linux/man-pages/man8/xfs_repair.8.html) - man7.org. Accessed 2026-08-09.
- [fstab(5)](https://man7.org/linux/man-pages/man5/fstab.5.html) - man7.org. Accessed 2026-08-09.
> **The commands here were run on a real machine, not written from memory.** The
> transcripts come from AlmaLinux 10.2 on aarch64, on a 64 MB ext4 filesystem
> built on a loop device so its superblock could be destroyed and rebuilt without
> risking anything. The identical error text for two unrelated faults is exactly
> what `mount` printed both times, and the backup superblock numbers are the ones
> `mke2fs -n` reported for that filesystem rather than the ones usually quoted.
