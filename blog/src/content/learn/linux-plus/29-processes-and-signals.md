---
title: "Something is stuck and there is no window to close"
description: "A process is running, or sleeping, or dead but still listed. What the state letters mean, why kill is a poor name for a command that mostly asks politely, and the one state where even the unblockable signal does nothing."
track: "linux-plus"
level: "working"
order: 300
objectives:
  - "Read a process listing including its state and parent"
  - "Choose the right signal, and say why 9 is a last resort"
  - "Explain what a zombie is and why killing it does not work"
  - "Change a process's priority and predict the effect"
prerequisites: ["account-files-and-attributes"]
tags: ["linux", "linux-plus", "processes", "signals", "ps"]
updated: 2026-08-07
draft: false
examObjectives:
  - exam: "xk0-006"
    domain: "2.0"
    objective: "2.3"
sources:
  - title: "ps(1)"
    url: "https://man7.org/linux/man-pages/man1/ps.1.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "signal(7)"
    url: "https://man7.org/linux/man-pages/man7/signal.7.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "kill(1)"
    url: "https://man7.org/linux/man-pages/man1/kill.1.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "proc(5)"
    url: "https://man7.org/linux/man-pages/man5/proc.5.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "nice(1)"
    url: "https://man7.org/linux/man-pages/man1/nice.1.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "pgrep(1)"
    url: "https://man7.org/linux/man-pages/man1/pgrep.1.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
symptoms:
  - symptom: "Process will not die even with kill -9"
    anchor: "1-kill-9-does-nothing"
  - symptom: "defunct processes in the process list"
    anchor: "2-zombies-you-cannot-kill"
---

> **Before you read.** An application has stopped responding. On a desktop you
> would close the window; on a server there is no window.
>
> Everyone knows `kill -9`. It is the first thing anyone learns and it is very
> nearly always the wrong first thing to try.
>
> **What could a process be doing that makes `kill -9` — the signal that cannot
> be caught, blocked, or ignored — do nothing at all?**

There is exactly one answer, it is not rare, and it explains a category of stuck
machines that nothing else does. It arrives about two thirds of the way down.

### Some words you will need

<dl class="terms">
<dt>process</dt>
<dd>A running program, with its own memory, open files, and identity.</dd>
<dt>PID</dt>
<dd>Its number. <strong>PPID</strong> is its parent's.</dd>
<dt>signal</dt>
<dd>A small message sent to a process. Most can be caught and handled; two cannot.</dd>
<dt>state</dt>
<dd>What a process is doing right now: running, sleeping, stopped, or finished and not yet collected.</dd>
<dt>niceness</dt>
<dd>A scheduling hint from -20 to 19. Higher is nicer, meaning lower priority.</dd>
</dl>

## What breaks without this

**You reboot a server to fix one program.** Which works, costs an outage, and
teaches you nothing about what went wrong.

**You use `kill -9` by reflex** and lose data, because the process never gets to
flush its buffers, finish its transaction, or remove its lock file.

**You cannot explain a load average of 40 on an idle machine**, which is the
signature of the state that `kill -9` cannot touch.

## Reading the process list

```bash
# Debian 13 (trixie), x86_64
$ sleep 300 & sleep 300 & sleep 1; echo '--- every process, with parents ---'; ps -eo pid,ppid,stat,ni,comm | head -8
--- every process, with parents ---
    PID    PPID STAT  NI COMMAND
      1       0 Ssl    0 sh
    294       1 Sl     0 sleep
    296       1 Sl     0 sleep
    303       1 Rl     0 ps
    305       1 Sl     0 head
```

**`ps -eo` lets you choose the columns**, which beats memorising what `ps aux` and
`ps -ef` each happen to show. `pid`, `ppid`, `stat`, `ni`, `comm`, `user`, `%cpu`,
`%mem`, `etime`, and `args` cover nearly everything.

Two things to read here. **Every process has a parent**, and everything descends
from PID 1 — here `sh`, because this is a container; on a real machine it is
systemd. **The `ps` process itself appears**, in state `R`, because it was running
at the moment it took the snapshot.

