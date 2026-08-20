---
title: "Connection and interface tools"
description: "Something is listening on a port and nobody knows what. Listing listening sockets and reading the address each is bound to, seeing who is connected right now, the interface tools on each platform and which name goes with which, and the neighbour table."
deck: "Something is listening on a port and nobody knows what"
track: "network-plus"
level: "working"
order: 640
objectives:
  - "List listening sockets and read the address each is bound to"
  - "Tell a socket bound to every interface from one bound to loopback"
  - "List active connections and recognise the states worth knowing"
  - "Name the interface tool on each platform and read its output"
  - "Read the neighbour table and say what it proves"
prerequisites: ["tcp-udp-and-the-handshake"]
tags: ["network-plus", "networking", "troubleshooting", "tools"]
updated: 2026-08-19
draft: false
examObjectives:
  - exam: "n10-009"
    domain: "5.0"
    objective: "5.5"
sources:
  - title: "ss(8)"
    url: "https://man7.org/linux/man-pages/man8/ss.8.html"
    publisher: "man7.org"
    accessed: 2026-08-19
    tier: 1
  - title: "ip(8)"
    url: "https://man7.org/linux/man-pages/man8/ip.8.html"
    publisher: "man7.org"
    accessed: 2026-08-19
    tier: 1
  - title: "RFC 9293, Transmission Control Protocol"
    url: "https://www.rfc-editor.org/rfc/rfc9293"
    publisher: "IETF"
    accessed: 2026-08-19
    tier: 1
symptoms:
  - symptom: "A port is open and the bound address decides whether it is exposed"
    anchor: "what-is-listening-and-on-which-address"
  - symptom: "An interface name in one tool does not match the name in another"
    anchor: "the-interface-tools-and-which-name-goes-with-which"
---

> **Before you read.** A security scan reports that a server has a port open that
> nobody expected. You log in to investigate. The port is genuinely listening. It
> could be a service you forgot, a service somebody else installed, or a service
> that is only reachable from the machine itself and no threat at all.
>
> **The port is open. What do you need to read to know whether it matters?**

The tools in this topic answer three questions about the machine in front of you:
what is listening, who is connected, and what does the machine know about its own
interfaces and neighbours. They are the first commands you run on a host that is
misbehaving, and the skill is less in running them than in reading one field most
people skip.

### Some words you will need

<dl class="terms">
<dt>socket</dt>
<dd>One end of a connection, identified by an address and a port. A listening socket is waiting for connections; an established one has one.</dd>
<dt>listen address</dt>
<dd>The address a service bound to. 0.0.0.0 means every interface, so the network; 127.0.0.1 means loopback only, so the machine itself.</dd>
<dt>established</dt>
<dd>A connection that completed the handshake and is open. One of several states a connection moves through.</dd>
<dt>neighbour table</dt>
<dd>The map of IP address to MAC address the host built by asking, from topic 02. Also the ARP table.</dd>
<dt>ss</dt>
<dd>The socket statistics tool on modern Linux. netstat is the older one the exam names, present on every platform.</dd>
</dl>

## What breaks without this

**An open port is treated as an exposure without checking.** A port bound to
loopback is reachable only from the machine itself, and reading a listening socket
without reading its bound address turns a non-issue into an incident, or misses a
real one.

**A connection's state is misread.** A connection in a lingering close state is not
a leak and not a fault, and counting it as an active user, or an attack, is a common
false alarm.

**An interface name is assumed to be the same everywhere.** The name a machine uses
for an interface differs by platform and by tool, and a command aimed at the wrong
name silently does nothing.

## What is listening, and on which address

