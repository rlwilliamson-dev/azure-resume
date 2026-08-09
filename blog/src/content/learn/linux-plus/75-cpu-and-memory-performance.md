---
title: "Everything is slow and the CPU graph looks fine"
description: "Load average does not measure CPU, free memory is not the number you want, and a process that vanished at 3am was probably chosen deliberately by the kernel. The three things people misread most, demonstrated on a machine doing the work."
track: "linux-plus"
level: "deep"
order: 760
objectives:
  - "Say what load average actually counts, and why it can exceed CPU count with an idle CPU"
  - "Read vmstat and identify which resource is the constraint"
  - "Explain why free memory being low is normal and which column matters"
  - "Recognise an OOM kill from the exit status and confirm it in the kernel log"
  - "Distinguish a memory leak from cache growth"
  - "Apply a method rather than guessing at which tool to run"
prerequisites: ["processes-and-signals", "process-and-service-failures"]
tags: ["linux", "linux-plus", "troubleshooting", "performance", "memory"]
updated: 2026-08-09
draft: false
examObjectives:
  - exam: "xk0-006"
    domain: "5.0"
    objective: "5.5"
sources:
  - title: "proc(5), /proc/loadavg and /proc/meminfo"
    url: "https://man7.org/linux/man-pages/man5/proc.5.html"
    publisher: "man7.org"
    accessed: 2026-08-09
    tier: 1
  - title: "vmstat(8)"
    url: "https://man7.org/linux/man-pages/man8/vmstat.8.html"
    publisher: "man7.org"
    accessed: 2026-08-09
    tier: 1
  - title: "free(1)"
    url: "https://man7.org/linux/man-pages/man1/free.1.html"
    publisher: "man7.org"
    accessed: 2026-08-09
    tier: 1
  - title: "Kernel documentation: Pressure Stall Information"
    url: "https://docs.kernel.org/accounting/psi.html"
    publisher: "kernel.org"
    accessed: 2026-08-09
    tier: 1
  - title: "Kernel documentation: control group v2 memory controller"
    url: "https://docs.kernel.org/admin-guide/cgroup-v2.html#memory"
    publisher: "kernel.org"
    accessed: 2026-08-09
    tier: 1
symptoms:
  - symptom: "Load average is high but the CPU is mostly idle"
    anchor: "load-average-does-not-measure-cpu"
  - symptom: "Process disappeared with no error and exit status 137"
    anchor: "the-oom-killer"
  - symptom: "Almost no free memory on a healthy machine"
    anchor: "free-memory-is-the-wrong-number"
---

> **Before you read.** Users say the application is slow. You log in, and the
> load average is 6 on a machine with 5 CPUs, which looks like the answer.
> Then you look at CPU utilisation and it is 98% idle.
>
> **Both readings are correct.** Load average is not a CPU metric, and believing
> that it is will send you to buy CPUs that will not help.

Performance work goes wrong in a specific way: somebody reads one number,
recognises it as bad, and starts fixing the thing that number appears to be
about. This lesson is mostly about three numbers that do not mean what their
names suggest, and a method that stops you guessing.

### Some words you will need

<dl class="terms">
<dt>load average</dt>
<dd>Processes running <em>or waiting</em>, averaged over 1, 5, and 15 minutes. Not a percentage, and not CPU-only.</dd>
<dt>run queue</dt>
<dd>Processes ready to run and waiting for a CPU.</dd>
<dt>I/O wait</dt>
<dd>Time the CPU was idle with at least one process blocked on disk.</dd>
<dt>context switch</dt>
<dd>The kernel swapping one process off a CPU for another. Cheap individually, expensive in bulk.</dd>
<dt>page cache</dt>
<dd>File data the kernel keeps in RAM. Counted as used, released on demand.</dd>
<dt>RSS</dt>
<dd>Resident set size: physical memory a process currently occupies.</dd>
<dt>swap</dt>
<dd>Disk used as an overflow for memory pages.</dd>
<dt>OOM killer</dt>
<dd>The kernel choosing a process to kill when memory cannot be reclaimed.</dd>
<dt>cgroup</dt>
<dd>A kernel grouping with its own resource limits. How containers are capped.</dd>
</dl>

## What breaks without this

**The wrong resource gets bought.** More CPU for a disk-bound workload changes
nothing except the invoice.

**Healthy machines get "fixed".** Low free memory looks alarming and is normal.
Dropping caches to make the number look better makes the machine slower.

