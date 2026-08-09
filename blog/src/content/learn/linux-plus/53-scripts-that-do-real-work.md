---
title: "The script works until it meets a filename with a space in it"
description: "Functions, parameter expansion, argument parsing, and traps. The pieces that turn a working script into one you can hand to somebody else, and the four ways ordinary filenames break the naive version."
track: "linux-plus"
level: "working"
order: 540
objectives:
  - "Write functions with local variables and a meaningful return status"
  - "Use parameter expansion instead of calling out to other programs"
  - "Iterate over filenames safely, including ones with spaces and newlines"
  - "Parse options with getopts rather than by hand"
  - "Clean up reliably with a trap, including when the script fails"
prerequisites: ["script-control-flow"]
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
  - title: "find(1)"
    url: "https://man7.org/linux/man-pages/man1/find.1.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-08
    tier: 1
  - title: "xargs(1)"
    url: "https://man7.org/linux/man-pages/man1/xargs.1.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-08
    tier: 1
  - title: "mktemp(1)"
    url: "https://man7.org/linux/man-pages/man1/mktemp.1.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-08
    tier: 1
  - title: "signal(7)"
    url: "https://man7.org/linux/man-pages/man7/signal.7.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-08
    tier: 1
  - title: "Shell Command Language"
    url: "https://pubs.opengroup.org/onlinepubs/9799919799/utilities/V3_chap02.html"
    publisher: "The Open Group"
    accessed: 2026-08-08
    tier: 1
symptoms:
  - symptom: "Script processes part of a filename as if it were two files"
    anchor: "the-filename-problem"
  - symptom: "Temporary directory left behind after a script fails"
    anchor: "cleaning-up-whatever-happens"
  - symptom: "Argument list too long"
    anchor: "3-argument-list-too-long"
---

> **Before you read.** A script that archives log files has run every night for a
> year. Somebody adds a directory called `Q3 reports`, and the next morning the
> archive contains two entries: `Q3` and `reports`. Neither exists.
>
> Nothing changed in the script. The filename is legal, spaces have always
> been allowed in Unix filenames, and so have newlines, quotes, and leading
> hyphens.
>
> **The script was always broken. What made it look correct for a year was the
> data.**

That is the shape of nearly every bug in this lesson. The script is not wrong in a
way you can see by reading it; it is wrong in a way that only appears when the
input stops being convenient.

This lesson is the set of tools that make a script robust rather than merely
working: functions to give it structure, parameter expansion so it stops shelling
out for string operations, safe iteration, real argument parsing, and cleanup that
happens even when things go wrong.

### Some words you will need

<dl class="terms">
<dt>function</dt>
<dd>A named block of commands, callable like any other command, with its own arguments.</dd>
<dt>local</dt>
<dd>A variable that exists only inside the function that declared it.</dd>
<dt>parameter expansion</dt>
<dd>The <code>${...}</code> forms that manipulate a variable's value without calling another program.</dd>
<dt>IFS</dt>
<dd>Internal field separator. What the shell splits unquoted values on.</dd>
<dt>trap</dt>
<dd>A command to run when the script receives a signal or exits.</dd>
<dt>idempotent</dt>
<dd>Safe to run twice. Running it again does not change the result.</dd>
</dl>

## What breaks without this

**The script works on your data and fails on real data.** Spaces, newlines, and
leading hyphens in filenames are all legal, and every one of them breaks the naive
loop.

**Temporary files accumulate.** A script that cleans up on its last line does not
clean up when it fails on the line before, so `/tmp` fills with directories from
runs that went wrong.

**Nobody else can change it.** A four-hundred-line script with no functions and no
argument parsing is one people work around rather than modify.

**And it half-runs.** Interrupted at the wrong moment, it leaves a lock file, a
partial archive, or a service stopped, and the next run refuses to start.

## The filename problem

Here is the bug from the opening, exactly.

The directory contains three files, two of which have a space in the name. The
script loops over `$(ls reports)`, which is a common and entirely broken idiom.

<details class="predict">
<summary>There are three files. The loop body prints one line per iteration, with the filename in brackets. How many lines appear?</summary>

