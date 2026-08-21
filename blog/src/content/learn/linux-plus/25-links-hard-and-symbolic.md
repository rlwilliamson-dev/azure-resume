---
title: "Links, hard and symbolic"
description: "Delete a file and it is still there under another name. What a filename actually is, the two kinds of link and how they fail differently, and why half of /bin is a shortcut to somewhere else."
deck: "Two names, one file"
track: "linux-plus"
level: "working"
order: 260
objectives:
  - "Explain what a filename is, given that a file can have several"
  - "Choose between a hard link and a symbolic link from a stated requirement"
  - "Predict what happens to each kind when the original is deleted"
  - "Recognise a broken symlink and find what it was pointing at"
prerequisites: ["virtualization"]
tags: ["linux", "linux-plus", "filesystem", "links", "inodes"]
updated: 2026-08-07
draft: false
examObjectives:
  - exam: "xk0-006"
    domain: "2.0"
    objective: "2.1"
sources:
  - title: "ln(1)"
    url: "https://man7.org/linux/man-pages/man1/ln.1.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "symlink(7)"
    url: "https://man7.org/linux/man-pages/man7/symlink.7.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "inode(7)"
    url: "https://man7.org/linux/man-pages/man7/inode.7.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "readlink(1)"
    url: "https://man7.org/linux/man-pages/man1/readlink.1.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "realpath(1)"
    url: "https://man7.org/linux/man-pages/man1/realpath.1.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "unlink(2)"
    url: "https://man7.org/linux/man-pages/man2/unlink.2.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
symptoms:
  - symptom: "Deleted a large file and the disk space did not come back"
    anchor: "3-you-deleted-it-and-the-space-did-not-come-back"
  - symptom: "Symlink points at a file that exists but does not resolve"
    anchor: "2-a-relative-symlink-that-moved"
---

> **Before you read.** Make a file. Give it a second name. Delete the first name.
>
> The file is still there, under the second name, complete and unharmed. Delete
> the second name as well and it is gone for good.
>
> That is not a copy. There was only ever one file, and it never occupied
> twice the space.
>
> **So what is a filename, if a file can have several and losing one costs
> nothing?**

A filename is a pointer, and the file is somewhere else. Once that lands, several
things that looked arbitrary stop being arbitrary: why `rm` is really called
unlink, why deleting a huge file sometimes frees no space at all, and why so much
of a Linux system is one thing wearing several names.

### Some words you will need

<dl class="terms">
<dt>inode</dt>
<dd>The actual file: its permissions, owner, timestamps, size, and where its data sits. It has a number and no name.</dd>
<dt>directory entry</dt>
<dd>A name paired with an inode number. This is what a filename is.</dd>
<dt>hard link</dt>
<dd>Another directory entry pointing at the same inode. A second real name.</dd>
<dt>symbolic link</dt>
<dd>A small file whose contents are a path. A signpost, which can point at nothing.</dd>
<dt>link count</dt>
<dd>How many names an inode has. When it reaches zero the file is freed.</dd>
</dl>

## What breaks without this

**You cannot explain the disk.** A deleted file that frees no space, or a
directory whose contents total more than the filesystem holds, both come down to
this and neither makes sense without it.

**You break things by moving them.** A relative symlink that works becomes broken
when either end moves, and the error names a file that plainly exists.

**You cannot read a Linux system.** `/bin`, `/lib`, and `/sbin` are symlinks on
every current distribution, and `/etc/alternatives` is a whole directory of them
deciding which `java` you get.

## What a filename really is

A file's data and metadata live in an **inode**, which is numbered. A filename
is an entry in a directory that points at an inode. `ls -li` prints that
number in the first column, and the second column is the **link count**, how
many names point at that inode.

Three names are made below: the original, a hard link, and a symbolic link.

<details class="predict">
<summary>Given that a name points at an inode, which of the three share a number, and what will the link count be on each?</summary>

