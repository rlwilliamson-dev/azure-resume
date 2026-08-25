# CompTIA Security+ track: the full topic plan

Every topic in the track, in reading order, with what each one has to teach and
what it depends on. Written for the same audience as the other two tracks:
somebody who has never held a security job, with experienced readers served by
`DEEPER` panels rather than by the main flow.

**76 topics plus an orientation page.** That is not a target. It is what covering
28 objectives and 743 bullet terms from zero takes, and it landing within one
page of both existing tracks is a coincidence rather than a design.

Companions: [security-plus-sy0-701-research.md](security-plus-sy0-701-research.md)
for what is on the exam,
[security-plus-teaching-design.md](security-plus-teaching-design.md) for how a
topic is written and what departs from the other two tracks, and
[linux-plus-question-authoring-standard.md](linux-plus-question-authoring-standard.md)
for the practice questions.

**Read the teaching design before this document.** It overrides the Linux+ and
Network+ design documents where they conflict, and the short version is that the
thesis is neither of theirs, Try it grows a fourth form, forty existing topics
overlap this material and the audit says what each Security+ page owes instead,
and no topic on this track runs an attack.

- [How to read this plan](#how-to-read-this-plan)
- [The topic template](#the-topic-template)
- [Across platforms](#across-platforms)
- [Balance check](#balance-check)
- [The orientation page](#the-orientation-page)
- [Block A. What security is for](#block-a-what-security-is-for)
- [Block B. Cryptography and trust](#block-b-cryptography-and-trust)
- [Block C. Threats, and what they leave behind](#block-c-threats-and-what-they-leave-behind)
- [Block D. Architecture and data](#block-d-architecture-and-data)
- [Block E. Security operations](#block-e-security-operations)
- [Block F. Governance, risk and compliance](#block-f-governance-risk-and-compliance)
- [Where the order came from](#where-the-order-came-from)
- [Objective coverage check](#objective-coverage-check)
- [Capture feasibility](#capture-feasibility)
- [Photographs to source](#photographs-to-source)
- [Question banks](#question-banks)
- [Infrastructure changes this track needs](#infrastructure-changes-this-track-needs)
- [Suggested authoring order](#suggested-authoring-order)

## How to read this plan

Numbers are reading order, not filenames. `order` in frontmatter is numbered in
tens and the displayed numbering is generated. `00` is the orientation page and
sits outside the lesson count.

**Zero hook** is the concrete thing the topic opens with, per the
concrete-before-abstract rule. A beginner should be able to picture it before any
terminology arrives. A topic with no plausible zero hook is scoped wrong.

**Deeper** is what goes behind the collapsible panels for experienced readers.
One panel per major body section, which is the floor the test enforces.

**Capture** says where the output comes from: `container` for `capture.sh
<distro>`, `vm` for the podman machine, `block` for real loop devices, `api` for a
live query against a public service run through `capture.sh --script`, `netlab`
for a namespace topology, `host` for the Windows and macOS runners, and `doc` for
output sourced from a standard or vendor documentation.

**Figure** names the argument the figure makes, never its subject. A row reading
"diagram: PKI" produces the generic version, which is the failure this column
exists to prevent. Every lesson carries at least one.

## The topic template

Fixed before the first topic is written, and not revisited. Same order as
Network+, because two templates quietly diverging around topic 60 cost seventeen
topics of reconciliation on Linux+.

| # | Section | Required |
| --- | --- | --- |
| 1 | **Before you read** | Yes. One question the reader cannot yet answer. |
| 2 | **Some words you will need** | Yes. A `dl.terms` list, carrying more weight here than on either other track. |
| 3 | **What breaks without this** | Yes. Consequence, not definition. |
| 4 | Body sections | Yes. Concrete first. At least two `details.predict` panels per topic, whether or not the topic captured anything: a question in the summary and the answer inside, captured output where there is captured output and reasoning where there is not. One `details.deeper` panel per major section. At least one figure. |
| 5 | **Across platforms** | Only where a triggering tool appears. See below. |
| 6 | **Prove it** | Yes. Run it, work it out, or look it up. |
| 7 | **What trips people up** | Yes. Three to six, each with real error text, real output, or the specific wrong decision. |
| 8 | **Work it through** | Yes. A scenario reasoned to a decision, with the rejected alternative named. |
| 9 | **Try it** | Yes. Optional for the reader, required in the topic. |
| 10 | **Check yourself** | Yes. `details.qa` blocks. |
| 11 | **References** | Yes. Every source, with the date it was checked. |

Three rules that go with it:

**Diagrams have no section.** An inline SVG goes inside the body section whose
argument it carries.

**A DEEPER panel belongs to the section above it.** A body section with nothing
worth putting behind a panel is usually still pitched too high for a beginner,
which is a signal to rewrite the section rather than skip the panel.

**The summary line at the foot states provenance.** Which blocks were captured, on
what, and which were sourced. On this track it also says where the evidence is
the observable half of something the topic did not run.

## Across platforms

The trigger list is in the [teaching design](security-plus-teaching-design.md#cross-platform-captures).
Columns are fixed at four, in the host-tool shape, because this exam has no
vendor CLI axis:

| Task | Linux | Windows | macOS |

The `COMPARE_META` entry for `security-plus` uses the heading "Across platforms"
and the slug `platforms`, matching Network+, so the shared component and the
comparison page work without change. The column pattern needs no new alternatives.

## Balance check

| Block | Topics | | Domain | Topics | Share | Exam weight |
| --- | --- | --- | --- | --- | --- | --- |
| A. What security is for | 5 | | 1.0 | 11 | 14.5% | 12% |
| B. Cryptography and trust | 5 | | 2.0 | 16 | 21.1% | 22% |
| C. Threats, and what they leave behind | 16 | | 3.0 | 13 | 17.1% | 18% |
| D. Architecture and data | 13 | | 4.0 | 22 | 28.9% | 28% |
| E. Security operations | 22 | | 5.0 | 14 | 18.4% | 20% |
| F. Governance, risk and compliance | 15 | | | | | |
| **Total** | **76** | | | **76** | | |

Four of the five domains land within 1.6 points of their weight. **Domain 1 runs
two and a half points over, and the whole of the excess is cryptography.** Objective
1.4 is 42 terms, the second-densest objective on the exam, and everything in
domains 3 and 4 that touches data protection, identity or certificates depends on
it. Teaching it once and thoroughly, early, is cheaper than teaching a third of it
five times. That is a deliberate choice rather than a drift, and it is the one
place this plan does not follow its own weighting rule.

The topics-per-domain column counts an objective's owner. Several topics declare
two objectives in `examObjectives`, which the coverage report handles.

## The orientation page

`00 start-here` sits outside the lesson count and outside the blocks. It is order
10 in frontmatter; lesson 01 is order 20.

It carries what the other two orientation pages carry, plus four things specific
to this exam. **The pass mark is 750 on a scale of 100 to 900**, and the scaled
score on this site is a linear approximation because CompTIA publishes no scaling
function. **The reading order is not CompTIA's numbering** and the page says why,
because a large share of readers arrive from a video course that follows the
numbering exactly. **There are no performance-based questions here**, and the
nearest honest thing is the eleven-style items that hand over a real capture and
ask what it proves. And **the certification page names CompTIA Network+ as
recommended experience**, which for a reader of this site is a track that already
exists.

## Block A. What security is for

Five topics. A reader arrives able to name a firewall and unable to say what
category of control it is, which is the exact gap objective 1.1 tests. This block
builds the vocabulary the whole exam is written in, and it ends with two physical
subjects so that the abstractions have objects attached before block B leaves the
building.

| # | Slug | Level | Obj | Zero hook | Must teach | Deeper | Capture | Figure |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 01 | `what-security-actually-protects` | intro | 1.2 | Three things went wrong last week. A laptop was stolen, an invoice was altered by one digit, and the payroll system was down for a day. Only one of them looks like a security incident | Confidentiality, integrity and availability as three separate properties that trade against each other; non-repudiation and why it needs a key only one party holds; authentication, authorization and accounting as three distinct questions; authenticating people against authenticating systems; authorization models named; gap analysis as the thing you do before choosing anything | Why availability is a security property and not an operations one; where the triad came from and what it leaves out; the AAA in this exam against the AAA in a RADIUS configuration | container | One incident drawn three times against the three properties, with the same control fixing it in one column and doing nothing in the other two |
| 02 | `control-categories-and-control-types` | intro | 1.1 | A locked door, a policy that says lock the door, a camera watching the door, and a sign saying the door is watched. Four controls, one door | The four categories, technical, managerial, operational and physical; the six types, preventive, deterrent, detective, corrective, compensating and directive; that the two axes are independent, which is why "is a firewall preventive" is the wrong question; a compensating control as the answer to a control you cannot deploy, with the residual gap named | Why a control can occupy two cells and what that does to an exam item; the empty cells and what they tell you; how CompTIA's four categories relate to the control families in a real catalogue | doc | The 4 by 6 grid with a real control in each populated cell and the empty cells left empty |
| 03 | `zero-trust` | working | 1.2 | The contractor's laptop is on the office network, so it can reach the finance server. Nobody decided that. It followed from where the cable went | Trust moving from the location to the request; the control plane with its policy engine, policy administrator, adaptive identity, threat scope reduction and policy-driven access control; the data plane with its implicit trust zones, subject and system, and policy enforcement point; that the decision point is not on the data path | Why the engine and the administrator are separate components; what an implicit trust zone actually is and why the name is a warning; where zero trust does not reach | doc | One request crossing the enforcement point, with the engine and administrator drawn off the data path and the decision travelling back as a token |
| 04 | `physical-security` | intro | 1.2 | The building has a card reader on the front door and a fire exit that props open in summer | Bollards, access control vestibules, fencing, video surveillance, security guards, access badges and lighting, each with what it actually stops; the four sensor types and the physics each one detects; tailgating as the attack every one of these is really about | Why a vestibule is the only control on the list that stops tailgating; what a camera is for, given it stops nothing; sensor false-positive modes and what makes each one fire | doc | The four sensor types against what each one physically detects, with the failure each one is blind to |
| 05 | `deception-and-disruption` | working | 1.2 | A file called `passwords_final.xlsx` that nobody has any reason to open, sitting on a share where everybody can see it | Honeypot, honeynet, honeyfile and honeytoken as four different things; that three of the four are records rather than machines; deception as a detection control with almost no false positives; what a honeypot costs you when it is compromised | Why the alert from a honeyfile is worth more than a hundred alerts from an IDS; legal and safety limits on running one; disruption technology against deception technology | container | The same alert from an IDS and from a honeyfile, with the base rate that makes one of them worth reading |

## Block B. Cryptography and trust

Five topics. Objective 1.4 is 42 terms and it is the largest single dependency on
the exam: data protection, identity, secure protocols and the whole certificate
half of domain 3 assume it. Everything here has a capture, which makes it the
right block to prove the toolchain on.

**Ownership note, in bold because this is where scope drift will happen.**
Block B owns the cryptographic decision. It does not own the TLS handshake, which
is Network+ topic 34's and is linked at the foot. It does not own `cryptsetup`
mechanics, which are Linux+ topic 49's. Topic 34 in this track owns what you
encrypt and where; block B owns which primitive and why.

| # | Slug | Level | Obj | Zero hook | Must teach | Deeper | Capture | Figure |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 06 | `hashing-salting-and-what-a-digest-proves` | intro | 1.4 | Two users pick the same password. The database stores two different strings, and neither of them is the password | Hashing as one-way and why that is the point; what a digest proves and what it does not; salting, and the rainbow table it defeats; key stretching and the work factor as a tunable defence; collisions in one sentence, with the attack deferred to block C | Why a fast hash is the wrong tool for a password and the right one for a download; how a work factor is chosen against hardware you do not control; what changes when the attacker has the salt, which they do | container, host | Two identical passwords, two different digests, and one rainbow table failing against both, with the real salts and digests in the drawing |
| 07 | `symmetric-asymmetric-and-the-key-exchange` | working | 1.4 | Two people who have never met need a shared secret, over a wire that everybody can read | Symmetric encryption and what it is good at; asymmetric encryption and what it is good at; why every real system uses both; key exchange as the problem asymmetric solves; key length and what it buys against what it costs; algorithms named without a taxonomy | Why key length does not compare across families; forward secrecy in one paragraph; what post-quantum changes and what it does not | container, host | One key pair used twice in opposite directions, encrypting on one side and signing on the other, with the real key fingerprints on it |
| 08 | `where-the-key-lives` | working | 1.4 | The disk is encrypted. The key is in a file on the same disk | TPM, HSM, key management system and secure enclave as four answers to one question; key escrow and who holds the second copy; root of trust and what it anchors; what an attacker who owns the operating system gets in each case | Why a TPM is not a safe and what sealing actually means; when escrow is a control and when it is a back door; the cost and operational burden of an HSM | container, host | The same key held four ways, with what an attacker who owns the OS reads in each |
| 09 | `certificates-and-what-they-bind` | working | 1.4 | Your browser trusts about a hundred and fifty organisations you have never heard of, and you did not pick any of them | What a certificate binds and what signs the binding; the certificate authority model and what you are actually trusting; self-signed against third-party, and when self-signed is the right answer; CSR generation and what goes in it; wildcard against subject alternative name; root of trust as a chain | What a CA actually validates before issuing; why the trust store is the real attack surface; certificate transparency, and reading every certificate ever issued for a name | container, api, host | Real fields from a captured certificate with an arrow showing which field each link in the chain signs |
| 10 | `revocation-and-the-answer-that-never-comes` | working | 1.4 | The certificate was revoked this morning. Your browser has not noticed | CRL, OCSP and OCSP stapling as three answers to one question; what each costs in latency and privacy; soft-fail, and what a client concludes when no answer arrives; why revocation is the weakest part of the model | Why OCSP leaks your browsing to the CA and stapling does not; short-lived certificates as the alternative to revocation; what happens to a revoked certificate already in a cache | container, api | Client, CA and server drawn as who asks whom, with the client's conclusion under each of the three mechanisms and under no answer at all |

## Block C. Threats, and what they leave behind

Sixteen topics, the second-largest block and the one where the thesis does its
other half. Nothing here is a control to choose. Everything here is evidence to
read, so every topic ends in what the evidence rules out as well as what it
suggests.

**No topic in this block runs an attack.** The rule is in the teaching design and
each topic's provenance line says which half was captured.

| # | Slug | Level | Obj | Zero hook | Must teach | Deeper | Capture | Figure |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 11 | `threat-actors-and-what-they-want` | intro | 2.1 | Two intrusions, identical technique, and the right response to each is completely different | Nation-state, unskilled attacker, hacktivist, insider threat, organised crime and shadow IT; the attributes that distinguish them, internal or external, resources and funding, level of sophistication; the motivations list, and that motivation predicts what happens next; shadow IT as the actor nobody calls an actor | Why attribution is hard and why it still changes your response; how sophistication and resources come apart; the insider who is not malicious | doc | The six actors placed on resources against sophistication, with the motivation that dominates each and the one pair the axes cannot separate |
| 12 | `how-a-message-becomes-a-vector` | intro | 2.2 | An invoice arrives as a PDF from a supplier you actually use, with the right reference number on it | Message-based vectors: email, SMS and instant messaging; image-based and file-based; voice call; removable device; why the delivery mechanism is a separate question from the payload | What makes an image a vector; why a removable device still works in 2026; the vector nobody blocks because blocking it stops the business | doc | One payload delivered five ways, with the control that stops each and the one that stops none of them |
| 13 | `the-surfaces-you-did-not-mean-to-expose` | working | 2.2 | A port is open on a server because a contractor needed it for an afternoon in 2019 | Vulnerable software, and client-based against agentless; unsupported systems and applications; unsecure networks, wireless, wired and Bluetooth; open service ports; default credentials; supply chain as a vector, through managed service providers, vendors and suppliers | Why agentless scanning misses what agent-based finds and the reverse; what unsupported actually means for risk; how a supplier becomes your attack surface | container, netlab | The estate drawn as an attack surface that grows by accretion, with the date each opening was added |
| 14 | `social-engineering` | intro | 2.2 | The message is from your finance director, it uses their turn of phrase, and it is urgent | Phishing, vishing and smishing as one technique on three channels; business email compromise and pretexting; impersonation and brand impersonation; watering hole; typosquatting; misinformation and disinformation; why the technical controls are the wrong place to look | Why urgency is the payload; what makes a pretext work; the reason awareness training keeps being funded and keeps not working | api | The same request delivered by four channels with the verification step that defeats all four, drawn once |
| 15 | `vulnerabilities-in-software` | working | 2.3 | A field accepts eighty characters. The developer allocated sixty-four | Memory injection and buffer overflow; race conditions, with time-of-check and time-of-use as the specific case; malicious update; operating-system-based vulnerabilities; web-based, with SQL injection and cross-site scripting; that all of these are one idea, which is trusting input | Why the bounds check is where the bug is, not where the crash is; the check-then-use gap drawn on a timeline; why the same class of bug survives fifty years of being written about | container | Two processes on one timeline with the gap between the check and the use, and the moment the file changes hands |
| 16 | `vulnerabilities-in-the-platform` | working | 2.3 | The virtual machine is isolated. It shares a CPU cache with forty others | Hardware vulnerabilities, firmware, end-of-life and legacy; virtualization, virtual machine escape and resource reuse; cloud-specific vulnerabilities; mobile device vulnerabilities, side loading and jailbreaking | Why resource reuse is a confidentiality problem and not a performance one; what end-of-life does to your risk register overnight; the firmware nobody has an inventory of | vm | The shared-substrate stack with the boundary each vulnerability class crosses, and the one boundary the tenant controls |
| 17 | `misconfiguration-and-the-supply-chain` | working | 2.3 | The storage bucket was public for four days and nothing in the logs says so | Misconfiguration as the largest real-world category and the one with no CVE; cryptographic vulnerabilities as a category; supply chain, split into service provider, hardware provider and software provider; why a dependency you never chose is still yours | The default that is insecure and the default that is merely surprising; how a software provider becomes an attacker without being compromised; where in a build a supply chain compromise would be caught | container | One dependency update reaching production, with every point it could have been caught and the ones that were not looking |
| 18 | `zero-day-and-the-window-before-the-patch` | working | 2.3 | The patch came out on a Tuesday. The exploit came out on the Thursday before | Zero-day as a specific claim about knowledge rather than a severity; the lifecycle from discovery to disclosure to patch to exploitation to remediation; why the window is not the same for you as for the vendor; what you can actually do about a zero-day, which is mostly not patching | Coordinated disclosure and the clock it runs; why "zero-day" is used for three different things in marketing; what defence in depth is actually for, which is this | api | One real CVE's timeline drawn to scale from discovery to patch to exploitation, with the window you were exposed marked |
| 19 | `malware` | intro | 2.4 | The finance share is full of files that will not open, and there is a text file in every folder | Ransomware, trojan, worm, spyware, bloatware, virus, keylogger, logic bomb and rootkit, each by what distinguishes it rather than by a definition; that the categories overlap and one sample is often four of them; what each one leaves behind | Why the virus-against-worm distinction survives when nothing else does; where a rootkit hides and why detection has to come from outside; bloatware as a real risk rather than an annoyance | api | The nine categories placed by what they need from the user and what they do once running, with the overlaps shown rather than hidden |
| 20 | `physical-and-network-attacks` | working | 2.4 | The card reader logged an entry from a badge whose owner is in another country | Physical: brute force, RFID cloning, environmental; network: distributed denial of service, amplified and reflected, DNS attacks, wireless, on-path, credential replay, malicious code | Why an amplified attack needs a service that answers bigger than it is asked; what an on-path position actually gives you and what it does not; why credential replay survives encryption | netlab, api | An amplification factor drawn to scale from one real query and its real response, with the ratio on it |
| 21 | `application-and-cryptographic-attacks` | working | 2.4 | The application logs show a request for a filename with a lot of dots in it | Injection, buffer overflow, replay, privilege escalation, forgery and directory traversal; downgrade, collision and birthday as attacks on cryptography rather than on code; that a cryptographic attack usually attacks the negotiation rather than the primitive | Why the birthday bound is the square root and what that costs; downgrade as a protocol design failure; forgery against replay, which are not the same | container | The negotiation drawn twice, once agreeing on the strong option and once on the weak one, with the message that made the difference |
| 22 | `password-attacks` | working | 2.4 | Sixty accounts, one password attempt each, once an hour. No lockout fires | Spraying against brute force, and why the first defeats lockout; the arithmetic of entropy in bits and what one more bit buys; measured hash rates against key stretching; what makes a password policy work and what makes it theatre | Why length beats complexity arithmetically; what a leaked-password list does to entropy estimates; the lockout threshold that helps the attacker | container | Entropy in bits against time to exhaust at a measured hash rate, with the crossover where length stops mattering |
| 23 | `the-nine-indicators` | working | 2.4 | The account is locked. Nobody tried to log in | Account lockout, concurrent session usage, blocked content, impossible travel, resource consumption, resource inaccessibility, out-of-cycle logging, published or documented, and missing logs; that each one has an innocent explanation and the job is to rule it out; missing logs as the indicator people never treat as one | Why impossible travel produces false positives at scale and how to keep it useful; the difference between out-of-cycle and unexpected; what a gap in a log actually proves | vm, host | Three log sources on one time axis, one incident, and the single identifier that ties them together |
| 24 | `segmentation-isolation-and-access-control` | working | 2.5 | The payment system and the vending machine are on the same network, and one of them is easier to reach | Segmentation as a mitigation and as an audit-scope decision; access control and access control lists; permissions; application allow lists; isolation; least privilege as a design position rather than a setting | Why an allow list is harder to run and better than a block list; where segmentation stops helping; the jump host that quietly reconnects two segments | netlab | One intrusion crossing four controls, three of which fail, with the point where the segment stops it |
| 25 | `patching-encryption-monitoring-and-configuration-enforcement` | working | 2.5 | The configuration was correct in January. Nobody changed it, and it is wrong now | Patching as a mitigation with a cost; encryption as a mitigation and what it does not mitigate; monitoring as a mitigation that prevents nothing; configuration enforcement and drift; decommissioning as the mitigation everybody skips | Why drift happens without anybody changing anything; the patch that breaks the application, and the decision that follows; what a decommissioned system still holds | container | Configuration drift over a year with no change events on it, and the enforcement run that closes the gap |
| 26 | `hardening-techniques` | working | 2.5 | A fresh install listens on eleven ports and you asked for one service | Endpoint protection installation; host-based firewall; host-based intrusion prevention; disabling ports and protocols; default password changes; removal of unnecessary software; the order to do them in and what each one costs in support | Why removing software beats blocking it; the port that has to stay open and how you constrain it instead; HIPS against endpoint protection, which overlap | container, host | Listening services before and after, with the attack surface counted rather than described |

## Block D. Architecture and data

Thirteen topics. Comparisons between designs, which only mean something once a
reader has met the things being compared, then the data those designs exist to
protect, then what happens when it all fails.

| # | Slug | Level | Obj | Zero hook | Must teach | Deeper | Capture | Figure |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 27 | `cloud-as-a-security-decision` | working | 3.1 | The provider patches the hypervisor. Nobody patched the operating system, because everybody assumed the provider did | Cloud as an architecture model; the shared responsibility matrix and where the line moves; hybrid considerations; third-party vendors; infrastructure as code; serverless; microservices; what each one moves off your plate and what it moves on | Why the responsibility line moves per service model and not per provider; what serverless does to your logging; microservices and the east-west traffic nobody inspects | doc | The responsibility boundary drawn across four service models, with one control landing on a different side each time |
| 28 | `on-premises-virtualised-and-air-gapped` | working | 3.1 | The air-gapped network has a USB port | On-premises as a choice rather than a legacy; centralised against decentralised; containerization and virtualization as different isolation strengths; software-defined networking; physical isolation and air gaps; logical segmentation | What an air gap actually costs to maintain; container isolation against VM isolation, honestly; SDN's control plane as a new single point of failure | vm | The isolation strength of four boundaries drawn against what has to fail for each to be crossed |
| 29 | `the-systems-you-cannot-patch` | working | 3.1 | The controller runs the production line. Its last firmware update was in 2011 and the vendor is gone | Industrial control systems and SCADA; real-time operating systems; embedded systems; IoT; why availability outranks confidentiality here and what that does to every other decision; inability to patch as a permanent condition rather than a backlog | Why a safety system cannot take a reboot; compensating controls as the only available answer; what a real-time constraint does to encryption | doc | The same vulnerability on a server and on a controller, with the four available responses and the three that are unavailable on one side |
| 30 | `comparing-architectures` | working | 3.1 | Two designs, both correct, and the one you pick is decided by something nobody wrote down | The considerations list as a scoring frame: availability, resilience, cost, responsiveness, scalability, ease of deployment, risk transference, ease of recovery, patch availability, inability to patch, power and compute; that risk transference is a real answer and not an evasion | Why ease of recovery and resilience are different columns; the requirement that decides it, and how to find it; what the scoring frame hides | doc | One requirement scored across four architecture models, with the column that decides it and the columns that turn out not to matter |
| 31 | `where-you-put-the-device` | working | 3.2 | The intrusion prevention system failed at three in the morning. Nobody noticed, because everything kept working | Device placement and security zones; attack surface; connectivity; failure modes, fail-open against fail-closed, and that this is a decision somebody makes; device attributes, active against passive, inline against tap or monitor | Why fail-open is sometimes right and what it costs; a tap that cannot block against an inline device that can fail; where the sensor sees encrypted traffic and what it does then | netlab | The same device inline and on a tap, with what each one sees and what each one can do about it |
| 32 | `the-appliances-and-what-each-one-reads` | working | 3.2 | Four boxes in a row, and only one of them can see the URL | Jump server; proxy server; IDS and IPS; load balancer; sensors; port security and 802.1X with EAP; firewall types, web application firewall, unified threat management, next-generation firewall, and layer 4 against layer 7 | How far into the packet each device reads and what that costs in throughput; why a WAF is not a firewall; what 802.1X actually authenticates | netlab, doc | Each appliance drawn against how far into the frame it reads, with the field that decides its verdict highlighted |
| 33 | `secure-communication-and-access` | working | 3.2 | The contractor needs one server. The VPN gives them the whole network | Virtual private networks and remote access; tunnelling; TLS and IPsec as two answers at two layers; software-defined wide area networking; secure access service edge; selection of effective controls as the objective's own closing phrase | Split tunnel against full tunnel and what each leaks; why SASE is a delivery model rather than a technology; the VPN that is the wrong tool for the job | netlab, host | The contractor's request drawn through a VPN and through a per-application broker, with what each one exposes |
| 34 | `what-you-encrypt-and-where` | working | 3.3, 1.4 | The database is encrypted. The backup of it is not | Data at rest, in transit and in use; encryption levels, full disk, partition, volume, file, database and record; transport and communication encryption; that each level protects against a different attacker; data in use as the one with almost no answer | Why full-disk encryption does nothing against a running machine; what record-level encryption costs in query performance; confidential computing in one paragraph | block, host | One record drawn at six encryption levels, with what an attacker at each level of access still reads |
| 35 | `what-the-data-is` | intro | 3.3 | Two spreadsheets. One is a lunch order and one is a payroll run, and the file server treats them identically | Data types: regulated, trade secret, intellectual property, legal information, financial information; human-readable and non-human-readable; classifications: sensitive, confidential, public, restricted, private and critical; that classification is what makes every later control decidable | Why classification schemes differ between organisations and what stays constant; the cost of over-classifying; who actually decides, which is the owner and not security | doc | One record classified by two schemes with the controls each one implies, and the row where they disagree |
| 36 | `tokenisation-masking-and-obfuscation` | working | 3.3, 1.4 | The support tool shows the last four digits. The database behind it holds all sixteen | Masking, tokenization, obfuscation and steganography as different promises; hashing as a data protection method; segmentation and permission restrictions as the non-cryptographic answers; what an attacker who steals the store gets in each case | Why tokenization removes data from scope and encryption does not; format-preserving encryption in one paragraph; masking that can be reversed by joining two tables | container | The same record four ways, with what an attacker who steals the store reads in each |
| 37 | `data-sovereignty-and-geographic-restrictions` | working | 3.3 | The backup replicated to the nearest region, which is in another country | Data sovereignty; geolocation; geographic restrictions as a control; where data leaks across a border, which is replication, caching and backup rather than placement; why this is a network and storage decision at once | Why the mechanism that leaks is always one added for resilience or speed; transit through a jurisdiction against storage in it; what a cloud region actually guarantees | api | One dataset's real footprint drawn across regions, with the three copies nobody placed on purpose |
| 38 | `high-availability-power-and-sites` | working | 3.4 | The failover worked. Both sites were in the path of the same storm | High availability, load balancing against clustering; site considerations, hot, warm and cold; geographic dispersion; platform diversity; multi-cloud; continuity of operations; power, generators and uninterruptible supplies | Why load balancing and clustering solve different problems; the correlated failure that geographic dispersion is for; what a UPS is actually sized for | doc | Three site types against recovery time and cost, drawn to scale, with the correlated failure that defeats two of them |
| 39 | `backups-recovery-and-testing-the-plan` | working | 3.4 | The backups ran every night for two years. The first restore was during the incident | Backups, onsite and offsite, frequency, encryption, snapshots, replication and journaling; recovery; capacity planning across people, technology and infrastructure; testing, tabletop exercises, failover, simulation and parallel processing; that an untested backup is a belief | Why replication is not a backup; what journaling protects that a snapshot does not; the capacity planning nobody does, which is people | container, block | Full, incremental and differential over a fortnight, with the restore chain each one needs and what one missing tape costs |

## Block E. Security operations

Twenty-two topics, the largest block and the one with almost all the captured
output. This is 28 percent of the exam and four of its seven scenario objectives.

| # | Slug | Level | Obj | Zero hook | Must teach | Deeper | Capture | Figure |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 40 | `secure-baselines` | working | 4.1 | Two servers built from the same image, eight months apart, and they no longer match | Establishing, deploying and maintaining a baseline as three separate jobs; benchmarks as a starting point rather than an answer; hardening targets across mobile devices, workstations, switches, routers, cloud infrastructure, servers, ICS and SCADA, embedded systems, RTOS, IoT and wireless devices; what a benchmark says about a machine it was not written for | Why a benchmark profile can be inapplicable rather than failed; the rule you turn off and the exception you record; what maintaining a baseline costs per year | container | A real benchmark run with pass, fail and notapplicable counts, and the rules that are inapplicable for a reason worth knowing |
| 41 | `mobile-devices-and-who-owns-them` | working | 4.1 | The phone has the company mail on it. It also has the owner's photographs, and one wipe removes both | Mobile device management; deployment models, bring your own device, corporate-owned personally enabled, choose your own device; connection methods, cellular, Wi-Fi and Bluetooth; what each ownership model can and cannot enforce | Why BYOD is a legal question before it is a technical one; containerisation on a phone; the enforcement that stops at the operating system version | host | The three ownership models against what the organisation can enforce, wipe and see on each |
| 42 | `wireless-security-settings` | working | 4.1 | The guest network password is on a card at reception and it has not changed in three years | Site surveys and heat maps; wireless security settings; WPA3 and what changed; AAA and RADIUS; cryptographic protocols against authentication protocols, which are two different choices; pre-shared key against enterprise | Why WPA3's handshake fixes the offline attack and what it does not fix; what RADIUS actually carries; the guest network that reaches the finance server | doc | The same association drawn under a pre-shared key and under enterprise, with what an attacker who captures the handshake gets in each |
| 43 | `application-security` | working | 4.1 | The form rejects a name with an apostrophe. It accepts one with a semicolon | Input validation as the control almost everything else in block C reduces to; secure cookies; static code analysis against dynamic; code signing; sandboxing; monitoring; where in the pipeline each of these runs | Why validation belongs on the server and what client-side validation is for; what a signature proves about code and what it does not; sandboxing that a determined process leaves | container, host | The pipeline with each control at the point it runs, and the one defect class each one cannot see |
| 44 | `asset-management-from-purchase-to-destruction` | intro | 4.2 | The laptop was returned when the contractor left. It was reissued last week with the old disk in it | Acquisition and procurement; assignment, accounting and ownership; classification; monitoring and asset tracking; inventory and enumeration; disposal and decommissioning; sanitization, destruction and certification; data retention; why the inventory is the control everything else depends on | Why you cannot protect what you cannot enumerate; sanitization against destruction, and when a certificate is required; the retention schedule that conflicts with the deletion request | container | The asset lifecycle with the data on it at each stage, and the two stages where it leaves your control |
| 45 | `finding-vulnerabilities` | working | 4.3 | The scanner found four thousand findings on a network of two hundred machines | Vulnerability scans; static and dynamic application analysis; package monitoring; threat feeds, open-source intelligence, proprietary and third-party feeds, information-sharing organisations, the dark web; penetration testing; responsible disclosure and bug bounty programmes; system and process audits | What a credentialed scan sees that an uncredentialed one does not; why a feed is only as good as the enrichment; the finding count that means the scanner is misconfigured | api, container | Six discovery methods against what each one can and cannot see, with the same real vulnerability found by two of them and missed by four |
| 46 | `three-numbers-and-what-each-one-answers` | working | 4.3 | The scanner says 9.8. The vendor says it has never been exploited. Both are true | CVSS and what a base score measures; CVE as an identifier rather than a score; EPSS as a probability of exploitation; the KEV catalogue as an observation rather than a prediction; exposure factor, environmental variables, industry and organisational impact; risk tolerance; false positives and false negatives; prioritisation as the actual job | Reading a CVSS vector string field by field; why environmental metrics exist and why nobody sets them; what a percentile means and what it does not | api | One real CVE scored three ways, with the question each number answers written under it |
| 47 | `what-you-do-about-a-vulnerability` | working | 4.3 | The patch exists. Applying it takes the production line down for six hours | Patching; insurance; segmentation; compensating controls; exceptions and exemptions and the difference; validation of remediation, rescanning, audit and verification; reporting; that doing nothing is a decision somebody has to sign | Why an exception has an owner and a date or it is not an exception; what validation actually has to prove; the report that changes behaviour against the one that files | container, api | The same finding under five responses with the residual risk drawn each time, and the one that leaves the most |
| 48 | `what-to-monitor-and-what-to-do-when-it-fires` | working | 4.4 | The alert fired four hundred times last month. Somebody wrote a rule to hide it | Monitoring systems, applications and infrastructure; log aggregation, alerting, scanning, reporting and archiving; alert response and remediation, validation, quarantine; alert tuning and what a tuned-out alert costs | Why alert fatigue is a design failure rather than a staffing one; what to archive and for how long; the tuning that removes the only true positive | vm, container | One alert's life from fire to disposition, with the four places it can be silenced and what each silence hides |
| 49 | `the-monitoring-tools` | working | 4.4 | Four tools all claim to detect the same thing, and only one of them saw it | SCAP and benchmarks; agents against agentless; security information and event management; antivirus; data loss prevention; SNMP traps; NetFlow; vulnerability scanners; what each tool sees and what it is blind to | Why a SIEM's value is added at the parse; NetFlow against full packet capture, honestly; the agent that cannot be installed on the thing you most need to watch | container, api | One real syslog line at each stage from raw to parsed to enriched to correlated to alert, with the value added at each step |
| 50 | `filtering-at-the-edge` | working | 4.5 | The rule that allows it is on line four hundred. The rule that denies it is on line three | Firewall rules, access lists, ports and protocols; screened subnets; IDS and IPS, trends and signatures; web filters, agent-based and centralised proxy, URL scanning, content categorisation, block rules and reputation | Why rule order is the whole of a firewall; signature against anomaly, and what each misses; the categorisation that blocks the thing the business runs on | netlab | A packet walking a rule list to the rule that decides it, with the shadowed rule that never fires |
| 51 | `securing-the-operating-system-and-the-protocols` | working | 4.5 | The application supports both. Nobody changed the default, and the default is the old one | Operating system security, Group Policy and SELinux as two answers to one question; implementation of secure protocols, protocol selection, port selection and transport method; DNS filtering; email security with SPF, DKIM and DMARC, and the gateway | Why the insecure protocol is still enabled and what breaks when you remove it; what DMARC's policy field actually instructs; SELinux against Group Policy as enforcement models | container, api, host | One domain's real SPF, DKIM and DMARC records with what each one asserts and the gap between them |
| 52 | `watching-the-endpoint-and-the-data` | working | 4.5 | The file left on a USB stick. The firewall logs are clean, and they always would have been | File integrity monitoring; data loss prevention; network access control; endpoint detection and response and extended detection and response; user behaviour analytics; that each of these exists because a network control cannot see it | Why EDR sees what antivirus cannot; DLP that stops the honest mistake and not the determined leak; what a behaviour baseline needs before it is useful | container, vm | The same exfiltration attempted four ways, with the one control that sees each and the path that no network control sees |
| 53 | `accounts-from-joiner-to-leaver` | working | 4.6 | The contractor left in March. The account still works, and it has more access than it did on day one | Provisioning and de-provisioning; permission assignments and their implications; identity proofing; attestation as the periodic re-justification; privilege creep as what happens without it; the joiner, mover and leaver path | Why the mover is harder than the leaver; what identity proofing actually verifies; attestation that gets rubber-stamped and how to tell | container, host | One account's permissions over three role changes, with the ones that were added and the ones that were never removed |
| 54 | `federation-and-single-sign-on` | working | 4.6 | You log in to one system and get access to eleven. None of them ever saw your password | Federation and what is actually being asserted; single sign-on; LDAP, OAuth and SAML as three different things doing three different jobs; interoperability; the trust relationship that makes it work and what breaks when it is abused | Why OAuth is authorisation and OpenID Connect is authentication; what a signed assertion contains; the identity provider as a single point of compromise | container | The same browser redirect chain under SAML and under OIDC, with the token and the trust anchor that differ |
| 55 | `the-six-access-control-models` | working | 4.6 | The same request, six schemes, and four different answers | Mandatory, discretionary, role-based, rule-based and attribute-based access control; time-of-day restrictions; least privilege; which model each real system actually implements; why the names are close and the behaviours are not | Why role-based scales and attribute-based expresses; the discretionary model's failure mode, which is everybody; where mandatory access control is actually used | container, host | One request evaluated by all six models side by side, with the two that disagree and why |
| 56 | `factors-and-multifactor-authentication` | working | 4.6 | Two passwords is not two factors | The four factors, something you know, have, are and somewhere you are; multifactor implementations, biometrics, hard and soft tokens, security keys; why a text message is a weak second factor and still better than none; what a security key does that a code does not | Why phishing resistance is the property that matters; biometric error rates and the threshold that trades them; the recovery flow that undoes the whole thing | container, host | A time-based code's shared secret, time step and drift window on a clock axis, with real computed codes |
| 57 | `passwords-and-privileged-access` | working | 4.6 | The administrator account password is in a document called `passwords.docx` | Password best practices, length, complexity, reuse, expiration and age; password managers; passwordless; privileged access management tools, just-in-time permissions, password vaulting and ephemeral credentials; what the current guidance actually says about expiry | Why forced expiry made passwords worse and what replaced the advice; what just-in-time actually removes; the break-glass account and how it is controlled | container, host | The standing-privilege model against just-in-time, with the window an attacker has in each drawn to scale |
| 58 | `automating-the-boring-and-dangerous-parts` | working | 4.7 | Forty new starters in one week, each needing eleven accounts | Use cases: user and resource provisioning, guard rails, security groups, ticket creation, escalation, enabling and disabling services and access, continuous integration and testing, integrations and application programming interfaces; that automation makes a decision repeatable, including a wrong one | Why a guard rail is a control and a policy is not; the API key that automates more than intended; what continuous testing catches that a gate does not | container | One provisioning request automated end to end, with the approval that stayed manual and why |
| 59 | `what-automation-costs` | working | 4.7 | The script that provisions accounts has been running for two years. The person who wrote it left | Benefits: efficiency, enforcing baselines, standard infrastructure configurations, scaling securely, employee retention, reaction time, workforce multiplier; other considerations: complexity, cost, single point of failure, technical debt and ongoing supportability; that this objective names the costs explicitly, which almost none of them do | When not to automate; the automation that becomes the only way to do the thing; technical debt with a security label on it | doc | Manual effort against automated effort over three years, with the maintenance line that crosses back over |
| 60 | `the-incident-response-process` | working | 4.8 | The alert fired at two in the morning. The first question is not what happened | Preparation, detection, analysis, containment, eradication, recovery and lessons learned; training; testing with tabletop exercises and simulation; root cause analysis; threat hunting as the proactive counterpart; why containment comes before eradication and what it costs | Why the tabletop finds the gap the plan does not; eradication that removes the evidence; the lesson that gets written and not implemented | doc | The seven phases against the clock, with the decision at each boundary and the one that cannot be reversed |
| 61 | `digital-forensics` | working | 4.8 | The server was rebooted to get it working again. It worked | Legal hold; chain of custody; acquisition and the order of volatility; preservation; reporting; e-discovery; why the first response often destroys the evidence; what makes evidence admissible against merely useful | Why memory goes first and what is in it; the hash taken at acquisition and what it is for; what a legal hold does to your retention schedule | vm, container | The volatility stack with real measured lifetimes against each layer, and the reboot that clears four of them |

## Block F. Governance, risk and compliance

Fifteen topics, and the block with the least to run. Twenty percent of the exam
plus change management. Every topic here uses the look-it-up or work-it-out form
of Prove it and says so.

| # | Slug | Level | Obj | Zero hook | Must teach | Deeper | Capture | Figure |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 62 | `change-management-as-a-security-control` | working | 1.3 | The outage started at 14:02. The change that caused it was approved, tested and documented | Business processes impacting security operation; the approval process, ownership and stakeholders; impact analysis, test results, backout plan and maintenance window; standard operating procedures; technical implications, allow and deny lists, restricted activities, downtime, service and application restarts, legacy applications and dependencies; documentation, updating diagrams and policies, version control | Why the backout plan is the part that is skipped; the emergency change and what it is allowed to skip; dependencies nobody mapped until the restart | container | One change drawn from request to backout, with the four points where it can be stopped and the one where it cannot |
| 63 | `policies-standards-procedures-and-guidelines` | intro | 5.1 | Four documents say something about passwords, and only one of them is binding | The hierarchy and what each level is for; acceptable use, information security, business continuity, disaster recovery, incident response, software development lifecycle and change management policies; standards for password, access control, physical security and encryption; procedures including onboarding and offboarding and playbooks; guidelines and why they are not rules | Why a guideline that reads like a rule causes audit findings; the policy nobody can comply with; who signs each level | doc | One real requirement traced from policy to standard to procedure to guideline, with what changes at each level |
| 64 | `who-decides-and-who-owns` | working | 5.1 | The data belongs to finance. The server belongs to infrastructure. The breach belongs to nobody | Governance structures, boards, committees, government entities, centralised against decentralised; roles and responsibilities for systems and data, owners, controllers, processors and custodians or stewards; that the controller and processor split is a legal one with consequences | Why the owner is a business role and not a technical one; what a steward actually does; the committee that cannot make a decision | doc | One dataset with four roles attached, and the decision each role can and cannot make |
| 65 | `the-rules-that-come-from-outside` | working | 5.1 | You are not in that country. Your customers are | External considerations, regulatory, legal, industry, local or regional, national and global; monitoring and revision as an ongoing obligation; why obligations attach by whose data it is rather than by where you are | Why industry requirements bind through contracts rather than law; the regulation that changed and the review that did not happen; conflicting obligations in two jurisdictions | doc | Three obligations against one system, with the strictest requirement in each column and the conflict that has no resolution |
| 66 | `finding-and-sizing-a-risk` | working | 5.2 | Everybody agrees it is a high risk. Nobody agrees what high means | Risk identification; risk assessment, ad hoc, recurring, one-time and continuous; risk analysis, qualitative against quantitative; probability and likelihood; exposure factor; impact; that qualitative scales are consistent within an organisation and meaningless between them | Why the five-by-five matrix hides more than it shows; what continuous assessment actually requires; the risk that is invisible to both methods | doc | The same risk scored qualitatively and quantitatively, with the decision each supports and the one they disagree on |
| 67 | `the-arithmetic-of-risk` | working | 5.2 | The control costs 40,000 a year. The loss it prevents costs 30,000 a year | Single loss expectancy from asset value and exposure factor; annualised rate of occurrence; annualised loss expectancy; the control cost comparison and the crossover; why the arithmetic is easy and the inputs are not; what happens to the answer when the rate is a guess | Where the numbers actually come from; sensitivity, and how much the answer moves when one input doubles; why a low-frequency high-impact risk breaks the model | container | Annualised loss against annual control cost, with the crossover marked and the input that moves it most |
| 68 | `deciding-what-to-do-about-it` | working | 5.2 | The risk was accepted in 2023 by somebody who has left | Risk register, key risk indicators, risk owners, threshold, tolerance and appetite, expansionary, conservative and neutral; strategies, transfer, accept, avoid and mitigate; exemption against exception; risk reporting; residual risk as the thing that is always left | Why accepting a risk needs a named owner and a date; transfer that does not transfer the consequence; the register that is a graveyard | doc | The same risk under four treatments with the residual drawn each time, and the one treatment that leaves the most |
| 69 | `business-impact-analysis` | working | 5.2 | The recovery plan targets four hours. The last backup was eleven hours before the failure | Business impact analysis; recovery time objective and recovery point objective as two independent numbers measured in opposite directions; mean time to repair; mean time between failures; reading all four off one outage timeline; why the objectives are chosen and the metrics are measured | Why RPO is a backup frequency decision and RTO is a restore capability one; MTTR against MTBF and what availability is computed from; the objective nobody has tested | doc | One outage timeline to scale with the last backup, the failure and the restore, and the four numbers read off it |
| 70 | `assessing-a-third-party` | working | 5.3 | Your supplier had a breach. Your customers do not care whose fault it was | Vendor assessment; penetration testing of a supplier; right-to-audit clause; evidence of internal audits; independent assessments; supply chain analysis; vendor selection; due diligence; conflict of interest; questionnaires; rules of engagement; vendor monitoring as ongoing rather than at signature | Why the questionnaire is the weakest instrument and the most used; what a right-to-audit clause is worth if never exercised; the fourth party nobody assessed | doc | The assessment methods ranked by what each actually verifies, against the effort each one costs |
| 71 | `the-agreements-and-what-each-one-binds` | working | 5.3 | The service level agreement promises 99.9 percent. Nothing in it says what happens if they miss | Service-level agreement, memorandum of agreement, memorandum of understanding, master service agreement, work order and statement of work, non-disclosure agreement, business partners agreement; which are binding and which are not; what each one is actually for | Why an MOU is not enforceable and is still worth signing; the SLA credit that is smaller than the outage; what a statement of work does that a master agreement cannot | doc | The seven agreement types placed by whether they bind and what they define, with the two that are commonly confused |
| 72 | `compliance-and-what-non-compliance-costs` | working | 5.4 | The finding was closed by writing a policy. The configuration never changed | Compliance reporting, internal and external; consequences of non-compliance, fines, sanctions, reputational damage, loss of licence, contractual impacts; compliance monitoring; due diligence and due care; attestation and acknowledgement; automation in compliance monitoring | Why loss of licence outranks the fine; due diligence against due care, which are not synonyms; the attestation that somebody signed without reading | container | The four consequences drawn against how quickly each one arrives and how long each one lasts |
| 73 | `privacy` | working | 5.4 | The customer asked you to delete their data. The backups keep it for seven years | Legal implications, local or regional, national and global; the data subject; controller against processor and what each is responsible for; ownership; data inventory and retention; the right to be forgotten and what it collides with | Why the controller and processor split decides who gets fined; the deletion request against the retention obligation; what an inventory has to record to answer either | doc | One deletion request traced through every copy of the data, with the two copies that cannot be deleted and why |
| 74 | `audits-and-assessments` | working | 5.5 | The internal audit found nothing. The external audit found eleven things | Attestation; internal audits, compliance, audit committee and self-assessments; external audits, regulatory, examinations, assessment and independent third-party audit; what each one is for and who it is for; why independence is the whole value | Why a self-assessment is worth doing and worth nothing as evidence; what an audit committee is for; the examination that is not an audit | doc | The audit types placed by independence against authority, with what each one's output is worth to whom |
| 75 | `penetration-testing` | working | 5.5 | The test found a way in through a system that was not in scope | Physical, offensive, defensive and integrated testing; known, partially known and unknown environments; reconnaissance, passive against active; rules of engagement as the document that matters most; why a penetration test is not a vulnerability scan | Why an unknown-environment test costs more and finds less; the finding that was out of scope and is still real; what a red team exercise measures that a penetration test does not | api | Three knowledge levels against what each test finds and what each one costs, with the finding that only one of them reaches |
| 76 | `security-awareness` | working | 5.6 | Ninety-four percent passed the phishing test. The other six percent are the whole problem | Phishing campaigns, recognising an attempt, responding to reported suspicious messages; anomalous behaviour recognition, risky, unexpected and unintentional; user guidance and training, policies and handbooks, situational awareness, insider threat, password management, removable media and cables, social engineering, operational security, hybrid and remote work; reporting and monitoring, initial and recurring; development and execution | Why the click rate is the wrong metric and the report rate is the right one; training that creates blame and what it costs in reporting; the unintentional insider | doc | Click rate against report rate over four campaigns, with the point where one improves and the other does not |

## Where the order came from

The exam's own numbering is not a reading order and following it produces two
specific problems. Change management arrives at 1.3, before a reader has seen a
control operating or knows what a backout plan is protecting. And cryptography
arrives at 1.4, immediately after the vocabulary topics, which is right, but the
numbering then leaves it unused for two whole domains.

The ordering rule is the one Network+ settled on: **a summary comes after its
components, an abstraction comes after the behaviour it names, and an instrument
comes before the reading it produces.** Applied here it produces five changes
worth recording.

**Cryptography moves up and stays together.** Five consecutive topics rather than
one, before threats, because block C's cryptographic attacks, block D's data
protection and block E's certificates, federation and code signing all assume it.

**Change management moves to block F.** Objective 1.3 is a governance process
that happens to be numbered in domain 1. Read next to policy, risk and audit it
makes sense immediately; read third it is a list of stages with nothing attached.
The topic keeps its 1.3 frontmatter, so coverage is unaffected.

**Physical security and deception stay in block A rather than moving to domain 3
or 4.** They are objective 1.2, they are objects rather than abstractions, and
putting two concrete topics at the end of the most abstract block is what stops
that block reading like a definition list.

**Indicators come after attacks, not with them.** Objective 2.4 mixes the two.
Splitting the nine indicators into their own topic, after the four attack
families, means a reader meets the evidence knowing what could have produced it,
which is the direction the exam asks the question in.

**Identity is one run of five topics rather than being split by mechanism.**
Accounts, federation, access control models, factors and privileged access read
as one argument about who gets to do what, and objective 4.6 is 41 terms with
plenty of ways to fragment it.

**Nothing in this plan references a topic by position.** Prose refers to other
topics by number. Names appear only in cross-track see-also links, where the
name is doing real work. That rule cost Network+ six broken link texts before it
was adopted.

## Objective coverage check

Every objective, and the topics that carry it. This is the table the generated
coverage report reproduces from frontmatter once the topics exist.

| Obj | Topics | Terms |
| --- | --- | --- |
| 1.1 | 02 | 12 |
| 1.2 | 01, 03, 04, 05 | 36 |
| 1.3 | 62 | 21 |
| 1.4 | 06, 07, 08, 09, 10, 34, 36 | 42 |
| 2.1 | 11 | 22 |
| 2.2 | 12, 13, 14 | 32 |
| 2.3 | 15, 16, 17, 18 | 29 |
| 2.4 | 19, 20, 21, 22, 23 | 47 |
| 2.5 | 24, 25, 26 | 20 |
| 3.1 | 27, 28, 29, 30 | 35 |
| 3.2 | 31, 32, 33 | 34 |
| 3.3 | 34, 35, 36, 37 | 30 |
| 3.4 | 38, 39 | 30 |
| 4.1 | 40, 41, 42, 43 | 41 |
| 4.2 | 44 | 12 |
| 4.3 | 45, 46, 47 | 38 |
| 4.4 | 48, 49 | 23 |
| 4.5 | 50, 51, 52 | 33 |
| 4.6 | 53, 54, 55, 56, 57 | 41 |
| 4.7 | 58, 59 | 24 |
| 4.8 | 60, 61 | 21 |
| 4.9 | 23, 48, 49, 61 | 13 |
| 5.1 | 63, 64, 65 | 36 |
| 5.2 | 66, 67, 68, 69 | 38 |
| 5.3 | 70, 71 | 20 |
| 5.4 | 72, 73 | 24 |
| 5.5 | 74, 75 | 21 |
| 5.6 | 76 | 22 |

**Objective 4.9 has no topic of its own, and that is deliberate.** It is thirteen
terms, all of them log sources, and a page listing seven kinds of log is the
definition-list failure this track exists to avoid. Instead it is declared by the
four topics that actually read logs: 23 correlates three sources onto one
timeline, 48 follows one alert from fire to disposition, 49 walks a real line
through a parsing pipeline, and 61 handles acquisition and the order of
volatility. Between them every named source appears in real captured output.
**If the term-level check finds a gap there, it gets its own topic**, and that
check runs at the end of block E rather than at the end of the track.

Three objectives carry one topic each: 1.1, 2.1 and 4.2. All three are
single-subject objectives where splitting would produce two thin pages.

**Two topics declare objective 1.4 alongside a domain 3 objective**, 34 and 36,
because encryption levels and the obfuscation family are printed under both. That
is CompTIA's overlap rather than this plan's, and declaring both is how the
coverage report stays honest about it.

## Capture feasibility

| Route | Topics |
| --- | --- |
| **container** (`capture.sh <distro>`) | 01, 05, 06, 07, 08, 09, 10, 13, 15, 17, 21, 22, 25, 26, 36, 39, 40, 43, 44, 45, 47, 48, 49, 51, 52, 53, 54, 55, 56, 57, 58, 61, 62, 67, 72 |
| **api** (public service via `capture.sh --script`) | 09, 10, 14, 18, 19, 20, 37, 45, 46, 47, 49, 51, 75 |
| **vm** (`capture.sh vm`) | 16, 23, 28, 48, 52, 61 |
| **block** (`capture.sh --block N`) | 34, 39 |
| **netlab** (namespace topology) | 13, 20, 24, 31, 32, 33, 50 |
| **host** (Windows and macOS runners) | 06, 07, 08, 09, 23, 26, 33, 34, 41, 43, 51, 53, 55, 56, 57 |
| **doc** (sourced) | 02, 03, 04, 11, 12, 27, 29, 30, 32, 35, 38, 42, 59, 60, 63, 64, 65, 66, 68, 69, 70, 71, 73, 74, 76 |

**Fifty-one of 76 topics carry real captured output**, which is a higher share
than the pre-work predicted and comes almost entirely from two places: objective
1.4 runs end to end, and the public vulnerability and certificate services are
queryable without an account.

**Twenty-five topics are documented only**, and they cluster exactly where the
research said they would. Eleven of the twenty-five are block F. The rest are
architecture comparisons, physical security, and the two topics about actors and
motivations. Each says so in its provenance line rather than dressing a
hand-written block as a capture.

### The public services, and the terms of use

Every `api` capture is a query against a service that publishes the data for
that purpose, with no account and no scraping. Verified working on 2026-08-21:

| Service | What it gives a topic |
| --- | --- |
| NVD CVE API 2.0 | One CVE's full record including the CVSS vector string, for topic 46 |
| FIRST EPSS API | The same CVE's exploitation probability and percentile, dated |
| CISA Known Exploited Vulnerabilities catalogue | Whether it has actually been exploited, and when it was added |
| MITRE ATT&CK STIX bundle | Technique identifiers for topics 19 and 20, at 54 MB, so queried rather than stored |
| crt.sh | Every certificate ever issued for a name, for topics 09 and 10 |
| Public DNS, for SPF, DKIM, DMARC and DNSSEC records | Topic 51's email authentication, and topic 37's footprint |
| `curl -I` for security headers | Topic 43 |

**Nothing scans, probes, enumerates or tests anything this project does not own.**
Where a topic wants the outside view of a host, the host is one of this
project's own.

### Routes proven before the plan was written

Five were unproven when this work started. All five were tested on 2026-08-21 and
two of them changed a row in the tables above.

| Route | Result |
| --- | --- |
| `oscap` with the SCAP Security Guide | Works. Real profile list, real per-rule pass, fail and notapplicable. Topic 40's figure is built on it |
| `cryptsetup` under `--block 1` | Works. Real LUKS2 header with real salts and PBKDF parameters. Topic 34 |
| `lynis` | Works, and needs `procps` installed through `--script` or every process test errors |
| `aide` | Installs and reports version. Not needed, because Linux+ topic 50 owns file integrity mechanics and topic 52 owns the decision |
| `auditd` under `--privileged` | **Fails.** The audit netlink socket refuses a container regardless of privilege |
| `auditd` on the `vm` target | Works for status and for reading a log full of real PAM records. A syscall watch rule listed but produced no records, so topics 23 and 61 use the log rather than promising a watch |
| crt.sh | **Works**, against a 502 in the pre-work. Topics 09 and 10 depend on it |

## Photographs to source

Researched at the same time as the sources for each topic, not afterwards. The
licence rule is absolute: a licence that permits display, a local file under
`src/content/learn/security-plus/images/`, an entry in `images/credits.json`, and
a visible credit in References.

| Topic | Objects |
| --- | --- |
| 04 physical security | Bollards, an access control vestibule, a badge reader, a security camera with its field of view visible, and each of the four sensor types where a licensed image exists |
| 08 where the key lives | A hardware security module, and a TPM on a board |
| 44 asset management | An asset tag, a degausser, and a physically destroyed drive |
| 56 factors | A security key, and a hardware token |

The sensors are the interesting case and the reason this table exists. Infrared,
pressure, microwave and ultrasonic are four bullets that look identical on a page
and four completely different objects in a corridor.

## Question banks

Five banks, one per domain, in `src/data/quizzes/security-plus/`. Ids are
`sp-<domain>-NNN`, following the `np-` and `lp-` convention.

| Bank | Weight | Weighted share | Pool target |
| --- | --- | --- | --- |
| `domain-1-general-security-concepts.json` | 12% | 11 | 33 |
| `domain-2-threats-vulnerabilities-and-mitigations.json` | 22% | 20 | 60 |
| `domain-3-security-architecture.json` | 18% | 16 | 48 |
| `domain-4-security-operations.json` | 28% | 25 | 75 |
| `domain-5-security-program-management-and-oversight.json` | 20% | 18 | 54 |
| **Total** | | **90** | **270** |

**The five weighted shares total exactly 90**, so `weightedShares` has nothing to
reconcile on this exam and the largest-remainder path is never exercised. That is
worth knowing rather than relying on: the helper still runs.

The six amendments to the authoring standard are in the
[teaching design](security-plus-teaching-design.md#question-design) and every one
of them is counted while writing rather than measured at the end, which is the
specific mistake Network+ made and paid for with 64 reframed stems.

**The legacy bank goes.** `fundamentals.json` becomes a hard build failure the
moment `security-plus` points at an exam, because `STRICT_TRACKS` derives from
`EXAM_FOR_TRACK`. Its eight questions are rewritten into the domain banks with
new ids and full metadata, and four assertions in `test/routes.test.mjs` repoint
at a real bank. All of that happens in the commit that adds the exam entry.

## Infrastructure changes this track needs

Smaller than the Network+ list, because Network+ did the generalisation work.

| Change | Why | Risk |
| --- | --- | --- |
| Add `sy0-701` to `src/config/exams.ts` and point `security-plus` at it in `EXAM_FOR_TRACK` | Everything derives from it: coverage, plan, exam, question validation | Low, and **watch the 750 pass mark**. Both existing exams are 720 and copying an entry gets it wrong silently |
| Rewrite the `security-plus` entry in `src/config/tracks.ts` | The description predates both real tracks and describes a track organised by exam domain, which this one is not | None |
| Add a `security-plus` entry to `COMPARE_META` | Gives the track its `/learn/security-plus/platforms` page. Heading "Across platforms", same column pattern as Network+ | None. The component is already extracted |
| Fix or remove `src/data/quizzes/security-plus/fundamentals.json` | Becomes a build failure in the same commit as the exam entry | Medium if missed, because it fails the build rather than warning |
| Repoint four assertions in `test/routes.test.mjs` | They use `practice/fundamentals` and the id `sp-001` as the worked example of the practice engine | Low, and it must happen in the same commit |
| Widen `test/platforms.test.mjs` to walk `security-plus` | Four of its describes hardcode the Network+ directory: the trigger check, the host-table check, the deeper panel floor and the exempt-list check | Low, mechanical, and it should happen before the first topic rather than after twenty |
| Add a per-topic figure floor test | The one-figure-per-lesson rule is otherwise a preference. Same shape and same file as the predict and deeper floors, with a keyed exempt list that is itself tested | Low, and it is what makes the ask real |
| Commit a term-coverage script | 743 terms is too many to check once at the end. Takes an objective or a block, reports terms with no match in the track | Low. The Network+ pass was a throwaway; this one is committed and run per block |
| Add `security-plus` to the predict panel walk | That test already walks both existing tracks by name | Trivial |

## Suggested authoring order

Not reading order. This front-loads the decisions that are expensive to revisit
and gets the coverage route building early.

1. **Exam entry, track entry, compare metadata, the legacy bank, and the empty
   content directory.** One commit. The coverage route starts working and the
   build stays green, which it will not if the bank is left for later.
2. **The test changes**: widen the platform and predict walks, add the figure
   floor with an empty exempt list, commit the term-coverage script. Doing this
   before any topic exists means the first topic is written against the rules
   rather than audited against them at topic twenty.
3. **Two topics as the pattern, then stop and review.** Recommend **09
   certificates and what they bind** and **68 deciding what to do about it**: one
   from objective 1.4 with heavy captured output across three platforms and a
   live public service, and one from domain 5 with nothing to run at all. Those
   are the two extremes the template has to survive, and they are not adjacent.
4. **Review those two together** before writing a third.
5. **Block B**, the rest of it, while the capture tooling is fresh and because
   five later blocks depend on it.
6. **Block A**, which sets the voice and is the easiest block to write badly.
7. **Block E**, the largest and the most captured.
8. **Block C**, which references block E's tooling constantly.
9. **Blocks D and F.**
10. **Question banks**, per domain, after that domain's topics exist so `learnRef`
    and `learnAnchor` land on real headings.
11. **The term-level pass**, per block as you go, and again at the end.
12. **The verification pass.** Every claim executed or checked against upstream,
    every citation fetched, and the CDN checked once more for the SY0-801
    objectives.

Step 12 is not a formality. The equivalent pass found eleven errors on Linux+ and
seven on Network+, in finished and reviewed content, and every one of the eighteen
was the same two shapes: the right idea stated a notch wider than it should have
been, or a version out of date.
