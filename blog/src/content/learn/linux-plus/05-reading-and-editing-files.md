---
title: "Reading files, editing files, escaping vi"
description: "Look inside a file without opening an editor, then change one line and save it. Plus the four commands that create, copy, rename, and delete, one of which does not ask twice."
track: "linux-plus"
level: "intro"
order: 60
objectives:
  - "Read a file three different ways and choose the right one for its size"
  - "Open a config file, change a line, and save it without a graphical editor"
  - "Escape from vi without losing work, and without panicking"
  - "Create, copy, rename, and delete files, knowing which of those is irreversible"
prerequisites: ["moving-around-the-filesystem"]
tags: ["linux", "linux-plus", "files", "editors", "beginner"]
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
  - title: "cat(1)"
    url: "https://man7.org/linux/man-pages/man1/cat.1.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "head(1)"
    url: "https://man7.org/linux/man-pages/man1/head.1.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "tail(1)"
    url: "https://man7.org/linux/man-pages/man1/tail.1.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "cp(1)"
    url: "https://man7.org/linux/man-pages/man1/cp.1.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "mv(1)"
    url: "https://man7.org/linux/man-pages/man1/mv.1.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "rm(1)"
    url: "https://man7.org/linux/man-pages/man1/rm.1.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "vi(1p)"
    url: "https://man7.org/linux/man-pages/man1/vi.1p.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "GNU nano manual"
    url: "https://www.nano-editor.org/dist/latest/nano.html"
    publisher: "GNU nano"
    accessed: 2026-08-07
    tier: 1
symptoms:
  - symptom: "Stuck in vi and cannot get out"
    anchor: "2-trapped-in-vi"
  - symptom: "Overwrote a file with cp and got no warning"
    anchor: "3-cp-and-mv-overwrite-without-asking"
---

> **Before you read.** Almost everything you will ever configure on a Linux
> system is a plain text file. Not a settings dialog, not a registry, not a
> database. A file, with words in it, that you edit with an editor.
>
> That is either a relief or a horror depending on the day. Either way, here is
> the question worth holding onto: if configuration is just text, what stops you
> from breaking a system with a single typo?

Nothing stops you. That is the deal. In exchange, you get to fix any machine on
earth with commands you already know, and you get to see exactly what changed,
which is more than most systems will give you.

This lesson covers reading a file, changing a file, and moving files about.
Three unglamorous skills that turn up in every single thing you will do later.

### Some words you will need

<dl class="terms">
<dt>plain text</dt>
<dd>A file containing nothing but characters. No fonts, no formatting, no hidden structure. What you see is the entire file.</dd>
<dt>editor</dt>
<dd>A program for changing a text file. On a server there is no window and no mouse, so the editor runs inside the terminal.</dd>
<dt>pager</dt>
<dd>A program that shows a long file one screen at a time and lets you scroll. <code>less</code> is the usual one.</dd>
<dt>config file</dt>
<dd>A plain text file that a program reads on startup to decide how to behave. Usually somewhere under <code>/etc</code>.</dd>
</dl>

## What breaks without this

**You cannot diagnose anything.** Every log is a text file and every setting is a
text file. If reading them is awkward, every problem takes an hour longer than it
needs to.

**You get stuck in an editor and lose an hour.** This is not a joke and it is not
rare. `vi` opens on systems where nothing else is installed, it does not behave
like any editor you have used, and there is no visible way out. People have
rebooted servers over this.

**You destroy something quietly.** `cp` and `mv` overwrite the destination
without a word. `rm` deletes without asking. There is no recycle bin, no undo,
and no "are you sure". The commands assume you meant it.

## Reading a file: three commands and when to use which

| Command | Use it when | What it does |
| --- | --- | --- |
| `cat` | The file is short | Dumps the whole thing and returns you to the prompt |
| `less` | The file is long | Opens a scrollable view you quit with `q` |
| `head` / `tail` | You want the start or the end | Prints ten lines by default |

Start with `cat`, which prints the file and stops:

```bash
# Debian 13 (trixie), x86_64
$ cat /etc/os-release
PRETTY_NAME="Debian GNU/Linux 13 (trixie)"
NAME="Debian GNU/Linux"
VERSION_ID="13"
VERSION="13 (trixie)"
VERSION_CODENAME=trixie
DEBIAN_VERSION_FULL=13.6
ID=debian
HOME_URL="https://www.debian.org/"
SUPPORT_URL="https://www.debian.org/support"
BUG_REPORT_URL="https://bugs.debian.org/"
```

