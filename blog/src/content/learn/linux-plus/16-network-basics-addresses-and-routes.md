---
title: "Network basics: addresses and routes"
description: "Two machines on the same desk cannot reach each other and both are configured. The four separate things every host needs, what a subnet mask actually decides, and why the answer is usually the third one."
deck: "Who counts as a neighbour"
track: "linux-plus"
level: "intro"
order: 170
objectives:
  - "Name the four things a host needs to reach the internet and say what each does"
  - "Read an address in CIDR notation and say which addresses are local"
  - "Read a routing table and predict which route a packet takes"
  - "Tell a port from an address, and TCP from UDP"
prerequisites: ["raid"]
tags: ["linux", "linux-plus", "networking", "beginner"]
updated: 2026-08-07
draft: false
examObjectives:
  - exam: "xk0-006"
    domain: "1.0"
    objective: "1.4"
sources:
  - title: "ip(8)"
    url: "https://man7.org/linux/man-pages/man8/ip.8.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "ip-address(8)"
    url: "https://man7.org/linux/man-pages/man8/ip-address.8.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "ip-route(8)"
    url: "https://man7.org/linux/man-pages/man8/ip-route.8.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "ss(8)"
    url: "https://man7.org/linux/man-pages/man8/ss.8.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "ping(8)"
    url: "https://man7.org/linux/man-pages/man8/ping.8.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "tcp(7)"
    url: "https://man7.org/linux/man-pages/man7/tcp.7.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
symptoms:
  - symptom: "Two machines on the same network cannot reach each other"
    anchor: "2-the-mask-is-wrong-and-everything-looks-fine"
  - symptom: "Network unreachable"
    anchor: "1-network-is-unreachable"
---

> **Before you read.** Two machines sit on the same desk, plugged into the same
> switch. One is `192.168.1.10`, the other is `192.168.2.20`. Both are on, both
> have working cables, both report the network as up.
>
> They cannot reach each other at all.
>
> Nothing is broken. **What is stopping them?**

The answer is one number that neither machine displays prominently and that
almost every beginner reads past. Once you know what it does, a large fraction of
network problems become obvious rather than mysterious.

This lesson is the foundation for the two after it. Configuration and name
resolution both assume you know what an address, a mask, and a route are, and
those three do more work than everything else combined.

### Some words you will need

<dl class="terms">
<dt>IP address</dt>
<dd>A number identifying one machine on a network. Like a street address, and just as useless without knowing which town it is in.</dd>
<dt>subnet mask</dt>
<dd>Which part of the address is the network and which part is the machine. This is the number in the puzzle above.</dd>
<dt>gateway</dt>
<dd>The machine that forwards traffic to networks you cannot reach directly. Usually your router.</dd>
<dt>route</dt>
<dd>A rule saying how to reach a given network. The routing table is the list of them.</dd>
<dt>port</dt>
<dd>A number identifying which program on a machine a connection is for. The address gets you to the building; the port is the flat number.</dd>
<dt>interface</dt>
<dd>A network connection on the machine. Physical card, virtual, or the loopback.</dd>
</dl>

## What breaks without this

**"The network is down" with no idea which part.** Cable, address, mask,
gateway, DNS, firewall, remote service, seven candidates, one symptom, and no
order to check them in.

**You change the wrong thing.** Adding a gateway when the mask is wrong, or
restarting a service when the route is missing. Both feel like progress and
neither helps.

**You cannot read what you are looking at.** `192.168.1.10/24` packs three
separate facts into eleven characters, and every diagnostic command assumes you
can unpack them.

## The four things every host needs

| Thing | Example | Answers |
| --- | --- | --- |
| **Address** | `192.168.1.10` | Who am I? |
| **Mask** | `/24` | Which machines can I reach directly? |
| **Gateway** | `192.168.1.1` | Where do I send everything else? |
| **DNS** | `192.168.1.1` | How do I turn a name into an address? |

**These are four independent settings and they fail independently.** That is the
single most useful thing in this lesson, because it turns "the network is broken"
into four questions with four different answers:

- Wrong **address**: nothing works, and you may have taken someone else's address
  with you.
- Wrong **mask**: some things work and some do not, in a pattern that looks
  random until you see it.
- Wrong **gateway**: the local network is perfect and the internet is unreachable.
- Wrong **DNS**: `ping 8.8.8.8` works and `ping google.com` does not.

