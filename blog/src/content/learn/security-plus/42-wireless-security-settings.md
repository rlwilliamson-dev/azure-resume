---
title: "Wireless security settings"
description: "Why choosing the encryption and choosing the authentication are two separate decisions, what a RADIUS server actually sends back besides yes, what WPA3 fixed and what it did not, and why the guest network is usually the one that reaches the finance server."
deck: "The guest network password is on a card at reception and has not changed in three years"
track: "security-plus"
level: "working"
order: 430
objectives:
  - "Separate the cipher choice from the key management choice, and say why they are independent"
  - "Read a real RADIUS exchange and name what comes back besides an accept"
  - "Say what WPA3 changed about the handshake and what it left alone"
  - "Choose between a pre-shared key and enterprise authentication, and state what each costs"
  - "Explain what a site survey and a heat map are for, and what neither of them measures"
  - "Say why a guest network is a segmentation problem rather than a wireless one"
prerequisites: ["secure-baselines"]
tags: ["security-plus", "security", "operations", "wireless"]
updated: 2026-08-25
draft: false
examObjectives:
  - exam: "sy0-701"
    domain: "4.0"
    objective: "4.1"
sources:
  - title: "RFC 2865, Remote Authentication Dial In User Service (RADIUS)"
    url: "https://www.rfc-editor.org/rfc/rfc2865.html"
    publisher: "IETF"
    accessed: 2026-08-25
    tier: 1
  - title: "RFC 3580, IEEE 802.1X Remote Authentication Dial In User Service (RADIUS) Usage Guidelines"
    url: "https://www.rfc-editor.org/rfc/rfc3580.html"
    publisher: "IETF"
    accessed: 2026-08-25
    tier: 1
  - title: "RFC 3748, Extensible Authentication Protocol (EAP)"
    url: "https://www.rfc-editor.org/rfc/rfc3748.html"
    publisher: "IETF"
    accessed: 2026-08-25
    tier: 1
  - title: "RFC 7664, Dragonfly Key Exchange"
    url: "https://www.rfc-editor.org/rfc/rfc7664.html"
    publisher: "IETF"
    accessed: 2026-08-25
    tier: 1
  - title: "RFC 8110, Opportunistic Wireless Encryption"
    url: "https://www.rfc-editor.org/rfc/rfc8110.html"
    publisher: "IETF"
    accessed: 2026-08-25
    tier: 1
  - title: "SP 800-97, Establishing Wireless Robust Security Networks"
    url: "https://csrc.nist.gov/pubs/sp/800/97/final"
    publisher: "NIST"
    accessed: 2026-08-25
    tier: 1
symptoms:
  - symptom: "Everybody on the wireless network has the same credential"
    anchor: "two-choices-that-look-like-one"
  - symptom: "A failed login tells an attacker whether the account exists"
    anchor: "the-two-rejects-are-not-the-same-size"
---

> **Before you read.** A visitor connects to the guest network using a password
> printed on a card at reception. The card has been there for three years, and
> several hundred people have photographed it.
>
> Somebody asks whether that is a problem.
>
> **What exactly is the problem, and is it the password?**

The password is the smaller half. The larger half is what the guest network can
reach, and the two get discussed as one thing because they arrive together in the
same conversation about wireless.

### Some words you will need

<dl class="terms">
<dt>cipher</dt>
<dd>The algorithm that encrypts the frames once keys exist. CCMP and GCMP are the current ones.</dd>
<dt>key management</dt>
<dd>How the two ends agree on those keys, and how they prove who they are while doing it. A completely separate setting.</dd>
<dt>pre-shared key</dt>
<dd>One passphrase, known to everybody on the network. Written PSK.</dd>
<dt>enterprise</dt>
<dd>Per-user credentials, checked by a server the access point talks to. The access point never learns the credential.</dd>
<dt>802.1X</dt>
<dd>The standard that carries an authentication conversation across a link before the link is usable.</dd>
<dt>EAP</dt>
<dd>Extensible Authentication Protocol. The conversation itself, in one of many methods.</dd>
<dt>RADIUS</dt>
<dd>The protocol the access point uses to ask a server whether to admit somebody, and to be told what to do about them.</dd>
<dt>SAE</dt>
<dd>Simultaneous Authentication of Equals. WPA3's replacement for the WPA2 four-way handshake when a passphrase is in use.</dd>
<dt>site survey</dt>
<dd>Measuring the radio environment in the actual building, before or after installing access points.</dd>
</dl>

