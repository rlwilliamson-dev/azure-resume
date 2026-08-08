---
title: "Users, root, and sudo"
description: "Why a machine you own tells you permission denied, who root is, and how to borrow root's authority for one command at a time without becoming a hazard."
track: "linux-plus"
level: "intro"
order: 70
objectives:
  - "Explain what a user account is and read your own identity with id"
  - "Say what root can do and why you should not be logged in as root"
  - "Use sudo for a single command and explain what it checks before running it"
  - "Choose between su, su -, and sudo -i and justify the choice"
prerequisites: ["reading-and-editing-files"]
tags: ["linux", "linux-plus", "accounts", "sudo", "beginner"]
updated: 2026-08-07
draft: false
examObjectives:
  - exam: "xk0-006"
    domain: "2.0"
    objective: "2.2"
  - exam: "xk0-006"
    domain: "3.0"
    objective: "3.3"
sources:
  - title: "id(1)"
    url: "https://man7.org/linux/man-pages/man1/id.1.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "su(1)"
    url: "https://man7.org/linux/man-pages/man1/su.1.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "passwd(5)"
    url: "https://man7.org/linux/man-pages/man5/passwd.5.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "useradd(8)"
    url: "https://man7.org/linux/man-pages/man8/useradd.8.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "sudo(8)"
    url: "https://www.sudo.ws/docs/man/sudo.man/"
    publisher: "Sudo Project"
    accessed: 2026-08-07
    tier: 1
  - title: "sudoers(5)"
    url: "https://www.sudo.ws/docs/man/sudoers.man/"
    publisher: "Sudo Project"
    accessed: 2026-08-07
    tier: 1
symptoms:
  - symptom: "Permission denied on a machine you own"
    anchor: "1-permission-denied-on-your-own-machine"
  - symptom: "is not in the sudoers file. This incident will be reported"
    anchor: "2-is-not-in-the-sudoers-file"
---

> **Before you read.** You bought the computer. You installed the operating
> system. Nobody else has ever logged into it. You try to save a file and it says
> `Permission denied`.
>
> Denied by whom, exactly? And if you are the only person here, who is the system
> protecting the file from?

The answer is not "from you". It is from *a mistake you might make*, which is a
different thing and a more useful one.

Linux was built for machines with many users on them at once, and it never gave
that up when it moved onto laptops. Every file belongs to somebody, every process
runs as somebody, and the system checks before it acts. That check is the reason
a bad command usually breaks one account rather than the whole machine.

### Some words you will need

<dl class="terms">
<dt>user account</dt>
<dd>An identity the system recognises. It owns files, runs programs, and has a numeric ID that the kernel actually uses.</dd>
<dt>root</dt>
<dd>The administrator account, user ID 0. Permission checks do not apply to it.</dd>
<dt>group</dt>
<dd>A named collection of users, so permission can be granted to several people at once without listing them individually.</dd>
<dt>UID and GID</dt>
<dd>The numeric user and group IDs. Names are for humans; the kernel compares numbers.</dd>
<dt>privilege escalation</dt>
<dd>Temporarily acting with more authority than your account normally has. <code>sudo</code> is the supported way to do it.</dd>
</dl>

## What breaks without this

**You cannot administer anything.** Installing software, editing anything under
`/etc`, restarting a service — all of it needs privilege you do not have by
default, and "permission denied" is where you stop until you understand why.

**Or you overcorrect and run everything as root.** This is the more expensive
failure. Working as root means every typo executes with full authority, and the
classic disasters all start this way.

**You cannot answer the audit question.** "Who made this change?" is a question
with a real answer if people escalate through `sudo`, and no answer at all if
everyone shares a root login. That is why objective 3.3 cares about this and not
just objective 2.2.

## Who are you?

Two commands. `whoami` gives the short answer, `id` gives the useful one:

```bash
# Debian 13 (trixie), x86_64
$ whoami; id; echo "--- now as sam ---"; su - sam -c "whoami; id"
root
uid=0(root) gid=0(root) groups=0(root)
--- now as sam ---
sam
uid=1000(sam) gid=1000(sam) groups=1000(sam)
```

