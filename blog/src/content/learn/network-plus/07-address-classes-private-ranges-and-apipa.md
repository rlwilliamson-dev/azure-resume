---
title: "Address classes, private ranges and APIPA"
description: "Some IPv4 ranges are special and knowing which is worth more than it looks. The classes and why they are obsolete but still examinable, the three private ranges, loopback, and what a 169.254 address is actually reporting."
deck: "The address that tells you what went wrong"
track: "network-plus"
level: "intro"
order: 80
objectives:
  - "Name the five address classes and the range each one covers"
  - "Say why classful addressing is obsolete and where it still shows up"
  - "Recite the three RFC 1918 private ranges, including the awkward one"
  - "Explain what a 169.254 address proves and what it rules out"
  - "Tell a public address from a private one and say what makes the difference"
prerequisites: ["ipv4-addresses-and-the-mask"]
tags: ["network-plus", "networking", "addressing", "beginner"]
updated: 2026-08-10
draft: false
examObjectives:
  - exam: "n10-009"
    domain: "1.0"
    objective: "1.7"
sources:
  - title: "RFC 1918, Address Allocation for Private Internets"
    url: "https://www.rfc-editor.org/rfc/rfc1918"
    publisher: "IETF"
    accessed: 2026-08-10
    tier: 1
  - title: "RFC 3927, Dynamic Configuration of IPv4 Link-Local Addresses"
    url: "https://www.rfc-editor.org/rfc/rfc3927"
    publisher: "IETF"
    accessed: 2026-08-10
    tier: 1
  - title: "RFC 1122, Requirements for Internet Hosts, Communication Layers"
    url: "https://www.rfc-editor.org/rfc/rfc1122"
    publisher: "IETF"
    accessed: 2026-08-10
    tier: 1
  - title: "RFC 5737, IPv4 Address Blocks Reserved for Documentation"
    url: "https://www.rfc-editor.org/rfc/rfc5737"
    publisher: "IETF"
    accessed: 2026-08-10
    tier: 1
  - title: "RFC 6598, IANA-Reserved IPv4 Prefix for Shared Address Space"
    url: "https://www.rfc-editor.org/rfc/rfc6598"
    publisher: "IETF"
    accessed: 2026-08-10
    tier: 1
  - title: "IANA IPv4 Special-Purpose Address Registry"
    url: "https://www.iana.org/assignments/iana-ipv4-special-registry/iana-ipv4-special-registry.xhtml"
    publisher: "IANA"
    accessed: 2026-08-10
    tier: 1
  - title: "How to use automatic TCP/IP addressing without a DHCP server"
    url: "https://learn.microsoft.com/en-us/windows-server/troubleshoot/how-to-use-automatic-tcpip-addressing-without-a-dh"
    publisher: "Microsoft"
    accessed: 2026-08-10
    tier: 1
symptoms:
  - symptom: "An interface has a 169.254 address and no internet access"
    anchor: "a-169-254-address-is-a-diagnosis"
  - symptom: "A machine can reach others on its own segment but nothing beyond"
    anchor: "a-169-254-address-is-a-diagnosis"
---

> **Before you read.** A user says the internet is down. You look at their
> machine and the interface has an address of `169.254.87.12`, a mask of
> `255.255.0.0`, and no default gateway.
>
> The cable is fine. The interface is up. The switch port is live.
>
> **What has already been ruled out, and what has almost certainly happened?**

Most addresses are unremarkable. A handful of ranges are reserved for particular
jobs, and recognising one on sight turns a vague fault report into a short list
of causes. That recognition is the whole of this topic, and the 169.254 case is
the one that pays for itself fastest.

### Some words you will need

<dl class="terms">
<dt>class</dt>
<dd>An obsolete scheme that decided an address's mask from its first few bits. Still named on this exam.</dd>
<dt>private address</dt>
<dd>An address from a range anyone may use internally, which routers on the internet will not carry.</dd>
<dt>public address</dt>
<dd>An address allocated to one organisation, which the internet routes to.</dd>
<dt>loopback</dt>
<dd>An address that refers to the machine itself. Traffic to it never reaches a cable.</dd>
<dt>link-local</dt>
<dd>An address valid only on one segment, which routers must not forward.</dd>
<dt>APIPA</dt>
<dd>Automatic Private IP Addressing, the Windows name for configuring a link-local address when DHCP does not answer.</dd>
</dl>

## What breaks without this

