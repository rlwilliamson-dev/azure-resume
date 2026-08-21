---
title: "How the internet is glued together"
description: "Your router knows how to reach a server in Tokyo and nobody told it. Autonomous systems, the three relationships every network has with its neighbours, why an announcement is a claim rather than a fact, and what the signing system built to check those claims does and does not cover."
deck: "Nobody told your router where Tokyo is"
track: "network-plus"
level: "working"
order: 800
beyondExam: true
objectives:
  - "Say what an autonomous system is and where its number comes from"
  - "Tell transit, peering and an exchange apart by what each network accepts"
  - "Explain why a more specific announcement wins, and what that makes possible"
  - "Read a route origin validation result and say what it checked"
  - "Name what origin validation does not cover, and what a route leak is"
prerequisites: ["dynamic-routing-protocols", "route-selection"]
tags: ["network-plus", "networking", "routing", "security", "beyond-the-exam"]
updated: 2026-08-20
draft: false
examObjectives: []
sources:
  - title: "RFC 4271, A Border Gateway Protocol 4 (BGP-4)"
    url: "https://www.rfc-editor.org/rfc/rfc4271"
    publisher: "IETF"
    accessed: 2026-08-20
    tier: 1
  - title: "RFC 6480, An Infrastructure to Support Secure Internet Routing"
    url: "https://www.rfc-editor.org/rfc/rfc6480"
    publisher: "IETF"
    accessed: 2026-08-20
    tier: 1
  - title: "RFC 6482, A Profile for Route Origin Authorizations (ROAs)"
    url: "https://www.rfc-editor.org/rfc/rfc6482"
    publisher: "IETF"
    accessed: 2026-08-20
    tier: 1
  - title: "RFC 6811, BGP Prefix Origin Validation"
    url: "https://www.rfc-editor.org/rfc/rfc6811"
    publisher: "IETF"
    accessed: 2026-08-20
    tier: 1
  - title: "RFC 7908, Problem Definition and Classification of BGP Route Leaks"
    url: "https://www.rfc-editor.org/rfc/rfc7908"
    publisher: "IETF"
    accessed: 2026-08-20
    tier: 1
  - title: "RIPEstat data API"
    url: "https://stat.ripe.net/docs/data_api"
    publisher: "RIPE NCC"
    accessed: 2026-08-20
    tier: 1
  - title: "Team Cymru IP to ASN mapping service"
    url: "https://team-cymru.com/community-services/ip-asn-mapping/"
    publisher: "Team Cymru"
    accessed: 2026-08-20
    tier: 2
  - title: "Is BGP safe yet?"
    url: "https://isbgpsafeyet.com/"
    publisher: "Cloudflare"
    accessed: 2026-08-20
    tier: 2
symptoms:
  - symptom: "Traffic to a service takes a route through a country it has no business being in"
    anchor: "an-announcement-is-a-claim"
  - symptom: "A prefix stops being reachable from some networks and not others"
    anchor: "what-origin-validation-checks"
---

> **Before you read.** Your laptop can reach a server in Tokyo. The router in
> your building has no idea where Tokyo is, was never configured with a route to
> it, and belongs to an organisation with no relationship to anybody in Japan.
>
> **Who told it, and why should it be believed?**

Topic 22 named BGP as the exterior routing protocol and moved on, which is the
right depth for the exam: the objectives name the protocol and never ask what it
carries. What follows is the layer underneath every outage postmortem you will
ever read, and none of it is examinable.

### Some words you will need

