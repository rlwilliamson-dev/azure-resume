---
title: "Permissions are right, SELinux is enforcing, and it still fails"
description: "The failures that survive a permissions check: a policy denying what the mode bits allow, a certificate that expired on a Sunday, a protocol both ends refuse to speak, and an account that is fine except for the one attribute nobody looked at."
track: "linux-plus"
level: "deep"
order: 750
objectives:
  - "Recognise an SELinux denial and find the AVC that describes it"
  - "Check certificate validity and read the dates properly"
  - "Diagnose a protocol negotiation failure, and say which end refused"
  - "Read a repository failure and separate reachability from trust"
  - "Distinguish an account that cannot authenticate from one that cannot authorise"
prerequisites: ["selinux", "tls-certificates-and-acme"]
tags: ["linux", "linux-plus", "troubleshooting", "security", "selinux", "tls"]
updated: 2026-08-09
draft: false
examObjectives:
  - exam: "xk0-006"
    domain: "5.0"
    objective: "5.4"
sources:
  - title: "openssl-x509(1)"
    url: "https://docs.openssl.org/master/man1/openssl-x509/"
    publisher: "OpenSSL"
    accessed: 2026-08-09
    tier: 1
  - title: "openssl-s_client(1)"
    url: "https://docs.openssl.org/master/man1/openssl-s_client/"
    publisher: "OpenSSL"
    accessed: 2026-08-09
    tier: 1
  - title: "ausearch(8)"
    url: "https://man7.org/linux/man-pages/man8/ausearch.8.html"
    publisher: "man7.org"
    accessed: 2026-08-09
    tier: 1
  - title: "update-crypto-policies(8)"
    url: "https://man7.org/linux/man-pages/man8/update-crypto-policies.8.html"
    publisher: "man7.org"
    accessed: 2026-08-09
    tier: 1
  - title: "dnf.conf(5)"
    url: "https://dnf.readthedocs.io/en/latest/conf_ref.html"
    publisher: "DNF"
    accessed: 2026-08-09
    tier: 1
symptoms:
  - symptom: "Access denied although the file mode and ownership are correct"
    anchor: "when-the-mode-bits-are-not-the-decision"
  - symptom: "Client reports a handshake failure with no obvious cause"
    anchor: "protocols-both-ends-refuse-to-speak"
  - symptom: "Repository metadata will not download"
    anchor: "repositories-reachability-against-trust"
---

> **Before you read.** The service cannot read its configuration file. You check
> the owner, the group, and the mode. All correct. You become the service user
> and read the file by hand, and it works.
>
> The service still cannot read it. Nothing about the permissions is wrong,
> because permissions are not what is refusing.

Lesson 73 covered the failures that a careful look at ownership and mode will
explain. This one is about the layers above: a mandatory access policy, a
certificate's validity dates, a protocol negotiation, a repository's trust
chain, and an account attribute that has nothing to do with the password.

They share a shape. Each is a second gatekeeper saying no after the first one
has already said yes, and each keeps its reasons somewhere other than the error
message you were handed.

### Some words you will need

<dl class="terms">
<dt>AVC</dt>
<dd>Access vector cache. The SELinux denial record, and the thing to search for.</dd>
<dt>context</dt>
<dd>The SELinux label on a process or file: user, role, type, level.</dd>
<dt>permissive</dt>
<dd>SELinux logging denials without enforcing them. A diagnostic mode, not a fix.</dd>
<dt>boolean</dt>
<dd>A named switch in SELinux policy turning a class of access on or off.</dd>
<dt>notAfter</dt>
<dd>The moment a certificate stops being valid. Absolute, and not negotiable.</dd>
<dt>chain of trust</dt>
<dd>The path from a certificate to a root the verifier already trusts.</dd>
<dt>crypto policy</dt>
<dd>A system-wide setting deciding which protocols and ciphers anything may use.</dd>
<dt>GPG check</dt>
<dd>Verifying a package was signed by a key the machine trusts.</dd>
</dl>

