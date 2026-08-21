---
title: "How to troubleshoot"
description: "Troubleshooting is a method, not a talent. Symptom to hypothesis to a test that can only come out one way, changing one thing at a time, and reading the error message you were actually given rather than the one you expected."
deck: "Everything is broken and you have to start somewhere"
track: "linux-plus"
level: "working"
order: 640
objectives:
  - "Turn a vague symptom into a testable hypothesis"
  - "Design a test that distinguishes between two causes"
  - "Read an error message for what it says rather than what it seems to say"
  - "Find what changed on a machine, and when"
  - "Change one thing at a time, and know why that matters"
  - "Decide when to stop investigating and escalate"
prerequisites: ["getting-help-on-any-command", "reading-logs-to-find-a-cause"]
tags: ["linux", "linux-plus", "troubleshooting", "method"]
updated: 2026-08-21
draft: false
examObjectives:
  - exam: "xk0-006"
    domain: "5.0"
    objective: "5.2"
sources:
  - title: "strace(1)"
    url: "https://man7.org/linux/man-pages/man1/strace.1.html"
    publisher: "man7.org"
    accessed: 2026-08-09
    tier: 1
  - title: "execve(2), including ENOENT on a missing interpreter"
    url: "https://man7.org/linux/man-pages/man2/execve.2.html"
    publisher: "man7.org"
    accessed: 2026-08-09
    tier: 1
  - title: "rpm(8)"
    url: "https://man7.org/linux/man-pages/man8/rpm.8.html"
    publisher: "man7.org"
    accessed: 2026-08-09
    tier: 1
  - title: "dnf history"
    url: "https://dnf.readthedocs.io/en/latest/command_ref.html#history-command-label"
    publisher: "DNF"
    accessed: 2026-08-09
    tier: 1
symptoms:
  - symptom: "Error message names a file that plainly exists"
    anchor: "read-the-error-you-were-given"
  - symptom: "Service broke and nobody knows what changed"
    anchor: "what-changed"
  - symptom: "Several fixes applied at once and the problem moved"
    anchor: "one-thing-at-a-time"
---

> **Before you read.** A ticket says "the reporting tool is broken". That is all
> it says. The machine is up, you can log in, and nobody can tell you what
> "broken" means.
>
> You have to start somewhere, and where you start decides whether this takes
> five minutes or the rest of the afternoon.

Most people learn troubleshooting by absorbing it, which works eventually and
takes years. There is a method underneath, and it is small enough to state on
one page: turn the symptom into a guess you can test, design a test that can
only come out one way, change one thing, and write down what you did.

The exam asks about this because it is the skill the other twelve lessons in
this block are in service of. Knowing that `df -i` exists is worth nothing if
you never think to suspect the filesystem.

### Some words you will need

<dl class="terms">
<dt>symptom</dt>
<dd>What somebody noticed. Almost never the fault itself.</dd>
<dt>hypothesis</dt>
<dd>A specific guess about the cause, phrased so it could be wrong.</dd>
<dt>discriminating test</dt>
<dd>An observation whose result rules something in or out. The whole game.</dd>
<dt>bisection</dt>
<dd>Halving the space of possible causes with each test.</dd>
<dt>blast radius</dt>
<dd>What a change can affect if it goes wrong.</dd>
<dt>escalation</dt>
<dd>Handing the problem to somebody with more access or more knowledge.</dd>
</dl>

## What breaks without this

**Fixes get applied at random.** Three changes go in at once, the symptom moves,
and now nobody knows which change did what.

**The wrong layer gets blamed.** Hours go into the application because the
error mentioned the application, when the disk was full.

**The same outage happens twice.** Nothing was written down, so the next person
starts from nothing, including you in six months.

**Nobody escalates in time.** An engineer spends four hours on something the
storage team would have recognised in four minutes.

**Changes make it worse.** A speculative fix breaks something that was working,
and now there are two faults.

## Symptom, hypothesis, test

The loop is three steps and you repeat it until the cause is cornered.

