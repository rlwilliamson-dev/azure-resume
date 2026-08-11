---
title: "Hardening a system"
description: "Hardening is subtraction. Counting what is actually exposed, finding the programs that run as root no matter who starts them, making a file even root cannot edit, and the kernel switches worth setting."
deck: "Forty services are running and you need eleven"
track: "linux-plus"
level: "working"
order: 460
objectives:
  - "Inventory what a machine actually exposes, rather than guessing"
  - "Find every setuid binary and decide which ones can go"
  - "Use file attributes to protect a file from its own owner"
  - "Set and persist the kernel hardening switches that matter"
  - "Write a login banner that says something useful"
prerequisites: ["reading-and-setting-permissions", "systemd-units-and-services"]
tags: ["linux", "linux-plus", "hardening", "security", "suid", "sysctl"]
updated: 2026-08-08
draft: false
examObjectives:
  - exam: "xk0-006"
    domain: "3.0"
    objective: "3.3"
sources:
  - title: "chattr(1)"
    url: "https://man7.org/linux/man-pages/man1/chattr.1.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-08
    tier: 1
  - title: "lsattr(1)"
    url: "https://man7.org/linux/man-pages/man1/lsattr.1.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-08
    tier: 1
  - title: "find(1)"
    url: "https://man7.org/linux/man-pages/man1/find.1.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-08
    tier: 1
  - title: "capabilities(7)"
    url: "https://man7.org/linux/man-pages/man7/capabilities.7.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-08
    tier: 1
  - title: "issue(5)"
    url: "https://man7.org/linux/man-pages/man5/issue.5.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-08
    tier: 1
  - title: "sysctl.d(5)"
    url: "https://man7.org/linux/man-pages/man5/sysctl.d.5.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-08
    tier: 1
  - title: "ss(8)"
    url: "https://man7.org/linux/man-pages/man8/ss.8.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-08
    tier: 1
  - title: "CIS Benchmarks"
    url: "https://www.cisecurity.org/cis-benchmarks"
    publisher: "Center for Internet Security"
    accessed: 2026-08-08
    tier: 2
symptoms:
  - symptom: "Operation not permitted removing a file as root"
    anchor: "a-file-even-root-cannot-change"
  - symptom: "Unknown service listening on a port"
    anchor: "count-what-is-exposed"
---

> **Before you read.** You have been handed a server and told to harden it. The
> checklist you were given has ninety items and most of them are `sysctl` settings
> somebody copied from a blog in 2014.
>
> Meanwhile the machine is running a print server, a mail transfer agent, and an
> RPC daemon, none of which anybody has used since it was built.
>
> **Which of those two things is the actual attack surface?**

Hardening is mostly **subtraction**, and the order matters. A service that is not
installed cannot be exploited, cannot be misconfigured, and does not need patching.
No `sysctl` value achieves anything comparable.

That is not an argument against the rest of it. It is an argument about sequence:
remove, then restrict, then tune. Most hardening guides present ninety items as a
flat list, and people start at the top, which is where the low-value items live.

### Some words you will need

<dl class="terms">
<dt>attack surface</dt>
<dd>Everything reachable that could be attacked. Listening ports, setuid programs, running services, installed packages.</dd>
<dt>setuid</dt>
<dd>A permission bit that makes a program run as its owner rather than as the person running it. Usually root.</dd>
<dt>capability</dt>
<dd>One narrow slice of root's power, grantable on its own. The modern replacement for setuid.</dd>
<dt>attribute</dt>
<dd>A filesystem-level flag, separate from permissions. Immutable is the one that matters.</dd>
<dt>sysctl</dt>
<dd>A kernel tunable, read and written through <code>/proc/sys</code>.</dd>
<dt>banner</dt>
<dd>Text shown before or after login. Occasionally a legal requirement, frequently a free gift to an attacker.</dd>
<dt>benchmark</dt>
<dd>A published, itemised hardening standard. CIS is the common one.</dd>
</dl>

## What breaks without this

**A service nobody knew about has a vulnerability**, and the machine is compromised
through a daemon that had no business being installed.

**A setuid binary with a bug becomes a root shell.** That is the entire point of
setuid programs from an attacker's perspective, and there are more of them on a
default install than anybody expects.

**Your hardening is undone by the next configuration-management run**, because you
made the change by hand and the change is not in the file that survives.

**You harden the wrong things.** Ninety `sysctl` values and a print server still
listening on the network is a machine that passes an audit and fails an attacker.

## Count what is exposed

