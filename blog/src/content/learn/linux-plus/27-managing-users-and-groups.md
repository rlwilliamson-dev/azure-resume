---
title: "Managing users and groups"
description: "Creating an account is one command. Doing it so the person can work, the auditor is satisfied, and offboarding is not an archaeology project takes a few more, and one flag that silently destroys group memberships."
deck: "Somebody new starts on Monday"
track: "linux-plus"
level: "working"
order: 280
objectives:
  - "Create a user with a home directory, a shell, and the right groups"
  - "Explain primary versus supplementary groups and where each is stored"
  - "Set password ageing and say what each field controls"
  - "Offboard an account so that no route back in remains"
prerequisites: ["finding-files"]
tags: ["linux", "linux-plus", "users", "groups", "accounts"]
updated: 2026-08-21
draft: false
examObjectives:
  - exam: "xk0-006"
    domain: "2.0"
    objective: "2.2"
sources:
  - title: "useradd(8)"
    url: "https://man7.org/linux/man-pages/man8/useradd.8.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "usermod(8)"
    url: "https://man7.org/linux/man-pages/man8/usermod.8.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "groupadd(8)"
    url: "https://man7.org/linux/man-pages/man8/groupadd.8.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "chage(1)"
    url: "https://man7.org/linux/man-pages/man1/chage.1.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "login.defs(5)"
    url: "https://man7.org/linux/man-pages/man5/login.defs.5.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "gpasswd(1)"
    url: "https://man7.org/linux/man-pages/man1/gpasswd.1.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
symptoms:
  - symptom: "usermod removed a user from groups they were already in"
    anchor: "1-usermod-g-without-the-a"
  - symptom: "New user has no home directory"
    anchor: "2-no-home-directory"
---

> **Before you read.** Creating an account is one command and takes a
> second. Removing one properly is harder, and most organisations get it wrong in
> the same way.
>
> A person leaves. Their password is disabled. Everyone is satisfied.
>
> **Why might that person still be able to log in tomorrow?**

Because a password is only one of the ways in, and disabling it leaves the others
untouched. That gap is the reason this topic is worth more attention than "run
`useradd`" suggests, and the answer arrives near the end of the lesson.

### Some words you will need

<dl class="terms">
<dt>primary group</dt>
<dd>One per user, stored in <code>/etc/passwd</code>. What new files they create are owned by.</dd>
<dt>supplementary group</dt>
<dd>Any number, stored in <code>/etc/group</code>. How access is granted to shared things.</dd>
<dt>user private group</dt>
<dd>The convention of giving each user a primary group of their own name. The default nearly everywhere.</dd>
<dt>skeleton</dt>
<dd><code>/etc/skel</code>. Copied into every new home directory.</dd>
<dt>ageing</dt>
<dd>Rules about how long a password lasts and when the account expires.</dd>
</dl>

## What breaks without this

**People cannot do their work, or can do too much.** Group membership is how
access is granted on a Linux system, and getting it wrong is either a blocked
colleague or an audit finding.

**Offboarding leaves a way in.** The subject of the question above.

**One flag silently removes access nobody notices losing.** `usermod -G` without
`-a`, which appeared in lesson 06 and is worth meeting again because it is the
single most destructive mistake in this area.

## Creating an account

One `useradd` is about to run. The command below then greps `/etc/passwd` for the
new user, greps `/etc/group` for the same name, and lists the home directory.

<details class="predict">
<summary>The command creates a user called <code>jordan</code> and never mentions a group. Why does the <code>/etc/group</code> grep find anything at all, and what will the dates on the home directory's files be?</summary>

```bash
# Debian 13 (trixie), x86_64
$ useradd -m -s /bin/bash -c 'Jordan Ellis' jordan; echo '--- what useradd created ---'; grep jordan /etc/passwd; grep jordan /etc/group; ls -la /home/jordan | head -6
--- what useradd created ---
jordan:x:1000:1000:Jordan Ellis:/home/jordan:/bin/bash
jordan:x:1000:
total 12
drwx------. 2 jordan jordan   57 Aug  8 03:19 .
drwxr-xr-x. 1 root   root     20 Aug  8 03:19 ..
-rw-r--r--. 1 jordan jordan  220 May  9 11:07 .bash_logout
-rw-r--r--. 1 jordan jordan 3526 May  9 11:07 .bashrc
-rw-r--r--. 1 jordan jordan 3526 May  9 11:07 .profile
```

