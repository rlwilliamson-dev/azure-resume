---
title: "Password policy and MFA"
description: "Length, expiry, reuse, and lockout are four controls in four different places, and none of them is where people look first. chage, passwd -S, pam_pwquality, pam_faillock, a second factor, and why locked is not closed."
deck: "You locked the account and they logged in anyway"
track: "linux-plus"
level: "working"
order: 470
objectives:
  - "Name the file or module that enforces each half of a password policy"
  - "Read and set every ageing field on an account with chage"
  - "Tell locked, shell-disabled, and expired apart, and choose the right one"
  - "Add strength checking, lockout, and a second factor without locking yourself out"
prerequisites: ["managing-users-and-groups", "account-files-and-attributes"]
tags: ["linux", "linux-plus", "passwords", "pam", "mfa", "security"]
updated: 2026-08-08
draft: false
examObjectives:
  - exam: "xk0-006"
    domain: "3.0"
    objective: "3.4"
sources:
  - title: "chage(1)"
    url: "https://man7.org/linux/man-pages/man1/chage.1.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-08
    tier: 1
  - title: "passwd(1)"
    url: "https://man7.org/linux/man-pages/man1/passwd.1.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-08
    tier: 1
  - title: "shadow(5)"
    url: "https://man7.org/linux/man-pages/man5/shadow.5.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-08
    tier: 1
  - title: "login.defs(5)"
    url: "https://man7.org/linux/man-pages/man5/login.defs.5.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-08
    tier: 1
  - title: "pwquality.conf(5)"
    url: "https://manpages.debian.org/trixie/libpwquality-common/pwquality.conf.5.en.html"
    publisher: "Debian manpages"
    accessed: 2026-08-08
    tier: 1
  - title: "pam_pwhistory(8)"
    url: "https://man7.org/linux/man-pages/man8/pam_pwhistory.8.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-08
    tier: 1
  - title: "pam_faillock(8)"
    url: "https://man7.org/linux/man-pages/man8/pam_faillock.8.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-08
    tier: 1
  - title: "NIST SP 800-63B, Digital Identity Guidelines"
    url: "https://pages.nist.gov/800-63-4/sp800-63b.html"
    publisher: "National Institute of Standards and Technology"
    accessed: 2026-08-08
    tier: 1
  - title: "google-authenticator-libpam"
    url: "https://github.com/google/google-authenticator-libpam"
    publisher: "Google"
    accessed: 2026-08-08
    tier: 1
  - title: "Pwned Passwords"
    url: "https://haveibeenpwned.com/Passwords"
    publisher: "Have I Been Pwned"
    accessed: 2026-08-08
    tier: 2
symptoms:
  - symptom: "This account is currently not available"
    anchor: "locked-shell-disabled-and-expired-are-three-different-things"
  - symptom: "Your account has expired; please contact your system administrator"
    anchor: "locked-shell-disabled-and-expired-are-three-different-things"
  - symptom: "The password fails the dictionary check"
    anchor: "strength-and-the-module-that-enforces-it"
  - symptom: "PASS_MAX_DAYS changed nothing"
    anchor: "3-setting-the-maximum-age-in-the-wrong-file"
  - symptom: "Account is locked due to failed logins"
    anchor: "lockout-after-repeated-failures"
---

> **Before you read.** Somebody left on Friday. You did the thing you were told to
> do: `passwd -l` on their account, ticket closed, offboarding complete.
>
> On Monday the audit log shows them logging in at 07:40, running a deployment,
> and logging out. The account is still locked. You check twice. It is definitely
> locked.
>
> **What did locking the password actually stop?**

Less than the word suggests. Locking makes the stored password hash unmatchable,
so nothing typed at a password prompt will ever succeed. It does not remove an
SSH key, it does not close a shell, and it does not stop `cron` running that
person's jobs at 07:40 on Monday.

That is the shape of this whole topic. **A password policy is four or five
separate controls, enforced by four or five separate mechanisms, configured in
four or five different files**, and the interesting failures all come from
believing that one of them covers more ground than it does.

### Some words you will need

<dl class="terms">
<dt>ageing</dt>
<dd>The dates and intervals stored per account that decide when a password must change and when the account stops working. Fields three to eight of <code>/etc/shadow</code>.</dd>
<dt>composition rule</dt>
<dd>A requirement that a password contain particular classes of character. "One upper, one digit, one symbol."</dd>
<dt>credit</dt>
<dd>In <code>pam_pwquality</code>, how much a class of character is worth toward the length requirement. A negative value turns the credit into a requirement.</dd>
<dt>history</dt>
<dd>Previous password hashes kept so a new password can be rejected for being an old one. Stored in <code>/etc/security/opasswd</code>.</dd>
<dt>lockout</dt>
<dd>Refusing further authentication attempts after a number of consecutive failures. Distinct from a locked password.</dd>
<dt>locked</dt>
<dd>A hash made unmatchable by prefixing it with <code>!</code>. Password authentication cannot succeed; nothing else is affected.</dd>
<dt>TOTP</dt>
<dd>Time-based one-time password. A six-digit code derived from a shared secret and the current time, changing every thirty seconds.</dd>
<dt>nologin</dt>
<dd>A program that prints a message and exits non-zero. Used as a login shell to give an account no interactive session.</dd>
</dl>

## What breaks without this

**You close an account and it is not closed.** Locking the password leaves key
authentication, scheduled jobs, and existing sessions completely untouched, which
is the single most common incomplete offboarding there is.

**Your new policy applies to nobody.** `/etc/login.defs` sets defaults *at account
creation*. Editing it changes nothing for the four hundred accounts that already
exist, and nothing warns you.

**You lock yourself out.** A lockout policy that counts root's failures, applied
to a machine you reach only over SSH, is a control and a self-inflicted outage
wearing the same clothes.

**The policy gets written on a sticky note.** Fourteen characters, one of each
class, changed every ninety days, no reuse: the reachable human response is
`Summer2026!` becoming `Autumn2026!`, on paper, under the keyboard. A rule nobody
can follow is not a control.

## Four controls, three moments

Almost every confusion in this topic comes from not knowing *when* a given
control runs. There are three moments in an account's life, and each one consults
a different thing.

