---
title: "Wireless security and authentication"
description: "The password is on a whiteboard and forty people know it. What WPA3 changed and why it mattered, the operational difference between a shared key and per-user identity, what enterprise authentication actually involves, and why two protocols this subject is famous for are absent from the exam."
deck: "The password is on a whiteboard and forty people know it"
track: "network-plus"
level: "working"
order: 320
objectives:
  - "Say what WPA3 changed relative to WPA2 and what problem it solved"
  - "Explain the operational difference between pre-shared key and enterprise"
  - "Describe what enterprise authentication involves and which parties are in it"
  - "Say why guest isolation is separate from guest addressing"
  - "Explain why WEP and the original WPA are not on this exam"
prerequisites: ["ssids-network-types-and-access-points"]
tags: ["network-plus", "networking", "wireless", "security"]
updated: 2026-08-11
draft: false
examObjectives:
  - exam: "n10-009"
    domain: "2.0"
    objective: "2.3"
sources:
  - title: "IEEE 802.11, Wireless LAN Medium Access Control and Physical Layer Specifications"
    url: "https://standards.ieee.org/ieee/802.11/7028/"
    publisher: "IEEE Standards Association"
    accessed: 2026-08-11
    tier: 1
  - title: "IEEE 802.1X, Port-Based Network Access Control"
    url: "https://standards.ieee.org/ieee/802.1X/7345/"
    publisher: "IEEE Standards Association"
    accessed: 2026-08-11
    tier: 1
  - title: "RFC 2865, Remote Authentication Dial In User Service (RADIUS)"
    url: "https://www.rfc-editor.org/rfc/rfc2865"
    publisher: "IETF"
    accessed: 2026-08-11
    tier: 1
  - title: "RFC 3748, Extensible Authentication Protocol (EAP)"
    url: "https://www.rfc-editor.org/rfc/rfc3748"
    publisher: "IETF"
    accessed: 2026-08-11
    tier: 1
symptoms:
  - symptom: "Somebody leaves and the wireless password has to change on every device"
    anchor: "shared-key-against-per-user-identity"
  - symptom: "Guests on the same network can reach each other"
    anchor: "guest-isolation-is-a-separate-setting"
---

> **Before you read.** The wireless password is written on a whiteboard in the
> meeting room. Forty people know it, along with everyone who has ever visited,
> and it has not changed in three years because changing it means visiting forty
> devices.
>
> Somebody leaves the company on Friday.
>
> **What actually has to happen, and what will actually happen?**

Wireless security has two halves that get taught as one. There is the
cryptography, which is mostly a matter of choosing the current option and moving
on. And there is the credential model, which is an operations problem that
outlives every device on the network, and which is what the scenario above is
about.

### Some words you will need

<dl class="terms">
<dt>WPA2</dt>
<dd>The security scheme most networks still run. Sound if configured well, with one structural weakness in its handshake.</dd>
<dt>WPA3</dt>
<dd>The current one. Its main change is how two ends agree a key.</dd>
<dt>pre-shared key</dt>
<dd>One passphrase, known by every device on the network. Frequently written PSK, and also called personal.</dd>
<dt>enterprise</dt>
<dd>Each user or device authenticating as itself, checked by a separate server.</dd>
<dt>802.1X</dt>
<dd>The IEEE standard for controlling access to a port, wired or wireless, until the device has authenticated.</dd>
<dt>RADIUS</dt>
<dd>The protocol carrying that authentication to the server that answers it.</dd>
<dt>client isolation</dt>
<dd>Stopping devices on the same network from reaching each other.</dd>
</dl>

## What breaks without this

**The credential outlives the people.** A shared passphrase that cannot
practically be changed is a credential that everybody who has ever worked there
still holds.

**Guest wireless is assumed to isolate and does not.** Addressing guests
separately and stopping them reaching each other are two different settings, and
only one of them is obvious.

**The wrong thing gets deployed for the size of the site.** Enterprise
authentication is right for an office and heavy for a shop with one access point,
and knowing what it requires prevents both mistakes.

## What WPA3 changed

