---
title: "The number in the firewall rule"
description: "A firewall rule says 443 and nobody explains what that means. The ports this exam expects you to know, a way to learn them that is not brute repetition, the plaintext and encrypted pairs, and the uncomfortable fact that a port number guarantees nothing at all."
track: "network-plus"
level: "intro"
order: 110
objectives:
  - "Recall the port numbers and transports this exam names"
  - "Say what a port number does and does not tell you about traffic"
  - "Pair each plaintext protocol with its encrypted counterpart"
  - "Say whether a given protocol uses TCP, UDP, or both, and why"
  - "Explain why moving a service to a non-standard port is not a security control"
prerequisites: ["tcp-udp-and-the-handshake"]
tags: ["network-plus", "networking", "ports", "protocols"]
updated: 2026-08-10
draft: false
examObjectives:
  - exam: "n10-009"
    domain: "1.0"
    objective: "1.4"
sources:
  - title: "Service Name and Transport Protocol Port Number Registry"
    url: "https://www.iana.org/assignments/service-names-port-numbers/service-names-port-numbers.xhtml"
    publisher: "IANA"
    accessed: 2026-08-10
    tier: 1
  - title: "RFC 6409, Message Submission for Mail"
    url: "https://www.rfc-editor.org/rfc/rfc6409"
    publisher: "IETF"
    accessed: 2026-08-10
    tier: 1
  - title: "RFC 8314, Cleartext Considered Obsolete: Use of TLS for Email Submission and Access"
    url: "https://www.rfc-editor.org/rfc/rfc8314"
    publisher: "IETF"
    accessed: 2026-08-10
    tier: 1
  - title: "RFC 9293, Transmission Control Protocol"
    url: "https://www.rfc-editor.org/rfc/rfc9293"
    publisher: "IETF"
    accessed: 2026-08-10
    tier: 1
  - title: "services(5)"
    url: "https://man7.org/linux/man-pages/man5/services.5.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-10
    tier: 1
symptoms:
  - symptom: "A firewall rule allows a port but the service is still unreachable"
    anchor: "a-port-number-is-a-convention"
  - symptom: "Traffic on port 443 that is not what it appears to be"
    anchor: "a-port-number-is-a-convention"
---

> **Before you read.** A change request says "allow inbound 443 from the branch
> office". It is approved, the rule goes in, and the ticket closes.
>
> A month later somebody asks what is actually crossing that rule.
>
> **What does the number 443 guarantee about the traffic it permits?**

The honest answer is nothing, and understanding why is worth more than the list
of numbers this topic also has to teach. Topic 02 covered what a port is and how
a connection is identified. This one is about the conventions built on top of
that, and about how much weight those conventions will bear.

### Some words you will need

<dl class="terms">
<dt>service name</dt>
<dd>The label a port is registered under, such as <code>https</code> for 443. A name, not an enforcement.</dd>
<dt>registry</dt>
<dd>IANA's list of which service claimed which port. A record of claims, not a set of rules.</dd>
<dt>plaintext protocol</dt>
<dd>One that sends its data readable, with no encryption of its own.</dd>
<dt>implicit TLS</dt>
<dd>Encryption from the first byte, on a port dedicated to the encrypted version.</dd>
<dt>opportunistic TLS</dt>
<dd>Starting in plaintext on the ordinary port and upgrading, usually with a STARTTLS command.</dd>
</dl>

## What breaks without this

**You approve firewall rules you cannot reason about.** A rule is written in port
numbers. Not knowing what each one conventionally carries means approving changes
on trust, which is how a permitted port becomes a route out for something nobody
sanctioned.

**Half the exam's scenario questions become unreadable.** A question describing a
fault will say a port is open or blocked and expect you to know which service
that affects. There is no working around it.

**You mistake obscurity for a control.** Moving a service to an unusual port
feels protective and is not, and the reasoning behind that is worth having before
somebody proposes it in a design review.

## A port number is a convention