<figure class="learn-figure">
<svg viewBox="0 0 720 396" role="img" aria-labelledby="pw-title pw-desc" style="width:100%;height:auto;">
  <title id="pw-title">Which password control runs at which moment in an account's life</title>
  <desc id="pw-desc">Three moments. When an account is created, useradd reads the defaults in /etc/login.defs and writes ageing fields into /etc/shadow; this happens once and never again. When a password is set or changed, the PAM password stack runs: pam_pwquality checks length and composition, pam_pwhistory rejects reuse, and pam_unix hashes the result into /etc/shadow. At every login the PAM auth stack runs pam_faillock for lockout and pam_unix to compare the hash, and then the account stack has pam_unix read the ageing fields back out of /etc/shadow to decide whether the password or the account has expired. The shadow file is written by the first two moments and read by the third.</desc>
  <g font-family="ui-monospace, monospace">
    <rect x="16" y="20" width="204" height="52" rx="5" fill="currentColor" fill-opacity="0.12" stroke="currentColor" stroke-opacity="0.4"/>
    <text x="118" y="42" text-anchor="middle" font-size="12" fill="currentColor">account created</text>
    <text x="118" y="60" text-anchor="middle" font-size="9.5" fill="currentColor" fill-opacity="0.65">useradd, adduser</text>
    <rect x="258" y="20" width="204" height="52" rx="5" fill="currentColor" fill-opacity="0.12" stroke="currentColor" stroke-opacity="0.4"/>
    <text x="360" y="42" text-anchor="middle" font-size="12" fill="currentColor">password set or changed</text>
    <text x="360" y="60" text-anchor="middle" font-size="9.5" fill="currentColor" fill-opacity="0.65">passwd, chpasswd</text>
    <rect x="500" y="20" width="204" height="52" rx="5" fill="currentColor" fill-opacity="0.12" stroke="currentColor" stroke-opacity="0.4"/>
    <text x="602" y="42" text-anchor="middle" font-size="12" fill="currentColor">every login</text>
    <text x="602" y="60" text-anchor="middle" font-size="9.5" fill="currentColor" fill-opacity="0.65">login, sshd, su</text>
    <rect x="16" y="98" width="204" height="128" rx="5" fill="currentColor" fill-opacity="0.07" stroke="currentColor" stroke-opacity="0.3"/>
    <text x="118" y="122" text-anchor="middle" font-size="10.5" fill="currentColor">/etc/login.defs</text>
    <text x="118" y="146" text-anchor="middle" font-size="9.5" fill="currentColor" fill-opacity="0.75">PASS_MAX_DAYS</text>
    <text x="118" y="162" text-anchor="middle" font-size="9.5" fill="currentColor" fill-opacity="0.75">PASS_MIN_DAYS</text>
    <text x="118" y="178" text-anchor="middle" font-size="9.5" fill="currentColor" fill-opacity="0.75">PASS_WARN_AGE</text>
    <text x="118" y="206" text-anchor="middle" font-size="9.5" fill="currentColor" fill-opacity="0.6">defaults, applied once</text>
    <rect x="258" y="98" width="204" height="128" rx="5" fill="currentColor" fill-opacity="0.07" stroke="currentColor" stroke-opacity="0.3"/>
    <text x="360" y="122" text-anchor="middle" font-size="10.5" fill="currentColor">PAM password stack</text>
    <text x="360" y="146" text-anchor="middle" font-size="9.5" fill="currentColor" fill-opacity="0.75">pam_pwquality  length</text>
    <text x="360" y="162" text-anchor="middle" font-size="9.5" fill="currentColor" fill-opacity="0.75">pam_pwhistory  reuse</text>
    <text x="360" y="178" text-anchor="middle" font-size="9.5" fill="currentColor" fill-opacity="0.75">pam_unix       hashes</text>
    <text x="360" y="206" text-anchor="middle" font-size="9.5" fill="currentColor" fill-opacity="0.6">runs on every change</text>
    <rect x="500" y="98" width="204" height="128" rx="5" fill="currentColor" fill-opacity="0.07" stroke="currentColor" stroke-opacity="0.3"/>
    <text x="602" y="122" text-anchor="middle" font-size="10.5" fill="currentColor">PAM auth, then account</text>
    <text x="602" y="146" text-anchor="middle" font-size="9.5" fill="currentColor" fill-opacity="0.75">pam_faillock   lockout</text>
    <text x="602" y="162" text-anchor="middle" font-size="9.5" fill="currentColor" fill-opacity="0.75">pam_unix       compare</text>
    <text x="602" y="178" text-anchor="middle" font-size="9.5" fill="currentColor" fill-opacity="0.75">pam_unix       expiry</text>
    <text x="602" y="206" text-anchor="middle" font-size="9.5" fill="currentColor" fill-opacity="0.6">runs every time</text>
    <rect x="16" y="300" width="688" height="60" rx="5" fill="currentColor" fill-opacity="0.12" stroke="currentColor" stroke-opacity="0.4"/>
    <text x="360" y="326" text-anchor="middle" font-size="12" fill="currentColor">/etc/shadow</text>
    <text x="360" y="345" text-anchor="middle" font-size="9.5" fill="currentColor" fill-opacity="0.65">the hash, and six ageing fields, per account</text>
    <text x="132" y="266" font-size="10" fill="currentColor" fill-opacity="0.75">writes</text>
    <text x="374" y="266" font-size="10" fill="currentColor" fill-opacity="0.75">writes</text>
    <text x="616" y="266" font-size="10" fill="currentColor" fill-opacity="0.75">reads</text>
  </g>
  <g stroke="currentColor" stroke-opacity="0.45" fill="none" stroke-width="1.2">
    <path d="M118 226 L118 294 M114 288 L118 295 L122 288"/>
    <path d="M360 226 L360 294 M356 288 L360 295 L364 288"/>
    <path d="M602 294 L602 226 M598 232 L602 225 L606 232"/>
  </g>
</svg>
<figcaption>Three moments, and only the middle one is what most people mean by "password policy". Editing login.defs changes the left column alone, which is why it has no effect on accounts that already exist.</figcaption>
</figure>

**Read the arrows.** Two of the three moments *write* to `/etc/shadow` and one
*reads* from it. That is why a change to `login.defs` today shows up in nothing
you can see: it will affect the next account created and no other.

| Control | Enforced by | Configured in | Applies to |
| --- | --- | --- | --- |
| Length and composition | `pam_pwquality` | `/etc/security/pwquality.conf` | Every password change |
| Reuse | `pam_pwhistory` | The PAM stack, plus `/etc/security/opasswd` | Every password change |
| Expiry and ageing | `pam_unix` account phase | `/etc/shadow`, per account, via `chage` | Every login |
| Defaults at creation | `useradd` | `/etc/login.defs` | New accounts only |
| Lockout | `pam_faillock` | `/etc/security/faillock.conf` | Every failed login |

Nothing in that table is set in the same place as anything else in it, and the
exam expects you to be able to name the right one from a symptom.

## The defaults, and why they are only defaults

Start with what a machine ships with:

```bash
# AlmaLinux 10.2, x86_64
$ grep -E '^PASS_|^UMASK|^ENCRYPT_METHOD' /etc/login.defs
UMASK		022
PASS_MAX_DAYS	99999
PASS_MIN_DAYS	0
PASS_MIN_LEN	8
PASS_WARN_AGE	7
PASS_CHANGE_TRIES	5
PASS_ALWAYS_WARN	yes
ENCRYPT_METHOD YESCRYPT
```

**`PASS_MAX_DAYS 99999` is the default on every mainstream distribution**, and
99999 days is about 273 years. Out of the box, passwords never expire. Everything
about expiry in this topic is a change from that.

The three that matter:

| Setting | Means | Written into |
| --- | --- | --- |
| `PASS_MAX_DAYS` | Days a password may be used | Shadow field 5 |
| `PASS_MIN_DAYS` | Days before it may be changed *again* | Shadow field 4 |
| `PASS_WARN_AGE` | Days of warning before expiry | Shadow field 6 |

**`ENCRYPT_METHOD YESCRYPT` decides the hash algorithm** for passwords set
from here on. It is the current default on AlmaLinux 10 and Debian 13; older
machines say `SHA512`. Changing it does nothing retroactively either, each
account migrates to the new algorithm the next time its password is set, which
you can see in the `$y$` versus `$6$` prefix from lesson 28.

**`PASS_MIN_LEN` is the interesting trap in that file.** AlmaLinux 10 still
ships the line, it looks exactly like the length policy you were asked to
configure, and on a machine using PAM nothing reads it, length is
`pam_pwquality`'s job, several sections down. The clearest evidence is that
current `login.defs(5)` documents `PASS_MAX_DAYS`, `PASS_MIN_DAYS`, and
`PASS_WARN_AGE` and does not mention `PASS_MIN_LEN` at all. Setting it to 14
and reporting the policy as implemented is a real and frequent mistake.

## Ageing, field by field

A brand new account inherits those defaults, and `chage -l` is how you read them
back:

```bash
# AlmaLinux 10.2, x86_64
$ useradd sam; chage -l sam
Last password change					: Aug 08, 2026
Password expires					: never
Password inactive					: never
Account expires						: never
Minimum number of days between password change		: 0
Maximum number of days between password change		: 99999
Number of days of warning before password expires	: 7
```

Seven lines, and they are the six ageing fields of `/etc/shadow` rendered as
dates instead of day counts. **`chage -l` is the tool to reach for**, not `grep`
on the shadow file, because it does the epoch arithmetic for you and it does not
require root to read your own account.

Now apply a policy to that account:

```bash
# AlmaLinux 10.2, x86_64
$ chage -M 90 -m 7 -W 14 sam; chage -l sam
Last password change					: Aug 08, 2026
Password expires					: Nov 06, 2026
Password inactive					: never
Account expires						: never
Minimum number of days between password change		: 7
Maximum number of days between password change		: 90
Number of days of warning before password expires	: 14
```

**`Password expires` became a real date**, computed from the last change plus 90
days. Nothing else moved.

| Flag | Sets | Effect |
| --- | --- | --- |
| `-M 90` | Maximum days | The password must be changed every 90 days |
| `-m 7` | Minimum days | It cannot be changed again for 7 days |
| `-W 14` | Warning | Nagging starts 14 days before expiry |
| `-I 30` | Inactive | 30 days after expiry the account stops working entirely |
| `-E 2026-12-31` | Account expiry | A hard end date for the account itself |
| `-d 0` | Last change | Forces a change at the next login |
| `-l` | *(nothing)* | Prints all of the above |

**`-m` exists for a reason and it is not the one people assume.** Its purpose is
to stop somebody defeating password history by changing their password eleven
times in a row to get back to the one they like. Its cost is that a person whose
password has just been compromised cannot change it, and you have to clear the
minimum before they can. Set it to 1 if you set it at all; 7 is a support ticket
waiting to happen.

`-E` is a different animal from `-M` and the difference is the whole of the next
section:

```bash
# AlmaLinux 10.2, x86_64
$ chage -E 2026-12-31 sam; chage -l sam
Last password change					: Aug 08, 2026
Password expires					: Nov 06, 2026
Password inactive					: never
Account expires						: Dec 31, 2026
Minimum number of days between password change		: 7
Maximum number of days between password change		: 90
Number of days of warning before password expires	: 14
```

Two independent expiry dates on one account. The November one ends the
*password*; the person changes it and carries on. The December one ends the
*account*, and nothing they do at a prompt will help.

**`chage -E` is what a contractor's account should have from the day it is
created.** An end date set in advance costs nothing and closes the account on
time whether or not anybody remembers.

<details class="deeper">
<summary>If you already administer Linux: the inactive field, epoch arithmetic, and the ageing bug that fires months later</summary>

Three details in `chage` that cause incidents rather than confusion.

**The inactive field (`-I`) is a second, silent deadline.** After the password
expires, the account still works: the person is prompted to change the password
at login and does. `-I 30` says that thirty days *after* the password expired,
stop accepting the account at all. So `-M 90 -I 30` is not a 90-day policy, it is
a 120-day fuse, and an account that goes untouched over a long secondment dies
without anybody choosing that. `chage -l` reports it as `Password inactive`, which
reads like a status and is a *date*.

**Everything in `/etc/shadow` is days since 1 January 1970, and the arithmetic
leaks.** `chage -E 0` means day zero, which is why lesson 28 shows it printing
`Jan 01, 1970` rather than an error. **`-1` removes a limit and `0` is the most
aggressive possible setting**: `chage -E -1` clears an account expiry and
`chage -M -1` clears password expiry, while typing `0` for either sets a date in
1970. `chage -d 0` is the exception that means what people expect, last
      changed
on day zero, therefore overdue, therefore change it at the next login, which is
the correct end to any temporary password you have issued.

**And the fleet-scale version:** `chage` is per account, so a policy is not
implemented by running it once. `chage -M 90 $(awk -F: '$3 >= 1000 && $3 < 60000
{print $1}' /etc/passwd)` applies it to today's humans and says nothing about
tomorrow's, which is what `login.defs` is for. You need both, they are edited by
different tools in different files, and that is exactly why one of them is usually
missing when an auditor asks.

The last trap: setting `-M 90` on Monday against accounts whose passwords were all
set on the same build day expires all of them on the same day, three months later,
during somebody else's shift. Staggering with a random offset is two lines of shell
and saves a genuinely bad morning.

</details>

## Locked, shell-disabled, and expired are three different things

This is the section the opening question was about, and the three states get
conflated constantly. Start from a normal account:

```bash
# AlmaLinux 10.2, x86_64
$ grep '^sam:' /etc/shadow; passwd -S sam
sam:$y$j9T$i3.3Rdlm9PuNsDxpu/xfu/$fp6oK8oAltwRX4OtNcXTLDckNNPsGBLbr79KFpndBu.:20673:0:99999:7:::
sam P 2026-08-08 0 99999 7 -1
```

Two views of the same account. The shadow line is the raw record; `passwd -S` is
the summary, and its seven fields are worth learning because they are the fastest
read there is:

| Field | Here | Means |
| --- | --- | --- |
| 1 | `sam` | The account |
| 2 | `P` | **Status.** `P` usable password, `L` locked, `NP` no password at all |
| 3 | `2026-08-08` | Last change |
| 4 | `0` | Minimum days |
| 5 | `99999` | Maximum days |
| 6 | `7` | Warning days |
| 7 | `-1` | Inactive days, `-1` meaning not set |

Field two is the one that matters, and it has three values.

<details class="predict">
<summary>Locking works by making the stored hash impossible to produce from any input. Given that, what changes in the shadow line when you run <code>passwd -l sam</code>, and what does <code>passwd -S</code> say afterwards?</summary>

```bash
# AlmaLinux 10.2, x86_64
$ passwd -l sam; grep '^sam:' /etc/shadow; passwd -S sam
passwd: password changed.
sam:!$y$j9T$i3.3Rdlm9PuNsDxpu/xfu/$fp6oK8oAltwRX4OtNcXTLDckNNPsGBLbr79KFpndBu.:20673:0:99999:7:::
sam L 2026-08-08 0 99999 7 -1
```

</details>

**One character.** The hash is byte-for-byte what it was, with `!` in front of
it. No password hashes to a string starting with `!`, so the comparison can
never match, and the original is still there, which is why unlocking restores
the old password rather than clearing it:

```bash
# AlmaLinux 10.2, x86_64
$ passwd -u sam; grep '^sam:' /etc/shadow; passwd -S sam
passwd: password changed.
sam:$y$j9T$i3.3Rdlm9PuNsDxpu/xfu/$fp6oK8oAltwRX4OtNcXTLDckNNPsGBLbr79KFpndBu.:20673:0:99999:7:::
sam P 2026-08-08 0 99999 7 -1
```

**Note `passwd: password changed.` on both.** That message is what `passwd`
prints for any modification of the field, and it is not evidence that a password
was set. Reading it as such is a classic way to convince yourself an offboarding
worked.

There is a fourth state hiding here, and it is the dangerous one:

```bash
# AlmaLinux 10.2, x86_64
$ passwd -d sam; grep '^sam:' /etc/shadow; passwd -S sam
passwd: password changed.
sam::20673:0:99999:7:::
sam NP 2026-08-08 0 99999 7 -1
```

**`passwd -d` empties the field**, and an empty password field does not mean
"no login". It means **no password required**. `passwd -S` reports `NP`, and
depending on how `pam_unix` is configured, `nullok` is in the shipped
AlmaLinux stack, that is an account anybody can walk into. `-d` and `-l` are
one letter apart and opposite in effect. `awk -F: '$2 == "" {print $1}'
/etc/shadow` is the check that finds them.

Locking is also, quietly, the normal state of most of the machine:

```bash
# AlmaLinux 10.2, x86_64
$ passwd -Sa | head -12
root L 2025-06-05 0 99999 7 -1
bin L 2025-06-05 0 99999 7 -1
daemon L 2025-06-05 0 99999 7 -1
adm L 2025-06-05 0 99999 7 -1
lp L 2025-06-05 0 99999 7 -1
sync L 2025-06-05 0 99999 7 -1
shutdown L 2025-06-05 0 99999 7 -1
halt L 2025-06-05 0 99999 7 -1
mail L 2025-06-05 0 99999 7 -1
operator L 2025-06-05 0 99999 7 -1
games L 2025-06-05 0 99999 7 -1
ftp L 2025-06-05 0 99999 7 -1
```

Every system account is `L`, including root on this image. **`passwd -Sa` is
one command for the whole machine**, and piping it to `awk '$2 == "P"'`
produces the list of accounts on this box that can be logged into with a
password, which is a much shorter and much more interesting list than
`/etc/passwd`.

### The second state: a shell that is not a shell

A working baseline first, so the difference is unambiguous:

```bash
# AlmaLinux 10.2, x86_64
$ su - sam -c id; echo "rc=$?"
uid=1000(sam) gid=1000(sam) groups=1000(sam)
rc=0
```

Now the same command against an account whose shell has been replaced:

```bash
# AlmaLinux 10.2, x86_64
$ grep '^sam:' /etc/passwd; passwd -S sam; su - sam -c id; echo "rc=$?"
sam:x:1000:1000::/home/sam:/sbin/nologin
sam P 2026-08-08 0 99999 7 -1
This account is currently not available.
rc=1
```

**Read the second line before the third.** `passwd -S` says `P`: the password is
perfectly usable and authentication succeeded. What failed is the *shell*.
`/sbin/nologin` printed its message and exited 1, and `id` never ran.

That is the correct state for a service account, and it is not an authentication
control. The credential still works, and depending on configuration SFTP, `scp`,
and SSH port forwarding may still function, because none of them needs an
interactive shell.

### The third state: the account itself has ended

Account expiry is checked in a different PAM phase from the password, and that one
structural fact produces a result most people get wrong.

<details class="predict">
<summary><code>chage -E 2020-01-01</code> puts the account's end date six years in the past. Root then runs <code>su - sam -c id</code>. Given that expiry is enforced in PAM's *account* phase rather than the auth phase, does the command run?</summary>

```bash
# AlmaLinux 10.2, x86_64
$ chage -E 2020-01-01 sam; chage -l sam | head -3; su - sam -c id; echo "rc=$?"
Last password change					: Aug 08, 2026
Password expires					: never
Password inactive					: never
uid=1000(sam) gid=1000(sam) groups=1000(sam)
rc=0
```

