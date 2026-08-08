---
title: "Mounting, and making it survive a reboot"
description: "The filesystem exists and you still cannot save anything to it. What mounting actually does, the six fields of /etc/fstab, why you should never name a disk by its device, and the mount options that quietly override file permissions."
track: "linux-plus"
level: "working"
order: 140
objectives:
  - "Mount and unmount a filesystem, and prove which one is where"
  - "Write an /etc/fstab line field by field and test it without rebooting"
  - "Explain why UUIDs are used instead of device names"
  - "Predict what nosuid, nodev, noexec, and ro each prevent"
prerequisites: ["disks-partitions-and-filesystems"]
tags: ["linux", "linux-plus", "storage", "mount", "fstab"]
updated: 2026-08-07
draft: false
examObjectives:
  - exam: "xk0-006"
    domain: "1.0"
    objective: "1.3"
sources:
  - title: "mount(8)"
    url: "https://man7.org/linux/man-pages/man8/mount.8.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "umount(8)"
    url: "https://man7.org/linux/man-pages/man8/umount.8.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "fstab(5)"
    url: "https://man7.org/linux/man-pages/man5/fstab.5.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "findmnt(8)"
    url: "https://man7.org/linux/man-pages/man8/findmnt.8.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "nfs(5)"
    url: "https://man7.org/linux/man-pages/man5/nfs.5.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "systemd.mount(5)"
    url: "https://man7.org/linux/man-pages/man5/systemd.mount.5.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
symptoms:
  - symptom: "target is busy when unmounting"
    anchor: "2-target-is-busy"
  - symptom: "Machine boots to emergency mode after editing fstab"
    anchor: "4-a-typo-in-fstab-stops-the-machine-booting"
---

> **Before you read.** You have a disk, a partition, and a filesystem on it with
> its own UUID. `blkid` confirms all three.
>
> You still cannot save a file to it. There is no letter to switch to and no icon
> to click.
>
> **Where would a new filesystem even appear?** Linux has exactly one directory
> tree, starting at `/`. A new filesystem cannot be alongside it, because there is
> no alongside.

So it has to go *inside* the tree, at a directory you choose. That is what
mounting is, and once the idea lands, most of the confusion about Linux storage
goes with it.

The rest of this lesson is the mechanics: doing it once by hand, doing it
permanently, and the options that change what the filesystem is allowed to do.

### Some words you will need

<dl class="terms">
<dt>mount</dt>
<dd>To attach a filesystem to a directory, so its contents appear there.</dd>
<dt>mount point</dt>
<dd>The directory it attaches to. An ordinary directory, which you usually create empty first.</dd>
<dt>mount options</dt>
<dd>Rules applied to the whole filesystem at mount time, such as read-only. They override what the files themselves permit.</dd>
<dt>UUID</dt>
<dd>A long identifier written into the filesystem when it is created. Unlike a device name, it does not change.</dd>
<dt>fstab</dt>
<dd><code>/etc/fstab</code>. The list of filesystems the machine should mount, read at boot.</dd>
</dl>

## What breaks without this

**Storage that vanishes at reboot.** A mount done by hand lasts until the machine
restarts. Every "it worked on Friday and the data was gone on Monday" is this.

**A machine that will not boot.** `/etc/fstab` is read early, and a line naming a
device that is not there drops the machine to emergency mode. It is the most
common way to make a working server unbootable with a text editor.

**Security controls you do not know are there.** `noexec` on a filesystem stops a
script running no matter what its permission bits say, and nothing in `ls -l`
hints at it.

## Mounting, once

The mount point is just a directory. Make one, then attach a filesystem to it —
except the first attempt below is against a device that has never been formatted.

<details class="predict">
<summary>`mount` is given a raw device with no filesystem on it. Does it report "no filesystem", or something less direct?</summary>

```bash
# AlmaLinux 10.2, aarch64
$ mkdir -p /mnt/data; echo "--- mount a device with no filesystem on it ---"; mount $DEV0 /mnt/data; echo "--- make one, then try again ---"; mkfs.ext4 -q $DEV0; mount $DEV0 /mnt/data && echo "mounted"; findmnt /mnt/data; df -h /mnt/data | tail -2; umount /mnt/data
--- mount a device with no filesystem on it ---
mount: /mnt/data: wrong fs type, bad option, bad superblock on /dev/loop0, missing codepage or helper program, or other error.
       dmesg(1) may have more information after failed mount system call.
--- make one, then try again ---
mounted
TARGET    SOURCE     FSTYPE OPTIONS
/mnt/data /dev/loop0 ext4   rw,relatime,seclabel
Filesystem      Size  Used Avail Use% Mounted on
/dev/loop0      488M   24K  452M   1% /mnt/data
```

