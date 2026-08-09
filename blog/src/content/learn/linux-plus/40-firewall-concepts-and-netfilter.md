---
title: "A port is open and you did not open it"
description: "Every Linux firewall is the same kernel machinery underneath. The five points a packet passes through, why the first rule is nearly always about state, and the difference between a packet that bounces and one that vanishes."
track: "linux-plus"
level: "working"
order: 410
objectives:
  - "Name the five netfilter hooks and say which path a packet takes"
  - "Explain what stateful filtering tracks and why it makes rulesets short"
  - "Choose between drop and reject and defend the choice"
  - "Distinguish SNAT, DNAT, and masquerade by where they happen"
  - "Read an nftables ruleset and say what it does to a packet"
prerequisites: ["network-basics-addresses-and-routes", "common-network-services"]
tags: ["linux", "linux-plus", "firewall", "netfilter", "nftables", "nat"]
updated: 2026-08-08
draft: false
examObjectives:
  - exam: "xk0-006"
    domain: "3.0"
    objective: "3.2"
sources:
  - title: "nft(8)"
    url: "https://manpages.debian.org/trixie/nftables/nft.8.en.html"
    publisher: "Debian manpages"
    accessed: 2026-08-08
    tier: 1
  - title: "nftables wiki"
    url: "https://wiki.nftables.org/wiki-nftables/index.php/Main_Page"
    publisher: "Netfilter project"
    accessed: 2026-08-08
    tier: 1
  - title: "iptables(8)"
    url: "https://man7.org/linux/man-pages/man8/iptables.8.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-08
    tier: 1
  - title: "Connection tracking sysctl reference"
    url: "https://docs.kernel.org/networking/nf_conntrack-sysctl.html"
    publisher: "Linux kernel documentation"
    accessed: 2026-08-08
    tier: 1
  - title: "IP sysctl reference"
    url: "https://docs.kernel.org/networking/ip-sysctl.html"
    publisher: "Linux kernel documentation"
    accessed: 2026-08-08
    tier: 1
  - title: "ss(8)"
    url: "https://man7.org/linux/man-pages/man8/ss.8.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-08
    tier: 1
symptoms:
  - symptom: "Connection times out instead of being refused"
    anchor: "drop-or-reject"
  - symptom: "Firewall rule added but traffic still passes"
    anchor: "3-the-rule-is-in-a-chain-the-packet-never-visits"
  - symptom: "Traffic is not being forwarded between interfaces"
    anchor: "nat-and-the-other-half-nobody-remembers"
---

> **Before you read.** `ss -tlnp` on a server you inherited shows something
> listening on port 8080. Nobody knows what it is. You add a firewall rule to block
> it and the connection still succeeds.
>
> You add the rule again, more emphatically. It is definitely there. You can
> list it. The traffic still gets through.
>
> **Where exactly does a firewall rule get consulted, and what if the packet never
> goes past that point?**

A Linux firewall is not a program sitting in front of the machine. It is a set of
rules the **kernel** evaluates at five specific moments while it is handling a
packet, and a rule placed at a moment the packet never reaches does nothing at all.

Which is why the answer to "I added the rule and it did not work" is almost never
about the rule.

`firewalld`, `ufw`, `nftables`, and `iptables` are four different ways to write
those rules. They are covered in the next lesson. **This one is about what they all
write to**, because a rule you cannot place is a rule you cannot debug.

### Some words you will need

<dl class="terms">
<dt>netfilter</dt>
<dd>The framework inside the kernel that lets code inspect packets at fixed points. The thing every Linux firewall is built on.</dd>
<dt>hook</dt>
<dd>One of those fixed points. There are five.</dd>
<dt>chain</dt>
<dd>A list of rules attached to a hook, evaluated in order.</dd>
<dt>table</dt>
<dd>A container for chains, scoped to one protocol family.</dd>
<dt>stateful</dt>
<dd>Deciding about a packet using what the kernel knows about the conversation it belongs to, not just the packet's own headers.</dd>
<dt>conntrack</dt>
<dd>Connection tracking. The kernel's table of conversations in progress.</dd>
<dt>NAT</dt>
<dd>Network address translation. Rewriting an address or port as the packet passes.</dd>
<dt>policy</dt>
<dd>What a chain does with a packet that matched no rule. Usually <code>accept</code> or <code>drop</code>.</dd>
</dl>

## What breaks without this

**You write a rule in the wrong chain** and it never matches, because the traffic you
meant to catch is passing through the machine and you filtered traffic *to* the
machine.

**You lock yourself out.** Setting a default-drop policy over SSH, before adding the
rule that permits SSH, ends the session immediately and permanently on a machine
without console access. This happens to everybody once.

**Your ruleset is enormous and slow**, because you wrote it statelessly and had to
describe both directions of every conversation by hand.

**You cannot tell a blocked port from a dead service**, because you chose
`drop` and now everything looks identical from outside, including to you, when
you are the one debugging it at 3am.

## The five hooks

