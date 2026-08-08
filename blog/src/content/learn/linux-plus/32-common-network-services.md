---
title: "The machine is fine and the website still does not load"
description: "A tour of the services a Linux server usually runs: what each is for, where its configuration lives on each family, and the order to check them in when something between the browser and the disk is not working."
track: "linux-plus"
level: "working"
order: 330
objectives:
  - "Name the common server services and say what each one does"
  - "Find a service's configuration and its log on an unfamiliar machine"
  - "Work up the stack from port to process to configuration"
  - "Say why an accurate clock is a prerequisite for several other things"
prerequisites: ["packages-repositories-and-signing"]
tags: ["linux", "linux-plus", "services", "nginx", "dns", "ntp"]
updated: 2026-08-07
draft: false
examObjectives:
  - exam: "xk0-006"
    domain: "2.0"
    objective: "2.4"
sources:
  - title: "nginx documentation"
    url: "https://nginx.org/en/docs/"
    publisher: "nginx"
    accessed: 2026-08-07
    tier: 1
  - title: "Apache HTTP Server documentation"
    url: "https://httpd.apache.org/docs/2.4/"
    publisher: "Apache Software Foundation"
    accessed: 2026-08-07
    tier: 1
  - title: "chrony documentation"
    url: "https://chrony-project.org/documentation.html"
    publisher: "chrony project"
    accessed: 2026-08-07
    tier: 1
  - title: "BIND 9 ARM"
    url: "https://bind9.readthedocs.io/en/latest/"
    publisher: "Internet Systems Consortium"
    accessed: 2026-08-07
    tier: 1
  - title: "ss(8)"
    url: "https://man7.org/linux/man-pages/man8/ss.8.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "CUPS documentation"
    url: "https://www.cups.org/documentation.html"
    publisher: "OpenPrinting"
    accessed: 2026-08-07
    tier: 2
symptoms:
  - symptom: "Service is running but the port is not reachable"
    anchor: "1-running-but-not-listening-where-you-think"
  - symptom: "Certificate errors and authentication failures across a fleet"
    anchor: "4-the-clock-is-wrong"
---

> **Before you read.** Somebody reports that the website is down. You log into the
> web server and everything looks fine: the machine is up, load is low, disk is
> fine, and `systemctl status nginx` says active.
>
> The website is still down.
>
> **Between somebody typing a URL and a file being read off this disk, how many
> separate things had to work?**

DNS, routing, the firewall, the listening socket, the web server's virtual host
matching, the application behind it, the database behind that, and the
permissions on the file. Eight, at least, and "the service is running" tests
exactly one of them.

This lesson is a tour of the services you will meet and — more usefully — the
order to check them in.

### Some words you will need

<dl class="terms">
<dt>daemon</dt>
<dd>A program that runs in the background providing a service. Conventionally named with a trailing d.</dd>
<dt>listening socket</dt>
<dd>An address and port a service has claimed, waiting for connections.</dd>
<dt>virtual host</dt>
<dd>One web server serving several sites, chosen by the hostname in the request.</dd>
<dt>reverse proxy</dt>
<dd>A web server that accepts a request and passes it to an application behind it.</dd>
<dt>stratum</dt>
<dd>How many hops a time source is from a reference clock. Lower is better.</dd>
</dl>

## What breaks without this

**You cannot find anything on an unfamiliar machine.** Config file locations differ
by family and by package, and the difference between `/etc/nginx/` and
`/etc/httpd/` is a real obstacle at 3am.

**You check the wrong layer first**, which is most of the time spent on a service
outage.

**Nothing that depends on time works**, and the failures do not mention time.

## The tour

| Service | Does | Usual package | Port |
| --- | --- | --- | --- |
| **HTTP** | Serves web content | `nginx`, `httpd`/`apache2` | 80, 443 |
| **DNS** | Names to addresses | `bind`, `unbound`, `dnsmasq` | 53 |
| **NTP** | Keeps the clock right | `chrony` | 123 |
| **DHCP** | Hands out addresses | `dhcp-server`, `kea` | 67, 68 |
| **SMTP** | Sends mail | `postfix` | 25, 587 |
| **IMAP** | Reads mail | `dovecot` | 143, 993 |
| **SSH** | Remote access | `openssh-server` | 22 |
| **Printing** | Print queues | `cups` | 631 |
| **Databases** | Data | `mariadb`, `postgresql` | 3306, 5432 |

