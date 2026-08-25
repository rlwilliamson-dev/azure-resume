---
title: "Application security"
description: "Where each application security control runs in a pipeline, the defect class each one cannot see, why validation belongs on the server, what a code signature actually proves, and the two lines a static analyser walked straight past."
deck: "The form rejects a name with an apostrophe. It accepts one with a semicolon"
track: "security-plus"
level: "working"
order: 440
objectives:
  - "Place each application security control at the point in a pipeline where it runs"
  - "Name the defect class each control is blind to"
  - "Say why input validation belongs on the server and what client-side validation is for"
  - "Read a static analysis report and account for what it did not flag"
  - "Say what a code signature proves and what it does not"
  - "Verify a signature on Linux, Windows and macOS and explain why the three answers differ"
prerequisites: ["secure-baselines"]
tags: ["security-plus", "security", "operations", "application-security"]
updated: 2026-08-25
draft: false
examObjectives:
  - exam: "sy0-701"
    domain: "4.0"
    objective: "4.1"
sources:
  - title: "SP 800-218, Secure Software Development Framework (SSDF)"
    url: "https://csrc.nist.gov/pubs/sp/800/218/final"
    publisher: "NIST"
    accessed: 2026-08-25
    tier: 1
  - title: "RFC 6265, HTTP State Management Mechanism"
    url: "https://www.rfc-editor.org/rfc/rfc6265.html"
    publisher: "IETF"
    accessed: 2026-08-25
    tier: 1
  - title: "CWE-89, Improper Neutralization of Special Elements used in an SQL Command"
    url: "https://cwe.mitre.org/data/definitions/89.html"
    publisher: "MITRE"
    accessed: 2026-08-25
    tier: 1
  - title: "CWE-78, Improper Neutralization of Special Elements used in an OS Command"
    url: "https://cwe.mitre.org/data/definitions/78.html"
    publisher: "MITRE"
    accessed: 2026-08-25
    tier: 1
  - title: "Get-AuthenticodeSignature reference"
    url: "https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.security/get-authenticodesignature"
    publisher: "Microsoft"
    accessed: 2026-08-25
    tier: 1
  - title: "About Code Signing"
    url: "https://developer.apple.com/library/archive/documentation/Security/Conceptual/CodeSigningGuide/Introduction/Introduction.html"
    publisher: "Apple"
    accessed: 2026-08-25
    tier: 1
symptoms:
  - symptom: "A scanner reports a clean file that contains an obvious logic flaw"
    anchor: "what-the-analyser-found-and-what-it-walked-past"
  - symptom: "A signed binary is still malicious"
    anchor: "what-a-signature-proves"
---

> **Before you read.** A registration form rejects the name O'Brien, because
> somebody heard that apostrophes are dangerous. The same form accepts a name
> containing a semicolon, a backtick and the word `DROP` without comment.
>
> **Which of those two behaviours is the security problem?**

Both are, and they are the same problem seen from two sides. Rejecting the
apostrophe is filtering characters that looked scary. Accepting the rest is what
happens when nobody asked what the field is actually for.

### Some words you will need

<dl class="terms">
<dt>input validation</dt>
<dd>Checking that data is what the program expects before using it. On the server, always.</dd>
<dt>static analysis</dt>
<dd>Reading the code without running it. Fast, early, and blind to anything that depends on behaviour.</dd>
<dt>dynamic analysis</dt>
<dd>Running the program and watching what it does. Sees real behaviour, and only the behaviour it exercised.</dd>
<dt>package monitoring</dt>
<dd>Watching the dependencies for known vulnerabilities and for versions that have moved.</dd>
<dt>code signing</dt>
<dd>A cryptographic assertion about who produced a piece of code and that it has not changed since.</dd>
<dt>sandboxing</dt>
<dd>Running code with less authority than the user who started it, so a compromise is worth less.</dd>
<dt>secure cookie</dt>
<dd>A cookie carrying flags that limit where it goes and who can read it. Chiefly Secure, HttpOnly and SameSite.</dd>
</dl>

## What breaks without this

**A control is bought and it is the wrong one for the defect.** Static analysis
finds nothing wrong with a working authorisation bug, and everybody concludes the
code is fine because the report is empty.

**Validation happens where an attacker controls it.** The check runs in the
browser, the attacker is not using a browser, and the field arrives at the server
unexamined.

**A signature is read as a safety claim.** Signed code is trusted because it is
signed, and the signature says who built it rather than whether it should be run.

**Everything is checked once, at the end.** The controls that are cheap early get
run late, where fixing what they find is expensive, so they get skipped.

## Every control runs somewhere, and misses something specific

