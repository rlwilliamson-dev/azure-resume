---
title: "Revocation, and the answer that never comes"
description: "Three ways to find out whether a certificate has been withdrawn, what each one costs in bandwidth and privacy, why the answer you get is a week old whichever way you ask, and what a browser does when it gets no answer at all."
deck: "The certificate was revoked this morning. Your browser has not noticed"
track: "security-plus"
level: "working"
order: 110
objectives:
  - "Explain what revocation is for, and why expiry does not cover it"
  - "Compare a revocation list, an online status query and stapling by what each costs"
  - "Say what a client concludes when a revocation check gets no answer, and why"
  - "Explain why shorter certificate lifetimes are the industry's actual answer"
  - "Read the revocation endpoints out of a certificate you are handed"
prerequisites: []
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
  - title: "RFC 6960, X.509 Internet Public Key Infrastructure Online Certificate Status Protocol"
    url: "https://www.rfc-editor.org/rfc/rfc6960.html"
    publisher: "IETF"
    accessed: 2026-08-21
    tier: 1
  - title: "RFC 6961, TLS Multiple Certificate Status Request Extension"
    url: "https://www.rfc-editor.org/rfc/rfc6961.html"
    publisher: "IETF"
    accessed: 2026-08-21
    tier: 1
  - title: "CA/Browser Forum Baseline Requirements for the Issuance and Management of Publicly-Trusted TLS Server Certificates"
    url: "https://cabforum.org/working-groups/server/baseline-requirements/documents/"
    publisher: "CA/Browser Forum"
    accessed: 2026-08-21
    tier: 1
  - title: "ocsp(1) command reference"
    url: "https://docs.openssl.org/master/man1/openssl-ocsp/"
    publisher: "OpenSSL Project"
    accessed: 2026-08-21
    tier: 1
symptoms:
  - symptom: "A certificate was revoked and clients still accept it"
    anchor: "what-happens-when-nothing-answers"
---

> **Before you read.** A server's private key is stolen on a Monday morning. By
> lunchtime the certificate has been revoked, correctly, through the authority's
> proper process.
>
> On Monday afternoon somebody visits the site through the attacker, using the
> stolen key and the revoked certificate, and their browser shows a padlock.
>
> **Everything worked as designed. What is the design?**

A certificate says it is valid until a date. Revocation is how an authority says
otherwise before that date arrives, and it is the weakest part of the whole
arrangement.

### Some words you will need

<dl class="terms">
<dt>revocation</dt>
<dd>Withdrawing a certificate before its expiry date, because the key was compromised or the binding is no longer true.</dd>
<dt>certificate revocation list</dt>
<dd>A file the authority publishes listing every certificate it has withdrawn. Abbreviated CRL, and certificate revocation lists are what the plural in a certificate's own extension refers to.</dd>
<dt>online certificate status protocol</dt>
<dd>A request asking an authority about one certificate, answered with good, revoked or unknown. Abbreviated OCSP.</dd>
<dt>stapling</dt>
<dd>The server fetching its own status answer periodically and including it in the handshake, so the client does not have to ask.</dd>
<dt>soft-fail</dt>
<dd>Treating no answer as permission to continue. What almost every browser does.</dd>
<dt>hard-fail</dt>
<dd>Refusing to connect when the check cannot be completed. Correct, and almost nobody does it.</dd>
</dl>

## What breaks without this

**A stolen key keeps working until the certificate expires.** Which may be
months, and the attacker is using a technically valid certificate the whole time.

**You revoke a certificate and nothing happens.** The process completed, the
authority published, and clients carry on accepting it because nothing made them
look.

**A check that costs the user something they did not agree to.** Every revocation
mechanism has a price, in bandwidth, in latency or in telling a third party which
sites somebody visits.

## What is in the certificate already

The certificate tells you where to ask. Both addresses are extensions inside it,
put there by the authority.

```bash
# AlmaLinux 10.2, x86_64
$ dnf -q -y install openssl >/dev/null 2>&1
openssl s_client -connect rlwilliamson.dev:443 -servername rlwilliamson.dev </dev/null 2>/dev/null | openssl x509 -noout -ext crlDistributionPoints,authorityInfoAccess
X509v3 CRL Distribution Points: 
    Full Name:
      URI:http://cdp.geotrust.com/GeoTrustTLSRSACAG1.crl

Authority Information Access: 
    OCSP - URI:http://status.geotrust.com
    CA Issuers - URI:http://cacerts.geotrust.com/GeoTrustTLSRSACAG1.crt
```

