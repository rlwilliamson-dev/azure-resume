---
title: "What a network actually is"
description: "A cable between two computers does not make a network. What else has to be true, why one machine needs two different addresses, and the arithmetic that decides whether your neighbour is reachable at all."
deck: "Two machines, one cable, and nothing happens"
track: "network-plus"
level: "intro"
order: 20
objectives:
  - "Say what a cable gives you and what it does not"
  - "Tell the difference between a link being up and a network working"
  - "Explain why a machine has both a MAC address and an IP address"
  - "Work out from two addresses whether one machine considers the other local"
  - "Read a neighbour table and say what it proves"
prerequisites: []
tags: ["network-plus", "networking", "beginner"]
updated: 2026-08-10
draft: false
examObjectives:
  - exam: "n10-009"
    domain: "1.0"
    objective: "1.1"
sources:
  - title: "RFC 826, An Ethernet Address Resolution Protocol"
    url: "https://www.rfc-editor.org/rfc/rfc826"
    publisher: "IETF"
    accessed: 2026-08-10
    tier: 1
  - title: "RFC 791, Internet Protocol"
    url: "https://www.rfc-editor.org/rfc/rfc791"
    publisher: "IETF"
    accessed: 2026-08-10
    tier: 1
  - title: "RFC 1918, Address Allocation for Private Internets"
    url: "https://www.rfc-editor.org/rfc/rfc1918"
    publisher: "IETF"
    accessed: 2026-08-10
    tier: 1
  - title: "ip-link(8)"
    url: "https://man7.org/linux/man-pages/man8/ip-link.8.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-10
    tier: 1
  - title: "ip-address(8)"
    url: "https://man7.org/linux/man-pages/man8/ip-address.8.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-10
    tier: 1
  - title: "ip-neighbour(8)"
    url: "https://man7.org/linux/man-pages/man8/ip-neighbour.8.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-10
    tier: 1
symptoms:
  - symptom: "Network is unreachable"
    anchor: "who-counts-as-local"
  - symptom: "Two machines on the same cable cannot reach each other"
    anchor: "who-counts-as-local"
  - symptom: "The link light is on and nothing works"
    anchor: "one-cable-is-not-a-network"
---

> **Before you read.** Take two computers. Run one cable between them. Both ends
> click, both link lights come on, and the operating system on each machine
> agrees the connection is up.
>
> Now try to copy a file from one to the other. It fails.
>
> Nothing is broken and nothing is unplugged. **What is missing?**

The answer is two things, and neither of them is hardware. Once you can name
them, a surprising share of "the network is down" turns into a question with an
obvious answer.

### Some words you will need

<dl class="terms">
<dt>host</dt>
<dd>Any machine on a network. A laptop, a server, a printer, a camera. If it has an address, it is a host.</dd>
<dt>link</dt>
<dd>The connection between two things. A cable, or a radio channel doing the same job.</dd>
<dt>interface</dt>
<dd>The socket on a machine that a link plugs into, and the software that drives it. Also called a NIC.</dd>
<dt>MAC address</dt>
<dd>A number burned into an interface, identifying it on the local link and nowhere else.</dd>
<dt>IP address</dt>
<dd>A number identifying a machine on a network, which can be carried across the world.</dd>
<dt>subnet mask</dt>
<dd>The rule that decides which other addresses count as local. The number in the puzzle above.</dd>
<dt>neighbour table</dt>
<dd>The list a machine keeps of which MAC address goes with which IP address. Sometimes called the ARP cache.</dd>
</dl>

## What breaks without this

**You blame the wrong layer.** The link light is on, so the cable gets ruled out,
and the next four hours go into firewall rules on a machine that was never
reachable in the first place.

**You cannot read what a tool is telling you.** Every diagnostic command in the
rest of this track prints addresses, masks and interface states. If those are
noise to you, the output is noise too.

**Fixes become guesses.** Somebody changes an address, it does not help, so they
change the mask as well, and now two settings are wrong instead of one.

