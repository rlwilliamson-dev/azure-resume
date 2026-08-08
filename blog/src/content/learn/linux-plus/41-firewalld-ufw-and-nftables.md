---
title: "You opened the port and a reload closed it again"
description: "firewalld, ufw, and nftables all write to the same kernel engine. What differs is what counts as a rule and what survives a reboot. Zones, the runtime versus permanent split, ufw's ordered list, and saving an nftables ruleset."
track: "linux-plus"
level: "working"
order: 420
objectives:
  - "Name what each front end writes and where its permanent copy lives"
  - "Open a port with firewall-cmd so it survives a reload and a reboot"
  - "Read a ufw ruleset as an ordered list and place a rule where it will match"
  - "Save and restore an nftables ruleset, and say why bare nft needs it"
  - "Tell iptables-nft from iptables-legacy and say why the difference matters"
prerequisites: ["firewall-concepts-and-netfilter"]
tags: ["linux", "linux-plus", "firewall", "firewalld", "ufw", "nftables", "iptables"]
updated: 2026-08-08
draft: false
examObjectives:
  - exam: "xk0-006"
    domain: "3.0"
    objective: "3.2"
sources:
  - title: "firewall-cmd(1)"
    url: "https://manpages.debian.org/trixie/firewalld/firewall-cmd.1.en.html"
    publisher: "Debian manpages"
    accessed: 2026-08-08
    tier: 1
  - title: "firewalld.zone(5)"
    url: "https://manpages.debian.org/trixie/firewalld/firewalld.zone.5.en.html"
    publisher: "Debian manpages"
    accessed: 2026-08-08
    tier: 1
  - title: "firewalld.richlanguage(5)"
    url: "https://manpages.debian.org/trixie/firewalld/firewalld.richlanguage.5.en.html"
    publisher: "Debian manpages"
    accessed: 2026-08-08
    tier: 1
  - title: "ufw(8)"
    url: "https://manpages.debian.org/trixie/ufw/ufw.8.en.html"
    publisher: "Debian manpages"
    accessed: 2026-08-08
    tier: 1
  - title: "ufw-framework(8)"
    url: "https://manpages.debian.org/trixie/ufw/ufw-framework.8.en.html"
    publisher: "Debian manpages"
    accessed: 2026-08-08
    tier: 1
  - title: "nft(8)"
    url: "https://manpages.debian.org/trixie/nftables/nft.8.en.html"
    publisher: "Debian manpages"
    accessed: 2026-08-08
    tier: 1
  - title: "iptables-translate(8)"
    url: "https://manpages.debian.org/trixie/iptables/iptables-translate.8.en.html"
    publisher: "Debian manpages"
    accessed: 2026-08-08
    tier: 1
  - title: "ipset(8)"
    url: "https://manpages.debian.org/trixie/ipset/ipset.8.en.html"
    publisher: "Debian manpages"
    accessed: 2026-08-08
    tier: 1
  - title: "nftables wiki"
    url: "https://wiki.nftables.org/wiki-nftables/index.php/Main_Page"
    publisher: "Netfilter project"
    accessed: 2026-08-08
    tier: 1
symptoms:
  - symptom: "Port opened with firewall-cmd disappears after firewall-cmd --reload"
    anchor: "runtime-and-permanent-are-two-different-configurations"
  - symptom: "FirewallD is not running"
    anchor: "is-the-daemon-even-running"
  - symptom: "Status: inactive"
    anchor: "ufw-and-the-ordered-list"
  - symptom: "nft rules gone after a reboot"
    anchor: "nftables-directly-and-saving-what-you-did"
---

> **Before you read.** A colleague opens port 8080 on a RHEL server with one
> command. The application starts answering. Everybody goes home.
>
> Three weeks later somebody adds a rule for an unrelated service, runs
> `firewall-cmd --reload`, and 8080 stops answering. Nothing was deleted, nobody
> touched the application, and the person who ran the reload was working on a
> different problem entirely.
>
> **Where did the rule go, and how did a command about something else take it
> away?**

Lesson 40 established that every Linux firewall is the same kernel machinery:
netfilter hooks, chains attached to them, and nftables holding the rules. This
lesson is the layer above. `firewalld`, `ufw`, and `nft` are three programs that
write to that one engine, so choosing between them is not a choice about
capability. **It is a choice about two things: what a rule looks like, and what
happens to it when the machine restarts.**

### Some words you will need

<dl class="terms">
<dt>front end</dt>
<dd>A program that writes firewall rules for you. It is not itself a firewall; the kernel is.</dd>
<dt>zone</dt>
<dd>firewalld's unit of policy. A named bundle of what is allowed, with interfaces and source addresses attached to it.</dd>
<dt>service</dt>
<dd>In firewalld, a named set of ports shipped as an XML file, so you write <code>--add-service=https</code> instead of a number.</dd>
<dt>runtime configuration</dt>
<dd>What firewalld currently has loaded in the kernel. Discarded on reload.</dd>
<dt>permanent configuration</dt>
<dd>The XML files under <code>/etc/firewalld</code>. Not in effect until something loads them.</dd>
<dt>rich rule</dt>
<dd>A firewalld rule carrying more than a port: a source address, a log, a rate limit, an explicit verdict.</dd>
<dt>ruleset</dt>
<dd>In nftables, everything currently loaded across every table. <code>nft list ruleset</code> prints the lot.</dd>
</dl>

## What breaks without this

**The port you opened closes itself weeks later for no visible reason.** The
runtime and permanent configurations are separate, the short command edits only
one of them, and the gap between the change and the symptom is long enough that
nobody connects the two.

**Your rules do not survive a reboot**, and you learn this during an unrelated
outage, at the point where the machine comes back and nothing can reach it, or
worse, everything can.

**You add a ufw rule and it never matches**, because ufw is an ordered list and
something above your rule already made the decision.

**You cannot tell which tool wrote a rule you did not write.** One machine can
carry rules from firewalld, a container runtime, and something somebody added with
`iptables` five years ago, all in the same engine.

## One engine, three opinions

