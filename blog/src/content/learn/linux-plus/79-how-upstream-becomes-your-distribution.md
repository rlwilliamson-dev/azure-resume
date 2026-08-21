---
title: "How upstream becomes your distribution"
description: "A scanner says your glibc is years out of date and your vendor says you are patched. Both are reading the same version number and only one of them is reading the changelog. What a release field carries, why distributions work this way, and what it does to vulnerability management."
deck: "The scanner says vulnerable and the vendor says fixed"
track: "linux-plus"
level: "working"
order: 800
beyondExam: true
objectives:
  - "Read a package version and say which part is upstream's and which is the distribution's"
  - "Explain backporting and why a vendor chooses it over rebasing"
  - "Say why a version-based vulnerability scan produces false positives"
  - "Name the machine-readable sources that answer the question properly"
  - "Tell a rolling release, a point release and a long-term support release apart"
prerequisites: ["packages-repositories-and-signing", "compliance-auditing-and-integrity"]
tags: ["linux", "linux-plus", "packaging", "security", "beyond-the-exam"]
updated: 2026-08-21
draft: false
examObjectives: []
sources:
  - title: "Backporting Security Fixes"
    url: "https://access.redhat.com/security/updates/backporting"
    publisher: "Red Hat"
    accessed: 2026-08-21
    tier: 1
  - title: "Debian Security FAQ"
    url: "https://www.debian.org/security/faq"
    publisher: "Debian"
    accessed: 2026-08-21
    tier: 1
  - title: "Ubuntu CVE reports"
    url: "https://ubuntu.com/security/cves"
    publisher: "Canonical"
    accessed: 2026-08-21
    tier: 1
symptoms:
  - symptom: "A vulnerability scan reports a CVE the vendor says is already fixed"
    anchor: "the-version-number-is-upstreams-and-the-rest-is-not"
  - symptom: "A package version looks years behind the current upstream release"
    anchor: "why-they-do-it-this-way"
---

> **Before you read.** A scanner reports the glibc on your server as version
> 2.39, and lists three vulnerabilities against it. Your vendor's advisory page
> says all three are fixed and have been for months. The scanner is reading the
> version correctly.
>
> **Which of them is right, and what would settle it?**

Objective 3.6 names backporting in a list and moves on, which is the whole of
what the exam has to say about the single largest source of argument between
security teams and the people who run the servers. This page is that argument,
settled with evidence, and it is not examinable.

### Some words you will need

<dl class="terms">
<dt>upstream</dt>
<dd>The project that writes the software. Its version numbers are the ones people quote.</dd>
<dt>downstream</dt>
<dd>The distribution that packages it, and everybody after that.</dd>
<dt>backport</dt>
<dd>Taking a fix from a newer version and applying it to an older one, without the rest of the newer version.</dd>
<dt>rebase</dt>
<dd>The alternative: replacing the old version with the new one entirely.</dd>
<dt>release field</dt>
<dd>The part of a package version after the upstream number, which counts the distribution's own work.</dd>
<dt>ABI</dt>
<dd>The binary contract between a library and everything compiled against it. Breaking it breaks other people's programs.</dd>
</dl>

## What breaks without this

**Time is spent on false positives.** A scanner that compares version strings
reports vulnerabilities that were fixed months ago, and somebody has to disprove
each one.

**Or worse, on real ones nobody believes.** A team that has learned to dismiss
scanner output as noise will dismiss the finding that mattered.

**An upgrade gets forced for no benefit.** "We must be on the latest version"
turns into a project, and the current version already contains the fix that
prompted it.

## The version number is upstream's, and the rest is not

<details class="predict">
<summary>A distribution shipping glibc 2.39, which upstream released early in 2024. What does its changelog say about vulnerabilities published in 2026?</summary>

```bash
# AlmaLinux 10.2, x86_64
$ rpm -q glibc --qf "installed: %{VERSION}-%{RELEASE}\n"; echo "--- and what that release number is carrying ---"; rpm -q --changelog glibc | grep -iE "^\*|CVE-" | head -10
installed: 2.39-124.el10_2.alma.1
--- and what that release number is carrying ---
* Tue May 26 2026 Eduard Abdullin <eabdullin@almalinux.org> - 2.39-124.alma.1
* Mon May 11 2026 Frédéric Bérat <fberat@redhat.com> - 2.39-124
* Sat May 09 2026 Frédéric Bérat <fberat@redhat.com> - 2.39-123
- CVE-2026-4046: Fix assertion failure in IBM1390 and IBM1399 iconv modules
* Tue May 05 2026 Frédéric Bérat <fberat@redhat.com> - 2.39-122
* Tue Apr 07 2026 Frédéric Bérat <fberat@redhat.com> - 2.39-121
* Wed Apr 01 2026 Florian Weimer <fweimer@redhat.com> - 2.39-120
- resolv: Check hostname for validity (CVE-2026-4438)
- resolv: Count records correctly (CVE-2026-4437)
* Mon Mar 30 2026 Frédéric Bérat <fberat@redhat.com> - 2.39-119
```