<figure class="learn-figure">
<svg viewBox="0 0 720 360" role="img" aria-labelledby="nf-title nf-desc" style="width:100%;height:auto;">
  <title id="nf-title">The five netfilter hooks and the two paths a packet can take</title>
  <desc id="nf-desc">A packet arriving on a network card first meets the prerouting hook, where destination NAT happens. The kernel then makes a routing decision. If the packet is addressed to this machine it goes down through the input hook to a local process; anything that process sends back goes out through the output hook. If the packet is addressed to somewhere else it goes across the forward hook instead, which only sees traffic passing through. Both paths converge on the postrouting hook, where source NAT and masquerading happen, before the packet leaves. Filtering rules attach to input, forward, and output. Address translation attaches to prerouting and postrouting.</desc>
  <g font-family="ui-monospace, monospace">
    <text x="8" y="58" font-size="11" fill="currentColor" fill-opacity="0.7">arrives</text>
    <text x="8" y="72" font-size="11" fill="currentColor" fill-opacity="0.7">on a NIC</text>
    <rect x="72" y="34" width="116" height="50" rx="5" fill="currentColor" fill-opacity="0.1" stroke="currentColor" stroke-opacity="0.35"/>
    <text x="130" y="55" text-anchor="middle" font-size="12" fill="currentColor">prerouting</text>
    <text x="130" y="72" text-anchor="middle" font-size="9.5" fill="currentColor" fill-opacity="0.62">nat: DNAT</text>
    <rect x="222" y="34" width="104" height="50" rx="5" fill="none" stroke="currentColor" stroke-opacity="0.4" stroke-dasharray="4 3"/>
    <text x="274" y="55" text-anchor="middle" font-size="12" fill="currentColor">routing</text>
    <text x="274" y="72" text-anchor="middle" font-size="9.5" fill="currentColor" fill-opacity="0.62">is this for me?</text>
    <rect x="386" y="34" width="116" height="50" rx="5" fill="currentColor" fill-opacity="0.07" stroke="currentColor" stroke-opacity="0.3"/>
    <text x="444" y="55" text-anchor="middle" font-size="12" fill="currentColor">forward</text>
    <text x="444" y="72" text-anchor="middle" font-size="9.5" fill="currentColor" fill-opacity="0.62">filter: passing through</text>
    <rect x="558" y="34" width="116" height="50" rx="5" fill="currentColor" fill-opacity="0.1" stroke="currentColor" stroke-opacity="0.35"/>
    <text x="616" y="55" text-anchor="middle" font-size="12" fill="currentColor">postrouting</text>
    <text x="616" y="72" text-anchor="middle" font-size="9.5" fill="currentColor" fill-opacity="0.62">nat: SNAT, masquerade</text>
    <rect x="222" y="166" width="104" height="50" rx="5" fill="currentColor" fill-opacity="0.07" stroke="currentColor" stroke-opacity="0.3"/>
    <text x="274" y="187" text-anchor="middle" font-size="12" fill="currentColor">input</text>
    <text x="274" y="204" text-anchor="middle" font-size="9.5" fill="currentColor" fill-opacity="0.62">filter: to this host</text>
    <rect x="558" y="166" width="116" height="50" rx="5" fill="currentColor" fill-opacity="0.07" stroke="currentColor" stroke-opacity="0.3"/>
    <text x="616" y="187" text-anchor="middle" font-size="12" fill="currentColor">output</text>
    <text x="616" y="204" text-anchor="middle" font-size="9.5" fill="currentColor" fill-opacity="0.62">filter: from this host</text>
    <rect x="330" y="284" width="230" height="52" rx="5" fill="currentColor" fill-opacity="0.12" stroke="currentColor" stroke-opacity="0.4"/>
    <text x="445" y="306" text-anchor="middle" font-size="12" fill="currentColor">a local process</text>
    <text x="445" y="323" text-anchor="middle" font-size="9.5" fill="currentColor" fill-opacity="0.65">sshd, nginx, your shell</text>
  </g>
  <g stroke="currentColor" stroke-opacity="0.45" fill="none" stroke-width="1.2">
    <path d="M56 59 L68 59 M62 55 L69 59 L62 63"/>
    <path d="M188 59 L218 59 M212 55 L219 59 L212 63"/>
    <path d="M326 59 L382 59 M376 55 L383 59 L376 63"/>
    <path d="M502 59 L554 59 M548 55 L555 59 L548 63"/>
    <path d="M674 59 L706 59 M700 55 L707 59 L700 63"/>
    <path d="M274 84 L274 162 M270 156 L274 163 L278 156"/>
    <path d="M274 216 L274 310 L326 310 M320 306 L327 310 L320 314"/>
    <path d="M560 310 L616 310 L616 220 M612 226 L616 219 L620 226"/>
    <path d="M616 166 L616 88 M612 94 L616 87 L620 94"/>
  </g>
  <g font-family="ui-monospace, monospace" font-size="9.5" fill="currentColor" fill-opacity="0.7">
    <text x="332" y="26">addressed elsewhere</text>
    <text x="284" y="128">addressed here</text>
    <text x="8" y="314">leaves</text>
    <text x="8" y="328">on a NIC</text>
    <text x="690" y="30">out</text>
  </g>
</svg>
<figcaption>One packet takes one of two paths, and never both. A rule in the wrong chain is a rule the packet never meets.</figcaption>
</figure>

**The routing decision in the middle is the whole diagram.** After `prerouting`, the
kernel looks at the destination address and asks one question: is this addressed to
me? The answer sends the packet down one branch or the other, and the branches never
meet again until `postrouting`.

