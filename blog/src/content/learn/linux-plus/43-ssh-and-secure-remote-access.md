---
title: "The key is installed and it still asks for a password"
description: "SSH is two programs on two machines, each with its own configuration and each deliberately quiet about why it said no. Key pairs, the permission rules that silently refuse a good key, and reading the effective configuration instead of arguing about files."
track: "linux-plus"
level: "working"
order: 440
objectives:
  - "Generate a key pair and install the public half on a server"
  - "Diagnose a refused key from the client and from the server, and say which holds the answer"
  - "Read sshd's effective configuration with sshd -T rather than reading a file"
  - "Harden sshd_config without locking yourself out of a remote machine"
prerequisites: ["users-root-and-sudo", "reading-and-setting-permissions"]
tags: ["linux", "linux-plus", "ssh", "openssh", "security", "remote-access"]
updated: 2026-08-08
draft: false
examObjectives:
  - exam: "xk0-006"
    domain: "3.0"
    objective: "3.3"
sources:
  - title: "ssh(1)"
    url: "https://man7.org/linux/man-pages/man1/ssh.1.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-08
    tier: 1
  - title: "sshd(8)"
    url: "https://man7.org/linux/man-pages/man8/sshd.8.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-08
    tier: 1
  - title: "sshd_config(5)"
    url: "https://man7.org/linux/man-pages/man5/sshd_config.5.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-08
    tier: 1
  - title: "ssh_config(5)"
    url: "https://man7.org/linux/man-pages/man5/ssh_config.5.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-08
    tier: 1
  - title: "ssh-keygen(1)"
    url: "https://man7.org/linux/man-pages/man1/ssh-keygen.1.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-08
    tier: 1
  - title: "ssh-agent(1)"
    url: "https://man7.org/linux/man-pages/man1/ssh-agent.1.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-08
    tier: 1
  - title: "ssh-copy-id(1)"
    url: "https://man7.org/linux/man-pages/man1/ssh-copy-id.1.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-08
    tier: 1
  - title: "sftp(1)"
    url: "https://man7.org/linux/man-pages/man1/sftp.1.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-08
    tier: 1
  - title: "jail.conf(5)"
    url: "https://manpages.debian.org/trixie/fail2ban/jail.conf.5.en.html"
    publisher: "Debian manpages"
    accessed: 2026-08-08
    tier: 1
symptoms:
  - symptom: "Permission denied (publickey)"
    anchor: "getting-the-public-half-onto-the-server"
  - symptom: "WARNING: UNPROTECTED PRIVATE KEY FILE"
    anchor: "1-the-private-key-is-readable-by-somebody-else"
  - symptom: "Authentication refused: bad ownership or modes for directory"
    anchor: "2-the-home-directory-is-group-writable"
  - symptom: "sshd_config: unsupported option"
    anchor: "check-the-file-before-you-reload-it"
---

> **Before you read.** You generated a key, copied the public half to the server,
> and checked with your own eyes that it is sitting in `authorized_keys`. You
> connect, and it asks for a password anyway. Nothing in the output says why. The
> connection was accepted, so the network is fine and the server is running.
>
> **What is refusing a key that is demonstrably present?**

Something on the far machine decided your key was not trustworthy and did not say so,
because saying so would tell an attacker the same thing. The reason is usually not
the key at all: it is the permissions on the directory the key file sits in, and the
only machine that knows that is the one that refused you. That is the shape of almost
every SSH problem. **Two programs, on two machines, each with its own configuration
file, each built to be unhelpful in public.** The skill is knowing which of the two
you are talking to, and how to make it show you what it thinks rather than what a
file says.

### Some words you will need

<dl class="terms">
<dt>client</dt>
<dd><code>ssh</code>, the program you run. It reads <code>~/.ssh/config</code> and then <code>/etc/ssh/ssh_config</code>.</dd>
<dt>server</dt>
<dd><code>sshd</code>, the daemon listening on the far machine. It reads <code>/etc/ssh/sshd_config</code> and the drop-in files beside it. The <code>d</code> is for daemon.</dd>
<dt>private key</dt>
<dd><code>~/.ssh/id_ed25519</code>. Never leaves the machine it was made on. Anybody holding it is you.</dd>
<dt>public key</dt>
<dd><code>~/.ssh/id_ed25519.pub</code>. Safe to publish, derivable from the private key, and useless on its own.</dd>
<dt>authorized_keys</dt>
<dd>A file in the target user's home directory on the <em>server</em>, listing the public keys permitted to log in as that user.</dd>
<dt>host key</dt>
<dd>The server's own key pair, in <code>/etc/ssh</code>. How the machine proves it is the same machine you reached last time.</dd>
<dt>passphrase</dt>
<dd>A password that encrypts a private key <em>file</em>. It is not the account password and it never crosses the network.</dd>
</dl>

## What breaks without this

**You cannot reach the machine at all.** Every other topic in this track quietly
assumes you already have a shell on the far end. This is the topic that gets you one.

**Your credentials cross the network as readable bytes.** Telnet and FTP send the
username and password with no encryption whatsoever, so anybody on the path reads
them once and owns the account forever. That is why both are gone from current builds
and why "we only use it internally" is not a defence.

**The server accepts password guesses from the entire internet**, thousands a day on
any public address with password authentication on.

**You reload the server with a broken configuration and lock yourself out.** The
session you are sitting in survives. The next one does not, and there is nobody in
the building.

## Two programs, and which one you are configuring

Client and server ship in separate packages and can be different versions, so start
by proving what you have:

```bash
# Debian 13 (trixie), x86_64
$ ssh -V
OpenSSH_10.0p2 Debian-7+deb13u4, OpenSSL 3.5.6 7 Apr 2026
```

Two numbers, two concerns. **OpenSSH 10.0** decides which algorithms exist and which
have been removed; **OpenSSL 3.5.6** is the library underneath, patched separately.

