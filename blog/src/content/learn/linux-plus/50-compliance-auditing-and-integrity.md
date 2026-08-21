---
title: "Compliance, auditing and integrity"
description: "Compliance is a demand for evidence rather than assertion. CVE and CVSS, why a version-number scan is wrong on an enterprise distribution, benchmark scanning with OpenSCAP, and proving on disk that nothing has changed."
deck: "The scanner says you are vulnerable and the package is fully patched"
track: "linux-plus"
level: "deep"
order: 510
objectives:
  - "Say what an auditor asks for and produce it as evidence"
  - "Read a CVE identifier and a CVSS score without mistaking severity for risk"
  - "Explain backporting and refute a version-string scan finding"
  - "Scan a machine against a benchmark profile and read the result"
  - "Verify package and filesystem integrity with rpm -V and AIDE"
prerequisites: ["packages-repositories-and-signing", "hardening-a-system"]
tags: ["linux", "linux-plus", "compliance", "auditing", "integrity", "security"]
updated: 2026-08-08
draft: false
examObjectives:
  - exam: "xk0-006"
    domain: "3.0"
    objective: "3.6"
sources:
  - title: "rpm(8)"
    url: "https://man7.org/linux/man-pages/man8/rpm.8.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-08
    tier: 1
  - title: "dpkg(1)"
    url: "https://manpages.debian.org/trixie/dpkg/dpkg.1.en.html"
    publisher: "Debian manpages"
    accessed: 2026-08-08
    tier: 1
  - title: "aide(1)"
    url: "https://manpages.debian.org/trixie/aide/aide.1.en.html"
    publisher: "Debian manpages"
    accessed: 2026-08-08
    tier: 1
  - title: "oscap(8)"
    url: "https://manpages.debian.org/trixie/openscap-scanner/oscap.8.en.html"
    publisher: "Debian manpages"
    accessed: 2026-08-08
    tier: 1
  - title: "rkhunter(8)"
    url: "https://manpages.debian.org/trixie/rkhunter/rkhunter.8.en.html"
    publisher: "Debian manpages"
    accessed: 2026-08-08
    tier: 1
  - title: "Common Vulnerability Scoring System version 4.0: Specification Document"
    url: "https://www.first.org/cvss/v4-0/specification-document"
    publisher: "FIRST"
    accessed: 2026-08-08
    tier: 1
  - title: "Backporting Security Fixes"
    url: "https://access.redhat.com/security/updates/backporting"
    publisher: "Red Hat"
    accessed: 2026-08-08
    tier: 1
  - title: "Regulation (EU) 2016/679 (General Data Protection Regulation)"
    url: "https://eur-lex.europa.eu/eli/reg/2016/679/oj"
    publisher: "EUR-Lex"
    accessed: 2026-08-08
    tier: 1
symptoms:
  - symptom: "Vulnerability scan reports a CVE against a package that is fully patched"
    anchor: "backporting-and-the-scan-report-that-is-wrong"
  - symptom: "AIDE found differences between database and filesystem"
    anchor: "a-tripwire-for-the-whole-filesystem"
  - symptom: "rpm -V prints S.5....T. on a file and you do not know if that is bad"
    anchor: "has-anything-changed-since-the-package-was-installed"
---

> **Before you read.** An auditor is in the room. You tell them the servers are
> patched, the configuration is hardened, and nobody has tampered with the binaries.
>
> They write none of that down. They ask you to show them, for one named host, on a
> named date.
>
> **What do you hand over?**

Nothing you have said so far is evidence. "The servers are patched" is a claim about a
set you have not enumerated, at a moment you have not fixed. Compliance work is almost
entirely the difference between that sentence and an artefact somebody else can check
without believing you.

This topic is the tooling that produces those artefacts, and the two places it
routinely misleads people: a scanner reporting vulnerabilities that were fixed months
ago, and an integrity check reporting changes that are entirely normal. Both cost teams
whole sprints, and both come down to reading one field correctly.

### Some words you will need

<dl class="terms">
<dt>control</dt>
<dd>A specific thing you do to reduce a risk. "Root login over SSH is disabled" is a control.</dd>
<dt>evidence</dt>
<dd>An artefact showing the control was in place on a host on a date. A scan result, a config file, a signed report.</dd>
<dt>framework</dt>
<dd>A published list of controls somebody expects you to have. PCI DSS, ISO 27001, NIST SP 800-53, SOC 2.</dd>
<dt>benchmark</dt>
<dd>A framework rendered as itemised, checkable settings for one specific platform. CIS and the DISA STIGs are the two you will meet.</dd>
<dt>CVE</dt>
<dd>Common Vulnerabilities and Exposures. An identifier, <code>CVE-YYYY-NNNNN</code>, so two tools can name the same flaw.</dd>
<dt>CVSS</dt>
<dd>A 0.0 to 10.0 score describing how severe a flaw is in the abstract. Not a measure of your risk.</dd>
<dt>backport</dt>
<dd>Taking a fix from a newer upstream release and applying it to the older version you already ship.</dd>
<dt>SCAP</dt>
<dd>Security Content Automation Protocol. The file formats that let a checklist be machine-readable, so a scan is repeatable.</dd>
<dt>baseline</dt>
<dd>A recorded snapshot of what every file looked like when you believed the system was clean.</dd>
<dt>SBOM</dt>
<dd>Software bill of materials. A list of every component inside something you shipped.</dd>
</dl>

## What breaks without this

**You cannot answer a question about last Tuesday.** Everything you know is about the
machine as it is now, and an incident is always about how it was.

**You spend a sprint patching a library nothing loads**, because a report sorted by
severity put it at the top and nobody asked whether the code was reachable.

**You argue with a scanner report and lose**, not because it is right but because you
cannot produce the vendor data showing it is wrong.

**A compromise is invisible.** A modified binary looks exactly like an unmodified one
in `ls -l`, and the only thing distinguishing them is a record made beforehand.

**An honest deviation becomes a finding.** Every organisation has settings it cannot
apply. The ones that pass audits wrote theirs down.

## What an auditor actually asks for

An audit is a sequence of three questions, and they get harder in order.

**Is the control defined?** Somewhere there is a document saying root login over SSH is
disabled on all production Linux hosts. Missing that, everything downstream is
somebody's personal preference.

Is the control implemented? On this host, right now, `PermitRootLogin no` is
in `/etc/ssh/sshd_config` and the running daemon has read it.

Can you demonstrate it was implemented? On the 14th of last month, across all
340 hosts, not only the one you are logged into. That question separates sites
which pass from sites which scramble, and it is a tooling problem rather than
a security one.

It is also why compliance regimes exist separately from security. **GDPR is the named
example**, and its Article 32 is unusually direct: the regulation requires appropriate
technical and organisational measures, and then requires "a process for regularly
testing, assessing and evaluating the effectiveness" of them. Having the control is one
obligation; demonstrating it keeps working is a second, separate one.

The rest of the landscape rhymes:

| Framework | Applies to | Known for |
| --- | --- | --- |
| **GDPR** | Personal data of people in the EU | Breach notification within 72 hours; testing the effectiveness of measures |
| **PCI DSS** | Anything touching card data | Prescriptive and specific; quarterly external scanning |
| **HIPAA** | US health information | Risk analysis; audit controls over access to records |
| **SOC 2** | Service providers, by customer demand | An auditor's opinion over a period, not a point in time |
| **ISO 27001** | Whole organisations | A management system, certified and re-certified |
| **NIST SP 800-53** | US federal systems and their suppliers | A large control catalogue others borrow from |

**None of them tell you which sysctl to set.** They say systems must be configured to
a hardened standard and leave the translation to a benchmark. That gap is where CIS
and the STIGs live, and it is why the practical work here is nearly all benchmark work.

<details class="deeper">
<summary>If you already administer Linux: mapping a finding to a framework, and why a written exception is a normal outcome</summary>

**A benchmark rule carries its framework mapping with it.** A CIS item for `sshd`
cites the NIST 800-53 controls and ISO 27001 clauses it satisfies, and SCAP content
records those references in the rule metadata. So one `fail` is not one problem: it is
a gap against every framework that rule maps to, which is how a single
misconfiguration becomes four line items on four reports.

The reverse direction is the useful one. Handed "NIST 800-53 AC-6, least privilege"
you cannot check anything. Handed the benchmark rules that map to AC-6, you can check
all of them tonight.

**The part people get wrong is what to do when a rule cannot be applied.** Some
cannot. A benchmark says disable USB storage; the machine is a lab workstation that
exists to read USB storage.

**An exception is a normal, expected audit outcome.** It needs four cheap things: the
rule named by its identifier, why it cannot be met, what you do instead as a
compensating control, and a review date with an owner.

With those, the auditor records an accepted risk and moves on. Without them
the same machine produces a **finding**, not because the setting is worse, but
because nobody decided it. That distinction is the most useful thing to
understand about how audits actually go, and it is why the answer to "we
cannot do that one" is never silence.

The related trap: exceptions with no review date accumulate for years, and a stack of
undated exceptions is itself a finding at the next audit. Give every one an expiry.

</details>

## A number that measures severity, not risk

Two identifiers do most of the talking in a vulnerability report, and they answer
different questions.

**CVE is a name.** `CVE-YYYY-NNNNN` identifies one flaw in one product, so your
scanner, your distribution's advisory, and the upstream project's mailing list are
demonstrably discussing the same thing. It carries no judgement at all.

**CVSS is a score**, 0.0 to 10.0, banded as None, Low (0.1 to 3.9), Medium (4.0 to
6.9), High (7.0 to 8.9), and Critical (9.0 to 10.0). It comes from a vector string,
which is worth reading because it says far more than the number:

```
CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:H
```

Reachable over the **n**etwork, **l**ow attack complexity, **n**o privileges
required, **n**o user interaction, and **h**igh impact to confidentiality, integrity,
and availability. Every metric at its worst, which is what produces the 9.8 attached
to the frightening ones.

**And now the sentence this section exists for: CVSS measures severity, not
risk.** The base score describes the flaw in the abstract, on a hypothetical
system where the affected component is installed, running, reachable, and
used. It knows nothing about your machine, not whether the package is
installed, whether the daemon is enabled, whether the port is firewalled off,
whether the vulnerable code path is ever executed, or whether something else
already stops the attack.

So a policy of "all criticals remediated within 7 days", applied to base scores with
no further thought, is how a team spends a sprint patching a library nothing loads
while a medium-severity flaw in the one internet-facing service waits its turn. The
number is an input to prioritisation. It is not the prioritisation.

**CVSS v4.0 splits this out explicitly**, into Base, Threat, and Environmental metric
groups, so the environmental part can be recorded rather than assumed. The number you
get handed is nearly always the base score alone, with the other two groups unset.

Two signals answer the question CVSS does not. **KEV** is the US CISA
catalogue of vulnerabilities known to be exploited in the wild, so a flaw on
it is being used against real systems today whatever its score. **EPSS**
publishes a probability that a given CVE will be exploited in the next 30
days, a likelihood rather than a severity.

A high CVSS on something unreachable with no known exploitation is routinely less
urgent than a medium on an internet-facing service that appears in KEV. Being able to
say that out loud, with reasons, is most of what separates useful vulnerability
management from a spreadsheet.

## Backporting, and the scan report that is wrong

This is the most consequential misunderstanding in the objective, and it produces
reports that are confidently and comprehensively wrong.

<figure class="learn-figure">
<svg viewBox="0 0 720 320" role="img" aria-labelledby="bp-title bp-desc" style="width:100%;height:auto;">
  <title id="bp-title">How backporting makes a version-string scan report a false positive</title>
  <desc id="bp-desc">Upstream ships version 2.4.57, later discovers a flaw, and fixes it in version 2.4.62. An enterprise distribution does not move to 2.4.62, because that would change behaviour for everyone. Instead it takes the upstream patch and applies it to the 2.4.57 it already ships, incrementing only the release field, producing 2.4.57-11.el10. A scanner that compares version strings sees 2.4.57, notes that it is lower than 2.4.62, and reports the machine as vulnerable, which is wrong. A scanner that reads the vendor's own security data sees that the fix landed in release 11 and reports the machine as patched, which is right.</desc>
  <g>
    <rect x="16" y="112" width="196" height="96" rx="5" fill="currentColor" fill-opacity="0.12" stroke="currentColor" stroke-opacity="0.4"/>
    <text x="114" y="138" text-anchor="middle" font-size="12" fill="currentColor">upstream</text>
    <text x="114" y="160" text-anchor="middle" font-size="10" fill="currentColor" fill-opacity="0.65">2.4.57 is what shipped</text>
    <text x="114" y="177" text-anchor="middle" font-size="10" fill="currentColor" fill-opacity="0.65">a flaw is found</text>
    <text x="114" y="194" text-anchor="middle" font-size="10" fill="currentColor" fill-opacity="0.85">2.4.62 carries the fix</text>
    <rect x="262" y="112" width="196" height="96" rx="5" fill="var(--accent)" fill-opacity="0.1" stroke="var(--accent)" stroke-opacity="0.9" stroke-width="1.8"/>
    <text x="360" y="138" text-anchor="middle" font-size="12" fill="var(--accent)">the vendor</text>
    <text x="360" y="160" text-anchor="middle" font-size="10" fill="currentColor" fill-opacity="0.65">takes the patch, not</text>
    <text x="360" y="177" text-anchor="middle" font-size="10" fill="currentColor" fill-opacity="0.65">the new release</text>
    <text x="360" y="194" text-anchor="middle" font-size="10" fill="currentColor" fill-opacity="0.85">2.4.57-11.el10</text>
    <rect x="508" y="24" width="196" height="96" rx="5" fill="currentColor" fill-opacity="0.07" stroke="currentColor" stroke-opacity="0.3"/>
    <text x="606" y="50" text-anchor="middle" font-size="12" fill="currentColor">version-string match</text>
    <text x="606" y="72" text-anchor="middle" font-size="10" fill="currentColor" fill-opacity="0.65">reads 2.4.57, compares</text>
    <text x="606" y="89" text-anchor="middle" font-size="10" fill="currentColor" fill-opacity="0.65">it against 2.4.62</text>
    <text x="606" y="106" text-anchor="middle" font-size="10" fill="currentColor" fill-opacity="0.85">reports vulnerable, wrongly</text>
    <rect x="508" y="200" width="196" height="96" rx="5" fill="currentColor" fill-opacity="0.07" stroke="currentColor" stroke-opacity="0.3"/>
    <text x="606" y="226" text-anchor="middle" font-size="12" fill="currentColor">vendor security data</text>
    <text x="606" y="248" text-anchor="middle" font-size="10" fill="currentColor" fill-opacity="0.65">changelog and OVAL name</text>
    <text x="606" y="265" text-anchor="middle" font-size="10" fill="currentColor" fill-opacity="0.65">the CVE and the release</text>
    <text x="606" y="282" text-anchor="middle" font-size="10" fill="currentColor" fill-opacity="0.85">reports patched, correctly</text>
  </g>
  <g stroke="currentColor" stroke-opacity="0.45" fill="none" stroke-width="1.2">
    <path d="M212 160 L256 160 M250 156 L257 160 L250 164"/>
    <path d="M458 148 L482 148 L482 72 L504 72 M498 68 L505 72 L498 76"/>
    <path d="M458 172 L482 172 L482 248 L504 248 M498 244 L505 248 L498 252"/>
  </g>
