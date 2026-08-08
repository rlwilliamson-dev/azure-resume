---
title: "Turning a directory into one file, and shrinking it"
description: "Archiving and compressing are two different jobs that tar does in one command. What the flags mean, why the three compressors give wildly different sizes, and the extraction that scatters files across your home directory."
track: "linux-plus"
level: "working"
order: 230
objectives:
  - "Explain why archiving and compression are separate operations"
  - "Create, list, and extract a tar archive, including a single file from one"
  - "Choose between gzip, bzip2, and xz from a stated requirement"
  - "Inspect an archive before extracting it, and say why that matters"
prerequisites: ["the-shell-environment"]
tags: ["linux", "linux-plus", "tar", "compression", "backup"]
updated: 2026-08-07
draft: false
examObjectives:
  - exam: "xk0-006"
    domain: "1.0"
    objective: "1.6"
sources:
  - title: "tar(1)"
    url: "https://man7.org/linux/man-pages/man1/tar.1.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "gzip(1)"
    url: "https://manpages.debian.org/stable/gzip/gzip.1.en.html"
    publisher: "Debian Project"
    accessed: 2026-08-07
    tier: 1
  - title: "xz(1)"
    url: "https://manpages.debian.org/stable/xz-utils/xz.1.en.html"
    publisher: "Debian Project"
    accessed: 2026-08-07
    tier: 1
  - title: "bzip2(1)"
    url: "https://manpages.debian.org/stable/bzip2/bzip2.1.en.html"
    publisher: "Debian Project"
    accessed: 2026-08-07
    tier: 1
  - title: "zip(1)"
    url: "https://manpages.debian.org/stable/zip/zip.1.en.html"
    publisher: "Debian Project"
    accessed: 2026-08-07
    tier: 1
  - title: "GNU tar manual"
    url: "https://www.gnu.org/software/tar/manual/tar.html"
    publisher: "GNU Project"
    accessed: 2026-08-07
    tier: 1
symptoms:
  - symptom: "Extracting an archive scattered files across the current directory"
    anchor: "1-the-archive-exploded-across-your-home-directory"
  - symptom: "tar reports Cannot open No such file or directory"
    anchor: "3-the-flags-are-not-in-a-sensible-order"
---

> **Before you read.** You need to send somebody a directory: forty files across
> three subdirectories. Email takes one file at a time. So does a form upload, and
> so does most of the internet.
>
> There are two separate problems in that sentence and it is worth seeing them
> apart before you meet the command that does both.
>
> **One:** how do forty files become one file, with the directory structure and
> the permissions preserved? **Two:** how does that one file become smaller?

They are genuinely different jobs, done by different programs, and Linux keeps
them separate — which is why the command has an odd shape and why `.tar.gz` has
two extensions rather than one.

Windows conflates them: a `.zip` is one thing that archives and compresses
together. Neither approach is wrong, and knowing which you are looking at
explains most of the confusion in this area.

### Some words you will need

<dl class="terms">
<dt>archive</dt>
<dd>Many files packed into one, with their names, structure, permissions, and timestamps kept. Not necessarily smaller.</dd>
<dt>compression</dt>
<dd>Making a single file smaller by encoding repetition. Says nothing about structure.</dd>
<dt>tarball</dt>
<dd>Informal name for a <code>.tar</code>, or a compressed one. From "tape archive", which is what tar was for.</dd>
<dt>lossless</dt>
<dd>Compression that reverses exactly. Everything here is lossless; JPEG and MP3 are not.</dd>
</dl>

## What breaks without this

**You cannot move a directory anywhere.** Backups, transfers, deployments, and log
retention all end with one file that used to be many.

**Extraction goes wrong in a way that is tedious to clean up.** An archive built
carelessly unpacks forty files directly into whatever directory you were
standing in.

**You pick the wrong compressor.** The difference between the three is a factor of
ten in size and a factor of twenty in time, in opposite directions, and the right
answer depends entirely on what the file is for.

## Archiving: tar

```bash
# Debian 13 (trixie), x86_64
$ cd /tmp; tar -cf project.tar project; ls -l project.tar; echo '--- what is inside, without extracting ---'; tar -tf project.tar | head -5; echo '--- entries in total ---'; tar -tf project.tar | wc -l
-rw-r--r--. 1 root root 962560 Aug  8 02:21 project.tar
--- what is inside, without extracting ---
project/
project/src/
project/src/service1.log
project/src/service2.log
project/src/service3.log
--- entries in total ---
13
```