The objective names half a dozen controls in one list, which makes them look
interchangeable. They are not: each one runs at a different point and is blind to
a different class of defect.

<figure class="learn-figure">
<svg viewBox="0 0 720 300" role="img" aria-labelledby="pipe-title" style="width:100%;height:auto;">
<title id="pipe-title">Five points in a delivery pipeline with the control that runs at each one and the defect class that control cannot see</title>
<g fill="currentColor">
<text x="14" y="20" font-size="11">each control runs somewhere, and each one is blind to something specific</text>
<path d="M 20 52 H 700" stroke="currentColor" stroke-opacity="0.4" stroke-width="1.2"/>
<path d="M 80 46 V 58" stroke="currentColor" stroke-opacity="0.5" stroke-width="1.2"/>
<text x="80" y="40" text-anchor="middle" font-size="9" fill-opacity="0.75">written</text>
<path d="M 220 46 V 58" stroke="currentColor" stroke-opacity="0.5" stroke-width="1.2"/>
<text x="220" y="40" text-anchor="middle" font-size="9" fill-opacity="0.75">built</text>
<path d="M 360 46 V 58" stroke="currentColor" stroke-opacity="0.5" stroke-width="1.2"/>
<text x="360" y="40" text-anchor="middle" font-size="9" fill-opacity="0.75">signed</text>
<path d="M 500 46 V 58" stroke="currentColor" stroke-opacity="0.5" stroke-width="1.2"/>
<text x="500" y="40" text-anchor="middle" font-size="9" fill-opacity="0.75">deployed</text>
<path d="M 640 46 V 58" stroke="currentColor" stroke-opacity="0.5" stroke-width="1.2"/>
<text x="640" y="40" text-anchor="middle" font-size="9" fill-opacity="0.75">running</text>
<rect x="20" y="72" width="120" height="38" rx="4" fill="var(--accent)" fill-opacity="0.12" stroke="var(--accent)" stroke-width="1.5"/>
<text x="80" y="89" text-anchor="middle" font-size="8.5">static</text>
<text x="80" y="102" text-anchor="middle" font-size="8.5">analysis</text>
<rect x="160" y="72" width="120" height="38" rx="4" fill="var(--accent)" fill-opacity="0.12" stroke="var(--accent)" stroke-width="1.5"/>
<text x="220" y="89" text-anchor="middle" font-size="8.5">package</text>
<text x="220" y="102" text-anchor="middle" font-size="8.5">monitoring</text>
<rect x="300" y="72" width="120" height="38" rx="4" fill="var(--accent)" fill-opacity="0.12" stroke="var(--accent)" stroke-width="1.5"/>
<text x="360" y="89" text-anchor="middle" font-size="8.5">code</text>
<text x="360" y="102" text-anchor="middle" font-size="8.5">signing</text>
<rect x="440" y="72" width="120" height="38" rx="4" fill="var(--accent)" fill-opacity="0.12" stroke="var(--accent)" stroke-width="1.5"/>
<text x="500" y="89" text-anchor="middle" font-size="8.5">dynamic</text>
<text x="500" y="102" text-anchor="middle" font-size="8.5">analysis</text>
<rect x="580" y="72" width="120" height="38" rx="4" fill="var(--accent)" fill-opacity="0.12" stroke="var(--accent)" stroke-width="1.5"/>
<text x="640" y="89" text-anchor="middle" font-size="8.5">sandboxing</text>
<text x="640" y="102" text-anchor="middle" font-size="8.5">and monitoring</text>
<text x="14" y="140" font-size="9.5" fill="var(--red)" fill-opacity="0.9">cannot see</text>
<path d="M 80 112 V 152" stroke="var(--red)" stroke-opacity="0.4" stroke-width="1" stroke-dasharray="3 3"/>
<rect x="20" y="156" width="120" height="38" rx="4" fill="var(--red)" fill-opacity="0.08" stroke="var(--red)" stroke-opacity="0.5" stroke-width="1.2" stroke-dasharray="4 3"/>
<text x="80" y="173" text-anchor="middle" font-size="8" fill-opacity="0.9">logic that is</text>
<text x="80" y="186" text-anchor="middle" font-size="8" fill-opacity="0.9">syntactically fine</text>
<path d="M 220 112 V 152" stroke="var(--red)" stroke-opacity="0.4" stroke-width="1" stroke-dasharray="3 3"/>
<rect x="160" y="156" width="120" height="38" rx="4" fill="var(--red)" fill-opacity="0.08" stroke="var(--red)" stroke-opacity="0.5" stroke-width="1.2" stroke-dasharray="4 3"/>
<text x="220" y="173" text-anchor="middle" font-size="8" fill-opacity="0.9">a package that is</text>
<text x="220" y="186" text-anchor="middle" font-size="8" fill-opacity="0.9">current and wrong</text>
<path d="M 360 112 V 152" stroke="var(--red)" stroke-opacity="0.4" stroke-width="1" stroke-dasharray="3 3"/>
<rect x="300" y="156" width="120" height="38" rx="4" fill="var(--red)" fill-opacity="0.08" stroke="var(--red)" stroke-opacity="0.5" stroke-width="1.2" stroke-dasharray="4 3"/>
<text x="360" y="173" text-anchor="middle" font-size="8" fill-opacity="0.9">whether the code</text>
<text x="360" y="186" text-anchor="middle" font-size="8" fill-opacity="0.9">is any good</text>
<path d="M 500 112 V 152" stroke="var(--red)" stroke-opacity="0.4" stroke-width="1" stroke-dasharray="3 3"/>
<rect x="440" y="156" width="120" height="38" rx="4" fill="var(--red)" fill-opacity="0.08" stroke="var(--red)" stroke-opacity="0.5" stroke-width="1.2" stroke-dasharray="4 3"/>
<text x="500" y="173" text-anchor="middle" font-size="8" fill-opacity="0.9">the path it</text>
<text x="500" y="186" text-anchor="middle" font-size="8" fill-opacity="0.9">never exercised</text>
<path d="M 640 112 V 152" stroke="var(--red)" stroke-opacity="0.4" stroke-width="1" stroke-dasharray="3 3"/>
<rect x="580" y="156" width="120" height="38" rx="4" fill="var(--red)" fill-opacity="0.08" stroke="var(--red)" stroke-opacity="0.5" stroke-width="1.2" stroke-dasharray="4 3"/>
<text x="640" y="173" text-anchor="middle" font-size="8" fill-opacity="0.9">what the app is</text>
<text x="640" y="186" text-anchor="middle" font-size="8" fill-opacity="0.9">allowed to do</text>
<rect x="20" y="212" width="680" height="34" rx="4" fill="currentColor" fill-opacity="0.06" stroke="currentColor" stroke-opacity="0.6" stroke-width="1.4"/>
<text x="360" y="233" text-anchor="middle" font-size="9">input validation, which is not a stage but a property of the code, and covers most of what the row above misses</text>
<text x="14" y="272" font-size="10" fill-opacity="0.85">no control on the top row inspects whether the program decides the right thing</text>
<text x="14" y="292" font-size="10" fill-opacity="0.85">which is why the analyser found four defects on this page and walked past two others</text>
</g></svg>
<figcaption>The row of blue boxes is the usual list, placed where each one actually runs. The dashed row underneath is the part that never appears in a product comparison: what that control is structurally unable to notice. Static analysis reads code and cannot tell whether an expression that parses correctly decides the right thing. Package monitoring compares versions against a database and says nothing about a dependency that is current and unsuitable. Signing asserts origin and integrity and makes no claim about quality. Dynamic analysis reports on the paths it took. Sandboxing constrains authority, which means anything the application is legitimately allowed to do stays available to whoever takes it over. The band across the bottom is input validation, which is a property of the code rather than a stage in the pipeline, and it covers a large share of what the top row cannot reach.</figcaption>
</figure>

