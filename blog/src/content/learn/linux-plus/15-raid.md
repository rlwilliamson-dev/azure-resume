---
title: "RAID"
description: "Disks fail. RAID is how a server keeps running through it, what each level costs you in capacity, and the commands for building an array, breaking one on purpose, and putting it back."
deck: "Staying up while a disk dies"
track: "linux-plus"
level: "deep"
order: 160
objectives:
  - "Choose a RAID level from a requirement, and say what it costs in capacity"
  - "Build an array, read its status, and tell degraded from failed"
  - "Replace a failed member and confirm the rebuild finished"
  - "Explain why RAID is not a backup, with a specific example"
prerequisites: ["lvm"]
tags: ["linux", "linux-plus", "storage", "raid", "mdadm"]
updated: 2026-08-07
draft: false
examObjectives:
  - exam: "xk0-006"
    domain: "1.0"
    objective: "1.3"
sources:
  - title: "mdadm(8)"
    url: "https://man7.org/linux/man-pages/man8/mdadm.8.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "md(4)"
    url: "https://man7.org/linux/man-pages/man4/md.4.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "mdadm.conf(5)"
    url: "https://man7.org/linux/man-pages/man5/mdadm.conf.5.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
symptoms:
  - symptom: "mdstat shows [2/1] [_U] instead of [UU]"
    anchor: "1-the-array-says-u-and-nobody-noticed"
  - symptom: "Array will not assemble after a reboot"
    anchor: "4-the-array-does-not-come-back-after-a-reboot"
---

> **Before you read.** Hard disks fail. Not occasionally, predictably, at a
> rate you can put in a spreadsheet. A rack of forty disks will lose one or
> two a year and nobody considers that remarkable.
>
> And yet servers stay up for years without anybody restoring a backup.
>
> **How does a machine keep serving files off a disk that has stopped working?**

By not depending on any one disk. Several disks are presented to the operating
system as one device, with enough duplication that losing a member is survivable.
The filesystem above never notices.

The interesting part is the arithmetic underneath, how much capacity that
costs, how many failures it survives, and what it does not protect you from,
which is more than people assume.

### Some words you will need

<dl class="terms">
<dt>array</dt>
<dd>Several disks presented as one block device. On Linux, <code>/dev/md0</code>.</dd>
<dt>member</dt>
<dd>One of the disks in the array.</dd>
<dt>striping</dt>
<dd>Splitting data across disks so several can be read at once. Faster, no protection.</dd>
<dt>mirroring</dt>
<dd>Writing the same data to two disks. Protection, at half the capacity.</dd>
<dt>parity</dt>
<dd>Extra data from which any one missing piece can be recalculated. Protection, at the cost of one disk.</dd>
<dt>degraded</dt>
<dd>Running with a member missing. Still working, no longer protected.</dd>
</dl>

## What breaks without this

**A single disk failure becomes an outage.** Restoring from backup takes hours and
loses everything since the last one.

**Or you have RAID and do not know how to read it.** An array can sit degraded for
months, working perfectly, until the second disk goes and takes everything. The
machine never complained because from its point of view nothing was wrong.

**You trust it for the wrong thing.** RAID protects against a disk failing. It does
nothing about deletion, corruption, ransomware, or fire, and treating it as a
backup is how organisations lose data while technically having redundancy.

## The levels

<figure class="learn-figure">
<svg viewBox="0 0 720 400" role="img" aria-labelledby="raid-title raid-desc" style="width:100%;height:auto;">
  <title id="raid-title">How RAID 0, 1, 5, and 10 lay data across disks</title>
  <desc id="raid-desc">RAID 0 stripes blocks across two disks with no duplication: full capacity, survives no failures. RAID 1 writes identical blocks to both disks: half capacity, survives one failure. RAID 5 spreads data blocks and a parity block across three disks, with the parity block on a different disk each row: capacity of all disks minus one, survives one failure. RAID 10 mirrors pairs of disks and stripes across the pairs: half capacity, survives one failure per mirror pair.</desc>
  <g font-size="11">
    <!-- RAID 0 -->
<text x="20" y="22" font-size="12.5" fill="currentColor">RAID 0, striping</text>
    <text x="20" y="40" font-size="10" fill="currentColor" fill-opacity="0.65">disk 1        disk 2</text>
    <g fill="currentColor" fill-opacity="0.65" stroke="currentColor" stroke-opacity="0.3">
      <rect x="20" y="48" width="52" height="22" rx="3"/><rect x="78" y="48" width="52" height="22" rx="3"/>
      <rect x="20" y="74" width="52" height="22" rx="3"/><rect x="78" y="74" width="52" height="22" rx="3"/>
      <rect x="20" y="100" width="52" height="22" rx="3"/><rect x="78" y="100" width="52" height="22" rx="3"/>
    </g>
    <g fill="currentColor" text-anchor="middle" font-size="10.5">
      <text x="46" y="63">A1</text><text x="104" y="63">A2</text>
      <text x="46" y="89">A3</text><text x="104" y="89">A4</text>
      <text x="46" y="115">A5</text><text x="104" y="115">A6</text>
    </g>
    <text x="150" y="63" font-size="10" fill="currentColor" fill-opacity="0.65">capacity: all of it</text>
    <text x="150" y="79" font-size="10" fill="currentColor" fill-opacity="0.65">survives: nothing</text>
    <text x="150" y="95" font-size="10" fill="currentColor" fill-opacity="0.65">lose one disk, lose</text>
    <text x="150" y="111" font-size="10" fill="currentColor" fill-opacity="0.65">every file on both</text>
    <!-- RAID 1 -->