## What breaks without this

**The obvious check passes and nothing improves.** Permissions are correct,
which is exactly why the real cause is hard to find.

**SELinux gets disabled.** It is the fastest way to make the symptom go away, it
removes a control the machine was relying on, and it teaches nobody anything.

**An expiry takes down a service on a Sunday.** Nothing changed, which is
precisely the point from lesson 63.

**The wrong end gets blamed for a handshake failure.** Both sides report that
the other refused, and frequently the local policy is what refused.

**Packages install from somewhere untrusted.** Somebody turns off the GPG check
to get past an error, converting a trust failure into a supply chain problem.

## When the mode bits are not the decision

SELinux is a second permission system running after the first has already
granted access. Discretionary permissions ask who you are. SELinux asks what
kind of program you are and what kind of file you are touching.

That is how a file with mode 644 owned by the right user stays unreadable. The
mode bits allowed it. Policy did not.

The signature to recognise: the operation fails, `ls -l` looks correct, becoming
the user by hand works, and the service log says "permission denied" with no
further detail. Every check from lesson 73 passes.

`ls -Z` shows the other half:

```bash
ls -Z /srv/app/settings.conf          # the file's context
ps -eZ | grep myservice               # the process's context
sudo ausearch -m AVC -ts recent       # denials, most recent first
sudo journalctl -t setroubleshoot     # plain-English summaries, if installed
```

**The AVC record is the whole diagnosis.** It names the source context, the
target context, the object class, and the permission refused, which is more
precise than any application error. A process in `httpd_t` reading a file
labelled `user_home_t` is the classic mislabelled-content case, and the fix is
the label rather than the mode.

| Fix | When |
| --- | --- |
| `restorecon -Rv /path` | The label drifted from policy's default. Commonest case, safest fix |
| `semanage fcontext -a -t <type> "/path(/.*)?"` then `restorecon` | Content lives somewhere policy does not expect. Makes it permanent |
| `setsebool -P <name> on` | Policy has a switch for exactly this. `getsebool -a` lists them |
| Write a policy module | Genuinely novel access. Last resort |

**Try `restorecon` before anything else.** A file that was moved rather than
copied keeps its old label, which is why `mv` from a home directory into a web
root breaks the web server and `cp` does not.

Permissive mode is a diagnostic, not a remedy. `setenforce 0` proves the fault
is SELinux and nothing more. If the answer to the outage ends up being to leave
it off, the honest record says a control was removed rather than that the
problem was fixed.

<details class="deeper">
<summary>If you already administer Linux: reading an AVC without guessing, and what hides one from you</summary>

The AVC record looks like noise and is highly structured. Four fields turn it
into a sentence.

```bash
sudo ausearch -m AVC -ts today                              # raw records
sudo ausearch -m AVC -ts recent | audit2allow -w            # explained in English
sudo ausearch -m AVC -ts recent | audit2allow -M mymodule   # generates a module
```

**The fields to read, in order:**

- **`denied { read }`** The permission refused. `read`, `write`, `open`,
  `name_connect`, `execute`.
- **`scontext=`** The source: what the process was labelled. Everything before
  the type is usually noise, so `httpd_t` is the part that matters.
- **`tcontext=`** The target: what the file, port, or socket was labelled.
- **`tclass=`** What kind of object. `file`, `dir`, `tcp_socket`, `capability`.

Together they say: a process of this type tried to do this to an object of that
type, and policy has no rule permitting it.

`audit2allow -w` writes that sentence for you and usually names the boolean that
would allow it, which is the thing to reach for before generating anything.

**Be careful with `audit2allow -M`.** It generates a module permitting exactly
what was denied, which is convenient and can grant far more than you intended,
because it works from the denial rather than from your intent. Read the
generated `.te` file before loading it. A module allowing `httpd_t` to read
`shadow_t` is not a fix, it is a hole with a package name.