Start here, before anything on any checklist. Two commands.

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ sudo ss -tulnp | head -10
Netid State  Recv-Q Send-Q Local Address:Port Peer Address:PortProcess                          
udp   UNCONN 0      0          127.0.0.1:323       0.0.0.0:*    users:(("chronyd",pid=902,fd=4))
udp   UNCONN 0      0              [::1]:323          [::]:*    users:(("chronyd",pid=902,fd=5))
tcp   LISTEN 0      128          0.0.0.0:22        0.0.0.0:*    users:(("sshd",pid=987,fd=6))   
tcp   LISTEN 0      128             [::]:22           [::]:*    users:(("sshd",pid=987,fd=7))   
```

**The flags are worth learning as a unit.** `-t` TCP, `-u` UDP, `-l` listening only,
`-n` numeric so it does not stall on reverse DNS, `-p` the process. `ss -tulnp` is
one of the half-dozen commands worth having in muscle memory.

<figure class="learn-figure">
<svg viewBox="0 0 720 200" role="img" aria-labelledby="hd-t hd-d" style="width:100%;height:auto;">
<title id="hd-t">The same open port, bound two different ways</title>
<desc id="hd-d">A listening socket is only exposed if something can reach the address it is bound to. chronyd on 127.0.0.1 port 323 is bound to loopback, so nothing outside the machine can open a connection to it however open the port looks in a port scan of the process list. sshd on 0.0.0.0 port 22 is bound to every address the machine has, so it is reachable from any network the machine sits on. Counting ports without reading the address column therefore overstates the attack surface, sometimes badly.</desc>
<g>
<rect x="30" y="52" width="300" height="76" rx="5" fill="currentColor" fill-opacity="0.07" stroke="currentColor" stroke-opacity="0.32" stroke-dasharray="5 3"/>
<text x="180" y="78" text-anchor="middle" font-size="11" fill="currentColor">127.0.0.1:323</text>
<text x="180" y="98" text-anchor="middle" font-size="10" fill="currentColor" fill-opacity="0.75">chronyd, bound to loopback</text>
<text x="180" y="116" text-anchor="middle" font-size="10" fill="currentColor" fill-opacity="0.65">nothing off this machine can reach it</text>
<rect x="390" y="52" width="300" height="76" rx="5" fill="var(--accent)" fill-opacity="0.12" stroke="var(--accent)" stroke-opacity="0.9" stroke-width="1.8"/>
<text x="540" y="78" text-anchor="middle" font-size="11" fill="var(--accent)">0.0.0.0:22</text>
<text x="540" y="98" text-anchor="middle" font-size="10" fill="var(--accent)">sshd, bound to every address</text>
<text x="540" y="116" text-anchor="middle" font-size="10" fill="var(--accent)">this is the actual exposure</text>
<text x="30" y="34" font-size="10" fill="currentColor" fill-opacity="0.65">both appear as open ports in ss -tulnp</text>
<text x="30" y="166" font-size="10" fill="currentColor" fill-opacity="0.65">counting ports without reading the address column overstates the surface</text>
</g>
</svg>
<figcaption>Two listening sockets, and only one of them is a way in. Hardening is subtraction, so the first job is knowing what there is to subtract, and a port bound to loopback is not on that list no matter how alarming the count looks. Read the address column first, every time.</figcaption>
</figure>

**Read the address column, not just the port.** `127.0.0.1:323` is `chronyd`
listening on loopback only, unreachable from the network and not attack
surface at all. `0.0.0.0:22` is reachable from anywhere the network allows.
Those two lines look similar and mean completely different things, and
confusing them is how a "we have seventeen open ports" panic starts.

This machine is genuinely minimal: one service on the network, and a clock daemon
talking to itself. Every listener is accounted for. That is the state to aim at.

Then the services, which is a longer list than the listeners because most services do
not listen:

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ systemctl list-units --type=service --state=running --no-pager | head -12
  UNIT                        LOAD   ACTIVE SUB     DESCRIPTION
  auditd.service              loaded active running Security Audit Logging Service
  chronyd.service             loaded active running NTP client/server
  dbus-broker.service         loaded active running D-Bus System Message Bus
  fwupd.service               loaded active running Firmware update daemon
  getty@tty1.service          loaded active running Getty on tty1
  gssproxy.service            loaded active running GSSAPI Proxy Daemon
  irqbalance.service          loaded active running irqbalance daemon
  NetworkManager.service      loaded active running Network Manager
  polkit.service              loaded active running Authorization Manager
  qemu-guest-agent.service    loaded active running QEMU Guest Agent
  serial-getty@hvc0.service   loaded active running Serial Getty on hvc0
```

The question to ask of each line is not "is this dangerous" but **"would anything
notice if it were gone"**. `qemu-guest-agent` is useful on a VM and pointless on
metal. `fwupd` matters on a laptop. `gssproxy` matters if you use Kerberos and is
otherwise a daemon nobody has thought about since installation.

**Removing beats disabling**, and disabling beats masking:

| | Effect | Comes back when |
| --- | --- | --- |
| `dnf remove` | Gone from disk | Somebody reinstalls it |
| `systemctl disable --now` | Stopped, not started at boot | A dependency wants it |
| `systemctl mask` | Cannot be started at all | Never, until unmasked |

`mask` is the strong form and exists precisely because `disable` is not enough: a
disabled unit still starts if something else `Requires=` it, and `mask` symlinks it
to `/dev/null` so nothing can. It is the right answer for a service you must keep
installed and must never run.

## The programs that are root regardless of who runs them