<text x="380" y="22" font-size="12.5" fill="currentColor">RAID 1, mirroring</text>
    <text x="380" y="40" font-size="10" fill="currentColor" fill-opacity="0.65">disk 1        disk 2</text>
    <g fill="currentColor" fill-opacity="0.65" stroke="currentColor" stroke-opacity="0.3">
      <rect x="380" y="48" width="52" height="22" rx="3"/><rect x="438" y="48" width="52" height="22" rx="3"/>
      <rect x="380" y="74" width="52" height="22" rx="3"/><rect x="438" y="74" width="52" height="22" rx="3"/>
      <rect x="380" y="100" width="52" height="22" rx="3"/><rect x="438" y="100" width="52" height="22" rx="3"/>
    </g>
    <g fill="currentColor" text-anchor="middle" font-size="10.5">
      <text x="406" y="63">A1</text><text x="464" y="63">A1</text>
      <text x="406" y="89">A2</text><text x="464" y="89">A2</text>
      <text x="406" y="115">A3</text><text x="464" y="115">A3</text>
    </g>
    <text x="510" y="63" font-size="10" fill="currentColor" fill-opacity="0.65">capacity: half</text>
    <text x="510" y="79" font-size="10" fill="currentColor" fill-opacity="0.65">survives: 1 disk</text>
    <text x="510" y="95" font-size="10" fill="currentColor" fill-opacity="0.65">the simple one, and</text>
    <text x="510" y="111" font-size="10" fill="currentColor" fill-opacity="0.65">what /boot uses</text>
    <!-- RAID 5 -->
<text x="20" y="212" font-size="12.5" fill="currentColor">RAID 5, striping with parity</text>
    <text x="20" y="230" font-size="10" fill="currentColor" fill-opacity="0.65">disk 1        disk 2        disk 3</text>
    <g fill="currentColor" fill-opacity="0.65" stroke="currentColor" stroke-opacity="0.3">
      <rect x="20" y="238" width="52" height="22" rx="3"/><rect x="78" y="238" width="52" height="22" rx="3"/><rect x="136" y="238" width="52" height="22" rx="3"/>
      <rect x="20" y="264" width="52" height="22" rx="3"/><rect x="78" y="264" width="52" height="22" rx="3"/><rect x="136" y="264" width="52" height="22" rx="3"/>
      <rect x="20" y="290" width="52" height="22" rx="3"/><rect x="78" y="290" width="52" height="22" rx="3"/><rect x="136" y="290" width="52" height="22" rx="3"/>
    </g>
    <g fill="currentColor" text-anchor="middle" font-size="10.5">
      <text x="46" y="253">A1</text><text x="104" y="253">A2</text><text x="162" y="253" fill-opacity="0.65">Ap</text>
      <text x="46" y="279">B1</text><text x="104" y="279" fill-opacity="0.65">Bp</text><text x="162" y="279">B2</text>
      <text x="46" y="305" fill-opacity="0.65">Cp</text><text x="104" y="305">C1</text><text x="162" y="305">C2</text>
    </g>
    <text x="205" y="253" font-size="10" fill="currentColor" fill-opacity="0.65">capacity: n minus 1</text>
    <text x="205" y="269" font-size="10" fill="currentColor" fill-opacity="0.65">survives: 1 disk</text>
    <text x="205" y="285" font-size="10" fill="currentColor" fill-opacity="0.65">p = parity, and it</text>
    <text x="205" y="301" font-size="10" fill="currentColor" fill-opacity="0.65">moves disk each row</text>
    <!-- RAID 10 -->
