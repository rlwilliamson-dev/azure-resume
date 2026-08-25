---
title: "Secure baselines"
description: "What a baseline is, why establishing one, deploying it and maintaining it are three different jobs with three different failure modes, what a published benchmark actually contains, and why the most common answer a scanner gives is neither pass nor fail."
deck: "Two servers built from the same image, eight months apart, and they no longer match"
track: "security-plus"
level: "working"
order: 410
objectives:
  - "Say what a secure baseline is and how it differs from a benchmark"
  - "Separate establishing, deploying and maintaining a baseline, and name what fails in each"
  - "Read a benchmark run and account for every rule that neither passed nor failed"
  - "Decide when a rule is inapplicable rather than failed, and record the difference"
  - "Name the hardening targets the objective lists and say why one baseline does not cover them"
  - "Check a machine against a baseline on Linux, Windows and macOS, and say what each platform does not give you"
prerequisites: ["control-categories-and-control-types"]
tags: ["security-plus", "security", "operations", "hardening"]
updated: 2026-08-25
draft: false
examObjectives:
  - exam: "sy0-701"
    domain: "4.0"
    objective: "4.1"
sources:
  - title: "SP 800-128, Guide for Security-Focused Configuration Management of Information Systems"
    url: "https://csrc.nist.gov/pubs/sp/800/128/upd1/final"
    publisher: "NIST"
    accessed: 2026-08-25
    tier: 1
  - title: "SP 800-70 Rev. 4, National Checklist Program for IT Products"
    url: "https://csrc.nist.gov/pubs/sp/800/70/r4/final"
    publisher: "NIST"
    accessed: 2026-08-25
    tier: 1
  - title: "ComplianceAsCode, the source of the SCAP Security Guide content"
    url: "https://github.com/ComplianceAsCode/content"
    publisher: "ComplianceAsCode project"
    accessed: 2026-08-25
    tier: 1
  - title: "OpenSCAP User Manual"
    url: "https://www.open-scap.org/resources/documentation/"
    publisher: "OpenSCAP project"
    accessed: 2026-08-25
    tier: 1
  - title: "secedit command reference"
    url: "https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/secedit"
    publisher: "Microsoft"
    accessed: 2026-08-25
    tier: 1
  - title: "macOS Security Compliance Project"
    url: "https://github.com/usnistgov/macos_security"
    publisher: "NIST"
    accessed: 2026-08-25
    tier: 1
symptoms:
  - symptom: "A scanner reports hundreds of rules that neither passed nor failed"
    anchor: "the-answer-that-is-neither-pass-nor-fail"
  - symptom: "Two machines built from the same image behave differently"
    anchor: "three-jobs-that-get-called-one-job"
---

> **Before you read.** Two web servers were built from the same image on the same
> day. One of them was patched in a hurry during an incident in March, and
> somebody turned off a service on the other one in June to make a deployment work.
>
> Eight months later the two machines no longer match, and nobody can say in what
> way without logging into both.
>
> **What would have told you, and when should it have told you?**

A baseline is the answer to "what is this machine supposed to look like", written
down somewhere a machine can read. The exam splits the work into three verbs and
the split is the useful part, because each verb fails differently.

### Some words you will need

<dl class="terms">
<dt>baseline</dt>
<dd>The configuration a machine is supposed to have. Yours, specific to your estate, and the thing drift is measured against.</dd>
<dt>benchmark</dt>
<dd>A published set of configuration recommendations for a product, written by somebody else. A starting point for a baseline rather than a baseline.</dd>
<dt>profile</dt>
<dd>One selection of rules inside a benchmark, aimed at a level of strictness or a regime. One benchmark file usually holds many.</dd>
<dt>hardening</dt>
<dd>Reducing what a machine offers and what it permits, so there is less of it to attack.</dd>
<dt>drift</dt>
<dd>The gap that opens between what the baseline says and what the machine is, once people start using it.</dd>
<dt>remediation</dt>
<dd>Changing the machine so it matches the baseline again.</dd>
<dt>datastream</dt>
<dd>A single file holding the rules, the checks and the profiles together, so one file describes a whole benchmark.</dd>
<dt>notapplicable</dt>
<dd>A scanner's answer when a rule cannot be evaluated on this machine because the thing it is about is not there.</dd>
</dl>

## What breaks without this

**Nobody can say what changed.** Two machines diverge and the only way to compare
them is to read both, by hand, at the time somebody is asking why one of them is
behaving oddly.

**A benchmark gets adopted whole and then abandoned.** Somebody runs the published
profile, gets several hundred findings, and the effort of triaging them is large
enough that the whole exercise stops. The machine ends up with no baseline rather
than an imperfect one.

**A failed rule and an irrelevant rule look the same in the report.** A count of
findings that mixes the two is not a measure of anything, and decisions get made
on it anyway.

**Drift is discovered during an incident.** The moment you most need to know
whether a machine is in a known state is the moment you find out that nobody has
checked for eight months.

## Three jobs that get called one job

The objective names establishing, deploying and maintaining, and treating them as
one project is why baseline work so often produces a document and no machines.

