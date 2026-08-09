---
title: "Getting help without leaving the terminal"
description: "How to answer your own questions about a command you have never seen, why the same name can have two completely different manual pages, and how to read a synopsis line."
track: "linux-plus"
level: "intro"
order: 30
objectives:
  - "Find out what an unfamiliar command does without leaving the terminal"
  - "Read a synopsis line and tell required parts from optional ones"
  - "Explain why man passwd and man 5 passwd are different pages"
  - "Search the manuals when you know the job but not the command"
prerequisites: ["the-terminal-and-how-a-command-works"]
tags: ["linux", "linux-plus", "shell", "beginner"]
updated: 2026-08-09
draft: false
examObjectives:
  - exam: "xk0-006"
    domain: "1.0"
    objective: "1.5"
sources:
  - title: "man(1)"
    url: "https://man7.org/linux/man-pages/man1/man.1.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "man-pages(7): conventions for writing Linux man pages"
    url: "https://man7.org/linux/man-pages/man7/man-pages.7.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "apropos(1)"
    url: "https://man7.org/linux/man-pages/man1/apropos.1.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "GNU Info standalone reader manual"
    url: "https://www.gnu.org/software/texinfo/manual/info-stnd/info-stnd.html"
    publisher: "GNU Project"
    accessed: 2026-08-07
    tier: 1
symptoms:
  - symptom: "man: command not found, or No manual entry for a command that exists"
    anchor: "3-the-manual-is-not-always-installed"
---

> **Before you read.** `passwd` is a command that changes your password.
> `/etc/passwd` is a file that lists user accounts. They are different things
> that happen to share a name.
>
> So when you type `man passwd`, which one do you get, and how would you ask for
> the other?

Topic 01 ended with a command nobody had explained: `tar -czf`. This topic is how
you answer that yourself, in about fifteen seconds, without a search engine.

### Some words you will need

<dl class="terms">
<dt>manual page</dt>
<dd>The reference document that ships with a command, on the machine rather than on the internet, and correct for the version installed. Usually shortened to <em>man page</em>.</dd>
<dt>section</dt>
<dd>The manual is split into numbered sections by kind of thing. Section 1 is commands you run, section 5 is file formats, section 8 is administration commands. The same name can appear in more than one.</dd>
<dt>synopsis</dt>
<dd>The line near the top of a man page showing the shape of the command. It is a grammar, not an example you can copy.</dd>
<dt>pager</dt>
<dd>The program that shows one screen of text at a time and waits. <code>man</code> opens its output in one, which is why <code>q</code> is how you leave.</dd>
</dl>

That is worth learning early rather than late. Every other topic in this track
becomes something you can extend on your own once you can read the manual, and
the manual is on the machine already, correct for the version you are actually
running, which is more than can be said for the first result on a search engine.

## What breaks without this

You end up dependent on other people's examples. That works until you hit a
machine with no internet access, or a version whose options changed, or a command
so obscure nobody has blogged about it. All three are normal in server work.

The narrower failure: you find a command that looks right, run it with options
copied from a forum post, and it does something adjacent to what you wanted. The
help was one keystroke away.

## The fastest answer: `--help`

Most commands accept `--help` and print a summary immediately:

Here is the first twelve lines of one. Look at the left-hand column of the option
list as you read it.

<details class="predict">
<summary>Some options in the list below have a short spelling and a long one; others have only a long one. Which kind is <code>--author</code>, and can you guess why it has no letter?</summary>

```bash
# Debian 13 (trixie), x86_64
$ ls --help | head -12
Usage: ls [OPTION]... [FILE]...
List information about the FILEs (the current directory by default).
Sort entries alphabetically if none of -cftuvSUX nor --sort is specified.

Mandatory arguments to long options are mandatory for short options too.
  -a, --all                  do not ignore entries starting with .
  -A, --almost-all           do not list implied . and ..
      --author               with -l, print the author of each file
  -b, --escape               print C-style escapes for nongraphic characters
      --block-size=SIZE      with -l, scale sizes by SIZE when printing them;
                             e.g., '--block-size=M'; see SIZE format below
```

