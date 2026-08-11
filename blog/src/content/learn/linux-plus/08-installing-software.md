---
title: "Installing software"
description: "There is no download button. Instead there is a signed catalogue your machine already trusts, three commands that do the same job on different distributions, and a good reason not to curl a binary off the internet."
deck: "When there is no download button"
track: "linux-plus"
level: "intro"
order: 90
objectives:
  - "Install, remove, search for, and update software with the right tool for the distribution"
  - "Explain what a repository is and why every package is signed"
  - "Find which package owns a file, and which files a package installed"
  - "Say why installing from a repository is a different risk from downloading a binary"
prerequisites: ["users-root-and-sudo"]
tags: ["linux", "linux-plus", "packages", "beginner"]
updated: 2026-08-09
draft: false
examObjectives:
  - exam: "xk0-006"
    domain: "2.0"
    objective: "2.4"
sources:
  - title: "apt(8)"
    url: "https://manpages.debian.org/stable/apt/apt.8.en.html"
    publisher: "Debian Project"
    accessed: 2026-08-07
    tier: 1
  - title: "sources.list(5)"
    url: "https://manpages.debian.org/stable/apt/sources.list.5.en.html"
    publisher: "Debian Project"
    accessed: 2026-08-07
    tier: 1
  - title: "dpkg(1)"
    url: "https://man7.org/linux/man-pages/man1/dpkg.1.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "rpm(8)"
    url: "https://man7.org/linux/man-pages/man8/rpm.8.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "DNF5 command reference"
    url: "https://dnf5.readthedocs.io/en/latest/commands/index.html"
    publisher: "DNF project"
    accessed: 2026-08-07
    tier: 1
  - title: "Zypper usage"
    url: "https://en.opensuse.org/SDB:Zypper_usage"
    publisher: "openSUSE"
    accessed: 2026-08-07
    tier: 2
symptoms:
  - symptom: "Unable to locate package"
    anchor: "1-unable-to-locate-package"
  - symptom: "No match for argument"
    anchor: "1-unable-to-locate-package"
---

> **Before you read.** On Windows or a Mac you find a website, click Download, run
> the installer, and click Next four times. On Linux nobody does this, and the
> instructions you find say things like `dnf install nginx` instead.
>
> That is not a limitation, it is a different model, and it is worth asking what
> the model buys you before learning the commands. Here is the question: when you
> download an installer from a website, what exactly are you trusting, and how
> would you know if you were wrong?

You are trusting that you reached the real site, that the file was not modified
in transit, that the site was not compromised, and that the vendor is honest.
Four separate acts of faith, checked by nobody, repeated for every program you
install and every time it updates.

Linux replaces all of that with a catalogue your machine already trusts,
cryptographically signed, updated centrally, with one command that patches
everything on the system at once. Once you have used it you will resent every
other operating system slightly.

### Some words you will need

<dl class="terms">
<dt>package</dt>
<dd>A single file containing a program, its files, where each one goes, and a list of what else it needs. <code>.rpm</code> or <code>.deb</code> depending on the family.</dd>
<dt>repository</dt>
<dd>A server holding thousands of packages plus an index of them. Your machine is configured with a list of these and trusts their signing keys.</dd>
<dt>dependency</dt>
<dd>Another package this one needs to work. The package manager works these out and installs them for you.</dd>
<dt>package manager</dt>
<dd>The command that talks to repositories, resolves dependencies, and installs. <code>dnf</code>, <code>apt</code>, or <code>zypper</code>.</dd>
</dl>

## What breaks without this

**You cannot install anything**, which stops most other work before it starts.

**You end up with software nobody can account for.** A binary dropped into
`/usr/local/bin` by hand belongs to no package, appears in no inventory, is
updated by no patch cycle, and will still be sitting there, unpatched, when it
turns up in a vulnerability scan two years later.

**You cannot answer "is this machine patched?"** With packages that question has a
one-line answer. Without them it becomes an archaeology project.

## What a repository actually is

Your machine has a list of servers it will accept software from. On Debian:

```bash
# Debian 13 (trixie), x86_64
$ cat /etc/apt/sources.list.d/debian.sources 2>/dev/null || cat /etc/apt/sources.list
Types: deb
# http://snapshot.debian.org/archive/debian/20260803T000000Z
URIs: http://deb.debian.org/debian
Suites: trixie trixie-updates
Components: main
Signed-By: /usr/share/keyrings/debian-archive-keyring.pgp

Types: deb
# http://snapshot.debian.org/archive/debian-security/20260803T000000Z
URIs: http://deb.debian.org/debian-security
Suites: trixie-security
Components: main
Signed-By: /usr/share/keyrings/debian-archive-keyring.pgp
```

