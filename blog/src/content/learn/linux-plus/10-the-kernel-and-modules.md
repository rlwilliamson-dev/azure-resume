---
title: "One kernel, ten thousand devices"
description: "Why a Linux kernel can support tens of thousands of devices without being enormous, how drivers get loaded on demand, and the four commands for inspecting, loading, and refusing them."
track: "linux-plus"
level: "working"
order: 110
objectives:
  - "Explain what a kernel module is and why the kernel is built this way"
  - "Inspect what is loaded, what a module does, and what depends on it"
  - "Load and unload a module, and make a choice about it persist"
  - "Say why a module tied to one kernel version does not work on another"
prerequisites: ["how-linux-boots"]
tags: ["linux", "linux-plus", "kernel", "modules", "drivers"]
updated: 2026-08-07
draft: false
examObjectives:
  - exam: "xk0-006"
    domain: "1.0"
    objective: "1.2"
sources:
  - title: "modprobe(8)"
    url: "https://man7.org/linux/man-pages/man8/modprobe.8.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "lsmod(8)"
    url: "https://man7.org/linux/man-pages/man8/lsmod.8.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "modinfo(8)"
    url: "https://man7.org/linux/man-pages/man8/modinfo.8.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "depmod(8)"
    url: "https://man7.org/linux/man-pages/man8/depmod.8.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "modprobe.d(5)"
    url: "https://man7.org/linux/man-pages/man5/modprobe.d.5.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "uname(1)"
    url: "https://man7.org/linux/man-pages/man1/uname.1.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
symptoms:
  - symptom: "modprobe: FATAL: Module not found in directory /lib/modules"
    anchor: "1-module-not-found-in-directory-lib-modules"
  - symptom: "Hardware works until a kernel update, then stops"
    anchor: "3-it-worked-until-the-kernel-was-updated"
---

> **Before you read.** Linux runs on a laptop, a phone, a router, a mainframe,
> and a car. It supports tens of thousands of different devices, every network
> card, every disk controller, every webcam anybody has bothered to write
> support for.
>
> All of that support cannot be loaded into memory at once; it would be
> gigabytes. But it also cannot be left out, because then the kernel would only
> work on hardware it was specifically built for.
>
> So: **how does one kernel support hardware nobody had invented when it was
> compiled, without carrying the weight of all of it?**

The answer is that the kernel is not one thing. It is a small core plus a large
pile of loadable pieces, and it loads the pieces it needs when it meets the
hardware that needs them.

That design is the reason "I plugged it in and it worked" happens at all, and it
is also the reason a handful of specific things go wrong in a way that looks like
broken hardware.

### Some words you will need

<dl class="terms">
<dt>kernel</dt>
<dd>The program that owns the hardware. Everything else asks it for access to memory, disks, and the network.</dd>
<dt>module</dt>
<dd>A piece of kernel code that can be loaded and unloaded while the machine is running. Most drivers are modules.</dd>
<dt>driver</dt>
<dd>Code that knows how to talk to one kind of hardware. On Linux, usually delivered as a module.</dd>
<dt>filesystem module</dt>
<dd>Not all modules are drivers. Filesystem support, network filtering, and encryption are modules too.</dd>
</dl>

## What breaks without this

**Hardware that "is not there".** A card is fitted, the machine sees nothing, and
there is no error anywhere obvious. The module for it did not load, and no part
of the system considers that worth complaining about.

**A machine that stops seeing its own disks after an update.** Modules are tied to
a kernel version. Anything not built by the distribution has to be rebuilt for
each new kernel, and when it is not, the failure arrives at the next reboot.

**A driver you cannot get rid of.** Two modules claim the same device, the wrong
one wins, and until you know how to refuse a module by name you are stuck with
whichever one loaded first.

