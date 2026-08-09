---
title: "Where any of this is actually stored"
description: "Four text files hold every account on the machine. What each field means, how a password is stored so that reading the file does not help, and the difference between an account that is locked and one that is closed."
track: "linux-plus"
level: "working"
order: 290
objectives:
  - "Read every field of the four account files and say what it controls"
  - "Explain how a password hash is stored and why the salt is visible"
  - "Distinguish locked, expired, nologin, and deleted"
  - "Find out who is logged in now and who was logged in earlier"
prerequisites: ["managing-users-and-groups"]
tags: ["linux", "linux-plus", "accounts", "shadow", "security"]
updated: 2026-08-07
draft: false
examObjectives:
  - exam: "xk0-006"
    domain: "2.0"
    objective: "2.2"
sources:
  - title: "passwd(5)"
    url: "https://man7.org/linux/man-pages/man5/passwd.5.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "shadow(5)"
    url: "https://man7.org/linux/man-pages/man5/shadow.5.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "group(5)"
    url: "https://man7.org/linux/man-pages/man5/group.5.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "crypt(5)"
    url: "https://manpages.debian.org/stable/libcrypt-dev/crypt.5.en.html"
    publisher: "Debian Project"
    accessed: 2026-08-07
    tier: 1
  - title: "nsswitch.conf(5)"
    url: "https://man7.org/linux/man-pages/man5/nsswitch.conf.5.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "pwck(8)"
    url: "https://man7.org/linux/man-pages/man8/pwck.8.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
symptoms:
  - symptom: "An account is locked and the person can still log in"
    anchor: "1-locked-is-not-closed"
  - symptom: "ls -l shows a number instead of a username"
    anchor: "4-a-number-where-a-name-should-be"
---

> **Before you read.** There is no user database on a Linux machine. No service to
> query, no binary format, nothing to corrupt in an interesting way.
>
> There are four text files, and you can read three of them right now without any
> privilege at all.
>
> **If `/etc/passwd` is world-readable, why is that not a catastrophe?**

Because the passwords are not in it, and have not been since the early
nineties. The fourth file is where they went, and the arrangement (one file
everyone can read, one file only root can) is a small, elegant piece of design
worth understanding rather than memorising.

### Some words you will need

<dl class="terms">
<dt>hash</dt>
<dd>A one-way function. You can check a guess against it; you cannot reverse it.</dd>
<dt>salt</dt>
<dd>Random data mixed into each hash so identical passwords produce different results.</dd>
<dt>locked</dt>
<dd>The password cannot match anything. Other login methods still work.</dd>
<dt>expired</dt>
<dd>The account itself is closed. Nothing works.</dd>
<dt>NSS</dt>
<dd>Name Service Switch: the layer that decides whether "user jordan" is answered from a file, LDAP, or elsewhere.</dd>
</dl>

## What breaks without this

**You cannot answer "does this person still have access".** Which is the question
that actually gets asked, and it needs all four files plus the login records.

**A malformed line locks everyone out.** These are text files parsed on every
login, and one bad entry can break authentication for the whole machine.

**You misread an audit.** Locked, expired, `nologin`, and no-password-set look
similar and mean four different things.

## /etc/passwd, world-readable on purpose

```
jordan:x:1000:1000:Jordan Ellis:/home/jordan:/bin/bash
```

| # | Field | Here | Means |
| --- | --- | --- | --- |
| 1 | Name | `jordan` | Login name |
| 2 | Password | `x` | **A marker.** The hash is in `/etc/shadow`. |
| 3 | UID | `1000` | What the kernel actually uses |
| 4 | GID | `1000` | Primary group |
| 5 | GECOS | `Jordan Ellis` | Full name and other free text |
| 6 | Home | `/home/jordan` | Where they start, and what `~` means |
| 7 | Shell | `/bin/bash` | What runs at login |

**It has to be world-readable.** Every `ls -l` turns a UID into a name, every
`ps` shows an owner, and every program that displays a username reads this file.
Restricting it would break all of that.

Which is exactly why the password cannot be in it. In early Unix it was, field
two held the hash, and world-readable hashes meant anyone could take the file
away and attack it offline at their leisure. **Shadow passwords split the file
in two**: the parts everything needs stay readable, and the secret moves
somewhere only root can go.

**Field seven decides whether the account is for a person.**
`/usr/sbin/nologin` gives an account that owns files and runs services and cannot
be logged into interactively. Most entries in `/etc/passwd` are that.

