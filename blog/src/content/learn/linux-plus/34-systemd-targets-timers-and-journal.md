---
title: "Targets, timers, and the log that knows everything"
description: "What replaced runlevels, how a timer beats a crontab, and a log query language that answers questions the old text files could not. Plus the four commands that configure a machine's identity."
track: "linux-plus"
level: "working"
order: 350
objectives:
  - "Explain what a target is and change the one a machine boots to"
  - "Read and write a systemd timer, and say when to prefer it to cron"
  - "Query the journal by unit, time, priority, and boot"
  - "Use the hostnamectl family to set a machine's identity"
prerequisites: ["systemd-units-and-services"]
tags: ["linux", "linux-plus", "systemd", "journal", "timers"]
updated: 2026-08-07
draft: false
examObjectives:
  - exam: "xk0-006"
    domain: "2.0"
    objective: "2.5"
sources:
  - title: "systemd.target(5)"
    url: "https://man7.org/linux/man-pages/man5/systemd.target.5.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "systemd.special(7)"
    url: "https://man7.org/linux/man-pages/man7/systemd.special.7.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "journalctl(1)"
    url: "https://man7.org/linux/man-pages/man1/journalctl.1.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "journald.conf(5)"
    url: "https://man7.org/linux/man-pages/man5/journald.conf.5.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "systemd.time(7)"
    url: "https://man7.org/linux/man-pages/man7/systemd.time.7.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "hostnamectl(1)"
    url: "https://man7.org/linux/man-pages/man1/hostnamectl.1.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
symptoms:
  - symptom: "Logs disappear after a reboot"
    anchor: "3-the-journal-is-not-persistent"
  - symptom: "Machine boots to a graphical desktop and should not"
    anchor: "1-the-wrong-default-target"
---

> **Before you read.** A server was installed by somebody who clicked the wrong
> option, and it boots to a graphical desktop nobody will ever look at. It works,
> and it wastes memory and starts services you did not ask for.
>
> On an older Unix you would have edited `/etc/inittab` and changed a number.
> That file no longer exists.
>
> **What replaced runlevels, and why would anybody change something that
> worked?**

Because a number cannot express a dependency. Runlevel 3 meant "the things we have
agreed runlevel 3 means", enforced by shell scripts numbered `S20` and `S30` so
they ran in the right order. It worked, it was entirely sequential, and nothing in
it could say *why* one thing had to come before another.

Targets replace the number with a named state and a dependency graph, which is
slower to explain and much easier to reason about.

### Some words you will need

<dl class="terms">
<dt>target</dt>
<dd>A named state, and a grouping of the units needed to reach it.</dd>
<dt>isolate</dt>
<dd>To switch to a target, stopping anything not wanted by it.</dd>
<dt>timer</dt>
<dd>A unit that activates another unit on a schedule.</dd>
<dt>journal</dt>
<dd>systemd's structured, indexed log. Not a text file.</dd>
<dt>priority</dt>
<dd>The severity of a log entry, 0 to 7, from emergency to debug.</dd>
</dl>

## What breaks without this

**A machine boots into the wrong state**, running a desktop on a server or failing
to reach a login prompt at all.

**You cannot answer "what happened".** Text logs are per-service and unindexed;
correlating an application error with a kernel message across two files and two
timestamp formats is the slow way to do everything.

**Logs vanish at reboot**, which is the default on some distributions and is
discovered after the reboot you needed them for.

## Targets

Three questions in one command below: what is scheduled, what state the machine
boots into, and what that state drags in with it.