Two entries: the main archive and the security archive. Read `Signed-By` closely,
because it is the whole security model in one line.

**Every package is signed, and the machine holds the key that verifies the
signature.** A package that does not verify is refused. That is why the URL can
be plain `http` without anyone panicking: the transport does not have to be
trusted, because the content proves its own origin.

Adding a third-party repository means adding its key, which means deciding to
trust whoever holds it, for every package they will ever ship you, forever. It
is a bigger decision than it looks and it is worth making deliberately.

The RHEL family keeps the same idea in a different shape:

```bash
# AlmaLinux 10.2, x86_64
$ dnf repolist
repo id                          repo name
appstream                        AlmaLinux 10 - AppStream
baseos                           AlmaLinux 10 - BaseOS
crb                              AlmaLinux 10 - CRB
extras                           AlmaLinux 10 - Extras
```

Four repositories, each a different slice of the distribution. `BaseOS` is the
core operating system, `AppStream` is everything else, and the split exists so
the two can move at different speeds.

## The catalogue is a local copy

<figure class="learn-figure">
<svg viewBox="0 0 720 210" role="img" aria-labelledby="ap-t ap-d" style="width:100%;height:auto;">
<title id="ap-t">apt update refreshes a local catalogue, apt install fetches packages</title>
<desc id="ap-d">Two commands doing two unrelated jobs. apt update contacts the repositories and downloads their package lists, roughly ten megabytes here, writing them to a cache on this machine. It installs nothing. apt install reads that cached list to work out which package and which dependencies it needs, then downloads and installs those. Because the catalogue is a local copy taken at a point in time, a stale one produces an install failure for a version that no longer exists on the server, which is why the fix is almost always to update first.</desc>
<g>
<rect x="30" y="52" width="170" height="60" rx="5" fill="currentColor" fill-opacity="0.07" stroke="currentColor" stroke-opacity="0.32"/>
<text x="115" y="78" text-anchor="middle" font-size="11" fill="currentColor">the repository</text>
<text x="115" y="96" text-anchor="middle" font-size="10" fill="currentColor" fill-opacity="0.65">on somebody's server</text>
<rect x="286" y="52" width="180" height="60" rx="5" fill="var(--accent)" fill-opacity="0.12" stroke="var(--accent)" stroke-opacity="0.9" stroke-width="1.8"/>
<text x="376" y="78" text-anchor="middle" font-size="11" fill="var(--accent)">the local catalogue</text>
<text x="376" y="96" text-anchor="middle" font-size="10" fill="var(--accent)">a copy, taken at a moment</text>
<rect x="552" y="52" width="150" height="60" rx="5" fill="currentColor" fill-opacity="0.07" stroke="currentColor" stroke-opacity="0.32"/>
<text x="627" y="78" text-anchor="middle" font-size="11" fill="currentColor">installed</text>
<text x="627" y="96" text-anchor="middle" font-size="10" fill="currentColor" fill-opacity="0.65">on this machine</text>
<text x="243" y="42" text-anchor="middle" font-size="10" fill="currentColor" fill-opacity="0.8">apt update</text>
<text x="243" y="140" text-anchor="middle" font-size="10" fill="currentColor" fill-opacity="0.65">10.1 MB of lists, 0 packages</text>
<text x="509" y="42" text-anchor="middle" font-size="10" fill="currentColor" fill-opacity="0.8">apt install</text>
<text x="30" y="182" font-size="10" fill="currentColor" fill-opacity="0.65">a stale catalogue asks for a version the server no longer has, which is the usual 404</text>
</g>
<g stroke="currentColor" stroke-opacity="0.5" fill="none" stroke-width="1.3">
<path d="M202 82 L282 82 M276 78 L283 82 L276 86"/>
<path d="M468 82 L548 82 M542 78 L549 82 L542 86"/>
</g>
</svg>
<figcaption>The two commands never touch the same thing. <code>apt update</code> refreshes the middle box and installs nothing at all, which is why it downloads ten megabytes and leaves the system unchanged. <code>apt install</code> reads the middle box to decide what to fetch, so when that copy is old it asks the server for a version that has already been replaced.</figcaption>
</figure>

This is the single most useful thing to understand about `apt`, and it explains
its most common error message:

<details class="predict">
<summary><code>apt update</code> is the command people run before installing anything. It downloads roughly 10 MB here. How many packages does it install?</summary>

