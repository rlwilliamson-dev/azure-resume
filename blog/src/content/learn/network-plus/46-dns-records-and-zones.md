---
title: "DNS records and zones"
description: "A record type is a question type, which is why moving a website and moving the mail are separate jobs. Plus the five numbers in the SOA, what a zone actually is, and the one place a CNAME is not allowed."
deck: "The website moved and email stopped"
track: "network-plus"
level: "working"
order: 470
objectives:
  - "Say what each record type the exam names is for"
  - "Explain why a zone is not the same thing as a domain"
  - "Read the five numeric fields of a start of authority record"
  - "Describe what a zone transfer is and why it is restricted"
  - "Say why a CNAME cannot sit at the top of a zone"
prerequisites: ["how-dns-resolution-works"]
tags: ["network-plus", "networking", "services"]
updated: 2026-08-12
draft: false
examObjectives:
  - exam: "n10-009"
    domain: "3.0"
    objective: "3.4"
sources:
  - title: "RFC 1035, Domain Names, Implementation and Specification"
    url: "https://www.rfc-editor.org/rfc/rfc1035"
    publisher: "IETF"
    accessed: 2026-08-12
    tier: 1
  - title: "RFC 1034, Domain Names, Concepts and Facilities"
    url: "https://www.rfc-editor.org/rfc/rfc1034"
    publisher: "IETF"
    accessed: 2026-08-12
    tier: 1
  - title: "RFC 5936, DNS Zone Transfer Protocol (AXFR)"
    url: "https://www.rfc-editor.org/rfc/rfc5936"
    publisher: "IETF"
    accessed: 2026-08-12
    tier: 1
  - title: "RFC 7505, A Null MX Resource Record for Domains That Accept No Mail"
    url: "https://www.rfc-editor.org/rfc/rfc7505"
    publisher: "IETF"
    accessed: 2026-08-12
    tier: 1
  - title: "RFC 3596, DNS Extensions to Support IP Version 6"
    url: "https://www.rfc-editor.org/rfc/rfc3596"
    publisher: "IETF"
    accessed: 2026-08-12
    tier: 1
symptoms:
  - symptom: "The website moved and mail stopped arriving"
    anchor: "one-name-two-questions"
  - symptom: "A zone will not load and the server says CNAME and other data"
    anchor: "the-one-place-a-cname-cannot-go"
  - symptom: "A secondary server is answering with records that were deleted"
    anchor: "five-numbers-and-a-contract"
---

> **Before you read.** A company moves its website to a new host. Somebody
> updates the record, the site comes up on the new server within the hour, and
> everybody is pleased.
>
> Two days later they notice that no email has arrived since the move.
>
> **What did changing that record do, and what did it fail to do?**

The record types are a memorisation task and they are also the thing that makes
the fault above obvious in advance. It is worth learning them as questions rather
than as a list, because that is what stops somebody assuming that a name has one
answer.

### Some words you will need

<dl class="terms">
<dt>zone</dt>
<dd>The part of the name tree one set of servers is responsible for.</dd>
<dt>delegation</dt>
<dd>Handing responsibility for a branch to somebody else's servers, with an NS record.</dd>
<dt>apex</dt>
<dd>The top of a zone. The name of the zone itself, written @ in a zone file.</dd>
<dt>primary</dt>
<dd>The server holding the copy of the zone somebody edits.</dd>
<dt>secondary</dt>
<dd>A server that copies the zone from the primary and answers for it.</dd>
<dt>zone transfer</dt>
<dd>The copy operation. AXFR for the whole zone, IXFR for the changes.</dd>
</dl>

## What breaks without this

**Mail stops and the website is fine.** Because they are answered by different
record types and only one of them was changed.

**A secondary keeps serving records that were deleted.** For as long as its
timers allow, which are numbers in the zone rather than settings on the server.

**A zone will not load at all** and the server reports something about CNAME and
other data, which is a specific and completely reasonable error nobody recognises
the first time.

## One name, two questions

