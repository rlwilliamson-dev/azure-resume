---
title: "It is installed, it runs, and it is gone after a reboot"
description: "systemd replaced a pile of shell scripts with a dependency graph. What a unit is, the difference between start and enable that catches everybody once, and how to read a status output that is telling you more than it looks."
track: "linux-plus"
level: "working"
order: 340
objectives:
  - "Explain what a unit is and where unit files live"
  - "Distinguish start from enable, and say what each writes"
  - "Read systemctl status and extract the actual cause of a failure"
  - "Override a shipped unit without editing it"
prerequisites: ["common-network-services"]
tags: ["linux", "linux-plus", "systemd", "services", "units"]
updated: 2026-08-07
draft: false
examObjectives:
  - exam: "xk0-006"
    domain: "2.0"
    objective: "2.5"
sources:
  - title: "systemd(1)"
    url: "https://man7.org/linux/man-pages/man1/systemd.1.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "systemctl(1)"
    url: "https://man7.org/linux/man-pages/man1/systemctl.1.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "systemd.unit(5)"
    url: "https://man7.org/linux/man-pages/man5/systemd.unit.5.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "systemd.service(5)"
    url: "https://man7.org/linux/man-pages/man5/systemd.service.5.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "systemd.exec(5)"
    url: "https://man7.org/linux/man-pages/man5/systemd.exec.5.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "systemd.resource-control(5)"
    url: "https://man7.org/linux/man-pages/man5/systemd.resource-control.5.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
symptoms:
  - symptom: "Service works now but does not start after a reboot"
    anchor: "1-started-but-not-enabled"
  - symptom: "Edited a unit file and nothing changed"
    anchor: "2-you-edited-the-unit-and-nothing-happened"
---

> **Before you read.** You install a service, start it, test it, and close the
> ticket. Six weeks later the machine reboots during patching and the service does
> not come back.
>
> Nothing was deleted and nothing failed. The command you ran did exactly what it
> said.
>
> **What is the difference between "run this now" and "run this every time"?**

They are two separate operations with two separate commands, and merging them in
your head is the single most common systemd mistake there is. One changes what is
running; the other writes a symlink that survives a reboot.

That distinction is most of this lesson. The rest is reading a unit file and
getting a useful answer out of `systemctl status`, which contains more than it
appears to.

### Some words you will need

<dl class="terms">
<dt>unit</dt>
<dd>Anything systemd manages: a service, a mount, a timer, a socket, a target.</dd>
<dt>unit file</dt>
<dd>The INI-style file describing one. <code>nginx.service</code>.</dd>
<dt>target</dt>
<dd>A grouping unit, used to say "the machine has reached this state".</dd>
<dt>enable</dt>
<dd>To create the symlink that makes a unit start at boot. Separate from starting it.</dd>
<dt>drop-in</dt>
<dd>A small file that overrides part of a shipped unit without editing it.</dd>
</dl>

## What breaks without this

**Services do not come back after a reboot**, discovered during a maintenance
window when everyone is already busy.

**You edit a unit file and a package update overwrites it.** Twice, before anyone
works out why.

**You cannot get a cause out of a failure.** `systemctl status` prints the
information and most people read only the first line.

## Units, and where they live

Everything systemd manages is a unit, and the suffix says what kind:

| Suffix | Is |
| --- | --- |
| `.service` | A daemon or a one-shot command |
| `.target` | A grouping. `multi-user.target`, `graphical.target`. |
| `.timer` | A schedule, from lesson 30 |
| `.mount` | A filesystem, generated from `/etc/fstab` |
| `.socket` | A listening socket that can start a service on demand |
| `.path` | Watches a file and starts something when it changes |

**Three directories, and the order matters:**

| Directory | Holds | Wins |
| --- | --- | --- |
| `/usr/lib/systemd/system/` | What packages ship | Lowest |
| `/run/systemd/system/` | Runtime, generated | Middle |
| `/etc/systemd/system/` | **Yours** | **Highest** |

**Never edit anything in `/usr/lib/systemd/system/`.** A package update overwrites
it and your change disappears. Everything you write belongs in
`/etc/systemd/system/`, and `systemctl cat nginx` shows the effective result of
all three.

