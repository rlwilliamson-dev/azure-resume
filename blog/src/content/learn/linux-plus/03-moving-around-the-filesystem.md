---
title: "Where you are, and how to go somewhere else"
description: "Where you are, how to go somewhere else, and how to describe a location two different ways. Three commands that everything else in this track assumes you can already use."
track: "linux-plus"
level: "intro"
order: 40
objectives:
  - "State where you currently are and move somewhere else deliberately"
  - "Write the same location as both an absolute and a relative path"
  - "Read the shorthand characters: dot, dot dot, tilde, and dash"
  - "List files including the ones that are hidden by default"
prerequisites: ["the-terminal-and-how-a-command-works"]
tags: ["linux", "linux-plus", "shell", "beginner"]
updated: 2026-08-07
draft: false
examObjectives:
  - exam: "xk0-006"
    domain: "1.0"
    objective: "1.5"
  - exam: "xk0-006"
    domain: "2.0"
    objective: "2.1"
sources:
  - title: "cd(1p)"
    url: "https://man7.org/linux/man-pages/man1/cd.1p.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "pwd(1)"
    url: "https://man7.org/linux/man-pages/man1/pwd.1.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "ls(1)"
    url: "https://man7.org/linux/man-pages/man1/ls.1.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "path_resolution(7)"
    url: "https://man7.org/linux/man-pages/man7/path_resolution.7.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
symptoms:
  - symptom: "No such file or directory, for a file you can see in the listing"
    anchor: "1-the-file-is-right-there-and-it-says-no-such-file"
---

> **Before you read.** You are given two ways to describe where a friend lives:
> "14 Oak Street, Springfield" and "two doors down on the left".
>
> Both are correct. One works from anywhere and one only works if you already
> know where you are standing. Linux paths work exactly the same way, and mixing
> them up is the most common early mistake there is. Which of the two do you
> think is more likely to break in a script that runs at 3am?

Graphical file managers show you where you are with a window title and a
breadcrumb bar. The terminal shows you almost nothing, so you have to ask, and
the asking becomes automatic quickly.

Three commands do the whole job. `pwd` says where you are, `cd` moves you, and
`ls` shows what is there. Everything in this track after this point assumes you
can use all three without thinking about it.

### Some words you will need

<dl class="terms">
<dt>working directory</dt>
<dd>Where the shell currently is. Commands act here unless you tell them otherwise. Also called the current directory.</dd>
<dt>home directory</dt>
<dd>The directory belonging to your user account, usually <code>/home/yourname</code>. Where you start, and the one place you can always write to.</dd>
<dt>absolute path</dt>
<dd>A location written from the very top, starting with <code>/</code>. Correct from anywhere.</dd>
<dt>relative path</dt>
<dd>A location written from wherever you currently are. Shorter, and only correct from one place.</dd>
</dl>

## What breaks without this

**You act on the wrong thing.** Commands work on the current directory by
default. Run a delete in the directory you think you are in rather than the one
you are actually in, and the command succeeds, which is the problem.

**Your instructions only work for you.** A relative path written down and sent to
somebody standing somewhere else does the wrong thing or fails outright. This is
the single most common reason a script that worked by hand fails when it runs on
a schedule.

**You cannot find your own files.** Listings hide anything beginning with a dot
by default, which is exactly where configuration lives, so a file can be present
and invisible at the same time.

## One tree, no drive letters

