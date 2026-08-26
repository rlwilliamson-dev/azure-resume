---
title: "Securing the operating system and the protocols"
description: "Two enforcement models that answer the same question differently, why the insecure protocol is still enabled and what breaks when you remove it, what each email authentication record actually asserts, and the one of the three an outsider cannot audit."
deck: "The application supports both. Nobody changed the default, and the default is the old one"
track: "security-plus"
level: "working"
order: 520
objectives:
  - "Compare mandatory enforcement with configuration policy as two enforcement models"
  - "Choose a protocol and a port for a task, and say what the insecure alternative costs"
  - "Read a real SPF record and say what it permits"
  - "Say what DMARC's policy field instructs a receiver to do"
  - "Explain why DKIM cannot be audited from outside the way the other two can"
  - "Describe what DNS filtering catches and where it stops working"
prerequisites: ["filtering-at-the-edge"]
tags: ["security-plus", "security", "operations", "hardening"]
updated: 2026-08-25
draft: false
examObjectives:
  - exam: "sy0-701"
    domain: "4.0"
    objective: "4.5"
sources:
  - title: "RFC 7208, Sender Policy Framework (SPF)"
    url: "https://www.rfc-editor.org/rfc/rfc7208.html"
    publisher: "IETF"
    accessed: 2026-08-25
    tier: 1
  - title: "RFC 6376, DomainKeys Identified Mail (DKIM) Signatures"
    url: "https://www.rfc-editor.org/rfc/rfc6376.html"
    publisher: "IETF"
    accessed: 2026-08-25
    tier: 1
  - title: "RFC 7489, Domain-based Message Authentication, Reporting, and Conformance (DMARC)"
    url: "https://www.rfc-editor.org/rfc/rfc7489.html"
    publisher: "IETF"
    accessed: 2026-08-25
    tier: 1
  - title: "SELinux Project documentation"
    url: "https://github.com/SELinuxProject/selinux/wiki"
    publisher: "SELinux Project"
    accessed: 2026-08-25
    tier: 1
  - title: "gpresult command reference"
    url: "https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/gpresult"
    publisher: "Microsoft"
    accessed: 2026-08-25
    tier: 1
symptoms:
  - symptom: "Mail from your domain is being spoofed and the records look correct"
    anchor: "three-records-and-the-one-you-cannot-audit"
  - symptom: "A service is still offering a protocol nobody meant to leave enabled"
    anchor: "the-old-protocol-is-still-there"
---

> **Before you read.** An application supports two protocols for the same job. One
> encrypts, one does not. The configuration file has never been edited, and the
> shipped default is the second one.
>
> Nobody chose this. It has been like that for four years.
>
> **Whose decision was it, and what would have caught it?**

Nobody's, which is the problem. Defaults are decisions made by somebody who has
never seen your environment, and the whole of this objective is about the ones
worth overriding and how you find out which those are.

### Some words you will need

<dl class="terms">
<dt>mandatory access control</dt>
<dd>Enforcement the process cannot override, based on labels rather than on ownership. SELinux is one implementation.</dd>
<dt>discretionary access control</dt>
<dd>The owner of a thing decides who may use it. Ordinary file permissions.</dd>
<dt>Group Policy</dt>
<dd>Settings pushed to Windows machines centrally. Configuration rather than a per-object label.</dd>
<dt>protocol selection</dt>
<dd>Choosing which protocol does a job, which is usually choosing whether it is encrypted.</dd>
<dt>SPF</dt>
<dd>A DNS record listing which servers may send mail using your domain.</dd>
<dt>DKIM</dt>
<dd>A signature over parts of a message, verified against a key published in DNS.</dd>
<dt>DMARC</dt>
<dd>A record saying what a receiver should do when the other two fail, and where to send reports.</dd>
<dt>alignment</dt>
<dd>DMARC's requirement that the domain SPF or DKIM validated matches the one a reader sees.</dd>
<dt>DNS filtering</dt>
<dd>Refusing to resolve names on a list, so the connection never starts.</dd>
</dl>

## What breaks without this

**A default nobody chose becomes the configuration.** The insecure option is
enabled because it shipped that way, and no review ever asks a question the answer
to which is a default.

**Removing the old protocol breaks something nobody knew about.** The one client
that still needs it is discovered during the change window rather than before it.

**Spoofed mail goes out under your name.** The records exist, they look right, and
one of the three is doing nothing because a field was set to monitor and never
moved.

