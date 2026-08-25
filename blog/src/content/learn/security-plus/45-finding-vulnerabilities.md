---
title: "Finding vulnerabilities"
description: "Six ways to discover a vulnerability and what each one is blind to, why a credentialed scan and an uncredentialed one disagree about the same patched server, what a threat feed is worth without enrichment, and the finding count that means the scanner is misconfigured."
deck: "The scanner found four thousand findings on a network of two hundred machines"
track: "security-plus"
level: "working"
order: 460
objectives:
  - "Name the discovery methods in this objective and say what each one can see"
  - "Explain why a credentialed scan and an uncredentialed one disagree"
  - "Read a package advisory list and say what it proves about a machine"
  - "Say what a threat feed contributes and what it cannot tell you"
  - "Distinguish a penetration test from a scan by what each one establishes"
  - "Recognise a finding count that indicates a misconfigured scan"
prerequisites: ["secure-baselines"]
tags: ["security-plus", "security", "operations", "vulnerability-management"]
updated: 2026-08-25
draft: false
examObjectives:
  - exam: "sy0-701"
    domain: "4.0"
    objective: "4.3"
sources:
  - title: "SP 800-115, Technical Guide to Information Security Testing and Assessment"
    url: "https://csrc.nist.gov/pubs/sp/800/115/final"
    publisher: "NIST"
    accessed: 2026-08-25
    tier: 1
  - title: "SP 800-40 Rev. 4, Guide to Enterprise Patch Management Planning"
    url: "https://csrc.nist.gov/pubs/sp/800/40/r4/final"
    publisher: "NIST"
    accessed: 2026-08-25
    tier: 1
  - title: "SP 800-216, Recommendations for Federal Vulnerability Disclosure Guidelines"
    url: "https://csrc.nist.gov/pubs/sp/800/216/final"
    publisher: "NIST"
    accessed: 2026-08-25
    tier: 1
  - title: "CVE Program"
    url: "https://www.cve.org/"
    publisher: "MITRE"
    accessed: 2026-08-25
    tier: 1
  - title: "Get-HotFix reference"
    url: "https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.management/get-hotfix"
    publisher: "Microsoft"
    accessed: 2026-08-25
    tier: 1
symptoms:
  - symptom: "A scanner reports a vulnerability the vendor says is already patched"
    anchor: "the-same-server-answered-six-ways"
  - symptom: "A scan returns thousands of findings on a small network"
    anchor: "the-count-that-means-the-scan-is-wrong"
---

> **Before you read.** A scan of two hundred machines returns four thousand
> findings. The person who ran it presents the number as a measure of how much
> work there is.
>
> **What are the two most likely explanations, and which one would you check
> first?**

Twenty findings per machine is either a genuinely neglected estate or a scan
configured to report things that are not true. Telling those apart is most of what
this topic is about, and the mechanism behind the second one is worth seeing
rather than being told.

### Some words you will need

<dl class="terms">
<dt>credentialed scan</dt>
<dd>A scan that logs in and reads the machine's own record of what is installed.</dd>
<dt>uncredentialed scan</dt>
<dd>A scan from outside, inferring what is installed from what the machine says over the network.</dd>
<dt>backport</dt>
<dd>Applying a fix to an older version without changing the version number it reports.</dd>
<dt>package monitoring</dt>
<dd>Watching a dependency or package list against a feed of known vulnerabilities.</dd>
<dt>threat feed</dt>
<dd>A stream of information about vulnerabilities, actors or indicators, published by somebody else.</dd>
<dt>OSINT</dt>
<dd>Open-source intelligence. Information gathered from public sources.</dd>
<dt>penetration test</dt>
<dd>An authorised attempt to reach something, which establishes exploitability rather than presence.</dd>
<dt>responsible disclosure</dt>
<dd>Reporting a vulnerability to whoever can fix it, with an agreed period before publication.</dd>
<dt>bug bounty</dt>
<dd>Paying for those reports, under published rules about scope and conduct.</dd>
</dl>

## What breaks without this

**A scan's output is treated as a fact about the machines.** It is a fact about
the scan, and the two differ most on exactly the systems where accuracy matters.