</details>

**`--author` has no short form**, and neither does `--block-size`. The indentation
shows it: options with both spellings start at the left margin with `-a,`, and
options with only a long name are indented to line up underneath.

The reason is simply that there are 26 letters and more options than that.
Short forms went to the ones people type constantly, and everything added
later got a long name only. So the presence or absence of a letter is a rough
guide to how old and how commonly used an option is, and it means **you cannot
assume a short form exists**, which is worth knowing before you go looking for
one that was never there.

The `| head -12` on the end trims it to the first twelve lines, because the full
output is long. That vertical bar is a pipe, and it is covered properly in topic
19. For now it is a way to stop output scrolling past.

Two things to notice in that output. Each option is listed in both its short and
long form, which is the mapping topic 01 described. And the very first line is
the **synopsis**, which is the part worth learning to read.

<details class="deeper">
<summary>If you already administer Linux: when <code>--help</code> and <code>man</code> disagree, and which one is lying</summary>

They can disagree, and knowing which to believe saves an argument with yourself.

**`--help` is compiled into the binary.** It describes the version you are actually
running, and cannot be out of date with respect to it.

The man page is a separate file from a separate package, frequently
`<name>-doc` or a `man-pages` bundle. It can be older than the binary, newer
than the binary, or absent entirely, which is why minimal container images
have commands that work and no manual at all.

So when they disagree, `--help` is right about behaviour. The man page is
usually right about *intent* and always has more detail: exit codes,
environment variables, files consulted, and the standards conformance section
that `--help` never carries.

The version check that settles it:

```
ls --version | head -1
man ls | tail -5
```

The foot of a man page carries the version and date it documents. If that predates
your binary by a major release, prefer `--help`.

**Two structural things worth knowing about man pages themselves:**

`man -k` and `apropos` are the same program, and both read a database that
`mandb` builds. On a fresh container or a machine where nobody has run it,
`apropos` reports nothing found for things that plainly exist. The pages are
there and the index is not. `sudo mandb` fixes it.

`man -a name` shows **every** section matching that name, one after another, rather
than stopping at the first. That is how you discover that `printf` is both a shell
command in section 1 and a C function in section 3, and it is the fastest way to
find out whether the thing you are reading about is the one you meant.

**`whatis` is `man -f`**, giving the one-line description without opening anything,
which is the fastest possible "what is this command" and reads from the same
database.

</details>

## Reading a synopsis line

```
Usage: ls [OPTION]... [FILE]...
```

That notation is a convention, and it is consistent across almost every command:

| Notation | Means |
| --- | --- |
| Plain text | Type it exactly, such as the command name |
| `[square brackets]` | Optional. You may leave it out |
| `...` | You may repeat the previous thing |
| `UPPERCASE` | A placeholder. Substitute your own value |
| `a\|b` | Choose one of these |

So `ls [OPTION]... [FILE]...` reads as: type `ls`, then optionally any number of
options, then optionally any number of files. Everything is optional, which is
why bare `ls` works.

Compare that with a command where something is required. `cp` has this synopsis:

```
cp [OPTION]... SOURCE DEST
```

`SOURCE` and `DEST` are not in brackets, so `cp` cannot be run without them. You
have learned that a `cp` with one argument will fail before ever running it.

## The manual: `man`

`--help` gives a summary. `man` gives the full documentation, which is what you
want when the summary is not enough.

```bash
# Debian 13 (trixie), x86_64
$ man ls 2>/dev/null | head -14
LS(1)                            User Commands                            LS(1)

NAME
       ls - list directory contents

SYNOPSIS
       ls [OPTION]... [FILE]...

DESCRIPTION
       List  information  about  the  FILEs (the current directory by default).
       Sort entries alphabetically if none of -cftuvSUX nor  --sort  is  speci-
       fied.

       Mandatory arguments to long options are mandatory for short options too.
```