`ps aux` (BSD style) and `ps -ef` (System V style) both work and both survive
because Linux accepts either. `ps aux` shows `%CPU` and `%MEM`; `ps -ef` shows the
parent PID. Neither is wrong.

<details class="deeper">
<summary>If you already administer Linux: /proc/PID, and the questions ps cannot answer</summary>

`ps` reads `/proc`, and everything it shows is a formatted selection from there.
Going to the source answers the questions `ps` has no column for, and it needs no
tools you might not have installed.

```
ls -l /proc/1234/cwd        # where it thinks it is, even if that directory was deleted
ls -l /proc/1234/exe        # the binary, even if the file has been replaced or removed
ls -l /proc/1234/fd/        # every open file, socket, and pipe
tr '\0' '\n' < /proc/1234/cmdline    # the real argv, not ps's truncation
tr '\0' '\n' < /proc/1234/environ    # the environment it was started with
cat /proc/1234/limits       # ulimits actually in force
cat /proc/1234/status       # UIDs, threads, memory, signal masks
```

**`exe` and `fd` are the pair that solves real problems.** A process holding a
deleted file keeps the disk space allocated, and `df` disagrees with `du` until it
exits — the topic on disk space covers the symptom, and `ls -l /proc/*/fd/ | grep
deleted` is what finds the culprit. `exe` showing `(deleted)` means the binary was
replaced underneath a running process, which is what a package update does and why
`needs-restarting` exists.

**`environ` is the one to know about for the wrong reasons too.** It is readable by
the process owner and by root, so a secret passed as an environment variable is
visible there for the life of the process. That is the concrete argument against
`docker run -e PASSWORD=...` and in favour of a file or a secrets mount.

**`status` beats `ps` for threads.** `Threads:` gives the count directly, where
`ps` needs `-L`. `SigIgn` and `SigCgt` are bitmasks of which signals the process is
ignoring and catching, which answers "why is it not responding to SIGTERM" without
guessing — and that is the same question the prediction above set up.

**`strace -p 1234` is the escalation** when the process is alive and doing nothing
useful: it shows the syscall it is sitting in. A process blocked in `read` on a
socket is waiting for a peer that is not answering, which is a network problem
rather than a process one. It costs real performance while attached, so it is a
diagnostic and not a monitor.

</details>

## The states