<details class="predict">
<summary>This is a minimal server image with no desktop installed. What will <code>systemctl get-default</code> report, and what would it say on a laptop?</summary>

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ systemctl list-timers --no-pager | head -8; echo "--- what the default target is ---"; systemctl get-default; echo "--- and what it pulls in ---"; systemctl list-dependencies multi-user.target --no-pager | head -8
NEXT                            LEFT LAST                          PASSED UNIT                         ACTIVATES
Fri 2026-08-07 23:29:19 CDT  1h 3min Fri 2026-08-07 22:15:55 CDT 9min ago fwupd-refresh.timer          fwupd-refresh.service
Sat 2026-08-08 00:25:36 CDT 1h 59min -                                  - logrotate.timer              logrotate.service
Sat 2026-08-08 11:38:01 CDT      13h -                                  - rpm-ostree-countme.timer     rpm-ostree-countme.service
Sat 2026-08-08 14:30:34 CDT      16h Fri 2026-08-07 14:30:34 CDT   7h ago systemd-tmpfiles-clean.timer systemd-tmpfiles-clean.service
Sun 2026-08-09 01:00:00 CDT 1 day 2h -                                  - raid-check.timer             raid-check.service
Mon 2026-08-10 00:37:32 CDT   2 days -                                  - fstrim.timer                 fstrim.service

--- what the default target is ---
multi-user.target
--- and what it pulls in ---
multi-user.target
○ ├─afterburn-checkin.service
○ ├─afterburn-firstboot-checkin.service
○ ├─audit-rules.service
● ├─auditd.service
● ├─authselect-apply-changes.service
● ├─bootc-status-updated.path
● ├─bootloader-update.service
```

</details>

**`systemctl get-default` is the modern `/etc/inittab`.** It reports
`multi-user.target`, a server booted to a text login with networking.

**`list-dependencies` shows the graph**, with a filled circle for active units and
an open one for inactive. That tree is what a runlevel number could never express:
each unit states its own requirements, and systemd works out the order.

| Target | Was runlevel | Means |
| --- | --- | --- |
| `poweroff.target` | 0 | Shut down |
| `rescue.target` | 1 | Single user, root shell, filesystems mounted |
| `multi-user.target` | 3 | Text login, networking. **Servers.** |
| `graphical.target` | 5 | Desktop |
| `reboot.target` | 6 | Restart |
| `emergency.target` |, | Read-only root, almost nothing else |

The old numbers still work as aliases, `systemctl isolate runlevel3.target`,
and should not be used in anything written down.

```
systemctl get-default                        # what it boots to
sudo systemctl set-default multi-user.target # change it permanently
sudo systemctl isolate multi-user.target     # switch now, without rebooting
```

**`set-default` and `isolate` are different**, in exactly the way `enable` and
`start` were in the last lesson. `set-default` writes a symlink at
`/etc/systemd/system/default.target` and changes nothing now; `isolate` switches
immediately and is forgotten at reboot.

**`isolate` stops everything not wanted by the new target**, which on a running
server is a substantial and abrupt change. It is the right tool for dropping to
`rescue.target` deliberately and the wrong one to try casually over SSH.

## Timers

The `list-timers` output above is worth a second look: **`NEXT`**, **`LEFT`**,
**`LAST`**, **`PASSED`**, the timer, and what it activates. A timer that has never
run shows `-` in `LAST`, and a timer whose `NEXT` is in the past is not firing.

That table is the thing cron never had. `crontab -l` shows what you wrote; this
shows what will actually happen and what already did.

A timer is two units:

```ini
# /etc/systemd/system/backup.timer
[Unit]
Description=Nightly backup
[Timer]
OnCalendar=*-*-* 02:30:00
RandomizedDelaySec=300
Persistent=true
[Install]
WantedBy=timers.target
```

```ini
# /etc/systemd/system/backup.service
[Unit]
Description=Nightly backup
[Service]
Type=oneshot
ExecStart=/usr/local/bin/backup.sh
```

```
sudo systemctl daemon-reload
sudo systemctl enable --now backup.timer
```

**Enable the `.timer`, not the `.service`.** Enabling the service would start the
backup at every boot; the timer is what schedules it. The service has no
`[Install]` section for exactly this reason.

| Key | Does |
| --- | --- |
| `OnCalendar=` | An absolute schedule |
| `OnBootSec=` | Relative to boot |
| `OnUnitActiveSec=` | Relative to the **last run**. "Every 15 minutes of uptime." |
| `Persistent=true` | Run a missed occurrence at next boot |
| `RandomizedDelaySec=` | Spread load across a fleet |
| `AccuracySec=1s` | Fire precisely. Default is a minute, for power reasons. |

`OnCalendar` syntax is `DayOfWeek Year-Month-Day Hour:Minute:Second`, with `*`
for any:

```
OnCalendar=*-*-* 02:30:00          # daily at 02:30
OnCalendar=Mon *-*-* 09:00:00      # Mondays at 09:00
OnCalendar=*-*-01 03:00:00         # the first of each month
OnCalendar=hourly                  # a shorthand
```

And unlike cron, you can check it before trusting it:

```
systemd-analyze calendar '*-*-* 02:30:00'
```

which prints the next several firing times. That is a genuine dry run, and it
is the single best reason to prefer timers for anything non-obvious, the
crontab mistake from lesson 30 is not possible if you check the expression
first.

## The journal

`systemctl status` on the broken unit from the last lesson gave a code:
`status=203/EXEC`, meaning systemd could not execute the binary. The journal is
asked about the same unit below.

<details class="predict">
<summary><code>systemctl status</code> reported the exit code but not the cause. What does the journal add that status did not have room for?</summary>

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ sudo journalctl -u broken.service --no-pager -n 6; echo "--- and since a time ---"; sudo journalctl --since "10 minutes ago" -p err --no-pager -n 5 | head -6
Aug 07 22:25:36 localhost.localdomain systemd[1]: broken.service: Failed with result 'exit-code'.
Aug 07 22:25:45 localhost.localdomain systemd[1]: Started broken.service - A service that will not start.
Aug 07 22:25:45 localhost.localdomain (nosuchprogram)[55907]: broken.service: Unable to locate executable '/usr/bin/nosuchprogram': No such file or directory
Aug 07 22:25:45 localhost.localdomain (nosuchprogram)[55907]: broken.service: Failed at step EXEC spawning /usr/bin/nosuchprogram: No such file or directory
Aug 07 22:25:45 localhost.localdomain systemd[1]: broken.service: Main process exited, code=exited, status=203/EXEC
Aug 07 22:25:45 localhost.localdomain systemd[1]: broken.service: Failed with result 'exit-code'.
```

