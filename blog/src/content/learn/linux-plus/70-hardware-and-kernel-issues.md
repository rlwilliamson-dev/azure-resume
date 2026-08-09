---
title: "The logs mention a device you have never heard of"
description: "Hardware faults do not announce themselves politely. They arrive as kernel messages full of unfamiliar names, and the skill is deciding whether you are looking at a dying disk, a driver that never loaded, or software blaming the wrong thing."
track: "linux-plus"
level: "deep"
order: 710
objectives:
  - "Read dmesg for hardware errors and say which layer reported them"
  - "Decide whether a fault is hardware or software"
  - "Check a disk's own opinion of its health with SMART"
  - "Explain what a tainted kernel means and why support asks"
  - "Recognise memory errors, and know what ECC does and does not do"
prerequisites: ["the-kernel-and-modules", "hardware-and-device-discovery"]
tags: ["linux", "linux-plus", "troubleshooting", "hardware", "kernel"]
updated: 2026-08-09
draft: false
examObjectives:
  - exam: "xk0-006"
    domain: "5.0"
    objective: "5.2"
sources:
  - title: "dmesg(1)"
    url: "https://man7.org/linux/man-pages/man1/dmesg.1.html"
    publisher: "man7.org"
    accessed: 2026-08-09
    tier: 1
  - title: "smartctl(8)"
    url: "https://www.smartmontools.org/browser/trunk/smartmontools/smartctl.8.in"
    publisher: "smartmontools"
    accessed: 2026-08-09
    tier: 1
  - title: "Kernel documentation: tainted kernels"
    url: "https://docs.kernel.org/admin-guide/tainted-kernels.html"
    publisher: "kernel.org"
    accessed: 2026-08-09
    tier: 1
  - title: "Kernel documentation: machine check exceptions"
    url: "https://docs.kernel.org/arch/x86/x86_64/machinecheck.html"
    publisher: "kernel.org"
    accessed: 2026-08-09
    tier: 1
  - title: "dmsetup(8)"
    url: "https://man7.org/linux/man-pages/man8/dmsetup.8.html"
    publisher: "man7.org"
    accessed: 2026-08-09
    tier: 1
symptoms:
  - symptom: "Buffer I/O error or blk_update_request in the kernel log"
    anchor: "what-a-real-io-error-looks-like"
  - symptom: "Device present in lspci but no interface or disk appears"
    anchor: "present-but-not-working"
  - symptom: "Vendor support declines to help because the kernel is tainted"
    anchor: "taint"
---

> **Before you read.** The kernel log has three lines in it about `dm-0`, a
> device nobody configured, and the application is throwing errors that mention
> nothing of the sort.
>
> Somewhere below the software there is a piece of hardware, or something
> pretending to be one, and it has stopped cooperating.

Hardware problems are the ones people reach for last, which is usually correct
because they are the least common. When they do occur they are unmistakable if
you know the vocabulary, and baffling if you do not, because the kernel names
devices and layers rather than the applications you recognise.

This lesson is about reading those messages, and about the harder judgement
underneath: deciding whether the hardware is genuinely at fault before somebody
spends a day replacing a healthy disk.

### Some words you will need

<dl class="terms">
<dt>ring buffer</dt>
<dd>The kernel's in-memory log. What <code>dmesg</code> prints.</dd>
<dt>block layer</dt>
<dd>The kernel between filesystems and storage drivers. Reports as <code>blk_update_request</code>.</dd>
<dt>SMART</dt>
<dd>Self-monitoring built into drives. The disk's own view of its health.</dd>
<dt>taint</dt>
<dd>A flag recording that something happened which makes the kernel's behaviour unsupportable.</dd>
<dt>MCE</dt>
<dd>Machine check exception. The CPU reporting a hardware error to the operating system.</dd>
<dt>ECC</dt>
<dd>Memory that detects and corrects single-bit errors, and reports them.</dd>
<dt>device-mapper</dt>
<dd>The kernel layer behind LVM, encryption, and RAID. Its devices appear as <code>dm-N</code>.</dd>
</dl>

## What breaks without this