<figure class="learn-figure">
<svg viewBox="0 0 720 250" role="img" aria-labelledby="ts-title ts-desc" style="width:100%;height:auto;">
<title id="ts-title">Symptom to hypothesis to test, and the loop back when the test says no</title>
<desc id="ts-desc">A symptom is what somebody reports, and it describes an experience rather than a fault. Converting it into a hypothesis is the step that carries the difficulty, because a hypothesis has to be specific enough to be wrong: it names a component, a mechanism, and an expected observation. The test then has to be one that can only come out one way, so that either result moves you forward. A test that confirms narrows the cause; a test that refutes sends you back to write a different hypothesis, not to try a different fix.</desc>
<g>
<rect x="24" y="66" width="170" height="66" rx="5" fill="currentColor" fill-opacity="0.07" stroke="currentColor" stroke-opacity="0.32"/>
<text x="109" y="94" text-anchor="middle" font-size="11.5" fill="currentColor">symptom</text>
<text x="109" y="114" text-anchor="middle" font-size="10" fill="currentColor" fill-opacity="0.65">what was reported</text>
<rect x="266" y="66" width="188" height="66" rx="5" fill="var(--accent)" fill-opacity="0.12" stroke="var(--accent)" stroke-opacity="0.9" stroke-width="1.8"/>
<text x="360" y="94" text-anchor="middle" font-size="11.5" fill="var(--accent)">hypothesis</text>
<text x="360" y="114" text-anchor="middle" font-size="10" fill="var(--accent)">must be able to be wrong</text>
<rect x="526" y="66" width="170" height="66" rx="5" fill="currentColor" fill-opacity="0.07" stroke="currentColor" stroke-opacity="0.32"/>
<text x="611" y="94" text-anchor="middle" font-size="11.5" fill="currentColor">test</text>
<text x="611" y="114" text-anchor="middle" font-size="10" fill="currentColor" fill-opacity="0.65">one answer only</text>
<text x="230" y="88" text-anchor="middle" font-size="10" fill="currentColor" fill-opacity="0.65">narrow</text>
<text x="490" y="88" text-anchor="middle" font-size="10" fill="currentColor" fill-opacity="0.65">predict</text>
<text x="340" y="204" text-anchor="end" font-size="10" fill="currentColor" fill-opacity="0.8">refuted, so write a different hypothesis</text>
<text x="611" y="176" text-anchor="middle" font-size="10" fill="currentColor" fill-opacity="0.65">confirmed, so change one thing</text>
</g>
<g stroke="currentColor" stroke-opacity="0.5" fill="none" stroke-width="1.3">
<path d="M196 99 L262 99 M256 95 L263 99 L256 103"/>
<path d="M456 99 L522 99 M516 95 L523 99 L516 103"/>
<path d="M611 134 L611 158 M607 152 L611 159 L615 152"/>
</g>
<g stroke="currentColor" stroke-opacity="0.45" fill="none" stroke-width="1.3" stroke-dasharray="5 3">
<path d="M611 186 L611 216 L360 216 L360 138 M356 145 L360 137 L364 145"/>
</g>
</svg>
<figcaption>The dashed return is the part people skip. A test that refutes the hypothesis has done its job, and the next move is a new hypothesis rather than a new fix. Changing something because the test disappointed you is how a second fault gets added to the first, which is why the change comes only after the loop closes.</figcaption>
</figure>

A symptom is what somebody reports: "the reporting tool is broken", "the site is
slow", "I cannot log in". It is a description of an experience, and it is
usually not a description of a fault. The first job is to convert it into
something specific enough to be wrong about.

That means asking what "broken" means in observable terms. Broken how? For
everybody or one person? Since when? What is the exact error?

**Hypothesis** comes next, and the phrasing matters more than people expect. "It
is a permissions problem" is not a hypothesis, because no observation could
disprove it. "The service cannot write to `/var/lib/reports` because the
directory is owned by root and the service runs as `reports`" is a hypothesis:
one `ls -ld` settles it.