The name is the same. What is being asked about it is not.

<figure class="learn-figure">
<svg viewBox="0 0 720 214" role="img" aria-labelledby="records-title" style="width:100%;height:auto;">
<title id="records-title">A browser asking for the A record of a name and a mail server asking for the MX record of the same name, arriving at two different hosts through two independent lookups</title>
<g fill="currentColor">
<text x="14" y="22" font-size="11">one name, two questions, two answers that are edited separately</text>
<rect x="270" y="106" width="170" height="42" rx="3" fill="var(--accent)" fill-opacity="0.14" stroke="var(--accent)" stroke-opacity="0.9" stroke-width="1.6"/>
<text x="355" y="132" text-anchor="middle" font-size="11" fill="var(--accent)">lab.example</text>
<rect x="20" y="52" width="120" height="38" rx="3" fill="currentColor" fill-opacity="0.1" stroke="currentColor" stroke-opacity="0.55"/>
<text x="80" y="76" text-anchor="middle" font-size="10.5">a browser</text>
<rect x="20" y="164" width="120" height="38" rx="3" fill="currentColor" fill-opacity="0.1" stroke="currentColor" stroke-opacity="0.55"/>
<text x="80" y="188" text-anchor="middle" font-size="10.5">a mail server</text>
<line x1="140" y1="76" x2="264" y2="112" stroke="currentColor" stroke-opacity="0.6" stroke-width="1.6"/>
<text x="196" y="84" text-anchor="middle" font-size="9.5" fill-opacity="0.8">A?</text>
<line x1="140" y1="184" x2="264" y2="146" stroke="currentColor" stroke-opacity="0.6" stroke-width="1.6"/>
<text x="196" y="180" text-anchor="middle" font-size="9.5" fill-opacity="0.8">MX?</text>
<line x1="440" y1="112" x2="556" y2="76" stroke="currentColor" stroke-opacity="0.6" stroke-width="1.6"/>
<path d="M 562 74 l -9 -1 l 4 9 z" fill="currentColor" fill-opacity="0.8"/>
<rect x="566" y="52" width="140" height="38" rx="3" fill="currentColor" fill-opacity="0.1" stroke="currentColor" stroke-opacity="0.55"/>
<text x="636" y="70" text-anchor="middle" font-size="10">203.0.113.10</text>
<text x="636" y="84" text-anchor="middle" font-size="9.5" fill-opacity="0.7">the web server</text>
<line x1="440" y1="146" x2="556" y2="182" stroke="currentColor" stroke-opacity="0.6" stroke-width="1.6"/>
<path d="M 562 184 l -9 1 l 4 -9 z" fill="currentColor" fill-opacity="0.8"/>
<rect x="566" y="164" width="140" height="38" rx="3" fill="currentColor" fill-opacity="0.1" stroke="currentColor" stroke-opacity="0.55"/>
<text x="636" y="182" text-anchor="middle" font-size="10">mail.lab.example</text>
<text x="636" y="196" text-anchor="middle" font-size="9.5" fill-opacity="0.7">then its own A lookup</text>
<text x="270" y="176" font-size="9.5" fill-opacity="0.75">the MX answer is a name,</text>
<text x="270" y="192" font-size="9.5" fill-opacity="0.75">so mail costs two lookups</text>
</g></svg>
<figcaption>This is the fault at the top of the page, drawn. The two lookups share a name and nothing else: they ask for different record types, the answers are separate records that somebody edits separately, and neither one is derived from the other. So changing the A record moves the website and leaves the mail exactly where it was, which is fine if the mail server did not move and a disaster if the old host has been switched off. Notice also that the MX answer is a name rather than an address, which is deliberate. It means mail costs a second lookup, and it means an organisation can move its mail by editing the A record of that name without touching the MX at all.</figcaption>
</figure>

The record types the exam names, as questions:

**A** asks what address this name has, in IPv4. **AAAA** asks the same in IPv6,
and they are separate records, so a name can have one, the other, or both.