A port number is how a machine decides which listening program gets an arriving
segment. That is the entire mechanism. Nothing checks that the program on port
443 is a web server, and nothing checks that what it sends is encrypted.

Which is easy to demonstrate and slightly alarming to watch.

<details class="predict">
<summary>An ordinary plaintext listener on port 443, the port everybody reads as encrypted. What does a capture of it show?</summary>

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology one-router
# a plain text listener on 443, the port everyone reads as encrypted
$ (ip netns exec h2 nc -l -p 443 > /dev/null 2>&1 &)
$ (ip netns exec h1 timeout 8 tcpdump -i h1eth0 -n -A -U "tcp port 443 and tcp[tcpflags] & tcp-push != 0" > /tmp/l.txt 2>/dev/null &)
$ sleep 2
$ ip netns exec h1 sh -c "echo 'PASSWORD hunter2' | nc -w 2 10.0.2.2 443" > /dev/null 2>&1
$ sleep 9
$ cat /tmp/l.txt
21:17:11.361535 IP 10.0.1.2.38184 > 10.0.2.2.443: Flags [P.], seq 4175561513:4175561530, ack 4071577401, win 251, options [nop,nop,TS val 2737025419 ecr 371788080], length 17
E..Ew.@.@...
...
....(.....)..W9.....;.....
.#...)	0PASSWORD hunter2
```

</details>

`PASSWORD hunter2`, readable, on the port whose name means encrypted. Nothing
malfunctioned. The number 443 is a convention about where to find a web server
that uses TLS, and a convention is not a mechanism.

Now the answer to the question at the top. The rule permitting 443 guarantees
that traffic may cross to that port, and nothing else. It does not guarantee the
traffic is HTTPS, that it is encrypted, that it is going to a web server, or that
it is going anywhere it was intended to. Port 443 is open outbound almost
everywhere on earth, which is exactly why so much software that has nothing to do
with the web is built to use it.

The useful mental model is a phone extension. Dialling extension 443 reaches
whoever is sitting at that desk. It does not tell you who they are or what they
will say.

<details class="deeper">
<summary>If you already work on networks: why moving SSH to port 2222 is not a security control, and what it does buy</summary>

Somebody proposes this in every organisation eventually, usually after seeing how
many failed login attempts port 22 attracts. It is worth being precise about what
it does and does not do, because the answer is not simply no.

What it does not do is stop anybody who is looking at you. A port scan finds the
service in seconds, and a scanner that identifies services by what they say
rather than by where they sit identifies it immediately: an SSH daemon announces
its version string as soon as you connect, on any port. Anyone specifically
interested in your organisation is unaffected.

What it does do is remove you from indiscriminate scanning. Most of the traffic
hammering port 22 is automated, sweeping the internet trying default credentials
against whatever answers, and it does not slow down to look elsewhere. Moving the
port makes your logs much quieter, and quieter logs are genuinely useful, because
a real attempt is easier to notice against a background of nothing.

The distinction worth carrying into a design review is between reducing noise and
reducing risk. Obscurity does the first and not the second. It becomes a problem
only when somebody treats the quiet logs as evidence that the service is now
safe, and skips the things that actually protect it: key-based authentication,
no password logins, no root logins, and something rate limiting attempts. Do
those and the port number stops mattering. Do only the port number and nothing
has improved except the log volume.

The same reasoning applies to the reverse case, and it is the one that catches
organisations out. Traffic on 443 gets far less scrutiny than traffic anywhere
else, because blocking it breaks the web. Anything wanting to leave a network
unnoticed uses 443 for exactly that reason, which is why serious egress filtering
inspects what is on the port rather than trusting the number.

</details>

## The list, and a way to learn it

There is no route around memorising this. What there is, is a better order than
numerical.

Learn them grouped by what they do, because that is how questions present them
and because the groups carry the reasoning. The table below is built from IANA's
registry rather than from any study guide, and the transport column is the one
people skip and then lose marks on.

| Function | Protocol | Port | Transport |
| --- | --- | --- | --- |
| File transfer | FTP data | 20 | TCP |
| File transfer | FTP control | 21 | TCP |
| File transfer | TFTP | 69 | UDP |
| File transfer | SMB | 445 | TCP |
| Remote access | SSH | 22 | TCP |
| Remote access | Telnet | 23 | TCP |
| Remote access | RDP | 3389 | TCP |
| Mail | SMTP | 25 | TCP |
| Mail | SMTP submission, which this exam calls SMTPS | 587 | TCP |
| Naming and addressing | DNS | 53 | TCP and UDP |
| Naming and addressing | DHCP server | 67 | UDP |
| Naming and addressing | DHCP client | 68 | UDP |
| Web | HTTP | 80 | TCP |
| Web | HTTPS | 443 | TCP and UDP |
| Directory | LDAP | 389 | TCP |
| Directory | LDAPS | 636 | TCP |
| Management | SNMP | 161 | UDP |
| Management | SNMP trap | 162 | UDP |
| Management | Syslog | 514 | UDP |
| Management | NTP | 123 | UDP |
| Voice | SIP | 5060 | TCP and UDP |
| Voice | SIP over TLS | 5061 | TCP and UDP |
| Databases | SQL Server | 1433 | TCP |
| Databases | Oracle SQLnet | 1521 | TCP |
| Databases | MySQL | 3306 | TCP |

Your own machine holds a copy of most of this, which is worth knowing because it
settles arguments without a search engine.

<details class="predict">
<summary>Every Unix machine ships a file mapping service names to port numbers. What does it say about 443 and 587?</summary>

```bash
# Debian 13 (trixie), x86_64
$ apt-get update -qq >/dev/null 2>&1; apt-get install -y -qq netbase >/dev/null 2>&1; grep -E "^(ftp|ssh|telnet|smtp|domain|bootps|tftp|http|ntp|snmp|ldap|https|syslog|submission|ldaps|mysql|sip)[[:space:]]" /etc/services
ftp		21/tcp
ssh		22/tcp				# SSH Remote Login Protocol
telnet		23/tcp
smtp		25/tcp		mail
domain		53/tcp				# Domain Name Server
domain		53/udp
bootps		67/udp
tftp		69/udp
http		80/tcp		www		# WorldWideWeb HTTP
ntp		123/udp				# Network Time Protocol
snmp		161/tcp				# Simple Net Mgmt Protocol
snmp		161/udp
ldap		389/tcp			# Lightweight Directory Access Protocol
ldap		389/udp
https		443/tcp				# http protocol over TLS/SSL
https		443/udp				# HTTP/3
syslog		514/udp
submission	587/tcp				# Submission [RFC4409]
ldaps		636/tcp				# LDAP over SSL
ldaps		636/udp
mysql		3306/tcp
sip		5060/tcp			# Session Initiation Protocol
sip		5060/udp
```

</details>

Two entries in there are worth stopping on.

`https 443/udp # HTTP/3` is the QUIC case from the previous topic, sitting in the
registry as an ordinary entry. HTTP over UDP is not a curiosity any more.

