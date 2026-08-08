---
title: "Interrogating a server you have never met"
description: "You have been handed a server and no documentation. The commands that tell you what CPU, how much memory, which disks, which cards, and whether any of it is real hardware at all."
track: "linux-plus"
level: "working"
order: 120
objectives:
  - "Inventory a machine's CPU, memory, disks, and expansion cards from the command line"
  - "Tell whether you are on physical hardware or a virtual machine, and say how you know"
  - "Read a device node and say whether it is a block or a character device"
  - "Use the kernel log to find out whether a device was detected at all"
prerequisites: ["the-kernel-and-modules"]
tags: ["linux", "linux-plus", "hardware", "inventory"]
updated: 2026-08-07
draft: false
examObjectives:
  - exam: "xk0-006"
    domain: "1.0"
    objective: "1.2"
sources:
  - title: "lscpu(1)"
    url: "https://man7.org/linux/man-pages/man1/lscpu.1.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "lsblk(8)"
    url: "https://man7.org/linux/man-pages/man8/lsblk.8.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "free(1)"
    url: "https://man7.org/linux/man-pages/man1/free.1.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "dmesg(1)"
    url: "https://man7.org/linux/man-pages/man1/dmesg.1.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "sysfs(5)"
    url: "https://man7.org/linux/man-pages/man5/sysfs.5.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "udev(7)"
    url: "https://man7.org/linux/man-pages/man7/udev.7.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "lspci(8)"
    url: "https://manpages.debian.org/stable/pciutils/lspci.8.en.html"
    publisher: "Debian Project"
    accessed: 2026-08-07
    tier: 1
  - title: "dmidecode(8)"
    url: "https://manpages.debian.org/stable/dmidecode/dmidecode.8.en.html"
    publisher: "Debian Project"
    accessed: 2026-08-07
    tier: 1
symptoms:
  - symptom: "A card is fitted but nothing on the system can see it"
    anchor: "1-the-card-is-fitted-and-nothing-sees-it"
---

> **Before you read.** Somebody hands you the login for a server. No
> documentation, no ticket, no colleague who remembers building it. You need to
> know what it is before you can do anything useful with it.
>
> You could open the case. Except it is in a data centre four hundred miles away,
> or it is a cloud instance and there is no case.
>
> **So how much can you learn about a machine's hardware without ever seeing it?**

Nearly all of it, as it turns out, and in about ninety seconds. The machine keeps
a detailed account of itself and there are half a dozen commands that read
different parts of it.

The commands are easy. What is worth learning here is which one answers which
question, because they overlap confusingly and reaching for the wrong one is how
a two-minute job becomes twenty.

### Some words you will need

<dl class="terms">
<dt>device node</dt>
<dd>A file under <code>/dev</code> that stands for a piece of hardware. Programs read and write it as if it were a file.</dd>
<dt>block device</dt>
<dd>Something you address in chunks and can seek around in. Disks. Marked <code>b</code>.</dd>
<dt>character device</dt>
<dd>Something you read as a stream, one byte after another. Terminals, random number sources. Marked <code>c</code>.</dd>
<dt>PCI</dt>
<dd>The bus that expansion cards plug into. Network cards, storage controllers, graphics cards.</dd>
<dt>DMI / SMBIOS</dt>
<dd>A table the firmware fills in describing the machine: manufacturer, model, serial number, memory slots.</dd>
</dl>

## What breaks without this

**You size things by guesswork.** "Is this machine big enough" and "why is it
slow" both start with knowing what is in it, and a wrong assumption about core
count or memory sends the whole investigation somewhere useless.

**You cannot tell whether a device failed or was never there.** A disk that has
disappeared and a disk that was never fitted look identical from the application's
point of view, and completely different from the kernel's.

**You cannot answer the asset question.** Serial number, model, and firmware
version are what a vendor asks for before they will talk to you, and they are all
available from the running system.

## The tour

Six commands. Learn which question each answers and the rest is reading.