**The same vulnerability is reported and dismissed forever.** The scanner says
vulnerable, the system owner says patched, both produce evidence, and the
disagreement is never resolved because nobody knows which one is measuring what.

**A feed is bought and nothing changes.** Indicators arrive, nothing is enriched
with what the organisation actually runs, and the feed becomes a subscription
somebody renews.

**A penetration test is used as a vulnerability scan.** It is a much more
expensive way to get a much shorter list, and the value of what it does establish
gets lost.

## The same server, answered six ways

Here is one machine running one web server. Nothing about it is unusual.

```bash
# AlmaLinux 10.2, x86_64
$ dnf -q -y install nginx curl >/dev/null 2>&1; nginx 2>/dev/null; sleep 2; echo "what a scanner without credentials sees:"; curl -sI http://127.0.0.1/ | grep -i "^server"; echo; echo "what a scanner with credentials sees:"; rpm -q nginx; echo; echo "and what the package changelog says was fixed in it:"; rpm -q --changelog nginx 2>/dev/null | grep -i -m3 "CVE\|security"
what a scanner without credentials sees:
Server: nginx/1.26.3

what a scanner with credentials sees:
nginx-1.26.3-6.el10_2.6.x86_64

and what the package changelog says was fixed in it:
  modification or denial of service (CVE-2026-56434)
  in ngx_http_slice_module (CVE-2026-60005)
  headers (CVE-2026-42055)
```

**Read the two version strings against each other.** From outside, the server
announces `nginx/1.26.3`. From inside, the package is
`nginx-1.26.3-6.el10_2.6`, and the changelog names three CVEs that release fixed.

Upstream nginx 1.26.3 has those vulnerabilities. This machine does not, because
the distribution took the fixes and applied them to 1.26.3 without moving to a
newer upstream version. The part after the dash is where the entire history of
that backporting lives, and it is invisible over the network.

<details class="predict">
<summary>An uncredentialed scanner checks that banner against its vulnerability database. Predict what it reports, and whether the report is a false positive or a true one.</summary>

**It reports three vulnerabilities, and all three are false positives.**

The scanner is not malfunctioning. It did the only thing available to it: read a
version, look it up, and report what is known about that version. Upstream 1.26.3
really does have those CVEs, so the lookup is correct and the conclusion about
this machine is wrong.

That is the shape of most disagreement between a security team and a system
owner on enterprise Linux. The scanner's report is accurate about the version
string. The owner's `rpm -q` is accurate about the machine. Both parties have
evidence, both are right about what they measured, and the argument continues
until somebody explains backporting.

The practical consequence is worth stating as a number rather than a principle. On
a machine with a hundred packages, an uncredentialed scan can produce dozens of
these, and dismissing them one at a time consumes the time that should have gone
to the real findings. That is the four thousand from the top of this page.

The fix is credentials, not a better scanner. Nothing readable over the network
distinguishes a patched 1.26.3 from an unpatched one, so no amount of remote
cleverness recovers the answer.

</details>