## What is actually loaded

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ lsmod | head -8; echo "---"; lsmod | wc -l
Module                  Size  Used by
raid1                  65536  0
loop                   36864  0
nft_ct                 24576  1
nft_fib_inet           12288  2
nft_fib_ipv4           12288  1 nft_fib_inet
nft_fib_ipv6           12288  1 nft_fib_inet
nft_fib                12288  3 nft_fib_ipv6,nft_fib_ipv4,nft_fib_inet
---
65
```

Sixty-five modules on a machine doing very little. Three columns:

- **Module**, the name, which is what every other command in this lesson
  takes.
- **Size**, bytes of kernel memory it occupies.
- **Used by**, a count, and then the names of whatever is using it.

**That third column is the useful one.** `nft_fib` shows `3` and then names three
modules that depend on it. A module with a non-zero count **cannot be unloaded**
until whatever is using it lets go, which is the answer to most of "why will this
not unload".

Notice what is in that list. `raid1` is not a driver for a piece of hardware; it
is software RAID. `nft_*` are the firewall. **Modules are not only drivers**, and
expecting them to be leads to confusion the first time you meet one that is not.

## What a module is and where it came from

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ modinfo xfs | head -9
filename:       /lib/modules/7.1.3-200.fc44.aarch64/kernel/fs/xfs/xfs.ko.xz
license:        GPL
description:    SGI XFS with ACLs, security attributes, realtime, scrub, repair, quota, no debug enabled
author:         Silicon Graphics, Inc.
alias:          fs-xfs
depends:        
intree:         Y
name:           xfs
vermagic:       7.1.3-200.fc44.aarch64 SMP preempt mod_unload aarch64
```

Read four of those lines closely, because they carry the whole model.

**`filename`** puts the module under `/lib/modules/<kernel version>/`. That path
is the most important thing on the page: **modules live in a directory named
after the kernel they belong to.** A machine with three kernels installed has
three of those directories.

**`depends`** lists other modules this one needs. Empty here; often not.
`modprobe` reads this so you never have to load dependencies by hand.

**`intree: Y`** means it ships with the kernel. `N` would mean it came from
somewhere else, and that is the set you have to think about at every update.

**`vermagic`** is the version stamp, and it is checked at load time. If it
does not match the running kernel exactly, the module is refused. Not warned
about, refused.

<details class="predict">
<summary>Given that <code>vermagic</code> must match exactly, what happens to a third-party driver (a proprietary graphics driver, say) when the machine installs a kernel update overnight and reboots?</summary>

**It stops loading.** The new kernel has a different version string, the module's
`vermagic` still names the old one, and the kernel refuses it.

The symptom is not an error about kernels or modules. It is that the hardware
appears to be missing: no graphics acceleration, or a network card that does not
exist, or a storage controller whose disks have vanished. Nothing on screen
mentions `vermagic`.

The old kernel is usually still installed, so **booting the previous entry
from the GRUB menu brings the hardware back**, which is both the emergency fix
and the confirmation that this is what happened.

The real fix is to rebuild the module for the new kernel. DKMS exists precisely
to do that automatically at every kernel install, and a third-party driver
installed without it is a scheduled outage waiting for a reboot.

</details>


<details class="deeper">
<summary>If you already administer Linux: taint flags, and what vendors read before your bug report</summary>

**`modinfo` will not tell you whether the kernel is unhappy about a module.**
`/proc/sys/kernel/tainted` will. It is a bitmask recording everything the kernel
considers to have compromised its own supportability, and it appears in the
header of every oops and panic.

The flags that come up: **`P`** a proprietary module is loaded, **`O`** an
out-of-tree module is loaded, **`E`** an unsigned module was force-loaded, **`D`**
the machine has already oopsed, **`W`** a warning was issued. `cat
/proc/sys/kernel/tainted` gives the number; the decoder table is in the kernel
documentation, and `dmesg | grep -i taint` usually names the offending module
directly.

Why it matters operationally: a tainted kernel is the first thing a
distribution vendor checks on a support case, and `P` or `O` is frequently
where the case stops. It is also a useful audit signal on a fleet. A machine
that is tainted and should not be has something on it nobody documented.