Then the test. A good test is one whose outcome you cannot predict, and where
either outcome tells you something. If you already know what it will say, you
are not testing, you are reassuring yourself.

| Weak | Strong |
| --- | --- |
| "Let me restart it and see" | "Does the process have the file open? `lsof -p`" |
| "Check if it's a network problem" | "Can this host open a TCP connection to port 5432 there? `nc -vz`" |
| "Look at the logs" | "What did this unit log in the ninety seconds before it failed?" |

Restarting deserves its own warning, because it is the most common first move
and it destroys evidence. It often clears the symptom, which feels like success
and teaches you nothing, and the fault returns on Sunday when you are not there.
Collect state first, restart second.

<details class="deeper">
<summary>If you already administer Linux: bisection, and the two directions you can reason in</summary>

The method above is fine for a fault with one plausible cause. When there are
twenty, you need a way to eliminate them faster than one at a time.

**Bisection is the tool, and it applies to more than code.** Split the space in
half, test which half contains the fault, repeat. Twenty candidates become five
tests instead of twenty.

The trick is choosing a split that genuinely halves the space. For a request
failing somewhere between a browser and a database, do not start at the browser.
Start in the middle: can the application host reach the database directly? That
one answer eliminates either everything upstream or everything downstream.

| Space | A good midpoint test |
| --- | --- |
| Client to server, many hops | From the server itself: does `curl localhost` work? |
| A pipeline of five stages | Run stage three by hand with stage two's output |
| A config file with 200 lines | Comment out half, restart, see which half matters |
| A commit range of 400 | `git bisect`, which is literally this |
| Ten hosts, one misbehaving | Compare a broken one against a working one, field by field |

**That last row is the most underused technique in this lesson.** When one
machine misbehaves and nine do not, the difference between them *is* the answer,
and `diff` on two config dumps finds it faster than any amount of reading.

**The two directions of reasoning** are worth naming, because experienced people
switch between them without noticing:

- **Forward, from cause to symptom.** "The disk is full, so writes fail, so the
  service errors." You start from something you observed about the system and
  work out what it would do.
- **Backward, from symptom to cause.** "Writes are failing. What makes a write
  fail? Full disk, read-only mount, permissions, SELinux, quota." You start from
  the symptom and enumerate what could produce it.

Backward reasoning is what to use when you are stuck, because it is systematic
and does not depend on already suspecting the right thing. Its weakness is that
the list can be long. Forward reasoning is faster and needs a hunch, so it is
what experts use and what beginners should not lean on: without the experience,
the hunch is just a guess wearing a lab coat.

**A practical hybrid:** reason backward to build the list of candidate causes,
then order that list by how cheap each is to test rather than by how likely it
seems. A two-second `df -h` that eliminates a whole branch beats a ten-minute
investigation of your favourite theory.

</details>

## Read the error you were given

Error messages are read carelessly, and the ones that mislead do so in a
consistent way: they name the thing the tool was working on, not the thing that
was missing.

Here is a script that exists, is executable, and will not run.

<details class="predict">
<summary>The file is present with mode 755. What does the shell say when it runs, and what is the exit status?</summary>

```bash
# AlmaLinux 10.2, aarch64
$ echo "--- the script is right there, and executable ---"; ls -l report.sh; echo "--- so what does running it say ---"; ./report.sh; echo "exit status: $?"
--- the script is right there, and executable ---
-rwxr-xr-x. 1 root root 36 Aug  9 04:06 report.sh
--- so what does running it say ---
/bin/sh: line 1: ./report.sh: cannot execute: required file not found
exit status: 127
```

</details>

Look carefully at what that says. `./report.sh: cannot execute: required file
not found`. The path it names is `./report.sh`, which `ls` just proved is
there.

The message is accurate and the reading is wrong. The file that was not found is
a different one, and the message does not name it. When you run a script, the
kernel reads the first line, finds the interpreter, and executes *that*. If the
interpreter is missing, the exec fails, and the shell reports the failure
against the file you asked for.