</details>

**Version 2.39, carrying fixes from 2026.** The upstream project has moved on
several releases since 2.39 and this package has not, and it nonetheless contains
the patch for three flaws that did not exist when 2.39 was published.

The whole story is in the string `2.39-124.el10_2.alma.1`. The `2.39` is
upstream's and it has not changed in two years. Everything after the hyphen is the
distribution counting its own work: this is the hundred and twenty fourth package
build of that upstream version, built for the 10.2 release, with a rebuild by
AlmaLinux on the end. When the vendor fixes something, the number after the hyphen
goes up and the number before it does not.

That is why comparing version numbers between a distribution package and an
upstream release answers a question nobody asked.

<details class="predict">
<summary>A different distribution, a different upstream version of the same library. Which of those three flaws does it carry a fix for?</summary>

```bash
# Debian 13 (trixie), x86_64
$ dpkg-query -W -f="installed: \${Version}\n" libc6; echo "--- the same three flaws, a different upstream version ---"; zcat /usr/share/doc/libc6/changelog.Debian.gz | grep -iE "^glibc \(|CVE-2026-4(437|438|046)" | head -8
installed: 2.41-12+deb13u3
--- the same three flaws, a different upstream version ---
glibc (2.41-12+deb13u3) trixie; urgency=medium
      gethostbyaddr_r (CVE-2026-4437).  Closes: #1131435.
      gethostbyaddr_r (CVE-2026-4438).  Closes: #1131887.
      inputs from the IBM139x character sets (CVE-2026-4046).  Closes:
glibc (2.41-12+deb13u2) trixie; urgency=medium
glibc (2.41-12+deb13u1) trixie; urgency=medium
glibc (2.41-12) unstable; urgency=medium
glibc (2.41-11) unstable; urgency=medium
```

</details>

The same three, on 2.41 rather than 2.39, with the distribution's work counted in
`+deb13u3` instead. Two vendors, two upstream versions, one set of fixes, and
neither version number is the one upstream would call fixed.

<details class="deeper">
<summary>If you maintain packages: how a two-line patch gets into a release that is otherwise frozen</summary>

The mechanism is deliberately boring, which is the point. A stable release is
frozen against change because change is what breaks things, so the process for a
security fix is built to be the smallest possible exception rather than a fast
path for arbitrary work.

The maintainer takes the upstream commit that fixes the flaw, and only that
commit. It gets rewritten as a patch against the older source, which is the
skilled part: the surrounding code has moved on, so the fix rarely applies
cleanly, and reproducing its effect without importing anything else takes
somebody who understands both versions. The patch is added to the package sources
as a file with a name and a comment saying which CVE it addresses, the release
field is incremented, and the package is rebuilt.

Nothing else in the package changes. No new features, no other bug fixes, no
dependency bumps, no ABI change. Debian's own guidance for this states the aim
plainly, which is to make as few changes as possible, and the reason is that the
update is going to be installed automatically on machines nobody is watching.

Two consequences follow that people find surprising. The fix in the distribution
can differ from the fix upstream, because upstream may have fixed it as part of a
refactor that cannot be backported. And a distribution's package can contain
fixes upstream does not have yet, when the maintainer is the person who found the
flaw.

</details>

## Why they do it this way

The obvious alternative is to ship the new upstream version, and the reason
distributions do not is compatibility rather than conservatism.

A stable release makes a promise: software that works on it at the start still
works at the end. Every binary compiled against a library depends on that
library's ABI, and a new upstream version can change one. Replacing glibc 2.39
with 2.42 across an installed base means every program linked against it is now
running against something it was not built for, and finding out which of them
mind is a large exercise that nobody asked for. Red Hat's own explanation of the
practice uses precisely this argument: backporting is what lets a vendor push
security updates automatically, at low risk, to machines whose owners are not
testing anything.

The cost is the confusion this page exists to resolve, and the vendors know it.
Red Hat's page on backporting says in as many words that reading a package's
version number will not tell you whether you are vulnerable.

## What it does to vulnerability scanning

A scanner that works by comparing version strings against a database of "fixed
in" versions is structurally unable to get this right. The installed version is
genuinely older than the version upstream fixed it in, so the comparison is
correct and the conclusion is wrong.

There are three ways out and only the last one scales.

**Read the changelog**, which is what the captures above do. It settles one
package definitively and it does not scale to a fleet.

