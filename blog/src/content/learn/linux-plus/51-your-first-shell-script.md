---
title: "Your first shell script"
description: "A script is a file containing the commands you already know. The shebang, the execute bit, arguments, and the two habits that separate a script that works from one that works on somebody else's machine."
deck: "You have typed the same three commands every morning for a month"
track: "linux-plus"
level: "intro"
order: 520
objectives:
  - "Write, save, and run a script from nothing"
  - "Explain what the shebang line does and predict what happens without one"
  - "Take arguments and act on them, including when none were given"
  - "Quote a variable correctly and say what breaks when you do not"
  - "Return a meaningful exit status and check one"
prerequisites: ["the-shell-environment", "reading-and-setting-permissions"]
tags: ["linux", "linux-plus", "scripting", "bash", "automation"]
updated: 2026-08-08
draft: false
examObjectives:
  - exam: "xk0-006"
    domain: "4.0"
    objective: "4.2"
sources:
  - title: "bash(1)"
    url: "https://man7.org/linux/man-pages/man1/bash.1.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-08
    tier: 1
  - title: "execve(2)"
    url: "https://man7.org/linux/man-pages/man2/execve.2.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-08
    tier: 1
  - title: "chmod(1)"
    url: "https://man7.org/linux/man-pages/man1/chmod.1.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-08
    tier: 1
  - title: "exit(3)"
    url: "https://man7.org/linux/man-pages/man3/exit.3.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-08
    tier: 1
  - title: "dash(1)"
    url: "https://manpages.debian.org/trixie/dash/dash.1.en.html"
    publisher: "Debian manpages"
    accessed: 2026-08-08
    tier: 1
  - title: "Shell Command Language"
    url: "https://pubs.opengroup.org/onlinepubs/9799919799/utilities/V3_chap02.html"
    publisher: "The Open Group"
    accessed: 2026-08-08
    tier: 1
symptoms:
  - symptom: "bash: ./script.sh: Permission denied"
    anchor: "1-permission-denied-on-a-script-you-just-wrote"
  - symptom: "Syntax error: \"(\" unexpected"
    anchor: "the-shebang-decides-which-language-you-are-writing"
  - symptom: "Script works with one filename and breaks on another"
    anchor: "quoting-is-not-punctuation"
---

> **Before you read.** Every morning you check the same three things: whether the
> backup ran, how full the disk is, and whether the service came back up. Three
> commands, typed the same way, for a month.
>
> The commands are correct. You already know them. Nothing about this needs
> learning.
>
> **So what is actually different about putting those three lines in a file?**

Almost nothing, and that is the point worth starting from. A shell script is a
file containing commands you would have typed anyway, run in order. There is
no new language to learn before you can write a useful one, you already know
the language, because it is the shell.

What this lesson is really about is the small number of things that are different:
how the system knows the file is meant to be run, how the file gets told what to
work on, and two habits that decide whether it still works next month on somebody
else's machine.

### Some words you will need

<dl class="terms">
<dt>script</dt>
<dd>A text file of commands, run top to bottom by an interpreter.</dd>
<dt>shebang</dt>
<dd>The <code>#!</code> on the first line, naming which interpreter runs the file.</dd>
<dt>interpreter</dt>
<dd>The program that reads the script and does what it says. Usually <code>bash</code>.</dd>
<dt>argument</dt>
<dd>Something given to the script on the command line. Available as <code>$1</code>, <code>$2</code>, and so on.</dd>
<dt>exit status</dt>
<dd>A number from 0 to 255 the script leaves behind. Zero means success.</dd>
<dt>word splitting</dt>
<dd>The shell breaking an unquoted value apart at spaces. The cause of most script bugs.</dd>
</dl>

## What breaks without this

**The knowledge stays in your head.** A procedure only you can perform is a
procedure that does not happen while you are on holiday, and one nobody can review
for correctness.

**It works differently every time.** Three commands typed by hand are three
opportunities to mistype, skip one, or run them in the wrong order at 3am.

**You cannot schedule it.** Everything in the scheduling lesson (cron, timers,
CI) needs something to run, and that something is a file.

**And the one that catches people later:** a script that works on your machine and
fails on the server, for reasons that have nothing to do with what it does.

## The smallest script that does anything

A file, three lines, no ceremony:

```bash
#!/bin/bash
name="$1"
echo "Good morning, $name"
echo "It is $(date +%A)"
```

`$(date +%A)` is command substitution: run `date +%A`, and put its output here.
The rest is a variable and two `echo`s.