That is a genuinely useful file, incidentally. It is how you find out what
distribution you have landed on, and it exists on all of them.

`cat` is fine here because the file is eleven lines. Point it at a 400,000-line
log and it will print all 400,000 lines, most of which scroll past faster than
you can read, and the only thing you learn is that the file was long.

### The start and the end

`head` and `tail` take the first or last ten lines. Both accept `-n` to change
the count:

```bash
# Debian 13 (trixie), x86_64
$ head -n 4 /etc/passwd; echo ...; tail -n 2 /etc/passwd; wc -l /etc/passwd
root:x:0:0:root:/root:/bin/bash
daemon:x:1:1:daemon:/usr/sbin:/usr/sbin/nologin
bin:x:2:2:bin:/bin:/usr/sbin/nologin
sys:x:3:3:sys:/dev:/usr/sbin/nologin
...
_apt:x:42:65534::/nonexistent:/usr/sbin/nologin
nobody:x:65534:65534:nobody:/nonexistent:/usr/sbin/nologin
18 /etc/passwd
```

Six lines of an eighteen-line file, and `wc -l` counting them. That `...` in the
middle is not output, it is an `echo` putting a marker between the two halves so
you can tell them apart.

**`tail` is the one you will use most**, because log files append at the bottom.
The newest thing that happened is the last line, so "what just went wrong" is
almost always `tail`.

`tail -f` is the follow mode: it prints the end of the file and then keeps
printing new lines as they arrive, live. Start it, reproduce the problem in
another window, and watch the error appear. It runs until you stop it with
**Ctrl+C**, the same key that got you out of trouble in lesson 01.

### The long ones

`less` opens a file in a scrollable view. It is the right choice for anything you
cannot see in one screen.

| Key | Does |
| --- | --- |
| Arrow keys | Line at a time |
| Space | Page down |
| `b` | Page back |
| `g` / `G` | Jump to the start / the end |
| `/word` | Search forward for "word", then `n` for the next match |
| `q` | Quit |

The important one is `q`. `less` takes over the whole terminal, so if you do not
know how to leave it, it looks exactly like a hang.

<details class="deeper">
<summary>If you already administer Linux: `cat` misuse, and why `less` is not `more`</summary>

`cat` concatenates, which is what the name is short for, and the single-argument
form is a degenerate case of that. `cat file | grep pattern` is the classic
useless use of `cat`: `grep pattern file` does the same work with one process
instead of two. Nobody will die, but it is a tell.

`cat` on a binary will happily send control sequences to your terminal and leave
it in a state where your typing is invisible. `reset` fixes it. `less` refuses,
or asks first, which is one more reason to reach for it by default.

`less` was written because `more` could only go forward, hence the name. On most
distributions `more` is now a symlink or a thin wrapper, but not all, and on a
container image you may find `more` present and `less` absent. `less -S` stops
long lines wrapping, `less +F` starts in follow mode and is `tail -f` you can
scroll back through, and `less` is what `man` uses under the hood, which is why
the navigation keys you learned in lesson 02 work here too.

</details>

## The editor problem nobody warns you about

Here is a thing that catches people out. You have read a tutorial that says "open
the file in nano". You try it:

```bash
# Debian 13 (trixie), x86_64
$ for e in nano vi vim less more cat; do printf "%-6s " "$e"; command -v "$e" || echo "(not installed)"; done
nano   (not installed)
vi     (not installed)
vim    (not installed)
less   (not installed)
more   /usr/bin/more
cat    /usr/bin/cat
```

No nano. No vi. No vim. No `less`. That is a real, stripped-down Debian image,
and it has no text editor at all.

Now the same check on AlmaLinux:

```bash
# AlmaLinux 10.2, x86_64
$ for e in nano vi vim less more cat; do printf "%-6s " "$e"; command -v "$e" || echo "(not installed)"; done
nano   (not installed)
vi     /usr/bin/vi
vim    (not installed)
less   /usr/bin/less
more   /usr/bin/more
cat    /usr/bin/cat
```

Different distribution, different answer. `vi` is there, `nano` is not.

Those two captures are from container images, which are deliberately minimal; a
normal server install of either distribution usually has more. But minimal
images are exactly what you meet in a container, a cloud instance, or a rescue
environment, and the lesson holds everywhere:

