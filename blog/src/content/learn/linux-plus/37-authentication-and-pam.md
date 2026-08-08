---
title: "You typed a new password and something you never configured said no"
description: "Every login and every password change on this machine is decided by a stack of small modules read top to bottom, in a file named for the service. The four module types, the control flags, how a stack short-circuits, and how to change one without locking everybody out."
track: "linux-plus"
level: "deep"
order: 380
objectives:
  - "Separate authentication, authorization, and accounting as three different questions"
  - "Trace a PAM stack top to bottom and predict what it returns"
  - "Choose between required, requisite, sufficient, and optional, and place them in the right order"
  - "Change a PAM configuration without locking every account out of the machine"
prerequisites: ["users-root-and-sudo", "account-files-and-attributes"]
tags: ["linux", "linux-plus", "pam", "authentication", "security"]
updated: 2026-08-08
draft: false
examObjectives:
  - exam: "xk0-006"
    domain: "3.0"
    objective: "3.1"
sources:
  - title: "pam(8)"
    url: "https://man7.org/linux/man-pages/man8/pam.8.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-08
    tier: 1
  - title: "pam.conf(5)"
    url: "https://man7.org/linux/man-pages/man5/pam.conf.5.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-08
    tier: 1
  - title: "pam_unix(8)"
    url: "https://man7.org/linux/man-pages/man8/pam_unix.8.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-08
    tier: 1
  - title: "pam_faillock(8)"
    url: "https://man7.org/linux/man-pages/man8/pam_faillock.8.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-08
    tier: 1
  - title: "pam_wheel(8)"
    url: "https://man7.org/linux/man-pages/man8/pam_wheel.8.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-08
    tier: 1
  - title: "pam_pwquality(8)"
    url: "https://manpages.debian.org/trixie/libpam-pwquality/pam_pwquality.8.en.html"
    publisher: "Debian Project"
    accessed: 2026-08-08
    tier: 1
  - title: "nsswitch.conf(5)"
    url: "https://man7.org/linux/man-pages/man5/nsswitch.conf.5.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-08
    tier: 1
  - title: "polkit(8)"
    url: "https://manpages.debian.org/trixie/polkitd/polkit.8.en.html"
    publisher: "Debian manpages"
    accessed: 2026-08-08
    tier: 1
  - title: "Configuring authentication and authorization in RHEL"
    url: "https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/10/html/configuring_authentication_and_authorization_in_rhel/index"
    publisher: "Red Hat"
    accessed: 2026-08-08
    tier: 1
symptoms:
  - symptom: "BAD PASSWORD: The password is shorter than 8 characters"
    anchor: "who-decides-your-password-is-good-enough"
  - symptom: "Authentication token manipulation error"
    anchor: "3-authentication-token-manipulation-error"
  - symptom: "Permission denied running su as a user who is not in wheel"
    anchor: "include-substack-and-the-shared-stack"
  - symptom: "The account is locked due to failed logins"
    anchor: "locking-an-account-after-failed-attempts"
---

> **Before you read.** You run `passwd`, type a new password, and get back
> `BAD PASSWORD: The password is shorter than 8 characters`.
>
> You did not configure that. There is no minimum length in `/etc/passwd` and none
> in `/etc/shadow`. The `passwd` command is a small program for writing one field
> in one file, and it does not contain a dictionary, a length policy, or an opinion.
>
> **So which program made that decision, and where is it written down?**

Not `passwd`. `passwd` asked something else, and repeated the answer.

Every program that establishes who you are — `login`, `sshd`, `su`, `sudo`, `passwd`,
`cron`, a screen locker — asks the same library the same way, and that library reads a
file named after the program asking. The file lists small modules to run in order, and
one of them has opinions about password length. That indirection is **PAM**, the
Pluggable Authentication Modules system, and it is why one file can change how every
login on the machine behaves. In both directions.

### Some words you will need

<dl class="terms">
<dt>authentication</dt>
<dd>Establishing that you are who you claim to be. A password, a key, a token, a fingerprint.</dd>
<dt>authorization</dt>
<dd>Given that you are who you say, deciding whether you may do a particular thing. A separate question, answered by separate machinery.</dd>
<dt>accounting</dt>
<dd>Recording what happened: who logged in, from where, when, and what they did.</dd>
<dt>PAM</dt>
<dd>Pluggable Authentication Modules. A library, <code>libpam</code>, that programs call instead of reading password files themselves.</dd>
<dt>module</dt>
<dd>A shared object such as <code>pam_unix.so</code> that answers one narrow question. It returns success or failure and nothing else.</dd>
<dt>stack</dt>
<dd>The ordered list of modules for one service and one module type. Read top to bottom, like a program.</dd>
<dt>control flag</dt>
<dd>The middle column of a stack line. It decides what a module's success or failure does to the rest of the stack.</dd>
<dt>service file</dt>
<dd>A file in <code>/etc/pam.d</code> named for the program that will use it. <code>/etc/pam.d/sshd</code> is consulted when <code>sshd</code> authenticates somebody.</dd>
</dl>

## What breaks without this

**You cannot enforce a password policy, or explain the one already in force.**
Length, complexity, history, and lockout are all module settings, and none of them
live in the account files you already know.

**A restriction you carefully added never runs.** A line below a module that
short-circuits the stack is unreachable code, and nothing warns you. The
configuration looks correct in review and does nothing in production.

**Your change disappears at the next package update**, because on a RHEL-family
machine the file you edited is generated from somewhere else and says so in its
first three lines.

**You lock every account out of the machine, including root.** A broken shared stack
refuses console logins, SSH, `su`, and `sudo` at the same moment, and the recovery is
a rescue boot.

## Three questions that get run together

"Auth" is used for two different things in conversation, and there are three:

| Question | The proper name | Answered by |
| --- | --- | --- |
| Are you who you claim to be? | **Authentication** | PAM's `auth` stack, SSH keys, Kerberos |
| May you do this particular thing? | **Authorization** | Permissions, `sudoers`, polkit, PAM's `account` stack |
| What did you do, and when? | **Accounting** | `wtmp`, `btmp`, the journal, `auditd`, PAM's `session` stack |

**They fail differently and you diagnose them differently.** A wrong password is an
authentication failure. A correct password from a user whose account expired last Friday
is an *authorization* failure: the identity was proved and the account may not be used.
Different log lines, different fixes, and "she cannot log in" tells you neither. PAM
touches all three, which is why the split gets blurred, but what it does *not* do is
decide whether you may restart a service or read a file.

## What happens when you log in

