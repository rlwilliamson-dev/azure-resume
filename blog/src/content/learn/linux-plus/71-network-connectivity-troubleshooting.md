---
title: "Network connectivity troubleshooting"
description: "Network faults feel arbitrary until you work the layers in order. Link, address, route, gateway, name, service, and the one distinction that decides where to look next: whether the far end refused you or said nothing at all."
deck: "It worked yesterday and nothing changed"
track: "linux-plus"
level: "deep"
order: 720
objectives:
  - "Work the diagnostic ladder in order rather than guessing"
  - "Distinguish a refused connection from a dropped one, and say what each implies"
  - "Read ip link, ip addr, and ip route output"
  - "Decide whether a fault is local, on the path, or at the far end"
  - "Recognise an MTU problem from its symptoms"
prerequisites: ["network-basics-addresses-and-routes", "configuring-networking"]
tags: ["linux", "linux-plus", "troubleshooting", "networking"]
updated: 2026-08-21
draft: false
examObjectives:
  - exam: "xk0-006"
    domain: "5.0"
    objective: "5.3"
sources:
  - title: "ip(8)"
    url: "https://man7.org/linux/man-pages/man8/ip.8.html"
    publisher: "man7.org"
    accessed: 2026-08-09
    tier: 1
  - title: "ss(8)"
    url: "https://man7.org/linux/man-pages/man8/ss.8.html"
    publisher: "man7.org"
    accessed: 2026-08-09
    tier: 1
  - title: "tcpdump(1)"
    url: "https://www.tcpdump.org/manpages/tcpdump.1.html"
    publisher: "tcpdump.org"
    accessed: 2026-08-09
    tier: 1
  - title: "RFC 792, ICMP including destination unreachable"
    url: "https://www.rfc-editor.org/rfc/rfc792"
    publisher: "IETF"
    accessed: 2026-08-09
    tier: 1
symptoms:
  - symptom: "Connection hangs with no error until it times out"
    anchor: "refused-or-dropped"
  - symptom: "Connection refused immediately on a port that should be open"
    anchor: "refused-or-dropped"
  - symptom: "Small requests work and large transfers hang"
    anchor: "when-the-size-of-the-packet-matters"
---

> **Before you read.** The application cannot reach the database. Both machines
> are up, both have addresses, and the developer has told you that nothing
> changed.
>
> There are perhaps fifteen things this could be, spread across two machines and
> everything between them. Guessing has a one in fifteen chance.

Network troubleshooting rewards order more than any other kind. The layers sit
on top of each other, each depending on the one below, so testing them in
sequence turns fifteen possibilities into four or five questions with yes or no
answers.

The mistake is starting in the middle, usually with `ping` to something on the
internet, and then reasoning backwards from an ambiguous result.

### Some words you will need

<dl class="terms">
<dt>link</dt>
<dd>The physical or virtual connection. Up means the interface believes it has a cable or its equivalent.</dd>
<dt>LOWER_UP</dt>
<dd>The driver reports carrier. Present means something is genuinely on the other end.</dd>
<dt>default route</dt>
<dd>Where packets go when no more specific route matches.</dd>
<dt>RST</dt>
<dd>A TCP reset. What a host sends when nothing is listening on the port.</dd>
<dt>DROP</dt>
<dd>A firewall discarding a packet without reply. Produces a timeout, not an error.</dd>
<dt>MTU</dt>
<dd>The largest packet an interface will carry without fragmenting.</dd>
<dt>conntrack</dt>
<dd>The kernel's table of tracked connections, used by NAT and stateful firewalls.</dd>
</dl>

## What breaks without this

**The wrong team gets the ticket.** A firewall problem goes to the application
team because the error mentioned the application.

**Hours go into a machine that was fine.** The fault was two hops away and every
test was run locally.

**A working service looks broken.** It was listening on `127.0.0.1` and
everything else was correct.

**Intermittent faults never get diagnosed.** Nobody captured packets while it was
happening, so every investigation starts after the evidence has gone.

## The ladder

Work upward. Each rung depends on the ones below it, so a failure tells you to
stop and fix that layer rather than continuing.