## A unit file

A minimal service is written below, reloaded, and started. Then two questions are
asked of it: `is-active`, and `is-enabled`.

<details class="predict">
<summary>The unit has an `[Install]` section but `enable` has not been run yet. What do those two commands report, and can both answers be what you expect at the same time?</summary>

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ sudo tee /etc/systemd/system/demo.service >/dev/null <<'EOF'
[Unit]
Description=A demonstration service
After=network-online.target

[Service]
Type=simple
ExecStart=/usr/bin/sleep 3600
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload; echo '--- started, but not enabled ---'; sudo systemctl start demo; systemctl is-active demo; systemctl is-enabled demo; echo '--- now enable it ---'; sudo systemctl enable demo; systemctl is-enabled demo
--- started, but not enabled ---
active
disabled
--- now enable it ---
Created symlink '/etc/systemd/system/multi-user.target.wants/demo.service' → '/etc/systemd/system/demo.service'.
enabled
```

</details>

**Read the middle two lines.** `active` and `disabled`, at the same time, on the
same service. It is running right now and it will not come back after a reboot.
That is the whole of the opening question, in two words of output.

**And read what `enable` actually did**: it created a symlink. Nothing else. The
service was already running and enabling did not touch it; it wrote
`/etc/systemd/system/multi-user.target.wants/demo.service` pointing at the unit,
and at boot systemd starts everything symlinked into the target it is reaching.

| Command | Effect | Survives reboot |
| --- | --- | --- |
| `systemctl start x` | Runs it now | No |
| `systemctl enable x` | Creates the symlink | Yes, but does not start it now |
| `systemctl enable --now x` | **Both** | Yes |
| `systemctl disable --now x` | Stops it and removes the symlink | — |

**`enable --now` is what you nearly always want**, and using it habitually removes
the whole category of mistake.

### The three sections

**`[Unit]`** — description and ordering. `After=` and `Before=` control *sequence*;
`Wants=` and `Requires=` control *dependency*. Those are different: `After=` says
"if both are starting, this one goes second", and says nothing about whether the
other starts at all.

**`[Service]`** — what to run.

| Key | Does |
| --- | --- |
| `Type=simple` | The command stays in the foreground. The default. |
| `Type=forking` | The command daemonises. Needs `PIDFile=`. |
| `Type=oneshot` | Runs and exits. For setup tasks. |
| `Type=notify` | The service tells systemd when it is ready |
| `ExecStart=` | The command. Must be an absolute path. |
| `ExecReload=` | What `systemctl reload` runs |
| `Restart=on-failure` | Restart if it exits non-zero |
| `User=`, `Group=` | Run as somebody other than root |
| `EnvironmentFile=` | From lesson 21 |

**`[Install]`** — what `enable` should do. `WantedBy=multi-user.target` means "put
a symlink in that target's wants directory". **A unit with no `[Install]` section
cannot be enabled**, which is what `static` means in `is-enabled` output.

<details class="predict">
<summary>A service has `ExecStart=/usr/bin/nosuchprogram`. What does `systemctl start` print, and where is the actual reason?</summary>

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ sudo systemctl start broken 2>&1 | head -3; sleep 2; systemctl status broken --no-pager 2>&1 | head -11
× broken.service - A service that will not start
     Loaded: loaded (/etc/systemd/system/broken.service; static)
    Drop-In: /usr/lib/systemd/system/service.d
             └─10-timeout-abort.conf
     Active: failed (Result: exit-code) since Fri 2026-08-07 22:25:45 CDT; 2s ago
   Duration: 8ms
 Invocation: a7077baebc6647a2a6b3fd2c6a03d57c
    Process: 55907 ExecStart=/usr/bin/nosuchprogram (code=exited, status=203/EXEC)
   Main PID: 55907 (code=exited, status=203/EXEC)
   Mem peak: 1.2M
        CPU: 3ms
```

**`status=203/EXEC` is the answer and it is precise.** systemd defines a range of
exit codes for the things that can go wrong before the program starts, and 203
means it could not execute the binary — missing, not executable, or a bad
interpreter line.