You can watch the kernel say so:

```bash
# AlmaLinux 10.2, aarch64
$ echo "--- ask the kernel which file it could not find ---"; strace -f -e trace=execve ./report.sh 2>&1 | head -4
--- ask the kernel which file it could not find ---
execve("./report.sh", ["./report.sh"], 0xfffffa3f0a88 /* 8 vars */) = -1 ENOENT (No such file or directory)
strace: exec: No such file or directory
+++ exited with 1 +++
```

`ENOENT` on `execve` of a file that exists is the signature. The kernel resolved
the interpreter, failed to find it, and returned the error against the original
call.

<details class="predict">
<summary>Where is the name of the file that is actually missing?</summary>

```bash
# AlmaLinux 10.2, aarch64
$ echo "--- the file the kernel wanted is named on line 1 ---"; head -1 report.sh; echo "--- does it exist ---"; ls -l /bin/bahs 2>&1; echo "--- fix the typo, run it again ---"; sed -i "1s|.*|#!/bin/bash|" report.sh; ./report.sh; echo "exit status: $?"
--- the file the kernel wanted is named on line 1 ---
#!/bin/bahs
--- does it exist ---
ls: cannot access '/bin/bahs': No such file or directory
--- fix the typo, run it again ---
report generated
exit status: 0
```

</details>

`#!/bin/bahs`. One transposition, and the error pointed at the wrong file the
whole time.

**How to read an error message properly**, in the order that pays:

- Read every word, including the ones that look like boilerplate. `cannot
  execute` and `not found` are two different claims and the combination is the
  clue.
- Ask which file, which line, which user, which host. If the message does not
  say, that absence is information.
- Distinguish what the tool observed from what the tool concluded. Tools report
  conclusions confidently and are often reasoning from one layer too high.
- Search the exact string, in quotes, before searching your paraphrase of it.
- If the message is thin, ask something lower down. `strace` for syscalls,
  `ltrace` for library calls, `-v` or `--debug` for the tool's own view.

**Exit status 127 is worth memorising**: command not found, or interpreter not
found. 126 means found but not executable, which is usually a mode bit or a
`noexec` mount. Those two are frequently mistaken for each other.

## What changed

Machines do not spontaneously break. Something changed, and the question is
what.

The awkward part is that the change is often not on the machine. A certificate
expired, a DNS record was updated, a firewall rule was added upstream, a
dependency published a new version, or a disk crossed a threshold that had been
climbing for a month. "Nothing changed" from a colleague means "I did not change
anything", which is a much smaller claim.

Package history is the easiest thing to check and is frequently decisive:

```bash
# AlmaLinux 10.2, aarch64
$ echo "--- what changed on this machine, most recent first ---"; rpm -qa --last | head -5
--- what changed on this machine, most recent first ---
krb5-libs-1.21.3-10.el10_2.aarch64            Tue Jun  2 11:13:49 2026
rootfiles-8.1-54.el10.noarch                  Tue Jun  2 11:12:21 2026
less-661-3.el10.aarch64                       Tue Jun  2 11:12:21 2026
yum-4.20.0-22.el10_2.alma.1.noarch            Tue Jun  2 11:12:20 2026
xz-5.6.2-4.el10_0.aarch64                     Tue Jun  2 11:12:20 2026
```

Everything installed on the same day, which is what a container image looks
like. On a real server this list is a timeline, and a package updated an hour
before the incident is a strong lead.

The places worth checking, roughly in order of how often they pay:

| Question | Command |
| --- | --- |
| What packages changed? | `rpm -qa --last \| head`, `dnf history`, `grep " install \| upgrade " /var/log/dpkg.log` |
| Can I undo it? | `dnf history undo <id>` |
| What config files changed? | `sudo find /etc -mtime -7 -type f` |
| Did the config drift from the package? | `rpm -Va` |
| Who logged in and when? | `last`, `journalctl _COMM=sudo` |
| Did it reboot? | `uptime`, `journalctl --list-boots` |
| Did a certificate expire? | `openssl x509 -enddate -noout -in <cert>` |
| Was something deployed? | Your pipeline's history, per lesson 60 |

