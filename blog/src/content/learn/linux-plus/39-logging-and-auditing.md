---
title: "Something happened at 3am and nobody saw it"
description: "Two logging systems run on every modern Linux machine, and auditd is a third thing that is not logging at all. Which to reach for, how to read a syslog selector, why unrotated logs fill a disk, and what auditd records that nothing else does."
track: "linux-plus"
level: "working"
order: 400
objectives:
  - "Query the journal by unit, boot, time window, and priority"
  - "Explain why the journal and rsyslog coexist, and say which to reach for"
  - "Read a syslog selector and predict which file a message lands in"
  - "Rotate logs deliberately, and diagnose a disk that filled anyway"
  - "Write an audit rule and read the accounting record it produces"
prerequisites: ["systemd-targets-timers-and-journal", "authentication-and-pam"]
tags: ["linux", "linux-plus", "logging", "journald", "rsyslog", "auditd", "security"]
updated: 2026-08-08
draft: false
examObjectives:
  - exam: "xk0-006"
    domain: "3.0"
    objective: "3.1"
  - exam: "xk0-006"
    domain: "5.0"
    objective: "5.1"
sources:
  - title: "journalctl(1)"
    url: "https://man7.org/linux/man-pages/man1/journalctl.1.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-08
    tier: 1
  - title: "journald.conf(5)"
    url: "https://man7.org/linux/man-pages/man5/journald.conf.5.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-08
    tier: 1
  - title: "syslog(3)"
    url: "https://man7.org/linux/man-pages/man3/syslog.3.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-08
    tier: 1
  - title: "logger(1)"
    url: "https://man7.org/linux/man-pages/man1/logger.1.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-08
    tier: 1
  - title: "rsyslog.conf(5)"
    url: "https://manpages.debian.org/trixie/rsyslog/rsyslog.conf.5.en.html"
    publisher: "Debian manpages"
    accessed: 2026-08-08
    tier: 1
  - title: "logrotate(8)"
    url: "https://man7.org/linux/man-pages/man8/logrotate.8.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-08
    tier: 1
  - title: "auditctl(8)"
    url: "https://man7.org/linux/man-pages/man8/auditctl.8.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-08
    tier: 1
  - title: "ausearch(8)"
    url: "https://man7.org/linux/man-pages/man8/ausearch.8.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-08
    tier: 1
symptoms:
  - symptom: "journalctl shows nothing from before the last reboot"
    anchor: "2-expecting-the-journal-to-survive-a-reboot"
  - symptom: "No space left on device but the log files look small"
    anchor: "4-rotating-a-log-the-daemon-still-holds-open"
  - symptom: "ausearch prints no matches"
    anchor: "3-ausearch-returns-no-matches"
---

> **Before you read.** At 09:00 somebody notices a configuration file has changed on a
> production server. The backup taken at 02:00 has the old contents, so it happened in
> the seven hours between, and nobody was watching.
>
> You type `journalctl`. Forty-six thousand lines for this boot alone. You try `grep`
> in `/var/log` instead, and the file you wanted was rotated and compressed at 04:00
> by something you did not know ran.
>
> **Where is the record of who changed that file, and does this machine even keep
> one?**

The honest answer on most machines: the journal knows a great deal about *services*
and nothing about *files*, the text logs in `/var/log` hold whatever a daemon chose to
say out loud, and the one subsystem that would have recorded the write itself was
running with no rules loaded.

Three systems, three jobs. This lesson is which is which, why two of them overlap
enough that people assume one is a copy of the other, and how to make the third answer
the question in the box.

### Some words you will need

<dl class="terms">
<dt>journal</dt>
<dd>systemd's log store. Binary, indexed, structured into named fields, split by boot. Read with <code>journalctl</code>, never with an editor.</dd>
<dt>syslog</dt>
<dd>The much older convention of tagging a message with a facility and a severity and handing it to a daemon that decides where to write it.</dd>
<dt>facility</dt>
<dd>Roughly "which part of the system is speaking": <code>auth</code>, <code>cron</code>, <code>mail</code>, <code>kern</code>, <code>daemon</code>.</dd>
<dt>severity</dt>
<dd>How bad it is, from <code>emerg</code> down to <code>debug</code>. Also called the priority.</dd>
<dt>selector</dt>
<dd>A <code>facility.severity</code> pair in an rsyslog rule, paired with a destination.</dd>
<dt>rotation</dt>
<dd>Renaming a log, starting a fresh one, and deleting the oldest, so a log does not grow without limit.</dd>
<dt>auditd</dt>
<dd>The user-space daemon for the kernel's audit subsystem, which records system calls rather than messages.</dd>
<dt>accounting</dt>
<dd>The third A in AAA: the durable record of what an authenticated, authorized user actually did.</dd>
</dl>

## What breaks without this

**Nobody can answer "what happened at 3am".** Not because the evidence was never
recorded, but because nobody knows which of three stores to open, or that the third
one exists.

**A disk fills and takes the machine with it.** `/var` at 100 percent stops databases
committing, stops journald writing, and stops the logs that would explain it.

**You grep files that do not exist.** On a modern minimal system `/var/log/messages`
is simply absent, and an empty result reads exactly like "nothing happened".

**The intruder deletes the evidence**, because the only copy was on the machine they
had root on, and that is the first thing anybody competent does.

## Two logs on every machine

A modern Linux machine runs **two log systems at once**, and they are not copies of
each other.

