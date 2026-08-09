---
title: "The answer is in a file you have never opened"
description: "Logs are not a wall of text to be scrolled. They are a queryable record with time, severity, and origin attached, and knowing four filters turns half an hour of scrolling into one command that returns six lines."
track: "linux-plus"
level: "working"
order: 660
objectives:
  - "Filter the journal by unit, time, priority, and boot"
  - "Say where a message goes and why some are in files and some are not"
  - "Read the structured fields behind a log line"
  - "Correlate events across sources by timestamp"
  - "Explain why a timestamp can lie, and what to do about it"
prerequisites: ["systemd-targets-timers-and-journal", "text-processing"]
tags: ["linux", "linux-plus", "troubleshooting", "logging", "journald"]
updated: 2026-08-09
draft: false
examObjectives:
  - exam: "xk0-006"
    domain: "5.0"
    objective: "5.1"
sources:
  - title: "journalctl(1)"
    url: "https://www.freedesktop.org/software/systemd/man/latest/journalctl.html"
    publisher: "freedesktop.org"
    accessed: 2026-08-09
    tier: 1
  - title: "systemd.journal-fields(7)"
    url: "https://www.freedesktop.org/software/systemd/man/latest/systemd.journal-fields.html"
    publisher: "freedesktop.org"
    accessed: 2026-08-09
    tier: 1
  - title: "journald.conf(5)"
    url: "https://www.freedesktop.org/software/systemd/man/latest/journald.conf.html"
    publisher: "freedesktop.org"
    accessed: 2026-08-09
    tier: 1
  - title: "syslog(3), facilities and severities"
    url: "https://man7.org/linux/man-pages/man3/syslog.3.html"
    publisher: "man7.org"
    accessed: 2026-08-09
    tier: 1
symptoms:
  - symptom: "Log file exists but contains nothing useful for the failure"
    anchor: "where-a-message-actually-goes"
  - symptom: "Events in two logs appear to happen in the wrong order"
    anchor: "correlating-across-sources"
  - symptom: "Journal is empty after a reboot"
    anchor: "narrowing-by-boot"
---

> **Before you read.** Something failed twenty minutes ago. You know roughly
> when, roughly which service, and nothing else. There are perhaps forty
> thousand log lines from that period on this machine.
>
> **You are not going to read them.** The skill is not patience, it is knowing
> which four filters cut forty thousand lines down to six.

Most people meet logs as an undifferentiated wall of text and develop a habit of
`tail -f` plus hope. The journal is a structured store with time, severity,
origin, and boot attached to every entry, and treating it as a database rather
than a file is the whole difference.

### Some words you will need

<dl class="terms">
<dt>journal</dt>
<dd>systemd's binary, indexed log store. Queried with <code>journalctl</code>, not read with an editor.</dd>
<dt>unit</dt>
<dd>The service an entry came from. The most useful single filter.</dd>
<dt>priority</dt>
<dd>Severity, 0 (emerg) to 7 (debug). Lower is worse.</dd>
<dt>facility</dt>
<dd>The syslog category: auth, cron, daemon, kern, mail.</dd>
<dt>boot ID</dt>
<dd>Identifies one boot of the machine, so you can ask about the boot that crashed.</dd>
<dt>structured field</dt>
<dd>Metadata attached to an entry, such as <code>_PID</code> or <code>_SELINUX_CONTEXT</code>. Queryable.</dd>
<dt>rsyslog</dt>
<dd>The traditional daemon that writes plain text files under <code>/var/log</code>.</dd>
<dt>stack trace</dt>
<dd>The call path a program was executing when it failed. Read bottom-up for the cause.</dd>
</dl>

## What breaks without this

**The evidence expires.** A journal that is not persistent is discarded at
reboot, so the log of the crash disappears when somebody reboots to fix the
crash.

**You read the wrong log.** Time is spent in `/var/log/messages` for a service
that logs only to the journal, and its silence is mistaken for having nothing to
say.

**Timestamps mislead.** Two machines a few seconds apart produce an ordering
that suggests the effect preceded the cause.