<figure class="learn-figure">
<svg viewBox="0 0 720 290" role="img" aria-labelledby="ssh-title ssh-desc" style="width:100%;height:auto;">
  <title id="ssh-title">Which keys live on which machine during an SSH connection</title>
  <desc id="ssh-desc">Two machines. On the left, your laptop, running the ssh client, holding your private key, your public key, your known_hosts file, and your personal client configuration. On the right, the server, running the sshd daemon, holding the authorized_keys file for the account you are logging into, the machine's own host key, and the server configuration and its drop-in directory. Three exchanges happen in order. First a key exchange establishes an encrypted channel before anybody has proved anything. Second, the server proves itself by signing with its host key, which your client checks against known_hosts. Third, you prove yourself by signing with your private key, which sshd checks against authorized_keys. The private key never crosses the wire; only a signature does.</desc>
  <g font-family="ui-monospace, monospace">
    <rect x="14" y="24" width="196" height="246" rx="5" fill="currentColor" fill-opacity="0.09" stroke="currentColor" stroke-opacity="0.4"/>
    <text x="112" y="48" text-anchor="middle" font-size="12" fill="currentColor">your laptop</text>
    <text x="112" y="70" text-anchor="middle" font-size="9.5" fill="currentColor" fill-opacity="0.8">ssh, the client</text>
    <text x="112" y="98" text-anchor="middle" font-size="9" fill="currentColor" fill-opacity="0.65">~/.ssh/id_ed25519</text>
    <text x="112" y="116" text-anchor="middle" font-size="9" fill="currentColor" fill-opacity="0.65">~/.ssh/id_ed25519.pub</text>
    <text x="112" y="134" text-anchor="middle" font-size="9" fill="currentColor" fill-opacity="0.65">~/.ssh/known_hosts</text>
    <text x="112" y="152" text-anchor="middle" font-size="9" fill="currentColor" fill-opacity="0.65">~/.ssh/config</text>
    <text x="112" y="176" text-anchor="middle" font-size="9" fill="currentColor" fill-opacity="0.5">/etc/ssh/ssh_config</text>
    <text x="112" y="216" text-anchor="middle" font-size="9.5" fill="currentColor" fill-opacity="0.85">the private key</text>
    <text x="112" y="232" text-anchor="middle" font-size="9.5" fill="currentColor" fill-opacity="0.85">never leaves here</text>
    <rect x="510" y="24" width="196" height="246" rx="5" fill="currentColor" fill-opacity="0.09" stroke="currentColor" stroke-opacity="0.4"/>
    <text x="608" y="48" text-anchor="middle" font-size="12" fill="currentColor">the server</text>
    <text x="608" y="70" text-anchor="middle" font-size="9.5" fill="currentColor" fill-opacity="0.8">sshd, the daemon</text>
    <text x="608" y="98" text-anchor="middle" font-size="9" fill="currentColor" fill-opacity="0.65">~/.ssh/authorized_keys</text>
    <text x="608" y="116" text-anchor="middle" font-size="9" fill="currentColor" fill-opacity="0.65">/etc/ssh/ssh_host_ed25519_key</text>
    <text x="608" y="134" text-anchor="middle" font-size="9" fill="currentColor" fill-opacity="0.65">/etc/ssh/sshd_config</text>
    <text x="608" y="152" text-anchor="middle" font-size="9" fill="currentColor" fill-opacity="0.65">/etc/ssh/sshd_config.d/</text>
    <text x="608" y="176" text-anchor="middle" font-size="9" fill="currentColor" fill-opacity="0.5">listening on port 22</text>
    <text x="608" y="216" text-anchor="middle" font-size="9.5" fill="currentColor" fill-opacity="0.85">sshd -T prints what</text>
    <text x="608" y="232" text-anchor="middle" font-size="9.5" fill="currentColor" fill-opacity="0.85">all of it adds up to</text>
    <text x="360" y="62" text-anchor="middle" font-size="11" fill="currentColor">key exchange</text>
    <text x="360" y="78" text-anchor="middle" font-size="9" fill="currentColor" fill-opacity="0.65">an encrypted channel, before</text>
    <text x="360" y="90" text-anchor="middle" font-size="9" fill="currentColor" fill-opacity="0.65">anybody has proved anything</text>
    <text x="360" y="128" text-anchor="middle" font-size="11" fill="currentColor">the server proves itself</text>
    <text x="360" y="144" text-anchor="middle" font-size="9" fill="currentColor" fill-opacity="0.65">signs with its host key; you</text>
    <text x="360" y="156" text-anchor="middle" font-size="9" fill="currentColor" fill-opacity="0.65">check it against known_hosts</text>
    <text x="360" y="206" text-anchor="middle" font-size="11" fill="currentColor">you prove yourself</text>
    <text x="360" y="222" text-anchor="middle" font-size="9" fill="currentColor" fill-opacity="0.65">sign with the private key; sshd</text>
    <text x="360" y="234" text-anchor="middle" font-size="9" fill="currentColor" fill-opacity="0.65">checks it against authorized_keys</text>
  </g>
  <g stroke="currentColor" stroke-opacity="0.45" fill="none" stroke-width="1.2">
    <path d="M232 102 L488 102 M238 98 L231 102 L238 106 M482 98 L489 102 L482 106"/>
    <path d="M488 168 L232 168 M238 164 L231 168 L238 172"/>
    <path d="M232 246 L488 246 M482 242 L489 246 L482 250"/>
  </g>
</svg>
<figcaption>Three exchanges, in order. The private key never crosses the wire; the client signs a challenge with it and sends the signature, which is why a stolen transcript is worth nothing.</figcaption>
</figure>

**The two configuration files differ by one letter and that letter is everything.**

| You want to change | File | Read by | Affects |
| --- | --- | --- | --- |
| A setting for yourself | `~/.ssh/config` | client | connections you make |
| A setting for everyone here | `/etc/ssh/ssh_config` | client | connections made from this machine |
| What this machine accepts | `/etc/ssh/sshd_config` | server | connections arriving here |
| The same, as a drop-in | `/etc/ssh/sshd_config.d/*.conf` | server | connections arriving here |

Editing `ssh_config` to stop password logins does nothing at all, and people make
that mistake more than once, because both filenames sit in the same directory listing
and the wrong one sorts first.

**The cryptography is negotiated, not fixed.** Both ends advertise what they can do
and pick the strongest thing they have in common:

```bash
# Debian 13 (trixie), x86_64
$ ssh -Q kex | head -6; echo '---'; ssh -Q key | head -6
diffie-hellman-group1-sha1
diffie-hellman-group14-sha1
diffie-hellman-group14-sha256
diffie-hellman-group16-sha512
diffie-hellman-group18-sha512
diffie-hellman-group-exchange-sha1
---
ssh-ed25519
ssh-ed25519-cert-v01@openssh.com
sk-ssh-ed25519@openssh.com
sk-ssh-ed25519-cert-v01@openssh.com
ecdsa-sha2-nistp256
ecdsa-sha2-nistp256-cert-v01@openssh.com
```

**That list is easy to misread.** `ssh -Q` prints what the binary was *compiled* to
understand, not what it will *offer*: `diffie-hellman-group1-sha1` is in there and has
not been enabled by default for years. What this machine actually proposes is a
different question, answered by `sshd -T | grep -i ciphers` and nothing else. Telnet
and FTP have no equivalent of any of it, because there is nothing to negotiate.

## What a key pair actually is

One command produces both halves:

```bash
# Debian 13 (trixie), x86_64
$ ssh-keygen -t ed25519 -f /root/.ssh/id_ed25519 -N '' -C 'sam@laptop'; echo '---'; cat /root/.ssh/id_ed25519.pub; ssh-keygen -lf /root/.ssh/id_ed25519.pub
Generating public/private ed25519 key pair.
Your identification has been saved in /root/.ssh/id_ed25519
Your public key has been saved in /root/.ssh/id_ed25519.pub
The key fingerprint is:
SHA256:XKXOoBVfKo/PqeLCRhsgJkaogjcbxdKkOHKvtAifNUQ sam@laptop
The key's randomart image is:
+--[ED25519 256]--+
|.  +E   .   o    |
|.o.o+    o =     |
|B oo.   + =      |
|B==o   + O       |
|*o.=+ . S +      |
|.+.=o.   o .     |
|. =o o    +      |
|    = .  .       |
|   . o...        |
+----[SHA256]-----+
---
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEUb1tzaDFMXTISKXP7Jj7y/udNEgGfgPgwqC1+Mf1ak sam@laptop
256 SHA256:XKXOoBVfKo/PqeLCRhsgJkaogjcbxdKkOHKvtAifNUQ sam@laptop (ED25519)
```

**Two files, one with no extension and one ending `.pub`**: the secret, and the one
you give away. **The fingerprint is a hash of the public key**, not the private one,
which is why `ssh-keygen -lf` works on the `.pub` file and why fingerprints are safe
to read aloud on a phone call. **The randomart is that fingerprint drawn as a
picture**, because people compare two grids of symbols more reliably than two lines of
base64; it is not a second security property. **The `-C` comment is free text**, and
the reason `authorized_keys` still says which human and which machine each line
belongs to six months later. **`-N ''` set an empty passphrase**, right for a capture
and wrong for a laptop: a passphrase encrypts the key file on disk, so somebody who
copies it still cannot use it.

The parameters worth knowing:

| Type | Command | Notes |
| --- | --- | --- |
| Ed25519 | `ssh-keygen -t ed25519` | The default and the right answer. Fixed size, small, fast, nothing to configure wrong. |
| RSA | `ssh-keygen -t rsa -b 4096` | Still fine, still everywhere. **Specify `-b 4096`**; the default is 3072. |
| ECDSA | `ssh-keygen -t ecdsa -b 521` | Works, less loved, no advantage over Ed25519. |
| DSA |, | Gone. Disabled by default in OpenSSH 9.8 and removed outright in 10.0. If a device demands it, that device is the problem. |
| Ed25519-SK | `ssh-keygen -t ed25519-sk` | Backed by a hardware security key. The private half cannot be copied off the token. |

