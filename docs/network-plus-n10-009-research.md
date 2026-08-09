# CompTIA Network+ N10-009: what is actually on the exam

What the current Network+ exam is, taken from CompTIA's own released objectives
document rather than from anybody's summary of it. Companion to
[network-plus-topic-plan.md](network-plus-topic-plan.md), which covers what to do
about it.

Research date: 2026-08-09. Every URL in [Sources](#sources) was checked for a 200
response on that date.

- [Why this document exists](#why-this-document-exists)
- [The exam, confirmed](#the-exam-confirmed)
- [Is N10-009 still the current exam](#is-n10-009-still-the-current-exam)
- [Domains and weights](#domains-and-weights)
- [The twenty-five objectives](#the-twenty-five-objectives)
- [What the primary document says that summaries do not](#what-the-primary-document-says-that-summaries-do-not)
- [The acronym list](#the-acronym-list)
- [What N10-009 dropped](#what-n10-009-dropped)
- [Four errors inside CompTIA's own material](#four-errors-inside-comptias-own-material)
- [Where output can come from](#where-output-can-come-from)
- [What cannot be captured](#what-cannot-be-captured)
- [Copyright and what this repo reproduces](#copyright-and-what-this-repo-reproduces)
- [Sources](#sources)

## Why this document exists

On the Linux+ track, reading CompTIA's released objectives changed the scope in
three ways no third-party summary mentioned. AppArmor turned out not to be on the
exam at all. OpenTofu was named where Terraform was not. The acronym list carried
twenty-two terms that appear nowhere in the objectives text.

So this one started with the primary document and nothing else. It was worth it
again: the same three shapes turned up, plus a numerical error in CompTIA's own
blog post about their own exam.

## The exam, confirmed

Taken from the objectives document and from CompTIA's certification page.

| | |
| --- | --- |
| Code | N10-009, also labelled V9 |
| Objectives document | Version 4.0, copyright 2023, print code 10461-May2023 |
| Launched | 20 June 2024 |
| Questions | Maximum of 90, multiple-choice and performance-based |
| Time | 90 minutes |
| Passing score | 720 on a scale of 100 to 900 |
| Languages | English, German, Japanese, Portuguese, Spanish |
| Recommended experience | "A minimum of 9–12 months of experience in the IT networking field" |
| Valid for | Three years |
| Renewal | 30 CEUs |
| Estimated retirement | 2027, per CompTIA's own page |

Two of those differ from Linux+ and are easy to copy across by accident. **Linux+
wants 12 months of experience and 50 CEUs; Network+ wants 9 to 12 months and 30.**
The orientation page has to say the Network+ numbers.

The passing score is not on the objectives document. It is on the certification
page, and the scale behaves the same way it does for Linux+: 720 out of 900 is not
80 percent, because the scale starts at 100, and CompTIA does not publish the
mapping from raw answers onto it.

## Is N10-009 still the current exam

Yes, and it needed checking, because CompTIA has a successor in progress.

CompTIA's exam-objectives-under-development page lists **"DRAFT CompTIA Network+
V10 Exam Objectives"** alongside drafts for DataSys+ V2, Security+ V8, SecOT+ V1,
Server+ V6, and Cloud+ V5. The Network+ V10 entry carries **no exam code and no
launch date**. The certification page still presents N10-009 as the exam you sit,
and gives an estimated retirement of 2027.

So the track targets N10-009. The thing worth writing down is the shape of the
transition rather than the date: CompTIA published the Linux+ XK0-006 objectives
as a draft well before launch, and the Linux+ track was written against that
draft. If a Network+ V10 draft appears with a code attached, the exam entry in
`src/config/exams.ts` is the only structural thing that has to change, because
every route derives from it.

## Domains and weights

From the objectives document, which is the version to trust. See
[the errors section](#four-errors-inside-comptias-own-material) for why that
qualifier is there.

| Domain | Weight |
| --- | --- |
| 5.0 Network Troubleshooting | 24% |
| 1.0 Networking Concepts | 23% |
| 2.0 Network Implementation | 20% |
| 3.0 Network Operations | 19% |
| 4.0 Network Security | 14% |

Sorted by weight rather than by number, because that ordering is the one that
should decide where the writing goes.

**Troubleshooting is the largest domain on this exam.** Not joint largest, not
nearly largest. It outweighs Networking Concepts, and it outweighs Network
Security by ten points. Almost every study resource on the market opens with the
OSI model and closes with a troubleshooting chapter, which is exactly backwards
from where the marks are.

**Security is 14 percent and has three objectives.** On Linux+ security was 18
percent across six objectives. A reader coming from that track will expect more
security than this exam wants, and the plan has to resist giving it to them.

The five weights total 100 exactly.

## The twenty-five objectives

CompTIA's numbering and CompTIA's own objective statements. The sub-bullet content
under each one is copyrighted and is deliberately not reproduced here or anywhere
else in this repository; see
[copyright](#copyright-and-what-this-repo-reproduces).

### 1.0 Networking Concepts, 23%

| | |
| --- | --- |
| 1.1 | Explain concepts related to the Open Systems Interconnection (OSI) reference model. |
| 1.2 | Compare and contrast networking appliances, applications, and functions. |
| 1.3 | Summarize cloud concepts and connectivity options. |
| 1.4 | Explain common networking ports, protocols, services, and traffic types. |
| 1.5 | Compare and contrast transmission media and transceivers. |
| 1.6 | Compare and contrast network topologies, architectures, and types. |
| 1.7 | Given a scenario, use appropriate IPv4 network addressing. |
| 1.8 | Summarize evolving use cases for modern network environments. |

### 2.0 Network Implementation, 20%

| | |
| --- | --- |
| 2.1 | Explain characteristics of routing technologies. |
| 2.2 | Given a scenario, configure switching technologies and features. |
| 2.3 | Given a scenario, select and configure wireless devices and technologies. |
| 2.4 | Explain important factors of physical installations. |

### 3.0 Network Operations, 19%

| | |
| --- | --- |
| 3.1 | Explain the purpose of organizational processes and procedures. |
| 3.2 | Given a scenario, use network monitoring technologies. |
| 3.3 | Explain disaster recovery (DR) concepts. |
| 3.4 | Given a scenario, implement IPv4 and IPv6 network services. |
| 3.5 | Compare and contrast network access and management methods. |

### 4.0 Network Security, 14%

| | |
| --- | --- |
| 4.1 | Explain the importance of basic network security concepts. |
| 4.2 | Summarize various types of attacks and their impact to the network. |
| 4.3 | Given a scenario, apply network security features, defense techniques, and solutions. |

### 5.0 Network Troubleshooting, 24%

| | |
| --- | --- |
| 5.1 | Explain the troubleshooting methodology. |
| 5.2 | Given a scenario, troubleshoot common cabling and physical interface issues. |
| 5.3 | Given a scenario, troubleshoot common issues with network services. |
| 5.4 | Given a scenario, troubleshoot common performance issues. |
| 5.5 | Given a scenario, use the appropriate tool or protocol to solve networking issues. |

Twenty-five objectives against Linux+'s twenty-nine, but each one is broader.
Objective 4.1 alone spans encryption, certificates, identity, physical security,
deception, risk vocabulary, regulatory compliance, and segmentation. It is the
largest single objective on either exam.

## What the primary document says that summaries do not

Eleven findings, each one checked against the document rather than inferred.

**Ten of the twelve command-line tools an experienced Linux engineer would reach
for are absent, and two deprecated ones are named.** Objective 5.5 names its
command-line tools explicitly. `netstat` is on the list. `ifconfig` is on the
list. **`ss` is not on the list, and neither is `mtr`, `nc`, `curl`, or
`iperf`.** For anyone who has internalised the Linux+ line that `ip` and `ss`
replaced `ifconfig` and `netstat`, this is a genuine trap: the exam names the
deprecated tool because the exam is not a Linux exam and `netstat` is still what
Windows ships. A topic has to teach the named tool first and the modern
replacement second, which is the opposite of the ordering on the other track.

**Wireshark is never named. Nmap is.** The document says "protocol analyzer" as a
category and then names Nmap directly as a product. Writing a topic around
Wireshark's interface would be writing around a product CompTIA declined to name;
writing one around Nmap is following the document.

**No 802.11 letter standards appear anywhere.** Objective 1.5 refers to 802.11
standards as a category. No a, b, g, n, ac, ax, or be appears in the document, and
neither does any Wi-Fi generation number. The same is true of 802.3: named as a
category, never enumerated. **802.11h is the single exception**, named
specifically under objective 2.3 for regulatory impact, which is an unusually
narrow thing for CompTIA to call out and is the sort of detail that gets skipped
by material working from a summary.

**No PoE standard numbers.** Objective 5.2 covers power budget and incorrect
standard as failure modes, and 802.3af, 802.3at, and 802.3bt appear nowhere. The
concept is examinable; the numbers are the author's choice to include.

**WEP is gone, and so is the original WPA.** Objective 2.3 names WPA2 and WPA3
only. Bare WPA appears in the acronym list and never in the objectives text, and
WEP is absent from the entire document, acronym list included. TKIP was in the
N10-008 acronym list and is not in this one. A topic that spends a page on WEP's
weaknesses is teaching history, not the exam.

**No first hop redundancy protocol is named.** Objective 2.1 names FHRP as a
concept. HSRP, VRRP, and GLBP appear nowhere in the document. VRRP was in the
N10-008 acronym list and has been dropped. The examinable thing is what an FHRP is
for, not which vendor's version you configure.

**Three dynamic routing protocols are named and two familiar ones are not.**
Objective 2.1 names BGP, EIGRP, and OSPF. **RIP and IS-IS appear in the acronym
list and nowhere in the objectives text.** This is the AppArmor finding again,
almost exactly: a term the reader will meet in every other study guide, present in
CompTIA's own acronym appendix, and absent from the thing that describes what is
tested.

**Spanning tree is named once as a feature and once as a fault, and no variant is
named.** RSTP is in the acronym list only. MSTP, PVST, BPDU, root guard, portfast,
and EtherChannel appear nowhere. Objective 5.3 does name root bridge selection,
port roles, and port states, so the mechanism is examinable in detail even though
no protocol variant is.

**The legacy WAN vocabulary is gone.** MPLS, Frame Relay, ATM, SONET, T1, and DSL
appear nowhere in the document. MPLS was in the N10-008 acronym list. Material
written against the older exam still spends chapters here.

**Flow data is a category, not a product.** Objective 3.2 says flow data. NetFlow,
sFlow, and IPFIX are absent. SNMP versions are named as v2c and v3, and the string
"SNMPv3" never appears, which matters for question wording.

**Screened subnet has replaced DMZ.** Objective 4.3 names screened subnet. DMZ
appears nowhere in the document. That is a deliberate terminology migration
CompTIA has been making across exams, and a question is far more likely to use
their term than the one everybody says out loud.

## The acronym list

The document carries an acronym appendix of 162 entries, and instructs candidates
to "attain a working knowledge of all listed acronyms".

**Twenty-three of them never appear in the objectives text.**

| Acronym | Spelled out |
| --- | --- |
| AUP | Acceptable Use Policy |
| CAM | Content-addressable Memory |
| CLI | Command-line Interface |
| CPU | Central Processing Unit |
| DAS | Direct-attached Storage |
| DLP | Data Loss Prevention |
| EAPoL | Extensible Authentication Protocol over LAN |
| EULA | End User License Agreement |
| IS-IS | Intermediate System to Intermediate System |
| LACP | Link Aggregation Control Protocol |
| LAN | Local Area Network |
| MDIX | Medium Dependent Interface Crossover |
| NIC | Network Interface Cards |
| RFID | Radio Frequency Identifier |
| RIP | Routing Information Protocol |
| RSTP | Rapid Spanning Tree Protocol |
| SOA | Start of Authority |
| TACAS+ | Terminal Access Controller Access Control System Plus |
| USB | Universal Serial Bus |
| UTM | Unified Threat Management |
| VoIP | Voice over IP |
| WPA | Wi-Fi Protected Access |
| WPS | Wi-Fi Protected Setup |

Twenty-three against Linux+'s twenty-two, from a document with a third more
acronyms in it. The pattern holds across both exams, which suggests the appendix
is maintained separately from the objectives and drifts.

Some of these are harmless. CPU, USB, and LAN are vocabulary a reader arrives
with. The ones that change what gets written are **IS-IS, RIP, RSTP, LACP,
EAPoL, CAM, MDIX, SOA, UTM, DLP, and WPS**: eleven real technologies that a
candidate is told to know and that the objectives never ask about. The plan gives
each of them a sentence in the topic where it belongs and no more than that. A
sentence is what "working knowledge of the acronym" costs; a section is what
writing from the appendix instead of the objectives costs.

Two entries in that table are worth reading twice. **CAM** is the forwarding table
inside a switch, so its absence from the objectives text is odd given MAC flooding
is named as an attack. **SOA** is a DNS record type, and objective 3.4 enumerates
record types without including it.

The traffic also runs the other way. **TLS is used in the objectives text and is
not in the acronym list**, which is a small thing until you notice the list does
contain SSL.

## What N10-009 dropped

Comparing the two acronym appendices is the cheapest way to see the shape of the
revision, so both documents were pulled and diffed.

N10-008 listed 101 acronyms. N10-009 lists 162. Beyond the additions CompTIA
advertises, **thirty-eight entries left**, and the interesting ones cluster:

- **Legacy WAN**: MPLS, and with it the whole circuit-era vocabulary.
- **Optical and physical detail**: MT-RJ, WDM, UPC, OTDR, TIA/EIA, RG.
- **Wireless radio detail**: MIMO, MU-MIMO, RSSI, WAP, WLAN.
- **Protocols**: POP3, RTSP, VNC, SRV, TKIP, VRRP.
- **Storage and platform**: RAID, SSD, VM.
- **Paperwork**: MOU, NDA, SOHO.

**POP3 and IMAP deserve their own line.** Neither appears anywhere in N10-009,
objectives or appendix, and the ports table does not list 110 or 143. Mail
retrieval has left this exam. Every port chart on the internet still has both.

Physical-layer tooling shrank the same way. The hardware tools objective 5.5 names
are a short list, and **OTDR, punchdown tool, crimper, multimeter, loopback plug,
and fusion splicer are all absent**, all of which N10-008 candidates were expected
to know.

## Four errors inside CompTIA's own material

Worth recording, because three of them will show up in a question one day and the
fourth is the argument for reading primary documents.

**1. CompTIA's blog gives weights that do not add up.** The post comparing N10-008
and N10-009 lists the new domains as Networking Concepts 23, Network
Implementations 19, Network Operations 19, Network Security 14, Network
Troubleshooting 24. That totals 99. The objectives document and the certification
page both give Network Implementation as 20 percent, which totals 100. The
objectives document is right and the blog post is wrong.

**2. SMTPS is listed at port 587.** Objective 1.4's ports table pairs Simple Mail
Transfer Protocol Secure with 587. In the standards, 587 is the message submission
port defined by RFC 6409. Port 465 was briefly registered as `smtps`, that
registration was revoked, and RFC 8314 assigned 465 an alternate usage under the
service name `submissions`, meaning submission over implicit TLS. **Port 465 does
not appear in the document at all.** So the name CompTIA uses and the port the
standards attach it to do not line up, and a
topic has to teach CompTIA's pairing as the exam answer while saying plainly where
it comes from. This is exactly the kind of thing that gets a question wrong in
both directions if you only read one source.

**3. TACACS+ is misspelled in the acronym list.** The appendix reads "TACAS+".
The objectives text spells it correctly. Trivial, and it confirms the appendix is
not proofread against the body.

**4. SASE is spelled out two different ways in the same document.** Objective 1.8
writes it as "Secure Access Secure Edge". The acronym list writes it as "Secure
Access Service Edge", which is the industry term and the one Gartner coined. A
question could use either. The topic should teach the correct expansion and note
that CompTIA's objectives text has the other one.

Two smaller ones, recorded for completeness rather than because they matter: the
appendix expands NIC as "Network Interface Cards", plural, and MTBF as "Mean Time
Between Failure", singular, where objective 3.3 writes failures.

## Where output can come from

This is the part of the Network+ track that has no equivalent on Linux+, and it
was worked out before any content was planned rather than after.

Linux+ captures output by running commands in containers pinned by digest, with a
podman machine for anything needing a real kernel or block devices. That gets you
one host. Networking is about several hosts and the boxes between them, so it
needs a different answer.

**The answer is Linux network namespaces inside one privileged container.** Each
namespace is a host, a switch, or a router. `veth` pairs are the cables. Linux
bridges are the switches, and they are real switches: they learn MAC addresses,
they filter VLANs, and they run spanning tree. FRRouting supplies real OSPF and
BGP, and its `vtysh` shell answers the vendor-style `show` commands objective 5.5
names.

**Containerlab was considered and rejected.** It solves a real problem, which is
running vendor network operating system images as containers with a declarative
topology. Most of those images need a licence or an account, it needs Docker
rather than podman, and on this machine it would run inside a Linux virtual
machine that already exists for the Linux+ captures. The topologies this track
needs are small, so the orchestration is a shell script and the dependency is
zero.

Everything below was run before this document was written. None of it is a plan.

**Multi-hop routing, and traceroute that means something.** Three namespaces, a
router in the middle, static routes, and `traceroute` reports two hops with
`ping` showing `ttl=63` on the far side. Deterministic private addressing, no
dependence on anybody's ISP, and the TTL decrement is visible rather than
asserted.

**A real MAC-learning, VLAN-filtering switch.** A bridge with `vlan_filtering 1`,
two access ports with different PVIDs and a trunk carrying both tags, produces a
genuine `bridge vlan show` table. The 802.1Q tag itself is visible on the wire:
`tcpdump -e` prints `ethertype 802.1Q (0x8100) ... vlan 30` for a frame crossing a
tagged subinterface.

**Spanning tree, converging, with a port actually blocked.** Three bridges wired
into a triangle, STP enabled, bridge priority set to force the election. After
convergence all three agree on the root bridge id, and one port on the third
bridge reports `state blocking` while every other port reports `state forwarding`.
That is objective 5.3's root bridge selection, port roles, and port states, from a
running system rather than from a diagram.

**OSPF, with administrative distance visible in the output.** Two FRR routers over
a point-to-point link learn each other's loopbacks. `show ip route` prints
`O>* 10.2.2.2/32 [110/10] via 10.0.12.2`, and the same route appears in the kernel
table as `proto ospf metric 20`. Objective 2.1 asks about administrative distance,
prefix length, and metric as route selection inputs, and 110 is OSPF's
administrative distance sitting there in the output.

**DHCP, all four messages.** A dnsmasq server and a busybox client on a veth pair.
The server log shows DHCPDISCOVER, DHCPOFFER, DHCPREQUEST, DHCPACK in order, and
`tcpdump` on the client side catches the broadcast request and the unicast reply.
Lease time, gateway option, and DNS option are all set by the server and land on
the client.

**NAT, proven from the far side.** An inside host, a gateway running an nftables
masquerade rule, and an outside host. `tcpdump` on the outside interface shows the
source address rewritten to the gateway's own. The translation is observed at the
destination rather than described.

**Authoritative DNS.** BIND with a real zone file answers `dig` with the `aa`
flag set in the header, and returns A, AAAA, MX, TXT, CNAME, and NS records from
that zone. Objective 3.4's authoritative versus non-authoritative distinction is a
flag in captured output, not a definition.

That covers, with genuine output, the majority of domains 2, 3, and 5, plus the
addressing half of domain 1. It reaches considerably further than the Linux+
tooling did on its first pass.

### The honesty rules that come with it

The Linux+ rule stands unchanged: **a block is either captured or sourced, and
nothing gets typed into a code fence from memory.** Two additions specific to this
track.

**A Linux bridge is a switch and it is not a Cisco switch.** The forwarding
behaviour, the VLAN filtering, and the spanning tree are the real protocols. The
command syntax is not IOS, and the label on the block has to say so. Prose that
teaches `bridge vlan show` must also say what the equivalent question looks like
on a vendor CLI, because the exam names `show vlan`.

**FRR output is FRR output.** `show ip route` from vtysh looks close enough to IOS
to be mistaken for it, which makes labelling it more important rather than less. A
block gets a header naming FRR and its version, and any topic using it says
plainly that the exam's `show route` is vendor-neutral phrasing for a family of
commands that differ in detail.

## What cannot be captured

Being straight about this up front is half the point of doing the work in this
order.

| Area | Objectives | Why not |
| --- | --- | --- |
| OSI model, encapsulation | 1.1 | A framework, not a system state |
| Appliance categories | 1.2 | Categories of hardware, some of which cost more than a car |
| Cloud constructs | 1.3 | Needs a cloud account, and the output would be one provider's |
| Cabling, connectors, transceivers | 1.5 | Physical objects |
| Topologies and architectures | 1.6 | Design patterns |
| SDN, SD-WAN, VXLAN, SASE, ZTA | 1.8 | Vendor platforms, or design approaches |
| Wireless radio behaviour | 2.3, 5.4 | The virtual machine has no radio |
| Physical installation | 2.4 | Racks, power, cooling |
| Documentation, lifecycle, change | 3.1 | Process |
| Disaster recovery | 3.3 | Process, and the metrics are arithmetic |
| Most of domain 4 | 4.1, 4.2 | Concepts, and demonstrating attacks is not the job |
| Cable faults and PoE | 5.2 | Physical faults on physical cable |
| Hardware tools | 5.5 | Toners and cable testers |

**Roughly a third of this exam is conceptual and no amount of tooling changes
that.** Those topics get output sourced from standards and vendor documentation,
labelled as sourced, and the difference between the two kinds of block stays
visible on the page. VXLAN is the one borderline case: the kernel supports VXLAN
interfaces and a tunnel between two namespaces is capturable, so the
encapsulation can be shown even though the commercial fabric cannot.

Domain 4 deserves a note of its own. Several of its attacks are demonstrable in a
namespace, ARP poisoning most obviously. **The track will not do that.** Showing
the defence and the evidence it leaves is the useful half, and the site does not
need a working ARP poisoning recipe on it to teach what one is.

## Copyright and what this repo reproduces

CompTIA's objectives document carries "Reproduction or dissemination prohibited
without the written consent of CompTIA, Inc."

What appears in this repository:

- **Objective numbers.** They are how the exam is referenced and there is no other
  way to say "objective 2.1".
- **CompTIA's objective statements**, the one-line "Explain characteristics of
  routing technologies." headings. These live in `src/config/exams.ts` and in this
  document, for the same reason.
- **Published exam facts**: domain weights, question count, duration, scoring
  scale, languages, renewal terms.

What does not appear anywhere:

- **The sub-bullet content.** The lists of examples under each objective are the
  substance of the document and they are not reproduced, condensed, restructured,
  or tabulated. Where this document discusses them it does so as commentary on
  what is present or absent, which is analysis rather than reproduction.
- **The acronym appendix as a list.** The table above is the twenty-three-entry
  subset that supports a specific finding, not the appendix.

One thing to check on the existing track: **`docs/linux-plus-xk0-006-research.md`
contains a per-objective table whose third column condenses the sub-bullets.** It
predates this rule. Under the standard applied here it would be cut back to
statements plus commentary, and it is worth doing before the two documents sit
next to each other in `docs/` looking like they follow the same policy.

The trademark rules from
[linux-plus-question-authoring-standard.md](linux-plus-question-authoring-standard.md)
apply unchanged, and one of them determines naming: a CompTIA certification name
must not appear without the word CompTIA. **The track is "CompTIA Network+", never
"Network+" on its own**, in `tracks.ts`, in headings, and in the navigation.

## Sources

| Claim | Source | Tier | URL | Accessed |
| --- | --- | --- | --- | --- |
| Objectives, domains, weights, test details, acronym appendix | CompTIA Network+ N10-009 Certification Exam Objectives, version 4.0 | 1 | https://comptiacdn.azureedge.net/webcontent/docs/default-source/exam-objectives/comptia-network-n10-009-exam-objectives-(4-0)-(1).pdf | 2026-08-09 |
| Exam code, launch date, passing score, languages, estimated retirement | CompTIA Network+ certification page | 1 | https://www.comptia.org/en-us/certifications/network/ | 2026-08-09 |
| Network+ V10 listed as under development with no code or date | CompTIA, exam objectives under development | 1 | https://www.comptia.org/en-us/resources/comptia-exam-objectives-under-development/ | 2026-08-09 |
| N10-008 acronym appendix, for the removal diff | CompTIA Network+ N10-008 Certification Exam Objectives, version 3.0 | 1 | https://comptiacdn.azureedge.net/webcontent/docs/default-source/exam-objectives/comptia-network-n10-008-exam-objectives-(3-0).pdf | 2026-08-09 |
| Domain weights that total 99 | CompTIA blog, N10-008 vs N10-009 | 1 | https://www.comptia.org/en-us/blog/comptia-network-n10-008-vs-n10-009-whats-the-difference/ | 2026-08-09 |
| 30 CEUs to renew | CompTIA, renewing Network+ | 1 | https://www.comptia.org/en-us/resources/ce/renew-options/renewing-network-single/ | 2026-08-09 |
| Three-year renewal cycle | CompTIA, certification renewal policy | 1 | https://www.comptia.org/en-us/resources/test-policies/continuing-education-policies/certification-renewal-policy/ | 2026-08-09 |
| Port 587 is the message submission port | RFC 6409, Message Submission for Mail | 1 | https://www.rfc-editor.org/rfc/rfc6409 | 2026-08-09 |
| Port 465 registered for submission over TLS | RFC 8314 | 1 | https://www.rfc-editor.org/rfc/rfc8314 | 2026-08-09 |
| Linux bridge VLAN filtering and spanning tree behaviour | bridge(8), Linux man-pages | 1 | https://man7.org/linux/man-pages/man8/bridge.8.html | 2026-08-09 |
| Network namespace semantics | ip-netns(8), Linux man-pages | 1 | https://man7.org/linux/man-pages/man8/ip-netns.8.html | 2026-08-09 |
| OSPF administrative distance and vtysh output | FRRouting user guide | 1 | https://docs.frrouting.org/en/latest/ | 2026-08-09 |

The objectives document itself is copyright CompTIA and is not committed to this
repository. It is downloaded, read, and cited.