**Two things hide denials from you**, both worth knowing because they make
SELinux look innocent:

**`dontaudit` rules.** Policy suppresses denials known to be harmless and noisy,
and occasionally the one you need is among them. `semodule -DB` disables
dontaudit temporarily and will reveal it. `semodule -B` restores normal
behaviour, and leaving it off is not an option.

**Audit rate limiting.** Under a flood, records are dropped, so the absence of a
recent AVC is weak evidence when something is failing repeatedly.

**Ports are labelled too**, which surprises people who only think in files. A
service on a non-standard port fails until the port carries the right label:

```bash
sudo semanage port -l | grep http_port_t
sudo semanage port -a -t http_port_t -p tcp 8888
```

That is the answer to "nginx works on 80 and refuses to bind 8888", and no
amount of examining file permissions will find it.

</details>

## Certificates, and the date nobody watched

A certificate is valid between two moments. Outside them, nothing else about it
matters.

<details class="predict">
<summary>A certificate's dates are printed, then <code>openssl</code> is asked whether it is valid right now with <code>-checkend 0</code>. What does it say, and what is the exit status?</summary>

```bash
# AlmaLinux 10.2, aarch64
$ cd /srv/certs; echo "--- when is this certificate valid ---"; openssl x509 -in expired.crt -noout -subject -dates; echo "--- and does openssl consider it valid now ---"; openssl x509 -in expired.crt -noout -checkend 0; echo "checkend exit status: $?"
--- when is this certificate valid ---
subject=CN=reports.example.com
notBefore=Jan  1 00:00:00 2024 GMT
notAfter=Jan  2 00:00:00 2024 GMT
--- and does openssl consider it valid now ---
Certificate will expire
checkend exit status: 1
```

</details>

`notBefore` and `notAfter` bracket the validity, and this one closed in January
2024. The wording "Certificate will expire" is `checkend` phrasing rather than a
claim about the future, and the exit status of 1 is the part a script reads.

That makes a monitoring check one line long, per lesson 64:

```bash
openssl x509 -in cert.pem -noout -checkend 0            # invalid now?
openssl x509 -in cert.pem -noout -checkend 2592000      # within 30 days?
```

**Check the certificate the server is serving, not the file you think it uses.**
Those differ more often than you would expect, because a service that was never
reloaded still presents the old one:

```bash
echo | openssl s_client -connect host:443 -servername host 2>/dev/null \
  | openssl x509 -noout -subject -dates -issuer
```

`-servername` matters on anything sharing an address. Without it you get
whichever certificate the server offers by default, which may not be the one you
are debugging.

Expiry is only one way a certificate fails, and the others are worth telling
apart:

| Error | Means |
| --- | --- |
| `certificate has expired` | The date. Renew |
| `self signed certificate in certificate chain` | The issuing CA is not trusted here. Install the CA rather than disabling verification |
| `unable to get local issuer certificate` | **An intermediate is missing from what the server sends.** The server's problem, not the client's |
| `Hostname mismatch` | The name you connected to is not in the certificate's SAN list |
| `certificate is not yet valid` | `notBefore` is in the future, so the local clock is probably wrong |

**The missing intermediate causes the most confusion**, because it works in
browsers and fails everywhere else. Browsers cache intermediates from earlier
sites and can fetch them; `curl`, Java, and Go do not. "It works in Chrome" is
therefore not evidence that the chain is correct, and
`openssl s_client -showcerts` is what settles it.

## Protocols both ends refuse to speak

When a connection fails during the handshake rather than at connect time, the
two ends could not agree on how to talk.

<details class="predict">
<summary>A client is told to use TLS 1.1 against a current public server. Which end refuses, and what does the error look like?</summary>