**Establishing** is deciding what the baseline says. It is an argument, mostly,
and the output is a list of settings with a reason against each. This is the part
that gets skipped by adopting a published benchmark unchanged, and adopting one
unchanged is a decision too, just an unexamined one.

**Deploying** is getting the baseline onto machines. Configuration management,
an image, a policy object, a profile from a management server. The failure here
is partial coverage: the baseline reaches the machines built after it existed and
not the forty that were already running.

**Maintaining** is the one with an ongoing cost, and it has two halves that people
merge. One half is detecting drift, which means measuring machines against the
baseline on a schedule. The other is updating the baseline itself, because the
software changes, new settings appear, and a baseline written for last year's
version is quietly wrong in ways nobody notices.

<details class="predict">
<summary>Of those three jobs, which one is still costing money in year three, and roughly what is it being spent on?</summary>

**Maintaining, and most of it goes on the baseline rather than on the machines.**

The intuition is usually the other way round: establishing feels like the big
piece of work because it is the one with meetings in it, and it is finite. You
decide, you write it down, you are done. Deploying is finite too, and it gets
easier as the estate turns over.

Maintaining never finishes and it splits in two. Detecting drift is cheap once
automated, which is the half people plan for. Keeping the baseline current is
not, because every operating system update can add settings, rename settings,
change a default, or deprecate something the baseline still requires. Nobody is
assigned to notice, so the baseline ages, machines are measured against a
document that describes a version they are no longer running, and the report
stays green while meaning less every quarter.

That is the honest annual cost of a baseline, and it is a person's attention
rather than a licence.

</details>

<figure class="learn-figure">
<svg viewBox="0 0 720 268" role="img" aria-labelledby="jobs-title" style="width:100%;height:auto;">
<title id="jobs-title">Two machines built from one image drifting apart over eight months, with the three baseline jobs marked at the points where each one would have caught the divergence</title>
<g fill="currentColor">
<text x="14" y="20" font-size="11">one image, two machines, and the gap that opens after they are handed over</text>
<path d="M 60 210 H 690" stroke="currentColor" stroke-opacity="0.45" stroke-width="1.2"/>
<text x="60" y="228" font-size="9" fill-opacity="0.7">build day</text>
<text x="690" y="228" text-anchor="end" font-size="9" fill-opacity="0.7">month eight</text>
<path d="M 60 120 H 200" stroke="currentColor" stroke-opacity="0.8" stroke-width="2"/>
<path d="M 200 120 C 300 120, 320 96, 430 96 L 690 96" stroke="var(--accent)" stroke-opacity="0.9" stroke-width="2" fill="none"/>
<path d="M 200 120 C 300 120, 340 158, 470 158 L 690 158" stroke="var(--red)" stroke-opacity="0.85" stroke-width="2" fill="none"/>
<text x="694" y="99" font-size="8.5" fill-opacity="0.85" text-anchor="end">web01</text>
<text x="694" y="176" font-size="8.5" fill-opacity="0.85" text-anchor="end">web02</text>
<text x="214" y="86" font-size="8.5" fill-opacity="0.8">March: patched during an incident</text>
<text x="246" y="180" font-size="8.5" fill-opacity="0.8">June: a service switched off for a deployment</text>
<rect x="46" y="42" width="120" height="30" rx="4" fill="var(--accent)" fill-opacity="0.12" stroke="var(--accent)" stroke-width="1.4"/>
<text x="106" y="61" text-anchor="middle" font-size="9">establish</text>
<rect x="186" y="42" width="120" height="30" rx="4" fill="var(--accent)" fill-opacity="0.12" stroke="var(--accent)" stroke-width="1.4"/>
<text x="246" y="61" text-anchor="middle" font-size="9">deploy</text>
<rect x="326" y="42" width="364" height="30" rx="4" fill="var(--accent)" fill-opacity="0.12" stroke="var(--accent)" stroke-width="1.4" stroke-dasharray="5 3"/>
<text x="508" y="61" text-anchor="middle" font-size="9">maintain, which is the only one still running here</text>
<path d="M 106 76 V 114" stroke="currentColor" stroke-opacity="0.35" stroke-width="1"/>
<path d="M 246 76 V 114" stroke="currentColor" stroke-opacity="0.35" stroke-width="1"/>
<path d="M 430 76 V 92" stroke="currentColor" stroke-opacity="0.35" stroke-width="1"/>
<path d="M 470 76 V 154" stroke="currentColor" stroke-opacity="0.35" stroke-width="1"/>
<text x="14" y="252" font-size="10" fill-opacity="0.85">the gap is not the problem. not knowing the gap exists is the problem</text>
</g></svg>
<figcaption>The two changes that separated these machines were both reasonable at the time, and neither was wrong. What is wrong is that eight months passed with nothing measuring either machine against what it was supposed to be, so the divergence was discovered by somebody debugging rather than reported by something scheduled. Establishing and deploying are finite pieces of work that finish. Maintaining is the dashed box, it runs for the life of the estate, and it is the one that gets no owner because it never appears as a project with an end date.</figcaption>
</figure>

