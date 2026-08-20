---
title: "Encryption, certificates and PKI"
description: "The padlock proves less than people think. Symmetric and asymmetric in one page, what a certificate actually binds and who vouches for it, and the chain of trust demonstrated by breaking it."
deck: "The browser padlock proves less than people think"
track: "network-plus"
level: "working"
order: 350
objectives:
  - "Tell symmetric from asymmetric encryption and say what each is used for"
  - "Say what a certificate binds and what a signature on it means"
  - "Walk a chain of trust from a leaf to a root"
  - "Explain what the padlock does and does not prove"
  - "Recognise the missing intermediate fault from its symptoms"
prerequisites: ["security-vocabulary-and-the-cia-triad"]
tags: ["network-plus", "networking", "security", "pki"]
updated: 2026-08-11
draft: false
examObjectives:
  - exam: "n10-009"
    domain: "4.0"
    objective: "4.1"
sources:
  - title: "RFC 5280, Internet X.509 Public Key Infrastructure Certificate and CRL Profile"
    url: "https://www.rfc-editor.org/rfc/rfc5280"
    publisher: "IETF"
    accessed: 2026-08-11
    tier: 1
  - title: "RFC 8446, The Transport Layer Security (TLS) Protocol Version 1.3"
    url: "https://www.rfc-editor.org/rfc/rfc8446"
    publisher: "IETF"
    accessed: 2026-08-11
    tier: 1
  - title: "openssl-verify(1)"
    url: "https://docs.openssl.org/master/man1/openssl-verify/"
    publisher: "OpenSSL"
    accessed: 2026-08-11
    tier: 1
symptoms:
  - symptom: "A site works in a browser and fails from a script or a phone"
    anchor: "the-fault-you-will-actually-meet"
  - symptom: "A certificate is valid and the connection is still refused"
    anchor: "what-the-padlock-proves"
---

> **Before you read.** A site has a valid certificate. The browser shows a
> padlock. A colleague says that means the connection is secure and the company
> is who it says it is.
>
> One of those is true, one is nearly true, and one is not.
>
> **Which is which?**

Certificates get taught as cryptography, which is the least useful framing for
somebody who will spend their career diagnosing them rather than designing them.
The mathematics is not the part that goes wrong. The chain is.

### Some words you will need

<dl class="terms">
<dt>symmetric encryption</dt>
<dd>One key, used to encrypt and to decrypt. Fast, and both ends need the same secret.</dd>
<dt>asymmetric encryption</dt>
<dd>A pair of keys, where what one encrypts only the other can decrypt. Slow, and only one of the pair is secret.</dd>
<dt>certificate</dt>
<dd>A document binding a name to a public key, signed by somebody else.</dd>
<dt>certificate authority</dt>
<dd>The somebody else. An organisation whose signature clients have been told to accept.</dd>
<dt>chain of trust</dt>
<dd>The path from the certificate in front of you to one your machine already trusts.</dd>
<dt>trust store</dt>
<dd>The set of root certificates a machine holds and believes without being told.</dd>
<dt>self-signed</dt>
<dd>A certificate whose issuer is itself. Every root is one, which is why being self-signed is not the problem people think it is.</dd>
</dl>

## What breaks without this

**A site works for you and fails for everyone else.** The commonest certificate
fault in existence is invisible from a desktop browser and obvious from a phone
or a script, and the reason is in the capture below.

**Nobody can say what the padlock claimed.** It makes a narrow claim, and
treating it as a broad one is how phishing works.

**Expiry takes down a service with no warning that anybody read.** A certificate
is a document with a date on it, and the failure at that date is total rather
than gradual.

## Two kinds of encryption, and why both

**Symmetric** encryption uses one key for both directions. It is fast, it is what
actually protects the bytes of a connection, and it has one problem: both ends
need the same secret, and they have to agree it over a network somebody may be
listening to.

**Asymmetric** encryption uses a pair. What one key encrypts, only the other can
decrypt, and one of the pair can be published. It is slow, and it solves exactly
the problem symmetric has.

So real systems use both, and the division of labour is worth stating plainly
because the exam blurs it. **Asymmetric is used at the start, to agree a shared
secret and to prove identity. Symmetric does the work after that.** Nobody
encrypts a video stream asymmetrically.

The identity half is where certificates come in. A public key alone tells you
nothing about whose it is, and that gap is what a certificate exists to close.

<details class="deeper">
<summary>If you already deploy this: what the key exchange protects that the encryption does not</summary>

The division of labour is usually described as fast against slow, and there is a
second property of the exchange worth knowing because it changes what a captured
recording is worth.