| Hook | Sees | Used for |
| --- | --- | --- |
| `prerouting` | Everything arriving, before routing | DNAT, port forwarding |
| `input` | Traffic addressed to this machine | Filtering what may reach local services |
| `forward` | Traffic passing **through** to somewhere else | Filtering on a router or gateway |
| `output` | Traffic this machine generated | Filtering outbound, rarely used |
| `postrouting` | Everything leaving, after routing | SNAT, masquerade |

**This answers the opening question.** If that mystery service on 8080 is being
reached through this machine on the way to a container or another host, the packets
go through `forward` and never touch `input`. A perfect rule in the `input` chain
sits there matching nothing, forever. It is listed, it is syntactically correct, and
it is in the wrong place.

**Two rules of thumb that are right nearly always:**

- Filtering a service **on this machine**? `input`.
- Filtering traffic **crossing** this machine? `forward`.

<details class="deeper">
<summary>If you already administer Linux: priorities, and how several firewalls coexist on one hook</summary>

Nothing stops two chains attaching to the same hook, and on a modern machine
several do. Podman, Docker, libvirt, Kubernetes, and `firewalld` all install their
own rules, and they are not negotiating with each other.

**Priority decides the order.** Each base chain declares a numeric priority, and
lower numbers run first. The named constants exist so you do not have to remember
the numbers:

| Name | Value | Where it sits |
| --- | --- | --- |
| `raw` | -300 | Before connection tracking. Where `notrack` goes. |
| `mangle` | -150 | Packet header rewriting |
| `dstnat` | -100 | DNAT, on prerouting |
| `filter` | 0 | Ordinary filtering |
| `srcnat` | 100 | SNAT, on postrouting |

`type filter hook input priority filter` in a rule listing is `priority 0`, written
in words.

**The consequence people meet is that their rule is correct and something else
already accepted the packet.** A chain's verdict on a packet is final for that hook,
so a `drop` at priority 10 never runs if a container runtime's chain at priority -10
already accepted it. `nft list ruleset` shows every chain on the machine with its
priority, and reading them in priority order is how you work out who is winning.

**The other half of this is that `iptables` and `nft` are the same kernel
subsystem on any current distribution.** `iptables` is a compatibility front
end that translates to nftables underneath: `iptables-nft`. So rules added
with `iptables` show up in `nft list ruleset`, in tables with names like
`filter` and `mangle`. They are not two firewalls fighting; they are two
syntaxes over one engine. Mixing them in a single ruleset still confuses
people badly, and the reason is ordering rather than incompatibility.

The one genuine trap: `iptables-legacy` exists on some machines and *is* a separate
engine, evaluated separately. `iptables --version` tells you which you have, and
`nf_tables` in the output is the one you want.

</details>

## Stateless, and why nobody does that

The simplest possible rule looks at one packet in isolation: source, destination,
protocol, port. That is stateless filtering, and it falls apart immediately.

Consider allowing your machine to browse the web. Outbound to port 443 is
easy. But the reply arrives **inbound**, from a random server, to a random
high-numbered port on your machine. To allow it statelessly you must permit
inbound traffic to every port above 1024 from anywhere, which is most of what
you were trying to prevent.

Stateful filtering solves this by remembering. The kernel keeps a table of
conversations, and a packet can be matched on which conversation it belongs to:

| State | Means |
| --- | --- |
| `new` | First packet of a conversation |
| `established` | Belongs to a conversation already seen |
| `related` | A new conversation the kernel knows is spawned by an existing one |
| `invalid` | Does not fit anything. Usually dropped. |

**So one rule replaces hundreds:** allow anything `established` or `related`,
and every reply to everything you sent is covered, permanently, without naming
a single port. `related` is the subtle one, an ICMP "fragmentation needed"
message about a connection you have open is a *different* conversation that
the kernel understands is about that one.

Here is a small stateful ruleset being built from nothing:

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ sudo nft add table inet filter; sudo nft add chain inet filter input "{ type filter hook input priority filter; policy accept; }"; sudo nft add rule inet filter input ct state established,related accept; sudo nft add rule inet filter input iif lo accept; sudo nft add rule inet filter input tcp dport 22 accept; sudo nft list ruleset
table inet filter {
	chain input {
		type filter hook input priority filter; policy accept;
		ct state established,related accept
		iif "lo" accept
		tcp dport 22 accept
	}
}
```

**Read the order, because it is the conventional one and every reason is practical.**

`ct state established,related accept` is first because it matches the overwhelming
majority of packets, and a rule that matches most traffic belongs at the top where
it ends evaluation early.

`iif lo accept` is second because loopback traffic is between processes on this
machine, and filtering it breaks software in confusing ways. Almost every real
ruleset has this line.

`tcp dport 22 accept` is third, and this is the one that saves you: **the rule
permitting your own SSH session goes in before the policy is tightened**, not after.

Note that `policy accept` is still in place. Everything so far has added
permissions to a chain that already allows everything, which is why nothing has
broken. Changing the policy to `drop` is the moment the ruleset starts doing work,
and it is the moment to have already tested the SSH rule.

<details class="deeper">
<summary>If you already administer Linux: what connection tracking costs, and what happens when the table fills</summary>

Stateful filtering is not free. Every tracked conversation is an entry in a kernel
hash table, and that table has a size.

The entries are real and readable. This is the machine these captures came from,
tracking its own SSH sessions:

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ sudo cat /proc/sys/net/netfilter/nf_conntrack_count; echo "--- the flows themselves ---"; sudo head -2 /proc/net/nf_conntrack
3
--- the flows themselves ---
ipv4     2 tcp      6 119 TIME_WAIT src=192.168.127.1 dst=192.168.127.2 sport=40189 dport=22 src=192.168.127.2 dst=192.168.127.1 sport=22 dport=40189 [ASSURED] mark=0 secctx=system_u:object_r:unlabeled_t:s0 zone=0 use=2
ipv4     2 tcp      6 431999 ESTABLISHED src=192.168.127.1 dst=192.168.127.2 sport=50452 dport=22 src=192.168.127.2 dst=192.168.127.1 sport=22 dport=50452 [ASSURED] mark=0 secctx=system_u:object_r:unlabeled_t:s0 zone=0 use=2
```