```bash
# Debian 13 (trixie), x86_64
$ apt-get update 2>&1 | head -12
Get:1 http://deb.debian.org/debian trixie InRelease [140 kB]
Get:2 http://deb.debian.org/debian trixie-updates InRelease [47.3 kB]
Get:3 http://deb.debian.org/debian-security trixie-security InRelease [43.4 kB]
Get:4 http://deb.debian.org/debian trixie/main amd64 Packages [9673 kB]
Get:5 http://deb.debian.org/debian trixie-updates/main amd64 Packages [4412 B]
Get:6 http://deb.debian.org/debian-security trixie-security/main amd64 Packages [236 kB]
Fetched 10.1 MB in 3s (3832 kB/s)
Reading package lists...
```

</details>

**`apt update` installed nothing.** It downloaded 10 MB of index, the
catalogue of what exists and at what version, and stopped there.

Your machine searches that local copy, not the internet. If the copy is stale or
empty, `apt` will tell you a package does not exist when it plainly does. On a
freshly built machine or container the copy is empty, which is why the very first
command in every Debian install instruction is `apt update`.

`dnf` and `zypper` refresh their metadata automatically when it is stale, which
is why you never see this step on the RHEL or SUSE side. Same mechanism,
different default.

## Installing something

Same job, three distributions, three sets of output worth reading.

```bash
# Debian 13 (trixie), x86_64
$ export DEBIAN_FRONTEND=noninteractive TERM=dumb; apt-get update -qq >/dev/null 2>&1; apt-get install -y -o Dpkg::Use-Pty=0 tree 2>/dev/null
Reading package lists...
Building dependency tree...
Reading state information...
The following NEW packages will be installed:
  tree
0 upgraded, 1 newly installed, 0 to remove and 0 not upgraded.
Need to get 59.4 kB of archives.
After this operation, 132 kB of additional disk space will be used.
Get:1 http://deb.debian.org/debian trixie/main amd64 tree amd64 2.2.1-1 [59.4 kB]
Fetched 59.4 kB in 0s (434 kB/s)
Selecting previously unselected package tree.
(Reading database ... 4936 files and directories currently installed.)
Preparing to unpack .../tree_2.2.1-1_amd64.deb ...
Unpacking tree (2.2.1-1) ...
Setting up tree (2.2.1-1) ...
```

The line to read is `0 upgraded, 1 newly installed, 0 to remove and 0 not
upgraded`. **Read that summary before agreeing to anything.** A request for one
small utility that reports "0 upgraded, 1 newly installed, 4 to remove" is telling
you something important, and the thing being removed is often something you
wanted.

The same on AlmaLinux, in a rather more formal register:

```bash
# AlmaLinux 10.2, x86_64
$ dnf install -y tree
AlmaLinux 10 - AppStream                        1.2 MB/s | 2.3 MB     00:01
AlmaLinux 10 - BaseOS                           3.6 MB/s |  25 MB     00:07
AlmaLinux 10 - CRB                              1.0 MB/s | 557 kB     00:00
AlmaLinux 10 - Extras                            24 kB/s | 7.3 kB     00:00
Dependencies resolved.
================================================================================
 Package        Architecture     Version                 Repository        Size
================================================================================
Installing:
 tree           x86_64           2.1.0-8.el10            baseos            56 k

Transaction Summary
================================================================================
Install  1 Package

Total download size: 56 k
Installed size: 108 k
Downloading Packages:
tree-2.1.0-8.el10.x86_64.rpm                    346 kB/s |  56 kB     00:00
--------------------------------------------------------------------------------
Total                                           181 kB/s |  56 kB     00:00
Running transaction check
Transaction check succeeded.
Running transaction test
Transaction test succeeded.
Running transaction
  Preparing        :                                                        1/1
  Installing       : tree-2.1.0-8.el10.x86_64                               1/1
  Running scriptlet: tree-2.1.0-8.el10.x86_64                               1/1

Installed:
  tree-2.1.0-8.el10.x86_64                                                      

Complete!
```

The first four lines are `dnf` refreshing its metadata because it had none,
the step `apt` makes you ask for. Then a table naming the package,
architecture, version, and **which repository it came from**, which is exactly
what you want to check when a package could have come from more than one
place.

Note the versions: Debian ships `tree` 2.2.1, AlmaLinux ships 2.1.0. Neither is
wrong. Distributions pick a version, stabilise it, and backport fixes to it,
which is why "the latest version" is not the goal you might assume it is.

And openSUSE, which is a third syntax for the same idea:

```bash
# openSUSE Leap 16.0, x86_64
$ zypper --non-interactive install tree 2>&1 | tail -25
Loading repository data...
Reading installed packages...
Resolving package dependencies...

The following NEW package is going to be installed:
  tree

1 new package to install.

Package download size:    84.2 KiB

Package install size change:
              |     148.8 KiB  required by packages that will be installed
   148.8 KiB  |  -      0 B    released by packages that will be removed

Backend:  classic_rpmtrans
Continue? [y/n/v/...? shows all options] (y): y
Preloading Packages [..
Preloading: tree-2.2.1-160000.2.2.x86_64.rpm [done]
.done]
Retrieving: tree-2.2.1-160000.2.2.x86_64 (repo-oss (16.0)) (1/1),  84.2 KiB

Checking for file conflicts: [..done]
(1/1) Installing: tree-2.2.1-160000.2.2.x86_64 [..done]
Running post-transaction scripts [...done]
```

Three tools, three output formats, one model. Learn the model and the commands
are lookup.

## The commands, side by side

| Job | `dnf` (RHEL family) | `apt` (Debian family) | `zypper` (SUSE) |
| --- | --- | --- | --- |
| Refresh the catalogue | *(automatic)* | `apt update` | `zypper refresh` |
| Search | `dnf search tree` | `apt search tree` | `zypper search tree` |
| Show details | `dnf info tree` | `apt show tree` | `zypper info tree` |
| Install | `dnf install tree` | `apt install tree` | `zypper install tree` |
| Remove | `dnf remove tree` | `apt remove tree` | `zypper remove tree` |
| Remove config too | *(n/a)* | `apt purge tree` | *(n/a)* |
| Update everything | `dnf upgrade` | `apt update && apt upgrade` | `zypper update` |
| List installed | `dnf list --installed` | `apt list --installed` | `zypper search -i` |

All of them need root, so all of them want `sudo` in front.

**The one asymmetry worth memorising is `purge`.** Everything else in that table
is the same idea wearing different clothes; `purge` is a genuine behavioural
difference, and it is on the exam.


<details class="deeper">
<summary>If you already administer Linux: transaction history, and undoing an update</summary>

**`dnf` records every transaction and can reverse them.** This is the single
biggest operational difference between the two families and it is worth knowing
before you need it:

```
sudo dnf history                  # every transaction, numbered
sudo dnf history info 42          # exactly what changed in one
sudo dnf history undo 42          # reverse it
sudo dnf history rollback 42      # reverse everything since
```

Which turns "last night's patch broke the application" from an archaeology
project into one command. `dnf history userinstalled` is the other useful one,
what was installed deliberately, as opposed to pulled in as a dependency,
which is what you actually want when rebuilding a machine.

**`apt` has no equivalent.** `/var/log/apt/history.log` and `/var/log/dpkg.log`
record what happened, and reversing it is manual: read the log, work out the
previous versions, and install those explicitly with `apt install
package=version`. `apt-mark showmanual` is the closest thing to
`userinstalled`.

The practical consequence is a difference in how much you should trust an
unattended upgrade on each family, and it is a fair thing to raise when somebody
asks which distribution to standardise on.

**Both families keep old versions available**, which is what makes any of this
possible. `dnf --showduplicates list kernel` and `apt list -a nginx` show what
you could go back to, and on the RHEL family `dnf downgrade` does it directly.

</details>

## Searching, when you do not know the name

```bash
# AlmaLinux 10.2, x86_64
$ dnf -q search tree 2>&1 | head -12
========================= Name & Summary Matched: tree =========================
tree.x86_64 : File system tree viewer
cockpit-ostree.noarch : Cockpit user interface for rpm-ostree
libtree-sitter-devel.x86_64 : Development files for tree-sitter
maven-dependency-tree.noarch : Maven dependency tree artifact
osbuild-ostree.x86_64 : OSTree support
ostree.x86_64 : Tool for managing bootable, immutable filesystem trees
ostree-devel.x86_64 : Development headers for ostree
ostree-grub2.x86_64 : GRUB2 integration for OSTree
ostree-libs.x86_64 : C shared libraries ostree
rpm-ostree-libs.x86_64 : Shared library for rpm-ostree
```

Search matches names *and* descriptions, which is why one four-letter query
returns eleven results, most of which contain "tree" somewhere in a sentence.
Skim the descriptions rather than the names.

Two conventions visible in that list and worth knowing now: **`-devel` (or `-dev`
on Debian) means header files for building software against a library**, not the
library itself, and **`noarch` means the package contains nothing
architecture-specific**, such as scripts or documentation.

## Remove, and the thing `purge` does differently

<details class="predict">
<summary><code>nano</code> is installed, so <code>/etc/nanorc</code> exists. After <code>apt remove nano</code>, is <code>/etc/nanorc</code> still on disk? And what does <code>dpkg -l nano</code> report?</summary>