**You troubleshoot the wrong thing for an hour.** A 169.254 address names its own
cause. Not recognising it means checking DNS, the browser, the firewall and the
proxy before arriving at the one thing that was actually wrong.

**You put a private address somewhere it cannot work.** Handing a 10.x address to
something on the public internet produces a service that works from the office
and from nowhere else, and the symptom appears days after the change.

**You lose marks on questions you already understand.** The exam names classes,
ranges and reserved blocks directly. This is the cheapest recall on the syllabus
and it is worth having cold.

## Classes, and why an obsolete idea is still on the exam

Before masks were written down alongside addresses, the first few bits of the
address decided how big the network was. That was the classful scheme, and the
five classes are still named in the objectives.

| Class | Leading bits | First octet | Range | What it was for |
| --- | --- | --- | --- | --- |
| A | 0 | 1 to 126 | 0.0.0.0 to 127.255.255.255 | Very large networks, default /8 |
| B | 10 | 128 to 191 | 128.0.0.0 to 191.255.255.255 | Medium networks, default /16 |
| C | 110 | 192 to 223 | 192.0.0.0 to 223.255.255.255 | Small networks, default /24 |
| D | 1110 | 224 to 239 | 224.0.0.0 to 239.255.255.255 | Multicast |
| E | 1111 | 240 to 255 | 240.0.0.0 to 255.255.255.255 | Reserved |

The first octet column is the one to memorise, because it is how you identify a
class in about a second. The gap in class A is not a typo: 127 is inside class
A's numeric range and is reserved for loopback, which is why the usable first
octet stops at 126.

The scheme collapsed because the sizes were wrong. A class A gave one
organisation 16 million addresses and a class C gave 254, with nothing usable in
between for an organisation needing a few thousand. Classless routing replaced it
by carrying the prefix length with the address, which is the CIDR notation the
last two topics have been using throughout.

Obsolete in this case means genuinely gone rather than deprecated. A modern
machine has no notion of an address's class at all.

<details class="predict">
<summary>A class A address given a /24 mask, and a class C address given a /16. Under classful rules both are illegal. What does the kernel say?</summary>

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology two-hosts
# a class A address with a class C mask, and a class C address with a class B mask
$ ip -n h1 addr add 10.5.5.1/24 dev h1eth0
$ ip -n h1 addr add 192.168.1.1/16 dev h1eth0
$ ip -n h1 addr show h1eth0
4: h1eth0@if3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
    link/ether 02:00:00:00:01:01 brd ff:ff:ff:ff:ff:ff link-netns h2
    inet 10.5.5.1/24 scope global h1eth0
       valid_lft forever preferred_lft forever
    inet 192.168.1.1/16 scope global h1eth0
       valid_lft forever preferred_lft forever
    inet6 fe80::ff:fe00:101/64 scope link tentative proto kernel_ll 
       valid_lft forever preferred_lft forever