</details>

**It runs, and the account is genuinely expired.** This is not a bug and it is not
evidence that `chage -E` failed. It is the account stack in `/etc/pam.d/su` on the
RHEL family, whose first line is:

```
account		sufficient	pam_succeed_if.so uid = 0 use_uid quiet
```

`sufficient` plus a condition that root satisfies means the account phase
returns success immediately and `pam_unix`, the module that would have read
the expiry field, is never reached. **Root's `su` is exempt by design**, so
testing account expiry as root, with `su`, gives a false negative every time.

Test it the way a person would arrive instead: over SSH, at a console login, or
with `su` from an unprivileged account. Those all run `pam_unix` in the account
phase, and those all get refused.

**And that is the point worth carrying out of this section.** Expiry is
checked *after* authentication has already succeeded, so it does not matter
which credential was used to get there. A password, an SSH key, a Kerberos
ticket, all of them reach the account phase, and all of them are refused
there. That is what makes it the strongest of the three states, and what makes
`su` as root the worst possible way to verify it.

Which gives the table the exam is testing:

| State | Set by | Password login | **SSH key login** | Interactive shell |
| --- | --- | --- | --- | --- |
| Normal |, | Yes | Yes | Yes |
| **Locked** | `passwd -l`, `usermod -L` | No | **Yes** | Yes |
| **Shell disabled** | `usermod -s /sbin/nologin` | Authenticates | Authenticates | **No** |
| **Expired** | `chage -E`, `usermod -e` | No | **No** | No |

**The bold column is the answer to the question this topic opened with.** Locking
prefixes the password hash; SSH public key authentication never looks at the
password hash. Somebody with an entry in `~/.ssh/authorized_keys` is entirely
unaffected by `passwd -l`, which is why the audit log shows them logging in at
07:40 on Monday.

**Say it as a rule: locking is not closing.** Closing an account is a sequence,
and the order matters because each step can be undone by something still running:

```
sudo chage -E 0 sam                     # expired: refused at the account phase
sudo passwd -l sam                      # locked: refused at the auth phase
sudo usermod -s /sbin/nologin sam       # no interactive shell if either is bypassed
sudo mv ~sam/.ssh/authorized_keys ~sam/.ssh/authorized_keys.revoked
sudo crontab -r -u sam                  # scheduled jobs do not need a login
sudo loginctl terminate-user sam        # kill what is already connected
```

`chage -E 0` first, because it is the one that holds regardless of credential.
Everything after it is defence in depth against a path you did not think of.

<details class="deeper">
<summary>If you already administer Linux: what <code>!</code> versus <code>!!</code> versus <code>*</code> actually mean, and the offboarding steps nobody writes down</summary>

The second field of `/etc/shadow` is doing more signalling than it looks, and the
conventions differ between tools.

| Field starts with | Means | Typically written by |
| --- | --- | --- |
| `$y$`, `$6$`, `$1$` | A usable hash, algorithm named by the first part | `passwd`, `chpasswd` |
| `!` then a hash | Locked, original recoverable | `passwd -l`, `usermod -L` |
| `!!` | Locked and no password was ever set | `useradd` on the RHEL family |
| `*` | No password login possible, and none was ever set | Distribution packaging for system accounts |
| *empty* | **No password required** | `passwd -d` |
| `!*` | Locked, and there was nothing to lock | Debian-family `adduser --disabled-password` |

**`*` and `!` are not equivalent.** Unlocking a `!`-prefixed account restores a
working password; unlocking a `*` account leaves it with a password of `*`, which
is not a hash and cannot be produced, so the account remains unusable and now
looks fine in a listing. That is why `passwd -u` on a service account appears to
succeed and changes nothing.

**The steps that get missed, in the order they bite:**

- **`authorized_keys`.** Not just the user's own. A key of theirs may sit in
  `root`'s file, in a shared deploy account, or behind an `AuthorizedKeysCommand`
  backed by a directory service where local edits do nothing.
- **`sudoers`.** An entry naming a departed user is harmless until the username is
  reissued to somebody else, at which point it is a privilege grant nobody
  intended. `grep -r sam /etc/sudoers /etc/sudoers.d/` from lesson 42.
- **Running processes and `cron`.** Expiry stops new logins and nothing else. A
  `tmux` session started last week keeps running, and so does every `crontab`, `at`
  job, and systemd user unit.
- **Tokens that are not passwords.** API keys, personal access tokens, and
  Kerberos keytabs live outside `/etc/shadow` entirely, and nothing in this topic
  touches them.

**And the one that decides whether any of this is auditable:** do not delete the
account. `userdel` frees the UID, and the next account created gets it and silently
inherits ownership of every file the leaver left behind. Expire, lock, disable the
shell, revoke the keys, and leave the account in place until the files have been
dealt with.

</details>

## Strength, and the module that enforces it

Length and composition are not in `login.defs` and not in `/etc/shadow`. They are
a PAM module that runs when a password is *set*, and on the RHEL family the line
is already in the shipped stack:

```
password    requisite                                    pam_pwquality.so
password    sufficient                                   pam_unix.so yescrypt shadow nullok use_authtok
```

**`requisite` before `sufficient` is the design.** `pam_pwquality` gets the
proposed password first and can refuse it outright; only if it passes does
`pam_unix` hash and store it. `use_authtok` on the `pam_unix` line means "use the
password the previous module already collected and approved", and removing it
silently disables the whole check by making `pam_unix` ask again.

`libpwquality` ships a way to ask the same question without changing anything:

<details class="predict">
<summary><code>pwscore</code> runs a candidate password through exactly the checks <code>pam_pwquality</code> would apply and prints a score out of 100, or an error. One of these three passes. Which one, and what does that tell you about composition rules?</summary>

```bash
# AlmaLinux 10.2, x86_64
$ for p in password Passw0rd correct-horse-battery-staple; do printf "%s\n" "$p" | pwscore; echo "rc=$?"; done
Password quality check failed:
 The password fails the dictionary check - it is based on a dictionary word
rc=1
Password quality check failed:
 The password fails the dictionary check - it is based on a dictionary word
rc=1
100
rc=0
```

</details>

**`Passw0rd` failing is the point of the whole section.** It satisfies every
composition rule anybody has ever written (upper, lower, digit, eight
characters) and it is rejected, because substituting a zero for an `o` is the
first thing any cracking tool tries and the dictionary check knows it.
Meanwhile `correct-horse-battery-staple` scores 100 with no capital letter, no
digit, and no symbol.

That is the empirical case against composition rules in a single transcript:
**they measure the wrong thing.** Length and unpredictability are what resist
guessing; character classes measure how annoyed the user was.

`pwscore` is worth having in your hands for another reason: it is the only way to
test a policy change without setting a real password on a real account. Edit
`pwquality.conf`, run `pwscore` against half a dozen realistic candidates, and you
know what you have done before anybody else finds out.

<details class="deeper">
<summary>If you already administer Linux: tuning pam_pwquality, and why a negative credit means "require"</summary>

`/etc/security/pwquality.conf` is where the numbers live, and the credit system in
it is the least intuitive thing in this topic.

**`minlen` is not a minimum length. It is a minimum *score*.** Every character
counts one toward it, and a character from a class with a *positive* credit counts
extra, up to that credit's value. Set `minlen = 9` with `dcredit = 1` and the
password `abcdefgh1` scores eight characters plus one credit for containing a
digit, reaches nine, and passes at eight characters of actual length. The length
you configured is not the length you get.

**Modern defaults do not do this to you; inherited configurations do.**
`libpwquality` ships `minlen = 8` with all four credits at `0`, so nothing buys a
character back. Positive credits are a `pam_cracklib` habit that survives in
copied configuration files, and they are worth grepping for before you trust a
length figure.

A negative credit changes the meaning entirely. `dcredit = -1` stops granting
a bonus and starts demanding: the password must contain at least one digit,
and it earns nothing toward `minlen` for doing so. That is how a composition
rule is written here, and it is why almost every hardening benchmark you will
be handed sets all four credits negative:

| Setting | Positive value | Negative value |
| --- | --- | --- |
| `dcredit` | Digits earn up to N toward `minlen` | At least N digits required |
| `ucredit` | Upper case earns up to N | At least N upper case required |
| `lcredit` | Lower case earns up to N | At least N lower case required |
| `ocredit` | Symbols earn up to N | At least N symbols required |

If you want a real length floor, set the credits to zero and `minlen` to the
number you mean. `minlen = 15` with `dcredit = 0 ucredit = 0 lcredit = 0
ocredit = 0` is fifteen actual characters and no composition rules, which is
what current guidance points at and which is much easier to explain to people.