Each line has both directions of the flow and a countdown. `431999` on the
established SSH session is seconds, five days, the default
`nf_conntrack_tcp_timeout_established`. `119` on the `TIME_WAIT` entry is what
is left of a two-minute timer.

**Those timeouts are the thing that bites at scale.** Five days per idle TCP
conversation, against a table sized at 65536 entries by default on this
machine, means a busy proxy or NAT gateway can exhaust it. When it fills, new
connections are dropped and the kernel logs `nf_conntrack: table full,
dropping packet`, which reads like a network fault and is a capacity problem.

The two knobs, both in `/etc/sysctl.d/`:

```
net.netfilter.nf_conntrack_max = 262144
net.netfilter.nf_conntrack_tcp_timeout_established = 86400
```

Raising `max` costs memory, roughly 300 bytes per entry. Lowering the established
timeout to a day is usually safer than it sounds, because anything that genuinely
idles longer than that should be using TCP keepalives.

**The escape hatch worth knowing** is that tracking can be turned off per flow. A
rule in the `raw` table with a `notrack` verdict skips connection tracking entirely
for matching packets, which is how high-volume DNS or load-balancer nodes stay
inside the table. The cost is that those flows can no longer be matched on state, so
everything about them must be filtered statelessly.

And the diagnostic: the table only fills up if something is *using* it. Note in the
main section that `nf_conntrack_count` was `0` before any `ct state` rule existed on
this machine. The kernel does not track connections for the sake of it; the first
rule that asks about state is what switches tracking on.

</details>

## Drop or reject

Two ways to refuse a packet, and they are visibly different from the other end. The
same rule, twice, on the same machine.

First, `reject`:

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ sudo nft add chain inet filter output "{ type filter hook output priority filter; policy accept; }"; sudo nft add rule inet filter output ip daddr 1.1.1.1 counter reject; ping -c 1 -W 2 1.1.1.1; echo "rc=$?"
PING 1.1.1.1 (1.1.1.1) 56(84) bytes of data.
From 192.168.127.2 icmp_seq=1 Destination Port Unreachable
ping: sendmsg: Operation not permitted

--- 1.1.1.1 ping statistics ---
1 packets transmitted, 0 received, +1 errors, 100% packet loss, time 0ms

rc=1
```

Now `drop`, and watch the clock:

<details class="predict">
<summary>`reject` sends an ICMP error back, so the sender learns immediately. `drop` sends nothing at all. What does the sender do, and how long does it take?</summary>

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ sudo nft flush chain inet filter output; sudo nft add rule inet filter output ip daddr 1.1.1.1 counter drop; time ping -c 1 -W 3 1.1.1.1; echo "rc=$?"
PING 1.1.1.1 (1.1.1.1) 56(84) bytes of data.

--- 1.1.1.1 ping statistics ---
1 packets transmitted, 0 received, 100% packet loss, time 0ms


rc=1
real	0m3.001s
user	0m0.001s
sys	0m0.000s
```

</details>

**`real 0m3.001s`, and the `-W 3` timeout is exactly where that number came from.**
The sender had no information, so it waited for the full timeout and then gave up.
`reject` returned in a few milliseconds with a reason.

| | `reject` | `drop` |
| --- | --- | --- |
| Sends back | ICMP error, or TCP RST | Nothing |
| Client sees | Immediate "connection refused" | A hang, then a timeout |
| Reveals | That a machine is here, filtering | Nothing |
| Costs you | One packet per refusal | Every client's patience |

**Neither is the right answer everywhere.**

Use `reject` **inward-facing**, on internal networks, and for services your
own applications call. A misconfigured client that fails in 3 milliseconds is
a five-minute diagnosis; the same client failing in 30 seconds is a support
ticket about "the network being slow", and the connection to the firewall is
never made.

Use `drop` **on internet-facing edges**, where the audience is scanners rather than
colleagues. A dropped packet costs the scanner its full timeout for every port, which
makes scanning you expensive, and it does not confirm anything is there.

The exam wants the distinction, and the reasoning above is what makes it stick:
**`drop` costs the client time, `reject` costs you information.**

<details class="deeper">
<summary>If you already administer Linux: which ICMP a reject sends, and the case where drop is actively harmful</summary>

`reject` has a `with` clause, and the default is not always what you want:

```
tcp dport 25 reject with tcp reset
ip protocol udp reject with icmpx port-unreachable
ip daddr 10.0.0.0/8 reject with icmp host-unreachable
```