| Question | Command |
| --- | --- |
| What CPU, how many cores? | `lscpu` |
| How much memory? | `free -h`, `lsmem` |
| What disks? | `lsblk`, `lsblk -f` |
| What cards are plugged in? | `lspci`, `lsusb` |
| What machine is this, really? | `dmidecode` |
| Did the kernel notice the device? | `dmesg` |

### The processor

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ lscpu | head -10
Architecture:                            aarch64
CPU op-mode(s):                          64-bit
Byte Order:                              Little Endian
CPU(s):                                  5
On-line CPU(s) list:                     0-4
Vendor ID:                               Apple
Model name:                              -
Model:                                   0
Thread(s) per core:                      1
Core(s) per cluster:                     5
```

**`CPU(s)` is the number the operating system will actually use**, and it is the
one to quote. It counts threads, not physical cores: a machine with 8 cores and
hyper-threading reports 16, and `Thread(s) per core: 2` is how you know. Here it
is 1, so five CPUs means five real cores.

`Architecture` is the answer to "will this binary run", and it is worth checking
before you spend an hour on a package that was never built for the machine.

### The memory

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ free -h; echo ---; lsmem | tail -4
               total        used        free      shared  buff/cache   available
Mem:           1.9Gi       530Mi       656Mi       1.0Mi       842Mi       1.4Gi
Swap:             0B          0B          0B
---

Memory block size:                128M
Total online memory:                2G
Total offline memory:               0B
```

**Read `available`, not `free`.** They are different numbers and the difference
catches everyone once. `free` is memory doing nothing at all. `available` is what
a new program could get, which includes most of `buff/cache` because the kernel
will hand cache back the moment something needs it.

Here: 656 MiB genuinely free, but 1.4 GiB available. A monitoring alert on `free`
would be firing; the machine is fine.

**Caching memory is the kernel doing its job.** A Linux server with lots of free
memory after a week of uptime is a server that is not being used.

### The disks

`lsblk` shows the storage tree, and `lsblk -f` adds what is on it. There is a
full example in the boot lesson, which is the same command. The two facts to take
from it: `TYPE` tells you disk from partition from LVM volume, and an empty
`FSTYPE` means no filesystem — the device is raw.

### The cards

`lspci` lists what is on the PCI bus. This machine is a virtual one, which makes
the output more informative than a physical machine's would be here.