WPA2 has a specific structural weakness and it is worth stating precisely,
because the vague version leads people to the wrong conclusions.

When a device joins a WPA2 network it performs a four-way handshake with the
access point, which derives the session keys from the shared passphrase. That
exchange can be captured by anyone in range, and once captured it can be attacked
offline: an attacker guesses a passphrase, derives what the handshake would have
looked like, and compares. No further contact with the network is needed and there
is no rate limit, because the attack is happening on somebody else's computer.

**So the strength of a WPA2 network is entirely the strength of its passphrase**,
and against a captured handshake a weak one falls quickly.

WPA3 replaces that key agreement with one where the offline attack does not work.
Each guess has to be tested against the live network, which makes the attempt rate
observable and limitable rather than free. That is the substantive change.

Two smaller ones are worth knowing. WPA3 also encrypts traffic on open networks,
so a public network with no password still gets each client its own encryption
against passive listeners, which WPA2 did not offer at all. And it requires
protected management frames, which closes off a family of attacks that worked by
forging the messages that disconnect a client.

<details class="deeper">
<summary>If you already work on networks: why WEP and the original WPA are not on this exam, and why that is unusual</summary>

The research for this track found that objective 2.3 names WPA2 and WPA3 and
nothing else. WEP does not appear. The original WPA does not appear either.

That is a deliberate editorial choice and a departure from how this subject is
usually taught, where the standard treatment walks through WEP's failure, then
WPA as the interim fix, then WPA2. It is a good story and it explains why things
are the way they are.

CompTIA's decision is defensible on the grounds that the exam tests what you
should configure, and a candidate who can recite WEP's weaknesses but reaches for
WPA2 personal in a building of forty people has learned the history and missed the
job. The history is genuinely interesting and it is not what is being examined.

What is worth carrying from it, in one paragraph, is the shape of the failure
rather than the mechanism: WEP's problem was not that its cipher was weak in the
abstract, it was that the way it used the cipher leaked key material with ordinary
traffic, so an attacker gained by waiting rather than by computing. That is a
different class of flaw from a short passphrase, and it is why the answer was a
new scheme rather than a longer key.

If you already know the history, keep it. If you are learning this for the exam,
learn WPA2 and WPA3 and spend the time you saved on the credential model below,
which is where the real decisions are.

</details>

## Shared key against per-user identity

The cryptography above is a choice you make once. This is the one you live with.

**Pre-shared key** means one passphrase for the network, held identically by every
device on it. Simple, works everywhere, requires no infrastructure, and has one
property that dominates everything else: the secret is shared, so it can only be
revoked collectively.

**Enterprise** means each user or device authenticates as itself against a
separate server. Every device gets its own session keys derived from its own
authentication, and access can be granted or removed one account at a time.

