---
title: "The machine powers on and never reaches a login prompt"
description: "Boot is a chain, and a failure anywhere in it leaves you with a different set of tools. Working out how far it got, editing the kernel command line from the boot menu, and getting a shell on a system that will not start one."
track: "linux-plus"
level: "deep"
order: 670
objectives:
  - "Say how far a boot got from what is on the screen"
  - "Read the kernel command line and explain what it must contain"
  - "Reach rescue and emergency targets, and know what each provides"
  - "Recover a system whose fstab or root device is wrong"
  - "Explain what chroot from live media gives you and why it is needed"
prerequisites: ["how-linux-boots", "filesystem-and-mount-failures"]
tags: ["linux", "linux-plus", "troubleshooting", "boot", "grub", "systemd"]
updated: 2026-08-09
draft: false
examObjectives:
  - exam: "xk0-006"
    domain: "5.0"
    objective: "5.2"
sources:
  - title: "systemd.special(7), rescue and emergency targets"
    url: "https://www.freedesktop.org/software/systemd/man/latest/systemd.special.html"
    publisher: "freedesktop.org"
    accessed: 2026-08-09
    tier: 1
  - title: "systemd-analyze(1)"
    url: "https://www.freedesktop.org/software/systemd/man/latest/systemd-analyze.html"
    publisher: "freedesktop.org"
    accessed: 2026-08-09
    tier: 1
  - title: "GNU GRUB manual"
    url: "https://www.gnu.org/software/grub/manual/grub/grub.html"
    publisher: "GNU"
    accessed: 2026-08-09
    tier: 1
  - title: "dracut(8)"
    url: "https://man7.org/linux/man-pages/man8/dracut.8.html"
    publisher: "man7.org"
    accessed: 2026-08-09
    tier: 1
  - title: "The kernel's command-line parameters"
    url: "https://docs.kernel.org/admin-guide/kernel-parameters.html"
    publisher: "kernel.org"
    accessed: 2026-08-09
    tier: 1
symptoms:
  - symptom: "Boot stops at an emergency shell asking for the root password"
    anchor: "rescue-and-emergency"
  - symptom: "System reached its target but reports degraded"
    anchor: "degraded-means-it-arrived-with-casualties"
  - symptom: "Kernel panic saying it cannot mount the root filesystem"
    anchor: "the-kernel-command-line"
---

> **Before you read.** The machine was rebooted for a routine kernel update. It
> has not come back. The console shows a wall of text, ending in a prompt that
> is not a login prompt, and it wants a root password you may not have.
>
> Everything you normally use to investigate a Linux machine assumes the
> machine booted.

Boot failures feel worse than other faults because your tools are gone with the
system. There is no SSH, no journal you can query from a comfortable terminal,
and frequently no shell.

The good news is that boot is a strict sequence, so the screen tells you roughly
where it stopped, and where it stopped narrows the cause sharply. Lesson 09
described that sequence working. This is the same ground when it does not.

### Some words you will need

<dl class="terms">
<dt>firmware</dt>
<dd>UEFI or BIOS. Runs before anything of yours, and picks what to load.</dd>
<dt>bootloader</dt>
<dd>GRUB on most systems. Loads a kernel and hands it parameters.</dd>
<dt>initramfs</dt>
<dd>A small temporary root filesystem holding the drivers needed to find the real one.</dd>
<dt>kernel command line</dt>
<dd>Parameters the bootloader passes. Includes which device holds the root filesystem.</dd>
<dt>target</dt>
<dd>A systemd state to reach. <code>multi-user.target</code> is a normal server.</dd>
<dt>rescue</dt>
<dd>Single user with the local filesystems mounted.</dd>
<dt>emergency</dt>
<dd>A shell with almost nothing started and root mounted read-only.</dd>
<dt>chroot</dt>
<dd>Running commands with a different directory as the root, so tools act on the broken system.</dd>
</dl>

## What breaks without this

**A production machine stays down** while somebody works out how to get a
prompt.

**The rebuild is chosen over the repair.** Reinstalling is a way to avoid
diagnosis, and it destroys whatever local state had not been backed up.

