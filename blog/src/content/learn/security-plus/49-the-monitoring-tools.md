---
title: "The monitoring tools"
description: "One real log line through five stages of a pipeline, why a SIEM's value is added at the parse rather than at the search, what an agentless view can and cannot reach, and the honest comparison between flow records and full packet capture."
deck: "Four tools all claim to detect the same thing, and only one of them saw it"
track: "security-plus"
level: "working"
order: 500
objectives:
  - "Follow one log line from raw text to an alert decision and name what each stage adds"
  - "Say where a SIEM's value is actually created"
  - "Compare an agent with an agentless view and say what each cannot reach"
  - "Say what flow records answer and what only full packet capture answers"
  - "Name what each tool in this objective sees and what it is blind to"
  - "Explain why the thing you most want to watch is often the thing you cannot install an agent on"
prerequisites: ["what-to-monitor-and-what-to-do-when-it-fires"]
tags: ["security-plus", "security", "operations", "monitoring"]
updated: 2026-08-25
draft: false
examObjectives:
  - exam: "sy0-701"
    domain: "4.0"
    objective: "4.4"
sources:
  - title: "SP 800-92, Guide to Computer Security Log Management"
    url: "https://csrc.nist.gov/pubs/sp/800/92/final"
    publisher: "NIST"
    accessed: 2026-08-25
    tier: 1
  - title: "RFC 7011, Specification of the IP Flow Information Export (IPFIX) Protocol"
    url: "https://www.rfc-editor.org/rfc/rfc7011.html"
    publisher: "IETF"
    accessed: 2026-08-25
    tier: 1
  - title: "RFC 3411, An Architecture for Describing SNMP Management Frameworks"
    url: "https://www.rfc-editor.org/rfc/rfc3411.html"
    publisher: "IETF"
    accessed: 2026-08-25
    tier: 1
  - title: "SCAP, Security Content Automation Protocol"
    url: "https://csrc.nist.gov/projects/security-content-automation-protocol"
    publisher: "NIST"
    accessed: 2026-08-25
    tier: 1
  - title: "Get-NetTCPConnection reference"
    url: "https://learn.microsoft.com/en-us/powershell/module/nettcpip/get-nettcpconnection"
    publisher: "Microsoft"
    accessed: 2026-08-25
    tier: 1
symptoms:
  - symptom: "A log search finds nothing because the field is not a field"
    anchor: "one-line-five-stages"
  - symptom: "The most important system is the one with no agent on it"
    anchor: "agents-and-what-they-reach"
---

> **Before you read.** A machine is compromised. Afterwards, four tools are asked
> whether they saw it: the vulnerability scanner, the antivirus, the flow
> collector and the log platform. Three say nothing. One has the evidence and
> nobody looked.
>
> **Which one, and why was nobody looking at it?**

The answer depends on what happened, which is the point of this topic. Every tool
in this objective sees a specific slice, and the way to hold them in your head is
by what each one is structurally unable to notice.

### Some words you will need

<dl class="terms">
<dt>SIEM</dt>
<dd>Security information and event management. Collects logs from many sources and runs rules over them.</dd>
<dt>parse</dt>
<dd>Turning a line of text into named fields. The step that makes searching possible.</dd>
<dt>enrichment</dt>
<dd>Adding context the log line never carried: who owns the machine, what it does, whether the account is privileged.</dd>
<dt>agent</dt>
<dd>Software running on the thing being watched. Sees the inside.</dd>
<dt>agentless</dt>
<dd>Watching from outside, over the network or through an API. Sees what is exposed.</dd>
<dt>flow record</dt>
<dd>A summary of a conversation: who talked to whom, on what port, how much, for how long. No contents.</dd>
<dt>full packet capture</dt>
<dd>The bytes themselves. Everything, at a cost that scales with your traffic.</dd>
<dt>SNMP trap</dt>
<dd>A device telling a manager something happened, rather than being asked.</dd>
<dt>DLP</dt>
<dd>Data loss prevention. Watches for defined content leaving by defined routes.</dd>
</dl>

## What breaks without this

**A search returns nothing and the data was there.** The field being searched was
never parsed into a field, so the query matched no records while the text sat in
the index.

**Coverage is measured in products.** Four tools are deployed, the report says four
tools, and nobody has written down which of them would have seen what.