**`command -v` before you assume.** It costs a second and it saves you from
typing a tutorial's instructions into a machine that cannot follow them.

And the practical consequence: **learn enough `vi` to survive**, because `vi` is
the one that is most often already there, and because it is the only editor the
POSIX standard requires.

## nano, which behaves like you expect

If `nano` is available, use it. It is a normal editor: the arrow keys move, you
type and the text appears, and the commands are printed along the bottom of the
screen so there is nothing to memorise.

```
nano /etc/hosts
```

The bottom two lines look like this:

```
^G Help    ^O Write Out   ^W Where Is   ^K Cut     ^T Execute
^X Exit    ^R Read File   ^\ Replace    ^U Paste   ^J Justify
```

**`^` means Ctrl.** So `^O` is Ctrl+O and `^X` is Ctrl+X. That single piece of
notation is the only thing about nano that is not obvious, and it trips up
roughly everyone the first time.

The whole workflow:

1. `nano filename` to open
2. Arrow keys to the line, type your change
3. **Ctrl+O** to write out, then Enter to confirm the filename
4. **Ctrl+X** to exit

Ctrl+O then Ctrl+X. Save, then quit. If you hit Ctrl+X with unsaved changes it
asks whether you want to save, so there is a safety net.

## vi, which does not

`vi` is different in a way that is genuinely confusing until someone tells you
the trick, at which point it is fine forever.

**`vi` has modes.** When it opens you are in *normal mode*, where the letter keys
are commands rather than text. Press `i` and you enter *insert mode*, where they
are text again. Press **Esc** and you are back to normal mode.

That is the whole secret. Everyone who has ever been trapped in `vi` was trapped
because they were in the wrong mode and did not know it.

The survival sequence, which is all you need for this exam and for most of your
career:

| Step | Keys |
| --- | --- |
| Open | `vi filename` |
| Start typing | `i` |
| Stop typing | `Esc` |
| Save and quit | `:wq` then Enter |
| Quit, discarding everything | `:q!` then Enter |

`:wq` is write and quit. `:q!` is quit, and the `!` means "yes, I know, do it
anyway". **`:q!` is the escape hatch.** If you have got yourself into a state you
do not understand, press Esc, type `:q!`, press Enter, and you are out with the
file untouched.

Press Esc first even if you think you are already in normal mode. Pressing Esc
when you are already in normal mode does nothing at all, which makes it free.

<details class="predict">
<summary>You open a file in `vi`, forget to press `i`, and type the word `dead` before noticing. What has happened to the file, and what should you press?</summary>

In normal mode those four letters are four commands, not text. `d` starts a
delete and waits for what to delete, `d` again completes it as "delete this
line", so `dd` has removed a line. Then `e` moved to the end of a word and `a`
put you into insert mode.

So: a line is gone, and you are now genuinely inserting text.

**Press Esc, then type `:q!` and Enter.** Nothing has been written to disk yet,
because `vi` edits a copy in memory and only writes when told to. Quitting
without saving discards the damage entirely.

This is the single most useful thing to know about `vi`, and it is why `:q!` is
worth committing to memory before anything else.

</details>

<details class="deeper">
<summary>If you already administer Linux: what `vi` actually is on a modern system</summary>

`vi` is almost never `vi`. On the Debian family it is usually `vim.tiny` via the
alternatives system, on RHEL family it is `vim-minimal`, and on BusyBox systems
it is a small independent implementation. They differ: `vim.tiny` has no syntax
highlighting and no visual mode, so a keystroke you rely on may silently do
nothing.

Two habits worth having. `vi -R` opens read-only when you only meant to look,
which stops the "I did not mean to change that" class of accident. And `vim -u
NONE` skips every config, which is how you find out whether a strange behaviour
is `vim` or somebody's `.vimrc`.

The swap file matters operationally: an interrupted session leaves a `.swp`
alongside the original, and the next person to open the file gets a recovery
prompt that reads like an error. It is not one. `:recover` or delete the swap.

`vi` is also the reason `EDITOR` and `VISUAL` exist. `visudo`, `crontab -e`, and
`systemctl edit` all launch whatever those variables name, defaulting to `vi`.
Setting `EDITOR=nano` in your shell profile is a legitimate choice and not a
character flaw.

</details>


<details class="deeper">
<summary>If you already administer Linux: editing a file nothing can open, and editors as a security surface</summary>