Read the `id` line as three facts: who you are, what your primary group is, and
every group you belong to.

**`uid=0` is the entire definition of root.** Not the name. A user account named
`root` with UID 500 would be an ordinary user, and an account named `dave` with
UID 0 would have complete authority over the machine. The kernel compares the
number.

That is also why "is there an account with UID 0 that should not be there" is a
real security check, and a genuinely quick one.

The numbers are not arbitrary. **0 is root, low numbers are system accounts, and
regular humans start at 1000** on most distributions. Sam is 1000, so sam was
the first real person created on this machine.

## What an account actually is

An account is a line in a text file. That is not a simplification.

```bash
# Debian 13 (trixie), x86_64
$ grep sam /etc/passwd; grep sam /etc/group; ls -ld /home/sam
sam:x:1000:1000::/home/sam:/bin/bash
sam:x:1000:
drwx------. 2 sam sam 57 Aug  8 00:30 /home/sam
```

Seven colon-separated fields, and you should be able to name them:

| Field | Value here | Means |
| --- | --- | --- |
| 1 | `sam` | Login name |
| 2 | `x` | Password placeholder — the real hash is in `/etc/shadow` |
| 3 | `1000` | UID |
| 4 | `1000` | Primary GID |
| 5 | *(empty)* | GECOS: full name and other free text |
| 6 | `/home/sam` | Home directory |
| 7 | `/bin/bash` | Login shell |

**That `x` in field two matters.** It is not the password and it is not an
abbreviation for one. It is a marker saying "the hash lives in `/etc/shadow`",
which is a separate file that ordinary users cannot read. `/etc/passwd` has to
be world-readable so that anything printing a username can look it up, and
putting password hashes in a world-readable file was, in hindsight, not the
finest hour of early Unix.

Field seven is worth a second look too. Setting a user's shell to
`/usr/sbin/nologin` is how you make an account that owns files and runs services
but that nobody can log into. Scroll back to the `/etc/passwd` output in lesson
05 and you will see most of the accounts on the system are exactly that.

<details class="deeper">
<summary>If you already administer Linux: the files, and why you edit them with tools</summary>

Four files carry the whole model: `/etc/passwd`, `/etc/shadow`, `/etc/group`,
`/etc/gshadow`. Editing them by hand is possible and inadvisable. `vipw` and
`vigr` take the appropriate lock and validate on exit; a hand edit that leaves a
malformed line can lock every account out at once, which is a memorable way to
learn about single-user mode.

`getent passwd sam` is better than `grep sam /etc/passwd` because it goes through
NSS, so it also answers for LDAP, SSSD, and anything else in
`/etc/nsswitch.conf`. On a domain-joined box `grep` returns nothing for a user
who plainly exists, and that discrepancy is diagnostic rather than confusing once
you know why.

`useradd` is the low-level tool and honours `/etc/default/useradd` and
`/etc/login.defs`. `adduser` on the Debian family is a Perl wrapper with better
defaults and an interactive prompt. They are not the same command, and a runbook
written for one distribution using `adduser` fails on RHEL where only `useradd`
exists.

</details>

## What root can do

Everything. That is the whole answer, and it is worth being blunt about because
people expect more nuance than there is.

Root skips the permission check. Not "root has permission to most things" —
**the check does not run**. Root can read any file, delete any file, kill any
process, and reformat the disk it is running from. There is no confirmation
prompt because there is no authority above root to ask.

Here is what that feels like from the other side. Sam, an ordinary user, tries
three things:

```bash
# Debian 13 (trixie), x86_64
$ su - sam -c "cat /etc/shadow"; su - sam -c "touch /etc/newfile"; su - sam -c "sudo whoami"
cat: /etc/shadow: Permission denied
touch: cannot touch '/etc/newfile': Permission denied
-bash: line 1: sudo: command not found
```

Two refusals and one surprise. Sam cannot read the password hashes and cannot
create a file in `/etc`, both of which are correct and desirable.

The third line is a different kind of failure and worth noticing: **`sudo` is not
installed here at all**. It is not part of the base system on every image. On a
minimal container or a stripped install you may have to install it before you can
use it, which is a chicken-and-egg problem you solve by being root already, or by
booting into rescue.