</details>

Two attempts. The first fails because there was nothing to mount — layer three
from the last lesson did not exist yet. **`wrong fs type, bad option, bad
superblock` is the error for "no filesystem here"**, and its wording is
unhelpfully broad; `blkid` is the command that actually tells you.

The second works. `findmnt` then reports the target, the source device, the type,
and the options in force. `df -h` gives the size.

**`findmnt` is better than `mount` with no arguments**, which also lists mounts
but in a wall of text including dozens of kernel pseudo-filesystems. `findmnt`
takes a path or a device and answers about that one thing.

`umount` takes the *mount point*, not the device — `umount /mnt/data`. It accepts
the device too, which is why people are surprised when a device mounted in two
places does not fully unmount.

## Making it permanent: /etc/fstab

One line per filesystem, six fields separated by whitespace:

```
UUID=57792d22-ffef-4b2a-a6a3-efde4fc906d9  /mnt/data  ext4  defaults,nosuid,nodev  0  2
```

| # | Field | This line | What it means |
| --- | --- | --- | --- |
| 1 | What to mount | `UUID=5779...` | Device, UUID, or label |
| 2 | Where | `/mnt/data` | The mount point, which must exist |
| 3 | Type | `ext4` | Filesystem type, or `auto` to guess |
| 4 | Options | `defaults,nosuid,nodev` | Comma-separated, no spaces |
| 5 | Dump | `0` | Backup flag for an ancient tool. Always `0`. |
| 6 | fsck order | `2` | `0` never, `1` for root, `2` for everything else |

**Field six is the one worth getting right.** Root gets `1`, other local
filesystems get `2`, and network filesystems get `0` because checking a remote
filesystem at boot is not a thing that can work.

Here it is end to end, tested without rebooting:

```bash
# AlmaLinux 10.2, aarch64
$ mkdir -p /mnt/data; mkfs.ext4 -q -L payroll $DEV0; uuid=$(blkid -s UUID -o value $DEV0); echo "UUID is $uuid"; echo "UUID=$uuid /mnt/data ext4 defaults,nosuid,nodev 0 2" >> /etc/fstab; tail -1 /etc/fstab; echo "--- mount -a reads the file ---"; mount -a; findmnt -o TARGET,SOURCE,FSTYPE,OPTIONS /mnt/data; umount /mnt/data
UUID is 57792d22-ffef-4b2a-a6a3-efde4fc906d9
UUID=57792d22-ffef-4b2a-a6a3-efde4fc906d9 /mnt/data ext4 defaults,nosuid,nodev 0 2
--- mount -a reads the file ---
TARGET    SOURCE     FSTYPE OPTIONS
/mnt/data /dev/loop0 ext4   rw,nosuid,nodev,relatime,seclabel
```

`blkid -s UUID -o value` prints just the UUID, which is how you get it into a
line without typing 36 characters by hand.

**`mount -a` mounts everything in `/etc/fstab` that is not already mounted.** It
is the test, and it is not optional: running it after every fstab edit is the
difference between finding a mistake now and finding it at the next reboot, when
the machine is in emergency mode and you are reading the file on a console.

Read the resulting options: `rw,nosuid,nodev,relatime,seclabel`. Your two options
are there, plus the ones `defaults` expands to and the ones the filesystem added.
**The options in force are not the options you wrote**, and `findmnt` shows the
truth.


<details class="deeper">
<summary>If you already administer Linux: fstab becomes systemd units, and the options that stop a machine hanging</summary>

**`/etc/fstab` is not read at boot in the way you might assume.**
`systemd-fstab-generator` translates every line into a `.mount` unit named after
the escaped mount point — `/mnt/data` becomes `mnt-data.mount` — and systemd
mounts things by starting those units. Two consequences worth having.

`systemctl status mnt-data.mount` explains a failed mount far better than the
boot console does, including the exact `mount` command that was run and what it
said. And `systemctl daemon-reload` after editing fstab is a real requirement
rather than superstition, because the generator only runs at boot and on reload.