**Processes vanish without explanation.** A service that is killed by the kernel
leaves no message in its own log, so the investigation starts in the wrong
place entirely.

**Slow is treated as one thing.** Slow because of CPU, slow because of disk, and
slow because of a lock look identical from the outside and have nothing in
common.

**Nobody knows what normal was.** Without a baseline, every number is
uninterpretable, and "high" becomes a matter of opinion.

## Load average does not measure CPU

The number is on every dashboard and is probably the most misread value in
Linux.

**Load average counts processes in the run queue plus processes in
uninterruptible sleep.** That second part is the whole misunderstanding: a
process blocked on disk I/O counts toward load while consuming no CPU at all.

Watch it happen. Eight processes read the disk with `iflag=direct`, bypassing
the page cache so every read is a real device operation:

<details class="predict">
<summary>Eight processes are doing nothing but blocking on disk reads, on a machine with 5 CPUs. What will the load average be, and what will the CPU be doing?</summary>

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ for i in $(seq 1 8); do (sudo dd if=/dev/vda of=/dev/null bs=4k count=4000000 iflag=direct status=none 2>/dev/null &) ; done
sleep 75
echo "--- load average, with 5 CPUs on this machine ---"; cat /proc/loadavg
echo "--- and where the time is actually going (us sy id wa) ---"; vmstat 2 3 | tail -1
echo "--- how many processes are blocked rather than running ---"; ps -eo stat | grep -c "^D"
sudo pkill -x dd 2>/dev/null; true
--- load average, with 5 CPUs on this machine ---
5.91 2.08 0.83 3/234 601709
--- and where the time is actually going (us sy id wa) ---
 2  6      0 949168    112 558332    0    0 577032  169 138723 262043 2 32 7 60 0 0
--- how many processes are blocked rather than running ---
6
```

</details>

**Load 5.91 on a 5-CPU machine, and user CPU is 2%.** By the load-average
reading alone this machine is saturated. It is not short of CPU by any measure.

Read the `vmstat` line, because every number in it is part of the story:

| Field | Value | Means |
| --- | --- | --- |
| `r` | `2` | Processes waiting for CPU. Two, on five CPUs. Nothing |
| `b` | `6` | **Processes blocked on I/O.** This is the load |
| `bi` | `577032` | Blocks read per second. The disk is working hard |
| `cs` | `262043` | Context switches per second |
| `us` | `2` | User CPU. Applications are barely computing |
| `sy` | `32` | System CPU, the kernel doing I/O work |
| `id` | `7` | Idle |
| `wa` | `60` | **I/O wait. Sixty percent of the time, waiting for disk** |

**`b` and `wa` are the diagnosis.** Six blocked processes and 60% I/O wait says
storage, not CPU, and confirms it twice from different angles.

**So the load average tells you how much work is outstanding, not what kind.**
It is a useful trend and a poor diagnosis. Three interpretation rules:

- **Compare it to CPU count.** Load 4 on 4 CPUs is fully committed; load 4 on 64
  CPUs is nothing. `nproc` first, always.
- **Read all three numbers.** `5.91 2.08 0.83` is 1, 5, and 15 minutes. Rising
  left to right means the problem is building; falling means it is passing. Here
  the 1-minute figure is far above the 15-minute one, so this started recently.
- **Never diagnose from load alone.** It is the signal to look, not the finding.

For contrast, the same machine at rest:

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ echo "--- memory, as the kernel accounts for it ---"; free -h; echo; echo "--- how many CPUs, and what the load average is ---"; nproc; cat /proc/loadavg
--- memory, as the kernel accounts for it ---
               total        used        free      shared  buff/cache   available
Mem:           1.9Gi       609Mi       277Mi       1.3Mi       1.1Gi       1.3Gi
Swap:             0B          0B          0B

--- how many CPUs, and what the load average is ---
5
0.06 0.14 0.13 1/210 596246
```

<details class="deeper">
<summary>If you already administer Linux: a method that beats picking tools you happen to know</summary>

The failure mode in performance work is not ignorance of tools, it is running
the three you are comfortable with and concluding from whatever they show.
Brendan Gregg's **USE method** fixes that by making the checklist about
resources rather than commands.

**For every resource, check three things:**

- **Utilisation**: how much of the time it was busy
- **Saturation**: how much work is queued and waiting for it
- **Errors**: how many operations failed

The insight is that **saturation usually hurts before utilisation looks bad**. A
disk at 100% utilisation serving a queue of one is fine; the same disk with a
queue depth of 40 is where latency explodes. Utilisation alone will not show you
that.