## What breaks without this

**A shared credential cannot be revoked for one person.** Somebody leaves and the
only way to remove their access is to change the passphrase for everybody, which
is why it never happens.

**Nobody can say who was on the network.** With one credential, the logs record
device addresses and nothing about people, so an incident investigation starts
with no names in it.

**The wrong setting gets hardened.** Somebody upgrades the cipher and leaves the
key management alone, or the reverse, because the two are read as one control.

**The guest network reaches something it should not.** The wireless was configured
carefully and the switch port behind it was not, and the failure is on the wired
side of a problem everybody discusses as a wireless one.

## Two choices that look like one

An access point's configuration has two lines that people conflate, and they
answer different questions. This is not a matter of interpretation: they are
separate settings with separate lists of legal values.

```bash
# AlmaLinux 10.2, x86_64
$ rpm -q hostapd wpa_supplicant | tr "\n" " "; echo; echo "=== key_mgmt values this build documents"; grep -o "WPA-PSK-SHA256\|WPA-EAP-SHA256\|WPA-PSK\|WPA-EAP\|SAE\|FT-SAE\|FT-PSK\|FT-EAP\|OWE\|DPP" /usr/share/doc/hostapd/hostapd.conf 2>/dev/null | sort -u | tr "\n" " "; echo; echo "=== ciphers"; grep -o "CCMP-256\|GCMP-256\|CCMP\|GCMP\|TKIP" /usr/share/doc/hostapd/hostapd.conf 2>/dev/null | sort -u | tr "\n" " "
hostapd-2.11-2.el10.x86_64 wpa_supplicant-2.11-5.el10.x86_64 
=== key_mgmt values this build documents
DPP FT-EAP FT-PSK FT-SAE OWE SAE WPA-EAP WPA-EAP-SHA256 WPA-PSK WPA-PSK-SHA256 
=== ciphers
CCMP CCMP-256 GCMP GCMP-256 TKIP 
```

**Ten values on one line and five on the other, and they combine.** The first list
is who you are and how the keys get agreed. The second is what encrypts the frames
afterwards. Picking SAE does not pick a cipher, and picking GCMP-256 says nothing
about whether anybody had to prove who they were.

Read the first list again and notice what is in it. `WPA-PSK` is the shared
passphrase. `SAE` is WPA3's replacement for it, still a passphrase. `WPA-EAP` is
enterprise, where a server decides. The three `FT-` entries are the same three with
fast roaming between access points. `OWE` is encryption with no authentication at
all, which is what a guest network should usually be, and `DPP` is a provisioning
protocol for devices with no keyboard.

The second list has one entry that should not be used. `TKIP` was the interim
answer when WPA replaced WEP, it is still in the software because old equipment
exists, and enabling it on a modern network is the single most common way to
undo the rest of the configuration.

<details class="predict">
<summary>A network is configured with SAE and TKIP. Which of the two settings has determined its actual security?</summary>

**TKIP, and this is the reason the two lines are worth separating in your head.**

SAE is the strong choice on the key management line. It resists the offline attack
that a captured WPA2 handshake enables, and it is the headline feature of WPA3.
Selecting it feels like the decision has been made.

Then the frames are encrypted with TKIP, which is a 2003 stopgap built to run on
hardware designed for WEP. Whatever SAE established, the traffic afterwards is
protected by the weaker of the two, and an attacker attacks the traffic rather
than the handshake.

The general rule is worth stating in a form that survives the specific names on
this page: a chain of two independent settings is as strong as the weaker one, and
because they are independent, a hardening exercise that improves one and leaves
the other is common rather than unusual. Somebody reads a headline about WPA3,
changes the key management, and never looks at the cipher line.