```bash
# AlmaLinux 10.2, aarch64
$ echo "--- a client insisting on TLS 1.1, which modern servers no longer accept ---"; echo | timeout 15 openssl s_client -connect example.com:443 -tls1_1 2>&1 | grep -iE "alert|no protocols|error:" | head -2
echo "--- the same server, negotiating normally ---"; echo | timeout 15 openssl s_client -connect example.com:443 2>&1 | grep -E "^ *(Protocol|Cipher) *:" | head -2
--- a client insisting on TLS 1.1, which modern servers no longer accept ---
A0DC078EFFFF0000:error:0A0000BF:SSL routines:tls_setup_handshake:no protocols available:ssl/statem/statem_lib.c:155:
--- the same server, negotiating normally ---
Protocol: TLSv1.3
```

</details>

Read that error carefully, because it is not what the heading led you to expect.
`tls_setup_handshake: no protocols available` happened in the **client**, before
anything was sent. The local OpenSSL was asked for TLS 1.1, its system crypto
policy does not permit TLS 1.1, and it declined to make the attempt. The server
was never consulted.

Left alone, the same client and the same server negotiate TLS 1.3 without
difficulty.

**That distinction is the skill worth taking from this section.** A handshake
failure can come from either end, and the text tells you which:

- **`no protocols available` or `no ciphers available`, with no traffic sent**,
  is local. Your policy or your build refused.
- **A received `alert`**, such as `alert handshake failure` or
  `alert protocol version`, came from the far end. It answered, and it said no.
- **A connection that establishes and then fails verification** is a trust
  problem rather than a negotiation one.

System crypto policy is why this happens more than it used to. RHEL-family
systems apply one policy to every application using the system libraries:

```bash
update-crypto-policies --show          # DEFAULT, LEGACY, FUTURE, FIPS
sudo update-crypto-policies --set LEGACY
```

Moving to `LEGACY` re-enables older protocols across the whole machine. It will
get an ancient appliance working and it lowers the bar for everything else at
the same time. Where the choice exists, a per-application exception is the
better trade, and the honest framing is that you are accepting a known weakness
for one connection rather than for the estate.

<details class="deeper">
<summary>If you already administer Linux: the service that is exposed rather than broken</summary>

Everything so far is about access being refused. The opposite failure is worth
the same attention, because nothing reports it: a service reachable by people
who should not reach it.

**The audit starts with what is actually listening**, not with what the
configuration says should be:

```bash
sudo ss -ltnp                                   # every listening TCP socket and its process
sudo ss -lunp                                   # UDP as well, which people forget
sudo firewall-cmd --list-all                    # what the firewall permits
sudo nft list ruleset | head -40                # or the raw ruleset
```

**Compare the two lists.** A socket on `0.0.0.0` that the firewall also permits
is reachable from anywhere the network allows. That is fine for a web server and
is how databases end up on the internet.

The bind address is the strongest control available and it costs nothing.
A database that only ever serves local applications should bind `127.0.0.1`, and
then a firewall mistake cannot expose it. Defence that does not depend on
another system being configured correctly is worth more than defence that does.

**Then the things that are exposed without listening on a port:**

- **World-readable secrets.** `find /etc -type f -perm -o=r -name '*.conf'` and
  look for credentials. Configuration files with passwords should be `0640` at
  most, owned by the service.
- **Backups and dumps in a served directory.** A `.sql` or `.tar.gz` under a web
  root is downloadable by anyone who guesses the name, and they do guess.
- **Version control directories.** A `.git` directory under a web root exposes
  the entire history, including whatever credentials were committed and later
  removed.
- **Directory listing enabled**, which turns a guess into a browse.

**Unpatched services** belong in this section too, because the exposure is the
same shape:

```bash
sudo dnf updateinfo list security               # security updates available
sudo dnf needs-restarting -r                    # does a reboot need scheduling
sudo needs-restarting                           # which services still run old code
```

`needs-restarting` is the underused one. Updating a package replaces the file
and does not restart the process, so a machine can be fully patched and still
running the vulnerable code in memory. Long-lived processes and anything with
`(deleted)` against its library mappings in `lsof` are the ones to look at, and
that is the same `(deleted)` signal from lesson 68 in a different costume.