**CNAME** says this name is another name. Everything about the target applies,
which is what makes it useful and what makes it dangerous.

**MX** asks where mail for this domain goes, and answers with a name and a
preference number, lower being preferred.

**NS** names the servers responsible for a zone. It is what creates a delegation.

**PTR** goes the other way: given an address, what name claims it. It lives in a
completely different zone.

**TXT** carries arbitrary text, which in practice means mail policy, domain
ownership proofs, and anything else nobody defined a record type for.

**SOA** sits at the top of every zone and carries the parameters that govern it.
The acronym list includes it and objective 3.4 enumerates record types without it,
which is worth knowing when you are deciding how much time to give it.

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology dns-web
# commands run on client
# the record at the top of the zone, which every zone has to have
$ dig @10.0.0.3 lab.example SOA +noall +answer
lab.example.		3600	IN	SOA	ns.lab.example. hostmaster.lab.example. 2026081201 7200 3600 1209600 900
# where mail for the zone goes, and the name it points at
$ dig @10.0.0.3 lab.example MX +noall +answer
lab.example.		3600	IN	MX	10 mail.lab.example.
$ dig @10.0.0.3 lab.example TXT +noall +answer
lab.example.		3600	IN	TXT	"v=spf1 mx -all"
# an alias, and what the resolver does about it without being asked
$ dig @10.0.0.3 shop.lab.example A +noall +answer
shop.lab.example.	3600	IN	CNAME	www.lab.example.
www.lab.example.	3600	IN	A	203.0.113.10
# the same host in both families
$ dig @10.0.0.3 www.lab.example AAAA +noall +answer
www.lab.example.	3600	IN	AAAA	2001:db8:113::10
# and the other direction, which is a different zone entirely
$ dig @10.0.0.3 -x 203.0.113.10 +noall +answer
10.113.0.203.in-addr.arpa. 3600	IN	PTR	www.lab.example.
```

Two things in that output repay a second look.

**The CNAME query returned two records.** Asking for the A record of
`shop.lab.example` produced the CNAME and then the A record of what it points at,
without a second question being asked, because the server followed the alias
itself and returned both. That is why a CNAME is convenient and why a chain of
them is expensive.

**The PTR lookup asked a completely different name.** `dig -x 203.0.113.10`
becomes a question about `10.113.0.203.in-addr.arpa`, which is the address
reversed with a suffix. The reverse tree is a separate hierarchy delegated by
whoever owns the address block, which is normally an ISP rather than you. That is
the reason you can set a domain's A record in five minutes and cannot set its PTR
without asking somebody.

<details class="deeper">
<summary>If you already manage records: the two record types that quietly go stale</summary>

Most record types are noticed when they break. Two are not, and both cause problems that
look like something else.

The first is a name pointing at an address that has been reassigned. Nothing fails at the
moment the service moves, because the record still resolves, and it resolves to whatever
now lives at that address. On a cloud provider that address may belong to somebody else
within the hour, which turns a forgotten record into a name you own pointing at a
stranger's server. Removing records when a service is decommissioned belongs in the
process topic 37 covers, and it is the step most often skipped.

The second is the reverse record. Forward and reverse are separate records in separate
zones, frequently maintained by different people, and nothing keeps them consistent. A
mismatch is invisible until something checks it, and the things that check it are mail
servers and some logging systems, so the symptom arrives as mail being rejected weeks
after an address changed.

The habit that catches both is to treat a record as part of the thing it names rather
than as configuration in a separate system. When a service is built, its records are part
of building it; when it is retired, removing them is part of retiring it. Anything else
relies on somebody remembering a zone file that nobody has opened for a year.

</details>

## Five numbers and a contract

Every zone starts with a start of authority record, and the numbers in it are the
agreement between the servers holding the zone.

<figure class="learn-figure">
<svg viewBox="0 0 720 268" role="img" aria-labelledby="soa-title" style="width:100%;height:auto;">
<title id="soa-title">The five numeric fields of a start of authority record, with what each one controls, showing that four govern the primary and secondary relationship and the last governs caching of failures</title>
<g fill="currentColor">
<text x="14" y="22" font-size="11">five numbers, and the last one is not about this zone at all</text>
<text x="14" y="52" font-size="10" fill-opacity="0.7">lab.example. IN SOA ns.lab.example. hostmaster.lab.example. (</text>
<rect x="20" y="68" width="120" height="28" rx="2" fill="currentColor" fill-opacity="0.1" stroke="currentColor" stroke-opacity="0.5"/>
<text x="80" y="87" text-anchor="middle" font-size="10.5">2026081201</text>
<text x="154" y="87" font-size="10.5">serial</text>
<text x="250" y="87" font-size="10" fill-opacity="0.8">has anything changed since you last asked</text>
<rect x="20" y="104" width="120" height="28" rx="2" fill="currentColor" fill-opacity="0.1" stroke="currentColor" stroke-opacity="0.5"/>
<text x="80" y="123" text-anchor="middle" font-size="10.5">7200</text>
<text x="154" y="123" font-size="10.5">refresh</text>
<text x="250" y="123" font-size="10" fill-opacity="0.8">how often the secondary asks that question</text>
<rect x="20" y="140" width="120" height="28" rx="2" fill="currentColor" fill-opacity="0.1" stroke="currentColor" stroke-opacity="0.5"/>
<text x="80" y="159" text-anchor="middle" font-size="10.5">3600</text>
<text x="154" y="159" font-size="10.5">retry</text>
<text x="250" y="159" font-size="10" fill-opacity="0.8">how soon it asks again when the primary did not answer</text>
<rect x="20" y="176" width="120" height="28" rx="2" fill="currentColor" fill-opacity="0.1" stroke="currentColor" stroke-opacity="0.5"/>
<text x="80" y="195" text-anchor="middle" font-size="10.5">1209600</text>
<text x="154" y="195" font-size="10.5">expire</text>
<text x="250" y="195" font-size="10" fill-opacity="0.8">when the secondary stops answering at all</text>
<rect x="20" y="212" width="120" height="28" rx="2" fill="var(--red)" fill-opacity="0.16" stroke="var(--red)" stroke-opacity="0.9"/>
<text x="80" y="231" text-anchor="middle" font-size="10.5" fill="var(--red)">900</text>
<text x="154" y="231" font-size="10.5" fill="var(--red)">minimum</text>
<text x="250" y="231" font-size="10" fill-opacity="0.8">how long anybody may cache the answer that a name does not exist</text>
<text x="14" y="254" font-size="10" fill-opacity="0.7">)</text>
</g></svg>
<figcaption>Four of these five govern one conversation, between the server somebody edits and the servers that copy from it. The secondary asks every refresh interval whether the serial has gone up, transfers the zone if it has, falls back to the retry interval if the primary is unreachable, and after the expire period stops answering for the zone entirely rather than serving data it can no longer confirm. That last behaviour is worth knowing because it is deliberate: a secondary that has lost touch with its primary for a fortnight goes quiet instead of handing out records that might be wrong. The fifth number is the odd one and topic 44 met it already. Minimum has nothing to do with primaries and secondaries; RFC 2308 redefined it as the time anybody may cache the fact that a name in this zone does not exist, which is why creating a record does not always make it visible immediately.</figcaption>
</figure>

**The serial is the trigger for everything else**, which makes it the field people
get wrong. A secondary transfers the zone when the serial has increased and does
nothing when it has not, so an edit made without incrementing it is an edit the
secondaries never see. The date-based convention in the capture, `2026081201`, is
year, month, day, and a two digit counter for the changes made that day, which
sorts correctly and tells a human when the zone was last touched.

<details class="deeper">
<summary>If you already run secondaries: what happens when the primary is unreachable for a week</summary>

The numbers describe a negotiation between servers and the two at the end are the ones
that decide what a long outage looks like.

While the primary is reachable, the secondary re-checks on the refresh interval and
retries on the retry interval when a check fails. Neither of those affects whether it
keeps answering. What does is the expiry: after that long without a successful transfer,
the secondary decides its copy is too old to be trusted and stops answering for the zone
entirely.

That is the behaviour worth understanding before it happens, because the failure is
sudden rather than gradual. A zone with a short expiry and a primary that has been down
for a fortnight goes from fully served to not served at all, at a moment determined by a
number somebody typed years ago. Setting expiry generously, on the order of weeks, is
usually right for exactly this reason: stale data beats no data for a zone whose records
change rarely.

The last number is the negative caching lifetime, and it governs how long a resolver
remembers that a name does not exist. Setting it high makes a newly created name
invisible to anybody who looked too early, which is the standard explanation for why a
new record works for most people and not for the one person who tried it first.

</details>

## Copying a zone

A secondary gets the zone by transferring it, which is a single request that
returns every record.

<details class="predict">
<summary>A zone transfer asked for in one request. What comes back, and how does it compare with asking for one record at a time?</summary>

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology dns-web
# commands run on client
# the whole zone in one request, because this server permits it from here
$ dig @10.0.0.3 lab.example AXFR +noall +answer
lab.example.		3600	IN	SOA	ns.lab.example. hostmaster.lab.example. 2026081201 7200 3600 1209600 900
lab.example.		3600	IN	NS	ns.lab.example.
lab.example.		3600	IN	MX	10 mail.lab.example.
lab.example.		3600	IN	TXT	"v=spf1 mx -all"
mail.lab.example.	3600	IN	A	203.0.113.25
ns.lab.example.		3600	IN	A	10.0.0.3
shop.lab.example.	3600	IN	CNAME	www.lab.example.
www.lab.example.	3600	IN	A	203.0.113.10
www.lab.example.	3600	IN	AAAA	2001:db8:113::10
lab.example.		3600	IN	SOA	ns.lab.example. hostmaster.lab.example. 2026081201 7200 3600 1209600 900
```

