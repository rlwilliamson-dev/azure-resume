---
title: "Three channels, and pointing them somewhere else"
description: "A command printed four thousand lines and you needed six of them. Every program has one way in and two ways out, and once you can point those anywhere, small commands start doing large jobs."
track: "linux-plus"
level: "working"
order: 200
objectives:
  - "Name the three standard channels and say which one an error goes to"
  - "Redirect output and errors independently, or together, in the right order"
  - "Build a pipeline and say why it beats a temporary file"
  - "Read an exit status, including from a pipeline"
prerequisites: ["name-resolution-and-dns"]
tags: ["linux", "linux-plus", "shell", "pipes", "redirection"]
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
  - title: "stdin(3)"
    url: "https://man7.org/linux/man-pages/man3/stdin.3.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "tee(1)"
    url: "https://man7.org/linux/man-pages/man1/tee.1.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "pipe(7)"
    url: "https://man7.org/linux/man-pages/man7/pipe.7.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "Shell Command Language"
    url: "https://pubs.opengroup.org/onlinepubs/9799919799/utilities/V3_chap02.html"
    publisher: "The Open Group"
    accessed: 2026-08-07
    tier: 1
symptoms:
  - symptom: "Errors still appear on screen after redirecting to a file"
    anchor: "1-the-error-still-appeared-on-screen"
  - symptom: "A script reports success when a step in the pipeline failed"
    anchor: "4-a-pipeline-reports-success-when-it-failed"
---

> **Before you read.** A command has just printed four thousand lines. You needed
> six of them.
>
> You could scroll. You could run it again into a file and open the file. Or you
> could hand its output straight to something that finds the six lines, without
> the four thousand ever reaching the screen.
>
> Here is the question underneath, and it is the one that makes Linux feel
> different once it lands: **why does a system full of small, single-purpose
> commands beat one large program that does everything?**

Because the small ones can be joined together, and the joining costs nothing. A
program that counts lines does not need to know how to search, and a program that
searches does not need to know how to count, because the output of one becomes
the input of the other.

That is the whole of the Unix philosophy, and it is two characters of syntax.

### Some words you will need

<dl class="terms">
<dt>standard input (stdin)</dt>
<dd>Where a program reads from when nobody says otherwise. Your keyboard, normally.</dd>
<dt>standard output (stdout)</dt>
<dd>Where its normal results go. The terminal, normally.</dd>
<dt>standard error (stderr)</dt>
<dd>Where its complaints go. Also the terminal, and that is why they look the same when they are not.</dd>
<dt>redirection</dt>
<dd>Pointing one of those three at a file instead.</dd>
<dt>pipe</dt>
<dd>Connecting one program's stdout to the next one's stdin.</dd>
<dt>exit status</dt>
<dd>A number every command returns when it finishes. Zero means success.</dd>
</dl>

## What breaks without this

**You cannot capture what happened.** Every log, every report, every "send me the
output" ends with redirection, and getting it wrong means the errors are missing
from the file you sent.

**Scripts lie about failing.** A pipeline reports the status of its last command
only, so a script can check for failure and find none while the important step
went wrong.

**Everything takes more steps than it needs.** Without pipes, every intermediate
result becomes a temporary file you create, use, and forget to delete.

## Three channels

