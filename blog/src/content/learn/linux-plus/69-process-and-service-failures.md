---
title: "The service says active and the application is down"
description: "systemd knows whether it started a process. It does not know whether that process is doing its job, and the gap between those two facts is where a whole category of outage lives. Reading a failed unit, a restart loop, and an exit code that names its own cause."
track: "linux-plus"
level: "working"
order: 700
objectives:
  - "Read systemctl status and say which part is the diagnosis"
  - "Explain why is-active can report a service that has never once started"
  - "Decode a systemd exit code, including the 200 range"
  - "Recognise a restart loop and the start limit that ends it"
  - "Explain what an exit status above 128 means"
  - "Distinguish a process that is running from a service that is working"
prerequisites: ["systemd-units-and-services", "processes-and-signals"]
tags: ["linux", "linux-plus", "troubleshooting", "systemd", "processes"]
updated: 2026-08-09
draft: false
examObjectives:
  - exam: "xk0-006"
    domain: "5.0"
    objective: "5.2"
sources:
  - title: "systemctl(1)"
    url: "https://www.freedesktop.org/software/systemd/man/latest/systemctl.html"
    publisher: "freedesktop.org"
    accessed: 2026-08-09
    tier: 1
  - title: "systemd.service(5)"
    url: "https://www.freedesktop.org/software/systemd/man/latest/systemd.service.html"
    publisher: "freedesktop.org"
    accessed: 2026-08-09
    tier: 1
  - title: "systemd.exec(5), process exit codes"
    url: "https://www.freedesktop.org/software/systemd/man/latest/systemd.exec.html#Process%20Exit%20Codes"
    publisher: "freedesktop.org"
    accessed: 2026-08-09
    tier: 1
  - title: "signal(7)"
    url: "https://man7.org/linux/man-pages/man7/signal.7.html"
    publisher: "man7.org"
    accessed: 2026-08-09
    tier: 1
symptoms:
  - symptom: "systemctl is-active reports active but the application is unreachable"
    anchor: "active-is-not-the-same-as-working"
  - symptom: "Service restarts repeatedly and then stops trying"
    anchor: "the-restart-loop-and-where-it-ends"
  - symptom: "Unit fails immediately with status 203"
    anchor: "the-exit-code-usually-is-the-answer"
---

> **Before you read.** The monitoring says the order API is down. You SSH in and
> run `systemctl is-active order-api`. It prints `active`. You run it again. Still
> `active`. The application is definitely down, and the init system is definitely
> telling you it is up.
>
> **Neither of you is lying.** systemd is answering a narrower question than the
> one you asked.

This lesson is about the distance between "a process exists" and "the service
works", because most service troubleshooting is spent in that gap. The tools
will tell you which side of it you are on, but only if you read past the first
line of output.

### Some words you will need

<dl class="terms">
<dt>unit</dt>
<dd>Anything systemd manages. A service is one kind of unit.</dd>
<dt>ActiveState</dt>
<dd>systemd's high-level view: active, inactive, failed, activating, deactivating.</dd>
<dt>SubState</dt>
<dd>The detail underneath it: running, exited, dead, auto-restart, start-pre.</dd>
<dt>main PID</dt>
<dd>The process systemd considers to be the service. Its exit ends the service.</dd>
<dt>exit code</dt>
<dd>The number a process returns. 0 is success; systemd reserves 200 and up for its own failures.</dd>
<dt>restart loop</dt>
<dd>A service that keeps failing and being restarted by its <code>Restart=</code> policy.</dd>
<dt>start limit</dt>
<dd>How many restarts in a window systemd will tolerate before giving up.</dd>
<dt>core dump</dt>
<dd>A snapshot of a crashed process's memory, written for later analysis.</dd>
</dl>

## What breaks without this

**You trust a green check that means nothing.** A dashboard polling
`systemctl is-active` reports healthy for a service that has never once
successfully started.

**You restart instead of diagnosing.** Restarting clears the symptom often
enough to feel like a fix, so the actual cause is never found and the outage
returns.