<details class="deeper">
<summary>If you own a pipeline: why the ordering above is about cost rather than about coverage</summary>

The reason these controls sit at different points is not that each one can only
work there. Most of them could run later. It is that the cost of acting on a
finding rises steeply as the code moves right along that line.

A static analysis finding at commit time is a developer changing a line they wrote
an hour ago, in a branch nobody else has. The same defect found in production is
an incident, a patch, a release, a change approval, and a conversation about how it
got there. Same defect, two or three orders of magnitude difference in what it
costs to remove.

That is the whole argument for moving checks earlier, and it is worth separating
from the marketing version of it. Nothing about running a scanner early makes the
scanner better. What changes is the price of what it finds, and the willingness of
a team to act on a finding is largely a function of that price.

The corollary is the useful part. A control that produces findings nobody acts on
has been placed too late, and the fix is usually to move it rather than to tune
it. SP 800-218 organises its practices roughly this way, around when in the
lifecycle a practice belongs, and reading it as a sequence rather than a checklist
is what makes it useful.

</details>

## What the analyser found, and what it walked past

Here is a small program with several defects in it, and a static analyser given
the file.

```bash
# AlmaLinux 10.2, x86_64
$ bandit -q -r /srv/app/handler.py 2>/dev/null | head -40
Run started:2026-08-25 20:40:20.781070+00:00

Test results:
>> Issue: [B404:blacklist] Consider possible security implications associated with the subprocess module.
   Severity: Low   Confidence: High
   CWE: CWE-78 (https://cwe.mitre.org/data/definitions/78.html)
   Location: /srv/app/handler.py:4:0
3	import sqlite3
4	import subprocess
5	

--------------------------------------------------
>> Issue: [B324:hashlib] Use of weak MD5 hash for security. Consider usedforsecurity=False
   Severity: High   Confidence: High
   CWE: CWE-327 (https://cwe.mitre.org/data/definitions/327.html)
   Location: /srv/app/handler.py:8:13
7	def store_password(username, password):
8	    digest = hashlib.md5(password.encode()).hexdigest()
9	    return (username, digest)

--------------------------------------------------
>> Issue: [B608:hardcoded_sql_expressions] Possible SQL injection vector through string-based query construction.
   Severity: Medium   Confidence: Medium
   CWE: CWE-89 (https://cwe.mitre.org/data/definitions/89.html)
   Location: /srv/app/handler.py:14:16
13	    cur = conn.cursor()
14	    cur.execute("SELECT * FROM users WHERE name = '%s'" % name)
15	    return cur.fetchall()

--------------------------------------------------
>> Issue: [B602:subprocess_popen_with_shell_equals_true] subprocess call with shell=True identified, security issue.
   Severity: High   Confidence: High
   CWE: CWE-78 (https://cwe.mitre.org/data/definitions/78.html)
   Location: /srv/app/handler.py:19:4
18	def run_report(report_name):
19	    subprocess.call("generate-report " + report_name, shell=True)
```

