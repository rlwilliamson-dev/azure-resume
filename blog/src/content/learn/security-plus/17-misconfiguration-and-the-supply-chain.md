---
title: "Misconfiguration and the supply chain"
description: "Why the largest category of real-world exposure has no identifier, what one dependency actually brings with it, what a build verifies by default, and how a software provider becomes an attacker without being compromised."
deck: "The storage bucket was public for four days and nothing in the logs says so"
track: "security-plus"
level: "working"
order: 180
objectives:
  - "Say why misconfiguration has no CVE and what follows from that"
  - "Distinguish an insecure default from a merely surprising one"
  - "Count what one dependency brings with it"
  - "Say what a build verifies by default and what it does not"
  - "Name the three supply chain categories in this objective"
  - "Identify where in a build a substitution would be caught"
prerequisites: ["vulnerabilities-in-the-platform"]
tags: ["security-plus", "security", "threats", "supply-chain"]
updated: 2026-08-26
draft: false
examObjectives:
  - exam: "sy0-701"
    domain: "2.0"
    objective: "2.3"
sources:
  - title: "SP 800-161 Rev. 1, Cybersecurity Supply Chain Risk Management Practices"
    url: "https://csrc.nist.gov/pubs/sp/800/161/r1/upd1/final"
    publisher: "NIST"
    accessed: 2026-08-26
    tier: 1
  - title: "SP 800-218, Secure Software Development Framework"
    url: "https://csrc.nist.gov/pubs/sp/800/218/final"
    publisher: "NIST"
    accessed: 2026-08-26
    tier: 1
  - title: "SP 800-128, Guide for Security-Focused Configuration Management"
    url: "https://csrc.nist.gov/pubs/sp/800/128/upd1/final"
    publisher: "NIST"
    accessed: 2026-08-26
    tier: 1
  - title: "pip secure installs documentation"
    url: "https://pip.pypa.io/en/stable/topics/secure-installs/"
    publisher: "PyPA"
    accessed: 2026-08-26
    tier: 1
symptoms:
  - symptom: "A scanner reports nothing and the storage was public"
    anchor: "the-category-with-no-identifier"
  - symptom: "A build succeeded and nobody can say what it fetched"
    anchor: "what-a-build-verifies-by-default"
---

> **Before you read.** A storage bucket held customer records and was readable by
> anybody for four days. No vulnerability was exploited, no credential was stolen,
> and no scanner reported anything.
>
> **What would have found it?**

Nothing that looks for vulnerabilities, because nothing was vulnerable. This is the
category that produces the most real-world exposure and has no identifier attached
to it, which changes how you have to look for it.

### Some words you will need

<dl class="terms">
<dt>misconfiguration</dt>
<dd>A system doing exactly what it was told, where what it was told is wrong.</dd>
<dt>insecure default</dt>
<dd>A shipped setting that is unsafe in most deployments.</dd>
<dt>transitive dependency</dt>
<dd>Something your dependency depends on. You did not choose it and you run it.</dd>
<dt>pinning</dt>
<dd>Stating an exact version rather than a range, so the resolution cannot change.</dd>
<dt>hash pinning</dt>
<dd>Stating the exact artefact, so even the same version number cannot be substituted.</dd>
<dt>service provider</dt>
<dd>Somebody operating something on your behalf. Their compromise reaches you through valid access.</dd>
<dt>hardware provider</dt>
<dd>Whoever made the machine, and everything on it below the operating system.</dd>
<dt>software provider</dt>
<dd>Anybody whose code ends up in yours, whether you have a contract with them or not.</dd>
</dl>

## What breaks without this

**A scan comes back clean and the data was public.** The scanner looked for known
flaws and there was none, because the exposure was a setting.

**A default is inherited and nobody records the decision.** Nobody chose it, so
nothing prompts anybody to revisit it, and it is invisible in every review.

**A build fetches whatever the registry currently offers.** The version resolved
today is not the one resolved last month, and no record says which either was.

**A dependency is compromised and the signature verifies.** The provider signed it,
which is what a signature attests, and the compromise was upstream of the signing.

## The category with no identifier

Every other class in this objective has a numbering scheme. A memory-safety bug
gets a CVE, appears in a database, is scored, and turns up in the vulnerability
report from block E.

**A misconfiguration gets none of that.** The software has no defect. It was
configured to permit something and it permitted it, correctly, and there is no
identifier because there is nothing to identify: the same setting is right on one
system and catastrophic on another.