**Key length only compares within an algorithm.** Generate an RSA key beside that one
with `ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa`, and the 256-bit Ed25519 key is
still the stronger of the two: the bit counts measure different things and cannot be
ranked against each other.

<details class="predict">
<summary>Four files now exist in that directory: two private keys and two public ones. The private half must be unreadable by anybody else, and the public half is meant to be handed out. Given that <code>ssh-keygen</code> sets the modes itself, what does <code>ls -l</code> show, and which two of the four could you paste into a public README?</summary>

```bash
# Debian 13 (trixie), x86_64
$ ls -l /root/.ssh/
total 16
-rw-------. 1 root root  399 Aug  8 17:50 id_ed25519
-rw-r--r--. 1 root root   92 Aug  8 17:50 id_ed25519.pub
-rw-------. 1 root root 3369 Aug  8 17:50 id_rsa
-rw-r--r--. 1 root root  736 Aug  8 17:50 id_rsa.pub
```

</details>

`0600` on the private keys, `0644` on the public ones, set by the tool. The
`.pub` files are publishable because a public key cannot be turned back into
the private one. The reverse is trivial:

```bash
# Debian 13 (trixie), x86_64
$ ssh-keygen -y -f /root/.ssh/id_ed25519; echo '---'; cat /root/.ssh/id_ed25519.pub
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKOesT1GEUt/RvS0XHbPxd+pax/Zyn/Wy9+vDDR6Fp3K sam@laptop
---
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKOesT1GEUt/RvS0XHbPxd+pax/Zyn/Wy9+vDDR6Fp3K sam@laptop
```

**Identical.** `ssh-keygen -y` regenerated the public key from the private
one, byte for byte, so deleting the `.pub` file costs nothing and the private
key is the only thing here worth protecting. That asymmetry is the whole
argument for keys over passwords. A password is a **shared** secret: you type
it across the connection and a compromised server learns it. A key is not
shared. The server holds only the public half, the private half never crosses
the wire, and a compromised server learns something it could have looked up. A
key also carries far more entropy than anything a person types twice a day.

<details class="deeper">
<summary>If you already administer Linux: certificates, and why distributing <code>authorized_keys</code> stops working at about fifty machines</summary>

Key distribution fails in two directions and both are the same problem: **no
revocation and no transitive trust.** When somebody leaves, their public key is in
`authorized_keys` on every machine they ever touched, and a host offline for a month
has not had a configuration management run. Meanwhile every new server has a fresh
host key, so every engineer gets an unfamiliar-host prompt and types yes without
looking, which is the moment host verification stops working at all.

**Certificates fix both, and OpenSSH has supported them since 5.4.** Make a
certificate authority key once, then sign with it:

```
# a CA, once, kept offline
ssh-keygen -t ed25519 -f /secure/ssh_user_ca -C 'user CA'

# a user's key, valid for a day, for two named accounts
ssh-keygen -s /secure/ssh_user_ca -I sam@example.com -n sam,deploy -V +1d ~/.ssh/id_ed25519.pub

# a host's key
ssh-keygen -s /secure/ssh_host_ca -I web01 -h -n web01.example.com /etc/ssh/ssh_host_ed25519_key.pub

# /etc/ssh/sshd_config on every server, instead of a per-user file
TrustedUserCAKeys /etc/ssh/user_ca.pub
RevokedKeys /etc/ssh/revoked_keys

# ~/.ssh/known_hosts on every client, one line for the whole estate
@cert-authority *.example.com ssh-ed25519 AAAA...
```

**What that buys, concretely.** No public key is distributed to any host,
adding a machine needs no distribution at all, and revocation becomes real:
`-V +1d` means a leaked certificate is worthless tomorrow whether or not
anybody noticed, which is a different property from "we removed the line on
the hosts we could reach". **The principals field is the access control**: `-n
sam,deploy` says this certificate may log in as `sam` or `deploy` and nothing
else, so one CA expresses "contractors may reach the deploy account" without
touching a server.

Two cautions. The CA private key is the crown jewel, anybody holding it can
mint a certificate for any account on any machine, so it belongs offline or in
a hardware token, never on the bastion. And short lifetimes mean the signing
step must be automated against your identity provider, which is where the
actual work is.

`ssh-keygen -L -f cert.pub` prints principals, validity, and extensions, and is what
you reach for when somebody's certificate stopped working at midnight.

</details>

## Getting the public half onto the server

The public key has to end up on one line of `~/.ssh/authorized_keys`, in the home
directory of the account you are logging in as, on the server. There is a tool for
it, and by hand it is a `cat` and two `chmod`s:

```
ssh-copy-id -i ~/.ssh/id_ed25519.pub sam@server

# what it does, without the tool
cat ~/.ssh/id_ed25519.pub | ssh sam@server \
  'mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys'
```

**`ssh-copy-id` needs a way in already**, a password, or another key. It opens
an ordinary SSH session and appends to a file. On a cloud instance the first
key arrives through the provider's metadata service instead, which is why
those images ship with `PasswordAuthentication no` and still let you in.
**Append, never overwrite:** `>` in place of `>>` removes everybody else's
access, including the emergency key you were told to leave in place.

**The permission rules are the part that bites**, and they are checked on both sides:

| Path | Where | Must be | Because |
| --- | --- | --- | --- |
| `~/.ssh/id_*` (no extension) | client | `0600`, owned by you | A private key others can read is not private |
| `~` | server | not writable by group or other | Somebody who can write your home can replace `.ssh` |
| `~/.ssh` | server | `0700`, owned by you | Somebody who can write it can add their own key |
| `~/.ssh/authorized_keys` | server | `0600`, owned by you | Same |

The client is loud about its half:

<details class="predict">
<summary>The key is correct and it is listed in <code>authorized_keys</code> on the server. The only thing changed is the mode on the private key file, from <code>0600</code> to <code>0644</code>, readable by everyone on the client machine. The rule is that a private key others can read is not treated as private. What does <code>ssh</code> do?</summary>

```bash
# Debian 13 (trixie), x86_64
$ chmod 0644 /root/.ssh/id_ed25519; ssh -i /root/.ssh/id_ed25519 -o BatchMode=yes root@localhost id
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@         WARNING: UNPROTECTED PRIVATE KEY FILE!          @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
Permissions 0644 for '/root/.ssh/id_ed25519' are too open.
It is required that your private key files are NOT accessible by others.
This private key will be ignored.
Load key "/root/.ssh/id_ed25519": bad permissions
root@localhost: Permission denied (publickey,password).
```

</details>

That is about as clear as a computer gets: the file, the mode, the rule, and what it
did about it. One `chmod` and nothing else changes:

```bash
# Debian 13 (trixie), x86_64
$ chmod 0600 /root/.ssh/id_ed25519; ssh -i /root/.ssh/id_ed25519 -o BatchMode=yes root@localhost id
uid=0(root) gid=0(root) groups=0(root)
```

Same key, same server, and `id` ran on the far end. `-o BatchMode=yes` forbids every
interactive prompt, so nothing here fell back to a password: the key did all of it.

**The server is the exact opposite, and this is the important half.** Change the mode
on `~/.ssh` on the *server* to something world-writable, leave everything else
correct, and here is the entire client-side story:

```bash
# Debian 13 (trixie), x86_64
$ chmod 0777 /root/.ssh; ssh -i /root/.ssh/id_ed25519 -o BatchMode=yes root@localhost id; echo "exit status: $?"
root@localhost: Permission denied (publickey,password).
exit status: 255
```

**One line, and it tells you nothing.** No mention of permissions, no mention of a
directory, no hint that the key was even considered. sshd will not explain a rejection
to an unauthenticated stranger, because the explanation is reconnaissance.

The directive doing it is **`StrictModes`**, which defaults to `yes` and makes
sshd refuse to read `authorized_keys` out of a directory somebody else could
write to. The logic is sound, a group-writable home means any member of that
group can install their own key into your account, and the diagnosis is
impossible from the client. The explanation exists only in the server's log:

```bash
# Debian 13 (trixie), x86_64
$ chmod 0777 /root/.ssh; ssh -i /root/.ssh/id_ed25519 -o BatchMode=yes root@localhost id >/dev/null 2>&1; grep -i 'Authentication refused' /var/log/sshd.log
Authentication refused: bad ownership or modes for directory /root/.ssh
```

**The whole diagnosis, in one line, on the other machine.** It names the check, the
verdict, and the exact directory, and nothing resembling it reached the person being
refused. On an ordinary systemd machine that line comes from
`sudo journalctl -u sshd -n 20`; the capture reads a file directly because the
container has no journal and `sshd` was started with `-E /var/log/sshd.log`. **That
single habit is most of what this topic is for: the client says
`Permission denied (publickey)`, then go and read the server's log.**

The client's half comes from `-v`, and one `-v` is usually enough:

```
ssh -v -i ~/.ssh/id_ed25519 sam@server
# Offering public key: /root/.ssh/id_ed25519 ED25519 SHA256:XKXOoB...
# Authentications that can continue: publickey,password
```

If `Offering public key` never appears, the client never sent it, and the fault is
on your side: wrong path, wrong mode, or an agent in the way. If it appears and is
refused, the fault is on the server's side and the log there has the reason.

## The setting you cannot find is in a drop-in

`sshd -T` is the most valuable command in this topic. It prints the **effective**
configuration: every keyword the server understands, with the value it will actually
use, including the several hundred you never wrote down anywhere.

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ sudo sshd -T 2>&1 | grep -E "^(port|permitrootlogin|passwordauthentication|pubkeyauthentication|permitemptypasswords|x11forwarding|maxauthtries|logingracetime|usepam|kbdinteractiveauthentication) "
port 22
usepam yes
logingracetime 120
maxauthtries 6
permitrootlogin prohibit-password
pubkeyauthentication yes
passwordauthentication no
kbdinteractiveauthentication no
x11forwarding yes
permitemptypasswords no
```

