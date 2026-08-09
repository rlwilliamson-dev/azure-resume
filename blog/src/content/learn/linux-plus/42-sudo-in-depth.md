---
title: "The rule grants one command and the user gets a root shell"
description: "The sudoers policy language field by field: who, where, as whom, and what. Why visudo exists, why a drop-in with a dot in its name is silently ignored, and why permitting vi, less, or a wildcard is the same as permitting root."
track: "linux-plus"
level: "working"
order: 430
objectives:
  - "Read a sudoers rule field by field and say exactly what it permits"
  - "Grant one command with a drop-in file that sudo will actually read"
  - "Judge whether a permitted command can be escaped into a root shell"
  - "Check what an account may do with sudo -l, and find where sudo wrote it down"
prerequisites: ["users-root-and-sudo", "managing-users-and-groups"]
tags: ["linux", "linux-plus", "sudo", "sudoers", "privilege", "security"]
updated: 2026-08-08
draft: false
examObjectives:
  - exam: "xk0-006"
    domain: "3.0"
    objective: "3.3"
sources:
  - title: "sudoers(5)"
    url: "https://www.sudo.ws/docs/man/sudoers.man/"
    publisher: "Sudo Project"
    accessed: 2026-08-08
    tier: 1
  - title: "sudo(8)"
    url: "https://www.sudo.ws/docs/man/sudo.man/"
    publisher: "Sudo Project"
    accessed: 2026-08-08
    tier: 1
  - title: "visudo(8)"
    url: "https://www.sudo.ws/docs/man/visudo.man/"
    publisher: "Sudo Project"
    accessed: 2026-08-08
    tier: 1
  - title: "sudoreplay(8)"
    url: "https://www.sudo.ws/docs/man/sudoreplay.man/"
    publisher: "Sudo Project"
    accessed: 2026-08-08
    tier: 1
  - title: "sudo_logsrvd(8)"
    url: "https://www.sudo.ws/docs/man/sudo_logsrvd.man/"
    publisher: "Sudo Project"
    accessed: 2026-08-08
    tier: 1
  - title: "Sudo security advisories"
    url: "https://www.sudo.ws/security/advisories/"
    publisher: "Sudo Project"
    accessed: 2026-08-08
    tier: 1
  - title: "sudoers(5) as shipped by Debian trixie"
    url: "https://manpages.debian.org/trixie/sudo/sudoers.5.en.html"
    publisher: "Debian Project"
    accessed: 2026-08-08
    tier: 1
  - title: "sudo"
    url: "https://wiki.debian.org/sudo"
    publisher: "Debian Project"
    accessed: 2026-08-08
    tier: 2
symptoms:
  - symptom: "User is not allowed to run sudo on"
    anchor: "drop-in-files-and-the-ones-sudo-silently-ignores"
  - symptom: "sudo: /etc/sudoers.d/sam is world writable"
    anchor: "3-a-drop-in-that-anyone-can-write-to"
  - symptom: "parse error in /etc/sudoers near line"
    anchor: "visudo-and-why-you-never-open-sudoers-in-an-editor"
  - symptom: "Cmnd_Alias referenced but not defined"
    anchor: "visudo-and-why-you-never-open-sudoers-in-an-editor"
---

> **Before you read.** A developer needs to restart the application after each
> deploy. That is one command. Nothing else on the machine is theirs, and the
> ticket has been open a week because nobody worked out how to grant exactly that.
>
> Somebody suggests adding them to the `wheel` group. It takes four seconds and
> grants every command on the machine, as every user, forever.
>
> **What is the smaller thing, and once you have written it, is it actually
> smaller?**

`sudo` is not a list of trusted people. It is a policy engine with its own small
language, and `/etc/sudoers` is a program written in that language. Lesson 06
taught you to run `sudo`; this lesson is the file. The uncomfortable half comes
second: a rule naming one command does not reliably grant one command's worth of
power, because a great many commands can run other commands. That is a fact about
the programs you permit rather than a bug in `sudo`, and designing around it is
most of the skill.

### Some words you will need

<dl class="terms">
<dt>sudoers</dt>
<dd>The policy. Normally <code>/etc/sudoers</code> plus every file it includes.</dd>
<dt>user specification</dt>
<dd>One rule line. Who may run what, on which hosts, as which identity.</dd>
<dt>runas</dt>
<dd>The identity the command is executed as. The parenthesised field in a rule, and the <code>-u</code> flag on the command line.</dd>
<dt>drop-in</dt>
<dd>A file under <code>/etc/sudoers.d</code>, read because the main file says to. The normal place to put your own rules.</dd>
<dt>alias</dt>
<dd>A named list of users, hosts, runas identities, or commands, so a rule can refer to a set by name.</dd>
<dt>tag</dt>
<dd>A modifier attached to a command in a rule: <code>NOPASSWD</code>, <code>NOEXEC</code>, <code>LOG_OUTPUT</code>. Written before the command, ending in a colon.</dd>
<dt>timestamp</dt>
<dd>The record that you authenticated recently, kept per user and per terminal. It is why the second <code>sudo</code> does not ask again.</dd>
<dt>shell escape</dt>
<dd>A feature of a program that lets it run another program. Editors, pagers, and anything with a scripting facility have one.</dd>
</dl>

## What breaks without this

**A syntax error locks everybody out of privilege**, on a machine where fixing it
requires privilege. Editing `/etc/sudoers` with a plain editor is the one
administrative task with a genuinely self-locking failure mode.

**The rule is perfect and does nothing.** A drop-in with the wrong *name* is
skipped without a message, a warning, or a line in any log. The policy you wrote
is not the policy in force and nothing on the machine says so.

**The narrow grant was never narrow.** You permitted `vi` on one file, or
`systemctl status`, or a command with a `*` in the arguments, and the account now
has a root shell. Nothing failed; you granted more than you meant to.

**You cannot answer "what can this account do".** That is what an auditor, an
incident, and a leaver's offboarding all ask, and reading `sudoers` by eye is not
an answer once aliases, groups, and five drop-in files are involved.

## What a sudo rule actually says

Two things in this topic changed behaviour at a specific release, so start by
knowing which sudo you are looking at:

```bash
# AlmaLinux 10.2, x86_64
$ rpm -q sudo; sudo -V | head -1
sudo-1.9.17-4.p2.el10_2.x86_64
Sudo version 1.9.17p2
```

**The package version and the program's own version are not the same string**, and
the second one decides behaviour: regular expressions in command arguments arrived
at 1.9.10, `use_pty` became a default at 1.9.14. Both come up later.

Every line the distribution ships is either a `Defaults` setting or a rule, and
stripping the comments makes that obvious:

```bash
# AlmaLinux 10.2, x86_64
$ grep -v '^#' /etc/sudoers | grep .
Defaults   !visiblepw
Defaults    always_set_home
Defaults    match_group_by_gid
Defaults    always_query_group_plugin
Defaults    env_reset
Defaults    env_keep =  "COLORS DISPLAY HOSTNAME HISTSIZE KDEDIR LS_COLORS"
Defaults    env_keep += "MAIL PS1 PS2 QTDIR USERNAME LANG LC_ADDRESS LC_CTYPE"
Defaults    env_keep += "LC_COLLATE LC_IDENTIFICATION LC_MEASUREMENT LC_MESSAGES"
Defaults    env_keep += "LC_MONETARY LC_NAME LC_NUMERIC LC_PAPER LC_TELEPHONE"
Defaults    env_keep += "LC_TIME LC_ALL LANGUAGE LINGUAS _XKB_CHARSET XAUTHORITY"
Defaults    secure_path = /sbin:/bin:/usr/sbin:/usr/bin
root	ALL=(ALL) 	ALL
%wheel	ALL=(ALL)	ALL
```

**Eleven `Defaults` lines and two rules.** Most of the shipped file is tuning;
the authorisation policy on a stock RHEL-family machine is two lines long.
`root` may run any command, as any user, on any host, and `%wheel`, the
percent sign means a group, may do the same. Everything else is denied,
because sudoers has no default-allow.

A rule has four positions, and they are always in this order:

```
sam     ALL   = (root)      /usr/bin/systemctl restart httpd
 |       |       |           |
 who    where   as whom     what
```