Four findings, each with a CWE identifier and a severity, in under a second and
without running the program. This is what static analysis is good at: patterns
that are recognisable in the text of the code. String-built SQL, a shell
invocation with concatenated input, a hash function that has no business near a
password.

Now the other half.

<details class="predict">
<summary>The same file also sets a session cookie and decides who is an administrator. Predict what the analyser said about those two.</summary>

```bash
# AlmaLinux 10.2, x86_64
$ bandit -q -r /srv/app/handler.py -f json 2>/dev/null | python3 /srv/what-it-missed.py
issues found: 4
  line  4  LOW    B404
  line  8  HIGH   B324
  line 14  MEDIUM B608
  line 19  HIGH   B602

lines the analyser had nothing to say about:
  line 23      response.headers["Set-Cookie"] = "session=%s; Path=/" % token
  line 26  def is_admin(user):
  line 27      return user.get("role") == "admin" or user.get("is_admin")
```

**Nothing at all, on either.** Both lines are perfectly ordinary code and both are
defects.

Line 23 sets a session cookie with no `Secure`, no `HttpOnly` and no `SameSite`.
The session identifier will therefore travel over plain HTTP if the browser is
ever tricked into using it, is readable by any script on the page, and is attached
to cross-site requests. Three separate weaknesses in one line, and there is nothing
about the line's shape that a pattern matcher can object to, because the mistake is
what is absent.

Lines 26 and 27 are worse and quieter. The function returns true if the role is
administrator, **or** if the object carries anything truthy in an `is_admin`
field. If any part of that object is influenced by data the user controls, the
second clause is an authorisation bypass. The code is valid, idiomatic, and does
exactly what it says. Deciding it is wrong requires knowing what the object is and
where it came from, which is not in this file.

That is the shape of the blind spot rather than a gap in this particular tool. A
static analyser reads structure. Missing security properties and incorrect
decisions are not structural, so a clean report means the recognisable patterns
are absent and nothing more.

</details>

<details class="deeper">
<summary>If you have argued about client-side validation: what it is genuinely for, and the sentence that settles it</summary>

Validation in the browser is not security and it is not useless, and both halves
of that are worth being able to say.

The sentence that settles the argument is that the browser is not where the
request comes from. It is where a request usually comes from. An attacker sends
HTTP directly, with whatever body they like, and every check that lives in
JavaScript is simply absent from that interaction. Not bypassed, not weakened.
Absent, because the code that performed it was never run.

What client-side validation is for is the honest bit: it is an interface feature.
It tells somebody their postcode is malformed before they wait for a round trip,
it stops the server processing a hundred obviously wrong submissions, and it makes
a form feel responsive. Those are real benefits and none of them is a control.

The practical rule follows directly. Every check that matters is repeated on the
server, and the client-side copy exists for the user's convenience. Where the two
disagree, the server wins and the disagreement itself is worth logging, because a
request that fails a server check the client would have caught is a request that
did not come from your form.