`submission 587/tcp # Submission [RFC4409]` is the one to notice, because the
system calls port 587 submission rather than SMTPS. The RFC number in Debian's
comment is the older one, since RFC 6409 obsoleted RFC 4409, and the definition
did not change. That disagreement with the exam's naming is covered in the panel
two sections down, and it is not a mistake in either place.

The learning method that works, in order of how much it helps. Group by function,
which the table above does. Then learn the transport with the number rather than
after it, because half the exam's port questions are really transport questions.
Then space the repetition out over days rather than massing it into one evening,
which is the single largest effect in the memory literature and the one most
candidates skip.

<details class="deeper">
<summary>If you already work on networks: what this exam quietly dropped, and why every port chart online is wrong for it</summary>

Two protocols that appear on every port chart ever printed are absent from
N10-009 entirely. POP3 on 110 and IMAP on 143 do not appear in the objectives, in
the acronym appendix, or in the ports table.

That is a scope change rather than an oversight. Mail submission is still there
in the form of 25 and 587, so sending mail is examinable. Retrieving it is not.
Somebody at CompTIA looked at what a network technician actually deals with and
concluded that mail retrieval protocols had stopped being one of those things,
which is defensible given how much mail is now read through a browser or a vendor
API.

The practical consequence is about study material rather than about networks.
Every port chart on the internet lists 110 and 143, most of them were written for
an older exam code, and none of them will tell you which entries are no longer
examinable. Time spent drilling ports you will not be asked about is time not
spent on the ones you will.

