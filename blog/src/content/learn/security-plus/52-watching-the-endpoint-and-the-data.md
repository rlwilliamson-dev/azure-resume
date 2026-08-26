---
title: "Watching the endpoint and the data"
description: "Four ways a document leaves and what a network control sees of each, why file integrity monitoring is already built into a package manager, what content detection actually does and why it produces false positives, and the leak no technical control catches."
deck: "The file left on a USB stick. The firewall logs are clean, and they always would have been"
track: "security-plus"
level: "working"
order: 530
objectives:
  - "Say why endpoint controls exist by naming what a network control cannot see"
  - "Use a package database as file integrity monitoring and read its output"
  - "Describe what content detection matches and why it needs a second check"
  - "Distinguish endpoint detection and response from antivirus by what each examines"
  - "Say what a behaviour baseline needs before it is worth anything"
  - "Name the exfiltration route no technical control catches"
prerequisites: ["filtering-at-the-edge"]
tags: ["security-plus", "security", "operations", "endpoint"]
updated: 2026-08-25
draft: false
examObjectives:
  - exam: "sy0-701"
    domain: "4.0"
    objective: "4.5"
sources:
  - title: "SP 800-137, Information Security Continuous Monitoring"
    url: "https://csrc.nist.gov/pubs/sp/800/137/final"
    publisher: "NIST"
    accessed: 2026-08-25
    tier: 1
  - title: "SP 800-83 Rev. 1, Guide to Malware Incident Prevention and Handling for Desktops and Laptops"
    url: "https://csrc.nist.gov/pubs/sp/800/83/r1/final"
    publisher: "NIST"
    accessed: 2026-08-25
    tier: 1
  - title: "rpm manual page"
    url: "https://man7.org/linux/man-pages/man8/rpm.8.html"
    publisher: "man7.org"
    accessed: 2026-08-25
    tier: 1
  - title: "Get-FileHash reference"
    url: "https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/get-filehash"
    publisher: "Microsoft"
    accessed: 2026-08-25
    tier: 1
  - title: "ISO/IEC 7812 check digit, Luhn algorithm"
    url: "https://www.rfc-editor.org/rfc/rfc4949.html"
    publisher: "IETF"
    accessed: 2026-08-25
    tier: 2
symptoms:
  - symptom: "Data left and the network logs show nothing unusual"
    anchor: "four-ways-out"
  - symptom: "The content scanner flags a phone number as a card number"
    anchor: "what-content-detection-actually-does"
---

> **Before you read.** A customer list left the company on a USB stick. The
> firewall logs for that day are clean and there is nothing unusual in them.
>
> **Was the firewall misconfigured?**

No. It worked perfectly and it was never going to see anything, because nothing
crossed it. Every control in this objective exists because a network control has a
structural blind spot, and knowing which blind spot each one covers is the whole
of the topic.

### Some words you will need

<dl class="terms">
<dt>file integrity monitoring</dt>
<dd>Noticing that a file changed when it should not have. Abbreviated FIM.</dd>
<dt>data loss prevention</dt>
<dd>Detecting defined content leaving by defined routes, and sometimes stopping it.</dd>
<dt>network access control</dt>
<dd>Deciding whether a device may join the network at all, and what it may reach once it has.</dd>
<dt>EDR</dt>
<dd>Endpoint detection and response. Records what processes do and lets you act on a machine remotely.</dd>
<dt>XDR</dt>
<dd>The same idea extended across more than the endpoint: mail, identity, cloud.</dd>
<dt>UEBA</dt>
<dd>User and entity behaviour analytics. Flags a person or machine behaving unlike its own history.</dd>
<dt>baseline</dt>
<dd>What normal looked like, learned over time. Everything behavioural depends on one being accurate.</dd>
<dt>false positive</dt>
<dd>A match that is not the thing. The cost that decides whether a detection is usable.</dd>
</dl>

## What breaks without this

**The investigation has no data.** The network logs are clean because the data
never crossed the network, and nothing on the machine was recording.

