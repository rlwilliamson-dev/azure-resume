---
title: "It works for you and not for the service account"
description: "The same command, the same machine, and two different results depending on who runs it and how. What the environment is, how a command actually gets found, and which startup file runs when."
track: "linux-plus"
level: "working"
order: 220
objectives:
  - "Explain what an environment variable is and why export exists"
  - "Say how the shell finds a command, and predict which one wins"
  - "Choose between .bashrc, .bash_profile, and /etc/profile correctly"
  - "Diagnose a command that works interactively and fails from cron"
prerequisites: ["text-processing"]
tags: ["linux", "linux-plus", "shell", "environment", "path"]
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
  - title: "environ(7)"
    url: "https://man7.org/linux/man-pages/man7/environ.7.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "env(1)"
    url: "https://man7.org/linux/man-pages/man1/env.1.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "execve(2)"
    url: "https://man7.org/linux/man-pages/man2/execve.2.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "locale(7)"
    url: "https://man7.org/linux/man-pages/man7/locale.7.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
symptoms:
  - symptom: "command not found from cron but works when typed"
    anchor: "1-works-when-typed-fails-from-cron"
  - symptom: "Added something to .bashrc and the service still cannot see it"
    anchor: "2-the-wrong-startup-file"
---

> **Before you read.** A backup script works perfectly when you run it. The
> same script, on the same machine, from cron at 2am, fails with `command not
> found`, for a command that is definitely installed and that you have just
> run successfully.
>
> Nothing about the machine changed between the two runs. The file is the same
> file.
>
> **What is different about the second run?**

Something invisible came with the first one and not the second. Every process
carries a set of variables it inherited from whatever started it, and one of
those variables decides where the shell looks for commands.

Your interactive session builds that set from several files over several steps.
A cron job gets almost none of it, which is deliberate and is the correct
behaviour, and is the source of an entire genre of 2am failures.

### Some words you will need

<dl class="terms">
<dt>environment variable</dt>
<dd>A named value a process carries and passes on to anything it starts.</dd>
<dt>shell variable</dt>
<dd>The same thing without the passing on. It exists only in the shell that set it.</dd>
<dt><code>PATH</code></dt>
<dd>A list of directories the shell searches, in order, to find a command you typed.</dd>
<dt>login shell</dt>
<dd>The shell you get when you log in. Reads a different startup file from the others.</dd>
<dt>interactive shell</dt>
<dd>One with a prompt, waiting for you to type. A script is neither interactive nor login.</dd>
</dl>

## What breaks without this

**Scripts fail on a schedule and nowhere else.** The single most common
"it worked yesterday" in this exam's territory.

**A service cannot find what you can.** Services run with their own environment,
which is neither yours nor cron's, and adding something to your shell profile
does not reach them.

**You cannot explain a wrong answer.** Locale settings change how `sort` orders
things and how dates are formatted, silently, and a script producing different
output on two machines is very often this.

## What is in there

`env` prints the whole environment. The ones worth recognising:

| Variable | Holds |
| --- | --- |
| `PATH` | Where to look for commands |
| `HOME` | Your home directory, which is what `~` expands to |
| `USER` | Your login name |
| `SHELL` | Your login shell from `/etc/passwd`, **not** the one you are running |
| `PWD` | The current directory |
| `LANG`, `LC_*` | Language and locale, which change sorting and formatting |
| `EDITOR`, `VISUAL` | What `visudo` and `crontab -e` will launch |
| `TERM` | What kind of terminal this is |

**`SHELL` is a trap worth knowing about.** It reports the shell listed for your
account, not the one you are in. Start `zsh` from `bash` and `SHELL` still says
bash. `ps -p $$` answers the real question.

## Setting, and passing on

```bash
# Debian 13 (trixie), x86_64
$ GREETING=hello; echo "set: $GREETING"; sh -c 'echo "child sees: [$GREETING]"'; export GREETING; sh -c 'echo "after export, child sees: [$GREETING]"'
set: hello
child sees: []
after export, child sees: [hello]
```