```bash
# Debian 13 (trixie), x86_64
$ cd /tmp; echo original > report.txt; ln report.txt hardlink.txt; ln -s report.txt softlink.txt; ls -li report.txt hardlink.txt softlink.txt
151018359 -rw-r--r--. 2 root root  9 Aug  8 03:18 hardlink.txt
151018359 -rw-r--r--. 2 root root  9 Aug  8 03:18 report.txt
151018360 lrwxrwxrwx. 1 root root 10 Aug  8 03:18 softlink.txt -> report.txt
```

</details>

The inode number settles everything.

<figure class="learn-figure">
<svg viewBox="0 0 720 270" role="img" aria-labelledby="ln-title ln-desc" style="width:100%;height:auto;">
<title id="ln-title">Three names, two inodes, and what each name actually points at</title>
<desc id="ln-desc">Three directory entries sit on the left. Both report.txt and hardlink.txt point at inode 151018359, which holds the file's data and carries a link count of 2. That is what a hard link is: two names for one inode, with neither being the original. The third entry, softlink.txt, points at a separate inode numbered 151018360 with a link count of 1, whose entire contents are the ten character string "report.txt". Resolving the symlink therefore means looking that name up again, shown as a dashed arrow running back to the report.txt directory entry rather than to the inode.</desc>
<g>
<text x="30" y="30" font-size="10" fill="currentColor" fill-opacity="0.65">directory entries</text>
<text x="400" y="30" font-size="10" fill="currentColor" fill-opacity="0.65">inodes</text>
<text x="40" y="74" font-size="11.5" fill="currentColor">report.txt</text>
<text x="40" y="124" font-size="11.5" fill="currentColor">hardlink.txt</text>
<text x="40" y="194" font-size="11.5" fill="currentColor">softlink.txt</text>
<rect x="396" y="46" width="278" height="72" rx="4" fill="var(--accent)" fill-opacity="0.1" stroke="var(--accent)" stroke-opacity="0.9" stroke-width="1.8"/>
<text x="412" y="70" font-size="11.5" fill="var(--accent)">inode 151018359</text>
<text x="412" y="88" font-size="10" fill="currentColor" fill-opacity="0.75">link count 2</text>
<text x="412" y="106" font-size="10" fill="currentColor" fill-opacity="0.65">data: original</text>
<rect x="396" y="160" width="278" height="66" rx="4" fill="none" stroke="currentColor" stroke-opacity="0.4" stroke-dasharray="5 3"/>
<text x="412" y="184" font-size="11.5" fill="currentColor">inode 151018360</text>
<text x="412" y="202" font-size="10" fill="currentColor" fill-opacity="0.75">link count 1</text>
<text x="412" y="220" font-size="10" fill="currentColor" fill-opacity="0.65">data: the 10 byte string report.txt</text>
</g>
<g stroke="currentColor" stroke-opacity="0.5" fill="none" stroke-width="1.3">
<path d="M170 70 L392 70 M386 66 L393 70 L386 74"/>
<path d="M180 120 L300 120 L300 92 L392 92 M386 88 L393 92 L386 96"/>
<path d="M170 190 L392 190 M386 186 L393 190 L386 194"/>
</g>
<g stroke="var(--accent)" stroke-opacity="0.85" fill="none" stroke-width="1.5" stroke-dasharray="5 3">
<path d="M400 244 L24 244 L24 66 L34 66 M29 61 L35 66 L29 71"/>
</g>
<text x="410" y="248" font-size="10" fill="var(--accent)">resolved by name, not by inode</text>
</svg>
<figcaption>Two names on one inode is the whole of a hard link, and the link count is how the filesystem knows. The symlink is a separate file whose contents are a name, which is why the dashed arrow lands back on the directory entry rather than on the data. Move or delete <code>report.txt</code> and the hard link still has the file, while the symlink is left holding a string that no longer resolves.</figcaption>
</figure>

**`report.txt` and `hardlink.txt` share inode 151018359.** Same number, same
permissions, same size, same timestamp, because they are not two files. They
are two names for one file, and neither is the original in any sense the
filesystem records.

The second column is `2`, the link count. That inode has two names.

`softlink.txt` is a different file entirely, inode 151018360, type `l`, and
`ls` shows what it points at. Its size is 10 bytes, which is the length of the
string `report.txt`, because that string *is* its contents.