A listening socket is a service waiting for connections, and the field that decides
whether it matters is the address it bound to. The lab runs a host with two
services: one that binds every interface and one that binds only loopback. The
topology is
[`sockets.sh`](https://github.com/rlwilliamson-dev/azure-resume/blob/main/blog/scripts/topologies/sockets.sh).

<details class="predict">
<summary>One host runs two services: one bound to every address and one bound to loopback. What does the socket list show, and which of the two can anybody else reach?</summary>

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology sockets
# a client on h2 opens a connection to the h1 web server and holds it
$ ip netns exec h2 python3 /root/hold.py &
$ sleep 1
# what is listening on h1, and the address each service bound to
$ ip netns exec h1 ss -tlnp
State  Recv-Q Send-Q Local Address:Port Peer Address:PortProcess                         
LISTEN 0      5            0.0.0.0:8000      0.0.0.0:*    users:(("python3",pid=44,fd=3))
LISTEN 0      5          127.0.0.1:9000      0.0.0.0:*    users:(("python3",pid=46,fd=3))
# who is connected to it right now
$ ip netns exec h1 ss -tnp
State Recv-Q Send-Q Local Address:Port Peer Address:Port Process                         
ESTAB 0      0           10.0.0.1:8000     10.0.0.2:45310 users:(("python3",pid=44,fd=4))
```

</details>

Read the two `LISTEN` lines, because they are the whole point. The service on
`0.0.0.0:8000` bound every interface, so it answers the network, and anything that
can route to this host can reach it. The service on `127.0.0.1:9000` bound loopback,
so it answers only this machine, and nothing on the network can reach it at all. A
scan from another host would see the first and never the second. Same word,
listening, two completely different exposures, and the difference is one field.

<figure class="learn-figure">
<svg viewBox="0 0 720 250" role="img" aria-labelledby="listen-title" style="width:100%;height:auto;">
<title id="listen-title">Two listening sockets on one host, one bound to every interface and reachable from the network, the other bound to loopback and reachable only from the host itself</title>
<g fill="currentColor">
<text x="14" y="20" font-size="11">two sockets, both listening, and only one of them is reachable from the network</text>
<rect x="270" y="44" width="330" height="180" rx="6" fill="currentColor" fill-opacity="0.03" stroke="currentColor" stroke-opacity="0.65"/>
<text x="286" y="66" font-size="10.5">the host</text>
<rect x="300" y="82" width="270" height="42" rx="4" fill="var(--accent)" fill-opacity="0.12" stroke="var(--accent)" stroke-opacity="0.85" stroke-width="1.5"/>
<text x="314" y="100" font-size="10">0.0.0.0:8000</text>
<text x="314" y="116" font-size="9.5" fill-opacity="0.8">bound every interface</text>
<rect x="300" y="146" width="270" height="42" rx="4" fill="currentColor" fill-opacity="0.08" stroke="currentColor" stroke-opacity="0.7"/>
<text x="314" y="164" font-size="10">127.0.0.1:9000</text>
<text x="314" y="180" font-size="9.5" fill-opacity="0.75">bound loopback only</text>
<rect x="24" y="120" width="120" height="40" rx="4" fill="currentColor" fill-opacity="0.06" stroke="currentColor" stroke-opacity="0.7"/>
<text x="84" y="144" text-anchor="middle" font-size="10">the network</text>
<path d="M 144 128 C 210 116 240 103 300 103" stroke="var(--accent)" stroke-width="1.8" fill="none"/>
<path d="M 292 98 l 9 5 l -9 5" stroke="var(--accent)" stroke-width="1.8" fill="none"/>
<text x="150" y="104" font-size="9.5" fill="var(--accent)">reaches it</text>
<path d="M 144 152 C 200 165 235 167 296 167" stroke="var(--red)" stroke-width="1.6" fill="none" stroke-dasharray="5 4"/>
<line x1="286" y1="161" x2="296" y2="173" stroke="var(--red)" stroke-width="1.8"/>
<line x1="296" y1="161" x2="286" y2="173" stroke="var(--red)" stroke-width="1.8"/>
<text x="150" y="196" font-size="9.5" fill="var(--red)">cannot reach it</text>
</g></svg>
<figcaption>Both services are listening, and the bound address is the whole difference. The one on 0.0.0.0 accepted every interface, so a packet arriving from the network reaches it. The one on 127.0.0.1 accepted only the loopback interface, so a packet from the network is refused before any service sees it, and only a process on the host itself can connect. Reading "a port is listening" without reading the address it bound to is how a harmless loopback service becomes a reported exposure, and how a genuinely exposed one gets waved past.</figcaption>
</figure>

<details class="deeper">
<summary>If you already audit these: reading a listen list as an attack surface</summary>

The same output that answers what is listening answers a more useful question, which is how
much of this machine is exposed and to whom.

Read the address column rather than the port column. A service on the loopback address is
reachable only from the machine and is not attack surface at all, however alarming its name.
A service on a specific address is exposed on that interface only, which on a multi-homed
host is a deliberate and useful restriction. A service on the wildcard is exposed on every
interface the machine has, including ones added later, which is the case worth questioning.

That reading turns a long list into a short one. Most of what a modern machine is listening
on is loopback, and the handful bound to real addresses is the actual surface. Comparing
that handful against what the machine is supposed to do is a five-minute audit that
reliably finds something nobody meant to run.

The related habit is to re-run it after any software installation, because packages
routinely start services nobody asked for and bind them widely. A machine that was audited
at build time and has had three things installed since has an attack surface nobody has
looked at, and the command to look takes seconds.

</details>

## Who is connected right now

The same tool, without the listen filter, shows connections rather than listeners.
The lab opens one connection to the web server and then asks who is connected.

The `ESTAB` line in the capture above names both ends: the local `10.0.0.1:8000`
and the peer `10.0.0.2` on some high port it chose. That is an established
connection, one that completed the handshake from topic 09 and is open. Reading who
is connected to a service, and from where, is how you tell expected traffic from a
client that should not be there.

<details class="deeper">
<summary>If you already read connection states: the ones that pile up, and what each pile means</summary>

A connection list is mostly established sessions and the interesting information is in the
states that accumulate, because each pile has a distinct cause.

Sockets waiting to close after the local end initiated the shutdown are normal and
short-lived, and a large number of them means the machine is closing many connections
quickly, which is ordinary for a busy client and worth noticing on a server. The pile that
matters more is half-open connections waiting for a handshake to complete: many of those
from many sources is either a flood or a network problem preventing handshakes finishing,
and either way the machine is not at fault.

A pile of connections in the state where the local application has closed but the far end
has not is the one that points at your own software, because it means the application is
not closing sockets it should be. That is a resource leak with a visible signature, and it
is usually discovered when the machine runs out of file descriptors rather than by anybody
looking.

Which suggests reading the distribution rather than the list. A count grouped by state
takes one command and turns a screen of connections into a shape, and the shape is what
tells you whether you are looking at a busy machine, an attacked one, or a leaking one.

</details>

## The interface tools, and which name goes with which

The second job is reading the host's own interfaces, and the trap is the name. Every
platform names interfaces differently, and even on one platform different tools can
print different names for the same thing, so a command aimed at the wrong name does
nothing and reports no error.

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology sockets
# the interfaces this host has, one line each
$ ip netns exec h1 ip -br addr show | grep -vE "gre0|gretap0|erspan0"
lo               UNKNOWN        127.0.0.1/8 
h10@if6          UP             10.0.0.1/24 
# who h1 has recently spoken to on the wire, after reaching two hosts
$ ip netns exec h1 ping -c1 -W1 -q 10.0.0.2 >/dev/null
$ ip netns exec h1 ping -c1 -W1 -q 10.0.0.3 >/dev/null
$ ip netns exec h1 ip neigh show
10.0.0.3 dev h10 lladdr 02:00:00:00:00:03 REACHABLE 
10.0.0.2 dev h10 lladdr 02:00:00:00:00:02 REACHABLE 
```

On this host the real interface is `h10`, carrying `10.0.0.1/24`, and `lo` is
loopback. The neighbour table underneath names the two hosts this machine has spoken
to, mapping each IP to the MAC behind it, which is topic 02's resolution cache made
visible. A populated neighbour entry proves the machine has exchanged frames with
that address at layer two, which is a lower and more specific fact than a successful
ping: it says the wire between them works, whatever is happening higher up.

<details class="deeper">
<summary>If you already work on networks: the tool the exam names against the one Linux actually uses, and the states worth recognising</summary>

Two things are worth having straight, and the first is a naming split the exam sits
on the wrong side of.

Objective 5.5 names `netstat`, and on a modern Linux system `netstat` is the older
tool, often not installed by default, superseded by `ss`. They answer the same
questions and `ss` is faster and shows more, which is why the labs on this track use
it. The exam will ask about `netstat`, so know both: `ss -tlnp` and `netstat -tlnp`
list the same listening sockets, and the flags happen to match. On Windows and macOS
`netstat` is the tool present, with different flags again, so the one name the exam
uses is the one that exists everywhere even where it is no longer preferred.

The second is connection states, because reading them wrongly is a routine false
alarm. A connection moves through states defined in RFC 9293: it is `LISTEN`, then
briefly in handshake states, then `ESTABLISHED` for its working life, then through
closing states as it shuts down. The one that confuses people is `TIME_WAIT`, the
lingering state a connection sits in after closing, for a minute or two, so that late
packets from the old connection cannot be mistaken for a new one. A host with hundreds
of `TIME_WAIT` connections is not leaking and not under attack; it is a busy server
that has closed a lot of connections recently and is waiting out the safety timer on
each, exactly as the protocol says to. Counting them as active users, or as a problem,
is the misread, and the cross platform captures below show a real server with a stack
of them.

Windows and macOS spell that state `TIME_WAIT` with an underscore, and Linux writes it
the same way, so the one place the platforms agree is the state that most often gets
misread.

</details>

## Across platforms

The three questions, what is listening, who is connected, and what are my interfaces
and neighbours, have a tool on every platform. The names and flags change and the
questions do not.

**On Linux**, the socket tool is `ss` and the interface and neighbour tool is `ip`,
both shown in the lab above: `ss -tlnp` for listeners, `ss -tnp` for connections,
`ip -br addr` for interfaces, `ip neigh` for the neighbour table. `netstat` also
works where it is installed.

**On macOS**, `netstat` lists connections with BSD flags, `ifconfig` reads the
interfaces, and `arp` reads the neighbour table.

```bash
# macOS 26.5.2, arm64
$ netstat -an -p tcp | head -12
Active Internet connections (including servers)
Proto Recv-Q Send-Q  Local Address                                 Foreign Address                               (state)    
tcp4       0    206  192.168.64.2.49167     140.82.113.22.443      ESTABLISHED
tcp4     489      0  192.168.64.2.49165     20.209.227.33.443      ESTABLISHED
tcp4       0   1255  192.168.64.2.49164     140.82.113.22.443      ESTABLISHED
tcp4       0      0  192.168.64.2.49163     140.82.113.22.443      ESTABLISHED

# The primary interface in full, the ifconfig the exam names
$ ifconfig en0
en0: flags=8863<UP,BROADCAST,SMART,RUNNING,SIMPLEX,MULTICAST> mtu 1500
	ether 76:d2:10:fc:24:27
	inet 192.168.64.2 netmask 0xffffff00 broadcast 192.168.64.255
	status: active

# The neighbour table, numeric, first entries only
$ arp -an | head -6
? (192.168.64.1) at a6:77:f3:70:92:64 on en0 ifscope [ethernet]
? (192.168.64.255) at ff:ff:ff:ff:ff:ff on en0 ifscope [ethernet]
```

**On Windows**, `netstat` lists sockets and `Get-NetTCPConnection` gives the same in
a form you can filter, `ipconfig` and `Get-NetAdapter` read the interfaces, and `arp`
reads the neighbour table.

```powershell
# Microsoft Windows Server 2025 Datacenter, version 10.0.26100.0
> netstat -ano -p TCP | Select-Object -First 12
Active Connections
  Proto  Local Address          Foreign Address        State           PID
  TCP    0.0.0.0:22             0.0.0.0:0              LISTENING       3920
  TCP    0.0.0.0:80             0.0.0.0:0              LISTENING       4
  TCP    0.0.0.0:135            0.0.0.0:0              LISTENING       1120
  TCP    0.0.0.0:445            0.0.0.0:0              LISTENING       4

# Every connection on the machine, counted by state
> Get-NetTCPConnection | Group-Object State | Format-Table Name, Count -AutoSize
Name        Count
----        -----
Listen         40
Established    39
TimeWait       22
Bound          39

# The interfaces this machine has, with the names the other commands use
> Get-NetAdapter | Format-Table Name, InterfaceDescription, Status, LinkSpeed -AutoSize
Name            InterfaceDescription                            Status LinkSpeed
----            --------------------                            ------ ---------
Ethernet 3      Microsoft Hyper-V Network Adapter #3            Up     50 Gbps
vEthernet (nat) Hyper-V Virtual Ethernet Adapter                Up     10 Gbps

# The neighbour table the exam calls arp
> arp -a
Interface: 10.1.0.103 --- 0xe
  Internet Address      Physical Address      Type
  10.1.0.1              12-34-56-78-9a-bc     dynamic
  10.1.15.255           ff-ff-ff-ff-ff-ff     static
```

The Windows `netstat` shows the same `0.0.0.0` listen address the lab did, meaning
those services answer the network, and the state count from `Get-NetTCPConnection`
shows a real server's twenty-two `TimeWait` connections, which is the busy-but-fine
picture the panel described. The interface names, `Ethernet 3` and `vEthernet (nat)`,
are the ones the other Windows commands expect, which is the point about names: on a
Windows box you aim a command at `Ethernet 3`, not at `eth0`.

## Prove it

The two lab blocks are from
[`sockets.sh`](https://github.com/rlwilliamson-dev/azure-resume/blob/main/blog/scripts/topologies/sockets.sh),
and the cross platform blocks are real Windows and macOS machines through the capture
workflow. The lab is built to show the one field that matters, the listen address, by
running two services that differ only in what they bound to.

**ss(8) and ip(8).** The manuals, and worth reading for the flags: `-l` for
listening, `-t` for TCP, `-n` for numeric, `-p` for the process. The same letters mean
the same things on `netstat`, which is the exam's tool, so learning one teaches the
other.

**RFC 9293.** The current TCP specification, for the state machine a connection moves
through. Read the part on `TIME_WAIT` and note that its whole job is to outlast stray
packets from the closed connection, which is why a busy server has so many and why
that is correct.

## What trips people up

### 1. Reading a listening socket without its address

A port bound to `127.0.0.1` is reachable only from the machine; one bound to `0.0.0.0`
answers the network. The word listening is the same; the exposure is not, and the
address is the field that says which.

### 2. Counting TIME_WAIT as a problem

It is the safety timer after a connection closes, keeping stray packets from being
mistaken for a new connection. A busy server has many, and they are fine.

### 3. Assuming an interface name is universal

Names differ by platform and by tool. A Windows interface is `Ethernet 3`, a macOS one
`en0`, a Linux one something else again, and a command aimed at the wrong name does
nothing quietly.

### 4. Trusting netstat to exist and behave the same everywhere

`netstat` is present on all three platforms with different flags, and on modern Linux it
is the older tool behind `ss`. The exam names `netstat`; the Linux habit is `ss`.

### 5. Reading a neighbour entry as more than it is

A neighbour entry proves layer-two exchange with that address: the wire works. It says
nothing about anything higher, which is exactly why it is useful as a low, specific fact.

### 6. Missing the peer on an established connection

An established connection names both ends. Reading only the local side misses who is
actually connected and from where, which is often the question you had.

## Work it through

The unexpected open port, worked through the tools.

First, list the listening sockets and read the bound address on the one that surprised
you. If it is `127.0.0.1`, the scan that reported it was scanning from the host itself or
is wrong, because nothing on the network can reach a loopback-bound service, and the
incident is closed. If it is `0.0.0.0` or a real interface address, it is genuinely
exposed and worth the next step.

Then find what is behind it, which is the process field the socket tools print with `-p`
or the PID column. A port is a number; the process is the answer to what is listening, and
the two together tell you whether it is a service you run, one somebody added, or one that
should not be there.

Then check who is connected to it, without the listen filter, and read the peers. Expected
clients from expected places are one story; a connection from somewhere that should not be
talking to this service is another, and the established connections are where you see it.

Then, if the question is whether the wire to a neighbour works at all, read the neighbour
table, because an entry there is a lower and more certain fact than a ping: it proves frames
crossed at layer two, which isolates a fault to above that layer. Each tool answers a
narrower question than the last, and running them in that order turns "a port is open" into
a specific sentence.

## Try it

**Run the lab and change what a service binds to.** In
[`sockets.sh`](https://github.com/rlwilliamson-dev/azure-resume/blob/main/blog/scripts/topologies/sockets.sh)
one service binds `0.0.0.0` and one binds `127.0.0.1`. Try to reach each from `h2` and watch
the loopback one refuse while the other answers. That is the listen address made real.

**List your own machine's listening sockets and read every bound address.** On whatever you
are on, `ss -tlnp`, `netstat -ano`, or `netstat -an` will list them. The ones on loopback are
private; the ones on `0.0.0.0` face the network, and you may be surprised which is which.

**Find the interface name your platform uses.** Then aim one command at it and one at the
wrong name, and watch the second do nothing. The silence is the lesson about names.

## Check yourself

<details class="qa">
<summary>A port is listening. What single field tells you whether the network can reach it?</summary>

The bound address. A socket on `0.0.0.0` bound every interface, so it answers the network and
anything that can route to the host can reach it. A socket on `127.0.0.1` bound only loopback,
so it answers only processes on the host itself and nothing on the network can reach it.

Reading "a port is listening" without reading its address is how a harmless loopback service
gets reported as an exposure, and how a genuinely exposed one gets waved through. The word is
the same; the address is the difference.

</details>

<details class="qa">
<summary>A busy server has two hundred connections in TIME_WAIT. Is that a problem?</summary>

No. `TIME_WAIT` is the state a connection sits in for a minute or two after it closes, so that
stray packets from the old connection cannot be mistaken for a new one on the same
address and port. A server that closes a lot of connections has a lot of them, and it is the
protocol working as specified.

It is a routine false alarm to count them as active users or as an attack. They are closed
connections waiting out a safety timer, and they clear on their own.

</details>

<details class="qa">
<summary>Why does the exam name netstat when modern Linux prefers ss?</summary>

Because `netstat` is the tool present on every platform, including Windows and macOS, while
`ss` is Linux-specific and newer. `netstat` on modern Linux is the older tool, often superseded
by `ss`, but it is the one common name across all three systems, so it is the portable answer.

They answer the same questions. `ss -tlnp` and `netstat -tlnp` both list listening TCP sockets
with the process, and the flags happen to line up, so knowing one teaches the other.

</details>

<details class="qa">
<summary>What does a neighbour-table entry prove that a ping does not?</summary>

That frames were exchanged with that address at layer two: the wire between the two machines
works. It is a lower and more specific fact than a ping, which tests a round trip up at layer
three and can fail for reasons that have nothing to do with the link.

That is what makes it useful in isolating a fault. An entry in the neighbour table places the
problem above layer two, because layer two demonstrably worked, which is one of the cleanest
discriminating tests there is.

</details>

## References

- [ss(8)](https://man7.org/linux/man-pages/man8/ss.8.html) - man7.org, the socket statistics tool the labs use and the flags it shares with `netstat`. Free. Accessed 2026-08-19.
- [ip(8)](https://man7.org/linux/man-pages/man8/ip.8.html) - man7.org, the interface and neighbour tool on modern Linux. Free. Accessed 2026-08-19.
- [RFC 9293](https://www.rfc-editor.org/rfc/rfc9293) - IETF, the current TCP specification and the connection state machine, including the job of `TIME_WAIT`. Free. Accessed 2026-08-19.

**Where the numbers came from.** The two lab blocks are from
[`sockets.sh`](https://github.com/rlwilliamson-dev/azure-resume/blob/main/blog/scripts/topologies/sockets.sh)
through `netlab.sh`, on the kernel in each header, with two services bound differently on
purpose so the listen-address distinction is visible. The Windows and macOS blocks are real
machines through the capture workflow, headed with each one's version; the addresses and
connection counts are whatever those runners were doing at capture time, which is why the
`TIME_WAIT` counts are real rather than staged.

**If you also work on Linux.** The lab is the Linux tools already: `ss` for sockets and `ip`
for interfaces and neighbours. Carrying to the other platforms, the one name that exists
everywhere is `netstat`, and the one field that matters everywhere is the listen address, which
`0.0.0.0` and `127.0.0.1` answer the same way on all three.