<dl class="terms">
<dt>autonomous system</dt>
<dd>A network under one administration with one routing policy. Abbreviated AS.</dd>
<dt>AS number</dt>
<dd>The number that identifies one. Handed out by the regional registries, and public.</dd>
<dt>prefix</dt>
<dd>A block of addresses announced as a unit, written as an address and a length.</dd>
<dt>transit</dt>
<dd>Paying another network to carry your traffic to everywhere it can reach.</dd>
<dt>peering</dt>
<dd>Two networks exchanging their own traffic directly, usually without money changing hands.</dd>
<dt>internet exchange</dt>
<dd>A shared switch fabric where many networks meet in one building to peer cheaply.</dd>
<dt>ROA</dt>
<dd>Route origin authorisation. A signed statement that a named AS may announce a named prefix.</dd>
<dt>route leak</dt>
<dd>Announcing routes to a neighbour who should never have received them, usually by accident.</dd>
</dl>

## What breaks without this

**Outage reports are unreadable.** The published account of most large internet
failures is written in this vocabulary, and without it the interesting part reads
as noise.

**A whole class of fault is invisible.** When traffic to your own service starts
taking a strange path, or half the world can reach you and half cannot, nothing on
your own network is wrong and nothing on your own network will tell you.

**Provider choices get made on price alone.** Transit and peering are different
products with different failure modes, and a network with one upstream has a
single point of failure that no amount of internal redundancy addresses.

## Eighty seven thousand networks agreeing

There is no map of the internet and no authority that publishes one. There are
independent networks, each with its own policy, telling their neighbours which
addresses they can reach and listening to the same from them.

```bash
# Debian 13 (trixie), x86_64
$ curl -s "https://stat.ripe.net/data/ris-asns/data.json?list_asns=false" | jq -r "\"autonomous systems seen in the global routing table: \" + (.data.counts.total|tostring)"
autonomous systems seen in the global routing table: 87710
```

Each of those is an autonomous system: one network, one administration, one
routing policy. The number identifying it comes from IANA to one of the five
regional registries and from there to the network, and the whole allocation is
public, which means an AS number can be looked up as easily as a domain name.

```bash
# Debian 13 (trixie), x86_64
$ dig +short AS15169.asn.cymru.com TXT; dig +short AS2856.asn.cymru.com TXT; dig +short 8.8.8.8.origin.asn.cymru.com TXT
"15169 | US | arin | 2000-03-30 | GOOGLE - Google LLC, US"
"2856 | GB | ripencc | 1993-12-22 | BT-UK-AS - British Telecommunications Limited, GB"
"15169 | 8.8.8.0/24 | US | arin | 2023-12-28"
```

Three facts in three lines, and the third is the one that does the work. Given any
address on the internet you can find the prefix it belongs to and the autonomous
system announcing that prefix, which is the first step in every investigation in
this topic. The allocation dates are a bonus: BT holds a four digit number issued
in 1993 and Google a five digit one from 2000, and the size of an AS number is a
rough measure of how long its holder has been doing this.

<details class="deeper">
<summary>If you already work with registries: why the lookup above is DNS and not a database query</summary>

Team Cymru publishes the mapping through the DNS because the alternative does not
scale to the way it gets used. Origin lookups are wanted in bulk, by tools
annotating firewall logs or flow records with the network each address belongs to,
and a whois server answering a million of those a day would fall over.

Putting the answer in a TXT record means every caching resolver on the path
becomes part of the infrastructure. A common address is answered from a cache near
the asker, the authoritative servers see a fraction of the traffic, and the whole
thing costs what DNS costs. It is the same reasoning behind the block lists that
were distributed this way for decades.

There is a cost, and it is the one that follows every use of DNS as a database.
The answer is a string with fields separated by pipes, so it has no schema, no
types and no way to signal a partial result. Anything parsing it is parsing text
by position, which works until the day a field is added. That is the trade the
service made, and for a lookup this stable it has held for twenty years.

</details>

## Three relationships, and the difference is what you accept

A network's neighbours are not interchangeable. Each connection is a business
arrangement, and the arrangement determines which routes cross it.

The clearest way to see this is that networks publish their policy. The registries
hold an object per AS, and operators record in it what they accept from each
neighbour and what they announce to them.