<figure class="learn-figure">
<svg viewBox="0 0 720 300" role="img" aria-labelledby="fd-title fd-desc" style="width:100%;height:auto;">
  <title id="fd-title">The three standard channels of a process</title>
  <desc id="fd-desc">A process has one input channel and two output channels. File descriptor 0, standard input, arrives from the keyboard, from a file with the less-than sign, or from a pipe. File descriptor 1, standard output, carries normal results and goes to the terminal, or to a file with the greater-than sign, or into a pipe. File descriptor 2, standard error, carries error messages and goes to the terminal by default, and stays there unless it is redirected separately with 2 greater-than.</desc>
  <g font-family="ui-monospace, monospace">
    <rect x="286" y="108" width="150" height="86" rx="5" fill="currentColor" fill-opacity="0.08" stroke="currentColor" stroke-opacity="0.35"/>
    <text x="361" y="145" text-anchor="middle" font-size="13" fill="currentColor">a command</text>
    <text x="361" y="166" text-anchor="middle" font-size="10.5" fill="currentColor" fill-opacity="0.6">grep, ls, anything</text>
    <text x="20" y="130" font-size="12" fill="currentColor">0  stdin</text>
    <text x="20" y="148" font-size="10" fill="currentColor" fill-opacity="0.55">the keyboard, or</text>
    <text x="20" y="162" font-size="10" fill="currentColor" fill-opacity="0.55">&lt; file, or a pipe</text>
    <text x="470" y="88" font-size="12" fill="currentColor">1  stdout</text>
    <text x="470" y="106" font-size="10" fill="currentColor" fill-opacity="0.55">results. the terminal,</text>
    <text x="470" y="120" font-size="10" fill="currentColor" fill-opacity="0.55">or &gt; file, or | next</text>
    <text x="470" y="196" font-size="12" fill="currentColor">2  stderr</text>
    <text x="470" y="214" font-size="10" fill="currentColor" fill-opacity="0.55">complaints. the terminal,</text>
    <text x="470" y="228" font-size="10" fill="currentColor" fill-opacity="0.55">and stays there unless</text>
    <text x="470" y="242" font-size="10" fill="currentColor" fill-opacity="0.55">you say 2&gt; as well</text>
  </g>
  <g stroke="currentColor" stroke-opacity="0.45" fill="none" stroke-width="1.3">
    <path d="M150 151 L282 151 M275 146 L283 151 L275 156"/>
    <path d="M436 132 L462 132 L462 96 M457 103 L462 95 L467 103"/>
    <path d="M436 172 L462 172 L462 206 M457 199 L462 207 L467 199"/>
  </g>
</svg>
<figcaption>One way in, two ways out. The two ways out look identical on screen and are not.</figcaption>
</figure>

**Errors go somewhere different from results.** That is the fact this whole lesson
rests on, and nothing on screen tells you, because both end up in the same
terminal.

Separate them and it becomes obvious:

```bash
# Debian 13 (trixie), x86_64
$ ls /etc/hostname /nosuchfile > out.txt 2> err.txt; echo "--- out.txt (stdout) ---"; cat out.txt; echo "--- err.txt (stderr) ---"; cat err.txt
--- out.txt (stdout) ---
/etc/hostname
--- err.txt (stderr) ---
ls: cannot access '/nosuchfile': No such file or directory
```

One command, two destinations. The filename that worked went to stdout; the
complaint about the one that did not went to stderr.

**The design reason is worth having.** If errors went to stdout, then
`ls *.txt > list.txt` on a directory with a problem would put the error message
into `list.txt`, and whatever read that file next would treat it as a filename.
Keeping them apart means **a pipeline carries data and a human sees the
problems**, which is exactly what you want.

| Symbol | Does |
| --- | --- |
| `> file` | stdout to a file, **replacing** it |
| `>> file` | stdout to a file, appending |
| `2> file` | stderr to a file |
| `2>> file` | stderr, appending |
| `< file` | take stdin from a file |
| `> file 2>&1` | both to the same file |
| `&> file` | both, bash shorthand for the same thing |
| `2>/dev/null` | throw the errors away |

## Replace or append

```bash
# Debian 13 (trixie), x86_64
$ echo first > log.txt; echo second > log.txt; echo "--- after two > redirects ---"; cat log.txt; echo third >> log.txt; echo "--- after >> ---"; cat log.txt
--- after two > redirects ---
second
--- after >> ---
second
third
```

**`>` truncates before it writes.** `first` was gone before `second` was written,
and nothing warned. The file is emptied the moment the shell sets up the
redirection, which is also why `cmd > file` on a file that `cmd` is reading
produces an empty file rather than an error.

`>>` appends. For anything that accumulates (a log, a report a script adds to)
that is what you want, and reaching for `>` out of habit is how a day's output
becomes one line.

## Both at once, and the order that matters

<details class="predict">
<summary>`cmd > file 2>&1` and `cmd 2>&1 > file` differ by moving three characters. One captures both channels and one does not. Which is which, and why?</summary>