**`passwordauthentication no` on that machine.** Now go and find it. It is not in
`/etc/ssh/sshd_config`, and grepping for it there returns nothing useful:

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ ls /etc/ssh/sshd_config.d/; echo "--- and what the main file includes ---"; grep -vE "^#|^$" /etc/ssh/sshd_config | head -12
40-disable-passwords.conf
40-redhat-crypto-policies.conf
50-redhat.conf
90-afterburn-authorized-keys-file.conf
91-ignition-authorized-keys-file.conf
99-podman-sshd.conf
--- and what the main file includes ---
grep: /etc/ssh/sshd_config: Permission denied
```

Two facts in one capture. **Six drop-in files**, none of which appear in any
tutorial, and **the main file is not world-readable** on this image, so an
ordinary user cannot grep it at all, which is why `sudo sshd -T` rather than
`sshd -T`.

<details class="predict">
<summary>Those files are read in filename order, and <code>sshd_config</code> uses **first obtained value wins**, the opposite of most Unix configuration files. <code>40-disable-passwords.conf</code> sorts before <code>50-redhat.conf</code>. If the Red Hat file turns password authentication on and the earlier file turns it off, which value does the server use, and what would you expect the comment in the earlier file to say?</summary>

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ cat /etc/ssh/sshd_config.d/40-disable-passwords.conf; echo "--- and the crypto policy include ---"; cat /etc/ssh/sshd_config.d/40-redhat-crypto-policies.conf
# Disable password logins by default.
# https://github.com/coreos/fedora-coreos-tracker/issues/138
# This file must sort before 50-redhat.conf, which enables
# PasswordAuthentication.
PasswordAuthentication no
--- and the crypto policy include ---
cat: /etc/ssh/sshd_config.d/40-redhat-crypto-policies.conf: Permission denied
```

</details>

The packagers wrote the rule into a comment because it catches everybody: **"This
file must sort before 50-redhat.conf, which enables PasswordAuthentication."** The
number in the filename is not decoration, it is the mechanism.

The second half of the rule is where that `Include` line sits. Here is the whole of
Debian's shipped `sshd_config` with comments and blank lines removed:

```bash
# Debian 13 (trixie), x86_64
$ grep -vE '^#|^$' /etc/ssh/sshd_config
Include /etc/ssh/sshd_config.d/*.conf
KbdInteractiveAuthentication no
UsePAM yes
X11Forwarding yes
PrintMotd no
AcceptEnv LANG LC_* COLORTERM NO_COLOR
Subsystem	sftp	/usr/lib/openssh/sftp-server
```

**Seven lines.** Everything else in that file, hundreds of lines of it, is
commented-out documentation showing you the default rather than setting it,
which is why grepping for a keyword returns a comment and convinces people the
setting is unset. `Include` is line one; note also
`KbdInteractiveAuthentication no` and `Subsystem sftp`, both of which come
back later.

First value wins, and the `Include` line is at the top of the shipped file.
Put those two together and you get the consequence that ruins afternoons: a
directive added at the bottom of `/etc/ssh/sshd_config` **loses** to any
drop-in that mentions it, because the include was processed first. You edit
the file you were told to edit, restart the service, and observe no change
whatsoever. A different machine then gives a different answer, which is the
point:

```bash
# Debian 13 (trixie), x86_64
$ sshd -T | grep -E '^(port|permitrootlogin|passwordauthentication|pubkeyauthentication|permitemptypasswords|x11forwarding|allowtcpforwarding|maxauthtries|logingracetime)'
port 22
logingracetime 120
maxauthtries 6
permitrootlogin without-password
pubkeyauthentication yes
passwordauthentication yes
x11forwarding yes
permitemptypasswords no
allowtcpforwarding yes
```

**`passwordauthentication yes` here**, against `no` on the CoreOS machine. A stock
Debian server accepts passwords, and if that is not what you wanted, that one line is
the finding. `without-password` is the deprecated spelling `sshd -T` still prints for
`prohibit-password`: root may log in with a key, never with a password. A third
machine, a third answer:

```bash
# AlmaLinux 10.2, x86_64
$ sshd -T | grep -E 'permitrootlogin|passwordauthentication'
permitrootlogin without-password
passwordauthentication yes
```

Three machines, three sets of defaults, one command. This is why "the default
is" is not a sentence worth finishing about SSH: it depends on the
distribution, the image, and whatever the vendor put in a drop-in, all of
which are invisible in the file you were told to read. So when somebody says
password authentication is off because the file says so, do not open the file,
run `sudo sshd -T | grep -i passwordauthentication`, which accounts for every
drop-in and every value the build was compiled with.

## Check the file before you reload it

`sshd -t` parses the configuration and exits without starting anything. On a healthy
machine it says nothing at all:

```bash
# Debian 13 (trixie), x86_64
$ sshd -t; echo "exit status: $?"
exit status: 0
```

Silence and zero. Now introduce one typo, a single extra letter in a value:

```bash
# Debian 13 (trixie), x86_64
$ echo 'PermitRootLogin yess' >> /etc/ssh/sshd_config; sshd -t; echo "exit status: $?"
/etc/ssh/sshd_config line 125: unsupported option "yess".
exit status: 255
```

**The file, the line number, and the offending token**, with exit status 255 for a
script to test. Without that check, `systemctl reload sshd` on a configuration sshd
cannot parse leaves the running daemon alive with the old configuration, which is
survivable; `systemctl restart sshd` stops it, fails to start it, and there is now no
SSH server on a machine you reach only over SSH.

