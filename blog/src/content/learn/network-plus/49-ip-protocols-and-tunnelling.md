---
title: "IP protocols and tunnelling"
description: "The field in the IP header that says what the payload is, and what happens when the answer is another packet. GRE and IPSec captured from the middle, where one of them shows you everything."
deck: "The packet has a header inside another header"
track: "network-plus"
level: "working"
order: 500
objectives:
  - "Distinguish a protocol number from a port number"
  - "Say what ICMP is for and why it is not TCP or UDP"
  - "Explain what GRE does and what it deliberately does not do"
  - "Name the parts of IPSec and say what each contributes"
  - "Distinguish transport mode from tunnel mode"
prerequisites: ["ports-and-the-protocols-that-use-them"]
tags: ["network-plus", "networking", "fundamentals"]
updated: 2026-08-13
draft: false
examObjectives:
  - exam: "n10-009"
    domain: "1.0"
    objective: "1.4"
sources:
  - title: "RFC 791, Internet Protocol"
    url: "https://www.rfc-editor.org/rfc/rfc791"
    publisher: "IETF"
    accessed: 2026-08-13
    tier: 1
  - title: "RFC 792, Internet Control Message Protocol"
    url: "https://www.rfc-editor.org/rfc/rfc792"
    publisher: "IETF"
    accessed: 2026-08-13
    tier: 1
  - title: "RFC 2784, Generic Routing Encapsulation"
    url: "https://www.rfc-editor.org/rfc/rfc2784"
    publisher: "IETF"
    accessed: 2026-08-13
    tier: 1
  - title: "RFC 4301, Security Architecture for the Internet Protocol"
    url: "https://www.rfc-editor.org/rfc/rfc4301"
    publisher: "IETF"
    accessed: 2026-08-13
    tier: 1
  - title: "Protocol Numbers registry"
    url: "https://www.iana.org/assignments/protocol-numbers/protocol-numbers.xhtml"
    publisher: "IANA"
    accessed: 2026-08-13
    tier: 1
symptoms:
  - symptom: "A firewall permits TCP and UDP and the tunnel still will not come up"
    anchor: "the-field-that-says-what-is-inside"
  - symptom: "Traffic works until a large packet is sent"
    anchor: "everything-costs-header-space"
  - symptom: "A capture shows only outer addresses"
    anchor: "the-same-packet-wrapped-two-ways"
---

> **Before you read.** A site to site tunnel will not establish. The firewall
> team confirm that all TCP and all UDP is permitted between the two public
> addresses, in both directions, and they are telling the truth.
>
> **Why does that not settle it?**

Ports are the field everybody knows. This topic is about the field one layer
below, which decides what a port number would even mean, and about what happens
when the thing inside an IP packet turns out to be another IP packet.

### Some words you will need

<dl class="terms">
<dt>protocol number</dt>
<dd>A field in the IP header saying what the payload is. TCP is 6, UDP is 17.</dd>
<dt>ICMP</dt>
<dd>The protocol IP uses to report on itself. Protocol 1, and it has no ports.</dd>
<dt>encapsulation</dt>
<dd>Putting one packet inside another so it can cross a network that would not carry it.</dd>
<dt>GRE</dt>
<dd>Generic Routing Encapsulation. A wrapper, protocol 47, with no security in it.</dd>
<dt>IPSec</dt>
<dd>A set of protocols that authenticate and encrypt IP packets.</dd>
<dt>SA</dt>
<dd>Security association. The agreed keys and parameters for one direction of an IPSec conversation.</dd>
</dl>

## What breaks without this

**A tunnel will not come up through a firewall** that permits every port there
is, because what it carries is not addressed by a port at all.

**Traffic works until somebody sends a large file.** Every wrapper costs header
space, and the packet that no longer fits is the one that fails.

**A capture shows nothing useful** and somebody concludes the traffic is
encrypted when it is merely wrapped.

## The field that says what is inside

An IP header carries a protocol field, one byte, and its value says how to read
everything after the header. TCP is 6 and UDP is 17, and those two are so common
that people forget the field exists.

