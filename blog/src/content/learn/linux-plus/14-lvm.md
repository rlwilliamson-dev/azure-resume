---
title: "LVM"
description: "A partition's size is decided when you create it and changing it means moving data. LVM inserts a layer that makes size a runtime decision, and the one step everybody forgets is the one that makes it visible."
deck: "Growing a disk on a Tuesday afternoon"
track: "linux-plus"
level: "deep"
order: 150
objectives:
  - "Explain the three LVM layers and what each one buys you"
  - "Build a volume group and carve a logical volume out of it"
  - "Grow a mounted filesystem without unmounting it, in the right order"
  - "Say why growing the volume alone changes nothing that df can see"
prerequisites: ["mounting-and-fstab"]
tags: ["linux", "linux-plus", "storage", "lvm"]
updated: 2026-08-21
draft: false
examObjectives:
  - exam: "xk0-006"
    domain: "1.0"
    objective: "1.3"
sources:
  - title: "lvm(8)"
    url: "https://man7.org/linux/man-pages/man8/lvm.8.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "lvcreate(8)"
    url: "https://man7.org/linux/man-pages/man8/lvcreate.8.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "lvresize(8)"
    url: "https://man7.org/linux/man-pages/man8/lvresize.8.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-21
    tier: 1
  - title: "lvchange(8)"
    url: "https://man7.org/linux/man-pages/man8/lvchange.8.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-21
    tier: 1
  - title: "lvextend(8)"
    url: "https://man7.org/linux/man-pages/man8/lvextend.8.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "vgcreate(8)"
    url: "https://man7.org/linux/man-pages/man8/vgcreate.8.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "resize2fs(8)"
    url: "https://man7.org/linux/man-pages/man8/resize2fs.8.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "xfs_growfs(8)"
    url: "https://man7.org/linux/man-pages/man8/xfs_growfs.8.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "lvmthin(7)"
    url: "https://man7.org/linux/man-pages/man7/lvmthin.7.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
symptoms:
  - symptom: "lvextend succeeded but df shows the same size"
    anchor: "1-lvextend-worked-and-df-did-not-change"
  - symptom: "Insufficient free space in volume group"
    anchor: "2-insufficient-free-space"
---

> **Before you read.** A database partition is at 96% and filling. You have a
> spare disk in the machine.
>
> With plain partitions, the options are: shrink the neighbouring partition and
> grow this one, which means unmounting and hoping; or mount the new disk
> somewhere else and change the application to use two paths; or take an outage,
> move everything, and repartition.
>
> None of those is good, and all of them exist for one reason: **a partition's
> start and end are decided when it is created, and everything after it on the
> disk is in the way.**
>
> So the question: what would have to change for "make this filesystem bigger" to
> be a thing you could do on a Tuesday afternoon, with the database running?

The answer is a layer of indirection. LVM sits between the disks and the
filesystems and stops them being adjacent, so growing one no longer means moving
another.

This is a deep-dive topic, and it is on the exam because the RHEL family installs
onto LVM by default. There is a reasonable chance the machine in front of you is
already using it.

### Some words you will need

<dl class="terms">
<dt>physical volume (PV)</dt>
<dd>A disk or partition handed over to LVM. It stops being used directly.</dd>
<dt>volume group (VG)</dt>
<dd>A pool made of one or more physical volumes. Capacity goes in here.</dd>
<dt>logical volume (LV)</dt>
<dd>A slice taken out of the pool. Behaves exactly like a partition, and this is what you put a filesystem on.</dd>
<dt>extent</dt>
<dd>The unit LVM allocates in, 4 MiB by default. Sizes are always a whole number of these.</dd>
</dl>

## What breaks without this

**Growing storage becomes an outage.** Every capacity increase means a maintenance
window, a backup, and a repartition, instead of two commands.

**You cannot read the machine in front of you.** On a RHEL-family default install,
`/dev/sda2` is a physical volume and the root filesystem is on
`/dev/mapper/rhel-root`. Somebody who only knows partitions cannot follow that,
and `df` output that names `/dev/mapper/` anything is telling you LVM is in play.

**You do the resize half way.** Growing the volume and not the filesystem is the
single most common LVM mistake, and it produces no error at all.