**`reject with tcp reset` on TCP is the polite one.** An RST is what a machine with
nothing listening sends anyway, so the client's stack handles it natively and
instantly, and it is indistinguishable from a closed port. `icmp port-unreachable`
on a TCP connection works but some clients handle it less gracefully than an RST.

**The case where `drop` does real damage is Path MTU Discovery.** A host sends a
large packet with "do not fragment" set; a router in the middle cannot forward it and
replies with ICMP type 3 code 4, "fragmentation needed". If you have blanket-dropped
ICMP at your edge because "ICMP is a security risk", that message never arrives. The
sender keeps retransmitting a packet that can never get through, and you get the
classic symptom: the connection opens, small requests work, and any response over
about 1500 bytes hangs forever.

This is why blanket `ip protocol icmp drop` is a bad rule and why sensible rulesets
are selective:

```
icmp type { echo-request, destination-unreachable, time-exceeded } accept
```

Blocking `echo-request` and nothing else is defensible. Blocking
`destination-unreachable` breaks PMTU discovery, and blocking `time-exceeded`
breaks `traceroute`, including yours, when you are trying to work out why the
connection hangs.

**On IPv6 it is not a matter of taste.** ICMPv6 carries Neighbour Discovery, which
is what ARP does on IPv4. Drop ICMPv6 wholesale and the machine cannot resolve its
neighbours; the network simply stops. Any IPv6 ruleset must permit it.

</details>

## Reading a ruleset

nftables organises rules in a fixed hierarchy, and each level exists for a reason:

```
table   inet filter        family and a name you chose
 chain  input              attached to a hook, with a priority and a policy
  rule  tcp dport 22 accept    matches, then a verdict
```

**The family on the table decides which protocols it can see:**

| Family | Handles |
| --- | --- |
| `inet` | IPv4 and IPv6 in one table. **Use this.** |
| `ip` | IPv4 only |
| `ip6` | IPv6 only |
| `arp`, `bridge`, `netdev` | Specialised. Rare. |

`inet` is the single biggest improvement nftables made over `iptables`, where
every rule had to be written twice (once with `iptables`, once with
`ip6tables`) and the IPv6 half was the one that got forgotten.

Rules get a **handle**, which is how you delete one without rewriting the chain.
The chain below has handles 2, 3 and 4, and handle 3 is about to be deleted.

<details class="predict">
<summary>After deleting handle 3, what number does the last rule carry? Think about whether a handle is a position in the list or a name for a rule.</summary>

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ sudo nft -a list chain inet filter input; echo "--- delete rule 3 by handle ---"; sudo nft delete rule inet filter input handle 3; sudo nft -a list chain inet filter input
table inet filter {
	chain input { # handle 1
		type filter hook input priority filter; policy accept;
		ct state established,related accept # handle 2
		iif "lo" accept # handle 3
		tcp dport 22 accept # handle 4
	}
}
--- delete rule 3 by handle ---
table inet filter {
	chain input { # handle 1
		type filter hook input priority filter; policy accept;
		ct state established,related accept # handle 2
		tcp dport 22 accept # handle 4
	}
}
```

</details>

**`-a` is the flag that shows handles**, and without it you cannot delete a single
rule at all. Note that the remaining handles did not renumber: `tcp dport 22` is
still handle 4. Handles are stable identifiers, not positions, which is what makes
them safe to script against.

The `counter` keyword is the other thing to reach for when a rule is not behaving:

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ sudo nft list chain inet filter output
table inet filter {
	chain output {
		type filter hook output priority filter; policy accept;
		ip daddr 1.1.1.1 counter packets 1 bytes 84 reject with icmp port-unreachable
	}
}
```

**`packets 1 bytes 84`.** That rule matched exactly one packet of 84 bytes,
the `ping` from earlier. A counter that stays at zero while traffic is
definitely flowing is the proof that a rule is in the wrong chain, and it is a
far better diagnostic than reasoning about it.

## NAT, and the other half nobody remembers

Address translation is a separate job from filtering, and it happens at the two hooks
where the packet is nearest the wire.

| Kind | Rewrites | Hook | Used for |
| --- | --- | --- | --- |
| **SNAT** | Source address | `postrouting` | Many private hosts behind one public address |
| **DNAT** | Destination address | `prerouting` | Publishing an internal service outward |
| **Masquerade** | Source, to whatever the outbound interface has | `postrouting` | SNAT when the address is not known in advance |

**Masquerade is SNAT for dynamic addresses.** SNAT names the replacement
address explicitly, which is faster because the kernel does not have to look
anything up. Masquerade asks the outbound interface what its address currently
is, every time, which is what you need on a link with a DHCP or PPP address,
and is why it is the default on home routers and cloud NAT gateways.

The hooks are not interchangeable, and the reason is the routing decision in the
diagram. DNAT must happen in `prerouting`, **before** routing, because it changes
the destination and therefore changes where the packet gets routed. SNAT must happen
in `postrouting`, **after** routing, because rewriting the source earlier would have
changed which route was chosen.

nftables checks your work as you type, which is a small kindness:

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ sudo nft add table ip nat; sudo nft add chain ip nat postrouting "{ type nat hook postrouting priority srcnat; policy accept; }"; sudo nft add rule ip nat postrouting oif "eth0" masquerade; sudo nft list table ip nat
Error: Interface does not exist
add rule ip nat postrouting oif eth0 masquerade
                                ^^^^