**`rpm -Va` deserves more use than it gets.** It verifies every installed file
against the package's recorded checksum, mode, and owner, so it finds the config
somebody edited by hand two years ago and forgot. On Debian the equivalent is
`debsums -c`.

<details class="deeper">
<summary>If you already administer Linux: when nothing changed and it broke anyway</summary>

Sometimes the colleague is right and nothing changed. The machine still broke,
because some failures are scheduled rather than triggered, and time is the
input nobody thinks to check.

These are the ones worth knowing, because each is invisible in every change log
you own:

- **A certificate expired.** The single most common example. It worked for 397
  days and then stopped at a precise second, and nothing in your history shows
  anything. Lesson 48 covers the machinery; here the point is that expiry is a
  scheduled outage somebody set up a year ago.
- **A disk crossed a threshold.** Growth had been linear for months. Nothing
  changed today except that the number reached 100 percent.
- **Log rotation ran.** A daemon lost its file handle at 03:12 because
  `postrotate` did not signal it, exactly as in lesson 68.
- **A token or password expired.** A service account with a 90-day rotation, an
  OAuth refresh token, a Kerberos ticket that stopped renewing.
- **A cron job ran.** Weekly and monthly jobs are the ones that catch people,
  because the correlation is only visible if you happen to look at the right
  day of the month. `systemd-analyze calendar` and `systemctl list-timers` show
  what is scheduled.
- **A cache expired.** DNS TTL, a CDN entry, an application cache. The upstream
  change happened days ago and only became visible when the cached copy aged
  out, which is why the timeline seems to make no sense.
- **A counter wrapped or a clock moved.** 32-bit counters, daylight saving, a
  leap second, an NTP step. Rare, and unmistakable when you see it.
- **Load reached a limit.** File descriptors, PIDs, connection pools, inode
  count. Nothing changed except traffic, and a limit that was always there
  finally mattered.

**The tell for all of them is a precise time with no deploy near it.** When the
timeline shows a clean break at 02:00:00 and nobody was awake, stop looking for
a person and start looking for a schedule or an expiry.

**Two commands that pay for themselves here:**

```bash
systemctl list-timers --all          # what is scheduled and when it next runs
sudo find /etc -name '*.crt' -o -name '*.pem' | \
  xargs -I{} sh -c 'echo -n "{} "; openssl x509 -enddate -noout -in {} 2>/dev/null'
```

The second one is worth running on a quiet afternoon rather than during an
incident, which is the general lesson: the cheapest time to discover a
scheduled failure is before it is scheduled to happen.

</details>

## One thing at a time

This is the rule people know and break, and the reason it matters is not
tidiness.

Change three things, and if the symptom clears you have learned nothing about
which mattered. Worse, if one of your three changes introduced a new fault while
another fixed the original, the symptom persists and you now have two problems
tangled together with no way to separate them.

So: one change, then observe, then keep or revert. Write down each one as you
go, because after ninety minutes you will not remember whether you reverted the
`sysctl` or only meant to.

**Before any change, ask three questions.** How do I undo this? What else could
it affect? Is this reversible at all? A `chmod -R` on the wrong directory, a
`truncate` on the wrong file, and a `dd` with the arguments swapped are not
reversible, and no amount of care afterwards helps.

Keep the original when you edit config:

```bash
sudo cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.$(date +%F)
```

Then validate before restarting, because most services will tell you whether
they can parse the file: `nginx -t`, `sshd -t`, `visudo -c`, `named-checkconf`.
Restarting into a broken config on a remote machine is a memorable way to end an
afternoon.

<details class="deeper">
<summary>If you already administer Linux: not locking yourself out, and knowing when to stop</summary>