<details class="predict">
<summary>One small Dutch network, and three of its neighbours: a transit provider it pays, a peer, and an exchange's route server. All three appear below. What in the policy separates them?</summary>

```bash
# Debian 13 (trixie), x86_64
$ whois -h whois.ripe.net -p 43 AS8283 2>/dev/null | grep -E "^mp-(import|export): +afi ipv4" | grep -E "AS8455|AS1200 |AS6777" | head -6
mp-import:      afi ipv4.unicast from AS8455 action pref=100; accept ANY
mp-export:      afi ipv4.unicast to AS8455 announce AS8283:AS-COLOCLUE
mp-import:      afi ipv4.unicast from AS1200 action pref=100; accept AS1200
mp-export:      afi ipv4.unicast to AS1200 announce AS8283:AS-COLOCLUE
mp-import:      afi ipv4.unicast from AS6777 action pref=100; accept AS6777:AS-AMS-IX-RS AS6777:AS-AMS-IX-RS-V6 AS6777:AS-AMS-IX-RS-SETS AS6777:AS-AMS-IX-RS-SETS-V6
mp-export:      afi ipv4.unicast to AS6777 announce AS8283:AS-COLOCLUE
```

</details>

Read the import lines and the answer is there. From AS8455, a transit provider,
this network accepts `ANY`: give me everything you know, which is what transit is
and what the invoice is for. From AS1200 it accepts `AS1200` and nothing else,
which is a peer handing over its own routes and no more. From AS6777 it accepts a
set of route sets belonging to an exchange's route server, which is one session
that delivers the routes of everyone else on that exchange.

Now read the export lines. All three are identical: this network announces its own
address space to everybody and nothing else to anybody.

<figure class="learn-figure">
<svg viewBox="0 0 720 214" role="img" aria-labelledby="rel-title" style="width:100%;height:auto;">
<title id="rel-title">A grid of three neighbour types against what a network accepts from each and announces to each, where the accept row differs for every column and the announce row is the same across all three</title>
<g fill="currentColor">
<text x="14" y="24" font-size="11">the same network, three neighbours</text>
<text x="196" y="56" text-anchor="middle" font-size="10.5">transit provider</text>
<text x="382" y="56" text-anchor="middle" font-size="10.5">peer</text>
<text x="568" y="56" text-anchor="middle" font-size="10.5">exchange route server</text>
<text x="14" y="92" font-size="10.5" fill="var(--accent)">I accept</text>
<rect x="110" y="70" width="172" height="32" rx="3" fill="var(--accent)" fill-opacity="0.16" stroke="var(--accent)" stroke-width="1.4"/>
<text x="196" y="91" text-anchor="middle" font-size="10.5" fill="var(--accent)">everything they know</text>
<rect x="296" y="70" width="172" height="32" rx="3" fill="var(--accent)" fill-opacity="0.16" stroke="var(--accent)" stroke-width="1.4"/>
<text x="382" y="91" text-anchor="middle" font-size="10.5" fill="var(--accent)">their own routes</text>
<rect x="482" y="70" width="172" height="32" rx="3" fill="var(--accent)" fill-opacity="0.16" stroke="var(--accent)" stroke-width="1.4"/>
<text x="568" y="91" text-anchor="middle" font-size="10.5" fill="var(--accent)">everyone on that fabric</text>
<text x="14" y="140" font-size="10.5">I announce</text>
<rect x="110" y="118" width="172" height="32" rx="3" fill="currentColor" fill-opacity="0.07" stroke="currentColor" stroke-opacity="0.4"/>
<text x="196" y="139" text-anchor="middle" font-size="10.5">my own address space</text>
<rect x="296" y="118" width="172" height="32" rx="3" fill="currentColor" fill-opacity="0.07" stroke="currentColor" stroke-opacity="0.4"/>
<text x="382" y="139" text-anchor="middle" font-size="10.5">my own address space</text>
<rect x="482" y="118" width="172" height="32" rx="3" fill="currentColor" fill-opacity="0.07" stroke="currentColor" stroke-opacity="0.4"/>
<text x="568" y="139" text-anchor="middle" font-size="10.5">my own address space</text>
<text x="14" y="186" font-size="10" fill-opacity="0.75">policy as published by AS8283 in the RIPE registry</text>
</g>
</svg>
<figcaption>The row that varies is the one that costs money. Accepting everything a neighbour knows is the definition of transit and is what the bill is for; accepting only their own routes is peering, and is normally free because the benefit is mutual. The row that does not vary is the discipline: announcing more than your own address space to a peer turns you into their transit provider by accident, for free, and that mistake has its own name later on this page.</figcaption>
</figure>