In practice modern equipment will not let you pair SAE with TKIP, which is a good
guard rail and not a reason to skip the check. Plenty of equipment in service is
not modern.

</details>

<details class="deeper">
<summary>If you configure access points: what OWE actually is, and why the guest network probably wants it</summary>

Opportunistic Wireless Encryption is the odd one on that list, because it provides
encryption without authentication. There is no passphrase, the network is open in
the sense that anybody may join, and each client still gets its own encryption
keys.

That combination sounds pointless until you look at what an open guest network
does today. With no encryption at all, everything every guest does is readable by
everybody else in range, which is a genuinely bad property that persists because
"open" and "unencrypted" have been the same thing since the beginning.

OWE separates them. Anybody may join, and nobody may read anybody else's traffic.
For a coffee shop, a reception area, or a conference, that is exactly the right
shape, and it removes the thing that makes shared-passphrase guest networks
faintly absurd: a secret printed on a card, which everybody knows, which protects
guests from each other not at all because they all derive keys from it.

RFC 8110 is short and worth reading if you have ever had the argument about
whether the guest network needs a password. The honest answer is that a
passphrase on a guest network is a queue management tool rather than a security
control, and OWE is what you want if the goal was actually privacy.

The catch is client support, which is the catch with everything in this list. A
network that offers only OWE will turn some devices away, and the usual
deployment runs it alongside an open network so older clients still work, which
weakens the argument somewhat.

</details>

## What the server actually sends back

Enterprise authentication is usually described as "the access point asks a server
and the server says yes or no". That is true and it leaves out the interesting
part, which is everything else in the answer.

Here is a real exchange against a real RADIUS server.

```bash
# AlmaLinux 10.2, x86_64
$ radiusd -i 127.0.0.1 -p 1812; sleep 3; radtest wifi-user Correct-Horse-1 127.0.0.1 0 testing123
Sent Access-Request Id 227 from 0.0.0.0:52817 to 127.0.0.1:1812 length 79
	User-Name = "wifi-user"
	User-Password = "Correct-Horse-1"
	NAS-IP-Address = 10.88.0.71
	NAS-Port = 0
	Message-Authenticator = 0x00
	Cleartext-Password = "Correct-Horse-1"
Received Access-Accept Id 227 from 127.0.0.1:1812 to 127.0.0.1:52817 length 85
	Message-Authenticator = 0xdada84ecba53b641f15ac5d834dcadb4
	Reply-Message = "welcome to the corporate SSID"
	Tunnel-Type:0 = VLAN
	Tunnel-Medium-Type:0 = IEEE-802
	Tunnel-Private-Group-Id:0 = "42"
```

**Look at the last three lines of the accept.** The server did not only say yes.
It said which VLAN this user belongs on, and the access point will act on that.

Those three attributes together are how a single wireless network puts different
people on different networks. Everybody associates to the same SSID, the server
answers per user, and the contractor lands on VLAN 42 while the finance team lands
somewhere else, with no second network name and no second radio.

That is the thing a pre-shared key cannot do at all. There is no per-user answer
to give, because there is no per-user question: everybody presented the same
secret, so the network has nothing to distinguish them by.