`passwd` has to write `/etc/shadow`, which only root may write, and yet any user can
change their own password. The bit that makes that work is setuid, from lesson 07,
and every one of them is a small piece of root that ordinary users can execute.

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ sudo find /usr/bin /usr/sbin -perm -4000 -type f -exec ls -l {} + 2>/dev/null
-rwsr-xr-x. 2 root root  78560 Dec 31  1969 /usr/bin/chage
-rws--x--x. 2 root root  69152 Dec 31  1969 /usr/bin/chfn
-rws--x--x. 2 root root  69096 Dec 31  1969 /usr/bin/chsh
-rwsr-xr-x. 2 root root  69216 Dec 31  1969 /usr/bin/fusermount3
-rwsr-xr-x. 2 root root  73968 Dec 31  1969 /usr/bin/gpasswd
-rwsr-xr-x. 2 root root  68832 Dec 31  1969 /usr/bin/grub2-set-bootflag
-rwsr-xr-x. 2 root root  69256 Dec 31  1969 /usr/bin/mount
-rwsr-xr-x. 2 root root 135992 Dec 31  1969 /usr/bin/mount.nfs
-rwsr-xr-x. 2 root root  70824 Dec 31  1969 /usr/bin/newgrp
-rwsr-xr-x. 2 root root  68952 Dec 31  1969 /usr/bin/pam_timestamp_check
-rwsr-xr-x. 2 root root 144592 Dec 31  1969 /usr/bin/passwd
-rwsr-xr-x. 2 root root  69160 Dec 31  1969 /usr/bin/pkexec
-rwsr-xr-x. 2 root root  69472 Dec 31  1969 /usr/bin/su
---s--x--x. 2 root root 272560 Dec 31  1969 /usr/bin/sudo
-rwsr-xr-x. 2 root root  69160 Dec 31  1969 /usr/bin/umount
-rwsr-xr-x. 2 root root  69136 Dec 31  1969 /usr/bin/unix_chkpwd
```

**Sixteen on a deliberately minimal image**, and that is a short list, a
general purpose server install typically has twice as many.

`-perm -4000` is the search, and the leading minus is doing real work: it means "has
at least these bits", so it matches whatever else the mode contains. `-perm 4000`
without the minus matches only files whose mode is *exactly* 4000, which is almost
nothing. The same pattern with `-perm -2000` finds setgid files.

**Read the `s` in the mode string, and read where it is.** `-rwsr-xr-x` has it
in the owner's execute position: setuid. `-rwxr-sr-x` would have it in the
group's: setgid. `/usr/bin/sudo` shows `---s--x--x`, which is setuid with the
read bit removed for everybody. You may run it, you may not read it.

Which of these can go? The honest answer is that on a server, several:

| Binary | Needed if |
| --- | --- |
| `passwd`, `chage`, `gpasswd` | Local users change their own passwords |
| `su`, `sudo` | Somebody escalates. Usually keep `sudo`, often drop `su`. |
| `mount`, `umount` | Users mount removable media. On a server, rarely. |
| `chfn`, `chsh` | Users change their own shell or GECOS field. Almost never. |
| `pkexec` | A polkit-using desktop application needs privilege |
| `mount.nfs` | Users mount NFS shares themselves |

**`chfn` and `chsh` are the standard first removals.** Nobody on a server changes
their own finger information, and both have a history of vulnerabilities out of
proportion to their usefulness.

Removing the bit is one command and it is reversible:

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ sudo cp -p /usr/bin/newgrp /var/tmp/oldtool; ls -l /var/tmp/oldtool; echo "--- drop the setuid bit ---"; sudo chmod u-s /var/tmp/oldtool; ls -l /var/tmp/oldtool; sudo rm -f /var/tmp/oldtool
-rwsr-xr-x. 1 root root 70824 Dec 31  1969 /var/tmp/oldtool
--- drop the setuid bit ---
-rwxr-xr-x. 1 root root 70824 Dec 31  1969 /var/tmp/oldtool
```

`chmod u-s`, and the `s` becomes `x`. The program still runs; it just runs as you,
so anything needing root inside it now fails.

**Two cautions.** A package update restores the bit, because the package owns
the file's mode, so this belongs in configuration management, not in a one-off
shell session. And `rpm -V` will report the change as a modification, which is
correct and means your integrity baseline needs to know about it.

<details class="deeper">
<summary>If you already administer Linux: capabilities, and why <code>ping</code> stopped being setuid</summary>

Setuid is all-or-nothing: the program gets every power root has, because it *is*
root, and the only thing standing between a bug in it and full compromise is the
program's own care.

**Capabilities split root into about forty separate powers** that can be granted
individually. `ping` needs to open a raw socket and nothing else, so instead of
making it root:

```
sudo setcap cap_net_raw+ep /usr/bin/ping
getcap /usr/bin/ping
```

A bug in `ping` now yields the ability to craft raw packets, which is bad, rather
than the ability to do anything at all, which is catastrophic. This is why `ping` is
no longer setuid on any current distribution, and why `find / -perm -4000` returns a
shorter list every few years.

The ones worth recognising:

| Capability | Grants |
| --- | --- |
| `CAP_NET_BIND_SERVICE` | Bind a port below 1024 |
| `CAP_NET_RAW` | Raw and packet sockets |
| `CAP_NET_ADMIN` | Configure interfaces, routes, firewall |
| `CAP_SYS_ADMIN` | An enormous grab bag. Close to root. |
| `CAP_DAC_OVERRIDE` | Ignore file permission checks entirely |
| `CAP_SETUID` | Become any user |

**`CAP_SYS_ADMIN` is the one to be suspicious of.** So many operations were filed
under it over the years that granting it is close to granting root, and a container
or unit asking for it is usually asking for something more specific that nobody
bothered to identify.

**Auditing them is the same shape as auditing setuid:**

```
sudo getcap -r / 2>/dev/null
```

That list belongs in the same inventory as the setuid one, and it is the list
people forget, a binary with `cap_dac_override` reads every file on the
machine and does not appear in any setuid search.

The systemd side of this is `CapabilityBoundingSet=` in a unit file, from lesson 33:
a service that only needs to bind port 443 gets `CAP_NET_BIND_SERVICE` and nothing
else, and does not need to start as root at all.

</details>

## A file even root cannot change

Permissions are enforced against users. **Attributes are enforced against
everybody, including root.** That sentence is the whole section, and the
consequence is worth predicting before you see it.