Save it as `greet.sh` and run it.

<details class="predict">
<summary>The file exists, the contents are correct, and the shebang names an interpreter that is installed. What happens, and what does the exit status tell you?</summary>

```bash
# Debian 13 (trixie), x86_64
$ cat greet.sh; echo "--- try to run it ---"; ./greet.sh Ryan; echo "rc=$?"
#!/bin/bash
name="$1"
echo "Good morning, $name"
echo "It is $(date +%A)"
--- try to run it ---
/bin/sh: 1: ./greet.sh: Permission denied
rc=126
```

</details>

**`Permission denied`, and this is everybody's first script error.** Creating
a file does not make it runnable. A new file is `rw-r--r--` (readable and
writable by you, readable by everyone, executable by nobody) and running it
requires the execute bit from lesson 07.

**`rc=126` is worth recognising.** It is not a generic failure: 126 means "found
it, could not execute it", which is a permissions or format problem. Compare it to
127, which means "did not find it at all". Those two numbers distinguish a typo in
the filename from a missing execute bit without any further investigation.

One `chmod` fixes it:

```bash
# Debian 13 (trixie), x86_64
$ ls -l greet.sh; chmod +x greet.sh; ls -l greet.sh; echo "--- now ---"; ./greet.sh Ryan; echo "rc=$?"
-rw-r--r--. 1 root root 74 Aug  8 22:15 greet.sh
-rwxr-xr-x. 1 root root 74 Aug  8 22:15 greet.sh
--- now ---
Good morning, Ryan
It is Saturday
rc=0
```

**`chmod +x` without a target sets it for everyone**, subject to your umask, which
is what you want for a script in `/usr/local/bin`. `chmod u+x` sets it for you
only, which is right for something in your home directory.

**And `./greet.sh` needs the `./`.** The shell searches `$PATH` for bare
command names, and `.` is not on `$PATH`, deliberately, since a directory
containing a file called `ls` could otherwise hijack the real one. Naming the
path explicitly says "this file, here".

## The shebang decides which language you are writing

The first two characters of the file are `#!`, and the kernel reads them before
anything else happens. They name the program that will interpret the rest.

This matters more than it looks, because `/bin/sh` and `/bin/bash` are not the
same program on most systems. On Debian and Ubuntu, `/bin/sh` is **dash**, a
smaller, faster, strictly POSIX shell with no arrays, no `[[ ]]`, and no `for
((;;))`.

<details class="predict">
<summary>The script below uses bash array syntax, and every line of it is valid bash. Its shebang says <code>#!/bin/sh</code>. On Debian, what happens?</summary>

```bash
# Debian 13 (trixie), x86_64
$ cat wrongshebang.sh; echo "--- run it ---"; ./wrongshebang.sh; echo "rc=$?"
#!/bin/sh
names=(alpha beta)
echo "${names[0]}"
--- run it ---
./wrongshebang.sh: 2: Syntax error: "(" unexpected
rc=2
```

</details>

**`Syntax error: "(" unexpected`**, from a script whose syntax is perfectly
correct, for a different shell. The shebang did not describe the file; it
*chose the interpreter*, and dash does not have arrays.

This is the single most common portability failure in shell scripting, and it has
a memorable shape: **the script works when you run `bash script.sh` and fails when
you run `./script.sh`**, because only the second form consults the shebang.

| Shebang | Means |
| --- | --- |
| `#!/bin/bash` | Bash specifically. Arrays, `[[ ]]`, `$'...'` all available. |
| `#!/bin/sh` | Whatever the system's POSIX shell is. **Dash on Debian.** |
| `#!/usr/bin/env bash` | The first `bash` on `$PATH`. Portable to macOS and BSD. |
| `#!/usr/bin/python3` | Not a shell at all. The mechanism is general. |

**Use `#!/bin/bash` when you use bash features, and mean it.** Writing `#!/bin/sh`
because it looks more portable, and then using bash syntax, gives you the worst of
both: it appears to work on Red Hat, where `/bin/sh` *is* bash, and breaks on
Debian.

**A file with no shebang at all still runs**, which confuses the picture. The
shell that invoked it runs it as a child of itself, so it works from an
interactive bash prompt and behaves unpredictably when something else (`cron`,
a systemd unit, a CI runner) executes it with a different shell. Always write
one.

<details class="deeper">
<summary>If you already administer Linux: what the kernel actually does with that line, and the limits nobody documents</summary>