$ ip -n h1 route
10.5.5.0/24 dev h1eth0 proto kernel scope link src 10.5.5.1 
192.168.0.0/16 dev h1eth0 proto kernel scope link src 192.168.1.1 
```

</details>

Nothing. Both are accepted without comment, and the routes the kernel derives
follow the masks it was given rather than the classes the addresses belong to.
`10.5.5.1/24` produces a route for `10.5.5.0/24` and not for `10.0.0.0/8`.

<details class="deeper">
<summary>If you already work on networks: the parts of the classful scheme that never went away</summary>

Classes are obsolete as a way of deciding masks. Several things that came out of
the scheme are current, and two of them are not obsolete at all.

**Class D is entirely alive.** Multicast really does live at 224.0.0.0 to
239.255.255.255, that is not history, and protocols you will meet later in this
track use specific addresses in it. OSPF speaks to 224.0.0.5, and any device
sending to 224.0.0.1 is addressing every host on the segment. When a capture
shows a destination beginning 224, the class tells you what kind of traffic it is
before you look at anything else.

**Class E is still reserved** and has been the subject of periodic proposals to
release it, none of which have gone anywhere, largely because too much deployed
software rejects addresses in it outright.

**Some protocols still assume a class.** RIP version 1 carried no masks in its
updates, so a receiving router had to infer the prefix from the address's class.
That is the concrete reason RIPv1 cannot support variable length subnetting, and
it is why version 2 exists. You will meet the distinction again in the routing
protocol topic.

**Tools still print classes**, which is the most common way people meet them now.
The `ipcalc` output in the previous topic labelled a network "Class C, Private
Internet" without being asked. It is describing the address's historical class
alongside a prefix that has nothing to do with it, which is harmless once you
know that is what it is doing.

The honest summary for exam purposes: know the five ranges and know that nothing
decides a mask from them any more. Both halves get tested.

</details>

## The three private ranges

RFC 1918 set aside three blocks that anybody may use inside their own network. No
allocation, no registration, no cost, and no reachability from the internet.

| Range | In CIDR | Addresses | Where you meet it |
| --- | --- | --- | --- |
| 10.0.0.0 to 10.255.255.255 | 10.0.0.0/8 | 16,777,216 | Large corporate networks, cloud virtual networks |
| 172.16.0.0 to 172.31.255.255 | 172.16.0.0/12 | 1,048,576 | Mid-sized networks, some container runtimes |
| 192.168.0.0 to 192.168.255.255 | 192.168.0.0/16 | 65,536 | Home routers, small offices |

**The middle one is the trap and it is worth ten seconds now.** The range stops at
172.31, not at 172.16 and not at 172.255. A /12 covers sixteen /16s, so
172.16.0.0 through 172.31.255.255 is private and 172.32.0.0 is somebody's public
address. Exam questions include 172.32 and 172.15 as distractors precisely
because this boundary is the one people misremember.

Nothing about a private address looks different on a machine. It is an ordinary
address with an ordinary mask, and the only thing that makes it private is an
agreement about what routers on the internet will carry. That agreement is the
whole mechanism.

<details class="deeper">
<summary>If you already work on networks: the other blocks that are not public either, and the ones to use in documentation</summary>

Three ranges is the exam answer. The registry of special-purpose blocks is longer
than three, and two entries in it come up in real work often enough to know.

**Shared address space, 100.64.0.0/10, from RFC 6598.** Set aside for carrier
grade NAT, where an internet provider puts many customers behind one public
address and needs a range for the intermediate hop. It is not RFC 1918 space and
it is not public space. If a home router's external interface shows an address
starting 100.64 through 100.127, the customer is behind carrier grade NAT, and
that has consequences: no inbound connections, so no port forwarding, and games
consoles and VPN endpoints behave badly. Seeing it saves the argument about which
end is broken.

**Documentation ranges, from RFC 5737.** Three /24s exist specifically for
examples and diagrams: 192.0.2.0/24, 198.51.100.0/24 and 203.0.113.0/24, named
TEST-NET-1 through 3. They are guaranteed never to be allocated to anybody, which
is exactly what you want in a document that will be copied and pasted. Writing a
firewall example against a real company's address is a small unkindness that
occasionally becomes a real one.

This track uses 10.x and 192.168.x in its captures because they come from real
namespace topologies where private space is the honest choice. In prose examples
about the public internet, the RFC 5737 ranges are the correct thing to reach
for.

The full list is worth bookmarking rather than memorising. IANA maintain it as
the IPv4 Special-Purpose Address Registry, and it is the authority for what any
given reserved block is actually for.

</details>

## The addresses that never leave the machine

Every machine has a loopback interface. It exists whether or not any cable is
attached, it is always up, and traffic sent to it turns around inside the network
stack without touching hardware.

The famous address is 127.0.0.1. The reserved block is larger than that.

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology two-hosts
$ ip -n h1 addr show lo
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host proto kernel_lo 
       valid_lft forever preferred_lft forever
# every address in 127.0.0.0/8 is this machine, not just the famous one
$ ip netns exec h1 ping -c 2 127.0.0.1
PING 127.0.0.1 (127.0.0.1) 56(84) bytes of data.
64 bytes from 127.0.0.1: icmp_seq=1 ttl=64 time=0.014 ms
64 bytes from 127.0.0.1: icmp_seq=2 ttl=64 time=0.061 ms

--- 127.0.0.1 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1055ms
rtt min/avg/max/mdev = 0.014/0.037/0.061/0.023 ms
$ ip netns exec h1 ping -c 2 127.9.9.9
PING 127.9.9.9 (127.9.9.9) 56(84) bytes of data.
64 bytes from 127.9.9.9: icmp_seq=1 ttl=64 time=0.029 ms
64 bytes from 127.9.9.9: icmp_seq=2 ttl=64 time=0.045 ms

--- 127.9.9.9 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1017ms
rtt min/avg/max/mdev = 0.029/0.037/0.045/0.008 ms
# and none of it is in the routing table you normally look at
$ ip -n h1 route
$ ip netns exec h1 ip route show table local
local 127.0.0.0/8 dev lo proto kernel scope host src 127.0.0.1 
local 127.0.0.1 dev lo proto kernel scope host src 127.0.0.1 
broadcast 127.255.255.255 dev lo proto kernel scope link src 127.0.0.1 
```