| Resource | Utilisation | Saturation | Errors |
| --- | --- | --- | --- |
| CPU | `vmstat` `us`+`sy`, `mpstat -P ALL` | `vmstat` `r` column, load average | Rare; MCEs in `dmesg` |
| Memory | `free`, `available` | `si`/`so` in `vmstat`, OOM kills | Failed allocations |
| Disk | `iostat -x` `%util` | `aqu-sz`, `vmstat` `b`, `wa` | `dmesg` I/O errors, SMART |
| Network | `sar -n DEV`, `ip -s link` | Drops, retransmits, `ss -ti` | `ip -s link` errors |

**Work the list rather than your instincts**, and the resource that is the
constraint identifies itself in a couple of minutes.

**Pressure Stall Information is the modern shortcut** and is worth knowing
because it answers the question load average was always being asked to answer.
The kernel exposes, per resource, the percentage of time tasks were stalled
waiting for it:

```bash
cat /proc/pressure/cpu /proc/pressure/io /proc/pressure/memory
```

Each gives `some` (at least one task stalled) and `full` (every task stalled)
over 10, 60, and 300 seconds. `full` above zero on memory or I/O means real work
is not happening, and unlike load average it is unambiguous about which resource
is responsible. It is per-cgroup too, so you can attribute pressure to a
container. If you build dashboards, PSI is a better top-level signal than load.

**And the thing to do before any of this: know your baseline.** "High" is
meaningless without a normal. A machine that always runs at load 8 is not
having an incident because it is at load 8 today. Record the ordinary numbers
while things are fine, per lesson 64, so that a comparison is available when
they are not.

</details>

## Free memory is the wrong number

Look again at the `free -h` output above: 1.9 GB total, 277 MB free. That looks
like a machine about to run out.

**It is not, and the number that says so is `available`, which reads 1.3 GB.**

**The kernel uses spare memory for the page cache**, keeping file data in RAM so
it does not have to read the disk twice. That memory is counted as used, and it
is instantly reclaimable the moment anything wants it. RAM sitting empty is RAM
doing no work, so a healthy machine that has been up for a while will always
show low free memory.

| Column | Means | Worth watching? |
| --- | --- | --- |
| `total` | Physical RAM | Reference only |
| `used` | Neither free nor cache | Somewhat |
| `free` | Genuinely untouched | **No.** Low is normal and good |
| `shared` | tmpfs and shared segments | Occasionally. `/dev/shm` lives here |
| `buff/cache` | Page cache and buffers | Reclaimable. Not a problem |
| `available` | **What a new process could get** | **Yes. This is the number** |

**`available` is an estimate the kernel computes**, accounting for how much of
the cache it could actually release. It is the only column that answers the
question people think they are asking when they look at `free`.

**Which makes "dropping caches" almost always wrong.** Writing to
`/proc/sys/vm/drop_caches` will make `free` look healthier and will make the
machine slower, because every file it re-reads now comes from disk. It is a
benchmarking tool, not a remedy, and it belongs nowhere near a production
runbook.

**Swap is worth its own sentence.** Swap being *used* is not itself a problem:
the kernel moves genuinely idle pages out to make room for cache, and those
pages may never be touched again. Swap being *actively traded* is the problem,
and `vmstat`'s `si` and `so` columns are what tell you. Sustained non-zero `si`
and `so` means the machine is thrashing, and that is a real emergency because
everything gets slow at once. Note the machine above has no swap at all, which
is common for cloud instances and containers and has consequences in the next
section.

## The OOM killer

When the kernel cannot satisfy an allocation and cannot reclaim anything, it
does not fail the allocation. It picks a process and kills it.

A container capped at 64 MB is asked to hold 200 MB:

<details class="predict">
<summary>A container is limited to 64 MB of memory and told to write a 200 MB file into <code>/dev/shm</code>, which is memory. What exit status does it return?</summary>

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ echo "--- a container capped at 64 MB, asked to hold 200 MB ---"; podman run --rm --memory 64m docker.io/library/almalinux:10 sh -c "dd if=/dev/zero of=/dev/shm/fill bs=1M count=200 status=none"; echo "container exit status: $?"
--- a container capped at 64 MB, asked to hold 200 MB ---
container exit status: 137
```

</details>

**137, and no error message from `dd` at all.** 137 is 128 plus 9, so the
process was killed by `SIGKILL`, per lesson 69. Nothing in the application's own
output explains it, because the application was not consulted.

This is why an OOM kill is so often misdiagnosed. The service log ends
mid-sentence, there is no stack trace, and the process is simply gone. The
evidence is in the kernel log instead:

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ echo "--- and the kernel says who it chose ---"; sudo journalctl -k --no-pager | grep -iE "Memory cgroup out of memory|Killed process" | tail -3
--- and the kernel says who it chose ---
Aug 08 13:25:07 localhost.localdomain kernel: Out of memory: Killed process 2811 (dnf) total-vm:771032kB, anon-rss:144864kB, file-rss:988kB, shmem-rss:0kB, UID:501 pgtables:476kB oom_score_adj:200
Aug 08 13:25:21 localhost.localdomain kernel: Out of memory: Killed process 2204 (dnf) total-vm:771664kB, anon-rss:145600kB, file-rss:136kB, shmem-rss:0kB, UID:501 pgtables:488kB oom_score_adj:200
Aug 08 22:22:20 localhost.localdomain kernel: Memory cgroup out of memory: Killed process 595735 (dd) total-vm:6052kB, anon-rss:1212kB, file-rss:2180kB, shmem-rss:0kB, UID:501 pgtables:52kB oom_score_adj:0
```

Three real kills, and the first words of each are the important difference.

- **`Out of memory:`** is a system-wide kill. The whole machine ran out. Those
  two `dnf` entries are from an earlier session on this VM, where a package
  operation exhausted a 1.9 GB machine.
- **`Memory cgroup out of memory:`** is a **limit** kill. The machine had memory
  to spare; a cgroup hit its own ceiling. That is the container above, and it is
  what every container OOM looks like.

Telling those apart is the first question to answer, because they have
opposite fixes: raise the container's limit, or find what is consuming the
host.

The rest of the line is the evidence:

| Field | In the `dd` kill | Means |
| --- | --- | --- |
| `total-vm` | `6052kB` | Address space reserved. Frequently huge and misleading |
| `anon-rss` | `1212kB` | **Real private memory.** The number that matters |
| `file-rss` | `2180kB` | Resident file-backed pages |
| `shmem-rss` | `0kB` | Shared memory. `/dev/shm` shows up here |
| `oom_score_adj` | `0` | The tuning knob, from -1000 to 1000 |

`total-vm` is not memory usage. A JVM or a Go program reserves an enormous
address space and occupies a fraction of it. Judge by `anon-rss`.

How the victim is chosen: the kernel scores every process roughly by how much
memory it would free, then adjusts by `oom_score_adj`. So it tends to kill the
biggest consumer, which is very often the important database rather than the
leaking script that caused the problem. `-1000` makes a process ineligible;
systemd exposes this as `OOMScoreAdjust=` in a unit file.

<details class="deeper">
<summary>If you already administer Linux: telling a leak from cache, and what to do about each</summary>

"Memory keeps climbing" is the report. It has three quite different causes and
distinguishing them takes about a minute.

**First, is it cache or is it processes?**

```bash
free -h                                # does buff/cache account for the growth
grep -E 'MemAvailable|Cached|Slab' /proc/meminfo
ps -eo pid,comm,rss --sort=-rss | head -10
```

If `buff/cache` is growing and `available` is holding steady, nothing is wrong.
That is the kernel doing its job.

**If a process's RSS climbs steadily and never falls, that is a leak.** Watch
one over time rather than guessing:

```bash
while :; do ps -o rss= -p <pid>; sleep 60; done
```

Monotonic growth over hours, across a period that included idle time, is a leak.
Growth that plateaus is a cache inside the application, which is normal and
usually configurable.

**Third possibility, and the one people miss: kernel memory.** `Slab` in
`/proc/meminfo` covers kernel objects, and it can grow without any process
owning it. `slabtop -o` shows what. `dentry` and `inode_cache` growing is
usually a workload creating enormous numbers of files, and it is reclaimable.
Something else growing without bound is a driver or filesystem bug.

Where the memory actually goes, per process:

```bash
ps -eo pid,ppid,rss,vsz,comm --sort=-rss | head
pmap -x <pid> | tail -1              # totals for one process
cat /proc/<pid>/status | grep -E 'VmRSS|VmSwap|Threads'
systemd-cgtop -m                     # by cgroup, which is by service
```

`systemd-cgtop -m` is underused and is the fastest way to attribute memory to
a service on a systemd machine, because it groups by unit instead of making
you sum processes.

Beware double counting with shared memory. Two processes sharing a library
each report its pages in RSS, so summing RSS across a fleet of workers
overstates the total badly. `PSS` in `/proc/<pid>/smaps_rollup` divides shared
pages by the number of sharers and is the honest per-process number.

