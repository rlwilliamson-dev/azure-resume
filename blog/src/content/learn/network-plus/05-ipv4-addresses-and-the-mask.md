---
title: "IPv4 addresses and the mask"
description: "An IPv4 address is 32 bits and the mask is a line drawn through them. Where that line falls decides which addresses are neighbours, which two you cannot give to anything, and why the obvious answer to how many machines fit is wrong twice."
deck: "Sixty-two, not sixty-four"
track: "network-plus"
level: "intro"
order: 60
objectives:
  - "Read an address in CIDR notation and say where the boundary falls"
  - "Work out the network address, the broadcast address and the usable range for any mask"
  - "Say how many machines fit in a given prefix, without a calculator"
  - "Recognise the eight values a mask octet can legally hold"
  - "Predict which of two addresses can reach the other directly"
prerequisites: ["the-boxes-on-a-network"]
tags: ["network-plus", "networking", "subnetting", "beginner"]
updated: 2026-08-10
draft: false
examObjectives:
  - exam: "n10-009"
    domain: "1.0"
    objective: "1.7"
sources:
  - title: "RFC 4632, Classless Inter-domain Routing (CIDR)"
    url: "https://www.rfc-editor.org/rfc/rfc4632"
    publisher: "IETF"
    accessed: 2026-08-10
    tier: 1
  - title: "RFC 950, Internet Standard Subnetting Procedure"
    url: "https://www.rfc-editor.org/rfc/rfc950"
    publisher: "IETF"
    accessed: 2026-08-10
    tier: 1
  - title: "RFC 919, Broadcasting Internet Datagrams"
    url: "https://www.rfc-editor.org/rfc/rfc919"
    publisher: "IETF"
    accessed: 2026-08-10
    tier: 1
  - title: "RFC 3021, Using 31-Bit Prefixes on IPv4 Point-to-Point Links"
    url: "https://www.rfc-editor.org/rfc/rfc3021"
    publisher: "IETF"
    accessed: 2026-08-10
    tier: 1
  - title: "RFC 1878, Variable Length Subnet Table For IPv4"
    url: "https://www.rfc-editor.org/rfc/rfc1878"
    publisher: "IETF"
    accessed: 2026-08-10
    tier: 1
  - title: "subnetting practice"
    url: "https://subnetipv4.com/"
    publisher: "subnetipv4.com"
    accessed: 2026-08-10
    tier: 2
  - title: "inet_aton(3)"
    url: "https://man7.org/linux/man-pages/man3/inet_aton.3.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-10
    tier: 1
symptoms:
  - symptom: "Two machines on the same switch cannot reach each other"
    anchor: "the-boundary-in-action"
  - symptom: "Network is unreachable for an address that looks local"
    anchor: "the-boundary-in-action"
---

> **Before you read.** You are handed `192.168.10.0/26` and asked how many
> machines it will hold.
>
> The obvious answer is 64. It is wrong, and it is wrong for two separate
> reasons, one of which most people get to eventually and one of which they
> usually do not.
>
> **How many, and what are the two reasons?**

Topic 01 showed the mask deciding who counts as a neighbour, and left the
arithmetic alone. This topic is the arithmetic, because everything from here on
depends on it: DHCP scope sizing, access lists, and the single most common
misconfiguration in networking all come back to where a boundary falls.

This is also the one skill on this exam that only repetition fixes. The
explanation takes twenty minutes. Getting fast takes a hundred problems, and
there is a link at the end for that.

### Some words you will need

<dl class="terms">
<dt>bit</dt>
<dd>One binary digit, 0 or 1. An IPv4 address is 32 of them.</dd>
<dt>octet</dt>
<dd>Eight bits, which is one of the four numbers in a dotted decimal address.</dd>
<dt>prefix</dt>
<dd>The leading bits that name the network. The number after the slash is how many.</dd>
<dt>network address</dt>
<dd>The first address in a range, with all host bits zero. It names the network rather than a machine.</dd>
<dt>broadcast address</dt>
<dd>The last address in a range, with all host bits one. Traffic to it goes to everything on that network.</dd>
<dt>usable range</dt>
<dd>Everything between those two. The addresses you can actually give to machines.</dd>
<dt>CIDR notation</dt>
<dd>Writing the prefix length after a slash, as in <code>/26</code>, instead of a dotted mask.</dd>
</dl>

## What breaks without this

**You size a network wrong and find out months later.** A /26 planned for 64
machines takes 62, and the two you cannot use are discovered when the sixty-third
person joins.