**Check the vendor's tracker.** Every major distribution publishes per-CVE status:
Red Hat's advisories, Debian's security tracker, Ubuntu's CVE pages. This is the
authoritative answer and it is a web page per question.

**Feed the scanner the vendor's own data.** The vendors publish machine-readable
security data precisely for this, OVAL definitions and their successors, which
state which package version in which release fixes which CVE. A scanner
configured with that source stops comparing upstream version numbers and starts
comparing the thing that actually decides the answer.

If you take one operational action from this page, it is the third: find out
which of the two your scanner is doing, because a scanner running in the first
mode will generate work forever and a scanner in the second will not.

<details class="deeper">
<summary>If you are the one being asked to prove it: what to send back, and what not to argue</summary>

The exchange usually goes badly in the same way. The security team sends a list,
the systems team replies that those are backported and therefore false positives,
and the security team hears a technical excuse for not patching. Both are acting
reasonably and neither has produced evidence.

What settles it is a link and a command. The link is the vendor's own page for
that CVE against that release, which is a third party stating the position rather
than you asserting it. The command is the changelog grep from this page, which
shows the fix in the installed package on the actual machine. Those two together
are checkable by somebody who does not trust you, which is the property that
matters.

What not to do is argue the principle. "Backporting exists" is true and answers
nothing about this CVE on this host, and a security team that has been told it
before has usually also met a case where it was said about something genuinely
unpatched.

And be careful about the direction of the mistake. Backporting produces false
positives, and a machine that has not taken updates produces a true positive that
looks exactly the same from the outside. The first question to ask yourself,
before replying, is when that package was last updated, because if the answer is
eighteen months then the scanner is right and the explanation you were about to
give is the wrong one.

</details>

## Rolling, point, and long-term support

Backporting is one point in a design space, and the models around it explain why
different systems feel so different to operate.

| Model | What changes, and when | What it costs |
| --- | --- | --- |
| Rolling | Everything, continuously, at upstream's pace | Never far behind, and never twice the same |
| Point release | Bug and security fixes within a series, features at the next series | Predictable, and behind on features |
| Long-term support | Security fixes only, for years, with the version frozen | Stable for a decade, and every version number looks alarming |

The confusion at the top of this page is a long-term support system working
exactly as designed. A machine running a five year old release with a version
number to match, and with a changelog full of last month's fixes, is not
neglected. It is the product being what it was sold as.

The corollary is worth stating because people get it backwards. On a
long-term-support system the version number is a poor signal of security and the
update timestamp is a good one. A package that has not been updated in a year on
a supported release is either genuinely unaffected by anything or is not
receiving updates, and finding out which is a better use of an afternoon than
comparing anything to upstream.

<details class="deeper">
<summary>If you choose distributions: what the support window is actually promising</summary>

A support window is a commitment to backport, and its edges are where the
surprises live.

The first edge is what is covered. A distribution supports the packages in its
own repositories, and the language stacks are the gap: a Python package installed
with `pip`, a Node module, a Ruby gem, or a container image built from something
else is outside the promise entirely, and the machine's own package manager will
report a clean bill of health for a host whose actual risk lives in a
`requirements.txt`. Objective 3.6's software supply chain bullet is pointing at
this and the exam does not have room to say so.

The second edge is the tail. Long support windows are usually tiered: full
support first, then a phase where only serious security issues are addressed,
then nothing. The middle phase is the one people miss, because updates keep
arriving and the criteria for what gets fixed have quietly narrowed.

The third is what happens at the end. An unsupported release does not stop
working, it stops receiving backports, and the machine that was defensible last
month becomes indefensible without anything about it changing. That date is
knowable years in advance and is the single most useful thing to have in a
calendar for an estate of any size.

</details>

## Prove it

**Read the changelog of a package on a machine you run.** `rpm -q --changelog`
on the RHEL family, or `zcat /usr/share/doc/<package>/changelog.Debian.gz` on the
Debian side. Find a CVE identifier newer than the upstream version and the whole
argument becomes concrete.

**Take the version string apart.** Whatever your system says for glibc, separate
the upstream part from the distribution's part and say what each number counts.
Doing that once makes every future scanner report readable.

**Find out which data your scanner uses.** One question to whoever runs it: does
it compare version strings, or does it consume the vendors' security data? The
answer predicts how much of your time it will consume for the rest of its life.

## What trips people up

### 1. Comparing a distribution version to an upstream release

They are different numbering schemes measuring different things. The comparison
is meaningless in both directions and produces confident wrong answers.

### 2. Reading a low upstream version as neglect

On a long-term support release, an unchanging upstream version is the product
working. The release field is where the activity is.