```bash
# Debian 13 (trixie), x86_64
$ export DEBIAN_FRONTEND=noninteractive; apt-get install -y -qq nano >/dev/null 2>&1; apt-get remove -y -qq -o Dpkg::Use-Pty=0 nano >/dev/null 2>&1; dpkg -l nano | tail -2; ls -l /etc/nanorc; echo "--- now purge ---"; apt-get purge -y -qq -o Dpkg::Use-Pty=0 nano >/dev/null 2>&1; dpkg -l nano 2>&1 | tail -1; ls -l /etc/nanorc
+++-==============-=============-============-============================================
rc  nano           8.4-1+deb13u1 amd64        small, friendly text editor inspired by Pico
-rw-r--r--. 1 root root 11763 May  3 23:09 /etc/nanorc
--- now purge ---
dpkg-query: no packages found matching nano
ls: cannot access '/etc/nanorc': No such file or directory
```

**The config file survives `remove`, and `dpkg -l` still lists the package.**

That `rc` at the start of the line is the status: **r** for removed, **c** for
config files remaining. The program is gone and its settings are not, so
reinstalling later gets your configuration back exactly as you left it.

`purge` takes the rest. After it, `dpkg-query` cannot find the package at all and
`/etc/nanorc` is gone.

The RHEL family does not make this distinction: `dnf remove` takes the package
and leaves modified config files behind with an `.rpmsave` suffix instead,
which achieves a similar goal by a different route.

</details>

That `rc` state is worth recognising because it produces a genuinely confusing
symptom: a package you removed months ago still appearing in `dpkg -l`, and
`apt list --installed` not showing it. Both are correct. The package is not
installed; a residue of it is recorded.

## Which package owns this file?

Two questions come up constantly. What put this file here, and what did that
package put where?

```bash
# Debian 13 (trixie), x86_64
$ dpkg -S /usr/bin/tree; dpkg -L tree | head -5; apt list --installed 2>/dev/null | grep tree
tree: /usr/bin/tree
/.
/usr
/usr/bin
/usr/bin/tree
/usr/share
tree/stable,now 2.2.1-1 amd64 [installed]
```

```bash
# AlmaLinux 10.2, x86_64
$ rpm -qf /usr/bin/tree; rpm -ql tree | head -5
tree-2.1.0-8.el10.x86_64
/usr/bin/tree
/usr/lib/.build-id
/usr/lib/.build-id/10
/usr/lib/.build-id/10/8d6eac2e38deba9d39d266a8517ad9ee1e96d1
/usr/share/doc/tree
```

| Question | Debian family | RHEL family |
| --- | --- | --- |
| What owns this file? | `dpkg -S /path` | `rpm -qf /path` |
| What files did this package install? | `dpkg -L name` | `rpm -ql name` |

**A file that no package owns is a finding.** `dpkg -S` or `rpm -qf` returning
nothing means somebody put that file there by hand, and it is outside the patch
cycle. On a machine you have inherited, that is one of the more informative
questions you can ask.

Note `rpm` and `dpkg` are the *low-level* tools: they operate on packages already
on the machine and do not talk to repositories or resolve dependencies. `dnf` and
`apt` sit above them and do. Use the high-level tool to install, the low-level
tool to ask questions.


<details class="deeper">
<summary>If you already administer Linux: holding a package back, and why it is usually the wrong answer</summary>

Sometimes one package must not move, a database that only certifies against a
specific point release, a kernel a vendor driver was built against.

**RHEL family:** `dnf versionlock` from `python3-dnf-plugin-versionlock`, or
`exclude=packagename*` in `/etc/dnf/dnf.conf`, or `--exclude` on a single
command. **Debian family:** `apt-mark hold packagename`, reversed with
`unhold`, and `apt-mark showhold` to list what is pinned. The finer-grained
version is `/etc/apt/preferences.d/` with a priority, which can pin to a
specific version or a specific repository.

**The reason to be uncomfortable about all of it:** a held package stops
receiving security updates, silently, forever, and the person who held it will
have left. A hold is a decision with an expiry date and no mechanism to enforce
one.

Two things make it survivable. **Document the hold where the fleet's
configuration lives**, not only on the machine, so it appears in review. And
**hold the narrowest thing that works**, one package rather than a whole
repository, and never `exclude=*`.

The related trap: **excluding kernels** to protect an out-of-tree driver.
That trades a driver problem for an unpatched kernel, which is a considerably
worse position. DKMS, from lesson 10, is the answer that does not require the
trade.

</details>

## Updating everything

One command patches the whole machine:

| | Command |
| --- | --- |
| RHEL family | `sudo dnf upgrade` |
| Debian family | `sudo apt update && sudo apt upgrade` |
| SUSE | `sudo zypper update` |