```bash
# Debian 13 (trixie), x86_64
$ echo "--- redirect both, the right way ---"; ls /etc/hostname /nosuchfile > both.txt 2>&1; cat both.txt; echo "--- and the wrong order ---"; ls /etc/hostname /nosuchfile 2>&1 > wrong.txt; echo "(the error above went to the terminal, not the file)"; cat wrong.txt
--- redirect both, the right way ---
ls: cannot access '/nosuchfile': No such file or directory
/etc/hostname
--- and the wrong order ---
ls: cannot access '/nosuchfile': No such file or directory
(the error above went to the terminal, not the file)
/etc/hostname
```

**`> file 2>&1` works. `2>&1 > file` does not.**

Read `2>&1` as "make channel 2 go wherever channel 1 currently goes", it
copies the *current* destination, at the moment it is processed, left to
right.

In the working version, `> file` points stdout at the file first, then `2>&1`
sends stderr to the same place. Both land in the file.

In the broken version, `2>&1` runs first, when stdout is still the terminal,
so stderr is pointed at the **terminal**. Then `> file` moves stdout to the
file and stderr stays where it was pointed. You get results in the file and
errors on screen, which is frequently the opposite of what was wanted.

Look at the second block of output: `ls: cannot access` appeared on screen
between the two `echo` lines, and `wrong.txt` contains only `/etc/hostname`.

The rule that survives: **the redirection that changes stdout must come first.**
Or sidestep it entirely with bash's `&> file`, which does both at once and cannot
be got backwards.

</details>

<details class="deeper">
<summary>If you already administer Linux: why `> file` truncates before the command runs, and the mistakes that follow from it</summary>

The shell sets up redirections **before** executing the command. That ordering is
invisible until it destroys something.

**`sort file > file` produces an empty file.** The shell opens `file` for writing
and truncates it to zero, and only then runs `sort`, which now has nothing to read.
The same applies to `grep pattern log > log`, `sed 's/x/y/' f > f`, and every
variant of "filter a file in place with a redirect". There is no warning, and the
data is gone.

The fixes, in order of preference:

```
sort file -o file              # sort knows about this and handles it
sed -i 's/x/y/' file           # in-place, via a temporary file
sponge < file > file           # from moreutils; soaks up stdin first
grep x file > tmp && mv tmp file
```

**`sed -i` is not atomic despite appearances.** It writes a temporary file and
renames it, so the inode changes, which breaks hard links, and means a process
holding the file open keeps reading the old content. `sed -i` on a log a
daemon has open does nothing visible to that daemon until it reopens the file.

**`noclobber` is the guard**, and worth knowing exists:

```
set -o noclobber
echo hi > existing.txt      # bash: existing.txt: cannot overwrite existing file
echo hi >| existing.txt     # the explicit override
```

Few people run it interactively, but it is reasonable in a script that writes
outputs, where an accidental `>` instead of `>>` is otherwise silent.

**The related trap is `>` inside a loop.** `for f in *; do process "$f" >
out.txt; done` truncates `out.txt` on every iteration and leaves only the last
result. Redirecting the whole loop, `done > out.txt`, opens the file once,
which is both correct and faster.

**And the reason `command > /dev/null 2>&1 &` is written in that order** is the
same rule: everything is arranged before the process starts, so by the time it
runs, both channels already point at the null device and nothing can leak to a
terminal that may be about to disappear.

</details>

## Pipes

A pipe connects one command's stdout to the next one's stdin. No temporary file,
and the two run at the same time rather than one after the other.

```bash
# Debian 13 (trixie), x86_64
$ echo "--- how many accounts ---"; cat /etc/passwd | wc -l; echo "--- same thing, one process fewer ---"; wc -l < /etc/passwd; echo "--- tee writes and passes through ---"; grep bash /etc/passwd | tee shells.txt | wc -l; echo "--- and the file has it too ---"; wc -l shells.txt
--- how many accounts ---
18
--- same thing, one process fewer ---
18
--- tee writes and passes through ---
1
--- and the file has it too ---
1 shells.txt
```

Three things there.

**`cat file | wc -l` works and is a tell.** `wc -l < file` and `wc -l file` do the
same job without an extra process. It is called a useless use of `cat`, nobody
will die, and it is worth not doing.

`tee` splits the stream, writing to a file *and* passing everything through.
It is what you want when a pipeline should also leave a record, and `| sudo
tee /etc/somefile` is the standard answer to the redirection-and-sudo problem
from lesson 06, because then the privileged process is the one doing the
writing.