Three consequences follow and all of them are practical.

**It is invisible to a vulnerability scanner.** Not missed, invisible: the scanner
compares versions against a database of defects, and this is not one.

**It has no severity to sort by.** Every prioritisation mechanism from block E,
CVSS, exploitation probability, the known exploited catalogue, operates on
identified vulnerabilities. A misconfiguration arrives without any of them.

**And it is found by a different activity.** Benchmarks and configuration
enforcement, which is topic 40's subject, or by somebody looking, which is the
audit. The vulnerability management programme is the wrong instrument entirely.

**The insecure default and the merely surprising one** are worth separating,
because they need different responses. An insecure default is unsafe in most
deployments and the vendor should change it, which is an argument to have with the
vendor. A surprising default is defensible in the vendor's intended case and wrong
in yours, which is nobody's fault and is yours to notice.

<details class="deeper">
<summary>If you are looking for these: where they concentrate, and the question that finds them</summary>

Misconfigurations are not evenly distributed, and knowing where they concentrate
makes the search finite.

They cluster wherever a setting has a permissive value that makes something work
and a restrictive value that requires understanding. Storage permissions, because
public makes the link work. Database bind addresses, because every interface makes
the connection succeed. Cross-origin rules, because permissive makes the browser
stop complaining. Firewall rules added during an incident. Debug and verbose modes
enabled to diagnose something. Every one of those has a value somebody set at a
moment when the priority was making it work.

They also cluster at boundaries between teams. A setting owned by nobody, in a
system two teams use, gets whatever the first team needed.

The question that finds them faster than reading configuration is inverted: rather
than asking whether each setting is correct, ask what would be reachable if this
component were fully accessible to somebody hostile, and then check whether it is.
That converts a large audit into a small number of specific tests, and the tests
are things like fetching a URL without credentials or connecting to a port from
outside the network.

The second useful question is about time. Not whether the configuration is right
now, but when it last changed and who changed it, because a setting that changed
during an incident three months ago and was never reverted is the classic shape.

And the structural answer, rather than the detective one, is the guard rail from
block E: a platform that refuses to create public storage removes the category
rather than helping you find instances of it.

</details>

## What one dependency brings

<details class="predict">
<summary>A build asks for one package by name. Predict how many packages arrive and how many licences come with them.</summary>

```bash
# AlmaLinux 10.2, x86_64
$ dnf -q -y install python3-pip >/dev/null 2>&1; echo "one package, asked for by name:"; echo "  requests"; echo; echo "what actually arrives:"; pip3 install --quiet --target /srv/deps requests 2>/dev/null; ls /srv/deps | grep -v dist-info | grep -v "^__" | tr "\n" " "; echo; echo; echo "packages installed, against packages requested:"; ls /srv/deps | grep -c dist-info; echo; echo "and the licences you have now agreed to, without reading any of them:"; grep -h -m1 "^License:" /srv/deps/*.dist-info/METADATA 2>/dev/null | sort -u | head -6
one package, asked for by name:
  requests

what actually arrives:
bin certifi charset_normalizer idna requests urllib3 

packages installed, against packages requested:
5

and the licences you have now agreed to, without reading any of them:
License: Apache-2.0
License: MIT
License: MPL-2.0
```

**Five packages for one request, under three different licences.**

Nobody chose four of those. They arrived because the package you asked for needs
them, and because those need others in turn, and the resolution happens at install
time rather than being something a person reviewed.

That is the practical meaning of a transitive dependency and it scales alarmingly.
Five is a small, well-behaved example from a mature library that takes its
dependency footprint seriously. A modern application framework routinely resolves
to hundreds, and every one of them is code that runs with your application's
authority, written by somebody you have no relationship with, updated on their
schedule.

The licences are a second finding people do not expect from a security topic, and
they belong here for the same reason: they are an obligation the organisation
acquired without anybody agreeing to it. Three different sets of terms arrived with
one install command.

The number worth knowing about your own application is not how many dependencies
you declared. It is how many resolve, which is a different and much larger number,
and it is the population your vulnerability scanning and your update process
actually have to cover.

</details>

## What a build verifies by default

The next question is what happens when one of those five changes.