**Two options prevent almost every fstab-induced boot failure.** `nofail` means a
missing device is not fatal, and belongs on every mount that is not essential to
the machine running. `x-systemd.device-timeout=10` shortens the wait for a device
that may not appear, which otherwise costs the 90-second default before the boot
gives up.

For network filesystems, `_netdev` orders the mount after the network is up.
Without it the mount is attempted before there is a network, waits for its
timeout, and fails — and on a machine where that mount is a dependency of
`local-fs.target`, takes the boot with it.

**Writing the `.mount` unit directly** gets you ordering and `automount`
behaviour that fstab cannot express. Worth reaching for when a mount has to
happen after a specific service rather than merely after the network.

</details>

## Why UUIDs

Device names are assigned in the order the kernel finds hardware. Add a
controller, swap a cable, or boot a machine where one disk spins up more slowly,
and `/dev/sdb` becomes `/dev/sdc`.

If `/etc/fstab` names `/dev/sdb1`, one of two things then happens: the machine
mounts a **different disk** at that path, or it fails to find the device and stops
booting.

A UUID is written into the filesystem itself at `mkfs` time. It travels with the
data, regardless of which port the disk is in or what order it was found.

| Identifier | Set by | Survives | Use for |
| --- | --- | --- | --- |
| `/dev/sdb1` | Enumeration order | Nothing | Interactive commands, once you have checked |
| `UUID=` | `mkfs` | Moving the disk anywhere | `/etc/fstab`. This is the answer. |
| `LABEL=` | `mkfs -L` or later | Moving the disk | Readable alternative, but not unique |
| `PARTUUID=` | Partitioning | Reformatting the filesystem | Boot entries, rare elsewhere |

<details class="deeper">
<summary>If you already administer Linux: four ways to name a device, and which one to use when</summary>

UUID is the usual advice and it is not always the right identifier. There are four,
they identify different things, and choosing wrongly produces failures that only
appear after a rebuild.

| Form | Identifies | Survives |
| --- | --- | --- |
| `/dev/sdb1` | Nothing stable | Nothing. Enumeration order can change on any boot. |
| `UUID=` | **The filesystem** | Moving the disk, adding disks. **Not `mkfs`.** |
| `LABEL=` | The filesystem, by a name you chose | The same, and it is human-readable |
| `PARTUUID=` | **The partition** | `mkfs`. Not repartitioning. |
| `/dev/disk/by-id/...` | **The physical device** | Everything, including repartitioning |

**UUID identifies the filesystem, not the disk**, and that distinction is the one
that matters. Reformat the partition and the UUID changes, so an fstab entry that
was correct becomes an unbootable machine — which is why "I reinstalled the
filesystem and now it drops to emergency mode" is a recognisable failure.

**`PARTUUID` is the right answer for a root filesystem in a cloud image**, because
it survives the `mkfs` that image build does and is what the GPT itself carries.

**`/dev/disk/by-id/` is the right answer for RAID and LVM members**, because it
names the physical drive by its serial number. When you need to know which disk to
physically pull out of a chassis, `by-id` is the only one of these that tells you.

```
ls -l /dev/disk/by-id/ /dev/disk/by-uuid/ /dev/disk/by-partuuid/
lsblk -o NAME,SIZE,FSTYPE,UUID,PARTUUID,SERIAL
```

**`LABEL` deserves more use than it gets.** An fstab of
`LABEL=payroll /srv/payroll ext4 defaults 0 2` is readable at a glance where a UUID
is forty characters of noise, and `e2label` or `xfs_admin -L` sets one on an
existing filesystem without touching the data. The trade is that labels are not
guaranteed unique — plug in a second disk labelled `payroll` and the behaviour is
undefined — so they suit machines you control and not fleets.

**Whatever you choose, `mount -a` before rebooting.** It is the single command
that turns a typo in fstab from an unbootable machine into an error message,
because it tries every entry that is not already mounted and reports what fails.

</details>

## Mount options that matter

Options apply to the entire filesystem and are checked before file permissions.
That ordering is the point.

| Option | Effect |
| --- | --- |
| `ro` / `rw` | Read-only or read-write |
| `noexec` | Nothing on this filesystem may be executed |
| `nosuid` | setuid and setgid bits are ignored |
| `nodev` | Device nodes here are not honoured |
| `noatime` | Do not update access times on read. Faster. |
| `defaults` | `rw,suid,dev,exec,auto,nouser,async` |
| `_netdev` | Wait for the network before mounting this |