<figure class="learn-figure">
<svg viewBox="0 0 720 340" role="img" aria-labelledby="proc-title proc-desc" style="width:100%;height:auto;">
  <title id="proc-title">Process states and the transitions between them</title>
  <desc id="proc-desc">A process in the running state R can move to sleeping S when it waits for something, and back when that arrives. SIGSTOP or Control-Z moves it to stopped T, and SIGCONT brings it back. When it waits on disk or network input and output it enters uninterruptible sleep D, where no signal including SIGKILL has any effect until the input or output completes. When it exits it becomes a zombie Z, holding only its exit status, until its parent collects that status and the entry disappears.</desc>
  <g font-family="ui-monospace, monospace">
    <rect x="286" y="26" width="150" height="52" rx="5" fill="currentColor" fill-opacity="0.1" stroke="currentColor" stroke-opacity="0.35"/>
    <text x="361" y="50" text-anchor="middle" font-size="13" fill="currentColor">R  running</text>
    <text x="361" y="68" text-anchor="middle" font-size="10" fill="currentColor" fill-opacity="0.6">on a CPU, or ready to be</text>
    <rect x="40" y="140" width="160" height="52" rx="5" fill="currentColor" fill-opacity="0.07" stroke="currentColor" stroke-opacity="0.3"/>
    <text x="120" y="164" text-anchor="middle" font-size="13" fill="currentColor">S  sleeping</text>
    <text x="120" y="182" text-anchor="middle" font-size="10" fill="currentColor" fill-opacity="0.6">waiting. most of them.</text>
    <rect x="522" y="140" width="160" height="52" rx="5" fill="currentColor" fill-opacity="0.07" stroke="currentColor" stroke-opacity="0.3"/>
    <text x="602" y="164" text-anchor="middle" font-size="13" fill="currentColor">T  stopped</text>
    <text x="602" y="182" text-anchor="middle" font-size="10" fill="currentColor" fill-opacity="0.6">suspended, not dead</text>
    <rect x="40" y="262" width="160" height="56" rx="5" fill="none" stroke="currentColor" stroke-opacity="0.4" stroke-dasharray="4 3"/>
    <text x="120" y="286" text-anchor="middle" font-size="13" fill="currentColor">D  uninterruptible</text>
    <text x="120" y="303" text-anchor="middle" font-size="10" fill="currentColor" fill-opacity="0.65">no signal reaches it</text>
    <text x="120" y="316" text-anchor="middle" font-size="10" fill="currentColor" fill-opacity="0.65">not even SIGKILL</text>
    <rect x="522" y="262" width="160" height="56" rx="5" fill="currentColor" fill-opacity="0.07" stroke="currentColor" stroke-opacity="0.3"/>
    <text x="602" y="286" text-anchor="middle" font-size="13" fill="currentColor">Z  zombie</text>
    <text x="602" y="303" text-anchor="middle" font-size="10" fill="currentColor" fill-opacity="0.65">finished. an exit status</text>
    <text x="602" y="316" text-anchor="middle" font-size="10" fill="currentColor" fill-opacity="0.65">waiting to be collected</text>
  </g>
  <g stroke="currentColor" stroke-opacity="0.45" fill="none" stroke-width="1.2">
    <path d="M290 66 L204 148 M211 141 L201 151 L212 155"/>
    <path d="M196 132 L282 52 M275 45 L285 49 L280 59"/>
    <path d="M432 66 L518 148 M511 141 L521 151 L510 155"/>
    <path d="M526 132 L440 52 M441 45 L435 51 L444 60"/>
    <path d="M120 196 L120 258 M115 251 L120 259 L125 251"/>
    <path d="M436 74 L560 258 M553 250 L562 260 L565 248"/>
  </g>
  <g font-family="ui-monospace, monospace" font-size="10" fill="currentColor" fill-opacity="0.7">
    <text x="150" y="108">waits for something</text>
    <text x="196" y="126">it arrives</text>
    <text x="452" y="108">SIGSTOP, Ctrl+Z</text>
    <text x="470" y="126">SIGCONT</text>
    <text x="130" y="232">waits on disk or network</text>
    <text x="452" y="212">exits</text>
  </g>
</svg>
<figcaption>Five letters in the STAT column. Two of them explain most stuck processes.</figcaption>
</figure>

| Letter | State | What it means in practice |
| --- | --- | --- |
| `R` | Running or runnable | Using a CPU, or queued for one |
| `S` | Interruptible sleep | Waiting. **Most processes, most of the time.** |
| `D` | Uninterruptible sleep | Waiting on I/O. Cannot be signalled. |
| `T` | Stopped | Suspended by a signal or a debugger |
| `Z` | Zombie | Finished; its exit status has not been collected |

Extra letters follow the first: `s` a session leader, `l` multi-threaded, `+` in
the foreground, `<` high priority, `N` low priority. In the capture above, `Ssl`
means sleeping, session leader, multi-threaded.

**A machine full of `S` is a healthy machine.** Sleeping is not idle in a bad
sense; it means waiting for work, which is what a web server does between
requests.

## Signals

`kill` sends a signal. It is a poor name, because most signals are requests.

| Signal | Number | Does | Catchable |
| --- | --- | --- | --- |
| `SIGHUP` | 1 | Historically "terminal closed". Now: **reload your config**. | Yes |
| `SIGINT` | 2 | Ctrl+C. Interrupt. | Yes |
| `SIGTERM` | 15 | Please shut down. **The default.** | Yes |
| `SIGKILL` | 9 | Stop immediately. | **No** |
| `SIGSTOP` | 19 | Suspend. | **No** |
| `SIGCONT` | 18 | Resume. | Yes |

