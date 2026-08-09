---
title: "The application is slow and it is not the application"
description: "Storage and network problems present as application problems, because the application is where the waiting is visible. Reading iostat properly, separating latency from throughput, and knowing why a device at 60 percent utilisation can already be the bottleneck."
track: "linux-plus"
level: "deep"
order: 770
objectives:
  - "Read iostat and say whether a device is saturated"
  - "Separate latency from throughput, and know which one users feel"
  - "Explain queue depth and why it predicts slowness before utilisation does"
  - "Diagnose packet loss, jitter, and low throughput from counters"
  - "Explain why a baseline is what makes any of these numbers mean anything"
prerequisites: ["cpu-and-memory-performance", "network-connectivity-troubleshooting"]
tags: ["linux", "linux-plus", "troubleshooting", "performance", "storage", "networking"]
updated: 2026-08-09
draft: false
examObjectives:
  - exam: "xk0-006"
    domain: "5.0"
    objective: "5.5"
sources:
  - title: "iostat(1)"
    url: "https://man7.org/linux/man-pages/man1/iostat.1.html"
    publisher: "man7.org"
    accessed: 2026-08-09
    tier: 1
  - title: "Kernel documentation: block layer statistics"
    url: "https://docs.kernel.org/block/stat.html"
    publisher: "kernel.org"
    accessed: 2026-08-09
    tier: 1
  - title: "ping(8)"
    url: "https://man7.org/linux/man-pages/man8/ping.8.html"
    publisher: "man7.org"
    accessed: 2026-08-09
    tier: 1
  - title: "fio documentation"
    url: "https://fio.readthedocs.io/en/latest/fio_doc.html"
    publisher: "fio"
    accessed: 2026-08-09
    tier: 1
symptoms:
  - symptom: "Application slow while CPU and memory look fine"
    anchor: "reading-iostat"
  - symptom: "Throughput is fine but every request feels slow"
    anchor: "latency-and-throughput-are-different-problems"
  - symptom: "Intermittent timeouts with no errors in any log"
    anchor: "the-network-half"
---

> **Before you read.** The report that used to take four seconds now takes
> ninety. Nobody deployed anything. CPU is idle, there is memory to spare, and
> the developers have looked at the query and it is the same query.
>
> Lesson 75 taught you to check `vmstat` first. It shows `wa` at 55 and `b` at
> six, which is the answer to "which resource" and not yet the answer to
> anything else.

Storage and network faults surface as application faults, because the
application is the only place anybody is watching. This lesson is the layer
underneath: how to tell a busy device from an overloaded one, and how to
recognise the network problems that never produce an error message.

### Some words you will need

<dl class="terms">
<dt>IOPS</dt>
<dd>I/O operations per second. What small random work is limited by.</dd>
<dt>throughput</dt>
<dd>Bytes per second. What large sequential work is limited by.</dd>
<dt>latency</dt>
<dd>How long one operation takes. What a user experiences.</dd>
<dt>queue depth</dt>
<dd>How many requests are outstanding at once. <code>aqu-sz</code> in iostat.</dd>
<dt>await</dt>
<dd>Average time a request spent queued plus serviced, in milliseconds.</dd>
<dt>jitter</dt>
<dd>Variation in latency between packets. Steady slow is easier than unpredictable.</dd>
<dt>bufferbloat</dt>
<dd>Oversized buffers that hold packets rather than dropping them, adding delay.</dd>
<dt>baseline</dt>
<dd>What the numbers looked like when things were fine. Without it nothing is interpretable.</dd>
</dl>

## What breaks without this

**Faster hardware gets bought for the wrong thing.** A workload limited by IOPS
does not improve on a disk with more throughput.

**Utilisation is read as headroom.** A device reported at 60 percent looks half
idle and can already be adding delay to every request.

**Averages hide the problem.** Mean latency stays flat while the slowest one
percent of requests gets steadily worse, and those are the requests people
complain about.