| Field | Here | Means |
| --- | --- | --- |
| who | `sam` | A user name, `%group`, `%#gid`, or a `User_Alias` |
| where | `ALL` | Which hosts this rule applies on, for a sudoers file shared across machines |
| as whom | `(root)` | The runas identity. `(ALL)` means any user; `(ALL:ALL)` means any user and any group |
| what | `/usr/bin/systemctl restart httpd` | A fully qualified path, optionally with arguments, or `ALL` |

**The host field is the one beginners misread.** `ALL` there does not mean
"all commands"; it means "on every host", because sudoers was designed to be
one file distributed to a fleet: "the DBAs get these commands, but only on the
database servers". Where sudoers is local it is `ALL` on every line and you
can read past it. **`ALL` in the command field is the dangerous one**, and
that is what the `%wheel` line has.

The runas field is not decoration either. `sudo` runs commands as root because
root is the default, not because that is all it does:

```bash
# AlmaLinux 10.2, x86_64
$ sudo -u sam id; sudo -u sam pwd
uid=1000(sam) gid=1000(sam) groups=1000(sam)
/
```

`sudo -u` picks the runas identity; the rule's parenthesised field decides whether
you may. A rule of the form `sam ALL=(app) /usr/bin/systemctl --user restart api`
never yields root even if the user escapes the command, which makes the runas field
a real control rather than a formality.

<details class="deeper">
<summary>If you already administer Linux: the Defaults you should recognise, and the two that quietly matter most</summary>

`Defaults` lines can be scoped, and most people only ever write the unscoped form:

| Form | Applies to |
| --- | --- |
| `Defaults x` | Everything |
| `Defaults:sam x` | When `sam` is the invoking user |
| `Defaults>root x` | When root is the runas target |
| `Defaults@dbserver x` | On that host |
| `Defaults!PAGERS x` | When the command matches that `Cmnd_Alias` |

The last one is the interesting shape. `Defaults!PAGERS noexec` turns on shell
escape prevention for exactly the commands in one alias, which is far more
surgical than a global flag and is the idiom the sudoers manual itself uses.

**`env_reset` and `secure_path` are doing the security work in that shipped file.**
`env_reset` throws away the invoking user's environment and rebuilds a minimal one,
keeping only what `env_keep` names; without it, `LD_PRELOAD`, `PYTHONPATH`,
`PERL5LIB`, `BASH_ENV`, and `EDITOR` are all steering wheels a caller could turn.
`secure_path` then replaces `PATH` outright, so a script run under sudo that calls
`tar` without a full path cannot be made to pick up `~/bin/tar`:

```bash
# AlmaLinux 10.2, x86_64
$ echo "PATH=$PATH"; sudo sh -c 'echo PATH=$PATH'
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
PATH=/sbin:/bin:/usr/sbin:/usr/bin
```

**The second path is the sudoers value verbatim**, and what vanished is
`/usr/local/bin` and `/usr/local/sbin`, the two directories a local administrator is
most likely to have put something in. That is the standard report of "my script
works and stops working under sudo".

`env_reset` is the other half, and `sudo -i` shows it at its cleanest:

```bash
# AlmaLinux 10.2, x86_64
$ sudo -i -u sam env | head
SHELL=/bin/bash
SUDO_GID=0
HISTCONTROL=ignoredups
HISTSIZE=1000
HOSTNAME=f9ea81af1e24
SUDO_COMMAND=/bin/bash -c env
SUDO_USER=root
PWD=/home/sam
LOGNAME=sam
SUDO_HOME=/root
```

The environment was rebuilt for the target user rather than inherited, and sudo
added breadcrumbs. **`SUDO_USER` is the one worth remembering**: under sudo,
`whoami` says `root` and `SUDO_USER` says who is actually there, which is what a
script should log.

**Read `env_keep` as a list of holes you have accepted.** The sudoers manual's own
sample file warns that keeping `HOME` can lead to privilege escalation, because
programs locate their configuration through it. The rest of the settings worth
knowing by name:

| Setting | Default | Why you would touch it |
| --- | --- | --- |
| `timestamp_timeout` | 5 minutes | `0` prompts every time. A negative value lasts until reboot, which is a bad idea on a shared jump host |
| `passwd_tries` | 3 | Attempts before sudo gives up and logs a denial |
| `requiretty` | off | Historically on in RHEL, and the cause of "sorry, you must have a tty" from cron and Ansible |
| `use_pty` | **on** since sudo 1.9.14 | Runs the command in its own pseudo-terminal, so a malicious program cannot inject keystrokes back into your terminal |
| `log_input` / `log_output` | off | Session recording. See the panel further down |
| `!authenticate` | n/a | Scoped with `Defaults:sam`, this removes the password prompt for a person rather than for a command, which is almost always the wrong axis |

</details>

## visudo, and why you never open sudoers in an editor

Look at the file's mode before anything else:

```bash
# AlmaLinux 10.2, x86_64
$ ls -l /etc/sudoers; ls -l /etc/sudoers.d/
-r--r-----. 1 root root 4328 Apr 10 00:00 /etc/sudoers
total 0
```

**Mode 0440, and not writable even by its owner.** That is a deliberate speed bump
in front of the one file where a typo self-locks: sudoers with a parse error grants
nothing to anybody, on a machine where repairing the file requires being somebody.

`visudo` is the answer, and it does four things a text editor does not:

1. **Takes a lock**, so two administrators cannot silently overwrite each other.
2. **Edits a temporary copy**, never the live file.
3. **Parses the copy before installing it**, and refuses to install a broken one.
4. **Puts it back atomically**, with the right owner and mode.

It picks an editor from `$SUDO_EDITOR`, `$VISUAL`, then `$EDITOR`, in that
order, falling back to whatever the package was built with, and only if the
`env_editor` flag is on, which is why a hardened build ignores your `$EDITOR`
and opens `vi` anyway. `visudo -f /etc/sudoers.d/deploy` edits one drop-in
with the same protections, and is how you should edit them.

The check runs on its own, without editing anything:

```bash
# AlmaLinux 10.2, x86_64
$ visudo -c
/etc/sudoers: parsed OK
/etc/sudoers.d/services: parsed OK
```

**It checked two files**, because `visudo -c` walks the whole include chain rather
than the one file you named. That listing doubles as an inventory: if a drop-in you
wrote is not named in the output, sudo is not reading it.

`visudo -cf FILE` checks a file in place, which is what a pipeline runs before a
configuration-management change lands. Here is the most common typo in the
language:

```bash
# AlmaLinux 10.2, x86_64
$ printf 'sam ALL=(root) NOPASSWD /usr/bin/dnf update\n' > /tmp/bad; visudo -cf /tmp/bad
/tmp/bad:1:44: syntax error
sam ALL=(root) NOPASSWD /usr/bin/dnf update
                                           ^
```

**`file:line:column`, then the line, then a caret.** The missing character is
a colon: `NOPASSWD` is a tag, tags end in `:`, and without it the parser reads
`NOPASSWD` as a command path and then finds a second command path where it
expected end of line. Note where the caret lands, at the *end*, not at the
mistake. Parsers report where they gave up, which is usually a few tokens past
where you went wrong, and sudo's runtime message is blunter still: `parse
error in /etc/sudoers near line N`, with "near" doing real work.

<details class="predict">
<summary><code>visudo -c</code> reports syntax errors. This file has none: the grammar is a user, a host, a runas, and a command name. But <code>WEBSTUFF</code> is a <code>Cmnd_Alias</code> that was never defined anywhere. Does the check pass, fail, or something else?</summary>

```bash
# AlmaLinux 10.2, x86_64
$ printf 'sam ALL=(root) WEBSTUFF\n' > /tmp/bad2; visudo -cf /tmp/bad2
/tmp/bad2:1:24: Cmnd_Alias "WEBSTUFF" referenced but not defined
/tmp/bad2: parsed OK
```

</details>

**Both.** It names the undefined alias and then says `parsed OK`, because an
unresolved alias is not a grammar error. The file is syntactically valid, and the
rule has nothing behind the name, so it grants zero commands while appearing in
`visudo -c` output. **`visudo -c` passing is not the same as your policy being in
force**; the only authoritative check is asking sudo what a user may actually run.

## Drop-in files, and the ones sudo silently ignores

Do not edit `/etc/sudoers`. Everything you write belongs in its own file, for the
same reasons drop-ins beat monolithic files everywhere else: a package upgrade
cannot conflict with your change, configuration management owns one small file,
and removing a grant is deleting a file rather than editing around it. The main
file already says so, on a line that looks exactly like a comment:

```bash
# AlmaLinux 10.2, x86_64
$ grep -n 'includedir' /etc/sudoers
120:#includedir /etc/sudoers.d
```

**That `#` is not a comment.** `#include` and `#includedir` are directives that
predate the modern spelling, and they still work; sudo 1.9.1 introduced `@include`
and `@includedir`, which are the same thing without the confusing punctuation.
People delete this line while tidying comments, and every drop-in on the machine
stops being read at once.