### 3. Believing the scanner without the vendor's data

A version-comparison scanner will report fixed vulnerabilities as open
indefinitely. This is not a bug in it; it is the limit of what a version string
can answer.

### 4. Dismissing the scanner because of backporting

The same output shape is produced by a machine that simply has not been updated.
Check the package's update date before reaching for the explanation.

### 5. Assuming the distribution's fix is upstream's fix

Sometimes it cannot be, because upstream fixed it inside a change too large to
backport. The effect is the same and the code is not, which matters when you go
looking for the patch.

### 6. Thinking the support window covers everything installed

It covers what the distribution ships. Anything installed by a language package
manager, or baked into a container image, is somebody else's promise or nobody's.

## Work it through

A quarterly scan returns four hundred findings across sixty servers. The security
team wants a remediation plan. The systems team says most of it is backporting
noise. The meeting is on Thursday.

Do not start with the four hundred. Start with two questions that change the
shape of the whole list: what data source is the scanner using, and when did each
of those sixty machines last apply updates. The first tells you whether the list
is trustworthy at all, and the second splits the estate into machines that are
patched and machines that are not, which is the only division that matters.

If the scanner is comparing version strings, the fix is to point it at the
vendors' security data, and that single change will remove most of the four
hundred without anybody examining a package. That is a better use of Thursday
than triage, and it is a permanent fix rather than one quarter's work.

Whatever remains after that deserves the changelog treatment, and the answer will
not be uniform. Expect three groups: genuinely fixed and misreported, genuinely
unfixed on machines that stopped taking updates, and packages installed outside
the distribution's repositories where the support window never applied. The third
group is usually the smallest and the most urgent, because nothing is watching it
at all.

And bring the evidence rather than the principle. A vendor page per finding and a
changelog line from the host is checkable. An explanation of how backporting works
is a lecture, and the security team has heard it.

## Try it

**Grep your own package changelogs for CVE identifiers.** One command, and it
turns an abstract argument into something you have seen.

**Look up one CVE on your distribution's tracker.** Find the page that states its
status for your release. Bookmark it, because you will use it again.

**Find the end of support date for the release you run most.** Put it in a
calendar. It is the one date on this page that will eventually surprise somebody.

## Check yourself

<details class="qa">
<summary>In glibc-2.39-124.el10_2, which part moves when a security fix is applied?</summary>

The release field after the hyphen. The `2.39` is upstream's version and stays
where it is for the life of the distribution release; the `124` counts the
distribution's own package builds and goes up each time it fixes something.

</details>

<details class="qa">
<summary>Why does a distribution backport rather than shipping the new upstream version?</summary>

Because a stable release promises that software working at the start still works
at the end, and a new upstream version can change the binary interface everything
compiled against it depends on. Backporting is what makes an automatic update
low risk enough to push to machines nobody is testing.

</details>

<details class="qa">
<summary>Your scanner reports a CVE your vendor says is fixed. What settles it?</summary>

The vendor's own page for that CVE against that release, plus the installed
package's changelog on the host itself. Both are checkable by somebody who does
not take your word for it, which an explanation of backporting is not.

</details>

<details class="qa">
<summary>Backporting explains a false positive. What produces output that looks identical and is not a false positive?</summary>

A machine that has not applied updates. From outside, an old version with the fix
and an old version without it look the same, so the first thing to check is when
that package was last updated rather than reaching for the explanation.

</details>

<details class="qa">
<summary>What does a support window not cover?</summary>

Anything the distribution did not ship. Packages installed with pip, npm, cargo
or their equivalents, and software baked into container images, are outside it,
and the host's package manager will report nothing about them.

</details>

## References

- [Backporting Security Fixes](https://access.redhat.com/security/updates/backporting) - Red Hat, the definition, the compatibility argument, and the statement that a version number will not tell you whether you are vulnerable. Free. Accessed 2026-08-21.
- [Debian Security FAQ](https://www.debian.org/security/faq) - Debian, on backporting into stable and on making as few changes as possible. Free. Accessed 2026-08-21.
- [Ubuntu CVE reports](https://ubuntu.com/security/cves) - Canonical, an example of the per-CVE, per-release status page this topic recommends checking. Free. Accessed 2026-08-21.

**Where the output came from.** Two captured blocks through `capture.sh` on the
images named in each header, pinned by digest in `blog/scripts/distros.json`. The
package versions and the CVE identifiers are whatever those images actually
carried on the day, which is the point: nothing here was chosen to make the
argument and the same commands on your own machines will produce your own
version of it.

**Why this is not in the lesson count.** Objective 3.6 names backporting in a
list of things to know about vulnerability scanning and asks nothing further.
Everything on this page follows from that one word and none of it is examinable.
