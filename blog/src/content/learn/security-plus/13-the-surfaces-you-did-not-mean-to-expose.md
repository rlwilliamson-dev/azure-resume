---
title: "The surfaces you did not mean to expose"
description: "Why an estate's attack surface grows by accretion rather than by decision, what a service that asks for nothing will tell a stranger, what unsupported actually changes on the day it happens, and how a supplier becomes part of your surface."
deck: "A port is open on a server because a contractor needed it for an afternoon in 2019"
track: "security-plus"
level: "working"
order: 140
objectives:
  - "Explain why attack surface accumulates without anybody deciding to expose anything"
  - "Say what a default configuration exposes and to whom"
  - "Compare agent-based and agentless discovery by what each one misses"
  - "Say what changes on the day a system becomes unsupported"
  - "Describe how a supplier becomes part of your attack surface"
  - "Count a machine's listening surface on three platforms"
prerequisites: ["how-a-message-becomes-a-vector"]
tags: ["security-plus", "security", "threats"]
updated: 2026-08-26
draft: false
examObjectives:
  - exam: "sy0-701"
    domain: "2.0"
    objective: "2.2"
sources:
  - title: "SP 800-115, Technical Guide to Information Security Testing and Assessment"
    url: "https://csrc.nist.gov/pubs/sp/800/115/final"
    publisher: "NIST"
    accessed: 2026-08-26
    tier: 1
  - title: "SP 800-161 Rev. 1, Cybersecurity Supply Chain Risk Management Practices"
    url: "https://csrc.nist.gov/pubs/sp/800/161/r1/upd1/final"
    publisher: "NIST"
    accessed: 2026-08-26
    tier: 1
  - title: "memcached security documentation"
    url: "https://github.com/memcached/memcached/wiki/ConfiguringServer"
    publisher: "memcached project"
    accessed: 2026-08-26
    tier: 1
  - title: "ss manual page"
    url: "https://man7.org/linux/man-pages/man8/ss.8.html"
    publisher: "man7.org"
    accessed: 2026-08-26
    tier: 1
symptoms:
  - symptom: "A port is open and nobody can say why"
    anchor: "nobody-exposed-this-it-accumulated"
  - symptom: "A service answers questions from anybody who asks"
    anchor: "the-service-that-asks-for-nothing"
---

> **Before you read.** A scan finds an open port on a production server. It has
> been open since 2019, when a contractor needed it for an afternoon. The
> contractor left, the project ended, and the port stayed.
>
> **Who exposed that service?**

Nobody, which is the point. Attack surface is not usually created by a decision to
expose something. It accumulates, one reasonable act at a time, and the thing
missing from every one of those acts is a step that removes anything.

### Some words you will need

<dl class="terms">
<dt>attack surface</dt>
<dd>Everything reachable that could be attacked. Ports, interfaces, accounts, dependencies, people.</dd>
<dt>accretion</dt>
<dd>Growth by accumulation rather than by design. How most surfaces get large.</dd>
<dt>default credential</dt>
<dd>A username and password that shipped with the product and is documented publicly.</dd>
<dt>unauthenticated service</dt>
<dd>One that answers without asking who you are. Worse than a default credential, and common.</dd>
<dt>agent-based discovery</dt>
<dd>Software on the machine reporting what is there.</dd>
<dt>agentless discovery</dt>
<dd>Finding things from outside, by asking the network.</dd>
<dt>unsupported</dt>
<dd>The vendor no longer issues fixes. The software does not change; the risk does.</dd>
<dt>supply chain</dt>
<dd>Everyone whose work ends up inside yours: suppliers, vendors, managed providers.</dd>
</dl>

## What breaks without this

**A port is open and nobody owns it.** Removing it feels risky because nobody knows
what would break, so it stays for another six years.

**A service answers strangers.** It was never configured to require anything,
because the default did not, and nobody checked what the default was.

**Discovery misses half the estate.** Agent-based scanning covers what has an agent
and agentless covers what answers the network, and the systems that fall between
them are the ones nobody manages.