<figure class="learn-figure">
<svg viewBox="0 0 720 350" role="img" aria-labelledby="sd-title sd-desc" style="width:100%;height:auto;">
  <title id="sd-title">The order sudo reads its policy files, and which drop-ins it skips</title>
  <desc id="sd-desc">Sudo parses /etc/sudoers from the top. When it reaches the includedir directive on line 120, it suspends the main file and reads every file in /etc/sudoers.d in sorted lexical order, skipping any file name that contains a dot or ends in a tilde. Skipped files produce no message at all. After the directory, parsing returns to the remainder of /etc/sudoers. Rules accumulate across all of these files, and when more than one rule matches, the last one read is the one that applies.</desc>
  <g font-family="ui-monospace, monospace">
    <rect x="18" y="26" width="212" height="62" rx="5" fill="currentColor" fill-opacity="0.12" stroke="currentColor" stroke-opacity="0.4"/>
    <text x="124" y="48" text-anchor="middle" font-size="11.5" fill="currentColor">/etc/sudoers</text>
    <text x="124" y="66" text-anchor="middle" font-size="9.5" fill="currentColor" fill-opacity="0.65">lines 1 to 119</text>
    <text x="124" y="80" text-anchor="middle" font-size="9.5" fill="currentColor" fill-opacity="0.65">Defaults, then rules</text>
    <rect x="18" y="134" width="212" height="54" rx="5" fill="currentColor" fill-opacity="0.07" stroke="currentColor" stroke-opacity="0.3"/>
    <text x="124" y="156" text-anchor="middle" font-size="11.5" fill="currentColor">line 120</text>
    <text x="124" y="174" text-anchor="middle" font-size="9.5" fill="currentColor" fill-opacity="0.65">@includedir /etc/sudoers.d</text>
    <rect x="18" y="234" width="212" height="54" rx="5" fill="currentColor" fill-opacity="0.12" stroke="currentColor" stroke-opacity="0.4"/>
    <text x="124" y="256" text-anchor="middle" font-size="11.5" fill="currentColor">/etc/sudoers</text>
    <text x="124" y="274" text-anchor="middle" font-size="9.5" fill="currentColor" fill-opacity="0.65">the rest of the file</text>
    <rect x="322" y="26" width="380" height="262" rx="5" fill="currentColor" fill-opacity="0.05" stroke="currentColor" stroke-opacity="0.28"/>
    <text x="342" y="50" font-size="10.5" fill="currentColor" fill-opacity="0.8">/etc/sudoers.d, in sorted lexical order</text>
    <text x="342" y="82" font-size="10.5" fill="currentColor">01-ops</text>
    <text x="342" y="104" font-size="10.5" fill="currentColor">10-deploy</text>
    <text x="342" y="126" font-size="10.5" fill="currentColor">sam</text>
    <text x="560" y="82" font-size="9.5" fill="currentColor" fill-opacity="0.6">read</text>
    <text x="560" y="104" font-size="9.5" fill="currentColor" fill-opacity="0.6">read</text>
    <text x="560" y="126" font-size="9.5" fill="currentColor" fill-opacity="0.6">read</text>
    <text x="342" y="170" font-size="10.5" fill="currentColor" fill-opacity="0.45">sam.conf</text>
    <text x="342" y="192" font-size="10.5" fill="currentColor" fill-opacity="0.45">deploy.bak</text>
    <text x="342" y="214" font-size="10.5" fill="currentColor" fill-opacity="0.45">notes~</text>
    <text x="440" y="170" font-size="9.5" fill="currentColor" fill-opacity="0.6">skipped: contains a dot</text>
    <text x="440" y="192" font-size="9.5" fill="currentColor" fill-opacity="0.6">skipped: contains a dot</text>
    <text x="440" y="214" font-size="9.5" fill="currentColor" fill-opacity="0.6">skipped: ends in a tilde</text>
    <text x="342" y="250" font-size="9.5" fill="currentColor" fill-opacity="0.75">no message is printed for a skipped file</text>
    <text x="342" y="268" font-size="9.5" fill="currentColor" fill-opacity="0.75">and nothing is written to any log</text>
    <text x="18" y="322" font-size="10.5" fill="currentColor">Rules accumulate across every file. When more than one matches, the last one read wins.</text>
  </g>
  <g stroke="currentColor" stroke-opacity="0.45" fill="none" stroke-width="1.2">
    <path d="M124 88 L124 130 M120 124 L124 131 L128 124"/>
    <path d="M230 152 L300 152 L300 96 L318 96 M312 92 L319 96 L312 100"/>
    <path d="M318 140 L300 140 L300 250 L124 250 L124 234 M120 240 L124 233 L128 240"/>
  </g>
</svg>
<figcaption>Two files can both mention the same user. Last match wins, which is why a drop-in named 99-something overrides one named 10-something.</figcaption>
</figure>

Before anything is written, sudo's answer for this account is unambiguous:

```bash
# AlmaLinux 10.2, x86_64
$ sudo -l -U sam
User sam is not allowed to run sudo on 83932010de01.
```

Now grant the one command from the opening scenario: write the file, set its mode.

```bash
# AlmaLinux 10.2, x86_64
$ echo 'sam ALL=(root) /usr/bin/systemctl restart httpd' > /etc/sudoers.d/sam; chmod 0440 /etc/sudoers.d/sam; sudo -l -U sam
Matching Defaults entries for sam on b673959cada4:
    !visiblepw, always_set_home, match_group_by_gid, always_query_group_plugin, env_reset, env_keep="COLORS DISPLAY HOSTNAME HISTSIZE KDEDIR LS_COLORS", env_keep+="MAIL PS1 PS2 QTDIR USERNAME LANG LC_ADDRESS LC_CTYPE", env_keep+="LC_COLLATE LC_IDENTIFICATION LC_MEASUREMENT LC_MESSAGES", env_keep+="LC_MONETARY LC_NAME LC_NUMERIC LC_PAPER LC_TELEPHONE", env_keep+="LC_TIME LC_ALL LANGUAGE LINGUAS _XKB_CHARSET XAUTHORITY", secure_path=/sbin\:/bin\:/usr/sbin\:/usr/bin

User sam may run the following commands on b673959cada4:
    (root) /usr/bin/systemctl restart httpd
```

**`sudo -l -U sam` is the authoritative answer to "what can this account do".** It
does not read the file the way you would; it asks the policy engine, with includes
resolved, aliases expanded, and last-match-wins already applied. The two halves are
the `Defaults` in force for that user and the rules that match. Run it as root, or
grant the `list` built-in, because by default only root or somebody who can already
run any command may ask about another user; everyone else gets a bare `sudo -l`
about themselves.

The command must be **fully qualified**: `sam ALL=(root) systemctl restart httpd`
matches nothing useful, because sudoers matches on the path.

Now the failure that costs people an afternoon.

<details class="predict">
<summary>The directive skips file names that contain a dot or end in a tilde, so package managers and editors can leave backups in the directory safely. The rule below is byte-identical to the one that worked a moment ago, the file is root-owned and mode 0440, and <code>visudo -c</code> is happy. It is named <code>sam.conf</code>. What does <code>sudo -l -U sam</code> say?</summary>

```bash
# AlmaLinux 10.2, x86_64
$ echo 'sam ALL=(root) /usr/bin/systemctl restart httpd' > /etc/sudoers.d/sam.conf; chmod 0440 /etc/sudoers.d/sam.conf; sudo -l -U sam
User sam is not allowed to run sudo on 42c7581fcd38.
```

