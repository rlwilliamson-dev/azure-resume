---
title: "It needs to run at 2am and you would like to be asleep"
description: "Putting a job in the background, keeping it alive after you disconnect, and handing it to something that will run it every night without you. Plus the five fields everyone gets wrong at least once."
track: "linux-plus"
level: "working"
order: 310
objectives:
  - "Move a job between foreground and background and list what is running"
  - "Keep a long job alive after the session ends"
  - "Write and read a crontab, field by field"
  - "Choose between cron, at, anacron, and a systemd timer"
prerequisites: ["processes-and-signals"]
tags: ["linux", "linux-plus", "cron", "jobs", "scheduling"]
updated: 2026-08-07
draft: false
examObjectives:
  - exam: "xk0-006"
    domain: "2.0"
    objective: "2.3"
sources:
  - title: "crontab(5)"
    url: "https://man7.org/linux/man-pages/man5/crontab.5.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "crontab(1)"
    url: "https://man7.org/linux/man-pages/man1/crontab.1.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "at(1)"
    url: "https://manpages.debian.org/stable/at/at.1.en.html"
    publisher: "Debian Project"
    accessed: 2026-08-07
    tier: 1
  - title: "systemd.timer(5)"
    url: "https://man7.org/linux/man-pages/man5/systemd.timer.5.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "nohup(1)"
    url: "https://man7.org/linux/man-pages/man1/nohup.1.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "anacron(8)"
    url: "https://man7.org/linux/man-pages/man8/anacron.8.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
symptoms:
  - symptom: "Long job died when the SSH session dropped"
    anchor: "1-the-job-died-with-the-session"
  - symptom: "Cron job never runs, or runs far more often than intended"
    anchor: "3-the-fields-are-in-the-wrong-order"
---

> **Before you read.** You start a job that will take four hours. Your
> terminal is now useless, it belongs to that job until it finishes.
>
> You could open a second terminal. Then your laptop sleeps, the SSH session
> drops, and the job dies with it.
>
> Two different problems hiding behind one inconvenience: **how do you get your
> terminal back, and how do you make a job outlive the session that started it?**
> They have different answers, and confusing them is why "I ran it in the
> background and it still died" is such a common sentence.

The third problem is the one that matters most in practice, and it is what most
of this lesson is about: how to make something run every night when nobody is
logged in at all.

### Some words you will need

<dl class="terms">
<dt>job</dt>
<dd>A command the shell is managing. Numbered per shell, unlike a PID.</dd>
<dt>foreground</dt>
<dd>Has the terminal. You cannot type until it finishes.</dd>
<dt>background</dt>
<dd>Running, but the prompt is yours again.</dd>
<dt>SIGHUP</dt>
<dd>The signal sent to a session's processes when the terminal goes away.</dd>
<dt>cron</dt>
<dd>A daemon that runs commands on a schedule, whether anyone is logged in or not.</dd>
</dl>

## What breaks without this

**Long jobs die at the worst moment**, usually a migration or a restore, three
hours in.

**Nothing happens overnight.** Backups, log rotation, certificate renewal, and
report generation are all scheduled work, and a job that never fires fails
silently by definition.

**Or it happens far too often.** A misread crontab field turns "monthly" into
"every minute", and cron is happy to comply.

## Getting your terminal back

| Action | Does |
| --- | --- |
| `command &` | Start it in the background |
| Ctrl+Z | Suspend the foreground job |
| `bg` | Resume the suspended job in the background |
| `fg` | Bring a background job to the foreground |
| `jobs` | List this shell's jobs |
| `fg %2` | Bring job 2 forward |
| Ctrl+C | Send SIGINT to the foreground job |

The usual rescue, when you have started something long without thinking:

```
Ctrl+Z          # suspend it
bg              # carry on in the background
jobs            # confirm
```

**Job numbers belong to one shell.** `%1` in this terminal is unrelated to `%1` in
another, and `jobs` in a new session shows nothing. PIDs are global; job numbers
are not.

