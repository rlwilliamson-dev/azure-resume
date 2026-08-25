---
title: "Certificates and what they bind"
description: "What a certificate actually asserts, who signs the assertion, why your machine trusts a few hundred organisations you never chose, what goes into a signing request and what the authority decides for you, and when a self-signed certificate is the right answer rather than a shortcut."
deck: "Your machine trusts about a hundred and fifty organisations you never chose"
track: "security-plus"
level: "working"
order: 100
objectives:
  - "Read the fields of a real certificate and say what each one asserts"
  - "Explain what a chain proves and why the root is not on the wire"
  - "Say what you are trusting when you trust a certificate authority"
  - "Describe what a signing request contains and what the authority decides"
  - "Choose between a self-signed certificate, a private authority and a public one"
  - "Choose between a wildcard and a list of names, and say what each costs"
prerequisites: ["what-security-actually-protects"]
tags: ["security-plus", "security", "cryptography", "pki"]
updated: 2026-08-21
draft: false
examObjectives:
  - exam: "sy0-701"
    domain: "1.0"
    objective: "1.4"
sources:
  - title: "RFC 5280, Internet X.509 Public Key Infrastructure Certificate and CRL Profile"
    url: "https://www.rfc-editor.org/rfc/rfc5280.html"
    publisher: "IETF"
    accessed: 2026-08-21
    tier: 1
  - title: "RFC 6125, Representation and Verification of Domain-Based Application Service Identity"
    url: "https://www.rfc-editor.org/rfc/rfc6125.html"
    publisher: "IETF"
    accessed: 2026-08-21
    tier: 1
  - title: "CA/Browser Forum Baseline Requirements for the Issuance and Management of Publicly-Trusted TLS Server Certificates"
    url: "https://cabforum.org/working-groups/server/baseline-requirements/documents/"
    publisher: "CA/Browser Forum"
    accessed: 2026-08-21
    tier: 1
  - title: "RFC 6962, Certificate Transparency"
    url: "https://www.rfc-editor.org/rfc/rfc6962.html"
    publisher: "IETF"
    accessed: 2026-08-21
    tier: 1
  - title: "x509(1) command reference"
    url: "https://docs.openssl.org/master/man1/openssl-x509/"
    publisher: "OpenSSL Project"
    accessed: 2026-08-21
    tier: 1
  - title: "About Certificate Stores"
    url: "https://learn.microsoft.com/en-us/windows-hardware/drivers/install/certificate-stores"
    publisher: "Microsoft"
    accessed: 2026-08-21
    tier: 1
symptoms:
  - symptom: "The certificate is valid and the browser still refuses it"
    anchor: "what-a-certificate-actually-binds"
  - symptom: "A certificate exists for your domain that nobody at your company requested"
    anchor: "every-certificate-ever-issued-for-your-name"
---

> **Before you read.** Open a browser and look at the list of certificate
> authorities it trusts. There are a few hundred of them, from a dozen countries,
> and you have never heard of most.
>
> Any one of them can issue a certificate for your bank's domain name, and your
> browser will accept it.
>
> **So what does the padlock actually tell you?**

A certificate is a signed claim that a particular public key belongs to a
particular name. That is the whole of it, and almost every mistake people make
with certificates comes from believing it says more.

### Some words you will need

<dl class="terms">
<dt>certificate</dt>
<dd>A file binding a name to a public key, signed by somebody. The signature is the only part doing any work.</dd>
<dt>certificate authority</dt>
<dd>An organisation that signs certificates for other people, and whose own certificate is already in your trust store. Abbreviated CA. Certificate authorities are the third-party half of the choice below.</dd>
<dt>public key infrastructure</dt>
<dd>The whole arrangement: authorities, the certificates they issue, the stores that trust them and the process for withdrawing one. Abbreviated PKI.</dd>
<dt>trust store</dt>
<dd>The list of authorities your machine has decided to believe. Shipped with the operating system or the browser, and not chosen by you.</dd>
<dt>root of trust</dt>
<dd>The one certificate in a chain that is trusted because it is in the store, rather than because something else vouched for it.</dd>
<dt>certificate signing request</dt>
<dd>The file you send an authority to ask for a certificate. Contains your public key and the name you want on it. Abbreviated CSR.</dd>
<dt>subject alternative name</dt>
<dd>The field that actually lists the names a certificate is valid for. Abbreviated SAN.</dd>
<dt>self-signed</dt>
<dd>A certificate whose issuer is itself. Nobody vouched for it, which is not the same as it being worthless.</dd>
</dl>

## What breaks without this

**You trust the padlock to mean something it does not.** A valid certificate says
the connection is encrypted and the name matches. It says nothing about whether
the site is honest, whether the company is who they claim, or whether the
certificate was issued to the right person.

**A service breaks at renewal and nobody knows why.** Certificates expire on a
date somebody chose months ago. The failure arrives without a change, at a time
nobody is watching, and the error the application prints usually names the wrong
thing.

**You cannot tell a misissued certificate from a legitimate one.** Any of the
authorities in your store can issue for any name. If you are not watching, a
certificate for your domain issued to somebody else looks exactly like yours.

## What a certificate actually binds

Here is a real one, read off a real server.

<details class="predict">
<summary>Before you look: which of these fields decides whether a browser accepts the certificate for the name you typed?</summary>