Two URLs, and they are two different mechanisms answering the same question.
`cdp.geotrust.com` serves a list. `status.geotrust.com` answers about one
certificate. The third address is where to fetch the issuer if you are missing it,
which is how a client repairs an incomplete chain.

## The list, and what it costs to use

<details class="predict">
<summary>To check one certificate against a revocation list, how much do you think a client downloads?</summary>

```bash
# AlmaLinux 10.2, x86_64
$ cd /root/rev
echo "the list this certificate authority publishes:"
ls -l ca.crl | tr -s " " | cut -d" " -f5,9
openssl crl -inform DER -in ca.crl -noout -lastupdate -nextupdate -issuer
echo
echo "how many certificates it has withdrawn:"
openssl crl -inform DER -in ca.crl -noout -text | grep -c "Serial Number:"
the list this certificate authority publishes:
340634 ca.crl
lastUpdate=Aug 21 04:00:59 2026 GMT
nextUpdate=Aug 28 04:00:59 2026 GMT
issuer=C=US, O=DigiCert Inc, OU=www.digicert.com, CN=GeoTrust TLS RSA CA G1

how many certificates it has withdrawn:
8407
```

</details>

**340,634 bytes and 8,407 entries, to answer one question about one
certificate.** That is the whole list of everything this authority has ever
withdrawn that has not yet expired, and a client that wants to check must fetch
all of it.

The dates are the other half of the problem. `lastUpdate` is 04:00 on the day of
the query and `nextUpdate` is the same time a week later. **A certificate revoked
an hour after that list was issued does not appear on it for another six days**,
and a client that fetched the list is entitled to cache and trust it for that
whole period.

So the mechanism has two costs and one gap. The bandwidth grows with the
authority's total revocations rather than with anything you care about, the
latency is on the first connection, and the freshness is measured in days.

<details class="deeper">
<summary>If you have run a CA: delta lists, and why they did not save it</summary>

The obvious fix for the size is to publish the changes rather than the whole
thing, and RFC 5280 specifies exactly that. A delta list carries only what
changed since a named base, and a client that already has the base applies it.

It works, and it did not solve the problem, for two reasons that are worth
knowing because they recur.

The first is that the client still needs the base, so the first connection of a
cold client pays the full cost anyway, and the first connection is where the
latency is noticed. The second is caching: delta lists are only useful to a
client that keeps state between connections and applies the delta correctly, and
the population of clients that do neither is large and cannot be upgraded.

The deeper issue is the shape of the whole thing. A revocation list is a
publication model, where the authority announces everything and every client
filters. That is efficient when most clients need most of the information, and
this is the opposite case: a client cares about one certificate and downloads
eight thousand. OCSP is the query model that follows from noticing that, and it
brought its own problem, which is the next section.

</details>

## The query, and what it costs you

<details class="predict">
<summary>An online status query returns an answer about one certificate. How long is that answer good for?</summary>

```bash
# AlmaLinux 10.2, x86_64
$ cd /root/rev
echo "asking the authority about this one certificate:"
openssl ocsp -issuer issuer.pem -cert leaf.pem -url http://status.geotrust.com -header "Host=status.geotrust.com" -resp_text 2>&1 | grep -E "Responder Id|Cert Status|This Update|Next Update|leaf.pem:" | head -8
asking the authority about this one certificate:
    Responder Id: 944FD45D8BE4A4E2A680FEFDD8F900EFA3BE0257
    Cert Status: good
    This Update: Aug 21 15:21:00 2026 GMT
    Next Update: Aug 28 14:21:00 2026 GMT
leaf.pem: good
	This Update: Aug 21 15:21:00 2026 GMT
	Next Update: Aug 28 14:21:00 2026 GMT
```

</details>

`Cert Status: good`, for one certificate, in a small response. That fixes the
bandwidth completely.