Read the rest, because every line is doing work:

**`Loaded: ... ; static`** — the unit was parsed successfully, and `static` means
it has no `[Install]` section so it cannot be enabled. Configuration is fine;
this is not a syntax problem.

**`Active: failed (Result: exit-code)`** — it ran and exited badly, as opposed to
`Result: timeout` or `Result: signal`, which point elsewhere.

**`Process: ... ExecStart=...`** — the exact command line systemd used, which is
what to compare against what you thought you wrote.

The codes worth recognising:

| Code | Means |
| --- | --- |
| `203/EXEC` | Could not execute. Missing binary, not executable, bad shebang. |
| `200/CHDIR` | `WorkingDirectory=` does not exist |
| `217/USER` | The `User=` account does not exist |
| `226/NAMESPACE` | A sandboxing directive could not be applied |
| `1` | The program ran and exited with an error of its own |

**`1` is the important distinction.** Anything in the 200s failed *before* your
program started, so the fault is in the unit file. `1` means the program ran and
had its own opinion, so the fault is in the program or its configuration — and
`journalctl -u` will have what it said.

</details>

<details class="deeper">
<summary>If you already administer Linux: why Type= decides whether After= means anything</summary>

`After=` orders one unit behind another, and the obvious reading is "start mine
once theirs is ready". What it actually means is "start mine once systemd
considers theirs to have finished starting" — and `Type=` is what decides when
that is. Get it wrong and the ordering you carefully wrote does nothing.

| `Type=` | Considered started when | Ready in any real sense |
| --- | --- | --- |
| `simple` | The `fork` succeeded | **No.** The program has not run a line yet. |
| `exec` | The `execve` succeeded | Barely. The binary loaded. |
| `forking` | The parent exits and the PID file appears | Usually |
| `oneshot` | The command exits | Yes |
| `notify` | The service says so with `sd_notify` | **Yes** |
| `dbus` | It takes its bus name | Yes |

**`simple` is the default and it is the one that lies.** systemd marks the unit
active the instant the fork returns, before the program has parsed its config,
bound a port, or opened a database connection. So a unit with
`After=postgresql.service` on a `Type=simple` database starts immediately after
`fork`, and your application connects to a server that is not listening yet. The
ordering is honoured exactly as specified and buys nothing.

**`Type=notify` is the real fix**, and it needs cooperation from the program: it
calls `sd_notify(0, "READY=1")` when it is genuinely serving. Most well-behaved
modern daemons support it — nginx, PostgreSQL, and systemd's own units do — and
`systemctl show unit -p Type` tells you what a shipped unit uses.

**When the program cannot be changed**, the honest options are a health check in
`ExecStartPost=` that polls until the port answers, or accepting that the
application must retry. Prefer the retry. Boot ordering is a one-time guarantee and
the dependency will be unavailable again later for reasons ordering cannot help
with, which is the same argument as `Requires=` versus `Wants=`.

**One measurable consequence:** `systemd-analyze blame` attributes almost no time
to `Type=simple` units, because they are "started" instantly, so a slow service can
be invisible in the very tool you would use to find it. `systemd-analyze
critical-chain` shows the ordering dependencies instead, which is the more honest
view when hunting a slow boot.

</details>

## Reading a healthy status

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ systemctl status sshd --no-pager | head -12
● sshd.service - OpenSSH server daemon
     Loaded: loaded (/usr/lib/systemd/system/sshd.service; enabled; preset: enabled)
    Drop-In: /usr/lib/systemd/system/service.d
             └─10-timeout-abort.conf
     Active: active (running) since Fri 2026-08-07 14:14:48 CDT; 8h ago
 Invocation: 78a57f808df4438c9aa5536838139efb
       Docs: man:sshd(8)
             man:sshd_config(5)
   Main PID: 1524 (sshd)
      Tasks: 1 (limit: 2327)
     Memory: 12.5M (peak: 18.2M)
        CPU: 14.979s