```bash
# AlmaLinux 10.2, x86_64
$ dnf -q -y install python3-pip >/dev/null 2>&1; printf "requests\n" > /tmp/req.txt; echo "the requirements file a build is given:"; cat /tmp/req.txt; echo "what the default install says about it:"; pip3 install --quiet --dry-run --target /srv/d1 -r /tmp/req.txt 2>&1 | tail -2; echo "exit status: $?"; echo; printf "requests==2.32.3\n" > /tmp/req2.txt; echo "the same build, told to require a hash for every artefact:"; pip3 install --dry-run --require-hashes --target /srv/d2 -r /tmp/req2.txt 2>&1 | grep -i "hash" | head -3
the requirements file a build is given:
requests
what the default install says about it:
exit status: 0

the same build, told to require a hash for every artefact:
ERROR: Hashes are required in --require-hashes mode, but they are missing from some requirements. Here is a list of those requirements along with the hashes their downloaded archives actually had. Add lines like these to your requirements files to prevent tampering. (If you did not enable --require-hashes manually, note that it turns on automatically when any package has a hash.)
    requests==2.32.3 --hash=sha256:70761cfe03c773ceb22aa2f671b4757976145175cdfca038c02654d061d6dcc6
```

**Exit status zero, and nothing was checked against anything.** The requirements
file named a package with no version, the resolver chose whatever the registry
currently offers, and the install succeeded.

The second command shows what the same tool does when asked to verify. It refuses,
explains why, and prints the exact line to add, including the hash of the artefact
it actually downloaded. That is the mechanism working as intended and it is off
until somebody turns it on.

**Three levels are available and the difference between them matters.**

**No constraint** resolves fresh every time. The build is not reproducible, and a
new version published this morning is in production this afternoon.

**A pinned version** fixes which release is used, so the resolution is stable. It
does not fix which bytes: a registry serving a different artefact under the same
version number satisfies the pin.

**A pinned hash** fixes the artefact. Nothing can be substituted without the build
failing, which is the property the second command is offering.

<figure class="learn-figure">
<svg viewBox="0 0 720 300" role="img" aria-labelledby="sc-title" style="width:100%;height:auto;">
<title id="sc-title">Six stages between a dependency being published and running in production, with the stages where a substitution could have been caught and the ones not looking</title>
<g fill="currentColor">
<text x="14" y="20" font-size="11">one dependency update, six stages, and where it could have been caught</text>
<rect x="14" y="42" width="196" height="28" rx="4" fill="var(--red)" fill-opacity="0.08" stroke="var(--red)" stroke-opacity="0.65" stroke-width="1.2"/>
<text x="26" y="60" font-size="8.5">a maintainer publishes</text>
<text x="222" y="60" font-size="8" fill-opacity="0.65">the registry</text>
<text x="330" y="60" font-size="8" fill-opacity="0.85">nothing you run is involved</text>
<rect x="14" y="82" width="196" height="28" rx="4" fill="var(--accent)" fill-opacity="0.13" stroke="var(--accent)" stroke-opacity="0.65" stroke-width="1.2"/>
<text x="26" y="100" font-size="8.5">your build resolves it</text>
<text x="222" y="100" font-size="8" fill-opacity="0.65">the build server</text>
<text x="330" y="100" font-size="8" fill-opacity="0.85">a version range, resolved fresh</text>
<text x="330" y="111" font-size="7.5" fill="var(--accent)" fill-opacity="0.95">a pin would have caught a version change</text>
<rect x="14" y="122" width="196" height="28" rx="4" fill="var(--accent)" fill-opacity="0.13" stroke="var(--accent)" stroke-opacity="0.65" stroke-width="1.2"/>
<text x="26" y="140" font-size="8.5">the artefact is fetched</text>
<text x="222" y="140" font-size="8" fill-opacity="0.65">the build server</text>
<text x="330" y="140" font-size="8" fill-opacity="0.85">verified against a hash, if you asked</text>
<text x="330" y="151" font-size="7.5" fill="var(--accent)" fill-opacity="0.95">a hash would have caught a changed artefact</text>
<rect x="14" y="162" width="196" height="28" rx="4" fill="var(--accent)" fill-opacity="0.13" stroke="var(--accent)" stroke-opacity="0.65" stroke-width="1.2"/>
<text x="26" y="180" font-size="8.5">tests run</text>
<text x="222" y="180" font-size="8" fill-opacity="0.65">the pipeline</text>
<text x="330" y="180" font-size="8" fill-opacity="0.85">they test your code, not the dependency</text>
<text x="330" y="191" font-size="7.5" fill="var(--accent)" fill-opacity="0.95">only if the change breaks your tests</text>
<rect x="14" y="202" width="196" height="28" rx="4" fill="var(--red)" fill-opacity="0.08" stroke="var(--red)" stroke-opacity="0.65" stroke-width="1.2"/>
<text x="26" y="220" font-size="8.5">the image is built</text>
<text x="222" y="220" font-size="8" fill-opacity="0.65">the pipeline</text>
<text x="330" y="220" font-size="8" fill-opacity="0.85">and signed, which proves you built it</text>
<rect x="14" y="242" width="196" height="28" rx="4" fill="var(--accent)" fill-opacity="0.13" stroke="var(--accent)" stroke-opacity="0.65" stroke-width="1.2"/>
<text x="26" y="260" font-size="8.5">it deploys</text>
<text x="222" y="260" font-size="8" fill-opacity="0.65">production</text>
<text x="330" y="260" font-size="8" fill-opacity="0.85">and runs with your application s authority</text>
<text x="330" y="271" font-size="7.5" fill="var(--accent)" fill-opacity="0.95">runtime behaviour, if anything watches</text>
<text x="14" y="286" font-size="10" fill-opacity="0.85">two of the four catches are configuration you have to have turned on in advance</text>
</g></svg>
<figcaption>The path from a dependency being published to it running in production, with what each stage would notice. Two of the four stages that could catch a substitution only do so if somebody configured them in advance: a version pin and a hash pin are both opt-in, and the capture above shows the default succeeding without either. The tests are the stage people expect to catch things and they are testing your code, so a dependency that changes without breaking your behaviour passes them. The last stage catches nothing unless something is watching what the application does at runtime, which is the endpoint monitoring from block E arriving here as the final backstop.</figcaption>
</figure>

