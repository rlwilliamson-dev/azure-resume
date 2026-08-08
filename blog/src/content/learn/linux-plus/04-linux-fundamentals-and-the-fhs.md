---
title: "Linux fundamentals and the filesystem hierarchy"
description: "Where files actually live and why, what the usr-merge changed underneath you, and how to tell which distribution family you are on before you type a command that only works on half of them."
track: "linux-plus"
level: "intro"
order: 50
objectives:
  - "Name the purpose of each top-level directory and predict where a given file belongs"
  - "Explain what the usr-merge changed and which tools still behave as if it did not happen"
  - "Identify a distribution and its family from the system itself rather than from memory"
  - "Choose the right package query command for the family you are actually on"
prerequisites: []
tags: ["linux", "linux-plus", "fhs", "distributions"]
updated: 2026-08-07
draft: false
examObjectives:
  - exam: "xk0-006"
    domain: "1.0"
    objective: "1.1"
sources:
  - title: "Filesystem Hierarchy Standard, version 3.0"
    url: "https://refspecs.linuxfoundation.org/FHS_3.0/fhs/index.html"
    publisher: "Linux Foundation"
    accessed: 2026-08-07
    tier: 1
  - title: "hier(7): description of the filesystem hierarchy"
    url: "https://man7.org/linux/man-pages/man7/hier.7.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "file-hierarchy(7): systemd's file system hierarchy overview"
    url: "https://man7.org/linux/man-pages/man7/file-hierarchy.7.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "os-release(5)"
    url: "https://man7.org/linux/man-pages/man5/os-release.5.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "UsrMerge"
    url: "https://wiki.debian.org/UsrMerge"
    publisher: "Debian Wiki"
    accessed: 2026-08-07
    tier: 1
  - title: "Features/UsrMove"
    url: "https://fedoraproject.org/wiki/Features/UsrMove"
    publisher: "Fedora Project"
    accessed: 2026-08-07
    tier: 1
  - title: "dpkg-query(1)"
    url: "https://man7.org/linux/man-pages/man1/dpkg-query.1.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "rpm(8)"
    url: "https://man7.org/linux/man-pages/man8/rpm.8.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "What is Copyleft?"
    url: "https://www.gnu.org/licenses/copyleft.en.html"
    publisher: "GNU Project"
    accessed: 2026-08-07
    tier: 1
  - title: "Wayland Architecture"
    url: "https://wayland.freedesktop.org/architecture.html"
    publisher: "freedesktop.org"
    accessed: 2026-08-07
    tier: 1
symptoms:
  - symptom: "dpkg-query: no path found matching pattern /bin/ls"
    anchor: "1-dpkg--s-and-rpm--qf-disagree-about-binls"
  - symptom: "A script works on RHEL and fails on Debian with the same command spelled the same way"
    anchor: "telling-the-families-apart-from-the-system-itself"
---

> **Before you read.** A Linux machine has run out of disk space. You have not
> installed anything new and you have not saved any files. Something has been
> quietly filling the disk on its own for months. Which one directory would you
> look in first, and what kind of thing would you expect to find there?
>
> You are not expected to know the answer yet. Have a guess anyway.

On Windows your programs live in `C:\Program Files` and your documents live in
`C:\Users\you\Documents`. Somebody decided that once, and now everybody follows
it. Linux has the same kind of agreement, written down as a standard, and it is
what this topic is about.

Here is why it is worth an hour rather than a glance. On Windows the folder
names are mostly labels. In Linux they encode **decisions**: what is safe to
share between machines, what can be locked read-only, and what is deliberately
thrown away every time the machine restarts. Once you can see the decisions, you
can work out where a file belongs rather than memorising twenty folder names.

### Some words you will need

<dl class="terms">
<dt>directory</dt>
<dd>A folder. Linux documentation says directory, so this track does too.</dd>
<dt>path</dt>
<dd>The address of a file, written with forward slashes: <code>/etc/hosts</code>. Linux uses <code>/</code> where Windows uses <code>\</code>.</dd>
<dt>root directory</dt>
<dd>The very top, written as a single <code>/</code>. Everything on the system hangs underneath it. There are no drive letters; a second disk appears as a directory somewhere under <code>/</code> rather than as <code>D:</code>.</dd>
<dt>distribution</dt>
<dd>A packaged version of Linux, such as Ubuntu, Debian, or Red Hat Enterprise Linux. Often shortened to "distro". They share almost everything and differ in specific, testable ways.</dd>
<dt>package</dt>
<dd>Installable software, roughly the equivalent of an installer on Windows. The program that installs them is a package manager.</dd>
</dl>