Look at the symlink's permissions: `lrwxrwxrwx`. Symlinks are always mode 777 and
it means nothing. The permission that decides access is the one on the **target**,
so setting a symlink's mode is a thing you can do and it changes nothing.

<details class="deeper">
<summary>If you already administer Linux: what a directory's link count is telling you, and why you cannot hard-link one</summary>

The link count is not only useful on files. Run `ls -ld` on any directory and the
count is never 1.

**A directory's link count is two plus the number of subdirectories it has.** The
directory's own name in its parent is one; the `.` entry inside it is two; and every
subdirectory's `..` points back at it, adding one each. So a link count of 7 on
`/var/log` means five subdirectories, without reading the directory at all. It is
occasionally the fastest way to answer "how many subdirectories" on a directory with
a million files in it, since `stat` is one syscall and `find -type d` is a full walk.

That also explains why `find` has an optimisation you may have seen: on a filesystem
that maintains the count honestly, `find` can stop descending once it has seen as
many subdirectories as the count predicted. `-noleaf` exists to turn that off for
filesystems that do not, such as CD-ROMs and some network mounts.

**Hard links to directories are forbidden**, and the reason is that the
filesystem is a tree only by convention. Nothing in the on-disk structure
prevents a cycle; what prevents it is that only the kernel creates directory
entries pointing at directories, and it only ever creates the tree-shaped
ones. Allow a user to make an arbitrary one and you can build a loop, a
directory that contains itself, and then every tool that walks the tree runs
forever, `rm -r` cannot terminate, and `fsck` cannot tell the loop from
corruption. There is no reference count that can free it either, because the
cycle keeps its own count above zero.

macOS permits it for Time Machine, under tight restrictions and with a history of
problems. Linux does not, for anybody, including root:

```
ln /var/log /tmp/loglink
ln: /var/log: hard link not allowed for directory
```

**`..` is the exception that proves the design.** It is a real hard link to the
parent directory, created by the kernel when the directory is made, and it is safe
only because the kernel guarantees it always points *up*. Bind mounts are the
supported way to get the effect people want from directory hard links, and they
live in the mount table rather than on disk.

</details>

## How they fail differently

<details class="predict">
<summary>Delete <code>report.txt</code>, the name we made the links from. What happens to each link? Use the inode numbers above to reason it out.</summary>

```bash
# Debian 13 (trixie), x86_64
$ cd /tmp; echo original > report.txt; ln report.txt hardlink.txt; ln -s report.txt softlink.txt; rm report.txt; echo '--- the hard link still works ---'; cat hardlink.txt; ls -li hardlink.txt; echo '--- the symlink does not ---'; cat softlink.txt; ls -l softlink.txt
--- the hard link still works ---
original
234895593 -rw-r--r--. 1 root root 9 Aug  8 03:18 hardlink.txt
--- the symlink does not ---
cat: softlink.txt: No such file or directory
lrwxrwxrwx. 1 root root 10 Aug  8 03:18 softlink.txt -> report.txt
```

**The hard link is completely unaffected**, and its link count has dropped
from 2 to 1. Removing a name decremented the count; the inode still had one
name left, so nothing was freed. `report.txt` was never special. It was one of
two equal names, and now there is one.

**The symlink is broken**, and this is the part worth looking at closely. It still
exists. `ls -l` still lists it and still shows its target. It is a perfectly
healthy file whose contents are the string `report.txt`, and there is simply
nothing by that name any more.

So `cat` reports `No such file or directory`, and note that message is about
the *target*, not the link, which is why it is confusing: the thing you named
is right there.

That is the whole difference:

- **A hard link is a name.** All names are equal; the file survives while any
  remain.
- **A symbolic link is a signpost.** It can point anywhere, including at nothing,
  and it does not keep its target alive.

Broken symlinks show up in colour in most terminals, and `find /path -xtype l`
lists them all.

</details>

## Choosing between them

| | Hard link | Symbolic link |
| --- | --- | --- |
| Is | Another name for the same inode | A small file holding a path |
| Survives the original being deleted | **Yes** | No, it breaks |
| Can cross filesystems | **No** | Yes |
| Can point at a directory | No, not for you | Yes |
| Can point at something that does not exist | No | Yes |
| Shows in `ls -l` as | An ordinary file | `l` type, with the target |
| Made with | `ln target name` | `ln -s target name` |