Knowing them anyway is not wasted, because POP3 and IMAP servers are still very
much running and you will meet them. Prioritising them for this exam is.

The general habit this is an argument for: when a study resource and the
objectives document disagree about scope, the objectives document decides, and it
is free to download. That is worth doing once at the start rather than trusting a
chart that does not say which exam it was written for.

</details>

## The pairs, and the pattern behind them

Several protocols come as a plaintext original and an encrypted counterpart, and
the exam tests the pairing directly. Learned as pairs rather than as ten separate
facts, it is half the work.

| Plaintext | Port | Encrypted | Port |
| --- | --- | --- | --- |
| HTTP | 80 | HTTPS | 443 |
| FTP | 21 | FTPS | 990 |
| Telnet | 23 | SSH | 22 |
| LDAP | 389 | LDAPS | 636 |
| SIP | 5060 | SIP over TLS | 5061 |
| SMTP | 25 | SMTP submission | 587 |

The pattern in most rows is that the encrypted version got a separate port, and
the reason is historical. Adding encryption to a protocol that was already
deployed everywhere was easier to do by putting the encrypted version somewhere
else than by negotiating an upgrade in place. That approach is called implicit
TLS: the connection is encrypted from the first byte, because the port says it
will be.

Two rows break the pattern in different ways.

**Telnet and SSH are not a pair.** SSH is not encrypted Telnet, it is a different
protocol that replaced it and does considerably more, including file transfer and
port forwarding. The exam pairs them because they solve the same problem, and
Telnet's presence on the syllabus is largely so you know not to use it.

**SIP over TLS gets the port after SIP** rather than one far away, which is the
tidy version of the same idea and shows how the convention settled once people
were designing for it rather than retrofitting.

The other approach is to keep one port and upgrade the connection mid-flight,
usually with a `STARTTLS` command. That is opportunistic TLS, it is what SMTP
between mail servers does on port 25, and its weakness is in the name: a
connection that starts in plaintext can be prevented from upgrading by something
in the middle, which then reads everything.

<details class="deeper">
<summary>If you already work on networks: why this exam pairs SMTPS with 587, and what the standards actually say</summary>

This one is worth knowing precisely, because the exam's answer and the standards'
answer are different and you need both.

The exam's ports table pairs Simple Mail Transfer Protocol Secure with port 587.
Answer 587 if asked.

What the standards say is a longer story. Port 587 is the message submission
port, defined by RFC 6409, and its purpose is to separate mail submitted by a
user's client from mail relayed between servers on port 25. That separation
exists so that providers can require authentication on submission without
breaking server to server relay. Submission on 587 historically starts in
plaintext and upgrades with STARTTLS, so it is opportunistic rather than implicit.

Port 465 is where the confusion comes from. It was briefly registered as `smtps`
in the 1990s, that registration was revoked, and the port sat in an unofficial
limbo for two decades while mail software kept using it anyway. RFC 8314 later
assigned it properly under the service name `submissions`, meaning submission
over implicit TLS, which is encryption from the first byte.

So there is a port that means submission with an optional upgrade, 587, and a
port that means submission encrypted from the start, 465. The name SMTPS
historically attached to 465 rather than to 587.

Port 465 does not appear in the N10-009 objectives at all. The capture above
shows Debian's own registry calling 587 `submission`, citing the RFC, and not
using the name SMTPS anywhere.

