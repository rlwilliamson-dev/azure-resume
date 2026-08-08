---
title: "The permissions are right and it still cannot read the file"
description: "SELinux is a second permission check that runs after the first one passes, and it does not care what the mode bits say. Contexts, labels, booleans, and how to read a denial instead of turning the whole thing off."
track: "linux-plus"
level: "deep"
order: 450
objectives:
  - "Explain what mandatory access control adds on top of file permissions"
  - "Read a context off a process and off a file, and say which part matters"
  - "Diagnose a denial from the audit log rather than by guessing"
  - "Fix a mislabelled file with restorecon instead of chcon, and say why"
  - "Find and set a boolean rather than writing policy"
prerequisites: ["reading-and-setting-permissions", "logging-and-auditing"]
tags: ["linux", "linux-plus", "selinux", "security", "mac"]
updated: 2026-08-08
draft: false
examObjectives:
  - exam: "xk0-006"
    domain: "3.0"
    objective: "3.3"
  - exam: "xk0-006"
    domain: "5.0"
    objective: "5.4"
sources:
  - title: "selinux(8)"
    url: "https://man7.org/linux/man-pages/man8/selinux.8.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-08
    tier: 1
  - title: "selinux_config(5)"
    url: "https://man7.org/linux/man-pages/man5/selinux_config.5.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-08
    tier: 1
  - title: "setsebool(8)"
    url: "https://man7.org/linux/man-pages/man8/setsebool.8.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-08
    tier: 1
  - title: "restorecon(8)"
    url: "https://man7.org/linux/man-pages/man8/restorecon.8.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-08
    tier: 1
  - title: "chcon(1)"
    url: "https://man7.org/linux/man-pages/man1/chcon.1.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-08
    tier: 1
  - title: "semanage-fcontext(8)"
    url: "https://man7.org/linux/man-pages/man8/semanage-fcontext.8.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-08
    tier: 1
  - title: "Using SELinux"
    url: "https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/10/html/using_selinux/index"
    publisher: "Red Hat"
    accessed: 2026-08-08
    tier: 1
  - title: "podman-run(1)"
    url: "https://docs.podman.io/en/latest/markdown/podman-run.1.html"
    publisher: "Podman"
    accessed: 2026-08-08
    tier: 1
symptoms:
  - symptom: "Permission denied on a file that ls -l says is readable"
    anchor: "2-a-denial-from-start-to-finish"
  - symptom: "Works after setenforce 0"
    anchor: "1-setenforce-0-made-it-work-so-that-is-the-fix"
  - symptom: "avc denied in the audit log"
    anchor: "reading-the-denial"
---

> **Before you read.** A file is mode 644, owned by root, and every process on the
> machine can see it in `ls -l`. A service tries to open it and gets
> `Permission denied`.
>
> You check the permissions again. They are fine. You check the owner. Fine. You
> check that the file exists and the path is right. It does and it is.
>
> **What else is there? Nothing in `ls -l` is refusing this.**

Something else is, and it is not in `ls -l`.

Every file access on this machine passes **two** checks, not one. The first is the
permission system from lesson 07 — owner, group, mode bits — and that one passed.
The second is a policy that the kernel consults afterwards, which knows nothing
about users and everything about *what kind of program* is asking and *what kind of
file* it is asking for. That policy said no.

That second check is SELinux, and it is on by default on every RHEL-family machine
you will ever touch.

### Some words you will need

<dl class="terms">
<dt>DAC</dt>
<dd>Discretionary access control. The ordinary permission bits. Called discretionary because the owner of a file decides who may read it.</dd>
<dt>MAC</dt>
<dd>Mandatory access control. A policy set system-wide that the owner of a file cannot override. SELinux is one.</dd>
<dt>context</dt>
<dd>The SELinux label on a thing, written <code>user:role:type:level</code>. Everything has one: files, processes, ports, sockets.</dd>
<dt>type</dt>
<dd>The third field of a context, and the one that does nearly all the work. <code>httpd_t</code>, <code>shadow_t</code>, <code>container_t</code>.</dd>
<dt>subject</dt>
<dd>The process doing something.</dd>
<dt>object</dt>
<dd>The thing being done to. A file, a port, a directory.</dd>
<dt>AVC</dt>
<dd>Access vector cache. The kernel's decision cache, and by extension the name of the log line written when it refuses something.</dd>
<dt>boolean</dt>
<dd>A named on-or-off switch inside the shipped policy, so common adjustments need no policy writing.</dd>
</dl>

## What breaks without this

**You lose a morning to a permissions problem that is not a permissions problem.**
Every tool you reach for says the access should work, because every tool you reach
for is looking at the wrong check.

**You turn SELinux off**, because that makes it work, and now the machine fails its
next audit and has lost a control that was doing real work.

**You `chcon` a file, it works, and it breaks again weeks later** after something
relabelled the filesystem. The fix did not survive because it was written in the
wrong place.

**You cannot read a denial.** The audit log tells you exactly which process, which
file, and which operation, in a format that looks like line noise until somebody
shows you the four fields that matter.

## The mental model