**The cross-filesystem limit is the one that decides it in practice**, because
inode numbers are only unique within one filesystem:

```bash
# Debian 13 (trixie), x86_64
$ cd /tmp; mkdir -p a/b; echo hi > a/b/real.txt; ln -s a/b/real.txt rel.txt; echo '--- readlink shows the target as stored ---'; readlink rel.txt; echo '--- realpath resolves the whole chain ---'; realpath rel.txt; echo '--- and a hard link across filesystems ---'; ln /etc/hostname /dev/shm/try.txt
--- readlink shows the target as stored ---
a/b/real.txt
--- realpath resolves the whole chain ---
/tmp/a/b/real.txt
--- and a hard link across filesystems ---
ln: failed to create hard link '/dev/shm/try.txt' => '/etc/hostname': Invalid cross-device link
```

**`Invalid cross-device link`** is the error, and it means exactly what it says: a
directory entry can only reference an inode in its own filesystem, so a name on
one filesystem cannot point at a file on another. A symlink can, because it stores
a path rather than an inode number.

**`readlink` and `realpath` answer different questions.** `readlink` prints
what the link literally stores: `a/b/real.txt`, a relative path. `realpath`
follows it all the way, resolving every symlink and `..` along the way, and
gives you the absolute answer. When a symlink chain is misbehaving, `realpath`
tells you where you actually end up and `readlink` tells you what somebody
wrote.

**Use a symlink unless you specifically need a hard link.** They are visible
in `ls`, they work across filesystems and onto directories, and a broken one
is obvious. Hard links are for when the link must survive the original being
removed, which is a real requirement and a narrow one.

<details class="deeper">
<summary>If you already administer Linux: what rm really does, and the deleted file still using disk</summary>

**`rm` calls `unlink(2)`**, which removes a directory entry and decrements the
inode's link count. The data is freed only when the count reaches zero **and no
process has the file open**. That second condition is the one that catches people.

A web server holding a 40 GB log open, and somebody runs `rm` on it. The name
is gone, `du` cannot see it, and `df` still reports the space as used, because
the open file descriptor is another reference, and the kernel will not free
the blocks while it exists.

**`lsof +L1`** lists exactly these: files with a link count below one that are
still open. The fix is to restart or signal the process, not to delete harder.

```
lsof +L1
ls -l /proc/1234/fd | grep deleted
```

The second form shows it from the process side, and `/proc/<pid>/fd/N` can
still be read, which is how you recover a file somebody deleted while it is
still open, by copying it back out before the process exits.

**This is also why `logrotate` has `copytruncate`.** Renaming a log and creating a
new one leaves the daemon writing to the old inode by its open descriptor;
truncating in place keeps the same inode so the writes continue into the file
everyone can see. The right answer is signalling the daemon to reopen its log,
which is what most rotate configurations do.

**`stat` shows the link count** as `Links:`, and comparing it against what you
expect is how you notice that a "copy" is actually a hard link. `find -samefile
/path/to/file` finds every other name for the same inode.

</details>

## Why so much of the system is a symlink

Symlinks are load-bearing infrastructure on a modern Linux system, not a
convenience.

**`/bin`, `/sbin`, and `/lib` are symlinks into `/usr`** on every current
distribution, the usr-merge from lesson 04. `ls -ld /bin` shows it. That is
why `/bin/ls` and `/usr/bin/ls` are the same program and why `dpkg -S /bin/ls`
behaves oddly.

`/etc/alternatives` decides which of several programs a generic name means.
`java`, `editor`, `python3` on some systems: `/usr/bin/java` is a symlink to
`/etc/alternatives/java`, which is a symlink to a specific version. Two hops,
and `update-alternatives --config java` repoints the middle one. That is how a
machine switches Java versions without moving any files.

`/etc/localtime` is a symlink to a file under `/usr/share/zoneinfo`.
`timedatectl set-timezone` just repoints it.