<text x="380" y="212" font-size="12.5" fill="currentColor">RAID 10, mirrors, striped</text>
    <text x="380" y="230" font-size="10" fill="currentColor" fill-opacity="0.65">disk 1  disk 2   disk 3  disk 4</text>
    <g fill="currentColor" fill-opacity="0.65" stroke="currentColor" stroke-opacity="0.3">
      <rect x="380" y="238" width="40" height="22" rx="3"/><rect x="424" y="238" width="40" height="22" rx="3"/>
      <rect x="474" y="238" width="40" height="22" rx="3"/><rect x="518" y="238" width="40" height="22" rx="3"/>
      <rect x="380" y="264" width="40" height="22" rx="3"/><rect x="424" y="264" width="40" height="22" rx="3"/>
      <rect x="474" y="264" width="40" height="22" rx="3"/><rect x="518" y="264" width="40" height="22" rx="3"/>
    </g>
    <g fill="currentColor" text-anchor="middle" font-size="10.5">
      <text x="400" y="253">A1</text><text x="444" y="253">A1</text><text x="494" y="253">A2</text><text x="538" y="253">A2</text>
      <text x="400" y="279">A3</text><text x="444" y="279">A3</text><text x="494" y="279">A4</text><text x="538" y="279">A4</text>
    </g>
    <g stroke="currentColor" stroke-opacity="0.35" fill="none">
      <path d="M380 294 L380 300 L464 300 L464 294"/>
      <path d="M474 294 L474 300 L558 300 L558 294"/>
    </g>
    <text x="422" y="313" text-anchor="middle" font-size="10" fill="currentColor" fill-opacity="0.65">mirror</text>
    <text x="516" y="313" text-anchor="middle" font-size="10" fill="currentColor" fill-opacity="0.65">mirror</text>
    <text x="380" y="336" font-size="10" fill="currentColor" fill-opacity="0.65">capacity: half · survives: one per pair</text>
    <text x="380" y="352" font-size="10" fill="currentColor" fill-opacity="0.65">fast rebuilds, and what databases want</text>
  </g>
</svg>
<figcaption>Capacity, speed, and how many failures you survive. Pick two.</figcaption>
</figure>

| Level | Disks | Usable | Survives | Reach for it when |
| --- | --- | --- | --- | --- |
| 0 | 2+ | 100% | **Nothing** | Speed matters and the data is disposable |
| 1 | 2 | 50% | 1 disk | Two disks, and you want it simple. `/boot` lives here. |
| 5 | 3+ | n−1 | 1 disk | Capacity matters and writes are light |
| 6 | 4+ | n−2 | 2 disks | Large disks, where a rebuild is a long exposure |
| 10 | 4+ | 50% | 1 per pair | Databases. Fast, and rebuilds quickly. |

**RAID 0 is not RAID in the sense anyone means it.** It has no redundancy and it
*doubles* your risk: two disks, either one takes everything. The zero is
appropriate.

RAID 5's write cost is the thing the table cannot show. Changing one block
means reading the old block and the old parity, computing the new parity, and
writing both, four operations for one logical write. On a database that hurts.
On a file archive nobody notices.

Parity is arithmetic, not a copy. Ap is computed from A1 and A2 such that any
one of the three can be reconstructed from the other two. That is why n−1
disks of capacity protects n disks, and why a rebuild is CPU work rather than
a straight copy.

<details class="deeper">
<summary>If you already administer Linux: RAID 10 and RAID 0+1 are not the same, and one of them is much worse</summary>

Both combine mirroring and striping across four disks. Both give the same usable
capacity and roughly the same speed. Their survivability differs enormously, and
the difference is purely which operation is on the inside.

**RAID 1+0, "ten": mirror first, then stripe the mirrors.** Two mirrored pairs,
striped together.

**RAID 0+1: stripe first, then mirror the stripes.** Two striped sets, mirrored
against each other.

Now lose one disk, then a second:

| | RAID 10 | RAID 0+1 |
| --- | --- | --- |
| First disk fails | One mirror is degraded. Fine. | That whole **stripe set** is dead. Fine, the other mirrors it. |
| Second disk fails, other side | Fine. Different mirror. | **Total loss.** Both stripe sets are now dead. |
| Second disk fails, same pair | Total loss | Total loss |
| Survives two failures | **Four times in six** | **Never**, unless it is the same set |

**With RAID 0+1, losing one disk kills half the array immediately**, because a
stripe set has no redundancy within it. Any subsequent failure on the surviving
side is fatal. With RAID 10, a single failure degrades one small mirror and every
other disk is still protected.

Rebuild cost differs the same way. RAID 10 rebuilds by copying **one disk** from
its partner. RAID 0+1 has to rebuild the entire dead stripe set from the surviving
one, which is more data, takes longer, and stresses every disk on the good side
for the whole window.

**`mdadm --level=10` gives you RAID 10 properly**, and Linux's implementation
is more flexible than the textbook version, it accepts an odd number of disks
and supports layouts (`--layout=f2`, "far", which improves read throughput on
spinning disks by placing copies at distant offsets).

**Nobody deliberately builds 0+1**, and the reason to know it is that hardware
controllers sometimes label it confusingly, and "RAID 10" in a vendor menu is
occasionally 0+1 underneath. `cat /proc/mdstat` and the controller's own topology
view are worth checking rather than trusting the label.

