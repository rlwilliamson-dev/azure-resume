---
title: "DHCP"
description: "Four messages, two of them shouted by a machine with no address. Plus what a reservation is not, the three deadlines inside a lease, and the one field that lets a server hand out addresses on a subnet it has never seen."
deck: "A machine plugs in and has an address three seconds later"
track: "network-plus"
level: "working"
order: 430
objectives:
  - "Name the four messages and say what each one is for"
  - "Say why the first two are broadcast and what the source address is"
  - "Distinguish a scope, a range, an exclusion and a reservation"
  - "Read the three deadlines in a lease and say what the client does at each"
  - "Explain how a relay lets one server serve a subnet it is not on"
prerequisites: ["unicast-multicast-anycast-broadcast"]
tags: ["network-plus", "networking", "services"]
updated: 2026-08-12
draft: false
examObjectives:
  - exam: "n10-009"
    domain: "3.0"
    objective: "3.4"
sources:
  - title: "RFC 2131, Dynamic Host Configuration Protocol"
    url: "https://www.rfc-editor.org/rfc/rfc2131"
    publisher: "IETF"
    accessed: 2026-08-12
    tier: 1
  - title: "RFC 2132, DHCP Options and BOOTP Vendor Extensions"
    url: "https://www.rfc-editor.org/rfc/rfc2132"
    publisher: "IETF"
    accessed: 2026-08-12
    tier: 1
  - title: "RFC 3046, DHCP Relay Agent Information Option"
    url: "https://www.rfc-editor.org/rfc/rfc3046"
    publisher: "IETF"
    accessed: 2026-08-12
    tier: 1
  - title: "dnsmasq documentation"
    url: "https://thekelleys.org.uk/dnsmasq/docs/dnsmasq-man.html"
    publisher: "Simon Kelley"
    accessed: 2026-08-12
    tier: 2
symptoms:
  - symptom: "A machine has a 169.254 address and nothing else"
    anchor: "when-there-is-nothing-left-to-give"
  - symptom: "Clients on one subnet get addresses and clients on another do not"
    anchor: "one-server-for-a-subnet-it-is-not-on"
  - symptom: "A device gets a different address every time it reboots"
    anchor: "scopes-ranges-exclusions-and-reservations"
---

> **Before you read.** A laptop is plugged into a wall socket. Three seconds
> later it has an address, a mask, a default gateway, a resolver and a domain
> name, and nobody typed any of them.
>
> The laptop had no address when it started, which means nothing could send it a
> packet.
>
> **How did anything reach it, and how did it end up with the right address for
> that socket rather than for the building next door?**

Almost every address in use anywhere came from this protocol, and its four
messages are among the most examinable things on this exam. They are also worth
knowing properly, because the interesting parts are the addresses on the
envelopes rather than the names of the messages.

### Some words you will need

<dl class="terms">
<dt>scope</dt>
<dd>The server's definition of one subnet: its range, its mask, and the options that go with it.</dd>
<dt>range</dt>
<dd>The block of addresses inside a scope that the server is allowed to hand out.</dd>
<dt>exclusion</dt>
<dd>Addresses inside the range that the server must not hand out.</dd>
<dt>reservation</dt>
<dd>A specific address tied to a specific MAC, so that client always gets it.</dd>
<dt>lease</dt>
<dd>Permission to use an address, for a stated length of time.</dd>
<dt>relay agent</dt>
<dd>Software on a router that forwards a client's broadcast to a server elsewhere.</dd>
</dl>

## What breaks without this

**A machine ends up on 169.254 and cannot reach anything.** Which is topic 07's
APIPA address, and it means nothing answered.

**One subnet works and another does not.** Because the helper address is
configured on three of the four interfaces.

**A device gets a new address every reboot** and every firewall rule naming it
stops matching.

## Four messages, and the addresses on them

The messages are usually memorised as an acronym. The acronym is fine and it is
the least interesting part.

