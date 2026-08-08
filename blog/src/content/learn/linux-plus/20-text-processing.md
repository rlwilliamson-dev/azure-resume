---
title: "Finding one line in a million"
description: "A log file has the answer somewhere in it. Six small commands that search, cut, count, and rewrite text, and the pipeline pattern that answers most questions you will ever ask of a log."
track: "linux-plus"
level: "working"
order: 210
objectives:
  - "Search a file with grep and a basic regular expression"
  - "Pull one column out of structured text and count what is in it"
  - "Rewrite text with sed and select fields with awk"
  - "Build the sort, uniq -c, sort -rn pipeline and say what each stage does"
prerequisites: ["shell-redirection-and-pipes"]
tags: ["linux", "linux-plus", "shell", "grep", "awk", "sed"]
updated: 2026-08-07
draft: false
examObjectives:
  - exam: "xk0-006"
    domain: "1.0"
    objective: "1.5"
sources:
  - title: "grep(1)"
    url: "https://man7.org/linux/man-pages/man1/grep.1.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "sed(1)"
    url: "https://man7.org/linux/man-pages/man1/sed.1.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "cut(1)"
    url: "https://man7.org/linux/man-pages/man1/cut.1.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "sort(1)"
    url: "https://man7.org/linux/man-pages/man1/sort.1.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "uniq(1)"
    url: "https://man7.org/linux/man-pages/man1/uniq.1.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "regex(7)"
    url: "https://man7.org/linux/man-pages/man7/regex.7.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "GNU Awk User's Guide"
    url: "https://www.gnu.org/software/gawk/manual/gawk.html"
    publisher: "GNU Project"
    accessed: 2026-08-07
    tier: 1
symptoms:
  - symptom: "grep pattern with a dot or star matches too much"
    anchor: "2-a-dot-matches-anything"
  - symptom: "cut -d gives the wrong field on space-separated text"
    anchor: "3-cut-cannot-cope-with-runs-of-spaces"
---

> **Before you read.** A web server has been misbehaving. Its log has 1.2 million
> lines in it. Somewhere in there is the answer.
>
> You cannot read 1.2 million lines. You cannot open it in an editor. And you do
> not yet know what you are looking for, so you cannot search for it either.
>
> **How do you get from a million lines to a handful without knowing in advance
> which handful you want?**

By asking questions of the *shape* of the data rather than its content. Which
addresses appear most often. Which status codes. How many of each. Those answers
fit on a screen, and one of them will tell you what to search for.

That is one pipeline, four commands long, and it is the single most useful thing
in this lesson. The rest is the vocabulary that lets you build variations of it.

The example log throughout is small enough to check by eye, so you can verify
that each command did what the prose claims. Everything works identically at a
million lines.

### Some words you will need

<dl class="terms">
<dt>regular expression</dt>
<dd>A pattern language for describing text. <code>grep</code> and <code>sed</code> both take one.</dd>
<dt>field</dt>
<dd>One column of structured text, decided by a separator. Field 1 of a log line is usually the address.</dd>
<dt>delimiter</dt>
<dd>The character separating fields. A space in a log, a colon in <code>/etc/passwd</code>, a comma in a CSV.</dd>
<dt>filter</dt>
<dd>A command that reads stdin, changes it, and writes stdout. Everything here is one, which is why they compose.</dd>
</dl>

## What breaks without this

**Investigation stops at the size of the file.** Anything you cannot read by eye
becomes unusable, which is every log on every real system.

**You answer the wrong question.** "Is the error in there?" is a yes-or-no with
little value. "Which client is causing them and how many?" is the useful one, and
it needs counting rather than searching.

**Reports become manual work.** Anything you do by reading and tallying is
something a four-command pipeline does correctly every time.

## grep: finding lines