<details class="deeper">
<summary>If you run configuration management already: where a baseline and a config repository stop being the same thing</summary>

If everything is built by Ansible or Puppet or a Terraform module, it is tempting
to say the repository is the baseline. It mostly is, and the gap between "mostly"
and "is" is where the interesting failures live.

A configuration repository describes what you set. A baseline describes what
should be true. Those differ on every setting nobody thought to manage, which is
most of them: a default that changed in a minor release, a package that brought
its own configuration, a setting an operator changed by hand at three in the
morning and never told the repository about.

The practical test is whether your tooling reports on state it does not manage.
Most convergence tools do not, by design. They enforce the resources declared in
the code and are silent about everything else, so a machine can be fully
converged and still fail a benchmark on forty rules nobody has ever written a
resource for.

That is the argument for running a scanner as well as a convergence run, even
in a fully managed estate. They answer different questions. One says "is the
machine what my code says", the other says "is the machine what a third party
thinks a machine like this should be", and the second one occasionally finds
something the first was never going to look at.

SP 800-128 is the document that makes this distinction formally, in the language
of configuration items and baseline configurations, and it is worth reading once
if you are the person who has to argue for the second tool.

</details>

## A benchmark is a starting point that arrives with numbers

Here is one, on a real machine, with real counts.

```bash
# AlmaLinux 10.2, x86_64
$ rpm -q openscap-scanner scap-security-guide | tr "\n" " "; echo; ls /usr/share/xml/scap/ssg/content/ | head -8
openscap-scanner-1.4.4-1.el10_2.alma.1.x86_64 scap-security-guide-0.1.81-1.el10_2.alma.1.noarch 
ssg-almalinux10-ds.xml
```

Two packages: a scanner and the content it evaluates. The content is one file for
this product, and inside it are seventeen different opinions about what this
machine should look like.

```bash
# AlmaLinux 10.2, x86_64
$ oscap info --profiles /usr/share/xml/scap/ssg/content/ssg-almalinux10-ds.xml
xccdf_org.ssgproject.content_profile_anssi_bp28_enhanced:ANSSI-BP-028 (enhanced)
xccdf_org.ssgproject.content_profile_anssi_bp28_high:ANSSI-BP-028 (high)
xccdf_org.ssgproject.content_profile_anssi_bp28_intermediary:ANSSI-BP-028 (intermediary)
xccdf_org.ssgproject.content_profile_anssi_bp28_minimal:ANSSI-BP-028 (minimal)
xccdf_org.ssgproject.content_profile_bsi:BSI SYS.1.1 and SYS.1.3
xccdf_org.ssgproject.content_profile_cis:CIS AlmaLinux OS 10 Benchmark for Level 2 - Server
xccdf_org.ssgproject.content_profile_cis_server_l1:CIS AlmaLinux OS 10 Benchmark for Level 1 - Server
xccdf_org.ssgproject.content_profile_cis_workstation_l1:CIS AlmaLinux OS 10 Benchmark for Level 1 - Workstation
xccdf_org.ssgproject.content_profile_cis_workstation_l2:CIS AlmaLinux OS 10 Benchmark for Level 2 - Workstation
xccdf_org.ssgproject.content_profile_e8:Australian Cyber Security Centre (ACSC) Essential Eight
xccdf_org.ssgproject.content_profile_hipaa:Health Insurance Portability and Accountability Act (HIPAA)
xccdf_org.ssgproject.content_profile_ism_o:Australian Cyber Security Centre (ACSC) ISM Official - Base
xccdf_org.ssgproject.content_profile_ism_o_secret:Australian Cyber Security Centre (ACSC) ISM Official - Secret
xccdf_org.ssgproject.content_profile_ism_o_top_secret:Australian Cyber Security Centre (ACSC) ISM Official - Top Secret
xccdf_org.ssgproject.content_profile_pci-dss:PCI-DSS v4.0.1 Control Baseline for AlmaLinux OS 10
xccdf_org.ssgproject.content_profile_stig:Red Hat STIG for AlmaLinux OS 10
xccdf_org.ssgproject.content_profile_stig_gui:Red Hat STIG with GUI for AlmaLinux OS 10
```

**Read that list before reading anything else about baselines.** Seventeen
profiles, from four levels of a French agency's guidance through an Australian
one, a German one, a payment card regime, a health regime, and two levels each of
CIS server and CIS workstation. All of them are for the same operating system.
None of them is the baseline for your machine, and choosing between them is the
work the word "establishing" is pointing at.

The choice is not cosmetic. Run four of them against the same machine and they do
not agree about how many questions there are, let alone the answers.

<details class="predict">
<summary>The same machine, four published profiles. Predict the spread in how many rules each one evaluates.</summary>

