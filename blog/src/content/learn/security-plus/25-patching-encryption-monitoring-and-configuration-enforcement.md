---
title: "Patching, encryption, monitoring and configuration enforcement"
description: "A configuration file with an unchanged hash and a service that now offers weaker ciphers, a package manager that detects drift and refuses to correct it, and a TLS handshake with the destination name sitting in the clear."
deck: "The configuration was correct in January. Nobody changed it, and it is wrong now"
track: "security-plus"
level: "working"
order: 260
objectives:
  - "Explain how a configuration drifts with no change to the file that holds it"
  - "Distinguish detecting drift from correcting it"
  - "State what patching costs and what the cost buys"
  - "Say what encryption mitigates and what it leaves visible"
  - "Explain why monitoring prevents nothing and is still worth the money"
  - "Say what a decommissioned system still holds"
prerequisites: ["segmentation-isolation-and-access-control"]
tags: ["security-plus", "security", "mitigation", "configuration"]
updated: 2026-08-26
draft: false
examObjectives:
  - exam: "sy0-701"
    domain: "2.0"
    objective: "2.5"
sources:
  - title: "SP 800-128, Guide for Security-Focused Configuration Management of Information Systems"
    url: "https://csrc.nist.gov/pubs/sp/800/128/upd1/final"
    publisher: "NIST"
    accessed: 2026-08-26
    tier: 1
  - title: "SP 800-40 Rev. 4, Guide to Enterprise Patch Management Planning"
    url: "https://csrc.nist.gov/pubs/sp/800/40/r4/final"
    publisher: "NIST"
    accessed: 2026-08-26
    tier: 1
  - title: "RFC 6066, TLS Extensions: Extension Definitions"
    url: "https://www.rfc-editor.org/rfc/rfc6066.html"
    publisher: "IETF"
    accessed: 2026-08-26
    tier: 1
  - title: "SP 800-88 Rev. 1, Guidelines for Media Sanitization"
    url: "https://csrc.nist.gov/pubs/sp/800/88/r1/final"
    publisher: "NIST"
    accessed: 2026-08-26
    tier: 1
symptoms:
  - symptom: "A setting is wrong and the file holding it has not been edited"
    anchor: "the-configuration-nobody-changed"
  - symptom: "An encrypted service is still leaking who talks to it"
    anchor: "what-encryption-mitigates-and-what-it-does-not"
---

> **Before you read.** An auditor asks why a server accepts a cipher your policy
> forbids. You check the file. It has not been edited: the hash matches the one
> recorded at the last review, the modification time is the day the package was
> built, and the change management system has no ticket touching this host.
>
> **Where did the setting come from?**

From somewhere else. A configuration file is not a configuration; it is one input
to one. Anything the service reads at start-up, inherits from a system-wide policy,
receives from a management system or takes as a default is equally part of the
answer, and only one of those things is the file you are looking at.

This topic covers four mitigations that are grouped together in the objective and
have almost nothing in common, plus the one everybody leaves out.

### Some words you will need

<dl class="terms">
<dt>configuration drift</dt>
<dd>A system's actual state moving away from its intended state over time.</dd>
<dt>configuration enforcement</dt>
<dd>Something that periodically compares actual against intended and corrects the difference.</dd>
<dt>baseline</dt>
<dd>The intended state, written down somewhere a machine can read.</dd>
<dt>effective configuration</dt>
<dd>What a service is actually running with, after every input has been combined.</dd>
<dt>patching</dt>
<dd>Replacing code with a newer version, usually to remove a defect.</dd>
<dt>decommissioning</dt>
<dd>Taking a system out of service properly, which includes what happens to its data.</dd>
<dt>metadata</dt>
<dd>Everything about a message other than its contents. Rarely encrypted.</dd>
</dl>

## The configuration nobody changed

Drift sounds like a slow process caused by careless people. Some of it is. The
awkward kind happens instantly, correctly, and to a file nobody has opened.

<details class="predict">
<summary>A service configuration file, untouched for months. Somebody changes a system-wide setting elsewhere. Predict what happens to the file and to the service.</summary>