```bash
# Debian 13 (trixie), x86_64
$ cd /tmp; grep 403 access.log
10.0.0.14 - - [07/Aug/2026:09:14:11] "GET /admin HTTP/1.1" 403 199
10.0.0.14 - - [07/Aug/2026:09:16:02] "GET /admin HTTP/1.1" 403 199
10.0.0.14 - - [07/Aug/2026:09:17:01] "GET /admin HTTP/1.1" 403 199
10.0.0.14 - - [07/Aug/2026:09:19:55] "GET /admin HTTP/1.1" 403 199
```

**`grep` prints lines that match.** That is the whole idea, and the flags are
where the value is:

| Flag | Does |
| --- | --- |
| `-i` | Ignore case |
| `-v` | Invert: print lines that do **not** match |
| `-c` | Count matching lines instead of printing them |
| `-n` | Show line numbers |
| `-r` | Search a directory tree |
| `-l` | Print only the names of files that matched |
| `-w` | Match whole words only |
| `-A 3` / `-B 3` / `-C 3` | Also print lines after, before, or around each match |
| `-E` | Extended regular expressions |
| `-q` | Print nothing, answer with the exit status |

**`-v` is the one people forget and it is half the job.** Excluding the noise is
frequently faster than describing the signal: `grep -v ' 200 ' access.log` gives
you every request that was not a success.

**`-C 3` is what you want when reading a stack trace or a service log**, because
the line that matched is rarely the whole story.

### Enough regular expression to be useful

| Pattern | Matches |
| --- | --- |
| `error` | that literal text, anywhere in the line |
| `^error` | only at the **start** of a line |
| `error$` | only at the end |
| `.` | any single character |
| `.*` | any number of any characters |
| `[0-9]` | one digit |
| `[a-z]*` | any number of lowercase letters |
| `\.` | a literal dot |

**Anchors are the highest-value two characters here.** `^root` finds the root
account in `/etc/passwd`; plain `root` also finds every account whose home is
under `/root` and every comment mentioning it.

`grep -E` turns on extended expressions, which add `+`, `?`, `|`, and `()` without
backslashes: `grep -E 'error|warning|fatal' logfile` is the everyday use.

## The pipeline that answers most questions

<details class="predict">
<summary>`cut -d" " -f1 access.log | sort | uniq -c | sort -rn` — four commands. Before you look, say what each one contributes and why `sort` appears twice.</summary>

```bash
# Debian 13 (trixie), x86_64
$ cd /tmp; echo "--- who is hitting us, most first ---"; cut -d" " -f1 access.log | sort | uniq -c | sort -rn
--- who is hitting us, most first ---
      5 10.0.0.14
      2 10.0.0.9
      2 10.0.0.31
      1 10.0.0.7
```

**`cut -d" " -f1`** keeps only the first space-separated field of each line — the
client address — and throws away the rest.

**`sort`** puts identical addresses next to each other. This is the stage people
leave out, and it is required by the next one.

**`uniq -c`** collapses runs of identical adjacent lines into one, with a count.
**`uniq` only compares neighbouring lines**, which is exactly why the sort has to
come first: unsorted input gives you a count of 1 for nearly everything.

**`sort -rn`** sorts the result numerically (`-n`) and in reverse (`-r`), putting
the biggest count at the top. Without `-n` it sorts as text, where `9` comes
after `10`.

The answer: `10.0.0.14` made five of the ten requests, more than twice anyone
else. That is the line to investigate, and we found it without knowing in advance
that it existed.

**This pipeline generalises to anything.** Change the field number and you are
counting status codes, or URLs, or usernames. It is the workhorse.

</details>

Reading it as a sentence: *take one column, group the same values together, count
each group, show the biggest first.*

<details class="deeper">
<summary>If you already administer Linux: sort's real flags, and why LC_ALL matters</summary>

**`sort` is not sorting the way you think.** It uses locale collation, so in most
locales it ignores punctuation and case, and the order changes with `LC_COLLATE`.
Two machines with different locales sort the same file differently, which breaks
`diff` on generated files and produces build artefacts that are not reproducible.
**`LC_ALL=C sort`** forces plain byte order and is what belongs in any script
whose output is compared.