<figure class="learn-figure">
<svg viewBox="0 0 720 330" role="img" aria-labelledby="se-title se-desc" style="width:100%;height:auto;">
  <title id="se-title">How SELinux adds a second check after ordinary Unix permissions</title>
  <desc id="se-desc">A process, called the subject, tries to open a file, called the object. The kernel checks ordinary Unix permissions first: owner, group, and mode bits. If those say no, the access is refused and SELinux is never consulted. If they say yes, the kernel then asks the SELinux policy whether a process in the subject's type is allowed that operation on an object of the object's type. If the policy has no rule permitting it, the access is refused and an AVC denial is written to the audit log. Both checks must pass. This is why a file that looks perfectly readable can still be unreadable.</desc>
  <g font-family="ui-monospace, monospace">
    <rect x="18" y="30" width="180" height="66" rx="5" fill="currentColor" fill-opacity="0.12" stroke="currentColor" stroke-opacity="0.4"/>
    <text x="108" y="52" text-anchor="middle" font-size="12" fill="currentColor">subject</text>
    <text x="108" y="69" text-anchor="middle" font-size="9.5" fill="currentColor" fill-opacity="0.65">a process wanting to read</text>
    <text x="108" y="86" text-anchor="middle" font-size="9.5" fill="currentColor" fill-opacity="0.8">container_t</text>
    <rect x="18" y="228" width="180" height="66" rx="5" fill="currentColor" fill-opacity="0.12" stroke="currentColor" stroke-opacity="0.4"/>
    <text x="108" y="250" text-anchor="middle" font-size="12" fill="currentColor">object</text>
    <text x="108" y="267" text-anchor="middle" font-size="9.5" fill="currentColor" fill-opacity="0.65">the file being read</text>
    <text x="108" y="284" text-anchor="middle" font-size="9.5" fill="currentColor" fill-opacity="0.8">user_tmp_t</text>
    <rect x="266" y="112" width="150" height="100" rx="5" fill="currentColor" fill-opacity="0.07" stroke="currentColor" stroke-opacity="0.3"/>
    <text x="341" y="140" text-anchor="middle" font-size="12" fill="currentColor">check one</text>
    <text x="341" y="160" text-anchor="middle" font-size="9.5" fill="currentColor" fill-opacity="0.65">owner, group, mode</text>
    <text x="341" y="176" text-anchor="middle" font-size="9.5" fill="currentColor" fill-opacity="0.65">the bits in ls -l</text>
    <text x="341" y="196" text-anchor="middle" font-size="9.5" fill="currentColor" fill-opacity="0.8">discretionary</text>
    <rect x="474" y="112" width="150" height="100" rx="5" fill="currentColor" fill-opacity="0.07" stroke="currentColor" stroke-opacity="0.3"/>
    <text x="549" y="140" text-anchor="middle" font-size="12" fill="currentColor">check two</text>
    <text x="549" y="160" text-anchor="middle" font-size="9.5" fill="currentColor" fill-opacity="0.65">does policy allow</text>
    <text x="549" y="176" text-anchor="middle" font-size="9.5" fill="currentColor" fill-opacity="0.65">container_t to read</text>
    <text x="549" y="196" text-anchor="middle" font-size="9.5" fill="currentColor" fill-opacity="0.8">user_tmp_t?</text>
    <text x="656" y="152" font-size="11" fill="currentColor">yes</text>
    <text x="656" y="170" font-size="9.5" fill="currentColor" fill-opacity="0.65">read it</text>
    <text x="474" y="252" font-size="11" fill="currentColor">no</text>
    <text x="474" y="270" font-size="9.5" fill="currentColor" fill-opacity="0.65">Permission denied,</text>
    <text x="474" y="284" font-size="9.5" fill="currentColor" fill-opacity="0.65">and an AVC in the audit log</text>
    <text x="266" y="252" font-size="11" fill="currentColor">no</text>
    <text x="266" y="270" font-size="9.5" fill="currentColor" fill-opacity="0.65">Permission denied,</text>
    <text x="266" y="284" font-size="9.5" fill="currentColor" fill-opacity="0.65">and no AVC at all</text>
  </g>
  <g stroke="currentColor" stroke-opacity="0.45" fill="none" stroke-width="1.2">
    <path d="M198 68 L232 68 L232 150 L262 150 M256 146 L263 150 L256 154"/>
    <path d="M198 258 L232 258 L232 176 L262 176 M256 172 L263 176 L256 180"/>
    <path d="M416 162 L470 162 M464 158 L471 162 L464 166"/>
    <path d="M624 162 L650 162 M644 158 L651 162 L644 166"/>
    <path d="M341 212 L341 238 M337 232 L341 239 L345 232"/>
    <path d="M549 212 L549 238 M545 232 L549 239 L553 232"/>
  </g>
</svg>
<figcaption>Both checks must pass. Only the second one writes an AVC, which is why a denial with nothing in the audit log is a permissions problem.</figcaption>
</figure>

**The order matters and it is a diagnostic.** DAC runs first. If the mode bits refuse
the access, SELinux is never asked and **nothing appears in the audit log**. So a
`Permission denied` with no AVC behind it is an ordinary permissions problem, and a
`Permission denied` *with* an AVC is this lesson. That single observation tells you
which of the two you are in before you have formed a theory.