**A file too large to open is a real situation** — a 40 GB log, a database dump.
`sed -n '1000,1200p' file` prints a range without loading the rest, `head -c 1M`
takes bytes rather than lines, and `sed -i` edits in place. Note that `sed -i`
does **not** edit in place in the way the name suggests: it writes a new file and
renames it over the original, which breaks hard links, changes the inode, and
needs free space equal to the file. On a full disk it fails halfway, which is
precisely when you were trying to free space by trimming a log.

**Truncating an open log file** is the specific case worth knowing.
`> /var/log/huge.log` empties it while the writing process keeps its file handle
and its offset, so the file immediately becomes sparse and the space is not
returned. `truncate -s 0` has the same problem. The answer is `logrotate` with
`copytruncate`, or signalling the process to reopen its log.

**Deleting a file does not free the space if something has it open.** `df` shows
the disk full, `du` shows it empty, and the difference is a deleted file with a
live handle. `lsof +L1` lists exactly those, and the space returns when the
process closes or restarts.

**Editors are a security surface** more than they look. `vi` swap files
(`.filename.swp`) can contain the contents of a file you were editing with
restricted permissions, sitting beside it at whatever your umask allows. Editing
`/etc/shadow` in a directory somebody else can read leaves a copy behind. `sudoedit`
exists for exactly this: it copies the file to a temporary location, edits it as
**you**, and copies it back with privilege — so the editor never runs as root and
never writes its scratch files where root's umask puts them.

</details>

## Creating, copying, renaming, deleting

Four commands. Three of them are polite and one is not.

```bash
# Debian 13 (trixie), x86_64
$ cd /tmp; touch newfile.txt; ls -l newfile.txt; rm newfile.txt; ls -l newfile.txt
-rw-r--r--. 1 root root 0 Aug  8 00:19 newfile.txt
ls: cannot access 'newfile.txt': No such file or directory
```

`touch` created an empty file. `rm` deleted it, said nothing, and asked nothing.
The only evidence that `rm` did anything is that the second `ls` fails.

(That trailing `.` on the mode string means a security label is attached. It
comes from the host these captures ran on and you can ignore it for now; the mode
string itself is lesson 07.)

**`rm` does not ask and there is no recycle bin.** The file is gone. Not in a
trash folder, not recoverable by a normal user, gone. The command did exactly
what you told it to, which is the problem.

| Command | Does | Careful because |
| --- | --- | --- |
| `touch f` | Creates `f` empty, or updates its timestamp if it exists | Harmless |
| `cp a b` | Copies `a` to `b` | Silently overwrites `b` |
| `mv a b` | Renames `a` to `b`, or moves it into `b` if `b` is a directory | Silently overwrites `b` |
| `rm f` | Deletes `f` | Immediately and permanently |

`mv` doing both renaming and moving surprises people, but it is one operation
seen from two angles: you are changing the file's full path, and whether that
reads as a rename or a move depends only on whether the directory part changed.

Directories need a flag. `cp -r` copies a directory and its contents, `rm -r`
deletes a directory and its contents. `rmdir` removes a directory only if it is
already empty, which makes it the safe one.

### The silent overwrite

Two files. `report.txt` contains the text `THE IMPORTANT FILE`. `notes.txt`
contains two lines of notes. Then somebody runs `cp notes.txt report.txt`.

<details class="predict">
<summary>What does `ls` show afterwards, and what does `cat report.txt` show? The first answer is the one that matters.</summary>

```bash
# Debian 13 (trixie), x86_64
$ ls; cp notes.txt report.txt; ls; cat report.txt
notes.txt
report.txt
notes.txt
report.txt
first line
second line
```

**The listing is identical before and after.** Two files, same names, no warning,
no output from `cp` at all. Nothing on screen suggests anything happened.

`cat report.txt` is where it shows up: the important file now contains the
contents of the notes file. The original text is not recoverable. `cp` was told
to make the destination match the source and it did precisely that.

</details>

The argument order is worth saying out loud, because it is the source of the
mistake: **source first, destination second**. `cp a b` means "make `b` a copy of
`a`". If you get it backwards you overwrite the file you meant to protect, and
you find out later.

`-i` makes both `cp` and `mv` ask before overwriting. It is not on by default and
the exam expects you to know it is not.

## Across distributions