**Content detection is deployed and immediately disabled.** It matched every phone
number and every reference number, the volume was unusable, and nobody added the
second check that would have fixed it.

**Antivirus is expected to catch something it never examines.** The technique
never wrote a file, and a scanner that examines files had nothing to look at.

**A behavioural tool is switched on in week one.** It has no baseline, so
everything is anomalous, and by the time it has learned something the team has
stopped reading its output.

## Four ways out

<figure class="learn-figure">
<svg viewBox="0 0 720 276" role="img" aria-labelledby="exf-title" style="width:100%;height:auto;">
<title id="exf-title">Four ways the same document can leave, what a network control can observe of each, and which control is the one that would notice</title>
<g fill="currentColor">
<text x="14" y="20" font-size="11">one document, four ways out, and what the network sees of each</text>
<text x="196" y="44" font-size="9" fill-opacity="0.7">what a network control sees</text>
<text x="470" y="44" font-size="9" fill-opacity="0.7">the control that would notice</text>
<text x="14" y="75" font-size="8.5">copied to a USB stick</text>
<rect x="184" y="56" width="266" height="30" rx="3" fill="var(--red)" fill-opacity="0.12" stroke="var(--red)" stroke-opacity="0.6" stroke-width="1.2"/>
<text x="196" y="75" font-size="8">never touches the network at all</text>
<rect x="462" y="56" width="244" height="30" rx="3" fill="currentColor" fill-opacity="0.05" stroke="currentColor" stroke-opacity="0.5" stroke-width="1.1"/>
<text x="474" y="75" font-size="8">endpoint agent, or nothing</text>
<text x="14" y="115" font-size="8.5">uploaded to personal cloud</text>
<rect x="184" y="96" width="266" height="30" rx="3" fill="currentColor" fill-opacity="0.05" stroke="currentColor" stroke-opacity="0.6" stroke-width="1.2"/>
<text x="196" y="115" font-size="8">the name and the size, not the contents</text>
<rect x="462" y="96" width="244" height="30" rx="3" fill="currentColor" fill-opacity="0.05" stroke="currentColor" stroke-opacity="0.5" stroke-width="1.1"/>
<text x="474" y="115" font-size="8">DLP on the endpoint, or a proxy</text>
<text x="14" y="155" font-size="8.5">emailed as an attachment</text>
<rect x="184" y="136" width="266" height="30" rx="3" fill="currentColor" fill-opacity="0.05" stroke="currentColor" stroke-opacity="0.6" stroke-width="1.2"/>
<text x="196" y="155" font-size="8">the message, if it goes through the gateway</text>
<rect x="462" y="136" width="244" height="30" rx="3" fill="currentColor" fill-opacity="0.05" stroke="currentColor" stroke-opacity="0.5" stroke-width="1.1"/>
<text x="474" y="155" font-size="8">the mail gateway</text>
<text x="14" y="195" font-size="8.5">photographed off the screen</text>
<rect x="184" y="176" width="266" height="30" rx="3" fill="var(--red)" fill-opacity="0.12" stroke="var(--red)" stroke-opacity="0.6" stroke-width="1.2"/>
<text x="196" y="195" font-size="8">nothing, on any system you own</text>
<rect x="462" y="176" width="244" height="30" rx="3" fill="currentColor" fill-opacity="0.05" stroke="currentColor" stroke-opacity="0.5" stroke-width="1.1"/>
<text x="474" y="195" font-size="8">nothing technical</text>
<text x="14" y="234" font-size="10" fill-opacity="0.85">two of the four are invisible to every network control there is</text>
<text x="14" y="254" font-size="10" fill-opacity="0.85">and the fourth is invisible to every technical control there is</text>
<text x="14" y="272" font-size="9" fill-opacity="0.7">which is why the endpoint controls in this topic exist at all</text>
</g></svg>
<figcaption>The same document, four routes, and the network's view of each. A copy to removable media produces no packets at all. An upload to a personal cloud service produces a name and a size, and on modern encrypted traffic nothing else. An email attachment is visible if the message goes through your gateway, which is why the route around it is a personal webmail account. And a photograph of the screen produces nothing anywhere, on any system anybody owns. Two of the four are invisible to every network control there is, which is the argument for the endpoint controls in this objective. The fourth is invisible to every technical control there is, which is the argument for the ones that are not technical.</figcaption>
</figure>