```bash
# AlmaLinux 10.2, x86_64
$ dnf -q -y install openssl >/dev/null 2>&1; openssl s_client -connect rlwilliamson.dev:443 -servername rlwilliamson.dev </dev/null 2>/dev/null | openssl x509 -noout -subject -issuer -dates -serial -ext subjectAltName,basicConstraints,keyUsage
subject=CN=rlwilliamson.dev
issuer=C=US, O=DigiCert Inc, OU=www.digicert.com, CN=GeoTrust TLS RSA CA G1
notBefore=May 14 00:00:00 2026 GMT
notAfter=Nov 14 23:59:59 2026 GMT
serial=0AC0E9B2C67B297EA0311845F3BB95EF
X509v3 Subject Alternative Name: 
    DNS:rlwilliamson.dev
X509v3 Key Usage: critical
    Digital Signature, Key Encipherment
X509v3 Basic Constraints: critical
    CA:FALSE
```

</details>

Six things worth naming in that block, and one of them is the answer.

The **subject** is the name being claimed. The **issuer** is who signed the
claim, and it is a different organisation from the subject, which is the normal
case. **notBefore** and **notAfter** bound the period the signature is meant to
be believed. The **serial** is the authority's own reference for this issuance,
unique to that authority, and it is what you quote when you want it revoked.

The field that decides the name check is **Subject Alternative Name**, not the
subject. The common name in the subject is legacy: RFC 6125 has clients match on
the SAN, and browsers have refused to fall back to the common name for years. A
certificate with the right common name and the wrong SAN fails, which is the
single most confusing certificate error there is because the field a person reads
first is the field the software ignores.

The last two lines are what stop this certificate being used to sign others.
**Basic Constraints CA:FALSE** says it is not an authority, and **Key Usage** is
marked critical, which means a client that does not understand the extension must
reject the certificate rather than ignore the extension.

<details class="deeper">
<summary>If you already run PKI: why the common name survived, and what to do with it</summary>

The common name was the original name field, from a design where a certificate
identified an organisation rather than a service. It was never meant to hold a
DNS name and it holds exactly one, which is why the subject alternative name
extension exists at all.

The CA/Browser Forum's baseline requirements make the situation explicit: the
common name field is deprecated for publicly trusted TLS certificates and, if
present, must contain a value that also appears in the subject alternative name.
So it carries no information the SAN does not, and it cannot carry more than one
name.

Two practical consequences. Any tooling that reads the subject to find out what a
certificate covers is wrong, and will be wrong quietly on every certificate with
more than one name. And a request that sets only the common name will produce
either a rejection or a certificate with a SAN the authority derived for you,
which is not necessarily the SAN you wanted.

</details>

## The chain, and the certificate that is not on the wire

The issuer above is not in your trust store. What is in your store is the
organisation that vouched for the issuer.

```bash
# AlmaLinux 10.2, x86_64
$ dnf -q -y install openssl >/dev/null 2>&1; openssl s_client -connect rlwilliamson.dev:443 -servername rlwilliamson.dev -showcerts </dev/null 2>/dev/null | grep -E "^ [0-9] s:|^   i:|^ *[0-9] s:|s:|i:" | head -12
 0 s:CN=rlwilliamson.dev
   i:C=US, O=DigiCert Inc, OU=www.digicert.com, CN=GeoTrust TLS RSA CA G1
 1 s:C=US, O=DigiCert Inc, OU=www.digicert.com, CN=GeoTrust TLS RSA CA G1
   i:C=US, O=DigiCert Inc, OU=www.digicert.com, CN=DigiCert Global Root G2
```

Two certificates, and read them as a sentence. Certificate 0 is for
`rlwilliamson.dev` and was issued by GeoTrust TLS RSA CA G1. Certificate 1 is for
GeoTrust TLS RSA CA G1 and was issued by DigiCert Global Root G2.

**And then it stops.** The root is not in the block, because the server does not
send it. It has no reason to: a client that does not already have the root cannot
be persuaded to trust it by receiving a copy, and a client that does have it does
not need one. The chain on the wire runs from the leaf up to something the client
already believes, and stops there.