The sequence that never goes wrong:

| Step | Command | Why it is in the list |
| --- | --- | --- |
| 1 | Open a **second** session and leave it | The one thing that saves you, and it costs nothing |
| 2 | Edit `/etc/ssh/sshd_config.d/99-local.conf` | Keeps your change clear of the package's, so an upgrade cannot revert it |
| 3 | `sudo sshd -t` | Catches every syntax error before it can matter |
| 4 | `sudo sshd -T \| grep -i <what you changed>` | Confirms the change actually took effect |
| 5 | `sudo systemctl reload sshd` | Re-reads configuration with no window in which nothing is listening |
| 6 | Connect **from a third terminal**, then close the second session | The only real test |

**Prefer `reload` to `restart`.** A reload has no window in which nothing is
listening; whether your own session survives a `restart` depends on how that
distribution wrote the unit. **And step 6 is the one people skip:** steps 3 and 4
prove the configuration is valid and says what you meant, and `AllowUsers` with your
username misspelled passes both perfectly.

## The directives worth changing

Everything below is `sshd_config`, on the server, and every one of them should be
verified afterwards with `sshd -T` rather than by reading the file back.

| Directive | Typical default | Set to | What it buys |
| --- | --- | --- | --- |
| `PermitRootLogin` | `prohibit-password` | `no` | Root access becomes log in as yourself, then `sudo`, which names a human in the log |
| `PasswordAuthentication` | `yes` on Debian | `no` | Password guessing stops being possible rather than being slowed down |
| `KbdInteractiveAuthentication` | varies | `no` | Closes the *second* door passwords arrive through |
| `PubkeyAuthentication` | `yes` | `yes` | Leave it alone |
| `PermitEmptyPasswords` | `no` | `no` | Already correct everywhere; check it anyway |
| `MaxAuthTries` | `6` | `3` | Fewer guesses per connection, and it caps agent key spraying |
| `LoginGraceTime` | `120` | `30` | Fewer half-open connections held by nobody |
| `AllowUsers` / `AllowGroups` | unset | name them | Turns login into default-deny |
| `X11Forwarding` | `yes` as shipped; `no` upstream | `no` | A server has no display and forwarding one is an attack path |
| `AllowTcpForwarding` | `yes` | `no` unless used | Stops SSH being a general-purpose tunnel into your network |
| `Banner` | `none` | `/etc/issue.net` | The pre-login notice, which is not shown unless you point at it |

**The argument for `PermitRootLogin no` is auditing, not strength.** A root key is
exactly as hard to break as the same key on a user account; the difference is that
`sshd[1234]: Accepted publickey for root` names nobody, while a login as `sam`
followed by `sudo` names a person and a command in two logs.

`PasswordAuthentication no` alone is not enough, and this is the trap. PAM
offers a second route in, `keyboard-interactive`, which on many builds also
asks for a password and is controlled by a *different* directive. Both have to
be off, which is why the Fedora CoreOS capture above shows the two as separate
lines.

`AllowUsers` is the most powerful and the most dangerous, because setting it
makes login default-deny for everyone not named:

```
AllowUsers sam deploy
AllowGroups ops
```

sshd applies `DenyUsers`, then `AllowUsers`, then `DenyGroups`, then
`AllowGroups`, in that order. If `AllowUsers` is set and you are not in it,
you are refused before authentication is attempted, no message about keys,
nothing in the log about your key, and `sshd -T | grep allowusers` is the only
thing that will tell you why. Both match on names rather than numeric IDs, and
`AllowGroups` counts your primary group as well as your supplementary ones.

<details class="deeper">
<summary>If you already administer Linux: the three kinds of port forwarding, and what <code>GatewayPorts</code> changes about all of them</summary>

`AllowTcpForwarding yes` is the default, and what it permits is SSH acting as a
general-purpose tunnel. Three flags, three completely different uses:

```
ssh -L 5432:db.internal:5432 sam@bastion   # local:  bring a remote service here
ssh -R 8080:localhost:3000   sam@server    # remote: expose a local service there
ssh -D 1080                  sam@bastion   # dynamic: a SOCKS5 proxy
```

**Local, `-L`.** Your laptop opens port 5432; anything connecting to it is carried
over the session to `bastion`, which opens a connection to `db.internal:5432` from
there. The database never had to be reachable from the internet and your `psql`
connects to `localhost`. **`db.internal` is resolved by the far end, not by you**,
which is why a typo produces a local port that opens fine and fails only in use.

**Remote, `-R`.** `server` opens port 8080; connections to it come back
through the tunnel to port 3000 on your laptop. Used for showing a colleague a
development build, and used by attackers to reach back out of a network that
blocks inbound connections, which is why `AllowTcpForwarding no` is on
hardening checklists.

**Dynamic, `-D`.** Port 1080 becomes a SOCKS5 proxy and anything speaking SOCKS routes
out through `bastion`. One flag replaces a VPN for browser traffic, which is why "SSH
access to one host" is never as narrow a grant as it sounds.

`GatewayPorts` changes the blast radius on the listening side. By default both
`-L` and `-R` bind their listening port to loopback only, so only processes on
that machine can use the tunnel. `GatewayPorts yes` in the server's
`sshd_config` lets a `-R` forward bind to every address instead, so **anybody
who can reach the server can reach through your tunnel to the service on your
laptop**, with no authentication at the tunnel at all. `GatewayPorts
clientspecified` is the middle setting, letting the client name a bind address
(`-R 10.0.0.5:8080:localhost:3000`), and is the one to use if you need this.
The client has its own `GatewayPorts` in `ssh_config` governing `-L`, with the
same effect available as a bind address in the specification: `-L
0.0.0.0:5432:db.internal:5432` publishes your tunnel to the whole local
network, which on coffee shop wireless is a memorable mistake.

Three things worth knowing operationally:

- **`AllowTcpForwarding no` does not stop a determined user**, because anybody with a
  shell can run their own forwarding tool over the session. It stops the casual case.
  The real control is not granting a shell.
- **`-N -f`** turns a forward into a background process with no shell:
  `ssh -N -f -L 5432:db.internal:5432 sam@bastion`. Without `-N` you get a shell you
  did not want, which times out and takes the tunnel with it.
- **`PermitOpen`** restricts where a `-L` may connect, per user or group, which is how
  a bastion offers exactly the database and nothing else.

</details>

## Typing the passphrase once

A passphrase on a private key is only useful if you use one, and you will not if it
means typing it every time. `ssh-agent` holds decrypted keys in memory and performs
signatures on request:

```
eval $(ssh-agent -s)     # start it and export its variables
ssh-add ~/.ssh/id_ed25519
ssh-add -l               # what is loaded
ssh-add -D               # forget everything
```

**`eval` is not a flourish.** `ssh-agent -s` prints shell variable assignments
to standard output, and a child process cannot set its parent's environment,
so without `eval` the agent starts and your shell never learns
`SSH_AUTH_SOCK`, the socket path everything else uses to find it. A desktop
session manager has already done this for you, which is why the command looks
unfamiliar the first time you need it on a server.

The agent never gives out the key: it receives a challenge, signs it, returns
the signature. So a process that can reach the socket can *use* your key
without being able to *copy* it, a distinction less comforting than it sounds
and the subject of the next panel. `ssh-add -t 3600` loads a key with a
one-hour lifetime, which on a shared or long-lived machine is worth the
inconvenience.

One trap produces a baffling error. If your agent holds six keys the client
offers them in order, each offer counts against the server's `MaxAuthTries` of
6, and you can exhaust the limit before the right key is tried. The message is
`Too many authentication failures`, which sounds like a password problem and
is not. `ssh -o IdentitiesOnly=yes -i ~/.ssh/the_right_key` fixes it once;
`IdentitiesOnly yes` with an `IdentityFile` in a `~/.ssh/config` host block
fixes it permanently.

