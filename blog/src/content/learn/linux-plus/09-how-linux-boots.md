---
title: "How Linux boots"
description: "The five stages between the power button and the login prompt, what each one hands to the next, and why knowing the order turns an unbootable machine from a mystery into a short list."
deck: "From the power button to the login prompt"
track: "linux-plus"
level: "working"
order: 100
objectives:
  - "Name the five boot stages in order and say what each one hands to the next"
  - "Explain what UEFI does differently from BIOS, and where the bootloader lives in each"
  - "Say what the initramfs is for and why a system can boot without one only sometimes"
  - "Read a kernel command line and change it for one boot"
prerequisites: ["installing-software"]
tags: ["linux", "linux-plus", "boot", "grub", "systemd"]
updated: 2026-08-07
draft: false
examObjectives:
  - exam: "xk0-006"
    domain: "1.0"
    objective: "1.1"
sources:
  - title: "boot(7)"
    url: "https://man7.org/linux/man-pages/man7/boot.7.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "bootup(7)"
    url: "https://man7.org/linux/man-pages/man7/bootup.7.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "The kernel's command-line parameters"
    url: "https://docs.kernel.org/admin-guide/kernel-parameters.html"
    publisher: "The Linux Kernel documentation"
    accessed: 2026-08-07
    tier: 1
  - title: "GNU GRUB Manual"
    url: "https://www.gnu.org/software/grub/manual/grub/grub.html"
    publisher: "GNU Project"
    accessed: 2026-08-07
    tier: 1
  - title: "dracut(8)"
    url: "https://man7.org/linux/man-pages/man8/dracut.8.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "efibootmgr(8)"
    url: "https://manpages.debian.org/stable/efibootmgr/efibootmgr.8.en.html"
    publisher: "Debian Project"
    accessed: 2026-08-07
    tier: 1
symptoms:
  - symptom: "Machine drops to a dracut or initramfs emergency shell"
    anchor: "2-dropped-into-an-initramfs-emergency-shell"
  - symptom: "GRUB rescue prompt instead of a boot menu"
    anchor: "1-grub-rescue-or-no-menu-at-all"
---

> **Before you read.** You press the power button. A few seconds later you get a
> login prompt.
>
> In between, at least five separate programs ran, each one loading the next and
> then getting out of the way. None of them is the operating system, exactly, and
> the last one only starts once the first four have all done their jobs.
>
> Here is the question worth holding: **if the disk holding your operating system
> needs a driver to be read, and that driver is a file on that disk, how does the
> first one ever get loaded?**

That is a genuine chicken-and-egg problem and it has a specific, elegant answer,
which is the most interesting thing in this lesson. Everything else here is
sequence, and sequence is easy once you have seen it once.

The practical payoff: when a machine will not boot, the symptom tells you which
stage failed, and that narrows "the server is dead" to one of five places.

### Some words you will need

<dl class="terms">
<dt>firmware</dt>
<dd>Software built into the machine itself, running before any disk is read. BIOS on older hardware, UEFI on anything modern.</dd>
<dt>bootloader</dt>
<dd>A small program whose only job is to find a kernel, load it into memory, and start it. Almost always GRUB.</dd>
<dt>kernel</dt>
<dd>The core of the operating system. Talks to hardware, manages memory and processes. Everything else is a program running on top of it.</dd>
<dt>initramfs</dt>
<dd>A small temporary filesystem loaded into memory alongside the kernel, holding just enough drivers to reach the real disk.</dd>
<dt>target</dt>
<dd>A named state systemd brings the machine to, such as "multi-user" or "graphical". The rough equivalent of the old runlevels.</dd>
</dl>

## What breaks without this

**An unbootable machine is unfixable.** Not because the fix is hard, but because
you cannot tell whether the problem is the firmware setting, the bootloader
config, a missing kernel, a broken initramfs, or a failed service. Those have
five different fixes and one identical symptom: a black screen.

**You cannot change a kernel parameter.** Recovering a lost root password,
booting a previous kernel, or disabling a driver that hangs the machine all
happen by editing the boot entry, which requires knowing which stage reads it.

**You reboot hopefully.** The most expensive habit in this business is rebooting a
production machine without knowing whether it will come back.

## The five stages

