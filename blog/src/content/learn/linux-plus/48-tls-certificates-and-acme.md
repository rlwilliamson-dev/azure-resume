---
title: "The certificate is installed and the browser still says not secure"
description: "A certificate is a public key with a name attached and somebody else's signature over both. Building a two-party PKI from nothing, watching verification fail and then succeed, and why a certificate that renews itself beats one a person remembers."
track: "linux-plus"
level: "deep"
order: 490
objectives:
  - "Name the parts of an X.509 certificate and say what each one is for"
  - "Explain how a client walks a chain from a leaf certificate to a trusted root"
  - "Diagnose a verification failure from the error the tooling prints"
  - "Create a signing request, have it signed, and inspect the result"
  - "Say why an automatically renewed short certificate is safer than a long one"
prerequisites: ["cryptography-basics", "name-resolution-and-dns"]
tags: ["linux", "linux-plus", "tls", "pki", "openssl", "certificates", "security"]
updated: 2026-08-08
draft: false
examObjectives:
  - exam: "xk0-006"
    domain: "3.0"
    objective: "3.5"
sources:
  - title: "RFC 8446: The Transport Layer Security (TLS) Protocol Version 1.3"
    url: "https://www.rfc-editor.org/rfc/rfc8446.html"
    publisher: "IETF"
    accessed: 2026-08-08
    tier: 1
  - title: "RFC 8996: Deprecating TLS 1.0 and TLS 1.1"
    url: "https://www.rfc-editor.org/rfc/rfc8996.html"
    publisher: "IETF"
    accessed: 2026-08-08
    tier: 1
  - title: "RFC 5280: Internet X.509 Public Key Infrastructure Certificate and Certificate Revocation List (CRL) Profile"
    url: "https://www.rfc-editor.org/rfc/rfc5280.html"
    publisher: "IETF"
    accessed: 2026-08-08
    tier: 1
  - title: "RFC 6125: Representation and Verification of Domain-Based Application Service Identity within Internet Public Key Infrastructure Using X.509 (PKIX) Certificates in the Context of Transport Layer Security (TLS)"
    url: "https://www.rfc-editor.org/rfc/rfc6125.html"
    publisher: "IETF"
    accessed: 2026-08-08
    tier: 1
  - title: "RFC 8555: Automatic Certificate Management Environment (ACME)"
    url: "https://www.rfc-editor.org/rfc/rfc8555.html"
    publisher: "IETF"
    accessed: 2026-08-08
    tier: 1
  - title: "openssl-x509(1)"
    url: "https://docs.openssl.org/master/man1/openssl-x509/"
    publisher: "OpenSSL"
    accessed: 2026-08-08
    tier: 1
  - title: "openssl-verify(1)"
    url: "https://docs.openssl.org/master/man1/openssl-verify/"
    publisher: "OpenSSL"
    accessed: 2026-08-08
    tier: 1
  - title: "update-ca-certificates(8)"
    url: "https://manpages.debian.org/trixie/ca-certificates/update-ca-certificates.8.en.html"
    publisher: "Debian manpages"
    accessed: 2026-08-08
    tier: 1
symptoms:
  - symptom: "unable to get local issuer certificate"
    anchor: "the-two-verifications"
  - symptom: "unable to verify the first certificate"
    anchor: "a-handshake-watched"
  - symptom: "NET::ERR_CERT_COMMON_NAME_INVALID"
    anchor: "the-name-that-gets-checked"
  - symptom: "certificate has expired"
    anchor: "what-is-actually-inside-a-certificate"
---

> **Before you read.** A web server is running and it has a certificate. The file is
> where the configuration says it is, `openssl x509` reads it without complaint, and
> the dates are comfortably in the future.
>
> `curl https://the-site/` fetches the page and says nothing. A browser on the next
> desk puts a full-screen warning in front of it and calls the site not secure.
>
> **They are looking at the same certificate. Why do they disagree?**

Because a certificate on its own proves nothing at all. Anybody can generate one in
four seconds, put any name in it they like, and serve it. What makes a certificate
mean something is that a party the client *already* trusts has signed it, and the
client can follow that signature back to a key it holds a copy of.

That following-back is called building a chain, and nearly every TLS problem you will
ever be handed is the chain failing to build. The two programs above disagree because
they were given different material to build it from.

This lesson builds a complete two-party public key infrastructure from nothing on a
real machine, then breaks the verification and fixes it, so the chain stops being an
abstraction.

### Some words you will need

<dl class="terms">
<dt>TLS</dt>
<dd>Transport Layer Security. The protocol that encrypts and authenticates a connection. SSL is its dead predecessor, and the name survives in filenames and job adverts.</dd>
<dt>certificate</dt>
<dd>A public key, a name, a validity period, and a signature over all of it by somebody else. Public by design; there is no secret in it.</dd>
<dt>X.509</dt>
<dd>The format certificates are written in. Version 3 is the one in use, and the "3" is what allows extensions. PEM is its base64 text encoding, with the <code>-----BEGIN CERTIFICATE-----</code> lines; DER is the same content as raw binary.</dd>
<dt>CA</dt>
<dd>Certificate authority. Whoever holds a signing key that other people trust. A public one, or one you run.</dd>
<dt>leaf</dt>
<dd>The certificate belonging to the actual server. Also called the end-entity certificate.</dd>
<dt>chain</dt>
<dd>The sequence of certificates from the leaf upward to something already trusted.</dd>
<dt>trust store</dt>
<dd>The set of root certificates a client accepts without being asked. Ships with the operating system, and you can add to it.</dd>
<dt>CSR</dt>
<dd>Certificate signing request. A name plus a public key plus a signature by the matching private key, handed to a CA.</dd>
<dt>SAN</dt>
<dd>Subject Alternative Name. The extension listing the hostnames a certificate is valid for. This is the field that gets checked.</dd>
<dt>ACME</dt>
<dd>Automatic Certificate Management Environment. The protocol that lets a machine prove it controls a name and collect a certificate with no human involved.</dd>
</dl>

## What breaks without this

**The site goes down at a time nobody chose.** A certificate expires at a precise
instant recorded in the certificate itself, and the outage starts then whether or not
anybody is awake. This is the most common TLS failure and it is entirely preventable.

**It works for you and not for a customer**, because your machine happens to have a
certificate cached from an earlier connection and theirs does not. That is the missing
intermediate, and it is the second most common failure.

**You reach for a self-signed certificate** to make a warning go away, and now everyone
who uses the service has been trained to click through security warnings.

**You cannot read the error.** `unable to get local issuer certificate` and
`unable to verify the first certificate` are different faults with different fixes,
and telling them apart takes about ten seconds once you know.

## The chain of trust

