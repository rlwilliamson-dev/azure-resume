---
title: "IPv6 address assignment and SLAAC"
description: "How a host ends up with three IPv6 addresses nobody configured, the two flag bits in a router advertisement that decide whether DHCPv6 is involved at all, and what happens when two machines claim the same address."
deck: "The interface has three IPv6 addresses and nobody assigned any of them"
track: "network-plus"
level: "working"
order: 440
objectives:
  - "Say what a router advertisement supplies and what the host supplies"
  - "Name three ways a host chooses an interface identifier"
  - "Read the managed and other-configuration flags and say what each means"
  - "Explain why a link-local address exists on every interface"
  - "Describe duplicate address detection and what it does when it finds one"
prerequisites: ["ipv6-addressing"]
tags: ["network-plus", "networking", "services"]
updated: 2026-08-12
draft: false
examObjectives:
  - exam: "n10-009"
    domain: "3.0"
    objective: "3.4"
sources:
  - title: "RFC 4862, IPv6 Stateless Address Autoconfiguration"
    url: "https://www.rfc-editor.org/rfc/rfc4862"
    publisher: "IETF"
    accessed: 2026-08-12
    tier: 1
  - title: "RFC 4861, Neighbor Discovery for IP version 6"
    url: "https://www.rfc-editor.org/rfc/rfc4861"
    publisher: "IETF"
    accessed: 2026-08-12
    tier: 1
  - title: "RFC 8981, Temporary Address Extensions for SLAAC in IPv6"
    url: "https://www.rfc-editor.org/rfc/rfc8981"
    publisher: "IETF"
    accessed: 2026-08-12
    tier: 1
  - title: "RFC 7217, A Method for Generating Semantically Opaque Interface Identifiers"
    url: "https://www.rfc-editor.org/rfc/rfc7217"
    publisher: "IETF"
    accessed: 2026-08-12
    tier: 1
  - title: "RFC 3849, IPv6 Address Prefix Reserved for Documentation"
    url: "https://www.rfc-editor.org/rfc/rfc3849"
    publisher: "IETF"
    accessed: 2026-08-12
    tier: 1
symptoms:
  - symptom: "An interface has several IPv6 addresses and nobody configured any"
    anchor: "one-prefix-three-second-halves"
  - symptom: "Hosts have addresses and no resolver"
    anchor: "two-bits-that-decide-whether-dhcpv6-is-involved"
  - symptom: "An address is present and marked unusable"
    anchor: "asking-before-using"
---

> **Before you read.** A server is connected to a network and given no IPv6
> configuration whatsoever. `ip addr` shows three IPv6 addresses on the
> interface.
>
> One of them starts `fe80::`. Two of them start with the same 64 bits and end
> completely differently, and one of those two was not there yesterday.
>
> **Where did each of the three come from, and which one will the machine use
> when it connects to something?**

IPv4 hosts get their addresses from a server. IPv6 hosts mostly do not, and the
difference is not a detail: it changes where the configuration lives, what a
router has to be told, and what you look at when it goes wrong.

### Some words you will need

<dl class="terms">
<dt>router advertisement</dt>
<dd>A message a router sends to the segment saying what the prefix is and that it is a router.</dd>
<dt>SLAAC</dt>
<dd>Stateless address autoconfiguration. The host builds its own address from the advertised prefix.</dd>
<dt>interface identifier</dt>
<dd>The right-hand 64 bits, chosen by the host.</dd>
<dt>EUI-64</dt>
<dd>One way of choosing it: the MAC address, with ff:fe inserted and one bit flipped.</dd>
<dt>link-local</dt>
<dd>An fe80:: address that every IPv6 interface has, valid only on its own segment.</dd>
<dt>DAD</dt>
<dd>Duplicate address detection. Asking the segment whether an address is taken before using it.</dd>
</dl>

## What breaks without this

**Nobody can say where an address came from.** Which makes it impossible to change
and impossible to document.

**Hosts get addresses and cannot resolve names.** Because the advertisement said
to ask DHCPv6 for the rest and nothing is running.

**A machine loses connectivity intermittently** and the address it is using is
different every time somebody looks.

## One prefix, three second halves

An IPv6 address is two halves, and on most networks they come from two different
places.

