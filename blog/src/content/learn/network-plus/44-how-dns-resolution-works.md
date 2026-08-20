---
title: "How DNS resolution works"
description: "The walk from the root down, drawn and then captured on a lab with its own root server. Plus the one flag that separates an answer from a copy of an answer, and why a change you made this morning is still invisible this afternoon."
deck: "`ping 1.1.1.1` works and `ping example.com` does not"
track: "network-plus"
level: "working"
order: 450
objectives:
  - "Describe the path from a stub resolver to the root to an authoritative server"
  - "Distinguish a recursive query from an iterative one"
  - "Read the authoritative flag out of a real answer"
  - "Say what a time to live governs and what it costs you"
  - "Explain how a failed lookup gets cached and for how long"
prerequisites: ["dhcp"]
tags: ["network-plus", "networking", "services"]
updated: 2026-08-12
draft: false
examObjectives:
  - exam: "n10-009"
    domain: "3.0"
    objective: "3.4"
sources:
  - title: "RFC 1034, Domain Names, Concepts and Facilities"
    url: "https://www.rfc-editor.org/rfc/rfc1034"
    publisher: "IETF"
    accessed: 2026-08-12
    tier: 1
  - title: "RFC 1035, Domain Names, Implementation and Specification"
    url: "https://www.rfc-editor.org/rfc/rfc1035"
    publisher: "IETF"
    accessed: 2026-08-12
    tier: 1
  - title: "RFC 2308, Negative Caching of DNS Queries"
    url: "https://www.rfc-editor.org/rfc/rfc2308"
    publisher: "IETF"
    accessed: 2026-08-12
    tier: 1
  - title: "Root Server Technical Operations Association"
    url: "https://root-servers.org/"
    publisher: "root-servers.org"
    accessed: 2026-08-12
    tier: 1
symptoms:
  - symptom: "An address works and the name for it does not"
    anchor: "the-walk-down-the-tree"
  - symptom: "A DNS change has not taken effect hours later"
    anchor: "the-answer-and-the-copy"
  - symptom: "A name that was mistyped once keeps failing after it is fixed"
    anchor: "when-the-answer-is-no"
---

> **Before you read.** A machine can ping 1.1.1.1 all day. `ping example.com`
> returns "Name or service not known" instantly.
>
> The cable is fine, the gateway is fine, and packets are reaching the internet.
>
> **What is broken, and why did the failure arrive instantly rather than after a
> timeout?**

Every name on the internet is resolved by a walk down a tree that starts at a
place nobody types. The walk is worth understanding properly rather than as a
diagram, because half of what looks like a network fault is a name that resolved
to something unexpected or did not resolve at all.

### Some words you will need

<dl class="terms">
<dt>stub resolver</dt>
<dd>The small piece of your operating system that asks a question and takes an answer.</dd>
<dt>recursive resolver</dt>
<dd>The server that does the actual work of finding out. Usually your ISP's or your company's.</dd>
<dt>authoritative server</dt>
<dd>A server holding the real records for a zone rather than a copy of them.</dd>
<dt>zone</dt>
<dd>The part of the tree one set of servers answers for.</dd>
<dt>referral</dt>
<dd>An answer that is not the answer: go and ask this other server.</dd>
<dt>TTL</dt>
<dd>Time to live. How many seconds anybody may keep a copy of a record.</dd>
</dl>

## What breaks without this

**An address works and a name does not.** Which points at exactly one part of the
system and saves an hour of looking at the wrong thing.

**A change is made and does not take effect.** For a length of time that was
decided months ago by whoever set the record's TTL.

**A typo keeps failing after it is corrected.** Because the failure was cached
too, and for a period nobody chose deliberately.

## The walk down the tree

Your machine asks one question. Something else asks several.