**ICMP is protocol 1 and it has no ports at all.** That is the cleanest way to see
why the two fields are different things: a port number lives inside a TCP or UDP
header, so a protocol with neither has nowhere to put one. A firewall rule
permitting "all ports" says nothing about ICMP, which is why `ping` and firewall
rules produce so much confusion.

ICMP exists so IP can report on itself: destination unreachable, time exceeded,
and the fragmentation needed message that topic 20 showed path MTU discovery
depending on. Blocking it wholesale is a decision with consequences that appear
weeks later as connections that hang on large transfers.

**GRE is protocol 47 and IPSec's encapsulating payload is protocol 50.** Neither
is TCP or UDP, so neither is described by any rule about ports, which is the
answer to the question at the top of this page. The firewall team permitted every
port and the tunnel uses a protocol that has none.

Every machine carries the registry, next to the one topic 10 read for ports.

```powershell
# Microsoft Windows Server 2025 Datacenter, version 10.0.26100.0
> Get-Content "$env:SystemRoot\System32\drivers\etc\protocol" | Select-String -Pattern "^(icmp|igmp|tcp|udp|gre|esp|ah|ipv6-icmp)\s"
icmp       1     ICMP         # Internet control message protocol
tcp        6     TCP          # Transmission control protocol
udp        17    UDP          # User datagram protocol
esp        50    ESP          # Encapsulating security payload
ah         51    AH           # Authentication header
ipv6-icmp  58    IPv6-ICMP    # ICMP for IPv6
```

```bash
# macOS 26.5.2, arm64
$ grep -E "^(icmp|igmp|tcp|udp|gre|esp|ah|ipv6-icmp)[[:space:]]" /etc/protocols
icmp	1	ICMP		# internet control message protocol
igmp	2	IGMP		# internet group management protocol
tcp	6	TCP		# transmission control protocol
udp	17	UDP		# user datagram protocol
gre	47	GRE		# Generic Routing Encapsulation
esp	50	ESP		# encapsulating security payload
ah	51	AH		# authentication header
ipv6-icmp	58	IPV6-ICMP	icmp6	# ICMP for IPv6
```

Same numbers, same meanings, two files that most people never open. IANA
maintains the list and it is the authority for both.

<details class="deeper">
<summary>If you already write firewall rules: the protocols that have no ports, and what that costs</summary>

Most filtering is written in terms of ports, and several of the protocols named by that
field do not have any, which changes how they can be controlled.

ICMP has types and codes rather than ports. The encapsulating security payload used by
IPSec has neither: it is its own protocol number carrying an encrypted blob. GRE is the
same. So a rule permitting them is a rule permitting the protocol between two addresses,
with no finer control available, and that is a coarser permission than anybody is used to
writing.

The practical consequences show up in two places. Devices that translate addresses need
per-protocol handling for anything without ports, which is why the encapsulating security
payload traverses translation badly and why a variant that wraps it in UDP exists purely
to give it a port to be translated by. And filtering ICMP by convenience, because it has
no ports and looks droppable wholesale, breaks path MTU discovery and produces the black
hole in topic 20.

The habit worth having is to treat the protocol field as the first thing a rule selects
on rather than an afterthought, and to know which protocols on your network have no
second level of selection available. Those are the ones where the permission is
all-or-nothing and the design has to compensate elsewhere.

</details>

## The same packet, wrapped two ways

Encapsulation is putting a packet inside another packet. What the wrapper does
beyond that is the whole difference between the two you need to know.