**Network faults go undiagnosed.** Loss and jitter produce retransmits and
timeouts, not error messages, so nothing appears in any log.

**Nobody knows what normal was.** Every number is argued about because there is
nothing to compare it against.

## Reading iostat

`iostat -x` is the tool. Its output is wide and most of it is noise, so know
which columns to read.

<details class="predict">
<summary>Eight processes write 4 KB blocks with <code>oflag=direct</code> to one device. Which columns show that the device is under pressure, and does utilisation reach 100 percent?</summary>

```bash
# AlmaLinux 10.2, aarch64
$ mkfs.ext4 -q $DEV0; mkdir -p /mnt/d; mount $DEV0 /mnt/d
for i in $(seq 1 8); do (dd if=/dev/urandom of=/mnt/d/f$i bs=4k count=60000 oflag=direct status=none 2>/dev/null &); done
sleep 3
echo "--- the loop device, while eight writers work it ---"
iostat -xd 4 2 | awk "/Device/{h=\$0} /loop/{last=\$0} END{print h; print last}"
pkill -x dd 2>/dev/null; true
--- the loop device, while eight writers work it ---
Device            r/s     rkB/s   rrqm/s  %rrqm r_await rareq-sz     w/s     wkB/s   wrqm/s  %wrqm w_await wareq-sz     d/s     dkB/s   drqm/s  %drqm d_await dareq-sz     f/s f_await  aqu-sz  %util
loop0            0.50      2.00     0.00   0.00    2.00     4.00 16549.25  67241.00     5.50   0.03    0.27     4.06    0.00      0.00     0.00   0.00    0.00     0.00    0.50   82.50    4.53  61.83
```

</details>

The columns that matter, in the order worth reading them:

| Column | Here | Means |
| --- | --- | --- |
| `w/s` | `16549` | Write operations per second. This is IOPS |
| `wkB/s` | `67241` | About 66 MB/s. This is throughput |
| `w_await` | `0.27` | Milliseconds per write, queued plus serviced |
| `aqu-sz` | `4.53` | **Average requests outstanding.** The saturation signal |
| `%util` | `61.83` | Percentage of time the device had at least one request in flight |

**`aqu-sz` is the number to look at first**, and it is the one people ignore. It
says that on average four and a half requests were waiting at any moment. A
device serving a queue of one is keeping up. A device with a persistent queue is
the constraint, and every request in that queue is waiting on the ones ahead of
it.

**`%util` is the most misread column in Linux performance work.** It means the
proportion of time at least one request was in flight, which was a sound measure
of saturation for a single mechanical disk that could do one thing at a time. An
SSD or an array handles many operations in parallel, so it can sit at 100 percent
while barely working, or as here be at 62 percent with a real queue behind it.
Never read it as a percentage of capacity.

**`await` is what a user feels.** It is per-operation latency, and it includes
queueing. When `await` climbs while `w/s` stays flat, the device is not doing
more work, it is taking longer to do the same work, and that means it is
struggling or something else is contending for it.

Compare `await` against what the hardware should give you: roughly 5 to 15 ms
for a mechanical disk, well under 1 ms for a local SSD, and anything from 1 ms to
tens for network storage depending on the path. The 0.27 ms above is a loop
device backed by the host's SSD, which is why it is fast.

## Latency and throughput are different problems

The distinction decides what to fix, and the two are often in tension.

**Throughput** is bytes moved per second, and it is what large sequential work
needs: backups, log shipping, video, table scans. A workload limited by
throughput improves with faster links and faster media.

**Latency** is how long one operation takes, and it is what interactive work
needs. A database doing small random reads is limited by how quickly each one
completes, not by aggregate bandwidth.

The tension is that you can raise throughput by queueing more work, and queueing
more work raises latency. A disk fed 64 requests at a time will report excellent
throughput and terrible per-request times. This is why a backup job makes an
interactive service feel awful while every throughput graph looks healthy.