## sudo: borrowing authority for one command

`sudo` runs a single command as another user, defaulting to root, and then hands
you straight back to your own account. Three things happen before it runs
anything:

1. **It checks the rules** in `/etc/sudoers` and `/etc/sudoers.d/` — are you
   allowed to run this?
2. **It asks for a password** — *yours*, not root's. That surprises people and it
   is the point: root's password does not need to exist or be shared.
3. **It logs the attempt**, allowed or denied, with who, when, from where, and
   what.

Ask for something you are not entitled to and it says so:

```bash
# Debian 13 (trixie), x86_64
$ su - sam -c "echo notarealpassword | sudo -S whoami"
[sudo] password for sam: sam is not in the sudoers file.
```

The password was accepted — that is sam's real password. The refusal is about
**authorisation**, not authentication. Sam proved who they were and the answer
was still no, which is exactly the distinction the security domain of this exam
keeps returning to.

The fix is not to hand out root's password. It is to put sam in the group that
the sudo rules already trust:

```bash
# Debian 13 (trixie), x86_64
$ usermod -aG sudo sam; id sam; su - sam -c "echo notarealpassword | sudo -S true 2>/dev/null; sudo whoami; sudo touch /etc/newfile; ls -l /etc/newfile"
uid=1000(sam) gid=1000(sam) groups=1000(sam),27(sudo)
root
-rw-r--r--. 1 root root 0 Aug  8 00:21 /etc/newfile
```

Three things to read out of that.

`id sam` now shows `27(sudo)` alongside sam's own group. **That group membership
is the whole grant** — no file was edited, no password was shared.

`sudo whoami` printed `root`. The `whoami` ran as root, then sam's shell carried
on as sam.

`sudo touch /etc/newfile` succeeded where the same command failed a moment ago,
and the file it created is **owned by root**, because the command ran as root.
That last point catches people out: files created under `sudo` belong to root,
so a file you made this way may be one you cannot then edit normally.

Only one password prompt appears for three `sudo` commands. **`sudo` caches your
authentication for a few minutes** — fifteen by default — per terminal. Convenient,
and also the reason an unlocked laptop with a recent `sudo` in its history is
more dangerous than it looks.

Notice that flag combination, because leaving one letter off it is destructive.
`-G` sets the complete list of supplementary groups; `-a` means append to the
list rather than replace it. Sam here starts out in three groups besides their
own.

<details class="predict">
<summary>Somebody types `usermod -G sudo sam` without the `-a`. Sam is currently in `adm`, `deploy`, and `webdev`. What does `id sam` report afterwards?</summary>

```bash
# Debian 13 (trixie), x86_64
$ id sam; usermod -G sudo sam; echo "--- after usermod -G sudo sam ---"; id sam
uid=1000(sam) gid=1000(sam) groups=1000(sam),4(adm),1001(deploy),1002(webdev)
--- after usermod -G sudo sam ---
uid=1000(sam) gid=1000(sam) groups=1000(sam),27(sudo)
```

Three group memberships gone. `adm`, `deploy`, and `webdev` were replaced by
`sudo`, because that is precisely what "set the list" means.

Sam's own group survives because it is the **primary** group, stored in a
different field of `/etc/passwd`, which `-G` does not touch.

The damage is quiet. No error, no output, no warning. Sam can still log in and
still owns every file they owned before, and finds out about the loss the next
time they touch something that needed `deploy`. **Always `-aG`**, and run `id`
afterwards to confirm you appended rather than replaced.

</details>

## su, su -, and sudo -i

Three ways to become somebody else, and the differences are not cosmetic.

| Command | Becomes | Password wanted | Environment |
| --- | --- | --- | --- |
| `su sam` | sam | sam's | Mostly keeps yours |
| `su - sam` | sam | sam's | A fresh login as sam |
| `su -` | root | root's | A fresh login as root |
| `sudo -i` | root | **yours** | A fresh login as root |
| `sudo command` | root, for one command | **yours** | Yours, mostly |

The dash is doing the work in `su`. Without it you take on the new identity but
keep the environment you arrived with:

```bash
# Debian 13 (trixie), x86_64
$ cd /root; su sam -c "pwd; echo \$HOME"; echo "--- now with the dash ---"; su - sam -c "pwd; echo \$HOME"
/root
/home/sam
--- now with the dash ---
/home/sam
/home/sam
```

Without the dash sam is standing in `/root`, a directory sam cannot even list.
With the dash sam starts in sam's own home, as a real login would.

The environment difference is worse than the directory one:

```bash
# Debian 13 (trixie), x86_64
$ su sam -c "echo \$PATH"; echo "--- now with the dash ---"; su - sam -c "echo \$PATH"
/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
--- now with the dash ---
/usr/local/bin:/usr/bin:/bin:/usr/local/games:/usr/games
```

Look at what disappears. The first `PATH` has `/usr/sbin` and `/sbin` in it,
because it was inherited from root. The second does not, because that is what
sam's own login gets.

**This is the source of an entire genre of confusion.** You `su` to root without
the dash, type an admin command, and get `command not found` — for a command that
is definitely installed. It is in `/usr/sbin`, and your inherited `PATH` never
looked there. The command exists, you have the privilege to run it, and the shell
cannot find it.

Use the dash. `su -` and `sudo -i` both give you a clean login environment, which
is the one that matches what documentation assumes.

<details class="deeper">
<summary>If you already administer Linux: wheel vs sudo, logging, and why <code>sudo su</code> is a smell</summary>

The trusted group differs by family. RHEL and its rebuilds use **`wheel`**; Debian
and Ubuntu use **`sudo`**. Same idea, different name, and a provisioning script
that assumes one silently grants nothing on the other — the `usermod` succeeds,
creating the group membership, and the sudo rule that would have honoured it does
not exist.

Never edit `/etc/sudoers` directly. `visudo` validates the syntax before saving,
and a malformed sudoers file means *nobody* can escalate, on a machine where
fixing it requires escalation. Prefer a drop-in under `/etc/sudoers.d/` with mode
`0440`; files there are read in lexical order and are far easier to manage with
configuration tooling than edits to a shared file.

Logging is the reason auditors like `sudo`. Entries land in `/var/log/secure` on
RHEL and `/var/log/auth.log` on Debian, and `journalctl -u sudo` or `journalctl
_COMM=sudo` finds them on any systemd box. Every invocation is recorded with the
requesting user, the target user, the working directory, and the full command
line. That is the audit trail a shared root password destroys.

`sudo su -` is a smell rather than a sin. It works, and it appears in a great
many runbooks. But it converts a fully-attributed audit trail into a single line
saying "sam started a root shell at 09:14", after which every subsequent action is
unattributed. `sudo -i` is the supported way to get the same shell and is one
character shorter, which removes the last excuse.

`NOPASSWD` deserves suspicion. It is legitimate for a service account running one
specific command non-interactively, and it is a standing privilege escalation
when applied to `ALL`. Scope it to the exact command with its full path, and know
that a wildcard in that path can often be walked around.

</details>

## Across distributions

| | RPM family | dpkg family |
| --- | --- | --- |
| Admin group | `wheel` | `sudo` |
| Grant it | `usermod -aG wheel sam` | `usermod -aG sudo sam` |
| Auth log | `/var/log/secure` | `/var/log/auth.log` |
| Create a user | `useradd -m sam` | `useradd -m sam` or `adduser sam` |
| Root login enabled by default | Usually yes | Ubuntu disables it; Debian does not |

Ubuntu's choice is worth understanding rather than memorising. It ships with
root's password **locked**, so `su -` cannot work at all and `sudo` is the only
route in. Debian asks for a root password during installation and behaves the old
way. Same package, different policy, and a habit built on one distribution will
mislead you on the other.

## Prove it

After granting or changing access, three checks:

```bash
# Did the group membership actually land
id sam

# What is this user allowed to run, according to the rules themselves
sudo -l -U sam

# Is the escalation being recorded
journalctl _COMM=sudo -n 20
```

`sudo -l` is the one people skip. It reports what the sudoers rules permit rather
than what you assume they permit, and the two differ more often than you would
like.