```bash
# AlmaLinux 10.2, x86_64
$ policy-drift
in January
  sha256 of /etc/ssh/sshd_config  a7329525af126b82
  mtime of the same file          2026-07-29 00:00:00
  ciphers the service will offer  5
  system-wide policy in force     DEFAULT

somebody sets the system-wide policy, on a different day, for a different reason:

in March
  sha256 of /etc/ssh/sshd_config  a7329525af126b82
  mtime of the same file          2026-07-29 00:00:00
  ciphers the service will offer  7
  system-wide policy in force     LEGACY

the ciphers the service now offers that it did not offer before:
  aes128-cbc
  aes256-cbc
```

**The file is byte for byte identical and the service now offers two ciphers it
previously refused.**

The hash matches. The modification time matches. Every integrity check you could
run against that file passes, and the effective configuration of the service has
changed, because the file includes a system-wide policy and somebody set the policy
to something looser.

That is the shape of the cold open. Nothing about the change is hidden or
malicious: it is a supported mechanism, deliberately designed so a single decision
about cryptography applies across every service on the machine. It works in both
directions and the direction here happened to be worse.

**Which invalidates the obvious control.** Watching configuration files for
modification catches the case where somebody edits a file, and it is blind to this.
The thing worth recording at review time is not the file but what the service
reports it will actually do, which is a different command and usually a longer
output.

</details>

<details class="deeper">
<summary>Why drift happens when nobody changed anything, and the five sources worth knowing</summary>

If drift were only careless edits it would be solved by discipline. It is not, and
the sources have different fixes.

**Package updates change defaults.** A new version of a service ships with a
different default for a setting your file does not mention. You never set it, so
you inherit the new value, and the release notes that mentioned it were read by
nobody.

**System-wide policies change many things at once**, which the capture above shows.
This is a feature, and the surprise is only ever about scope: the person who set it
was thinking about one service.

**Somebody fixed an outage.** At two in the morning, correctly, and the fix was
never written down because the outage was the emergency and the paperwork was not.
This is the most common single cause and the one nobody puts on a diagram.

**Something else manages the machine.** An agent, an inventory tool, a management
platform, each reconciling its own idea of correct on its own schedule. Two of them
with different intentions produce a setting that oscillates, which is diagnosed
much later than it should be because the value is correct whenever anybody looks.

**And the intended state changed rather than the system.** The policy was updated,
the baseline was not, and the machine has drifted without moving. This one is worth
naming separately because the remediation is to edit a document, and no amount of
scanning finds it.

**The consequence for practice** is that a drift programme with no owner for the
baseline is measuring against a fiction. The scanning is the easy half.

</details>

## Detecting drift and correcting it are different jobs

Most systems can tell you something has changed. Far fewer will put it back, and
the ones that will not are frequently assumed to.

<details class="predict">
<summary>A file installed by the package manager, edited by hand. Predict whether the package manager notices, and whether reinstalling the package undoes it.</summary>

```bash
# AlmaLinux 10.2, x86_64
$ package-drift
before anybody touches it:
  rpm -V reports nothing

one line is appended to /etc/chrony.conf by hand:
  S.5....T.  c /etc/chrony.conf

asking the package manager to reinstall the package:
  S.5....T.  c /etc/chrony.conf

what it left on disk instead:
  /etc/chrony.conf
  last line of the live file: # added at some point by somebody
```

**It notices immediately and reinstalling changes nothing.**

The verification output names the file, flags the size and checksum as different
and the modification time as changed, and marks it as configuration. All of that is
detection working exactly as intended, and it took no setup.

Then the reinstall leaves the edit in place, which is not a bug. A package manager
that overwrote local configuration during an update would destroy every deliberate
change on every machine it touched, so it deliberately refuses, and the last line
confirms the hand-written line survived.

**So the package database is a detector and not an enforcer**, and treating a clean
verification report as evidence of a correct configuration is a category error
twice over. It says nothing about files no package owns, which is most of what
matters, and it says nothing about the effective configuration, which the previous
capture showed can change while every file passes.

</details>

