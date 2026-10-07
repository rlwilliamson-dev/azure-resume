---
title: "The system you cannot change"
description: "Every capture in this track was taken on a machine whose /usr is read-only and whose root filesystem is a directory named after a hash. Image-based systems, what they move where, what they give up, and why servers are drifting this way."
deck: "Read-only file system, on a machine nobody broke"
track: "linux-plus"
level: "deep"
order: 810
beyondExam: true
objectives:
  - "Say what an image-based system is and how it differs from a package-managed one"
  - "Read the deployment layout and say where the writable state lives"
  - "Explain what an update and a rollback are when the system is an image"
  - "Say what you give up, and what stops working the way you learned"
  - "Recognise the same idea under its several current names"
prerequisites: ["installing-software", "how-linux-boots"]
tags: ["linux", "linux-plus", "packaging", "immutable", "beyond-the-exam"]
updated: 2026-08-21
draft: false
examObjectives: []
sources:
  - title: "OSTree"
    url: "https://ostreedev.github.io/ostree/"
    publisher: "the OSTree project"
    accessed: 2026-08-21
    tier: 1
  - title: "rpm-ostree"
    url: "https://coreos.github.io/rpm-ostree/"
    publisher: "the rpm-ostree project"
    accessed: 2026-08-21
    tier: 1
  - title: "Fedora CoreOS documentation"
    url: "https://docs.fedoraproject.org/en-US/fedora-coreos/"
    publisher: "the Fedora Project"
    accessed: 2026-08-21
    tier: 1
  - title: "bootc"
    url: "https://bootc-dev.github.io/bootc/"
    publisher: "the bootc project"
    accessed: 2026-08-21
    tier: 1
symptoms:
  - symptom: "Read-only file system when writing to /usr on a working machine"
    anchor: "usr-is-read-only-and-that-is-the-design"
  - symptom: "A package manager that refuses to install into the running system"
    anchor: "what-you-give-up"
---

> **Before you read.** Every captured block in this track that says "on a virtual
> machine" came from a host whose `/usr` cannot be written to, whose root
> filesystem is a subdirectory named after a hash, and whose `/home` is a symbolic
> link into `/var`.
>
> **Nothing is wrong with that machine. What kind of system is it?**

The Linux this track teaches is a machine you change: install a package, edit a
file in `/etc`, restart a service. There is a second kind, it has been quietly
taking over the places where servers are deployed in numbers, and it is not on
the exam in any form. It is also the machine most of these captures were taken
on, which the track has never mentioned.

### Some words you will need

<dl class="terms">
<dt>image-based</dt>
<dd>A system whose operating system is delivered as a whole tree, not as a set of packages applied in place.</dd>
<dt>deployment</dt>
<dd>One such tree, on disk, ready to boot. A machine normally keeps two.</dd>
<dt>commit</dt>
<dd>A content-addressed version of that tree, identified by a hash of everything in it.</dd>
<dt>layering</dt>
<dd>Adding packages on top of the delivered image, which produces a new local commit rather than modifying the running one.</dd>
<dt>drift</dt>
<dd>The accumulated difference between what a machine was built as and what it is now. The thing this design is aimed at.</dd>
<dt>rebase</dt>
<dd>Switching to a different image stream entirely, which is what an upgrade between major versions looks like here.</dd>
</dl>

## What breaks without this

**Familiar commands fail in unfamiliar ways.** `dnf install` refuses, writing to
`/usr` returns a read-only error, and none of the usual reasons apply.

**You cannot reason about the machine.** The mental model from the rest of this
track predicts the wrong things about where state lives and what an update does.

**A design decision goes unexamined.** These systems trade away a real capability
for a real guarantee, and choosing one without knowing which is which is how a
team ends up fighting its own platform.

## The root filesystem is a directory named after a hash

<details class="predict">
<summary>A normal Linux machine mounts a partition at /. What does a machine like this one mount there instead?</summary>

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ ostree admin status; echo "--- and what the root filesystem actually is ---"; findmnt -no SOURCE / | cut -c1-96
* fedora-coreos a995df5379537ae1adbe9b6841a4330a390d0b11421c1715c67739d26a1cbd3d.0
    origin: <unknown origin type>