Two failure modes cost more than any wrong diagnosis: cutting off your own
access, and continuing alone past the point where somebody else would be faster.

**Keep a second way in before touching anything that could remove the first.**
Firewall rules, SSH configuration, PAM, network configuration, and SELinux
enforcement can all end your session permanently.

- **Open a second SSH session and leave it idle.** If the change breaks
  authentication, the existing connection usually survives, and it is the only
  way back.
- **Use a timer as a dead man's switch** before a risky network or firewall
  change:

  ```bash
  sudo sh -c 'sleep 300 && systemctl restart NetworkManager' &
  ```

  If you lock yourself out, the machine repairs itself in five minutes. If it
  worked, kill the timer.
- **`firewall-cmd --timeout=`** does this natively for firewalld rules: they
  expire unless you make them permanent.
- **Know where the console is.** Cloud serial console, IPMI, or the hypervisor's
  console. Find out before you need it, not after.

**On escalation**, which is a judgement rather than an admission. Escalate when
any of these is true:

- You have been going for a fixed period with no progress. Decide the number in
  advance, thirty or sixty minutes, because in the moment you will always feel
  one more idea away.
- The next step needs access or authority you do not have.
- The blast radius of the fix exceeds what you are comfortable owning.
- It is a system somebody else built and you are reasoning from first principles
  about their design decisions.
- Customer impact is ongoing and mitigation matters more than diagnosis. Fail
  over first, understand afterwards.

**Escalating well is a skill in itself**, and a good handover is worth more than
another hour of solo work. Give the symptom with its exact error text, the
timeline, what you have ruled out **and how**, what you changed, and what you
think is happening. The "and how" is the part people leave out, and it is what
stops the next person repeating your first twenty minutes.

**Write it down while it is happening**, not afterwards. A running note of
commands and their results costs nothing during the incident and becomes the
postmortem, the runbook, and the answer when it recurs. Even
`script /tmp/incident.log` at the start of the session is better than memory.

</details>

## Across distributions

The method is identical everywhere, because it is a way of thinking rather than
a toolset. What moves is where the evidence is kept.

| | RHEL family | Debian family |
| --- | --- | --- |
| Authentication failures | `/var/log/secure` | `/var/log/auth.log` |
| General text log | `/var/log/messages` | `/var/log/syslog` |
| The journal | `journalctl`, identical | `journalctl`, identical |
| Which package owns a file | `rpm -qf <path>` | `dpkg -S <path>` |
| Has a package's file been altered | `rpm -V <pkg>`, always available | `debsums <pkg>`, **rarely installed** |
| Recent package activity | `rpm -qa --last` | `/var/log/dpkg.log` |
| Mandatory access control | SELinux, `ausearch -m AVC` | AppArmor, `journalctl -k` |

**The journal is the portable answer**, which is the practical reason to reach
for `journalctl -u` before hunting for a file. It is the same command, with the
same options, on every systemd machine, and it does not care what the
distribution decided to call `/var/log/messages`.

The `rpm -V` row is the one that repays knowing. On the RHEL family you can ask
"has anything about this package changed since it was installed" and get a
per-file answer covering mode, ownership, and checksum, which turns "what
changed" from an interview question into a command. The Debian equivalent needs
`debsums` installed ahead of time, and on a machine you have just been handed it
will not be.

## Prove it

Collect before you change. This is the whole of it, and it takes under a minute:

```bash
# The exact error, from the machine rather than from the person reporting it
journalctl -u <unit> -p err -b --no-pager | tail -20

# What changed, and when
rpm -qa --last | head            # Debian: tail /var/log/dpkg.log
systemctl list-units --failed
uptime                           # has it restarted since it last worked

# The four cheap eliminations, before any theory at all
df -h; df -i                     # space, and inodes separately
free -h
ss -ltnp | head                  # is it even listening
id <the service account>         # is it running as who you think
```

**Run this before restarting anything.** A restart frequently clears the symptom
and always destroys the state that would have explained it, so the fault comes
back on a Sunday with nothing left to read. Ninety seconds of collection buys you
the ability to diagnose it the second time.