**The agent is on everything except the thing that matters.** The appliance, the
industrial controller and the printer are exactly where an agent cannot go, and
they are frequently the least defended things on the network.

**Flow records are treated as evidence of content.** The investigation needs to
know what left and the collector can only say how much.

## One line, five stages

Here is a real authentication line, written by a real SSH server, put through the
five stages a monitoring platform performs on it.

```bash
# AlmaLinux 10.2, x86_64
$ /usr/sbin/sshd -o LogLevel=INFO -E /var/log/sshd.log; sleep 1; ssh -o StrictHostKeyChecking=no -o PreferredAuthentications=password -o PubkeyAuthentication=no -o ConnectTimeout=4 -o NumberOfPasswordPrompts=1 analyst@127.0.0.1 true 2>/dev/null </dev/null; sleep 1; grep -m1 "Connection closed by authenticating" /var/log/sshd.log | pipeline
1. raw
   Connection closed by authenticating user analyst 127.0.0.1 port 54654 [preauth]
2. parsed
   {"event": "Connection closed", "how": "authenticating", "user": "analyst", "src": "127.0.0.1", "port": "54654"}
3. enriched, from a local asset table
   {"event": "Connection closed", "how": "authenticating", "user": "analyst", "src": "127.0.0.1", "port": "54654", "host": "build01", "owner": "platform-team", "role": "ci runner", "internet_facing": false, "privileged": false, "last_seen_days": 214}
4. correlated
   1 event like this in the last 60s
5. alert
   not raised: one failure, unprivileged account, not internet facing
```

<figure class="learn-figure">
<svg viewBox="0 0 720 320" role="img" aria-labelledby="pipe49-title" style="width:100%;height:auto;">
<title id="pipe49-title">One authentication log line through five stages of a monitoring pipeline, with what each stage adds and what question it makes answerable</title>
<g fill="currentColor">
<text x="14" y="20" font-size="11">one log line, five stages, and what each stage makes answerable</text>
<rect x="14" y="46" width="132" height="34" rx="4" fill="var(--accent)" fill-opacity="0.13" stroke="var(--accent)" stroke-opacity="0.75" stroke-width="1.4"/>
<text x="80" y="68" text-anchor="middle" font-size="9">raw</text>
<text x="164" y="60" font-size="8.5" fill-opacity="0.9">one line of text</text>
<text x="164" y="74" font-size="8" fill-opacity="0.7">searchable, if you know the words</text>
<path d="M 80 81 V 91" stroke="currentColor" stroke-opacity="0.45" stroke-width="1.2"/>
<path d="M 77 88 L 80 92 L 83 88" fill="none" stroke="currentColor" stroke-opacity="0.45" stroke-width="1.2"/>
<rect x="14" y="92" width="132" height="34" rx="4" fill="var(--accent)" fill-opacity="0.13" stroke="var(--accent)" stroke-opacity="0.75" stroke-width="1.4"/>
<text x="80" y="114" text-anchor="middle" font-size="9">parsed</text>
<text x="164" y="106" font-size="8.5" fill-opacity="0.9">five named fields</text>
<text x="164" y="120" font-size="8" fill-opacity="0.7">now you can ask for one user</text>
<path d="M 80 127 V 137" stroke="currentColor" stroke-opacity="0.45" stroke-width="1.2"/>
<path d="M 77 134 L 80 138 L 83 134" fill="none" stroke="currentColor" stroke-opacity="0.45" stroke-width="1.2"/>
<rect x="14" y="138" width="132" height="34" rx="4" fill="var(--accent)" fill-opacity="0.13" stroke="var(--accent)" stroke-opacity="0.75" stroke-width="1.4"/>
<text x="80" y="160" text-anchor="middle" font-size="9">enriched</text>
<text x="164" y="152" font-size="8.5" fill-opacity="0.9">plus owner, role, exposure</text>
<text x="164" y="166" font-size="8" fill-opacity="0.7">now you can ask which matter</text>
<path d="M 80 173 V 183" stroke="currentColor" stroke-opacity="0.45" stroke-width="1.2"/>
<path d="M 77 180 L 80 184 L 83 180" fill="none" stroke="currentColor" stroke-opacity="0.45" stroke-width="1.2"/>
<rect x="14" y="184" width="132" height="34" rx="4" fill="var(--accent)" fill-opacity="0.13" stroke="var(--accent)" stroke-opacity="0.75" stroke-width="1.4"/>
<text x="80" y="206" text-anchor="middle" font-size="9">correlated</text>
<text x="164" y="198" font-size="8.5" fill-opacity="0.9">plus how many, how fast</text>
<text x="164" y="212" font-size="8" fill-opacity="0.7">now one alert covers forty events</text>
<path d="M 80 219 V 229" stroke="currentColor" stroke-opacity="0.45" stroke-width="1.2"/>
<path d="M 77 226 L 80 230 L 83 226" fill="none" stroke="currentColor" stroke-opacity="0.45" stroke-width="1.2"/>
<rect x="14" y="230" width="132" height="34" rx="4" fill="currentColor" fill-opacity="0.06" stroke="currentColor" stroke-opacity="0.75" stroke-width="1.4"/>
<text x="80" y="252" text-anchor="middle" font-size="9">alert</text>
<text x="164" y="244" font-size="8.5" fill-opacity="0.9">a decision, or silence</text>
<text x="164" y="258" font-size="8" fill-opacity="0.7">and this one stayed silent</text>
<text x="14" y="292" font-size="10" fill-opacity="0.85">the parse is where the value is added, and it is the step nobody buys a product for</text>
<text x="14" y="312" font-size="10" fill-opacity="0.85">an unparsed log is a text file with a search box in front of it</text>
</g></svg>
<figcaption>The same line at each stage, with what the stage adds and the question it makes answerable. Raw text can be searched only if you already know the words in it. Parsing turns it into fields, so you can ask about one user across every source. Enrichment brings in facts the log never contained, which is what turns a technical event into a business one. Correlation collapses many events into one, which is what makes a queue survivable. The last stage is a decision, and in this case the decision was silence: a single failure by an unprivileged account on a machine nothing can reach from the internet is not worth waking anybody for. Reaching that conclusion automatically, rather than by an analyst reading the line, is the entire value of the four stages above it.</figcaption>
</figure>