`127.0.0.1/8` is the address and the mask together, and the mask is the
interesting half. The reserved block runs from 127.0.0.0 to 127.255.255.255, and
on this machine every one of those addresses is the machine itself, which is why
`127.9.9.9` answers exactly as `127.0.0.1` does. Sixteen million addresses for
one interface, the most generous allocation in the address space, handed to the
one place that never needed more than one.

Whether every address in the block answers turns out to depend on the operating
system, which is not something the reservation implies and is covered under
**Across platforms** below.

Notice the last two commands. `ip route` prints nothing at all, because there is
no route for 127.0.0.0/8 in the table you normally read. The kernel keeps local
and loopback destinations in a separate table called `local`, consults it first,
and only falls through to the main table for everything else. So loopback traffic
is decided before ordinary routing is involved, which is why unplugging every
cable does not affect it.

<details class="deeper">
<summary>If you already work on networks: why loopback is useful rather than merely curious</summary>

The reason to care about a whole /8 rather than one address is that services can
be bound to different loopback addresses and stay separate.

That matters most on the security side, and topic 01's panel on bind addresses is
the practical version: a service listening on 127.0.0.1 is reachable from the
machine and from nowhere else, whatever the firewall permits, because packets to
loopback never reach an interface. A database bound that way is protected by
something stronger than a rule, since there is no path to it at all.

The other regular use is on routers, where a loopback is given a single address
that is not tied to any physical interface. Routing protocols are then configured
to source their traffic from it, and the router keeps a stable identity even when
individual links go down. That is why a router configuration frequently has a /32
loopback with an address that looks like it belongs to a real network.

IPv6 made the opposite choice and it is worth the contrast. Its loopback is
`::1/128`, one single address, no block. Both captures earlier in this track show
it sitting alongside `127.0.0.1/8` on the same interface. Nothing was lost by
allocating one instead of sixteen million.

</details>

## A 169.254 address is a diagnosis

Now the question at the top.

The range 169.254.0.0/16 is link-local, defined by RFC 3927. Machines use it when
they have no other address, and it comes with one hard rule: a packet with a
169.254 address as source or destination must never be given to a router to
forward. The range works on one segment and nowhere else, by design.

A machine ends up with one by a specific route. It was configured to get its
address from DHCP, it asked, nothing answered, and rather than sit with no
address at all it gave itself one from the link-local range. So the address is a
report, and it reports quite a lot.

Here is what one can and cannot do, on two hosts that have nothing else.

<details class="predict">
<summary>Two machines on one cable, each with only a link-local address. What can they reach, and what does the failure look like when they try to go further?</summary>

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology two-hosts
# neither host has an IPv4 address yet
$ ip -n h1 addr show h1eth0
4: h1eth0@if3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
    link/ether 02:00:00:00:01:01 brd ff:ff:ff:ff:ff:ff link-netns h2
    inet6 fe80::ff:fe00:101/64 scope link tentative proto kernel_ll 
       valid_lft forever preferred_lft forever
$ ip -n h1 route
# give each end a link-local address, which is what a machine does when DHCP never answers
$ ip -n h1 addr add 169.254.11.5/16 dev h1eth0
$ ip -n h2 addr add 169.254.200.42/16 dev h2eth0
$ ip -n h1 route
169.254.0.0/16 dev h1eth0 proto kernel scope link src 169.254.11.5 
# the two machines can reach each other
$ ip netns exec h1 ping -c 2 169.254.200.42
PING 169.254.200.42 (169.254.200.42) 56(84) bytes of data.
64 bytes from 169.254.200.42: icmp_seq=1 ttl=64 time=0.030 ms
64 bytes from 169.254.200.42: icmp_seq=2 ttl=64 time=0.055 ms