<figure class="learn-figure">
<svg viewBox="0 0 720 330" role="img" aria-labelledby="tls-title tls-desc" style="width:100%;height:auto;">
  <title id="tls-title">A certificate chain from a root CA to the certificate a server presents</title>
  <desc id="tls-desc">A root certificate authority certificate is self-signed: its subject and its issuer are the same name, and a copy of it sits in the operating system's trust store. The root signs an intermediate certificate, whose issuer field names the root. The intermediate signs the leaf certificate belonging to a server, whose issuer field names the intermediate. When a client connects, the server sends the leaf and the intermediate but not the root. The client walks the issuer names upward until it reaches a certificate it already trusts. If it never reaches one, verification fails with the error about being unable to get the local issuer certificate.</desc>
  <g font-family="ui-monospace, monospace">
    <rect x="30" y="30" width="230" height="80" rx="5" fill="currentColor" fill-opacity="0.14" stroke="currentColor" stroke-opacity="0.45"/>
    <text x="145" y="52" text-anchor="middle" font-size="12" fill="currentColor">root CA</text>
    <text x="145" y="70" text-anchor="middle" font-size="9.5" fill="currentColor" fill-opacity="0.7">subject: Demo Root CA</text>
    <text x="145" y="85" text-anchor="middle" font-size="9.5" fill="currentColor" fill-opacity="0.7">issuer:  Demo Root CA</text>
    <text x="145" y="102" text-anchor="middle" font-size="9.5" fill="currentColor" fill-opacity="0.85">self-signed</text>
    <rect x="30" y="140" width="230" height="66" rx="5" fill="currentColor" fill-opacity="0.08" stroke="currentColor" stroke-opacity="0.3"/>
    <text x="145" y="162" text-anchor="middle" font-size="12" fill="currentColor">intermediate CA</text>
    <text x="145" y="180" text-anchor="middle" font-size="9.5" fill="currentColor" fill-opacity="0.7">subject: Demo Issuing CA</text>
    <text x="145" y="195" text-anchor="middle" font-size="9.5" fill="currentColor" fill-opacity="0.7">issuer:  Demo Root CA</text>
    <rect x="30" y="236" width="230" height="66" rx="5" fill="currentColor" fill-opacity="0.08" stroke="currentColor" stroke-opacity="0.3"/>
    <text x="145" y="258" text-anchor="middle" font-size="12" fill="currentColor">leaf, the server's own</text>
    <text x="145" y="276" text-anchor="middle" font-size="9.5" fill="currentColor" fill-opacity="0.7">subject: www.example.com</text>
    <text x="145" y="291" text-anchor="middle" font-size="9.5" fill="currentColor" fill-opacity="0.7">issuer:  Demo Issuing CA</text>
    <rect x="430" y="30" width="250" height="80" rx="5" fill="none" stroke="currentColor" stroke-opacity="0.4" stroke-dasharray="4 3"/>
    <text x="555" y="52" text-anchor="middle" font-size="12" fill="currentColor">the client's trust store</text>
    <text x="555" y="70" text-anchor="middle" font-size="9.5" fill="currentColor" fill-opacity="0.65">/etc/ssl/certs</text>
    <text x="555" y="86" text-anchor="middle" font-size="9.5" fill="currentColor" fill-opacity="0.65">roots shipped by the distribution,</text>
    <text x="555" y="100" text-anchor="middle" font-size="9.5" fill="currentColor" fill-opacity="0.65">plus whatever you added</text>
    <text x="430" y="180" font-size="10" fill="currentColor" fill-opacity="0.75">sent by the server</text>
    <text x="430" y="196" font-size="9.5" fill="currentColor" fill-opacity="0.6">during the handshake</text>
    <text x="430" y="266" font-size="10" fill="currentColor" fill-opacity="0.75">sent by the server</text>
    <text x="430" y="282" font-size="9.5" fill="currentColor" fill-opacity="0.6">during the handshake</text>
  </g>
  <g stroke="currentColor" stroke-opacity="0.45" fill="none" stroke-width="1.2">
    <path d="M145 110 L145 136 M141 130 L145 137 L149 130"/>
    <path d="M145 206 L145 232 M141 226 L145 233 L149 226"/>
    <path d="M260 70 L426 70 M420 66 L427 70 L420 74"/>
    <path d="M262 168 L420 168 M414 164 L421 168 L414 172"/>
    <path d="M262 254 L420 254 M414 250 L421 254 L414 258"/>
  </g>
  <g font-family="ui-monospace, monospace" font-size="9.5" fill="currentColor" fill-opacity="0.7">
    <text x="152" y="128">signs</text>
    <text x="152" y="224">signs</text>
    <text x="276" y="60">a copy lives here already</text>
  </g>
</svg>
<figcaption>The client walks issuer names upward until it hits something already in the store. Miss the intermediate and the walk stops one step short.</figcaption>
</figure>

Three facts from that picture carry most of the topic.

**The root is self-signed, and that is not a criticism.** Its subject and its issuer are
the same name because there is nobody above it to sign it. A root is trusted because a
copy of it was installed in your trust store by your operating system vendor, not
because of anything the certificate itself says. Trust starts by assertion; there is no
way for it not to.

The server sends the leaf and any intermediates, and does not send the root.
Sending it would be pointless: the client either has it already, in which case
the copy is redundant, or does not, in which case a copy arriving from the
server it is trying to authenticate proves nothing. This is the single fact
behind "works in curl, fails in a browser", one of them had the intermediate
lying around from a previous connection and one of them did not.

The walk is by name. Each certificate's `issuer` field names the subject of
the certificate above it, and the verifier follows that name upward, checking
a signature at every step, until it reaches something in its store. Reach one
and the chain is valid. Run out of certificates first and you get an error
about not being able to find the issuer.

## Which versions of TLS are still alive

Two are current and everything before them is retired.

| Version | Published | Status now |
| --- | --- | --- |
| SSL 2.0 | 1995 | Prohibited. Broken beyond patching. |
| SSL 3.0 | 1996 | Prohibited. POODLE killed it in 2014. |
| TLS 1.0 | 1999 | **Deprecated by RFC 8996.** Removed from browsers in 2020. |
| TLS 1.1 | 2006 | **Deprecated by RFC 8996.** Same removal. |
| TLS 1.2 | 2008 | Current. Fine, with a sensible cipher list. |
| TLS 1.3 | 2018 | Current and preferred. |

**"Deprecated" here means the IETF published a document saying stop**, RFC 8996 in
2021, and the browser vendors had already acted. A server still offering TLS 1.0 is
not serving old clients successfully; it is failing a compliance scan and offering an
attacker a downgrade target.

**TLS 1.3 is a smaller protocol on purpose.** It removed static RSA key exchange, so
every session has forward secrecy and a stolen server key cannot decrypt yesterday's
traffic. It removed CBC ciphers, compression, and renegotiation, all of which had
produced named attacks, and cut the handshake to one round trip. It also changed how
cipher suites are named: a TLS 1.2 suite spells out key exchange, authentication,
cipher, and MAC, where a TLS 1.3 suite names only the AEAD cipher and the hash,
because the rest is no longer negotiable. You will see all of that in the handshake
later in this lesson, including the line `This TLS version forbids renegotiation.`

## Building a certificate authority from nothing