**You cannot read a firewall rule or a routing table.** Both are written in this
notation, and a rule that says `/24` where you meant `/25` silently covers twice
what you intended.

**The commonest fault in networking becomes invisible to you.** Two correctly
configured machines that cannot see each other, because a boundary falls between
them, looks like broken hardware until you do the arithmetic.

## Thirty-two bits, wearing a disguise

An IPv4 address is a 32 bit number. Dotted decimal is a convenience for humans,
and it hides the thing the mask actually operates on.

```
192  .  168  .  10   .  1
11000000 10101000 00001010 00000001
```

Four groups of eight bits, written as four numbers between 0 and 255, because 255
is what eight bits can count to. The dots are punctuation. The address is one
number and the machine treats it as one number.

**Binary is not optional here, and it is not as much of it as you fear.** You
need eight bit patterns and a short list of powers of two, and you never need to
convert a whole address by hand.

<details class="deeper">
<summary>If you already work on networks: proving the address really is one number, and the trouble that causes</summary>

The claim that dotted decimal is only presentation is easy to make and easy to
demonstrate. Every tool that takes an address parses it through the same C
library function, and that function accepts several spellings of the same 32 bit
value.

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology two-hosts
# the same address, written four ways
$ ip netns exec h1 ping -c 1 127.0.0.1
PING 127.0.0.1 (127.0.0.1) 56(84) bytes of data.
64 bytes from 127.0.0.1: icmp_seq=1 ttl=64 time=0.012 ms

--- 127.0.0.1 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 0.012/0.012/0.012/0.000 ms
$ ip netns exec h1 ping -c 1 2130706433
PING 2130706433 (127.0.0.1) 56(84) bytes of data.
64 bytes from 127.0.0.1: icmp_seq=1 ttl=64 time=0.005 ms

--- 2130706433 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 0.005/0.005/0.005/0.000 ms
$ ip netns exec h1 ping -c 1 0x7f000001
PING 0x7f000001 (127.0.0.1) 56(84) bytes of data.
64 bytes from 127.0.0.1: icmp_seq=1 ttl=64 time=0.003 ms

--- 0x7f000001 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 0.003/0.003/0.003/0.000 ms
$ ip netns exec h1 ping -c 1 127.1
PING 127.1 (127.0.0.1) 56(84) bytes of data.
64 bytes from 127.0.0.1: icmp_seq=1 ttl=64 time=0.003 ms