--- 169.254.200.42 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1035ms
rtt min/avg/max/mdev = 0.030/0.042/0.055/0.012 ms
# and nothing beyond the wire
$ ip netns exec h1 ping -c 1 -W 1 8.8.8.8
ping: connect: Network is unreachable
```

</details>

Read the route table first. One entry, for 169.254.0.0/16, on the interface, and
no default route. There is nothing to give traffic to for any other destination,
which is why `8.8.8.8` fails instantly with `Network is unreachable` rather than
timing out. The machine did not try and fail; it had nowhere to send it.

The two hosts reach each other perfectly. Link-local is a working address on the
segment, so file sharing between two machines on one switch can work while
everything else is dead, and that combination confuses people more than a total
failure would.

So the address rules things in and out. **The interface is up, the driver works,
and the machine has a live link,** because a machine with no carrier does not
bother asking for DHCP and does not get this far. **The DHCP server did not
answer,** which is one of: the server is down, the relay is missing on this VLAN,
the switch port is in the wrong VLAN, or the DHCP scope is exhausted. Notably
none of those are on the machine you are looking at.

That is the payoff. The one address on screen has moved the investigation from
the user's laptop to the network, before you have run a single command.

<details class="deeper">
<summary>If you already work on networks: why Linux usually does not do this and Windows always does</summary>

The block above is worth reading carefully, because the addresses in it were
assigned by hand. That is not a shortcut. It is the accurate demonstration,
because a Linux host in this situation would ordinarily end up with no IPv4
address at all rather than a link-local one.

RFC 3927 is the reason, and the exact wording matters. A host that loses its
routable address "MAY identify a usable IPv4 Link-Local address and assign that
address to the interface". MAY, not MUST. The specification permits the behaviour
and does not require it, so implementations differ, and both are compliant.

Windows takes the permission. Microsoft's documentation calls the feature
Automatic Private IP Addressing, says it is enabled by default, and describes it
yielding to DHCP as soon as a DHCP server becomes available. That is why APIPA is
a Windows word for a range that has a vendor-neutral name.

Most Linux distributions do not, by default. A DHCP client that gets no answer
generally leaves the interface without an address, so the symptom is an empty
address list rather than a 169.254 one. The behaviour is available and off:
NetworkManager can be told to configure link-local addressing for a connection,
and there are separate daemons that implement the RFC 3927 procedure including
its duplicate address detection.

The consequence for troubleshooting is that the same underlying fault presents
differently by platform. On Windows, look for 169.254. On Linux, look for no IPv4
address on an interface that is up. On both, the conclusion is the same and it is
about the network rather than the machine.

One more thing the exam likes: an address in this range means DHCP failed, and it
never means DHCP is misconfigured with the wrong scope. A wrong scope hands out
an address, and a wrong address is a different fault with different symptoms.

</details>

## Public, private, and where NAT sits

The last piece is what actually separates the two.

A public address is one that a registry allocated to a specific organisation, and
that routers on the internet carry a route toward. There is nothing in the number
itself that makes it public. It is public because it is in a routing table
somewhere, and that entry exists because somebody was allocated it.

A private address is one from the RFC 1918 blocks, which providers deliberately
do not carry. Send a packet to 10.1.1.1 across the internet and it is discarded,
because no router beyond your own network has any idea which of the millions of
10.1.1.1s you meant.

Which raises the obvious question, since a machine with a private address plainly
does reach the internet. The answer is that it does not reach it with that
address. Something at the boundary rewrites the source address to a public one on
the way out and reverses the change on the way back, and that something is NAT.
Topic 25 covers how it works and what it costs, including why incoming
connections are the hard direction.

For now the shape is enough: private inside, public outside, and a translation at
the border. Almost every network you have ever used is built that way, including
the one this page arrived over.

<details class="deeper">
<summary>If you already work on networks: what a boundary router actually filters, and the addresses that should never appear</summary>

Providers do not simply decline to route private addresses. Well-run networks
filter them explicitly at the edge, in both directions, and the list of what gets
filtered is longer than RFC 1918.

The general term is bogon filtering: dropping traffic whose source address could
not legitimately have come from where it arrived. The candidates are the
special-purpose blocks. Private ranges are the obvious ones. So are 127.0.0.0/8,
because a packet from the internet claiming to be from your own loopback is
either broken or hostile, 169.254.0.0/16, which RFC 3927 forbids routing at all,
0.0.0.0/8, and 240.0.0.0/4.

Two practical consequences. Traffic with a forged private source address gets
dropped at the boundary rather than travelling, which removes a whole class of
spoofing attack, and topic 56 covers what the remaining ones look like. And when
something inside your network cannot reach a service outside it, one of the
things worth checking is whether the return path knows how to get back, because
an asymmetric route into filtered space fails silently in one direction only.

The registry is the reference for all of this. IANA's IPv4 Special-Purpose
Address Registry lists every reserved block, what defines it, and specifically
whether it is forwardable and whether it is globally reachable. Those last two
columns are the ones that answer "should this address ever cross a router", which
is the question a boundary filter is built from.

</details>

## Across platforms

The reservation of 127.0.0.0/8 is the same everywhere. What each platform does
with the other sixteen million addresses is not, and this is the one place in
this topic where a claim that holds on Linux does not hold on all three.

| Task | Linux | Windows | macOS |
| --- | --- | --- | --- |
| Reach 127.0.0.1 | works | works | works |
| Reach anything else in 127.0.0.0/8 | works | works | times out |
| Show what covers the block | `ip route show table local` | `Get-NetIPAddress -InterfaceAlias "Loopback*"` | `ifconfig lo0` |

Windows behaves the way Linux does.

```powershell
# Microsoft Windows Server 2025 Datacenter, version 10.0.26100.0
> ping -n 2 127.9.9.9
Pinging 127.9.9.9 with 32 bytes of data:
Reply from 127.9.9.9: bytes=32 time<1ms TTL=128
Reply from 127.9.9.9: bytes=32 time<1ms TTL=128
Ping statistics for 127.9.9.9:
    Packets: Sent = 2, Received = 2, Lost = 0 (0% loss),