<figure class="learn-figure">
<svg viewBox="0 0 720 400" role="img" aria-labelledby="boot-title boot-desc" style="width:100%;height:auto;">
  <title id="boot-title">The five stages of a Linux boot, in order</title>
  <desc id="boot-desc">Firmware runs first and finds a bootloader: UEFI reads a .efi file from the EFI System Partition, while legacy BIOS reads the first 512 bytes of the disk. The bootloader, usually GRUB, loads the kernel and the initramfs from /boot. The kernel starts and mounts the initramfs as a temporary root. The initramfs loads the drivers needed to reach the real root filesystem, mounts it, and switches to it. Finally systemd, process ID 1, starts services until the default target is reached.</desc>
  <g>
    <!-- stage 1 -->
    <rect x="24" y="18" width="168" height="46" rx="4" fill="currentColor" fill-opacity="0.07" stroke="currentColor" stroke-opacity="0.3"/>
    <text x="108" y="40" text-anchor="middle" font-size="13" fill="currentColor">1. Firmware</text>
    <text x="108" y="56" text-anchor="middle" font-size="10" fill="currentColor" fill-opacity="0.6">UEFI or BIOS</text>
    <text x="210" y="34" font-size="11" fill="currentColor" fill-opacity="0.75">Tests the hardware, then looks for something to boot.</text>
    <text x="210" y="50" font-size="10" fill="currentColor" fill-opacity="0.5">UEFI: reads a .efi file from the EFI System Partition</text>
    <text x="210" y="64" font-size="10" fill="currentColor" fill-opacity="0.5">BIOS: reads the first 512 bytes of the disk</text>
    <!-- stage 2 -->
    <rect x="24" y="92" width="168" height="46" rx="4" fill="currentColor" fill-opacity="0.07" stroke="currentColor" stroke-opacity="0.3"/>
    <text x="108" y="114" text-anchor="middle" font-size="13" fill="currentColor">2. Bootloader</text>
    <text x="108" y="130" text-anchor="middle" font-size="10" fill="currentColor" fill-opacity="0.6">GRUB</text>
    <text x="210" y="110" font-size="11" fill="currentColor" fill-opacity="0.75">Shows the menu. Loads a kernel and an initramfs from /boot.</text>
    <text x="210" y="126" font-size="10" fill="currentColor" fill-opacity="0.5">This is where you edit the kernel command line</text>
    <!-- stage 3 -->
    <rect x="24" y="166" width="168" height="46" rx="4" fill="currentColor" fill-opacity="0.07" stroke="currentColor" stroke-opacity="0.3"/>
    <text x="108" y="188" text-anchor="middle" font-size="13" fill="currentColor">3. Kernel</text>
    <text x="108" y="204" text-anchor="middle" font-size="10" fill="currentColor" fill-opacity="0.6">vmlinuz</text>
    <text x="210" y="184" font-size="11" fill="currentColor" fill-opacity="0.75">Takes over the hardware, then mounts the initramfs as a temporary root.</text>
    <text x="210" y="200" font-size="10" fill="currentColor" fill-opacity="0.5">Cannot reach the real disk yet: no drivers loaded</text>
    <!-- stage 4 -->
    <rect x="24" y="240" width="168" height="46" rx="4" fill="currentColor" fill-opacity="0.07" stroke="currentColor" stroke-opacity="0.3"/>
    <text x="108" y="262" text-anchor="middle" font-size="13" fill="currentColor">4. initramfs</text>
    <text x="108" y="278" text-anchor="middle" font-size="10" fill="currentColor" fill-opacity="0.6">in memory</text>
    <text x="210" y="258" font-size="11" fill="currentColor" fill-opacity="0.75">Loads the drivers for the real root: RAID, LVM, encryption, the disk itself.</text>
    <text x="210" y="274" font-size="10" fill="currentColor" fill-opacity="0.5">Mounts the real root, switches to it, and disappears</text>
    <!-- stage 5 -->
    <rect x="24" y="314" width="168" height="46" rx="4" fill="currentColor" fill-opacity="0.07" stroke="currentColor" stroke-opacity="0.3"/>
    <text x="108" y="336" text-anchor="middle" font-size="13" fill="currentColor">5. systemd</text>
    <text x="108" y="352" text-anchor="middle" font-size="10" fill="currentColor" fill-opacity="0.6">PID 1</text>
    <text x="210" y="332" font-size="11" fill="currentColor" fill-opacity="0.75">Starts services in dependency order until the default target is reached.</text>
    <text x="210" y="348" font-size="10" fill="currentColor" fill-opacity="0.5">Login prompt appears somewhere in here</text>
  </g>
  <g stroke="currentColor" stroke-opacity="0.45" fill="none" stroke-width="1.2">
    <path d="M108 64 L108 88 M103 82 L108 89 L113 82"/>
    <path d="M108 138 L108 162 M103 156 L108 163 L113 156"/>
    <path d="M108 212 L108 236 M103 230 L108 237 L113 230"/>
    <path d="M108 286 L108 310 M103 304 L108 311 L113 304"/>
  </g>
</svg>
<figcaption>Each stage exists only to start the next one, then gets out of the way.</figcaption>
</figure>