<details class="predict">
<summary>A virtual machine has no real network card or disk controller. What manufacturer will `lspci` name for its devices, and what does that tell you about how the guest talks to hardware?</summary>

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ lspci
00:00.0 Host bridge: Apple Inc. Device 1a05
00:01.0 Ethernet controller: Red Hat, Inc. Virtio 1.0 network device (rev 01)
00:05.0 Communication controller: Red Hat, Inc. Virtio 1.0 console (rev 01)
00:06.0 Mass storage controller: Red Hat, Inc. Virtio 1.0 block device (rev 01)
00:07.0 Mass storage controller: Red Hat, Inc. Virtio 1.0 file system (rev 01)
00:08.0 Mass storage controller: Red Hat, Inc. Virtio 1.0 file system (rev 01)
00:09.0 Mass storage controller: Red Hat, Inc. Virtio 1.0 file system (rev 01)
00:0a.0 Mass storage controller: Red Hat, Inc. Virtio 1.0 file system (rev 01)
00:0b.0 Communication controller: Red Hat, Inc. Virtio 1.0 socket (rev 01)
00:0c.0 Network and computing encryption device: Red Hat, Inc. Virtio 1.0 RNG (rev 01)
```

</details>

**Red Hat, and every device is `Virtio`.** There is no emulated Intel network card
here. Virtio devices are *paravirtualised* — the guest knows it is virtualised and
talks to the hypervisor through a shared-memory interface instead of pretending to
poke registers on hardware that does not exist. That removes a whole layer of
emulation and is why a virtio disk is several times faster than an emulated IDE
one.

**Reading `lspci` is therefore a fast way to tell where you are.** Virtio means
KVM or a KVM-derived hypervisor. `VMware` in the vendor column means ESXi.
Intel and Broadcom part numbers with no hypervisor in sight generally mean metal.

Every line is a device on the PCI bus, with its address, its class, and its name.

**Look at what those devices are.** "Red Hat, Inc. Virtio" is not a real card;
`virtio` is the standard interface a hypervisor presents to a guest. Seeing it
tells you, without any other evidence, that **this is a virtual machine.** On
physical hardware you would be reading Intel, Broadcom, Mellanox, LSI.

That is the single most useful thing `lspci` does on an unfamiliar machine, and
it takes one second.

`lspci -k` adds which kernel module is driving each device, which is the direct
join to the previous lesson: a device listed with no driver is a device that will
not work.

`lsusb` does the same job for USB. It is less interesting on a server and
essential on anything with peripherals.

### What machine is this, really

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ sudo dmidecode -t system 2>&1 | head -12
# dmidecode 3.7
Getting SMBIOS data from sysfs.
SMBIOS 3.3.0 present.

Handle 0x0000, DMI type 1, 27 bytes
System Information
	Manufacturer: Apple Inc.
	Product Name: Apple Virtualization Generic Platform
	Version: 1
	Serial Number: Virtualization-b9287a28-db52-4736-a491-9a26c1478f15
	UUID: 287a28b9-52db-3647-a491-9a26c1478f15
	Wake-up Type: Power Switch
```

`dmidecode` reads the table the firmware wrote. On a physical server this is
where the **model and serial number** come from, and it is what a hardware vendor
will ask for. On a virtual machine it says so, in as many words: `Apple
Virtualization Generic Platform`.

Useful `-t` types: `system` for model and serial, `memory` for the DIMMs and which
slots are populated, `bios` for firmware version, `processor` for the socket.

**`dmidecode -t memory` is the one that earns its keep.** It shows physical slots
and what is in each, which is how you answer "can we add more memory without
opening it" — a question `free` cannot touch, because `free` reports what the
operating system was given, not what the machine can hold.

<details class="predict">
<summary>`free -h` reports 1.9 GiB total on a server the invoice says has 4 GiB. Name two explanations, and the command that distinguishes them.</summary>

**A DIMM has failed or is not seated**, so the firmware only counted half the
memory. Or **the memory is present and something is holding it back** — a kernel
`mem=` parameter, memory reserved for a device, or a hypervisor that was
configured with less than the host has.

`sudo dmidecode -t memory` distinguishes them. It reads the firmware's own table
of physical slots, independently of what the kernel decided to use. If it shows
two populated 2 GiB slots, the hardware is fine and the loss is above it —
check `cat /proc/cmdline` for a `mem=` parameter next. If it shows one populated
slot and one empty, or one flagged as failed, the problem is physical.

The general shape is worth keeping: **`free` reports what the operating system
was given, `dmidecode` reports what the machine has.** When they disagree, the
answer is between them, and knowing which is which tells you whether to send an
engineer or read a config file.

</details>

<details class="deeper">
<summary>If you already administer Linux: reading memory numbers that do not mean what they say</summary>

`free -h` is the most misread output on a Linux system, and the misreading
generates real incidents — someone sees a nearly full memory column and orders
more RAM for a machine that is fine.

**The `available` column is the only one worth acting on.** It is not
`free`, and it is not `free + buffers/cache`. The kernel estimates how much a new
allocation could obtain without swapping, accounting for the fact that some cache
is reclaimable and some is not. That estimate did not exist before kernel 3.14, and
every rule of thumb older than that is wrong.

**Cache is not consumption.** A machine that has been up a week will show almost no
free memory, because the kernel keeps file contents cached rather than leaving RAM
idle. That memory is handed back the instant anything wants it. Free memory is
wasted memory, and a Linux machine deliberately has very little.