<details class="deeper">
<summary>If you already buy connectivity: why a network with one transit provider has a redundancy problem no amount of internal design fixes</summary>

Internal redundancy protects against your own equipment failing. A single transit
relationship means that when your provider has a bad day, or fat-fingers a filter
that stops accepting your announcements, you are off the internet and every
redundant switch you own is working perfectly.

The usual answer is a second transit provider, and it costs more than twice as
much in practice, because the second one has to be big enough to carry everything
alone and because running two makes your own routing more complicated. The
alternative that mature networks reach for is peering at an exchange, which
displaces traffic off the transit link rather than replacing it, and gets cheaper
per bit as it grows rather than more expensive.

That is the actual economic shape of the internet, and it explains a fact people
find surprising: large content networks connect to hundreds of others directly and
buy very little transit, while a small business network buys transit from one
provider and peers with nobody. Both are rational. What is not rational, and is
common, is a network large enough to be hurt by an outage buying from one provider
because the second quote looked like a duplicate cost.

</details>

## An announcement is a claim

Nothing in the protocol establishes that a network is entitled to the addresses it
announces. A router hears a prefix from a neighbour, applies whatever filters its
operator configured, and if it passes, believes it and tells its own neighbours.
That is the whole mechanism, and it worked for decades on the basis that the
operators knew each other.

Two properties make the consequences worse than a naive reading suggests.

**Forwarding prefers the most specific match.** A router with a route to
203.0.113.0/24 and another to 203.0.113.0/25 sends anything in the smaller range
by the smaller route, and no comparison of path length or origin is involved.
Announcing a piece of somebody else's block, cut finer than they announce it,
therefore wins everywhere the announcement is accepted.

**Acceptance spreads.** Once one large network takes the announcement, it passes
it on, and every network downstream of that one inherits it without ever having
made a decision.

<figure class="learn-figure">
<svg viewBox="0 0 720 226" role="img" aria-labelledby="hijack-title" style="width:100%;height:auto;">
<title id="hijack-title">Two announcements for overlapping address space, a slash twenty-four from its rightful holder and a slash twenty-five from another network, with a router choosing the longer prefix for the addresses both cover</title>
<g fill="currentColor">
<text x="14" y="24" font-size="11">two announcements, one address, and no authentication anywhere</text>
<rect x="14" y="58" width="212" height="44" rx="3" fill="currentColor" fill-opacity="0.08" stroke="currentColor" stroke-opacity="0.5"/>
<text x="120" y="78" text-anchor="middle" font-size="10.5">AS 64500 announces</text>
<text x="120" y="94" text-anchor="middle" font-size="10.5">203.0.113.0/24</text>
<rect x="14" y="130" width="212" height="44" rx="3" fill="var(--red)" fill-opacity="0.12" stroke="var(--red)" stroke-opacity="0.75" stroke-width="1.4"/>
<text x="120" y="150" text-anchor="middle" font-size="10.5" fill="var(--red)">AS 64501 announces</text>
<text x="120" y="166" text-anchor="middle" font-size="10.5" fill="var(--red)">203.0.113.0/25</text>
<line x1="226" y1="80" x2="330" y2="104" stroke="currentColor" stroke-opacity="0.45" stroke-width="1.4"/>
<line x1="226" y1="152" x2="330" y2="120" stroke="var(--red)" stroke-opacity="0.6" stroke-width="1.4"/>
<rect x="334" y="94" width="120" height="36" rx="3" fill="currentColor" fill-opacity="0.08" stroke="currentColor" stroke-opacity="0.5"/>
<text x="394" y="116" text-anchor="middle" font-size="10.5">a router</text>
<line x1="454" y1="112" x2="530" y2="112" stroke="var(--red)" stroke-opacity="0.6" stroke-width="1.4"/>
<text x="540" y="106" font-size="10.5">203.0.113.5 goes to</text>
<text x="540" y="122" font-size="10.5" fill="var(--red)">AS 64501</text>
<text x="14" y="204" font-size="10" fill-opacity="0.75">203.0.113.0/24 is the documentation range from RFC 5737, and both AS numbers are private</text>
</g>
</svg>
<figcaption>The longer prefix wins and nothing else is compared. Not who holds the addresses, and not the fact that a shorter announcement covering the same space says something different. That is the forwarding rule from topic 23 working exactly as specified, applied to a protocol with no way of establishing who owns what.</figcaption>
</figure>