<figure class="learn-figure">
<svg viewBox="0 0 720 276" role="img" aria-labelledby="resolve-title" style="width:100%;height:auto;">
<title id="resolve-title">A stub resolver asking one question and getting one answer, while the recursive resolver behind it asks the root, the top level server and the authoritative server in turn</title>
<g fill="currentColor">
<text x="14" y="22" font-size="11">one question on the left, four on the right</text>
<rect x="20" y="120" width="96" height="40" rx="3" fill="currentColor" fill-opacity="0.12" stroke="currentColor" stroke-opacity="0.6"/>
<text x="68" y="138" text-anchor="middle" font-size="10.5">your machine</text>
<text x="68" y="152" text-anchor="middle" font-size="9.5" fill-opacity="0.7">stub resolver</text>
<line x1="116" y1="132" x2="196" y2="132" stroke="var(--accent)" stroke-width="2"/>
<path d="M 202 132 l -9 -5 l 0 10 z" fill="var(--accent)"/>
<text x="159" y="124" text-anchor="middle" font-size="9.5" fill="var(--accent)">A? www</text>
<line x1="196" y1="150" x2="122" y2="150" stroke="currentColor" stroke-opacity="0.7" stroke-width="1.6"/>
<path d="M 116 150 l 9 -5 l 0 10 z" fill="currentColor"/>
<text x="159" y="166" text-anchor="middle" font-size="9.5" fill-opacity="0.75">203.0.113.10</text>
<rect x="202" y="112" width="104" height="56" rx="3" fill="currentColor" fill-opacity="0.16" stroke="currentColor" stroke-opacity="0.75" stroke-width="1.6"/>
<text x="254" y="134" text-anchor="middle" font-size="10.5">resolver</text>
<text x="254" y="150" text-anchor="middle" font-size="9.5" fill-opacity="0.7">recursive</text>
<rect x="470" y="56" width="140" height="40" rx="3" fill="currentColor" fill-opacity="0.1" stroke="currentColor" stroke-opacity="0.55"/>
<text x="540" y="74" text-anchor="middle" font-size="10.5">root</text>
<text x="540" y="88" text-anchor="middle" font-size="9.5" fill-opacity="0.7">try ns.example</text>
<line x1="310" y1="140" x2="458" y2="76" stroke="currentColor" stroke-opacity="0.55" stroke-width="1.4"/>
<path d="M 464 76 l -9 -3 l 3 9 z" fill="currentColor" fill-opacity="0.7"/>
<rect x="470" y="140" width="140" height="40" rx="3" fill="currentColor" fill-opacity="0.1" stroke="currentColor" stroke-opacity="0.55"/>
<text x="540" y="158" text-anchor="middle" font-size="10.5">example</text>
<text x="540" y="172" text-anchor="middle" font-size="9.5" fill-opacity="0.7">try ns.lab.example</text>
<line x1="310" y1="140" x2="458" y2="160" stroke="currentColor" stroke-opacity="0.55" stroke-width="1.4"/>
<path d="M 464 160 l -9 -3 l 3 9 z" fill="currentColor" fill-opacity="0.7"/>
<rect x="470" y="224" width="140" height="40" rx="3" fill="currentColor" fill-opacity="0.1" stroke="currentColor" stroke-opacity="0.55"/>
<text x="540" y="242" text-anchor="middle" font-size="10.5">lab.example</text>
<text x="540" y="256" text-anchor="middle" font-size="9.5" fill-opacity="0.7">203.0.113.10</text>
<line x1="310" y1="140" x2="458" y2="244" stroke="currentColor" stroke-opacity="0.55" stroke-width="1.4"/>
<path d="M 464 244 l -9 -3 l 3 9 z" fill="currentColor" fill-opacity="0.7"/>
<text x="20" y="204" font-size="10.5" fill="var(--accent)">recursive: answer it or fail, do not send me elsewhere</text>
<text x="20" y="224" font-size="10.5">iterative: tell me who to ask next</text>
</g></svg>
<figcaption>Recursive and iterative are not two protocols or two products. They are the two halves of this picture: the query on the left is recursive because the machine sending it wants a final answer and will not chase referrals, and the three on the right are iterative because each server answers with the best it has, which is usually the name of somebody better placed to help. The consequence worth carrying is on the left. Your machine receives one answer, at no point learns that three other servers were consulted, and cannot tell a fast lookup from a slow one except by how long it took. That is why a DNS problem so rarely looks like a DNS problem from the machine reporting it.</figcaption>
</figure>