**The two web servers are the ones you will meet most.** `nginx` is
event-driven, fast at serving files and proxying, and configured in one coherent
syntax. `httpd` (Apache) is older, module-based, and has `.htaccess` for
per-directory overrides. Both are correct choices; nginx is the more common
default for new work and Apache is extremely common in place.

## Where the configuration lives

```bash
# AlmaLinux 10.2, x86_64
$ dnf install -y -q nginx >/dev/null 2>&1; echo '--- the main config, and which package owns it ---'; rpm -qf /etc/nginx/nginx.conf; echo '--- where the drop-ins go ---'; ls -d /etc/nginx/conf.d /usr/share/nginx/html 2>/dev/null; echo '--- and the port it will listen on ---'; grep -m1 'listen' /etc/nginx/nginx.conf
--- the main config, and which package owns it ---
nginx-core-1.26.3-6.el10_2.5.x86_64
--- where the drop-ins go ---
/etc/nginx/conf.d
/usr/share/nginx/html
--- and the port it will listen on ---
        listen       80;
```

**`rpm -qf` on a config file is the fastest orientation on an unfamiliar
machine.** Note the answer: `nginx.conf` is owned by `nginx-core`, not `nginx`.
That is why searching for a package named after the command sometimes finds
nothing useful, and it is lesson 31's query tools doing real work.

The layout by family:

| | RHEL family | Debian family |
| --- | --- | --- |
| nginx config | `/etc/nginx/nginx.conf` | same |
| nginx sites | `/etc/nginx/conf.d/*.conf` | `/etc/nginx/sites-available/`, symlinked into `sites-enabled/` |
| Apache root | `/etc/httpd/` | `/etc/apache2/` |
| Apache config | `/etc/httpd/conf/httpd.conf` | `/etc/apache2/apache2.conf` |
| Apache sites | `/etc/httpd/conf.d/*.conf` | `sites-available/` and `a2ensite` |
| Web root | `/usr/share/nginx/html`, `/var/www/html` | `/var/www/html` |
| Service name | `httpd` | `apache2` |

**The `sites-available` and `sites-enabled` pattern is Debian's**, and the symlink
between them is the enable switch — `a2ensite` and `a2dissite` just create and
remove it, which is lesson 25 again. The RHEL family has no equivalent: everything
in `conf.d/` is active, and disabling means renaming the file so it no longer ends
in `.conf`.

**Every one of these has a config test**, and using it before reloading is the
single best habit in this lesson:

```
sudo nginx -t
sudo apachectl configtest
sudo named-checkconf
sudo postfix check
sudo sshd -t
```

A syntax error found by `nginx -t` costs five seconds. The same error found by
`systemctl restart nginx` on a live server costs an outage, because the old
process has already stopped.

## Time, and why it is first

`chronyc tracking` reports how far the local clock is from the time source it has
settled on. This machine has been running for hours with a working network.