Normally `man ls` opens full-screen and you move around in it. The keys:

| Key | Does |
| --- | --- |
| **q** | Quit. The one to know first |
| Space | Down a page |
| Arrow keys | Down or up a line |
| **/word** then Enter | Search for a word |
| **n** | Jump to the next match |
| **h** | Help for the viewer itself |

Every manual page uses the same headings in the same order: NAME, SYNOPSIS,
DESCRIPTION, then usually OPTIONS, EXAMPLES, FILES, and SEE ALSO. **NAME and
SYNOPSIS are often all you need**, and they are the first thing on the page,
which makes `man` far faster than it looks.

<details class="deeper">
<summary>If you already administer Linux: sections, and where the good parts hide</summary>

Two habits worth having. **EXAMPLES is at the bottom** and is frequently the
fastest route to a working command; jump straight there with `/EXAMPLES`.
**SEE ALSO is the discovery mechanism** the manual is actually built around, and
following it is how you find the tool you did not know existed.

`man -k` is `apropos` and `man -f` is `whatis`; both read a database that
`mandb` builds, which is why a freshly built container often returns nothing
until it is generated.

For long options, `man` search is often less useful than piping to `grep`:
`man ls | grep -A2 -- '--time-style'` beats scrolling.

</details>

## The same name, two different manuals

Back to the question at the top. Manual pages are grouped into numbered
**sections**, and the same name can appear in more than one:

| Section | Contains |
| --- | --- |
| **1** | Commands you can run |
| **5** | File formats and configuration files |
| **8** | Commands for system administration |

Those three cover almost everything you will need. `passwd` appears in two of
them:

`man -k` searches the short description of every manual page on the system. You
already know two things: `passwd` is a command that changes passwords, and
`/etc/passwd` is a file listing accounts. You also know section 1 is commands and
section 5 is file formats.

<details class="predict">
<summary>So: will <code>passwd</code> appear once in this list or more than once, and what would tell the entries apart?</summary>

```bash
# Debian 13 (trixie), x86_64
$ man -k passwd 2>/dev/null | head -8
chgpasswd (8)        - update group passwords in batch mode
chpasswd (8)         - update passwords in batch mode
gpasswd (1)          - administer /etc/group and /etc/gshadow
pam_localuser (8)    - require users to be listed in /etc/passwd
passwd (1)           - change user password
passwd (5)           - the password file
pwhistory_helper (8) - update passwords in batch mode
update-passwd (8)    - safely update /etc/passwd, /etc/shadow and /etc/group
```

</details>

There it is on lines five and six:

- **`passwd (1)`** - change user password. The command.
- **`passwd (5)`** - the password file. The file format.

`man passwd` gives you section 1, because `man` returns the lowest-numbered
section by default. To get the other one, name the section first:

```
man 5 passwd
```

That is the syntax people find surprising: the number goes **before** the name.
This comes up constantly with configuration files, because the file and the tool
that manages it usually share a name.

<details class="deeper">
<summary>If you already administer Linux: the sections you will actually reach for</summary>

The full set is nine, and the ones beyond 1, 5, and 8 earn their keep more often
than people expect:

| Section | Contains | When you want it |
| --- | --- | --- |
| 2 | System calls | Reading `strace` output, or working out what a program is really asking the kernel for |
| 3 | Library functions | C interfaces, and the reason `man 3 printf` differs from `man 1 printf` |
| 7 | Overviews and conventions | The best pages on the system. `man 7 signal`, `man 7 path_resolution`, `man 7 hier`, `man 7 capabilities` |

Section 7 is genuinely underused. It is where the conceptual documentation lives,
and several pages there are better written than most books on the same subject.

Distribution differences worth knowing: Debian splits documentation into
`man-db` plus `manpages` plus `manpages-dev`, so a system can have `man` working
and still be missing sections 2 and 3. The RHEL family bundles more by default
but strips it in the minimal and container images.

</details>


<details class="deeper">
<summary>If you already administer Linux: what to read when the man page is the wrong document</summary>