<figure class="learn-figure">
<svg viewBox="0 0 720 330" role="img" aria-labelledby="chain-title" style="width:100%;height:auto;">
<title id="chain-title">A two-certificate chain sent by a server, with each certificate's issuer naming the subject of the one above it, and the root certificate sitting outside the chain in the client's own trust store</title>
<g fill="currentColor">
<text x="14" y="20" font-size="11">the server sends two, and the one that decides is the one it does not send</text>
<rect x="74" y="40" width="342" height="176" rx="6" fill="currentColor" fill-opacity="0.04" stroke="currentColor" stroke-opacity="0.55" stroke-width="1.4" stroke-dasharray="6 4"/>
<text x="86" y="56" font-size="10" fill-opacity="0.8">sent by the server</text>
<rect x="90" y="64" width="310" height="52" rx="4" fill="var(--bg)" stroke="var(--accent)" stroke-width="1.8"/>
<text x="104" y="83" font-size="10">subject   CN=rlwilliamson.dev</text>
<text x="104" y="103" font-size="10">issuer    CN=GeoTrust TLS RSA CA G1</text>
<text x="440" y="83" font-size="10" fill-opacity="0.8">certificate 0</text>
<text x="440" y="103" font-size="10" fill-opacity="0.8">the leaf</text>
<path d="M 245 156 V 122" stroke="currentColor" stroke-opacity="0.75" stroke-width="1.6"/>
<path d="M 240 130 L 245 120 L 250 130" fill="none" stroke="currentColor" stroke-opacity="0.75" stroke-width="1.6"/>
<text x="258" y="146" font-size="10" fill-opacity="0.8">signs</text>
<rect x="90" y="156" width="310" height="52" rx="4" fill="var(--bg)" stroke="currentColor" stroke-opacity="0.75" stroke-width="1.4"/>
<text x="104" y="175" font-size="10">subject   CN=GeoTrust TLS RSA CA G1</text>
<text x="104" y="195" font-size="10">issuer    CN=DigiCert Global Root G2</text>
<text x="440" y="175" font-size="10" fill-opacity="0.8">certificate 1</text>
<text x="440" y="195" font-size="10" fill-opacity="0.8">the intermediate</text>
<path d="M 245 254 V 214" stroke="currentColor" stroke-opacity="0.75" stroke-width="1.6" stroke-dasharray="5 4"/>
<path d="M 240 222 L 245 212 L 250 222" fill="none" stroke="currentColor" stroke-opacity="0.75" stroke-width="1.6"/>
<text x="258" y="240" font-size="10" fill-opacity="0.8">signs</text>
<rect x="74" y="246" width="342" height="70" rx="6" fill="currentColor" fill-opacity="0.04" stroke="currentColor" stroke-opacity="0.55" stroke-width="1.4" stroke-dasharray="2 3"/>
<rect x="90" y="256" width="310" height="52" rx="4" fill="var(--bg)" stroke="currentColor" stroke-opacity="0.75" stroke-width="1.4" stroke-dasharray="4 3"/>
<text x="104" y="275" font-size="10">subject   CN=DigiCert Global Root G2</text>
<text x="104" y="295" font-size="10">issuer    CN=DigiCert Global Root G2</text>
<text x="440" y="275" font-size="10" fill-opacity="0.8">already in your store</text>
<text x="440" y="295" font-size="10" fill-opacity="0.8">never sent, and self-issued</text>
</g></svg>
<figcaption>Two certificates arrive from the server and a third decides the outcome. Certificate 0 names the site and is signed by GeoTrust; certificate 1 names GeoTrust and is signed by DigiCert Global Root G2. The root itself never crosses the wire, because a client that already holds it does not need a copy and a client that does not hold it would have no reason to believe one that arrived. That is why the root is the only certificate in the picture whose subject and issuer are the same name: nothing vouches for it except its presence in a store somebody else chose. The dashed link is the one your machine can only complete from what it already has.</figcaption>
</figure>

<details class="deeper">
<summary>If you have debugged a chain before: the incomplete chain, and why it fails on one client and not another</summary>

The failure mode this creates is the most common certificate problem in
production, and it is asymmetric in a way that wastes days.

A server that sends only the leaf, omitting the intermediate, works fine in a
browser and fails in `curl`, in a Java client, and in most monitoring. The reason
is that browsers cache intermediates they have seen before, and some will fetch a
missing one from the URL in the leaf's Authority Information Access extension.
Command-line clients generally do neither. So the person who reports the problem
cannot reproduce it, and the person who cannot reproduce it owns the server.

The check that settles it is to ask for the chain from outside your own machine
and count the certificates, which is what the block above does. One certificate
where you expected two is the whole diagnosis.

The opposite mistake is sending the root as well. It is harmless to correctness
and it adds a kilobyte to every handshake for no benefit, which on a busy service
is a measurable amount of somebody's bandwidth spent transmitting a file the
recipient already has.

</details>

## What you are trusting, and how much of it there is

The store is the interesting part, because it is the part nobody looks at and the
part that decides everything.

```bash
# AlmaLinux 10.2, x86_64
$ cd /root/pki
echo "self-signed, same name:"
openssl x509 -in ss.crt -noout -subject -issuer
echo
echo "issued by a public CA:"
openssl s_client -connect rlwilliamson.dev:443 -servername rlwilliamson.dev </dev/null 2>/dev/null | openssl x509 -noout -subject -issuer
echo
echo "roots this machine trusts:"
grep -c "BEGIN CERTIFICATE" /etc/pki/tls/certs/ca-bundle.crt
self-signed, same name:
subject=C=GB, O=Example Ltd, CN=payments.example.internal
issuer=C=GB, O=Example Ltd, CN=payments.example.internal

issued by a public CA:
subject=CN=rlwilliamson.dev
issuer=C=US, O=DigiCert Inc, OU=www.digicert.com, CN=GeoTrust TLS RSA CA G1

roots this machine trusts:
146
```

The last number is the one to sit with. **This machine trusts 146 root
certificates.** Not 146 certificates it has checked, or 146 organisations
somebody at your company approved. One hundred and forty-six organisations whose
certificates arrived with the operating system, any of which can issue a
certificate for any name in the world, and all of which your machine will believe
without asking you.

That number is not the same on every platform, and the spread is larger than
people expect.