```

**`Loaded:` carries three facts.** The unit file path — so you know which of the
three directories won. Whether it is **enabled**, which is the reboot question
answered without a second command. And the vendor **preset**, which is what the
distribution intended.

**`Drop-In:` lists overrides in effect**, which is where a setting you cannot find
in the main unit file is coming from.

**`Active:` gives state and uptime.** `since ... 8h ago` on a service you expected
to have restarted this morning is information.

**`Tasks`, `Memory`, and `CPU` are cgroup accounting**, free with every unit. A
service whose memory has climbed all week is visible here without any monitoring
at all.

## Finding things

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ systemctl list-units --type=service --state=running --no-pager | head -10; echo "--- anything failed? ---"; systemctl --failed --no-pager
  UNIT                        LOAD   ACTIVE SUB     DESCRIPTION
  auditd.service              loaded active running Security Audit Logging Service
  chronyd.service             loaded active running NTP client/server
  dbus-broker.service         loaded active running D-Bus System Message Bus
  demo.service                loaded active running A demonstration service
  fwupd.service               loaded active running Firmware update daemon
  getty@tty1.service          loaded active running Getty on tty1
  gssproxy.service            loaded active running GSSAPI Proxy Daemon
  irqbalance.service          loaded active running irqbalance daemon
  NetworkManager.service      loaded active running Network Manager
--- anything failed? ---
  UNIT           LOAD   ACTIVE SUB    DESCRIPTION
● broken.service loaded failed failed A service that will not start

Legend: LOAD   → Reflects whether the unit definition was properly loaded.
        ACTIVE → The high-level unit activation state, i.e. generalization of SUB.
        SUB    → The low-level unit activation state, values depend on unit type.

1 loaded units listed.
```

**`systemctl --failed` is the first command to run on any machine behaving
oddly.** It is short, it is usually empty, and when it is not, it has named the
problem before you have asked a question.

| Command | Does |
| --- | --- |
| `systemctl --failed` | Everything broken. Start here. |
| `systemctl list-units --type=service` | Everything loaded |
| `systemctl list-unit-files --state=enabled` | What will start at boot |
| `systemctl cat nginx` | The effective unit, drop-ins included |
| `systemctl show nginx -p MemoryMax` | One resolved property |
| `systemctl list-dependencies nginx` | What it pulls in |

## Overriding without editing

```
sudo systemctl edit nginx
```

This opens an empty drop-in, saves it to
`/etc/systemd/system/nginx.service.d/override.conf`, and runs `daemon-reload` for
you. Put in only what you are changing:

```ini
[Service]
Restart=always
MemoryMax=2G
```

**The shipped unit is untouched**, so a package update keeps your override.
`systemctl edit --full` copies the whole unit into `/etc/` instead, which is
occasionally what you want and loses future upstream changes.

**One trap:** list-valued keys like `ExecStart=` **append** rather than replace, so
a drop-in adding `ExecStart=` gives the service two commands and it fails. Clear
it first:

```ini
[Service]
ExecStart=
ExecStart=/usr/local/bin/mywrapper
```

<details class="deeper">
<summary>If you already administer Linux: Wants versus Requires, and why After= is the one you usually want</summary>

Four directives, two dimensions, and conflating them causes real problems.

**Dependency** — should this pull that in?

`Wants=b` starts `b` alongside `a`, and `a` starts anyway if `b` fails.
`Requires=b` starts `b` too, and **`a` fails if `b` fails**. `BindsTo=b` is
stronger still: if `b` stops later, `a` stops too.

**Ordering** — which goes first?

`After=b` means `a` starts after `b` **if both are being started**. It says
nothing about whether `b` starts at all.

**They are independent, and that is the part people miss.** `Requires=b` without
`After=b` starts both simultaneously, so your service may start before its
database is accepting connections and fail. `After=b` without `Requires=b` means
that if `b` is not being started, yours starts immediately anyway.

**Prefer `Wants=` plus `After=`** for most cases. `Requires=` couples failure
domains — a transient failure in a dependency takes your service down and it stays
down — and that is rarely what you want when `Restart=on-failure` would have
recovered.

**`network-online.target` is not what most people think.** `network.target`
means "networking has been configured", not "the network works". Waiting for a
usable network needs `Wants=network-online.target` **and** `After=network-online.target`,
and it only works if `NetworkManager-wait-online` or the equivalent is enabled.
Even then it is a poor substitute for an application that retries — a service
depending on a remote database should handle the database being unavailable,
because it will be again later regardless of boot ordering.