The fourth row is worth pausing on rather than treating as a joke. A determined
person with legitimate access photographs the screen, and no product on this exam
addresses it. What addresses it is the set of controls that reduce how much any
one person can see at once, plus the ones that are about people rather than about
machines.

**That is the honest boundary of this whole objective.** Everything here is good
at the ordinary case, which is somebody moving data carelessly or an intruder
using a machine. None of it stops a determined insider, and a programme sold as if
it does will be believed until it is tested.

## File integrity is already installed

You do not need a product to answer the question "has this file changed since it
was installed", because a package manager already keeps a hash of everything it
put on disk.

<details class="predict">
<summary>One line is appended to a configuration file. Predict how much a package verification reports about it.</summary>

```bash
# AlmaLinux 10.2, x86_64
$ dnf -q -y install openssh-server >/dev/null 2>&1; echo "the package database already holds a hash of every file it installed:"; rpm -V openssh-server; echo "(no output means every file matches what was shipped)"; echo; echo "now change one byte in a configuration file:"; echo "# added by nobody in particular" >> /etc/ssh/sshd_config; rpm -V openssh-server; echo; echo "and what those flag positions mean:"; rpm -V openssh-server | awk "{print \$1}" | head -1 | fold -w1 | tr "\n" " "
the package database already holds a hash of every file it installed:
(no output means every file matches what was shipped)

now change one byte in a configuration file:
S.5....T.  c /etc/ssh/sshd_config

and what those flag positions mean:
S . 5 . . . . T . 
```

**Nine flag positions, three of them set, and the file marked as configuration.**

`S` means the size differs. `5` means the MD5 digest differs. `T` means the
modification time differs. The dots are the checks that passed: ownership, group,
permissions, device type, symlink target and capabilities. The `c` in the second
column marks this as a config file rather than a binary.

That is a complete file integrity report and it came from a package manager doing
its ordinary job. No agent, no licence, no baseline to build, because the baseline
was created when the package was installed.

Two limits worth knowing before relying on it. It only covers files a package
installed, so anything your application wrote, anything in `/opt`, and every
data file is outside it entirely. And the database it compares against lives on
the same machine, so an attacker with root can update it, which is the general
weakness of any integrity check whose reference copy is local.

Both limits point the same way. This is an excellent free check for the packaged
system, and a real file integrity product earns its money by covering the rest and
by keeping the reference somewhere the machine cannot reach.

</details>

<details class="deeper">
<summary>If you deploy file integrity monitoring: the tuning problem, and where to put the reference</summary>

Every file integrity deployment goes through the same two weeks and it is worth
knowing the shape in advance.

The first problem is volume. Watch everything and the report is thousands of
changes a day, because operating systems write constantly: logs, caches,
timestamps, package updates, temporary files. The output is unreadable and the
tool gets a reputation before it has found anything.

The tuning that works is not a list of exclusions bolted on afterwards. It is
choosing the watched set deliberately at the start, and the set that earns its
place is small: the directories holding executables and libraries, the
configuration of the services that matter, the scheduled task and service
definitions, and the account files. Those change rarely, they change for reasons
somebody can name, and a change to any of them during an incident is meaningful.

The second problem is where the reference lives. A hash database on the machine
being watched can be rewritten by anybody who compromises the machine, which
makes the whole exercise a check against a party who may already be lying. Real
deployments keep the reference on a separate system, or sign it with a key the
machine does not hold, or ship every hash off the box as it is computed.