```bash
# AlmaLinux 10.2, x86_64
$ for p in cis_server_l1 stig pci-dss anssi_bp28_minimal; do printf "%-20s" "$p"; oscap xccdf eval --profile "$p" /usr/share/xml/scap/ssg/content/ssg-almalinux10-ds.xml 2>/dev/null | awk -F"\t" '/^Result/{c[$2]++} END{printf "%4d rules  %3d pass  %2d fail  %3d notapplicable\n", c["pass"]+c["fail"]+c["notapplicable"], c["pass"], c["fail"], c["notapplicable"]}'; done
cis_server_l1        323 rules   73 pass   3 fail  247 notapplicable
stig                 508 rules   64 pass   6 fail  438 notapplicable
pci-dss              252 rules   37 pass   0 fail  215 notapplicable
anssi_bp28_minimal    37 rules   14 pass   1 fail   22 notapplicable
```

**Thirty-seven to five hundred and eight, a factor of nearly fourteen.** Same
machine, same file, same afternoon.

The number of findings a machine has is therefore not a property of the machine.
It is a property of which profile somebody selected, and a report that says "we
have six findings" without saying which profile produced them is a sentence with
no information in it.

Notice the PCI-DSS row in particular: zero fails. That is not a stronger machine
than the STIG row's six. It is a different question, asked of the same machine,
and answered against a narrower set of rules.

</details>

<figure class="learn-figure">
<svg viewBox="0 0 720 250" role="img" aria-labelledby="prof-title" style="width:100%;height:auto;">
<title id="prof-title">Four published profiles evaluated against one machine, drawn to scale, showing that the rule counts differ by a factor of nearly fourteen and that inapplicable dominates every one of them</title>
<g fill="currentColor">
<text x="14" y="20" font-size="11">four published profiles, one machine, drawn to the same scale</text>
<rect x="330" y="32" width="11" height="9" rx="2" fill="var(--accent)" fill-opacity="0.5" stroke="var(--accent)" stroke-width="1.2"/>
<text x="347" y="40" font-size="9" fill-opacity="0.8">pass</text>
<rect x="386" y="32" width="11" height="9" rx="2" fill="var(--red)" fill-opacity="0.75" stroke="var(--red)" stroke-width="1.2"/>
<text x="403" y="40" font-size="9" fill-opacity="0.8">fail</text>
<rect x="436" y="32" width="11" height="9" rx="2" fill="currentColor" fill-opacity="0.1" stroke="currentColor" stroke-opacity="0.6" stroke-width="1.2" stroke-dasharray="3 2"/>
<text x="453" y="40" font-size="9" fill-opacity="0.8">notapplicable</text>
<text x="14" y="70" font-size="9">cis_server_l1</text>
<rect x="150" y="58" width="69" height="17" fill="var(--accent)" fill-opacity="0.5" stroke="var(--accent)" stroke-width="1"/>
<rect x="219" y="58" width="3" height="17" fill="var(--red)" fill-opacity="0.85"/>
<rect x="222" y="58" width="233" height="17" fill="currentColor" fill-opacity="0.08" stroke="currentColor" stroke-opacity="0.5" stroke-width="1" stroke-dasharray="3 2"/>
<text x="463" y="70" font-size="8.5" fill-opacity="0.85">323</text>
<text x="14" y="104" font-size="9">stig</text>
<rect x="150" y="92" width="60" height="17" fill="var(--accent)" fill-opacity="0.5" stroke="var(--accent)" stroke-width="1"/>
<rect x="210" y="92" width="6" height="17" fill="var(--red)" fill-opacity="0.85"/>
<rect x="216" y="92" width="414" height="17" fill="currentColor" fill-opacity="0.08" stroke="currentColor" stroke-opacity="0.5" stroke-width="1" stroke-dasharray="3 2"/>
<text x="638" y="104" font-size="8.5" fill-opacity="0.85">508</text>
<text x="14" y="138" font-size="9">pci-dss</text>
<rect x="150" y="126" width="35" height="17" fill="var(--accent)" fill-opacity="0.5" stroke="var(--accent)" stroke-width="1"/>
<rect x="185" y="126" width="203" height="17" fill="currentColor" fill-opacity="0.08" stroke="currentColor" stroke-opacity="0.5" stroke-width="1" stroke-dasharray="3 2"/>
<text x="396" y="138" font-size="8.5" fill-opacity="0.85">252</text>
<text x="14" y="172" font-size="9">anssi_bp28_minimal</text>
<rect x="150" y="160" width="13" height="17" fill="var(--accent)" fill-opacity="0.5" stroke="var(--accent)" stroke-width="1"/>
<rect x="163" y="160" width="1" height="17" fill="var(--red)" fill-opacity="0.85"/>
<rect x="164" y="160" width="21" height="17" fill="currentColor" fill-opacity="0.08" stroke="currentColor" stroke-opacity="0.5" stroke-width="1" stroke-dasharray="3 2"/>
<text x="193" y="172" font-size="8.5" fill-opacity="0.85">37</text>
<text x="14" y="206" font-size="10" fill-opacity="0.85">the fail bars are three, six, none and one rule wide, which is why you can barely see them</text>
<text x="14" y="228" font-size="10" fill-opacity="0.85">and the dashed part is the majority of every profile on this particular machine</text>
</g></svg>
<figcaption>Every bar is one profile from the same file evaluated against the same machine on the same afternoon, drawn to a single scale. The failures are the thin red slivers and they are easy to miss, which is the honest visual answer to "how bad is this machine": on these four profiles, three fails, six fails, none and one. The dashed majority is the answer that is neither pass nor fail, and on this machine it runs from fifty-nine percent of the smallest profile to eighty-six percent of the largest. A report that quotes a finding count without naming the profile has quoted one number out of four possible ones.</figcaption>
</figure>