**The recovery makes it worse.** Reinstalling a bootloader from the wrong root
or against the wrong disk is a common way to lose the other operating system on
the machine.

**Nobody knows where the console is.** The fix takes two minutes and access to
it takes two hours.

## How far did it get?

Work out which stage failed before touching anything, because each stage has
different tools.

| Screen shows | Stopped at | Suggests |
| --- | --- | --- |
| Nothing, no firmware logo | Firmware or hardware | Power, RAM, the display itself |
| Firmware screen, then nothing | Bootloader not found | Boot order, a wiped bootloader, a failed disk |
| `grub>` or `grub rescue>` | GRUB loaded, cannot find its configuration | Renamed or missing `/boot`, a broken `grub.cfg` |
| GRUB menu, then a panic | Kernel or initramfs | Wrong root device, missing driver, corrupt initramfs |
| Kernel messages, then a dracut prompt | initramfs could not find root | The root device is not where the command line says |
| Systemd messages, then an emergency shell | A unit or a mount failed | Usually `fstab`, per lesson 67 |
| Login prompt but services missing | Booted, with failures | `systemctl --failed` |

**The most useful distinction is whether you got a GRUB menu.** Before it, the
problem is firmware, disk, or bootloader. After it, the kernel is running and
you have parameters you can edit, which is a much better position.

## The kernel command line