There is also the change management half, which is the part that decides whether
anybody keeps reading the alerts. If a patch window produces four thousand
integrity alerts and nobody suppressed them in advance, the team learns to ignore
the tool exactly when it is noisiest. Wiring the monitoring to the change calendar
so expected changes are expected is unglamorous and it is what separates the
deployments that survive from the ones that get switched off.

</details>

## What content detection actually does

Data loss prevention is usually described as recognising sensitive data, which
makes it sound like a judgement. It is a pattern match followed by a check, and
seeing the two steps separately explains most of its behaviour.

```bash
# AlmaLinux 10.2, x86_64
$ dlp-scan /srv/docs/notes.txt
4 strings match the shape of a card number
  4111 1111 1111 1111        16 digits, passes the checksum
  0800 4111 1111 1111        16 digits, fails the checksum
  1234 5678 9012 3456        16 digits, fails the checksum
  4111111111111112           16 digits, fails the checksum
```

**Four strings matched the shape and one passed the checksum.** The other three
are a phone number, a reference number and an employee identifier, all sixteen
digits, all shaped exactly like a card number.

Without the second check, this document produces four findings and three of them
are wrong. That ratio is the entire reason content detection has a reputation for
noise, and the checksum is the cheapest possible fix: a card number carries a
check digit, so most random sixteen-digit strings fail it.

Not everything has a checksum, which is where the difficulty is. A national
insurance number, a customer reference or a project codename has no arithmetic to
verify, so detection falls back on context: the words nearby, the document type,
the location. Those work and they are softer, and the false positive rate for
anything without a check digit is structurally worse.

**The route matters as much as the content.** Detection on the endpoint sees a
copy to a USB stick. Detection at the mail gateway sees an attachment. Detection
at a web proxy sees an upload. Each covers one route and none covers the others,
and a deployment on one route is frequently sold and bought as coverage.

<details class="deeper">
<summary>If you own the DLP: why it stops the honest mistake and not the determined leak</summary>

Content detection is genuinely effective against one thing and structurally
ineffective against another, and the difference is worth being direct about
because it decides what you should promise.

What it stops is the ordinary mistake. Somebody attaches the wrong spreadsheet.
Somebody copies a customer export to a personal drive to work on at home. Somebody
sends a file to an address that autocompleted wrongly. Every one of those is a
person doing their job carelessly, the content is unmodified, and a pattern match
catches it. That is most incidents by count, and preventing them is worth the
deployment on its own.

What it does not stop is anybody who has decided to take the data and thought
about it for five minutes. Compress the file and the patterns are gone. Encrypt it
and there is nothing to match. Paste the contents into a document with the digits
spaced differently. Photograph the screen. Retype a hundred records. Every one of
those defeats content matching completely, and none of them requires any
sophistication.

The honest framing for a business case is therefore that DLP reduces accidental
loss and creates a record, and that it raises the effort required of a deliberate
leak from nothing to slightly more than nothing. Sold as a control that prevents
insider theft, it will be believed by whoever signed for it and disproved by the
first person who tries.

There is a second effect worth claiming, because it is real: the block message
teaches. A person who is stopped from uploading a customer list learns that the
organisation watches, and that changes behaviour among people who were not
intending anything. That is a deterrent control in the vocabulary from the control
types topic, and it is the part of DLP with the best return and the least
measurable evidence.

</details>

## Why EDR sees what antivirus cannot

Both run on the endpoint and they examine different things.

**Antivirus examines files.** It scans on write, on read, and on a schedule,
against signatures and against heuristics about what a file looks like. It is
mature, cheap and effective against files that are known to be bad or that look
like it.

**EDR records behaviour.** Processes starting, what started them, what they
opened, what they connected to, what they wrote. It is a continuous record rather
than a verdict, and the detections are written against sequences: this process
spawned that one, which is unusual, and then reached out.

The gap between them is the technique that never becomes a file. A script
interpreted in memory, a legitimate system tool used for something it was not
meant for, a process injected into another. Antivirus has nothing to scan because
nothing was written, and EDR sees the sequence.