That last pair is worth memorising as a test on its own. It splits the problem in
half in one command.

## Reading an address

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ ip addr show; echo "--- routes ---"; ip route
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host noprefixroute 
       valid_lft forever preferred_lft forever
2: enp0s1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 5a:94:ef:e4:0c:ee brd ff:ff:ff:ff:ff:ff
    altname enx5a94efe40cee
    inet 192.168.127.2/24 brd 192.168.127.255 scope global dynamic noprefixroute enp0s1
       valid_lft 1803sec preferred_lft 1803sec
    inet6 fe80::97bb:e9e5:6ee3:27a3/64 scope link noprefixroute 
       valid_lft forever preferred_lft forever
--- routes ---
default via 192.168.127.1 dev enp0s1 proto dhcp src 192.168.127.2 metric 100 
192.168.127.0/24 dev enp0s1 proto kernel scope link src 192.168.127.2 metric 100 
```

Dense, so take it piece by piece.

**Two interfaces.** `lo` is the loopback, a fake interface every machine has,
always `127.0.0.1`, which lets programs on the machine talk to each other
without touching a network. `enp0s1` is the real one.

**`UP,LOWER_UP`** means the interface is enabled *and* the cable is connected.
Those are two different things: `UP` without `LOWER_UP` is a configured interface
with nothing plugged in, and it is the first thing to check when nothing works at
all.

**`link/ether 5a:94:ef:e4:0c:ee`** is the MAC address, burned in and used only on
the local network segment. It never leaves it.

**`inet 192.168.127.2/24`** is the address and the mask together.

`dynamic` with `valid_lft 1803sec` means this came from DHCP and the lease has
30 minutes left. A static address says neither.

The interface is called `enp0s1`, not `eth0`. Modern distributions name
interfaces after where the hardware physically sits, so the name is stable
across reboots and card additions. It looks unfriendly and it is a genuine
improvement over `eth0` and `eth1` swapping places at boot. You saw the rename
happen in the kernel log back in lesson 10.

`ip -brief` gives the same information at a glance. Look at the state column for
`lo`, the loopback interface, which is always up and always working.

<details class="predict">
<summary><code>enp0s1</code> reports <code>UP</code>. Loopback is functioning perfectly. What state does it report, and why is it not <code>UP</code>?</summary>

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ ip -brief addr; echo "--- link state only ---"; ip -brief link
lo               UNKNOWN        127.0.0.1/8 ::1/128 
enp0s1           UP             192.168.127.2/24 fe80::97bb:e9e5:6ee3:27a3/64 
--- link state only ---
lo               UNKNOWN        00:00:00:00:00:00 <LOOPBACK,UP,LOWER_UP> 
enp0s1           UP             5a:94:ef:e4:0c:ee <BROADCAST,MULTICAST,UP,LOWER_UP> 
```

</details>

**`UNKNOWN`, and it is not a fault.** That column reports the *operational state*
the driver publishes, and virtual interfaces frequently do not publish one because
there is no physical link to have an opinion about. Loopback has no cable, so the
honest answer is that the question does not apply.

The one to read on a real interface is `LOWER_UP` in the flags: it means the
driver sees carrier, a cable plugged into something that is switched on.
**`UP` without `LOWER_UP` is the signature of an unplugged cable or a dead
switch port**, and it is the first thing to check before anything about
addresses.

Use `ip -brief addr` as the everyday command and the long form when you need the
detail.

## The mask, and the puzzle

`/24` means **the first 24 bits are the network, the rest is the machine.** An
IPv4 address is 32 bits, in four 8-bit chunks, so 24 bits is exactly the first
three numbers.

| CIDR | Old-style mask | Network part | Usable addresses |
| --- | --- | --- | --- |
| `/8` | `255.0.0.0` | First number | ~16.7 million |
| `/16` | `255.255.0.0` | First two | 65,534 |
| `/24` | `255.255.255.0` | First three | 254 |
| `/25` | `255.255.255.128` | First three and a bit | 126 |
| `/30` | `255.255.255.252` | Almost all of it | 2 |
| `/32` | `255.255.255.255` | All of it | 1 |

So `192.168.127.2/24` means: network is `192.168.127`, machine is `2`, and
**anything else starting `192.168.127.` is a neighbour I can reach directly.**

Two addresses in every subnet are not usable: the all-zeros one names the network
itself (`192.168.127.0`) and the all-ones one is broadcast (`192.168.127.255`).
That is why a `/24` gives 254 hosts rather than 256.