**The error is on screen and gets skipped.** systemd usually prints the exact
reason in `status`, four lines down, and people read the first line and stop.

**A dependency failure is chased in the wrong service.** The unit that failed is
frequently not the unit with the problem.

**A crash loop is mistaken for a healthy service**, because between restarts it
genuinely is running.

## The exit code usually is the answer

Start with a unit that cannot possibly work, because seeing the clean case
makes the messy ones readable. This one points at a binary that does not exist:

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ sudo tee /etc/systemd/system/billing.service >/dev/null <<EOF
[Unit]
Description=Billing exporter

[Service]
Type=simple
ExecStart=/usr/local/bin/billing-export
Restart=on-failure
RestartSec=2
EOF
sudo systemctl daemon-reload; sudo systemctl start billing.service 2>&1; echo "--- what did that do ---"; systemctl is-active billing.service
--- what did that do ---
active
```

**`systemctl start` printed no error and `is-active` says `active`.** The binary
does not exist. Nothing has ever run. This is the whole problem in five lines.

`status` tells the truth, and the useful part is not at the top:

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ systemctl status billing.service --no-pager 2>&1 | head -12
● billing.service - Billing exporter
     Loaded: loaded (/etc/systemd/system/billing.service; static)
    Drop-In: /usr/lib/systemd/system/service.d
             └─10-timeout-abort.conf
     Active: activating (auto-restart) (Result: exit-code) since Sat 2026-08-08 22:13:05 CDT; 274ms ago
 Invocation: c635874ff7924afb879862cdbe99cda1
    Process: 584700 ExecStart=/usr/local/bin/billing-export (code=exited, status=203/EXEC)
   Main PID: 584700 (code=exited, status=203/EXEC)
   Mem peak: 1.2M
        CPU: 2ms

Aug 08 22:13:05 localhost.localdomain systemd[1]: billing.service: Main process exited, code=exited, status=203/EXEC
```

**Read it in this order**, because the first line is the least informative:

| Line | Says |
| --- | --- |
| `Loaded:` | The unit file was found and parsed. A problem here is a typo or a missing file |
| `Active:` | `activating (auto-restart)`, and `(Result: exit-code)`. It is looping, and it is looping because something exited badly |
| `Process:` | The command that ran and what it returned. **This is the diagnosis** |
| `Main PID:` | Same, for the process systemd was tracking |
| The log lines | The journal tail for this unit, free of charge |

**`status=203/EXEC` is the answer.** systemd reserves exit codes from 200 up for
its own failures, and it names them:

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ echo "--- the exit code is the whole diagnosis ---"; systemd-analyze exit-status 203 2>&1 | head -8
--- the exit code is the whole diagnosis ---
NAME STATUS CLASS
EXEC    203 systemd
```

`EXEC` means systemd could not execute the command at all. The binary is
missing, is not executable, or its interpreter line points at nothing.

**The systemd exit codes worth recognising on sight:**

| Code | Name | Almost always means |
| --- | --- | --- |
| `200` | `EXIT_CHDIR` | `WorkingDirectory=` does not exist |
| `203` | `EXIT_EXEC` | Binary missing, not executable, or bad shebang |
| `205` | `EXIT_MEMORY` | Out of memory during setup |
| `208` | `EXIT_STDERR` | Could not set up output redirection |
| `209` | `EXIT_CHROOT` | `RootDirectory=` is wrong |
| `216` | `EXIT_GROUP` | `Group=` does not exist |
| `217` | `EXIT_USER` | `User=` does not exist |
| `226` | `EXIT_NAMESPACE` | A sandboxing directive could not be applied |
| `1` | (the program's own) | The application ran and chose to fail. Read its logs |

**The distinction that matters:** a code in the 200s means the service never
started, so the problem is in the unit file or the filesystem, and the
application's own logs will be empty. A code of 1 means the application ran and
failed on its own terms, so its logs are exactly where to look. Knowing which
of those you have saves a great deal of time.

## The restart loop and where it ends

`Restart=on-failure` is in that unit, which is why `Active:` said
`activating (auto-restart)` rather than `failed`.

<details class="predict">
<summary>The service has been failing every two seconds. Twenty seconds later, what does <code>is-active</code> report, and what is in the journal?</summary>

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ sleep 20; echo "--- twenty seconds later, the loop has given up ---"; systemctl is-active billing.service; systemctl status billing.service --no-pager 2>&1 | sed -n "5p;7p"; echo "--- and the journal says why it stopped trying ---"; journalctl -u billing.service -n 3 --no-pager -o cat
--- twenty seconds later, the loop has given up ---
activating
     Active: activating (auto-restart) (Result: exit-code) since Sat 2026-08-08 22:13:40 CDT; 1s ago
    Process: 585562 ExecStart=/usr/local/bin/billing-export (code=exited, status=203/EXEC)
--- and the journal says why it stopped trying ---
billing.service: Failed at step EXEC spawning /usr/local/bin/billing-export: No such file or directory
billing.service: Main process exited, code=exited, status=203/EXEC
billing.service: Failed with result 'exit-code'.
```