**A supplier's compromise becomes yours.** They had a management route into your
network, which was agreed years ago and never reviewed.

## Nobody exposed this. It accumulated

<figure class="learn-figure">
<svg viewBox="0 0 720 300" role="img" aria-labelledby="acc-title" style="width:100%;height:auto;">
<title id="acc-title">Six years of one server, with each opening added for a reason at the time and none of them removed afterwards</title>
<g fill="currentColor">
<text x="14" y="20" font-size="11">nobody exposed this server. it accumulated</text>
<text x="14" y="64" font-size="9" fill-opacity="0.8">2019</text>
<rect x="62" y="46" width="304" height="28" rx="4" fill="currentColor" fill-opacity="0.05" stroke="currentColor" stroke-opacity="0.5" stroke-width="1.1"/>
<text x="74" y="64" font-size="8">a contractor needs a cache for one afternoon</text>
<rect x="378" y="46" width="322" height="28" rx="4" fill="var(--red)" fill-opacity="0.13" stroke="var(--red)" stroke-opacity="0.7" stroke-width="1.2"/>
<text x="390" y="64" font-size="8">memcached on 0.0.0.0:11211</text>
<text x="14" y="100" font-size="9" fill-opacity="0.8">2020</text>
<rect x="62" y="82" width="304" height="28" rx="4" fill="currentColor" fill-opacity="0.05" stroke="currentColor" stroke-opacity="0.5" stroke-width="1.1"/>
<text x="74" y="100" font-size="8">the web server goes in</text>
<rect x="378" y="82" width="322" height="28" rx="4" fill="var(--accent)" fill-opacity="0.13" stroke="var(--accent)" stroke-opacity="0.7" stroke-width="1.2"/>
<text x="390" y="100" font-size="8">port 80, intended</text>
<text x="14" y="136" font-size="9" fill-opacity="0.8">2021</text>
<rect x="62" y="118" width="304" height="28" rx="4" fill="currentColor" fill-opacity="0.05" stroke="currentColor" stroke-opacity="0.5" stroke-width="1.1"/>
<text x="74" y="136" font-size="8">a monitoring agent is added</text>
<rect x="378" y="118" width="322" height="28" rx="4" fill="var(--red)" fill-opacity="0.13" stroke="var(--red)" stroke-opacity="0.7" stroke-width="1.2"/>
<text x="390" y="136" font-size="8">port 9100, forgotten</text>
<text x="14" y="172" font-size="9" fill-opacity="0.8">2022</text>
<rect x="62" y="154" width="304" height="28" rx="4" fill="currentColor" fill-opacity="0.05" stroke="currentColor" stroke-opacity="0.5" stroke-width="1.1"/>
<text x="74" y="172" font-size="8">a supplier is given a management route</text>
<rect x="378" y="154" width="322" height="28" rx="4" fill="var(--red)" fill-opacity="0.13" stroke="var(--red)" stroke-opacity="0.7" stroke-width="1.2"/>
<text x="390" y="172" font-size="8">a VPN account, still active</text>
<text x="14" y="208" font-size="9" fill-opacity="0.8">2024</text>
<rect x="62" y="190" width="304" height="28" rx="4" fill="currentColor" fill-opacity="0.05" stroke="currentColor" stroke-opacity="0.5" stroke-width="1.1"/>
<text x="74" y="208" font-size="8">the operating system reaches end of life</text>
<rect x="378" y="190" width="322" height="28" rx="4" fill="var(--red)" fill-opacity="0.13" stroke="var(--red)" stroke-opacity="0.7" stroke-width="1.2"/>
<text x="390" y="208" font-size="8">nothing changes, and everything does</text>
<text x="14" y="244" font-size="9" fill-opacity="0.8">2026</text>
<rect x="62" y="226" width="304" height="28" rx="4" fill="currentColor" fill-opacity="0.05" stroke="currentColor" stroke-opacity="0.5" stroke-width="1.1"/>
<text x="74" y="244" font-size="8">somebody asks what is exposed</text>
<rect x="378" y="226" width="322" height="28" rx="4" fill="var(--accent)" fill-opacity="0.13" stroke="var(--accent)" stroke-opacity="0.7" stroke-width="1.2"/>
<text x="390" y="244" font-size="8">four openings, one intended</text>
<path d="M 40 42 V 258" stroke="currentColor" stroke-opacity="0.3" stroke-width="1.2"/>
<text x="14" y="282" font-size="10" fill-opacity="0.85">every line was somebody solving a problem, and every decision was reasonable</text>
<text x="14" y="298" font-size="9" fill-opacity="0.7">what is missing from this timeline is any event that removes something</text>
</g></svg>
<figcaption>Six years of one server. Every entry on the left was somebody solving a real problem, approved at the time, and correct on the day. The right column is what each act left behind, and four of the five are still there. What the timeline has no room for, because it never happened, is an event that removes something: no line saying the contractor's port was closed when the project ended, or that the monitoring agent was uninstalled when the monitoring changed. Attack surface accumulates because addition has an owner and a business reason and removal has neither.</figcaption>
</figure>