The rest of the file, in rough order of usefulness:

- **`minclass`**, require characters from N of the four classes. Cleaner than
  four separate negative credits and does the same job. Defaults to `0`,
  meaning no requirement.
- **`dictcheck`**, on by default, and the check that rejected `Passw0rd`
  above. It uses the cracklib dictionary, which is a word list. **It is not a
  breach list**, and conflating the two is common.
- **`badwords`**, a space-separated list of words the password must not
  contain, checked in addition to the dictionary. This is where your company
  name, product names, and the site's town go, and it is the cheapest real
  improvement in the file.
- **`maxrepeat`** and **`maxsequence`**, cap runs of the same character and of
  monotonic sequences. Both default to `0`, which means *disabled*, so
  `aaaaaaaaaaaaaaa` satisfies a length-only policy until you set them.
- **`usercheck`**, reject a password containing the username. On by default,
  and worth leaving on.

Two options you will reach for live on the PAM line rather than in the file.
**`enforce_for_root`** is off by default and surprises people during testing: root
setting a password for another user is warned and not stopped, so `passwd sam` as
root succeeds with a weak password, the policy looks broken, and it is working as
documented. **`local_users_only`** limits the check to accounts in `/etc/passwd`,
leaving directory accounts to the directory's own policy from lesson 38.

**Where the numbers go is not where the PAM line goes, and both matter.** On the
RHEL family `/etc/pam.d/system-auth` is generated by `authselect` and carries a
header telling you not to edit it; hand edits are reverted the next time anything
runs `authselect apply-changes`. Put settings in `/etc/security/pwquality.conf` or
a drop-in under `/etc/security/pwquality.conf.d/`, which `authselect` does not own.
On the Debian family the line lives in `/etc/pam.d/common-password` and is managed
by `pam-auth-update` from packaged profiles under `/usr/share/pam-configs/`.

The failure mode either way: a policy that tests correctly today and is silently
gone after a package update, because it was written in the generated file rather
than in the source.

</details>

## Reuse, and the file that has to exist

Stopping somebody cycling back to last quarter's password is a separate module
again:

```
password requisite pam_pwquality.so retry=3
password required  pam_pwhistory.so use_authtok remember=10
password sufficient pam_unix.so yescrypt shadow use_authtok
```

`pam_pwhistory` stores previous hashes in `/etc/security/opasswd` and refuses a
new password matching any of the last `remember` entries. Three things about it
are worth knowing before you add the line.

**It only remembers from the moment you enable it.** The file starts empty, so on
the day you set `remember=10` every user may still set the password they have been
using for two years. Nothing is retroactive.

Root is exempt unless you say otherwise, the same shape as `enforce_for_root`.
A password set by root for another user bypasses the history check by default,
which is exactly the path a helpdesk reset takes.

It needs a minimum age beside it, and the age needs to be small. Without
`chage -m`, history is defeated by changing the password eleven times in one
sitting; with `-m 7`, somebody whose password has just leaked cannot replace
it. One day is the setting that survives both arguments.

`pam_unix` has its own `remember=` option that predates the separate module and
writes to the same file. Either works; having both in one stack double-counts
confusingly, so pick one.

## Lockout after repeated failures

Guessing a password takes attempts. `pam_faillock` counts them and stops
accepting more:

```bash
# AlmaLinux 10.2, x86_64
$ authselect enable-feature with-faillock; grep faillock /etc/pam.d/system-auth
auth        required                                     pam_faillock.so preauth silent
auth        required                                     pam_faillock.so authfail
account     required                                     pam_faillock.so
```

**One command, three lines added in the right places.** That is the supported way
to do it on the RHEL family, and the alternative is putting those three lines into
a generated file by hand and having them removed by the next profile apply.

Then it counts. Two failed `su` attempts, and the tally:

<details class="predict">
<summary>The <code>authfail</code> line records a failure and the <code>preauth</code> line refuses once the count is over the limit. Two failures is under any sane <code>deny</code> value, so nothing is locked. What does <code>faillock --user root</code> have to show?</summary>

```bash
# AlmaLinux 10.2, x86_64
$ for i in 1 2; do (sleep 2; echo hunter2) | runuser -u tux -- script -qec "su - root -c id" /dev/null; done; faillock --user root
Password: 
su: Authentication failure
Password: 
su: Authentication failure
root:
When                Type  Source                                           Valid
2026-08-08 18:15:11 TTY   /dev/pts/0                                           V
2026-08-08 18:15:16 TTY   /dev/pts/0                                           V
```

</details>

**Two rows, five seconds apart, both marked `V` for valid.** `Valid` here
means "still inside `fail_interval`, so still counting". A row that has aged
out stays in the file and stops being `V`. That column is the difference
between "this account has failed twice recently" and "this account failed
twice last March", which is the question you actually have when a ticket
arrives.

The two commands you will use are reading that table and clearing it:

```
sudo faillock --user sam
sudo faillock --user sam --reset
```

**`--reset` is the answer to the support ticket**, and it is worth knowing before
the ticket arrives, because the command people reach for instead is `passwd -u`,
which does nothing at all to a faillock tally.

`/etc/security/faillock.conf` holds the numbers, and the man page is explicit that
this file is where they belong rather than on the module line:

| Setting | What it does |
| --- | --- |
| `deny` | Consecutive failures before the account is locked |
| `unlock_time` | Seconds until the lock clears itself |
| `fail_interval` | Window in which failures count as consecutive, fifteen minutes by default |
| `even_deny_root` | Apply the policy to root, which is otherwise deliberately exempt |
| `root_unlock_time` | Root's own timeout, when the line above is set |
| `silent` | Do not tell the user the account is locked |

**`unlock_time` is the setting that decides whether this is a control or an
outage.** Zero means locked until an administrator resets it, which some standards
require and which is a denial of service anybody can trigger against anybody:
attempt four bad passwords against every account on the machine and nobody can
work. A finite `unlock_time` costs an attacker almost as much and costs you
nothing.

**Root is exempt by default and that is a decision, not an oversight.** The module
documentation says so in as many words: locking root out prevents denial of
service, and it is safe on a machine where root logs in only at the console or
through `su`. Turning `even_deny_root` on is a reasonable choice, and it is the
choice that needs a recovery plan beside it.

<details class="deeper">
<summary>If you already administer Linux: where pam_faillock lines must sit, and how to get back in after locking out root</summary>

`pam_faillock` is the module people most often install correctly and place
incorrectly, and a wrong placement fails open with no error anywhere.

**It needs two entries, not one**, because it does two different jobs at two
different points in the stack:

```
auth     required       pam_faillock.so preauth
auth     sufficient     pam_unix.so
auth     [default=die]  pam_faillock.so authfail
auth     required       pam_deny.so
account  required       pam_faillock.so
```

- The **`preauth`** line runs *before* `pam_unix` and refuses immediately if the
  account is already over its limit. Put it after `pam_unix` and a locked-out
  account still gets a password check on every attempt.
- The **`authfail`** line runs *after* `pam_unix` and is what increments the
  counter. Omit it and nothing is ever counted, the `preauth` line never fires, and
  the configuration looks complete.
- The **`account`** line is what reports the lockout to programs that only run
  account management.

`[default=die]` rather than `required` on the `authfail` line stops the stack
immediately instead of continuing to the next module, which matters when there
are several authentication sources. And **the numbers do not go on these
lines**, they go in `faillock.conf`, which the module's own documentation
recommends and which means one file to read rather than four stack entries to
compare.

`preauth` without `silent` leaks account existence, which is a subtlety the
module documentation calls out. Failures are not recorded for users who do not
exist, so the "account is locked" message can only ever appear for a real
account, and an attacker who sees it has confirmed the username. Adding
`silent` costs the locked-out user an explanation and removes the oracle.

The recovery you should rehearse before you need it. With `even_deny_root =
yes` and an SSH-only machine, five bad root passwords lock the only way in.
Three routes back:

- **A second session you already had open.** The cheapest insurance in existence
  is a second SSH session left connected while you change authentication
  configuration. Existing sessions are unaffected by anything in this topic.
- **`faillock --user root --reset`** from that session, or from any account with
  `sudo` that is not itself locked out.
- **Console or single-user mode**, which needs the hypervisor or the out-of-band
  management card, and needs `root_unlock_time` not to be zero if you get as far
  as a login prompt.

The tallies are files under `/var/run/faillock/`, one per user, so on a machine
where `/var/run` is a tmpfs a reboot clears every lockout. That is a legitimate
last resort and an argument for not treating faillock state as an audit record.