## What breaks without this

Three failures, all cheap to avoid and expensive to debug.

**You put a file somewhere that gets wiped.** You need to save something, you
find a directory you are allowed to write to, and you use it. If that directory
was `/run` or `/tmp`, the system deletes the contents on reboot. On purpose.
Your file works fine for a week, someone restarts the machine, and it is gone
with no error and nothing in a log.

**You write instructions that only work on half of Linux.** The command to
install software on Ubuntu is not the command to install software on Red Hat.
Neither are some of the paths around it. A script you tested on one machine
fails on another, and the error message names a missing program rather than the
assumption you made.

**You trust a command that quietly gives the wrong answer.** There is one
further down this page that does exactly that, and it catches people with years
of experience, because the command is correct and the answer is still wrong.

## The mental model

Start with one directory rather than the whole tree.

Say you install a web server. Its program file has to go somewhere, its settings
file has to go somewhere, and the log it writes has to go somewhere. Three files,
three different kinds of thing:

- **The program** is identical on every machine that installed the same version.
  Nobody edits it. It gets replaced when you upgrade.
- **The settings** are specific to this machine, and you *do* edit them. Change
  the settings and you change what this server does.
- **The log** grows on its own, forever, without anybody touching it.

Linux puts those in three different places for that reason: the program in
`/usr`, the settings in `/etc`, the log in `/var`. Not by tradition. Because
they behave differently.

Generalise that and you have the whole standard. Every directory sits somewhere
on two questions: does the content **change by itself while the machine runs**,
and is it **the same on every machine** or specific to this one?

<figure class="learn-figure">
<svg viewBox="0 0 720 300" role="img" aria-labelledby="fhs-axes-title fhs-axes-desc" style="width:100%;height:auto;">
  <title id="fhs-axes-title">The two axes the filesystem hierarchy sorts directories along</title>
  <desc id="fhs-axes-desc">A two by two grid. Static and shareable holds /usr. Static and local holds /etc and /boot. Variable and shareable holds /var/mail and /home. Variable and local holds /var/log, /var/run and /tmp.</desc>
  <g fill="none" stroke="currentColor" stroke-opacity="0.25" stroke-width="1">
    <rect x="150" y="40" width="520" height="220" rx="4"/>
    <line x1="410" y1="40" x2="410" y2="260"/>
    <line x1="150" y1="150" x2="670" y2="150"/>
  </g>
  <g font-family="ui-monospace, monospace" font-size="12" fill="currentColor" fill-opacity="0.65">
    <text x="280" y="28" text-anchor="middle">shareable</text>
    <text x="540" y="28" text-anchor="middle">local</text>
    <text x="140" y="100" text-anchor="end">static</text>
    <text x="140" y="210" text-anchor="end">variable</text>
  </g>
  <g font-family="ui-monospace, monospace" font-size="13" fill="currentColor">
    <text x="280" y="88" text-anchor="middle">/usr</text>
    <text x="540" y="80" text-anchor="middle">/etc</text>
    <text x="540" y="102" text-anchor="middle">/boot</text>
    <text x="280" y="196" text-anchor="middle">/home</text>
    <text x="540" y="186" text-anchor="middle">/var/log</text>
    <text x="540" y="208" text-anchor="middle">/run</text>
    <text x="540" y="230" text-anchor="middle">/tmp</text>
  </g>
  <g font-family="ui-monospace, monospace" font-size="10.5" fill="currentColor" fill-opacity="0.55">
    <text x="280" y="112" text-anchor="middle">mountable read-only</text>
    <text x="540" y="126" text-anchor="middle">this machine's identity</text>
    <text x="280" y="218" text-anchor="middle">exportable over the network</text>
    <text x="540" y="252" text-anchor="middle">/run is cleared every boot</text>
  </g>
</svg>
<figcaption>The FHS is not an arbitrary list. It sorts by what can be shared and what changes.</figcaption>
</figure>