<details class="deeper">
<summary>If you already administer Linux: the four states an account can be in, and why only two of them stop SSH</summary>

"Disabled" is not a thing `/etc/passwd` and `/etc/shadow` record. There are
four separate mechanisms, they compose, and they stop different things, which
is why an account somebody swears they disabled is still logging in.

| Mechanism | Set with | Stops password login | Stops SSH keys | Stops `su` from root |
| --- | --- | --- | --- | --- |
| Password locked | `passwd -l`, `usermod -L` | Yes | **No** | No |
| Shell is `nologin` | `usermod -s /usr/sbin/nologin` | Yes | Interactive only | Yes |
| Account expired | `chage -E 0` | Yes | **Yes** | Yes |
| Password expired | `chage -d 0` | Forces a change | No | No |

**The row that catches people is the first.** `passwd -l` prefixes the hash
with `!` so no password can match, and SSH public key authentication never
consults the hash at all. An account locked this way and holding a key in
`authorized_keys` logs in exactly as before. Offboarding that stops at `passwd
-l` has not removed access.

`chage -E` is the one that actually closes the account, because the expiry is
checked by `pam_unix`'s account phase rather than its auth phase, so it
applies regardless of *how* the user authenticated. That is the offboarding
command.

`nologin` is about interactive sessions, not authentication. The account can
still authenticate; there is simply no shell to give it. It does not stop `ssh
host command`, SFTP, or port forwarding, all of which are reasons a "disabled"
service account can still be doing useful work for an attacker. `sshd_config`
needs `AllowUsers`, `DenyUsers`, or a `Match` block to close those.

Two markers worth being able to tell apart in field two: `!` or `!!` means
locked, and a bare `*` means the account has never had a usable password and
is not meant to. Almost every system account shows `*`. An empty field two is
the dangerous one (it means no password is required at all) and `pwck` flags
it.

</details>

## /etc/shadow, and what a hash looks like

A password is set, then the account is locked with `passwd -l`, then expired with
`chage -E 0`. The shadow entry is printed after each step.

<details class="predict">
<summary>Locking an account has to be reversible, so it cannot discard the hash. What one-character change would you expect `passwd -l` to make, and what date does `chage -E 0` produce?</summary>

```bash
# Debian 13 (trixie), x86_64
$ useradd -m jordan >/dev/null 2>&1; echo 'jordan:notarealpassword' | chpasswd; echo '--- the shadow entry ---'; grep '^jordan' /etc/shadow; echo '--- now lock it ---'; passwd -l jordan >/dev/null 2>&1; grep '^jordan' /etc/shadow | cut -c1-40; echo '--- and expire the account outright ---'; chage -E 0 jordan; chage -l jordan | grep -i 'account expires'
--- the shadow entry ---
jordan:$y$j9T$kPrG5D21P2aNr55UsgWQV0$UHM9LbkJSEDLgXk3T3.OtP5u9AFTdeT4vnZ9bL97JgD:20673:0:99999:7:::
--- now lock it ---
jordan:!$y$j9T$kPrG5D21P2aNr55UsgWQV0$UH
--- and expire the account outright ---
Account expires						: Jan 01, 1970
```

</details>

**An exclamation mark, prepended.** The hash is untouched underneath it, which
is what makes `passwd -u` an exact reversal. It also means the lock works by
making the stored string impossible for the hashing function to ever produce,
no input hashes to something starting with `!`, rather than by any explicit
"locked" flag.

**And `Jan 01, 1970` is not an error.** Field 8 is a count of days since the epoch,
so `-E 0` means day zero, which prints as the epoch itself. Any date in the past
expires the account; zero is just the bluntest way to write one.

Nine colon-separated fields. The first two carry nearly all the meaning:

| # | Here | Means |
| --- | --- | --- |
| 1 | `jordan` | Login name |
| 2 | `$y$j9T$...` | The hash. Dissected below. |
| 3 | `20673` | Password last changed, in days since 1 Jan 1970 |
| 4 | `0` | Minimum days before it can be changed again |
| 5 | `99999` | Maximum days before it must be |
| 6 | `7` | Days of warning |
| 7 | *(empty)* | Days of inactivity allowed after expiry |
| 8 | *(empty)* | Account expiry date, in days since the epoch |
| 9 | *(empty)* | Reserved |

**`chage -l` prints all of that as readable dates** and is what to use. Field
3 being a day count is why `chage -E 0` displays as `Jan 01, 1970`, day zero.

