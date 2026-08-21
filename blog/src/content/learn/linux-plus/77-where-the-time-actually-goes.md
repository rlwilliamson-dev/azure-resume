---
title: "Where the time actually goes"
description: "Topics 75 and 76 give you tools that say a machine is busy. None of them says which function it is busy in. Sampling against tracing, reading a profile, what a flame graph is really showing, and asking the kernel a question no tool has a flag for."
deck: "Forty per cent CPU, and nothing on the list looks wrong"
track: "linux-plus"
level: "deep"
order: 780
beyondExam: true
objectives:
  - "Say what a profiler measures and why it is statistical rather than complete"
  - "Read a perf profile and say which layer the time is in"
  - "Explain what a flame graph shows and what its horizontal axis is not"
  - "Use a tracer to answer a question no existing tool has an option for"
  - "Choose between counting, sampling and tracing for a given question"
prerequisites: ["cpu-and-memory-performance", "io-and-network-performance"]
tags: ["linux", "linux-plus", "performance", "tracing", "beyond-the-exam"]
updated: 2026-08-21
draft: false
examObjectives: []
sources:
  - title: "Linux Performance"
    url: "https://www.brendangregg.com/linuxperf.html"
    publisher: "Brendan Gregg"
    accessed: 2026-08-21
    tier: 2
  - title: "CPU Flame Graphs"
    url: "https://www.brendangregg.com/FlameGraphs/cpuflamegraphs.html"
    publisher: "Brendan Gregg"
    accessed: 2026-08-21
    tier: 2
  - title: "perf wiki"
    url: "https://perfwiki.github.io/main/"
    publisher: "Linux kernel perf project"
    accessed: 2026-08-21
    tier: 1
  - title: "perf-stat(1)"
    url: "https://man7.org/linux/man-pages/man1/perf-stat.1.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-21
    tier: 1
  - title: "perf-record(1)"
    url: "https://man7.org/linux/man-pages/man1/perf-record.1.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-21
    tier: 1
  - title: "bpftrace"
    url: "https://bpftrace.org/"
    publisher: "bpftrace project"
    accessed: 2026-08-21
    tier: 1
  - title: "ftrace, the kernel documentation"
    url: "https://docs.kernel.org/trace/ftrace.html"
    publisher: "The kernel development community"
    accessed: 2026-08-21
    tier: 1
symptoms:
  - symptom: "A process uses a lot of CPU and nothing says which part of it"
    anchor: "utilisation-says-there-is-a-problem-and-never-where"
  - symptom: "A profile is full of hexadecimal addresses instead of function names"
    anchor: "perf-record-and-where-the-samples-land"
---

> **Before you read.** A service is slow. `top` shows it using forty per cent of
> one core, `vmstat` shows no swapping, the disks are quiet and the network is
> fine. Every tool in topics 75 and 76 says the machine is healthy.
>
> **Which function is the forty per cent in, and how would you find out?**

The performance topics in this track teach you to measure utilisation, and
utilisation is a number about a resource. It tells you a queue is forming and it
cannot tell you what is in the queue. This page is the other half, it is not on
the exam, and it is the difference between reporting that a machine is busy and
being able to say what it is busy doing.

### Some words you will need

<dl class="terms">
<dt>profiler</dt>
<dd>A tool that interrupts a running system at intervals and records where it was. Statistical by construction.</dd>
<dt>sample</dt>
<dd>One of those recordings: a stack of function names, taken at one instant.</dd>
<dt>tracer</dt>
<dd>A tool that records every occurrence of a chosen event rather than sampling.</dd>
<dt>tracepoint</dt>
<dd>A named, stable hook the kernel exposes on purpose, for tracers to attach to.</dd>
<dt>kprobe</dt>
<dd>A hook attached to an arbitrary kernel function, which is powerful and not stable across versions.</dd>
<dt>symbol</dt>
<dd>The name of a function, as opposed to the address it lives at. Without symbols a profile is arithmetic.</dd>
<dt>flame graph</dt>
<dd>A way of drawing many stacks at once so the common paths become visible as width.</dd>
</dl>