<figure class="learn-figure">
<svg viewBox="0 0 720 306" role="img" aria-labelledby="find-title" style="width:100%;height:auto;">
<title id="find-title">Six discovery methods asked the same question about one patched server, with the two that answer correctly, the one that answers wrongly, and the three that cannot see it at all</title>
<g fill="currentColor">
<text x="14" y="20" font-size="11">one server running a patched nginx 1.26.3, asked six different ways</text>
<text x="170" y="46" font-size="9" fill-opacity="0.7">what it looks at</text>
<text x="392" y="46" font-size="9" fill-opacity="0.7">what it reports</text>
<text x="628" y="46" font-size="9" fill-opacity="0.7">verdict</text>
<text x="14" y="75" font-size="8.5" fill-opacity="0.9">uncredentialed scan</text>
<rect x="164" y="58" width="200" height="26" rx="3" fill="currentColor" fill-opacity="0.05" stroke="currentColor" stroke-opacity="0.5" stroke-width="1.1"/>
<text x="264" y="75" text-anchor="middle" font-size="8">reads the banner</text>
<rect x="376" y="58" width="228" height="26" rx="3" fill="var(--red)" fill-opacity="0.16" stroke="var(--red)" stroke-opacity="0.7" stroke-width="1.6"/>
<text x="490" y="75" text-anchor="middle" font-size="8">says vulnerable, wrongly</text>
<text x="620" y="75" font-size="8" fill-opacity="0.9">wrong</text>
<text x="14" y="109" font-size="8.5" fill-opacity="0.9">credentialed scan</text>
<rect x="164" y="92" width="200" height="26" rx="3" fill="currentColor" fill-opacity="0.05" stroke="currentColor" stroke-opacity="0.5" stroke-width="1.1"/>
<text x="264" y="109" text-anchor="middle" font-size="8">reads the package version</text>
<rect x="376" y="92" width="228" height="26" rx="3" fill="var(--accent)" fill-opacity="0.16" stroke="var(--accent)" stroke-opacity="0.7" stroke-width="1.6"/>
<text x="490" y="109" text-anchor="middle" font-size="8">says patched, correctly</text>
<text x="620" y="109" font-size="8" fill-opacity="0.9">right</text>
<text x="14" y="143" font-size="8.5" fill-opacity="0.9">package monitoring</text>
<rect x="164" y="126" width="200" height="26" rx="3" fill="currentColor" fill-opacity="0.05" stroke="currentColor" stroke-opacity="0.5" stroke-width="1.1"/>
<text x="264" y="143" text-anchor="middle" font-size="8">reads the advisory feed</text>
<rect x="376" y="126" width="228" height="26" rx="3" fill="var(--accent)" fill-opacity="0.16" stroke="var(--accent)" stroke-opacity="0.7" stroke-width="1.6"/>
<text x="490" y="143" text-anchor="middle" font-size="8">says fixed in -6.el10_2.6</text>
<text x="620" y="143" font-size="8" fill-opacity="0.9">right</text>
<text x="14" y="177" font-size="8.5" fill-opacity="0.9">static analysis</text>
<rect x="164" y="160" width="200" height="26" rx="3" fill="currentColor" fill-opacity="0.05" stroke="currentColor" stroke-opacity="0.5" stroke-width="1.1"/>
<text x="264" y="177" text-anchor="middle" font-size="8">reads your source</text>
<rect x="376" y="160" width="228" height="26" rx="3" fill="currentColor" fill-opacity="0.05" stroke="currentColor" stroke-opacity="0.7" stroke-width="1.1"/>
<text x="490" y="177" text-anchor="middle" font-size="8">silent, it is not your code</text>
<text x="620" y="177" font-size="8" fill-opacity="0.9">blind</text>
<text x="14" y="211" font-size="8.5" fill-opacity="0.9">penetration test</text>
<rect x="164" y="194" width="200" height="26" rx="3" fill="currentColor" fill-opacity="0.05" stroke="currentColor" stroke-opacity="0.5" stroke-width="1.1"/>
<text x="264" y="211" text-anchor="middle" font-size="8">tries the exploit</text>
<rect x="376" y="194" width="228" height="26" rx="3" fill="currentColor" fill-opacity="0.05" stroke="currentColor" stroke-opacity="0.7" stroke-width="1.1"/>
<text x="490" y="211" text-anchor="middle" font-size="8">fails, so reports nothing</text>
<text x="620" y="211" font-size="8" fill-opacity="0.9">blind</text>
<text x="14" y="245" font-size="8.5" fill-opacity="0.9">threat feed</text>
<rect x="164" y="228" width="200" height="26" rx="3" fill="currentColor" fill-opacity="0.05" stroke="currentColor" stroke-opacity="0.5" stroke-width="1.1"/>
<text x="264" y="245" text-anchor="middle" font-size="8">reads the world</text>
<rect x="376" y="228" width="228" height="26" rx="3" fill="currentColor" fill-opacity="0.05" stroke="currentColor" stroke-opacity="0.7" stroke-width="1.1"/>
<text x="490" y="245" text-anchor="middle" font-size="8">says the CVE exists somewhere</text>
<text x="620" y="245" font-size="8" fill-opacity="0.9">blind</text>
<text x="14" y="278" font-size="10" fill-opacity="0.85">the wrong answer and the three silences all come from the same fact:</text>
<text x="14" y="298" font-size="10" fill-opacity="0.85">the upstream version number did not change when the fix was backported into it</text>
</g></svg>
<figcaption>The same fact about the same machine, asked six ways. Two methods answer correctly, and both of them are looking at the package database rather than at the network. One answers wrongly, and it is the one most often run first because it needs no access. The three marked blind are not failing: static analysis has nothing to say because nginx is not your source code, a penetration test that cannot exploit a patched server correctly reports nothing, and a threat feed describes a vulnerability in the world rather than in your estate. What connects the wrong answer and the three silences is a single fact, that the upstream version number did not change when the fix was backported into it.</figcaption>
</figure>