| | RPM family | dpkg family |
| --- | --- | --- |
| `vi` present on a minimal install | Usually, as `vim-minimal` | Often not; `vim.tiny` when it is |
| `nano` present on a minimal install | Frequently not | Frequently not |
| Install an editor | `dnf install nano` | `apt install nano` |
| `EDITOR` default | `vi` | `vi`, sometimes `nano` on Ubuntu |

Reading and writing files behaves identically everywhere. Which editor is sitting
there when you arrive does not, which is the whole point of the section above.

## Prove it

After editing a config file, three checks before you walk away:

```bash
# Did the change land where you think
grep 'the-setting-you-changed' /etc/thefile

# Did you accidentally save to a different name
ls -l /etc/thefile

# Does the program still parse it
# (most services have a config test; use it before restarting)
```

That last one saves the most grief. Editing a config file is easy; discovering at
restart that you broke the syntax and the service will no longer start is the
expensive part.

## What trips people up

### 1. `cat` on something enormous

You `cat` a log file, thousands of lines fly past, and the terminal is now
useless to you. Nothing is broken. Ctrl+C stops it.

Then use the right tool: `tail -n 50 file` for the recent end, `less file` to
scroll, `grep pattern file` when you know what you are looking for.

### 2. Trapped in vi

The keys do nothing, or they do something alarming, and there is no menu.

**Esc, then `:q!`, then Enter.** You are out, and the file on disk is exactly as
it was. Remember it as three steps: stop what you are doing, quit, insist.

If you did want to keep the changes, `:wq` instead. The difference between those
two is the difference between a bad afternoon and a fine one.

### 3. `cp` and `mv` overwrite without asking

Covered above, and worth repeating because it is the one that costs real data.
There is no prompt and no warning. `cp -i` and `mv -i` add one.

Some distributions alias `cp` to `cp -i` for the root user, which is well
intentioned and actively harmful, because you get used to a prompt that will not
be there on the next machine. Do not rely on it.

### 4. Editing a file you cannot write to

You open `/etc/hosts` as a normal user, make your change, and the save fails.
`nano` reports an error at the bottom of the screen; `vi` says something like
`E45: 'readonly' option is set`.

The edit is not the problem, the permission is. That is lesson 06 and lesson 07,
and it is the single most common reason an edit does not stick.

## Work it through

A service will not start. Somebody tells you the config is at
`/etc/myapp/config.conf` and that "someone changed something last week".

You are on a machine you have not used before. Reason through what you do, in
order, before reading on.

**First, look before you touch.** `cat` if it is short, `less` if it is not. You
cannot fix a file you have not read, and reading is free.

**Second, check what the last change was.** If there is a `.bak` or a `.rpmsave`
alongside it, `diff` the two and the change is right there. Backups from package
upgrades land next to the original with a suffix, which is a convention worth
knowing.

**Third, copy it before you edit it.** `cp config.conf config.conf.bak` costs
nothing and gives you a known-good state to return to. Everyone agrees with this
and about half of us actually do it.

**Fourth, edit.** `nano` if it is there. If not, `vi`, and remember `i` to type
and Esc then `:wq` to save.

**Fifth, prove it.** Re-read the file, confirm your line is what you think it is,
and use the service's own config test if it has one.

Now the question underneath all of that: **why did we check what editors exist
before starting rather than just typing `nano`?** Because on an unfamiliar
machine `nano` may not be installed, and the failure mode is not obvious. `nano
config.conf` on a system without nano gives you `command not found` and no file
open, which is fine. But `vi config.conf` on a system where you expected nano
gives you an open editor that does not respond to any key you try, and *that* is
the one that eats twenty minutes.

## Try it

Optional, if you have a machine handy.

1. `cat /etc/os-release`. Then `less /etc/services`, scroll a page, search for
   `http` with `/http`, and quit with `q`.
2. `head -n 3 /etc/passwd` and `tail -n 3 /etc/passwd`. Then `wc -l /etc/passwd`
   and confirm the numbers make sense together.
3. In your home directory: `touch test.txt`, open it in whatever editor exists,
   type a line, save, quit, and `cat` it to prove the text is there.
4. Open it again in `vi`, type nothing, and get out with `:q!`. Do it three
   times until it is muscle memory.
5. `cp test.txt test2.txt`, then `mv test2.txt renamed.txt`, then `rm
   renamed.txt`. Run `ls` after each and narrate what changed.

**Verification step.** You have it when you can open an unfamiliar file, change
one line, save it, and confirm the change with a second command, on a machine
where you did not know in advance which editor was installed.

## Check yourself