**The handover is the thing to remember.** Each stage knows almost nothing except
how to find and start the next one. That is why a boot failure is diagnosable:
whatever you saw last tells you which stage was still alive.

## The chicken and the egg

Back to the question at the top. Your root filesystem might be on an LVM logical
volume, on top of a RAID array, on top of an NVMe disk, possibly encrypted. The
kernel needs drivers for every one of those layers. Those drivers are files.
They live on the filesystem the kernel cannot yet read.

**The initramfs is the answer.** The bootloader loads *two* files into memory: the
kernel, and a small compressed archive containing exactly the drivers this
machine needs to reach its own root filesystem. The kernel mounts that archive as
a temporary root, runs the tools inside it to assemble the RAID, activate the
LVM, unlock the encryption, and mount the real root. Then it **switches** to the
real root and the temporary one is discarded.

So the drivers arrive in memory, alongside the kernel, before any disk is
readable. The egg was carried in.

Two consequences worth carrying:

- **The initramfs is built for this machine.** It is not part of the kernel
  package. Change the storage layout without rebuilding it and the machine will
  not boot, which is the single most common self-inflicted boot failure there is.
- **A machine with a plain root filesystem on a driver the kernel has built in
  can boot without one.** Rare on a general-purpose distribution, common in
  embedded systems and appliances.

<details class="deeper">
<summary>If you already administer Linux: building the initramfs, and looking inside one</summary>

**dracut** builds it on the RHEL family; `update-initramfs` wraps
`mkinitramfs` on Debian. `dracut -f` rebuilds for the running kernel and
`dracut --regenerate-all -f` does every installed kernel, which is what you
actually want after changing the storage stack, rebuilding only the running
kernel leaves the others unbootable and you find out at the next update.

**`lsinitrd`** lists what went in. It is the fast way to answer "does this
initramfs contain the driver for the card we just fitted", and it beats
rebooting to find out. `lsinitrd -f /etc/fstab` even prints a file from inside
it, which is how you check what the early boot thinks the storage layout is.

**Host-only versus generic** is the setting that catches people out. The default
is host-only: an image containing just the drivers *this* machine needs, which
is small and fast and completely unusable if the disk is moved to different
hardware. `dracut --no-hostonly` produces a larger image that boots anywhere,
and it is what you want for golden images, rescue media, and anything that might
be restored onto a different server than it came off.

`rd.` is the prefix for dracut's own kernel parameters. `rd.break` stops at a
chosen point in early boot and hands you a shell: `rd.break=pre-mount` is the
one for debugging why root will not mount. `rd.debug` makes it noisy. Both go
on the kernel command line, which is the next section.

</details>

<details class="deeper">
<summary>If you already administer Linux: why there is an initramfs at all, and what is inside it</summary>

The five stages have one that looks redundant: the kernel loads a small
filesystem into memory, uses it, and then throws it away to mount the real root.
Why not mount the real root directly?

**Because of a circular dependency.** To mount `/` the kernel needs a driver
for the controller the disk is on, a driver for the filesystem, and possibly
LVM, RAID, multipath, or LUKS assembled first. Those drivers are modules.
Modules live in `/lib/modules`, which is on `/`. The kernel cannot reach the
thing it needs to reach that thing.

**The initramfs breaks the cycle.** It is a compressed cpio archive containing
just enough userspace, a shell, `udev`, the storage modules, and the tools to
assemble whatever `/` sits on top of. The kernel unpacks it into a tmpfs, runs
`/init` from it, and that assembles the real root and pivots to it.

You can look inside one:

```
lsinitrd /boot/initramfs-$(uname -r).img | head -30      # RHEL family
lsinitrd /boot/initramfs-$(uname -r).img -f etc/cmdline.d/*.conf
unmkinitramfs /boot/initrd.img-$(uname -r) /tmp/x        # Debian family
```

**The alternative to building one is compiling every needed driver into the kernel
itself**, which is what an embedded system with fixed hardware does. A general
distribution cannot, because it does not know whether your root is on NVMe, iSCSI,
or an encrypted volume on a RAID set, and building all of it in would produce an
enormous kernel that loads drivers for hardware nobody has.

**The operationally important consequence is that the initramfs is machine
state, not vendor state.** It is generated locally, and it goes stale:

- Add a storage driver, a LUKS volume, or a RAID set and the initramfs needs
  rebuilding or the machine will not find its root.
- Blacklist a module in `/etc/modprobe.d` and it is ignored until you rebuild.
- Change the root filesystem's UUID, which `mkfs` does, and the reference
  baked into both GRUB and the initramfs is wrong.