**Scrolling replaces searching.** Without filters, investigation is reading, and
reading does not scale past a few thousand lines.

**The first error is missed.** The screen shows the last error, which is
frequently a consequence of the first one, several hundred lines earlier.

## The four filters

Nearly every log investigation is a combination of four things. Learn these and
the rest is detail.

| Filter | Flag | Example |
| --- | --- | --- |
| **Which service** | `-u` | `journalctl -u nginx` |
| **When** | `--since` / `--until` | `journalctl --since "-30min"` |
| **How bad** | `-p` | `journalctl -p err` |
| **Which boot** | `-b` | `journalctl -b -1` |

They combine, and combining them is the point:

```bash
journalctl -u nginx -p err --since "2026-08-08 14:00" --until "2026-08-08 14:30"
```

That is the whole technique. One service, errors only, a thirty-minute window.

**`--since` accepts human phrasing**, which matters more than it sounds because
it removes the friction that stops people filtering at all: `-1h`, `-30min`,
`yesterday`, `today`, `09:00`, and full timestamps all work.

Here it is against a real unit, with ISO timestamps so they are unambiguous:

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ echo "--- narrowing by time and by unit at once ---"; journalctl -u sshd --since "-30min" --no-pager -o short-iso | tail -4
--- narrowing by time and by unit at once ---
2026-08-08T22:34:08-05:00 localhost.localdomain sshd-session[609291]: pam_unix(sshd:session): session opened for user core(uid=501) by core(uid=0)
2026-08-08T22:34:08-05:00 localhost.localdomain sshd-session[609291]: pam_unix(sshd:session): session closed for user core
2026-08-08T22:34:08-05:00 localhost.localdomain sshd-session[609335]: Accepted publickey for core from 192.168.127.1 port 19760 ssh2: ED25519 SHA256:Pb+UHMFS8gTLYJ9IfkbVWV+wDgYDjr9iE3vaNXm1POI
2026-08-08T22:34:08-05:00 localhost.localdomain sshd-session[609335]: pam_unix(sshd:session): session opened for user core(uid=501) by core(uid=0)
```

**`-o short-iso` is worth making a habit.** The default format omits the year and
the timezone offset, which is fine until you are comparing against a log from
somewhere else, and then it is the source of an hour of confusion.

### Priority, and the useful trick

Priorities run 0 to 7, and `-p` means "this level **and worse**", not "this
level exactly".

| Number | Name | Means |
| --- | --- | --- |
| 0 | `emerg` | System is unusable |
| 1 | `alert` | Act immediately |
| 2 | `crit` | Critical |
| 3 | `err` | Error. **The usual starting point** |
| 4 | `warning` | Warning |
| 5 | `notice` | Normal but significant |
| 6 | `info` | Informational. Most of the volume |
| 7 | `debug` | Debug |

**`journalctl -p err -b` is the single most valuable command in this lesson.**
Everything at error or worse, this boot, in one screen:

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ echo "--- errors and worse, this boot ---"; journalctl -p err -b --no-pager | tail -6
--- errors and worse, this boot ---
                                                                #0  0x0000ffffac33b88c n/a (/usr/lib64/libc.so.6 + 0x3b88c)
                                                                #1  0x0000aaaab539776c user_command_matches (/usr/bin/bash + 0xa776c)
                                                                #2  0x0000aaaae5d3ac30 n/a (n/a + 0x0)
                                                                ELF object binary architecture: AARCH64
Aug 08 22:15:08 localhost.localdomain objective_visvesvaraya[587819]: /bin/sh: line 1:     2 Segmentation fault      (core dumped) sh -c "kill -SEGV \$\$"
Aug 08 22:22:20 localhost.localdomain kernel: Memory cgroup out of memory: Killed process 595735 (dd) total-vm:6052kB, anon-rss:1212kB, file-rss:2180kB, shmem-rss:0kB, UID:501 pgtables:52kB oom_score_adj:0
```

**Six lines, and they are a complete account of everything that went wrong.**
This machine is the one the other lessons were captured on, so what it found is
the evidence those lessons left behind: the segfault from lesson 69, the stack
trace `systemd-coredump` recorded for it, and the container OOM kill from lesson
75. The odd name in the middle, `objective_visvesvaraya`, is a random container
name podman assigned.