<figure class="learn-figure">
<svg viewBox="0 0 720 330" role="img" aria-labelledby="psk-title" style="width:100%;height:auto;">
<title id="psk-title">The same association under a pre-shared key and under enterprise authentication, showing where the secret lives in each and what a per-user answer can carry</title>
<g fill="currentColor">
<text x="14" y="20" font-size="11">the same client joining the same network, twice, with the secret in a different place</text>
<text x="14" y="58" font-size="9.5" fill-opacity="0.9">pre-shared key</text>
<rect x="150" y="66" width="118" height="34" rx="4" fill="none" stroke="currentColor" stroke-opacity="0.7" stroke-width="1.4"/>
<text x="209" y="87" text-anchor="middle" font-size="9">client</text>
<path d="M 272 83 H 322" stroke="currentColor" stroke-opacity="0.75" stroke-width="1.6"/>
<path d="M 314 78 L 324 83 L 314 88" fill="none" stroke="currentColor" stroke-opacity="0.75" stroke-width="1.6"/>
<rect x="328" y="66" width="118" height="34" rx="4" fill="currentColor" fill-opacity="0.08" stroke="currentColor" stroke-opacity="0.8" stroke-width="1.6"/>
<text x="387" y="87" text-anchor="middle" font-size="9">access point</text>
<text x="150" y="118" font-size="8.5" fill="var(--red)" fill-opacity="0.95">one passphrase, and both ends hold the same one</text>
<text x="150" y="134" font-size="8.5" fill-opacity="0.8">so does everybody else who has ever joined</text>
<text x="470" y="80" font-size="8.5" fill-opacity="0.85">the network cannot tell</text>
<text x="470" y="96" font-size="8.5" fill-opacity="0.85">two clients apart, because</text>
<text x="470" y="112" font-size="8.5" fill-opacity="0.85">they presented the same thing</text>
<path d="M 14 168 H 706" stroke="currentColor" stroke-opacity="0.2" stroke-width="1"/>
<text x="14" y="204" font-size="9.5" fill-opacity="0.9">enterprise</text>
<rect x="150" y="212" width="104" height="34" rx="4" fill="none" stroke="currentColor" stroke-opacity="0.7" stroke-width="1.4"/>
<text x="202" y="233" text-anchor="middle" font-size="9">client</text>
<path d="M 258 229 H 296" stroke="currentColor" stroke-opacity="0.75" stroke-width="1.6"/>
<path d="M 288 224 L 298 229 L 288 234" fill="none" stroke="currentColor" stroke-opacity="0.75" stroke-width="1.6"/>
<rect x="302" y="212" width="104" height="34" rx="4" fill="currentColor" fill-opacity="0.08" stroke="currentColor" stroke-opacity="0.8" stroke-width="1.6"/>
<text x="354" y="233" text-anchor="middle" font-size="9">access point</text>
<path d="M 410 229 H 448" stroke="var(--accent)" stroke-opacity="0.9" stroke-width="1.6"/>
<path d="M 440 224 L 450 229 L 440 234" fill="none" stroke="var(--accent)" stroke-opacity="0.9" stroke-width="1.6"/>
<rect x="454" y="212" width="118" height="34" rx="4" fill="var(--accent)" fill-opacity="0.14" stroke="var(--accent)" stroke-width="1.8"/>
<text x="513" y="233" text-anchor="middle" font-size="9">RADIUS server</text>
<text x="150" y="264" font-size="8.5" fill-opacity="0.85">per-user credential, never held by the access point</text>
<text x="150" y="280" font-size="8.5" fill="var(--accent)" fill-opacity="0.95">the accept carries a VLAN, so the answer is about this person</text>
<text x="14" y="310" font-size="10" fill-opacity="0.85">removing one person from the top row means changing the passphrase for everyone</text>
</g></svg>
<figcaption>Both rows are the same client joining the same network. In the top row the secret is symmetric and universal: the client has it, the access point has it, and so does everybody who has ever been told it, which is why revoking one person means changing it for all of them. In the bottom row the access point holds no user credential at all and forwards the question, so the answer can be different per person, and the capture above shows what different looks like in practice: three attributes naming a VLAN. The bottom row costs a server, a certificate on it, and a supplicant configuration on every client, and that cost is the honest reason the top row is still everywhere.</figcaption>
</figure>

<details class="deeper">
<summary>If you have run a RADIUS server: what the protocol carries, and the two things it does not protect</summary>

RFC 2865 is from 1997 and it shows. The protocol is UDP, the shared secret between
the access point and the server is used to obscure the password attribute and to
sign the response, and almost everything else in the packet is in the clear.

That is why the user password attribute in the capture above is readable. Between
a client and an access point, EAP methods build a TLS tunnel and the credential
never appears in the clear. Between the access point and the RADIUS server, the
protection is that shared secret and whatever transport you put underneath, which
is why RADIUS over TLS exists and why the link between the two is usually kept on
a network you control.