Running that walk by hand shows every step, because `dig +trace` does what a
resolver does and prints each referral as it arrives.

<details class="predict">
<summary>A name nobody on this network has looked up before. How many servers get asked before an answer comes back, and what does each one contribute?</summary>

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology dns-web
# commands run on client
# ask starting at the root, and follow every referral by hand
$ dig +trace www.lab.example 2>&1 | grep -v "^;; global\|^$\|^; <<>>"
.			3600	IN	NS	a.root-servers.lab.
;; Received 87 bytes from 10.0.0.4#53(10.0.0.4) in 1 ms
example.		3600	IN	NS	ns.example.
;; Received 105 bytes from 10.0.0.1#53(a.root-servers.lab) in 0 ms
lab.example.		3600	IN	NS	ns.lab.example.
;; Received 105 bytes from 10.0.0.2#53(ns.example) in 0 ms
www.lab.example.	3600	IN	A	203.0.113.10
lab.example.		3600	IN	NS	ns.lab.example.
;; Received 121 bytes from 10.0.0.3#53(ns.lab.example) in 0 ms
```

</details>

Read it from the top. The resolver hands over the list of root servers. The root
does not know `www.lab.example` and has never heard of it; what it knows is who
handles `example.`, so it says so. The `example.` server does not know the name
either, and says who handles `lab.example.`. Only the third server has the record.

**Nobody in that chain looked anything up on your behalf except the resolver.**
Each of the others answered from its own zone and stopped, which is what makes
this scale: the root servers answer a question about the top of the tree and
nothing else, forever, no matter how many names exist below.

<figure class="learn-figure photo">

![A rack of network equipment photographed through a glass door, with reflections across the image. Two printed labels are fixed to the front panels: ROUTER.AMS-IX.K.RIPE.NET on the left and K.ROOT-SERVERS.NET on the right. Below them a Cisco 7301 router shows three gigabit Ethernet ports with green link lights, and blue, green and orange patch leads run untidily across the front of the equipment in every direction.](./images/k-root-server-instance.jpg)

<figcaption>One of the root servers, in a rack at the Amsterdam Internet Exchange, behind a glass door with the photographer reflected in it. Two things are worth taking from a picture this ordinary. The first is that it is ordinary: a mid-range router and a server, cabled by somebody in a hurry, of the kind in thousands of buildings. The second is arithmetic. There are thirteen root server addresses, a number fixed decades ago by how much would fit in one UDP response, and there are not thirteen machines. Each letter is announced from many sites at once using the anycast routing topic 15 described, so the K in that label is one instance of one letter, and a query from Amsterdam reaches this rack while the same query from Sydney reaches different hardware entirely. Photograph by Bas van Schaik, <a href="https://creativecommons.org/licenses/by-sa/3.0/">CC BY-SA 3.0</a>.</figcaption>
</figure>

<details class="deeper">
<summary>If you already run resolvers: why the walk almost never happens, and what that means when it does</summary>

The full walk is the model and it is not what your resolver spends its time doing.

A busy resolver answers most queries from cache without asking anybody, and the parts
of the walk that would be repeated are the parts cached longest: the root referrals and
the top level domain servers change rarely and carry long lifetimes. So a resolver that
has been running for a day is usually one query away from an answer, not five.

That has two consequences. The first is that resolution timing is bimodal rather than
average: cached answers come back in under a millisecond and uncached ones take as long
as the slowest server in the chain, which may be on another continent. Reporting a mean
response time for a resolver hides that completely, which is the averaging problem topic
40 covers arriving somewhere unexpected.

The second is that a cold resolver behaves nothing like a warm one. Restart it and the
first minutes are slow for everybody while the cache refills, which is worth knowing
before restarting one at nine in the morning. It is also why a newly built resolver
tested at midnight looks faster than it will be in production, and why the useful test
is against a warm cache with real query patterns rather than a handful of lookups.

</details>

## The answer and the copy

Ask twice and you get the same values with two differences, and both differences
matter.

<figure class="learn-figure">
<svg viewBox="0 0 720 250" role="img" aria-labelledby="cache-title" style="width:100%;height:auto;">
<title id="cache-title">The same answer from the authoritative server and from a resolver, with the authoritative flag set on one and not the other, and the time to live counting down on the copy</title>
<g fill="currentColor">
<text x="14" y="22" font-size="11">the same record, from the server that owns it and from one that copied it</text>
<text x="30" y="56" font-size="10.5" fill-opacity="0.85">from the authoritative server</text>
<rect x="30" y="66" width="300" height="66" rx="3" fill="var(--accent)" fill-opacity="0.12" stroke="var(--accent)" stroke-opacity="0.85" stroke-width="1.6"/>
<text x="44" y="88" font-size="10.5" fill="var(--accent)">flags: qr aa rd</text>
<text x="44" y="108" font-size="10">www.lab.example. 3600 IN A</text>
<text x="44" y="124" font-size="10">203.0.113.10</text>
<text x="30" y="152" font-size="9.5" fill-opacity="0.75">aa is set: this server holds the zone</text>
<text x="30" y="168" font-size="9.5" fill-opacity="0.75">3600 is what the zone says the record is worth</text>
<text x="390" y="56" font-size="10.5" fill-opacity="0.85">from a resolver, four seconds later</text>
<rect x="390" y="66" width="300" height="66" rx="3" fill="currentColor" fill-opacity="0.1" stroke="currentColor" stroke-opacity="0.6"/>
<text x="404" y="88" font-size="10.5">flags: qr rd ra</text>
<text x="404" y="108" font-size="10">www.lab.example. 3596 IN A</text>
<text x="404" y="124" font-size="10">203.0.113.10</text>
<text x="390" y="152" font-size="9.5" fill-opacity="0.75">no aa: this is a copy</text>
<text x="390" y="168" font-size="9.5" fill-opacity="0.75">3596 is what is left of it</text>
<text x="30" y="204" font-size="10.5">the copy is discarded at zero and fetched again</text>
<text x="30" y="224" font-size="10.5" fill="var(--red)">until then a change at the zone is invisible to anybody holding one</text>
</g></svg>
<figcaption>Two fields carry the whole of caching. The authoritative answer flag says this server holds the zone rather than a copy of it, and its absence is what makes every answer from a resolver a non-authoritative answer, which is the phrase people have seen in nslookup output for years without anybody explaining it. The time to live is the number that decides how long everybody else may keep what they were given, and it is counted down by whoever is holding the copy rather than reset on each use. The practical consequence is the one that costs an afternoon: after you change a record, every resolver that already asked keeps handing out the old value until its copy runs out, and there is nothing you can do from your side to make that happen sooner.</figcaption>
</figure>

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology dns-web
# commands run on client
# the resolver has never been asked this before
$ dig @10.0.0.4 www.lab.example A | grep -E "^www|Query time"
www.lab.example.	3600	IN	A	203.0.113.10
;; Query time: 3 msec
$ sleep 4
# four seconds later, from the same resolver
$ dig @10.0.0.4 www.lab.example A | grep -E "^www|Query time"
www.lab.example.	3596	IN	A	203.0.113.10
;; Query time: 0 msec
# the same question to the server that owns the zone
$ dig @10.0.0.3 www.lab.example A | grep -E "^;; flags"
;; flags: qr aa rd; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1
# and to the resolver, which is handing back a copy of somebody else answer
$ dig @10.0.0.4 www.lab.example A | grep -E "^;; flags"
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1
# a name that does not exist anywhere
$ dig @10.0.0.4 nothere.lab.example A | grep -E "status:|^lab.example"
;; ->>HEADER<<- opcode: QUERY, status: NXDOMAIN, id: 22557
lab.example.		900	IN	SOA	ns.lab.example. hostmaster.lab.example. 2026081201 7200 3600 1209600 900
```