<figure class="learn-figure">
<svg viewBox="0 0 720 220" role="img" aria-labelledby="stores-title" style="width:100%;height:auto;">
<title id="stores-title">Bars drawn to scale showing the number of root certificates trusted by default on AlmaLinux, macOS and Windows Server, at 146, 158 and 564 respectively</title>
<g fill="currentColor">
<text x="14" y="20" font-size="11">organisations each machine trusts to vouch for any name, counted on 21 August 2026</text>
<text x="14" y="56" font-size="10">AlmaLinux 10.2</text>
<rect x="180" y="44" width="110" height="16" rx="2" fill="currentColor" fill-opacity="0.3" stroke="currentColor" stroke-opacity="0.7"/>
<text x="300" y="56" font-size="10">146</text>
<text x="14" y="94" font-size="10">macOS 26.5.2</text>
<rect x="180" y="82" width="119" height="16" rx="2" fill="currentColor" fill-opacity="0.3" stroke="currentColor" stroke-opacity="0.7" stroke-dasharray="4 3"/>
<text x="309" y="94" font-size="10">158</text>
<text x="14" y="132" font-size="10">Windows Server 2025</text>
<rect x="180" y="120" width="423" height="16" rx="2" fill="var(--accent)" fill-opacity="0.35" stroke="var(--accent)" stroke-width="1.6"/>
<text x="613" y="132" font-size="10">564</text>
<path d="M 180 150 V 40" stroke="currentColor" stroke-opacity="0.35" stroke-width="1"/>
<text x="14" y="180" font-size="10" fill-opacity="0.8">any one of them can issue a certificate for any name, and none was chosen by the person using the machine</text>
<text x="14" y="200" font-size="10" fill-opacity="0.8">on Windows all 564 are self-issued, which is the definition of a root stated as a measurement</text>
</g></svg>
<figcaption>Three machines doing comparable work, and the number of organisations each one trusts without being asked differs by a factor of nearly four. The counts are not a quality signal: each of Microsoft, Apple and the Linux distributions runs its own root programme with its own inclusion criteria, and an authority applies to each separately. What the picture is for is the scale of the assumption. Trust here is not scoped by name, so every bar is a count of organisations that could issue a certificate for your bank's domain and have it accepted. The Windows figure is also a measurement of what a root is: all 564 of them name themselves as issuer.</figcaption>
</figure>

<details class="deeper">
<summary>If you already think about trust: why the count differs, and why a smaller store is not obviously better</summary>

The three stores differ because the programmes behind them differ. Each of
Microsoft, Apple, Mozilla and Google runs its own root programme with its own
audit requirements, inclusion criteria and removal process, and a certificate
authority applies to each separately. The counts move as authorities are added,
merged, and distrusted.

The instinct on seeing 564 is to trim it, and the instinct is mostly wrong for a
general-purpose machine. Remove a root and every service that chained to it stops
working, including ones you have never heard of, and the failure arrives as an
unexplained outage in something unrelated. The blast radius of pruning a trust
store is genuinely hard to predict.

Where trimming does work is on a machine with a known and small set of
correspondents: an appliance that talks to three endpoints, a container that
talks to one API. There, replacing the whole store with the two roots that
service actually uses removes 562 organisations from the set that can impersonate
it, and nothing breaks because nothing else was ever contacted. That is the same
argument as an allow list, applied to trust.

The general-purpose answer is not a smaller store. It is pinning, which narrows
trust for one connection rather than for the machine, and monitoring, which is
the last section of this topic.

</details>

## Asking for one, and what the authority decides

You do not create a certificate. You ask for one, with a signing request, and
what you can ask for is narrower than people assume.

<details class="predict">
<summary>A signing request carries a name and a public key. Which of the certificate's fields do you think it also carries?</summary>

```bash
# AlmaLinux 10.2, x86_64
$ cd /root/pki
openssl req -in svc.csr -noout -text | grep -E "Subject:|Public-Key|DNS:|Signature Algorithm" | head -4
echo "fields a CSR does not carry:"
openssl req -in svc.csr -noout -text | grep -ciE "notBefore|notAfter|Issuer:|Serial Number"
        Subject: C=GB, O=Example Ltd, CN=payments.example.internal
                Public-Key: (2048 bit)
                    DNS:payments.example.internal, DNS:pay.example.internal
    Signature Algorithm: sha256WithRSAEncryption
fields a CSR does not carry:
0
```

</details>

The request holds the subject, the public key, the names you want in the subject
alternative name, and a signature over all of it made with the matching private
key. That signature is doing a specific job: it proves to the authority that
whoever sent the request holds the private key for the public key inside it.

**The last line is the point.** A search for `notBefore`, `notAfter`, `Issuer`
and `Serial Number` in the request finds zero of them. The validity period, the
issuer and the serial are not yours to ask for. The authority sets all three, and
that is what makes it an authority rather than a printing service.

<details class="deeper">
<summary>If you have submitted a CSR: what an authority actually validates, and the three levels of it</summary>

For a publicly trusted TLS certificate, the authority validates control of the
name and nothing else. The baseline requirements list the acceptable methods:
publishing a value in DNS, responding to a challenge over HTTP at the name, or
replying to mail at one of a short list of addresses at the domain. That is the
whole of what a domain-validated certificate asserts, and it is what almost every
certificate on the public internet is.

Organisation validation adds a check that the named company exists and that the
requester is connected to it. Extended validation adds more of the same, more
strictly. Both put a company name in the subject, and neither changes what
happens in a browser any more, because the visual distinction that used to
justify the price was removed from every major browser between 2018 and 2019.

The thing worth carrying: the request does not decide what gets validated. The
product you bought decides it, and for the overwhelming majority of certificates
the answer is that somebody proved they could change a DNS record.