**The response half is the other difference.** EDR lets somebody isolate the
machine from a console, kill a process, collect artefacts and roll something back,
without physically reaching the endpoint. That capability is why the response
letter is in the name, and it is a substantial standing privilege that deserves
its own access control.

XDR is the same idea widened to mail, identity and cloud, so a sequence can cross
from a message to an endpoint to a sign-in. The value is real and it depends
entirely on those sources being correctly onboarded, which is the parse problem
from the monitoring topic in a different costume.

**Behavioural analytics needs a baseline before it is anything.** A tool that
flags a user behaving unlike their history has to have the history, and how long
that takes depends on how variable the person is. Deployed on Monday, it flags
everything. The practical requirement is a learning period nobody wants to wait
out and a definition of the entity that makes sense: a shared service account has
no personal behaviour to model, and modelling it anyway produces the confident
nonsense these tools are mocked for.
<details class="deeper">
<summary>If you are evaluating network access control: what it decides, and the two states everybody forgets</summary>

Network access control decides whether a device may join and what it may reach
once it has, usually by checking something about the device before granting more
than a minimal amount of connectivity.

The check varies and the categories are worth knowing. Identity-based checks ask
whether the device or its user can authenticate, which on a wired network means
802.1X and on wireless means the enterprise mode from the wireless topic. Posture
checks ask whether the device meets a standard: patched, encrypted, running an
agent, antivirus current. Most deployments do both.

The two states everybody forgets are what happens to a device that fails the check
and what happens when the checking service is unavailable.

A device that fails needs somewhere to go. Denying it entirely is clean and
produces a support call from somebody whose laptop is three days behind on
patches. A remediation network, where it can reach the patch server and nothing
else, is the usual answer and is a real network somebody has to build and
maintain. Deployments that skip it end up with an exception list that grows until
it is the policy.

Unavailability is the fail-open and fail-closed decision again, and it bites
harder here than almost anywhere else, because the failure affects everybody
trying to connect rather than one flow. Fail closed and an outage in the
authentication service is an outage in the office. Fail open and an attacker who
can degrade that service has removed the control for the whole site.

The third thing worth checking in an evaluation is what the control does about
devices that cannot participate at all. Printers, cameras, building systems and
appliances frequently have no supplicant and no agent, so they are exempted by
address, and an exemption list keyed on addresses is defeated by presenting a
different address. That is not a reason to skip it, and it is a reason the
exempted devices belong on a segment of their own rather than on the corporate
network with a note beside them.

</details>

<details class="predict">
<summary>Antivirus and EDR both run on a laptop. A technique runs a script in memory and never writes a file. Predict what each one has to work with.</summary>

**Antivirus has nothing at all, and EDR has the whole sequence.**

This is not a quality difference between products. It is what each one examines.
Antivirus hooks file operations: something is written, opened or scheduled, and
the scanner reads the bytes. If nothing is written, no hook fires, and the most
thorough scanner in the world is looking at an empty set.

EDR records process activity regardless of whether files are involved. A shell
starting from a document handler, that shell starting an interpreter, the
interpreter opening a network connection, and none of it touching disk, is four
recorded events and a detectable sequence.

The technique's name in the industry is living off the land, and the reason it is
so common is exactly this asymmetry: it defeats an entire mature product category
without needing anything clever, by using tools the operating system ships and
never dropping anything to scan.

Two practical notes. The tools involved are legitimate, so the detection is
necessarily about sequences and context rather than about the tool, which makes
tuning harder and false positives more likely than with a signature. And the
recording has to be running before the event, because unlike a file, a process
that has exited leaves nothing behind to examine afterwards. An EDR deployed the
day after an incident answers nothing about it.

</details>


## Across platforms

The integrity question has three quite different answers, and one of the three is
much stronger than the others about a much narrower set of files.