None of which changes what to write on the exam. It changes what to say when a
colleague asks why the mail client's settings do not match what you were taught,
and it is a reasonable illustration of why this track reads primary documents
rather than trusting a chart.

</details>

## Which transport, and why

The transport column is not arbitrary, and after the previous topic you can
mostly derive it rather than memorising it. A protocol chooses UDP when setting
up a connection would cost more than the exchange itself, or when late data is
worthless, and TCP when the exchange has to be complete and in order.

| Uses UDP | The reason |
| --- | --- |
| DHCP, 67 and 68 | The client has no address yet, so there is nothing to build a connection from |
| DNS, 53, for ordinary queries | One question, one answer, both small. Retrying is cheaper than connecting |
| TFTP, 69 | Deliberately tiny, for devices with almost no software, which is why it is used to boot things |
| SNMP, 161 and 162 | High volume, individually unimportant, and polling must not be slowed by the receiver |
| Syslog, 514 | The same, and a logging system must never block the thing generating logs |
| NTP, 123 | A timestamp that arrived late has been made wrong by arriving late |

Everything moving a file, a session or a page uses TCP, because a page missing
its middle is not a page. SSH, HTTP, HTTPS, SMTP, FTP, SMB, RDP and the database
protocols are all TCP for that reason.

<details class="deeper">
<summary>If you already work on networks: the protocols that use both, and why the exam asks about exactly those</summary>

Three entries in the table say TCP and UDP, and each of them has a different
reason, which is why they make good exam questions.

**DNS, 53.** Queries go over UDP because they are small and cheap to retry. DNS
switches to TCP when a response will not fit in a datagram, and for zone
transfers between servers, which are large and must be complete. So a firewall
that permits UDP 53 and blocks TCP 53 works fine until a response gets large,
which is a fault that appears months after the rule was written and only for
certain names. DNSSEC made responses larger and made this considerably more
common.

**HTTPS, 443.** TCP is the traditional answer. UDP is QUIC carrying HTTP/3,
covered in the previous topic's panel, which is now a large share of web traffic.
A network policy written when 443 meant TCP will silently block HTTP/3, and
because browsers fall back to TCP, the visible symptom is a slight slowdown that
nobody attributes to a firewall rule.

**SIP, 5060.** Either, depending on deployment. UDP has been traditional for call
signalling, TCP is used where messages are large or where reliability is wanted,
and 5061 with TLS is TCP in practice.

There is a fourth case not in the table, and it is a good illustration of the
theme of this topic. Oracle's use of port 1521 is a de facto convention rather
than an assignment. IANA registers 1521 to `ncube-lm`, the nCube License Manager,
and has done since long before Oracle became the thing everybody associates with
the number. The registry records who asked; it does not record who ended up
there.

</details>

## Prove it

You have this when you can recall the table cold and check any entry against a
primary source in under a minute.

The recall half is the work, and there is no command for it. Cover the port
column and name each one, then cover the protocol column and name those, then
cover the transport column, which is the one that will be weakest.

The checking half is one command, on any Unix machine:

```bash
# what your own system thinks a port is called
grep -w 443/tcp /etc/services
grep -w 587/tcp /etc/services

# and the reverse direction, from a name
getent services ssh
getent services domain
```

On Debian and Ubuntu the file arrives with the `netbase` package, and a minimal
container may not have it. When the local file and your memory disagree, IANA's
registry is the authority, and the panels on this page are two cases where it is
worth going and looking.

## What trips people up

### 1. Reading a port number as a guarantee about the traffic

The capture on this page shows a password crossing port 443 in plaintext. The
number says where to deliver a segment. It says nothing about what is there or
whether it is encrypted.

### 2. Forgetting the transport

Half of the exam's port questions are really asking whether a protocol uses TCP
or UDP. Learning the number without the transport gets half of them wrong, and
the transport is the easier half to derive.

### 3. Pairing Telnet with SSH as plaintext and encrypted

SSH replaced Telnet and is a different protocol that does considerably more. The
exam groups them because they solve the same problem, which is not the same as
one being the encrypted form of the other.