</details>

**That is the whole failure chain in four lines**, and it is the same
`203/EXEC` from the last lesson with the reason attached: `Unable to locate
executable`. `systemctl status` gave the code; the journal gives the sentence.

The journal is **structured**, not a text file. Every entry carries fields
(the unit, the PID, the executable, the priority, the boot ID) and
`journalctl` queries them.

| Query | Shows |
| --- | --- |
| `journalctl -u nginx` | One unit |
| `journalctl -f` | Follow, like `tail -f` |
| `journalctl -n 50` | Last 50 lines |
| `journalctl -b` | This boot only |
| `journalctl -b -1` | The **previous** boot |
| `journalctl --since '1 hour ago'` | By time, in plain English |
| `journalctl --since 09:00 --until 10:00` | A window |
| `journalctl -p err` | Priority error and worse |
| `journalctl -k` | Kernel messages, like `dmesg` |
| `journalctl _UID=1000` | By any structured field |
| `journalctl -o json-pretty` | Every field of every entry |

**`journalctl -b -1` is the one that earns its place.** After an unexplained
reboot, the previous boot's log is right there, including the last thing that
happened before the machine went down. With text logs that is an archaeology
exercise across rotated files.

Combining is where it gets useful:

```
journalctl -u nginx -p err --since today
journalctl -b -1 -p warning --no-pager | tail -50
```

**Priorities** run 0 to 7: emerg, alert, crit, err, warning, notice, info, debug.
`-p err` means err *and worse*, which is the useful default when scanning.

## Persistence

**The journal is not always kept across reboots**, and which behaviour you get
depends on whether `/var/log/journal/` exists.

```bash
sudo journalctl --disk-usage        # how much it is using
ls -d /var/log/journal 2>/dev/null || echo "volatile: logs are lost at reboot"
```

To make it persistent:

```
sudo mkdir -p /var/log/journal
sudo systemd-tmpfiles --create --prefix /var/log/journal
sudo systemctl restart systemd-journald
```

