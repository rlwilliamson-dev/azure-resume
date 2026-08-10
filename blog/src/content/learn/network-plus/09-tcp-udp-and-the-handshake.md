---
title: "One protocol asks. The other just sends"
description: "TCP sets up a connection, numbers everything, and resends what goes missing. UDP does none of that on purpose. The handshake packet by packet, what retransmission actually costs, the state that lingers after a close, and why a video call chooses the protocol that gives up."
track: "network-plus"
level: "intro"
order: 100
objectives:
  - "Say what connection-oriented and connectionless mean in terms of packets on a wire"
  - "Read a three-way handshake in a packet capture and name each flag"
  - "Explain how sequence numbers and acknowledgements detect a loss"
  - "Describe what a connection close looks like and why a socket lingers afterwards"
  - "Choose between TCP and UDP for a given application and defend the choice"
prerequisites: ["macs-ips-and-ports"]
tags: ["network-plus", "networking", "tcp", "udp"]
updated: 2026-08-10
draft: false
examObjectives:
  - exam: "n10-009"
    domain: "1.0"
    objective: "1.4"
sources:
  - title: "RFC 9293, Transmission Control Protocol"
    url: "https://www.rfc-editor.org/rfc/rfc9293"
    publisher: "IETF"
    accessed: 2026-08-10
    tier: 1
  - title: "RFC 768, User Datagram Protocol"
    url: "https://www.rfc-editor.org/rfc/rfc768"
    publisher: "IETF"
    accessed: 2026-08-10
    tier: 1
  - title: "RFC 7323, TCP Extensions for High Performance"
    url: "https://www.rfc-editor.org/rfc/rfc7323"
    publisher: "IETF"
    accessed: 2026-08-10
    tier: 1
  - title: "RFC 2018, TCP Selective Acknowledgment Options"
    url: "https://www.rfc-editor.org/rfc/rfc2018"
    publisher: "IETF"
    accessed: 2026-08-10
    tier: 1
  - title: "RFC 6298, Computing TCP's Retransmission Timer"
    url: "https://www.rfc-editor.org/rfc/rfc6298"
    publisher: "IETF"
    accessed: 2026-08-10
    tier: 1
  - title: "ss(8)"
    url: "https://man7.org/linux/man-pages/man8/ss.8.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-10
    tier: 1
  - title: "tcpdump(1)"
    url: "https://www.tcpdump.org/manpages/tcpdump.1.html"
    publisher: "tcpdump.org"
    accessed: 2026-08-10
    tier: 1
symptoms:
  - symptom: "Connection refused immediately, with no timeout"
    anchor: "the-three-way-handshake"
  - symptom: "A transfer is slow but nothing is reporting errors"
    anchor: "when-something-goes-missing"
  - symptom: "Address already in use when restarting a service"
    anchor: "closing-down-and-the-state-that-lingers"
---

> **Before you read.** A file copy and a video call both cross the same network.
> The copy uses a protocol that notices when something goes missing and sends it
> again. The call uses one that does not, and never finds out.
>
> The call is not making do with the worse protocol. It picked the one it wanted.
>
> **Why would anybody deliberately choose the protocol that gives up?**

Topic 02 introduced ports and showed a connection being opened without saying
what opening one involves. This topic is that mechanism: what the two transport
protocols actually do, what reliability costs, and why the expensive option is
sometimes the wrong one.

### Some words you will need

<dl class="terms">
<dt>segment</dt>
<dd>The unit TCP sends. A datagram is the equivalent for UDP.</dd>
<dt>flag</dt>
<dd>A single bit in the TCP header. SYN, ACK, FIN and RST are the four you need.</dd>
<dt>sequence number</dt>
<dd>A counter naming the position of the data in a segment within the whole stream.</dd>
<dt>acknowledgement</dt>
<dd>A receiver saying which byte it expects next, which implicitly confirms everything before it.</dd>
<dt>retransmission</dt>
<dd>Sending a segment again because no acknowledgement arrived in time.</dd>
<dt>window</dt>
<dd>How much data a sender may have outstanding before it has to wait for an acknowledgement.</dd>
</dl>

## What breaks without this

**A slow transfer looks like a mystery.** Nothing errors, nothing logs, and the
copy takes twenty minutes. Without knowing what retransmission looks like, there
is nothing to measure and the answer becomes "the network is slow".

**Connection refused gets treated as a firewall problem.** It is the opposite: a
refusal is an answer, and an answer means the packet arrived. Reading it as a
block sends the investigation in exactly the wrong direction.

**You cannot say why a service uses the port it uses.** The next topic is a list
of protocols and their ports, and half of them specify TCP or UDP for reasons
that only make sense once this material does.

## Two ways to send something

TCP is connection-oriented. Before any data moves, the two ends exchange packets
to agree that they are talking, and from then on the protocol tracks what was
sent, what arrived, and what has to go again. The application hands over a stream
of bytes and gets the same bytes out of the other end, in order, or it gets an
error.