**So match the measurement to the workload.** For a database, watch `await` and
the queue. For a backup window, watch `MB/s`. Testing the wrong one produces a
benchmark that says everything is fine.

That is also why `fio` exists rather than `dd`:

```bash
fio --name=randread --rw=randread --bs=4k --size=1G --numjobs=4 \
    --runtime=60 --time_based --direct=1 --group_reporting
```

`dd` does sequential I/O with one thread, which is the easiest possible pattern
and tells you almost nothing about a database workload. `fio` lets you set the
block size, the read and write mix, the number of concurrent jobs, and whether
the page cache is bypassed. `--direct=1` is the important one: without it you
may be measuring RAM.

<details class="deeper">
<summary>If you already administer Linux: finding which process is doing the I/O, and what is actually slow</summary>

`iostat` tells you a device is busy. It does not tell you who is making it busy,
and that is usually the next question.

```bash
sudo iotop -oPa           # only processes doing I/O, accumulated
pidstat -d 2              # per-process read and write rates
sudo biolatency 10 1      # bcc: a histogram of I/O latency
sudo biosnoop             # bcc: every I/O with process, size, and latency
cat /proc/<pid>/io        # cumulative bytes for one process
```

**`iotop -oPa` is the fastest answer to "who".** `-o` hides idle processes, `-P`
shows processes rather than threads, and `-a` accumulates so a bursty writer does
not hide between samples.

**The eBPF tools are better when you have them**, because they answer questions
the sampling tools cannot. `biolatency` prints a histogram rather than an
average, which is how you see that most requests are fast and a tail is dreadful.
`biosnoop` traces individual operations with the issuing process, and it will
find the one thread doing synchronous writes that a per-second average smooths
away entirely.

**Three patterns worth recognising:**

**High `await` with low `w/s`.** The device is slow rather than busy. Suspect
failing hardware, a degraded array rebuilding, or shared storage where somebody
else is the load. `dmesg` for I/O errors and `smartctl` per lesson 70.

**High `w/s` with low `wkB/s`.** Small random writes. The workload is
IOPS-bound, so the fix is a faster device class or fewer, larger operations, not
more bandwidth. Very often it is an application doing unbatched commits, and the
real fix is in the application.

**`f/s` and `f_await` non-trivial**, as in the capture above at 82.5 ms. Those
are flush operations, and they are how a database forces data to durable media.
Slow flushes throttle every commit, which presents as a slow application with an
idle-looking disk. A write cache without battery backup, or a filesystem
barrier, is usually behind it.

**And the scheduler is worth a glance** on anything with a mixed workload:

```bash
cat /sys/block/sda/queue/scheduler        # which one is active
cat /sys/block/sda/queue/nr_requests      # queue depth the kernel allows
```

`mq-deadline` gives latency guarantees, `bfq` favours interactive work, and
`none` is right for fast NVMe where the device schedules better than the kernel
can. A rotational disk left on `none` because someone copied a tuning guide for
SSDs is a real and common misconfiguration.

</details>

## The network half

Network performance problems are harder to see than storage ones because the
failure is usually silent. TCP hides loss by retransmitting, so the application
sees slowness rather than errors, and nothing is logged anywhere.

Start with latency and its spread:

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ echo "--- latency to the gateway, and the spread across 10 probes ---"; ping -c 10 -q -i 0.2 192.168.127.1 2>&1 | tail -3
--- latency to the gateway, and the spread across 10 probes ---
--- 192.168.127.1 ping statistics ---
10 packets transmitted, 10 received, 0% packet loss, time 1868ms
rtt min/avg/max/mdev = 0.239/0.374/0.470/0.064 ms
```

Four numbers, and the last two are the interesting ones. `max` of 0.470 against
an average of 0.374 means nothing stalled. `mdev` of 0.064 is the deviation, and
a small one means the path is consistent.

**Jitter matters more than average latency for anything interactive.** A path
with 40 ms of steady latency is workable, because TCP and applications adapt to
it. A path averaging 20 ms with excursions to 400 produces timeouts, retries,
and audio that breaks up, while its average looks better. When `mdev` is a
significant fraction of `avg`, that is the finding.

**Zero percent loss is the other thing to confirm.** TCP treats loss as
congestion and backs off, so even one percent loss can halve throughput on a
long path. It is not a linear relationship and it surprises people.

Then the interface's own counters:

<details class="predict">
<summary>An interface has carried three and a half million packets. How many errors and drops would a healthy one show?</summary>

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ echo "--- interface counters: errors and drops are what matter ---"; ip -s link show enp0s1 | tail -5
--- interface counters: errors and drops are what matter ---
    RX:  bytes packets errors dropped  missed   mcast           
    4790550016 3464390      0       0       0       0 
    TX:  bytes packets errors dropped carrier collsns           
      76018160  814380      0       0       0       0 
    altname enx5a94efe40cee
```