Everything after GRUB depends on the parameters it passed. This is what a
healthy one looks like:

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ echo "--- what the kernel was told at boot ---"; cat /proc/cmdline; echo "--- where the system is trying to get to, and where it is ---"; systemctl get-default; systemctl is-system-running
--- what the kernel was told at boot ---
BOOT_IMAGE=(hd0,gpt3)/boot/ostree/fedora-coreos-b03a2111206afe90841d87f839937afc8dce4e7fa9e11e5ac0c314f03439c33f/vmlinuz-7.1.3-200.fc44.aarch64 rw ostree.prepare-root.composefs=0 ostree=/ostree/boot.1/fedora-coreos/b03a2111206afe90841d87f839937afc8dce4e7fa9e11e5ac0c314f03439c33f/0 ignition.platform.id=applehv console=tty0 console=hvc0 root=UUID=159ca8aa-2ced-4891-90cc-0bde469c40f8 rw rootflags=prjquota boot=UUID=ec4a7bbc-82cf-4c92-a421-381dd40c0e0c
--- where the system is trying to get to, and where it is ---
multi-user.target
degraded
```

That line is long because this is an ostree system, and most of it is
distribution machinery. The parts that matter on any system are the same three:

- **`BOOT_IMAGE=`** which kernel was loaded, and from which partition.
- **`root=UUID=159ca8aa-...`** where the root filesystem is. **This is the
  parameter that causes the most boot failures**, because a UUID that no longer
  exists produces a kernel that boots perfectly and then has nowhere to go.
- **`console=tty0 console=hvc0`** where kernel messages are sent. Worth knowing
  when the screen is blank but the machine seems alive: the messages may be
  going to a serial console you are not watching.

**Editing it from the boot menu is the single most valuable recovery skill**,
and it requires no media and no preparation:

1. At the GRUB menu, highlight the entry and press `e`.
2. Find the line beginning `linux` or `linuxefi`.
3. Edit it. Append `systemd.unit=rescue.target`, or `single`, or `init=/bin/bash`.
4. `Ctrl-X` or `F10` to boot with the change.

Nothing is saved. A reboot restores the original entry, which makes this safe to
experiment with.

**What to append, and what each gives you:**

| Parameter | Effect |
| --- | --- |
| `systemd.unit=rescue.target` | Single user, local filesystems mounted, root password required |
| `systemd.unit=emergency.target` | Minimal shell, root read-only, nothing else started |
| `init=/bin/bash` | **Skips systemd entirely.** No password prompt. Root is read-only |
| `rd.break` | A shell inside the initramfs, before the real root is used |
| `nomodeset` | Skip the graphics driver, for a machine that boots blind |
| `systemd.mask=<unit>` | Boot without one unit that is hanging |

**`init=/bin/bash` is the one to remember for a lost root password**, since it
bypasses the password prompt that rescue mode would give you. Root is mounted
read-only, so `mount -o remount,rw /` comes first, and on a system with SELinux
a password change needs `touch /.autorelabel` before rebooting or the next boot
fails for a different reason.

<details class="deeper">
<summary>If you already administer Linux: the initramfs, and the failures that live inside it</summary>

The gap between the kernel starting and the real root filesystem being available
is filled by the initramfs, and a surprising number of boot failures happen
inside it.

**Why it exists:** the kernel needs a driver to read the disk holding root, and
that driver is on the disk. The initramfs breaks the circle by shipping the
necessary modules in a small archive the bootloader loads into memory alongside
the kernel.

**Which means it must contain the right modules for this machine.** Change the
storage controller, move a disk image to a different hypervisor, add LVM or
LUKS under root, and an initramfs built for the old configuration cannot find
the new one. The symptom is a dracut timeout and a shell, usually after a
90-second wait with a message about a device not appearing.

**Inspect one without rebooting:**

```bash
lsinitrd /boot/initramfs-$(uname -r).img | head -40    # contents
lsinitrd /boot/initramfs-$(uname -r).img | grep -iE 'virtio|nvme|megaraid'
```

**Rebuild it when the answer is that something is missing:**

```bash
sudo dracut -f                                  # current kernel, in place
sudo dracut -f --kver 6.1.0-30                  # a specific kernel
sudo dracut -f --add-drivers "virtio_blk virtio_scsi"
sudo dracut -f --regenerate-all                 # every installed kernel
```

**`rd.break` is the tool for looking around inside it.** It drops to a shell
before the real root is used, where the actual root is mounted at `/sysroot`.
That is the standard place to repair an unbootable root:

```bash
mount -o remount,rw /sysroot
chroot /sysroot
# fix the problem
exit
mount -o remount,ro /sysroot
exit
```

**Two adjacent parameters worth knowing.** `rd.debug` makes the initramfs
extremely verbose, which is how you see which step is hanging. `rd.timeout=` and
`rd.retry=` control how long it waits for devices, and raising them is the right
answer for slow storage rather than for genuinely absent storage.

**And the ordering trap that catches people during kernel updates:** the
bootloader configuration, the kernel, and the initramfs must agree. Removing an
old kernel package while an entry still points at it, or generating an initramfs
for the wrong kernel version, produces a menu entry that cannot boot. Keep at
least one known-good kernel installed, and boot the new one once before removing
anything, which is the whole argument for GRUB keeping several entries.

</details>

## Rescue and emergency

Both give you a shell on a system that will not boot normally, and the
difference is how much has been started.

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ echo "--- the targets that exist for recovery ---"; systemctl list-units --type=target --all --no-pager 2>/dev/null | grep -E "rescue|emergency|multi-user|graphical" | head -5
--- the targets that exist for recovery ---
  emergency.target                   loaded    inactive dead   Emergency Mode
  multi-user.target                  loaded    active   active Multi-User System
  rescue.target                      loaded    inactive dead   Rescue Mode
```

**Rescue** mounts the local filesystems and starts a minimal set of services,
so the system is broadly usable and single user. Reach for it when the machine
mostly works and one service or one configuration file is the problem.

**Emergency** starts almost nothing. Root is mounted read-only, other
filesystems are not mounted at all, and there is no networking. It is the right
choice when the filesystems themselves are suspect, because it touches as little
as possible.

**Both prompt for the root password**, which is the practical catch. A system
with no root password set, which is increasingly common on cloud images, cannot
offer either, and `init=/bin/bash` is the way in.

You can also reach them from a running system, which is worth knowing for
maintenance rather than recovery:

```bash
sudo systemctl rescue          # drop to rescue now
sudo systemctl emergency       # drop to emergency now
sudo systemctl default         # back to normal
```

<details class="deeper">
<summary>If you already administer Linux: the boot you cannot watch, and preparing before you need to</summary>

Most of this lesson assumes a console. On a remote server, in a datacentre, or
on a cloud instance, getting one is the hard part, and it is worth solving on a
quiet afternoon rather than during an outage.

**Know where your console is, by platform:**

