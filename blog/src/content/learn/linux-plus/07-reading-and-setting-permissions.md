---
title: "Reading and setting permissions"
description: "The ten characters at the start of every ls -l line, what each one grants, how to change them in two different notations, and why the execute bit on a directory has nothing to do with running anything."
track: "linux-plus"
level: "working"
order: 80
objectives:
  - "Read a ten-character mode string and say exactly who may do what"
  - "Convert between symbolic and octal notation in both directions"
  - "Change mode and ownership, and predict the result before pressing Enter"
  - "Explain why the execute bit means something different on a directory"
prerequisites: ["users-root-and-sudo"]
tags: ["linux", "linux-plus", "permissions", "security"]
updated: 2026-08-07
draft: false
examObjectives:
  - exam: "xk0-006"
    domain: "2.0"
    objective: "2.1"
  - exam: "xk0-006"
    domain: "3.0"
    objective: "3.3"
sources:
  - title: "chmod(1)"
    url: "https://man7.org/linux/man-pages/man1/chmod.1.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "chown(1)"
    url: "https://man7.org/linux/man-pages/man1/chown.1.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "stat(1)"
    url: "https://man7.org/linux/man-pages/man1/stat.1.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "umask(2)"
    url: "https://man7.org/linux/man-pages/man2/umask.2.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "inode(7)"
    url: "https://man7.org/linux/man-pages/man7/inode.7.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "path_resolution(7)"
    url: "https://man7.org/linux/man-pages/man7/path_resolution.7.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
symptoms:
  - symptom: "Permission denied running a script you just wrote"
    anchor: "1-permission-denied-on-a-script-you-just-wrote"
  - symptom: "Can list a directory but cannot read the files in it"
    anchor: "3-you-can-list-a-directory-but-not-read-what-is-in-it"
---

> **Before you read.** Two files sit side by side in the same directory, owned by
> the same person. You can open one and not the other.
>
> Nothing about *where* they are explains that. So the difference has to be
> carried by the files themselves — and there is a place it is written down, in
> plain sight, on every line of `ls -l` output you have ever scrolled past.

Ten characters. That is the whole permission system for a file, and once you can
read them you can predict what will happen before you try it, which is a
noticeably better way to work than finding out.

This is also the point where the exam starts caring, because objective 3.3 is
about hardening, and almost every real hardening finding is a permission that is
more generous than it needed to be.

### Some words you will need

<dl class="terms">
<dt>mode</dt>
<dd>The permission bits on a file. Written either as ten characters or as a three or four digit number.</dd>
<dt>owner</dt>
<dd>The single user account a file belongs to. Shown in the third column of <code>ls -l</code>.</dd>
<dt>group owner</dt>
<dd>The single group a file belongs to. Fourth column. Everyone in that group gets the group permissions.</dd>
<dt>octal</dt>
<dd>Base eight. The compact way to write a mode, where each digit stands for one set of three permission bits.</dd>
<dt>umask</dt>
<dd>The bits removed from the default mode when something new is created. A subtraction, not a setting.</dd>
</dl>

## What breaks without this

**Nothing runs.** A script you wrote and a program you downloaded both refuse to
execute until the execute bit is set, and the error says nothing about
permissions in a way that is obvious to a beginner.

**Or everything runs, for everyone.** The reflex fix is `chmod 777`, which does
make the error go away, along with every protection the file had. Half of the
findings in a real hardening review are exactly this, applied a year earlier by
somebody in a hurry.

**Services fail in ways that do not look like permissions.** A web server that
returns 403, a database that will not start, a cron job that produces no output —
these are all frequently one wrong mode, and none of them says so.

## The ten characters

Here is a real listing, chosen because it contains every case worth knowing:

```bash
# Debian 13 (trixie), x86_64
$ ls -l /etc/hostname /etc/shadow /usr/bin/passwd; ls -ld /tmp /home
-rw-r--r--. 1 root root       13 Aug  8 00:21 /etc/hostname
-rw-r-----. 1 root shadow    474 Aug  3 00:00 /etc/shadow
-rwsr-xr-x. 1 root root   118168 Apr 19  2025 /usr/bin/passwd
drwxr-xr-x. 2 root root 6 Jul  4 09:05 /home
drwxrwxrwt. 2 root root 6 Aug  3 00:00 /tmp
```