**And the operational argument worth having with whoever wrote the standard:**
lockout defends against online guessing only. An attacker with a copy of
`/etc/shadow` is offline and unaffected, and rate limiting at the SSH layer plus
key-only authentication from lesson 43 removes the attack surface that lockout
protects, without handing anybody a way to lock your staff out at will.

</details>

## A second factor

A password is one factor: something you know. Adding a second means adding
something you *have*, and the portable answer on Linux is TOTP, the six digits
your phone shows, derived from a shared secret and the clock.

The reference implementation is Google's PAM module, which ships a provisioning
tool that generates a secret per user:

```
google-authenticator -t -d -f -r 3 -R 30 -w 3
```

That writes `~/.google_authenticator` owned by the user, containing the secret,
the parameters, and a set of single-use recovery codes. **The secret lives in the
user's home directory**, which has two consequences people meet later: a home
directory on NFS puts every second factor on a file server, and restoring a home
directory from backup restores a secret somebody may have rotated.

Enabling it is one line in the PAM stack, and *where* that line goes is the entire
question:

```
auth required pam_google_authenticator.so nullok
```

**`nullok` during rollout is not optional.** Without it, every user who has not yet
run the provisioning tool is locked out the moment you add the line. With it, users
without a secret pass through and users with one are challenged, so you can enrol
people over a fortnight instead of over a weekend. Removing `nullok` afterwards is
what makes the factor mandatory, and doing that is a decision, not a detail.

<details class="deeper">
<summary>If you already administer Linux: whether the code comes before or after the password, and why SSH keys skip your second factor entirely</summary>

Two ordering questions, and the second one is why most first attempts at this
quietly do nothing.

**Order within the stack decides what an attacker learns.** Put the TOTP line
*before* `pam_unix` and a wrong code ends the exchange before the password is
ever tested, so a guessing attack cannot distinguish a wrong password from a
wrong code, and, more usefully, a stolen password alone produces no signal
about whether it was correct. Put it *after* `pam_unix` and the password is
validated first, which gives cleaner log lines and a better error for the
user, at the cost of confirming to an attacker that they have the password
right. Neither is wrong; the security argument favours first, the support
argument favours second, and a standard that specifies one will say which.

The related knob is which of the two modules prompts. Running TOTP first with
`forward_pass`, and `pam_unix` with `use_first_pass`, lets the user type the code
and password as one string. It works and it confuses people, and the support cost
usually exceeds the benefit.

**The failure that wastes a whole afternoon: SSH public key authentication
does not run the PAM auth stack.** You add the module, restart `sshd`, log in
with your key, and are never asked for a code. Nothing is broken. The auth
stack was never consulted, because the key satisfied authentication before PAM
was reached. Making the second factor real over SSH needs three things in
`sshd_config`:

```
KbdInteractiveAuthentication yes
UsePAM yes
AuthenticationMethods publickey,keyboard-interactive
```

The third line is the one that does the work. It says a session must satisfy
publickey **and then** keyboard-interactive, in that order, which is what turns a
key plus a code into genuine two-factor authentication rather than a key plus a
module nobody calls. The comma means "and"; a space between two lists would mean
"either of these".

**Two more things worth knowing before you deploy it:**

- **Time skew ends the whole scheme.** TOTP is a function of the clock. A machine
  whose NTP client is broken by thirty seconds rejects every valid code, and the
  error the user sees is indistinguishable from a wrong code. `-w 3` widens the
  accepted window to three time steps; `chronyd` actually working is the real fix,
  and checking it is the first diagnostic when "the codes stopped working".
- **Emergency access has to exist before you need it.** The recovery codes printed
  at enrolment, a `Match Address` block in `sshd_config` exempting a management
  network, or console access. A second factor with no break-glass path is an
  outage waiting for a lost phone.

For enterprise deployments the same PAM slot is filled by other modules:
`pam_sss` with a directory service's own OTP support from lesson 38,
`pam_yubico` for hardware tokens, or a vendor RADIUS module. The stack
position and the SSH configuration above are identical in every case; only the
module name changes.

</details>

## What the evidence says, and what you will be asked to configure

Every mechanism above predates the research on whether it helps, and the guidance
has moved a long way from the habits.

**NIST SP 800-63B is the document to know by name.** Its current position, in
short: require a real minimum length and recommend a substantially longer one,
allow very long passwords and every printable character, screen candidates
against lists of commonly used and compromised passwords, and **do not**
impose composition rules or force periodic changes, change on evidence of
compromise instead.

The reasoning is behavioural rather than mathematical. Forced quarterly rotation
produces predictable transformations: `Autumn2026!` follows `Summer2026!`, and an
attacker with one has the next. Composition rules produce `Passw0rd`, which the
transcript above shows being rejected by a dictionary check a composition rule
would have waved straight through. Both controls make passwords worse while
appearing to make them stronger.

**And you will still be asked to configure 90-day expiry**, because plenty of
compliance regimes mandate it, auditors check for it, and "NIST says otherwise" is
not an answer that closes a finding. The two positions coexist like this:

| Requirement | Mechanism | Worth arguing about |
| --- | --- | --- |
| Minimum length | `minlen` in `pwquality.conf` | No. Raise it. |
| One of each class | Negative credits, or `minclass` | Sometimes. Offer length instead. |
| 90-day expiry | `chage -M 90` plus `PASS_MAX_DAYS` | Only with evidence and a sponsor |
| No reuse of last 10 | `pam_pwhistory remember=10` | No. Cheap and harmless. |
| Lock after 5 failures | `pam_faillock deny=5` | Argue about `unlock_time`, not `deny` |
| Screen against breaches | Nothing shipped. See below. | No. This is the one that works. |

**The exam expects the mechanisms regardless of the argument.** Knowing that
`chage -M` sets password expiry is testable; knowing that the control is
contested is what makes you useful afterwards.

### Breach-list checking, and the gap in the base system

The control with the best evidence behind it is the one Linux does not ship.
`dictcheck` uses the cracklib word list, which catches `password` and `Passw0rd`
and does not catch a password that appeared in a breach corpus last year.

Three practical routes:

- **Extend the dictionary.** `cracklib-format` and `cracklib-packer` compile a
  cracklib dictionary from a word list, so a trimmed extract of a public
  breach list can become one. It is coarse, a substring word check rather than
  an exact-match lookup, and better than nothing on an isolated machine.
- **Check at the application layer.** The Have I Been Pwned range API answers
  "has this exact password appeared in a breach" without receiving the password:
  the client sends only a short prefix of the password's hash and gets back every
  matching suffix to compare locally. That is where the control belongs for
  anything user-facing.
- **Push it to the directory.** If accounts come from FreeIPA, Active Directory,
  or LDAP (lesson 38), password policy including breach screening is the
  directory's job, and configuring it per host is the wrong layer.

**For local Linux accounts, be honest that there is no shipped answer.** The
realistic control is to have very few accounts with passwords at all, `passwd
-Sa | awk '$2 == "P"'` should be a short list, and keys and a directory for
the rest.

## Restricted shells, and not being root

The last part of objective 3.4 is not about passwords. It is about how much an
authenticated session can do.

**`nologin` is the right shell for anything that is not a person.** Database
daemons, web servers, and backup agents all need an account and none needs a
login. It is the shipped default for system accounts and worth confirming on any
account you create for software.

**`rbash` is the restricted shell**, and it is worth knowing precisely what it
does, because people deploy it expecting a jail:

```bash
# AlmaLinux 10.2, x86_64
$ su - sam -c "cd /tmp"; echo "rc=$?"; su - sam -c "PATH=/bin"; echo "rc=$?"
-rbash: line 1: cd: restricted
rc=1
-rbash: line 1: PATH: readonly variable
rc=1
```

`cd` refused, `PATH` refused. It also blocks `/` in a command name, output
redirection, `exec`, and `SHELL` and `ENV` assignment. **What it does not do
is contain anything the user can start.** Any program that can run a subshell
(`vi`, `less`, `awk`, `find -exec`, `python`) hands back an unrestricted shell
in one step, so `rbash` is only a boundary if the `PATH` it is given contains
a small, audited set of commands and nothing else.

Treat it as a way to shape a session for a cooperative user, not as a security
control against an uncooperative one. The real boundaries are the ones from
lessons 42 and 44: `sudo` rules that name specific commands, and SELinux confining
what a process may touch regardless of who is running it.

**And the standing rule underneath all of it: do not work as root.** Log in as
yourself, escalate with `sudo` for the command that needs it, and let the
audit trail record who did what. An interactive root session logs one word,
`root`, against every action in it, and `PermitRootLogin no` in `sshd_config`
from lesson 43 is how most sites make that structural rather than optional.