<details class="deeper">
<summary>If you own the pipeline: why pinning is resisted, and the arrangement that satisfies both sides</summary>

Pinning every dependency to an exact artefact is obviously correct and it is
resisted for a reason worth taking seriously rather than overriding.

The objection is maintenance. A pinned dependency does not receive security
updates, so somebody has to move the pin, and with several hundred resolved
dependencies that becomes continuous work. Teams that pinned everything and then
stopped updating have a reproducible build of known-vulnerable software, which is
worse than what they started with.

So the two failure modes are floating dependencies that change without anybody
knowing, and pinned ones that never change at all. Both are real and the second is
more common in organisations that took the advice without the second half.

The arrangement that satisfies both is automation plus a lock file. Declare ranges
in the manifest, so intent is expressed, and commit a lock file recording the exact
resolved artefacts and their hashes, so builds are reproducible and substitution
fails. Then run an automated updater that proposes lock file changes as ordinary
reviewed changes, with the tests running against them.

That converts the maintenance objection into a stream of small pull requests rather
than a periodic large effort, which is the form teams actually sustain. It also
produces the audit trail: every dependency change is a commit with a diff and a
reviewer, rather than a thing that happened at build time.

The detail that catches people: the lock file only helps if the build uses it. A
build that regenerates the lock from the manifest on every run has a lock file and
floating dependencies, which is the worst of both and is a common misconfiguration
in exactly the sense the first half of this topic describes.

</details>
<details class="predict">
<summary>A build pins every dependency to an exact version and the pins are never moved. Predict where the estate is after two years.</summary>

**Running a reproducible build of software with two years of known vulnerabilities
in it.**

That is the failure mode of taking the pinning advice without its second half, and
it is more common than floating dependencies in organisations that took security
guidance seriously at some point and then moved on.

The mechanism is that a pin does exactly what it says. It prevents the version
changing, which is the property you wanted, and it prevents it changing for good
reasons as well as bad. Every security release published for those components since
the pin was set is not in the build, and nothing about the build failing or
succeeding tells anybody.

What makes it worse than floating is the confidence. A team with floating
dependencies knows it does not know what it is running. A team with pins believes
it does, and the belief is correct about the version and wrong about the risk.

The arrangement that avoids both is ranges in the manifest, a committed lock file
recording the resolved artefacts and their hashes, and an automated updater raising
lock file changes as ordinary reviewed pull requests. That keeps reproducibility,
keeps substitution failing, and converts the maintenance from a periodic large
effort into a stream of small ones, which is the form teams actually sustain.

The check worth running on your own repository takes a minute: find the date the
lock file or the pins were last changed. If it is measured in years, this panel is
describing you.

</details>


## Three providers, three routes in

The objective splits the supply chain three ways and each becomes your problem
differently.

**A service provider operates something for you**, with access you granted. Their
compromise arrives through a legitimate channel with valid credentials, which is
the case from topic 13, and the only lever you control is what that access can
reach.