(That trailing `.` after each mode means an SELinux label is attached. It comes
from the machine these were captured on and is not part of the permissions.
Some systems show `+` there instead, which means an ACL, and that one *does*
matter — more on it at the end.)

Take the first line apart.

<figure class="learn-figure">
<svg viewBox="0 0 720 330" role="img" aria-labelledby="mode-title mode-desc" style="width:100%;height:auto;">
  <title id="mode-title">How a ten character mode string is divided</title>
  <desc id="mode-desc">The mode string dash r w x r dash x r dash dash. The first character is the file type. The next three are the owner's permissions, read write execute, worth 7 in octal. The next three are the group's, read and execute, worth 5. The last three are everyone else's, read only, worth 4. Read is worth 4, write 2, execute 1, and each triad is the sum. Setuid replaces the owner's execute character with s, setgid replaces the group's execute character with s, and the sticky bit replaces the other execute character with t.</desc>

  <g font-family="ui-monospace, monospace" font-size="27" fill="currentColor" text-anchor="middle">
    <text x="160" y="58">-</text>
    <text x="202" y="58">r</text>
    <text x="244" y="58">w</text>
    <text x="286" y="58">x</text>
    <text x="328" y="58">r</text>
    <text x="370" y="58">-</text>
    <text x="412" y="58">x</text>
    <text x="454" y="58">r</text>
    <text x="496" y="58">-</text>
    <text x="538" y="58">-</text>
  </g>

  <g fill="none" stroke="currentColor" stroke-opacity="0.35" stroke-width="1">
    <path d="M148 74 L148 84 L172 84 L172 74"/>
    <path d="M186 74 L186 84 L302 84 L302 74"/>
    <path d="M312 74 L312 84 L428 84 L428 74"/>
    <path d="M438 74 L438 84 L554 84 L554 74"/>
  </g>

  <g font-family="ui-monospace, monospace" font-size="12.5" fill="currentColor" fill-opacity="0.65" text-anchor="middle">
    <text x="160" y="102">type</text>
    <text x="244" y="102">user</text>
    <text x="370" y="102">group</text>
    <text x="496" y="102">other</text>
  </g>

  <g font-family="ui-monospace, monospace" font-size="10.5" fill="currentColor" fill-opacity="0.5" text-anchor="middle">
    <text x="160" y="120">- file</text>
    <text x="160" y="134">d dir</text>
    <text x="160" y="148">l link</text>
    <text x="244" y="120">the owner</text>
    <text x="370" y="120">members of</text>
    <text x="370" y="134">the group</text>
    <text x="496" y="120">everyone</text>
    <text x="496" y="134">else</text>
  </g>

  <g font-family="ui-monospace, monospace" font-size="22" fill="currentColor" text-anchor="middle">
    <text x="244" y="188">7</text>
    <text x="370" y="188">5</text>
    <text x="496" y="188">4</text>
  </g>
  <g font-family="ui-monospace, monospace" font-size="10.5" fill="currentColor" fill-opacity="0.55" text-anchor="middle">
    <text x="244" y="206">4+2+1</text>
    <text x="370" y="206">4+0+1</text>
    <text x="496" y="206">4+0+0</text>
  </g>
  <g font-family="ui-monospace, monospace" font-size="11.5" fill="currentColor" fill-opacity="0.7">
    <text x="600" y="188">r=4  w=2  x=1</text>
  </g>

  <line x1="120" y1="232" x2="640" y2="232" stroke="currentColor" stroke-opacity="0.2" stroke-width="1"/>

  <g font-family="ui-monospace, monospace" font-size="11.5" fill="currentColor" fill-opacity="0.65">
    <text x="120" y="256">the special bits sit in the execute positions</text>
  </g>
  <g font-family="ui-monospace, monospace" font-size="20" fill="currentColor" text-anchor="middle">
    <text x="286" y="292">s</text>
    <text x="412" y="292">s</text>
    <text x="538" y="292">t</text>
  </g>
  <g font-family="ui-monospace, monospace" font-size="10.5" fill="currentColor" fill-opacity="0.55" text-anchor="middle">
    <text x="286" y="312">setuid</text>
    <text x="412" y="312">setgid</text>
    <text x="538" y="312">sticky</text>
  </g>