**Thirteen entries in one file, and the file is not smaller.** 962560 bytes for
what was 940 KiB of logs — slightly *larger*, in fact, because tar adds a 512-byte
header per entry and pads to block boundaries.

That is the point worth taking from this block: **archiving is not compression.**
It solved the "many files, one file" problem and nothing else.

Three letters do nearly everything:

| Letter | Means | Remember it as |
| --- | --- | --- |
| `c` | create | **c**reate |
| `t` | list | lis**t** |
| `x` | extract | e**x**tract |

Always with `f` for the filename, and `-v` when you want to watch:

```
tar -cf archive.tar directory/      # create
tar -tf archive.tar                 # list
tar -xf archive.tar                 # extract
```

**`-f` must come immediately before the filename**, because it takes the next
argument. `tar -cvf name.tar dir` works; `tar -cfv name.tar dir` tries to create
an archive called `v` and then fails on `name.tar`.

**`-t` before `-x`, always.** Listing costs nothing and tells you what the archive
will do to your current directory, which is the subject of the prediction below.

## Compression: three choices

```bash
# Debian 13 (trixie), x86_64
$ cd /tmp; tar -cf project.tar project; cp project.tar a.tar; cp project.tar b.tar; cp project.tar c.tar; gzip a.tar; bzip2 b.tar; xz c.tar; ls -l project.tar a.tar.gz b.tar.bz2 c.tar.xz
-rw-r--r--. 1 root root  95586 Aug  8 02:22 a.tar.gz
-rw-r--r--. 1 root root  31942 Aug  8 02:22 b.tar.bz2
-rw-r--r--. 1 root root   9572 Aug  8 02:22 c.tar.xz
-rw-r--r--. 1 root root 962560 Aug  8 02:22 project.tar
```

**The same archive, three compressors, and a hundredfold spread.** 962 KB becomes
95 KB with gzip, 32 KB with bzip2, and **9.5 KB** with xz.

| | gzip | bzip2 | xz |
| --- | --- | --- | --- |
| Here | 95 KB | 32 KB | 9.5 KB |
| Speed to compress | Fast | Slow | Slowest |
| Speed to decompress | Fastest | Slow | Fast |
| Memory to decompress | Small | Moderate | **Large** |
| Extension | `.gz` | `.bz2` | `.xz` |
| tar flag | `-z` | `-j` | `-J` |

**This example flatters xz**, and it is worth saying so: the test data is highly
repetitive log lines, which is exactly what its larger dictionary exploits. On
photographs or already-compressed data the three would land within a few per cent
of each other and all three would be near-useless.

The decision, stated plainly:

- **gzip** when it will be decompressed often, or by something small, or when
  compatibility matters. It is everywhere and it is fast.
- **xz** when it is compressed once and distributed many times — a release
  tarball, an install image. Slow to make, small to ship, quick to open.
- **bzip2** rarely, now. It has been overtaken at both ends; it survives in
  existing archives you will need to open.
- **zstd** (`.zst`) is the modern answer and is displacing all three: close to xz
  ratios at gzip speeds. It is not on this exam's objective list and it is
  increasingly the default in package managers and filesystems, so it is worth
  recognising.

**Note that each compressor replaced its input.** `gzip a.tar` leaves `a.tar.gz`
and no `a.tar`. `-k` keeps the original.

## Both at once

tar calls the compressor for you, which is why the three flags exist:

```bash
# Debian 13 (trixie), x86_64
$ cd /tmp; tar -czf project.tar.gz project; mkdir restore; tar -xzf project.tar.gz -C restore; echo '--- what came back ---'; find restore -type f | head -4; echo '--- and extracting one file only ---'; tar -xzf project.tar.gz -C restore project/docs/README; ls -l restore/project/docs/README
--- what came back ---
restore/project/src/service1.log
restore/project/src/service2.log
restore/project/src/service3.log
restore/project/src/service4.log
--- and extracting one file only ---
-rw-r--r--. 1 root root 11 Aug  8 02:22 restore/project/docs/README
```

Two flags earning their place here.

**`-C directory` changes where tar works** before doing anything. On extraction it
means "unpack into there", which is far safer than `cd`-ing about, and on creation
it means "treat this as the top", which controls the paths stored in the archive.

**Naming a path after the archive extracts only that.** `tar -xzf a.tar.gz
project/docs/README` pulls one file out of a thousand without unpacking the rest.
The path must match what `-t` shows exactly, which is one more reason to list
first.