**Pipes run concurrently.** `command | head -5` does not wait for the first
command to finish; `head` exits after five lines and the first command is stopped
with a broken pipe. That is why `head` on a huge file is instant.

## Exit status

Every command returns a number. Zero means success, anything else means a
specific failure, and `$?` holds the last one.

<details class="predict">
<summary>`false | true` runs a command that always fails, piped into one that always succeeds. What status does the pipeline report, and is that what a script checking for errors would want?</summary>

```bash
# Debian 13 (trixie), x86_64
$ grep -q root /etc/passwd; echo "found root, exit status $?"; grep -q notarealuser /etc/passwd; echo "did not find it, exit status $?"; echo "--- a pipeline reports only the last command ---"; false | true; echo "pipeline status $?"; set -o pipefail; false | true; echo "with pipefail set, status $?"
found root, exit status 0
did not find it, exit status 1
--- a pipeline reports only the last command ---
pipeline status 0
with pipefail set, status 1
```

</details>

**Zero is success**, which is backwards from most people's instinct and is the
convention everywhere: there is one way to succeed and many ways to fail, so
failure gets the non-zero numbers.

`grep -q` is worth knowing on its own, it prints nothing and answers only with
its exit status, which makes it the standard way to ask "does this file
contain this" in a script.

**And the last two lines are the important ones.** `false | true` fails and then
succeeds, and the pipeline reports **0**, because a pipeline's status is its last
command's status. A script checking that status sees success.

`set -o pipefail` changes it to report the first failure instead. On the same
pipeline, the status becomes 1.

<details class="deeper">
<summary>If you already administer Linux: the three lines every script should start with</summary>

```bash
#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
```

**`-e`** exits on the first command that fails, instead of carrying on and doing
the next thing to a system that is not in the state you assumed.

**`-u`** treats an unset variable as an error. This is the one that prevents
`rm -rf "$PREFIX/"` becoming `rm -rf /` when `PREFIX` was never set, a mistake
with a long and well-documented history.

**`-o pipefail`** as above, so a failure anywhere in a pipeline is a failure.

**`IFS`** limits word splitting to newlines and tabs rather than spaces too,
which stops filenames with spaces in them being split into several arguments.

Two honest caveats, because this is often presented as a magic incantation.
`set -e` has genuinely surprising exemptions: it does not trigger inside a
condition, in a command followed by `||`, or in most of a function called in a
test. And it makes deliberate failure handling more verbose: `somecommand ||
true` where you meant it to be allowed to fail. Knowing the limits is the
difference between a safety net and false confidence.

`trap 'echo "failed at line $LINENO" >&2' ERR` on top of that gives you a line
number instead of silence, and `trap cleanup EXIT` runs a cleanup function
whichever way the script ends.

</details>

## Here-documents

When a command wants input and you want to supply several lines of it inline:

```bash
# Debian 13 (trixie), x86_64
$ cat > note.txt <<EOF
first line
second line
EOF
echo "--- the here-doc wrote this ---"; cat note.txt; echo "--- and /dev/null discards ---"; ls /nosuchfile 2>/dev/null; echo "nothing above, exit status was $?"
--- the here-doc wrote this ---
first line
second line
--- and /dev/null discards ---
nothing above, exit status was 2
```

`<<EOF` feeds everything up to the next line reading `EOF` into the command. The
word is arbitrary; `EOF` is convention. It is how a script writes a config file
without a separate template.

**`<<'EOF'` with the word quoted** stops the shell expanding variables inside,
which is what you want when the text contains `$` characters that belong to
something else. Unquoted, `$HOME` becomes your home directory; quoted, it stays
`$HOME`.

**`/dev/null` is the bin.** Anything written to it disappears. `2>/dev/null`
silences errors you have decided you do not care about, and note the exit
status was still 2, so **discarding the message does not discard the
failure.** Silencing errors you have not read is how a broken script looks
like a working one.

<details class="deeper">
<summary>If you already administer Linux: file descriptors properly, and process substitution</summary>

The numbers 0, 1, and 2 are just the first three entries in a per-process
table, and you can use the others. `exec 3< file` opens a file on descriptor 3
for the life of the shell, `read -u 3` reads a line from it, and `exec 3<&-`
closes it, which is how a script reads two files line by line at the same
time, something a plain `while read` loop cannot do.