Windows gives each disk its own letter and its own tree: `C:\`, `D:\`. Linux has
exactly one tree, starting at `/`, and additional disks appear as directories
somewhere inside it.

So there is no equivalent of "which drive am I on". There is only "where in the
single tree am I", and the answer is always a path starting with `/`.

That single `/` at the top is called the **root directory**. Confusingly, the
administrator account is also called root, and there is a directory named
`/root` which is that account's home. Three different things, same word. Context
tells you which, and this comes up often enough to be worth flagging now.

## Where am I?

```bash
# Debian 13 (trixie), x86_64
$ pwd
/home/sam
```

`pwd` stands for print working directory. It takes no options you will ever need
and it is the answer to a question you should ask whenever anything surprises
you.

## What is here?

`ls` lists a directory. `ls -a` lists it again asking for **all** entries. This
directory contains two folders and one configuration file whose name begins with a
dot.

<details class="predict">
<summary>Plain <code>ls</code> shows two things. How many does <code>ls -a</code> show, three, or more than three?</summary>

```bash
# Debian 13 (trixie), x86_64
$ ls; echo "--- now with -a ---"; ls -a
notes
projects
--- now with -a ---
.
..
.config-example
notes
projects
```

</details>

**Five, not three.** The hidden config file is the one you expected; `.` and
`..` are the surprise, and they are present in **every** directory on the
system without exception. They are not names somebody added, the filesystem
creates them when the directory is made.

Plain `ls` shows two directories. `ls -a` shows five things, and three of them
start with a dot.

**A leading dot means hidden**, and hidden here means nothing more than "`ls`
does not show it unless asked". It is not a permission or a security feature. It
is a convention so that configuration files do not clutter your home directory.

The first two entries are special and always present:

- **`.`** is this directory
- **`..`** is the directory above this one

They look like clutter and they turn out to be two of the most useful things in
the shell.

<details class="deeper">
<summary>If you already administer Linux: the working directory is a kernel object, not a string</summary>

The shell shows you a path, which makes the working directory look like a piece of
text it remembers. It is not. The kernel holds a **reference to the directory
itself**, and every path you type is resolved relative to that reference.

The difference is observable, and it explains behaviour that otherwise looks like
a bug:

```
$ cd /tmp/work
$ mv /tmp/work /tmp/archive     # from another shell
$ pwd
/tmp/work
$ /bin/pwd
/tmp/archive
```

**`pwd` and `/bin/pwd` disagree**, and both are correct. The shell builtin prints
`$PWD`, a string it has been carrying since you last ran `cd`. The external `pwd`
asks the kernel where it actually is by walking back up through `..`. When a
directory is renamed underneath you, the string goes stale and the reference does
not. `pwd -P` forces the builtin to do the real resolution.

Delete the directory instead of renaming it and the shell survives, still
holding a reference to something with no name. `/bin/pwd` then fails outright
and almost every relative path stops working, which produces the memorable
experience of a shell where nothing works and `pwd` looks fine.

The same distinction is what `cd -P` and `cd -L` are about. With symlinks in
the path, `cd -L` keeps the symlinked path in `$PWD` (the default, and the
friendlier answer) while `cd -P` resolves to the physical location. `cd ..`
after following a symlink therefore goes somewhere different depending on
which you used, which is a genuine source of confusion in scripts.

In a script, prefer absolute paths or `cd` with error handling. `cd /some/dir`
that fails leaves you in the previous directory and the next line runs there
anyway, which is how a cleanup script deletes the wrong tree. `cd /some/dir ||
exit` is the one-line habit that prevents it, and it is the reason `set -e`
alone is not enough.

</details>

## Two ways to write the same location

Both of these end up in the same place:

```bash
# Debian 13 (trixie), x86_64
$ cd projects/website; pwd; cd /home/sam/projects/website; pwd
/home/sam/projects/website
/home/sam/projects/website
```

The first is **relative**: `projects/website` means "starting from where I am,
go into `projects`, then into `website`". It has no leading slash, and it only
works because the shell happened to be in `/home/sam`.

The second is **absolute**: `/home/sam/projects/website` starts at `/` and spells
out every step. It works from anywhere.

**The leading slash is the entire difference.** A path starting with `/` is
absolute. Anything else is relative.

Back to the question at the top: the relative one is the one that breaks at 3am,
because a scheduled job does not start in the directory you were sitting in when
you wrote it. Use relative paths when typing, absolute paths when writing
anything down.

## The four shorthands

| Shorthand | Means |
| --- | --- |
| `.` | Here |
| `..` | One level up |
| `~` | Your home directory |
| `-` | The directory you were in before this one |

Given those four and knowing we start in `/home/sam`, trace this sequence before
you look. Four `cd` commands, each followed by a `pwd`.

<details class="predict">
<summary>Where does each <code>pwd</code> report? There are five lines of output, not four, and the reason for the extra one is the interesting part.</summary>

```bash
# Debian 13 (trixie), x86_64
$ cd projects/website; pwd; cd ..; pwd; cd /etc; pwd; cd -; pwd
/home/sam/projects/website
/home/sam/projects
/etc
/home/sam/projects
/home/sam/projects
```

Into `website`, then `..` up one level to `projects`, then an absolute jump to
`/etc`, then `cd -` back to `projects`.

The fifth line is `cd -` itself. Unlike every other form of `cd`, it prints where
it landed, on the theory that if you had to ask to go "back", you may not
remember where back is. So the last two lines are `cd -` announcing itself and
then `pwd` agreeing with it.

</details>

Two notes on that output. `cd -` printed the directory it moved to, which is why
`/home/sam/projects` appears twice: once from `cd -` and once from the `pwd`
after it. And **bare `cd` with no argument goes home**, which is the fastest way
out of anywhere confusing.

`..` chains, so `cd ../..` goes up two levels and `cd ../notes` goes up one and
back down into a sibling directory. That last shape is worth recognising, because
it appears constantly in real paths.

<details class="deeper">
<summary>If you already administer Linux: resolution, symlinks, and CDPATH</summary>

`cd` is a shell builtin rather than a program, and it has to be: a child process
cannot change its parent's working directory. That is also why `cd` inside a
script affects only that script.

`cd` follows symlinks logically by default, so `pwd` reports the path you took
rather than the physical one. `pwd -P` and `cd -P` give the resolved path, which
matters when a symlinked directory makes `cd ..` land somewhere unexpected.

`CDPATH` makes `cd` search a list of parents, which is convenient interactively
and a genuine hazard in scripts, since a bare relative `cd` may then resolve
somewhere you did not intend. Do not export it.

The kernel's rules for walking a path are in `path_resolution(7)`, and the
execute-bit-on-directories consequence of them is the subject of topic 73.

</details>

## Making it faster

Two things that stop the typing being tedious. Both are worth building as habits
now rather than discovering in a year.

**Tab completion.** Type the first few letters of a name and press Tab. The shell
completes it. Press Tab twice to see all the matches when it is ambiguous.

This is not only about speed. Tab completion only completes things that exist, so
a name that will not complete is a name you have got wrong, and you find out
before you press Enter rather than after.

**Up arrow.** Recalls previous commands. Editing the last one is almost always
faster than retyping it.

<details class="deeper">
<summary>If you already administer Linux: what <code>ls</code> is really doing, and when it lies</summary>

`ls` sorts by locale collation, not by byte value, so the order changes with
`LC_COLLATE` and a script that depends on `ls` output ordering is fragile. Set
`LC_ALL=C` when order matters.

`ls` also changes behaviour based on whether stdout is a terminal: colour and
column formatting disappear when piped, which is why `ls | wc -l` gives a
different shape from what you saw on screen. That is deliberate, and it is also
why **parsing `ls` output is a long-standing mistake**. Filenames may contain
spaces, newlines, and quotes, none of which `ls` escapes by default. Use `find
-print0` with `xargs -0`, or a shell glob, and leave `ls` for humans.

Two flags worth having: `-i` shows inode numbers, which is how you prove two
names are one file, and `--time-style=full-iso` gives timestamps you can actually
sort.

</details>


<details class="deeper">
<summary>If you already administer Linux: finding things, and doing it safely</summary>

`cd` and `ls` orient you. `find` is what you reach for when you do not already
know where something is, and it has two traps worth clearing early.

**Order matters, because `find` evaluates left to right.** `find / -name '*.log'
-mtime +30` tests the name first and the age second, which is efficient.
Reversing them tests the age of every file on the system. On a large filesystem
that is the difference between seconds and minutes.

`-exec ... {} +` rather than `{} \;`. The semicolon form runs the command once
per file, a million forks for a million files. The plus form batches them like
`xargs`, and is dramatically faster.

Filenames can contain spaces, quotes, and newlines, which is why parsing `ls`
is a long-standing mistake and why `find -print0 | xargs -0` exists. Anything
that assumes whitespace separates filenames breaks on the first file somebody
names badly, and that file is usually in the directory you were about to
delete from.

Prune before you descend, not after. `find / -path /proc -prune -o -name
'*.conf' -print` skips `/proc` entirely; filtering it out of the results still
walks it. On a machine with network mounts, `-xdev` keeps `find` on one
filesystem and stops it hanging on an unreachable NFS server, which is worth
making a habit.

And the safety one: **run the `find` before the `-delete`.** Look at the list,
then add the action. `-delete` at the end of a command with a mistake in it is
one of the few things in this track with no undo.

</details>

## What trips people up

### 1. The file is right there and it says "No such file"

You can see it in `ls`, and the command insists it does not exist. Almost always
one of three things:

- **Wrong capitalisation.** `Notes` and `notes` are different names.
- **You moved.** The name was relative and you are no longer where you were.
- **A space in the name.** `my file.txt` is two arguments unless it is quoted.

`pwd` and `ls` together answer all three in two seconds.

### 2. Confusing `/` at the start with `/` in the middle

`/etc` is absolute: the `etc` directory at the top of the tree. `etc` is
relative: an `etc` directory inside wherever you are.

The slash in the middle of `projects/website` is just a separator. Only the very
first character decides absolute or relative.

### 3. Expecting `cd` to work on a file

`cd` moves between directories only. Point it at a file and it refuses:

```
bash: cd: /etc/hostname: Not a directory
```

Which is an unusually clear error, and it tells you something useful: the thing
you named exists, it is simply not a directory. `ls -l` shows which is which.

### 4. Losing track after using a relative path several times

Chains like `cd ../../var/log` work, and they are also how people end up
somewhere they did not intend. When output stops making sense, run `pwd`. It is
free and it is right.

## Prove it

Three commands, in this order, whenever anything is confusing:

```bash
# Where am I
pwd