And the apostrophe from the top of the page belongs here. Rejecting `'` is
character filtering, which is what people do instead of validation. The right
question is what the field is for: a surname field accepts the characters
surnames contain, and the SQL problem is fixed by parameterising the query rather
than by deciding which letters are frightening.

</details>

## What a signature proves

A package signature is a different kind of control and it answers a much narrower
question than people assume.

```bash
# AlmaLinux 10.2, x86_64
$ cd /tmp && dnf -q download zlib 2>/dev/null; ls *.rpm; echo "=== as shipped"; rpm -K *.rpm; echo "=== one byte changed in the middle of the payload"; cp zlib*.rpm tampered.rpm; printf "\x00" | dd of=tampered.rpm bs=1 seek=40000 conv=notrunc status=none; rpm -K tampered.rpm
zlib-ng-compat-2.2.3-3.el10_1.x86_64.rpm
=== as shipped
zlib-ng-compat-2.2.3-3.el10_1.x86_64.rpm: digests signatures OK
=== one byte changed in the middle of the payload
tampered.rpm: DIGESTS SIGNATURES NOT OK
```

One byte, and the answer flips. That is the entire claim: **this is the artefact
the signer signed, unchanged.**

Two things it does not claim. It does not say the code is safe, because the signer
may have signed something bad, deliberately or otherwise. And it does not say the
signer is trustworthy, because that judgement is yours and you made it when you
imported their key.

<details class="predict">
<summary>A vendor's signed installer contains a backdoor the vendor did not know about. What does signature verification report?</summary>

**Valid, and it is right to.** The signature is a statement about origin and
integrity, and both are true: the vendor built it, and it arrived unchanged.

This is not a hypothetical shape. It is the mechanism behind supply chain
compromises that reach large numbers of organisations at once, and signing is what
makes them effective rather than what fails to stop them. The artefact is
authentic, the verification passes everywhere, and the trust the signature carries
is exactly what delivers the payload.

The useful conclusion is not that signing is worthless. It removes an entire class
of attack, the one where somebody modifies a package in transit or on a mirror,
and that class used to be common. The conclusion is that signature verification
answers "did this come from where I think" and that a separate control has to
answer "should I be running this at all". Those are the sandbox, the monitoring,
and the decision about what the software is allowed to reach.

Anybody who tells you a signature makes code safe has compressed two questions
into one.

</details>

<details class="deeper">
<summary>If a sandbox is your answer to untrusted code: what a determined process still walks out with</summary>

A sandbox reduces the authority a piece of code holds. That is a precise
statement and it is narrower than the word suggests, because authority is not the
same as capability and the gap between them is where the disappointments live.

Start with what it genuinely does. A process confined by a seccomp filter, a
container, an app sandbox or a mandatory access control policy cannot make the
system calls it is denied, cannot open the files outside its permitted paths, and
cannot reach the network endpoints the policy excludes. Compromise it and you have
a process with those limits rather than a process with the user's full rights,
which is a real and large reduction.

Now the part that gets skipped. Everything the application legitimately needs
remains available, by construction, because otherwise it would not work. A
sandboxed application that reads the customer database reads the customer
database, and so does whoever takes it over. Confinement moves the question from
what the attacker can do on the machine to what the application was allowed to do,
and if the application was allowed too much, the sandbox has changed the shape of
the problem without changing its size.

Three further leaks worth knowing. The sandbox usually cannot constrain what the
application writes into its own permitted storage, so data staged for exfiltration
looks like normal operation. It rarely constrains outbound connections finely
enough to matter, because most applications need to reach something. And the
policy is written by somebody who had to make the application work, under time
pressure, which is why permissive rules outnumber tight ones in every real
deployment.

The habit worth building is to read a sandbox policy as a statement of what an
attacker gets rather than as a statement of what they are denied. It is the same
list, and reading it in that direction changes which rules look generous.

</details>

## Across platforms

All three verify signatures and they verify different units, which changes what
an unsigned thing means on each.

| Task | Linux | Windows | macOS |
| --- | --- | --- | --- |
| The unit that is signed | the package | the executable file | the executable file |
| Verify it | `rpm -K file.rpm` | `Get-AuthenticodeSignature file.exe` | `codesign --verify file` |
| What an unsigned artefact means | it came from outside the repositories | ordinary, and most scripts are | ordinary for command line tools |
| A separate "may it run" question | none built in | `Get-ExecutionPolicy` for scripts | `spctl --assess` |