Read-only means read-only, whatever the file says:

```bash
# AlmaLinux 10.2, aarch64
$ mkdir -p /mnt/data; mkfs.ext4 -q $DEV0; mount -o ro $DEV0 /mnt/data; findmnt -o TARGET,SOURCE,FSTYPE,OPTIONS /mnt/data; touch /mnt/data/newfile; echo "--- remount read-write ---"; mount -o remount,rw /mnt/data; touch /mnt/data/newfile && echo "created"; umount /mnt/data
TARGET    SOURCE     FSTYPE OPTIONS
/mnt/data /dev/loop0 ext4   ro,relatime,seclabel
touch: cannot touch '/mnt/data/newfile': Read-only file system
--- remount read-write ---
created
```

`Read-only file system` — running as root, in a directory root owns. **Root does
not override a mount option**, which is a genuinely different kind of restriction
from everything in the permissions lesson.

`mount -o remount,rw` changes it in place, without unmounting. That is also the
first thing to try when a filesystem has gone read-only on its own: the kernel
remounts read-only after an I/O error rather than risk corrupting data, so a
filesystem that turns read-only by itself is reporting a failing disk, and
`dmesg` will say so.

Now the one that surprises people:

<details class="predict">
<summary>A shell script on a `noexec` filesystem has mode `-rwxr-xr-x` and is owned by the user running it. What happens, and what does `ls -l` show?</summary>

```bash
# AlmaLinux 10.2, aarch64
$ mkdir -p /mnt/data; mkfs.ext4 -q $DEV0; mount -o noexec $DEV0 /mnt/data; printf "#!/bin/sh\necho it ran\n" > /mnt/data/script.sh; chmod +x /mnt/data/script.sh; ls -l /mnt/data/script.sh; /mnt/data/script.sh; umount /mnt/data
-rwxr-xr-x. 1 root root 22 Aug  8 01:09 /mnt/data/script.sh
/bin/sh: line 5: /mnt/data/script.sh: Permission denied
```

**`ls -l` shows the execute bit set on all three triads, and it still refuses.**

The mount option is checked before the file's permissions are ever consulted. The
filesystem has been told that nothing on it may be executed, and that applies to
every file it holds, whatever their modes say, and to root as well.

This is worth internalising because of how the failure reads. `Permission denied`
on a file whose permissions are visibly fine sends people to `chmod`, then to
`chown`, then to SELinux, and none of those is it. **`findmnt` on the path is the
command that answers it**, and it should come early rather than late.

The reason `noexec` exists: `/tmp`, `/var/tmp`, and `/dev/shm` are world-writable
and are where anything that gets a foothold on a machine will try to drop a
payload. Mounting them `noexec,nosuid,nodev` is a standard hardening baseline,
and this error is what it looks like when it works.

</details>

<details class="deeper">
<summary>If you already administer Linux: bind mounts, systemd units, /proc/mounts, and network filesystems</summary>

**`/etc/mtab` is a symlink to `/proc/self/mounts` on every current
distribution.** `/etc/fstab` is what you asked for; `/proc/mounts` is what the
kernel is actually doing. When they disagree, the kernel is right. `findmnt`
reads the kernel's view, which is why it is the tool to trust.

**Bind mounts** make a directory appear at a second path: `mount --bind /srv/data
/var/www/html/files`, or `/srv/data /var/www/html/files none bind 0 0` in fstab.
One filesystem, two places, no copy. Containers are built on this and on its
cousin the mount namespace, which is why `findmnt` inside a container looks so
different from outside.

**systemd mount units** are what `/etc/fstab` is translated into at boot —
`systemd-fstab-generator` produces a `.mount` unit per line, named after the
escaped mount point (`mnt-data.mount`). That means `systemctl status
mnt-data.mount` explains a failed mount far better than the boot console does,
and it is why `systemctl daemon-reload` after editing fstab is a real requirement
rather than superstition. Writing the unit directly gets you `automount`
behaviour and ordering control that fstab cannot express.

**`nofail` and `_netdev`** are the two options that stop a filesystem taking the
machine down. `nofail` means a missing device is not fatal at boot; every
removable and optional mount should carry it. `_netdev` orders the mount after
the network is up, and a network filesystem without it will hang the boot for the
90-second default timeout and then fail anyway. `x-systemd.device-timeout=10`
shortens the wait for a device that may not be there.