<figure class="learn-figure">
<svg viewBox="0 0 720 340" role="img" aria-labelledby="fe-title fe-desc" style="width:100%;height:auto;">
  <title id="fe-title">Three firewall front ends writing to one nftables engine, and where each keeps its permanent copy</title>
  <desc id="fe-desc">Three front ends sit above one kernel. The firewall-cmd command, from firewalld, thinks in zones and named services and is the default on the RHEL family. The ufw command thinks in one ordered numbered list and is the default on Ubuntu. The nft command thinks in tables, chains, and rules, and runs with no daemon at all. Each can change the running kernel immediately, shown by the direct arrows down to the single nftables ruleset in the kernel. Each also has a permanent copy on disk: firewalld writes XML files under slash etc slash firewalld slash zones, ufw writes slash etc slash ufw slash user dot rules, and nft writes slash etc slash nftables dot conf only if you tell it to. Those files reach the kernel only when something loads them, at boot or on reload. The two paths are separate, which is why a change can take effect now and be gone after a restart, or be written down and have no effect at all.</desc>
  <g font-family="ui-monospace, monospace">
    <rect x="30" y="22" width="200" height="64" rx="5" fill="currentColor" fill-opacity="0.12" stroke="currentColor" stroke-opacity="0.4"/>
    <text x="130" y="44" text-anchor="middle" font-size="12" fill="currentColor">firewall-cmd</text>
    <text x="130" y="61" text-anchor="middle" font-size="9.5" fill="currentColor" fill-opacity="0.65">zones and named services</text>
    <text x="130" y="77" text-anchor="middle" font-size="9.5" fill="currentColor" fill-opacity="0.8">RHEL family</text>
    <rect x="260" y="22" width="200" height="64" rx="5" fill="currentColor" fill-opacity="0.12" stroke="currentColor" stroke-opacity="0.4"/>
    <text x="360" y="44" text-anchor="middle" font-size="12" fill="currentColor">ufw</text>
    <text x="360" y="61" text-anchor="middle" font-size="9.5" fill="currentColor" fill-opacity="0.65">one ordered numbered list</text>
    <text x="360" y="77" text-anchor="middle" font-size="9.5" fill="currentColor" fill-opacity="0.8">Ubuntu</text>
    <rect x="490" y="22" width="200" height="64" rx="5" fill="currentColor" fill-opacity="0.12" stroke="currentColor" stroke-opacity="0.4"/>
    <text x="590" y="44" text-anchor="middle" font-size="12" fill="currentColor">nft</text>
    <text x="590" y="61" text-anchor="middle" font-size="9.5" fill="currentColor" fill-opacity="0.65">tables, chains, rules</text>
    <text x="590" y="77" text-anchor="middle" font-size="9.5" fill="currentColor" fill-opacity="0.8">no daemon at all</text>
    <rect x="112" y="132" width="136" height="52" rx="5" fill="none" stroke="currentColor" stroke-opacity="0.35" stroke-dasharray="4 3"/>
    <text x="180" y="152" text-anchor="middle" font-size="8.5" fill="currentColor" fill-opacity="0.8">/etc/firewalld/zones/</text>
    <text x="180" y="168" text-anchor="middle" font-size="8.5" fill="currentColor" fill-opacity="0.8">public.xml</text>
    <rect x="342" y="132" width="136" height="52" rx="5" fill="none" stroke="currentColor" stroke-opacity="0.35" stroke-dasharray="4 3"/>
    <text x="410" y="152" text-anchor="middle" font-size="8.5" fill="currentColor" fill-opacity="0.8">/etc/ufw/user.rules</text>
    <text x="410" y="168" text-anchor="middle" font-size="8.5" fill="currentColor" fill-opacity="0.6">written for you</text>
    <rect x="572" y="132" width="136" height="52" rx="5" fill="none" stroke="currentColor" stroke-opacity="0.35" stroke-dasharray="4 3"/>
    <text x="640" y="152" text-anchor="middle" font-size="8.5" fill="currentColor" fill-opacity="0.8">/etc/nftables.conf</text>
    <text x="640" y="168" text-anchor="middle" font-size="8.5" fill="currentColor" fill-opacity="0.6">only if you save it</text>
    <rect x="30" y="232" width="660" height="66" rx="5" fill="currentColor" fill-opacity="0.07" stroke="currentColor" stroke-opacity="0.3"/>
    <text x="360" y="258" text-anchor="middle" font-size="12" fill="currentColor">one nftables ruleset, in the kernel</text>
    <text x="360" y="278" text-anchor="middle" font-size="9.5" fill="currentColor" fill-opacity="0.65">nft list ruleset shows all of it, whoever wrote it</text>
  </g>
  <g stroke="currentColor" stroke-opacity="0.45" fill="none" stroke-width="1.2">
    <path d="M60 86 L60 226 M56 220 L60 227 L64 220"/>
    <path d="M290 86 L290 226 M286 220 L290 227 L294 220"/>
    <path d="M520 86 L520 226 M516 220 L520 227 L524 220"/>
    <path d="M170 86 L170 126 M166 120 L170 127 L174 120"/>
    <path d="M400 86 L400 126 M396 120 L400 127 L404 120"/>
    <path d="M630 86 L630 126 M626 120 L630 127 L634 120"/>
    <path d="M170 184 L170 226 M166 220 L170 227 L174 220"/>
    <path d="M400 184 L400 226 M396 220 L400 227 L404 220"/>
    <path d="M630 184 L630 226 M626 220 L630 227 L634 220"/>
  </g>
  <g font-family="ui-monospace, monospace" font-size="9" fill="currentColor" fill-opacity="0.7">
    <text x="12" y="160">now</text>
    <text x="186" y="212">at boot,</text>
    <text x="186" y="224">or on reload</text>
  </g>
</svg>
<figcaption>Two paths, and they are independent. The left arrow in each column takes effect immediately and is forgotten on restart; the right one is written down and does nothing until something loads it.</figcaption>
</figure>

| | firewalld | ufw | nftables |
| --- | --- | --- | --- |
| A rule is | an entry in a **zone** | a line in an **ordered list** | a rule in a chain in a table |
| Permanent copy | `/etc/firewalld/**/*.xml` | `/etc/ufw/*.rules` | `/etc/nftables.conf`, if you write it |
| Loaded at boot by | `firewalld.service` | `ufw.service` | `nftables.service`, if enabled |
| Change with no file edit | Yes, and it is the default | No | Yes, and it is all `nft` does |
| Default on | RHEL family | Ubuntu | Debian |
| Reaches the kernel via | nftables | `iptables-nft`, so nftables | nftables |

**Read the last row twice.** ufw is not a different firewall from nftables; it
writes `iptables` commands, and on any current distribution `iptables` is a
translation layer over nftables. Three front ends, one engine, and `nft list
ruleset` prints whatever any of them produced.

**Do not run two of them at once.** Nothing in the kernel stops you, because from
the kernel's point of view they are all just processes adding rules. What you get
is two sets of chains at similar priorities, a packet accepted by one before the
other is consulted, and no error message anywhere.

## Is the daemon even running

firewalld is unusual among the three in being a **daemon**. `firewall-cmd` is a
client that talks to it over D-Bus and does nothing on its own, which produces a
distinctive first failure:

```bash
# AlmaLinux 10.2, x86_64
$ firewall-cmd --state
Error: DBUS_ERROR: Failed to connect to socket /run/dbus/system_bus_socket: No such file or directory
```

That ran in a container, which has no systemd and no system message bus, so
firewalld cannot start there and its client cannot reach it. On a real machine
where the service is merely stopped you get `FirewallD is not running` instead.
Either way, **the command failed before it got anywhere near a firewall rule**,
and no amount of correcting the rule will help.

The escape hatch is a second binary that edits the configuration files directly
with the daemon down:

| Command | Talks to | Edits |
| --- | --- | --- |
| `firewall-cmd` | The running daemon | Runtime, permanent, or both |
| `firewall-offline-cmd` | Nothing. The files. | **Permanent only** |

`firewall-offline-cmd` produced every firewalld capture below. It is not a
workaround invented for this lesson: it is the correct tool inside an image build,
a Kickstart `%post` section, or a container, where there is no daemon to talk to.
It is `firewall-cmd --permanent` without the daemon, which conveniently means
everything you are about to see **is** the permanent side of the split this lesson
is about.

## Zones are policies, and one of them is the default

A zone is a named policy. Interfaces and source addresses get attached to zones,
and traffic arriving on an interface is judged by that interface's zone.

```bash
# AlmaLinux 10.2, x86_64
$ firewall-offline-cmd --get-default-zone; firewall-offline-cmd --get-zones
public
block dmz drop external home internal public trusted work
```

**Nine shipped zones, and the default is `public`.** That single fact explains most
first encounters with firewalld:

| Zone | Unsolicited incoming traffic |
| --- | --- |
| `drop` | Dropped. No reply of any kind. |
| `block` | Rejected with an ICMP prohibited message |
| `public` | Only the listed services. **The default.** |
| `external` | Like `public`, with masquerading turned on |
| `dmz` | Only the listed services, for hosts with limited access inward |
| `work` | Listed services, with a slightly more trusting default set |
| `home` | More trusting again |
| `internal` | The same shape as `home`, intended for internal networks |
| `trusted` | Everything accepted |

Zone names are a **suggestion about intent, not an enforced meaning**. `home` is
not more secure than `work` in any deep way; the difference is which services each
one lists out of the box. Read the list rather than inferring from the name:

```bash
# AlmaLinux 10.2, x86_64
$ firewall-offline-cmd --list-all
public (default)
  target: default
  ingress-priority: 0
  egress-priority: 0
  icmp-block-inversion: no
  interfaces: 
  sources: 
  services: cockpit dhcpv6-client ssh
  ports: 
  protocols: 
  forward: yes
  masquerade: no
  forward-ports: 
  source-ports: 
  icmp-blocks: 
  rich rules: 
```

**There is the answer to a question every new RHEL administrator asks.** `services:
cockpit dhcpv6-client ssh` and nothing else. You install a web server, it starts
happily, `ss -tlnp` shows it listening on `0.0.0.0:80`, and nothing can reach it,
because port 80 is not on that line and this zone is the default for everything.

Three of the other lines are worth naming while they are in front of you:

- **`target: default`** is what happens to a packet no rule matched. `default`
  rejects it. A zone can instead set `ACCEPT`, `DROP`, or `%%REJECT%%`.
- **`interfaces:` and `sources:` are empty** because this container has no
  interface assigned. On a real machine one of them names the interface, and that
  binding is what makes this zone apply to anything at all.
- **`forward: yes`** allows traffic between interfaces in this same zone. It is on
  by default in current firewalld and was not always, which trips people migrating
  from older releases.

<details class="predict">
<summary>`public` has `target: default`, which rejects, and lists three services. The `drop` zone is named for what it does. Given that a zone is nothing but a target plus a list, what will its `target` and its `services` line say?</summary>

```bash
# AlmaLinux 10.2, x86_64
$ firewall-offline-cmd --zone=drop --list-all
drop
  target: DROP
  ingress-priority: 0
  egress-priority: 0
  icmp-block-inversion: no
  interfaces: 
  sources: 
  services: 
  ports: 
  protocols: 
  forward: yes
  masquerade: no
  forward-ports: 
  source-ports: 
  icmp-blocks: 
  rich rules: 
```

</details>

**`target: DROP` and an empty services list.** The whole difference between `drop`
and `public` is those two lines. There is no separate mechanism and no special
mode: a zone is a target plus a list of exceptions, and the nine shipped zones are
nine combinations of those two things.

**A source address beats an interface.** If one zone names a subnet in `sources:`
and another has the arriving interface, the source binding wins. That is useful,
because it is how you say "this management network is trusted whichever interface
it arrives on", and it is the reason a rule that looks correct in the interface's
zone sometimes does nothing at all. `firewall-cmd --get-active-zones` prints both
bindings and is the command that ends the argument.

## Services are names, not port numbers

firewalld ships a large dictionary of named services, each one an XML file listing
ports. This is the first twenty in alphabetical order out of several hundred:

```bash
# AlmaLinux 10.2, x86_64
$ firewall-offline-cmd --get-services | tr ' ' '\n' | head -20
0-AD
RH-Satellite-6
RH-Satellite-6-capsule
afp
alvr
amanda-client
amanda-k5-client
amqp
amqps
anno-1602
anno-1800
apcupsd
aseqnet
audit
ausweisapp2
bacula
bacula-client
bareos-director
bareos-filedaemon
bareos-storage
```

They live in `/usr/lib/firewalld/services/`, and your own go in
`/etc/firewalld/services/` where a package update will not touch them.

**Prefer the name over the number when one exists.** `--add-service=samba` opens
the four ports Samba needs, on the right protocols, without you having to know
what they are, and it keeps working if the definition is corrected upstream. A
port number is the right answer only when nothing has named it, your application
on 8080 for instance:

```bash
# AlmaLinux 10.2, x86_64
$ firewall-offline-cmd --add-service=http; firewall-offline-cmd --add-port=8080/tcp; firewall-offline-cmd --list-all
success
success
public (default)
  target: default
  ingress-priority: 0
  egress-priority: 0
  icmp-block-inversion: no
  interfaces: 
  sources: 
  services: cockpit dhcpv6-client http ssh
  ports: 8080/tcp
  protocols: 
  forward: yes
  masquerade: no
  forward-ports: 
  source-ports: 
  icmp-blocks: 
  rich rules: 
```

`http` joins `services:` and `8080/tcp` joins `ports:`. Equivalent in effect,
different in maintainability.

## Runtime and permanent are two different configurations

Here is the thing the opening question was about, and it is the single most
expensive misunderstanding in this topic. **`firewall-cmd` maintains two
configurations.** The runtime one is loaded in the kernel; the permanent one is
XML on disk. A command edits one or the other depending on a flag, and the flag is
easy to leave off because the short form is the one that visibly works.

| What you type | Works now | Survives a reload | Survives a reboot |
| --- | --- | --- | --- |
| `firewall-cmd --add-port=8080/tcp` | Yes | **No** | **No** |
| `firewall-cmd --permanent --add-port=8080/tcp` | **No** | Yes | Yes |
| `--permanent`, then `firewall-cmd --reload` | Yes | Yes | Yes |

**Row one is the opening question.** The rule was runtime-only. It worked for three
weeks because nothing reloaded. Then a colleague made an unrelated permanent
change, ran `--reload` to apply it, and reload does exactly what it says: it
throws away the runtime configuration and rebuilds it from the files. Port 8080
was never in the files.

**Row two is the other half of the same mistake**, and it is quieter still: the
change is written down correctly and does nothing. People add the rule, test it,
find it did not work, and conclude firewalld is broken.

<details class="predict">
<summary>The permanent configuration is XML under `/etc/firewalld/zones/`, one file per zone you have modified, and a zone is a target plus a list. You have just added `http` and `8080/tcp` through the offline command, which writes the permanent side. What is in `public.xml`, and what else does the directory contain?</summary>

```bash
# AlmaLinux 10.2, x86_64
$ ls /etc/firewalld/zones/; cat /etc/firewalld/zones/public.xml
public.xml
public.xml.old
<?xml version="1.0" encoding="utf-8"?>
<zone>
  <short>Public</short>
  <description>For use in public areas. You do not trust the other computers on networks to not harm your computer. Only selected incoming connections are accepted.</description>
  <service name="ssh"/>
  <service name="dhcpv6-client"/>
  <service name="cockpit"/>
  <service name="http"/>
  <port port="8080" protocol="tcp"/>
  <forward/>
</zone>
```

</details>

**That is what "permanent" means.** Not a mode, not a flag the kernel understands:
a file, in a directory, that `firewalld.service` reads at start-up and `--reload`
reads again. Two details in that listing are worth having.

**`public.xml.old` is a free backup.** firewalld renames the previous version every
time it writes, so exactly one generation back is always recoverable. It is not
version control and it has saved people.

**The shipped zones are not in this directory until you change one.** The defaults
live in `/usr/lib/firewalld/zones/` and a file appears under `/etc` only when you
override it, so `ls /etc/firewalld/zones/` is a fast answer to "what has anybody
customised on this machine", and an empty directory means nobody has.