--- and what the root filesystem actually is ---
/dev/vda4[/ostree/deploy/fedora-coreos/deploy/a995df5379537ae1adbe9b6841a4330a390d0b11421c1715c6
```

</details>

Two facts in four lines. The system identifies itself by a **content hash** rather
than a version, and the root filesystem is a bind of a directory inside
`/ostree/deploy/` on an ordinary XFS partition.

That directory is the whole operating system as one immutable tree. Updating does
not modify it. Updating writes a **second** directory alongside it, hashed
differently, and changes which one the bootloader points at. The old one stays,
which is what makes a rollback a boot menu entry rather than a restore.

The `*` marks the deployment currently booted. A machine that has updated shows
two entries here, and the one to boot next is a property of the bootloader rather
than of anything inside either tree.

<figure class="learn-figure">
<svg viewBox="0 0 720 244" role="img" aria-labelledby="deploy-title" style="width:100%;height:auto;">
<title id="deploy-title">One partition holding two deployment trees, each named by a content hash, with the bootloader pointing at the one currently booted</title>
<g fill="currentColor">
<text x="14" y="24" font-size="11">an update writes a second tree and moves one pointer</text>
<rect x="24" y="52" width="400" height="152" rx="4" fill="currentColor" fill-opacity="0.04" stroke="currentColor" stroke-opacity="0.3"/>
<text x="36" y="72" font-size="10" fill-opacity="0.7">/dev/vda4, an ordinary XFS partition</text>
<rect x="44" y="86" width="360" height="48" rx="3" fill="var(--accent)" fill-opacity="0.18" stroke="var(--accent)" stroke-width="1.6"/>
<text x="224" y="106" text-anchor="middle" font-size="10.5" fill="var(--accent)">/ostree/deploy/fedora-coreos/deploy/a995df53...</text>
<text x="224" y="122" text-anchor="middle" font-size="10" fill="var(--accent)">booted now</text>
<rect x="44" y="146" width="360" height="48" rx="3" fill="currentColor" fill-opacity="0.08" stroke="currentColor" stroke-opacity="0.45"/>
<text x="224" y="166" text-anchor="middle" font-size="10.5">/ostree/deploy/fedora-coreos/deploy/7c14b0e2...</text>
<text x="224" y="182" text-anchor="middle" font-size="10" fill-opacity="0.75">the previous one, still here</text>
<rect x="500" y="86" width="196" height="48" rx="3" fill="currentColor" fill-opacity="0.08" stroke="currentColor" stroke-opacity="0.45"/>
<text x="598" y="115" text-anchor="middle" font-size="10.5">the bootloader</text>
<line x1="500" y1="110" x2="410" y2="110" stroke="var(--accent)" stroke-opacity="0.8" stroke-width="1.6"/>
<path d="M416 110 l -9 -4 l 0 8 z" fill="var(--accent)"/>
<text x="500" y="166" font-size="10" fill-opacity="0.8">rolling back moves this arrow</text>
<text x="500" y="182" font-size="10" fill-opacity="0.8">to the box below</text>
<text x="14" y="226" font-size="10" fill-opacity="0.75">the second hash is illustrative; this machine has only ever run one deployment</text>
</g>
</svg>
<figcaption>Nothing is modified by an update and nothing is deleted by one. A new tree is written into the same partition under its own hash, the bootloader is told to use it, and the machine reboots into an operating system that was assembled somewhere else and verified before it arrived. The old tree stays until a later update reclaims it, which is why a rollback costs a reboot rather than a restore, and why the two entries in an ostree admin status are worth reading before any risky change.</figcaption>
</figure>

## Where the writable state went

If `/usr` cannot be written, everything a system normally keeps there has to be
somewhere else, and the layout says exactly where.

<details class="predict">
<summary>Six directories on this machine. Three of them are symbolic links. Predict which three, and where each one points.</summary>

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ ls -ld /bin /sbin /lib /home /etc /var
lrwxrwxrwx.  2 root root    7 Aug  1  2022 /bin -> usr/bin
drwxr-xr-x. 94 root root 8192 Aug  8 13:21 /etc
lrwxrwxrwx.  2 root root    8 Aug  1  2022 /home -> var/home
lrwxrwxrwx.  2 root root    7 Aug  1  2022 /lib -> usr/lib
lrwxrwxrwx.  2 root root    8 Aug  1  2022 /sbin -> usr/sbin
drwxr-xr-x. 25 root root 4096 Aug  7 14:14 /var
```

</details>

`/bin`, `/sbin` and `/lib` point into `/usr`, which is the usr-merge that topic 04
covers and is not the interesting part. **`/home -> var/home` is the interesting
part**, and it is the tell that identifies one of these systems at a glance.

The rule underneath is a three-way split. `/usr` is the image: immutable, replaced
wholesale, identical on every machine running the same commit. `/etc` is
configuration: writable, and merged intelligently when the image changes, so your
edits survive an update and files you never touched follow the new image. `/var`
is state: writable, never touched by an update, and the only place anything is
expected to persist.

Which is why `/home` is a link into `/var`. Home directories are state, and on
this design state has exactly one home.

## /usr is read-only, and that is the design

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ findmnt -no TARGET,OPTIONS /usr; echo "--- so what happens if you try ---"; touch /usr/local-change; echo "exit status $?"
/usr ro,relatime,seclabel,inode64,logbufs=8,logbsize=32k,prjquota
--- so what happens if you try ---
touch: cannot touch '/usr/local-change': Read-only file system
exit status 1
```

Not a fault, not a full disk, not a permissions problem. The mount is `ro` and
there is no combination of privileges that changes it, because the guarantee is
the point: two machines running the same commit have byte-identical operating
systems, and that is only true if nothing can quietly edit one of them.

<details class="deeper">
<summary>If you administer these: how to install a package anyway, and what it costs</summary>

You can install packages, and the mechanism explains the whole model.

`rpm-ostree install` does not put files in `/usr`. It takes the image you are
running, adds the package to it, produces a new local commit with a new hash, and
stages that as the deployment for the next boot. The running system is untouched
and the change appears when you reboot. That is called layering, and a machine
with layered packages reports them separately from the base image, so the drift
is visible rather than invisible.

Two costs come with it. The first is the reboot, which is the part people
object to and is also the part that makes the guarantee real: a change that
required a reboot is a change nobody made by accident at three in the morning.
The second is that layering is a local modification to a shared image, and every
layered package is a small piece of the uniformity you adopted this system for.
A fleet where every machine layers a different set has reinvented drift with more
steps.

The direction the tooling has moved is to make layering unnecessary by building
the image itself. If the package is needed, it belongs in the image the fleet
boots, built once, tested once, and rolled out as a unit. Which is the same
argument the container ecosystem made about application dependencies, arriving a
decade later at the operating system.

For genuinely local, genuinely temporary work there is a third answer that
sidesteps all of it: run it in a container. On these systems that is not a
workaround, it is the expected way to get a tool onto a machine without changing
the machine.

</details>

## What an update is here

On a package-managed system an update is thousands of small changes applied to a
running machine, and the machine is different afterwards in ways that depend on
what it was before. Two servers built the same way a year apart, updated on
different schedules, are not the same system by the end.

On an image-based system an update is: fetch a new tree, write it alongside the
old one, point the bootloader at it, reboot. The machine afterwards is the image,
exactly, plus whatever is in `/etc` and `/var`. Two servers running the same
commit are the same system, and that is checkable by comparing two hashes rather
than by comparing two package lists.

The rollback follows from the same structure. The previous deployment is still on
disk, so going back is selecting it at boot, and it is a complete return rather
than an attempt to undo a set of changes. Anybody who has tried to reverse a bad
update on a conventional system knows why that distinction is worth the
constraints.

<details class="deeper">
<summary>If you are wondering how this differs from a snapshot: because it looks similar and behaves differently</summary>

Snapshots on btrfs or ZFS, and LVM snapshots from topic 14, give you a previous
state to return to, so the obvious question is what an image-based system adds.

The difference is where the state came from. A snapshot captures whatever the
machine happened to be at that moment, including every local change, every
half-finished configuration, and every difference from its neighbours. Rolling
back returns you to that machine's own past. An image-based deployment is a tree
somebody built deliberately, elsewhere, and every machine that boots it gets the
identical thing. Rolling back returns you to a known build rather than to your own
history.

That difference shows up in the questions each can answer. A snapshot can tell you
what changed on this machine since Tuesday. An image can tell you that these four
hundred machines are running exactly the same operating system, which no amount of
snapshotting establishes.

They also compose rather than compete: an image-based system on a snapshotting
filesystem is a reasonable arrangement, with the image handling the operating
system and snapshots handling `/var`.

</details>

## What you give up

This is a trade and the honest way to describe it is by what stops working.

**Editing the system in place.** Every runbook that says to edit a file under
`/usr`, drop a binary in `/usr/local/bin`, or patch a vendor script needs
rewriting. `/usr/local` is a symlink into `/var` on these systems specifically so
that some of those keep working, which tells you how common the habit is.

**Immediate installation.** A package you need now arrives after a reboot, unless
you run it in a container instead.

**Some vendor software.** Anything whose installer writes into `/opt` or `/usr`
at install time, and plenty of agents do, either needs a container, needs
layering, or needs a conversation with the vendor. This is the practical obstacle
that decides most adoptions.

**The debugging habits from the rest of this track**, partly. Reading logs,
inspecting units, and tracing processes are unchanged. Fixing something by editing
it where it lives is not.

What you get for that is worth stating just as plainly: a fleet where every
machine is provably the same, an update that is a single atomic switch, a rollback
that is a boot entry, and a class of incident, the one that begins with "somebody
changed something on that box", that stops being possible.

## The same idea, several names

<details class="deeper">
<summary>If you are trying to follow the ecosystem: which names refer to the same thing</summary>

The vocabulary is unusually confusing because the projects overlap and the
marketing does not match the layering.

**OSTree** is the underlying mechanism: a content-addressed store of filesystem
trees with atomic deployment and rollback. It is sometimes described as git for
operating system binaries, which is a reasonable one-line summary of the data
model.

**rpm-ostree** is OSTree plus RPM understanding, which is what gives you package
layering on top of an image and the ability to build images from RPMs.

**Fedora CoreOS, Silverblue and their relatives** are distributions built on that,
differing mostly in what is in the image and who it is aimed at. CoreOS is the
server one and is the machine these captures ran on.

**bootc** is the current direction and the one worth watching, because it changes
the packaging rather than the mechanism. The operating system is built and shipped
as an ordinary container image, using the same registries, signing and build
pipelines as application containers, and the machine boots it rather than running
it. Red Hat's image mode for RHEL is the commercial form of the same idea.

The thing to hold on to across all of them is that the mechanism has been stable
for years while the packaging keeps changing, and every one of them is doing what
this page describes: an immutable `/usr`, a merged `/etc`, a writable `/var`, and
an update that swaps a tree and reboots.

</details>

## Across distributions

Every family has one of these and no two of them chose the same mechanism, which
is why the vocabulary does not transfer.

| | RHEL family | Debian family |
| --- | --- | --- |
| The image-based system | Fedora CoreOS, Silverblue, and RHEL image mode | Ubuntu Core |
| Mechanism | OSTree deployments, moving to bootc container images | Snaps, with the operating system delivered as a read-only base snap |
| Add software to a running system | Layer a package, which applies at the next boot | Install a snap, which is confined rather than merged into the system |
| Roll back | Select the previous deployment at boot | Revert to the previous snap revision |

**openSUSE is the interesting third answer.** MicroOS and SUSE's transactional
systems reach the same place through btrfs snapshots rather than through a
content-addressed store: a transactional update writes into a new snapshot, and
the machine boots that snapshot next time. The properties a user cares about,
atomic update and a rollback that is a boot choice, are the same, and none of the
commands are.

Everything in this topic other than the command names is common to all three, so
recognising the shape matters more than knowing any one of them. Read-only
operating system, writable configuration, persistent state somewhere separate,
and an update that swaps a whole tree instead of editing one.

## Prove it

**Look at where your own root filesystem comes from.** `findmnt -no SOURCE /` on
any machine. On a conventional one it names a device or a volume, and on one of
these it names a subdirectory with a hash in it. It is the fastest way to know
which kind of machine you are on.

**Check whether `/usr` is writable.** `findmnt -no OPTIONS /usr` and look for
`ro`. On a conventional system it will not be there, and the fact that it can be
is the whole idea.

**Read the three-way split in the OSTree documentation.** The project's own pages
are explicit about which directories are immutable, which are merged, and which
are yours. Reading that once removes the guesswork about where anything is
supposed to live.

## What trips people up

### 1. Reading the read-only error as a fault

`Read-only file system` on `/usr` is the machine working. Nothing is broken and no
remount will fix it, because the guarantee depends on it.

### 2. Expecting an install to take effect now

Layering builds a new deployment and stages it. The package is there after the
reboot, and a script that installs and then immediately uses the tool will fail.

### 3. Putting state in the wrong place

Anything expected to persist belongs in `/var`. Something written into a
directory that the next image replaces is gone at the next update, and the update
is not at fault.

### 4. Treating layered packages as free

Every layered package is a local difference from the fleet, which is the thing
this system was adopted to remove. A few are fine and a habit of it is drift
wearing a new name.

### 5. Confusing the deployment hash with a version

It identifies content, not release order. Two machines with the same hash are
identical and a higher hash means nothing at all.

### 6. Assuming vendor agents will install

Anything whose installer writes into `/usr` or `/opt` at install time needs a
different approach, and finding out which of your agents do is the first thing to
check before proposing one of these systems.

## Work it through

A team proposes moving a fleet of two hundred application servers to an
image-based system. The applications already run in containers. The security team
likes the idea, and the operations team has questions.

Take the applications first, because they are the easy part. If they already run
in containers, they were never installing into `/usr` and nothing about them
changes. That is why the container-first shops adopted this earliest: most of the
work was already done.

Then inventory what else touches those machines. Monitoring agents, backup
agents, endpoint security, configuration management, and whatever a vendor
support case has asked somebody to install over the years. Each one is either
containerisable, layerable, or a blocker, and the blockers are where the project
actually lives. This inventory is the whole feasibility study and it can be done
in a week.

Then look at how changes reach those machines today. If the answer is a
configuration management tool converging state on running systems, that model does
not translate directly: the equivalent here is building the change into the image
and rolling it out. Teams that skip this step end up layering packages from a
playbook, which works and gives up the property they were buying.

And ask about the reboot, because it is the cultural obstacle rather than the
technical one. An estate that already replaces machines rather than patching them
will not notice. An estate where a reboot needs a change request and a window will
find that every operating system change now needs one, and that is a real cost to
weigh rather than to dismiss.

## Try it

**Run the three commands from this page on any machine you have.**
`findmnt -no SOURCE /`, `findmnt -no OPTIONS /usr`, and `ls -ld /home`. Three
seconds, and you will know which kind of system you are looking at forever
afterwards.

**Boot one.** Fedora CoreOS and Silverblue are both free and both run in a
virtual machine. Installing something and having to reboot for it is the moment
the model stops being abstract.

**Look at what your agents install.** Pick the three that would have to run on
such a machine and find out where their installers write. That is the answer to
whether any of this is available to you.

## Check yourself

<details class="qa">
<summary>What does findmnt report as the source of / on one of these systems?</summary>

A subdirectory of an ordinary partition, under `/ostree/deploy/`, named after the
content hash of the deployed tree. The operating system is a directory rather than
a filesystem of its own.

</details>

<details class="qa">
<summary>Why is /home a symbolic link into /var?</summary>

Because `/var` is the only writable, persistent part of the design. `/usr` is the
image and is replaced by updates, `/etc` is merged, and anything expected to
survive an update has to be in `/var`. Home directories are state, so that is
where they go.

</details>

<details class="qa">
<summary>What happens when you install a package on one of these systems?</summary>

A new local commit is built from the running image plus the package, and staged as
the next deployment. The running system is unchanged and the package appears after
a reboot.

</details>

<details class="qa">
<summary>How does a rollback differ from restoring a snapshot?</summary>

The previous deployment is a tree somebody built deliberately and every machine
running it is identical. A snapshot is whatever this machine happened to be at
that moment, including its own local changes. One returns you to a known build,
the other to your own history.

</details>

<details class="qa">
<summary>A script installs a tool and then runs it, and fails on one of these systems. Why?</summary>

Because the install staged a new deployment rather than modifying the running one.
The tool exists after the next boot and does not exist yet. Running it in a
container is the usual answer when it is needed immediately.

</details>

## References

- [OSTree](https://ostreedev.github.io/ostree/) - the OSTree project, the content-addressed store, the deployment model, and which directories are immutable, merged or writable. Free. Accessed 2026-08-21.
- [rpm-ostree](https://coreos.github.io/rpm-ostree/) - the rpm-ostree project, package layering and how it produces a new commit. Free. Accessed 2026-08-21.
- [Fedora CoreOS documentation](https://docs.fedoraproject.org/en-US/fedora-coreos/) - the Fedora Project, the distribution these captures were taken on. Free. Accessed 2026-08-21.
- [bootc](https://bootc-dev.github.io/bootc/) - the bootc project, shipping the operating system as a container image. Free. Accessed 2026-08-21.

**Where the output came from.** Three captured blocks through `capture.sh vm`,
which runs on the podman machine itself rather than in a container, because the
subject is that machine's own layout. Everything on this page is that host
describing itself, and the reason a topic about image-based systems could be
written from this repository without building anything is that the capture
infrastructure has been running on one from the start.

**Why this is not in the lesson count.** The objectives describe package
management on systems you modify in place, and nothing in them refers to
image-based systems in any form. This page exists because the machine behind a
third of this track's captures is one, and until now the track has said nothing
about it.