1. **Link.** Is the interface up and does it have carrier?
2. **Address.** Does it have the address you expect, on the subnet you expect?
3. **Route.** Is there a path out, and via the right gateway?
4. **Gateway.** Can you reach the first hop?
5. **Name.** Does the hostname resolve, and to the right address?
6. **Path.** Can packets reach the far end?
7. **Service.** Is anything listening there, and will it accept you?

<figure class="learn-figure">
<svg viewBox="0 0 720 320" role="img" aria-labelledby="lad-title lad-desc" style="width:100%;height:auto;">
<title id="lad-title">The seven rungs, bottom to top, and the command that answers each one</title>
<desc id="lad-desc">The ladder is drawn with link at the bottom and service at the top, because each rung depends on the ones below it. Link is answered by ip -brief link show, address by ip -brief addr show, route by ip route, gateway by ping to the first hop, name by getent hosts, path by traceroute -n or mtr, and service by ss -ltnp on the far end or nc -vz from here. Working upward means the first rung that fails is the one to fix, and every rung above it is untestable until then.</desc>
<g>
<rect x="46" y="16" width="216" height="34" rx="4" fill="currentColor" fill-opacity="0.07" stroke="currentColor" stroke-opacity="0.32"/>
<text x="62" y="38" font-size="11" fill="currentColor">7  service</text>
<text x="292" y="38" font-size="10" fill="currentColor" fill-opacity="0.75">ss -ltnp there, nc -vz from here</text>
<rect x="46" y="58" width="216" height="34" rx="4" fill="currentColor" fill-opacity="0.07" stroke="currentColor" stroke-opacity="0.32"/>
<text x="62" y="80" font-size="11" fill="currentColor">6  path</text>
<text x="292" y="80" font-size="10" fill="currentColor" fill-opacity="0.75">traceroute -n, or mtr</text>
<rect x="46" y="100" width="216" height="34" rx="4" fill="currentColor" fill-opacity="0.07" stroke="currentColor" stroke-opacity="0.32"/>
<text x="62" y="122" font-size="11" fill="currentColor">5  name</text>
<text x="292" y="122" font-size="10" fill="currentColor" fill-opacity="0.75">getent hosts</text>
<rect x="46" y="142" width="216" height="34" rx="4" fill="currentColor" fill-opacity="0.07" stroke="currentColor" stroke-opacity="0.32"/>
<text x="62" y="164" font-size="11" fill="currentColor">4  gateway</text>
<text x="292" y="164" font-size="10" fill="currentColor" fill-opacity="0.75">ping the first hop</text>
<rect x="46" y="184" width="216" height="34" rx="4" fill="currentColor" fill-opacity="0.07" stroke="currentColor" stroke-opacity="0.32"/>
<text x="62" y="206" font-size="11" fill="currentColor">3  route</text>
<text x="292" y="206" font-size="10" fill="currentColor" fill-opacity="0.75">ip route</text>
<rect x="46" y="226" width="216" height="34" rx="4" fill="currentColor" fill-opacity="0.07" stroke="currentColor" stroke-opacity="0.32"/>
<text x="62" y="248" font-size="11" fill="currentColor">2  address</text>
<text x="292" y="248" font-size="10" fill="currentColor" fill-opacity="0.75">ip -brief addr show</text>
<rect x="46" y="268" width="216" height="34" rx="4" fill="var(--accent)" fill-opacity="0.12" stroke="var(--accent)" stroke-opacity="0.9" stroke-width="1.8"/>
<text x="62" y="290" font-size="11" fill="var(--accent)">1  link</text>
<text x="292" y="290" font-size="10" fill="var(--accent)">ip -brief link show, and read LOWER_UP</text>
<text x="560" y="290" font-size="10" fill="var(--accent)">start here</text>
</g>
<g stroke="currentColor" stroke-opacity="0.5" fill="none" stroke-width="1.4">
<path d="M28 300 L28 20 M23 27 L28 18 L33 27"/>
</g>
</svg>
<figcaption>Bottom to top, because each rung rests on the ones under it. The first one that fails is the one to fix, and nothing above it can be tested until it does. Rung 1 is drawn as the starting point because it is also the rung people skip: <code>UP</code> is somebody having enabled the interface, and <code>LOWER_UP</code> is the driver seeing carrier, so an interface can be <code>UP</code> and unplugged.</figcaption>
</figure>