<figure class="learn-figure">
<svg viewBox="0 0 720 236" role="img" aria-labelledby="slaac-title" style="width:100%;height:auto;">
<title id="slaac-title">One 64-bit prefix from a router advertisement, and three hosts each choosing a different 64-bit interface identifier to sit behind it</title>
<g fill="currentColor">
<text x="14" y="22" font-size="11">the router supplies the left half, the host chooses the right half</text>
<text x="192" y="52" text-anchor="middle" font-size="10" fill-opacity="0.75">from the advertisement</text>
<text x="384" y="52" text-anchor="middle" font-size="10" fill-opacity="0.75">chosen by the host</text>
<text x="192" y="70" text-anchor="middle" font-size="9.5" fill-opacity="0.6">64 bits</text>
<text x="384" y="70" text-anchor="middle" font-size="9.5" fill-opacity="0.6">64 bits</text>
<text x="14" y="108" font-size="10.5">EUI-64</text>
<rect x="110" y="88" width="164" height="30" rx="2" fill="var(--accent)" fill-opacity="0.16" stroke="var(--accent)" stroke-opacity="0.8"/>
<text x="192" y="108" text-anchor="middle" font-size="10.5" fill="var(--accent)">2001:db8:1:0</text>
<rect x="274" y="88" width="220" height="30" rx="2" fill="currentColor" fill-opacity="0.12" stroke="currentColor" stroke-opacity="0.6"/>
<text x="384" y="108" text-anchor="middle" font-size="10.5">0000:00ff:fe00:0012</text>
<text x="506" y="108" font-size="9.5" fill-opacity="0.75">the MAC with ff:fe in the middle</text>
<text x="14" y="160" font-size="10.5">stable privacy</text>
<rect x="110" y="140" width="164" height="30" rx="2" fill="var(--accent)" fill-opacity="0.16" stroke="var(--accent)" stroke-opacity="0.8"/>
<text x="192" y="160" text-anchor="middle" font-size="10.5" fill="var(--accent)">2001:db8:1:0</text>
<rect x="274" y="140" width="220" height="30" rx="2" fill="currentColor" fill-opacity="0.12" stroke="currentColor" stroke-opacity="0.6"/>
<text x="384" y="160" text-anchor="middle" font-size="10.5">d746:ffa7:5870:5a60</text>
<text x="506" y="160" font-size="9.5" fill-opacity="0.75">a hash of the prefix and a secret</text>
<text x="14" y="212" font-size="10.5">temporary</text>
<rect x="110" y="192" width="164" height="30" rx="2" fill="var(--accent)" fill-opacity="0.16" stroke="var(--accent)" stroke-opacity="0.8"/>
<text x="192" y="212" text-anchor="middle" font-size="10.5" fill="var(--accent)">2001:db8:1:0</text>
<rect x="274" y="192" width="220" height="30" rx="2" fill="currentColor" fill-opacity="0.12" stroke="currentColor" stroke-opacity="0.6"/>
<text x="384" y="212" text-anchor="middle" font-size="10.5">0b29:1048:1278:b400</text>
<text x="506" y="212" font-size="9.5" fill-opacity="0.75">random, replaced every few hours</text>
</g></svg>
<figcaption>Three hosts on one segment, all hearing the same advertisement, all ending up with unrelated addresses. The accented half is the only part the network decided, and everything to the right of it is a local choice made by each machine according to how it is configured. That is the structural difference from IPv4 worth carrying: there is no allocation and no record of one, because nothing handed these out. The EUI-64 row is the scheme the exam describes and the one you are least likely to see on a modern desktop, because deriving the address from the hardware address means the address follows the machine between networks and identifies it wherever it goes. The other two rows are the responses to that: one stable per network and opaque, one deliberately short lived.</figcaption>
</figure>

Every address in that figure came off a real segment, and no host was told any of
them.

<details class="predict">
<summary>Three hosts on one segment, none of them told an address and no DHCP server anywhere. How many addresses does each one end up with?</summary>

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology slaac-lan
# nobody configured a global address on any of these. all three heard the same
# advertisement and made different choices about the second half
$ for h in h1 h2 h3; do echo "-- $h --"; ip netns exec $h ip -6 addr show ${h}0 | grep inet6; done
-- h1 --
    inet6 2001:db8:1:0:d746:ffa7:5870:5a60/64 scope global dynamic mngtmpaddr stable-privacy proto kernel_ra 
    inet6 fe80::231:f4f8:451f:b43d/64 scope link stable-privacy proto kernel_ll 