--- 127.1 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 0.003/0.003/0.003/0.000 ms
```

Four spellings, one address. `2130706433` is the decimal value of the whole 32 bit
number. `0x7f000001` is the same value in hex, one byte per pair. `127.1` is the
short form the parser allows, where the last part fills all the remaining bytes,
so it means 127.0.0.1 rather than 127.0.1 or 127.1.0.0.

Notice that ping printed the address you typed and then the address it resolved
to, in brackets, on each line. That second value is the only one the network
sees.

This is a curiosity right up until it is a vulnerability. Software that decides
whether an address is safe by matching the text rather than by parsing it can be
walked past with a spelling it did not expect. A filter looking for the string
`127.0.0.1` sees nothing to block in `2130706433`, and the connection goes to
loopback regardless. The lesson generalises well beyond addresses: compare values
after parsing, never the text you were handed.

</details>

## The mask is a line drawn through those bits

The mask says where the network part stops and the host part begins. Everything
to the left of the line is which network. Everything to the right is which
machine on it.

<figure class="learn-figure">
<svg viewBox="0 0 720 250" role="img" aria-labelledby="mask-title" style="width:100%;height:auto;">
  <title id="mask-title">A slash 26 mask drawn as a boundary through the 32 bits of an address</title>
  <g font-family="ui-monospace, monospace">
    <text x="12" y="26" font-size="12" fill="currentColor" fill-opacity="0.75">192.168.10.1/26, as the machine holds it</text>
    <rect x="12" y="40" width="474" height="44" rx="3" fill="currentColor" fill-opacity="0.12" stroke="currentColor" stroke-opacity="0.45"/>
    <rect x="486" y="40" width="222" height="44" rx="3" fill="currentColor" fill-opacity="0.04" stroke="currentColor" stroke-opacity="0.45" stroke-dasharray="5 4"/>
    <text x="249" y="60" text-anchor="middle" font-size="12" fill="currentColor">26 bits: which network</text>
    <text x="249" y="76" text-anchor="middle" font-size="10.5" fill="currentColor" fill-opacity="0.7">the same for every machine here</text>
    <text x="597" y="60" text-anchor="middle" font-size="12" fill="currentColor">6 bits: which machine</text>
    <text x="597" y="76" text-anchor="middle" font-size="10.5" fill="currentColor" fill-opacity="0.7">2 to the power 6 = 64 combinations</text>
    <text x="12" y="110" font-size="11.5" fill="currentColor" fill-opacity="0.85">11000000 10101000 00001010 00</text>
    <text x="486" y="110" font-size="11.5" fill="currentColor" fill-opacity="0.85">000001</text>
  </g>
  <g stroke="currentColor" stroke-opacity="0.8" stroke-width="2" fill="none">
    <path d="M486 32 L486 122"/>
  </g>
  <g font-family="ui-monospace, monospace" font-size="11" fill="currentColor" fill-opacity="0.8">
    <text x="492" y="30">the boundary</text>
  </g>
  <g font-family="ui-monospace, monospace">
    <text x="12" y="152" font-size="12" fill="currentColor" fill-opacity="0.75">the 64 combinations, and the two that are spoken for</text>
    <rect x="12" y="164" width="120" height="38" rx="3" fill="currentColor" fill-opacity="0.05" stroke="currentColor" stroke-opacity="0.5" stroke-dasharray="4 3"/>
    <text x="72" y="181" text-anchor="middle" font-size="11" fill="currentColor">000000</text>
    <text x="72" y="196" text-anchor="middle" font-size="10" fill="currentColor" fill-opacity="0.72">.0 network</text>
    <rect x="140" y="164" width="426" height="38" rx="3" fill="currentColor" fill-opacity="0.14" stroke="currentColor" stroke-opacity="0.5"/>
    <text x="353" y="181" text-anchor="middle" font-size="11" fill="currentColor">000001 through 111110</text>
    <text x="353" y="196" text-anchor="middle" font-size="10" fill="currentColor" fill-opacity="0.72">.1 to .62, the 62 you can use</text>
    <rect x="574" y="164" width="134" height="38" rx="3" fill="currentColor" fill-opacity="0.05" stroke="currentColor" stroke-opacity="0.5" stroke-dasharray="4 3"/>
    <text x="641" y="181" text-anchor="middle" font-size="11" fill="currentColor">111111</text>
    <text x="641" y="196" text-anchor="middle" font-size="10" fill="currentColor" fill-opacity="0.72">.63 broadcast</text>
    <text x="12" y="228" font-size="10.5" fill="currentColor" fill-opacity="0.7">dashed = reserved, cannot be given to a machine</text>
  </g>
</svg>
<figcaption>A slash 26 puts the boundary 26 bits in, leaving 6 bits to number machines. Six bits give 64 combinations, from 000000 to 111111. The all-zeros combination is the network address, 192.168.10.0, which names the network itself. The all-ones combination is the broadcast address, 192.168.10.63, which reaches everything on it. Neither can be assigned to a machine, so 64 combinations yield 62 usable addresses. The two reserved blocks are drawn with dashed outlines and labelled; the shading is decoration.</figcaption>
</figure>

There is the answer to the question at the top. **Sixty-two.** Wrong for two
reasons: 64 is the count of combinations rather than of machines, and two of
those combinations are spoken for.

The formula people memorise is 2 to the power of the host bits, minus 2. It is
worth understanding rather than memorising, because the minus 2 is the part that
gets misapplied.

<details class="deeper">
<summary>If you already work on networks: what happens when two machines on one wire disagree about where the line is</summary>

The mask is configured per machine, and nothing enforces that neighbours agree.
Give one machine the wrong one and you get a fault that is genuinely confusing
the first time, because each machine is behaving correctly according to what it
was told.

Two hosts on a single cable. One has a /24, the other a /25, and the addresses
are chosen so that only one of them thinks the other is local.

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology two-hosts
# same wire, two machines, one of them given the wrong mask
$ ip -n h1 addr add 10.0.0.1/24 dev h1eth0
$ ip -n h2 addr add 10.0.0.200/25 dev h2eth0
$ ip -n h1 route
10.0.0.0/24 dev h1eth0 proto kernel scope link src 10.0.0.1 
$ ip -n h2 route
10.0.0.128/25 dev h2eth0 proto kernel scope link src 10.0.0.200 
# h1 believes h2 is local, and gets an ARP reply proving h2 is there
$ ip netns exec h1 ping -c 2 -W 1 10.0.0.200
PING 10.0.0.200 (10.0.0.200) 56(84) bytes of data.

--- 10.0.0.200 ping statistics ---
2 packets transmitted, 0 received, 100% packet loss, time 1039ms

$ ip -n h1 neigh show
10.0.0.200 dev h1eth0 INCOMPLETE 
```