</svg>
<figcaption>One type character, then three groups of three. Each group is a digit.</figcaption>
</figure>

So `-rw-r--r--` reads as: a regular file, the owner may read and write, the group
may read, everyone else may read. Nobody may execute it.

**The three sets are checked in order and only one applies.** If you are the
owner, the owner bits decide, and the group and other bits are never consulted.
This surprises people, because it means you can lock yourself out of your own
file while everyone else can still read it. `----r--r--` is a legal mode and it
does exactly that.

Now read the other four lines from that capture:

- `/etc/shadow` is `-rw-r-----`, owned by `root:shadow`. Root reads and writes,
  members of the `shadow` group read, **everybody else gets nothing**. That is why
  sam's `cat` failed in lesson 06.
- `/usr/bin/passwd` is `-rwsr-xr-x`. There is an `s` where the owner's execute
  character should be. Hold that thought.
- `/home` is `drwxr-xr-x`. The leading `d` says directory.
- `/tmp` is `drwxrwxrwt`. Writable by everyone, and a `t` on the end. Also hold
  that thought.

## Two notations for the same thing

Octal is the compact form. Each triad becomes one digit by adding up what is set:

| | Read | Write | Execute |
| --- | --- | --- | --- |
| Worth | 4 | 2 | 1 |

Add them per triad, left to right:

| Octal | Symbolic | Reads as |
| --- | --- | --- |
| `644` | `rw-r--r--` | Owner edits, everyone reads. The default for a file. |
| `755` | `rwxr-xr-x` | Owner edits, everyone runs. The default for a program or directory. |
| `600` | `rw-------` | Owner only. Private keys and credentials. |
| `640` | `rw-r-----` | Owner edits, one group reads. Most sensitive config. |
| `775` | `rwxrwxr-x` | A group can both edit and run. Shared project directories. |
| `777` | `rwxrwxrwx` | Everyone can do everything. Almost never correct. |

There are only eight digits and you will recognise the common half a dozen within
a week. Worth memorising anyway, because the exam will show you one and expect
the other.

Symbolic notation changes bits relative to what is there. Three parts: **who**,
**what operation**, **which bits**.

| Who | | Operation | | Bits |
| --- | --- | --- | --- | --- |
| `u` user | | `+` add | | `r` read |
| `g` group | | `-` remove | | `w` write |
| `o` other | | `=` set exactly | | `x` execute |
| `a` all | | | | |

So `chmod u+x file` adds execute for the owner and touches nothing else.
`chmod go-w file` removes write from group and other. `chmod a=r file` sets
everyone to read-only, clearing anything that was there.

**The two notations are for different jobs.** Octal states the final answer, which
makes it right for anything written down: a script, a runbook, a config
management rule. Symbolic adjusts one bit without needing to know or restate the
rest, which makes it right for typing at a prompt.

## Making something runnable

The single most common permission task, start to finish. `backup.sh` is a shell
script that sam has just written:

```bash
# Debian 13 (trixie), x86_64
$ cd /home/sam; ls -l backup.sh; su - sam -c "./backup.sh"; chmod u+x backup.sh; ls -l backup.sh; su - sam -c "./backup.sh"
-rw-r--r--. 1 sam sam 22 Aug  8 00:21 backup.sh
-bash: line 1: ./backup.sh: Permission denied
-rwxr--r--. 1 sam sam 22 Aug  8 00:21 backup.sh
it ran
```

Four steps in one line. The file starts at `644`, running it fails, `chmod u+x`
turns the owner's `-` into an `x`, and now it runs.

**`Permission denied` on a script you just wrote is almost always this.** You own
the file, the contents are correct, and the execute bit is missing because
creating a file never sets it. The system will not run something you did not
explicitly mark as runnable, which is a small deliberate obstacle in the way of
accidentally executing a downloaded text file.

Note what did *not* change: group and other still show `r--`. `u+x` was surgical.
The equivalent octal is `chmod 744`, which requires you to have known the other
six bits, and if you had guessed `755` you would have quietly handed the execute
bit to the entire machine.

## Octal in practice, and stat