Taint is sticky. It is set at load time and does not clear when the module is
unloaded, so the only way back to a clean flag is a reboot without the module.

</details>

<details class="deeper">
<summary>If you already administer Linux: how a module gets loaded when nobody ran modprobe</summary>

Almost every module on a running machine was loaded automatically, and the
mechanism is worth knowing because it is also how you stop one loading.

**Devices advertise an identifier; modules advertise which identifiers they
handle.** A PCI card reports a vendor and device ID; a USB device reports its own
pair. Each module carries a table of aliases it claims, compiled in and readable:

```
modinfo e1000e | grep ^alias | head -3
cat /lib/modules/$(uname -r)/modules.alias | wc -l
```

When the kernel finds a device it cannot drive, it emits a uevent naming the
alias. `udev` receives it, asks `modprobe` for a module matching that alias, and
the driver loads. Nothing in userspace decided; the hardware asked.

**Which is why blacklisting is more subtle than it looks:**

```
# /etc/modprobe.d/blacklist-nouveau.conf
blacklist nouveau
install nouveau /bin/false
```

`blacklist` only stops the module being loaded **by alias**, the automatic
path. It does not stop it being loaded as a dependency of something else, and
it does not stop `modprobe nouveau` typed by hand. The `install ...
/bin/false` line is what closes both, by replacing the load action entirely.
Guides give both lines and rarely say why, and the reason is that the first
one alone does not work for the case people usually care about.

**And blacklisting is not enough on its own if the module is in the initramfs.**
The early boot environment carries its own copy of the module set and its own
configuration, so a blacklist added to `/etc/modprobe.d` after the fact is not
seen until you rebuild:

```
sudo dracut -f              # RHEL family
sudo update-initramfs -u    # Debian family
```

Forgetting that step is why "I blacklisted it and it still loads" is such a
common report. The module is being loaded before the root filesystem holding
your configuration is even mounted.

**The kernel command line is the escape hatch** when the machine will not boot far
enough to edit a file: adding `module_blacklist=nouveau` at the GRUB prompt applies
before anything on disk is read.

</details>

## Loading and unloading

The `dummy` module is counted, loaded, listed, unloaded, and counted again.
Note the **third column** of `lsmod` output while it is loaded. That is the
use count.

<details class="predict">
<summary>Loading a module has no effect on anything until something uses it. What will the use count be immediately after <code>modprobe</code>, and why does that matter for whether <code>modprobe -r</code> succeeds?</summary>

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ lsmod | grep -c dummy; sudo modprobe dummy; lsmod | grep dummy; sudo modprobe -r dummy; lsmod | grep -c dummy
0
dummy                  12288  0
0
```

</details>

**Zero, which is why the unload worked.** The kernel refuses to remove a
module whose use count is above zero, so `modprobe -r` on a driver with a
mounted filesystem or an up interface fails with `Module ... is in use`, and
the fix is never to force it but to stop whatever is using it. The third
column is the first thing to read when an unload is refused.

Not loaded, loaded, not loaded. Three states in one line.

| Command | Does |
| --- | --- |
| `modprobe name` | Load it, plus anything it depends on |
| `modprobe -r name` | Unload it, plus dependencies nothing else needs |
| `rmmod name` | Unload just that one, refusing if anything uses it |
| `lsmod` | What is loaded now |
| `modinfo name` | What a module is, whether loaded or not |
| `depmod` | Rebuild the dependency map after adding modules |

**Prefer `modprobe` over `insmod` and `rmmod`.** The older pair take a file path
and ignore dependencies entirely; `modprobe` takes a name, resolves dependencies,
and searches the right directory for the running kernel. The exam mentions both;
in practice `modprobe` is the answer.

Ask for something that does not exist and the message is unusually clear:

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ sudo modprobe notarealmodule; ls /etc/modprobe.d/ 2>/dev/null || echo "(empty)"; ls /usr/lib/modprobe.d/ | head -5
modprobe: FATAL: Module notarealmodule not found in directory /lib/modules/7.1.3-200.fc44.aarch64
blacklist-nouveau.conf
dist-blacklist.conf
systemd.conf
```