Now the puzzle from the top.

<details class="predict">
<summary><code>192.168.1.10/24</code> and <code>192.168.2.20/24</code>, same switch, same cable, both up. Work out from the mask alone why they cannot talk, and what single change fixes it.</summary>

**They are on different networks.** With a `/24`, the first machine's network is
`192.168.1` and the second's is `192.168.2`. Different by one number in the third
position, which is inside the network part.

So when machine one wants to reach `192.168.2.20`, it compares that address
against its own network and concludes the destination is **not local**. A
non-local destination is sent to the gateway. If there is no gateway configured,
the packet is dropped immediately with `Network is unreachable`; if there is one,
it is handed to a router that has no idea these two machines are on the same
switch.

Being on the same physical cable is irrelevant. **The mask decides who is a
neighbour, not the wiring.**

The single change: give them the same network. `192.168.1.10/24` and
`192.168.1.20/24`. Or, if the addresses must stay, widen both masks to `/16`,
so the network becomes `192.168` and both addresses fall inside it, which
works and is a strange thing to do deliberately.

This is why the mask is the second thing to check, right after "is it plugged
in". It produces failures that look like broken hardware and are arithmetic.

</details>

## Where a packet goes

<figure class="learn-figure">
<svg viewBox="0 0 720 320" role="img" aria-labelledby="route-title route-desc" style="width:100%;height:auto;">
  <title id="route-title">How a host decides where to send a packet</title>
  <desc id="route-desc">A host with address 192.168.1.10 slash 24 compares the destination against its own network. If the destination is inside 192.168.1.0 slash 24, the packet is delivered directly on the local network segment. If it is outside, the packet is sent to the default gateway at 192.168.1.1, which forwards it onward toward the internet. The subnet mask is what makes this decision.</desc>
  <g font-family="ui-monospace, monospace">
    <rect x="16" y="126" width="150" height="66" rx="4" fill="currentColor" fill-opacity="0.08" stroke="currentColor" stroke-opacity="0.32"/>
    <text x="91" y="150" text-anchor="middle" font-size="12" fill="currentColor">this host</text>
    <text x="91" y="168" text-anchor="middle" font-size="10.5" fill="currentColor" fill-opacity="0.65">192.168.1.10/24</text>
    <text x="91" y="183" text-anchor="middle" font-size="10" fill="currentColor" fill-opacity="0.5">wants to send to X</text>
    <rect x="214" y="118" width="176" height="82" rx="4" fill="currentColor" fill-opacity="0.05" stroke="currentColor" stroke-opacity="0.32"/>
    <text x="302" y="145" text-anchor="middle" font-size="11.5" fill="currentColor">is X inside</text>
    <text x="302" y="163" text-anchor="middle" font-size="11.5" fill="currentColor">192.168.1.0/24?</text>
    <text x="302" y="185" text-anchor="middle" font-size="9.5" fill="currentColor" fill-opacity="0.5">the mask decides this</text>
    <rect x="452" y="34" width="252" height="66" rx="4" fill="currentColor" fill-opacity="0.08" stroke="currentColor" stroke-opacity="0.32"/>
    <text x="578" y="58" text-anchor="middle" font-size="12" fill="currentColor">deliver directly</text>
    <text x="578" y="76" text-anchor="middle" font-size="10" fill="currentColor" fill-opacity="0.6">straight out of the interface,</text>
    <text x="578" y="90" text-anchor="middle" font-size="10" fill="currentColor" fill-opacity="0.6">no router involved</text>
    <rect x="452" y="216" width="252" height="66" rx="4" fill="currentColor" fill-opacity="0.08" stroke="currentColor" stroke-opacity="0.32"/>
    <text x="578" y="240" text-anchor="middle" font-size="12" fill="currentColor">send to the gateway</text>
    <text x="578" y="258" text-anchor="middle" font-size="10" fill="currentColor" fill-opacity="0.6">192.168.1.1, which forwards it</text>
    <text x="578" y="272" text-anchor="middle" font-size="10" fill="currentColor" fill-opacity="0.6">onward toward the internet</text>
  </g>
  <g stroke="currentColor" stroke-opacity="0.45" fill="none" stroke-width="1.2">
    <path d="M166 159 L210 159 M203 154 L211 159 L203 164"/>
    <path d="M390 145 L420 145 L420 67 L448 67 M441 62 L449 67 L441 72"/>
    <path d="M390 175 L420 175 L420 249 L448 249 M441 244 L449 249 L441 254"/>
  </g>
  <g font-family="ui-monospace, monospace" font-size="11" fill="currentColor" fill-opacity="0.75">
    <text x="398" y="112">yes</text>
    <text x="398" y="205">no</text>
  </g>