## What origin validation checks

The system built to answer the ownership question is a signing infrastructure. The
holder of a block publishes a signed object, a route origin authorisation, which
says that a named autonomous system may announce a named prefix, up to a named
length. A router that validates compares each announcement it hears against the
set of those objects.

<details class="predict">
<summary>The same prefix checked twice: once against the network that really announces it, and once against a network that does not. What does each check return?</summary>

```bash
# Debian 13 (trixie), x86_64
$ R=https://stat.ripe.net/data/rpki-validation/data.json; curl -s "$R?resource=AS15169&prefix=8.8.8.0/24" | jq -r ".data.status"; curl -s "$R?resource=AS64500&prefix=8.8.8.0/24" | jq -r ".data.status, .data.validating_roas[0]"
valid
invalid_asn
{
  "origin": "15169",
  "prefix": "8.8.8.0/24",
  "validity": "invalid_asn",
  "max_length": 24
}
```

</details>

Two lookups, two answers, and the second one shows its working: there is a signed
object saying 8.8.8.0/24 belongs to AS15169 with a maximum length of 24, so an
announcement of that prefix from any other AS contradicts it. RFC 6811 defines
three outcomes, and it is worth knowing all three because the third is the common
one. Valid means a matching object was found. Invalid means an object covers this
prefix and disagrees. And not found means no object covers it at all, which is not
an accusation and cannot be treated as one.

**Two separate things have to happen and only one of them is common.** Publishing
an object protects nobody by itself; it is a statement sitting in a repository.
The protection arrives when other networks validate and discard what comes back
invalid, and a network that has not configured that continues to accept whatever
it is told. So the value of signing your own prefixes depends entirely on how many
other people do the checking, which is the shape of every security measure that
needs adoption to work.

<details class="deeper">
<summary>If you already sign your prefixes: the two ways a correctly published object still leaves you exposed</summary>

The first is the maximum length field, and it is the one that catches people. An
object authorising AS64500 to announce 203.0.113.0/24 with a maximum length of 24
means exactly that prefix. Publish it with a maximum length of 32 instead, which
looks generous and harmless, and you have authorised anybody announcing any piece
of that block as AS64500 to pass validation. The permissive setting undoes most of
the protection, and the guidance is to set the maximum to the length you actually
announce.

The second is more fundamental and no configuration fixes it. Origin validation
checks the origin, meaning the AS at the far end of the path. It does not check
the rest of the path, and it does not check whether the path is real. An attacker
who announces your prefix with your AS number in the origin position, and their
own AS in front of it, produces an announcement that validates perfectly and still
sends your traffic to them. Signing the path rather than the origin is the problem
a further set of work addresses, and it is not widely deployed.