`dracut -f` and `update-initramfs -u` are the rebuild commands, and both are worth
running before rebooting a machine whose storage you have touched. **A broken
initramfs presents as `dracut-initqueue timeout` and a dracut emergency shell**,
which is a recognisable enough failure that spotting it saves an hour.

</details>

## Where the bootloader lives

UEFI and BIOS differ in exactly one way that matters here: **how the firmware
finds the bootloader.**

| | Legacy BIOS | UEFI |
| --- | --- | --- |
| Where the firmware looks | First 512 bytes of the disk (the MBR) | A FAT partition called the EFI System Partition |
| What it finds there | 446 bytes of code, which loads more code | A normal file, such as `grubx64.efi` |
| Partition table | MBR, four primary partitions, 2 TB limit | GPT, 128 partitions, huge disks |
| Boot entries stored in | Nowhere; there is one MBR | The firmware's own NVRAM, editable from Linux |

The UEFI arrangement is better in a way you can feel: the bootloader is **a file
on a filesystem**, which you can list, copy, and back up, rather than raw bytes
in a place with no filenames.

Here is a real UEFI disk layout:

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ lsblk -f
NAME   FSTYPE FSVER LABEL      UUID                                 FSAVAIL FSUSE% MOUNTPOINTS
vda                                                                                
├─vda1                                                                             
├─vda2 vfat   FAT16 EFI-SYSTEM 7B77-95E7                                           
├─vda3 ext4   1.0   boot       ec4a7bbc-82cf-4c92-a421-381dd40c0e0c  167.7M    45% /boot
└─vda4 xfs          root       159ca8aa-2ced-4891-90cc-0bde469c40f8   94.4G     5% /var
                                                                                   /sysroot/ostree/deploy/fedora-coreos/var
                                                                                   /sysroot
                                                                                   /usr
                                                                                   /etc
                                                                                   /
```

Read it from the top. **`vda2` is `vfat` and labelled `EFI-SYSTEM`**. That is
the EFI System Partition, and it is FAT because FAT is the one filesystem
every UEFI implementation is required to understand. **`vda3` is `/boot`**,
holding the kernel and initramfs. **`vda4` is the root filesystem.** That
three-partition shape is what a modern install looks like.

Two things about this particular machine, so the output does not mislead you.
It is aarch64 rather than x86_64, which changes the bootloader filename from
`grubx64.efi` to `grubaa64.efi` and nothing else. And it is an image-based
system, which is why `vda4` lists six mount points instead of one: `/`,
`/etc`, `/usr`, and `/var` are all the same filesystem presented at several
places at once. On an ordinary server that column would say `/` and stop. It
does illustrate something true and worth noticing early, though, **a mount
point is not a disk**, and one filesystem can appear in more than one place.

The firmware's own list of boot entries is readable from Linux:

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ sudo efibootmgr | head -8
BootCurrent: 0000
Timeout: 0 seconds
BootOrder: 0005,0000,0001,0002,0003,0004
Boot0000* UEFI Misc Device	PciRoot(0x0)/Pci(0x6,0x0){auto_created_boot_option}
Boot0001* UEFI Non-Block Boot Device	PciRoot(0x0)/Pci(0x7,0x0){auto_created_boot_option}
Boot0002* UEFI Non-Block Boot Device 2	PciRoot(0x0)/Pci(0x8,0x0){auto_created_boot_option}
Boot0003* UEFI Non-Block Boot Device 3	PciRoot(0x0)/Pci(0x9,0x0){auto_created_boot_option}
Boot0004* UEFI Non-Block Boot Device 4	PciRoot(0x0)/Pci(0xa,0x0){auto_created_boot_option}
```

`BootOrder` is the sequence the firmware will try. `BootCurrent` is the one that
actually worked this time. On a machine that boots the wrong thing, those two
lines are the fastest diagnosis available, and `efibootmgr -o` reorders them
without going into the firmware setup screen.

<details class="deeper">
<summary>If you already administer Linux: grub.cfg is generated, and Secure Boot's real consequence</summary>

**Never edit `/boot/grub2/grub.cfg` by hand.** It is generated, and the next
kernel update overwrites it, which gives you a machine that boots correctly
for three weeks and then does not. Edit `/etc/default/grub` for global
settings, drop files into `/etc/grub.d/` for entries, then regenerate with
`grub2-mkconfig -o /boot/grub2/grub.cfg` on the RHEL family or `update-grub`
on Debian.

Recent RHEL-family releases have moved further, generating **BootLoaderSpec**
entries under `/boot/loader/entries/`, one small file per kernel, with `grubby
--info=ALL` and `grubby --update-kernel` as the supported way to change them.
On those systems editing `grub.cfg` is doubly pointless, because the menu is
assembled from the entry files at boot.