</details>

## Building an array

A RAID 1 mirror is created from two blank 512 MiB disks. Both are new and contain
nothing.

<details class="predict">
<summary>The two disks are empty, so there is nothing to copy from one to the other. Does the array come up ready to use immediately, or does <code>/proc/mdstat</code> show it doing work?</summary>

```bash
# AlmaLinux 10.2, aarch64
$ mdadm --create /dev/md0 --level=1 --raid-devices=2 $DEVS --run; echo; cat /proc/mdstat
mdadm: Note: this array has metadata at the start and
    may not be suitable as a boot device.  If you plan to
    store '/boot' on this device please ensure that
    your boot-loader understands md/v1.x metadata, or use
    --metadata=0.90
mdadm: Defaulting to version 1.2 metadata
mdadm: array /dev/md0 started.

Personalities : [raid1] 
md0 : active raid1 loop1[1] loop0[0]
      523264 blocks super 1.2 [2/2] [UU]
      [>....................]  resync =  0.1% (1024/523264) finish=8.3min speed=1024K/sec
      
unused devices: <none>
```

</details>

**It resyncs anyway**, and the array is usable the whole time. The kernel has
no way to know the disks are blank, "empty" is not a thing a block device
reports, so it copies every block from one to the other to guarantee they
match. On two 512 MiB loop devices that takes minutes; on a pair of 20 TB
disks it takes a day, and the array is degraded-but-working throughout.

`--assume-clean` skips it, and is safe only when you genuinely know both members
are identical. Getting that wrong on a mirror means the two halves disagree and
reads return whichever one they land on.

**Learn to read `/proc/mdstat`**, because it is the fastest health check there is
and it is the same on every distribution.

- `active raid1 loop1[1] loop0[0]`, the level and the members, with their
  index in the array.
- `[2/2]`, two members expected, two present.
- `[UU]`, one character per member. **`U` is up, `_` is missing.**
- The progress bar is the initial resync, making both halves identical. The array
  is usable during it, just slower.

`--run` skips the confirmation prompt. The warning about metadata is worth
reading once: version 1.2 metadata sits near the *start* of the member, which
older bootloaders cannot see past, hence the note about `/boot`.

A three-disk RAID 5, and the arithmetic:

```bash
# AlmaLinux 10.2, aarch64
$ mdadm --create /dev/md0 --level=5 --raid-devices=3 $DEVS --run 2>/dev/null; sleep 3; mdadm --detail /dev/md0 | head -22
mdadm: Defaulting to version 1.2 metadata
mdadm: array /dev/md0 started.
/dev/md0:
           Version : 1.2
     Creation Time : Sat Aug  8 01:12:45 2026
        Raid Level : raid5
        Array Size : 1044480 (1020.00 MiB 1069.55 MB)
     Used Dev Size : 522240 (510.00 MiB 534.77 MB)
      Raid Devices : 3
     Total Devices : 3
       Persistence : Superblock is persistent

       Update Time : Sat Aug  8 01:12:48 2026
             State : clean 
    Active Devices : 3
   Working Devices : 3
    Failed Devices : 0
     Spare Devices : 0

            Layout : left-symmetric
        Chunk Size : 512K

Consistency Policy : resync
```

**Three 512 MiB disks give a 1020 MiB array.** Two disks' worth of capacity, one
disk's worth spent on parity. That is the n−1 rule, in numbers you can check.

`State: clean` and `Failed Devices: 0` are the two lines to read on a health
check. `mdadm --detail` is the verbose view; `/proc/mdstat` is the one you glance
at.


<details class="deeper">
<summary>If you already administer Linux: chunk size, metadata versions, and the write hole</summary>

**Chunk size** is how much goes on one member before moving to the next, 512 KiB
by default. It is set at creation and cannot be changed without rebuilding the
array. Large chunks suit large sequential files; small chunks suit random I/O
across many small ones. The default is a reasonable compromise and worth changing
only when you can measure the workload.

Metadata version decides where the superblock sits, which is why `mdadm`
warned about `/boot` when the array was created. Version 1.2 puts it 4 KiB
from the start of the member, so a bootloader reading the raw device sees the
metadata rather than a filesystem. Version 1.0 puts it at the **end**, which
means a RAID 1 member is byte-identical to a plain filesystem from the front,
and therefore readable by firmware that knows nothing about RAID. That is why
`/boot` on software RAID is conventionally RAID 1 with `--metadata=1.0`.

The RAID 5 write hole is the failure nobody plans for. A stripe update is not
atomic: lose power between writing the data and writing the parity and the
stripe is now inconsistent, with no record that it is. The array comes back
looking healthy and the corruption surfaces during a later rebuild, when the
bad parity is used to reconstruct a block. A write-intent bitmap does not fix
this; a battery-backed controller cache or a journal (`--write-journal`) does,
and so does using RAID 10.