<details class="deeper">
<summary>If you have been handed a benchmark to implement: what the levels actually mean, and the one that is not a level</summary>

CIS numbers its profiles Level 1 and Level 2 and the distinction is stated in
terms of impact rather than security. Level 1 is intended to be applicable
without breaking things. Level 2 is for environments where security is worth
noticeable operational cost, and it is expected to break something.

That is a more useful reading than "Level 2 is more secure", because it tells you
what the argument with the application team will be about. It will not be about
whether the setting is a good idea. It will be about whether the thing it breaks
is worth more than the risk it removes, and Level 2 is the set where somebody
already decided that answer varies.

The server and workstation split is doing something different again. It is not
strictness, it is assumptions about who sits in front of the machine and what is
plausibly installed. Applying the workstation profile to a server produces a mess
of irrelevant findings rather than a stricter server.

STIG is the one that is not a level. It is a Department of Defense
requirement set with a compliance process attached, and its rules carry severity
categories rather than levels. If somebody hands you a STIG they are usually
handing you an obligation rather than a recommendation, and the interesting field
is not the rule text but whether an exception process exists.

The general habit: before implementing any benchmark, find out what its authors
say it is for, because all of them say so explicitly and almost nobody reads it.

</details>

## The answer that is neither pass nor fail

Look again at the first row. Three failures and two hundred and forty-seven rules
that did not produce a result at all.

That is not the scanner giving up. It is the scanner saying the rule is about
something this machine does not have.

```bash
# AlmaLinux 10.2, x86_64
$ oscap xccdf eval --profile cis_server_l1 /usr/share/xml/scap/ssg/content/ssg-almalinux10-ds.xml 2>/dev/null | awk -F"\t" "/^Title/{t=\$2} /^Result/{print \$2 \"|\" t}" | grep -v notapplicable | grep fail
fail|Implement Custom Crypto Policy Modules for CIS Benchmark
fail|Ensure the Default Bash Umask is Set Correctly
fail|Ensure the Default Umask is Set Correctly in /etc/profile
```

Three real findings, and they are the sort you can act on in an afternoon. Now
some of the two hundred and forty-seven.

```bash
# AlmaLinux 10.2, x86_64
$ oscap xccdf eval --profile cis_server_l1 /usr/share/xml/scap/ssg/content/ssg-almalinux10-ds.xml 2>/dev/null | awk -F"\t" "/^Title/{t=\$2} /^Result/{if(\$2==\"notapplicable\") print t}" | sed -n "5p;40p;95p;150p;200p;240p"
Ensure /dev/shm is configured
Ensure PAM Enforces Password Requirements - Minimum Different Characters
Disable systemd-journal-remote Socket
Add nosuid Option to /tmp
Ensure that /etc/at.allow exists
Enable PAM
```

Mount options, PAM configuration, systemd sockets, the at daemon's allow file.
Every one of them is a real rule about a real risk, and every one of them is
about a part of the system this particular machine does not own.

**The machine is a container.** It has a userland and no kernel, and the rules
that did not run are the ones that would have had to ask the kernel something.

```bash
# AlmaLinux 10.2, x86_64
$ systemd-detect-virt --container 2>/dev/null || echo "(no systemd-detect-virt)"; ls /lib/modules 2>&1; echo "kernel the container reports:"; uname -r
podman
kernel the container reports:
7.1.3-200.fc44.aarch64
```

`/lib/modules` is empty, and `uname -r` answers with a kernel that belongs to
somebody else. The userland here is AlmaLinux 10.2 on x86_64 and the kernel
version it reports is Fedora 44 on aarch64, because the container is borrowing
the host's kernel and cannot do otherwise.

The content knows this is possible, and gates rules on it.

```bash
# AlmaLinux 10.2, x86_64
$ grep -o "platform idref=\"[^\"]*\"" /usr/share/xml/scap/ssg/content/ssg-almalinux10-ds.xml | sort | uniq -c | sort -rn | head -6
    189 platform idref="#system_with_kernel"
     23 platform idref="#package_pam"
     17 platform idref="#not_aarch64_arch"
     15 platform idref="#package_libpwquality"
     15 platform idref="#aarch64_arch"
     14 platform idref="#ppc64le_arch"
```

One hundred and eighty-nine rules in this file are conditional on the system
having a kernel of its own, more than any other condition in it. Others are
conditional on a package being installed, or on the processor architecture.

**This is the property that makes a benchmark usable on machines it was not
written for**, and it is worth stating as a rule you can apply outside SCAP:
inapplicable is a third answer, it is not a quiet failure, and a report that
collapses it into either of the other two is lying in one direction or the other.

The consequence for the exam and for the job is the same. When a rule does not
apply, you record why, and the recording matters because next quarter the machine
might be a virtual machine rather than a container and the same rule will start
having an answer.