## What trips people up

### 1. Permission denied on your own machine

Owning the hardware grants you nothing. The kernel checks the UID of the process,
and your interactive shell runs as you, not as root.

`id` tells you who you currently are. If the answer is not root and the file
belongs to root, `sudo` is the answer — not `chmod 777`, which "fixes" it by
removing the protection from everybody at once.

### 2. "is not in the sudoers file"

Sometimes followed by `This incident will be reported`, which sounds far more
ominous than it is. It means a log line was written.

The message means you authenticated correctly and are not authorised. Adding the
user to `wheel` or `sudo` is the usual fix — and note **the two group names are
different on different distributions**, which is the most common reason a
correct-looking `usermod` changes nothing.

One catch: **group membership is read at login.** Add yourself to a group and your
current shell will not have it. Log out and back in, or check with `id` and
believe the output rather than the `usermod` that appeared to succeed.

### 3. Files created under sudo belong to root

`sudo touch report.txt` in your own home directory makes a file you cannot then
edit. Nothing is broken; the file's owner is root because the process that made
it was root.

`sudo chown sam:sam report.txt` fixes it. The wider habit is to notice when you
are escalating for a command that did not need it.

### 4. Redirection happens before sudo does

This one is genuinely counter-intuitive:

```
sudo echo "127.0.0.1 test" > /etc/hosts
```

That fails with `Permission denied`, and people conclude sudo is broken. It is
not. **Your shell sets up the redirection before `sudo` ever runs**, so the file
is opened by your unprivileged shell. The `echo` would have run as root, but it
never gets that far.

`sudo tee -a /etc/hosts` is the usual fix, because then the privileged process is
the one doing the writing.

### 5. Being root all the time because it is easier

It is easier, briefly. Then every typo runs with full authority, every script you
try runs with full authority, and nothing in your shell history can be attributed
to a person.

The discipline is not superstition. `sudo` in front of the commands that need it
means the commands that do not need it cannot hurt you, which covers almost all
of them.

## Work it through

A new colleague needs to restart the web service on a Debian machine. You add
them:

```
useradd -m -s /bin/bash jordan
usermod -aG wheel jordan
```

They log in, run `sudo systemctl restart nginx`, and get `jordan is not in the
sudoers file`. Both of your commands succeeded and printed no errors.

Work out what happened before reading on.

**The group is wrong for this distribution.** `wheel` is the RHEL family's admin
group; Debian uses `sudo`. The `usermod` succeeded because Debian does have a
`wheel` group defined — it just is not referenced by any sudoers rule, so
membership of it grants precisely nothing.

**Why no error?** Because nothing was wrong from `usermod`'s point of view. It was
asked to add a user to an existing group and it did. The mismatch is between the
group you chose and the group the rules trust, and no single command is in a
position to notice that.

**How would you have caught it?** `sudo -l -U jordan` asks the rules directly, and
would have reported no permitted commands while `id jordan` looked perfectly
healthy. Checking the grant rather than the group is the habit worth building.

**The fix:** `usermod -aG sudo jordan`, then have them log out and back in, because
group membership is established at login. Then `sudo -l` as jordan to confirm.

And one more thing worth asking: should jordan have full `sudo` at all, when the
job is restarting one service? A sudoers drop-in permitting exactly `systemctl
restart nginx` grants the access the role needs and nothing else. That is the
whole of least privilege, and objective 3.3 asks about it directly.

## Try it

Optional, if you have a machine handy where you already have administrative
access.

1. Run `id`. Name your UID, your primary group, and every supplementary group,
   and say which of those you did not expect.
2. Run `sudo -l`. Read what you are actually permitted to do.
3. Run `whoami`, then `sudo whoami`. Two words, and the difference is the entire
   lesson.
4. Run `su - ` (with the dash) and then `echo $PATH`. Exit, run `su` without the
   dash, and compare. Explain the difference in `/sbin`.
5. Try `sudo echo hello > /root/test.txt` and watch it fail. Then work out which
   part of the line was not running as root.

**Verification step.** You have it when you can explain, without looking, why
`sudo command > file` fails while `sudo tee file` works.