UDP is connectionless. There is no setup. A datagram is addressed and sent, and
the protocol's involvement ends there. Nothing is numbered, nothing is
acknowledged, nothing is retried, and the sender is not told whether it arrived.

The framing to avoid is reliable against unreliable, because it makes UDP sound
like a broken version of TCP. The accurate framing is about who deals with loss.
TCP deals with it, at a cost in delay and state. UDP hands the problem to the
application, which sometimes has a better answer than resending would be.

| | TCP | UDP |
| --- | --- | --- |
| Setup before data | Three packets | None |
| Delivery checked | Yes, with retransmission | No |
| Order preserved | Yes | No |
| Header size | 20 bytes minimum | 8 bytes |
| State held per conversation | Yes, both ends | None |
| A lost packet means | A delay | Nothing, unless the application notices |

<details class="deeper">
<summary>If you already work on networks: the reliability the exam describes and the reliability applications actually get</summary>

TCP guarantees less than the word reliable suggests, and the gap matters when
something goes wrong.

What it guarantees is that bytes handed to it arrive in order, without gaps or
duplicates, or that the connection fails and the application is told. That is a
strong guarantee and it is entirely about the transport. It says nothing about
whether the far application read the bytes, processed them, or did what they
asked. A write that TCP acknowledged has reached the receiving kernel's buffer,
not the receiving program's logic, and a server that crashes between those two
points has accepted data it never acted on.

Which is why every protocol that needs to know something was done sends its own
confirmation. SMTP has reply codes, HTTP has status codes, and database protocols
have commit acknowledgements. Those exist on top of a protocol that already
promises delivery, because delivery and completion are different claims.

The second gap is timing. TCP will keep a connection alive and keep retrying for
a long time, so a network that has failed does not produce an immediate error. An
application that needs to fail fast has to impose its own timeout, and the number
of outages made worse by a client patiently waiting for a TCP connection that was
never coming back is not small.

The exam answer is that TCP is reliable and UDP is not. Hold that, and hold the
more precise version underneath it.

</details>

## The three-way handshake

Opening a TCP connection takes three packets, and every one of them is visible.

<details class="predict">
<summary>One machine connects to another, sends six bytes, and disconnects. How many packets does that take, and which of them carry data?</summary>

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology one-router
# a listener on h2, and a capture running on h1 before anything connects
$ (ip netns exec h2 nc -l -p 8080 > /dev/null 2>&1 &)
$ (ip netns exec h1 timeout 9 tcpdump -i h1eth0 -n tcp > /tmp/tcp.txt 2>/dev/null &)
$ sleep 2
$ ip netns exec h1 sh -c "echo hello | nc -w 2 10.0.2.2 8080" > /dev/null 2>&1
$ sleep 9
$ cat /tmp/tcp.txt
20:20:46.346860 IP 10.0.1.2.57244 > 10.0.2.2.8080: Flags [S], seq 2547666588, win 64240, options [mss 1460,sackOK,TS val 3723456496 ecr 0,nop,wscale 8], length 0
20:20:46.346916 IP 10.0.2.2.8080 > 10.0.1.2.57244: Flags [S.], seq 3031872331, ack 2547666589, win 65160, options [mss 1460,sackOK,TS val 2399148578 ecr 3723456496,nop,wscale 8], length 0
20:20:46.346931 IP 10.0.1.2.57244 > 10.0.2.2.8080: Flags [.], ack 1, win 251, options [nop,nop,TS val 3723456496 ecr 2399148578], length 0
20:20:46.347024 IP 10.0.1.2.57244 > 10.0.2.2.8080: Flags [P.], seq 1:7, ack 1, win 251, options [nop,nop,TS val 3723456496 ecr 2399148578], length 6: HTTP
20:20:46.347099 IP 10.0.2.2.8080 > 10.0.1.2.57244: Flags [.], ack 7, win 255, options [nop,nop,TS val 2399148578 ecr 3723456496], length 0
20:20:48.350728 IP 10.0.1.2.57244 > 10.0.2.2.8080: Flags [F.], seq 7, ack 1, win 251, options [nop,nop,TS val 3723458500 ecr 2399148578], length 0
20:20:48.350909 IP 10.0.2.2.8080 > 10.0.1.2.57244: Flags [F.], seq 1, ack 8, win 255, options [nop,nop,TS val 2399150582 ecr 3723458500], length 0
20:20:48.350929 IP 10.0.1.2.57244 > 10.0.2.2.8080: Flags [.], ack 2, win 251, options [nop,nop,TS val 3723458500 ecr 2399150582], length 0
```

</details>

Eight packets for six bytes of data, and only one of them carries any.

The first three are the handshake, and the flags name each step.

**`Flags [S]`, the SYN.** The client says it wants a connection and states the
sequence number it will start counting from, here 2547666588. That number is
chosen at random rather than starting at zero, which matters for a reason covered
below.

**`Flags [S.]`, the SYN-ACK.** The dot is how tcpdump prints an ACK flag, so this
packet has both bits set. The server agrees, states its own starting sequence
number, and acknowledges the client's with `ack 2547666589`. That is the client's
number plus one, because the SYN itself counts as one byte of the stream even
though it carries no data.

**`Flags [.]`, the ACK.** The client acknowledges the server's number, and the
connection is open. Notice that tcpdump has switched to relative numbering from
here on, printing `ack 1` rather than the full value, which is what makes the
rest of the exchange readable.

Then the data, one segment with `Flags [P.]` and `length 6`, and the server's
acknowledgement of it. The last three packets are the close, covered further
down.

Three packets before a byte of data moves, which is the cost of the arrangement.
On a link with a round trip of 100 milliseconds, that is a tenth of a second
spent agreeing to talk.

The handshake also explains a failure everybody has seen.

<details class="predict">
<summary>The same connection attempt, to a port where nothing is listening. What comes back, and how quickly?</summary>

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology one-router
# nothing is listening on 9999
$ (ip netns exec h1 tcpdump -i h1eth0 -n -c 2 tcp > /tmp/rst.txt 2>/dev/null &)
$ sleep 2
$ ip netns exec h1 nc -w 2 10.0.2.2 9999
$ echo "exit status $?"
exit status 1
$ sleep 2
$ cat /tmp/rst.txt
20:17:25.195038 IP 10.0.1.2.38428 > 10.0.2.2.9999: Flags [S], seq 3489944708, win 64240, options [mss 1460,sackOK,TS val 1808667717 ecr 0,nop,wscale 8], length 0
20:17:25.195077 IP 10.0.2.2.9999 > 10.0.1.2.38428: Flags [R.], seq 0, ack 3489944709, win 0, length 0
```