<figure class="learn-figure">
<svg viewBox="0 0 720 320" role="img" aria-labelledby="pam-title pam-desc" style="width:100%;height:auto;">
  <title id="pam-title">How a program hands authentication to PAM and which stacks run</title>
  <desc id="pam-desc">A program such as su is linked against the libpam library. Instead of reading the password files itself, it tells libpam which service name it is. The library opens the matching file in /etc/pam.d, in this case /etc/pam.d/su, and reads it top to bottom. The file is divided into four stacks by module type. The auth stack establishes identity. The account stack decides whether the account may be used at all. The password stack runs only when a password is being changed. The session stack runs before and after the session itself. The calling program chooses which of the four stacks to run, which is why a program that only changes passwords has a file containing only password lines.</desc>
  <g font-family="ui-monospace, monospace">
    <rect x="16" y="118" width="150" height="70" rx="5" fill="currentColor" fill-opacity="0.12" stroke="currentColor" stroke-opacity="0.4"/>
    <text x="91" y="142" text-anchor="middle" font-size="12" fill="currentColor">su</text>
    <text x="91" y="160" text-anchor="middle" font-size="9.5" fill="currentColor" fill-opacity="0.65">linked against</text>
    <text x="91" y="175" text-anchor="middle" font-size="9.5" fill="currentColor" fill-opacity="0.8">libpam</text>
    <rect x="204" y="118" width="176" height="70" rx="5" fill="currentColor" fill-opacity="0.07" stroke="currentColor" stroke-opacity="0.3"/>
    <text x="292" y="142" text-anchor="middle" font-size="11.5" fill="currentColor">/etc/pam.d/su</text>
    <text x="292" y="160" text-anchor="middle" font-size="9.5" fill="currentColor" fill-opacity="0.65">one file per service</text>
    <text x="292" y="175" text-anchor="middle" font-size="9.5" fill="currentColor" fill-opacity="0.65">read top to bottom</text>
    <rect x="432" y="18" width="180" height="52" rx="5" fill="currentColor" fill-opacity="0.07" stroke="currentColor" stroke-opacity="0.3"/>
    <text x="522" y="40" text-anchor="middle" font-size="11.5" fill="currentColor">auth</text>
    <text x="522" y="57" text-anchor="middle" font-size="9.5" fill="currentColor" fill-opacity="0.65">prove who you are</text>
    <rect x="432" y="88" width="180" height="52" rx="5" fill="currentColor" fill-opacity="0.07" stroke="currentColor" stroke-opacity="0.3"/>
    <text x="522" y="110" text-anchor="middle" font-size="11.5" fill="currentColor">account</text>
    <text x="522" y="127" text-anchor="middle" font-size="9.5" fill="currentColor" fill-opacity="0.65">may it be used at all</text>
    <rect x="432" y="158" width="180" height="52" rx="5" fill="currentColor" fill-opacity="0.04" stroke="currentColor" stroke-opacity="0.22" stroke-dasharray="4 3"/>
    <text x="522" y="180" text-anchor="middle" font-size="11.5" fill="currentColor" fill-opacity="0.7">password</text>
    <text x="522" y="197" text-anchor="middle" font-size="9.5" fill="currentColor" fill-opacity="0.55">only when changing one</text>
    <rect x="432" y="228" width="180" height="52" rx="5" fill="currentColor" fill-opacity="0.07" stroke="currentColor" stroke-opacity="0.3"/>
    <text x="522" y="250" text-anchor="middle" font-size="11.5" fill="currentColor">session</text>
    <text x="522" y="267" text-anchor="middle" font-size="9.5" fill="currentColor" fill-opacity="0.65">before and after</text>
    <text x="628" y="44" font-size="9.5" fill="currentColor" fill-opacity="0.65">1</text>
    <text x="628" y="114" font-size="9.5" fill="currentColor" fill-opacity="0.65">2</text>
    <text x="628" y="184" font-size="9.5" fill="currentColor" fill-opacity="0.55">3</text>
    <text x="628" y="254" font-size="9.5" fill="currentColor" fill-opacity="0.65">4</text>
    <text x="16" y="298" font-size="9.5" fill="currentColor" fill-opacity="0.65">The calling program chooses which stacks to run, which is why a file can contain only one of them.</text>
  </g>
  <g stroke="currentColor" stroke-opacity="0.45" fill="none" stroke-width="1.2">
    <path d="M166 153 L200 153 M194 149 L201 153 L194 157"/>
    <path d="M380 153 L406 153 L406 44 L428 44 M422 40 L429 44 L422 48"/>
    <path d="M406 153 L406 114 L428 114 M422 110 L429 114 L422 118"/>
    <path d="M406 153 L428 153 L428 184 M424 178 L428 185 L432 178" stroke-dasharray="4 3"/>
    <path d="M406 153 L406 254 L428 254 M422 250 L429 254 L422 258"/>
  </g>
</svg>
<figcaption>The service name picks the file. The file is four stacks. The program decides which of them run.</figcaption>
</figure>

The programs really are linked against the library:

```bash
# AlmaLinux 10.2, x86_64
$ ldd /usr/bin/su | grep pam
	libpam.so.0 => /lib64/libpam.so.0 (0x0000ffff8851c000)
	libpam_misc.so.0 => /lib64/libpam_misc.so.0 (0x0000ffff88515000)
```

`su` does not open `/etc/shadow`. It calls `libpam`, which decides what opening
`/etc/shadow` would even mean here: a local file, a directory server, a smart card.
The sequence for an interactive login:

1. The program collects a username and tells the library which **service** it is.
   `sshd` says `sshd`, `su` says `su`, `passwd` says `passwd`.
2. The library opens `/etc/pam.d/<service>` and reads it.
3. The program calls for authentication. The **`auth`** stack runs.
4. The program calls for account validation. The **`account`** stack runs.
5. If the account stack came back saying the token has expired, the **`password`**
   stack runs to change it, right there in the middle of the login.
6. The program opens a session. The **`session`** stack runs.
7. At logout, the session stack runs again, closing.

**Step 5 is the one that surprises people.** "You are required to change your password
immediately" is not `passwd` running; it is the same login process running a different
stack, because the account stack said so.

**And the safety rule that governs everything below.** Most of those programs share a
file, so a stack that refuses everybody refuses the console, SSH, `su`, and `sudo` at
once, including the session you would fix it from. Full procedure in the panel after the
control flags.

## A file for every service

The directory is small and nearly every file in it is named for a program:

```bash
# AlmaLinux 10.2, x86_64
$ ls /etc/pam.d
chfn
chsh
config-util
fingerprint-auth
login
other
passwd
password-auth
postlogin
remote
runuser
runuser-l
smartcard-auth
su
su-l
switchable-auth
system-auth
```

**The name is the interface.** There is no registry and no build step, which is why
writing `/etc/pam.d/myapp` is all it takes to give your own program a PAM configuration,
and why a typo in a filename produces a service with no configuration rather than an
error. (The older single `/etc/pam.conf` is ignored whenever `/etc/pam.d` exists.)
**`other` is the fallback** for a service name with no matching file, and on the RHEL
family it denies all four module types with `pam_deny.so`, so an unknown service fails
closed.