Shared libraries use a chain: `libssl.so.3` points at `libssl.so.3.0.14`, so
software links against the stable name and the specific version can change
underneath it.

**`/proc/<pid>/exe` and `/proc/<pid>/cwd`** are symlinks the kernel synthesises,
pointing at the binary a process is running and its working directory. They are
how you find out what an unidentified process actually is.

<details class="deeper">
<summary>If you already administer Linux: symlink attacks, and the flags that defend against them</summary>

A symlink is a redirection that anyone who can write to a directory can create,
which makes it an attack primitive rather than a curiosity.

**The classic:** a privileged process writes to a predictable path in a
world-writable directory, `/tmp/app.log`, and an attacker replaces that path
with a symlink to `/etc/shadow` between the check and the write. The
privileged process follows it and truncates the file. This is a **TOCTOU**
race, and it is why `/tmp` handling has so many special rules.

**Three defences, all worth recognising:**

`fs.protected_symlinks=1` in `sysctl`, on by default on current kernels, makes
the kernel refuse to follow a symlink in a sticky world-writable directory
when the link's owner differs from the directory's owner.
`fs.protected_hardlinks=1` does the equivalent for hard links, stopping an
unprivileged user linking to a file they cannot read, which was otherwise a
way to preserve a file past its deletion.

**`mktemp`** rather than a predictable name. `mktemp -d` gives a directory with a
random name and mode 700, which removes the race entirely.

**`O_NOFOLLOW`** at the syscall level, and its command-line equivalents: `cp -P`
copies the link rather than the target, `rsync --safe-links` refuses links
pointing outside the tree, `find -P` does not follow, and `tar` refuses absolute
and `../` paths on extraction by default.

**The audit angle:** `find / -type l -xtype l` lists broken symlinks across a
system, and a broken symlink in a privileged path is worth understanding rather
than deleting, because something intended to be there is not.

</details>

## Across distributions

| | RHEL family | Debian family |
| --- | --- | --- |
| `/bin`, `/sbin`, `/lib` | Symlinks into `/usr` | Symlinks into `/usr` |
| Alternatives system | `alternatives` | `update-alternatives` |
| Alternatives directory | `/etc/alternatives` | `/etc/alternatives` |
| `ls` colours broken links | Yes, usually red | Yes, usually red |

The command name is the only real difference and it is enough to break a script.
`alternatives --config java` on RHEL, `update-alternatives --config java` on
Debian, same mechanism underneath.

## Prove it

```bash
# Are these two names the same file
ls -li file1 file2          # compare inode numbers
stat -c '%i %h %n' file1 file2   # inode, link count, name

# Every name this inode has
find /path -samefile /path/to/file

# What does this symlink point at, and where do I actually end up
readlink linkname
readlink -f linkname
realpath linkname

# Every broken symlink under here
find /path -xtype l

# Deleted but still open, and still using disk
sudo lsof +L1
```

**`stat -c '%i %h %n'` is the compact version of the whole lesson**: inode, link
count, name. Two files with the same inode are one file; a link count above 1
means other names exist somewhere.

## What trips people up

### 1. Expecting `cp` to make a link

`cp` copies data and uses twice the space. `cp -l` makes hard links instead and
`cp -s` makes symlinks, which is what you want when duplicating a large tree that
does not need to diverge.

`cp -a` preserves symlinks as symlinks; plain `cp` follows them and copies the
target, which quietly turns a 4-byte link into a 4 GB file.

### 2. A relative symlink that moved

`ln -s ../config/app.conf link` stores the literal string `../config/app.conf`.
Move the *link* and it now resolves relative to somewhere else. Move the target
and it breaks.

`ln -s "$(realpath target)" link` stores an absolute path, which survives the link
moving and breaks if the target does. Neither is safe from everything; pick based
on which end is more likely to move. Relative links inside a tree that moves as a
unit are the case where relative wins.

### 3. You deleted it and the space did not come back

A process still has the file open. The name is gone, the inode is not.

`sudo lsof +L1` names the process. Restart it, or signal it to reopen its files.
Deleting again achieves nothing, because there is nothing left to delete.

### 4. Trying to hard link across filesystems