</svg>
<figcaption>Illustrative version numbers. The version field stopped tracking upstream the moment the vendor backported; only the release field and the vendor's own data know what is in the binary.</figcaption>
</figure>

**Enterprise distributions promise that behaviour does not change within a
major release**, and that promise is the product. An application certified
against RHEL 10 on day one must still work on day 2,000, so the vendor cannot
move a package to a new upstream release every time upstream fixes something,
new upstream releases change behaviour, drop options, and move files.

Instead the vendor takes the upstream patch, applies it to the version already shipped,
increments the **release** field, and publishes. Red Hat and its rebuilds, SUSE, Ubuntu,
and Debian stable all work this way, and the evidence is in any installed package:

```bash
# AlmaLinux 10.2, x86_64
$ rpm -qi bash | grep -iE "signature|source rpm|build date"
Signature   :
Source RPM  : bash-5.2.26-6.el10.src.rpm
Build Date  : Mon Mar  3 19:03:14 2025
```

**Read the two fields together.** The version `5.2.26` is upstream's. The release
`-6.el10` is the vendor's, and the `6` counts how many times they have rebuilt that
upstream version with their own changes. The build date is March 2025, which has
nothing to do with when upstream released 5.2.26.

**A version number and the age of a binary are not the same fact**, and that sentence
is the whole misunderstanding. A scanner reading `5.2.26` and comparing it to a table
of upstream fixed-in versions reports every CVE fixed upstream since 5.2.26, any number
of which are already present in that binary.

The empty `Signature` field there is an artefact of how the container image was
assembled rather than a property of the package, and a useful reminder that a metadata
field is not a verification. `rpm -K` on a package file checks the digest and the
signature against the trusted keys, which is a later section.

### What to actually check

The authoritative answer is the vendor's own security data, never the version string:

```
# Does the package's own changelog name the CVE?
rpm -q --changelog httpd | grep -i CVE-2024 | head

# What security errata apply here, and which are outstanding?
dnf updateinfo list --security
dnf updateinfo info CVE-2024-12345

# Debian and Ubuntu equivalents
apt changelog nginx | head -40
apt list --upgradable
```

`rpm -q --changelog` is the one to reach for in front of an auditor, because it is the
package speaking for itself: the vendor writes the CVE identifier into the changelog
entry for the build that fixed it. If the CVE is named at or below your installed
release, the fix is in the binary you are running. **The vendor publishes the same
data as machine-readable OVAL**, which is what a correctly configured scanner consumes
instead of a version table.

### What to tell the auditor

Do not argue about backporting in the abstract. Produce four things, in this order:

1. **The finding**, quoted exactly: this CVE, this package, this host.
2. **The vendor advisory** for that CVE, naming the release the fix shipped in.
3. **The host's own evidence**: `rpm -q` showing the installed release is at or above
   that, and `rpm -q --changelog` naming the CVE.
4. **The correction to the process**: the scan was matching version strings, which is
   a defect in the scan configuration, and here is the OVAL feed it should use.

Point four is the one people skip, and skipping it means doing all of this
again next quarter with the same 340 findings. **A false positive is a real
defect** (in the scanner, not the host) and an auditor who sees you treat it
that way will trust the rest of your evidence considerably more.

**The mistake runs the other way too.** Because the version field does not move, you
cannot conclude a machine is patched by reading it either: a host that has not updated
in a year reports the same `5.2.26`. The release field is what changed, and comparing
releases is the only version comparison meaning anything on these distributions.

## Scanning a machine against a benchmark

Two scans answer two different questions and get confused constantly.

| | Vulnerability scan | Configuration scan |
| --- | --- | --- |
| Asks | Is any installed software known to be flawed? | Does this machine match the standard? |
| Source of truth | CVE feeds and vendor security data | A benchmark, as SCAP content |
| Finds | Unpatched packages | Weak settings that were never a CVE |
| Tools | OpenVAS/Greenbone, Nessus, Qualys | OpenSCAP with the SCAP Security Guide |
| Fixed by | Patching | Changing configuration |

**A machine can be fully patched and score badly on a benchmark**, because nothing
about `PermitRootLogin yes` is a vulnerability with a CVE. It is a setting, and that is
the gap configuration scanning fills.

**OpenSCAP is the tool the exam means**, with the SCAP Security Guide as its content,
shipping pre-written profiles for the distribution you are on.

```
dnf install -y openscap-scanner scap-security-guide

# What profiles does the shipped content offer?
oscap info /usr/share/xml/scap/ssg/content/ssg-rhel10-ds.xml

# Run one, keeping machine-readable results and a report to hand over
oscap xccdf eval --profile cis_server_l1 \
  --results scan-results.xml --report scan-report.html \
  /usr/share/xml/scap/ssg/content/ssg-rhel10-ds.xml
```

The vocabulary inside those files is worth thirty seconds, because it appears in exam
questions and in error messages:

| Term | Is |
| --- | --- |
| **XCCDF** | The checklist: rules, groups, and profiles, with the framework mappings |
| **OVAL** | The machine-readable tests each rule runs |
| **CPE** | Platform identification, so a rule is skipped on the wrong OS |
| **datastream** | All of it bundled into the one `-ds.xml` file you point `oscap` at |
| **profile** | A named subset of the rules: `cis_server_l1`, `stig`, `pci-dss` |