<figure class="learn-figure">
<svg viewBox="0 0 720 208" role="img" aria-labelledby="encap-title" style="width:100%;height:auto;">
<title id="encap-title">The same packet wrapped in GRE and wrapped in IPSec, showing that the inner header and payload are readable in one and encrypted in the other</title>
<g fill="currentColor">
<text x="14" y="22" font-size="11">the same inner packet, wrapped two ways</text>
<text x="14" y="74" font-size="10.5" fill-opacity="0.85">GRE</text>
<rect x="110" y="52" width="150" height="34" rx="2" fill="currentColor" fill-opacity="0.2" stroke="currentColor" stroke-opacity="0.7"/>
<text x="185" y="74" text-anchor="middle" font-size="10">outer IP</text>
<rect x="260" y="52" width="86" height="34" rx="2" fill="currentColor" fill-opacity="0.2" stroke="currentColor" stroke-opacity="0.7"/>
<text x="303" y="74" text-anchor="middle" font-size="10">GRE</text>
<rect x="346" y="52" width="150" height="34" rx="2" fill="currentColor" fill-opacity="0.1" stroke="currentColor" stroke-opacity="0.7"/>
<text x="421" y="74" text-anchor="middle" font-size="10">inner IP</text>
<rect x="496" y="52" width="200" height="34" rx="2" fill="currentColor" fill-opacity="0.1" stroke="currentColor" stroke-opacity="0.7"/>
<text x="596" y="74" text-anchor="middle" font-size="10">ICMP echo request</text>
<text x="14" y="102" font-size="9.5" fill-opacity="0.7">protocol 47 in the outer header</text>
<text x="14" y="162" font-size="10.5" fill-opacity="0.85">IPSec ESP</text>
<rect x="110" y="140" width="150" height="34" rx="2" fill="currentColor" fill-opacity="0.2" stroke="currentColor" stroke-opacity="0.7"/>
<text x="185" y="162" text-anchor="middle" font-size="10">outer IP</text>
<rect x="260" y="140" width="86" height="34" rx="2" fill="currentColor" fill-opacity="0.2" stroke="currentColor" stroke-opacity="0.7"/>
<text x="303" y="162" text-anchor="middle" font-size="10">ESP</text>
<rect x="346" y="140" width="350" height="34" rx="2" fill="var(--red)" fill-opacity="0.16" stroke="var(--red)" stroke-opacity="0.7"/>
<text x="521" y="162" text-anchor="middle" font-size="10">everything else</text>
<text x="14" y="190" font-size="9.5" fill-opacity="0.7">protocol 50 in the outer header</text>
</g></svg>
<figcaption>Both wrappers do the same structural job and cost the same twenty bytes of outer IP header on every packet, which is where the MTU problem in topic 20 comes from. The difference is what survives to be read. GRE adds four bytes and nothing else: no encryption, no authentication, no protection of any kind, and the inner packet sits behind it in plain view. That is not an oversight, it is the design, and RFC 2784 is a short document because there is very little to specify. ESP replaces the visible interior with ciphertext, so an observer learns the two tunnel endpoints, the amount of traffic and its timing, and nothing else. Choosing between them is not a choice between two grades of tunnel: one is a delivery mechanism and the other is a delivery mechanism with a guarantee attached.</figcaption>
</figure>

Building a GRE tunnel and watching from the middle shows exactly how little it
conceals.