```bash
# Debian 13 (trixie), x86_64
$ ls reports; echo "--- the script ---"; cat tidy.sh; echo "--- run it ---"; ./tidy.sh
q1 sales.txt
q2 sales.txt
simple.txt
--- the script ---
#!/bin/bash
for f in $(ls reports); do
    echo "processing [$f]"
done
--- run it ---
processing [q1]
processing [sales.txt]
processing [q2]
processing [sales.txt]
processing [simple.txt]
```

</details>

**Five iterations for three files.** The command substitution produced a string,
the shell split it on whitespace, and each fragment became a separate item. Note
that `sales.txt` appears twice and neither occurrence refers to a file that exists.

**`ls` is not the problem**, it printed the three names correctly, one per
line, as the first three lines show. The problem is that command substitution
discards that structure. The shell receives one flat string and has no way to
know that the space in `q1 sales.txt` is part of a name while the newline
after it is a separator; it splits on both, because both are whitespace.

The fix is to let the shell produce the list itself, using a glob:

```bash
# Debian 13 (trixie), x86_64
$ cat tidy-fixed.sh; echo "--- run it ---"; ./tidy-fixed.sh
#!/bin/bash
for f in reports/*; do
    echo "processing [$f]"
done
--- run it ---
processing [reports/q1 sales.txt]
processing [reports/q2 sales.txt]
processing [reports/simple.txt]
```

**Three iterations, correct names.** A glob expands to a *list of words* rather
than a string, so no splitting is needed and none happens. This is the single most
important habit in shell scripting: **`for f in *` is correct and
`for f in $(ls)` is not**, and the difference is invisible until it is expensive.

**For anything more selective than a glob, `find -print0` is the answer:**

```bash
# Debian 13 (trixie), x86_64
$ cat walk.sh; echo "--- run it ---"; ./walk.sh
#!/bin/bash
find reports -type f -print0 |
while IFS= read -r -d '' f; do
    echo "processing [$f]"
done
--- run it ---
processing [reports/q1 sales.txt]
processing [reports/q2 sales.txt]
processing [reports/simple.txt]
```

**`-print0` separates names with a null byte** instead of a newline, and `read
-d ''` reads up to a null. That combination is the only one that is correct
for *every* legal filename, because null is the one byte a filename cannot
contain. A newline can, and a script that splits on newlines is still broken,
just more rarely.

<details class="deeper">
<summary>If you already administer Linux: the four ways a filename breaks a script, and what each one costs</summary>

Spaces are the famous one and the least dangerous. The others are worth knowing
because the failures are stranger.

**A space** splits one name into several. Usually loud (the resulting paths do
not exist, so commands fail) and the archive-with-two-missing-entries case at
the top of this lesson.

**A newline** does the same thing to any script that reads line by line, which is
most of them. `find | while read` is broken for a file called `report\nDROP.txt`,
and this is genuinely used by attackers to hide files from monitoring scripts.
`-print0` is the only complete fix.

**A leading hyphen** turns the filename into an option. A file called `-rf` in a
directory means `rm *` expands to `rm -rf ...` and behaves very differently from
what was intended. The guards are `--` to end option parsing, and `./` to force a
path:

```
rm -- *
rm ./*
```

`--` is supported by essentially every GNU tool and is worth putting in scripts
that take filenames from anywhere you do not control.

**A glob character** (`*`, `?`, `[`) in a filename is harmless until an
unquoted expansion re-expands it. `f="*"; echo $f` prints every file in the
directory, because the value was globbed *after* substitution. Quoting
prevents it, and this is a second, independent reason for the quoting rule
beyond word splitting.

**The general defence, in order:**

1. Quote every expansion. `"$f"`, always.
2. Use globs rather than command output to produce file lists.
3. Use `-print0` and `read -d ''` when a glob is not selective enough.
4. Use `--` before filename arguments.
5. Run `shellcheck`, which catches all four classes.

**And the reason this matters beyond correctness:** these are the same mechanisms
behind shell injection. A script that builds a command string from a filename and
runs it through `eval` is exploitable by anyone who can create a file. Treating
filenames as opaque data rather than as text you can concatenate is a security
habit as much as a robustness one.

</details>

## Functions

A function is a named block of commands. It gets its own `$1`, `$2`, and `$@`, and
it returns an exit status like anything else.

