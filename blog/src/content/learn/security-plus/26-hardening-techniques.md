---
title: "Hardening techniques"
description: "Ten listening sockets from five services, three ways of closing a port that leave three different machines, and what a fresh Windows and a fresh macOS already have switched on before anybody touches them."
deck: "Five services are running, ten sockets are listening, and you asked for one of them"
track: "security-plus"
level: "working"
order: 270
objectives:
  - "Count a machine's listening surface rather than describing it"
  - "Distinguish blocking a port, stopping a service and removing the software"
  - "Say why removing software is worth more than blocking it"
  - "Explain how to constrain a port that has to stay open"
  - "Distinguish host-based intrusion prevention from endpoint protection"
  - "Give an order for the hardening techniques and say what each costs in support"
prerequisites: ["patching-encryption-monitoring-and-configuration-enforcement"]
tags: ["security-plus", "security", "mitigation", "hardening"]
updated: 2026-08-26
draft: false
examObjectives:
  - exam: "sy0-701"
    domain: "2.0"
    objective: "2.5"
sources:
  - title: "SP 800-123, Guide to General Server Security"
    url: "https://csrc.nist.gov/pubs/sp/800/123/final"
    publisher: "NIST"
    accessed: 2026-08-26
    tier: 1
  - title: "SP 800-83 Rev. 1, Guide to Malware Incident Prevention and Handling for Desktops and Laptops"
    url: "https://csrc.nist.gov/pubs/sp/800/83/r1/final"
    publisher: "NIST"
    accessed: 2026-08-26
    tier: 1
  - title: "M1042, Disable or Remove Feature or Program"
    url: "https://attack.mitre.org/mitigations/M1042/"
    publisher: "MITRE"
    accessed: 2026-08-26
    tier: 1
  - title: "M1050, Exploit Protection"
    url: "https://attack.mitre.org/mitigations/M1050/"
    publisher: "MITRE"
    accessed: 2026-08-26
    tier: 1
symptoms:
  - symptom: "A machine is listening on ports nobody asked for"
    anchor: "counting-the-surface-rather-than-describing-it"
  - symptom: "A service must be reachable and cannot be turned off"
    anchor: "the-port-that-has-to-stay-open"
---

> **Before you read.** You are handed a server built yesterday. Its purpose is to
> run one application. You run the command that lists what is listening and get
> back ten sockets belonging to five different programs.
>
> **Which of the nine do you turn off, and how?**

The interesting half of that question is the "how", because there are at least
three ways to close a port and they are not interchangeable. One leaves the
service running and unreachable from the network. One leaves the software
installed and startable. One leaves nothing. The exam treats them as a list of
techniques; an operator has to know what each one leaves behind, because that is
what an attacker inherits.

### Some words you will need

<dl class="terms">
<dt>attack surface</dt>
<dd>Everything reachable that could be made to do something. Countable, not a feeling.</dd>
<dt>host-based firewall</dt>
<dd>A filter running on the machine it protects, deciding what may reach its own sockets.</dd>
<dt>host-based intrusion prevention</dt>
<dd>Something on the machine that watches behaviour and blocks it, rather than filtering packets.</dd>
<dt>endpoint protection</dt>
<dd>Software that identifies malicious files and activity on a host and acts on them.</dd>
<dt>listening socket</dt>
<dd>A program waiting for connections on a port. The unit an attack surface is counted in.</dd>
<dt>default credentials</dt>
<dd>The username and password something shipped with, which are published.</dd>
<dt>bind address</dt>
<dd>Which addresses a service will accept connections on. Frequently all of them by accident.</dd>
</dl>

## Counting the surface rather than describing it

Attack surface is usually discussed as a quantity nobody has measured. It takes one
command to measure, and the measurement is more useful than the discussion.

<details class="predict">
<summary>Five ordinary services on one machine. Predict how many listening sockets they produce, and what is left after closing three of them three different ways.</summary>