Here is the accumulation in miniature, on one machine, in one command.

```bash
# AlmaLinux 10.2, x86_64
$ dnf -q -y install iproute >/dev/null 2>&1; count() { ss -ltn 2>/dev/null | tail -n +2 | wc -l; }; echo "a base image, before anybody asks for anything:"; count; echo "somebody needs a web server:"; dnf -q -y install nginx >/dev/null 2>&1; nginx 2>/dev/null; sleep 1; count; echo "and a cache, for one afternoon in 2019:"; dnf -q -y install memcached >/dev/null 2>&1; memcached -u nobody -d -l 0.0.0.0 2>/dev/null; sleep 1; count; echo; echo "what is listening now, and on which addresses:"; ss -ltn 2>/dev/null | tail -n +2 | awk "{print \$4}" | sort -u
a base image, before anybody asks for anything:
0
somebody needs a web server:
2
and a cache, for one afternoon in 2019:
3

what is listening now, and on which addresses:
*:80
0.0.0.0:11211
0.0.0.0:80
```

**Zero, then two, then three**, and the third is a cache somebody wanted for an
afternoon. Nothing in that sequence is unusual and every step had a reason.

Notice the addresses in the last block. The web server listens on port 80, which is
what a web server is for. The cache listens on `0.0.0.0:11211`, which means every
interface on the machine, which means anything that can route to it.

<details class="deeper">
<summary>If you inherit an estate: how to remove an opening nobody can explain, without breaking something</summary>

The reason the 2019 port is still open is not laziness. It is that nobody can say
what would break, and the cost of being wrong lands on whoever removed it. That
asymmetry keeps every unexplained opening open indefinitely, and it is fixable by
changing what the removal costs rather than by exhorting anybody.

The sequence that works is the same as the firewall rules in block E, for the same
reason. Log rather than remove. Turn the opening into one that records every
connection, wait a full business cycle including whatever the longest periodic job
is, and look at what actually used it.

Three outcomes and all are useful. Nothing used it, which converts removal from a
guess into a documented fact and makes it approvable. Something used it and can be
identified, which turns an unexplained opening into a known dependency with an
owner. Or something used it and cannot be identified, which is itself a finding
worth pursuing, because unattributable traffic to a forgotten service is exactly
what an investigation would want to know about.

Two practical details. Make the removal reversible in minutes and say so when
proposing it, because the objection is almost always about risk rather than about
the port. And do the observation on several machines at once rather than one, since
the effort is the same and the result is a pattern rather than an anecdote.

The organisational fix is smaller than it sounds: attach an expiry to temporary
access when it is granted. A firewall rule created for a contractor with a date on
it becomes somebody's problem automatically, and the alternative is that it becomes
nobody's problem permanently.

</details>

## The service that asks for nothing