## One cable is not a network

Here are two machines with a cable between them and nothing else configured.

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology two-hosts
# commands run on h1
# is the interface enabled, and is anything on the other end?
$ ip -brief link show
lo               UNKNOWN        00:00:00:00:00:00 <LOOPBACK,UP,LOWER_UP> 
h1eth0@if3       UP             02:00:00:00:01:01 <BROADCAST,MULTICAST,UP,LOWER_UP> 
# and does it have an address to send from?
$ ip -brief addr show
lo               UNKNOWN        127.0.0.1/8 ::1/128 
h1eth0@if3       UP             fe80::ff:fe00:101/64 
```

Read the flags on `h1eth0` first, because they are the part people misread.

**`UP` means somebody enabled the interface.** It is an administrative setting,
like a light switch being in the on position.

**`LOWER_UP` means the driver can see something on the other end.** That is the
cable being plugged into a device that is switched on. The two are independent,
and an interface can sit at `UP` for months with nothing attached.

So this machine has a working cable. Watch what happens anyway.

<details class="predict">
<summary>The cable is good and the interface is up. What does the machine say when you ask it to reach the host at the far end, and how long does it take?</summary>

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology two-hosts
# commands run on h1
$ ping -c 1 -W 2 10.0.0.2
ping: connect: Network is unreachable
$ echo "exit status $?"
exit status 2
```

</details>

It failed instantly. Not a timeout, not a delay, an immediate refusal, and the
wording is exact: `Network is unreachable`. The machine is not telling you the
far end is down. It is telling you it has no idea how to send anything to that
address at all, so it did not try.

Look back at the address output and you can see why. There is a `127.0.0.1`,
which is the loopback every machine has and which never leaves the box, and
there is an `fe80::` address, which the kernel generated for IPv6 on its own.
**There is no IPv4 address on the interface.** A machine with no address on a
link has nothing to send from and no notion of what is at the other end.

Give both ends an address and the same commands behave completely differently.

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology two-hosts
# give each end an address on the same network
$ ip -n h1 addr add 10.0.0.1/24 dev h1eth0
$ ip -n h2 addr add 10.0.0.2/24 dev h2eth0
$ ip netns exec h1 ping -c 2 10.0.0.2
PING 10.0.0.2 (10.0.0.2) 56(84) bytes of data.
64 bytes from 10.0.0.2: icmp_seq=1 ttl=64 time=0.031 ms
64 bytes from 10.0.0.2: icmp_seq=2 ttl=64 time=0.042 ms