`ls -l /proc/<pid>/fd` shows what any running process has open, resolved to real
paths. It is the tool for "what file is this thing writing to", and for finding
the deleted-but-still-open file that explains why `df` and `du` disagree.

**Process substitution** is the bash feature worth knowing: `<(command)` presents
a command's output as if it were a file.

```
diff <(sort a.txt) <(sort b.txt)
```

`diff` needs two filenames and cannot take a pipe for both. Process substitution
gives it two, without temporary files, and the same trick works for anything
expecting a filename. `>(command)` goes the other way, feeding a command as if it
were an output file.

**`command | while read` runs the loop in a subshell** in bash, so variables
set inside it are lost when the loop ends, the single most confusing gotcha in
shell scripting. `while read; do ...; done < <(command)` uses process
substitution instead and keeps the loop in the current shell, where the
variables survive.

</details>

<details class="deeper">
<summary>If you already administer Linux: what a pipe actually is, and buffering</summary>

A pipe is a kernel buffer, 64 KiB by default, with a reader at one end and a
writer at the other. Both processes run **concurrently**, and the buffer is what
decouples their speeds: the writer blocks when it is full, the reader blocks when
it is empty. That is why a pipeline's memory use does not grow with the amount of
data flowing through it, however large.

**`SIGPIPE` is why `head` is instant.** When the reader exits, the next write
gets a signal that kills the writer by default. `command | head -5` stops the
command almost immediately rather than letting it produce gigabytes nobody
will read. It is also why you occasionally see `Broken pipe` errors from a
script, usually harmless, and usually meaning something downstream exited
early.

**Buffering changes with the destination**, and this one wastes real time. The C
library line-buffers when stdout is a terminal and **block-buffers** when it is a
pipe or a file. So `tail -f log | grep ERROR` can sit silently for a long while,
producing nothing, not because there are no matches but because 4 KiB of them
have not accumulated yet. `stdbuf -oL command` forces line buffering, `grep
--line-buffered` does it for grep specifically, and `unbuffer` from `expect`
pretends to be a terminal.

The related trick: **many programs change behaviour when stdout is not a
terminal**, not just buffering. `ls` drops colour and columns, `git log` stops
paging. `isatty()` is what they are checking, and it is why piping something
sometimes produces output that looks nothing like what was on screen.

</details>

## Across distributions

Redirection and pipes are shell syntax, not commands, so they behave identically
everywhere the shell is the same. The variation is *which* shell:

| | Note |
| --- | --- |
| `/bin/sh` on Debian and Ubuntu | `dash`, which is POSIX and small |
| `/bin/sh` on the RHEL family | a symlink to `bash` |
| `&>`, `<()`, `set -o pipefail` | **bash only.** `dash` rejects all three. |

**A script starting `#!/bin/sh` and using `&>` works on RHEL and fails on
Debian**, which is a genuinely common portability bug and one of the more
annoying to diagnose, because the failure is a syntax error on a line that looks
fine. Use `#!/bin/bash` if you are going to use bash features, and `>file 2>&1`
if you want the script to run anywhere.

## Prove it

When output is not going where you expect:

```bash
# Is it on stdout or stderr? Throw one away and see what remains.
command 2>/dev/null      # only stdout survives
command 1>/dev/null      # only stderr survives

# Did the file get everything
command > out.txt 2>&1; wc -l out.txt

# Did the pipeline actually succeed
set -o pipefail
command | grep something; echo "status $?"
```

**That first pair is the diagnostic worth remembering.** Discard one channel
and look at what is left, and you know which channel a given line came from,
which is otherwise unanswerable, because on screen they are identical.

## What trips people up

### 1. The error still appeared on screen

`command > file` redirects stdout only. Errors go to stderr and were never
included.

`command > file 2>&1`, or `command &> file` in bash. And check the order: `2>&1`
must come **after** the redirection that moves stdout.

### 2. `>` ate the file

It truncates before writing, immediately, with no prompt. `>>` appends.

The dangerous shape is `sort file > file`, which empties the file before `sort`
reads it and leaves you with nothing. Use `sort file > tmp && mv tmp file`, or
`sort -o file file`, which the tool supports precisely because of this.

Bash's `set -o noclobber` makes `>` refuse to overwrite an existing file, with
`>|` to override. Worth having on interactively.

