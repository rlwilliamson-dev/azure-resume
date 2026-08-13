---
title: "Time protocols"
description: "Stratum counts hops rather than quality, a clock that is wrong makes a perfectly good certificate look forged, and the fault presents as a security problem on exactly one machine."
deck: "Certificates are valid and authentication fails on one server"
track: "network-plus"
level: "working"
order: 490
objectives:
  - "Say why time matters to authentication and to certificates"
  - "Explain what a stratum number counts and what it does not"
  - "Describe how a time hierarchy is built"
  - "Say where precision time protocol is used and why"
  - "Recognise clock skew from the symptoms it produces"
prerequisites: ["encryption-certificates-and-pki"]
tags: ["network-plus", "networking", "services"]
updated: 2026-08-13
draft: false
examObjectives:
  - exam: "n10-009"
    domain: "3.0"
    objective: "3.4"
sources:
  - title: "RFC 5905, Network Time Protocol Version 4"
    url: "https://www.rfc-editor.org/rfc/rfc5905"
    publisher: "IETF"
    accessed: 2026-08-13
    tier: 1
  - title: "RFC 8915, Network Time Security for the Network Time Protocol"
    url: "https://www.rfc-editor.org/rfc/rfc8915"
    publisher: "IETF"
    accessed: 2026-08-13
    tier: 1
  - title: "RFC 5280, Internet X.509 Public Key Infrastructure Certificate Profile"
    url: "https://www.rfc-editor.org/rfc/rfc5280"
    publisher: "IETF"
    accessed: 2026-08-13
    tier: 1
  - title: "IEEE 1588, Precision Time Protocol"
    url: "https://standards.ieee.org/ieee/1588/6825/"
    publisher: "IEEE"
    accessed: 2026-08-13
    tier: 2
symptoms:
  - symptom: "One server rejects logins that work everywhere else"
    anchor: "what-a-wrong-clock-looks-like"
  - symptom: "A certificate is reported as not yet valid"
    anchor: "what-a-wrong-clock-looks-like"
  - symptom: "Log entries from two machines cannot be put in order"
    anchor: "what-breaks-without-this"
---

> **Before you read.** One server in a rack of twelve rejects every login. The
> accounts are fine, the password is correct, and the same credentials work on
> the other eleven.
>
> Somebody checks the certificate on it. The certificate is valid, issued last
> month, expiring next year.
>
> **What is wrong with that server, and why does the fault look like two
> different problems at once?**

Time is infrastructure in the same way addressing is: nothing mentions it until
it is wrong, and then several unrelated things fail at once in ways that point
everywhere except at the cause.

### Some words you will need

<dl class="terms">
<dt>NTP</dt>
<dd>Network Time Protocol. How almost every machine on a network learns what time it is.</dd>
<dt>stratum</dt>
<dd>How many steps a server is from a reference clock.</dd>
<dt>reference clock</dt>
<dd>Something that knows the time without asking: GPS, a radio signal, an atomic standard.</dd>
<dt>offset</dt>
<dd>How far this machine's clock is from the time it was told.</dd>
<dt>skew</dt>
<dd>The rate at which a clock drifts away, as opposed to how far out it currently is.</dd>
<dt>PTP</dt>
<dd>Precision Time Protocol. The same job to microseconds, with help from the switches.</dd>
</dl>

## What breaks without this

**Authentication fails on one machine.** Kerberos rejects a ticket outside a
five minute window by default, so a clock off by six minutes stops logins on that
machine alone.

**A valid certificate is reported as invalid.** Because validity is a pair of
dates and the machine checking them believes the wrong date.

**Logs cannot be put in order.** Two machines describing the same incident with
timestamps that disagree by ten seconds cannot be correlated, and the incident
review becomes an argument about which one to believe.

## Stratum counts hops

The number gets read as a rating. It is a distance.

