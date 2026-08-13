---
title: "DNS security"
description: "A signed answer proves the zone owner wrote it and hides nothing. An encrypted one hides the question and proves nothing about the answer. Both, demonstrated on a lab that signs its own zone and then breaks it."
deck: "The answer came back signed, and something still gave you the wrong address"
track: "network-plus"
level: "working"
order: 480
objectives:
  - "Say what DNSSEC signs and what it does not do"
  - "Explain why a validating resolver returns SERVFAIL rather than a wrong answer"
  - "Distinguish DNS over TLS from DNS over HTTPS and say what each conceals"
  - "Say what neither of them hides"
  - "Describe poisoning and spoofing as the attacks these answer"
prerequisites: ["dns-records-and-zones"]
tags: ["network-plus", "networking", "security"]
updated: 2026-08-13
draft: false
examObjectives:
  - exam: "n10-009"
    domain: "3.0"
    objective: "3.4"
sources:
  - title: "RFC 4033, DNS Security Introduction and Requirements"
    url: "https://www.rfc-editor.org/rfc/rfc4033"
    publisher: "IETF"
    accessed: 2026-08-13
    tier: 1
  - title: "RFC 4035, Protocol Modifications for the DNS Security Extensions"
    url: "https://www.rfc-editor.org/rfc/rfc4035"
    publisher: "IETF"
    accessed: 2026-08-13
    tier: 1
  - title: "RFC 7858, Specification for DNS over Transport Layer Security"
    url: "https://www.rfc-editor.org/rfc/rfc7858"
    publisher: "IETF"
    accessed: 2026-08-13
    tier: 1
  - title: "RFC 8484, DNS Queries over HTTPS"
    url: "https://www.rfc-editor.org/rfc/rfc8484"
    publisher: "IETF"
    accessed: 2026-08-13
    tier: 1
  - title: "RFC 5452, Measures for Making DNS More Resilient against Forged Answers"
    url: "https://www.rfc-editor.org/rfc/rfc5452"
    publisher: "IETF"
    accessed: 2026-08-13
    tier: 1
symptoms:
  - symptom: "A name resolves to an address that is not in the zone"
    anchor: "what-a-signature-is-over"
  - symptom: "One domain returns SERVFAIL from one resolver and works from another"
    anchor: "what-a-signature-is-over"
  - symptom: "Internal names stop resolving on a laptop that worked yesterday"
    anchor: "the-two-that-encrypt"
---

> **Before you read.** A user reaches a convincing copy of a company's login
> page. The address in the browser is correct. The name resolved to a server
> nobody at the company owns.
>
> The zone is signed with DNSSEC and every signature checked out.
>
> **How can both of those be true at once?**

DNS was designed in 1983 with no security in it at all, and the two mechanisms
bolted on since answer different questions. Being precise about which is which is
most of what this topic is for, because the two get sold as the same thing and a
network can have one without the other.

### Some words you will need

<dl class="terms">
<dt>DNSSEC</dt>
<dd>Signatures over records, so an answer can be checked against the zone owner's key.</dd>
<dt>RRSIG</dt>
<dd>The record that holds one of those signatures.</dd>
<dt>trust anchor</dt>
<dd>A key you already have, which the chain of signatures is checked back to.</dd>
<dt>DoT</dt>
<dd>DNS over TLS. The same messages inside a TLS connection, on port 853.</dd>
<dt>DoH</dt>
<dd>DNS over HTTPS. The same messages inside ordinary web requests, on port 443.</dd>
<dt>cache poisoning</dt>
<dd>Getting a resolver to accept and store an answer that did not come from the zone.</dd>
</dl>

## What breaks without this

**A resolver accepts an answer from the wrong place** and every machine using it
goes to the wrong server for as long as the record is cached.

**Every question anybody asks is readable** by whoever is on the path, which is a
list of every site each person visited.

**A signed zone with one bad record takes the whole name down**, which is a
failure mode people are unprepared for the first time it happens.

## Two mechanisms, two questions

Before either one, it is worth being exact about what each is for.