<details class="predict">
<summary>Of those five stages, which one creates most of the value, and which one do people buy a product for?</summary>

**The parse creates it, and nobody buys a product for parsing.**

Products are bought for the search interface, the dashboards and the rule engine,
because those are what a demonstration shows. All three are worthless against
unparsed data. A search across raw text finds the lines containing the string you
typed, which means you can only find what you already know how to phrase, and you
cannot ask a question like "every authentication failure by this account across
every system" because neither the account nor the concept of an authentication
failure exists as a field.

Parsing is unglamorous, per-source, and never finished. Every new log source needs
its own rules, vendors change their formats in point releases, and a parser that
silently stops matching produces a source that silently stops being searchable
while continuing to consume storage and licence.

That last failure is the one worth watching for. A broken parser does not throw an
error that anybody sees. The events still arrive, they still count against your
volume, they simply stop being findable, and the first sign is usually an
investigation that comes up empty against a system everybody assumed was covered.

The practical measure of a monitoring platform is therefore not what its query
language can express. It is what fraction of the sources feeding it are correctly
parsed today, and almost nobody reports that number.

</details>

<details class="deeper">
<summary>If you run a platform: what enrichment costs, and the two fields that pay for themselves</summary>

Enrichment is the stage with the best return and the most annoying dependencies,
because everything it adds comes from somewhere else.

The asset owner and the machine's role come from the inventory. Whether an account
is privileged comes from the directory. Whether a machine is reachable from
outside comes from the firewall or the cloud configuration. Each of those is a
system with its own owner, its own freshness problem, and its own opinion about
being queried thousands of times an hour.

Two fields pay for themselves faster than the rest.

The first is whether the account is privileged. It changes the triage decision on
almost every identity-related alert, and the difference between a failed login by
a contractor and one by a domain administrator is the whole of the judgement.

The second is exposure: can this thing be reached from the internet. It is the
field that separates the alerts where an unauthenticated attacker could be
involved from the ones where somebody already had access, and that distinction
reorders a queue more sharply than severity does.

Both are cheap to fetch and both go stale in exactly the way that hurts. An asset
that became internet-facing last week and is still enriched as internal produces
alerts triaged at the wrong priority, and nothing about the alert says the
enrichment is old. Timestamping the enrichment, so an analyst can see the context
was three weeks stale, is a small change that prevents a specific and nasty class
of mistake.

</details>

## Agents and what they reach

An agentless view and an agent see the same service and learn different things
about it.