table ip nat {
	chain postrouting {
		type nat hook postrouting priority srcnat; policy accept;
	}
}
```

The interface on this machine is not called `eth0`, and the rule was refused with the
offending token underlined. **The chain was still created**, which is the part to
notice: nftables commands are not transactional across a shell one-liner, so a
failure halfway through leaves you in a partial state.

With the right name, the rule takes. And then the second command asks the machine
a question that has nothing to do with the firewall.

<details class="predict">
<summary>The masquerade rule is now correct and loaded. What does `sysctl net.ipv4.ip_forward` report on a machine that has never been configured as a router, and what does that mean for the rule you just wrote?</summary>

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ sudo nft add rule ip nat postrouting oif "enp0s1" masquerade; sudo nft list table ip nat; echo "--- forwarding is the other half ---"; sysctl net.ipv4.ip_forward
table ip nat {
	chain postrouting {
		type nat hook postrouting priority srcnat; policy accept;
		oif "enp0s1" masquerade
	}
}
--- forwarding is the other half ---
net.ipv4.ip_forward = 0
```

</details>

**`net.ipv4.ip_forward = 0` is the line that ruins afternoons.** The NAT rule is
perfect and the machine will not route a single packet, because a Linux host does not
forward traffic between interfaces unless it is told to. Nothing warns you; packets
addressed elsewhere are simply dropped before they reach the `forward` hook.

```
# now
sudo sysctl -w net.ipv4.ip_forward=1

# and after a reboot
echo 'net.ipv4.ip_forward = 1' | sudo tee /etc/sysctl.d/99-router.conf
sudo sysctl --system
```

Both, always. `sysctl -w` is the runtime change and the file is the persistent one,
which is the same two-part shape as `setsebool -P` and `systemctl enable`.

<details class="deeper">
<summary>If you already administer Linux: why NAT is not a firewall, and the flow a forwarded packet actually takes</summary>

A machine doing NAT is often described as protecting the hosts behind it. It does,
incidentally, and the protection is a side effect that disappears the moment
anything changes.

**The protection is only that inbound packets have nowhere to go.** With no DNAT rule
and no existing conntrack entry, an unsolicited packet arriving at the public address
matches nothing and is dropped for lack of a destination. That is not a policy
decision; it is an absence of one. Add a single port-forward and every host behind it
is reachable on that port with no filtering applied, because `forward` is a
different chain from the `nat` table and nobody wrote any rules in it.

**IPv6 makes the assumption visible.** With globally routable addresses there is no
NAT, so a network whose security was NAT has none. This is the most common IPv6
deployment mistake there is, and it is entirely a consequence of a side effect having
been mistaken for a control.

The full path of a forwarded packet, in order, is worth having:

1. `prerouting` in the `raw` table, priority -300, where `notrack` can skip tracking
2. connection tracking looks the packet up, or creates an entry
3. `prerouting` in `nat`, priority -100, **DNAT happens here**
4. **the routing decision**, using the destination as it now stands after DNAT
5. `forward` in `filter`, priority 0, **the only chance to filter this packet**
6. `postrouting` in `nat`, priority 100, **SNAT and masquerade happen here**
7. out

**Step 5 is the one people leave empty.** A NAT gateway with rules in `input` and
nothing in `forward` filters traffic to itself and passes everything through it, which
is exactly backwards for a router. It is also the opening question of this lesson,
and the reason it is worth being able to draw this list from memory.

One more consequence of the order: because DNAT happens at step 3 and
filtering at step 5, a `forward` rule sees the **post-DNAT** destination, the
internal address, not the public one. Writing `ip daddr 203.0.113.10 accept`
in `forward` to permit traffic to a published service matches nothing at all.
The rule has to name the internal address, which surprises everybody once.

</details>

## Across distributions

The kernel machinery is identical everywhere. What differs is which front end is
installed and running.

| | RHEL family | Debian family | Ubuntu |
| --- | --- | --- | --- |
| Default front end | `firewalld` | none | `ufw`, installed and inactive |
| Underlying engine | nftables | nftables | nftables |
| `iptables` present | As a compatibility shim | As a compatibility shim | As a compatibility shim |
| Service unit | `firewalld.service` | `nftables.service` | `ufw.service` |
| Rules survive reboot | Yes, permanent config | Only if you save them | Yes |

**That last row is the one that catches people.** Rules added with bare `nft` live in
the kernel and nowhere else. Reboot and they are gone. Every front end exists partly
to solve that, which is the next lesson.

## Prove it

```
# What is actually loaded, everything, every table
sudo nft list ruleset

# With handles, which you need to delete anything
sudo nft -a list ruleset

# Is a rule matching at all? Add "counter" and watch
sudo nft list chain inet filter input

# What is even listening, before you filter it
sudo ss -tlnp

# Is this machine willing to route at all
sysctl net.ipv4.ip_forward

# And from the other end, which tells drop from reject
curl -v --max-time 5 http://host:8080/
```

**`nft list ruleset` first, always.** It shows every table from every source
(`firewalld`, the container runtime, whatever `iptables` wrote) and the
surprise is usually in a chain you did not know existed.

## What trips people up

### 1. Locking yourself out

Setting `policy drop` on `input` before adding a rule for SSH ends the session
instantly, and you are not getting back in.