<figure class="learn-figure">
<svg viewBox="0 0 720 262" role="img" aria-labelledby="dnsprot-title" style="width:100%;height:auto;">
<title id="dnsprot-title">Three properties of a DNS answer, showing which of them signing provides, which encrypted transport provides, and which neither provides</title>
<g fill="currentColor">
<text x="14" y="22" font-size="11">two answers to two different questions, and one they both leave open</text>
<text x="330" y="52" text-anchor="middle" font-size="10" fill-opacity="0.75">DNSSEC</text>
<text x="470" y="52" text-anchor="middle" font-size="10" fill-opacity="0.75">DoT or DoH</text>
<text x="610" y="52" text-anchor="middle" font-size="10" fill-opacity="0.75">both together</text>
<rect x="14" y="66" width="692" height="30" rx="2" fill="currentColor" fill-opacity="0.05" stroke="currentColor" stroke-opacity="0.28"/>
<text x="24" y="86" font-size="10.5">the answer has not been altered</text>
<path d="M 323 81 l 5 6 l 10 -12" fill="none" stroke="var(--accent)" stroke-width="2.2" stroke-linecap="round"/>
<path d="M 463 81 l 5 6 l 10 -12" fill="none" stroke="var(--accent)" stroke-width="2.2" stroke-linecap="round"/>
<path d="M 603 81 l 5 6 l 10 -12" fill="none" stroke="var(--accent)" stroke-width="2.2" stroke-linecap="round"/>
<rect x="14" y="100" width="692" height="30" rx="2" fill="currentColor" fill-opacity="0.05" stroke="currentColor" stroke-opacity="0.28"/>
<text x="24" y="120" font-size="10.5">the answer came from the zone owner</text>
<path d="M 323 115 l 5 6 l 10 -12" fill="none" stroke="var(--accent)" stroke-width="2.2" stroke-linecap="round"/>
<path d="M 464 109 l 12 12 M 476 109 l -12 12" fill="none" stroke="var(--red)" stroke-opacity="0.8" stroke-width="2"/>
<path d="M 603 115 l 5 6 l 10 -12" fill="none" stroke="var(--accent)" stroke-width="2.2" stroke-linecap="round"/>
<rect x="14" y="134" width="692" height="30" rx="2" fill="currentColor" fill-opacity="0.05" stroke="currentColor" stroke-opacity="0.28"/>
<text x="24" y="154" font-size="10.5">you are talking to the resolver you chose</text>
<path d="M 324 143 l 12 12 M 336 143 l -12 12" fill="none" stroke="var(--red)" stroke-opacity="0.8" stroke-width="2"/>
<path d="M 463 149 l 5 6 l 10 -12" fill="none" stroke="var(--accent)" stroke-width="2.2" stroke-linecap="round"/>
<path d="M 603 149 l 5 6 l 10 -12" fill="none" stroke="var(--accent)" stroke-width="2.2" stroke-linecap="round"/>
<rect x="14" y="168" width="692" height="30" rx="2" fill="currentColor" fill-opacity="0.05" stroke="currentColor" stroke-opacity="0.28"/>
<text x="24" y="188" font-size="10.5">nobody on the path can read the question</text>
<path d="M 324 177 l 12 12 M 336 177 l -12 12" fill="none" stroke="var(--red)" stroke-opacity="0.8" stroke-width="2"/>
<path d="M 463 183 l 5 6 l 10 -12" fill="none" stroke="var(--accent)" stroke-width="2.2" stroke-linecap="round"/>
<path d="M 603 183 l 5 6 l 10 -12" fill="none" stroke="var(--accent)" stroke-width="2.2" stroke-linecap="round"/>
<rect x="14" y="202" width="692" height="30" rx="2" fill="currentColor" fill-opacity="0.05" stroke="currentColor" stroke-opacity="0.28"/>
<text x="24" y="222" font-size="10.5">the resolver itself cannot see what you asked</text>
<path d="M 324 211 l 12 12 M 336 211 l -12 12" fill="none" stroke="var(--red)" stroke-opacity="0.8" stroke-width="2"/>
<path d="M 464 211 l 12 12 M 476 211 l -12 12" fill="none" stroke="var(--red)" stroke-opacity="0.8" stroke-width="2"/>
<path d="M 604 211 l 12 12 M 616 211 l -12 12" fill="none" stroke="var(--red)" stroke-opacity="0.8" stroke-width="2"/>
</g></svg>
<figcaption>Signing and encrypting are not two grades of the same thing. DNSSEC is about the answer and says nothing about the journey; encrypted transport is about the journey and says nothing about the answer. Running both is not redundant, and running one is not most of the way to the other. The last row is the one worth arguing about, because it is the row that never turns into a tick. Whichever resolver you send your questions to, encrypted or not, knows every name you asked for. Encrypted transport moves that knowledge from your network operator to whoever runs the resolver, and the argument about DNS over HTTPS is mostly an argument about who you would rather that be.</figcaption>
</figure>