Default credentials are in the objective and they are the easier half of the
problem. The harder half is services that do not have credentials at all.

<details class="predict">
<summary>A cache is listening on every interface. Predict what it requires before answering a question from a stranger.</summary>

```bash
# AlmaLinux 10.2, x86_64
$ dnf -q -y install memcached nmap-ncat iproute >/dev/null 2>&1; memcached -u nobody -d -l 0.0.0.0 2>/dev/null; sleep 1; echo "the service, as it starts by default:"; ss -ltn 2>/dev/null | grep 11211; echo; echo "what it asks for before answering:"; printf "version\r\n" | timeout 3 nc 127.0.0.1 11211 | head -2; echo; echo "lines of statistics it returns to a caller that supplied nothing:"; printf "stats\r\n" | timeout 3 nc 127.0.0.1 11211 | wc -l
the service, as it starts by default:
LISTEN 0      0            0.0.0.0:11211      0.0.0.0:*   

what it asks for before answering:
VERSION 1.6.23

lines of statistics it returns to a caller that supplied nothing:
93
```

**Nothing whatsoever.** It answered a version request immediately and returned
ninety-three lines of statistics to a caller that supplied no credential, because
there is no credential to supply.

This is a different problem from a default password and in some ways a worse one.
A default password is at least a control that somebody failed to configure, and
scanning for it finds a fixable misconfiguration. A service with no authentication
mechanism is working exactly as designed, and the design assumed it would only ever
be reachable from a trusted network.

That assumption is the whole thing. Plenty of infrastructure software makes it:
caches, message queues, search indexes, metrics endpoints, container APIs. Every
one is correct on a loopback interface and dangerous on `0.0.0.0`, and the
difference is one line of configuration that frequently defaults to the wrong one.

The statistics themselves are worth noticing too. Ninety-three lines is not a
version banner: it is uptime, connection counts, memory in use, and how many items
are stored. That is reconnaissance handed over on request, before anybody attempts
anything, and it costs the caller one connection.

The check worth running against your own estate is not for weak passwords. It is
for services bound to every address that were designed for a trusted one, and the
listening list is where you find them.

</details>

<details class="deeper">
<summary>If you run discovery: what agent-based finds that agentless does not, and the reverse</summary>

The two approaches see different estates, and an organisation using one will have
a blind spot shaped like the other.

**Agent-based discovery** reports from inside. It sees installed software including
what is never started, local accounts, configuration, scheduled tasks, and the full
package inventory. What it cannot see is anything without an agent, and the list of
things without an agent is the list from block E: appliances, printers, industrial
controllers, embedded systems, and any machine somebody stood up without going
through the build process. Those are frequently the least defended things you own.

**Agentless discovery** finds whatever answers. It sees the machine somebody built
last week without telling anybody, the appliance, the device in a cupboard. What it
cannot see is anything that does not answer, which includes a machine that is
firewalled from the scanner, a laptop that was not on the network that night, and
everything about a system's inside.

The systems that fall between them are the interesting ones. A device with no agent
that also does not answer the scanner is absent from both inventories, and the way
it eventually surfaces is a network flow to somewhere unexpected or an invoice.

The practical arrangement is both, plus a third source that is neither: the
purchasing record. Every asset was paid for by somebody, and reconciling the two
technical inventories against finance's list of what was bought is what closes the
gap. That is a tedious afternoon and it is the only method that finds the thing
which answers nothing and runs nothing you recognise.

</details>

## Unsupported changes the risk, not the code

A system becomes unsupported on a date announced years in advance. Nothing about
the software changes that day. The binaries are identical, the configuration is
identical, and it does exactly what it did the day before.

**What changes is that the flow of fixes stops.** Every vulnerability discovered
after that date is permanent for you. The risk therefore does not jump on the day;
it begins increasing on the day, and it never comes back down.

That distinction matters for how you argue about it. An unsupported system is not
suddenly dangerous, which is why the "it works fine" response is honest rather than
obtuse. It is a system whose risk has an upward slope and no ceiling, and the
question is not whether it is safe now but what the position looks like in two
years.