**Secure Boot** has the firmware verify the bootloader's signature, the
bootloader verify the kernel's, and the kernel verify module signatures.
Distributions ship a small signed `shim` that chains to their own GRUB, because
the shim is what Microsoft's key has signed.

The practical consequence is not about booting at all: it is that an
**out-of-tree module** (a proprietary graphics driver, a vendor storage
driver) silently refuses to load until you enrol your own key with `mokutil
--import`. The failure presents as the hardware simply not being there, with
nothing on screen mentioning signatures. `mokutil --sb-state` tells you
whether Secure Boot is on, and it is the first thing to check when a driver
that installed cleanly does nothing.

</details>

## The kernel command line

The bootloader passes the kernel a line of text. That line decides a
surprising amount, and it is readable after the fact, including the one thing
the kernel cannot discover for itself.

<details class="predict">
<summary>The kernel has just been loaded into memory and has no filesystem yet. There is one piece of information it absolutely must be told rather than work out. What is it, and can you spot it in the line below?</summary>

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ cat /proc/cmdline
BOOT_IMAGE=(hd0,gpt3)/boot/ostree/fedora-coreos-b03a2111206afe90841d87f839937afc8dce4e7fa9e11e5ac0c314f03439c33f/vmlinuz-7.1.3-200.fc44.aarch64 rw ignition.firstboot ostree.prepare-root.composefs=0 ostree=/ostree/boot.1/fedora-coreos/b03a2111206afe90841d87f839937afc8dce4e7fa9e11e5ac0c314f03439c33f/0 ignition.platform.id=applehv console=tty0 console=hvc0
```

</details>

**Which filesystem to mount as `/`.** Everything else on that line is a preference;
that one is the bootstrap problem. The kernel cannot look up the root filesystem in
a configuration file, because configuration files live on the root filesystem.
Here it is the `ostree=` parameter doing the job; on an ordinary server it is
`root=UUID=...`, and a wrong or missing value is the single most common cause of a
kernel panic at boot.

That is a long one, because this machine is an image-based system with its own
parameters. On an ordinary server it looks more like
`root=UUID=... ro quiet`. The parts that matter to you are the same either way:

| Parameter | Does |
| --- | --- |
| `root=UUID=...` | Which filesystem to mount as `/` |
| `ro` / `rw` | Mount it read-only at first, or read-write |
| `quiet` | Suppress kernel messages; remove it to watch the boot |
| `single` or `rescue` | Boot to a minimal single-user state |
| `init=/bin/bash` | Skip systemd entirely and run a shell as PID 1 |
| `nomodeset` | Skip graphics mode setting, for a machine that boots to a black screen |

**`init=/bin/bash` is the classic lost-root-password recovery.** You edit the boot
entry in the GRUB menu, add it, boot, and land in a root shell with no
authentication, because nothing that authenticates has started yet. It also
explains why physical access is effectively root access, and why encrypted disks
and a GRUB password exist.

Editing in the GRUB menu is per-boot: press `e`, change the line, press Ctrl+X.
Nothing is written to disk, so a mistake is fixed by rebooting.

<details class="deeper">
<summary>If you already administer Linux: making a kernel parameter permanent, on each family</summary>

The per-boot edit is the right tool for testing and the wrong one for anything
you want to keep. Three ways to persist it, and picking the wrong one is a
common source of "I set that and it did not stick".

**RHEL family, current releases:** `grubby` edits the BootLoaderSpec entries
directly, which is the supported path.

```
sudo grubby --update-kernel=ALL --args="transparent_hugepage=never"
sudo grubby --update-kernel=ALL --remove-args="quiet"
sudo grubby --info=ALL | grep args
```

`--update-kernel=ALL` matters: applying it only to the running kernel leaves the
next one without it, and the setting quietly disappears at the following update.

**Either family, via the template:** add it to `GRUB_CMDLINE_LINUX` in
`/etc/default/grub`, then regenerate. This is the one that survives a
`grub2-mkconfig`, because it is the input that generation reads.

**Verify by reading it back, not by trusting the command.** After a reboot,
`cat /proc/cmdline` is the only thing that proves the kernel received it. A
parameter can be present in the config, absent from the entry, and missing from
the running kernel, and only the third one matters.

Worth knowing which parameters are worth persisting at all: `nomodeset` for a
machine that boots to a black screen, `transparent_hugepage=never` for several
databases that document it, `elevator=` on older kernels, and
`systemd.unit=rescue.target` as a permanent choice on an appliance. Most other
things belong in configuration rather than on the command line.

</details>

<details class="predict">
<summary>Given the five stages, at which one does <code>init=/bin/bash</code> take effect, and why does that mean no password is required?</summary>

**Stage 5, or rather instead of it.** The kernel starts one process when it has
finished mounting the real root, and `init=` names which program that is.
Normally it is systemd. Set to `/bin/bash`, you get a shell as PID 1.

No password is required because **nothing that could ask for one has started
yet**. Logins are handled by services, services are started by systemd, and
systemd is exactly the thing you have just replaced. There is no login prompt to
get past because there is no login service running.

The consequence is worth stating plainly: anyone who can reach the GRUB menu of
an unencrypted machine can become root on it. Full-disk encryption and a GRUB
password are the two things that change that, and physical security is the third.

</details>

## systemd takes over

The kernel starts exactly one process. That process is PID 1, it is systemd on
every distribution this exam covers, and everything else on the machine descends
from it.

systemd reads what the default target is and works backwards through dependencies
to start what is needed:

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ systemd-analyze; systemctl get-default
Startup finished in 392ms (kernel) + 5.307s (initrd) + 3.637s (userspace) = 9.337s 
multi-user.target reached after 3.486s in userspace.
multi-user.target
```