What origin validation actually eliminates is the accident: the operator who
mistypes a prefix, the lab that announces a block it does not hold, the router
that reoriginates routes it should have passed along. Those are the majority of
incidents by count, which makes it worth doing, and it is not a solution to a
determined attacker.

</details>

## A leak is not a hijack

The other failure mode has nothing to do with ownership. Every announcement in a
leak is for addresses the originator genuinely holds, and every one of them is
sent somewhere it should not have gone.

The rule a network is supposed to follow is that routes learned from a transit
provider or a peer are announced only to its own customers, never to another
provider or peer. Break that rule, usually by deploying a router without the
filter that enforces it, and your network starts telling one large provider that
it can reach everything another large provider knows about. The announcement is
true. Your network really can reach those places, by paying its own provider to.
So traffic between two networks with hundreds of gigabits between them starts
flowing through yours, which has a fraction of that, and everybody's traffic stops
until somebody notices.

RFC 7908 catalogues the variants, and the reason it exists is that this has
happened often enough to need a taxonomy. It is also the reason the export
discipline in the figure earlier matters: announcing only your own address space,
to everybody, makes leaking structurally impossible rather than merely
discouraged.

## Across platforms

Every lookup on this page is `dig`, `whois`, or `curl` piped into `jq`, which is a
Linux reader's set of tools. Two of those ship with macOS and none of them ship
with Windows, so the same questions have three different answers.

| Task | Linux | Windows | macOS |
| --- | --- | --- | --- |
| Who holds an AS number | `dig +short ASnnnn.asn.cymru.com TXT` | `Resolve-DnsName -Type TXT` | `dig`, as Linux |
| Which prefix and origin an address has | the same, against `origin.asn.cymru.com` | the same cmdlet | `dig`, as Linux |
| Whether an announcement is authorised | `curl` piped into `jq` | `Invoke-RestMethod` | `curl` piped into `python3` |
| Read a network's published policy | `whois -h whois.ripe.net -p 43` | no client by default, so the registry's web interface | `whois` ships with the system |

**On Windows** the DNS lookups are a cmdlet rather than `dig`, and the validation
query is better off than either of the other two: `Invoke-RestMethod` parses the
JSON on the way in, so the answer is a property rather than something to pipe
through a parser.

```powershell
# Microsoft Windows Server 2025 Datacenter, version 10.0.26100.0
> Resolve-DnsName -Type TXT -Name AS15169.asn.cymru.com | Select-Object -ExpandProperty Strings
15169 | US | arin | 2000-03-30 | GOOGLE - Google LLC, US

# which prefix an address belongs to, and which AS announces it
> Resolve-DnsName -Type TXT -Name 8.8.8.8.origin.asn.cymru.com | Select-Object -ExpandProperty Strings
15169 | 8.8.8.0/24 | US | arin | 2023-12-28

# whether that announcement is authorised, from the RIPE data API
> (Invoke-RestMethod "https://stat.ripe.net/data/rpki-validation/data.json?resource=AS15169&prefix=8.8.8.0/24").data.status
valid
```

**On macOS** the first two commands are the Linux ones unchanged, because `dig`
and `curl` are both part of the system. Only the third differs, and only because
`jq` is not installed. Homebrew fixes that, and the `python3` already on the
machine does the same job for one field.

```bash
# macOS 26.5.2, arm64
$ dig +short AS15169.asn.cymru.com TXT
"15169 | US | arin | 2000-03-30 | GOOGLE - Google LLC, US"

# which prefix an address belongs to, and which AS announces it
$ dig +short 8.8.8.8.origin.asn.cymru.com TXT
"15169 | 8.8.8.0/24 | US | arin | 2023-12-28"

# whether that announcement is authorised, read without jq
$ curl -s "https://stat.ripe.net/data/rpki-validation/data.json?resource=AS15169&prefix=8.8.8.0/24" | python3 -c "import json,sys; print(json.load(sys.stdin)['data']['status'])"
valid
```

