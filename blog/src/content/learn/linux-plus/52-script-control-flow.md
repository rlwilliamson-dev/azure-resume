---
title: "The script should only run the backup if the disk is there"
description: "Decisions and repetition. Why the square bracket is a command rather than syntax, the numeric and string operators that are not interchangeable, and the loop that runs once when it should run never."
track: "linux-plus"
level: "working"
order: 530
objectives:
  - "Write an if with elif and else, and choose the right test operator"
  - "Distinguish numeric from string comparison and predict what each does"
  - "Choose between if, case, and a loop for a given problem"
  - "Iterate over files, lines, and counters without breaking on odd input"
  - "Explain what a non-matching glob does to a for loop"
prerequisites: ["your-first-shell-script"]
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
  - title: "test(1)"
    url: "https://man7.org/linux/man-pages/man1/test.1.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-08
    tier: 1
  - title: "Shell Command Language"
    url: "https://pubs.opengroup.org/onlinepubs/9799919799/utilities/V3_chap02.html"
    publisher: "The Open Group"
    accessed: 2026-08-08
    tier: 1
  - title: "glob(7)"
    url: "https://man7.org/linux/man-pages/man7/glob.7.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-08
    tier: 1
  - title: "read(1p)"
    url: "https://man7.org/linux/man-pages/man1/read.1p.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-08
    tier: 1
symptoms:
  - symptom: "Loop runs once with the pattern instead of the filenames"
    anchor: "for-over-a-glob-and-the-trap-in-it"
  - symptom: "integer expression expected"
    anchor: "numbers-and-text-are-compared-differently"
  - symptom: "unary operator expected"
    anchor: "1-unary-operator-expected"
---

> **Before you read.** The backup script from the last lesson takes a directory
> and archives it. Somebody runs it against a path that does not exist, and it
> cheerfully creates an empty archive and reports success.
>
> You want it to check first. The check itself is easy, you know `ls` and you
> know exit statuses.
>
> **But what is `if` actually testing? It is not comparing two things the way a
> programming language does.**

`if` in the shell tests **the exit status of a command**. That is the whole
mechanism, and it explains almost everything that looks strange about shell
conditionals, including why the square bracket needs spaces around it, and why
comparing numbers and comparing text use completely different operators.

Once that one idea is in place, the rest of this lesson is vocabulary.

### Some words you will need