**Look at the two dates.** `This Update` is 15:21 on the day of the query and
`Next Update` is 14:21 a week later. The answer is a signed statement with a
seven-day validity, which means an online status protocol is not live. It is a
cache with an expiry, exactly like the list, and the freshness is the same.

That is the fact most material about OCSP leaves out, and it changes what the
mechanism is for. It is not real-time revocation. It is the same weekly answer,
delivered one certificate at a time instead of eight thousand.

The cost it introduces instead is privacy. A client that queries the authority
before visiting a site has told the authority which site it is about to visit,
along with its address and the time. That is a log of browsing held by a party the
user has no relationship with and did not choose.

## Stapling, which fixes both

```bash
# AlmaLinux 10.2, x86_64
$ cd /root/rev
echo "the status this server staples into its own handshake:"
openssl s_client -connect rlwilliamson.dev:443 -servername rlwilliamson.dev -status </dev/null 2>/dev/null | grep -E "OCSP Response Status|Cert Status:|This Update|Next Update" | head -4
echo
echo "and the same question asked of a responder that is not there:"
openssl ocsp -issuer issuer.pem -cert leaf.pem -url http://rlwilliamson.dev/there-is-no-responder-here 2>&1 | head -3
the status this server staples into its own handshake:
    OCSP Response Status: successful (0x0)
    Cert Status: good
    This Update: Aug 21 15:21:00 2026 GMT
    Next Update: Aug 28 14:21:00 2026 GMT

and the same question asked of a responder that is not there:
Error querying OCSP responder
40C7D0A0FFFF0000:error:1E800074:HTTP routines:OSSL_HTTP_REQ_CTX_nbio:redirection not enabled:crypto/http/http_client.c:765:
40C7D0A0FFFF0000:error:1E800067:HTTP routines:OSSL_HTTP_REQ_CTX_exchange:error receiving:crypto/http/http_client.c:1046:server=http://rlwilliamson.dev:80
```

The server fetched its own status answer from the authority, and included it in
the handshake. The client got `Cert Status: good` without asking anybody, so there
is no extra connection, no download of eight thousand entries and no third party
learning where the user is going.