**That is the whole of `export` in three lines.** A plain assignment makes a
**shell variable**, which the shell can see and nothing it starts can.
`export` promotes it to an **environment variable**, which every child process
inherits.

Note the direction: **inheritance flows downward only.** A child cannot change
its parent's environment, which is why `cd` has to be a shell builtin, a
program changing its own directory would achieve nothing, and why a script
that sets a variable cannot affect the shell that ran it. `source script.sh`
(or `. script.sh`) runs it in the *current* shell instead, which is how a
script changes your environment and the only way it can.

`unset NAME` removes it. `VAR=value command` sets it for that one command only,
which is the cleanest way to test a theory:

```
LC_ALL=C sort file.txt
DEBUG=1 ./thescript.sh
```

## How a command is found

```bash
# Debian 13 (trixie), x86_64
$ bash -c 'echo "$PATH"; echo "--- what kind of thing is each of these ---"; type ls; type cd; type -a echo'
/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
--- what kind of thing is each of these ---
ls is /usr/bin/ls
cd is a shell builtin
echo is a shell builtin
echo is /usr/bin/echo
echo is /bin/echo
```

**`PATH` is a colon-separated list, searched left to right, first match wins.**
Type `ls` and the shell tries `/usr/local/sbin/ls`, then `/usr/local/bin/ls`, then
`/usr/sbin/ls`, then finds `/usr/bin/ls` and stops.

**`cd` is a shell builtin**, so it is never searched for at all, which is why
`which cd` finds nothing and people conclude it does not exist.

**`echo` is both**, and the builtin wins because builtins are checked before
`PATH`. That is why `echo`'s behaviour differs slightly between shells while
`/bin/echo` stays constant.

| Command | Answers |
| --- | --- |
| `type name` | What kind of thing it is: builtin, alias, function, or file |
| `type -a name` | **Every** match, in the order they would be tried |
| `command -v name` | The path only. Portable, and the one for scripts. |
| `which name` | Same idea, an external program, does not know about builtins |

**Prefer `type` interactively and `command -v` in scripts.** `which` is a
separate binary that only searches `PATH`, so it misses builtins, functions,
and aliases, and it is not installed everywhere.

### First match wins, and why that matters

<details class="predict">
<summary>A script called `hostname` is placed in `/usr/local/bin`, where the real one is `/usr/bin/hostname`. Given the PATH above, which runs?</summary>

```bash
# Debian 13 (trixie), x86_64
$ mkdir -p /usr/local/bin; printf '#!/bin/sh\necho "the one in /usr/local/bin"\n' > /usr/local/bin/hostname; chmod +x /usr/local/bin/hostname; echo '--- which one wins? ---'; command -v hostname; hostname; echo '--- and every match, in order ---'; bash -c 'type -a hostname'
--- which one wins? ---
/usr/local/bin/hostname
the one in /usr/local/bin
--- and every match, in order ---
hostname is /usr/local/bin/hostname
hostname is /usr/bin/hostname
hostname is /bin/hostname
```

**The one in `/usr/local/bin`**, because it comes earlier in `PATH`. The real
`hostname` is still installed and still there, `type -a` lists all three, and
it will not run while the first one exists.

This is the intended design: `/usr/local/bin` precedes `/usr/bin` precisely so
that something you installed yourself overrides the distribution's version. It is
what lets you test a newer build without removing the packaged one.

It is also a **privilege escalation route**, and worth understanding as one. If a
directory earlier in root's `PATH` is writable by an unprivileged user, that user
can place a file there named after a command root runs, and it executes as root.
The same applies to any script that runs privileged and calls commands by bare
name.

Two defences, both worth knowing: **never put `.` (the current directory) in
`PATH`**, which would mean running `ls` in a directory somebody else can write to
executes their `ls`; and **use full paths in privileged scripts**, or set `PATH`
explicitly at the top of them.

`type -a` is the diagnostic. When a command behaves unexpectedly, it tells you
whether you are running the one you think you are.