<figure class="learn-figure">
<svg viewBox="0 0 720 320" role="img" aria-labelledby="psk-title" style="width:100%;height:auto;">
<title id="psk-title">A pre-shared key network where one secret is held by every device, next to an enterprise network where each device holds its own identity checked against an authentication server</title>
<g fill="currentColor">
<text x="14" y="20" font-size="11.5">pre-shared key</text>
<text x="344" y="20" text-anchor="end" font-size="10" fill-opacity="0.75">one secret, shared</text>
<rect x="120" y="40" width="120" height="34" rx="4" fill="currentColor" fill-opacity="0.14" stroke="currentColor" stroke-opacity="0.6"/>
<text x="180" y="62" text-anchor="middle" font-size="11">access point</text>
<line x1="58" y1="180" x2="180" y2="78" stroke="currentColor" stroke-opacity="0.45" stroke-width="1.2"/>
<line x1="124" y1="180" x2="180" y2="78" stroke="currentColor" stroke-opacity="0.45" stroke-width="1.2"/>
<line x1="190" y1="180" x2="180" y2="78" stroke="currentColor" stroke-opacity="0.45" stroke-width="1.2"/>
<line x1="256" y1="180" x2="180" y2="78" stroke="currentColor" stroke-opacity="0.45" stroke-width="1.2"/>
<line x1="322" y1="180" x2="180" y2="78" stroke="var(--red)" stroke-opacity="0.45" stroke-width="1.2"/>
<rect x="36" y="180" width="44" height="40" rx="3" fill="currentColor" fill-opacity="0.12" stroke="currentColor" stroke-width="1" stroke-opacity="0.5"/>
<text x="58" y="197" text-anchor="middle" font-size="9.5" fill-opacity="0.8">key</text>
<text x="58" y="211" text-anchor="middle" font-size="9.5" fill-opacity="0.8">P@ss</text>
<rect x="102" y="180" width="44" height="40" rx="3" fill="currentColor" fill-opacity="0.12" stroke="currentColor" stroke-width="1" stroke-opacity="0.5"/>
<text x="124" y="197" text-anchor="middle" font-size="9.5" fill-opacity="0.8">key</text>
<text x="124" y="211" text-anchor="middle" font-size="9.5" fill-opacity="0.8">P@ss</text>
<rect x="168" y="180" width="44" height="40" rx="3" fill="currentColor" fill-opacity="0.12" stroke="currentColor" stroke-width="1" stroke-opacity="0.5"/>
<text x="190" y="197" text-anchor="middle" font-size="9.5" fill-opacity="0.8">key</text>
<text x="190" y="211" text-anchor="middle" font-size="9.5" fill-opacity="0.8">P@ss</text>
<rect x="234" y="180" width="44" height="40" rx="3" fill="currentColor" fill-opacity="0.12" stroke="currentColor" stroke-width="1" stroke-opacity="0.5"/>
<text x="256" y="197" text-anchor="middle" font-size="9.5" fill-opacity="0.8">key</text>
<text x="256" y="211" text-anchor="middle" font-size="9.5" fill-opacity="0.8">P@ss</text>
<rect x="300" y="180" width="44" height="40" rx="3" fill="var(--red)" fill-opacity="0.12" stroke="var(--red)" stroke-width="1.8"/>
<text x="322" y="197" text-anchor="middle" font-size="9.5" fill-opacity="0.8">key</text>
<text x="322" y="211" text-anchor="middle" font-size="9.5" fill-opacity="0.8">P@ss</text>
<text x="322" y="238" text-anchor="end" font-size="10" fill="var(--red)">one person leaves</text>
<text x="14" y="264" font-size="10.5">the secret is the same in every box, so</text>
<text x="14" y="280" font-size="10.5">removing one person means changing all of them</text>
<text x="378" y="20" font-size="11.5">enterprise</text>
<text x="708" y="20" text-anchor="end" font-size="10" fill-opacity="0.75">one identity each</text>
<rect x="470" y="40" width="120" height="34" rx="4" fill="currentColor" fill-opacity="0.14" stroke="currentColor" stroke-opacity="0.6"/>
<text x="530" y="62" text-anchor="middle" font-size="11">access point</text>
<rect x="612" y="40" width="96" height="34" rx="4" fill="var(--accent)" fill-opacity="0.2" stroke="var(--accent)" stroke-width="1.8"/>
<text x="660" y="62" text-anchor="middle" font-size="10.5" fill="var(--accent)">auth server</text>
<line x1="590" y1="57" x2="610" y2="57" stroke="var(--accent)" stroke-width="2"/>
<line x1="422" y1="180" x2="530" y2="78" stroke="currentColor" stroke-opacity="0.45" stroke-width="1.2"/>
<line x1="488" y1="180" x2="530" y2="78" stroke="currentColor" stroke-opacity="0.45" stroke-width="1.2"/>
<line x1="554" y1="180" x2="530" y2="78" stroke="currentColor" stroke-opacity="0.45" stroke-width="1.2"/>
<line x1="620" y1="180" x2="530" y2="78" stroke="currentColor" stroke-opacity="0.45" stroke-width="1.2"/>
<line x1="686" y1="180" x2="530" y2="78" stroke="var(--red)" stroke-opacity="0.45" stroke-width="1.2"/>
<rect x="400" y="180" width="44" height="40" rx="3" fill="currentColor" fill-opacity="0.12" stroke="currentColor" stroke-width="1" stroke-opacity="0.5"/>
<text x="422" y="204" text-anchor="middle" font-size="9.5" fill-opacity="0.85">ana</text>
<rect x="466" y="180" width="44" height="40" rx="3" fill="currentColor" fill-opacity="0.12" stroke="currentColor" stroke-width="1" stroke-opacity="0.5"/>
<text x="488" y="204" text-anchor="middle" font-size="9.5" fill-opacity="0.85">ben</text>
<rect x="532" y="180" width="44" height="40" rx="3" fill="currentColor" fill-opacity="0.12" stroke="currentColor" stroke-width="1" stroke-opacity="0.5"/>
<text x="554" y="204" text-anchor="middle" font-size="9.5" fill-opacity="0.85">cara</text>
<rect x="598" y="180" width="44" height="40" rx="3" fill="currentColor" fill-opacity="0.12" stroke="currentColor" stroke-width="1" stroke-opacity="0.5"/>
<text x="620" y="204" text-anchor="middle" font-size="9.5" fill-opacity="0.85">dev</text>
<rect x="664" y="180" width="44" height="40" rx="3" fill="var(--red)" fill-opacity="0.12" stroke="var(--red)" stroke-width="1.8"/>
<text x="686" y="204" text-anchor="middle" font-size="9.5" fill-opacity="0.85">eli</text>
<text x="686" y="238" text-anchor="end" font-size="10" fill="var(--red)">one person leaves</text>
<text x="378" y="264" font-size="10.5">each box proves who it is to the server, so</text>
<text x="378" y="280" font-size="10.5">removing one person disables one account</text>
</g></svg>
<figcaption>The same five devices under each model, and the difference only shows when somebody leaves. On the left every box holds an identical copy of one secret, so the box marked in red cannot be dealt with on its own: revoking its access means changing the secret in all five, and in a real office that includes the printer and whatever is on the wall in the warehouse. On the right each box proves who it is to a server, so the same departure is one account disabled and nothing else touched. The encryption protecting the traffic is the same in both drawings.</figcaption>
</figure>