Modern key agreement produces a session key that neither side transmits and that is
discarded when the session ends. So somebody who records the traffic today and obtains
the server's private key years later cannot go back and decrypt the recording, because
the private key was used to authenticate the exchange rather than to encrypt it. That
property has a name, forward secrecy, and it is the reason older key exchange methods
were retired rather than merely deprecated.

The practical consequence is that a compromised server key is bad for the future and
not retrospectively catastrophic, provided the exchange was done this way. It also
means that anybody wanting to decrypt traffic in bulk has to be in the path at the
time rather than patient, which changes the shape of the threat considerably.

Worth pairing with the limits. The exchange authenticates the server to the client
using the certificate, and it says nothing about the client unless the client presents
one too, which most do not. And none of it protects the data once it arrives, which
topic 50's panel makes the same point about for tunnels. Encryption in transit is one
property, bought at one moment, and it is routinely assumed to cover things it never
touched.

</details>

## What a certificate actually binds

A certificate says: this name goes with this public key, and here is a signature
from somebody vouching for it.

Three parts, and the third is doing all the work. Anybody can generate a key pair
and write a certificate claiming to be any name. What makes one believable is who
signed it, and whether your machine already trusts that signer.

Which is why the chain matters, and the fastest way to understand a chain is to
build one and then break it.

<details class="predict">
<summary>Three certificates, each signed by the one above. What does verification say when the middle one is not supplied?</summary>

```bash
# Debian 13 (trixie), x86_64
$ cd /pki
$ for c in leaf inter root; do openssl x509 -in $c.crt -noout -subject -issuer; done
subject=O=Demo, CN=shop.example.com
issuer=O=Demo, CN=Demo Issuing CA
subject=O=Demo, CN=Demo Issuing CA
issuer=O=Demo, CN=Demo Root CA
subject=O=Demo, CN=Demo Root CA
issuer=O=Demo, CN=Demo Root CA

# the server sends leaf and intermediate; the client already holds the root
$ openssl verify -CAfile root.crt -untrusted inter.crt leaf.crt
leaf.crt: OK

# the same leaf, with the intermediate left off the server
$ openssl verify -CAfile root.crt leaf.crt
O=Demo, CN=shop.example.com
error 20 at 0 depth lookup: unable to get local issuer certificate
error leaf.crt: verification failed
```

</details>

Read the first block as three sentences. The leaf is `shop.example.com` and its
issuer is the Issuing CA. The Issuing CA's issuer is the Root CA. The Root CA's
issuer is the Root CA, which is what self-signed means and is true of every root
in every trust store on earth.