The distinction the columns hide:

| Column | Means |
| --- | --- |
| `used` | Genuinely allocated, not reclaimable |
| `buff/cache` | Page cache, dentries, inodes. Mostly reclaimable. |
| `shared` | tmpfs, which lives in RAM. **Counted in cache and not reclaimable.** |
| `available` | What a new allocation could actually get |

**`shared` is the one that catches people.** A large file written to `/tmp` on a
system where `/tmp` is tmpfs consumes RAM permanently until deleted, and it appears
under cache — which everyone has learned to ignore. `df -h /tmp` and
`findmnt /tmp` tell you whether that applies to your machine.

**Per-process numbers have the same problem in reverse.** `RSS` in `ps` and `top`
counts shared library pages against every process using them, so summing RSS across
processes vastly exceeds real usage. `PSS` in `/proc/PID/smaps_rollup` divides
shared pages by the number of sharers and actually adds up:

```
grep -H Pss /proc/[0-9]*/smaps_rollup 2>/dev/null | sort -t: -k3 -rn | head
```

**And the modern answer to "is this machine under memory pressure" is neither.**
`/proc/pressure/memory` reports the share of time tasks were stalled waiting for
memory, which is a direct measure rather than an inference from a gauge:

```
cat /proc/pressure/memory
```

`some avg10` above a few percent means real pressure. Zero means the machine is
fine no matter how alarming `free` looks.

</details>

### Device nodes

Hardware appears under `/dev` as files, and the first character of `ls -l` says
which kind:

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ ls -l /dev/vda /dev/null /dev/random /dev/console | head
crw-------. 1 root tty    5, 1 Aug  7 14:14 /dev/console
crw-rw-rw-. 1 root root   1, 3 Aug  7 14:14 /dev/null
crw-rw-rw-. 1 root root   1, 8 Aug  7 14:14 /dev/random
brw-rw----. 1 root disk 253, 0 Aug  7 14:14 /dev/vda
```

Three `c` and one `b`. **`b` is a block device** — a disk, addressed in blocks,
seekable. **`c` is a character device** — a stream. That first character is the
same position as the `d` for directory in the permissions lesson; it is the file
*type*, and devices simply have two more types than you had met.

Where the file size would be, there are **two numbers instead**: `253, 0` for
`/dev/vda`. Major and minor. The major identifies the driver, the minor
identifies which device that driver is handling. A device node is not the
hardware; it is a pair of numbers pointing at a driver, wrapped in something that
behaves like a file.

Notice `/dev/vda` is group `disk` and mode `brw-rw----`, so members of `disk` can
read the raw device. That is effectively read access to every file on it,
regardless of the permissions on those files — which is a permissions lesson and
a security finding at the same time.

### Did the kernel even see it

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ sudo dmesg | grep -i "virtio_blk\|virtio_net" | head -5; echo "--- /sys ---"; ls /sys/class | head -12
[    0.068159] virtio_blk virtio2: 1/0/0 default/read/poll queues
[    0.068472] virtio_blk virtio2: [vda] 209715200 512-byte logical blocks (107 GB/100 GiB)
[    1.778543] virtio_net virtio0 enp0s1: renamed from eth0
--- /sys ---
accel
ata_device
ata_link
ata_port
backlight
bdi
block
bsg
devcoredump
devfreq
devfreq-event
devlink
```

**`dmesg` is the first place to look when hardware is not working**, because it
records detection as it happens, with a timestamp in seconds since boot. The disk
was found 68 milliseconds in; the network interface was renamed at 1.7 seconds.

`dmesg -T` prints wall-clock times instead of seconds, which matters when you are
correlating with an incident. `dmesg -w` follows, so you can watch what happens
when you plug something in — genuinely the fastest way to identify an unlabelled
USB device.