</details>

One SYN out, and `Flags [R.]` straight back. R is the reset flag, and it is the
machine saying there is nothing here, immediately, in the same millisecond.

**A reset is an answer, and that is the useful part.** Something received the SYN,
processed it, and replied, which proves the packet reached the host and the return
path works. A firewall dropping traffic produces silence and a timeout instead.
So connection refused and connection timed out are different diagnoses:
refused means the host is there and the service is not, timed out means something
in between is discarding traffic.

<details class="deeper">
<summary>If you already work on networks: what the handshake negotiates besides agreeing to talk</summary>

Look again at the options field on the first two packets, because the handshake
is also where the two ends settle how the connection will behave. Everything in
`options [mss 1460,sackOK,TS val ...,nop,wscale 8]` is being agreed once, here,
and cannot be changed later.

**`mss 1460`** is the maximum segment size, the largest amount of data this end
will accept in one segment. It comes from the interface MTU of 1500 minus 20
bytes of IP header and 20 of TCP header. Each end states its own, and each end
respects the other's. When the MTU topic later in this track explains why a path
with a smaller MTU causes trouble, this is the number that was agreed before
anybody knew about it.

**`wscale 8`** is window scaling. The window field in the TCP header is 16 bits,
so it tops out at 65535 bytes, which was generous in 1981 and is not now. The
option says to multiply every window this end advertises later by 2 to the power
8, which is 256. The scaling does not apply to the SYN itself, which is why the
first packets say `win 64240` and the ones after the handshake say `win 251`. A
window of 251 looks absurd until you multiply it back up to 64256. Without this
option a fast long-distance link cannot be filled, however much bandwidth it
has.

**`sackOK`** offers selective acknowledgement. Without it, a receiver can only say
"I have everything up to byte N", so one lost segment in the middle of a burst
forces everything after it to be resent. With it, the receiver can say which
specific ranges arrived, and the sender resends only the hole.

**`TS val`** is a timestamp, used to measure the round trip time accurately and to
detect sequence numbers that have wrapped around on a very fast connection.

All of it is negotiated in the first two packets and none of it is renegotiated.
If one end does not offer an option, the connection runs without it for its whole
life, which is why a middlebox that strips TCP options can cause a connection to
be slow rather than broken, and why that is such an unpleasant thing to diagnose.

</details>

## When something goes missing

Sequence numbers are what make loss detectable. Every byte in the stream has a
position, each segment says where its data sits, and each acknowledgement says
which byte the receiver wants next. A sender that has sent up to byte 4000 and
been acknowledged only to byte 1449 knows precisely what is missing.

If an acknowledgement does not arrive within the retransmission timeout, the
segment goes again. That is the whole reliability mechanism, and it is cheap to
describe and expensive to run.

You can watch it cost. Here half of everything leaving one host is discarded
deliberately, and then the kernel is asked what the connection is doing.