**`systemd-analyze verify nginx.service`** checks a unit for errors and missing
dependencies without starting it, and `systemctl list-dependencies --reverse
nginx` shows what would break if you stopped it.

</details>

<details class="deeper">
<summary>If you already administer Linux: sandboxing and resource limits, free with every unit</summary>

A unit file is also a security and resource policy, and most of these are one line.

**Filesystem restriction:**

```ini
ProtectSystem=strict          # /usr and /etc read-only
ProtectHome=true              # /home, /root, /run/user invisible
PrivateTmp=true               # its own /tmp, invisible to anything else
ReadWritePaths=/var/lib/myapp # the exceptions
```

`PrivateTmp=true` alone removes an entire class of symlink attack from lesson 25,
and costs nothing.

**Privilege restriction:**

```ini
User=myapp
NoNewPrivileges=true          # cannot gain privilege via setuid
CapabilityBoundingSet=CAP_NET_BIND_SERVICE
ProtectKernelTunables=true
RestrictAddressFamilies=AF_INET AF_INET6
```

`CAP_NET_BIND_SERVICE` is the one worth knowing: it lets a non-root process bind
a port below 1024, which removes the historical reason web servers started as
root.

**Resource control**, and this is where a runaway service stops taking the machine
with it:

```ini
MemoryMax=2G                  # killed if it exceeds this
CPUQuota=50%                  # a real ceiling, unlike nice
TasksMax=100                  # fork bomb protection
```

`MemoryMax` converts an unpredictable OOM event that kills the largest process on
the machine — usually the database — into a predictable one that kills the
offender. That is a substantial operational improvement from one line.

**`systemd-analyze security nginx.service`** scores a unit's exposure out of ten
and lists every directive it is not using. It is opinionated and occasionally
impractical, and it is an excellent starting point for hardening something you
wrote.

**Check what is actually in force** with `systemctl show nginx -p MemoryMax
-p User -p ProtectSystem`, because the effective value is the result of the unit
plus every drop-in.

</details>

## Across distributions

systemd is the same software everywhere, so this is one of the more portable
areas. What differs:

| | RHEL family | Debian family |
| --- | --- | --- |
| Apache unit | `httpd.service` | `apache2.service` |
| Cron unit | `crond.service` | `cron.service` |
| Enabled on install | **No**, by preset | **Yes**, usually |
| Environment files | `/etc/sysconfig/` | `/etc/default/` |

**That third row is a real behavioural difference.** Debian's packaging
conventionally starts and enables a service when you install it; the RHEL family
generally does not, because presets say otherwise. So `dnf install nginx` gives
you an installed, stopped, disabled service, and `apt install nginx` gives you a
running one. Neither is wrong and assuming the wrong one wastes time.

## Prove it

```bash
# Both questions, not one
systemctl is-active nginx
systemctl is-enabled nginx

# What is the effective configuration, drop-ins included
systemctl cat nginx

# What actually happened
systemctl status nginx --no-pager
journalctl -u nginx --since '10 minutes ago'

# And the check that matters
sudo reboot
```

**`is-active` and `is-enabled` together, every time.** They answer two different
questions and only asking one is how services quietly fail to come back.

## What trips people up

### 1. Started but not enabled

`start` runs it now, `enable` writes the boot symlink. They are separate.

`systemctl enable --now` does both. `is-enabled` confirms.

### 2. You edited the unit and nothing happened

systemd caches unit files. Editing on disk changes nothing until
`systemctl daemon-reload`.

`systemctl edit` runs it for you, which is one more reason to prefer it. And if
you edited under `/usr/lib/systemd/system/`, the next package update will discard
it regardless.

### 3. `restart` when `reload` would do

`restart` stops and starts, dropping every connection. `reload` signals the
process to re-read its configuration and keeps serving.

`reload` only works if the unit defines `ExecReload=`. `reload-or-restart` does
the right thing either way.

### 4. `Requires=` where `Wants=` was meant