<details class="deeper">
<summary>If you run scans: what credentials actually buy, and the reason people avoid them</summary>

A credentialed scan reads the package database, the registry, the installed
software list, the configuration files and the running services from inside. An
uncredentialed one infers all of that from what leaks over the network, which on a
hardened machine is close to nothing.

The accuracy difference is not marginal. Credentialed scanning removes almost all
of the version-inference false positives and finds a large class of things the
network never exposes: an old library on disk that nothing is currently using, a
configuration setting, a local privilege escalation, a package installed and never
started.

So why does anybody run the other kind? Three reasons, and they are all real.
Credentials on a scanner are a standing high-privilege account against the whole
estate, which is a serious thing to create and a target worth stealing. Getting
them to work across a heterogeneous estate is genuinely fiddly. And an
uncredentialed scan answers a different and legitimate question, which is what an
attacker sees from where they are standing.

The mature arrangement runs both and reads them differently. The credentialed scan
is the inventory of what needs fixing. The uncredentialed one is the exposure
report, and its value is in what it can see rather than in its vulnerability list.
Reading the second one as if it were the first is what produces the four thousand
findings.

If you are creating scanner credentials, the details that matter are that the
account is unique per scanner, that it has the least privilege the scan actually
needs rather than domain administrator, and that its use is logged somewhere the
scanner cannot edit.

</details>

## What the machine already knows

Before any scanner arrives, a Linux machine will tell you what is wrong with it,
because the package manager carries the vendor's advisory feed.

```bash
# AlmaLinux 10.2, x86_64
$ dnf -q updateinfo list --security 2>/dev/null | head -12; echo "---"; echo "total security advisories waiting on this image:"; dnf -q updateinfo list --security 2>/dev/null | wc -l
ALSA-2026:33124 Moderate/Sec.  coreutils-single-9.5-8.el10_2.x86_64
ALSA-2026:55432 Important/Sec. curl-8.12.1-4.el10_2.4.x86_64
ALSA-2026:22715 Important/Sec. expat-2.7.3-1.el10_2.1.x86_64
ALSA-2026:42063 Important/Sec. glib2-2.80.4-12.el10_2.14.x86_64
ALSA-2026:57015 Moderate/Sec.  glib2-2.80.4-12.el10_2.21.x86_64
ALSA-2026:33092 Moderate/Sec.  glibc-2.39-126.el10_2.alma.1.x86_64
ALSA-2026:42694 Moderate/Sec.  glibc-2.39-128.el10_2.alma.1.x86_64
ALSA-2026:33092 Moderate/Sec.  glibc-common-2.39-126.el10_2.alma.1.x86_64
ALSA-2026:42694 Moderate/Sec.  glibc-common-2.39-128.el10_2.alma.1.x86_64
ALSA-2026:33092 Moderate/Sec.  glibc-minimal-langpack-2.39-126.el10_2.alma.1.x86_64
ALSA-2026:42694 Moderate/Sec.  glibc-minimal-langpack-2.39-128.el10_2.alma.1.x86_64
ALSA-2026:42739 Important/Sec. libacl-2.4.0-1.el10_2.x86_64
---
total security advisories waiting on this image:
34
```

<details class="predict">
<summary>A base image pinned by digest, containing almost nothing beyond a minimal userland. Predict how many outstanding security advisories it carries.</summary>

**Thirty-four**, on the image this track pins, and the packages they name are the
ones you would least expect to be interesting: `glibc`, `coreutils`, `expat`,
`libacl`. There is no application on this image at all.

Two things follow and both are worth carrying.