```powershell
# Microsoft Windows Server 2025 Datacenter, version 10.0.26100.0
> Get-AuthenticodeSignature C:\Windows\System32\notepad.exe | Select-Object Status, @{n='Signer';e={$_.SignerCertificate.Subject -replace ',.*',''}} | Format-List
Status : Valid
Signer : CN=Microsoft Windows

# The same check on a file nobody signed, which is most of what runs on a machine
> Set-Content -Path $env:TEMP\helper.ps1 -Value 'Write-Output "hello"'; Get-AuthenticodeSignature $env:TEMP\helper.ps1 | Select-Object Status, StatusMessage | Format-List
Status        : NotSigned
StatusMessage : The file C:\Users\RUNNER~1\AppData\Local\Temp\helper.ps1 is not digitally signed. You cannot run this script on the current system. For more information about running scripts and setting execution policy, see about_Execution_Policies at https://go.microsoft.com/fwlink/?LinkID=135170

# A signed binary with one byte changed, to see what the signature is actually over
> Copy-Item C:\Windows\System32\notepad.exe $env:TEMP\tampered.exe -Force; $b = [IO.File]::ReadAllBytes("$env:TEMP\tampered.exe"); $b[40000] = $b[40000] -bxor 0xFF; [IO.File]::WriteAllBytes("$env:TEMP\tampered.exe", $b); (Get-AuthenticodeSignature $env:TEMP\tampered.exe).Status
NotSigned

# Whether the machine would refuse to run the unsigned one
> Get-ExecutionPolicy -List | Format-Table -AutoSize
        Scope ExecutionPolicy
        ----- ---------------
MachinePolicy       Undefined
   UserPolicy       Undefined
      Process       Undefined
  CurrentUser       Undefined
 LocalMachine    RemoteSigned
```

**The second command is the one to sit with.** A one-line PowerShell script,
written a second ago, comes back `NotSigned`, and the status message says the
machine will not run it. That is the normal state of almost every script on almost
every Windows machine, which is why the execution policy exists as a separate
setting and why `RemoteSigned` is the practical default: signed if it came from
elsewhere, unsigned is fine if it was written locally.

The modified copy of `notepad.exe` also reports `NotSigned` rather than a hash
mismatch. Whether Windows reports a broken signature or no signature depends on
where the change landed relative to the file's own structures, and the fact that
matters is the same either way: `Valid` became not valid.

```bash
# macOS 26.5.2, arm64
$ codesign -dv --verbose=2 /bin/ls 2>&1 | grep -E "Identifier|Authority|TeamIdentifier|Signature|Format"
Identifier=com.apple.ls
Format=Mach-O universal (x86_64 arm64e)
Signature size=4442
Authority=Software Signing
Authority=Apple Code Signing Certification Authority
Authority=Apple Root CA
TeamIdentifier=not set

# Verification rather than description, which is the check that can fail
$ codesign --verify --verbose=2 /bin/ls 2>&1
/bin/ls: valid on disk
/bin/ls: satisfies its Designated Requirement

# The binary holds more than one architecture, so where a change lands matters
$ lipo -archs /bin/ls; stat -f '%z bytes' /bin/ls
x86_64 arm64e
154624 bytes

# A copy with one byte inverted rather than overwritten, so the change is certain
$ cp /bin/ls /tmp/tampered-ls; python3 -c 'p="/tmp/tampered-ls"; b=bytearray(open(p,"rb").read()); o=len(b)*3//5; b[o]^=0xFF; open(p,"wb").write(b); print("flipped byte at offset", o)'; echo "bytes differing from the original:"; cmp -l /bin/ls /tmp/tampered-ls | wc -l | tr -d " "
flipped byte at offset 92774
bytes differing from the original:
1

# What the signature says about it now
$ codesign --verify --verbose=2 /tmp/tampered-ls 2>&1 | head -3
/tmp/tampered-ls: invalid signature (code or signature have been modified)
In architecture: arm64e

# Whether the system would let it run, which is a separate question from whether it is signed
$ spctl --assess --type execute --verbose=2 /bin/ls 2>&1; spctl --assess --type execute --verbose=2 /tmp/tampered-ls 2>&1 | head -2
/bin/ls: rejected (the code is valid but does not seem to be an app)
/tmp/tampered-ls: invalid signature (code or signature have been modified)
```

**macOS separates the two questions more clearly than the other two platforms
do**, and the last command is where you can see it. The unmodified `/bin/ls` is
signed by Apple, verifies, satisfies its designated requirement, and is still
`rejected` by the policy assessor. The reason given is that it does not seem to be
an app, which is a policy statement rather than a cryptographic one. Valid and
permitted are different answers to different questions, and only the second one
decides whether something runs.