<figure class="learn-figure">
<svg viewBox="0 0 720 330" role="img" aria-labelledby="rev-title" style="width:100%;height:auto;">
<title id="rev-title">Three ways to find out whether a certificate is revoked, drawn as who asks whom, with the real size and freshness of each answer and what a browser concludes when no answer arrives</title>
<g fill="currentColor">
<text x="14" y="20" font-size="11">three ways to ask the same question, and what each one costs the client</text>
<text x="14" y="52" font-size="10">crl</text>
<rect x="80" y="38" width="90" height="24" rx="3" fill="none" stroke="currentColor" stroke-opacity="0.7" stroke-width="1.4"/>
<text x="125" y="54" text-anchor="middle" font-size="9.5">client</text>
<path d="M 178 50 H 268" stroke="currentColor" stroke-opacity="0.75" stroke-width="1.5"/>
<path d="M 260 45 L 270 50 L 260 55" fill="none" stroke="currentColor" stroke-opacity="0.75" stroke-width="1.5"/>
<rect x="276" y="38" width="120" height="24" rx="3" fill="none" stroke="currentColor" stroke-opacity="0.7" stroke-width="1.4"/>
<text x="336" y="54" text-anchor="middle" font-size="9.5">the authority</text>
<text x="410" y="47" font-size="9.5" fill-opacity="0.85">340,634 bytes, 8,407 entries</text>
<text x="410" y="61" font-size="9.5" fill-opacity="0.85">reissued weekly, for one lookup</text>
<text x="14" y="112" font-size="10">ocsp</text>
<rect x="80" y="98" width="90" height="24" rx="3" fill="none" stroke="currentColor" stroke-opacity="0.7" stroke-width="1.4"/>
<text x="125" y="114" text-anchor="middle" font-size="9.5">client</text>
<path d="M 178 110 H 268" stroke="currentColor" stroke-opacity="0.75" stroke-width="1.5"/>
<path d="M 260 105 L 270 110 L 260 115" fill="none" stroke="currentColor" stroke-opacity="0.75" stroke-width="1.5"/>
<rect x="276" y="98" width="120" height="24" rx="3" fill="none" stroke="currentColor" stroke-opacity="0.7" stroke-width="1.4"/>
<text x="336" y="114" text-anchor="middle" font-size="9.5">the authority</text>
<text x="410" y="107" font-size="9.5" fill-opacity="0.85">one certificate, one answer</text>
<text x="410" y="121" font-size="9.5" fill-opacity="0.85">and the authority learns who you visit</text>
<text x="14" y="172" font-size="10">stapled</text>
<rect x="80" y="158" width="90" height="24" rx="3" fill="none" stroke="var(--accent)" stroke-width="1.6"/>
<text x="125" y="174" text-anchor="middle" font-size="9.5">client</text>
<path d="M 178 170 H 268" stroke="var(--accent)" stroke-width="1.7"/>
<path d="M 260 165 L 270 170 L 260 175" fill="none" stroke="var(--accent)" stroke-width="1.7"/>
<rect x="276" y="158" width="120" height="24" rx="3" fill="var(--accent)" fill-opacity="0.16" stroke="var(--accent)" stroke-width="1.6"/>
<text x="336" y="174" text-anchor="middle" font-size="9.5">the server</text>
<path d="M 404 170 H 470" stroke="currentColor" stroke-opacity="0.5" stroke-width="1.4" stroke-dasharray="4 3"/>
<path d="M 462 165 L 472 170 L 462 175" fill="none" stroke="currentColor" stroke-opacity="0.5" stroke-width="1.4"/>
<rect x="478" y="158" width="120" height="24" rx="3" fill="none" stroke="currentColor" stroke-opacity="0.55" stroke-width="1.2" stroke-dasharray="4 3"/>
<text x="538" y="174" text-anchor="middle" font-size="9.5">the authority</text>
<text x="80" y="204" font-size="9.5" fill-opacity="0.85">the answer arrives inside the handshake, and the dashed hop happened hours ago</text>
<path d="M 14 226 H 706" stroke="currentColor" stroke-opacity="0.3" stroke-width="1"/>
<text x="14" y="252" font-size="10" fill-opacity="0.85">and when no answer arrives at all, a browser connects anyway</text>
<text x="14" y="276" font-size="10" fill-opacity="0.85">so an attacker who can block the check has defeated all three of these</text>
<text x="14" y="298" font-size="10" fill-opacity="0.85">which is why the real answer is a certificate short enough not to need revoking</text>
<text x="14" y="320" font-size="10" fill-opacity="0.85">the ocsp answer above is itself valid for seven days, so none of this is live</text>
</g></svg>
<figcaption>Every figure here is measured from the certificate this site serves. A certificate revocation list is one file covering every certificate that authority ever withdrew, 340,634 bytes and 8,407 entries, reissued weekly, downloaded to answer one question. OCSP asks about a single certificate and gets a single answer, at the cost of telling the authority which sites you visit. Stapling has the server fetch that answer periodically and include it in the handshake, which removes both the size and the privacy problem. What it does not remove is the last line: the OCSP answer captured for this page carries a next update seven days later, so it is a cached statement rather than a live one, and a browser that gets no answer at all connects regardless. Revocation is the weakest part of the model, and the direction the industry actually went was shorter certificate lifetimes, which is a way of not needing it.</figcaption>
</figure>

The answer is signed by the authority, so the server cannot forge it, and it
carries the same seven-day window, so the server refreshes periodically rather
than per connection.

This is the mechanism to prefer and it is a server-side decision. A client cannot
make a server staple, which is why the second block asks the question of a real
server rather than describing the feature.

<details class="deeper">
<summary>If you configure servers: must-staple, and why almost nobody sets it</summary>

Stapling leaves one hole. A server that simply does not staple looks, to the
client, exactly like a server that could not reach the authority, and the client
proceeds either way. An attacker holding a stolen key and a revoked certificate
just does not staple.

The fix is an extension in the certificate itself, usually called must-staple,
which tells clients that this certificate will always arrive with a status and
that a handshake without one should be refused. It converts stapling from an
optimisation into a requirement, and it closes the hole properly.

It is also close to unused, and the reason is operational rather than technical.
With must-staple set, any failure to obtain a fresh status takes the site down
completely: the authority's responder being slow, a network problem between your
server and them, a clock skew, an expired stapled response nobody noticed. You
have made a third party's availability into your own availability, and the
failure is total rather than degraded.