Now the scenario at the top, honestly. What should happen when somebody leaves a
PSK network is that the passphrase changes, on the access points and then on every
device that uses it, including the ones nobody thinks of: the printer, the
handheld scanner in the warehouse, the thermostat, the two laptops belonging to
people on holiday. What will actually happen is nothing, because that job is a
day of work and the risk feels abstract on the Friday somebody leaves.

That is not a failure of discipline. It is the credential model working exactly as
designed, and it is the reason enterprise authentication exists at all. The
cryptography is the same either way.

## What enterprise authentication involves

Three parties, and naming them makes the rest readable.

The **supplicant** is the device asking for access. The **authenticator** is the
access point or switch controlling the port, which starts out allowing nothing
through except the authentication conversation itself. The **authentication
server** is what actually decides, and the authenticator forwards to it rather
than answering.

**802.1X is the framework** for that, and it is not a wireless standard: the same
mechanism controls a wired switch port, which is why it turns up again in the
security block. **EAP** is the family of methods carried inside it, and there are
many, differing in what the device presents: a password, a certificate, or a
certificate on both sides. **RADIUS** is the protocol carrying the conversation
from the authenticator to the server.

Two things follow that are worth knowing before proposing this.

It needs a server, and the server becomes load bearing. If it is unreachable,
nobody new can join. Existing sessions usually continue, which means the failure
is invisible until the first person tries to connect in the morning.

And it needs the client configured to check the server, which is the step most
often skipped. If a device is set to authenticate but not to verify the server's
certificate, an attacker can stand up an access point with the same name, collect
the authentication attempt, and the client will hand it over. The protection
depends on the client caring who it is talking to, and the default in a lot of
manual configuration is that it does not.

## Guest isolation is a separate setting

The previous topic made this point from the network side and it belongs here too,
because it is a security control rather than a design detail.

Putting guests on their own SSID and their own VLAN stops them reaching the
internal network. It does nothing about guests reaching each other, because they
are all on one segment and traffic between two devices on the same segment does
not pass through anything that could stop it.