</details>

Three and a half million packets received, zero errors, zero dropped. That is
what healthy looks like, and it is worth knowing so the unhealthy version is
recognisable.

**`errors` and `dropped` are the columns to read**, and they mean different
things. Errors are malformed or damaged frames, which points at cabling, a
failing NIC, or a duplex mismatch. Drops usually mean the receiver could not keep
up: the ring buffer filled or the kernel had no buffer space. Rising drops with
zero errors is a capacity problem rather than a hardware one.

**`missed` and `overrun` deserve attention on a busy host**, because they mean
the NIC received frames the system could not collect in time. That is a tuning
problem, usually ring buffer size via `ethtool -G` or interrupt handling, and it
appears as random slowness under load.

<details class="deeper">
<summary>If you already administer Linux: measuring throughput honestly, and the things that quietly cap it</summary>

"The network is slow" needs a number before it is a fault, and getting an honest
one takes more care than people expect.

**`iperf3` is the tool**, and it measures the network rather than a disk or an
application:

```bash
iperf3 -s                                  # on one end
iperf3 -c server.example.com -t 30         # on the other
iperf3 -c server -P 8 -t 30                # eight parallel streams
iperf3 -c server -R                         # reverse: measure the other direction
iperf3 -c server -u -b 500M                 # UDP, to see loss and jitter
```

**Test both directions.** Asymmetry is common, especially on consumer links and
through firewalls doing inspection, and testing one way finds half the problems.

**Parallel streams tell you something specific.** If one stream is slow and eight
streams together saturate the link, the limit is per-connection, which points at
TCP window size, latency, or a per-flow shaper rather than at bandwidth.

**The bandwidth-delay product is why a single stream can be slow on a fast link.**
Throughput is bounded by window size divided by round-trip time. On a 1 Gb link
with 100 ms RTT, a 64 KB window gives you about 5 Mb/s no matter how much
capacity exists. Modern kernels scale windows automatically, but a middlebox that
strips the window scaling option, or an application setting its own socket
buffer, reintroduces the limit.

**Things that cap throughput without being "the network":**

- **Disk on either end.** Copying a file measures the slower of the disk and the
  network. `iperf3` avoids this by generating traffic in memory, which is exactly
  why it is the right tool.
- **CPU on either end.** Encryption, or a single-threaded receiver, per lesson 75.
- **MTU**, per lesson 71. Working but suboptimal, or black-holing entirely.
- **Duplex mismatch.** `ethtool eth0` showing half duplex on a switched link is a
  fault, and it produces collisions and terrible throughput while the link works.
- **Shapers and policers.** A rate limit somewhere in the path, which shows as a
  suspiciously round number.

**Bufferbloat is the one that confuses people most**, because the symptom is
latency and the cause is a buffer meant to prevent loss. Oversized queues in a
router hold packets instead of dropping them, TCP never learns to slow down, and
latency climbs to hundreds of milliseconds while throughput looks perfect. The
tell is latency that is fine when idle and dreadful during a transfer. Test by
pinging while running `iperf3` and watching the RTT climb. On Linux the fix is a
modern queue discipline, and `fq_codel` is the default on most distributions
now, which is visible in the `qdisc fq_codel` field of `ip link` output.