<dl class="terms">
<dt>test</dt>
<dd>A command that evaluates a condition and exits 0 for true. <code>[</code> is another name for it.</dd>
<dt>operator</dt>
<dd>The flag or symbol naming which comparison to make. <code>-f</code>, <code>-eq</code>, <code>=</code>.</dd>
<dt>glob</dt>
<dd>A filename pattern the shell expands before the command runs. <code>*.log</code>.</dd>
<dt>iteration</dt>
<dd>One pass through a loop.</dd>
<dt>arithmetic context</dt>
<dd>Somewhere the shell treats text as numbers. <code>$(( ))</code> and <code>(( ))</code>.</dd>
</dl>

## What breaks without this

**The script does the wrong thing confidently.** A backup of a directory that is
not there produces an empty archive, a zero exit status, and a monitoring system
that reports everything is fine.

**It handles one input and not the next.** Working on `report.txt` and breaking on
a directory with no files in it is the ordinary shape of a script that has not
been given decisions.

**You compare numbers as text.** `[ "10" > "9" ]` is false, silently, and the
script takes the wrong branch with no error at all.

**The loop runs once when it should run never**, because a pattern that matched
nothing was passed through literally.

## `[` is a command, not syntax

This is the single idea the rest of the lesson hangs from.

```
if [ -d /srv/data ]; then
```

`[` is a program. On a minimal system it is a real file, `/usr/bin/[`, and in
bash it is a builtin with the same behaviour. It takes arguments, evaluates
them, and exits 0 for true or 1 for false. The final `]` is not punctuation;
it is a **required argument** telling `[` where its arguments end.

Three consequences follow immediately, and all three are things people trip over:

**The spaces are mandatory.** `[-d /srv/data]` is the shell trying to run a command
called `[-d`, and `[ -d /srv/data]` never gets its closing argument. Both produce
errors that look nothing like the actual mistake.

**`if` is not special.** It runs whatever you give it and branches on the status:

```
if grep -q "^root:" /etc/passwd; then echo "found"; fi
if systemctl is-active --quiet nginx; then echo "running"; fi
if ping -c1 -W1 host >/dev/null 2>&1; then echo "up"; fi
```

None of those use `[` at all, and they are usually clearer than testing the output
of a command with one.

**Zero is true.** Not because the shell is inverted, but because it is reading an
*exit status*, where zero means success. This is the opposite of every programming
language you have met and it stops being confusing once you stop reading it as a
boolean.

<details class="deeper">
<summary>If you already administer Linux: <code>&&</code> and <code>||</code> as control flow, and why <code>a && b || c</code> is not an if-else</summary>

Since `if` branches on an exit status, the shell offers two operators that do the
same job inline. They are worth understanding precisely, because the obvious
shorthand for if-else is subtly broken.

**`a && b` runs `b` only if `a` succeeded. `a || b` runs `b` only if `a`
failed.** Both short-circuit, so the second command is not merely ignored, it
never runs.

The idioms that follow are worth having:

```
mkdir -p /srv/app && cd /srv/app          # only proceed if it worked
command -v jq >/dev/null || { echo "jq required" >&2; exit 1; }
[ -f "$conf" ] || conf=/etc/defaults.conf
systemctl is-active --quiet nginx || systemctl start nginx
```

The second and third are the common ones: `||` as a guard clause, and `||` to
supply a fallback.

**Now the trap.** This looks like if-else and is not:

```
[ -d /srv ] && echo "exists" || echo "missing"
```

It works for that example and breaks the moment the middle command can fail.
`&&` and `||` evaluate strictly left to right with equal precedence, so the
whole thing reads as `([ -d /srv ] && echo "exists") || echo "missing"`. **If
the test succeeds and `echo` then fails, the `||` branch runs too**, and you
get both messages.

With `echo` that is unlikely. With something real it is not:

```
[ -d /srv ] && cp file /srv/ || echo "directory missing"
```

The directory exists, `cp` fails because the disk is full, and the script
reports "directory missing", an error message that sends the next person to
entirely the wrong place.

**Use `&& ... ||` only when the middle command cannot meaningfully fail**, and write
a real `if` otherwise. The rule of thumb: `||` as a guard that exits is always safe,
because nothing follows it; `&& x ||` as a substitute for if-else is not.

**Two related things worth knowing:**

`{ ...; }` groups commands without a subshell, which is what makes the guard
idiom work: `|| { echo ...; exit 1; }` runs both in the current shell. The
semicolon before the closing brace is required, and the spaces inside are too,
for the same reason `[` needs them.

**`set -e` does not apply inside these chains.** A command followed by `&&` or
`||` is being tested, so its failure is handled rather than fatal. That is
deliberate, and it is one of the exceptions from the last lesson, which means
wrapping something in `|| true` is the standard way to say "this is allowed to
fail" under `set -e`.

</details>

## The tests worth knowing

There are many; these are the ones that come up.

**About files:**

| Test | True when |
| --- | --- |
| `-e path` | It exists, whatever it is |
| `-f path` | It exists and is a **regular file** |
| `-d path` | It exists and is a **directory** |
| `-r`, `-w`, `-x` | You can read, write, or execute it |
| `-s path` | It exists and is **not empty** |
| `-L path` | It is a symbolic link |
| `f1 -nt f2` | `f1` is newer than `f2` |

**About strings:**

| Test | True when |
| --- | --- |
| `-z "$v"` | It is **empty** |
| `-n "$v"` | It is **not empty** |
| `"$a" = "$b"` | They are the same text |
| `"$a" != "$b"` | They are not |

Here is all of that in one script:

```bash
# Debian 13 (trixie), x86_64
$ cat check.sh
#!/bin/bash
target="$1"
if [ -z "$target" ]; then
    echo "no target given"
    exit 2
elif [ -d "$target" ]; then
    echo "$target is a directory"
elif [ -f "$target" ]; then
    echo "$target is a regular file"
else
    echo "$target does not exist"
    exit 1
fi
```

**Order matters in an `elif` chain**, and this one is deliberate. The empty
check is first, because every other test on an empty string would be answering
a question about the wrong thing. `-d` comes before `-f` because they are
mutually exclusive and either order works, but `-e` would have to come last,
since it is true for both.

Run against four different inputs:

```bash
# Debian 13 (trixie), x86_64
$ for t in /etc /etc/hostname /nope ""; do printf "%-16s " "${t:-(empty)}"; ./check.sh "$t"; done
/etc             /etc is a directory
/etc/hostname    /etc/hostname is a regular file
/nope            /nope does not exist
(empty)          no target given
```

Four inputs, four branches, and every path through the script exercised, which
is worth doing deliberately for any conditional you write.

## Numbers and text are compared differently

This is the one that produces silent wrong answers rather than errors.

| Compare | Numbers | Text |
| --- | --- | --- |
| equal | `-eq` | `=` |
| not equal | `-ne` | `!=` |
| greater | `-gt` | `>` |
| less | `-lt` | `<` |
| greater or equal | `-ge` |, |
| less or equal | `-le` |, |

<details class="predict">
<summary><code>[ 10 -gt 9 ]</code> compares numerically. <code>[ "10" > "9" ]</code> compares as text, the way a dictionary sorts. Is the second one true?</summary>

```bash
# Debian 13 (trixie), x86_64
$ if [ 10 -gt 9 ]; then echo "10 -gt 9 is true"; else echo "10 -gt 9 is false"; fi; if [ "10" \> "9" ]; then echo "10 > 9 is true"; else echo "10 > 9 is false, because it compared text"; fi
10 -gt 9 is true
10 > 9 is false, because it compared text
```

</details>

**False, and nothing warned you.** As text, `"10"` sorts before `"9"` because the
comparison is character by character and `1` comes before `9`. The script takes the
wrong branch, does the wrong thing, and exits 0.

Where this bites for real is anything comparing versions, sizes, or counts
read from a command. A disk at 100 percent compared as text is "less than" one
at 9 percent, so the alert never fires, and it fires correctly during testing
at 85 percent, which is what makes it survive review.

The rule: `-eq` and friends for numbers, `=` and `!=` for text. The mnemonic
that sticks is that the lettered operators are for numbers, which is backwards
from what it looks like and is worth over-learning for that reason.

And `>` inside `[ ]` needs escaping, as `\>` above, because otherwise the
shell reads it as output redirection and creates a file called `9`. That alone
is a good argument for the double-bracket form in the panel below.

<details class="deeper">
<summary>If you already administer Linux: <code>[[ ]]</code> and <code>(( ))</code>, and when the extra brackets earn their keep</summary>

Bash has two constructs `[` does not, and both remove entire categories of bug.

**`[[ ]]` is shell syntax rather than a command**, which is exactly why it behaves
better: the shell parses it before expansion, so word splitting and globbing do not
happen inside it.

```bash
# Debian 13 (trixie), x86_64
$ ./brackets.sh
--- unquoted, inside [[ ]] ---
  [[ ]] handled the empty variable
--- regex matching, which [ ] cannot do ---
  major 9, minor 2
--- pattern matching, no quotes needed ---
  starts with 9
```

Three things there that `[ ]` cannot do:

**An unquoted empty variable is safe.** `[ -z $empty ]` becomes `[ -z ]`,
which tests whether the string `-z` is non-empty and returns true, the wrong
answer. Inside `[[ ]]` there is no splitting, so it works. You should still
quote out of habit, but the trap is gone.

**`=~` does regex**, with the captures landing in `BASH_REMATCH`. Parsing a version
string without calling out to `sed` or `awk` is worth having, and `${BASH_REMATCH[1]}`
is the first capture group.

`==` does glob pattern matching when the right side is unquoted, so `[[ $file
== *.log ]]` needs no external `case` and no `grep`. Quote the right side and
it becomes a literal comparison instead, which is the distinction to remember.

`(( ))` is arithmetic, and inside it the shell speaks maths:

```
if (( count > 10 )); then
(( count++ ))
(( total = used * 100 / size ))
```

No `$` needed on variable names, `>` and `<` mean what they look like, and there is
no escaping. `$(( ))` is the same evaluation used as a value rather than a test.

**One genuine trap in `(( ))`:** its exit status follows C, not the shell. An
expression evaluating to zero is *false*, so `(( count ))` is false when count is 0,
and `(( 0 ))` under `set -e` **terminates the script**. `((count++)) || true` is
the guard people learn the hard way.

The cost of both is portability. `[[ ]]` and `(( ))` are bash and ksh and zsh,
not POSIX, and they do not exist in dash, so a script using them with
`#!/bin/sh` fails on Debian exactly as in the last lesson. Use `#!/bin/bash`
and they are free; write for `/bin/sh` and you are back to `[ ]` and careful
quoting.

`[[ ]]` also cannot be used with `find -exec` or `xargs`, because it is not a
command, which occasionally surprises people trying to use it outside a
script.

</details>

## `case`, when there are several answers

An `elif` chain comparing one variable against several values is a `case`
statement wearing a disguise:

```
case "$1" in
    start)   echo "starting" ;;
    stop)    echo "stopping" ;;
    restart) echo "stopping"; echo "starting" ;;
    *)       echo "usage: service.sh {start|stop|restart}" >&2; exit 2 ;;
esac
```

<details class="predict">
<summary>The script is called three times: <code>start</code>, <code>restart</code>, and <code>frobnicate</code>. <code>restart</code> matches one pattern that contains two commands. What are the four lines of output, and what is the final exit status?</summary>

```bash
# Debian 13 (trixie), x86_64
$ ./service.sh start; ./service.sh restart; ./service.sh frobnicate; echo "rc=$?"
starting
stopping
starting
usage: service.sh {start|stop|restart}
rc=2
```

</details>

**`case` matches glob patterns, not literal text**, which is more useful than it
first appears:

| Pattern | Matches |
| --- | --- |
| `start` | Exactly that |
| `sta*` | Anything beginning `sta` |
| `start\|begin` | Either word |
| `[Yy]*` | Anything starting with a Y in either case |
| `*` | Everything. **Put it last.** |

**`*)` last is the whole reason to bother with the default case.** It catches the
argument nobody anticipated and turns "the script did nothing and exited 0" into a
usage message and a non-zero status. A `case` without one is a silent failure
waiting for a typo.

**`;;` ends each branch** and does not fall through the way C does. Bash has `;&`
for deliberate fall-through and `;;&` for "keep testing later patterns", both of
which are rare and worth recognising rather than using.

## `for` over a glob, and the trap in it

Iterating over files is the most common loop there is, and the shell expands the
pattern before the loop starts.

<details class="predict">
<summary>The second loop uses the pattern <code>logs/*.missing</code>, and no file matches it. How many times does that loop body run, zero, or something else?</summary>

```bash
# Debian 13 (trixie), x86_64
$ cat glob.sh; echo "--- run it ---"; ./glob.sh
#!/bin/bash
for f in logs/*.log; do
    echo "found $f"
done
for f in logs/*.missing; do
    echo "and now: $f"
done
--- run it ---
found logs/app.log
found logs/db.log
found logs/web.log
and now: logs/*.missing
```

</details>

**Once, with the pattern itself as the value.** When a glob matches nothing, the
shell leaves it alone and passes the literal text through. The loop body then runs
against a filename that does not exist.

**This is a real bug and not a curiosity.** A cleanup loop doing
`for f in /var/spool/*.tmp; do rm "$f"; done` on an empty directory runs `rm` on a
file called `*.tmp`, which fails harmlessly. The same loop calling something that
*creates* a file, or logging an error per iteration, does not fail harmlessly.

Two fixes, and the first is the one to reach for:

```bash
shopt -s nullglob          # a non-matching glob expands to nothing at all
for f in logs/*.missing; do ...; done    # now runs zero times
```

```bash
for f in logs/*.missing; do
    [ -e "$f" ] || continue     # guard inside the loop
    ...
done
```

`nullglob` is a bash option and changes behaviour for the whole script, which is
right at the top of a script you own. The guard is portable and explicit, which is
right in a shared library or a `/bin/sh` script.

**`for` iterates over a list of words, and files are only one kind:**

```
for f in logs/*.log; do ... done          # files, via a glob
for host in web01 web02 db01; do ... done # a literal list
for u in $(cut -d: -f1 /etc/passwd); do ... done   # command output. Fragile.
for ((i = 1; i <= 3; i++)); do ... done   # a counter
```

**That third form is the one to be suspicious of.** Iterating over command
output splits on whitespace, so any value containing a space becomes two
iterations, the same word-splitting failure as the last lesson, and the
subject of the next one.

The counting form is bash-only and needs the double parentheses:

```bash
# Debian 13 (trixie), x86_64
$ cat retry.sh; echo "--- run it ---"; ./retry.sh
#!/bin/bash
for ((i = 1; i <= 3; i++)); do
    echo "attempt $i"
done
--- run it ---
attempt 1
attempt 2
attempt 3
```

## `while`, `until`, and reading lines

`while` repeats as long as a command succeeds. Its most important use is reading
input a line at a time:

```bash
# Debian 13 (trixie), x86_64
$ while IFS= read -r line; do echo "read: $line"; done < names.txt
read: alpha
read: beta
read: gamma
```

**`while IFS= read -r line` is an idiom worth memorising as one unit**, because each
piece prevents a specific corruption:

- **`IFS=`** for this command only, so leading and trailing whitespace on the line
  is preserved rather than stripped.
- **`-r`** so backslashes in the data stay as backslashes.
- **`read` returning non-zero at end of input** is what ends the loop.

Without `IFS=` and `-r` you have a loop that quietly alters the data it reads, which
is worse than one that fails.

**`until` is `while` inverted**, it repeats until the command succeeds, and it
reads better for waiting on something:

```bash
# Debian 13 (trixie), x86_64
$ n=0; until [ "$n" -ge 3 ]; do n=$((n + 1)); echo "n is now $n"; done
n is now 1
n is now 2
n is now 3
```

In practice `until` earns its place in retry loops: `until curl -sf "$url"; do sleep
5; done` says exactly what it means, where the `while ! curl` equivalent needs a
moment's thought.

## Getting out early

`break` leaves the loop. `continue` skips to the next iteration. Both take an
optional number for nested loops, `break 2` leaves two levels, which is rare
and occasionally exactly what you need.

```bash
# Debian 13 (trixie), x86_64
$ while IFS= read -r line; do case "$line" in ok) continue ;; FAIL*) echo "stopping at: $line"; break ;; esac; done < results.txt
stopping at: FAIL disk
```

The file contained five lines and two failures. The loop printed once and stopped,
because `break` fired on the first `FAIL`.

**`continue` is how you skip without nesting.** The alternative is wrapping the
whole body in an `if`, which pushes everything a level to the right and gets worse
with each condition added. An early `continue` for the cases you do not care about
keeps the body flat.

<details class="deeper">
<summary>If you already administer Linux: the subshell that eats your variables, and how to spot it</summary>

This one costs people an hour, produces no error, and looks like the shell is
lying to you.

```
count=0
find /var/log -name '*.log' | while read -r f; do
    count=$((count + 1))
done
echo "$count"        # prints 0
```

**Every stage of a pipeline runs in its own subshell.** The `while` loop on the
right-hand side is a child process; it increments its own copy of `count`, and that
copy is discarded when the pipeline ends. The parent's `count` was never touched.

The same applies to anything else the loop sets (an array, a flag, a
`found=yes`) and it applies to `for` loops in pipelines too.

**Four ways out, in rough order of preference:**

```bash
# 1. Redirect instead of piping. No subshell at all.
while read -r f; do ((count++)); done < <(find /var/log -name '*.log')

# 2. A here-string, when the data is already in a variable
while read -r f; do ((count++)); done <<< "$filelist"

# 3. lastpipe, which runs the final stage in the current shell
shopt -s lastpipe
set +m
find /var/log -name '*.log' | while read -r f; do ((count++)); done

# 4. Let the pipeline produce the answer instead of counting by hand
count=$(find /var/log -name '*.log' | wc -l)
```

`< <(command)` is process substitution and is the general fix. The `<(...)`
part gives the command's output a filename the shell can redirect from, so the
loop runs in the current shell and its variables survive. Note the space
between the two `<` characters; they are two separate things.

**`lastpipe` has conditions** that make it less useful than it sounds: it only
applies when job control is off, which is the default in scripts but not
interactively, hence the `set +m`.

The general test for whether you are in a subshell is to set a variable inside
and read it outside. If it is empty, something forked, a pipeline, a `( )`
group, a command substitution, or a background job. Braces `{ }` group without
forking, which is why `{ ...; } < file` works where `( ... ) < file` would not
help.

</details>

## Across distributions

Control flow is shell behaviour, so it does not vary by distribution, it
varies by **shell**, which is the same portability question as the last
lesson.

| | POSIX `sh` (dash) | bash |
| --- | --- | --- |
| `if`, `case`, `for`, `while`, `until` | Yes | Yes |
| `[ ]` and `test` | Yes | Yes |
| `[[ ]]` | **No** | Yes |
| `(( ))` and `for ((;;))` | **No** | Yes |
| `=~` regex | **No** | Yes |
| Arrays | **No** | Yes |
| `shopt -s nullglob` | **No** | Yes |

**Everything in the left column works everywhere**, which is why POSIX-only
scripts are worth writing when something must run on unknown systems, a
container entrypoint, an installer, anything shipped to customers.

**`dash script.sh` is the test**, and it takes a second. A script that passes both
`bash -n` and `dash -n` is portable in practice.

## Prove it

```
# Does it parse, in both shells
bash -n script.sh
dash -n script.sh

# Exercise every branch deliberately
for t in /etc /etc/hostname /nope ""; do ./check.sh "$t"; done

# Watch which branch is taken
bash -x script.sh /some/path

# And the linter, which knows all of this
shellcheck script.sh
```

**Running a conditional against every input class is the habit.** A
four-branch `if` needs four runs, and writing them as a loop takes one line,
which is what the capture above is doing.

## What trips people up

### 1. `unary operator expected`

`[ -n $v ]` with `v` empty becomes `[ -n ]`, and `[` has an operator with nothing
to operate on.

Quote it: `[ -n "$v" ]`. Or use `[[ -n $v ]]`, where it cannot happen.

The same cause produces `too many arguments` when the variable contains spaces.

### 2. Missing spaces around `[`

`[` is a command. `[-d /path]` is a command called `[-d`, and `[ -d /path]` never
terminates its arguments.

Both errors name something that does not look like the real problem.

### 3. Comparing numbers with `=` or `>`

`[ "10" > "9" ]` is text comparison and is false. It also creates a file called `9`,
because unescaped `>` is redirection.

`-eq`, `-gt`, `-lt` for numbers. Or `(( 10 > 9 ))`, which reads naturally.

### 4. `integer expression expected`

The reverse: `-eq` given something that is not a number. Usually a variable holding
a command's output with a trailing newline, or an empty string.

`${v:-0}` gives a default, and `[[ $v =~ ^[0-9]+$ ]]` checks first.

### 5. A glob that matched nothing

The loop runs once with the pattern as the value. `shopt -s nullglob`, or
`[ -e "$f" ] || continue` as the first line of the body.

### 6. Variables set inside a pipeline

`... | while read; do count=$((count+1)); done` counts in a subshell and the parent
never sees it. Use `< <(...)` instead of a pipe.

## Work it through

A disk-space check is reported as "never alerts". It runs hourly from cron and has
not fired in eight months, including during an incident where a filesystem hit 100
percent.

```
#!/bin/sh
USED=$(df -h /var | tail -1 | awk '{print $5}')
if [ "$USED" > "90%" ]; then
    echo "disk warning: $USED" | mail -s "alert" ops@example.com
fi
```

Reason it out before reading on. There are three faults and they compound.

**`df -h` gives `85%`, with a percent sign.** So `$USED` is never a number, and any
numeric operator would fail with `integer expression expected`. `df -h --output=pcent`
or piping through `tr -dc '0-9'` gives a bare number.

**`>` is not a comparison here.** Unquoted inside `[ ]`, it is output
redirection, the shell creates a file called `90%` in cron's working
directory, and `[ "$USED" ]` becomes a plain non-empty test which is **always
true**. So this script should have alerted every hour.

Except it did not, which is the third fault.

**`#!/bin/sh` and `mail` under cron.** With the test always true, the alert
depended on `mail` working, and cron's minimal environment frequently has no
`PATH` entry for it. The message went nowhere, the exit status was discarded,
and the failure was invisible.

Repaired:

```
#!/bin/bash
set -euo pipefail

used=$(df --output=pcent /var | tail -1 | tr -dc '0-9')

if [ "$used" -ge 90 ]; then
    echo "disk warning: ${used}% on /var" | mail -s "disk alert" ops@example.com
fi
```

**Test it by forcing the branch**, not by waiting: `used=95 bash -x ./check.sh` runs
it with the value you want and shows which way it went.

The point worth extracting: **the two faults that mattered were both silent.**
A text comparison that is always true and a redirection mistaken for an
operator produce no error, no log line, and a script that appears to run
correctly for eight months. Exercising every branch once, including the one
you expect never to happen, is the cheapest possible protection, and it is why
the capture above runs `check.sh` against four different inputs rather than
one.

## Try it

Optional. Everything here is safe.

1. Write `check.sh` from this lesson. Run it against a directory, a file, a
   nonexistent path, and an empty string.
2. Remove the quotes from `[ -z $target ]` and run it with no argument. Read the
   error.
3. `if [ "10" \> "9" ]; then echo yes; else echo no; fi`, then the same with `-gt`.
4. `if (( 10 > 9 )); then echo yes; fi` and note that no escaping was needed.
5. `mkdir empty; for f in empty/*; do echo "[$f]"; done`. Count the iterations.
6. `shopt -s nullglob` and run it again.
7. `count=0; printf 'a\nb\n' | while read -r x; do count=$((count+1)); done; echo "$count"`.
   Then the same with `< <(printf 'a\nb\n')`.
8. Run `shellcheck` on all of them.

**Verification step.** You have it when you can predict, before running it,
how many times a `for` loop over a non-matching glob will execute, and say
why.

## Check yourself

<details class="qa">
<summary>Why does <code>[ -d /srv ]</code> need spaces inside the brackets, and what does the closing <code>]</code> actually do?</summary>

**Because `[` is a command, not syntax.** It is a real program, `/usr/bin/[`,
and a bash builtin with identical behaviour. The shell has to see it as a
separate word to run it, and `[-d` is just a command name that does not exist.

**The closing `]` is a required argument.** `[` was designed so that conditionals
would *look* like other languages, and it insists on a final `]` to confirm you have
reached the end. That is why `[ -d /srv]` fails: `/srv]` is one argument and the
terminator never arrived.

The error messages do not point at this. `[-d: command not found` and
`missing ']'` both describe the symptom rather than the cause.

**The consequence worth carrying forward** is that `if` is not testing an
expression at all. It is running a command and branching on its exit status.
That is why `if grep -q x file` and `if systemctl is-active --quiet nginx`
work with no brackets, and they are usually clearer than wrapping the same
question in a `[ ]`.

It is also why zero means true: zero is success for a command, and the shell is
reading a status rather than a boolean.

</details>

<details class="qa">
<summary>A script compares disk usage with <code>[ "$used" > "90" ]</code> and never alerts. Give the two separate things wrong with that line.</summary>

**`>` inside `[ ]` is output redirection, not comparison.** The shell
consumes it before `[` ever sees it, creates a file called `90`, and leaves `[`
with a single argument. `[ "$used" ]` is a test for a non-empty string, which is
**true whenever `used` has any value at all**.

So the condition is not "greater than 90". It is "is this variable set", and
it always fires, or, in the mirror-image version of this bug, the redirection
silently overwrites something.

**Even escaped as `\>`, it would be a text comparison.** `[ "100" \> "90" ]`
is false, because as text `1` sorts before `9`. That produces the opposite failure:
an alert that works at 85 percent during testing and stays silent at 100 percent
during the incident.

**The fix is a numeric operator on a numeric value:**

```
if [ "$used" -ge 90 ]; then
if (( used >= 90 )); then
```

`(( ))` is the more readable form and needs no escaping, at the cost of being bash
rather than POSIX.

And the value has to actually be a number: `df -h` returns `85%`, so the
percent sign has to be stripped first or `-ge` fails with `integer expression
expected`.

</details>

<details class="qa">
<summary>A <code>for</code> loop over <code>/var/spool/*.tmp</code> runs once when the directory is empty. What happened, and what are the two fixes?</summary>

**A glob that matches nothing is passed through literally.** The shell tries to
expand `*.tmp`, finds no files, and leaves the pattern as text. The loop then
executes once with `f` set to the string `/var/spool/*.tmp`, which is a filename
that does not exist.

**Fix one, for a script you own:**

```
shopt -s nullglob
```

A non-matching glob then expands to nothing and the loop runs zero times. It is a
bash option and applies for the rest of the script, so it belongs near the top.

**Fix two, portable and explicit:**

```
for f in /var/spool/*.tmp; do
    [ -e "$f" ] || continue
    ...
done
```

This works in dash and in a `/bin/sh` script, and it is self-documenting.

**Why it matters more than it looks:** the loop body usually fails harmlessly:
`rm` on a nonexistent file is an error and nothing more. But a body that logs,
sends a notification, increments a counter, or creates a file *does* act,
once, on a name that is a pattern. Cleanup jobs that email an error every hour
on an empty directory are this bug.

The opposite option, `failglob`, makes a non-matching glob an error instead, which
is occasionally what you want in an interactive shell.

</details>

<details class="qa">
<summary><code>count=0; find . -name '*.log' | while read -r f; do count=$((count+1)); done; echo $count</code> prints 0. Why?</summary>

**Each stage of a pipeline runs in its own subshell.** The `while` loop is a child
process. It increments *its* copy of `count`, quite correctly, and that copy is
destroyed when the pipeline finishes. The parent shell's `count` was never
modified, so it is still 0.

Nothing failed and nothing warned you, which is what makes it expensive to
diagnose. The same applies to arrays, flags, and anything else the loop sets.

**The general fix is to avoid the pipe:**

```
while read -r f; do count=$((count+1)); done < <(find . -name '*.log')
```

`< <(...)` is process substitution. The command's output is given a filename,
and the loop is redirected from it rather than piped into it, so it runs in
the current shell. Note the space between the two `<`; they are separate
constructs.

**Or let the pipeline do the counting**, which is usually simpler and faster:

```
count=$(find . -name '*.log' | wc -l)
```

The diagnostic in general: set a variable inside a construct and read it
outside. If it is empty, something forked. Pipelines, `( )` groups, command
substitutions, and background jobs all fork; `{ }` groups do not, which is why
`{ ...; } < file` is the subshell-free way to feed a block.

</details>

<details class="qa">
<summary>When should you reach for <code>case</code> instead of an <code>elif</code> chain, and what does the <code>*)</code> branch buy you?</summary>

When you are comparing one value against several possibilities. An `elif`
chain repeats the variable on every line, which is noise and a place for a
typo; `case "$1" in` names it once.

`case` also matches **glob patterns rather than literal strings**, which an `elif`
of `=` comparisons cannot do without extra work:

```
case "$file" in
    *.log)        archive "$file" ;;
    *.tmp|*.bak)  rm "$file" ;;
    [Rr]eport*)   process "$file" ;;
    *)            echo "unknown: $file" >&2 ;;
esac
```

**`*)` is the default and it must be last**, because patterns are tried in order and
`*` matches everything. What it buys you is a script that reacts to the input nobody
anticipated: without it, an unrecognised argument falls through the whole statement,
the script does nothing, and it exits 0 reporting success.

That silent-success failure is the same category as the always-true comparison
and the glob that matched nothing. The script did not error, it just did not
do anything, and nothing downstream can tell.

**One detail worth recognising:** `;;` ends a branch and does not fall through the
way C does. Bash adds `;&` to fall through deliberately and `;;&` to carry on
testing later patterns, both rare enough that seeing them should make you read
carefully.

</details>

## References

- [bash(1)](https://man7.org/linux/man-pages/man1/bash.1.html) - Linux man-pages project. Accessed 2026-08-08.
- [test(1)](https://man7.org/linux/man-pages/man1/test.1.html) - Linux man-pages project. Accessed 2026-08-08.
- [Shell Command Language](https://pubs.opengroup.org/onlinepubs/9799919799/utilities/V3_chap02.html) - The Open Group. Accessed 2026-08-08.
- [glob(7)](https://man7.org/linux/man-pages/man7/glob.7.html) - Linux man-pages project. Accessed 2026-08-08.
- [read(1p)](https://man7.org/linux/man-pages/man1/read.1p.html) - Linux man-pages project. Accessed 2026-08-08.

Every block above with a distribution and architecture header was captured by running the command on a Debian 13 (trixie) container. Blocks without one are illustrative.