### Reading the hash

`$y$j9T$kPrG5D21P2aNr55UsgWQV0$UHM9Lbk...` is three `$`-separated parts:

- **`y`**, the algorithm. `y` is yescrypt, the current default on Debian and
  Fedora. `6` is SHA-512, still the default on the RHEL family. `1` is MD5 and
  is a finding.
- **`j9T$kPrG5D21P2aNr55UsgWQV0`**, parameters and the **salt**.
- **`UHM9Lbk...`**, the hash itself.

**The salt is stored in plain sight and that is correct.** Its job is not to be
secret; it is to be *different* for every account, so that two people with the
same password get different hashes, and so an attacker cannot precompute one table
that works against everybody. Without a salt, identical hashes in the file would
reveal identical passwords at a glance.

Verification never reverses anything: the system takes the password offered, mixes
in the stored salt, runs the same function, and compares.

**Locking prepends a `!`.** Look at the second capture: the hash is intact and
now begins `!$y$...`. No password can ever produce a string starting with `!`,
so nothing matches, and unlocking is simply removing the character, which is
why `passwd -u` restores the original password rather than clearing it.

`*` in the field means "no password login was ever possible", which is what
service accounts have. An **empty** field means no password is required at all,
which is a serious finding and worth checking for:
`sudo awk -F: '$2 == "" {print $1}' /etc/shadow`.

<details class="predict">
<summary>An auditor asks you to confirm a departing colleague cannot log in. `/etc/shadow` shows their entry beginning `!$y$...`. Is that sufficient?</summary>

**No.** The `!` locks the *password*, and a locked password is only one of the
ways in.

**SSH public key authentication never consults `/etc/shadow`.** If there is a key
in `~/.ssh/authorized_keys`, the person logs in exactly as before, and nothing
about the shadow file changes that.

The capture above shows what does close it. `chage -E 0` sets field 8, the
account expiry, and `chage -l` reports `Account expires: Jan 01, 1970`, a date
in the past, so the account is expired, and **expiry is enforced regardless of
authentication method.**

Four states worth being able to tell apart, because they look similar and are not:

| State | Set by | Password login | Key login |
| --- | --- | --- | --- |
| Normal |, | Yes | Yes |
| **Locked** | `passwd -l`, `!` prefix | No | **Yes** |
| **Expired** | `chage -E 0` | No | **No** |
| `nologin` shell | `usermod -s` | Connects, then exits | Connects, then exits |

The `nologin` row is worth a note: the login succeeds and the shell immediately
prints a message and exits, so it blocks an interactive session and does **not**
reliably block port forwarding or `scp` on every configuration.

So the answer to the auditor is: expire the account, remove the keys, and then
confirm. Locking alone is the most common incomplete offboarding there is.

</details>

## /etc/group and /etc/gshadow

```
deploy:x:1001:jordan,alex
```

Name, a password marker, GID, and a comma-separated member list. Those members
are the **supplementary** members, somebody whose *primary* group this is does
not appear here, because `/etc/passwd` already says so. That asymmetry is why
`id` is the reliable answer and `grep` is not.

`/etc/gshadow` holds group passwords and administrator lists. Group passwords are
a rarely-used feature that lets someone `newgrp` into a group they are not a
member of, and they are generally considered a bad idea.

<details class="deeper">
<summary>If you already administer Linux: validating the files, and why you never edit them directly</summary>

These four files are parsed on every authentication. A malformed line does not
produce a helpful error. It can break login for **every** account, on a
machine where fixing it requires logging in.

**`vipw` and `vigr`** are the supported way to edit them by hand. They take
the correct lock, so a concurrent `useradd` cannot corrupt your edit, and
validate the syntax on exit, refusing to save something broken. `vipw -s` and
`vigr -s` edit the shadow variants.

**`pwck` and `grpck`** verify the files independently: field counts, valid shells,
home directories that exist, duplicate names or UIDs, and entries in `/etc/shadow`
with no matching `/etc/passwd` line. Worth running after any bulk change or
restore, and it is quick.

```
sudo pwck -r        # read-only, report problems
sudo grpck -r
```

Keep a way back in. Before editing by hand on a remote machine, open a second
session and leave it logged in. A root shell that is already authenticated
survives a broken passwd file; a new login does not.