**NFS and SMB** are mounted the same way as anything else, with a source that is
`server:/export` or `//server/share`. NFS is the Unix-native one and cares about
UID matching between client and server, which is the source of most "permission
denied on a file I own" on NFS. SMB needs `cifs-utils` and a credentials file
referenced with `credentials=/root/.smbcreds` at mode `0600`, because the
alternative is a password in a world-readable fstab.

**`autofs`** mounts on access and unmounts after an idle timeout. It is the right
answer for home directories on a fileserver and for anything that is only
occasionally needed, because a filesystem that is not mounted cannot hang the
machine when the server behind it goes away.

</details>


<details class="deeper">
<summary>If you already administer Linux: bind mounts, namespaces, and the UID problem on NFS</summary>

**Bind mounts** make one directory appear at a second path: `mount --bind
/srv/data /var/www/html/files`, or `/srv/data /var/www/html/files none bind 0 0`
in fstab. One filesystem, two places, no copy and no extra space. It is how you
present part of a large volume to something that expects a specific path, and it
is the mechanism containers are built on.

The container relationship is worth understanding rather than memorising:
`findmnt` inside a container looks nothing like `findmnt` outside because the
container has its own **mount namespace** — a private view of the mount table.
Which is also why a filesystem mounted on the host after a container started is
invisible inside it, a fault that presents as an empty directory and sends people
looking at permissions.

**`/etc/mtab` is a symlink to `/proc/self/mounts`** on every current
distribution. `/etc/fstab` is what you asked for; `/proc/mounts` is what the
kernel is doing. When they disagree the kernel is right, and `findmnt` reads the
kernel's view, which is why it is the tool to trust.

**NFS and UID matching** is the one that wastes the most time. Classic NFS
authorises by numeric UID, so a file owned by UID 1000 on the server is owned by
whoever is UID 1000 on the client — a different person. The symptom is
`Permission denied` on a file `ls -l` says you own. NFSv4 with Kerberos or
`idmapd` fixes it properly; matching UIDs across machines fixes it crudely; and
`root_squash` on the export is why `sudo` does not help.

</details>

## Across distributions

| | RPM family | dpkg family |
| --- | --- | --- |
| `/etc/fstab` format | Identical | Identical |
| SMB support package | `cifs-utils` | `cifs-utils` |
| NFS client package | `nfs-utils` | `nfs-common` |
| autofs package | `autofs` | `autofs` |
| Default root options | `defaults` plus SELinux relabelling | `errors=remount-ro` |

Debian's `errors=remount-ro` on root is worth knowing: on an I/O error the root
filesystem goes read-only rather than continuing. The machine stays up and stops
being able to write, which looks alarming and is the correct behaviour.

## Prove it

After any mount change:

```bash
# What is actually mounted there, and with which options
findmnt /mnt/data

# Does every fstab line still work, without rebooting
sudo mount -a

# systemd agrees with the file
sudo systemctl daemon-reload
systemctl --failed

# And the check that matters
sudo umount /mnt/data && sudo mount -a && findmnt /mnt/data
```

That last sequence is the one to build a habit around. **`mount -a` after every
fstab edit, every time.** It costs two seconds and it catches the typo while you
still have a shell, rather than at 3am when the machine is in emergency mode.

## What trips people up

### 1. Mounting over a directory that has files in it

The existing contents do not go anywhere and are not deleted. They are **hidden**,
covered by the filesystem you just mounted on top, and they come back when you
unmount.

The consequence people hit: a service writes to `/var/log/app` before the mount
happens, the mount then covers those files, and disk usage does not add up
because `du` can no longer see them. `umount` and look.

Always mount onto an empty directory.

### 2. "target is busy"

```bash
# AlmaLinux 10.2, aarch64
$ mkdir -p /mnt/data; mkfs.ext4 -q $DEV0; mount $DEV0 /mnt/data; cd /mnt/data; echo "--- unmount while something is using it ---"; umount /mnt/data; cd /; umount /mnt/data && echo "unmounted once nothing was in it"
--- unmount while something is using it ---
umount: /mnt/data: target is busy.
unmounted once nothing was in it
```