</details>

<details class="deeper">
<summary>If you already administer Linux: hashing, aliases, functions, and the resolution order</summary>

The full order bash uses for a bare word, first match winning:

1. **Aliases**, interactive shells only, and not expanded in scripts, which is
   why an alias in `.bashrc` does nothing for a cron job.
2. **Functions**, shell functions defined in the current shell.
3. **Builtins**: `cd`, `echo`, `type`, `export`.
4. **`PATH`**, left to right.

`command name` skips aliases and functions and goes straight to builtins and
`PATH`; `\name` with a backslash skips the alias; `builtin name` forces the
builtin. All three exist so a function can wrap a command and still call the real
one, which is otherwise an infinite loop.

**Bash caches lookups in a hash table**, so it does not search `PATH` on every
invocation. Install a newer version of something earlier in `PATH` and bash
keeps running the old one it remembers. `hash -r` clears it; `hash` lists it.
The symptom, a command still running the old binary after you replaced it,
looks like a packaging problem and is not.

`type -a` reveals all four layers, which is why it beats `which` for
diagnosis. A `git` that behaves oddly might be an alias, a function, a shim in
`/usr/local/bin`, or the real one.

Functions can be exported with `export -f`, which is occasionally useful and
was the mechanism behind Shellshock, worth knowing exists, and worth being
sparing with.

</details>

## Which file runs when

This is the part that catches everyone, and it is testable:

```bash
# Debian 13 (trixie), x86_64
$ printf 'echo "bashrc ran"\n' > /root/.bashrc; printf 'echo "profile ran"\n' > /root/.bash_profile; echo '--- a login shell ---'; bash -lc 'echo done'; echo '--- an interactive non-login shell ---'; bash -ic 'echo done' 2>/dev/null; echo '--- a plain script, neither ---'; bash -c 'echo done'
--- a login shell ---
profile ran
done
--- an interactive non-login shell ---
bashrc ran
done
--- a plain script, neither ---
done
```

**Three kinds of shell, three different answers.** Read that output carefully,
because it explains most of this lesson's failures.

| Shell is | Reads | You get one when |
| --- | --- | --- |
| **Login** | `/etc/profile`, then `~/.bash_profile` | SSH in, log in at a console, `su -`, `bash -l` |
| **Interactive, not login** | `/etc/bash.bashrc`, then `~/.bashrc` | Open a terminal in a desktop, run `bash` |
| **Neither** | **nothing** | A script, a cron job, a systemd service |

The third row is the important one. A script reads no startup file at all. Not
`.bashrc`, not `.bash_profile`, not `/etc/profile`. Anything you put in those
files is invisible to it.

Why most people's `.bash_profile` sources `.bashrc`: because otherwise an SSH
session would get the profile and miss everything in `.bashrc`. The
conventional line is:

```bash
[ -f ~/.bashrc ] && . ~/.bashrc
```

which is why editing `.bashrc` usually appears to work for both cases. The
profile is quietly forwarding to it. On a machine where that line is missing,
the same edit works in a desktop terminal and not over SSH, which is a
genuinely confusing few minutes.

| File | Applies to | Put here |
| --- | --- | --- |
| `/etc/profile`, `/etc/profile.d/*.sh` | every user, login shells | system-wide settings |
| `/etc/bash.bashrc` | every user, interactive | system-wide aliases |
| `~/.bash_profile` | you, login shells | `PATH` changes, and sourcing `.bashrc` |
| `~/.bashrc` | you, interactive shells | aliases, prompt, functions |
| `~/.bash_logout` | you, on exit | cleanup |

**`/etc/profile.d/*.sh` is where system-wide settings belong**, not in
`/etc/profile` itself, a drop-in file survives a package upgrade and an edit
to the main file may not.

## The 2am failure

<details class="predict">
<summary>`useradd` runs fine when you type it. From cron, the same command reports `command not found`. Given what you now know about `PATH`, what is happening?</summary>