</details>

**Twenty seconds and hundreds of failed starts later, `is-active` still says
`activating`.** Not `failed`. A monitoring check that treats anything other
than the literal string `failed` as healthy will never fire on this.

**And the first journal line is the plain-English version of 203:**
`Failed at step EXEC spawning /usr/local/bin/billing-export: No such file or
directory`. That is the whole investigation, and it was one command away the
entire time.

**A restart loop does eventually stop.** `StartLimitBurst=` (5 by default) within
`StartLimitIntervalSec=` (10 seconds) is the budget; exceed it and the unit
enters `failed` with "start request repeated too quickly", and systemd will not
try again until you `systemctl reset-failed`. Whether you see that or a loop
that continues depends on how `RestartSec=` compares to the interval: a
two-second delay spaces the attempts widely enough that the burst counter keeps
resetting, which is exactly what happened above.

**Which is worth knowing as a design point, not just a diagnostic one.** A
service that retries slowly enough never trips its own limit, so it will loop
until somebody notices. That may be what you want for a service waiting on a
database, and it is not what you want for one with a typo in its unit file.

<details class="deeper">
<summary>If you already administer Linux: what "active" actually asserts, and why Type= decides it</summary>

The reason `is-active` can be so misleading is that `Type=` changes what
systemd is even measuring, and most people set it once by copying an example.

| `Type=` | systemd considers the service started when | Failure mode |
| --- | --- | --- |
| `simple` (default) | It has **forked**. Not when the process is ready, not when it has bound a port | Anything depending on it starts too early |
| `exec` | The `execve()` succeeded | Catches 203 at start time, still says nothing about readiness |
| `forking` | The parent exits and the daemon has forked into the background | Wrong `PIDFile=` means systemd tracks the wrong process forever |
| `oneshot` | The process has **exited**. `RemainAfterExit=yes` keeps it "active" afterwards | An "active" unit with nothing running at all, by design |
| `notify` | The process **tells** systemd it is ready, via `sd_notify()` | The only type that means what people assume "active" means |
| `dbus` | It has acquired its bus name | Bus-dependent |

**`Type=simple` is the default and it asserts almost nothing.** systemd forked,
the fork succeeded, so the service is active. Whether the process then died
half a second later is a separate question that `is-active` will answer
correctly only after it notices.

**`Type=notify` is the one to want.** The service explicitly signals readiness,
so `systemctl start` blocks until the service is genuinely up, and `After=`
ordering finally means what it looks like it means. Most modern daemons support
it: nginx, PostgreSQL, and systemd's own units all do.

**`Type=oneshot` with `RemainAfterExit=yes` is the honest liar.** The unit is
reported active forever after a script ran once and exited. That is correct and
intended, for things like applying sysctl settings, and it is deeply confusing
if you assume active means a process exists.

**So the practical rules:**

- `systemctl is-active` answers "did systemd's start job succeed", not "is the
  service working". They are different questions.