Two things in that table are worth carrying beyond this topic. The `whois -p 43`
is not decoration: a minimal Linux image often has no `/etc/services` entry for
the service name, and the client fails with an error about the service name
rather than about the network. And the Windows row is the one place in this track
where the Windows answer is the tidier of the three, which is worth saying out
loud in a track that mostly finds the opposite.

## Prove it

**Find the network behind an address you use.** Take any public address your
traffic goes to, reverse the octets onto `origin.asn.cymru.com`, and look up the
TXT record. You will get the prefix and the autonomous system announcing it. Doing
this for the services you depend on takes ten minutes and produces a map of who
actually carries your business.

**Check whether your own provider validates.** Cloudflare publishes a test page
that loads a resource from a deliberately invalid announcement. If your network
drops invalids, the resource fails to load, which is the correct outcome and is
worth confirming before you rely on signing anything.

**Read the three outcomes in the specification.** RFC 6811 defines valid, invalid
and not found. Read what it says about not found in particular, because the whole
argument about how aggressively to filter turns on the fact that most of the
routing table has historically been in that state.

## What trips people up

### 1. Thinking somebody is in charge

There is no authority that decides how traffic crosses the internet. There are
independent networks with commercial agreements, and the routing table is the
aggregate of what they have each decided to tell their neighbours.

### 2. Confusing transit with peering

Transit is a purchase of reachability to everywhere. Peering is an exchange of
each other's own traffic. A network that has peering with a large provider is not
buying transit from them, and it cannot reach that provider's customers' customers
through the peering session.

### 3. Reading a hijack as a protocol flaw

Choosing the most specific prefix is the forwarding rule working correctly. What
is missing is any check on whether the announcement was authorised, which is a
separate layer added later and still not universal.

### 4. Believing a ROA protects you on its own

Publishing an authorisation is a statement. It has an effect only where somebody
else is validating and dropping what fails, and a large part of the internet still
is not.

### 5. Setting a permissive maximum length

An authorisation with a maximum length longer than what you announce authorises
anybody to announce the smaller pieces as you. It looks like flexibility and it
gives away most of the protection.

### 6. Assuming validation covers the path

Origin validation checks the last AS in the path. Everything in front of it is
unverified, so an announcement can validate and still be an attack.

## Work it through

A company hosts its own mail on addresses it holds. One Tuesday, mail from three
large providers stops arriving, mail from everywhere else is fine, and every
internal check is green. The mail server is up, the firewall is passing, the
records resolve, and a test from a laptop on a home connection works.

The shape of that fault is the giveaway. Working from some networks and not others,
with nothing wrong at either end, is not a fault you can find from inside your own
estate, because your estate is not where it is happening.

Start by asking what those three providers have in common. If they are the three
that discard invalid announcements, and the others are not, then the difference is
validation, and the question becomes what changed about the company's
announcements or its authorisations. A ROA that expired, or one published with the
wrong maximum length after somebody started announcing a longer prefix for traffic
engineering, produces exactly this: the announcement is now invalid, and precisely
the networks doing the checking are the ones that stop believing it.

The second candidate is a hijack, and it is distinguishable. In a hijack the
addresses become reachable, just not by you, so mail does not fail so much as
disappear, and an origin lookup from outside shows an AS number that is not yours
announcing your prefix.

Either way the tools are the same and none of them are on your network. Look up
your own prefix from outside, check what origin is being seen for it, check the
validation state of your announcement, and look at a public route collector for
when the change happened. And the thing worth building before you need it is a
monitor that watches your own prefixes from the outside and tells you when the
origin or the validity changes, because the alternative is finding out from a
customer.

## Try it

**Look yourself up.** Find the prefix and origin for an address you own or use,
then check its validation state. Both are single commands and the second one
frequently surprises people who assumed their provider had done it.

**Read one published policy.** Pick any autonomous system and pull its registry
object. The import and export lines are the network's business relationships
written in a formal language, and reading one is the fastest way to make transit
and peering stop being abstract.