That trade is the same one that runs through this whole topic. Every mechanism
that makes revocation actually work also makes an outage somewhere else into an
outage here, and the industry has consistently chosen availability. Whether that
was right is a real argument; what is not arguable is that it was chosen, and it
is why revocation does not work the way people assume.

</details>

## What happens when nothing answers

The second half of that capture is the important one. A status query to a
responder that is not there produced an error, and no answer about the
certificate at all.

**A browser in that position connects anyway.** That is soft-fail, it is the
default behaviour in every mainstream browser, and it means an attacker who can
prevent the check has defeated the entire mechanism. Somebody who can present a
stolen certificate on a network they control can usually also drop traffic to the
authority.

The alternative is hard-fail, refusing to connect when the check cannot complete,
and the reason nobody does it is availability. Under hard-fail, an authority's
responder going down takes every site it issued for off the internet
simultaneously. That has happened, at scale, and the outage was worse than the
risk being managed.

**So the honest summary of revocation is that it works against an inattentive
adversary and not against an attentive one.** A certificate withdrawn because a
company changed hosting will stop being accepted, eventually. A certificate
withdrawn because a criminal has the key will keep working for anybody the
criminal can position themselves against.

<details class="deeper">
<summary>If you have argued for hard-fail: what browsers built instead, and its limits</summary>

The browser vendors did not accept soft-fail as the end of the discussion. What
they built instead is worth knowing, because it is the mechanism actually
protecting people today and it is invisible.

Rather than asking per connection, a browser ships with a list. The vendor
collects revocations from the authorities on a schedule, filters them down to the
ones that matter, compresses the result aggressively, and pushes it to every
installation as an ordinary update. The client then answers the question locally,
in microseconds, with nothing to block and nobody to tell.

That is a publication model again, which is where this topic started, and it
works this time because the publisher is somebody with an existing update channel
reaching a billion clients. The authority never sees the query and the network
attacker has nothing to interfere with.

Two limits come with it. The list has to be small enough to push, so it is
filtered rather than complete, and the filtering criteria are the vendor's:
typically the certificates most likely to matter rather than all of them. And it
is a vendor mechanism rather than a standard, so each browser has its own, and
anything that is not a browser, which is most software making TLS connections, is
still doing what this topic describes or nothing at all.

That last point is the one worth carrying into a design review. Your monitoring
agent, your build pipeline and your application's HTTP client are almost certainly
not checking revocation in any form.

</details>

## The answer the industry actually chose

Given all of the above, the direction taken was not a better revocation
mechanism. It was to make revocation matter less by shortening the window.

The certificate this page reads has a validity of May to November 2026, which is
roughly six months. Ten years ago three years was normal, and the maximum has
been cut repeatedly by the browser vendors and the authorities through the
CA/Browser Forum, with further reductions agreed.

The logic is simple and it is worth following, because it explains a lot of
industry behaviour that otherwise looks arbitrary. If a certificate lives six
months, a compromise you never detect is exploitable for at most six months. If it
lives six days, it is exploitable for six days, and the value of revoking it at all
approaches zero.

**That is only tolerable because issuance was automated first.** A six-day
certificate renewed by hand is an outage waiting for a holiday. The order of
events matters: automation made short lifetimes possible, short lifetimes made
revocation less important, and the mechanisms in this topic remain in place for
the cases automation does not cover.

## Across platforms

Everything above is a library doing the checking, which is how Linux works and is
why the Linux column is a list of commands. Windows and macOS do it somewhere
else, and the difference is the point of this table.

| Task | Linux | Windows | macOS |
| --- | --- | --- | --- |
| Read the revocation endpoints | `openssl x509 -ext crlDistributionPoints` | `certutil -dump` | `/usr/bin/openssl x509 -text` |
| Check status online | `openssl ocsp -issuer -cert -url` | `certutil -verify -urlfetch` | trust evaluation, not a direct command |
| See what is cached | nothing shared, per application | `certutil -urlcache CRL` | held by the security framework |
| Verify the whole chain | `openssl verify` | `X509Chain` with `RevocationMode` | `security verify-cert` |