**Two practical consequences.** The first is that risk registers frequently record
unsupported systems as a single finding with a static score, which is wrong in a
way that gets worse quietly. The second is that compensating controls are the
realistic answer for anything that cannot be replaced: reduce what can reach it,
watch what it does, and record the arrangement as an exception with an owner and a
date, because it is one.

<details class="deeper">
<summary>If you are arguing for a replacement: the framing that works, and the number to bring</summary>

The argument for replacing an unsupported system is usually made as a risk
argument and usually loses, because the person hearing it has a working system, a
budget, and no visible problem.

The framing that works better is about the slope rather than the level. The
question is not whether the system is safe, which is arguable and which the other
person will win. It is what the organisation's position will be when a serious
vulnerability is published for it, which is not a question of whether but of when,
and the answer is that there will be no patch and the options will be the
compensating controls you could build now under less pressure.

The number to bring is the count of vulnerabilities published for that product
since its support ended, which is public and takes an hour to assemble. It is a
line going up, it has no relationship to anybody's opinion, and it makes the
slope concrete in a way a risk rating does not.

The second number worth having is the exposure: what can reach this system today,
and what could an attacker reach from it. That converts an abstract discussion into
a specific one about a specific machine, and it frequently reveals that the
cheapest immediate action is not replacement at all but segmentation.

The concession worth making early, because it builds the case rather than
weakening it: agree that the system works, agree that replacing it is expensive,
and agree that doing nothing this year is a defensible choice. Then ask for the
decision to be recorded as an acceptance with a review date, which is the risk
topic's machinery applied here. Organisations that will not fund a replacement will
usually sign an acceptance, and the acceptance is what brings the question back
next year instead of never.

</details>

## The supplier is part of your surface

The objective lists supply chain as a vector alongside ports and protocols, and the
placement is deliberate: a supplier is an opening in the same sense a port is.

**A managed service provider has administrative access to your estate**, by design,
because that is what you engaged them for. Their compromise is your compromise, and
the route arrives with valid credentials through an approved channel.

**A vendor's software runs inside your systems**, updates itself, and is trusted to.
That is topic 17's subject and it belongs here as a category.

**A supplier with a network route** is the case people forget. A management VPN
agreed for a project in 2021, still active, still permitted, with an account list
neither party has reviewed.

The question worth asking about each supplier relationship is the same one as the
screened subnet in block E: if this supplier were fully compromised tomorrow, what
could reach us, and would anybody notice? That is answerable from your own
configuration without asking them anything, and the answer is frequently more than
anybody expects.

<details class="deeper">
<summary>If you assess suppliers: why the questionnaire does not work, and the two things that do</summary>

Supplier security assessment is usually a questionnaire, and the questionnaire is a
poor instrument for a specific reason: it asks the supplier to describe themselves,
and the answers are written by somebody whose job is to win the contract.

That is not an accusation of dishonesty. It is that a two hundred question form is
answered by the person best placed to answer it optimistically, reviewed by nobody
technical on either side, and filed. Its value is contractual rather than
informational: it establishes what was claimed, which matters afterwards.

Two things work better and both are cheap.

**Assess your own exposure rather than their posture.** What access do they have,
what could it reach, and what would we see if it were used at three in the morning?
Those are answerable from your configuration, they do not require the supplier's
cooperation, and they are the questions that determine your actual risk. A supplier
with excellent security and administrative access to everything is a larger
exposure than one with mediocre security and access to a single system.

**Ask for evidence rather than assertions.** Not whether they have a vulnerability
management programme, but their most recent penetration test report and what they
did about the findings. Not whether they encrypt data, but which systems and which
of their staff can decrypt. The answers are shorter, harder to write optimistically,
and more informative.

The third thing, which is not an assessment technique but does more than either: put
an expiry on the access. A supplier route that has to be renewed annually gets
looked at annually, and one that does not, does not.