<details class="predict">
<summary>Kerberos rejects tickets more than five minutes out and TLS rejects certificates that are not yet valid. Roughly how far off would you guess a synchronised clock actually is — minutes, seconds, or less?</summary>

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ echo "--- is the clock in sync, and with what ---"; chronyc tracking 2>/dev/null | head -5 || timedatectl show-timesync 2>/dev/null | head -5; echo "--- sources ---"; chronyc sources 2>/dev/null | head -4
--- is the clock in sync, and with what ---
Reference ID    : 178FC4CB (23.143.196.203)
Stratum         : 3
Ref time (UTC)  : Sat Aug 08 03:18:24 2026
System time     : 0.000838063 seconds slow of NTP time
Last offset     : -0.000397323 seconds
--- sources ---
MS Name/IP address         Stratum Poll Reach LastRx Last sample               
===============================================================================
^+ 172.104.209.204               5  10   377   560  +2341us[+1943us] +/-   50ms
^* 23.143.196.203                2  10   377   548  -3711us[-4108us] +/-   40ms
```

</details>

**838 microseconds.** Under a millisecond, held there continuously by small
corrections rather than jumps. That precision is why the five-minute tolerances
elsewhere feel generous — a machine that has drifted into breaking Kerberos has not
drifted, it has lost its time source entirely, and `chronyc tracking` is the one
command that distinguishes those two.

The `^*` in the sources list marks the server currently selected; `^+` is a
candidate being kept as a cross-check. `Reach 377` is an octal bitmask of the last
eight polls, so 377 means all eight arrived — anything less is packet loss to that
source.

**`chronyc tracking` is the health check** and `System time: 0.000838 seconds slow`
is what healthy looks like — under a millisecond.

In `chronyc sources`, the leading character is the state: **`*`** the source
currently being used, **`+`** an acceptable alternative, **`?`** unreachable, `x`
believed to be wrong. `Stratum` is distance from a reference clock. `Reach` is an
octal history of the last eight polls, so **377 means eight out of eight** and
anything less means packet loss.

**Time is a prerequisite for things that do not mention time in their errors:**

- **TLS certificates** have validity windows. A clock wrong by days produces
  `certificate is not yet valid` and looks like a certificate problem.
- **Kerberos** rejects tickets more than five minutes out, so a domain-joined
  machine with a drifting clock stops authenticating and reports a credentials
  error.
- **Correlating logs across machines** is impossible if their clocks disagree,
  which is discovered during an incident and not before.
- **`make` and build systems** compare timestamps, and a clock that jumped
  backwards makes them rebuild everything or nothing.

**Use `chrony`.** It is the default on both families now, converges faster than
`ntpd`, and copes with laptops and VMs that suspend. `timedatectl` shows the
summary; `chronyc` is the detail.

<details class="predict">
<summary>`systemctl status nginx` says active, and `curl http://localhost` works from the server. From another machine the connection times out. Where would you look, in what order?</summary>

**The service is proven good and so is the application.** `curl` from localhost
exercised the socket, the virtual host, the file, and the permissions. So the
problem is between the two machines, and there are exactly three candidates.

**One: is it listening on an address the outside can reach?**

```
sudo ss -tlnp | grep :80
```

`127.0.0.1:80` means loopback only — it works locally by definition and is
unreachable from anywhere else, whatever the firewall says. `0.0.0.0:80` means
every interface. This is the single most common cause and it is invisible from
`systemctl status`.

**Two: is the firewall allowing it?**

```
sudo firewall-cmd --list-all      # RHEL family
sudo ufw status                   # Ubuntu
sudo nft list ruleset             # either
```

A default-deny firewall with no rule for 80 produces exactly this symptom: a
timeout rather than a refusal, because the packet is dropped rather than rejected.

**Three: does anything between them block it?** A cloud security group, a network
ACL, or a host firewall on the *client*. On a cloud instance this is at least as
likely as the local firewall and is configured somewhere else entirely.

**The distinction that narrows it fastest** is what the failure looks like:

| Symptom | Means |
| --- | --- |
| Connection **refused** | Reached the machine; nothing listening on that port |
| Connection **timed out** | Packets dropped. Firewall, or wrong address entirely. |
| Works locally, not remotely | Bound to loopback, or a firewall |

`nc -zv server 80` from the client and `ss -tlnp` on the server together answer it
in two commands, and neither of them is `systemctl status`.

</details>

## The order to check

Work from the outside in, and stop at the first thing that fails.

