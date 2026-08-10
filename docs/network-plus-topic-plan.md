# CompTIA Network+ track: the full topic plan

Every topic in the track, in reading order, with what each one has to teach and
what it depends on. Written for the same audience as the Linux+ track: somebody
who has never configured a network, with experienced engineers served by `DEEPER`
panels rather than by the main flow.

**76 topics plus an orientation page.** That is not a target. It is what covering
25 objectives from zero takes, and it lands within one page of the Linux+ track
by coincidence rather than by design.

Companions: [network-plus-n10-009-research.md](network-plus-n10-009-research.md)
for what is on the exam,
[linux-plus-teaching-design.md](linux-plus-teaching-design.md) for how a topic is
written, and
[linux-plus-question-authoring-standard.md](linux-plus-question-authoring-standard.md)
for the practice questions.

**Read [network-plus-teaching-design.md](network-plus-teaching-design.md) before
this document.** It records where Network+ has to depart from the Linux+ design
and it overrides both of those companions where they conflict. The short version:
the Linux+ thesis does not transfer, "Prove it" needs a second form for the
twenty-three topics that have nothing to run, and the question authoring standard
takes five per-track amendments rather than applying unchanged.

- [How to read this plan](#how-to-read-this-plan)
- [The topic template, decided once](#the-topic-template-decided-once)
- [Across platforms, and what it costs to build](#across-platforms-and-what-it-costs-to-build)
- [Balance check](#balance-check)
- [Stage A. Foundations](#stage-a-foundations)
- [Stage B. Addressing and media](#stage-b-addressing-and-media)
- [Stage C. Switching and routing](#stage-c-switching-and-routing)
- [Stage D. Network designs and wireless](#stage-d-network-designs-and-wireless)
- [Stage E. Security foundations and operations](#stage-e-security-foundations-and-operations)
- [Stage F. Attacks, controls, and modern environments](#stage-f-attacks-controls-and-modern-environments)
- [Stage G. Troubleshooting](#stage-g-troubleshooting)
- [Where the order came from](#where-the-order-came-from)
- [Objective coverage check](#objective-coverage-check)
- [Capture feasibility](#capture-feasibility)
- [The netlab script](#the-netlab-script)
- [Diagrams worth building](#diagrams-worth-building)
- [Question banks](#question-banks)
- [Infrastructure changes this track needs](#infrastructure-changes-this-track-needs)
- [Suggested authoring order](#suggested-authoring-order)

## How to read this plan

Numbers are reading order, not filenames. `order` in frontmatter is numbered in
tens and the displayed numbering is generated. `00` is the orientation page and
sits outside the lesson count.

**Zero hook** is the concrete thing the topic opens with, per the
concrete-before-abstract rule. A beginner should be able to picture it before any
terminology arrives. If a topic has no plausible zero hook, it is scoped wrong.

**Deeper** is what goes behind the collapsible panels for experienced readers.
Topics get one panel per major body section rather than one at the foot of the
page, which is the correction made late on the Linux+ track and is baked in here
from the start.

**Capture** says where the output in that topic comes from: `netlab` for a
namespace topology, `container` for a single-host command, `vm` for the podman
machine, and `doc` for output sourced from standards or vendor documentation.

## The topic template, decided once

Two templates quietly diverged around topic 60 on the Linux+ track and had to be
reconciled across seventeen topics afterwards. So the order below is fixed before
the first topic is written, and it does not get revisited.

| # | Section | Required |
| --- | --- | --- |
| 1 | **Before you read** | Yes. One question the reader cannot yet answer. |
| 2 | **Some words you will need** | Yes. A `dl.terms` list. |
| 3 | **What breaks without this** | Yes. Consequence, not definition. |
| 4 | Body sections | Yes. Concrete first. `details.predict` hides captured output behind a question. One `details.deeper` panel per major section. |
| 5 | **Across platforms** | Only where the same task has a vendor CLI, a Linux, and a Windows answer. |
| 6 | **Prove it** | Yes. Evidence in one of three forms: a command to run, arithmetic to do, or a named clause to look up. See the teaching design. |
| 7 | **What trips people up** | Yes. Three to six, each with real error text or real output. |
| 8 | **Work it through** | Yes. A scenario reasoned out on the page, nothing to run. |
| 9 | **Try it** | Yes. Optional for the reader, required in the topic. |
| 10 | **Check yourself** | Yes. `details.qa` blocks. |
| 11 | **References** | Yes. Every source, with the date it was checked. |

Block F topics insert two more before References, exactly as the Linux+
troubleshooting topics do: **For the exam** and **Where this sits**.

Three rules that go with the template, so they are not decided per topic:

**Diagrams have no section.** An inline SVG goes wherever the concept is
structural, inside the body section that needs it.

**A DEEPER panel belongs to the section above it.** If a body section has nothing
worth putting behind a panel, the section is probably still pitched too high for
a beginner, which is the signal to rewrite the section rather than skip the panel.

**The summary line at the foot of a topic states provenance.** Which blocks were
captured, on what, and which were sourced. Every topic ends with one, in the same
place, as the Linux+ topics do.

## Across platforms, and what it costs to build

Linux+ has "Across distributions" because the exam is deliberately vendor-neutral
across two distribution families. Network+ has no distribution split, so the
question was whether an equivalent earns its place at all.

**It does, and the reason is in objective 5.5.** That objective names a vendor CLI
command family and, separately, names `ip`, `ifconfig`, and `ipconfig` as three
tools for the same job. The exam therefore has a genuine recurring three-way axis
of its own: the same question asked of a switch, of a Linux host, and of a Windows
host. That is the shape that benefits from shared table geometry, because a reader
moving between topics reads those tables as a set.

Fixed columns, everywhere it appears:

| Task | Vendor CLI | Linux | Windows |

**It is not a required section.** It applies to switching, routing, addressing,
name resolution, monitoring, and most of block F. It does not apply to cabling,
wireless radio behaviour, cloud models, disaster recovery, topologies, or physical
installation, and forcing a table onto those topics would produce exactly the
padded comparison the convention exists to prevent.

**The vendor CLI column is the one to be careful with.** The exam's phrasing is
vendor-neutral, real switches differ, and this track has no Cisco switch. Where
the column holds captured output it comes from FRRouting and says so. Where it
holds a command form, it is CompTIA's own vendor-neutral phrasing and the prose
says that a given vendor's syntax will differ in detail. What the column must
never do is present an invented IOS transcript as if somebody ran it.

Building this needs a small change to two files that currently hardcode the Linux+
heading. See [infrastructure changes](#infrastructure-changes-this-track-needs).

## Balance check

| Stage | Topics |
| --- | --- |
| A. Foundations | 4 |
| B. Addressing and media | 9 |
| C. Switching and routing | 13 |
| D. Network designs and wireless | 6 |
| E. Security foundations and operations | 19 |
| F. Attacks, controls, and modern environments | 9 |
| G. Troubleshooting | 16 |
| **Total** | **76** |

Block A is excluded from the share column for the same reason the Linux+ plan
excludes its foundations block: it teaches what the exam assumes you already know
rather than what the exam tests. Every other block lands within two points of its
weight.

Two deliberate choices inside that table. **Troubleshooting gets sixteen topics
because it is the largest domain on this exam**, which is the finding from the
research document that most changes how the track is shaped. And **security gets
ten**, which will feel thin to anyone arriving from the Linux+ track, because 14
percent is what it is worth.

## The orientation page

`00 start-here` sits outside the lesson count and outside the stages. It is order 10 in frontmatter; lesson 01 is order 20.

## Stage A. Foundations

Four topics. A reader arrives with a device-centric picture of networking and no layered structure at all, so this stage builds the structure out of one cable and three identifiers before naming anything.

| # | Slug | Level | Obj | Zero hook | Must teach | Deeper | Capture |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 01 | `what-a-network-actually-is` | intro | 1.1 | Two laptops, one cable, and nothing happens | What a network is for; hosts, links, and the boxes between; why a machine needs more than one identifier; client and server as roles rather than hardware. **written** | Link state vs carrier; why two identifiers; circuit vs packet switching | netlab |
| 02 | `macs-ips-and-ports` | intro | 1.1, 1.4 | One machine, three different addresses, all correct at once | MAC as the local identifier, IP as the routable one, port as the application one; the three nested inside one frame; local delivery against routed delivery, and what changes at each hop | ARP cache poisoning previewed; why MAC addresses do not leave the segment | netlab |
| 03 | `the-osi-model` | intro | 1.1 | A page will not load, and the fault could be in seven different places | The seven layers and what each one adds; encapsulation as headers nesting, with the frame from topic 02 as the referent; the four-layer stack from RFC 1122 alongside, so the reader knows which model the protocols match; that layers 5 and 6 have no separate counterpart in anything they will meet. **The diagnostic half belongs to the layer-ladder troubleshooting topic, not here** | Where the model and reality disagree; the TCP/IP stack alongside it; why layer 8 jokes exist | netlab |
| 04 | `the-boxes-on-a-network` | intro | 1.2 | A cupboard with six devices in it and nobody knows what any of them do | Router, switch, firewall, IDS and IPS, load balancer, proxy, NAS and SAN, access point and controller; CDN as an application; VPN, QoS, and TTL as functions; physical versus virtual appliances; UTM gets its one sentence here | Where a virtual appliance actually runs; why IDS and IPS differ by placement rather than by logic | doc |

## Stage B. Addressing and media

Nine topics. Addressing to fluency, then the physical world the addresses travel through, then the room it all lives in.

| # | Slug | Level | Obj | Zero hook | Must teach | Deeper | Capture |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 05 | `ipv4-addresses-and-the-mask` | intro | 1.7 | You are handed `192.168.10.0/26` and asked how many machines fit. The obvious answer is wrong twice | The 32 bits and binary, in the main flow rather than behind a panel; dotted decimal as a convenience; what the mask decides; network, host and broadcast addresses; CIDR notation; the eight legal mask octet values and powers of two to 2^16 as part-task material | Why the two unusable addresses exist, and the one case where they do not; how a mask is stored | netlab |
| 06 | `subnetting-by-hand` | working | 1.7 | You are given a /24 and told to make six networks out of it, and six does not divide into anything | Dividing a network rather than reading one: borrowing bits, and why you round up to a power of two; how many subnets a given number of borrowed bits buys; picking a prefix from a host requirement; laying out the resulting ranges without gaps or overlaps; doing it on the digital whiteboard online delivery gives you, since physical writing materials are prohibited. **Topic 05 owns reading a prefix; this one owns creating them, and must not re-teach the block-size method** | The arithmetic behind the shortcut; subnetting a subnet, and where VLSM begins | container |
| 07 | `address-classes-private-ranges-and-apipa` | intro | 1.7 | An interface with a 169.254 address and no internet | Classes A through E and why they are obsolete but examinable; RFC 1918 ranges; loopback; APIPA and what it proves; public versus private and where NAT sits | Classful remnants in real protocols; the documentation ranges used throughout this track | netlab |
| 08 | `ipv6-addressing` | working | 1.8 | Four billion addresses ran out in 2011 and the internet kept working | Why exhaustion happened; 128 bits and hex notation; shortening rules; link-local; the compatibility story of dual stack, tunnelling, and NAT64 | EUI-64 and privacy addresses; why NAT is not the IPv6 answer | netlab |
| 09 | `tcp-udp-and-the-handshake` | intro | 1.4 | One protocol resends what got lost. The other does not, and that is the point | Connection-oriented versus connectionless; the three-way handshake; sequence numbers, acknowledgement, retransmission; teardown; when each protocol is the right choice | Window size and flow control; TIME_WAIT; why streaming uses UDP | netlab |
| 10 | `ports-and-the-protocols-that-use-them` | intro | 1.4 | A firewall rule mentions 443 and nobody said what that is | The protocols and port numbers the exam names, learned as a table, with a method for learning them; secure and insecure pairs and the pattern behind them; what a port number does and does not guarantee. **Topic 02's deeper panel already shipped the three IANA ranges, the Linux ephemeral range, privileged ports and the four-tuple. Link to it, do not repeat it** | Why SMTPS is listed at 587 and what the RFCs actually say; POP3 and IMAP being absent from this exam | container |
| 11 | `copper-cabling` | intro | 1.5 | The cable looks identical and the link will not come up | Twisted pair and why it is twisted; shielded and unshielded; categories and the speeds they carry; direct attach copper and twinaxial; coaxial; plenum rating and why a building inspector cares | Crosstalk and the physics of the twist; why category numbers are not speeds | doc |
| 12 | `fibre-and-transceivers` | working | 1.5 | Two fibres that look the same, one of which will not carry your traffic 300 metres | Single mode against multimode and what changes; connector types the exam names; transceiver form factors; Ethernet and Fibre Channel as transceiver protocols; matching a transceiver to a fibre | Wavelength and dispersion; why a mismatched transceiver produces a working-looking link | doc |
| 13 | `physical-installations` | working | 2.4 | A rack that overheats every afternoon at four | Main and intermediate distribution frames; rack units and sizing; port-side intake and exhaust and why the direction matters; patch panels and fibre distribution panels; locking; uninterruptible supplies, power distribution units, load and voltage; humidity, temperature, and fire suppression | Hot and cold aisle containment; sizing a UPS from the load; why the wrong extinguisher ruins the room | doc |

## Stage C. Switching and routing

Thirteen topics, the heart of the exam and the block with the most captured output. A switch forwards on a MAC address and a router forwards on a network, and everything here is a consequence of those two decisions.

| # | Slug | Level | Obj | Zero hook | Must teach | Deeper | Capture |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 14 | `how-a-switch-learns` | working | 2.2 | Plug in a new machine and the switch finds it without being told | The MAC address table and how it fills; flooding an unknown destination and what that means for anyone listening; ageing and why the timer is what it is; why a switch is not a hub. **Topic 04's panels already shipped collision and broadcast domain counting, the control and data plane split, and the hardware table size limit. Reference them, do not re-teach them** | The CAM acronym the exam lists and never uses; ageing against the ARP cache timer, and the flooding that happens when they disagree | netlab |
| 15 | `unicast-multicast-anycast-broadcast` | working | 1.4 | One packet, and four different answers to "who gets this" | The four delivery types; broadcast domains; multicast groups and where they are used; anycast and how one address is in several places at once | IGMP snooping; why anycast makes DNS fast; broadcast storms previewed | netlab |
| 16 | `vlans` | working | 2.2 | One switch, two companies, and traffic that must never mix | What a VLAN separates and what it does not; the VLAN database; access ports and the port VLAN id; switch virtual interfaces; voice VLANs; inter-VLAN routing as a preview | Why a VLAN is a broadcast domain; the native VLAN and the argument about untagging | netlab |
| 17 | `trunking-and-802-1q-tagging` | working | 2.2 | One cable between two switches carrying eight VLANs | The tag, where it sits in the frame, and what it costs; trunk ports; the native VLAN and untagged traffic; allowed VLAN lists; what happens when two ends disagree | Double tagging and VLAN hopping; QinQ named once; the four bytes and the MTU implication | netlab |
| 18 | `interface-configuration-and-link-aggregation` | working | 2.2 | The link is up at 100 Mb on a gigabit switch | Speed and duplex, negotiation, and mismatch; enabling and disabling an interface; link aggregation and what it does and does not give you; the acronym for the negotiation protocol the exam lists and does not test | Why duplex mismatch produces late collisions; hashing and why one flow does not get two links | netlab |
| 19 | `spanning-tree` | working | 2.2, 5.3 | Two switches, two cables between them, and the whole network stops | Why a layer 2 loop is fatal; the root bridge and how it is elected; port roles and port states; convergence; what enabling it costs | Reading a real bridge id; why the lowest priority wins and how to force it; rapid spanning tree named once | netlab |
| 20 | `mtu-and-jumbo-frames` | working | 2.2 | Small requests work. Large ones hang forever | What the MTU is; fragmentation and path MTU discovery; jumbo frames and where they help; what an inconsistent MTU does to a path; the black hole when the ICMP that would report it is blocked | Encapsulation eating MTU; TCP MSS clamping | netlab |
| 21 | `the-routing-table-and-static-routes` | working | 2.1 | The packet is not for anyone on this network. Now what | The routing table as a list of decisions; connected, static, and default routes; longest prefix match; adding a static route; the default gateway as the least specific route | `ip route get` and asking the kernel to show its working; floating static routes | netlab |
| 22 | `dynamic-routing-protocols` | working | 2.1 | Forty routers and a link that just failed at 3am | Why dynamic routing exists; the three protocols the exam names and what distinguishes them; interior against exterior; convergence; neighbours and adjacency | Link state against distance vector; why BGP is a policy protocol rather than a shortest-path one | netlab |
| 23 | `route-selection` | working | 2.1 | Two routes to the same place. Only one goes in the table | Administrative distance and what it compares; prefix length beating everything; metric as the last tiebreak; the order the three are applied in | Reading administrative distance out of real routing output; equal cost multipath | netlab |
| 24 | `vlsm-and-planning-an-address-space` | working | 1.7 | Six subnets, wildly different sizes, and one /22 to fit them in | Variable length subnet masking; allocating largest first; summarisation; leaving room to grow; reading somebody else's plan | Route summarisation and why it needs contiguous allocation; discontiguous networks | container |
| 25 | `nat-and-pat` | working | 2.1 | Fifty machines, one public address, and everything works | What NAT translates and why; port address translation and the table that makes it work; source and destination translation; what NAT breaks | Why NAT is not a security control; the conntrack table filling; NAT and IPv6 | netlab |
| 26 | `fhrp-vip-and-subinterfaces` | working | 2.1 | The default gateway is a single point of failure | First hop redundancy as a concept and why no protocol is named; the virtual IP and virtual MAC; active and standby; subinterfaces and router on a stick | Why the exam names no FHRP protocol; preemption and the failover that flaps | netlab |

## Stage D. Network designs and wireless

Six topics. Comparisons between designs, which only mean something once a reader has met the devices being compared, and then the radio.

| # | Slug | Level | Obj | Zero hook | Must teach | Deeper | Capture |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 27 | `topologies-and-architectures` | intro | 1.6 | Two buildings, four hundred desks, and a drawing to make | Star and hub and spoke, mesh, hybrid, point to point; spine and leaf; the three-tier hierarchical model and collapsed core; north-south and east-west traffic flows | Why spine and leaf replaced three-tier in data centres; oversubscription ratios | doc |
| 28 | `sdn-sd-wan-and-vxlan` | working | 1.8 | Two hundred branch offices and one policy change | The control plane and data plane split; software-defined networking; SD-WAN and what application-aware, transport-agnostic, and zero-touch provisioning mean; VXLAN as layer 2 over layer 3 and data centre interconnect | The VXLAN header and the MTU cost it imposes; why overlays need underlays | netlab |
| 29 | `wireless-and-cellular-media` | intro | 1.5 | The laptop says connected and nothing loads | 802.11 as a family; what a radio link shares that a cable does not; cellular and satellite as transmission media; the honest limits of each | Half duplex on the air; why the exam names 802.11 as a category and no letter standards | doc |
| 30 | `wireless-channels-and-frequencies` | working | 2.3 | Twelve access points in one office and everything is slow | The three bands and what each trades; channel width; non-overlapping channels and why only three in 2.4 GHz; band steering; regulatory limits and the standard the exam names for them | Why wider channels are not always faster; dynamic frequency selection | doc |
| 31 | `ssids-network-types-and-access-points` | working | 2.3 | The same network name in every room, and your laptop moves between them | SSID, BSSID, and ESSID as three different things; infrastructure, mesh, ad hoc, and point to point; guest networks and captive portals; autonomous against lightweight access points and the controller; antenna patterns | Why roaming is a client decision; where a controller sits in the traffic path | doc |
| 32 | `wireless-security-and-authentication` | working | 2.3 | The password is on a whiteboard and forty people know it | WPA2 and WPA3 and what changed; pre-shared key against enterprise; what enterprise authentication actually involves; guest isolation | Why WEP and the original WPA are absent from this exam; the four-way handshake named once | doc |

## Stage E. Security foundations and operations

Nineteen topics, the longest stretch in the track. Encryption and identity come first because six later topics need them, then the services a network runs and the processes around them.

| # | Slug | Level | Obj | Zero hook | Must teach | Deeper | Capture |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 33 | `security-vocabulary-and-the-cia-triad` | intro | 4.1 | Everyone uses these five words and half of them mean something else | Risk, vulnerability, threat, and exploit as four distinct things; the confidentiality, integrity, and availability triad; why availability is a security property | Why the triad is a checklist rather than a theory; risk as likelihood times impact | doc |
| 34 | `encryption-certificates-and-pki` | working | 4.1 | The browser padlock proves less than people think | Data in transit and data at rest; symmetric and asymmetric in one page; what a certificate binds; public key infrastructure and the chain of trust; self-signed certificates and when they are acceptable | Reading a real certificate chain; why an expired certificate fails closed | container |
| 35 | `identity-and-access-management` | working | 4.1 | The contractor left in March and the account still works | Authentication against authorisation; multifactor and single sign-on; the four authentication services the exam names and what distinguishes them; time-based authentication; least privilege and role-based access control; geofencing | RADIUS against TACACS+ on what they encrypt; why SAML is not a login protocol | container |
| 36 | `network-documentation-and-diagrams` | working | 3.1 | The person who built it left in 2019 | Physical against logical diagrams; rack diagrams and cable maps; layer 1, 2, and 3 diagrams as three different drawings; asset inventory with hardware, software, licensing, and warranty; IP address management; service level agreements; wireless surveys and heat maps | What makes a diagram survive contact with change; why layer 2 diagrams are the ones nobody has | doc |
| 37 | `lifecycle-change-and-configuration-management` | working | 3.1 | The switch stopped getting firmware updates two years ago | End of life against end of support; patching, operating system, and firmware as separate cycles; decommissioning; change management and request tracking; production, backup, and golden configurations | Configuration drift and how it is detected; why a backup config nobody restores is not a backup | doc |
| 38 | `snmp` | working | 3.2 | The switch has been telling you for six months and nobody was listening | What SNMP is for; the management information base and object identifiers; polling against traps; community strings and why v2c is not secure; version 3 and what it adds | Walking a real MIB; why OIDs look the way they do; the acronym for the trap receiver | container |
| 39 | `flow-data-capture-and-port-mirroring` | working | 3.2 | You need to know who is using the bandwidth, not how much is being used | Flow data and what a flow record contains; packet capture as the heavier alternative; port mirroring and where to place it; taps against mirrors; what each method can and cannot see | Why the exam says flow data and names no product; sampling and what it hides | netlab |
| 40 | `baselines-alerting-and-monitoring-solutions` | working | 3.2 | The alert fired at 2am and it was nothing | Baseline metrics and why a number means nothing without one; anomaly alerting; log aggregation, syslog collectors, and security event management; API integration; network discovery, ad hoc and scheduled; traffic, performance, availability, and configuration monitoring | Alert fatigue as a real failure mode; the golden signals | container |
| 41 | `disaster-recovery` | working | 3.3 | The building has no power and the business needs to keep trading | Recovery point and recovery time objectives and the difference; mean time to repair and mean time between failures; cold, warm, and hot sites and what each costs; active-active against active-passive; tabletop exercises and validation tests | Why RPO is a data decision and RTO is a money decision; the recovery plan nobody has read | doc |
| 42 | `dhcp` | working | 3.4 | A machine plugs in and has an address three seconds later | The four-message exchange; scopes, ranges, and exclusions; reservations; lease time and renewal; the options that carry the gateway and the resolver; relay and the helper address for crossing a broadcast boundary | Watching the exchange on the wire; why a rogue server wins; lease exhaustion | netlab |
| 43 | `ipv6-address-assignment-and-slaac` | working | 3.4 | The interface has three IPv6 addresses and nobody assigned any of them | Stateless address autoconfiguration and router advertisements; how it differs from DHCP; when you still want DHCPv6; link-local as always present | Duplicate address detection; the privacy extension that changes the address daily | netlab |
| 44 | `how-dns-resolution-works` | working | 3.4 | `ping 1.1.1.1` works and `ping example.com` does not | The resolution path from stub resolver to root to authoritative; recursive against iterative; caching and time to live; authoritative against non-authoritative answers; the hosts file and where it sits in the order | Reading the authoritative flag out of a real answer; negative caching; why a stale record outlives the change | netlab |
| 45 | `what-happens-when-you-open-a-web-page` | intro | 1.1, 1.4 | You type a name and press enter. Roughly nine things happen | DNS lookup, ARP for the gateway, TCP handshake, TLS, HTTP request, response, teardown; each step tied back to its layer | Connection reuse; happy eyeballs and dual stack; where each step can fail | netlab |
| 46 | `dns-records-and-zones` | working | 3.4 | The website moved and email stopped | The record types the exam names and what each one is for; forward and reverse zones; primary and secondary; the start of authority record the acronym list mentions and the objectives do not; zone transfers | Reverse lookup delegation; why a CNAME at the apex is a problem | netlab |
| 47 | `dns-security` | working | 3.4 | The answer came back signed, and something still gave you the wrong address | What DNSSEC signs and what it does not; DNS over HTTPS and DNS over TLS and what each hides from whom; poisoning and spoofing as the attacks these answer | Why DNSSEC does not encrypt; the split-horizon problem DoH creates for enterprises | netlab |
| 48 | `time-protocols` | working | 3.4 | Certificates are valid and authentication fails on one server | Why time matters on a network; NTP, stratum, and how a hierarchy is built; precision time protocol and where microseconds are needed; network time security | Clock skew breaking Kerberos and TLS; why a bad clock looks like a certificate problem | container |
| 49 | `ip-protocols-and-tunnelling` | working | 1.4 | The packet has a header inside another header | ICMP and what it is for; TCP and UDP as IP protocol numbers; GRE as plain encapsulation; IPSec with its authentication header, encapsulating payload, and key exchange | Protocol numbers versus port numbers; why GRE has no encryption; transport mode against tunnel mode | netlab |
| 50 | `vpns` | working | 3.5 | Somebody needs the finance system from a hotel | Site to site against client to site; clientless access; split tunnel and full tunnel and the trade each makes; where the tunnel terminates | Why split tunnel is a policy argument rather than a technical one; what a VPN does not protect | doc |
| 51 | `managing-devices-remotely` | working | 3.5 | The switch is in a locked room 200 miles away and its config is wrong | Console, SSH, graphical interfaces, and APIs as four access methods; the jump box and why it exists; in-band against out-of-band management and why the distinction saves outages | Out-of-band done properly with a separate path; why managing a switch through the switch is a trap | container |

## Stage F. Attacks, controls, and modern environments

Nine topics. Every attack here is against a mechanism the reader has already built, so this stage is consolidation rather than first contact.

| # | Slug | Level | Obj | Zero hook | Must teach | Deeper | Capture |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 52 | `physical-security-and-deception` | intro | 4.1 | The most effective attack on the data centre used a clipboard | Cameras and locks as network controls; honeypots and honeynets and what they are actually for | Why a honeypot is an alerting tool rather than a defence; legal caution | doc |
| 53 | `compliance-and-audits` | working | 4.1 | The audit asks you to prove the control works, not that it exists | Why regulation reaches the network; data locality; the payment card standard and the data protection regulation the exam names; what an audit asks for and what evidence looks like | Evidence that survives an auditor; the gap between a policy and a running configuration | doc |
| 54 | `acls-filtering-and-security-zones` | working | 4.3 | The rule is in the list and traffic still gets through | Access control lists, order of evaluation, and the implicit deny; URL and content filtering; trusted and untrusted zones; the screened subnet and what it is for | Why rule order is the whole game; why the exam says screened subnet and everybody says DMZ | netlab |
| 55 | `network-segmentation` | working | 4.1 | A vending machine on the same network as the payment system | Segmentation as an enforcement mechanism; the device categories that need their own segment; guest networks; bring your own device; how segmentation limits blast radius | Why flat networks persist; microsegmentation named once | netlab |
| 56 | `layer-2-attacks` | working | 4.2 | Everything still works and somebody is reading all of it | MAC flooding against the table from topic 22; ARP poisoning and spoofing; VLAN hopping against the tagging from topic 24; what each one gives an attacker; the evidence each leaves | Reading a poisoned neighbour table; why these attacks need local access and what that implies | netlab |
| 57 | `attacks-on-services-and-people` | working | 4.2 | The network is fine and the company has been compromised | Denial of service and the distributed form; DNS poisoning and spoofing; rogue DHCP servers and rogue access points; evil twin; on-path attacks; the social engineering techniques the exam names; malware as a category | Amplification and why UDP services get abused; why the human techniques are on a network exam | doc |
| 58 | `device-hardening-and-network-access-control` | working | 4.3 | A switch in a meeting room with sixteen live ports | Disabling unused ports and services; changing default credentials; port security; 802.1X and what a supplicant, authenticator, and server each do; MAC filtering and why it is weak; key management | The acronym for 802.1X's transport that the exam lists and never uses; why MAC filtering is a speed bump | netlab |
| 59 | `cloud-concepts-and-connectivity` | working | 1.3 | The server is in a building you will never visit | Service models and deployment models; virtual private cloud; network security groups and lists; internet and NAT gateways; connecting to cloud by VPN or dedicated circuit; scalability, elasticity, multitenancy; network functions virtualisation | Why a security group is not a firewall appliance; shared responsibility at the network layer | doc |
| 60 | `zero-trust-sase-and-infrastructure-as-code` | working | 1.8 | The old model trusted anything already inside the building | Zero trust architecture, policy-based authentication, authorisation, least privilege; secure access service edge and security service edge; infrastructure as code for networks, with automation, templates, drift, and source control | Why the perimeter model failed; how network IaC differs from server IaC; CompTIA spelling SASE two ways | container |

## Stage G. Troubleshooting

Sixteen topics, matching the largest domain on the exam. Instruments before symptoms, because a symptom topic that references a tool taught two topics later teaches nobody.

| # | Slug | Level | Obj | Zero hook | Must teach | Deeper | Capture |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 61 | `the-troubleshooting-methodology` | working | 5.1 | Everything is broken and you have to start somewhere | CompTIA's seven steps, in order, and what each one is guarding against; questioning the obvious; duplicating the problem; approaching multiple problems individually; documenting outcomes | Why the documented step is the one everybody skips; escalating without losing the context | doc |
| 62 | `ping-traceroute-and-what-they-prove` | working | 5.5 | Ping fails and the server is serving traffic perfectly | What ICMP echo tests and what it does not; reading a traceroute honestly; loss at a hop against loss to the end; the asymmetry between a successful test and a failed one | Path MTU discovery with a forbidden-fragment ping; why traceroute output differs between platforms | netlab |
| 63 | `connection-and-interface-tools` | working | 5.5 | Something is listening on a port and nobody knows what | Listing connections and listening sockets; reading a listen address; the interface tools on each platform and which name goes with which; the neighbour and address resolution table | The tool this exam names against the tool a modern Linux system prefers; connection states worth recognising | netlab |
| 64 | `name-resolution-tools` | working | 5.5 | The name resolves on your machine and not on theirs | Querying a specific server; reading an answer section; authoritative and non-authoritative in the output; forward and reverse lookups; the tool the exam names on each platform | Why the resolver a program uses is not always the one the tool queries; caching on the client | netlab |
| 65 | `narrowing-a-fault-by-layer` | working | 5.1 | Fifteen candidates, two machines, and one afternoon | Top-down, bottom-up, and divide and conquer as three named approaches; picking one deliberately; the discriminating test as the unit of progress | Why experts do not run the ladder in order and why you should until you are one | netlab |
| 66 | `cable-faults-and-signal-problems` | working | 5.2 | The link works at 100 Mb and refuses to negotiate 1000 | Wrong cable type, category, and shielding; attenuation, crosstalk, and interference; improper termination; transmit and receive transposed; distance limits | Why a marginal cable passes a continuity test; the cable that works until somebody moves the desk | doc |
| 67 | `interface-counters-and-port-status` | working | 5.2 | The interface is up and the counters are climbing | Reading error counters and what each one means; frame check errors, runts, giants, and drops; error disabled, administratively down, and suspended port states; what a rising counter narrows the fault to | Which counters indicate a duplex mismatch; counters that reset and hide the evidence | netlab |
| 68 | `poe-and-transceiver-problems` | working | 5.2 | Six cameras, one switch, and the sixth one keeps rebooting | Power budget and how it is exceeded; standards mismatch between injector and device; transceiver mismatch and insufficient signal strength; what each failure looks like from the switch | Reading a power budget; why the last device on the budget fails first | doc |
| 69 | `switching-faults-loops-and-vlans` | deep | 5.3 | The network is saturated and no host is sending anything | Spanning tree faults: loops, wrong root bridge, port roles and states not converging; incorrect VLAN assignment; access lists blocking what you did not intend | Broadcast storms and how fast they take a network down; the loop caused by somebody being helpful with a patch cable | netlab |
| 70 | `routing-and-default-gateway-faults` | deep | 5.3 | Local traffic is perfect and nothing leaves the building | Missing and wrong default routes; the wrong gateway configured; route selection picking a path you did not expect; asymmetric routing | Comparing a broken host against a working one; policy routing that nobody mentioned | netlab |
| 71 | `addressing-faults` | deep | 5.3 | Two machines, one address, and connectivity that comes and goes | Duplicate addresses and the intermittent failure they produce; incorrect address; incorrect subnet mask and the pattern it produces; address pool exhaustion and what it looks like from the client | Detecting a duplicate from the neighbour table; why a wrong mask looks like broken hardware | netlab |
| 72 | `wireless-performance-and-roaming` | deep | 5.4 | Full signal strength, and the connection keeps dropping | Interference and channel overlap; signal degradation and coverage gaps; client disassociation; roaming misconfiguration; why signal strength alone tells you almost nothing | Sticky clients; the survey that was done when the building was empty | doc |
| 73 | `packet-capture-and-protocol-analysis` | deep | 5.5 | The two teams disagree and the packets settle it | Capturing on the right interface with the right filter; reading a handshake; recognising retransmission, reset, and silence; what nothing on the wire tells you; where to capture when the fault is between two places | Filters that keep a capture usable on a busy host; why name resolution in a capture tool misleads | netlab |
| 74 | `discovery-tools-and-device-commands` | working | 5.5 | You inherit a network and no documentation | Port and host discovery; the neighbour discovery protocols and what they reveal; speed testers; the vendor-neutral device commands the exam names and what each answers; the hardware tools and what each is for | Scanning responsibly and why it is a permission question; reading a neighbour table to rebuild a diagram | netlab |
| 75 | `bandwidth-congestion-and-bottlenecks` | deep | 5.4 | The link is at 40 percent and everything is slow | Throughput capacity against bandwidth; congestion and contention; finding the bottleneck rather than the busiest link; what a saturated uplink does to everything behind it | Buffer bloat; why averages hide a saturated interface | netlab |
| 76 | `latency-jitter-and-packet-loss` | deep | 5.4 | The call breaks up and the file transfer is fine | Latency and where it comes from; jitter and why it destroys voice; packet loss and the effect on TCP against UDP; measuring each of the three; which applications care about which | One percent loss and what it does to a TCP transfer; the ICMP that traceroute depends on being deprioritised | netlab |

## Where the order came from

The first version of this plan ran the topics in the exam's own objective order,
lightly rearranged. That was never checked against how networking is taught, and
when it was, the order broke its own dependencies in about twenty places: five of
the six foundations topics were defined in terms of material taught fifteen to
fifty-five positions later.

The ordering rule now is one sentence. **A summary comes after its components, an
abstraction comes after the behaviour it names, and an instrument comes before the
reading it produces.**

Deliberately not a position on top-down against bottom-up. The only direct
empirical comparison anybody found is a 2005 conference paper, closed access, nine
citations in twenty years, reportedly measuring student preference rather than
attainment. It carries no weight here in either direction. What the order rests on
instead is the dependency graph, which is checkable in the tables above, and
convergent practice across five curricula where it exists.

Topics that changed position, by new number and old:

| New | Old | Slug |
| --- | --- | --- |
| 02 | 03 | `macs-ips-and-ports` |
| 03 | 02 | `the-osi-model` |
| 04 | 05 | `the-boxes-on-a-network` |
| 05 | 07 | `ipv4-addresses-and-the-mask` |
| 06 | 08 | `subnetting-by-hand` |
| 07 | 10 | `address-classes-private-ranges-and-apipa` |
| 08 | 11 | `ipv6-addressing` |
| 09 | 12 | `tcp-udp-and-the-handshake` |
| 10 | 13 | `ports-and-the-protocols-that-use-them` |
| 11 | 16 | `copper-cabling` |
| 12 | 17 | `fibre-and-transceivers` |
| 13 | 36 | `physical-installations` |
| 14 | 22 | `how-a-switch-learns` |
| 16 | 23 | `vlans` |
| 17 | 24 | `trunking-and-802-1q-tagging` |
| 18 | 25 | `interface-configuration-and-link-aggregation` |
| 19 | 26 | `spanning-tree` |
| 20 | 27 | `mtu-and-jumbo-frames` |
| 21 | 28 | `the-routing-table-and-static-routes` |
| 22 | 29 | `dynamic-routing-protocols` |
| 23 | 30 | `route-selection` |
| 24 | 09 | `vlsm-and-planning-an-address-space` |
| 25 | 31 | `nat-and-pat` |
| 26 | 32 | `fhrp-vip-and-subinterfaces` |
| 27 | 06 | `topologies-and-architectures` |
| 28 | 20 | `sdn-sd-wan-and-vxlan` |
| 29 | 18 | `wireless-and-cellular-media` |
| 30 | 33 | `wireless-channels-and-frequencies` |
| 31 | 34 | `ssids-network-types-and-access-points` |
| 32 | 35 | `wireless-security-and-authentication` |
| 33 | 51 | `security-vocabulary-and-the-cia-triad` |
| 34 | 52 | `encryption-certificates-and-pki` |
| 35 | 53 | `identity-and-access-management` |
| 36 | 37 | `network-documentation-and-diagrams` |
| 37 | 38 | `lifecycle-change-and-configuration-management` |
| 38 | 39 | `snmp` |
| 39 | 40 | `flow-data-capture-and-port-mirroring` |
| 40 | 41 | `baselines-alerting-and-monitoring-solutions` |
| 41 | 42 | `disaster-recovery` |
| 42 | 43 | `dhcp` |
| 43 | 44 | `ipv6-address-assignment-and-slaac` |
| 44 | 45 | `how-dns-resolution-works` |
| 45 | 04 | `what-happens-when-you-open-a-web-page` |
| 49 | 14 | `ip-protocols-and-tunnelling` |
| 50 | 49 | `vpns` |
| 51 | 50 | `managing-devices-remotely` |
| 52 | 54 | `physical-security-and-deception` |
| 53 | 55 | `compliance-and-audits` |
| 54 | 60 | `acls-filtering-and-security-zones` |
| 55 | 56 | `network-segmentation` |
| 56 | 57 | `layer-2-attacks` |
| 57 | 58 | `attacks-on-services-and-people` |
| 58 | 59 | `device-hardening-and-network-access-control` |
| 59 | 19 | `cloud-concepts-and-connectivity` |
| 60 | 21 | `zero-trust-sase-and-infrastructure-as-code` |
| 62 | 72 | `ping-traceroute-and-what-they-prove` |
| 63 | 74 | `connection-and-interface-tools` |
| 64 | 73 | `name-resolution-tools` |
| 65 | 62 | `narrowing-a-fault-by-layer` |
| 66 | 63 | `cable-faults-and-signal-problems` |
| 67 | 64 | `interface-counters-and-port-status` |
| 68 | 65 | `poe-and-transceiver-problems` |
| 69 | 66 | `switching-faults-loops-and-vlans` |
| 70 | 67 | `routing-and-default-gateway-faults` |
| 71 | 68 | `addressing-faults` |
| 72 | 71 | `wireless-performance-and-roaming` |
| 73 | 75 | `packet-capture-and-protocol-analysis` |
| 74 | 76 | `discovery-tools-and-device-commands` |
| 75 | 69 | `bandwidth-congestion-and-bottlenecks` |
| 76 | 70 | `latency-jitter-and-packet-loss` |

## Objective coverage check

Every objective, and the topics that carry it. This is the table the generated
coverage report reproduces from frontmatter once the topics exist. **Every
objective has at least one topic**, which is the rule the plan had to satisfy
before anything else.

| Obj | Topics |
| --- | --- |
| 1.1 | 01, 02, 03, 45 |
| 1.2 | 04 |
| 1.3 | 59 |
| 1.4 | 02, 09, 10, 15, 45, 49 |
| 1.5 | 11, 12, 29 |
| 1.6 | 27 |
| 1.7 | 05, 06, 07, 24 |
| 1.8 | 08, 28, 60 |
| 2.1 | 21, 22, 23, 25, 26 |
| 2.2 | 14, 16, 17, 18, 19, 20 |
| 2.3 | 30, 31, 32 |
| 2.4 | 13 |
| 3.1 | 36, 37 |
| 3.2 | 38, 39, 40 |
| 3.3 | 41 |
| 3.4 | 42, 43, 44, 46, 47, 48 |
| 3.5 | 50, 51 |
| 4.1 | 33, 34, 35, 52, 53, 55 |
| 4.2 | 56, 57 |
| 4.3 | 54, 58 |
| 5.1 | 61, 65 |
| 5.2 | 66, 67, 68 |
| 5.3 | 19, 69, 70, 71 |
| 5.4 | 72, 75, 76 |
| 5.5 | 62, 63, 64, 73, 74 |

Two objectives carry one topic each, 1.2 and 2.4, and both are deliberate: they
are single-subject objectives and splitting them would produce two thin pages
instead of one complete one.

**The eleven acronym-only technologies** from the research document each get a
sentence, in these topics: IS-IS and RIP in 29, RSTP in 26, LACP in 25, EAPoL in
59, CAM in 22, MDIX in 63, SOA in 46, UTM in 05, DLP in 55, WPS in 35. None gets a
section. That is the whole treatment, and it is deliberate.

## Capture feasibility

| Capture route | Topics |
| --- | --- |
| **netlab** (namespace topology) | 01, 02, 03, 05, 07, 08, 09, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 25, 26, 28, 39, 42, 43, 44, 45, 46, 47, 49, 54, 55, 56, 58, 62, 63, 64, 65, 67, 69, 70, 71, 73, 74, 75, 76 |
| **container** (`capture.sh <distro>`) | 06, 10, 24, 34, 35, 38, 40, 48, 51, 60 |
| **documented** | 04, 11, 12, 13, 27, 29, 30, 31, 32, 33, 36, 37, 41, 50, 52, 53, 57, 59, 61, 66, 68, 72 |

**54 of 76 topics carry real captured output.** That is a higher
proportion than the Linux+ plan predicted for itself and about the same as what it
achieved, which is reassuring rather than surprising: networking is unusually
reproducible in software once you accept that a Linux bridge is a real switch.

The twenty-three documented-only topics are the ones the research document
predicted: physical media, wireless radio, cloud, process, and the conceptual half
of security. Every one of them is a topic where the honest answer is that there is
nothing to run, and each will say so in its provenance line rather than dressing a
hand-written block as a capture.

**Wireless is the biggest gap and it is unavoidable.** Five topics, no radio.
Their output comes from standards documents and vendor documentation, and the
prose says which. If a USB wireless adapter ever gets passed through to the podman
machine, topics 33 through 35 and 71 are the ones to revisit.

## The netlab script

New tooling, sibling to `capture.sh` rather than a mode inside it, because the
mental model is genuinely different: `capture.sh` runs a command on one machine,
`netlab.sh` builds a network and runs a command on one node of it.

```
blog/scripts/netlab.sh --topo topologies/two-routers.sh --node h1 -- traceroute -n 10.10.2.2
```

How it works, all of it proven before this plan was written:

1. Starts one **privileged container** on the podman machine from an image pinned
   by digest, with the tools the topology needs.
2. Sources a **topology file**, a short shell script that creates namespaces,
   `veth` pairs, bridges, addresses, and routes. Topologies live in
   `blog/scripts/topologies/` and are committed, so a transcript is reproducible.
3. Runs the captured command inside one named namespace with `ip netns exec`.
4. Emits a fenced block headed with the image label, the architecture, and the
   topology name, so a reader can see what produced it.
5. Exits, which tears down every namespace with the container.

The pieces already demonstrated on this machine: multi-hop routing with a real
TTL decrement, a VLAN-filtering bridge with tags visible in a capture, spanning
tree converging with a port genuinely blocked, FRRouting learning an OSPF route
with its administrative distance in the output, a complete DHCP exchange in both
the server log and a packet capture, NAT observed from the far side, and an
authoritative DNS answer with the flag set. Details and output are in
[the research document](network-plus-n10-009-research.md#where-output-can-come-from).

**Five things need building that do not exist yet.**

1. **A setup-image cache** keyed on the base digest and the package list, for the
   same reason `capture.sh --script` grew one: FRR and BIND are slow to install
   and a topic needs a dozen captures.
2. **A per-topology convergence wait**, declared rather than constant. Spanning
   tree is about 30 seconds, OSPF about 40, LACP about 12.
3. **Rootful execution** through the `podman-machine-default-root` connection,
   which already exists. Rootless privileged fails at `ip netns exec` with
   `rc=255` and the kernel says why every time: `mount of /sys failed: Operation
   not permitted`. Do not reach for nested `podman machine ssh sudo podman run`,
   which puts every captured command through another quoting layer, and do not
   run `podman machine set --rootful`, which hides the Linux+ capture images
   behind separate root storage.
4. **A per-node `/run` bind mount** inside the mount namespace `ip netns exec`
   already creates. Two `lldpd` instances in two namespaces otherwise collide on
   one control socket. No `unshare --mount` is needed.
5. **A provenance header carrying the podman machine OS and kernel version**, not
   just the container digest. The digest does not pin the kernel, and on this
   tooling the kernel is what produces the behaviour.

Items 3 and 4 are the difference between `netlab.sh` working and appearing to
work, and all 43 netlab topics sit behind them.

## Diagrams worth building

Inline SVG, theme-aware, only where the concept is structural. Marked essential
where the topic does not work without one.

| Topic | Diagram | |
| --- | --- | --- |
| 02 | One frame, showing the MAC, IP, and port fields at their three layers | essential |
| 03 | The seven layers, with what each header adds and where it is removed | essential |
| 04 | Where each device sits in a path, and how far into the frame each one reads | essential |
| 05 | 32 bits with the mask boundary drawn through them | essential |
| 08 | An IPv6 address broken into prefix, subnet, and interface identifier | |
| 09 | The three-way handshake and the teardown | essential |
| 13 | The path from a desk to the intermediate frame to the main frame | |
| 14 | A switch learning two MAC addresses and flooding the third frame | essential |
| 17 | The 802.1Q tag in position inside an Ethernet frame | essential |
| 19 | The triangle of switches with the blocked port marked | essential |
| 21 | Longest prefix match choosing between three candidate routes | essential |
| 25 | The translation table, with one inside address and two flows | essential |
| 26 | Virtual IP moving between two routers at failover | |
| 27 | Star, mesh, spine and leaf, and three-tier side by side at one scale | essential |
| 30 | Channel overlap across the 2.4 GHz band | essential |
| 42 | The four DHCP messages, with the relay variant alongside | essential |
| 44 | Recursive resolution from stub resolver to root to authoritative | essential |
| 45 | The sequence of a page load, as a time axis across four parties | essential |
| 49 | A packet inside a GRE header inside an IPSec header | |
| 50 | Split tunnel against full tunnel, as two traffic paths | |
| 54 | The screened subnet with the two firewalls and three zones | essential |
| 65 | The layer ladder as a decision tree rather than a list | |
| Topic | Diagram | |
| --- | --- | --- |

## Question banks

Five banks, one per domain, in `src/data/quizzes/network-plus/`. Ids are
`np-<domain>-NNN`, following the `lp-` convention.

`quiz-validate.ts` sets `POOL_MULTIPLE` to 3, so a bank has to hold three times
its domain's weighted share of a 90-question exam or the build warns. That is the
number that stops a full attempt from drawing the entire pool and making the
shuffle decorative.

| Bank | Weight | Weighted share | Pool target |
| --- | --- | --- | --- |
| `domain-1-networking-concepts.json` | 23% | 21 | 63 |
| `domain-2-network-implementation.json` | 20% | 18 | 54 |
| `domain-3-network-operations.json` | 19% | 17 | 51 |
| `domain-4-network-security.json` | 14% | 13 | 39 |
| `domain-5-network-troubleshooting.json` | 24% | 22 | 66 |
| **Total** | | **91** | **273** |

That 91 is the sum of the per-domain weighted shares, and it is not the length of
the exam. Rounding each weight against 90 questions gives 21+18+17+13+22, which
overshoots by one. XK0-006's weights happen to round to exactly 90, which is why
the three places that compute this (`Quiz.astro`, `exam.astro` and
`quiz-validate.ts`) have never had to reconcile it. They need a shared
`weightedShares(exam)` helper doing largest-remainder reconciliation before the
weighted exam runs for this track, or it will serve 91 questions for a
90-question exam.

**273 questions, and every one of the 25 objectives needs at least one.** Question
and option order are already shuffled per attempt by the existing engine, so the
pool size is the only thing standing between a second attempt and the first one
repeated.

The authoring standard applies unchanged, including the input rule that matters
most: written from the objectives document and vendor documentation only, never
from a braindump, never from anyone's memory of a real exam, and nothing labelled
as real, actual, or leaked. The build enforces the labelling part; the input rule
is a discipline.

Two things this exam changes about question writing. **Domain 5 is the biggest
bank**, which is unusual and correct. And **the tool questions have to name the
tools CompTIA names**, so a stem asking which command shows listening connections
has `netstat` as its answer and not `ss`, with the explanation making the reason
explicit rather than leaving a Linux engineer thinking the key is wrong.

## Infrastructure changes this track needs

Small, and all of them exist because the platform was built for one certification
track and is about to have two.

| Change | Why | Risk |
| --- | --- | --- |
| Add `n10-009` to `src/config/exams.ts` and point `network-plus` at it in `EXAM_FOR_TRACK` | Everything derives from this: coverage, plan, exam, question validation | None. The file already validates weights and duplicate objectives at load. |
| Add a `network-plus` entry to `src/config/tracks.ts` | Display name must be "CompTIA Network+", per the trademark rule | None |
| Make the comparison table per-track, in four places not one | `distributions.ts` hardcodes the section regex, a RHEL and Debian column-name gate, and its label-heading list; `compare-tables.mjs` hardcodes the rendered heading | Medium, and it fails silently if missed. The column gate drops any table whose headings are not distribution names, so an "Across platforms" table builds clean and renders nothing. |
| Give the comparison table a blank first heading | The Linux+ convention is `\| \| RHEL family \| Debian family \|`. A "Task" heading either needs adding to the label list or the table gets a five-cell header over four-cell rows | Trivial, if decided before any topic is written |
| Add a `weightedShares(exam)` helper | N10-009's weights round to 91 against a 90-question exam. Three call sites compute this independently | Small. Under an hour, and it is wrong for this track from day one without it |
| Give the aggregate comparison page a per-track slug | Linux+ keeps `/learn/linux-plus/distributions`, which `test/distributions.test.mjs` asserts; Network+ gets `/learn/network-plus/platforms` | Low, if done by extracting the page into a shared component and leaving two thin route files. Renaming the route would break the existing test and the existing URL. |
| Rename `src/lib/distributions.ts` to something track-neutral | It will be collecting platform tables as well as distribution tables | Low, mechanical |

The generated comparison page follows the existing convention: **it shows what it
has and does not explain what it left out.** The earlier version of the
distributions page listed its own exclusions and it confused people.

## Suggested authoring order

Not reading order. This order front-loads the decisions that are expensive to
revisit and gets a preview environment building early.

1. **Exam entry, track entry, and the empty content directory.** One commit,
   nothing to read yet, and the coverage route starts working.
2. **`netlab.sh` and the first three topology files.** The tooling before the
   content, exactly as Linux+ did it, because a topic written before the capture
   tooling exists gets written from memory.
3. **Two topics as the pattern**, and then stop. Recommend **26 spanning tree**
   and **72 ping and traceroute**: one implementation topic with heavy captured
   output and one troubleshooting topic, which is the template most likely to need
   revision once it exists on a page. Not two adjacent topics.
4. **Review those two together** before writing a third.
5. **Block A**, which sets the voice for a beginner audience.
6. **Blocks B and C**, the largest captured-output blocks, in order.
7. **Block F**, while the implementation detail is fresh, because the
   troubleshooting topics reference it constantly.
8. **Blocks D and E.**
9. **Question banks**, per domain, after that domain's topics exist, so `learnRef`
   and `learnAnchor` point at real headings.
10. **The verification pass.** Every claim either executed or checked against
    upstream documentation, and every citation URL fetched.

Step 10 is not optional and it is not a formality. The equivalent pass on Linux+
found eleven errors in finished, reviewed content, and every one of them was the
same shape: the right idea stated a notch wider than it should have been, or a
version out of date. None of them was a fact backwards, which is exactly why
reading never caught them and running things did.