<figure class="learn-figure">
<svg viewBox="0 0 720 300" role="img" aria-labelledby="drift-title" style="width:100%;height:auto;">
<title id="drift-title">A year of configuration drift accumulating in four steps with no change events recorded against any of them, and an enforcement run returning the system to its baseline</title>
<g fill="currentColor">
<text x="14" y="20" font-size="11">a year of drift on one machine, and the change record for the same year</text>
<text x="14" y="42" font-size="9" fill-opacity="0.85">four changes to the effective configuration, none of them an edit anybody made to a file</text>
<text x="14" y="130" font-size="9" fill-opacity="0.8">distance from</text>
<text x="14" y="144" font-size="9" fill-opacity="0.8">intended state</text>
<path d="M 150 190 H 240 V 163 H 330 V 136 H 465 V 109 H 555 V 82 H 600" fill="none" stroke="var(--red)" stroke-width="1.8"/>
<path d="M 600 82 V 190 H 690" fill="none" stroke="var(--accent)" stroke-width="1.8"/>
<text x="244" y="158" font-size="8" fill="var(--red)" fill-opacity="0.95">1</text>
<text x="334" y="131" font-size="8" fill="var(--red)" fill-opacity="0.95">2</text>
<text x="469" y="104" font-size="8" fill="var(--red)" fill-opacity="0.95">3</text>
<text x="559" y="77" font-size="8" fill="var(--red)" fill-opacity="0.95">4</text>
<text x="604" y="100" font-size="8" fill="var(--accent)" fill-opacity="0.95">5</text>
<line x1="150" y1="190" x2="690" y2="190" stroke="currentColor" stroke-opacity="0.4" stroke-width="1"/>
<text x="150" y="206" font-size="8" text-anchor="middle" fill-opacity="0.7">Jan</text>
<text x="285" y="206" font-size="8" text-anchor="middle" fill-opacity="0.7">Apr</text>
<text x="420" y="206" font-size="8" text-anchor="middle" fill-opacity="0.7">Jul</text>
<text x="555" y="206" font-size="8" text-anchor="middle" fill-opacity="0.7">Oct</text>
<text x="645" y="206" font-size="8" text-anchor="middle" fill-opacity="0.7">Dec</text>
<rect x="150" y="228" width="540" height="22" rx="2" fill="currentColor" fill-opacity="0.07"/>
<text x="14" y="243" font-size="9" fill-opacity="0.8">changes recorded</text>
<text x="160" y="243" font-size="8.5" fill-opacity="0.75">not one, all year</text>
<text x="14" y="272" font-size="9" fill-opacity="0.85">1 a package update changed a default.  2 a system-wide policy was set elsewhere.</text>
<text x="14" y="288" font-size="9" fill-opacity="0.85">3 somebody fixed an outage at 2am.  4 a new release changed a default.  5 the enforcement run.</text>
</g></svg>
<figcaption>The drift is real and the change record is empty, because none of the four steps was a change to this machine in any sense the change process recognises. Two came from packages, one from a decision made about a different service, and one from a person solving an urgent problem correctly at an hour when writing it down was the lowest priority in the room. The enforcement run at step five is the only thing on the drawing that returns the line to the baseline, and note where it starts from: it has to compare against a written statement of intent, so an organisation without one has nothing to run.</figcaption>
</figure>

**The enforcement half needs three things** and the missing one is usually the
second. A written baseline a machine can read. A schedule on which something
compares against it. And a decision, made in advance, about what happens when the
comparison fails, because a tool that reports differences forever is a detector
with a scheduler attached.

<details class="deeper">
<summary>The patch that breaks the application, and the decision that actually follows</summary>

Patching is the mitigation with the clearest security case and the worst reputation
among the people who have to do it, and the reason is that its cost is concentrated
and its benefit is diffuse.

**The cost is an outage window and a risk of breakage**, both of which land on a
named team on a named night. The benefit is a vulnerability that now cannot be
exploited, which nobody experiences. That asymmetry is why patching slips, and no
amount of explaining the security case changes the arithmetic for the person
holding the pager.

**When a patch does break the application, there are four options** and only one of
them is usually considered. Roll back and stay exposed, which is the default and
frequently becomes permanent. Fix the application, which is correct and slow.
Compensate around it, by restricting who can reach the vulnerable path until the
fix lands. Or replace the component, which is the honest answer when the
application only works on a version nobody supports.

**The option worth defending is compensation**, because it is the only one that
addresses the exposure on the same timescale as the discovery. It also requires
somebody to write down that it is temporary, with a date, or it becomes the third
permanent workaround on a system nobody wants to touch.