The fastest way to stop finding certificates mysterious is to be the CA for ten
minutes. One command produces a key and a self-signed certificate together.

<details class="predict">
<summary>The command below supplies one name with <code>-subj</code> and no CA to sign against, because there is not one yet. Given that a certificate has both a subject field and an issuer field, what will the issuer say?</summary>

```bash
# Debian 13 (trixie), x86_64
$ cd /root/pki; openssl req -x509 -newkey rsa:4096 -sha256 -days 3650 -nodes -keyout ca.key -out ca.crt -subj "/C=GB/O=Demo Ltd/CN=Demo Root CA" 2>/dev/null; ls -l ca.key ca.crt; openssl x509 -in ca.crt -noout -subject -issuer -dates
-rw-r--r--. 1 root root 1903 Aug  8 18:07 ca.crt
-rw-------. 1 root root 3272 Aug  8 18:07 ca.key
subject=C=GB, O=Demo Ltd, CN=Demo Root CA
issuer=C=GB, O=Demo Ltd, CN=Demo Root CA
```

</details>

**`subject=` and `issuer=` are the same string, and that is the definition of
self-signed.** Not a policy, not a warning flag somebody set. The two fields
hold identical bytes because the key that signed the certificate is the key
inside the certificate. Every root CA on earth looks exactly like this,
including the ones your browser trusts implicitly.

| Flag | Does |
| --- | --- |
| `-x509` | Emit a certificate rather than a request. This is what makes it self-signed. |
| `-newkey rsa:4096` | Generate a fresh 4096-bit key at the same time |
| `-days 3650` | Ten years, which is normal for a root and absurd for a leaf |
| `-nodes` | Leave the private key unencrypted on disk. Spelled `-noenc` in current OpenSSL. |
| `-subj` | Supply the name non-interactively instead of answering seven prompts |

Look at the two file modes. `ca.crt` is `-rw-r--r--` and `ca.key` is
`-rw-------`, and OpenSSL chose those. The certificate is public (that is the
entire point of it) and the key is the thing whose disclosure ends the CA.

This is also the moment to separate two ideas that get conflated. A
*self-signed certificate*, served directly by a web server, is one no client
has any reason to accept, and the fix people reach for is telling users to
click through the warning. A *private CA whose root you install into the trust
store* is a legitimate design used by every large organisation for internal
services: the leaf certificates are not self-signed, they chain to a root, and
that root is trusted because you deliberately put it there. Same commands,
completely different security posture. The distinction is whether trust was
established once, centrally, or dismissed repeatedly by each user.

## What is actually inside a certificate

The certificate is a text file in base64 and it decodes to a structure. `-text` prints
it:

```bash
# Debian 13 (trixie), x86_64
$ cd /root/pki; openssl x509 -in ca.crt -noout -text | head -13
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number:
            18:84:23:09:85:be:dd:cc:be:ed:1e:e1:fb:07:dc:fa:9f:d6:b4:45
        Signature Algorithm: sha256WithRSAEncryption
        Issuer: C=GB, O=Demo Ltd, CN=Demo Root CA
        Validity
            Not Before: Aug  8 18:13:02 2026 GMT
            Not After : Aug  5 18:13:02 2036 GMT
        Subject: C=GB, O=Demo Ltd, CN=Demo Root CA
        Subject Public Key Info:
            Public Key Algorithm: rsaEncryption
```

Seven things, and each one answers a question a verifier is about to ask.

| Field | Here | What it decides |
| --- | --- | --- |
| `Version: 3` | v3 | Whether extensions are allowed at all. v1 has no SAN, no key usage, nothing. |
| `Serial Number` | 20 random bytes | The CA's unique reference for this certificate. It is what a revocation list names. |
| `Signature Algorithm` | `sha256WithRSAEncryption` | Which hash and which signature scheme. SHA-1 here would be rejected outright. |
| `Issuer` | Demo Root CA | Whose signature to look for, and therefore which certificate to fetch next |
| `Validity` | 2026 to 2036 | The two instants outside which this is not a certificate |
| `Subject` | Demo Root CA | Who this certificate is about |
| `Public Key Info` | `rsaEncryption` | The key being certified, and the algorithm it belongs to |

**The private key is not in there and never is.** A certificate is the public
half plus a name plus somebody's signature over both. You can email one to
anybody, publish it, put it in a git repository, and every client that
connects receives a full copy of the server's certificate as the first step of
the handshake.

**`Version: 3 (0x2)` looks like a typo and is not.** The version field is
zero-indexed, so version 3 is encoded as 2. Version 3 is what added
extensions, and extensions are where the name checking, the CA flag, and the
key usage restrictions live, everything that makes a modern certificate more
than a signed name. The `head` cuts the output at thirteen lines, so they are
below the fold; you meet them shortly.

<details class="deeper">
<summary>If you already administer Linux: expiry is the most common TLS outage and <code>-checkend</code> is the whole fix</summary>

Every certificate carries the timestamp of its own failure. Nothing else in
infrastructure is quite so obliging, and organisations still take outages from it
several times a year. `openssl x509` has an option for exactly this that returns an exit
code, so it is a complete monitoring check in one line:

```
openssl x509 -in /etc/ssl/certs/site.crt -noout -checkend 604800

echo | openssl s_client -connect www.example.com:443 -servername www.example.com 2>/dev/null \
  | openssl x509 -noout -dates -checkend 604800
```

**604800 is seven days in seconds.** It exits 0 if the certificate is still valid that
far ahead and 1 if it is not, printing `Certificate will expire`. The second form asks
the server rather than trusting a file on disk to be the one actually in use.

**That distinction is the one that catches people.** The file you are
monitoring and the certificate the service is serving are only the same thing
if the service was reloaded after the last renewal. A renewal that wrote a new
file and never triggered a reload leaves the old certificate in the process's
memory until it expires, and file-based monitoring reports everything is fine
right up to the outage. Monitor the port, and monitor the whole estate rather
than the certificate somebody asked about: the one that takes you down is the
one nobody remembered existed, an internal API, a message broker, an LDAP
server from lesson 38.

</details>

## From a request to a certificate

A CA does not generate your key. You generate it, keep it, and send the CA a request
containing the public half and the name you want. That request is a CSR.

```bash
# Debian 13 (trixie), x86_64
$ cd /root/pki; openssl req -in www.csr -noout -subject -verify; echo "--- sign it with the CA ---"; openssl x509 -req -in www.csr -CA ca.crt -CAkey ca.key -CAcreateserial -days 365 -sha256 -extfile ext.cnf -out www.crt
Certificate request self-signature verify OK
subject=C=GB, O=Demo Ltd, CN=www.example.com
--- sign it with the CA ---
Certificate request self-signature ok
subject=C=GB, O=Demo Ltd, CN=www.example.com
```

**`Certificate request self-signature verify OK` is proof of possession**, and it is
worth being precise about what it proves. A CSR contains a public key and is signed
using the matching private key. Anyone can verify that signature using the public key
that is right there inside the request. If it verifies, whoever built the request held
the private key at the time they built it.