Modern GNU tar detects compression automatically on extraction, so `-xf` works on
a `.gz`, a `.bz2`, and an `.xz` alike. **On creation you still have to say
which**, because tar cannot guess from a filename you invented.

## The thing that goes wrong

<details class="predict">
<summary>Somebody builds an archive by running `tar -czf backup.tar.gz *` inside the directory. What happens when a colleague extracts it in their home directory?</summary>

Nothing dangerous, and a genuine mess.

Because the archive was created from **inside** the directory, its entries are
`service1.log`, `docs/README`, and so on — with no common parent. So extracting
it does not create a `project/` directory. It writes all thirteen entries
**directly into the current directory**, mixed in with whatever was already
there.

If the colleague ran it in their home directory, they now have your files
scattered among theirs, with no easy way to tell which is which. If any name
collided, theirs was silently overwritten.

The fix at creation time is to archive the directory **from its parent**, so
every path shares a top-level component:

```
cd /srv && tar -czf ~/backup.tar.gz project/
```

or equivalently `tar -czf backup.tar.gz -C /srv project`.

The defence at extraction time is the habit already mentioned: **`tar -tf`
first.** One glance at whether every line starts with the same directory name
answers it. And `-C` into a fresh empty directory costs nothing:

```
mkdir incoming && tar -xzf backup.tar.gz -C incoming
```

An archive that unpacks without a common parent is called a **tarbomb**, and the
term exists because it used to be common. Nobody does it on purpose; it is what
`*` produces.

</details>

<details class="deeper">
<summary>If you already administer Linux: preserving ownership, sparse files, and the extraction risks that are not accidents</summary>

**Ownership on extraction depends on who you are.** As a normal user, tar assigns
extracted files to *you* regardless of what the archive says, because you cannot
give files away. As root, it restores the stored UIDs and GIDs. So the same
archive extracted two ways produces different ownership, and a restore done
without `sudo` produces a tree that looks right and belongs to the wrong account.
`--no-same-owner` forces the user behaviour explicitly, `-p` (`--preserve-permissions`)
is the default for root and needs asking for otherwise.

**Extended attributes and SELinux contexts are not included by default.**
`--xattrs --selinux --acls` on both create and extract, or a restored web root
comes back with the wrong contexts and SELinux denies everything for reasons that
have nothing to do with the permission bits. On a RHEL-family machine this is the
single most common "the restore did not work".

**`-S` handles sparse files.** A 100 GB virtual disk image with 4 GB of data
archives as 100 GB without it, and as 4 GB with it.

**Extraction is a trust decision, not a copy.** GNU tar strips leading `/` and
refuses `../` by default, so the classic path-traversal attacks fail — but
`--absolute-names` turns that off, and a symlink stored in an archive can point
anywhere, so a later entry written "through" it lands outside the target
directory. The general rule: **do not extract an untrusted archive as root**, and
`tar -tf` before extracting is a security check as much as a tidiness one.

**`--exclude` and `-T`** are what make tar usable for real backups:
`--exclude='*.tmp' --exclude-from=.excludes`, and `-T filelist.txt` to archive a
list produced by `find`. `--exclude` must come **before** the paths on the
command line, which is a genuine and irritating ordering requirement.

</details>

<details class="deeper">
<summary>If you already administer Linux: compression levels, parallelism, and where the time goes</summary>