**Two things worth noticing about that output.** The stack frames are indented
continuation lines of one multi-line entry, so an entry is not always a line.
And the OOM kill is logged by the **kernel**, not by the process that died,
which is exactly why the application's own log said nothing.

## Narrowing by boot

`-b` selects a boot. `-b` alone is the current one; `-b -1` is the previous one,
which is what you want when a machine has rebooted and you need to know why.

<details class="predict">
<summary>This machine has been rebooted more than once. Does its journal still hold the logs from before those reboots?</summary>

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ echo "--- how much journal there is, and how far back it goes ---"; journalctl --disk-usage; journalctl --list-boots --no-pager | tail -3
--- how much journal there is, and how far back it goes ---
Archived and active journals take up 173.9M in the file system.
 -2 4deecf7538d74e608cdb644b4c853e72 Fri 2026-08-07 14:14:40 CDT Fri 2026-08-07 23:12:07 CDT
 -1 0c5a4845793041e4ae090aa26818a7f3 Sat 2026-08-08 11:40:59 CDT Sat 2026-08-08 13:20:25 CDT
  0 07613d8ef7bb4c44aecf74ce263f383d Sat 2026-08-08 13:21:02 CDT Sat 2026-08-08 22:34:08 CDT
```

</details>

**Three boots are available, so this journal is persistent.** That is the
precondition for `-b -1` meaning anything, and it is not the default
everywhere.

If `--list-boots` shows only boot 0, the journal is in memory and everything
before the last reboot is gone. Persistence is a directory:

```bash
sudo mkdir -p /var/log/journal
sudo systemd-tmpfiles --create --prefix /var/log/journal
sudo systemctl restart systemd-journald
```

Do that on any machine you will ever have to diagnose, before you need it. The
commonest version of this problem is an engineer rebooting a wedged machine
and destroying the only record of why it wedged.

<details class="predict">
<summary>A journal entry looks like one line of text. How much does journald actually store alongside it?</summary>

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ echo "--- one unit, with the fields the journal actually stores ---"; journalctl -u sshd -n 1 --no-pager -o verbose 2>/dev/null | head -22
--- one unit, with the fields the journal actually stores ---
Sat 2026-08-08 22:33:07.785012 CDT [s=1ca7a8734e3a46dd92067201e4a11ac2;i=371b3;b=07613d8ef7bb4c44aecf74ce263f383d;m=547300942;t=65894e56cdd45;x=c4015ddc5d41315d]
    PRIORITY=6
    _BOOT_ID=07613d8ef7bb4c44aecf74ce263f383d
    _MACHINE_ID=fbe3cf662cb64de7a1d91f9d0cad9413
    _HOSTNAME=localhost.localdomain
    _RUNTIME_SCOPE=system
    _CAP_EFFECTIVE=1ffffffffff
    _UID=0
    _GID=0
    _SYSTEMD_SLICE=system.slice
    _TRANSPORT=syslog
    _SELINUX_CONTEXT=system_u:system_r:sshd_session_t:s0-s0:c0.c1023
    SYSLOG_FACILITY=10
    SYSLOG_IDENTIFIER=sshd-session
    _COMM=sshd-session
    _EXE=/usr/libexec/openssh/sshd-session
    _CMDLINE="sshd-session: core [priv]"
    _SYSTEMD_CGROUP=/system.slice/sshd.service
    _SYSTEMD_UNIT=sshd.service
    _SYSTEMD_INVOCATION_ID=87a3c48b1883457dba2dc70706140e5b
    MESSAGE=pam_unix(sshd:session): session opened for user core(uid=501) by core(uid=0)
    SYSLOG_TIMESTAMP=Aug  8 22:33:07 
```

</details>

Twenty fields for one line of message text, and this is the part that makes
the journal a different kind of thing from a text file.