-- h2 --
    inet6 2001:db8:1::ff:fe00:12/64 scope global dynamic mngtmpaddr proto kernel_ra 
    inet6 fe80::ff:fe00:12/64 scope link proto kernel_ll 
-- h3 --
    inet6 2001:db8:1:0:b29:1048:1278:b400/64 scope global temporary dynamic 
    inet6 2001:db8:1::ff:fe00:13/64 scope global dynamic mngtmpaddr proto kernel_ra 
    inet6 fe80::ff:fe00:13/64 scope link proto kernel_ll 
# and the route it was given, which points at a link-local address
$ ip netns exec h1 ip -6 route | tail -1
default via fe80::ff:fe00:1 dev h10 proto ra metric 1024 expires 11sec hoplimit 64 pref medium
```

</details>

**The link-local address is the one to notice first.** Every IPv6 interface has
one, whether or not there is a router, a prefix or anything else. It is generated
when the interface comes up, it is only valid on that segment, and it is what
neighbour discovery uses. The corollary is one people meet in a routing table
before they meet it in a book: **the IPv6 default route points at a link-local
address**, not at a global one, because the router's identity on that segment is
its link-local address.

**The three global addresses are three different answers to one question.** The
prefix is fixed by the advertisement. What goes after it is up to the host.

**EUI-64** takes the 48-bit MAC, inserts `ff:fe` in the middle to make 64 bits, and
inverts the seventh bit. So `02:00:00:00:00:12` becomes `0000:00ff:fe00:0012`, and
you can read the hardware address straight off the network address. The exam
describes this method and it is worth being able to perform in both directions.

**Stable privacy** replaces that with a hash of the prefix, the interface and a
secret held by the machine, per RFC 7217. The result is stable on a given network
and reveals nothing, and moving the machine to a different network changes it,
which is the point.

**A temporary address** is an additional one, random, and regenerated on a
schedule. RFC 8981 defines it, and the machine prefers it for connections it
starts while keeping the stable address for connections that arrive.

That last part answers the second half of the question at the top. **Outbound
connections use the temporary address** where one exists, which is why a machine's
address in somebody else's logs is different every day and why matching a firewall
rule to a client address is a poor idea on IPv6.

<details class="deeper">
<summary>If you already run IPv6: why a host has several addresses at once, and which one it sends from</summary>

A host on an IPv6 segment ends up holding a handful of addresses simultaneously, and
that is normal rather than a symptom.

There is a link-local address, which every interface has and which never leaves the
segment. There is usually a stable address derived from the prefix, used for anything
that needs to be reachable. And there are temporary addresses, generated periodically
and retired, which exist so that a machine's outbound traffic cannot be correlated
across weeks by its address alone.

Which one is used for an outgoing connection is decided by a set of source address
selection rules rather than by anything obvious, and the short version is that
temporary addresses win for connections the host starts, while the stable one is what
gets registered in DNS for connections other people start. The consequence for
operations is that a firewall log or a flow record showing an address may not identify
the machine tomorrow, because that address will have been retired.

So anything that ties policy to a specific IPv6 address needs the stable one, and
anything correlating logs over time needs to expect the temporary addresses to churn.
That is a genuine difference from IPv4 habits rather than a configuration mistake, and
it catches people the first time they try to trace a machine from a log a fortnight
later.

</details>

## Two bits that decide whether DHCPv6 is involved

The advertisement carries more than a prefix. Two flags in it tell the host what
to do about everything the prefix does not cover.

<figure class="learn-figure">
<svg viewBox="0 0 720 230" role="img" aria-labelledby="raflags-title" style="width:100%;height:auto;">
<title id="raflags-title">The managed and other-configuration flags in a router advertisement, and what a host does about addresses and about everything else in each of the four combinations</title>
<g fill="currentColor">
<text x="14" y="22" font-size="11">two bits in the advertisement, and what a host does about each</text>
<text x="44" y="60" font-size="10" fill-opacity="0.75">M</text>
<text x="98" y="60" font-size="10" fill-opacity="0.75">O</text>
<text x="160" y="60" font-size="10" fill-opacity="0.75">address from</text>
<text x="360" y="60" font-size="10" fill-opacity="0.75">resolver and the rest from</text>
<rect x="30" y="78" width="660" height="34" rx="2" fill="currentColor" fill-opacity="0.07" stroke="currentColor" stroke-opacity="0.35"/>
<text x="44" y="100" font-size="11">0</text>
<text x="98" y="100" font-size="11">0</text>
<text x="160" y="100" font-size="10.5">the advertisement</text>
<text x="360" y="100" font-size="10.5">the advertisement, if it carries them</text>
<rect x="30" y="120" width="660" height="34" rx="2" fill="var(--accent)" fill-opacity="0.14" stroke="var(--accent)" stroke-opacity="0.9" stroke-width="1.8"/>
<text x="44" y="142" font-size="11">0</text>
<text x="98" y="142" font-size="11">1</text>
<text x="160" y="142" font-size="10.5">the advertisement</text>
<text x="360" y="142" font-size="10.5">DHCPv6, which hands out no addresses</text>
<rect x="30" y="162" width="660" height="34" rx="2" fill="currentColor" fill-opacity="0.07" stroke="currentColor" stroke-opacity="0.35"/>
<text x="44" y="184" font-size="11">1</text>
<text x="98" y="184" font-size="11">0</text>
<text x="160" y="184" font-size="10.5">DHCPv6</text>
<text x="360" y="184" font-size="10.5">DHCPv6</text>
<rect x="30" y="204" width="660" height="34" rx="2" fill="currentColor" fill-opacity="0.07" stroke="currentColor" stroke-opacity="0.35"/>
<text x="44" y="226" font-size="11">1</text>
<text x="98" y="226" font-size="11">1</text>
<text x="160" y="226" font-size="10.5">DHCPv6</text>
<text x="360" y="226" font-size="10.5">DHCPv6</text>
</g></svg>
<figcaption>The managed flag decides where addresses come from and the other-configuration flag decides where everything else comes from, and the accented row is the combination most networks end up on. It exists because SLAAC alone had no way to carry a resolver for years, so the advertisement said "build your own address, then ask DHCPv6 for the rest", and DHCPv6 in that mode hands out no addresses at all. Two consequences follow. A DHCPv6 server running in that mode has no address pool and no lease database, so looking for one is looking for something that does not exist. And a network where hosts have perfectly good addresses and cannot resolve anything is usually this row with nothing listening, which is a failure that never happens on IPv4 because there the two things arrive in the same message.</figcaption>
</figure>

The advertisement itself is readable, and the flags are the first thing on the
line after the header.

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology slaac-lan
# the advertisement itself. two flag bits decide what a host does after reading it
$ ip netns exec h1 timeout 8 tcpdump -i h10 -n -v -c 1 "icmp6 and ip6[40] == 134" 2>/dev/null
20:06:24.362069 IP6 (flowlabel 0x24051, hlim 255, next-header ICMPv6 (58) payload length: 80) fe80::ff:fe00:1 > ff02::1: [icmp6 sum ok] ICMP6, router advertisement, length 80
	hop limit 64, Flags [other stateful], pref medium, router lifetime 15s, reachable time 0ms, retrans timer 0ms
	  prefix info option (3), length 32 (4): 2001:db8:1::/64, Flags [onlink, auto], valid time 86400s, pref. time 3600s
	  rdnss option (25), length 24 (3):  lifetime 600s, addr: 2001:db8:1::1
	  source link-address option (1), length 8 (1): 02:00:00:00:00:01
```