**The files arrive with the packages that need them.** That listing is an AlmaLinux
container with no SSH server and no `sudo` installed. The same directory on a Fedora
CoreOS machine that runs both:

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ ls /etc/pam.d/ | head -20; echo "--- how many ---"; ls /etc/pam.d/ | wc -l
chfn
chsh
config-util
fingerprint-auth
login
other
passwd
password-auth
postlogin
remote
runuser
runuser-l
smartcard-auth
sshd
sssd-shadowutils
su
su-l
sudo
sudo-i
switchable-auth
--- how many ---
22
```

`sshd`, `sudo`, and `sudo-i` are here and absent there, because `openssh-server` ships
`/etc/pam.d/sshd` and `sudo` ships `/etc/pam.d/sudo`. Removing a package removes its
stack file, and reinstalling one quietly restores a file somebody had customised.

## The four module types

Every line begins with one of four words, and that word says which question is being
answered:

| Type | The question | Runs when | Modules you will meet |
| --- | --- | --- | --- |
| `auth` | Can you prove you are this user? | Logging in, `su`, `sudo`, unlocking | `pam_unix`, `pam_rootok`, `pam_wheel`, `pam_faillock`, `pam_sss` |
| `account` | May this account be used, now, from here? | Immediately after `auth` | `pam_unix`, `pam_access`, `pam_time`, `pam_succeed_if` |
| `password` | Is this new authentication token acceptable, and store it | Only when a password is being changed | `pam_pwquality`, `pam_pwhistory`, `pam_unix` |
| `session` | Set up and tear down whatever a session needs | Around the session, both ends | `pam_limits`, `pam_systemd`, `pam_mkhomedir`, `pam_keyinit` |

**The four are independent stacks that happen to live in one file.** `pam_unix` checks
the hash in the `auth` stack, checks expiry in the `account` stack, writes a new hash in
the `password` stack, and logs session open and close in the `session` stack: one shared
object, four questions, and it may answer one with success and another with failure.

<details class="predict">
<summary>The `passwd` command only ever changes a password. It never logs anybody in and never opens a session. Given that the calling program chooses which stacks to run, what would you expect `/etc/pam.d/passwd` to contain?</summary>

```bash
# AlmaLinux 10.2, x86_64
$ cat /etc/pam.d/passwd
#%PAM-1.0
# This tool only uses the password stack.
password   substack	system-auth
-password   optional	pam_gnome_keyring.so use_authtok
password   substack	postlogin
```

</details>

**Only `password` lines, and the file says so in a comment.** A program that never
authenticates anybody needs no `auth` stack. The `-` on the middle line is not a typo;
it is covered with the flags.

## Modules are shared objects in a directory

A module is a `.so` file, and there are a lot of them:

```bash
# AlmaLinux 10.2, x86_64
$ ls /usr/lib64/security | head -20
pam_access.so
pam_canonicalize_user.so
pam_cap.so
pam_chroot.so
pam_debug.so
pam_deny.so
pam_echo.so
pam_env.so
pam_exec.so
pam_faildelay.so
pam_faillock.so
pam_filter
pam_filter.so
pam_ftp.so
pam_group.so
pam_issue.so
pam_keyinit.so
pam_lastlog.so
pam_limits.so
pam_listfile.so
```

The library `dlopen`s the file named on the line, calls the entry point for the module
type, and takes back a return code. **A module returns success or failure and nothing
else**: no partial credit, no explanation to the stack, and anything it wants to tell a
human goes to the log. Debian keeps the same shared objects under a multiarch path,
`/usr/lib/x86_64-linux-gnu/security`, which is why a stack line names `pam_unix.so` and
never a path. The ones worth recognising:

| Module | Does |
| --- | --- |
| `pam_unix` | The traditional local check: hashes in `/etc/shadow`, expiry, and writing new hashes |
| `pam_deny` | Always fails. Used as the last line of a stack, so failure is explicit |
| `pam_permit` | Always succeeds. Dangerous in the wrong stack, useful in a scratch service |
| `pam_rootok` | Succeeds if the calling process is already uid 0 |
| `pam_wheel` | Restricts a service to members of a group, usually `wheel` |
| `pam_pwquality` | Judges a proposed new password |
| `pam_faillock` | Counts failures and locks the account |
| `pam_env` | Sets environment variables from `/etc/environment` and `pam_env.conf` |
| `pam_limits` | Applies `/etc/security/limits.conf` to the session |
| `pam_access` | Allows or denies by user, group, and origin, from `/etc/security/access.conf` |
| `pam_succeed_if` | Succeeds if a condition about the user holds. Used for jumps |
| `pam_mkhomedir` | Creates a home directory on first login |
| `pam_systemd` | Registers the session with `logind` |

**`pam_deny` and `pam_permit` look like jokes and are neither.** They are how a stack says
"and otherwise, no" and "and otherwise, yes", which matters once the flags below turn a
stack into something with control flow.

<details class="deeper">
<summary>If you already administer Linux: nsswitch and PAM are two different lookups, and conflating them costs an afternoon</summary>

Both are configured per machine, both are involved in logging in, and they answer
different questions. **NSS answers "does this user exist, and what are their numbers":**
`getpwnam()`, `getgrnam()`, `getspnam()`, uid, gid, home directory, shell, groups.
`/etc/nsswitch.conf` lists, per database, which sources to consult and in what order, so
`passwd: files sss` means look in `/etc/passwd`, then ask SSSD. **PAM answers "can they
prove it, and may they log in",** and is called only by programs that authenticate.
Nothing about `ls -l` showing a username involves PAM.

**One command separates them**, because `getent` goes through NSS and never touches PAM:

```
getent passwd alice
```

- **A line comes back and login still fails.** NSS is fine, the uid resolves, and the
  problem is PAM or the credential itself.
- **Nothing comes back.** NSS is the problem and PAM never got a chance. Her name shows
  as a bare number in `ls -l`, `chown alice` fails, and no stack editing helps.

**Joining a directory service requires both**, which is where the confusion is born.
`sss` has to appear in `nsswitch.conf` so the users exist, and `pam_sss.so` in the PAM
stacks so they can authenticate. Do one and not the other and you get a machine where
`id alice` works perfectly and she cannot log in, or one where she authenticates and lands
in a shell with no home directory and a numeric prompt. The clue that they belong together
is on disk: the directory holding the generated PAM stacks on a RHEL-family machine also
holds a generated `nsswitch.conf`, written by the same tool.

A third thing can be wrong that neither answers: field two of `/etc/shadow` from lesson
28, where a leading `!` means the password is locked. That is `pam_unix` in the `auth`
stack.

</details>

## The control flags

Here is the file nearly every service on a RHEL-family machine ends up using. Thirteen
module lines, and between them every control flag you need:

```bash
# AlmaLinux 10.2, x86_64
$ cat /etc/pam.d/system-auth
# Generated by authselect
# Do not modify this file manually, use authselect instead. Any user changes will be overwritten.
# You can stop authselect from managing your configuration by calling 'authselect opt-out'.
# See authselect(8) for more details.

auth        required                                     pam_env.so
auth        required                                     pam_faildelay.so delay=2000000
auth        sufficient                                   pam_unix.so nullok
auth        required                                     pam_deny.so

account     required                                     pam_unix.so

password    requisite                                    pam_pwquality.so
password    sufficient                                   pam_unix.so yescrypt shadow nullok use_authtok
password    required                                     pam_deny.so

session     optional                                     pam_keyinit.so revoke
session     required                                     pam_limits.so
-session    optional                                     pam_systemd.so
session     [success=1 default=ignore]                   pam_succeed_if.so service in crond quiet use_uid
session     required                                     pam_unix.so
```

The columns are **type**, **control flag**, **module**, then arguments. The flag decides
what a module's result does to everything below it:

| Flag | On success | On failure |
| --- | --- | --- |
| `required` | Continue | Remember the failure, **continue anyway**, fail the stack at the end |
| `requisite` | Continue | **Return immediately.** Nothing below runs |
| `sufficient` | **Return success immediately**, unless an earlier `required` already failed | Ignore it and continue |
| `optional` | Continue | Continue. The result is ignored unless it is the only module in the stack |

**`required` and `requisite` differ in *when* the failure is reported, not whether it is.**
`required` keeps going, so the user cannot tell from the prompts or the timing which check
refused them, and so modules further down still run — which matters when one of them is
what records the failed attempt. `requisite` stops dead, which is what you want when
continuing would hand a secret to something that should not receive it.

**`sufficient` is the one that changes program flow.** Its success ends the stack there
and then. That is how "any one of these will do" is expressed, and it is the single most
common way a configuration comes to contain a restriction that restricts nothing.
**`optional` is weaker than it sounds:** its result counts only when no other module
returned a definite success or failure, so it is for modules that do work rather than
modules that decide.

Two more pieces of syntax are on that page. **The leading `-` on `-session optional
pam_systemd.so`** attaches to the *type*, not the flag, and means: if this module is not
installed, skip the line silently instead of logging an error. It is how one stack ships
to machines with and without a component.

**The bracket form** on the `pam_succeed_if` line is the general case the named flags are
shorthand for: `returncode=action` pairs, with `default=` catching everything unnamed. The
actions are `ignore`, `ok`, `bad`, `die`, `done`, `reset`, and **a number**, meaning "skip
the next N modules". So that line says *if the service running this stack is `crond`, jump
over one module*, and the module jumped over is `session required pam_unix.so`, which
writes a session record — so cron does not add a login record every minute. The named
flags are defined in terms of it, which is the clearest way to see what they do:

| Shorthand | Is exactly |
| --- | --- |
| `required` | `[success=ok new_authtok_reqd=ok ignore=ignore default=bad]` |
| `requisite` | `[success=ok new_authtok_reqd=ok ignore=ignore default=die]` |
| `sufficient` | `[success=done new_authtok_reqd=done default=ignore]` |
| `optional` | `[success=ok new_authtok_reqd=ok default=ignore]` |

`bad` marks the stack failed and keeps going. `die` marks it failed and returns at
once. That one word is the whole difference between `required` and `requisite`.

<details class="predict">
<summary>Here is the same shared stack on a different machine, filtered with `grep -E "^(auth|account|password|session)"`. Twelve lines come back rather than thirteen. Given what the leading `-` does to a line, which one is missing from this output, and does its absence prove it is missing from the file?</summary>

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ grep -E "^(auth|account|password|session)" /etc/authselect/system-auth
auth        required                                     pam_env.so
auth        required                                     pam_faildelay.so delay=2000000
auth        sufficient                                   pam_unix.so nullok
auth        required                                     pam_deny.so
account     required                                     pam_unix.so
password    requisite                                    pam_pwquality.so
password    sufficient                                   pam_unix.so yescrypt shadow nullok use_authtok
password    required                                     pam_deny.so
session     optional                                     pam_keyinit.so revoke
session     required                                     pam_limits.so
session     [success=1 default=ignore]                   pam_succeed_if.so service in crond quiet use_uid
session     required                                     pam_unix.so
```