</details>

**The dates are the giveaway on the second question.** The directory is stamped
today; the files inside it are stamped May. They were *copied* from `/etc/skel`
with their timestamps preserved, which is a small thing that tells you exactly
where they came from the first time you notice it.

One command did four things.

**An entry in `/etc/passwd`** with UID 1000, the GECOS field holding the full
name, a home directory, and a shell.

A group called `jordan` with GID 1000. That is the *user private group*
convention: each person gets a primary group of their own, so a file they
create is group-owned by nobody else. Without it, everyone's primary group
would be something shared like `users` and every new file would be readable by
the whole company by default.

A home directory at mode 700, owned by jordan.

The contents of `/etc/skel` copied in: `.bashrc`, `.profile`, `.bash_logout`,
with the dates from the skeleton rather than today. That is where you put
anything every new person should start with.

The flags worth knowing:

| Flag | Does |
| --- | --- |
| `-m` | Create the home directory. **Not always the default.** |
| `-s /bin/bash` | Login shell |
| `-c 'Full Name'` | The GECOS comment field |
| `-G grp1,grp2` | Supplementary groups at creation |
| `-g grp` | Primary group, if not the private one |
| `-u 1234` | A specific UID |
| `-r` | A system account: no home, no ageing, low UID |
| `-e 2026-12-31` | An expiry date, which contractors should always have |

**`-m` is the one that catches people**, because whether it is the default depends
on `CREATE_HOME` in `/etc/login.defs` and differs between distributions. Passing
it explicitly always works.

The account has **no password** at this point and cannot log in until one is set
with `passwd jordan`, or a key is placed in `~/.ssh/authorized_keys`.

<details class="deeper">
<summary>If you already administer Linux: UID ranges, system accounts, and why getent is the right way to ask</summary>

**Why UID 1000 and not 1?** `/etc/login.defs` carries `UID_MIN` and `UID_MAX`
for human accounts, 1000 to 60000 on both families, and
`SYS_UID_MIN`/`SYS_UID_MAX` for the range `useradd -r` allocates from,
typically 201 to 999. Below that, 0 to 200 is reserved for accounts the
distribution itself ships. The split exists so a package installing a service
account can never collide with a person, and so tools can tell the two apart
by number alone.

A system account differs in more than its number. `useradd -r` skips the home
directory, sets no password ageing, and conventionally gets `/sbin/nologin` as
its shell. That last one is the part that matters: `nginx` and `postgres` need
a UID to own files and run as, and explicitly must not be able to log in.

Where the numbers bite is anywhere UIDs cross a boundary. NFS carries the UID
on the wire, not the name, so user 1001 on one host is whoever 1001 is on the
other, which is the entire reason central identity from lesson 38 exists.
Container images have their own `/etc/passwd`, so a `USER 1000` in a
Dockerfile is a different person inside than out, and a bind-mounted volume
shows files owned by whoever holds that number locally. Restoring a backup
onto a rebuilt machine has the same failure if accounts were created in a
different order.

Read accounts with `getent`, not `grep /etc/passwd`.

```
getent passwd jordan
getent group deploy
getent passwd | wc -l
```

`getent` queries the whole NSS stack in the order `/etc/nsswitch.conf` specifies,
so it sees LDAP, SSSD, and Active Directory accounts as well as local ones.
`grep /etc/passwd` sees only the local file, which means a script built on it
quietly reports that a perfectly real user does not exist the moment the machine
joins a domain. It is also the correct way to check a UID is free before assigning
it, and `getent passwd 1000` looks up by number.

The exit status is the useful half: `getent passwd jordan >/dev/null` returns 0 if
the account exists anywhere and 2 if it does not, which is the idiom for "create
this user if it is missing" in a script that has to be idempotent.

</details>

## Groups