## What a signature is over

DNSSEC signs record sets. The signature is a record in its own right, it lives
in the zone next to what it signs, and it travels with the data.

<figure class="learn-figure">
<svg viewBox="0 0 720 250" role="img" aria-labelledby="rrsig-title" style="width:100%;height:auto;">
<title id="rrsig-title">A signed record set travelling from the authoritative server through a resolver and a cache to a client, with the signature intact at every hop and the transport unprotected</title>
<g fill="currentColor">
<text x="14" y="22" font-size="11">the signature travels with the record, not with the connection</text>
<rect x="30" y="70" width="106" height="38" rx="3" fill="currentColor" fill-opacity="0.1" stroke="currentColor" stroke-opacity="0.55"/>
<text x="83" y="94" text-anchor="middle" font-size="10.5">zone owner</text>
<rect x="220" y="70" width="106" height="38" rx="3" fill="currentColor" fill-opacity="0.1" stroke="currentColor" stroke-opacity="0.55"/>
<text x="273" y="94" text-anchor="middle" font-size="10.5">resolver</text>
<rect x="410" y="70" width="106" height="38" rx="3" fill="currentColor" fill-opacity="0.1" stroke="currentColor" stroke-opacity="0.55"/>
<text x="463" y="94" text-anchor="middle" font-size="10.5">a cache</text>
<rect x="600" y="70" width="106" height="38" rx="3" fill="currentColor" fill-opacity="0.1" stroke="currentColor" stroke-opacity="0.55"/>
<text x="653" y="94" text-anchor="middle" font-size="10.5">you</text>
<line x1="136" y1="89" x2="208" y2="89" stroke="currentColor" stroke-opacity="0.5" stroke-width="1.6"/>
<path d="M 214 89 l -9 -5 l 0 10 z" fill="currentColor" fill-opacity="0.7"/>
<line x1="326" y1="89" x2="398" y2="89" stroke="currentColor" stroke-opacity="0.5" stroke-width="1.6"/>
<path d="M 404 89 l -9 -5 l 0 10 z" fill="currentColor" fill-opacity="0.7"/>
<line x1="516" y1="89" x2="588" y2="89" stroke="currentColor" stroke-opacity="0.5" stroke-width="1.6"/>
<path d="M 594 89 l -9 -5 l 0 10 z" fill="currentColor" fill-opacity="0.7"/>
<rect x="30" y="140" width="676" height="34" rx="3" fill="var(--accent)" fill-opacity="0.12" stroke="var(--accent)" stroke-opacity="0.85" stroke-width="1.6"/>
<text x="44" y="162" font-size="10.5" fill="var(--accent)">A 203.0.113.10 + RRSIG, checkable by anybody, at every hop</text>
<line x1="136" y1="118" x2="208" y2="118" stroke="var(--red)" stroke-width="1.6" stroke-dasharray="5 4"/>
<line x1="326" y1="118" x2="398" y2="118" stroke="var(--red)" stroke-width="1.6" stroke-dasharray="5 4"/>
<line x1="516" y1="118" x2="588" y2="118" stroke="var(--red)" stroke-width="1.6" stroke-dasharray="5 4"/>
<text x="30" y="200" font-size="10.5" fill="var(--red)">every hop is readable to anybody on the path</text>
<text x="30" y="220" font-size="10" fill-opacity="0.75">the question, the answer and who asked it</text>
</g></svg>
<figcaption>This is the structural reason DNSSEC works at all in a system built on caching. A signature over a record survives being copied, so a resolver can hand out an answer it stored an hour ago and the person receiving it can still check it against the zone owner's key. Nothing has to trust the resolver, which is what makes the property useful. It also explains the limitation drawn underneath: the signature says who wrote the record and says nothing whatsoever about the connection carrying it, so an observer sees the question, the answer and the address that asked, exactly as they would without it.</figcaption>
</figure>