A man page documents a command. Three questions it is a poor answer to, and where
to go instead.

**"How do I configure this service?"** The man page for the daemon covers its
command-line flags; the one you want is the **section 5 page for its config
file**: `man 5 sshd_config`, `man 5 nginx.conf` where it exists. Failing that,
`/usr/share/doc/<package>/` frequently holds a full manual, worked examples,
and a `NEWS` or `changelog` explaining what changed between versions. `rpm -qd
<package>` and `dpkg -L <package> | grep /doc/` list exactly what a package
installed there.

**"Why is this behaving differently from the documentation?"** Because the
documentation you found online is for a different version. `man` on the machine
in front of you describes what is installed on it, which is the version that
matters, and this is the single strongest argument for reading the local page
rather than searching.

"What does this error mean?" `man 3 errno` and `man 7 signal` decode the
numbers that appear in strace output and crash messages. `errno 28` meaning
`ENOSPC` is the kind of thing that turns an opaque log line into an obvious
problem.

`apropos` only works if the index exists. On a minimal image, `mandb` has
never run and `apropos` returns nothing for everything. `sudo mandb` builds
it, which is the fix for "the search feature is broken".

</details>

## Searching when you do not know the command

Sometimes the problem is the other way round: you know the job, not the name.

```
man -k compress        # or: apropos compress
```

That searches the short description of every installed manual page. It is a
crude search and it works well enough to find the tool, which is all you need,
because once you have a name you can read its page properly.

## `info`, and when you need it

A few GNU programs keep their real documentation in a different system called
`info`, and their manual page is a stub that says so. If `man something` looks
suspiciously thin and mentions info, try:

```
info something
```

Navigation is different and less intuitive than `man`. `q` still quits. In
practice you will meet this mostly with `coreutils` programs, and the manual page
is usually sufficient anyway.

## What trips people up

### 1. Not knowing how to get out

`man` opens full-screen and there is no visible instruction for leaving. People
close the whole terminal window.

**`q` quits.** It works in `man`, in `less`, and in most full-screen text
viewers, because they are all the same viewer underneath.

### 2. Reading the synopsis as an example

`ls [OPTION]... [FILE]...` is a description of the shape, not something to type.
Beginners occasionally type the brackets. They are notation, and so are the
capital letters.

### 3. The manual is not always installed

Minimal server images and most container images ship without manual pages to
save space. You get:

```
bash: man: command not found
```

or a `man` that exists but reports no entry for a command that is clearly
installed. That is not a broken system, it is a deliberately trimmed one. Install
the documentation, on Debian and Ubuntu with `man-db` and `manpages`, on the RHEL
family with `man-db` and `man-pages`. `--help` works either way, which is a good
reason to reach for it first.

### 4. Assuming the internet is more current than the machine

An answer from a search engine was written for some version, on some
distribution, at some point in the past, and it does not say which. The manual on
the machine describes exactly the version you are about to run.

Where a web search genuinely wins is when you do not know the vocabulary yet.
Once you have a command name, the local manual is the better source.

## Prove it

Given any unfamiliar command, three steps in order:

```bash
# 1. Does it exist here at all
command -v somecommand

# 2. The fast summary
somecommand --help | head -20

# 3. The full documentation
man somecommand
```

If step 1 prints nothing, stop. Nothing else will work, and the answer is that
the program is not installed rather than that you typed it wrong.

## Work it through

Topic 01 left you with this line and one precise question:

```
tar -czf backup.tar.gz /home/sam/notes
```

You worked out the shape: three combined short options, an output file, and an
input directory. What you did not know was what `c` and `z` mean.

Answer it now, without running anything.

**Start with the summary**, because you have one specific question rather than a
need for the whole manual:

```
tar --help | head -30
```

**Look for the three letters individually.** They are separate options, so you
are looking for `-c`, `-z`, and `-f`, not for `czf` as a word. That is the step
people miss.