```bash
# Debian 13 (trixie), x86_64
$ useradd -m jordan >/dev/null 2>&1; groupadd deploy; groupadd webdev; usermod -aG deploy,webdev jordan; echo '--- what jordan is now ---'; id jordan; echo '--- and from the group file ---'; grep -E '^(deploy|webdev)' /etc/group
--- what jordan is now ---
uid=1000(jordan) gid=1000(jordan) groups=1000(jordan),1001(deploy),1002(webdev)
--- and from the group file ---
deploy:x:1001:jordan
webdev:x:1002:jordan
```

<figure class="learn-figure">
<svg viewBox="0 0 720 200" role="img" aria-labelledby="gr-t gr-d" style="width:100%;height:auto;">
<title id="gr-t">Where a user's primary group is recorded, against the supplementary ones</title>
<desc id="gr-d">A user's primary group is a numeric field in their own line in /etc/passwd, so nothing in /etc/group names them. Supplementary groups work the other way round: the group's line in /etc/group lists its members. That split is why id has to read both files to answer the question, and why grepping /etc/group for a username never shows the private group and can make a correctly configured account look wrong.</desc>
<g>
<rect x="30" y="52" width="290" height="80" rx="5" fill="var(--accent)" fill-opacity="0.12" stroke="var(--accent)" stroke-opacity="0.9" stroke-width="1.8"/>
<text x="175" y="78" text-anchor="middle" font-size="11.5" fill="var(--accent)">/etc/passwd</text>
<text x="175" y="98" text-anchor="middle" font-size="10" fill="currentColor" fill-opacity="0.75">jordan's own line holds gid 1000</text>
<text x="175" y="116" text-anchor="middle" font-size="10" fill="var(--accent)">the primary group, and only here</text>
<rect x="400" y="52" width="290" height="80" rx="5" fill="currentColor" fill-opacity="0.07" stroke="currentColor" stroke-opacity="0.32"/>
<text x="545" y="78" text-anchor="middle" font-size="11.5" fill="currentColor">/etc/group</text>
<text x="545" y="98" text-anchor="middle" font-size="10" fill="currentColor" fill-opacity="0.75">deploy:x:1001:jordan</text>
<text x="545" y="116" text-anchor="middle" font-size="10" fill="currentColor" fill-opacity="0.65">supplementary, listed by the group</text>
<text x="360" y="166" text-anchor="middle" font-size="11" fill="currentColor">id reads both</text>
<text x="30" y="188" font-size="10" fill="currentColor" fill-opacity="0.65">grep jordan /etc/group never shows the primary group, because it is not written there</text>
</g>
<g stroke="currentColor" stroke-opacity="0.5" fill="none" stroke-width="1.3">
<path d="M175 136 L175 152 L300 152"/>
<path d="M545 136 L545 152 L420 152"/>
</g>
</svg>
<figcaption>Two files, recording the relationship from opposite ends. That is the whole reason <code>id</code> exists as a separate command: neither file answers the question on its own, and grepping only the group file makes a perfectly good account look like it is missing its main group.</figcaption>
</figure>

**The primary group is in `/etc/passwd`; supplementary groups are in
`/etc/group`.** That is why `id` has to read both, and why `grep jordan
/etc/group` does not show the private group's membership. A user is not listed
as a member of their own primary group, because the passwd entry already says
so.

| Command | Does |
| --- | --- |
| `groupadd name` | Create a group |
| `groupdel name` | Delete one |
| `groupmod -n new old` | Rename a group, or change its number with `-g` |
| `usermod -aG grp user` | **Add** to a supplementary group |
| `gpasswd -d user grp` | Remove from one |
| `usermod -g grp user` | Change the primary group |
| `id user` | What they are in now |
| `getent group name` | Members, including from LDAP |

<details class="predict">
<summary>Jordan is in <code>deploy</code> and <code>webdev</code>. Somebody runs <code>usermod -G sudo jordan</code>, meaning to add sudo access. What does <code>id jordan</code> report afterwards?</summary>