<details class="predict">
<summary>A 2 MB transfer across a link dropping half its packets. What does the connection look like six seconds in?</summary>

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology one-router
# drop half of everything leaving h1, then push data through and ask the kernel what it cost
$ ip netns exec h1 tc qdisc add dev h1eth0 root netem loss 50%
$ (ip netns exec h2 nc -l -p 8080 > /dev/null 2>&1 &)
$ sleep 1
$ (ip netns exec h1 sh -c "head -c 2000000 /dev/zero | tr '\0' 'x' | nc -w 20 10.0.2.2 8080" > /dev/null 2>&1 &)
$ sleep 6
$ ip netns exec h1 ss -tin dst 10.0.2.2
State Recv-Q Send-Q Local Address:Port  Peer Address:Port
ESTAB 0      53952       10.0.1.2:45424     10.0.2.2:8080
	 cubic wscale:8,8 rto:5852 backoff:1 rtt:698.262/556.776 mss:1448 pmtu:1500 rcvmss:536 advmss:1448 cwnd:1 ssthresh:11 bytes_sent:25072 bytes_retrans:7240 bytes_acked:11585 segs_out:20 segs_in:6 data_segs_out:18 send 16590bps lastsnd:2023 lastrcv:4965 lastack:4964 pacing_rate 132712bps delivery_rate 2574222216bps delivered:11 busy:4964ms unacked:5 retrans:1/5 lost:3 sacked:2 rcv_space:14480 rcv_ssthresh:64088 notsent:47704 minrtt:0.005 snd_wnd:86784 rcv_wnd:64256 rehash:2
```

</details>

Every number in that output is worth reading, because together they are the whole
of TCP's response to a bad network.

`bytes_sent:25072` against `bytes_retrans:7240` says nearly a third of everything
put on the wire was a second attempt. `retrans:1/5` is one retransmission in
flight and five so far, and `lost:3` is the count it currently believes missing.

`cwnd:1` is the one to notice. The congestion window is how many segments the
sender will allow in flight before waiting, and it has collapsed to a single
segment. TCP reads loss as congestion, so its response to packets going missing
is to slow down, and with a window of one it sends a segment and waits for the
acknowledgement before sending the next.

`rto:5852` is the retransmission timeout in milliseconds, stretched to almost six
seconds by repeated failure. `backoff:1` is the doubling that produced it.

And `Send-Q 53952` with `notsent:47704` is the application's view: it wrote 2 MB,
TCP accepted what it could buffer, and 47 kB of that is sitting in the kernel
waiting for a network that will not take it. The program has no idea. From inside
the application this is a write that has not returned yet.

That is what a slow transfer with no errors actually is. Nothing failed, nothing
logged, and the throughput collapsed by design because the protocol interpreted
loss the way it was built to.

<details class="deeper">
<summary>If you already work on networks: the two separate windows, and which one is limiting you</summary>

There are two limits on how much data can be in flight and they come from
opposite ends of the connection. Telling them apart is the difference between a
useful diagnosis and guesswork.

**The receive window is flow control.** It is advertised by the receiver in every
segment, and it means "I have this much buffer space left". It exists so a fast
sender cannot overwhelm a slow receiver, and it has nothing to do with the
network in between. In the capture above, `rcv_wnd:64256` and `snd_wnd:86784` are
the two ends telling each other how much room they have.

**The congestion window is congestion control.** It is not advertised anywhere and
does not appear in any packet. It is a number the sender keeps for itself,
estimating how much the network between here and there will carry. It grows while
things are going well and collapses when they are not, which is `cwnd:1` above.

A sender may have in flight the smaller of the two, so the interesting question
when a transfer is slow is which one is the binding constraint. A small receive
window points at the far machine: it is not reading fast enough, or its buffer is
misconfigured. A small congestion window points at the path: loss somewhere is
being interpreted as congestion.

`ssthresh:11` in the capture is the boundary between the two phases of growth.
TCP increases the congestion window rapidly until it reaches that threshold, then
increases it cautiously, one segment per round trip. After a loss the threshold
is lowered, which is why a connection that has hit trouble stays slow for a while
after the trouble has passed.

The wireless case is where this design shows its age. TCP assumes loss means
congestion, and on a radio link loss frequently means interference, so the
protocol slows down in response to a condition that slowing down does not fix.
Topic 03's panel on layering made the same point from the other direction, and
this is what it looks like in the numbers.

</details>

## Closing down, and the state that lingers

Closing takes four packets in principle and often three on the wire, because a
close is really two independent shutdowns.

Look at the last three packets of the handshake capture. The client sends
`Flags [F.]`, a FIN with an ACK, meaning it has no more data. The server replies
with its own `Flags [F.]`, and the client acknowledges. Each direction is closed
separately, which is why a connection can be half closed with one side still
sending.

The socket does not disappear when the last packet is sent.

<details class="predict">
<summary>A short connection is made and finishes cleanly. What does the client's socket table show immediately afterwards?</summary>

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology one-router
$ (ip netns exec h2 nc -l -p 8080 > /dev/null 2>&1 &)
$ sleep 2
$ ip netns exec h2 ss -tan
State  Recv-Q Send-Q Local Address:Port Peer Address:Port
LISTEN 0      1            0.0.0.0:8080      0.0.0.0:*   
$ ip netns exec h1 sh -c "echo hello | nc -w 1 10.0.2.2 8080" > /dev/null 2>&1
$ ip netns exec h1 ss -tan
State     Recv-Q Send-Q Local Address:Port  Peer Address:Port
TIME-WAIT 0      0           10.0.1.2:34700     10.0.2.2:8080
```

</details>