Two `sleep` processes are started below and sent the identical signal. The second
one is wrapped in `trap "" TERM`, which tells the shell to ignore SIGTERM.

<details class="predict">
<summary>Both get a plain `kill`, which sends signal 15. Given the "Catchable" column in the table above, what happens to each, and which signal finishes the survivor?</summary>

```bash
# Debian 13 (trixie), x86_64
$ sleep 300 & pid=$!; sleep 1; echo "started PID $pid"; echo '--- ask it politely ---'; kill $pid; sleep 1; ps -p $pid -o pid,stat,comm || echo 'gone'; echo '--- a process that ignores SIGTERM needs -9 ---'; sh -c 'trap "" TERM; sleep 300' & stub=$!; sleep 1; kill $stub; sleep 1; ps -p $stub -o pid,comm --no-headers && echo 'still there after SIGTERM'; kill -9 $stub; sleep 1; ps -p $stub -o pid --no-headers || echo 'gone after SIGKILL'
started PID 294
--- ask it politely ---
    PID STAT COMMAND
gone
--- a process that ignores SIGTERM needs -9 ---
    306 sh
still there after SIGTERM
gone after SIGKILL
```

</details>

**Two different outcomes from the same command.** The first `sleep` took SIGTERM
and exited. The second had `trap "" TERM` — it deliberately ignores SIGTERM — and
survived, until SIGKILL, which it cannot ignore.

**That is the whole argument for trying 15 first.** A well-written program handles
SIGTERM by finishing the current request, flushing its buffers, closing its
database connections, and removing its lock file. SIGKILL gives it none of that:
the kernel simply stops it, mid-write if that is where it was.

The order to work through:

```bash
kill 1234           # SIGTERM. Wait a few seconds.
kill 1234           # Again, in case the first was missed
kill -9 1234        # Only when it has genuinely not responded
```

**`SIGHUP` deserves its own note.** For a daemon it conventionally means "re-read
your configuration", not "quit" — which is how nginx and sshd pick up config
changes without dropping connections. `systemctl reload` sends it, or whatever the
unit file specifies.

Finding the PID:

| Command | Does |
| --- | --- |
| `pgrep -f nginx` | PIDs matching a pattern |
| `pkill -f nginx` | Signal them all |
| `killall nginx` | Signal by **exact** name |
| `pidof nginx` | PIDs by exact name |

**`pkill -f` matches the full command line**, which is powerful and dangerous:
`pkill -f python` kills every Python process on the machine. Run `pgrep -f` first
and read the list. Always.

## The one `kill -9` cannot touch

<details class="predict">
<summary>A process shows state `D` and does not respond to `kill -9`. Given that SIGKILL cannot be caught, blocked, or ignored, how is that possible?</summary>

**Because the process is not in a position to receive anything.**

`D` is uninterruptible sleep: the process is inside a system call, waiting on I/O,
and the kernel has deliberately made it unwakeable until that I/O completes.
Signals are delivered when a process is about to return to userspace — and this
one is not going to return until the read finishes.

So SIGKILL is not blocked or ignored. It is **queued**, and it will be delivered
the instant the I/O completes.

The reason the kernel does this is data integrity: interrupting a process halfway
through a disk write, with kernel structures half-updated, would corrupt the
filesystem. Uninterruptible means "this operation must complete or fail on its
own".

**What actually causes it:**

- **An unresponsive NFS server.** The classic. Every process touching that mount
  goes into `D` and stays there. `mount -o soft` makes such reads fail with an
  error instead of hanging forever, at the cost of applications seeing I/O errors.
- **A failing disk**, where reads take 30 seconds and retry.
- **Genuinely heavy I/O**, briefly and normally — a moment in `D` is not a problem.