</details>

## Self-signed against third-party

A self-signed certificate is one where the issuer field holds the subject. Nobody
vouched for it, and the comparison above shows the difference in one line: the
self-signed certificate names Example Ltd twice, and the public one names
DigiCert as issuer and the site as subject.

Those are the two ends of the choice: self-signed, where you vouch for yourself,
and third-party, where one of the certificate authorities in a trust store
vouches for you. The reflex is that self-signed means insecure. It does not. The encryption is
identical, because the encryption never depended on who signed the certificate.
What you lose is the ability of a stranger to verify the name, and **whether that
matters depends entirely on whether the client is a stranger.**

Three cases, and the decision is different in each.

**A public website.** Use a publicly trusted certificate. Visitors have no
relationship with you, no way to check a fingerprint, and no reason to click
through a warning, and teaching them to click through warnings is a harm that
outlives the certificate.

**Service to service inside your own estate.** A private certificate authority is
usually the right answer rather than either extreme. You issue the certificates,
you distribute your own root to your own machines, and you get name validation
between services without asking a public authority to certify a hostname that
does not resolve on the internet.

**One machine, one client, one operator.** A self-signed certificate is
defensible if the operator verifies the fingerprint out of band once and pins it.
That is the same trust model as an SSH host key, and it is a real model rather
than a fallback. It stops being defensible the moment there are two operators,
because the verification step is what nobody does twice.

<details class="deeper">
<summary>If you run internal services: the trap in a private CA, and the cost nobody budgets</summary>

Running a private authority moves the problem rather than removing it, and the
part that gets underestimated is distribution.

Every machine, container image, language runtime and appliance that has to trust
your root needs a copy of it, in whatever format it expects. Java has its own
store. Node has its own bundle. Python may use the system store or a bundled one
depending on how it was installed. A container built from a base image gets the
base image's store and none of yours. Each of those is a place your certificate
works everywhere except one, and the error will name TLS rather than naming the
store.

The second cost is the root's own lifetime. A private root with a ten-year
validity is a ten-year commitment to holding a key safely, and a rotation event
at the end of it that touches every machine you ever distributed it to. The
authorities that do this professionally keep their roots offline, in hardware,
with a ceremony. Most private authorities keep theirs in a file on the machine
that issues certificates, which means compromising that one machine yields the
ability to impersonate every service in the estate.

That is not an argument against a private authority. It is an argument for
treating the root key as the most valuable thing you hold, which is the subject
of the next topic.

</details>

## Wildcard against a list of names

A wildcard certificate carries a name like `*.example.com` and is valid for every
single-label host under it. A subject alternative name list carries the specific
names you asked for.

The wildcard is convenient and the convenience is exactly the risk. One
certificate covering every host in a domain means one private key that, if taken,
impersonates every host in that domain. It also means the key has to be present
on every machine serving any of those names, so the number of places it lives
grows with the estate.

A SAN list is more work: each name is a decision, and adding one means a new
certificate. What it buys is that the compromise of one service's key is the
compromise of one service.

**The rule worth carrying is that a wildcard is a convenience for the operator
and a concentration for the attacker**, and the question to ask is how many
machines will end up holding that key. Two is a reasonable answer. Forty is a
decision somebody should have to defend.

One detail that catches people: a wildcard matches one label. `*.example.com`
covers `www.example.com` and does not cover `a.b.example.com`, and it does not
cover `example.com` itself unless that name is also listed.

<details class="deeper">
<summary>If you are choosing between them: the third option, and where each one actually fails</summary>

The option people forget is a short-lived certificate with a narrow SAN list,
issued automatically. That is what ACME made ordinary, and it changes the
calculation: the operational cost of a specific name was the reason to buy a
wildcard, and automation removes most of it.

Where each choice fails is worth naming. A wildcard fails when the key spreads,
and it spreads because the certificate is convenient, so the failure mode is
built into the reason for choosing it. A SAN list fails when somebody adds a
hostname and forgets the certificate, which is a change-management failure and
produces an outage rather than a compromise. Automatic issuance fails when the
renewal breaks silently and the expiry arrives at three in the morning, which is
why the monitoring for it watches the remaining validity rather than the last
renewal.

Between an outage and a compromise, prefer the outage. That is most of the case
for the narrow list.

</details>

## Every certificate ever issued for your name

The weakest part of the whole model is that any authority can issue for any name.
The check on that is not prevention, it is publication.

Certificate transparency requires publicly trusted certificates to be logged in
public, append-only logs, and browsers refuse certificates that are not. The logs
are queryable, which means you can ask what has been issued for a name you own.

```bash
# AlmaLinux 10.2, x86_64
$ curl -sS "https://crt.sh/?q=rlwilliamson.dev&output=json" | jq -r ".[] | [.issuer_name, .not_before, .not_after, .serial_number] | @tsv" | sort -u | head -8
C=US, O=DigiCert Inc, OU=www.digicert.com, CN=GeoTrust TLS RSA CA G1	2026-05-14T00:00:00	2026-11-14T23:59:59	0ac0e9b2c67b297ea0311845f3bb95ef
```

One certificate, issued by DigiCert, valid from May to November 2026, serial
`0ac0e9b2c67b297ea0311845f3bb95ef`. **Compare that serial with the one the server
presented at the top of this page.** They match, which is what it looks like when
nothing is wrong.