```bash
# AlmaLinux 10.2, aarch64
$ surface
a machine with five ordinary services running:
  21     tcp  *:21                 vsftpd
  22     tcp  0.0.0.0:22           sshd
  22     tcp  [::]:22              sshd
  80     tcp  *:80                 httpd
  111    tcp  0.0.0.0:111          rpcbind
  111    tcp  [::]:111             rpcbind
  111    udp  0.0.0.0:111          rpcbind
  111    udp  [::]:111             rpcbind
  323    udp  127.0.0.1:323        chronyd
  323    udp  [::1]:323            chronyd
  10 listening sockets

closing three of them, three different ways:
  1. a firewall rule against the ftp port
  2. stopping the web server
  3. removing the package behind the portmapper

what is listening now:
  21     tcp  *:21                 vsftpd
  22     tcp  0.0.0.0:22           sshd
  22     tcp  [::]:22              sshd
  323    udp  127.0.0.1:323        chronyd
  323    udp  [::1]:323            chronyd
  5 listening sockets

and what is left behind by each:
  ftp    socket still listening: 1   binary still present: yes
  http   socket still listening: 0   binary still present: yes
  rpc    socket still listening: 0   binary still present: no
```

**Ten sockets from five services, five after, and the last three lines are the
finding.**

The first count is worth dwelling on because five services did not produce five
sockets. The portmapper alone accounts for four, being bound on two protocols
across two address families, and that is entirely normal. So a surface counted in
services undercounts what is actually reachable, and the thing to count is sockets.

Then the three closures. The firewall rule closed the ftp port to the network and
the socket is still open and the program is still installed. Stopping the web
server removed the socket and left the program, which anything with rights to run
it can start again. Removing the package took the socket, the program and the
possibility.

**All three would satisfy a scan** that checks whether the port answers. Only one
of them changed what the machine is.

</details>

<figure class="learn-figure">
<svg viewBox="0 0 720 300" role="img" aria-labelledby="surface-title" style="width:100%;height:auto;">
<title id="surface-title">Ten listening sockets from five services reduced to five, with each square one socket, showing that the three closure techniques leave different residues</title>
<g fill="currentColor">
<text x="14" y="20" font-size="11">the listening surface counted, before and after, one square per socket</text>
<text x="14" y="42" font-size="9" fill-opacity="0.85">five services produced ten sockets, because a socket is per protocol and per address family</text>
<text x="150" y="68" font-size="8.5" fill-opacity="0.75">before</text>
<text x="300" y="68" font-size="8.5" fill-opacity="0.75">after</text>
<text x="430" y="68" font-size="8.5" fill-opacity="0.75">what closed it, and what it left</text>
<text x="14" y="83" font-size="9">vsftpd, port 21</text>
<rect x="150" y="74" width="12" height="12" rx="2" fill="var(--accent)" fill-opacity="0.75"/>
<rect x="300" y="74" width="12" height="12" rx="2" fill="var(--red)" fill-opacity="0.8"/>
<text x="430" y="83" font-size="8" fill-opacity="0.85">a firewall rule: socket and program both still there</text>
<text x="14" y="109" font-size="9">sshd, port 22</text>
<rect x="150" y="100" width="12" height="12" rx="2" fill="var(--accent)" fill-opacity="0.75"/>
<rect x="166" y="100" width="12" height="12" rx="2" fill="var(--accent)" fill-opacity="0.75"/>
<rect x="300" y="100" width="12" height="12" rx="2" fill="var(--accent)" fill-opacity="0.75"/>
<rect x="316" y="100" width="12" height="12" rx="2" fill="var(--accent)" fill-opacity="0.75"/>
<text x="430" y="109" font-size="8" fill-opacity="0.85">kept, because this is the service you asked for</text>
<text x="14" y="135" font-size="9">httpd, port 80</text>
<rect x="150" y="126" width="12" height="12" rx="2" fill="var(--accent)" fill-opacity="0.75"/>
<text x="430" y="135" font-size="8" fill-opacity="0.85">stopped: program still there, startable again</text>
<text x="14" y="161" font-size="9">rpcbind, port 111</text>
<rect x="150" y="152" width="12" height="12" rx="2" fill="var(--accent)" fill-opacity="0.75"/>
<rect x="166" y="152" width="12" height="12" rx="2" fill="var(--accent)" fill-opacity="0.75"/>
<rect x="182" y="152" width="12" height="12" rx="2" fill="var(--accent)" fill-opacity="0.75"/>
<rect x="198" y="152" width="12" height="12" rx="2" fill="var(--accent)" fill-opacity="0.75"/>
<text x="430" y="161" font-size="8" fill-opacity="0.85">package removed: nothing left to start</text>
<text x="14" y="187" font-size="9">chronyd, port 323</text>
<rect x="150" y="178" width="12" height="12" rx="2" fill="var(--accent)" fill-opacity="0.75"/>
<rect x="166" y="178" width="12" height="12" rx="2" fill="var(--accent)" fill-opacity="0.75"/>
<rect x="300" y="178" width="12" height="12" rx="2" fill="var(--accent)" fill-opacity="0.75"/>
<rect x="316" y="178" width="12" height="12" rx="2" fill="var(--accent)" fill-opacity="0.75"/>
<text x="430" y="187" font-size="8" fill-opacity="0.85">kept, and bound to the loopback only</text>
<text x="150" y="214" font-size="9" fill-opacity="0.9">10 listening sockets</text>
<text x="300" y="214" font-size="9" fill-opacity="0.9">5 listening sockets</text>
<text x="14" y="246" font-size="10">the count halved, and only one of the three closures removed anything</text>
<text x="14" y="266" font-size="9" fill-opacity="0.8">the ftp port is closed to the network with its socket still open and its program still installed</text>
<text x="14" y="288" font-size="9" fill-opacity="0.7">so these are not three ways of doing one thing. They leave three different machines behind</text>
</g></svg>
<figcaption>Each square is one listening socket from the capture above, which is why the portmapper has four and the web server has one. The row worth looking at twice is the first: after the firewall rule, the ftp port is unreachable from the network and the square is still there, because the socket is still open and the program is still installed. A port scan from outside reports that row and the rows below it identically. The difference only appears when something on the machine gets to make a connection, or when the rule is removed by an update, a reboot into a different profile, or somebody solving an unrelated problem at two in the morning.</figcaption>
</figure>