That is the only thing a CSR is for. Without it a CA could be talked into signing
somebody else's public key under your name, and the certificate would attest to a
pairing nobody could actually use. The private key never leaves your machine, never
reaches the CA, and appears nowhere in this transcript. The second
`Certificate request self-signature ok` comes from the signing command, which checks the
same signature again before it will sign anything.

**`-extfile ext.cnf` is not optional and this is the trap.** `openssl x509
-req` reads the subject and the public key out of the request and **ignores
the extensions**. Ask for a SAN in your CSR, sign it this way without an
extensions file, and the certificate comes out with no SAN at all, which, as
the next two sections show, means it is not valid for any hostname in any
current browser. Current OpenSSL grew `-copy_extensions copy` for the other
approach, and it is off by default deliberately, because copying extensions
from a request means letting the requester choose them.

`-CAcreateserial` starts a serial-number file next to the CA if there is not one
already, and `-days 365` is the leaf's lifetime, short where the root's was ten years.

## The two verifications

The certificate exists. Now the part that decides everything.

<details class="predict">
<summary>The certificate below was signed by a CA that exists only in this directory and is in no trust store anywhere. What does <code>openssl verify -CAfile ca.crt www.crt</code> print, and what does <code>openssl verify www.crt</code> print?</summary>

```bash
# Debian 13 (trixie), x86_64
$ cd /root/pki; openssl x509 -in www.crt -noout -subject -issuer -dates -ext subjectAltName; echo "--- verify against the CA ---"; openssl verify -CAfile ca.crt www.crt; echo "--- and without it ---"; openssl verify www.crt
subject=C=GB, O=Demo Ltd, CN=www.example.com
issuer=C=GB, O=Demo Ltd, CN=Demo Root CA
notBefore=Aug  8 18:26:20 2026 GMT
notAfter=Aug  8 18:26:20 2027 GMT
X509v3 Subject Alternative Name: 
    DNS:www.example.com, DNS:example.com
--- verify against the CA ---
www.crt: OK
--- and without it ---
C=GB, O=Demo Ltd, CN=www.example.com
error 20 at 0 depth lookup: unable to get local issuer certificate
error www.crt: verification failed
```

**Read the first two lines before the verifications.** `subject=` says
`CN=www.example.com` and `issuer=` says `CN=Demo Root CA`. They differ, and that
difference is the whole distinction between this certificate and the root: this one was
signed by somebody else. The dates are one year rather than ten. And the SAN extension
made it in, listing both names.

</details>

**Nothing about the certificate changed between those two commands.** Same file, same
bytes, same signature, run a fraction of a second apart. One says `OK` and one fails with
`unable to get local issuer certificate`.

The only difference is what the verifier was permitted to trust. `-CAfile ca.crt` said
"treat this file as a trust anchor", and the walk then took one step from
`issuer=Demo Root CA` to a certificate with that subject, checked the signature, and
finished. Without it, the verifier consulted the system trust store, found no
`Demo Root CA` in it, ran out of chain, and stopped.

**Trust is a property of the verifier, not of the certificate.** That sentence is the one
to keep. There is no field inside a certificate that makes it trusted, no flag to set,
nothing to fix in the file. When a client rejects a certificate that another client
accepts, the certificate is not the variable.

**`error 20 at 0 depth` names where the walk stopped.** Depth 0 is the leaf itself, so
the failure happened at the first step: the verifier could not find the issuer of the
certificate it was handed. Depth 1 would be the intermediate, depth 2 its issuer. The
depth in an error tells you how far up the chain the client got before it lost the trail,
which narrows a chain problem to one certificate immediately.

One honest caveat: **`openssl verify` checks the chain and does not check the hostname.**
It was asked about signatures and validity, not identity;
`-verify_hostname www.example.com` asks the other question.

## The name that gets checked

The certificate above carries the hostname twice: once in the subject as
`CN=www.example.com`, and once in the `X509v3 Subject Alternative Name` extension as
`DNS:www.example.com, DNS:example.com`. Only one of those is consulted.

**The Common Name is dead for hostname matching.** It was the original
mechanism, it was deprecated in 2000, RFC 6125 formalised the replacement, and
browsers finished the job years ago, Chrome removed the fallback outright and
the rest followed. A certificate with a perfectly correct CN and no SAN is
rejected by every current browser with a message along the lines of
`ERR_CERT_COMMON_NAME_INVALID`, which is a slightly cruel error string given
the CN is the one thing that *is* correct.

**The SAN is what is checked, and it is a list.** One certificate can carry many names,
which is how one covers `example.com` and `www.example.com`, or a whole family of
internal services. Wildcards go in there too, as `DNS:*.example.com`, and they match
exactly one label: `a.example.com` matches, `a.b.example.com` does not.

The extension file that produced the SAN above is four lines:

```
subjectAltName = DNS:www.example.com, DNS:example.com
basicConstraints = CA:FALSE
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
```

**`basicConstraints = CA:FALSE` is the other extension worth knowing by name.** It says
this certificate may not sign other certificates. Without that constraint, any leaf
could act as a CA and mint certificates for any name in the world, which is a real
historical vulnerability rather than a theoretical one. A root says `CA:TRUE`, usually
with a `pathlen` limiting how many intermediates may sit below it.
`extendedKeyUsage = serverAuth` says this one authenticates a server; a client
certificate says `clientAuth`, and one presented in the wrong role is rejected even
though it verifies perfectly.

## Where trust actually lives

The trust store is a directory, and on Debian it is populous:

```bash
# Debian 13 (trixie), x86_64
$ ls /etc/ssl/certs | wc -l; echo "--- a few of them ---"; ls /etc/ssl/certs | head -4; echo "--- the bundle everything actually reads ---"; ls -l /etc/ssl/certs/ca-certificates.crt
301
--- a few of them ---
002c0b4f.0
0179095f.0
02265526.0
062cdee6.0
--- the bundle everything actually reads ---
-rw-r--r--. 1 root root 224449 Aug  8 21:47 /etc/ssl/certs/ca-certificates.crt
```

**Those hexadecimal names are not random and not filenames anybody chose.** Each is the
hash of a certificate's subject name, followed by `.0` to disambiguate collisions, and
they are symbolic links. That naming is a lookup index: given
`issuer=C=GB, O=Demo Ltd, CN=Demo Root CA`, a verifier hashes that name, opens the file
with the matching name, and has the issuer's certificate without reading 300 files. It
is what `-CApath` uses, and `openssl rehash` generates it after you drop a certificate
into such a directory.

**`ca-certificates.crt` is the other form**: every trusted root concatenated into one PEM
file, 224 kilobytes of it. That is what `-CAfile` takes, and what most libraries read at
start-up. Two representations of one set, and which a program wants depends on the
program.

The roots come from a package, `ca-certificates`, tracking the set Mozilla
curates. **So `apt upgrade` is part of your TLS security posture**, because a
CA that has been distrusted is only distrusted on your machine once that
package updates.