Two things worth knowing beyond that. First, accounting is a separate packet type
on a separate port, and it is where the record of who was on the network for how
long actually comes from. An organisation that authenticates with RADIUS and
never collects accounting has the ability to say who may join and not who did.

Second, the attributes in the response are a general mechanism rather than a
wireless one. The same VLAN assignment works on a wired switch port, which is
what makes 802.1X on the wired side worth doing and is the reason RFC 3580 talks
about ports rather than radios. If the wireless is authenticated and the meeting
room network sockets are not, an attacker with a cable has an easier route than
one with an antenna.

</details>

## The two rejects are not the same size

Two failed authentications against the same server, one with a wrong password for
a real user and one for a user who does not exist.

<details class="predict">
<summary>Both attempts are rejected. Predict whether anything in the two rejections tells an observer which kind of failure it was.</summary>

```bash
# AlmaLinux 10.2, x86_64
$ radiusd -i 127.0.0.1 -p 1812; sleep 3; echo "=== wrong password"; radtest wifi-user wrong-password 127.0.0.1 0 testing123 2>&1 | tail -4; echo; echo "=== a user who does not exist"; radtest nobody anything 127.0.0.1 0 testing123 2>&1 | tail -3
=== wrong password
	Cleartext-Password = "wrong-password"
Received Access-Reject Id 27 from 127.0.0.1:1812 to 127.0.0.1:44183 length 69
	Message-Authenticator = 0xa213f92f3527b4d119ac759af4d2a68a
	Reply-Message = "welcome to the corporate SSID"

=== a user who does not exist
	Cleartext-Password = "anything"
	Received Access-Reject Id 119 from 127.0.0.1:1812 to 127.0.0.1:37179 length 38
	Message-Authenticator = 0x37772855c0bd78352e17d3fd76ea1a2c
```

**Sixty-nine bytes against thirty-eight, and one of them carries a message.**

Both attempts were refused, so the access decision is identical and correct. What
differs is everything around it. The real user's rejection came back carrying the
reply message that was configured against that account, because the account
matched and its reply attributes were assembled before the password was checked.
The account that does not exist matched nothing, so there were no attributes to
assemble and the packet is thirty-one bytes shorter.

An observer who can count bytes now has a way to test whether a username exists,
without ever guessing a password. That is user enumeration, and it is the same
defect as a login page whose "no such account" and "wrong password" messages
differ, met in a protocol where nobody thinks to look because the difference is a
length rather than a sentence.

This is a consequence of where the reply attributes were configured rather than
something RADIUS does by itself, which is the useful part: it is a configuration
mistake anybody can make, in a place nobody inspects. The fix is to attach reply
attributes in the stage that runs after a successful authentication rather than
the stage that runs before it.

</details>

**The general lesson outlives the protocol.** Any time a system gives two
different answers to two different failures, somebody can turn that difference
into a list of valid accounts. The difference does not have to be a message. A
length, a delay, or an extra round trip will do.

## What WPA3 changed

WPA2 with a passphrase has one well-known structural problem, and it is worth
stating precisely because the imprecise version leads people to the wrong fix.

The problem is not that the passphrase travels. It does not. The problem is that
the four-way handshake gives an observer enough material to test candidate
passphrases **offline**, at whatever rate their hardware allows, without touching
the network again. Capture once, guess for a year, and the network never knows.

**SAE changes that shape.** It is a password-authenticated key exchange, based on
the Dragonfly construction in RFC 7664, and its property is that a passive
observer of the exchange cannot use what they saw to test guesses offline.
Guessing has to happen against the live network, one attempt at a time, where it
is slow and visible.

That is a large improvement and it is a narrow one. Three things SAE does not do:

**It does not make a weak passphrase strong.** Online guessing is still guessing,
and a passphrase of `guest2023` will not survive it.

**It does not solve the shared-secret problem.** Everybody still has the same
passphrase, so nobody can be revoked individually and the logs still cannot name
anybody. SAE is a better way to use a shared secret, not an alternative to
sharing one.