The first three come from one command each:

<details class="predict">
<summary>Three commands run in sequence on a working container. What does each rung report, and which flag in the link output actually proves something is on the other end?</summary>

```bash
# AlmaLinux 10.2, aarch64
$ echo "--- rung 1, is the link up ---"; ip -brief link show; echo "--- rung 2, is there an address ---"; ip -brief addr show; echo "--- rung 3, is there a route out ---"; ip route
--- rung 1, is the link up ---
lo               UNKNOWN        00:00:00:00:00:00 <LOOPBACK,UP,LOWER_UP> 
eth0@if9810      UP             da:49:22:3c:99:0c <BROADCAST,MULTICAST,UP,LOWER_UP> 
--- rung 2, is there an address ---
lo               UNKNOWN        127.0.0.1/8 ::1/128 
eth0@if9810      UP             10.88.20.93/16 fe80::d849:22ff:fe3c:990c/64 
--- rung 3, is there a route out ---
default via 10.88.0.1 dev eth0 proto static metric 100 
10.88.0.0/16 dev eth0 proto kernel scope link src 10.88.20.93 
```

</details>

`-brief` is worth the habit. The full output of `ip addr` is forty lines of
detail you rarely need, and the brief form fits the whole answer on one screen.

Reading rung 1: `UP` is the administrative state, meaning somebody enabled the
interface. `LOWER_UP` inside the flags is the one that matters, because it means
the driver sees carrier. An interface that is `UP` without `LOWER_UP` is
configured and unplugged, which on a physical machine means a cable and on a
virtual one means the hypervisor.

Rung 2 gives the address and, importantly, the prefix. `10.88.20.93/16` means
this host considers everything in `10.88.0.0` to `10.88.255.255` to be local and
will ARP for it rather than routing. A wrong prefix length is a classic fault
that looks like a routing problem: with `/24` here, the host would try to route
to `10.88.20.5` through the gateway instead of reaching it directly.

Rung 3 has two entries. The `default via 10.88.0.1` line is how anything off the
subnet leaves, and the second line is the subnet itself, added automatically
because of the address. No default route means the machine can talk to its own
subnet and nothing else, which presents as "some things work and some do not"
and is diagnosed in one command.

## Refused or dropped

This is the most useful distinction in network troubleshooting and it costs one
command to establish.

```bash
# AlmaLinux 10.2, aarch64
$ (nc -l 9000 >/dev/null 2>&1 &); sleep 1; echo "--- something is listening here ---"; nc -vz 127.0.0.1 9000 2>&1 | tail -1; echo "--- and nothing is listening here ---"; nc -vz 127.0.0.1 9999 2>&1 | tail -1
--- something is listening here ---
Ncat: 0 bytes sent, 0 bytes received in 0.01 seconds.
--- and nothing is listening here ---
Ncat: Connection refused.
```

Both answers came back instantly. The refusal is a real reply: the host received
the packet, had nothing listening on 9999, and sent a TCP RST saying so.

**So "Connection refused" is good news.** It proves the entire path works. Your
packet arrived, the host processed it, and its answer came back. The fault is
narrowed to one thing: the service is not listening where you expected.

Now the other case, with a firewall rule dropping packets to a destination:

<details class="predict">
<summary>A firewall rule silently discards packets to an address. What does a connection attempt look like, and how long does it take?</summary>

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ sudo nft add table inet tb; sudo nft add chain inet tb out "{ type filter hook output priority 0; }"; sudo nft add rule inet tb out ip daddr 192.0.2.1 drop
echo "--- packets to this address are silently discarded ---"
time timeout 5 bash -c "cat < /dev/tcp/192.0.2.1/80" 2>&1 | tail -3
sudo nft delete table inet tb
--- packets to this address are silently discarded ---