## What breaks without this

**The investigation stops at "it is slow".** Utilisation is where most people run
out of tools, and the next step becomes guessing, or adding hardware, or blaming
the application team.

**Optimisation goes to the wrong place.** Without a measurement, effort lands on
whatever somebody assumed was expensive, and the actual cost is somewhere nobody
looked.

**Questions with no flag go unanswered.** "Which process is opening the most
files right now" has no option in any standard tool, and the honest answer
without a tracer is that you cannot know.

## Utilisation says there is a problem and never where

The tools in topic 75 read counters the kernel already keeps: how much CPU time
each process accumulated, how many pages were faulted in, how long the run queue
was. Every one of those is a total, and a total has no idea how it was
accumulated.

The first step up is still counting, but counting the right things. `perf stat`
runs a command with the hardware and software counters attached and reports what
that command specifically cost.

<details class="predict">
<summary>Writing 300 megabytes to a file, with an explicit flush at the end. Where does the time go, user space or the kernel, and how many context switches does an operation with no waiting in it need?</summary>

```bash
# Debian 13 (trixie), aarch64
$ perf stat -e task-clock,context-switches,page-faults,minor-faults dd if=/dev/zero of=/tmp/z bs=1M count=300 conv=fsync 2>&1 | grep -vE "^$|records (in|out)|copied" | head -12
 Performance counter stats for 'dd if=/dev/zero of=/tmp/z bs=1M count=300 conv=fsync':
             40.00 msec task-clock                       #    0.692 CPUs utilized             
                16      context-switches                 #  399.996 /sec                      
               313      page-faults                      #    7.825 K/sec                     
               313      minor-faults                     #    7.825 K/sec                     
       0.057795674 seconds time elapsed
       0.000928000 seconds user
       0.038696000 seconds sys
```

</details>

Read the last two lines first, because they are the ones that decide what to do
next. Almost all of the time is `sys` and almost none is `user`, so the process
is not computing anything; it is asking the kernel to move bytes. Sixteen context
switches for three hundred megabytes says it is not blocking much either. And the
`task-clock` of forty milliseconds against fifty-eight of elapsed time says the
thing spent about a third of its life not running at all.

None of that names a function. It does tell you which half of the machine to
point the next tool at, which is worth the two seconds it took.

<details class="deeper">
<summary>If you already read these numbers: why user against sys is the most useful split on the page</summary>

The two figures divide the world in a way that maps directly onto what you would
do about it.

Time in user space is the program executing its own instructions. If that
dominates, the answer is in the code or in the data it was given: an algorithm, a
regular expression, a loop over something larger than the author expected. Nothing
about the kernel, the storage or the network will change it, and profiling the
application is the next step.

Time in sys is the program asking the kernel for things. If that dominates, the
interesting question is what it is asking for and how often, and the usual answer
is that it is making an enormous number of small requests. A program doing
four-kilobyte writes where it could do one-megabyte writes spends its life in the
syscall path, and no faster disk fixes it because the disk is not the constraint.

The third case is the one that catches people: neither figure is large and the
elapsed time is. That is waiting, and waiting does not appear in either column.
Off-CPU time is its own investigation, and the tool for it is a tracer rather than
a profiler, because a profiler samples what is running and a process that is
waiting is precisely not running.

</details>

## Sampling and tracing are different instruments

Everything from here divides into two kinds of tool, and choosing wrongly wastes
either your time or the machine's.