Or set `Storage=persistent` in `/etc/systemd/journald.conf`.

**Check this on any machine you inherit**, because discovering that logs are
volatile *after* the reboot you needed them for is a bad afternoon. The RHEL
family defaults to persistent; Debian historically did not, and container images
generally do not.

`SystemMaxUse=1G` in `journald.conf` caps the size, and
`journalctl --vacuum-time=30d` trims by age.

<details class="deeper">
<summary>If you already administer Linux: the identity commands, and what each one writes</summary>

Four commands configure the things every machine needs, and each replaces editing
a file.

**`hostnamectl`** sets the name, and it distinguishes three: the **static**
hostname in `/etc/hostname`, the **transient** one the kernel currently has, and a
**pretty** one for display. `hostnamectl set-hostname web01.example.com` sets the
static one and applies it immediately.

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ hostnamectl | head -7; echo "--- time ---"; timedatectl | head -6
  Transient hostname: localhost
     Static hostname: (unset)
           Icon name: computer-vm
             Chassis: vm 🖴
          Machine ID: fbe3cf662cb64de7a1d91f9d0cad9413
             Boot ID: 4deecf7538d74e608cdb644b4c853e72
        AF_VSOCK CID: 3
--- time ---
               Local time: Fri 2026-08-07 22:25:55 CDT
           Universal time: Sat 2026-08-08 03:25:55 UTC
                 RTC time: Sat 2026-08-08 03:25:56
                Time zone: America/Chicago (CDT, -0500)
System clock synchronized: yes
              NTP service: active