## The three layers

<figure class="learn-figure">
<svg viewBox="0 0 720 330" role="img" aria-labelledby="lvm-title lvm-desc" style="width:100%;height:auto;">
  <title id="lvm-title">The three LVM layers</title>
  <desc id="lvm-desc">At the bottom, two physical volumes, /dev/sdb and /dev/sdc, are whole disks handed to LVM. They are pooled into a single volume group called data. Out of that pool, logical volumes are carved: one called web, one called db, and some space left unallocated. A logical volume can be grown into the unallocated space while it is mounted and in use.</desc>
  <g>
    <text x="120" y="68" text-anchor="end" font-size="11" fill="currentColor" fill-opacity="0.65">logical</text>
    <text x="120" y="82" text-anchor="end" font-size="11" fill="currentColor" fill-opacity="0.65">volumes</text>
    <text x="120" y="170" text-anchor="end" font-size="11" fill="currentColor" fill-opacity="0.65">volume</text>
    <text x="120" y="184" text-anchor="end" font-size="11" fill="currentColor" fill-opacity="0.65">group</text>
    <text x="120" y="270" text-anchor="end" font-size="11" fill="currentColor" fill-opacity="0.65">physical</text>
    <text x="120" y="284" text-anchor="end" font-size="11" fill="currentColor" fill-opacity="0.65">volumes</text>
    <rect x="130" y="42" width="170" height="48" rx="4" fill="currentColor" fill-opacity="0.1" stroke="currentColor" stroke-opacity="0.35"/>
    <text x="215" y="64" text-anchor="middle" font-size="12" fill="currentColor">data-web</text>
    <text x="215" y="80" text-anchor="middle" font-size="10" fill="currentColor" fill-opacity="0.65">ext4, mounted</text>
    <rect x="310" y="42" width="140" height="48" rx="4" fill="currentColor" fill-opacity="0.1" stroke="currentColor" stroke-opacity="0.35"/>
    <text x="380" y="64" text-anchor="middle" font-size="12" fill="currentColor">data-db</text>
    <text x="380" y="80" text-anchor="middle" font-size="10" fill="currentColor" fill-opacity="0.65">xfs, mounted</text>
    <rect x="460" y="42" width="240" height="48" rx="4" fill="none" stroke="var(--accent)" stroke-opacity="0.9" stroke-width="1.8" stroke-dasharray="4 3"/>
    <text x="580" y="64" text-anchor="middle" font-size="12" fill="var(--accent)">unallocated</text>
    <text x="580" y="80" text-anchor="middle" font-size="10" fill="currentColor" fill-opacity="0.65">room to grow into</text>
    <rect x="130" y="142" width="570" height="48" rx="4" fill="currentColor" fill-opacity="0.06" stroke="currentColor" stroke-opacity="0.3"/>
    <text x="415" y="164" text-anchor="middle" font-size="12" fill="currentColor">volume group: data</text>
    <text x="415" y="180" text-anchor="middle" font-size="10" fill="currentColor" fill-opacity="0.65">one pool of extents; nothing here is adjacent to anything</text>
    <rect x="130" y="242" width="275" height="48" rx="4" fill="currentColor" fill-opacity="0.1" stroke="currentColor" stroke-opacity="0.35"/>
    <text x="267" y="264" text-anchor="middle" font-size="12" fill="currentColor">/dev/sdb</text>
    <text x="267" y="280" text-anchor="middle" font-size="10" fill="currentColor" fill-opacity="0.65">pvcreate</text>
    <rect x="425" y="242" width="275" height="48" rx="4" fill="currentColor" fill-opacity="0.1" stroke="currentColor" stroke-opacity="0.35"/>
    <text x="562" y="264" text-anchor="middle" font-size="12" fill="currentColor">/dev/sdc</text>
    <text x="562" y="280" text-anchor="middle" font-size="10" fill="currentColor" fill-opacity="0.65">pvcreate</text>
  </g>
  <g stroke="currentColor" stroke-opacity="0.45" fill="none" stroke-width="1.2">
    <path d="M267 242 L267 196 M262 203 L267 195 L272 203"/>
    <path d="M562 242 L562 196 M557 203 L562 195 L567 203"/>
    <path d="M215 142 L215 96 M210 103 L215 95 L220 103"/>
    <path d="M380 142 L380 96 M375 103 L380 95 L385 103"/>
  </g>
  <g stroke="currentColor" stroke-opacity="0.5" fill="none" stroke-width="1.4">
    <path d="M304 86 L456 86 M449 81 L457 86 L449 91"/>
  </g>
  <text x="380" y="30" text-anchor="middle" font-size="10.5" fill="currentColor" fill-opacity="0.75">lvextend grows this way, while mounted</text>