| Platform | Console |
| --- | --- |
| Cloud provider | Serial console, and a screenshot of the display. Both in the web console or the CLI |
| Physical server | IPMI, iDRAC, iLO, or a KVM over IP |
| Local hypervisor | `virsh console`, or the GUI's display |
| Container host | Not applicable. A container that will not start is lesson 61 |

**Then make the boot visible on it.** A machine that logs to a screen nobody can
see is as opaque as one that logs nothing:

```bash
console=tty0 console=ttyS0,115200n8       # kernel command line: both screen and serial
```

The last `console=` receives the interactive prompt, which is the detail that
matters. With the pair above, kernel messages go to both and the rescue shell
appears on the serial port, which is what you want for a headless machine.

`grubby --update-kernel=ALL --args="console=ttyS0,115200n8"` applies that
persistently on the RHEL family.

**Two more preparations that pay for themselves:**

**Keep a known-good kernel and boot it once.** GRUB keeps several entries for
exactly this reason. After a kernel update, the previous entry is your rollback,
and `grub2-set-default` or the `saved_entry` mechanism decides which is tried
first. Removing old kernels aggressively to save space in `/boot` removes the
rollback with them.

**Set a root password on machines you might need to rescue**, or accept that
`init=/bin/bash` is the only route in. Cloud images ship without one
deliberately, which is fine until the day the instance will not boot and the
serial console offers you a password prompt you cannot satisfy.

**And on the specific question of a machine that is up but unreachable**, which
looks like a boot failure from your desk and is not: check the console before
assuming the worst. A booted machine with a broken network configuration shows a
normal login prompt on the console, and that single observation separates lesson
71's territory from this one in about ten seconds.

**One thing worth doing after any recovery.** Boot it again, deliberately, while
you are still there and still paying attention. A system repaired into a running
state is not the same as a system that boots, and discovering the difference at
the next unplanned reboot is how a two-hour incident becomes two incidents.

</details>

## Degraded means it arrived with casualties

A boot can succeed and still be wrong, and systemd has a specific word for it.
Look again at the first capture: `systemctl is-system-running` reported
`degraded`, not `running`.

That means the machine reached `multi-user.target` and something failed on the
way. It is easy to miss, because a degraded system gives you a login prompt and
looks fine.

<details class="predict">
<summary>The system reports <code>degraded</code>. Which command names what actually failed, and how much does it tell you?</summary>

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ echo "--- degraded means it got there with casualties. which ones ---"; systemctl --failed --no-pager
--- degraded means it got there with casualties. which ones ---
  UNIT                LOAD   ACTIVE SUB    DESCRIPTION
● rpm-ostreed.service loaded failed failed rpm-ostree System Management Daemon

Legend: LOAD   → Reflects whether the unit definition was properly loaded.
        ACTIVE → The high-level unit activation state, i.e. generalization of SUB.
        SUB    → The low-level unit activation state, values depend on unit type.

1 loaded units listed.
```

</details>

One unit, named, with its load and active states. From here it is lesson 69's
territory: `systemctl status rpm-ostreed.service` and the journal for that unit.

**Make `is-system-running` a habit after any reboot.** It returns `running`,
`degraded`, `maintenance`, or `starting`, and it is a single word that tells you
whether to look further. A monitoring check on it costs nothing and catches the
service that quietly failed to start three reboots ago.

Boot timing is worth the same glance, because a boot that succeeds slowly is
usually a boot that timed out waiting for something:

<details class="predict">
<summary>A boot is timed. It reports three separate figures rather than one. What are they, and why does splitting them matter?</summary>

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ echo "--- how long the last boot took, and which units were slowest ---"; systemd-analyze; systemd-analyze blame --no-pager 2>/dev/null | head -5
--- how long the last boot took, and which units were slowest ---
Startup finished in 316ms (kernel) + 2.108s (initrd) + 3.179s (userspace) = 5.604s 
multi-user.target reached after 3.086s in userspace.
2.210s dev-hvc4.device
2.210s sys-devices-virtual-tty-hvc4.device
2.208s sys-devices-virtual-tty-hvc1.device
2.208s dev-hvc1.device
2.208s dev-hvc0.device
```

</details>

Three phases, separately timed: 316 ms in the kernel, 2.1 seconds in the
initramfs, 3.2 seconds in userspace. That split localises a slow boot
immediately, because a long initrd phase and a long userspace phase have nothing
in common.