The first is that a minimal image is not a small attack surface in this sense. It
is a small number of packages, each of which is old the moment the image is
published, and the advisory count grows monotonically from that day. Nobody did
anything wrong; time passed.

The second is the one that catches teams running containers. A pinned digest is
chosen precisely so the thing does not change, which is the correct instinct for
reproducibility and means the advisory list has no mechanism for going down. The
policy that has to exist alongside pinning is a rebuild trigger: a count, a
severity, a date, something. Without one the pin quietly converts a deliberate
engineering decision into an accumulating pile of known flaws that no longer
surprises anybody.

</details>

Thirty-four advisories, each naming a package and a severity, on a base image that
somebody pinned deliberately. **This is package monitoring in its simplest form
and it is free.** No scanner, no agent, no credentials, because the machine is
asking on its own behalf.

The list is also a small lesson in why pinned images need a policy. Nothing here
is a failure: the image was correct on the day it was published, and the advisories
accumulated afterwards. The question a pinned image raises is who is watching this
list and what happens when it reaches a length somebody has agreed is too long.

<details class="deeper">
<summary>If you buy threat intelligence: the three tiers, and the question that decides whether a feed is worth anything</summary>

Feeds come in three broad shapes and they answer different questions, which is
worth sorting out before spending money.

**Vulnerability feeds** tell you that a flaw exists in a product. The CVE list is
one and it is free. A commercial version adds earlier notification, better
descriptions, and sometimes an assessment of exploitability before the public
scoring catches up.

**Indicator feeds** carry addresses, hashes and domains associated with observed
activity. These are the ones sold by volume, and volume is the wrong measure: an
indicator is worth something only for as long as the attacker is still using it,
which for an address may be hours.

**Actor and campaign intelligence** describes who is doing what, how, and against
whom. It is the most expensive, it is narrative rather than machine-readable, and
it is the only tier that helps you decide what to build rather than what to block.

The question that decides whether any of it is worth anything is what the feed is
joined against. A vulnerability feed matched against your asset inventory produces
a work list. Unmatched, it produces a newsletter. An indicator feed matched against
your logs produces alerts. Unmatched, it produces a subscription.

That is why this objective puts feeds next to asset management and monitoring
rather than in a section of their own, and it is why "we have threat intelligence"
is not an answer to any audit question. The answer is what the intelligence is
joined to and what happens when a match occurs.

Information-sharing organisations sit slightly outside this. What they provide is
often less about the data and more about the phone call from somebody in the same
industry who saw it last week, and that is not something a feed replaces.

</details>

## What a penetration test establishes that a scan does not

A scan says a vulnerability is present. A penetration test says somebody got in,
and those are different claims with different consequences.

The scan is a survey. It runs against everything, it is cheap per host, it is
repeatable, and it reports presence. It cannot tell you whether the flaw it found
is reachable from anywhere that matters, whether a compensating control blocks it,
or what an attacker would get by chaining it with something else.

The test is an investigation. It runs against a scope, it is expensive, it is not
repeatable in any useful sense, and it reports a route. Its output is a story with
a beginning and an end: from this position, through these three steps, to this
data.

**The mistake is to use one as the other**, in both directions. Commissioning a
penetration test to produce a vulnerability list is buying the most expensive
possible scan. Reading a clean scan as evidence that nobody can get in is reading
a survey as an investigation.

Two more things belong in this objective and they are both about reports arriving
from outside.

**Responsible disclosure** is somebody telling you about a flaw before telling
everybody. What makes it work is having somewhere for the report to go: a
published address, a stated response time, and an assurance that the reporter will
not be pursued. Organisations without that receive their disclosures through
whatever channel the finder can reach, which is sometimes a journalist.

**A bug bounty** pays for those reports under published rules. It is not a
substitute for testing, because the scope is what you advertised and the finders
choose their own targets within it, and it is a good way to hear about the things
your own testing did not cover.

<details class="deeper">
<summary>If you are commissioning a test: what the scope statement decides, and the finding you will never receive</summary>

The single most consequential document in a penetration test is not the report. It
is the scope, and it is usually written by whoever is buying rather than by
whoever knows where the risk lives.