## Across distributions

| | RHEL family | Debian family |
| --- | --- | --- |
| Defaults at creation | `/etc/login.defs` | `/etc/login.defs`, plus `/etc/adduser.conf` |
| PAM file to change | Never edit directly | `/etc/pam.d/common-password` |
| Managed by | `authselect` | `pam-auth-update` |
| Strength module | `pam_pwquality`, installed | `libpam-pwquality`, **not installed by default** |
| Strength defaults live in | `/etc/security/pwquality.conf` | `/etc/security/pwquality.conf` |
| Lockout | `authselect enable-feature with-faillock` | Add `pam_faillock` lines by hand |
| Default hash | yescrypt on 10, SHA-512 on 9 | yescrypt on 13 |

**The row that catches people is the fourth.** A Debian or Ubuntu machine with no
`libpam-pwquality` installed enforces no length or complexity policy whatsoever,
regardless of what `login.defs` says, and the machine reports no error because
there is no module to report one. `dpkg -l libpam-pwquality` is a one-line audit
that finds it.

**The second row is the one that causes silent regressions.** Both families
generate their PAM stack from something else. On the RHEL family the file says so
in its own header; on Debian the mechanism is quieter. Either way, a hand edit is a
change with a hidden expiry date.

## Prove it

```
# What will happen to the next account created here
grep -E '^PASS_|^ENCRYPT_METHOD' /etc/login.defs

# What this account actually has, which is not the same question
chage -l alex
sudo passwd -S alex

# Every account and its password state, in one line
sudo passwd -Sa | awk '{print $2}' | sort | uniq -c

# Anybody with no password at all, which should be nobody
sudo awk -F: '$2 == "" {print $1}' /etc/shadow

# Where strength is enforced, and with what numbers
grep -r pwquality /etc/pam.d/
grep -vE '^\s*(#|$)' /etc/security/pwquality.conf

# Test a policy without setting a password
echo 'candidate-password-here' | pwscore

# Reuse, and lockout state
grep -r pwhistory /etc/pam.d/
sudo faillock --user alex

# And the credential none of the above controls
sudo ls -l ~alex/.ssh/authorized_keys
```

**The first and second commands answer different questions and people run only
the first.** `login.defs` describes the future; `chage -l` describes this account.
An audit that reads the file and not the accounts will pass a machine where every
existing user has `PASS_MAX_DAYS 99999`.

## What trips people up

### 1. Locking the password and calling the account closed

`passwd -l` prefixes the hash with `!`. SSH public key authentication never reads
the hash, so a key in `authorized_keys` still works, `cron` still runs, and open
sessions stay open.

`chage -E 0` is the one that holds regardless of credential, because it is checked
in PAM's account phase after authentication has already succeeded. Do that first,
then everything else.

### 2. Editing a generated PAM file

`/etc/pam.d/system-auth` on the RHEL family carries a header saying it is
generated by `authselect` and will be overwritten. It is telling the truth.
`/etc/pam.d/common-password` on Debian is regenerated by `pam-auth-update`.

Put numbers in `/etc/security/pwquality.conf`, use `authselect enable-feature` for
stack changes, and if you genuinely need a custom stack, make a custom profile
rather than a hand edit.

### 3. Setting the maximum age in the wrong file

It is a default applied by `useradd` at creation. Existing accounts already have
their own copy of that number in `/etc/shadow` and are not consulted again.

Set both: the file for future accounts, `chage` for the ones that exist. Checking
with `chage -l` on a real account rather than reading the file is what catches it.

### 4. `passwd -d` when you meant `passwd -l`

One letter apart, opposite effects. `-l` locks; `-d` deletes the password, leaving
the field empty, which means **no password required** rather than no login.

`sudo awk -F: '$2 == "" {print $1}' /etc/shadow` should return nothing.

### 5. `pam_faillock` counting nothing

The module needs a `preauth` entry before `pam_unix` and an `authfail` entry
after it. With only the first, nothing increments the counter and no lockout
ever happens, and the configuration looks complete on inspection.

`faillock --user someone` after three deliberate failures is the test. If the
table is empty, the `authfail` line is missing.

### 6. Turning on TOTP and never being prompted

SSH public key authentication does not run the PAM auth stack, so the module is
never called. `AuthenticationMethods publickey,keyboard-interactive` in
`sshd_config` is what requires both, and without it you have installed a second
factor that nothing invokes.

## Work it through

The security team hands you a standard. Fourteen characters, one of each class,
changed every 90 days, no reuse of the last ten, locked after five failures. Two
hundred machines, RHEL family, humans authenticate with SSH keys and there is one
legacy application account that uses a password.

Reason it out before reading on.

**Split it by where each line is enforced**, because that decides how many
separate changes this is:

| Line of the standard | Where |
| --- | --- |
| Fourteen characters | `minlen` in `/etc/security/pwquality.conf` |
| One of each class | `minclass = 4`, or four negative credits, same file |
| Every 90 days | `PASS_MAX_DAYS` **and** `chage -M 90` per existing account |
| No reuse of ten | `pam_pwhistory remember=10` in the stack |
| Lock after five | `authselect enable-feature with-faillock`, `deny = 5` |

Five lines of standard, four files, two of which are generated and must not be
edited directly.

**Notice the trap in line one.** `minlen = 14` is fourteen characters
only while every credit is zero or negative. A positive credit, `dcredit = 1`
survives in a great many inherited configuration files, lets a digit buy a
character back, and the real floor drops to thirteen. Grep for the credits
before you report the length as implemented, and write down whether the
standard means fourteen characters or a score of fourteen, because the next
auditor will read it the other way.

Third, the 90-day line is two jobs. `PASS_MAX_DAYS 90` in `login.defs` covers
accounts created from now on. Existing accounts need `chage -M 90` applied
individually, and doing that on all two hundred machines on the same afternoon
sets every password to expire on the same day in November. Stagger it.

Fourth, ask what any of this protects. Humans log in with keys. A key-only
account is not affected by password length, expiry, or history, and the only
account with a real password is the legacy application, which authenticates
non-interactively, so a 90-day expiry on it means the application stops
working in November. That account needs `chage -M -1` and a documented
exception, and the exception is a better outcome than the outage.

Now change one detail. Suppose the machines were Debian rather than RHEL. Line
one and two do nothing at all until `libpam-pwquality` is installed, and no
error is produced anywhere. The module is not in the stack. The lockout line
needs three hand-placed entries instead of one `authselect` feature. Same
standard, substantially different work, which is why "we applied the policy"
needs a per-family verification rather than a per-family assumption.

**And one more.** Suppose an auditor asks you to prove the standard is in
effect. Reading `/etc/security/pwquality.conf` proves what the file says.
`pwscore` proves what the machine does, feed it a thirteen-character password
and a fourteen, and the pair of results is evidence rather than intent.
Likewise `chage -l` on three real accounts beats `grep PASS_MAX_DAYS
/etc/login.defs` in every direction.

The point worth extracting: **a password policy is not one setting and it is
not in one place.** It is a strength check at change time, an ageing record
per account, a history file, a lockout counter, and a default for accounts
that do not exist yet, and each of those has its own file, its own tool, and
its own way of appearing to be configured when it is not. Verify each one
against a real account rather than against the file that is supposed to
control it.

## Try it

Optional, on a machine or container you can break.

1. `grep -E '^PASS_' /etc/login.defs`, then `sudo useradd testy` and
   `chage -l testy`. Confirm the account inherited exactly those numbers.
2. Change `PASS_MAX_DAYS` to 90 in `login.defs` and run `chage -l testy` again.
   Notice nothing changed. Then `sudo chage -M 90 testy` and look again.
3. `sudo passwd testy`, then `sudo grep '^testy:' /etc/shadow` and
   `sudo passwd -S testy`. Identify the algorithm from the `$` prefix.
4. `sudo passwd -l testy`, and look at both again. Find the one character that
   changed. Then `sudo passwd -u testy` and confirm the original hash is back.
5. `sudo passwd -Sa | awk '$2 == "P"'`. That is the list of accounts on the
   machine that a password can log into. Is it as short as you expected?
6. `sudo usermod -s /sbin/nologin testy`, then `sudo su - testy`. Read the message
   and the exit code, and say which of authentication and shell failed.
7. `sudo chage -E 2020-01-01 testy`, then `sudo su - testy` again. Note that the
   error is different, and note *which* PAM phase produced it.