It names the directory it searched, and that directory has the kernel version
in it. When this message appears for a module you are sure exists, **read the
version in the path**. It is very often a module built for a different kernel,
or a `depmod` that was never run.

## Making a choice persist

Loading a module by hand lasts until reboot. Two directories make it permanent:

| Want | File | Line |
| --- | --- | --- |
| Load at boot | `/etc/modules-load.d/mine.conf` | `dummy` |
| Never load | `/etc/modprobe.d/blacklist-mine.conf` | `blacklist nouveau` |
| Pass an option | `/etc/modprobe.d/mine.conf` | `options nvme poll_queues=4` |

Note the two directories in the capture above. **`/usr/lib/modprobe.d/` is the
distribution's** and `/etc/modprobe.d/` is yours; yours wins. The file
`blacklist-nouveau.conf` shipping by default is a real example of the pattern:
`nouveau` is the open-source NVIDIA driver, and it is blacklisted so it does
not grab the card before the proprietary one gets a chance.

**Blacklisting is not absolute.** It stops the module being loaded automatically
as a dependency or by device detection; an explicit `modprobe nouveau` still
works. To refuse it outright you need `install nouveau /bin/false` instead, which
is the distinction the exam likes.


<details class="deeper">
<summary>If you already administer Linux: module parameters, and reading them back</summary>

`modprobe` accepts parameters on the command line, `modprobe nvme
poll_queues=4`, and `/etc/modprobe.d/*.conf` makes them permanent with an
`options` line. What is less well known is that you can **read the values a
loaded module is currently using**, which is the only way to confirm a
parameter actually took:

```
ls /sys/module/nvme/parameters/
cat /sys/module/nvme/parameters/poll_queues
```

`modinfo -p <module>` lists which parameters exist and what each one is for,
which beats searching for a driver's documentation.

Three things that catch people out. **Parameters set in `/etc/modprobe.d/`
only apply at load time**, so changing one does nothing until the module is
reloaded or the machine reboots. **Some parameters are writable at runtime**
through `/sys/module/.../parameters/`, and some are not, a file with mode
`0644` can be changed live, one with `0444` cannot. And **a module loaded from
the initramfs reads the copy of `modprobe.d` inside the initramfs**, not the
one on disk, so a storage or graphics parameter needs a rebuild to take
effect.

</details>