## What trips people up

### 1. Restarting first

It is the most common opening move and it is evidence destruction. The process
table, the open file handles, the memory usage, and anything the service was
about to log all go away. If the restart works you have learned nothing, and you
will be back.

### 2. "It is a permissions problem"

That is a hunch, not a hypothesis, because no observation could disprove it. A
hypothesis names a specific thing that a single command settles: the service runs
as `reports` and `/var/lib/reports` is owned by `root`, so `ls -ld` decides it in
one line.

### 3. Changing two things at once

Then it works and you cannot say why, so you cannot write it down, tell anybody,
or recognise it next time. Worse, one of the two changes may have introduced a
fault that surfaces next week looking unrelated.

### 4. Treating the reporter's diagnosis as the symptom

"The database is down" is almost always someone's conclusion rather than their
observation. What they saw was an error in an application. Ask what they typed
and what appeared, because the conclusion has already thrown away the useful
part.

### 5. Reading the last error instead of the first

A failure cascades, so the end of the log is full of consequences. The first
error in the sequence is the one with the cause in it, and everything after it is
noise generated by the thing that already went wrong.

### 6. Never asking what changed

Systems that ran for a year do not spontaneously develop faults. Something
changed: a package, a certificate expiring on its own schedule, a disk filling, a
group membership. "What changed" is the highest-yield question in the topic and
it is the one most often skipped, because the answer is usually "nothing" and
that answer is usually wrong.

## Work it through

Putting the pieces together on the fault above, as it would actually go.

The report says the reporting tool is broken. First question: what does broken
mean? The answer is that running it prints an error. Ask for the exact text and
you get `./report.sh: cannot execute: required file not found`.

That message suggests a missing file, so the first hypothesis is the obvious
one: the script is gone. `ls -l report.sh` shows it present and executable.
Hypothesis dead in one command, which is exactly what a good test does.

Second hypothesis: the message means a different file. That gives a
discriminating test, because if some *other* file is missing, the kernel knows
which. `strace -e trace=execve` shows `ENOENT` against a path that exists,
which only happens when the interpreter cannot be resolved.

Third: the interpreter named in the script is wrong. `head -1` shows
`#!/bin/bahs`, and `ls /bin/bahs` confirms it does not exist. One change, one
character, and it runs.

Four commands, no restart, and the fix was the last thing done rather than the
first. Note that the middle step is what beginners skip: when the obvious
reading of an error turned out to be wrong, the next move was to ask a lower
layer rather than to guess again.

## Try it

Optional, and worth doing on a VM you can restore, because the point is to break
something on purpose and practise the loop rather than the fix.

1. Break a service in a way you will forget. Pick one that is running, then do
   exactly one of these without writing it down: rename its binary, change the
   user in its unit file, revoke read on its config, or fill the filesystem its
   working directory sits on. Walk away for ten minutes.
2. Come back and treat it as a report. Write the symptom in observable terms
   before typing anything, then run the collection block from **Prove it** and
   read it before forming a theory.
3. Write your hypothesis down as a sentence containing a path, a user, or a
   number. If you cannot, it is still a hunch.
4. Test it with one command whose answer you cannot predict, then fix exactly one
   thing.

**Verification step.** You have done this properly when you can state, without
looking, which single command eliminated the largest number of candidate causes.
If your answer is "the one that fixed it", the diagnosis was luck, so restore the
snapshot and run it again with a different fault.

Do it a second time with two faults introduced at once. That version teaches the
lesson about changing one thing at a time faster than reading about it does.

## For the exam

**Symptom, hypothesis, test.** Convert a report into something specific enough
to be wrong about.

**A good test discriminates.** If you know the answer already, it is not a test.

**Change one thing at a time**, and record each change.

**Establish what changed** before assuming the machine changed itself.

**Read the exact error text.** It may name the wrong file, and 127 means
"command or interpreter not found".

