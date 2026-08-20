---
title: "What happens when you open a web page"
description: "One capture of one page load, from the first frame to the last, with every step named and tied to its layer. Nine things happen in twelve milliseconds and any one of them failing produces the same sentence from the user."
deck: "You type a name and press enter. Roughly nine things happen"
track: "network-plus"
level: "intro"
order: 460
objectives:
  - "List the steps of a page load in order"
  - "Name the layer each step belongs to"
  - "Say what the user sees when each individual step fails"
  - "Explain why a client asks for A and AAAA records at the same time"
  - "Read a packet capture of a page load and find each step in it"
prerequisites: ["how-dns-resolution-works"]
tags: ["network-plus", "networking", "fundamentals"]
updated: 2026-08-12
draft: false
examObjectives:
  - exam: "n10-009"
    domain: "1.0"
    objective: "1.1"
  - exam: "n10-009"
    domain: "1.0"
    objective: "1.4"
sources:
  - title: "RFC 9293, Transmission Control Protocol"
    url: "https://www.rfc-editor.org/rfc/rfc9293"
    publisher: "IETF"
    accessed: 2026-08-12
    tier: 1
  - title: "RFC 8446, The Transport Layer Security Protocol Version 1.3"
    url: "https://www.rfc-editor.org/rfc/rfc8446"
    publisher: "IETF"
    accessed: 2026-08-12
    tier: 1
  - title: "RFC 8305, Happy Eyeballs Version 2"
    url: "https://www.rfc-editor.org/rfc/rfc8305"
    publisher: "IETF"
    accessed: 2026-08-12
    tier: 1
  - title: "RFC 9110, HTTP Semantics"
    url: "https://www.rfc-editor.org/rfc/rfc9110"
    publisher: "IETF"
    accessed: 2026-08-12
    tier: 1
symptoms:
  - symptom: "A page will not load and nobody can say which part failed"
    anchor: "nine-steps-in-twelve-milliseconds"
  - symptom: "One site fails and everything else works"
    anchor: "nine-steps-in-twelve-milliseconds"
  - symptom: "A site is slow to start and fast once it starts"
    anchor: "why-both-address-families-at-once"
---

> **Before you read.** Somebody types a name, presses enter, and gets an error
> page. They tell you the website is down.
>
> The website is not down. Something between the keyboard and the server did not
> work, and there are about nine candidates.
>
> **Which nine, and what would each one look like from the chair?**

This is the topic that ties the rest of the track together. Everything on this
page has appeared somewhere else: addressing, layer 2 resolution, the handshake,
names, encryption. Here they run in order, once, in twelve milliseconds, and the
useful skill is being able to say which one broke from the symptom alone.

### Some words you will need

<dl class="terms">
<dt>stub resolver</dt>
<dd>The part of your machine that turns a name into an address.</dd>
<dt>ARP</dt>
<dd>Finding the layer 2 address of something on your own segment.</dd>
<dt>three-way handshake</dt>
<dd>The SYN, SYN-ACK and ACK that open a TCP connection.</dd>
<dt>TLS handshake</dt>
<dd>Agreeing keys and checking the server's certificate before anything is sent.</dd>
<dt>round trip</dt>
<dd>One message out and its answer back. The unit almost everything here is counted in.</dd>
</dl>

## What breaks without this

**A user reports one sentence.** "The website is down." That sentence maps to nine
different faults with nine different owners.

**The wrong thing gets investigated.** Somebody looks at the web server for an
hour when the fault was a resolver, and the evidence to tell them apart was
available in the first thirty seconds.

**A slow page is treated as a fast page's problem.** Latency at the start of a
load and latency during it come from completely different places.

## Nine steps in twelve milliseconds

Here is the whole thing, in order, with the layer each step belongs to and what
the person at the keyboard sees if that step is the one that failed.