The first answer took three milliseconds because the resolver had to do the walk.
The second took none, because it already had the answer, and the record came back
saying 3596 rather than 3600.

**That countdown is the whole mechanism.** A record with a TTL of 3600 can be four
seconds old or fifty nine minutes old when you receive it, and nothing in the
answer says which. Lowering the value before a planned change is the standard
practice for exactly that reason: set it to 300 a day in advance, make the change,
and put it back afterwards.

The last block is the negative case, and it is the part people do not expect.

<details class="deeper">
<summary>If you already chase caching problems: the three caches between a user and the answer</summary>

Asking twice shows one caching layer and there are at least three between a person and
an authoritative server, which is why a change that has definitely propagated is still
not visible on somebody's laptop.

The resolver's cache is the one people think of, and it honours the record's lifetime.
The operating system on the client keeps its own, and on some platforms it does not
honour that lifetime in the way you would expect. And the application, particularly a
browser, keeps a third, with its own rules and a floor that can outlast a short record
lifetime entirely.

So the sequence for testing a change is bottom up rather than top down: query the
authoritative server directly, then the resolver, then the machine, then the
application. Each step that still shows the old value tells you which cache to clear,
and clearing them in the wrong order proves nothing because the layer above refills the
one below.

The lesson for planning a change is to lower the record's lifetime well before the
change rather than at the same time. Lowering it at the moment of the change does
nothing for anybody already holding a copy under the old, longer lifetime, which is
exactly the population you were worried about.