Each rule returns `pass`, `fail`, `notapplicable`, `notchecked`, or `error`, and the
last three matter as much as the first two. **A profile reporting 200 rules
`notchecked` is not a clean machine**, it is a broken scan, and the summary percentage
will happily hide that.

**CIS Benchmarks come in levels**, and choosing the wrong one wastes a week. Level 1 is
defensible on essentially any machine with little functional cost; Level 2 is defence
in depth for environments where security outweighs convenience, and it will break
things. Server and workstation profiles differ again. Start at Level 1 server, and
treat Level 2 as a per-rule decision.

OpenSCAP will write the fix for you, and this is the sharp edge:

```
oscap xccdf generate fix --profile cis_server_l1 --fix-type bash \
  --result-id "" scan-results.xml > remediate.sh
```

**Read that script before it runs anywhere.** `oscap xccdf eval --remediate` applies
the whole profile in place, which on a running production host includes disabling
services something depends on and tightening permissions something needs. Generate,
review, test on a rebuild, then apply. The assessment is safe; the remediation is not.

<details class="deeper">
<summary>If you already administer Linux: authenticated versus unauthenticated scanning, and how often is often enough</summary>

**An unauthenticated scan sees what an attacker on the network sees:** open ports,
service banners, TLS parameters, HTTP responses. That is a genuinely useful view,
because it is the attacker's, and it is the only one proving a port is reachable
rather than merely open.

It is also a false-positive factory, for exactly the reason the previous section gave.
With no way to read the package database it guesses versions from banners.
`Server: Apache/2.4.57` is all it has, and the backported release field is invisible
from the network. Nearly every "we are vulnerable to 400 CVEs" report that turns out
to be nonsense came from an unauthenticated scan of an enterprise distribution.

**An authenticated scan logs in, or runs an agent, and reads the package database
directly.** It is the only way to answer "what is installed, at what release, and is
the vendor's fix in it", and it also sees what the network cannot: packages installed
but not listening, kernels built but not booted, and configuration.

It introduces a real risk of its own, which gets waved through far too easily.
A scanning account with credentials on every host is one of the most valuable
targets in the estate. Scope it to what the scan needs rather than blanket
`sudo` with `NOPASSWD: ALL`, source-restrict it to the scanner's addresses,
rotate it, and log its sessions. A scanner compromise is a whole-estate
compromise.

**On cadence**, a schedule alone is insufficient, because the event that breaks
compliance is a change and changes do not wait for Tuesday.

- **Continuously**, an asset inventory. You cannot scan what you do not know exists,
  and the machine nobody knew about is the unpatched one.
- **On every change**, at build time. Scanning an image in the pipeline is cheaper
  than scanning a fleet and stops the finding being deployed 400 times.
- **On a schedule** for the fleet, because drift and newly published CVEs both
  accumulate against machines nothing has touched.
- **When the framework says so.** PCI DSS requires quarterly external scanning by an
  approved vendor plus a rescan after significant change, and no argument about the
  quality of your pipeline changes that.

The quiet failure is scanning often and remediating slowly. A weekly scan producing
findings nobody closes is not a control; it is a record of how long you have known.

</details>

## Has anything changed since the package was installed

Every file a package installed has a recorded size, mode, owner, group, timestamp, and
content digest. `rpm -V` compares the disk against that record, and its silence is the
result you want.

<details class="predict">
<summary><code>rpm -V</code> prints one line per file that differs from what the package recorded, and nothing at all when everything matches. A <code>chmod 700</code> changes a file's permissions and not one byte of its contents. What appears, and what does not?</summary>

```bash
# AlmaLinux 10.2, x86_64
$ rpm -V bash; echo "rc=$? (silent means unmodified)"; echo "--- now change a packaged file ---"; chmod 700 /usr/bin/bash; echo "# tampered" >> /etc/profile.d/csh.csh 2>/dev/null; rpm -V bash setup; echo "rc=$?"
rc=0 (silent means unmodified)
--- now change a packaged file ---
.M.......    /usr/bin/bash
rc=1
```

</details>

**Silence is the pass.** No output and `rc=0` means every file that package owns is
byte-for-byte what was installed, with the same mode, owner, group, and timestamp. That
is a strong statement and it takes one command.

**`.M.......` is nine test results in nine fixed positions**, one character each:

| Position | Character | Test that failed |
| --- | --- | --- |
| 1 | `S` | File **S**ize differs |
| 2 | `M` | **M**ode differs, which covers permissions and file type |
| 3 | `5` | The content digest differs |
| 4 | `D` | **D**evice major or minor number mismatch |
| 5 | `L` | Symbolic **l**ink target mismatch |
| 6 | `U` | **U**ser ownership differs |
| 7 | `G` | **G**roup ownership differs |
| 8 | `T` | m**T**ime differs |
| 9 | `P` | Ca**p**abilities differ |

A `.` means that test passed. A `?` means the test could not be performed, usually
because the file is unreadable, and a column full of `?` is a permissions problem in
your check rather than a finding.

**After the nine characters comes a marker column**, which changes the meaning of
everything to its left: `c` for a configuration file, `d` documentation, `l` a licence,
`r` a readme, and `g` a ghost file the package expects to exist but does not ship.

Now put the two together, because this is the distinction the whole section is for:

```bash
# AlmaLinux 10.2, x86_64
$ rpm -qf /etc/profile; echo "--- append one line to it ---"; echo "# added by hand" >> /etc/profile; rpm -V setup; echo "rc=$?"
setup-2.14.5-7.el10.noarch
--- append one line to it ---
S.5....T.  c /etc/profile
rc=1
```

**`S.5....T.` with a `c` is expected and boring.** Size, digest, and
modification time all changed on `/etc/profile`, which is marked `c` because
configuration files exist to be edited. Every machine you run this on reports
dozens of these, and they are the reason people stop reading `rpm -Va` output,
which is exactly the problem.

**`.M.......` on `/usr/bin/bash` is an incident.** Nothing marks it, because
no packaging convention expects anyone to modify a binary. The contents are
unchanged (position 3 is a `.`, so the digest still matches) but the mode is
not what the vendor shipped. Something ran `chmod` on the system shell, and
there is no benign version of that which does not also involve somebody able
to explain it.

The filtering that makes `rpm -Va` usable on a real machine:

```
# Everything, which on a live server takes minutes and prints a lot
sudo rpm -Va

# Drop the config files, which is where the signal is
sudo rpm -Va | grep -v ' c /'

# A digest change on a binary: the highest-value line this command produces
sudo rpm -Va | grep '^..5'
```

**And the limitation, which is why the next section exists.** `rpm -V`
compares the disk against the RPM database, and that database is a file on the
same disk, writable by root. An attacker with root updates it and the modified
binary verifies perfectly. This catches accidents, misconfiguration, and
unsophisticated tampering, a great deal in practice, and it does not catch a
competent attacker.

### The Debian side is weaker, and it is worth knowing why