</details>

**`-session optional pam_systemd.so` is missing**, because the pattern anchors on
`^session` and that line begins with a hyphen, so the output cannot tell you whether the
line is in the file. **A pattern that looks like it matches "every module line" misses
every optional-if-absent line**, and those are exactly the lines that differ between
distributions and releases: a naive regular expression under-reports, and what it
under-reports is what the vendor changed.

<details class="deeper">
<summary>If you already administer Linux: the order trap, and testing a stack change without needing a rescue boot</summary>

The order trap has one shape and it appears in every real deployment sooner or later.

```
auth  sufficient  pam_unix.so
auth  required    pam_wheel.so use_uid
```

That restricts nothing. `pam_unix` succeeds for anybody with the right password,
`sufficient` returns on the spot, and `pam_wheel` never executes. The file reviews
perfectly — right module, right flag — and the control is absent. **A restriction has to
sit above every `sufficient` line that could return before it.** The same trap in a
subtler dress: adding `auth sufficient pam_sss.so` at the top of a stack with a
`pam_faillock preauth` line further down. Directory users now bypass local lockout
entirely, and the change that did it looks like an addition rather than a removal.

**Now the part that keeps you employed.** A shared stack serves console login, SSH,
`su`, and `sudo` at once, so breaking it closes every route in, including the one you
would use to undo the edit. The procedure:

1. **Copy the file first.** `cp -a /etc/pam.d/system-auth /root/system-auth.orig`.
2. **Keep a root shell open** in one terminal. Do not close it, do not let it time out,
   do not `exit` out of habit. PAM is not consulted again for a shell that already
   exists, which is the only reason the safety shell works.
3. **Test from a second, separate session**: a new SSH connection or another console.
   Then as an ordinary user, then as a user who should now be refused.
4. **Watch the log while you test.** `journalctl -f`, or `tail -f /var/log/secure` on
   the RHEL family. PAM logs which module refused, and that is the only place the
   reason exists.
5. **Only then close the safety session.**

Two things make step 3 fail in ways people misread. A module that cannot be loaded at
all — wrong filename, wrong architecture directory, package not installed — is a failure
of that line, so a `required` line naming a module that does not exist denies every
login while looking like a spelling mistake. And a syntax error in the bracket form is
treated as a module failure too, not as a parse error you hear about at edit time.
**There is no `pam -t` and no equivalent of `visudo`.** `pamtester`, where it is
packaged, is the nearest thing: `pamtester sshd alice authenticate` exercises a stack
without a login, which turns a risky test into a cheap one.

If a machine is already broken: boot with `rd.break` or into the emergency target from
lesson 09, or attach the disk elsewhere, and restore the copy from step one. Ten minutes
if the copy exists, considerably longer if it does not.

</details>

## Tracing a stack top to bottom

The whole skill is reading a stack the way you would read a small program. Take the four
`auth` lines from the shared file above:

```
auth        required     pam_env.so
auth        required     pam_faildelay.so delay=2000000
auth        sufficient   pam_unix.so nullok
auth        required     pam_deny.so
```

**With the right password:** the first two succeed. `pam_faildelay` only registered that
a failure should be reported late — `delay=2000000` is microseconds, so two seconds,
jittered by up to a quarter either way. `pam_unix` hashes what was typed with the stored
salt from lesson 28 and matches, and because it is `sufficient` **the stack returns
success immediately** and `pam_deny` never runs. **With the wrong password:** `pam_unix`
fails, `sufficient` discards the failure, and evaluation falls through to `pam_deny`,
which always fails and is `required`. The stack returns failure, two seconds late.

Both traces on a real machine, an ordinary user running `su` with the wrong password and
then the right one. The plumbing exists only because `su` insists on reading a password
from a terminal rather than a pipe:

```bash
# AlmaLinux 10.2, x86_64
$ (sleep 2; echo hunter2) | runuser -u tux -- script -qec "su - root -c id" /dev/null; echo "rc=$?"
Password: 
su: Authentication failure
rc=1
```

```bash
# AlmaLinux 10.2, x86_64
$ (sleep 2; echo correcthorse) | runuser -u tux -- script -qec "su - root -c id" /dev/null; echo "rc=$?"
Password: 
uid=0(root) gid=0(root) groups=0(root)
rc=0
```

Note what `su` does *not* say when it fails. It received one return code and has no idea
whether the password was wrong, the account was locked, or a module failed to load. That
distinction exists in `/var/log/secure` and nowhere else, which is why the log window is
part of the testing procedure rather than an afterthought.

**`pam_deny` at the foot of a `sufficient` chain is a deliberate idiom.** The chain reads
"try local users, or the directory, or the smart card"; `pam_deny` is the `else` that makes
the refusal explicit instead of depending on what a stack does when it runs off the end.
Every generated stack on a RHEL machine ends this way.

## Who decides your password is good enough

Back to the question at the top. The `password` stack from the same file:

```
password    requisite    pam_pwquality.so
password    sufficient   pam_unix.so yescrypt shadow nullok use_authtok
password    required     pam_deny.so
```

**`pam_pwquality` is the module with the opinions**, and `BAD PASSWORD` is its message.
It reads `/etc/security/pwquality.conf`, which ships with almost everything commented
out so the built-in defaults apply:

| Setting | Controls |
| --- | --- |
| `minlen` | Minimum length, adjusted by the credit settings below |
| `dcredit`, `ucredit`, `lcredit`, `ocredit` | Length credit for digits, upper case, lower case, other. A negative value makes that class **required** |
| `minclass` | How many of the four character classes must appear |
| `maxrepeat` | Longest run of the same character |
| `difok` | How many characters must differ from the old password |
| `dictcheck` | Whether to run the new password past a dictionary |
| `retry` | How many attempts before giving up |
| `enforce_for_root` | Whether root is subject to any of this |

**`enforce_for_root` is off by default**, which explains a confusing observation: root
sets a three-character password, is told it is a `BAD PASSWORD`, and proceeds anyway. The
check ran and the complaint is real; the module simply does not return an error for root
unless you ask it to.

**The `requisite` on that line is doing security work.** With `required` instead, the bad
password fails `pam_pwquality`, the failure is remembered, and *evaluation continues* — so
`pam_unix` runs, takes the token, and writes it to `/etc/shadow`. The stack then reports
failure, the user sees an error, and the password has already been changed to the bad one.

**Each argument on the `pam_unix` line carries weight.** `yescrypt` is the hashing
algorithm, the same one behind the `$y$` prefix in lesson 28. `shadow` writes to
`/etc/shadow` rather than `/etc/passwd`. `use_authtok` means "use the password the previous
module already collected rather than prompting again", which is why `pam_pwquality` has to
sit above it. `nullok` permits a change from an empty existing password — and on an `auth`
line the same word permits *logging in* to an account whose password field is empty, which
is a finding in any audit and worth grepping for on a machine you inherit.

## include, substack, and the shared stack

No service file repeats those thirteen lines. They pull them in. `su` is the most
instructive file in the directory:

```bash
# AlmaLinux 10.2, x86_64
$ cat /etc/pam.d/su
#%PAM-1.0
auth		required	pam_env.so
auth		sufficient	pam_rootok.so
# Uncomment the following line to implicitly trust users in the "wheel" group.
#auth		sufficient	pam_wheel.so trust use_uid
# Uncomment the following line to require a user to be in the "wheel" group.
#auth		required	pam_wheel.so use_uid
auth		substack	system-auth
auth		include		postlogin
account		sufficient	pam_succeed_if.so uid = 0 use_uid quiet
account		include		system-auth
password	include		system-auth
session		include		system-auth
session		include		postlogin
session		optional	pam_xauth.so
```