**Ctrl+Z sends SIGSTOP** and the process enters state `T` from the previous
lesson. A job left suspended is not running at all, which is worth remembering
before wondering why it never finished.

## Surviving the disconnect

This is the second problem, and `&` does not solve it.

When a terminal closes, the kernel sends **SIGHUP** to the processes in that
session, and the default action is to terminate. A background job is still in that
session, so it dies with everything else.

| Approach | Survives logout | Reattach later | Notes |
| --- | --- | --- | --- |
| `command &` | **No** | No | Only frees the prompt |
| `nohup command &` | Yes | No | Output goes to `nohup.out` |
| `setsid command` | Yes | No | New session, fully detached |
| `systemd-run --user` | Yes | No | Managed unit, logs in the journal |
| `tmux` or `screen` | **Yes** | **Yes** | What you actually want |

**`nohup` makes the process ignore SIGHUP** and redirects its output, since there
will be no terminal to write to:

```
nohup ./long-migration.sh > migration.log 2>&1 &
```

**`tmux` is the better answer for interactive work.** The session lives on the
server, and you attach and detach from it:

```
tmux new -s migration     # start
# Ctrl+B then d           to detach
tmux attach -t migration  # reattach, from anywhere, later
```

The difference is that `nohup` gives you a process you cannot look at again,
and `tmux` gives you a terminal you can come back to, including from a
different machine after your laptop has been closed all night. For anything
you might need to interact with, that is worth the small learning cost.

## cron

`crontab -u jordan -` installs a crontab for jordan, read from standard input. The
command then lists it back and looks at where it went.

<details class="predict">
<summary>A user's crontab is not a file in their home directory. Where does it land, who owns it, and what permissions would you expect on something holding commands that run as that user?</summary>

```bash
# Debian 13 (trixie), x86_64
$ printf '# m h dom mon dow  command\n30 2 * * *  /usr/local/bin/backup.sh\n*/15 * * * *  /usr/local/bin/check.sh\n0 3 * * 0  /usr/local/bin/weekly.sh\n' | crontab -u jordan -; echo '--- jordan crontab ---'; crontab -u jordan -l; echo '--- where it was written ---'; ls -l /var/spool/cron/crontabs/
--- jordan crontab ---
# m h dom mon dow  command
30 2 * * *  /usr/local/bin/backup.sh
*/15 * * * *  /usr/local/bin/check.sh
0 3 * * 0  /usr/local/bin/weekly.sh
--- where it was written ---
total 4
-rw-------. 1 jordan crontab 313 Aug  8 03:23 jordan
```

</details>

**`/var/spool/cron/crontabs/`, mode 600, owned by the user and the `crontab`
group.** Spool rather than home, because a home directory can be on NFS, be
unmounted, or be deleted at offboarding, and the scheduler still has to be able to
read it. Mode 600 because those lines run as that user, so being able to write the
file is being able to run commands as them.

Never edit that file directly. `crontab -e` writes to a temporary copy,
validates it, and installs it atomically, the same shape as `visudo`. Editing
the spool file in place can leave `cron` reading a half-written crontab, and
on some implementations the daemon only notices a change through `crontab`'s
own signal.

Five time fields, then the command. In order:

| Field | Range | `30 2 * * *` |
| --- | --- | --- |
| Minute | 0-59 | 30 |
| Hour | 0-23 | 2 |
| Day of month | 1-31 | any |
| Month | 1-12 | any |
| Day of week | 0-7, both 0 and 7 are Sunday | any |

So that first line is **02:30 every day**. Reading right to left helps: any day of
week, any month, any day of month, hour 2, minute 30.

| Syntax | Means |
| --- | --- |
| `*` | Every value |
| `*/15` | Every 15, so minutes 0, 15, 30, 45 |
| `1,15` | Only those values |
| `9-17` | The range |
| `@daily`, `@reboot` | Shorthands: midnight, and at boot |