**Scrubbing** finds the damage while there is still redundancy to repair it with:
`echo check > /sys/block/md0/md/sync_action`, and `mismatch_cnt` afterwards. Most
distributions ship a monthly timer for this; confirm yours does rather than
assuming.

</details>

## Losing a disk

<details class="predict">
<summary>A two-disk RAID 1 holds a file. One member is failed. What does <code>/proc/mdstat</code> show, and can you still read the file?</summary>

```bash
# AlmaLinux 10.2, aarch64
$ cat /proc/mdstat | head -4; echo "--- pull a disk ---"; mdadm --manage /dev/md0 --fail $DEV0; cat /proc/mdstat | head -4; echo "--- is the data still there? ---"; cat /mnt/raid/important.txt
Personalities : [raid1] [raid4] [raid5] [raid6] 
md0 : active raid1 loop1[1] loop0[0]
      523264 blocks super 1.2 [2/2] [UU]
      
--- pull a disk ---
Personalities : [raid1] [raid4] [raid5] [raid6] 
md0 : active raid1 loop1[1] loop0[0](F)
      523264 blocks super 1.2 [2/1] [_U]
      
--- is the data still there? ---
payroll data
```

**Three changes and the data is fine.**

`loop0[0]` gained an `(F)`, that member is flagged failed. `[2/2]` became
`[2/1]`: two expected, one present. `[UU]` became `[_U]`: the first member is
down, the second is up.

The file reads perfectly. The filesystem was never told anything happened; from
its point of view `/dev/md0` is the same block device it always was, and the RAID
layer quietly served every request from the surviving member.

**This is the state that gets people killed.** The array is *degraded*, not
failed. Everything works. Performance is normal. Nothing on the console,
nothing in the application logs, no user complains. And there is now **zero**
redundancy, the next disk failure takes all of it.

`[_U]` instead of `[UU]` is the single most important thing to monitor on a
machine with software RAID, and it is four characters in a file most people never
read.

</details>

## Putting it back

```bash
# AlmaLinux 10.2, aarch64
$ mdadm --manage /dev/md0 --remove $DEV0 >/dev/null; mdadm --manage /dev/md0 --add $DEV2; sleep 2; echo; cat /proc/mdstat | head -5; echo "--- wait for it to finish ---"; while grep -q recovery /proc/mdstat; do sleep 2; done; cat /proc/mdstat | head -4
mdadm: hot removed /dev/loop0 from /dev/md0
mdadm: added /dev/loop2

Personalities : [raid1] [raid4] [raid5] [raid6] 
md0 : active raid1 loop2[2] loop1[1]
      523264 blocks super 1.2 [2/1] [_U]
      [===============>.....]  recovery = 76.6% (401792/523264) finish=0.0min speed=200896K/sec
      
--- wait for it to finish ---
Personalities : [raid1] [raid4] [raid5] [raid6] 
md0 : active raid1 loop2[2] loop1[1]
      523264 blocks super 1.2 [2/2] [UU]
      
```

Two commands, then waiting. **`--remove` then `--add`**, and the rebuild
starts on its own. Note it says `recovery` rather than `resync`, resync is
making a new array consistent, recovery is rebuilding a replaced member. Same
bar, different word, and the word tells you which situation you are in.

**`[UU]` at the end is the acceptance test.** Until the bar reaches 100% the array
is still degraded and another failure is still fatal. On real hardware this is
hours rather than seconds, and that window is the whole argument for RAID 6.

The whole replacement procedure:

| Step | Command |
| --- | --- |
| Confirm which member failed | `cat /proc/mdstat`, `mdadm --detail /dev/md0` |
| Mark it failed, if it has not already | `mdadm --manage /dev/md0 --fail /dev/sdb` |
| Remove it from the array | `mdadm --manage /dev/md0 --remove /dev/sdb` |
| Physically swap the disk |, |
| Add the replacement | `mdadm --manage /dev/md0 --add /dev/sdb` |
| Watch the rebuild | `watch cat /proc/mdstat` |

**`--fail` before `--remove` even on a dead disk.** `--remove` refuses to take an
active member, and a disk the kernel has not given up on yet still counts as
active.

<details class="deeper">
<summary>If you already administer Linux: URE risk, bitmaps, monitoring, and the LVM ordering question</summary>

**Why RAID 5 is discouraged on large disks.** A rebuild reads every sector of every
surviving disk. Consumer drives quote an unrecoverable read error rate around one
in 10<sup>14</sup> bits, which is roughly one per 12 TB read. Rebuilding a
four-disk array of 8 TB drives reads 24 TB. The arithmetic is uncomfortable, and
an URE during a RAID 5 rebuild fails the rebuild. RAID 6 tolerates it because
there is a second parity to fall back on. This is the actual reason behind the
advice, and it is worth being able to state rather than repeat.