</svg>
<figcaption>Pool the disks, then carve slices out of the pool. Slices are not adjacent, so one can grow.</figcaption>
</figure>

**The whole trick is in the middle box.** Once capacity is a pool, a logical volume
is not sitting between two neighbours. Growing it means taking more extents from
the pool, and the extents do not have to be next to the ones it already has, or
even on the same disk.

## Building it

Three commands, bottom up. The two devices below are raw disks that have never
been partitioned.

<details class="predict">
<summary>Every guide to adding a disk starts by making a partition table. Does <code>pvcreate</code> require one, and what does the <code>VG</code> column say for a brand new physical volume?</summary>

```bash
# AlmaLinux 10.2, aarch64
$ pvcreate $DEVS; echo; pvs
  Physical volume "/dev/loop0" successfully created.
  Physical volume "/dev/loop1" successfully created.
  Creating devices file /etc/lvm/devices/system.devices

  PV         VG Fmt  Attr PSize   PFree  
  /dev/loop0    lvm2 ---  512.00m 512.00m
  /dev/loop1    lvm2 ---  512.00m 512.00m
```

</details>

`pvcreate` writes an LVM header onto each device. Two 512 MiB disks, both entirely
free, and the `VG` column is empty because neither belongs to a group yet.

Note there are **no partitions here.** LVM is happy to take a whole disk, and
on a data disk that is the tidier choice, one fewer layer, and no partition
table to keep in step.

Then the group, and a volume out of it:

```bash
# AlmaLinux 10.2, aarch64
$ pvcreate -q $DEVS 2>/dev/null; vgcreate data $DEVS; echo; vgs; echo; lvcreate -n web -L 300M data; echo; lvs; echo; lsblk $DEVS
  Physical volume "/dev/loop0" successfully created.
  Physical volume "/dev/loop1" successfully created.
  Creating devices file /etc/lvm/devices/system.devices
  Volume group "data" successfully created

  VG   #PV #LV #SN Attr   VSize    VFree   
  data   2   0   0 wz--n- 1016.00m 1016.00m

  Logical volume "web" created.

  LV   VG   Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  web  data -wi-a----- 300.00m                                                    

NAME       MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
loop0        7:0    0  512M  0 loop 
`-data-web 252:0    0  300M  0 lvm  
loop1        7:1    0  512M  0 loop 
```

Three things to read out of that.

**`VSize 1016.00m` from two 512 MiB disks.** Not 1024. Each PV gives up a little
to LVM's own metadata, so the pool is always slightly smaller than the sum of the
parts. Expect it and do not go looking for the missing megabytes.

**The `lsblk` tree.** `data-web` is nested under `loop0`, and `loop1` has nothing
under it. The volume fitted entirely on the first disk, because 300 MiB fits in
512 MiB. LVM allocates linearly by default and only spills onto the second disk
when it has to.

The volume is at `/dev/data/web`, and also at `/dev/mapper/data-web`. Both
work. `/dev/mapper/<vg>-<lv>` is the one that shows up in `df` output, which
is why a `df` line naming `/dev/mapper/` anything means you are looking at
LVM.

The three reporting commands go together and are worth learning as a set:

| Command | Answers |
| --- | --- |
| `pvs` | Which devices are in LVM, and how much of each is used |
| `vgs` | How big each pool is and how much is free |
| `lvs` | Which volumes exist and how big |
| `pvdisplay` | The same about one device at length, including its extent count |
| `vgdisplay` | The same about one group, including the extent size and free extents |
| `lvdisplay` | The same about one volume, including its path and whether it is active |

There are two families and both are named in the objectives. The short set prints
a line per object and is what you reach for when you want to see everything at
once. The `display` set prints a paragraph per object and is what you reach for
when the short form leaves out the field you need.

`VFree` in `vgs` is the number to look at before any resize. It is the answer to
"can I grow this right now".

Two more commands are worth having before the next section. **`lvresize` does the
job of `lvextend` and `lvreduce` together**, with the sign on the argument
deciding: `-L +500M` grows, `-L -500M` shrinks, and a bare `-L 500M` sets the
size outright. The separate commands still exist because shrinking a mounted
filesystem by accident is expensive, and having to type `lvreduce` is a small
speed bump in front of it.

The option worth remembering on any of the three is `-r`, which resizes the
filesystem in the same breath as the volume. It is the answer to the pitfall the
whole next section is about, and the reason to know the long way round first is
that `-r` only knows how to grow the filesystems it supports.

And **`lvchange` is the one you need when a volume exists and is not there.**
`lvchange -ay data/web` activates a volume, which is what an imported volume
group needs before anything appears under `/dev/mapper`. A volume that `lvs`
lists and `ls /dev/mapper` does not is almost always inactive rather than broken.

From here it is an ordinary block device: `mkfs.ext4 /dev/data/web`, mount it, put
it in `/etc/fstab`. The filesystem neither knows nor cares that LVM is underneath.


<details class="deeper">
<summary>If you already administer Linux: extents, allocation, and why a volume can be slower than the disks under it</summary>

**The extent is the unit of everything.** 4 MiB by default, set at `vgcreate`
time with `-s` and awkward to change afterwards. Every logical volume is a whole
number of extents, which is why `lvcreate -L 300M` on a 4 MiB extent size gives
you exactly 300 MiB and `-L 301M` quietly gives you 304. `vgdisplay` shows the
extent size and the free count; `lvs -o +seg_pe_ranges` shows which extents on
which physical volume a given volume actually occupies.

That last command answers a question that comes up on any multi-disk group:
**where is this volume, physically?** LVM allocates linearly by default, filling
one PV before starting the next, so a volume can sit entirely on one spindle
while the group spans four. If that spindle is the slow one, the volume is slow
and nothing in `lvs` hints at it.

`lvcreate -i 2` stripes across two physical volumes instead, which is a real
performance decision made at creation time and not easily changed later.
`--alloc anywhere` and `--alloc contiguous` are the other allocation policies,
and `contiguous` is occasionally worth it on spinning disks and never on SSDs.

**`pvmove` is how you fix a bad placement without downtime.** It relocates
extents off a physical volume (or, with `pvmove /dev/sdb:1000-1999`, a
specific range) while everything stays online. It is slow, restartable after
an interruption, and genuinely one of the more impressive things LVM does.

</details>

## The resize, and the step everybody forgets

The volume is mounted and in use. Here is the whole operation:

<details class="predict">
<summary><code>lvextend -L +500M</code> succeeds and reports the volume grew from 300 MiB to 800 MiB. What does <code>df -h</code> show immediately afterwards?</summary>

```bash
# AlmaLinux 10.2, aarch64
$ df -h /mnt/web | tail -1; echo "--- grow the logical volume ---"; lvextend -L +500M /dev/data/web; df -h /mnt/web | tail -1; echo "--- now grow the filesystem inside it ---"; resize2fs /dev/data/web; df -h /mnt/web | tail -1
/dev/mapper/data-web  272M   14K  253M   1% /mnt/web
--- grow the logical volume ---
  Size of logical volume data/web changed from 300.00 MiB (75 extents) to 800.00 MiB (200 extents).
  Logical volume data/web successfully resized.
/dev/mapper/data-web  272M   14K  253M   1% /mnt/web
--- now grow the filesystem inside it ---
resize2fs 1.47.1 (20-May-2024)
Filesystem at /dev/data/web is mounted on /mnt/web; on-line resizing required
old_desc_blocks = 3, new_desc_blocks = 7
The filesystem on /dev/data/web is now 819200 (1k) blocks long.