`/sys` is the other half of the picture: a directory tree the kernel exposes
describing every device it knows about. `/sys/class/net/` lists network
interfaces, `/sys/block/` lists disks. You will rarely browse it by hand, but
every `ls*` command in this lesson is reading it, and knowing that explains why
they all agree with each other.

<details class="deeper">
<summary>If you already administer Linux: udev, lshw, sensors, and out-of-band</summary>

**udev** is what turns kernel device events into the `/dev` nodes and the names
you actually use. `udevadm info -a -n /dev/sda` walks the device up its parent
chain and prints every attribute you could match on; `udevadm monitor` shows
events live. Rules in `/etc/udev/rules.d/` give a device a stable name — the
standard use is a `SYMLINK+=` on a serial number so a USB serial adapter is
always `/dev/ttyPLC1` rather than whichever `ttyUSB*` it happened to enumerate as.
The same mechanism is behind predictable network interface names.

**`lshw`** does in one command what the six above do separately, and `lshw
-short` is a genuinely good first look at an unknown machine. It is usually not
installed and it is worth installing. `hwinfo` on SUSE covers the same ground.

**`lm_sensors`** reads temperatures and fan speeds; run `sensors-detect` once,
then `sensors`. On a machine that is throttling under load this is the difference
between "the application is slow" and "the intake is blocked". Nothing here works
on a virtual machine, because there is nothing to measure.

**GPUs** are their own world: `nvidia-smi` for NVIDIA, `rocm-smi` for AMD, and
`nvtop` as a top-like view across both. `lspci -k` first, though — a GPU whose
driver did not bind shows up in `lspci` and in none of the others.

**Out-of-band** is the part people forget. `ipmitool` and vendor tools (iDRAC,
iLO) talk to the management controller, which is a small computer that stays
powered when the server is not. It holds the hardware event log — the record of
the DIMM that failed at 03:00 before the machine stopped answering. When Linux is
not running, that log is the only account of what happened.

**`/proc/cpuinfo` and `/proc/meminfo`** are still there and still readable, and
`lscpu` and `free` are formatted views onto them. Worth knowing for scripts, and
for the machine so minimal that `lscpu` is not installed.

</details>


<details class="deeper">
<summary>If you already administer Linux: the disk group, and hardware inventory at fleet scale</summary>

Two things worth carrying out of `/dev` that the tour above only touches.

**`brw-rw---- root disk` is a privilege boundary that does not look like one.**
Membership of the `disk` group grants read access to the raw block device, which
is read access to every byte on it regardless of the file permissions above.
Adding a user to `disk` so they can run `lsblk` is a genuine privilege
escalation, and it appears in real hardening findings. `getent group disk`
should normally be empty.

**Inventory does not scale by running six commands per host.** `dmidecode -s`
takes a single keyword and prints one value with no parsing —
`dmidecode -s system-serial-number`, `-s system-product-name`,
`-s bios-version` — which makes it usable in a loop across a fleet.
`dmidecode -s` with no argument lists every valid keyword.

The same job from the other direction: `/sys/class/dmi/id/` holds most of the
same fields as one-line files, readable **without root**, which matters when the
inventory account should not be privileged. `cat
/sys/class/dmi/id/product_name` needs no `sudo` where `dmidecode` does.

And `systemd-detect-virt` answers the virtual-or-physical question in one word
with a useful exit status, which is the version to put in a script rather than
grepping `lspci` for the string `Virtio`.

</details>

## Across distributions

| | RPM family | dpkg family |
| --- | --- | --- |
| `lscpu`, `lsblk`, `free`, `dmesg` | `util-linux`, `procps-ng` | `util-linux`, `procps` |
| `lspci`, `lsusb` | `pciutils`, `usbutils` | `pciutils`, `usbutils` |
| `dmidecode` | `dmidecode` | `dmidecode` |
| `lshw` | `lshw`, often via EPEL | `lshw` |
| Sensors | `lm_sensors` | `lm-sensors` |