</details>

## When the answer is no

A name that does not exist produces `NXDOMAIN`, and the answer carries the zone's
start of authority record in its authority section. That is not decoration. RFC
2308 says the minimum field in that record is how long the failure may be cached,
so a lookup that failed is remembered as a failure for a period the zone's owner
chose.

In the capture that value is 900, so a mistyped name is remembered as
non-existent for fifteen minutes even after somebody creates it. This is a real
support call: a record is added, the person who reported the problem still cannot
reach it, and everybody else can. The difference is which resolver each of them
uses and whether it happened to ask during the window.

**It also answers the question at the top of this page.** `ping example.com` fails
instantly because the failure is local: the stub resolver either had no resolver
configured to ask, or asked and got a definite no. Neither involves a timeout. A
name that fails after several seconds is a different fault, one where something
was asked and did not answer, and the difference between an instant failure and a
slow one is the most useful free diagnostic in this topic.

<details class="deeper">
<summary>If you already work on networks: what the hosts file does to the order, why a resolver caches a referral as well as an answer, and where the thirteen came from</summary>

**The hosts file comes first**, on all three platforms, and it is not part of DNS
at all. The resolver library consults it before sending anything, which makes it
both the fastest way to test a change and the most durable way to create a fault
nobody can find. An entry in it is invisible to every diagnostic that asks a
server, including `dig`, which is why a machine can insist on an address that no
DNS server anywhere is handing out. Checking it is worth doing early on any
single-machine name fault, and `dig` versus `ping` disagreeing is close to a
fingerprint for it.

**A resolver caches referrals as well as answers**, which is what stops the root
being asked for anything twice. Look at the trace again: the delegation records
have their own TTL, so once a resolver knows which servers handle `example.` it
goes straight to them for months. In practice a busy resolver almost never talks
to a root server, and the root serves a query rate far below what the number of
lookups on the internet would suggest.

That has a diagnostic consequence. A resolver holding a stale delegation will keep
asking the wrong name servers after a domain moves to a new provider, which
produces a domain that resolves correctly from most of the internet and fails from
one network for as long as the NS record's TTL. Nothing at the zone can shorten
that, because the copy being used was handed out before the change.