**The three captured lines read as:** 02:30 daily, every fifteen minutes, and
03:00 every Sunday.

Note the file is mode 600 and owned by jordan. Never edit `/var/spool/cron/`
directly: `crontab -e` validates the syntax before installing, and a malformed
file edited by hand can stop **every** job in it from running.

| Command | Does |
| --- | --- |
| `crontab -e` | Edit yours, with validation |
| `crontab -l` | List yours |
| `crontab -r` | **Delete** yours. No confirmation. |
| `crontab -u jordan -e` | Edit somebody else's, as root |

`crontab -r` sits next to `-e` on the keyboard and removes the whole crontab
without asking. `crontab -l > ~/crontab.bak` before editing is a two-second
habit worth having.

### System crontabs, which have a sixth field

`/etc/crontab` and files in `/etc/cron.d/` add a **user** field between the time
and the command:

```
30 2 * * *  root  /usr/local/bin/backup.sh
```

**That extra field is the single most common cron mistake.** Put a user crontab
line in `/etc/cron.d/` and cron tries to run `root` as the command; put a system
line in a user crontab and it tries to run `/usr/local/bin/backup.sh` as an
argument to a command called `root`. Neither works and the error goes to mail
nobody reads.

`/etc/cron.daily/`, `/etc/cron.hourly/`, and `/etc/cron.weekly/` are simpler
still: drop an executable script in and it runs on that schedule, no time
fields at all. **The script must be executable and must have no file
extension** on many systems: `run-parts` skips anything with a dot in the
name, which is why `backup.sh` in `/etc/cron.daily/` silently never runs.

<details class="predict">
<summary>A job is meant to run at 02:30 on the first of each month. Somebody writes <code>30 2 1 * *</code> and a colleague writes <code>2 30 1 * *</code>. What does each actually do?</summary>

**`30 2 1 * *` is correct**, minute 30, hour 2, day-of-month 1. It runs at
02:30 on the first.

**`2 30 1 * *` never runs at all.** The fields are minute, hour, day-of-month, so
this asks for minute 2 of hour 30. There is no hour 30.

What makes this dangerous is that **cron does not reject it.** Depending on
the implementation it is either accepted and simply never matches, or rejected
with a message sent to the user's mail, which nobody reads. Either way there
is no error at the terminal and no log entry saying "this will never fire".
The job just quietly does not exist.

The same class of mistake in the other direction is worse. `* 2 * * *` is not
"2am". The first field is minute, and `*` means *every* minute, so it runs 60
times between 02:00 and 02:59. A backup written that way runs sixty times a
night until somebody notices the load.

**Three defences.** Read the fields aloud right to left: day of week, month, day
of month, hour, minute. Use `crontab -l` afterwards and check it against what you
meant. And for anything non-obvious, `systemd-analyze calendar` will tell you the
next few firing times of a systemd timer expression, which is the closest thing to
a dry run that scheduling offers.

</details>

<details class="deeper">
<summary>If you already administer Linux: what cron does when a job is still running from last time</summary>

Nothing. That is the answer, and it is the failure mode that takes a machine down
rather than merely failing to run.

**Cron starts the next run on schedule regardless of whether the previous one
has finished.** A backup scheduled `*/15` that normally takes two minutes will
one day take twenty (because the dataset grew, or the network was slow) and
now two copies are running against the same data. Then three. Each is slower
than the last because they are competing, so the overlap widens, and a job
that was fine for two years saturates the disk in an afternoon. The classic
signature is a load average climbing all night with dozens of identical
processes in `ps`.

**`flock` is the fix and it belongs in the crontab line, not the script:**

```
*/15 * * * * /usr/bin/flock -n /var/lock/backup.lock /usr/local/bin/backup.sh
```