The server shows a socket in `LISTEN`, which is the waiting state a service sits
in. After the connection has closed, the client shows `TIME-WAIT`, and that entry
will sit there for a couple of minutes with no traffic flowing at all.

<details class="deeper">
<summary>If you already work on networks: what TIME_WAIT is protecting against, and the error it causes</summary>

TIME_WAIT looks like a leak and it is a guarantee.

The end that closes first holds the socket for twice the maximum segment
lifetime, which on Linux works out at about a minute. Two things need that
window. A delayed duplicate of an old segment could still be wandering the
network, and if the same four-tuple were reused immediately, that stray segment
would arrive inside a new connection and be accepted as valid data. And the final
acknowledgement can be lost, in which case the other end resends its FIN, and
something has to be there to answer it.

The visible cost is on servers. A machine closing thousands of connections a
second accumulates thousands of TIME_WAIT entries, each holding a port. The
common consequence is the error that greets you when restarting a service too
quickly: the listening socket cannot be recreated because the address is still
considered in use.

The correct fix for that specific case is the `SO_REUSEADDR` socket option, which
lets a listening socket bind to an address that has connections in TIME_WAIT.
Most server software sets it, which is why most services restart cleanly and the
ones that do not stand out.

The fix to be careful with is shortening the timeout or reusing sockets
aggressively. There are kernel settings for it, the internet is full of
recommendations to change them, and they exist to trade a correctness guarantee
for a resource. Sometimes that trade is right. It is worth knowing that it is a
trade rather than a tidy-up.

One detail with a practical consequence: TIME_WAIT belongs to whichever end
closed first. Design a protocol where the server closes and the server
accumulates the state. Design it so the client closes and the state is spread
across thousands of machines that each have one.

</details>

## UDP, and why anyone would choose it

Now the question at the top.

UDP does none of the above. Eight bytes of header holding source port,
destination port, length and checksum, and then the data. No handshake, no
sequence numbers, no acknowledgements, no state at either end.

Which means it can fail silently, and it is worth seeing that rather than being
told it.

<details class="predict">
<summary>A UDP datagram sent to a port where nothing is listening. What comes back, and what does the sending program see?</summary>

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology one-router
# the same message over UDP, with nothing listening at the far end
$ sleep 3
$ (ip netns exec h1 timeout 8 tcpdump -i h1eth0 -n udp or icmp > /tmp/udp.txt 2>/dev/null &)
$ sleep 2
$ ip netns exec h1 sh -c "echo hello | nc -u -w 2 10.0.2.2 9999"
$ echo "exit status $?"
exit status 0
$ sleep 7
$ cat /tmp/udp.txt
20:21:02.826553 IP 10.0.1.2.35144 > 10.0.2.2.9999: UDP, length 6
20:21:02.826590 IP 10.0.2.2 > 10.0.1.2: ICMP 10.0.2.2 udp port 9999 unreachable, length 42
```

</details>

Two packets. The datagram goes out, and an ICMP port unreachable comes back
saying nothing is listening there.

Then look at the exit status. **Zero.** The sending program was told it succeeded.

The ICMP message arrived, and it arrived after `nc` had already handed its
datagram to the kernel and moved on. There is no connection for the error to be
attached to and no call still waiting for a result, so nothing reports it. A
UDP sender finds out about failure only if the application it is part of asks a
question and notices that no answer came.

That is the property, not a defect, and it is why the video call chooses it. A
lost frame of video is worth nothing by the time TCP could have resent it. The
call would rather show a glitch and stay in the present than pause and stay
correct. DNS makes the same trade differently: a query and an answer fit in one
datagram each, so a lost query is cheaper to ask again than a connection would
have been to set up.

| Uses UDP | Why |
| --- | --- |
| DNS lookups | One small question, one small answer. Setting up a connection costs more than retrying |
| Voice and video | Late data is worthless. A glitch now beats correct audio a second late |
| DHCP | The client has no address yet, so there is nothing to build a connection from |
| SNMP, syslog | High volume, individually unimportant, and the sender must not be slowed by the receiver |
| Game state updates | Superseded by the next update almost immediately |

<details class="deeper">
<summary>If you already work on networks: what applications build on top of UDP, and why they did not just use TCP</summary>

The interesting cases are the ones that need reliability and chose UDP anyway,
then implemented their own. That sounds perverse until you look at what they
gained.

Streaming and conferencing protocols want to control the trade themselves. An
application that knows a lost packet was audio can conceal the gap and carry on,
and one that knows it was a keyframe can ask for that specific frame again. TCP
offers one policy, resend everything in order, and applies it whether or not
resending helps.

The one that had the largest effect is head of line blocking. TCP delivers bytes
in order, so a single lost segment stalls everything behind it even if that data
arrived perfectly and is sitting in the receiver's buffer. For a web page pulling
a hundred objects down one connection, one loss stalls all hundred. QUIC, which
carries most HTTP/3 traffic, is built on UDP specifically to escape that:
independent streams inside one connection, so a loss on one does not hold up the
others, with reliability and encryption implemented above UDP rather than below.

There is a second reason, less discussed and probably more important. TCP is
implemented in operating system kernels, so changing it means waiting years for
machines to be updated, and middleboxes on the path have opinions about TCP that
break anything unfamiliar. A protocol built on UDP lives in the application and
ships when the application ships. QUIC could deploy in a browser release.

So the modern picture is not TCP for important things and UDP for disposable
ones. It is TCP when its policy is the one you want, and UDP when you want to
write the policy yourself. That is a change from how the split is usually taught
and the exam still teaches the older version, which is the one to answer with.

</details>

## Across platforms

This topic uses `ss` throughout, because that is what the capture environment
ships. Objective 5.5 names `netstat` and does not name `ss`, so the tool you
will be asked about is the one this page has not been using, and the state names
are spelled differently in three places.

| Task | Linux | Windows | macOS |
| --- | --- | --- | --- |
| Every TCP connection | `ss -tan` | `netstat -ano -p TCP` | `netstat -an -p tcp` |
| Per-connection counters | `ss -ti` | `Get-NetTCPConnection` | `netstat -s -p tcp` for totals |
| Owning process | `ss -tanp` | `netstat -ano`, then match the PID | `lsof -i` |

```powershell
# Microsoft Windows Server 2025 Datacenter, version 10.0.26100.0
> netstat -ano -p TCP | Select-Object -First 12
Active Connections
  Proto  Local Address          Foreign Address        State           PID
  TCP    0.0.0.0:22             0.0.0.0:0              LISTENING       3096
  TCP    0.0.0.0:80             0.0.0.0:0              LISTENING       4
  TCP    0.0.0.0:135            0.0.0.0:0              LISTENING       1092
  TCP    0.0.0.0:445            0.0.0.0:0              LISTENING       4
  TCP    0.0.0.0:1801           0.0.0.0:0              LISTENING       4184
  TCP    0.0.0.0:2103           0.0.0.0:0              LISTENING       4184
  TCP    0.0.0.0:2105           0.0.0.0:0              LISTENING       4184
  TCP    0.0.0.0:2107           0.0.0.0:0              LISTENING       4184