That is the entire patching story for the operating system and every program
installed from a repository, which is most of them. It is also the strongest
practical argument for the package model: software you installed by hand is not
covered by any of these lines, and you will not be reminded.

Debian's two-step catches people out. `apt upgrade` alone upgrades using whatever
catalogue you last downloaded, so without `apt update` first you can carefully
install yesterday's version of everything.

<details class="deeper">
<summary>If you already administer Linux: modules, language managers, and the /usr/local boundary</summary>

**`dnf upgrade` versus `dnf update`** are the same command; `update` is the alias
kept for muscle memory. `apt upgrade` and `apt full-upgrade` are *not* the same:
plain `upgrade` will not remove a package to satisfy a dependency, and
`full-upgrade` (formerly `dist-upgrade`) will. On a release upgrade you want the
second and you want to read the summary first.

**AppStream modules** on the RHEL family let one release carry several
versions of the same thing: `dnf module list nodejs`, `dnf module enable
nodejs:20`. Enabling a stream pins you to it, and a package that appears
missing is quite often present in a stream nobody enabled. DNF5 in RHEL 10 has
reworked this considerably; check the version in front of you rather than
trusting a blog post.

**Language package managers** (`pip`, `npm`, `gem`, `cargo`) are the sharp
edge. They install into the same filesystem, they do not coordinate with `rpm`
or `dpkg`, and `pip install` as root into the system Python has broken enough
machines that recent versions refuse outright with `error:
externally-managed-environment`. That refusal is a feature. Use a virtual
environment, or a distribution package, or a container. The general rule:
**the system package manager owns `/usr`; you own `/usr/local`; nothing else
may write to `/usr`.**

**Verification** is what makes the ownership questions above worth having. `rpm
-Va` and `debsums -c` compare every installed file against the checksums recorded
at install time and report what has changed. Slow, noisy about config files that
are meant to change, and occasionally the fastest route to noticing that a binary
is not the one the distribution shipped.

**Containers and Flatpak** change the boundary rather than removing it. A
container image has its own package manager and its own patch cycle, which means
`dnf upgrade` on the host patches nothing inside it. Inventorying images is a
separate job from inventorying hosts, and forgetting that is one of the more
common gaps in an otherwise well-run patch process.

</details>

<details class="deeper">
<summary>If you already administer Linux: what the package manager is actually solving, and the four ways people re-create the problem</summary>

A package manager is a **dependency solver with a transaction log**, and describing
it as "a way to install software" undersells it enough that people cheerfully route
around it.

What it maintains that a downloaded binary does not:

- **A resolvable dependency graph.** It will not install something whose
  requirements cannot be met, and it will not remove something another package
  needs. The failure happens before anything changes, not afterwards.
- **A file-to-package index.** Every file on the system has an owner, so `rpm
  -qf` and `dpkg -S` can answer "what put this here", the first question in
  any incident involving an unexpected binary.
- **A verification baseline.** `rpm -V` and `debsums` compare what is on disk
  against what shipped, which is the file-integrity check you get for free.
- **A patch path.** One `dnf update` reaches everything it manages. Anything it
  does not manage is invisible to that command and to every vulnerability scanner
  that reads the package database.

**The four common ways people give this up**, in rough order of how much trouble
they cause:

**Language package managers.** `pip install` outside a virtual environment,
`npm -g`, `gem install`. These write into paths the system package manager
owns and have their own idea of what version of a shared library is correct.
The two databases then disagree, and a distribution upgrade breaks in a way
that is genuinely hard to unpick. Debian and Fedora both refuse this now by
default, the PEP 668 error earlier in this track is exactly that guard.

`make install` from source. Installs into `/usr/local` with no record of what
it wrote, so there is no uninstall and no verification. `checkinstall` builds
a package instead and is worth the extra minute.

Vendor install scripts piped into a shell. `curl ... | sh` executes whatever
the server returns today, unverified, as root. It also usually adds a
repository and a signing key, which is the part worth reading before you run
it.

Container images as a way to avoid packaging. Legitimate, and it moves the
problem rather than removing it: the packages inside the image still need
patching, and now they are invisible to the host's package manager. That is
what image scanning exists for.

The honest exception is `/opt`. The FHS reserves it for self-contained
third-party software precisely because some vendors ship that way and always
will. Keeping such things in `/opt`, out of `/usr`, at least means the
boundary is visible, and `find /opt -maxdepth 2` becomes your inventory of
what the package manager does not know about.

</details>

## Why not just download the binary

You will find projects offering `curl https://example.com/install.sh | sudo bash`.
It works. Consider what it does:

- **Executes an unreviewed script as root**, from a URL, fetched at the moment of
  running. Nobody, including you, knows what it contained.