The file below is owned by root, has ordinary permissions, and sits in `/etc`. The
command runs as root, with `-f`.

<details class="predict">
<summary>The immutable attribute is set with <code>chattr +i</code>. Given that it applies to everybody rather than to a particular user, what does <code>rm -f</code> do as root, and what does the error say?</summary>

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ sudo touch /etc/keepme.conf; sudo chattr +i /etc/keepme.conf; lsattr /etc/keepme.conf; sudo rm -f /etc/keepme.conf; echo "rc=$?"; sudo sh -c "echo x >> /etc/keepme.conf"
----i----------------- /etc/keepme.conf
rm: cannot remove '/etc/keepme.conf': Operation not permitted
rc=1
sh: line 1: /etc/keepme.conf: Operation not permitted
```

</details>

**`rm -f` as root, refused.** The `-f` did not help, because `-f` suppresses prompts
and does not grant permission. Appending was refused too. The file cannot be
modified, renamed, deleted, hard-linked to, or have its metadata changed by anybody.

**The `i` in `lsattr` output is the only visible evidence.** It is in the fifth
column of a twenty-character field, and it appears nowhere in `ls -l`, which is why
this costs people an hour the first time.

Reversing it is symmetric:

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ sudo chattr -i /etc/keepme.conf; lsattr /etc/keepme.conf; sudo rm -f /etc/keepme.conf; echo "rc=$?"
---------------------- /etc/keepme.conf
rc=0
```

**`Operation not permitted` as root is the signature.** Root normally gets
`Permission denied` from nothing, so this specific error on a file you own is
the thing that should make you run `lsattr`, and it is the single most useful
diagnostic in this topic, because nothing in `ls -l` shows the attribute.

The attributes worth knowing:

| Flag | Letter | Effect |
| --- | --- | --- |
| immutable | `i` | Cannot be changed at all, by anybody |
| append-only | `a` | Can be appended to, never truncated or overwritten |
| no dump | `d` | Skipped by `dump` |
| secure delete | `s` | Blocks zeroed on delete, where the filesystem supports it |

**`+a` on a log file is the interesting one**, because it means an intruder can add
to the log and cannot erase what is already there.

<details class="deeper">
<summary>If you already administer Linux: where immutable actually helps, and where it just breaks your automation</summary>

`chattr +i` gets recommended for `/etc/resolv.conf` more than anything else, usually
by somebody whose DHCP client keeps overwriting it. It works, and it is worth knowing
what it costs.

**It is not a security control against root.** Anybody who can run `chattr -i` can
undo it in one command, and anybody with `CAP_LINUX_IMMUTABLE` can too. What it
stops is *accident* and *automation*: a script that would have overwritten the file
fails loudly instead of succeeding quietly.

That is genuinely valuable and it is a different claim from "protects against
attackers".

**Where it earns its place:**

- A file that a misbehaving daemon keeps rewriting, while you work out why.
- `/etc/resolv.conf` on a machine where NetworkManager and something else disagree,
  as a stopgap.
- Append-only on audit logs, so a compromise cannot erase its own tracks. This is a
  real control, because it defeats a class of anti-forensics rather than a class of
  attacker.

Where it causes an outage:

- Anything configuration management writes. Ansible does not run `chattr -i` first;
  it reports a failure that reads like a permissions problem and is not, and the
  next person spends an hour on it.
- Anything a package update replaces. `rpm` and `dpkg` both fail on an immutable
  file, and a failed package transaction on a production machine at 2am is a worse
  problem than the one you were solving.
- A directory marked immutable stops files being created *in* it, which is rarely
  what people intend.

The rule that keeps this useful: if you set it, write down where. An immutable
file with no record of why is a trap for the next person, and it is invisible
to every tool except `lsattr`. Reviewing `lsattr -R /etc 2>/dev/null | grep -v
'^-----'` on a machine you inherit takes seconds and occasionally explains a
mystery somebody has been living with for a year.

</details>

## The kernel switches, and which are worth it

`sysctl` exposes kernel tunables. Most hardening checklists are mostly these, and
most of the entries do less than the checklist implies.

Here are six that appear on essentially every checklist, read off a stock,
unhardened installation. Before you look: distributions have been tightening their
own defaults for twenty years, and a checklist written in 2014 does not know that.