## Where modules come from

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ uname -r; ls /lib/modules/; ls /lib/modules/$(uname -r)/kernel/fs | head -8
7.1.3-200.fc44.aarch64
7.1.3-200.fc44.aarch64
9p
afs
binfmt_misc.ko.xz
cachefiles
ceph
dlm
ecryptfs
erofs
```

One kernel installed, so one directory, and its name is exactly what `uname
-r` prints. Under it, the tree is organised by subsystem: `kernel/fs/` for
filesystems, `kernel/drivers/` for hardware, `kernel/net/` for networking.

**`uname -r` is the command to reach for constantly.** It answers "which kernel is
running", which is the first half of nearly every module question. `uname -a`
gives the same plus architecture and build date.

And the loading happens without you:

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

Three lines from the kernel log, all in the first two seconds. The block
driver loaded and announced a 100 GiB disk called `vda`. The network driver
loaded and **renamed the interface from `eth0` to `enp0s1`**, that rename is
predictable interface naming, and it is why the interface on a modern machine
is not called what you expect. It comes back in the networking lessons.

Nobody typed `modprobe`. The kernel saw the hardware, looked up which module
claims it, and loaded it. `dmesg` is where you go to find out whether that
happened.

<details class="deeper">
<summary>If you already administer Linux: signing, DKMS, taint, and the initramfs consequence</summary>

**Module signing** is enforced when Secure Boot is on. An unsigned or wrongly
signed module is refused with `Key was rejected by service`, `-EKEYREJECTED`,
which reads like an authentication problem and is not. Enrol your own key with
`mokutil --import` and sign with `scripts/sign-file`, or turn Secure Boot off
and accept what that means.

**DKMS** rebuilds out-of-tree modules on every kernel install. Anything from
outside the distribution that you expect to survive an update belongs under it:
`dkms status` lists what is registered, and a module that is *not* there is the
one that will disappear at the next reboot. This is the single highest-value
check on a machine with vendor drivers.

**Taint flags** in `/proc/sys/kernel/tainted` and in the header of an oops record
what the kernel considers to have compromised its own supportability: `P` for a
proprietary module, `O` for out-of-tree, `E` for unsigned. `lsmod` will not tell
you; `cat /proc/sys/kernel/tainted` and the decoder in the kernel docs will.
Vendors read this before they read your bug report.

**`depmod`** regenerates `modules.dep` and `modules.alias` from what is in
`/lib/modules/<version>/`. Dropping a `.ko` in by hand without running it gives
you a module `modprobe` cannot find while `ls` plainly shows it. Package installs
run it for you, which is why this only bites when you are doing something by
hand.

**The initramfs consequence** joins this lesson to the last one. A module
needed to reach the root filesystem has to be in the initramfs, because at
that moment `/lib/modules` is not readable yet. Blacklist a storage driver, or
add one, and rebuild, `dracut -f` or `update-initramfs -u`, or the machine
boots fine today and not at all after the next restart.

**Unloading in production** deserves more caution than the commands suggest.
`modprobe -r` on a storage or network module with a zero use count can still
stall the machine, because the count tracks module references rather than
in-flight work. On a running server, prefer a blacklist and a scheduled reboot to
a live unload.

</details>

## Across distributions

| | RHEL family | Debian family |
| --- | --- | --- |
| Module directory | `/lib/modules/$(uname -r)/` | `/lib/modules/$(uname -r)/` |
| Distribution defaults | `/usr/lib/modprobe.d/` | `/lib/modprobe.d/` |
| Your overrides | `/etc/modprobe.d/` | `/etc/modprobe.d/` |
| Load at boot | `/etc/modules-load.d/*.conf` | `/etc/modules-load.d/*.conf` or `/etc/modules` |
| Rebuild initramfs after a change | `dracut -f` | `update-initramfs -u` |
| Kernel package | `kernel`, `kernel-core` | `linux-image-*` |

The commands are the same everywhere; this is one of the more portable corners of
Linux. Debian's older `/etc/modules` still works and still appears in
documentation, but `/etc/modules-load.d/` is the systemd-era answer and is
understood on both.

## Prove it

After loading, blacklisting, or updating a module:

```bash
# Is it loaded, and is anything using it
lsmod | grep thename

# Which file would load, and for which kernel
modinfo thename | head -3

# Did the kernel say anything when it loaded
sudo dmesg | grep -i thename | tail

# Will the choice survive a reboot
grep -r thename /etc/modprobe.d/ /etc/modules-load.d/
```

That last one is the check people skip. A module loaded by hand and a module
loaded at boot look identical in `lsmod`, and only one of them is still there
tomorrow.

## What trips people up

### 1. "Module not found in directory /lib/modules/..."

Read the version in that path and compare it to `uname -r`. Three common causes:

- **The module was built for a different kernel.** Common after an update, when
  the machine booted a new kernel and the module was built against the old one.
- **`depmod` was never run** after a module was copied in by hand.
- **The module genuinely is not installed**. It is in an optional package such
  as `kernel-modules-extra` on the RHEL family.

### 2. "Module is in use" when unloading

`rmmod: ERROR: Module xyz is in use`. Look at the third column of `lsmod`: it
names what is holding it.

Unload the dependants first, or use `modprobe -r`, which does that for you. If
the user count is non-zero with no names listed, something has the device
open, a mounted filesystem, a configured interface, a running process.

### 3. It worked until the kernel was updated

The classic. Anything out-of-tree has to be rebuilt per kernel, and `vermagic`
enforces it.

Boot the previous kernel from the GRUB menu to confirm, then fix it properly with
DKMS so it rebuilds itself next time. Do not fix it by pinning the kernel and
never updating; that trades a driver problem for a security problem.

### 4. Blacklisting and being surprised it still loads

`blacklist` prevents automatic loading, not explicit loading, and not loading as
a dependency of a module that lists it under `install`. If something must never
load, `install thename /bin/false` is the stronger form.

And if the module loads during boot before userspace exists, the blacklist has
to be in the initramfs too, which means rebuilding it.

### 5. Assuming every module is a driver

`raid1`, `nft_ct`, `dm_crypt`, `xfs`, `overlay`, software subsystems, all of
them modules. Unload one thinking it is a driver for absent hardware and you
have taken away the firewall, or the ability to mount a filesystem.

Check `modinfo`'s `description` line before unloading anything you did not load
yourself.

## Work it through

A server has a vendor storage card. It has worked for a year. The machine was
patched and rebooted at the weekend, and it now boots to an emergency shell
saying it cannot find the root filesystem.

You boot the previous kernel from the GRUB menu and everything works perfectly.

Reason it out before reading on.

**Booting the old kernel fixes it, so the hardware is fine.** So is the disk,
the data, the partition table, and the bootloader, all of those are the same
on both kernels. The variable is the kernel.

What differs between kernels? The module directory. `/lib/modules/<old>/` and
`/lib/modules/<new>/` are separate trees, and a module in one is not in the
other. The vendor's driver was installed once, into the tree that existed at
the time.

Why an emergency shell rather than a boot with one missing card? Because this
card holds the root filesystem. From the last lesson: the initramfs has to
load whatever is needed to reach root. It could not, so stage 4 gave up. Had
the card held only a data volume, the machine would have booted and the volume
would simply have been absent, a much quieter and arguably worse failure.

**Confirm it.** From the working boot: `modinfo thedriver | grep -E
'filename|vermagic'` shows which kernel it belongs to, and `dkms status` shows
whether anything is registered to rebuild it. An empty `dkms status` is the
finding.

**The fix.** Install the driver under DKMS so it builds for every kernel, then
rebuild the initramfs for the new kernel with `dracut -f --kver <new>`, then
reboot deliberately.

Now the question underneath: **why did the kernel update succeed and report no
problem?** Because from the package manager's point of view nothing was wrong.
It installed a kernel. It has no idea which of the modules on the machine came
from outside the distribution, and the module that would have complained never
ran. It was never built.

The habit worth taking: **on any machine with out-of-tree drivers, `dkms status`
belongs in the pre-reboot checklist**, next to checking that `/boot` has room.

## Try it

Optional, if you have a machine handy.

1. `uname -r`, then `ls /lib/modules/`. Say how many kernels are installed.
2. `lsmod | wc -l`, then `lsmod | head`. Find a module with a non-zero use count
   and name what is using it.
3. `modinfo` on one of them. Say whether it is in-tree and which kernel it is for.
4. `sudo modprobe dummy`, confirm with `lsmod | grep dummy`, then
   `sudo modprobe -r dummy`. Harmless, and it creates nothing you have to undo.
5. `ls /etc/modprobe.d/ /usr/lib/modprobe.d/` and read any blacklist file you
   find. Work out what it is protecting against.
6. `sudo dmesg | head -40` and find the point where the storage driver loaded.

**Verification step.** You have it when you can take a device that is not working
and say, in order, whether the module exists, whether it loaded, and whether
anything stopped it.

## Check yourself

<details class="qa">
<summary>Why is the kernel built as a small core plus loadable modules rather than one large program?</summary>

**Because it has to support hardware that is not present, and hardware that did
not exist when it was compiled.** Building every driver in would make the kernel
enormous, and almost all of it would be code for devices this machine will never
have.

Modules let the kernel load only what the hardware in front of it needs, at the
moment it meets that hardware. It also means a driver can be added to a running
system without rebooting, and a broken one can be unloaded.

The cost is the version coupling: a module is compiled against a specific kernel
and is refused by any other, which is where most module problems come from.

</details>

<details class="qa">
<summary><code>rmmod xfs</code> fails with "Module is in use". Where do you look, and what is the likely cause?</summary>

**The third column of `lsmod`**, which shows a use count and, when it can, the
names of the modules using it.

For `xfs` specifically the likely cause is not another module but **a mounted XFS
filesystem**. The count tracks anything holding a reference, and an active mount
does. `findmnt -t xfs` finds them.

`modprobe -r` unloads dependants first and is generally the better command, but
it cannot help here: it will not unmount a filesystem for you, and it should not.

Worth adding: even a zero use count does not make a live unload of a storage or
network module safe on a production server. Blacklist and reboot rather than
unload and hope.

</details>

<details class="qa">
<summary>What is <code>vermagic</code> and what does it cause to happen after a kernel update?</summary>

A version string compiled into every module, naming the exact kernel it was built
for. The kernel compares it at load time and **refuses any module that does not
match**.

After an update, the machine boots a new kernel with a new version string.
Modules that came from the distribution were rebuilt and shipped alongside it,
so they match. Anything from outside (a vendor driver, something compiled
locally) still carries the old string and will not load.

The symptom is missing hardware rather than an error message, which is what makes
it confusing. Booting the previous kernel restores it and confirms the diagnosis;
DKMS is the fix, because it rebuilds registered modules at every kernel install.

</details>

<details class="qa">
<summary>What is the difference between <code>blacklist nouveau</code> and <code>install nouveau /bin/false</code>?</summary>

**`blacklist`** stops the module being loaded automatically, by device
detection, or as a dependency resolved by alias. An explicit `modprobe
nouveau` still loads it.

**`install nouveau /bin/false`** replaces the load action itself with a command
that fails, so nothing loads it, including an explicit `modprobe`.

Use the first when you want a different driver to win the race for a device,
which is the usual case and is why `blacklist-nouveau.conf` ships by default. Use
the second when the module must not be present at all.

One catch for both: if the module would load during early boot, the rule has to
be in the initramfs as well, which means rebuilding it after adding the file.

</details>

<details class="qa">
<summary>You copy a <code>.ko</code> file into <code>/lib/modules/$(uname -r)/extra/</code> and <code>modprobe</code> says it cannot find it, while <code>ls</code> shows it plainly. What is missing?</summary>

**`depmod`.** `modprobe` does not search the directory tree; it reads
`modules.dep` and `modules.alias`, which are index files generated from the tree.
A file that is present but not in the index is invisible to it.

`sudo depmod -a` regenerates them, after which `modprobe` finds it.

You never hit this installing packages, because the package scripts run `depmod`
for you. It shows up exactly when you are placing a module by hand, which is also
when you should be asking whether DKMS should be doing this instead.

</details>

## References

- [modprobe(8)](https://man7.org/linux/man-pages/man8/modprobe.8.html) - Linux man-pages project. Accessed 2026-08-07.
- [lsmod(8)](https://man7.org/linux/man-pages/man8/lsmod.8.html) - Linux man-pages project. Accessed 2026-08-07.
- [modinfo(8)](https://man7.org/linux/man-pages/man8/modinfo.8.html) - Linux man-pages project. Accessed 2026-08-07.
- [depmod(8)](https://man7.org/linux/man-pages/man8/depmod.8.html) - Linux man-pages project. Accessed 2026-08-07.
- [modprobe.d(5)](https://man7.org/linux/man-pages/man5/modprobe.d.5.html) - Linux man-pages project. Accessed 2026-08-07.
- [uname(1)](https://man7.org/linux/man-pages/man1/uname.1.html) - Linux man-pages project. Accessed 2026-08-07.

Command output was captured on the podman machine, which has a real kernel; a
container borrows the host's and has no modules of its own. Blocks without a
distribution and architecture header are illustrative.