/dev/mapper/data-web  740M   14K  702M   1% /mnt/web
```

**`df` shows exactly the same 272M.** Not a rounding difference, the identical
line, before and after a command that reported complete success.

The reason is the layering from lesson 12. `lvextend` operates on the **volume**;
`df` reports the **filesystem**. Making the container bigger does not make its
contents bigger, and the filesystem is still using precisely the blocks it was
created with. There is now 500 MiB of space inside the volume that no filesystem
has claimed.

`resize2fs` is what tells the filesystem to expand into it, and only then does
`df` move, 272M to 740M.

**Nothing warned you.** `lvextend` did what it was asked and succeeded. There is no
error state here, just a job left half done, and the machine will keep filling up
while `vgs` cheerfully reports free space in the group. That is what makes this
the most common LVM mistake there is.

</details>

So the operation is always **two steps**, and the second one depends on the
filesystem:

| Filesystem | Grow command | Notes |
| --- | --- | --- |
| ext4 | `resize2fs /dev/vg/lv` | Works mounted. Takes no size: fills the volume. |
| XFS | `xfs_growfs /mount/point` | **Takes the mount point, not the device.** |
| Btrfs | `btrfs filesystem resize max /mount/point` | |

**Note the XFS asymmetry.** `resize2fs` takes a device; `xfs_growfs` takes a mount
point. Getting them the wrong way round is a small, annoying, extremely common
error, and the reason is that XFS can only be grown while mounted so it works in
terms of the mount.

Or skip the second step entirely by asking `lvextend` to do it:

```
lvextend -L +500M --resizefs /dev/data/web
```

`-r` is the short form. It calls the right resize tool for the filesystem it
finds. **Use it.** The only reason to do the two steps separately is to understand
what `-r` is doing, which is what the capture above is for.

And `-l +100%FREE` is the other flag worth memorising. It takes everything
left in the group rather than a number you had to work out:

```
lvextend -l +100%FREE -r /dev/data/web
```

<details class="deeper">
<summary>If you already administer Linux: snapshots, thin pools, pvmove, and the devices file</summary>

**Snapshots** are copy-on-write and are the reason to reach for LVM even on a
single disk. `lvcreate -s -n web-snap -L 2G /dev/data/web` gives a frozen view
for the duration of a backup, so a database dumps consistently without going
offline. The trap is capacity: a snapshot stores *changed* blocks, and when it
fills it is **dropped**, invalidating the backup in progress. Size it for the
write volume during the window, monitor `lvs` for the `Data%` column, and
delete it as soon as the backup finishes, a forgotten snapshot degrades write
performance indefinitely.

**Thin provisioning** (`lvmthin`) lets the sum of volume sizes exceed the pool, on
the assumption they will not all fill. That is a genuinely useful trade for
virtual machine images and a genuinely dangerous one otherwise: when a thin pool
fills, every filesystem on it takes I/O errors at once, and recovering is far
harder than having said no in the first place. Monitor pool usage, set
`autoextend` thresholds in `lvm.conf`, and treat the alert as urgent.

**`pvmove`** relocates extents off a physical volume while everything stays
online, which is how you retire a failing disk: `pvmove /dev/sdb`, then
`vgreduce data /dev/sdb`, then `pvremove`. It is slow and restartable, and it is
one of the genuinely impressive things LVM does.

**The devices file** (`/etc/lvm/devices/system.devices`, visible in the capture
above) replaced `global_filter` on recent releases. LVM now only considers devices
listed in it, which stops it scanning every disk on the machine. Add one with
`lvmdevices --adddev`, and know that this is why a disk from another machine may
not show up in `pvs` until you do.

**Striping and mirroring** exist (`lvcreate -i 2` stripes across two PVs, `-m
1` mirrors) but mdadm is the more common answer for redundancy, and that is
the next lesson. LVM on top of mdadm is the usual arrangement: mdadm handles
the disks failing, LVM handles the sizes changing.

**Shrinking** is possible for ext4 and Btrfs and never for XFS, and the order
reverses: filesystem first, then volume. Shrink the volume first and you have cut
the end off a filesystem that was still using it. `lvreduce -r` gets the order
right for you, and doing it by hand is one of the few places where reading the
command twice is genuinely warranted.

</details>

## Across distributions

| | RHEL family | Debian family |
| --- | --- | --- |
| LVM by default on install | Yes | No, unless chosen |
| Package | `lvm2` | `lvm2` |
| Typical root device | `/dev/mapper/rhel-root` | `/dev/sda1` |
| Root filesystem | XFS, so `xfs_growfs` | ext4, so `resize2fs` |

**The two defaults compound.** A RHEL-family machine is LVM plus XFS, so growing
root means `lvextend` then `xfs_growfs <mount point>` and shrinking is impossible.
A Debian machine is usually a plain partition plus ext4, so growing root means
repartitioning first. Same task, entirely different procedure, and assuming the
one you know is how people get stuck.


<details class="deeper">
<summary>If you already administer Linux: what to check before you trust an LVM machine you inherited</summary>

Four things, none of which show up in `df`.

**Is anything thin-provisioned?** `lvs -o +lv_layout,pool_lv` names the
layout. A thin pool can be over-committed, and when it fills, every filesystem
on it takes I/O errors simultaneously. `lvs` on a thin pool shows `Data%` and
`Meta%` columns, and **metadata exhaustion is the failure people miss**, a
pool with free data space and full metadata is just as broken.

**Are there forgotten snapshots?** A snapshot with a `Data%` climbing toward 100
will be dropped when it fills, silently invalidating whatever it was taken for.
One left behind after a backup degrades write performance indefinitely, because
every write to the origin now copies the old block first. `lvs` shows them with
an `s` in the `Attr` column.

**Does the volume group have room to breathe?** `vgs` with `VFree 0` means the
next capacity request needs a disk and a change window. Twenty per cent
unallocated is what turns a 2am alert into a one-line fix.

**Is the devices file current?** `/etc/lvm/devices/system.devices` replaced
`global_filter` on recent releases, and LVM only considers devices listed in it.
A disk moved from another machine will not appear in `pvs` until
`lvmdevices --adddev` is run, which presents as LVM refusing to see a disk that
is plainly there.

</details>

## Prove it

Before a resize:

```bash
# Is there room in the pool
sudo vgs