<details class="deeper">
<summary>If you already administer Linux: two commands, two directories, and the several trust stores that ignore both</summary>

Adding an internal root is a two-step operation everywhere, and the two families put the
files in different places with differently named commands.

| | RHEL family | Debian family |
| --- | --- | --- |
| Drop the root here | `/etc/pki/ca-trust/source/anchors/` | `/usr/local/share/ca-certificates/` |
| Then run | `update-ca-trust` | `update-ca-certificates` |
| Which writes | `/etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem` | `/etc/ssl/certs/ca-certificates.crt` |
| Compatibility path | `/etc/pki/tls/certs/ca-bundle.crt` | `/etc/ssl/certs/` hashed links |

**Two details bite.** On Debian the file must end in `.crt` or
`update-ca-certificates` will skip it silently, and it must be PEM regardless
of the extension. On both, the generated bundle is generated, editing
`ca-certificates.crt` by hand works until the next package update overwrites
it, which is the same durability problem as `chcon` versus `restorecon` in
lesson 44.

**And then there are the stores that neither command touches**, which is where the report
"I added the root and it still fails" comes from:

- **Java** keeps its own `cacerts` keystore inside the JDK, managed with `keytool`. Recent
  packaging links it to the system store; older packaging and slim container bases do not.
- **Firefox and Thunderbird** use NSS with a per-profile `cert9.db`, added to by
  enterprise policy or `certutil`.
- **Node.js** compiles in its own root list; `NODE_EXTRA_CA_CERTS=/path/to/root.crt` is
  the supported way in, set in the service's environment rather than your shell.
- **Python** uses whatever `certifi` bundled, so a virtual environment can disagree with
  the machine it is running on.
- **Containers** carry their own `/etc/ssl/certs` from the image, and the host's store is
  irrelevant unless you mount it in.

The diagnostic that separates these in one command is to test with `openssl s_client`
first. If OpenSSL verifies and the application does not, the application has its own store
and no amount of work on the system one will help.

</details>

## A handshake, watched

Everything so far was files on disk. Here is the same certificate being presented over
a real connection to a local `openssl s_server`.

```bash
# Debian 13 (trixie), x86_64
$ cd /root/pki; openssl s_client -connect localhost:4433 -CAfile ca.crt -servername www.example.com </dev/null 2>/dev/null | sed -n "1,12p;/New,/,/Verify return/p"
CONNECTED(00000003)
---
Certificate chain
 0 s:C=GB, O=Demo Ltd, CN=www.example.com
   i:C=GB, O=Demo Ltd, CN=Demo Root CA
   a:PKEY: RSA, 2048 (bit); sigalg: sha256WithRSAEncryption
   v:NotBefore: Aug  8 18:30:44 2026 GMT; NotAfter: Aug  8 18:30:44 2027 GMT
---
Server certificate
-----BEGIN CERTIFICATE-----
MIIEmTCCAoGgAwIBAgIUWhwMCOx/feEuDDlYs7/nqRTJSoMwDQYJKoZIhvcNAQEL
BQAwNzELMAkGA1UEBhMCR0IxETAPBgNVBAoMCERlbW8gTHRkMRUwEwYDVQQDDAxE
New, TLSv1.3, Cipher is TLS_AES_256_GCM_SHA384
Protocol: TLSv1.3
Server public key is 2048 bit
This TLS version forbids renegotiation.
Compression: NONE
Expansion: NONE
No ALPN negotiated
Early data was not sent
Verify return code: 0 (ok)
```

The `sed` in that command is why the PEM block stops mid-certificate: the transcript is
trimmed rather than three screens of base64.

**`Certificate chain` is the list the server sent.** One entry, numbered 0, which is the
leaf. `s:` is its subject and `i:` is its issuer, and here the issuer is the root
directly, because this PKI has two parties and no intermediate. On a public site you
would see entry 0 with entry 1 above it, and the root would still be absent.

`Verify return code: 0 (ok)` is the answer to the whole question, and it is at
the bottom because it is the last thing decided. Every other line is evidence.
`TLS_AES_256_GCM_SHA384` names two things rather than four, which is TLS 1.3's
naming: the AEAD cipher and the hash. Key exchange is always ephemeral
Diffie-Hellman and authentication is whatever the certificate holds, so
neither appears.

`-servername www.example.com` sets SNI, the field telling the server which
certificate to present when one address hosts many sites. Leave it out against
a virtual-hosted server and you get whichever certificate is configured as the
default, which is a common way to spend twenty minutes debugging the wrong
one.

<details class="predict">
<summary>The same server, the same certificate, and the same command with <code>-CAfile ca.crt</code> removed. The Demo Root CA is not in the system trust store. What does the verify line say now?</summary>

```bash
# Debian 13 (trixie), x86_64
$ openssl s_client -connect localhost:4433 -servername www.example.com </dev/null 2>/dev/null | grep -E "^(depth|verify|Verify)"
Verify return code: 21 (unable to verify the first certificate)
```

</details>

Note that it still connected. `s_client` reports the failure and completes the
handshake anyway, because it is a diagnostic tool. A browser or a library
would refuse. That is why `-verify_return_error` exists: it makes `s_client`
behave like a real client and exit non-zero, which is what you want in a
script.

<details class="deeper">
<summary>If you already administer Linux: error 18, 19, 20 and 21 are four different faults with four different fixes</summary>

The number in `Verify return code` and in `openssl verify` output is an
`X509_V_ERR_` code, and four of them cover almost everything you will meet. Telling
them apart is the fastest diagnosis in TLS.

| Code | Text | What actually happened | Fix |
| --- | --- | --- | --- |
| 18 | self signed certificate | The leaf signed itself. There is no chain. | Get a real certificate, or trust this one deliberately |
| 19 | self signed certificate in certificate chain | The chain reaches a self-signed root the client does not have | Install that root in the client's trust store |
| 20 | unable to get local issuer certificate | The issuer named by some certificate cannot be found anywhere | Supply the CA, or install the missing intermediate on the **server** |
| 21 | unable to verify the first certificate | The server sent the leaf alone and nothing above it | Add the intermediate to the server's chain file |

**19 and 20 are the pair people confuse**, and the distinction is where the
missing piece lives. Code 19 means the chain built all the way to a root and
the client does not trust that root, an internal CA whose certificate was
never distributed. Code 20 means the walk stopped part-way, so a certificate
in the middle is missing. One is a client problem, one is a server problem,
and swapping them wastes an afternoon.

**Code 21 is the "works in curl, fails in a browser" report almost every time.** The
server is sending only its own certificate. Some clients have the intermediate cached
from an earlier connection to an unrelated site and succeed; a fresh client does not.
The reproduction is a machine that has never made that connection before.

Look at what is actually being sent, which needs the full list rather than the summary,
then count the `BEGIN CERTIFICATE` blocks. One is the bug; two or three is normal, and
the root should not be among them.