**A filter is deployed at the wrong layer.** DNS filtering is added, the malicious
traffic uses addresses directly, and the control reports success against traffic
it was never going to see.

## Two ways to enforce, and they answer different questions

Two of the three platforms in this topic have a mandatory layer and they are not
the same shape.

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ echo "the enforcement model, and whether it is on:"; getenforce; sestatus 2>/dev/null | head -6; echo; echo "what it is actually enforcing, counted:"; seinfo 2>/dev/null | head -8 || echo "(seinfo not installed; the policy is in /sys/fs/selinux)"; ls /sys/fs/selinux/booleans 2>/dev/null | wc -l; echo "booleans, each one a switchable part of the policy"
the enforcement model, and whether it is on:
Enforcing
SELinux status:                 enabled
SELinuxfs mount:                /sys/fs/selinux
SELinux root directory:         /etc/selinux
Loaded policy name:             targeted
Current mode:                   enforcing
Mode from config file:          enforcing

what it is actually enforcing, counted:
367
booleans, each one a switchable part of the policy
```

**Enforcing, targeted policy, 367 booleans.** SELinux labels every process and
every object and consults a policy about whether this label may do that to that
label. Root does not exempt you: a process running as root in a confined domain is
still confined, which is the property that distinguishes mandatory from
discretionary control.

The 367 booleans are the practical face of it. Each one is a switchable piece of
policy, and the reason there are so many is that the policy has to accommodate
every legitimate thing every packaged service might do. That number is also why
SELinux gets disabled: somebody hits a denial, cannot find the boolean, and turns
the whole thing off rather than the one rule.

<details class="predict">
<summary>A process running as root is denied a file operation by SELinux. Predict what changing the file's permissions to 777 achieves.</summary>

**Nothing.** The denial is not about permissions and root is not an exemption.

Discretionary permissions and mandatory policy are two separate checks, and both
have to pass. Ordinary permissions ask whether this user may do this to this file.
SELinux asks whether a process in this domain may do this to an object with this
label. Making the file world-writable answers the first question more generously
and leaves the second one exactly as it was.

This is the single most common confusion about mandatory access control and it
produces a specific, recognisable afternoon: permissions get progressively looser,
the error does not change, and eventually somebody sets enforcement to permissive
and everything works, which appears to prove the problem was SELinux rather than a
missing label or an unset boolean.

The diagnostic that actually helps is to read the denial. It names the source
domain, the target label and the permission that was refused, and those three
things point at either a mislabelled file, which `restorecon` fixes, or a policy
decision, which a boolean usually covers.

The general lesson outlives SELinux. When two independent checks guard something,
loosening one of them changes nothing and leaves you with a weakened system and
the original problem.

</details>

<details class="deeper">
<summary>If you administer both: what Group Policy is for, and why it is not the same tool</summary>

Comparing SELinux with Group Policy is comparing a referee with a rulebook, and
the comparison is worth making precisely because the exam lists them together.

SELinux is a decision point in the kernel. Every relevant operation is checked
against a policy at the moment it happens, and a process cannot escape its own
label. Nothing about it is a setting in the ordinary sense.

Group Policy is a mechanism for applying configuration. It sets registry values,
installs certificates, configures the firewall, sets password rules and applies
security templates, centrally and repeatedly. Once applied, enforcement is done by
whatever component owns the setting, not by Group Policy itself.

The consequences differ in a way that matters operationally. A Group Policy
setting can be changed locally by an administrator between refresh intervals, and
the machine will drift until the next refresh puts it back. A SELinux policy is
not a setting that can drift; it is either loaded or it is not.

Windows does have a mandatory layer, and the capture on this page shows it:
integrity levels. A process runs at an integrity level and cannot write to objects
at a higher one, which is what keeps a browser's rendering process from modifying
system state. It is real mandatory control and its scope is far narrower than
SELinux's, covering a specific set of write operations rather than every class of
access.

The practical takeaway for an exam item and for a job: if the question is about
what a compromised process can do despite running as an administrator, the answer
on Linux is the mandatory policy and on Windows is integrity levels plus whatever
else is in the way. If the question is about how a setting gets to a thousand
machines and stays there, that is Group Policy and its Linux counterpart is a
configuration management tool rather than SELinux.

</details>

## The old protocol is still there

Every insecure protocol on this exam has a secure counterpart doing the same job,
and the reason the old one is still enabled is almost never that somebody decided
it should be.

The pairs are worth knowing as pairs, because exam items and real hardening
checklists both work by asking which one you are running. Telnet against SSH. FTP
against SFTP or FTPS. HTTP against HTTPS. SNMPv1 and v2c against SNMPv3. LDAP
against LDAPS. SMTP against SMTP with STARTTLS or implicit TLS. In every case the
old one carries credentials or content in the clear.

**Port selection follows protocol selection and is not a control by itself.**
Moving SSH to 2222 does not encrypt anything. It reduces log noise from automated
scanning, which is a real and modest benefit, and it is worth being clear that it
is a housekeeping measure rather than security.

The interesting question is what happens when you remove the old protocol, and
this is where hardening projects stall. The honest answer is that something
usually breaks, and the something is typically a device with no update path, a
script somebody wrote in 2014, or a supplier's integration. Removing the protocol
without finding those first turns a hardening task into an outage.

The sequence that works: enable the secure protocol alongside, log every use of
the insecure one for a full business cycle, take the resulting list of clients to
their owners, and only then disable. That converts an argument about risk into a
list of names, which is a much easier conversation.
<details class="deeper">
<summary>If you are removing a protocol: what the logs will not tell you, and the trick that finds the rest</summary>

Logging use of the insecure protocol before disabling it is the right move and it
has a specific blind spot worth planning around.

The logs record clients that connected during the observation window. They say
nothing about the quarterly job, the disaster recovery procedure nobody has
exercised this year, the supplier who integrates once at renewal, or the backup
route that only activates when the primary fails. Every one of those is a
legitimate user of the protocol that will be absent from a month of data, and
between them they account for most of the surprises.

Two things find the rest. The first is asking rather than observing: the list of
clients the logs did produce almost always names systems whose owners can tell you
about the periodic ones, because the person who runs the nightly job usually also
runs the quarterly one. That conversation is cheap and it is the step people skip
because they have data and feel finished.

The second is to make removal reversible and noisy rather than final. Disable the
protocol behind a change you can undo in minutes, announce a window, and make sure
somebody is watching the error logs of the dependent systems rather than only your
own. A failure that shows up as a supplier's overnight batch erroring is invisible
from your side until they call.

There is also the case where the insecure protocol cannot be removed at all,
because a device needs it and cannot be updated. That is a compensating control
problem rather than a hardening one: restrict which addresses may reach it, put
the traffic on a segment of its own, log every use, and record the arrangement as
an exception with an owner and a date. Leaving it enabled without that record is
the same protocol on the same port, and the difference is entirely whether anybody
has agreed to it.

</details>


## Three records, and the one you cannot audit

Email authentication is three separate mechanisms that get discussed as one, and
they answer three different questions.

```bash
# AlmaLinux 10.2, x86_64
$ dnf -q -y install bind-utils >/dev/null 2>&1; for d in rlwilliamson.dev github.com gov.uk; do echo "=== $d"; echo "  SPF:   $(dig +short TXT $d | grep -o "v=spf1[^\"]*" | head -1)"; echo "  DMARC: $(dig +short TXT _dmarc.$d | tr -d "\"" | head -1)"; done
=== rlwilliamson.dev
  SPF:   v=spf1 include:spf.tutanota.de -all
  DMARC: v=DMARC1; p=quarantine; adkim=s