- **Installs files no package owns**, invisible to every inventory and audit.
- **Opts out of patching.** No `dnf upgrade` will ever touch it.
- **Trusts TLS alone.** Compare with a package, whose signature is checked against
  a key you already hold, independent of how it arrived.

The reasonable middle ground, in order of preference: use the distribution's
package; if the vendor publishes a repository, add it deliberately and add its
key; if you must install by hand, put it under `/usr/local`, write down what you
did, and own the patching yourself.

None of this is purity. It is the difference between "we patched everything" being
a fact and being a hope.

## Prove it

After installing, three checks:

```bash
# Is the package actually recorded as installed
rpm -q tree          # or: dpkg -l tree

# Is the command on your PATH
command -v tree

# Which repository did it come from, and which version
dnf info tree        # or: apt show tree
```

The third is the one people skip and the one that answers "why do I have a
different version from the other server".

## What trips people up

### 1. "Unable to locate package"

On Debian this almost always means the catalogue is stale or empty. `sudo apt
update` first, then try again. On a fresh container it is empty by definition.

If it persists, the package genuinely may not be in your configured
repositories. The RHEL family says `No match for argument` for the same
situation, and on that side the usual cause is a repository that is not
enabled, EPEL, or a module stream, rather than a stale index.

### 2. The name is not what you expected

Package names do not always match command names. The command `dig` is in
`bind-utils` on RHEL and `dnsutils` on Debian. `ifconfig` is in `net-tools`.
`ping` may be in `iputils`.

`dnf provides '*/dig'` and `apt-file search bin/dig` answer "which package
contains this command", which is the question you actually have. Search by what
you want to run, not by what you think it is called.

### 3. Forgetting sudo

`Permission denied` or `are you root?` from a package manager. Installing writes
to `/usr` and to the package database, both of which belong to root.

Read the message rather than assuming the command failed: `dnf search` and `apt
show` work fine unprivileged, because reading the catalogue is not a privileged
operation.

### 4. Mixing package managers with language installers

`pip install` as root on top of a system Python is the classic. The distribution
has packaged specific versions of specific libraries and something else depends
on them; the language installer knows nothing about that and replaces one.

Recent Python refuses with `externally-managed-environment` rather than doing it.
That message is protecting you, and the correct response is a virtual environment
rather than the `--break-system-packages` flag whose name is trying to tell you
something.

### 5. Assuming the newest version is the goal

Distributions freeze a version and backport security fixes to it, so a package
that looks years old may be fully patched. `rpm -q --changelog` and Debian's
package changelog show the backports.

Chasing upstream versions by adding third-party repositories is a real trade-off,
not a free upgrade: you gain features and you take on that repository's trust and
its release cadence.

## Work it through

You need `dig` on a fresh AlmaLinux server to test name resolution. You try:

```
sudo dnf install dig
```

and get `No match for argument: dig`. The machine has a working network and the
repositories are the distribution's own.

Reason it out before reading on.

**The package is not called `dig`.** Package names describe collections; command
names describe programs, and one package usually ships several commands. `dig`
ships inside a bundle of DNS utilities, which on the RHEL family is
`bind-utils` and on Debian is `dnsutils`.

**How would you find that without knowing it?** Ask by capability rather than by
name:

```
dnf provides '*/dig'
```

which searches the repository metadata for packages containing a file whose path
ends in `dig` and returns `bind-utils`. The Debian equivalent is `apt-file search
bin/dig`, with the wrinkle that `apt-file` is itself a package you may have to
install first.

**Why did the error not say so?** Because from `dnf`'s point of view nothing
unusual happened: you asked for a package by name, no package has that name, and
it said so accurately. It has no way of knowing you were describing a command.

**The habit worth taking:** when a package manager says a name does not exist,
your next question is not "is my repository broken" but "am I searching for a
command name instead of a package name". Those two failures look identical and
have completely different fixes, and this one is much more common.

## Try it

Optional, if you have a machine handy.

1. Find your repository list: `dnf repolist`, or `cat
   /etc/apt/sources.list.d/*.sources`. Say what each entry is for.
2. Search for something you do not have installed. Read the descriptions rather
   than the names.
3. Install `tree`, then run `tree -L 2 /etc` and enjoy it briefly.
4. Find out what package owns `/usr/bin/tree`, then list every file that package
   installed.
5. Run `rpm -qf /usr/local/bin/*` or `dpkg -S /usr/local/bin/*` if anything is
   there. Notice what it says about files no package owns.
6. Remove `tree` again, and on Debian check `dpkg -l tree` afterwards to see the
   `rc` state.

**Verification step.** You have it when you can take a command name you have never
heard of, find which package provides it on both families, install it, and
confirm afterwards which repository it came from.