```bash
# AlmaLinux 10.2, x86_64
$ dnf -q -y install iproute procps-ng >/dev/null 2>&1; /usr/sbin/sshd -o LogLevel=INFO -E /var/log/sshd.log; sleep 1; echo "what an agentless view can learn: which ports answer"; ss -ltnp 2>/dev/null | head -4; echo; echo "what an agent can learn about the same service:"; ps -eo pid,user,etimes,args --sort=-etimes 2>/dev/null | grep -m2 "[s]shd"; echo; echo "and what nothing on the network could have told you:"; ls -l /proc/$(pgrep -f "sshd" | head -1)/exe 2>/dev/null
what an agentless view can learn: which ports answer
State  Recv-Q Send-Q Local Address:Port Peer Address:PortProcess                      
LISTEN 0      0            0.0.0.0:22        0.0.0.0:*    users:(("sshd",pid=40,fd=8))
LISTEN 0      0                  *:22              *:*    users:(("sshd",pid=40,fd=9))

what an agent can learn about the same service:
     40 root           1 /usr/bin/qemu-x86_64-static /usr/sbin/sshd /usr/sbin/sshd -o LogLevel=INFO -E /var/log/sshd.log

and what nothing on the network could have told you:
lrwxrwxrwx. 1 root root 0 Aug 26 00:29 /proc/40/exe -> /usr/bin/qemu-x86_64-static
```

**The last two lines are the argument.** From the network, this is an SSH server
on port 22. From inside, the binary actually executing is
`/usr/bin/qemu-x86_64-static`, an emulator, with the SSH server passed to it as an
argument.

The reason here is mundane: this is an x86_64 container running on an arm64
machine, so every binary in it runs under a translator. That is not a security
incident and it is a precise demonstration of the distinction. A network view
reports what answers on a port. It has no mechanism at all for reporting what is
actually executing, and the gap between those two is where a process pretending to
be something else lives.

An agent also sees things that never touch the network: files being written,
processes starting and exiting, a scheduled task being created, a driver loading.
None of those produce packets, so none of them are visible from outside no matter
how good the network tooling is.

<details class="deeper">
<summary>If you are planning coverage: the machine you most want an agent on is usually the one that cannot have one</summary>

The systems where an agent would be most valuable are frequently the systems where
installing one is impossible, and the correlation is not a coincidence.

The pattern: appliances with a vendor-supported configuration that excludes third
party software, industrial and building control systems where any change voids
support or safety certification, medical devices under regulatory approval,
printers and cameras with no facility for it, and end-of-life systems that are
still running precisely because nobody dares touch them.

Every one of those is also a system that is hard to patch, hard to scan, and
frequently sitting on a flat network because it was installed by somebody who was
not thinking about segmentation. So the coverage gap and the risk concentration
are the same list.

What to do about it is unglamorous and it works. Watch the network around the
thing, since if you cannot see inside it you can at least see everything it says,
and a device with a narrow normal behaviour makes that unusually effective: a
building controller that talks to three addresses on two ports is trivially
profiled and anything else is immediately interesting. Take its logs if it emits
any, even by syslog to a collector, because a poor log stream beats none. And
segment it hard, so that the thing you cannot watch is also the thing that cannot
reach much.

The honest framing for a coverage report is two numbers rather than one: what
percentage of assets have an agent, and what percentage of the assets without one
are compensated by network monitoring and segmentation. A single agent-coverage
figure of 94 percent hides whether the missing 6 percent is laptops in a drawer or
the entire industrial estate.

</details>

## Flow records, packets, and what each one can answer

Flow records and full packet capture get compared as cheap against expensive,
which is true and is not the useful distinction.

**A flow record is a summary of a conversation.** Source, destination, ports,
protocol, byte and packet counts, start and end. No contents at all, by
construction.

That makes it excellent at a specific set of questions. Who did this machine talk
to. How much left. Did anything talk to an address it has never contacted before.
Did a workstation start behaving like a server. All of those are answerable from
flow data, cheaply, over long retention, and none of them require reading a single
payload.

**Full packet capture is the bytes.** It answers what was in it, which is the
question flow records cannot touch, and it is the only thing that will do when the
investigation needs to know exactly what was taken.