`Flags [other stateful]` is the other-configuration bit set with the managed bit
clear, which is the accented row. `Flags [onlink, auto]` on the prefix is two more
bits, and the `auto` one is what authorises SLAAC for this prefix: a prefix
advertised without it is a statement about what is on the segment rather than a
licence to build an address from it.

`router lifetime 15s` is worth a look too. A router advertising a lifetime of zero
is saying "I am here but do not use me as a default router", which is how a device
providing prefix information without being a gateway announces itself.

**The RDNSS option** carries the resolver in the advertisement itself, from RFC
8106, which is the mechanism that removes the need for DHCPv6 in the accented row.
Support is now widespread and was not for a long time, which is why so many
networks are still configured the older way.

<details class="deeper">
<summary>If you already deploy this: the option DHCPv6 cannot supply, and what that forces</summary>

The two flags let a network choose between stateless configuration and DHCPv6, and
there is one asymmetry between the two that decides several designs.

DHCPv6 as originally specified has no option for a default gateway. A host learns its
router from the router advertisement and from nowhere else, so the advertisements are
mandatory whatever else is in use. That is the opposite of IPv4, where the gateway is
an ordinary DHCP option and a network can run without any router advertisement
equivalent.

The practical consequences are two. A host that is not hearing advertisements has no
route off the segment regardless of how its address was obtained, so a filtering
decision that blocks them breaks the network in a way that looks like a routing fault.
And any control you wanted to exercise by handing out addresses centrally still leaves
the router announcing itself to everything on the segment, which is why rogue
advertisements are the IPv6 equivalent of the rogue DHCP server in topic 57 and need
their own protection on the switch.