## Check yourself

<details class="qa">
<summary>What does <code>apt update</code> actually do, and why is it the first line of nearly every Debian install instruction?</summary>

It downloads the **package index**, the catalogue of what exists in each
configured repository and at what version, and stores it locally. It installs
and upgrades nothing.

It comes first because `apt` searches that local copy rather than the network. On
a newly built machine or container the copy is empty, so every package looks like
it does not exist, and `Unable to locate package` for something obviously present
in Debian is the result.

`dnf` and `zypper` refresh automatically when their metadata is stale, which is
why the step is invisible on those systems rather than absent.

</details>

<details class="qa">
<summary>What is the difference between <code>apt remove</code> and <code>apt purge</code>, and what does <code>rc</code> mean in <code>dpkg -l</code>?</summary>

`remove` deletes the program and leaves its configuration files. `purge` deletes
both.

`rc` is a two-character status: **r**emoved, **c**onfig files remaining. So a
package you removed still appears in `dpkg -l`, correctly, because the system
is still holding something on its behalf, and reinstalling would restore your
settings exactly as you left them.

The RHEL family has no equivalent split. `dnf remove` takes the package and
preserves *modified* config files by renaming them with an `.rpmsave` suffix,
which serves a similar purpose by a different route.

</details>

<details class="qa">
<summary>You find <code>/usr/local/bin/monitoring-agent</code> on a server you have inherited. <code>rpm -qf</code> on it reports no owning package. What does that tell you, and why does it matter?</summary>

**Somebody installed it by hand.** Every file that arrived through the package
manager is recorded in its database; a file with no owner did not come from
there.

Why it matters is patching. `dnf upgrade` updates packages, and this is not one.
It will never be patched by the routine that patches everything else, nobody will
be notified when a vulnerability is published for it, and it will not appear in
any inventory built from the package database.

Its location is at least conventional: `/usr/local` is precisely where
locally-installed software belongs, and the fact that it is not in `/usr/bin`
means whoever did it knew that much. The gap is the patching, and the fix is
to write it down and own it, or replace it with a packaged version.

</details>

<details class="qa">
<summary><code>sudo dnf install dig</code> fails with <code>No match for argument</code>. The network and repositories are fine. What is wrong and how do you find the right name?</summary>

**`dig` is a command, not a package.** It ships inside `bind-utils` on the RHEL
family and `dnsutils` on Debian, because one package usually provides several
commands and the package is named for the collection.

`dnf provides '*/dig'` searches repository metadata by file path and returns the
package that contains it. On Debian, `apt-file search bin/dig` does the same,
though `apt-file` may need installing first.

The general rule: when a package manager says a name does not exist, ask whether
you are searching by command name instead of package name before you start
suspecting the repository configuration.

</details>

<details class="qa">
<summary>Why is <code>curl https://example.com/install.sh | sudo bash</code> a worse idea than <code>dnf install</code>, given that both fetch code over the internet and run it as root?</summary>

Four differences, and the last two are the ones people underweight.

**Verification.** A package is signed and checked against a key the machine
already holds. The script is trusted because TLS said the hostname was right,
which is a different and weaker claim.

**Review.** The package is built and reviewed by the distribution. The script is
whatever that URL returned at the moment you ran it, seen by nobody.

**Inventory.** Package files are recorded in a database you can query. Script
files are not, so nothing can tell you they exist.

**Patching.** `dnf upgrade` covers packages. Nothing covers the script's
output, so it stays at the version you installed until somebody remembers it,
and it is precisely the thing nobody remembers.

</details>

## References

- [apt(8)](https://manpages.debian.org/stable/apt/apt.8.en.html) - Debian Project. Accessed 2026-08-07.
- [sources.list(5)](https://manpages.debian.org/stable/apt/sources.list.5.en.html) - Debian Project. Accessed 2026-08-07.
- [dpkg(1)](https://man7.org/linux/man-pages/man1/dpkg.1.html) - Linux man-pages project. Accessed 2026-08-07.
- [rpm(8)](https://man7.org/linux/man-pages/man8/rpm.8.html) - Linux man-pages project. Accessed 2026-08-07.
- [DNF5 command reference](https://dnf5.readthedocs.io/en/latest/commands/index.html) - DNF project. Accessed 2026-08-07.
- [Zypper usage](https://en.opensuse.org/SDB:Zypper_usage) - openSUSE. Accessed 2026-08-07.

Every block above with a distribution and architecture header was captured by running the command on a Debian 13 (trixie) container, an AlmaLinux 10.2 container and an openSUSE Leap 16.0 container. Blocks without one are illustrative.