```bash
# Debian 13 (trixie), x86_64
$ echo '--- your interactive PATH finds it ---'; command -v useradd; echo '--- with the PATH cron gives you, it does not ---'; env -i PATH=/usr/bin:/bin /bin/sh -c 'command -v useradd || echo "useradd: not found"'; echo '--- the full path always works ---'; env -i PATH=/usr/bin:/bin /bin/sh -c '/usr/sbin/useradd --help 2>&1 | head -1'
--- your interactive PATH finds it ---
/usr/sbin/useradd
--- with the PATH cron gives you, it does not ---
useradd: not found
--- the full path always works ---
Usage: useradd [options] LOGIN
```

**`useradd` lives in `/usr/sbin`, and cron's `PATH` does not include it.**

Your interactive `PATH` has six directories including `/usr/sbin` and `/sbin`,
because a login shell built it from `/etc/profile` and your own files. Cron
supplies a minimal one, typically `/usr/bin:/bin`, and reads none of those
files, because a cron job is not a login shell and not an interactive one.

The command is installed. You have permission to run it. The shell simply never
looks in the directory it is in.

Note the last line: **the full path works regardless**, because no searching is
involved. That is both the diagnosis and one of the fixes.

Three fixes, in order of preference. **Use full paths in scheduled jobs**,
`/usr/sbin/useradd`, which is unambiguous and immune to any `PATH`. **Set
`PATH` at the top of the crontab**, which cron supports as a line of its own
and which applies to every job in the file. Or **source the profile in the
job**, which is the least predictable of the three because it depends on what
is in those files today.

The general rule worth carrying: **anything that runs unattended should not
depend on an environment a human built.** That covers cron, systemd services, CI
runners, and container entrypoints, all of which fail this way.

</details>

<details class="deeper">
<summary>If you already administer Linux: systemd services, and where their environment comes from</summary>

A systemd service gets even less than cron: no shell startup files, and a `PATH`
compiled into systemd itself, typically
`/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin`. It does **not**
inherit anything from the shell that ran `systemctl start`.

Four ways to give a unit what it needs, roughly in order of how much you should
like them:

**`Environment=` in the unit** for one or two values:
`Environment=NODE_ENV=production`. Visible in `systemctl show`, so nothing
secret.

**`EnvironmentFile=/etc/sysconfig/theservice`** for a set of them, and the
conventional place for per-machine settings. Note the file is parsed by
systemd rather than by a shell, so there is no expansion, no substitution, and
quoting rules that are close to shell but not identical: `VAR=$OTHER` is a
literal dollar sign.

**`LoadCredential=` and `systemd-creds`** for actual secrets, which keeps them out
of the unit file and out of `systemctl show`.

**A drop-in**, `systemctl edit theservice`, rather than editing the shipped
unit under `/usr/lib/systemd/system/`, which a package upgrade overwrites. The
drop-in lands in `/etc/systemd/system/theservice.service.d/override.conf` and
survives.

`systemctl show -p Environment theservice` prints what a unit will actually
get, and `systemd-run -p Environment=... --pty command` runs something
interactively under the same conditions, which is the fastest way to reproduce
a service-only failure without restarting anything.

`DefaultEnvironment=` in `/etc/systemd/system.conf` sets it for everything, and
is almost always the wrong tool.

</details>

## Locale, and why two machines disagree

`LANG` and the `LC_*` variables decide language, and also sorting, number
formatting, and date formatting. That second group causes real problems:

- **`sort` orders differently** under different collations. In many locales it
  ignores case and punctuation; under `LC_ALL=C` it is plain byte order. Two
  machines with different locales produce different sorted output from the same
  input.
- **Decimal separators change.** Some locales use a comma, which breaks anything
  parsing numbers.
- **`date` formats change**, so a log parser written against one machine's output
  fails on another.

**`LC_ALL=C` in scripts whose output is compared or parsed.** It is not a
workaround; it is the correct setting for machine-readable output, and the reason
build systems set it.