You will find that `-c` creates an archive, `-z` compresses it with gzip, and
`-f` names the file to write. So the line reads: create a compressed archive
called `backup.tar.gz` containing `/home/sam/notes`.

**Now check the danger.** `-f` names a file to **write**, and there is nothing in
that command warning you if it already exists. `tar` will overwrite it without
asking. That is the kind of thing worth knowing before you run something on a
real machine, and you found it in the documentation rather than the hard way.

The reasoning that matters: you did not search the internet, you did not run it
to find out, and you turned an unfamiliar command into a known one using a tool
that was already installed.

## Try it

Optional, if you have a machine handy.

1. Run `man ls`. Find the option that shows file sizes in a human-readable form,
   using `/` to search rather than scrolling. Then quit without closing the
   window.
2. Run `man passwd`, note what it describes, then run `man 5 passwd` and note how
   different it is.
3. Use `man -k` to find a command for comparing two files, then read its NAME and
   SYNOPSIS only.

**Verification step.** You have it when you can take a command you have never
seen, say what it does, and name which of its arguments are required, without
running it.

## Check yourself

Answer before opening. A wrong guess followed by the reason is worth more than a
right guess followed by nothing.

<details class="qa">
<summary>In <code>cp [OPTION]... SOURCE DEST</code>, which parts may be omitted, and how can you tell?</summary>

Only `[OPTION]...` may be omitted, because it is the only part in square
brackets. `SOURCE` and `DEST` are bare, which means required.

So `cp` on its own will fail, and `cp onefile` will also fail, and you knew both
of those without running anything. That is the whole reason the notation is worth
five minutes.

</details>

<details class="qa">
<summary>You need the format of the <code>/etc/fstab</code> file, not a command. What do you type?</summary>

`man 5 fstab`.

Section 5 is file formats, and the number goes before the name. The trap is that
`man fstab` might well work here too, since there is no `fstab` command competing
for the name. Get in the habit of naming the section anyway, because the moment
there is a competing command, the unqualified version silently gives you the
wrong page.

</details>

<details class="qa">
<summary><code>man</code> opens and you are stuck in it. Which key?</summary>

**`q`.**

The same key quits `less`, and `man` is really `less` wearing a hat, which is why
the navigation feels identical. If `q` ever fails you, Ctrl+C is the bigger
hammer.

</details>

<details class="qa">
<summary>A command exists but <code>man</code> says there is no entry for it. Give the most likely reason and one thing that would still work.</summary>

The manual pages are not installed. Minimal server images and nearly all
container images strip them to save space, so the program is there and its
documentation is not.

`--help` still works, because that text is compiled into the program itself
rather than shipped as a separate file. That is exactly why this topic reaches
for `--help` first: it is the one that survives a stripped-down system.

The fix is installing `man-db` plus the manual page collection for your
distribution, at which point everything works again.

</details>

<details class="qa">
<summary>Why is the manual on the machine often a better answer than a search result?</summary>

Because it describes the version you are actually about to run, on the
distribution you are actually on. A search result was written for some version,
on some distribution, at some point in the past, and usually says none of the
three.

The honest exception is when you do not know the vocabulary yet. `man` is
excellent at telling you how a command works and useless at telling you which
command you want. Once you have a name, come back to the machine.

</details>

## References

- [man(1)](https://man7.org/linux/man-pages/man1/man.1.html) - Linux man-pages project. Accessed 2026-08-07.
- [man-pages(7)](https://man7.org/linux/man-pages/man7/man-pages.7.html) - Linux man-pages project. Accessed 2026-08-07.
- [apropos(1)](https://man7.org/linux/man-pages/man1/apropos.1.html) - Linux man-pages project. Accessed 2026-08-07.
- [GNU Info standalone reader manual](https://www.gnu.org/software/texinfo/manual/info-stnd/info-stnd.html) - GNU Project. Accessed 2026-08-07.

Every block above with a distribution and architecture header was captured by running the command on a Debian 13 (trixie) container. Blocks without one are illustrative.