The flags worth knowing beyond `-n` and `-r`:

**`-h`** sorts human-readable sizes, so `du -h | sort -h` orders `1.5K`, `2M`,
`1G` correctly — which plain `-n` cannot do.

**`-k`** sorts by a field: `sort -k3 -n file` on the third column, and
`sort -t: -k3 -n /etc/passwd` sorts accounts by UID. Note `-k3` alone means
"from field 3 to the end of the line", and `-k3,3` means field 3 only; the
difference produces wrong answers that look plausible.

**`-u`** deduplicates, so `sort -u` replaces `sort | uniq` with one process.

**`-s`** is a stable sort, preserving the previous order within equal keys, which
is what lets you chain two sorts to get a secondary ordering.

**`uniq` has more than `-c`:** `-d` shows only the duplicated lines, `-u` only the
ones that appeared exactly once, and `-f n` skips the first n fields when
comparing — which is how you dedupe log lines that differ only by timestamp.

</details>

## cut, and its limitation

`cut` pulls out columns. `-d` sets the delimiter, `-f` picks the fields:

```
cut -d: -f1,7 /etc/passwd     # login name and shell
cut -d, -f2 data.csv          # second column of a CSV
cut -c1-8 file                # characters 1 to 8, ignoring fields entirely
```

**`cut` treats every delimiter as significant**, which is fine for `/etc/passwd`
where the colons are exact and a real problem for text aligned with spaces. Two
spaces between columns means an empty field between them, and `-f2` returns
nothing.

There is no `cut` flag that fixes this. `awk` is the answer, and that is largely
why `awk` exists.

## awk: fields, done properly

```bash
# Debian 13 (trixie), x86_64
$ cd /tmp; echo '--- awk picks fields by number ---'; awk '{print $1, $8}' access.log | head -4; echo '--- and can filter as it goes ---'; awk '$8 == 403 {print $1}' access.log | sort -u
--- awk picks fields by number ---
10.0.0.14 200
10.0.0.9 200
10.0.0.14 403
10.0.0.31 200
--- and can filter as it goes ---
10.0.0.14
```

**`$1` is the first field, `$8` the eighth, `$0` the whole line, `NF` the number
of fields.** Any run of whitespace separates them, so the `cut` problem above does
not arise.

An awk program is `pattern { action }`, and either half can be left out:

| Program | Does |
| --- | --- |
| `{print $1}` | no pattern, so every line |
| `/error/ {print}` | lines matching a regex |
| `$8 == 403 {print $1}` | lines where field 8 equals 403 |
| `NF > 5 {print}` | lines with more than five fields |
| `$9 > 1000 {print $1, $9}` | numeric comparison on a field |

**`-F` sets the separator** for text that is not whitespace-delimited:
`awk -F: '{print $1}' /etc/passwd`.

And awk can count as it goes, which is where it stops being a better `cut`:

```bash
# Debian 13 (trixie), x86_64
$ cd /tmp; echo '--- sed replaces ---'; sed 's/10\.0\.0\./10.0.0.x/' access.log | head -3; echo '--- how many bytes served in total ---'; awk '{total += $9} END {print total}' access.log
--- sed replaces ---
10.0.0.x14 - - [07/Aug/2026:09:14:02] "GET /index.html HTTP/1.1" 200 5120
10.0.0.x9 - - [07/Aug/2026:09:14:07] "GET /style.css HTTP/1.1" 200 812
10.0.0.x14 - - [07/Aug/2026:09:14:11] "GET /admin HTTP/1.1" 403 199
--- how many bytes served in total ---
17194
```

**`END { }` runs once after the last line**, which is how you accumulate a total.
`BEGIN { }` runs once before the first, for headers and setting `FS`.