```bash
# Debian 13 (trixie), x86_64
$ cat report.sh
#!/bin/bash
set -euo pipefail

log() {
    printf '%s [%s] %s\n' "$(date +%H:%M:%S)" "$1" "$2"
}

usage_for() {
    local path="$1"
    local pct
    pct=$(df --output=pcent "$path" | tail -1 | tr -dc '0-9')
    echo "$pct"
}

main() {
    local target="${1:-/}"
    log INFO "checking $target"
    local used
    used=$(usage_for "$target")
    if [ "$used" -ge 90 ]; then
        log WARN "$target is ${used}% full"
        return 1
    fi
    log INFO "$target is ${used}% full, fine"
}

main "$@"
```

Several things there are deliberate and worth naming.

**`local` on every variable inside a function.** Without it, variables are global,
so a function that uses `i` as a counter silently destroys the caller's `i`. That
is the most common function bug in shell and it produces symptoms far from the
cause.

**Declared and assigned on separate lines** in `usage_for`:

```
local pct
pct=$(df ... )
```

That looks fussy and prevents a real problem. `local pct=$(command)` masks the
command's exit status, because `local` itself succeeds, so a failure inside
the substitution is invisible, including to `set -e`. Splitting the two lines
lets the status through.

**A function returns a status, it does not return a value.** `return 1` sets the
exit status; to hand back data you `echo` it and the caller captures with `$( )`,
which is what `usage_for` does. `return` only accepts 0 to 255, so returning a
percentage that way would work by accident and break at 256.

**`main "$@"` at the bottom** is a convention worth adopting. It means every
statement in the file is a definition until the last line, so the script can be
sourced for testing without doing anything, and the reading order matches the
calling order.

```bash
# Debian 13 (trixie), x86_64
$ ./report.sh /; echo "rc=$?"
22:20:32 [INFO] checking /
22:20:32 [INFO] / is 7% full, fine
rc=0
```

## Parameter expansion

Every one of these is a string operation the shell does itself, with no process
started. They replace a surprising amount of `sed`, `cut`, `basename`, and
`dirname`.

<details class="predict">
<summary>`file` holds `report.2026.tar.gz`. `${file%.gz}` strips the shortest match from the end; `${file%%.*}` strips the longest. What does each produce?</summary>

```bash
# Debian 13 (trixie), x86_64
$ cat expand.sh; echo "--- run it ---"; ./expand.sh
#!/bin/bash
name="${1:-world}"
file="report.2026.tar.gz"
path="/var/log/nginx/access.log"

echo "default if unset:  ${name}"
echo "length:            ${#file}"
echo "strip last ext:    ${file%.gz}"
echo "strip all ext:     ${file%%.*}"
echo "basename:          ${path##*/}"
echo "dirname:           ${path%/*}"
echo "replace all:       ${file//./-}"
--- run it ---
default if unset:  world
length:            18
strip last ext:    report.2026.tar
strip all ext:     report
basename:          access.log
dirname:           /var/log/nginx
replace all:       report-2026-tar-gz
```

</details>

**The pattern is consistent once you see it:** `%` works from the end, `#` from the
beginning, and doubling the character makes the match greedy.

| Form | Does |
| --- | --- |
| `${v:-default}` | Use `default` if `v` is unset or empty |
| `${v:=default}` | The same, **and assign it** |
| `${v:?message}` | Error out with `message` if unset. Good for required inputs. |
| `${#v}` | Length |
| `${v%pattern}` | Remove shortest match from the **end** |
| `${v%%pattern}` | Remove longest match from the end |
| `${v#pattern}` | Remove shortest match from the **start** |
| `${v##pattern}` | Remove longest match from the start |
| `${v/old/new}` | Replace first occurrence |
| `${v//old/new}` | Replace **all** occurrences |
| `${v^^}` / `${v,,}` | Upper case / lower case. Bash only. |

**`${path##*/}` is `basename` and `${path%/*}` is `dirname`**, without forking.
That matters in a loop over ten thousand files, where two processes per iteration
is twenty thousand processes.

**`${v:?message}` deserves more use than it gets.** It is a one-line required-
argument check:

```
target="${1:?usage: backup.sh SOURCE}"
```

If `$1` is missing the script exits with that message and a non-zero status, which
is three lines of `if` compressed into one.

<details class="deeper">
<summary>If you already administer Linux: making a script's output useful to something other than a person</summary>

A script that prints friendly progress messages is pleasant interactively and a
problem everywhere else. Three decisions make it work for both audiences.