<details class="deeper">
<summary>If you already administer Linux: what agent forwarding actually exposes, and why <code>ProxyJump</code> replaced it</summary>

Agent forwarding, `ssh -A`, solves a real problem: you are on a bastion, you need a
host behind it, and you do not want your private key on the bastion. `-A` forwards
the *agent socket* instead of the key, and the second hop signs through it.

**The key never lands on the intermediate host. That is not the same as being
safe.** Forwarding creates a Unix socket there, owned by you, at the path in
`SSH_AUTH_SOCK`, and anything that can open it can ask your agent to sign
anything for as long as your session lasts. That means **root on that host**
(root opens any socket and reads any process's environment to find the path,
then uses your agent to log into every machine your key opens, with no prompt
and nothing in any log distinguishing it from you) and **any process running
as you there**, including whatever got in through an unrelated vulnerability.

So `-A` into a jump host you administer is a considered risk. `-A` into a shared
bastion, a customer's machine, or a build agent hands your credentials to whoever
controls it, and the compromise does not look like a compromise. It looks like you
logging in.

**`ProxyJump` solves the same problem without any of this:**

```
ssh -J sam@bastion sam@web01

# or permanently
Host web01
    HostName web01.internal
    ProxyJump sam@bastion
```

The client opens a session to the bastion, asks it to open a plain TCP
connection onward, and runs a **second, complete SSH session** to `web01`
inside it. Your key signs locally, twice. The bastion carries encrypted bytes
it cannot read and never sees an agent socket, and `web01`'s host key is
verified by your client rather than by the bastion, so a compromised bastion
cannot impersonate the target either. `ProxyJump` arrived in OpenSSH 7.3; the
older `ProxyCommand ssh -W %h:%p bastion` is the same thing more verbosely and
is what inherited configurations contain.

**If you genuinely must forward an agent**, two mitigations are worth the trouble.
**`ssh-add -c`** loads a key requiring confirmation, so every signature request pops
a prompt on your workstation and a hijacked socket becomes visible as prompts you did
not cause. And **scope it**: `ForwardAgent` under one `Host` block, never under
`Host *`, which is a line people write once and then forward their agent to every
machine they touch for five years.

The server-side control is `AllowAgentForwarding no`, and on a bastion whose users
should be using `-J` anyway it costs nothing.

</details>

## Moving files, and accounts that can do nothing else

SFTP is a subsystem of the same daemon on the same port, not a separate service and
nothing to do with FTP. No second port to open, no second thing to harden:

```
sftp sam@server
scp ~/report.pdf sam@server:/tmp/
rsync -avz ~/site/ sam@server:/var/www/site/
```

**`scp` and `sftp` are the same protocol now.** OpenSSH 9.0 changed `scp` to use SFTP
underneath by default, because the original `scp` protocol expanded filenames on the
remote shell and had the vulnerability class you would expect from that sentence.
`rsync` is still worth reaching for on anything large or repeated, because it
transfers differences.

**The reason SFTP gets its own section is chrooted accounts**, for a file transfer
user who should never have a shell:

```
Match Group sftponly
    ChrootDirectory /srv/sftp/%u
    ForceCommand internal-sftp
    AllowTcpForwarding no
    X11Forwarding no
```

`internal-sftp` matters: it is implemented inside sshd, so the chroot needs no binary,
no library, and no `/dev` inside it. The older `sftp-server` is a separate executable
that would have to exist within the chroot along with everything it links against.

**The chroot ownership rule is where this goes wrong**, and it is not obvious: the
`ChrootDirectory` and every directory above it must be owned by **root** and not
writable by anybody else, so the user cannot own the directory they land in and cannot
write to it. The arrangement that works:

```
/srv/sftp            root:root  0755
/srv/sftp/sam        root:root  0755   <- ChrootDirectory, user lands here, read-only to them
/srv/sftp/sam/upload sam:sam    0755   <- and this is where they can actually write
```

If sshd refuses the session with `fatal: bad ownership or modes for chroot
directory`, that rule is the reason, every time.

<details class="deeper">
<summary>If you already administer Linux: <code>Match</code> blocks, the one line that makes them debuggable, and the ordering rule that catches people</summary>

A `Match` block applies its directives only to connections meeting a condition. The
criteria are `User`, `Group`, `Host`, `LocalAddress`, `LocalPort`, `RDomain`, and
`Address`, plus `All` and `Invalid-User`. One daemon, several policies:

```
# everybody, and this section must come first
PasswordAuthentication no
AllowTcpForwarding no

Match Address 10.0.0.0/8
    PasswordAuthentication yes

Match User ansible
    PermitTTY no
    AuthenticationMethods publickey
```

**Four rules that are not guessable, and the first contradicts what you learned two
sections ago.**

`Match` overrides the global section. It does not lose to it. The global rule
is first obtained value wins, which is why a drop-in beats a later line in the
main file. `Match` is the documented exception: when the criteria are
satisfied, its keywords override whatever the global section set, so the
example above really does re-enable passwords for `10.0.0.0/8`. Two precedence
rules in one file, and knowing which one you are inside is the whole skill.

Between `Match` blocks, first wins again. If a keyword appears in several
blocks that all match, only the first instance applies, so ordering blocks is
a design decision rather than a formatting one.

A block runs to the next `Match` or the end of the file. There is no closing
keyword and no de-indent that ends it, so the global-looking directive
somebody appends to the bottom of the file six months later silently joins the
last block. This is the most common `sshd_config` bug there is, and why every
global directive belongs above the first `Match`.

Not every keyword is allowed inside one. `Port` and `ListenAddress` are not,
because sshd binds its sockets before it knows who is connecting; `sshd -t`
catches a misplaced keyword.

The command that makes all of this visible is `sshd -T` with `-C`, which asks
what the effective configuration would be for *one specific connection*:

```
sudo sshd -T -C user=fileuser,host=localhost,addr=10.0.0.9
sudo sshd -T -C user=sam,host=localhost,addr=203.0.113.7
```

Run it twice with different users and diff the output. Every `Match` block you wrote
either shows up in that difference or does not work, and no amount of reading the
file gives you the same certainty.

</details>

## Slowing the brute force down

`fail2ban` reads a log, counts failures per source address, and asks the firewall to
drop that address for a while. The vocabulary is three numbers:

| Setting | Means |
| --- | --- |
| `maxretry` | Failures needed to trigger a ban |
| `findtime` | The window those failures must fall within |
| `bantime` | How long the ban lasts |

Enable the shipped `sshd` jail from `/etc/fail2ban/jail.local`, never `jail.conf`,
which the package replaces on upgrade:

```
# /etc/fail2ban/jail.local
[sshd]
enabled  = true
maxretry = 3
findtime = 10m
bantime  = 1h

# then
sudo systemctl enable --now fail2ban
sudo fail2ban-client status sshd
sudo fail2ban-client set sshd unbanip 203.0.113.9
```

**Know what it is worth.** With `PasswordAuthentication no` a brute force cannot
succeed however many attempts it makes, and `fail2ban`'s contribution drops to keeping
the log readable and shedding load. Three limitations: a **distributed** attempt from
a thousand addresses never reaches `maxretry` on any single one; an **IPv6** ban
covers one address out of a /64 the attacker was given for free; and it **bans you**
eventually, from the office address everybody shares, so `ignoreip` for your
management network is part of deploying it rather than an afterthought.

Modern OpenSSH has some of this built in: `MaxStartups` limits unauthenticated
connections in flight, and 9.8 added `PerSourcePenalties`, which slows repeat
offenders without a second daemon. `sshd -T | grep -i persource` says whether your
build has them and what they are set to.

## Across distributions