Two other details worth carrying. The chain in the first block is visible: three
authorities from a leaf called Software Signing up to Apple Root CA, which is the
same structure as any certificate chain. And `In architecture: arm64e` in the
failure tells you which slice of a universal binary was being checked, because the
file contains two and the verification is per architecture.

## Prove it

**Run it.** Download any signed package with `dnf download` or `apt-get download`,
verify it with `rpm -K` or `dpkg-sig --verify`, then change a byte with `dd` and
verify again. Two commands and a byte, and the property is no longer abstract.

**Work it out.** Take the two lines the analyser missed. For each one, name a
control from the figure that would have caught it, and say at which point in the
pipeline that control runs. You should find that one of them is caught by a
different tool and the other is caught by a person.

**Look it up.** Open RFC 6265 and find what the `HttpOnly` attribute is specified
to do. Then decide what that means for a session cookie in a page that loads any
third-party script.

## What trips people up

### 1. Reading a clean static analysis report as clean code

It means the recognisable patterns are absent. Missing cookie flags and incorrect
authorisation logic are not patterns, and both were in the file the analyser
passed.

### 2. Treating a signature as a safety claim

It asserts origin and integrity. A vendor can sign something harmful and the
signature will verify correctly everywhere, which is the mechanism rather than the
failure in a supply chain compromise.

### 3. Validating in the browser

The browser is where a request usually comes from, not where it must come from.
A check written in JavaScript is not present in a request sent directly, so the
server repeats every check that matters.

### 4. Filtering characters instead of validating fields

Rejecting apostrophes breaks real names and stops nothing, because the SQL problem
is fixed by parameterising the query. Validate against what the field is for.

### 5. Confusing signed with permitted

On macOS, `/bin/ls` is validly signed by Apple and still rejected by `spctl`.
Whether something is authentic and whether policy allows it to run are two
questions and only the second one is a gate.

### 6. Expecting a sandbox to contain a legitimate action

A sandbox reduces authority. Whatever the application is allowed to do remains
available to anybody who takes it over, so an application permitted to read the
whole customer database is a sandbox away from nothing.

## Work it through

A team of six ships a web application weekly. There is no application security
tooling at all and you have been asked to introduce some. You can realistically
land one thing this quarter.

**The tempting move is dynamic analysis, because it finds real problems.** A
scanner against the running application produces findings that are demonstrably
exploitable, which is persuasive in a way a static finding is not. It also runs
late, produces work for a team already shipping weekly, and covers only the paths
it managed to reach.

**The move that works is static analysis wired into the pull request.** It is
cheaper to run, it runs before the code is anybody else's problem, and the four
findings above took under a second on a laptop. Crucially, the person who has to
act on a finding is the person who wrote the line an hour ago, which is the
difference between a fix and a ticket.

**Then the second thing is package monitoring, not the scanner.** Most of the
code in the application was written by somebody else and arrives through the
dependency file, and a dependency with a published vulnerability is the highest
ratio of risk removed to effort spent that this list offers.

**What this rejects is the control that finds the most interesting bugs.**
Dynamic analysis belongs in the plan and it belongs after the team has built the
habit of acting on findings at all. Introducing it first tends to produce a report
that gets read once.

The residual is the whole right-hand side of the figure, and it is worth writing
down rather than leaving implied. Nothing in this plan looks at authorisation
logic, and the `is_admin` defect above would survive all of it. That is a code
review by a person, and it does not have a product.

## Try it

**Run an analyser on your own code.** `pip install bandit && bandit -r .` for
Python, or the equivalent for your language. Read the findings, then find one
thing it did not flag that you know is wrong.

**Verify something you already trust.** `rpm -K` on a package,
`Get-AuthenticodeSignature` on a Windows binary, or `codesign --verify` on a Mac
one. Then copy it, change a byte, and verify again.

**Inspect a real cookie.** Open the developer tools on any site you log in to and
look at the session cookie's flags. `Secure`, `HttpOnly` and `SameSite` are either
there or they are not, and their absence is the defect this topic's example
contains.

**Check what your own site asserts.** `curl -sI https://example.invalid/` prints
the response headers. Compare what comes back against the six headers below, which
are the ones a review usually asks about.

```bash
# AlmaLinux 10.2, x86_64
$ curl -sI https://rlwilliamson.dev/ | grep -iE "^(HTTP|strict-transport|content-security|x-content-type|x-frame|referrer-policy|permissions-policy|set-cookie)"
HTTP/2 200 
strict-transport-security: max-age=63072000; includeSubDomains; preload
referrer-policy: strict-origin-when-cross-origin
x-content-type-options: nosniff
content-security-policy: default-src 'self'; img-src 'self' data: https://learn.microsoft.com https://fonts.gstatic.com; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; font-src 'self' https://fonts.gstatic.com; script-src 'self' 'unsafe-inline'; connect-src 'self'; frame-ancestors 'none'; base-uri 'self'; form-action 'self'; object-src 'none'
x-frame-options: DENY
permissions-policy: camera=(), microphone=(), geolocation=(), interest-cohort=()
```