```
openssl s_client -connect www.example.com:443 -servername www.example.com -showcerts </dev/null
cat leaf.crt intermediate.crt > /etc/ssl/certs/site-chain.crt
```

**Fixing it is file order, and the order is not arbitrary**: leaf first, then
each issuer in turn, upward. Nginx takes the whole thing in `ssl_certificate`;
Apache takes it in `SSLCertificateFile`. Get the order backwards and some
clients tolerate it and some reject the connection, which makes the failure
intermittent by client, the worst outcome, because it then looks like a
network problem.

And **the service still has the old chain in memory** until it is reloaded.
`systemctl reload nginx` is part of the fix, not a formality.

</details>

## Certificates that renew themselves

Everything above is what a person does by hand. ACME, defined in RFC 8555, is that
whole sequence run by a program: generate a key, build a CSR, prove to the CA that you
control the name, collect the certificate, and repeat before it expires.

**The argument for it is not convenience.** A ninety-day certificate that renews itself
every sixty days is safer than a two-year certificate renewed by a person, and the
reason is that the person leaves. The manual process depends on a calendar entry in
somebody's account, a runbook naming a server that has been rebuilt, and a private key
emailed once and never rotated. The automated process depends on a timer. One of those
degrades quietly over two years and the other does not. The short lifetime does real
work too: a compromised key becomes useless in weeks rather than years, which matters
precisely because revocation barely functions.

Proving control of a name is the interesting part, and there are two challenge
types worth knowing by name.

| | HTTP-01 | DNS-01 |
| --- | --- | --- |
| You publish | A token at `/.well-known/acme-challenge/<token>` | A TXT record at `_acme-challenge.<name>` |
| Requires | Port 80 reachable from the internet | Credentials for the DNS zone |
| Wildcards | **No** | **Yes**, and it is the only way |
| Works for internal hosts | No | Yes, the host is never contacted |
| Main risk | A redirect or a rewrite rule swallowing the path | An API token that can edit your DNS living on a web server |

HTTP-01 is the default and the simplest thing that can work. The CA resolves
the name, connects on port 80, and fetches a file the client wrote. That the
CA reached the right machine *is* the proof. It follows redirects to HTTPS,
which trips people whose web server rewrites everything including the
challenge path.

DNS-01 is what you need for a wildcard, and for anything not reachable from
the public internet, because nothing connects to the host at all. The cost is
that renewal needs credentials capable of writing to your DNS zone, and those
credentials then live on a machine. Scope the token to one zone, or to the
`_acme-challenge` records specifically if your provider supports it.

A third, TLS-ALPN-01, does the same job over port 443 using a dedicated ALPN protocol,
for hosts where port 80 is not available.

The client side, using certbot as the common example:

```
certbot certonly --webroot -w /var/www/html -d www.example.com -d example.com
certbot certonly --dns-route53 -d '*.example.com' -d example.com
certbot renew --deploy-hook 'systemctl reload nginx'
systemctl list-timers certbot.timer
```

**The `--deploy-hook` is the part people leave out**, and it produces the outage
described earlier: the renewal succeeds, the file on disk is new, the running service
still holds the old certificate, and monitoring that reads the file says everything is
fine. The hook runs only when a certificate was actually renewed, which is why it beats
a blanket restart on every timer firing.

Renewal is idempotent and safe to run often, the client checks how much life
is left and does nothing if there is plenty, which is why the packaged timer
runs twice a day. Web servers that speak ACME themselves, such as Caddy or
Apache's `mod_md`, remove the external client entirely.

<details class="deeper">
<summary>If you already administer Linux: revocation mostly does not work, and short lifetimes are the industry's answer</summary>

Every certificate carries a serial number so it can be revoked. In practice revocation
is the weakest part of the whole system, and knowing why explains several design
decisions that otherwise look arbitrary.

**CRLs are lists of revoked serials, published by the CA and downloaded by clients.** A
large CA's list is megabytes, it is stale between publications, and a client that fails
to fetch it has to decide whether to fail open or fail closed. Failing closed means an
unreachable CRL server takes down every site that CA issued for. Everybody failed open,
which means an attacker who can block the fetch has defeated it.

OCSP asks the CA about one certificate at a time, which fixes the size problem
and creates two others: a round trip to a third party on every connection, and
the CA learning which sites each client visits. Same fail-open logic, same
consequence.

OCSP stapling moves the fetch to the server, which collects a signed,
timestamped response every few hours and attaches it to its own handshake.
Latency and privacy both solved. But a client cannot insist on it, the
"must-staple" extension exists and is barely deployed, because a certificate
that fails to load when stapling breaks is a certificate that takes your site
down. So a client that receives no staple carries on, and the attacker
suppresses it.

The result is that a compromised private key stays usable until the
certificate expires, for most clients, most of the time. Browsers partly work
around this by shipping curated lists of high-profile revocations, effective
for the cases somebody notices and useless for yours.

So the industry moved the lever. If revocation cannot be relied on, the
exposure window is the certificate's remaining lifetime, and the fix is to
make that short. That is the real reason maximum lifetimes keep being cut and
the real reason ACME exists. The operational consequence: **treat a key
compromise as requiring a rotation you can perform quickly**, not a revocation
you can rely on. If reissuing every certificate in your estate is a multi-day
manual project, you do not have a working answer to a compromise.

</details>

## Across distributions

The commands are the same. The trust store paths and the policy machinery are not.

| | RHEL family | Debian family |
| --- | --- | --- |
| Trust anchors go in | `/etc/pki/ca-trust/source/anchors/` | `/usr/local/share/ca-certificates/` |
| Rebuild the store with | `update-ca-trust` | `update-ca-certificates` |
| Generated bundle | `/etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem` | `/etc/ssl/certs/ca-certificates.crt` |
| System-wide crypto policy | `update-crypto-policies` | none; per-application configuration |
| Root package | `ca-certificates` | `ca-certificates` |

**`update-crypto-policies` is the RHEL-family feature with no Debian equivalent**, and it
is lesson 47's material applied here: one setting moves every TLS library on the machine
between `LEGACY`, `DEFAULT`, and `FUTURE`, so a service that suddenly refuses to talk to
an old appliance after an upgrade is very often the policy rather than the service.
Debian expects each daemon to be configured on its own.

### OpenSSL and LibreSSL

Two implementations provide the `openssl` command, and the exam names both.

**OpenSSL** is the original and the default nearly everywhere on Linux. Version 3.x is
current; `openssl version` tells you which you have. **LibreSSL** is OpenBSD's fork,
begun in 2014 after Heartbleed, with a deliberately reduced codebase and its own
defaults. It is the system TLS on OpenBSD and is packaged as an option elsewhere.

For everything in this lesson the two are interchangeable: `req`, `x509`,
`verify`, and `s_client` behave the same way and take the same common flags.
They diverge on newer or less common options, `-copy_extensions` and the
`-provider` machinery are OpenSSL-specific, and on the version string, which
is the practical gotcha. A script that parses `openssl version` and expects it
to begin with `OpenSSL` breaks on a machine running LibreSSL, and the fix is
to test for the capability rather than the name.