**And the general principle worth stating**, since it is what ties this lesson
together: every control here fails open in the direction of access. An expired
certificate stops connections, a denial stops a read, and both are loud. A
service bound to the wrong address, a secret left world-readable, or a process
still running last month's OpenSSL is silent, and silence is why those are the
ones that need looking for on purpose.

</details>

## Repositories: reachability against trust

Package installation fails in two quite different ways, and the error says which
if you read past the first line.

```bash
# AlmaLinux 10.2, aarch64
$ cat > /etc/yum.repos.d/internal.repo <<EOF
[internal]
name=Internal packages
baseurl=https://packages.internal.example.com/el10/
enabled=1
gpgcheck=1
EOF
echo "--- a repository the machine cannot reach ---"; dnf -q makecache 2>&1 | tail -4
--- a repository the machine cannot reach ---
Error: Failed to download metadata for repo 'internal': Cannot download repomd.xml: Cannot download repodata/repomd.xml: All mirrors were tried
```

That is a **reachability** failure: the repository name, the file it wanted, and
the fact that every mirror was tried. Nothing here is about trust, and the
causes are ordinary. DNS, a firewall, a proxy needing configuration, or a URL
that is simply wrong. Lessons 71 and 72 own it from there.

A **trust** failure reads completely differently. `GPG check FAILED`, or a
message about a key not being installed, means the machine reached the
repository, downloaded the package, and refused to install it because it could
not verify the signature.

**Those have opposite fixes and one of them is dangerous.** Reachability is a
network problem. Trust means importing the correct key, or discovering that the
package is not what it claims to be. `gpgcheck=0` makes the message disappear
and disables the only check standing between you and a modified package. Lesson
31 covers what it is protecting.

<details class="deeper">
<summary>If you already administer Linux: accounts that authenticate and still cannot do anything</summary>

The last family here is the account that is almost fine. Authentication and
authorisation are separate, and each can be blocked several ways, which is why
"the password is correct" settles less than people expect.

Work down this list, because each answers a different question:

```bash
getent passwd alice          # does the account exist to this machine at all
passwd -S alice              # locked, expired, or usable
chage -l alice               # password and account expiry dates
id alice                     # groups, which decide authorisation
sudo faillock --user alice   # locked out by repeated failures
sudo lastb | head            # failed attempts, if btmp is kept
```

**The distinctions worth being precise about:**

- **No entry from `getent`** means the account is not visible here at all. For a
  directory account that is SSSD, the network, or the directory itself, not the
  user's password.
- **`passwd -S` showing `L`** means locked. A `!` before the hash in
  `/etc/shadow` does the same thing, and it blocks password authentication while
  **leaving SSH keys working**, which produces the confusing case of a disabled
  account that can still log in.
- **`chage -l` expiry** is the quiet one. An account can have a perfect password
  and a past expiry date, and the login fails with a message nobody reads.
- **A locked shell**, `/sbin/nologin` or `/bin/false`, means the account
  authenticates correctly and gets no session. Correct for service accounts, and
  occasionally applied to a human by accident.
- **`faillock`** counts failures and locks for a period, so an account that "was
  fine ten minutes ago" may be serving a timeout because somebody's client
  retried a stale password.

**Then authorisation, which is a different question entirely.** An account that
logs in and cannot do the job is usually one of:

- **Group membership that has not taken effect.** Groups are resolved at login,
  so adding a user to a group changes nothing for their existing sessions. They
  must log out and back in, and `id` in an old shell keeps showing the old list.
  This wastes a great deal of time.
- **`sudo` rules that do not match.** `sudo -l` as the user shows what they may
  actually run, which is more reliable than reading `sudoers`, per lesson 42.
- **A stale cached credential.** With SSSD, `sss_cache -E` invalidates it;
  otherwise a directory change may take minutes to become visible.