**The tell is the load average.** Linux counts `D` processes as runnable, so a
machine with forty processes stuck on a dead NFS mount shows a load average of 40
while every CPU is idle. That combination — high load, no CPU usage — is
effectively diagnostic:

```
ps -eo pid,stat,wchan:20,comm | awk '$2 ~ /D/'
```

`wchan` names the kernel function each one is waiting in, which usually identifies
the subsystem immediately.

**The fix is never at the process level.** Restore the NFS server, replace the
disk, or wait for the I/O. If the mount is gone for good, `umount -f` or `umount
-l` releases it and the processes come back. Rebooting works and is the blunt
version of the same thing.

</details>

## Zombies

A zombie has already finished. It holds nothing but its exit status, waiting for
its parent to call `wait()` and collect it. Its memory, files, and everything else
are long gone.

**You cannot kill a zombie.** It is already dead; there is nothing to signal.
`kill -9` on one does nothing at all, which is confusing until you see why.

**The bug is in the parent**, which is not reaping its children. Signal *the
parent* — `kill -CHLD <ppid>` sometimes prompts it, and restarting the parent
always works, because when a parent dies its children are re-parented to PID 1,
and PID 1 reaps unconditionally.

**A handful of zombies is normal and harmless.** They occupy a process table entry
and nothing else. Thousands of them means a genuine bug and eventually PID
exhaustion, at which point nothing new can start.

## Priority

```bash
# Debian 13 (trixie), x86_64
$ nice -n 10 sleep 300 & sleep 300 & sleep 1; echo '--- niceness, higher means lower priority ---'; ps -eo pid,ni,comm | grep -E 'NI|sleep'; renice -n 19 -p $(pgrep -f 'sleep 300' | head -1) >/dev/null; sleep 1; echo '--- after renice ---'; ps -eo pid,ni,comm | grep -E 'NI|sleep'
--- niceness, higher means lower priority ---
    PID  NI COMMAND
    294  10 sleep
    296   0 sleep
--- after renice ---
    PID  NI COMMAND
    294  19 sleep
    296   0 sleep
```

**Niceness runs -20 to 19, and the name is the mnemonic**: a nicer process yields
more, so **higher is lower priority**. The default is 0.

```
nice -n 10 ./backup.sh        # start it considerate
renice -n 5 -p 1234           # change a running one
renice -n 5 -u jordan         # everything a user is running
```

**Only root can be less nice.** A normal user can raise their own niceness and
never lower it, so you can deprioritise your own work and not promote it above
everyone else's.

**Niceness only matters under contention.** On an idle machine a nice-19 process
gets the whole CPU, because nothing else wants it. It is a tiebreaker, not a cap —
`cgroups` are what actually limit a process, and that is what systemd and
containers use.

<details class="deeper">
<summary>If you already administer Linux: what to look at when a machine is slow</summary>

`top` sorted by CPU is the reflex and frequently the wrong first look, because the
most common causes are not CPU.

**Read the load average against the core count.** `uptime` gives three numbers —
1, 5, and 15 minutes. Load equal to the core count is fully busy; double is
queueing. The trend across the three matters more than any one: rising means it is
still getting worse.

**Then check whether it is CPU at all.** In `top`, the `%Cpu(s)` line splits it:
`us` userspace, `sy` kernel, **`wa` waiting on I/O**, `st` stolen by the
hypervisor. High `wa` means storage, not CPU, and no amount of `renice` helps.
High `st` on a cloud instance means a noisy neighbour, and the fix is a support
ticket.

**`vmstat 1 5`** is the compact version: run queue, blocked count, swap in and
out, and the same CPU breakdown, once a second. The `b` column is `D`-state
processes and the `si`/`so` columns are swap — non-zero swap activity is far more
damaging to latency than a high load average.

**`iotop`** for which process is doing the I/O, **`pidstat -d 1`** if `iotop` is
not installed.

**`top` interactively:** `1` splits per-CPU, `M` sorts by memory, `P` by CPU, `c`
shows full command lines, `H` shows threads. `htop` is friendlier and needs
installing.