**And there is a version of this that is not a technical decision at all.** A
vendor appliance whose patch cadence is quarterly, or whose support contract makes
patching the vendor's job, moves the whole question into a commercial relationship.
The exposure is still yours and the remedy is not, which is worth stating plainly
in a risk register rather than filed as a technical constraint.

</details>

## What encryption mitigates, and what it does not

Encryption is the mitigation people are most confident about and the one whose
boundary is least examined. The boundary is easy to see if you look at the packets.

<details class="predict">
<summary>One TLS connection, recorded. Predict what an observer who cannot decrypt any of it still learns.</summary>

```bash
# AlmaLinux 10.2, aarch64
$ in-the-clear
bytes captured: 6121

searching the captured packets for the name the client asked for:
  occurrences of the hostname in the clear: 1
  found: "finance-reporting.internal.example

and for the body of the request, which was sent after the handshake:
  occurrences of the message text in the clear: 0
```

**The destination name, in plain text, once, in the first packet. The message,
never.**

The body of the request is not in the capture at all, which is the mitigation
working. Everything after the handshake is unreadable to the observer, and that is
the whole of what transport encryption was asked to do.

The hostname is a different matter. It is sent in the opening message, before any
key exists, because the server needs to know which certificate to present and
cannot know until it is told. The extension carrying it is defined in the clear by
design, and the consequence is that an observer learns exactly which service was
contacted while learning nothing about what was said.

**Which is the general rule worth carrying.** Encryption protects contents. It
leaves the participants, the timing, the volume and the pattern, and for a great
many investigations those four are the answer. A connection to a service whose name
gives away what it is, at three in the morning, moving a hundred times the usual
volume, is a finding that never required decrypting anything.

</details>

**And encryption does nothing at all against three things** worth naming because
people expect otherwise. It does not protect data from a process that holds the
key, which is every application that uses the data. It does not stop a valid
message being sent again, which is the replay material in topic 21. And it does not
help once the endpoint is compromised, because the endpoint is where the plaintext
is by definition.

<details class="deeper">
<summary>What a decommissioned system still holds, and why this is the mitigation everybody skips</summary>

Decommissioning appears in this objective next to the mitigations and gets treated
as an administrative chore, which is how systems end up holding data years after
anybody uses them.

**A system that is switched off is still a system.** It holds its data, its stored
credentials, its certificates, its keys, its cached copies of other systems' data,
and its network trust, which is the one people forget. The service accounts it used
still exist and still work, and the firewall rules that let it reach things are
still in place, so a decommissioned host powered back on lands in a network
configured to trust it.

**The data half has a defined answer** and it is worth using the vocabulary from
topic 44: clear, purge or destroy, chosen by how sensitive the data is and what the
media is, with a record of what was done to which asset. The record is the part
that gets skipped and the part an auditor asks for.

**The access half has no equivalent standard and is where the risk actually sits.**
Removing a host means removing its accounts, revoking its certificates, deleting
its rules, and taking its name out of whatever still resolves it. Each of those is
somebody else's system, which is why the work fragments and why the last two
usually do not happen.

**The encryption connection is the reason this sits in this topic.** If the storage
was encrypted and the key is destroyed with the system, the sanitisation problem
gets much smaller, which is the strongest operational argument for encrypting
things that were never obviously sensitive. It only works if the key was genuinely
unique to that system, and on a fleet built from one image that is worth checking
rather than assuming.

**And the mitigation that is skipped most often is the simplest.** A system nobody
uses is still an attack surface, still needs patching, and still appears in your
scan results as an exception somebody dismisses each quarter. Turning it off is a
security control with a positive return, and it is filed as housekeeping.

</details>

## Monitoring, which prevents nothing

Monitoring is in this list with three controls that stop things, and it stops
nothing. It is worth being blunt about that, because the confusion produces bad
spending decisions in both directions.

**A monitoring system observes and reports.** Every attack it sees, it sees while
the attack is working. Nothing it does makes the next packet fail. The mitigation
is entirely downstream: a person or an automation reacts, and the value is the time
between the event and that reaction.

**Which makes the useful measure a duration rather than a count.** How long from
the thing happening to somebody knowing. A platform that generates four hundred
alerts a day and a mean time to acknowledge of three days is worse than a smaller
one with ten alerts and twenty minutes, and the first will look better in every
report anybody writes about it.