Practical mitigations, roughly in order:

- **Set `MemoryMax=` on the unit.** Better a bounded service that fails
  predictably than an unbounded one that takes the host with it. `MemoryHigh=`
  throttles before killing, which is gentler.
- **Protect what must survive** with `OOMScoreAdjust=-500` on the database, so
  the kernel prefers something else.
- **Configure swap deliberately.** No swap means the OOM killer is the only
  reclaim mechanism, so the machine goes from fine to a dead process with
  nothing in between. A small swap gives the kernel somewhere to put genuinely
  idle pages and buys time to alert.
- **`vm.swappiness`** controls the preference for swapping anonymous pages
  against evicting cache. 60 is the default, 10 is a common choice for
  databases, and 0 does not mean "never swap".
- **Alert on `available`, not on `free`**, and alert on OOM kills directly.
  `journalctl -k --grep='Killed process'` is trivial to scrape and is a real
  incident every time it fires.

And note what happens with no swap and a hard cgroup limit, which is the
common container case: there is nowhere to put idle anonymous pages, so a
workload that would merely have gone slow instead dies at exit 137. That is
usually preferable in a cluster, where a killed pod is rescheduled, and it is
worth understanding as a deliberate trade rather than a surprise.

</details>

## When it really is the CPU

Having ruled out the impostors, sometimes the CPU is the constraint. The
distinction that matters is *which kind* of CPU time.

```bash
vmstat 2 5                 # us sy id wa st, and r for the run queue
mpstat -P ALL 2            # per-CPU, which exposes single-threaded bottlenecks
pidstat -u 2               # per-process CPU, sampled rather than instantaneous
top -o %CPU                # interactive; press 1 for per-CPU
```

| Symptom | Suggests |
| --- | --- |
| High `us`, `r` above CPU count | Genuine CPU shortage. Profile the application or add CPUs |
| High `sy` | Kernel work: syscall storms, context switching, network interrupts |
| High `wa` | Not CPU. Storage, per lesson 76 |
| High `st` (steal) | **The hypervisor is giving your CPU to somebody else.** A noisy neighbour, or a throttled instance |
| One CPU at 100%, others idle | Single-threaded bottleneck. More cores will not help |
| High `cs` with low `us` | Thrashing between too many runnable threads, or lock contention |

**`st` deserves attention on any cloud instance.** Steal time is time your
virtual CPU was ready to run and the hypervisor scheduled somebody else. You
cannot fix it from inside the guest, and sustained double-digit steal is a
reason to resize or move, not to optimise your code.

**And "one CPU pinned, the rest idle" is one of the most useful patterns to
recognise**, because it changes the answer completely: the workload is
single-threaded and buying a bigger machine will do nothing. `mpstat -P ALL` is
what makes it visible; an averaged CPU graph hides it entirely, which is exactly
how a 16-core machine can look 6% busy while being completely stuck.

<details class="deeper">
<summary>If you already administer Linux: cgroup CPU throttling, the slowdown with no busy resource</summary>

There is a way for an application to be badly CPU-starved while every host
metric looks calm, and it catches people constantly on Kubernetes and anywhere
else with CPU limits.

**A cgroup CPU limit is enforced by quota, not by priority.** `cpu.max` gives a
cgroup so many microseconds of CPU per period, 100 ms by default. Spend the
quota early and **every thread in that cgroup is stopped until the period
rolls over.** Not slowed down. Stopped.

From outside, the host is idle and your application has 100 ms gaps in it.

**The evidence is in the cgroup's own accounting**, not in `top`:

```bash
cat /sys/fs/cgroup/<path>/cpu.stat
```

```text
nr_periods 4521
nr_throttled 1832
throttled_usec 41982331
```

`nr_throttled` against `nr_periods` is the ratio that matters. Anything
persistently above a few percent is a real latency source, and it will show up
in your p99 response times while every dashboard says the machine is fine.

**The counter-intuitive part is that adding threads makes it worse.** A limit of
"1 CPU" spread across 16 worker threads means all 16 burn the shared quota in
about 6 ms and then all 16 are frozen for 94 ms. The same work on two threads
would have used the quota smoothly. This is why Java and Go services in
containers need to be told how many CPUs they actually have: a runtime that
sizes its thread pool from `nproc` sees the host's core count, not its limit.

- Go: `GOMAXPROCS` should match the limit, not `nproc`.
- Java: modern JVMs are container-aware, older ones need
  `-XX:ActiveProcessorCount`.