**On the thirteen.** The number is a consequence of arithmetic rather than
design intent. A DNS response over UDP was originally limited to 512 bytes, and
the list of root servers with their addresses had to fit inside one, which put the
ceiling at thirteen names. The limitation has long since gone, and the number has
stayed because changing it would mean changing the root hints file on every
resolver in the world for no benefit. Meanwhile the actual number of machines grew
without touching it, because anycast lets one address be many servers.

</details>

## Across platforms

Every machine has three things worth checking when a name will not resolve: which
resolver it asks, what it already believes, and whether the hosts file is in the
way.

**On Linux**, the resolver configuration is in `/etc/resolv.conf`, though on most
current systems that file is generated by something else, and the hosts file is
`/etc/hosts`. Most Linux systems keep no cache in the stub resolver itself, so
what you see is what the resolver said.

**On macOS**, the configuration lives somewhere less obvious.

```bash
# macOS 26.5.2, arm64
$ scutil --dns | grep -E "resolver #1|nameserver|search domain" | head -6
resolver #1
  nameserver[0] : 192.168.64.1
resolver #1
  nameserver[0] : 192.168.64.1

# The file consulted before any of that, and the entries it always carries
$ grep -vE "^#|^$" /etc/hosts | head -5
127.0.0.1	localhost
255.255.255.255	broadcasthost
::1             localhost
192.168.64.11 iad20-eo1211-351fb571-9590-4b92-b87a-b4a612b49e88-8A88039F2FA6.local iad20-eo1211-351fb571-9590-4b92-b87a-b4a612b49e88-8A88039F2FA6

# Resolving a name through the system rather than by talking to a server
$ dscacheutil -q host -a name example.com
name: example.com
ipv6_address: 2606:4700:10::ac42:93f3
ipv6_address: 2606:4700:10::6814:179a

name: example.com
ip_address: 172.66.147.243
ip_address: 104.20.23.154

```

`/etc/resolv.conf` exists on macOS and is not the authority; `scutil --dns` is,
and it shows a separate resolver configuration per interface and per search
domain, which is how a VPN sends some names one way and the rest another.
`dscacheutil` asks the system the way an application would, hosts file included,
rather than talking to a server.

**On Windows**, there is a client-side cache with a countdown of its own.

```powershell
# Microsoft Windows Server 2025 Datacenter, version 10.0.26100.0
> Get-DnsClientServerAddress -AddressFamily IPv4 | Where-Object ServerAddresses | Format-Table InterfaceAlias, ServerAddresses -AutoSize
InterfaceAlias ServerAddresses
-------------- ---------------
Ethernet 3     {168.63.129.16}

# The file consulted before any of that
> Get-Content "$env:SystemRoot\System32\drivers\etc\hosts" | Select-String -NotMatch "^#|^$" | Select-Object -First 3
10.1.0.101 runnervm7vqe0.5hgwdkdzwbtu1adlnb4fab40uf.ex.internal.cloudapp.net runnervm7vqe0

# What the machine already knows, with its own countdown per entry
> Resolve-DnsName example.com -Type A | Format-Table Name, Type, TTL, IPAddress -AutoSize
Name        Type TTL IPAddress
----        ---- --- ---------
example.com    A 263 172.66.147.243
example.com    A 263 104.20.23.154

> Get-DnsClientCache -Entry example.com | Format-Table Entry, RecordName, TimeToLive, Data -AutoSize
Entry       RecordName TimeToLive Data
-----       ---------- ---------- ----
example.com                   263 172.66.147.243
example.com                   263 104.20.23.154
example.com                   603 hera.ns.cloudflare.com
example.com                   603 elliott.ns.cloudflare.com
example.com                   603 173.245.58.162
example.com                   603 108.162.192.162
example.com                   603 172.64.32.162
example.com                   603 108.162.195.228
example.com                   603 162.159.44.228
example.com                   603 172.64.35.228
example.com                   259 . 0
```

That cache is the reason a Windows machine can behave differently from the one
next to it after a DNS change, and it is why `ipconfig /flushdns` is such a common
first move. The listing also shows something the earlier figure describes:
alongside the addresses are the name server records and their addresses, which is
the cached delegation, and an entry with a data field of `.` which is a remembered
failure.