Worth knowing alongside: stateless configuration gives the host an address the server
never recorded, so there is no central log of who had what. Where that record is needed,
for an investigation or for compliance, it has to come from the neighbour tables on the
switches rather than from a lease database, and those age out.

</details>

## Asking before using

Before a host uses any address, including one it generated itself, it asks the
segment whether anybody already has it.

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology slaac-lan
# h1 takes an address by hand
$ ip netns exec h1 ip addr add 2001:db8:1::99/64 dev h10
$ sleep 2
# then h2 tries to take the same one, and asks the segment before using it
$ (ip netns exec r1 timeout 12 tcpdump -i r10 -n icmp6 > /tmp/dad.txt 2>/dev/null &)
$ sleep 1
$ ip netns exec h2 ip addr add 2001:db8:1::99/64 dev h20
$ sleep 11
$ grep -a "2001:db8:1::99" /tmp/dad.txt
20:07:11.812132 IP6 :: > ff02::1:ff00:99: ICMP6, neighbor solicitation, who has 2001:db8:1::99, length 32
20:07:11.812164 IP6 2001:db8:1::99 > ff02::1: ICMP6, neighbor advertisement, tgt is 2001:db8:1::99, length 32
# h2 never gets to use it, and h1 keeps it
$ ip netns exec h2 ip -6 addr show h20 | grep 99
    inet6 2001:db8:1::99/64 scope global dadfailed tentative 
       valid_lft 86399sec preferred_lft 3599sec
$ ip netns exec h1 ip -6 addr show h10 | grep 99
    inet6 2001:db8:1::99/64 scope global 
       valid_lft 86399sec preferred_lft 3599sec
```

The solicitation comes **from `::`**, the unspecified address, because the address
being tested is not usable yet and the host has nothing else to send from. It goes
to the solicited-node multicast group derived from the address being claimed,
which is why only machines whose addresses end similarly have to look at it.

h1 answered, so h2's address is marked `dadfailed tentative` and never becomes
usable. There is no negotiation and no second attempt at a different address:
the host that got there first keeps it, and the other one has an interface with an
address it is not allowed to use.

That matters more on IPv6 than the equivalent does on IPv4, because addresses here
are generated rather than assigned, and generation can collide. It is also the
mechanism behind a fault worth recognising: an address that is present in `ip addr`
and does not work is frequently one that failed detection, and the flag saying so
is easy to read past.

<details class="deeper">
<summary>If you already work on networks: rogue advertisements, why RA guard is the IPv6 equivalent of DHCP snooping, and what happens when a machine believes two routers</summary>

Everything on this page happens because a host believes what it is told by
whatever sends an advertisement. There is no authentication, exactly as there is
none in DHCP, and the consequences are worse in one specific way.

A rogue DHCP server has to win a race: the client takes the first acceptable
offer, so a legitimate server that answers faster wins. **A rogue router
advertisement does not race.** Hosts accept advertisements from every router that
sends them and build an address per prefix, so a machine can hold addresses from
the real router and the rogue one simultaneously, and route through whichever the
address selection rules prefer for a given destination.

The usual cause is not an attack. It is a machine with IPv6 forwarding enabled and
a tunnel interface, or a virtualisation host, or an operating system feature that
shares a connection. Windows Internet Connection Sharing did this for years, and
the symptom was a segment where some machines routed through somebody's laptop.

The control is on the switch and it is the direct counterpart of DHCP snooping.
**RA guard** designates ports as allowed to carry router advertisements and drops
them everywhere else, which again turns an unauthenticated protocol into a
statement about topology. The ports facing routers are trusted and the ports
facing users are not.

**Two further details worth having.** First, hosts do not forget advertisements
quickly. The lifetimes in the message govern how long a prefix stays valid, and a
rogue router that is unplugged leaves its prefix behind on every machine that
heard it until those timers expire. Removing the cause does not immediately remove
the effect, which is confusing during an incident.

Second, this interacts with address selection in a way that produces the worst
kind of fault. RFC 6724 governs which source address a machine picks for a given
destination, and the rules prefer a source whose prefix matches the destination
more closely. So a machine holding a good address and a bad one will use the good
one for some destinations and the bad one for others, which presents as some
things working and some not, on the same machine, at the same time, with nothing
in the routing table looking wrong.

</details>

## Across platforms

Every platform does SLAAC and every one of them makes a different choice about
the interface identifier. Two settings decide it, and both are readable.

**On Linux**, `addr_gen_mode` under `/proc/sys/net/ipv6/conf/<interface>/` selects
the scheme and `use_tempaddr` controls temporary addresses. The lab on this page
sets both explicitly, which is why the three hosts differ.

**On macOS**, temporary addresses are on and the identifier is opaque.

```bash
# macOS 26.5.2, arm64
$ ndp -p 2>&1 | head -6
fe80::%utun1/64 if=utun1
flags=AILSO vltime=infinity, pltime=infinity, expire=Never, ref=0
  No advertising router