`-n` means fail immediately rather than wait, so an overlapping run exits quietly
with status 1 instead of queueing. If you would rather it waited, `-w 60` gives it
a timeout. Putting it in the crontab rather than inside the script means the lock
covers the whole job including any interpreter start-up, and it works for scripts
you did not write.

**A lock file you manage yourself is worse than it looks**, which is why `flock`
exists. `[ -f /tmp/lock ] && exit` has a race between the test and the create, and
leaves a stale lock behind whenever the job is killed or the machine reboots
mid-run. `flock` uses a kernel lock on an open file descriptor, so it is atomic and
the lock disappears when the process does, however it died.

**Systemd timers handle this natively.** A `.timer` triggers a `.service`, and
a service that is already active is not started again. The overlap problem
does not exist. That is one of the better arguments for timers, alongside
three others:

- `Persistent=true` runs a missed job once after boot, which is what `anacron`
  exists to do for cron.
- `RandomizedDelaySec=` spreads a fleet out. A thousand machines with `0 3 * * *`
  all hit the backup server at 03:00:00; `RandomizedDelaySec=1800` scatters them
  across half an hour without anyone editing a schedule.
- `OnUnitActiveSec=` schedules relative to the *last finish*, so "every 15 minutes
  after it completes" is expressible, which crontab syntax simply cannot say.

</details>

## The environment problem

A cron job runs with almost nothing: a minimal `PATH`, no shell startup files, and
frequently a different `HOME`. This is lesson 21 arriving with a schedule attached,
and it is the reason most cron jobs fail the first time.

**The three rules that avoid nearly all of it:**

Use absolute paths for everything, the command, and every file it touches.
`/usr/local/bin/backup.sh` rather than `backup.sh`, and `/srv/data` rather
than `data`.

Set `PATH` at the top of the crontab. Cron accepts variable assignments as
lines of their own, and they apply to every job in the file:

```
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
MAILTO=ops@example.com
30 2 * * *  /usr/local/bin/backup.sh
```

**Capture the output**, because otherwise cron mails it to the local user and
nobody reads local mail:

```
30 2 * * *  /usr/local/bin/backup.sh >> /var/log/backup.log 2>&1
```

`MAILTO=""` suppresses mail entirely, which is right only once you are logging
somewhere you actually look.

**And the percent sign is a trap.** In a crontab, `%` means a newline and
everything after the first one becomes standard input to the command. `date
+%Y-%m-%d` in a cron line does not do what it does at a prompt. It has to be
`\%`. This catches everybody once, usually on a log filename.

<details class="deeper">
<summary>If you already administer Linux: at, anacron, and choosing between the four</summary>

**`at` runs something once**, at a time you name, and then forgets it:

```
echo '/usr/local/bin/one-off.sh' | at 02:00 tomorrow
atq          # what is queued
atrm 3       # cancel job 3
```

It accepts human times (`at now + 2 hours`, `at 4pm friday`) and is the right
tool for "restart this after the change window" rather than editing a crontab
you then have to remember to remove. It needs `atd` running, which is
frequently not installed.

**`anacron` exists because cron assumes the machine is on.** A laptop or an
intermittently-powered server misses every job scheduled while it was off, and
cron never catches up. anacron works in **days elapsed** rather than clock times:
if a daily job has not run for a day, it runs it shortly after boot. That is why
`/etc/cron.daily/` on a desktop distribution is usually driven by anacron and not
by cron.

It cannot do anything more frequent than daily, and it is not appropriate for
anything that must happen at a specific time.

**Choosing between the four:**

| Need | Use |
| --- | --- |
| Once, at a time | `at` |
| Repeatedly, machine always on | cron |
| Repeatedly, machine sometimes off | anacron, or a timer with `Persistent=true` |
| Anything on a modern managed server | a systemd timer |

**Access control:** `/etc/cron.allow` and `/etc/cron.deny` decide who may
install a crontab, with `at.allow` and `at.deny` doing the same for `at`. If
`cron.allow` exists, only the users in it may, and an empty `cron.allow`
denies everybody, which is a legitimate hardening measure and a surprising one
to inherit.