The shebang is not a shell feature. It is handled in `execve(2)`, in the kernel,
which is why it works for Python and Perl and anything else.

**The mechanism, exactly:** the kernel reads the first two bytes of the file. If
they are `#!`, it reads the rest of that line, splits it into an interpreter path
and **at most one argument**, and then executes the interpreter with the script's
path appended. So `./greet.sh Ryan` becomes `/bin/bash ./greet.sh Ryan`.

Three consequences that are invisible until they bite:

**Only one argument is passed.** `#!/usr/bin/env python3 -u` works on Linux and
fails on some other systems, because `env` receives `python3 -u` as a single string
and looks for a program with a space in its name. `#!/usr/bin/env -S python3 -u`
is the GNU fix, and `-S` is not universal.

The interpreter path is not searched. It must be absolute. There is no `$PATH`
lookup, which is precisely why `#!/usr/bin/env bash` exists: `env` *is* at a
fixed path and does the searching for you. That matters on macOS, where the
system bash is version 3.2 from 2007 and anything modern lives in
`/opt/homebrew/bin`.

There is a length limit, historically 127 bytes and still 255 on Linux
(`BINPRM_BUF_SIZE`). A long interpreter path inside a deeply nested virtualenv
can exceed it, and the failure is a bare `Permission denied` or `No such file
or directory` naming a file that plainly exists, one of the more baffling
errors available.

And the classic one: `bad interpreter: No such file or directory` on a file
that is definitely there. The missing file is the *interpreter*, not the
script, and the usual cause is a carriage return. A file edited on Windows has
`\r` at the end of every line, so the kernel looks for `/bin/bash\r`, which
does not exist. `file script.sh` reports "CRLF line terminators" and
`dos2unix` or `sed -i 's/\r$//'` fixes it.

</details>

## Taking arguments

A script that only ever does one thing is a note to yourself. A script that takes
an argument is a tool.

<figure class="learn-figure">
<svg viewBox="0 0 720 200" role="img" aria-labelledby="ar-t ar-d" style="width:100%;height:auto;">
<title id="ar-t">A command line split into the variables the script receives</title>
<desc id="ar-d">Running a script with arguments fills a fixed set of variables. Dollar zero holds the name the script was invoked as, which is the path you typed rather than the file's real location. Dollar one, dollar two and dollar three hold the arguments in order. Dollar hash holds the count, three here, and it does not include dollar zero. Dollar at expands to all of the arguments together, which is what you pass on when a script wraps another command.</desc>
<g>
<text x="30" y="52" font-size="13" fill="var(--accent)">./args.sh</text>
<text x="140" y="52" font-size="13" fill="currentColor">alpha</text>
<text x="230" y="52" font-size="13" fill="currentColor">beta</text>
<text x="310" y="52" font-size="13" fill="currentColor">gamma</text>
<text x="30" y="96" font-size="11" fill="var(--accent)">$0</text>
<text x="140" y="96" font-size="11" fill="currentColor" fill-opacity="0.8">$1</text>
<text x="230" y="96" font-size="11" fill="currentColor" fill-opacity="0.8">$2</text>
<text x="310" y="96" font-size="11" fill="currentColor" fill-opacity="0.8">$3</text>
<text x="140" y="134" font-size="10" fill="currentColor" fill-opacity="0.75">$@ is all three of these</text>
<text x="140" y="154" font-size="10" fill="currentColor" fill-opacity="0.75">$# is 3, and never counts $0</text>
<text x="30" y="134" font-size="10" fill="var(--accent)">the name you typed</text>
<text x="440" y="96" font-size="10" fill="currentColor" fill-opacity="0.65">a script with no arguments is a note</text>
<text x="440" y="112" font-size="10" fill="currentColor" fill-opacity="0.65">to yourself, one with them is a tool</text>
</g>
<g stroke="currentColor" stroke-opacity="0.45" fill="none" stroke-width="1.2">
<path d="M140 62 L140 76"/>
<path d="M230 62 L230 76"/>
<path d="M310 62 L310 76"/>
<path d="M136 112 L136 118 L400 118 L400 112"/>
</g>
<g stroke="var(--accent)" stroke-opacity="0.9" fill="none" stroke-width="1.6">
<path d="M30 62 L30 76"/>
</g>
</svg>
<figcaption><code>$0</code> is the accented one because it is the odd member of the set: it holds the name the script was invoked as, so it changes depending on how you called it and it is deliberately left out of <code>$#</code>. That is why a script checking <code>$#</code> against zero is asking whether it got any arguments, not whether it knows its own name.</figcaption>
</figure>