<details class="predict">
<summary>On the RHEL family, appending a line to <code>/etc/profile</code> produced <code>S.5....T.  c /etc/profile</code>. Debian's <code>dpkg -V</code> reads the md5sums file that packages record, and that file deliberately omits conffiles. The same edit, on Debian:</summary>

```bash
# Debian 13 (trixie), x86_64
$ dpkg -V bash; echo "rc=$? (silent means unmodified)"; echo "--- change a packaged file ---"; echo "# added by hand" >> /etc/profile; dpkg -V base-files; echo "rc=$?"
rc=0 (silent means unmodified)
--- change a packaged file ---
rc=0
```

</details>

**Silence, on a file that was definitely modified.** That is not a bug and it is not
`dpkg` failing to notice; it is `dpkg -V` checking a narrower thing on purpose.

| | `rpm -V` | `dpkg -V` |
| --- | --- | --- |
| Compares | Nine attributes, from the RPM header | Recorded md5sums only |
| Covers mode, owner, mtime | Yes | **No** |
| Covers config files | Yes, marked `c` | **No**, conffiles are excluded |
| Every package covered | Yes | Only those shipping an md5sums file |

So a clean `dpkg -V` is a much weaker statement than a clean `rpm -V`: it says the
contents of the non-config files it knows about are unchanged, and nothing about
permissions, ownership, or config files, which is where a great deal of interesting
tampering happens. The fuller Debian answers are `debsums`, reading the same md5sums
with better ergonomics, and the conffile hashes `dpkg` keeps separately:

```
sudo apt install debsums
sudo debsums -c            # changed files only
sudo debsums -e            # configuration files only
dpkg-query -W -f='${Conffiles}\n' base-files
```

If a policy says "verify installed package integrity" across a mixed estate, this
asymmetry belongs in the policy rather than in the audit.

## A tripwire for the whole filesystem

Package verification only covers files a package installed. Nothing in `/root`, nothing
in `/etc` that a person created, nothing dropped into `/usr/local/bin`, and nothing an
attacker adds. **AIDE covers the filesystem**, by recording a baseline at a moment you
believe the system is clean.

```
dnf install -y aide
sudo aide --init                                   # build the baseline
sudo mv /var/lib/aide/aide.db.new.gz /var/lib/aide/aide.db.gz
sudo aide --check                                  # compare disk against it
sudo aide --update                                 # re-baseline after legitimate change
```

`/etc/aide.conf` decides what is watched and which attributes are compared, with named
groups so a rule reads as intent: everything including content hashes for `/usr/bin`,
permissions and ownership but not size for `/var/log`, since logs grow by design.

A clean run says so without ambiguity:

```bash
# AlmaLinux 10.2, x86_64
$ aide --check --config /etc/aide.conf 2>&1 | head -8
Start timestamp: 2026-08-08 21:49:41 +0000 (AIDE 0.19.2)
AIDE found NO differences between database and filesystem. Looks okay!!

Number of entries:	18

---------------------------------------------------
The attributes of the (uncompressed) database(s):
---------------------------------------------------
```

**"AIDE found NO differences" is the artefact.** Dated, naming the database it compared
against, countable. That is the shape of a thing you hand an auditor, and it is a
materially stronger statement than "we monitor file integrity".

Now plant something the way an attacker would: a shell snippet in a directory every
login shell sources.

<details class="predict">
<summary>The baseline recorded 18 entries and none of them was <code>/etc/profile.d/rogue.sh</code>, because it did not exist. AIDE compares attributes between the database and the disk. What can it compare for a file that has no database entry at all?</summary>

```bash
# AlmaLinux 10.2, x86_64
$ echo "export EXTRA=1" > /etc/profile.d/rogue.sh; aide --check --config /etc/aide.conf 2>&1 | sed -n "1,20p"
Start timestamp: 2026-08-08 21:49:42 +0000 (AIDE 0.19.2)
AIDE found differences between database and filesystem!!

Summary:
  Total number of entries:	19
  Added entries:		1
  Removed entries:		0
  Changed entries:		1

---------------------------------------------------
Added entries:
---------------------------------------------------

f+++++++++++++++++: /etc/profile.d/rogue.sh

---------------------------------------------------
Changed entries:
---------------------------------------------------

d < ... m .n      : /etc/profile.d
```

</details>

**`f+++++++++++++++++` is what "nothing to compare against" looks like.** The
leading `f` is the file type, a regular file. Every position after it reads
`+`, meaning that attribute was added. The entry is new, so every attribute is
new. AIDE's legend is small and consistent: `.` unchanged, `+` added, `-`
removed, `:` ignored, and a space where the attribute was not checked at all.

The second line, against `/etc/profile.d` itself, is the same event seen one level up:
creating a file inside a directory changes the directory's own metadata, so the
directory is reported as changed too. That is not a second incident, and reading it as
one is a common way to double-count a change report.

**Notice the entry count**, 18 then 19. On a real installation that number is in the
hundreds of thousands, and the difference between a useful AIDE and an ignored one is
entirely in how well `/etc/aide.conf` has been scoped. Watch `/usr/bin`, `/usr/sbin`,
`/lib`, `/boot`, and `/etc`; exclude `/var/log` content, `/proc`, `/sys`, and anything
an application rewrites constantly, or the daily report is 4,000 lines and nobody opens
it.

**`rkhunter` is the other half of the pair**, answering a different question. Where AIDE
asks "has anything changed since I last looked", `rkhunter` asks "does anything here
look like a known rootkit": signatures of specific rootkits, hidden files and
directories, suspicious strings in kernel modules, wrong permissions on system
binaries, and the classic replaced-`ls`-and-`ps` pattern.

```
sudo rkhunter --update            # refresh the signature data
sudo rkhunter --propupd           # record current file properties as the baseline
sudo rkhunter --check --sk        # run, skipping the keypress between sections
```

`--propupd` is `aide --init` wearing a different name, with the identical trap: **run
it and you accept the current state as correct**. After a legitimate package update
that is required, or the next check reports every updated binary. Run it on a machine
you have not established is clean and you have recorded the compromise as normal.

<details class="deeper">
<summary>If you already administer Linux: the integrity database is the whole control, and it must not live where the attacker does</summary>

Everything above has the same single point of failure, and it is not the tool.

**An attacker who gets root can run `aide --init` too.** The database is a
file on the machine, writable by root, and regenerating it folds every change
since the compromise into the new normal. The next `aide --check` reports no
differences, and you have a clean report certifying an owned machine, worse
than no report at all, because it will be believed. The same argument applies
to `rkhunter --propupd`, to the RPM database behind `rpm -V`, and to the
md5sums behind `dpkg -V`. In every case the record and the thing recorded
share a trust domain.

The mitigations, in order of how much they buy:

- **Keep the database off the machine.** Store it on a management host and copy it in
  read-only for the check, or run the comparison elsewhere entirely. This is the one
  that changes the threat model, and it is why `aide.conf`'s `database` directive
  accepts a URL.