```bash
# Debian 13 (trixie), x86_64
$ cd /home/sam; chmod 640 vault/secret.txt; ls -l vault/secret.txt; chmod 755 vault; ls -ld vault; chmod 644 vault/secret.txt; stat -c "%a %A %U %G %n" vault/secret.txt vault
-rw-r-----. 1 sam sam 11 Aug  8 00:21 vault/secret.txt
drwxr-xr-x. 2 sam sam 24 Aug  8 00:21 vault
644 -rw-r--r-- sam sam vault/secret.txt
755 drwxr-xr-x sam sam vault
```

`stat -c` is worth adopting. `%a` gives the octal, `%A` gives the symbolic, `%U`
and `%G` give the owner and group. Both notations side by side, which is a
useful thing to stare at while the conversion is still becoming automatic.

## Who owns it

Two commands, and only root can hand a file to somebody else:

```bash
# Debian 13 (trixie), x86_64
$ cd /home/sam; groupadd webdev; ls -l backup.sh; chown root backup.sh; chgrp webdev backup.sh; ls -l backup.sh; chown sam:sam backup.sh; ls -l backup.sh
-rw-r--r--. 1 sam sam 22 Aug  8 00:33 backup.sh
-rw-r--r--. 1 root webdev 22 Aug  8 00:33 backup.sh
-rw-r--r--. 1 sam sam 22 Aug  8 00:33 backup.sh
```

`chown` sets the user, `chgrp` sets the group, and `chown user:group` sets both
in one go, which is why `chgrp` is the one you can forget about.

**The mode never changed.** All three lines are `-rw-r--r--`. Ownership and mode
are two independent things, and confusing them is behind a lot of unsuccessful
troubleshooting: "I set it to 644 and it still cannot read it" is usually a file
owned by the wrong account, where the mode was never the problem.

`-R` applies recursively. `chown -R sam:sam /home/sam` is the standard repair
after copying files around as root, and it is also the command that ruins an
afternoon if you point it at `/` by mistake.

## The bit that means something else on a directory

Here is the part that genuinely does not follow from anything so far. On a
directory, the three bits mean:

| Bit | On a file | On a directory |
| --- | --- | --- |
| `r` | Read the contents | List the names inside |
| `w` | Change the contents | Create, rename, and delete entries inside |
| `x` | Run it as a program | **Go through it to reach what is inside** |

Execute on a directory is not about running anything. It is permission to
traverse — to use that directory as a step in a path.

Sam owns a directory called `vault` and removes its execute bit:

<details class="predict">
<summary>After `chmod 644 vault`, does `ls vault` still work? Does `cat vault/secret.txt`? Use the table above and decide before you look.</summary>

```bash
# Debian 13 (trixie), x86_64
$ su - sam -c "chmod 644 vault; ls -ld vault; ls vault; cat vault/secret.txt"
drw-r--r--. 2 sam sam 24 Aug  8 00:22 vault
secret.txt
cat: vault/secret.txt: Permission denied
```

**`ls` works and `cat` does not.** The read bit survived, so sam can still list
the names inside. The execute bit is gone, so sam cannot step *through* `vault`
to reach anything it holds.

You can see that a file called `secret.txt` exists and you cannot touch it. The
name is metadata belonging to the directory; the contents are behind a door you
no longer have permission to walk through.

Note also the mode string: `drw-r--r--`. A directory with no `x` anywhere. If you
ever see that in the wild, somebody has typed `644` at a directory out of habit,
and things are about to stop working in a confusing way.

</details>

**The practical rule: directories almost always want `755`, files almost always
want `644`.** The directory needs `x` so people can reach what is inside; the
file does not need `x` unless it is a program.

And this compounds along a path. To read `/home/sam/vault/secret.txt` you need
execute on `/`, on `/home`, on `/home/sam`, and on `/vault` — every directory in
the chain — plus read on the file itself. One missing `x` anywhere along the way
and the whole path fails, which is why the error can point at a file whose
permissions are perfectly fine.

## What new files get: umask

Nothing asks you what mode a new file should have, so something decides. That
something is the umask, and it works by **subtraction**:

```bash
# Debian 13 (trixie), x86_64
$ su - sam -c "umask; touch a.txt; mkdir b; ls -l a.txt; ls -ld b"
0002
-rw-rw-r--. 1 sam sam 0 Aug  8 00:22 a.txt
drwxrwxr-x. 2 sam sam 6 Aug  8 00:22 b
```