```bash
# 1. Does the name resolve, and to the right place
getent hosts www.example.com
dig +short www.example.com

# 2. Can you reach the machine at all
ping -c2 <address>
nc -zv <address> 443

# 3. Is something listening, and on what address
sudo ss -tlnp | grep :443

# 4. Is the firewall allowing it
sudo firewall-cmd --list-all

# 5. Is the service healthy, and does its config parse
systemctl status nginx
sudo nginx -t

# 6. What does the service itself say
sudo journalctl -u nginx --since '10 minutes ago'
sudo tail -50 /var/log/nginx/error.log

# 7. Can the service read what it is serving
sudo -u nginx cat /var/www/html/index.html
```

**Step 7 is the one people reach last and should reach sooner** on the RHEL
family, because SELinux denies access that the permission bits allow, and every
visible piece of evidence looks correct. `sudo ausearch -m AVC -ts recent` is the
check.

## Logs

| Service | Log |
| --- | --- |
| Anything under systemd | `journalctl -u name` |
| nginx | `/var/log/nginx/{access,error}.log` |
| Apache (RHEL) | `/var/log/httpd/{access_log,error_log}` |
| Apache (Debian) | `/var/log/apache2/{access,error}.log` |
| Mail | `/var/log/maillog` or `/var/log/mail.log` |
| Auth | `/var/log/secure` or `/var/log/auth.log` |

**Web servers keep their own logs as well as the journal**, and the two contain
different things: the journal has startup and crash information, the access log
has requests. A 403 appears in the error log and nowhere else.

<details class="deeper">
<summary>If you already administer Linux: the web stack, and what a reverse proxy actually solves</summary>

The common arrangement is nginx in front and an application behind it, and the
reasons are worth being able to state.

**TLS terminates once**, at the proxy, so the application never handles
certificates and renewal is one place rather than many.

**Static files are served by something good at it.** nginx serving a CSS file
costs almost nothing; the same file served by a Python application costs a worker
process.

**One address, several applications**, routed by hostname or path, which is what
lets a single server host unrelated sites.

**The application binds to loopback or a Unix socket**, so it is unreachable from
outside except through the proxy. That is a real security boundary and it is why
`ss -tlnp` showing an application on `0.0.0.0` behind a proxy is a finding.

**PHP is the exception in shape.** With Apache it has historically been a module,
running inside the web server process; with nginx it is `php-fpm`, a separate
process pool the proxy talks to over a socket. The `fastcgi_pass` line is the
join, and "nginx returns 502" nearly always means `php-fpm` is not running or the
socket path is wrong.

**Certificates** come from `certbot` in practice: `certbot --nginx` obtains and
installs one and adds a renewal timer. The renewal is the part that fails silently
eighteen months later, so `systemctl list-timers | grep certbot` belongs on the
list of things to check on an inherited machine.

**`curl` is the diagnostic.** `curl -Iv https://site` shows the certificate chain,
the response headers, and the redirect chain. `curl --resolve site:443:10.0.0.5
https://site` tests a specific backend without changing DNS, which is how you
check a new server before cutting over.

</details>

<details class="deeper">
<summary>If you already administer Linux: running a resolver, and the two jobs DNS servers do</summary>

"Install BIND" is two quite different jobs and conflating them causes real
problems.

**A recursive resolver** answers any question by asking the internet on the
client's behalf. That is what a machine points at in `/etc/resolv.conf`.

**An authoritative server** holds the records for a zone you own and answers only
for that zone.

Running both roles on one instance is possible and has been the source of
significant incidents — an **open resolver** reachable from the internet is used
for DNS amplification attacks, where a small spoofed query produces a large reply
aimed at a victim. If a resolver is reachable from outside your network, that is a
finding regardless of anything else.

**Pick the right software for the job.** `unbound` is a validating recursive
resolver and is what you want for the first role. `BIND` does both and is the
usual choice for authoritative service. `dnsmasq` is small, does DNS and DHCP
together, and suits a branch office or a lab.

**Zone file mechanics that catch people:** the **serial** in the SOA record must
increase or secondaries will not transfer, and the conventional format is
`YYYYMMDDNN`. `named-checkzone` validates a zone file and `named-checkconf`
validates the configuration; both are free and both prevent the failure mode where
`systemctl reload named` silently keeps serving the old data.