## Is it even on, and in which mode

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ sestatus
SELinux status:                 enabled
SELinuxfs mount:                /sys/fs/selinux
SELinux root directory:         /etc/selinux
Loaded policy name:             targeted
Current mode:                   enforcing
Mode from config file:          enforcing
Policy MLS status:              enabled
Policy deny_unknown status:     allowed
Memory protection checking:     actual (secure)
Max kernel policy version:      35
```

**Read the two mode lines separately.** `Current mode` is what the kernel is doing
right now. `Mode from config file` is what it will do after a reboot. When those
disagree, somebody ran `setenforce` and did not write it down, and the machine is
about to change behaviour the next time it restarts.

There are three modes, and only two of them are a mode:

| Mode | Denies | Logs | Set by |
| --- | --- | --- | --- |
| `enforcing` | Yes | Yes | `setenforce 1`, or `SELINUX=enforcing` |
| `permissive` | **No** | Yes | `setenforce 0`, or `SELINUX=permissive` |
| `disabled` | No | **No** | `SELINUX=disabled` in the config file, reboot required |

**Permissive is a diagnostic tool, not a setting.** It allows everything and logs
every denial it would have made, so you can collect the full list of things a
service needs in one run rather than fixing one denial, hitting the next, and
repeating six times. Then you go back to enforcing.

**`disabled` is different in kind.** Permissive still labels files as they are
created; disabled does not, so a machine that runs disabled for a month has a
filesystem full of wrong labels and needs a full relabel — which reads and rewrites
the label on every file on every filesystem — before it can be turned back on.
That is why the run-time switch has only two positions and turning it off entirely
takes a reboot.

`getenforce` prints just the current mode, which is the one to reach for in a script.

<details class="deeper">
<summary>If you already administer Linux: targeted policy, and why `unconfined_t` is doing more work than it looks</summary>

`Loaded policy name: targeted` is the important line in `sestatus` and it explains
why SELinux feels invisible until suddenly it does not.

**Targeted policy confines a list of things and leaves everything else alone.**
Network-facing daemons, container runtimes, and anything historically worth
attacking run in their own domains — `httpd_t`, `sshd_t`, `container_t` — with
policy written for exactly what they need. Everything else, including your login
shell, runs in `unconfined_t`, which is permitted almost everything.

Look at what your own shell is:

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ id -Z; echo "---"; ls -Z /etc/passwd /etc/shadow
unconfined_u:unconfined_r:unconfined_t:s0-s0:c0.c1023
---
system_u:object_r:passwd_file_t:s0 /etc/passwd
     system_u:object_r:shadow_t:s0 /etc/shadow
```

`unconfined_t`. That is why every command you type by hand works, and why the first
time SELinux stops you is nearly always a *service* rather than you. It is also why
"it works when I run it by hand and fails from systemd" is such a common report:
running it by hand runs it unconfined, and systemd runs it in its own domain.

The alternative shipped policy is `mls`, multi-level security, which implements the
military classification model properly using that fourth `s0` field. Almost nobody
runs it, and the exam will not ask you to configure it. Knowing that the field
exists and that targeted mostly ignores it is enough.

**`Policy deny_unknown status: allowed`** is worth understanding too: it decides what
happens when the kernel knows about an object class the policy has never heard of,
which happens after a kernel upgrade and before a policy upgrade. `allowed` fails
open; `denied` fails closed and can make a machine unbootable after an upgrade.

</details>

## Contexts, and the one field that matters

Everything has a context, written as four colon-separated fields:

```
system_u:object_r:shadow_t:s0
   |         |        |     |
   user     role     type  level
```

**Ninety-five percent of what you will ever do is the third field.** The SELinux
user and role fields matter for confined *user* accounts, which most sites do not
use. The level field is MLS, which most sites do not use either. The type is the
whole game.

Processes have one too:

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ ps -eZ | head -6
LABEL                               PID TTY          TIME CMD
system_u:system_r:init_t:s0           1 ?        00:00:00 systemd
system_u:system_r:kernel_t:s0         2 ?        00:00:00 kthreadd
system_u:system_r:kernel_t:s0         3 ?        00:00:00 pool_workqueue_release
system_u:system_r:kernel_t:s0         4 ?        00:00:00 kworker/R-rcu_gp
system_u:system_r:kernel_t:s0         5 ?        00:00:00 kworker/R-sync_wq
```

**A type on a process is called a domain**, and that is the only difference between
the two words. Policy is then a very large list of statements of the form "a process
in domain X may perform operation Y on an object of type Z". If no statement covers
what is being attempted, it is refused. There is no default-allow.

The flag is `-Z` and it is the same letter everywhere: `ls -Z`, `ps -Z`, `id -Z`,
`cp -Z`, `mkdir -Z`, `ss -Z`.

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ ls -Zd /etc/shadow /var/log/messages /usr/bin/passwd /var/home/core
ls: cannot access '/var/log/messages': No such file or directory
           system_u:object_r:shadow_t:s0 /etc/shadow
      system_u:object_r:passwd_exec_t:s0 /usr/bin/passwd
unconfined_u:object_r:user_home_dir_t:s0 /var/home/core
```

**Look at `/usr/bin/passwd`.** Its type is `passwd_exec_t`, and that is not
decoration: policy says that when a process executes a file of type `passwd_exec_t`,
it *transitions* into the `passwd_t` domain, which is the only domain permitted to
write `shadow_t`. The setuid bit from lesson 07 makes it run as root; the label
decides what that root process is subsequently allowed to touch. Two independent
mechanisms, and SELinux is the one that stops a compromised `passwd` from being a
general-purpose root shell.