The system starts from a base of `666` for files and `777` for directories — note
that files never get execute by default, which is exactly why your script needed
`chmod u+x`. Then the umask bits are removed:

| | Base | umask | Result |
| --- | --- | --- | --- |
| File | `666` | `002` | `664` = `rw-rw-r--` |
| Directory | `777` | `002` | `775` = `rwxrwxr-x` |

Both match the capture. A umask of `002` removes write from "other" and leaves
the group able to write, which is Debian's default and suits a machine where
each user has their own group.

`umask 077` is the paranoid setting: it removes everything from group and other,
so new files come out `600` and new directories `700`. That is the right choice
on a shared machine, and it is a common hardening recommendation.

The default is not the same everywhere. The identical commands on AlmaLinux:

```bash
# AlmaLinux 10.2, x86_64
$ su - sam -c "umask; touch a.txt; mkdir b; ls -l a.txt; ls -ld b"
0022
-rw-r--r--. 1 sam sam 0 Aug  8 00:43 a.txt
drwxr-xr-x. 2 sam sam 6 Aug  8 00:43 b
```

Same user, same commands, different results: `644` and `755` rather than `664`
and `775`. **The group can write on Debian and cannot on AlmaLinux.** Worth
knowing before you debug a deployment that works on one and not the other.

<details class="deeper">
<summary>If you already administer Linux: setuid, setgid, sticky, and where ACLs come in</summary>

Back to the two odd lines from the first capture.

**`/usr/bin/passwd` is `-rwsr-xr-x`.** The `s` in the owner's execute position is
**setuid**: the program runs as the file's owner rather than as the person who
launched it. `passwd` has to be setuid root because changing your own password
means writing to `/etc/shadow`, which you cannot read, let alone write.

That is also why setuid is the first thing an attacker looks for and the first
thing a hardening baseline enumerates. `find / -perm -4000 -type f 2>/dev/null`
lists them, and every entry is a program that gives an unprivileged user a
controlled path to root's authority. The list should be short, and it should be
the distribution's.

**`/tmp` is `drwxrwxrwt`.** That `t` is the **sticky bit**, and on a directory it
restricts deletion: anyone may create files, but only the file's owner (or the
directory's owner, or root) may remove them. Without it, world-writable `/tmp`
would let any user delete any other user's temporary files, which was in fact a
real problem before the bit existed.

**setgid on a directory** is the genuinely useful one for shared work. `chmod g+s
/srv/project` makes new files inside inherit the directory's group rather than
the creator's primary group, so a team can actually collaborate without every
file arriving owned by the wrong group. Combine it with a group-writable mode and
a `002` umask and shared directories stop needing daily repair.

Octal gets a fourth digit for these: setuid 4, setgid 2, sticky 1, prepended. So
`chmod 4755` is setuid plus `755`, and `chmod 2775` is a setgid shared directory.
An uppercase `S` or `T` in the listing means the special bit is set while the
underlying execute bit is not, which is usually a mistake and always worth a
second look.

Finally, the limit of all of this: **one owner, one group**. Two groups needing
different access to the same file cannot be expressed. That is what POSIX ACLs
are for — `setfacl` and `getfacl`, with a `+` on the end of the mode string where
the SELinux `.` sat in these captures. The exam covers them under objective 3.3
and they get their own topic later; the thing to carry from here is *why* they
exist, which is that the model above ran out of room.

</details>

## Across distributions

Verified on the two images pinned for this track, rather than quoted from
documentation, because this is an area where the documentation and the shipped
defaults have drifted apart more than once:

| | AlmaLinux 10.2 | Debian 13 |
| --- | --- | --- |
| Umask a regular user actually gets | `0022` | `0002` |
| So a new file is | `644` | `664` |
| `UMASK` in `/etc/login.defs` | `022` | not set — PAM decides |
| `USERGROUPS_ENAB` | `yes` | `yes` |
| `HOME_MODE` | `0700` | `0700` |
| Extra character after the mode | `.` for an SELinux label | `+` for an ACL, if present |

The umask difference is the one that bites. On AlmaLinux a new file is `644` and
the group cannot write it; on Debian it is `664` and the group can. A deployment
that works on one and fails on the other, with no code change between them, is
very often this.

`HOME_MODE 0700` on both is newer than a lot of the material you will find
online, which still says home directories are `755`. They were, and on some
long-lived systems they still are, because upgrading does not retroactively
change directories that already exist.