<figure class="learn-figure">
<svg viewBox="0 0 740 330" role="img" aria-labelledby="log-title log-desc" style="width:100%;height:auto;">
<title id="log-title">How messages reach the journal, the text logs, and the audit log</title>
<desc id="log-desc">Three sources feed systemd-journald: the kernel ring buffer at /dev/kmsg, the standard output and standard error of services, and calls to syslog from the C library arriving on /dev/log. Journald stores everything in a structured, binary, indexed store under /var/log/journal, which journalctl reads. Rsyslog, where it is installed, takes a second copy of the same messages and applies selector rules to write plain text files such as /var/log/syslog and /var/log/auth.log. Separately, the kernel audit subsystem sends syscall records over a netlink socket to auditd, which writes /var/log/audit/audit.log; journald also receives a copy of those audit records, which is why the same event can appear in both places.</desc>
<g font-family="ui-monospace, monospace">
<rect x="12" y="16" width="170" height="40" rx="5" fill="currentColor" fill-opacity="0.12" stroke="currentColor" stroke-opacity="0.4"/>
<text x="97" y="34" text-anchor="middle" font-size="11" fill="currentColor">kernel ring buffer</text>
<text x="97" y="48" text-anchor="middle" font-size="9.5" fill="currentColor" fill-opacity="0.65">/dev/kmsg</text>
<rect x="12" y="66" width="170" height="40" rx="5" fill="currentColor" fill-opacity="0.12" stroke="currentColor" stroke-opacity="0.4"/>
<text x="97" y="84" text-anchor="middle" font-size="11" fill="currentColor">service stdout</text>
<text x="97" y="98" text-anchor="middle" font-size="9.5" fill="currentColor" fill-opacity="0.65">whatever a unit prints</text>
<rect x="12" y="116" width="170" height="40" rx="5" fill="currentColor" fill-opacity="0.12" stroke="currentColor" stroke-opacity="0.4"/>
<text x="97" y="134" text-anchor="middle" font-size="11" fill="currentColor">syslog() from libc</text>
<text x="97" y="148" text-anchor="middle" font-size="9.5" fill="currentColor" fill-opacity="0.65">/dev/log</text>
<rect x="12" y="236" width="170" height="40" rx="5" fill="currentColor" fill-opacity="0.12" stroke="currentColor" stroke-opacity="0.4"/>
<text x="97" y="254" text-anchor="middle" font-size="11" fill="currentColor">kernel audit</text>
<text x="97" y="268" text-anchor="middle" font-size="9.5" fill="currentColor" fill-opacity="0.65">netlink socket</text>
<rect x="232" y="16" width="150" height="140" rx="5" fill="currentColor" fill-opacity="0.07" stroke="currentColor" stroke-opacity="0.3"/>
<text x="307" y="60" text-anchor="middle" font-size="12" fill="currentColor">systemd-journald</text>
<text x="307" y="86" text-anchor="middle" font-size="9.5" fill="currentColor" fill-opacity="0.65">structured fields</text>
<text x="307" y="102" text-anchor="middle" font-size="9.5" fill="currentColor" fill-opacity="0.65">binary and indexed</text>
<text x="307" y="118" text-anchor="middle" font-size="9.5" fill="currentColor" fill-opacity="0.65">split by boot</text>
<rect x="232" y="236" width="150" height="40" rx="5" fill="currentColor" fill-opacity="0.07" stroke="currentColor" stroke-opacity="0.3"/>
<text x="307" y="254" text-anchor="middle" font-size="12" fill="currentColor">auditd</text>
<text x="307" y="268" text-anchor="middle" font-size="9.5" fill="currentColor" fill-opacity="0.65">a separate daemon</text>
<rect x="432" y="16" width="150" height="54" rx="5" fill="currentColor" fill-opacity="0.12" stroke="currentColor" stroke-opacity="0.4"/>
<text x="507" y="38" text-anchor="middle" font-size="11" fill="currentColor">/var/log/journal</text>
<text x="507" y="55" text-anchor="middle" font-size="9.5" fill="currentColor" fill-opacity="0.65">journalctl queries it</text>
<rect x="432" y="102" width="150" height="54" rx="5" fill="currentColor" fill-opacity="0.12" stroke="currentColor" stroke-opacity="0.4"/>
<text x="507" y="124" text-anchor="middle" font-size="11" fill="currentColor">rsyslog</text>
<text x="507" y="141" text-anchor="middle" font-size="9.5" fill="currentColor" fill-opacity="0.65">selectors decide</text>
<rect x="432" y="236" width="150" height="40" rx="5" fill="currentColor" fill-opacity="0.12" stroke="currentColor" stroke-opacity="0.4"/>
<text x="507" y="254" text-anchor="middle" font-size="11" fill="currentColor">/var/log/audit/</text>
<text x="507" y="268" text-anchor="middle" font-size="9.5" fill="currentColor" fill-opacity="0.65">audit.log</text>
<text x="616" y="118" font-size="11" fill="currentColor">/var/log/syslog</text>
<text x="616" y="134" font-size="11" fill="currentColor">/var/log/auth.log</text>
<text x="616" y="150" font-size="9.5" fill="currentColor" fill-opacity="0.65">plain text, greppable</text>
<text x="196" y="206" font-size="9.5" fill="currentColor" fill-opacity="0.65">journald takes a copy of the audit stream too</text>
</g>
<g stroke="currentColor" stroke-opacity="0.45" fill="none" stroke-width="1.2">
<path d="M182 36 L206 36 L206 60 L228 60 M222 56 L229 60 L222 64"/>
<path d="M182 86 L228 86 M222 82 L229 86 L222 90"/>
<path d="M182 136 L206 136 L206 112 L228 112 M222 108 L229 112 L222 116"/>
<path d="M382 43 L428 43 M422 39 L429 43 L422 47"/>
<path d="M382 129 L428 129 M422 125 L429 129 L422 133"/>
<path d="M582 129 L610 129 M604 125 L611 129 L604 133"/>
<path d="M182 256 L228 256 M222 252 L229 256 L222 260"/>
<path d="M382 256 L428 256 M422 252 L429 256 L422 260"/>
<path d="M97 236 L97 196 L188 196 L188 148 L228 148 M222 144 L229 148 L222 152" stroke-dasharray="4 3"/>
</g>
</svg>
<figcaption>Everything funnels into journald. Rsyslog is a second consumer that writes plain text. Auditd is a different subsystem, and only journald hears both.</figcaption>
</figure>

**Journald is the collection point.** It listens on several inputs at once and stamps
every message with the unit, process, user, boot, and a monotonic timestamp. A running
machine will tell you which inputs it is using:

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ journalctl -F PRIORITY; echo ---; journalctl -F _TRANSPORT
2
3
4
7
5
6
---
audit
syslog
stdout
journal
driver
kernel
```

`journalctl -F <field>` lists every value a field has taken, which is the fastest
survey of a machine you have never seen. **Six transports, and reading them is reading
the diagram:** `kernel` is the ring buffer, `stdout` is a unit's output, `syslog` is
the `/dev/log` socket, `journal` is an application calling the native API, `driver` is
journald talking about itself, and `audit` is the kernel audit subsystem.

The `PRIORITY` list matters too. This boot produced 2 through 7 and **no 0 or
1**, no `emerg`, no `alert`. Those numbers are the syslog severity scale,
which is the first sign that the journal did not replace syslog so much as
swallow it.

**Rsyslog is the second consumer**, and it writes plain text files using rules you can
read. The overlap is deliberate: the journal is what you query, and the text files are
what you `grep`, ship to a collector, and keep for a year.

They are genuinely separable, and one machine here proves it:

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ systemctl is-active auditd; systemctl is-active rsyslog 2>&1; rpm -q audit rsyslog 2>&1
active
inactive
audit-4.1.4-1.fc44.aarch64
package rsyslog is not installed
```

**`package rsyslog is not installed`.** A current Fedora-derived image with a journal,
an audit daemon, and no syslog daemon at all. That is why `tail -f /var/log/messages`
on a modern minimal system produces nothing: the file was never created, because
nothing was ever going to write it.

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ journalctl --disk-usage; echo ---; ls -ld /var/log/journal; echo ---; ls /var/log/
Archived and active journals take up 76M in the file system.
---
drwxr-sr-x+ 3 root systemd-journal 46 Aug  7 14:14 /var/log/journal
---
README
audit
btmp
chrony
dnf5.log
journal
lastlog
private
qemu-ga
rhsm
samba
sssd
wtmp
```

**No `messages`, no `secure`, no `syslog`.** What is there: `journal`, a directory of
binary files; `audit`, the audit daemon's own directory; and `btmp`, `wtmp`, and
`lastlog`, three fixed-format binary files older than all of this, read with `lastb`,
`last`, and `lastlog`. Everything else is a service that chose to write its own file.

<details class="deeper">
<summary>If you already administer Linux: persistent versus volatile, and why one directory is the entire switch</summary>

`Storage=auto` is journald's default, and `auto` means one specific thing: **write to
`/var/log/journal` if that directory exists, and to `/run/log/journal` if it does
not.** `/run` is a tmpfs, so a journal there is erased at every boot.

That is the whole mechanism. There is no enable command, and on the machine
above the shipped `journald.conf` contains a section header and no settings at
all, because every value is a compiled-in default the vendor did not need to
override. So "is the journal persistent here" is answered by `ls -d
/var/log/journal`, and turning it on is `mkdir -p /var/log/journal` plus
`systemctl restart systemd-journald`, or `Storage=persistent`, which creates
the directory itself and is the honest way to write the intent down.

**Check it on every machine you inherit, before you need it.** Discovering the journal
was volatile *after* the crash you were investigating is the single most common reason
`journalctl -b -1` comes back empty.

Set the size controls at the same time. `SystemMaxUse=` caps the total and defaults to
10 percent of the filesystem, capped at 4 GB; `SystemKeepFree=` reserves headroom;
`MaxRetentionSec=` discards by age. To trim now, `journalctl --vacuum-size=200M` or
`--vacuum-time=30d`, both of which only ever delete *archived* journal files and never
the one being written.

The trap for anyone arriving from text logs: **journald is not rotated by logrotate
and does not respect it.** A file in `/etc/logrotate.d` for the journal does nothing.
The journal rotates itself, and its limits live in `journald.conf`.

</details>

## Reading the journal

Lesson 34 introduced `journalctl`. This is the part that matters under time
pressure: **four filters, and they compose.** `-u` for a unit, `-b` for a
boot, `--since` and `--until` for a window, `-p` for severity, plus `-f` to
follow and `-n` for the last few. Start with a unit, because that is usually
what you have:

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ journalctl -u chronyd.service -b -n 6 --no-pager
Aug 08 11:41:09 localhost.localdomain chronyd[902]: System clock TAI offset set to 37 seconds
Aug 08 12:24:42 localhost.localdomain chronyd[902]: Forward time jump detected!
Aug 08 12:24:42 localhost.localdomain chronyd[902]: Can't synchronise: no selectable sources (0 unreachable sources)
Aug 08 12:26:52 localhost.localdomain chronyd[902]: Selected source 162.159.200.1 (2.fedora.pool.ntp.org)
Aug 08 12:27:32 localhost.localdomain chronyd[902]: Selected source 5.78.139.245 (2.fedora.pool.ntp.org)
Aug 08 12:27:56 localhost.localdomain chronyd[902]: Selected source 162.159.200.1 (2.fedora.pool.ntp.org)
```