**`auth sufficient pam_rootok.so`** is why root is never asked for a password when running
`su`: the module succeeds for uid 0 and `sufficient` ends the stack before any password is
collected. It is `sufficient` and not `required` on purpose — as `required` it would mean
*only* uid 0 may use `su` at all.

**The two commented lines are the classic exercise, and their flags differ on purpose.**
Uncommenting the **second** restricts `su` to `wheel`: a non-member fails a `required`
module and is refused, and a member returns a neutral result so the stack carries on and
still asks for the password. Uncommenting the **first** does something else entirely —
`trust` makes the module return outright *success* for a member, which with `sufficient`
ends the stack and lets wheel members `su` **with no password at all**. One word and one
flag apart, and one of them is a significant loosening. `use_uid` judges by the process's
current uid rather than the login name, which is the reliable choice when `su` is reached
from a script or a nested session. Both sit above `auth substack system-auth` so the group
check happens before the shared stack asks for a password; below it they are unreachable.

**`include` and `substack` both pull in another file, and they are not the same.**

| | `include` | `substack` |
| --- | --- | --- |
| Effect | The named file's lines of this type are evaluated as if pasted in | The same, but evaluated as a self-contained unit |
| A `done` or `die` inside | Ends the **whole** stack | Ends only the substack |
| A jump like `success=1` inside | Can jump out into the parent | Confined; the substack counts as one module to the parent |

Look at what that buys `su`. `auth substack system-auth` runs the shared stack, and when
`pam_unix` inside it succeeds — a `sufficient`, which means `done` — the substack ends
**but `su`'s own stack does not**, so `auth include postlogin` on the next line still runs.
Written as `include system-auth`, that `done` would have ended `su`'s auth stack outright
and skipped `postlogin`. That is why the file uses one keyword on one line and the other
on the next.

<details class="predict">
<summary>Nearly every RHEL-family service file points at `system-auth`, and there is no program called `system-auth`. It is not a service. Predict what `ls -l` says about it and about its sibling `password-auth`.</summary>

```bash
# AlmaLinux 10.2, x86_64
$ ls -l /etc/pam.d/system-auth /etc/pam.d/password-auth
lrwxrwxrwx. 1 root root 29 Aug  8 17:04 /etc/pam.d/password-auth -> /etc/authselect/password-auth
lrwxrwxrwx. 1 root root 27 Aug  8 17:04 /etc/pam.d/system-auth -> /etc/authselect/system-auth
```

</details>

**They are symlinks out of `/etc/pam.d` entirely.** The real files live in
`/etc/authselect`, next to a generated `nsswitch.conf`:

```bash
# AlmaLinux 10.2, x86_64
$ readlink -f /etc/pam.d/system-auth; ls /etc/authselect
/etc/authselect/system-auth
authselect.conf
custom
dconf-db
dconf-locks
fingerprint-auth
nsswitch.conf
password-auth
postlogin
smartcard-auth
switchable-auth
system-auth
```

Two shared stacks rather than one, and the split matters: **`system-auth` is for local
and console services, `password-auth` for services that authenticate over the network**,
`sshd` chief among them, so a policy can differ between somebody at the physical console
and somebody arriving from the internet. Editing only `system-auth` and wondering why SSH
behaves differently is a recurring afternoon. `fingerprint-auth`, `smartcard-auth`, and
`postlogin` are the same idea for other routes in.

<details class="deeper">
<summary>If you already administer Linux: what authselect is actually for, and why your edit to system-auth vanished</summary>

The first three lines of `system-auth` tell you the ending, and they are not advice:
`authselect apply-changes`, `authselect select`, and any package update that touches the
profile regenerate the file from a template, with no warning and no backup. The symptom
is a control that worked for three weeks and then silently stopped, which is the worst
class of failure there is.