<figure class="learn-figure">
<svg viewBox="0 0 720 300" role="img" aria-labelledby="dora-title" style="width:100%;height:auto;">
<title id="dora-title">The four DHCP messages between a client and a server, with the source and destination address of each, showing that the client sends from 0.0.0.0 to the broadcast address because it has no address yet</title>
<g fill="currentColor">
<text x="14" y="22" font-size="11">four messages, and the addresses are the part worth reading</text>
<rect x="84" y="42" width="132" height="30" rx="3" fill="currentColor" fill-opacity="0.12" stroke="currentColor" stroke-opacity="0.6"/>
<text x="150" y="61" text-anchor="middle" font-size="10.5">client</text>
<rect x="494" y="42" width="132" height="30" rx="3" fill="currentColor" fill-opacity="0.12" stroke="currentColor" stroke-opacity="0.6"/>
<text x="560" y="61" text-anchor="middle" font-size="10.5">server 10.0.0.1</text>
<line x1="150" y1="72" x2="150" y2="278" stroke="currentColor" stroke-opacity="0.3" stroke-width="1"/>
<line x1="560" y1="72" x2="560" y2="278" stroke="currentColor" stroke-opacity="0.3" stroke-width="1"/>
<line x1="156" y1="108" x2="548" y2="108" stroke="var(--accent)" stroke-width="2"/>
<path d="M 554 108 l -9 -5 l 0 10 z" fill="var(--accent)"/>
<text x="355" y="100" text-anchor="middle" font-size="10.5" fill="var(--accent)">DISCOVER</text>
<text x="355" y="124" text-anchor="middle" font-size="9.5" fill-opacity="0.75">0.0.0.0 to 255.255.255.255</text>
<line x1="554" y1="156" x2="162" y2="156" stroke="currentColor" stroke-width="1.6"/>
<path d="M 156 156 l 9 -5 l 0 10 z" fill="currentColor"/>
<text x="355" y="148" text-anchor="middle" font-size="10.5">OFFER</text>
<text x="355" y="172" text-anchor="middle" font-size="9.5" fill-opacity="0.75">10.0.0.1 to 10.0.0.101</text>
<line x1="156" y1="204" x2="548" y2="204" stroke="var(--accent)" stroke-width="2"/>
<path d="M 554 204 l -9 -5 l 0 10 z" fill="var(--accent)"/>
<text x="355" y="196" text-anchor="middle" font-size="10.5" fill="var(--accent)">REQUEST</text>
<text x="355" y="220" text-anchor="middle" font-size="9.5" fill-opacity="0.75">0.0.0.0 to 255.255.255.255</text>
<line x1="554" y1="252" x2="162" y2="252" stroke="currentColor" stroke-width="1.6"/>
<path d="M 156 252 l 9 -5 l 0 10 z" fill="currentColor"/>
<text x="355" y="244" text-anchor="middle" font-size="10.5">ACK</text>
<text x="355" y="268" text-anchor="middle" font-size="9.5" fill-opacity="0.75">10.0.0.1 to 10.0.0.101</text>
<text x="14" y="112" font-size="10" fill="var(--accent)">no address</text>
<text x="14" y="208" font-size="10" fill="var(--accent)">still none</text>
<text x="640" y="112" font-size="10" fill-opacity="0.75">udp/67</text>
<text x="640" y="160" font-size="10" fill-opacity="0.75">udp/68</text>
</g></svg>
<figcaption>The accented messages are the ones the client sends, and both of them go out from 0.0.0.0 to the broadcast address. That is not a design flourish: a machine with no address cannot put a source address on a packet and cannot be sent one, so the only envelope available is the one everybody opens. It also explains why the exchange takes four messages rather than two. The second pair exists because more than one server may have offered, and the request names which offer is being accepted, broadcast so that the servers whose offers were not taken hear it and put their addresses back. The last thing worth reading is the destination of the reply. The server answers to the address it is about to lease, which the client does not have yet and is watching for anyway, which is why the client is still listening on udp/68 with an interface it has not finished configuring.</figcaption>
</figure>

Running it on a real segment produces exactly that, and the client narrates as it
goes.

<details class="predict">
<summary>A client with no address at all, on a segment where the server is present. How many messages does it take, and at which one does the address first appear?</summary>

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology dhcp-lan
# a client with no address at all, on a segment where the server is present
$ ip netns exec h1 dhclient -v -1 h10 2>&1 | tail -5
DHCPDISCOVER on h10 to 255.255.255.255 port 67 interval 6
DHCPOFFER of 10.0.0.101 from 10.0.0.1
DHCPREQUEST for 10.0.0.101 on h10 to 255.255.255.255 port 67
DHCPACK of 10.0.0.101 from 10.0.0.1
bound to 10.0.0.101 -- renewal in 18908 seconds.
$ ip netns exec h1 ip -4 addr show h10 | grep inet
    inet 10.0.0.101/24 brd 10.0.0.255 scope global dynamic h10