`locale` prints the current settings and `locale -a` lists what is available. A
machine reporting `LC_ALL=` empty and `LANG=C.UTF-8` is the common server
default, and it is a sensible one.

<details class="deeper">
<summary>If you already administer Linux: reading another process's environment, and secrets</summary>

**`cat /proc/<pid>/environ | tr '\0' '\n'`** prints the environment a running
process was started with. It is the definitive answer to "what does this service
actually have", as opposed to what its unit file says, and it settles arguments
about whether a restart picked up a change.

The permission is worth knowing: you can read it for your own processes, and
root can read it for any. Which is the security consequence, **an environment
variable is not a secret from root, and on a machine where anyone can become
root it is not a secret at all.**

Worse, the environment is inherited by every child process, so a credential
passed this way spreads to everything the service spawns, and appears in core
dumps and in some crash reporters.

`ps eww <pid>` shows the same thing, and on some systems is readable more
widely than `/proc/<pid>/environ`, historically this is how passwords passed
on command lines and in environments leaked to other users.

**The alternatives, in order:** a file readable only by the service account, with
the path in the environment rather than the value; `systemd-creds` and
`LoadCredential=`, which decrypts to a tmpfs the unit can read and nothing else
can; or a secrets manager the application queries at startup.

`env -i` starts a process with an empty environment, and is the tool for
reproducing a minimal-environment failure exactly. `env -i PATH=/usr/bin:/bin
./script.sh` tests whether a script will survive cron without waiting until 2am.

</details>

## Across distributions

| | RHEL family | Debian family |
| --- | --- | --- |
| System-wide interactive | `/etc/bashrc` | `/etc/bash.bashrc` |
| System-wide login | `/etc/profile`, `/etc/profile.d/` | same |
| Service environment files | `/etc/sysconfig/` | `/etc/default/` |
| Default user `PATH` includes sbin | Yes, for root; for users on recent releases | No, for regular users |
| `/bin/sh` | a symlink to `bash` | `dash` |

**Two of those cause real trouble.** The system-wide bashrc filename differs by
one character and a script that appends to the wrong one silently does nothing.
And the `/etc/sysconfig` versus `/etc/default` split means a unit file's
`EnvironmentFile=` path is not portable between the families.

## Prove it

When something works for you and not for something else:

```bash
# What do I have
echo "$PATH"
env | sort | head -20

# What is this command, really
type -a thecommand

# What would it look like with almost nothing
env -i PATH=/usr/bin:/bin /bin/sh -c 'command -v thecommand'

# What does the service actually have
sudo cat /proc/$(pgrep -f theservice | head -1)/environ | tr '\0' '\n'
systemctl show -p Environment theservice
```

**The `env -i` line is the one to reach for first.** It reproduces the
minimal-environment case in a second, rather than scheduling a cron job and
waiting.

## What trips people up

### 1. Works when typed, fails from cron

`PATH`. Cron gives a minimal one and reads no startup files.

Full paths in scheduled jobs, or a `PATH=` line at the top of the crontab. And
test with `env -i PATH=/usr/bin:/bin ./script.sh` rather than waiting for 2am.

### 2. The wrong startup file

`.bashrc` for interactive shells, `.bash_profile` for login shells, **neither**
for scripts and services.

If an SSH session does not pick up your aliases, check that `.bash_profile`
sources `.bashrc`. If a service does not see a variable, neither file will
ever help. It needs `Environment=` or `EnvironmentFile=`.

### 3. Setting a variable without exporting it

A plain assignment is a shell variable. Child processes see nothing.

`export VAR=value`, or `VAR=value command` for a single command. `env | grep VAR`
confirms it is exported; `echo $VAR` does not, because that works for both kinds.

### 4. A script that cannot change your shell

Running `./setenv.sh` starts a child, which sets its own variables and exits,
taking them with it.

`source setenv.sh` or `. setenv.sh` runs it in the current shell. This is why
tools that modify your environment tell you to source their script rather than
run it, and why `cd` inside a script does not move you.

### 5. Assuming `~` and `$HOME` are set