=== github.com
  SPF:   
  DMARC: v=DMARC1; p=quarantine; sp=reject; pct=100; rua=mailto:dmarc@github.com; ruf=mailto:dmarc@github.com; fo=1
=== gov.uk
  SPF:   v=spf1 -all
  DMARC: v=DMARC1;p=reject;sp=none;np=reject;adkim=s;aspf=s;fo=1;rua=mailto:dmarc-rua@dmarc.service.gov.uk
```

<figure class="learn-figure">
<svg viewBox="0 0 720 292" role="img" aria-labelledby="mail-title" style="width:100%;height:auto;">
<title id="mail-title">Three email authentication records, the question each one answers, what it publishes, and the gap each one leaves that the next one has to close</title>
<g fill="currentColor">
<text x="14" y="20" font-size="11">three records, three different questions, and the gap each one leaves</text>
<rect x="14" y="42" width="86" height="56" rx="4" fill="var(--accent)" fill-opacity="0.14" stroke="var(--accent)" stroke-width="1.5"/>
<text x="57" y="75" text-anchor="middle" font-size="10">SPF</text>
<text x="112" y="60" font-size="8.5" fill-opacity="0.9">asks: may this server send as this name</text>
<text x="112" y="76" font-size="8.5" fill-opacity="0.75">publishes: a list of permitted senders</text>
<text x="112" y="92" font-size="8" fill="var(--red)" fill-opacity="0.9">gap: the envelope sender, which the reader never sees</text>
<rect x="14" y="110" width="86" height="56" rx="4" fill="var(--accent)" fill-opacity="0.14" stroke="var(--accent)" stroke-width="1.5"/>
<text x="57" y="143" text-anchor="middle" font-size="10">DKIM</text>
<text x="112" y="128" font-size="8.5" fill-opacity="0.9">asks: was this message altered in transit</text>
<text x="112" y="144" font-size="8.5" fill-opacity="0.75">publishes: a signature over chosen headers</text>
<text x="112" y="160" font-size="8" fill="var(--red)" fill-opacity="0.9">gap: a selector you cannot guess from the domain</text>
<rect x="14" y="178" width="86" height="56" rx="4" fill="var(--accent)" fill-opacity="0.14" stroke="var(--accent)" stroke-width="1.5"/>
<text x="57" y="211" text-anchor="middle" font-size="10">DMARC</text>
<text x="112" y="196" font-size="8.5" fill-opacity="0.9">asks: what should a receiver do about a failure</text>
<text x="112" y="212" font-size="8.5" fill-opacity="0.75">publishes: a policy, and where to report</text>
<text x="112" y="228" font-size="8" fill="var(--red)" fill-opacity="0.9">gap: alignment: the two above must match the visible From</text>
<text x="14" y="258" font-size="10" fill-opacity="0.85">SPF and DMARC sit at names anybody can look up. DKIM does not, which is why</text>
<text x="14" y="278" font-size="10" fill-opacity="0.85">an outsider can audit two of the three and only guess at the third</text>
</g></svg>
<figcaption>Each record answers a different question and leaves a different gap. SPF says which servers may send, and it validates the envelope sender rather than the address a reader sees, so on its own it can be satisfied by a message displaying somebody else's name. DKIM signs headers and content, so it survives forwarding better, and it says nothing about who was allowed to send. DMARC exists to close both gaps: it requires alignment between what was validated and what is displayed, and it tells the receiver what to do about a failure. Two of the three sit at names anybody can look up, which is why an outsider can audit your SPF and DMARC in seconds and can only guess at your DKIM.</figcaption>
</figure>

**Read the three domains against each other.** One publishes a narrow permitted
sender and asks receivers to quarantine failures. One publishes no SPF record at
the apex at all, and a DMARC policy of quarantine with a stricter policy for
subdomains and full reporting addresses. One publishes `v=spf1 -all`, which says
no server anywhere is permitted to send mail using this name, alongside a DMARC
policy of reject.

That third one is the strongest configuration on the page and it is worth
understanding why it is available. A domain that sends no mail from its apex can
say so absolutely, and `-all` with `p=reject` is a complete instruction: nothing
is authorised, refuse everything. Most organisations cannot do that because they
do send mail, which is why their records are longer and their policies weaker.

<details class="predict">
<summary>SPF and DMARC are at names anybody can query. Predict whether an outsider can find your DKIM keys the same way.</summary>

```bash
# AlmaLinux 10.2, x86_64
$ dnf -q -y install bind-utils >/dev/null 2>&1; echo "SPF and DMARC live at names anybody can guess. DKIM does not:"; for s in default selector1 google s1 dkim; do printf "  %s._domainkey.github.com -> %s\n" "$s" "$(dig +short TXT $s._domainkey.github.com | head -c 60)"; done; echo; echo "the selector is named in the message header, not in the DNS:"; dig +short TXT _dmarc.github.com | tr -d "\"" | tr ";" "\n" | sed "s/^ *//" | head -4
SPF and DMARC live at names anybody can guess. DKIM does not:
  default._domainkey.github.com -> 
  selector1._domainkey.github.com -> "v=DKIM1; k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCxZ
  google._domainkey.github.com -> "v=DKIM1; k=rsa; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCA
  s1._domainkey.github.com -> "k=rsa; t=s; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAy
  dkim._domainkey.github.com -> 