$ ip netns exec h1 ip route
default via 10.0.0.254 dev h10 
10.0.0.0/24 dev h10 proto kernel scope link src 10.0.0.101 
$ ip netns exec h1 cat /var/lib/dhcp/dhclient.leases | tail -12
  option dhcp-message-type 5;
  option domain-name-servers 10.0.0.1;
  option dhcp-server-identifier 10.0.0.1;
  option dhcp-renewal-time 21600;
  option broadcast-address 10.0.0.255;
  option dhcp-rebinding-time 37800;
  option host-name "1a816ae0c1cd";
  option domain-name "lab.example";
  renew 4 2026/08/13 01:14:06;
  rebind 4 2026/08/13 06:28:58;
  expire 4 2026/08/13 07:58:58;
}
```

</details>


**The default route is the part to notice.** Nobody configured it. It arrived as
option 3 in the acknowledgement, alongside the resolver and the domain name, and
this is the answer to a question people ask about DHCP without realising: it is
not an address protocol, it is a configuration protocol that happens to start with
an address.

That matters because the option list is long. RFC 2132 defines dozens, and a
device can be handed a time server, a boot file, a proxy configuration URL or a
vendor-specific blob the same way it is handed a gateway. The exam cares about
three of them: the router, the resolver and the domain name.

<details class="deeper">
<summary>If you already run this: why the client asks again for something it was just offered</summary>

The third message looks redundant and it is the one doing the protocol's real work.

More than one server can answer a discovery, and each one offers an address and reserves
it while it waits. The request is broadcast rather than sent to the chosen server, so
every server that offered hears which one won, and the ones that lost release the
addresses they were holding. Without that, a client on a segment with two servers would
consume an address from each on every lease.

It also confirms the client actually got the offer. A server that offers and never hears
a request does not commit the address, which matters when a client vanishes mid-exchange
or when an offer never arrives. The two-step is what keeps the pool from filling with
addresses reserved for clients that never took them.

Worth knowing for troubleshooting: the request carries the identity of the chosen server,
so a capture shows which server won as well as which ones offered. On a segment where a
rogue server is suspected, that field is the evidence, and it is in the client's own
exchange rather than requiring access to any server.

</details>

## Scopes, ranges, exclusions and reservations

Four words that overlap enough to be worth separating precisely.

**A scope is the server's model of one subnet.** Its network, its mask, and the
options that apply to anything on it.

**A range is the part of the scope the server may hand out.** Usually a slice
rather than the whole subnet, because the infrastructure addresses are at one end
and somebody wanted room.

**An exclusion is a hole in the range.** Addresses inside it that the server must
skip, normally because something already uses them.

**A reservation ties one address to one MAC.** The named client always gets that
address, and no other client ever does.

The distinction that gets missed: a reservation is not the same as a statically
configured address. The client still goes through the whole exchange, still holds
a lease, and still gets all the options. It just always ends up at the same place.
That is usually better than configuring the address on the device, because the
address is then recorded in one system rather than on forty machines.

<details class="predict">
<summary>A client with a reservation waiting for it. Does it go through the same four messages as everybody else, and which address does it get?</summary>

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology dhcp-lan
# h2 has a reservation, so it never takes an address from the pool
$ ip netns exec h2 dhclient -v -1 h20 2>&1 | tail -3
DHCPREQUEST for 10.0.0.50 on h20 to 255.255.255.255 port 67
DHCPACK of 10.0.0.50 from 10.0.0.1
bound to 10.0.0.50 -- renewal in 17593 seconds.
# the pool is two addresses wide. h1 and h4 take both of them
$ ip netns exec h1 dhclient -v -1 h10 2>&1 | tail -1
bound to 10.0.0.101 -- renewal in 18316 seconds.
$ ip netns exec h4 dhclient -v -1 h40 2>&1 | tail -1
bound to 10.0.0.100 -- renewal in 20831 seconds.
# and h5 asks for one that no longer exists
$ ip netns exec h5 timeout 30 dhclient -v -1 h50 2>&1 | tail -5
Sending on   Socket/fallback
DHCPDISCOVER on h50 to 255.255.255.255 port 67 interval 5
DHCPDISCOVER on h50 to 255.255.255.255 port 67 interval 14
DHCPDISCOVER on h50 to 255.255.255.255 port 67 interval 8
DHCPDISCOVER on h50 to 255.255.255.255 port 67 interval 12
```

</details>


h2 got 10.0.0.50, which is outside the pool, because a reservation is an address
the pool never touches. That is worth checking on a real server, because a
reservation written for an address that is also inside the range will eventually
be handed to somebody else while the reserved client is switched off.

<details class="deeper">
<summary>If you already manage scopes: the reservation that is worse than a static address</summary>

Reservations look like the tidy answer to every device that needs a fixed address, and
there is a category where they quietly fail.

A reservation is still a lease, so the device has to complete an exchange to get it. A
device that boots before the server is reachable, or on a segment where relaying has
broken, ends up with no address at all rather than with the address it always has. For a
desktop that is an inconvenience. For the infrastructure the exchange itself depends on,
it is a loop: the server needs the network, the network needs the switch, the switch is
waiting for the server.

So anything the recovery of the network depends on takes a static address configured on
the device. Switches, routers, firewalls, the out of band access path, and frequently
the DHCP server itself. Everything else is better as a reservation, because a reservation
is recorded centrally where somebody can find it, and a static address exists only on the
device and in whatever documentation is out of date.

The exclusion is what stops the two colliding. Statically addressed infrastructure sits
in a range the server is told never to hand out, and skipping that step produces the
duplicate address in topic 71: a server offering an address a router has been using for
three years, to a laptop, on a Tuesday.

</details>

## When there is nothing left to give

The last part of that transcript is the whole of what pool exhaustion looks like.

**The client asks, and asks, and asks.** The intervals get longer, nothing
answers, and there is no message meaning "sorry, none left". A server with an
empty pool says nothing at all, which is indistinguishable at the client from a
server that is switched off, a broken cable, or a VLAN with no helper address on
it.

After enough attempts the client gives up and configures a link-local address
itself, which is where topic 07's 169.254 comes from. So the symptom of pool
exhaustion is identical to the symptom of four other faults, and the diagnosis
lives on the server rather than on the machine complaining.