| Task | Linux | Windows | macOS |
| --- | --- | --- | --- |
| Verify installed files against a stored hash | `rpm -V`, per file, per attribute | no per-file database | a seal over the whole system volume |
| Verify one binary | package hash, or a signature | `Get-AuthenticodeSignature` | `codesign --verify` |
| Hash a file yourself | `sha256sum` | `Get-FileHash` | `shasum -a 256` |
| Watch for changes as they happen | `auditctl`, `fanotify` | audit subcategory, off by default | `fs_usage`, live only |

```powershell
# Microsoft Windows Server 2025 Datacenter, version 10.0.26100.0
> Get-Command rpm, dpkg, sfc, DISM -ErrorAction SilentlyContinue | Select-Object Name, CommandType | Format-Table -AutoSize
Name     CommandType
----     -----------
sfc.exe  Application
Dism.exe Application

# Whether a signed system binary still matches its signature, one file at a time
> Get-AuthenticodeSignature C:\Windows\System32\cmd.exe | Select-Object Status | Format-List
Status : Valid

# What a hash of one file looks like, since there is no per-file database to compare against
> Get-FileHash C:\Windows\System32\cmd.exe -Algorithm SHA256 | Select-Object -ExpandProperty Hash
64AFC6DB3AAD1289533662E2D79E27DD55C7DCDB8CD918B08E145AD82AD5ACB4

# Whether anything is watching for changes, which is a separate subsystem again
> auditpol /get /subcategory:"File System" 2>&1 | Select-String -Pattern 'File System' | Select-Object -Last 1 | ForEach-Object { $_.Line.Trim() }
File System                             No Auditing
```


# provenance: Microsoft Windows Server 2025 Datacenter, version 10.0.26100.0, runner image 20260818.207.1

**Neither `rpm` nor `dpkg` is there, and the two tools that are do something
else.** `sfc` and `Dism` repair the component store, which answers whether Windows
can restore a correct copy rather than telling you which files differ and how.

So the per-file question is answered one file at a time, by signature. `cmd.exe`
verifies as `Valid`, which is a strong statement about that file and requires
knowing to ask about it. The hash on the next line has nothing to compare against
locally: there is no shipped database of expected hashes, so a hash is only useful
against a reference you keep somewhere else.

The last line is the one that matters most for an investigation. File System
auditing reports `No Auditing`, so nothing on this machine is recording file
access at all. That is the default, and it is the reason a Windows forensic
timeline is frequently thinner than people expect.

```bash
# macOS 26.5.2, arm64
$ csrutil authenticated-root status 2>&1; diskutil apfs list 2>/dev/null | grep -m1 -i "sealed\|Snapshot"
Authenticated Root status: enabled
|   |   Sealed:                    Yes

# Whether one system binary still verifies, which is per-file and per-signature
$ codesign --verify --verbose=2 /bin/sh 2>&1 | head -2
/bin/sh: valid on disk
/bin/sh: satisfies its Designated Requirement

# A hash of the same file, for comparison with the Linux and Windows columns
$ shasum -a 256 /bin/sh | awk '{print toupper($1)}'
AD5C194B05F83BC5E793C1CD67B148A4B680467B5A5730AB1A31FE4E6460EE9F

# Whether anything on the machine is watching for changes to files you own
$ sudo fs_usage -w -f filesys 2>/dev/null | head -2 & sleep 2; kill %1 2>/dev/null; echo "fs_usage streams events live and stores none of them"
01:49:49.837632  close             F=10                                                                                                                                                                                       0.000002   provjobd2056419940.6035
01:49:49.837745    RdData[A]       D=0x0021b1ba  B=0xc000   /dev/disk3s2                                                                                                                                                      0.000639 W adprivacyd.6615
fs_usage streams events live and stores none of them
```

**macOS answers with a seal rather than a list.** Authenticated Root is enabled,
which means the system volume carries a cryptographic seal covering everything
Apple shipped, verified at boot. That is a stronger guarantee than a per-file hash
database, because it cannot be updated file by file by anybody who compromises the
machine.

