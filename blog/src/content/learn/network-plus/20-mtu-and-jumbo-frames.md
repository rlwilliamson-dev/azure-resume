---
title: "MTU and jumbo frames"
description: "Small requests work and large ones hang forever. What the MTU is, what fragmentation costs, how path MTU discovery is supposed to find the answer, and why blocking one kind of ICMP turns a working network into one that fails only for big packets."
deck: "Small requests work. Large ones hang forever"
track: "network-plus"
level: "working"
order: 210
objectives:
  - "Say what the MTU is and what it does and does not include"
  - "Explain what happens to a packet larger than the MTU of the next link"
  - "Describe path MTU discovery and what it depends on"
  - "Recognise an MTU black hole from its symptoms"
  - "Say where jumbo frames help and what has to agree for them to work"
prerequisites: ["tcp-udp-and-the-handshake"]
tags: ["network-plus", "networking", "troubleshooting"]
updated: 2026-08-10
draft: false
examObjectives:
  - exam: "n10-009"
    domain: "2.0"
    objective: "2.2"
sources:
  - title: "RFC 1191, Path MTU Discovery"
    url: "https://www.rfc-editor.org/rfc/rfc1191"
    publisher: "IETF"
    accessed: 2026-08-10
    tier: 1
  - title: "RFC 4821, Packetization Layer Path MTU Discovery"
    url: "https://www.rfc-editor.org/rfc/rfc4821"
    publisher: "IETF"
    accessed: 2026-08-10
    tier: 1
  - title: "RFC 791, Internet Protocol"
    url: "https://www.rfc-editor.org/rfc/rfc791"
    publisher: "IETF"
    accessed: 2026-08-10
    tier: 1
symptoms:
  - symptom: "Small requests succeed and large transfers hang"
    anchor: "the-black-hole"
  - symptom: "A website loads its text and never finishes"
    anchor: "the-black-hole"
---

> **Before you read.** A user can ping a server, log in, and run small queries.
> Anything that returns a large result hangs and eventually times out. A web
> page loads its layout and never finishes.
>
> Nothing reports an error. The link is up, there is no packet loss on a ping,
> and both machines are healthy.
>
> **What kind of fault works for small things and fails for large ones?**

Almost every fault in this track is all or nothing. This one is size dependent,
which makes it the hardest thing on the syllabus to diagnose by instinct, and it
comes up constantly the moment anyone builds a tunnel.

### Some words you will need

<dl class="terms">
<dt>MTU</dt>
<dd>Maximum transmission unit. The largest payload a link will carry in one frame, 1500 bytes on ordinary Ethernet.</dd>
<dt>fragmentation</dt>
<dd>Splitting one packet into several so each fits, and reassembling at the destination.</dd>
<dt>DF bit</dt>
<dd>Don't fragment. A flag in the IP header telling routers to drop the packet rather than split it.</dd>
<dt>path MTU</dt>
<dd>The smallest MTU on the whole route, which is what actually limits you.</dd>
<dt>jumbo frame</dt>
<dd>A frame carrying more than 1500 bytes, typically 9000, on links configured for it.</dd>
<dt>MSS</dt>
<dd>Maximum segment size. The largest amount of data TCP will put in one segment.</dd>
</dl>

## What breaks without this

**A fault that no tool reports.** Ping works, the link is up, the counters are
clean, and large transfers die. Every ordinary check passes.

**Every tunnel you build.** A VPN, a VXLAN overlay, anything encapsulated takes
bytes from the same budget, and the symptom appears days later on one application.

**Storage over the network runs at a fraction of its speed.** Jumbo frames are
worth real money in that case and worth nothing anywhere else, and knowing which
is which stops a pointless project.

## The size limit, and what it counts

The MTU is the largest IP packet a link will carry. Ethernet's is 1500 bytes, and
that counts the IP header and everything above it, not the Ethernet header.

So the arithmetic for a ping is: 1500 minus 20 bytes of IP header minus 8 bytes of
ICMP header leaves 1472 bytes of payload. That is a number worth memorising
because it makes the boundary testable.