**Split-horizon** — different answers for internal and external clients — is
common, correct, and the reason "it resolves from my laptop and not from the
server" is an expected result rather than a mystery.

</details>

<details class="deeper">
<summary>If you already administer Linux: mail, which is mostly about not being an open relay</summary>

Postfix is the usual MTA and the default configuration on both families is
sensible: listening on loopback only, accepting mail for local delivery, relaying
nothing.

**The dangerous change is `mynetworks` and `inet_interfaces`.** Opening the
listener to the world plus a permissive `mynetworks` produces an **open relay** —
a server that accepts mail from anyone and forwards it to anyone. It will be found
by scanners within hours, used for spam, and the address blacklisted, and the
cleanup takes weeks.

**For most servers you do not want an MTA at all**, you want the machine able to
*send* — cron output, monitoring alerts, application mail. That is a **null client**:
`relayhost` pointing at your organisation's mail server, `inet_interfaces =
loopback-only`, and nothing accepted from outside. Five lines, no attack surface.

**The three DNS records that decide deliverability** are worth knowing even if you
never run a mail server, because they are the answer to "our mail goes to spam":
**SPF** lists which hosts may send for the domain, **DKIM** signs outgoing
messages, and **DMARC** tells receivers what to do when the first two fail. All
three are DNS records rather than mail server configuration.

**`postqueue -p`** shows what is stuck and **`postfix check`** validates the
configuration. `/var/log/maillog` records every delivery attempt with a reason,
and mail is unusual in that its logs are genuinely good.

Dovecot handles IMAP and POP3, and the pairing matters: Postfix delivers into a
mailbox format, Dovecot serves it, and the two must agree on `Maildir` versus
`mbox` or nothing appears.

</details>

## Across distributions

| | RHEL family | Debian family |
| --- | --- | --- |
| Apache package and service | `httpd` | `apache2` |
| Apache config root | `/etc/httpd/` | `/etc/apache2/` |
| Enabling a site | drop a `.conf` in `conf.d/` | `a2ensite`, a symlink |
| Enabling a module | `LoadModule` in a conf file | `a2enmod` |
| MariaDB service | `mariadb` | `mariadb` |
| Firewall | `firewalld` | `ufw`, or `nftables` directly |
| Extra restriction | **SELinux enforcing** | AppArmor, more permissive |

**The `httpd` versus `apache2` split is the one that catches everybody**, because
it changes the package name, the service name, the config path, the log path, and
the user the server runs as. A runbook written for one is useless on the other.

**SELinux is the other big difference in practice.** On the RHEL family, serving
files from a non-standard directory requires the right context —
`semanage fcontext` and `restorecon` — and without it every permission looks
correct and access is denied.

## Prove it

```bash
# Everything listening, and what owns it
sudo ss -tlnp

# Does the config parse, before you reload anything
sudo nginx -t

# Is it enabled as well as running
systemctl is-active nginx; systemctl is-enabled nginx

# What it said recently
sudo journalctl -u nginx --since '1 hour ago' --no-pager | tail -20