`getent` rather than `grep`. `getent passwd jordan` goes through NSS and so
answers for LDAP, SSSD, and anything else in `/etc/nsswitch.conf`. On a
domain-joined machine `grep /etc/passwd` returns nothing for a user who
plainly exists, and that discrepancy is itself the diagnosis, because it tells
you the account is not local. `getent passwd` with no argument lists
everything NSS can enumerate, which on a large directory may be nothing at all
by design.

</details>

## Who is here, and who was

| Command | Answers |
| --- | --- |
| `who` | Who is logged in now, and on what terminal |
| `w` | The same, plus what each is running and system load |
| `id` | Who you are, or who somebody else is |
| `last` | Login history, from `/var/log/wtmp` |
| `lastb` | **Failed** login attempts, from `/var/log/btmp` |
| `lastlog` | The last login time for every account |

**`w` is the one to run first on a machine behaving oddly.** It gives you
logged-in users, their idle time, what they are running, and the load average
in one screen, which frequently answers "why is this slow" before you have
asked anything else.

`lastb` is the security one and needs root. A large number of failed attempts
for one account, or attempts for accounts that do not exist, is a brute-force
attempt in progress and is visible nowhere else.

**`lastlog`** finds accounts that exist and have never been used, which is the
list an auditor asks for and which is usually longer than anyone expects.

These read binary logs (`wtmp`, `btmp`, `lastlog`) rather than text, which is
why you need the commands rather than `cat`. On a systemd machine `journalctl
_COMM=sshd` covers similar ground with more detail and honest timestamps.

<details class="deeper">
<summary>If you already administer Linux: hashing algorithms, and what a modern finding looks like</summary>

**The prefix names the algorithm**, and it is the fastest audit you can run on a
shadow file:

| Prefix | Algorithm | Verdict |
| --- | --- | --- |
| `$1$` | MD5 | A finding. Fast to attack. |
| `$2b$` | bcrypt | Acceptable, widely used |
| `$5$` | SHA-256 | Acceptable |
| `$6$` | SHA-512 | The RHEL-family default |
| `$y$` | yescrypt | Current Debian and Fedora default. Memory-hard. |

```
sudo awk -F: '{print $2}' /etc/shadow | cut -d'$' -f2 | sort | uniq -c
```

A machine with `$1$` entries has accounts whose passwords were set a very long
time ago and never changed, because the algorithm is chosen at the moment a
password is set. **Changing the system default does not rehash existing
passwords**. Nothing can, because the plaintext is gone. Only the user
changing their password produces a new hash in the new format, which is a
genuine argument for a one-off forced rotation after upgrading the default.

**Why yescrypt and bcrypt are better is worth knowing rather than accepting.**
SHA-512 is fast, and fast is bad here: an attacker with the file and a GPU can
try billions of guesses per second. yescrypt and bcrypt are deliberately slow
and, more importantly, **memory-hard**. They need a large working set, which
GPUs and custom hardware are poor at supplying in parallel. The cost is a few
milliseconds per legitimate login and several orders of magnitude for an
attacker.

`/etc/login.defs` sets `ENCRYPT_METHOD`, and on current systems the real
configuration is in the PAM stack: `pam_unix.so yescrypt` in
`/etc/pam.d/common-password` or `password-auth`.

**The threat model this defends against is offline attack**: somebody who has
obtained the file, from a backup, a snapshot, or a compromised host. Against
online guessing, rate limiting and `fail2ban` matter far more than the algorithm.

</details>

## Across distributions

| | RHEL family | Debian family |
| --- | --- | --- |
| Default hash | SHA-512, `$6$` | yescrypt, `$y$` |
| Set by | `/etc/login.defs`, PAM | PAM `common-password` |
| Auth log | `/var/log/secure` | `/var/log/auth.log` |
| Admin group | `wheel` | `sudo` |
| `HOME_MODE` | `0700` | `0700` |

The file formats are identical, which is why an `/etc/passwd` line can be moved
between distributions. The hash format cannot be assumed portable in the other
direction: a `$y$` hash needs a libcrypt that supports yescrypt, and an older RHEL
release will not authenticate against it.

## Prove it

To answer "can this person get in":

```bash
# Does the account exist, and via which source
getent passwd jordan

# Is the password usable
sudo grep '^jordan:' /etc/shadow | cut -c1-30

# Is the account expired
sudo chage -l jordan

# Is there a key, which is the route people forget
sudo ls -l /home/jordan/.ssh/authorized_keys 2>/dev/null

# Are they logged in right now
who | grep jordan
```

**All five, not one.** Each covers a different route, and the common mistake is
stopping after the second.

## What trips people up