**A hardware provider supplies the machine** and everything below the operating
system: firmware, management controllers, and the microcode from topic 16. You
cannot inspect most of it, you frequently cannot inventory it, and the trust is
established at purchase rather than continuously.

**A software provider's code runs inside yours.** This is the largest category by
volume and the one the captures above are about, and it includes everybody whose
package resolved into your build without your having chosen them.

**How a software provider becomes an attacker without being compromised** is the
part worth stating plainly, because it is not intuitive. A maintainer can transfer
a package to somebody else. An abandoned package can be adopted by a new
maintainer with different intentions. A name close to a popular package can be
registered, and a typing mistake in a requirements file installs it. In none of
those is anybody compromised: the mechanisms worked, and the party at the other end
changed.

That is why the defences here are about the artefact rather than about the
publisher. A hash pin does not care who the maintainer is today.

<details class="deeper">
<summary>If you are asked for a software bill of materials: what it is for, and what it does not do</summary>

An inventory of what is inside your software has become a common contractual
requirement, and it is worth understanding what question it answers before treating
it as a control.

What it does is make a question answerable quickly. When a widely used component
turns out to have a serious vulnerability, the organisations that can say within an
hour which of their applications contain it are the ones with an inventory, and the
ones that cannot spend a week grepping repositories. That is the entire value and
it is substantial: the difference between a same-day response and a week-long one
is most of the exposure.

What it does not do is any of the following, and people expect all of them.

It does not tell you whether the components are vulnerable, which requires joining
it against a vulnerability feed, which is the package monitoring from block E.

It does not tell you whether they are reachable in your application. A vulnerable
function in a component you include and never call is a different exposure from one
on your request path, and an inventory cannot distinguish them.

And it does not establish that the inventory is complete. Generated at build time
from the resolver it is accurate about what the build fetched, and it says nothing
about anything vendored, copied, or compiled in by another route.

The practical advice for producing one: generate it in the build rather than
writing it, from the same resolution the build used, and keep the one that
corresponds to each released artefact. An inventory produced separately from the
build describes an intention rather than a release, and the whole point is to be
able to answer questions about what is actually running.

</details>

## Prove it

**Run it.** Install any package into an empty directory and count what arrives.
The ratio between what you asked for and what appeared is the interesting number.

**Work it out.** For your own main application, find how many dependencies resolve
against how many are declared. Then decide which of those two numbers your
vulnerability process actually covers.

**Look it up.** Open the secure installs documentation for whichever package
manager you use and find whether hash verification is on by default. It usually is
not, and the reason given is worth reading.

## What trips people up

### 1. Expecting a vulnerability scanner to find a misconfiguration

It compares versions against a database of defects. A correctly functioning system
configured to permit something is not in that database and never will be.

### 2. Treating every default as the vendor's fault

An insecure default is worth arguing about with the vendor. A surprising one is
defensible in their intended case and wrong in yours, and noticing it is your job.

### 3. Counting declared dependencies

One request produced five packages here. What your process has to cover is the
resolved set, which is larger and which nobody chose.

### 4. Reading a pinned version as a pinned artefact

A version pin fixes which release. A registry serving different bytes under the
same version satisfies it. Only a hash fixes the artefact.

### 5. Pinning everything and then not updating

That produces a reproducible build of known-vulnerable software. The sustainable
form is ranges plus a committed lock file plus an automated updater.

### 6. Assuming a supply chain compromise means somebody was hacked

A maintainer can hand a package over, an abandoned one can be adopted, and a
near-miss name can be registered. In none of those is anybody compromised, and a
hash pin defends against all three.

## Work it through

An application has four hundred resolved dependencies, no lock file, and a
requirements file listing twelve packages with no versions. A widely used component
is reported vulnerable and somebody asks whether you are affected.

**The tempting answer is to check the twelve.** They are the ones you declared, the
list is short, and none of them is the component in question. That answer is wrong
about the estate rather than about the twelve.

**The move that works produces the resolved set first.** Whatever the build
actually fetched most recently, listed with versions, which is a command rather
than an investigation. That answers today's question, and it will answer the next
one too.

**Then the durable fix is the lock file.** Commit what resolved, so the question
becomes a file lookup rather than a build, and so the answer describes what is
running rather than what would resolve if you built now.

**What this rejects is answering the question by hand.** It is answerable by hand
once, slowly, and the same question arrives every few weeks. The difference between
organisations that respond in an hour and in a week is entirely this file.