Read each corner as an answer to those two questions:

- **`/usr` does not change by itself, and is the same everywhere.** This is where
  installed programs live. Because nothing on the running machine writes to it,
  it can be made read-only, or stored once and shared with many machines.
- **`/etc` does not change by itself, but is specific to this machine.** The
  settings. This is the directory that makes this server *this* server, which is
  why it is the one to back up.
- **`/var` changes constantly.** Logs, mail queues, caches, databases. It grows
  whether you touch it or not, which is why it is the usual reason a machine runs
  out of disk.
- **`/run` changes constantly and is thrown away on every restart.** It holds
  notes the running system keeps for itself, such as which processes are alive.
  Nothing durable should ever be put here.

<details class="deeper">
<summary>If you already administer Linux: the standard's own vocabulary</summary>

The two axes are what the Filesystem Hierarchy Standard calls **static versus
variable** and **shareable versus unshareable**. The practical consequences are
the ones worth carrying: `/usr` being static and shareable is what makes a
read-only `/usr` and network-mounted `/usr` possible, and it is the assumption
behind image-based systems and containers, where the OS layer is immutable and
everything writable is a mount.

`/run` is a `tmpfs`, a filesystem that exists only in memory, which is why it is
empty after boot without anything having to delete it. Before it existed this
state lived in `/var/run`, which on modern systems is a symlink to `/run` for
compatibility.

</details>

The directories worth committing to memory are the ones where getting it wrong
costs you something:

| Directory | Holds | The reason it matters |
| --- | --- | --- |
| `/etc` | System-wide configuration, no binaries | The machine's identity. Back this up. |
| `/usr` | Installed software: `/usr/bin`, `/usr/lib`, `/usr/share` | Owned by the package manager. Do not hand-edit. |
| `/var` | Logs, spools, caches, service data | Fills up. Give it its own filesystem on a server. |
| `/opt` | Self-contained third-party software | Vendor drops that do not follow the FHS live here. |
| `/srv` | Data served by this system | Web roots and exports, by convention rather than enforcement. |
| `/boot` | Kernel, initramfs, bootloader config | Often a small separate partition, which is why it fills. |
| `/proc` | Kernel and process interface | Not on disk. Files here are generated on read. |
| `/sys` | Device and driver interface | Also not on disk. |
| `/run` | Runtime state, PID files, sockets | Cleared every boot. Never put anything durable here. |
| `/tmp` | Scratch space | May be cleared on boot or on a timer. Assume it will be. |

`/proc` and `/sys` catch people out because they look like directories and are
not. Nothing there is stored anywhere; reading a file runs kernel code that
produces the answer. That is why `cat /proc/cpuinfo` is instant and why you
cannot back `/proc` up.

## The usr-merge, and what it broke

For most of Linux's history `/bin` and `/usr/bin` were genuinely different
directories, split because early systems had a small root disk and mounted
`/usr` separately. That distinction stopped being useful once initramfs existed,
and every mainstream distribution has since collapsed it: `/bin`, `/sbin`,
`/lib`, and `/lib64` are now symlinks into `/usr`.

You can see it directly.

```bash
# Debian 13 (trixie), x86_64
$ ls -l / | head -25
total 0
lrwxrwxrwx.   1 root   root      7 Jul  4 09:05 bin -> usr/bin
drwxr-xr-x.   2 root   root      6 Jul  4 09:05 boot
drwxr-xr-x.   5 root   root    340 Aug  7 19:25 dev
drwxr-xr-x.   1 root   root     31 Aug  7 19:25 etc
drwxr-xr-x.   2 root   root      6 Jul  4 09:05 home
lrwxrwxrwx.   1 root   root      7 Jul  4 09:05 lib -> usr/lib
lrwxrwxrwx.   1 root   root      9 Jul  4 09:05 lib64 -> usr/lib64
drwxr-xr-x.   2 root   root      6 Aug  3 00:00 media
drwxr-xr-x.   2 root   root      6 Aug  3 00:00 mnt
drwxr-xr-x.   2 root   root      6 Aug  3 00:00 opt
dr-xr-xr-x. 216 nobody nogroup   0 Aug  7 19:25 proc
drwx------.   2 root   root     37 Aug  3 00:00 root
drwxr-xr-x.   1 root   root     42 Aug  7 19:25 run
lrwxrwxrwx.   1 root   root      8 Jul  4 09:05 sbin -> usr/sbin
drwxr-xr-x.   2 root   root      6 Aug  3 00:00 srv
dr-xr-xr-x.  12 nobody nogroup   0 Aug  7 19:25 sys
drwxrwxrwt.   2 root   root      6 Aug  3 00:00 tmp
drwxr-xr-x.  12 root   root    133 Aug  3 00:00 usr
drwxr-xr-x.  11 root   root    139 Aug  3 00:00 var
```