- **Read-only media.** Still correct for a machine that changes rarely: database and
  configuration on a volume mounted read-only, or genuinely read-only media.
- **Send the report off the box immediately**, so the copy an attacker would have to
  edit is already elsewhere. Central logging is the same idea for a different record.
- **Sign the database**, so tampering is detectable even when it is not preventable.
- **Immutable flags** (`chattr +i` from lesson 45) raise the bar slightly and are not a
  control on their own, because root can clear them.

And the operational reality that decides whether any of it survives: every
package update legitimately changes hundreds of watched files, so unless `aide
--update` is part of the patching runbook the first post-patch report is
enormous, the second is ignored, and by the third nobody opens it. The tool is
not the control. The tool, plus somebody reading the output, plus a defined
re-baselining process is the control, and an audit asks about all three.

</details>

## What the package manager trusts

Everything above assumes the software arrived from somewhere legitimate. That
assumption has a concrete, enumerable answer on any machine:

```bash
# AlmaLinux 10.2, x86_64
$ rpm -qa gpg-pubkey --qf "%{version}-%{release} %{summary}\n"
c2a1e572-668fe8ef AlmaLinux OS 10 <packager@almalinux.org> public key
```

**One key, and it is the distribution's own.** That listing is the machine's complete
trust set for packages, and the way to read it is as a list of everyone who can install
code as root on this host. On a server that has accumulated third-party repositories
over five years it is longer, and every extra line is a supply chain you accepted.
`gpg-pubkey` entries are pseudo-packages: RPM keeps trusted keys in its own database
rather than a keyring file, which is why `rpm -qa` finds them and why removing one is
`rpm -e gpg-pubkey-c2a1e572-668fe8ef`.

The Debian family keeps the same information in files:

```
ls /etc/apt/keyrings/ /usr/share/keyrings/
gpg --show-keys /usr/share/keyrings/debian-archive-keyring.gpg
grep -r Signed-By /etc/apt/sources.list.d/
```

**`Signed-By:` on a source is the habit that matters**, because it binds one key to one
repository. Without it any trusted key can sign any package from any source, so a
third-party repository added for one utility can transparently replace your kernel. It
is the successor to `apt-key add`, deprecated for exactly that reason.

For an auditor, three artefacts together answer "who can ship code to this
host": the trusted key list, the repository definitions under
`/etc/yum.repos.d` or `/etc/apt/sources.list.d`, and evidence that checking is
switched on: `gpgcheck=1` in every repo file, worth grepping for as a control
in its own right.

## The supply chain, which is everything upstream of you

Signature verification proves a package reached you from its publisher unmodified. It
proves nothing about what the publisher put in it, and modern attacks live in that gap:
compromised build systems signing malicious artefacts with the real key, a maintainer
account taken over, a typosquatted package name one character from the popular one, and
dependency confusion where an internal package name is registered publicly and the
resolver prefers the public copy.

**The distribution's packages are the well-defended part of your estate.** The exposure
is everything else: language ecosystem packages an application pulls at build time,
base container images, and the software your own team builds and installs without any
of the machinery in this topic applying to it.

<details class="deeper">
<summary>If you already administer Linux: SBOMs, and verifying what you build rather than what you install</summary>

**An SBOM is an inventory of the components inside an artefact**, in one of two formats:
SPDX, from the Linux Foundation and now an ISO standard, and CycloneDX, from OWASP and
common in application security tooling. Both list components, versions, licences, and
relationships, and both are generated from a built image rather than written by hand.

The reason to care is a question you cannot otherwise answer quickly. When a serious
flaw lands against a widely embedded library, the industry spends a fortnight answering
"where do we have it". With SBOMs stored per build that is a query; without them it is
archaeology across every team.

```
syft packages dir:/opt/myapp -o spdx-json > myapp.sbom.json
grype sbom:myapp.sbom.json
```

**Verification splits into two problems and only one is solved for you.**

*What you install* is handled: the distribution signs it, `rpm -K` and `apt` check it,
and `rpm -qa gpg-pubkey` says whose signature counts.

*What you build* is handled by nobody. An internal RPM repository with no signing is a
hole in exactly the shape of the one lesson 31 closed, and it is common because the
tooling defaults to unsigned:

```
rpmsign --addsign myapp-1.0-1.el10.x86_64.rpm       # sign your own RPMs
cosign sign --key cosign.key registry/myapp:1.4.2   # sign container images
cosign verify --key cosign.pub registry/myapp:1.4.2
```

Then set `gpgcheck=1` on the internal repository and import your own key, so an
internal build is held to the same standard as a vendor one.

**The vocabulary beyond signing is provenance:** SLSA, a framework of levels describing
how trustworthy a build process is, and in-toto attestations recording who built what
from which source. Both answer "was this built from the source it claims, by the
pipeline it claims", which a signature alone does not. Reproducible builds are the
strongest form: if two independent builders produce byte-identical output, a
compromised build system becomes detectable rather than merely signed.

</details>

## Across distributions

| | RHEL family | Debian family |
| --- | --- | --- |
| Package verification | `rpm -V`, `rpm -Va` | `dpkg -V`, `debsums` |
| What is compared | Nine attributes including mode, owner, mtime | Recorded md5sums only |
| Config files | Reported, marked `c` | Excluded from md5sums |
| Trusted keys | `rpm -qa gpg-pubkey` | `/etc/apt/keyrings`, `Signed-By:` |
| Security errata | `dnf updateinfo list --security` | `apt list --upgradable`, the Security Tracker |
| Benchmark content | `scap-security-guide`, many profiles | `ssg-debian`, fewer profiles |
| Scanner | `oscap` | `oscap` |
| File integrity | `aide`, `rkhunter` | `aide`, `rkhunter`, `debsums` |

**The patch model is the same idea with different words.** Debian stable and Ubuntu
LTS backport into the shipped version exactly as RHEL does, so the false positive in
this topic is not a Red Hat quirk. Ubuntu additionally publishes USN advisories and
`pro fix USN-1234-5` as a per-advisory remediation path, which is a convenient way to
close a specific finding and to produce evidence that you did.

## Prove it

```
# Is the fix actually in the binary, whatever the version string says
rpm -q --changelog httpd | grep -i CVE | head
dnf updateinfo list --security

# Has anything on disk changed since it was installed
sudo rpm -Va | grep -v ' c /'
sudo debsums -c

# Who can ship code to this host as root
rpm -qa gpg-pubkey --qf '%{summary}\n'
grep -rn gpgcheck /etc/yum.repos.d/

# Does the machine match the standard, with an artefact to hand over
oscap xccdf eval --profile cis_server_l1 --report scan-report.html \
  /usr/share/xml/scap/ssg/content/ssg-rhel10-ds.xml

# Has anything changed since the last known-good baseline
sudo aide --check
```

**The pairing that matters is `rpm -q --changelog` and the scan report.** One is the
claim and the other is the evidence that contradicts it, and being able to produce the
second in ten seconds is what turns a two-week argument into a two-minute one.

## What trips people up