<details class="deeper">
<summary>Why removing software beats blocking it, and the three cases where you cannot</summary>

The ordering is not a preference. Each technique removes a different amount of the
thing that could go wrong, and they nest.

**A firewall rule removes network reachability from outside.** The vulnerable code
is still running, still parsing input from anything already inside, still holding
whatever it holds in memory, and still exploitable by a local process. It also
depends on the rule surviving, and a rule is a configuration that drifts like any
other, which is the previous topic arriving here.

**Stopping the service removes the running code.** Much better: nothing is parsing
anything. What remains is a binary and a configuration that anything with the
rights can start, including an update that restarts services it thinks it owns, a
dependency that pulls it in, and a person who does not know why it was stopped.
Stopped services come back, and the record of why they were stopped is usually in
somebody's head.

**Removing the package removes the possibility.** There is nothing to start, no
configuration to be found by a scanner, and no entry in the inventory to explain
every quarter. It is also the only one that reduces your patching workload, since
software you do not have does not need updating.

**The three cases where you cannot remove it.** A dependency that another package
requires, where removing it takes something you need with it. An appliance or a
managed image where you do not control what is installed. And a component the
vendor's support contract requires be present, which is a commercial constraint
wearing a technical hat.

**In those cases the ordering still applies downward.** Cannot remove, so stop it.
Cannot stop it, so bind it to the loopback interface. Cannot do that, so filter it
to a named set of sources. Each step is worse than the one above and much better
than nothing, and writing down which step you are on and why is what separates a
constraint from an oversight.

</details>

## The port that has to stay open

Every machine has at least one, and the way it is usually discussed is unhelpful,
because "we need port 22 open" is four different statements depending on who is
asking.

**Open to whom is the question that matters.** A management port reachable from
one jump host is a different exposure from the same port reachable from the whole
site, which is different again from the internet. The capture above has one service
already demonstrating the cheapest version of this: the time service is bound to
the loopback interface, so it is running, useful, and not reachable from anywhere.

**Binding is stronger than filtering** and gets used less. A service bound to a
single address cannot be reached on any other, with no rule to maintain and nothing
to drift. Where a service supports it, that is the first thing to change, and it
is a one-line edit that most people never make because the default is to bind
everywhere.

**Then filtering by source**, which is the next best and requires the list of
permitted sources to be a real, owned piece of data rather than a comment.

**And then authentication as the last line**, which is where most people start.

<details class="deeper">
<summary>Constraining a port you cannot close, in the order the constraints are worth applying</summary>

Six things can be done to a port that has to answer, and they are worth doing in
roughly this order because each is cheaper and more durable than the next.

**Bind it narrowly.** One interface, or the loopback, so the socket does not exist
on the networks it has no business on. Nothing to maintain.

**Filter by source.** A named set of addresses that may reach it. Durable if
somebody owns the list, and dead weight if nobody does.