<figure class="learn-figure">
<svg viewBox="0 0 720 240" role="img" aria-labelledby="samp-title" style="width:100%;height:auto;">
<title id="samp-title">A run of work drawn twice, once with a profiler taking evenly spaced samples that catch some events and miss others, and once with a tracer recording every event that occurs</title>
<g fill="currentColor">
<text x="14" y="24" font-size="11">the same second, measured two ways</text>
<text x="14" y="58" font-size="10.5">sampling</text>
<rect x="120" y="46" width="570" height="30" rx="2" fill="currentColor" fill-opacity="0.07" stroke="currentColor" stroke-opacity="0.3"/>
<line x1="150" y1="46" x2="150" y2="76" stroke="var(--accent)" stroke-width="2"/>
<line x1="240" y1="46" x2="240" y2="76" stroke="var(--accent)" stroke-width="2"/>
<line x1="330" y1="46" x2="330" y2="76" stroke="var(--accent)" stroke-width="2"/>
<line x1="420" y1="46" x2="420" y2="76" stroke="var(--accent)" stroke-width="2"/>
<line x1="510" y1="46" x2="510" y2="76" stroke="var(--accent)" stroke-width="2"/>
<line x1="600" y1="46" x2="600" y2="76" stroke="var(--accent)" stroke-width="2"/>
<text x="120" y="98" font-size="10" fill="var(--accent)">99 photographs a second, and whatever happened between them is inferred</text>
<text x="14" y="146" font-size="10.5">tracing</text>
<rect x="120" y="134" width="570" height="30" rx="2" fill="currentColor" fill-opacity="0.07" stroke="currentColor" stroke-opacity="0.3"/>
<line x1="134" y1="134" x2="134" y2="164" stroke="currentColor" stroke-opacity="0.75" stroke-width="1.4"/>
<line x1="158" y1="134" x2="158" y2="164" stroke="currentColor" stroke-opacity="0.75" stroke-width="1.4"/>
<line x1="171" y1="134" x2="171" y2="164" stroke="currentColor" stroke-opacity="0.75" stroke-width="1.4"/>
<line x1="205" y1="134" x2="205" y2="164" stroke="currentColor" stroke-opacity="0.75" stroke-width="1.4"/>
<line x1="248" y1="134" x2="248" y2="164" stroke="currentColor" stroke-opacity="0.75" stroke-width="1.4"/>
<line x1="262" y1="134" x2="262" y2="164" stroke="currentColor" stroke-opacity="0.75" stroke-width="1.4"/>
<line x1="299" y1="134" x2="299" y2="164" stroke="currentColor" stroke-opacity="0.75" stroke-width="1.4"/>
<line x1="341" y1="134" x2="341" y2="164" stroke="currentColor" stroke-opacity="0.75" stroke-width="1.4"/>
<line x1="366" y1="134" x2="366" y2="164" stroke="currentColor" stroke-opacity="0.75" stroke-width="1.4"/>
<line x1="404" y1="134" x2="404" y2="164" stroke="currentColor" stroke-opacity="0.75" stroke-width="1.4"/>
<line x1="437" y1="134" x2="437" y2="164" stroke="currentColor" stroke-opacity="0.75" stroke-width="1.4"/>
<line x1="463" y1="134" x2="463" y2="164" stroke="currentColor" stroke-opacity="0.75" stroke-width="1.4"/>
<line x1="498" y1="134" x2="498" y2="164" stroke="currentColor" stroke-opacity="0.75" stroke-width="1.4"/>
<line x1="529" y1="134" x2="529" y2="164" stroke="currentColor" stroke-opacity="0.75" stroke-width="1.4"/>
<line x1="561" y1="134" x2="561" y2="164" stroke="currentColor" stroke-opacity="0.75" stroke-width="1.4"/>
<line x1="588" y1="134" x2="588" y2="164" stroke="currentColor" stroke-opacity="0.75" stroke-width="1.4"/>
<line x1="617" y1="134" x2="617" y2="164" stroke="currentColor" stroke-opacity="0.75" stroke-width="1.4"/>
<line x1="655" y1="134" x2="655" y2="164" stroke="currentColor" stroke-opacity="0.75" stroke-width="1.4"/>
<text x="120" y="186" font-size="10" fill-opacity="0.8">every occurrence, at a cost that rises with how often the event happens</text>
<text x="14" y="222" font-size="10" fill-opacity="0.75">a rare event can be invisible to the top row and is never invisible to the bottom one</text>
</g>
</svg>
<figcaption>A profiler answers "where does this spend most of its time" cheaply and approximately, and its blind spot is anything rare: a function called twice a second that takes fifty milliseconds each time is real and may never land under a sample. A tracer answers "what happened, every time" and its cost scales with the event rate, so tracing something that fires a million times a second is a way of making the machine slower. The choice is not about accuracy. It is about whether your question is about proportions or about occurrences.</figcaption>
</figure>