It is also narrower in a way worth stating: it covers the system volume. Your
applications, your data and anything installed outside it are not sealed, and the
per-file route for those is `codesign`, which verifies a signature rather than
comparing against an expected hash.

The last command is the closest thing to live file monitoring and it demonstrates
the limit. `fs_usage` shows real events, from real processes, in real time, and
stores none of them. Two seconds of it produced records from two background
daemons. It is a diagnostic tool rather than a monitoring one, and anything that
retains this stream on a Mac is a product somebody installed.

## Prove it

**Run it.** `rpm -V` or `dpkg -V` on any package on a Linux machine you own, then
append a comment to one of its configuration files and run it again. The flag
string is a complete integrity report and it costs nothing.

**Work it out.** Take the four exfiltration routes in the figure and, for your own
organisation, name the control that covers each. Count how many you can name.
Then decide what you would tell somebody who asked whether the organisation would
notice a customer list leaving.

**Look it up.** Open SP 800-83 and find what it says about detection based on
files against detection based on behaviour. The distinction it draws is older than
the product category names and clearer than most of them.

## What trips people up

### 1. Expecting network controls to see a USB copy

Nothing crosses the network, so nothing observes it. The firewall logs are clean
and would have been clean in every scenario, which is why an empty log is not
evidence.

### 2. Deploying content detection without a second check

Four sixteen-digit strings in one short document, one of them a card number. The
checksum removes three false positives for free, and anything without a check
digit has no equivalent and a structurally worse rate.

### 3. Buying DLP as protection against insiders

It stops the careless mistake and creates a record. Compression, encryption,
retyping or a photograph defeat content matching entirely, and none of those
requires skill.

### 4. Expecting antivirus to catch what never becomes a file

It examines files. A script interpreted in memory or a system tool misused writes
nothing to scan, which is the gap behavioural recording covers.

### 5. Judging a behavioural tool in its first month

It has no baseline, so everything is a departure. It also needs an entity worth
modelling, and a shared service account has no personal behaviour to learn.

### 6. Assuming file access is being recorded

On the Windows machine above, File System auditing reports `No Auditing`, which is
the default. On macOS the live stream is not retained at all. Both are
configuration states rather than gaps in the platforms.

## Work it through

A customer export left the company. You have EDR on laptops, a mail gateway, a web
proxy, and no DLP anywhere. You have been asked to make sure it does not happen
again, and there is budget for one thing.

**The tempting move is to buy DLP.** It is the product named after the problem, a
vendor will demonstrate it catching exactly this file, and it will genuinely stop
the next careless version of it. It will also take a quarter to tune, generate
false positives from every document with a reference number in it, and be defeated
by anybody who compresses the file.

**The move that works starts with the route rather than the product.** Find out
how this one left. If it went to a personal cloud service, the proxy already saw
the connection and nobody was looking, and the fix is a rule and a report rather
than a purchase. If it went on a USB stick, the EDR you already own can record and
in most cases block removable media, which is a configuration change.

**Then the budget goes to whichever route is left uncovered.** That is a decision
you can defend, because it names the gap rather than the category.

**What this rejects is buying the named product first.** DLP is likely to be right
eventually and it is the second purchase, after you know which routes are already
covered by things you own and are not using. Buying it first is how organisations
end up with three overlapping controls on the email route and nothing on removable
media.

The residual to write down: none of this covers the photograph, and none of it
covers somebody with legitimate access taking what they are entitled to see. The
controls for those are access scope and the ones that are about people, and
saying so plainly at the start is better than being asked after the next incident
why the tooling did not stop it.

## Try it

**Verify a package.** `rpm -V bash` or `dpkg -V coreutils`. Silence means every
file matches. Then change something and read the flag string.

**Run a pattern against a real document.** Take any document you have and search
it for sixteen-digit strings. Count the matches, then count how many are actually
card numbers. The ratio is what a content detector deals with.

**Ask whether file access is recorded.** `auditpol /get /subcategory:"File System"`
on Windows or `auditctl -l` on Linux. On most machines the answer is that nothing
is watching.