## Prove it

After changing permissions, do not trust that it worked. Test as the account that
was failing:

```bash
# What the mode is now, both notations at once
stat -c '%a %A %U %G %n' /path/to/file

# Can the account that was failing actually do the thing
sudo -u www-data cat /path/to/file

# Walk the whole path, because one missing x anywhere breaks it
namei -l /path/to/file
```

`namei -l` is the underrated one. It prints every component of a path with its
own mode and owner, so a missing execute bit three directories up is visible in
one line instead of found by bisection.

## What trips people up

### 1. Permission denied on a script you just wrote

You wrote it, you own it, and it will not run. The execute bit is not set,
because creating a file never sets it.

`chmod u+x script.sh` and you are done. Prefer that to `chmod 755`, which also
hands execute to everyone else, and prefer both to `chmod 777`, which hands them
write as well.

### 2. `chmod 777` as a first move

It makes the error stop, which is why people do it. It also means any account on
the machine can rewrite the file, and for a script that runs privileged, that is
a direct path from "any user" to "whatever that script can do".

Work out *which* of the three sets needs the access and grant only that. If the
web server cannot read a file, the answer is usually to fix the ownership, not to
open the file to the world.

### 3. You can list a directory but not read what is in it

Read on a directory shows you the names. Execute lets you reach the contents.
Having the first without the second gives you a listing you cannot act on, which
looks like a bug and is not.

`chmod +x` on the directory. And check the whole path with `namei -l`, because
this is the failure that hides several levels above the file you are staring at.

### 4. `-R` on the wrong target

`chmod -R 755 /` and `chown -R sam:sam /` are both single-line ways to make a
machine unbootable, and both are usually one misplaced space away from the
command you meant.

Look at the path before pressing Enter. `ls -d` on the target first is two
seconds. Recursive commands do not ask.

### 5. Setting the mode when the problem is the owner

Ownership and mode are independent. If a service cannot read a file owned by the
wrong user, no amount of adjusting the mode fixes it correctly — it can only be
"fixed" by opening the file up to other, which is trip-up 2 wearing a disguise.

`ls -l` shows both. Read the third and fourth columns before you reach for
`chmod`.

## Work it through

A web server returns `403 Forbidden` for one page. The file is there, the config
is right, and the same page works on another server.

You check:

```
-rw-r--r--. 1 root root 4021 Aug  7 09:14 /var/www/html/reports/q3.html
```

Mode `644`, world-readable, owned by root. The web server runs as `www-data`.
Reason it out before reading on.

**The file itself is fine.** `644` means everyone can read it, and `www-data`
counts as everyone. Ownership by root does not matter here, because the "other"
bits already grant read.

**So the file is not the problem.** Which means the path to it is. To open
`/var/www/html/reports/q3.html`, the web server needs execute on `/var`, `/var/www`,
`/var/www/html`, and `/var/www/html/reports`. Any one of those missing produces a
denial that names the file, not the directory.

```
namei -l /var/www/html/reports/q3.html
```

would show it directly. Suppose `reports` comes back as `drw-r--r--` — somebody
typed `chmod 644` at a directory, probably while fixing the permissions on the
files inside it and catching the parent by accident.

**The fix:** `chmod 755 /var/www/html/reports`, which restores traverse without
granting anything else.

**The wrong fix:** `chmod -R 777 /var/www`, which also makes the error go away.
It additionally allows every account on the server to modify the site's content,
including anything the web server itself gets tricked into doing, and it will sit
there unnoticed until someone runs a scan.

Now the question worth answering out loud: **why did the error name the file when
the file was innocent?** Because path resolution is performed step by step from
the left, and it fails at the first directory it cannot enter. The application
only knows the request it made, so it reports the full path it asked for. The
error tells you the destination, not the step that stopped you — and that is why
`namei -l` exists.

## Try it

Optional, if you have a machine handy.

1. `ls -l /etc/shadow /usr/bin/passwd` and `ls -ld /tmp`. Read all three modes
   out loud, including the odd character in each.
2. Create a file. Check its mode against your `umask` and confirm the subtraction
   works out.
3. Write a two-line script, run it, watch it fail, `chmod u+x`, run it again.
4. Make a directory with a file in it. Remove the directory's execute bit and try
   to `cat` the file. Then remove the read bit instead and try `ls`. Two different
   failures.