The leading underscore is the important convention. Fields starting with `_`
are **trusted**: journald derived them from the kernel about the sending
process, and an application cannot forge them. `MESSAGE` and
`SYSLOG_IDENTIFIER` come from the application and can say anything. In a
security investigation that distinction is the difference between evidence and
assertion.

And every one of these fields is queryable, which is the real payoff:

```bash
journalctl _UID=1000                    # everything from one user
journalctl _COMM=sshd                   # by command name
journalctl _SYSTEMD_UNIT=nginx.service  # exactly what -u does underneath
journalctl _PID=609335                  # one process
journalctl SYSLOG_FACILITY=10           # the auth facility
journalctl _BOOT_ID=0c5a48...           # a specific boot
```

Combine two fields and they are ANDed; repeat one field and the values are ORed.
`journalctl _COMM=sshd _COMM=sudo` gives you both.

<details class="deeper">
<summary>If you already administer Linux: where a message actually goes, and why a log file can be empty</summary>

"Check the logs" assumes one destination. There are several, and knowing the
paths explains why a service can appear to log nothing.

**Four ways a message reaches the journal:**

- **`_TRANSPORT=stdout`**: the service wrote to stdout or stderr and systemd
  captured it. The modern default, and why a containerised app needs no logging
  configuration at all.
- **`_TRANSPORT=syslog`**: the process called `syslog(3)`. The sshd entry above
  is this one.
- **`_TRANSPORT=journal`**: it used the native API, which is how an application
  attaches its own structured fields.
- **`_TRANSPORT=kernel`**: from the kernel ring buffer. `journalctl -k` is
  shorthand for this, and is `dmesg` with timestamps and persistence.

And two ways it does not:

- **The application writes its own file**, bypassing everything. nginx's
  `access.log`, most databases, and anything with a `logfile` directive. The
  journal will be silent about it and that is not a fault.
- **rsyslog reads the journal and writes text** into `/var/log/messages`,
  `/var/log/secure`, and friends. On a machine running both, entries exist
  twice, in two formats, with two retention policies.

Which produces the most common wasted half hour: reading `/var/log/messages`
on a system where rsyslog is not installed. Many minimal and
container-oriented images ship without it, so `/var/log` is nearly empty and
the journal has everything. Check with `systemctl is-active rsyslog` before
concluding a service is silent.

The `/var/log` layout still worth knowing, because plenty of machines have it:

| Path | Holds |
| --- | --- |
| `/var/log/messages` or `/var/log/syslog` | General catch-all |
| `/var/log/secure` or `/var/log/auth.log` | Authentication, sudo, sshd |
| `/var/log/cron` | Scheduled jobs |
| `/var/log/maillog` | Mail |
| `/var/log/boot.log` | Early boot |
| `/var/log/audit/audit.log` | auditd, not journald. Its own format entirely |
| `/var/log/httpd/`, `/var/log/nginx/` | Application-written, journald uninvolved |

The RHEL family uses `messages` and `secure`; Debian uses `syslog` and
`auth.log`. That split accounts for a lot of "the file does not exist" on the
wrong distribution.

**Two journald settings worth setting deliberately** in
`/etc/systemd/journald.conf`:

- **`Storage=persistent`** so it survives reboots, as above.
- **`SystemMaxUse=`** so it cannot fill the disk. Without it journald takes up to
  10% of the filesystem, which on a large disk is a lot. `journalctl
  --vacuum-size=500M` or `--vacuum-time=30d` reclaims space now, and is the
  supported way rather than deleting files.

**And `journalctl --verify`** checks the journal's integrity. On a machine
suspected of disk trouble, a corrupt journal is both a symptom and a reason to
distrust what you just read.

</details>

## Correlating across sources

Once more than one machine is involved, the investigation becomes about lining
up timelines, and this is where logs quietly mislead.

**Establish the window first.** Get one timestamp you trust, from the alert, a
user report, or a request ID, then widen a few minutes either side.

```bash
journalctl --since "14:05" --until "14:12" -o short-iso        # everything, all units
journalctl --since "14:05" --until "14:12" -p warning -o short-iso
```

Look at everything before filtering by unit. The cause is frequently in a
different service from the symptom, and filtering to the service that
complained is how you miss it.