## A denial from start to finish

Here is the whole thing on one machine, with nothing simulated. A file in `/var/tmp`:

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ mkdir -p /var/tmp/sedemo && echo "the report" > /var/tmp/sedemo/report.txt; ls -Zd /var/tmp/sedemo; ls -Z /var/tmp/sedemo/report.txt
unconfined_u:object_r:user_tmp_t:s0 /var/tmp/sedemo
unconfined_u:object_r:user_tmp_t:s0 /var/tmp/sedemo/report.txt
```

Type `user_tmp_t`, which is what anything created in `/var/tmp` gets. The file is
readable by everyone as far as the mode bits are concerned. Now hand that directory
to a container and ask it to read the file.

<details class="predict">
<summary>The container runs as root inside itself, the file is world-readable, and the path is correct. Given that policy is a list of allow statements and there is no default-allow, what happens?</summary>

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ podman run --rm -v /var/tmp/sedemo:/data:ro docker.io/library/almalinux:10 cat /data/report.txt
cat: /data/report.txt: Permission denied
```

</details>

**Permission denied**, on a world-readable file, from a process running as root.
Every instinct says to check the mode bits, and every minute spent there is wasted,
because the mode bits are fine.

### Reading the denial

The evidence is in the audit log, and it names everything:

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ sudo ausearch --input-logs -m AVC -ts today 2>&1 | grep -B1 container_t
time->Sat Aug  8 11:44:07 2026
type=AVC msg=audit(1786207447.300:780): avc:  denied  { open } for  pid=2668 comm="cat" path="/data/report.txt" dev="vda4" ino=863403 scontext=system_u:system_r:container_t:s0:c28,c528 tcontext=unconfined_u:object_r:user_tmp_t:s0 tclass=file permissive=0
```

That line looks like noise and is not. **Five fields carry the answer:**

| Field | Here | Means |
| --- | --- | --- |
| `denied { open }` | `open` | The operation refused. Not "read", specifically `open`. |
| `scontext` | `container_t` | The **s**ubject: what kind of process was asking |
| `tcontext` | `user_tmp_t` | The **t**arget: what kind of object it wanted |
| `tclass` | `file` | What sort of object. `file`, `dir`, `tcp_socket`, `unix_stream_socket`. |
| `permissive` | `0` | Enforcing, so the access really was refused |

Read as a sentence: *a process of type `container_t` tried to `open` a `file` of type
`user_tmp_t`, and no policy rule permits that.* Everything you need to fix it is in
those five fields, and none of it is about users or permissions.

**`comm="cat"` and `path=` are a bonus**, not the diagnosis. They tell you which
command and which file, which is how you find the thing to relabel — but two
services can hit the identical `scontext`/`tcontext` pair from completely different
files, and it is the pair that decides the fix.

**`--input-logs` deserves a word**, because on a system where `auditd` writes to
both the journal and its own file, `ausearch` reads the journal by default and can
report `<no matches>` while `/var/log/audit/audit.log` is full of denials. If
`ausearch` comes back empty on a machine you are certain is denying something, add
`--input-logs` before you conclude there is nothing there.

<details class="deeper">
<summary>If you already administer Linux: the categories after `s0`, and why two containers cannot read each other's volumes</summary>

Look again at the subject in that denial: `container_t:s0:c28,c528`. The type is
`container_t` for every container on the machine, so type alone cannot keep one
container out of another's data. The `c28,c528` does.

Those are **MCS categories**, and this is the one place the multi-category part of
the policy earns its keep on an ordinary server. Podman assigns each container a
random category pair at start-up and labels that container's volumes to match. A
process may access an object only if the object's category set is a subset of its
own — so container A with `c28,c528` cannot touch a volume labelled `c22,c400`,
even though both are `container_t` and both run as root.

You can watch it happen. This is the same directory after a relabel:

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ podman run --rm -v /var/tmp/sedemo:/data:ro,Z docker.io/library/almalinux:10 cat /data/report.txt; ls -Z /var/tmp/sedemo/report.txt
the report
system_u:object_r:container_file_t:s0:c22,c400 /var/tmp/sedemo/report.txt
```

The type became `container_file_t` **and** it acquired a category pair. That is what
the `Z` did.

**This is why `:z` and `:Z` differ and why the difference bites.** Lowercase `z`
relabels with the shared `container_file_t` type and **no** categories, so every
container can read it — correct for a config directory two services share.
Uppercase `Z` adds the private category pair, so exactly one container can. Mount
the same volume into a second container with `:Z` and it gets relabelled again with
*that* container's categories, and the first container starts failing. A shared
volume marked `:Z` is a bug that only appears when you scale to two replicas.

The other trap: `:Z` on a host path relabels the real directory, recursively.
`-v /home:/data:Z` will happily relabel your entire home directory tree to
`container_file_t` and break everything that expected `user_home_t`. There is no
undo except `restorecon -R`.

</details>

## Fixing it, in order of preference

There are three ways to resolve a denial, and they are not equally good. Try them in
this order.

### 1. The label is wrong. Fix the label.

This is the common case by a wide margin: a file is in the right place with the
wrong type, usually because it was moved rather than copied, or restored from a
backup, or written by a process that had no business writing there.