**Collect evidence before restarting.** Restarting destroys the state that would
have explained it.

**Have a way back in** before touching SSH, firewall, or network configuration.

**Escalate on a clock**, on access limits, or on blast radius.

<details class="qa">
<summary>Check yourself</summary>

**A ticket says "the site is slow". What is your first move?**
Turn it into something testable. Slow for whom, since when, which page, and how
slow compared to what. A symptom is not a fault.

**Why is "it is a permissions problem" a poor hypothesis?**
Nothing could disprove it. A hypothesis has to name something specific enough
that one command settles it.

**You can restart the service and it will probably clear the symptom. Why
wait?**
Restarting destroys the evidence that would explain the fault, and the fault
returns later when you are not watching.

**A script exists and is executable, and running it says the file is not found.
What is happening?**
The interpreter on the shebang line is missing. The error names the script
because that is what was passed to `execve`.

**What do exit statuses 126 and 127 mean?**
127 is command or interpreter not found. 126 is found but not executable,
typically a mode bit or a `noexec` mount.

**Which command shows what the kernel could not find?**
`strace -e trace=execve`, which shows `ENOENT` against the exec call.

**Name three ways to find what recently changed.**
`rpm -qa --last` or `dnf history`, `find /etc -mtime -7`, and `last` or the
journal for who logged in. Certificates and upstream changes count too.

**What does `rpm -Va` do that a package list does not?**
Verifies installed files against the package's recorded checksums, modes, and
owners, so it finds files edited by hand.

**Why change one thing at a time?**
Otherwise a fix and a new fault can cancel out, or you cannot tell which change
mattered.

**Three questions before making any change?**
How do I undo it, what else could it affect, and is it reversible at all.

**You are about to change firewall rules on a remote host. What first?**
Keep a second session open, and set a timer that reverts or restarts networking
if you lose access. `firewall-cmd --timeout=` does this natively.

**When should you escalate?**
On a predetermined clock with no progress, when the next step needs access you
lack, when the blast radius exceeds what you should own, or when mitigation
matters more than diagnosis.

**What belongs in a handover?**
The exact error, the timeline, what you ruled out and how you ruled it out, what
you changed, and your current theory.

**Nine machines are fine and one is not. What is the fastest technique?**
Compare a broken one against a working one field by field. The difference is
the answer.

</details>

## Where this sits

This lesson is the method; the rest of block F is the specific knowledge it
operates on. Lesson 65 is where the evidence lives, and the lessons after it
work through the layers in turn: boot, filesystems, disk space, services,
hardware, network, permissions, and performance.

The next lesson is about noticing a fault before a customer does, which is the
only thing better than diagnosing one quickly.


## References

- [strace(1)](https://man7.org/linux/man-pages/man1/strace.1.html) - man7.org. Accessed 2026-08-09.
- [execve(2), including ENOENT on a missing interpreter](https://man7.org/linux/man-pages/man2/execve.2.html) - man7.org. Accessed 2026-08-09.
- [rpm(8)](https://man7.org/linux/man-pages/man8/rpm.8.html) - man7.org. Accessed 2026-08-09.
- [dnf history](https://dnf.readthedocs.io/en/latest/command_ref.html#history-command-label) - DNF. Accessed 2026-08-09.
**If the fault is live and people are asking.** This topic is a method for
finding a cause. [The hour after it breaks](/learn/network-plus/the-hour-after-it-breaks)
on the Network+ track is everything happening around you while you use it: who
runs the incident, what to say before you know anything, and why a postmortem
that names a person has found nothing. It is written for a network fault and
none of it is about networks.

> **The commands here were run on a real machine, not written from memory.** The
> transcripts come from AlmaLinux 10.2 on aarch64, run natively so the shell's
> own error text is the one you would see. `report.sh` really did carry
> `#!/bin/bahs`, and the error really did name the script rather than the
> interpreter. The package list is from a container image, which is why every
> package shares an install date; on a server that column is a timeline.