The RHEL family did the same thing, earlier. AlmaLinux 10 looks almost identical,
with the addition of `/afs` and without a `/boot` entry inside a container image:

```bash
# AlmaLinux 10.2, x86_64
$ uname -m; ls -l / | head -6
x86_64
total 8
dr-xr-xr-x.   2 root   root      6 Apr  2  2025 afs
lrwxrwxrwx.   1 root   root      7 Apr  2  2025 bin -> usr/bin
drwxr-xr-x.   5 root   root    340 Aug  7 19:27 dev
drwxr-xr-x.  43 root   root   4096 Jun  2 11:08 etc
drwxr-xr-x.   2 root   root      6 Apr  2  2025 home
```

The practical consequence is that `/bin/ls` and `/usr/bin/ls` are the same file.
The consequence people get caught by is what happens when you ask a package
manager about it.

## Telling the families apart from the system itself

The split that matters most on this exam is RPM-based against dpkg-based,
because it decides which package manager, which config paths, and often which
service names you get. Do not infer it from the hostname. Read it.

`/etc/os-release` is the answer, and it is the one file that is present and
consistent everywhere, because systemd standardised it.

```bash
# AlmaLinux 10.2, x86_64
$ . /etc/os-release; printf "%s | %s | %s\n" "$ID" "$VERSION_ID" "$PRETTY_NAME"
almalinux | 10.2 | AlmaLinux 10.2 (Lavender Lion)
```

```bash
# Debian 13 (trixie), x86_64
$ . /etc/os-release; printf "%s | %s | %s\n" "$ID" "$VERSION_ID" "$PRETTY_NAME"
debian | 13 | Debian GNU/Linux 13 (trixie)
```

```bash
# Ubuntu 24.04 LTS, x86_64
$ . /etc/os-release; printf "%s | %s | %s\n" "$ID" "$VERSION_ID" "$PRETTY_NAME"
ubuntu | 24.04 | Ubuntu 24.04.4 LTS
```

```bash
# openSUSE Leap 16.0, x86_64
$ . /etc/os-release; printf "%s | %s | %s\n" "$ID" "$VERSION_ID" "$PRETTY_NAME"
opensuse-leap | 16.0 | openSUSE Leap 16.0
```

The file is shell syntax on purpose, so sourcing it is the intended way to read
it rather than a trick. For derivative distributions there is also `ID_LIKE`,
which is how you detect a family rather than a specific product: Ubuntu reports
`ID_LIKE=debian`, AlmaLinux reports `ID_LIKE="rhel centos fedora"`.

## Across distributions

| | RPM family | dpkg family |
| --- | --- | --- |
| Examples on this exam | RHEL, AlmaLinux, Rocky, Fedora, openSUSE, SLES | Debian, Ubuntu |
| Low-level tool | `rpm` | `dpkg` |
| Resolver | `dnf` (`zypper` on SUSE) | `apt` |
| Which package owns a path | `rpm -qf PATH` | `dpkg -S PATH` |
| Package file extension | `.rpm` | `.deb` |
| Web server package | `httpd` | `apache2` |

That last row is the shape of a whole class of differences: the same software,
a different package name, and therefore a different service name and a different
config path. It is not a detail you can reason your way to, which is why the
exam asks about it.

## Server architectures, and the two names for each one

Four architectures are worth knowing by name: **x86** (32-bit), **x86_64** (also
written AMD64, the 64-bit extension and the default for servers), **AArch64**
(64-bit ARM, now common in cloud instances and in every Apple Silicon Mac), and
**RISC-V**, an open instruction set architecture that is still mostly outside
production but is named because it is arriving.