**Write-intent bitmaps** (`--bitmap=internal`) track which regions have been
written since the array was last consistent. After an unclean shutdown or a
briefly-removed disk, only those regions are resynced instead of the whole
array, minutes instead of hours. The cost is a small write penalty. On
anything large it is worth it, and `mdadm --grow --bitmap=internal /dev/md0`
adds one to an existing array.

**Monitoring is not optional and is not automatic enough.** `mdadm --monitor
--scan --daemonise` with `MAILADDR` in `/etc/mdadm.conf` sends mail on a failure;
most distributions enable something equivalent, and most people never test it.
Test it: `mdadm --monitor --scan --test` sends a message immediately. An array
that degrades silently is worse than no array, because it produces confidence
that is not warranted.

**Spares.** `--spare-devices=1` keeps a disk idle in the array that is pulled in
automatically the moment one fails, which collapses the exposure window from "when
somebody notices" to "immediately". On any array you cannot reach quickly, a
spare is worth more than one more disk of capacity.

**RAID under LVM, not over.** Standard practice is mdadm on the disks, then
`pvcreate` on `/dev/md0`, then LVM on top. That way mdadm handles disks
failing and LVM handles volumes resizing, each doing what it is good at. The
other order, LVM's own `-m` mirroring across raw disks, works and is much less
common, so you get less tested code and colleagues who cannot read your setup.

**`mdadm.conf` and assembly.** Arrays are found at boot by scanning
superblocks, but `/etc/mdadm.conf` (`/etc/mdadm/mdadm.conf` on Debian) pins
the mapping from UUID to device name. After creating an array, run `mdadm
--detail --scan >> /etc/mdadm.conf` and rebuild the initramfs, otherwise the
array can come back as `/dev/md127`, and if root is on it, not come back at
all. This is lesson 09's initramfs rule arriving again in a different costume.

</details>

## Hardware, software, and the thing in between

| | Hardware RAID | Linux software RAID (mdadm) | Firmware / "fake" RAID |
| --- | --- | --- | --- |
| Where it runs | A dedicated controller | The kernel | The BIOS, then a driver |
| Disks portable to another machine | Usually only to the same controller | **To any Linux machine** | No |
| Battery-backed write cache | Yes, and it matters | No | No |
| Visible to the OS | One disk; members are hidden | Every member, plus `/dev/md0` | Messy |
| Cost | The controller | Free | "Free" |

**mdadm's portability is underrated.** The array metadata lives on the disks, so
moving them to any Linux machine and running `mdadm --assemble --scan` brings the
array up. A failed hardware controller, by contrast, frequently means sourcing the
same model before you can read your own data.

**Avoid firmware RAID.** It is a BIOS option that looks like hardware RAID and is
software RAID with a proprietary on-disk format and worse tooling. If the machine
has it enabled, turning it off and using mdadm is almost always the better answer.


<details class="deeper">
<summary>If you already administer Linux: growing an array, and identifying the disk you are about to pull</summary>

**Arrays can grow.** `mdadm --add` then `mdadm --grow --raid-devices=5` reshapes
a four-disk RAID 5 into five, online, redistributing every stripe. It takes hours
to days and it is genuinely dangerous to interrupt without a backup file
(`--backup-file=` on a separate device), because a reshape that loses its
progress record with no backup is unrecoverable. `--grow --size=max` is the
other one: after replacing every member with a larger disk, one at a time, that
claims the new space.

**Identifying the physical disk** is the step that goes wrong in the data centre.
`/dev/sdb` tells you nothing about which bay to open, and pulling the wrong disk
from a degraded array ends the array. Three ways to be sure, in order of
preference: `lsblk -o NAME,SERIAL,MODEL` and match the serial to the label on the
carrier; `ledctl locate=/dev/sdb` to light the drive's fault LED where the
backplane supports it; and `dd if=/dev/sdb of=/dev/null` while watching which
activity light is busy, which is crude and works everywhere.

Write the serial numbers down when you build the array. The moment you need them
is the moment the array is degraded and you are in a hurry.

**`mdadm --examine /dev/sdb`** reads the superblock on a single member rather
than asking about the assembled array, which is how you identify a disk found
loose in a drawer, or work out why a member is not being accepted back.

</details>

## Across distributions

| | RHEL family | Debian family |
| --- | --- | --- |
| Package | `mdadm` | `mdadm` |
| Config file | `/etc/mdadm.conf` | `/etc/mdadm/mdadm.conf` |
| Monitoring service | `mdmonitor.service` | `mdmonitor.service` |
| Rebuild initramfs after changes | `dracut -f` | `update-initramfs -u` |

The config file path is the only real difference and it is enough to break a
script that hardcodes one.

## Prove it

Health, in one line, worth putting in a login banner or a monitoring check:

```bash
# The whole answer, if you can read it
cat /proc/mdstat

# The verbose version
sudo mdadm --detail /dev/md0

# Is monitoring actually going to tell anyone
systemctl status mdmonitor
sudo mdadm --monitor --scan --test    # sends a test alert now
```

**Look for `[UU]`, not for absence of errors.** A degraded array produces no
errors. The only difference between healthy and one-failure-from-catastrophe is
an underscore.

## What trips people up

### 1. The array says `[_U]` and nobody noticed

Degraded arrays work. Applications are fine, users are fine, performance is
normal, and there is no redundancy left at all.

Monitor `/proc/mdstat`, and test that the monitoring works. An untested alert is
not an alert.

### 2. `--remove` refuses

`mdadm: hot remove failed for /dev/sdb: Device or resource busy`. The member is
still active as far as the kernel is concerned.

`--fail` it first, then `--remove`. Marking a dying disk as failed is safe and
is what the command is for.

### 3. Treating RAID as a backup

It is not, and the distinction is worth stating precisely: **RAID replicates
writes.** Delete a file and it is deleted on every member instantly. Encrypt the
volume with ransomware and every copy is encrypted. Corrupt a database and the
corruption is faithfully mirrored.

RAID protects against exactly one thing: **a disk failing.** Backups protect
against everything else, and everything else is most of what happens.

### 4. The array does not come back after a reboot

Usually a missing or stale `/etc/mdadm.conf`. The array assembles under a
different name, `/dev/md127` is the classic, and `/etc/fstab` cannot find it.

`mdadm --detail --scan >> /etc/mdadm.conf`, then rebuild the initramfs. Use
`UUID=` in fstab, which does not care what the array is called.

### 5. Rebuilding onto a smaller disk

Replacement disks must be at least as large as the smallest existing member. The
same nominal size from a different manufacturer can be very slightly smaller, and
`mdadm` will refuse with a size error that reads like a bug.

`--size` set slightly below the raw disk size at creation leaves room for this,
and is what array vendors do.

## Work it through

A file server has a four-disk RAID 5. Monday morning, `/proc/mdstat` reads:

```
md0 : active raid5 sdd1[3] sdc1[2] sdb1[1]
      5860532224 blocks super 1.2 level 5, 512k chunk, algorithm 2 [4/3] [_UUU]
```

The server is up, users have no complaints. Reason it through before reading on.

**Read the status first.** `[4/3]`, four members expected, three present.
`[_UUU]`. The first is gone. `sda1` is absent from the member list entirely,
so it has not merely failed, it has been dropped.

How bad is this? RAID 5 survives one failure. It has had one. So the array is
running with **no remaining protection**, and a second failure loses roughly
5.8 TB.

How long has it been like this? Nobody knows, which is the actual problem.
`sudo journalctl -k --since '7 days ago' | grep -i md` and the SMART data on
the remaining disks will give a timestamp. If the answer is "three weeks", the
monitoring is broken and that is a second incident.

**What comes first?** Not the disk swap. **Verify the backup.** The array is one
failure from total loss, and a rebuild is the most stressful thing you can do to
the surviving disks: it reads every sector of all three. If a second disk is
marginal, the rebuild is exactly what will finish it off.

Then check the others before rebuilding. `smartctl -a /dev/sdb` on each
survivor. Reallocated sectors or pending sectors on a second disk changes the
plan entirely. You would then be copying the array off to somewhere else
rather than rebuilding in place.

**Then replace.** `--fail` if not already, `--remove`, swap, `--add`, and watch.
For 5.8 TB expect many hours, during which the array is still degraded.

Now the question underneath: **why is a rebuild the riskiest moment in an array's
life?** Because it is the only time every sector of every surviving disk is read.
Disks accumulate unreadable sectors quietly; nothing finds them until something
reads them. A rebuild reads all of them at once, on disks that are the same age
and model as the one that just died, under sustained load.

That is the whole argument for **RAID 6** on large disks, for **scrubbing**
regularly so bad sectors surface while there is still redundancy, and for **hot
spares** so the window between failure and rebuild is seconds rather than days.

And the practical habit: **write down the monitoring check and test that it
fires.** This array degraded and told nobody. Every other decision here was
downstream of that.

## Try it

Optional, on a virtual machine with three spare disks. Genuinely do not do this on
anything real.

1. `sudo mdadm --create /dev/md0 --level=1 --raid-devices=2 /dev/sdb /dev/sdc`,
   then `cat /proc/mdstat`. Watch the initial resync.
2. `sudo mdadm --detail /dev/md0`. Compare `Array Size` to the disk sizes.
3. `sudo mkfs.ext4 /dev/md0`, mount it, write a file.
4. `sudo mdadm --manage /dev/md0 --fail /dev/sdb`, then read `/proc/mdstat` and
   your file. Note that nothing broke.