**That first line is the whole lesson in one command.** Three numbers, one per
phase: the kernel took 392 milliseconds, the initramfs took 5.3 seconds, and
userspace took 3.6 seconds. A slow boot is one of those three, and you now know
which.

`multi-user.target` is a server booted to a text login with networking. The
alternative you will meet is `graphical.target`. Two others matter:
`rescue.target` for single-user with a root shell, and `emergency.target` for the
absolute minimum when even that will not start.

<details class="deeper">
<summary>If you already administer Linux: reading a slow boot, and the order of the emergency options</summary>

**`systemd-analyze blame` is the obvious tool and frequently the wrong one.** It
sorts units by how long each took, which is not the same as what delayed the
boot: a unit taking 30 seconds in parallel with everything else costs nothing.
`systemd-analyze critical-chain` shows the actual dependency path that determined
the finish time, and that is where the fix is. `systemd-analyze plot > boot.svg`
draws the whole thing when the chain is not obvious.

A slow initrd phase is nearly always waiting rather than working. A device
that never appears, a network mount attempted too early, or a `root=` naming
something that is not there. The time is a timeout expiring. `systemd-analyze`
splitting the boot into kernel, initrd, and userspace is what lets you tell
that apart from a genuinely slow service, in one command.

The order of the emergency options, when a machine will not come up at all,
from most to least hospitable:

`rescue.target` first, mounts the local filesystems, starts a minimal set of
services, and gives you a root shell with a working system underneath.

`emergency.target` next, a read-only root and almost nothing else. Reach for
it when `rescue` cannot get far enough, and expect to `mount -o remount,rw /`
before you can change anything.

`init=/bin/bash` last, and only when the other two fail, because at that point
there is no `/proc`, no `/sys`, no writable root, and no systemd. Mounting those
by hand is the first thing you will need to do, and forgetting `/proc` makes
every subsequent tool behave strangely for reasons that are not obvious.

All three are typed onto the kernel command line at the GRUB menu, which is why
the previous section matters more than it looks.

</details>

## Across distributions

| | RHEL family | Debian family |
| --- | --- | --- |
| GRUB config | `/boot/grub2/grub.cfg` | `/boot/grub/grub.cfg` |
| Regenerate it | `grub2-mkconfig -o ...` | `update-grub` |
| Global settings | `/etc/default/grub` | `/etc/default/grub` |
| Build the initramfs | `dracut -f` | `update-initramfs -u` |
| Per-kernel entries | `grubby`, `/boot/loader/entries/` | `/boot/grub/grub.cfg` |
| Commands are prefixed | `grub2-` | `grub-` |

**That `grub2-` prefix is a real trap.** Every command on the RHEL family is
`grub2-mkconfig`, `grub2-install`, `grub2-editenv`; on Debian they are
`grub-mkconfig`, `grub-install`. Same software, and a runbook that hardcodes one
fails on the other with `command not found`.

## Prove it

After any change to the bootloader, the kernel, or the storage layout:

```bash
# What the running kernel was actually told
cat /proc/cmdline

# Which kernels are installed and which is default
sudo grubby --info=ALL | grep -E '^(kernel|index)'   # RHEL family

# Where the time went on the last boot
systemd-analyze
systemd-analyze blame | head

# Anything that failed to start
systemctl --failed
```

And the one that matters most: **reboot while you can still get to the machine
another way.** Discovering a boot problem at the next unplanned restart, six
weeks later, is how a five-minute fix becomes an outage.

## What trips people up

### 1. GRUB rescue, or no menu at all

`grub rescue>` means GRUB started but cannot find its own configuration or
modules. The disk moved, the partition was resized, or `grub-install` was never
run after a change.