# End to end, from outside
curl -Iv https://example.com
```

**`ss -tlnp` is the single most useful command in this lesson.** It answers what
is listening, on which address, and which process owns it — which covers "is it
running", "is it reachable", and "is it the thing I think" at once.

## What trips people up

### 1. Running but not listening where you think

`0.0.0.0:80` is every interface; `127.0.0.1:80` is loopback only and unreachable
from anywhere else regardless of the firewall.

`ss -tlnp` before anything else.

### 2. Reloading without testing the config

`systemctl restart nginx` on a broken config stops the running server and fails to
start the new one, turning a typo into an outage.

`nginx -t` first, every time. And prefer `reload` to `restart` where the service
supports it, because reload keeps serving while it re-reads.

### 3. Started but not enabled

The service runs now and does not come back after a reboot. Covered properly in
the next lesson, and it belongs here too because it is discovered weeks later.

`systemctl is-enabled` alongside `is-active`.

### 4. The clock is wrong

Certificate errors, Kerberos failures, and logs that cannot be correlated. None of
the messages mention time.

`chronyc tracking` and `timedatectl`. Check it early on any machine behaving
strangely across a fleet.

### 5. SELinux, on the RHEL family

Files served from a non-standard path are denied with permissions that look
perfect.

`sudo ausearch -m AVC -ts recent`, then `semanage fcontext` and `restorecon`.
Never `setenforce 0` as a fix.

## Work it through

A site returns **502 Bad Gateway**. nginx is running, `nginx -t` passes, and the
server is otherwise healthy.

Reason it out before reading on.

**502 is a specific message and it is the one that narrows this fastest.** It
means nginx accepted the request, tried to pass it to something behind it, and got
nothing usable back. So **nginx is working** — it is talking to you, and the
problem is between it and the application.

That immediately rules out DNS, routing, the firewall between client and server,
the listening socket, and the virtual host. All of those would have produced a
different failure.

**What is it proxying to?**

```
grep -rE 'proxy_pass|fastcgi_pass' /etc/nginx/
```

Suppose `fastcgi_pass unix:/run/php-fpm/www.sock`.

**Is the thing at the other end running?**

```
systemctl status php-fpm
ss -tlnp | grep php
ls -l /run/php-fpm/www.sock
```

Three common answers. **The service is stopped** — start it, then find out why it
stopped, which the journal will say. **The socket path is wrong**, because a
package update moved it; nginx's error log names the path it tried. **The socket
exists and nginx cannot open it**, which is a permissions or SELinux problem
between two accounts.

**nginx's error log names the cause exactly:**

```
sudo tail -20 /var/log/nginx/error.log
```

`connect() to unix:/run/php-fpm/www.sock failed (2: No such file or directory)`
is a missing service. `(13: Permission denied)` is the socket's permissions or an
SELinux denial. Two different fixes, and the log distinguishes them without any
guessing.

Now the point worth extracting. **The HTTP status code told you which layer to
look at, before you ran anything.** 502 means the proxy is fine and the backend is
not. 403 means the request reached a file and something refused it — permissions,
or SELinux. 404 means the server looked and found nothing, so the virtual host
matched and the path is wrong. 504 means the backend accepted and never answered,
which is a slow application rather than a stopped one. And a **timeout with no
status at all** means nothing reached nginx, which is the firewall or the address.

The habit: **read the failure before choosing where to look.** "The website is
down" describes a symptom; the status code names a layer, and it is free.

## Try it

Optional, on any machine.

1. `sudo ss -tlnp` and identify every listening service and the process behind it.
2. `systemctl list-units --type=service --state=running` and name what each is for.
3. `chronyc tracking` and `chronyc sources`, and read the state characters.
4. `timedatectl` and confirm NTP is active.
5. If a web server is installed: find its config with `rpm -qf` or `dpkg -S`,
   run its config test, and find its logs.
6. `curl -Iv https://example.com` and read the certificate and headers.
7. `getent hosts example.com` and `dig +short example.com`, and confirm they
   agree.

**Verification step.** You have it when you can be handed an HTTP status code and
say which layer of the stack to investigate, before touching the machine.

## Check yourself

<details class="qa">
<summary>`systemctl status nginx` says active and remote connections time out. Give the three things to check, in order.</summary>

**One: what address is it listening on.** `sudo ss -tlnp | grep :80`. Bound to
`127.0.0.1` means loopback only — it works locally by definition and is
unreachable from anywhere else, whatever the firewall does. This is the most
common cause and `systemctl status` cannot show it.

**Two: the host firewall.** `firewall-cmd --list-all` or `ufw status`. A
default-deny policy with no rule for the port produces a timeout rather than a
refusal, because packets are dropped silently.

**Three: anything in between.** A cloud security group or network ACL, configured
somewhere else entirely, and at least as likely as the host firewall on a cloud
instance.

The symptom itself narrows it: **refused** means something reached the machine and
nothing was listening; **timed out** means packets were dropped.

</details>

<details class="qa">
<summary>Why run `nginx -t` before `systemctl reload nginx`?</summary>