<details class="predict">
<summary>1472 bytes of payload is exactly the MTU. What happens at 1473, and what happens when the far end's MTU is smaller than yours?</summary>

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology one-switch
# every interface here carries the Ethernet default
$ ip -n h1 link show h1eth0 | grep -o "mtu [0-9]*"
mtu 1500
# 1472 bytes of payload plus 20 IP and 8 ICMP is exactly 1500
$ ip netns exec h1 ping -c 1 -M do -s 1472 10.0.0.2 | tail -2
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 0.080/0.080/0.080/0.000 ms
# one byte more, with fragmentation forbidden
$ ip netns exec h1 ping -c 1 -M do -s 1473 10.0.0.2 2>&1 | head -3
PING 10.0.0.2 (10.0.0.2) 1473(1501) bytes of data.
ping: sendmsg: Message too long

# now shrink the far end and leave this one alone
$ ip -n h2 link set h2eth0 mtu 1400
$ ip netns exec h1 ping -c 2 -W 1 -M do -s 1472 10.0.0.2 | tail -3
--- 10.0.0.2 ping statistics ---
2 packets transmitted, 0 received, 100% packet loss, time 1015ms

# small packets across the same mismatch are fine, which is the confusing part
$ ip netns exec h1 ping -c 1 -W 1 -M do -s 100 10.0.0.2 | tail -2
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 0.057/0.057/0.057/0.000 ms
```

</details>

Four results, and the last two are the topic.

**1472 works.** Exactly 1500 bytes on the wire.

**1473 fails immediately** with `Message too long`, and notice that it never left
the machine. The `-M do` flag sets the don't fragment bit, the packet is bigger
than the local interface allows, so the kernel refuses it rather than sending it.
That is a local error, not a network one.

**Then the far end is shrunk to 1400 and 1472 stops working.** 100 percent loss.
The sending machine still has a 1500 byte interface, so it happily sends a 1500
byte packet, and the receiving interface cannot accept it. Nothing on the sender
reports anything: it sent, and nothing came back.

**And a 100 byte ping across the same broken path works perfectly.** That is the
whole diagnostic signature in one line. The path is not down. The path has a size
limit somebody violated.

## Fragmentation, and why it stopped being the answer

Splitting a packet that does not fit was the original design. A router with a
packet too large for the next link could cut it into fragments, each with its own
IP header, and the destination reassembles them.

It works and it is now mostly avoided, for reasons worth knowing.

Reassembly happens only at the destination, so every fragment must arrive. Lose
one and the whole original packet is lost, which turns one dropped fragment into
a retransmission of everything. It costs the destination memory and time holding
fragments while it waits. Firewalls and load balancers have to reassemble to see
the ports, since only the first fragment carries the TCP header, and many simply
drop fragments instead.

**IPv6 removed router fragmentation entirely.** A router that meets a packet too
large drops it and reports back, and only the sender may fragment. That was a
deliberate decision to force the sender to find the right size instead.

Which is what the DF bit does in IPv4, and it is set on essentially all modern
TCP traffic. So the normal case today is that packets are not fragmented, they
are refused, and something is expected to notice.

<details class="deeper">
<summary>If you already work on networks: how path MTU discovery is supposed to work, and the single dependency that breaks it</summary>

Path MTU discovery is the mechanism that finds the smallest MTU along a route
without anybody configuring anything, and it is elegant right up until one
firewall rule.

The sender sets the don't fragment bit on everything. A router that cannot pass a
packet drops it and sends back an ICMP message, type 3 code 4, "fragmentation
needed and DF set", which helpfully includes the MTU it could have accepted. The
sender caches that figure for the destination and resends smaller. Repeat if
there is a smaller link further along.

The entire mechanism depends on that ICMP message arriving.

And ICMP is the protocol people block. Somebody decides ICMP is a security risk,
writes a rule dropping it at the firewall, and path MTU discovery stops working
silently. The sender transmits a packet that is too large, it is dropped
somewhere in the middle, the message explaining why never arrives, and the sender
retransmits the same oversized packet forever.

That is the black hole. It is not a bug in anything, it is a rule somebody wrote
interacting with a mechanism they did not know depended on it.

RFC 4821 exists because of exactly this. It defines a discovery method that does
not rely on ICMP at all, working instead by probing with progressively larger
packets and watching what gets acknowledged. It is slower and more complex, and
it works through a firewall that eats ICMP, which is why it exists.

The operational rule that comes out of all this: do not block ICMP wholesale.
Blocking echo request, so the network cannot be pinged, is a defensible if
overrated decision. Blocking type 3 code 4 breaks large transfers across your
network in a way nobody will diagnose for weeks.

</details>

## The black hole

The capture above is a black hole in miniature, and the reason it deserves a name
is the shape of the symptom.

A path with a size limit that nobody reports produces this: small things work,
large things fail, and every diagnostic tool says the network is fine. Ping works
because a ping is small. DNS works because a query is small. Logging in works
because credentials are small. The connection establishes, because a handshake is
three small packets.

Then the first full-sized segment goes out and disappears, and the application
sits there retransmitting it.

That is why a web page loads its layout and never finishes. The HTML request is
small, the response headers are small, and the body arrives in full-sized
segments that never make it. The page renders what it has and hangs.

Three places this comes from, in order of how often you will meet them.

**A tunnel.** A VPN wraps every packet in another header, so the usable payload
inside the tunnel is smaller than 1500. If nothing tells the sender that, it
keeps sending 1500.

**A mismatch on one link**, as in the capture, usually somebody setting jumbo
frames on part of a path.

**A firewall eating ICMP**, which does not create the size limit but removes the
mechanism that would have coped with it.

<details class="deeper">
<summary>If you already work on networks: MSS clamping, which is the fix that actually gets deployed</summary>

The clean fix for a tunnel is to make path MTU discovery work, and the practical
fix used everywhere is to not need it.

TCP negotiates a maximum segment size in the handshake, which topic 09 showed as
`mss 1460` in the options of the first two packets. Each end states the largest
segment it will accept, derived from its own interface MTU.

Neither end knows about the tunnel in the middle. Both advertise 1460, both send
1460 byte segments, and those become 1500 byte packets that do not fit through
the tunnel.

MSS clamping is a router or firewall on the path rewriting that number as the
handshake goes past. The tunnel endpoint knows its own overhead, so it rewrites
the advertised MSS down to something that fits, and both ends then send segments
small enough to pass. Neither end knows it happened.

Three things worth knowing about it.

It is a middlebox rewriting a field in somebody else's connection setup, which is
exactly the layering violation topic 03's panel described, and it is deployed on
essentially every VPN concentrator in existence because it works.

It only helps TCP. UDP has no handshake and nothing to clamp, so applications
carrying large UDP payloads over a tunnel still need their own answer, and this
is a recurring problem for DNS responses and for some VPN protocols carried inside
other tunnels.

And it explains a diagnostic result that otherwise makes no sense: a path where
TCP works fine and a large ping with DF set fails. Clamping fixed TCP and did
nothing for ICMP, so the ping is telling you the truth about the path while the
applications are fine.

</details>

## Jumbo frames

A jumbo frame carries more than 1500 bytes, typically 9000, and the case for it
is straightforward arithmetic. Every frame costs headers and per-packet
processing, so moving a fixed amount of data in six times fewer frames means six
times less of that overhead.

Where that matters is where the traffic is large, sustained and predictable:
storage networks, backup traffic, virtual machine migration, anything moving
files between two machines that exist to move files.

Where it does not matter is the ordinary office network. Web traffic is mostly
small requests and responses, and a 9000 byte MTU does nothing for a workload
that never fills a 1500 byte frame.

**Every device on the path has to agree.** That is the real cost, and it is why
jumbo frames belong on a dedicated storage network rather than a general one. One
switch left at 1500 in the middle of a path configured for 9000 gives you the
black hole above, and it will be found by whichever application first sends a
large packet, weeks later.

The other detail worth knowing: 9000 is a convention rather than a standard. IEEE
802.3 does not define jumbo frames at all, so support and maximum sizes are a
vendor matter, and two devices that both claim jumbo support may not agree on the
number.

## Prove it

You have this when you can find a path's MTU from one end.

```bash
# find where it breaks. 1472 is the largest that fits a 1500 byte path
ping -c 1 -M do -s 1472 <destination>
ping -c 1 -M do -s 1473 <destination>