Here is a zone signed with its own keys, and a resolver told to check them.

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology dns-secure
# the signed answer, and the flag that says the resolver checked it
$ ip netns exec client dig @10.0.0.4 +dnssec www.lab.example A | grep -E "status:|^;; flags|^www"
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 55136
;; flags: qr rd ra ad; QUERY: 1, ANSWER: 2, AUTHORITY: 0, ADDITIONAL: 1
www.lab.example.	3600	IN	A	203.0.113.10
www.lab.example.	3600	IN	RRSIG	A 13 3 3600 20260912142404 20260813142404 55174 lab.example. 51LaLw01zK2RMkqSY4VLgJsf+eFCL8bwO2qsL4U142t+I527qf2F7gFp QDB30dC0Jy2pJie/8q0gQh5eqnCNBQ==

# now change the address in the signed zone, without re-signing it
$ ip netns exec auth sed -i "s/203.0.113.10/203.0.113.66/" /etc/bind-auth/lab.example.signed
$ ip netns exec auth pkill named; ip netns exec resolver pkill named; sleep 1
$ ip netns exec auth named -c /etc/bind-auth/named.conf
$ ip netns exec resolver named -c /etc/bind-resolver/named.conf
$ sleep 4
# the server that owns the zone hands out the new address quite happily
$ ip netns exec client dig @10.0.0.3 www.lab.example A +short
203.0.113.66
# the resolver that checks signatures will not hand out anything at all
$ ip netns exec client dig @10.0.0.4 www.lab.example A | grep -E "status:|^www"
;; ->>HEADER<<- opcode: QUERY, status: SERVFAIL, id: 41267
```

The `ad` flag in that first answer is the whole point. It stands for authenticated
data, and it means the resolver checked the signature chain back to a key it
already trusted and the check passed. Without validation the same answer arrives
looking identical, which is why the flag is worth being able to spot.

Then the address in the signed zone is changed without re-signing it, and the two
servers disagree about what to do.

**The authoritative server hands out the new address without hesitation**, because
nothing about serving a zone requires the signatures to match the data.

**The validating resolver returns SERVFAIL.** Not the old answer, not the new one,
and not a warning: nothing at all. That is the correct behaviour and it is the
part that surprises people. A validator that cannot verify an answer has no way to
know which part is wrong, so the only safe thing it can do is refuse to pass
anything on.

**Which means a DNSSEC mistake takes a domain off the internet** for everybody
whose resolver validates, while continuing to work perfectly for everybody whose
resolver does not. A domain that works from your phone and fails from the office
is a signature that has expired or a key that was rolled without updating the
parent, and it is one of the few faults where the symptom points almost uniquely
at the cause.

<figure class="learn-figure photo">

![A hardware security module on a PCIe card, photographed against a white background. Most of the board is covered by a black potted enclosure with a blue finned heatsink set into it, printed with the manufacturer's name. A small strip of temperature indicator dots runs along the lower edge of the potting, marked 29, 40, 49, 60, 71 and 82 degrees. The gold PCIe contacts and a metal mounting bracket are visible at the edges.](./images/hardware-security-module.jpg)

<figcaption>What a signing key lives in when it matters. The black area is potting compound, poured over the processor and memory and set hard, so the components cannot be probed without destroying them, and the temperature strip beside it is there because heat is one of the ways somebody would try. A module like this generates its own keys and performs signatures internally, and the private key is never available to the machine it is plugged into, which is a different proposition from a key in a file with careful permissions on it. That distinction matters for DNSSEC because the key-signing key of a zone is a long-lived secret whose compromise is not something you can undo quickly: the parent has published a fingerprint of it, resolvers have cached that, and replacing it is a process measured in days. Photograph by Alexander Klink, <a href="https://creativecommons.org/licenses/by/3.0/">CC BY 3.0</a>.</figcaption>
</figure>

## The two that encrypt

DNSSEC leaves every question and answer readable on the wire. Two protocols fix
that and they differ mostly in where they hide.

**DNS over TLS** puts the ordinary DNS message inside a TLS connection on port
853. It is DNS, recognisably, on a port of its own.

**DNS over HTTPS** puts the same message inside an HTTPS request on port 443,
where it is indistinguishable from any other web traffic.

Asking the same question both ways, with a capture running on each, shows what
changes.

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology dns-secure
# commands run on client
# the same question twice, on port 53 and on port 853, with a capture of each
$ (timeout 10 tcpdump -i client0 -n -A -s0 "port 53" > /tmp/plain.txt 2>/dev/null &)
$ (timeout 10 tcpdump -i client0 -n -A -s0 "port 853" > /tmp/tls.txt 2>/dev/null &)
$ sleep 2
$ dig +short @10.0.0.4 www.lab.example A
203.0.113.10
$ dig +tls +short @10.0.0.4 www.lab.example A
203.0.113.10
$ sleep 9
# on port 53, the name is in the packet and so is the answer
$ grep -a "A? www\|A 203" /tmp/plain.txt | head -2
16:01:42.983544 IP 10.0.0.5.33093 > 10.0.0.4.53: 5410+ [1au] A? www.lab.example. (56)
16:01:42.989073 IP 10.0.0.4.53 > 10.0.0.5.33093: 5410$ 1/0/1 A 203.0.113.10 (88)
# on port 853, the same conversation, searched for the same name
$ echo "packets on 853: $(grep -ac "IP 10" /tmp/tls.txt)"
packets on 853: 17
$ echo "times the name appears in them: $(grep -ac "lab.example" /tmp/tls.txt)"
times the name appears in them: 0
$ echo "times the address appears in them: $(grep -ac "203.0.113.10" /tmp/tls.txt)"
times the address appears in them: 0
```