**`-u` plus `-b` is the workhorse pair**, and that is a real finding rather than
filler: `Forward time jump detected!` followed by `Can't synchronise` is the clock
moving under the machine, which is exactly what makes timestamps from two hosts
disagree during an investigation.

`--since` and `--until` take `yesterday`, `-1h`, `09:00`, or `2026-08-08 12:00:00`.
**Use both.** `--since` alone on a busy machine still returns everything up to now.

Severity is the filter people under-use. `-p err` means **err and everything worse**,
not err exactly:

| Number | Name | Means |
| --- | --- | --- |
| 0 | `emerg` | The system is unusable |
| 1 | `alert` | Act immediately |
| 2 | `crit` | Critical condition |
| 3 | `err` | An error |
| 4 | `warning` | A warning |
| 5 | `notice` | Normal but significant |
| 6 | `info` | Informational |
| 7 | `debug` | Debugging detail |

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ journalctl -b -p err --no-pager | head -12
Aug 08 11:44:07 localhost.localdomain eager_rubin[2666]: cat: /data/report.txt: Permission denied
Aug 08 11:48:59 localhost.localdomain elastic_gagarin[3990]: ldap_sasl_bind(SIMPLE): Can't contact LDAP server (-1)
Aug 08 11:49:03 localhost.localdomain zealous_yonath[3801]: Error: DBUS_ERROR: Failed to connect to socket /run/dbus/system_bus_socket: No such file or directory
Aug 08 11:50:22 localhost.localdomain xenodochial_torvalds[12693]: OpenSSH_10.0p2 Debian-7+deb13u4, OpenSSL 3.5.6 7 Apr 2026
Aug 08 11:51:34 localhost.localdomain great_pasteur[24614]: Pseudo-terminal will not be allocated because stdin is not a terminal.
Aug 08 11:51:34 localhost.localdomain great_pasteur[24614]: Warning: Permanently added 'localhost' (ED25519) to the list of known hosts.
Aug 08 11:51:34 localhost.localdomain great_pasteur[24614]: sam@localhost: Permission denied (publickey,password).
Aug 08 11:53:11 localhost.localdomain xenodochial_jepsen[42859]: @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
Aug 08 11:53:11 localhost.localdomain xenodochial_jepsen[42859]: @         WARNING: UNPROTECTED PRIVATE KEY FILE!          @
Aug 08 11:53:11 localhost.localdomain xenodochial_jepsen[42859]: @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
Aug 08 11:53:11 localhost.localdomain xenodochial_jepsen[42859]: Permissions 0644 for '/root/.ssh/id_ed25519' are too open.
Aug 08 11:53:11 localhost.localdomain xenodochial_jepsen[42859]: It is required that your private key files are NOT accessible by others.
```

That is a machine's whole error history for a boot, and it reads like a summary of
this track: an SELinux denial from lesson 44, an LDAP bind failure from lesson 38, and
a private key with permissions too open from lesson 43.

<details class="predict">
<summary>This boot's journal holds 46,541 lines. Given that <code>-p</code> selects a severity and everything worse, roughly how many lines should <code>-p warning..err</code> return, and what does the ratio say about reading logs from the top?</summary>

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ journalctl -p warning..err -b --no-pager | wc -l; echo ---; journalctl -b --no-pager | wc -l
112
---
46541
```

</details>

**112 out of 46,541**, a quarter of one percent. Reading a log from the top is not a
technique; **starting at `-p warning` and widening** is. The range form `-p
warning..err` exists so you can exclude the `crit` and `emerg` noise a dying machine
produces while you study what led up to it.

The other axis is boots. `journalctl --list-boots` numbers them, `IDX 0` is
the current one, and negative numbers go backwards, which gives the most
valuable command available after an unexplained restart:

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ journalctl -b -1 -n 3 --no-pager; echo "--- kernel ring buffer, this boot ---"; journalctl -k -b -n 3 --no-pager
Aug 07 23:12:07 localhost.localdomain systemd-shutdown[1]: Sending SIGTERM to remaining processes...
Aug 07 23:12:07 localhost.localdomain systemd-journald[1193]: Received SIGTERM from PID 1 (systemd-shutdow).
Aug 07 23:12:07 localhost.localdomain systemd-journald[1193]: Journal stopped
--- kernel ring buffer, this boot ---
Aug 08 12:59:55 localhost.localdomain kernel: veth1 (unregistering): left allmulticast mode
Aug 08 12:59:55 localhost.localdomain kernel: veth1 (unregistering): left promiscuous mode
Aug 08 12:59:55 localhost.localdomain kernel: podman0: port 2(veth1) entered disabled state
```

**`Received SIGTERM from PID 1` and `Journal stopped`** is a clean shutdown, recorded
by the log system in the act of stopping. A machine that lost power or panicked ends
its previous boot mid-sentence instead, and telling those two endings apart is usually
the first real fact in an outage review.

**`-k` is `dmesg` with the journal's filters attached.** Same kernel messages, except
`-k -b -1` reaches the previous boot, which `dmesg` cannot do because the ring buffer
does not survive a restart.

All of this works because a journal entry is not a line of text. It is a record with
named fields:

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ journalctl -u chronyd.service -n 1 -o verbose --no-pager
Sat 2026-08-08 12:27:56.969503 CDT [s=1ca7a8734e3a46dd92067201e4a11ac2;i=fd31;b=0c5a4845793041e4ae090aa26818a7f3;m=a68504ce;t=6588c7121ca3b;x=d451fc6d3f49f561]
    PRIORITY=6
    SYSLOG_FACILITY=3
    _SYSTEMD_SLICE=system.slice
    _TRANSPORT=syslog
    _MACHINE_ID=fbe3cf662cb64de7a1d91f9d0cad9413
    _RUNTIME_SCOPE=system
    SYSLOG_IDENTIFIER=chronyd
    _COMM=chronyd
    _EXE=/usr/bin/chronyd
    _CMDLINE=/usr/sbin/chronyd -n -F 2
    _SELINUX_CONTEXT=system_u:system_r:chronyd_t:s0
    _SYSTEMD_CGROUP=/system.slice/chronyd.service
    _SYSTEMD_UNIT=chronyd.service
    _UID=994
    _GID=992
    _CAP_EFFECTIVE=2000400
    _HOSTNAME=localhost.localdomain
    _BOOT_ID=0c5a4845793041e4ae090aa26818a7f3
    SYSLOG_PID=902
    _PID=902
    _SYSTEMD_INVOCATION_ID=5733792e1ef14f2f8ebe3eb272a5859d
    MESSAGE=Selected source 162.159.200.1 (2.fedora.pool.ntp.org)
    SYSLOG_TIMESTAMP=Aug  8 12:27:56 
    _SOURCE_REALTIME_TIMESTAMP=1786210076969503
```

**Everything the default output throws away is here.** `_SYSTEMD_UNIT` is attached by
journald rather than parsed out of the message; `_PID`, `_UID`, and `_GID` are the
process identity; `_EXE` and `_CMDLINE` are what was really running;
`_SELINUX_CONTEXT` is the domain from lesson 44; `_BOOT_ID` is why `-b` works.

**Fields with a leading underscore are trusted.** Journald sets them from the
kernel and from the sending socket and the sender cannot forge them. Fields
without one (`MESSAGE`, `PRIORITY`, `SYSLOG_FACILITY`) came from the
application and are exactly as trustworthy as the application. In an
investigation that line decides which half of a record is evidence.

And note `SYSLOG_FACILITY=3` with `PRIORITY=6` on a chronyd message: facility 3 is
`daemon`, priority 6 is `info`. **The journal keeps the syslog metadata even on a
machine with no syslog daemon**, which is the mechanical reason the two can stand in
for one another.

<details class="deeper">
<summary>If you already administer Linux: field matches, <code>-o json</code>, and the queries that make the format worth its opacity</summary>