**Healthy hardware gets replaced.** A driver problem or a cable produces
identical symptoms to a failing disk, and the disk is what gets swapped.

**Failing hardware gets ignored.** Correctable errors are logged for weeks
before the uncorrectable one, and nobody was reading the log.

**Data is written to a dying disk.** Every repair attempt and every retry makes
recovery less likely.

**Support declines the case.** A tainted kernel means the vendor cannot
reproduce your configuration, and that is the first thing they check.

**The wrong layer is blamed.** An application error about a file is the last
link in a chain that started at the controller.

## What a real I/O error looks like

Rather than describing one, here is a device built to fail. Device-mapper has an
`error` target that returns a failure for every read, which produces the genuine
article without harming anything.

<details class="predict">
<summary>A block device is created whose every read fails. What does <code>dd</code> report, and what does the kernel log?</summary>

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ sudo dmsetup remove faultydisk 2>/dev/null
echo "--- a block device whose every read fails, built with device-mapper ---"
sudo dmsetup create faultydisk --table "0 2048 error"
sudo dd if=/dev/mapper/faultydisk of=/dev/null bs=512 count=1 2>&1 | tail -3
echo "--- what the kernel logged about it ---"
sudo dmesg | tail -3
sudo dmsetup remove faultydisk
--- a block device whose every read fails, built with device-mapper ---
0+0 records in
0+0 records out
0 bytes copied, 8.8084e-05 s, 0.0 kB/s
--- what the kernel logged about it ---
[30718.870606] Buffer I/O error on dev dm-0, logical block 0, async page read
[30718.870633] Buffer I/O error on dev dm-0, logical block 0, async page read
[30718.882536] Buffer I/O error on dev dm-0, logical block 0, async page read
```

</details>

Look at what `dd` said: `0 bytes copied`, no error text of its own worth reading.
The tool that failed is nearly silent. The kernel is where the explanation is.

`Buffer I/O error on dev dm-0, logical block 0` names three things: the layer
that noticed, the device, and the exact block. That precision is the point of
reading `dmesg` rather than application logs.

**Learn the shape of these messages, because the prefix tells you the layer:**

| Message begins | Layer | Suggests |
| --- | --- | --- |
| `Buffer I/O error on dev` | Block layer, buffered read path | The device below returned a failure |
| `blk_update_request: I/O error, dev sda, sector N` | Block layer | The most common real disk error. Note the sector |
| `critical medium error` | SCSI | The drive could not read that physical area. Genuine media failure |
| `ata1.00: failed command:` | ATA driver | Often cabling or a controller, not always the drive |
| `EXT4-fs error (device sda1)` | Filesystem | Filesystem noticed inconsistency. May be caused by the layer below |
| `nvme nvme0: I/O N QID N timeout` | NVMe driver | Device stopped responding. Firmware, thermal, or power |
| `Machine check events logged` | CPU | Hardware error the processor detected. Take seriously |

**The distinction that matters most is between a device that returned an error
and a device that stopped answering.** An error means the hardware is working
well enough to say no. A timeout means it stopped responding entirely, which is
more often a controller, a cable, power, or firmware than the media itself.

**And `dm-0` deserves a note**, because it is the name people find least
helpful. Device-mapper numbers its devices, so the message tells you nothing
about which volume it is. Translate it:

```bash
sudo dmsetup ls                    # names against dm-N
lsblk                              # the whole tree, names included
ls -l /dev/mapper/                 # symlinks pointing at dm-N
```

## Present but not working

The other family of hardware faults is the device that exists and does nothing,
and the diagnostic question is whether the kernel found it, bound a driver to
it, and brought it up. Those are three separate steps.

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ echo "--- what the kernel found on the PCI bus ---"; lspci 2>/dev/null | head -5 || echo "(no lspci on this image)"; echo "--- memory the firmware handed over ---"; sudo dmesg | grep -iE "Memory:|efi:" | head -3
--- what the kernel found on the PCI bus ---
00:00.0 Host bridge: Apple Inc. Device 1a05
00:01.0 Ethernet controller: Red Hat, Inc. Virtio 1.0 network device (rev 01)
00:05.0 Communication controller: Red Hat, Inc. Virtio 1.0 console (rev 01)
00:06.0 Mass storage controller: Red Hat, Inc. Virtio 1.0 block device (rev 01)
00:07.0 Mass storage controller: Red Hat, Inc. Virtio 1.0 file system (rev 01)
--- memory the firmware handed over ---
```