The trap is that the same machine reports two different architecture strings
depending on who you ask.

```bash
# Debian 13 (trixie), x86_64
$ uname -m; dpkg --print-architecture
x86_64
amd64
```

```bash
# Debian 13 (trixie), aarch64
$ uname -m; dpkg --print-architecture
aarch64
arm64
```

```bash
# AlmaLinux 10.2, x86_64
$ uname -m; rpm -E "%{_arch}"
x86_64
x86_64
```

`uname -m` reports the kernel's name for the machine. `dpkg` uses Debian's own
architecture names, which are different words for the same thing: `amd64` for
`x86_64`, `arm64` for `aarch64`. `rpm` uses the kernel's name unchanged.

So on a Debian-family system, a script that compares `uname -m` against a
package architecture will never match, and the mismatch is not an error - it is
two naming schemes for one machine. When you need the packaging name, ask the
packaging tool.

## The graphical stack, briefly

Servers usually have none of this, but the exam names the pieces and they stack
in a specific order:

| Piece | Job | Examples |
| --- | --- | --- |
| Display server | Talks to input devices and the screen; draws nothing itself | X.Org (X11), Wayland compositor |
| Display manager | The graphical login prompt, starts the session | GDM, SDDM, LightDM |
| Window manager | Decorates, moves, and stacks windows | Mutter, KWin, i3 |
| Desktop environment | The window manager plus a full set of applications | GNOME, KDE Plasma, Xfce |

The distinction that gets tested is X versus Wayland. X.Org is a display server
that clients connect to over a socket, with the window manager a separate client
telling X where to put things. Wayland collapses that: the compositor is the
display server and the window manager at once, and clients draw their own
windows. That is why "X forwarding over SSH" has no direct Wayland equivalent,
and why disabling X forwarding shows up as a hardening step later in this track.

## Software licensing

Four terms, and the difference between two of them is the one people get wrong.

- **Free software** is about the recipient's rights: to run, study, modify, and
  redistribute. "Free" as in freedom, not price.
- **Open source** describes largely the same set of licenses with the emphasis on
  the development model rather than the ethics.
- **Copyleft** is a specific mechanism, not a synonym for either. A copyleft
  license requires that derivative works carry the same license, so the freedoms
  cannot be stripped downstream. The GPL is copyleft; MIT and BSD are open source
  and permissive, which means a derivative may be closed.
- **Proprietary** software withholds some of those rights, typically the source
  itself.

The practical consequence in a work setting: permissive and copyleft licenses
have genuinely different obligations when you ship a product built on them, which
is why the distinction is on a sysadmin exam at all.

## Prove it

Three checks that tell you what you are on and confirm the layout is what you
think it is.

```bash
# Which distribution and family
. /etc/os-release && echo "$ID (${ID_LIKE:-none}) $VERSION_ID"

# Confirm the usr-merge is in effect: these should be symlinks, not directories
ls -ld /bin /sbin /lib

# Confirm /bin/ls and /usr/bin/ls are one file, not two copies
stat -c '%i %n' /bin/ls /usr/bin/ls
```

The third one is the check worth internalising. `stat -c '%i'` prints the inode
number. If the two paths report the same inode, they are the same file on the
same filesystem, and any difference in how a tool answers questions about them
is coming from the tool, not from the disk.

## What trips people up

### 1. `dpkg -S` and `rpm -qf` disagree about `/bin/ls`

Both systems have `/bin` symlinked to `usr/bin`. Both have exactly one `ls`. Ask
each package manager who owns `/bin/ls` and you get different answers.

<details class="predict">
<summary>One of these two commands fails. Which, and what does that tell you about where each tool looks?</summary>

```bash
# AlmaLinux 10.2, x86_64
$ rpm -qf /bin/ls; rpm -qf /usr/bin/ls
coreutils-single-9.5-7.el10.x86_64
coreutils-single-9.5-7.el10.x86_64
```

```bash
# Debian 13 (trixie), x86_64
$ dpkg -S /bin/ls; echo "exit=$?"; dpkg -S /usr/bin/ls
dpkg-query: no path found matching pattern /bin/ls
exit=1
coreutils: /usr/bin/ls
```

</details>