8. `echo 'Passw0rd' | pwscore`, then set `minlen = 15` with all four credits at
   `0` in `/etc/security/pwquality.conf` and score a fourteen-character password
   against a fifteen.

**Verification step.** You have it when somebody says "the account is locked"
and your next question is which of the three states they mean, and you can
name the command that produced each one and the credential each one fails to
stop.

## Check yourself

<details class="qa">
<summary>An account shows <code>sam L 2026-08-08 0 99999 7 -1</code> in <code>passwd -S</code>, and the person logged in this morning. Explain how, and say what you would have run instead.</summary>

**They authenticated with an SSH key.** `L` means the password hash is
prefixed with `!` so no password can match it, and public key authentication
never consults the password hash at all. Locking closes exactly one door.

**`chage -E 0 sam` is what you should have run.** Account expiry is checked in
PAM's *account* phase, which runs after authentication has already succeeded,
whatever credential was used. A key, a password, or a Kerberos ticket all arrive at
the same check and are all refused.

The tempting wrong answer is that somebody unlocked the account and re-locked
it. `passwd -S` would show the same `L` either way, so the state is not
evidence about history, but `last sam` and the `sshd` journal entries are, and
the journal line will say `Accepted publickey`, which settles it in one
command.

The thing you will need next: expiry stops new logins and nothing else. A session
opened before you expired the account stays open, `cron` keeps running their jobs,
and `sudo` rules naming them are still there. `loginctl terminate-user sam`,
`crontab -r -u sam`, and a grep through `/etc/sudoers.d/` are the rest of the job.

</details>

<details class="qa">
<summary>You set <code>minlen = 12</code> in <code>pwquality.conf</code> and a user successfully sets an eleven-character password. Nothing is broken. Why?</summary>

**Because `minlen` is a score, not a length, and character classes earn credit
toward it.** With `dcredit = 1` and `ucredit = 1`, an eleven-character password
containing a digit and a capital scores 11 plus 2, reaches 13, and passes a
`minlen` of 12.

**The fix is to zero the credits**: `dcredit = 0`, `ucredit = 0`, `lcredit =
0`, `ocredit = 0` with `minlen = 12` gives a real twelve-character floor. If
the standard also demands character classes, use negative values, `dcredit =
-1` requires a digit and grants nothing toward the length, or `minclass`,
which is easier to read.

The tempting wrong answer is that the module was not loaded. That is a real
failure and it looks different: with no `pam_pwquality` line, a four-character
password would be accepted too. One eleven-character password passing while short
ones fail is the credit system working as documented.

What you will need next: `enforce_for_root` is off by default, so if *you* set that
password as root with `passwd sam`, the policy warned and did not stop you
regardless of any of the above. Test policy changes as an unprivileged user, or
with `pwscore`, which applies the checks without needing an account at all.

</details>

<details class="qa">
<summary>Name the three states an administrator might mean by "the account is disabled", the command that produces each, and the one credential each fails to stop.</summary>

**Locked**: `passwd -l` or `usermod -L`. Prefixes the hash with `!`. Stops
password authentication. **Does not stop SSH key authentication.**

**Shell disabled**: `usermod -s /sbin/nologin`. Authentication still succeeds;
the shell prints a message and exits. **Does not stop authentication at all**,
and depending on configuration may not stop SFTP, `scp`, or port forwarding,
because none of those needs an interactive shell.

**Expired**: `chage -E 0` or `usermod -e`. Refused in PAM's account phase
after authentication. **Stops every credential**, which is what makes it the
right first move when closing an account.

The tempting wrong answer is that `nologin` is the strongest of the three because
it is the one that produces a visible refusal. It is the weakest: the credential
still works, and the refusal is the shell's decision, not the system's.

What you will need next: none of the three stops what is already running. Sessions,
`cron` jobs, `at` jobs, and systemd user units all survive every one of them, so
closing an account is a sequence rather than a command.

</details>

<details class="qa">
<summary>Your organisation mandates 90-day password rotation and one character of each class. What does current guidance say, and what do you actually do on Monday?</summary>

**Current guidance says both controls make passwords worse.** NIST SP 800-63B
tells verifiers not to impose composition rules and not to require periodic
change except on evidence of compromise, and to screen candidates against
lists of commonly used and compromised passwords instead. The reasoning is
behavioural: forced rotation produces `Summer2026!` then `Autumn2026!`, and
composition rules produce `Passw0rd`, which the `pwscore` transcript in this
topic shows being rejected by a dictionary check that a composition rule would
have approved.

**What you do on Monday is implement the standard**, because an auditor's finding
is not closed by citing a document, and because you were asked. `chage -M 90` on
existing accounts, `PASS_MAX_DAYS 90` in `login.defs` for new ones, and
`minclass = 4` or negative credits for the classes.

The tempting wrong answer is to implement what the evidence supports and document
the deviation. That is a legitimate outcome, but it is a *negotiated* one: it needs
the standard's owner to agree in advance, in writing, with a compensating control
named. An undocumented deviation found by a scanner is a finding regardless of how
correct it was.

What you will need next: the argument that usually wins is not "NIST says so", it
is offering something better in exchange. Longer minimum length, breach-list
screening, and a second factor are each more effective than rotation, and a trade
is a much easier conversation than a refusal.

</details>

<details class="qa">
<summary>You add <code>pam_google_authenticator.so</code> to the auth stack, restart <code>sshd</code>, log in with your key, and are never asked for a code. What happened, and what else should you check before declaring MFA deployed?</summary>

**SSH public key authentication does not run the PAM auth stack.** The key
satisfied authentication before PAM was consulted, so the module was never called.
Nothing is misconfigured in PAM.

**`AuthenticationMethods publickey,keyboard-interactive` in `sshd_config` is the
fix**, along with `KbdInteractiveAuthentication yes` and `UsePAM yes`. The comma
means both, in order: the key, and then the code. A space between two lists would
mean either one, which is not two-factor authentication.

The tempting wrong answer is to disable key authentication so that the password
and TOTP path is used. That trades a strong credential for a weaker one to make a
second factor visible, and leaves you with password plus code where you could have
had key plus code.

Two things to check before declaring it done. **`nullok`**, with it, everybody
who has not yet enrolled passes straight through, which is right during a
rollout and wrong afterwards, and removing it is a separate deliberate step.
And **the clock**: TOTP is a function of time, so a host with a broken NTP
client rejects every valid code with an error indistinguishable from a wrong
one. Check `chronyd` before you debug anything else.

</details>

## References

- [chage(1)](https://man7.org/linux/man-pages/man1/chage.1.html) - Linux man-pages project. Accessed 2026-08-08.
- [passwd(1)](https://man7.org/linux/man-pages/man1/passwd.1.html) - Linux man-pages project. Accessed 2026-08-08.
- [shadow(5)](https://man7.org/linux/man-pages/man5/shadow.5.html) - Linux man-pages project. Accessed 2026-08-08.
- [login.defs(5)](https://man7.org/linux/man-pages/man5/login.defs.5.html) - Linux man-pages project. Accessed 2026-08-08.
- [pwquality.conf(5)](https://manpages.debian.org/trixie/libpwquality-common/pwquality.conf.5.en.html) - Debian manpages. Accessed 2026-08-08.
- [pam_pwhistory(8)](https://man7.org/linux/man-pages/man8/pam_pwhistory.8.html) - Linux man-pages project. Accessed 2026-08-08.
- [pam_faillock(8)](https://man7.org/linux/man-pages/man8/pam_faillock.8.html) - Linux man-pages project. Accessed 2026-08-08.
- [NIST SP 800-63B, Digital Identity Guidelines](https://pages.nist.gov/800-63-4/sp800-63b.html) - National Institute of Standards and Technology. Accessed 2026-08-08.
- [google-authenticator-libpam](https://github.com/google/google-authenticator-libpam) - Google. Accessed 2026-08-08.
- [Pwned Passwords](https://haveibeenpwned.com/Passwords) - Have I Been Pwned. Accessed 2026-08-08.

Captured output came from AlmaLinux 10.2 containers with `shadow-utils`, `passwd`,
`libpwquality`, and `authselect` installed, using an account whose password hash
was set from a fixed value so the locked and unlocked transcripts can be compared
character by character. The expired-account transcript is included precisely
because it does *not* show a refusal: `su` run by root short-circuits the account
phase on that distribution, and showing the false negative is more useful than
hiding it.

Blocks without a distribution and architecture header are illustrative. The PAM
stack fragments, the `sshd_config` lines, the TOTP enrolment command, and the
offboarding sequence are shown as they would be written rather than as captured
output, because a container has no `sshd`, no second machine to authenticate from,
and no interactive login to prompt at.