Cron and some services run with a minimal environment where `HOME` may be
missing or different, so `~/.config/thing` resolves somewhere unexpected or fails
outright.

Use absolute paths in anything unattended.

## Work it through

A nightly report script runs from cron. It produces a file, but the rows are in a
different order from when you run it by hand, and a downstream tool that expects
sorted input rejects it intermittently.

```
#!/bin/bash
psql -At -c "select name from customers" | sort > /reports/names.txt
```

Reason it out before reading on.

**It is not `PATH` this time.** The script runs, `psql` is found, and a file is
produced. `command not found` is the obvious environment failure and this is a
different one.

`sort` is the suspect, and locale is why. Sorting is locale-dependent: under
most `en_US.UTF-8` collations, case and punctuation are largely ignored, so
`apple`, `Banana`, `cherry` sorts in that order. Under `LC_ALL=C` it is byte
order, so all the capitals come before all the lowercase and it is `Banana`,
`apple`, `cherry`.

Your interactive session has a locale; cron's environment may not. You get
`LANG=en_US.UTF-8` from `/etc/profile` and your own files. The cron job reads
neither, so it falls back to the C locale, and produces a different, equally
correct, ordering.

Confirm it in one command, without waiting for the next scheduled run:

```
env -i /bin/bash -c 'printf "apple\nBanana\ncherry\n" | sort'
LANG=en_US.UTF-8 /bin/bash -c 'printf "apple\nBanana\ncherry\n" | sort'
```

Two different orderings from the same input proves the mechanism.

**The fix is to stop depending on the ambient locale**, in the script itself:

```bash
#!/bin/bash
set -euo pipefail
export LC_ALL=C
psql -At -c "select name from customers" | sort > /reports/names.txt
```

Not "set the locale to match my session", **pin it**, so the output is the
same regardless of who runs it, on which machine, with which login files.

Now the point worth extracting, because it generalises past locale: **the
environment is an input to your program, and an input nobody wrote down.** The
script has no bug in it. It behaves differently because it was handed different
inputs by two different launchers, and neither launcher is wrong.

The habit: **anything that runs unattended should declare what it needs rather
than inherit it.** Set `PATH`, set `LC_ALL`, use absolute paths, and pass
configuration explicitly. Then the 2am run and the run you just did are actually
the same run, which is the only way "it works on my machine" stops being a
sentence anyone has to say.

## Try it

Optional, on any machine.

1. `env | sort | less`. Find `PATH`, `HOME`, and `LANG`.
2. `MYVAR=test`, then `bash -c 'echo "[$MYVAR]"'`. Then `export MYVAR` and repeat.
3. `type -a ls`, `type -a cd`, `type -a echo`. Explain each answer.
4. `echo $PATH | tr ':' '\n'` to see the search order one directory per line.
5. `env -i PATH=/usr/bin:/bin /bin/sh -c 'command -v useradd'` and see it fail.
6. `printf "apple\nBanana\ncherry\n" | sort`, then the same with `LC_ALL=C` in
   front. Two orderings.
7. `bash -lc 'echo login'` versus `bash -c 'echo script'` with an `echo` in your
   `.bashrc`, and see which one runs it.

**Verification step.** You have it when you can take a script that fails from
cron and reproduce the failure interactively in one command, without editing the
script or waiting for a schedule.

## Check yourself

<details class="qa">
<summary>What does `export` actually do, and how would you check whether a variable is exported?</summary>

**It marks a variable to be passed to child processes.** A plain assignment
creates a shell variable that only the current shell can see; `export` promotes
it to an environment variable, which every process the shell starts inherits.

To check: **`env | grep VAR`**, or `export -p | grep VAR`. Those list only
exported variables.

`echo $VAR` does **not** answer the question, because it prints both kinds
identically, which is exactly why this is confusing in the first place.

Inheritance is one-way: a child can never modify its parent's environment. That
is why a script cannot change your shell unless you `source` it.

</details>