The residual worth naming: a lock file describes what the build fetched, and
anything vendored into the repository, copied from elsewhere, or bundled inside
another artefact is outside it. That gap is small in most projects and it is not
zero, and it is worth checking once rather than assuming.

## Try it

**Count the ratio.** Install one package into an empty target directory and count
the result. Do it for something from your own project and the ratio will be worse.

**Try requiring hashes.** Run your package manager's verification mode against your
current requirements. It will refuse, and what it prints is the work required to
fix it.

**Find one insecure default.** Take a service you run and find a setting whose
shipped value you would not have chosen. There is always one.

**Check whether your lock file is used.** Look at the build command. If it
regenerates the lock rather than installing from it, the lock is decoration.

## Check yourself

<details class="qa">
<summary>Why does misconfiguration have no CVE, and what follows?</summary>

Because there is no defect. The software did what it was configured to do, and the
same setting is correct on one system and catastrophic on another, so there is
nothing to identify.

Three things follow. It is invisible to a vulnerability scanner rather than missed
by one. It has no severity to sort by, so every prioritisation mechanism built on
identified vulnerabilities is inapplicable. And it is found by benchmarks,
configuration enforcement or somebody looking, which is a different activity from
vulnerability management.

</details>

<details class="qa">
<summary>One package is requested and five arrive. What does that mean for your process?</summary>

That the population your scanning and updating have to cover is the resolved set
rather than the declared one. Four of the five were chosen by somebody else's
dependency declarations, and every one runs with your application's authority.

Three different licences arrived with them too, which is an obligation acquired
without anybody agreeing to it, and it is discovered the same way.

</details>

<details class="qa">
<summary>What is the difference between pinning a version and pinning a hash?</summary>

A version pin fixes which release is installed, which makes resolution stable. It
does not fix which bytes: a registry serving a different artefact under the same
version number satisfies the pin.

A hash pin fixes the artefact, so any substitution fails the build. The capture on
this page shows the default install succeeding with neither, and the same tool
refusing and printing the exact hash line to add when asked to verify.

</details>

<details class="qa">
<summary>How can a software provider become an attacker without being compromised?</summary>

By changing. A maintainer can transfer a package to somebody else, an abandoned
package can be adopted by a new maintainer, and a name close to a popular one can
be registered so that a typing mistake installs it.

None of those involves anybody being hacked. The mechanisms worked as designed and
the party at the other end is different, which is why the defence is about the
artefact rather than about the publisher: a hash pin does not care who the
maintainer is today.

</details>

<details class="qa">
<summary>What does a software bill of materials give you, and what does it not?</summary>

It makes one question answerable quickly: which of our applications contain this
component. The difference between answering that in an hour and in a week is most
of the exposure during a widely publicised vulnerability.

It does not tell you whether the components are vulnerable, which needs a
vulnerability feed joined to it. It does not tell you whether the vulnerable code
is reachable in your application. And it is only as complete as the build that
generated it, so anything vendored or copied in by another route is absent.

</details>

## References

- [SP 800-161 Rev. 1](https://csrc.nist.gov/pubs/sp/800/161/r1/upd1/final) - NIST, supply chain risk management, for the provider categories and what each requires. Free. Accessed 2026-08-26.
- [SP 800-218](https://csrc.nist.gov/pubs/sp/800/218/final) - NIST, secure software development, for where in a build each check belongs. Free. Accessed 2026-08-26.
- [SP 800-128](https://csrc.nist.gov/pubs/sp/800/128/upd1/final) - NIST, configuration management, for the enforcement side of the misconfiguration problem. Free. Accessed 2026-08-26.
- [pip secure installs](https://pip.pypa.io/en/stable/topics/secure-installs/) - PyPA, the documentation for the verification mode the second capture invokes. Free. Accessed 2026-08-26.

**Where the content came from.** Both blocks are captured from an AlmaLinux 10.2
container fetching from a public package registry, which is an ordinary install and
not a probe of anything. The dependency count and the licences are whatever that
package resolved to at capture time, and the hash in the second block is the one
the tool computed for the artefact it downloaded. Nothing here substitutes,
tampers with or publishes any package. There is no platform comparison on this
page, because dependency resolution is a property of a package manager rather than
of an operating system.

**If you also work on Linux.** The Linux+ track's
[packages, repositories and signing](/learn/linux-plus/packages-repositories-and-signing)
covers the distribution-level version of the same question, where the signing and
the pinning are handled differently.