## Prove it

**Trace a real name.** `dig +trace` any domain you use and count the referrals. It
is the fastest way to see that the root knows nothing about the name you asked
for.

**Watch a TTL count down.** Ask a resolver the same question twice with a pause
between, and compare the numbers. Then ask the authoritative server directly and
watch it return the full value every time.

**Find the hosts file on the machine in front of you.** Then check whether
anything has been added to it, because on a machine that has been in use for a
while the answer is sometimes yes.

## What trips people up

### 1. Thinking the root servers know where things are

They know who handles each top level name and nothing else. Every referral in a
trace is a server saying it cannot help and naming somebody who might.

### 2. Reading recursive and iterative as two systems

They are two kinds of query in one exchange. Your machine sends a recursive query
and the resolver sends iterative ones, which is why one machine sees one round
trip and something else did four.

### 3. Expecting a DNS change to take effect immediately

Every resolver holding a copy keeps handing it out until the time to live runs
down. Lowering the value in advance is the only lever, and it has to be pulled
before the change rather than during it.

### 4. Missing the authoritative answer flag

An answer from a resolver is a copy. The flag is how you tell, and its absence is
what nslookup has been calling a non-authoritative answer all along.

### 5. Forgetting that failures are cached too

A name that does not exist is remembered as not existing, for the period in the
zone's start of authority record. Creating the record does not clear that.

### 6. Ignoring the hosts file

It is consulted before anything is sent, so it can produce an address no server
anywhere is publishing, and it is invisible to every tool that queries a server.

## Work it through

The machine that can ping an address and not a name.

The first thing this tells you is which half of the system to look at, and that is
worth saying because it is most of the value. Reaching 1.1.1.1 proves the
interface, the address, the gateway and routing all work. Everything below layer 4
is fine, and any time spent on cables or switches is wasted.

**The instant failure is the second clue.** Resolution that fails because nothing
answered takes seconds, because the resolver library waits and retries. An
immediate failure means a definite answer arrived, or no question was ever asked.
So there are three candidates and they separate quickly.

There may be no resolver configured at all, which is the case when a machine ended
up with a link-local address after DHCP failed, and topic 42's exhaustion story is
one route to that. Check what the machine thinks its resolver is before anything
else.

There may be a resolver configured that is refusing. A resolver reachable but
unwilling to answer for you, because you are outside the networks it serves,
returns a refusal rather than nothing, and that is instant too.

Or the name genuinely does not exist, including the case where it exists and you
have typed it slightly wrong. `dig` distinguishes all three by name: `NXDOMAIN`
for a name that does not exist, `REFUSED` for a server declining, and a timeout
for silence.

**Then there is the case that is none of those**, and it is worth knowing because
it wastes the most time. If `dig` resolves the name and `ping` still fails, the
two are not consulting the same thing. `dig` talks to a server and `ping` uses the
system resolver library, which reads the hosts file first. A stale entry there
resolves the contradiction and nothing else does.

## Try it

**Trace the same name from two networks.** Home and work, or a phone on mobile
data. The referral chain will be identical and the addresses of the servers
answering may not, which is anycast doing its job.

**Set a low TTL before a change.** On any domain you control, lower it to 300 a
day ahead, make the change, and see how quickly it propagates compared with your
usual value. Then put it back.

**Ask for a name that does not exist, twice.** Watch the second failure arrive
faster than the first, and read the SOA in the authority section to see how long
the failure is being kept.

## Check yourself

<details class="qa">
<summary>A machine can ping 1.1.1.1 but not example.com, and the failure is instant. What does each of those two facts tell you?</summary>

Reaching the address proves the interface, addressing, gateway and routing all
work, so the fault is in name resolution rather than anywhere below it.

The failure being instant means a definite answer came back, or no question was
sent. Resolution that fails because nothing answered takes seconds while the
resolver retries, so an immediate failure points at no resolver configured, a
resolver refusing to serve this client, or a name that genuinely does not exist.