--- 10.0.0.2 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1017ms
rtt min/avg/max/mdev = 0.031/0.036/0.042/0.005 ms
# what h1 now knows about its neighbour
$ ip -n h1 neigh show
10.0.0.2 dev h1eth0 lladdr 02:00:00:00:01:02 REACHABLE 
# and the route nobody typed
$ ip -n h1 route
10.0.0.0/24 dev h1eth0 proto kernel scope link src 10.0.0.1 
```

Two commands, and the network works. Three things in that output are worth
sitting with.

The last line is a route, and **nobody typed it.** `proto kernel` is the kernel
saying it made this itself. Assigning an address to an interface tells the
machine, implicitly, that everything in `10.0.0.0/24` can be reached by sending
directly out of that interface. That single automatic rule is what makes local
networking work without anybody configuring anything.

The middle line is the neighbour table, and it now has an entry that was not
there before. The machine learned something during that ping.

And the round trip is 0.031 milliseconds, which is worth noticing only because
you will later see the same measurement in tens of milliseconds and want a sense
of what fast looks like.

<details class="deeper">
<summary>If you already work on networks: what UP and LOWER_UP actually report, and why the loopback lies about both</summary>

`UP` is the `IFF_UP` flag, set when something administratively enables the
interface. `LOWER_UP` reflects `IFF_LOWER_UP`, which the driver sets when the
physical layer reports carrier. On copper Ethernet that is link pulse detected
from a partner. The pair is the fastest hardware triage you have: `UP` without
`LOWER_UP` on a physical port means the cable, the patch panel, the far switch
port, or the far device being off.

The third state worth knowing is `NO-CARRIER`, which appears in the flag list
when an interface is administratively up and the driver explicitly reports no
link partner. It is the same fault as missing `LOWER_UP` and it is easier to
spot, because it is a word rather than an absence.

The `lo` line reports `UNKNOWN` in the state column and it is not a fault. That
column carries the operational state the driver publishes, and interfaces with
no physical layer to have an opinion about frequently publish nothing. Loopback
has no cable, so the honest answer is that the question does not apply. Virtual
interfaces do the same thing, which catches people out when they start reading
the state column on a machine full of tunnels and bridges.

The `@if3` suffix on the interface name is specific to how this capture was
made. These hosts are network namespaces joined by a virtual Ethernet pair, and
the suffix names the interface index at the other end of the pair. On a physical
machine you would see a plain `eth0` or `enp0s31f6`. The behaviour is the same;
the naming is a consequence of the lab.

</details>

## Two names for the same machine

You gave the machine an IP address and it started working. But look at the
neighbour table entry again:

```
10.0.0.2 dev h1eth0 lladdr 02:00:00:00:01:02 REACHABLE
```

There are two identifiers in that line for one machine. `10.0.0.2` is the IP
address you configured. `02:00:00:00:01:02` is the MAC address, which you did
not configure, and which the interface has had since it existed.

Nobody told `h1` what `h2`'s MAC address was. It found out, and you can watch it
happen.

<details class="predict">
<summary>h1 has been given an address and told to reach 10.0.0.2. It does not know the MAC address that belongs to it. How does it find out, and who does it have to ask?</summary>

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology two-hosts
# address both ends, then watch the link while h1 first tries to reach h2
$ ip -n h1 addr add 10.0.0.1/24 dev h1eth0
$ ip -n h2 addr add 10.0.0.2/24 dev h2eth0
$ (ip netns exec h2 timeout 6 tcpdump -i h2eth0 -n -e -c 2 arp > /tmp/arp.txt 2>/dev/null &)
$ sleep 2
$ ip netns exec h1 ping -c 1 -W 2 10.0.0.2 > /dev/null
$ sleep 2
$ cat /tmp/arp.txt
13:08:41.033627 02:00:00:00:01:01 > ff:ff:ff:ff:ff:ff, ethertype ARP (0x0806), length 42: Request who-has 10.0.0.2 tell 10.0.0.1, length 28
13:08:41.033647 02:00:00:00:01:02 > 02:00:00:00:01:01, ethertype ARP (0x0806), length 42: Reply 10.0.0.2 is-at 02:00:00:00:01:02, length 28
```

</details>

Two frames, and they read almost like English.

The first goes to `ff:ff:ff:ff:ff:ff`, which is the broadcast address, meaning
every machine on the local link receives it. The content is a question:
`who-has 10.0.0.2 tell 10.0.0.1`. Roughly, "whoever owns 10.0.0.2, tell
10.0.0.1 about it."

The second is a reply, sent back to one specific MAC rather than broadcast,
because the answering machine now knows who asked. `10.0.0.2 is-at
02:00:00:00:01:02`.

That exchange is the Address Resolution Protocol, and it happens constantly on
every network you have ever used. **Every conversation between two machines on
the same link begins with one machine shouting a question at everybody.**

Twenty microseconds separate those two frames, which is the difference
between the timestamps and is another number worth having a feel for.

<details class="deeper">
<summary>If you already work on networks: why two identifiers instead of one, and what that costs</summary>

The honest answer is that they solve different problems and were designed by
different people for different networks.

A MAC address identifies an interface and is meant to be globally unique and
permanent. It carries no information about where the machine is. That is fine
on one cable segment, where "deliver to this MAC" means "shout it and let the
right interface pick it up", and useless at scale: routing to a flat namespace
of billions of unrelated numbers would mean every router knowing every machine.