`awk '{a[$1]++} END {for (k in a) print a[k], k}'` replaces the whole
`sort | uniq -c` pipeline with one pass and no sorting — the associative array is
awk's real party trick, and it is the version that scales to a file too large to
sort.

## sed: rewriting

`sed 's/old/new/'` substitutes. The pieces:

| | Means |
| --- | --- |
| `s/a/b/` | replace the **first** `a` on each line with `b` |
| `s/a/b/g` | replace every occurrence |
| `s/a/b/gi` | every occurrence, ignoring case |
| `/pattern/d` | delete matching lines |
| `-n '5,10p'` | print only lines 5 to 10 |
| `-i` | edit the file in place |

In the capture above, `10\.0\.0\.` has **escaped dots** — because an unescaped `.`
matches any character. The dots are the point of the exercise: `10.0.0.` would
also match `100000x` and a great deal else.

**`sed -i` deserves suspicion.** It does not edit in place: it writes a new file
and renames it over the original, which breaks hard links, changes the inode, and
needs free space. Run it without `-i` first and read the output. `sed -i.bak`
keeps a copy, which costs nothing and has saved a great many afternoons.

<details class="deeper">
<summary>If you already administer Linux: grep's faster relatives, and when to stop using these tools</summary>

**`grep -F` searches for a fixed string** with no regex interpretation, and is
substantially faster on large files. `grep -F -f patterns.txt bigfile` matches
against a list of literal strings from a file, which is the tool for checking a
log against a list of known-bad addresses.

**`grep -P` uses Perl-compatible expressions** where they are compiled in, adding
lookahead, non-greedy `*?`, and `\d`. Portable scripts should not rely on it —
it is unavailable on some builds and `-E` covers most needs.

**`ripgrep` (`rg`) and `ag`** are dramatically faster on trees because they
parallelise and skip what `.gitignore` excludes. Neither is on the exam and both
are worth installing on a machine you use daily.

**`zgrep`, `zcat`, `zless`** read gzipped files without decompressing them first,
which matters because rotated logs are compressed and `/var/log/syslog.2.gz` is
where yesterday's answer lives. There are `bz` and `xz` equivalents.

**Know when to stop.** These tools are for lines of text. The moment the data is
JSON, `jq` is the correct answer and a `grep`-based approach will produce
something that works on your sample and fails on the first nested object. For
YAML, `yq`. For CSV with quoted fields containing commas, a CSV-aware tool —
because `cut -d,` cannot parse it and neither can awk without help. Reaching for
`grep` on structured data is a common way to build something subtly wrong.

`awk` is a full programming language with functions, arrays, and control flow. If
your awk program has grown past a few lines, that is the signal to write it in
something with a test suite rather than a signal to write more awk.

</details>

## Everything else, briefly

| Command | Does |
| --- | --- |
| `wc -l` / `-w` / `-c` | count lines, words, bytes |
| `head -n 20` / `tail -n 20` | first or last lines |
| `tr 'a-z' 'A-Z'` | translate characters |
| `tr -d '\r'` | delete characters — this one fixes Windows line endings |
| `tr -s ' '` | squeeze runs of a character into one |
| `xargs` | turn input lines into arguments for another command |

**`tr -d '\r'`** earns its place. A config file edited on Windows has `\r\n` line
endings, and the trailing carriage return becomes part of the last value on every
line — so `PORT=8080\r` is not `8080`, and the error message will not mention it.
`file thefile` says `with CRLF line terminators` and `dos2unix` fixes it properly.

**`xargs` bridges the gap** between commands that produce lines and commands that
take arguments:

```
grep -rl 'old.example.com' /etc | xargs sed -i.bak 's/old/new/g'
```

`-r` on `xargs` stops it running at all when the input is empty, which prevents
a command running with no arguments and doing something unintended. `-0` with
`find -print0` handles filenames containing spaces.

<details class="deeper">
<summary>If you already administer Linux: the classic pipelines, and the ones worth memorising</summary>