</details>

**Not allowed, and no explanation offered.** Naming configuration files
`something.conf` is correct nearly everywhere else on the system and wrong here.
Renaming is the entire fix:

```bash
# AlmaLinux 10.2, x86_64
$ ls -l /etc/sudoers.d/; mv /etc/sudoers.d/sam.conf /etc/sudoers.d/sam; sudo -l -U sam | tail -2
total 4
-r--r-----. 1 root root 48 Aug  8 17:52 sam.conf
User sam may run the following commands on 764ee7a8f02f:
    (root) /usr/bin/systemctl restart httpd
```

Nothing about the file changed except its name. Same content, owner, mode, and
timestamp. It is the most valuable thing in the topic to have seen once,
because every instinct says to check the contents and the permissions, and
both were right the whole time. The naming rules, in full:

| File name | Read? |
| --- | --- |
| `sam`, `10-deploy`, `01_ops` | Yes |
| `sam.conf`, `deploy.bak`, `10-deploy.disabled` | No, contains a dot |
| `notes~` | No, ends in a tilde |

Order is lexical, not numeric. `1_whoops` sorts *after* `10_second`, so use a
consistent number of leading digits when order matters, and it does matter,
because when two rules match the same user and command, the last one read
applies.

The other rejection is louder, and the contrast is the point.

<details class="predict">
<summary>Sudo refuses to read a policy file that people other than root can write to, because a policy file anyone can edit is not a policy. This file is correctly named and correctly worded, and someone has run <code>chmod 0666</code> on it. Does sudo ignore it the way it ignored <code>sam.conf</code>?</summary>

```bash
# AlmaLinux 10.2, x86_64
$ echo 'sam ALL=(root) /usr/bin/systemctl restart httpd' > /etc/sudoers.d/sam; chmod 0666 /etc/sudoers.d/sam; sudo -l -U sam
sudo: /etc/sudoers.d/sam is world writable
User sam is not allowed to run sudo on 734ac5f0a16a.
```

</details>

**It complains, by name, before it answers.** Compare that with the silence over
`sam.conf`: a permissions problem announces itself, a naming problem does not. When
a rule is not taking effect and sudo has said nothing at all, check the name first.

```bash
# AlmaLinux 10.2, x86_64
$ ls -l /etc/sudoers.d/sam; chmod 0440 /etc/sudoers.d/sam; sudo -l -U sam | tail -2
-rw-rw-rw-. 1 root root 48 Aug  8 17:55 /etc/sudoers.d/sam
User sam may run the following commands on 68ba09ec5918:
    (root) /usr/bin/systemctl restart httpd
```

**0440, owned by root, is the mode for every file in that directory.** Group
writable is refused for the same reason world writable is.

## Aliases, and when they earn their place

An alias is a named list. Four kinds, one for each field of a rule:

```bash
# AlmaLinux 10.2, x86_64
$ printf '%s\n' 'Cmnd_Alias SERVICES = /usr/bin/systemctl restart httpd, /usr/bin/systemctl restart nginx' 'sam ALL=(root) SERVICES' > /etc/sudoers.d/services; chmod 0440 /etc/sudoers.d/services; sudo -l -U sam | tail -2
User sam may run the following commands on 303fa203fd2c:
    (root) /usr/bin/systemctl restart httpd, /usr/bin/systemctl restart nginx
```

**`sudo -l` expanded the alias.** It reports what the rule resolves to rather than
what you typed, which makes it the right thing to paste into a change record. The
four kinds, and where each one sits:

| Alias | Substitutes for | Example use |
| --- | --- | --- |
| `User_Alias` | The who field | `User_Alias DEPLOYERS = sam, jo, priya` |
| `Host_Alias` | The where field | `Host_Alias WEBSERVERS = web01, web02, 10.0.4.0/24` |
| `Runas_Alias` | The parenthesised field | `Runas_Alias APPS = app, worker` |
| `Cmnd_Alias` | The command field | `Cmnd_Alias SERVICES = /usr/bin/systemctl restart httpd` |

Put together, they turn a wall of near-identical lines into one readable rule:

```
User_Alias  DEPLOYERS = sam, jo, priya
Host_Alias  WEBSERVERS = web01, web02
Runas_Alias APPS = app
Cmnd_Alias  APPCTL = /usr/bin/systemctl restart api, /usr/bin/systemctl reload api

DEPLOYERS WEBSERVERS = (APPS) APPCTL
```

**Alias names must be upper case**, starting with an upper-case letter and
containing only upper-case letters, digits, and underscores. That is a grammar rule
rather than a convention: it is what lets the parser tell an alias from a user name.

**A group in the who field is not an alias.** `%wheel` is a real Unix group looked
up through `getent`; `WHEEL` would be an alias you defined. Groups win when the
membership already exists in your identity system, aliases when the grouping is
specific to this policy.

Negation exists, `!` before a command excludes it, and is much weaker than it
looks:

```
# This does not do what it appears to do
sam ALL=(ALL) ALL, !/usr/bin/su, !/bin/bash
```

The user has `ALL`. They can copy `bash` to another name and run that, or reach a
shell through any of a hundred other permitted programs, and the sudoers manual is
blunt that restrictions of this shape are advisory at best. **Blacklisting after
granting `ALL` is not a control.**

## NOPASSWD, and what it costs

A tag goes before the command and modifies it:

```bash
# AlmaLinux 10.2, x86_64
$ printf '%s\n' 'sam ALL=(root) NOPASSWD: /usr/bin/dnf update' > /etc/sudoers.d/sam-dnf; chmod 0440 /etc/sudoers.d/sam-dnf; sudo -l -U sam | tail -2
User sam may run the following commands on 04fadd9efca1:
    (root) NOPASSWD: /usr/bin/dnf update
```

**The tag shows up in `sudo -l` output**, which makes it the easiest thing here to
audit for across a fleet.

The password prompt is not authorisation, that happened when the rule matched.
It is a **presence check**, and its state lives in a timestamp:

- Per user **and per terminal** by default (`timestamp_type` is `tty`), under
  `/run/sudo/ts`, so authenticating in one window does not authorise another.
- Valid for `timestamp_timeout` minutes, default **5**.
- `sudo -v` refreshes it without running anything, `sudo -k` invalidates it, and
  `sudo -K` removes it entirely.

`NOPASSWD` removes that check for the tagged command, and the cost is that
**anything running as that user can invoke the command as root with no human
involved**: a hijacked SSH session, a malicious dependency in a build, a
compromised CI runner, a script somebody was persuaded to paste. On an escapable
command it is unattended root, and that pairing is the finding a reviewer looks for
first.

Where it is legitimate is narrow and real: **non-interactive automation**, where
there is no terminal to prompt and a prompt means failure. When you write one, put
it on a **dedicated service account** so the grant does not follow a person around
or survive their offboarding, pin the arguments, and prefer a wrapper script you
own that takes no arguments, so there is nothing to manipulate.

## A narrow rule is frequently not narrow

**If a permitted command can execute another program, you have granted a root
shell.** Not "might have". Sudo's own manual opens the subject the same way: once
sudo executes a program, that program is free to do whatever it pleases, including
run other programs. The category is larger than people expect, because running
other programs is a *feature* in most of these:

| Permitted command | The feature that gives it away |
| --- | --- |
| `vi`, `vim`, `nano` | `:!command` and `:shell`; nano has an execute-command prompt |
| `less`, `more`, `most` | `!command` from the pager prompt |
| `man`, `git log`, `systemctl status`, `journalctl` | They open a pager, and the pager is the escape |
| `awk`, `perl`, `python`, `ruby`, `ed` | A scripting language. `system()` is one call away |
| `find` | `-exec` is the documented purpose of the flag |
| `tar` | `--checkpoint-action=exec=` and `--to-command` |
| `rsync` | `-e` names the remote shell |
| `ssh` | `ProxyCommand` and `LocalCommand` |
| `env`, `nice`, `nohup`, `timeout`, `xargs`, `watch` | Their entire job is to run another program |
| `dnf`, `apt` | Plugins and package scriptlets run as root |