**Two things cause exhaustion in practice**, and neither is usually a growing
headcount. The first is a lease time much longer than the dwell time: a guest
network with a twelve hour lease and visitors who stay ninety minutes holds
addresses for eight people for every one present. The second is a device that
requests a fresh address on every wake, which some client software does when a
network profile changes.

The fix for the first is a shorter lease. That is one of the very few settings in
this protocol worth tuning, and the guide is how long clients typically stay
rather than any number in a book.

## The three deadlines inside a lease

A lease looks like one number and behaves like three.

<figure class="learn-figure">
<svg viewBox="0 0 720 236" role="img" aria-labelledby="lease-title" style="width:100%;height:auto;">
<title id="lease-title">A twelve hour lease with the renewal timer at half of it, the rebinding timer at seven eighths, and expiry at the end, showing what the client does at each</title>
<g fill="currentColor">
<text x="14" y="22" font-size="11">a lease is three deadlines, and the client acts at all of them</text>
<rect x="60" y="86" width="600" height="28" rx="3" fill="currentColor" fill-opacity="0.1" stroke="currentColor" stroke-opacity="0.5"/>
<line x1="60" y1="80" x2="60" y2="120" stroke="currentColor" stroke-opacity="0.75" stroke-width="1.6"/>
<text x="60" y="72" text-anchor="middle" font-size="10.5">granted</text>
<text x="60" y="134" text-anchor="middle" font-size="9.5" fill-opacity="0.75">0</text>
<line x1="360" y1="80" x2="360" y2="120" stroke="currentColor" stroke-opacity="0.75" stroke-width="1.6"/>
<text x="360" y="72" text-anchor="middle" font-size="10.5">T1</text>
<text x="360" y="134" text-anchor="middle" font-size="9.5" fill-opacity="0.75">21600 s</text>
<line x1="585" y1="80" x2="585" y2="120" stroke="currentColor" stroke-opacity="0.75" stroke-width="1.6"/>
<text x="585" y="72" text-anchor="middle" font-size="10.5">T2</text>
<text x="585" y="134" text-anchor="middle" font-size="9.5" fill-opacity="0.75">37800 s</text>
<line x1="660" y1="80" x2="660" y2="120" stroke="currentColor" stroke-opacity="0.75" stroke-width="1.6"/>
<text x="660" y="72" text-anchor="middle" font-size="10.5">expiry</text>
<text x="660" y="134" text-anchor="middle" font-size="9.5" fill-opacity="0.75">43200 s</text>
<rect x="360" y="86" width="225" height="28" fill="var(--accent)" fill-opacity="0.16"/>
<rect x="585" y="86" width="75" height="28" fill="var(--red)" fill-opacity="0.2"/>
<text x="60" y="170" font-size="10.5">T1</text>
<text x="120" y="170" font-size="10.5" fill-opacity="0.85">renew, unicast to the server that granted it</text>
<text x="60" y="190" font-size="10.5" fill="var(--accent)">T2</text>
<text x="120" y="190" font-size="10.5" fill="var(--accent)">rebind, broadcast to any server that answers</text>
<text x="60" y="210" font-size="10.5" fill="var(--red)">expiry</text>
<text x="120" y="210" font-size="10.5" fill="var(--red)">stop using the address</text>
</g></svg>
<figcaption>The three numbers in the lease file above, drawn to scale. The client acts twice before anything expires, which is what makes a lease survive a server being rebooted, and it is why a twelve hour lease does not mean a machine goes quiet for twelve hours. At half the lease it asks the server that granted the address for more time, quietly and directly. If that gets no answer it keeps trying, and at seven eighths it stops addressing the original server and broadcasts instead, on the theory that some other server on the segment might be willing to confirm the lease. Only when the whole period has passed with no answer from anybody does the client have to give the address up, which is the point at which a user notices. The gap between those last two marks is the part people forget exists, and it is why a DHCP server can be down for hours on a network of long leases with nobody reporting anything.</figcaption>
</figure>

The renewal is a unicast to the server, so it does not use the broadcast path and
no relay agent touches it. It still crosses the router when the server sits on
another subnet, which is the ordinary arrangement and the subject of the next
section, but it crosses as ordinary routed traffic rather than as something a
relay has to carry across for it. That is a useful diagnostic: a network where
existing clients keep working and new ones get nothing is a network where the
broadcast path is broken and the unicast path is fine, which points at the relay
rather than at the server.

## One server for a subnet it is not on

A broadcast does not cross a router. That is the definition of a broadcast domain
and it is the entire reason relay agents exist.