A few that come up often enough to type from memory.

**Top talkers in a log**, the pipeline from earlier with a field number swapped:

```
awk '{print $1}' access.log | sort | uniq -c | sort -rn | head -20
```

**Status code distribution**, which is the first thing to look at on a web
server behaving oddly:

```
awk '{print $8}' access.log | sort | uniq -c | sort -rn
```

**Largest directories**, when a disk fills:

```
du -h --max-depth=1 /var | sort -h | tail -20
```

`sort -h` rather than `-n`, because the sizes have suffixes.

**Which process is using a deleted file**, when `df` and `du` disagree:

```
lsof +L1
```

**Failed SSH logins by source**, which is both a security check and a good
demonstration that these tools are the whole toolkit:

```
journalctl -u sshd --since '24 hours ago' \
  | grep 'Failed password' \
  | awk '{print $(NF-3)}' \
  | sort | uniq -c | sort -rn
```

`$(NF-3)` counts backwards from the end of the line, which is how you address a
field in text where the number of leading fields varies — a genuinely useful trick
when the timestamp format is inconsistent.

**Two files, what is in one and not the other:**

```
comm -23 <(sort a.txt) <(sort b.txt)
```

`comm` needs sorted input and prints three columns — only in A, only in B, in
both — and `-23` suppresses the second and third, leaving only-in-A. The process
substitution is from the previous lesson.

</details>

## Across distributions

The tools are GNU coreutils, GNU grep, GNU sed, and GNU awk on every distribution
this exam covers, so they behave identically. Two things to know anyway:

| | Note |
| --- | --- |
| `awk` | Usually `gawk`, sometimes `mawk` on Debian minimal. `mawk` is faster and lacks some GNU extensions. |
| `sed -i` without a suffix | GNU accepts it. BSD and macOS require an argument, so `sed -i '' ...`. |
| `grep -P` | Present on most builds, absent on some. `-E` is the portable choice. |

**The `sed -i` difference is the one that catches people writing on a Mac and
deploying to Linux**, and it fails loudly rather than subtly, which is the better
kind of incompatibility.

## Prove it

Build pipelines one stage at a time, checking after each:

```bash
# Stage 1: is the field right
cut -d" " -f1 access.log | head

# Stage 2: add the sort, confirm grouping
cut -d" " -f1 access.log | sort | head

# Stage 3: add the count
cut -d" " -f1 access.log | sort | uniq -c | head

# Stage 4: order it
cut -d" " -f1 access.log | sort | uniq -c | sort -rn | head
```

**`| head` after each stage** keeps the output readable while you check that the
stage did what you meant. Building the whole thing and running it once produces
output you cannot verify, and a wrong field number looks exactly like a correct
one until you check.

## What trips people up

### 1. `uniq` without `sort` first

`uniq` compares **adjacent** lines only. Unsorted input gives a count of 1 for
almost everything, and the output looks plausible.

Always `sort | uniq -c`. Or `sort -u` when you want deduplication without counts.

### 2. A dot matches anything

`grep 10.0.0.1` also matches `100.0.0.1`, `10x0y0z1`, and more. In a regular
expression `.` is any character.

`grep -F 10.0.0.1` for a literal string, or escape them: `10\.0\.0\.1`.

`.*` is greedy in the same way and matches as much as it can, which is why
`s/".*"/X/` on a line with two quoted strings replaces everything between the
first and last quote rather than each pair.

### 3. `cut` cannot cope with runs of spaces

Two spaces mean an empty field between them, so `-f2` on aligned output returns
nothing.

`awk '{print $2}'` treats any run of whitespace as one separator. Use `cut` for
exact delimiters like `/etc/passwd`, `awk` for anything spaced by eye.

### 4. `sed -i` on a file you have not backed up

It rewrites the file with no undo, and a regex that matches more than you
intended does so on every line at once.