**Read a real postmortem.** Any large routing incident of the last decade has a
public account. With the vocabulary on this page, the interesting part becomes
readable: which announcement, accepted by whom, and what filter was missing.

## Check yourself

<details class="qa">
<summary>What separates a transit relationship from a peering relationship in a network's published policy?</summary>

What it accepts. From a transit provider it accepts everything that provider
knows, which is what the money buys. From a peer it accepts only that peer's own
routes. What it announces is the same to both: its own address space and nothing
else.

</details>

<details class="qa">
<summary>Why does announcing a /25 out of somebody else's /24 divert their traffic?</summary>

Forwarding always uses the most specific matching prefix, and nothing else is
compared. Any router that accepts the longer announcement will send matching
traffic that way regardless of who announced it or how far away they are.

</details>

<details class="qa">
<summary>A validation lookup returns not found. What has it established?</summary>

That no signed object covers that prefix, which is not evidence of anything being
wrong. Most announcements were in this state for years, so treating not found as
invalid would discard a large part of the internet.

</details>

<details class="qa">
<summary>An attacker announces your prefix with your AS number as the origin and their own in front of it. Does origin validation catch it?</summary>

No. Origin validation checks the AS at the end of the path against the signed
object, and that AS is yours, so the announcement validates. Everything in front
of the origin is unverified.

</details>

<details class="qa">
<summary>What makes a route leak different from a hijack?</summary>

Nobody is announcing addresses they do not hold. The announcements are all
truthful and have been sent to a neighbour that should not have received them,
usually because a filter was missing, and the result is traffic taking a path
through a network far too small to carry it.

</details>

## References

- [RFC 4271](https://www.rfc-editor.org/rfc/rfc4271) - IETF, the Border Gateway Protocol itself, for what an announcement contains and how it propagates. Free. Accessed 2026-08-20.
- [RFC 6480](https://www.rfc-editor.org/rfc/rfc6480) - IETF, the architecture of the resource public key infrastructure and how it follows the allocation hierarchy. Free. Accessed 2026-08-20.
- [RFC 6482](https://www.rfc-editor.org/rfc/rfc6482) - IETF, the route origin authorisation, including the maximum length field. Free. Accessed 2026-08-20.
- [RFC 6811](https://www.rfc-editor.org/rfc/rfc6811) - IETF, prefix origin validation and the three outcomes it defines. Free. Accessed 2026-08-20.
- [RFC 7908](https://www.rfc-editor.org/rfc/rfc7908) - IETF, the definition and classification of route leaks. Free. Accessed 2026-08-20.
- [RIPEstat data API](https://stat.ripe.net/docs/data_api) - RIPE NCC, the source of the autonomous system count and the validation lookups. Free. Accessed 2026-08-20.
- [Team Cymru IP to ASN mapping](https://team-cymru.com/community-services/ip-asn-mapping/) - Team Cymru, the DNS service used for the origin lookups. Free. Accessed 2026-08-20.
- [Is BGP safe yet?](https://isbgpsafeyet.com/) - Cloudflare, a test for whether your own provider discards invalid announcements. Free. Accessed 2026-08-20.

**Where the output came from.** Four captured blocks through `capture.sh` on the
image named in each header. The autonomous system count and the two validation
results are live queries to the RIPE NCC's public data API and are true as of the
date on this topic rather than permanently; the origin lookups are the Team Cymru
DNS service; the routing policy is the RIPE registry object AS8283 publishes about
itself. The example prefix in the hijack figure is the documentation range from
RFC 5737 and both AS numbers in it are from the private range, so nothing on this
page names a real network in an attack.

**Why this is not in the lesson count.** The objectives name BGP as one of three
exterior routing protocols and ask nothing about how the internet is organised.
None of this is examinable, and all of it is assumed by anybody discussing an
outage that happened outside your building.