**Send diagnostics to stderr and results to stdout.** That split is what lets
somebody pipe your script without capturing its chatter:

```
log() { printf '%s [%s] %s\n' "$(date -Is)" "$1" "$2" >&2; }
```

Note the `>&2` inside the function, so every call is on stderr and the caller's
`$(myscript)` gets only the actual output. A script whose log lines land in a
variable somebody is parsing is a script nobody will script against.

**Decide once whether the output is for a person or a program.** `[ -t 1 ]` is true
when stdout is a terminal, which is how tools choose to colourise or not:

```
if [ -t 1 ]; then
    red=$'\033[31m'; reset=$'\033[0m'
else
    red=''; reset=''
fi
```

Without that check, colour escape codes end up in log files and in `grep` output,
which is why so many tools have a `--no-color` flag people have to remember.

**Use `date -Is` or `date -u +%FT%TZ` for timestamps, not a local format.**
ISO 8601 sorts correctly as text, is unambiguous about which number is the
month, and is what every log aggregator expects. `date +%H:%M:%S`, which the
example earlier in this lesson uses for readability, loses the date entirely
and is fine for a terminal and wrong for a file.

**And the level prefix is worth being consistent about**, because it is what turns
grep into filtering. `INFO`, `WARN`, `ERROR` as the second field means
`grep ' \[ERROR\] '` works, and a structured format means it keeps working when the
message text changes.

**The larger version of this idea is `logger`**, which writes to the system journal
instead of a file:

```
logger -t myjob -p user.warning "disk at 91% on /var"
```

That gets you timestamps, the hostname, the PID, rotation, and remote
forwarding for free, and it means a cron job's output ends up somewhere a
person will actually look, which is the real failure of scripts that print
carefully and are run by something that discards stdout.

</details>

## Parsing options properly

Hand-rolled argument parsing works until somebody combines flags or puts them in a
different order. `getopts` handles the standard conventions:

```
while getopts ":vo:" opt; do
    case "$opt" in
        v) verbose=1 ;;
        o) output="$OPTARG" ;;
        \?) echo "unknown option: -$OPTARG" >&2; exit 2 ;;
        :)  echo "-$OPTARG needs a value" >&2; exit 2 ;;
    esac
done
shift $((OPTIND - 1))
```

**The option string `":vo:"` is dense and every character matters.** A **leading
colon** turns on silent error handling, which is what lets you write your own
messages in the `\?` and `:` cases. A colon **after a letter** means that option
takes a value, which arrives in `$OPTARG`.

**`shift $((OPTIND - 1))` is not optional.** `getopts` sets `OPTIND` to the index
of the first non-option argument, and the shift discards everything it consumed so
that `$1` becomes the first real argument. Forgetting it means `"$@"` still
contains the flags.

<details class="predict">
<summary>Three invocations: valid flags with two files, then `-o` with no value, then an unknown `-z`. Predict all three outputs and the exit statuses of the last two.</summary>

```bash
# Debian 13 (trixie), x86_64
$ ./opts.sh -v -o /tmp/out.txt file1 file2; ./opts.sh -o; echo "rc=$?"; ./opts.sh -z; echo "rc=$?"
verbose=1 output=/tmp/out.txt remaining=file1 file2
-o needs a value
rc=2
unknown option: -z
rc=2
```

</details>

**Both error cases are distinguished and both exit 2**, which is the
"used incorrectly" convention from lesson 51. That is what `getopts` buys over
hand-parsing: the two failure modes are separate cases rather than one catch-all.

**`getopts` handles short options only.** It accepts `-vo file` combined, and
it does not do `--verbose`. For long options the choices are GNU `getopt` (a
different, external program with awkward quoting) or a manual `while` loop
over `case "$1"`. For a script you own, short options and a `--help` are
usually enough.

<details class="deeper">
<summary>If you already administer Linux: making a script safe to run twice, and safe to run at the same time as itself</summary>

Two properties turn a script into something you can put in cron and stop thinking
about, and neither is about correctness of the logic.

**Idempotence: running it twice does the same thing as running it once.**

The test is to run it twice in a row and diff the result. Most of the fixes are
choosing the right flag:

| Instead of | Use | Because |
| --- | --- | --- |
| `mkdir /srv/app` | `mkdir -p /srv/app` | Second run does not fail |
| `useradd deploy` | `id deploy >/dev/null 2>&1 \|\| useradd deploy` | Check first |
| `echo "x" >> /etc/hosts` | `grep -qxF "x" file \|\| echo "x" >> file` | Otherwise it appends every run |
| `ln -s a b` | `ln -sfn a b` | Force and no-dereference |
| `tar -xf pkg.tar` | The same into a fresh directory | Extraction is already idempotent |

**The appending one is the classic.** A configuration line added with `>>` on every
run produces a file with the same line two hundred times, and the symptom appears
months later as a service that has become slow to start.

**Concurrency: two copies must not run at once.** Cron will start the next run on
schedule whether or not the last one finished, which is the overlap problem from
lesson 30. `flock` is the answer, and it works inside the script as well as in the
crontab:

```bash
exec 9>/var/lock/myjob.lock
flock -n 9 || { echo "already running" >&2; exit 0; }
```

That opens file descriptor 9 on a lock file and takes a non-blocking lock. The
descriptor stays open for the life of the script and the lock is released when
the process dies, however it dies, no stale lock file, no cleanup needed.
**Exiting 0 rather than 1 is deliberate:** an overlapping run is normal, not
an error, and exiting non-zero would fill your inbox with cron mail.

**A third property worth the same attention: being safe to interrupt.** A script
that writes a file directly leaves a truncated one if killed halfway. Writing to a
temporary and renaming is atomic, because `rename` is:

```bash
tmp=$(mktemp "${target}.XXXXXX")
generate_content > "$tmp"
mv -- "$tmp" "$target"
```

Readers see either the old file or the new one, never a partial. That is the same
mechanism `sed -i` and `visudo` use, and it is worth reaching for any time the
output matters.

</details>

## Cleaning up whatever happens

A script that removes its temporary directory on the last line does so only when
it reaches the last line. `trap` attaches cleanup to the *exit* instead.

<details class="predict">
<summary>The script creates a temporary directory, registers a trap on EXIT, and then deliberately runs `false` under `set -e`. Does the cleanup line run, and what is the exit status?</summary>

```bash
# Debian 13 (trixie), x86_64
$ cat cleanup.sh; echo "--- run it ---"; ./cleanup.sh; echo "rc=$?"
#!/bin/bash
set -euo pipefail
workdir=$(mktemp -d)
trap 'echo "cleaning up $workdir"; rm -rf "$workdir"' EXIT

echo "working in $workdir"
touch "$workdir/scratch"
ls "$workdir"
echo "about to fail on purpose"
false
echo "never reached"
--- run it ---
working in /tmp/tmp.5NZt9tEhO0
scratch
about to fail on purpose
cleaning up /tmp/tmp.5NZt9tEhO0
rc=1
```

</details>

**The cleanup ran and the failure status survived.** `never reached` did not
print, because `set -e` stopped the script at `false`, and the `EXIT` trap
fired anyway, because it fires on *every* exit path. The script still reported
1, so the caller knows it failed.

**`EXIT` is the trap to use**, and it covers more than it looks: normal completion,
`exit` anywhere in the script, a failure under `set -e`, and termination by
SIGTERM or SIGHUP. It does **not** cover SIGKILL, which nothing can.

| Signal | Trap fires | Notes |
| --- | --- | --- |
| Normal end | `EXIT` | |
| `exit 1` | `EXIT` | |
| `set -e` failure | `EXIT` | |
| Ctrl+C | `EXIT`, `INT` | |
| `kill` | `EXIT`, `TERM` | The default `kill` |
| `kill -9` | **Nothing** | Cannot be caught |

**`mktemp -d` and a trap belong together**, as a two-line habit at the top of any
script that needs scratch space. `mktemp` creates the directory with mode 700 and
an unpredictable name, which also closes a symlink-attack class that
`/tmp/myscript.$$` leaves open.

**One caveat worth knowing:** a second `trap ... EXIT` replaces the first rather
than adding to it. If a script needs several cleanups, put them in one function and
trap that.

## Across distributions

None of this varies by distribution, only by shell, which is the same
portability question as the two previous lessons.