## perf record, and where the samples land

`perf record` takes the same workload and, ninety-nine times a second, writes
down the entire call stack. `perf report` then groups those stacks.

<details class="predict">
<summary>The same 300 megabyte write. It is a write benchmark, so the time should be in the write path. Where does a third of it actually go?</summary>

```bash
# Debian 13 (trixie), aarch64
$ perf record -q -g -o /tmp/d.data -- dd if=/dev/zero of=/tmp/z bs=1M count=300 conv=fsync 2>/dev/null; perf report -i /tmp/d.data --stdio --no-children --sort symbol --percent-limit 6 2>/dev/null | grep -vE "^#|^$" | head -14
    34.21%  [k] __arch_clear_user            -      -            
            |
            ---vfs_read
               ksys_read
               __arm64_sys_read
               invoke_syscall.constprop.0
               el0_svc_common.constprop.0
               do_el0_svc
               el0_svc
               el0t_64_sync_handler
               el0t_64_sync
               0xffffa9eb263c
               0xffffa9eb265c
               0xaaaae1425ad4
```

</details>

**A third of the time is in the read side.** `__arch_clear_user` is the kernel
zeroing a buffer for user space, reached through `vfs_read`, because the source
was `/dev/zero` and producing those zeroes is real work. The benchmark that was
meant to measure writing spends a third of itself manufacturing the data to
write, which is the sort of thing a profile tells you and a stopwatch never does.

The rest of the output is a call stack read from the bottom up: the process
entered the kernel through the exception handler, went through the syscall
dispatch, into the read implementation, and ended in the routine doing the
clearing. Reading these upwards is the habit to build, because the interesting
name is usually at the top and the reason it was called is underneath it.

Notice the last three lines. Where the stack leaves the kernel it becomes
hexadecimal, because the kernel has symbols and the userspace binary does not.

<details class="deeper">
<summary>If your profiles are full of hex: where symbols come from, and the second thing that breaks stacks</summary>

Two separate mechanisms have to work before a profile reads as names, and they
fail independently.

The first is symbols. Kernel names come from `/proc/kallsyms`, which the kernel
exports, so the kernel half of a stack usually resolves. Userspace names come
from the binary's own symbol table, and distributions ship binaries stripped to
save space, so the addresses have nothing to resolve against. The fix is the
matching debug package, `-dbgsym` on Debian and Ubuntu or `-debuginfo` on the
RHEL family, and `debuginfod` can now fetch them on demand, which turns a
half-hour of hunting into a configuration line.

The second is the stack walk itself, and it fails more confusingly because it
produces a plausible answer that is wrong. To walk a stack the profiler needs to
find each caller, and the cheap way is a frame pointer register that compilers
have historically been happy to reuse for something else under optimisation. A
binary built without frame pointers gives you the top function and nothing
underneath it. The answers are to build with `-fno-omit-frame-pointer`, which
several distributions have now turned on by default precisely because of this,
or to use DWARF unwinding with `perf record --call-graph dwarf`, which is correct
and much more expensive.

The practical version: if your stacks are one frame deep, you have a frame
pointer problem rather than a profiler problem, and no amount of sampling harder
will fix it.

</details>

## What a flame graph is showing

A profile of anything real is thousands of stacks, and reading them as a list
does not scale. A flame graph is those stacks sorted and drawn as rectangles, and
once you have read one the shape is faster than any table.