<figure class="learn-figure">
<svg viewBox="0 0 720 268" role="img" aria-labelledby="relay-title" style="width:100%;height:auto;">
<title id="relay-title">A client broadcast stopping at a router, the relay agent on that router forwarding it as a unicast to the server with the gateway address field filled in, and the server choosing a pool from that field</title>
<g fill="currentColor">
<text x="14" y="22" font-size="11">a broadcast that stops, and the one field that survives it</text>
<rect x="20" y="82" width="96" height="34" rx="3" fill="currentColor" fill-opacity="0.12" stroke="currentColor" stroke-opacity="0.6"/>
<text x="68" y="103" text-anchor="middle" font-size="10.5">client</text>
<circle cx="290" cy="99" r="34" fill="currentColor" fill-opacity="0.1" stroke="currentColor" stroke-opacity="0.6"/>
<text x="290" y="96" text-anchor="middle" font-size="10">router</text>
<text x="290" y="110" text-anchor="middle" font-size="9.5" fill-opacity="0.75">10.0.2.254</text>
<rect x="580" y="82" width="120" height="34" rx="3" fill="currentColor" fill-opacity="0.12" stroke="currentColor" stroke-opacity="0.6"/>
<text x="640" y="103" text-anchor="middle" font-size="10.5">server 10.0.0.1</text>
<line x1="116" y1="99" x2="244" y2="99" stroke="currentColor" stroke-opacity="0.7" stroke-width="2"/>
<path d="M 250 99 l -9 -5 l 0 10 z" fill="currentColor"/>
<text x="182" y="88" text-anchor="middle" font-size="10">broadcast</text>
<text x="182" y="120" text-anchor="middle" font-size="9.5" fill-opacity="0.75">255.255.255.255</text>
<line x1="332" y1="76" x2="352" y2="122" stroke="var(--red)" stroke-width="2.4"/>
<line x1="352" y1="76" x2="332" y2="122" stroke="var(--red)" stroke-width="2.4"/>
<text x="342" y="142" text-anchor="middle" font-size="10" fill="var(--red)">goes no further</text>
<line x1="372" y1="99" x2="568" y2="99" stroke="var(--accent)" stroke-width="2"/>
<path d="M 574 99 l -9 -5 l 0 10 z" fill="var(--accent)"/>
<text x="470" y="88" text-anchor="middle" font-size="10" fill="var(--accent)">unicast, from the relay</text>
<text x="470" y="120" text-anchor="middle" font-size="9.5" fill-opacity="0.75">10.0.0.254 to 10.0.0.1</text>
<rect x="300" y="176" width="330" height="52" rx="3" fill="var(--accent)" fill-opacity="0.12" stroke="var(--accent)" stroke-opacity="0.9" stroke-width="1.6"/>
<text x="316" y="196" font-size="10" fill-opacity="0.8">giaddr</text>
<text x="316" y="216" font-size="11" fill="var(--accent)">10.0.2.254</text>
<text x="430" y="196" font-size="10" fill-opacity="0.8">hops</text>
<text x="430" y="216" font-size="11">1</text>
<text x="490" y="196" font-size="10" fill-opacity="0.8">chaddr</text>
<text x="490" y="216" font-size="11">02:00:00:00:00:13</text>
<line x1="410" y1="128" x2="410" y2="170" stroke="var(--accent)" stroke-opacity="0.6" stroke-width="1.2" stroke-dasharray="4 3"/>
<text x="20" y="200" font-size="10.5">the server reads giaddr</text>
<text x="20" y="218" font-size="10.5" fill-opacity="0.8">and picks the pool for that subnet</text>
<text x="640" y="252" text-anchor="end" font-size="10" fill-opacity="0.75">reply goes back to 10.0.2.254, not to the client</text>
</g></svg>
<figcaption>The relay solves two problems at once and the second one is easy to miss. The obvious problem is reach: the client's broadcast dies at the router, so something on the router has to pick it up and send it onwards as an ordinary unicast packet that routing can carry. The subtler problem is identity. The server now receives a request that arrived from somewhere else entirely, and nothing in the client's message says which subnet it is sitting on, so the server has no way to know which pool to draw from. The gateway address field is the answer: the relay stamps its own address on that interface into the request, and the server treats that field as the question "which of my scopes covers this address". This is why a relay is configured per interface on a router, and why the address it uses matters as much as the fact that it is running.</figcaption>
</figure>

Watching the same exchange from the server's side shows the field in place.

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology dhcp-lan
# h3 is on a segment with no DHCP server on it. watch what reaches the server
$ (ip netns exec srv timeout 14 tcpdump -i srv0 -n -c 2 -v "udp port 67" > /tmp/far.txt 2>/dev/null &)
$ sleep 2
$ ip netns exec h3 dhclient -v -1 h30 2>&1 | tail -4
DHCPOFFER of 10.0.2.101 from 10.0.2.254
DHCPREQUEST for 10.0.2.101 on h30 to 255.255.255.255 port 67
DHCPACK of 10.0.2.101 from 10.0.2.254
bound to 10.0.2.101 -- renewal in 21132 seconds.
$ sleep 12
$ grep -a "BOOTP/DHCP\|Gateway-IP\|Your-IP\|Client-Ethernet\|Default-Gateway" /tmp/far.txt
    10.0.0.254.67 > 10.0.0.1.67: BOOTP/DHCP, Request from 02:00:00:00:00:13, length 300, hops 1, xid 0x6694ca67, Flags [none]
	  Gateway-IP 10.0.2.254
	  Client-Ethernet-Address 02:00:00:00:00:13
	      Subnet-Mask (1), BR (28), Time-Zone (2), Default-Gateway (3)
    10.0.0.1.67 > 10.0.2.254.67: BOOTP/DHCP, Reply, length 300, hops 1, xid 0x6694ca67, Flags [none]
	  Your-IP 10.0.2.101
	  Gateway-IP 10.0.2.254
	  Client-Ethernet-Address 02:00:00:00:00:13
	    Default-Gateway (3), length 4: 10.0.2.254