<details class="predict">
<summary>Of these six, how many do you think a current distribution already sets to the hardened value without anybody asking? <code>randomize_va_space</code> is address space randomisation and <code>dmesg_restrict</code> keeps ordinary users out of the kernel ring buffer.</summary>

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ sysctl kernel.dmesg_restrict kernel.kptr_restrict net.ipv4.conf.all.rp_filter net.ipv4.conf.all.accept_redirects fs.suid_dumpable kernel.randomize_va_space
kernel.dmesg_restrict = 1
kernel.kptr_restrict = 0
net.ipv4.conf.all.rp_filter = 0
net.ipv4.conf.all.accept_redirects = 1
fs.suid_dumpable = 2
kernel.randomize_va_space = 2
```

</details>

**Two of the six are already at the hardened value, and one of the remaining
four is deliberate.** That ratio is the reason to read before writing: a
hardening pass that sets all six is claiming credit for two it did not do,
and, worse, the same reflex applied to a value that has *improved* since the
checklist was written can weaken the machine while appearing to strengthen it.

**Some are already right and some are not**, which is exactly why you read
them rather than assuming. `kernel.randomize_va_space = 2` is full address
space layout randomisation and has been the default for years, an item on your
checklist that is already done. `kernel.dmesg_restrict = 1` keeps unprivileged
users out of the kernel ring buffer, also already set.

`net.ipv4.conf.all.accept_redirects = 1` is not what you want on a server: it means
the machine will change its routing table because an ICMP redirect told it to.

The ones with an actual argument behind them:

| Setting | To | Because |
| --- | --- | --- |
| `net.ipv4.conf.all.accept_redirects` | `0` | Stops a forged ICMP redirect altering routing |
| `net.ipv4.conf.all.send_redirects` | `0` | This machine is not a router |
| `net.ipv4.conf.all.rp_filter` | `1` | Drops packets whose source could not have come from that interface |
| `net.ipv4.tcp_syncookies` | `1` | Survives a SYN flood instead of filling the backlog |
| `kernel.kptr_restrict` | `1` | Hides kernel addresses from `/proc`, which defeats some exploits |
| `fs.protected_hardlinks` | `1` | Closes a symlink and hardlink race in shared directories |
| `fs.suid_dumpable` | `0` | A setuid program's core dump can contain secrets |

**`rp_filter` is worth a caveat**, because it is the one that causes outages.
On a machine with two interfaces and asymmetric routing, traffic arriving on
one and replies leaving by another, strict reverse path filtering drops
legitimate traffic. The value `2` is the loose mode, which checks the source
is reachable by *any* interface, and is the right answer on a multi-homed
host.

Making it stick is the usual two-part shape:

```
# now
sudo sysctl -w net.ipv4.conf.all.accept_redirects=0

# and after a reboot
sudo tee /etc/sysctl.d/99-hardening.conf <<'EOF'
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.tcp_syncookies = 1
kernel.kptr_restrict = 1
fs.suid_dumpable = 0
EOF
sudo sysctl --system
```

**`/etc/sysctl.d/` rather than `/etc/sysctl.conf`.** The drop-in directory is
ordered by filename, so a numbered file makes precedence explicit, and it does not
conflict with anything the distribution ships. `sysctl --system` reads every
directory in order and applies the lot, which is also what happens at boot.

<details class="deeper">
<summary>If you already administer Linux: reading a benchmark without doing everything in it</summary>

CIS Benchmarks and the DISA STIGs are itemised, numbered, and long, several
hundred items for a single distribution. Working through one top to bottom is
how hardening projects die.

**They are structured, and the structure is the useful part.** CIS marks each item
Level 1 or Level 2. Level 1 is meant to be applicable to essentially any machine
without breaking anything; Level 2 is for environments where security dominates
functionality and explicitly accepts a functional cost. Doing Level 1 completely and
Level 2 selectively is a defensible position that most auditors accept, and it is
about a third of the work.

Read the rationale field, not just the remediation. Every item has one, and it
is where you find out whether an item is defending against something in your
threat model. "Ensure the `cramfs` filesystem is disabled" is real if somebody
can plug in a USB stick and irrelevant on a cloud instance with no physical
access. The remediation is two lines; the rationale is what tells you whether
to bother.

Automate the assessment before automating the fix. `oscap` from lesson 50
scores a machine against a profile and produces a report with each item's
status. Running the scan first tells you your actual starting position, which
is usually much better than assumed, because distributions ship a lot of these
defaults already, you saw that above with `randomize_va_space` and
`dmesg_restrict`.

And keep the exceptions somewhere durable. Every real deployment has items it
cannot meet: a legacy application needing a weak cipher, a service that must
run as root. An exception with a written reason and a review date is a normal,
acceptable audit outcome. An undocumented deviation found by a scanner is a
finding, and the difference between those two is entirely paperwork you can do
in advance.

The trap worth naming: benchmarks are versioned against a distribution *version*.
Applying the RHEL 8 benchmark to a RHEL 10 machine produces items that do not apply,
items that are already met by newer defaults, and occasionally a remediation that
breaks something. Match the version.

</details>

## Banners

Three files, and people routinely edit the wrong one:

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ cat /etc/issue; echo "--- issue.net ---"; cat /etc/issue.net 2>&1; echo "--- motd ---"; ls -l /etc/motd /etc/motd.d 2>&1
\S
Kernel \r on \m (\l)

--- issue.net ---
\S
Kernel \r on \m (\l)
--- motd ---
-rw-r--r--. 1 root root 0 Aug  1  2022 /etc/motd

/etc/motd.d:
total 0
```

| File | Shown | To |
| --- | --- | --- |
| `/etc/issue` | **Before** login | Local console users |
| `/etc/issue.net` | **Before** login | Network users, if `sshd` is told to |
| `/etc/motd` | **After** login | Everybody who successfully authenticates |

**The escape sequences are the problem.** `\S` expands to the operating system name,
`\r` to the kernel release, `\m` to the architecture. So the shipped default
announces the exact OS and kernel version to anybody who connects, before they have
authenticated. That is free reconnaissance, and it is the default.

Replace them with text that says nothing about the machine:

```
sudo tee /etc/issue.net <<'EOF'
Authorised access only. Activity on this system is monitored and logged.
Disconnect immediately if you are not an authorised user.
EOF
```

**`/etc/issue.net` is not shown by `sshd` unless you tell it to**, which is the part
people miss. It needs `Banner /etc/issue.net` in `sshd_config` and a reload;
otherwise you have written a pre-login banner that nobody will ever see.

**"Welcome" is the word to avoid.** Some jurisdictions have treated a welcoming
banner as an invitation, undermining a prosecution. Whether that would hold anywhere
you operate is a question for a lawyer, and the cost of writing "Authorised access
only" instead of "Welcome" is zero, so the calculation is easy.