<figure class="learn-figure">
<svg viewBox="0 0 720 344" role="img" aria-labelledby="pageload-title" style="width:100%;height:auto;">
<title id="pageload-title">The nine steps of loading one page in order, each with the layer it belongs to, the elapsed time it happened at, and what the user sees if that step is the one that fails</title>
<g fill="currentColor">
<text x="14" y="22" font-size="11">one sentence from the user, nine places it can have gone wrong</text>
<text x="20" y="48" font-size="9.5" fill-opacity="0.7">at</text>
<text x="86" y="48" font-size="9.5" fill-opacity="0.7">layer</text>
<text x="150" y="48" font-size="9.5" fill-opacity="0.7">step</text>
<text x="404" y="48" font-size="9.5" fill-opacity="0.7">if this is the one that failed</text>
<rect x="14" y="66" width="692" height="26" rx="2" fill="currentColor" fill-opacity="0.06" stroke="currentColor" stroke-opacity="0.3"/>
<text x="20" y="83" font-size="9.5" fill-opacity="0.75">0.000</text>
<text x="92" y="83" font-size="10.5" fill="var(--accent)">2</text>
<text x="150" y="83" font-size="10.5">find the resolver at layer 2</text>
<text x="404" y="83" font-size="9.5" fill-opacity="0.8">nothing at all, instantly</text>
<rect x="14" y="96" width="692" height="26" rx="2" fill="currentColor" fill-opacity="0.06" stroke="currentColor" stroke-opacity="0.3"/>
<text x="20" y="113" font-size="9.5" fill-opacity="0.75">0.000</text>
<text x="92" y="113" font-size="10.5" fill="var(--accent)">7</text>
<text x="150" y="113" font-size="10.5">ask for A and AAAA</text>
<text x="404" y="113" font-size="9.5" fill-opacity="0.8">name not resolved</text>
<rect x="14" y="126" width="692" height="26" rx="2" fill="currentColor" fill-opacity="0.06" stroke="currentColor" stroke-opacity="0.3"/>
<text x="20" y="143" font-size="9.5" fill-opacity="0.75">0.004</text>
<text x="92" y="143" font-size="10.5" fill="var(--accent)">7</text>
<text x="150" y="143" font-size="10.5">both answers arrive</text>
<text x="404" y="143" font-size="9.5" fill-opacity="0.8">name not resolved</text>
<rect x="14" y="156" width="692" height="26" rx="2" fill="currentColor" fill-opacity="0.06" stroke="currentColor" stroke-opacity="0.3"/>
<text x="20" y="173" font-size="9.5" fill-opacity="0.75">0.004</text>
<text x="92" y="173" font-size="10.5" fill="var(--accent)">2</text>
<text x="150" y="173" font-size="10.5">find the gateway at layer 2</text>
<text x="404" y="173" font-size="9.5" fill-opacity="0.8">this network only, everything else fine</text>
<rect x="14" y="186" width="692" height="26" rx="2" fill="currentColor" fill-opacity="0.06" stroke="currentColor" stroke-opacity="0.3"/>
<text x="20" y="203" font-size="9.5" fill-opacity="0.75">0.004</text>
<text x="92" y="203" font-size="10.5" fill="var(--accent)">4</text>
<text x="150" y="203" font-size="10.5">open the connection</text>
<text x="404" y="203" font-size="9.5" fill-opacity="0.8">connection refused or a long wait</text>
<rect x="14" y="216" width="692" height="26" rx="2" fill="currentColor" fill-opacity="0.06" stroke="currentColor" stroke-opacity="0.3"/>
<text x="20" y="233" font-size="9.5" fill-opacity="0.75">0.006</text>
<text x="92" y="233" font-size="10.5" fill="var(--accent)">5 to 7</text>
<text x="150" y="233" font-size="10.5">agree keys and check the certificate</text>
<text x="404" y="233" font-size="9.5" fill-opacity="0.8">a warning page about the site</text>
<rect x="14" y="246" width="692" height="26" rx="2" fill="currentColor" fill-opacity="0.06" stroke="currentColor" stroke-opacity="0.3"/>
<text x="20" y="263" font-size="9.5" fill-opacity="0.75">0.011</text>
<text x="92" y="263" font-size="10.5" fill="var(--accent)">7</text>
<text x="150" y="263" font-size="10.5">send the request</text>
<text x="404" y="263" font-size="9.5" fill-opacity="0.8">a blank page or a stall</text>
<rect x="14" y="276" width="692" height="26" rx="2" fill="currentColor" fill-opacity="0.06" stroke="currentColor" stroke-opacity="0.3"/>
<text x="20" y="293" font-size="9.5" fill-opacity="0.75">0.011</text>
<text x="92" y="293" font-size="10.5" fill="var(--accent)">7</text>
<text x="150" y="293" font-size="10.5">read the response</text>
<text x="404" y="293" font-size="9.5" fill-opacity="0.8">half a page</text>
<rect x="14" y="306" width="692" height="26" rx="2" fill="currentColor" fill-opacity="0.06" stroke="currentColor" stroke-opacity="0.3"/>
<text x="20" y="323" font-size="9.5" fill-opacity="0.75">0.011</text>
<text x="92" y="323" font-size="10.5" fill="var(--accent)">4</text>
<text x="150" y="323" font-size="10.5">close the connection</text>
<text x="404" y="323" font-size="9.5" fill-opacity="0.8">nothing the user notices</text>
</g></svg>
<figcaption>The elapsed times are from the capture below, on a network with nothing else on it, so treat them as ordering rather than as anything to expect from a real connection. What survives the move to a real network is the right-hand column. Each row fails differently and visibly, which is what makes a user's description worth listening to carefully: "nothing happened at all" and "it sat there for thirty seconds" and "it said the certificate was wrong" are three different faults with three different owners, and the person reporting has already told you which one it is. The layer column is the other half. Two of the nine steps are layer 2 operations that most people never think about during a web request, and one of them, finding the gateway, fails in a way that looks like the whole internet is down while everything on the local segment works perfectly.</figcaption>
</figure>