Scope decides three things. Which systems may be touched, which techniques are
permitted, and what happens if the tester finds a route into something not on the
list. That third one is where the value leaks. A tester who reaches a boundary and
stops because the next hop is out of scope has found the most important thing in
the engagement and cannot tell you where it goes.

The practical fix is a rule in the scope for exactly that case: the tester stops,
reports the position reached, and asks. It costs a phone call and it converts the
most valuable finding in most tests from a footnote into a conversation.

Two techniques are worth deciding on explicitly rather than by omission. Social
engineering is frequently excluded, which is defensible and means the report
cannot speak to the route most real intrusions take. Denial of service is almost
always excluded, correctly, and the consequence is that availability weaknesses go
untested and unmentioned.

The finding you will never receive is the one about something nobody put in scope
because nobody knew it existed. That is not a failure of the test. It is the asset
inventory again, arriving in a different disguise, and it is why a test of a
carefully scoped estate can come back clean while the actual way in is a server
somebody stood up in 2021 and forgot.

</details>

## Across platforms

Asking a machine what it is missing gets three answers of quite different
usefulness.

| Task | Linux | Windows | macOS |
| --- | --- | --- | --- |
| List security advisories outstanding | `dnf updateinfo list --security` | no per-CVE list on the machine | `softwareupdate -l` |
| What was installed and when | `rpm -qa --last` | `Get-HotFix` | `system_profiler SPInstallHistoryDataType` |
| The identifier a fix is keyed on | package name and release | the build and revision number | the build |
| Can the machine name a CVE it lacks | yes, per package | no | no |

```powershell
# Microsoft Windows Server 2025 Datacenter, version 10.0.26100.0
> Get-HotFix | Select-Object -Last 4 HotFixID, Description, InstalledOn | Format-Table -AutoSize
HotFixID  Description     InstalledOn
--------  -----------     -----------
KB5120708 Update          8/9/2026 12:00:00 AM
KB5120233 Security Update 8/9/2026 12:00:00 AM
KB5120232 Security Update 8/9/2026 12:00:00 AM

# How many that is in total, against the per-package advisory count on the Linux side
> (Get-HotFix | Measure-Object).Count
3

# The build number, which is what decides whether a given fix is present
> [System.Environment]::OSVersion.Version.ToString(); (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').UBR
10.0.26100.0
33296

# Whether the machine can name a single CVE it is missing
> Get-HotFix | Where-Object { $_.Description -match 'CVE' } | Measure-Object | Select-Object -ExpandProperty Count
0
```

**Three hotfixes against thirty-four advisories, and the difference is packaging
rather than security.** Windows ships fixes as cumulative updates, so one KB
number covers many vulnerabilities and supersedes the previous one. That is why
the list is short and why the last line returns zero: no CVE identifier appears
anywhere in what the machine holds.

The identifier that matters here is the pair on the third command. Build
`10.0.26100` with revision `33296` is what Microsoft's own security update guide is
keyed on, and the mapping from that revision to a list of fixed CVEs lives on
their website rather than on the machine. A credentialed scan of a Windows host is
therefore doing a lookup against an external table, where the same scan of a Linux
host is reading an advisory feed the machine already has.

```bash
# macOS 26.5.2, arm64
$ softwareupdate -l 2>&1 | head -6
Software Update Tool

Finding available software
Software Update found the following new or updated software:
* Label: macOS Tahoe 26.6.2-25G83
	Title: macOS Tahoe 26.6.2, Version: 26.6.2, Size: 3831075KiB, Recommended: YES, Action: restart, 

# What has been installed and when, which is what a credentialed scan reads
$ system_profiler SPInstallHistoryDataType 2>/dev/null | grep -A2 -m3 "Software Update" | head -9

# The build, which is the identifier Apple's security notes are keyed on
$ sw_vers
ProductName:		macOS
ProductVersion:		26.5.2
BuildVersion:		25F84

# Whether anything on the machine names a CVE it is missing
$ softwareupdate -l 2>&1 | grep -c CVE
0
```

macOS gives the least of the three. One update is available, it is the whole
operating system at 3.8 GB, and nothing on the machine says what is wrong with the
version currently installed. The second command returned nothing at all on this
runner, which is worth leaving in: a machine with no install history through that
key cannot answer the when question either.