The honest comparison is about retention rather than price. Flow records for a
mid-sized network can be kept for a year without difficulty. Full capture at the
same site fills a lot of disk per day, so real deployments keep hours or days.
That inverts the usefulness during an investigation: the incident is discovered
weeks later, the flow data still covers it, and the packets do not.

So the sensible arrangement is flow everywhere with long retention, and full
capture at a small number of chosen points with short retention, understood as a
tool for questions asked quickly rather than for archaeology.

**And encryption has changed what the packets are worth.** A full capture of TLS
traffic gives you the handshake, the certificate, the size and timing of what
followed, and no contents. That is more than flow data and much less than the
promise, which is worth saying because packet capture budgets are frequently
justified on a claim about content visibility that stopped being generally true
some years ago.

The remaining tools in this objective sort quickly by the same question.
**Antivirus** looks at files against known-bad patterns and at behaviour, and is
blind to anything that never becomes a file. **Data loss prevention** watches
defined content on defined routes and is blind to content it has no definition for
and routes it does not cover. **SNMP traps** are devices reporting events they
were configured to report and are blind to anything the device does not consider
notable. **Vulnerability scanners** report what is present and are blind to
whether anybody is using it. **SCAP content** reports configuration against a
benchmark, which is the previous week's question rather than tonight's.
<details class="deeper">
<summary>If you compare products: the two numbers vendors quote, and the one that decides what you pay</summary>

Monitoring platforms are priced on volume, and the volume is not the number in the
brochure. Understanding which number is which is worth doing before a contract
rather than after.

The first number is events per second, which sounds like a capacity figure and is
usually a peak sizing figure. It matters for whether the system keeps up, and it
has almost no relationship to the bill.

The second is ingest volume, measured in gigabytes per day, and that is what most
licences are keyed on. It has an awkward property: it goes up when you improve
your monitoring. Enabling a useful audit category, onboarding a source somebody
forgot, or turning on verbose logging during an investigation all increase the
number, so the licence prices exactly the behaviour you want to encourage.

The predictable consequence is filtering at the collector to control cost, which
is a legitimate engineering decision made for a financial reason and rarely
recorded as a security one. Somebody drops informational events at the agent, the
bill comes down, and two years later an investigation discovers the field it needs
was in the dropped category.

Three things worth doing about it. Write down what is being dropped and why, in a
place a future investigator will look, so a filtering decision is visible the way
a suppression rule is. Keep a cheap archive of the raw stream even where the
expensive tier gets a filtered copy, since storage is much cheaper than licensed
ingest. And when the licence is being renegotiated, check whether the current
volume reflects what you decided to collect or what you could afford, because
those drift apart quietly.

</details>


## Across platforms

The two halves of the previous section have different shapes on each platform, and
one of them answers something surprising.

| Task | Linux | Windows | macOS |
| --- | --- | --- | --- |
| Which ports are listening | `ss -ltnp` | `Get-NetTCPConnection -State Listen` | `lsof -nP -iTCP -sTCP:LISTEN` |
| What process holds the port | included in `ss -p` | a second lookup by process id | included, and often not the server |
| Where the binary is | `/proc/PID/exe` | the process `Path` property | the process `comm` |
| Whether it is signed | package signature, not per binary | `Get-AuthenticodeSignature` | `codesign --verify` |

```powershell
# Microsoft Windows Server 2025 Datacenter, version 10.0.26100.0
> Get-NetTCPConnection -State Listen | Sort-Object LocalPort | Select-Object -First 5 LocalAddress, LocalPort, OwningProcess | Format-Table -AutoSize
LocalAddress LocalPort OwningProcess
------------ --------- -------------
0.0.0.0             22          3888
::                  22          3888
172.17.192.1        53          3684
::                  80             4
0.0.0.0            135          1108

# The agent half: what is actually behind one of those ports
> Get-NetTCPConnection -State Listen | Sort-Object LocalPort | Select-Object -First 1 | ForEach-Object { Get-Process -Id $_.OwningProcess | Select-Object Id, ProcessName, Path, StartTime } | Format-List
Id          : 3888
ProcessName : sshd
Path        : C:\Windows\System32\OpenSSH\sshd.exe
StartTime   : 8/26/2026 12:24:43 AM

# What no network view could have told you: whether the binary is signed
> Get-NetTCPConnection -State Listen | Sort-Object LocalPort | Select-Object -First 1 | ForEach-Object { $p = (Get-Process -Id $_.OwningProcess).Path; if ($p) { (Get-AuthenticodeSignature $p).Status } else { 'no path, protected process' } }
Valid

# How many listening ports there are in total, against how many you would guess
> (Get-NetTCPConnection -State Listen | Measure-Object).Count
40
```