### 1. Locked is not closed

`!` in front of the hash stops password authentication and nothing else. SSH keys
still work.

`chage -E 0` expires the account, which stops everything. Remove
`authorized_keys` as well.

### 2. Editing the files directly

One malformed line can break authentication for every account on the machine.

`vipw` and `vigr` lock and validate. `pwck -r` and `grpck -r` check afterwards.
And keep a second session open while you work.

### 3. `grep` instead of `getent`

On a domain-joined machine the account is not in `/etc/passwd` at all, and `grep`
finding nothing looks like the account does not exist.

`getent passwd name` goes through NSS and answers for every configured source.

### 4. A number where a name should be

`ls -l` showing `1001` instead of a name means no passwd entry exists for that
UID, usually a deleted account, or files restored from a machine whose UIDs
differed.

`find / -uid 1001` finds them all. Decide deliberately who should own them, before
the next `useradd` claims that UID and inherits the lot.

### 5. Assuming the shadow file is a complete picture

It covers local accounts only. LDAP, SSSD, and Kerberos accounts have no entry in
it, and their password policy lives somewhere else entirely.

`getent passwd` and `/etc/nsswitch.conf` tell you which sources are in play.

## Work it through

An auditor asks for a list of every account on a server that can log in
interactively. Somebody hands over `wc -l /etc/passwd`, which says 42.

Reason it out before reading on.

**42 is wrong and enormously so**, because most entries in `/etc/passwd` are not
people. Service accounts need an identity to own files and run processes; they are
not login accounts.

**First cut: the shell.** An account whose shell is `/usr/sbin/nologin` or
`/bin/false` cannot get an interactive session:

```
getent passwd | awk -F: '$7 !~ /(nologin|false)$/ {print $1, $7}'
```

That usually reduces 42 to a handful.

**Second cut: the UID.** System accounts live below `UID_MIN` from
`/etc/login.defs`, conventionally 1000:

```
getent passwd | awk -F: '$3 >= 1000 && $3 != 65534 {print $1}'
```

`65534` is `nobody` and is excluded deliberately.

**Third cut: is the password usable?**

```
sudo awk -F: '$2 !~ /^[!*]/ {print $1}' /etc/shadow
```

Entries starting `!` are locked and `*` were never usable.

**Fourth (and this is the one that makes the answer honest), keys:**

```
sudo find /home /root -name authorized_keys -not -empty 2>/dev/null
```

An account with a locked password and a key is a login account, and none of the
first three checks would have caught it.

**Fifth: is `/etc/passwd` even the whole story?** `grep -E '^(passwd|shadow):'
/etc/nsswitch.conf`. If it lists `sss` or `ldap`, local files are a fraction of
the accounts that can authenticate, and the real answer lives in the directory.

Now the point worth extracting. **"Can this account log in" is not one
question and no single file answers it.** Shell, UID range, password state,
key presence, and account expiry are five independent things, any one of which
can be the deciding factor, and they can disagree.

The habit worth taking: **when asked about access, check the keys.** It is the
route that no field in `/etc/passwd` or `/etc/shadow` mentions, which is exactly
why it gets missed, and it is the one most administrators actually use.

## Try it

Optional, on any machine.

1. `getent passwd | wc -l`, then the shell and UID filters above. Compare the
   three numbers.
2. `getent passwd root` and name all seven fields.
3. `sudo grep '^root:' /etc/shadow | cut -d: -f2 | cut -c1-4` and identify the
   algorithm from the prefix.
4. `sudo awk -F: '{print $2}' /etc/shadow | cut -d'$' -f2 | sort | uniq -c`.
5. `w`, then `who`, then `last | head`. Note what each adds.
6. `sudo lastb | head` if there is anything in it.
7. `sudo pwck -r` and `sudo grpck -r`, and read what they check.

**Verification step.** You have it when you can produce a defensible list of
interactive accounts on an unfamiliar machine, and say why each excluded entry was
excluded.

## Check yourself

<details class="qa">
<summary>Why is `/etc/passwd` world-readable, and what problem did shadow passwords solve?</summary>

**Because everything needs it.** Every `ls -l` turns a UID into a name, every `ps`
shows an owner, and every program displaying a username reads it. Restricting it
would break all of that for unprivileged users.

Originally the password hash was in field two of that same world-readable file,
which meant any user could copy it and attack every account offline at leisure,
with no rate limiting and no logging.