Look at the two route tables. `10.0.0.0/24` includes `10.0.0.200`, so h1 considers
h2 a neighbour. `10.0.0.128/25` starts at `.128`, so `10.0.0.1` is outside it and
h2 considers h1 somewhere else entirely.

The ping gets nothing back and the neighbour table says `INCOMPLETE`, which is
the kernel reporting that it asked and nobody answered. Read on its own, that
looks exactly like a machine that is switched off.

It is not. The request is arriving.

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology two-hosts
$ ip -n h1 addr add 10.0.0.1/24 dev h1eth0
$ ip -n h2 addr add 10.0.0.200/25 dev h2eth0
# does h2 even hear the request? capture on h2 while h1 asks
$ (ip netns exec h2 timeout 6 tcpdump -i h2eth0 -n -e arp > /tmp/a.txt 2>/dev/null &)
$ sleep 2
$ ip netns exec h1 ping -c 1 -W 1 10.0.0.200 > /dev/null 2>&1
$ sleep 5
$ cat /tmp/a.txt
20:28:57.924253 02:00:00:00:01:01 > ff:ff:ff:ff:ff:ff, ethertype ARP (0x0806), length 42: Request who-has 10.0.0.200 tell 10.0.0.1, length 28
20:28:58.959310 02:00:00:00:01:01 > ff:ff:ff:ff:ff:ff, ethertype ARP (0x0806), length 42: Request who-has 10.0.0.200 tell 10.0.0.1, length 28
20:28:59.983252 02:00:00:00:01:01 > ff:ff:ff:ff:ff:ff, ethertype ARP (0x0806), length 42: Request who-has 10.0.0.200 tell 10.0.0.1, length 28

# give h2 a way back to 10.0.0.1 and nothing else changes
$ ip -n h2 route add 10.0.0.0/25 dev h2eth0
$ ip netns exec h1 ping -c 2 -W 1 10.0.0.200
PING 10.0.0.200 (10.0.0.200) 56(84) bytes of data.
64 bytes from 10.0.0.200: icmp_seq=1 ttl=64 time=0.042 ms
64 bytes from 10.0.0.200: icmp_seq=2 ttl=64 time=0.066 ms

--- 10.0.0.200 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1039ms
rtt min/avg/max/mdev = 0.042/0.054/0.066/0.012 ms
```

Three requests reach h2 and no reply leaves. h2 has the address being asked for,
so it has an answer to give, and to give it it must send a frame back to
`10.0.0.1`. That address is outside its /25 and it has no route for anything
outside its /25, so the answer has nowhere to go. Adding a route back is enough
to fix it, and notice that h1 was never touched.

Two things worth taking from this. An `INCOMPLETE` neighbour entry means no
answer arrived, and that is a different statement from the machine being absent.
And when connectivity fails between two machines on the same wire, check both
masks before anything else, because a mismatch produces symptoms that point at
the wrong end.

</details>

## The boundary in action

The kernel does this arithmetic every time an address is assigned, and it will
show you its working.

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology two-hosts
# commands run on h1
# ask the kernel to work the mask out for us
$ ip addr add 192.168.10.1/26 brd + dev h1eth0
$ ip addr show h1eth0 | grep "inet "
    inet 192.168.10.1/26 brd 192.168.10.63 scope global h1eth0
# and the route that address implies
$ ip route
192.168.10.0/26 dev h1eth0 proto kernel scope link src 192.168.10.1 
```

`brd +` asks the kernel to compute the broadcast address rather than being told
it, and it answers `192.168.10.63`. The route it wrote by itself is
`192.168.10.0/26`. Both numbers came out of the mask, and both match the diagram.

Now watch the boundary decide something.