</details>

## Across platforms

Counting what is listening is the same question everywhere and the three answers
start from very different places.

| Task | Linux | Windows | macOS |
| --- | --- | --- | --- |
| Count listening sockets | `ss -ltn` | `Get-NetTCPConnection -State Listen` | `lsof -nP -iTCP -sTCP:LISTEN` |
| Baseline on a fresh machine | 0 on a minimal image | 23 unique ports | 4 sockets |
| Bound to every address | whatever you configured | 16 of them | 1 |
| Default inbound firewall action | the chain policy | per profile, unset here | the packet filter is off |

```powershell
# Microsoft Windows Server 2025 Datacenter, version 10.0.26100.0
> (Get-NetTCPConnection -State Listen | Select-Object -Unique LocalPort | Measure-Object).Count
23

# How many of those belong to a process somebody installed, against the system itself
> Get-NetTCPConnection -State Listen | Select-Object -Unique LocalPort, OwningProcess | ForEach-Object { (Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue).ProcessName } | Group-Object | Sort-Object Count -Descending | Select-Object -First 5 Count, Name | Format-Table -AutoSize
Count Name
----- ----
    6 System
    5 mqsvc
    5 svchost
    1 dockerd
    1 lsass

# Whether any of them is reachable from anywhere rather than from this machine
> Get-NetTCPConnection -State Listen | Where-Object { $_.LocalAddress -eq '0.0.0.0' } | Select-Object -Unique LocalPort | Measure-Object | Select-Object -ExpandProperty Count
16

# And what the firewall would do about a connection to one of them
> (Get-NetFirewallProfile | Where-Object { $_.Name -eq 'Public' }).DefaultInboundAction
NotConfigured
```


# provenance: Microsoft Windows Server 2025 Datacenter, version 10.0.26100.0, runner image 20260818.207.1

**Twenty-three listening ports before anybody installs anything, and sixteen of
them bound to every address.** That is the baseline, and it is why a minimal Linux
image and a Windows Server are not comparable by port count: the ports are roles
that ship enabled rather than software somebody chose.

The last line is the one that matters operationally. The public profile's default
inbound action reports `NotConfigured`, which is not the same as permitting
everything, and it means the effective behaviour comes from the rules rather than
from a stated default. That is a harder thing to reason about than a policy line
saying drop.

```bash
# macOS 26.5.2, arm64
$ sudo lsof -nP -iTCP -sTCP:LISTEN 2>/dev/null | tail -n +2 | wc -l | tr -d ' '
4

# Which processes hold them, which on this platform is mostly one answer
$ sudo lsof -nP -iTCP -sTCP:LISTEN 2>/dev/null | tail -n +2 | awk '{print $1}' | sort | uniq -c | sort -rn | head -4
   4 launchd

# How many are bound to every address rather than to loopback
$ sudo lsof -nP -iTCP -sTCP:LISTEN 2>/dev/null | awk '$9 ~ /^\*:/ {print $9}' | sort -u | wc -l | tr -d ' '
1

# And whether the packet filter would do anything about a connection to one
$ sudo pfctl -s info 2>&1 | head -3 | tail -1
Status: Disabled                              Debug: Urgent
```

**Four sockets, all held by `launchd`, one bound to every address.** The smallest
of the three baselines by a wide margin, for the reason from block E: `launchd`
holds the socket and starts the real service on demand, so the count reflects
configured services rather than running ones.

And the packet filter is disabled, which is the default. So the machine has a small
surface and nothing filtering it, where the Windows machine has a large surface
with rules in front of it. Neither is straightforwardly better and the comparison
is the useful part: an attack surface number means nothing without knowing what is
in front of it.
<details class="predict">
<summary>A fresh Windows Server and a minimal Linux image are compared by open port count. Predict the numbers, and whether the comparison means anything.</summary>

**Twenty-three against zero, and the comparison means very little.**