`Invalid cross-device link`. Inode numbers are per-filesystem, so a directory
entry cannot reference one elsewhere.

Use a symlink, or a bind mount if you need the target to appear inside a specific
tree. `df` on both paths tells you whether they are on the same filesystem before
you try.

### 5. Setting permissions on a symlink

`chmod 600 thelink` changes the target's permissions on Linux, because `chmod`
follows the link. The symlink's own mode stays `lrwxrwxrwx` and is ignored by
everything.

If you meant to restrict access, restrict the target. There is no way to make a
symlink itself more restrictive.

## Work it through

A deployment script has done this for years:

```
ln -sfn /srv/releases/2026-08-07 /srv/current
systemctl reload myapp
```

Someone asks why it is not simply `cp -r`, or a `mv`. And a colleague reports that
after an emergency rollback the app served the wrong version for about a minute.

Reason both out before reading on.

**Why a symlink rather than a copy.** Copying a release into place takes time
proportional to its size, and during that copy the directory contains a
mixture of old and new files, a state in which the application is genuinely
broken. The symlink swap is a single operation: `/srv/current` points at one
release or the other, never at half of each.

Why `-f` and `-n` together, because this is the part that is easy to get
wrong. `-f` replaces an existing link. `-n` treats an existing symlink-to-a-
directory as a file rather than following it, without it, `ln -sf newdir
/srv/current` creates `/srv/current/newdir` **inside** the directory the link
points at, rather than repointing the link. That failure is silent, leaves the
old version live, and is one of the more baffling ten minutes in this
business.

**Now the rollback.** `ln -sfn` is not atomic. It unlinks the old name and creates
the new one, and between those two steps `/srv/current` does not exist. A request
arriving in that window fails.

The atomic version uses `mv`, because renaming over an existing name **is** atomic
on a POSIX filesystem:

```
ln -sfn /srv/releases/2026-08-06 /srv/current.new
mv -Tf /srv/current.new /srv/current
```

`mv -T` treats the destination as a name rather than a directory to move into,
which is the same trap as `-n` above wearing different clothes. The rename either
happened or it did not; there is no moment where the path is absent.

**And the minute of wrong version?** That is not the link at all. The link
swap is instantaneous. A minute of stale content means something cached the
resolved path, an application that resolved `/srv/current` at startup and held
it, or a web server with its own path cache. `systemctl reload` was in the
script for exactly that reason and evidently was not enough for whatever was
holding it.

Now the point worth extracting. **A symlink swap is the standard way to make a
deployment atomic**, and it works because the pointer is small and the file is
not. The three details that make it correct (`-n` so you repoint rather than
descend, `mv -T` so there is no gap, and a reload so nothing holds the old
resolution) are all consequences of the same fact this lesson opened with: **a
name is a pointer, and changing where it points is cheap.**

## Try it

Optional, in `/tmp` where nothing matters.

1. `echo hello > a.txt`, `ln a.txt b.txt`, `ln -s a.txt c.txt`, then
   `ls -li a.txt b.txt c.txt`. Read the inode numbers and link counts.
2. `rm a.txt`. Then `cat b.txt` and `cat c.txt`. Explain both results.
3. `ls -l c.txt` and note it still exists and still shows a target.
4. `stat -c '%i %h %n' b.txt` before and after step 2.
5. `ln -s /nowhere/at/all broken`, then `ls -l broken` and `find . -xtype l`.
6. `ls -ld /bin /lib` on any machine, and follow where they go.
7. `readlink /etc/localtime`, then `realpath /etc/localtime`.

**Verification step.** You have it when you can be shown two filenames and say,
from `ls -li` alone, whether they are one file or two.

## Check yourself

<details class="qa">
<summary>What is a filename, given that a file can have several?</summary>

**A directory entry: a name paired with an inode number.** The file itself is
the inode (permissions, owner, timestamps, and the location of the data) and
it has no name of its own.

So a hard link is just another directory entry pointing at the same inode. None
of the names is the original; the filesystem records no such distinction.

The inode carries a **link count** of how many names refer to it. `rm` removes
one name and decrements the count, and the data is freed only when the count
reaches zero, which is why the system call is called `unlink` rather than
`delete`.