**`/proc/<pid>/` is the definitive source** for a single process: `cmdline` for
what it was actually invoked with, `environ` for its environment, `status` for
memory and thread counts, `fd/` for open files, `stack` for where it is in the
kernel. `wchan` in `ps` is a summary of that last one.

</details>

<details class="deeper">
<summary>If you already administer Linux: the OOM killer, and why the wrong process died</summary>

When memory runs out, the kernel chooses a process and kills it. The choice is
frequently not the culprit.

**It scores by `oom_score`**, which is roughly proportional to memory used, so it
picks the largest process — which on a database server is the database, not the
runaway script that consumed everything else.

`dmesg | grep -i 'killed process'` or `journalctl -k | grep -i oom` shows what
happened and when, and it is the answer to "the database restarted itself
overnight and nothing in its own log explains why".

**Exit code 137** is the signature: 128 + 9, meaning SIGKILL. In a container that
usually means the cgroup memory limit rather than the host running out, and
`systemctl status` or `podman inspect` will say `OOMKilled`.

**Protect a process** by lowering its score:
`echo -500 > /proc/<pid>/oom_score_adj`, range -1000 to 1000, or `OOMScoreAdjust=`
in a systemd unit. `-1000` exempts it entirely, which should be reserved for
things whose death takes the machine with them.

**The better fix is nearly always a memory limit on the offender**, not protection
for the victim. `MemoryMax=` in a systemd unit confines a service to a cgroup, so
it is killed when *it* exceeds its allowance rather than when the machine does.
That converts an unpredictable outage into a predictable and attributable one.

**Swap changes the failure mode rather than preventing it.** With swap, a machine
under memory pressure becomes extremely slow before anything dies, which is
sometimes worse than a fast failure — a server that responds in forty seconds is
down as far as its users are concerned, and the monitoring may not agree.

</details>

## Across distributions

The commands here are `procps-ng` on the RHEL family and `procps` on Debian, and
they behave identically. `htop`, `iotop`, and `pidstat` (from `sysstat`) are
separate packages on both and are rarely installed by default.

The one real difference is PID 1: systemd on any normal machine, and whatever the
image specifies inside a container — which is why a container's process list looks
so short and why signals sent to PID 1 in a container behave unusually.

## Prove it

```bash
# What is using CPU, and is it CPU at all
top -b -n1 | head -12
uptime                              # load against core count from nproc

# Anything stuck in uninterruptible sleep
ps -eo pid,stat,wchan:20,comm | awk '$2 ~ /D/'

# Any zombies, and whose children they are
ps -eo pid,ppid,stat,comm | awk '$3 ~ /Z/'

# Before signalling anything, see what you would hit
pgrep -a -f thepattern
```

**That last line is the habit that prevents the worst mistake in this lesson.**
`pgrep -a -f` lists the PIDs *and* their full command lines. Read it, then run
`pkill` with the identical pattern.

## What trips people up

### 1. `kill -9` does nothing

State `D`. The process is inside a system call waiting on I/O and cannot receive
anything until it completes. SIGKILL is queued, not ignored.

Fix the I/O — usually an unresponsive NFS mount or a failing disk. `ps -eo
pid,stat,wchan,comm` and look at `wchan`.

### 2. Zombies you cannot kill

Already dead. Nothing to signal.

Signal or restart the **parent**. When the parent exits, PID 1 adopts the children
and reaps them.

### 3. Reaching for `-9` first

It denies the process any chance to flush buffers, finish transactions, or clean
up lock files. Data loss and stale locks follow.

SIGTERM, wait, SIGTERM again, and only then SIGKILL.

### 4. `pkill -f` matching more than intended

`pkill -f python` kills every Python process on the machine, including ones you
had not thought about.

`pgrep -a -f` first, every time.

### 5. Expecting `renice` to fix a slow machine

Niceness only decides who wins when processes compete for CPU. If the machine is
waiting on I/O, or swapping, or short of memory, it changes nothing.

Check the `wa` and `st` columns in `top` before assuming CPU is the constraint.