**What it replaced explains the design.** Its predecessor `authconfig` rewrote the PAM
files in place by pattern-matching them, so a local edit and a tool run fought over the
same bytes and neither could be trusted afterwards. authselect instead owns the files
completely: you pick a profile, toggle features, and it renders the result.

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ ls -l /etc/pam.d/system-auth /etc/pam.d/password-auth; echo "--- what authselect is doing ---"; sudo authselect current 2>&1
lrwxrwxrwx. 1 root root 29 Aug  7 14:14 /etc/pam.d/password-auth -> /etc/authselect/password-auth
lrwxrwxrwx. 1 root root 27 Aug  7 14:14 /etc/pam.d/system-auth -> /etc/authselect/system-auth
--- what authselect is doing ---
Profile ID: local
Enabled features:
- with-silent-lastlog
```

`Profile ID` names the template, `Enabled features` the toggles applied on top. The
profiles are few and deliberate:

```bash
# AlmaLinux 10.2, x86_64
$ authselect list
- local  	 Local users only
- sssd   	 Enable SSSD for system authentication (also for local users only)
- winbind	 Enable winbind for system authentication
```

`local` for a standalone machine, `sssd` once identities come from a directory, `winbind`
for a direct Active Directory join without SSSD. `authselect select sssd --force` rewrites
both the PAM stacks and `nsswitch.conf` consistently, which is the point: the half-joined
machine where one of the two was updated is the failure this tool exists to prevent.

**Features are how you make a supported change.** `authselect enable-feature
with-faillock` inserts the lockout modules in the correct positions in every stack that
needs them; `with-mkhomedir` creates home directories on first login; `with-pamaccess`
turns on `pam_access`. `authselect list-features <profile>` enumerates them. When no
feature covers what you need, the supported route is a custom profile, not an edit:

```
sudo authselect create-profile ourpolicy --base-on sssd
sudo authselect select custom/ourpolicy
```

That copies the templates under `/etc/authselect/custom/ourpolicy/`, where they are yours
and nothing overwrites them; `authselect apply-changes` re-renders after you edit one.
**`authselect check`** verifies that the generated files still match what the profile
would produce, so it detects exactly the hand edit this panel is about — run it when one
machine behaves unlike its siblings.

The escape hatch, `authselect opt-out`, hands the files back to you permanently. It is
legitimate on a machine with genuinely unusual requirements, and a bad choice made
accidentally: from then on nothing keeps the stacks consistent with `nsswitch.conf`, and
every future change is manual on that host and automatic on every other one.

**Files authselect does not own stay editable.** `su`, `sudo`, `login`, and the rest are
shipped by their own packages, which is why the `pam_wheel` exercise above is a
legitimate hand edit and the same edit to `system-auth` is not. The listing of
`/etc/authselect` above is the authoritative list of what the tool owns.

</details>

## Locking an account after failed attempts

Nothing in the stacks above counts anything: a wrong password costs two seconds and
nothing else, forever. `pam_faillock` changes that, and its command-line half is
present on any machine with PAM installed:

```bash
# AlmaLinux 10.2, x86_64
$ faillock --user root
root:
When                Type  Source                                           Valid
```

**An empty table is the answer, not a missing feature.** The columns are there, root has
no recorded failures, and the module is not in this machine's stack at all. That is the
default state everywhere: the tooling ships, the enforcement does not.

Settings live in `/etc/security/faillock.conf`, which beats repeating module arguments in
three places:

| Setting | Does |
| --- | --- |
| `deny` | Failures before the account locks |
| `unlock_time` | Seconds until it unlocks itself. `0` means never |
| `fail_interval` | The window failures are counted within |
| `even_deny_root` | Whether root is subject to lockout at all |
| `root_unlock_time` | A shorter automatic unlock for root, if it is |
| `dir` | Where the counters are kept |
| `audit`, `silent` | Whether attempts on unknown users are logged, and whether the user is told |

**`unlock_time = 0` is a decision, not a default to inherit.** An account that never
unlocks itself turns password guessing against a service account into a denial of service
that needs a human; a few hundred seconds stops guessing at any rate that matters while
healing on its own.

`faillock --user alice` inspects and `sudo faillock --user alice --reset` clears. On the
RHEL family, the way to put the modules into the stacks is not to type them in:

```bash
# AlmaLinux 10.2, x86_64
$ authselect enable-feature with-faillock; grep faillock /etc/pam.d/system-auth
auth        required                                     pam_faillock.so preauth silent
auth        required                                     pam_faillock.so authfail
account     required                                     pam_faillock.so
```

**Three lines across two stacks, and not a `deny=` or `unlock_time=` among them.** One
command inserted them into every generated stack and left the numbers in `faillock.conf`,
so one file governs every service on the machine. With those lines in place the empty
table fills up. An ordinary user attempts `su` twice with the wrong password:

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

**Read the `Valid` column.** `V` means the record still counts toward `deny`. Records
older than `fail_interval` stay in the listing and stop counting, so a table with rows
in it is not by itself a locked account.

<details class="deeper">
<summary>If you already administer Linux: pam_faillock takes three lines in two stacks, and two of them are in positions people get wrong</summary>

Those three lines are meaningless without the line they surround. Interleaved with the
authenticating module, the arrangement the RHEL-family tooling produces reads:

```
auth     required    pam_faillock.so preauth silent
auth     sufficient  pam_unix.so nullok
auth     required    pam_faillock.so authfail
auth     required    pam_deny.so
account  required    pam_faillock.so
```

Each position is load bearing.

**`preauth` goes above the authenticating module**, to refuse an account that is already
locked before a password is collected. Below `pam_unix` it is useless: a locked account
with the correct password would already have returned success through the `sufficient`
line. The order trap again, in the configuration people are most likely to write by hand.

**`authfail` goes below the authenticating module, and it must be reachable.** It records
the failure that just happened, so it only runs when `pam_unix` failed and the
`sufficient` fell through — which is exactly why `pam_unix` has to be `sufficient` rather
than `requisite` here. Change that flag and the counter stops incrementing while
everything appears to work, and a lockout that never triggers produces no symptom until
somebody tests it.

**The flag on the `authfail` line is worth a note.** The module's own documentation shows
`[default=die]` where the generated stack shows `required`. Both fail the stack: `die`
returns at once, `required` continues to `pam_deny`, which was going to refuse anyway.
Either is correct here, and copying a `[default=die]` example into a stack with no
terminating `pam_deny` is how people end up with a lockout module that records failures
and refuses nobody.

**The `account` line is the one everybody omits**, and its absence is the classic
half-working deployment. Without it the lock is counted and never consulted at the point
where the account's usability is decided, so behaviour diverges between services
depending on which stacks they run. If lockout works over SSH and not at the console, or
works but never seems to expire, check this line first.

**Counters live in `dir`, which defaults to a path under `/var/run`** — `tmpfs` on a
modern system, so **a reboot clears every lockout**. Convenient during testing, and a real
gap if your threat model includes somebody who can trigger a reboot. Pointing `dir` at
persistent storage is supported and deliberate.

**`even_deny_root` deserves a full stop before you enable it.** With `unlock_time = 0` and
`even_deny_root` set, a script holding a stale root password will permanently lock root
out, and the recovery is a rescue boot. If you enable it, set `root_unlock_time` too.

One piece of history that still shows up in older guides: `pam_tally2` was the previous
implementation and is gone from current releases, so configuration copied from a
pre-RHEL 8 guide names a module that no longer exists — and a `required` line naming a
missing module denies every login.

</details>

## polkit, the other authorisation engine

PAM decides whether you may become a session. **polkit decides whether a session you
already have may perform one specific privileged action.** It is the desktop half of
the same problem, and it is present on servers too.

- **Actions** are named strings such as `org.freedesktop.systemd1.manage-units`,
  declared by packages in `/usr/share/polkit-1/actions/`.
- **Rules** are JavaScript files in `/etc/polkit-1/rules.d/`, evaluated in filename
  order, that answer yes, no, or ask for a password.
- **`pkexec`** is polkit's answer to `sudo`, and it is setuid root — it appeared in the
  setuid inventory in lesson 45. `pkaction` lists actions and `pkcheck` tests one.

The two compose rather than compete: when a rule says "ask for a password", polkit
authenticates that password **through PAM**. So a PAM change can alter how a polkit
prompt behaves, and a polkit rule can grant something `sudoers` never mentions. **On a
headless server that matters more than it looks.** An ordinary user running `systemctl
restart` over D-Bus is authorised by polkit, not by `sudoers`, so a permissive rule file
dropped in by a package is a grant that appears in no `sudo` audit; `pkaction --verbose`
is where that inventory lives. The exam wants you to say what polkit is and how it
differs from PAM. Writing rules is beyond it.

## Across distributions

The mechanism is identical everywhere. What differs is who writes the shared files and
what they are called:

```bash
# Debian 13 (trixie), x86_64
$ ls /etc/pam.d
chfn
chpasswd
chsh
common-account
common-auth
common-password
common-session
common-session-noninteractive
login
newusers
other
passwd
runuser
runuser-l
su
su-l
```

**No `system-auth` and no `password-auth`.** Four `common-` files instead, split by
module type rather than by local-versus-network, plus a fifth for non-interactive
sessions. A guide that tells you to edit `system-auth` here is describing a file that
does not exist:

```bash
# Debian 13 (trixie), x86_64
$ ls -l /etc/pam.d/common-auth /etc/pam.d/system-auth
ls: cannot access '/etc/pam.d/system-auth': No such file or directory
-rw-r--r--. 1 root root 1214 Aug  3 00:00 /etc/pam.d/common-auth
```

Debian's `su` pulls those in with a different keyword:

```bash
# Debian 13 (trixie), x86_64
$ grep -vE "^\s*(#|$)" /etc/pam.d/su
auth       sufficient pam_rootok.so
session       required   pam_env.so readenv=1
session       required   pam_env.so readenv=1 envfile=/etc/default/locale
session    optional   pam_mail.so nopen
session    required   pam_limits.so
@include common-auth
@include common-account
@include common-session
```

**`@include` is a real syntax difference, not a spelling.** It takes no module type and
pulls in the *entire* named file, every stack in it at once. The RHEL-family `include`
takes a type and pulls only the lines of that type, which is why the RHEL `su` above
names `system-auth` on four separate lines, one per stack.

And the shared stack itself is the same logic written a different way:

```bash
# Debian 13 (trixie), x86_64
$ cat /etc/pam.d/common-auth
#
# /etc/pam.d/common-auth - authentication settings common to all services
#
# This file is included from other service-specific PAM config files,
# and should contain a list of the authentication modules that define
# the central authentication scheme for use on the system
# (e.g., /etc/shadow, LDAP, Kerberos, etc.).  The default is to use the
# traditional Unix authentication mechanisms.
#
# As of pam 1.0.1-6, this file is managed by pam-auth-update by default.
# To take advantage of this, it is recommended that you configure any
# local modules either before or after the default block, and use
# pam-auth-update to manage selection of other modules.  See
# pam-auth-update(8) for details.