<details class="predict">
<summary>h1 is <code>192.168.10.1/26</code>. It pings <code>192.168.10.62</code>, then a machine is moved to <code>192.168.10.65</code> and it pings that. Both are on the same cable. What happens to each, and what does the neighbour table show afterwards?</summary>

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology two-hosts
# both hosts in the same /26
$ ip -n h1 addr add 192.168.10.1/26 brd + dev h1eth0
$ ip -n h2 addr add 192.168.10.62/26 brd + dev h2eth0
$ ip netns exec h1 ping -c 1 -W 2 192.168.10.62 | tail -2
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 0.030/0.030/0.030/0.000 ms
# now move h2 one address further on, to .65
$ ip -n h2 addr del 192.168.10.62/26 dev h2eth0
$ ip -n h2 addr add 192.168.10.65/26 brd + dev h2eth0
$ ip netns exec h1 ping -c 1 -W 2 192.168.10.65
ping: connect: Network is unreachable
# h1 did not even ask who .65 was
$ ip -n h1 neigh show
192.168.10.62 dev h1eth0 lladdr 02:00:00:00:01:02 REACHABLE 
```

</details>

`.62` works. `.65` fails instantly, and it is the same machine on the same cable
with the same hardware. Only the number changed.

The neighbour table is the detail worth stopping on. It still holds the entry for
`.62`, learned when that ping worked, and there is no entry at all for `.65`.
**h1 never asked who `.65` was**, because it had already decided the address was
not local and there was no router to hand it to.

Why `.65` and not `.64`? Because `192.168.10.63` is the last address in this /26.
The next /26 starts at `.64`, and its own network address is `.64`, so the first
machine you could put there is `.65`. Two addresses apart on paper, on different
networks in fact.

<details class="deeper">
<summary>If you already work on networks: why the two addresses are reserved, and the case where they are not</summary>

The all-ones host part being a broadcast is specified in RFC 919, which defines
the directed broadcast for a network. The all-zeros form has an older history:
RFC 950 describes it as having been used to mean "this network", and both ends of
the range were kept out of the host pool because a host that used one could not
be distinguished from the network or from a broadcast.

The practical consequence is the minus 2 in every subnetting question you will
answer. The interesting part is that there is a documented exception, and the
exam does not ask about it while real networks use it constantly.

**RFC 3021 permits a /31 on a point-to-point link.** With one host bit there are
two combinations, and subtracting two would leave zero usable addresses, which
makes the prefix useless by the normal rule. On a link with exactly two devices
and no broadcast to speak of, neither reserved address is needed, so both are
assigned and the link uses two addresses instead of four. Routers use this
between each other constantly, and it halves the address waste of a network full
of point-to-point links.

A /32 is the other edge. One address, no host bits, no range. It is used for a
loopback on a router or to name one specific destination in a routing table,
which is where topic 21's longest prefix match will meet it.

Worth knowing how the mask is actually stored, because it explains the legal
values. It is a 32 bit number whose bits are all ones then all zeros, never
mixed. `255.255.255.192` is 26 ones followed by 6 zeros. That is why a mask octet
can only be one of eight values, and why `255.255.255.100` is not a mask at all
rather than an unusual one.

</details>

## The eight values, and the powers of two

Two short lists do most of the work, and they are worth knowing cold rather than
deriving each time.

**A mask octet can only hold these values**, because the bits fill from the left
and never leave a gap:

| Bits set | Value | As a prefix, in the last octet |
| --- | --- | --- |
| 0 | 0 | /24 |
| 1 | 128 | /25 |
| 2 | 192 | /26 |
| 3 | 224 | /27 |
| 4 | 240 | /28 |
| 5 | 248 | /29 |
| 6 | 252 | /30 |
| 7 | 254 | /31 |
| 8 | 255 | /32 |

Anything else in a mask is a typo. That alone rules out a whole class of wrong
answers before you calculate anything.

**And the powers of two**, which give the size of a block:

| Host bits | Combinations | Usable |
| --- | --- | --- |
| 2 | 4 | 2 |
| 3 | 8 | 6 |
| 4 | 16 | 14 |
| 5 | 32 | 30 |
| 6 | 64 | 62 |
| 7 | 128 | 126 |
| 8 | 256 | 254 |

The second column is also the step between one network and the next, which is the
fastest way to find where a given address falls. A /26 has 64 combinations, so
the /26 networks in `192.168.10.0` start at `.0`, `.64`, `.128` and `.192`. An
address of `.100` is in the third one, and you found that by counting in 64s
rather than by converting anything to binary.

<details class="deeper">
<summary>If you already work on networks: the other mask, which looks like this one written backwards</summary>

Sooner or later you will read a configuration line containing `0.0.0.255` and
wonder why the mask is inside out. It is not a mask that has been typed wrong. It
is a wildcard mask, and it is a different tool that happens to look similar.

A subnet mask marks the network part with ones. A wildcard mask marks the bits
that are allowed to differ, so a zero means the bit must match and a one means do
not care. For a whole /24 that gives `0.0.0.255`: the first three octets must
match exactly, the last one can be anything.

Converting between them is subtraction. Take each octet away from 255.

| Prefix | Subnet mask | Wildcard mask |
| --- | --- | --- |
| /24 | 255.255.255.0 | 0.0.0.255 |
| /26 | 255.255.255.192 | 0.0.0.63 |
| /30 | 255.255.255.252 | 0.0.0.3 |
| /32 | 255.255.255.255 | 0.0.0.0 |

The bottom row is the one to remember, because a single host in an access list is
written with an all-zeros wildcard, and that reads as "no mask at all" to anyone
expecting subnet masks.

There is a real capability difference underneath the arithmetic, not just a
notation difference. A subnet mask has to be a run of ones followed by a run of
zeros, because it is drawing one boundary. A wildcard mask makes a decision per
bit, so its ones do not have to be contiguous, and a rule can be written to match
something a subnet mask could never express. Support for that varies by platform
and it is rare in practice, but it is why the two are separate ideas rather than
one idea written two ways.

You meet these again in the access list topic. For now the useful reflex is
recognising which one you are looking at: leading 255s make it a subnet mask,
leading 0s make it a wildcard.

</details>

## Across platforms

The mask is the same 32 bits wherever you look at it. The three platforms write
it three different ways, and only one of them is the notation this topic has
been using.

| Task | Linux | Windows | macOS |
| --- | --- | --- | --- |
| Show the address and its mask | `ip -brief addr show` | `ipconfig` | `ifconfig en0` |
| The notation you get | `192.168.10.1/24` | `255.255.255.0` | `0xffffff00` |
| Get a prefix length | it is already one | `Get-NetIPAddress` | convert it yourself |
| Get dotted decimal | convert it yourself | it is already one | `ipconfig getoption en0 subnet_mask` |

Windows first, where a prefix length does exist and `ipconfig` is not the tool
that shows it.

```powershell
# Microsoft Windows Server 2025 Datacenter, version 10.0.26100.0
> ipconfig | Select-String -Pattern "IPv4 Address|Subnet Mask"
   IPv4 Address. . . . . . . . . . . : 10.1.0.124
   Subnet Mask . . . . . . . . . . . : 255.255.240.0
   IPv4 Address. . . . . . . . . . . : 192.168.112.1
   Subnet Mask . . . . . . . . . . . : 255.255.240.0