**Change the default credentials**, which belongs here rather than at the end
because a port constrained to the right sources and answering to a published
password is constrained against nobody who matters. This is the cheapest item on
the whole hardening list and the most frequently skipped, because the device works
either way and nothing prompts.

**Require an authentication method that cannot be replayed or guessed.** Keys or
certificates rather than passwords, which turns the port from something guessable
into something that needs a stolen credential.

**Rate limit it.** Not to stop a determined attacker, but to make the noisy version
of the attack expensive and visible, and to keep a burst from becoming an outage.

**And log it somewhere else.** Once the port is as narrow as it will get, the
residual is detection, and detection on the machine being attacked is worth less
than detection on a machine that is not.

**One warning about a technique that sounds like it belongs here.** Moving the
service to a different port removes it from broad scanning and from the noise in
your logs, which is a real if small operational benefit. It does not constrain
anybody who looks, and treating it as a control rather than as noise reduction is
how it ends up substituting for one of the six above.

</details>

## Endpoint protection and intrusion prevention

These two overlap enough that products merge them and exam questions separate them,
so it is worth having a distinction that survives both.

**Endpoint protection asks what this is.** A file, a process, a script: it is
identified, by signature or by reputation or by a model, and acted on. The question
is about the object.

**Host-based intrusion prevention asks what this is doing.** A process writing to
another process's memory, a service spawning a shell, a document launching a script
interpreter. The question is about the behaviour, and the object may be entirely
legitimate.

**Which is why the behavioural half catches things the identifying half cannot.**
An attack conducted entirely with tools the operating system shipped has no
malicious file to identify. There is nothing to match a signature against, because
everything involved is signed by the vendor and present on every machine.

**And why the identifying half is still worth having.** It is cheap, it is
accurate on what it knows, and the volume of ordinary commodity malware it removes
without anybody being involved is the reason nobody notices it working.

<details class="deeper">
<summary>Where the two overlap, and the operational cost that decides whether either survives</summary>

Modern products ship both under one name, which makes the exam distinction feel
academic until you have to tune one.

**The overlap is real and it is in the middle.** A behavioural rule that blocks a
document launching a script interpreter is behavioural in mechanism and looks like
a signature to whoever writes it. Vendors ship these as named, individually
switchable rules precisely because each one has a different false positive profile
in a different organisation.

**Which is the whole operational story.** The identifying half is close to free to
run: it is on by default, its errors are rare, and when it is wrong somebody
restores a file. The behavioural half blocks things people were legitimately doing,
and every block is an interruption to somebody's work, arriving without warning,
often during something urgent.

**So the behavioural half gets deployed in report-only mode** and, in a great many
organisations, stays there. That is not a failure of the technology. It is a
correct reading of the cost by somebody who will be blamed for the outage and not
credited for the prevention, and changing it requires the organisation to decide in
advance that a certain number of interruptions is acceptable.

**The way it actually gets switched on** is one rule at a time, each in report mode
long enough to see what it would have blocked, with the exceptions written down
before enforcement. That is slow, unglamorous and the only approach that survives
contact with a production estate.

**And the residual is worth stating.** Both halves run on the endpoint, with high
privilege, parsing hostile input. They are large pieces of software in the most
sensitive position on the machine, and they have their own vulnerabilities. That is
not an argument against them; it is an argument for keeping them patched with the
same urgency as anything else on the perimeter, which is not how they are usually
treated.

</details>

## The order to do them in, and what each costs

The techniques in this objective are usually listed and rarely ordered, and the
order matters because the cheap ones remove the need for some of the expensive
ones.

**First, remove what you do not need**, because it costs nothing to support and
reduces everything downstream: fewer patches, fewer scan findings, fewer rules.
The cost is finding out what is needed, which is a real investigation on an
inherited machine.

**Second, change every default credential**, which is one afternoon and closes the
most reliably exploited class of exposure there is.

**Third, bind and filter what is left.** The support cost is a queue of connection
problems from people who used to reach something and now cannot, and every one of
them is a case you should have known about.

**Fourth, switch on the host firewall with a default of deny inbound**, which
formalises the previous step and catches what it missed.

**Fifth, install endpoint protection.** Nearly free to run, and its cost is a small
steady tax on performance and an occasional false positive.