Every row of that table is a real frame. Here is the whole load, captured on the
client, with the time counted from the first frame.

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology dns-web
# commands run on client
# start from nothing known: no cached name, no neighbour entries
$ ip neigh flush all
$ (timeout 16 tcpdump -i client0 -n -ttttt > /tmp/page.txt 2>/dev/null &)
$ sleep 2
$ curl -s -o /dev/null --cacert /tmp/lab-ca.pem https://www.lab.example/
$ sleep 14
# every frame the load took, in order, from the first to the last
$ grep -v "10.0.0.4 > 10.0.0.1\|10.0.0.4 > 10.0.0.2\|10.0.0.4 > 10.0.0.3" /tmp/page.txt | head -26
 00:00:00.000000 ARP, Request who-has 10.0.0.4 tell 10.0.0.5, length 28
 00:00:00.000090 ARP, Reply 10.0.0.4 is-at 02:00:00:00:00:04, length 28
 00:00:00.000094 IP 10.0.0.5.40578 > 10.0.0.4.53: 47802+ A? www.lab.example. (33)
 00:00:00.000185 IP 10.0.0.5.40578 > 10.0.0.4.53: 61367+ AAAA? www.lab.example. (33)
 00:00:00.001755 ARP, Request who-has 10.0.0.1 tell 10.0.0.4, length 28
 00:00:00.002633 ARP, Request who-has 10.0.0.2 tell 10.0.0.4, length 28
 00:00:00.003519 ARP, Request who-has 10.0.0.3 tell 10.0.0.4, length 28
 00:00:00.004057 IP 10.0.0.4.53 > 10.0.0.5.40578: 61367 1/0/0 AAAA 2001:db8:113::10 (61)
 00:00:00.004087 IP 10.0.0.4.53 > 10.0.0.5.40578: 47802 1/0/0 A 203.0.113.10 (49)
 00:00:00.004464 ARP, Request who-has 10.0.0.254 tell 10.0.0.5, length 28
 00:00:00.004487 ARP, Reply 10.0.0.254 is-at 02:00:00:00:00:fe, length 28
 00:00:00.004489 IP 10.0.0.5.50006 > 203.0.113.10.443: Flags [S], seq 3065613587, win 64240, options [mss 1460,sackOK,TS val 3853537089 ecr 0,nop,wscale 8], length 0
 00:00:00.004541 IP 203.0.113.10.443 > 10.0.0.5.50006: Flags [S.], seq 1350722648, ack 3065613588, win 65160, options [mss 1460,sackOK,TS val 3754028811 ecr 3853537089,nop,wscale 8], length 0
 00:00:00.004553 IP 10.0.0.5.50006 > 203.0.113.10.443: Flags [.], ack 1, win 251, options [nop,nop,TS val 3853537089 ecr 3754028811], length 0
 00:00:00.006878 IP 10.0.0.5.50006 > 203.0.113.10.443: Flags [P.], seq 1:1576, ack 1, win 251, options [nop,nop,TS val 3853537091 ecr 3754028811], length 1575
 00:00:00.006945 IP 203.0.113.10.443 > 10.0.0.5.50006: Flags [.], ack 1576, win 267, options [nop,nop,TS val 3754028813 ecr 3853537091], length 0
 00:00:00.010306 IP 203.0.113.10.443 > 10.0.0.5.50006: Flags [P.], seq 1:2485, ack 1576, win 267, options [nop,nop,TS val 3754028817 ecr 3853537091], length 2484
 00:00:00.010339 IP 10.0.0.5.50006 > 203.0.113.10.443: Flags [.], ack 2485, win 271, options [nop,nop,TS val 3853537095 ecr 3754028817], length 0
 00:00:00.011265 IP 10.0.0.5.50006 > 203.0.113.10.443: Flags [P.], seq 1576:1656, ack 2485, win 271, options [nop,nop,TS val 3853537096 ecr 3754028817], length 80
 00:00:00.011379 IP 10.0.0.5.50006 > 203.0.113.10.443: Flags [P.], seq 1656:1757, ack 2485, win 271, options [nop,nop,TS val 3853537096 ecr 3754028817], length 101
 00:00:00.011463 IP 203.0.113.10.443 > 10.0.0.5.50006: Flags [P.], seq 2485:2788, ack 1757, win 267, options [nop,nop,TS val 3754028818 ecr 3853537096], length 303
 00:00:00.011518 IP 203.0.113.10.443 > 10.0.0.5.50006: Flags [P.], seq 2788:3091, ack 1757, win 267, options [nop,nop,TS val 3754028818 ecr 3853537096], length 303
 00:00:00.011567 IP 10.0.0.5.50006 > 203.0.113.10.443: Flags [.], ack 3091, win 294, options [nop,nop,TS val 3853537096 ecr 3754028818], length 0
 00:00:00.011654 IP 203.0.113.10.443 > 10.0.0.5.50006: Flags [P.], seq 3091:3403, ack 1757, win 267, options [nop,nop,TS val 3754028818 ecr 3853537096], length 312
 00:00:00.011804 IP 10.0.0.5.50006 > 203.0.113.10.443: Flags [P.], seq 1757:1781, ack 3403, win 305, options [nop,nop,TS val 3853537096 ecr 3754028818], length 24
 00:00:00.011885 IP 10.0.0.5.50006 > 203.0.113.10.443: Flags [F.], seq 1781, ack 3403, win 305, options [nop,nop,TS val 3853537096 ecr 3754028818], length 0