**Finally, the socket-level view** when you need to know why one connection is
slow:

```bash
ss -ti                    # per-socket: RTT, congestion window, retransmits
nstat -az | grep -i retrans
```

`ss -ti` reports `rtt`, `cwnd`, and `retrans` per connection. A small congestion
window with retransmits climbing is loss limiting that specific connection, and
that is a much sharper finding than "the network is slow".

</details>

<details class="deeper">
<summary>If you already administer Linux: remote storage, where the network becomes a disk problem</summary>

NFS, iSCSI, and cloud block storage put a network in the middle of every I/O
operation, which means a network fault presents as a storage fault and gets
investigated on the wrong layer.

**The symptom is distinctive:** `await` is high, the local device counters look
unremarkable, and processes pile up in `D` state per lesson 69. The disk is not
slow. The path to it is.

**For NFS, `nfsstat` and `mountstats` are the tools that answer this:**

```bash
nfsstat -c                          # client counts by operation
mountstats --nfs /mnt/share         # per-operation timings, the useful one
nfsiostat 2                          # like iostat, per NFS mount
```

`mountstats` gives average RTT and execution time per operation type, which
separates "the server is slow to answer" from "the network is slow to carry it".
A high RTT with low server execution time is a network problem; the reverse is
the server.

**Retransmissions are the number that matters.** `nfsstat -c` reports retrans,
and anything non-trivial means requests are being lost and resent, which
multiplies latency invisibly.

**The mount options change the failure mode entirely**, and this is the part
worth deciding deliberately:

- **`hard`** (the default) retries forever. A dead server leaves processes stuck
  in `D` state permanently, unkillable, and the machine can end up needing a
  reboot. It guarantees data integrity, which is why it is the default.
- **`soft`** returns an error after `retrans` attempts. Processes survive, and
  writes can fail silently in ways applications handle badly. Reasonable for
  read-only mounts, risky for anything else.
- **`intr`** used to allow signals to interrupt a hard mount. It is a no-op on
  modern kernels, which handle this differently, so advice recommending it is
  out of date.
- **`_netdev`** in fstab, per lesson 67, so the mount waits for the network.

**For cloud block storage the trap is the throttle.** Volumes have provisioned
IOPS and throughput limits, and crossing one produces latency that looks exactly
like a failing disk. `iostat` shows rising `await` with a queue, the hardware is
perfect, and the fix is a bigger volume or a different volume type. Burst credit
exhaustion is the same thing with a delay: excellent performance for an hour,
then a cliff. Check the provider's metrics alongside the guest's, because the
guest cannot see the throttle that is causing it.

**And on any shared storage, remember you are not the only tenant.** A SAN or a
cloud volume performing badly with no local explanation may simply be busy for
somebody else, which is unsatisfying and is the answer more often than people
like.

</details>

## Baselines

Every number in this lesson is uninterpretable on its own. `await` of 8 ms is
excellent for a mechanical disk and alarming for NVMe. Load of 12 is a crisis on
a 4-core machine and normal on a 64-core one.

So collect the ordinary numbers while nothing is wrong. It takes minutes and it
is the difference between "this looks high" and "this is four times what it was
last Tuesday":

```bash
iostat -xd 60 5 > /var/tmp/baseline-io.txt
ping -c 100 -q <gateway> >> /var/tmp/baseline-net.txt
iperf3 -c <peer> -t 30 >> /var/tmp/baseline-net.txt
```

Better still, keep the metrics from lesson 64 so the comparison is a graph rather
than a text file. Either way, the point stands: **exceeding a baseline is a
finding, and a number without one is an opinion.**

## Across distributions

Almost nothing here is a family difference, because these numbers come from the
block layer and the network stack. What differs is which measuring tools are
present, and every one of them is worth installing before you need it.