### 4. Mixing up DHCP's two ports

The server listens on 67 and the client on 68. The direction that catches people
is that a firewall rule for DHCP needs both, and which one is the source depends
on which way the packet is going.

### 5. Assuming SNMP and its traps share a port

Polling is 161 and traps are 162, and they travel in opposite directions. A rule
permitting 161 lets you query a device and does nothing for the alerts it tries
to send you.

### 6. Trusting a port chart written for an older exam code

POP3 and IMAP are on every chart online and are not in N10-009. The objectives
document is free and it is the only thing that decides what is in scope.

## Work it through

A firewall change request asks for outbound TCP 443 to be opened from a server
network that currently has no internet access at all. The stated reason is
"software updates".

The request is reasonable and the reasoning is worth doing properly, because 443
is the rule people approve without thinking and it is the one that carries the
most.

Start with what is actually being asked for. Outbound 443 from a server network
permits any process on any of those servers to open an encrypted connection to
any host on the internet. Encrypted means the firewall cannot see what is inside
it without terminating the TLS itself. So the request is not "allow software
updates", it is "allow arbitrary outbound encrypted traffic", and those are very
different rules that happen to be written identically.

That does not make it wrong. It makes the scope the thing to negotiate. Two
questions narrow it enormously and neither is difficult. Which destinations?
Update services have published hostnames or address ranges, and a rule scoped to
those is a fraction of the exposure. And which servers? The ones that need
patching, rather than the whole network.

The thing to notice about the original request is that it names a port when the
requirement is about a destination. That is a habit worth pushing back on gently,
because the port is the least informative part of what is being asked for.

If the answer to "which destinations" is that nobody knows, that is useful too.
It means the requirement has not been worked out, and approving a broad rule to
cover an unknown requirement is how server networks end up with unrestricted
outbound access that nobody remembers granting.

## Try it

**Test your recall against your own machine.** Pick ten ports from the table,
write down the protocol and transport from memory, then check each with `grep -w
<port>/tcp /etc/services`. The ones you got wrong are your revision list, and it
will be shorter than you expect.

**Look at what your machine is actually talking to.** Run `ss -tunp` and read the
destination ports. Most will be 443, some will be 53, and anything else is worth
a moment's curiosity. It is a good way to notice that the table is a description
of real traffic rather than a list to be memorised in the abstract.

**Read one registry entry properly.** Open IANA's port registry, search for 1521,
and see what is actually assigned there. The panel above tells you the answer;
seeing it yourself is what makes the point stick about what a registry does and
does not record.

## Check yourself

<details class="qa">
<summary>A firewall permits inbound TCP 443 to a server. What can you conclude about the traffic that rule allows?</summary>

That it is TCP, that it is going to port 443 on that server, and nothing else.

It is not necessarily HTTPS, not necessarily encrypted, and not necessarily a web
request. Port 443 is a convention about where TLS-protected web servers listen,
and nothing in the network enforces it. The capture on this page sends a password
in plaintext across that port.

If you need to know what is crossing the rule, the port number cannot tell you.
Something has to inspect the traffic.

</details>

<details class="qa">
<summary>Which of these use UDP: DNS, SNMP, RDP, TFTP, syslog, SMB?</summary>

DNS, SNMP, TFTP and syslog use UDP. RDP and SMB use TCP.

DNS is the one with a qualification: ordinary queries use UDP, and it switches to
TCP for responses too large for a datagram and for zone transfers, so a firewall
rule needs both.

The reasoning behind the split is worth more than the list. UDP goes to things
that are small, frequent and individually unimportant, or that cannot afford to
wait. TCP goes to anything transferring a file or holding a session, which is
what RDP and SMB both do.

</details>

<details class="qa">
<summary>Somebody moves the SSH service to port 2222 and reports that attacks have stopped. What has actually changed?</summary>

The automated background noise has stopped. The risk has not changed.

Most traffic hitting port 22 from the internet is indiscriminate scanning, and it
does not follow you to another port. So the logs get quiet, which is a real
benefit, because a genuine attempt is much easier to spot against silence.