Anything in that verbose output is a filter. `journalctl FIELD=value` matches exactly,
and several on one line are ANDed:

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ journalctl _SYSTEMD_UNIT=chronyd.service -n 3 --no-pager; echo ---; journalctl _PID=1 -n 3 --no-pager
Aug 08 12:26:52 localhost.localdomain chronyd[902]: Selected source 162.159.200.1 (2.fedora.pool.ntp.org)
Aug 08 12:27:32 localhost.localdomain chronyd[902]: Selected source 5.78.139.245 (2.fedora.pool.ntp.org)
Aug 08 12:27:56 localhost.localdomain chronyd[902]: Selected source 162.159.200.1 (2.fedora.pool.ntp.org)
---
Aug 08 12:58:34 localhost.localdomain systemd[1]: Started session-936.scope - Session 936 of User core.
Aug 08 12:58:34 localhost.localdomain systemd[1]: session-936.scope: Deactivated successfully.
Aug 08 12:58:34 localhost.localdomain systemd[1]: Started session-937.scope - Session 937 of User core.
```

**`_SYSTEMD_UNIT=` is not the same as `-u`, and the difference bites.** `-u
nginx` is a convenience that also pulls in messages *about* the unit written
by PID 1 ("Started", "Failed with result") plus attributed coredumps.
`_SYSTEMD_UNIT=nginx.service` is strict: only records journald tagged with
that unit. When `-u` is showing you systemd's opinion and you wanted the
service's own output, the underscore form is the one you want.

The others worth memorising: `_COMM=` for a command name whatever started it, `_UID=`
for one user's activity, `_TRANSPORT=audit` for the audit stream alone, and `_EXE=`
when several units run the same binary.

For anything programmatic, ask for the structure rather than the rendering.
`-o json` emits one object per line for `jq`; `-o export` is the binary
serialisation `systemd-journal-remote` accepts. Both carry `__CURSOR`, an
opaque handle to an exact position, so a shipper can resume with
`--after-cursor` after a restart without duplicating or dropping entries, a
guarantee `tail -f` on a text file cannot make.

**The operational reason to care** is that field matching does not scan. Journald
keeps per-field indexes, so `_SYSTEMD_UNIT=x` on a multi-gigabyte journal stays fast
in a way `grep` across a directory of rotated, gzipped text never does.

</details>

## Where rsyslog fits, and what a selector is

If the journal has everything, why is rsyslog still on most servers? Because **a text
file is a universal interface.** `grep`, `awk`, a decade-old collection agent, an SIEM
connector, and the auditor who wants one file for last March all consume text and none
of them speak the journal's format. Rsyslog also does the thing journald deliberately
does not: forward to another host, with filtering, queueing, and TLS.

Its configuration is a list of **selectors**, and Debian ships a file that explains
itself:

```bash
# Debian 13 (trixie), x86_64
$ sed -n '/#### RULES ####/,$p' /etc/rsyslog.conf | head -22
#### RULES ####
###############

#
# Log anything besides private authentication messages to a single log file
#
*.*;auth,authpriv.none		-/var/log/syslog

#
# Log commonly used facilities to their own log file
#
auth,authpriv.*			/var/log/auth.log
cron.*				-/var/log/cron.log
kern.*				-/var/log/kern.log
mail.*				-/var/log/mail.log
user.*				-/var/log/user.log