**Because a restart on a broken config leaves you with nothing running.**
`systemctl restart` stops the working process and then fails to start the new one,
so a typo becomes an outage.

`nginx -t` parses the configuration and reports the file and line of any error
without touching the running server. It takes a second.

Also prefer **reload over restart** where the service supports it: reload signals
the running process to re-read its configuration, so existing connections are
served throughout and there is no gap at all.

Every service in this lesson has an equivalent: `apachectl configtest`,
`named-checkconf`, `postfix check`, `sshd -t`. The `sshd` one is worth special
mention, because a bad `sshd_config` on a remote machine can lock you out
permanently.

</details>

<details class="qa">
<summary>Name three things that break when a server's clock is wrong, none of which mention time in the error.</summary>

**TLS certificates.** They have validity windows, so a clock wrong by days gives
`certificate is not yet valid` or `has expired` — which sends people to check the
certificate, which is fine.

**Kerberos authentication.** Tickets are rejected more than about five minutes out
of step, so a domain-joined machine stops authenticating and reports a credentials
failure.

**Log correlation across machines.** Two servers whose clocks disagree produce
timelines that cannot be reconciled, which is discovered during an incident and
never before.

Others: build systems comparing timestamps, database replication, TOTP
two-factor codes, and anything with a scheduled window.

`chronyc tracking` shows the offset; healthy is well under a millisecond. It is
worth checking early on any machine behaving oddly across a fleet.

</details>

<details class="qa">
<summary>What does a 502 tell you that a timeout does not?</summary>

**That nginx is working.** A 502 is a response — the server accepted the request,
tried to reach the application behind it, and got nothing usable back.

So DNS, routing, the firewall, the listening socket, and the virtual host are all
proven good by the fact that you received the status code at all. The problem is
between nginx and the backend.

**A timeout with no status is the opposite**: nothing reached nginx, which points
at the network, the firewall, or the listening address.

The other codes narrow it similarly. **403** means a file was reached and access
refused, so permissions or SELinux. **404** means the virtual host matched and the
path did not exist. **504** means the backend accepted the connection and did not
answer in time, which is a slow application rather than a stopped one.

Reading the code before choosing where to look is free and saves the most time.

</details>

<details class="qa">
<summary>Why is `sites-available` with a symlink into `sites-enabled` a useful pattern, and what is the RHEL-family equivalent?</summary>

**It separates "configured" from "active".** A site's configuration lives
permanently in `sites-available/`, and a symlink in `sites-enabled/` turns it on.
Disabling is removing the symlink, which keeps the configuration intact and makes
re-enabling trivial.

`a2ensite` and `a2dissite` do nothing more than create and remove that symlink —
which is lesson 25's mechanism doing ordinary work.

**The RHEL family has no equivalent.** Everything matching `/etc/httpd/conf.d/*.conf`
or `/etc/nginx/conf.d/*.conf` is active, and disabling means renaming the file so
it no longer ends in `.conf` — `site.conf.disabled` by convention.

That difference is worth knowing before you go looking for `a2dissite` on a RHEL
box and conclude the installation is broken.

</details>

## References

- [nginx documentation](https://nginx.org/en/docs/) - nginx. Accessed 2026-08-07.
- [Apache HTTP Server documentation](https://httpd.apache.org/docs/2.4/) - Apache Software Foundation. Accessed 2026-08-07.
- [chrony documentation](https://chrony-project.org/documentation.html) - chrony project. Accessed 2026-08-07.
- [BIND 9 ARM](https://bind9.readthedocs.io/en/latest/) - Internet Systems Consortium. Accessed 2026-08-07.
- [ss(8)](https://man7.org/linux/man-pages/man8/ss.8.html) - Linux man-pages project. Accessed 2026-08-07.
- [CUPS documentation](https://www.cups.org/documentation.html) - OpenPrinting. Accessed 2026-08-07.

The service configurations here are from each project's own documentation, since
a container has no service manager to start them under. The `rpm -qf` and chrony
captures are real. Blocks without a distribution and architecture header are
illustrative.