```

`Machine ID` is worth knowing about. It is in `/etc/machine-id`, generated at
first boot, and it identifies the machine to the journal and to several other
things. **Cloning a VM without clearing it** gives two machines the same ID,
which breaks journal separation and, on some setups, DHCP, because
systemd-networkd derives the DHCP client identifier from it. Truncate the file
to zero bytes before taking an image and it regenerates on next boot.

**`timedatectl`** sets the timezone and the clock. `System clock synchronized:
yes` and `NTP service: active` are the two lines to check, and they are the
same question lesson 32 asked from chrony's side. `timedatectl set-timezone
Europe/London` repoints `/etc/localtime`, which is a symlink, lesson 25 again.

**`localectl`** sets the system locale and console keymap, writing
`/etc/locale.conf`. Relevant because of the sorting and formatting consequences
from lesson 21.

**`loginctl`** manages login sessions: `loginctl list-sessions`, `loginctl
terminate-user jordan` to end everything a user has open, which is the tidy
version of the `pkill -u` in the offboarding sequence.

All of them take `--help` and all of them write files you could edit by hand. The
reason to use the commands is that they apply the change immediately as well as
persisting it, which editing does not.

</details>

<details class="deeper">
<summary>If you already administer Linux: what the journal indexes, and querying by field</summary>

Every entry carries fields, and the ones prefixed with an underscore are
**trusted**, added by journald itself from the sending process's credentials
rather than supplied by the sender, so they cannot be forged by an application
writing misleading log lines.

```
journalctl -o json-pretty -n1
```

shows the lot. The ones worth knowing:

| Field | Is |
| --- | --- |
| `_SYSTEMD_UNIT` | Which unit. What `-u` matches. |
| `_PID`, `_UID`, `_GID` | The sending process's identity, verified |
| `_COMM`, `_EXE` | The command name and full binary path |
| `_HOSTNAME`, `_BOOT_ID` | Machine and boot |
| `PRIORITY` | 0 to 7 |
| `MESSAGE_ID` | A UUID identifying a *kind* of message |

Querying by field is exact where grep is approximate:

```
journalctl _COMM=sshd --since today
journalctl _UID=1000 -p warning
journalctl _SYSTEMD_UNIT=nginx.service _PID=1234
```

`journalctl -F _SYSTEMD_UNIT` lists every distinct value a field has taken, which
is how you find out what has been logging at all.

**`MESSAGE_ID` is the underused one.** systemd assigns stable UUIDs to defined
events, so `journalctl MESSAGE_ID=$(...)` finds every occurrence of a specific
*kind* of event regardless of how the text was worded, which is what makes
journal queries survive a version upgrade where grep patterns do not.

**Forwarding.** `ForwardToSyslog=yes` in `journald.conf` sends everything to
rsyslog as well, which is how a machine using the journal locally still ships to a
central syslog collector. `systemd-journal-remote` and `journalctl -o export`
handle journal-native shipping, which preserves the fields; syslog forwarding
flattens everything to text and loses them.

**`journalctl --verify`** checks the journal files' integrity, and with **FSS**
(`journalctl --setup-keys`) it can be made tamper-evident: entries are sealed
with a forward-secure key so an attacker with root cannot retroactively edit the
log without detection. Rarely deployed and worth knowing exists.

</details>

<details class="deeper">
<summary>If you already administer Linux: timers versus cron, decided properly</summary>

Lesson 30 listed what timers add. The honest version of when to use which:

**Use a timer** when the job is on a systemd machine you manage, and any of these
matter: you want the output in the journal automatically; the machine is sometimes
off and `Persistent=true` should catch up; it runs across a fleet and
`RandomizedDelaySec` should stagger it; it needs a dependency such as the network;
or it should be resource-limited so a runaway job cannot take the machine down.

**Use cron** when the schedule is trivial and legibility matters more than
features, when the machine may not run systemd, or when everyone on the team can
read a crontab and nobody has met a timer.

The strongest argument for timers is not on the feature list: a failing timer
appears in `systemctl --failed`, and a failing cron job appears nowhere. That
single difference is why a broken cron job runs unnoticed for three weeks and
a broken timer is visible in the command you already run on any machine
behaving oddly.

Migrating one is mechanical. `systemd-run --on-calendar='*-*-* 02:30:00'
/usr/local/bin/backup.sh` creates a transient timer immediately, which is the
fastest way to test the schedule before writing unit files.

**Two gotchas.** A timer with no matching service does nothing and reports
nothing useful, so the names must correspond: `backup.timer` activates
`backup.service` unless `Unit=` says otherwise. And **`Type=oneshot` is what
you want** for a scheduled job; the default `Type=simple` makes systemd
consider the service active for as long as the script runs, which interacts
badly with `OnUnitActiveSec=`.

</details>

## Across distributions

systemd is the same everywhere. The differences are defaults:

| | RHEL family | Debian family |
| --- | --- | --- |
| Journal persistent by default | **Yes** | Historically no; now usually yes |
| Journal location | `/var/log/journal/` | same |
| rsyslog also installed | Usually | Usually |
| Default target on a server | `multi-user.target` | `multi-user.target` |

**Both families frequently run rsyslog alongside the journal**, so the same
event is in `/var/log/messages` *and* queryable with `journalctl`. That is not
duplication by accident (it is how central log shipping keeps working) and it
means `grep` on a text file and `journalctl` are both valid on the same
machine.

## Prove it

```bash
# What state does this machine boot to
systemctl get-default

# What is scheduled, and has it been running
systemctl list-timers --all

# Is the journal being kept
sudo journalctl --disk-usage
ls -d /var/log/journal 2>/dev/null || echo "volatile"

# What went wrong, most recently
journalctl -p err -b --no-pager | tail -20