`Requires=` makes your service fail when its dependency fails, and stay failed. A
transient database restart takes your application down permanently.

`Wants=` plus `After=`, plus `Restart=on-failure`.

### 5. Expecting `After=network-online.target` to guarantee a network

It waits for a target that only means what its wait-online service says it means,
and it is frequently not enabled.

An application that needs a remote service should retry. Boot ordering is not a
substitute for handling a dependency being unavailable, because it will be
unavailable again later.

## Work it through

A monitoring agent stops reporting after a routine reboot. It was installed and
tested three weeks ago and worked perfectly since.

Reason it out before reading on.

**Ask both questions first:**

```
systemctl is-active monitoring-agent
systemctl is-enabled monitoring-agent
```

**`inactive` and `disabled`** is the whole answer: it was started and never
enabled, ran for three weeks because nothing restarted the machine, and did not
come back. `systemctl enable --now` fixes it permanently.

**`inactive` and `enabled`** is a different problem — it was supposed to start and
did not — and `journalctl -u monitoring-agent -b` gives the reason. Common causes
at boot that never appear when starting by hand: a dependency not ready, a network
mount not yet available, or a `WorkingDirectory=` on a filesystem mounted later.

**`failed`** means it tried. `systemctl status` gives the exit code, and the 200s
versus 1 distinction from the prediction tells you whether to look at the unit
file or at the application.

**The subtle one worth knowing:** `enabled` in `is-enabled` and a missing symlink
can disagree if somebody deleted the symlink by hand.
`systemctl list-unit-files monitoring-agent.service` and
`ls /etc/systemd/system/multi-user.target.wants/` settle it.

**And one more possibility** if the agent was installed by a vendor script rather
than a package: the unit may be in `/etc/systemd/system/` with no `[Install]`
section at all, in which case `is-enabled` reports `static` and it can never be
enabled. The fix is adding the section and running `daemon-reload`.

Now the point worth extracting. **"Is it running" and "will it run" are separate
questions with separate answers**, and the one that matters after a reboot is the
one nobody checks. A service can be active and disabled for years without anyone
noticing, because the evidence only appears at the moment the machine restarts —
which is usually the moment you least want to be diagnosing it.

The habit: **`enable --now`, never bare `start`**, unless you specifically mean
"just for now". And on any machine you inherit,
`systemctl list-unit-files --state=enabled` against
`systemctl list-units --type=service --state=running` — the difference between
those two lists is the set of surprises waiting for the next reboot.

## Try it

Optional, on a machine you can restart.

1. `systemctl --failed`. Hopefully empty.
2. `systemctl status sshd` and name every line of the header.
3. `systemctl is-active sshd; systemctl is-enabled sshd`.
4. `systemctl cat sshd` and note which directory the unit came from.
5. Write the `demo.service` from this lesson, `daemon-reload`, `start` it, and
   check `is-enabled`. Then `enable` it and look at what symlink appeared.
6. `systemctl edit demo`, add `Restart=always`, and confirm with
   `systemctl show demo -p Restart`.
7. `systemctl list-unit-files --state=enabled | wc -l` against
   `systemctl list-units --type=service --state=running | wc -l`.

**Verification step.** You have it when you can look at a service and say, in two
commands, both whether it is running and whether it will still be running after a
reboot.

## Check yourself

<details class="qa">
<summary>What is the difference between `systemctl start` and `systemctl enable`, and what does enable actually write?</summary>

**`start` runs the service now** and changes nothing on disk. **`enable` creates a
symlink** and does not start anything.

The symlink goes into the wants directory of the target named in the unit's
`[Install]` section — typically
`/etc/systemd/system/multi-user.target.wants/name.service` pointing at the unit
file. At boot, systemd starts everything symlinked into the target it is reaching.

So a service can be `active` and `disabled` at the same time: running now, gone
after a reboot. That combination is the most common systemd mistake and it is
invisible until the machine restarts.

**`systemctl enable --now`** does both, and using it by default removes the whole
category.

A unit with no `[Install]` section cannot be enabled at all — that is what
`static` means in `is-enabled` output.

</details>