# What is here, including hidden things
ls -a

# What is this thing, exactly
ls -l
```

The third is the one that resolves most confusion. Its first character tells you
what you are looking at: `-` for a normal file, `d` for a directory, `l` for a
symbolic link. The rest of that line is permissions, which is topic 07.

## Work it through

You are asked to look at a log file at `/var/log/syslog` on a machine you have
just logged into. You run:

```
cd /var/log
ls
```

and see a long list including `syslog`. You then run `less syslog` and it works.

The next day you write those same steps into a script that runs automatically at
midnight, and it fails with `syslog: No such file or directory`.

Nothing about the machine changed. Why?

Reason it out before reading on.

**The script did not start where you started.** When you typed those commands you
had already logged in, and your session began in your home directory. The `cd
/var/log` moved you, and `less syslog` worked because `syslog` was relative to
where you now were.

A scheduled job starts somewhere else entirely, often `/` or the account's home,
and does not inherit your session.

**So which line actually failed?** Not the `cd`, which is absolute and works from
anywhere. The `less syslog` failed, because that relative name only means the
right thing if the `cd` above it succeeded.

**Two fixes, and one is better.** You could keep the `cd` and trust it. Or you
could remove the dependency entirely:

```
less /var/log/syslog
```

One absolute path, no assumption about where the script starts, nothing to go
wrong. **Anything written down should use absolute paths.** Relative paths are
for typing, where you can see where you are.

The habit worth taking: when something works by hand and fails on a schedule,
suspect the working directory before anything else.

## Try it

Optional, if you have a machine handy.

1. Run `pwd`. Then `cd /` and `pwd` again. Then bare `cd` and `pwd` a third time.
   Say what happened at each step.
2. From your home directory, run `ls` then `ls -a`. Count the difference and
   explain it.
3. Get to `/var/log` twice: once with a single absolute path, once using only
   relative steps from your home directory.
4. Use `cd -` to bounce between two distant directories a few times.

**Verification step.** You have it when you can start anywhere, reach a named
directory using a relative path only, and then write the absolute path for the
same place without running `pwd` to check.

## Check yourself

<details class="qa">
<summary>What single character tells you whether a path is absolute or relative?</summary>

The **first** character. A leading `/` means absolute, starting from the top of
the tree. Anything else means relative, starting from wherever you happen to be.

Slashes later in the path are just separators between names and tell you nothing
about which kind it is. `etc/hosts` and `/etc/hosts` contain the same characters
in the same order apart from one, and they mean entirely different things.

</details>

<details class="qa">
<summary><code>ls</code> shows two files, <code>ls -a</code> shows six. What are the extra four, and are they hidden in any security sense?</summary>

Two of them are `.` and `..`, which are always present: this directory and the
one above it. The other two are files whose names begin with a dot.

**Nothing is hidden in a security sense.** A leading dot is a naming convention
that `ls` honours by default, and that is the entire mechanism. Anyone who can
read the directory can see them by asking, and `ls -a` is the asking. It exists
so that the dozen configuration files in your home directory do not bury the
three you actually put there.

</details>

<details class="qa">
<summary>You are in <code>/home/sam/projects/website</code>. Write the relative path to <code>/home/sam/notes</code>.</summary>

`../../notes`

Up out of `website`, up out of `projects`, and you are in `/home/sam`, which is
where `notes` lives. Count the levels you need to climb and that is how many
`..` you need.

If counting them makes you uneasy, that instinct is correct, and `cd
/home/sam/notes` is right there and cannot be miscounted.

</details>

<details class="qa">
<summary>A command works when you type it and fails when a scheduled job runs it, with a "no such file" error. What is the first thing to suspect?</summary>

**The working directory.** You typed it from somewhere specific; the scheduled
job started somewhere else and had no way of knowing where you were standing at
the time.

Any relative path in that command is now pointing at a different place, or at
nothing. The fix is absolute paths in anything written down, and the diagnostic
is to have the job run `pwd` and tell you where it thinks it is.

This is worth knowing early because the symptom looks like a permissions problem
or a broken schedule, and it is neither.

</details>

<details class="qa">
<summary>Why is <code>cd</code> unable to move into <code>/etc/hostname</code>, and what does that error tell you about the thing you named?</summary>

`cd` moves between directories, and `/etc/hostname` is a regular file. You cannot
stand inside a file.

The error is more useful than it first appears. `Not a directory` is a different
message from `No such file or directory`, and the difference matters: the thing
you named **exists**, you have simply asked it to do something it is not. If you
had misspelled it you would have got the other error.

Learning to tell those two apart saves a great deal of time, because they point
in opposite directions.

</details>

## References

- [cd(1p)](https://man7.org/linux/man-pages/man1/cd.1p.html) - Linux man-pages project. Accessed 2026-08-07.
- [pwd(1)](https://man7.org/linux/man-pages/man1/pwd.1.html) - Linux man-pages project. Accessed 2026-08-07.
- [ls(1)](https://man7.org/linux/man-pages/man1/ls.1.html) - Linux man-pages project. Accessed 2026-08-07.
- [path_resolution(7)](https://man7.org/linux/man-pages/man7/path_resolution.7.html) - Linux man-pages project. Accessed 2026-08-07.

Every block above with a distribution and architecture header was captured by running the command on a Debian 13 (trixie) container. Blocks without one are illustrative.