| | RHEL family | Debian family |
| --- | --- | --- |
| Server package | `openssh-server` | `openssh-server` |
| Client package | `openssh-clients` | `openssh-client` |
| Service unit | `sshd.service` | `ssh.service`, with `sshd.service` as an alias |
| Config file | `/etc/ssh/sshd_config` | `/etc/ssh/sshd_config` |
| Drop-in directory | `/etc/ssh/sshd_config.d/` | `/etc/ssh/sshd_config.d/` |
| Algorithm selection | System-wide crypto policy, injected as a drop-in | Package defaults, edited in place |
| Firewall | `firewall-cmd --add-service=ssh` | `ufw allow OpenSSH` |

**The unit name is the row that wastes time.** `systemctl reload sshd` on Debian
works through the alias; `systemctl status ssh` on RHEL does not exist.

**The crypto policy row is the RHEL-specific surprise.** There
`update-crypto-policies` maintains a drop-in that pulls in system-wide
`Ciphers`, `MACs`, and `KexAlgorithms`, and because it sorts early it wins
over anything you write in the main file. Setting `Ciphers` by hand and
finding it ignored is the same first-value-wins rule arriving from a direction
nobody expects. Change the policy instead, `update-crypto-policies --set
FUTURE`, or add a drop-in that sorts earlier.

## Prove it

```
# the effective configuration, which is not the file
sudo sshd -T | grep -iE 'passwordauth|kbdinteractive|permitrootlogin|allowusers|maxauthtries'

# who has an opinion about the setting you cannot find
ls -l /etc/ssh/sshd_config.d/
grep -rn -i permitrootlogin /etc/ssh/sshd_config /etc/ssh/sshd_config.d/

# what a specific user would get, Match blocks included
sudo sshd -T -C user=sam,host=localhost,addr=10.0.0.9

# never reload without this
sudo sshd -t && sudo systemctl reload sshd

# the two halves of a refusal: client, then server
ssh -v -i ~/.ssh/id_ed25519 sam@server
sudo journalctl -u sshd -n 50
```

**The pairing worth memorising is `sshd -T` and `journalctl -u sshd`.** The first
says what the server has decided to be; the second says what it decided about you.

## What trips people up

### 1. The private key is readable by somebody else

`WARNING: UNPROTECTED PRIVATE KEY FILE!`, and the key is ignored. The cause is
almost always a copy through something with no Unix permissions (a FAT stick,
a Windows share, a zip file) or a restore that did not preserve modes. `chmod
600` on the file.

### 2. The home directory is group-writable

`Permission denied (publickey)` on the client and nothing else, because `StrictModes`
will not read `authorized_keys` out of a directory somebody else could write to. Fix
`~`, `~/.ssh`, and `authorized_keys`, and remember the evidence only ever appears in
the server's log.

### 3. Editing `ssh_config` when you meant `sshd_config`

`ssh_config` governs connections *out* of this machine; `sshd_config` governs
connections *in*. Turning off password authentication in the first changes nothing
about who can log in to you.

### 4. Editing the right file and being overridden anyway

First value wins, and the include sits at the top, so a directive appended to the
bottom of `sshd_config` loses to any drop-in that mentions it. The same trap in
reverse applies to `Match`: a block runs to the end of the file, so a "global"
directive appended after one is not global at all.

### 5. `PasswordAuthentication no` and still a password prompt

`KbdInteractiveAuthentication` is a second door with its own directive. Turn both
off, and check for a `Match` block re-enabling one for a network range somebody added
years ago.

### 6. Changing the port and calling it hardening

Moving SSH to 2222 removes noise from your logs and no risk at all; a port scan finds
it in seconds. There is a real cost, too: ports above 1023 can be bound by any
unprivileged process, so if sshd is ever stopped on a multi-user machine an ordinary
user can bind 2222 and collect credentials. Do it for log hygiene, not for a
hardening report.

## Work it through

A new colleague cannot log in to a server you are logged in to right now, using a key
you installed for them yourself an hour ago. Same key type as yours, same server.

Reason it out before reading on.

**First, establish which machine holds the explanation**, from the client:

```
ssh -v -i ~/.ssh/id_ed25519 newperson@server 2>&1 | grep -i 'offering\|denied\|authentications'
```

If `Offering public key` never appears, the client never sent it: wrong path,
a mode that made `ssh` ignore the key, or an agent supplying something else.
Nothing on the server is at fault. If it appears and is then denied, the
server considered the key and refused it, and will not say why, so stop
looking at the client.

**Second, read the server's version of events**, which you can do because you are
already logged in:

```
sudo journalctl -u sshd -n 50
```

Suppose it says `Authentication refused: bad ownership or modes for directory
/home/newperson/.ssh`. That is `StrictModes`, and the cause is that you created the
directory as root and never handed it over:

```
sudo chmod 700 /home/newperson/.ssh
sudo chmod 600 /home/newperson/.ssh/authorized_keys
sudo chown -R newperson:newperson /home/newperson/.ssh
```

**Now change one detail.** Suppose the log has *nothing at all* for that user. Then
they were rejected before authentication began, and that is `AllowUsers` or
`AllowGroups`:

```
sudo sshd -T | grep -iE 'allowusers|allowgroups|denyusers'
```

**And one more.** Suppose the key works from your laptop and not from theirs, with
the same file and correct modes, and the server log shows a refusal after several
offered keys. That is the agent: theirs holds eight keys and `MaxAuthTries 6` ends
the connection before the right one comes up. `ssh -o IdentitiesOnly=yes -i <the key>`
proves it in one attempt.

The point worth extracting: **the client and the server each know half of why
a login failed, and SSH is built so neither shares its half with a stranger.**
Every question in this topic is answered by deciding which half you need (`ssh
-v` on one side, `journalctl -u sshd` on the other) and going to the machine
that has it.

## Try it

Optional, on two machines you can break, or on one machine connecting to itself.

1. `ssh-keygen -t ed25519 -C "$(whoami)@$(hostname)"`, then `ls -l ~/.ssh` and read
   the modes the tool chose.
2. `ssh-keygen -y -f ~/.ssh/id_ed25519` and compare it to the `.pub` file. Delete the
   `.pub` file and regenerate it, to prove nothing was lost.
3. `ssh-copy-id sam@server`, then read `~/.ssh/authorized_keys` on the server and
   find your comment field at the end of the line.
4. `chmod 644 ~/.ssh/id_ed25519`, connect, read the warning in full, `chmod 600`,
   connect again.
5. `chmod 777 ~/.ssh` **on the server**, connect, and note how little the client tells
   you. Then read `journalctl -u sshd` there and note how much it knew.
6. `sudo sshd -T | wc -l`, then pick three keywords out of the output that appear in
   no file on the machine.
7. Add `PermitRootLogin yess` to the bottom of `sshd_config`, run `sshd -t`, read the
   line number, and remove it.
8. Open a second session. **Then** set `MaxAuthTries 3`, `sshd -t`,
   `systemctl reload sshd`, and connect from a third terminal before closing anything.

**Verification step.** You have it when, handed `Permission denied
(publickey)`, you can say in one sentence which of the two machines holds the
explanation and which command prints it, before touching anything else.

## Check yourself

<details class="qa">
<summary>A user's public key is definitely in <code>authorized_keys</code> on the server and they still get <code>Permission denied (publickey)</code>. What is the most likely cause, and where is the evidence?</summary>

**Permissions on the server, not the key.** Either `~/.ssh` is more permissive than
`0700`, `authorized_keys` is more permissive than `0600`, the home directory itself is
group- or world-writable, or the whole lot is owned by root because you created it for
them. **The evidence is in the server's log and nowhere else:**

```
sudo journalctl -u sshd -n 50
# Authentication refused: bad ownership or modes for directory /home/sam/.ssh
```

The directive is `StrictModes`, it defaults to `yes`, and the reasoning is sound: if
somebody else can write that directory, somebody else can install a key into that
account, so a key found there proves nothing.