**Last, enable behavioural prevention**, in report mode, and move rules to
enforcement one at a time. This is the only item on the list with an ongoing
operational cost that never ends, which is why it goes last and why leaving it in
report mode is a defensible position rather than a failure.

## Across platforms

The first four items on that list are things you do to a Linux machine and things
you check on the other two, which is the largest practical difference between them.

<details class="predict">
<summary>A Windows server nobody has hardened. Predict how much of this list is already switched on.</summary>

```powershell
# Microsoft Windows Server 2025 Datacenter, version 10.0.26100.0
> Get-NetFirewallProfile | Select-Object Name, Enabled, DefaultInboundAction, DefaultOutboundAction | Format-Table -AutoSize
Name    Enabled DefaultInboundAction DefaultOutboundAction
----    ------- -------------------- ---------------------
Domain     True        NotConfigured         NotConfigured
Private    True        NotConfigured         NotConfigured
Public     True        NotConfigured         NotConfigured

# How many rules are enabled, since the default only applies to what none of them match
> '{0} of {1} firewall rules are enabled' -f (Get-NetFirewallRule | Where-Object Enabled -eq 'True' | Measure-Object).Count, (Get-NetFirewallRule | Measure-Object).Count
183 of 348 firewall rules are enabled

# Whether endpoint protection is running here, and whether its behavioural half is on
> Get-MpComputerStatus | Select-Object AMServiceEnabled, RealTimeProtectionEnabled, BehaviorMonitorEnabled, IsTamperProtected | Format-List
AMServiceEnabled          : True
RealTimeProtectionEnabled : False
BehaviorMonitorEnabled    : False
IsTamperProtected         : False

# How much optional software is switched on, since every feature is surface somebody has to justify
> $f = Get-WindowsOptionalFeature -Online; '{0} of {1} optional features are enabled' -f ($f | Where-Object State -eq 'Enabled').Count, $f.Count
86 of 320 optional features are enabled
```

**The firewall is on with a hundred and eighty three rules already enabled, and the
protective half of the endpoint software is off.**

Read the first two blocks together. All three profiles are enabled and their
default action reads as not configured, which resolves to the built-in default of
blocking inbound connections that no rule permits. So the shape is right and the
detail is in the hundred and eighty three enabled rules, each one a hole somebody
shipped, most of them for features nobody on this machine uses.

The third block is the finding. The antimalware service is running and real-time
protection, behaviour monitoring and tamper protection are all off, which on this
image is a deliberate choice by whoever built it. A machine can report that
endpoint protection is installed and running while none of the parts that stop
anything are switched on.

And eighty six of three hundred and twenty optional features are enabled on a
machine that has not been given a job yet, which is the first item on the ordered
list waiting to be done.

</details>

**macOS arrives with the firewall switched off.**

```bash
# macOS 26.5.2, arm64
$ /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate 2>&1; /usr/libexec/ApplicationFirewall/socketfilterfw --getblockall 2>&1
Firewall is disabled. (State = 0)
Firewall has block all state set to disabled.

# How many applications hold an exception to it
$ /usr/libexec/ApplicationFirewall/socketfilterfw --listapps 2>&1 | head -2
Total number of apps = 8 
1 : /usr/local/libexec/remotepairingdeviced 

# Which malware definitions this machine holds, since that is the endpoint protection here
$ defaults read /Library/Apple/System/Library/CoreServices/XProtect.bundle/Contents/Info.plist CFBundleShortVersionString 2>&1
5287

# How many launch items are loaded, which is the closest thing to a count of what runs unasked
$ launchctl list 2>/dev/null | grep -c .
511
```

The application firewall is disabled, which is the default on macOS and surprises
people who assume otherwise. Eight applications already hold exceptions to a
firewall that is not running, which is the kind of state that makes a review
awkward: turning it on will change the behaviour of eight things nobody has
examined.

The malware definition version is the endpoint protection answer here, and it is
present and updated without anybody asking, which is the identifying half from the
section above running quietly. Five hundred and eleven loaded launch items is the
surface count, and it is the number that makes the first item on the ordered list
hard on this platform: almost none of them are things you may remove.

**Which gives the comparison in one sentence.** Linux gives you a small machine and
expects you to add protection, Windows gives you a large machine with most
protection present and some of it switched off, and macOS gives you a large machine
with its firewall off and its malware definitions current. All three need the same
list applied; only the starting point differs.

## Try it

**Count your own sockets.** Run the listening list on any machine you administer
and count. Then name the program behind each one. The ones you cannot name are the
finding.