<details class="deeper">
<summary>If you produce compliance figures: the percentage that gets quoted, and the three ways to compute it</summary>

Somebody will eventually ask for a compliance percentage. There are three
defensible ways to compute one from this run and they give different answers.

Pass over pass plus fail is 73 of 76, which is 96 percent. This is the number
most tools report by default and it answers "of the things we could check, how
many were right".

Pass over every rule in the profile is 73 of 323, which is 23 percent. This
answers "how much of this benchmark does this machine satisfy", and on a machine
where most rules are inapplicable it is a misleading way to say something true.

Neither of those is the number a risk conversation wants. The third one is a
count rather than a percentage: three failures, named, with an owner and a date
against each. It cannot be gamed by changing profile, it does not move when the
machine's shape changes, and it is the only one of the three that tells somebody
what to do on Monday.

The reason to know all three is that you will be shown one of the first two and
asked whether things are getting better. The answer depends on whether the
denominator moved, and the denominator moves whenever anybody changes the
profile, upgrades the content package, or rebuilds the machine differently.

Ask what the denominator is. It is the single most useful question about any
compliance figure and it is almost never in the report.

</details>

## Across platforms

Checking a machine against a baseline is a job all three platforms have, and they
answer it in three different shapes rather than with three different commands.
Linux ships the content and the scanner together. Windows ships the engine and no
content. macOS ships neither, and on an unmanaged machine there is no baseline to
be measured against at all.

| Task | Linux | Windows | macOS |
| --- | --- | --- | --- |
| Is a benchmark scanner installed | `oscap`, from `openscap-scanner` | nothing in the box | nothing in the box |
| Where the content comes from | `scap-security-guide`, one datastream per product | you supply it, as a security template or a Group Policy backup | a configuration profile, sent by management |
| Run the check | `oscap xccdf eval --profile P file.xml` | `secedit /export` and compare the values yourself | ask each setting individually |
| Per-rule result | pass, fail or notapplicable | none | none |

```powershell
# Microsoft Windows Server 2025 Datacenter, version 10.0.26100.0
> Get-Command oscap, scap, Invoke-ScapScan -ErrorAction SilentlyContinue | Measure-Object | Select-Object -ExpandProperty Count
0

# The local security policy exported as a template, which is the baseline format Windows uses
> secedit /export /cfg $env:TEMP\current.inf /quiet; Select-String -Path $env:TEMP\current.inf -Pattern '^(MinimumPasswordLength|MaximumPasswordAge|LockoutBadCount) ' | ForEach-Object { $_.Line }
MaximumPasswordAge = 42
MinimumPasswordLength = 0
LockoutBadCount = 10

# How many settings that export carries, against the 323 rules the Linux profile evaluated
> (Select-String -Path $env:TEMP\current.inf -Pattern '^\S+\s*=' | Measure-Object).Count
109

# The comparison, which nothing in the box will do for you
> $want = @{ MinimumPasswordLength = 14; MaximumPasswordAge = 30; LockoutBadCount = 5 }; $have = @{}; Select-String -Path $env:TEMP\current.inf -Pattern '^(\S+) = (\S+)' | ForEach-Object { $have[$_.Matches[0].Groups[1].Value] = $_.Matches[0].Groups[2].Value }; $want.Keys | Sort-Object | ForEach-Object { "{0,-22} want {1,-4} have {2,-4} {3}" -f $_, $want[$_], $have[$_], $(if ([int]$have[$_] -eq $want[$_]) { 'pass' } else { 'fail' }) }
LockoutBadCount        want 5    have 10   fail
MaximumPasswordAge     want 30   have 42   fail
MinimumPasswordLength  want 14   have 0    fail
```

**The last block is a script, not a tool, and that is the finding.** Windows will
export its security policy in the same format it imports one, which is genuinely
useful, and 109 settings came out. What it will not do from the command line is
tell you how those settings compare with a baseline. The three-line comparison at
the end had to be written, and the pass and fail words in that output are ones
this script printed rather than ones Windows decided.

Note the default values while they are on screen. A maximum password age of 42
days, a minimum length of zero, and ten bad attempts before lockout. Those are
what an unconfigured Windows Server has, and every benchmark for the platform
changes at least two of them.

```bash
# macOS 26.5.2, arm64
$ command -v oscap scap-workbench 2>/dev/null | wc -l | tr -d ' '
0

# Which configuration profiles are installed, which is where a macOS baseline lands
$ sudo /usr/bin/profiles show 2>&1 | head -4
There are no configuration profiles installed in the system domain

# Whether the machine is enrolled in anything that could send one
$ sudo /usr/bin/profiles status -type enrollment 2>&1
Enrolled via DEP: No
MDM enrollment: No

# Two settings a benchmark would check, asked one at a time because nothing will ask for you
$ sudo /usr/sbin/systemsetup -getremotelogin 2>&1; /usr/bin/fdesetup status 2>&1; /usr/bin/sudo /usr/bin/pwpolicy getaccountpolicies 2>&1 | head -3
Remote Login: On
FileVault is Off.
Getting global account policies
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
```