**The fastest discriminating test** is whether the failure happens at login or
after it. Failing to get a shell is authentication and account state. Getting a
shell and then being refused is authorisation, and the two lists do not overlap.

</details>

## Across distributions

This is the topic where the two families genuinely differ in mechanism rather
than in spelling, because they ship different mandatory access control systems
and they keep trust material in different places.

| | RHEL family | Debian family |
| --- | --- | --- |
| Mandatory access control | SELinux, enforcing by default | AppArmor, enabled by default |
| Is it on | `getenforce`, `sestatus` | `aa-status` |
| Where a denial is recorded | `auditd`, `ausearch -m AVC` | kernel log, `journalctl -k \| grep -i apparmor` |
| Scope of a profile | Every subject and object, by label | Per program, by path |
| Repository signing keys | `/etc/pki/rpm-gpg`, `rpm --import` | `/etc/apt/keyrings`, signed-by in the source |
| System CA trust store | `/etc/pki/ca-trust/source/anchors`, then `update-ca-trust` | `/usr/local/share/ca-certificates`, then `update-ca-certificates` |
| Certificate tooling | `openssl`, `certbot` | `openssl`, `certbot` |

**The scope row is the difference that changes how you investigate.** SELinux
labels everything and confines every process, so a denial can involve a subject
and object you were not thinking about. AppArmor confines named programs against
path rules, so if the program has no profile it is unconfined and AppArmor is
simply not the answer. `aa-status` tells you which programs have profiles, and
that list is short enough to read.

The CA trust row catches people adding an internal root. Dropping the file in the
right directory does nothing until the update command runs, and the two families
disagree about both the directory and the command. A certificate that verifies
with `openssl -CAfile` and fails without it is this, every time.

## Prove it

The order matters, because each check rules out a layer that would otherwise
muddy the next:

```bash
# 1. Ordinary permissions first: MAC runs after them, never instead of them
namei -l /path/to/thing
sudo -u <service-user> test -r /path/to/thing && echo readable

# 2. Was the mandatory access control layer even consulted
sudo ausearch -m AVC -ts recent            # RHEL family
sudo journalctl -k --since -10min | grep -i apparmor   # Debian family

# 3. Certificates: the date, and the chain the server actually sends
openssl x509 -noout -dates -subject -in /path/to/cert.pem
openssl s_client -connect host:443 -servername host </dev/null 2>/dev/null \
  | openssl x509 -noout -dates

# 4. Protocol: what each end is willing to speak
openssl s_client -connect host:443 -tls1_2 </dev/null 2>&1 | head -3

# 5. Repositories: reachability and trust are two separate questions
curl -sI https://repo.example.com/repodata/repomd.xml | head -1
sudo dnf clean all && sudo dnf makecache        # or: sudo apt update
```

**No denial record means the layer was never consulted, which is a real answer.**
Ordinary permissions are checked first, so a failure that produces no AVC and no
AppArmor line was refused before the policy engine was asked. That rules out a
whole category in one command, without turning enforcement off to find out.

## What trips people up

### 1. `setenforce 0` treated as a fix

It is a diagnosis. All it establishes is that the policy was involved, and it
does so by removing mandatory access control from the entire machine to solve one
mislabelled file. Relabel the file instead, or set the boolean, and leave the
protection where it is.

### 2. `gpgcheck=0` as a fix for a signature error

That disables the check that just told you something was wrong. A signature
failure means the key is missing, the key expired, or the package is not what it
claims, and exactly one of those three is fixed by importing a key you have
verified.

### 3. Reading a repository failure without splitting it in two

"Cannot download repomd.xml, all mirrors were tried" is reachability: DNS, the
route, a proxy, the firewall. "GPG check FAILED" is trust: the file arrived
perfectly and you do not trust it. Different causes, different fixes, and one
`curl` separates them.

### 4. Missing an expiry because nothing changed

A certificate stops working on a date, with no deploy and no edit involved, which
is precisely why it looks so mysterious. When a TLS service breaks on a day
nothing was touched, read `notAfter` before anything else.