5. `--remove` it, `--add` the third disk, and watch the recovery bar.
6. Rebuild with `--level=5` and three disks. Confirm the capacity is n−1.
7. `sudo mdadm --monitor --scan --test` and find out whether anything reaches you.

**Verification step.** You have it when you can glance at a `/proc/mdstat` line
and say the level, how many members are missing, and whether another failure
would be survivable.

## Check yourself

<details class="qa">
<summary>Six 4 TB disks. Give the usable capacity and failures survived for RAID 0, 1, 5, 6, and 10.</summary>

**RAID 0**, 24 TB, survives nothing. Any one disk takes all of it.

**RAID 1**, 4 TB with all six mirrored, surviving five failures. In practice
you would not; RAID 1 is a two-disk arrangement.

**RAID 5**, 20 TB (n−1), survives one.

**RAID 6**, 16 TB (n−2), survives two. The right answer at this disk size,
because a rebuild of 4 TB members is long enough that a second failure during
it is a real possibility.

**RAID 10**, 12 TB (half), survives one per mirror pair, so up to three if you
are lucky and one if you are not. Fastest of these and the quickest to
rebuild, because rebuilding a mirror is a straight copy rather than a parity
calculation across every surviving disk.

</details>

<details class="qa">
<summary><code>/proc/mdstat</code> shows <code>[4/3] [_UUU]</code>. Explain each part and say how urgent it is.</summary>

**`[4/3]`**, four members expected, three present. **`[_UUU]`**, one character
per member in order; the first is down, the other three are up.

If this is RAID 5, it is **urgent**. RAID 5 survives exactly one failure and has
had it. There is now no redundancy: a second disk loses the entire array.

The array is working normally, which is what makes it dangerous. No errors, no
complaints, no performance change. The only visible difference between healthy and
one-failure-from-total-loss is that underscore.

If it is RAID 6, it is serious but not immediately critical, one failure of
tolerance remains, and it should still be fixed today.

</details>

<details class="qa">
<summary>Give two things RAID protects against and three it does not.</summary>

**Protects against:** a disk failing outright, and unreadable sectors on one disk
(which are reconstructed from the others).

**Does not protect against:** accidental deletion, which is replicated to
every member instantly; corruption, whether from a bug, a bad controller, or
ransomware, which is faithfully mirrored; and anything affecting the whole
machine, fire, theft, flood, a failed power supply that takes the backplane
with it.

The clean way to hold it: **RAID replicates writes.** Every write, including the
ones you did not want. It buys uptime through a hardware failure and nothing else.

Backups protect against the rest, and the rest is most of what actually happens.

</details>

<details class="qa">
<summary>Why is a rebuild the most dangerous moment in an array's life?</summary>

**It reads every sector of every surviving disk**, which nothing else ever does.

Disks accumulate unreadable sectors silently; a sector that has gone bad is not
discovered until something tries to read it. A rebuild reads all of them at once,
under sustained load, on disks that are the same age and model as the one that
just failed.

On RAID 5 an unrecoverable read error during a rebuild fails the rebuild, because
there is no second parity to fall back on. With multi-terabyte disks the odds of
hitting one across a full-array read are not small, which is the real argument
behind "RAID 5 is not appropriate for large disks".

Three mitigations: RAID 6, so one URE is survivable; regular scrubbing, so bad
sectors surface while redundancy still exists; and hot spares, so the rebuild
starts immediately rather than when somebody notices.

</details>

<details class="qa">
<summary>An array comes back as <code>/dev/md127</code> after a reboot and <code>/etc/fstab</code> cannot find it. What happened?</summary>

**The array was assembled by scanning superblocks, with no configuration pinning
its name.** `mdadm` numbers unknown arrays downward from 127, so an array with no
entry in `/etc/mdadm.conf` gets an arbitrary name rather than the `/dev/md0` you
created it as.

Two fixes, and you want both. Record the array: `sudo mdadm --detail --scan >>
/etc/mdadm.conf`, `/etc/mdadm/mdadm.conf` on Debian, then rebuild the
initramfs so the assembly happens correctly during early boot too.

And reference the filesystem in `/etc/fstab` by `UUID=` rather than by
`/dev/md0`, so the mount does not depend on the array's name at all.

If root is on the array, the missing config is not an inconvenience: the machine
will not boot, because the initramfs cannot assemble something it was never told
about.

</details>

## References

- [mdadm(8)](https://man7.org/linux/man-pages/man8/mdadm.8.html) - Linux man-pages project. Accessed 2026-08-07.
- [md(4)](https://man7.org/linux/man-pages/man4/md.4.html) - Linux man-pages project. Accessed 2026-08-07.
- [mdadm.conf(5)](https://man7.org/linux/man-pages/man5/mdadm.conf.5.html) - Linux man-pages project. Accessed 2026-08-07.

Every block above with a distribution and architecture header was captured by running the command on an AlmaLinux 10.2 container. Blocks without one are illustrative.