On port 53 the name is in the packet and so is the answer. On port 853 there are
seventeen packets carrying the same conversation, and the name appears in none of
them.

**The difference between the two protocols is not cryptographic.** Both use TLS
and both conceal the same content. The difference is that a port number is a
policy handle and 443 is not: an organisation can block or redirect port 853 and
force its own resolver to be used, and it cannot do the same to 443 without
breaking the web. That is the whole of the argument about DNS over HTTPS, and it
is worth being able to state neutrally, because it is an argument about who
controls resolution rather than about encryption.

The consequence a network administrator meets first is split horizon. Many
organisations answer internal names differently on the inside, and a laptop whose
browser has quietly enabled DNS over HTTPS to a public resolver stops seeing
those answers. The symptom is that internal sites fail on one machine while
everything public works, and nothing in the network changed.

<details class="deeper">
<summary>If you already work on networks: what poisoning actually required, why the fix was randomness rather than signatures, and what DNSSEC does about a name that does not exist</summary>

Cache poisoning is the attack both of these are usually explained by, and the
mechanics are worth knowing because the defence that actually deployed was not
DNSSEC.

A resolver accepts an answer if it arrives from the address it asked, on the port
it asked from, with the query identifier it used, and matching the question. The
identifier is 16 bits. An attacker who can guess the source port and win a race
against the real server can have their answer cached instead, and in 2008 it
became clear that the guessing was far easier than anybody had assumed, because
many resolvers used a predictable source port and the attacker could force
repeated attempts by asking for names that did not exist.

**The fix that shipped everywhere within weeks was source port randomisation**,
which is RFC 5452: use a random source port as well as a random identifier, and
the search space becomes roughly 32 bits instead of 16. It is a mitigation rather
than a solution, it makes the attack expensive rather than impossible, and it is
what is actually protecting most of the internet today. DNSSEC is the solution
and its deployment on the answering side remains partial.