<details class="qa">
<summary>Which startup file does a shell script read, and what follows from that?</summary>

**None.** A script is neither a login shell nor an interactive one, so it reads
`/etc/profile`, `~/.bash_profile`, and `~/.bashrc` not at all.

What follows is most of this lesson's failures. Aliases defined in `.bashrc` do
not exist in a script. `PATH` additions made in `.bash_profile` are absent.
Functions, prompt settings, and locale exports are all missing.

The same is true of cron jobs and systemd services, with the addition that both
supply a minimal `PATH` of their own.

The consequence for practice: **a script must declare what it needs.** Set
`PATH`, set `LC_ALL`, use absolute paths, and do not rely on anything a human's
login built.

</details>

<details class="qa">
<summary>A script works when you run it and fails from cron with "command not found". Give the diagnosis and three fixes.</summary>

**The command is not in cron's `PATH`.** Your interactive `PATH` was built by
`/etc/profile` and your own startup files and typically includes `/usr/sbin` and
`/sbin`. Cron reads none of those and supplies a minimal `PATH`, usually
`/usr/bin:/bin`. Administrative commands live in the sbin directories, so they
are not found.

**Fix one, best:** use absolute paths in scheduled jobs: `/usr/sbin/useradd`.
No searching happens, so no `PATH` can be wrong.

**Fix two:** put a `PATH=` line at the top of the crontab. Cron supports it and
it applies to every job in that file.

**Fix three, weakest:** source the profile at the start of the job. It works and
it depends on what is in those files today, which is not a property you control.

Reproduce it in one command rather than waiting: `env -i PATH=/usr/bin:/bin
/bin/sh -c 'yourcommand'`.

</details>

<details class="qa">
<summary>`type -a git` lists four entries. Why does that matter more than what `which git` says?</summary>

**Because `which` only searches `PATH`.** It is an external program and knows
nothing about aliases, shell functions, or builtins, all three of which are
checked *before* `PATH`.

So `which git` can confidently report `/usr/bin/git` while the thing that
actually runs is an alias in `.bashrc` or a function that wraps it.

`type -a` shows every candidate in resolution order: aliases first, then
functions, then builtins, then each `PATH` match. The first line is what will
run.

That makes it the right tool when a command behaves unexpectedly. It is also
how you spot a shim earlier in `PATH` shadowing the real binary, which is a
legitimate technique and a privilege escalation route depending on who can
write to that directory.

</details>

<details class="qa">
<summary>Why does `LC_ALL=C` belong in a script whose output is parsed or compared?</summary>

**Because sorting, number formatting, and date formatting are all
locale-dependent**, and the locale comes from the environment the script happened
to inherit.

`sort` under a typical UTF-8 collation largely ignores case and punctuation;
under `C` it is plain byte order. The same input produces two different,
equally correct orderings, so the same script gives different results run by
hand and run from cron, or on two machines with different defaults.

`LC_ALL=C` pins it. Output becomes a function of the input alone rather than of
the environment, which is what makes it comparable, diffable, and reproducible.

The wider principle: an unattended script should **declare** what it needs rather
than inherit it. The environment is an input nobody wrote down, and pinning it is
how you stop it being one.

</details>

## References

- [bash(1)](https://man7.org/linux/man-pages/man1/bash.1.html) - Linux man-pages project. Accessed 2026-08-07.
- [environ(7)](https://man7.org/linux/man-pages/man7/environ.7.html) - Linux man-pages project. Accessed 2026-08-07.
- [env(1)](https://man7.org/linux/man-pages/man1/env.1.html) - Linux man-pages project. Accessed 2026-08-07.
- [execve(2)](https://man7.org/linux/man-pages/man2/execve.2.html) - Linux man-pages project. Accessed 2026-08-07.
- [locale(7)](https://man7.org/linux/man-pages/man7/locale.7.html) - Linux man-pages project. Accessed 2026-08-07.

Every block above with a distribution and architecture header was captured by running the command on a Debian 13 (trixie) container. Blocks without one are illustrative.