Approximate round trip times in milli-seconds:
    Minimum = 0ms, Maximum = 0ms, Average = 0ms

# The interface it lives on, and the mask that covers the whole block
> Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias "Loopback*" | Format-Table IPAddress, PrefixLength, PrefixOrigin, SuffixOrigin -AutoSize
IPAddress PrefixLength PrefixOrigin SuffixOrigin
--------- ------------ ------------ ------------
127.0.0.1            8    WellKnown    WellKnown
```

`127.9.9.9` replies, and the loopback interface carries `127.0.0.1` with a prefix
length of 8. `PrefixOrigin WellKnown` is Windows saying this address came from the
specification rather than from DHCP or from a person, which is the same label it
puts on an address configured from the link-local range when DHCP fails.

macOS does not.

```bash
# macOS 26.5.2, arm64
$ ifconfig lo0 | grep -E "inet "
	inet 127.0.0.1 netmask 0xff000000

# So this one works
$ ping -c 2 127.0.0.1
PING 127.0.0.1 (127.0.0.1): 56 data bytes
64 bytes from 127.0.0.1: icmp_seq=0 ttl=64 time=0.057 ms
64 bytes from 127.0.0.1: icmp_seq=1 ttl=64 time=0.056 ms

--- 127.0.0.1 ping statistics ---
2 packets transmitted, 2 packets received, 0.0% packet loss
round-trip min/avg/max/stddev = 0.056/0.057/0.057/0.000 ms

# And this one does not
$ ping -c 2 -t 3 127.9.9.9
PING 127.9.9.9 (127.9.9.9): 56 data bytes
Request timeout for icmp_seq 0