Every compressor takes a level from `-1` to `-9`, and the returns are strikingly
uneven. Going from `-6` (gzip's default) to `-9` typically costs two to three
times the CPU for a couple of per cent of size. Going from `-1` to `-6` is where
almost all the benefit is.

**So `-1` is frequently the right answer** for anything compressed on the fly —
a backup stream, a log being rotated, data crossing a fast network. The bottleneck
there is the CPU, not the link, and `gzip -1` keeps up with a disk where `gzip -9`
does not. `xz -9` on a large archive can take hours and is worth it only for
something distributed thousands of times.

**All three are single-threaded by default**, which on a 32-core server is
absurd. The parallel versions are drop-in: **`pigz`** for gzip, **`pbzip2`** for
bzip2, and `xz -T0` for xz, which uses every core without needing a different
binary. `tar -c dir | pigz > out.tar.gz` turns a twenty-minute compression into a
one-minute one on a machine with cores to spare.

**`zstd` deserves its growing default status.** `zstd -19` approaches xz ratios at
a fraction of the time, decompresses faster than gzip, and has `--long` for
large-window matching. Both package families now use it for package payloads, and
btrfs and OpenZFS both offer it for transparent filesystem compression.

**Measure before optimising.** `time tar -czf /dev/null dir` tells you whether the
compression or the disk read is the limit. On a spinning disk full of small files
it is frequently neither — it is the seeking, and no compressor choice will help.

</details>

## zip, and when you need it

`zip` compresses each file separately and stores them in one container, which is
the opposite arrangement from `tar` plus a compressor.

```
zip -r archive.zip directory/
unzip archive.zip
unzip -l archive.zip          # list, the equivalent of tar -tf
```

**Per-file compression is why zip archives are larger** than an equivalent
`.tar.gz`: the compressor restarts at every file and cannot exploit repetition
*between* files. It is also why you can extract one file from a zip instantly,
while a `.tar.gz` has to be decompressed up to that point.

Use zip when the recipient is on Windows or when something specifically requires
it. Use `tar` plus a compressor otherwise.

**7-Zip** (`7z`) appears on the objective list too. It compresses well, handles
many formats, and is a separate package (`p7zip`) on both families.

<details class="deeper">
<summary>If you already administer Linux: reading compressed files without decompressing them</summary>

Rotated logs are compressed, and yesterday's answer is in `syslog.2.gz`.
Decompressing it to read it wastes time and disk, and on a full disk — the usual
reason you are reading logs — it may not be possible at all.

The `z` family reads gzip directly: **`zcat`, `zless`, `zgrep`, `zdiff`**. There
are `bz` equivalents (`bzcat`, `bzgrep`) and `xz` ones (`xzcat`, `xzgrep`), and
`zstdcat` for zstd.

```
zgrep -h 'ERROR' /var/log/syslog*.gz | tail -20
zless /var/log/syslog.2.gz
```

**`zgrep` across a rotated set is the everyday use**, and the shell glob handles
both the compressed and uncompressed members. Note `-h` to suppress filename
prefixes when you want to pipe the result onward.

**`tar -tvf` shows sizes, permissions, and timestamps**, not just names, which
lets you confirm an archive contains what you expect before spending the time and
disk on extracting it.

**Checking integrity without extracting:** `gzip -t file.gz`, `xz -t file.xz`,
`bzip2 -t file.bz2` all verify the checksum and report corruption. Worth running
on an archive that has been sitting on a disk or moved across a network before
you rely on it — which is the point where this lesson joins the next one.

</details>

## Across distributions

| | RHEL family | Debian family |
| --- | --- | --- |
| `tar`, `gzip` | Installed | Installed |
| `bzip2`, `xz` | `bzip2`, `xz` | `bzip2`, `xz-utils` |
| `zip` / `unzip` | `zip`, `unzip`, often absent | `zip`, `unzip`, often absent |
| 7-Zip | `p7zip` | `p7zip-full` |
| Package format compression | zstd on recent releases | zstd on recent releases |

**`xz-utils` versus `xz` is a real difference** and `zip` being absent on minimal
images is worth expecting — the same lesson as the missing editor in lesson 05.

## Prove it

Before extracting anything you did not create:

```bash
# What is in it, and does everything share a parent
tar -tf archive.tar.gz | head
tar -tf archive.tar.gz | cut -d/ -f1 | sort -u

# How big will it be
tar -tvf archive.tar.gz | awk '{total += $3} END {print total " bytes"}'

# Is it intact
gzip -t archive.tar.gz && echo "checksum ok"

# Extract somewhere it cannot do damage
mkdir incoming && tar -xzf archive.tar.gz -C incoming
```

**That second line is the tarbomb check** in one command: if it returns a single
name, everything shares a parent and extraction is tidy. If it returns thirteen
names, it is going to unpack into your current directory.

## What trips people up

### 1. The archive exploded across your home directory

Created with `tar -czf backup.tar.gz *` from inside the directory, so nothing
shares a parent.

`tar -tf` first, always. Extract with `-C` into an empty directory. And when
creating, archive the directory from its parent so the paths carry a common top.

### 2. `.tar.gz` versus `.tar` versus `.gz`

`.tar` is an archive, uncompressed. `.gz` is one compressed file, not an archive.
`.tar.gz` (or `.tgz`) is an archive that was then compressed.

`gunzip file.tar.gz` gives you `file.tar`, which still needs `tar -xf`. Modern
`tar -xf` does both in one step, which is why the intermediate stage surprises
people when they meet it.

`file archive.whatever` tells you which you have, regardless of the name.

### 3. The flags are not in a sensible order

`-f` consumes the next argument as the filename. `tar -cfv name.tar dir` creates
an archive named `v`.

Put `f` last among the letters: `-czvf`, `-xzvf`, `-tzf`. Or use the long forms —
`tar --create --gzip --file=name.tar.gz dir` — in anything written down.

### 4. Compressing what is already compressed

Re-compressing JPEGs, MP4s, or a `.tar.gz` gains nothing and occasionally makes
the file slightly larger, while costing the full CPU time.

Check what is actually in the directory first. A backup of a photo archive is a
copy job, not a compression job.

### 5. Losing the original

`gzip file` replaces `file` with `file.gz`. So does `bzip2` and `xz`.

`-k` keeps it. `tar -czf` does not have this problem, because it reads the
source and writes a new archive.

## Work it through

A colleague asks you to archive `/srv/webapp` — 8 GB, mostly images with some
code and logs — so it can be stored offsite and restored onto a RHEL server if
the machine is lost.

Reason through the decisions before reading on.

**First: which compressor?** The instinct is xz for the smallest file. Look at
the content: *mostly images*. JPEGs and PNGs are already compressed, so no
compressor will meaningfully shrink them, and xz will spend a great deal of CPU
proving it. gzip is the right answer here, and the honest reason is that most of
these 8 GB are not compressible at all.

Worth checking rather than assuming:

```
du -sh /srv/webapp/*
tar -cf - /srv/webapp | gzip | wc -c
```

The second one compresses to nothing and reports the size, so you know the ratio
before committing to a run.

**Second: how is it built?** From the parent, so the archive has a common top and
restores predictably:

```
tar -czf /backup/webapp-2026-08-07.tar.gz -C /srv webapp
```

**Third: what has to survive the round trip?** This is the part that gets missed.
It is being restored to a **RHEL** server, which means SELinux, and the archive is
being created by root, which means ownership is stored. Both need asking for:

```
sudo tar --xattrs --selinux --acls -czf /backup/webapp-2026-08-07.tar.gz -C /srv webapp
```

Without `--selinux`, the restored files carry default contexts, the web server is
denied access to its own content, and every visible permission looks correct. It
is one of the most confusing restores there is, and it is one flag.

**Fourth: prove it before you need it.**

```
gzip -t /backup/webapp-2026-08-07.tar.gz && echo "intact"
tar -tvf /backup/webapp-2026-08-07.tar.gz | head
tar -tf /backup/webapp-2026-08-07.tar.gz | cut -d/ -f1 | sort -u
```

Intact, contains what you expect, and has exactly one top-level name.

Now the question underneath: **why does the destination change how the archive is
made?** Because tar stores what it is told to store, and permissions, ownership,
ACLs, and security contexts are four separate things it can carry or drop. An
archive is not a copy of the files; it is a copy of the parts of the files
somebody selected.

The habit worth taking: **decide what has to survive before you create the
archive, not when you restore it.** The flags are on the create side, and by the
time a restore is going wrong the information is already gone. Which leads
directly into the next lesson, where the whole point is that a backup nobody has
restored is not yet a backup.

## Try it

Optional, on any machine.

1. `mkdir -p demo/sub && echo hi > demo/sub/a.txt && echo there > demo/b.txt`.
2. `tar -cf demo.tar demo` then `ls -l demo demo.tar`. Note the archive is not
   smaller.
3. `tar -tf demo.tar`. Confirm every line starts with `demo/`.
4. `gzip -k demo.tar` and compare sizes. Then `xz -k demo.tar` and compare again.
5. `mkdir out && tar -xf demo.tar -C out && find out`.
6. Extract one file: `tar -xf demo.tar -C out demo/b.txt`.
7. Now the mistake, deliberately: `cd demo && tar -czf ../bomb.tar.gz *`, then
   `cd /tmp && mkdir mess && cd mess && tar -xzf ~/bomb.tar.gz` and see what
   lands there.

**Verification step.** You have it when you can be handed an unfamiliar archive
and say, before extracting, whether it will create a directory or scatter files
into the one you are standing in.

## Check yourself

<details class="qa">
<summary>Why is a `.tar` file sometimes larger than the files it contains?</summary>

**Because tar archives without compressing.** Its job is to turn many files into
one while preserving names, directory structure, permissions, ownership, and
timestamps — none of which involves making anything smaller.

It adds a 512-byte header for every entry and pads each file to a block boundary,
so an archive of many small files can be noticeably larger than the sum of them.

Compression is a separate step, done by `gzip`, `bzip2`, or `xz`, which is why
`.tar.gz` has two extensions: one for each operation. tar's `-z`, `-j`, and `-J`
flags just call the compressor for you.

</details>

<details class="qa">
<summary>The same archive is 95 KB with gzip and 9.5 KB with xz. Should you always use xz?</summary>

**No**, and the example that produced those numbers is the reason to be careful
with them: it was highly repetitive log text, which is exactly what xz's larger
dictionary exploits. On photographs, video, or anything already compressed, the
three land within a few per cent of each other and none of them helps.

The trade is time. xz is much slower to compress, so it suits things
**compressed once and distributed many times** — a release tarball, an install
image, an offsite archive nobody touches.

gzip suits anything decompressed often, anything on a constrained device, and
anything where compatibility matters. It is fast and it is everywhere.

Check before assuming: `tar -cf - dir | gzip | wc -c` tells you the actual ratio
for your data in one command.

</details>

<details class="qa">
<summary>What is a tarbomb, what creates one, and what are the two defences?</summary>

An archive whose entries have **no common parent directory**, so extracting it
writes files straight into the current directory rather than creating one.

It is created by archiving from *inside* the directory — `tar -czf backup.tar.gz *`
— which stores paths like `a.txt` and `docs/README` with nothing above them.
Nobody does it deliberately; it is what `*` produces.

**Defence one, at creation:** archive the directory from its parent, so every
path shares a top-level name. `tar -czf backup.tar.gz -C /srv project`.

**Defence two, at extraction:** `tar -tf` before `tar -xf`, and extract with `-C`
into a fresh empty directory. `tar -tf a.tar.gz | cut -d/ -f1 | sort -u` answers
it in one line — one result means tidy, many means a bomb.

</details>

<details class="qa">
<summary>You restore a web root from a tar archive onto a RHEL server and the web server is denied access, though the permissions look correct. Why?</summary>

**SELinux contexts were not in the archive.** tar does not store them by default,
so the restored files carry whatever the default context is for that path — which
is frequently not the one the web server is permitted to read.

Everything `ls -l` shows is correct, which is what makes it confusing: the mode
bits, the owner, and the group are all right, and SELinux is refusing on a
dimension `ls -l` does not display.

The fix at creation time is `--xattrs --selinux --acls` on **both** create and
extract. After the fact, `restorecon -Rv /var/www` relabels to the policy default,
which is usually what you wanted.

The general point: an archive stores the parts of a file somebody selected.
Permissions, ownership, ACLs, and security contexts are four separate things,
and three of them need asking for.

</details>

<details class="qa">
<summary>Why does `tar -cfv archive.tar dir` fail, and what is the rule?</summary>

**`-f` takes the next argument as the filename**, and here the next argument is
`v`. So tar tries to create an archive called `v`, then treats `archive.tar` as
something to add to it, and the command does something entirely unlike what was
intended.

The rule: **`f` goes last among the letters**, immediately before the filename.
`-cvf`, `-xzvf`, `-tzf`.

In anything written down, prefer the long forms, which cannot be got wrong:
`tar --create --gzip --file=archive.tar.gz dir`.

</details>

## References

- [tar(1)](https://man7.org/linux/man-pages/man1/tar.1.html) - Linux man-pages project. Accessed 2026-08-07.
- [gzip(1)](https://manpages.debian.org/stable/gzip/gzip.1.en.html) - Debian Project. Accessed 2026-08-07.
- [xz(1)](https://manpages.debian.org/stable/xz-utils/xz.1.en.html) - Debian Project. Accessed 2026-08-07.
- [bzip2(1)](https://manpages.debian.org/stable/bzip2/bzip2.1.en.html) - Debian Project. Accessed 2026-08-07.
- [zip(1)](https://manpages.debian.org/stable/zip/zip.1.en.html) - Debian Project. Accessed 2026-08-07.
- [GNU tar manual](https://www.gnu.org/software/tar/manual/tar.html) - GNU Project. Accessed 2026-08-07.

Command output was captured on the images pinned in `blog/scripts/distros.json`,
against generated log text. Blocks without a distribution and architecture header
are illustrative.