<figure class="learn-figure">
<svg viewBox="0 0 720 250" role="img" aria-labelledby="flame-title" style="width:100%;height:auto;">
<title id="flame-title">A small flame graph, where each box is a function, width is the proportion of samples containing it, and boxes sit on top of the function that called them</title>
<g fill="currentColor">
<text x="14" y="24" font-size="11">width is how many samples contained it, height is how deep the stack was</text>
<rect x="20" y="192" width="670" height="26" rx="2" fill="currentColor" fill-opacity="0.09" stroke="currentColor" stroke-opacity="0.35"/>
<text x="355" y="209" text-anchor="middle" font-size="10.5">main</text>
<rect x="20" y="162" width="250" height="26" rx="2" fill="currentColor" fill-opacity="0.09" stroke="currentColor" stroke-opacity="0.35"/>
<text x="145" y="179" text-anchor="middle" font-size="10.5">parse_request</text>
<rect x="274" y="162" width="416" height="26" rx="2" fill="var(--accent)" fill-opacity="0.18" stroke="var(--accent)" stroke-width="1.4"/>
<text x="482" y="179" text-anchor="middle" font-size="10.5" fill="var(--accent)">handle_request</text>
<rect x="20" y="132" width="118" height="26" rx="2" fill="currentColor" fill-opacity="0.09" stroke="currentColor" stroke-opacity="0.35"/>
<text x="79" y="149" text-anchor="middle" font-size="10">split</text>
<rect x="274" y="132" width="330" height="26" rx="2" fill="var(--accent)" fill-opacity="0.18" stroke="var(--accent)" stroke-width="1.4"/>
<text x="439" y="149" text-anchor="middle" font-size="10.5" fill="var(--accent)">db_query</text>
<rect x="608" y="132" width="82" height="26" rx="2" fill="currentColor" fill-opacity="0.09" stroke="currentColor" stroke-opacity="0.35"/>
<text x="649" y="149" text-anchor="middle" font-size="10">render</text>
<rect x="274" y="102" width="300" height="26" rx="2" fill="var(--accent)" fill-opacity="0.28" stroke="var(--accent)" stroke-width="1.6"/>
<text x="424" y="119" text-anchor="middle" font-size="10.5" fill="var(--accent)">escape_string</text>
<text x="20" y="66" font-size="10.5" fill="var(--accent)">escape_string is 42 per cent of the profile and nobody would have guessed it</text>
<text x="20" y="240" font-size="10" fill-opacity="0.75">left to right is alphabetical order, not time</text>
</g>
</svg>
<figcaption>The one thing to unlearn before reading these: the horizontal axis is not time. Boxes are sorted alphabetically so that the same function lands in the same place across two graphs, which is what makes before and after comparable. Width is the share of samples a function appeared in, so a wide box near the top is a function that is itself expensive, and a wide box with a narrow tower on it is a function whose cost is somewhere below. The plateau is the thing to look for, and it is usually somewhere nobody suspected.</figcaption>
</figure>

## Asking a question nothing has a flag for

Sampling answers questions about proportion. Some questions are about events, and
for those the tool is a tracer attached to the kernel's own instrumentation.

<details class="predict">
<summary>Nothing on this machine was asked to report file opens, and no tool has an option for it. Which processes are opening the most files over five seconds?</summary>

```bash
# Debian 13 (trixie), aarch64
$ bpftrace -e "tracepoint:syscalls:sys_enter_openat { @[comm] = count(); } interval:s:5 { exit(); }" 2>&1 | grep -v "^Attach" | head -12


@[sh]: 18
@[sleep]: 27
@[systemd-journal]: 43
@[netavark]: 84
@[conmon]: 165
@[systemd]: 270
@[crun]: 423
@[nft]: 480
@[podman]: 540
```

</details>

That is a complete count of every `openat` on the machine for five seconds,
grouped by process, produced by a one-line program. No tool ships with that
option, and the reason it is available anyway is that the kernel exposes a
tracepoint for every syscall entry and `bpftrace` compiles a small program that
attaches to it and counts.

The output is also a fair description of what this capture ran on: `podman`,
`crun`, `conmon` and `nft` at the top are the container runtime building the
environment the trace itself is running in.

Distributions are the other thing a tracer gives you and a counter cannot.

<details class="predict">
<summary>Two thousand four-kilobyte writes and sixty one-megabyte writes, on a machine also doing its ordinary work. What does a histogram of every write size show that an average would hide?</summary>