</details>

<details class="deeper">
<summary>If you already administer Linux: systemd timers, and why they are winning</summary>

A timer is two units: a `.timer` describing when, and a `.service` describing what.

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

```
sudo systemctl enable --now backup.timer
systemctl list-timers
```

**Five things they do that cron does not**, and together they are why distributions
have been migrating:

**Logging.** Output goes to the journal automatically, `journalctl -u
backup.service`, rather than to mail nobody reads. This alone is most of the
argument.

**`Persistent=true`** runs a missed job at next boot, which is anacron's behaviour
without a second tool.

**`RandomizedDelaySec`** spreads load. A hundred machines with the same cron line
all hit the backup server at exactly 02:30; a randomised delay staggers them.

**Dependencies.** `After=network-online.target` in the service, so a job that needs
the network waits for it rather than failing at boot.

**Resource control.** The same `MemoryMax=`, `CPUQuota=`, and `Nice=` available to
any unit, so a runaway backup cannot take the machine with it.

`OnCalendar` syntax is different from cron and `systemd-analyze calendar
'*-*-* 02:30:00'` prints the next firing times. A genuine dry run, which cron
has never had. `OnUnitActiveSec=` schedules relative to the last run instead,
which is what you want for "every 15 minutes of uptime" rather than "at :00,
:15, :30".

When to stay with cron: portability across non-systemd systems, and the fact
that everyone can read a crontab. A five-field line is still the clearest
statement of a simple schedule there is.

</details>

## Across distributions

| | RHEL family | Debian family |
| --- | --- | --- |
| Package | `cronie` | `cron` |
| User crontabs | `/var/spool/cron/` | `/var/spool/cron/crontabs/` |
| System | `/etc/crontab`, `/etc/cron.d/` | same |
| anacron | included in `cronie` | separate `anacron` package |
| `at` | `at`, often not installed | `at`, often not installed |

**`cronie` versus `cron` matters when a machine has neither.** A minimal
server image frequently ships without any cron daemon at all, and a crontab
installed on it is stored correctly and never runs. `systemctl status crond`
on RHEL, `systemctl status cron` on Debian, note the daemon names differ too.

## Prove it

After adding a scheduled job:

```bash
# Is it installed and does it read the way you meant
crontab -l

# Is the daemon actually running
systemctl status crond    # RHEL family
systemctl status cron     # Debian family

# Did it run, and what happened
sudo journalctl -u crond --since today | grep backup
sudo grep CRON /var/log/syslog | tail

# For a timer, the definitive answer
systemctl list-timers
systemd-analyze calendar '*-*-* 02:30:00'
```

**And the test that removes all doubt: schedule it for two minutes from now.**
Change the time, watch it fire, read the log, then set the real schedule. Waiting
until 02:30 to find out that `PATH` was wrong is a day lost per attempt.

## What trips people up

### 1. The job died with the session

`&` frees the prompt and does not detach the process. SIGHUP at logout kills it.

`nohup ... &` for fire-and-forget, `tmux` for anything you might want to look at
again.

### 2. The cron job runs nothing

`PATH` is minimal and no startup files are read. `command not found` goes to mail
nobody reads.

Absolute paths, a `PATH=` line at the top, and redirect output to a log file.

### 3. The fields are in the wrong order

Minute, hour, day-of-month, month, day-of-week. `* 2 * * *` is every minute of the
2am hour, not 2am.

Read them aloud, and check with `crontab -l` afterwards.

### 4. The sixth field

`/etc/crontab` and `/etc/cron.d/` take a **user** field that user crontabs do not.
Getting it wrong means the job silently never runs.

### 5. A dot in a `/etc/cron.daily/` filename

`run-parts` skips files with extensions. `backup.sh` there never runs; `backup`
does. It must also be executable.

## Work it through