## Check yourself

<details class="qa">
<summary>What single thing makes an account root, and why is that worth knowing as a security check?</summary>

**UID 0.** Not the name, not membership of a group, not a flag in a config file.
The kernel skips permission checks for processes with an effective UID of 0, and
that is the whole mechanism.

As a check: any account with UID 0 has complete authority regardless of what it
is called. A second UID 0 account named something innocuous is a classic
persistence trick precisely because it does not look like anything in a user
listing.

`awk -F: '$3 == 0' /etc/passwd` should return exactly one line.

</details>

<details class="qa">
<summary>`sudo` asks for a password. Whose is it, and what does that let you avoid?</summary>

**Yours.** `sudo` authenticates you as you, then consults its rules to decide
whether you are permitted to act as the target user.

What that avoids is a shared root password. Nobody needs to know it, it never has
to be circulated when someone joins, and it never has to be rotated when someone
leaves — revoking a group membership is the whole of offboarding.

The near-miss answer is "root's password", which is what `su` wants and is
exactly the difference between the two commands. `su` proves you know root's
secret; `sudo` proves you are you and then checks a policy.

</details>

<details class="qa">
<summary>You run `su` to root without the dash, then a command in `/usr/sbin`, and get `command not found`. What happened?</summary>

You kept your own `PATH`. `su` without `-` takes the new identity but does not
run the target user's login profile, so the environment is still the one you
arrived with, and an ordinary user's `PATH` usually has no `/sbin` or
`/usr/sbin`.

The command exists and you have the privilege to run it. The shell simply never
looked in the directory it lives in.

Two fixes: use `su -` or `sudo -i` so you get a login environment, or give the
full path, `/usr/sbin/thecommand`. The first is the habit; the second is the
diagnostic that proves this is what happened.

</details>

<details class="qa">
<summary>`sudo echo "text" > /etc/hosts` fails with permission denied. Explain the order of events.</summary>

**The shell sets up the redirection first, before running anything.** Your shell
is unprivileged, so opening `/etc/hosts` for writing fails immediately and the
command line never proceeds to `sudo`.

`sudo` was going to work fine. It never got the chance.

`echo "text" | sudo tee -a /etc/hosts` is the usual fix: `tee` is the process
doing the writing, and `tee` is the process running under `sudo`. `sudo sh -c
'echo "text" > /etc/hosts'` also works, by putting the redirection inside a shell
that is itself privileged.

</details>

<details class="qa">
<summary>You add a user to the admin group on a Debian server with `usermod -aG wheel sam`, and sudo still refuses. Both commands reported success. Why?</summary>

**Wrong group for the distribution.** Debian and Ubuntu trust the `sudo` group;
`wheel` is the RHEL family's name for the same idea. Debian defines a `wheel`
group, so `usermod` had a real group to add sam to and succeeded — but no sudoers
rule references it, so the membership grants nothing.

Nothing errored because nothing was wrong at the level `usermod` operates on. The
mismatch is between the group you picked and the group the policy trusts.

`sudo -l -U sam` would have shown it: the rules answer directly rather than by
inference. And once fixed, sam still needs to log out and back in, because group
membership is established at login.

</details>

## References

- [id(1)](https://man7.org/linux/man-pages/man1/id.1.html) - Linux man-pages project. Accessed 2026-08-07.
- [su(1)](https://man7.org/linux/man-pages/man1/su.1.html) - Linux man-pages project. Accessed 2026-08-07.
- [passwd(5)](https://man7.org/linux/man-pages/man5/passwd.5.html) - Linux man-pages project. Accessed 2026-08-07.
- [useradd(8)](https://man7.org/linux/man-pages/man8/useradd.8.html) - Linux man-pages project. Accessed 2026-08-07.
- [sudo(8)](https://www.sudo.ws/docs/man/sudo.man/) - Sudo Project. Accessed 2026-08-07.
- [sudoers(5)](https://www.sudo.ws/docs/man/sudoers.man/) - Sudo Project. Accessed 2026-08-07.

Command output was captured on the images pinned in `blog/scripts/distros.json`.
Blocks without a distribution and architecture header are illustrative.