# and on Windows, where the flag is different
ping -f -l 1472 <destination>
```

Work down until it succeeds and you have the path MTU, plus 28 for the headers.
A local `Message too long` means your own interface is the limit. A timeout means
something further along is dropping it and not telling you, which is the black
hole.

Compare that with an ordinary small ping to the same destination. If small works
and large times out, you have proved a size-dependent fault in under a minute,
which is the entire value of knowing this.

## What trips people up

### 1. Expecting an MTU problem to look like an outage

It never does. Small packets pass, so ping, DNS and logins all work, and only
large transfers fail. Every ordinary check says the network is healthy.

### 2. Forgetting the 28 bytes

The MTU counts the IP header. A 1500 byte path carries 1472 bytes of ping payload,
because 20 bytes of IP and 8 of ICMP come out of the same budget.

### 3. Blocking ICMP and then wondering why large transfers fail

Path MTU discovery works by a router sending back a "fragmentation needed"
message. Drop that and the sender never learns, so it retransmits the oversized
packet indefinitely.

### 4. Setting jumbo frames on some of a path

Every device in the path has to agree. One switch at 1500 in the middle turns a
9000 byte path into a black hole that only appears when something sends a large
packet.

### 5. Treating 9000 as a standard

It is a widely used convention. IEEE 802.3 does not define jumbo frames, so the
maximum is a vendor question and two devices claiming support may disagree.

### 6. Enabling jumbo frames on an office network

The benefit comes from moving large sustained volumes in fewer frames. A network
of small web requests never fills a 1500 byte frame, so there is nothing to save.

## Work it through

A company moves its file server behind a site-to-site VPN. Users can browse the
share, open small documents, and see every folder. Opening anything over about a
megabyte hangs, and copying a large file never completes. The VPN is up and small
transfers are fast.

The size dependence names the fault before anything else is checked. Browsing a
share and opening a small document are small exchanges. Copying a large file is
full-sized segments back to back. A fault that distinguishes between them is
about size, and the only thing that is about size is the MTU.

The VPN is the reason. Every packet is wrapped in another header to cross the
tunnel, so the usable payload inside is smaller than 1500. Neither the client nor
the server knows that. Both negotiated an MSS from their own 1500 byte
interfaces, both send full-sized segments, and those do not fit.

Path MTU discovery is supposed to handle this, and the question is why it did
not. Either the tunnel endpoint is not sending the message that says the packet
was too big, or something between the endpoints is dropping the ICMP that carries
it. Both are common and the second is more common, because somebody blocked ICMP
years ago for security reasons.

The test takes a minute. Ping across the tunnel with DF set at 1472 and work
down. Where it starts succeeding is the real path MTU, and the gap between that
and 1500 is the tunnel's overhead.

The fix in practice is MSS clamping on the tunnel endpoint, because it works
without depending on ICMP surviving a path you may not control. Lowering the MTU
on every client is the alternative and it means touching every machine. Unblocking
the ICMP is the correct fix and is often somebody else's firewall.

One thing to note for the report: nothing was broken. The VPN worked exactly as
configured, and the fault was created by adding overhead to a path whose endpoints
were never told.

## Try it

**Find your own path MTU.** Ping something on the internet with DF set, starting
at 1472 and working down. On most connections it will succeed at 1472. On a
connection using PPPoE it usually will not, and the number you find will be 1492
minus the headers, which is the classic case.

**Reproduce the black hole.** Use the topology from this page's capture, set one
end to 1400, and confirm that small pings work while large ones fail. It takes
about thirty seconds and it is the fault you will meet in the field.

**Look for MSS in a real handshake.** Capture any TCP connection and read the
options on the first two packets, as topic 09 did. The `mss` value tells you what
each end thinks it can accept, and on a connection through a tunnel with clamping
it will be lower than 1460.

## Check yourself

<details class="qa">
<summary>Why does a ping of 1472 bytes fit a 1500 byte MTU exactly?</summary>

Because the MTU counts the IP header and everything above it.

The IP header is 20 bytes and the ICMP header is 8, so 1472 bytes of payload plus
28 bytes of headers is exactly 1500.

One byte more, with the don't fragment bit set, is refused. If the interface
sending it is the limit, that refusal is local and immediate rather than a network
error.

</details>

<details class="qa">
<summary>An application works for small requests and hangs on large responses. Ping succeeds and no errors are logged. What is this?</summary>

An MTU black hole.

Something on the path cannot carry a full-sized packet, and the message that
would have said so is not getting back to the sender. So the sender keeps
retransmitting a packet that will never fit.

Small things work because they fit. Ping works because it is small, the TCP
handshake works because those packets are small, and the failure begins with the
first full-sized segment.

The test is a ping with the don't fragment bit set, working down in size until it
succeeds.

</details>

<details class="qa">
<summary>Why does blocking ICMP break large transfers?</summary>

Because path MTU discovery is built on ICMP.

A router that cannot forward a packet because it is too large and has the don't
fragment bit set drops it and sends back an ICMP message saying fragmentation was
needed, including the MTU it could accept. The sender uses that to resize.

Blocking ICMP removes the message. The packet still gets dropped, the sender
never learns why, and it retransmits the same oversized packet indefinitely.

Blocking echo request is a defensible choice. Blocking the fragmentation needed
message breaks transfers in a way nobody diagnoses quickly.

</details>

<details class="qa">
<summary>What is MSS clamping and why is it used instead of fixing path MTU discovery?</summary>

A device on the path rewriting the maximum segment size that the two ends
advertise during the TCP handshake, so both send segments small enough to fit
through a tunnel neither of them knows about.

It is used because it works without depending on ICMP surviving a path you may
not control, and it needs no change on any client.

Two limits. It is a middlebox rewriting a field inside somebody else's connection
setup, which is a layering violation deployed everywhere because it is effective.
And it only helps TCP, since UDP has no handshake to clamp.

</details>

<details class="qa">
<summary>Where do jumbo frames help, and what has to be true?</summary>

Where traffic is large, sustained and predictable: storage networks, backups,
virtual machine migration. Moving the same data in fewer, larger frames cuts
per-frame overhead.

Every device on the path has to agree on the larger size. One device left at 1500
in the middle creates a black hole that appears the first time something sends a
large packet, which may be weeks later.

They do nothing for an office network of small web requests, because that traffic
never fills a 1500 byte frame in the first place.

</details>

<details class="qa">
<summary>Why did IPv6 remove fragmentation by routers?</summary>

Because reassembly only happens at the destination, so fragmentation costs the
destination memory and turns one lost fragment into a lost packet, and it forces
middleboxes to reassemble before they can see the ports.

In IPv6 a router that meets a packet too large drops it and reports back, and
only the sender may fragment. That forces the sender to find the correct size
rather than letting the network paper over it.

It is the same behaviour IPv4 gets when the don't fragment bit is set, which is
now the normal case for TCP traffic.

</details>

## References

- [RFC 1191, Path MTU Discovery](https://www.rfc-editor.org/rfc/rfc1191) - IETF, the mechanism and the ICMP message it depends on. Accessed 2026-08-10.
- [RFC 4821, Packetization Layer Path MTU Discovery](https://www.rfc-editor.org/rfc/rfc4821) - IETF, the method that exists because the first one gets blocked. Accessed 2026-08-10.
- [RFC 791, Internet Protocol](https://www.rfc-editor.org/rfc/rfc791) - IETF, for the don't fragment bit and fragmentation itself. Accessed 2026-08-10.

**Where the output came from.** The captured block was produced on
`blog/scripts/topologies/one-switch.sh` through `blog/scripts/netlab.sh`. The
mismatch is real: one interface is set to 1400 and the other left at 1500, and
the resulting failure is the kernel's rather than an illustration. What the lab
cannot reproduce is the ICMP-blocked version, because that needs a firewall in the
middle of a path, so the black hole here is a two-host version of the same
arithmetic.

**If you also work on Linux.** [Configuring networking](/learn/linux-plus/configuring-networking)
on the Linux+ track covers setting an interface MTU and making it persist, which
is the administration half of this page.