What you are watching for is a second row nobody asked for: a certificate for
your domain, from an authority you do not use, issued on a date you cannot
account for. That is a misissuance or a compromise, it is visible within hours,
and it is visible to you rather than only to the attacker's victims.

<details class="deeper">
<summary>If you own domains: what to do with this beyond looking, and the record that stops it earlier</summary>

Monitoring is the useful form. Several services will watch the logs for names you
own and mail you on a new issuance, and the useful signal is not the arrival of a
certificate but the arrival of one from an authority that is not yours.

The control that acts rather than watches is a CAA record in DNS. It names the
authorities permitted to issue for your domain, and an authority is required to
check it and refuse if it is not listed. It is one DNS record, it costs nothing,
and it converts an entire class of misissuance from something you detect
afterwards into something that does not happen.

Neither is a substitute for the other. CAA depends on the authority honouring it,
which a compromised or careless authority may not, and transparency depends on
somebody reading the logs. Together they cover each other's failure.

</details>

## Across platforms

The same three questions on each platform: what does this machine trust, what
does a real certificate look like, and what is a root.

| Task | Linux | Windows | macOS |
| --- | --- | --- | --- |
| Count the trusted roots | `grep -c "BEGIN CERTIFICATE" /etc/pki/tls/certs/ca-bundle.crt` | `(Get-ChildItem Cert:\LocalMachine\Root).Count` | `security find-certificate -a -p /System/Library/Keychains/SystemRootCertificates.keychain \| grep -c "BEGIN CERTIFICATE"` |
| Read a server's certificate | `openssl s_client -connect host:443 \| openssl x509 -noout -subject -issuer -dates` | `[Net.Sockets.TcpClient]` plus `SslStream`, then `X509Certificate2` | `/usr/bin/openssl s_client`, same form as Linux |
| List the extensions | `openssl x509 -noout -ext subjectAltName` | `$cert.Extensions` | not supported by the openssl Apple ships |
| Where the roots live | a bundle file, read by the library | a store the operating system owns | a keychain the operating system owns |

```powershell
# Microsoft Windows Server 2025 Datacenter, version 10.0.26100.0
> (Get-ChildItem Cert:\LocalMachine\Root).Count
564

# Four of them, to show what a root actually is and where they come from
> Get-ChildItem Cert:\LocalMachine\Root | Sort-Object Subject | Select-Object -First 4 -ExpandProperty Subject
C=CZ, OID.2.5.4.97=NTRCZ-26439395, O="První certifikační autorita, a.s.", CN=I.CA Root CA/ECC 05/2022
C=CZ, OID.2.5.4.97=NTRCZ-26439395, O="První certifikační autorita, a.s.", CN=I.CA Root CA/RSA 05/2022
C=CZ, OID.2.5.4.97=NTRCZ-26439395, O="První certifikační autorita, a.s.", CN=I.CA TLS Root CA/RSA 05/2022
C=DE, O=Atos, CN=Atos TrustedRoot 2011

# A root is self-issued, which is the whole definition. Subject and issuer match.
> (Get-ChildItem Cert:\LocalMachine\Root | Where-Object { $_.Subject -eq $_.Issuer }).Count
564

# The certificate a real server presents, read the way Windows reads it
> $t = [Net.Sockets.TcpClient]::new('rlwilliamson.dev', 443); $s = [Net.Security.SslStream]::new($t.GetStream()); $s.AuthenticateAsClient('rlwilliamson.dev'); $c = [Security.Cryptography.X509Certificates.X509Certificate2]::new($s.RemoteCertificate); $c | Format-List Subject, Issuer, NotBefore, NotAfter, SerialNumber
Subject      : CN=rlwilliamson.dev
Issuer       : CN=GeoTrust TLS RSA CA G1, OU=www.digicert.com, O=DigiCert Inc, C=US
NotBefore    : 5/14/2026 12:00:00 AM
NotAfter     : 11/14/2026 11:59:59 PM
SerialNumber : 0AC0E9B2C67B297EA0311845F3BB95EF
```

Two things in that block are worth more than the commands. **Windows trusts 564
roots against Linux's 146**, on machines doing comparable work. And **all 564 are
self-issued**, which is the definition of a root stated as a measurement: a root
is a certificate that vouches for itself, and the only reason to believe it is
that it is in the store.

```bash
# macOS 26.5.2, arm64
$ which -a openssl
/opt/homebrew/bin/openssl
/usr/bin/openssl

# The one Apple ships, which is a fork rather than a version
$ /usr/bin/openssl version
LibreSSL 3.3.6

# How many roots the system keychain holds, without anybody choosing them
$ security find-certificate -a -p /System/Library/Keychains/SystemRootCertificates.keychain | grep -c "BEGIN CERTIFICATE"
158

# The certificate a real server presents, read with the tool Apple ships
$ /usr/bin/openssl s_client -connect rlwilliamson.dev:443 -servername rlwilliamson.dev </dev/null 2>/dev/null | /usr/bin/openssl x509 -noout -subject -issuer -dates -serial
subject= /CN=rlwilliamson.dev
issuer= /C=US/O=DigiCert Inc/OU=www.digicert.com/CN=GeoTrust TLS RSA CA G1
notBefore=May 14 00:00:00 2026 GMT
notAfter=Nov 14 23:59:59 2026 GMT
serial=0AC0E9B2C67B297EA0311845F3BB95EF

# The extension flag the Linux column uses, on the tool Apple ships
$ /usr/bin/openssl s_client -connect rlwilliamson.dev:443 -servername rlwilliamson.dev </dev/null 2>/dev/null | /usr/bin/openssl x509 -noout -ext subjectAltName 2>&1 | head -3
unknown option -ext
usage: x509 [-C] [-addreject arg] [-addtrust arg] [-alias] [-CA file]
    [-CAcreateserial] [-CAform der | pem] [-CAkey file]
```