### 1. Reading a version number instead of the vendor's security data

`httpd 2.4.57` on an enterprise distribution may contain fixes upstream shipped in
much later releases, because the vendor backported them and incremented the release
field instead. The version string stopped tracking upstream on day one of the major
release. `rpm -q --changelog` and the vendor's OVAL feed are the authoritative answer.

### 2. Treating a CVSS base score as a risk score

It measures severity of the flaw in the abstract, assuming the component is
installed, running, reachable, and used. It knows nothing about your machine. "All
criticals in 7 days" applied to base scores is how a sprint disappears into a library
nothing loads.

### 3. Baselining a machine you have not verified

`aide --init` and `rkhunter --propupd` record the current state as correct. On a
compromised host that certifies the compromise, and every check afterwards comes back
clean. Baseline from a known-good build, not from whatever is running.

### 4. Leaving the integrity database where the attacker is

Root can rewrite the AIDE database, the RPM database, and the md5sums files. If the
record and the thing recorded share a machine, a competent attacker defeats all of it
in one step. Off the host, or read-only, or it is decoration.

### 5. Chasing every `c` line in `rpm -Va`

Configuration files are meant to be edited and every machine reports dozens.
Filter them out and read what remains. A digest change on a binary (a `5` in
position three, with no marker character) is worth more attention than a
hundred `c` lines.

### 6. An undocumented deviation instead of a written exception

Every estate has rules it cannot apply. The ones that pass audits wrote down the rule,
the reason, the compensating control, and a review date. An exception is a normal
outcome. Silence is a finding.

## Work it through

An auditor hands you a vulnerability scan of a RHEL 10 web server: 340 findings, 12 of
them critical, and a policy saying criticals close within seven days. You have one
afternoon before the remediation meeting.

Reason it out before reading on.

**Ask how the scan was run.** Authenticated, reading the package
database, or unauthenticated, reading banners? One question, and it
reorganises everything after it. An unauthenticated scan of an enterprise
distribution produces exactly this shape of report (hundreds of findings,
mostly against `httpd`, `openssl`, and the kernel) because it compares banner
version strings against upstream fixed-in versions and the release field is
invisible from the network.

**Test the hypothesis on one finding rather than arguing the principle:**

```
rpm -q httpd
rpm -q --changelog httpd | grep -i CVE-2024 | head
dnf updateinfo info CVE-2024-12345
```

If the CVE is named at or below the installed release, that finding is a false positive
and so, probably, are most of its neighbours. Do three, from different packages.

**Sort what survives by reachability, not by score.** Is the package installed
at all, is the service running, is the port reachable from anywhere that matters, and
does anything call the vulnerable code path? A 9.8 in a library that ships in the base
image and is loaded by nothing outranks nothing.

Fourth, split the survivors three ways. Patch what can be patched this week.
Mitigate what cannot, and record the mitigation. Write an exception (reason,
compensating control, owner, review date) for anything left.

Fifth, file the false positives as a defect in the scanning process, with the
OVAL feed the scanner should be consuming. Skip this and the same 340 findings
arrive next quarter, along with the same afternoon.

Now change one detail and watch the answer change. Suppose the scan *was*
authenticated and *was* using the vendor's OVAL. The backporting defence is
gone and the findings are real. Steps one and two vanish, step three becomes
the whole job, and the conversation shifts from "these are wrong" to "here is
the order we are fixing them in and why", a better conversation and a much
worse week.

**And one more.** Suppose one finding is against a Java library inside an application
your team builds. Nobody backported anything, no changelog names the CVE, and `rpm -q`
knows nothing about it because it was never packaged. That finding is real until proven
otherwise, and the only fast way to learn where else that library lives is an SBOM you
generated at build time. Without one, the honest answer is that you cannot currently
answer the question, which is itself the finding.

The point worth extracting: **compliance work is evidence work.** Every step above
replaces an assertion with an artefact somebody else can check, and the two skills
carrying the most weight are knowing which artefact answers which question, and knowing
when a tool is confidently telling you something untrue.

## Try it

Optional, on a machine or container you can break.

1. `rpm -V bash`, and note that silence is the pass. Then `chmod 700 /usr/bin/bash`
   and run it again. Name each character position.
2. `chmod 755 /usr/bin/bash` to put it back, and confirm `rpm -V bash` is silent.
3. `echo "# note" >> /etc/profile; rpm -V setup`. Read the `c` marker, and say why this
   line differs in kind from the one above.
4. `rpm -Va | grep -v ' c /' | head -20` on a machine that has been running a while.
   Decide whether anything there deserves attention.
5. `rpm -q --changelog openssl | grep -i CVE | head`. That is what refuting a scan
   finding looks like.
6. `rpm -qa gpg-pubkey --qf '%{summary}\n'`, then `grep -rn gpgcheck /etc/yum.repos.d/`.
7. Install `aide`, run `aide --init`, move the database into place, and `aide --check`.
   Read the "NO differences" line.
8. Create a file somewhere AIDE watches, `aide --check` again, and read the `+` run.
9. `aide --update` to re-baseline, then consider what would have happened had you done
   that without knowing what the added file was.
10. If `scap-security-guide` is available, `oscap info` the datastream and list the
    profiles before running one.

**Verification step.** You have it when you can look at a line of `rpm -V`
output and say, without checking, whether it is expected or an incident, and
when you can refute a version-string scan finding with two commands.

## Check yourself

<details class="qa">
<summary>Two lines from one <code>rpm -Va</code> run: <code>.M.......    /usr/bin/bash</code> and <code>S.5....T.  c /etc/profile</code>. Which is the incident, and how do you know?</summary>

**`.M.......` on `/usr/bin/bash` is the incident.**

Position 2 is `M`, so the mode changed. Position 3 is a `.`, so the digest
still matches, and there is **no marker character** after the nine positions,
an ordinary packaged binary with no convention that anyone edits it. Something
ran `chmod` on the system shell, and there is no routine reason for that.

**`S.5....T.` with a `c` is expected.** Size, digest, and mtime changed on a file
marked `c` for configuration. Config files exist to be edited, RPM marks them so you
can tell, and every real machine reports dozens. Reading them as alarms is why people
stop reading `rpm -Va` at all.

The tempting wrong answer is the reverse, because the second line has three flags and
the first has one. **Flag count is not severity.** *Which* file and *which* attribute
is the whole judgement: a digest change on a binary is the highest-value line this
command produces, and a mode change on one is close behind.

What you will need next: `rpm -V` compares against the RPM database, which is on the
same machine and writable by root. It catches accidents and clumsy tampering, not an
attacker who thought about it. That is what AIDE with an off-host database is for.

</details>

<details class="qa">
<summary>A scanner reports the web server vulnerable to a CVE fixed upstream in 2.4.62. The host runs 2.4.57 and is fully patched. What do you hand the auditor?</summary>

**Four artefacts, and an admission that the scan is misconfigured.**