```


Three things in there are worth reading twice.

**The client thinks the offer came from 10.0.2.254.** Look at its own output: it
reports the offer as coming from the relay, because that is the address that
appeared on the packet it received. A client never learns the server's address
this way, which is why a rogue server on the local segment and a legitimate one
behind a relay look identical from the client's point of view.

**The gateway address is 10.0.2.254 and the reply's default gateway option is
10.0.2.254.** The server has never seen that subnet, has no interface on it, and
handed out the correct address and the correct gateway for it, entirely from that
one field.

**The exchange between relay and server is unicast on port 67 in both
directions**, which is ordinary routed traffic. Any firewall between a relay and a
server has to permit it, and that rule being absent produces a subnet where
nothing gets an address while everything else works.

The configuration on the router is usually called a helper address, and it takes
the address of the server. The mistake that produces the classic fault is
configuring it on the wrong interface: a relay listens for client broadcasts on
the interface it is configured on, so putting it on the interface facing the
server instead of the one facing the clients produces silence.

<details class="deeper">
<summary>If you already work on networks: why a rogue server wins, what the relay agent information option is for, and the reason snooping exists</summary>

A client takes the first acceptable offer. There is no authentication in this
protocol, no notion of a legitimate server, and no way for a client to tell one
answer from another. Any machine on the segment that answers a DISCOVER is a DHCP
server as far as the client is concerned.

That is why a rogue server wins, and it usually is not malicious. Somebody plugs
a home router in the wrong way round and its LAN port starts handing out
192.168.1.x addresses with itself as the gateway. Every machine that renews after
that gets an address on the wrong network with a default route pointing at a
consumer device in somebody's drawer. The malicious version is the same mechanism
with a machine that forwards traffic while reading it.

There is nothing in the protocol to prevent this, so the answer lives in the
switch. **DHCP snooping** designates ports as trusted and untrusted: server
messages arriving on an untrusted port are dropped. The trusted ports are the ones
facing the real server or the relay, and everything a user can plug into is
untrusted. That converts a protocol with no authentication into a topology
statement about where servers are allowed to be, which is a good example of a
control being placed at the only layer that can enforce it.

**The relay agent information option**, option 82 from RFC 3046, is the other half
of the same idea. A relay can add information about where the request came from:
which port on which switch, and which VLAN. The server can then make decisions
with it, and the snooping database can be checked against it. In carrier and
campus networks this is how an address gets tied to a physical port rather than to
a MAC, which matters because a MAC is trivially changed and a port is not.

One consequence worth knowing. Switches that insert option 82 frequently set the
gateway address to zero while doing so, and servers vary in whether they accept
that. This is a real interoperability problem between a switch doing snooping and
a server expecting a conventional relay, and its symptom is a subnet that stopped
getting addresses on the day somebody enabled a security feature.

</details>

## Across platforms

Every platform is a DHCP client, and each keeps the lease somewhere different.

**On Linux**, the client writes a lease file, which is what the first capture on
this page read. The path varies by client software: `/var/lib/dhcp/` for the ISC
client, `/var/lib/NetworkManager/` or `/run/systemd/netif/leases/` elsewhere.

**On macOS**, the whole packet is available, which is the most useful of the
three.

```bash
# macOS 26.5.2, arm64
$ ipconfig getpacket en0 | head -24
op = BOOTREPLY
htype = 1
flags = 0x0
hlen = 6
hops = 0
xid = 0x36630b74
secs = 0
ciaddr = 0.0.0.0
yiaddr = 192.168.64.13
siaddr = 192.168.64.1
giaddr = 0.0.0.0
chaddr = 4e:d0:7b:35:a2:68
sname = maccloud-iad20-eo1210-mac30
file = 
options:
Options count is 7
dhcp_message_type (uint8): ACK 0x5
server_identifier (ip): 192.168.64.1
lease_time (uint32): 0xe10
subnet_mask (ip): 255.255.255.0
router (ip_mult): {192.168.64.1}
domain_name_server (ip_mult): {192.168.64.1}
end (none): 

# The same lease as a summary, including when it was taken
$ ipconfig getsummary en0 | grep -iE "lease|router|server_identifier|domain_name_server" | head -6
        LeaseExpirationTime : 08/12/2026 21:05:05
        LeaseStartTime : 08/12/2026 20:05:05