Three things that make timestamps lie:

- **Clock skew.** Two machines a few seconds apart produce an order that is
  simply wrong. `timedatectl` shows whether NTP is synchronised, and `chronyc
  tracking` shows by how much. Fix this before drawing conclusions.
- **Time zones.** The journal displays in local time by default while most
  application logs are UTC, and the offset is exactly the kind of error that
  reverses cause and effect. `journalctl --utc` puts everything in UTC, and
  `-o short-iso` shows the offset explicitly.
- **Buffering.** A log line's timestamp is when it was *written*, which for a
  buffered writer can be well after the event. A process that crashed may never
  have flushed its last buffer at all, so the absence of a final message is
  not evidence.

Prefer the kernel's own clock for hardware events. `journalctl -k` entries
come from the ring buffer with monotonic timestamps, which cannot be skewed by
NTP stepping the wall clock.

<details class="deeper">
<summary>If you already administer Linux: reading a stack trace, and searching logs without drowning</summary>

A stack trace reads bottom-up for the cause and top-down for the location. The
bottom frame is where execution started; the top frame is where it died. The
useful line is usually the topmost frame that belongs to *your* code rather
than to a library, because the library is nearly always doing what it was
asked.

In the capture above, `user_command_matches (/usr/bin/bash + 0xa776c)` is the
only frame with a symbol, and `n/a` frames mean no debug symbols were
available. Installing the matching `-debuginfo` package turns those into
function names, per lesson 69.

**The exception line matters more than the trace.** `NullPointerException at
line 47` tells you more than forty frames of framework. Read the message, then
find the first frame in your own package.

Searching logs without drowning, roughly in order of how often each earns its
keep:

```bash
journalctl -u app --grep 'timeout|refused' -p warning     # journald's own regex, with a priority floor
journalctl -u app -o cat | grep -c ERROR                  # count first, read second
journalctl -u app --since -1h -o cat | sort | uniq -c | sort -rn | head
```

That last one is the highest-value habit in this section. Collapsing an hour
of logs into "how many of each distinct line" turns a wall of text into a
ranked list, and the anomaly is usually either the line with a surprisingly
high count or the one that appears exactly once.

For text files the same shape applies, with the addition that you can go
backwards:

```bash
tac /var/log/messages | grep -m1 -B5 -A20 'ERROR'    # the LAST error, with context
awk '$0 >= "14:05" && $0 <= "14:12"' /var/log/messages
zgrep 'error' /var/log/messages-*.gz                  # rotated files, still compressed
```

**`grep -B` and `-A` are the difference between a matching line and an
understandable one.** An error alone is rarely enough; the five lines before it
usually contain what it was doing.

**And know the difference between the first error and the last.** The screen
shows you the last. The first is the cause, and `grep -m1` from the start of the
incident window is how you find it. A cascade of a hundred errors usually has
one origin, several hundred lines earlier, and everything after it is noise
about consequences.

</details>

<details class="deeper">
<summary>If you already administer Linux: the messages that were never written, and shipping logs off the box</summary>

Two things will make you distrust a log, and both are worth knowing before they
cost you an investigation.

**journald rate-limits by default, and it says so quietly.** `RateLimitBurst=`
(10000) within `RateLimitIntervalSec=` (30s) is applied **per service**. A
service that floods past it has messages dropped, and the only trace is a line
saying so:

```text
Suppressed 4382 messages from /system.slice/app.service
```

Which means **the absence of a log line is not evidence that the event did not
happen**, precisely during the incident when the service was noisiest. If you
are diagnosing a flood, raise the limits or set `RateLimitIntervalSec=0` on that
unit before concluding anything from a gap.

**And a log on the failed machine may be unreachable when you need it.** A disk
that filled, a kernel panic, a host that was terminated by the cloud provider,
or a compromise where the first thing an attacker does is truncate
`/var/log/secure`. A local log is evidence held by the suspect.

So logs get shipped, and the vocabulary is worth having:

| Piece | Does |
| --- | --- |
| **Shipper** | Reads local logs and forwards them. `rsyslog`, `vector`, `fluent-bit`, `promtail`, `filebeat` |
| **Transport** | Syslog over TCP or TLS, or HTTP. UDP 514 is the legacy default and drops silently under load |
| **Store** | Elasticsearch/OpenSearch, Loki, or a vendor's platform |
| **Query** | Kibana, Grafana, or the vendor's search |

**`systemd-journal-upload`** ships the journal itself, preserving the structured
fields, which is worth preferring over reformatting to plain syslog and losing
them.

Three things that go wrong with centralised logging, all of them common:

- **Time.** Every shipper stamps with the local clock. Without NTP everywhere,
  the merged timeline is fiction. This is the single biggest cause of
  correlation errors across a fleet.
- **Volume and cost.** Log volume grows with traffic and platforms charge by
  ingest. The instinct is to sample or drop debug, and the risk is dropping the
  thing you needed. Decide by value, not by level.
- **Integrity.** If a compromised host ships its own logs, an attacker can
  simply stop the shipper. Forwarding to a host the source cannot log in to,
  append-only storage, and alerting on a shipper going quiet are what make logs
  admissible rather than merely available.

Which is the security-side point worth carrying, and it connects to lesson 50:
for audit purposes, a log is only as trustworthy as the path it took to get
somewhere the subject of the log cannot reach.

</details>

## The order to work in

1. **Establish a time window** you trust, and check for clock skew before
   trusting it.
2. **`journalctl -p err -b`** for everything bad since boot. Frequently the
   whole answer.
3. **Widen to the window across all units**, not just the service that
   complained.
4. **Find the *first* error**, not the last. The rest is usually consequence.
5. **Narrow to the unit** once you know which one, and read with `-B5 -A20` of
   context.
6. **Check whether the application logs elsewhere.** An empty journal for a
   service with its own log file means nothing.
7. **Confirm the journal is persistent** before rebooting anything, or the
   evidence goes with it.

## Across distributions

`journalctl` is the portable half and behaves identically everywhere. The text
logs underneath it are where the families part company, and a habit built on one
family fails silently on the other.

| | RHEL family | Debian family |
| --- | --- | --- |
| Authentication and `sudo` | `/var/log/secure` | `/var/log/auth.log` |
| General text log | `/var/log/messages` | `/var/log/syslog` |
| Journal commands | identical | identical |
| Syslog facility for auth | `authpriv` | `authpriv` |
| Rotation | `logrotate`, `/etc/logrotate.d` | `logrotate`, `/etc/logrotate.d` |
| Text logs present at all | `rsyslog`, usually installed | `rsyslog`, absent from minimal images |

**The last row causes more confusion than the naming does.** A container or a
minimal cloud image may have no `rsyslog` at all, so `/var/log/messages` and
`/var/log/syslog` are both missing and `grep` on either returns nothing. The
machine is logging perfectly well, into the journal, and the file you reached for
was never going to exist. `journalctl` first, files second, is the habit that
survives moving between machines.

Persistence is worth checking rather than assuming, because it varies by
distribution and by how minimal the image is. `ls -d /var/log/journal` answers it
in one command, and if the directory is absent the journal lives in memory and
yesterday's evidence went away with yesterday's boot.

## Prove it

Before reading a journal, establish that you are reading all of it:

```bash
# Is it persistent, and how far back does it actually go
ls -d /var/log/journal 2>/dev/null || echo "volatile: this boot only"
journalctl --list-boots | head

# Everything that failed this boot
journalctl -p err -b --no-pager

# Are you seeing the whole journal, or your own slice of it
journalctl --disk-usage
journalctl --verify | tail -3

# Is journald dropping messages before they ever reach you
journalctl -b | grep -i "Suppressed"

# Do the machines you are correlating agree about the time
timedatectl
chronyc tracking 2>/dev/null | head -3
```

**The suppression check is the one nobody runs.** journald rate limits a service
that floods it, and the only record is a single line saying messages were
dropped. If your timeline has a hole in it, that line explains the hole, and
without it you will spend an hour theorising about a service that was talking the
whole time.

## What trips people up

### 1. Reading the last error rather than the first