# here are the per-package modules (the "Primary" block)
auth	[success=1 default=ignore]	pam_unix.so nullok
# here's the fallback if no module succeeds
auth	requisite			pam_deny.so
# prime the stack with a positive return value if there isn't one already;
# this avoids us returning an error just because nothing sets a success code
# since the modules above will each just jump around
auth	required			pam_permit.so
# and here are more per-package modules (the "Additional" block)
# end of pam-auth-update config
```

**Trace it: the bracket form is doing the work of `sufficient`.** `pam_unix` succeeds,
`success=1` jumps over one module — `pam_deny` — and lands on `pam_permit`, which returns
success. `pam_unix` fails, `default=ignore` carries on to `pam_deny`, which is `requisite`
and returns failure at once. Identical behaviour to the RHEL stack you traced, expressed
as a jump rather than a short circuit, and the file's own comment says why: modules are
added and removed here by a program, and a jump computed from a known number of lines
composes more predictably than a chain of `sufficient` lines whose meaning depends on
what a package inserted above them. That comment is also the same warning in different
words. **Both families generate their shared files and both will overwrite your edit**;
here the tool is `pam-auth-update`, driven by files in `/usr/share/pam-configs/`.

| | RHEL family | Debian family |
| --- | --- | --- |
| Service files | `/etc/pam.d/<service>` | `/etc/pam.d/<service>` |
| Shared stacks | `system-auth`, `password-auth` | `common-auth`, `common-account`, `common-password`, `common-session` |
| Where they really live | Symlinks into `/etc/authselect/` | Regular files in `/etc/pam.d/` |
| Who generates them | `authselect` | `pam-auth-update`, from `/usr/share/pam-configs/` |
| Pulling them in | `include` and `substack`, per type | `@include`, whole file |
| Expressing "any of these" | `sufficient` | `[success=N default=ignore]` jumps |
| Module directory | `/usr/lib64/security/` | `/usr/lib/<triplet>/security/` |
| Password quality | `pam_pwquality`, in the shipped stack | `pam_unix obscure` until `libpam-pwquality` is installed |
| Lockout | `pam_faillock`, via `authselect enable-feature with-faillock` | `pam_faillock`, added by editing or `pam-auth-update` |

**The password-quality row is the one that catches people.** A stock Debian machine has no
quality module at all: `obscure` turns on `pam_unix`'s own small checks — palindrome,
case-only change, too similar to the old one, too short — and that is the entire policy
until `libpam-pwquality` is installed. Auditing a Debian host for `minlen` finds nothing
because there is nothing there to find.

## Prove it

```
# Which file will this service use, and does it exist at all
ls -l /etc/pam.d/sshd

# Where does the shared stack really live, and who owns it
readlink -f /etc/pam.d/system-auth
authselect current
authselect check

# Before blaming PAM: is the user even visible
getent passwd alice
id alice

# What PAM actually decided, with the module that decided it
sudo journalctl -t sshd -t su -t sudo --since "10 min ago"
sudo tail -n 50 /var/log/secure