real	0m5.002s
user	0m0.001s
sys	0m0.002s
```

</details>

Five seconds, no output, no error. It hung until the timeout killed it, and left
behind exactly nothing to diagnose from.

**That silence is the signature of a firewall.** Something in the path is
discarding packets without replying, so the sender waits and retransmits until it
gives up. The pattern is the same whether the rule is on your host, on the far
host, or on a device between them.

| Result | Means | Look at |
| --- | --- | --- |
| Connects | Path and service are fine | The application |
| **Connection refused**, instantly | Reached the host, nothing listening | The service. `ss -ltnp` on the far end |
| **Times out** with no reply | Something is dropping silently | Firewalls, security groups, routing |
| **No route to host** | Local routing has nowhere to send it | `ip route` here |
| **Network unreachable** | No route at all for that destination | `ip route`, default gateway |
| Name resolution error | Never got as far as connecting | Lesson 72 |

**REJECT and DROP are the firewall settings behind the first two.** A rule that
rejects sends an ICMP or RST reply, which looks like "connection refused" and is
kind to clients. A rule that drops says nothing, which is slower to diagnose and
gives an attacker less information. Knowing which you are looking at tells you
what kind of rule you are up against.

<details class="deeper">
<summary>If you already administer Linux: is it listening, and is it listening where you think</summary>

More outages than anyone would like come down to a service bound to the wrong
address, and the check takes seconds.

```bash
ss -ltnp                    # listening TCP sockets, numeric, with process
ss -ltnp 'sport = :5432'    # just one port
ss -tnp state established   # who is currently connected
ss -s                       # summary counts by state
```

**The address in the Local Address column decides everything:**

| Shown as | Reachable from |
| --- | --- |
| `127.0.0.1:5432` | This machine only. The commonest cause of "it works locally" |
| `0.0.0.0:5432` | Any IPv4 address on this host |
| `[::]:5432` | All IPv6, and usually all IPv4 too via dual-stack |
| `10.0.1.5:5432` | Only through that one interface |

A service on `127.0.0.1` while the client is on another machine produces
"connection refused" from the client and works perfectly when you test it by
SSHing in first, which is exactly how it survives testing.

**Connection states worth recognising in `ss` output:**

- **`SYN-SENT` piling up** means your side is trying and getting nothing back.
  Same signature as the drop above.
- **`TIME-WAIT` in large numbers** is normal. It is the protocol holding a socket
  briefly after close, and it is rarely the problem people take it for.
- **`CLOSE-WAIT` piling up** is an application bug: the far end closed and your
  program never called `close()`. It leaks descriptors and will eventually hit
  the limit.
- **Recv-Q growing** on a listening socket means the application is not accepting
  connections fast enough, and the backlog is filling.

**Two counters that explain intermittent faults**, both easy to miss:

```bash
ss -s                                       # socket totals
nstat -az | grep -iE 'TcpExtListenDrops|TcpExtListenOverflows|TcpRetransSegs'
```

`ListenOverflows` climbing means the accept queue is full and connections are
being dropped at the kernel, which the application never sees and never logs. It
presents to users as random connection failures under load, and no amount of
reading application logs will find it.

**And conntrack, for anything doing NAT or stateful filtering.** The table has a
fixed maximum, and when it fills, new connections are dropped:

```bash
sudo conntrack -C                                  # current count
cat /proc/sys/net/netfilter/nf_conntrack_max       # the ceiling
dmesg | grep -i 'conntrack table full'
```

That message in `dmesg` is the whole diagnosis for a busy gateway or container
host that starts refusing connections under load while every service on it looks
healthy.

</details>

<details class="deeper">
<summary>If you already administer Linux: deciding which end is at fault without access to both</summary>

The awkward reality of network faults is that you usually control one side. Here
is how to work out which side is wrong from the side you have.

**Test outward in widening circles from the client**, and note where it stops:

```bash
ss -ltnp                              # is it even a local service
nc -vz 127.0.0.1 <port>               # loopback: the service itself
nc -vz <own-ip> <port>                # own address: local firewall in play
nc -vz <gateway> <port-you-know-open>  # can you leave the subnet
nc -vz <target> <port>                # the real thing
```

Each rung that works eliminates everything below it. Loopback succeeding and own
address failing is a **local firewall**, because nothing left the machine. Own
address succeeding and the target timing out puts the fault outward.

**Then the single most valuable test, if you can get a shell on the far end:**
run `nc -vz 127.0.0.1 <port>` there. If it works locally on the server and times
out from the client, the service is fine and the fault is the path or a
firewall. If it fails locally too, stop looking at the network.

**When you cannot get on the far end**, the asymmetry itself is informative:

- **Another client can reach it and you cannot.** The difference is your source
  address. Look for a source-based firewall rule or a security group.
- **You can reach it from a different host on your own subnet.** Same conclusion,
  narrowed to your host.
- **It worked an hour ago from here.** Something changed in between: a rule, a
  route, a certificate, a DHCP lease.
- **Some connections work and some do not, to the same host.** Suspect a load
  balancer with one bad backend. Test repeatedly and see if failures cluster.

**Asymmetric routing is the fault that produces the strangest evidence.**
Packets go out one path and return by another, and if a stateful firewall sees
only one direction it drops the connection. The signature is a handshake that
half completes, with tcpdump on each end showing packets the other never saw.
Multiple default routes, or two interfaces on subnets that both reach the target,
are how you get there. `ip route get <destination>` shows which path the kernel
will actually choose, which is more reliable than reading the routing table and
inferring.

**One more: DNS resolving to the wrong address entirely.** Everything above is a
connectivity test to whatever address the name gave you. Resolve it explicitly
first, with `getent hosts <name>`, and confirm you are testing the host you think
you are. That is lesson 72's territory and it is worth ruling out before spending
an hour on firewalls.

</details>

## Following the path

When the far end times out, the next question is how far the packets get.

```bash
ping -c3 10.88.0.1              # the gateway. Rung 4
traceroute -n db.example.com    # the path, one hop per line
mtr -rwc 100 db.example.com     # traceroute plus loss over time
```

`traceroute` shows where packets stop. `mtr` runs it continuously and reports
loss per hop, which is what you want for an intermittent fault rather than a
total failure.

Two more are worth having in the same muscle memory. **`tracepath` does most of
what `traceroute` does and needs no privileges**, which matters on a machine where
you have a login and not much else, and it prints the path MTU as it goes, so a
black-holed large packet shows up in the same output. **`ping6`** is the same
question asked over IPv6, and on a dual-stack host it is the command that
separates "the network is broken" from "the network is broken for one of the two
address families", which is a distinction the objectives name and a fault people
lose hours to.

**And one symptom that reads as a cabling fault and is not.** Two machines
answering for the same MAC address, whether from a cloned virtual machine, a
misconfigured bond, or somebody setting one by hand with
`ip link set dev eth0 address`, produces connectivity that works for one host at a
time and alternates. The neighbour table on a third machine is where it shows: the
same hardware address against two addresses, or one address whose hardware address
changes every time you look.

**Read a traceroute carefully, because it lies in a specific way.** Stars in the
middle followed by later hops answering do not mean packet loss: plenty of
routers deprioritise or refuse the ICMP that traceroute depends on while
forwarding traffic perfectly. Loss that starts at a hop **and continues to the
end** is real. Loss at one hop that clears afterwards is a router being
uncooperative, not a fault.

**`ping` deserves the same caution.** ICMP is frequently rate-limited or blocked
outright, so a host that does not answer ping may be serving traffic fine. Use it
as a positive signal and never as proof of absence. A TCP test to the actual port
is always better evidence.

<details class="deeper">
<summary>If you already administer Linux: watching the packets, and the fault that only affects large transfers</summary>

When the higher-level tools disagree with each other, capture the traffic. It is
the only way to see what genuinely left the machine and what came back.

```bash
sudo tcpdump -n -i any port 5432                    # no name lookups, all interfaces
sudo tcpdump -n host 10.0.1.5 and port 5432 -c 20   # bounded, so it stops
sudo tcpdump -n -i eth0 -w /tmp/cap.pcap            # to a file for Wireshark
```

**`-n` matters more than it looks.** Without it, tcpdump does a reverse DNS
lookup for every address, which is slow and, when DNS is the thing you are
debugging, actively misleading.

**What to look for, in order:**

- **SYN with no reply.** Your packets are leaving and nothing is coming back.
  The fault is outward of this machine.
- **SYN followed by RST.** The far end is actively refusing. Service not
  listening, or a rejecting firewall.
- **Retransmissions of the same sequence number.** Loss somewhere in the path.
- **Nothing at all on the wire.** The packets never left. Look at local routing,
  a local firewall, or the application not doing what you assume.

That last case is worth its own note, because it is the one that resolves
arguments. If tcpdump on the sending host shows nothing, the network is not
involved and the application never made the call.

**MTU problems have a distinctive signature** and confuse people for days: the
connection establishes, small requests work, and anything large hangs. The
handshake is tiny packets and succeeds; the first full-size packet is too big for
some link in the path and gets dropped.

Normally ICMP "fragmentation needed" tells the sender to use smaller packets.
When a firewall blocks that ICMP, the sender never finds out and retransmits
forever. This is **PMTU black hole** behaviour, and blocking all ICMP is what
causes it.

Test it by finding the largest packet that gets through, with fragmentation
forbidden:

```bash
ping -M do -s 1472 -c2 db.example.com     # 1472 + 28 = 1500
ping -M do -s 1400 -c2 db.example.com     # if 1472 fails, work down
```

1500 is the Ethernet default. Anything encapsulating traffic reduces it: VPNs,
VXLAN overlays like lesson 61's Swarm networks, and PPPoE all take a bite.
Setting the interface MTU to match the path, or clamping TCP MSS on a gateway, is
the fix.

**And check the interface's own error counters before blaming the path:**

```bash
ip -s link show eth0        # RX/TX errors, dropped, overruns
sudo ethtool eth0           # negotiated speed and duplex
sudo ethtool -S eth0        # driver-level statistics
```

A link negotiated at 100 Mb when it should be 1000, or a duplex mismatch, gives
you a connection that works and is inexplicably slow, with errors climbing. That
is a physical layer fault wearing a performance costume.

</details>

## Across distributions

The kernel side of networking is identical everywhere. Everything above it, the
thing that decides what the interface is configured with and which firewall is
enforcing what, is a distribution choice.

| | RHEL family | Debian family |
| --- | --- | --- |
| `ip`, `ss`, `ping` | `iproute2`, identical | `iproute2`, identical |
| What configures the interface | NetworkManager | netplan on Ubuntu, ifupdown on Debian |
| Change an address persistently | `nmcli con mod` | `netplan apply`, or `/etc/network/interfaces` |
| Firewall front end | `firewalld` | `ufw`, or `nftables` directly |
| `traceroute` installed | Often not, `traceroute` package | Often not, `traceroute` package |
| `tcpdump` installed | Rarely, `tcpdump` package | Rarely, `tcpdump` package |
| Rule that produces a timeout | `firewalld` drops by default | `ufw` drops by default |

**Both default firewalls drop rather than reject**, which is why a blocked port
on a stock machine of either family hangs instead of refusing. That is a
deliberate choice, and it is also the single most common reason a connection test
takes thirty seconds to tell you nothing.

`tcpdump` being absent is worth planning around. The moment you want it is the
moment you are already in an incident, and installing a package onto a machine
whose networking is broken has an obvious problem. Put it in the base image.

## Prove it

Work the ladder in order. Each command answers one rung, and answering them out
of order is how people end up debugging DNS when the cable is unplugged:

```bash
# 1. Link: is there a carrier
ip -br link show                 # LOWER_UP is the flag that matters