**Forty listening ports on a machine nobody has installed anything on.** The
fourth listener in the list is port 80 owned by process 4, which is the System
process, meaning the HTTP stack is answering in the kernel rather than in an
application. An agentless scan sees a web server. There is no web server.

The third command is the one an agentless view cannot reach at all. Path and
signature status are properties of a file on that machine, and no amount of
probing port 22 recovers them.

<details class="predict">
<summary>A freshly provisioned Windows Server, with nothing installed on it. Predict how many TCP ports are listening.</summary>

**Forty.** On a machine where nobody has installed an application, configured a
role, or joined a domain.

That number is the practical starting point for a conversation about attack
surface, and it is higher than almost anyone guesses. The listeners are remote
management, name resolution, file sharing, remote procedure call infrastructure
and the machinery those depend on, and every one of them is there because a
default said so rather than because somebody decided this machine needed it.

The entry worth looking at twice in the capture is port 80 owned by process 4.
Process 4 is the System process, which means the HTTP stack is answering inside
the kernel rather than in an application. An agentless scan of this machine
reports a web server. There is no web server, there is no service somebody could
uninstall, and the finding will be argued about at length by two people neither of
whom has looked at the owning process.

Two things follow for practice. A hardening baseline that only removes
applications leaves most of this list untouched, because most of it is not an
application. And a network scan of your own estate will return a large number of
listeners that are correct, expected and impossible to explain from outside,
which is the strongest single argument for pairing the scan with something that
can see the process.

</details>

```bash
# macOS 26.5.2, arm64
$ sudo lsof -nP -iTCP -sTCP:LISTEN 2>/dev/null | awk 'NR==1 || NR<=5 {print $1, $2, $3, $9}'
COMMAND PID USER NAME
launchd 1 root *:22
launchd 1 root *:22
launchd 1 root *:22
launchd 1 root *:22

# The agent half: what is actually behind the first of those ports
$ sudo lsof -nP -iTCP -sTCP:LISTEN 2>/dev/null | awk 'NR==2 {print $2}' | xargs -I{} ps -o pid,user,etime,comm -p {} 2>/dev/null
  PID USER ELAPSED COMM
    1 root   11:03 /sbin/launchd

# What no network view could have told you: whether the binary is signed
$ sudo lsof -nP -iTCP -sTCP:LISTEN 2>/dev/null | awk 'NR==2 {print $2}' | xargs -I{} sh -c 'codesign -dv --verbose=2 /proc/{} 2>/dev/null || ps -o comm= -p {} | xargs -I@ codesign --verify --verbose=2 @ 2>&1 | head -2'
/sbin/launchd: valid on disk
/sbin/launchd: satisfies its Designated Requirement

# How many listening sockets there are in total
$ sudo lsof -nP -iTCP -sTCP:LISTEN 2>/dev/null | tail -n +2 | wc -l | tr -d ' '
4
```

**Every listening socket on this Mac is held by process 1.** Not by an SSH server:
by `launchd`, which holds the socket and starts the actual service only when a
connection arrives.

That is a genuine trap for anybody porting a detection from another platform. On
Linux and Windows, the process holding the port is the process that serves the
connection, so "which process owns port 22" is a useful question with a useful
answer. On macOS the honest answer is `launchd` for a large share of ports, and a
rule that alerts on unexpected processes holding ports produces one finding
containing everything.

The contrast in the totals is worth noting too. Forty listening sockets on the
Windows machine, four on the Mac, both freshly provisioned and neither running an
application anybody installed. Those are default postures, and the difference is
what an attacker finds before doing anything.
<details class="deeper">
<summary>If you are choosing where to collect: why the boundary you instrument decides what you can ever ask</summary>

Flow collection is usually deployed at the internet edge, because that is where
the perceived threat is and where the equipment already supports it. The
consequence is a specific and permanent blind spot that nobody notices until an
investigation runs into it.

Traffic between two machines on the same internal segment never crosses the edge.
Neither does traffic between two virtual machines on the same host, or between two
containers on the same node, or from a workstation to a file server in the next
rack. All of that is the movement an intruder makes after they get in, which is
the phase where detection is still possible and the phase your collectors cannot
see.