## Prove it

```
# What is in this file, in the order that matters
openssl x509 -in site.crt -noout -subject -issuer -dates -ext subjectAltName

# Does it chain to something, and to what
openssl verify -CAfile ca.crt site.crt
openssl verify -untrusted intermediate.crt site.crt

# Is it going to expire on you
openssl x509 -in site.crt -noout -checkend 604800

# What is the server actually sending, as opposed to what is on disk
openssl s_client -connect host:443 -servername host -showcerts </dev/null

# Does the key on disk match the certificate on disk
openssl x509 -in site.crt -noout -pubkey | openssl sha256
openssl pkey -in site.key -pubout | openssl sha256
```

**The last pair is the check nobody thinks of until they need it.** A certificate and a
key that do not match produce a service that refuses to start with an unhelpful message.
Extract the public key from each and compare the hashes: identical means they belong
together, different means somebody copied the wrong file.

## What trips people up

### 1. A missing intermediate that curl forgives

The server sends only its leaf. Clients holding the intermediate from an earlier
connection succeed; fresh clients fail with error 21. Because the first group includes
your laptop, the bug looks like it is on the customer's side. Count the certificates
with `s_client -showcerts`, concatenate leaf then intermediate, reload.

### 2. A Common Name with no Subject Alternative Name

Browsers stopped consulting the CN for hostname matching years ago, so a certificate
with a perfect CN and no SAN is invalid for every hostname. The usual cause is signing a
CSR with `openssl x509 -req` and no `-extfile`, which silently discards the request's
extensions.

### 3. Confusing self-signed with a private CA

A self-signed certificate served directly teaches users to click through warnings. A
private CA whose root is installed in the trust store is a legitimate internal design
and produces no warnings at all. The commands overlap; the outcomes do not.

### 4. Letting it expire

The certificate names the exact moment it stops working. `-checkend` against
the port, not against the file, is a one-line monitoring check, and expiry
remains the most common TLS outage there is.

### 5. Renewing and not reloading

The new certificate is on disk and the running process still holds the old one in
memory. Use `--deploy-hook`, and monitor what the port serves rather than the file.

### 6. Adding the root and having it still fail

Java, Firefox, Node, Python, and every container image keep their own trust stores, and
`update-ca-trust` and `update-ca-certificates` do not reach them. Test with
`openssl s_client` first: if OpenSSL is happy and the application is not, the
application has its own store.

## Work it through

A service moved to a new load balancer overnight. Your `curl` from a jump host works.
Two customers report a browser warning. A partner's Java client fails with a chain
error. Nothing about the certificate changed.

Reason it out before reading on.

**First, look at what the server sends rather than what is on disk:**

```
openssl s_client -connect api.example.com:443 -servername api.example.com -showcerts </dev/null | grep -c "BEGIN CERTIFICATE"
```

One certificate is the diagnosis. The load balancer was configured with the
leaf alone and the intermediate was left behind on the old host. Your `curl`
succeeded because that jump host had already spoken to another site under the
same CA and cached the intermediate; the customers' browsers had not.
Re-running the same `s_client` without `-showcerts` and reading `Verify return
code: 21` confirms it: the walk stopped at the leaf, which is a server-side
fault no work on any client will fix.

Fix it where the fault is, and reload:

```
cat leaf.crt intermediate.crt > /etc/ssl/certs/api-chain.crt
systemctl reload nginx
```

Leaf first, then its issuer. Then repeat the `s_client` and expect two certificates and
`Verify return code: 0 (ok)`.

**Now change one detail and watch the answer change.** Suppose the chain had
come back with two certificates and `Verify return code: 19 (self signed
certificate in certificate chain)`. That is not a missing intermediate, the
chain built correctly all the way to a root the client does not trust, so this
is an internal CA and the fix is to distribute its root to clients rather than
to touch the server.

**And one more.** Suppose the chain is complete, OpenSSL verifies, browsers are happy,
and only the partner's Java client fails. Nothing on your side is wrong: Java keeps its
own `cacerts` keystore, and on a slimmed-down image it is not linked to the system
store, so the root reached the machine and not the runtime. Being able to say so with
`s_client` output in hand is the difference between a resolved ticket and a week of
blame.

The point worth extracting: **a TLS failure is a question about which party is missing
which certificate, and the error code answers it.** Depth tells you where the walk
stopped, the code tells you what was missing, and the two together name the machine to
go and fix.

## Try it

Optional, on any machine with `openssl` installed, in a scratch directory. This is the
whole lesson in eight commands.

1. `openssl req -x509 -newkey rsa:4096 -sha256 -days 3650 -noenc -keyout ca.key -out ca.crt -subj "/CN=My Test CA"`
2. `openssl x509 -in ca.crt -noout -subject -issuer`, and confirm the two are identical.
3. `openssl req -newkey rsa:2048 -noenc -keyout www.key -out www.csr -subj "/CN=www.test.local"`
4. `openssl req -in www.csr -noout -verify`, and read what the success line claims.
5. `printf 'subjectAltName = DNS:www.test.local\nbasicConstraints = CA:FALSE\n' > ext.cnf`
6. `openssl x509 -req -in www.csr -CA ca.crt -CAkey ca.key -CAcreateserial -days 365 -sha256 -extfile ext.cnf -out www.crt`
7. `openssl verify www.crt`, then `openssl verify -CAfile ca.crt www.crt`. Two different
   answers about one unchanged file.
8. Sign it again *without* `-extfile`, then run
   `openssl x509 -in www.crt -noout -ext subjectAltName` and see the SAN disappear.

Then, if you have two terminals: `openssl s_server -cert www.crt -key www.key -www` in
one, and `openssl s_client -connect localhost:4433 -CAfile ca.crt </dev/null` in the
other. Remove `-CAfile` and compare the verify line.

**Verification step.** You have it when you can say, without running anything, why
`openssl verify www.crt` and `openssl verify -CAfile ca.crt www.crt` disagree about a
file that did not change.

## Check yourself

<details class="qa">
<summary><code>openssl verify www.crt</code> fails with error 20 and <code>openssl verify -CAfile ca.crt www.crt</code> prints OK, a second apart, on the same file. Did the certificate change?</summary>

**No. The verifier changed.**

`-CAfile ca.crt` told OpenSSL to treat that file as a trust anchor. The verifier read
`issuer=Demo Root CA` off the leaf, found a certificate with that subject in the file it
was handed, checked the signature, reached a trust anchor, and stopped. Without the flag
it consulted the system trust store, which holds a few hundred public roots and no
`Demo Root CA`, ran out of chain at the first step, and reported
`error 20 at 0 depth lookup: unable to get local issuer certificate`.

**Trust is a property of the verifier, not of the certificate.** There is no field inside
a certificate that makes it trusted and nothing to fix in the file. Whenever one client
accepts a certificate another rejects, the certificate is not the variable. The tempting
wrong answer is that the file is invalid or malformed; it verified perfectly a moment
later.