**`blame` sorts units by how long each took**, and it is frequently
misinterpreted. A unit at the top of the list is not necessarily delaying the
boot: it may have started early and run alongside everything else.
`systemd-analyze critical-chain` shows the dependency path that actually
determined the total, which is the one to act on.

**A unit taking a suspiciously round number**, 90 seconds especially, is almost
always a timeout rather than work. 90 seconds is systemd's default device
timeout, so it usually means something waited for a device that never appeared,
which brings you back to `fstab` and lesson 67's `nofail`.

<details class="deeper">
<summary>If you already administer Linux: chroot from live media, and reinstalling a bootloader without breaking the machine</summary>

When the system cannot boot far enough to give you any shell, the answer is to
boot something else and work on the installation from outside.

**The sequence, and every step matters:**

```bash
# 1. identify the partitions
lsblk -f

# 2. mount the real root somewhere
sudo mount /dev/sda2 /mnt

# 3. mount the other filesystems the system expects
sudo mount /dev/sda1 /mnt/boot
sudo mount /dev/sda1 /mnt/boot/efi        # if EFI is separate

# 4. give the chroot the kernel interfaces it needs
for d in dev proc sys run; do sudo mount --bind /$d /mnt/$d; done

# 5. enter it
sudo chroot /mnt /bin/bash
```

**Step 4 is the one people skip and it is not optional.** Without `/proc`,
`/sys`, and `/dev`, tools inside the chroot cannot see devices or kernel state,
so `grub2-install` writes nonsense, `dracut` builds an initramfs for the wrong
hardware, and `systemctl` does not work at all. If a recovery inside a chroot
behaves strangely, this is nearly always why.

Modern systemd has a shortcut that does the binds for you:

```bash
sudo systemd-nspawn -D /mnt              # a container-like chroot, binds handled
```

**Once inside**, the repairs are ordinary commands acting on the broken system
rather than on the live media:

```bash
grub2-mkconfig -o /boot/grub2/grub.cfg          # regenerate the menu
grub2-install /dev/sda                          # BIOS: write to the disk's MBR
dnf reinstall grub2-efi shim                    # UEFI: replace the EFI binaries
dracut -f --regenerate-all                      # rebuild every initramfs
passwd root                                     # reset a lost password
vi /etc/fstab                                   # fix the entry that stranded it
touch /.autorelabel                             # if SELinux is enforcing
```

**Two mistakes worth naming, because both make things worse:**

**Installing GRUB to the wrong disk.** `grub2-install /dev/sda` writes to the
disk you named, not the one you booted. On a multi-disk machine, or a machine
that dual boots, that can leave the system unbootable in a new way. Check
`lsblk` and be certain which disk holds `/boot`.

**Confusing BIOS and UEFI recovery.** On a UEFI system there is nothing useful
to install to the MBR, and `grub2-install` on the block device is not the fix.
The EFI system partition holds the bootloader, and `efibootmgr` manages the
firmware's list of entries:

```bash
efibootmgr -v                             # what the firmware will try, in order
efibootmgr -o 0003,0001                   # change the order
```

A machine whose EFI entry was deleted, which some firmware updates do, has a
perfectly good bootloader on disk that the firmware no longer knows about.
`efibootmgr -c` recreates the entry, and that is a two-minute fix that people
spend an afternoon reinstalling around.

**And the general principle for all of it:** work out which stage failed before
running any recovery command. The tools in this panel are capable of turning a
single broken `fstab` line into a system with no bootloader, and the only
protection is knowing what you are fixing.

</details>

## For the exam

**Where it stops tells you the stage.** No GRUB menu means firmware, disk, or
bootloader. A menu means the kernel can run and you can edit its parameters.

**`e` at the GRUB menu edits an entry for one boot only.**

**`root=UUID=` on the kernel command line says where the root filesystem is**,
and a stale UUID is a common cause of a kernel panic on mount.

**`systemd.unit=rescue.target` is single user with filesystems mounted;
`emergency.target` starts almost nothing and mounts root read-only.**

**Both ask for the root password. `init=/bin/bash` does not**, which is the
route in when no root password exists.