the selector is named in the message header, not in the DNS:
v=DMARC1
p=quarantine
sp=reject
pct=100
```

**Only by guessing, and guessing works more often than it should.**

DKIM keys live at `<selector>._domainkey.<domain>`, and the selector is chosen by
whoever configured the sending service. There is no record anywhere in DNS listing
which selectors exist, because the selector arrives in the message header where a
verifier reads it.

Three of the five common selectors tried above returned a key, each different from
the others. That tells an outsider something real: this domain sends through at
least three separate services, each of which set up its own selector, and two of
those selectors are named after the products that created them.

Two consequences. For an auditor, DKIM is the one of the three you cannot check
from outside with confidence, so a review that says "SPF, DKIM and DMARC are all
configured" has verified two of them and taken the third on trust. For a defender,
the selectors you can guess are an inventory of your own mail senders that you did
not intend to publish, which is mild rather than serious and is worth knowing
before somebody points it out.

The practical check, since the records cannot be enumerated: send yourself a
message from each system that sends on your behalf and read the DKIM header. That
is the only reliable way to find out which selectors are in use, and it usually
turns up a service nobody remembered.

</details>

<details class="deeper">
<summary>If you own the domain: what the DMARC policy field actually instructs, and the value that does nothing</summary>

DMARC's `p=` field takes three values and the difference between them is the whole
of the control.

**`p=none`** asks the receiver to do nothing differently. It is monitoring: the
reports arrive, the mail flows exactly as it would have, and no spoofed message is
ever rejected on account of it. This is the correct starting point and it is where
a very large number of domains have sat for years, because moving off it requires
being confident you have found every legitimate sender.

**`p=quarantine`** asks the receiver to treat failures as suspicious, which in
practice means the spam folder. It is a real reduction and it is not a block.

**`p=reject`** asks the receiver to refuse the message outright. It is the only
value that stops a spoofed message reaching a person.

**A domain at `p=none` has DMARC configured and has no DMARC protection**, and
that sentence is worth being able to say in a meeting, because the compliance
question is usually phrased as whether DMARC is present.

Two further fields are worth knowing because they turn up in real records. `sp=`
sets a separate policy for subdomains, which lets an organisation reject on
subdomains while still working through the apex, and one of the domains captured
on this page does exactly that. `pct=` applies the policy to a percentage of
messages, which exists to make the move from none to reject gradual.

The reason so many domains stall at none is worth naming honestly: the reports are
XML, they arrive in volume, and reading them well enough to be confident you have
found every legitimate sender is work somebody has to be assigned. The technical
change is one DNS edit. The project is the inventory of who sends mail as you, and
that is the same asset management problem as everything else on this exam.

</details>
<details class="deeper">
<summary>If you run a mail gateway: what it adds that the three records cannot, and the check it performs badly</summary>

The three DNS records answer questions about the sender's domain. A mail gateway
answers questions about the message, and the two sets barely overlap.

What the gateway adds is content inspection: attachments unpacked and scanned,
links rewritten so they can be checked at the moment somebody clicks rather than
at delivery, and a judgement about whether a message that passed every
authentication check is nonetheless a fraud. That last one matters more than it
sounds, because the most effective business email compromise is sent from a domain
the attacker owns and has configured perfectly. SPF, DKIM and DMARC all pass. They
were never asking whether the sender is trustworthy, only whether they are who
they claim.

Link rewriting is the feature worth understanding, because it changes the timing
of the check. A URL that was harmless at delivery and hostile an hour later is a
real and common technique, and rewriting is the only mechanism that catches it. It
also means every link in every message now routes through a third party, which is
a privacy and availability consideration somebody should have signed off.

The check gateways perform badly is display name spoofing. A message whose From
header shows a familiar name and an unfamiliar address passes every technical
check, because nothing in the standards constrains what a display name may say.
Some gateways flag it, most do so crudely, and the reliable answer is a mail client
that shows the address rather than the name, which is a client configuration
question rather than a gateway one.

The general shape to carry: authentication records answer whether a domain
authorised this message. Nothing in them answers whether the message is honest,
and conflating those two is how an organisation with a perfect DMARC posture loses
money to an invoice.

</details>


## DNS filtering, and where it stops

DNS filtering refuses to resolve names on a list, so the connection is never
attempted. It is cheap, it applies to every application without configuration, and
it catches a genuine and large share of ordinary badness, because most malicious
infrastructure is reached by name.

Where it stops is equally clear. Traffic that uses an address directly never asks
a resolver anything. A device configured with its own resolver bypasses yours. And
encrypted DNS moves the query somewhere your resolver cannot see, which is a
privacy improvement for the user and a control failure for the organisation, and
both of those statements are true at once.

That last one is worth sitting with rather than resolving. An organisation that
blocks encrypted DNS to preserve its filtering is making a defensible choice and
is also reducing the privacy of people on its network, and the honest version of
the policy says so.

## Across platforms

The mandatory layer exists on all three and is a different thing on each.

| Task | Linux | Windows | macOS |
| --- | --- | --- | --- |
| Is a mandatory layer enforcing | `getenforce` | integrity levels, always on | `csrutil status` |
| What it constrains | every labelled operation | writes to higher integrity objects | what root itself may modify |
| Central configuration | a configuration management tool | Group Policy | configuration profiles |
| How much is switchable | 367 booleans here | audit subcategories and policy settings | few switches, mostly on or off |

```powershell
# Microsoft Windows Server 2025 Datacenter, version 10.0.26100.0
> gpresult /r /scope:computer 2>&1 | Select-String -Pattern 'Applied Group Policy Objects|The following GPOs|N/A|None' | Select-Object -First 4 | ForEach-Object { $_.Line.Trim() }
Site Name:                   N/A
Group Policy was applied from:      N/A
Applied Group Policy Objects
N/A