```bash
# Debian 13 (trixie), aarch64
$ bpftrace -e "kprobe:vfs_write { @bytes = hist(arg2); } interval:s:5 { exit(); }" > /tmp/h.txt 2>&1 & sleep 1; dd if=/dev/zero of=/tmp/z1 bs=4k count=2000 status=none; dd if=/dev/zero of=/tmp/z2 bs=1M count=60 status=none; sleep 6; grep -vE "^Attach|^$" /tmp/h.txt | grep -vE "^\[[0-9]+K?M?, [0-9]+K?M?\) +0 " 
@bytes:
[0]                    2 |                                                    |
[1]                   22 |                                                    |
[2, 4)                16 |                                                    |
[4, 8)               154 |@@@                                                 |
[8, 16)              110 |@@                                                  |
[16, 32)               8 |                                                    |
[32, 64)              16 |                                                    |
[64, 128)              9 |                                                    |
[128, 256)            24 |                                                    |
[256, 512)             4 |                                                    |
[512, 1K)             22 |                                                    |
[1K, 2K)               6 |                                                    |
[2K, 4K)               8 |                                                    |
[4K, 8K)            2096 |@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@|
[8K, 16K)              4 |                                                    |
[1M, 2M)              60 |@                                                   |
```

</details>

Two spikes and a tail, and no average would have described any of it. The mean
write size across that set is around thirty kilobytes, which is a number matching
almost nothing that actually happened. The 4K spike is the first `dd`, the 1M
spike is the second, and the small stuff at the bottom is everything else on the
machine going about its business.

**This is the shape of most real performance data**, which is why the histogram is
worth reaching for whenever somebody quotes you an average latency. A service
whose mean response time is fine and whose distribution has a second hump at two
seconds has a real problem that the mean is actively concealing.

<details class="deeper">
<summary>If you are considering running this in production: what a tracer actually costs, and the one that will hurt you</summary>

The cost of tracing is the event rate multiplied by the work done per event, and
the first of those varies by orders of magnitude between probes that look
similar.

A tracepoint on process creation fires a handful of times a second on a normal
machine and costs nothing measurable. A tracepoint on syscall entry fires tens of
thousands of times a second and costs a little. A kprobe on something like
`vfs_write` fires as often as anything writes, and on a busy database that is a
lot. Attaching to a function in the scheduler or the network receive path is how
people make a machine noticeably slower with a diagnostic.

Three habits keep it safe. Aggregate in the kernel rather than printing per
event, which is what `count()` and `hist()` do and what `printf` in a hot probe
does not; a program that prints a line per event on a busy system is a program
that turns the box into a log generator. Filter as early as possible, because a
predicate on the probe is cheaper than the same test after the data has been
copied. And prefer tracepoints to kprobes where one exists, both because they are
cheaper and because they are a stable interface, where a kprobe is attached to an
internal function name that can change in a point release and take your tooling
with it.

The honest summary is that a well-written aggregating one-liner on a tracepoint
is safe on production and a careless one on a hot kprobe is an outage you caused
while investigating a slowdown.

</details>

## Which tool for which question

| The question | The instrument |
| --- | --- |
| How much did this cost, in total | `perf stat`, or the counters in topic 75 |
| Where does this spend its time | `perf record`, and a flame graph if the answer is not obvious |
| How often does this happen, and to whom | a tracer counting a tracepoint |
| What is the distribution, not the average | a tracer building a histogram |
| Why is this waiting rather than running | a tracer on scheduler or block events, because a profiler samples what runs |

The order matters as much as the choices. Start with counting, because it is free
and narrows the question. Move to sampling when you need to know where. Reach for
tracing when the question is about events rather than proportions, or when
sampling has told you the time is going somewhere the samples cannot see.

## Across distributions

Both tools are packaged everywhere and the names differ, and one of them has a
constraint the other does not.

| | RHEL family | Debian family |
| --- | --- | --- |
| Profiler package | `perf` | `linux-perf` |
| Profiler version | Follows the kernel, so `perf-6.12.0-211.el10_2` against a 6.12.0-211 kernel | Follows the kernel too, with per-version packages behind the name |
| Tracer package | `bpftrace` | `bpftrace` |
| Userspace symbols | `-debuginfo` packages, and `debuginfod` fetches them on demand | `-dbgsym` packages, from a separate repository you have to enable |