A second category reaches root without executing anything: **any command that can
write an arbitrary file as root**. `sudo tee`, `sudo cp`, `sudo dd`, `sudo chmod`,
`sudo chown` on the wrong target. If you can write `/etc/sudoers.d/anything`, a
systemd unit, or root's `authorized_keys`, the escape is one step longer and every
bit as complete.

And **sudo is itself a set-user-ID program with a security history**: CVE-2021-3156,
a heap overflow in its command-line argument parsing, was exploitable by any local
user whether or not they appeared in sudoers at all. Patch promptly, and do not
treat "we use sudo" as the end of a conversation about local privilege.

The defensive rule is short: **permit programs that do one thing and then exit.**
`systemctl restart httpd` does not page and does not exec; `systemctl status httpd`
pages. That is the difference between a good rule and a bad one, and it is not
visible in the rule's length.

Three practical moves, in order of how much they buy:

1. **Choose a different command.** `sudoedit` instead of `sudo vi`; a specific
   `systemctl` verb instead of `systemctl`; a wrapper script you wrote instead of
   a general-purpose tool.
2. **Pin the arguments**, so `journalctl -u api --no-pager` is permitted and bare
   `journalctl` is not.
3. **Add `NOEXEC:`** to the command, which asks the kernel to refuse the exec
   family of calls for that process. It helps, and it is not complete. The panel
   below is about exactly where it stops.

### The wildcard trap

Wildcards look like the tool for "any file under this directory", and they are not,
because of one sentence in the grammar: **command line arguments are matched as a
single, concatenated string**, and `*` matches any character including spaces and
slashes. (In the *path* portion of a command a wildcard will not match a `/`; in
the arguments it will. That asymmetry is what makes this surprising.)

```
# Intended: let the web team fix ownership under the document root
%web ALL=(root) /usr/bin/chown * /var/www
```

The pattern the user's arguments must match is `* /var/www`. So this matches:

```
sudo chown apache /var/www
sudo chown apache /etc/shadow /var/www
```

The second concatenates to `apache /etc/shadow /var/www`, the leading `*` swallows
`apache /etc/shadow`, and `/etc/shadow` changes owner. Nothing was bypassed; the
rule was written to permit it.

Three more grammar facts in the same family, all exam-relevant:

- **A command with no arguments listed permits any arguments.**
  `sam ALL=(root) /usr/bin/systemctl` is a grant of every systemctl subcommand
  against every unit, which is very close to root on a systemd machine.
- **`""` as the only argument means no arguments are allowed.**
  `sam ALL=(root) /usr/bin/systemctl ""` permits `systemctl` and nothing else,
  which is finally narrow.
- A command that is a **directory ending in `/`** permits every file directly in
  it, and not in its subdirectories.

Since sudo 1.9.10 the safer tool is a regular expression, written between `^` and
`$`:

```
%web ALL=(root) /usr/bin/chown ^apache /var/www/[a-zA-Z0-9._-]*$
```

Anchored at both ends, and the character class cannot match a space or a slash, so
there is no second path to smuggle in. The path and the arguments are matched
separately, so one regular expression can never cover both. **Where the matching
gets complicated, stop matching in sudoers**: grant one no-argument wrapper script,
owned by root and not writable by the user, and validate in the script where you
can test it.

<details class="deeper">
<summary>If you already administer Linux: NOEXEC, intercept, and sudoedit, or how far you can actually get with a permitted editor</summary>

Take the request at face value: somebody needs to edit one root-owned
configuration file. The naive grant, `sam ALL=(root) /usr/bin/vi /etc/app.conf`, is
a full root shell, because `:!sh` exists.

**`NOEXEC:` is the first real answer.** Tag the command and sudo arranges for the
process to be unable to start other programs:

```
sam ALL=(root) NOEXEC: /usr/bin/vi /etc/app.conf
```

How it is implemented decides the caveats. **On Linux it is a `seccomp` filter**,
which sits in the kernel and covers the whole process, statically linked or not.
Elsewhere it is `LD_PRELOAD`: a shared object overriding `execve`, `system`,
`popen`, `posix_spawn` and relatives, which the dynamic loader ignores for static
binaries and for set-user-ID programs. Reasoning about an older or non-Linux
machine, assume the weaker version.

**What `NOEXEC` does not stop is why it is not a complete answer.** The process is
still root, so writing `/etc/sudoers.d/oops`, a systemd unit, a cron job, or root's
`authorized_keys` is an escape that never calls `exec` at all. An editor running as
root is a general-purpose file writer by definition.

`INTERCEPT:` is the heavier tool. It does not block new commands; it checks
each one against sudoers and logs it. Two mechanisms: `dso`, the `LD_PRELOAD`
approach with the same dynamic-linking limits and no SELinux RBAC support, and
`trace`, built on `ptrace` and `seccomp`, which handles static binaries, works
under RBAC, and since 1.9.12 verifies the arguments did not change between the
policy check and the exec, a race `dso` still has. The cost is real: anything
that uses `ptrace` itself, `strace` and `gdb` included, stops working under
it, and the same restriction applies to `log_subcmds`.

For the original request the correct answer is neither. It is `sudoedit`:

```
sam ALL=(root) sudoedit /etc/app.conf
```

`sudoedit` is built into sudo, so it is written **without a path**, a rule
naming `/usr/bin/sudoedit` is a common mistake. It copies the file to a
temporary location, runs the user's own editor **as the user, with their own
environment**, then copies the result back with the original ownership. No
root editor process exists, so there is nothing to escape from. The `FOLLOW`
and `NOFOLLOW` tags control whether it opens a symbolic link, and since 1.8.15
it refuses by default, which closes the trick of pointing the target at
`/etc/shadow`.

The design rule: **`NOEXEC` is a mitigation for a command you have already decided
to permit, not a licence to permit one you otherwise would not.** Rank the options
as a safer command, then pinned arguments, then `NOEXEC`, then accept the risk and
log the session.

</details>

## The admin group, wheel and sudo

The blanket grant is the thing you are trying to avoid. It is worth seeing how
little it takes:

```bash
# AlmaLinux 10.2, x86_64
$ usermod -aG wheel sam; id sam; sudo -l -U sam | tail -2
uid=1000(sam) gid=1000(sam) groups=1000(sam),10(wheel)
User sam may run the following commands on 7324e1248e93:
    (ALL) ALL
```

**One `usermod` and the answer is `(ALL) ALL`.** Every command, as every user. The
shipped `%wheel ALL=(ALL) ALL` rule was already there waiting; adding the group
membership is the whole act.

Two mechanical details that cause real confusion:

- **The group name differs by family.** RHEL and its rebuilds use `wheel`; Debian
  and Ubuntu use `sudo` and do not define a `wheel` group at all, so
  `usermod -aG wheel sam` there fails outright with
  `usermod: group 'wheel' does not exist` and exit status 6. That failure is at
  least loud. The quiet version of the same mistake is creating the group first,
  after which the command succeeds and grants nothing, because no shipped rule
  mentions it.
- **Group membership is established at login.** `usermod -aG` does not change the
  groups of a session that is already open, so the user logs out and back in or the
  change appears not to have worked.

The same two commands on the other family, with the other group name:

```bash
# Debian 13 (trixie), x86_64
$ usermod -aG sudo sam; id sam; sudo -l -U sam | tail -2
uid=1000(sam) gid=1000(sam) groups=1000(sam),27(sudo)
User sam may run the following commands on 0ae0bd4c9abc:
    (ALL : ALL) ALL
```

**`(ALL : ALL)` rather than `(ALL)`.** Debian's shipped rule uses the two-part
runas field, runas-user and runas-group, so members may also pick a group with
`sudo -g`. Almost nobody does, and the difference is close to cosmetic, but it
is the sort of detail an exam question is built from, so read the parentheses.
Whether the first Debian account gets that membership at all depends on the
installer: leave the root password empty and it adds you to the `sudo` group,
set one and it does not.

<details class="deeper">
<summary>If you already administer Linux: why <code>sudo su -</code> is a smell, and precisely what it destroys</summary>

Somebody asks for `sudo su -` because it is what they have always typed. It works
by permitting `/usr/bin/su`, or more often because they already have `ALL`. What it
costs, in order of how much it hurts:

**It collapses the audit trail to one line.** The log entry says
`COMMAND=/usr/bin/su -` and then nothing further, ever. What you have instead is
root's shell history, which is unattributed, shared between everybody who did the
same thing, truncated on a crash, and trivially editable by the person you are
trying to hold accountable. On a machine with three administrators you can no
longer say who ran the destructive command, only that somebody became root at 11:04.

It defeats the timestamp model. The five-minute presence check applies to the
`su` invocation once; the root shell it produces lasts as long as the
terminal. A session left open on a borrowed laptop is unauthenticated root for
the rest of the day.

It defeats every per-command control here. `NOEXEC` applies to the tagged
command, and the tagged command was `su`. `INTERCEPT` is off unless you turned
it on. Argument pinning is meaningless. And `log_output` is per rule, so
unless somebody wrote `LOG_OUTPUT:` on that `su`, nobody who reaches for `sudo
su -` has, the session is not recorded either.

The honest counterpoint is that an interactive root shell is sometimes correct:
disaster recovery, a broken package database, an interactive `fsck`. When you need
it, use **`sudo -i`**, which runs root's login shell directly, applies the sudoers
`Defaults`, and produces one clean sudo event rather than a sudo event wrapping a
`su` event. Turn on **`log_output`** and **`use_pty`** for those grants so you get
a replayable recording instead of a gap, and time-box it with something like
`Defaults:oncall timestamp_timeout=0`.

It is a smell rather than a mistake because the request usually means somebody could
not express what they needed as a rule and gave up. Ten minutes writing the four
narrow rules that would have done the job settles it better than arguing about `su`.

</details>

## What sudo writes down

Every decision sudo makes is logged, accepted or denied, through syslog. On the
RHEL family that lands in `/var/log/secure`; on Debian and Ubuntu it is
`/var/log/auth.log`. On a systemd machine the journal has it too, and
`journalctl _COMM=sudo` is the fastest way in.

An accepted command is one line, and the sudoers manual specifies its shape. This
is that shape, wrapped to fit the page rather than captured from a machine:

```
Aug  8 17:52:04 web01 sudo: sam : TTY=pts/0 ; PWD=/home/sam ; USER=root ;
    COMMAND=/usr/bin/systemctl restart httpd
```

Read it as five facts: **who** ran it, from **which terminal**, in **which
directory**, **as whom**, and **what**. The working directory is there because the
same command means different things in different places; the runas user is there
because `root` is a default rather than the only option. When I/O logging is on the
line also carries `TSID=`, the session identifier `sudoreplay` takes.

A denial replaces those fields with a reason, and the reasons are a diagnostic list
worth knowing:

| Reason in the log | What actually happened |
| --- | --- |
| `user NOT in sudoers` | No rule anywhere names them |
| `user NOT authorized on host` | A rule names them, but its host field does not match this machine |
| `command not allowed` | They are in the policy for this host and asked for something outside it |
| `3 incorrect password attempts` | They matched a rule and failed the presence check |
| `a password is required` | `sudo -n` was used where the rule had no `NOPASSWD` |

**Those first three are different failures and people report all of them as "sudo
does not work".** Reading which one you got saves a round of guessing: a missing
rule, a host field copied from another machine, or a rule that exists and is
narrower than the user expected.

And the thing sudo does **not** log is anything the command subsequently does. The
line above records that `systemctl` started. Had the permitted command been `vi`,
the log would record `vi` and nothing about the shell that came out of it.

<details class="deeper">
<summary>If you already administer Linux: session recording with log_output, and replaying it with sudoreplay</summary>

The audit requirement usually arrives worded as "privileged sessions must be
recorded", and people buy a product for it. Sudo has had it built in since the 1.8
series; on a machine already running sudo the incremental cost is a flag. Turn it
on per rule, which is the right granularity:

```
Cmnd_Alias DBTOOLS = /usr/bin/psql, /usr/bin/mysql
%dba ALL=(root) LOG_OUTPUT: DBTOOLS
```

Or as a scoped default, `Defaults:oncall log_output`. The two flags are
`log_input`, which records what was typed, and `log_output`, which records what was
displayed; the `LOG_INPUT` and `LOG_OUTPUT` tags override them per command. Logs go
under `iolog_dir`, by default `/var/log/sudo-io`, one directory per session, keyed
by the `TSID=` value in the syslog line. Replay is the part that surprises people:

```
sudoreplay -l                    # list sessions, with a search language
sudoreplay -l user sam command /usr/bin/psql
sudoreplay 0100AB                # replay that session at original speed
sudoreplay -s 10 0100AB          # ten times faster
sudoreplay -m 2 0100AB           # cap idle gaps at 2 seconds
```

It replays timing as well as content, so you watch the session happen. For an
incident review that beats a log file, and it is the artefact that ends an argument
about what somebody actually did. Four consequences before you enable it fleet-wide.

**`log_input` records passwords.** Anything typed at a prompt inside the
session (a database password, an API token pasted into a command) is now on
disk. `iolog_mode` defaults to `0600` with root ownership, which is the
minimum. Disabling `log_passwords` makes sudo match the terminal buffer
against `passprompt_regex` and mask what follows a prompt, which is a
heuristic rather than a guarantee. Treat the directory as sensitive data with
a retention policy, and prefer `log_output` alone unless you genuinely need
keystrokes.

**Disk grows quietly.** Give `/var/log/sudo-io` its own space or a rotation job,
because filling `/var` is a worse outage than the one you were auditing.

A local log is deletable by the person you are recording, who is root by
construction. That is what `sudo_logsrvd` is for: it accepts logs over TLS on
a separate host, so the recording leaves the machine as it is made, and
`log_servers` in sudoers points clients at it. That is what an auditor means
by "tamper-evident".

Shell escapes stay invisible unless you ask. `log_output` records the screen,
so you would *see* a shell start, but no event log entry is created for the
commands run inside it. `log_subcmds` creates one per command, using the same
`ptrace` mechanism `intercept` does, with the same incompatibility with
debuggers.

</details>

## Across distributions

The policy language is identical; the shipped file is not. Here is the whole of
Debian's, comments stripped:

```bash
# Debian 13 (trixie), x86_64
$ grep -v '^#' /etc/sudoers | grep .
Defaults	env_reset
Defaults	mail_badpass
Defaults	secure_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
Defaults	use_pty
root	ALL=(ALL:ALL) ALL
%sudo	ALL=(ALL:ALL) ALL
@includedir /etc/sudoers.d
```

**Four `Defaults` against AlmaLinux's eleven**, and three differences worth naming.
`secure_path` here keeps `/usr/local/sbin` and `/usr/local/bin`, which AlmaLinux
drops. `use_pty` is set explicitly rather than left to the compiled default. And
the include directive **survived the comment strip**, because Debian writes the
modern `@includedir` where AlmaLinux still ships `#includedir`. Both work; only one
looks like a directive.

The drop-in directory is not empty on Debian either:

```bash
# Debian 13 (trixie), x86_64
$ ls -l /etc/sudoers; ls -l /etc/sudoers.d/
-r--r-----. 1 root root 1714 Apr 11 12:21 /etc/sudoers
total 4
-r--r-----. 1 root root 1068 Apr 11 12:21 README
```

`README` has no dot in its name, so it is genuinely parsed as policy. It contains
nothing but comments:

```bash
# Debian 13 (trixie), x86_64
$ visudo -c
/etc/sudoers: parsed OK
/etc/sudoers.d/README: parsed OK
```

Everything else that differs:

| | RHEL family | Debian family |
| --- | --- | --- |
| Admin group | `wheel` | `sudo` |
| Shipped rule | `%wheel ALL=(ALL) ALL` | `%sudo ALL=(ALL:ALL) ALL` |
| Grant it | `usermod -aG wheel sam` | `usermod -aG sudo sam` |
| Policy file | `/etc/sudoers`, mode 0440 | `/etc/sudoers`, mode 0440 |
| Drop-in directory | `/etc/sudoers.d`, empty | `/etc/sudoers.d`, with a `README` |
| Include directive | `#includedir` | `@includedir` |
| `secure_path` includes `/usr/local` | No | Yes |
| Log lands in | `/var/log/secure` | `/var/log/auth.log` |
| `visudo` editor | `vi`, unless `EDITOR` says otherwise | `editor`, through update-alternatives, often nano |
| First account gets sudo | Only if the installer's box was ticked | Only if the root password was left empty |