```powershell
# Microsoft Windows Server 2025 Datacenter, version 10.0.26100.0
> $t = [Net.Sockets.TcpClient]::new('rlwilliamson.dev', 443); $s = [Net.Security.SslStream]::new($t.GetStream()); $s.AuthenticateAsClient('rlwilliamson.dev'); $c = [Security.Cryptography.X509Certificates.X509Certificate2]::new($s.RemoteCertificate); [IO.File]::WriteAllBytes("$env:TEMP\leaf.cer", $c.RawData); $c.Subject
CN=rlwilliamson.dev

# Build and verify the chain, fetching revocation information over the network
> certutil -verify -urlfetch "$env:TEMP\leaf.cer" 2>&1 | Select-String -Pattern "Revocation check|CRL|OCSP|Cert is|Verified Issuance|Leaf certificate revocation check" | Select-Object -First 8
  Verified "Base CRL (0c75)" Time: 0 47411632cb20c3dcecce4c3c46474809f4025332
    [0.0] http://cdp.geotrust.com/GeoTrustTLSRSACAG1.crl
  ----------------  Base CRL CDP  ----------------
  ----------------  Certificate OCSP  ----------------
  Verified "OCSP" Time: 0 144278ccf09bc6c032327a5cab323b84f874e4ad
    CRL (null):
    CRL: 053986866ccad7dbe931f6dca3837040961deb69
  Verified "Base CRL (0307)" Time: 0 fe7eb2a41602ab8c605e565305da5dfc76013d36

# What the chain engine has already cached, which is where the freshness lives
> certutil -urlcache CRL 2>&1 | Select-Object -First 6
http://crl.microsoft.com/pki/crl/products/MicRooCerAut2011_2011_03_22.crl
http://crl3.digicert.com/DigiCertGlobalRootG2.crl

# The same question through .NET, which is what an application actually calls
> $ch = [Security.Cryptography.X509Certificates.X509Chain]::new(); $ch.ChainPolicy.RevocationMode = 'Online'; $ch.ChainPolicy.RevocationFlag = 'EntireChain'; "chain builds: $($ch.Build($c))"; $ch.ChainStatus | ForEach-Object { $_.Status }
chain builds: True
```

The chain engine fetched and verified both the list and the online status, and
`certutil -urlcache` shows what it has kept. **That cache is where the freshness
actually lives on Windows**, and it is shared by every application on the machine
rather than being each application's problem, which is the structural difference
worth taking away: on Windows and macOS an application gets revocation checking
whether or not its author thought about it, and on Linux it gets whatever the
library was told to do.

```bash
# macOS 26.5.2, arm64
$ /usr/bin/openssl s_client -connect rlwilliamson.dev:443 -servername rlwilliamson.dev </dev/null 2>/dev/null | sed -n '/BEGIN CERT/,/END CERT/p' > /tmp/leaf.pem; /usr/bin/openssl x509 -in /tmp/leaf.pem -noout -subject
subject= /CN=rlwilliamson.dev

# Whether the openssl Apple ships has the subcommand the Linux column uses
$ /usr/bin/openssl ocsp -help 2>&1 | head -2
usage: ocsp [-CA file] [-CAfile file] [-CApath directory] [-cert file]
    [-dgst alg] [-header name value] [-host hostname:port]

# The system's own trust evaluation, which is what an application gets
$ security verify-cert -c /tmp/leaf.pem -p ssl 2>&1 | sed $'s/\033\[[0-9;]*m//g' | head -4
...certificate verification successful.
---
No extended validation result found
Certificate Transparency (CT) status: verified

# Whether the server offered a stapled status, asked with the tool that is here
$ /usr/bin/openssl s_client -connect rlwilliamson.dev:443 -servername rlwilliamson.dev -status </dev/null 2>&1 | grep -E "OCSP response|Cert Status" | head -3
OCSP response: 
    Cert Status: good
```

Two things there. `security verify-cert` reports the system's own verdict,
including a certificate transparency status, which is the operating system doing
work no command asked it to do. And the openssl Apple ships does have `ocsp`,
unlike the `-ext` flag from topic 09 that it does not have, so the divergence
between LibreSSL and OpenSSL is subcommand by subcommand rather than wholesale.