**Client isolation is the setting that stops it**, and it works at the access
point by refusing to forward frames from one associated client to another. It is
usually a single checkbox and it is off by default on a lot of equipment.

The case for turning it on is not theoretical. A public network without it is a
shared segment on which every device is reachable by every other, and a laptop
with file sharing left on at home is now offering it to a coffee shop.

## Prove it

Nothing captured here, for the reason the whole wireless block gives: the lab has
no radio. Two documents and one thing to check.

**IEEE 802.1X.** The scope is readable without purchase. Read it and answer one
question: does the standard describe itself as wireless, and what does the answer
tell you about where else you will meet it?

**RFC 3748.** Free, and worth ten minutes. Read the introduction and answer a
narrower question: is EAP an authentication method, or a framework that carries
them? Getting this right is the difference between the exam's vocabulary making
sense and not.

**Then look at your own client configuration.** On any device joined to an
enterprise wireless network, find the settings for that network and look for
whether it validates the server certificate and which authority it trusts. If the
answer is that it does not validate, you have found the gap the last section
described, on a real network, in about a minute.

## What trips people up

### 1. Thinking WPA3 fixed a broken cipher

WPA2's encryption is not the weakness. The weakness is that its handshake can be
captured and attacked offline at no cost, so the passphrase is the whole defence.
WPA3 changes the key agreement so guesses have to be made against the live
network.

### 2. Treating the credential choice as a security setting

Pre-shared key and enterprise use the same cryptography. What differs is whether
access can be revoked for one person, and that is an operations property rather
than a cryptographic one.

### 3. Believing a shared passphrase gets changed when somebody leaves

It rarely does, because changing it means touching every device including the
ones nobody remembers. Assume any long-lived shared key is held by everyone who
has ever been in the building.

### 4. Deploying enterprise without a plan for the server being down

Existing sessions usually survive, so the outage is invisible until people start
arriving in the morning and nobody can join.

### 5. Skipping server certificate validation on clients

A client that authenticates without checking who it is authenticating to will
hand its credentials to an access point with the right name. This is the most
common way enterprise wireless is undermined.

### 6. Assuming a guest VLAN isolates guests from each other

It separates them from the internal network. Client isolation is the separate
setting that stops guests reaching each other, and it is frequently off by
default.

## Work it through

Friday, somebody leaves, and the network uses a pre-shared key.

Start by being clear about what they still hold. Not an account, because there is
no account. They hold the passphrase, which is the same passphrase every device
has, and which grants full access to whatever the wireless network reaches. There
is no per-user revocation available, because there was never anything per user.

Then work out what changing it costs, because that number decides what actually
happens. Every device that joins the network needs the new one: laptops, phones,
printers, anything embedded, anything belonging to someone away that week. Some of
those have no screen and are reconfigured by a method somebody will have to look
up. In an office of forty people this is a day of somebody's time and a week of
stragglers.

That arithmetic is why the honest answer to "what will happen" is usually nothing,
and it is worth saying out loud in the meeting rather than pretending otherwise.
A control that is never exercised is not a control.

So the real options are two. Accept it, and treat the wireless network as
semi-public: put it outside the internal network, require a VPN or per-application
authentication for anything that matters, and stop pretending the passphrase is a
security boundary. Or change the credential model, which means enterprise
authentication, a RADIUS server, and clients configured to validate it.

The second is more work up front and it is the one that makes the Friday question
answerable, because leaving becomes one account disabled. Which to choose depends
on the size of the site and what the network reaches, and the useful way to frame
it is not security against convenience. It is whether you want the answer to
"somebody left" to be a day of work or a checkbox.

And the thing to do regardless, on Friday, costing nothing: check whether the
guest network shares the passphrase with the main one, and check whether client
isolation is on. Both are quick and both are commonly wrong.

## Try it

**Find out what your own wireless is using.** Every operating system will tell you
the security type of the network you are on. If it says WPA2 personal, the
passphrase is the whole defence.

**Check whether your client validates the server.** On an enterprise network, look
at the network's settings for certificate validation. This takes a minute and the
answer is frequently no.