Add the permit rule **first**, confirm it with a second SSH session, and only then
change the policy. On a machine you cannot reach physically, schedule an undo before
you start:

```
sudo sh -c 'sleep 300; nft flush ruleset' &
```

If you lock yourself out, it clears in five minutes. If everything works, kill the
job. This is cheap insurance and almost nobody does it until the first time they need
it.

### 2. Rules that do not survive a reboot

`nft add rule` changes the running kernel. That is all it does.

Persisting them is the front end's job, or `nft list ruleset > /etc/nftables.conf`
plus an enabled `nftables.service`.

### 3. The rule is in a chain the packet never visits

Traffic *through* the machine goes through `forward`, not `input`. This is the
opening question, and it is the single most common wasted hour.

Add `counter` to the rule and look at it. A counter stuck at zero has told you the
packet is not passing through that chain.

### 4. Blocking ICMP wholesale

It breaks Path MTU Discovery, which produces the maddening symptom of small requests
working and large ones hanging. On IPv6 it breaks address resolution outright and the
network stops.

Block `echo-request` if you must. Permit `destination-unreachable` and
`time-exceeded`.

### 5. NAT with no forwarding

`net.ipv4.ip_forward = 0` means no packet is routed between interfaces regardless of
how correct the NAT rule is. There is no error message; the packets simply do not
appear.

### 6. Expecting `forward` rules to see the public address

DNAT happens before routing, filtering after. A `forward` rule sees the internal
destination address, because the translation already happened.

## Work it through

A machine acts as a gateway for a small subnet. Hosts behind it can reach each other
but not the internet. You have configured masquerade correctly and confirmed it with
`nft list ruleset`.

Reason it out before reading on.

**Check the thing that has no error message first:**

```
sysctl net.ipv4.ip_forward
```

**`0`** and you have the answer in one command. The NAT rule is fine and is never
consulted, because packets addressed elsewhere are discarded before the `forward`
hook. Set it, persist it in `/etc/sysctl.d/`, and it works.

**`1`**, and the packets are being forwarded, so the question becomes where they die.
Work along the path:

```
sudo nft list ruleset
```

**Is there a `forward` chain with `policy drop` and no rules?** That is a firewall
doing exactly what it was told. It needs `ct state established,related accept` plus a
rule permitting new outbound conversations from the internal subnet.

**Is there no `forward` chain at all?** Then filtering is not the problem, and the
next suspect is routing: do the internal hosts have this machine as their default
gateway, and does this machine have a route out?

**And the case that looks like a firewall and is not.** Traffic leaves, gets
NATed correctly, reaches the internet, and the replies come back to the
gateway, but the upstream router does not know the internal subnet exists, so
if masquerade were *missing*, the replies would be addressed to a private
address and dropped somewhere upstream. Symptom: outbound packets counted,
nothing ever returns. `tcpdump` on the external interface separates "we never
sent it" from "we sent it and nothing came back", and those have completely
different causes.

Now the point worth extracting. **A firewall problem is a question about position,
not about syntax.** Which hook does this packet pass through, is there a chain on
that hook, and did a rule in it match? A `counter` on the rule answers the third
question directly, and `nft list ruleset` answers the first two. Reasoning about
whether the rule *looks* right is the slowest available method and the one everybody
tries first.

## Try it

Optional, and on a machine you can reach another way.

1. `sudo nft list ruleset`. On a stock machine with containers it will not be empty.
2. `sudo ss -tlnp`, and account for every listener.
3. Add a table and an `input` chain with `policy accept`, and add
   `ct state established,related accept`. Nothing should change.
4. `sudo cat /proc/sys/net/netfilter/nf_conntrack_count` before and after adding
   that rule.
5. Block one address outbound with `counter reject`, `ping` it, then read the
   counter.
6. Change `reject` to `drop` and time the same `ping`.
7. `sudo nft -a list ruleset`, then delete one rule by handle.
8. `sudo nft flush ruleset` when you are done, and confirm it is empty.

**Verification step.** You have it when you can predict, before running it,
whether a given rule will match a given packet, and name which hook that
packet passes through on the way.

## Check yourself

<details class="qa">
<summary>A rule blocking port 8080 is present and correct, and traffic to port 8080 still reaches its destination. What is the most likely cause, and what one addition to the rule would confirm it?</summary>

**The rule is in `input` and the traffic is being forwarded**, so it passes through
the `forward` hook and never touches `input` at all.

The routing decision happens after `prerouting` and sends a packet down exactly one
of two paths: `input` if it is addressed to this machine, `forward` if it is
addressed to something beyond it. A rule on the path the packet does not take is
inert no matter how correct it is.

**Add `counter` to the rule** and list the chain. A counter reading
`packets 0 bytes 0` while traffic is definitely flowing proves the packets are not
passing through that chain, which turns an argument about rule syntax into a fact.

The tempting wrong answer is that another rule above it accepted the packet
first, and that is worth ruling out, but it produces a *non-zero* counter on
the earlier rule, so the counters distinguish the two cases immediately.

The other possibility on a busy machine is a chain at a lower priority, installed by
a container runtime, that accepted the packet before your chain ran.
`nft list ruleset` shows every chain with its priority.

</details>

<details class="qa">
<summary>What does `ct state established,related accept` do, and why is it conventionally the first rule in the chain?</summary>