The numbers are real and they are measuring different things. The Linux image is
a minimal userland with no services configured, so nothing listens until somebody
installs something, and the count rises one service at a time as the earlier
capture shows. The Windows count is roles that ship enabled: remote management,
name resolution, file sharing, and the remote procedure call infrastructure those
depend on.

So a low number does not mean a hardened machine and a high one does not mean a
neglected one. What each number tells you is the shape of the default, and the two
platforms make opposite choices: one ships with nothing and expects you to add,
the other ships functional and expects you to remove.

The comparison that does mean something has two more columns. How many are bound
to every address rather than to loopback, because a service listening only on
loopback is not reachable from anywhere else. And what is in front of them, since
the Windows machine in the capture has rules and the Mac has a packet filter that
is switched off.

The habit worth carrying: never quote an attack surface number without saying what
is filtering it. A count on its own is a measurement of one variable in a system
with at least three, and it is the variable people report because it is the easy
one.

</details>


## Prove it

**Run it.** `ss -ltn` on any Linux machine you own, or the equivalent above. Count
the lines, then try to name what each one is for. The gap between the count and the
names is the finding.

**Work it out.** Take the timeline in the figure and write the equivalent for a
system you actually run. Note the date of each opening and whether an event
anywhere in the history removed one.

**Look it up.** Open SP 800-161 and find what it says about supplier access. The
framing it uses is about your own controls rather than about the supplier's, which
is the point this topic makes about questionnaires.

## What trips people up

### 1. Looking for who exposed something

Usually nobody did. Each opening was added for a reason by somebody with authority,
and what is missing is any process that removes one.

### 2. Scanning for default passwords and stopping there

A service with no authentication at all is working as designed and is worse. The
check to run is for services bound to every address that assumed a trusted network.

### 3. Trusting one discovery method

Agent-based sees inside what has an agent. Agentless sees whatever answers. The
systems in neither inventory are the ones nobody manages, and finance's payment
record is what finds them.

### 4. Treating end of support as a step change in danger

Nothing about the software changes that day. What changes is that the risk starts
rising and never comes back down, which is an argument about slope rather than
level.

### 5. Assessing suppliers by questionnaire

It records what was claimed, which has contractual value. What determines your risk
is your own exposure to them, and that is answerable without asking them anything.

### 6. Comparing platforms by port count

Twenty-three on Windows and four on macOS are not the same measurement. One counts
roles that ship enabled and the other counts sockets held by a launcher, and
neither number means anything without knowing what filters them.

## Work it through

An external scan of your estate returns forty open ports across twelve hosts.
Nobody can account for eleven of them. You have been asked to clean it up.

**The tempting move is to close the eleven.** They are unaccounted for, the scan
report is a list of findings, and closing them is what the report implies. It will
also break something, because at least one of those eleven is load-bearing for a
process nobody documented, and the breakage will arrive as an urgent ticket that
reverses the change and stalls the project.

**The move that works logs before it closes.** Turn each unexplained port into one
that records connections, wait a full business cycle, and read what used it. That
converts eleven guesses into a smaller number of documented removals and a short
list of newly discovered dependencies with owners.

**Then the finding worth escalating is not the ports.** It is that eleven of forty
openings had no owner, which is a process gap rather than a configuration one, and
the fix is an expiry on temporary access rather than a cleanup.

**What this rejects is the cleanup as the deliverable.** Closing eleven ports
returns the estate to a state that will accumulate again at the same rate, and the
same report will be produced in three years by somebody else.

The residual worth naming: a business cycle is a month for most organisations and
misses anything annual. Ports still showing nothing after the observation carry a
real if small chance of being used once a year, which is why the first action is
logging rather than deletion, and why the change should be reversible in minutes.

## Try it

**Count your own.** Run the listening-socket command for your platform and count.
Then, for each entry, write one sentence saying what it is for. The ones you cannot
finish are the topic of this page.

**Find something bound to everything.** Look for `0.0.0.0` or `*` in the local
address column. Each one is reachable from anywhere that can route to the machine,
and at least one will surprise you.