`chcon` sets a context directly. Watch what it does, and then what happens to it:

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ sudo touch /etc/demo.conf; ls -Z /etc/demo.conf; echo "--- mislabel it ---"; sudo chcon -t shadow_t /etc/demo.conf; ls -Z /etc/demo.conf
unconfined_u:object_r:etc_t:s0 /etc/demo.conf
--- mislabel it ---
unconfined_u:object_r:shadow_t:s0 /etc/demo.conf
```

The label changed. Now ask the system what the label is *supposed* to be, and put it
back:

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ matchpathcon /etc/demo.conf; echo "--- put it back ---"; sudo restorecon -v /etc/demo.conf; ls -Z /etc/demo.conf; sudo rm -f /etc/demo.conf
/etc/demo.conf	system_u:object_r:etc_t:s0
--- put it back ---
Relabeled /etc/demo.conf from unconfined_u:object_r:shadow_t:s0 to unconfined_u:object_r:etc_t:s0
unconfined_u:object_r:etc_t:s0 /etc/demo.conf
```

**Read `matchpathcon` first, always.** It answers "what does policy say this path
should be labelled" without changing anything, and comparing its answer to `ls -Z`
is the fastest way to confirm you have a labelling problem rather than a policy
problem. If they already agree, relabelling will not help and you are in case 2 or 3.

**`restorecon` is the right tool and `chcon` is not**, and the reason is durability:

| | `chcon` | `restorecon` |
| --- | --- | --- |
| Sets | Whatever you type | Whatever policy says it should be |
| Source of truth | Your memory | The file-context database |
| Survives a relabel | **No** | Yes, it *is* the relabel |
| Right for | Testing a theory | Actually fixing it |

A `chcon` is a fact you asserted. A relabel — triggered by `touch /.autorelabel`, by
a policy update, or by somebody running `restorecon -R /` — consults the database,
finds no support for your assertion, and reverts it. The change disappears weeks
later with no obvious cause, which is the worst possible failure mode.

**If the path itself is non-standard**, the database is what needs changing, not the
file. Serving a site out of `/srv/web` rather than `/var/www` means telling policy
that `/srv/web` holds web content, and *then* relabelling:

```
sudo semanage fcontext -a -t httpd_sys_content_t "/srv/web(/.*)?"
sudo restorecon -Rv /srv/web
```

Two commands, and the order is not optional: the first writes the rule, the second
applies it. Doing only the first changes nothing on disk; doing only the second
re-applies the old wrong answer. `semanage` lives in `policycoreutils-python-utils`,
which is not always installed by default and is the first package to add on a machine
where you expect to do this work.

### 2. The label is right and the policy has a switch for this

Before writing any policy, look for a boolean. There are a lot of them:

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ sudo getsebool -a | head -8; echo "--- how many ---"; sudo getsebool -a | wc -l
abrt_anon_write --> off
abrt_handle_event --> on
abrt_upload_watch_anon_write --> on
antivirus_can_scan_system --> off
antivirus_use_jit --> off
auditadm_exec_content --> on
authlogin_nsswitch_use_ldap --> off
authlogin_radius --> off
--- how many ---
367
```

**367 switches**, and their names are searchable in exactly the way you want:
`getsebool -a | grep httpd` narrows to the web server, `grep ldap` to directory
integration. `httpd_can_network_connect` — the one that lets a web application reach
a database on another host — is the single most-hit boolean in existence, and it is
off by default because a web server that can open arbitrary outbound connections is
a much better foothold than one that cannot.

Setting one has a trap in it:

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ getsebool container_use_devices ssh_sysadm_login; echo "--- flip one, runtime only ---"; sudo setsebool container_use_devices on; getsebool container_use_devices; sudo setsebool container_use_devices off
container_use_devices --> off
ssh_sysadm_login --> off
--- flip one, runtime only ---
container_use_devices --> on
```

**That change is gone after a reboot.** `setsebool` without `-P` sets the running
value only. `setsebool -P` writes it into the policy store as well, takes noticeably
longer because it rebuilds part of the policy, and is what you almost always meant.
The failure mode is the systemd one from lesson 33 in a new costume: it works now,
it is not there after the reboot, and the connection between the two events is six
weeks of distance.

### 3. Nothing fits, so write a rule

This is genuinely rare, and it is where `audit2allow` comes in. It reads denials and
emits a policy module that would permit exactly them:

```
sudo ausearch -m AVC -ts recent | audit2allow -M myapp
sudo semodule -i myapp.pp
```

The first command writes `myapp.te`, which is human-readable, and `myapp.pp`, which
is the compiled module. **Read the `.te` file before installing it.** `audit2allow`
has no judgement: pointed at a denial caused by a mislabelled file it will cheerfully
generate a rule granting the service access to that entire type, which is a much
larger hole than relabelling one file. It answers "what would make this stop
complaining", which is not the same question as "what should this be allowed to do".