| | RHEL family | Debian family |
| --- | --- | --- |
| `iostat`, `sar`, `pidstat` | `sysstat`, **install it** | `sysstat`, **install it** |
| `fio` | `fio`, from AppStream | `fio` |
| `iperf3` | `iperf3` | `iperf3` |
| `ss`, `ip -s link` | `iproute2`, installed | `iproute2`, installed |
| Default I/O scheduler, NVMe | `none` | `none` |
| Default I/O scheduler, rotational | `mq-deadline` | `mq-deadline` |
| Default queue discipline | `fq_codel` | `fq_codel` |
| Tuning profiles | `tuned`, with `tuned-adm profile` | `tuned` available, not installed |

**`tuned` is the row worth knowing exists.** On the RHEL family it is installed
and active with a profile chosen at install time, so a machine may already be
tuned for throughput, for latency, or for virtual guests, and
`tuned-adm active` tells you which. That profile changes the I/O scheduler,
readahead, and several sysctls underneath you, which is a genuinely surprising
thing to discover partway through a benchmark.

Both families default to `fq_codel` for the queue discipline, which matters
because it is the fix for bufferbloat. If you meet latency climbing under load on
a modern machine, check `tc qdisc show` before assuming the default is the
problem: the default is usually fine, and the oversized buffer is often in the
router rather than on the host.

## Prove it

Storage and network split cleanly, so run whichever half the symptom points at:

```bash
# Storage: the columns that mean something, in order of usefulness
iostat -xz 1 5
#   aqu-sz  requests waiting: the saturation signal
#   await   per-operation latency including queueing
#   r/s w/s and rkB/s wkB/s  operation count against bandwidth
#   %util   time with a request in flight, misleading on NVMe and arrays

# Which process is doing the I/O
sudo iotop -bon2 2>/dev/null | head -15
pidstat -d 1 3

# Measure the device honestly, bypassing the page cache
sudo fio --name=t --filename=/tmp/t --size=1G --bs=4k --rw=randread \
         --direct=1 --numjobs=4 --runtime=30 --time_based --group_reporting

# Network: per-connection latency and retransmits
ss -ti | grep -A1 ESTAB | head
ip -s link show eth0            # errors against dropped

# Throughput without a disk in the way, both directions
iperf3 -c theserver
iperf3 -c theserver -R
```

**`aqu-sz` is the column to read first and `%util` is the one to distrust.**
%util counts time with at least one request outstanding, which meant something on
a disk that served one request at a time and means very little on a device that
handles dozens in parallel. A persistent queue with rising `await` is saturation;
100 percent `%util` on NVMe may be a device that is barely working.

## What trips people up

### 1. Treating `%util` at 100 percent as a full device

It is the single most misread number in `iostat`. On NVMe, on a RAID array, and
on any SAN volume it can sit at 100 percent while the device has capacity to
spare. Read `aqu-sz` and `await` instead.

### 2. Confusing an IOPS limit with a throughput limit

16,000 writes per second at 66 MB/s is about 4 KB per operation, which is an
operation-count limit rather than a bandwidth one. More bandwidth changes
nothing; a faster device class or an application that batches its writes does.
Divide the two numbers before deciding what to buy.

### 3. Benchmarking with `dd`

Single threaded, sequential, and without `oflag=direct` it measures the page
cache rather than the disk. It is the easiest possible pattern and it flatters
every device. `fio` with `--direct=1` and a realistic block size, mix, and job
count measures the thing you actually run.

### 4. Reading an average latency and stopping

Ping showing 20 ms average and 400 ms maximum is not a 20 ms link. Jitter causes
timeouts and retries even when the mean looks healthy, so read `mdev` from `ping`
and the per-connection RTT from `ss -ti`.

### 5. Treating `errors` and `dropped` as the same counter

`errors` counts frames the hardware could not accept: CRC failures, a duplex
mismatch, a bad cable. `dropped` counts frames that arrived intact with nowhere
to go, which is a buffer or capacity problem. Rising drops with zero errors
points away from the cabling entirely.