- Anything else that sizes pools automatically: check what it read.

`cpu.weight` (shares) is the alternative and is usually the better tool. It
sets relative priority under contention rather than a hard ceiling, so a
workload can use idle CPU when it is there and yields when others need it.
Limits are for guaranteeing you cannot be a bad neighbour; weights are for
making the machine efficient. Reaching for a hard limit by default is how
services end up throttled on an idle host.

How to spot it in one line on a systemd machine: `systemd-cgtop` shows CPU per
unit, and comparing that against the unit's `CPUQuota=` tells you whether it
is pressed against its ceiling. If it is, the fix is the quota or the thread
count, and no amount of profiling the application will help.

</details>

## The order to work in

1. **`uptime`** for load, and **`nproc`** for context. Rising or falling?
2. **`vmstat 2 5`** and read `r`, `b`, `wa`, `si`, `so`. This one command
   usually names the constrained resource.
3. **If `b` or `wa` is high**, it is storage. Lesson 76.
4. **If `si`/`so` are non-zero**, it is memory pressure. Find the consumer.
5. **If `us` is high and `r` exceeds CPU count**, it is CPU. `mpstat -P ALL` to
   check whether it is one thread or all of them.
6. **If `st` is high**, it is the hypervisor, not you.
7. **If none of them are high and it is still slow**, the constraint is not a
   resource: a lock, a dependency, a remote call, DNS. Lessons 72 and 76.

**That last case is worth expecting.** A machine can be slow with every
resource idle, because it is waiting on something else. Checking that all four
resources are unremarkable is a real finding, not a failed investigation.

## Across distributions

The numbers come from the kernel, so they mean the same thing everywhere. What
differs is whether the tool that displays them is installed, and whether anything
recorded them before the incident started.

| | RHEL family | Debian family |
| --- | --- | --- |
| `top`, `free`, `vmstat`, `ps` | `procps-ng`, installed | `procps`, installed |
| `sar`, `iostat`, `mpstat`, `pidstat` | `sysstat`, **install it** | `sysstat`, **install it** |
| Historical collection enabled | `sysstat` collects once installed | `sysstat` ships with collection **off** |
| Where history is kept | `/var/log/sa/` | `/var/log/sysstat/` |
| Per-process memory detail | `/proc/<pid>/smaps_rollup` | identical |
| OOM killer messages | `journalctl -k`, and `/var/log/messages` | `journalctl -k`, and `/var/log/syslog` |
| Default cgroup version | v2 | v2 |

**The collection row is the one worth acting on today rather than during an
incident.** On Debian and Ubuntu, installing `sysstat` gives you the commands and
records nothing until you set `ENABLED="true"` in `/etc/default/sysstat`. So
`sar -q -f` for yesterday afternoon returns an empty file on exactly the machine
where you needed it, and there is no way to go back and collect it.

Everything else here is portable, which is worth saying plainly: load average,
the `available` column, `si` and `so`, and the OOM killer's accounting behave
identically on both families, so a habit built on one transfers whole.

## Prove it

Read these in order, because the first two decide whether the rest are relevant
at all:

```bash
# Is the machine busy, and with what kind of busy
uptime; nproc                       # load against core count
vmstat 1 5                          # r and us mean CPU; b and wa mean I/O; st means hypervisor

# Memory: the number that matters, not the one people read
free -h                             # 'available', never 'free'

# Is it swapping, or merely using swap
vmstat 1 5                          # si and so are the traffic; a used swap column is not

# Per-core, because an average across sixteen hides one at 100 percent
mpstat -P ALL 1 3

# Who is using it
ps -eo pid,ppid,%cpu,%mem,rss,etime,comm --sort=-%mem | head
ps -eo pid,stat,wchan:20,comm | awk '$2 ~ /D/'      # blocked on I/O

# Did the kernel kill something
journalctl -k | grep -iE "out of memory|killed process"
```

**Load average against core count, then `wa`, is the whole first minute.** High
load with idle CPU and a high `wa` is storage, and no amount of profiling the
application will change that. High load with high `us` is genuinely CPU. Getting
that fork right decides which of the next ten commands are worth running.

## What trips people up

### 1. Reading load average as a CPU percentage

It counts processes running plus processes in uninterruptible sleep, so a machine
blocked on a failing disk shows a load of 12 with the CPU asleep. Compare it
against `nproc`, and read it alongside `wa` rather than alone.

### 2. Reading the `free` column