| | POSIX `sh` (dash) | bash |
| --- | --- | --- |
| Functions, `local` | Yes (`local` is near-universal) | Yes |
| `${v%pattern}`, `${v#pattern}` | Yes | Yes |
| `${v/old/new}` | **No** | Yes |
| `${v^^}`, `${v,,}` | **No** | Yes |
| `getopts` | Yes | Yes |
| `trap ... EXIT` | Yes | Yes |
| `read -d ''` | **No** | Yes |
| Arrays | **No** | Yes |

**The substitution and case-conversion forms are the ones to watch**, because
they fail silently in dash rather than erroring. The expansion simply does not
happen the way you expect. `${v%pattern}` and `${v#pattern}` are POSIX and
safe.

## Prove it

```
# The two parse checks
bash -n script.sh
dash -n script.sh

# Everything above, found automatically
shellcheck script.sh

# Does it survive an awkward filename
mkdir -p /tmp/t && touch /tmp/t/"a b.txt" /tmp/t/-rf && ./script.sh /tmp/t

# Is it idempotent
./script.sh && ./script.sh && echo "twice is fine"

# Does it clean up when interrupted
./script.sh & sleep 1; kill %1; ls /tmp | grep -c tmp.
```

**The awkward-filename test is the one that finds real bugs**, and it takes one
`touch`. A directory containing `a b.txt` and `-rf` exercises both the splitting and
the leading-hyphen failure in a single run.

## What trips people up

### 1. `for f in $(ls)`

Command substitution flattens the list to a string and the shell splits it on
whitespace. Three files become five iterations.

`for f in *` for a glob, `find -print0` piped to `while IFS= read -r -d ''` for
anything more selective.

### 2. Variables leaking out of functions

Without `local`, everything is global, so a function using `i` destroys the
caller's `i`. The symptom appears somewhere else entirely.

`local` on every variable, and `local x` on its own line before `x=$(command)` so
the command's status is not masked.

### 3. `Argument list too long`

`grep pattern *` in a directory with a hundred thousand files exceeds the kernel's
limit on the size of an argument list.

`find . -name '*.log' -exec grep pattern {} +` batches them, and `xargs` does the
same. The `+` rather than `\;` is what makes it batch instead of forking per file.

### 4. Cleanup on the last line

It runs only if the script reaches the last line, which it does not when it fails.

`trap 'rm -rf "$workdir"' EXIT`, registered immediately after creating the
directory.

### 5. Appending configuration on every run

`echo "x" >> file` in a script that runs nightly produces a file with three hundred
copies of the line.

`grep -qxF "x" file || echo "x" >> file`.

### 6. `local x=$(command)` hiding a failure

`local` succeeds, so the substitution's exit status is discarded and `set -e` never
fires. Declare and assign on separate lines.

## Work it through

A log-archiving script has run nightly for a year and this morning produced an
archive missing two directories. The relevant part:

```
#!/bin/bash
cd /var/log/app
for d in $(ls); do
    tar -czf /backup/$d.tar.gz $d
    rm -rf $d
done
```

Reason it out before reading on. There are four faults, and one of them is much
worse than the others.

**`$(ls)` splits on whitespace**, so a directory called `Q3 reports` becomes `Q3`
and `reports`. That is the reported symptom, and it is the least dangerous fault
here.

**`rm -rf $d` is unquoted**, and this is the serious one. With `d` set to
`Q3`, the `tar` fails, but `rm -rf Q3` also fails harmlessly. Now consider a
directory called `old logs`: the loop runs with `d=old`, and `rm -rf old`
removes a directory called `old` **if one exists**. The script deletes
something it never archived, and the archive that was supposed to protect it
does not contain it.

**No error checking between `tar` and `rm`.** Even with the quoting fixed,
`tar` failing (disk full, permission denied) is followed immediately by `rm
-rf` on the data that was not archived. The two lines must be connected by
their status.

**`cd` unchecked**, which is lesson 51's fault: if `/var/log/app` does not exist,
the loop runs in whatever directory cron started in.

Repaired:

```
#!/bin/bash
set -euo pipefail

cd /var/log/app || exit 1

for d in */; do
    d="${d%/}"
    if tar -czf "/backup/${d}.tar.gz" -- "$d"; then
        rm -rf -- "$d"
    else
        echo "archive failed for $d, keeping it" >&2
    fi
done
```

