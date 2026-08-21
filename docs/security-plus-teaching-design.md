# CompTIA Security+ track: teaching design

How the SY0-701 material gets presented, and specifically where it has to differ
from the two tracks that already exist rather than inheriting either shape.
Companion to
[security-plus-sy0-701-research.md](security-plus-sy0-701-research.md), which
covers what is on the exam, and
[security-plus-topic-plan.md](security-plus-topic-plan.md), which covers what
gets written.

[linux-plus-teaching-design.md](linux-plus-teaching-design.md) governs everything
not contradicted here: the audience, progressive disclosure, concrete before
abstract, defining the word before using it, the voice, and the rules about
analogies and dry wit.
[network-plus-teaching-design.md](network-plus-teaching-design.md) governs
everything the Linux+ document got wrong for a second track: the three forms of
Prove it, cross-track duplication, triggered platform tables, the diagram rules,
how claims are worded, photographs, and the fact that the question standard takes
per-track amendments rather than applying unchanged. This document records only
the deltas from those two.

It exists for the same reason the Network+ one does. That document was written
because the first Network+ plan was produced by adapting the Linux+ shape and
several of those adaptations turned out to be wrong. The same is true again here,
in different places, and the places are listed below.

Researched 2026-08-21.

- [The thesis, and how the candidate one was tested](#the-thesis-and-how-the-candidate-one-was-tested)
- [What Prove it becomes](#what-prove-it-becomes)
- [What Try it becomes](#what-try-it-becomes)
- [The overlap audit](#the-overlap-audit)
- [The attack-demonstration rule](#the-attack-demonstration-rule)
- [Diagrams](#diagrams)
- [Photographs](#photographs)
- [The vocabulary problem, and the glossary decision](#the-vocabulary-problem-and-the-glossary-decision)
- [Cross-platform captures](#cross-platform-captures)
- [Within-track scope drift](#within-track-scope-drift)
- [Question design](#question-design)
- [The legacy bank](#the-legacy-bank)
- [What we are deliberately not building](#what-we-are-deliberately-not-building)
- [Decisions taken](#decisions-taken)
- [Open questions](#open-questions)

## The thesis, and how the candidate one was tested

The two existing theses do not transfer, and the reason is one number. Objectives
opening "Given a scenario" are 63.5 percent of Linux+ by weight, 44.3 percent of
Network+, and **24.7 percent of Security+**. Explain alone is 49.3 percent here.
A track built on "change a system and prove the change took" would ship most of
its pages promising to run something they cannot.

A candidate replacement came in with the work, offered to be tested rather than
adopted:

> Security+ teaches you to choose a control and defend the choice. Every topic
> ends in a decision, names the alternative it rejected, and says what the
> rejection cost.

**Tested against the objectives, it holds for about three quarters of the exam
and fails cleanly on the rest.** Going objective by objective and asking whether
the content ends in a choice among things you could actually deploy: nineteen do.
Risk treatment is literally a choice among accept, avoid, transfer and mitigate.
Objective 1.4's own statement contains the word appropriate. Objective 4.3 ends
in patch, mitigate, accept or take an exception.

Five do not, and they are a coherent group rather than scattered exceptions:
2.1 threat actors, 2.2 threat vectors, 2.3 vulnerability types, 2.4 indicators of
malicious activity, and 4.9 using data sources to support an investigation.
Nothing in those is a control you choose. You are handed evidence and asked what
it means. **That is 20.7 percent of the exam by weight**, which is too much to
call an exception, and it includes the objective with the most terms on the paper.

So the thesis widens rather than being replaced, and the widening is the part
that makes it true:

> **Linux+ teaches you to change a system and prove the change took. Network+
> teaches you to read a network you did not build and prove what it is doing.
> Security+ teaches you to pick the right one from a set of things that are all
> real, and to say what the ones you rejected would have cost you.**
>
> The set is controls for three quarters of the exam and explanations of evidence
> for the other quarter. Every topic ends in a named choice, states what it
> rejected, and states the price of the rejection. On the evidence objectives the
> price is a wrong response to a real incident, which is the most expensive
> rejection on the exam.

Three reasons that is the right sentence.

It matches what the exam actually does to a candidate. Four options, all of them
real security controls, one of them right for the scenario. A track built on
definitions rehearses recognition, which is the failure mode of every
glossary-shaped resource for this exam, and it is why so many people report
knowing the material and failing the paper.

It gives the conceptual three quarters an obligation rather than an exemption,
which is the same move the Network+ thesis made and the reason that one worked.
A governance topic with no command in it still has to end somewhere, and "here
are five documents in a hierarchy" is not an ending. "You need this to be true by
March, here are the three ways to get there, here is the one that survives an
audit and here is what the other two cost" is.

And it fixes the distractor rule for the banks before the first question is
written, which is the single largest thing this track would otherwise get wrong.
If every topic already names the alternative it rejected and why, the distractors
write themselves and each one has a reason attached. See
[question design](#question-design).

**One thing the thesis is not.** It is not an instruction to end every page with
a section headed "the decision". The template already has the sections that carry
this: **Work it through** is a scenario reasoned to a conclusion, and **What
trips people up** is where the rejected alternative usually lives. What changes
is that the reasoning has to land somewhere, and a page that finishes by
restating what the terms mean has not.

## What Prove it becomes

**The three forms carry over unchanged**: run it, work it out, look it up. Every
topic uses at least one and says at the foot which. Nothing about this exam
argues for a fourth.

What changes is the mix. On Network+ the arithmetic form was mostly subnetting
plus a handful of recovery metrics. Here it is a much larger share of the track,
and it is where this exam hides its equivalent of subnetting: a number you can
compute, get wrong in a nameable way, and check against a published tool.

Five families, each of which owns at least one topic:

| Family | The arithmetic | Checkable against |
| --- | --- | --- |
| Loss expectancy | SLE from asset value and exposure factor, ALE from SLE and ARO, against the annual cost of the control | The definitions in NIST SP 800-30, and the crossover point drawn as a figure |
| Recovery metrics | RPO, RTO, MTTR and MTBF read off one outage timeline | The timeline itself, which is the figure |
| Vulnerability scoring | A CVSS base score from a real vector string, and the same CVE's EPSS percentile | The FIRST calculator and the live EPSS API |
| Password entropy | Bits from an alphabet size and a length, and what one more bit buys | Powers of two, and a measured hash rate |
| Key lifetime | Key length against how long the data has to stay secret | NIST key-management guidance |

**Each of those is a place where the wrong answer has a name**, which is exactly
the property the Network+ subnetting rule wanted and mostly could not get outside
objective 1.7. Confusing SLE with ALE, reading MTTR as MTBF, quoting a CVSS score
as if it were a probability of exploitation: all three are specific errors a
distractor can be built from and an explanation can name.

The look-it-up form does more work here than on either other track, because
domain 5 is 20 percent of the exam with nothing to run. It stays what it is: a
named document, a named clause, and a question only that clause answers. Not a
reading list.

## What Try it becomes

Network+ has three forms, chosen by what the topic is: run the committed
topology, do the arithmetic, or read the named clause. Two of those transfer
directly. The topology form mostly does not, because outside a handful of network
security topics there is no second host to build.

**A fourth form replaces it, and it is better than what it replaces:**

> **Look at your own machine.** Almost every reader of this track is sitting in
> front of a computer that has full-disk encryption in some state, a certificate
> store with a few hundred roots in it, a host firewall, an authentication log,
> a screen lock policy and a patch level. Every one of those is a Security+
> subject, and the reader owns an instance of it.

That is available to a reader with no lab, no VM and no second machine, which is
the constraint that made the Linux+ "if you have a VM handy" framing fail for
most of the Network+ track. It is also the single most effective thing this track
can do to make an abstract control concrete: the difference between reading that
a certificate store is a list of organisations you have decided to trust, and
running one command to find out that you personally trust about a hundred and
fifty of them without ever having chosen any.

The four forms, and which topics use which:

| Topic kind | Try it is |
| --- | --- |
| Anything with a host tool | Run it against your own machine and read what comes back |
| The arithmetic topics | Compute it, then check against the named tool |
| The netlab topics, which are a minority here | Run the committed topology with one thing removed |
| Governance, risk and compliance | Read a named clause and answer a question only that clause answers |

**The safety rule that comes with form one.** Everything a reader is asked to run
on their own machine is read-only. No topic tells anybody to change a firewall
rule, disable a control, install a scanner or run anything against a network they
do not own. Where the interesting command would be a change, the topic gives the
read-only version and says what the change would be. That is not squeamishness:
a study page that gets somebody's work laptop flagged has done real damage, and
the authorisation-before-technique note already established in the Linux+
hardening topic is the tone to match.

## The overlap audit

**This is the largest design problem on the track and it has no precedent in
either existing one.** Network+ collided with nine Linux+ topics and accepted
roughly 40,000 words of overlap. Security+ collides with forty topics across both
tracks.

Measured rather than estimated: 743 objective terms matched against all 164
existing topics, then filtered to terms that are two words or longer or are
three-letter-plus acronyms, so that a hit means something more than the word
"encryption" appearing on a page.

| Track | Security-adjacent topics | Words |
| --- | --- | --- |
| Linux+ | 21 | 167,406 |
| Network+ | 19 | 83,338 |
| | **40** | **250,744** |

Word counts include figure markup and code fences, so the prose figure is lower
by a roughly constant fraction. The set is wider than the 32 topics the pre-work
named, because it includes the troubleshooting and monitoring topics that carry
security vocabulary without being security topics.

**Applying the Network+ rule unchanged would cost five times what it cost there**,
and it would produce three pages about TLS on one site that can drift apart in
public.

### The rule

**Keep "write self-contained, see-also at the foot" and change what
self-contained means.** The three tracks are answering different questions about
the same subject, so a complete answer to the Security+ question is not a
repetition of the other two:

- **Linux+ asks how you configure this on a RHEL or a Debian machine.**
- **Network+ asks what the protocol does and how you would know.**
- **Security+ asks which one you should choose, and what it costs when you are
  wrong.**

So the cryptography topic owes a reader a complete treatment of the decision:
symmetric against asymmetric, what key length buys, where the key lives, when you
rotate, what happens when it is lost, and what the certificate authority model
actually asks you to trust. It does not owe another TLS handshake walkthrough,
because the exam does not ask for one and Network+ topic 34 already has it.

That is scoping to the exam rather than stopping halfway and pointing elsewhere.
The see-also link at the foot stays what it is on Network+: further depth for
somebody who wants it, never a hole in the page.

### Linux+ topics that overlap

| Existing topic | Words | What it already answers | What the Security+ page owes instead |
| --- | --- | --- | --- |
| `07-reading-and-setting-permissions` | 5,835 | The bits, the octal, the directory rule, on both families | Permission restriction as one of the named ways to protect data, alongside encryption and tokenisation |
| `23-backup-and-restore` | 5,401 | tar, rsync, dump levels, restore verification | Backup as a resilience decision: frequency against RPO, offsite and journaling as named options, and testing as the control that is actually missing |
| `31-packages-repositories-and-signing` | 4,626 | GPG keys, repository trust, signature verification | Supply chain as a risk category with vendors, providers and a monitoring obligation |
| `37-authentication-and-pam` | 10,102 | The PAM stack, module types, control flags | Nothing. PAM is not on this exam. Federation, SSO and provisioning are, and PAM is not the way in |
| `38-central-identity` | 12,055 | LDAP, SSSD, Kerberos, realm join | Federation and single sign-on as a trust decision, and what the identity provider is actually asserting |
| `39-logging-and-auditing` | 9,246 | journald, rsyslog, auditd, rotation, accounting | Which log answers which question during an investigation, and what is missing when a log is missing |
| `40-firewall-concepts-and-netfilter` | 6,929 | Hooks, tables, chains, the packet path | Rules, ports and protocols as an enterprise capability you modify, not a ruleset you write |
| `41-firewalld-ufw-and-nftables` | 9,151 | Three front ends, zones, syntax | Nothing directly. The Security+ firewall content is about placement and rule intent |
| `42-sudo-in-depth` | 9,941 | sudoers syntax, aliases, logging, NOPASSWD | Privileged access management: just-in-time permissions, vaulting, ephemeral credentials |
| `43-ssh-and-secure-remote-access` | 9,394 | Keys, config, hardening, agent forwarding | Secure protocol selection as a decision, with the insecure counterpart named and the cost of the swap |
| `44-selinux` | 7,142 | Contexts, booleans, denials, relabelling | Mandatory access control as one of six named access control models, against discretionary, role, rule, attribute and time-of-day |
| `45-hardening-a-system` | 7,033 | Exposure counting, SUID, immutable files, sysctl, Secure Boot | Hardening targets as a list, and secure baselines against benchmarks as a decision |
| `46-password-policy-and-mfa` | 11,082 | chage, pam_pwquality, faillock, TOTP on Linux | Password concepts as policy: length against complexity, expiration and age, managers, passwordless, and what the evidence says about each |
| `47-cryptography-basics` | 12,129 | Hashing, HMAC, symmetric, asymmetric, signatures, salts, algorithm retirement | The whole of objective 1.4's decision half: key length, escrow, TPM against HSM against secure enclave, the obfuscation family, blockchain, root of trust, CSR contents, wildcard |
| `48-tls-certificates-and-acme` | 8,890 | The handshake, ACME, renewal, chain files | Revocation as a decision: CRL against OCSP against stapling, and what a client concludes when no answer arrives |
| `49-encrypting-data-at-rest` | 7,332 | LUKS, key slots, boot unlock, secure deletion | Data states, classification, sovereignty, and tokenisation against masking against encryption as three answers to one question |
| `50-compliance-auditing-and-integrity` | 9,063 | CVSS as severity not risk, oscap, AIDE, package trust | CVSS against EPSS against KEV as three numbers answering three questions, and the remediation decision that follows |
| `64-monitoring-concepts` | 5,817 | Metrics, thresholds, alert fatigue | Alerting and monitoring as named tools: SIEM, SCAP, NetFlow, SNMP traps, and what each is for |
| `65-reading-logs-to-find-a-cause` | 5,266 | Reading a journal to a root cause | Correlation across sources, and the identifier that ties three logs to one incident |
| `73-permission-and-access-troubleshooting` | 5,395 | Diagnosing a denial | Nothing. The diagnostic ladder is Linux-specific |
| `74-security-and-service-access-problems` | 5,577 | SELinux, certificates, repositories, ciphers as causes | Nothing directly, and it is the right see-also for several topics |

### Network+ topics that overlap

| Existing topic | Words | What it already answers | What the Security+ page owes instead |
| --- | --- | --- | --- |
| `32-wireless-security-and-authentication` | 4,485 | WPA2 against WPA3, PSK against enterprise | Wireless security settings as a configuration decision, with AAA and RADIUS named, and the cryptographic protocol choice |
| `33-security-vocabulary-and-the-cia-triad` | 3,592 | Risk, vulnerability, threat, exploit, and the triad | Non-repudiation, AAA broken into authenticating people against systems, gap analysis, and the control categories grid |
| `34-encryption-certificates-and-pki` | 4,561 | Symmetric and asymmetric, what a certificate binds, the padlock | The trust decision, revocation, self-signed against third-party, and key management |
| `35-identity-and-access-management` | 3,993 | Authn against authz, factors, four services, least privilege | Provisioning and deprovisioning, identity proofing, federation, interoperability, attestation, six access control models, and privileged access management |
| `37-lifecycle-change-and-configuration-management` | 3,519 | End of life, patching cycles, change process | Change management as a security control: approval, ownership, impact analysis, test results, backout plan, maintenance window, and the technical implications |
| `40-baselines-alerting-and-monitoring-solutions` | 6,519 | Baselines, thresholds, monitoring solutions | The alert response cycle: validate, quarantine, tune, and what a tuned-out alert costs |
| `41-disaster-recovery` | 5,052 | RPO, RTO, MTTR, MTBF, site types, testing | Resilience as architecture: capacity planning across people, technology and infrastructure, platform diversity, multi-cloud, power and cooling |
| `47-dns-security` | 5,305 | DNSSEC, DoH, poisoning | DNS filtering as an enterprise capability, and email authentication as its neighbour |
| `50-vpns` | 3,913 | Split against full tunnel, IPsec, site to site | Tunnelling as one of several secure communication choices, against SD-WAN and SASE |
| `52-physical-security-and-deception` | 4,553 | Bollards, vestibules, cameras, honeypots | The four sensor types by the physics each one detects, and deception's four artefacts distinguished |
| `53-compliance-and-audits` | 3,983 | Scope, locality, policy against configuration, evidence | Compliance reporting, non-compliance consequences, privacy law vocabulary, attestation, and audits against assessments |
| `54-acls-filtering-and-security-zones` | 4,216 | Rule order, implicit deny, zones | Access lists as one named way to modify an enterprise capability, and what a screened subnet is for |
| `55-network-segmentation` | 4,503 | VLANs, subnets, east-west | Segmentation as a data protection method and as an audit-scope decision |
| `56-layer-2-attacks` | 5,530 | ARP poisoning, MAC flooding, VLAN hopping | On-path and credential replay as indicators, seen from the defender's side |
| `57-attacks-on-services-and-people` | 3,775 | Denial of service, rogue services, social engineering | The full 2.4 taxonomy: malware, physical, network, application, cryptographic and password attacks, plus the nine indicators |
| `58-device-hardening-and-network-access-control` | 4,253 | Default credentials, NAC, 802.1X | Hardening targets across the whole estate, and secure baselines with deployment and maintenance |
| `59-cloud-concepts-and-connectivity` | 3,921 | Service and deployment models, VPCs, security groups | Cloud as an architecture model with named security implications, against on-premises, serverless, microservices, IoT, ICS and embedded |
| `60-zero-trust-sase-and-infrastructure-as-code` | 4,030 | Zero trust framing, SASE, drift | Zero trust to SP 800-207's own vocabulary: control plane against data plane, policy engine, administrator and enforcement point |
| `81-the-hour-after-it-breaks` | 3,635 | Conduct during a live incident, roles, comms | The incident response process as CompTIA names it, plus training, testing and root cause analysis |

### What the audit changes about the plan

Three things fall out of it.

**Objective 1.4 is the most heavily pre-covered ground on the exam and still
needs the most words**, because the existing 38,000 words across four topics
teach the mechanics and almost none of the decision. That is the clearest case
for the rule above, and it is why the first pattern topic comes from 1.4.

**Objective 5.3 is untouched.** Third-party risk assessment and management scored
one distinctive term hit across all 164 existing topics. Vendor assessment,
penetration testing of a supplier, right-to-audit clauses, evidence of internal
audits, independent assessments, supply chain analysis, and the whole contract
vocabulary of SLA, MOA, MOU, MSA, SOW, NDA and BPA are new ground. So is most of
2.1 threat actors and much of 2.3 vulnerability types.

**Two Linux+ topics owe nothing and should not be linked as though they do.**
`37-authentication-and-pam` and `73-permission-and-access-troubleshooting` are
excellent pages about mechanisms this exam does not test. A see-also link to
either would send a revising reader into 15,000 words of off-syllabus material,
which is the opposite of what the link is for.

**Links go both ways once the topics exist.** A Linux+ reader who lands on the
cryptography topic from a search should be told the decision-level treatment is
there. Neither existing track does this today and both should.

## The attack-demonstration rule

Network+ hit this once, with ARP poisoning, and resolved it in an open question.
Security+ hits it on most of domain 2, so it is a rule rather than a judgement
made per topic.

> **Capture the evidence, not the attack.** A topic may show what an attack looks
> like from the defender's side, produced by arranging the observable state
> directly. It does not run the attack. A neighbour table with two addresses on
> one MAC comes from a static entry. A brute-force pattern in an auth log comes
> from failed logins somebody made. A malicious indicator comes from a published
> sample's hash, never from the sample.

Everything on this track is written for the person defending the system. Where a
technique cannot be shown without doing the thing, it stays described, and the
topic says in its provenance line that the evidence half is what was captured.

**The objectives document supports this rather than merely permitting it.**
Objective 2.4 lists its indicators separately from its attacks: account lockout,
concurrent session usage, blocked content, impossible travel, resource
consumption, resource inaccessibility, out-of-cycle logging, published or
documented, and missing logs. Those nine are what a defender sees. The exam asks
you to reason from them to the attack, which is exactly the direction the rule
produces.

Three consequences worth stating before anybody writes a topic.

**A capture that shows only the effect still says so.** A failed-login block in
an auth log is real output from real failed logins, and the topic says that
rather than implying somebody ran a password spray.

**Nothing is run against a third party.** The public API captures query
services that publish the data for that purpose: NVD, EPSS, the KEV catalogue,
certificate transparency. Scanning, probing or enumerating anything else is out,
and the reason is the same one the Linux+ hardening topic gives for `nmap`:
authorisation comes before technique.

**No sample malware, ever.** A hash from a published advisory is a real indicator
and it is the whole of what the track needs.

## Diagrams

The pre-work carried an instruction to make a figure per lesson a floor with a
test behind it, and estimated roughly 70 figures against 29 built for Network+.

**The 29 is the number of diagrams the Network+ plan listed. The track shipped
115, across 82 of its 83 topics.** Linux+ has 82 across 80 of 81. In both cases
the only topic without one is the orientation page. So the floor being asked for
is already what both tracks do, and the honest framing is that this makes an
existing convention enforceable rather than that it adds seventy figures of new
cost. It is still the largest single line of work on the track. It is not a
change of standard.

**The floor, and the test.** Every lesson carries at least one figure. Exemptions
are a keyed list with a reason, in the same test file and the same shape as the
predict and deeper panel floors, and the exempt list is itself tested so an entry
keyed to a slug that no longer exists fails the build.

All the existing figure rules apply unchanged. The two that bite hardest here:

**Draw the insight, not the layout.** Security material is full of diagrams that
show boxes where the argument was about failure. A picture of a PKI hierarchy is
decoration with a footnote. A picture of one certificate chain with the real
subject, issuer and validity dates from a captured `openssl x509`, and an arrow
showing which field each link signs, is the argument.

**A figure with two insights in it is two figures.** The temptation on this track
is the omnibus: one drawing covering symmetric and asymmetric and hashing and
signing. That is four figures and it always reads as a poster.

**Colour is never the only channel**, which matters more here than on Network+
because nearly every distinction this track draws is trusted against untrusted,
allowed against blocked, or before against after. Each of those is a place an
author reaches for red and green.

**Detail earns its place when it carries data.** The real vector string, the real
digest, the real timestamp goes in the drawing, and the reason it matters goes in
the caption.

The starter list names the argument each figure makes rather than its subject,
because a plan row reading "diagram: PKI" produces the generic version. It lives
in the [topic plan](security-plus-topic-plan.md), one per row, so the argument is
on screen at the moment the figure gets drawn.

## Photographs

**They are back on the table and two objectives need them.** Objective 1.2 names
bollards, access control vestibules, fencing, video surveillance, security
guards, access badges, lighting, and four sensor types: infrared, pressure,
microwave and ultrasonic. Objective 4.2 covers asset management including
disposal and sanitisation.

The test is the one the Network+ design set, unchanged: does this topic name a
physical object the reader may never have held. For the physical security topics
the answer is yes for most of the list, and the sensors are the interesting case
because four different physical principles look identical as a bullet list and
completely different as four photographs.

Research images at the same time as the sources for those topics, not
afterwards. The Network+ experience was that a later pass finds fewer and worse
ones.

**The licence rule is unchanged and it is not negotiable.** A licence that
permits display, a local file under `src/content/learn/security-plus/images/`, an
entry in `images/credits.json`, and a visible credit in References. Attribution
is not a licence. Never hotlink.

Network+ has a working precedent for one of these already: it carries a
photograph of a hardware security module, which is an object almost nobody has
seen and which objective 1.4 names.

## The vocabulary problem, and the glossary decision

**743 unique terms and 328 acronyms, half again as many as Network+.** This is
the largest vocabulary of the three exams and it is the thing most likely to
produce a track that covers everything and teaches nothing.

**No `/glossary` route.** The repository already refused one for Network+ at 490
terms with 48 duplicates and no disambiguation policy, and the reasoning gets
stronger rather than weaker at this size. A term is taught in the topic that owns
the idea, in the `dl.terms` list at the top or inline on first use. That list
carries more weight on this track than on either other one.

**The term-level check runs per block, not once at the end.** On Network+ it ran
last and found seven strings CompTIA prints that appeared nowhere in the track,
one of which the bank was already asking for while the topic taught it under a
different name, so a reader could get a question wrong having read the page it
links to. At 743 terms that will not be one case. The script is committed rather
than thrown away, it takes an objective or a block as an argument, and it reports
terms with no match anywhere in the track.

**The acronym policy, decided here.** Of 334 appendix entries, 241 name something
that appears nowhere in the objectives text in any form. An abbreviation whose
concept the track teaches gets the abbreviation printed once, in the topic that
teaches it. An abbreviation naming something genuinely off the objectives gets
nothing. The full reasoning and the breakdown of what those 241 are is in the
[research document](security-plus-sy0-701-research.md#the-acronym-list).

**The five collisions are the exception and they earn real treatment**, because
they are a way to get a question wrong rather than a word to recognise:

| Abbreviation | Meanings on this exam |
| --- | --- |
| MAC | Mandatory Access Control, Media Access Control, Message Authentication Code |
| PAM | Privileged Access Management, Pluggable Authentication Modules |
| RA | Recovery Agent, Registration Authority |
| RBAC | Role-based Access Control, Rule-based Access Control |
| SAN | Storage Area Network, Subject Alternative Name |

MAC is the worst of them: three meanings across three domains, and a candidate
who has only met one will misread a stem without noticing.

## Cross-platform captures

The Network+ trigger rule applies and the list of triggering tools is different,
because the Linux-only tools on this track are different ones.

**A topic owes the Windows and macOS answers if it tells a reader to run any of:**
`openssl`, `sha256sum`, `gpg`, `ssh-keygen`, `journalctl`, `ausearch` or
`auditctl`, `getenforce`, `ss`, `iptables` or `nft`, `dig`, `passwd` or `chage`,
`last` or `lastb`, `stat`, or anything that reads a certificate store.

The counterparts, captured rather than sourced:

| Task | Linux | Windows | macOS |
| --- | --- | --- | --- |
| Hash a file | `sha256sum` | `Get-FileHash`, `certutil -hashfile` | `shasum -a 256` |
| Read the security log | `journalctl`, `ausearch` | `Get-WinEvent` | `log show --predicate` |
| List local accounts | `/etc/passwd`, `getent` | `Get-LocalUser` | `dscl . -list /Users` |
| Inspect a certificate | `openssl x509 -text` | `Get-PfxCertificate`, `certutil` | `security find-certificate` |
| Full-disk encryption state | `cryptsetup status` | `Get-BitLockerVolume` | `fdesetup status` |
| Host firewall state | `nft list ruleset`, `firewall-cmd` | `Get-NetFirewallProfile` | `socketfilterfw --getglobalstate` |
| Code signature | `rpm -V`, `dpkg -V` | `Get-AuthenticodeSignature` | `codesign -dv`, `spctl -a` |
| Malware protection state | varies | `Get-MpComputerStatus` | `system_profiler SPConfigurationProfileDataType` |

**macOS ships LibreSSL, not OpenSSL.** `openssl version` on macOS 26.5.2 returns
LibreSSL 3.3.6, and several subcommands a Linux reader takes for granted behave
differently or are absent. That is the same shape as the `ifconfig` finding that
earned macOS its column on Network+: the exam's own named tool behaving opposite
to the habit the track otherwise teaches. It belongs in the cryptography topic
rather than in a footnote.

Scripts go one per topic in `blog/scripts/windows/` and `blog/scripts/macos/`,
joining the 30 PowerShell and 29 shell scripts already there, and are triggered
through `hostcap.sh`.

**A four-column table with nothing under it is already a build failure**, from
the Network+ pass: a topic carrying a host table owes a Windows and a macOS
capture or an exempt entry saying why. That test walks the Network+ directory
today and needs widening to this track, which is one line.

## Within-track scope drift

The Network+ rule carries over without amendment, because the failure it prevents
is one this track is more exposed to rather than less.

**Before writing topic N, check its row against what topic N-1 shipped, not
against what topic N-1's row promised.** If the next row asks for something
already taught, the row is stale and gets fixed before a word of the topic is
written. Fix the row, not the finished topic: the written page is the better
evidence of what a reader needs.

Where the split is not obvious, **split by direction rather than by subtopic**.
On this track the natural directions are choosing a control against operating
one, and reading evidence against producing it. Both are lines a writer can apply
to a sentence they have not written yet, which a list of subtopics is not.

The exposure is higher here because several objectives overlap each other rather
than only overlapping other tracks. Encryption appears in 1.4, 3.3 and 4.1.
Segmentation appears in 2.5, 3.3 and 4.1. Hardening appears in 2.5 and 4.1. The
plan assigns an owner for each and the row says so.

## Question design

The authoring standard in
[linux-plus-question-authoring-standard.md](linux-plus-question-authoring-standard.md)
applies, with amendments. The Network+ mistake was measuring the bank against the
exam after it was finished and then reframing 64 stems. These are baked in from
the first question, and each one is countable while writing rather than only at
the end.

**A person in the stem.** CompTIA's house style puts a technician, an analyst or
an administrator in almost every item. Six of 273 Network+ questions had one
before the fix. Target: the great majority, and count it per bank as you go.

**Named things as the options, not explanatory clauses.** Seventy-seven percent
of the Network+ bank offered four explanations. Those teach better and rehearse
the wrong skill, because the exam tests recognise and eliminate.

**Every distractor is a real control that is wrong for a nameable reason, and the
explanation names the reason.** This is the most important line in this section.
It follows directly from the thesis: if the topic already names the alternative
it rejected and what the rejection cost, the distractors are already written. An
item where three options are obviously not security controls teaches elimination,
which is the failure mode of a badly written Security+ question and the reason
most free banks for this exam are worthless.

**Situational coverage on the seven scenario objectives**, which are 2.4, 3.2,
4.1, 4.5, 4.6, 4.9 and 5.6. Counted while writing. Network+ drifted from 93
percent situational in the domain written last to as low as 7 percent in the ones
written first, and only counting found it.

**A multiple-response floor on the four Compare and contrast objectives**, which
are 1.1, 2.1, 3.1 and 3.3. That path is exercised by two of 276 Linux+ questions
and has thin coverage.

**A diagram-anchor requirement** for the visual objectives, with `learnAnchor`
resolving to a heading that holds a figure and a stem answerable only by having
read it. On this exam those are 1.1 the control grid, 1.2 Zero Trust and physical
security, 3.4 the recovery timeline, 4.3 the three scores, and 5.2 the risk
treatment quadrants.

**Performance-based questions are not reproduced.** Say so on the exam page. The
nearest honest thing, and Network+ has eleven of them, is handing over a real
capture from a topic and asking what it proves. The two build checks that keep
exhibits honest already exist: every line of an exhibit must appear in the topic
it claims to come from, and a slice may not run from the end of one capture into
the start of another.

**The input rule is unchanged and it is the one that actually matters.** Written
from the objectives document and primary documentation only. Never a braindump,
never anyone's memory of a real exam, nothing labelled real, actual or leaked.
The build enforces the labelling; the input rule is a discipline.

**Off-syllabus material takes no questions.** `beyondExam: true` puts a topic in
its own section outside the lesson numbering, and `quiz-validate.ts` fails the
build on a question that links to one. That is a build failure rather than a
convention, and the reason is that a question in the bank is a claim that the
thing is examinable.

## The legacy bank

`src/data/quizzes/security-plus/fundamentals.json` holds eight questions dated
7 August 2026, with ids `sp-001` upward, `domain` holding a display name rather
than an objective number, and no `learnRef`, `objective` or `difficulty`.

**It is not merely untidy, it is a build failure waiting for one line.**
`STRICT_TRACKS` in `quiz-validate.ts` is derived from `EXAM_FOR_TRACK`, so the
moment `security-plus` points at `sy0-701` the bank fails three checks at once:
missing metadata, a domain string that does not match the objective's domain, and
no backlink. That happens in the same commit that adds the exam, so it has to be
handled there.

**The decision: rewrite the eight, do not delete them.** They are good questions.
The compensating-control item and the certificate-pinning multiple-response item
are close to the shape this track wants before anybody touches them. Each one
moves into the domain bank it belongs in, takes an `sp-<domain>-NNN` id, gains
`objective`, `learnRef`, `learnAnchor` and `difficulty`, and `fundamentals.json`
goes away.

One consequence to handle in the same commit: `test/routes.test.mjs` uses
`security-plus/practice/fundamentals` as its worked example of the practice
engine and asserts on the id `sp-001`. Those four assertions repoint at a real
domain bank.

## What we are deliberately not building

Stated so it does not get relitigated.

- **A `/glossary` route.** Covered above, and refused once already at a smaller
  term count.
- **A CVSS calculator.** FIRST publishes one, it is free, it is authoritative,
  and the project already ruled the same way on subnetting generators and labs.
  Link to it and enforce the distractor rule instead.
- **A risk register or any tool with state.** No storage, no accounts, no
  backend. Unchanged from both existing tracks.
- **Any attack tooling, any sample malware, any scanning of anything this project
  does not own.** Covered by the attack-demonstration rule.
- **A threat-model builder or an interactive control matrix.** Same reasoning as
  the diagram generator: a primitive library costs more than the figures it
  would draw.
- **A separate compliance track.** ISO 27001, SOC 2 and the rest get exactly the
  treatment the exam asks for. A reader who wants the certification itself is
  reading the wrong page.
- **Mnemonics**, and no paragraph explaining why not.

## Decisions taken

| Question | Decision | Date |
| --- | --- | --- |
| Does the candidate thesis survive the objectives | Partly. It holds for 19 of 28 objectives and fails on 20.7 percent of the exam by weight, so it widens to cover choosing among explanations of evidence as well as among controls | 2026-08-21 |
| Prove it | Three forms unchanged. The arithmetic form takes five named families and carries more of this track than of Network+ | 2026-08-21 |
| Try it | Four forms. The new one is reading the reader's own machine, read-only, which replaces the topology form that does not transfer | 2026-08-21 |
| Cross-track duplication | Self-contained, with self-contained redefined by the question each track answers. Audit table above, forty topics | 2026-08-21 |
| Attack demonstrations | Capture the evidence, never the attack. Stated as a rule rather than resolved per topic | 2026-08-21 |
| Figure floor | Every lesson carries one, tested with a keyed exempt list. Both existing tracks already do this, so it enforces a convention rather than raising the bar | 2026-08-21 |
| Photographs | Required for the physical security and asset disposal topics, researched alongside sources rather than afterwards | 2026-08-21 |
| Glossary route | No. Terms live in the topic that teaches the idea, and the coverage check is a committed script that runs per block | 2026-08-21 |
| The acronym appendix | 241 of 334 entries name nothing in the objectives. Concept taught means the abbreviation appears once; otherwise nothing. The five collisions get real treatment | 2026-08-21 |
| Across platforms | Triggered by a named tool list, tested, with the exempt list itself tested | 2026-08-21 |
| Question shape | Six amendments, all counted while writing rather than measured at the end | 2026-08-21 |
| The legacy bank | Rewrite the eight into the domain banks and delete the file. It becomes a hard build failure the moment the exam entry lands | 2026-08-21 |
| Objective numbers in prose | Never. Frontmatter and question metadata only, because SY0-801 is coming and the remap should be three mechanical places | 2026-08-21 |

## Open questions

**Whether a netlab topology earns its place at all.** Network+ committed 27 of
them and this track has perhaps four topics that could use one: segmentation,
network access control, a screened subnet, and an on-path indicator produced from
static state. Three of those already have a Network+ topology. Worth checking
before block C whether any new topology is needed rather than assuming.

**Where the question-authoring amendments live.** The shared document is called
`linux-plus-question-authoring-standard.md` and now has two sets of per-track
amendments living in two other documents. The copyright, trademark and
prohibited-input sections genuinely are shared and must not drift into three
copies. This is the second track to raise it and the third would be too late.

**Whether the audit rule figure can be captured.** The `oscap` route produces
real benchmark results and a real `notapplicable`, which is the better teaching
moment. Whether a rule can be made to fail and then pass on the same container,
which is the shape the remediation section wants, is unproven and worth twenty
minutes before that topic is written.

**The syscall audit gap.** `auditctl` accepts a watch rule on the podman machine
and the rule lists, but no file-access record appeared in testing. The audit log
itself is full of real PAM records, so the topic has material either way. Whether
the file-watch demonstration is available needs proving before a topic promises
it.