**macOS is the honest illustration of what a baseline is for.** There are no
configuration profiles installed, the machine is enrolled in nothing, so there is
no statement anywhere on it about what it is supposed to look like. Asking about
individual settings still works and returns real answers: remote login is on and
FileVault is off, which two of the three published macOS benchmarks would flag.
Nothing on the machine knows that, because nothing on the machine has been told
what it should be.

That is the difference between a hardened machine and a machine with a baseline.
You can harden this Mac by hand this afternoon. Without a profile it will still
have nothing to drift from, and in eight months you will be back at the top of
this page.

**The published content does exist for both platforms**, and neither ships it.
Microsoft publishes the Security Compliance Toolkit with baselines as Group
Policy backups, and NIST publishes the macOS Security Compliance Project, which
generates the profiles and the checking scripts from the same rule set. Both are
downloads. That is the shape of the difference: on Linux the content is a package
the distribution maintains, and on the other two it is something you go and get.

## Prove it

**Run it.** On any Linux machine with `openscap-scanner` and
`scap-security-guide` installed, run `oscap info --profiles` against your
distribution's datastream and count the profiles. Then evaluate two of them and
compare the rule totals. The point of the exercise is the difference between the
two numbers rather than either number.

**Work it out.** Take the run above: 323 rules, 73 pass, 3 fail, 247
notapplicable. Compute the compliance percentage three ways, as pass over pass
plus fail, as pass over the whole profile, and as a count of failures. Then decide
which of the three you would put in a monthly report to somebody who is not
technical, and write one sentence saying why.

**Look it up.** Open SP 800-128 and find what it calls the thing this topic calls
a baseline. The term it uses is more precise and the reason it is more precise is
the useful part.

## What trips people up

### 1. Treating a benchmark as a baseline

A benchmark is somebody else's opinion about a product. A baseline is your
statement about your machines. Adopting a benchmark unchanged is a legitimate way
to produce a baseline and it is still a decision, which means it has an owner and
a date like any other.

### 2. Reading notapplicable as a pass

It is neither. `notapplicable` means the rule could not be evaluated because the
thing it is about is absent, and 247 of them on the run above are mostly rules
that needed a kernel to ask. If the machine changes shape, they will start
producing answers, and some of those answers will be failures that were always
there in potential.

### 3. Quoting a finding count with no profile attached

Six findings under the STIG profile and zero under PCI-DSS are the same machine
on the same afternoon. The count is a fact about the question, not about the
machine, and a report without the profile name in it cannot be compared with
anything, including itself last month.

### 4. Applying a workstation profile to a server

The CIS server and workstation profiles are not two strictness levels. They assume
different things about what is installed and who is at the keyboard, so the wrong
one produces a long list of irrelevant findings that buries the relevant ones.

### 5. Establishing a baseline and never maintaining it

The document gets written, the machines get built, and nobody is assigned to
notice when the operating system adds a setting or changes a default. Two years
later the machines are measured against a description of a version they are not
running, and the report is green.

### 6. Assuming an unmanaged machine can drift

Drift is measured against a baseline. The Mac above cannot drift, because nothing
on it says what it should be. That sounds like a technicality and it is the
difference between a machine you can report on and one you can only inspect.

## Work it through

Forty Linux servers, built over three years by four different people. There is no
baseline. You have been asked to produce one and you have a quarter.

**The tempting move is to pick the strictest profile and remediate.** Take the
STIG, run it everywhere, fix everything. On the numbers above that is over five
hundred rules per machine, and on real servers rather than a container most of
those 438 inapplicable rules will have answers, so the finding count will be
large and real. The team will spend the quarter triaging, several changes will
break applications, and the exercise will acquire a reputation.

**The move that works starts with measuring and changes nothing.** Run a profile
everywhere and collect the results without remediating. You now know two things
you did not know: what the estate actually looks like, and which rules are
already satisfied on every machine. Those rules are free. They go into the
baseline immediately because nothing has to change for them to be true, and they
are usually a substantial fraction.

**Then the argument is small enough to have.** What is left is the rules that
some machines pass and others fail, which is drift you have just discovered, plus
the rules nothing passes, which is a decision about whether you want them. The
first group is a remediation list. The second is a conversation with the
application teams, and it is a much shorter conversation than one that opens with
five hundred rules.

**What this rejects is completeness in the first quarter.** The baseline you
publish will not cover everything the STIG covers, and the STIG's authors are not
wrong. The alternative is a complete baseline that nothing is measured against,
because the effort to reach it exceeded the quarter, and a partial baseline that
is enforced beats a total one that is aspirational.

The cost of the choice is worth stating plainly: you have accepted the rules you
left out, and unless they are written down as accepted with a date, you have
accepted them silently, which is the thing the risk topic warns about.

## Try it

**Count your own profiles.** On a Linux machine, install `scap-security-guide`
and run `oscap info --profiles` against the datastream for your distribution.
Then pick the profile whose name you understand least and read what its authors
say it is for.

**Find your platform's inapplicable rules.** Run one profile and list everything
that came back `notapplicable`, then pick three and work out what about your
machine made them irrelevant. On a container it is the kernel. On a virtual
machine it will be something else, and the something else is worth knowing.