- For monitoring, check the thing the service is meant to do. A TCP connect, an
  HTTP request to a health endpoint, a query. Not the init system's opinion.
- `systemctl is-failed` is a better alert signal than the absence of
  `is-active`, because it distinguishes failed from activating.
- `systemctl show <unit> -p ActiveState -p SubState -p NRestarts` is the
  scriptable form and gives all three facts without parsing `status` output.
  `NRestarts` climbing is the crash-loop signal.

</details>

## Active is not the same as working

Here is the version of the problem that costs real time: the unit is genuinely
running, systemd is genuinely correct, and the service is genuinely down.

<details class="predict">
<summary>A unit starts a process that prints a line and then sleeps for 900 seconds. It never binds a port. What does systemd report about it, and what is listening on 9090?</summary>

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ sudo systemctl stop billing.service >/dev/null 2>&1; sudo rm -f /etc/systemd/system/billing.service; sudo tee /etc/systemd/system/api.service >/dev/null <<EOF
[Unit]
Description=Order API

[Service]
ExecStart=/bin/sh -c "echo starting the order API; exec sleep 900"
EOF
sudo systemctl daemon-reload; sudo systemctl start api.service; sleep 1; echo "--- systemd is perfectly happy ---"; systemctl show api.service -p ActiveState -p SubState -p MainPID; echo "--- and nothing is serving port 9090 ---"; ss -ltn "sport = :9090"
--- systemd is perfectly happy ---
ActiveState=active
SubState=running
MainPID=586422
--- and nothing is serving port 9090 ---
State Recv-Q Send-Q Local Address:Port Peer Address:Port
```

</details>

**`active`, `running`, a real main PID, and nothing listening.** `ss` printed
its header and no rows, which is what "no socket matches" looks like.

There is no bug here. A process is running, exactly as systemd reports. It is
simply not doing the job the service exists to do, and **the init system has no
way to know that.** In the real world this is a daemon that started, failed to
read its config, logged a complaint, and sat there; or one that crashed a worker
thread while its supervisor kept breathing.

**So the diagnostic move is to stop asking systemd and ask the service:**

| Question | Command |
| --- | --- |
| Is it listening where it should be? | `ss -ltnp 'sport = :9090'` |
| Does it answer? | `curl -sS -o /dev/null -w '%{http_code}\n' localhost:9090/health` |
| What has it said recently? | `journalctl -u api.service -n 50 --no-pager` |
| Is the process actually alive? | `ps -p "$(systemctl show -P MainPID api.service)" -o pid,stat,etime,cmd` |
| Is it stuck rather than working? | `cat /proc/<pid>/status \| grep State` |

**`ss -ltnp` is the single most valuable of those** for a network service,
because "is it listening" is the closest thing to a binary answer you will get,
and if it is listening on `127.0.0.1` when it should be on `0.0.0.0` you have
found the bug outright.

<details class="deeper">
<summary>If you already administer Linux: process states, and telling stuck from busy</summary>

When a process is alive and doing nothing useful, its state code says a
surprising amount. `ps -o stat` and `/proc/<pid>/status` both report it.

| State | Means | What it suggests |
| --- | --- | --- |
| `R` | Running or runnable | Genuinely working, or spinning. Check CPU time |
| `S` | Interruptible sleep | Waiting on something normal: a socket, a timer. The healthy idle state |
| `D` | **Uninterruptible sleep** | Blocked in the kernel, nearly always on I/O. Cannot be killed, not even with `-9` |
| `Z` | Zombie | Exited; the parent has not reaped it. Harmless individually, a parent bug in bulk |
| `T` | Stopped | Suspended by `SIGSTOP`, or being traced |
| `I` | Idle kernel thread | Ignore it |

**`D` state is the one that matters most**, and it is the answer to "why will
`kill -9` not work". A process in uninterruptible sleep is inside a syscall the
kernel will not abandon, so signals are not delivered until it returns. Many
processes in `D` at once means storage: a hung NFS mount, a failing disk, a
saturated device. That is a hardware or network problem wearing a process
costume, and lesson 76 is where it leads.

Zombies are widely misunderstood. A zombie holds no memory and no descriptors;
it is an entry in the process table keeping an exit status until somebody
calls `wait()`. One is nothing. Thousands means the parent is not reaping, and
the fix is to restart the parent, never to try to kill the zombie, which is
already dead.

Distinguishing stuck from busy without guessing:

```bash
cat /proc/<pid>/wchan; echo        # the kernel function it is sleeping in
sudo cat /proc/<pid>/stack         # kernel stack, if available
ps -o pid,stat,wchan:30,etime,time,cmd -p <pid>
```

`etime` against `time` is the quick discriminator: elapsed time far exceeding
CPU time means it is waiting, not computing. The reverse means it is spinning.

**`strace -p <pid>` shows what it is asking the kernel for.** A process
repeatedly failing the same syscall, or blocked in one `read()` forever, tells
you the answer immediately. It has real overhead and should not be left running
on a busy production process, but a few seconds is usually enough.

**And `kill` is worth being precise about**, since it comes up constantly:

- `SIGTERM` (15, the default) asks politely and can be handled. Always first.
- `SIGHUP` (1) conventionally means reload configuration, not exit.
- `SIGKILL` (9) cannot be caught or ignored, so buffers are not flushed and
  temporary files are not cleaned up. It is a last resort, not a habit.
- Nothing kills a `D`-state process, including `SIGKILL`. Fix the I/O.

</details>

## When a process is killed by a signal

The other way a service dies is that something kills it, and the exit status
records which signal did it.

```bash
# AlmaLinux 10.2, aarch64
$ echo "--- a process killed by a signal, and what the shell reports ---"; sh -c "kill -SEGV \$\$"; echo "exit status: $?"; echo "--- which signal is 11 ---"; kill -l 11
--- a process killed by a signal, and what the shell reports ---
/bin/sh: line 1:     2 Segmentation fault      (core dumped) sh -c "kill -SEGV \$\$"
exit status: 139
--- which signal is 11 ---
SEGV
```

**139 is 128 plus 11**, and 11 is `SIGSEGV`. That arithmetic is the convention:
**a status above 128 means the process was killed by signal (status minus
128).**

| Status | Signal | Means |
| --- | --- | --- |
| `137` | 9, `SIGKILL` | Killed outright. Very often the OOM killer, per lesson 75 |
| `139` | 11, `SIGSEGV` | Segmentation fault. A bug in the program, or bad memory |
| `143` | 15, `SIGTERM` | Asked to stop. Usually normal shutdown |
| `134` | 6, `SIGABRT` | The program aborted itself, typically a failed assertion |
| `141` | 13, `SIGPIPE` | Wrote to a closed pipe. Common and usually benign |

`137` deserves special attention because it looks like a crash and usually is
not: it is most often the kernel's out-of-memory killer choosing your process.
`journalctl -k | grep -i 'killed process'` confirms it in one command, and the
fix is a memory problem, not an application bug.

In `systemctl status` this appears as `code=killed, signal=SEGV` rather than
`code=exited`, and that distinction is worth reading carefully: `exited` means
the program chose its fate, `killed` means something else chose it.

<details class="deeper">
<summary>If you already administer Linux: core dumps, and getting something useful out of a crash</summary>

A segfault that happens once is noise. One that happens every twenty minutes is
worth actually investigating, and the machinery is better than most people
expect.

**`systemd-coredump` catches them by default** on most modern distributions,
storing dumps under `/var/lib/systemd/coredump` with metadata in the journal:

```bash
coredumpctl list                     # every crash the system has recorded
coredumpctl info 12345               # signal, command line, and a stack trace if symbols allow
coredumpctl debug 12345              # open it in gdb
coredumpctl dump 12345 > core.dump   # extract the raw dump
```

`coredumpctl info` alone frequently identifies the culprit, because it prints
the backtrace with whatever symbols are available. Installing the matching
`-debuginfo` package turns a stack of addresses into function names, and on
RHEL-family systems `debuginfod` can fetch them on demand.

**If no dump was written, work through these in order:**

- **`ulimit -c`** is zero by default in many shells. For a service, set
  `LimitCORE=infinity` in the unit rather than fighting the shell.
- **`/proc/sys/kernel/core_pattern`** must point at `systemd-coredump`. If
  something else has overwritten it, dumps go somewhere you are not looking.
- **`Storage=` in `/etc/systemd/coredump.conf`** can be `none`.
- **Setuid processes do not dump by default**, controlled by
  `fs.suid_dumpable`. There is a good reason for that: a dump contains memory,
  and memory contains secrets.

Which is the real caution. A core dump of a web server may contain session
tokens, private keys, and customer data in plain text. It is a sensitive
artefact, it lands in a path that is probably not encrypted, and `coredumpctl`
retains it until it ages out. Treat dumps from production the way you would
treat a database export, and be deliberate about who can read
`/var/lib/systemd/coredump`.

And for a crash you cannot reproduce, the journal metadata is often enough
without any dump at all: `coredumpctl list` gives you the timestamp, the
signal, the executable and its command line. Correlated against a deployment
or a traffic spike, that is frequently the answer.

</details>

## Dependencies, and the unit that is not the problem

A failing unit is often collateral damage.

```bash
systemctl list-dependencies app.service          # what it needs
systemctl list-dependencies --reverse app.service # what needs it
systemctl --failed                                # everything currently failed
journalctl -b -p err                              # this boot, errors and worse
```

**`systemctl --failed` first, always.** If three units are failed, they are
probably not three problems: they are one problem and two consequences. Fix the
one whose failure is earliest in the journal.

**The ordering directives that produce this:**

| Directive | Effect |
| --- | --- |
| `Requires=` | If that unit fails, this one is stopped too. Hard dependency |
| `Wants=` | Start it too, but carry on if it fails. The usual choice |
| `After=` / `Before=` | **Ordering only.** No dependency at all |
| `BindsTo=` | Like `Requires=`, and also stops if the other stops for any reason |

**`After=` does not require anything and `Requires=` does not order anything.**
That is the single most common misunderstanding in unit files. `Requires=db.service`
without `After=db.service` starts both at once and your service races the
database. Nearly always you want both, and nearly always the pair is what the
vendor's unit already has.

**And a dependency being started is not a dependency being ready**, which is the
`Type=` problem from earlier viewed from the other side. With `Type=simple` on
the database, `After=` waits for a fork and nothing more. The robust answer is
for the application to retry its connection, exactly as lesson 61 argued for
containers.

## The order to work in

1. **`systemctl --failed`** to see the whole picture before fixating on one unit.
2. **`systemctl status <unit>`** and read down to `Process:` and the log lines.
   The answer is usually there.
3. **Decode the exit code.** 200s mean it never started, so look at the unit
   file. Anything else means it ran, so look at its logs.
4. **`journalctl -u <unit> -b --no-pager`** for the full story rather than the
   ten-line tail.
5. **If it claims to be active, verify independently.** `ss -ltnp`, a `curl`, a
   query. Do not accept the init system's word for it.
6. **Check what it depends on** before assuming the fault is here.
7. **`systemctl cat <unit>`** to see the unit file and every drop-in that
   modifies it, which is where a surprising number of causes hide.

## For the exam

**`systemctl status` shows the failing command and its exit code** in the
`Process:` line. That is the diagnosis, not the first line.

**Exit codes 200 and up are systemd's**, meaning the service never started.
`203/EXEC` is a missing or non-executable binary.

**Exit status above 128 means killed by a signal**, status minus 128. 137 is
`SIGKILL`, 139 is `SIGSEGV`, 143 is `SIGTERM`.

**`active` does not mean working.** With `Type=simple` it means systemd forked
successfully, nothing more.

**A unit in a restart loop reports `activating (auto-restart)`, not `failed`.**

**`systemctl --failed`** lists everything currently failed.

**`journalctl -u <unit>`** is where the reason lives.

**`Requires=` is dependency, `After=` is ordering.** They are independent and
you usually need both.

**A `D`-state process cannot be killed**, not even with `-9`. It is blocked on
I/O.

<details class="qa">
<summary>Check yourself</summary>

**`systemctl is-active` says `active` and the application is unreachable. Is
systemd wrong?**
No. With `Type=simple`, active means the process was forked successfully. It
says nothing about whether the service works. Verify with `ss -ltnp` or a
request.

**A unit fails instantly with `status=203/EXEC`. Where do you look?**
The unit file and the filesystem. 203 means systemd could not execute the
command at all, so the application never ran and its own logs will be empty.
Missing binary, not executable, or a bad shebang.

**Which command turns an exit code into a name?**
`systemd-analyze exit-status <code>`.

**A service exits with status 137. What happened, and what confirms it?**
Killed by signal 9, and 137 is 128 plus 9. Most often the OOM killer. Confirm
with `journalctl -k | grep -i 'killed process'`.

**What is 139?**
128 plus 11, a segmentation fault.

**A service has failed a hundred times and `is-active` says `activating`. Why
not `failed`?**
It has a `Restart=` policy and is between attempts. It only reaches `failed`
when it exceeds `StartLimitBurst` within `StartLimitIntervalSec`.

**A unit reached the start limit. What clears it?**
`systemctl reset-failed <unit>`, then start it again.

**Which `Type=` actually means the service is ready?**
`notify`. The process signals readiness with `sd_notify()`.

**A `oneshot` unit is reported active and no process exists. Bug?**
No. `RemainAfterExit=yes` keeps it active after the script exits. That is the
intended behaviour.

**Three units are failed. Where do you start?**
The one that failed earliest in the journal. The other two are probably
consequences.

**Difference between `Requires=` and `After=`?**
`Requires=` is a dependency with no ordering; `After=` is ordering with no
dependency. Use both.

**A process will not die even with `kill -9`. What state is it in?**
`D`, uninterruptible sleep, blocked in the kernel on I/O. Signals are not
delivered until the syscall returns. Fix the storage, not the process.

**Where are crashes recorded, and how do you read one?**
`coredumpctl list`, then `coredumpctl info <pid>` for a backtrace or
`coredumpctl debug` for gdb.

**Why treat a production core dump carefully?**
It contains the process's memory, which can include session tokens, keys, and
customer data.

</details>

## Where this sits

Lesson 33 wrote unit files and lesson 34 read the journal; this is what to do
when a unit will not behave. Lesson 29's signals explain the numbers above 128,
and status 137 usually leads to lesson 75 and the OOM killer rather than to any
bug in the service.

The next lesson goes one layer lower, to the point where the logs start naming
hardware.


## References

- [systemctl(1)](https://www.freedesktop.org/software/systemd/man/latest/systemctl.html) - freedesktop.org. Accessed 2026-08-09.
- [systemd.service(5)](https://www.freedesktop.org/software/systemd/man/latest/systemd.service.html) - freedesktop.org. Accessed 2026-08-09.
- [systemd.exec(5), process exit codes](https://www.freedesktop.org/software/systemd/man/latest/systemd.exec.html#Process%20Exit%20Codes) - freedesktop.org. Accessed 2026-08-09.
- [signal(7)](https://man7.org/linux/man-pages/man7/signal.7.html) - man7.org. Accessed 2026-08-09.
> **The commands here were run on a real machine, not written from memory.** The
> systemd transcripts come from Fedora CoreOS 44.20260707.3.1 on aarch64, where
> systemd is genuinely PID 1, so the restart loop, the journal, and
> `systemd-analyze` are the real ones rather than a container approximation. The
> `billing.service` unit really did point at a binary that does not exist, and
> `is-active` really did report `active` while it had never once run. The
> segfault transcript is from AlmaLinux 10.2 on aarch64, run natively so the
> shell's own report of the signal is the one you would see.