</svg>
<figcaption>One comparison, made for every packet. The mask is the only input.</figcaption>
</figure>

The routing table is that decision written down:

```
default via 192.168.127.1 dev enp0s1 proto dhcp src 192.168.127.2 metric 100 
192.168.127.0/24 dev enp0s1 proto kernel scope link src 192.168.127.2 metric 100 
```

Read the second line first, because it is the one that matters most and the one
nobody notices.

**`192.168.127.0/24 dev enp0s1 scope link`**, to reach this network, send out
of `enp0s1` directly. `proto kernel` means nobody configured it: **the kernel
created this route automatically when the address was assigned.** That is the
mechanism behind the diagram, and it is why an address and a mask are enough
to talk to neighbours with no further configuration.

**`default via 192.168.127.1`**, everything not matched by another line goes
to the gateway. `default` is shorthand for `0.0.0.0/0`, a route matching every
address, which is why it is checked last: **the most specific matching route
wins.**

`metric 100` breaks ties when two routes match equally, lower winning.


<details class="deeper">
<summary>If you already administer Linux: reading the whole routing table, and the reserved ranges</summary>

**`ip route get <address>` is the command that ends the argument.** Rather than
reading the table and reasoning about which line wins, ask the kernel to decide
for one specific destination and tell you the answer:

```
ip route get 8.8.8.8
ip route get 192.168.1.50
```

It reports the route chosen, the interface, and the source address that will
be used, which is the missing piece on a multi-homed machine, where "which
interface does this leave by" and "what address does the far end see" have
different answers.

**Most specific wins, then metric.** A `/32` beats a `/24` beats the default,
regardless of order in the file, because the kernel matches on prefix length
first. Metric only breaks ties between routes of equal specificity, lower
winning. That ordering explains why adding a more specific route is the safe way
to redirect one destination without touching the default.

**Multiple routing tables** exist and are worth knowing about before you meet
them. `ip rule` selects a table based on source address, interface, or firewall
mark; `ip route show table 100` reads a non-default one. VPNs and any host with
two uplinks use this, and a machine where `ip route` looks correct and traffic
still goes the wrong way is very often policy routing that nobody mentioned.

**The reserved ranges** are worth recognising on sight: `10.0.0.0/8`,
`172.16.0.0/12`, and `192.168.0.0/16` are private (RFC 1918); `127.0.0.0/8` is
loopback; `169.254.0.0/16` is link-local, and **an interface holding a 169.254
address means DHCP failed**, the machine gave itself one because nothing
answered. That last one is a diagnosis in a single glance.

</details>

<details class="deeper">
<summary>If you already administer Linux: how the kernel actually picks a route, and why "the default gateway" is only usually the answer</summary>

`ip route` prints a list and the kernel does not read it top to bottom. It picks
by **longest prefix match**: of every route whose network contains the destination,
the one with the most specific mask wins, regardless of order in the output.

```
10.0.0.0/8      via 192.168.1.254
10.5.0.0/16     via 192.168.1.253
0.0.0.0/0       via 192.168.1.1
```

A packet for `10.5.1.1` takes the `/16`, because 16 bits of match beats 8. A
packet for `10.9.1.1` takes the `/8`. Anything else takes the default, which
is simply the least specific route there is: `/0` matches everything with zero
bits, so it wins only when nothing else matches at all. **"Default gateway" is
not a special mechanism; it is the fallback that emerges from the rule.**

`ip route get` asks the kernel to run the decision for one destination and show its
working, which removes all guessing:

```
ip route get 10.5.1.1
ip route get 8.8.8.8 from 192.168.1.50
```

That prints the chosen route, the source address it will use, and the
interface, and `from` lets you ask the question as a specific local address,
which matters on multi-homed hosts.

**Metric breaks ties between routes of equal length**, and lower wins. A laptop on
both wifi and ethernet has two default routes; the metric is why traffic prefers
the cable, and `nmcli connection modify ... ipv4.route-metric` is how you change
which.

**And there is a whole layer above this that people meet without recognising it.**
The kernel actually consults *policy rules* first, which select which routing
**table** to use:

```
ip rule show
ip route show table all | head
```

Most machines have three tables and one obvious rule. But a VPN client, a
container runtime, or `systemd-networkd` with multiple interfaces will add
rules, and then `ip route` showing what looks like the right default is
misleading, because the packet is being sent to a different table entirely.
When routing behaviour makes no sense against `ip route`, `ip rule show` is
the next command, and `ip route get` is the one that settles it.

</details>

## Ports, TCP, and UDP

An address gets you to a machine. A **port** says which program on it.

| Port | Service |
| --- | --- |
| 22 | SSH |
| 80 | HTTP |
| 443 | HTTPS |
| 53 | DNS |
| 25 | SMTP |
| 3306 | MySQL |

Ports below 1024 are privileged: only root can bind them, which is why a web
server starts as root and drops privileges immediately.

| | TCP | UDP |
| --- | --- | --- |
| Connection | Established first | None |
| Delivery | Guaranteed, in order, retried | Best effort |
| Overhead | Higher | Lower |
| Used by | SSH, HTTP, databases | DNS, NTP, video, VPNs |

**TCP is a phone call, UDP is a postcard.** The postcard is faster and cheaper and
sometimes does not arrive, which is fine for one frame of video and not for one
row of a database.

What is listening:

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ ss -tuln | head -8; echo "--- with process names ---"; sudo ss -tlnp | head -5
Netid State  Recv-Q Send-Q Local Address:Port Peer Address:Port
udp   UNCONN 0      0          127.0.0.1:323       0.0.0.0:*   
udp   UNCONN 0      0              [::1]:323          [::]:*   
tcp   LISTEN 0      128          0.0.0.0:22        0.0.0.0:*   
tcp   LISTEN 0      128             [::]:22           [::]:*   
--- with process names ---
State  Recv-Q Send-Q Local Address:Port Peer Address:PortProcess                        
LISTEN 0      128          0.0.0.0:22        0.0.0.0:*    users:(("sshd",pid=1524,fd=6))
LISTEN 0      128             [::]:22           [::]:*    users:(("sshd",pid=1524,fd=7))
```

`-t` TCP, `-u` UDP, `-l` listening, `-n` numeric, `-p` process. **`ss -tlnp`
is the one to memorise**, it answers "what is listening and what program is
it".

Read the addresses. **`0.0.0.0:22` means SSH is listening on every interface**,
reachable from anywhere that can route to this machine. **`127.0.0.1:323` means
that service is bound to loopback only**, so nothing outside the machine can reach
it at all, whatever the firewall says.

That distinction is a security control in itself, and it is the first thing to
check when a service is "exposed" or "unreachable". Those are the same
question asked from two directions.

## Testing reachability

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ ping -c 3 192.168.127.1; echo "--- a name that does not exist ---"; dig +short nosuchname.example.com; echo "exit status $?"; host nosuchname.example.com
PING 192.168.127.1 (192.168.127.1) 56(84) bytes of data.
64 bytes from 192.168.127.1: icmp_seq=1 ttl=64 time=0.711 ms
64 bytes from 192.168.127.1: icmp_seq=2 ttl=64 time=0.249 ms
64 bytes from 192.168.127.1: icmp_seq=3 ttl=64 time=0.230 ms

--- 192.168.127.1 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2063ms
rtt min/avg/max/mdev = 0.230/0.396/0.711/0.222 ms
--- a name that does not exist ---
exit status 0
Host nosuchname.example.com not found: 3(NXDOMAIN)
```

`ping` sends ICMP echo requests. Three sent, three received, no loss,
sub-millisecond, a healthy local link.

**`-c 3` matters.** Without it `ping` runs until you press Ctrl+C, which is fine
interactively and a hang in a script.

The name lookup at the end is the next lesson, and there is already something
worth noticing: `dig +short` printed nothing and **exited 0**, while `host` said
`NXDOMAIN` plainly. Do not test for a name's existence with `dig +short`'s exit
status.

<details class="deeper">
<summary>If you already administer Linux: what ping really tests, MTU, IPv6, and the ARP layer</summary>

**A failed ping is weak evidence.** ICMP is routinely filtered (by hosts, by
firewalls, by cloud security groups) so "ping fails" frequently means "ICMP is
blocked" rather than "unreachable". A *successful* ping is strong evidence; a
failed one is nearly none. Test the port you actually care about: `nc -zv host
443`, or `curl -sv telnet://host:443`, or `ss` on the far end.