--- 127.9.9.9 ping statistics ---
2 packets transmitted, 0 packets received, 100.0% packet loss
```

The mask on the interface is `0xff000000`, which is 255.0.0.0 and covers the
whole block, and `127.9.9.9` still times out. BSD assigns the single address and
answers on that alone, where Linux installs a route for the entire block in its
`local` table and Windows does the equivalent.

So the reservation and the behaviour are separate facts. All three reserve the
block, and two of them will talk to any address in it. If you have ever bound a
service to `127.0.0.2` to keep it separate from something on `127.0.0.1`, that
works on Linux, works on Windows, and needs the address explicitly added on a
Mac.

For the exam, the answer is that 127.0.0.0/8 is reserved for loopback. This
difference is the kind of thing that costs an afternoon rather than a mark.


## Prove it

You have this when you can classify an address on sight and say what it implies.
No commands, no calculator, and about five seconds each.

For each of these, name the range it belongs to and one thing it tells you:

```
172.20.14.3
169.254.201.7
127.0.0.53
100.64.9.12
172.32.14.3
224.0.0.5
203.0.113.9
```

Then check yourself on a machine you have to hand. Run `ip addr` on Linux or
macOS, or `ipconfig` on Windows, and for every address it prints, say which of
the categories on this page it falls into before reading any further output. Any
machine on a home or office network will show at least one private address and at
least one loopback, and knowing which is which without thinking is the skill this
topic is for.

## What trips people up

### 1. Getting the 172.16 range wrong

The private block is 172.16.0.0 to 172.31.255.255. Not 172.16 to 172.16.255.255,
and not everything beginning 172. A /12 covers sixteen /16s, so counting from 16
lands on 31 as the last one. Both 172.15.0.0 and 172.32.0.0 are public addresses.

### 2. Reading 169.254 as a DHCP misconfiguration

It means DHCP did not answer at all. A DHCP server handing out addresses from the
wrong range still hands out an address, and you get a working-looking machine on
the wrong network, which is a different fault entirely.

### 3. Thinking a private address is a security control

Private means unrouted on the internet, which is not the same as unreachable.
Anything on the same network reaches it, VPNs reach it, and NAT lets it reach
out. It is an addressing decision that has a useful side effect, not a firewall.

### 4. Expecting 127.0.0.1 to be the only loopback address

The whole of 127.0.0.0/8 loops back, as the capture above shows. This surprises
people mostly when they meet a service configured on 127.0.0.2 and assume it is a
typo.

### 5. Assuming the class decides the mask

It did once and it does not now. `10.5.5.1/24` is an entirely ordinary
configuration, and calling it a class A network with the wrong mask is applying a
scheme that no equipment has implemented for decades.

### 6. Forgetting that 127 is missing from class A

Class A's first octet runs 1 to 126 in every table you will see, because 127 was
taken for loopback. If a question offers 127 as a class A address, that is the
distractor.

## Work it through

A user in a branch office reports that they cannot reach anything. You are remote
and you have one screenshot of their `ipconfig` output. It shows an IPv4 address
of `169.254.19.240`, a subnet mask of `255.255.0.0`, and the default gateway
field empty.

Start with what the address rules out, because that is faster than what it rules
in. The machine got far enough to try DHCP, which means the interface came up and
the driver is working. The link is live: no carrier means no attempt. So the
cable, the NIC and the switch port having power are all off the list, and so is
anything about DNS or the browser, because there is no path for those to fail
across yet.

Now what it rules in. Windows configured this address because a DHCP request went
unanswered. Four candidates, and they are worth ordering by how many people they
affect.

Is anyone else in that office affected? That single question splits the space.
One machine affected points at the switch port: wrong VLAN, or a port in a state
that carries no DHCP traffic. Everybody affected points at the shared parts: the
DHCP server itself, the relay that forwards DHCP across the router to that VLAN,
or a scope with no addresses left.

The empty gateway field is confirmation rather than a separate clue. Link-local
configuration does not create a default route, which is exactly what the capture
above shows, so an empty gateway is expected here and not an extra fault to
chase.

The thing not to do is start on the user's machine. Every piece of evidence
points away from it, and the address said so before you asked a single question.

## Try it

**Read your own machine.** Run `ip addr` or `ipconfig /all` and classify every
address it shows. Expect a loopback, at least one private address, and possibly an
IPv6 link-local beginning `fe80`, which topic 08 covers. If you find something
beginning 100.64, you are behind carrier grade NAT and that is worth knowing about
your own connection.

**Produce a link-local situation deliberately.** On a spare machine or a virtual
one, disconnect it from anything running DHCP and watch what it does. On Windows
you will get a 169.254 address within a minute or so. On Linux you will most
likely get no IPv4 address at all, which is the platform difference in the panel
above, seen rather than read.

**Look up one block.** Open IANA's IPv4 Special-Purpose Address Registry and find
the entry for 169.254.0.0/16. Read the Forwardable and Globally Reachable columns
and confirm for yourself that both say false. Those two columns answer more
troubleshooting questions than the rest of the table put together.

## Check yourself

<details class="qa">
<summary>Which of these are private addresses: 172.15.9.1, 172.20.9.1, 172.31.255.254, 172.32.0.1?</summary>

The middle two. The private block is 172.16.0.0/12, which runs from 172.16.0.0 to
172.31.255.255.

`172.20.9.1` and `172.31.255.254` are inside it. `172.15.9.1` is below the range
and `172.32.0.1` is above it, and both of those are public addresses belonging to
somebody.

</details>

<details class="qa">
<summary>A machine has 169.254.14.9 and can reach another machine on the same switch but nothing else. Is that consistent, and what does it tell you?</summary>

Completely consistent, and it is the expected behaviour rather than a second
fault.

A link-local address works on its own segment, so two machines with 169.254
addresses on the same switch can reach each other. There is no default route,
because link-local configuration does not create one, so anything off the segment
fails immediately with a network unreachable error.

What it tells you is that DHCP did not answer. The partial connectivity is a
consequence of that, not a separate problem.

</details>

<details class="qa">
<summary>Why is the usable first octet for class A given as 1 to 126 rather than 0 to 127?</summary>

Both ends are taken. The 0.0.0.0/8 block means "this network" and is not a usable
host address, and 127.0.0.0/8 is reserved entirely for loopback.

Both fall inside class A's numeric range of 0 to 127, so the range that is
actually available to assign runs 1 to 126.

</details>

<details class="qa">
<summary>Somebody says a network is secure because it uses private addresses. What is wrong with that?</summary>

Private means the internet will not route to those addresses. It says nothing
about who can reach them by other means.

Anything on the same network reaches them directly. A VPN puts a remote machine
on the network. NAT lets machines inside reach out, and anything they connect to
can send responses back. A compromised machine on the network reaches everything
else on it.

Private addressing is an allocation decision with a useful side effect. The
control that decides who reaches what is a firewall, and segmentation in topic 55
is how the side effect gets turned into something you can rely on.

</details>

<details class="qa">
<summary>What is 100.64.0.0/10 for, and what does seeing it on a router's external interface tell you?</summary>

It is shared address space from RFC 6598, reserved for carrier grade NAT.

Seeing it on the outside of your router means your provider has put you behind
their own layer of NAT rather than giving you a public address. The practical
consequences are that inbound connections do not work, so port forwarding will
not do anything, and services that need to accept a connection from outside need
another approach.

It is not RFC 1918 space and it is not public space, which is the point of having
a separate block for it.

</details>

<details class="qa">
<summary>Under classful rules, what mask would 10.5.5.1 have had, and what mask does a modern machine give it?</summary>

Classful rules would have made it a /8, because 10 is in class A's range of 1 to
126 and class A's default mask is 255.0.0.0.

A modern machine gives it whatever mask you configure. The capture on this page
assigns `10.5.5.1/24` and the kernel accepts it without comment, deriving a route
for `10.5.5.0/24` rather than for `10.0.0.0/8`.

Nothing on a current system reads an address's class to decide anything.

</details>

## References

- [RFC 1918, Address Allocation for Private Internets](https://www.rfc-editor.org/rfc/rfc1918) - IETF, the three private ranges. Accessed 2026-08-10.
- [RFC 3927, Dynamic Configuration of IPv4 Link-Local Addresses](https://www.rfc-editor.org/rfc/rfc3927) - IETF, on 169.254.0.0/16 and the MAY that explains the platform difference. Accessed 2026-08-10.
- [RFC 1122, Requirements for Internet Hosts](https://www.rfc-editor.org/rfc/rfc1122) - IETF, section 3.2.1.3 on loopback. Accessed 2026-08-10.
- [RFC 5737, IPv4 Address Blocks Reserved for Documentation](https://www.rfc-editor.org/rfc/rfc5737) - IETF, the TEST-NET ranges. Accessed 2026-08-10.
- [RFC 6598, IANA-Reserved IPv4 Prefix for Shared Address Space](https://www.rfc-editor.org/rfc/rfc6598) - IETF, carrier grade NAT space. Accessed 2026-08-10.
- [IANA IPv4 Special-Purpose Address Registry](https://www.iana.org/assignments/iana-ipv4-special-registry/iana-ipv4-special-registry.xhtml) - IANA, the authority for every reserved block. Accessed 2026-08-10.
- [How to use automatic TCP/IP addressing without a DHCP server](https://learn.microsoft.com/en-us/windows-server/troubleshoot/how-to-use-automatic-tcpip-addressing-without-a-dh) - Microsoft, on APIPA being enabled by default and yielding to DHCP. Accessed 2026-08-10.

**Where the output came from.** All three captured blocks were produced on the
two-host namespace topology, `blog/scripts/topologies/two-hosts.sh`, through
`blog/scripts/netlab.sh`. The link-local addresses in the last block were
assigned by hand rather than configured automatically, because Linux does not
ordinarily configure them at all, and the panel under that block explains why
that is the honest way to demonstrate it rather than a shortcut. The Windows
behaviour described on this page is sourced from Microsoft's documentation and
was not captured, because a runner with working DHCP never enters the state being
described.

**If you also work on Linux.** The Linux+ track covers the private ranges in
passing in [Network basics: addresses and routes](/learn/linux-plus/network-basics-addresses-and-routes), from the
point of view of assigning them rather than recognising them. The classes and the
link-local diagnosis are specific to this exam and are not there.