An IP address is assigned rather than burned in, and it is structured. The
leading bits say which network, which means a router can hold one entry for a
whole network rather than one per machine. That structure is the entire reason
the internet can be routed at all, and it is also why an IP address changes when
a laptop moves between buildings while its MAC does not.

The cost is that every machine has to keep translating between the two, which is
what the neighbour table is. It is also a security surface. Nothing in the
protocol authenticates a reply, so a machine on your link can answer a question
that was not addressed to it, claim an address it does not own, and quietly
receive traffic meant for somebody else. That is ARP spoofing, it is on this
exam, and the reason it works is visible in the capture above: the reply is
believed because it arrived, not because it was proved.

Worth knowing the vocabulary distinction now, because the exam uses it. IPv6
does not use ARP. It does the same job with Neighbor Discovery, which runs over
ICMPv6, and the `fe80::` address in the very first capture is part of that
machinery.

</details>

## Who counts as local

The addresses in the working example were `10.0.0.1` and `10.0.0.2`, both
written with `/24` on the end. That suffix is the subnet mask, and it decides
which other addresses a machine treats as reachable directly.

Change nothing but the addresses, and the same cable stops working.

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology two-hosts
# same cable, but addresses one number apart in the third position
$ ip -n h1 addr add 192.168.1.10/24 dev h1eth0
$ ip -n h2 addr add 192.168.2.20/24 dev h2eth0
$ ip netns exec h1 ping -c 1 -W 2 192.168.2.20
ping: connect: Network is unreachable
# an empty neighbour table means h1 never even asked who h2 was
$ ip -n h1 neigh show
```

Same cable. Same interfaces. Both ends up, both ends addressed. And the
neighbour table is empty, which is the detail that matters most: **h1 never sent
an ARP request at all.** It did not try to find h2 and fail. It decided in
advance that h2 was not something it could reach directly, and gave up before
putting anything on the wire.

With `/24`, the first three numbers are the network part. `192.168.1` and
`192.168.2` differ in the third, so as far as each machine is concerned the
other is on a different network, somewhere else, reachable only by handing the
packet to a router. There is no router here, so there is nowhere to hand it.

**Being on the same cable is irrelevant. The mask decides who is a neighbour.**

That is worth rereading, because it is the single most useful sentence in this
topic. It produces failures that look exactly like broken hardware and are
arithmetic. The fix here is not a new cable or a new switch; it is changing one
number so that both machines agree they are on the same network.

<details class="deeper">
<summary>If you already work on networks: why networks are packet switched, and what the alternative looked like</summary>

The behaviour above is a consequence of a design decision that predates all of
it, and knowing the alternative makes the design make sense.

The telephone network was circuit switched. Making a call reserved a path
through the network for the duration, end to end, and that path was yours
whether you were talking or not. It gave excellent, predictable quality, and it
wasted almost everything: a conversation is mostly silence, and the silence was
reserved at full cost.

Data networks are packet switched instead. There is no reserved path. Data is
chopped into packets, each one carrying a destination address, and each device
along the way decides independently where to send it next. Two packets in the
same conversation can take different routes and arrive out of order.

That trade is why everything else in this track works the way it does. Nothing
is reserved, so links can be shared and a network can be built far cheaper than
its worst case. Nothing is guaranteed, so packets can be lost, delayed, or
delivered out of order, and something above has to notice and cope, which is
what TCP is for. Every device has to make its own forwarding decision, which is
why every machine needs an address it can be found by and a rule about who is
local. The neighbour table, the automatic route, and the mask arithmetic in this
topic are all machinery serving that one decision.

</details>

## Client and server are jobs, not machines

Worth clearing up early because the words get used as if they described
hardware.

A **server** is a program that waits for connections. A **client** is a program
that starts one. Both are roles, both are software, and a single machine
routinely does both at once: your laptop is a client to a website and a server
to the printer asking it for a job.

The rack-mounted box people call a server is just a computer built for the job,
with more memory and better cooling. It is not a server because of its shape. A
Raspberry Pi running a web server is a server; a large expensive machine running
nothing is not.

The distinction matters on this exam because a fault is often on one side and
not the other, and the first useful question in any connectivity problem is
which side is which.

<details class="deeper">
<summary>If you already work on networks: the service is running, the port is open, and the connection still fails</summary>

A listening program does not simply claim a port. It claims a port on a
particular address, and that second half is where a working service turns into an
unreachable one.

Bind to `127.0.0.1` and the socket is reachable from the machine itself and
nowhere else. The loopback address never leaves the machine, so a connection from
somewhere else cannot arrive on it however permissive the firewall is. Bind to
`0.0.0.0` and the socket takes connections arriving on any address the machine
holds. The IPv6 equivalent of that wildcard is `::`.

The reason to carry this is the shape of the fault it causes. On the server
itself, a request to `localhost` succeeds, and almost everybody reads that as
proof the service is up. From any other machine the connection is refused. Both
observations are correct. The service is running somewhere the network cannot
reach it, and no amount of firewall work will change that.

The bind address is not hidden. It is the left-hand column of the listening
socket table, which the next topic captures: `0.0.0.0:9000` is reachable from the
network and `127.0.0.1:9000` is not. Reading that column before touching a
firewall rule saves an afternoon roughly once a year.

</details>

## Across platforms

The four questions above are the same four questions on any machine. The
commands are not, and objective 5.5 names the Windows ones rather than the Linux
ones, so this is examinable rather than a convenience.

| The question | Linux | Windows | macOS |
| --- | --- | --- | --- |
| Is the interface enabled, and is anything on the other end | `ip -brief link show` | `ipconfig`, then `netsh interface show interface` | `ifconfig` |
| Does it have an address, and what is the mask | `ip -brief addr show` | `ipconfig` | `ifconfig` |
| Has this machine actually spoken to the other one | `ip neigh show` | `arp -a` | `arp -a` |

**The one to watch is `ifconfig`.** It is deprecated on Linux and often not
installed, which is why this track uses `ip`. On macOS it is the current tool and
it answers the first two questions at once. So a Linux habit fails on a Mac and a
Mac habit fails on Linux, in opposite directions, and neither failure is obvious.

The next topic captures all three platforms answering the same question side by
side, and it is worth reading even if you only ever use one of them, because the
exam will use whichever name suits the question.


## Prove it

You have this when you can answer four questions about any two machines, in
order, without guessing.

```bash
# 1. Is the interface enabled, and is anything on the other end?
#    UP is the switch being on. LOWER_UP is the cable being there.
ip -brief link show