Run it without `-i` and read the output. Then `sed -i.bak`.

### 5. Building the whole pipeline before testing any of it

A six-stage pipeline that produces nothing gives no clue which stage is at fault.
Build up, checking with `head` after each.

## Work it through

A web server is slow. The log is 1.2 million lines. Nobody knows what changed.

Reason through the order before reading on.

**Do not search yet.** You do not know what you are looking for, and `grep`
requires knowing. Start with distributions, which need no hypothesis.

**What status codes are we returning?**

```
awk '{print $8}' access.log | sort | uniq -c | sort -rn
```

A normal shape is mostly 200s with a scattering of 304s and 404s. A large count
of 500s means the application; a large count of 403s means something is being
refused repeatedly; a large count of 499s or 408s means clients giving up, which
points at slowness rather than errors.

**Who is generating the traffic?**

```
awk '{print $1}' access.log | sort | uniq -c | sort -rn | head -20
```

If one address has a large share, that is a scraper, a broken client, or a
health check that somebody set to one second. If it is flat, the load is genuine
and this is a capacity question rather than an incident.

**What are they asking for?**

```
awk '{print $7}' access.log | sort | uniq -c | sort -rn | head -20
```

One expensive endpoint dominating is the common answer, and it names the thing to
fix.

**Now** you know enough to search. Cross the two:

```
awk '$1 == "10.0.0.14" {print $7, $8}' access.log | sort | uniq -c | sort -rn | head
```

which tells you what that specific client was doing and whether it was being
served or refused.

**And check the time distribution**, because "slow since when" is the question
everyone asks next:

```
awk '{print substr($4, 14, 5)}' access.log | sort | uniq -c
```

`substr` pulls the hour and minute out of the timestamp field. A count per minute
turns "slow today" into "started at 09:15", and 09:15 is something you can
correlate with a deployment.

Now the point worth extracting: **every one of those is the same pipeline with a
different field number.** Extract a column, group, count, order. Learn it once and
the only thing you vary is which column and which filter — which is why this
lesson is short and covers more ground than it looks.

And the habit: **start with distributions, not searches.** A search needs a
hypothesis; a distribution produces one. Beginning with `grep` means you find only
what you already suspected, which on a problem nobody understands is nothing.

## Try it

Optional, on any machine. `/var/log/` has real material.

1. `grep -c bash /etc/passwd`, then `grep -v nologin /etc/passwd | wc -l`.
2. `cut -d: -f1,7 /etc/passwd | head`. Then `cut -d: -f7 /etc/passwd | sort |
   uniq -c | sort -rn` — how many accounts use each shell.
3. `awk -F: '$3 >= 1000 {print $1}' /etc/passwd` — every real human account.
4. `awk -F: '{total += $3} END {print total}' /etc/passwd`, which is meaningless
   and proves the mechanism.
5. `du -h --max-depth=1 /var 2>/dev/null | sort -h | tail`.
6. Build a pipeline one stage at a time with `| head` after each, and notice how
   much easier it is to spot a wrong field number.
7. `echo "hello world" | tr 'a-z' 'A-Z'`, then `tr -s ' '` on text with runs of
   spaces.

**Verification step.** You have it when, given an unfamiliar structured file, you
can produce a count of the most common value in any column without looking
anything up.

## Check yourself

<details class="qa">
<summary>Why must `sort` come before `uniq -c`, and what happens without it?</summary>

**`uniq` only compares adjacent lines.** It collapses *runs* of identical lines,
not all identical lines anywhere in the file.

Without a preceding sort, identical values scattered through the file are never
adjacent, so almost every line reports a count of 1. The output looks like a
valid result — it has counts, it has values — and it is wrong.

`sort` brings identical values together so `uniq` can see them as a run.

`sort -u` is the shortcut when you only want deduplication and not counts, and it
does both jobs in one process.

</details>