The identifier is `25F84`, and Apple publishes security notes per build. So the
same pattern as Windows, with one difference that matters operationally: because
the unit is the entire operating system, there is no such thing as applying one
fix. The decision is always to take everything or nothing, which is why the
argument about macOS patching is usually a scheduling argument rather than a
selection one.

**The general point survives all three.** Only one of these machines can tell you
which vulnerabilities it has. On the other two the machine reports a version and
the mapping to vulnerabilities lives with the vendor, which means the quality of
your vulnerability data depends on the quality of somebody else's table and on
your scanner having a current copy of it.

## Prove it

**Run it.** On any Linux machine, `dnf updateinfo list --security` or
`apt list --upgradable` will produce the advisory list in seconds. Then pick one
package and read its changelog with `rpm -q --changelog` or
`apt changelog` to see which CVEs the current version already fixed.

**Work it out.** Take the four thousand findings from the top of this page. If a
credentialed rescan of the same estate returns four hundred, what did the other
three thousand six hundred consist of, and what would you tell the person who
presented the first number?

**Look it up.** Open SP 800-115 and find what it says about the difference between
vulnerability scanning and penetration testing. The distinction it draws is about
what each activity establishes, and it is more precise than the usual one about
depth.

## What trips people up

### 1. Reading an uncredentialed scan as an inventory of what is wrong

It is an inventory of what is visible. On enterprise Linux it will report
vulnerabilities that were fixed by backporting, because the version string does
not move when the fix is applied.

### 2. Believing the scanner is broken

It is not. It read a version and looked it up, both correctly. The conclusion is
wrong because the input does not carry the information needed to reach a right
one.

### 3. Treating a penetration test as a scan

A test establishes a route, against a scope, once. A scan establishes presence,
against everything, repeatedly. Commissioning the first to get the second is
expensive and produces a shorter list.

### 4. Buying a feed and not joining it to anything

An indicator matched against your logs produces an alert. Unmatched, it produces
a subscription. The value is entirely in what the feed is joined to.

### 5. Expecting every platform to name its CVEs

Only the package-managed one does. Windows and macOS report a build, and the
mapping from that build to a list of fixes is published by the vendor rather than
held on the machine.

### 6. Reading a pinned image as a frozen risk

The image does not change and the advisory list against it grows. Thirty-four on
the image above, none of which existed when it was published.

## Work it through

You inherit a vulnerability management programme. The monthly report says 4,000
findings, unchanged for three months, and nobody reads it. You have been asked to
make it useful.

**The tempting move is to start fixing.** Sort by severity, take the top hundred,
work down the list. It produces visible activity, and if a meaningful share of
those findings are the backporting artefacts above, most of that activity is
spent proving that already-patched software is patched.

**The move that works is to run one credentialed scan against a sample and
compare.** Twenty machines, credentials, same scanner, and put the two reports
side by side. If the number collapses, you have found the problem and it is a
configuration problem rather than a remediation backlog. If it does not, the
backlog is real and you now know that too, which is worth the afternoon either
way.

**Then the second question is which of the real findings matter**, and that is
the next topic rather than this one. Presence is what this topic's methods
establish. Priority needs numbers they do not carry.

**What this rejects is remediation as the first action.** It feels like progress
and it is the wrong order, because fixing findings from a scan you have not
validated means the report stays at 4,000 while the team gets busier. The cost of
the sample scan is a day and the cost of getting this wrong is a quarter.

The residual worth naming: a credentialed scan needs an account with broad access,
and creating one is a real risk that has to be accepted deliberately. If the
organisation is not willing to create it, the programme stays uncredentialed and
the report stays approximate, which is a decision somebody should make on the
record rather than by default.

## Try it

**Compare the two views of one service.** On any Linux machine running a web
server, `curl -sI localhost | grep -i server` and then the package query for the
same software. Note whether the two strings would let a stranger tell them apart.

**Read your own advisory list.** `dnf updateinfo list --security` or
`apt list --upgradable`, then count. Whatever the number is, ask who currently
looks at it.