**The tempting wrong answer is to regenerate the key**, which changes nothing because
the key was never the problem. The second most tempting is to read the client's output
more carefully; there is nothing in it, on purpose, because the explanation would be a
reconnaissance tool.

**What you will need next:** the client's half comes from `ssh -v`. If
`Offering public key` never appears there, the problem is on the client after
all (wrong path, bad mode, or an agent offering something else) and the
server's log will have nothing about them at all.

</details>

<details class="qa">
<summary>Somebody insists password authentication is disabled because <code>sshd_config</code> says so, and password logins demonstrably still work. Settle it in one command, then give two reasons this happens.</summary>

```
sudo sshd -T | grep -iE 'passwordauthentication|kbdinteractiveauthentication'
```

`sshd -T` prints the **effective** configuration, every keyword with the value
the running daemon will use, including defaults that appear in no file and
everything contributed by drop-ins. Reading `sshd_config` cannot answer the
question.

**Reason one: something overrides it.** The drop-in directory is included from the top
of the shipped file, and `sshd_config` uses **first obtained value wins**, the opposite
of most Unix configuration files, so a directive added at the bottom of the main file
loses to any drop-in that mentions it. The Fedora CoreOS machine above is the same
mechanism working correctly: `40-disable-passwords.conf` beats `50-redhat.conf` purely
because `40` sorts before `50`.

**Reason two: it is the wrong directive.** `KbdInteractiveAuthentication` governs
PAM's second path, which on many builds also prompts for a password, so turning off
`PasswordAuthentication` alone leaves that door open.

**What you will need next:** if the file contains a `Match` block, check what
it does. A block runs to the next `Match` or the end of the file, so a
directive appended to the bottom of such a file is not global, it belongs to
the last block. `sshd -T -C user=sam,host=x,addr=10.0.0.9` is the only
reliable way to test one.

</details>

<details class="qa">
<summary>Name every key involved in one SSH login, which machine each lives on, and what each proves.</summary>

**Five files, two key pairs, two directions.**

| Key | Machine | Proves |
| --- | --- | --- |
| `~/.ssh/id_ed25519` | client | That you are you. Signs a challenge; never transmitted. |
| `~/.ssh/id_ed25519.pub` | client, and copied to the server | Nothing on its own. It is the thing signatures are checked against. |
| `~/.ssh/authorized_keys` | **server** | The list of public keys allowed into that account. |
| `/etc/ssh/ssh_host_*_key` | **server** | That the server is the machine you connected to last time. |
| `~/.ssh/known_hosts` | client | Your record of host keys you have accepted before. |

**Two separate authentications happen, in this order.** The server proves itself
first, host key against your `known_hosts`; then you prove yourself, private key
against `authorized_keys`. The order matters: you never send anything about yourself
to a server that has not proved who it is.

**The tempting wrong answer** is that the private key is sent to the server
and compared. It is not, ever. The client signs a challenge and sends the
signature, so a recorded session and a compromised server both learn nothing
usable, the entire reason keys beat passwords, since a password *is*
transmitted.

**What you will need next:** `REMOTE HOST IDENTIFICATION HAS CHANGED` means
the host key does not match `known_hosts`, a rebuilt machine, a new machine at
the same address, or somebody sitting between you and it. Deleting the line to
make the warning stop is the reflex; it should be a decision, and `ssh-keygen
-R hostname` removes the entry cleanly once you have confirmed which it was.

</details>

<details class="qa">
<summary>You are changing <code>PermitRootLogin</code> on a machine three thousand miles away with nobody on site. Describe the sequence, and say what each step protects against.</summary>

**Second session, drop-in, `sshd -t`, `sshd -T`, reload, third terminal.** The second
session is the safety net: still authenticated, still able to put the file back. The
drop-in (`99-local.conf`) keeps your change clear of the package's, though sort order
still applies, so an earlier-sorting drop-in beats yours. `sshd -t` proves the file
parses, reporting a typo with a line number and exit status 255 and changing nothing.
`sshd -T | grep -i permitrootlogin` proves the value actually took rather than losing
to a drop-in you did not know about. `reload` re-reads with no window in which nothing
is listening.

**The tempting wrong move is `restart` straight after the edit**, skipping the checks,
because it usually works. When it does not, the failure mode is a machine with no SSH
server and no way to reach it.

**What you will need next:** the last step is the one that matters, because
`sshd -t` and `sshd -T` prove the file is valid and says what you meant, and neither
proves *you* can log in. `AllowUsers` with your username misspelled passes both
perfectly and locks out everybody.

</details>

<details class="qa">
<summary>Is <code>fail2ban</code> a substitute for turning off password authentication? Argue it either way, then decide.</summary>

**No, and the reason is a difference in kind rather than degree.** `fail2ban` makes a
brute force **slower**: it counts failures per source address within `findtime` and
bans for `bantime` once `maxretry` is exceeded, so the attack still works and just
takes longer. `PasswordAuthentication no` makes it **impossible**, because there is no
password to guess.

**The case for it anyway** is real. Not every machine can turn passwords off today,
jump hosts sometimes must accept them, and even on a key-only server it sheds load and
keeps the log readable enough that a genuine anomaly is visible.

**Three limits**, because they are what "we have fail2ban" tends to mean in practice.
A distributed attempt from a thousand addresses never reaches `maxretry` on any one of
them. An IPv6 attacker has a /64 and can burn a fresh address per attempt. And it will
eventually ban your own office address, which is why `ignoreip` and knowing
`fail2ban-client set sshd unbanip` are part of deploying it.

**Decide: keys first, `fail2ban` second.** In that order they are complementary; in the
other you have a slower version of a problem you could have deleted.

**What you will need next:** put the jail in `/etc/fail2ban/jail.local`, never
in `jail.conf`, which the package replaces on upgrade. And check `sshd -T |
grep -i 'maxstartups\|persource'`, recent OpenSSH does some of this itself,
without a second daemon reading logs.

</details>

## References

- [ssh(1)](https://man7.org/linux/man-pages/man1/ssh.1.html) - Linux man-pages project. Accessed 2026-08-08.
- [sshd(8)](https://man7.org/linux/man-pages/man8/sshd.8.html) - Linux man-pages project. Accessed 2026-08-08.
- [sshd_config(5)](https://man7.org/linux/man-pages/man5/sshd_config.5.html) - Linux man-pages project. Accessed 2026-08-08.
- [ssh_config(5)](https://man7.org/linux/man-pages/man5/ssh_config.5.html) - Linux man-pages project. Accessed 2026-08-08.
- [ssh-keygen(1)](https://man7.org/linux/man-pages/man1/ssh-keygen.1.html) - Linux man-pages project. Accessed 2026-08-08.
- [ssh-agent(1)](https://man7.org/linux/man-pages/man1/ssh-agent.1.html) - Linux man-pages project. Accessed 2026-08-08.
- [ssh-copy-id(1)](https://man7.org/linux/man-pages/man1/ssh-copy-id.1.html) - Linux man-pages project. Accessed 2026-08-08.
- [sftp(1)](https://man7.org/linux/man-pages/man1/sftp.1.html) - Linux man-pages project. Accessed 2026-08-08.
- [jail.conf(5)](https://manpages.debian.org/trixie/fail2ban/jail.conf.5.en.html) - Debian manpages. Accessed 2026-08-08.

Captured output came from two machines: a Debian 13 container for the client
and server tooling, and a Fedora CoreOS virtual machine for the drop-in
configuration. The refused-key transcripts are real, produced by loosening
permissions on a live key and connecting to `localhost` inside the container.
Blocks without a distribution and architecture header are illustrative:
`ssh-copy-id`, `sftp`, `fail2ban`, `Match` blocks, and certificate signing all
need a second machine or a running service manager, so those are shown as
commands without invented output.