</details>

<details class="qa">
<summary>What is the difference between a recursive query and an iterative one, and who sends each?</summary>

A recursive query asks for a final answer and says not to reply with a referral.
Your machine sends these to its configured resolver, which is why it sees one
exchange.

Iterative queries are what the resolver then sends. Each server answers with what
it holds, which is usually the name of another server closer to the answer, and
the resolver follows the chain. The root and the top level servers only ever
answer this way.

</details>

<details class="qa">
<summary>A DNS record was changed two hours ago and some users still reach the old address. Why, and what could have been done in advance?</summary>

Every resolver that asked before the change is holding a copy, and it keeps
handing that copy out until the record's time to live runs down. The number is
counted from when the copy was taken, so different resolvers expire at different
moments and users see the change at different times.

Nothing at the authoritative server can shorten a copy that has already been
handed out. The lever is to lower the time to live a day ahead of the change and
raise it again afterwards.

</details>

<details class="qa">
<summary>How can you tell whether an answer came from a server that owns the record?</summary>

The authoritative answer flag. It is set when the responding server holds the zone
and absent when the answer is a copy, which is every answer a recursive resolver
gives you.

That flag is what nslookup is reporting when it prints "non-authoritative answer".
It says nothing about whether the answer is correct, only about whether you are
talking to the source or to somebody who asked the source earlier.

</details>

<details class="qa">
<summary>A record was created ten minutes ago and one user still gets "no such name" while everyone else is fine. What is happening?</summary>

Negative caching. When their resolver asked before the record existed, it received
NXDOMAIN with the zone's start of authority record in the authority section, and
the minimum field in that record says how long the failure may be kept.

So their resolver is remembering that the name does not exist, for a period the
zone's owner chose, and it will not ask again until that runs out. Everybody whose
resolver did not ask during the gap is unaffected.

</details>

## References

- [RFC 1034](https://www.rfc-editor.org/rfc/rfc1034) - IETF, the concepts, including zones, delegation and the two query modes. Free. Accessed 2026-08-12.
- [RFC 1035](https://www.rfc-editor.org/rfc/rfc1035) - IETF, the message format, the header flags and the 512 byte UDP limit. Free. Accessed 2026-08-12.
- [RFC 2308](https://www.rfc-editor.org/rfc/rfc2308) - IETF, negative caching, and the use of the SOA minimum field to bound it. Free. Accessed 2026-08-12.
- [root-servers.org](https://root-servers.org/) - The operators of the root servers, for the number of letters and the number of instances behind them. Accessed 2026-08-12.
- [dig(1)](https://bind9.readthedocs.io/en/latest/manpages.html) - ISC, for the trace mode used on this page. Accessed 2026-08-12.

**Pictures.** A freely licensed file from Wikimedia Commons, downloaded and served
from this site rather than linked across to somebody else's server. Resized and
otherwise unaltered.

- [The AMS-IX mirror of the K root-server](https://commons.wikimedia.org/wiki/File:Ams-ix.k.root-servers.net.jpg) by Bas van Schaik, [CC BY-SA 3.0](https://creativecommons.org/licenses/by-sa/3.0/).

**Where the output came from.** The Linux blocks ran on the `dns-web` namespace
topology through `blog/scripts/netlab.sh`, which builds a complete name hierarchy
rather than pointing at the real one: a root server that delegates `example.`, a
server for `example.` that delegates `lab.example.`, an authoritative server for
that zone, and a recursive resolver whose root hints file names our root instead
of the real thirteen. That is what makes the trace genuine and short enough to
read. The zone is under `example.`, which RFC 2606 reserves for exactly this, and
every address in it is from a documentation range. The Windows and macOS blocks
came from GitHub Actions runners through `blog/scripts/hostcap.sh` and query
`example.com`, which IANA operates for documentation use.

**If you also work on Linux.** [Common network services](/learn/linux-plus/common-network-services)
on the Linux+ track covers running a resolver rather than querying one, including
the configuration files behind the behaviour on this page.