**Shadow passwords split the file.** The parts everything needs stayed readable in
`/etc/passwd`, with an `x` as a placeholder, and the hashes moved to
`/etc/shadow` at mode 640 owned by `root:shadow`.

The design is worth appreciating: the secret is separated from the metadata, and
only the thing that needs privilege has it.

</details>

<details class="qa">
<summary>What are the three parts of `$y$j9T$kPrG5D21P2aNr55UsgWQV0$UHM9Lbk...`, and why is the salt not secret?</summary>

**`y`** is the algorithm, yescrypt. **`j9T$kPrG5D21P2aNr55UsgWQV0`** is the
parameters and the salt. **`UHM9Lbk...`** is the hash.

The salt is stored in plain sight because **secrecy is not its job**. Its job is to
be different for every account, and it achieves two things by being so.

Two people with the same password get different hashes, so identical entries
in the file do not reveal identical passwords. And an attacker cannot
precompute one rainbow table that works against the whole file. They must
attack each account separately, which multiplies the cost by the number of
accounts.

Verification never reverses anything: take the offered password, mix in the stored
salt, run the same function, compare the result.

</details>

<details class="qa">
<summary>Distinguish locked, expired, and a nologin shell.</summary>

**Locked**: `passwd -l`, a `!` before the hash in `/etc/shadow`. No password
can match. **SSH keys still work**, which makes this the weakest of the three
and the most commonly mistaken for a complete answer.

**Expired**: `chage -E 0`, field 8 of `/etc/shadow` set to a past date. The
account is closed and **no** authentication method works, keys included. This
is the one that actually stops access.

**`nologin` shell**, field 7 of `/etc/passwd` set to `/usr/sbin/nologin`.
Authentication succeeds, then the shell prints a message and exits. It blocks
an interactive session and is not a reliable block on port forwarding or `scp`
in every configuration. It is the right setting for a service account and the
wrong one for a departing employee.

</details>

<details class="qa">
<summary>`ls -l` shows `1001` where a username should be. What does that mean and what should you do?</summary>

No `/etc/passwd` entry exists for UID 1001. The file is fine; the account is
gone or was never on this machine.

Two usual causes: somebody ran `userdel` and the account's files outside the home
directory were left behind, or files were restored from another machine where the
UIDs differed.

The reason it matters is **UID reuse**. The next account created will very likely
take 1001 and silently inherit ownership of every one of those files.

`sudo find / -uid 1001 -not -path '/proc/*' 2>/dev/null` lists them. Then
decide deliberately: `chown` to a successor, archive, or delete, before the
UID is handed out again.

</details>

<details class="qa">
<summary>A shadow file contains `$1$` entries. Why is that a finding, and why does changing the system default not fix it?</summary>

**`$1$` is MD5**, which is fast, and fast is exactly wrong for password
hashing. Someone holding the file can attempt billions of guesses per second
on commodity hardware, so a password that would survive a slow algorithm falls
quickly.

**Changing `ENCRYPT_METHOD` or the PAM configuration does not rehash anything**,
and nothing could: the plaintext password is gone, and a hash cannot be converted
from one algorithm to another. The algorithm is chosen at the moment a password is
*set*.

So the only fix is for each affected user to change their password, which produces
a new hash in the current format. `chage -d 0 user` forces that at next login, and
a one-off forced rotation is the standard remedy after changing the default.

`sudo awk -F: '{print $2}' /etc/shadow | cut -d'$' -f2 | sort | uniq -c` shows the
spread in one command.

</details>

## References

- [passwd(5)](https://man7.org/linux/man-pages/man5/passwd.5.html) - Linux man-pages project. Accessed 2026-08-07.
- [shadow(5)](https://man7.org/linux/man-pages/man5/shadow.5.html) - Linux man-pages project. Accessed 2026-08-07.
- [group(5)](https://man7.org/linux/man-pages/man5/group.5.html) - Linux man-pages project. Accessed 2026-08-07.
- [crypt(5)](https://manpages.debian.org/stable/libcrypt-dev/crypt.5.en.html) - Debian Project. Accessed 2026-08-07.
- [nsswitch.conf(5)](https://man7.org/linux/man-pages/man5/nsswitch.conf.5.html) - Linux man-pages project. Accessed 2026-08-07.
- [pwck(8)](https://man7.org/linux/man-pages/man8/pwck.8.html) - Linux man-pages project. Accessed 2026-08-07.

Every block above with a distribution and architecture header was captured by running the command on a Debian 13 (trixie) container. Blocks without one are illustrative.