### 5. Renewing a certificate and not reloading the service

The file on disk is new and the running process is still holding the old one in
memory. `openssl s_client` shows what the server actually presents, which is the
only version that matters, and it will still show the expired one.

### 6. Trusting the absence of audit records

`auditd` rate limits under load, and dropped records leave only a line saying so.
On a busy machine, "no AVC" is slightly weaker evidence than it looks, so check
for the backlog message before concluding.

## Work it through

A service that has run for eight months stops responding over TLS. Clients report
a handshake failure. Nothing was deployed, and the certificate was renewed
automatically three days ago.

Reason it out before reading on.

**First, ask what the server is actually presenting**, rather than what is on
disk. Those are different things and the difference is the answer more often than
not:

```bash
openssl s_client -connect api.internal:443 -servername api.internal </dev/null 2>/dev/null \
  | openssl x509 -noout -dates -subject
```

Say it reports a `notAfter` three days in the past, while the file in
`/etc/pki/tls/certs` has a date months in the future.

**Second, read what that gap means.** Renewal wrote a new file and the running
process never re-read it. Most services load certificates at start and hold them
open, so a renewal without a reload leaves the old one serving until something
restarts it:

```bash
sudo systemctl reload nginx
sudo ss -ltnp | grep :443          # confirm the process really is the one you reloaded
```

**Third, confirm the fix from the client's point of view**, using the same
command as step one. This matters because reloading the wrong unit, or a service
that ignores reload and needs a restart, looks identical from the server side.

**Fourth, fix the recurrence rather than the instance.** The renewal ran fine and
the deploy hook did not, so the same failure is scheduled for the next renewal:
add the reload to the certbot deploy hook and test it by forcing a renewal in dry
run mode.

The reasoning to keep: the certificate on disk was valid the whole time, so
anybody who checked the file concluded there was nothing wrong. Asking the server
what it was serving, rather than asking the filesystem what it held, is what
separated the two.

## Try it

Optional, and a container with `openssl` is enough for most of it.

1. Generate a self-signed certificate with a lifetime of one day, serve it with
   `openssl s_server`, and connect with `openssl s_client`. Read the dates in the
   output. Then generate one that has already expired and compare the errors.
2. Add your own CA certificate to the system trust store for whichever family you
   are on, and prove it took effect by connecting without `-CAfile`. Then remove
   it and watch the failure come back.
3. Force a version mismatch: run the server with `-tls1_2` only and the client
   with `-tls1_3` only. Read the alert text carefully, because that exact
   phrasing is what you will meet in a log.
4. On a RHEL-family machine, use `chcon` to give a file a wrong label, watch a
   service fail on it, and confirm the AVC in `ausearch`. Fix it with
   `restorecon` rather than by turning anything off.

**Verification step.** Step 3 is right when you can name, from the alert text
alone, whether the two ends failed to agree on a protocol version or on a cipher.
Those are different alerts and they send you to different parts of the
configuration.

## For the exam

**SELinux denies after ordinary permissions have allowed.** Correct mode bits
plus a failure is the signature.

**`ausearch -m AVC` finds the denial**, and `scontext` with `tcontext` names the
two labels.

**`restorecon` fixes a drifted label.** `mv` preserves the old label where `cp`
does not.

**Permissive mode is a diagnostic.** Disabling SELinux is not a fix.

**A certificate is valid between `notBefore` and `notAfter`.**
`openssl x509 -checkend N` exits non-zero when it is about to expire.

**`unable to get local issuer certificate` usually means the server is not
sending its intermediate.** Working in a browser proves nothing.

**A handshake error naming "no protocols available" came from your side**, from
system crypto policy. A received `alert` came from the far end.

**Repository failures split into reachability and trust.** `gpgcheck=0` is not a
fix.

**Locking an account blocks the password and not an SSH key.**

**Group changes need a new login to take effect.**