`rpm -qf` resolves the path on the live filesystem before looking it up, so the
symlink is followed and both spellings land on the same entry. `dpkg -S` does a
string match against the paths recorded in the package database, and Debian's
database records `/usr/bin/ls`. `/bin/ls` is not in the database because no
package ever claimed that spelling.

Neither tool is broken. They are answering different questions: `rpm` asks the
filesystem, `dpkg` asks its own records.

What this means in practice: **`dpkg -S` wants the canonical path.** When a
lookup comes back empty on a Debian-family system, resolve the path first rather
than concluding the file is unpackaged.

```bash
dpkg -S "$(realpath /bin/ls)"
```

### 2. `/tmp` and `/run` are not places to keep things

`/run` is a `tmpfs` and is empty after every boot. That is its purpose: it holds
runtime state such as PID files and sockets that should not survive a restart.
`/tmp` may also be cleared, either at boot or on a timer, and which of those
happens depends on the distribution.

The failure is slow. A service writes state to one of them, works for as long as
the machine stays up, and loses everything at the next reboot. Durable service
data belongs in `/var/lib/<service>`, and that is what packages use.

### 3. `/proc` and `/sys` are not files, so normal tools mislead you

`ls -l /proc/cpuinfo` reports a size of zero, and every file under `/proc` and
`/sys` reports zero. The content does not exist until you read it, at which point
the kernel generates it. So `du` reports nothing, backup tools either skip these
trees or hang on them, and a file size tells you nothing about whether there is
content.

Read them with `cat`, and exclude them from anything that walks the filesystem.

### 4. Confusing `/usr/local` with `/usr`

`/usr` belongs to the package manager. `/usr/local` belongs to you, and package
managers do not write there. Software you compile from source installs to
`/usr/local` by default for exactly this reason: it keeps hand-built binaries
out of the tree that a package upgrade will overwrite.

If you put something in `/usr/bin` by hand, the next package upgrade that ships
that path will overwrite it without asking. That is not a bug; you wrote into
someone else's directory.

## Work it through

You inherit a Linux server with no documentation. A monitoring check is failing
with a message about a missing binary at `/usr/bin/healthcheck`. You need to know
whether that file was installed by a package, dropped there by hand, or never
existed.

Reason it out before reading on.

**First, establish which family you are on**, because it decides which query you
can run:

```bash
. /etc/os-release && echo "$ID ${ID_LIKE:-}"
```

Say it reports `debian`. That means `dpkg`, not `rpm`.

**Second, ask whether the path exists at all**, and if it does, resolve it:

```bash
ls -l /usr/bin/healthcheck
```

**Third, ask the package database who owns it.** On the dpkg family, give it the
canonical path, because of trip-up one:

```bash
dpkg -S "$(realpath /usr/bin/healthcheck 2>/dev/null || echo /usr/bin/healthcheck)"
```

Three outcomes and what each one tells you:

- **A package name comes back.** The file belongs to a package and something
  removed or replaced it. Reinstalling that package restores it.
- **`no path found matching pattern`, and the file exists.** Somebody put it
  there by hand. It is not managed, it will not be upgraded, and it will not be
  reinstalled by anything. It also belongs in `/usr/local/bin`, not `/usr/bin`.
- **The file does not exist and no package claims it.** The check is pointing at
  something that was never installed on this machine. The bug is in the
  monitoring configuration, not on the server.

The reasoning that matters: you did not guess, and you did not run a command
that only works on the other family. You read the system, chose the query that
matches it, and let the outcome narrow the possibilities.

## Try it

Optional, and only worth doing if you have a VM or a container to hand.

Start from a Debian-family system and reproduce the usr-merge disagreement
deliberately.

1. Confirm `/bin` is a symlink and that `/bin/ls` and `/usr/bin/ls` share an
   inode.
2. Run `dpkg -S /bin/ls` and confirm it fails.
3. Make it succeed without changing anything on disk.

For step 3 you need the same idea as trip-up one: the database stores canonical
paths, so the query has to supply one.

**Verification step.** You have it right when the same file produces a package
name through one spelling and an error through the other, and you can say in one
sentence why, without using the word "bug".

## Check yourself

<details class="qa">
<summary>A file must survive a reboot and is service state rather than configuration. Which directory does it belong in, and which two are the tempting wrong answers?</summary>