A Linux machine with lots of free memory after a week of uptime is a machine
nobody is using. The kernel spends free memory on page cache because unused
memory is wasted memory, and it hands it back the moment something needs it.
`available` is the number that answers "could a new process get memory".

### 3. Dropping caches to fix something

It frees a number on a screen and makes the machine slower, because everything
that was cached has to be read from disk again. The kernel would have released
that memory on demand anyway. There is no production problem this fixes.

### 4. Panicking about swap being used

Pages that were swapped out during a busy period and never needed again sit there
harmlessly. The problem is traffic, not occupancy: sustained `si` and `so` in
`vmstat` means the machine is actively paging and everything is slow. A used swap
column on its own is not an incident.

### 5. Reading `total-vm` in an OOM message

It is reserved address space, and a runtime that maps a large heap up front can
report far more than the machine has. `anon-rss` is the resident memory that
actually counted. Chasing `total-vm` sends people looking for a leak that is not
there.

### 6. Missing that the limit was a cgroup rather than the machine

"Out of memory: Killed process" means the machine ran out. "Memory cgroup out of
memory" means one container or unit hit its own limit while the host had memory
to spare. Same kill, completely different fix, and the difference is one word in
the log line.

## Work it through

A reporting server is slow every weekday at 09:00. Users report timeouts. The
monitoring graph shows CPU utilisation around 10 percent throughout.

Reason it out before reading on.

**First, distrust the CPU graph before distrusting the report.** Ten percent
across sixteen cores is what one saturated core looks like when the graph
averages, so measure per core:

```bash
mpstat -P ALL 1 5
```

Say one CPU shows 99 percent user time and the rest are idle. That is a
single-threaded bottleneck, and the useful conclusion arrives early: a bigger
machine will not help, because the work cannot use the cores it already has.

**Second, confirm it is CPU rather than something masquerading as it.** Load
average and the blocked count separate the two:

```bash
uptime; nproc
vmstat 1 5
```

Low `b`, low `wa`, high `us` on one core confirms it. High `b` and `wa` would
have meant storage, and the whole investigation would turn.

**Third, find the process and ask what it is doing.** Ten percent of the machine
is one process at 100 percent of one core:

```bash
ps -eo pid,%cpu,etime,cmd --sort=-%cpu | head -5
sudo strace -c -p <pid> -f       # what syscalls, if any
```

**Fourth, connect it to the timing.** Every weekday at 09:00 is a schedule, not a
coincidence:

```bash
systemctl list-timers --all | head
crontab -l; sudo ls -l /etc/cron.d/
```

A nightly report generator that overruns into business hours, or a job that
starts at 09:00 by design, explains the pattern and points at the fix: move it,
or make it use more than one core.

The lesson that generalises past this incident: the averaged graph was not wrong,
it was answering a different question from the one being asked. Any metric
averaged across a dimension can hide a problem in that dimension, which is why
`mpstat -P ALL` exists and why percentiles beat means for latency.

## Try it

Optional, and a VM with more than one core makes it much more interesting.

1. Run one CPU-bound loop, such as `yes > /dev/null`, and watch `uptime`,
   `top`, and `mpstat -P ALL` together. Note what the averaged view shows against
   the per-core view.
2. Read a file much larger than free memory with `cat bigfile > /dev/null`, then
   compare `free -h` before and after. Watch `free` collapse while `available`
   barely moves.
3. Force an OOM kill in a container with a low memory limit, then read the kernel
   message. Find `total-vm` and `anon-rss`, and confirm which one is close to the
   limit you set. Note whether the message says "Memory cgroup out of memory".
4. Create artificial I/O wait with `dd if=/dev/zero of=/tmp/f bs=1M count=4000
   oflag=direct` and watch `b` and `wa` climb in `vmstat` while `us` stays low.

**Verification step.** You have step 4 right when the load average has risen
noticeably and the CPU is mostly idle, and you can explain in one sentence why
those two facts are consistent rather than contradictory.

## For the exam

**Load average counts running plus uninterruptible-sleep processes.** It is not
a CPU percentage, and disk-blocked processes raise it.

**Compare load to CPU count.** The three figures are 1, 5, and 15 minutes.

**`available` is the memory number that matters, not `free`.** Low free memory
is normal, because the kernel caches with it.

**`buff/cache` is reclaimable.** Do not drop caches to fix anything.

**Swap in use is not an emergency; `si`/`so` traffic is.**

**Exit status 137 is `SIGKILL`**, and most often the OOM killer. Confirm in
`journalctl -k`.