`ls -li` shows both numbers: inode in the first column, link count in the second.

</details>

<details class="qa">
<summary>You delete the file a hard link and a symlink both point at. What happens to each?</summary>

**The hard link is unaffected.** You removed one of two equal names, the link
count dropped from 2 to 1, and the inode still has a name so nothing was freed.
The data is intact and reachable.

**The symlink breaks.** It stores a path as text, and there is now nothing at
that path. The link itself still exists, `ls -l` lists it and still shows its
target, but following it gives `No such file or directory`, and the message is
about the target rather than the link, which is what makes it confusing.

The underlying difference: a hard link **is** a name and keeps the file alive; a
symlink is a **signpost** and has no relationship to whether its target exists.

`find /path -xtype l` lists broken symlinks.

</details>

<details class="qa">
<summary>Why can a hard link not cross filesystems, when a symlink can?</summary>

**A directory entry stores an inode number, and inode numbers are only unique
within one filesystem.** Inode 12345 exists on both `/` and `/home`, referring to
completely different files, so an entry on one filesystem naming an inode on
another would be ambiguous and unresolvable.

The error is `Invalid cross-device link`.

A symlink stores a **path** as ordinary text. Paths are global, so it can
point anywhere in the tree, or at nothing at all, which is the same freedom
seen from the other side.

`df` on both locations tells you whether they are the same filesystem before you
try.

</details>

<details class="qa">
<summary>You <code>rm</code> a 40 GB log and <code>df</code> shows no change. What happened and how do you confirm it?</summary>

**A process still has the file open.** `rm` removed the name and decremented the
link count to zero, but an open file descriptor is also a reference, and the
kernel will not free the blocks while one exists.

So the file has no name (`du` cannot find it, `ls` cannot see it) and it is
still occupying disk.

**`sudo lsof +L1`** lists files whose link count is below one and are still open,
which is exactly this case. `ls -l /proc/<pid>/fd | grep deleted` shows it from
the process side.

The fix is to restart the process, or signal it to reopen its logs. Deleting again
does nothing, because there is nothing left to delete.

Bonus: the data is still readable through `/proc/<pid>/fd/N`, so a file deleted by
accident can be copied back out while the process is alive.

</details>

<details class="qa">
<summary>Why does a deployment repoint a symlink rather than copy files into place, and what does <code>-n</code> prevent?</summary>

**Because the swap is one operation and a copy is not.** Copying a release
into place takes time proportional to its size, and during that time the
directory holds a mixture of old and new files, a state the application is not
designed to run in. Repointing a symlink changes one small pointer, so the
path resolves to one complete release or the other.

**`-n` stops `ln` following an existing symlink-to-a-directory.** Without it,
`ln -sf newdir /srv/current` creates `/srv/current/newdir` *inside* the directory
the link already points at, instead of repointing the link. It succeeds, prints
nothing, and leaves the old version live.

Worth adding: `ln -sfn` is still not atomic, because it unlinks before it
creates. `ln -sfn ... /srv/current.new` followed by `mv -Tf /srv/current.new
/srv/current` is, because a rename over an existing name is atomic.

</details>

## References

- [ln(1)](https://man7.org/linux/man-pages/man1/ln.1.html) - Linux man-pages project. Accessed 2026-08-07.
- [symlink(7)](https://man7.org/linux/man-pages/man7/symlink.7.html) - Linux man-pages project. Accessed 2026-08-07.
- [inode(7)](https://man7.org/linux/man-pages/man7/inode.7.html) - Linux man-pages project. Accessed 2026-08-07.
- [readlink(1)](https://man7.org/linux/man-pages/man1/readlink.1.html) - Linux man-pages project. Accessed 2026-08-07.
- [realpath(1)](https://man7.org/linux/man-pages/man1/realpath.1.html) - Linux man-pages project. Accessed 2026-08-07.
- [unlink(2)](https://man7.org/linux/man-pages/man2/unlink.2.html) - Linux man-pages project. Accessed 2026-08-07.

Every block above with a distribution and architecture header was captured by running the command on a Debian 13 (trixie) container. Blocks without one are illustrative.
