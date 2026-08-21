---
title: "Name resolution tools"
description: "The name resolves on your machine and not on theirs. Querying a specific server instead of the default one, reading an answer section, telling an authoritative answer from a cached copy by one flag, and doing forward and reverse lookups with the tool the exam names."
deck: "The name resolves on your machine and not on theirs"
track: "network-plus"
level: "working"
order: 650
objectives:
  - "Query a specific name server rather than the default resolver"
  - "Read the answer section of a lookup"
  - "Tell an authoritative answer from a non-authoritative one by its flag"
  - "Do forward and reverse lookups"
  - "Name the tool the exam uses on each platform"
prerequisites: ["how-dns-resolution-works"]
tags: ["network-plus", "networking", "troubleshooting", "tools"]
updated: 2026-08-19
draft: false
examObjectives:
  - exam: "n10-009"
    domain: "5.0"
    objective: "5.5"
sources:
  - title: "RFC 1035, Domain Names, Implementation and Specification"
    url: "https://www.rfc-editor.org/rfc/rfc1035"
    publisher: "IETF"
    accessed: 2026-08-19
    tier: 1
  - title: "dig(1)"
    url: "https://man.openbsd.org/dig.1"
    publisher: "OpenBSD / ISC"
    accessed: 2026-08-19
    tier: 1
  - title: "RFC 1912, Common DNS Operational and Configuration Errors"
    url: "https://www.rfc-editor.org/rfc/rfc1912"
    publisher: "IETF"
    accessed: 2026-08-19
    tier: 1
symptoms:
  - symptom: "A name resolves on one machine and not on another"
    anchor: "querying-a-specific-server"
  - symptom: "An answer looks correct but is a stale cached copy"
    anchor: "authoritative-or-a-copy-one-flag-says-which"
---

> **Before you read.** A colleague says a site is down. On your machine the name
> resolves and the site loads. On theirs, the same name returns an old address, or
> nothing. Same name, same internet, two different answers.
>
> **Whose answer is right, and how do you find out without guessing?**

Name resolution is where "it works for me" lives, because two machines can ask the
same question of different servers, or ask the same server and get a cached answer
of a different age, and both believe they are right. The tools here let you ask a
named server directly and read exactly what it said, which turns "it works for me"
into a question with an answer.

### Some words you will need

<dl class="terms">
<dt>resolver</dt>
<dd>The server your machine asks by default. It does the walking down the hierarchy from topic 44 and caches the result.</dd>
<dt>authoritative</dt>
<dd>An answer from a server that owns the zone. It is the source, not a copy, and it carries a flag saying so.</dd>
<dt>non-authoritative</dt>
<dd>An answer from a resolver's cache. Correct if fresh, and it says it is a copy rather than the source.</dd>
<dt>forward lookup</dt>
<dd>Name to address, the usual direction.</dd>
<dt>reverse lookup</dt>
<dd>Address back to a name, using the special in-addr.arpa hierarchy.</dd>
</dl>

## What breaks without this

**You debug the wrong machine.** When a name resolves differently in two places, the
fault is in whichever server gave the wrong answer, and you cannot tell which without
asking each one directly.

**A stale answer looks like a correct one.** A resolver serving an old cached record
returns a clean, confident, wrong address, and nothing about the answer says old
unless you read the flag that distinguishes a copy from the source.

**A tool queries a different resolver than the program does.** The tool you test with
and the application that failed may not ask the same server, so a lookup that succeeds
in the tool proves less than it seems about why the application could not resolve.

## Querying a specific server