A nightly backup has not run for three weeks. `crontab -l` shows the entry and
looks right. The script works when run by hand.

Reason through the order before reading on.

**First: is the daemon running at all?**

```
systemctl status crond    # or cron
```

A minimal image frequently ships without one. A crontab on a machine with no cron
daemon is stored perfectly and never executes, and `crontab -l` looks exactly the
same either way. This is the cheapest check and it is not the first thing most
people try.

**Second: did cron attempt it?**

```
sudo journalctl -u crond --since '3 weeks ago' | grep backup
sudo grep CRON /var/log/syslog | grep backup | tail
```

That splits the problem cleanly. **No log entries** means cron never tried, a
schedule problem, a daemon problem, or an access-control problem. **Entries
present** means it tried and the script failed, which is a completely
different investigation.

**If cron tried and it failed**, the answer is nearly always the environment:

```
env -i /bin/sh -c '/usr/local/bin/backup.sh'
```

Straight from lesson 21. This reproduces the minimal-environment case in one
command rather than waiting for tomorrow night, and a `command not found` here
names the problem immediately.

**If cron never tried**, check the schedule against what you meant, and check
`/etc/cron.allow`, if that file exists and the user is not in it, they may
install a crontab and cron will never run it.

**And this is what would have caught it in week one: where was the output
going?** If the line has no redirection, cron mailed it to the local user, and
`/var/spool/mail/` on a server nobody reads is where three weeks of nightly error
messages are sitting. `mail` or `cat /var/spool/mail/root` may hand you the answer
directly.

Now the point worth extracting. **A scheduled job that fails is silent by
construction**. There is nobody logged in to see it, and the default
destination for its output is a mailbox from another era. Every one of these
investigations is really about finding where the evidence went.

The habit, and it is one line: **redirect to a log file, and make the success
message carry a number.**

```
30 2 * * *  /usr/local/bin/backup.sh >> /var/log/backup.log 2>&1
```

That, plus a monitoring check on the log's *modification time*, turns "it has not
run for three weeks" from something a person eventually notices into something
that alerts on the second night. Which is the same conclusion as the backup
lesson, arriving from the scheduling side: **a check that can only report success
is not a check.**

## Try it

Optional, on any machine.

1. `sleep 300`, then Ctrl+Z, then `jobs`, then `bg`, then `jobs` again.
2. `fg` to bring it back, then Ctrl+C.
3. `nohup sleep 300 &`, then `exit` the shell, reconnect, and `pgrep -a sleep`.
4. `crontab -l > ~/cron.bak`, the habit, then `crontab -e` and add `* * * * *
   date >> /tmp/cron-test.log`.
5. Wait two minutes, then `cat /tmp/cron-test.log`. Then remove the line.
6. `systemctl list-timers` and read what is already scheduled.
7. `systemd-analyze calendar 'Mon *-*-* 09:00:00'` and check it means what you
   think.

**Verification step.** You have it when you can write a crontab line for "03:15 on
the first Sunday of the month", explain why cron cannot express that directly, and
say what you would do instead.

## Check yourself

<details class="qa">
<summary>Why does <code>command &</code> not survive logging out, and what does?</summary>

**Because `&` only moves the job into the background of the same session.** When
the terminal goes away, the kernel sends **SIGHUP** to the session's processes,
and the default action for SIGHUP is to terminate. The background job is still in
that session.

`nohup command &` makes the process ignore SIGHUP and redirects its output to
`nohup.out`, since there will be no terminal to write to.

`setsid` puts it in a new session entirely, so the HUP never reaches it.

**`tmux` or `screen` is usually the better answer**, because the session lives on
the server: you detach, close the laptop, reconnect from anywhere, and reattach to
a terminal that has been running all along. `nohup` gives you a process you cannot
look at again.

</details>

<details class="qa">
<summary>What are the five cron fields in order, and what does <code>* 2 * * *</code> actually do?</summary>