`/var/lib/<service>`. That is where packages put exactly this kind of thing:
data a service owns and needs to still be there tomorrow.

The tempting wrong answers are `/tmp` and `/run`, because both are writable and
convenient and neither complains. `/run` is emptied on every boot by design, and
`/tmp` may be cleared on boot or on a timer depending on the distribution.

`/etc` is the third near-miss. It survives reboots perfectly well, but it is for
configuration you edit, not for state a service writes, and mixing the two makes
backups and version control unpleasant.

</details>

<details class="qa">
<summary>`ls -l /proc/meminfo` reports a size of 0 bytes. Is the file empty?</summary>

No. It is not a file in the usual sense at all.

Everything under `/proc` is generated by the kernel at the moment you read it,
so there is nothing sitting on a disk to have a size. The kernel reports zero
because reporting anything else would be a guess.

Read it with `cat` and you get plenty of content. The practical consequences:
`du` sees nothing there, and backup tools should skip `/proc` and `/sys`
entirely, because walking them is at best pointless and at worst a hang.

</details>

<details class="qa">
<summary>`rpm` is not installed and `dpkg -S` returns nothing for a path you can see with `ls`. Name two explanations and the command that tells them apart.</summary>

Either the file genuinely is not owned by any package, meaning somebody put it
there by hand, or you gave `dpkg` a path it does not have on file, because the
database records the canonical `/usr/...` spelling and you handed it a
usr-merge symlink.

`dpkg -S "$(realpath /path/to/file)"` distinguishes them. Resolve the path first;
if it now returns a package, you had spelling, not an unmanaged file. If it still
returns nothing, the file is genuinely unmanaged, which also means nothing will
ever upgrade or reinstall it.

</details>

<details class="qa">
<summary>What does `ID_LIKE` in `/etc/os-release` give you that `ID` does not?</summary>

`ID` tells you the specific product: `ubuntu`, `almalinux`, `opensuse-leap`.
`ID_LIKE` tells you the **family** it descends from, so Ubuntu reports
`ID_LIKE=debian` and AlmaLinux reports `ID_LIKE="rhel centos fedora"`.

That is the difference between a script that works on Ubuntu and a script that
works on anything Debian-shaped. Match on `ID_LIKE` when you care about which
package manager exists, and on `ID` only when you genuinely need one specific
distribution.

Worth knowing the edge: Debian itself has no `ID_LIKE`, because it is not like
anything else, it is the thing others are like. A check that only reads
`ID_LIKE` will miss Debian entirely.

</details>

## References

- [Filesystem Hierarchy Standard, version 3.0](https://refspecs.linuxfoundation.org/FHS_3.0/fhs/index.html) - Linux Foundation. Accessed 2026-08-07.
- [hier(7): description of the filesystem hierarchy](https://man7.org/linux/man-pages/man7/hier.7.html) - Linux man-pages project. Accessed 2026-08-07.
- [file-hierarchy(7): systemd's file system hierarchy overview](https://man7.org/linux/man-pages/man7/file-hierarchy.7.html) - Linux man-pages project. Accessed 2026-08-07.
- [os-release(5)](https://man7.org/linux/man-pages/man5/os-release.5.html) - Linux man-pages project. Accessed 2026-08-07.
- [UsrMerge](https://wiki.debian.org/UsrMerge) - Debian Wiki. Accessed 2026-08-07.
- [Features/UsrMove](https://fedoraproject.org/wiki/Features/UsrMove) - Fedora Project. Accessed 2026-08-07.
- [dpkg-query(1)](https://man7.org/linux/man-pages/man1/dpkg-query.1.html) - Linux man-pages project. Accessed 2026-08-07.
- [rpm(8)](https://man7.org/linux/man-pages/man8/rpm.8.html) - Linux man-pages project. Accessed 2026-08-07.
- [What is Copyleft?](https://www.gnu.org/licenses/copyleft.en.html) - GNU Project. Accessed 2026-08-07.
- [Wayland Architecture](https://wayland.freedesktop.org/architecture.html) - freedesktop.org. Accessed 2026-08-07.

Command output above was captured on the images pinned in
`blog/scripts/distros.json` and is reproducible with `blog/scripts/capture.sh`.