Five devices, and the mixture is worth noticing: an Apple host bridge because
this is a virtual machine on Apple hardware, and Red Hat virtio devices for
everything the hypervisor provides. On a physical server the same command lists
real controllers and network cards.

**`lspci` listing a device proves only that the bus enumerated it.** The next
question is whether a driver claimed it, and `-k` answers that:

```bash
lspci -k                    # each device with its kernel driver, if any
lspci -nn                   # with numeric vendor:device IDs, for searching
```

A device with no `Kernel driver in use` line is the classic "present but not
working" case. It means the hardware is fine and the software to operate it is
missing, which is a firmware package, a missing module, or a kernel too old for
the part.

**The sequence to work through:**

| Question | Command |
| --- | --- |
| Did the bus find it? | `lspci`, `lsusb`, `lsblk` |
| Did a driver bind to it? | `lspci -k`, `lsmod` |
| Did the driver complain? | `dmesg \| grep -i <driver>` |
| Is firmware missing? | `dmesg \| grep -i firmware` |
| Is the interface up? | `ip link`, per lesson 71 |

**Missing firmware is worth calling out** because the message is explicit and
people still miss it. Many network and graphics devices need a binary blob
loaded at initialisation, and `dmesg` will say `Direct firmware load for ...
failed with error -2`. The device then exists and does nothing. The fix is a
package, usually `linux-firmware`, and no amount of hardware replacement helps.

<details class="deeper">
<summary>If you already administer Linux: asking the disk what it thinks, and reading the answer properly</summary>

Drives run continuous self-monitoring and will tell you what they have seen, if
you ask. `smartctl` from `smartmontools` is how.

```bash
sudo smartctl -H /dev/sda           # overall pass or fail
sudo smartctl -a /dev/sda           # every attribute
sudo smartctl -l error /dev/sda     # the drive's own error log
sudo smartctl -t short /dev/sda     # start a self test, minutes
sudo smartctl -l selftest /dev/sda  # results
```

**The overall health line is nearly useless on its own.** It reports PASSED
right up until a threshold is crossed, and drives routinely fail while passing.
Read the attributes.

**The attributes that actually predict failure**, from published large-scale
studies of drive populations:

| Attribute | Meaning |
| --- | --- |
| `Reallocated_Sector_Ct` | Sectors found bad and remapped to spares. **Any non-zero value is a warning; a rising one is a decision** |
| `Current_Pending_Sector` | Sectors that failed to read and are awaiting reallocation. Worse than reallocated, because data may be at risk now |
| `Offline_Uncorrectable` | Could not be read or corrected at all |
| `Reported_Uncorrect` | Errors the drive could not fix |
| `UDMA_CRC_Error_Count` | **Interface errors, which usually means a cable**, not the drive |

That last row saves whole afternoons. A drive throwing CRC errors is very often
sitting on a bad SATA cable or a loose connector, and replacing the drive
achieves nothing.

**Rate of change matters more than absolute value.** Five reallocated sectors
that have been five for two years is a drive with a small manufacturing defect.
Five that were zero last week is a drive to replace now. This is the argument
for recording SMART attributes as metrics, per lesson 64, rather than reading
them during an incident.

**For NVMe the vocabulary changes** and the tool is the same:

```bash
sudo smartctl -a /dev/nvme0        # or: sudo nvme smart-log /dev/nvme0
```

Watch `percentage_used`, which is the drive's estimate of endurance consumed,
`media_errors`, and `critical_warning`. NVMe drives also throttle when hot, so a
suddenly slow NVMe with a high `temperature` is a cooling problem rather than a
failing one.