There is no `set-cookie` line in that response, because the site sets none. That
is the cheapest possible answer to session cookie security and it is available to
fewer applications than you would like.

## Check yourself

<details class="qa">
<summary>A static analyser returns no findings on a file. What have you learned?</summary>

That the patterns it recognises are absent. Nothing more.

The file in this topic returned four findings and contained at least two more
defects: a session cookie set without `Secure`, `HttpOnly` or `SameSite`, and an
authorisation function that returns true for any truthy `is_admin` field. Both are
ordinary, valid code. One is a missing property and the other is an incorrect
decision, and neither is structural, which is what a static analyser reads.

</details>

<details class="qa">
<summary>What does a valid code signature tell you, and what does it not?</summary>

That the artefact came from the signer and has not changed since. One byte changed
in a package flips `digests signatures OK` to `NOT OK`.

It does not tell you the code is safe, because a signer can sign something
harmful, and it does not tell you the signer deserves trust, because that decision
was yours when you imported their key. A compromised vendor's signed installer
verifies perfectly everywhere.

</details>

<details class="qa">
<summary>Why is client-side validation not a security control, and what is it for?</summary>

Because an attacker does not use your form. A request sent directly never runs the
JavaScript, so the check is absent rather than bypassed.

It is a user interface feature: faster feedback, fewer wasted round trips, a form
that feels responsive. Keep it, repeat every meaningful check on the server, and
treat a request that fails a server check the client would have caught as a signal
worth logging.

</details>

<details class="qa">
<summary>On macOS, /bin/ls verifies as validly signed by Apple and spctl rejects it. Is something wrong?</summary>

No, and the pair is the point. `codesign --verify` answers whether the code is
authentic and unmodified. `spctl --assess` answers whether policy permits it to
run, and the reason given here is that it does not appear to be an app.

Authentic and permitted are separate questions. Only the second one is a gate, and
conflating them is how a validly signed but unwanted binary ends up trusted.

</details>

<details class="qa">
<summary>Name a defect class that each of static analysis, code signing and sandboxing cannot see.</summary>

Static analysis cannot see logic that is syntactically fine and decides the wrong
thing, or a security property that is missing rather than wrong.

Code signing cannot see whether the code is any good. It reports origin and
integrity and makes no claim about behaviour.

A sandbox cannot see anything the application is legitimately permitted to do,
because it constrains authority rather than intent. An application allowed to read
the whole customer database is constrained in ways that do not include that.

</details>

## References

- [SP 800-218](https://csrc.nist.gov/pubs/sp/800/218/final) - NIST, the Secure Software Development Framework, for where each practice belongs in a lifecycle. Free. Accessed 2026-08-25.
- [RFC 6265](https://www.rfc-editor.org/rfc/rfc6265.html) - IETF, HTTP state management, for what the cookie attributes are specified to do. Free. Accessed 2026-08-25.
- [CWE-89](https://cwe.mitre.org/data/definitions/89.html) - MITRE, SQL injection, the identifier the analyser reported against line 14. Free. Accessed 2026-08-25.
- [CWE-78](https://cwe.mitre.org/data/definitions/78.html) - MITRE, OS command injection, the identifier behind the `shell=True` finding. Free. Accessed 2026-08-25.
- [Get-AuthenticodeSignature](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.security/get-authenticodesignature) - Microsoft, for the status values in the Windows capture. Free. Accessed 2026-08-25.
- [About Code Signing](https://developer.apple.com/library/archive/documentation/Security/Conceptual/CodeSigningGuide/Introduction/Introduction.html) - Apple, for designated requirements and what verification checks. Free. Accessed 2026-08-25.

**Where the content came from.** The analyser output, the package signature check
and the header request are captured from an AlmaLinux 10.2 container. The signing
blocks are captured from disposable Windows and macOS runners. The vulnerable
program is written for this topic and its defects are deliberate, which is stated
rather than implied because the interesting result is the two lines the analyser
did not report on. Nothing here exploits anything: the SQL and command injection
findings are shown as an analyser's report on source code, and the tampering is
performed on local copies of files to demonstrate what a signature covers.

**If you also work on Linux.** The Linux+ track's
[packages, repositories and signing](/learn/linux-plus/packages-repositories-and-signing)
covers the package signature machinery in detail, including what importing a key
commits you to.