**"Out of memory" is system-wide; "Memory cgroup out of memory" is a limit.**

**`total-vm` is address space, not usage.** Read `anon-rss`.

**`oom_score_adj` biases the choice**, `-1000` makes a process immune.

**High `wa` means storage. High `st` means the hypervisor.**

<details class="qa">
<summary>Check yourself</summary>

**Load average is 5.91 on a machine with 5 CPUs and the CPU is 98% idle. What
is happening?**
Processes blocked in uninterruptible sleep count toward load. In the capture
above, `b` was 6 and `wa` was 60%, so the constraint was disk.

**Which `vmstat` columns tell you it is I/O rather than CPU?**
`b` (blocked processes) and `wa` (I/O wait). `r` and `us` would be high instead
if it were CPU.

**`free -h` shows 277 MB free out of 1.9 GB. Is that a problem?**
No. Look at `available`, which was 1.3 GB. The rest is page cache and is
reclaimable on demand.

**Should you ever drop caches to free memory?**
No, other than for benchmarking. It makes the machine slower by forcing re-reads
from disk, and the kernel would have released that memory anyway.

**Swap is 40% used. Emergency?**
Not by itself. Look at `si` and `so` in `vmstat`. Sustained swap traffic is the
problem; idle pages sitting in swap are not.

**A process exits with 137 and logs nothing. What happened?**
Killed by `SIGKILL`, 128 plus 9. Very likely the OOM killer. Check
`journalctl -k` for "Killed process".

**What is the difference between "Out of memory" and "Memory cgroup out of
memory" in the kernel log?**
The first is system-wide: the machine ran out. The second is a cgroup hitting
its own limit while the host had memory free. Different fixes.

**A process shows `total-vm` of 40 GB on a 16 GB machine. How?**
`total-vm` is reserved address space, not resident memory. Read `anon-rss`.

**How do you stop the kernel choosing your database?**
Lower its `oom_score_adj`, for example `OOMScoreAdjust=-500` in the unit, so
something else scores higher.

**Memory climbs steadily and never falls. Leak or cache?**
Check whether the growth is in `buff/cache` (fine) or in a process's RSS
(a leak). Kernel `Slab` growth is a third possibility, shown by `slabtop`.

**Why can summing RSS across processes overstate memory use?**
Shared pages are counted in every sharer's RSS. `PSS` in `smaps_rollup` divides
shared pages between them.

**`st` is 25% in `vmstat`. What does that mean and what do you do?**
Steal time: the hypervisor is running someone else on your CPU. It cannot be
fixed inside the guest. Resize or move the instance.

**One core is at 100% and fifteen are idle. Will a bigger machine help?**
No. That is a single-threaded bottleneck. `mpstat -P ALL` reveals it; an
averaged graph hides it.

**Which three things does the USE method check for each resource?**
Utilisation, saturation, and errors. Saturation usually degrades performance
before utilisation looks bad.

</details>

## Where this sits

Lesson 29 introduced processes and signals, and lesson 69 showed exit status 137
without saying who sends it. This lesson is the answer. The `b` and `wa` columns
point straight at the next lesson, which takes the same posture toward storage
and the network.


## References

- [proc(5), /proc/loadavg and /proc/meminfo](https://man7.org/linux/man-pages/man5/proc.5.html) - man7.org. Accessed 2026-08-09.
- [vmstat(8)](https://man7.org/linux/man-pages/man8/vmstat.8.html) - man7.org. Accessed 2026-08-09.
- [free(1)](https://man7.org/linux/man-pages/man1/free.1.html) - man7.org. Accessed 2026-08-09.
- [Kernel documentation: Pressure Stall Information](https://docs.kernel.org/accounting/psi.html) - kernel.org. Accessed 2026-08-09.
- [Kernel documentation: control group v2 memory controller](https://docs.kernel.org/admin-guide/cgroup-v2.html#memory) - kernel.org. Accessed 2026-08-09.
> **The commands here were run on a real machine, not written from memory.** The
> transcripts come from Fedora CoreOS 44.20260707.3.1 on aarch64, a virtual
> machine with 5 CPUs and 1.9 GB of RAM. The load average of 5.91 was produced by
> eight processes doing direct reads from the virtual disk, so the reads bypass
> the page cache and genuinely block. The container OOM was a real kill by the
> kernel, and the two "Out of memory" lines above it are real system-wide kills
> from an earlier session on the same machine, which is why the timestamps do not
> match: a package operation exhausted it hours before.