**Test client isolation on a network you administer.** Two devices, try to reach
one from the other. If it works, isolation is off.

## Check yourself

<details class="qa">
<summary>What is the actual weakness in WPA2 that WPA3 addresses?</summary>

That its four-way handshake can be captured by anyone in range and then attacked
offline. An attacker guesses a passphrase, computes what the handshake would have
looked like, and compares, without contacting the network again and without any
rate limit.

So a WPA2 network's security is the strength of its passphrase and nothing else.

WPA3 replaces the key agreement so that each guess must be made against the live
network, which makes the attempt rate visible and limitable. It also encrypts
traffic on open networks and requires protected management frames.

</details>

<details class="qa">
<summary>Pre-shared key and enterprise use the same encryption. So what is the difference?</summary>

Revocation.

With a pre-shared key there is one secret, held identically by every device, so
access can only be withdrawn from everybody at once. Removing one person means
changing the passphrase everywhere, including on devices nobody remembers.

With enterprise each device authenticates as itself, so removing one person is
one account disabled and nothing else is touched.

That is an operations property rather than a cryptographic one, which is why
comparing them on strength misses the point.

</details>

<details class="qa">
<summary>Name the three parties in an 802.1X exchange and what each does.</summary>

The supplicant is the device asking for access. The authenticator is the access
point or switch holding the port closed to everything except the authentication
conversation. The authentication server decides, and the authenticator forwards to
it rather than answering itself.

EAP is the family of methods carried inside the exchange, and RADIUS is the
protocol carrying it from the authenticator to the server.

Worth noting that 802.1X is not a wireless standard. The same mechanism controls a
wired switch port.

</details>

<details class="qa">
<summary>Why is a client that does not validate the server certificate a serious problem on enterprise wireless?</summary>

Because the protection depends on the client caring who it is talking to.

An attacker can stand up an access point advertising the same network name. A
client configured to authenticate but not to check the server's certificate will
begin the exchange and hand over its credentials, and nothing warns the user.

Validation is the step that makes the credential worth having, and it is the step
most often skipped when a network is configured by hand on each device.

</details>

<details class="qa">
<summary>Guests are on their own SSID and their own VLAN. What are they still able to do?</summary>

Reach each other.

The VLAN separates guests from the internal network. It does nothing about traffic
between two devices on the guest segment, because that traffic never passes
through anything that could filter it.

Client isolation is the separate setting that stops it, implemented at the access
point by refusing to forward between associated clients. It is commonly off by
default, which makes a public network a shared segment full of strangers'
machines.

</details>

## References

- [IEEE 802.11](https://standards.ieee.org/ieee/802.11/7028/) - IEEE Standards Association, which defines the handshake and the management frame protection described here. Scope readable without purchase. Accessed 2026-08-11.
- [IEEE 802.1X](https://standards.ieee.org/ieee/802.1X/7345/) - IEEE Standards Association, port-based network access control, which is wired and wireless rather than wireless alone. Accessed 2026-08-11.
- [RFC 2865](https://www.rfc-editor.org/rfc/rfc2865) - IETF, the RADIUS specification. Free. Accessed 2026-08-11.
- [RFC 3748](https://www.rfc-editor.org/rfc/rfc3748) - IETF, which defines EAP as a framework carrying authentication methods rather than as a method. Free. Accessed 2026-08-11.

**Where the numbers came from.** Nothing on this page is captured: the lab behind
this track is Linux network namespaces and has no radio, and capturing a handshake
from a network in order to demonstrate an offline attack would be neither legal nor
useful here. The forty devices in the diagram are the scenario's number rather than
a measurement. The claim that client isolation is off by default on a lot of
equipment is a generalisation about vendor defaults rather than a figure, which is
why it is written as one.

**If you also work on Linux.** `wpa_supplicant` is the client side of all of this,
and its configuration file is the clearest place to see the difference between the
two models: a PSK network is a passphrase, and an enterprise one names an EAP
method, an identity, and the certificate authority it will accept. That last
setting is the validation the page above says is skipped, and in a hand written
config its absence is visible rather than buried in a dialog.