`at 0 depth` is the part to carry forward. Depth 0 is the leaf, depth 1 its
issuer, and so on, so the depth in a verification error tells you how far up
the chain the client got before it lost the trail.

</details>

<details class="qa">
<summary>A site loads under <code>curl</code> on your machine and shows a security warning in a colleague's browser. What is it, and where is the fix?</summary>

Almost certainly a missing intermediate, and the fix is on the server.

The server is sending only its own leaf certificate. Your machine happened to
have the intermediate cached from an earlier connection to some unrelated site
under the same CA, so it completed the chain locally. A client that has never
seen it cannot, and reports `Verify return code: 21 (unable to verify the
first certificate)`. Confirm it by counting what is actually sent, then fix
the chain order, leaf first, each issuer after it:

```
openssl s_client -connect site:443 -servername site -showcerts </dev/null | grep -c "BEGIN CERTIFICATE"
cat leaf.crt intermediate.crt > /etc/ssl/certs/site-chain.crt
systemctl reload nginx
```

One certificate is the bug; two or three is normal. **The root does not go in
that file**. The client either has it already or does not trust it, and a copy
arriving from the server proves nothing.

The tempting wrong answer is that the colleague's trust store is out of date. Error code
19 rather than 21 would point there, but 21 is unambiguous about the failure being at the
leaf, which is the server's responsibility. And do not skip the reload: the running
process holds the old chain until it is told otherwise.

</details>

<details class="qa">
<summary>A certificate has <code>CN=www.example.com</code> and no Subject Alternative Name. It verifies with <code>openssl verify</code>. Will a browser accept it?</summary>

**No. Every current browser rejects it, typically with an error naming the Common Name.**

Hostname matching moved from the Common Name to the `subjectAltName` extension. The CN
fallback was deprecated in 2000, formalised away by RFC 6125, and removed from browsers
years ago. A certificate with no SAN is valid for no hostname at all, however correct its
CN looks.

**That `openssl verify` said OK is not a contradiction.** It answers a different question:
does this chain to a trusted root, and is it inside its validity period. It checks no
names unless you ask, with `-verify_hostname www.example.com`.

The usual cause is the signing step, not the request. `openssl x509 -req`
reads the subject and public key out of a CSR and discards its extensions, so
signing without `-extfile` produces a certificate with no SAN even when the
CSR asked for one.

What you will need next: the SAN is a list, so one certificate covers several
names, and a wildcard matches exactly one label: `*.example.com` covers
`a.example.com` and not `a.b.example.com`.

</details>

<details class="qa">
<summary>Why does a certificate signing request carry a signature, and what does verifying it prove?</summary>

It proves possession of the private key, and that is the only thing it proves.

A CSR contains a subject name and a public key, and it is signed with the
private key matching that public key. Anyone can check that signature using
the public key inside the request itself, which is what `Certificate request
self-signature verify OK` reports. If it verifies, whoever assembled the
request held the corresponding private key, proof of possession. Without it a
CA could be persuaded to bind your name to somebody else's key, and the
certificate would attest to a pairing that does not exist.

**What it does not prove is the name.** Nothing about the CSR establishes any
right to `www.example.com`; a request can claim any name at all. Establishing
the name is the CA's separate job, and it is exactly what an ACME challenge
does, HTTP-01 by fetching a token from that host, DNS-01 by reading a record
in that zone.

The tempting wrong answer is that the signature proves the request came from a trusted
source. It carries no trust of any kind; a self-signature is worth precisely as much as
the key that made it.

**And the thing worth carrying:** the private key never appears in the CSR, never reaches
the CA, and never leaves the machine that generated it. A CA that offers to generate your
key for you is offering to hold a copy of it.

</details>

<details class="qa">
<summary>Why is a 90-day certificate renewed automatically considered safer than a two-year one renewed by a person?</summary>

**Because the exposure window after a key compromise is the certificate's remaining
lifetime, and because manual processes decay.**

Revocation is the mechanism supposed to cut a compromised certificate short,
and it barely works. CRLs are large and stale, OCSP adds a third-party round
trip to every connection, and both fail open. A client that cannot reach the
revocation service carries on rather than blocking. So in practice a stolen
key stays usable until its certificate expires, which makes lifetime the lever
that actually moves. Ninety days of exposure is a manageable incident. Two
years is not.

**The second reason is organisational and it is the one that causes outages.** A manual
renewal depends on a calendar entry in an account, a runbook naming a host that has since
been rebuilt, and a person who may have left. It works twice and fails the third time, at
an hour nobody chose. An ACME client on a timer depends on the timer.

The objection worth answering is that automation adds a moving part which can
itself fail. True, and its failure is visible and testable: `certbot renew
--dry-run` exercises the whole path on demand, and a timer that has not fired
is something monitoring can see. A person who forgot is not.

What you will need next: the renewal is only half the job. Use `--deploy-hook`
to reload the service, because a renewed file with an unreloaded daemon still
serves the old certificate, and monitoring that checks the file rather than
the port reports success right up until the outage.

</details>

## References

- [RFC 8446: The Transport Layer Security (TLS) Protocol Version 1.3](https://www.rfc-editor.org/rfc/rfc8446.html) - IETF. Accessed 2026-08-08.
- [RFC 8996: Deprecating TLS 1.0 and TLS 1.1](https://www.rfc-editor.org/rfc/rfc8996.html) - IETF. Accessed 2026-08-08.
- [RFC 5280: Internet X.509 Public Key Infrastructure Certificate and Certificate Revocation List (CRL) Profile](https://www.rfc-editor.org/rfc/rfc5280.html) - IETF. Accessed 2026-08-08.
- [RFC 6125: Representation and Verification of Domain-Based Application Service Identity](https://www.rfc-editor.org/rfc/rfc6125.html) - IETF. Accessed 2026-08-08.
- [RFC 8555: Automatic Certificate Management Environment (ACME)](https://www.rfc-editor.org/rfc/rfc8555.html) - IETF. Accessed 2026-08-08.
- [openssl-x509(1)](https://docs.openssl.org/master/man1/openssl-x509/) - OpenSSL. Accessed 2026-08-08.
- [openssl-verify(1)](https://docs.openssl.org/master/man1/openssl-verify/) - OpenSSL. Accessed 2026-08-08.
- [update-ca-certificates(8)](https://manpages.debian.org/trixie/ca-certificates/update-ca-certificates.8.en.html) - Debian manpages. Accessed 2026-08-08.

Every captured block came from a Debian 13 container in which a two-party PKI was built
from nothing: a root CA, a key and CSR for `www.example.com`, a certificate signed by
that CA with a SAN extension, and a local `openssl s_server` for the handshake. Each
capture ran the setup fresh, so serial numbers and timestamps differ between blocks even
where the certificate is conceptually the same one. Blocks without a distribution and
architecture header are illustrative; no `certbot` run appears in this topic because
issuing a real certificate requires a name the certificate authority can reach.