**The profiler version is the one that catches people.** `perf` is built from the
kernel source, so it belongs to a kernel rather than to a distribution release. A
machine whose kernel has been updated and not yet rebooted has a `perf` that does
not match the kernel it is running against, and it says so before producing
output that may or may not be right. The fix is a reboot rather than anything to
do with the tool.

Everything else on this page is kernel behaviour and is identical: the
tracepoints, the `/proc/kallsyms` symbols, the sampling frequency, and the
tracefs mount that has to exist before any tracepoint is visible.

## Prove it

**Run `perf stat` on something you already run.** A backup script, a build, a
report job. Read the user against sys split and decide, before doing anything
else, which of the two halves of the machine your problem is in. That one number
redirects more investigations than any other on this page.

**Profile something and find one surprise.** Anything with a workload will do.
The value of the first profile you take is almost never the optimisation, it is
discovering that the expensive part was not where you assumed.

**Count something the tools do not count.** Pick a question about your own
systems with no existing flag: which process opens the most files, how large are
the writes, how often does a particular syscall fail. One tracepoint and one
`count()` will answer it, and going from "I cannot know that" to a number in
thirty seconds is the point of the whole page.

## What trips people up

### 1. Reading a flame graph left to right as time

The horizontal axis is alphabetical. It exists so that two graphs line up for
comparison, and reading it as a sequence produces a story that is entirely
invented.

### 2. Profiling a process that is waiting

A sampling profiler records what is on CPU. A process blocked on a lock or on I/O
is not on CPU, so it contributes nothing, and a profile of a mostly-idle slow
service looks empty because it is measuring the wrong state.

### 3. Believing a profile with one-frame stacks

That is a missing frame pointer, not a shallow program. Fix the stack walk before
drawing any conclusion from the proportions.

### 4. Tracing a hot function with a print statement

Aggregate in the kernel. A `printf` on a probe that fires a hundred thousand
times a second produces a hundred thousand lines a second and a slower machine
than the one you were investigating.

### 5. Quoting an average from data that has two humps

Latency and size distributions are rarely single-peaked, and a mean over two
populations describes neither. Draw the histogram before quoting a number.

### 6. Attaching a kprobe and expecting it to keep working

A kprobe names an internal kernel function, which is not an interface and can be
renamed or inlined by an update. Anything you intend to keep should sit on a
tracepoint.

## Work it through

A service handles requests in about 20 milliseconds at the median and about 900
at the ninety-ninth percentile. CPU is at thirty per cent, disks are quiet, and
the application team says nothing changed.

Start by refusing the framing. Thirty per cent CPU is a fact about a resource and
the complaint is about latency, and the two are only loosely related: a request
can be slow because it is computing, or because it is waiting, and utilisation
looks similar either way.

So ask which of the two it is, and the cheap version of that question is `perf
stat` on the process for a few seconds. Large sys time means an enormous number
of small requests to the kernel. Large user time means the code. Neither of them
large, with real elapsed time passing, means waiting, and that is the answer the
percentile split hints at: a median of 20 with a tail at 900 rarely comes from
computation, because computation is roughly the same every time.

If it is waiting, a profiler will not help and it is worth knowing that before
spending an afternoon with one. The instrument for waiting is a tracer on the
scheduler or on block events, asking how long each request was off CPU and what
put it there. A lock, a DNS lookup with a timeout, a connection pool with fewer
slots than workers, and a disk with an occasional slow response all produce this
shape, and they are distinguishable by what the trace says the process was
blocked on.

And the tail is where to look rather than the median, because the median request
is fine. Filter everything you measure to the slow ones, which a tracer can do in
the probe and an average never can.

## Try it

**Install `perf` and profile your own shell doing something.** A `find` across a
large tree, a compile, anything with a few seconds of work in it. Reading your
own machine's kernel stacks once removes most of the mystery from the exercise.