<details class="predict">
<summary>A packet for the far site is handed to a tunnel. What does it look like on the public link in the middle, and how many headers does it carry?</summary>

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology two-sites
# one GRE tunnel, built from both ends
$ ip netns exec ra ip link add gre1 type gre local 198.51.100.1 remote 198.51.100.2 ttl 64
$ ip netns exec ra ip addr add 172.16.0.1/30 dev gre1
$ ip netns exec ra ip link set gre1 up
$ ip netns exec ra ip route add 10.2.0.0/24 dev gre1
$ ip netns exec rb ip link add gre1 type gre local 198.51.100.2 remote 198.51.100.1 ttl 64
$ ip netns exec rb ip addr add 172.16.0.2/30 dev gre1
$ ip netns exec rb ip link set gre1 up
$ ip netns exec rb ip route add 10.1.0.0/24 dev gre1
# watch from the middle of the public network, where neither end of the tunnel is
$ (ip netns exec swm timeout 10 tcpdump -i br0 -n > /tmp/gre.txt 2>/dev/null &)
$ sleep 2
$ ip netns exec lana ping -c 2 -W 2 -q 10.2.0.2 | tail -1
rtt min/avg/max/mdev = 0.092/0.121/0.150/0.029 ms
$ sleep 9
$ grep -a "GREv0" /tmp/gre.txt | head -2
16:20:11.023373 IP 198.51.100.1 > 198.51.100.2: GREv0, length 88: IP 10.1.0.2 > 10.2.0.2: ICMP echo request, id 132, seq 1, length 64
16:20:11.023415 IP 198.51.100.2 > 198.51.100.1: GREv0, length 88: IP 10.2.0.2 > 10.1.0.2: ICMP echo reply, id 132, seq 1, length 64
```

</details>

Read the last two lines carefully. One line contains the outer addresses, the
word GREv0, the inner addresses, and the fact that the payload is an ICMP echo
request. An observer in the middle knows which two private machines are talking
and what they are saying.

**GRE is useful precisely because it is simple.** It will carry anything,
including protocols that are not IP at all, and routing protocols will run over
it, which is why it turns up as the thing carrying traffic that IPSec then
protects. The two are frequently used together rather than as alternatives.

Now the same two sites, the same ping, the same observer, with IPSec instead.

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology two-sites
# the same two sites, joined by IPSec in tunnel mode instead of GRE
$ ip netns exec ra ip route add 10.2.0.0/24 via 198.51.100.2
$ ip netns exec rb ip route add 10.1.0.0/24 via 198.51.100.1
$ ip netns exec ra ip xfrm state add src 198.51.100.1 dst 198.51.100.2 proto esp spi 0x1001 mode tunnel aead "rfc4106(gcm(aes))" 0x0102030405060708090a0b0c0d0e0f1011121314 128
$ ip netns exec ra ip xfrm state add src 198.51.100.2 dst 198.51.100.1 proto esp spi 0x1002 mode tunnel aead "rfc4106(gcm(aes))" 0x1112131415161718191a1b1c1d1e1f2021222324 128
$ ip netns exec ra ip xfrm policy add src 10.1.0.0/24 dst 10.2.0.0/24 dir out tmpl src 198.51.100.1 dst 198.51.100.2 proto esp mode tunnel
$ ip netns exec ra ip xfrm policy add src 10.2.0.0/24 dst 10.1.0.0/24 dir fwd tmpl src 198.51.100.2 dst 198.51.100.1 proto esp mode tunnel
$ ip netns exec rb ip xfrm state add src 198.51.100.1 dst 198.51.100.2 proto esp spi 0x1001 mode tunnel aead "rfc4106(gcm(aes))" 0x0102030405060708090a0b0c0d0e0f1011121314 128
$ ip netns exec rb ip xfrm state add src 198.51.100.2 dst 198.51.100.1 proto esp spi 0x1002 mode tunnel aead "rfc4106(gcm(aes))" 0x1112131415161718191a1b1c1d1e1f2021222324 128
$ ip netns exec rb ip xfrm policy add src 10.2.0.0/24 dst 10.1.0.0/24 dir out tmpl src 198.51.100.2 dst 198.51.100.1 proto esp mode tunnel
$ ip netns exec rb ip xfrm policy add src 10.1.0.0/24 dst 10.2.0.0/24 dir fwd tmpl src 198.51.100.1 dst 198.51.100.2 proto esp mode tunnel
# the same observer, in the same place, watching the same ping
$ (ip netns exec swm timeout 10 tcpdump -i br0 -n > /tmp/esp.txt 2>/dev/null &)
$ sleep 2
$ ip netns exec lana ping -c 2 -W 2 -q 10.2.0.2 | tail -1
rtt min/avg/max/mdev = 0.239/0.355/0.472/0.116 ms
$ sleep 9
$ grep -a "ESP" /tmp/esp.txt | head -2
16:20:24.743134 IP 198.51.100.1 > 198.51.100.2: ESP(spi=0x00001001,seq=0x1), length 120
16:20:24.743220 IP 198.51.100.2 > 198.51.100.1: ESP(spi=0x00001002,seq=0x1), length 120
$ echo "frames mentioning either private address: $(grep -ac "10.1.0.2\|10.2.0.2" /tmp/esp.txt)"
frames mentioning either private address: 0
```