**It does not encrypt anything by itself.** The cipher is the other line, as the
first section established.

<details class="deeper">
<summary>If you are planning a migration: transition mode, and the thing it gives back</summary>

Nobody moves a fleet to WPA3 at once, so equipment offers a transition mode where
one network name accepts both WPA2 and WPA3 clients. It works, it is the sensible
migration path, and it is worth being clear about what it costs while it is on.

A network in transition mode still accepts the WPA2 handshake, because that is
the point of it. So the offline-guessing property SAE was chosen for is available
to an attacker for as long as the mode is enabled, by the simple route of
presenting as a WPA2 client. The improvement arrives when transition mode is
turned off, not when WPA3 is turned on.

That is not an argument against transition mode. It is an argument for putting an
end date on it, and for knowing that the security case you made to fund the
project is not delivered until that date. Plenty of networks have been in
transition mode for years and describe themselves as WPA3.

The way to find out is to try to associate a WPA2-only client. If it works, the
old handshake is still on offer.

</details>

## Surveys, heat maps, and the guest network

A site survey is measurement in the actual building: walking the space with a
receiver and recording what the radio environment is, rather than what a
floor plan predicts. A heat map is the picture that comes out of it.

Both are answering coverage and interference questions rather than security ones,
and they belong in this objective for a reason that is easy to miss. **Coverage is
a security setting.** An access point turned up to reach the far corner of the
building also reaches the car park, and the boundary of your network is wherever
the signal is still usable rather than wherever the walls are.

The survey tells you where that is. Nothing else does, because transmit power and
actual coverage are related by the building, and the building is not in the
documentation.

**The guest network is the other half of this objective and it is not a wireless
problem.** Everything above concerns getting onto the radio. What makes a guest
network dangerous is what it is connected to on the wired side, and that is a
switch and firewall question with a wireless entry point.

The failure is ordinary. The guest SSID is put on a VLAN, the VLAN is trunked back
to a switch, and somewhere in the configuration that VLAN can route to an internal
subnet, either because it was set up in a hurry or because something needed to
work once. The wireless configuration can be perfect while this is true, and no
amount of WPA3 addresses it.

## Across platforms

The question a client asks is the same everywhere, and the three commands report
different subsets of the answer.

| Task | Linux | Windows | macOS |
| --- | --- | --- | --- |
| Which security the current network uses | `iw dev wlan0 link` plus `wpa_cli status` | `netsh wlan show interfaces` | `wdutil info` |
| List the networks in range and their security | `nmcli device wifi list` | `netsh wlan show networks mode=bssid` | `wdutil info` reports the joined network only |
| The stored profile for a saved network | `/etc/NetworkManager/system-connections/` | `netsh wlan show profile name=X key=clear` | `security find-generic-password -ga X` |

The Windows row has the one worth knowing about. `netsh wlan show profile
name=X key=clear` prints the saved passphrase in plain text, to any user who can
run it on that machine. That is not a defect, it is the documented behaviour, and
it is the practical answer to why a shared passphrase on a laptop that leaves the
building is a credential you have distributed rather than a secret you hold.

## Prove it

**Run it.** Install `freeradius` and `freeradius-utils` on any Linux machine, add
a test user to the `authorize` file, start `radiusd` and point `radtest` at it.
The whole exercise is under five minutes and it makes the accept and reject
packets concrete in a way reading about them does not.

**Work it out.** Take the reject capture above. If an attacker can distinguish a
real account from a fake one by packet length, how many attempts does it take to
test a list of a thousand candidate usernames, and does any account lockout
policy stop them? Then say what the fix is, and notice that it is a configuration
change rather than a protocol change.

**Look it up.** Open RFC 3580 and find the three attributes the capture returned.
The document says what a network access server is expected to do with them, and it
is worth reading the actual wording, because "expected to" is doing real work in
that sentence.

## What trips people up

### 1. Treating the cipher and the key management as one setting

They are separate lines with separate lists of legal values. A network can have a
modern key exchange and a 2003 cipher, and the traffic is protected by the weaker
one.