**The three rows that cost time are the group name, the log path, and
`secure_path`.** The first two you get wrong once per family and never again. The
third is subtler: a script calling something in `/usr/local/bin` works under sudo on
Debian and fails on AlmaLinux, and nothing in the error says why.

**SUSE is the outlier worth one sentence.** It has historically shipped a sudoers
permitting `ALL` for all users subject to entering the *root* password rather than
the wheel-group model, so a machine you inherit may be more permissive than its
`%wheel` line suggests. Read the file rather than assuming the family.

## Prove it

```
# What does the policy engine say this account can do
sudo -l                       # as the user
sudo -l -U sam                # as root, about somebody else

# Is the whole policy even valid, and which files are in it
sudo visudo -c

# Check one file before it lands, from a pipeline
sudo visudo -cf /etc/sudoers.d/deploy

# Which drop-ins will actually be read
ls -l /etc/sudoers.d/

# What has been run, and what was refused
sudo journalctl _COMM=sudo --since today
sudo grep sudo /var/log/secure        # RHEL family
sudo grep sudo /var/log/auth.log      # Debian family
```

**`sudo -l -U` is the one to build a habit around.** Reading sudoers by eye gets
aliases, group membership, include order, and last-match-wins wrong, in roughly
that order of likelihood. Asking the engine gets all four right.

## What trips people up

### 1. Editing sudoers with a text editor

Forcing a write past mode 0440 and saving a typo means nobody can run `sudo`, on a
machine where fixing sudoers needs `sudo`. Recovery is a console root login, a
rescue boot, or `pkexec` if polkit happens to be configured for it, and all three
are worse than typing `visudo`.

### 2. A drop-in with a dot in its name

`sam.conf`, `deploy.bak`, `10-app.disabled`, anything ending in `~`: skipped in
silence. To disable a drop-in, move it out of the directory rather than renaming it
to `.disabled`, so the intent is visible.

### 3. A drop-in that anyone can write to

`sudo: /etc/sudoers.d/sam is world writable`, and the rule is discarded. Group
writable is refused too. Mode `0440`, owner `root`, group `root`. This one at least
tells you; the naming trap does not.

### 4. NOPASSWD on something that can spawn a shell

`NOPASSWD` removes the human, and a shell escape removes the boundary. Together
they are unattended root reachable by anything running as that account, including a
compromised build step. Spend the extra ten minutes on a genuinely non-escapable
command, or on a wrapper script with no arguments.

### 5. Wildcards in arguments

`*` crosses spaces and slashes, so `/usr/bin/chown * /var/www` permits
`chown apache /etc/shadow /var/www`. Anchor a regular expression instead, or move
the argument checking into a script.

### 6. Adding somebody to wheel because the narrow rule was fiddly

Four seconds of work, and it grants `(ALL) ALL`. The rule that took twenty minutes
is the one still correct when that person changes teams.

## Work it through

A deploy account, `deployer`, runs the release pipeline on a web server. It needs
to restart the application, read the application's logs when a restart fails, and
edit one configuration file during an incident. Write the policy, and reason it out
before reading on.

**The naive version, and why each line is wrong.**

```
deployer ALL=(root) /usr/bin/systemctl, /usr/bin/journalctl, /usr/bin/vi
```

`systemctl` with no arguments is every subcommand against every unit, including
`systemctl edit`, which opens an editor as root. `journalctl` opens a pager, and
`!sh` at a pager prompt is a root shell. `vi` is a root shell in one keystroke.
Three commands, three independent routes to the thing you were trying not to grant.

**Narrow each one to the verb rather than the tool.**

```
Cmnd_Alias APPCTL = /usr/bin/systemctl restart api, /usr/bin/systemctl status api --no-pager
Cmnd_Alias APPLOG = /usr/bin/journalctl -u api --no-pager, /usr/bin/journalctl -u api -n 200 --no-pager

deployer ALL=(root) APPCTL, APPLOG
deployer ALL=(root) sudoedit /etc/api/api.conf
```

Three things changed. The arguments are pinned, so `systemctl` cannot be aimed at
another unit. `--no-pager` is part of the permitted invocation, so the escape
through the pager is gone and the user cannot drop it, because the arguments must
match. And the editor became `sudoedit`, which runs as `deployer` on a temporary
copy with no root editor process to escape from.

**Decide about the password.** The pipeline is non-interactive, so
`systemctl restart api` needs `NOPASSWD:` or the deploy hangs. The incident-time
commands do not. Split them, because the tag applies per command:

```
deployer ALL=(root) NOPASSWD: /usr/bin/systemctl restart api
deployer ALL=(root) APPLOG
deployer ALL=(root) sudoedit /etc/api/api.conf
```

Fourth, put it where it will be read: `/etc/sudoers.d/deployer`, no dot in the
name, mode 0440, owned by root, checked with `visudo -cf` before it lands and
confirmed with `sudo -l -U deployer` afterwards.

Now change one detail. Suppose the cache directory also needs clearing, and
somebody proposes `/usr/bin/rm -rf /var/cache/api/*`. The user's shell expands
that wildcard before sudo ever sees it, and the sudoers pattern is matched
against whatever arrives, so the rule is both fragile and wide. The right
shape is a two-line script owned by root, mode 0755, granted with no arguments
at all.

**And one more.** Suppose the log request had been "read anything, we cannot know
in advance which unit". Argument pinning cannot help, so the honest answers are to
add `deployer` to the `systemd-journal` group and use no sudo at all, or to accept
a broad grant and turn on `log_output`. Adding somebody to a group that already
holds the access you want to grant beats most sudo rules, and it is the option
people forget because the question arrived with the word "sudo" in it.

The point worth extracting: **the width of a sudo rule is not the length of the
line.** It is the set of things the permitted program can be made to do, including
every program it can start and every file it can write.

## Try it

Optional, on a virtual machine you can break. Keep a second root session open
before you touch sudoers.

1. `sudo -l` as yourself, and read both halves of the output.
2. `grep -v '^#' /etc/sudoers | grep .` and identify every line as either a
   `Defaults` or a rule.
3. `sudo visudo -c` and note that it lists more than one file.
4. Create a test user and grant one command in `/etc/sudoers.d/test`, mode 0440.
   Confirm with `sudo -l -U test`.
5. Rename that file to `test.conf` and run `sudo -l -U test` again. Notice that
   nothing anywhere tells you what happened.
6. Rename it back, then `chmod 0666` it and run `sudo -l -U test` once more.
   Compare the two failures.
7. Write a deliberately broken rule to a scratch file and run `visudo -cf` on it.
   Read the line and column, and find the real mistake relative to the caret.
8. Grant the test user `/usr/bin/less /var/log/messages`, then work out on
   paper, not on the machine, which keystroke would give them a root shell,
   and rewrite the rule so it cannot.

**Verification step.** You have it when you can look at an unfamiliar sudoers
rule and say, without running anything, whether the permitted command can
start another program or write an arbitrary file, and therefore whether the
rule grants what it appears to grant.

## Check yourself

<details class="qa">
<summary>You write <code>sam ALL=(root) /usr/bin/systemctl restart httpd</code> into <code>/etc/sudoers.d/sam.conf</code>, owned by root, mode 0440. <code>visudo -c</code> reports everything parsed OK. <code>sudo</code> still refuses. What is wrong?</summary>

**The file name contains a dot, so the `@includedir` directive skips it.**

The directive reads every file in `/etc/sudoers.d` *except* names that contain a
`.` or end in `~`, so package managers and editors can leave `.rpmnew`, `.dpkg-old`
and backup files in the directory without them becoming policy. Renaming the file
to `sam` is the entire fix; nothing about its contents, owner, mode, or wording
needs to change.

**The tempting wrong answer is ownership or permissions**, because that is the
usual cause of a file being ignored. It is not the cause here, and there is a
reliable way to tell the two apart: a permissions problem *prints something*,
`sudo: /etc/sudoers.d/sam is world writable`, and a naming problem prints
nothing at all, in any log, ever. **Silence points at the name.**