<figure class="learn-figure">
<svg viewBox="0 0 720 244" role="img" aria-labelledby="stratum-title" style="width:100%;height:auto;">
<title id="stratum-title">A reference clock and three servers below it, each one stratum lower than the server it synchronises to, showing that the number counts hops rather than quality</title>
<g fill="currentColor">
<text x="14" y="22" font-size="11">the number counts hops away from a clock, and nothing else</text>
<rect x="30" y="60" width="152" height="66" rx="3" fill="var(--accent)" fill-opacity="0.16" stroke="var(--accent)" stroke-opacity="0.9"/>
<text x="106" y="82" text-anchor="middle" font-size="10.5">a clock</text>
<text x="106" y="104" text-anchor="middle" font-size="13" fill="var(--accent)">stratum 0</text>
<text x="106" y="118" text-anchor="middle" font-size="9" fill-opacity="0.7">caesium, GPS, radio</text>
<line x1="182" y1="93" x2="206" y2="93" stroke="currentColor" stroke-opacity="0.5" stroke-width="1.6"/>
<path d="M 212 93 l -9 -5 l 0 10 z" fill="currentColor" fill-opacity="0.7"/>
<rect x="200" y="60" width="152" height="66" rx="3" fill="currentColor" fill-opacity="0.09" stroke="currentColor" stroke-opacity="0.5"/>
<text x="276" y="82" text-anchor="middle" font-size="10.5">one attached to it</text>
<text x="276" y="104" text-anchor="middle" font-size="13">stratum 1</text>
<text x="276" y="118" text-anchor="middle" font-size="9" fill-opacity="0.7">reads it over a wire</text>
<line x1="352" y1="93" x2="376" y2="93" stroke="currentColor" stroke-opacity="0.5" stroke-width="1.6"/>
<path d="M 382 93 l -9 -5 l 0 10 z" fill="currentColor" fill-opacity="0.7"/>
<rect x="370" y="60" width="152" height="66" rx="3" fill="currentColor" fill-opacity="0.09" stroke="currentColor" stroke-opacity="0.5"/>
<text x="446" y="82" text-anchor="middle" font-size="10.5">one asking that one</text>
<text x="446" y="104" text-anchor="middle" font-size="13">stratum 2</text>
<text x="446" y="118" text-anchor="middle" font-size="9" fill-opacity="0.7">over the network</text>
<line x1="522" y1="93" x2="546" y2="93" stroke="currentColor" stroke-opacity="0.5" stroke-width="1.6"/>
<path d="M 552 93 l -9 -5 l 0 10 z" fill="currentColor" fill-opacity="0.7"/>
<rect x="540" y="60" width="152" height="66" rx="3" fill="currentColor" fill-opacity="0.09" stroke="currentColor" stroke-opacity="0.5"/>
<text x="616" y="82" text-anchor="middle" font-size="10.5">and so on</text>
<text x="616" y="104" text-anchor="middle" font-size="13">stratum 3</text>
<text x="616" y="118" text-anchor="middle" font-size="9" fill-opacity="0.7">up to 15</text>
<text x="30" y="164" font-size="10.5">a stratum 2 server on a fast local link can be closer to the truth</text>
<text x="30" y="184" font-size="10.5" fill-opacity="0.85">than a stratum 1 server on the other side of the world</text>
<text x="30" y="216" font-size="10" fill-opacity="0.7">16 means unsynchronised, which is a state rather than a distance</text>
</g></svg>
<figcaption>Stratum 0 is not a server and cannot be queried: it is the clock itself, a caesium standard or a GPS receiver or a radio time signal. Everything after that counts steps away from it, and a server one step further out claims one number higher without anybody configuring it. The consequence in the third line is the part worth arguing with somebody about, because "we should use a stratum 1 server" sounds like a quality decision and is mostly a distance decision. Time transfer accuracy is dominated by the variability of the round trip, so a stratum 2 server three milliseconds away on your own network will usually hold a machine closer to the truth than a stratum 1 server across an ocean, and it will do it without adding load to somebody else's public service.</figcaption>
</figure>