Two packets, the endpoints, a security parameter index, a sequence number, a
length, and nothing else. Zero frames in the entire capture mention either
private address.

**The security parameter index is worth knowing by name.** It identifies which
security association this packet belongs to, which is how the receiving end knows
which keys to use, and it is why IPSec state is directional: each direction has
its own association, its own index, and its own keys.

<details class="deeper">
<summary>If you already build tunnels: why two headers is the common arrangement rather than one</summary>

Stacking a tunnelling protocol inside a security protocol looks redundant and it is the
standard way these are built, for reasons about capability rather than caution.

The security protocol protects and authenticates and, in its usual mode, carries only IP
unicast between two endpoints. It will not carry multicast, it will not carry a routing
protocol's hellos, and it does not present itself as an interface that routes can point
at. The tunnelling protocol does all of those and protects nothing.

Put the tunnel inside the protection and each does what it is good at: the tunnel gives
you an interface, so routing protocols run across it and the path can reconverge on its
own, and the security wrapper makes the whole thing private and authenticated. That is
why the combination is what most site to site designs actually use, and why a design with
only the security protocol usually ends up with static routes and no dynamic failover.

The cost is header size, which is where topic 20's arithmetic arrives. Two wrappers take
a substantial bite out of the payload, and it has to be accounted for at the tunnel
interface rather than discovered later. A tunnel built without adjusting for it works for
everything small and fails for everything large, which is the single most common fault in
a newly built tunnel.

</details>

## The parts of IPSec

The exam names three pieces and they do different jobs.

**AH, the authentication header**, protocol 51, proves a packet came from the
holder of the key and has not been altered, and encrypts nothing. It is rarely
deployed, largely because it covers parts of the outer header and so breaks
through NAT.

**ESP, the encapsulating security payload**, protocol 50, encrypts the payload
and authenticates it. This is what almost every deployment uses, and it is what
the capture above shows.

**IKE, the internet key exchange**, is the negotiation that establishes the keys
and the parameters. It runs over UDP port 500, and over UDP 4500 when NAT
traversal is in use, which is the one part of IPSec that does have a port number
and the reason a firewall rule can permit the negotiation while blocking the
tunnel that follows.

**Transport mode and tunnel mode** are the last distinction. Transport mode
protects the payload and keeps the original IP header, so it works between two
hosts that are talking directly. Tunnel mode wraps the whole original packet,
header included, in a new one, which is what lets two gateways carry traffic on
behalf of the networks behind them. Site to site is tunnel mode, and the capture
above is tunnel mode, which is why the private addresses were inside rather than
on the outside.

<details class="deeper">
<summary>If you already work on networks: why the MTU problem lands on tunnels harder than anything else, and the specific way it fails</summary>

Every tunnel adds bytes to every packet, and the bytes come off the payload the
tunnel can carry. On a 1500 byte link, GRE leaves 1476 and IPSec in tunnel mode
leaves somewhere near 1400 depending on the algorithms, which is why 1400 is such
a common number in tunnel configuration.

The failure this produces is one of the most distinctive in networking, and it is
worth being able to recognise from the description alone. **Small things work and
large things hang.** Logins succeed, a `ping` succeeds, a web page loads its HTML
and stalls on an image, a file copy starts and freezes. The connection is
established, so the fault does not look like connectivity.

The mechanism is path MTU discovery, from topic 20. A sender emits a full sized
packet with the do not fragment bit set. The tunnel endpoint cannot fit it, so it
should return an ICMP fragmentation needed message telling the sender to use a
smaller size. If that message is blocked, and it very often is, because ICMP gets
filtered wholesale by people who think of it as `ping`, the sender learns nothing.
It retransmits the same too-large packet forever, and the connection hangs rather
than fails.