The positional parameters arrive as numbered variables, plus three that describe
the set:

```bash
# Debian 13 (trixie), x86_64
$ cat args.sh; echo "--- run it with three arguments ---"; ./args.sh alpha beta gamma
#!/bin/bash
echo "script name: $0"
echo "first arg:   $1"
echo "how many:    $#"
echo "all of them: $@"
--- run it with three arguments ---
script name: ./args.sh
first arg:   alpha
how many:    3
all of them: alpha beta gamma
```

| Variable | Is |
| --- | --- |
| `$0` | How the script was invoked. **Not counted in `$#`.** |
| `$1`, `$2`, ... | The arguments, in order |
| `$#` | How many there were |
| `$@` | All of them. **Always write it as `"$@"`.** |
| `$*` | All of them joined into one string. Rarely what you want. |

**`$0` is not an argument**, which is why `$#` is 3 and not 4. It holds
whatever path was used to run the script, so a script can behave differently
depending on the name it was called by. That is how `gzip`, `gunzip`, and
`zcat` are one binary.

**`"$@"` versus `"$*"` is a real distinction and worth learning once.** Quoted,
`"$@"` expands to each argument as a separate word, preserving spaces inside them.
`"$*"` joins everything into a single word. Passing arguments along to another
command is always `"$@"`.

<details class="deeper">
<summary>If you already administer Linux: how a script finds the file next to it, and why <code>$0</code> is not the answer</summary>

The moment a script needs a config file, a template, or a helper script beside
it, this comes up, and the obvious approaches all fail in ways that only show
up later.

**A relative path is wrong immediately.** `source ./config.sh` resolves against the
*caller's* working directory, not the script's. It works while you are testing from
the script's own directory and fails the first time cron runs it, because cron
starts in the user's home.

`$0` is closer and still not enough. It holds whatever path was used to invoke
the script, so `dirname "$0"` gives the directory only when the invocation was
a path. When the script is found on `$PATH`, `$0` is a bare name and `dirname`
gives `.`. And if the script is a symlink in `/usr/local/bin` pointing into
`/opt/myapp`, `$0` names the symlink and its neighbours are not what you
wanted.

The idiom that handles all of it:

```bash
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
source "$script_dir/config.sh"
```

Three parts, each doing real work. `${BASH_SOURCE[0]}` rather than `$0`,
because it is correct when the file has been `source`d rather than executed,
where `$0` is the *calling* shell's name. `cd` followed by `pwd` resolves it
to an absolute path regardless of how it was reached. And `--` before the
argument stops a path beginning with a hyphen being read as an option.

**For symlinks, add `readlink -f`**, or `realpath`, to follow to the real
file:

```bash
script_dir=$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")
```

Whether you *want* that is a genuine decision. A tool deliberately installed as a
symlink usually wants the real directory. A script whose behaviour depends on the
name it was invoked under wants `$0` unresolved.

**The alternative worth considering is not doing this at all.** A script that
takes its configuration from an environment variable with a sensible default,
`CONFIG="${MYAPP_CONFIG:-/etc/myapp.conf}"`, is easier to test, easier to
package, and follows the convention every other program on the system uses.
Locating files relative to the script is right for a self-contained tool in
`/opt` and wrong for anything that looks like a system service.

</details>

## Handling the case where there is no argument

The most common bug in a first script is assuming it was given what it needs. The
fix is three lines at the top:

```bash
#!/bin/bash
src="$1"
dest="/var/backups"
if [ -z "$src" ]; then
    echo "usage: backup.sh SOURCE" >&2
    exit 2
fi
echo "would copy $src to $dest"
```

`[ -z "$src" ]` is true when the variable is empty. `>&2` sends the message to
standard error, from lesson 19, so it does not pollute output somebody is piping.
And `exit 2` sets the status deliberately.

<details class="predict">
<summary>The script is run twice: once with no argument and once with <code>/etc</code>. Predict both outputs and both exit statuses.</summary>

```bash
# Debian 13 (trixie), x86_64
$ ./backup.sh; echo "rc=$?"; echo "--- and with an argument ---"; ./backup.sh /etc; echo "rc=$?"
usage: backup.sh SOURCE
rc=2
--- and with an argument ---
would back up /etc
rc=0
```

</details>

**Zero for success and non-zero for failure**, which is the convention everything
else relies on. `&&`, `||`, `if`, `set -e`, cron's failure mail, a systemd unit's
`Restart=on-failure`, and every CI system read that number.