```bash
# Debian 13 (trixie), x86_64
$ id sam; usermod -G sudo sam; echo "--- after usermod -G sudo sam ---"; id sam
uid=1000(sam) gid=1000(sam) groups=1000(sam),4(adm),1001(deploy),1002(webdev)
--- after usermod -G sudo sam ---
uid=1000(sam) gid=1000(sam) groups=1000(sam),27(sudo)
```

(Captured with a user called sam in three groups, which is the same situation.)

**Every other supplementary group is gone.** `-G` sets the complete list;
`-a` means append to it. Without `-a`, "set the groups to sudo" is exactly what
was asked for and exactly what happened.

The primary group survives, because it lives in a different field of
`/etc/passwd` that `-G` does not touch.

**The damage is silent.** No error, no output, no warning. The person can
still log in and still owns all their files, and discovers the loss the next
time they touch something that needed `deploy`, which might be days later, and
will not obviously connect to a change made to their sudo access.

**Always `-aG`**, and **run `id` afterwards** to confirm you appended rather than
replaced. That second habit is what turns a silent failure into a visible one,
and it costs one command.

</details>

## Password ageing

```bash
# Debian 13 (trixie), x86_64
$ useradd -m jordan >/dev/null 2>&1; echo 'jordan:notarealpassword' | chpasswd; echo '--- ageing before ---'; chage -l jordan | head -5; chage -M 90 -W 14 -I 7 jordan; echo '--- after setting a 90 day maximum ---'; chage -l jordan | tail -4
--- ageing before ---
Last password change					: Aug 08, 2026
Password expires					: never
Password inactive					: never
Account expires						: never
Minimum number of days between password change		: 0
--- after setting a 90 day maximum ---
Account expires						: never
Minimum number of days between password change		: 0
Maximum number of days between password change		: 90
Number of days of warning before password expires	: 14
```

**`chage -l` is far more readable than `/etc/shadow`** and shows every ageing
field at once.

| Flag | Sets |
| --- | --- |
| `-M 90` | Password must change every 90 days |
| `-m 1` | Cannot change it again for 1 day |
| `-W 14` | Warn for 14 days beforehand |
| `-I 7` | Account inactive 7 days after the password expires |
| `-E 2026-12-31` | Account expires on this date |
| `-d 0` | Force a change at next login |

`chage -d 0` is the one to use after issuing a temporary password, so the
person must set their own immediately and you never know it.

`-E` versus `-M` is a distinction worth being precise about. `-M` expires the
*password*, and the person changes it and carries on. `-E` expires the
*account*, and they cannot log in at all, including with an SSH key. That
difference is the answer to the question this lesson opened with.

`/etc/login.defs` holds the defaults applied to new accounts (`PASS_MAX_DAYS`,
`PASS_WARN_AGE`, `UID_MIN`, `HOME_MODE`) and setting them there is better than
remembering flags per account.

<details class="deeper">
<summary>If you already administer Linux: UID ranges, and why they matter more than they look</summary>

`/etc/login.defs` defines `UID_MIN` and `UID_MAX` for humans, typically 1000 to
60000, and `SYS_UID_MIN`/`SYS_UID_MAX` for system accounts, typically 201 to 999.
`useradd -r` allocates from the system range.

**Why the split matters operationally:** most "list the real users" checks are
`awk -F: '$3 >= 1000' /etc/passwd`, and an account created with an explicit low
UID does not appear. So does every audit built on the same assumption.

**UID consistency across machines is the one that causes real pain.** NFS
authorises by numeric UID, so jordan being 1001 on one server and 1004 on another
means files created on one are owned by somebody else on the other. The symptom is
`Permission denied` on a file `ls -l` says you own, and it is not a permissions
problem at all.

Three ways to avoid it: allocate UIDs centrally with a directory service, pass
`-u` explicitly from a source of truth, or accept it and use NFSv4 with `idmapd`.
Doing none of these and hoping is the common fourth option.

**Deleting a user does not reclaim their files.** `userdel jordan` without `-r`
leaves everything they owned with a bare numeric UID where the name was, and the
next user created gets that UID and silently inherits ownership of all of it.
`find / -uid 1001` before deleting, and `userdel -r` when you are sure.