**Ask Windows what it is missing.** `Get-HotFix` and the build revision from the
registry. Then try to find a CVE identifier anywhere in the output, and notice
that the answer is a lookup rather than a field.

**Find a disclosure address.** Pick any organisation and look for
`/.well-known/security.txt` on their site. Whether it exists tells you where a
finder's report would go, and how quickly it would reach somebody.

## Check yourself

<details class="qa">
<summary>An uncredentialed scan reports three CVEs against a server. The owner shows a package version that includes the fixes. Who is right?</summary>

Both, about different things. The scanner read `nginx/1.26.3` from the banner and
looked it up, and upstream 1.26.3 does have those CVEs. The owner's
`nginx-1.26.3-6.el10_2.6` is the same upstream version with the fixes backported
into it.

The version number does not move when a distribution backports a fix, so nothing
readable over the network distinguishes a patched build from an unpatched one. The
resolution is credentials, not a better scanner.

</details>

<details class="qa">
<summary>What does a penetration test establish that a vulnerability scan does not?</summary>

That a route exists. A scan reports presence across everything, cheaply and
repeatably. A test reports that somebody started from a position, took a sequence
of steps, and reached something, which is a claim about exploitability and about
chaining rather than about presence.

Using one as the other fails in both directions: a test commissioned to produce a
list is an expensive scan, and a clean scan read as proof nobody can get in is a
survey mistaken for an investigation.

</details>

<details class="qa">
<summary>A pinned base image has 34 outstanding security advisories. Is that a failure?</summary>

Not on its own. The image was correct when it was published and the advisories
accumulated after it. Pinning is a deliberate choice that trades currency for
reproducibility.

What it does require is somebody watching the list and a stated threshold for
rebuilding. An image nobody re-examines becomes a permanent inventory of known
flaws that the organisation has stopped noticing.

</details>

<details class="qa">
<summary>Why can a Linux machine name the CVEs it is missing when a Windows or macOS machine cannot?</summary>

Because the package manager carries the vendor's advisory feed, so the machine
holds the mapping from installed package to known vulnerability locally and per
package.

Windows ships cumulative updates and reports a build revision; macOS ships whole
operating system versions and reports a build. In both cases the mapping from that
build to a list of fixed CVEs is published by the vendor rather than held on the
machine, so a scan of those hosts is doing an external lookup.

</details>

<details class="qa">
<summary>What makes a threat feed worth anything?</summary>

What it is joined to. A vulnerability feed matched against an asset inventory
produces a work list. An indicator feed matched against your logs produces alerts.
Neither matched against anything produces a subscription.

Volume is the wrong measure, particularly for indicators, because an address or a
hash is useful only for as long as the attacker is still using it.

</details>

## References

- [SP 800-115](https://csrc.nist.gov/pubs/sp/800/115/final) - NIST, Technical Guide to Information Security Testing and Assessment, for what scanning and testing each establish. Free. Accessed 2026-08-25.
- [SP 800-40 Rev. 4](https://csrc.nist.gov/pubs/sp/800/40/r4/final) - NIST, enterprise patch management planning, for what happens after discovery. Free. Accessed 2026-08-25.
- [SP 800-216](https://csrc.nist.gov/pubs/sp/800/216/final) - NIST, vulnerability disclosure guidelines, for what a disclosure process has to provide and how long it has. Free. Accessed 2026-08-25.
- [CVE Program](https://www.cve.org/) - MITRE, the identifier scheme every feed on this page is keyed on. Free. Accessed 2026-08-25.
- [Get-HotFix](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.management/get-hotfix) - Microsoft, for what the Windows capture reads and what it omits. Free. Accessed 2026-08-25.

**Where the content came from.** The nginx comparison, the advisory list and the
changelog are captured from an AlmaLinux 10.2 container, with the web server
installed and started during the capture. The Windows and macOS blocks are from
disposable runners. Nothing here scans, probes or tests any host this project does
not own: the only server queried is one started inside the container a second
earlier, and every other command asks a machine about itself.

**If you also work on Linux.** The Linux+ track's
[packages, repositories and signing](/learn/linux-plus/packages-repositories-and-signing)
covers what a package release number records, which is the fact the whole first
half of this page turns on.