The default lookup asks your configured resolver, which is fine until two machines
disagree, at which point the useful move is to ask a named server directly and compare.
Every tool here takes a server argument for exactly this. The lab has a full hierarchy
from topic 44: a root, a top level, an authoritative server for `lab.example`, and a
recursive resolver. The topology is
[`dns-web.sh`](https://github.com/rlwilliamson-dev/azure-resume/blob/main/blog/scripts/topologies/dns-web.sh).

Here is the same name asked of the server that holds it, and then of a resolver that
has been asked for it before.

<details class="predict">
<summary>One server asked directly for a name it holds. Does the answer say it is authoritative, and where in the output would you see that?</summary>

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology dns-web
# commands run on client
# ask the authoritative server for the zone directly
$ dig @10.0.0.3 www.lab.example A +noall +comments +answer
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 27872
;; flags: qr aa rd; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1
;; WARNING: recursion requested but not available

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 1232
; COOKIE: 6270dfb53723f3db010000006a85ac6875b03d6cd2be41af (good)
;; ANSWER SECTION:
www.lab.example.	3600	IN	A	203.0.113.10

# ask the resolver, which fetches the same answer on your behalf
$ dig @10.0.0.4 www.lab.example A +noall +comments +answer
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 1219
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 1232
; COOKIE: 585d8cd46d723982010000006a85ac6811bc219497718ed3 (good)
;; ANSWER SECTION:
www.lab.example.	3600	IN	A	203.0.113.10
```

</details>

Both say `www.lab.example` is `203.0.113.10`. What differs is one line of the header,
and it is the whole topic.

<details class="deeper">
<summary>If you already debug resolution: the resolver the tool uses is not always the one the application uses</summary>

Querying a named server directly is the right technique and it hides a difference that
catches people out on modern desktops.

The tool asks the server you name, directly, using its own resolver code. The application
having the problem goes through the operating system's resolution machinery, which on
current systems may consult a local caching service, may apply per-domain rules sending
different suffixes to different servers, may use a search list, and may have a VPN client
inserting its own resolver for some names and not others.

So a test that succeeds proves the server holds the record, and it does not prove the
application would have reached that server. The two diverge most on exactly the machines
where people are debugging: laptops with a VPN, split tunnelling, and a corporate suffix
handled differently from everything else.

Which is why the second test is worth running: ask the machine the way an application
would, without naming a server, and compare. Where they differ, the fault is in the
machine's own resolution configuration rather than in any server, and no amount of querying
servers directly will show it. That is a five-second addition to a test people already run,
and it separates two very different investigations.

</details>

## Authoritative, or a copy: one flag says which

Look at the `flags:` line in each answer above. The query to the authoritative server,
`10.0.0.3`, carries `aa`, which stands for authoritative answer: this server owns the
zone, and its answer is the source of truth. The query to the resolver, `10.0.0.4`,
carries `ra`, recursion available, and crucially does not carry `aa`: the resolver
fetched the answer and is handing you a copy from its cache, correct while it is fresh
and its own thing once the original changes.

<figure class="learn-figure">
<svg viewBox="0 0 720 244" role="img" aria-labelledby="aa-title" style="width:100%;height:auto;">
<title id="aa-title">A client querying an authoritative server that owns the zone and answers with the aa flag, next to a resolver that holds a cached copy and answers without it</title>
<g fill="currentColor">
<text x="14" y="20" font-size="11">the same address from two servers, and one flag says which one owns it</text>
<rect x="24" y="96" width="110" height="44" rx="4" fill="currentColor" fill-opacity="0.1" stroke="currentColor" stroke-opacity="0.7"/>
<text x="79" y="122" text-anchor="middle" font-size="10.5">client</text>
<rect x="470" y="40" width="230" height="66" rx="5" fill="var(--accent)" fill-opacity="0.1" stroke="var(--accent)" stroke-opacity="0.85" stroke-width="1.5"/>
<text x="486" y="60" font-size="10.5" fill="var(--accent)">authoritative server</text>
<text x="486" y="78" font-size="9.5" fill-opacity="0.85">owns the zone file</text>
<text x="486" y="94" font-size="9.5" fill="var(--accent)">answers with aa</text>
<rect x="470" y="132" width="230" height="66" rx="5" fill="currentColor" fill-opacity="0.05" stroke="currentColor" stroke-opacity="0.7"/>
<text x="486" y="152" font-size="10.5">resolver</text>
<text x="486" y="170" font-size="9.5" fill-opacity="0.8">holds a cached copy</text>
<text x="486" y="186" font-size="9.5" fill-opacity="0.8">answers with ra, no aa</text>
<path d="M 134 108 C 300 92 340 73 470 73" stroke="var(--accent)" stroke-width="1.6" fill="none"/>
<path d="M 462 68 l 9 5 l -9 5" stroke="var(--accent)" stroke-width="1.6" fill="none"/>
<path d="M 134 128 C 300 144 340 163 470 165" stroke="currentColor" stroke-opacity="0.6" stroke-width="1.4" fill="none"/>
<path d="M 462 160 l 9 5 l -9 5" stroke="currentColor" stroke-opacity="0.6" stroke-width="1.4" fill="none"/>
<text x="200" y="214" font-size="9.5" fill-opacity="0.75">same name, same address, different authority</text>
</g></svg>
<figcaption>Both servers return 203.0.113.10 for the name, and the flag is what separates the source from a copy. The authoritative server holds the zone file and stamps its answer aa, so it is the truth by definition. The resolver walked the hierarchy once, cached what it found, and hands out that copy with ra and no aa, which is correct until the authoritative record changes and the cached copy has not yet expired. When two machines disagree about a name, this flag is how you tell the machine reading stale cache from the one reading the source.</figcaption>
</figure>

The tool the exam names, `nslookup`, prints the same distinction in words rather than
a flag.

<details class="predict">
<summary>The same query through the tool the exam names rather than the one the lab has been using. Does the output say the same things?</summary>

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology dns-web
# commands run on client
# nslookup against the resolver: note what it says about authority
$ nslookup www.lab.example 10.0.0.4
Server:		10.0.0.4
Address:	10.0.0.4#53

Non-authoritative answer:
Name:	www.lab.example
Address: 203.0.113.10
Name:	www.lab.example
Address: 2001:db8:113::10
```

</details>

"Non-authoritative answer" is `nslookup` saying exactly what the missing `aa` flag
said: this came from a cache, not from the zone's owner. When a name resolves wrongly
somewhere, this line is the fastest way to tell a resolver serving stale cache from an
authoritative server that genuinely holds a bad record, and they need different fixes:
the first clears on its own or with a cache flush, the second is a change to the zone.

<details class="deeper">
<summary>If you already chase stale answers: why the same name resolves differently in two places</summary>

Two machines getting different answers for one name is common and has a short list of
causes, all of which the flag helps separate.

If both answers are non-authoritative and they differ, it is caching: one resolver holds an
older copy, and the record's remaining lifetime says how long that will last. That is
waiting rather than fixing.

If one is authoritative and disagrees with a non-authoritative answer, the same applies and
you now know which one is right. If two authoritative servers disagree, that is a genuine
fault: a zone transfer has failed and one secondary is serving an old copy, which topic 46's
serial number governs.

And if the same resolver returns different answers to different clients, nothing is stale.
Something is answering differently by design, which means split-horizon serving internal and
external views, or a filtering resolver returning a substitute address, or two different
resolvers behind one address. That last case is common with anycast and is worth ruling in
early, because chasing it as a caching problem never converges.

The flag does not tell you which of these it is by itself. What it does is split the
possibilities in two on the first query, which is worth more than any single subsequent
test.

</details>

## Forward and reverse

Everything so far is a forward lookup: a name to an address. The reverse, an address
back to a name, uses a separate hierarchy, and the exam wants both. The cross platform
captures below show the reverse form on real machines, turning `8.8.8.8` back into
`dns.google`. Reverse lookups matter for mail, for logging that shows names instead of
numbers, and for the check that an address and its name agree in both directions, which
is a common configuration error when they do not.

<details class="deeper">
<summary>If you already work on networks: why the tool and the program disagree, and the cache in front of both</summary>

Two things trip up experienced people here, and both are about the tool not asking what
the program asked.

The first is that `dig` and `nslookup` talk to a DNS server directly, and many
applications do not. A program usually calls the system resolver library, which may
consult `/etc/hosts` or its equivalent first, may use a local caching stub, and may apply
search domains that append a suffix to a bare name. So a name that fails in an application
can succeed in `dig`, because `dig` went straight to the server and skipped the hosts file,
the stub cache, and the search-domain rewrite the application went through. When they
disagree, the difference is usually one of those steps, and the fix is to make the tool ask
the same way, by checking the hosts file and the search domains rather than only the server.

The second is the client cache, which sits in front of everything on some platforms.
Windows keeps its own DNS cache with a countdown per record, so a machine can hold a stale
answer after the resolver behind it has the fresh one, and the record is current on the
next machine and old on this one. This is exactly the "works for me" split the topic opened
on, and on Windows it is often resolved not by touching any server but by clearing the
client cache. The countdown the client shows is its own copy of the TTL, ticking down
independently, which is why two machines that ask the same resolver can still answer
differently for a minute or two after a change.

The practical rule that falls out is to name the layer before blaming it: the authoritative
record, the resolver's cache, the client's cache, and the local hosts file are four
different places an answer can come from, and the tools let you ask each one on purpose
instead of guessing which answered.

</details>

## Across platforms

`nslookup` is the tool the exam names and it exists on all three platforms. `dig` is the
one most engineers prefer because it shows the flags and the answer section in full, and
it is on Linux and macOS.

**On Linux**, `dig` is the tool, and the lab above is Linux `dig`: `dig @server name type`
to ask a specific server, `dig -x address` for a reverse lookup, and the `+noall +comments
+answer` used above to show the header flags and the answer without the noise.

**On macOS**, both `nslookup` and `dig` are present. `nslookup` prints the non-authoritative
line; `dig` shows the flags, the answer section, and reverse lookups with `-x`.

```bash
# macOS 26.5.2, arm64
$ nslookup example.com
Server:		192.168.64.1
Address:	192.168.64.1#53

Non-authoritative answer:
Name:	example.com
Address: 104.20.23.154

# The same question through dig, which shows the answer section and the flags
$ dig +noall +answer +comments example.com A
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 32544
;; flags: qr rd ra; QUERY: 1, ANSWER: 2, AUTHORITY: 0, ADDITIONAL: 1
;; ANSWER SECTION:
example.com.		291	IN	A	104.20.23.154
example.com.		291	IN	A	172.66.147.243

# A reverse lookup, address back to a name
$ dig +noall +answer -x 8.8.8.8
8.8.8.8.in-addr.arpa.	4502	IN	PTR	dns.google.
```

**On Windows**, `nslookup` is the tool the exam names, and `Resolve-DnsName` is the newer
cmdlet that breaks out the type and TTL. Both do forward and reverse.

```powershell
# Microsoft Windows Server 2025 Datacenter, version 10.0.26100.0
> nslookup example.com
Server:  UnKnown
Address:  168.63.129.16
Name:    example.com
Addresses:  172.66.147.243
	  104.20.23.154

# The same, asking a specific server rather than the default one
> nslookup example.com 1.1.1.1
Server:  one.one.one.one
Address:  1.1.1.1
Name:    example.com
Addresses:  172.66.147.243
	  104.20.23.154

# A reverse lookup, address back to a name
> nslookup 8.8.8.8
Name:    dns.google
Address:  8.8.8.8
```

The macOS `dig` shows the `ra` flag and no `aa`, which is the resolver-copy answer the lab
demonstrated, and its reverse lookup turns the address into `dns.google`. The Windows
`nslookup` does the same three jobs the exam asks for: a forward lookup, the same lookup
against a named server, and a reverse lookup. The one to carry forward is that when two
machines disagree, you ask each one's resolver by name, the way the second Windows command
asks `1.1.1.1` directly, and compare what each returns.

## Prove it

The two lab blocks are from
[`dns-web.sh`](https://github.com/rlwilliamson-dev/azure-resume/blob/main/blog/scripts/topologies/dns-web.sh),
and the cross platform blocks are real machines through the capture workflow. The lab is the
only place the `aa` flag can be shown set, because no public resolver is ever authoritative
for a public name, so the authoritative answer is something only a lab with its own zone can
produce.

**RFC 1035.** The DNS specification, and the source of the header flags. Read the part on the
`AA` bit and note that it is defined as "this server is an authority for the domain name in
the question", which is exactly what the lab's authoritative server sets and the resolver does
not.

**dig(1).** The manual, for the query options. Knowing `@server`, `-x`, and the `+` options
that trim the output is what turns `dig` from a wall of text into a precise question.

## What trips people up

### 1. Trusting the default resolver when two machines disagree

The default lookup asks your resolver, and when the fault is a resolver serving a wrong answer,
you have to ask a named server directly to see it. Every tool takes a server argument for this.

### 2. Missing the authoritative flag

A correct-looking answer from a cache is still a copy. The `aa` flag, or `nslookup`'s
"Non-authoritative answer" line, is the only thing on the answer that says whether you reached
the source or a copy.

### 3. Assuming the tool and the application resolve the same way

`dig` and `nslookup` ask a server directly. An application goes through the hosts file, a stub
cache, and search domains first, so a lookup that works in the tool can still fail in the
program for a reason above the server.

### 4. Forgetting the client cache

Some platforms, notably Windows, cache answers on the client with their own countdown, so a
machine can hold a stale record after the resolver behind it is fresh. Clearing the client
cache, not any server, is often the fix.

### 5. Ignoring the reverse direction

Reverse lookups matter for mail and logging, and an address whose name does not match in both
directions is a common misconfiguration the forward lookup never shows.

### 6. Reading the TTL as the record's age everywhere

The countdown a resolver or client shows is its own copy of the TTL, ticking down
independently, which is why two caches of the same record can show different times and answer
differently for a while after a change.

## Work it through

The name that resolves for you and not for them, worked with the tools.

First, stop trusting either default resolver, because the whole problem is that the two
machines are asking different servers or holding caches of different ages. Ask a named server
directly from both machines, the same server, and compare what each returns. If the same server
gives both machines the same answer, the fault is in one machine's own resolver or client cache,
not in the name.

Then read the authority on each answer. An authoritative answer, with `aa`, is the source and is
correct by definition; a non-authoritative one is a cache and can be stale. If your machine gets
the right address authoritatively and theirs gets a wrong one non-authoritatively, theirs is
reading stale cache, and the fix is a cache clear rather than a change to the zone.

Then, if the authoritative server itself returns the wrong record, the fault is in the zone, and
that is a change to the DNS records from topic 46, not a caching problem at all. The `aa` flag is
what tells these two apart, and they have completely different fixes.

Then check the client and the hosts file before declaring the network at fault, because on some
platforms a stale client cache or a stray hosts entry produces exactly this split with nothing
wrong on any server. Name the layer the answer came from, and the "works for me" stops being a
mystery.

## Try it

**Run the lab and read the two flags.** In
[`dns-web.sh`](https://github.com/rlwilliamson-dev/azure-resume/blob/main/blog/scripts/topologies/dns-web.sh)
ask `10.0.0.3` and `10.0.0.4` for the same name and compare the `flags:` line. The `aa` on one and
not the other is the whole distinction between a source and a copy.

**Ask two public resolvers the same question.** `dig @1.1.1.1 example.com` and `dig @8.8.8.8
example.com`, or the `nslookup` equivalents, and compare. When they differ, one is holding an
older cache, and neither is authoritative, which is why both say non-authoritative.

**Do a reverse lookup on an address you know.** Turn an address back into a name with `dig -x` or
`nslookup <address>`, and check whether the name it returns points back to the same address. When
it does not, you have found the forward-and-reverse mismatch that trips up mail servers.

## Check yourself

<details class="qa">
<summary>A name resolves for you and returns an old address for a colleague. How do you find which server is wrong?</summary>

Ask a named server directly from both machines, the same server, rather than trusting each
machine's default resolver. If that one server gives both of you the same answer, the fault is in
one machine's own resolver or client cache, not in the name.

Comparing what each resolver returns, by asking it by name with `dig @server` or `nslookup name
server`, is the move. The default lookup hides which server answered; naming the server makes the
disagreement visible.

</details>

<details class="qa">
<summary>What does the aa flag mean, and why does its absence matter?</summary>

`aa` is the authoritative-answer flag: the server that answered owns the zone, so its answer is the
source of truth by definition. Its absence means the answer came from a resolver's cache, which is
a copy, correct while fresh and its own thing once the original record changes.

It matters because a cached answer can be confidently wrong. The `aa` flag, or `nslookup`'s
"Non-authoritative answer" line, is the only thing that tells you whether you reached the source or
a copy, and stale cache and a bad authoritative record need different fixes.

</details>

<details class="qa">
<summary>A lookup succeeds in dig but the application still cannot resolve the name. Why might that be?</summary>

Because `dig` asks a DNS server directly, and the application goes through the system resolver
first: the hosts file, a local stub cache, and any search domains that rewrite a bare name. The
failure is usually in one of those steps, above the server `dig` queried.

So a successful `dig` proves the server has the answer, not that the application's whole path to it
works. Checking the hosts file and the search domains, and asking the tool to resolve the same way,
is how you close the gap.

</details>

<details class="qa">
<summary>Why can two machines that ask the same resolver still show different answers after a change?</summary>

Because some platforms cache answers on the client, with their own countdown per record. Windows
does this. After the authoritative record changes and the resolver picks up the new one, a client
holding the old answer keeps serving it until its own countdown expires, so one machine is fresh and
another is stale for a minute or two.

The countdown the client shows is its own copy of the TTL, ticking down independently of the
resolver's. Clearing the client cache, not touching any server, is what resolves that split.

</details>

<details class="qa">
<summary>What is a reverse lookup, and what is one thing it is used to check?</summary>

A reverse lookup turns an address back into a name, using the separate in-addr.arpa hierarchy rather
than the normal forward tree. It is the opposite direction from the usual name-to-address lookup.

One common use is checking that an address and its name agree in both directions: the name resolves
to the address forward, and the address resolves to the name in reverse. Mail servers often require
this, and a mismatch, where the two directions disagree, is a configuration error the forward lookup
alone never reveals.

</details>

## References

- [RFC 1035](https://www.rfc-editor.org/rfc/rfc1035) - IETF, the DNS specification and the source of the header flags, including the `AA` authoritative-answer bit. Free. Accessed 2026-08-19.
- [dig(1)](https://man.openbsd.org/dig.1) - OpenBSD / ISC, the manual for the query tool and its `@server`, `-x`, and `+` options. Free. Accessed 2026-08-19.
- [RFC 1912](https://www.rfc-editor.org/rfc/rfc1912) - IETF, common DNS errors, including the forward-and-reverse mismatch. Free. Accessed 2026-08-19.

**Where the numbers came from.** The two lab blocks are from
[`dns-web.sh`](https://github.com/rlwilliamson-dev/azure-resume/blob/main/blog/scripts/topologies/dns-web.sh)
through `netlab.sh`, on the kernel in each header, and the lab is the only place the `aa` flag can be
shown set because no public resolver is authoritative for a public name. The Windows and macOS blocks
are real machines through the capture workflow, headed with each one's version; `example.com` and
`8.8.8.8` are stable public names, and the addresses are whatever those resolvers returned at capture
time.

**If you also work on Linux.** The lab is Linux `dig`, and it is the tool worth learning first
because its output names the parts the concepts refer to: the `flags:` line with `aa` and `ra`, the
`ANSWER SECTION`, and the TTL per record. `nslookup` is the portable name the exam uses and exists
everywhere; `dig` is the one that shows you why an answer is what it is.