server_identifier (ip): 192.168.64.1
lease_time (uint32): 0xe10
router (ip_mult): {192.168.64.1}
domain_name_server (ip_mult): {192.168.64.1}
```

Those field names are the ones in the relay figure above. `yiaddr` is the address
being granted, `giaddr` is the gateway address field, and here it is zero because
this machine is on the same segment as its server. `lease_time` is `0xe10`, which
is 3600 seconds, and the two timestamps are an hour apart, so the numbers agree
with each other.

**On Windows**, the same facts arrive in two places.

```powershell
# Microsoft Windows Server 2025 Datacenter, version 10.0.26100.0
> ipconfig /all | Select-String -Pattern "DHCP Enabled|DHCP Server|Lease Obtained|Lease Expires|IPv4 Address|Default Gateway"
   DHCP Enabled. . . . . . . . . . . : Yes
   IPv4 Address. . . . . . . . . . . : 10.1.0.102(Preferred)
   Lease Obtained. . . . . . . . . . : Wednesday, August 12, 2026 8:06:53 PM
   Lease Expires . . . . . . . . . . : Sunday, September 19, 2162 2:36:59 AM
   Default Gateway . . . . . . . . . : 10.1.0.1
   DHCP Server . . . . . . . . . . . : 168.63.129.16
   DHCP Enabled. . . . . . . . . . . : No
   IPv4 Address. . . . . . . . . . . : 172.17.176.1(Preferred)
   Default Gateway . . . . . . . . . :