**Check the two settings this page found on macOS.** If you are on a Mac, run
`fdesetup status` and `sudo /usr/bin/profiles status -type enrollment`. Two
commands, and between them they tell you whether the machine is encrypted and
whether anything is in a position to tell it what to be.

**Export a Windows baseline.** On a Windows machine, `secedit /export /cfg
baseline.inf` produces the whole local security policy as a text file. Read it
once. It is more settings than most people expect and fewer than a benchmark
covers, and both of those facts are useful.

## Check yourself

<details class="qa">
<summary>What is the difference between a benchmark and a baseline, and why does it matter operationally?</summary>

A benchmark is published configuration guidance for a product, written by
somebody outside your organisation. A baseline is your statement of what your
machines should be.

It matters because drift is measured against a baseline. Machines cannot drift
from a benchmark you have not adopted, and adopting one unchanged is itself a
decision that needs an owner, so that when the benchmark's next version changes
forty rules there is somebody whose job it is to look.

</details>

<details class="qa">
<summary>A scan reports 323 rules, 73 pass, 3 fail and 247 notapplicable. Somebody asks whether the machine is compliant. What do you say?</summary>

Ask which profile, first, because the same machine returned 508 rules under the
STIG profile and 252 under PCI-DSS.

Then give the count rather than a percentage: three failures, named. The
percentage is 96 percent if you divide by the rules that produced an answer and
23 percent if you divide by the whole profile, and both of those are defensible,
which is exactly why neither is a good answer on its own.

The 247 are not passes and not failures. They are rules about parts of the system
this machine does not have, and if the machine's shape changes they will start
producing results.

</details>

<details class="qa">
<summary>Name the three jobs the objective splits baseline work into, and say which one has the ongoing cost.</summary>

Establishing, deploying and maintaining.

Maintaining is the one that never finishes, and it has two halves. Detecting
drift is the half people automate. Keeping the baseline current as the operating
system changes is the half nobody is assigned, and it is why a two-year-old
baseline can report green while describing a version that is no longer running.

</details>

<details class="qa">
<summary>Why can a published benchmark for your exact operating system still contain rules that do not apply to your machine?</summary>

Because the benchmark is written for the product and your machine is one
deployment of it. The content gates rules on conditions: whether the system has
its own kernel, whether a package is installed, what the processor architecture
is. In the file used on this page, 189 rules are conditional on the machine
having a kernel of its own, which a container does not.

The scanner reports those as `notapplicable` rather than passing or failing them,
and that third answer is the mechanism that makes one benchmark usable across
machines of different shapes.

</details>

<details class="qa">
<summary>An unmanaged Mac has FileVault off and remote login on. Is that drift?</summary>

No. Drift is a gap between a machine and its baseline, and this machine has no
baseline: `profiles show` reports nothing installed and it is enrolled in
nothing.

Those two settings are findings against a published benchmark, which is a
different statement. The distinction is practical rather than pedantic, because
fixing the two settings by hand leaves the machine in exactly the same position
it is in now, with nothing on it that says what it should be and nothing that
will notice when it changes again.

</details>

## References

- [SP 800-128](https://csrc.nist.gov/pubs/sp/800/128/upd1/final) - NIST, Guide for Security-Focused Configuration Management of Information Systems, for baseline configurations and what maintaining one involves. Free. Accessed 2026-08-25.
- [SP 800-70 Rev. 4](https://csrc.nist.gov/pubs/sp/800/70/r4/final) - NIST, National Checklist Program for IT Products, for what a published checklist is and who is expected to tailor it. Free. Accessed 2026-08-25.
- [ComplianceAsCode](https://github.com/ComplianceAsCode/content) - the project that builds the SCAP Security Guide content used on this page, including the platform conditions that produce `notapplicable`. Free. Accessed 2026-08-25.
- [OpenSCAP documentation](https://www.open-scap.org/resources/documentation/) - the scanner, its result values and the command syntax. Free. Accessed 2026-08-25.
- [secedit](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/secedit) - Microsoft, for the export, import and analyse operations on the Windows side. Free. Accessed 2026-08-25.
- [macOS Security Compliance Project](https://github.com/usnistgov/macos_security) - NIST, the published macOS baseline content that macOS itself does not ship. Free. Accessed 2026-08-25.

**Where the content came from.** The Linux blocks are captured from an AlmaLinux
10.2 container with `openscap-scanner` 1.4.4 and `scap-security-guide` 0.1.81
installed, and every count on this page comes from those runs rather than from
documentation. The Windows and macOS blocks are captured from disposable runners.
The container's `notapplicable` count is a real property of running a
server benchmark against a container, which is why that machine was used rather
than worked around: it makes the third result value visible in a way a
conventional server would not.

**If you also work on Linux.** The Linux+ track's
[compliance, auditing and integrity](/learn/linux-plus/compliance-auditing-and-integrity)
topic covers the same scanner from the operator's side, including remediation,
and [the system you cannot change](/learn/linux-plus/the-system-you-cannot-change)
covers image-based hosts where the baseline is the image.