# What went wrong last time the machine went down
journalctl -b -1 -p err --no-pager | tail -20
```

**`systemctl list-timers --all` includes timers that are not running**, which is
the version to use when something scheduled has stopped happening.

## What trips people up

### 1. The wrong default target

`systemctl get-default` reports `graphical.target` on a server.

`sudo systemctl set-default multi-user.target`, then reboot. `isolate` switches
now and does not persist.

### 2. `isolate` on a production machine

It stops everything not wanted by the target you named, which over SSH can include
your session.

`set-default` plus a scheduled reboot is nearly always what you meant.

### 3. The journal is not persistent

`/var/log/journal/` does not exist, so logs live in `/run` and vanish at
reboot, discovered after the reboot you needed them for.

Create the directory, or set `Storage=persistent`. Check it on any machine you
inherit.

### 4. Enabling the service instead of the timer

`systemctl enable backup.service` runs the backup at every boot. The timer is what
schedules it.

`systemctl enable --now backup.timer`, and confirm with `list-timers`.

### 5. Expecting `journalctl` alone to show everything

Applications that write their own files (nginx, Apache, many databases) are
not in the journal unless they log to stdout under systemd.

`journalctl -u name` **and** the service's own log directory.

## Work it through

A server rebooted overnight and nobody knows why. It is up and healthy now.

Reason it out before reading on.

**The whole investigation is the previous boot**, and the journal has it if it is
persistent. Check that first, because if it is not, everything below is
unavailable and the answer is elsewhere:

```
ls -d /var/log/journal && journalctl --list-boots | tail -5
```

**`--list-boots` numbers them**, with 0 the current and -1 the previous.

Then read the end of the previous boot:

```
journalctl -b -1 -n 50 --no-pager
```

The last lines before the log stops tell you which of three things happened, and
they look quite different:

**A clean shutdown** ends with `Stopped` and `Reached target Shutdown`
messages, so something *asked* for the reboot, and the question becomes what.
`journalctl -b -1 -u systemd-logind` shows a user-initiated one, and an
unattended-upgrade or a patching tool will have logged it.

A kernel panic or hardware fault ends abruptly, and anything captured will be
at priority `emerg` or `crit`:

```
journalctl -b -1 -p crit --no-pager
```

**Nothing at all**, the log simply stops mid-sentence, means the machine lost
power or was reset. There is no software evidence because there was no
software left to write any. On a VM that is the hypervisor; on hardware it is
the power supply or a watchdog, and the out-of-band management log from lesson
11 is the only remaining witness.

Two more places worth checking:

```
journalctl -b -1 -p err | tail -30      # errors before the end
last -x | head                           # reboot and shutdown records
```

`last -x` includes `reboot` and `shutdown` pseudo-entries with timestamps, and
distinguishes a clean shutdown from a crash by whether a matching `shutdown`
record exists.

Now the point worth extracting. **The journal makes "what happened before the
machine went down" a single command**, and that is the capability that most
justifies it over text logs. `-b -1` crosses the reboot boundary, keeps kernel and
userspace messages interleaved in one timeline, and does not care that the log
files rotated.

The habit: **check journal persistence on every machine you inherit, before you
need it.** `ls -d /var/log/journal` is one command, and the alternative is finding
out at the exact moment the evidence would have mattered.

## Try it

Optional, on any machine.

1. `systemctl get-default` and say whether it is right for the machine.
2. `systemctl list-timers --all` and find one that has never run.
3. `systemd-analyze calendar 'Mon *-*-* 09:00:00'` and read the next firing times.
4. `journalctl -b -n 20`, then `journalctl -b -1 -n 20` if there is a previous
   boot.
5. `journalctl -p err -b | wc -l`, then read a few.
6. `journalctl -u sshd --since today`.
7. `sudo journalctl --disk-usage` and `ls -d /var/log/journal`.
8. `hostnamectl` and `timedatectl`, and check the two synchronisation lines.

**Verification step.** You have it when you can find out what a machine was doing
in the minute before its last unexplained reboot, in one command.

## Check yourself

<details class="qa">
<summary>What replaced runlevels, and why is a target better than a number?</summary>

**Targets.** `multi-user.target` is the old runlevel 3, `graphical.target` is 5,
`rescue.target` is 1.

A runlevel was a number whose meaning was a convention, implemented by shell
scripts named `S20foo` and `K80bar` so they ran in an order somebody had chosen by
hand. It was entirely sequential and nothing in it could express *why* one service
needed another.

A target is a named state with a **dependency graph**. Each unit declares what
it needs and what it must follow, and systemd derives the order, which means
it can also start independent things in parallel, and can tell you why
something ran when it did.

`systemctl list-dependencies multi-user.target` shows the graph; a runlevel could
only ever show you a directory of numbered symlinks.

</details>

<details class="qa">
<summary>What is the difference between <code>systemctl set-default</code> and <code>systemctl isolate</code>?</summary>

**`set-default` changes what the machine boots to** and does nothing now. It
writes a symlink at `/etc/systemd/system/default.target`.

**`isolate` switches to a target immediately** and does not persist. At the next
reboot the machine returns to its default.

It is the same distinction as `enable` versus `start` in the previous lesson: one
writes a symlink for next time, one changes what is happening now.

**`isolate` also stops everything not wanted by the target**, which on a running
server is abrupt and can include the session you are typing in. `set-default`
plus a scheduled reboot is nearly always what was meant.

</details>

<details class="qa">
<summary>Why enable the <code>.timer</code> rather than the <code>.service</code>, and what does <code>Persistent=true</code> do?</summary>

**The timer is what schedules; the service is what runs.** Enabling the service
would start it at every boot, which for a nightly backup means it runs once at
boot and never again. The service usually has no `[Install]` section for exactly
this reason, so it cannot be enabled by accident.

`systemctl enable --now backup.timer`, then confirm with `systemctl list-timers`.

**`Persistent=true` runs a missed occurrence at the next boot.** If the machine
was off at 02:30, the job runs shortly after it comes up rather than being skipped
until tomorrow.

That is anacron's behaviour without needing anacron, and it is one of the
clearer advantages over cron, which simply misses anything scheduled while the
machine was down.

</details>

<details class="qa">
<summary>What does <code>journalctl -b -1</code> show, and why is it hard to reproduce with text logs?</summary>

**The complete log of the previous boot**, kernel and userspace messages
interleaved in one timeline, ending at whatever the machine managed to write
before it went down.

With text logs the same question means finding which rotated files cover that
window, opening several of them, reconciling different timestamp formats, and
manually interleaving kernel messages from `dmesg` with service messages from
elsewhere. The boot boundary is not marked in any of them.

The journal records a boot ID on every entry, so `-b -1` is an exact query rather
than a reconstruction.

**It only works if the journal is persistent.** `ls -d /var/log/journal`, if
that directory does not exist, logs live in `/run` and the previous boot is
gone. Checking that on a machine you inherit, before you need it, is one
command.

</details>

<details class="qa">
<summary>Why do many machines run both journald and rsyslog?</summary>

**Because they solve different halves of the problem.** journald gives structured,
indexed, queryable local logging with verified fields. rsyslog gives mature
network forwarding to a central collector, which is what compliance and
correlation across a fleet require.

`ForwardToSyslog=yes` in `journald.conf` sends everything to rsyslog as well, so
the same event is queryable with `journalctl` locally and shipped centrally as
text.

The cost is that syslog forwarding **flattens** the structure: the trusted
fields (`_PID`, `_UID`, `_EXE`) become part of a text line or are dropped, and
the receiving end cannot query them.

`systemd-journal-remote` ships journal-native and preserves the fields, and is the
better answer where the whole fleet is systemd. rsyslog remains the pragmatic
choice when it is not, or when the collector already exists.

</details>

## References

- [systemd.target(5)](https://man7.org/linux/man-pages/man5/systemd.target.5.html) - Linux man-pages project. Accessed 2026-08-07.
- [systemd.special(7)](https://man7.org/linux/man-pages/man7/systemd.special.7.html) - Linux man-pages project. Accessed 2026-08-07.
- [journalctl(1)](https://man7.org/linux/man-pages/man1/journalctl.1.html) - Linux man-pages project. Accessed 2026-08-07.
- [journald.conf(5)](https://man7.org/linux/man-pages/man5/journald.conf.5.html) - Linux man-pages project. Accessed 2026-08-07.
- [systemd.time(7)](https://man7.org/linux/man-pages/man7/systemd.time.7.html) - Linux man-pages project. Accessed 2026-08-07.
- [hostnamectl(1)](https://man7.org/linux/man-pages/man1/hostnamectl.1.html) - Linux man-pages project. Accessed 2026-08-07.

Command output was captured on the podman machine, which runs real systemd.
Blocks without a distribution and architecture header are illustrative.