You are still at stage 2, which is good news: the firmware found something. Boot
rescue media, mount the root filesystem, `chroot` into it, and re-run
`grub2-install` plus `grub2-mkconfig`.

No menu at all and no GRUB message means stage 1 failed. The firmware did not
find a bootloader. Check the boot order with `efibootmgr`, and check the
machine is not set to boot from a disk you removed.

### 2. Dropped into an initramfs emergency shell

A prompt that says `dracut:/#` or `(initramfs)` means stage 4 is running and could
not find or mount the real root.

Almost always one of: the root device UUID changed and `/etc/fstab` or the kernel
command line still names the old one; the initramfs is missing a driver for a
storage layout that changed; or the filesystem needs a check it cannot do
automatically.

`cat /proc/cmdline` to see what root it was told to find, then `blkid` to see what
is actually there. The two disagreeing is the answer most of the time.

### 3. Changing the storage layout without rebuilding the initramfs

You add a RAID array, move root onto LVM, or enable encryption. Everything works
perfectly until the reboot, and then stage 4 cannot assemble the thing you built.

The initramfs was built before the change and does not contain the tools.
Rebuild it, `dracut -f` or `update-initramfs -u`, *before* rebooting.

### 4. Editing grub.cfg directly

It works, and it is overwritten by the next kernel update, which is a delightful
way to have a machine boot correctly for three weeks and then not.

Edit `/etc/default/grub`, then regenerate.

### 5. Confusing the initramfs with /boot

They are related and not the same. `/boot` is a directory on a real filesystem
holding the kernel and the initramfs *file*. The initramfs is an archive that
gets unpacked into memory. A full `/boot` prevents a new initramfs being written;
a broken initramfs prevents the real root being mounted. Different failures,
different fixes.

## Work it through

A server was working. Somebody moved the root filesystem onto a new LVM volume,
copied the data across, updated `/etc/fstab`, verified the mount, and rebooted.

It now stops at a prompt reading `dracut:/#`.

Reason it out before reading on.

**Which stage are we in?** The prompt names it: dracut builds the initramfs,
so this is the initramfs emergency shell. That means stages 1, 2, and 3 all
succeeded, the firmware found the bootloader, the bootloader loaded the
kernel, the kernel started and mounted the initramfs. We are at stage 4.

What does stage 4 do? It loads the drivers needed to reach the real root, then
mounts it. It has failed at one of those two.

Why would it fail here specifically? Because root moved onto LVM. Activating
an LVM volume needs the LVM tools and the device-mapper module, and the
initramfs on this machine was built when root was a plain partition, so it
contains neither. The kernel is fine, the volume is fine, the fstab is fine.
The thing that has to assemble the volume before any of that matters does not
know how.

Was `/etc/fstab` the problem? No, and this is the part worth slowing down on.
`/etc/fstab` lives on the root filesystem. Nothing has read it, because
reading it requires mounting the filesystem it is on. It gets consulted at
stage 5, and we never got there.

**The fix.** From the dracut shell, or better from rescue media: activate the
volume group by hand (`lvm vgchange -ay`), mount the real root, `chroot` into it,
and rebuild the initramfs with `dracut -f`. Then reboot.

**The habit.** Rebuild the initramfs as part of any change to the storage
underneath root, in the same maintenance window, before the reboot that proves
it. The rule generalises: **anything the machine needs to reach its own root
filesystem has to be in the initramfs, because at that moment nothing else is
available.**

## Try it

Optional, and best on a virtual machine you can break.

1. `systemd-analyze` and `systemd-analyze blame`. Say which of the three phases
   dominates and what the slowest unit is.
2. `cat /proc/cmdline`. Identify the root device and whether `quiet` is set.
3. Reboot, press `e` at the GRUB menu, remove `quiet`, and boot with Ctrl+X.
   Watch the kernel messages. Nothing was saved, so the next boot is unchanged.
4. `ls /boot`. Find the `vmlinuz-` and `initramfs-` (or `initrd.img-`) pair, and
   note there is one of each per installed kernel.
5. `systemctl get-default`, then `systemctl list-units --type=target --state=active`.
6. If the machine is UEFI, `sudo efibootmgr -v` and read the boot order.

**Verification step.** You have it when you can look at a stuck boot and name the
stage from the symptom alone, before touching anything.

## Check yourself

<details class="qa">
<summary>Name the five stages in order, and say what each one hands to the next.</summary>

**Firmware** tests the hardware and finds a bootloader, from the EFI System
Partition under UEFI, or the MBR under legacy BIOS.

**Bootloader** (GRUB) reads its config, shows a menu, and loads two files from
`/boot` into memory: the kernel and the initramfs. It also hands the kernel its
command line.