#
# Emergencies are sent to everybody logged in.
#
*.emerg				:omusrmsg:*
```

Every rule is `facility.severity<tab>destination`. Four things to read:

- **`auth,authpriv.*` to `/var/log/auth.log`**, two facilities, any severity,
  one file. Commas list facilities.
- **`*.*;auth,authpriv.none` to `-/var/log/syslog`**, everything *except*
  those two. `;` chains selectors and `.none` subtracts.
- **The leading `-`** means do not flush to disk after every line: faster, and a few
  lines can be lost in a crash. `auth.log` has no dash, deliberately.
- **`*.emerg` to `:omusrmsg:*`**, write to every logged-in user's terminal,
  which is where the wall-of-text-on-your-console tradition comes from.

The facilities are a fixed list from the 1980s whose names have drifted from their
meanings, so they are learned rather than derived:

| Facility | Number | Used for |
| --- | --- | --- |
| `kern` | 0 | Kernel messages |
| `user` | 1 | Generic user-level messages, the `logger` default |
| `mail` | 2 | Mail system |
| `daemon` | 3 | Other system daemons |
| `auth` | 4 | Login and authorization |
| `syslog` | 5 | The log daemon talking about itself |
| `cron` | 9 | Scheduled jobs |
| `authpriv` | 10 | Authentication, private enough to restrict the file's mode |
| `local0` to `local7` | 16 to 23 | Yours. Nothing in the base system uses them. |

**`auth` versus `authpriv` is the pair worth knowing.** Both are authentication;
`authpriv` exists so messages carrying usernames and failure detail can go to a file
that is not world-readable. That is why Debian sends both to `auth.log` and then
excludes both from the general `syslog` file.

`logger` puts a message into the system yourself, which is how you test a rule and how
a shell script logs properly:

```bash
# Debian 13 (trixie), x86_64
$ rsyslogd; sleep 1; logger -p auth.warning 'test message'; sleep 1; tail -3 /var/log/auth.log
rsyslogd: imklog: cannot open kernel log (/proc/kmsg): Permission denied.
rsyslogd: activation of module imklog failed [v8.2504.0 try https://www.rsyslog.com/e/2145 ]
2026-08-08T17:37:20.543621+00:00 bd320de6eb28 root: test message
```

**Two of those lines are an error and both are true.** `imklog` reads kernel messages
from `/proc/kmsg`, and a container is not permitted to open it because a container has
no kernel of its own. Kernel logging is a host concern, always. Everything else
started anyway, which is why the third line is the message landing in `auth.log`
exactly as the selector promised.

Now test the exclusion. On a container where a login has actually happened:

```bash
# Debian 13 (trixie), x86_64
$ grep -c 'session opened' /var/log/auth.log /var/log/syslog
/var/log/auth.log:1
/var/log/syslog:0
```

**One and zero.** The `.none` worked. This matters more than it looks: search
`/var/log/syslog` on a Debian machine for a failed login and you will find nothing,
forever, and conclude the login was never attempted.

Severity is a **threshold**, not an equality. `local3.err` catches err and worse:

```bash
# Debian 13 (trixie), x86_64
$ cat /etc/rsyslog.d/10-critical.conf; logger -p local3.info "routine"; logger -p local3.err "disk failing"; logger -p local3.crit "controller gone"; sleep 3; echo "--- what landed in critical.log ---"; cat /var/log/critical.log
local3.err			/var/log/critical.log
--- what landed in critical.log ---
2026-08-08T18:18:01.929155+00:00 a3e3c310dc18 root: disk failing
2026-08-08T18:18:01.954470+00:00 a3e3c310dc18 root: controller gone
```

**Three sent, two arrived.** `info` did not match because it is *less* severe than the
threshold. For one severity exactly the syntax is `local3.=err`, and to exclude one it
is `local3.!=err`. Almost every rule written by mistake is written by forgetting that
the plain form is a threshold.

Put your own rules in `/etc/rsyslog.d/*.conf` rather than editing `rsyslog.conf`,
because an upgrade replaces the main file and leaves the directory alone.

<details class="deeper">
<summary>If you already administer Linux: send logs off the box, because deleting them is the intruder's first move</summary>

Every log so far lives on the machine that produced it, and root there can rewrite all
of it. An attacker who leaves your local logs intact was not trying.

**Remote logging is the countermeasure**, and one rsyslog line does it:

```
*.*  @@logs.example.com:6514
```

`@@` is TCP and a single `@` is UDP. UDP drops silently under load and needs no
handshake, which is fine for volume and useless for evidence; TCP with a disk-assisted
queue buffers through a collector outage instead of losing. TLS via
`$DefaultNetstreamDriver gtls` authenticates the transport, which matters because a
plain syslog receiver accepts anything from anywhere and forging entries is otherwise
trivial. The journal's equivalent pair is `systemd-journal-upload` and
`systemd-journal-remote`, which ship structured records and resume on `__CURSOR`.

**The local copy can still be made awkward to erase.** Lesson 45's append-only
attribute is the tool:

```
sudo chattr +a /var/log/auth.log
lsattr /var/log/auth.log
```

A file with `a` set can be appended to but not truncated, overwritten, or
deleted. That does not stop root, anyone who can run `chattr -a` undoes it,
but it stops the reflexive `> /var/log/auth.log`, defeats scripted log wipers
that do not expect it, and clearing the attribute is itself an auditable
event. Note it breaks logrotate's `create` mode, so the rule needs
`copytruncate` or a `prerotate` that clears the flag.

**The number that decides the design is retention.** Local disk gives you days; a
collector gives you the year a regulator, a contract, or an incident retainer will ask
for. Decide that first, because it determines whether `rotate 4` is a policy or an
accident.

</details>

## Rotation, and why a disk fills up

A log grows forever. Something must rename it, start a new one, and delete the
oldest, and on a text-log machine that something is `logrotate`. An ordinary
program run once a day by `logrotate.timer` or, on older systems,
`/etc/cron.daily/logrotate`. It is configured in one global file plus a
directory of per-package fragments:

```bash
# Debian 13 (trixie), x86_64
$ grep -vE "^#|^$" /etc/logrotate.conf
weekly
rotate 4
create
include /etc/logrotate.d
```

**Four lines are the entire default policy**: rotate weekly, keep four generations,
create a fresh file after rotating, and read everything in `/etc/logrotate.d`. Four
weekly generations is **one month of history**, which is the number to check against
whatever your organisation believes its retention period is.

Each package drops in its own rules:

```bash
# Debian 13 (trixie), x86_64
$ cat /etc/logrotate.d/rsyslog
/var/log/syslog
/var/log/mail.log
/var/log/kern.log
/var/log/auth.log
/var/log/user.log
/var/log/cron.log
{
	rotate 4
	weekly
	missingok
	notifempty
	compress
	delaycompress
	sharedscripts
	postrotate
		/usr/lib/rsyslog/rsyslog-rotate
	endscript
}
```

| Directive | Effect |
| --- | --- |
| `rotate 4` | Keep four old files, then delete |
| `weekly`, `daily`, `size 100M` | When to rotate |
| `compress` | gzip the rotated file |
| `delaycompress` | Leave the newest rotated file uncompressed for one cycle |
| `missingok` | Do not complain if the file is absent |
| `notifempty` | Skip rotation if there is nothing in it |
| `create 0640 root adm` | Recreate the log with this mode and owner |
| `copytruncate` | Copy the file, then truncate the original in place |
| `sharedscripts` | Run `postrotate` once for the set, not once per file |
| `postrotate` | Commands to run afterwards, usually to signal the daemon |

**`postrotate` is the point of the whole file.** Renaming a log tells the
daemon nothing: it still holds the open file descriptor and keeps writing to
the renamed inode. `/usr/lib/rsyslog/rsyslog-rotate` signals rsyslog to
reopen, and `sharedscripts` makes that happen once after all six files rather
than six times. **`copytruncate` is the alternative when a daemon cannot be
signalled**, it copies the contents aside and truncates in place, at the cost
of a window where new lines are lost and briefly twice the disk space.

`logrotate -d` is a dry run that prints its whole decision trace without
touching anything, including the state file, `/var/lib/logrotate/status` on
Debian, which is where logrotate remembers when each file was last rotated.
**That state file, not the file's timestamp, is what makes `weekly` mean
weekly.**

<details class="predict">
<summary>The rule sets <code>compress</code> and <code>delaycompress</code>, and rsyslog is running with data in its files. After <code>logrotate -f</code> forces a rotation, what are the file names, is the newest rotated file compressed, and how big is the original?</summary>

```bash
# Debian 13 (trixie), x86_64
$ logrotate -f /etc/logrotate.conf; ls -l /var/log/syslog* /var/log/auth.log*
-rw-r-----. 1 root adm    0 Aug  8 17:52 /var/log/auth.log
-rw-r-----. 1 root adm   83 Aug  8 17:52 /var/log/auth.log.1
-rw-r-----. 1 root adm    0 Aug  8 17:52 /var/log/syslog
-rw-r-----. 1 root adm 3609 Aug  8 17:52 /var/log/syslog.1
```

</details>

**`.1` files exist and none of them end in `.gz`.** That is `delaycompress`:
the newest rotated file stays plain text this cycle and is compressed next
time, so a daemon that has not yet reopened does not have its output vanish
into a half-written gzip. And **the originals are zero bytes, not gone**:
`create` remade them with the same mode and owner, which is why `auth.log` is
still `root adm 0640`.

**Now the failure this section is named for.** A disk fills, you find the enormous
log, you delete it, and `df` does not move. Unlinking a file that an open descriptor
still references frees the name and not the blocks, so the space returns only when the
process holding it lets go. `lsof +L1` lists exactly those files. The lesson is that
`rm` on a live log both destroys the evidence and fails to solve the problem;
`truncate -s 0` frees the space with the descriptor still valid.

## auditd is not logging

Everything so far records **what a program chose to say**. No log statement, no entry.
The audit subsystem fills that gap: it lives in the kernel, watches **system calls**,
and records events whether or not any program wanted them recorded.

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ sudo auditctl -s
enabled 1
failure 1
pid 858
rate_limit 0
backlog_limit 64
lost 0
backlog 0
backlog_wait_time 60000
backlog_wait_time_actual 0
loginuid_immutable 0 unlocked
```

Four of those numbers matter:

- **`enabled 1`**, on. `2` means on and *immutable* until reboot, which is
  what a hardened machine sets so root cannot quietly unload the rules.
- **`failure 1`**, what the kernel does if it cannot record: `0` silent, `1`
  log it, `2` panic the machine. Sites that must not lose a record really do
  set `2`.
- **`backlog_limit 64`** and **`lost 0`**, the queue between kernel and
  daemon, and how many events fell off the end. **`lost` above zero means the
  audit trail has holes**, and the fix is a bigger backlog or fewer rules.

Out of the box there is nothing to watch:

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ sudo auditctl -l; echo ---; ls /etc/audit/rules.d/; echo ---; sudo ls -l /var/log/audit/
No rules
---
audit.rules
---
total 16900
-rw-------. 1 root root 6186397 Aug  8 12:58 audit.log
-r--------. 1 root root 8388953 Aug  8 11:58 audit.log.1
```

**`No rules`, and yet `audit.log` is six megabytes.** Both are true: with no
rules loaded the kernel still emits its own events (logins, PAM decisions,
SELinux denials, crypto session setup) and those fill the file. Rules are for
watching things nobody reports on their own.

Rules live in `/etc/audit/rules.d/*.rules`, which `augenrules` compiles into
`/etc/audit/audit.rules` at start-up. `auditctl` loads one immediately and without
persistence, which is what to use while working out what you want:

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ sudo touch /var/tmp/secrets.conf; sudo auditctl -w /var/tmp/secrets.conf -p wa -k secrets-watch; sudo auditctl -l
Old style watch rules are slower
-w /var/tmp/secrets.conf -p wa -k secrets-watch
```

Three parts. **`-w` is the path.** **`-p wa` is which permissions to care
about** (`r` read, `w` write, `x` execute, `a` attribute change) and `wa` is
the usual choice for a file that should not change. **`-k` is a key**, an
arbitrary string stamped on every matching event, and it is the difference
between a searchable trail and a haystack. `Old style watch rules are slower`
is a real warning; the modern form compiles to a faster rule:

```
-a always,exit -F path=/var/tmp/secrets.conf -F perm=wa -F key=secrets-watch
```

Now change the file and ask what the kernel saw:

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ sudo sh -c "echo tampered >> /var/tmp/secrets.conf"; sleep 2; sudo ausearch --input-logs -k secrets-watch -i 2>&1 | tail -12
----
type=PROCTITLE msg=audit(08/08/26 12:59:14.123:21992) : proctitle=auditctl -w /var/tmp/secrets.conf -p wa -k secrets-watch 
type=SYSCALL msg=audit(08/08/26 12:59:14.123:21992) : arch=aarch64 syscall=sendto success=yes exit=1092 a0=0x4 a1=0xffffd3b92b50 a2=0x444 a3=0x0 items=0 ppid=475287 pid=475289 auid=core uid=root gid=root euid=root suid=root fsuid=root egid=root sgid=root fsgid=root tty=(none) ses=964 comm=auditctl exe=/usr/bin/auditctl subj=unconfined_u:unconfined_r:unconfined_t:s0-s0:c0.c1023 key=(null) 
type=CONFIG_CHANGE msg=audit(08/08/26 12:59:14.123:21992) : auid=core ses=964 subj=unconfined_u:unconfined_r:unconfined_t:s0-s0:c0.c1023 op=add_rule key=secrets-watch list=exit res=yes 
----
type=PROCTITLE msg=audit(08/08/26 12:59:14.450:22047) : proctitle=sh -c echo tampered >> /var/tmp/secrets.conf 
type=PATH msg=audit(08/08/26 12:59:14.450:22047) : item=0 name=/var/tmp/secrets.conf inode=9534622 dev=fd:04 mode=file,644 ouid=root ogid=root rdev=00:00 obj=unconfined_u:object_r:user_tmp_t:s0 nametype=NORMAL cap_fp=none cap_fi=none cap_fe=0 cap_fver=0 cap_frootid=0 
type=CWD msg=audit(08/08/26 12:59:14.450:22047) : cwd=/var/home/core 
type=SYSCALL msg=audit(08/08/26 12:59:14.450:22047) : arch=aarch64 syscall=openat success=yes exit=3 a0=AT_FDCWD a1=0xaaaad9314580 a2=O_WRONLY|O_CREAT|O_APPEND a3=0x1b6 items=1 ppid=475390 pid=475392 auid=core uid=root gid=root euid=root suid=root fsuid=root egid=root sgid=root fsgid=root tty=(none) ses=966 comm=sh exe=/usr/bin/bash subj=unconfined_u:unconfined_r:unconfined_t:s0-s0:c0.c1023 key=secrets-watch 
```

**One event, four records, and together they are a complete sentence.**
`PROCTITLE` is the command line as typed, `PATH` is the file with its inode,
mode, and SELinux label, `CWD` is where the process was, and `SYSCALL` is the
kernel call itself: `openat` with `O_WRONLY|O_CREAT|O_APPEND`, succeeding.

**Read `auid=core uid=root` in that syscall record**, because it is the whole reason
the audit subsystem exists. The process ran as root. The *login* UID, set when the
session was created and unchangeable afterwards, is still `core`. `su` and `sudo`
change `uid`; nothing in user space changes `auid`. That one field turns "root did it"
into "this person did it", and no other log on the machine records it.

The `CONFIG_CHANGE` record above it is the same principle applied to auditing itself:
adding the rule was logged, with the key and the account that did it.

<details class="predict">
<summary><code>auditd</code> is running, <code>/var/log/audit/audit.log</code> is six megabytes, and the journal also lists <code>audit</code> as a transport. What does a plain <code>ausearch -m USER_CMD -ts today</code> print?</summary>

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ sudo ausearch -m USER_CMD -ts today 2>&1 | head -5; echo "--- and again with --input-logs ---"; sudo ausearch --input-logs -m USER_CMD -ts today 2>&1 | head -3
<no matches>
--- and again with --input-logs ---
----
time->Sat Aug  8 11:43:50 2026
type=USER_CMD msg=audit(1786207430.654:633): pid=2341 uid=501 auid=501 ses=23 subj=unconfined_u:unconfined_r:unconfined_t:s0-s0:c0.c1023 msg='cwd="/var/home/core" cmd=6765747365626F6F6C202D61 exe="/usr/bin/sudo" terminal=? res=success'
```

</details>

**`<no matches>` on a machine full of matches.** Where the audit stream reaches both
journald and `auditd`, `ausearch` reads the *journal* by default and comes back empty
while `audit.log` is full. **`--input-logs` reads the files.** Every `ausearch` and
`aureport` in this lesson carries it for that reason, and it is the first thing to try
before concluding auditing is off.

The other flag there is `-i`, for *interpret*. Without it a command is
hex-encoded, `cmd=6765747365626F6F6C202D61`, because a command line may
contain any byte and the raw log escapes it. With `-i` the same field reads
`cmd=getsebool -a`, and UIDs, syscall numbers, and architectures become names.
`aureport -k --summary` then counts events per key, which is the report you
send somebody; name keys after the control they satisfy (`identity`,
`privileged`, `time-change`) rather than after the file.

<details class="deeper">
<summary>If you already administer Linux: what an audit rule costs, and the ones that will hurt you</summary>

Every rule is evaluated on **every matching syscall, on every CPU, in the kernel's
fast path**, and the record then drains through a 64-entry backlog. That is not free
and the cost is not evenly distributed.

**Cheap:** file watches on a handful of specific paths, and syscall rules with narrow
filters. `/etc/shadow`, `/etc/sudoers`, `/etc/passwd` produce a few events a week.

**Expensive**, in roughly the order somebody following a hardening guide too literally
adds them:

- `-a always,exit -F arch=b64 -S open,openat` with no path filter. Every file open by
  every process. On a busy server that is tens of thousands of events a second, a
  measurable throughput loss, and a `lost` counter that climbs.
- A recursive watch on a directory that changes (`-w /var/lib`, a package
  cache) turning routine work into a flood.
- `-S execve` without `-F auid>=1000 -F auid!=unset`, recording every fork of every
  cron script alongside the human logins you cared about.

The exclusion filter is the tool people miss. `-a never,exit` rules are
evaluated first, so excluding a known-noisy path or user before a broad rule
costs far less than the broad rule alone. First match wins, so ordering is
part of the rule.

Then the disk, which `auditd` manages itself:

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ sudo grep -vE "^#|^$" /etc/audit/auditd.conf | head -16
local_events = yes
write_logs = yes
log_file = /var/log/audit/audit.log
log_group = root
log_format = ENRICHED
flush = INCREMENTAL_ASYNC
freq = 50
max_log_file = 8
num_logs = 5
priority_boost = 4
name_format = NONE
max_log_file_action = ROTATE
space_left = 75
space_left_action = SYSLOG
verify_email = yes
action_mail_acct = root
```

**`max_log_file = 8` and `num_logs = 5` is a hard ceiling of 40 MB**, enforced inside
`auditd` by `max_log_file_action = ROTATE`. Logrotate is not involved. On a machine
with real rules loaded, 40 MB is hours, and then the oldest evidence is silently
discarded.

`space_left_action` and `admin_space_left_action` turn that from a default into a
decision: they can `SYSLOG` a warning, `SUSPEND` logging, or `halt` the machine. A
system with a legal obligation to retain audit records is configured to stop rather
than overwrite, and that is an availability trade nobody should make by accident.
`log_format = ENRICHED` is worth noting too: it resolves UIDs, groups, and
architecture names *at write time*, so a record still makes sense after the account
that produced it is deleted.

</details>

## Accounting, the third A

Lesson 37 named the three A's and covered two. Authentication proves who you are;
authorization decides what you may do; **accounting is the durable record of what you
actually did**. It is the one that gets skipped, because the first two are required to
log in and the third is only required when somebody asks a question.

Accounting on Linux lives in the audit subsystem, and one record type carries most of
it:

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ sudo ausearch --input-logs -m USER_CMD -i -ts today 2>&1 | tail -8
----
type=USER_CMD msg=audit(08/08/26 12:58:46.043:21582) : pid=474082 uid=core auid=core ses=947 subj=unconfined_u:unconfined_r:unconfined_t:s0-s0:c0.c1023 msg='cwd=/var/home/core cmd=ls -l /var/log/audit/ exe=/usr/bin/sudo terminal=? res=success' 
----
type=USER_CMD msg=audit(08/08/26 12:58:46.431:21630) : pid=474176 uid=core auid=core ses=949 subj=unconfined_u:unconfined_r:unconfined_t:s0-s0:c0.c1023 msg='cwd=/var/home/core cmd=ausearch -m USER_CMD -ts today exe=/usr/bin/sudo terminal=? res=success' 
----
type=USER_CMD msg=audit(08/08/26 12:58:46.444:21636) : pid=474180 uid=core auid=core ses=949 subj=unconfined_u:unconfined_r:unconfined_t:s0-s0:c0.c1023 msg='cwd=/var/home/core cmd=ausearch --input-logs -m USER_CMD -ts today exe=/usr/bin/sudo terminal=? res=success' 
----
type=USER_CMD msg=audit(08/08/26 12:58:55.103:21706) : pid=474392 uid=core auid=core ses=952 subj=unconfined_u:unconfined_r:unconfined_t:s0-s0:c0.c1023 msg='cwd=/var/home/core cmd=ausearch --input-logs -m USER_CMD -i -ts today exe=/usr/bin/sudo terminal=? res=success' 
```

**Read one line as a sentence.** At a stated time, the user `core`, whose login UID is
`core`, in session `947`, working in `/var/home/core`, ran `ls -l /var/log/audit/`
through `/usr/bin/sudo`, and it succeeded.

That is accounting: not "sudo was used" but *who*, *what*, *where*, *which session*,
and *whether it worked*, for every privileged command, written by the kernel rather
than by the program being run. `ses=947` ties every record from one login together, so
one session identifier reconstructs an entire visit.

Note that the last line records the `ausearch` command itself. **Looking at the audit
log is an audited event**, which is what makes the trail defensible: an investigator
who tampers leaves a record of having done so.

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ sudo aureport --input-logs --summary 2>&1 | head -14

Summary Report
======================
Range of time in logs: 08/07/26 14:14:47.480 - 08/08/26 12:57:42.363
Selected time for report: 08/07/26 14:14:47 - 08/08/26 12:57:42.363
Number of changes in configuration: 639
Number of changes to accounts, groups, or roles: 38
Number of logins: 547
Number of failed logins: 0
Number of authentications: 1500
Number of failed authentications: 0
Number of users: 3
Number of terminals: 7
Number of host names: 3
```

**`Number of failed logins: 0` against 547 logins** is the kind of line a report is
built from, and `aureport -au`, `-l`, `-f`, and `-x` break out authentications,
logins, file access, and executables respectively.

Three layers of accounting exist and they answer different questions:

| Layer | Records | Read with |
| --- | --- | --- |
| `wtmp`, `btmp`, `lastlog` | Logins, failed logins, last login per user | `last`, `lastb`, `lastlog` |
| The journal and syslog | Whatever services chose to report | `journalctl`, `grep` |
| The audit subsystem | Syscalls, with login UID and session | `ausearch`, `aureport` |

**Only the third survives an argument**, because only it records `auid`, only it is
written by the kernel, and only it logs its own configuration changes.

## Across distributions

| | RHEL family | Debian family |
| --- | --- | --- |
| Journal | Persistent by default | Historically volatile; check `/var/log/journal` |
| Syslog daemon | On server installs; absent on minimal and image-based ones | `rsyslog`, installed |
| How rsyslog gets messages | `imjournal`, reading the journal | `imuxsock`, reading `/dev/log` |
| Catch-all text log | `/var/log/messages` | `/var/log/syslog` |
| Authentication text log | `/var/log/secure` | `/var/log/auth.log` |
| logrotate state file | `/var/lib/logrotate/logrotate.status` | `/var/lib/logrotate/status` |
| Audit package | `audit`, installed and enabled | `auditd`, not installed by default |

**The input difference is the one that changes behaviour.** Reading the journal means
rsyslog inherits journald's rate limiting and structured fields; reading `/dev/log`
means rsyslog sees messages journald may never have. That is why the same application
can appear in `/var/log/messages` on one family and only in the journal on the other.

**Check for the file before you grep it.** `/var/log/messages` on Ubuntu and
`/var/log/syslog` on RHEL are both absent, and so is either on a machine with no
syslog daemon.

## Prove it

```
# Which log systems does this machine actually run
systemctl is-active systemd-journald rsyslog auditd
ls -d /var/log/journal 2>/dev/null || echo "journal is volatile"

# The journal, narrowed the way it should be narrowed
journalctl -u <unit> -b -p warning --since "1 hour ago"
journalctl -b -1 -n 20
journalctl -F _TRANSPORT

# What syslog rules exist, if any
grep -vE '^#|^$' /etc/rsyslog.conf /etc/rsyslog.d/*.conf

# What rotation would do, without doing it
logrotate -d /etc/logrotate.conf

# Is anything audited, and did anything fall off the queue
sudo auditctl -s
sudo auditctl -l

# Who ran what as root
sudo ausearch --input-logs -m USER_CMD -i -ts today
sudo aureport --input-logs --summary
```

**Build the habit around `auditctl -s` and `auditctl -l`.** The first says whether
auditing is on and whether it has lost events; the second says whether anything is
being watched. A machine with `enabled 1` and `No rules` looks audited on a checklist
and answers no questions at all.

## What trips people up

### 1. Grepping text logs on a machine that has none

`/var/log/messages` does not exist on a minimal or image-based system, because rsyslog
was never installed. The absence produces no error, just an empty result, which reads
exactly like "nothing happened". Run `systemctl is-active rsyslog` before trusting an
empty `grep`.

### 2. Expecting the journal to survive a reboot

`Storage=auto` writes to `/var/log/journal` if the directory exists and to a tmpfs if
it does not. No directory, no history: `journalctl -b -1` is empty and the crash you
were investigating left nothing behind. `ls -d /var/log/journal` on every machine you
inherit.

### 3. `ausearch` returns no matches

Where the audit stream reaches journald as well as `auditd`, `ausearch` reads the
journal by default and reports `<no matches>` while `audit.log` is full. Add
`--input-logs`. This is not a corner case; it is the default on current Fedora and
RHEL systems.

### 4. Rotating a log the daemon still holds open

Renaming a file tells the writing process nothing. Without a `postrotate` signal or
`copytruncate`, the daemon keeps writing to the renamed inode and the new file stays
empty forever. The same mechanism explains why deleting a huge log frees no disk space
until the holder restarts; `lsof +L1` finds them.

### 5. Auditing everything

`-S open,openat` with no path filter records every file access on the machine. The
result is a throughput cost you can measure, a `lost` counter that climbs, and a 40 MB
audit log that rolls over in an hour and destroys the evidence you wanted.

### 6. Keeping the only copy on the machine being investigated

Root can rewrite any local log, so a compromised machine's logs are an attacker's
draft. Forward to a collector and treat that copy as the evidence.

## Work it through

A file under `/etc` changed overnight on one server. Nobody admits to it. You have
shell access at 09:00 and the change happened after 02:00.

Reason it out before reading on.

**Establish what this machine keeps at all:**

```
systemctl is-active systemd-journald rsyslog auditd
ls -d /var/log/journal
sudo auditctl -s
```

Three answers, and they determine everything after. **If `auditd` is enabled
with a rule covering that path**, the question is already answered and the
rest is reading. If it is enabled with `No rules`, the kernel's own events are
still there (logins, sudo, PAM) which is less than you wanted and more than
nothing.

**Narrow by time rather than by content:**

```
journalctl --since "2026-08-08 02:00" --until "2026-08-08 09:00" -p notice
```

A seven-hour window at `notice` and worse is a few hundred lines on most machines
against tens of thousands unfiltered. Bounding with `--until` as well as `--since` is
what makes it tractable.

**Ask who was on the machine:**

```
sudo ausearch --input-logs -m USER_LOGIN,USER_START -ts today -i
last -F | head
```

One person with a session in that window and you are nearly finished. A
configuration management run and you are also finished, and this is not a
security incident at all, which is the outcome for roughly half of these.

**The step that names the command:**

```
sudo ausearch --input-logs -m USER_CMD -i -ts today | grep -A2 '/etc'
```

`USER_CMD` records carry `auid`, `ses`, `cwd`, and the full command line, so a match
names a person rather than an account. **This step fails on a machine where accounting
was never configured**, and noticing that is itself the finding worth reporting.

**Now change one detail.** Suppose the journal is volatile and the machine rebooted at
06:00. Everything before that is gone and `journalctl -b -1` returns nothing. What
survives is `/var/log/audit/audit.log`, because `auditd` writes its own files and does
not care about the journal's storage setting, and `wtmp`, which is also a file. The
investigation narrows to the two stores that were on disk all along.

**And one more.** Suppose the audit record says `auid=1004 uid=root`, and 1004 is a
service account nobody should be logging in as interactively. That is no longer a
change-management question; that is an incident, and it is the reason the `auid` field
exists.

The point worth extracting: **the three stores answer three different questions, and
knowing which to open is most of the speed.** The journal tells you what services
said. The text logs are what you grep and what leaves the machine. The audit log is
the only one that records what was *done*, by whom, whether or not anybody chose to
report it.

## Try it

Optional, on any machine you can restart services on.

1. `journalctl -F _TRANSPORT` and `journalctl -F PRIORITY`. Name each transport
   against the diagram at the top.
2. `journalctl -b --no-pager | wc -l`, then the same with `-p warning`. Work out the
   ratio on your own machine.
3. `journalctl -u sshd -o verbose -n 1`. Find `_SYSTEMD_UNIT`, `_PID`, and `PRIORITY`,
   and say which fields the sending program could have forged.
4. `ls -d /var/log/journal`. If it is missing, you now know something important.
5. `logger -p local3.err "test from $USER"`, then find it with `journalctl -p err -n 5`
   and, if rsyslog is installed, in a file under `/var/log`.
6. `logrotate -d /etc/logrotate.conf` and read the trace. Find the state file it names
   and `cat` it.
7. `sudo auditctl -s` and `sudo auditctl -l`. Note `lost`, and whether rules exist.
8. `sudo auditctl -w /tmp/canary -p wa -k canary`, `touch /tmp/canary`, then
   `sudo ausearch --input-logs -k canary -i`. Read `auid` against `uid`.
9. `sudo auditctl -D` to clear it again.

**Verification step.** You have it when somebody asks "where would that be logged" and
you can name which of the three stores, and why, before running anything.

## Check yourself

<details class="qa">
<summary>Why does a modern Linux machine run both journald and rsyslog, and which do you reach for?</summary>

**Because they serve different consumers, and neither replaced the other.**

**The journal** is the collection point. Kernel messages, unit output,
`/dev/log`, and the audit stream all land there, and journald attaches trusted
fields (unit, PID, UID, boot ID, SELinux context) that the sender cannot
forge. It is indexed, so `journalctl -u x -p err -b` is fast and precise.
**Reach for it when diagnosing.**

**Rsyslog** takes a second copy and writes plain text, which is the universal
interface: `grep`, an SIEM connector, a shipper, and an auditor who wants one file for
last March all consume text and none of them speak the journal's format. Rsyslog also
forwards over the network with queueing and TLS, which journald does not do on its
own. **Reach for it when logs must leave the machine or persist for a year.**

The tempting wrong answer is that `/var/log/messages` is a text dump of the
journal and therefore redundant. It is a *filtered* copy decided by selector
rules (Debian's `*.*;auth,authpriv.none` keeps authentication out of `syslog`
entirely) so the two stores differ in content, not only in format.

**What you will need next:** on a minimal or image-based system rsyslog is not
installed at all, so `systemctl is-active rsyslog` is worth running before you trust
an empty `grep`.

</details>

<details class="qa">
<summary><code>journalctl -b -1</code> returns nothing on a machine that has definitely rebooted. What happened, and how do you fix it before the next incident?</summary>

**The journal is volatile there, so the previous boot's records were erased on
restart.**

`Storage=auto` is the default and means exactly one thing: write to
`/var/log/journal` if that directory exists, and to `/run/log/journal`, a
tmpfs, if it does not. There is no enable switch. The presence of one
directory is the whole mechanism.

**The fix, before you need it:**

```
sudo mkdir -p /var/log/journal
sudo systemd-tmpfiles --create --prefix /var/log/journal
sudo systemctl restart systemd-journald
```

Or `Storage=persistent` in `/etc/systemd/journald.conf`, which creates the directory
itself and leaves the intent written down.

The tempting wrong answer is that the journal was rotated or vacuumed away.
`--vacuum-size` and `--vacuum-time` only remove *archived* journal files and would not
selectively erase one boot, and logrotate has no involvement in the journal at all.

**What you will need next:** set `SystemMaxUse=` at the same time. A persistent
journal defaults to 10 percent of the filesystem, which on a small `/var` is a number
worth choosing rather than inheriting.

</details>

<details class="qa">
<summary>A log file filled <code>/var</code>. You deleted it and <code>df</code> still reports the filesystem full. Why, and what does the correct fix look like?</summary>

**Because the daemon still holds the file open, and unlinking a file with an open
descriptor frees the name, not the blocks.**

The inode and its data stay allocated until the last descriptor closes. `lsof
+L1` lists exactly these (open, link count zero) and their sizes are the space
you are missing. Restarting or signalling the process releases it immediately.

**The correct fix is not to be here**, and it has two parts:

- **Rotate with a `postrotate` script** that signals the daemon to reopen, or use
  `copytruncate` where it cannot be signalled. Renaming without either leaves the
  daemon writing to the renamed inode and the new file empty.
- **Set the policy against the disk you have.** `rotate 4` weekly is one month;
  `size 100M` rotates on volume rather than on a calendar, which is what a chatty
  service needs.

The tempting wrong answer is the `rm` that caused this: it destroys evidence and does
not return the space. If you must act immediately, `truncate -s 0 /var/log/big.log`
frees the blocks with the descriptor still valid and the daemon writing.

**What you will need next:** `journalctl --disk-usage` and `du -sh /var/log/audit`,
because on a machine with no rsyslog the disk is being filled by one of the two stores
logrotate does not manage.

</details>

<details class="qa">
<summary>Decode this: <code>type=SYSCALL ... syscall=openat success=yes ... auid=core uid=root ... comm=sh key=secrets-watch</code>. What does it prove that no other log could?</summary>

**That a specific human, not merely "root", opened a watched file for writing.**

`syscall=openat success=yes` is the kernel operation and its outcome. `uid=root` is
the effective identity the process ran as. `comm=sh` is the program. `key=secrets-watch`
is the label from the rule that matched, which is how the event is searchable.

**`auid=core` is the field doing the work.** The login UID is set when a session is
created and cannot afterwards be changed by anything in user space. `su` and `sudo`
change `uid`; nothing changes `auid`. So `auid=core uid=root` says this action was
taken by the account `core` after escalating, and that mapping exists nowhere else on
the system.

The tempting wrong answer is that `/var/log/secure` or the journal already shows the
`sudo` invocation. It shows that sudo was *run*; it does not show which syscalls the
resulting root process made, and it records nothing at all when the write comes from a
process that was already privileged.

**What you will need next:** `ses=` in the same record ties every event from one login
together, so one session identifier reconstructs a whole visit rather than one command.

</details>

<details class="qa">
<summary><code>sudo ausearch -k mykey</code> prints <code><no matches></code> on a machine where <code>/var/log/audit/audit.log</code> is megabytes long and the rule is loaded. What is wrong?</summary>

**Nothing is wrong with the auditing. `ausearch` is reading the wrong input.**

On current Fedora and RHEL systems the kernel's audit stream reaches both `auditd`,
which writes `/var/log/audit/audit.log`, and journald, which stores it as
`_TRANSPORT=audit`. `ausearch` reads the journal by default, and if the events are not
there in the form it expects it reports `<no matches>` while the file on disk is full
of them.

**`--input-logs` tells it to read `auditd`'s own files**, and it is the first thing to
try before concluding auditing is off:

```
sudo ausearch --input-logs -k mykey -i
sudo aureport --input-logs --summary
```

The tempting wrong answer is that the rule never loaded. Check that properly with
`auditctl -l` rather than inferring it from an empty search. Note that `aureport`
without `--input-logs` betrays itself by reporting a time range starting at `12/31/69`,
which is the Unix epoch and means it found nothing at all.

**What you will need next:** `-i` on every `ausearch`. Without it command lines come
back hex-encoded, because a command may contain any byte and the raw log escapes it.

</details>

## References

- [journalctl(1)](https://man7.org/linux/man-pages/man1/journalctl.1.html) - Linux man-pages project. Accessed 2026-08-08.
- [journald.conf(5)](https://man7.org/linux/man-pages/man5/journald.conf.5.html) - Linux man-pages project. Accessed 2026-08-08.
- [syslog(3)](https://man7.org/linux/man-pages/man3/syslog.3.html) - Linux man-pages project. Accessed 2026-08-08.
- [logger(1)](https://man7.org/linux/man-pages/man1/logger.1.html) - Linux man-pages project. Accessed 2026-08-08.
- [rsyslog.conf(5)](https://manpages.debian.org/trixie/rsyslog/rsyslog.conf.5.en.html) - Debian manpages. Accessed 2026-08-08.
- [logrotate(8)](https://man7.org/linux/man-pages/man8/logrotate.8.html) - Linux man-pages project. Accessed 2026-08-08.
- [auditctl(8)](https://man7.org/linux/man-pages/man8/auditctl.8.html) - Linux man-pages project. Accessed 2026-08-08.
- [ausearch(8)](https://man7.org/linux/man-pages/man8/ausearch.8.html) - Linux man-pages project. Accessed 2026-08-08.

Captured output came from two machines. The rsyslog and logrotate transcripts are from
a Debian 13 container with `rsyslog` and `logrotate` installed, which is why `imklog`
fails there: a container has no kernel log of its own to read. The journal and audit
transcripts are from a Fedora CoreOS virtual machine, which runs `auditd` and has no
syslog daemon installed at all. Blocks without a distribution and architecture header
are illustrative rather than captured.