**The other half is proving a negative**, and it is the part of DNSSEC that is
genuinely clever and genuinely awkward. Signing a record that exists is
straightforward. Proving that a name does not exist means signing a statement
about a gap, and the original design does this with NSEC records that name the
next existing name in the zone, in order. It works, and it lets anybody walk the
entire zone one query at a time by following the chain, which is a zone transfer
by other means and was not what most operators wanted.

NSEC3 replaced the names with hashes of names to stop that, and made the
enumeration expensive rather than free, since the hashes can still be attacked
offline. The current answer for large zones is to sign the denial when it is
asked for rather than in advance, which needs the key online and is the trade
most large providers now make.

None of the three is on the exam. The reason to know it is that "signed" is not
one property, and a question about what DNSSEC guarantees has a more careful
answer than a question about what TLS guarantees.

</details>

## Across platforms

Encrypted DNS is configured per machine, and the three platforms are at three
different points.

**On Linux**, `systemd-resolved` supports DNS over TLS and can be set to opportunistic
or strict mode, and every browser ships its own DNS over HTTPS setting that
bypasses the system resolver entirely.

**On macOS**, the system resolver supports encrypted DNS through configuration
profiles, and the command line tool in the base system is old enough to have no
idea what you are asking for.

```bash
# macOS 26.5.2, arm64
$ dig -v 2>&1 | head -1
DiG 9.10.6

# Ask it to use DNS over TLS and see whether it recognises the request
$ dig +tls example.com 2>&1 | head -2
Invalid option: +tls
Usage:  dig [@global-server] [domain] [q-type] [q-class] {q-opt}

# What the system resolver is configured to do, which is a separate question
$ scutil --dns | grep -iE "flags|reach" | head -3
  flags    : Request A records
  reach    : 0x00020002 (Reachable,Directly Reachable Address)
  flags    : Request A records
```

**On Windows**, the client carries a list of resolvers it already knows how to
reach over HTTPS, so turning it on is a matter of choosing one.

```powershell
# Microsoft Windows Server 2025 Datacenter, version 10.0.26100.0
> Get-DnsClientDohServerAddress | Format-Table ServerAddress, DohTemplate, AutoUpgrade -AutoSize
ServerAddress        DohTemplate                          AutoUpgrade
-------------        -----------                          -----------
149.112.112.112      https://dns.quad9.net/dns-query            False
9.9.9.9              https://dns.quad9.net/dns-query            False
8.8.8.8              https://dns.google/dns-query               False
8.8.4.4              https://dns.google/dns-query               False
1.1.1.1              https://cloudflare-dns.com/dns-query       False
1.0.0.1              https://cloudflare-dns.com/dns-query       False
2001:4860:4860::8844 https://dns.google/dns-query               False
2001:4860:4860::8888 https://dns.google/dns-query               False
2606:4700:4700::1001 https://cloudflare-dns.com/dns-query       False
2606:4700:4700::1111 https://cloudflare-dns.com/dns-query       False
2620:fe::9           https://dns.quad9.net/dns-query            False
2620:fe::fe          https://dns.quad9.net/dns-query            False

# Whether encrypted DNS is currently switched on for any interface
> Get-DnsClientDohServerAddress | Measure-Object | Select-Object -ExpandProperty Count
12
```

That list is the interesting artefact. Twelve entries, three operators, each
paired with the URL template to use for it, and `AutoUpgrade` false against all of
them, which means the machine is currently using plain DNS to servers it knows it
could be reaching privately. Switching that column to true is the whole
configuration.

## Prove it

**Check whether a domain is signed.** `dig +dnssec` any domain and look for RRSIG
records in the answer. Most are not signed, which is worth seeing.

**Find the ad flag.** Ask a validating resolver, such as 1.1.1.1 or 9.9.9.9, for a
signed domain and look at the flags line.

**Query over TLS.** `kdig +tls` or a recent `dig +tls` against a public resolver
that supports it, with a capture running. Compare what you can see against the
same query on port 53.

## What trips people up

