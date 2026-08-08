---
title: "The terminal, and what to type at it"
description: "What the black window actually is, what the prompt is telling you, and the three parts every command is built from. The first thing to learn, and the thing everything else assumes."
track: "linux-plus"
level: "intro"
order: 20
objectives:
  - "Describe what a shell is and what the parts of the prompt mean"
  - "Break any command into its name, its options, and its arguments"
  - "Explain why some options are one letter and some are whole words"
  - "Recover from a command that appears to have hung"
prerequisites: []
tags: ["linux", "linux-plus", "shell", "beginner"]
updated: 2026-08-07
draft: false
examObjectives:
  - exam: "xk0-006"
    domain: "1.0"
    objective: "1.5"
sources:
  - title: "bash(1)"
    url: "https://man7.org/linux/man-pages/man1/bash.1.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "ls(1)"
    url: "https://man7.org/linux/man-pages/man1/ls.1.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "signal(7)"
    url: "https://man7.org/linux/man-pages/man7/signal.7.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "The Open Group Base Specifications: Utility Argument Syntax"
    url: "https://pubs.opengroup.org/onlinepubs/9699919799/basedefs/V1_chap12.html"
    publisher: "The Open Group"
    accessed: 2026-08-07
    tier: 1
symptoms:
  - symptom: "ls: unrecognized option"
    anchor: "3-a-wrong-option-is-not-a-crash"
  - symptom: "command not found, when the command definitely exists"
    anchor: "1-linux-cares-about-capital-letters"
---

> **Before you read.** Here are two instructions for the same computer:
>
> `ls -l /etc` and `ls --format=long /etc`
>
> One is short and one is spelled out, and they do exactly the same thing. Why
> would anyone build a system with two ways to say one thing? Have a guess. The
> answer is in section 3.

If you have only ever used a computer by clicking things, the terminal looks
hostile. A black window, a blinking cursor, no menus, and no obvious way to find
out what you are allowed to do.

It is worth pushing past that, because the trade is a good one. Clicking is
easier to learn and harder to repeat. Typing is harder to learn and trivial to
repeat: an instruction you type once can be saved, scheduled, sent to a
colleague, or run on four hundred machines at the same time. That is the entire
reason servers are administered this way.

This topic covers the smallest possible amount you need before anything else
makes sense.

### Some words you will need

<dl class="terms">
<dt>terminal</dt>
<dd>The window. It displays text and accepts what you type. On its own it does nothing else.</dd>
<dt>shell</dt>
<dd>The program running inside that window. It reads what you type, works out what you meant, runs it, and shows you the result. The common one is called <code>bash</code>.</dd>
<dt>prompt</dt>
<dd>The text the shell prints when it is ready for you. It usually ends in <code>$</code> or <code>#</code>.</dd>
<dt>command</dt>
<dd>One instruction. Usually the name of a small program that does one job.</dd>
</dl>

People say "the terminal", "the shell", and "the command line" fairly
interchangeably. The distinction only matters occasionally, and this topic will
say which one it means when it does.

## What breaks without this

Nothing dramatic. What happens instead is worse: you follow a tutorial, it works,
and you learn nothing you can reuse. Somebody pastes you a command, you run it,
and you cannot tell what part of it was the important part.

The specific failures this topic prevents:

- You type a command correctly and get **command not found**, because Linux
  cares about capital letters and you did not.
- You copy a command from a website, change one thing, and it stops working,
  because you changed a part you did not realise was structural.
- Something appears to hang forever and you close the window and start again,
  because nobody told you the key that stops it.

## The prompt is telling you four things

When you open a terminal you get something like this:

```
sam@web01:~$
```

Four pieces of information, and it is worth being able to read them:

| Part | Means |
| --- | --- |
| `sam` | Who you are logged in as |
| `web01` | Which machine you are on |
| `~` | Which directory you are currently in. `~` is shorthand for your home directory |
| `$` | The shell is ready for a command |

That third one matters more than it looks. Commands usually act on wherever you
currently are, so "which directory am I in" is a question you will ask
constantly. Topic 03 is entirely about it.

The last character is the one to watch:

- **`$` means you are a normal user.** You can change your own files and not much
  else.
- **`#` means you are root**, the administrator account, and the system will let
  you do anything at all, including destroy itself. If you see `#` when you were
  not expecting it, slow down.

> The prompt above is illustrative. Prompts vary between distributions and can be
> customised freely, so yours may look different. The `$` and `#` convention is
> near-universal.

## Every command has the same three parts

This is the whole idea, and once you can see it you can read any command.

```
ls -l /etc
^  ^  ^
|  |  argument: what to act on
|  option: how to behave
command: what to run
```

**The command** is the name of the program. `ls` lists things. `date` prints the
date. `whoami` prints who you are.