## Prove it

**Run it.** Take any site you use and read its revocation endpoints out of the
certificate, the way the first block on this page does. Then fetch the list it
points at and look at how large it is and how many entries it holds. The number
is usually a surprise.

**Work it out.** An authority reissues its list weekly and has 8,407 live
revocations at 340,634 bytes. A certificate is compromised and revoked one hour
after an issue. How long, at worst, before a client that checks only the list will
see it? Now suppose the list were reissued hourly: what happens to the client's
bandwidth over a month of daily browsing, and is that a trade you would make?

**Look it up.** RFC 6960 section 2.2 defines the three status values a responder
can return. Read what `unknown` means and answer one question: is `unknown` a
statement that the certificate is fine, that it is bad, or neither, and what
should a client do with it? The answer explains a class of misconfiguration that
is invisible in a browser.

## What trips people up

### 1. Believing a revocation check is live

Both mechanisms return an answer with a validity period, and on the certificate
read for this page that period is seven days. Revoking a certificate does not
produce an immediate effect anywhere.

### 2. Assuming a browser refuses when the check fails

It connects. Soft-fail is the default everywhere, so an attacker who can block
the check has removed it, and blocking traffic is easier than obtaining a
certificate.

### 3. Thinking stapling is something the client turns on

It is a server-side decision. A client can indicate that it would like a stapled
response and cannot compel one, which is exactly the hole must-staple exists to
close.

### 4. Reading OCSP as strictly better than a list

It is better on bandwidth and worse on privacy, because the query tells the
authority which site is about to be visited. Stapling is what gets both, and it
requires the server operator to have done something.

### 5. Confusing revocation with expiry

Expiry is in the certificate and every client enforces it without asking anybody.
Revocation is an external claim that has to be looked up, and looking it up is
optional in practice. That difference is why shortening expiry is the intervention
that actually worked.

### 6. Expecting a revoked certificate to disappear

It stays valid-looking. Nothing about the file changes, the signature still
verifies, and the only way to know is to ask somebody, which is the whole problem.

## Work it through

Back to the stolen key and the padlock on Monday afternoon.

**First, what revocation actually did.** The authority added the certificate's
serial number to its list and its responder began answering revoked for it. Both
of those are true within minutes and neither of them reaches out to anybody.

**Then what the victim's browser did.** It received the certificate from the
attacker, validated the chain, and checked the name. All of that passed, because
the certificate is genuine and the attacker holds the matching key.

**Then the revocation check, which is where it fails, in one of three ways.** If
the browser relies on a cached list, that list was fetched before the revocation
and is good for another six days. If it queries the responder, the attacker who
controls the network drops the query, and the browser soft-fails and continues. If
the attacker simply declines to staple, the browser has nothing to check and
continues.

**So no step went wrong.** Every component behaved as specified, and the
specification prefers availability over refusing an uncertain connection. That is
a decision somebody made, not an oversight, and it is defensible: hard-fail has
caused larger outages than soft-fail has caused breaches.

**What actually limits the damage** is the certificate's remaining lifetime,
which is why that number has been falling for a decade. Six months of exposure is
a lot. Six days is a manageable incident.

The decision, written the way it should be written down: rely on short lifetimes
and automated reissuance as the primary control, staple status so the ordinary
case is covered cheaply, and treat revocation as a cleanup mechanism rather than
as a response to a live compromise. The rejected option is must-staple with
hard-fail, and the cost of rejecting it is that a determined attacker on the path
is not stopped by any of this. The cost of choosing it would have been the
authority's availability becoming yours.

## Try it

**Read the endpoints out of a certificate and fetch what they point at.** Pick a
large site, get the CRL URL out of its certificate, download it and count the
entries. Some authorities publish lists in the tens of megabytes, and finding one
makes the argument about size concrete in a way no description does.

**Check whether a site staples.** One command with `-status`. Try a few and notice
how many do not, including ones that should know better.

**Read RFC 6960 section 2.2 and section 2.3.** They are short, and between them
they define what a responder may say and what a client should do about each. Then
ask yourself which of those three answers your browser distinguishes in its
interface, and what that tells you.

## Check yourself