<details class="qa">
<summary>A service fails with `status=203/EXEC`. What does that tell you, and how does it differ from `status=1`?</summary>

**203/EXEC means systemd could not execute the binary at all** — the path in
`ExecStart=` does not exist, is not executable, or has a bad interpreter line. The
program never ran.

**`status=1` means the program ran** and exited with an error of its own.

That distinction decides where to look. Anything in the 200s is a **unit file**
problem — systemd could not set up the execution environment. `200/CHDIR` is a
missing `WorkingDirectory=`, `217/USER` is a `User=` account that does not exist,
`226/NAMESPACE` is a sandboxing directive that could not be applied.

`1` is an **application** problem, and `journalctl -u thename` will have whatever
the program printed before exiting.

Reading the code first saves reading the wrong logs.

</details>

<details class="qa">
<summary>Why should you never edit a file in `/usr/lib/systemd/system/`, and what do you do instead?</summary>

**Because package updates overwrite it.** That directory belongs to the packaging
system, and your change disappears at the next update — typically weeks later,
with no obvious connection to the update.

**Use `systemctl edit thename`.** It creates a drop-in at
`/etc/systemd/system/thename.service.d/override.conf` containing only your
changes, and runs `daemon-reload` for you. `/etc/` outranks `/usr/lib/`, so the
override wins, and the shipped unit stays pristine and continues to receive
upstream improvements.

`systemctl cat thename` shows the effective result of the unit plus every drop-in.

One trap: list-valued keys such as `ExecStart=` **append** rather than replace, so
an override adding one gives the service two commands. Set the key to empty first
to clear it, then set your value.

</details>

<details class="qa">
<summary>What is the difference between `Wants=`, `Requires=`, and `After=`?</summary>

**`Wants=` and `Requires=` are about dependency; `After=` is about order.** They
are independent, which is the part that catches people.

`Wants=b` pulls `b` in, and your service starts anyway if `b` fails.
`Requires=b` pulls it in and **fails your service if `b` fails**.
`After=b` says that *if both are being started*, yours goes second — and says
nothing about whether `b` starts at all.

So `Requires=` without `After=` starts both at once, and your service may reach a
database that is not yet accepting connections.

**Prefer `Wants=` plus `After=`** in most cases. `Requires=` couples failure
domains: a transient failure in a dependency takes your service down and leaves it
down, where `Restart=on-failure` would have recovered.

</details>

<details class="qa">
<summary>Why does editing a unit file on disk have no effect until you run `daemon-reload`?</summary>

**systemd caches unit files in memory.** It parses them when it starts and when
told to re-read, not on every operation, so a file changed on disk is not the file
systemd is using.

`systemctl daemon-reload` re-reads everything. Without it, `systemctl restart`
faithfully restarts the service using the **old** definition, which produces the
memorable experience of a change that visibly does nothing.

`systemctl edit` runs the reload for you, which is one more reason to prefer it
over editing files directly.

The same requirement applies after editing `/etc/fstab`, because those lines are
turned into mount units by a generator that only runs at boot and on reload.

</details>

## References

- [systemd(1)](https://man7.org/linux/man-pages/man1/systemd.1.html) - Linux man-pages project. Accessed 2026-08-07.
- [systemctl(1)](https://man7.org/linux/man-pages/man1/systemctl.1.html) - Linux man-pages project. Accessed 2026-08-07.
- [systemd.unit(5)](https://man7.org/linux/man-pages/man5/systemd.unit.5.html) - Linux man-pages project. Accessed 2026-08-07.
- [systemd.service(5)](https://man7.org/linux/man-pages/man5/systemd.service.5.html) - Linux man-pages project. Accessed 2026-08-07.
- [systemd.exec(5)](https://man7.org/linux/man-pages/man5/systemd.exec.5.html) - Linux man-pages project. Accessed 2026-08-07.
- [systemd.resource-control(5)](https://man7.org/linux/man-pages/man5/systemd.resource-control.5.html) - Linux man-pages project. Accessed 2026-08-07.

Command output was captured on the podman machine, which runs real systemd. The
demonstration units were removed afterwards. Blocks without a distribution and
architecture header are illustrative.