**The conventional values are worth using:**

| Status | Means |
| --- | --- |
| `0` | Success |
| `1` | General failure |
| `2` | **Misuse.** Wrong arguments, bad usage. |
| `126` | Found but not executable |
| `127` | Command not found |
| `130` | Terminated by Ctrl+C |

A script that always exits 0 is a script nothing can react to, and it is the reason
a broken nightly job can run silently for months.

## Quoting is not punctuation

This is the habit that separates a script that works from one that works on
everyone's data. The rule is short: **put double quotes around every variable
expansion**, unless you have a specific reason not to.

Here is why, on the most ordinary input imaginable, a filename with a space in
it.

<details class="predict">
<summary><code>printf '[%s]\n'</code> prints each argument it receives on its own line in brackets. The variable holds <code>my report.txt</code>. How many lines does the unquoted version print?</summary>

```bash
# Debian 13 (trixie), x86_64
$ cat quoting.sh; echo "--- run it on a filename with a space ---"; ./quoting.sh "my report.txt"
#!/bin/bash
file="$1"
echo "without quotes, the shell splits it:"
printf '  [%s]\n' $file
echo "with quotes, it stays one thing:"
printf '  [%s]\n' "$file"
--- run it on a filename with a space ---
without quotes, the shell splits it:
  [my]
  [report.txt]
with quotes, it stays one thing:
  [my report.txt]
```

</details>

**Two arguments instead of one.** The shell performed word splitting on the
unquoted value, and `printf` was handed `my` and `report.txt` as separate things.

Now imagine that value went to `rm` instead of `printf`. `rm $file` deletes two
files, neither of them the one you meant, and neither of them exists so you get two
errors and no clue. The same expansion inside `cp`, `mv`, or a `for` loop produces
the same class of damage.

**The variable holds the right value the whole time.** Nothing is corrupted; the
shell is doing exactly what it is documented to do with an unquoted expansion. The
quotes are how you say "this is one thing".

**When not to quote** is a much shorter list: when you actively want splitting,
which is rare and should carry a comment.

<details class="deeper">
<summary>If you already administer Linux: the three lines to put at the top of every script, and what each one actually prevents</summary>

There is a conventional preamble, and it is worth understanding rather than
copying, because one of the three has real caveats.

```bash
#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
```

**`set -e` stops on the first failing command.** Without it, a script carries
on regardless, which means a `cd` that failed is followed by an `rm -rf *`
running somewhere unintended. Watch the difference:

```bash
# Debian 13 (trixie), x86_64
$ bash -c "echo start; nosuchcommand; echo carried on anyway"; echo "rc=$?"; echo "--- with set -e ---"; bash -c "set -e; echo start; nosuchcommand; echo never printed"; echo "rc=$?"
start
bash: line 1: nosuchcommand: command not found
carried on anyway
rc=0
```

Without `-e` the script printed `carried on anyway` **and exited 0**, reporting
success for a run in which a command did not exist.

**`set -u` errors on an unset variable** instead of expanding it to nothing. That
converts `rm -rf "$PREFIX/"` with a typo'd `PREFIX` from a catastrophe into an
error message, and it is the cheapest safety line available.

`set -o pipefail` makes a pipeline report the first failure, not just the last
command's status. `grep x file | sort` otherwise reports success even when
`grep` failed, because `sort` succeeded.

The honest caveats on `set -e`, because it is not the guarantee people think:

- It does **not** trigger for a command in an `if` condition, a `&&` chain, or
  anything followed by `||`. That is by design, and it means a failure inside
  `if backup; then` is handled rather than fatal.
- It does not trigger inside a function called in a condition, which surprises
  people writing helper functions.
- Command substitution in an assignment masks it: `x=$(false)` does not exit,
  because the assignment succeeded.

So `set -e` is a good default and not a substitute for checking things you care
about. `cmd || { echo "cmd failed" >&2; exit 1; }` is still worth writing at the
steps that matter.

**`IFS=$'\n\t'` removes the space from the field separator**, so unquoted
expansions split on newlines and tabs only. It reduces the blast radius of a
missed quote and is genuinely useful when iterating over `find` output. It also
changes behaviour that other people's code may rely on, so it belongs in scripts
you own rather than in a shared library.

**And the tool that finds all of this for you is `shellcheck`.** It catches unquoted
expansions, `set -e` misconceptions, and a long list of subtler issues, and running
it is a better use of ten seconds than any amount of reading about quoting.