The end of a failure is full of consequences. A hundred errors in five minutes is
usually one cause and ninety-nine effects, and the first entry in the sequence is
the one worth your attention.

### 2. Expecting `-b -1` to work on a volatile journal

Without `/var/log/journal`, the journal is in `/run` and the previous boot went
away when the machine restarted. `--list-boots` showing only boot 0 is the tell.
Make it persistent before you need it, because there is no way to recover a boot
that was never written down.

### 3. Reading `-p err` as "errors only"

Priority is a threshold, not a selector. `-p err` gives you error, critical,
alert, and emergency, and `-p warning` includes all of those plus warnings. That
is what you want almost always, and it surprises people who expect an exact
match.

### 4. Grepping text logs on a machine that has none

`grep: /var/log/messages: No such file or directory` on a working server usually
means no `rsyslog`, not a broken machine. It is also how people conclude a
service logs nothing when it is logging into the journal perfectly well.

### 5. Deleting journal files by hand

journald still holds them open, so the space does not come back and the journal
can be left inconsistent. `journalctl --vacuum-size=500M` or `--vacuum-time=30d`
is the supported route, and `SystemMaxUse=` in `journald.conf` stops it
recurring.

### 6. Trusting timestamps across machines

Two hosts with drifting clocks produce a timeline where the effect precedes the
cause, and you will believe it. Check `timedatectl` on both, watch for time zone
differences in the display, and use `--utc` or `-o short-iso` so the offset is
written down rather than assumed.

## Work it through

A service failed overnight. `journalctl -u api` since yesterday returns eleven
hundred lines and the last forty are all the same connection error.

Reason it out before reading on.

**Stop reading the end.** The repeated connection error at the tail is the
service failing over and over after something already broke. Go to the front of
the failure instead:

```bash
journalctl -u api -p err -b --no-pager | head -5
```

Say the first error is at 02:14 and reads `could not translate host name "db" to
address`, while everything after 02:14 is the connection error repeating.

**Widen from the unit to the machine at that moment.** A unit's own log
only shows what the unit noticed, and a name resolution failure is rarely the
application's fault:

```bash
journalctl --since 02:10 --until 02:20 --no-pager
```

This is the step that finds the thing the service could not see, such as a
network interface reconfiguring or `systemd-resolved` restarting.

**The useful question is what changed, not what is wrong.** The service ran until
02:14, so the useful question is what happened at 02:14:

```bash
journalctl -k --since 02:10 --until 02:20    # kernel: link state, hardware
journalctl -u systemd-resolved --since 02:10 --until 02:20
```

**The reasoning that matters** is that eleven hundred lines contained one piece
of information and a great deal of repetition. Filtering by priority found it in
one command, and moving from the unit's log to the machine's log at that
timestamp is what turned a symptom into a cause.

If two machines are involved, do the clock check before building any timeline.
Correlating a 02:14 event on one host with a 02:11 event on another is worthless
if one of them is three minutes out.

## Try it

Optional, and a VM or container is plenty.

1. Run `ls -d /var/log/journal`. If it is missing, create it, restart
   `systemd-journald`, reboot, and confirm `journalctl --list-boots` now lists
   more than one boot. That single change is the difference between diagnosing an
   overnight reboot and guessing at it.
2. Compare `journalctl -p err -b` against `journalctl -b | grep -i error`. Note
   which lines each one finds that the other misses, and why the grep version
   catches the word "error" inside messages that are not errors.
3. Take an hour of one unit's log and rank it:
   `journalctl -u <unit> --since -1h -o cat | sort | uniq -c | sort -rn | head`.

**Verification step.** Step 3 is working when the top line is something dull that
repeats thousands of times, and the interesting entry is near the bottom with a
count of one. That inversion is the whole technique: in a log, rarity is the
signal.

## For the exam

**`journalctl -u <unit>`** filters by service.

**`-p err`** means error and worse, not error exactly. 0 emerg to 7 debug.

**`-b`** is this boot, **`-b -1`** the previous one, which needs a persistent
journal.

**`--since` and `--until`** take human phrasing as well as timestamps.