<figure class="learn-figure">
<svg viewBox="0 0 720 320" role="img" aria-labelledby="chain-title" style="width:100%;height:auto;">
<title id="chain-title">A certificate chain where each certificate is signed by the one above it, next to the same chain with the intermediate missing so the client cannot reach the root it trusts</title>
<g fill="currentColor">
<text x="14" y="20" font-size="11">what the client has to be able to walk, and what happens when a link is absent</text>
<text x="14" y="48" font-size="11">chain complete</text>
<rect x="14" y="58" width="250" height="48" rx="3" fill="var(--accent)" fill-opacity="0.2" stroke="var(--accent)" stroke-width="1.8"/>
<text x="26" y="78" font-size="10.5" fill="var(--accent)">Demo Root CA</text>
<text x="26" y="94" font-size="10" fill="var(--accent)" fill-opacity="0.8">signed by itself</text>
<rect x="14" y="140" width="250" height="48" rx="3" fill="currentColor" fill-opacity="0.08" stroke="currentColor" stroke-width="1" stroke-opacity="0.55"/>
<text x="26" y="160" font-size="10.5" fill="currentColor">Demo Issuing CA</text>
<text x="26" y="176" font-size="10" fill="currentColor" fill-opacity="0.8">signed by Demo Root CA</text>
<rect x="14" y="222" width="250" height="48" rx="3" fill="currentColor" fill-opacity="0.08" stroke="currentColor" stroke-width="1" stroke-opacity="0.55"/>
<text x="26" y="242" font-size="10.5" fill="currentColor">shop.example.com</text>
<text x="26" y="258" font-size="10" fill="currentColor" fill-opacity="0.8">signed by Demo Issuing CA</text>
<g stroke="currentColor" stroke-opacity="0.6" stroke-width="1.6" fill="none">
<path d="M 139 222 V 190"/><path d="M 134 197 l 5 -8 l 5 8"/>
<path d="M 139 140 V 108"/><path d="M 134 115 l 5 -8 l 5 8"/>
</g>
<text x="276" y="86" font-size="10" fill="var(--accent)">in the trust store</text>
<text x="276" y="170" font-size="10" fill-opacity="0.7">sent by the server</text>
<text x="276" y="252" font-size="10" fill-opacity="0.7">sent by the server</text>
<text x="14" y="296" font-size="10.5" fill="var(--accent)">verify: OK</text>
<text x="396" y="48" font-size="11">intermediate not sent</text>
<rect x="396" y="58" width="250" height="48" rx="3" fill="var(--accent)" fill-opacity="0.2" stroke="var(--accent)" stroke-width="1.8"/>
<text x="408" y="78" font-size="10.5" fill="var(--accent)">Demo Root CA</text>
<text x="408" y="94" font-size="10" fill="var(--accent)" fill-opacity="0.8">signed by itself</text>
<rect x="396" y="140" width="250" height="48" rx="3" fill="var(--red)" fill-opacity="0.08" stroke="var(--red)" stroke-width="1" stroke-dasharray="5 4"/>
<text x="408" y="160" font-size="10.5" fill="var(--red)">nothing here</text>
<text x="408" y="176" font-size="10" fill="var(--red)" fill-opacity="0.8">signed by nobody</text>
<rect x="396" y="222" width="250" height="48" rx="3" fill="currentColor" fill-opacity="0.08" stroke="currentColor" stroke-width="1" stroke-opacity="0.55"/>
<text x="408" y="242" font-size="10.5" fill="currentColor">shop.example.com</text>
<text x="408" y="258" font-size="10" fill="currentColor" fill-opacity="0.8">signed by Demo Issuing CA</text>
<g stroke="var(--red)" stroke-width="1.6" fill="none">
<path d="M 521 222 V 190" stroke-dasharray="5 4"/>
</g>
<text x="680" y="200" text-anchor="end" font-size="10" fill="var(--red)">the gap</text>
<text x="396" y="296" font-size="10.5" fill="var(--red)">verify: unable to get local issuer certificate</text>
<text x="14" y="316" font-size="10.5" fill-opacity="0.85">the leaf is identical in both. only what the server chose to send alongside it differs.</text>
</g></svg>
<figcaption>The same leaf certificate in both columns, byte for byte. What differs is only what the server chose to send alongside it. On the left the client receives the intermediate, so it can follow the issuer field from the leaf up to a certificate it already holds, and verification succeeds. On the right the intermediate was not sent, the client has never seen it, and the trail stops one step short of the root it would have accepted. Nothing is expired, nothing is revoked, and nothing about the leaf is wrong.</figcaption>
</figure>

<details class="deeper">
<summary>If you already run an internal authority: why trust is a property of the client, not the certificate</summary>

The chain is only worth what the client's trust store says it is, and that store is
the part of the system people forget they own.

An internal authority is a perfectly good design and it works because every managed
device has been told to trust it. Devices outside that management do not, which is why
an internal certificate produces a warning on a contractor's laptop, a personal phone,
or anything else nobody enrolled. That is the system behaving correctly, and the usual
response, telling people to click through the warning, trains them to accept any
warning anywhere.

The same store is what makes a private authority dangerous if it is careless. A trusted
authority can sign a certificate for any name at all, including names it has no
business signing, so an internal authority whose key is loosely held is a way to
impersonate anything to every managed device in the organisation. Public authorities
are audited and constrained for exactly this reason, and an internal one usually is
not.

Two habits follow. Keep the internal authority's key offline and issue from an
intermediate, so a compromise of the issuing system is recoverable without replacing
the trust anchor on every device. And know which devices trust it, because that list is
the true scope of what the authority can affect, and it is almost always larger than
the list of devices the certificates were issued for.

</details>

## The fault you will actually meet

**Verification failed, and the certificate is fine.** That is the second command,
and it is the most common certificate fault in production by a distance.

The reason it survives testing is worth understanding, because it is why it
reaches production at all. **Desktop browsers hide it.** Having seen the
intermediate once, from any site, a browser caches it and will happily use the
cached copy next time. Some will even go and fetch a missing intermediate
themselves. So the engineer who installed the certificate opens the site, sees a
padlock, and closes the ticket.

Then the failures arrive from everywhere else. A phone that has never visited the
site. A script using a library that does no caching and no fetching. A payment
provider's callback. Each of those does the strict thing, which is to follow only
what the server sent, and each of them stops at the gap.