Building the hierarchy is what makes the number concrete. Here is a server told
to serve from its own clock, a second synchronising to it, and a third
synchronising to that.

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology ntp-lan
# what the bottom of the chain thinks, and where it got it
$ ip netns exec leaf chronyc -h 10.0.0.3 sources
MS Name/IP address         Stratum Poll Reach LastRx Last sample               
===============================================================================
^* 10.0.0.2                      6   0   377     1    +13us[  +19us] +/-   48us
$ ip netns exec leaf chronyc -h 10.0.0.3 tracking | head -5
Reference ID    : 0A000002 (10.0.0.2)
Stratum         : 7
Ref time (UTC)  : Thu Aug 13 16:57:29 2026
System time     : 0.000004045 seconds fast of NTP time
Last offset     : +0.000006726 seconds
# and the server it is asking, one step further up
$ ip netns exec mid chronyc -h 10.0.0.2 tracking | head -2
Reference ID    : 0A000001 (10.0.0.1)
Stratum         : 6
```

Nobody typed 6 or 7 anywhere. The leaf asked its source what stratum it was,
added one, and that is the whole algorithm.

The other fields are worth reading once. `Reach` is an octal history of the last
eight exchanges, so 377 is all eight successful and anything else is a source
that is missing answers. The offset is how far this machine's clock currently
sits from the time it was told, in this case a few microseconds, and it is the
number that matters rather than the stratum.

<figure class="learn-figure photo">

![A small green metal box photographed on a wooden table, its front panel silkscreened with white lettering. The panel reads GPS Disciplined Oscillator and carries, from left to right, three indicator lights labelled ALM, GPS LOCK and RUN, a nine pin serial connector labelled RS232 with its pin functions printed underneath, two BNC sockets labelled 1PPS and 10MHz, a power input marked DC 11.7 to 12.9V MAX 15W, and a threaded antenna connector labelled GPS ANT.](./images/gps-disciplined-oscillator.jpg)

<figcaption>What sits behind a stratum 1 server, with every port labelled. The antenna connector at the right takes a feed from a GPS receiver on the roof, and the two BNC sockets are the outputs that matter: 10 MHz is a frequency reference, and 1PPS is a single pulse once per second, aligned to the start of that second, which is how the satellites' notion of time gets into a piece of equipment. A server with one of these attached reads that pulse directly and becomes stratum 1, which is the entire qualification. The status lights are the operational part: GPS LOCK going out means the box has lost the satellites and is running on its own oscillator, still accurate for a while and drifting, and a stratum 1 server whose antenna was disconnected during building work will keep serving confident time for days. Photograph by RoundupResistance, released under <a href="https://creativecommons.org/publicdomain/zero/1.0/">CC0</a>.</figcaption>
</figure>

## What a wrong clock looks like

The reason time is worth a topic is that its failures do not look like time
failures. Here is the same certificate file, verified three times, with nothing
different except what the clock says.

```bash
# Debian 13 (trixie), x86_64
$ openssl x509 -in ca.pem -noout -subject -dates; echo; for t in 2026-03-01 2025-12-01 2026-08-01; do printf "clock says %s: " "$t"; openssl verify -attime $(date -u -d "$t" +%s) -CAfile ca.pem ca.pem 2>&1 | tail -2 | tr "\n" " "; echo; done
subject=CN=Lab CA
notBefore=Jan  1 00:00:00 2026 GMT
notAfter=Jun 30 00:00:00 2026 GMT