# The nearest thing to a mandatory model, which is integrity levels on processes
> whoami /groups 2>&1 | Select-String -Pattern 'Mandatory Label' | ForEach-Object { $_.Line.Trim() }
Mandatory Label\High Mandatory Level                          Label            S-1-16-12288

# How many audit subcategories exist and how many are actually switched on
> $a = auditpol /get /category:* 2>&1; ($a | Select-String -Pattern '^\s{2}\S' | Measure-Object).Count; ($a | Select-String -Pattern 'Success|Failure' | Measure-Object).Count
60
27

# Which secure and insecure protocol pairs this machine currently offers
> Get-NetTCPConnection -State Listen | Where-Object { $_.LocalPort -in 21,22,23,25,80,443,445,3389,5985,5986 } | Select-Object LocalPort -Unique | Sort-Object LocalPort | ForEach-Object { $_.LocalPort }
22
80
445
3389
5985
5986
```


# provenance: Microsoft Windows Server 2025 Datacenter, version 10.0.26100.0, runner image 20260818.207.1

**Sixty audit subcategories and twenty-seven switched on**, which is the number to
carry from this block. Audit configuration is the input to everything in the
monitoring topic, and slightly less than half of it is enabled by default on a
machine nobody has configured.

The Group Policy result is `N/A` throughout because this machine is not joined to
a domain, which is the honest state of a standalone server and worth seeing: the
central mechanism exists and is doing nothing here. The mandatory line underneath
is the one that is always doing something. `Mandatory Label\High Mandatory Level`
is the integrity level of this process, and integrity levels are enforced whether
or not anybody configured anything.

The port list at the end is the protocol question made concrete. Six ports, and
two of them are the pair worth noticing: 5985 and 5986 are remote management
without and with TLS, offered simultaneously, on a machine nobody hardened.

```bash
# macOS 26.5.2, arm64
$ csrutil status 2>&1
System Integrity Protection status: disabled.