**The first two lines are the trap.** There are two programs called `openssl` on
that machine. The shell will run the Homebrew one, which is OpenSSL 3.6.3. The
one Apple ships is `/usr/bin/openssl`, and it is not OpenSSL at all: it is
LibreSSL 3.3.6, a fork taken in 2014 that has diverged since.

The consequence is in the last command. The exact instruction the Linux column
gives, `openssl x509 -noout -ext subjectAltName`, returns **`unknown option
-ext`** on the tool Apple ships. And look at the line above it: LibreSSL prints
`subject= /CN=rlwilliamson.dev` with a leading slash and slash separators, where
OpenSSL 3 prints `subject=CN=rlwilliamson.dev`. Any script that parses that output
gets a different answer on a Mac.

So a reader on macOS following a Linux instruction is running one of two
different programs, depending on a PATH they have probably never looked at, and
the failure when it goes wrong does not mention LibreSSL.

## Prove it

**Run it.** Read your own machine's trust store and count it, with the command
for your platform from the table above. Then pick one authority in it and look up
where that organisation is based. The exercise is not the number, it is the
moment of noticing that you have a trust relationship with an organisation in a
country you have no other connection to, and that you did not agree to it.

**Run it.** Fetch the certificate for a site you use and read the four fields:
subject, issuer, notBefore, notAfter. Then work out how many days of validity are
left, and ask whether anybody would notice if it were fewer.

**Look it up.** RFC 5280 section 4.2.1.6 defines the subject alternative name
extension, and RFC 6125 section 6.4.4 says what a client does about the common
name. Read the second one and answer this: when a certificate has both a common
name and a subject alternative name, which does a conforming client use, and what
does it do with the other?

## What trips people up

### 1. Reading the common name and ignoring the SAN

The subject is the field a person reads and the subject alternative name is the
field the software checks. A certificate can name your host in the subject and
fail, because the SAN does not list it. The error usually says the certificate is
not valid for the name, which sounds like the certificate is wrong rather than
like you are reading the wrong field.

### 2. Thinking the padlock says the site is legitimate

It says the name matches and the connection is encrypted. A domain-validated
certificate is issued to whoever can change a DNS record for that name, which a
criminal registering a lookalike domain can do in minutes. The padlock on a
phishing site is real and means exactly what it means everywhere else.

### 3. Sending an incomplete chain

The server has to send the intermediate. It works in your browser because
browsers cache intermediates and sometimes fetch them, and it fails in `curl`, in
Java and in your monitoring. The person reporting the fault cannot reproduce it
and the person who can fix it cannot see it.

### 4. Expecting the CSR to set the validity period

You ask, the authority decides. The request contains no dates, no issuer and no
serial, and a certificate that comes back with a shorter validity than you wanted
is the authority's policy rather than a mistake.

### 5. Reaching for a wildcard because it is easier

It is easier, and the ease is the risk. One key, valid for everything under the
domain, copied to every machine that serves any of it. Count the machines that
will hold it before you buy it.

### 6. Running the Linux command on a Mac and believing the result

`openssl` on a Mac may be LibreSSL and may be a Homebrew OpenSSL, and the two
print different formats and support different flags. `unknown option -ext` is
what that looks like when it fails loudly. The dangerous case is when it succeeds
and prints something slightly different.

## Work it through

A payment service inside your own network needs TLS. It has one hostname,
`payments.example.internal`, which does not resolve on the public internet. Four
engineers will operate it. Somebody has already suggested using the company's
wildcard certificate for `*.example.com`, which is on the load balancer.

Take the options in order and say what each one costs.

**The wildcard is out, and the reason is not the name.** The host is not under
`example.com` at all, so the certificate would not validate for it, but suppose
it were. Using it means copying the private key for every public-facing service
in the company onto an internal payment server so that four engineers can test
it. The convenience is one certificate; the cost is that a compromise of the
payment service becomes a compromise of the public estate.

**A public certificate is out because the name cannot be validated.** A publicly
trusted authority validates control of the name through DNS or HTTP, and
`example.internal` resolves nowhere on the internet, so there is nothing to
validate against. This is not a policy obstacle to argue around; it is what
domain validation means.

**A self-signed certificate is defensible and does not survive the fourth
engineer.** Its trust model is that somebody checks the fingerprint out of band
and pins it. One operator can do that. Four operators, plus a monitoring system,
plus a container that talks to it in a pipeline, means the verification step gets
skipped by whoever is in a hurry, and the first person to click through the
warning has removed the entire control.

**A private authority is the answer, and the cost is distribution.** You issue
the certificate, and every client that talks to the service needs your root. The
work is not the issuing, it is finding all the stores: the operating system's,
the Java one, the language runtime's, the base image the container was built
from. That is the real bill, it is payable once per client type rather than once
per certificate, and it buys name validation that keeps working when the fourth
engineer arrives.