**So the signature of this fault is that it works for you and fails for
somebody else**, and the fix is on the server: send the intermediate alongside the
leaf. It is a configuration line rather than a new certificate.

<details class="deeper">
<summary>If you already work on networks: why roots are self-signed, and what a trust store actually is</summary>

Self-signed gets used as an insult, and every root certificate on your machine is
self-signed. Both of those are true and the apparent contradiction is worth
resolving, because it explains what trust means here.

A signature is only worth something if you already trust the signer. Follow any
chain upward and eventually you reach a certificate with nobody above it, and that
one has to be signed by itself, because there is no one else. So the top of every
chain is self-signed by necessity rather than by laziness.

What makes a root trustworthy is not its signature, which proves nothing. It is
that a copy of it is already on your machine, put there by whoever shipped your
operating system or browser, and that they applied some process before including
it. **Trust in this system is not cryptographic at the top. It is a list.**

Two consequences follow, and both come up in real work.

Adding your own root to a trust store is a completely normal operation, and it is
how internal certificate authorities work. A certificate signed by your company's
own root is exactly as valid as a public one on any machine that holds that root,
and worthless on any machine that does not. That is not a lesser kind of
certificate, it is the same mechanism with a smaller audience.

And anybody who can add a root to a machine can issue certificates that machine
will believe for any name. That is how the inspecting proxy in topic 54 works, and
it is why installing a root certificate is a much larger decision than it looks
when a dialog asks.

</details>

## What the padlock proves

Now the question at the top of this page, taken claim by claim.

**The connection is encrypted.** True. That is exactly what it means, and it is a
statement about the transport rather than about anybody.

**The certificate is valid for the name in the address bar.** Nearly true, and
worth stating precisely: a chain was followed to a root the browser trusts, the
certificate is inside its validity dates, and the name matches. That is a real
claim and it is narrower than it sounds.

**The company is who it says it is.** Not proved. The certificate says whoever
controls this name also controls this key, and most certificates are issued on
exactly that basis: the applicant demonstrated control of the domain, and nothing
else was checked. A convincing-looking name that somebody registered this morning
gets a padlock in minutes, and it will be a genuine one.

That gap is the whole of why phishing sites have padlocks, and telling somebody to
look for one is advice that stopped being useful some years ago.

## Prove it

The capture above is the proof for the chain. Two documents for the rest.

**RFC 5280.** The certificate profile, and the document that defines what the
fields mean. Read the section describing the issuer and subject fields and answer
one question: is the issuer field a pointer to a certificate, or a name that has
to be matched against one? The answer explains why a missing intermediate breaks
the chain rather than being looked up.

**RFC 8446.** TLS 1.3. Read the introduction and answer a narrower question: does
the protocol require the server to send the whole chain including the root? The
answer is why sending the root is harmless and pointless, and why sending the
intermediate is neither.

**Then break one yourself.** The commands in the capture are the whole exercise
and take five minutes: build a root, build an intermediate, sign a leaf, verify
with and without. Doing it once makes the error message readable for the rest of
your career.

## What trips people up

### 1. Reading a padlock as an identity claim

It says the connection is encrypted and the name matches a certificate that chains
to a trusted root. Most certificates are issued on proof of domain control alone,
so it says nothing about who the organisation is.

### 2. Treating self-signed as inherently wrong

Every root is self-signed. What matters is whether the machine already holds the
certificate at the top of the chain, not whether that certificate signed itself.

### 3. Testing a new certificate only in a desktop browser

Browsers cache intermediates they have seen elsewhere and some fetch missing ones.
That hides the commonest fault in existence. Test with something strict.

### 4. Fixing a missing intermediate by reissuing the certificate

The certificate is fine. The server is not sending the whole chain, which is a
configuration change rather than a new document.

### 5. Thinking asymmetric encryption protects the traffic

It is used to agree a shared secret and to prove identity. Symmetric encryption
carries the bytes, because asymmetric is far too slow for that job.

### 6. Sending the root along with the chain

Harmless and pointless. A client that trusts the root already has it, and a client
that does not will not start trusting it because the server offered a copy.

## Work it through

A certificate is installed on a new service. It works in a browser. Within a day
there are reports from a mobile app and from a partner's automated integration,
both saying the certificate is untrusted.

Start by noticing what the reports have in common, because it is the diagnosis.
The things that work are browsers on machines that browse the wider internet. The
things that fail are a mobile app and a script, both of which follow only what the
server sends. That pattern is a chain problem rather than a certificate problem,
before anybody has looked at anything.

Then confirm it rather than assume it, with the strict tool rather than the
forgiving one. Verification against the root alone, with no intermediate supplied,
is what the failing clients are doing, and the error names the problem: unable to
get local issuer certificate.