The cause is **backporting**. Enterprise distributions promise stable behaviour for the
life of a major release, so they do not move to new upstream releases to fix flaws.
They apply the upstream patch to the version already shipped and increment the
**release** field: `2.4.57-11.el10`. A scanner comparing `2.4.57` against a table of
upstream fixed-in versions reports a flaw that is not present.

What to produce, in order:

1. The finding, quoted exactly: CVE, package, host.
2. The vendor advisory naming the release the fix shipped in.
3. The host's evidence: `rpm -q httpd` showing the installed release is at or above it,
   and `rpm -q --changelog httpd | grep CVE` naming the CVE.
4. The process correction: the scan was version-string matching and should consume the
   vendor's OVAL feed.

The tempting wrong answer is to explain backporting and expect that to settle it. It
does not, because an auditor cannot verify an explanation and can verify a changelog
entry. **Produce the artefact, then explain it.**

And do not skip point four. A false positive is a real defect in the scanner
configuration; leaving it unfixed means the identical report next quarter. What you
will need after that is the same reasoning in reverse, since the version field also
cannot tell you a machine *is* patched. Compare release fields, never versions.

</details>

<details class="qa">
<summary>Your policy says all CVSS criticals are remediated within seven days. Why is that a bad policy as written, and what would make it a good one?</summary>

**Because CVSS measures severity, not risk.**

A base score describes the flaw in the abstract, on a hypothetical system where the
affected component is installed, running, reachable from the network, and executed. All
the worst base metrics together produce the 9.8 on the headline ones. None of them are
facts about your machine, so the policy directs effort by a number that does not know
whether the package is installed, the daemon enabled, the port firewalled, or the
vulnerable code path ever called. The predictable result is a sprint spent patching a
library nothing loads while a medium in the one internet-facing service waits behind it.

**What makes it a good policy is adding context to the score:**

- **Exposure.** Internet-facing outranks internal; internal outranks not running.
- **Exploitation.** A CVE in the CISA KEV catalogue is being used against real systems
  today. EPSS gives a published probability for the rest.
- **Compensating controls.** A mitigation already in place changes the deadline
  legitimately, provided it is written down.
- **Environmental metrics.** CVSS v4.0 has a metric group for exactly this, and almost
  nobody fills it in.

The tempting wrong answer is that severity thresholds are meaningless. They
are not. They are a fine first sort, and a framework may require one. The
failure is treating the first sort as the final order.

</details>

<details class="qa">
<summary>AIDE reports "found NO differences" the morning after a confirmed compromise. Name two ways that happens, and what you would change.</summary>

**Either the database was regenerated, or the changed files were never watched.**

The database was regenerated. `aide --init` and `aide --update` are available
to root, and so is the database file, because it sits on the machine being
checked. An attacker with root re-baselines and every subsequent check is
clean, a report certifying an owned host, worse than no report because it will
be believed. The same argument applies to `rkhunter --propupd`, the RPM
database behind `rpm -V`, and the md5sums behind `dpkg -V`.

The changes were outside the watched set. `/etc/aide.conf` decides scope, and
a configuration tuned to keep the daily report short is a configuration with
holes in it. A web shell dropped in a document root nobody watches produces a
clean run, correctly.

**What to change:**

- Move the database **off the machine**, or onto read-only media, so the check does not
  depend on a file the attacker controls. That is the one altering the threat model.
- Send the report off the box immediately, so the copy that matters is already
  elsewhere.
- Review the scope against where you would actually put something: `/usr/bin`,
  `/usr/sbin`, `/lib`, `/boot`, `/etc`, cron directories, systemd unit paths, and
  application document roots.
- Make `aide --update` an explicit step in the patching runbook, so legitimate change
  does not train everyone to ignore the report.

The tempting wrong answer is that AIDE failed. It reported accurately against the
database it was given. **The database is the control**, and where it lives decides
whether the control means anything.

</details>

<details class="qa">
<summary>You edit <code>/etc/profile</code> on a RHEL host and on a Debian host. <code>rpm -V</code> reports it; <code>dpkg -V</code> says nothing. Is the Debian tooling broken?</summary>

**No. It is checking a deliberately narrower thing.**

`dpkg -V` compares files against the md5sums each package records in
`/var/lib/dpkg/info/`, and that list **excludes conffiles**, the configuration
files `dpkg` tracks separately precisely because they are expected to be
edited. It compares content only: no mode, no owner, no group, no mtime, and
no coverage for packages that ship no md5sums file. `rpm -V` compares nine
attributes from the RPM header, config files included, marking those with `c`
so you can filter rather than exclude.

**So a clean `dpkg -V` is a much weaker statement than a clean `rpm -V`.** It means the
contents of the non-config files it knows about are unchanged. It does not mean nothing
was modified. The fuller Debian answers are `debsums -c` for changed files, `debsums -e`
for configuration files, and `dpkg-query -W -f='${Conffiles}\n'` for the conffile hashes.

The tempting wrong answer is that Debian packages are not verified. They are,
every `.deb` is checked against a signed release file at install time, a
complementary control covering origin rather than drift.

What you will need next: across a mixed estate, a policy saying "verify installed
package integrity" has to name this asymmetry. Discovering it while an auditor watches
is a poor time to learn it.

</details>

## References

- [rpm(8)](https://man7.org/linux/man-pages/man8/rpm.8.html) - Linux man-pages project. Accessed 2026-08-08.
- [dpkg(1)](https://manpages.debian.org/trixie/dpkg/dpkg.1.en.html) - Debian manpages. Accessed 2026-08-08.
- [aide(1)](https://manpages.debian.org/trixie/aide/aide.1.en.html) - Debian manpages. Accessed 2026-08-08.
- [oscap(8)](https://manpages.debian.org/trixie/openscap-scanner/oscap.8.en.html) - Debian manpages. Accessed 2026-08-08.
- [rkhunter(8)](https://manpages.debian.org/trixie/rkhunter/rkhunter.8.en.html) - Debian manpages. Accessed 2026-08-08.
- [Common Vulnerability Scoring System version 4.0: Specification Document](https://www.first.org/cvss/v4-0/specification-document) - FIRST. Accessed 2026-08-08.
- [Backporting Security Fixes](https://access.redhat.com/security/updates/backporting) - Red Hat. Accessed 2026-08-08.
- [Regulation (EU) 2016/679 (General Data Protection Regulation)](https://eur-lex.europa.eu/eli/reg/2016/679/oj) - EUR-Lex. Accessed 2026-08-08.

Captured output came from AlmaLinux 10.2 and Debian 13 containers. The `rpm -V` and
AIDE transcripts are real: the mode change, the appended configuration line, and the
planted `/etc/profile.d/rogue.sh` were all performed on those machines and the reports
are what the tools printed. CVE identifiers in illustrative blocks are placeholders and
name no real vulnerability. Blocks without a distribution and architecture header are
sourced from documentation rather than captured; `oscap`, `rkhunter`, `debsums`,
`syft`, and `cosign` are not installed on the capture images and their invocations are
shown without output rather than with invented output.