**MTU** is the largest frame the path will carry, 1500 by default. Anything
adding encapsulation (a VPN, a tunnel, some cloud overlays) leaves less room,
and if the ICMP "fragmentation needed" messages that would report this are
filtered, you get **path MTU black holes**: small packets fine, `ping` fine,
SSH connects and then hangs the moment output exceeds one frame. `ping -M do
-s 1472` finds the real limit by refusing fragmentation.

IPv6 is not optional any more. Every interface above has an `fe80::`
link-local address, always present and never routable off the segment. Modern
distributions prefer IPv6 when both are available, so a service listening only
on IPv4 with a name that resolves to both fails in a way that looks
intermittent. `curl -4` and `curl -6` are the fastest way to prove which
family is at fault, and `ss` output showing `[::]` versus `0.0.0.0` tells you
what a service is willing to accept.

**ARP** is the layer under all of this. Having decided a destination is local,
the host still needs its MAC address, and broadcasts to ask. `ip neigh` shows
the cache. Two machines with the same IP produce an ARP conflict, which
presents as brutally intermittent connectivity that follows no pattern: `ip
neigh` showing an address flipping between MACs is the tell, and `arping`
confirms it.

`0.0.0.0` means two different things depending on where it appears, which is a
genuine trap. As a listen address it means every interface. As a route
destination it means every address. Same notation, opposite direction.

</details>


<details class="deeper">
<summary>If you already administer Linux: ss beyond listening sockets, and connection states</summary>

`ss -tlnp` answers what is listening. The other half of the tool answers what is
*connected*, which is where capacity and firewall problems show up.

**`ss -tanp` shows every TCP socket with its state.** The states worth
recognising: `ESTAB` is a live connection; `TIME-WAIT` is a closed one being held
briefly by the side that closed first, and thousands of them is normal on a busy
server rather than a leak; `CLOSE-WAIT` is the local application failing to close
its end, and a growing count is a genuine application bug; `SYN-SENT` piling up
means packets are leaving and nothing is answering, which is a firewall or a
routing problem rather than a service problem.

`ss -s` gives the summary, total sockets by state, which is the fastest way to
see a machine running out of ephemeral ports or accumulating `CLOSE-WAIT`.

Filters make it usable on a busy host: `ss -tn state established '( dport =
:443 or sport = :443 )'`, or `ss -tn dst 10.0.5.0/24`. Worth knowing because
on a web server `ss -tanp` unfiltered produces thousands of lines.

`Recv-Q` and `Send-Q` on a listening socket mean something different from on
an established one. On a listener, `Recv-Q` is the number of connections
waiting to be accepted and `Send-Q` is the backlog limit, a `Recv-Q` at the
`Send-Q` value means the application is not accepting fast enough and
connections are being dropped, which presents to users as intermittent
refusals.

</details>

## Across distributions

The tools in this lesson are identical everywhere: `ip`, `ss`, and `ping` come
from `iproute2` and `iputils` on every distribution the exam covers.

| | Note |
| --- | --- |
| `ifconfig`, `netstat`, `route` | Deprecated, from `net-tools`, frequently not installed |
| `ip`, `ss`, `ip route` | The replacements. Use these. |
| Interface names | `enp0s1`-style everywhere; `eth0` only on containers and older systems |

**`ifconfig` is worth recognising and not worth using.** It appears in every older
tutorial, it does not understand multiple addresses per interface properly, and on
a minimal modern install it is simply absent. `ip addr` is the answer.

| Old | New |
| --- | --- |
| `ifconfig` | `ip addr` |
| `route -n` | `ip route` |
| `netstat -tulpn` | `ss -tulpn` |
| `arp -a` | `ip neigh` |

## Prove it

The ladder, in order. Each step assumes the one before it passed:

```bash
# 1. Is the interface up and is something plugged in
ip -brief link

# 2. Do I have an address, and what is the mask
ip -brief addr

# 3. Can I reach my own gateway
ip route | grep default
ping -c 3 <the gateway address>

# 4. Can I reach the internet by address
ping -c 3 1.1.1.1

# 5. Can I reach it by name
ping -c 3 example.com
```

**Steps 4 and 5 together are the most valuable two commands in networking.** Both
fail: routing or connectivity. Four works, five fails: DNS, and nothing else.
That one comparison eliminates half the possible causes in about three seconds.