**Close one port three ways.** On a test machine, block a port, then stop the
service, then remove the package, checking after each what is left. Fifteen
minutes, and the difference becomes permanent knowledge.

**Find one service bound too widely.** Look for something listening on every
address that only needs one. That is a one-line change with no rule to maintain.

**Check whether protection is actually protecting.** On any endpoint, find out
whether the real-time and behavioural components are enabled rather than whether
the product is installed. Those are different questions and only one of them is on
the inventory.

## Check yourself

<details class="qa">
<summary>Why is a machine's attack surface counted in sockets rather than services?</summary>

Because one service produces several. The capture on this page shows five services
producing ten listening sockets, four of them belonging to the portmapper alone,
which listens on two protocols across two address families.

A surface counted in services undercounts what is reachable, and the count is the
useful number because it is what a scan finds and what an operator has to justify
one entry at a time.

</details>

<details class="qa">
<summary>What is the difference between blocking a port, stopping a service and removing the package?</summary>

What is left. A firewall rule leaves the socket open and the program running, so
the vulnerable code still parses input from anything already inside and the rule
can drift. Stopping the service removes the running code and leaves a program
anything with rights can start again. Removing the package leaves nothing to start.

All three satisfy a scan that only checks whether the port answers, which the
capture on this page shows directly: after the rule, the ftp socket is still
listening and the binary is still present.

</details>

<details class="qa">
<summary>You cannot close a port. What do you do to it, in order?</summary>

Bind it to one interface so the socket does not exist on networks it has no
business on. Filter it to a named set of sources. Change the default credentials.
Require an authentication method that cannot be guessed or replayed. Rate limit it.
Log it somewhere the machine cannot reach.

Moving the service to a different port belongs to none of those. It reduces
scanning noise and constrains nobody who looks, so treating it as a control is how
it ends up substituting for one.

</details>

<details class="qa">
<summary>How do endpoint protection and host-based intrusion prevention differ?</summary>

Endpoint protection asks what something is, identifying a file or process and
acting on it. Intrusion prevention asks what something is doing, watching for a
behaviour such as a service spawning a shell, where the object involved may be
entirely legitimate.

The behavioural half is what catches an attack conducted with tools the operating
system shipped, because there is no malicious file to identify. It also blocks
things people were legitimately doing, which is why it is usually deployed in
report-only mode and frequently stays there.

</details>

<details class="qa">
<summary>Why does removing unnecessary software come first?</summary>

Because it costs nothing to support and reduces everything downstream: fewer
patches, fewer scan findings, fewer firewall rules and one fewer thing on the
inventory to justify each quarter. Nothing else on the list has that property.

Its cost is the investigation into what is actually needed, which is real work on
an inherited machine, and the three cases where it is impossible are a dependency
another package needs, an image you do not control, and a component a support
contract requires.

</details>

## References

- [SP 800-123](https://csrc.nist.gov/pubs/sp/800/123/final) - NIST, general server security, for the ordering of hardening steps and what each removes. Free. Accessed 2026-08-26.
- [SP 800-83 Rev. 1](https://csrc.nist.gov/pubs/sp/800/83/r1/final) - NIST, malware prevention on endpoints, for the endpoint protection half. Free. Accessed 2026-08-26.
- [M1042](https://attack.mitre.org/mitigations/M1042/) - MITRE, disabling or removing a feature or program, with the techniques it addresses listed against it. Free. Accessed 2026-08-26.
- [M1050](https://attack.mitre.org/mitigations/M1050/) - MITRE, exploit protection, which is the behavioural half. Free. Accessed 2026-08-26.

**Where the content came from.** The surface block is captured from an AlmaLinux
10.2 container that starts five ordinary services, counts what is listening, then
applies a firewall rule, stops a service and removes a package. It runs privileged
so the packet filter can be configured, which forces the virtual machine's
architecture and is why the block is labelled aarch64. Nothing is scanned from
outside and nothing is attacked: every count comes from the machine asking its own
kernel what is listening. The Windows and macOS blocks come from disposable runners
and read only. Both report a state that is a property of a continuous integration
image as much as of the operating system, which is why the readings are described
rather than generalised.

**If you also work on networks.** The Network+ track's
[device hardening and network access control](/learn/network-plus/device-hardening-and-network-access-control)
covers the same list from the position of somebody hardening switches and routers.