</details>

## Asking the person running it

`read` takes a line from standard input into a variable. It is how a script asks a
question:

```bash
# Debian 13 (trixie), x86_64
$ cat ask.sh; echo "--- feed it two answers ---"; printf "/srv/data\ny\n" | ./ask.sh
#!/bin/bash
read -r -p "Which directory? " target
read -r -p "Are you sure? [y/N] " reply
if [ "$reply" = "y" ]; then
    echo "would back up $target"
else
    echo "cancelled"
fi
--- feed it two answers ---
would back up /srv/data
```

**The prompts do not appear in the output**, because `read -p` writes them to
standard error rather than standard output, which is correct, and means piping
a script's output does not capture its questions.

`-r` should be on every `read` you ever write. Without it, backslashes in the
input are treated as escapes, so a user pasting a Windows path gets it
mangled. There is no case where the default is what you want.

The bigger point is about when to ask at all. A script that asks questions
cannot be scheduled, cannot run in CI, and cannot be used non-interactively.
Prefer arguments, and use `read` only for genuinely interactive tools, or gate
it:

```
if [ -t 0 ]; then
    read -r -p "Are you sure? [y/N] " reply
else
    reply=y
fi
```

`[ -t 0 ]` is true when standard input is a terminal, so the script asks a person
and assumes yes when piped.

## Across distributions

Scripting is one of the most portable things in this track. What differs is what
`/bin/sh` points at, and where scripts belong.

| | RHEL family | Debian family |
| --- | --- | --- |
| `/bin/sh` is | **bash**, in POSIX mode | **dash** |
| Bash syntax under `#!/bin/sh` | Usually works | **Fails** |
| Bash version | 5.x | 5.x |
| Your scripts belong in | `/usr/local/bin` | `/usr/local/bin` |
| `shellcheck` package | `ShellCheck`, via EPEL | `shellcheck` |

**That second row is the whole reason to be careful.** A script written and tested
on RHEL with `#!/bin/sh` and bash syntax appears correct, and fails the first time
it runs on Ubuntu. Testing with `dash script.sh` catches it before deployment.

## Prove it

```
# Does it parse at all, without running anything
bash -n script.sh

# What is it actually doing, line by line
bash -x script.sh /some/arg

# What will somebody else's shell make of it
dash script.sh

# What does a linter think
shellcheck script.sh

# And the one that matters
./script.sh; echo "exit status $?"
```

**`bash -n` is the pre-flight check** and costs nothing, it parses without
executing, so a syntax error in a rarely-taken branch is found before that
branch is taken at 3am.

**`bash -x` prints each line as it runs**, with variables expanded, which answers
"what did it actually do" faster than adding `echo` statements. `set -x` inside the
script turns it on partway through, and `set +x` turns it off.

## What trips people up

### 1. `Permission denied` on a script you just wrote

Creating a file does not make it executable. `chmod +x script.sh`.

`rc=126` specifically means "found it, could not run it", which distinguishes this
from `127`, "not found at all".

### 2. `./` is required and looks like a typo

`script.sh` searches `$PATH`, which does not include the current directory.
`./script.sh` names the file where it is. Put scripts in `/usr/local/bin` and the
`./` stops being necessary.

### 3. Bash syntax under `#!/bin/sh`

Works on RHEL, fails on Debian, because `/bin/sh` is dash there. `Syntax error:
"(" unexpected` on a line that is valid bash is this every time.

Write `#!/bin/bash` when you use bash features.

### 4. `bad interpreter: No such file or directory`

The missing file is the interpreter, not the script. Nearly always a carriage
return from a Windows editor: the kernel is looking for `/bin/bash\r`.

`file script.sh` says "CRLF line terminators". `dos2unix` fixes it.

### 5. Unquoted variables

`rm $file` on `my report.txt` deletes two things, neither of them right.
`rm "$file"` does what you meant.

The value was never wrong; the shell split it because you did not say it was one
thing.

### 6. Exiting 0 no matter what

Nothing downstream can react. Cron will not mail you, systemd will not restart it,
CI will pass. Use `exit 1` for failure and `exit 2` for misuse.

## Work it through

You are asked to turn the three morning checks into a script. The first version
looks like this, and somebody else will run it:

```
#!/bin/sh
cd $1
tar -czf backup.tar.gz *
echo done
```

Reason it out before reading on. There are four problems and they are not equally
serious.