The name for this is a path MTU black hole, and there are two fixes. Permit ICMP
type 3 code 4 through the firewalls, which is the correct one and requires
somebody to be persuaded. Or clamp the TCP maximum segment size on the tunnel
interface, which rewrites the value the two ends negotiate during the handshake so
they never try to send anything too large. Clamping is what almost everybody does,
it is one line on most equipment, and it works only for TCP, which is worth
remembering the day somebody tunnels something else.

</details>

## Prove it

**Read your own protocol registry.** The file is on every machine you own and
most people have never opened it. Find GRE and ESP in it.

**Look for protocol numbers in a firewall rule.** On any firewall you administer,
find where a rule specifies a protocol rather than a port, and notice how
differently it is expressed.

**Capture a ping and look at the protocol field.** It is 1, and there is nowhere
in the packet a port number could go.

## What trips people up

### 1. Treating protocol numbers and port numbers as the same thing

The protocol number is in the IP header and says what the payload is. A port
number is inside a TCP or UDP header, so a protocol that is neither has no ports.

### 2. Assuming a rule permitting all ports permits everything

GRE, ESP and ICMP are addressed by protocol number. A rule about ports does not
mention them.

### 3. Expecting GRE to protect anything

It adds four bytes and no security whatsoever. The inner packet is fully readable
to anybody on the path.

### 4. Thinking IPSec is one protocol

It is a negotiation over UDP 500, and then ESP as protocol 50 or AH as protocol
51. A firewall can permit the negotiation and block the traffic that follows.

### 5. Confusing transport mode with tunnel mode

Transport mode keeps the original header and protects the payload, between two
hosts. Tunnel mode wraps the entire original packet, which is what gateways need
to carry traffic for the networks behind them.

### 6. Blocking ICMP and then debugging the tunnel

Path MTU discovery depends on an ICMP message. Blocking it turns a size problem
into a connection that establishes and then hangs on anything large.

## Work it through

The tunnel that will not come up through a firewall permitting all TCP and all
UDP.

The reason that is not a contradiction is the protocol field. A site to site
IPSec tunnel needs at least two things through: UDP port 500 for the key
exchange, which the rule does cover, and protocol 50 for the traffic itself,
which it does not mention at all. A GRE tunnel needs protocol 47 and no ports
whatsoever.

**So the question to take back is not about ports.** It is whether the firewall
permits IP protocol 50, or 47, between those two addresses, and that is a
different kind of rule that somebody has to write deliberately.

The symptom usually tells you which half is missing before anybody looks. If the
negotiation completes and the tunnel reports itself up but no traffic passes, UDP
500 is getting through and protocol 50 is not, which is the common case because
the port rule covers one and not the other. If nothing happens at all, the
negotiation itself is blocked.

**Two further things worth checking while you are there**, because both produce a
tunnel that comes up and does not work properly.

If there is NAT anywhere on the path, the negotiation should have detected it and
moved to UDP 4500, and that port needs permitting too. A tunnel that works from
one site and not another, where the difference is a NAT gateway, is this.

And once traffic does pass, test with something large before declaring it fixed.
The MTU arithmetic in the deeper panel means a tunnel can carry every small packet
perfectly and hang on the first full sized one, and that fault will be reported a
week later as an unrelated application problem.

## Try it

**Build a GRE tunnel between two machines.** It is four commands per end and it
works over anything. Then capture the middle and read the inner packet.

**Add ESP to the same pair.** Then capture again and notice how much less there is
to see.

**Send a large ping through a tunnel.** `ping -s 1500` with the do not fragment
bit set, and watch what happens. That is the MTU problem in one command.

## Check yourself

<details class="qa">
<summary>A firewall permits all TCP and all UDP between two sites and an IPSec tunnel will not pass traffic. Why?</summary>

Because the traffic is not TCP or UDP. ESP is IP protocol 50 and is identified by
the protocol field in the IP header, which has no ports in it for a port rule to
match.