`semodule -l` lists what is installed, and on a stock machine it is already a lot:

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ sudo semodule -l | wc -l; echo "--- a few ---"; sudo semodule -l | head -5; echo "--- policy source ---"; ls /etc/selinux/; grep -v "^#" /etc/selinux/config | grep .
434
--- a few ---
abrt
accountsd
acct
adcli
afs
--- policy source ---
config
final
semanage.conf
targeted
SELINUX=enforcing
SELINUXTYPE=targeted
```

434 modules, one per subsystem somebody has written policy for. Your custom module
becomes the 435th, and being able to name it and remove it with `semodule -r myapp`
is why a module beats a permanent permissive domain.

<details class="deeper">
<summary>If you already administer Linux: `sealert`, and getting the useful half of setroubleshoot without the daemon</summary>

`setroubleshoot` watches the audit log and turns denials into paragraphs of English
with suggested fixes, delivered to the desktop or to `/var/log/messages`. When it is
installed, `sealert -a /var/log/audit/audit.log` is the fastest path from a denial to
a plausible fix, and it will often name the exact boolean.

Two things worth knowing about it in practice.

**It is not installed on servers and frequently should not be.** It is a Python
daemon that wakes on every denial, and on a machine generating denials at volume it
is a genuine performance problem. Minimal and image-based systems ship without it —
the machine these captures came from has neither `sealert` nor `audit2allow` — so
the audit log and the five fields above are the skill that actually travels.

**Its suggestions are ranked and the ranking is not always right.** It presents the
`chcon` fix and the `semanage fcontext` fix as alternatives, and copy-pasting the
first one gives you the change that evaporates at the next relabel. When it offers
both, take the `semanage` one.

Where it earns its place is the `if you want to allow` phrasing on booleans: it maps
a raw denial to the named switch faster than grepping 367 boolean names, and getting
from `scontext=httpd_t tcontext=mysqld_port_t` to `httpd_can_network_connect_db`
otherwise requires knowing the naming convention.

The other half of the tooling is `sesearch`, from `setools-console`, which queries
the loaded policy directly: `sesearch -A -s httpd_t -t httpd_sys_content_t` lists
every rule permitting the web server to touch web content. That is how you answer
"is this supposed to work at all" rather than guessing, and it is worth installing
on any machine where you write policy.

</details>

## Across distributions

This is the least portable topic in the block, because the two families made
different choices and both stuck with them.

| | RHEL family | Debian family |
| --- | --- | --- |
| Shipped and enforcing by default | **Yes** | No |
| Default MAC system | SELinux | AppArmor |
| Model | Labels on every object | Paths in per-program profiles |
| Enforcing state | `getenforce` | `aa-status` |
| Adjust without policy | Booleans | Edit the profile |
| Config | `/etc/selinux/config` | `/etc/apparmor.d/` |

**AppArmor is path-based rather than label-based**, and that one difference explains
most of the rest. A profile says "this program may read `/etc/myapp/*`", so there is
nothing to relabel and nothing to get out of sync — and equally, a hard link to a
file under a different path is a different rule, which SELinux's labels are immune
to because the label lives on the inode.

The exam is RHEL-centric here and AppArmor appears mainly so you know which machine
you are on. `sestatus` returning "command not found" on an Ubuntu box is the answer,
not a broken installation.

**SUSE runs AppArmor by default and ships SELinux as an option**, which is worth a
sentence only because it stops "SUSE is RHEL-like so it must be SELinux" from being a
free wrong answer.

## Prove it

```
# Which check are you even in? No AVC means it was not SELinux
sudo ausearch --input-logs -m AVC -ts recent

# What is the label, and what should it be
ls -Z /path/to/file
matchpathcon /path/to/file

# Fix the label properly
sudo restorecon -v /path/to/file

# Is there a switch for this instead
getsebool -a | grep <service>

# And the confirmation that the mode is what you think
getenforce
sestatus | head -6
```

**The pairing of `ls -Z` and `matchpathcon` is the highest-value habit in this
lesson.** Two commands, no changes made, and they separate a labelling problem from a
policy problem before you have touched anything.

## What trips people up

### 1. `setenforce 0` made it work, so that is the fix

It is not a fix, it is a *diagnosis*. All it establishes is that SELinux was
involved, which you now have to act on.

Here is the trap in a single transcript, and the reason it is so seductive:

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ sudo setenforce 0; getenforce; podman run --rm -v /var/tmp/sedemo:/data:ro docker.io/library/almalinux:10 cat /data/report.txt; sudo setenforce 1; getenforce
Permissive
the report
Enforcing
```

One command and the problem disappears. It is going to be tempting at 3am, and the
machine that stays permissive is the machine that fails its next audit — and, worse,
has silently lost a control that was doing real work, because containers really can
read each other's data once the categories stop being enforced.

Use permissive deliberately: switch to it, exercise the whole failing workflow so
every denial gets logged, switch back, then fix the complete list at once. That is
the legitimate use and it takes about two minutes.

### 2. `chcon` instead of `restorecon`

`chcon` writes the label you typed. `restorecon` writes the label policy says the
path should have. The first works today and vanishes at the next relabel; the second
is the durable answer.

If the path is non-standard, the fix is `semanage fcontext -a` to teach policy about
the path, *then* `restorecon` to apply it.

### 3. `setsebool` without `-P`

Same shape as `systemctl start` without `enable`. It works now, it is gone after a
reboot, and the two events are far enough apart that nobody connects them.

`setsebool -P` every time, and accept that it takes a few seconds longer.

### 4. Assuming a `Permission denied` is SELinux at all

Half the time it is not. **If there is no AVC, SELinux never got asked**, because DAC
ran first and refused. Checking `ausearch` before forming any theory costs one
command and prevents a whole afternoon of relabelling files that were never the
problem.

### 5. `:Z` on a shared volume

The uppercase form gives the volume one container's private categories. Mount it into
a second container and it is relabelled again, and the first container starts
failing — under load, in production, when you scale from one replica to two. Shared
data wants lowercase `:z`.

## Work it through

A web application was working. It now returns 500 on every page that reads an
uploaded file. Nothing was deployed; a colleague restored `/var/www/uploads` from a
backup last night.

Reason it out before reading on.

**First, decide whether SELinux is even involved:**

```
sudo ausearch --input-logs -m AVC -ts today | tail
```

An AVC naming `scontext=httpd_t` and `tcontext=` something that is not
`httpd_sys_content_t` settles it in one command. **No AVC at all** would mean the
restore got the owner or the mode wrong, and this is lesson 07's problem, not this
one.

**Second, confirm which of the three fixes applies:**

```
ls -Z /var/www/uploads/somefile
matchpathcon /var/www/uploads/somefile
```

They disagree — `ls -Z` says `user_home_t` or `default_t`, `matchpathcon` says
`httpd_sys_content_t`. That is case 1: **the label is wrong and the path is
standard.** The backup tool wrote files without preserving contexts, which most of
them do not by default.

**Third, fix it at the right level:**

```
sudo restorecon -Rv /var/www/uploads
```

Not `chcon`. The path is one policy already knows about, so the database has the
right answer and `restorecon` will apply it — and the fix will still be there after
the next policy update.

**Now change one detail and watch the answer change.** Suppose `matchpathcon` had
*agreed* with `ls -Z`. Then the label is right, and the denial is about an operation
rather than a file — `httpd_t` trying to open a network socket, say, because the
application now calls an external API. That is case 2, and
`getsebool -a | grep httpd` finds `httpd_can_network_connect` in about four seconds.

**And one more.** Suppose the uploads directory is on an NFS mount. NFS has no
extended attributes to store a label in, so every file on it presents a single
context set at mount time, and `restorecon` cannot change anything. The fix is a
mount option or a boolean — `httpd_use_nfs` — and no amount of relabelling will do
it. Recognising *which* of these three you are in, from two commands, is the skill.

The point worth extracting: **SELinux problems are diagnosable, not mysterious.** The
audit log names the subject, the object, and the operation. Everything after that is
deciding whether the object is mislabelled, the operation needs a switch, or you
genuinely need new policy — and the three have three different fixes, of which only
one is durable.

## Try it

Optional, on a RHEL-family machine or a VM you can break.

1. `sestatus`, and name what `Current mode` and `Mode from config file` each mean.
2. `id -Z` and `ps -eZ | head`. Find something not running as `unconfined_t`.
3. `touch /etc/test.conf`, `ls -Z` it, `chcon -t shadow_t` it, then `matchpathcon`
   and `restorecon -v` it. Watch the `Relabeled ... from ... to ...` line.
4. `getsebool -a | wc -l`, then `getsebool -a | grep httpd`.
5. `setsebool httpd_can_network_connect on`, confirm with `getsebool`, then reboot
   and check it again. Then do it with `-P`.
6. Deliberately break something: `chcon -t user_home_t` a file your web server
   serves, reload the page, and read the resulting AVC with `ausearch -m AVC -ts recent`.
   Name the five fields before you fix it.
7. Fix it with `restorecon`, and confirm with `ls -Z`.

**Verification step.** You have it when you can look at one AVC line and say, out
loud, which process type wanted which object type to do what — and then say which of
the three fixes applies, without running anything else.

## Check yourself

<details class="qa">
<summary>A file is mode 644 and owned by root. A service running as root gets `Permission denied` reading it. What is the first command you run, and what do the two possible outcomes tell you?</summary>

**`sudo ausearch --input-logs -m AVC -ts recent`**, before anything else.

**An AVC appears**: SELinux refused it. The line names `scontext` (what kind of
process asked), `tcontext` (what kind of object it wanted), and the operation in
`denied { ... }`, and those three decide the fix.

**No AVC appears**: SELinux was never consulted, because ordinary permissions are
checked first and refused it before the policy engine was asked. So despite the mode
bits looking fine, this is a DAC problem — a directory in the path without execute,
an ACL, or an immutable attribute.

The tempting wrong first move is `ls -l` again. You have already read it; reading it
a third time will not change it, and the whole point of this topic is that `ls -l`
cannot show you the check that is failing.

Second most tempting is `setenforce 0` to "see if it is SELinux". That does answer
the question, but it answers it by disabling a security control on a live machine,
and `ausearch` answers the same question without changing anything.

</details>

<details class="qa">
<summary>What is the difference between `chcon` and `restorecon`, and why does one of them stop working weeks later?</summary>

**`chcon` writes the context you specify. `restorecon` writes the context the policy
database says that path should have.**

`chcon` is an assertion with nothing behind it. Any relabel — a policy package
update, somebody running `restorecon -R /`, a `touch /.autorelabel` and reboot —
consults the file-context database, finds no support for your change, and reverts it.
The service breaks again with no apparent cause, weeks after the change, which makes
it exceptionally hard to connect back.

`restorecon` cannot drift, because it *is* what a relabel does.

**If the correct label for the path is not what policy currently thinks**, the fix is
not `chcon` either — it is to change the database and then apply it:

```
sudo semanage fcontext -a -t httpd_sys_content_t "/srv/web(/.*)?"
sudo restorecon -Rv /srv/web
```

Both commands, in that order. The first alone changes nothing on disk; the second
alone re-applies the old answer.

`chcon` is still useful for one thing: testing a theory in ten seconds before
committing to the durable fix.

</details>

<details class="qa">
<summary>Decode this: `avc: denied { open } for pid=2668 comm="cat" scontext=system_u:system_r:container_t:s0:c28,c528 tcontext=unconfined_u:object_r:user_tmp_t:s0 tclass=file`</summary>

**A process of type `container_t` tried to `open` a `file` of type `user_tmp_t`, and
no rule in the loaded policy permits that.**

The four fields, in the order you should read them:

- **`denied { open }`** — the operation. Note it is `open`, not `read`; policy is
  granular about which, and a rule permitting `read` but not `open` is a real thing.
- **`scontext`** — the subject, and only its **type** matters here: `container_t`.
- **`tcontext`** — the target, and again the type: `user_tmp_t`.
- **`tclass`** — what kind of object. `file` here, but `dir`, `tcp_socket`, and
  `unix_stream_socket` are all common and change the fix entirely.

The tempting misreading is that `unconfined_u` in the target context means the file
is unconfined and therefore fine. The **user** field is not the type and does almost
nothing on targeted policy; `user_tmp_t` is the whole story.

`comm=` and `pid=` tell you which command hit it, which helps you find the file to
fix, but the `scontext`/`tcontext` pair is the diagnosis.

And the fix here follows from the pair: a container should be reading
`container_file_t`, not `user_tmp_t`, so the volume needs relabelling — `:Z` at run
time, or `semanage fcontext` plus `restorecon` if it is a permanent host path.

</details>

<details class="qa">
<summary>Why is `setenforce 0` a legitimate diagnostic step but never a fix, and what is the correct way to use permissive mode?</summary>

**Because it establishes only one fact — that SELinux was involved — and leaves the
machine without a control it was relying on.**

The legitimate use is collecting the *complete* list of denials in one pass. In
enforcing mode the first denial stops the operation, so you fix it, run again, hit
the second, and iterate. In permissive mode nothing is refused and everything is
still logged, so one run of the failing workflow produces every denial at once:

```
sudo setenforce 0
# run the whole failing workflow
sudo ausearch --input-logs -m AVC -ts recent
sudo setenforce 1
```

Then fix the list, and go back to enforcing. That is a two-minute operation, not a
configuration change.

**`permissive` and `disabled` are not the same thing**, and the difference matters
if somebody suggests the latter. Permissive still labels files as they are created;
disabled does not. A machine left disabled accumulates unlabelled files, and turning
SELinux back on afterwards requires a full filesystem relabel — every file on every
filesystem — followed by a reboot, on a schedule nobody wants.

The other thing to know: `setenforce` never survives a reboot in either direction.
`/etc/selinux/config` is what the machine comes back as, which is why `sestatus`
prints both values.

</details>

<details class="qa">
<summary>A boolean was set, the service worked, and after the next reboot it failed again. What happened, and what is the general shape of this mistake?</summary>

**`setsebool` was run without `-P`.** Without it the change applies to the running
kernel only; `-P` also writes it to the policy store so it survives a reboot. The
`-P` run is noticeably slower because it rebuilds part of the policy, which is
exactly why people leave it off while testing and then forget to repeat it.

The general shape is the same mistake as `systemctl start` without `enable` from
lesson 33, and `ip addr add` without writing a config file from lesson 17: **a
runtime change and a persistent change are separate operations, and the runtime one
is the one with the shorter command.**

The evidence is always the same too — it works, nobody touches it, a reboot happens
weeks later during patching, and it does not come back. The gap between cause and
symptom is what makes it expensive.

The habit worth building: whenever you change something that took effect
immediately, ask what file that change is written into. If the answer is "none", you
are not finished.

</details>

## References

- [selinux(8)](https://man7.org/linux/man-pages/man8/selinux.8.html) - Linux man-pages project. Accessed 2026-08-08.
- [selinux_config(5)](https://man7.org/linux/man-pages/man5/selinux_config.5.html) - Linux man-pages project. Accessed 2026-08-08.
- [setsebool(8)](https://man7.org/linux/man-pages/man8/setsebool.8.html) - Linux man-pages project. Accessed 2026-08-08.
- [restorecon(8)](https://man7.org/linux/man-pages/man8/restorecon.8.html) - Linux man-pages project. Accessed 2026-08-08.
- [chcon(1)](https://man7.org/linux/man-pages/man1/chcon.1.html) - Linux man-pages project. Accessed 2026-08-08.
- [semanage-fcontext(8)](https://man7.org/linux/man-pages/man8/semanage-fcontext.8.html) - Linux man-pages project. Accessed 2026-08-08.
- [Using SELinux](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/10/html/using_selinux/index) - Red Hat. Accessed 2026-08-08.
- [podman-run(1)](https://docs.podman.io/en/latest/markdown/podman-run.1.html) - Podman. Accessed 2026-08-08.

Captured output came from a Fedora CoreOS virtual machine running SELinux in
enforcing mode with the targeted policy. The denial is a real one, produced by
mounting a `/var/tmp` directory into a container without relabelling it. Blocks
without a distribution and architecture header are illustrative; `audit2allow`,
`sealert`, and `semanage` are not present on that image and their invocations are
shown without output rather than with invented output.