## What trips people up

### 1. "Network is unreachable"

The kernel is saying it has **no route** for that destination, not that the
destination is down. Nothing was even sent.

`ip route` and look for a `default` line. No default gateway means anything
outside the local subnet fails this way immediately.

Compare with `No route to host`, which usually means something answered and
refused, and `Connection timed out`, which means the packet went somewhere and
nothing came back. Three different messages pointing at three different places.

### 2. The mask is wrong and everything looks fine

`ip addr` shows an address. The interface is up. The cable is in. And some
destinations work while others do not.

The pattern is the tell: the machines that work are the ones inside your
(incorrectly narrow, or incorrectly wide) network. Read the `/nn` and do the
comparison by hand.

A wrong mask is the failure that most looks like broken hardware and least is.

### 3. Confusing the interface being up with the network working

`UP` means the interface is administratively enabled. `LOWER_UP` means the
physical link is present. An interface can be `UP` with no cable.

`ip -brief link` shows both. `NO-CARRIER` in the flags means the cable, the
switch port, or the far end.

### 4. Using `ping` as proof of anything

Covered in the deeper panel. ICMP is filtered so often that a failed ping is
nearly meaningless on its own. Test the actual port.

### 5. Forgetting loopback is separate

A service bound to `127.0.0.1` is reachable from the machine and from nowhere
else. Testing with `curl localhost` succeeds, testing from another machine fails,
and the firewall gets blamed.

`ss -tlnp` and read the listen address. `0.0.0.0` is everywhere; `127.0.0.1` is
here only.

## Work it through

A user reports that a new server "has no internet". You log in (over SSH, from
the same office) and find:

```
$ ip -brief addr
lo               UNKNOWN        127.0.0.1/8 ::1/128
enp1s0           UP             10.0.5.42/24

$ ip route
10.0.5.0/24 dev enp1s0 proto kernel scope link src 10.0.5.42
```

Reason it out before reading on.

**Start with what already works.** You are logged in over SSH from the same
office. So the cable, the interface, the address, and the mask are all fine
for local traffic, that connection is the proof, and it rules out four things
without running a command.

Now read the routing table. One line. It covers `10.0.5.0/24`, the local
network, and it was created automatically by the kernel when the address was
set.

There is no `default` route. Nothing tells this machine where to send traffic
for anything outside `10.0.5.0/24`.

So what is the symptom, exactly? `ping 10.0.5.1` works. The gateway is a
neighbour and reachable directly. `ping 1.1.1.1` fails instantly with `Network
is unreachable`, not a timeout, because the kernel has nowhere to send it and
does not try.

Why is DNS not the answer? It could be a symptom, but it cannot be the cause:
the DNS server is almost certainly outside this subnet too, so lookups fail
for the same reason. Fixing DNS would change nothing. **Routing is below name
resolution, so it gets checked first.**

**The fix, temporarily:**

```
sudo ip route add default via 10.0.5.1
```

Immediate, and gone at the next reboot. Which makes it the perfect test: add it,
confirm `ping 1.1.1.1` works, and you have proved the diagnosis before changing
any configuration file. Making it permanent is the next lesson.

**Why did this happen?** Almost certainly a static address configured by hand with
the gateway field left blank. The address and mask are enough to produce a
working-looking machine, and the gateway is the field that is easy to skip
because nothing complains when you do.

**The habit worth taking:** when someone says "no internet", run `ip route` before
anything else. The presence or absence of one `default` line splits the problem
cleanly, and it takes a second.

## Try it

Optional, on any machine.

1. `ip -brief addr`. Write down your address, your mask, and work out your
   network's first and last usable addresses.
2. `ip route`. Identify the default gateway and the automatic local route.
3. `ping -c 3` your gateway, then `1.1.1.1`, then `example.com`. Note which
   succeed.
4. `ss -tlnp`. Find one service on `0.0.0.0` and one on `127.0.0.1`, and say what
   the difference means for reachability.
5. Work out by hand whether `192.168.4.130/25` and `192.168.4.120/25` are on the
   same network. Then check with `ipcalc` if it is installed.
6. `ip neigh` and see which neighbours your machine has recently talked to.

**Verification step.** You have it when you can be given an address in CIDR
notation and a second address, and say without tooling whether one can reach the
other directly.

## Check yourself

<details class="qa">
<summary>Name the four settings a host needs, and give the distinct symptom of each being wrong.</summary>