**Kernel** takes over the hardware and mounts the initramfs as a temporary root,
because it cannot reach the real one yet.

**initramfs** loads the drivers for the real root (disk, RAID, LVM,
encryption) mounts it, switches to it, and is discarded.

**systemd** starts as PID 1 and brings the machine to its default target.

The handover is what makes boot failures diagnosable: whatever you saw last tells
you which stage was still alive.

</details>

<details class="qa">
<summary>Why does an initramfs exist at all? Answer with the specific problem it solves.</summary>

**The drivers needed to read the root filesystem are files on the root
filesystem.** The kernel cannot load them from a disk it cannot yet read.

The initramfs breaks the circle by arriving in memory alongside the kernel,
loaded by the bootloader from `/boot`. It contains exactly the modules and tools
this machine needs to reach its own root: the disk controller driver, plus
whatever assembles RAID, activates LVM, or unlocks encryption.

Once the real root is mounted, the system switches to it and the initramfs is
thrown away.

The operational consequence: it is built for this machine's storage layout, so
changing that layout without rebuilding it produces a machine that will not boot.

</details>

<details class="qa">
<summary>A machine stops at <code>dracut:/#</code>. Which stages are known good, and what are the two likeliest causes?</summary>

**Stages 1 through 3 are known good.** The firmware found a bootloader, GRUB
loaded a kernel, and the kernel started and mounted the initramfs. You are
looking at a shell that only exists because stage 4 got far enough to run.

The two likeliest causes:

**The root device it was told to find is not there**, a UUID changed after a
reinstall, a restore, or a disk swap, and the kernel command line still names
the old one. `cat /proc/cmdline` against `blkid` settles it in seconds.

**The initramfs lacks a driver for the storage layout**, root moved onto LVM,
RAID, or an encrypted volume and the image was never rebuilt.

Note what is *not* a candidate: anything in `/etc/fstab` or any service, because
neither has been read. `/etc/fstab` lives on the filesystem that has not been
mounted.

</details>

<details class="qa">
<summary>Why does <code>init=/bin/bash</code> get you a root shell with no password, and what defends against it?</summary>

`init=` tells the kernel which program to run as PID 1 once the real root is
mounted. Normally that is systemd, which starts the services that provide login
and authentication. Replace it with a shell and **none of those services ever
start**, so there is nothing to authenticate against.

You get a root shell because PID 1 has always run as root; no privilege was
escalated, you simply chose a different first program.

Three defences, in increasing strength: a **GRUB password** stops the menu being
edited; **full-disk encryption** means the root filesystem cannot be mounted at
all without the passphrase; **physical security** covers the case where somebody
removes the disk entirely.

This is why "physical access is root access" is the usual shorthand, and why an
unencrypted laptop is a data-loss incident rather than a hardware loss.

</details>

<details class="qa">
<summary><code>systemd-analyze</code> reports 400ms kernel, 22s initrd, 3s userspace. Where is the problem and where is it not?</summary>

**The initramfs phase**, at 22 seconds out of 25. The kernel and userspace are
both normal.

That points at stage 4 waiting for something: a device that is slow to appear,
a RAID array being assembled, a network mount attempted before the network is
ready, or, very commonly, a device named in the boot configuration that does
not exist, where the delay is a timeout expiring rather than work being done.

Where it is *not*: any service you might be suspicious of. Services start in
userspace, and userspace took 3 seconds. `systemd-analyze blame` would confirm by
showing nothing in userspace taking meaningful time.

The three numbers are worth reading before anything else, because they turn "the
boot is slow" into one of three much smaller questions.

</details>

## References

- [boot(7)](https://man7.org/linux/man-pages/man7/boot.7.html) - Linux man-pages project. Accessed 2026-08-07.
- [bootup(7)](https://man7.org/linux/man-pages/man7/bootup.7.html) - Linux man-pages project. Accessed 2026-08-07.
- [The kernel's command-line parameters](https://docs.kernel.org/admin-guide/kernel-parameters.html) - The Linux Kernel documentation. Accessed 2026-08-07.
- [GNU GRUB Manual](https://www.gnu.org/software/grub/manual/grub/grub.html) - GNU Project. Accessed 2026-08-07.
- [dracut(8)](https://man7.org/linux/man-pages/man8/dracut.8.html) - Linux man-pages project. Accessed 2026-08-07.
- [efibootmgr(8)](https://manpages.debian.org/stable/efibootmgr/efibootmgr.8.en.html) - Debian Project. Accessed 2026-08-07.

Every block above with a distribution and architecture header was captured by running the command on a Fedora CoreOS 44.20260707.3.1 virtual machine. Blocks without one are illustrative.