## Work it through

A server is unresponsive over SSH but still answers ping. You get a session
eventually, and it takes a minute.

```
$ uptime
 14:22:01 up 41 days,  load average: 38.42, 36.10, 21.55
$ nproc
4
```

Reason it out before reading on.

**Load 38 on 4 cores looks catastrophic**, and the rising trend across the three
figures says it is still getting worse. The instinct is to find the process
burning CPU.

**Check whether it is CPU at all**, because load on Linux is not a CPU metric:

```
top -b -n1 | head -5
```

If `%Cpu(s)` shows `us` and `sy` near zero and **`wa` very high**, no process is
using the CPU. Every core is idle and the load average is 38.

**That combination is close to diagnostic.** Linux counts uninterruptible-sleep
processes as runnable, so `D`-state processes inflate the load average without
using any CPU at all. Thirty-eight processes stuck waiting on I/O produce exactly
this.

**Confirm and identify:**

```
ps -eo pid,stat,wchan:25,comm | awk '$2 ~ /D/'
```

A long list, all in `D`, with `wchan` values naming NFS or block-layer functions.

**Then find what they are waiting on:**

```
findmnt -t nfs4,nfs
dmesg -T | tail -30
```

`nfs: server fileserver not responding, still trying` in `dmesg` is the answer,
and it will be timestamped from before anyone noticed.

**Why is SSH slow but working?** Because `sshd` and your shell are not touching
the dead mount — until something does. A login shell whose profile lists a
directory on that mount will hang there, which is why some sessions connect and
some do not.

**The fix is not on this machine.** Restore the NFS server. If it is gone for
good, `umount -f` or `umount -l /mnt/share` detaches it and the `D` processes
return, get their I/O error, and exit.

**`kill -9` on any of them does nothing**, which is the thing worth having
internalised before the day it matters.

Now the point to extract. **Load average measures demand, not CPU usage**, and on
Linux specifically it includes processes blocked on I/O. So "high load" is the
start of a question rather than an answer, and the second command — the `wa`
column — is what splits it into two completely different investigations.

The habit: **`uptime` then `top`, and read `wa` before `us`.** A slow machine with
idle CPUs is a storage problem, and every minute spent looking at process CPU
usage is a minute not spent on the mount.

## Try it

Optional, on any machine.

1. `ps -eo pid,ppid,stat,ni,comm | head -20`. Find something in `S` and something
   in `R`.
2. `ps -eo stat | sort | uniq -c | sort -rn`. Count the states.
3. `sleep 300 &`, note the PID, then `kill` it and confirm with `ps -p`.
4. `sleep 300 &`, then `kill -STOP`, check `ps` shows `T`, then `kill -CONT`.
5. `nice -n 15 sleep 300 &` and confirm with `ps -eo pid,ni,comm`.
6. `uptime` and `nproc`. Work out whether the load is high for this machine.
7. `top`, then press `1`, `M`, `P`, and `c` in turn.

**Verification step.** You have it when you can look at a machine with a load
average of 30 and decide, in two commands, whether to investigate CPU or storage.

## Check yourself

<details class="qa">
<summary>Why try SIGTERM before SIGKILL, when SIGKILL always works?</summary>

**Because SIGTERM can be handled and SIGKILL cannot.**

A well-written program catches SIGTERM and uses it to shut down properly: finish
the current request, flush buffers to disk, commit or roll back the open
transaction, close network connections, remove its PID and lock files.

SIGKILL gives it none of that. The kernel stops the process immediately, wherever
it was — possibly halfway through a write. The results are lost data, corrupt
files, and stale lock files that stop the service starting again.

The order: `kill`, wait a few seconds, `kill` again, and only then `kill -9`. The
only time to go straight to 9 is when the process is genuinely not responding to
anything and you have accepted the cost.

</details>

<details class="qa">
<summary>A process is in state `D` and ignores `kill -9`. Explain, and say what actually fixes it.</summary>