**Ask a service what it wants.** For any internal service you run, connect to it
and see what it asks for before answering. Do this only on machines you own.

**Check one supplier's access.** Pick a supplier with a route into your network and
find out what it can reach and when it was last reviewed.

## Check yourself

<details class="qa">
<summary>Why does attack surface accumulate rather than being decided?</summary>

Because addition has an owner and a business reason and removal has neither. Every
opening was created by somebody solving a real problem with approval at the time,
and no process step exists that closes one when the reason ends.

The organisational fix is an expiry on temporary access at the moment it is
granted, which makes the removal somebody's problem automatically instead of
nobody's problem permanently.

</details>

<details class="qa">
<summary>What is worse than a default credential, and why?</summary>

A service with no authentication at all. A default password is a control somebody
failed to configure, which a scan finds and a change fixes. A service with no
credential mechanism is working exactly as designed.

The design assumed a trusted network, and the difference between correct and
dangerous is one configuration line binding it to loopback rather than to every
address. The capture on this page shows one returning ninety-three lines of
statistics to a caller that supplied nothing.

</details>

<details class="qa">
<summary>What does agent-based discovery see that agentless does not, and the reverse?</summary>

An agent sees inside: installed software that never runs, local accounts,
configuration, scheduled tasks. It cannot see anything without an agent, which is
appliances, printers, controllers and machines built outside the process.

Agentless discovery finds whatever answers the network, including things nobody
registered. It cannot see anything that does not answer, or anything about a
system's inside. What falls between them is found by reconciling both against
finance's record of what was purchased.

</details>

<details class="qa">
<summary>What changes on the day a system becomes unsupported?</summary>

Not the software, which is byte for byte what it was the day before. What changes
is that the supply of fixes stops, so every vulnerability discovered from that
point is permanent.

The risk therefore does not jump, it acquires an upward slope with no ceiling.
That is why a risk register entry with a static score is wrong in a way that gets
worse quietly, and why the argument for replacement is about the slope rather than
about today's safety.

</details>

<details class="qa">
<summary>Why is a supplier questionnaire a poor assessment instrument, and what is better?</summary>

Because it asks the supplier to describe themselves, and the description is written
by somebody whose job is to win the contract, reviewed by nobody technical on
either side. Its value is contractual: it records what was claimed.

Better: assess your own exposure rather than their posture, which needs no
cooperation from them, and ask for evidence rather than assertions. Best of all,
put an expiry on their access, because a route that must be renewed annually gets
looked at annually.

</details>

## References

- [SP 800-115](https://csrc.nist.gov/pubs/sp/800/115/final) - NIST, testing and assessment, for discovery techniques and what each one covers. Free. Accessed 2026-08-26.
- [SP 800-161 Rev. 1](https://csrc.nist.gov/pubs/sp/800/161/r1/upd1/final) - NIST, supply chain risk management, for supplier access as part of your own surface. Free. Accessed 2026-08-26.
- [memcached server configuration](https://github.com/memcached/memcached/wiki/ConfiguringServer) - the project's own documentation on binding and on what it assumes about the network. Free. Accessed 2026-08-26.
- [ss(8)](https://man7.org/linux/man-pages/man8/ss.8.html) - the listening-socket query the Linux captures use. Free. Accessed 2026-08-26.

**Where the content came from.** Both Linux blocks are captured from an AlmaLinux
10.2 container, with the services installed and started during the capture, and the
cache queried over loopback on the same machine that started it seconds earlier.
Nothing is scanned, probed or enumerated that this project does not own. The
Windows and macOS blocks are from disposable runners. The timeline in the figure is
an illustration of the accretion pattern rather than a record of a specific estate,
and the dates in it are chosen to make the shape legible.

**If you also work on Linux.** The Linux+ track's
[hardening a system](/learn/linux-plus/hardening-a-system) covers removing the
services this topic counts, and
[common network services](/learn/linux-plus/common-network-services) covers what
each of them is for.