# 2. Does it have an address, and what is the mask?
ip -brief addr show

# 3. Given those two addresses, is the other machine local?
#    Do this one in your head. Compare the network parts.

# 4. Has this machine actually spoken to it?
#    An entry means ARP succeeded. An empty table is a diagnosis of its own.
ip neigh show
```

**Step 4 is the one people never run and it settles arguments.** An entry in the
neighbour table is proof that the two machines exchanged frames on the link. An
empty table for an address you are trying to reach means either nothing answered
or, as in the capture above, your machine never asked, and those are different
faults with different causes.

## What trips people up

### 1. Reading a link light as a working network

The light means carrier. It says the cable is intact and the far device is
powered. It says nothing about addresses, masks, routes, or whether the machine
at the other end will talk to you.

### 2. Hearing "Network is unreachable" as "the other machine is down"

It means the opposite of a timeout. The kernel found no way to send the packet
and never sent one, so this is a fault on your machine, in its addressing or its
routes, and not at the far end.

Compare it with `No route to host`, where something answered and refused, and
with a plain timeout, where the packet left and nothing came back. Three
messages, three different places to look.

### 3. Believing the same cable means the same network

Covered above at length because it is the one that wastes the most time. Two
correctly configured machines on one cable will ignore each other completely if
their masks put them on different networks.

### 4. Expecting a MAC address to travel

MAC addresses are local to a link. When a packet crosses a router the MAC
addresses are replaced, because the next link is a different conversation
between different interfaces. The IP addresses survive the journey. This is why
a firewall rule written against a MAC address only works on the same segment.

### 5. Confusing the loopback with the network

`127.0.0.1` is a fake interface every machine has, and traffic to it never
reaches a cable. A service tested successfully on `127.0.0.1` has proved that
the service runs, and nothing whatsoever about whether anybody else can reach
it.

## Work it through

Two machines are on the same switch in the same room. You are told they cannot
reach each other, and that both were working yesterday.

Somebody has already checked the cables and swapped one of them. On each machine
you find this:

```
machine A     address 10.20.1.15    mask 255.255.255.0
machine B     address 10.20.2.15    mask 255.255.255.0
```

Reason it out before reading on.

**Start with what the mask says, because it costs nothing.** A mask of
`255.255.255.0` is the same as `/24`: the first three numbers are the network.
Machine A is on `10.20.1`. Machine B is on `10.20.2`. Those are different
networks, so each machine considers the other remote and will look for a router
rather than putting a frame on the wire.

**Now predict the symptom before you go and look.** If this diagnosis is right,
A will fail to reach B instantly rather than after a wait, and A's neighbour
table will hold no entry for B, because A never asked. If instead you found A
timing out slowly, or an ARP entry present, the diagnosis is wrong and you would
need to think again.

The swapped cable is a red herring because the failure happens before
anything reaches the cable. The kernel compares the destination against its own
network, concludes it is not local, looks for a route, finds none, and returns
an error. No frame is ever transmitted. Any cable would produce this.

**What actually changed yesterday?** Almost certainly one machine's address, not
both. Somebody moved a machine to a different subnet, or a static address was
typed with the wrong third number, or a machine that used to get its address
automatically now has one set by hand. The fix is to put both on the same
network, and the question worth asking afterwards is which of the two addresses
is the wrong one, because that tells you what to correct rather than which to
overwrite.

**The habit worth taking away:** when two machines cannot see each other, read
both addresses and both masks before touching anything physical. It takes ten
seconds and it eliminates the largest single cause.

## Try it

Optional, and none of this needs network hardware.

1. On any machine you have, run the equivalent of `ip -brief link show` and find
   an interface that is `UP`. Check whether it also has `LOWER_UP`.
2. Run `ip -brief addr show` and write down your address and mask. Work out by
   hand which addresses your machine treats as local.
3. Run `ip neigh show` and look at what your machine has recently talked to on
   its own link. Everything in that list is one link away from you.
4. Ping something on your local network, then check the neighbour table again to
   see whether a new entry appeared.
5. If you have a Linux machine or virtual machine, the topology used for the
   captures above is `blog/scripts/topologies/two-hosts.sh` in this site's
   repository. It is fifteen lines. Build it, then repeat the mismatched-mask
   experiment and watch the neighbour table stay empty.

**Verification step.** You have it when you can be handed two addresses with
masks and say, without a calculator and without touching a machine, whether one
can reach the other directly, and what error the failure would produce.

## Check yourself

<details class="qa">
<summary>An interface shows <code>UP</code> but not <code>LOWER_UP</code>. What is wrong, and where would you look?</summary>

The interface is administratively enabled and the driver cannot see anything on
the other end. Nobody has disabled it; there is no carrier.

On a physical machine that is the cable, the patch panel, the far switch port,
or a far device that is powered off. On a virtual machine it is the hypervisor's
network configuration.

What it is not is an addressing problem. Addresses are irrelevant until there is
a link to carry them.

</details>

<details class="qa">
<summary>Why does a machine need both a MAC address and an IP address?</summary>

They answer different questions. The MAC address identifies an interface on the
local link, is burned in, and carries no information about where the machine is.
The IP address is assigned, and it is structured so that the leading part names
a network, which lets a router hold one entry for a whole network instead of one
per machine.

The MAC is how a frame is delivered on this cable. The IP is how a packet is
routed across the world. Machines translate between the two constantly, and the
neighbour table is where they keep the results.

</details>

<details class="qa">
<summary><code>ping</code> returns <code>Network is unreachable</code> immediately. What does that rule out?</summary>

It rules out the far end entirely, and it rules out the path.

The message means the kernel could not work out how to send the packet, so it
never sent one. The fault is local: no address, the wrong mask, or no route to
that destination. Nothing left the machine, so nothing about the cable, the
switch, or the far host is implicated.

Contrast it with a timeout, where the packet was sent and nothing came back,
which points outward instead.

</details>

<details class="qa">
<summary>Two machines on one switch, <code>192.168.1.10/24</code> and <code>192.168.2.20/24</code>. Can they communicate, and what does the neighbour table show?</summary>

No. With `/24` the first three numbers are the network part, so `192.168.1` and
`192.168.2` are different networks. Each machine treats the other as remote and
looks for a router, and there is none.

The neighbour table stays empty for that address. That is the diagnostic detail:
the machine did not try and fail to find its neighbour, it never asked, because
it had already decided the destination was not local.

Sharing a switch changes nothing. The mask decides who is a neighbour, not the
wiring.

</details>

<details class="qa">
<summary>What does an entry in the neighbour table actually prove?</summary>

That the two machines exchanged frames on the same link. One asked who owned an
address, the other answered, and both are therefore present, powered, and on the
same network as far as addressing is concerned.

It proves nothing above that. A service on the far machine can still be stopped,
firewalled, or listening on the wrong address. It is a floor, not a certificate.

</details>

<details class="qa">
<summary>Somebody says "the server is down" and you find you can reach it fine from your laptop. What is the first distinction to draw?</summary>

Server and client are roles rather than machines, so "the server is down" could
mean the machine is off, or that one program on it has stopped accepting
connections, and those need different fixes.

Being able to reach it yourself narrows it further. Your path works and theirs
does not, so the difference is on their side, in the path between them, or in
which address they are actually using.

</details>

## References

- [RFC 826, An Ethernet Address Resolution Protocol](https://www.rfc-editor.org/rfc/rfc826) - IETF. Accessed 2026-08-10.
- [RFC 791, Internet Protocol](https://www.rfc-editor.org/rfc/rfc791) - IETF. Accessed 2026-08-10.
- [RFC 1918, Address Allocation for Private Internets](https://www.rfc-editor.org/rfc/rfc1918) - IETF. Accessed 2026-08-10.
- [ip-link(8)](https://man7.org/linux/man-pages/man8/ip-link.8.html) - Linux man-pages project. Accessed 2026-08-10.
- [ip-address(8)](https://man7.org/linux/man-pages/man8/ip-address.8.html) - Linux man-pages project. Accessed 2026-08-10.
- [ip-neighbour(8)](https://man7.org/linux/man-pages/man8/ip-neighbour.8.html) - Linux man-pages project. Accessed 2026-08-10.

**Where the output came from.** Every block on this page that shows output was
captured, not written. The one under **Prove it** shows none: it is a command
list to be typed, with no provenance header, and it is the only block here that
is not a transcript. They come from two Linux network namespaces joined by a virtual
Ethernet pair, on the kernel named in each block's header, using the topology
committed at `blog/scripts/topologies/two-hosts.sh`. MAC addresses are fixed in
that topology so the transcripts can be reproduced and checked rather than taken
on trust. The `@if3` suffix on the interface name is an artefact of how
namespaces are joined and would not appear on a physical machine.

**If you also work on Linux.** The Linux+ track reaches the same idea from the
other direction in [Addresses, masks, and who counts as a neighbour](/learn/linux-plus/network-basics-addresses-and-routes), starting from the four things a host needs before
it can talk to anything. It goes further into distribution differences and into
making a configuration survive a reboot, neither of which this exam asks about.
Nothing on this page depends on reading it.