# The same lease through the cmdlet, where the origin of each address is a field
> Get-NetIPAddress -AddressFamily IPv4 | Format-Table InterfaceAlias, IPAddress, PrefixOrigin, SuffixOrigin, AddressState -AutoSize
InterfaceAlias              IPAddress    PrefixOrigin SuffixOrigin AddressState
--------------              ---------    ------------ ------------ ------------
vEthernet (nat)             172.17.176.1       Manual       Manual    Preferred
Ethernet 3                  10.1.0.102           Dhcp         Dhcp    Preferred
Loopback Pseudo-Interface 1 127.0.0.1       WellKnown    WellKnown    Preferred
```

The lease expiry on that machine is in the year 2162. That is not an error: this
is a cloud instance, and the platform issues a lease long enough that it never
renews, because the address is decided by the platform rather than negotiated.
Reading it as a fault is the mistake, and it is the kind of thing worth having
seen once.

The second block is the one to remember for troubleshooting, because `PrefixOrigin
Dhcp` against `Manual` answers "did this address come from a server or did
somebody type it" in one column, which `ipconfig` makes you infer.

## Prove it

**Watch your own machine get an address.** Release and renew on any platform with
a capture running, and count four messages. `ipconfig /release` and `/renew` on
Windows, `sudo ipconfig set en0 DHCP` on macOS, `dhclient -r` and `dhclient` on
Linux.

**Read your own lease.** Then work out the renewal time from it. It should be half
the lease, and if it is not, the server has sent explicit values.

**Find the helper address.** On any router or firewall you administer, find where
the DHCP server address is configured and note which interface it is on. That is
the configuration behind the relay figure.

## What trips people up

### 1. Thinking the client has an address during the exchange

The first two client messages go from 0.0.0.0 to the broadcast address. It has
nothing to put in the source field and nothing that could be unicast to it.

### 2. Assuming the second pair of messages is redundant

More than one server may have offered. The request names which offer is accepted
and is broadcast so the others can release the addresses they set aside.

### 3. Confusing a reservation with a static address

A reservation still goes through the whole exchange and still holds a lease. The
address lives in the server's configuration rather than on the device, which is
where you want it.

### 4. Expecting an error when the pool is empty

There is no such message. The client asks repeatedly, hears nothing, and ends up
on a 169.254 address, which looks exactly like a server that is switched off.

### 5. Reading a lease as one deadline

The client renews at half, rebinds at seven eighths, and only gives the address up
at the end. A server can be down for a long time without anybody noticing.

### 6. Configuring the helper address on the wrong interface

A relay listens for client broadcasts on the interface it is configured on. Facing
it at the server rather than at the clients produces a subnet where nothing gets
an address.

## Work it through

The laptop that got everything three seconds after being plugged in.

The mechanism is the four messages, and the honest answer to "how did anything
reach it" is that nothing reached it in the ordinary sense. It broadcast from
0.0.0.0, which every machine on the segment received and almost all of them
discarded, and the server replied to an address that the laptop did not yet own
but was already watching for.

**The second half of the question is the more interesting one.** How it got the
right address for that socket depends on which network it is.

If the DHCP server is on the same VLAN as the socket, there is nothing to explain.
The broadcast reached it directly and it drew from the only pool it has for that
segment.

If the server is central, which it is in most buildings, then the router serving
that VLAN has a helper address configured, its relay agent picked the broadcast up
and stamped the gateway address field with its own address on that interface, and
the server chose the scope matching that address. Move the same laptop to a socket
in a different VLAN and the same server hands out a different address, from a
different pool, with a different gateway, because a different interface address
went into that field.

**That is also the diagnostic path when it does not work.** Start at the socket and
ask which VLAN it is in, because a socket patched to the wrong VLAN produces
exactly this fault and is more common than any server problem. Then ask whether
that VLAN's interface has a helper address, and whether it points at a server that
still exists. Then check whether the server has a scope for that subnet at all,
because a new VLAN with a helper address and no matching scope produces silence
that looks identical to a missing helper.

And if some clients on that VLAN work and new ones do not, stop looking at the
server. Renewals are unicast and do not use the relay, so working clients prove
the routed path is fine and prove nothing about the broadcast path. That
combination is close to a fingerprint for a relay problem.

## Try it

**Shorten a lease and watch what happens.** On any lab network, set a two minute
lease and leave a capture running. The renewal traffic at half the lease is the
part nobody has usually seen.

**Fill a pool.** Set a range of two addresses and connect three clients. The third
one's behaviour is worth watching once, because that pattern is what every
exhaustion incident looks like from the client.

**Make a reservation for a machine you own.** Then check whether the address you
chose is inside the range, and move it out if it is.

## Check yourself

<details class="qa">
<summary>Why does a DHCP client send its first two messages from 0.0.0.0 to 255.255.255.255?</summary>

Because it has no address. It cannot put a source address on the packet, and
nothing can send it a unicast reply, so the only envelope available in both
directions is broadcast.

That constraint also explains the shape of the exchange: the server replies to the
address it is about to grant, which the client does not yet hold but is already
listening for on udp/68.

</details>

<details class="qa">
<summary>Why are there four messages rather than two?</summary>

Because more than one server may answer. The offer is one server's proposal, and
the request names which proposal the client is accepting.

The request is broadcast rather than unicast so that the servers whose offers were
not taken can hear it and release the addresses they had set aside. Without that
second pair, every server would have to hold an address for every client it ever
offered to.

</details>

<details class="qa">
<summary>A client is on a subnet with no DHCP server. What has to exist on the router, and what does it add to the message?</summary>

A relay agent, configured on the interface facing the clients, with the address of
the server. It receives the client's broadcast and sends it onwards as an ordinary
unicast packet that routing can deliver.

It also fills in the gateway address field with its own address on that interface.
That field is how the server, which has no interface on the client's subnet,
decides which scope to draw from, and it is why the reply carries the correct
gateway for the far subnet rather than for the server's own.

</details>

<details class="qa">
<summary>Existing clients on a VLAN keep working and newly connected ones get 169.254 addresses. Where is the fault most likely to be?</summary>

In the broadcast path, which means the relay rather than the server. Renewals are
unicast from the client to the server and never involve a relay, so existing
clients prove that routing and the server are both fine.

A new client has only the broadcast path available. A missing or misconfigured
helper address, a scope that does not exist for that subnet, or a firewall
blocking the relay to server traffic all produce this, and all three look the same
from the client.

</details>

<details class="qa">
<summary>What is the difference between a reservation and an exclusion?</summary>

An exclusion is a hole in the range: addresses the server must never hand out,
usually because something already uses them.

A reservation ties one address to one client's MAC, so that client always receives
it and nobody else ever does. The client still performs the full exchange and
still holds a lease, which is what separates it from configuring the address on
the device by hand.

</details>

## References

- [RFC 2131](https://www.rfc-editor.org/rfc/rfc2131) - IETF, the protocol itself, including the four messages, the renewal and rebinding timers, and the relay agent's use of the gateway address field. Free. Accessed 2026-08-12.
- [RFC 2132](https://www.rfc-editor.org/rfc/rfc2132) - IETF, the option numbers, including the router, resolver and domain name options in the capture. Free. Accessed 2026-08-12.
- [RFC 3046](https://www.rfc-editor.org/rfc/rfc3046) - IETF, the relay agent information option. Free. Accessed 2026-08-12.
- [dnsmasq(8)](https://thekelleys.org.uk/dnsmasq/docs/dnsmasq-man.html) - Simon Kelley, the server used in the lab, on ranges, reservations and tagging by relay address. Accessed 2026-08-12.
- [ipconfig(8)](https://keith.github.io/xcode-man-pages/ipconfig.8.html) - Apple, on `getpacket` and `getsummary`. Accessed 2026-08-12.

**Where the output came from.** Every Linux block was captured on the `dhcp-lan`
namespace topology through `blog/scripts/netlab.sh`: a real server, real clients
with no addresses configured, and a router running a real relay agent. The pool is
deliberately two addresses wide so that exhaustion happens on the third client
rather than after a wait nobody would sit through, and the reservation is outside
the pool because that is how one should be written. The Windows and macOS blocks
came from GitHub Actions runners through `blog/scripts/hostcap.sh`, which is why
the Windows lease belongs to a cloud instance and expires in 2162.

**If you also work on Linux.** [Configuring networking](/learn/linux-plus/configuring-networking)
on the Linux+ track covers the client side as a configuration task: which service
is asking, where it writes what it was given, and how to make a machine stop asking
and use a static address instead.