```

Read it against the table. The first two frames are ARP: the client has to find
the resolver's layer 2 address before it can ask anything, and that is a step
nobody lists when describing what happens when you open a page.

Then the two queries go out, 91 microseconds apart, and both come back four
milliseconds later. **The three ARP requests in between are the resolver doing its
own work**, visible only because everything shares one segment here: it is finding
the root server, then the `example.` server, then the authoritative one, which is
the walk topic 44 traced.

Then another ARP, this time for 10.0.0.254, and that one is the gateway. The web
server is on a different network, so the client cannot reach it directly; it hands
the frame to the router and the router deals with the rest.

**The three frames after that are the handshake**, SYN, SYN-ACK, ACK, and they are
the only three anybody names. Then 1575 bytes leave the client, 2484 come back,
and a short exchange follows: that is TLS agreeing keys and the server presenting
its certificate. From the last of those frames onward everything is encrypted, and
the capture stops being able to tell you what was sent.

Finally FIN in both directions. The whole thing took 11.9 milliseconds.

## Why the request is invisible and how to see it anyway

Look again at the middle of that capture. There is no `GET`, no `Host` header,
nothing readable. That is TLS doing its job, and it is why packet capture is less
useful for application faults than it used to be.

The same page over plain HTTP is entirely readable, which is the other half of the
point.

<details class="predict">
<summary>The request a browser sends is invisible from the outside. Read off the wire, what does it actually contain?</summary>

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology dns-web
# commands run on client
# the same page over http, where the request and the answer are readable
$ (timeout 12 tcpdump -i client0 -n -A -s0 "tcp port 80 and tcp[tcpflags] & tcp-push != 0" > /tmp/plain.txt 2>/dev/null &)
$ sleep 2
$ curl -s -o /dev/null http://www.lab.example/
$ sleep 10
$ grep -a -A9 "GET /" /tmp/plain.txt | head -12
20:37:52.894630 IP 10.0.0.5.51562 > 203.0.113.10.80: Flags [P.], seq 3583358151:3583358230, ack 2205492461, win 251, options [nop,nop,TS val 3368102006 ecr 130650976], length 79: HTTP: GET / HTTP/1.1
E...C.@.@..{
.....q
.j.P.....u$.....F......
..(v...`GET / HTTP/1.1
Host: www.lab.example
User-Agent: curl/8.14.1
Accept: */*


20:37:52.894794 IP 203.0.113.10.80 > 10.0.0.5.51562: Flags [P.], seq 1:291, ack 79, win 255, options [nop,nop,TS val 130650976 ecr 3368102006], length 290: HTTP: HTTP/1.1 200 OK
E..V.F@.?..L..q
```

</details>

That is the request in full: the method, the path, the version, and the `Host`
header that tells a server which of the sites it hosts is being asked for. Then
the status line comes back.

Both blocks are the same page from the same server. The difference between them is
the argument for encrypting the web, made in two captures: anybody positioned on
the path can read the second one and can read nothing of the first except who was
talking to whom.

## Why both address families at once

One detail in the capture is worth its own section, because it explains a class of
slow connection people misdiagnose.

<figure class="learn-figure">
<svg viewBox="0 0 720 236" role="img" aria-labelledby="eyeballs-title" style="width:100%;height:auto;">
<title id="eyeballs-title">A client sending A and AAAA queries at the same moment and starting connections on both families, keeping the one that answers first and abandoning the other</title>
<g fill="currentColor">
<text x="14" y="22" font-size="11">the client does not pick a family, it races them</text>
<rect x="20" y="94" width="110" height="44" rx="3" fill="currentColor" fill-opacity="0.12" stroke="currentColor" stroke-opacity="0.6"/>
<text x="75" y="121" text-anchor="middle" font-size="10.5">the browser</text>
<line x1="130" y1="106" x2="252" y2="72" stroke="currentColor" stroke-opacity="0.7" stroke-width="1.6"/>
<path d="M 258 70 l -9 -1 l 4 9 z" fill="currentColor" fill-opacity="0.8"/>
<line x1="130" y1="126" x2="252" y2="160" stroke="currentColor" stroke-opacity="0.7" stroke-width="1.6"/>
<path d="M 258 162 l -9 1 l 4 -9 z" fill="currentColor" fill-opacity="0.8"/>
<text x="190" y="80" text-anchor="middle" font-size="9.5" fill-opacity="0.8">A?</text>
<text x="190" y="158" text-anchor="middle" font-size="9.5" fill-opacity="0.8">AAAA?</text>
<rect x="262" y="50" width="180" height="40" rx="3" fill="currentColor" fill-opacity="0.1" stroke="currentColor" stroke-opacity="0.55"/>
<text x="352" y="66" text-anchor="middle" font-size="10">203.0.113.10</text>
<text x="352" y="82" text-anchor="middle" font-size="9.5" fill-opacity="0.7">answered in 4 ms</text>
<rect x="262" y="142" width="180" height="40" rx="3" fill="currentColor" fill-opacity="0.1" stroke="currentColor" stroke-opacity="0.55"/>
<text x="352" y="158" text-anchor="middle" font-size="10">2001:db8:113::10</text>
<text x="352" y="174" text-anchor="middle" font-size="9.5" fill-opacity="0.7">answered in 4 ms</text>
<line x1="442" y1="70" x2="556" y2="98" stroke="var(--accent)" stroke-width="2"/>
<path d="M 562 100 l -9 -1 l 3 -9 z" fill="var(--accent)"/>
<line x1="442" y1="162" x2="556" y2="134" stroke="currentColor" stroke-opacity="0.4" stroke-width="1.6" stroke-dasharray="5 4"/>
<rect x="566" y="94" width="130" height="44" rx="3" fill="var(--accent)" fill-opacity="0.14" stroke="var(--accent)" stroke-opacity="0.9" stroke-width="1.6"/>
<text x="631" y="112" text-anchor="middle" font-size="10.5" fill="var(--accent)">connection</text>
<text x="631" y="128" text-anchor="middle" font-size="9.5" fill="var(--accent)">first to complete</text>
<text x="470" y="182" font-size="9.5" fill-opacity="0.7">the other is abandoned</text>
</g></svg>
<figcaption>Both queries go out together rather than one after the other, and where both answer, the client starts connecting on both and keeps whichever completes first. RFC 8305 calls this happy eyeballs, and it exists because of a specific failure that used to be common: a network with IPv6 addresses configured and no working IPv6 path. Before this behaviour, a client would resolve the AAAA record, try it, wait for a timeout measured in tens of seconds, and only then fall back. Users experienced that as certain sites being unusably slow while everything else was fine. Racing the two turns a broken path from a failure into a delay of a few hundred milliseconds, which is why the fault mostly disappeared without anybody fixing the underlying networks.</figcaption>
</figure>

The practical consequence for diagnosis: **a site that is slow only on the first
connection and fine afterwards is frequently an address family problem** rather
than a server problem. The client is racing, losing time on one path, and then
reusing the connection it won on.

<details class="deeper">
<summary>If you already work on networks: what actually costs the time on a real connection, and why the second page is so much faster than the first</summary>

The lab numbers on this page are useless as timings, because everything is a
fraction of a millisecond away. On a real connection the cost is almost entirely
round trips, and counting them is the whole of front-end network performance.

A cold load to a server 80 milliseconds away costs roughly: one round trip for
DNS if nothing is cached, sometimes several if the resolver has to walk the tree;
one for the TCP handshake; one for TLS 1.3, or two for TLS 1.2; and one for the
request and response. That is four to five round trips before a byte of the page
is on screen, or about 350 milliseconds, of which almost none is the server
thinking.

**This is why the second page from the same site is transformed.** The name is
cached, the connection is still open, and the TLS session can be resumed. Modern
browsers keep connections alive and multiplex many requests over one, so the
second request costs one round trip instead of five. Anybody measuring a site's
speed by loading it twice is measuring two completely different things.

**Three optimisations exist to remove specific round trips** and it is worth
knowing which is which, because they come up in troubleshooting.

TLS 1.3 cut the handshake from two round trips to one, which is the single largest
change to page load latency in a decade and arrived without anybody having to
change their site.

Session resumption removes the handshake entirely on a return visit, at the cost
of a small privacy trade: the ticket that permits it is also a way to recognise a
returning client.

Connection reuse removes the TCP handshake for every request after the first,
which is why the number of separate hosts a page pulls resources from matters more
than the number of resources.

**And the diagnostic that follows from all of it.** If the first byte is slow and
the rest is fast, look at the round trips: name resolution, handshakes, and the
distance to the server. If the first byte is fast and the page takes a long time
to finish, that is bandwidth or the server, and no amount of handshake tuning will
touch it.

</details>

## Across platforms

The capture on this page needs a machine you control on both ends. What you
usually have instead is the machine after the fact, and each step leaves something
behind in its tables.

**On Linux**, `ss -tn` shows the connections, `ip neigh` shows what was resolved
at layer 2, and the resolver's cache depends on which resolver is running.

**On macOS**, the same three pieces of evidence, in three different places.

```bash
# macOS 26.5.2, arm64
$ curl -s -o /dev/null https://example.com/

# the name step: what the resolver returned
$ dscacheutil -q host -a name example.com | head -4
name: example.com
ipv6_address: 2606:4700:10::ac42:93f3
ipv6_address: 2606:4700:10::6814:179a


# the address resolution step: the gateway this machine had to find first
$ netstat -rn -f inet | awk '$1 == "default" { print; exit }'
default            192.168.64.1       UGScg                 en0       

$ arp -a | grep -c .
3

# the connection step: what the load opened, and what state it is in now
$ netstat -an -p tcp | grep -E "\.443 " | head -3
tcp4       0      0  192.168.64.11.49163    140.82.113.21.443      ESTABLISHED
tcp4       0      0  192.168.64.11.49161    20.209.226.129.443     ESTABLISHED
tcp4       0      0  192.168.64.11.49160    140.82.113.21.443      ESTABLISHED
```

**On Windows**, each one is a cmdlet, and the connection from the load is still
listed in `TimeWait` immediately afterwards.

```powershell
# Microsoft Windows Server 2025 Datacenter, version 10.0.26100.0
> Invoke-WebRequest -Uri "https://example.com/" -UseBasicParsing -OutFile $env:TEMP\page.html

# the name step, still in the client cache afterwards
> Get-DnsClientCache -Entry example.com | Format-Table Entry, Type, TimeToLive, Data -AutoSize
Entry       Type TimeToLive Data
-----       ---- ---------- ----
example.com    1         49 104.20.23.154
example.com    1         49 172.66.147.243
example.com   15        250 . 0
example.com    2        594 hera.ns.cloudflare.com
example.com    2        594 elliott.ns.cloudflare.com
example.com    1        594 173.245.58.162
example.com    1        594 108.162.192.162
example.com    1        594 172.64.32.162
example.com    1        594 108.162.195.228
example.com    1        594 162.159.44.228
example.com    1        594 172.64.35.228
example.com    1         49 104.20.23.154
example.com    1         49 172.66.147.243

# the address resolution step: the gateway, and the neighbour entry for it
> Find-NetRoute -RemoteIPAddress 1.1.1.1 | Select-Object -First 1 -Property NextHop, InterfaceAlias | Format-Table -AutoSize
NextHop InterfaceAlias
------- --------------
        Ethernet 3

> Get-NetNeighbor -AddressFamily IPv4 -State Reachable, Stale | Select-Object -First 3 IPAddress, LinkLayerAddress, State | Format-Table -AutoSize
IPAddress LinkLayerAddress      State
--------- ----------------      -----
10.1.0.1  12-34-56-78-9A-BC Reachable

# the connection step
> Get-NetTCPConnection -RemotePort 443 | Select-Object -First 3 LocalAddress, LocalPort, RemoteAddress, State | Format-Table -AutoSize
LocalAddress LocalPort RemoteAddress       State
------------ --------- -------------       -----
10.1.0.101       65453 140.82.112.24 Established
10.1.0.101       55862 172.183.7.192 Established
10.1.0.101       54478 104.20.23.154    TimeWait
```

Both blocks are worth reading as the same list. The name step left a cache entry.
The layer 2 step left a neighbour entry for the gateway. The transport step left a
connection, and on Windows the one in `TimeWait` is the page load that just
finished, sitting in the state topic 09 described, waiting out its timer before
the port can be reused.

## Prove it

**Capture your own page load.** `tcpdump -i any -n` and load one small page from a
site you have never visited, then find each of the nine steps in the output. It is
the single most useful hour in this track.

**Load it again immediately.** Count how many of the nine steps happened the
second time. Most of them do not.

**Break one step on purpose.** Put a wrong entry in your hosts file, or point at a
resolver that does not exist, and see what the browser says. Matching the message
to the step is what turns a user's description into a diagnosis.

## What trips people up

### 1. Starting the story at the TCP handshake

Two layer 2 operations and a full DNS resolution happen before the first SYN. One
of them, finding the gateway, is the difference between "one site is down" and
"nothing works".

### 2. Expecting to read the request in a capture

Over HTTPS everything after the handshake is encrypted. A capture still tells you
who talked to whom, when, and how much, and nothing about what was said.

### 3. Assuming the client picks an address family

It asks for both and races them. That is why a broken IPv6 path is a delay rather
than an outage, and why the delay shows up on the first connection only.

### 4. Reading a second load as representative

The second load skips name resolution, the handshake and often the TLS exchange.
It measures a different thing from the first.

### 5. Treating "the website is down" as one fault

It is nine, and the person reporting it has usually already told you which one by
describing what they saw.

### 6. Blaming the server for time spent before the request

Round trips for DNS, TCP and TLS all happen before the server is asked anything.
On a distant server they are most of the wait.

## Work it through

The user who says the website is down.

Start by asking what they saw, in their words, because the nine steps fail
differently and the description usually names one.

If nothing happened at all and it happened instantly, that is name resolution or a
resolver, and topic 44 has the separation. If they waited a long time and then got
an error, something was asked and did not answer, which is a connection problem
rather than a name problem. If they got a warning about the site's certificate,
seven of the nine steps worked perfectly and the fault is in the eighth. If part of
the page appeared, everything worked and the response was interrupted.

**Then check whether it is one site or all of them**, which splits the list in
half. Everything failing points at the shared steps: the resolver, the gateway,
the path out. One site failing points at the steps specific to that name, which
are the lookup for that name and everything after the connection is opened.

The pair worth running early is a name and an address. If a name fails and its
address works, the fault is above layer 4 and probably in resolution. If both
fail, it is below, and the gateway is the first thing to look at. That is two
commands and it removes most of the candidates.

**One more thing worth knowing about this report.** The user is not wrong to say
the website is down, because from where they are sitting that is exactly what it
looks like. Nine independent mechanisms produce one observable symptom, and that
asymmetry is the reason this job needs the layers rather than the sentence.

## Try it

**Load a page with the developer tools open.** The network panel shows the same
steps with the same names, with the time each one took, and it is the version of
this capture that runs everywhere without root.

**Compare a cold load and a warm one.** Same page, twice. The difference is the
steps the second one skipped.

**Find a site that fails on one machine only.** Then work down the nine steps in
order until one of them behaves differently. It is almost always the first or
second.

## Check yourself

<details class="qa">
<summary>Put the steps of a page load in order, starting from the moment the name is typed.</summary>

Find the resolver at layer 2, ask it for the name in both address families, and
receive the answers. Then find the gateway at layer 2, because the server is on a
different network.

Then open the TCP connection with the three-way handshake, complete the TLS
handshake and check the certificate, send the HTTP request, read the response, and
close the connection. Two of those are layer 2 operations that happen before
anything anybody usually mentions.

</details>

<details class="qa">
<summary>A user says nothing happened at all and it happened immediately. Which steps are still candidates?</summary>

Only the early ones. An instant failure means something answered definitively or
nothing was ever sent, so the connection steps are out, because a failure there
takes time.

That leaves the resolver being unreachable or unconfigured, or the name genuinely
not resolving. A failure at any step from the TCP handshake onward would have made
them wait first.

</details>

<details class="qa">
<summary>Why can a packet capture of an HTTPS page load not show you the request?</summary>

Because everything after the TLS handshake is encrypted, including the method, the
path and the headers. The capture shows the handshake, then application data with
no readable content.

What it still shows is who talked to whom, when, how much, and how long each part
took, which is enough for most network faults and no use at all for an application
one.

</details>

<details class="qa">
<summary>Why does a client ask for A and AAAA records at the same time rather than one and then the other?</summary>

Because it intends to race the two paths. Where both answer, it starts connecting
on both families and keeps whichever completes first, which is what RFC 8305
describes.

The reason is a specific failure it replaced: a network with IPv6 configured and
no working IPv6 path used to produce a long timeout before falling back, and users
saw that as certain sites being unusably slow. Racing turns that into a delay of a
few hundred milliseconds.

</details>

<details class="qa">
<summary>The first page from a site is slow and every page after it is fast. Where is the time going?</summary>

Into round trips that only happen once. Name resolution, the TCP handshake and the
TLS handshake all cost a round trip each, and on a distant server they add up to
most of the wait before the first byte.

The second request reuses the resolved name, the open connection and often the TLS
session, so it costs one round trip instead of four or five. That is a property of
the connection rather than of the server, which is why measuring a site by loading
it twice measures two different things.

</details>

## References

- [RFC 9293](https://www.rfc-editor.org/rfc/rfc9293) - IETF, TCP, for the handshake and the closing exchange in the capture. Free. Accessed 2026-08-12.
- [RFC 8446](https://www.rfc-editor.org/rfc/rfc8446) - IETF, TLS 1.3, including the one round trip handshake. Free. Accessed 2026-08-12.
- [RFC 8305](https://www.rfc-editor.org/rfc/rfc8305) - IETF, happy eyeballs, on querying both families and racing the connections. Free. Accessed 2026-08-12.
- [RFC 9110](https://www.rfc-editor.org/rfc/rfc9110) - IETF, HTTP semantics, for the request line and the Host header in the plaintext capture. Free. Accessed 2026-08-12.
- [RFC 826](https://www.rfc-editor.org/rfc/rfc826) - IETF, ARP, which is the first thing that happens and the last thing anybody mentions. Free. Accessed 2026-08-12.

**Where the output came from.** Both captures ran on the `dns-web` namespace
topology through `blog/scripts/netlab.sh`. Everything in them is real: a name
resolved through a hierarchy built in the lab, a router between the client and the
server, and a TLS handshake against a self-signed certificate the client is
configured to trust, so the exchange completes rather than failing halfway. The
neighbour table is flushed immediately before the capture, which is why the two
address resolution steps appear; on a machine that has been running for a while
they would already have been done and the capture would start at the DNS query.
The elapsed times are honest and unrepresentative, because every node is a
fraction of a millisecond from every other one, and the deeper panel gives the
numbers that matter on a real connection instead. The Windows and macOS blocks
came from GitHub Actions runners through `blog/scripts/hostcap.sh`, loading
`example.com`, which IANA operates for documentation use.

**If you also work on Linux.** [Network connectivity
troubleshooting](/learn/linux-plus/network-connectivity-troubleshooting) on the
Linux+ track walks the same steps as a diagnostic sequence from a single machine,
with the command for each one.