The commands are identical everywhere. What differs is which are installed by
default, and on a minimal image the answer is usually "fewer than you expect" —
`lspci` in particular is frequently missing, which is the same lesson as the
missing editor from lesson 05.


<details class="deeper">
<summary>If you already administer Linux: SMART, and asking a disk how it feels</summary>

`lsblk` says a disk is there. It says nothing about whether it is about to stop
being there, and that question has a direct answer.

**`smartctl -a /dev/sda`** reads the drive's own health log. The attributes worth
knowing by name: **Reallocated_Sector_Ct** — sectors that failed and were
remapped, and any non-zero value that is *growing* is a disk to replace;
**Current_Pending_Sector** — sectors that failed a read and have not been remapped
yet, which is worse than reallocated because the data in them is currently
unreadable; **Offline_Uncorrectable**; and **Power_On_Hours**, which is how you
find out the "new" server is running five-year-old drives.

`smartctl -H` gives the one-line pass or fail, and it is close to useless on its
own — drives routinely report PASSED with hundreds of pending sectors, because
the threshold the manufacturer set is generous. Read the attributes.

**Behind a RAID controller you need `-d`.** `smartctl -a -d megaraid,0
/dev/sda` or `-d cciss,0`, because the controller hides the physical disks. This
is the step people miss, and it presents as SMART simply not working.

**`smartctl -t short` runs a self-test** in the background, results in
`smartctl -l selftest`. Ten minutes, no downtime, and it is what to run before
committing to a RAID rebuild — the previous lesson's point about rebuilds being
the riskiest moment applies here, and this is how you check the survivors first.

`smartd` monitors continuously and mails on change, which is the version that
catches a failing disk before it takes an array with it.

</details>

## Prove it

A ninety-second first look at an unknown machine:

```bash
# What and how big
lscpu | head -6
free -h
lsblk

# Real or virtual, and what model
sudo dmidecode -t system | grep -E 'Manufacturer|Product|Serial'

# What is plugged in, and is anything driverless
lspci -k | grep -A2 -E 'Ethernet|Mass storage|VGA'

# Did anything complain on the way up
sudo dmesg --level=err,warn | head -20
```

That last line is the one to run first on a machine somebody has told you is
behaving oddly. Kernel-level errors and warnings, nothing else, and it is
frequently the whole answer.

## What trips people up

### 1. The card is fitted and nothing sees it

Work down the chain in order, because each step rules out everything above it.

**Is it on the bus?** `lspci`. Absent means the hardware is not seated, not
powered, or dead — nothing in software will help.

**Did a driver bind?** `lspci -k` and look for `Kernel driver in use`. Present on
the bus with no driver means a missing or blacklisted module.

**Did the kernel say anything?** `sudo dmesg | grep -i <the device>`. Firmware load
failures and initialisation errors show up here and nowhere else.

**Is there a device node?** `ls /dev`, or `ls /sys/class/net/` for an interface.

Four commands, and whichever one first comes up empty is where the problem is.

### 2. Reading `free` instead of `available`

Covered above and worth repeating because it generates so many false alarms. A
healthy Linux server has very little `free` memory, because unused memory is
wasted memory and the kernel is using it for cache.

Alert on `available`. Alert on swap activity. Do not alert on `free`.

### 3. Trusting `lscpu` for physical cores

`CPU(s)` counts logical processors. With hyper-threading that is twice the
physical cores, and licensing, capacity planning, and thread-count tuning
generally want the physical number.

`Thread(s) per core` and `Core(s) per socket` are the fields that answer it,
along with `Socket(s)`.

### 4. Assuming `/dev` names are stable

`/dev/sda` is whichever disk enumerated first this boot, and that can change when
you add a controller, change a cable, or reboot a machine with a slow-spinning
disk.

Use UUIDs, which is why `lsblk -f` and `blkid` matter and why `/etc/fstab` is
written the way it is. That is the next lesson but one.

### 5. Running the inventory commands without root