Something has a file open, or a process has its working directory inside. Note
what caused it here: **a shell sitting in the directory.** That is the most common
cause and the easiest to miss, because your own terminal is doing it.

`lsof +D /mnt/data` or `fuser -vm /mnt/data` names the culprits. `umount -l` (lazy)
detaches it from the tree and cleans up when the last user lets go, which is the
escape hatch; avoid it as a habit, because a lazy-unmounted filesystem that is
still being written to is a genuinely confusing state.

### 3. Editing fstab and never testing it

Covered above, and it is the single highest-value habit in this lesson.

### 4. A typo in fstab stops the machine booting

A device that is not there, or a mount point that does not exist, and the boot
stops in emergency mode asking for the root password.

From that prompt: `mount -o remount,rw /` to get a writable root, then edit
`/etc/fstab` and fix or comment the line.

`nofail` on every non-essential mount prevents the whole category. It is two
words and it means a missing disk degrades the machine instead of stopping it.

### 5. Confusing the device with the mount point

`umount /dev/sdb1` and `umount /mnt/data` usually do the same thing and stop being
equivalent the moment a device is mounted in two places. Name the mount point.

Similarly, `mkfs` on a mounted filesystem will refuse — but `mkfs` on a *different*
device that happens to be the one you meant to keep will not.

## Work it through

A web server was moved to new hardware. The site works, but uploaded files are
missing. The uploads directory `/var/www/uploads` exists, is owned by the web
server account, and has mode `755`. Writing a test file into it succeeds.

`df -h /var/www/uploads` reports the root filesystem, size 40 GB.

Reason it out before reading on.

**The write succeeded, so this is not permissions.** Every instinct says
permissions, and the test already ruled it out.

**`df` is the finding.** It reports the *root* filesystem for that path. On the old
machine, uploads were on a separate 2 TB disk mounted at `/var/www/uploads`. On
this machine that mount is not happening, so the path resolves to an ordinary
directory on root — which exists, is writable, and is empty.

**So where did the files go?** Nowhere. They are on the old disk, which is either
not attached to the new machine or attached and not mounted. Nothing was deleted.

**Confirm it in two commands.** `findmnt /var/www/uploads` returns nothing, proving
there is no mount there. `lsblk -f` shows whether the disk is present with a
filesystem on it and no mount point.

**And here is the trap waiting.** If somebody now mounts the real disk at
`/var/www/uploads`, the test file written a moment ago disappears — hidden under
the mount, exactly as in trip-up 1. That is correct behaviour and it looks like
data loss, so it is worth expecting rather than discovering.

**The fix.** Mount it, verify with `findmnt` and `df`, then add the fstab line with
its UUID and run `mount -a` to prove the line parses. Then unmount and `mount -a`
again, so the thing you tested is the thing that will run at boot.

**The habit worth taking:** when a directory that should have data is empty,
**`df` on the path before anything else.** It answers "am I even looking at the
filesystem I think I am", and it is the question that being wrong about wastes
the most time. A directory and a mount point look identical until you ask.

## Try it

Optional, on a machine with a spare device, or a virtual machine.

1. `findmnt` with no arguments, then `findmnt /`. Compare the noise.
2. `findmnt -o TARGET,SOURCE,FSTYPE,OPTIONS /`. Read every option and say what it
   does.
3. `cat /etc/fstab`. Identify all six fields on each line and say what field six
   is for.
4. Make a directory, put a file in it, mount something over it, and confirm the
   file is hidden. Unmount and confirm it is back.
5. `cd` into a mount point and try to unmount it. Then `cd /` and try again.
6. Add a line to `/etc/fstab` for a spare device using its UUID, run `mount -a`,
   confirm with `findmnt`, then remove the line.

**Verification step.** You have it when you can add a disk to `/etc/fstab`, prove
it mounts, and prove it would still mount if the device name changed.

## Check yourself

<details class="qa">
<summary>Why does `/etc/fstab` use `UUID=` instead of `/dev/sdb1`?</summary>

**Because device names are assigned by enumeration order and can change.** Add a
controller, move a cable, or boot a machine where one disk is slower to spin up,
and the same physical disk comes back with a different name.

If fstab names `/dev/sdb1`, the machine then either mounts the wrong disk at that
path or fails to find the device and stops booting in emergency mode.

A UUID is written into the filesystem when it is created, so it travels with the
data. `blkid` and `lsblk -f` both show it.