# Windows writes the lingering close state with an underscore. Linux uses a dash
> netstat -ano -p TCP | Select-String "TIME_WAIT" | Select-Object -First 3
  TCP    10.1.0.124:50792       168.63.129.16:80       TIME_WAIT       0

# Every connection on the machine, counted by state
> Get-NetTCPConnection | Group-Object State | Format-Table Name, Count -AutoSize
Name        Count
----        -----
Listen         40
Established    18
TimeWait        1
Bound          19
```

Three things there. Windows writes the waiting-to-accept state as `LISTENING`
where `ss` writes `LISTEN`. It writes the lingering close state as `TIME_WAIT`
with an underscore, where `ss` writes `TIME-WAIT` with a hyphen. And
`Get-NetTCPConnection` writes the same state a third way, as `TimeWait`. Anyone
who has ever grepped for the wrong one of those has spent longer on it than they
would like to admit.

The `-ano` flags are worth learning as a unit: addresses numeric, all
connections, and the owning process id. The PID column is the equivalent of the
`users:` field `ss -tlnp` prints, except that Windows gives you a number and
leaves looking up the process to you.

macOS is BSD, so the flags differ again.

```bash
# macOS 26.5.2, arm64
$ netstat -an -p tcp | head -12
Active Internet connections (including servers)
Proto Recv-Q Send-Q  Local Address                                 Foreign Address                               (state)    
tcp4       0      0  192.168.64.3.49160     140.82.113.21.443      ESTABLISHED
tcp4       0      0  192.168.64.3.49159     57.150.86.161.443      ESTABLISHED
tcp4       0      0  192.168.64.3.49158     140.82.113.21.443      ESTABLISHED
tcp4       0      0  192.168.64.3.49157     140.82.113.21.443      ESTABLISHED
tcp4       0      0  192.168.64.3.49156     140.82.113.21.443      ESTABLISHED
tcp4       0      0  192.168.64.3.49155     20.85.130.105.443      ESTABLISHED
tcp4       0      0  192.168.64.3.49154     20.85.130.105.443      ESTABLISHED
tcp4       0      0  192.168.64.3.49153     20.85.130.105.443      ESTABLISHED
tcp4       0      0  192.168.64.3.49152     20.75.202.224.443      ESTABLISHED
tcp4       0      0  *.22                   *.*                    LISTEN     

# The lingering close state, spelled with an underscore here as on Windows
$ netstat -an -p tcp | grep TIME_WAIT | head -3
tcp4       0      0  192.168.64.3.51876     151.101.3.6.443        TIME_WAIT  
tcp4       0      0  192.168.64.3.51857     17.248.228.19.443      TIME_WAIT  
tcp4       0      0  192.168.64.3.51852     17.132.112.129.443     TIME_WAIT  
```

`-p tcp` here means the protocol, where on Windows `-p TCP` means the same thing
and on Linux `-p` means processes. Same letter, three meanings, and a Linux habit
produces an error rather than the wrong output, which is at least a fast failure.

The states themselves are identical because they come from the protocol rather
than from the operating system. `ESTABLISHED`, `LISTEN` and `TIME_WAIT` mean
exactly what they mean on the other two.


## Prove it

You have this when you can produce a handshake and read it, on any machine with
tcpdump.

```bash
# 1. Watch a real interface, not "any". Pick one from ip -brief link show.
sudo tcpdump -i <interface> -n "tcp port 443 and tcp[tcpflags] & tcp-syn != 0"