# A prefix length does exist on Windows. This is where it lives
> Get-NetIPAddress -AddressFamily IPv4 | Format-Table InterfaceAlias, IPAddress, PrefixLength, PrefixOrigin -AutoSize
InterfaceAlias              IPAddress     PrefixLength PrefixOrigin
--------------              ---------     ------------ ------------
vEthernet (nat)             192.168.112.1           20       Manual
Ethernet 3                  10.1.0.124              20         Dhcp
Loopback Pseudo-Interface 1 127.0.0.1                8    WellKnown
```

`Subnet Mask 255.255.240.0` and `PrefixLength 20` describe the same interface on
the same machine, printed by two tools that shipped twenty years apart. Convert
either one and you get the other: 255 is eight ones, 255 is eight more, 240 is
`11110000` which is four, and 8 plus 8 plus 4 is 20.

`PrefixOrigin` is worth noticing while it is on screen. It says where the address
came from, and `Dhcp` against `Manual` against `WellKnown` is a distinction the
next topic makes use of.

macOS is the one that catches people.

```bash
# macOS 26.5.2, arm64
$ ifconfig en0 | grep -E "inet "
	inet 192.168.64.3 netmask 0xffffff00 broadcast 192.168.64.255

# The same fact asked for directly, which comes back in dotted decimal
$ ipconfig getoption en0 subnet_mask
255.255.255.0
```

`netmask 0xffffff00` is hexadecimal, and it is the same 32 bits again. Each pair
of hex digits is one octet, so `ff` is 255 three times and `00` is zero, giving
255.255.255.0 and a /24. Asking for the same fact through `ipconfig getoption`
returns dotted decimal, which is the quicker route when you do not want to
convert anything in your head.

Three notations, one boundary. The exam uses prefix length and dotted decimal
and will not ask you for hex, but a Mac in front of you will show it whether you
asked or not.


## Prove it

This topic has both kinds of evidence, and they check each other.

**Work it out.** Given any address and mask, you should be able to produce four
numbers on paper: the network address, the first usable address, the last usable
address, and the broadcast address. The method is one subtraction and two counts.
Take `192.168.10.100/26`. The block size is 64, so the networks begin at 0, 64,
128 and 192. `.100` falls in the one starting at `.64`. The broadcast is one below
the next network, so `.127`. Usable is `.65` to `.126`. That is 62 addresses,
which matches the table.

**Run it.** Then hand the same address to a machine and let it check you:

```bash
# The kernel computes the broadcast from the mask. If it disagrees with your
# arithmetic, your arithmetic is wrong.
ip addr add 192.168.10.100/26 brd + dev eth0
ip addr show eth0 | grep "inet "