```
# the pair people actually mean
sudo firewall-cmd --permanent --add-port=8080/tcp
sudo firewall-cmd --reload

# promote everything currently in the runtime config to permanent
sudo firewall-cmd --runtime-to-permanent

# read the two configurations separately, and compare them
sudo firewall-cmd --list-all
sudo firewall-cmd --permanent --list-all
```

**That last pair is the diagnostic habit.** Two commands, nothing changed, and the
difference between them tells you which of the two mistakes you are looking at. In
the runtime output and not the permanent one: it dies at the next reload. In the
permanent output and not the runtime one: somebody forgot to reload.

**`--runtime-to-permanent` is the honest option** when you have been experimenting
interactively and it now works. It writes the whole current runtime configuration
into the files, including anything else you tried and left behind, which is the
one caution.

**`--reload` and `--complete-reload` are not the same.** The ordinary reload keeps
connection tracking state, so established sessions, including the SSH session you
are typing into, survive it. `--complete-reload` reloads the netfilter kernel
modules too and loses that state, which terminates existing connections. Reaching
for the complete one out of thoroughness is how people disconnect themselves.

## Rich rules, when a port number is not enough

`--add-service` and `--add-port` say "allow this from anywhere". Real policy is
usually narrower, and that is what the rich language is for:

```bash
# AlmaLinux 10.2, x86_64
$ firewall-offline-cmd --add-rich-rule="rule family=ipv4 source address=10.10.0.0/16 service name=ssh accept"; firewall-offline-cmd --list-all | tail -4
success
  source-ports: 
  icmp-blocks: 
  rich rules: 
	rule family="ipv4" source address="10.10.0.0/16" service name="ssh" accept
```

Read it left to right, because the syntax is deliberately English-shaped:

| Part | Says |
| --- | --- |
| `rule family="ipv4"` | This is an IPv4 rule. `ipv6` is a separate rule. |
| `source address="10.10.0.0/16"` | Only traffic from this network |
| `service name="ssh"` | Matching the ports the `ssh` service names |
| `accept` | The verdict. `reject`, `drop`, and `mark` are the others. |

That rule is how "SSH from the management network only" is expressed: the rich
rule accepts from `10.10.0.0/16`, and because `ssh` is not in the zone's plain
service list, everybody else falls through to the zone target and is rejected.

**Rich rules are not an ordered list, and this is where people guess wrong.** A
rule with no `priority` is filed by its verdict, into the zone's deny stage or its
allow stage, and deny is evaluated first. So a rich `reject` beats a plain
`--add-service` for the same port, but a rich `accept` does not automatically beat
anything. When order genuinely matters, say so: `priority` runs from -32768 to
32767, lower first, and a negative value puts the rule ahead of everything else
firewalld generates for that zone.

```
rule priority="-10" family="ipv4" source address="203.0.113.5" drop
rule family="ipv4" source address="10.10.0.0/16" service name="ssh" log prefix="mgmt-ssh " level="info" accept
rule service name="ssh" accept limit value="10/m"
```

**`log` is how you get firewall logging at all**, because firewalld does not log
accepted or rejected traffic by default; the prefix is what you grep the journal
for. **`limit value="10/m"`** caps matches at ten a minute, which takes most of the
value out of a password-guessing attempt without any extra software.

The trap is the one you already know in a new costume: `firewall-cmd
--add-rich-rule=...` without `--permanent` lives until the next reload. The quoting
is fiddly enough that people get the rule right, watch it work, and never notice
the missing flag.

<details class="deeper">
<summary>If you already administer Linux: `--direct` and `--passthrough`, and what reaching for them tells you</summary>

firewalld has an escape hatch for rules its own vocabulary cannot express:

```
sudo firewall-cmd --permanent --direct --add-rule ipv4 filter INPUT 0 \
  -p tcp --dport 8080 -m state --state NEW -j ACCEPT
sudo firewall-cmd --direct --get-all-rules
```

That is an `iptables` rule passed through nearly verbatim, with a priority number
deciding where it lands relative to *other direct rules*. `--passthrough` is
blunter still: it hands the arguments straight to `iptables` and firewalld does not
attempt to understand them at all.

**They are deprecated.** `firewall-cmd(1)` says so in as many words and names the
replacement: policies, created with `--new-policy`, which express the cross-zone
and forwarded-traffic cases direct rules used to be needed for. Code still using
them is usually code written against firewalld 0.6 and never revisited.

**Priority zero is not "first", and on a current machine it is not even the same
table.** With the nftables backend firewalld's own rules live in an `inet` table it
owns, while a direct rule is added through `iptables` and lands in the classic
`filter` table. Both are attached to the same hooks and the kernel evaluates them
by hook priority, so a direct `ACCEPT` does not reliably pre-empt a zone's
behaviour. People who assume it does write a rule that appears in
`--get-all-rules`, is syntactically perfect, and never decides anything. That is
lesson 40's "the packet never visits that chain" problem, one level up.

**They bypass the abstraction, so they bypass its protections.** A zone rule is
re-derived on every reload; a direct rule is replayed as text. If a future
firewalld reorganises its chains, your direct rule is inserted somewhere you did
not intend and nothing warns you.

**The judgement call.** More than one or two direct rules is not evidence that
firewalld is limited, it is evidence that this machine has outgrown zones. A router
filtering between six networks is not a zone-shaped problem, and plain `nftables`
with a ruleset in version control is smaller and more reviewable than a pile of
direct rules smuggled through a tool trying to do something else. The cost is the
named services and the zone model, which on a router you were not using anyway.

</details>

## ufw, and the ordered list

Ubuntu ships ufw, which was written to make a firewall approachable and largely
succeeds. It has no zones and no services dictionary. It has verbs, and a list.

```bash
# Ubuntu 24.04 LTS, x86_64
$ ufw status; grep ENABLED /etc/ufw/ufw.conf
ERROR: Couldn't determine iptables version
ENABLED=no
```

**`Status: inactive` is the state ufw ships in**, and it is not an error. Ubuntu
installs ufw on every image and leaves it switched off, so a fresh Ubuntu machine
has a firewall tool and no firewall. `ENABLED=no` in `/etc/ufw/ufw.conf` is the
same fact from the other side: that line is what `ufw enable` edits, and it decides
whether the rules come back after a reboot.

The grammar is `ufw [insert NUM] allow|deny|reject|limit [in|out] [from ADDR [port
PORT]] [to ADDR [port PORT] [proto PROTO]]`, which covers what most people need
without a manual:

```
ufw allow 22/tcp
ufw allow from 10.10.0.0/16 to any port 5432 proto tcp
ufw deny 23/tcp
ufw limit ssh
```

**`deny` drops and `reject` replies**, which is lesson 40's distinction with the
choice made in one word. **`limit` is the verb with no equivalent elsewhere**: it
allows the connection but denies an address that has attempted six or more
connections in the last thirty seconds. It is the rich rule `limit` clause with the
numbers already chosen for you.

Applications register named profiles, which is ufw's answer to firewalld's
services:

```bash
# Ubuntu 24.04 LTS, aarch64
$ ufw app list; ufw app info OpenSSH
Available applications:
  OpenSSH
Profile: OpenSSH
Title: Secure shell server, an rshd replacement
Description: OpenSSH is a free implementation of the Secure Shell protocol.

Port:
  22/tcp
```

Those come from files in `/etc/ufw/applications.d` dropped there by packages, so
the list reflects what is installed rather than a fixed dictionary. That is the
opposite trade-off from firewalld, which ships hundreds of definitions for software
you do not have.

**`--dry-run` prints what ufw would write and changes nothing.** It is the fastest
way to see what one verb actually costs:

```bash
# Ubuntu 24.04 LTS, aarch64
$ ufw --dry-run allow 22/tcp | wc -l; ufw --dry-run allow 22/tcp | awk "/### RULES ###/,/### END RULES ###/"
70
### RULES ###

### tuple ### allow tcp 22 0.0.0.0/0 any 0.0.0.0/0 in
-A ufw-user-input -p tcp --dport 22 -j ACCEPT

### END RULES ###
### RULES ###

### tuple ### allow tcp 22 ::/0 any ::/0 in
-A ufw6-user-input -p tcp --dport 22 -j ACCEPT

### END RULES ###
```

**Seventy lines for one verb, and two `### RULES ###` sections.** ufw does not emit
a rule; it emits the entire ruleset it intends the machine to have, IPv4 and IPv6,
with your rule inserted into it. That is the mechanism behind everything else here:
ufw owns the file, regenerates it in full, and applies it atomically.

Adding rules for real is unremarkable, which is the idea:

```bash
# Ubuntu 24.04 LTS, aarch64
$ ufw allow 22/tcp; ufw deny 23/tcp
Rules updated
Rules updated (v6)
Rules updated
Rules updated (v6)
```

`Rules updated` twice per command, because ufw writes the IPv4 and IPv6 rule from
one line by default. That is genuinely better than the `iptables` era, where the
IPv6 half was a separate command everybody forgot.

Enabling the firewall is what turns the file into policy, and `ufw status
numbered` is how you then read it:

```bash
# Ubuntu 24.04 LTS, aarch64
$ ufw --force enable; ufw status numbered
Firewall is active and enabled on system startup
Status: active

     To                         Action      From
     --                         ------      ----
[ 1] 22/tcp                     ALLOW IN    Anywhere                  
[ 2] 5432/tcp                   ALLOW IN    10.10.0.0/16              
[ 3] 23/tcp                     DENY IN     Anywhere                  
[ 4] 22/tcp (v6)                ALLOW IN    Anywhere (v6)             
[ 5] 23/tcp (v6)                DENY IN     Anywhere (v6)             
```

`--force` skips the prompt warning that enabling may disrupt existing SSH
connections; on a remote machine, read that prompt rather than skipping it. The
numbered list is the ordered list: `ufw delete 3` removes the third entry and
`ufw insert 1 ...` puts one at the top. **The numbers are positions, not
identifiers** — deleting rule 3 renumbers everything below it, which is the
opposite of the stable nftables handles from lesson 40.

The same rules on disk, in the same order:

```bash
# Ubuntu 24.04 LTS, aarch64
$ grep -A 12 "### RULES ###" /etc/ufw/user.rules
### RULES ###

### tuple ### allow tcp 22 0.0.0.0/0 any 0.0.0.0/0 in
-A ufw-user-input -p tcp --dport 22 -j ACCEPT

### tuple ### allow tcp 5432 0.0.0.0/0 any 10.10.0.0/16 in
-A ufw-user-input -p tcp --dport 5432 -s 10.10.0.0/16 -j ACCEPT

### tuple ### deny tcp 23 0.0.0.0/0 any 0.0.0.0/0 in
-A ufw-user-input -p tcp --dport 23 -j DROP

### END RULES ###
```

`/etc/ufw/user.rules` is the permanent configuration, it is plain text, and file
order is evaluation order. The `### tuple ###` comment above each line is how ufw
reconstructs `ufw status` from `iptables` syntax it wrote itself.

<details class="deeper">
<summary>If you already administer Linux: why `ufw insert` exists, and where hand-written rules actually belong</summary>

ufw evaluates its user rules in file order and stops at the first match, and every
rule you add goes on the end. Those two facts together produce the classic ufw
incident.

**The shape of it:** somebody adds `ufw deny from 203.0.113.0/24` to block a noisy
network. Later, somebody else adds `ufw allow 443/tcp` because the site is going
public. The allow lands *after* the deny, so that network is still blocked, which
is intended. Now reverse the order of those two events: the `allow 443/tcp` is
already there, the `deny` is appended below it, and the block silently does nothing
for the one port anybody cares about. The rules are identical; only the order two
people happened to type them differs.

**`ufw insert N` is the fix and it is positional:**

```
ufw status numbered
ufw insert 1 deny from 203.0.113.0/24
```

**The numbers renumber on every insert and delete**, so `ufw delete 2; ufw delete 3`
does not remove the rules that were 2 and 3: after the first deletion the old rule
4 is the new rule 3. Delete from the bottom up, or delete by rule text, since
`ufw delete allow 22/tcp` matches on content and is safe against renumbering.

**Specific before general** is the habit that keeps this from arising. ufw mostly
does it for you when rules concern different ports, because a rule naming a port
only matches that port. It cannot help when one rule names a source and another
names a port, because then both match the same packet and only position decides.

**And the thing that bites people who know `iptables`:** `/etc/ufw/user.rules` is
generated, but it is also read back, so hand-editing it works and survives. It is
still the wrong place. `ufw reset` overwrites it without asking, and a syntax error
in it makes `ufw enable` fail with a message about the file rather than about your
rule. The supported homes for hand-written rules are `/etc/ufw/before.rules` and
`/etc/ufw/after.rules`, which ufw wraps around its own generated block and does not
regenerate. Those two names are also the answer to "how do I get a rule to run
*before* everything ufw wrote", which is otherwise not expressible at all.

</details>

## nftables directly, and saving what you did

On Debian there is often no front end installed. You write rules with `nft`,
exactly as in lesson 40, and you meet the problem the other two tools were built to
solve: **`nft` changes the kernel and touches no file, ever.** There is no permanent
configuration, no daemon, and nothing that will restore your work.

Writing the current state out is one redirection:

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ sudo nft list ruleset | sudo tee /var/tmp/rules.nft >/dev/null; head -12 /var/tmp/rules.nft
table inet filter {
	chain input {
		type filter hook input priority filter; policy accept;
		ct state established,related accept
		tcp dport 22 accept
	}

	chain output {
		type filter hook output priority filter; policy accept;
		ip daddr 1.1.1.1 counter packets 1 bytes 84 drop
	}
}
```

That is the ruleset built in lesson 40, now on disk. The output of `nft list
ruleset` is **valid input to `nft -f`**, which is the design decision that makes
this work: the dump format and the source format are the same language, so there is
no export step and no separate tooling.

<details class="predict">
<summary>`nft flush ruleset` empties the kernel of every table and rule. The file you just wrote is still on disk and is valid `nft` input. What does the flush leave behind, and what comes back when the file is reloaded?</summary>

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ sudo nft flush ruleset; sudo nft list ruleset; echo "--- gone. now reload the file ---"; sudo nft -f /var/tmp/rules.nft; sudo nft list tables
--- gone. now reload the file ---
table inet filter
table ip nat
```

</details>

**`nft list ruleset` printed nothing at all** after the flush, because an empty
kernel ruleset is empty output rather than a message, and `nft -f` brought back
both tables. A reboot is that flush without the reload.

Surviving a reboot on Debian is two things, and both are required:

```
# 1. write the file the unit reads
sudo nft list ruleset > /etc/nftables.conf

# 2. make something read it at boot
sudo systemctl enable --now nftables.service
```

**The file wants one extra line at the top.** A ruleset file beginning with `flush
ruleset` replaces everything rather than adding to what is already loaded, which
makes reloading it idempotent instead of doubling every rule:

```
#!/usr/sbin/nft -f
flush ruleset

table inet filter {
	chain input {
		type filter hook input priority filter; policy drop;
		ct state established,related accept
		iif "lo" accept
		tcp dport 22 accept
	}
}
```