**Address**, who I am. Wrong: nothing works at all, and you may have collided
with another machine, producing wildly intermittent behaviour for both.

**Subnet mask**, which machines are local. Wrong: some destinations work and
some do not, following a pattern that only makes sense once you do the
arithmetic.

**Gateway**, where to send non-local traffic. Wrong or missing: the local
network is perfect and everything beyond it fails instantly with `Network is
unreachable`.

**DNS**, how to turn names into addresses. Wrong: `ping 1.1.1.1` works and
`ping example.com` does not.

They fail independently, which is what makes them useful diagnostically: the
symptom names the setting.

</details>

<details class="qa">
<summary><code>192.168.1.10/24</code> and <code>192.168.2.20/24</code> on the same switch cannot communicate. Why, and what fixes it?</summary>

**Different networks.** With `/24`, the first three numbers are the network part.
`192.168.1` and `192.168.2` differ, so each machine considers the other non-local
and hands the packet to its gateway instead of putting it on the wire directly.

Sharing a switch is irrelevant. **The mask decides who is a neighbour, not the
cabling.**

The fix is to put them in the same network: `192.168.1.10/24` and
`192.168.1.20/24`. Widening both masks to `/16` also works, since `192.168`
would then be the network part and both addresses fall inside it, but that is
an odd thing to do on purpose.

</details>

<details class="qa">
<summary>What is the difference between <code>0.0.0.0:22</code> and <code>127.0.0.1:323</code> in <code>ss</code> output?</summary>

**`0.0.0.0:22`** means listening on **every** interface. Anything that can route
to this machine can reach port 22, subject to the firewall.

**`127.0.0.1:323`** means listening on **loopback only**. Reachable from
processes on this machine and from nowhere else at all, not because of a
firewall rule, but because the socket is not bound to any interface that
carries outside traffic.

The distinction is the first thing to check for both "why is this exposed" and
"why can I not reach this". They are the same question from two directions, and
`ss -tlnp` answers both.

Note `0.0.0.0` means something different as a *route* destination, where it means
every address rather than every interface. Same notation, opposite direction.

</details>

<details class="qa">
<summary><code>ping 1.1.1.1</code> succeeds and <code>ping example.com</code> fails. What is working and what is not?</summary>

**Everything up to and including routing is working.** The interface, the
address, the mask, the gateway, and the path to the internet are all fine, a
packet reached 1.1.1.1 and came back.

**Name resolution is not.** The machine cannot turn `example.com` into an address,
so nothing is ever sent.

Look at the DNS server the machine is configured with, whether it is reachable,
and whether it is answering. That is the next lesson.

This pair of commands is the highest-value test in networking precisely because
it splits the problem in half: everything below DNS is proven good by the first,
and the failure is isolated to one layer by the second.

</details>

<details class="qa">
<summary>Why is a failed <code>ping</code> weak evidence, and what should you use instead?</summary>

**Because ICMP is routinely blocked.** Host firewalls, network firewalls, and
cloud security groups all commonly drop it while allowing normal traffic, so a
failed ping frequently means "ICMP is filtered" rather than "the host is
unreachable".

The asymmetry is worth stating: a **successful** ping is strong evidence the path
works. A **failed** one is nearly no evidence at all.

Test the port you actually care about: `nc -zv host 443`, `curl -sv
telnet://host:443`, or `ss -tlnp` on the far end to confirm something is
listening there in the first place.

</details>

## References

- [ip(8)](https://man7.org/linux/man-pages/man8/ip.8.html) - Linux man-pages project. Accessed 2026-08-07.
- [ip-address(8)](https://man7.org/linux/man-pages/man8/ip-address.8.html) - Linux man-pages project. Accessed 2026-08-07.
- [ip-route(8)](https://man7.org/linux/man-pages/man8/ip-route.8.html) - Linux man-pages project. Accessed 2026-08-07.
- [ss(8)](https://man7.org/linux/man-pages/man8/ss.8.html) - Linux man-pages project. Accessed 2026-08-07.
- [ping(8)](https://man7.org/linux/man-pages/man8/ping.8.html) - Linux man-pages project. Accessed 2026-08-07.
- [tcp(7)](https://man7.org/linux/man-pages/man7/tcp.7.html) - Linux man-pages project. Accessed 2026-08-07.

Command output was captured on the podman machine, which has a real network
stack. Blocks without a distribution and architecture header are illustrative.