### 3. Silencing errors and losing the failure

`2>/dev/null` hides the message. It does not change the exit status and it does
not make the problem go away. A script that discards errors it has not read will
carry on after something important failed.

Discard errors you have identified and decided to ignore. Never as a default.

### 4. A pipeline reports success when it failed

The status is the **last** command's. `curl badurl | grep pattern` reports
whatever `grep` did, and `curl` failing is invisible.

`set -o pipefail`, or check `${PIPESTATUS[@]}`, which holds every command's status
individually.

### 5. Expecting a pipe to work for a command that wants a filename

`diff` and `tar -f` and most `-f` options want a name, not a stream. A pipe gives
them nothing usable.

`-` means stdin for many of them (`tar -xf -`). Otherwise bash's `<(command)`
supplies a filename, as in the deeper panel above.

## Work it through

A nightly script backs up a database and reports success every morning. Somebody
notices the backup file is 0 bytes and has been for three weeks.

```
#!/bin/sh
pg_dump mydb | gzip > /backups/db.sql.gz 2>/dev/null
if [ $? -eq 0 ]; then
    echo "backup ok" | mail -s "nightly backup" ops@example.com
fi
```

Reason it out before reading on. There are three separate faults and they
compound.

**Fault one: the pipeline's status is `gzip`'s.** `pg_dump` can fail
completely and `gzip` will still succeed, because compressing nothing is a
perfectly valid thing to do, it produces a small, valid, empty archive. `$?`
is 0, the test passes, the mail goes out.

Fault two: `2>/dev/null` discarded the explanation. `pg_dump` almost certainly
printed something useful (authentication failed, no such database, connection
refused) every night for three weeks, and it went to the bin. This is what
makes it three weeks rather than one morning.

Fault three: `2>` is attached to the wrong thing. In `a | b > file
2>/dev/null` the redirection applies to `gzip`, the last command. `pg_dump`'s
stderr was never touched by it and went to wherever cron sends it, which is
usually mail to the account, which nobody reads. So the message was not even
discarded where the author thought.

The fix, and each line earns its place:

```
#!/bin/bash
set -euo pipefail

if pg_dump mydb | gzip > /backups/db.sql.gz; then
    printf 'backup ok, %s bytes\n' "$(stat -c %s /backups/db.sql.gz)" \
      | mail -s "nightly backup" ops@example.com
else
    echo "backup FAILED" | mail -s "nightly backup FAILED" ops@example.com
fi
```

`pipefail` makes `pg_dump`'s failure the pipeline's failure. Nothing is silenced,
so errors reach cron's mail. The `if` tests the pipeline directly rather than
`$?` afterwards. And **the success message reports the size**, so a zero-byte
backup announces itself instead of being reported as fine.

Now the question worth sitting with: **why did three weeks pass?** Not because
the failure was subtle: `pg_dump` was shouting every night. It passed because
the script was written to report success, and it did that faithfully. A check
that can only say "ok" is not a check.

The habit: **make the success message carry a number.** "Backup ok" is
unfalsifiable. "Backup ok, 2,481,003 bytes" is the same message with a fact in
it, and a human reading "backup ok, 20 bytes" notices on the first morning.

## Try it

Optional, on any machine.

1. `ls /etc /nosuchdir > out.txt 2> err.txt`, then look at both files. Say which
   channel each line came from.
2. Run the same command with `2>/dev/null`, then with `1>/dev/null`. Compare.
3. `echo one > f.txt`, `echo two > f.txt`, `echo three >> f.txt`, `cat f.txt`.
4. `ls /etc | wc -l`, then `ls /etc | head -3`. Notice how fast the second is.
5. `grep -q root /etc/passwd; echo $?` and then with a name that does not exist.
6. `false | true; echo $?`, then `set -o pipefail` and run it again.
7. `diff <(sort /etc/passwd) <(sort /etc/passwd)` and confirm it prints nothing.

**Verification step.** You have it when you can look at `cmd 2>&1 > file` and say,
without running it, which channel ends up where.

## Check yourself

<details class="qa">
<summary>Why do errors go to a separate channel when both end up on the same screen?</summary>

**So that redirecting the results does not contaminate them with error
messages.** `ls *.txt > list.txt` should produce a file of filenames; if errors
went to stdout, a permission problem would put an English sentence in the middle
of that list and whatever read it next would treat it as a filename.