**Options** change how it behaves. They start with a dash.

**Arguments** are what it acts on. Usually a file or a directory.

Some commands need none of it:

```bash
# Debian 13 (trixie), x86_64
$ whoami; date -u
root
Fri Aug  7 23:29:00 UTC 2026
```

Two commands on one line there, separated by a semicolon, which runs them one
after the other. `whoami` took nothing at all. `date` took one option, `-u`,
meaning show UTC rather than local time.

<details class="deeper">
<summary>If you already administer Linux: not every command is a program, and it matters more than it sounds</summary>

"The shell runs the program you name" is true of most commands and false of some
of the most important ones, and the exceptions explain several things that
otherwise look arbitrary.

`type` tells you which is which:

```
$ type ls cd echo systemctl [
ls is aliased to `ls --color=auto'
cd is a shell builtin
echo is a shell builtin
systemctl is /usr/bin/systemctl
[ is a shell builtin
```

**`cd` has to be a builtin, and could not possibly be a program.** The working
directory belongs to a process. If `cd` were an external command, the shell would
fork a child, that child would change *its own* directory, and then exit — leaving
the shell exactly where it was. The same argument applies to `export`, `ulimit`,
`umask`, and anything else that alters the shell's own state.

**Four kinds of thing can answer to a name**, and the shell resolves them in this
order: alias, function, builtin, then `$PATH`. That ordering is the entire
explanation for a class of confusion — an alias shadowing a program, or a function
in someone's `.bashrc` intercepting a command you thought you were running.

Escaping the lookup is worth knowing:

| Form | Skips |
| --- | --- |
| `\ls` or `'ls'` | Aliases |
| `command ls` | Aliases and functions |
| `/usr/bin/ls` | Everything |
| `builtin cd` | Aliases and functions, forcing the builtin |

**Two of these exist as both a builtin and a program**, which catches people:
`/usr/bin/echo` and `/usr/bin/test` are real files, and they behave slightly
differently from the builtins — notably `echo -e`. A script whose output changes
depending on whether it ran under bash or dash is usually meeting this.

The practical use of `type` is in a script that must not be fooled: `type -P` gives
the `$PATH` binary and ignores everything else, which is what you want when
checking whether a tool is genuinely installed.

</details>

## Options come in two spellings

Back to the question at the top. `-l` and `--format=long` are two ways of writing
the same request, run here one after the other on the same file.

<details class="predict">
<summary>If they are genuinely the same option in two spellings, what should the two lines of output look like?</summary>

```bash
# Debian 13 (trixie), x86_64
$ ls -l /etc/hostname; ls --format=long /etc/hostname
-rw-r--r--. 1 root root 13 Aug  7 23:29 /etc/hostname
-rw-r--r--. 1 root root 13 Aug  7 23:29 /etc/hostname
```

</details>

**Identical, character for character.** That is the point: the short and long
spellings are not two similar features, they are one feature with two names, and
which you use is a matter of who is going to read the command afterwards.

Identical, because they are the same option written two ways.

- **Short options are one dash and one letter**: `-l`. Fast to type, hard to
  remember later.
- **Long options are two dashes and a word**: `--format=long`. Slow to type,
  obvious when you read it back in six months.

The reason both exist is that they are for two different moments. Short options
are for typing, when you know what you meant and nobody else is watching. Long
options are for writing down, when the person reading it in six months is you and
you have forgotten everything.

A script full of `-rn` is a riddle. A script full of `--recursive --dry-run`
explains itself to a stranger at three in the morning, which is roughly when
scripts get read.

**Short options can be combined.** These three are the same instruction:

```
ls -l -a -h
ls -la -h
ls -lah
```

That is why commands sometimes look like `tar -xzvf`. It is not one mysterious
incantation handed down through the generations. It is four separate options
stuck together because somebody got tired of pressing the space bar.

<details class="deeper">
<summary>If you already administer Linux: option-argument attachment</summary>

The combining rule has an edge that bites in scripts. An option that takes a
value must be last in a cluster, because everything after it is consumed as the
value. `tar -xzf backup.tar.gz` works and `tar -xfz backup.tar.gz` does not,
because in the second the `z` becomes the filename.

Long options split on this too: `--file=name` and `--file name` are both usually
accepted, but only the `=` form survives being passed through something that
re-splits on whitespace. Prefer `=` in anything generated.

`--` on its own ends option parsing, which is the fix for a filename that starts
with a dash: `rm -- -rf` removes a file literally named `-rf`. You will need this
exactly once, and it will be memorable.

</details>

<details class="deeper">
<summary>If you already administer Linux: where the inconsistency comes from</summary>

The convention is described in the POSIX Utility Argument Syntax, but it is a
convention rather than an enforced rule, and long options are a GNU extension
that POSIX never specified. So you get three families in practice: GNU tools with
both forms, older utilities with short only, and a scattering of tools such as
`find`, `dd`, and `ps` with their own syntax entirely.

`ps` is the one that catches people, because it accepts BSD-style options without
a dash (`ps aux`), UNIX-style with one dash (`ps -ef`), and GNU-style with two,
and they are not interchangeable.

The practical rule: when a command behaves oddly with options, check whether it
predates the convention rather than assuming you typed it wrong.

</details>

## What trips people up

### 1. Linux cares about capital letters

**Everything here is case sensitive**: commands, options, filenames, directory
names. `Reports` and `reports` are as unrelated as `Reports` and `haddock`.
Windows will politely pretend they are the same thing. Linux will not.

Given that rule, work out what this does before you look. `mkdir` creates
directories, and `-p` means "do not complain if it already exists".

<details class="predict">
<summary>How many directories does the first command create, and does the last one work?</summary>

```bash
# Debian 13 (trixie), x86_64
$ mkdir -p /tmp/Reports /tmp/reports; ls -d /tmp/Reports /tmp/reports; LS /etc
/tmp/Reports
/tmp/reports
/bin/sh: 1: LS: not found
```

Two directories, because those are two different names. And `LS` fails, because
the command is `ls` and there is no such thing as `LS`.

</details>

The error is worth reading closely, because you will see it a great deal:

```
LS: not found
```

The shell is not being obtuse. It genuinely looked, and there is nothing called
`LS` anywhere it knows to look. **`command not found` means one of three things**,
in this order of likelihood: a typo, wrong capitalisation, or the program really
is not installed. Check them in that order and you will be right most of the
time.

### 2. Spaces separate the parts, so filenames with spaces cause trouble

The shell splits what you type at every space. `ls my file.txt` is not one
filename, it is two arguments: `my` and `file.txt`.

Put quotes around anything containing a space:

```
ls "my file.txt"
```

This is the single most common beginner frustration, and it is also why
experienced people avoid spaces in filenames on servers entirely.

### 3. A wrong option is not a crash

If you misspell an option, the command refuses and tells you so:

```bash
# Debian 13 (trixie), x86_64
$ ls --lang /etc; echo "exit code: $?"
ls: unrecognized option '--lang'
Try 'ls --help' for more information.
exit code: 2
```

Two things worth noticing. The message tells you exactly where to look next,
which is the subject of topic 02. And `exit code: 2` is the command reporting
that it failed: every command finishes with a number, `0` meaning success and
anything else meaning a problem. That becomes important once you start writing
scripts.

### 4. Nothing happening is usually success

This one genuinely unsettles people coming from graphical software, where every
completed action gets a progress bar, a chime, and occasionally a celebratory
animation. Copy a file in Linux and you get: nothing. A blank line and a fresh
prompt.

That is not the command thinking about it. That is the command having finished,
correctly, and seeing no reason to make a fuss.

The convention is old and deliberate: print output when there is something to
say, stay quiet otherwise. It exists because these tools were built to be chained
together, and a program that announced its own success would be shouting into the
next program's input.

**Silence is good news.** If something had gone wrong, you would have been told,
usually rudely.

<details class="deeper">
<summary>If you already administer Linux: exit codes, and where the real answer lives</summary>

Silence is convention, not contract. The reliable signal is the exit status:
`$?` holds the last command's, `0` for success and anything else for a failure
whose meaning is command-specific. `grep` returns `1` for "no match found", which
is not an error, and scripts under `set -e` die on it constantly.

Worth knowing early: `$?` is overwritten by the very next command, including the
`echo` you were about to use to inspect it. Capture it first if you need it
twice.

The tools that break the silence convention are the ones that predate it or come
from elsewhere: some `rsync` invocations, most Java tooling, and anything that
prints a banner. Redirect their stdout in scripts rather than trying to make them
behave.

</details>

### 5. Getting out of something

Three keys worth committing to memory before you need them:

| Keys | Does |
| --- | --- |
| **Ctrl+C** | Stop whatever is running right now and give the prompt back |
| **q** | Quit a full-screen text viewer, such as `man` or `less` |
| **Ctrl+D** | "No more input." At an empty prompt this logs you out |

**Ctrl+C is the one that matters.** If a command seems stuck, press it. You have
not broken anything. Note that Ctrl+C is not copy here, and Ctrl+V is not paste;
in most terminals those are Ctrl+Shift+C and Ctrl+Shift+V.

## Prove it

Three commands that confirm the shell is doing what you think:

```bash
# Which shell is running
echo "$SHELL"

# Who the shell thinks you are
whoami

# Whether a command exists before you try to use it
command -v ls
```

The last one is the useful habit. If `command -v something` prints a path, the
program is installed. If it prints nothing, it is not, and no amount of retyping
will help.

## Work it through

A colleague sends you this line and asks you to run it on a test machine:

```
tar -czf backup.tar.gz /home/sam/notes
```

You have never used `tar`. Before running anything, work out what it is going to
do, using only what this topic covered.

Reason it out before reading on.

**Break it into the three parts.** The command is `tar`. The options are `-czf`,
which is three short options combined: `c`, `z`, and `f`. The arguments are
`backup.tar.gz` and `/home/sam/notes`.

**Notice something is unusual.** There are two arguments, and the first one looks
like a file that does not exist yet. That is a clue that one of those options
takes a value: `f` almost certainly means "file", and the filename that follows it
is attached to it rather than being a thing to act on.

**So the shape is:** do something with three settings, write the result to
`backup.tar.gz`, using `/home/sam/notes` as the input.

**What you cannot know yet** is what `c` and `z` mean, and that is fine. You have
narrowed an opaque line down to one precise question, which topic 02 answers in
about fifteen seconds.

The habit worth taking from this: you can safely read any command before running
it, and knowing which part you do not understand is most of the work.

## Try it

Optional, and only if you have a Linux machine or virtual machine handy.

1. Open a terminal and read your prompt. Name the user, the machine, the
   directory, and whether you are root.
2. Run `date`, then `date -u`, then `date --utc`. Confirm the last two match.
3. Run `ls -l`, then `ls -a`, then combine them into one command with a single
   dash.
4. Deliberately break something: run `LS`, then `ls --nonsense`. Read both errors
   rather than skipping past them.

**Verification step.** You have it when you can look at `ls -lah /var/log` and
say out loud which part is the command, which parts are options, how many options
there are, and what the argument is.

## Check yourself

Answer each one out loud before you open it. Getting one wrong is not a problem;
getting one wrong and then reading why is the entire point of this section.

<details class="qa">
<summary>What is the difference between the terminal and the shell?</summary>

The terminal is the window: it shows text and accepts keystrokes, and that is
all it does. The shell is the program running inside it that actually reads what
you typed, works out what you meant, and runs it.

The useful consequence is that they are swappable. You can run a different shell
inside the same terminal, or the same shell inside a different terminal, and
neither cares. When somebody says "a bash script", they mean the shell, not the
window.

</details>

<details class="qa">
<summary>Your prompt ends in `#`. What does that tell you, and why should it change how carefully you type?</summary>

You are root, the administrator account. The system will do whatever you tell it
without asking whether you meant it, including deleting the files that make it
bootable.

A normal user's mistakes are usually confined to their own files. Root's
mistakes are not confined to anything. That is why the convention exists at all:
the prompt changes character so that the warning is in front of you rather than
in your memory.

</details>

<details class="qa">
<summary>`ls -lh` and `ls -l -h` do the same thing. Why?</summary>

Because `-lh` is not one option called "lh". It is two separate short options
that have been stuck together, which the shell is happy to unpack.

That is also how to read anything that looks like line noise: `tar -xzvf` is
four options, not one word. Once you see the seam, those commands stop being
intimidating.

</details>

<details class="qa">
<summary>You run a command to copy a file and nothing is printed. Did it work?</summary>

Almost certainly yes. Most Linux commands say nothing when they succeed, on the
principle that there is nothing to report.

If it had failed you would have seen an error, and errors here are not subtle.
If you want certainty rather than a strong assumption, check the result directly:
list the destination and see whether the file is there.

</details>

<details class="qa">
<summary>A command has been running for two minutes with no output and you want it to stop. Which key, and what will it not do?</summary>

**Ctrl+C.** It stops the running command and hands the prompt back.

What it will not do is copy anything. In most terminals copy is Ctrl+Shift+C,
because plain Ctrl+C was claimed for "stop that" decades before anyone thought of
clipboards. Pressing Ctrl+C expecting a copy is a rite of passage, and the worst
outcome is that you cancel something you wanted.

It also will not undo work already done. Stopping a half-finished delete leaves
you with a half-finished delete.

</details>

## References

- [bash(1)](https://man7.org/linux/man-pages/man1/bash.1.html) - Linux man-pages project. Accessed 2026-08-07.
- [ls(1)](https://man7.org/linux/man-pages/man1/ls.1.html) - Linux man-pages project. Accessed 2026-08-07.
- [signal(7)](https://man7.org/linux/man-pages/man7/signal.7.html) - Linux man-pages project. Accessed 2026-08-07.
- [Utility Argument Syntax](https://pubs.opengroup.org/onlinepubs/9699919799/basedefs/V1_chap12.html) - The Open Group. Accessed 2026-08-07.

Command output was captured on the images pinned in `blog/scripts/distros.json`.
Blocks without a distribution and architecture header are illustrative.