The key exchange runs over UDP port 500 and is covered by the rule, which is why
the tunnel frequently negotiates successfully and then carries nothing. The
firewall needs a rule permitting protocol 50 explicitly.

</details>

<details class="qa">
<summary>What is the difference between a protocol number and a port number?</summary>

The protocol number is a field in the IP header saying how to interpret the
payload: 1 for ICMP, 6 for TCP, 17 for UDP, 47 for GRE, 50 for ESP.

A port number lives inside a TCP or UDP header, so it only exists when the
protocol number is 6 or 17. ICMP has no ports at all, which is the clearest
demonstration that the two fields are at different layers and answer different
questions.

</details>

<details class="qa">
<summary>What does GRE provide, and what does it not?</summary>

It provides encapsulation and nothing else: a four byte header that lets one
packet be carried inside another, including packets that are not IP. It will carry
routing protocols and multicast, which is why it is so often the thing inside an
IPSec tunnel.

It provides no encryption, no authentication and no integrity checking. A capture
from anywhere on the path shows the inner addresses and the inner payload in
full.

</details>

<details class="qa">
<summary>What is the difference between transport mode and tunnel mode?</summary>

Transport mode protects the payload of a packet and keeps the original IP header,
so it works between two hosts communicating directly with each other.

Tunnel mode wraps the entire original packet, header included, inside a new one
addressed between the two gateways. That is what allows two sites to carry traffic
on behalf of the networks behind them, and it is why the private addresses in a
site to site capture are hidden inside rather than visible on the outside.

</details>

<details class="qa">
<summary>Traffic through a new tunnel works for logins and hangs on file transfers. What is happening?</summary>

The tunnel's headers have reduced the usable packet size, and something is
blocking the ICMP message that would tell the sender about it.

A full sized packet with the do not fragment bit set cannot fit, so the tunnel
endpoint should return a fragmentation needed message. If that is filtered, the
sender never learns and retransmits the same oversized packet indefinitely. Small
packets are unaffected, which is why the connection establishes and only large
transfers hang.

</details>

## References

- [RFC 791](https://www.rfc-editor.org/rfc/rfc791) - IETF, the IP header, including the protocol field. Free. Accessed 2026-08-13.
- [RFC 792](https://www.rfc-editor.org/rfc/rfc792) - IETF, ICMP, including the destination unreachable message path MTU discovery depends on. Free. Accessed 2026-08-13.
- [RFC 2784](https://www.rfc-editor.org/rfc/rfc2784) - IETF, GRE, which is short because there is little to specify. Free. Accessed 2026-08-13.
- [RFC 4301](https://www.rfc-editor.org/rfc/rfc4301) - IETF, the IPSec architecture, including transport and tunnel modes and security associations. Free. Accessed 2026-08-13.
- [RFC 4303](https://www.rfc-editor.org/rfc/rfc4303) - IETF, ESP, for the security parameter index in the capture. Free. Accessed 2026-08-13.
- [Protocol Numbers](https://www.iana.org/assignments/protocol-numbers/protocol-numbers.xhtml) - IANA, the registry both platform captures are copies of. Accessed 2026-08-13.

**Where the output came from.** Both tunnels were built on the `two-sites`
namespace topology through `blog/scripts/netlab.sh`. The topology deliberately
ships with no tunnel in it, so each capture builds its own in the command and the
configuration appears next to its result. Both captures were taken from a
namespace in the middle of the public segment rather than from either endpoint,
which is the only vantage point that makes the comparison honest: a capture on a
tunnel endpoint sees the traffic after decryption and would show the inner packet
in both cases. The IPSec keys are written into the commands because they were
generated for one run of one lab and the container is destroyed afterwards; a real
deployment negotiates them with IKE and never writes them down. The Windows and
macOS blocks came from GitHub Actions runners through `blog/scripts/hostcap.sh`.

**If you also work on Linux.** [firewalld, ufw and nftables](/learn/linux-plus/firewalld-ufw-and-nftables)
on the Linux+ track covers writing the rules this topic says are missing,
including the syntax for matching a protocol rather than a port.