`/etc/motd.d/` is the modern arrangement: drop-in files assembled at login, so a
package or configuration management can add a line without fighting over one file.

## Secure Boot

Firmware verifying signatures on what it loads, so an attacker who can write to disk
cannot substitute a kernel:

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ sudo mokutil --sb-state; echo "--- firmware ---"; ls -d /sys/firmware/efi; sudo bootctl status 2>&1 | head -8
This system doesn't support Secure Boot
--- firmware ---
/sys/firmware/efi
Couldn't find EFI system partition. It is recommended to mount it to /boot/ or /efi/.
Alternatively, use --esp-path= to specify path to mount point.
System:
      Firmware: n/a (n/a)
 Firmware Arch: aa64
   Secure Boot: disabled (unsupported)
  TPM2 Support: no
  Measured UKI: no
```

**`mokutil --sb-state` is the one-line answer** and the two commands agree
here: Secure Boot is unsupported on this machine. It is a virtual machine
whose firmware does not implement it, which is common and worth knowing, a lot
of hypervisor configurations have Secure Boot off, and "we require Secure
Boot" as a policy needs checking against what the platform actually provides.

`/sys/firmware/efi` existing means the machine booted via UEFI rather than legacy
BIOS, which is the prerequisite: **Secure Boot is a UEFI feature and cannot exist
without it**. The two are frequently confused, and the directory is the fastest
check.

The chain is worth stating once, because it explains what Secure Boot does and
does not buy: firmware verifies the bootloader, the bootloader verifies the
kernel, and the kernel verifies module signatures. Break any link and the rest
is decoration. Notably, it says nothing about the filesystem after boot, a
machine with Secure Boot and no disk encryption still gives up all its data to
anybody holding the disk.

## Across distributions

| | RHEL family | Debian family |
| --- | --- | --- |
| MAC | SELinux, enforcing | AppArmor |
| Firewall | `firewalld` | `nftables` or `ufw` |
| Sysctl drop-ins | `/etc/sysctl.d/` | `/etc/sysctl.d/` |
| Secure Boot shim | `shim-x64` | `shim-signed` |
| Benchmark tooling | `oscap`, `scap-security-guide` | `oscap`, with fewer shipped profiles |
| Unattended patching | `dnf-automatic` | `unattended-upgrades` |

**Unattended patching is the row worth acting on.** It is not on most hardening
checklists and it beats most of what is, because the overwhelming majority of real
compromises use a vulnerability that had a patch available.

<details class="deeper">
<summary>If you already administer Linux: making unattended patching safe enough to actually leave on</summary>

The objection to automatic patching is always the same, an update will break
something at 3am with nobody watching, and it is a real objection that has a
mostly boring answer.

**Split the decision in two: download and apply, and reboot.** Almost all of the
risk lives in the second one. A package update replaces files and restarts the
affected service, which is usually seconds; a reboot is minutes and can fail to come
back. Configure them separately.

On the RHEL family, `dnf-automatic` reads `/etc/dnf/automatic.conf`:

```ini
[commands]
upgrade_type = security
apply_updates = yes
reboot = when-needed
reboot_command = "shutdown -r +5 'Rebooting after applying updates'"
```

`upgrade_type = security` is the setting that makes this defensible: it applies only
updates the vendor has flagged as security fixes, which is a much smaller and much
better-tested set than everything. Enable `dnf-automatic.timer`, not the service.

On the Debian family, `unattended-upgrades` with
`/etc/apt/apt.conf.d/50unattended-upgrades`:

```
Unattended-Upgrade::Allowed-Origins { "${distro_id}:${distro_codename}-security"; };
Unattended-Upgrade::Automatic-Reboot "false";
Unattended-Upgrade::Automatic-Reboot-Time "03:00";
```

Same shape: the security pocket only, and reboot as a separate decision.

**Two things that make the reboot question smaller than it looks.**
`needs-restarting -r` on RHEL and the presence of `/var/run/reboot-required`
on Debian tell you whether a reboot is actually pending, so you can batch them
into a window instead of taking one per update. And `needs-restarting -s`
lists the *services* holding old libraries open, frequently the real fix is
restarting three daemons rather than the machine.

Livepatching removes most of the remaining argument for kernel updates
specifically: `kpatch` on RHEL, Canonical's Livepatch on Ubuntu. Neither is a
complete substitute, because a livepatched kernel still needs a real reboot
eventually, but they turn "reboot this week" into "reboot this quarter".

The honest counter-argument, and when to accept it: on a machine where an
outage costs more than a breach (a single-node database with no replica, an
industrial controller) staged patching with a human is correct. That is a
small minority of machines, and the decision should be written down per
machine rather than assumed for the fleet, because "we patch manually" almost
always decays into "we do not patch".

</details>

## Prove it

```
# What is exposed
sudo ss -tulnp
systemctl list-units --type=service --state=running

# What runs as root regardless of who starts it
sudo find / -xdev -perm -4000 -type f -exec ls -l {} + 2>/dev/null
sudo getcap -r / 2>/dev/null

# What has attributes you cannot see in ls -l
sudo lsattr -R /etc 2>/dev/null | grep -v '^--------------------'

# What the kernel is actually set to, not what your file says
sysctl -a | grep -E 'accept_redirects|rp_filter|syncookies'