`dmidecode` needs root and says so clearly. `lspci` runs unprivileged but hides
detail. `dmesg` on many recent distributions is restricted to root by
`kernel.dmesg_restrict`.

Partial output because you were not root looks a lot like hardware that is not
there. `sudo` and look again before drawing conclusions.

## Work it through

A colleague reports that a database server "lost a disk". Applications are
running but a mount is missing. You have never seen this machine.

Reason through the order before reading on.

**Start at the bottom, not the top.** The temptation is to look at the filesystem,
because that is where the symptom is. But the filesystem sits on a partition, on
a disk, on a controller, on a bus — and a failure anywhere below the top produces
exactly this symptom.

**Is the controller on the bus?** `lspci | grep -i 'mass storage'`. If the
controller itself has gone, every disk behind it went with it and you are talking
about a hardware failure rather than a disk.

**Does the kernel see the disk?** `lsblk`, and compare against what should be
there. A disk that is present but has no partitions is very different from a disk
that is absent entirely.

**What did the kernel say?** `sudo dmesg -T | grep -iE 'sd[a-z]|i/o error|ata'`.
Read errors, resets, and link failures all land here with timestamps. This is
usually where the actual answer is, and it is usually timestamped hours before
anyone noticed.

**Is it a disk problem at all?** If `lsblk` shows the disk and the partition
healthy, nothing below the filesystem has failed and the missing mount is a
mounting problem — which is a completely different lesson and a much better
outcome.

Now the point worth extracting: **the layers are the diagnostic order.** Bus,
device, driver, block device, partition, filesystem, mount. A symptom at the top
can originate anywhere below it, so you work upward from the bottom and stop at
the first layer that is wrong. Guessing at the top and working down means
re-testing the same layer several times without ever ruling anything out.

And one more thing to check on an unfamiliar machine before drawing any
conclusion: `dmidecode -t system`. If this is a virtual machine, "lost a disk"
may be a storage volume that was detached at the hypervisor, and no amount of
looking at the guest will show you that.

## Try it

Optional, on any machine you have.

1. `lscpu`. Say how many physical cores you have, not how many CPUs are listed.
2. `free -h`. Say how much memory a new program could get, and explain why that is
   not the `free` column.
3. `lspci`. Decide from it alone whether you are on physical or virtual hardware,
   then check with `sudo dmidecode -t system`.
4. `ls -l /dev/sda /dev/null` (or `/dev/vda`). Name the device type of each and
   what the two numbers are.
5. `sudo dmesg | head -30`. Find where the storage was detected.
6. `lspci -k` and find a device with no `Kernel driver in use` line, if there is
   one.

**Verification step.** You have it when you can be dropped onto an unknown machine
and produce its core count, memory, disk layout, model, and whether it is virtual,
in under two minutes.

## Check yourself

<details class="qa">
<summary>`free -h` shows 656 MiB free and 1.4 GiB available on a 1.9 GiB machine. Is it short of memory?</summary>

**No.** `available` is the number that matters: it estimates what a new program
could get without pushing anything to swap, and it includes most of the page
cache because the kernel releases cache on demand.

`free` counts only memory doing nothing at all, and on a healthy Linux server
that number is small by design. Memory the kernel is not using for cache is
memory being wasted.

The practical rule: alert on `available` and on swap activity, never on `free`.
Alerting on `free` produces a permanent false alarm on every well-behaved server
you own.

</details>

<details class="qa">
<summary>How can you tell a virtual machine from physical hardware, using two different commands?</summary>

**`lspci`** — virtual machines present `virtio` devices, or hypervisor-specific
ones like VMware's. Real hardware shows Intel, Broadcom, LSI, Mellanox. One
glance is usually enough.

**`sudo dmidecode -t system`** — reads the firmware's own description. A
hypervisor writes its name into it, so `Product Name` says something like
`VMware Virtual Platform`, `KVM`, or `Apple Virtualization Generic Platform`
rather than `PowerEdge R650`.