# Whether the boot chain is verified, which is the other half of the same idea
$ csrutil authenticated-root status 2>&1; sudo nvram -p 2>/dev/null | grep -c boot-args
Authenticated Root status: enabled
1

# The per-application consent database, which is the layer users actually meet
$ sudo ls -l /Library/Application\ Support/com.apple.TCC/TCC.db 2>&1 | head -2
-rw-r--r--  1 root  wheel  73728 Jul 28 05:41 /Library/Application Support/com.apple.TCC/TCC.db

# Which secure and insecure protocol pairs this machine currently offers
$ sudo lsof -nP -iTCP -sTCP:LISTEN 2>/dev/null | awk '{print $9}' | grep -oE ':[0-9]+$' | tr -d ':' | sort -n -u | tr '\n' ' '; echo
22 
```

**System Integrity Protection is disabled on this machine**, and that is a
property of a continuous integration runner rather than of macOS. It ships
enabled, and disabling it requires booting to recovery, which is exactly the
friction the design intends. The runner image turns it off so that automated jobs
can modify the system, which is a reasonable trade for a disposable machine and
would be alarming on a laptop.

Authenticated Root is still enabled, so the system volume's cryptographic seal is
intact even with SIP off. Those are two separate protections and one of them
survives.

The TCC database is the layer users actually meet: a file owned by root recording
which applications have been granted access to the camera, the microphone, the
disk and the rest. It is mandatory in the same sense SELinux is, in that an
application cannot grant itself an entry, and it is scoped to user data rather
than to every operation.

And one listening port against Windows's six. Both machines are freshly
provisioned and neither had anything installed, so that difference is a default
posture rather than a configuration.

## Prove it

**Run it.** `dig +short TXT yourdomain` and `dig +short TXT _dmarc.yourdomain`
take two seconds and tell you what the world thinks about mail from your name.
Then read the `p=` value and decide whether it is doing anything.

**Work it out.** Take the three DMARC records on this page and rank them by how
much a spoofed message would be inconvenienced. Then say what each domain would
have to do to get to the next level, and which of those steps is a technical
change and which is an inventory.

**Look it up.** Open RFC 7489 and find what it says about alignment. The
distinction between the domain that was validated and the domain a reader sees is
the reason DMARC exists, and the RFC states it more precisely than any summary.

## What trips people up

### 1. Loosening permissions to fix an SELinux denial

They are two independent checks. Making a file world-writable answers the
discretionary question and leaves the mandatory one untouched, so the error does
not change and the system is now weaker.

### 2. Treating a port change as security

Moving SSH off 22 reduces automated scanning noise. It encrypts nothing and stops
nobody who is looking at your estate specifically.

### 3. Reading "DMARC is configured" as protection

A record with `p=none` monitors and blocks nothing. It is the right place to start
and a very large number of domains have been there for years.

### 4. Assuming DKIM can be audited from outside

The selector is not published anywhere. A review that checked SPF and DMARC by
query has verified two of three and taken the third on trust.

### 5. Disabling a protocol before finding who uses it

Something usually depends on it, and it is usually a device with no update path or
a script from years ago. Log the use first, then take a list of names to their
owners.

### 6. Expecting DNS filtering to see everything

Traffic to a literal address asks no resolver anything, a device with its own
resolver bypasses yours, and encrypted DNS moves the query out of your view
entirely.

## Work it through

Mail is being spoofed as your domain. Finance received an invoice that looked
internal. The records exist: SPF lists three services, DKIM is configured, DMARC
is present with `p=none`.

**The tempting move is to set `p=reject` today.** It is one DNS edit, it stops the
spoofing, and it will also stop the monthly statement run, the ticketing system's
notifications and the marketing platform, because at least one of them is sending
in a way that does not align and nobody knows which.

**The move that works reads the reports first.** The `rua` address is already
receiving aggregate reports if it is set, and if it is not, setting it is the
first change. Those reports name every source sending as your domain and whether
each one passed, which turns "we think there are three senders" into a list.

**Then move in stages.** Fix alignment for the legitimate senders the reports
reveal, go to `p=quarantine` with a percentage, watch for a cycle, then raise it.
The subdomain policy is the useful lever in the meantime: `sp=reject` costs
nothing if nothing legitimate sends from subdomains, and it closes the most
convenient spoofing route immediately.

**What this rejects is the one-line fix.** The DNS change is trivial and the
project is finding out who sends mail as you, which nobody has ever written down.
Doing it in the wrong order produces an outage in a business process and a
reputation for security changes breaking things.

The residual, stated plainly: until the policy moves off none, spoofed mail
reaches inboxes and the only protection is the mail gateway's own judgement and
the recipient's. That is worth writing down with a date, because the interim can
otherwise last years.

## Try it

**Look up your own three.** `dig +short TXT yourdomain` for SPF,
`dig +short TXT _dmarc.yourdomain` for DMARC, and for DKIM send yourself a message
and read the selector out of the header, because there is no other reliable route.

**Ask a machine what it is enforcing.** `getenforce` and `sestatus` on Linux,
`csrutil status` on a Mac, `whoami /groups` on Windows to see the integrity level.
Three different answers to a similar question.

**Count your audit coverage.** `auditpol /get /category:*` on Windows and compare
the number of subcategories with the number switched on. The gap is what your
monitoring cannot see.

**Find your insecure pair.** List what is listening on a server you own and look
for a pair like 5985 and 5986, or 80 and 443, or 389 and 636. Offering both is
common and is rarely a decision anybody made.

## Check yourself

<details class="qa">
<summary>A root process is denied by SELinux. Why does chmod 777 not help?</summary>

Because they are two independent checks and both must pass. Ordinary permissions
ask whether this user may act on this file. SELinux asks whether a process in this
domain may act on an object with this label, and root is not an exemption from it.

Loosening the permission answers the first question more generously and leaves the
second unchanged, so the error persists and the file is now world-writable. The
denial message names the domain, the label and the permission, and the fix is
usually a relabel or a boolean.

</details>

<details class="qa">
<summary>What does each of SPF, DKIM and DMARC assert, and which one can an outsider not verify?</summary>

SPF lists which servers may send mail using the domain, checked against the
envelope sender. DKIM is a signature over selected headers and the body, verified
against a key in DNS. DMARC states what a receiver should do when the others fail
and requires alignment with the domain a reader actually sees.

DKIM is the one an outsider cannot verify, because the key lives at a selector
that is not published anywhere and arrives in the message header instead. Guessing
common selectors works often enough to be worth doing and proves nothing about the
ones you did not guess.

</details>

<details class="qa">
<summary>A domain publishes DMARC with p=none. What protection does it provide?</summary>

None, in the sense the word is usually meant. `p=none` asks receivers to change
nothing and to send reports, so spoofed mail is delivered exactly as it would have
been.

It is the correct starting point, because the reports are how you find every
legitimate sender before tightening. It becomes a problem when it is treated as
completion, which is why a compliance answer of "DMARC is configured" needs the
follow-up question about the policy value.

</details>

<details class="qa">
<summary>Why is disabling an insecure protocol harder than it looks, and what sequence works?</summary>

Because something depends on it and nobody knows what. Typically a device with no
update path, a script written years ago, or a supplier's integration.

Enable the secure protocol alongside, log every use of the insecure one for a full
business cycle, take the resulting list of clients to their owners, and disable
afterwards. That converts an argument about risk into a list of names, and the
list is what makes the change approvable.

</details>

<details class="qa">
<summary>Name two situations where DNS filtering sees nothing.</summary>

Traffic addressed to a literal IP address, which asks no resolver anything at all,
and a device configured to use its own resolver rather than yours.

Encrypted DNS is the third and the most awkward, because it moves the query
somewhere your resolver cannot observe. It improves privacy for the person using
it and removes the control for the organisation, and both of those are true at the
same time.

</details>

## References

- [RFC 7208](https://www.rfc-editor.org/rfc/rfc7208.html) - IETF, SPF, for what the record means and what `-all` asserts. Free. Accessed 2026-08-25.
- [RFC 6376](https://www.rfc-editor.org/rfc/rfc6376.html) - IETF, DKIM, for selectors and what the signature covers. Free. Accessed 2026-08-25.
- [RFC 7489](https://www.rfc-editor.org/rfc/rfc7489.html) - IETF, DMARC, for alignment, the policy field and the reporting addresses. Free. Accessed 2026-08-25.
- [SELinux Project](https://github.com/SELinuxProject/selinux/wiki) - the policy model, booleans and the tooling behind the first capture. Free. Accessed 2026-08-25.
- [gpresult](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/gpresult) - Microsoft, for what the Windows capture reports and what `N/A` means on an unjoined machine. Free. Accessed 2026-08-25.

**Where the content came from.** The SELinux block is captured from the virtual
machine this project uses for kernel-level work. The mail records are live DNS
queries made at capture time against three real domains, one of which belongs to
this site; nothing was sent to any of them and nothing was probed, because a TXT
record is published for anybody to read. The DKIM selector attempt uses five
common names and the topic says so, since the point being made is precisely that
they cannot be enumerated. The Windows and macOS blocks are from disposable
runners, and the macOS one has System Integrity Protection disabled because the
runner image turns it off, which is stated rather than left to imply that macOS
ships that way.

**If you also work on Linux.** The Linux+ track's
[SELinux](/learn/linux-plus/selinux) covers the enforcement model in detail,
including reading a denial and finding the boolean, and
[hardening a system](/learn/linux-plus/hardening-a-system) covers the protocol
removal this topic sequences.