**It is in uninterruptible sleep, inside a system call waiting on I/O.** Signals
are delivered when a process is about to return to userspace, and this one will
not return until the I/O completes. SIGKILL is not blocked — it is **queued**, and
delivered the moment the wait ends.

The kernel does this deliberately: interrupting a process midway through a disk
operation, with kernel structures half-updated, would risk corruption.

**Causes:** an unresponsive NFS server, a failing disk, or genuinely heavy I/O.

**The fix is never at the process level.** Restore the server, replace the disk, or
wait. If the mount is gone for good, `umount -f` or `umount -l` releases it and
the processes come back and exit.

The tell at machine level: high load average with idle CPUs, because Linux counts
`D` processes as runnable.

</details>

<details class="qa">
<summary>What is a zombie, and why does killing it not work?</summary>

**A process that has finished but whose exit status has not been collected by its
parent.** Everything else about it is already gone — memory, open files, the lot.
What remains is an entry in the process table holding the exit code.

**Killing it does nothing because it is already dead.** There is no running process
to receive a signal.

The bug is in the **parent**, which is not calling `wait()` to reap its children.
`kill -CHLD <ppid>` sometimes prompts it; restarting the parent always works,
because orphaned children are re-parented to PID 1, which reaps unconditionally.

A few zombies are harmless — one process table entry each. Thousands mean a real
bug and eventually PID exhaustion, at which point nothing new can start.

</details>

<details class="qa">
<summary>Does `nice -n 19` limit how much CPU a process can use?</summary>

**No.** Niceness is a scheduling hint that only matters when processes compete. On
a machine with spare capacity, a nice-19 process gets everything it asks for,
because nothing else wants the CPU.

It is a tiebreaker, not a cap.

What actually limits a process is **cgroups**, which is what systemd and
containers use: `CPUQuota=50%` in a unit file, or `--cpus=0.5` on a container,
enforce a real ceiling regardless of what else is running.

Also worth knowing: only root can *lower* niceness. A normal user can make their
own processes nicer and never less nice, so nobody can promote their work above
everyone else's.

</details>

<details class="qa">
<summary>Load average is 38 on a 4-core machine and every CPU is idle. What is happening?</summary>

**Processes are blocked on I/O.** Linux's load average counts uninterruptible-sleep
(`D`) processes as runnable, unlike most other Unixes, so processes waiting on
storage inflate it without consuming any CPU.

Thirty-eight processes stuck on an unresponsive NFS mount or a failing disk
produce exactly this reading.

**Confirm it** with the `%Cpu(s)` line in `top`: a high `wa` figure with `us` and
`sy` near zero. Then `ps -eo pid,stat,wchan:25,comm | awk '$2 ~ /D/'` lists the
blocked processes and names the kernel function each is waiting in.

`dmesg -T | tail` usually contains the explanation, timestamped from before anyone
noticed.

The general lesson: **load average measures demand, not CPU usage.** High load is
the beginning of a question, and the `wa` column decides which investigation you
are actually in.

</details>

## References

- [ps(1)](https://man7.org/linux/man-pages/man1/ps.1.html) - Linux man-pages project. Accessed 2026-08-07.
- [signal(7)](https://man7.org/linux/man-pages/man7/signal.7.html) - Linux man-pages project. Accessed 2026-08-07.
- [kill(1)](https://man7.org/linux/man-pages/man1/kill.1.html) - Linux man-pages project. Accessed 2026-08-07.
- [proc(5)](https://man7.org/linux/man-pages/man5/proc.5.html) - Linux man-pages project. Accessed 2026-08-07.
- [nice(1)](https://man7.org/linux/man-pages/man1/nice.1.html) - Linux man-pages project. Accessed 2026-08-07.
- [pgrep(1)](https://man7.org/linux/man-pages/man1/pgrep.1.html) - Linux man-pages project. Accessed 2026-08-07.

Command output was captured on the images pinned in `blog/scripts/distros.json`.
Blocks without a distribution and architecture header are illustrative.