# 2. In another window, open a connection.
curl -s https://example.com > /dev/null

# 3. Then count what the socket table holds afterwards.
ss -tan state time-wait | head
```

Three things to confirm. The first packet has `Flags [S]` and the second has
`Flags [S.]`, so you have seen both halves of the agreement. The options on those
two packets include an `mss` and probably a `wscale`, which is the negotiation
from the panel above. And the socket table has a `TIME-WAIT` entry afterwards
that you did not have before.

If step 1 shows nothing, the usual cause is watching the wrong interface. On a
laptop with wifi and ethernet, traffic leaves one of them.

## What trips people up

### 1. Reading connection refused as a firewall block

It is the opposite. A refusal is a reset packet, which means the host received
the SYN and answered. A firewall dropping traffic gives you silence and a
timeout. Refused says the service is not running, timed out says something is
discarding packets on the way.

### 2. Thinking the handshake carries data

The three packets set up the connection and carry no application data. In the
capture the six bytes go in a fourth packet. TCP Fast Open changes this in some
circumstances and it is not what the exam is asking about.

### 3. Believing UDP tells you when delivery fails

The capture above ends with an exit status of zero on a datagram that provoked an
ICMP port unreachable. The error came back and the sending program never saw it.
Anything that needs to know has to ask and notice the silence.

### 4. Trusting the protocol label in a capture

The handshake block shows `length 6: HTTP` on a segment carrying the six bytes
`hello`. There is no HTTP anywhere in it. tcpdump guesses the application from the
port number, port 8080 is in its list, and the guess is wrong. The port is a
convention, not a declaration, and the next topic is about exactly that.

### 5. Treating TIME_WAIT as a leak

A socket sitting in TIME_WAIT with no traffic is doing its job. It is holding the
four-tuple so that a late duplicate cannot be mistaken for new data. It clears on
its own.

### 6. Expecting a lost packet to produce an error

TCP handles loss by resending, so the visible effect is slowness rather than
failure. A transfer that has retransmitted a third of its bytes reports nothing
at all to the application, which is why `ss -ti` is worth knowing.

## Work it through

A team reports that uploads to their file server take twenty minutes for a file
that downloads in one. Nothing errors. The server logs are clean, the switches
report no errors, and a ping to the server is fast and loses nothing.

Start with what the symptom rules out. Traffic is arriving, because the upload
completes. There is no error anywhere, which points away from anything that would
reject or drop a connection outright. And the asymmetry is the clue that matters:
the same path in the other direction is fine, so the cable, the link speed and
the routing are all doing their job.

Ping being clean is worth being careful with. A ping is a handful of small
packets with gaps between them, and a link that loses packets under load will
often pass them perfectly when idle. So a clean ping does not rule out loss, it
only rules out loss at that traffic level.

The measurement to make is on the connection itself, while it is slow. `ss -ti`
during an upload gives you the two numbers that decide it. If `bytes_retrans` is
a meaningful fraction of `bytes_sent` and `cwnd` is small, the path is losing
packets under load and TCP is doing what it should. If retransmission is near zero
but the receive window is small, the server is not reading fast enough and the
problem is on the machine rather than in the network.

Both look identical from outside and they lead to completely different next
steps: one is a duplex mismatch, a failing cable or a saturated uplink, the other
is a busy or misconfigured server. The point of this topic is that you can tell
which without guessing.

## Try it

**Watch a handshake on your own machine.** Run the commands from **Prove it**
against any website. Reading a real one takes about a minute and it makes the
flags stop being letters.

**Break a connection deliberately.** If you have a spare Linux machine or a
container, add packet loss with `tc qdisc add dev <interface> root netem loss
20%`, run a transfer, and watch `ss -ti` while it happens. Remove it afterwards
with `tc qdisc del dev <interface> root`. Seeing the congestion window collapse in
real time explains more than any diagram of it.

**Find the TIME_WAIT entries on a busy machine.** `ss -tan state time-wait | wc
-l` on a web server or your own laptop after some browsing. The number is usually
larger than people expect, and knowing it is normal is the point.

## Check yourself

<details class="qa">
<summary>A connection attempt returns "connection refused" instantly. What does that tell you about the path, and what is the fault?</summary>

The path is fine in both directions. A refusal is a TCP reset sent back by the
host, so your SYN arrived, was processed, and the reply reached you.

The fault is that nothing is listening on that port. The service is stopped,
crashed, listening on a different port, or bound to an address that does not
include the one you connected to.

Contrast that with a timeout, which means no answer came at all, and points at
something dropping traffic rather than at the service.

</details>

<details class="qa">
<summary>Why does the SYN-ACK acknowledge the client's sequence number plus one, when the SYN carried no data?</summary>

Because the SYN flag itself consumes one sequence number.

An acknowledgement means "I have everything up to and including this point, send
me the next thing", so acknowledging the client's initial number plus one
confirms the SYN was received. The FIN flag works the same way at the other end
of the connection.

If it did not consume a number, there would be no way to acknowledge the SYN
distinctly from acknowledging nothing.

</details>

<details class="qa">
<summary>A transfer is slow and ss -ti shows cwnd:2 and bytes_retrans about a quarter of bytes_sent. What is happening?</summary>

The path is losing packets and TCP is reacting to it.

Retransmission at a quarter of the bytes sent means a substantial fraction of
segments are not arriving. The congestion window of 2 is TCP's response: it reads
loss as congestion and reduces how much it will have in flight, so throughput
collapses even though nothing has failed.

The next question is where the loss is. A saturated link, a duplex mismatch, a
failing cable or a wireless problem all produce this signature, and the
troubleshooting topics later in the track separate them.

Notice what is not happening: nothing is erroring and nothing is being logged.

</details>

<details class="qa">
<summary>DNS uses UDP for ordinary lookups. Given that a lost query gets no answer at all, why is that the right choice?</summary>

Because the cost of the alternative is higher than the cost of the failure.

A lookup is one small question and one small answer. Over TCP, the handshake
alone is three packets before the question is asked, so the connection setup
costs more than the query. Retrying a lost UDP query costs one packet.

The application handles the loss: a resolver that gets no answer within its
timeout asks again, often of a different server, which is a better response than
retransmitting to a server that may be down.

DNS does use TCP when a response is too large for a datagram, and for zone
transfers, so the choice is per situation rather than fixed.

</details>

<details class="qa">
<summary>Why does a socket sit in TIME_WAIT for minutes after both ends have finished, and which end holds it?</summary>

The end that closed first holds it, for twice the maximum segment lifetime.

Two reasons. A delayed duplicate from the old connection could still be in the
network, and reusing the same four-tuple immediately would let it be accepted as
data in the new one. And the final acknowledgement might be lost, in which case
the other end retransmits its FIN and something has to be present to answer.

The practical consequence is a service that will not restart because the address
is still in use, and the correct fix for that is the `SO_REUSEADDR` option rather
than shortening the timeout.

</details>

<details class="qa">
<summary>A packet capture labels a segment as HTTP, but the payload is six bytes of the word hello. Is the capture wrong?</summary>

The capture is accurate and the label is a guess.

tcpdump infers the application protocol from the port number, and port 8080 is
conventionally HTTP, so it labels the segment that way without inspecting the
bytes. The six bytes are not HTTP.

The general lesson is that a port number is a convention that makes services
findable, and nothing enforces what actually runs there. Anything reading a
capture, including you, has to keep those separate.

</details>

## References

- [RFC 9293, Transmission Control Protocol](https://www.rfc-editor.org/rfc/rfc9293) - IETF, the current TCP specification. Accessed 2026-08-10.
- [RFC 768, User Datagram Protocol](https://www.rfc-editor.org/rfc/rfc768) - IETF, three pages long and worth reading in full. Accessed 2026-08-10.
- [RFC 7323, TCP Extensions for High Performance](https://www.rfc-editor.org/rfc/rfc7323) - IETF, window scaling and timestamps. Accessed 2026-08-10.
- [RFC 2018, TCP Selective Acknowledgment Options](https://www.rfc-editor.org/rfc/rfc2018) - IETF, the `sackOK` in the handshake. Accessed 2026-08-10.
- [RFC 6298, Computing TCP's Retransmission Timer](https://www.rfc-editor.org/rfc/rfc6298) - IETF, where the `rto` value comes from. Accessed 2026-08-10.
- [ss(8)](https://man7.org/linux/man-pages/man8/ss.8.html) - Linux man-pages project, on the counters in the loss capture. Accessed 2026-08-10.
- [tcpdump(1)](https://www.tcpdump.org/manpages/tcpdump.1.html) - tcpdump.org. Accessed 2026-08-10.

**Where the output came from.** All five captured blocks were produced on the
one-router namespace topology, `blog/scripts/topologies/one-router.sh`, through
`blog/scripts/netlab.sh`, so every connection shown genuinely crossed a router.
The loss block uses `tc netem` to discard half the packets leaving one host,
which is a deliberately extreme setting chosen to make the counters move within a
few seconds; a real network losing half its packets would be an emergency rather
than a slow transfer. The block under **Prove it** is a command list rather than
a transcript, with no output and no provenance header, and is there to be typed.

**If you also work on Linux.** [Addresses, masks, and who counts as a
neighbour](/learn/linux-plus/16-network-basics-addresses-and-routes) on the
Linux+ track covers ports, TCP and UDP from the point of view of finding out what
is listening on a machine you administer. The handshake mechanics and the
congestion behaviour here are specific to this exam.