**`nft -f` is atomic**, and this is the property worth the whole section. The file
is parsed and validated first, and either all of it is applied or none of it is. A
typo on line 40 leaves the machine running the old ruleset rather than half a new
one, which is exactly the failure mode a shell script full of `nft add rule` lines
has. You can watch the validation refuse something:

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ sudo nft add rule inet filter input tcp dport 80 acept 2>&1; echo "rc=$?"
Error: syntax error, unexpected newline
add rule inet filter input tcp dport 80 acept
                                             ^
rc=1
```

A misspelled verdict, the offending position marked, and a non-zero exit status.
**The non-zero status is the part that matters in a script**: `nft` fails loudly
and can be tested for, so `set -e` does what you want.

<details class="deeper">
<summary>If you already administer Linux: sets, maps, and ipset, and why ten thousand addresses is one lookup rather than ten thousand comparisons</summary>

A chain is walked in order until something matches. That is fine for twenty rules
and catastrophic for ten thousand: blocking ten thousand addresses with ten
thousand rules means the average packet is compared against five thousand of them,
per packet, in the kernel's hot path.

**A set is a hash table, and matching against it is one lookup regardless of size.**

```
table inet filter {
	set blocklist {
		type ipv4_addr
		flags interval
		elements = { 203.0.113.0/24, 198.51.100.7 }
	}

	chain input {
		type filter hook input priority filter; policy drop;
		ip saddr @blocklist drop
	}
}
```

One rule. The `@blocklist` reference costs the same whether the set holds ten
entries or a million, and the set can be modified without touching the rule:

```
sudo nft add element inet filter blocklist { 192.0.2.55 }
sudo nft delete element inet filter blocklist { 192.0.2.55 }
```

**`flags interval` is the one to remember**, because without it a set holds exact
addresses only and adding a CIDR range fails with an error about the type. With it,
ranges and prefixes work. **`flags timeout` is the other one**: each element carries
its own expiry and the kernel removes it, so a fail2ban-shaped tool needs no cron
job and no state file.

**Maps return a value rather than a yes or no**, which collapses a dispatch table
into a rule. Note the two spellings: `map` yields data, `vmap` yields a verdict, and
using `map` where a jump is intended is a syntax error people lose ten minutes to.

```
tcp dport vmap { 80 : jump web_chain, 25 : jump mail_chain, 443 : jump web_chain }
dnat to ip daddr map { 203.0.113.10 : 10.0.0.5, 203.0.113.11 : 10.0.0.6 }
```

That second line is fifty port-forwards as one rule and one lookup.

**Where `ipset` fits.** `ipset` is the older, separate tool that gave `iptables` the
same capability, and it is still everywhere:

```
sudo ipset create blocklist hash:net
sudo ipset add blocklist 203.0.113.0/24
sudo iptables -I INPUT -m set --match-set blocklist src -j DROP
```

It works, it performs, and the exam expects you to recognise the name. The
practical catch is that an `ipset` is a **separate object from the ruleset**:
saving your `iptables` rules does not save the set, restoring them against a
missing set fails, and `ipset save` and `ipset restore` are their own persistence
problem with their own file. A native nftables set keeps everything in one atomic
`nft -f` file, which is why new work should not reach for `ipset` even though it
still functions.

**The number to have ready** when somebody asks why the firewall is expensive: rule
evaluation is linear in the number of rules in a chain, set matching is constant or
logarithmic in the number of elements. Ten thousand blocked networks is a
configuration problem in one form and a performance incident in the other.

</details>

## iptables is a syntax, not a firewall

`iptables` is still installed nearly everywhere and still in every tutorial written
before about 2019, so it needs placing precisely: on a current distribution it is
**a front end, like the other three**, translating its own syntax into nftables
rules. The version string is where you check, because two implementations hide
behind one command name:

```bash
# Ubuntu 24.04 LTS, aarch64
$ iptables --version; update-alternatives --display iptables | head -4
iptables v1.8.10 (nf_tables)
iptables - auto mode
  link best version is /usr/sbin/iptables-nft
  link currently points to /usr/sbin/iptables-nft
  link iptables is /usr/sbin/iptables
```

`(nf_tables)` is the compatibility front end, and `auto mode` pointing at
`/usr/sbin/iptables-nft` is the Debian-family default. The alternative is the one
that is genuinely a different firewall:

| Binary | Writes to | Visible in `nft list ruleset` |
| --- | --- | --- |
| `iptables-nft` | nftables, as a `filter`-style table | **Yes** |
| `iptables-legacy` | The old `x_tables` engine | No |

**Why this matters more than a historical footnote:** the two engines are evaluated
separately by the kernel, both attached to the same hooks. A machine where somebody
switched some tooling to legacy and left the rest on nft has two independent
firewalls, each invisible in the other's listing, and a packet must pass both.
`iptables --version` on a machine that behaves inexplicably is a ten-second check
with a real chance of explaining everything.

`update-alternatives --set iptables /usr/sbin/iptables-nft` sets it on a
Debian-family machine; the RHEL family ships only the nft version and has no
alternative to select. `iptables-save` and `iptables-restore` are the persistence
pair, and the same split applies, since `iptables-save` reads whichever back end is
currently selected.

<details class="deeper">
<summary>If you already administer Linux: translating an existing iptables ruleset, and the four things that do not come across</summary>

`iptables-translate` converts a single `iptables` command into its `nft` equivalent
without touching the kernel, and `iptables-restore-translate` does the same for a
whole saved ruleset:

```
iptables-translate -A INPUT -p tcp --dport 22 -m conntrack --ctstate NEW -j ACCEPT
# nft add rule ip filter INPUT tcp dport 22 ct state new counter accept