<details class="qa">
<summary>`grep 10.0.0.1 access.log` returns lines containing `100.0.0.14`. Why, and what are two fixes?</summary>

**`.` matches any single character in a regular expression.** So the pattern
matches `10`, any character, `0`, any character, `0`, any character, `1` — which
`100.0.0.14` satisfies, along with a great many strings that are not addresses at
all.

**Fix one: escape them.** `grep '10\.0\.0\.1'` makes each dot literal.

**Fix two: `grep -F 10.0.0.1`**, which turns off regex interpretation entirely and
searches for the fixed string. It is also faster.

Worth adding `-w` in this case regardless: even a correct literal match for
`10.0.0.1` matches `10.0.0.14`, because it is a substring. `grep -Fw` handles
both problems at once.

</details>

<details class="qa">
<summary>When would you reach for `awk` instead of `cut`, and why?</summary>

**When the fields are separated by whitespace rather than by an exact
character.** `cut` treats every delimiter as significant, so two spaces mean an
empty field between them and `-f2` returns nothing. `awk` treats any run of
whitespace as a single separator, which is what aligned output requires.

Also when the task involves anything beyond selection: comparing a field
numerically (`$8 == 403`), accumulating a total in `END`, addressing a field from
the end (`$(NF-3)`), or counting into an array.

`cut` remains the right tool for exact-delimiter data — `/etc/passwd` with its
colons, a simple CSV — where it is simpler to read and marginally faster.

</details>

<details class="qa">
<summary>What does `sed -i` actually do to the file, and why should that make you careful?</summary>

**It does not edit in place, despite the name.** It writes the result to a new
file and renames that over the original.

Three consequences. Hard links to the original are broken, because the new file
is a different inode. The inode number changes, which matters to anything
tracking it. And it needs free space for a second copy, so on a full disk it can
fail partway — which is exactly when you were editing a file to free space.

Add the risk that a regex matching more than intended does so on every line at
once, with no undo.

`sed -i.bak` keeps the original with a suffix and costs nothing. And running it
without `-i` first, to read the output, is the habit worth having.

</details>

<details class="qa">
<summary>You have a 1.2 million line log and no hypothesis. What do you run first, and why not `grep`?</summary>

**A distribution, not a search.** Something like:

```
awk '{print $8}' access.log | sort | uniq -c | sort -rn
```

which counts each status code, or the same with `$1` for client addresses.

**`grep` requires knowing what you are looking for.** It can only confirm or deny
a suspicion you already hold, so on a problem nobody understands it returns
either nothing or exactly the thing you already assumed — neither of which is
information.

A distribution needs no hypothesis and produces one. It fits on a screen
regardless of the input size, and the anomaly in it is what you then search for.

Start broad, narrow once the data has told you where to look.

</details>

## References

- [grep(1)](https://man7.org/linux/man-pages/man1/grep.1.html) - Linux man-pages project. Accessed 2026-08-07.
- [sed(1)](https://man7.org/linux/man-pages/man1/sed.1.html) - Linux man-pages project. Accessed 2026-08-07.
- [cut(1)](https://man7.org/linux/man-pages/man1/cut.1.html) - Linux man-pages project. Accessed 2026-08-07.
- [sort(1)](https://man7.org/linux/man-pages/man1/sort.1.html) - Linux man-pages project. Accessed 2026-08-07.
- [uniq(1)](https://man7.org/linux/man-pages/man1/uniq.1.html) - Linux man-pages project. Accessed 2026-08-07.
- [regex(7)](https://man7.org/linux/man-pages/man7/regex.7.html) - Linux man-pages project. Accessed 2026-08-07.
- [GNU Awk User's Guide](https://www.gnu.org/software/gawk/manual/gawk.html) - GNU Project. Accessed 2026-08-07.

Command output was captured on the images pinned in `blog/scripts/distros.json`,
against a synthetic access log small enough to check by eye. Blocks without a
distribution and architecture header are illustrative.