</details>

That is the entire zone in one answer, starting and ending with the SOA, which is
how the receiving end knows it has the whole thing.

**Which is also why transfers are restricted.** A zone transfer hands over a
complete list of every name in a domain, with addresses, and for an internal zone
that is a map of the organisation: server names, what they run, the naming
convention, the address ranges in use, and frequently the machines somebody forgot
about. The lab server permits the transfer only from the client's address, which
is what an authoritative server should do: allow the secondaries and nobody else.

Testing this against your own domain is worth five minutes, because a server that
permits transfers to anybody is a configuration mistake that has been made for
thirty years and is still made.

## The one place a CNAME cannot go

A CNAME says this name is really that name, and it comes with a rule that catches
everybody once: **a name with a CNAME may have no other records.**

That is a rule about the name rather than about the record. Since the apex of a
zone has to carry an SOA and at least one NS record, and those are other records,
the apex can never carry a CNAME. The server does not warn about this or work
around it; it refuses to load the zone.

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology dns-web
# commands run on auth
# put a CNAME at the top of the zone, alongside the SOA and NS already there
$ cp /etc/bind-auth/lab.example.zone /tmp/broken.zone
$ printf "@\tIN\tCNAME\telsewhere.example.\n" >> /tmp/broken.zone
$ named-checkzone lab.example /tmp/broken.zone
dns_master_load: /tmp/broken.zone:11: lab.example: CNAME and other data
zone lab.example/IN: loading from master file /tmp/broken.zone failed: CNAME and other data
zone lab.example/IN: not loaded due to errors.
```

"CNAME and other data" is the whole explanation in four words. The zone has an SOA
and NS records at `lab.example`, and adding a CNAME to the same name is not
allowed.

**This matters because it is a common thing to want.** Content delivery networks
and platform hosts publish a name rather than an address, precisely so they can
change the address without telling anybody, and pointing your domain at that name
is the natural move. At `www.example.com` it works and at `example.com` it does
not, which is why so many sites work with the `www` and not without it.

The answers are all workarounds. Redirect the apex to the `www` name at the HTTP
layer, which needs something running at a fixed address to do the redirecting. Use
a provider that offers a non-standard record type doing the same job inside their
own servers, which is not part of the protocol and only works while you stay with
that provider. Or publish an address at the apex and accept that you have to
change it when the provider does.

<details class="deeper">
<summary>If you already work on networks: the reverse tree, why your PTR is somebody else's record, and the null MX</summary>

**The reverse tree is a separate delegation hierarchy** and it works the same way
as the forward one, which surprises people who expect the reverse of a name to be
somehow attached to it. `in-addr.arpa` for IPv4 and `ip6.arpa` for IPv6 are
ordinary zones, delegated downwards by address block. Whoever holds a block holds
the corresponding zone, so a company with a /24 from its ISP has a reverse zone
only if the ISP delegates it, and a company with a handful of addresses inside the
ISP's /24 usually has no reverse zone at all and has to ask for each record.

This asymmetry produces a specific frustration. You can create any forward record
you like in a domain you control, and you cannot create the matching reverse
record without the cooperation of whoever owns the address. It is also why a
mismatch between forward and reverse is so common, and why some mail systems
checking that they agree reject mail from networks whose operators never got round
to it.

**For a /24 the delegation is clean** because the zone boundary falls on an octet.
For anything smaller it is not, and RFC 2317 describes the arrangement that gets
used instead: the ISP delegates a made-up sub-zone and puts CNAME records in its
own zone pointing at it, one per address. It works, it looks bizarre the first
time you see it, and it is the reason a reverse lookup sometimes returns a CNAME
before the PTR.

**The null MX is the other detail worth knowing** and it appears in the Windows
and macOS captures further down this page. `example.com` publishes an MX record
with preference 0 and a single dot as the exchange, which RFC 7505 defines to mean
this domain accepts no mail at all. It exists because the alternative, publishing
no MX record, means senders fall back to the A record and try to deliver to the
web server, which then has to refuse it. Publishing the null MX makes the refusal
immediate and unambiguous, and a domain that will never receive mail should have
one.

</details>

## Across platforms

The commands on this page are `dig`, which is on two of the three platforms.

**On Linux**, `dig` comes from the `bind9-dnsutils` or `bind-utils` package
depending on the distribution, and `host` is a shorter alternative.

**On macOS**, it is already there.

```bash
# macOS 26.5.2, arm64
$ dig -v 2>&1 | head -1
DiG 9.10.6