### 6. Reading a number without a baseline

An `await` of 8 ms is excellent for a spinning disk and alarming for NVMe. 400
MB/s is good for one and poor for another. Without a figure from the same
hardware when it was healthy, a measurement is an opinion, which is the argument
for recording one on a quiet day.

## Work it through

A file server feels slow to users every night between 01:00 and 03:00. The
throughput graph for that period looks better than during the day, and the disks
are not full.

Reason it out before reading on.

**First, notice that the graph is the clue rather than the contradiction.**
Higher throughput alongside worse responsiveness is the signature of queueing:
something is keeping the device busy with large amounts of work, and every small
interactive request waits behind it.

```bash
iostat -xz 1 5
```

Look at `aqu-sz` and `await` rather than at `%util` or the transfer rates. A deep
queue with `await` in the tens of milliseconds, while throughput is high, is
saturation.

**Second, find what runs at 01:00.** The window is too precise to be organic:

```bash
systemctl list-timers --all
sudo iotop -bon2 | head -15
```

A backup, a database dump, or a `mandb` rebuild is the usual answer.

**Third, decide which of the two limits it is hitting**, because it changes the
fix:

```bash
iostat -x 1 5      # compare w/s against wkB/s
```

Large sequential writes at high bandwidth means the job is using the device
properly and simply competing. Small operations at high count means it is
spending the operation budget, and batching would help both jobs.

**Fourth, fix it as a contention problem rather than a storage problem.** Nothing
here is broken. The options are to move the job, to slow it down deliberately
with `ionice -c2 -n7` or a systemd `IOReadBandwidthMax=`, or to give it its own
device. Buying faster storage also works and treats a scheduling decision as a
hardware shortage.

The reasoning that transfers: throughput and latency rise together under
queueing, so a throughput graph alone can make a contention incident look like a
healthy night. Latency is what users experience, and it is the number that should
have been on the graph.

## Try it

Optional. A VM is fine, and the numbers will be strange, which is itself part of
the lesson about baselines.

1. Run `dd if=/dev/zero of=/tmp/f bs=1M count=2000` and note the rate. Run it
   again with `oflag=direct` and compare. The gap between them is the page cache.
2. Run `fio` with `--bs=4k --rw=randread --direct=1` and again with `--bs=1M
   --rw=read`. Compare IOPS against MB/s in the two results and work out which
   limit each pattern hit.
3. While a `fio` job runs, watch `iostat -xz 1` in another terminal. Find
   `aqu-sz` and `await` climbing, and note what `%util` does at the same time.
4. Run `ping` to your gateway while starting a large upload, and watch the
   round-trip time. Note `mdev` in the summary line at the end.

**Verification step.** Step 3 is right when you can say what `%util` read at the
moment the queue was deepest, and explain why that number would have misled you
if it had been the only one on the dashboard.

## For the exam

**IOPS for small random work, throughput for large sequential work.** They are
different limits with different fixes.

**`aqu-sz` is the saturation signal.** A persistent queue means the device is the
constraint.

**`%util` is not percent of capacity.** It is time with at least one request in
flight, and it misleads badly on SSDs and arrays.

**`await` is per-operation latency including queueing.** Rising `await` with flat
IOPS means the device is struggling.

**High `w/s` with low `wkB/s` is IOPS-bound**; the fix is a faster device class
or larger operations.

**`fio` measures storage properly**, with `--direct=1` to bypass the page cache.
`dd` only does the easy pattern.

**`iperf3` measures the network** without a disk in the way. Test both
directions.

**Jitter matters more than average latency** for interactive work. Watch `mdev`.

**Interface `errors` suggest hardware; `dropped` suggests the receiver could not
keep up.**

**A small amount of loss costs a lot of TCP throughput**, and not linearly.

**Bufferbloat is latency caused by oversized buffers**, visible as RTT climbing
during a transfer.

<details class="qa">
<summary>Check yourself</summary>