**`cd $1` is two problems in one line.** It is unquoted, so a directory with a
space in it becomes two arguments and `cd` fails. And **the failure is not
checked**, the script carries on to the next line, where `tar -czf
backup.tar.gz *` now runs in whatever directory the script started in. That is
the serious one: it does not fail, it succeeds against the wrong data.

```
cd "$1" || exit 1
```

**No argument check.** With no argument, `cd ""` fails, and with `set -e` absent
the same wrong-directory problem follows. Three lines at the top fix it.

`#!/bin/sh` with no bash features is actually fine here, but it is a decision
nobody made. If the next person adds an array, it breaks on Debian and works
in their testing on RHEL.

And `echo done` with no exit status means the caller cannot tell a successful
backup from a failed one. `tar` sets a status; the script discards it by
ending with an `echo` that always succeeds.

The repaired version:

```
#!/bin/bash
set -euo pipefail

src="${1:-}"
if [ -z "$src" ]; then
    echo "usage: $0 SOURCE" >&2
    exit 2
fi

cd "$src" || exit 1
tar -czf /var/backups/backup.tar.gz .
```

**Note what disappeared.** There is no `echo done`, because the exit status
says it, and with `set -e`, reaching the end at all means everything
succeeded. A script that prints "done" whether or not it worked is worse than
one that prints nothing.

The point worth extracting: **the dangerous failures in a script are the ones
where something succeeds at the wrong thing.** A command that errors is
visible. A `cd` that quietly failed, followed by a command that quietly worked
in the wrong directory, produces a backup file full of the wrong data and a
successful exit status, and nobody looks at it until they need to restore.

## Try it

Optional, and everything here is safe.

1. Write `greet.sh` with the three lines from the top of this lesson. Run it
   before `chmod +x` and note the exit status.
2. `chmod +x` it and run it again with your name.
3. Delete the shebang and run it. Then run `dash ./greet.sh` and compare.
4. Add `echo "you gave me $# arguments"` and run it with none, then with three.
5. Make a file called `my report.txt`. Write a script that takes a filename and
   runs `ls -l $1` unquoted. Run it against that file and read the error.
6. Add the quotes. Run it again.
7. Put `set -euo pipefail` at the top of any script and introduce a typo in a
   command name. Compare the exit status with and without it.
8. Run `bash -x` on any of them and watch the expansion.

**Verification step.** You have it when you can explain, without running anything,
why `./script.sh` and `bash script.sh` can behave differently on the same file.

## Check yourself

<details class="qa">
<summary>A script exists, its contents are correct, and running it gives <code>Permission denied</code> with exit status 126. What is wrong, and how does 126 differ from 127?</summary>

**The execute bit is not set.** `chmod +x script.sh` fixes it.

Creating a file gives it `rw-r--r--` by default, subject to your umask. Reading and
writing are allowed; executing is not, and the shell reports that as a permission
problem.

**126 and 127 are different diagnoses:**

- **126** means the file was **found and could not be executed**, no execute
  bit, or it is a directory, or the format is unrecognisable.
- **127** means **command not found**. The path is wrong, or the name is
  misspelled, or it is not on `$PATH`.

So the number tells you whether to check permissions or check the path, before you
have investigated anything.

The tempting wrong answer is that the script's *contents* need permission to
run the commands inside them. They do not. This is about the file itself, and
the commands inside run with your ordinary privileges once it starts.

One related case worth knowing: 126 also appears when the interpreter named in the
shebang exists but is not executable, which is rare, and when you try to execute a
directory, which is not.

</details>

<details class="qa">
<summary>A script runs correctly with <code>bash script.sh</code> and fails with <code>./script.sh</code>. What single line explains the difference?</summary>

**The shebang.**

`bash script.sh` ignores the shebang entirely. You have named the interpreter
yourself, and bash simply reads the file. `./script.sh` executes the *file*,
which means the kernel reads the first line and runs whatever interpreter it
names.

So the two forms can use different interpreters for the same file. The common case
is a shebang of `#!/bin/sh` in a script using bash syntax: it works under
`bash script.sh`, and under `./script.sh` on Debian it runs in dash and fails with
something like `Syntax error: "(" unexpected`.

**The other version of the same answer** is a script with no shebang at all.
It still runs, because the invoking shell handles it, which means it works
from your interactive bash prompt and behaves differently when cron, a systemd
unit, or a CI runner executes it.

The fix is to write the shebang you actually mean, and to test with the interpreter
it names.

If the failure is `bad interpreter: No such file or directory` rather than a syntax
error, the missing file is the interpreter, and the cause is nearly always a
carriage return from a Windows editor making the kernel look for `/bin/bash\r`.