**And it is still the control worth buying first** in most estates, for a reason
that has nothing to do with detection: it is the only one on this page that tells
you whether the others are working. Segmentation you cannot see is a diagram.
Patching you cannot verify is a schedule. The evidence for every other mitigation
comes out of the monitoring, which is a stronger argument than the one usually made
for it.

## Across platforms

Whether a machine can compare itself against an intended state, and whether it will
correct the difference, has three different answers.

**Windows ships both halves and neither is doing anything here.**

```powershell
# Microsoft Windows Server 2025 Datacenter, version 10.0.26100.0
> Get-DscLocalConfigurationManager -ErrorAction SilentlyContinue | Select-Object ConfigurationMode, ConfigurationModeFrequencyMins, RefreshMode, RebootNodeIfNeeded | Format-List
ConfigurationMode              : ApplyAndMonitor
ConfigurationModeFrequencyMins : 15
RefreshMode                    : PUSH
RebootNodeIfNeeded             : False

# Whether it has ever applied a configuration to this machine
> $s = @(Get-DscConfigurationStatus -All -ErrorAction SilentlyContinue); if ($s.Count) { $s | Select-Object -First 3 Status, StartDate, Type | Format-Table -AutoSize } else { 'no configuration has ever been applied by it' }
no configuration has ever been applied by it

# Whether the security settings here match a stored template, asked by the tool built for that comparison
> secedit /export /cfg "$env:TEMP\base.inf" > $null; (Get-Content "$env:TEMP\base.inf" | Measure-Object -Line).Lines.ToString() + ' lines exported as the current baseline'; secedit /analyze /db "$env:TEMP\drift.sdb" /cfg "$env:TEMP\base.inf" /log "$env:TEMP\drift.log" /quiet 2>&1 | Out-Null; (Select-String -Path "$env:TEMP\drift.log" -Pattern 'Mismatch' -ErrorAction SilentlyContinue).Count.ToString() + ' settings differ from it'
126 lines exported as the current baseline
0 settings differ from it

# Which group policies applied here, since an effective setting can arrive from somewhere other than this machine
> gpresult /r /scope:computer 2>&1 | Select-String -Pattern 'Applied Group Policy Objects' -Context 0,2 | ForEach-Object { $_.ToString().Trim() }
>     Applied Group Policy Objects
      -----------------------------
          N/A
```

The declarative engine is present and set to apply and monitor on a fifteen minute
cycle, and it has never been given a configuration, so the cycle runs against
nothing. The security comparison tool exports a hundred and twenty six lines of
current settings and reports zero differences, which is what happens when you
compare a machine against itself: the answer is arithmetically correct and tells
you nothing, because the baseline was generated from the thing being measured. That
is the shape of a great many drift programmes.

**macOS has one mechanism and it comes from outside the machine.**

```bash
# macOS 26.5.2, arm64
$ out=$(sudo profiles list -all 2>&1); printf '%s\n' "${out:-nothing returned}" | head -4
There are no configuration profiles installed

# Whether this machine is enrolled in management at all, which is what would push one
$ profiles status -type enrollment 2>&1
Enrolled via DEP: No
MDM enrollment: No

# Whether the managed preference store holds anything, which is where a profile's settings land
$ out=$(sudo ls -1 "/Library/Managed Preferences" 2>&1); printf '%s\n' "${out:-nothing in the managed preference store}" | head -4
nothing in the managed preference store

# What one setting reads as locally, with nothing managing it
$ defaults read /Library/Preferences/com.apple.SoftwareUpdate 2>&1 | head -5
{
    AutoUpdate = 0;
    AutoUpdateRestartRequired = 0;
    AutomaticDownload = 0;
    AutomaticallyInstallMacOSUpdates = 0;
```

No profiles are installed, the machine is not enrolled in management, and the
managed preference store is empty. So the local settings in the last block are the
whole configuration, held nowhere else, compared against nothing, and reapplied by
nobody. On a managed Mac a profile would supply all three, which makes the drift
answer for this platform a question about the management system rather than about
the operating system.

**Linux has the detection half only**, as the package capture shows, and it covers
files a package owns. Everything else requires a configuration management tool that
somebody has to install, populate and schedule.

**Which gives the comparison one sentence.** All three platforms can tell you
something about drift and none of them is doing it by default, so on any machine
you have not deliberately configured, the honest answer to "has this drifted" is
that nobody knows.