**Enable the daemon rather than checking by hand.** `smartd` runs the tests on a
schedule and alerts, which is the difference between finding out at 2am and
finding out on a Tuesday afternoon.

**A caution about virtual and network-attached disks.** SMART passes through to
real hardware, and a virtio disk, an iSCSI LUN, or a cloud volume has no SMART
data to give you. `smartctl` on the VM used for these captures reports that the
command does not exist, because the abstraction has no drive underneath it from
the guest's point of view. On those, health is the hypervisor's or the
provider's to report, and asking the guest is the wrong question.

</details>

<details class="deeper">
<summary>If you already administer Linux: what to do while the disk is still dying</summary>

Deciding a drive is failing is the easy half. What you do in the next hour
decides how much data survives, and the instinct most people have is the wrong
one.

**Stop writing to it.** Every write, every filesystem repair, and every retry
consumes remaining life and can overwrite the sectors you were hoping to
recover. Mount it read-only if it must stay mounted:

```bash
sudo mount -o remount,ro /mnt/data
```

**Image before repairing.** `fsck` on a failing device is the combination most
likely to turn recoverable data into unrecoverable data, per lesson 67. Copy
first, then work on the copy:

```bash
sudo ddrescue -f -n /dev/sdb /dev/sdc /var/tmp/rescue.map     # fast pass, skip errors
sudo ddrescue -d -f -r3 /dev/sdb /dev/sdc /var/tmp/rescue.map # retry the gaps
```

**`ddrescue` rather than `dd`, and the reason is the map file.** `dd` stops or
stalls on the first bad sector and has no memory of where it got to.
`ddrescue` copies everything readable first, records what it missed, and only
then goes back for the difficult parts, so you get the maximum readable data in
the minimum time on the drive. Interrupt it and it resumes from the map.

**The order that gets the most data back:**

1. Stop writes. Unmount, or remount read-only.
2. If the array is redundant, do not rebuild yet. A rebuild reads every sector
   of every remaining disk, which is exactly the workload most likely to kill a
   second marginal one. Back up first, per lesson 15.
3. Image with `ddrescue` onto a healthy device.
4. Verify the image mounts read-only.
5. Repair the copy, never the original.
6. Replace the hardware.

**Two things that make the drive worse while you work:** heat, and time spent
spinning. Copy at a sensible speed rather than hammering it, and if the drive is
audibly failing or repeatedly resetting, stop and consider whether the data is
worth a professional recovery service. That decision belongs to whoever owns the
data, not to whoever is holding the screwdriver.

**And check the array's own view before touching anything**, because "one disk
failed" and "the array is already degraded and this is the second" are very
different situations:

```bash
cat /proc/mdstat                # software RAID
sudo mdadm --detail /dev/md0    # per-device state
```

</details>

## Taint

The kernel keeps a flag recording whether anything has happened that makes its
behaviour hard to reason about.