**`*/` matches directories only** and needs no `ls`. `${d%/}` strips the trailing
slash the glob adds. `--` protects against a directory named like an option. And
the `if` makes the deletion conditional on the archive succeeding, which is the
fault that actually loses data.

The point worth extracting: **three of the four faults were invisible for a
year because the data was convenient.** The script did not become wrong when
somebody created `Q3 reports`; it was always wrong, and the directory name was
the first input that exercised it. Testing with a deliberately awkward
filename (one space, one leading hyphen) takes one `touch` and finds all of
this before production does.

## Try it

Optional, and use a scratch directory.

1. `mkdir -p /tmp/t/"a b" /tmp/t/c && cd /tmp/t`.
2. `for f in $(ls); do echo "[$f]"; done` and count the lines.
3. `for f in *; do echo "[$f]"; done` and count again.
4. `touch -- -rf` in that directory, then run `ls *` and see what happens. Then
   `ls -- *`.
5. Write a function that sets a variable without `local`, call it, and print the
   variable afterwards.
6. Add `local` and repeat.
7. Write a script that does `workdir=$(mktemp -d)`, traps EXIT to remove it, and
   then calls `false`. Confirm the directory is gone and the status is non-zero.
8. `shellcheck` everything you wrote.

**Verification step.** You have it when a directory containing `a b.txt` and a
file called `-rf` runs through your script with no surprises.

## Check yourself

<details class="qa">
<summary>Why does `for f in $(ls)` produce five iterations for three files, and what are the two correct alternatives?</summary>

**Command substitution produces a single string, and the shell then splits it on
whitespace.** `ls` printed the names correctly; the structure was lost the moment
its output became one flat value. A file called `q1 sales.txt` becomes two words,
neither of which names anything.

**The two correct forms:**

```
for f in reports/*; do ...            # a glob expands to a list, not a string
find reports -type f -print0 | while IFS= read -r -d '' f; do ...
```

A glob is the right default, the shell builds the list itself, so no splitting
is required and none happens. `find -print0` is for when you need more
selection than a pattern gives you.

**`-print0` is not paranoia.** Newlines are legal in filenames, so a script
reading line by line is broken for a file called `report\nDROP.txt`, and that
is used deliberately to hide files from monitoring scripts. Null is the one
byte a filename cannot contain, which is why it is the only fully correct
separator.

The tempting wrong fix is quoting: `for f in "$(ls)"` gives you **one** iteration
containing all three names joined together, which is a different wrong answer.
Nothing about `$(ls)` can be made correct here.

</details>

<details class="qa">
<summary>What does `local` do inside a function, and why should `local x` and `x=$(command)` be on separate lines?</summary>

**`local` confines a variable to the function.** Without it every assignment
is global, so a function using `i` or `count` as a working variable silently
overwrites the caller's, and the symptom shows up somewhere unrelated, which
makes it expensive to find.

**The two-line rule is about exit status.** Written as one line:

```
local pct=$(df --output=pcent / | tail -1 | tr -dc '0-9')
```

the exit status of the whole statement is `local`'s, not the command
substitution's. `local` succeeded, so the statement succeeded, even if `df`
failed. `set -e` never fires, and `$?` afterwards is 0.

Split it:

```
local pct
pct=$(df --output=pcent / | tail -1 | tr -dc '0-9')
```

and the assignment's status is the command's, so a failure propagates.

The same applies to `declare`, `export`, and `readonly`, all of which mask the
status of anything on their right-hand side. `shellcheck` flags it as SC2155.

**One more thing about functions worth pairing with this:** `return` sets an
exit status and cannot hand back a value. To return data, `echo` it and let
the caller capture with `$( )`, and note `return` only accepts 0 to 255, so
returning a count that way breaks silently at 256.

</details>

<details class="qa">
<summary>A script creates a temporary directory and removes it on its last line. Why is that wrong, and what replaces it?</summary>

**Because the last line only runs if the script reaches it.** Any failure, any
`exit` in the middle, and any `set -e` abort skips the cleanup and leaves the
directory behind. Over months, `/tmp` fills with the debris of runs that went
wrong, which is exactly the runs you would have wanted to investigate.

**A trap on EXIT runs on every exit path:**

```
workdir=$(mktemp -d)
trap 'rm -rf "$workdir"' EXIT
```