**Minute, hour, day of month, month, day of week.**

`* 2 * * *` means **every minute of the 2am hour**, sixty runs between 02:00
and 02:59. The intended `2am daily` is `0 2 * * *`.

The first field being minute rather than hour is the mistake, and cron does not
warn: the line is valid, so it is obeyed exactly.

Reading right to left helps: day of week, month, day of month, hour, minute.

The mirror-image error is `2 30 1 * *`, which asks for hour 30 and therefore
never fires at all, also without any error at the terminal.

</details>

<details class="qa">
<summary>A cron job fails with "command not found" for a command you can run. Why, and give two fixes.</summary>

**Cron supplies a minimal `PATH`**, typically `/usr/bin:/bin`, and reads none
of the shell startup files that build your interactive one. Administrative
commands in `/usr/sbin` and `/sbin` are therefore not found.

**Fix one:** use absolute paths in the job: `/usr/sbin/useradd` rather than
`useradd`. Unambiguous and immune to any `PATH`.

**Fix two:** put a `PATH=` line at the top of the crontab. Cron accepts variable
assignments as lines of their own and applies them to every job in the file.

Reproduce it without waiting for the schedule:
`env -i /bin/sh -c '/path/to/script.sh'`.

</details>

<details class="qa">
<summary>What is the extra field in <code>/etc/cron.d/</code> files, and what happens if you omit it?</summary>

**A user field**, between the five time fields and the command, naming the account
the job runs as:

```
30 2 * * *  root  /usr/local/bin/backup.sh
```

System crontabs, `/etc/crontab` and everything in `/etc/cron.d/`, have it
because they are not owned by any particular user. Personal crontabs installed
with `crontab -e` do not, because the owner is already known.

**Omit it and cron treats the first word of your command as the username**, so it
tries to run `/usr/local/bin/backup.sh` as a user that does not exist, or runs
`root` as a command. Either way the job never does what was intended, and the
error goes to mail.

The reverse mistake, including the field in a personal crontab, fails the same
way from the other direction.

</details>

<details class="qa">
<summary>Give three things a systemd timer does that cron does not.</summary>

**Logging.** Output goes to the journal automatically, so
`journalctl -u backup.service` shows what happened. cron mails it to a local
mailbox nobody reads, which is why cron failures go unnoticed for weeks.

**`Persistent=true`.** A job missed because the machine was off runs at the next
boot. cron simply skips it; anacron exists as a separate tool to cover this.

**`RandomizedDelaySec`.** Spreads load across a fleet, a hundred machines with
the same cron line all hit the backup server at exactly 02:30.

Two more worth having: **dependencies**, so `After=network-online.target` makes a
job wait for the network rather than failing at boot; and **resource control**,
since the timer's service is an ordinary unit and takes `MemoryMax=` and
`CPUQuota=`.

And a genuine dry run: `systemd-analyze calendar` prints the next firing times,
which cron has never been able to do.

</details>

## References

- [crontab(5)](https://man7.org/linux/man-pages/man5/crontab.5.html) - Linux man-pages project. Accessed 2026-08-07.
- [crontab(1)](https://man7.org/linux/man-pages/man1/crontab.1.html) - Linux man-pages project. Accessed 2026-08-07.
- [at(1)](https://manpages.debian.org/stable/at/at.1.en.html) - Debian Project. Accessed 2026-08-07.
- [systemd.timer(5)](https://man7.org/linux/man-pages/man5/systemd.timer.5.html) - Linux man-pages project. Accessed 2026-08-07.
- [nohup(1)](https://man7.org/linux/man-pages/man1/nohup.1.html) - Linux man-pages project. Accessed 2026-08-07.
- [anacron(8)](https://man7.org/linux/man-pages/man8/anacron.8.html) - Linux man-pages project. Accessed 2026-08-07.

Every block above with a distribution and architecture header was captured by running the command on a Debian 13 (trixie) container. Blocks without one are illustrative.