sudo iptables-save > /tmp/old.rules
iptables-restore-translate -f /tmp/old.rules > /tmp/new.nft
```

That gets you eighty percent of a migration in a minute, and the remaining twenty
percent is where the afternoon goes.

**The `ip` and `ip6` split stays split.** The translation is mechanical, so an IPv4
ruleset becomes an IPv4-only nftables ruleset in a `table ip filter`. You get none
of the benefit of the `inet` family, which is the main reason to migrate at all.
Merging the two by hand into one `inet` table is the actual work, and it is where
you discover which rules the IPv6 half never had.

**Modules with no nftables equivalent are emitted as-is or refused.** Anything using
`-m recent`, `-j TARPIT`, or a niche `xt_` match may come out untranslated or not at
all. `-m recent` in particular is common in home-grown SSH protection, and its
replacement is a set with `flags timeout`, which is a rewrite rather than a
translation.

**Custom chains survive, but their ordering assumptions may not.** Translation
preserves what you wrote; it does not preserve the fact that your ruleset assumed
nothing else was attached to the same hook. Once you are in nftables you share that
hook with everything else on the machine, priorities deciding order, so a ruleset
that worked when it was the only thing present can be pre-empted after the move.

**Counters do not come across at all.** The translation produces rules, not the
packet counts that told you which rules were doing work. Take `iptables -L -v -n`
output before the migration if you intend to prune dead rules afterwards, because
the counters are how you tell a rule that matters from one somebody added in 2016.

**The safe sequence**, worth following on anything you cannot walk over to:
translate to a file, read the file end to end, apply it with `nft -f` on a machine
with a scheduled `nft flush ruleset` five minutes out, verify from a second session,
then cancel the timer. The atomicity of `nft -f` means the failure mode is "nothing
changed", which is the one you want.

</details>

## Across distributions

| | RHEL family | Debian family |
| --- | --- | --- |
| Installed and running by default | `firewalld`, enabled | Debian: none. Ubuntu: `ufw`, installed and **inactive**. |
| Package to install | `firewalld` | `ufw`, `nftables` |
| Permanent configuration | `/etc/firewalld/**/*.xml` | `/etc/ufw/*.rules`, `/etc/nftables.conf` |
| Unit that loads it | `firewalld.service` | `ufw.service`, `nftables.service` |
| Apply a saved change | `firewall-cmd --reload` | `ufw reload`, `nft -f /etc/nftables.conf` |
| Named service definitions | `/usr/lib/firewalld/services/` | `/etc/ufw/applications.d/` |
| `iptables` back end | `iptables-nft` only | `iptables-nft`, with `iptables-legacy` selectable |

**SUSE is the odd one out and worth a sentence**, because "SUSE is RPM-based so it
must be firewalld" is only half right: it ships firewalld as the default, having
replaced its own `SuSEfirewall2` some releases ago, so the RHEL habits transfer.

**The row to act on is the first one.** A fresh Ubuntu machine has a firewall tool
and no firewall, and a fresh Debian machine has neither. Assuming a default-deny
posture exists because the distribution is "secure by default" is how a database
ends up reachable from the internet.

## Prove it

```
# Which front end is even in charge on this machine
systemctl is-active firewalld ufw nftables

# The truth, whoever wrote it, from every source at once
sudo nft list ruleset

# firewalld: the two configurations, separately, and compare them
sudo firewall-cmd --list-all
sudo firewall-cmd --permanent --list-all

# firewalld: which zone is this interface actually in
sudo firewall-cmd --get-active-zones

# ufw: the ordered list with the numbers you need to edit it
sudo ufw status numbered

# nftables: is what is loaded the same as what is on disk
sudo diff <(sudo nft list ruleset) /etc/nftables.conf

# and which iptables you have, when something is inexplicable
iptables --version
```

**`nft list ruleset` is the one that does not lie to you.** Every other command in
that list reports what one tool believes. That one reports what the kernel will
actually do, including the chains a container runtime installed that no front end
knows about.

## What trips people up

### 1. `--permanent` with no `--reload`

Written to `/etc/firewalld/zones/`, and the kernel has never heard of it. Testing
immediately sends people looking for a mistake in a rule that is perfectly correct.
`firewall-cmd --reload` after every permanent change, without exception.

### 2. `--reload` with no `--permanent`

The mirror image, and the more expensive one because the failure is delayed by
however long it takes somebody else to reload for an unrelated reason.

### 3. Adding the rule to a zone the interface is not in

`firewall-cmd --add-service=http` acts on the **default** zone. If the interface is
bound to `internal`, or a source binding put this traffic in `trusted`, the rule
is in a policy that never evaluates this traffic. Run `--get-active-zones` first,
then `--zone=` explicitly.

### 4. A ufw rule appended below one that already matched

ufw evaluates in file order and stops at the first match, so a `deny` added after
an `allow` for the same traffic does nothing. `ufw status numbered`, then
`ufw insert 1` rather than `ufw allow`.

### 5. `nft` rules that were never written to a file

`nft add rule` changes the kernel, and that is the entire scope of what it does.
The file and the enabled unit are both required, not either.

### 6. Treating `iptables` as a separate firewall

On a current machine it is a syntax over nftables, so its rules appear in `nft list
ruleset`. The exception is real and specific: `iptables-legacy` **is** a separate
engine, and `iptables --version` distinguishes them.

## Work it through

A RHEL 10 server runs an application on port 8443. From the machine itself,
`curl https://localhost:8443/` works. From anywhere else, it times out.

Reason it out before reading on.

**First, establish it is a firewall problem at all:**

```
sudo ss -tlnp | grep 8443
```

`127.0.0.1:8443` means the application is bound to loopback and no firewall rule
will ever help. `0.0.0.0:8443` means it is listening on the network and something
between the client and the socket is refusing.

**Second, ask which zone is actually judging this traffic**, because every
`firewall-cmd` command that does not say `--zone=` is talking about the default
one:

```
sudo firewall-cmd --get-active-zones
sudo firewall-cmd --list-all
```

**This is usually where it is.** The active zone is `internal` on `enp1s0`, and the
port was added to `public`, which nothing is bound to. The rule is real, correct,
and in a policy that never sees the packet.
`firewall-cmd --permanent --zone=internal --add-port=8443/tcp` and a reload fixes
it.

**Now change one detail.** Suppose the port is present in the right zone's runtime
configuration and absent from `firewall-cmd --permanent --list-all`. Nothing is
broken today and everything breaks at the next reload; that is
`--runtime-to-permanent`, and it is worth checking even when the port is reachable.

**And one more.** Suppose the port is in both configurations, in the bound zone,
and it still times out from outside while working from the office. Look for a rich
rule with a `source address` clause, which is indistinguishable from a working
firewall until you test from an address it does not cover, and then read
`sudo nft list ruleset` for a chain nobody in firewalld knows about, a container
runtime's for instance.

The point worth extracting: **a front end question is almost never "is my rule
right".** It is "which configuration am I looking at, has anything loaded it, and is
it the policy that judges this traffic". Three questions, three commands, and the
rule's syntax is the last thing worth doubting even though it is the first thing
everybody checks.

## Try it

Optional, and on a machine you can reach another way.

1. On a RHEL-family machine: `firewall-cmd --state`, `--get-default-zone`, and
   `--get-active-zones`. Name which interface is in which zone.
2. `firewall-cmd --list-all` beside `firewall-cmd --permanent --list-all`. Confirm
   they agree before you change anything.
3. `sudo firewall-cmd --add-port=9999/tcp`, then both listings again. Watch them
   disagree. Then `--reload` and watch the port vanish.
4. Do it properly with `--permanent --add-port=9999/tcp` and `--reload`, then read
   `/etc/firewalld/zones/public.xml`.
5. Add a rich rule limiting SSH to one subnet, permanently, and read the XML again.
6. On an Ubuntu machine: `ufw status`, `ufw allow 22/tcp`, `ufw status numbered`,
   `ufw insert 1 deny from 203.0.113.0/24`, `ufw status numbered` again. Watch the
   numbers move.
7. On anything: `sudo nft list ruleset > /tmp/rules.nft`, `sudo nft flush ruleset`,
   then `sudo nft -f /tmp/rules.nft`. Confirm with `nft list tables`.
8. `iptables --version` on every machine you have, and note which say `nf_tables`.

**Verification step.** You have it when you can say, for a rule you are about to
add, exactly which file it will end up in and what has to happen before the kernel
enforces it, before you press return.

## Check yourself

<details class="qa">
<summary>Somebody ran `firewall-cmd --add-port=8080/tcp` three weeks ago and it worked. Today, after a colleague ran `firewall-cmd --reload`, port 8080 is closed. Explain, and give the command that should have been used.</summary>

**The rule was runtime-only.** Without `--permanent`, `firewall-cmd` changes the
configuration loaded in the kernel and writes nothing to disk. `--reload` discards
the runtime configuration entirely and rebuilds it from
`/etc/firewalld/zones/*.xml`, and port 8080 was never in those files.

```
sudo firewall-cmd --permanent --add-port=8080/tcp
sudo firewall-cmd --reload
```

The tempting wrong answer is that the colleague deleted something. They did not:
reload is not destructive, it is *authoritative*, and the two are easy to confuse.
The equally tempting half-fix is to run `--permanent` on its own next time, which
gives you the mirror-image failure, written down correctly with no effect at all.

**The thing you will need next** is the diagnostic that catches both before they
cost anything: `firewall-cmd --list-all` beside `firewall-cmd --permanent
--list-all`. If they disagree you already know which of the two mistakes is on this
machine, and `--runtime-to-permanent` promotes a runtime configuration you have
finished testing.

</details>

<details class="qa">
<summary>What is a firewalld zone, and why is a newly installed web server unreachable on a default RHEL install even though it is listening on 0.0.0.0:80?</summary>

**A zone is a named policy: a target for unmatched traffic, plus a list of
exceptions.** Interfaces and source addresses are bound to zones, and traffic is
judged by the zone its arrival is bound to.

**The default zone is `public`**, which lists `ssh`, `dhcpv6-client`, and `cockpit`
with `target: default`, meaning unmatched packets are rejected. Port 80 is not on
that list, so packets are refused before the web server ever sees them.

```
sudo firewall-cmd --permanent --add-service=http --add-service=https
sudo firewall-cmd --reload
```

The tempting wrong answer is that the application is misconfigured, because
everything about it looks right. That is precisely the evidence that it is not the
application: a bind problem shows `127.0.0.1:80` instead.

**What you will need next** is that adding to the default zone is only correct if
the default zone is the one in play. `firewall-cmd --get-active-zones` names the
bindings, and a **source** binding beats an **interface** binding, so traffic from
a subnet listed in another zone's `sources:` is judged there instead and a perfect
rule in `public` never sees it.

</details>

<details class="qa">
<summary>You run `ufw allow 8080/tcp` on Ubuntu and the port stays closed. Give two distinct explanations and say how to tell them apart.</summary>

**One: ufw is not enabled.** Ubuntu ships it installed and inactive, so the rule is
recorded and enforced by nothing. `ufw status` says `Status: inactive` and
`/etc/ufw/ufw.conf` says `ENABLED=no`. `sudo ufw enable` is the fix, and on a remote
machine you add the SSH rule *first*.

**Two: an earlier rule already matched.** ufw evaluates in file order and stops at
the first match, and every new rule is appended to the end, so a broad `deny` above
your `allow` decides the packet before your rule is reached.

**Telling them apart is one command:** `sudo ufw status numbered`. `Status:
inactive` is the first case. A numbered list is the second, and you read it top to
bottom for whatever matches port 8080 before your line does.

The fix for the second is positional: `sudo ufw insert 1 allow 8080/tcp`. **The
numbers renumber after every insert and delete**, so a loop of `ufw delete 2; ufw
delete 3` removes the wrong rules; delete from the bottom up, or by text with
`ufw delete allow 8080/tcp`.

Worth knowing next: this ordering problem is specific to ufw's model. firewalld has
no ordered user list to get wrong, and nftables gives every rule a stable handle
that does not renumber when its neighbours are deleted.

</details>

<details class="qa">
<summary>Rules added with `nft` are gone after a reboot. What are the two things you must do, and why does firewalld not have this problem?</summary>

**Write the ruleset to a file, and enable a unit that loads it.** Both, because
either alone does nothing:

```
sudo nft list ruleset > /etc/nftables.conf
sudo systemctl enable --now nftables.service
```

`nft` manipulates the running kernel and has no persistence of its own: no daemon
holding a copy, no configuration directory it consults, nothing that notices you
made a change. A reboot starts with an empty ruleset.

**firewalld does not have the problem because persistence is its main job.** Its
permanent configuration *is* a set of files, `firewalld.service` loads them at boot,
and `--reload` loads them again. The two tools sit at opposite ends of one
trade-off: firewalld makes you say when you mean the runtime configuration, and
`nft` makes you say when you mean the persistent one.

The tempting wrong answer is the redirection on its own. The file is correct and
nothing reads it unless the unit is enabled, which is the same shape as
`systemctl start` without `enable` from lesson 33.

**Put `flush ruleset` at the top of that file.** Without it, reloading adds to
whatever is already present instead of replacing it, so a second `nft -f` doubles
every rule.

</details>

<details class="qa">
<summary>Is `iptables` a different firewall from `nftables`? Answer precisely, and say what you would run to be sure on a specific machine.</summary>

**Usually no, occasionally yes, and the difference is which binary is installed
behind the name.**

On any current distribution `iptables` is `iptables-nft`: a front end translating
its own syntax into nftables rules. Rules added with it appear in `nft list
ruleset`, in tables named after the classic ones. It is a third syntax over the
same engine, not a competing firewall.

**`iptables-legacy` is the exception and it is genuinely separate.** It drives the
old `x_tables` code, which the kernel evaluates independently at the same hooks, so
a machine running some tooling on legacy and some on nft has two firewalls, each
invisible in the other's listing, and a packet has to satisfy both.

`iptables --version` settles it: `nf_tables` in the output means the compatibility
front end, `legacy` means the separate engine, and
`update-alternatives --set iptables /usr/sbin/iptables-nft` switches a
Debian-family machine back.

The tempting wrong answer is that `iptables` is simply obsolete and can be ignored.
It is still the interface a great deal of running software uses, including ufw,
Docker, and a decade of scripts, so knowing its rules land in the same ruleset is
what lets you read `nft list ruleset` and recognise where each table came from.

**What you will need next**: to migrate rather than translate on the fly, pipe
`iptables-save` through `iptables-restore-translate` to get an `nft` file, then read
it. The mechanical translation keeps the IPv4-only structure, so merging into one
`inet` table, the actual benefit, is manual work.

</details>

## References

- [firewall-cmd(1)](https://manpages.debian.org/trixie/firewalld/firewall-cmd.1.en.html) - Debian manpages. Accessed 2026-08-08.
- [firewalld.zone(5)](https://manpages.debian.org/trixie/firewalld/firewalld.zone.5.en.html) - Debian manpages. Accessed 2026-08-08.
- [firewalld.richlanguage(5)](https://manpages.debian.org/trixie/firewalld/firewalld.richlanguage.5.en.html) - Debian manpages. Accessed 2026-08-08.
- [ufw(8)](https://manpages.debian.org/trixie/ufw/ufw.8.en.html) - Debian manpages. Accessed 2026-08-08.
- [ufw-framework(8)](https://manpages.debian.org/trixie/ufw/ufw-framework.8.en.html) - Debian manpages. Accessed 2026-08-08.
- [nft(8)](https://manpages.debian.org/trixie/nftables/nft.8.en.html) - Debian manpages. Accessed 2026-08-08.
- [iptables-translate(8)](https://manpages.debian.org/trixie/iptables/iptables-translate.8.en.html) - Debian manpages. Accessed 2026-08-08.
- [ipset(8)](https://manpages.debian.org/trixie/ipset/ipset.8.en.html) - Debian manpages. Accessed 2026-08-08.
- [nftables wiki](https://wiki.nftables.org/wiki-nftables/index.php/Main_Page) - Netfilter project. Accessed 2026-08-08.

The firewalld output came from an AlmaLinux 10 container, where no daemon can run,
so `firewall-cmd --state` genuinely fails and every configuration command shown is
`firewall-offline-cmd` editing the permanent files directly. The ufw and `iptables`
output came from an Ubuntu 24.04 container running privileged so that it has its
own network namespace to write rules into; it is labelled `aarch64` because that
capture path runs on the podman machine's kernel, and none of that output varies by
architecture. The nftables output came from a Fedora CoreOS virtual machine with a
real kernel, so the flush and the reload really happened. Blocks without a
distribution and architecture header are illustrative.