Keeping them apart means **a pipeline carries data and a human sees the
problems**. The data path stays clean while the diagnostics still reach you.

It is also what makes `2>/dev/null` and `2>logfile` possible: you can decide to
handle the two independently, which you could not do if they were one stream.

</details>

<details class="qa">
<summary>`cmd 2>&1 > file` and `cmd > file 2>&1` differ. Explain both.</summary>

Redirections are processed **left to right**, and `2>&1` means "send channel 2
wherever channel 1 is pointing **right now**".

**`cmd > file 2>&1`** points stdout at the file, then sends stderr to the same
destination. Both end up in the file. This is the one you want.

**`cmd 2>&1 > file`** sends stderr to wherever stdout currently points, the
terminal, and *then* moves stdout to the file. Results go to the file, errors
stay on screen.

It is not a duplicate of the destination that gets copied; it is the destination
at that moment. Bash's `&> file` does both in one token and cannot be written
backwards, which is a reason to prefer it when portability is not a concern.

</details>

<details class="qa">
<summary>`curl https://example.com/data | grep ERROR` returns exit status 0 but curl failed. Why, and what are two fixes?</summary>

**A pipeline's exit status is the status of its last command.** `grep` ran, did
its job, and reported on itself. `curl` failing is not represented anywhere in
that number.

Fix one: `set -o pipefail`, which makes the pipeline report the first non-zero
status instead of the last. This is the one to put at the top of every script.

**Fix two: `${PIPESTATUS[@]}`**, a bash array holding every command's status
individually. Useful when you need to know *which* stage failed rather than only
that one did.

Worth noting the second-order problem: `grep` finding no matches also returns 1,
so with `pipefail` and `set -e` a pipeline that legitimately finds nothing will
abort the script. `|| true` on the end is the usual answer where that is
expected.

</details>

<details class="qa">
<summary>Why does `sort file.txt > file.txt` produce an empty file?</summary>

**The shell sets up the redirection before running the command**, and `>`
truncates immediately. By the time `sort` opens `file.txt` to read it, it has
already been emptied.

Nothing warns, and the data is gone.

Two correct forms: `sort file.txt > tmp && mv tmp file.txt`, or `sort -o
file.txt file.txt`: `sort` supports `-o` for exactly this reason, and handles
the ordering internally.

The general rule: **never redirect into a file that the same command is
reading.** `sed -i` and similar exist because of it, and even those write a new
file and rename it rather than truly editing in place.

</details>

<details class="qa">
<summary>What does `tee` do, and why is `| sudo tee /etc/hosts` the answer to a problem from the sudo lesson?</summary>

`tee` writes its input to a file **and** passes it through to stdout, so a
pipeline can leave a record and continue.

The sudo connection: `sudo echo "text" > /etc/hosts` fails, because the shell
sets up the redirection before `sudo` runs, and the shell is unprivileged. The
`echo` would have run as root; it never gets that far.

`echo "text" | sudo tee /etc/hosts` works because **`tee` is the process doing
the writing, and `tee` is the one running under `sudo`.** The redirection is
gone entirely. There is no `>` in the command.

`tee -a` appends rather than replacing, which is what you want for adding a line
to an existing file. And `| sudo tee file > /dev/null` suppresses the copy that
would otherwise be echoed back to your terminal.

</details>

## References

- [bash(1)](https://man7.org/linux/man-pages/man1/bash.1.html) - Linux man-pages project. Accessed 2026-08-07.
- [stdin(3)](https://man7.org/linux/man-pages/man3/stdin.3.html) - Linux man-pages project. Accessed 2026-08-07.
- [tee(1)](https://man7.org/linux/man-pages/man1/tee.1.html) - Linux man-pages project. Accessed 2026-08-07.
- [pipe(7)](https://man7.org/linux/man-pages/man7/pipe.7.html) - Linux man-pages project. Accessed 2026-08-07.
- [Shell Command Language](https://pubs.opengroup.org/onlinepubs/9799919799/utilities/V3_chap02.html) - The Open Group. Accessed 2026-08-07.

Every block above with a distribution and architecture header was captured by running the command on a Debian 13 (trixie) container. Blocks without one are illustrative.