<details class="qa">
<summary>You are dropped onto a server, run `vi /etc/hosts`, and now nothing you type appears on screen. What has happened and what are the two keystrokes that get you out safely?</summary>

You are in **normal mode**, where letters are commands rather than text. `vi`
always starts there. Your typing is being interpreted, not inserted, which is why
nothing appears where you expect it.

**Esc, then `:q!` and Enter.** Esc guarantees you are in normal mode; `:q!` quits
and discards. Nothing has touched the file on disk, because `vi` works on a copy
in memory until you tell it to write.

The near-miss people reach for is Ctrl+C, which works in most other programs and
does nothing useful here. And if you wanted to keep the change, `:wq` rather than
`:q!` — the difference is one character and it is the whole ballgame.

</details>

<details class="qa">
<summary>A colleague runs `cp backup.conf production.conf` when they meant it the other way round. What does the terminal tell them?</summary>

Nothing. `cp` prints no output on success, and success here means "the
destination now matches the source", which is exactly what it was asked for.

`production.conf` has been replaced by the backup's contents and the previous
contents are not recoverable. The listing looks unchanged, both files are still
there, both have the same names as before.

**Source first, destination second.** The wrong-way-round mistake is common
enough that `cp -i` exists to prompt, but it is not the default, and the exam
expects you to know it is not.

</details>

<details class="qa">
<summary>Why is `tail` more useful than `head` for reading logs, and what does `tail -f` add?</summary>

Logs append. New entries go on the end, so the most recent event is the last
line and `tail` shows it without reading through everything before it. `head`
would show you the oldest entries in the file, which is usually the least
interesting thing available.

**`tail -f` follows the file**: it prints the end and then stays running,
printing new lines as they are written. That turns log reading from a snapshot
into a live view, which is what you want when you are about to reproduce a
problem deliberately.

It runs until you stop it with Ctrl+C. It is not hung, it is waiting.

</details>

<details class="qa">
<summary>You need to edit a config file on a minimal container image and `nano` is not installed. Name two things you should check before concluding you cannot edit the file.</summary>

**Check whether `vi` is there**, with `command -v vi`. It very often is, because
POSIX requires it and distributions ship a minimal build for exactly this reason.

**Check whether you can install an editor**, with the distribution's package
manager. `dnf install nano` or `apt install nano` takes seconds if the machine
has a network and a working repository, and that is lesson 08.

A third answer that is also correct: you can edit a file without an interactive
editor at all, using redirection or `sed`. That is a later lesson, but it is why
"no editor installed" is an inconvenience rather than a dead end.

</details>

<details class="qa">
<summary>What is the difference between `rm` and `rmdir`, and which one would you rather run by accident?</summary>

`rmdir` removes a directory **only if it is already empty**, and refuses with
`Directory not empty` otherwise. `rm -r` removes a directory and everything
inside it, recursively, without asking.

You would very much rather run `rmdir` by accident. Its refusal to touch a
non-empty directory means the worst case is that you delete something with
nothing in it.

The habit worth building: `ls` the directory before you remove it. Two seconds of
looking, against a deletion with no undo.

</details>

## References

- [cat(1)](https://man7.org/linux/man-pages/man1/cat.1.html) - Linux man-pages project. Accessed 2026-08-07.
- [head(1)](https://man7.org/linux/man-pages/man1/head.1.html) - Linux man-pages project. Accessed 2026-08-07.
- [tail(1)](https://man7.org/linux/man-pages/man1/tail.1.html) - Linux man-pages project. Accessed 2026-08-07.
- [cp(1)](https://man7.org/linux/man-pages/man1/cp.1.html) - Linux man-pages project. Accessed 2026-08-07.
- [mv(1)](https://man7.org/linux/man-pages/man1/mv.1.html) - Linux man-pages project. Accessed 2026-08-07.
- [rm(1)](https://man7.org/linux/man-pages/man1/rm.1.html) - Linux man-pages project. Accessed 2026-08-07.
- [vi(1p)](https://man7.org/linux/man-pages/man1/vi.1p.html) - Linux man-pages project. Accessed 2026-08-07.
- [GNU nano manual](https://www.nano-editor.org/dist/latest/nano.html) - GNU nano. Accessed 2026-08-07.

Every block above with a distribution and architecture header was captured by running the command on a Debian 13 (trixie) container and an AlmaLinux 10.2 container. Blocks without one are illustrative.