### 1. Thinking DNSSEC encrypts anything

It signs. Every question and answer stays readable on the wire, and that is by
design, because the signature has to survive caching.

### 2. Thinking DoT or DoH proves the answer is correct

They prove you are talking to the resolver you meant and that nobody in between
altered the conversation. They say nothing about whether the resolver's answer is
what the zone owner published.

### 3. Expecting a validation failure to give a warning

A validating resolver that cannot verify an answer returns SERVFAIL. It cannot
tell which part is wrong, so it passes nothing on.

### 4. Assuming a signed zone is safer to operate

It has a new failure mode. An expired signature or a key rolled without updating
the parent takes the domain down for validating resolvers and leaves it working
for everybody else.

### 5. Reading the DoH argument as being about encryption

Both protocols encrypt the same content the same way. The argument is that port
443 cannot be blocked selectively, which moves control of resolution from the
network operator to the application.

### 6. Forgetting that the resolver still sees everything

Neither mechanism hides the question from the server answering it. Encrypted
transport changes who knows, not whether anybody does.

## Work it through

The convincing login page, at the correct address, in a signed zone.

The first move is to be precise about what the signatures proved. DNSSEC
guarantees that the records a resolver returned are the records the zone owner
published. If validation passed, then the address that came back is the address in
the zone. That is a strong statement and it is narrow.

**So there are two families of explanation and they are very different problems.**

Either the answer was correct and the resolution was never the attack. The user
followed a link to a name that looks right and is not, and the address in the
browser being correct is a claim about what they read rather than about what was
resolved. A homograph or a plausible neighbouring domain resolves correctly, is
signed correctly, and belongs to somebody else. Nothing in DNS is broken and DNS
was never involved.

Or the records in the zone genuinely say what the user reached, which means the
zone was edited. That is a compromise of the account that manages the domain, or
of the registrar, and it is worse than a spoofing attack because every signature
will keep validating perfectly. DNSSEC signs whatever is in the zone, including
whatever an attacker put there.

**Both of those are outside what any of the transport protections cover**, and
that is the useful lesson rather than a technicality. Encrypting the query would
not have helped. Validating the signature did not help, and did its job.

For the investigation, the fork is quick. Get the exact name from the user, not
their description of it, and resolve it yourself. If it is not your domain, the
problem is a phishing message and the response is a mail and awareness one. If it
is your domain, pull the zone's current contents and its change history, and treat
it as a compromised account with the registrar until proven otherwise.

And there is a control worth having in place before this happens: registrar lock,
and multifactor authentication on the account that can change the zone. Topic 35's
argument about the account nobody removed applies with unusual force to a domain
registrar, because that one account can redirect everything at once, and every
protection on this page will faithfully certify the result.

## Try it

**Sign a zone in a lab.** Any zone, any name, then break one record and watch a
validating resolver stop answering. Doing it once removes the mystery.

**Capture your own DNS.** On any network you control, watch port 53 for a minute
and read the names. It is a persuasive demonstration to show somebody who thinks
DNS is not sensitive.

**Turn on encrypted DNS and watch what breaks.** On a machine that uses internal
names, enable DNS over HTTPS in the browser and see which internal sites stop
working. That is the split horizon problem, first hand.

## Check yourself

<details class="qa">
<summary>What does DNSSEC prove, and what does it not?</summary>

It proves that the records in an answer are the records the zone owner published,
and that they have not been altered in transit or in a cache. The signature
travels with the data, so it can be checked by anybody who receives it, however
many caches it passed through.

It does not encrypt anything. The question, the answer and who asked are all
readable on the wire exactly as they would be without it. It also says nothing
about whether the contents of the zone are correct, only that they are genuinely
what the zone contains.

</details>

<details class="qa">
<summary>A record in a signed zone is edited without re-signing. What does a validating resolver do?</summary>

It returns SERVFAIL. The signature no longer matches the data, so the resolver
cannot verify the answer, and it has no way to tell which of the two is wrong.

That means it returns nothing at all rather than the old value or a warning. The
domain then fails for everybody whose resolver validates and works normally for
everybody whose resolver does not, which is a distinctive symptom.