5. `namei -l` on any deep path and read what it shows you.
6. Convert `rwxr-x---` to octal, and `640` back to symbolic, without a table.

**Verification step.** You have it when you can look at `-rw-r-----` owned by
`root:shadow` and say precisely which accounts on the machine can read it, without
running anything.

## Check yourself

<details class="qa">
<summary>Convert `rwxr-x---` to octal, and say what it permits.</summary>

**`750`.** Owner 4+2+1 = 7, group 4+0+1 = 5, other 0+0+0 = 0.

The owner may read, write, and execute. Members of the group may read and
execute but not modify. Everybody else gets nothing at all — they cannot even
list it if it is a directory.

This is the standard mode for a script that a specific team needs to run and
nobody else should see.

</details>

<details class="qa">
<summary>You own a file and its mode is `----rw-rw-`. Can you read it? Can your colleagues in its group?</summary>

**You cannot. They can.**

Only one set of bits is consulted, and which set is decided by identity, in
order: owner first, then group, then other. You are the owner, so the owner
triad applies, and it is empty. The system never looks at the other two on your
behalf.

Your colleagues are not the owner, so they fall through to the group triad, which
grants read and write.

You can fix it, though — `chmod` is permitted to the file's owner regardless of
the mode, because the authority to change permissions comes from ownership, not
from the bits.

</details>

<details class="qa">
<summary>What does the execute bit do on a directory, and why is `chmod 644` on a directory a mistake?</summary>

It grants **traverse**: permission to pass through the directory to reach what is
inside. Nothing is executed.

`644` leaves a directory with no execute bit for anyone. The read bit survives,
so `ls` still lists the names, but nothing inside can be opened, entered, or
`stat`ed. You get a visible list of things you cannot touch.

The tell in a listing is `drw-r--r--` — a `d` at the front with no `x` anywhere
after it. Directories want `755`, or `750` when only a group should reach inside.

</details>

<details class="qa">
<summary>Your umask is `022`. What mode does a newly created file get, and why does it not get execute?</summary>

**`644`.** The base for a new file is `666`, the umask removes `022`, and
666 − 022 = 644, so `rw-r--r--`.

Execute is absent because the base for files is `666`, not `777` — the execute
bit is never granted at creation regardless of the umask. That is deliberate: a
file you have just written should not become runnable by accident, which is why
every new script needs an explicit `chmod u+x`.

Directories are the other case: their base is `777`, so with the same umask they
come out `755` and are traversable straight away.

</details>

<details class="qa">
<summary>A service cannot read a file whose mode is `644` and whose ownership is correct. Where do you look next, and with what?</summary>

**The directories above it.** Reading a file requires execute on every directory
in its path, and a failure at any one of them reports the full path you asked
for, which makes it look like the file's problem.

`namei -l /full/path/to/file` prints every component with its own mode and owner,
so the missing `x` is visible in one pass rather than found by walking up
directory by directory.

Two other things worth ruling out while you are there: a `+` on the mode string
means an ACL is in play and `getfacl` may be overriding what `ls -l` implies, and
on a RHEL-family machine SELinux can deny access that the permission bits allow,
with `ls -l` looking entirely innocent throughout.

</details>

## References

- [chmod(1)](https://man7.org/linux/man-pages/man1/chmod.1.html) - Linux man-pages project. Accessed 2026-08-07.
- [chown(1)](https://man7.org/linux/man-pages/man1/chown.1.html) - Linux man-pages project. Accessed 2026-08-07.
- [stat(1)](https://man7.org/linux/man-pages/man1/stat.1.html) - Linux man-pages project. Accessed 2026-08-07.
- [umask(2)](https://man7.org/linux/man-pages/man2/umask.2.html) - Linux man-pages project. Accessed 2026-08-07.
- [inode(7)](https://man7.org/linux/man-pages/man7/inode.7.html) - Linux man-pages project. Accessed 2026-08-07.
- [path_resolution(7)](https://man7.org/linux/man-pages/man7/path_resolution.7.html) - Linux man-pages project. Accessed 2026-08-07.

Command output was captured on the images pinned in `blog/scripts/distros.json`.
Blocks without a distribution and architecture header are illustrative.