The general rule is that you can only ever ask questions about traffic that
crossed a point you instrumented. Everything else is not merely unmonitored, it is
unaskable, and the gap is invisible in a coverage report that counts collectors
rather than paths.

Where to put them, in rough order of value for a normal estate: the boundary
between user networks and server networks, because that is where lateral movement
becomes visible; the boundary around anything you cannot put an agent on; and then
the internet edge, which is usually already done and which the perimeter firewall
partly duplicates anyway.

The awkward case is cloud and virtualised traffic that never touches a physical
network at all. Flow logging exists at the virtual network layer on the major
platforms and it is off by default in most configurations, priced per volume, and
frequently discovered during an incident to have been enabled on three subnets out
of forty.

</details>


## Prove it

**Run it.** On any Linux machine, `ss -ltnp` and then `ps -p <pid> -o args=` for
one of the process ids it reports. Compare the two answers to the same question.

**Work it out.** Take one log source you rely on and write down the fields it is
parsed into. If you cannot list them, that is the finding, and the follow-up
question is which of your rules depend on fields that do not exist.

**Look it up.** Open RFC 7011 and find the list of information elements a flow
record can carry. Notice what is not in the list, and what that means for an
investigation that needs to know what was taken.

## What trips people up

### 1. Buying a search interface and expecting detection

Search works on fields. Fields come from parsing. An unparsed source is a text
file with a search box in front of it, and no rule you write will match it.

### 2. Not noticing when a parser breaks

The events keep arriving, keep counting against your volume, and stop being
findable. Nothing errors, and the discovery is usually an investigation that comes
up empty.

### 3. Treating a network view as knowledge of what is running

A port tells you something answers. The capture above shows a machine where the
binary behind port 22 is an emulator, and another where the process holding it is
`launchd`. Neither is visible from the network.

### 4. Reading flow records as content

They summarise a conversation and carry no payload by construction. If the
question is what left, flow data can answer how much and not what.

### 5. Justifying packet capture on content visibility

Most traffic is encrypted, so a full capture gives you the handshake, the
certificate, and sizes and timings. That is worth having and it is not what the
budget usually claims.

### 6. Reporting agent coverage as one number

Ninety-four percent hides whether the missing six percent is laptops in a drawer
or the entire industrial estate, and it is usually the latter, because the systems
that cannot take an agent are the same ones that cannot be patched.

## Work it through

An organisation has a SIEM with eleven sources, agents on all servers and
laptops, flow collection at the internet edge, and no packet capture. A machine in
the factory has been behaving oddly and none of the tools has said anything.

**The tempting move is to buy the missing tool.** Packet capture is the obvious
gap on that list, and a vendor will be delighted. It also would not have helped,
because nothing in the factory traverses the internet edge where the collectors
are, and the machine in question could not take an agent even if somebody bought
more licences.

**The move that works maps the tools against the asset before buying anything.**
For this one machine, write down what each existing tool would see. The scanner
cannot log in. The antivirus cannot be installed. The flow collector is at the
wrong boundary. The SIEM has no source for it. That is four blanks, and the list
of blanks is the requirement.

**Then the cheapest thing that fills a blank comes first.** Flow collection at the
factory boundary rather than the internet edge, which is a configuration change on
existing equipment rather than a purchase, and it turns a device with a narrow
normal behaviour into one of the most monitorable things on the network precisely
because anything unusual stands out.

**What this rejects is buying coverage by product.** The eleven sources and the
agent estate are real coverage of the things they cover, and the gap is a specific
asset class rather than a missing category of tool. A purchase made without the
mapping buys visibility somewhere you already had it.

The residual is worth naming plainly: nothing proposed here sees inside that
machine. If it is compromised in a way that does not change its network behaviour,
this arrangement will not find it, and the compensating answer is segmentation,
so that a machine you cannot watch is also a machine that cannot reach anything.

## Try it

**Find an unparsed source.** In whatever log platform you have, pick a source and
search for a field rather than a string. If the field search returns nothing while
the string search returns records, that source is not parsed.

**Compare the two views.** `ss -ltnp` or `Get-NetTCPConnection` for the outside
view, then look up what is actually running behind one of those ports. Note how
much of the second answer is unavailable from the first.

**Count your own listeners.** Run the port list on a machine you consider clean.
The number will be higher than you expect, and identifying every entry is a
genuinely useful hour.