### 2. Believing WPA3 removes the shared-secret problem

SAE is a better way to use a shared passphrase. Everybody still has the same one,
nobody can be revoked individually, and the logs still cannot name a person.

### 3. Thinking enterprise means the access point checks the password

It never sees it. The access point forwards an authentication conversation to a
server and acts on the answer, which is why an access point in a public corridor
is a smaller problem under enterprise than under a pre-shared key.

### 4. Reading an accept as a yes

The capture above carried three attributes naming a VLAN alongside the accept. A
RADIUS response is an instruction as much as a decision, and the interesting
security properties usually live in the attributes.

### 5. Leaving transition mode on

A network accepting both WPA2 and WPA3 still offers the WPA2 handshake, so the
offline-guessing improvement is not delivered until the old mode is turned off.

### 6. Treating the guest network as a wireless problem

Whether guests can reach the finance server is decided by a VLAN, a trunk and a
firewall rule. The wireless configuration is upstream of the actual failure and
cannot fix it.

## Work it through

A twelve-person office, one access point, one passphrase everybody knows,
including three former employees. You have been asked to fix it and there is no
budget for a RADIUS server or the person to run one.

**The tempting move is to insist on enterprise.** It is the right answer in
general, it is what the exam will reward, and here it means standing up a server,
obtaining a certificate for it, configuring a supplicant on twelve machines and
several phones, and owning that server afterwards. In an office with no full-time
technical staff, the realistic outcome is that it half-works and somebody puts the
old network back alongside it.

**The move that works is to change the passphrase and change what it protects.**
Rotate it, which removes the three former employees. Then put the office network
and everything sensitive behind something that authenticates people rather than
devices: if the file share and the accounting system each require a personal
login, the wireless passphrase stops being the thing standing between a stranger
in the car park and the company's data.

**Then reduce what the radio reaches.** Turn the transmit power down until the
signal stops being usable in the car park, which a survey with a phone will tell
you, and put anything that must be on a shared network on a segment that reaches
the internet and nothing else.

**What this rejects is the correct answer in favour of one that will be
maintained.** Enterprise authentication is better and it is not free, and a
control nobody can run is worth less than a weaker one that stays configured. If
the office grows to fifty people the calculation changes, and the trigger for
revisiting should be written down now rather than discovered later.

The residual is real and worth naming: anybody with the current passphrase is on
the office network until it is rotated again, and there is still no record naming
who was on it. That has been accepted rather than solved.

## Try it

**Stand up a RADIUS server.** `dnf install freeradius freeradius-utils` or the
equivalent, add one user to `mods-config/files/authorize`, run
`radiusd -i 127.0.0.1 -p 1812` and then `radtest`. Watch an accept and a reject.

**Add a VLAN to the accept.** Put `Tunnel-Type := VLAN`,
`Tunnel-Medium-Type := IEEE-802` and `Tunnel-Private-Group-Id := "42"` against
your test user and run `radtest` again. The three attributes come back, and that
is per-user network placement in its entirety.

**Reproduce the enumeration difference.** Authenticate with a wrong password for
a user that exists, then for one that does not, and compare the packet lengths.
Then move the reply attributes so they are applied after authentication succeeds
and check that both rejects are now the same size.

**Read your own saved passphrase.** On Windows,
`netsh wlan show profile name="YourNetwork" key=clear`. It prints in plain text.
Whether that surprises you is a good measure of how much you were relying on the
passphrase being a secret.

## Check yourself

<details class="qa">
<summary>Name the two independent wireless settings that people treat as one, and give a legal but bad combination.</summary>

Key management and the cipher. Key management covers WPA-PSK, SAE, WPA-EAP, OWE
and the fast-roaming variants. The cipher covers CCMP, GCMP, their 256-bit forms
and TKIP.

A bad legal combination is SAE with TKIP: a modern key exchange protecting frames
encrypted by a 2003 stopgap. The traffic is only as good as the cipher, and the
independence of the two settings is exactly why a partial hardening happens.

</details>