That covers normal completion, an explicit `exit`, a `set -e` abort, Ctrl+C, and a
plain `kill`. The one thing it cannot cover is `kill -9`, which no process can
intercept.

**Register the trap immediately after creating the directory**, not later, the
window between creation and trapping is time in which a failure leaks.

**`mktemp -d` rather than a fixed path** matters for a second reason: it creates
the directory mode 700 with an unpredictable name. `/tmp/myscript.$$` is guessable,
and `/tmp` is world-writable, so an attacker can pre-create it or plant a symlink
and have your script write through it.

One caveat: a second `trap ... EXIT` **replaces** the first. Multiple cleanups go in
one function that the trap calls.

</details>

<details class="qa">
<summary>In `getopts ":vo:"`, what do the leading colon and the colon after `o` each mean, and why is `shift $((OPTIND - 1))` required?</summary>

**The leading colon turns on silent error reporting.** Without it, `getopts`
prints its own message for an unknown option or a missing value. With it, it
stays quiet and signals through the case variable instead, setting `opt` to
`?` for an unknown option and `:` for a missing value, with the offending
letter in `OPTARG`. That is what lets you write your own messages and choose
your own exit status.

**The colon after `o` means that option takes a value**, which arrives in `OPTARG`.
So `":vo:"` declares `-v` as a flag and `-o` as taking an argument.

**`shift $((OPTIND - 1))` discards what `getopts` consumed.** `OPTIND` ends up
pointing at the first non-option argument, so the shift makes `$1` the first real
argument and leaves `"$@"` holding only the operands. Without it the flags are still
in `"$@"`, and a loop over the remaining arguments processes `-v` as though it were
a filename.

**What `getopts` does not do is long options.** It handles `--` as a terminator and
accepts combined short flags like `-vo file`, but `--verbose` needs either GNU
`getopt`, which is a separate external program with awkward quoting, or a manual
`while` loop over `case "$1"`.

For a script you own, short options plus a `--help` case is usually the right amount
of machinery.

</details>

<details class="qa">
<summary>A nightly script appends a line to a config file and, months later, the file has hundreds of copies of it. What property was missing, and what else does that property require?</summary>

**Idempotence: running the script twice should leave the same result as running it
once.** `echo "x" >> file` appends unconditionally, so every run adds another copy.

The fix is to check first:

```
grep -qxF "setting = value" /etc/app.conf || echo "setting = value" >> /etc/app.conf
```

`-q` quiet, `-x` whole line, `-F` fixed string rather than a pattern. All three
matter: without `-x` a line that merely contains the text counts as a match, and
without `-F` any regex character in the value changes the meaning.

**The same property applies across the script**, and it is mostly about flags:

- `mkdir -p` rather than `mkdir`
- `ln -sfn` rather than `ln -s`
- `id user >/dev/null 2>&1 || useradd user`
- Extraction into a fresh directory rather than over an existing one

**The test is mechanical:** run it twice and diff the result. Anything that differs
between the first and second run is not idempotent.

**And the neighbouring property worth fixing at the same time is
concurrency.** Cron starts the next run whether or not the last finished, so a
slow night means two copies operating on the same files. `flock` on a lock
file, exiting 0 when the lock is held, is the standard guard, 0 rather than 1,
because an overlapping run is normal rather than an error and you do not want
cron mail about it.

</details>

## References

- [bash(1)](https://man7.org/linux/man-pages/man1/bash.1.html) - Linux man-pages project. Accessed 2026-08-08.
- [find(1)](https://man7.org/linux/man-pages/man1/find.1.html) - Linux man-pages project. Accessed 2026-08-08.
- [xargs(1)](https://man7.org/linux/man-pages/man1/xargs.1.html) - Linux man-pages project. Accessed 2026-08-08.
- [mktemp(1)](https://man7.org/linux/man-pages/man1/mktemp.1.html) - Linux man-pages project. Accessed 2026-08-08.
- [signal(7)](https://man7.org/linux/man-pages/man7/signal.7.html) - Linux man-pages project. Accessed 2026-08-08.
- [Shell Command Language](https://pubs.opengroup.org/onlinepubs/9799919799/utilities/V3_chap02.html) - The Open Group. Accessed 2026-08-08.

Every block above with a distribution and architecture header was captured by running the command on a Debian 13 (trixie) container. Blocks without one are illustrative.