**Reserved UIDs:** 0 is root, and `nobody` is 65534 on most systems. An account
with UID 0 that is not called root has full privileges and looks unremarkable in a
listing, which is why `awk -F: '$3 == 0' /etc/passwd` should return exactly one
line.

</details>

<details class="deeper">
<summary>If you already administer Linux: /etc/skel, and shaping the account before it exists</summary>

Everything in `/etc/skel` is copied into a new home directory at creation, with
its permissions preserved. It is the cheapest configuration management there is
for anything per-user.

Worth putting there: a `.bashrc` with your house aliases and a sane prompt, a
`.vimrc`, a `.ssh` directory at mode 700 so nobody has to create it correctly, and
a README pointing at internal documentation.

**It only applies at creation.** Changing `/etc/skel` does nothing for
accounts that already exist, which is a limitation and also a safety property.
It cannot overwrite somebody's customisations.

**`useradd -k /path/to/other-skel`** uses a different skeleton, which is how you
give service accounts and humans different starting points from one command.

`/etc/login.defs` shapes the rest: `HOME_MODE` (0700 on current releases, 0755
on older ones, worth checking, because it decides whether colleagues can read
each other's home directories by default), `CREATE_HOME`, `UMASK`, and the
ageing defaults.

`adduser` on the Debian family is a different program, a Perl wrapper with
interactive prompts and better defaults, configured by `/etc/adduser.conf`. It
is not `useradd` and a runbook written for one fails on the other. `useradd`
exists on both, which makes it the portable choice for scripts.

For anything at scale, none of this belongs in a runbook. `newusers` reads a
batch file in passwd format; configuration management does it properly and
idempotently; a directory service does it centrally. Hand-running `useradd` on
forty machines is how UIDs diverge.

</details>

## Offboarding

Here is the answer to the opening question, and it is the part of this topic worth
most.

**Disabling a password does not disable an account.** `passwd -l jordan` puts
a `!` in front of the password hash so no password can match, and SSH **key**
authentication never consults the password at all. Somebody with a key in
`~/.ssh/authorized_keys` walks straight in.

The sequence that actually closes an account:

```bash
# 1. Expire the account. This stops key logins too.
sudo chage -E 0 jordan

# 2. Lock the password as well
sudo usermod -L jordan

# 3. Remove the way in that nobody checks
sudo rm -f /home/jordan/.ssh/authorized_keys

# 4. Take away the group memberships
sudo gpasswd -d jordan deploy
sudo gpasswd -d jordan sudo

# 5. End any session they still have open
sudo pkill -u jordan

# 6. Find out what they own before deciding what to do with it
sudo find / -user jordan -not -path '/proc/*' 2>/dev/null | head -50

# 7. Only then, and only when the files are dealt with
sudo userdel -r jordan
```

**Steps 1 and 3 are the ones people miss**, and either one alone leaves a route
in. Step 6 matters because `userdel -r` deletes the home directory and leaves
everything *outside* it owned by a numeric UID that the next account created will
inherit.

**Do not delete immediately.** Disable, then delete once you are sure nothing of
theirs is needed. An account that is expired and locked cannot be used and can be
reversed; a deleted one cannot.

## Across distributions

| | RHEL family | Debian family |
| --- | --- | --- |
| Low-level tool | `useradd` | `useradd` |
| Friendly wrapper | none | `adduser`, `deluser` |
| Admin group | `wheel` | `sudo` |
| Defaults | `/etc/login.defs`, `/etc/default/useradd` | plus `/etc/adduser.conf` |
| `HOME_MODE` on current releases | `0700` | `0700` |

**Use `useradd` in anything written down.** `adduser` is more pleasant
interactively and does not exist on the RHEL family, so a script using it is not
portable.

## Prove it

After creating or changing an account:

```bash
# Did the groups land the way you meant
id jordan

# What does the passwd entry actually say
getent passwd jordan

# Ageing and expiry
sudo chage -l jordan

# Can they get in at all, and by what route
sudo grep '^jordan' /etc/shadow | cut -c1-30
ls -l /home/jordan/.ssh/authorized_keys 2>/dev/null
```

**`getent` rather than `grep /etc/passwd`**, because it goes through NSS and so
also answers for LDAP and SSSD. On a domain-joined machine `grep` returns nothing
for a user who plainly exists, and that discrepancy is diagnostic rather than
confusing once you know why.

## What trips people up

### 1. `usermod -G` without the `-a`

Replaces every supplementary group instead of adding one. Silent, and discovered
days later.

`usermod -aG`, then `id` to confirm.

### 2. No home directory

`useradd` does not always create one; it depends on `CREATE_HOME` in
`/etc/login.defs`. The user logs in and lands in `/` with no dotfiles and a shell
that complains.

Pass `-m` explicitly, always.

### 3. Group membership not taking effect

Supplementary groups are read at **login**. Adding somebody to a group does not
change any session they already have open, including yours.

`id` shows the truth; the running shell does not. Log out and back in, or start a
new session with `newgrp`.

### 4. Deleting a user and orphaning their files

`userdel` removes the account. Files outside the home directory keep the numeric
UID, and the next account created gets that UID and inherits them.

`find / -user name` before deleting. `userdel -r` for the home directory, and deal
with the rest deliberately.

### 5. Locking the password and calling it done

Covered above. `passwd -l` does nothing about SSH keys. `chage -E 0` is the one
that closes the account.

## Work it through

A contractor finishes on Friday. On Monday, the security team asks you to confirm
they no longer have access. You run:

```
$ sudo passwd -l contractor
$ sudo chage -l contractor | grep -i 'account expires'
Account expires						: never
```

Reason it out before reading on.

**The password is locked and the account is not expired.** So the question is
whether any route in remains that does not involve a password.

Route one: SSH keys. `ls -l /home/contractor/.ssh/authorized_keys`. If it
exists and is non-empty, the contractor can still log in today, because public
key authentication never consults `/etc/shadow`. This is the big one and it is
why the answer to the security team is currently "no".

Route two: an active session. `who` and `ps -u contractor`. A shell opened on
Thursday is unaffected by anything done on Monday, and a long-running `tmux`
session can survive for months.

Route three: sudo through a group. If they are still in `wheel` or `sudo`, and
any route in exists, they are still an administrator. `id contractor`.

Route four: shared credentials. Service account passwords, application logins,
API tokens, and anything in a shared password manager. These are outside the
scope of `useradd` entirely and are usually the ones that are actually still
live.

Route five: their key on other machines. If keys were distributed by
configuration management, removing one `authorized_keys` file fixes one
server.

So the honest answer to the security team is "not yet", and the fix is the
sequence from the offboarding section (expire the account, remove the keys,
drop the groups, kill the sessions) applied everywhere the account exists.

Now the point worth extracting. **`passwd -l` is a control on one authentication
method, and it is the method the person is least likely to be using.** Keys, open
sessions, and group-derived privilege are three separate doors, and locking a
password closes none of them.

The habit: **write the offboarding sequence down, and make expiry rather than
password locking the first step.** `chage -E 0` is one command and it is the only
one in that list that stops a key login. Everything else is cleanup.

## Try it

Optional, on a machine you can break.

1. `sudo useradd -m -s /bin/bash -c 'Test User' testy`, then `getent passwd testy`
   and read all seven fields.
2. `ls -la /home/testy` and compare with `ls -la /etc/skel`.
3. `sudo groupadd project1`, `sudo usermod -aG project1 testy`, `id testy`.
4. Now the mistake, deliberately: `sudo usermod -G project1 testy` and run `id`
   again. Note what disappeared.
5. `sudo chage -l testy`, then `sudo chage -M 90 -W 7 testy`, then `chage -l`
   again.
6. `sudo chage -E 0 testy` and read the expiry line.
7. `sudo userdel -r testy` when you are done.

**Verification step.** You have it when you can list, from memory, every route
into an account that locking the password leaves open.

## Check yourself

<details class="qa">
<summary>What is the difference between a primary and a supplementary group, and where is each stored?</summary>

**The primary group is one per user, stored in the fourth field of
`/etc/passwd`** as a GID. It is what files the user creates are group-owned by.

**Supplementary groups are any number, stored in `/etc/group`** as a membership
list on each group's line. They are how access to shared resources is granted.

`id` reads both, which is why it is the tool to trust: `gid=` is the primary,
`groups=` is everything.

One detail that confuses people: a user does **not** appear in their own private
group's member list in `/etc/group`, because the passwd entry already establishes
it. So `grep jordan /etc/group` can look incomplete while `id jordan` is correct.

</details>

<details class="qa">
<summary>Why is <code>usermod -aG</code> different from <code>usermod -G</code>, and how do you catch the mistake?</summary>

**`-G` sets the complete list of supplementary groups. `-a` means append to it.**

Without `-a`, every group not named on the command line is removed. The primary
group survives, because it lives in `/etc/passwd` rather than `/etc/group`.

It is silent (no error, no output) and the person keeps working normally until
they touch something that needed one of the lost groups, which may be days
later and will not obviously connect to the change.

**Catch it by running `id` immediately afterwards** and confirming the list grew
rather than shrank. That single habit turns a silent failure into a visible one.

</details>

<details class="qa">
<summary>Which <code>chage</code> option would you use to force a password change at next login, and which to stop an account being used at all?</summary>

`chage -d 0 user` sets the last-change date to the epoch, so the password is
immediately considered expired and must be changed at next login. This is what
to run after issuing a temporary password, so you never know the one they end
up with.

`chage -E 0 user` expires the *account*, which prevents login entirely,
including with an SSH key.

That second one is the important distinction. `-M` and `-d` are about the
*password*, and a person with a key never touches their password. `-E` is about
the account, and it is the only one of the three that closes a key-based route in.

`chage -l user` shows every field, and is far more readable than `/etc/shadow`.

</details>

<details class="qa">
<summary>You lock a departing employee's password. Give three ways they might still have access.</summary>

**An SSH key in `~/.ssh/authorized_keys`.** Public key authentication never
consults the password, so locking it changes nothing for anyone using a key,
which is most people with server access.

**An open session.** A shell or `tmux` started before the change is unaffected and
can persist for months.

Group-derived privilege on another machine. If the account exists on several
servers, or keys were distributed by configuration management, locking one
password addresses one server.

Others worth naming: shared service-account credentials, application logins
outside the operating system, and API tokens.

The fix is `chage -E 0` to expire the account, removing `authorized_keys`,
dropping group memberships, and `pkill -u` for live sessions, on every machine
the account exists on.

</details>

<details class="qa">
<summary>Why should you run <code>find / -user jordan</code> before <code>userdel jordan</code>?</summary>

**Because `userdel` removes the account and not the files.** Anything jordan owned
outside their home directory keeps its numeric UID, and `ls -l` then shows a bare
number where the name was.

The real problem is what happens next: **UIDs are reused.** The next account
created takes the freed UID and silently inherits ownership of every one of
those orphaned files, which may include things nobody intended them to have.

`find / -user jordan -not -path '/proc/*'` lists them while the name still
resolves, which is the only convenient time to do it.

Then decide deliberately: `chown` them to a successor, archive them, or delete
them. `userdel -r` handles the home directory and nothing else.

</details>

## References

- [useradd(8)](https://man7.org/linux/man-pages/man8/useradd.8.html) - Linux man-pages project. Accessed 2026-08-07.
- [usermod(8)](https://man7.org/linux/man-pages/man8/usermod.8.html) - Linux man-pages project. Accessed 2026-08-07.
- [groupadd(8)](https://man7.org/linux/man-pages/man8/groupadd.8.html) - Linux man-pages project. Accessed 2026-08-07.
- [chage(1)](https://man7.org/linux/man-pages/man1/chage.1.html) - Linux man-pages project. Accessed 2026-08-07.
- [login.defs(5)](https://man7.org/linux/man-pages/man5/login.defs.5.html) - Linux man-pages project. Accessed 2026-08-07.
- [gpasswd(1)](https://man7.org/linux/man-pages/man1/gpasswd.1.html) - Linux man-pages project. Accessed 2026-08-07.

Every block above with a distribution and architecture header was captured by running the command on a Debian 13 (trixie) container. Blocks without one are illustrative.