**Ask what your flow retention is.** Then ask how long your organisation typically
takes to notice an incident. If the second number is larger than the first, flow
data will not cover the beginning of the next investigation.

## Check yourself

<details class="qa">
<summary>Where is a SIEM's value created, and what happens when that stage fails silently?</summary>

At the parse. Turning text into named fields is what makes searching, rule writing
and correlation possible, and it is per-source, never finished, and broken by
vendor format changes.

When a parser stops matching, nothing errors. The events still arrive and still
consume storage and licence, and they stop being findable. The usual discovery is
an investigation that returns nothing against a system everybody believed was
covered.

</details>

<details class="qa">
<summary>Name two things an agent sees that no agentless view can reach.</summary>

What is actually executing behind a port, and anything that never produces
packets. The capture in this topic shows a machine where the binary behind port 22
is an emulator with the SSH server passed as an argument, which the network view
reports as an SSH server.

Files being written, processes starting and exiting, scheduled tasks being
created, drivers loading: none of those generate network traffic, so no amount of
network monitoring reaches them.

</details>

<details class="qa">
<summary>An investigation needs to know what data left the network six weeks ago. Which tool answers?</summary>

Probably none of them, and the reason is retention rather than capability.

Flow records say how much left and to where, and are cheap enough to keep for a
year, so they will cover six weeks ago. They carry no payload. Full packet capture
carries the payload and is usually retained for hours or days, so it will not
reach back that far, and where the traffic was encrypted it would give sizes and
timings rather than contents anyway.

</details>

<details class="qa">
<summary>Why is the system you most want an agent on often the one that cannot have one?</summary>

Because the same properties cause both. Appliances, industrial and building
controllers, medical devices and end-of-life systems exclude third party software
by vendor policy, regulatory approval or sheer fragility, and those same
properties make them hard to patch and hard to scan.

The coverage gap and the risk concentration are therefore the same list. The
answers are network monitoring around the device, taking whatever logs it emits,
and segmenting it hard.

</details>

<details class="qa">
<summary>On macOS, every listening socket is owned by process 1. What does that mean for a detection rule?</summary>

That `launchd` holds the socket and starts the real service on demand, so the
process owning a port is not the process serving the connection.

A rule written on Linux or Windows logic, alerting on unexpected processes holding
ports, produces one finding on macOS containing everything. Detections do not port
between platforms by translating the command; the question has to be re-answered
against what each platform actually reports.

</details>

## References

- [SP 800-92](https://csrc.nist.gov/pubs/sp/800/92/final) - NIST, log management, for collection, parsing and what a log platform is for. Free. Accessed 2026-08-25.
- [RFC 7011](https://www.rfc-editor.org/rfc/rfc7011.html) - IETF, IPFIX, for what a flow record carries and what it does not. Free. Accessed 2026-08-25.
- [RFC 3411](https://www.rfc-editor.org/rfc/rfc3411.html) - IETF, the SNMP architecture, for what a trap is and who sends it. Free. Accessed 2026-08-25.
- [SCAP](https://csrc.nist.gov/projects/security-content-automation-protocol) - NIST, the protocol behind the benchmark scanning in the baselines topic. Free. Accessed 2026-08-25.
- [Get-NetTCPConnection](https://learn.microsoft.com/en-us/powershell/module/nettcpip/get-nettcpconnection) - Microsoft, for the Windows capture and what the owning process field means. Free. Accessed 2026-08-25.

**Where the content came from.** The pipeline block is a real SSH server on an
AlmaLinux 10.2 container, connected to from the same container with no password
set, which is what produces the line. Stages two and four are real transformations
of that real line. The enrichment table in stage three was written for this
demonstration and the output says so, because an asset table is
organisation-specific by definition and there is no honest way to capture somebody
else's. The emulator visible behind port 22 is a property of running an x86_64
container on an arm64 host, stated rather than presented as a finding. The Windows
and macOS blocks are captured from disposable runners.

**If you also work on networks.** The Network+ track's
[SNMP](/learn/network-plus/snmp) covers traps and polling in detail,
[flow data, capture and port mirroring](/learn/network-plus/flow-data-capture-and-port-mirroring)
covers where the collectors go, and
[packet capture and protocol analysis](/learn/network-plus/packet-capture-and-protocol-analysis)
covers what a capture actually contains.