**`rd.break` gives a shell in the initramfs**, with the real root at `/sysroot`.

**Rebuild an initramfs with `dracut -f`** after changing storage hardware or
adding LVM or LUKS under root.

**`degraded` means the target was reached with failures.** `systemctl --failed`
names them.

**`systemd-analyze` splits boot into kernel, initrd, and userspace.** A 90
second unit is a timeout, not work.

**A chroot needs `/dev`, `/proc`, `/sys`, and `/run` bind mounted** or the tools
inside it will misbehave.

**On UEFI, the bootloader lives on the EFI system partition** and `efibootmgr`
manages the firmware's entries.

<details class="qa">
<summary>Check yourself</summary>

**The firmware screen appears and then nothing. Which stage failed?**
The bootloader was not found or could not load. Boot order, a wiped bootloader,
or a failed disk. You never reached the kernel.

**You get a GRUB menu and then a panic about mounting root. What do you
suspect?**
The `root=` parameter, or an initramfs without the driver for that storage. A
UUID that no longer exists is the classic cause after a restore or a disk swap.

**How do you boot once with different kernel parameters, without saving them?**
Press `e` at the GRUB menu, edit the `linux` line, and boot with `Ctrl-X`. The
change lasts for that boot only.

**Rescue against emergency?**
Rescue mounts local filesystems and starts a minimal set of services. Emergency
starts almost nothing and mounts root read-only. Emergency is right when the
filesystems are suspect.

**The machine has no root password, so rescue mode cannot let you in. What
now?**
Boot with `init=/bin/bash`, which skips systemd and the password prompt. Root
is read-only, so remount it read-write first.

**You reset the root password on an SELinux system and the next boot fails.
Why?**
The new `/etc/shadow` has the wrong label. `touch /.autorelabel` before
rebooting relabels the filesystem on the next boot.

**What does `rd.break` give you, and where is the real root?**
A shell inside the initramfs before the real root is used. It is mounted at
`/sysroot`.

**When must you rebuild the initramfs?**
After changing storage hardware or hypervisor, or after putting LVM, RAID, or
LUKS under root. `dracut -f`.

**`systemctl is-system-running` says `degraded`. What does that mean?**
The system reached its target but at least one unit failed. `systemctl --failed`
names them. It still gives you a login prompt, which is why it goes unnoticed.

**A unit takes exactly 90 seconds in `systemd-analyze blame`. What does that
suggest?**
A timeout rather than work. 90 seconds is the default device timeout, so
something waited for a device that never appeared. Check `fstab` and consider
`nofail`.

**Why is `blame` a poor guide to what made the boot slow?**
It sorts by duration, and a slow unit may have run in parallel with everything
else. `systemd-analyze critical-chain` shows the path that actually determined
the total.

**Which four filesystems must be bind mounted before you chroot, and why?**
`/dev`, `/proc`, `/sys`, and `/run`. Without them the tools inside cannot see
devices or kernel state, so bootloader and initramfs commands produce wrong
results.

**On a UEFI machine, is `grub2-install /dev/sda` the right repair?**
No. The bootloader lives on the EFI system partition. Reinstall the EFI packages
and check the firmware entries with `efibootmgr`.

**A firmware update removed the boot entry. Is the disk damaged?**
No. The bootloader is still there and the firmware no longer lists it.
`efibootmgr -c` recreates the entry.

</details>

## Where this sits

Lesson 09 walked the boot sequence when it works. This lesson is the same
sequence when it does not, and the stage that failed decides which tool applies.
Lesson 67 owns the filesystem and `fstab` problems that produce most emergency
shells, and lesson 69 takes over once you have a prompt and a failed unit.

That completes block F, and with it the material for all five domains.

> **The commands here were run on a real machine, not written from memory.** The
> transcripts come from Fedora CoreOS 44.20260707.3.1 on aarch64. The kernel
> command line is long because that is an ostree system, and it is shown as it
> actually is rather than trimmed to look tidy. The `degraded` state is genuine:
> that machine really did have `rpm-ostreed.service` failed at the time of
> capture, which is exactly the situation the section describes, and it had been
> giving a normal login prompt throughout.