<details class="qa">
<summary>Check yourself</summary>

**Ownership and mode are correct, `sudo -u svc cat` works, and the service still
cannot read the file. Next command?**
`sudo ausearch -m AVC -ts recent`. This is the SELinux signature: the
discretionary check passed and policy refused.

**Which two AVC fields identify the problem?**
`scontext`, the process label, and `tcontext`, the object label. With `tclass`
and the denied permission they state the whole thing.

**A file moved into a web root breaks the web server, and copying it works.
Why?**
`mv` preserves the original SELinux label; `cp` takes the destination's.
`restorecon` fixes the moved one.

**Is `setenforce 0` a fix?**
No. It confirms SELinux is responsible. Leaving it that way removes a control
the machine was relying on.

**Which command tells you whether a certificate expires within thirty days?**
`openssl x509 -in cert.pem -noout -checkend 2592000`. Non-zero exit means yes.

**How do you check the certificate a server is actually serving?**
`openssl s_client -connect host:443 -servername host`, piped into
`openssl x509 -noout -dates`. The file on disk may not be what the process
loaded.

**A certificate works in a browser and fails in `curl`. Likely cause?**
A missing intermediate. Browsers cache and fetch them; most other clients do
not.

**`tls_setup_handshake: no protocols available`, with nothing sent. Which end
refused?**
Yours. The local crypto policy would not offer the protocol requested, so
nothing reached the server.

**And if you receive `alert protocol version` instead?**
That came from the server. It answered and refused.

**What does `update-crypto-policies --set LEGACY` cost you?**
It re-enables older protocols and ciphers for every application using the system
libraries, so it fixes one old appliance and weakens everything else on the
machine.

**"Cannot download repomd.xml: All mirrors were tried" is which kind of
failure?**
Reachability. DNS, firewall, proxy, or a wrong URL. Nothing to do with trust.

**And "GPG check FAILED"?**
Trust. The machine reached the repository and refused the package because the
signature could not be verified. Import the right key.

**An account is locked and the user still logs in. How?**
Locking places a `!` before the password hash, which blocks password
authentication and leaves key authentication working.

**You added a user to a group and they still cannot write. Why?**
Group membership is resolved at login. Their current session holds the old set,
so they must log out and back in.

**A user logs in fine and then cannot run a command. Authentication or
authorisation?**
Authorisation. Check `id` for groups and `sudo -l` for what they may run.

</details>

## Where this sits

Lesson 73 covered the permission failures that ownership and mode explain. This
lesson covers the ones that survive that check. Lesson 44 built the SELinux
model, lesson 48 built the certificates, and lesson 31 explains what the
repository signature protects.

That is the troubleshooting block complete, and with it domain 5.


## References

- [openssl-x509(1)](https://docs.openssl.org/master/man1/openssl-x509/) - OpenSSL. Accessed 2026-08-09.
- [openssl-s_client(1)](https://docs.openssl.org/master/man1/openssl-s_client/) - OpenSSL. Accessed 2026-08-09.
- [ausearch(8)](https://man7.org/linux/man-pages/man8/ausearch.8.html) - man7.org. Accessed 2026-08-09.
- [update-crypto-policies(8)](https://man7.org/linux/man-pages/man8/update-crypto-policies.8.html) - man7.org. Accessed 2026-08-09.
- [dnf.conf(5)](https://dnf.readthedocs.io/en/latest/conf_ref.html) - DNF. Accessed 2026-08-09.
> **The commands here were run on a real machine, not written from memory.** The
> transcripts come from AlmaLinux 10.2 on aarch64. The expired certificate was
> generated with validity dates in January 2024 so `checkend` would fail against
> the real clock rather than a contrived one. The TLS 1.1 attempt is against a
> genuine public server, and the error is worth the space it takes: it came from
> the local crypto policy declining to offer the protocol, so nothing ever
> reached the server. The repository failure is a real `dnf` run against a
> hostname that does not exist.