The second tempting wrong answer is that `visudo -c` would have caught it. It
would not, and for an instructive reason: `visudo -c` walks the same include chain
sudo does, so it skipped the file for the same reason. The signal is in what the
output *omits*. If a file you wrote is not listed in `visudo -c`, it is not policy.

The thing you will need next: files in that directory are read in **lexical**
order, not numeric, so `9-app` sorts after `10-app`. Use a consistent number of
leading digits, because when two rules match the same user and command, the last
one read wins.

</details>

<details class="qa">
<summary>A rule permits exactly <code>/usr/bin/vi /etc/app.conf</code> and nothing else. Is that one file's worth of privilege? What should the rule have been?</summary>

**No. It is a root shell.** `vi` runs shell commands with `:!command`, and `:shell`
starts an interactive one. The moment `vi` is running as root, everything it can do
is running as root, and running other programs is a documented feature of the
editor rather than a flaw in sudo.

The principle: **if a permitted command can execute another program, you have
granted a root shell.** The same reasoning applies to `less`, `more`, `awk`,
`find` with `-exec`, `tar --checkpoint-action`, `env`, `xargs`, and anything
that opens a pager: `man`, `git log`, `systemctl status`, `journalctl`.

**The tempting wrong answer is `NOEXEC:`.** It genuinely helps: on Linux with
current sudo it installs a seccomp filter that refuses the `exec` family for
that process. But the process is still root, and an editor running as root can
write any file on the machine, including `/etc/sudoers.d/anything`, a systemd
unit, or root's `authorized_keys`. `NOEXEC` closes the fast route and leaves
the obvious one open, so treat it as a mitigation for a command you have
already decided to permit rather than a reason to permit one.

**The rule should have been `sam ALL=(root) sudoedit /etc/app.conf`.** `sudoedit`
copies the file to a temporary location, runs the user's own editor **as the user**,
and copies the result back with the original ownership. No root editor process
exists at any point.

Two details for when you write it: `sudoedit` is built into sudo, so it goes in the
rule **without a leading path**, and since 1.8.15 it refuses to open a symbolic
link by default, which closes the trick of pointing the target at `/etc/shadow`.

</details>

<details class="qa">
<summary><code>%web ALL=(root) /usr/bin/chown * /var/www</code> was meant to let the web team fix ownership under the document root. What did it actually grant?</summary>

**`chown` on any file on the machine.**

Sudoers matches command line arguments as a **single concatenated string**, and `*`
matches any character, including spaces and slashes. The pattern is `* /var/www`,
so `chown apache /etc/shadow /var/www` concatenates to
`apache /etc/shadow /var/www`, the wildcard absorbs `apache /etc/shadow`, and the
match succeeds. The shadow file changes owner, and from there the account is root.

**The tempting wrong answer is that the `*` only stands in for the ownership
argument**, which is what it looks like and what the person who wrote the rule
believed. Wildcards in sudoers are glob patterns applied to one flat string,
not per-argument placeholders, and a `*` in the *path* portion of a command
will not match a `/`, while a `*` in the *arguments* will, which is exactly
the asymmetry that makes this surprising.

**The fix is an anchored regular expression**, supported since sudo 1.9.10:

```
%web ALL=(root) /usr/bin/chown ^apache /var/www/[a-zA-Z0-9._-]*$
```

Anchored at both ends, and the character class cannot match a space or a slash, so
there is no second path to smuggle in.

The two related grammar facts you will need next: a command with **no arguments
listed permits any arguments**, so `/usr/bin/systemctl` on its own is far wider
than it reads; and `""` as the only argument means the command may be run
**only** with no arguments. And where the matching gets complicated, stop matching in
sudoers and grant a no-argument wrapper script that you own.

</details>

<details class="qa">
<summary>What does <code>NOPASSWD:</code> actually remove, what does that cost, and when is it the right answer?</summary>

**It removes a presence check, not an authorisation check.** Authorisation
happened when the rule matched. The password prompt exists to confirm a human
is at the keyboard, and its result is cached in a timestamp kept per user and
per terminal under `/run/sudo/ts`, valid for `timestamp_timeout` minutes, five
by default.

The cost is that anything running as that account can now invoke the command
as root with nobody present. A hijacked SSH session, a malicious dependency in
a build, a compromised CI runner, a script somebody was persuaded to paste.
The prompt is what would have made those visible.

The tempting wrong answer is "they already have the privilege, so the password
adds nothing". It adds the requirement that a person be there, which is
precisely the property that separates an administrator doing their job from a
process acting in their name. It is also the control that limits blast radius
when a session is stolen rather than an account.

It is the right answer for non-interactive automation, where there is no
terminal to prompt and a prompt means failure: a monitoring agent, an Ansible
task, a cron job. When you write one, put it on a dedicated service account
rather than a human's, pin the arguments, and prefer a wrapper script with no
arguments so there is nothing to manipulate.

The thing to check next: **`NOPASSWD` on an escapable command is unattended root**,
and it shows up in `sudo -l` output as a literal `NOPASSWD:` tag, which makes it
the easiest thing in this topic to audit for across a fleet.

</details>

<details class="qa">
<summary>An administrator wants <code>sudo su -</code> rather than a set of narrow rules. What does that destroy, and what would you offer instead?</summary>

**It collapses the audit trail to a single line.** Sudo logs the command it ran, so
the entry says `COMMAND=/usr/bin/su -` and records nothing after it. Every command
in the resulting session is invisible. What is left is root's shell history:
unattributed, shared between everybody who did the same thing, lost on a crash, and
editable by the person you are trying to hold accountable.

It also **defeats the timestamp model** (one presence check, then a root shell
that lasts as long as the terminal) and **defeats every per-command control in
this topic**, because `NOEXEC`, argument pinning, and `INTERCEPT` all apply to
the command that was tagged, and the command that was tagged was `su`.

**The tempting wrong answer is that `sudo -i` is the same thing.** It is a
blanket grant too, but it is a better one: it runs root's login shell
directly, applies the `Defaults` from sudoers, and produces one clean sudo
event instead of a sudo event wrapping a `su` event. If somebody genuinely
needs an interactive root shell (disaster recovery, a broken package database,
an interactive `fsck`) `sudo -i` is what to give them.

**And make it recordable.** `LOG_OUTPUT:` on that rule, with `use_pty` (on by
default since sudo 1.9.14), turns the gap into a session you can replay with
`sudoreplay`. That is the difference between an unexplained hour and an artefact.

The thing worth noticing underneath the request: it usually means somebody could
not express what they needed as a rule and gave up. Ten minutes writing the four
narrow rules that would have done the job resolves it better than any argument
about `su`.

</details>

## References

- [sudoers(5)](https://www.sudo.ws/docs/man/sudoers.man/) - Sudo Project. Accessed 2026-08-08.
- [sudo(8)](https://www.sudo.ws/docs/man/sudo.man/) - Sudo Project. Accessed 2026-08-08.
- [visudo(8)](https://www.sudo.ws/docs/man/visudo.man/) - Sudo Project. Accessed 2026-08-08.
- [sudoreplay(8)](https://www.sudo.ws/docs/man/sudoreplay.man/) - Sudo Project. Accessed 2026-08-08.
- [sudo_logsrvd(8)](https://www.sudo.ws/docs/man/sudo_logsrvd.man/) - Sudo Project. Accessed 2026-08-08.
- [Sudo security advisories](https://www.sudo.ws/security/advisories/) - Sudo Project. Accessed 2026-08-08.
- [sudoers(5) as shipped by Debian trixie](https://manpages.debian.org/trixie/sudo/sudoers.5.en.html) - Debian Project. Accessed 2026-08-08.
- [sudo](https://wiki.debian.org/sudo) - Debian Project. Accessed 2026-08-08.

Captured output came from two containers: AlmaLinux 10.2 running sudo 1.9.17p2 and
Debian 13 (trixie), each with a test account called `sam` and a scratch drop-in
directory. The ignored file, the world-writable file, and both `visudo` errors are
real refusals produced by creating those conditions, not illustrations. Blocks
without a distribution and architecture header are sourced from the sudo project's
documentation or are policy written to be read rather than run: the log line
format, the alias examples, the wildcard and regular expression rules, and
everything in the `Work it through` section are all of that kind.