## Try it

**Compare a file against an effective configuration.** Take any service that can
print what it will actually run with, and compare that against its configuration
file. Count the settings present in one and not the other.

**Edit a packaged file and ask the package manager.** One line appended, one
verification command, and you have seen both the detection and its limits.

**Look for a name in a handshake.** Record a connection to a service you run and
search the bytes for the hostname. The body will not be there and the name will.

**Find one decommissioned system that still has access.** Look for accounts,
certificates or rules belonging to something that no longer exists. There is
usually at least one, and it is the cheapest finding available.

## Check yourself

<details class="qa">
<summary>How can a configuration change with no change to the configuration file?</summary>

Because the file is one input among several. The capture on this page changes a
system-wide cryptographic policy, leaves the service's file byte for byte identical
with the same modification time, and the service then offers two CBC ciphers it
previously refused.

The control that catches file edits is blind to this, so what belongs in a review
record is what the service reports it will actually do rather than the contents of
its file.

</details>

<details class="qa">
<summary>Does a package manager enforce configuration?</summary>

No. It detects. The capture shows a hand-edited file flagged immediately by
verification, with size, checksum and modification time all reported as different,
and the same flag still present after the package is reinstalled.

That refusal is deliberate, since a package manager that overwrote local
configuration during updates would destroy every intentional change on every
machine. Enforcement needs a separate tool with a baseline to compare against.

</details>

<details class="qa">
<summary>What does an observer learn from an encrypted connection?</summary>

The destination name, from the opening message of the handshake, plus the
participants, the timing, the volume and the pattern. The capture on this page
finds the hostname once in the recorded packets and the message body not at all.

The name travels in the clear because the server must know which certificate to
present before any key exists. For many investigations the metadata is sufficient
and nothing needs decrypting.

</details>

<details class="qa">
<summary>Why is monitoring in a list of mitigations when it prevents nothing?</summary>

Because the mitigation is downstream of it: a person or an automation reacts, and
what the monitoring buys is the time between the event and that reaction. The
useful measure is therefore a duration rather than a count of alerts.

It is also the only control that produces evidence about the others. Segmentation
you cannot see is a diagram and patching you cannot verify is a schedule, so the
monitoring is where the proof for both comes from.

</details>

<details class="qa">
<summary>What does a decommissioned system still hold?</summary>

Its data, its stored credentials, its certificates and keys, and its place in
everybody else's trust: service accounts that still work, firewall rules that still
permit it, and names that still resolve to it.

The data half has defined answers in the sanitisation vocabulary, chosen by
sensitivity and media, with a record. The access half has no equivalent standard,
lives in other people's systems, and is the part that does not get done.

</details>

## References

- [SP 800-128](https://csrc.nist.gov/pubs/sp/800/128/upd1/final) - NIST, security-focused configuration management, for baselines and what a change process has to cover. Free. Accessed 2026-08-26.
- [SP 800-40 Rev. 4](https://csrc.nist.gov/pubs/sp/800/40/r4/final) - NIST, enterprise patch management planning, including the case for treating patching as routine maintenance. Free. Accessed 2026-08-26.
- [RFC 6066](https://www.rfc-editor.org/rfc/rfc6066.html) - IETF, the TLS extension that carries the server name, which is the one in the capture. Free. Accessed 2026-08-26.
- [SP 800-88 Rev. 1](https://csrc.nist.gov/pubs/sp/800/88/r1/final) - NIST, media sanitisation, for the decommissioning vocabulary and the record it expects. Free. Accessed 2026-08-26.

**Where the content came from.** The policy and package blocks are captured from an
AlmaLinux 10.2 container, which changes a system-wide policy and edits one file it
owns; both changes live and die with the container. The packet capture block runs
privileged so that a packet sniffer can attach to the container's own loopback
interface, which forces the virtual machine's architecture and is why that block is
labelled aarch64 while the other two are amd64. Both ends of that connection are in
the same container, the certificate is generated for it and discarded with it, and
nothing crosses a network. The Windows and macOS blocks come from disposable
runners and read only.

**If you also work on Linux.** The Linux+ track's
[packages, repositories and signing](/learn/linux-plus/packages-repositories-and-signing)
covers package verification and what the database does and does not record.