</details>

<details class="qa">
<summary>Why is <code>rm $file</code> dangerous when <code>rm "$file"</code> is not, given the variable holds the correct value in both cases?</summary>

**Because the shell splits an unquoted expansion into words at whitespace before
the command ever sees it.**

The variable is correct throughout. With `file="my report.txt"`, the unquoted
form hands `rm` two arguments, `my` and `report.txt`, and `rm` does exactly
what it was asked. Neither file exists, so you get two errors and the file you
meant is untouched. On a system where those names *do* exist, you have deleted
two wrong files.

The quotes are how you tell the shell that the value is one word. They are not
decoration and they are not about strings.

**The general rule: quote every variable expansion**, and treat an unquoted one as
requiring a comment explaining why. The exceptions are rare enough that they are
worth flagging.

**Where this bites hardest is loops.** `for f in $(ls)` splits filenames at spaces
and is broken for the same reason; `for f in *` uses the shell's own globbing and
is not. That is the topic of the next-but-one lesson.

`shellcheck` finds every unquoted expansion in a script in about a second, which is
a better use of your attention than remembering.

</details>

<details class="qa">
<summary>What does <code>set -e</code> do, and name two situations where it does not do what people expect.</summary>

**It exits the script as soon as any command returns a non-zero status**, instead
of carrying on to the next line. Without it, a failed `cd` is followed by commands
running in the wrong directory, which is how scripts do damage.

Two places it deliberately does not fire:

Anything in a condition. A command in `if`, in a `&&` or `||` chain, or in a
`while` test is being *checked*, so its failure is meaningful rather than
fatal. `if grep -q x file; then` does not exit when grep finds nothing, which
is correct, and surprises people who expect `-e` to be absolute.

Assignments from command substitution. `x=$(false)` does not exit, because the
*assignment* succeeded even though the command inside it did not. `local
x=$(false)` inside a function has the same problem, more subtly, because
`local` itself returns 0.

So `set -e` is a good default and not a guarantee. Anywhere the failure genuinely
matters, check it explicitly:

```
cmd || { echo "cmd failed" >&2; exit 1; }
```

The companions are `set -u`, which turns a typo'd variable name into an error
instead of an empty string, and `set -o pipefail`, which stops a pipeline reporting
success because its last command succeeded.

</details>

<details class="qa">
<summary>Your script ends with <code>echo "backup complete"</code> and always exits 0. Why is that worse than printing nothing at all?</summary>

**Because it tells every automated caller that the run succeeded, whatever
happened.**

The exit status is the only thing cron, systemd, and CI look at. `echo` succeeds, so
a script ending with one exits 0 even if `tar` failed on the line above. The
consequences:

- **Cron sends no mail**, because it only mails on non-zero status or output.
- **`Restart=on-failure` in a systemd unit never fires.**
- **A CI pipeline goes green.**
- **`&&` chains continue** to the next step, which now runs against a broken
  artefact.

And the message actively misleads a human reading the log, because "backup
complete" appears after a backup that did not complete.

**The fix is to let the status flow through**, which usually means removing
the `echo` rather than adding anything. With `set -e`, reaching the end of the
script already means everything succeeded, the exit status says so, and it
says so in the one language automation reads.

Where you do want a deliberate status, use the conventions: `1` for a general
failure, `2` for being called wrongly, and `exit "$?"` or nothing at all to pass
through the last command's result.

</details>

## References

- [bash(1)](https://man7.org/linux/man-pages/man1/bash.1.html) - Linux man-pages project. Accessed 2026-08-08.
- [execve(2)](https://man7.org/linux/man-pages/man2/execve.2.html) - Linux man-pages project. Accessed 2026-08-08.
- [chmod(1)](https://man7.org/linux/man-pages/man1/chmod.1.html) - Linux man-pages project. Accessed 2026-08-08.
- [exit(3)](https://man7.org/linux/man-pages/man3/exit.3.html) - Linux man-pages project. Accessed 2026-08-08.
- [dash(1)](https://manpages.debian.org/trixie/dash/dash.1.en.html) - Debian manpages. Accessed 2026-08-08.
- [Shell Command Language](https://pubs.opengroup.org/onlinepubs/9799919799/utilities/V3_chap02.html) - The Open Group. Accessed 2026-08-08.

Every block above with a distribution and architecture header was captured by running the command on a Debian 13 (trixie) container. Blocks without one are illustrative.