# The route it writes is the network address and prefix, which is the other
# number you worked out.
ip route

# And the question the whole topic answers, asked directly.
ip route get 192.168.10.126     # inside the block: delivered on the link
ip route get 192.168.10.130     # outside it: sent to a gateway, or unreachable
```

**`ip route get` is the one that ends an argument.** It asks the kernel to decide
for one specific destination and report what it would do, which is the same
comparison you just did by hand, run by the thing that will actually be doing it.

## What trips people up

### 1. Answering with the block size instead of the usable count

64 combinations is 62 machines. The question is almost always how many hosts, and
the subtraction is the point of the question.

### 2. Subtracting two from a /31

RFC 3021 exists precisely because the normal rule gives zero. A /31 on a
point-to-point link has two usable addresses. The exam is unlikely to ask, and a
real router configuration will show you one.

### 3. Thinking the next network starts at the next number

After `192.168.10.63` the next /26 is `192.168.10.64`, and its first usable
address is `.65`, because `.64` is that network's own network address. Off by one
here is the most common arithmetic slip there is.

### 4. Reading a mask octet that cannot exist

`255.255.255.100` is not a narrow subnet. It is not a mask. The bits in a mask
fill from the left with no gaps, which leaves eight legal values per octet.

### 5. Assuming the dots mean something

They separate octets for human reading. The boundary can fall anywhere in the 32
bits, including in the middle of an octet, which is exactly what a /26 does.

### 6. Doing it in binary every time

Converting a whole address to binary is slow and you will run out of clock. The
block size method is arithmetic in decimal, and binary is for understanding why it
works rather than for answering under time pressure.

## Work it through

You are given `172.16.20.0/22` and asked to confirm two things: that
`172.16.23.200` is inside it, and how many machines it holds.

Reason it out before reading on.

**Find which octet the boundary falls in.** A /22 is 22 bits. The first two octets
take 16, so 6 bits fall inside the third octet and the fourth octet is entirely
host. The boundary is in the third octet, which is where the interesting
arithmetic is.

Now get the block size for that octet. Six bits used in the third octet leaves 2
bits there, so the third octet counts in steps of 4. The /22 networks are
`172.16.0.0`, `172.16.4.0`, `172.16.8.0` and so on, and the one starting at
`172.16.20.0` runs up to `172.16.23.255`.

That answers the first question. `172.16.23.200` has a third octet of 23, which
is inside 20 to 23, so yes, it is in this network. Note you never converted
anything to binary.

For the second, the host part is 32 minus 22, so 10 bits. Two to the power of
10 is 1024 combinations, minus 2, so 1022 machines. The network address is
`172.16.20.0` and the broadcast is `172.16.23.255`.

There is a check worth doing here. The broadcast address should be one below the next
network. The next /22 starts at `172.16.24.0`, and one below that is
`172.16.23.255`. It agrees, so the arithmetic held.

**The habit worth taking:** find the octet the boundary falls in, get the step
size for that octet, and count. Everything else follows, and it works the same
way for every prefix length.

## Try it

Optional, and the first four need only paper.

1. For `10.20.30.0/28`, write down the network address, the first and last usable
   addresses, and the broadcast. Then check by finding the next /28 and
   subtracting one.
2. Work out how many /26 networks fit inside a single /24, and list where each
   one starts.
3. Decide whether `192.168.4.130` and `192.168.4.120` can reach each other
   directly if both use a /25. Then do it again for a /24 and note that the
   answer changes.
4. Write out the eight legal mask octet values from memory. If you can do that
   without hesitating, most subnetting questions get faster.
5. On any Linux machine, assign an address with `brd +` and confirm the broadcast
   the kernel computes matches the one you worked out. Then use `ip route get` on
   an address just inside your range and one just outside.

**Then go and do a hundred of them.** [subnetipv4.com](https://subnetipv4.com/)
generates unlimited problems with worked solutions, which is the one thing this
page cannot give you. The explanation above is what makes the method make sense;
speed comes from volume, and there is no way around that.

## Check yourself

<details class="qa">
<summary>How many usable addresses does a <code>/26</code> hold, and why is the obvious answer wrong twice?</summary>

Sixty-two.

A /26 leaves 6 host bits, and 2 to the power of 6 is 64. That is the first
correction: 64 is the number of combinations, not of machines.

The second is that two of those combinations cannot be given to anything. The
all-zeros one is the network address and the all-ones one is the broadcast, so 64
becomes 62.

</details>

<details class="qa">
<summary>Why can <code>192.168.10.1/26</code> not reach <code>192.168.10.65</code>, even on the same cable?</summary>

Because the /26 that contains `.1` ends at `.63`. The next /26 starts at `.64`, so
`.65` is on a different network.

The sending machine compares the destination against its own network, decides it
is not local, and looks for a router. With no router configured it fails
immediately with `Network is unreachable`, and its neighbour table holds no entry
for that address, because it never asked.

Sharing a cable is irrelevant. The mask decides who is a neighbour.

</details>

<details class="qa">
<summary>Which values can a mask octet hold, and why only those?</summary>

0, 128, 192, 224, 240, 248, 252, 254 and 255.

A mask is 32 bits that are all ones and then all zeros, with no mixing. Filling an
octet from the left one bit at a time produces exactly those nine values, so
anything else is not an unusual mask, it is not a mask.

</details>

<details class="qa">
<summary>Where does the network beginning <code>172.16.20.0/22</code> end, and how did you get there without binary?</summary>

At `172.16.23.255`.

A /22 uses 6 bits of the third octet, leaving 2 there, so the third octet steps in
4s: 0, 4, 8, and so on up to 20. The block starting at 20 covers third octets 20
through 23, and the fourth octet is entirely host, so it runs to `.255`.

The check is that the next /22 starts at `172.16.24.0`, and one below that is the
broadcast.

</details>

<details class="qa">
<summary>When does subtracting 2 give the wrong answer?</summary>

On a /31, where it would give zero.

RFC 3021 allows a /31 on a point-to-point link, where there are only two devices
and neither reserved address is needed. Both addresses are assigned, so a /31
gives two usable addresses rather than none, and routers use it between each
other to avoid wasting two addresses per link.

A /32 is the other edge: one address, no host bits, used for a loopback or to name
one destination in a routing table.

</details>

<details class="qa">
<summary>You need to check somebody else's subnetting without doing it yourself. What do you run?</summary>

Assign the address with `brd +` and let the kernel compute the broadcast, then
compare it with theirs. The route the kernel writes gives you the network address
and prefix at the same time.

For a specific pair of addresses, `ip route get <destination>` asks the kernel to
make the local-or-routed decision and report it, which is the same comparison done
by the thing that will actually be doing it.

</details>

## References

- [RFC 4632, Classless Inter-domain Routing (CIDR)](https://www.rfc-editor.org/rfc/rfc4632) - IETF. Accessed 2026-08-10.
- [RFC 950, Internet Standard Subnetting Procedure](https://www.rfc-editor.org/rfc/rfc950) - IETF. Accessed 2026-08-10.
- [RFC 919, Broadcasting Internet Datagrams](https://www.rfc-editor.org/rfc/rfc919) - IETF. Accessed 2026-08-10.
- [RFC 3021, Using 31-Bit Prefixes on IPv4 Point-to-Point Links](https://www.rfc-editor.org/rfc/rfc3021) - IETF. Accessed 2026-08-10.
- [RFC 1878, Variable Length Subnet Table For IPv4](https://www.rfc-editor.org/rfc/rfc1878) - IETF. Accessed 2026-08-10.
- [subnetipv4.com](https://subnetipv4.com/) - subnetipv4.com. Accessed 2026-08-10.

**Where the output came from.** Both terminal blocks were captured rather than
written, from two Linux network namespaces joined by a virtual Ethernet pair,
using the topology committed at `blog/scripts/topologies/two-hosts.sh`. The
broadcast address and the route in the first block are the kernel's own
arithmetic, not mine, which is why they are worth showing. The block under
**Prove it** is a command list to be typed and has no output. The bit patterns in
the diagram and the two tables are derived rather than captured, and the RFCs
behind the reserved addresses are cited above.

**If you also work on Linux.** The mask section of [Addresses, masks, and who counts as a neighbour](/learn/linux-plus/network-basics-addresses-and-routes) on the Linux+
track works the same arithmetic on a live system, with more attention to what
persists across a reboot and less to doing it on paper. This exam wants the paper
version, which is why it is the one taught here.
- [inet_aton(3)](https://man7.org/linux/man-pages/man3/inet_aton.3.html) - Linux man-pages project, on the address forms the parser accepts. Accessed 2026-08-10.