Anyone specifically interested finds the service in seconds with a port scan, and
an SSH daemon identifies itself by its version banner on whatever port it is
listening on. Nothing about authentication, key management or rate limiting has
improved.

The failure mode to watch for is somebody treating the quiet logs as evidence the
service is now protected.

</details>

<details class="qa">
<summary>This exam pairs SMTPS with port 587. What do the standards call 587, and where did the name SMTPS come from?</summary>

The standards call 587 the message submission port, defined in RFC 6409. Its
purpose is separating mail submitted by a user's client, which can require
authentication, from mail relayed server to server on port 25.

The name SMTPS historically attached to port 465, which was briefly registered as
`smtps`, had that registration revoked, and was later assigned properly by RFC
8314 under the name `submissions`, meaning submission over implicit TLS.

Port 465 does not appear in the N10-009 objectives at all, so 587 is the answer to
give. It is worth knowing that the name and the port do not line up outside the
exam.

</details>

<details class="qa">
<summary>A firewall rule permits UDP 53 outbound and blocks TCP 53. What works, and what breaks, and when will anybody notice?</summary>

Ordinary DNS queries work, because they fit in a UDP datagram and that is how
they are sent.

What breaks is any response too large for a datagram, which falls back to TCP.
DNSSEC-signed responses, records with many entries, and zone transfers all hit
this. So a small number of names fail to resolve while everything else is fine.

Nobody notices for a long time, and when they do, the symptom is a specific site
failing rather than DNS being broken, which points the investigation almost
anywhere except at the firewall rule.

</details>

<details class="qa">
<summary>Why is a port number a poor basis for an egress filtering policy, and what does that imply about port 443?</summary>

Because nothing binds a service to its conventional port. Any program can listen
on any port, and any client can connect to any port.

Port 443 is the sharpest case. It has to be open outbound in almost every
network, because closing it breaks the web, and the traffic on it is encrypted so
a firewall cannot see inside without terminating the TLS. Anything wanting to
leave a network without attracting attention uses it for exactly those reasons.

The implication is that a policy which allows and denies by number is making a
statement about destinations and nothing more. Filtering that actually restricts
what leaves has to inspect traffic or restrict destinations, and both cost more
than writing a port number in a rule.

</details>

## References

- [Service Name and Transport Protocol Port Number Registry](https://www.iana.org/assignments/service-names-port-numbers/service-names-port-numbers.xhtml) - IANA, the source for every port number in the table on this page. Accessed 2026-08-10.
- [RFC 6409, Message Submission for Mail](https://www.rfc-editor.org/rfc/rfc6409) - IETF, which defines port 587 as the submission port. Accessed 2026-08-10.
- [RFC 8314, Cleartext Considered Obsolete](https://www.rfc-editor.org/rfc/rfc8314) - IETF, which assigns 465 the service name `submissions`. Accessed 2026-08-10.
- [RFC 9293, Transmission Control Protocol](https://www.rfc-editor.org/rfc/rfc9293) - IETF. Accessed 2026-08-10.
- [services(5)](https://man7.org/linux/man-pages/man5/services.5.html) - Linux man-pages project, on the local registry file. Accessed 2026-08-10.

**Where the output came from.** The plaintext block on port 443 was captured on
the one-router namespace topology, `blog/scripts/topologies/one-router.sh`,
through `blog/scripts/netlab.sh`. The `/etc/services` block came from a Debian 13
container through `blog/scripts/capture.sh`, and the command includes the
`netbase` install because a minimal Debian image does not ship the file. The port
table was assembled from IANA's registry rather than from any study guide, which
is why it disagrees with several charts about port 1521 and why the panel says so
explicitly.

**If you also work on Linux.** [Common network services](/learn/linux-plus/32-common-network-services)
on the Linux+ track covers several of these protocols from the point of view of
running them, with the configuration and the verification for each. This page is
the recall list; that one is the operation.