$ dig example.com MX +noall +answer +comments | grep -E "status:|^example"
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 28784
example.com.		183	IN	MX	0 .

$ dig example.com NS +short
elliott.ns.cloudflare.com.
hera.ns.cloudflare.com.
```

**On Windows**, there is no `dig` and there are two replacements.

```powershell
# Microsoft Windows Server 2025 Datacenter, version 10.0.26100.0
> nslookup -type=MX example.com 2>$null | Select-String -NotMatch "^$" | Select-Object -First 6
Server:  UnKnown
Address:  168.63.129.16
example.com	MX preference = 0, mail exchanger = (root)

# The cmdlet, where each record is an object with typed fields
> Resolve-DnsName example.com -Type MX | Format-Table Name, Type, TTL, NameExchange, Preference -AutoSize
Name        Type TTL NameExchange Preference
----        ---- --- ------------ ----------
example.com   MX 260 .                     0

> Resolve-DnsName example.com -Type NS | Where-Object Type -eq "NS" | Format-Table Name, Type, NameHost -AutoSize
Name        Type NameHost
----        ---- --------
example.com   NS hera.ns.cloudflare.com
example.com   NS elliott.ns.cloudflare.com

# Is there a dig
> Get-Command dig -ErrorAction SilentlyContinue | Measure-Object | Select-Object -ExpandProperty Count
0
```

`nslookup` is the one the exam names and it is worth being able to drive, but
`Resolve-DnsName` returns objects with typed fields, so the preference and the
exchange are separate properties rather than text to be read out of a line. For
anything scripted that difference is the whole argument.

Both platforms happened to capture the null MX described above: `example.com`
answers with preference 0 and an exchange of `.`, which macOS prints as `0 .` and
Windows prints as `(root)`. Neither is an error.

## Prove it

**Look up your own domain four ways.** A, AAAA, MX and NS. Then look up the MX
target's A record and confirm it points somewhere you expect.

**Read your own SOA.** Find the serial and work out whether it is date-based, and
find the minimum and note how long a failure for that domain is remembered.

**Try a transfer against a domain you own.** `dig AXFR` at each of its name
servers. It should be refused. If it is not, that is a finding.

## What trips people up

### 1. Assuming one name has one answer

A name has as many answers as there are record types asked about it. Moving the
website changes one of them.

### 2. Expecting the MX to hold an address

It holds a name, which then needs its own lookup. That is what lets an
organisation move its mail without touching the MX record.

### 3. Putting a CNAME at the apex

A name with a CNAME may have no other records, and the apex must have SOA and NS.
The server refuses to load the zone rather than warning.

### 4. Editing a zone without changing the serial

Secondaries transfer when the serial increases. Without that they never learn
about the edit, and the primary and the secondaries disagree indefinitely.

### 5. Treating the reverse record as part of the forward one

The reverse tree is a separate delegation, normally held by whoever owns the
address block. You can usually create the forward record yourself and usually
cannot create the reverse.

### 6. Leaving zone transfers open

A transfer returns every name in the zone. On an internal domain that is a map of
the estate, and restricting it to the secondaries takes one line.

## Work it through

The website that moved and took the mail with it.

The change was to the A record, which is what a browser asks for, and it did
exactly what it was supposed to. Nothing about it touched the MX record, which is
what a sending mail server asks for, and that record is still pointing wherever it
pointed before.

**So the question is where the MX points**, and there are two cases with different
answers.

If the MX names a host at the old provider, mail is still being delivered there,
and whether it is arriving depends on whether that server still exists. If the old
hosting was cancelled, the mail server is gone and senders have been getting
delivery failures for two days, which means the messages are not lost and the
senders know. If the old server is still running, the mail is sitting in a mailbox
nobody is reading, which is worse and quieter.

If the MX names a host whose A record was also changed, the mail is being delivered
to the new server, which is not running a mail service, and it is being refused.

**Either way the fix is the same shape.** Decide where mail should go, point the MX
at a name whose A record resolves to that place, and lower the TTL first if the
change has to be quick, which is topic 44's lever.

There is a check worth doing before declaring it fixed, and it is the one people
skip. The MX record answers with a name, so confirm that name resolves, and
confirm what it resolves to, because a correct MX pointing at a name with a stale
A record fails in exactly the same way with none of the same evidence.

**And a note on how this happens.** Nobody decided to break the mail. Somebody was
given one job, changed one record, and tested the thing they changed. The general
version is worth carrying: **a name is not one setting**, and a change to one
record type says nothing about the others, so the checklist for moving a service
is a list of record types rather than a list of servers.

## Try it

**Write a zone file by hand.** Ten lines, an SOA, an NS, an A and an MX, and run
it through `named-checkzone`. The errors it gives you are the best teacher for
this material.

**Follow a real MX to its address.** Pick any large organisation, ask for its MX,
then resolve the name it gives you. Two lookups, and the second one is the one
people forget exists.

**Find a domain that works with www and not without it.** They are common, and
now you know why.

## Check yourself

<details class="qa">
<summary>A company changes its A record to move its website and mail stops arriving. What is the relationship between those two events?</summary>

There is none, which is the point. A browser asks for the A record and a sending
mail server asks for the MX record, and they are separate records that are edited
separately.

Changing the A record moved the website and left the MX pointing wherever it
pointed before. If that is a host at the old provider which no longer exists, mail
has been failing since the move; if the old host is still running, mail is
arriving somewhere nobody is looking.

</details>

<details class="qa">
<summary>Why can a CNAME not be placed at the apex of a zone?</summary>

Because a name carrying a CNAME may have no other records, and the apex is
required to carry an SOA and at least one NS record.

The server does not work around this or warn about it. It refuses to load the
zone, reporting CNAME and other data, which is a precise description of the rule
being broken.

</details>

<details class="qa">
<summary>What do the five numbers in an SOA record govern?</summary>

Four of them govern the relationship between the primary and its secondaries. The
serial is what a secondary compares to decide whether to transfer, refresh is how
often it checks, retry is how soon it tries again after a failure, and expire is
when it stops answering for the zone at all.

The fifth, minimum, is unrelated to that conversation. It sets how long anybody
may cache the answer that a name in this zone does not exist.

</details>

<details class="qa">
<summary>Why is a zone transfer normally restricted to named addresses?</summary>

Because it returns every record in the zone in one answer. On an internal domain
that is a list of every host name, its address, the naming convention in use and
the address ranges in service, which is a map of the estate for anybody who asks.

The legitimate need is narrow: the secondaries have to be able to do it and
nothing else does. Restricting it to their addresses is one line of configuration
and is still left undone often enough to be worth checking.

</details>

<details class="qa">
<summary>You can create any forward record you like for your domain but cannot create the matching PTR. Why?</summary>

Because reverse lookups live in a separate delegation hierarchy under
`in-addr.arpa` or `ip6.arpa`, organised by address block rather than by name.

Whoever holds the address block holds that zone, which for most organisations is
the ISP. So the forward record is yours to edit and the reverse one belongs to
whoever gave you the address, which is why the two so often disagree.

</details>

## References

- [RFC 1034](https://www.rfc-editor.org/rfc/rfc1034) - IETF, zones, delegation and the rule that a CNAME excludes other data at the same name. Free. Accessed 2026-08-12.
- [RFC 1035](https://www.rfc-editor.org/rfc/rfc1035) - IETF, the record types and the SOA fields. Free. Accessed 2026-08-12.
- [RFC 2308](https://www.rfc-editor.org/rfc/rfc2308) - IETF, which redefined the SOA minimum field as the negative caching interval. Free. Accessed 2026-08-12.
- [RFC 5936](https://www.rfc-editor.org/rfc/rfc5936) - IETF, the zone transfer protocol. Free. Accessed 2026-08-12.
- [RFC 7505](https://www.rfc-editor.org/rfc/rfc7505) - IETF, the null MX record that appears in the platform captures. Free. Accessed 2026-08-12.
- [RFC 3596](https://www.rfc-editor.org/rfc/rfc3596) - IETF, the AAAA record. Free. Accessed 2026-08-12.
- [RFC 2317](https://www.rfc-editor.org/rfc/rfc2317) - IETF, reverse delegation for blocks smaller than a /24, described in the deeper panel. Free. Accessed 2026-08-12.

**Where the output came from.** The Linux blocks ran on the `dns-web` namespace
topology through `blog/scripts/netlab.sh`, against an authoritative server holding
a forward zone and a reverse zone written out in the topology file, so the records
being queried are visible alongside the queries. The transfer succeeds because the
server is configured to permit it from the client's address and from nowhere else,
which is what an authoritative server should do and is the configuration the
prose recommends. The apex CNAME block is `named-checkzone` refusing a copy of the
same zone with one line added; nothing is edited and the error is the server's own
wording. The Windows and macOS blocks came from GitHub Actions runners through
`blog/scripts/hostcap.sh` and query `example.com`, which IANA operates for
documentation use.

**If you also work on Linux.** [Common network services](/learn/linux-plus/common-network-services)
on the Linux+ track covers running an authoritative server rather than querying
one, including the zone file syntax and the checks that catch a mistake before it
reaches a resolver.