<details class="predict">
<summary>A machine that has loaded no proprietary modules and has never crashed is asked whether it is tainted. What number comes back?</summary>

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ echo "--- is the kernel tainted, and by what ---"; cat /proc/sys/kernel/tainted; echo "--- CPU, as the kernel sees it ---"; lscpu | grep -E "^(Architecture|CPU\(s\)|Model name|Vendor ID|Hypervisor)" 2>/dev/null
--- is the kernel tainted, and by what ---
0
--- CPU, as the kernel sees it ---
Architecture:                            aarch64
CPU(s):                                  5
Vendor ID:                               Apple
Model name:                              -
```

</details>

Zero, which is what a clean kernel reports. The value is a bitmask, so anything
non-zero needs decoding:

```bash
cat /proc/sys/kernel/tainted                                    # the number
sudo dmesg | grep -i taint                                      # why, in words
```

**The bits worth recognising:**

| Bit | Value | Means |
| --- | --- | --- |
| 0 | 1 | A proprietary module was loaded |
| 1 | 2 | A module was force-loaded |
| 4 | 16 | **A machine check exception occurred.** Hardware error |
| 5 | 32 | **A bad page was found.** Memory problem |
| 7 | 128 | The kernel died previously, an oops or panic |
| 9 | 512 | A kernel warning was issued |
| 12 | 4096 | An out-of-tree module was loaded |

Bits 4, 5, and 7 are the ones that matter for this lesson, because they are the
kernel recording that something genuinely went wrong rather than that you
installed a driver.

**Why anybody cares:** taint is the first thing a vendor's support process
checks. A kernel running a proprietary or out-of-tree module is not the kernel
they ship, so they cannot reproduce your problem and will usually ask you to
remove it before continuing. That is a reasonable position and it is worth
knowing before you open the case rather than after.

<details class="deeper">
<summary>If you already administer Linux: memory errors, and deciding hardware against software</summary>

Memory faults are the hardest of these to attribute, because bad memory
corrupts whatever happens to be using it. The symptom is whichever program was
unlucky, so it looks like a different software bug every time.

**With ECC memory the machine tells you.** Single-bit errors are corrected
transparently and logged, and that log is an early warning worth acting on:

```bash
sudo edac-util -v                          # per-DIMM correctable and uncorrectable
sudo ras-mc-ctl --summary                  # if rasdaemon is running
sudo dmesg | grep -iE 'EDAC|Machine check|mce|Hardware Error'
sudo mcelog --client                       # on older systems
```

**Correctable errors are the useful signal.** ECC fixes them, nothing breaks,
and a DIMM producing them at a rising rate is going to produce an uncorrectable
one eventually. Replacing a module on the strength of correctable errors is
cheap; discovering the problem through an uncorrectable one is a crash.

**Without ECC you get no warning at all**, which is the whole argument for it on
anything that matters. A desktop with failing memory produces random
segmentation faults in unrelated programs, filesystem corruption, and builds
that fail differently each time. `memtest86+` from boot media is the test, and
it needs hours rather than minutes to be meaningful.

**Machine check exceptions are the CPU reporting a hardware error directly.**
`Machine check events logged` in `dmesg` is never noise. Decode them with
`mcelog` or `rasdaemon`, and treat repeated ones as a reason to move the
workload off that machine.

**The judgement: is this hardware or software?** These lean hardware:

- Errors that follow the machine rather than the workload. Move the job
  elsewhere and it is fine.
- Multiple unrelated programs failing in unrelated ways.
- Errors correlated with temperature, load, or time since power-on.
- Anything in `dmesg` from a driver, the block layer, or EDAC.
- Corruption that survives a reinstall.

And these lean software:

- Reproducible on identical hardware elsewhere.
- Started exactly when something was deployed or updated, per lesson 63.
- Only one application affected, everything else healthy.
- Clean `dmesg`. **This is the strongest single signal.** Genuine hardware
  problems almost always leave a trace in the kernel log, so a completely quiet
  `dmesg` is good evidence that the fault is above the kernel.

**The cheapest discriminating test is to move the workload.** If it follows the
application to a different machine, it is software. If it stays with the
machine, it is hardware. That is one afternoon and it settles arguments that
otherwise run for weeks.

</details>

## For the exam

**`dmesg` and `journalctl -k` are where hardware errors appear**, not in
application logs.

**`blk_update_request: I/O error` names the device and sector.** Media problems
are `critical medium error`.

**A device that returns an error is answering; a device that times out has
stopped.** The second is more often the controller, cable, or power.

**`lspci` shows enumeration, `lspci -k` shows whether a driver bound.** No
driver means missing module or firmware.

**`Direct firmware load ... failed` means a missing firmware package**, usually
`linux-firmware`.

**SMART: `Reallocated_Sector_Ct` and `Current_Pending_Sector` predict failure.
`UDMA_CRC_Error_Count` means the cable.**

**A PASSED health check does not mean a healthy drive.** Read the attributes.

**Virtual and network-attached disks have no SMART data.**

**A tainted kernel is recorded in `/proc/sys/kernel/tainted`**, and vendors check
it before accepting a support case.

**ECC corrects and logs single-bit errors.** Correctable errors rising is the
warning to act on.

**A completely clean `dmesg` is evidence against a hardware fault.**

<details class="qa">
<summary>Check yourself</summary>

**An application reports a read failure and its own log says almost nothing.
Where do you look?**
`dmesg` or `journalctl -k`. The kernel names the layer, the device, and the
block; the tool above it often just reports zero bytes.

**What does `Buffer I/O error on dev dm-0, logical block 0` tell you?**
The block layer failed a read, on a device-mapper device, at a specific block.
`dmsetup ls` or `lsblk` translates `dm-0` into a name you recognise.

**Difference between a device returning an I/O error and a device timing out?**
An error means it is working well enough to refuse. A timeout means it stopped
responding, which points more often at the controller, cable, power, or
firmware than at the media.

**A device appears in `lspci` and nothing works. What next?**
`lspci -k` to see whether a driver bound. No driver means a missing module or
missing firmware, not broken hardware.

**`Direct firmware load for ... failed with error -2`. What is the fix?**
Install the firmware package, usually `linux-firmware`. Replacing hardware will
not help.

**Which SMART attribute usually means a cable rather than a drive?**
`UDMA_CRC_Error_Count`.

**SMART reports PASSED. Is the drive healthy?**
Not necessarily. The overall verdict stays PASSED until a threshold is crossed.
Read `Reallocated_Sector_Ct` and `Current_Pending_Sector`, and watch their rate
of change.

**Which is more urgent, reallocated sectors or pending sectors?**
Pending. Those are sectors that failed to read and have not been remapped yet,
so data may be at risk now.

**`smartctl` returns nothing useful on a cloud volume. Why?**
There is no physical drive from the guest's point of view. Health for that
storage is the provider's to report.

**What does a non-zero `/proc/sys/kernel/tainted` mean, and who cares?**
Something happened that makes kernel behaviour hard to support: a proprietary
module, a forced module load, a previous oops, a machine check. Vendor support
checks it first.

**Which taint bits indicate genuine hardware trouble?**
Bit 4 (machine check exception) and bit 5 (bad page). Bit 7 records a previous
oops or panic.

**Programs crash randomly and differently each time, with no pattern. What do
you suspect?**
Memory. With ECC, check `edac-util` for correctable errors. Without ECC, run
`memtest86+` for hours.

**What does ECC give you that non-ECC does not?**
It corrects single-bit errors and, more usefully, logs them, so a failing module
announces itself before it causes a crash.

**One test to decide hardware against software?**
Move the workload to another machine. If the fault follows the workload it is
software; if it stays with the machine it is hardware.

</details>

## Where this sits

Lesson 10 covered the kernel and its modules, and lesson 11 covered device
discovery. This lesson is the same territory when something has gone wrong.
Lesson 67 handles the filesystem sitting on top of a failing device, and lesson
76 covers a disk that is slow rather than broken, which is a different
investigation with a different answer.


## References

- [dmesg(1)](https://man7.org/linux/man-pages/man1/dmesg.1.html) - man7.org. Accessed 2026-08-09.
- [smartctl(8)](https://www.smartmontools.org/browser/trunk/smartmontools/smartctl.8.in) - smartmontools. Accessed 2026-08-09.
- [Kernel documentation: tainted kernels](https://docs.kernel.org/admin-guide/tainted-kernels.html) - kernel.org. Accessed 2026-08-09.
- [Kernel documentation: machine check exceptions](https://docs.kernel.org/arch/x86/x86_64/machinecheck.html) - kernel.org. Accessed 2026-08-09.
- [dmsetup(8)](https://man7.org/linux/man-pages/man8/dmsetup.8.html) - man7.org. Accessed 2026-08-09.
> **The commands here were run on a real machine, not written from memory.** The
> transcripts come from Fedora CoreOS 44.20260707.3.1 on aarch64. The I/O errors
> are genuine kernel messages, produced by building a device-mapper `error`
> target so that every read really did fail, and the device was removed in the
> same command that created it. The `lspci` listing shows an Apple host bridge
> beside Red Hat virtio devices because that is what this virtual machine
> actually is. `smartctl` is not installed on that image, which is the reason the
> SMART section carries no transcript and says so.