# Lockout state, and clearing it
faillock --user alice
sudo faillock --user alice --reset
```

**`getent` before anything else.** It goes through the name service and never touches
PAM, so it splits "this user does not exist here" from "this user cannot authenticate"
in one command, and those two arrive as the same sentence from the same user.

## What trips people up

### 1. A restriction placed below a sufficient line

`auth sufficient pam_unix.so` followed by `auth required pam_wheel.so` restricts nobody:
the `sufficient` returns success for anyone with a valid password and the line below
never executes. Read a stack as a program with early returns, and put a control
**above** every line that could return before it.

### 2. Editing the generated shared stack by hand

`system-auth` and `password-auth` are symlinks into `/etc/authselect`, and the real
files say in their first two lines that they are generated. The change works, survives
a reboot, and vanishes weeks later during patching. Use a feature, or a custom profile,
or `authselect opt-out` and accept ownership.

### 3. Authentication token manipulation error

The generic failure from the `password` stack, with several causes behind identical
text: `pam_pwquality` rejected the new password and said why only in the log; the
current password was wrong; `/etc/shadow` is not writable, whether immutable from
lesson 45, a full filesystem, or a read-only mount; or SELinux refused the write, from
lesson 44, leaving an AVC and no other clue. `journalctl -t passwd` or
`/var/log/secure` names the module. The terminal never will.

### 4. One `pam_faillock` line instead of three

`preauth` above the authenticating module, `authfail` below it, and an `account` line
as well. Miss the `account` line and the lock is counted but inconsistently enforced;
put `preauth` below `pam_unix` and it never runs. `authselect enable-feature
with-faillock` does all three correctly.

### 5. Testing a change with only one session open

The shared stack serves the console, SSH, `su`, and `sudo` at once, so breaking it
closes every way in and the recovery is a rescue boot. Copy the file, keep an
authenticated root shell open, test from a second session, and watch the log while you
do. A session that already exists is not re-authenticated, which is the only reason the
safety shell works.

## Work it through

A security review lands with two requirements for a fleet of RHEL 10 machines: `su` is
to be restricted to members of `wheel`, and accounts are to lock after five failed
passwords with an automatic unlock after fifteen minutes. Reason it out before reading
on.

**First, decide which files are yours to edit**, because the two requirements do not have
the same answer. `ls -l /etc/pam.d/su /etc/pam.d/system-auth` returns a regular file and a
symlink into `/etc/authselect`, so the `su` requirement is a legitimate hand edit and the
lockout requirement is not. Getting this backwards costs you either a control that
evaporates at the next update, or a hunt for an authselect template that does not exist
because the tool does not own `/etc/pam.d/su`.

**Second, the `su` restriction.** The line is already in the file, commented, and the
right one is the second of the two:

```
auth		required	pam_wheel.so use_uid
```

**Not** the `trust` variant, which would let wheel members become root with no password at
all. And it stays where it is, above `auth substack system-auth`.

**Third, the lockout.** `sudo authselect enable-feature with-faillock`, then `deny = 5`
and `unlock_time = 900` in `/etc/security/faillock.conf` — once, rather than as module
arguments repeated across three lines in several files.

**Fourth, and this is the step that is not on the review.** Open a second root session
before touching anything, copy `/etc/pam.d/su`, and test from a third: as a wheel member,
as a non-member, and as a non-member typing a wrong password five times. Confirm with
`faillock --user testuser`, clear it with `--reset`, and read `/var/log/secure` to see
which module refused each attempt.

**Now change one detail and watch the answer change.** Had the requirement been to
restrict *SSH*, `system-auth` would be the wrong file: network services use
`password-auth`, and `sshd` has its own service file besides. The better answer might not
be PAM at all, since `AllowGroups wheel` in `sshd_config` is simpler, more visible, and
does not risk the shared stack. And if these machines are joined to a directory, a
`pam_sss.so` line exists in the auth stack, and where lockout sits relative to it decides
whether directory accounts are counted at all.

The point worth extracting: **a PAM stack is a small program with early returns, and the
two questions that answer almost everything are "what runs before this line" and "who
writes this file".** Order decides whether a control exists. Ownership decides whether
it is still there next month.

## Try it

Optional, on a machine you can break, **with a second root session already open**.

1. `ls /etc/pam.d/` and name the program each of five files belongs to.
2. `ldd $(which su) | grep pam` and confirm the program is linked against the library.
3. `cat /etc/pam.d/su`. Find the `sufficient` line and say what it does for root.
4. `readlink -f /etc/pam.d/system-auth`, then `authselect current`. Say who owns that
   file.
5. `cat /etc/pam.d/system-auth` and trace the `auth` stack twice out loud, once for a
   correct password and once for a wrong one. Name the line that runs last in each case.
6. Uncomment `auth required pam_wheel.so use_uid` in `/etc/pam.d/su`, then try `su` from
   an account that is not in `wheel`, **from your second session**. Read
   `/var/log/secure`.
7. Move that line below `auth substack system-auth` and try again. Explain what changed.
8. `faillock --user root`, then `authselect enable-feature with-faillock`, then look at
   the generated stack again.

**Verification step.** You have it when you can be handed an unfamiliar
`/etc/pam.d/<service>` file and say, without running anything, which line a correct
password stops at, which line a wrong password stops at, and which lines in the file can
never execute.

## Check yourself

<details class="qa">
<summary>Trace this `auth` stack for a wrong password. Which modules run, which does not, and what does the user experience?</summary>

```
auth        required     pam_env.so
auth        required     pam_faildelay.so delay=2000000
auth        sufficient   pam_unix.so nullok
auth        required     pam_deny.so
```

**All four run, and the stack fails at the last one.**

`pam_env` succeeds. `pam_faildelay` succeeds, having registered that a failure should be
reported two seconds late — the argument is microseconds. `pam_unix` hashes what was typed
and does not match, and because it is `sufficient` **its failure is ignored** and
evaluation continues. `pam_deny` always fails and is `required`, so the stack returns
failure. The user waits about two seconds and is told the authentication failed, with no
indication of which check refused them. That is deliberate.

**The tempting wrong answer is that `pam_deny` does not run** because an earlier failure
"already failed the stack". It did not: a `sufficient` module's failure is discarded
entirely, and `pam_deny` is the reason the refusal happens at all. Whatever you add to
this stack, ask where it sits relative to line three; anything below it is unreachable on
a successful login.

</details>

<details class="qa">
<summary>`required` and `requisite` both fail the stack. What is the actual difference, and give a case where choosing wrongly changes the outcome rather than the timing?</summary>

**`required` remembers the failure and keeps evaluating. `requisite` returns to the
calling program immediately.** Both end in failure; the difference is what runs in
between.

**Information disclosure** is the first consequence. `required` runs everything
regardless, so an attacker cannot tell from prompts or timing which check refused them.
`requisite` stops at the first refusal, which can leak that a username exists or that an
account is locked.

**Side effects downstream** is the one that bites. In the `password` stack:

```
password    requisite    pam_pwquality.so
password    sufficient   pam_unix.so ... use_authtok
```

With `requisite`, a rejected password stops there and `pam_unix` never receives it.
Change that one word to `required` and evaluation continues: `pam_unix` runs, takes the
token via `use_authtok`, and **writes the bad password to `/etc/shadow`**. The stack then
reports failure, so the user sees an error and believes nothing happened.

**The tempting wrong answer is that `requisite` is "stronger"** and therefore safer
everywhere. It is not stronger, it is earlier. In an `auth` stack, stopping early is often
worse, because a module below that records the failed attempt — `pam_faillock` with
`authfail` — never gets to run.

The thing you will need next: `required` is `[... default=bad]` and `requisite` is
`[... default=die]`. `bad` marks the stack failed and continues; `die` marks it failed and
returns.

</details>

<details class="qa">
<summary>You add `auth required pam_wheel.so use_uid` to `/etc/pam.d/su`, below the line that includes the shared stack. Testing shows a non-wheel user can still `su`. Why, and what else is different about the `trust` variant?</summary>

**The line is unreachable.** The shared stack above it contains
`auth sufficient pam_unix.so`, and a `sufficient` module's success returns from the stack
immediately. Any user with a valid password satisfies it, so evaluation ends before your
line is considered. **Move it above `auth substack system-auth`**, which is exactly where
the two commented examples shipped in the file already sit.

**The `trust` variant is a different thing entirely, not a variation:**

```
#auth		sufficient	pam_wheel.so trust use_uid
#auth		required	pam_wheel.so use_uid
```

Without `trust`, a member of the group returns a neutral result and the stack carries on
to ask for a password, while a non-member fails a `required` module and is refused. That
is a restriction. With `trust`, a member returns outright success, and paired with
`sufficient` that **ends the auth stack with no password requested at all**. That is a
loosening, and uncommenting the wrong one of two adjacent lines is an easy way to grant
passwordless root to a group.

**The tempting wrong answer is that the module did not load** or that the group name is
wrong. Both are worth checking and `/var/log/secure` would say so — but a silent success
with the restriction absent is the signature of unreachable configuration rather than a
broken module. The thing you will need next: `use_uid` checks the process's current uid
rather than the login name, which is what you want anywhere `su` might be reached from a
script or a nested session.

</details>

<details class="qa">
<summary>You added `pam_faillock` lines to `/etc/pam.d/system-auth` on a RHEL machine. It worked. Six weeks later lockout no longer happens and nobody changed anything. What happened, and what should you have done?</summary>

**The file was regenerated and your lines are gone.** `system-auth` is a symlink into
`/etc/authselect`, and the real file's first two lines say it is generated and that
manual changes will be overwritten. `authselect apply-changes`, `authselect select`, or a
package update that re-renders the profile all silently replace it.

**The supported change is a feature:** `sudo authselect enable-feature with-faillock`.
That inserts `preauth`, `authfail`, and the `account` line in the right positions in
every generated stack, and it survives updates because the tool regenerates *with* it
rather than over it. Settings go in `/etc/security/faillock.conf`, once.

**The tempting wrong answer is `authselect opt-out`.** It does stop the overwriting, and
it hands you permanent manual ownership of the stacks and `nsswitch.conf` on that one
host, so every future change is manual there and automatic everywhere else. Use a
feature first, a custom profile (`authselect create-profile ... --base-on sssd`) second,
and opt-out only when neither fits.

**`authselect check`** is how you would have caught this before the auditor did: it reports
whether the current files still match what the profile produces. The thing you will need
next: this only applies to files authselect owns, which listing `/etc/authselect` shows.
`/etc/pam.d/su`, `/etc/pam.d/sudo`, and `/etc/pam.d/login` are ordinary package-shipped
files and are yours to edit.

</details>

<details class="qa">
<summary>A user reports she cannot log in. `id alice` prints her uid, gid, and groups correctly. What have you just ruled out, and what do you check next?</summary>

**You have ruled out the name service.** `id` goes through NSS and never touches PAM, so
a correct answer means the account exists as far as the system is concerned and `ls -l`
will show her name rather than a number.

**So the problem is authentication or the account's usability**, which is PAM's
territory:

- **Authentication.** Wrong password, an expired or empty hash, a locked password — the
  `!` prefix in `/etc/shadow` from lesson 28 — or a `pam_faillock` lock from earlier
  attempts, which `faillock --user alice` answers in one command.
- **Account usability.** The password aged out, the account expired (`chage -l alice`),
  or an `account` module such as `pam_access` or `pam_time` refused this origin or this
  hour.

**`/var/log/secure` or `journalctl` names the module**, which is the fastest route and the
step people skip. PAM writes which module refused; the login prompt deliberately does not.

**The tempting wrong answer is to start re-reading the PAM stack.** It has not changed and
works for everybody else; something about this account or this attempt is different, and
the log says which.

**And check the route in before concluding.** SSH does not use the same shared stack as
the console — `password-auth` rather than `system-auth` — and it has non-PAM gates of its
own: `AllowUsers`, `AllowGroups`, `PermitRootLogin`, and key authentication that never
consults `/etc/shadow` at all.

</details>

## References

- [pam(8)](https://man7.org/linux/man-pages/man8/pam.8.html) - Linux man-pages project. Accessed 2026-08-08.
- [pam.conf(5)](https://man7.org/linux/man-pages/man5/pam.conf.5.html) - Linux man-pages project. Accessed 2026-08-08.
- [pam_unix(8)](https://man7.org/linux/man-pages/man8/pam_unix.8.html) - Linux man-pages project. Accessed 2026-08-08.
- [pam_faillock(8)](https://man7.org/linux/man-pages/man8/pam_faillock.8.html) - Linux man-pages project. Accessed 2026-08-08.
- [pam_wheel(8)](https://man7.org/linux/man-pages/man8/pam_wheel.8.html) - Linux man-pages project. Accessed 2026-08-08.
- [pam_pwquality(8)](https://manpages.debian.org/trixie/libpam-pwquality/pam_pwquality.8.en.html) - Debian Project. Accessed 2026-08-08.
- [nsswitch.conf(5)](https://man7.org/linux/man-pages/man5/nsswitch.conf.5.html) - Linux man-pages project. Accessed 2026-08-08.
- [polkit(8)](https://manpages.debian.org/trixie/polkitd/polkit.8.en.html) - Debian manpages. Accessed 2026-08-08.
- [Configuring authentication and authorization in RHEL](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/10/html/configuring_authentication_and_authorization_in_rhel/index) - Red Hat. Accessed 2026-08-08.

Captured output came from three machines: an AlmaLinux 10.2 container with no SSH server
and no `sudo` installed, a Debian 13 container, and a Fedora CoreOS virtual machine that
runs both. None ships `pam_faillock` in its stacks by default, which is why the `faillock`
table is empty until `authselect enable-feature` puts the modules there. The `su`
transcripts are real logins and real refusals driven through a pseudo-terminal, because
`su` will not take a password from a pipe. Blocks without a distribution and architecture
header are illustrative: the interleaved `pam_faillock` stack, the `pwquality` settings,
and excerpts quoted back from files shown in full elsewhere come from the module
documentation rather than from a capture.