A third, if the tooling is there: `systemd-detect-virt` answers in one word and
exits non-zero on bare metal, which makes it the one to use in a script.

It matters more than it looks. On a virtual machine, "the disk failed" may be a
volume detached at the hypervisor, and every diagnostic you run inside the guest
will agree that the disk is gone without ever telling you why.

</details>

<details class="qa">
<summary>What do the two numbers in place of the file size mean for `/dev/vda`, and what does the leading `b` tell you?</summary>

They are the **major and minor numbers**. The major identifies which driver
handles the device; the minor tells that driver which device it is. A device node
holds no data — it is a pointer to a driver, wrapped in something the filesystem
can present as a file.

The leading **`b` means block device**: addressed in fixed-size blocks and
seekable, which is what a disk is. `c` would mean character device, read as a
stream, which is what a terminal or `/dev/random` is.

That first character sits in the same position as the `d` that marks a directory
in `ls -l`. It is the file type field, and devices are simply two more types than
you had met before.

</details>

<details class="qa">
<summary>A network card is physically fitted. Give the order of checks, and say what each one rules out.</summary>

**`lspci`** — is it on the bus at all? Missing here means seating, power, or a
dead card, and nothing in software will change that. Everything above this is
ruled out until it appears.

**`lspci -k`** — did a driver bind? A device listed with no `Kernel driver in use`
means the module is missing, blacklisted, or built for a different kernel.

**`sudo dmesg | grep -i eth`** — did the kernel complain? Firmware load failures
and initialisation errors appear here and in no other place.

**`ip link`** or `ls /sys/class/net/` — is there an interface? If one exists, the
hardware and driver are both fine and the problem is configuration, which is a
different lesson entirely.

Whichever check first comes up empty is where the fault is. Working in this order
means each step rules out everything below it, so you never test the same layer
twice.

</details>

<details class="qa">
<summary>Why should `/dev/sda` never appear in `/etc/fstab`, given what you know about how device nodes are assigned?</summary>

**Because the name is assigned by enumeration order, not by identity.**
`/dev/sda` is whichever disk the kernel found first this boot. Add a controller,
change a cable, or reboot a machine where one disk spins up more slowly, and the
same physical disk can come back as `/dev/sdb`.

If `/etc/fstab` names `/dev/sda1`, the machine will then mount a different disk at
that path, or fail to boot because the device is not what it expected.

A UUID is written into the filesystem itself when it is created, so it travels
with the data regardless of which port the disk is in. `lsblk -f` and `blkid`
both show it, and that is why the fstab in the next lesson is written with
`UUID=` rather than device names.

</details>

## References

- [lscpu(1)](https://man7.org/linux/man-pages/man1/lscpu.1.html) - Linux man-pages project. Accessed 2026-08-07.
- [lsblk(8)](https://man7.org/linux/man-pages/man8/lsblk.8.html) - Linux man-pages project. Accessed 2026-08-07.
- [free(1)](https://man7.org/linux/man-pages/man1/free.1.html) - Linux man-pages project. Accessed 2026-08-07.
- [dmesg(1)](https://man7.org/linux/man-pages/man1/dmesg.1.html) - Linux man-pages project. Accessed 2026-08-07.
- [sysfs(5)](https://man7.org/linux/man-pages/man5/sysfs.5.html) - Linux man-pages project. Accessed 2026-08-07.
- [udev(7)](https://man7.org/linux/man-pages/man7/udev.7.html) - Linux man-pages project. Accessed 2026-08-07.
- [lspci(8)](https://manpages.debian.org/stable/pciutils/lspci.8.en.html) - Debian Project. Accessed 2026-08-07.
- [dmidecode(8)](https://manpages.debian.org/stable/dmidecode/dmidecode.8.en.html) - Debian Project. Accessed 2026-08-07.

Command output was captured on the podman machine, which is a virtual machine and
says so throughout. Blocks without a distribution and architecture header are
illustrative.