<details class="qa">
<summary>A certificate is revoked at midday. A user visits the site an hour later and sees a padlock. Which of the components failed?</summary>

None of them. The authority published, the browser validated the chain and the
name, and the revocation check either used a cached answer that predates the
revocation, or got no answer and soft-failed, or was never prompted because the
server did not staple.

Every mechanism has a validity period measured in days, and browsers treat a
missing answer as permission to continue. That is a deliberate preference for
availability, and it is why revocation does not stop an attacker who controls the
network.

</details>

<details class="qa">
<summary>What does a client download to check one certificate against a revocation list, and how fresh is the result?</summary>

The whole list. For the authority read on this page that is 340,634 bytes and
8,407 entries, and it covers every certificate that authority has withdrawn.

The freshness is the reissue interval, which for that list is a week. A
certificate revoked shortly after an issue does not appear until the next one, and
a client is entitled to cache and trust the copy it has for that whole period.

</details>

<details class="qa">
<summary>OCSP returns an answer about one certificate rather than a whole list. What does it fix, and what does it introduce?</summary>

It fixes the bandwidth, because the response covers one certificate. It does not
fix the freshness: the response captured for this page carries a next update
seven days later, so it is a cached statement rather than a live one.

What it introduces is privacy loss. Querying the authority before visiting a site
tells that authority which site is about to be visited, and when, and from where.
Stapling removes that by having the server fetch the answer instead.

</details>

<details class="qa">
<summary>Why can a client not simply insist on stapling?</summary>

Because a server that does not staple is indistinguishable from a server that
could not reach its authority, and refusing both would break every correctly
configured site whose authority is having a bad day.

The extension that fixes it is set in the certificate rather than by the client:
must-staple tells clients that this certificate will always arrive with a status.
It is rarely used, because it makes the authority's availability into the site's
availability, and a failure to obtain a status takes the site down completely.

</details>

<details class="qa">
<summary>Given how weak revocation is, what actually limits the damage from a stolen key?</summary>

The certificate's remaining lifetime, which is why the maximum has been cut
repeatedly. A compromise nobody detects is exploitable until the certificate
expires, so shortening the certificate shortens the exposure directly.

That approach only became possible once issuance was automated, because a
short-lived certificate renewed by hand is an outage waiting to happen. The order
matters: automation first, then short lifetimes, and revocation demoted to a
cleanup mechanism rather than an incident response.

</details>

## References

- [RFC 5280](https://www.rfc-editor.org/rfc/rfc5280.html) - IETF, the certificate and CRL profile, including the distribution point extension and delta lists. Free. Accessed 2026-08-21.
- [RFC 6960](https://www.rfc-editor.org/rfc/rfc6960.html) - IETF, the online certificate status protocol, and the definition of the three status values a responder may return. Free. Accessed 2026-08-21.
- [RFC 6961](https://www.rfc-editor.org/rfc/rfc6961.html) - IETF, the TLS extension that carries stapled status responses. Free. Accessed 2026-08-21.
- [CA/Browser Forum Baseline Requirements](https://cabforum.org/working-groups/server/baseline-requirements/documents/) - CA/Browser Forum, where the maximum certificate lifetime is set and where the reductions are agreed. Free. Accessed 2026-08-21.
- [openssl-ocsp](https://docs.openssl.org/master/man1/openssl-ocsp/) - OpenSSL Project, the command that produced the status blocks on this page. Free. Accessed 2026-08-21.

**Where the numbers came from.** Every block on this page is captured, on
AlmaLinux 10.2 x86_64 pinned by digest, against the certificate
`rlwilliamson.dev` was serving on 21 August 2026 and the public endpoints that
certificate's own extensions name. The list size of 340,634 bytes and the count of
8,407 revocations are that authority's published list on that day and will drift.
The seven-day windows on both the list and the status response are read from the
`nextUpdate` fields in the captures rather than quoted from documentation. The
responder that did not answer is a path on this site's own domain, chosen so that
nothing was sent to a third party that had not published an endpoint for it.

**If you also work on Linux.** The Linux+ track's
[TLS certificates and ACME](/learn/linux-plus/tls-certificates-and-acme) topic
covers automated issuance, which is the mechanism that made short lifetimes
practical and is the reason revocation matters less than it used to.