**It accepts any packet belonging to a conversation the kernel is already tracking**,
plus new conversations the kernel knows are spawned by an existing one.

Without it you would have to describe the return direction of every
conversation by hand: replies from web servers arrive from arbitrary addresses
to arbitrary high ports, so permitting them statelessly means permitting
almost everything inbound, which defeats the purpose.

**First for two independent reasons.**

*Performance*: it matches the overwhelming majority of packets in any real traffic
mix, and a chain stops evaluating at the first match, so putting it first means most
packets are decided by one comparison instead of walking the whole chain.

*Correctness*: it is unconditional. Rules below it can be as specific as you like
without risk of accidentally breaking established sessions, including the SSH session
you are typing into.

`related` is the part worth understanding: an ICMP "fragmentation needed"
message about a connection you have open is technically a *different*
conversation, and without `related` it is dropped, which breaks Path MTU
Discovery in exactly the way that produces hanging large transfers.

</details>

<details class="qa">
<summary>You block a port with `drop` on an internal application server. A colleague reports the application is "slow". What did you do, and what should you have done?</summary>

**`drop` sends nothing back**, so the client's connection attempt has no information
to act on and waits for its full timeout before failing. To a user that is
indistinguishable from a slow application, which is why the report arrives as
"slow" rather than "refused" and why nobody connects it to the firewall change.

**`reject` on internal networks.** It returns an ICMP error or a TCP RST, the
client fails in milliseconds, and the error says "connection refused", which
names the cause and gets the ticket to the right person immediately.

The general rule: **`drop` costs the client time, `reject` costs you information.**
On an internet-facing edge, costing scanners time is the point and revealing nothing
is worth having. On an internal network your clients are your colleagues, and
withholding information from them buys nothing.

For TCP specifically, `reject with tcp reset` is better than the default ICMP
port-unreachable, because an RST is exactly what a machine with nothing listening
sends anyway, and every client stack handles it natively.

</details>

<details class="qa">
<summary>Why must DNAT happen at `prerouting` and SNAT at `postrouting`, rather than both in the same place?</summary>

**Because the routing decision sits between them, and each one has to be on the
correct side of it.**

DNAT changes the destination address, and the destination is what the routing
decision uses. Translating after routing would mean the kernel routed the
packet to where it was originally addressed, then changed where it was going,
so it would be sent out of the wrong interface, or delivered locally when it
should have been forwarded. It has to happen first.

SNAT changes the source address, which does not affect where the packet goes
but does affect where the reply comes back to. Translating before routing
could change which route is selected on a machine with source-based routing
rules, and the address to translate *to* frequently depends on the outbound
interface, which is not known until after routing. So it has to happen last.

**The consequence people meet in practice** is that a `forward` rule sees the
*post-DNAT* destination. Filtering happens at step 5, DNAT at step 3, so a rule
naming the public address of a published service matches nothing. It has to name the
internal address.

</details>

<details class="qa">
<summary>A NAT gateway is configured and no traffic passes. `nft list ruleset` shows the masquerade rule is present and correct. What do you check, and why is there no error message?</summary>

**`sysctl net.ipv4.ip_forward`**, and it is almost certainly `0`.

A Linux host is not a router by default. With forwarding disabled, a packet
whose destination is not one of this machine's addresses is discarded during
the routing decision, **before** it reaches the `forward` hook, and therefore
before any rule or NAT chain is consulted.

There is no error because nothing failed. The kernel was asked to handle a packet
addressed to somewhere else, has not been told it is allowed to do that, and dropped
it. Firewall rules never ran, so nothing logged anything.

The fix is two commands, and only doing one is its own classic mistake:

```
sudo sysctl -w net.ipv4.ip_forward=1
echo 'net.ipv4.ip_forward = 1' | sudo tee /etc/sysctl.d/99-router.conf
```

The first takes effect now; the second survives a reboot. Same shape as
`setsebool -P` and `systemctl enable`, a runtime change and a persistent
change are separate operations.

For IPv6 the knob is `net.ipv6.conf.all.forwarding`, and it is separate. Setting only
the IPv4 one on a dual-stack gateway produces a network where half the traffic works.

</details>

## References

- [nft(8)](https://manpages.debian.org/trixie/nftables/nft.8.en.html) - Debian manpages. Accessed 2026-08-08.
- [nftables wiki](https://wiki.nftables.org/wiki-nftables/index.php/Main_Page) - Netfilter project. Accessed 2026-08-08.
- [iptables(8)](https://man7.org/linux/man-pages/man8/iptables.8.html) - Linux man-pages project. Accessed 2026-08-08.
- [Connection tracking sysctl reference](https://docs.kernel.org/networking/nf_conntrack-sysctl.html) - Linux kernel documentation. Accessed 2026-08-08.
- [IP sysctl reference](https://docs.kernel.org/networking/ip-sysctl.html) - Linux kernel documentation. Accessed 2026-08-08.
- [ss(8)](https://man7.org/linux/man-pages/man8/ss.8.html) - Linux man-pages project. Accessed 2026-08-08.

Captured output came from a Fedora CoreOS virtual machine with a real kernel and a
real network, so the rules were genuinely loaded and the packets genuinely refused.
The ruleset was flushed afterwards. Blocks without a distribution and architecture
header are illustrative.