**`journalctl -k`** is the kernel ring buffer, the same content as `dmesg`.

**Persistence is `/var/log/journal` existing**, or `Storage=persistent`.

**Fields beginning with `_` are trusted metadata** added by journald; the rest
comes from the application.

**`/var/log/secure` on RHEL is `/var/log/auth.log` on Debian.**

**`journalctl --vacuum-size=` reclaims space**; deleting journal files by hand
does not.

<details class="qa">
<summary>Check yourself</summary>

**Which one command shows everything that went wrong since boot?**
`journalctl -p err -b`.

**Does `-p warning` include errors?**
Yes. `-p` means that priority and everything more severe.

**A machine rebooted overnight and you need the logs from before it. What do
you need, and what might stop you?**
`journalctl -b -1`. It only works if the journal is persistent. If
`--list-boots` shows only boot 0, the previous boot is gone.

**How do you make the journal persistent?**
Create `/var/log/journal` (or set `Storage=persistent`) and restart
`systemd-journald`. Do it before you need it.

**A service's journal is empty but the service is clearly running. Why?**
It probably writes its own log file, like nginx or most databases. Or you are
reading `/var/log/messages` on a machine with no rsyslog installed.

**What is the difference between `MESSAGE` and `_COMM` in a journal entry?**
`_COMM` has a leading underscore, so journald derived it from the kernel and the
application cannot forge it. `MESSAGE` is whatever the application wrote.

**How do you see every field on an entry?**
`journalctl -o verbose`.

**Show everything logged by user ID 1000.**
`journalctl _UID=1000`.

**Two machines disagree about the order of two events. What do you check?**
Clock skew, with `timedatectl` and `chronyc tracking`, and time zones. Use
`--utc` or `-o short-iso` so offsets are explicit.

**Why prefer `journalctl -k` timestamps for hardware events?**
They come from the kernel's monotonic clock, which NTP cannot step.

**A hundred errors in five minutes. Which do you read?**
The first one. The other ninety-nine are usually consequences.

**How do you turn an hour of logs into a ranked summary?**
`journalctl -u app --since -1h -o cat | sort | uniq -c | sort -rn | head`.
The anomaly is the surprisingly frequent line or the one appearing once.

**How do you read a stack trace?**
Bottom-up for the cause, and look for the topmost frame in your own code. The
exception message usually matters more than the frames.

**The journal is filling the disk. What is the supported fix?**
`journalctl --vacuum-size=` or `--vacuum-time=`, and set `SystemMaxUse=` in
`journald.conf`. Do not delete files under `/var/log/journal` by hand.

</details>

## Where this sits

Lesson 34 introduced the journal as a place logs live. This lesson treats it as
a thing you query. Lesson 63's method needs evidence, and this is where the
evidence is; lessons 69 and 75 both end with a journal command, and the capture
above is literally the trace those two lessons left on this machine.

The next lesson goes to the case where the machine does not get far enough to
have a journal at all.


## References

- [journalctl(1)](https://www.freedesktop.org/software/systemd/man/latest/journalctl.html) - freedesktop.org. Accessed 2026-08-09.
- [systemd.journal-fields(7)](https://www.freedesktop.org/software/systemd/man/latest/systemd.journal-fields.html) - freedesktop.org. Accessed 2026-08-09.
- [journald.conf(5)](https://www.freedesktop.org/software/systemd/man/latest/journald.conf.html) - freedesktop.org. Accessed 2026-08-09.
- [syslog(3), facilities and severities](https://man7.org/linux/man-pages/man3/syslog.3.html) - man7.org. Accessed 2026-08-09.
> **The commands here were run on a real machine, not written from memory.** The
> transcripts come from Fedora CoreOS 44.20260707.3.1 on aarch64, a virtual
> machine with 173.9 MB of accumulated journal across three boots. The errors
> found by `journalctl -p err -b` are genuinely the wreckage left by the other
> captures in this track: the segfault is the one from lesson 69, and the cgroup
> OOM kill is the container from lesson 75. Nothing was staged for this lesson,
> which is why a random podman container name appears in the middle of it.