The decision, written the way it should be written down: private CA, because the
name cannot be publicly validated and the operator count defeats fingerprint
pinning. The rejected option is self-signed, and the cost of rejecting it is
maintaining a root key and distributing it to four client types.

## Try it

**Count your own trust store, then look at one entry.** One command from the table
above. Then pick the authority with the least familiar name and find out who owns
it now, because several have changed hands.

**Read the certificate of a site you use every day.** Fetch it, print the subject,
issuer and dates, and check the subject alternative name. If it is a large site,
count how many names are in that field. Some carry over a hundred, which tells you
something about how that infrastructure is arranged.

**Query certificate transparency for a domain you own.** Any domain, including a
personal one. Look at what has been issued for it and by whom, and check whether
every row is one you can account for. This is the one exercise here that has
found real problems for real people.

## Check yourself

<details class="qa">
<summary>A certificate has the correct hostname in its subject and the browser still rejects it as not valid for that name. What is the most likely cause?</summary>

The name is missing from the subject alternative name extension. Conforming
clients match on the SAN and do not fall back to the common name in the subject,
so a certificate can name the host in the field a person reads and fail the check
the software performs.

That is why the request in this topic sets the SAN explicitly rather than relying
on the subject. A request that names the host only in the subject produces either
a rejection or a certificate whose SAN the authority derived, which may not be
what was wanted.

</details>

<details class="qa">
<summary>Why does a server not send the root certificate along with the rest of the chain?</summary>

Because it would do no good. A client that already has the root in its trust
store does not need a copy, and a client that does not have it cannot be
persuaded to trust it by being sent one, since anybody could send any root.

The chain on the wire runs from the leaf up to something the client already
believes and stops there. Sending the root anyway is harmless to correctness and
wastes bandwidth on every handshake.

</details>

<details class="qa">
<summary>Your machine trusts 146 root certificates. What can any one of those organisations do?</summary>

Issue a certificate for any name in the world, which your machine will accept as
valid. Trust in this model is not scoped by name: an authority is trusted for
everything or for nothing.

That is the weakness certificate transparency exists to expose and CAA records
exist to constrain. Transparency makes a misissuance visible in public logs
within hours; a CAA record names the authorities permitted to issue for your
domain and requires the others to refuse.

</details>

<details class="qa">
<summary>A signing request contains a name and a public key. Name three things it does not contain, and say who decides them.</summary>

The validity dates, the issuer and the serial number. The authority sets all
three.

That is the difference between an authority and a printing service. You are
asking for a certificate, not specifying one, and the authority's policy decides
how long the assertion is good for and how it is identified for revocation.

</details>

<details class="qa">
<summary>An internal service has one hostname that does not resolve publicly, and four people operate it. Why is a self-signed certificate the wrong answer here, and what makes it the right answer somewhere else?</summary>

Because its trust model depends on somebody verifying the fingerprint out of band
and pinning it, and that step is what gets skipped once more than one person is
involved. The first operator to click through a warning has removed the control
entirely.

It is the right answer when there is exactly one client and one operator who
verifies the fingerprint once, which is the same trust model as an SSH host key.
For four operators plus monitoring, a private authority is the answer, and its
cost is distributing the root to every client type rather than to every service.

</details>

## References

- [RFC 5280](https://www.rfc-editor.org/rfc/rfc5280.html) - IETF, the X.509 certificate profile, including the subject alternative name, basic constraints and key usage extensions. Accessed 2026-08-21.
- [RFC 6125](https://www.rfc-editor.org/rfc/rfc6125.html) - IETF, how a client matches a name against a certificate, and what it does with the common name. Accessed 2026-08-21.
- [CA/Browser Forum Baseline Requirements](https://cabforum.org/working-groups/server/baseline-requirements/documents/) - CA/Browser Forum, the rules publicly trusted authorities issue under, including the permitted domain validation methods and the status of the common name. Accessed 2026-08-21.
- [RFC 6962](https://www.rfc-editor.org/rfc/rfc6962.html) - IETF, certificate transparency and the public logs. Accessed 2026-08-21.
- [openssl-x509](https://docs.openssl.org/master/man1/openssl-x509/) - OpenSSL Project, the command used for every Linux block on this page. Accessed 2026-08-21.
- [About Certificate Stores](https://learn.microsoft.com/en-us/windows-hardware/drivers/install/certificate-stores) - Microsoft, how Windows organises the stores the PowerShell block reads. Accessed 2026-08-21.

**Where the output came from.** Every block on this page is captured. The Linux
blocks were run in AlmaLinux 10.2 on x86_64, pinned by digest, against
`rlwilliamson.dev`, which this site owns. The Windows block was captured on
Windows Server 2025, runner image 20260818.207.1, and the macOS block on macOS
26.5.2 arm64, runner image 20260728.0273.1. The certificate transparency query is
a live lookup and its answer is true as of the date on this page rather than
permanently. The root counts are what those three machines held on 21 August
2026 and will drift as authorities are added and removed.

**If you also work on Linux.** The Linux+ track's
[TLS certificates and ACME](/learn/linux-plus/tls-certificates-and-acme) topic
covers the handshake and automated issuance on a real machine, and
[cryptography basics](/learn/linux-plus/cryptography-basics) covers the
signature underneath all of this. The Network+ treatment of
[encryption, certificates and PKI](/learn/network-plus/encryption-certificates-and-pki)
covers what the padlock proves from a network's point of view.