fe80::%utun3/64 if=utun3
flags=AILSO vltime=infinity, pltime=infinity, expire=Never, ref=0
  No advertising router

$ ndp -r 2>&1 | head -4
fe80::%utun0 if=utun0, flags=IST, pref=medium, expire=Never
fe80::%utun1 if=utun1, flags=IST, pref=medium, expire=Never
fe80::%utun2 if=utun2, flags=IST, pref=medium, expire=Never
fe80::%utun3 if=utun3, flags=IST, pref=medium, expire=Never

# Whether this machine generates temporary addresses at all
$ sysctl net.inet6.ip6.use_tempaddr net.inet6.ip6.temppltime net.inet6.ip6.tempvltime
net.inet6.ip6.use_tempaddr: 1
net.inet6.ip6.temppltime: 86400
net.inet6.ip6.tempvltime: 604800

# The interface identifier scheme in use, which the secured flag names
$ ifconfig en0 inet6 | head -4
en0: flags=8863<UP,BROADCAST,SMART,RUNNING,SIMPLEX,MULTICAST> mtu 1500
	options=400<CHANNEL_IO>
	inet6 fe80::106c:94a9:d29a:2f7d%en0 prefixlen 64 secured scopeid 0x7 
	nd6 options=201<PERFORMNUD,DAD>
```

`use_tempaddr: 1` with a preferred lifetime of 86400 seconds and a valid lifetime
of 604800 is the RFC 8981 behaviour with day-long preference and week-long
validity. The `secured` flag on the link-local address is the opaque identifier
from RFC 7217 rather than an EUI-64 one, which is why nothing in that address
resembles a MAC.

**On Windows**, the two settings are separate and both are visible.

```powershell
# Microsoft Windows Server 2025 Datacenter, version 10.0.26100.0
> netsh interface ipv6 show interfaces | Select-Object -First 6
Idx     Met         MTU          State                Name
---  ----------  ----------  ------------  ---------------------------
  1          75  4294967295  connected     Loopback Pseudo-Interface 1
 14          10        1500  connected     Ethernet 3
 11        5000        1500  connected     vEthernet (nat)

# The two settings that decide what the second half of the address looks like
> Get-NetIPv6Protocol | Format-List RandomizeIdentifiers, UseTemporaryAddresses, MaxTemporaryPreferredLifetime, MaxTemporaryValidLifetime
RandomizeIdentifiers  : Enabled
UseTemporaryAddresses : Disabled