clock says 2026-03-01: ca.pem: OK 
clock says 2025-12-01: error 9 at 0 depth lookup: certificate is not yet valid error ca.pem: verification failed 
clock says 2026-08-01: error 10 at 0 depth lookup: certificate has expired error ca.pem: verification failed 
```

One file, three answers. **"Certificate is not yet valid" and "certificate has
expired" are the same fault** seen from either side, and neither message mentions
the clock, because from the verifying machine's point of view the certificate
genuinely is outside its validity window.

That is the fault in the scenario at the top of the page, and it explains why it
looked like two problems. Authentication fails because Kerberos and most token
schemes reject anything outside a tolerance window, five minutes by default,
which is short enough that an unsynchronised clock reaches it in weeks.
Certificates fail because validity is a pair of dates. Both are consequences of
one number being wrong on one machine.

**The diagnostic is one command, and it is worth reaching for early.** Compare the
clock on the machine that is failing against a machine that is not. If they
disagree by more than a few seconds, stop investigating the certificate.

## Where microseconds are needed

NTP over a network holds machines within a few milliseconds of each other, which
is far more than enough for logs, authentication and certificates.

**Precision Time Protocol is the answer when it is not enough.** IEEE 1588,
targeting microseconds or better, and it gets there by a different route: the
switches take part. A transparent clock measures how long a message spent inside
it and writes that into the message, so the accumulated delay through the network
is known rather than estimated.

That is the practical difference to carry. NTP is software on the endpoints and
works over any network. PTP needs the network equipment to support it, which
makes it a design decision rather than a configuration one.

The places it is used are specific: financial trading, where regulators require
timestamps accurate to microseconds; broadcast, where video and audio streams
have to stay aligned; industrial control and power distribution; and mobile
networks, where base stations must agree closely enough not to interfere.

<details class="deeper">
<summary>If you already work on networks: why time is a security dependency, what NTP had instead of authentication for thirty years, and the two failure modes of a time source</summary>

Time is the one dependency almost every security control shares, which makes an
attacker who can control it unusually well placed.

Move a machine's clock backwards far enough and a revoked certificate becomes
valid again, because revocation lists have their own validity windows and an
expired certificate becomes unexpired. Move it forwards and sessions expire, tokens
become invalid and one-time codes stop matching. Neither needs any access to the
cryptography.

**NTP had almost nothing to protect against this for most of its life.** The
symmetric key authentication in the protocol required a shared secret per server
pair, which nobody deployed at scale, and the public pool has always been
unauthenticated. RFC 8915 defines Network Time Security, which uses TLS to
establish keys and then authenticates the time exchanges themselves. Support is
now in the main implementations and deployment is early, and it is worth knowing
by name because it is the answer to the obvious question about the pool.

**A time source fails in two ways and they need different responses.** It can stop
answering, which is loud: clients notice, log it, and keep running on their own
oscillators, drifting slowly. Or it can answer confidently with the wrong time,
which is silent and much worse, because clients will follow it.

This is why clients are configured with several sources rather than one. With
three or more, an implementation can discard the outlier and keep the agreeing
majority, which is exactly what the algorithm in RFC 5905 does. With two, a
disagreement is unresolvable and most implementations refuse to step rather than
guess. With one, whatever it says is the truth.

That argues for a specific arrangement: at least three internal servers, each
synchronising upward to several external sources, with everything else pointing at
all three. It costs nothing and it converts the silent failure into a detectable
one.

</details>

## Across platforms

Every platform runs a time client by default and none of them use the same one.

**On Linux** it is usually `chrony` or `systemd-timesyncd`, and `chronyc sources`
and `timedatectl` are the two commands worth knowing.

**On macOS** and **on Windows** the client is built into the system and each
exposes its state differently. The important part is the same on all three: the
question to ask when something fails is what this machine believes the time is and
how far that is from everybody else.

Topic 02 covers reading the clock on each platform. What matters here is the
comparison rather than the command, and any two machines whose clocks disagree by
more than a few seconds have found the fault.

## Prove it

**Compare two clocks.** Any two machines you have. If they agree to the second,
the mechanism on this page is working and you have never had to think about it.

**Break one on purpose.** In a virtual machine, set the clock forward by a year
and try to browse anywhere. The errors are the ones on this page, and none of them
will mention the time.

**Find what your machine is synchronising to.** Then find out what that server is
synchronising to. Most people cannot answer the second question about their own
network.

## What trips people up

### 1. Reading stratum as a quality rating

It counts hops from a reference clock. A nearby stratum 2 server is usually a
better source than a distant stratum 1 one, because accuracy is dominated by the
variability of the round trip.

### 2. Thinking stratum 0 is a server

It is the clock itself, and it has no network interface. Stratum 1 is the first
thing you can query.

### 3. Treating a certificate error as a certificate problem

The same file is valid or invalid depending on what the verifying machine thinks
the date is. Check the clock before the certificate.

### 4. Missing that Kerberos has a tolerance window

Five minutes by default. A machine drifting quietly reaches that in weeks, and the
symptom is that logins fail on one host while working everywhere else.

### 5. Configuring one time source

A source that stops answering is obvious. A source that answers with the wrong
time is silent, and with a single source there is nothing to compare it against.

### 6. Expecting PTP to be a drop-in improvement

It reaches microseconds by having the switches measure their own delay, so it
needs the network equipment to support it. NTP is software on the endpoints.

## Work it through

The one server in twelve that rejects every login while its certificate is valid.

The shape of the report is the clue, and it is worth noticing before touching
anything. Two unrelated subsystems are failing on one machine and neither is
failing anywhere else. Authentication and certificate validation have almost
nothing in common except that both compare something against the current time.

**So the first command is not about either of them.** Read the clock on that
server and read it on one of the eleven that work. If they differ by minutes, the
investigation is over and the rest is repair.

Assume they do. Now there are two questions, and only the second one matters in a
week's time.

The immediate one is why the clock drifted, and there are three usual answers: the
time client is not running, it is running and configured with a source it cannot
reach, or it is running and reaching a source that is itself wrong. The first two
are visible in the client's own status output, which will say plainly that it has
no reachable sources. The third is the one to suspect if several machines drifted
together rather than one, and it is why the deeper panel argues for more than one
source.

The second question is why nobody knew. A machine's clock does not jump; it
drifts, over weeks, through a range where nothing complains at all. It passed
through one minute of error with no symptom, and then somewhere past five minutes
Kerberos started refusing, which means the fault existed and was invisible for
most of its life. Offset is a metric like any other, topic 40's argument applies
to it, and almost nobody monitors it.

**And a note on the certificate.** Somebody checked it and found it valid, which
was correct and was also a dead end, because they were reading the dates on a
machine with a working clock. Reading the same certificate on the failing server
would have produced the error message and pointed straight at the answer. The
general version: when a fault is on one machine, run the diagnostic on that
machine.

## Try it

**Set a clock wrong and read the errors.** Nothing teaches this faster than seeing
"certificate is not yet valid" on a certificate you issued yourself an hour ago.

**Look at the offset your machines report.** Not whether they are synchronised,
which is a yes or no, but by how much. That number is the one that goes wrong
slowly.

**Count your time sources.** If the answer is one, you have a single point of
failure that fails silently, which is the worst combination available.

## Check yourself

<details class="qa">
<summary>What does a stratum number count, and why is a low one not automatically better?</summary>

It counts steps away from a reference clock. Stratum 0 is the clock itself,
stratum 1 is a server with one attached, and every server that synchronises to
another claims one higher.

It is a distance rather than a quality rating. Accuracy over a network is
dominated by the variability of the round trip, so a stratum 2 server a few
milliseconds away will usually hold a machine closer to the truth than a stratum 1
server on the other side of the world.

</details>

<details class="qa">
<summary>A server reports that a certificate is not yet valid. The certificate was issued a month ago. What is wrong?</summary>

The clock on that server. Validity is a pair of dates in the certificate, and a
machine that believes the date is earlier than the notBefore field will report
exactly that, because from its point of view the certificate genuinely has not
started yet.

Nothing in the message mentions the time, which is what makes the fault confusing.
The same file verifies without complaint on a machine whose clock is right.

</details>

<details class="qa">
<summary>Why does clock drift produce authentication failures on one machine while other machines are fine?</summary>

Because the tolerance is checked per machine. Kerberos rejects tickets outside a
window that defaults to five minutes, so the machine whose clock has drifted past
that refuses, and every machine still inside the window carries on normally.

The credentials are correct and the directory is fine, which is why the report
arrives as an account problem rather than a time problem.

</details>

<details class="qa">
<summary>What does PTP do that NTP does not, and what does it require in exchange?</summary>

It reaches microsecond accuracy rather than millisecond, by having the network
equipment take part: a transparent clock measures how long a message spent inside
the switch and records it, so the delay through the network is measured rather
than estimated.

The cost is that the switches have to support it, which makes it a network design
decision. NTP is software on the endpoints and works across any path, which is why
it is what almost everything uses.

</details>

<details class="qa">
<summary>Why configure three time sources rather than one?</summary>

Because a time source fails in two ways. It can stop answering, which clients
notice and log, or it can answer confidently with the wrong time, which they will
follow.

With three or more, an implementation can discard a source that disagrees with the
others and keep the majority. With two, a disagreement cannot be resolved. With
one, whatever it says becomes the truth, and the silent failure has nothing to
catch it.

</details>

## References

- [RFC 5905](https://www.rfc-editor.org/rfc/rfc5905) - IETF, NTP version 4, including stratum, the selection algorithm and the meaning of stratum 16. Free. Accessed 2026-08-13.
- [RFC 8915](https://www.rfc-editor.org/rfc/rfc8915) - IETF, Network Time Security. Free. Accessed 2026-08-13.
- [RFC 5280](https://www.rfc-editor.org/rfc/rfc5280) - IETF, the certificate profile, for the validity period the capture tests against. Free. Accessed 2026-08-13.
- [IEEE 1588](https://standards.ieee.org/ieee/1588/6825/) - IEEE, Precision Time Protocol. Paid. Accessed 2026-08-13.
- [chrony documentation](https://chrony-project.org/documentation.html) - The implementation used to build the hierarchy in the capture. Accessed 2026-08-13.

**Pictures.** A freely licensed file from Wikimedia Commons, downloaded and served
from this site rather than linked across to somebody else's server. Resized and
otherwise unaltered.

- [GPS disciplined oscillator unit](https://commons.wikimedia.org/wiki/File:GPS_disciplined_oscillator_unit.jpg) by RoundupResistance, [CC0](https://creativecommons.org/publicdomain/zero/1.0/).

**Where the output came from.** The hierarchy ran on the `ntp-lan` namespace
topology through `blog/scripts/netlab.sh`, with three real chrony instances
synchronising to each other. One thing in it is a fiction and is worth naming: the
top server is told `local stratum 5`, which makes it willing to serve time from
its own clock without a reference attached, because a lab cannot have a caesium
standard in it. Everything below that is genuine, and the stratum numbers in the
output were counted by the software rather than configured. The certificate block
came from a Debian 13 container through `blog/scripts/capture.sh`, using a
certificate with fixed validity dates so the answers do not depend on the day the
capture ran, and `openssl verify -attime` to ask the question as if at three
different moments.

**If you also work on Linux.** [Central identity](/learn/linux-plus/central-identity)
on the Linux+ track has a panel on the same dependency from the other direction:
what a domain-joined machine does when its clock drifts past the tolerance, and
why the time client is a dependency of authentication rather than a convenience.