# 2. Address: is there one, and is the prefix right
ip -br addr show

# 3. Route: where would a packet to that destination go
ip route get 10.4.9.5

# 4. Gateway: can the first hop be reached
ping -c2 "$(ip route | awk '/default/{print $3}')"

# 5. Name: what does the application get, not what dig gets
getent hosts theserver

# 6. Path: does anything answer on the port
nc -vz theserver 5432

# 7. Service: is it listening, and on which address
ss -ltnp | grep 5432
```

**`ip route get` is the rung people skip and the one that settles arguments.** It
asks the kernel what it would actually do with a packet to that address,
including which source address and which interface it would use, so it answers a
routing question without any guessing about which rule matched.

## What trips people up

### 1. Reading `UP` as connected

`UP` is the administrative state you set. `LOWER_UP` is the driver saying it can
see a link partner. An interface can be `UP` for months with the cable out.

### 2. Treating refused and timed out as the same failure

Refused means a host received the packet and answered with a reset, which proves
the address, the route, and the firewall are all fine and only the service is at
fault. A timeout means nothing came back at all, which is a firewall until
proven otherwise. They are opposite diagnoses.

### 3. Using `ping` as proof of anything

Plenty of hosts and networks drop ICMP on purpose, so a failed `ping` to a
working server is routine and a successful one says only that the machine is
powered on. Test the port you actually care about with `nc -vz` or `curl`.

### 4. Believing traceroute's middle hops

Routers rate limit or suppress the ICMP replies traceroute depends on, so a hop
showing complete loss while later hops answer normally is a reporting artefact.
Loss that starts at a hop and continues to the destination is the real thing.

### 5. Missing that the service is bound to loopback

`ss -ltnp` showing `127.0.0.1:8080` means the service accepts connections from
the machine itself and nothing else. Testing from the server works perfectly,
which is exactly why this survives so long, and remote clients get refused.

### 6. Getting the prefix wrong and not noticing

A `/24` on a network that is really a `/16` still works for anything inside the
mistaken range and for anything reached through the gateway. It breaks only for
the hosts that should have been local and are not, which looks like an
intermittent fault rather than a configuration error.

## Work it through

An application on `app-02` cannot reach a database on `db-01:5432`. The database
is running and other clients are connected to it.

Reason it out before reading on.

**One distinction saves more time here than anything else.** This one distinction saves more
time than anything else in the topic:

```bash
nc -vz db-01 5432
```

If it returns `Connection refused` immediately, the packet reached `db-01` and
something there said no, so the whole network path is fine. If it hangs and times
out, nothing came back and the fault is in the path.

Say it times out.

**Work down the ladder rather than guessing.** Other clients connect,
which is a strong hint the database is fine and the difference is on this host or
this route:

```bash
ip route get 10.4.9.5           # what would this host do with the packet
ping -c2 10.4.9.4               # the gateway that route names
```

**A working client is a reference implementation sitting right there.** Something works for other clients and not this
one, so compare rather than investigate in isolation. A working client is a
reference implementation sitting right there:

```bash
# on app-02 and on a client that works
ip -br addr show; ip route
```

A different prefix, a different gateway, or a source address on the wrong
interface shows up immediately in that comparison.

**If the host looks identical, suspect what sits between them.** A
timeout with a correct route is a firewall dropping silently, and it may be on
`db-01` rather than on the network:

```bash
# on db-01
sudo firewall-cmd --list-all          # or: sudo ufw status verbose
sudo ss -ltnp | grep 5432             # is it listening on 0.0.0.0 or on one address
```

The reasoning worth taking away: the first command classified the failure, and
that classification eliminated either the network or the service before anything
else was checked. Comparing against a working client did most of the rest, which
is usually faster than reasoning from first principles about one machine.

## Try it

Optional, and two containers on the same host are enough for most of it.

1. Start a service listening on `127.0.0.1` only, then try to reach it from
   another container. Note the exact error and how long it takes. Rebind it to
   `0.0.0.0` and repeat.
2. Add a firewall rule that REJECTs the port, test again, then change it to DROP
   and test again. Time both. This is the difference the whole topic rests on.
3. Take an interface down with `ip link set eth0 down` and read `ip -br link`
   before and after. Find `LOWER_UP` in the output of a working one.
4. Set an obviously wrong prefix, such as `/30` on a `/24` network, and see which
   hosts you can still reach and which you cannot.

**Verification step.** You have step 2 right when you can state, without checking
your notes, which rule produced the instant failure and which produced the wait,
and what each one tells you when you meet it on a machine you have never seen.

## For the exam

**Work the ladder in order:** link, address, route, gateway, name, path,
service.

**`LOWER_UP` means carrier.** `UP` without it is configured and unplugged.

**"Connection refused" proves the path works.** The host replied with a reset,
so only the service is at fault.

**A timeout with no reply means something is dropping silently**, which is a
firewall until proven otherwise.

**REJECT produces refused; DROP produces a timeout.**

**`ss -ltnp` shows what is listening and on which address.** `127.0.0.1` is
local only.

**ICMP being blocked means `ping` and `traceroute` can mislead.** Prefer a TCP
test to the real port.

**Traceroute loss that stops after a hop is a router deprioritising ICMP**, not a
fault. Loss that continues to the end is real.

**Small packets working and large ones hanging is MTU**, usually with the
necessary ICMP blocked.

**Check the subnet prefix.** A wrong `/24` for a `/16` looks like a routing
fault.

<details class="qa">
<summary>Check yourself</summary>

**Connection refused instantly. What does that rule out?**
Everything in the path. Packets reached the host and it replied with a reset, so
the problem is that nothing is listening on that port.

**A connection hangs for 5 seconds and times out with no message. What is the
likeliest cause?**
Something is dropping packets silently, which is a firewall rule until proven
otherwise. It could be on either host or anywhere between.

**Difference between a REJECT rule and a DROP rule, from the client's side?**
REJECT replies, so the client sees "connection refused" immediately. DROP says
nothing, so the client waits and times out.

**An interface shows `UP` but not `LOWER_UP`. What is wrong?**
It is administratively enabled with no carrier. Physically that is a cable or
switch port; on a VM it is the hypervisor's network.

**The host has address `10.88.20.93/16`. Why does the prefix matter?**
It decides what the host treats as local. With `/16` it ARPs directly for
anything in `10.88.x.x`. Set to `/24` it would try to route those through the
gateway instead.

**`ip route` shows no default route. What are the symptoms?**
Local subnet works, everything else fails. It presents as "some things work",
which sounds like a bigger mystery than it is.

**The service works when you SSH in and test locally, and not from another
machine. First check?**
`ss -ltnp`. It is almost certainly bound to `127.0.0.1` instead of `0.0.0.0`.

**A traceroute shows stars at hop 4 but hops 5 through 9 answer. Is hop 4
dropping traffic?**
No. That router is not answering ICMP for traceroute while still forwarding.
Loss that continues to the end is real; loss that clears is not.

**A host does not answer ping. Is it down?**
Not necessarily. ICMP is often blocked or rate limited. Test the actual TCP port
instead.

**The connection establishes, small queries work, large results hang. What is
it?**
MTU, with the ICMP "fragmentation needed" message being blocked so the sender
never learns to send smaller packets.

**How do you find the largest packet that gets through?**
`ping -M do -s <size>`, working down. Add 28 bytes for headers when comparing
against 1500.

**What does `CLOSE-WAIT` piling up in `ss` mean?**
The far end closed and the local application never called `close()`. It is an
application bug and it leaks file descriptors.

**Connections fail randomly under load, and the application logs nothing. What
kernel counters would you check?**
`ListenOverflows` and `ListenDrops` in `nstat`, and conntrack table usage against
`nf_conntrack_max`. Both drop connections below the application's view.

**tcpdump on the sending host shows nothing at all. What does that tell you?**
The packets never left, so the network is not involved. Look at local routing, a
local firewall, or whether the application made the call.

</details>

## Where this sits

Lessons 16 and 17 built and configured networking. This is the same knowledge
turned around: given a failure, which layer is at fault. Lesson 40 explains what
the firewall doing the dropping is actually made of, and lesson 72 takes the name
resolution rung and gives it a lesson of its own.


## References

- [ip(8)](https://man7.org/linux/man-pages/man8/ip.8.html) - man7.org. Accessed 2026-08-09.
- [ss(8)](https://man7.org/linux/man-pages/man8/ss.8.html) - man7.org. Accessed 2026-08-09.
- [tcpdump(1)](https://www.tcpdump.org/manpages/tcpdump.1.html) - tcpdump.org. Accessed 2026-08-09.
- [RFC 792, ICMP including destination unreachable](https://www.rfc-editor.org/rfc/rfc792) - IETF. Accessed 2026-08-09.
> **The commands here were run on a real machine, not written from memory.** The
> ladder and the refused-versus-open pair come from AlmaLinux 10.2 on aarch64. The
> silent drop was produced on the Fedora CoreOS VM with a real nftables rule
> discarding packets to a documentation address, and the five seconds in that
> transcript is `time` reporting an actual wait, not an illustration. The rule was
> deleted in the same command that created it.