**`iostat` shows `%util` at 100 percent on an NVMe device. Is it saturated?**
Not necessarily. `%util` is the proportion of time at least one request was in
flight, which means little on a device that handles many in parallel. Read
`aqu-sz` and `await` instead.

**Which single column best indicates a device is the bottleneck?**
`aqu-sz`. A persistent queue means requests are waiting behind each other.

**`await` is climbing while IOPS stays flat. What does that mean?**
The device is taking longer to do the same work. Suspect failing hardware, a
rebuilding array, or contention on shared storage.

**A workload shows 16,000 w/s at 66 MB/s. What is it limited by?**
Small operations, so IOPS. 66 MB over 16,000 writes is about 4 KB each. More
bandwidth will not help; a faster device class or batching will.

**Why is `dd` a poor storage benchmark?**
It is single-threaded sequential I/O, the easiest possible pattern, and without
`oflag=direct` it may be measuring the page cache. Use `fio` with a realistic
block size, mix, and job count.

**Backups run at night and the interactive service feels terrible, yet
throughput graphs look great. Why?**
Queueing raises throughput and latency together. The backup fills the queue, so
every interactive request waits behind it.

**Ping shows avg 20 ms and max 400 ms. Is that acceptable?**
Probably not. The spread is the problem. Jitter causes timeouts and retries even
when the average looks fine. Check `mdev`.

**One percent packet loss. How much does it matter to TCP?**
A lot, and not linearly. TCP reads loss as congestion and backs off, so a small
loss rate can halve throughput on a long path.

**Interface counters show rising `dropped` and zero `errors`. What does that
suggest?**
The receiver could not keep up, so a buffer or capacity problem rather than
hardware. Errors would point at cabling, the NIC, or a duplex mismatch.

**Single-stream transfer is slow, eight parallel streams saturate the link.
What does that tell you?**
The limit is per-connection: window size, latency, or a per-flow shaper. Total
bandwidth is not the constraint.

**A 1 Gb link with 100 ms RTT gives 5 Mb/s on one stream. Why?**
Bandwidth-delay product. Throughput is bounded by window size over round-trip
time, so a small window caps a high-latency link regardless of capacity.

**Latency is fine when idle and terrible during a large transfer. What is that?**
Bufferbloat. Oversized queues hold packets rather than dropping them, so TCP
never backs off and delay accumulates. `fq_codel` is the usual fix.

**Which command shows per-connection RTT and retransmits?**
`ss -ti`.

**Why is a baseline necessary?**
Because the same number can be excellent or alarming depending on the hardware
and the workload. Exceeding a baseline is a finding; a number alone is an
opinion.

</details>

## Where this sits

Lesson 75 identified which resource is constrained and pointed here whenever `b`
or `wa` was high. This lesson is what to do once storage or the network is the
answer. Lesson 70 takes over when the disk is not slow but failing, and lesson 71
owns connectivity as opposed to performance.

That completes the troubleshooting block, and with it the material for domain 5.


## References

- [iostat(1)](https://man7.org/linux/man-pages/man1/iostat.1.html) - man7.org. Accessed 2026-08-09.
- [Kernel documentation: block layer statistics](https://docs.kernel.org/block/stat.html) - kernel.org. Accessed 2026-08-09.
- [ping(8)](https://man7.org/linux/man-pages/man8/ping.8.html) - man7.org. Accessed 2026-08-09.
- [fio documentation](https://fio.readthedocs.io/en/latest/fio_doc.html) - fio. Accessed 2026-08-09.
> **The commands here were run on a real machine, not written from memory.** The
> `iostat` figures come from AlmaLinux 10.2 on aarch64, with eight processes
> writing 4 KB blocks with `oflag=direct` to an ext4 filesystem on a loop device,
> sampled while they were still running. The queue depth of 4.53 and 61.83 percent
> utilisation are what that produced. The ping statistics and interface counters
> are from the Fedora CoreOS VM, and the zero errors against three and a half
> million packets is genuinely what a healthy interface looks like.