# Anything learned from an advertisement appears here with RouterAdvertisement as its origin
> Get-NetIPAddress -AddressFamily IPv6 | Format-Table InterfaceAlias, IPAddress, PrefixOrigin, SuffixOrigin -AutoSize
InterfaceAlias              IPAddress                    PrefixOrigin SuffixOrigin
--------------              ---------                    ------------ ------------
vEthernet (nat)             fe80::97ee:88:c036:61e9%11      WellKnown         Link
Ethernet 3                  fe80::b794:b243:4197:655b%14    WellKnown         Link
Loopback Pseudo-Interface 1 ::1                             WellKnown    WellKnown
```

`RandomizeIdentifiers : Enabled` is why a Windows address has never looked like
its hardware address, and it is a different setting from `UseTemporaryAddresses`,
which controls whether an additional short-lived address is generated on top.
Those two get conflated constantly, and the capture separates them.

Neither runner is on a network with an advertising router, which is why the only
addresses present are link-local and why `PrefixOrigin` reads `WellKnown` rather
than `RouterAdvertisement`. That is the honest picture of an IPv6 stack on an
IPv4-only network: the link-local address exists regardless, and nothing else
does.

## Prove it

**Look at your own interface.** Any machine, any platform. Count the IPv6
addresses and identify which is link-local, which is stable and which if any is
temporary.

**Work an EUI-64 by hand.** Take your own MAC, split it, insert `ff:fe`, flip the
seventh bit, and compare against what the machine actually has. On most modern
machines they will not match, and understanding why is the point of the exercise.

**Find the default route.** On any IPv6-connected machine, look at what the
default route points at. It will be an `fe80::` address, and that is the fact
worth internalising.

## What trips people up

### 1. Looking for a server that handed out the address

On SLAAC there is no allocation and no record of one. The router supplied a prefix
to the whole segment and each host built its own address.

### 2. Expecting the address to contain the MAC

That is EUI-64, and most current systems use an opaque identifier instead. The
exam describes EUI-64 and your laptop probably does not use it.

### 3. Treating the temporary address as an anomaly

It is deliberate, it is used for outbound connections, and it changes on a
schedule. A client address in a log is not a durable identifier on IPv6.

### 4. Assuming DHCPv6 hands out addresses

Only when the managed flag is set. In the common configuration it supplies the
resolver and other options and has no address pool at all.

### 5. Forgetting that the default gateway is link-local

The IPv6 default route points at an `fe80::` address on a named interface. A route
without the interface is meaningless, because the same link-local address can
exist on every segment.

### 6. Reading past a failed duplicate detection

An address marked `dadfailed` is present in the interface listing and unusable.
That is a specific fault with a specific cause, and it looks like a working
configuration at a glance.

## Work it through

The server with three addresses and no configuration.

**The `fe80::` one is not optional and did not come from the network.** The kernel
generated it when the interface came up, and it would exist on a machine plugged
into a dead switch. It is what neighbour discovery and the default route use, and
it is never routed off the segment.

**The two global addresses share their first 64 bits because a router said so.**
Something on the segment is sending advertisements carrying that prefix with the
autonomous flag set, and the machine built addresses from it. Finding out which
router is one capture: listen for advertisements and read the source address,
which will be the link-local address of whatever is sending them. That is also how
you find out whether it is the router you expect.

**The two differ in their second halves because they are different kinds of
address.** One is stable for as long as the machine is on this network, and one is
temporary and will be replaced, which is why it was not there yesterday. The
machine will prefer the temporary one for connections it initiates and keep the
stable one for connections that arrive.

**So the answer to which one it will use is: it depends on the direction**, and
that is the part with practical consequences. Anything identifying this server to
another system, an allow list at a partner, a firewall rule, a licence check, has
to use the stable address, and anything reading the source address of its outbound
connections will see the temporary one. Those two facts together are the reason
servers are frequently configured with a static IPv6 address in spite of everything
on this page, and that is a reasonable decision rather than a failure to understand
SLAAC.

There is one more thing worth checking on a machine like this. Read the flags on
the advertisement. If the other-configuration bit is set, the machine has been
told to get its resolver from DHCPv6, and if nothing is running the machine has
three perfectly good addresses and cannot resolve a name. That fault presents as
"IPv6 is broken" and is a missing service rather than a missing address.

## Try it

**Capture an advertisement.** On any IPv6 network, listen for ICMPv6 type 134 and
read the flags. It takes one command and it is the fastest way to know how the
network expects hosts to configure themselves.

**Provoke a duplicate.** In a lab, assign the same address to two machines on one
segment and watch the second one fail. The flag it ends up with is worth having
seen.

**Turn temporary addresses off and on.** On your own machine, and watch what
appears and disappears in the interface listing. It makes the distinction between
the stable and temporary address concrete in a way that reading does not.

## Check yourself

<details class="qa">
<summary>A host with no configuration has three IPv6 addresses. Where does each come from?</summary>

The `fe80::` one is generated by the host when the interface comes up and exists
whether or not any router is present. It is valid only on that segment and is what
neighbour discovery and the default route use.

The two global ones share a prefix that came from a router advertisement, and
differ in the 64 bits after it because the host chose those itself. One is stable
for this network and one is temporary and regenerated on a schedule.

</details>

<details class="qa">
<summary>What do the managed and other-configuration flags mean, and which combination is most common?</summary>

The managed flag says addresses come from DHCPv6 rather than from the prefix. The
other-configuration flag says everything else, chiefly the resolver, comes from
DHCPv6.

The common combination is managed clear and other-configuration set: build your
own address from the prefix, then ask DHCPv6 for the resolver. A DHCPv6 server in
that mode has no address pool, so a network where hosts have addresses and cannot
resolve names is usually this configuration with nothing answering.

</details>

<details class="qa">
<summary>Why does a duplicate address detection message come from :: rather than from the address being tested?</summary>

Because the address being tested is not usable yet. Until detection completes it
is tentative, and using it as a source would defeat the purpose of the check, so
the host sends from the unspecified address.

The destination is the solicited-node multicast group derived from the address
being claimed, which limits who has to process it. If anybody answers, the address
is marked as failed and is never used.

</details>

<details class="qa">
<summary>Why is the IPv6 default route pointed at an fe80:: address?</summary>

Because that is the router's identity on the segment. Link-local addresses exist
on every IPv6 interface without configuration, so a host can talk to its router
before either of them has a global address.

It also means the route is meaningless without the interface it applies to. The
same link-local address can legitimately exist on every segment, so the interface
is part of the destination rather than an optional detail.

</details>

<details class="qa">
<summary>Why does an EUI-64 address raise a privacy objection that a DHCP-assigned IPv4 address does not?</summary>

Because it is derived from the hardware address, which does not change when the
machine moves. The prefix changes from network to network and the second half
stays the same, so the same identifier appears in the address on every network the
machine visits.

That makes a machine trackable across networks by anything it connects to. Opaque
identifiers stop it by changing per network, and temporary addresses go further by
changing on a schedule within one network.

</details>

## References

- [RFC 4862](https://www.rfc-editor.org/rfc/rfc4862) - IETF, stateless address autoconfiguration, including duplicate address detection and the tentative state. Free. Accessed 2026-08-12.
- [RFC 4861](https://www.rfc-editor.org/rfc/rfc4861) - IETF, neighbour discovery, which defines the advertisement, its flags and the solicited-node multicast address. Free. Accessed 2026-08-12.
- [RFC 8981](https://www.rfc-editor.org/rfc/rfc8981) - IETF, temporary address extensions, and the preference rules for outbound connections. Free. Accessed 2026-08-12.
- [RFC 7217](https://www.rfc-editor.org/rfc/rfc7217) - IETF, semantically opaque interface identifiers, which is the stable privacy scheme in the capture. Free. Accessed 2026-08-12.
- [RFC 8106](https://www.rfc-editor.org/rfc/rfc8106) - IETF, the option that carries resolver addresses in a router advertisement. Free. Accessed 2026-08-12.
- [RFC 6724](https://www.rfc-editor.org/rfc/rfc6724) - IETF, source and destination address selection, referenced in the deeper panel. Free. Accessed 2026-08-12.
- [RFC 3849](https://www.rfc-editor.org/rfc/rfc3849) - IETF, the documentation prefix every address in the lab uses. Free. Accessed 2026-08-12.
- [radvd(8)](https://www.systutorials.com/docs/linux/man/8-radvd/) - The router advertisement daemon used to build the lab. Accessed 2026-08-12.

**Where the output came from.** The Linux blocks were captured on the `slaac-lan`
namespace topology through `blog/scripts/netlab.sh`, with a real router running
radvd and three hosts configured to use three different interface identifier
schemes. Both schemes are set explicitly in the topology rather than left to the
default, because the default varies: a bare kernel namespace generates EUI-64 and
a desktop distribution usually configures something opaque instead, and setting
both is what puts the two side by side in one listing. The stable privacy host
uses a fixed secret so that its address is the same on every run, which a real
machine would not do and a transcript needs. The Windows and macOS blocks came
from GitHub Actions runners through `blog/scripts/hostcap.sh`, on networks with no
advertising router, which is why neither shows a global address.

**If you also work on Linux.** [Network basics: addresses and
routes](/learn/linux-plus/network-basics-addresses-and-routes) on the Linux+ track
covers reading and setting these addresses as a configuration task, including the
sysctl entries this page reads.