<details class="qa">
<summary>What did SAE change about WPA2, and what did it leave alone?</summary>

It removed the offline attack. A passive observer of a WPA2 four-way handshake
gets material they can use to test candidate passphrases at their own pace,
forever. SAE's exchange does not yield that, so guessing has to happen against the
live network, one attempt at a time.

It leaves the shared secret intact. Everybody still uses the same passphrase, no
individual can be revoked, and the logs still cannot name anybody. It also leaves
the cipher choice alone, and it delivers nothing while transition mode is
accepting WPA2 clients.

</details>

<details class="qa">
<summary>Besides an accept, what did the RADIUS server in this topic send back, and what does the access point do with it?</summary>

Three attributes naming a VLAN: `Tunnel-Type = VLAN`,
`Tunnel-Medium-Type = IEEE-802` and `Tunnel-Private-Group-Id = "42"`, alongside a
reply message.

The access point places that client on VLAN 42. That is how one wireless network
puts different people on different networks with no second SSID, and it is
something a pre-shared key cannot do at all, because everybody presented the same
secret and there is nothing to tell them apart by.

</details>

<details class="qa">
<summary>Two rejections come back at 69 bytes and 38 bytes. What has an observer learned?</summary>

Which username exists. The longer rejection carried reply attributes that were
assembled because the account matched, before the password was checked. The
shorter one matched nothing and had none to carry.

That is user enumeration through a length difference rather than a message, and
the fix is a configuration change: attach reply attributes in the stage that runs
after authentication succeeds rather than the one that runs before it.

</details>

<details class="qa">
<summary>Why is a site survey in an objective about security settings?</summary>

Because coverage is a security setting. The boundary of a wireless network is
where the signal stops being usable, not where the building ends, and an access
point turned up to reach a far corner also reaches the car park.

A survey measures where that boundary actually is in this building, which nothing
else tells you, because the relationship between transmit power and real coverage
depends on the walls.

</details>

## References

- [RFC 2865](https://www.rfc-editor.org/rfc/rfc2865.html) - IETF, RADIUS, for the packet types, the shared secret between access point and server, and what is protected. Free. Accessed 2026-08-25.
- [RFC 3580](https://www.rfc-editor.org/rfc/rfc3580.html) - IETF, 802.1X RADIUS usage guidelines, and the source of the three VLAN attributes in the capture. Free. Accessed 2026-08-25.
- [RFC 3748](https://www.rfc-editor.org/rfc/rfc3748.html) - IETF, EAP, for the conversation 802.1X carries. Free. Accessed 2026-08-25.
- [RFC 7664](https://www.rfc-editor.org/rfc/rfc7664.html) - IETF, Dragonfly key exchange, the construction SAE is built on. Free. Accessed 2026-08-25.
- [RFC 8110](https://www.rfc-editor.org/rfc/rfc8110.html) - IETF, Opportunistic Wireless Encryption, for the guest network case. Free. Accessed 2026-08-25.
- [SP 800-97](https://csrc.nist.gov/pubs/sp/800/97/final) - NIST, Establishing Wireless Robust Security Networks, for the architecture the above sits in. Free. Accessed 2026-08-25.

**Where the content came from.** The RADIUS and hostapd blocks are captured from
an AlmaLinux 10.2 container running FreeRADIUS and hostapd 2.11, including the
accept with its VLAN attributes and the two rejections of different sizes. The
enumeration difference is a real consequence of where the reply attributes were
configured, reproduced deliberately, and the section says so rather than implying
the protocol does it unprompted. Nothing on this page captures a handshake being
attacked; the offline-guessing property is described from RFC 7664 and the
standard it belongs to, because demonstrating it would mean performing the attack
rather than showing its evidence. The comparison table is sourced rather than
captured, because a disposable runner has no wireless adapter.

**If you also work on networks.** The Network+ track's
[wireless security and authentication](/learn/network-plus/wireless-security-and-authentication)
covers the same settings from the network's side, and
[network segmentation](/learn/network-plus/network-segmentation) covers the wired
half of the guest network problem this topic ends on.