`LABEL=` is a readable alternative and works the same way, with the caveat that
labels are not guaranteed unique — two disks labelled `data` in one machine is an
ambiguity a UUID cannot have.

</details>

<details class="qa">
<summary>A script has mode `755`, is owned by you, and running it gives "Permission denied". Permissions and ownership check out. What next?</summary>

**`findmnt` on the path.** The filesystem is very likely mounted `noexec`, which
forbids execution of everything on it regardless of file permissions, and applies
to root as well.

Mount options are checked before file permissions, so nothing in `ls -l` hints at
it. That is exactly what makes this one expensive: every visible piece of
evidence says the file is fine.

`/tmp`, `/var/tmp`, and `/dev/shm` are the usual places, because mounting them
`noexec,nosuid,nodev` is a standard hardening measure. The error is what that
control looks like when it is working.

Two other candidates worth ruling out in the same breath: a missing interpreter
named on the shebang line, which reports the *script* as not found; and SELinux,
which `ausearch` or `dmesg` would show.

</details>

<details class="qa">
<summary>What are fields five and six of an `/etc/fstab` line, and what should each be for a network filesystem?</summary>

**Field five is the dump flag**, for a backup tool nobody has used in decades.
Always `0`.

**Field six is the fsck order**: `0` means never check, `1` is for the root
filesystem, `2` is for other local filesystems, which are then checked in
parallel after root.

For a network filesystem both should be `0`. Checking a remote filesystem from
the client is not a thing that can work — the server owns it — and asking for it
at boot only creates a delay and an error.

Network mounts want two other things in field four: `_netdev`, so the mount waits
for the network, and usually `nofail`, so an unreachable server degrades the
machine rather than stopping the boot.

</details>

<details class="qa">
<summary>You mount a filesystem over `/var/log/app`, which already contained 8 GB of logs. Where did they go?</summary>

**Nowhere. They are hidden underneath.** Mounting covers a directory's existing
contents; it does not delete or move them. Unmount and they are all still there.

The practical consequence is a disk-space mystery: `du` on the running system
cannot see the covered files, so the space they occupy is unaccounted for. `df`
on the underlying filesystem shows it used, `du` shows it free, and the gap is
exactly the hidden data.

To recover the space, unmount and delete, or bind-mount the parent somewhere else
to reach the covered files without disturbing the live mount.

The rule that avoids all of it: **mount onto empty directories.**

</details>

<details class="qa">
<summary>You edit `/etc/fstab` and the machine will not boot, stopping at emergency mode. What is the recovery, and what would have prevented it?</summary>

**Recovery:** log in at the emergency prompt with the root password, then
`mount -o remount,rw /` to make the root filesystem writable — it is read-only at
that point — then edit `/etc/fstab` to fix or comment the offending line, and
reboot.

**Prevention, in two parts.** Run `sudo mount -a` immediately after every fstab
edit; it exercises exactly the same parsing and mounting that boot does, while
you still have a working shell. And put `nofail` on every mount that is not
essential to the machine running, so a missing or failed device degrades the
system instead of stopping it.

Worth knowing why it is fatal at all: systemd turns each fstab line into a mount
unit and treats a failed one as a failed dependency of `local-fs.target`, which
the rest of the boot waits on. `nofail` is what tells it not to.

</details>

## References

- [mount(8)](https://man7.org/linux/man-pages/man8/mount.8.html) - Linux man-pages project. Accessed 2026-08-07.
- [umount(8)](https://man7.org/linux/man-pages/man8/umount.8.html) - Linux man-pages project. Accessed 2026-08-07.
- [fstab(5)](https://man7.org/linux/man-pages/man5/fstab.5.html) - Linux man-pages project. Accessed 2026-08-07.
- [findmnt(8)](https://man7.org/linux/man-pages/man8/findmnt.8.html) - Linux man-pages project. Accessed 2026-08-07.
- [nfs(5)](https://man7.org/linux/man-pages/man5/nfs.5.html) - Linux man-pages project. Accessed 2026-08-07.
- [systemd.mount(5)](https://man7.org/linux/man-pages/man5/systemd.mount.5.html) - Linux man-pages project. Accessed 2026-08-07.

Command output was captured against real loop devices, reproducible with
`blog/scripts/capture.sh --block`. Blocks without a distribution and architecture
header are illustrative.