Then read the fault properly. The leaf is valid, in date, and correctly named. The
issuing authority is a real one. Nothing needs reissuing, and asking the
certificate authority for a new certificate will produce an identical failure,
which is a wasted day that happens frequently.

The fix is on the server. Configure it to present the intermediate alongside the
leaf, which most software calls a chain file or a full chain, and restart.

And the check afterwards has to be done with something that does not cache. A
browser on a machine that has already met that intermediate will say it was fine
before you changed anything, which is exactly how it got shipped.

## Try it

**Build the chain from the capture.** Five commands, and the error message becomes
readable permanently.

**Look at your own trust store.** Every machine has one. Counting how many
organisations are in it is a sobering ten seconds, because every one of them can
issue a certificate your machine will believe for any name.

**Check a certificate you rely on with a strict client.** Not the browser you
installed it from.

## Check yourself

<details class="qa">
<summary>Why do real systems use both symmetric and asymmetric encryption?</summary>

Because each solves what the other cannot.

Symmetric is fast enough to carry actual traffic, and it needs both ends to hold
the same secret, which is a problem when the only way to share it is over a
network somebody may be watching.

Asymmetric is slow, and one key of the pair can be published, which makes it able
to agree a secret in the open and to prove identity.

So asymmetric is used at the start to establish a shared key and prove who is
there, and symmetric carries everything after that.

</details>

<details class="qa">
<summary>Verification fails with "unable to get local issuer certificate" and the certificate is in date and correctly named. What is wrong?</summary>

The server is not sending the intermediate.

The client has the root and the leaf, and the leaf's issuer field names a
certificate it has never seen. It cannot look that up, so the chain stops one step
short of a certificate it would have accepted.

Nothing is wrong with the leaf, so reissuing it changes nothing. The fix is to
configure the server to present the intermediate alongside it.

</details>

<details class="qa">
<summary>Why does that fault work in a desktop browser and fail on a phone?</summary>

Because browsers are forgiving in a way that hides it. Having seen the
intermediate once from any other site, a browser caches it and reuses it, and some
will fetch a missing one on demand.

A client that has never met that intermediate, and that follows only what the
server sent, stops at the gap. Which is why testing a new certificate in the
browser you installed it from proves almost nothing.

</details>

<details class="qa">
<summary>Every root certificate is self-signed. So what makes one trustworthy?</summary>

Not its signature, which proves nothing, since it signed itself.

What makes it trustworthy is that a copy is already on your machine, placed there
by whoever shipped the operating system or browser after applying some process
before including it. At the top of the chain, trust is a list rather than a
calculation.

Which is why adding your own root to a machine is a normal operation for an
internal certificate authority, and also why anybody who can add a root can issue
certificates that machine will believe for any name.

</details>

<details class="qa">
<summary>A phishing site has a padlock. Does that mean the certificate is fraudulent?</summary>

Usually not. It is generally a genuine certificate, correctly issued.

Most certificates are issued on proof of control of the domain and nothing else.
Somebody who registers a convincing name this morning controls it, so they can
obtain a real certificate for it in minutes.

The padlock says the connection is encrypted and the name in the bar matches a
certificate chaining to a trusted root. It never claimed the organisation is who
you assume, which is why looking for a padlock stopped being useful advice.

</details>

## References

- [RFC 5280](https://www.rfc-editor.org/rfc/rfc5280) - IETF, the X.509 certificate profile, which defines the issuer and subject fields the chain is walked with. Free. Accessed 2026-08-11.
- [RFC 8446](https://www.rfc-editor.org/rfc/rfc8446) - IETF, TLS 1.3, on what the server is expected to send. Free. Accessed 2026-08-11.
- [openssl-verify(1)](https://docs.openssl.org/master/man1/openssl-verify/) - OpenSSL, which documents the error the capture produces. Accessed 2026-08-11.

**Where the numbers came from.** The certificates in the capture are built on the
page rather than borrowed, which is deliberate: showing a real site's chain would
date badly and would demonstrate only the working case. Building the chain means
the failure can be shown as well, and the failure is the part worth having. The
claim that browsers cache intermediates and some fetch missing ones is behaviour
rather than a specification, which is why it is described as what browsers do
rather than as something required.

**If you also work on Linux.** [TLS certificates and
ACME](/learn/linux-plus/tls-certificates-and-acme) covers issuing and renewing
these rather than diagnosing them, and the two are worth reading together: that
page builds the authority, this one breaks the chain.