</details>

<details class="qa">
<summary>What is the practical difference between DNS over TLS and DNS over HTTPS?</summary>

Not the cryptography. Both put ordinary DNS messages inside TLS and conceal the
same content from anybody on the path.

The difference is the port. DNS over TLS uses 853, which an organisation can block
or redirect to force its own resolver to be used. DNS over HTTPS uses 443, where
it is indistinguishable from web traffic and cannot be blocked without breaking
the web, which moves the choice of resolver from the network to the application.

</details>

<details class="qa">
<summary>Internal sites stop resolving on one laptop while public sites work. What is worth checking first?</summary>

Whether something on that machine has started using encrypted DNS to a public
resolver. A browser with DNS over HTTPS enabled bypasses the system resolver
entirely, and a public resolver has no knowledge of internal names.

That is the split horizon problem: the organisation answers internal names
differently on the inside, and a machine that stopped asking the internal resolver
stops getting those answers. Nothing on the network changed, which is what makes
it confusing.

</details>

<details class="qa">
<summary>Why was source port randomisation, rather than DNSSEC, the fix that actually deployed against cache poisoning?</summary>

Because it could be deployed unilaterally and immediately. A resolver accepts an
answer that matches the query identifier, the question and the source address, and
the identifier is only 16 bits. Randomising the source port as well takes the
search space to roughly 32 bits, which makes the race expensive rather than
practical.

It is a mitigation rather than a proof, and it required no cooperation from zone
owners. DNSSEC is the actual solution and needs the zone signed at the other end,
which is why deployment is still partial decades later.

</details>

## References

- [RFC 4033](https://www.rfc-editor.org/rfc/rfc4033) - IETF, the DNSSEC introduction, on what the extensions do and explicitly do not provide. Free. Accessed 2026-08-13.
- [RFC 4035](https://www.rfc-editor.org/rfc/rfc4035) - IETF, the protocol modifications, including the authenticated data flag and the behaviour on validation failure. Free. Accessed 2026-08-13.
- [RFC 7858](https://www.rfc-editor.org/rfc/rfc7858) - IETF, DNS over TLS and the assignment of port 853. Free. Accessed 2026-08-13.
- [RFC 8484](https://www.rfc-editor.org/rfc/rfc8484) - IETF, DNS over HTTPS. Free. Accessed 2026-08-13.
- [RFC 5452](https://www.rfc-editor.org/rfc/rfc5452) - IETF, on forged answers and the randomisation measures that answer them. Free. Accessed 2026-08-13.
- [RFC 5155](https://www.rfc-editor.org/rfc/rfc5155) - IETF, NSEC3, referenced in the deeper panel on proving a name does not exist. Free. Accessed 2026-08-13.

**Pictures.** A freely licensed file from Wikimedia Commons, downloaded and served
from this site rather than linked across to somebody else's server. Resized and
otherwise unaltered.

- [nCipher nShield F3 hardware security module](https://commons.wikimedia.org/wiki/File:NCipher_nShield_F3_Hardware_Security_Module.jpg) by Alexander Klink, [CC BY 3.0](https://creativecommons.org/licenses/by/3.0/).

**Where the output came from.** Both Linux blocks ran on the `dns-secure`
namespace topology through `blog/scripts/netlab.sh`. The zone is signed with keys
generated during the build, and the resolver is given the zone's key-signing key
as a trust anchor rather than following the chain of DS records up through the
parents. That is a shortcut and it is worth naming: validation below the anchor is
the real algorithm and produces the real failure, and what is skipped is the part
that would need three more signed zones to demonstrate the same point. The
tampering is a one character edit to the signed zone file followed by a reload,
which is exactly the shape of the mistake it stands in for. The Windows and macOS
blocks came from GitHub Actions runners through `blog/scripts/hostcap.sh`.

**If you also work on Linux.** [TLS certificates and ACME](/learn/linux-plus/tls-certificates-and-acme)
on the Linux+ track covers the other public key hierarchy a name depends on, and
the two are worth holding apart: that one proves you reached the right server,
this one proves you were told the right address.