# What is the volume now, and what is the filesystem
sudo lvs
df -h /mnt/web
```

After:

```bash
# The volume grew
sudo lvs

# And so did the filesystem. This is the one that matters.
df -h /mnt/web
```

**`df` is the acceptance test, not `lvs`.** `lvs` confirms the volume changed,
which is the step that never fails. `df` confirms the thing the application will
actually experience.

## What trips people up

### 1. `lvextend` worked and `df` did not change

The whole subject of the prediction above. The volume grew; the filesystem did
not. `resize2fs /dev/vg/lv` for ext4, `xfs_growfs /mount/point` for XFS.

Use `lvextend -r` and it cannot happen.

### 2. "Insufficient free space"

`lvextend` refuses because the volume group has nothing left. `vgs` shows
`VFree 0`.

LVM does not create capacity; it manages it. You need a new disk: `pvcreate
/dev/sdc`, then `vgextend data /dev/sdc`, and the pool grows. Then extend.

That three-command sequence (pvcreate, vgextend, lvextend -r) is the whole
answer to "we need more space", and it is worth being able to type from
memory.

### 3. Mixing up the device and the mount point

`resize2fs` takes the device. `xfs_growfs` takes the mount point. `lvextend` takes
the device. `df` takes either.

There is no logic to remember here, only the fact. `-r` avoids it.

### 4. Forgetting LVM is there at all

`df` reports `/dev/mapper/rhel-root` and somebody goes looking for a partition of
that name. There is not one.

`lsblk` shows the whole stack at once (disk, partition, PV, LV) and is the
fastest way to orient on an unfamiliar machine.

### 5. Treating LVM as a backup or a redundancy layer

It is neither. A volume group spanning two disks loses **everything** when either
disk fails, because extents are spread across both and nothing is duplicated.
That is strictly worse than two separate disks.

Redundancy is the next lesson. LVM is about flexibility, and combining the two is
the normal arrangement rather than a choice between them.

## Work it through

A monitoring alert says `/var/lib/mysql` is at 97%. The server is live and the
database cannot be stopped.

```
$ df -h /var/lib/mysql
Filesystem                  Size  Used Avail Use% Mounted on
/dev/mapper/vg_data-mysql   200G  194G  6.1G  97% /var/lib/mysql
```

Reason it through before reading on.

**Is this even LVM?** Yes: `/dev/mapper/vg_data-mysql` names a volume
group and a logical volume. That single detail decides whether this is a
two-command fix or a maintenance window.

Second, is there room in the pool? `sudo vgs`. Two possibilities:

- **`VFree` shows 300G.** Somebody provisioned generously and left headroom. You
  are three minutes from done.
- **`VFree` shows 0.** The pool is fully allocated, and you need a disk before you
  can do anything. That is a different conversation and it involves other people.

**Which filesystem?** `findmnt /var/lib/mysql` or `lsblk -f`. XFS on a
RHEL-family box, most likely, which decides the second command and rules out ever
giving the space back.

With free space in the group, the whole operation is one line:

```
sudo lvextend -L +100G -r /dev/vg_data/mysql
```

Volume grown, filesystem grown, database never stopped, no unmount. `df` confirms
it.

**With no free space**, add a disk and extend the pool first:

```
sudo pvcreate /dev/sdd
sudo vgextend vg_data /dev/sdd
sudo lvextend -l +100%FREE -r /dev/vg_data/mysql
```

Still online, still no outage.

Now the question worth sitting with: **why can this be done live at all, when the
same job on a plain partition would need an outage?**

Because of what is *not* next to the volume. On a partitioned disk, growing
`/dev/sda3` means the space immediately after it must be free, and it is
occupied by `/dev/sda4`. The only ways out involve moving `/dev/sda4`, which means
unmounting it.

Under LVM, the volume is a set of extents scattered wherever there was room. There
is no "next to". Adding extents does not disturb anything, so nothing has to be
unmounted, so nothing has to stop.

**The habit worth taking:** on a new machine, look at `lsblk` before you need
it. Knowing whether you are on LVM, and how much `VFree` there is, converts a
2am capacity alert from an investigation into a command. And when you build
something, **do not allocate the whole volume group**, leaving 20% unallocated
is what makes that command available later.

## Try it

Optional, on a virtual machine with two spare disks. Do not do this on anything
you care about.

1. `sudo pvcreate /dev/sdb /dev/sdc`, then `sudo pvs`. Note the free space.
2. `sudo vgcreate testvg /dev/sdb /dev/sdc`, then `sudo vgs`. Compare `VSize` to
   the sum of the two disks and explain the difference.
3. `sudo lvcreate -n vol1 -L 1G testvg`, then `lsblk`. Say which physical disk it
   landed on and why.
4. `sudo mkfs.ext4 /dev/testvg/vol1`, mount it, `df -h`.
5. `sudo lvextend -L +1G /dev/testvg/vol1` and run `df -h` again **before** doing
   anything else. Confirm nothing changed.
6. `sudo resize2fs /dev/testvg/vol1`, then `df -h` once more.
7. Do it again with `lvextend -L +1G -r` and note that step 5 disappears.

**Verification step.** You have it when you can grow a mounted filesystem in one
command and explain, without looking, why `df` would not have moved if you had
left the `-r` off.

## Check yourself

<details class="qa">
<summary>Name the three LVM layers from the bottom up, and the command that creates each.</summary>

**Physical volume**, a disk or partition handed to LVM, created with
`pvcreate`. It stops being usable directly.

**Volume group**, a pool made from one or more physical volumes, created with
`vgcreate`. This is where capacity lives.

**Logical volume**, a slice taken from the pool, created with `lvcreate`. It
behaves exactly like a partition and is what you run `mkfs` on.

The reporting commands mirror them: `pvs`, `vgs`, `lvs`. `vgs` is the one to check
before any resize, because its `VFree` column answers whether the resize is
possible at all.

</details>

<details class="qa">
<summary><code>lvextend</code> reports success and <code>df</code> is unchanged. What happened and what is the fix?</summary>

**The volume grew and the filesystem did not.** They are separate layers.
`lvextend` made the container bigger; the filesystem inside it is still using
exactly the blocks it was created with, so `df`, which reports the filesystem,
reports the same number.

Nothing failed. There is simply unclaimed space inside the volume now.

The fix depends on the filesystem: `resize2fs /dev/vg/lv` for ext4, `xfs_growfs
/mount/point` for XFS. Note that one takes a device and the other takes a mount
point, which is a small piece of arbitrary trivia worth remembering.

Better: `lvextend -r` does both, picking the right tool for the filesystem it
finds, and removes the whole failure mode.

</details>

<details class="qa">
<summary>Why can an LVM volume be grown while mounted, when a partition cannot?</summary>

**Because nothing is next to it.** A partition is a contiguous region defined
by a start and an end sector, so growing it requires the sectors immediately
after it to be free, and they belong to the next partition. Freeing them means
moving that partition, which means unmounting it.

A logical volume is a set of extents allocated from a pool. They need not be
contiguous, need not be in order, and need not be on the same physical disk.
Growing it means taking more extents from wherever there is room, which disturbs
nothing.

Since nothing is disturbed, nothing has to be unmounted, and both ext4 and XFS
support growing while mounted. The database never stops.

</details>

<details class="qa">
<summary><code>vgs</code> shows <code>VFree 0</code> and you need another 500 GB. What are the three commands, in order?</summary>

```
sudo pvcreate /dev/sdd
sudo vgextend vg_data /dev/sdd
sudo lvextend -l +100%FREE -r /dev/vg_data/mysql
```

**`pvcreate`** hands the new disk to LVM. **`vgextend`** adds it to the existing
pool, which is the step that makes `VFree` non-zero. **`lvextend -l +100%FREE -r`**
takes everything now available and grows the filesystem in the same breath.

LVM manages capacity; it does not create it. When the group is full the answer is
always a new physical volume first.

All three run with the filesystem mounted and in use.

</details>

<details class="qa">
<summary>A volume group spans two disks and one of them fails. What happens, and what does that tell you about what LVM is for?</summary>

**You lose the entire volume group**, including volumes that appear to live
entirely on the surviving disk. Extents are allocated from a single pool with no
duplication, so half of the pool disappearing takes every filesystem in it with
it.

That is **worse** than two independent disks, where a failure would have cost you
one of them.

What it tells you: LVM is a flexibility layer, not a redundancy layer. It answers
"how do I resize this without downtime", not "how do I survive a disk failure".

Redundancy is mdadm's job, and the normal arrangement is both, RAID underneath
handling failure, LVM on top handling size. They solve different problems and
neither substitutes for the other, and neither is a backup.

</details>

## References

- [lvm(8)](https://man7.org/linux/man-pages/man8/lvm.8.html) - Linux man-pages project. Accessed 2026-08-07.
- [lvcreate(8)](https://man7.org/linux/man-pages/man8/lvcreate.8.html) - Linux man-pages project. Accessed 2026-08-07.
- [lvresize(8)](https://man7.org/linux/man-pages/man8/lvresize.8.html) - Linux man-pages project, for the sign convention and the `-r` option. Accessed 2026-08-21.
- [lvchange(8)](https://man7.org/linux/man-pages/man8/lvchange.8.html) - Linux man-pages project, for activation. Accessed 2026-08-21.
- [lvextend(8)](https://man7.org/linux/man-pages/man8/lvextend.8.html) - Linux man-pages project. Accessed 2026-08-07.
- [vgcreate(8)](https://man7.org/linux/man-pages/man8/vgcreate.8.html) - Linux man-pages project. Accessed 2026-08-07.
- [resize2fs(8)](https://man7.org/linux/man-pages/man8/resize2fs.8.html) - Linux man-pages project. Accessed 2026-08-07.
- [xfs_growfs(8)](https://man7.org/linux/man-pages/man8/xfs_growfs.8.html) - Linux man-pages project. Accessed 2026-08-07.
- [lvmthin(7)](https://man7.org/linux/man-pages/man7/lvmthin.7.html) - Linux man-pages project. Accessed 2026-08-07.

Every block above with a distribution and architecture header was captured by running the command on an AlmaLinux 10.2 container. Blocks without one are illustrative.