**Check what your endpoint tool retains.** Not what it detects: what it keeps, and
for how long. A tool that records process activity for seven days answers
different questions from one that keeps thirty.

## Check yourself

<details class="qa">
<summary>A file left on a USB stick and the firewall logs are clean. What does that tell you?</summary>

Nothing about whether data left. The copy produced no network traffic, so the
firewall had nothing to log and its logs would look identical if nothing had
happened at all.

That structural blind spot is why endpoint controls exist. The control that would
have seen it is an agent on the machine, and the control that would have prevented
it is a device policy.

</details>

<details class="qa">
<summary>Why does content detection need a second check after the pattern match?</summary>

Because the pattern is a shape and many things share it. In the capture on this
page, four sixteen-digit strings matched and three were a phone number, a
reference number and an employee identifier.

A card number carries a check digit, so arithmetic removes most false matches for
free. Identifiers without a check digit have no equivalent, so detection falls
back on surrounding context and the false positive rate is structurally worse.

</details>

<details class="qa">
<summary>What does EDR examine that antivirus does not?</summary>

Behaviour rather than files. It records processes starting, what started them,
what they opened and connected to, and detections are written against sequences.

The gap it covers is the technique that never becomes a file: a script interpreted
in memory, a legitimate system tool used for something else, code injected into
another process. A scanner that examines files has nothing to scan in any of those
cases.

</details>

<details class="qa">
<summary>What does rpm -V actually verify, and what are its two limits?</summary>

Each installed file against the hash, size, permissions, ownership, timestamp and
other attributes recorded when the package was installed. The flag string names
which of those differ.

It covers only files a package installed, so application data and anything in
`/opt` is outside it. And the reference database is on the same machine, so an
attacker with root can update it, which is the general weakness of any integrity
check whose reference copy is local.

</details>

<details class="qa">
<summary>Which exfiltration route is invisible to every technical control, and what does that imply?</summary>

Photographing the screen. No product on this exam addresses it, and it requires no
skill.

What follows is that the controls in this objective are good at the ordinary case,
which is careless movement of data or an intruder using a machine, and are not a
defence against a determined person with legitimate access. The answers there are
reducing how much any one person can see at once, and controls that are about
people rather than machines.

</details>

## References

- [SP 800-137](https://csrc.nist.gov/pubs/sp/800/137/final) - NIST, continuous monitoring, for where endpoint data fits in a monitoring programme. Free. Accessed 2026-08-25.
- [SP 800-83 Rev. 1](https://csrc.nist.gov/pubs/sp/800/83/r1/final) - NIST, malware incident prevention and handling, for file-based against behaviour-based detection. Free. Accessed 2026-08-25.
- [rpm(8)](https://man7.org/linux/man-pages/man8/rpm.8.html) - the verify flags and what each position means. Free. Accessed 2026-08-25.
- [Get-FileHash](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/get-filehash) - Microsoft, for the Windows hashing route and its lack of a local reference. Free. Accessed 2026-08-25.
- [RFC 4949](https://www.rfc-editor.org/rfc/rfc4949.html) - IETF, the internet security glossary, for the vocabulary this topic uses across several product categories. Free. Accessed 2026-08-25.

**Where the content came from.** The integrity block is captured from an AlmaLinux
10.2 container, with the configuration file modified during the capture so the
before and after are the same machine seconds apart. The content detection block
runs a real Luhn implementation over a document written for the topic, and the
numbers in it are the published test values every payment processor documents for
this purpose, so nothing on this page is anybody's card. Nothing here exfiltrates
anything: the four routes in the figure are described and the captures show the
detection side, because demonstrating the routes would mean moving data rather
than showing evidence of it. The Windows and macOS blocks are from disposable
runners.

**If you also work on Linux.** The Linux+ track's
[compliance, auditing and integrity](/learn/linux-plus/compliance-auditing-and-integrity)
covers the verification mechanics in detail, including what each flag position
means and how to read a change during an incident.