# And whether your changes survived
sudo sysctl --system
```

**`sysctl -a` reads the running kernel; the files in `/etc/sysctl.d/` are only an
intention.** Checking the file rather than the value is how a hardening change that
was silently overridden goes unnoticed for a year.

## What trips people up

### 1. Hardening the tunables and leaving the services

Ninety `sysctl` values on a machine still running an unused mail server is a machine
that passes an audit and fails an attacker. Inventory and remove first.

### 2. `chmod u-s` by hand

A package update puts the bit back, because the package owns the file's mode. The
change belongs in configuration management, and `rpm -V` will correctly report it as
a modification.

### 3. Immutable files that break automation

`chattr +i` makes Ansible, `rpm`, and `dpkg` fail with errors that read like
permissions problems. `Operation not permitted` as root means run `lsattr`.

Nothing in `ls -l` shows it.

### 4. Editing `/etc/issue` and expecting SSH users to see it

`/etc/issue` is the console. Network users get `/etc/issue.net`, and only if
`sshd_config` has a `Banner` line pointing at it.

And the shipped default announces your kernel version, which is the opposite of what
a banner is for.

### 5. `rp_filter = 1` on a multi-homed host

Strict reverse path filtering drops legitimate traffic when routing is asymmetric.
Use `2` on a machine with more than one path.

### 6. Assuming defaults are bad

`kernel.randomize_va_space = 2` and `kernel.dmesg_restrict = 1` were already set on
the machine above. Reading the current value before changing it saves work and avoids
the more embarrassing failure of "hardening" a setting into a weaker value than it
had.

## Work it through

You inherit a web server. It has never been hardened and you have half a day. What do
you do, in order?

Reason it out before reading on.

**Inventory. Change nothing.**

```
sudo ss -tulnp
systemctl list-units --type=service --state=running
```

Suppose that turns up `httpd` on 80 and 443, `sshd` on 22, and, the actual
finding, `cups` on 631 and `rpcbind` on 111. A web server does not print and
does not serve NFS. Those are two whole network services that exist only as
risk, and removing them is a bigger win than everything else on this page
combined.

**Close what is left.** `sshd` on 22 is necessary; is it reachable from the
whole internet? A firewall rule limiting it to the management network, from lessons
40 and 41, removes it from the attack surface without removing the service.

**Subtract privilege.**

```
sudo find / -xdev -perm -4000 -type f -exec ls -l {} + 2>/dev/null
```

`chfn` and `chsh` go. Anything from a vendor package that nobody can explain gets
investigated, because a setuid binary outside `/usr/bin` and `/usr/sbin` is unusual
enough to deserve a question.

**The tunables**, in `/etc/sysctl.d/99-hardening.conf`, after reading the
current values.

**The banner**, and remember the `Banner` line in `sshd_config` or you have
written a file nobody reads.

And the thing that is not on the list and outranks items three through five:
is unattended patching enabled? A machine that patches itself weekly is in
better shape than one with a perfect `sysctl` file and a six-month-old kernel.

Now the point worth extracting. **Hardening has an order, and the order is by
how much it removes.** A service that is not installed cannot be exploited. A
privilege that is not granted cannot be abused. A tunable makes an existing
thing marginally harder to attack. Checklists present all three as equal
because a checklist has no way to express that the first item is worth more
than the next forty, and reading one in the order it is printed is how people
spend a day on `sysctl` and leave a print server on the internet.

## Try it

Optional, on a machine you can break.

1. `sudo ss -tulnp` and account for **every** listener. Anything you cannot explain
   is the finding.
2. `systemctl list-units --type=service --state=running` and ask of each: would
   anything notice if this were gone?
3. `sudo find / -xdev -perm -4000 -type f 2>/dev/null | wc -l`, then look at the list.
4. `sudo getcap -r / 2>/dev/null`. It is usually shorter and always more surprising.
5. `sudo touch /etc/testfile; sudo chattr +i /etc/testfile`, then try to delete it as
   root. Read the error. Then `lsattr` it, then `chattr -i` and delete it.
6. `sysctl kernel.randomize_va_space kernel.dmesg_restrict` before you change
   anything, and notice they are already right.
7. `cat /etc/issue.net` and work out exactly how much it tells a stranger.

**Verification step.** You have it when you can look at `ss -tulnp` on an unfamiliar
machine and say which lines are attack surface and which are loopback noise, without
looking anything up.

## Check yourself

<details class="qa">
<summary>You have one hour to harden a server. Do you work through the CIS benchmark or do something else first, and why?</summary>

**Inventory and remove first.** `ss -tulnp` and
`systemctl list-units --type=service --state=running`, then remove or mask anything
the machine does not need.

The reasoning is about what each action buys. A service that is not installed
cannot be exploited, cannot be misconfigured, and does not need patching, it
removes an entire category of risk permanently. A `sysctl` value makes an
existing exposure marginally harder to attack. Those are not comparable, and a
checklist has no way to say so because every item looks the same on the page.

The tempting wrong answer is that the benchmark is authoritative so it must be the
right starting point. It is authoritative about *what* to do and says nothing useful
about order, and it is long enough that starting at item one means the high-value
work never happens.

The other thing to do inside that hour, which is on very few checklists: **turn on
unattended patching.** Most real compromises exploit something that had a patch
available, so a machine that patches itself is ahead of one with a perfect
configuration and a stale kernel.

</details>

<details class="qa">
<summary>What does <code>find / -perm -4000</code> look for, why does the leading minus matter, and what is the risk it is finding?</summary>

**Setuid files.** The `4000` is the setuid bit, and those programs run as
their owner, nearly always root, no matter who executes them.

The leading minus means "at least these bits". `-perm -4000` matches any file
whose mode includes 4000, whatever else it contains, which is what you want.
`-perm 4000` without the minus matches only files whose mode is *exactly*
4000, setuid with no permission bits at all, which is essentially nothing, so
the search appears to come back clean when it has found nothing because it was
asked the wrong question.

The risk is that each one is a small piece of root that any user can run. A
bug in a setuid program is not a bug that gets you the program's privileges;
it is a bug that gets you root, because the process genuinely is root.

`chfn` and `chsh` are the conventional removals on a server: nobody changes their
finger information, and both have a vulnerability history out of proportion to their
value.

The related search people forget is `getcap -r /`. A binary with `cap_dac_override`
can read every file on the machine and appears in no setuid listing at all.

</details>

<details class="qa">
<summary><code>rm -f</code> on a file, as root, returns <code>Operation not permitted</code>. What is going on, and what shows it?</summary>

**The file has the immutable attribute.** `chattr +i` prevents modification,
deletion, renaming, and hard-linking, and it applies to root as well as to everyone
else. `-f` does not help, because `-f` suppresses prompting and does not grant
permission.

`lsattr` on the file is what shows it. Nothing in `ls -l` does, which is why
this is such a reliable time-waster, every tool you would normally reach for
reports that the permissions are fine.

The error text is the tell. Root does not normally get refused by file
permissions, so `Operation not permitted` as root on a file you own is a
strong signal to check attributes rather than modes.

`chattr -i` clears it.

The reason it matters beyond the immediate fix: an immutable file makes Ansible,
`rpm`, and `dpkg` fail in the same way, and a failed package transaction on a
production machine is worse than the problem the immutable flag was solving. If you
set it, write down where.

</details>

<details class="qa">
<summary>Why do people edit <code>/etc/issue</code> and find that SSH users never see it, and what is wrong with the shipped default anyway?</summary>

**Two separate mistakes.**

`/etc/issue` is shown before login on the **local console**. Network users get
`/etc/issue.net`, and only if `sshd_config` contains a `Banner /etc/issue.net`
line and sshd has been reloaded. Without that line the file exists and is
never displayed to anybody.

`/etc/motd` is different again: it appears **after** a successful login, so it cannot
serve as a warning to unauthorised users at all. It is for messages to people who
already got in.

**And the shipped default is actively unhelpful.** `\S`, `\r`, and `\m` expand to the
operating system, kernel release, and architecture, so an unauthenticated stranger is
told exactly what the machine runs before they have proved anything. That is free
reconnaissance handed over by default.

Replace it with text that identifies nothing and states that access is restricted and
monitored. Avoid the word "welcome": it has been argued in court as an invitation,
and writing "Authorised access only" instead costs nothing.

</details>

<details class="qa">
<summary>You set a hardening sysctl, and months later the value is wrong again. Give two distinct explanations and how to tell them apart.</summary>

**One: it was only ever set at runtime.** `sysctl -w` changes the running kernel and
writes nothing to disk, so the next reboot restores the old value. This is the same
shape as `systemctl start` without `enable` and `setsebool` without `-P`.

Two: it is set in a file, and a later file overrides it. `/etc/sysctl.d/` is
processed in filename order, and a drop-in shipped by a package with a
higher-sorting name wins. Your `50-tuning.conf` loses to a vendor's
`99-something.conf`, and nothing warns you.

Telling them apart takes two commands:

```
sysctl net.ipv4.conf.all.accept_redirects      # what the kernel is doing
grep -r accept_redirects /etc/sysctl.d/ /etc/sysctl.conf   # who has an opinion
```

If nothing in the files mentions it, it was case one. If more than one file mentions
it, the highest-numbered filename is the one in effect, and that is case two.

The fix for both is a numbered drop-in high enough to win,
`99-hardening.conf`, and then `sysctl --system` to apply everything in order
the way boot does.

The general habit: **checking the file is not checking the setting.** Read the value
from the running kernel, always.

</details>

## References

- [chattr(1)](https://man7.org/linux/man-pages/man1/chattr.1.html) - Linux man-pages project. Accessed 2026-08-08.
- [lsattr(1)](https://man7.org/linux/man-pages/man1/lsattr.1.html) - Linux man-pages project. Accessed 2026-08-08.
- [find(1)](https://man7.org/linux/man-pages/man1/find.1.html) - Linux man-pages project. Accessed 2026-08-08.
- [capabilities(7)](https://man7.org/linux/man-pages/man7/capabilities.7.html) - Linux man-pages project. Accessed 2026-08-08.
- [issue(5)](https://man7.org/linux/man-pages/man5/issue.5.html) - Linux man-pages project. Accessed 2026-08-08.
- [sysctl.d(5)](https://man7.org/linux/man-pages/man5/sysctl.d.5.html) - Linux man-pages project. Accessed 2026-08-08.
- [ss(8)](https://man7.org/linux/man-pages/man8/ss.8.html) - Linux man-pages project. Accessed 2026-08-08.
- [CIS Benchmarks](https://www.cisecurity.org/cis-benchmarks) - Center for Internet Security. Accessed 2026-08-08.

Captured output came from a Fedora CoreOS virtual machine, which is a
deliberately minimal image, a general purpose server install has a longer
setuid list and more running services than shown here. Secure Boot is
unsupported on that platform, and the output says so rather than being
simulated. Blocks without a distribution and architecture header are
illustrative.