**Draw one flame graph.** The scripts are a small download and the process is
`perf record -g`, then `perf script`, then two filters. Doing it once is what
makes the picture readable forever afterwards.

**Write a one-line tracer for a question you actually have.** Not an example from
a page. A question about your own systems that no tool answers, which is the
moment the tool stops being a curiosity.

## Check yourself

<details class="qa">
<summary>Why can a profiler miss a function that runs for fifty milliseconds twice a second?</summary>

Because it samples. At ninety-nine samples a second, a hundred milliseconds of
activity per second may land under a handful of samples or under none, and rare
events are exactly what sampling is bad at. A tracer records every occurrence and
would report both.

</details>

<details class="qa">
<summary>A profile of a slow service is almost empty. What does that tell you?</summary>

That the service is not on CPU, so it is waiting rather than computing. A
sampling profiler records what is running, and a blocked process contributes
nothing. The investigation moves to off-CPU time and to what the process is
blocked on.

</details>

<details class="qa">
<summary>What is the horizontal axis of a flame graph?</summary>

Alphabetical order, not time. It is sorted that way so the same function occupies
the same position in two different graphs, which makes a before and after
comparison meaningful. Width is the proportion of samples the function appeared
in.

</details>

<details class="qa">
<summary>Every userspace frame in your profile is a hexadecimal address. What is missing?</summary>

The symbols for that binary. The kernel exports its own through
`/proc/kallsyms`, so kernel frames resolve, and distribution binaries are
stripped, so userspace frames have nothing to resolve against. The matching debug
package, or debuginfod, supplies them.

</details>

<details class="qa">
<summary>Why prefer a tracepoint to a kprobe for something you intend to keep?</summary>

A tracepoint is a hook the kernel exposes deliberately and keeps stable. A kprobe
attaches to an internal function name, which can be renamed or inlined by any
update, so tooling built on one can stop working after a routine patch.

</details>

## References

- [Linux Performance](https://www.brendangregg.com/linuxperf.html) - Brendan Gregg, the map of which tool observes which part of the system, and the source of the methodology this page follows. Free. Accessed 2026-08-21.
- [CPU Flame Graphs](https://www.brendangregg.com/FlameGraphs/cpuflamegraphs.html) - Brendan Gregg, what the axes mean and how the graphs are produced. Free. Accessed 2026-08-21.
- [perf wiki](https://perfwiki.github.io/main/) - the perf project, tutorial and event reference. Free. Accessed 2026-08-21.
- [perf-stat(1)](https://man7.org/linux/man-pages/man1/perf-stat.1.html) - Linux man-pages project, the counters and what each measures. Accessed 2026-08-21.
- [perf-record(1)](https://man7.org/linux/man-pages/man1/perf-record.1.html) - Linux man-pages project, sampling frequency and the call-graph options. Accessed 2026-08-21.
- [bpftrace](https://bpftrace.org/) - the bpftrace project, the language reference and the probe types. Free. Accessed 2026-08-21.
- [ftrace](https://docs.kernel.org/trace/ftrace.html) - the kernel development community, the tracing infrastructure underneath and what tracefs exposes. Free. Accessed 2026-08-21.

**Where the output came from.** Four captured blocks through `capture.sh` with
the new `--privileged` flag, on the kernel of the podman machine named in each
header. The tools are installed by
[`setups/tracing-tools.sh`](https://github.com/rlwilliamson-dev/azure-resume/blob/main/blog/scripts/setups/tracing-tools.sh),
which also mounts tracefs, because a container does not inherit that mount and
`bpftrace` reports every tracepoint as missing until it is there. Profiling from
inside a container profiles the host kernel, because there is only one kernel.
The flame graph figure is drawn to explain the format and is not a rendering of
any profile taken here.

**Why this is not in the lesson count.** The objectives name `top`, `htop`,
`atop`, `mpstat`, `pidstat`, `ps` and `strace`, and none of `perf`, `bpftrace` or
anything that produces a flame graph. This page is the answer to the question
topics 75 and 76 raise and stop short of.
