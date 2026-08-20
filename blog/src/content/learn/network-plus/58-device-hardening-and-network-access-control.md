---
title: "Device hardening and network access control"
description: "A switch in a meeting room with sixteen live ports. The cheap controls that close most of the door, why MAC filtering is a speed bump you can watch an attacker step over, and 802.1X, where a port passes nothing but the authentication until the authentication succeeds."
deck: "A switch in a meeting room with sixteen live ports"
track: "network-plus"
level: "working"
order: 590
objectives:
  - "Name the cheap hardening steps and say what each one closes"
  - "Explain port security and why MAC filtering is weak"
  - "Say what a supplicant, an authenticator and an authentication server each do"
  - "Read an 802.1X exchange and tell a success from a failure"
  - "Say why a device that cannot do 802.1X reopens the MAC-filtering problem"
prerequisites: ["identity-and-access-management", "how-a-switch-learns"]
tags: ["network-plus", "networking", "security", "access-control"]
updated: 2026-08-15
draft: false
examObjectives:
  - exam: "n10-009"
    domain: "4.0"
    objective: "4.3"
sources:
  - title: "IEEE 802.1X-2020, Port-Based Network Access Control"
    url: "https://standards.ieee.org/ieee/802.1X/7345/"
    publisher: "IEEE"
    accessed: 2026-08-15
    tier: 1
  - title: "RFC 3748, Extensible Authentication Protocol (EAP)"
    url: "https://www.rfc-editor.org/rfc/rfc3748"
    publisher: "IETF"
    accessed: 2026-08-15
    tier: 1
  - title: "NIST SP 800-53 Rev. 5, Security and Privacy Controls"
    url: "https://csrc.nist.gov/pubs/sp/800/53/r5/upd1/final"
    publisher: "NIST"
    accessed: 2026-08-15
    tier: 1
symptoms:
  - symptom: "A MAC allow list is in place and an unauthorised device still connects"
    anchor: "port-security-and-the-speed-bump"
  - symptom: "A device is refused network access until it authenticates"
    anchor: "802-1x-and-the-port-that-stays-shut"
---

> **Before you read.** A meeting room has a small switch under the table with
> sixteen ports. Two are in use. The other fourteen are live, configured, and
> reachable by anyone who brings a cable, which in a meeting room is anyone at
> all.
>
> **What has each of those fourteen ports been handed, and what would it take for
> them to hand out nothing?**

Hardening is the unglamorous half of security: not stopping a clever attack, but
removing the easy access that was left on by default. Most of it costs nothing and
most of it is not done, and this topic runs from the cheapest controls to the one
that actually authenticates a device before letting it on.

### Some words you will need

<dl class="terms">
<dt>hardening</dt>
<dd>Removing default and unnecessary access from a device, so it offers only what it is meant to.</dd>
<dt>port security</dt>
<dd>A switch feature that limits which, or how many, MAC addresses may use a port.</dd>
<dt>802.1X</dt>
<dd>Port-based access control: a port passes nothing but the authentication exchange until the device authenticates.</dd>
<dt>supplicant</dt>
<dd>The device asking to join.</dd>
<dt>authenticator</dt>
<dd>The switch port it connects to, which holds the door shut until told otherwise.</dd>
<dt>authentication server</dt>
<dd>The system holding the credentials and making the decision, usually RADIUS.</dd>
</dl>

## What breaks without this

**An unused port is an open connection.** A live port with no device is an
invitation, and in any room the public can reach it is a serious one. The default
on most switches is that every port is on.

**A default credential is a published credential.** A device left with the
password it shipped with is protected by a secret that is in a manual and on the
internet, which is no secret.

**A control that trusts a MAC address trusts something public.** MAC filtering
looks like access control and is not, because the thing it checks is broadcast in
every frame and can be changed in one command.

## The cheap controls that close most of the door

Before the two mechanisms with acronyms, the controls that cost nothing and are
skipped anyway.

**Disable unused ports.** A port with nothing plugged into it should be
administratively down, so that plugging into it achieves nothing. The fourteen live
ports under the meeting room table are fourteen ways onto the network, and turning
them off is one command each. This is the single highest-value item on the page
because the access it removes is the easiest kind to abuse: physical, anonymous,
and requiring nothing but a cable.

**Disable unused services.** A switch or router runs services you are not using,
each a way in and a thing to keep patched. The management protocols left on by
default, the web interface nobody uses, the discovery protocols advertising the
device to anyone listening: each one that is off is one fewer.

**Change default credentials.** The account a device ships with has a password that
is documentation, not a secret. Changing it is the difference between a device
protected by a credential and a device protected by nobody having read the manual.
This is topic 52's console port from the other side: physical access is total
access partly because the local account is so often still the default one.

None of these stops a determined attacker on its own, and all of them together
remove the access that requires no skill, which is most of the access that gets
used.

<details class="deeper">
<summary>If you already harden estates: why the defaults are the whole problem</summary>

Almost everything in this category exists because equipment ships in a state designed for
somebody to be able to set it up, and that state is not a state to run in.

Default credentials are published by the manufacturer and collected into lists that any
automated tool tries first. Management services are enabled so a new device can be reached.
Discovery protocols are on so devices find each other. Every one of those is a reasonable
factory decision and an unreasonable production one, and nothing about the device
distinguishes between the two.

The consequence is that hardening is not a response to a threat assessment. It is finishing
the installation, and the reason it gets skipped is that the device works perfectly without
it, so nothing prompts anybody. A device commissioned by somebody in a hurry looks
identical to one commissioned properly until somebody looks.

Which is why this belongs in a build standard rather than in a security review. A
documented set of steps applied to every device as it is installed, checked by something
automated afterwards, costs almost nothing per device and removes an entire category. A
security review a year later finds the same issues at ten times the cost, on equipment that
is now in production and harder to change.

</details>

## Port security and the speed bump

Port security limits the MAC addresses allowed on a port: a specific address, or a
maximum count, with the port shutting down or dropping traffic when the limit is
exceeded. Limiting the count is genuinely useful, because it stops somebody
plugging a small switch into one port and attaching a room full of devices, and it
blunts the MAC flooding from topic 56 by capping how many addresses one port can
introduce.

Limiting to a specific MAC address, though, is where the exam wants you to see the
weakness, because a MAC address is not a secret. It is in the clear in every frame
the permitted device sends, an attacker on the segment reads it, and setting your
own interface to match is one command. The lab shows exactly that. The topology is
[`port-security.sh`](https://github.com/rlwilliamson-dev/azure-resume/blob/main/blog/scripts/topologies/port-security.sh),
and the switch is configured to accept one known-good address on the attacker's
port and drop the rest.

<details class="predict">
<summary>A machine with an address the switch has never seen is plugged into a port with port security on it. What happens to its first packet?</summary>

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology port-security
# the attacker, with its own address, is not on the allow list
$ ip netns exec atk ping -c1 -W1 10.0.0.1
PING 10.0.0.1 (10.0.0.1) 56(84) bytes of data.

--- 10.0.0.1 ping statistics ---
1 packets transmitted, 0 received, 100% packet loss, time 0ms

$ echo "with its own MAC: exit status $?"
with its own MAC: exit status 1

# it reads the allowed address off the wire and puts it on. one command
$ ip netns exec atk ip link set atk0 address 02:00:00:00:00:0d
$ ip netns exec atk ping -c1 -W1 10.0.0.1
PING 10.0.0.1 (10.0.0.1) 56(84) bytes of data.
64 bytes from 10.0.0.1: icmp_seq=1 ttl=64 time=0.132 ms

--- 10.0.0.1 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 0.132/0.132/0.132/0.000 ms
$ echo "wearing the allowed MAC: exit status $?"
wearing the allowed MAC: exit status 0
```

</details>

The filter did its job in both lines. With its own address the attacker was
dropped, which is the control working. After reading the allowed address off the
wire and putting it on, the attacker was admitted, which is the control being
worthless, and nothing in between was defeated. That is why MAC filtering is a
speed bump: it stops the device that has not bothered, and the one command that
steps over it is not a sophisticated attack.

<details class="deeper">
<summary>If you already run port security: the operational cost that gets it disabled</summary>

The control is weak against a determined attacker and its real problem is what it does to
the people running the network.

A port configured to shut down when it sees an unexpected address does exactly that, and
the events that trigger it are mostly innocent. Somebody swaps a laptop. A dock is moved
between desks. A meeting room gets a different device. A phone with a computer behind it
is replaced. Each one produces a dead port and a call, and the fix requires somebody with
access to clear it.

So the sticky version, where addresses are learned and remembered, gets used to reduce the
calls, and now the port trusts whatever was plugged in first, which is a substantially
weaker control. Or the shutdown is changed to a drop, which is quieter and means a
violation produces no signal at all. Or, most often, the whole thing is disabled on the
floor where the complaints came from.

Which is the honest case for the stronger control. Authentication per device does not care
that the laptop changed, because the new laptop authenticates as itself, so the operational
cost that kills port security does not arise. The reason to move is not that port security
is easy to defeat, although it is. It is that port security is expensive to live with, and
the version people can live with is the version that no longer protects anything.

</details>

## 802.1X and the port that stays shut

The difference 802.1X makes is that it asks for something the device has to prove
rather than something it can copy. The port itself refuses to pass ordinary traffic
until the device has authenticated, and it authenticates against a credential, not
an address.

Three roles do this, and the exam expects all three by name. The **supplicant** is
the device asking to join. The **authenticator** is the switch port, which holds
the door shut and passes nothing but the authentication conversation until it is
told to open. The **authentication server**, in practice a RADIUS server, holds the
credentials and makes the decision. One server backs every switch in the building,
which is the whole point: the credential lives in one place and every port consults
it.

<figure class="learn-figure">
<svg viewBox="0 0 720 236" role="img" aria-labelledby="dot1x-title" style="width:100%;height:auto;">
<title id="dot1x-title">A supplicant at a switch port whose authenticator passes only the EAPOL authentication exchange until the RADIUS server returns success, at which point the port opens to ordinary traffic</title>
<g fill="currentColor">
<text x="14" y="20" font-size="11">the port passes only the authentication until the server says yes</text>
<rect x="14" y="92" width="140" height="52" rx="4" fill="currentColor" fill-opacity="0.1" stroke="currentColor" stroke-opacity="0.7"/>
<text x="84" y="114" text-anchor="middle" font-size="10.5">supplicant</text>
<text x="84" y="130" text-anchor="middle" font-size="9.5" fill-opacity="0.75">the device</text>
<rect x="346" y="92" width="140" height="52" rx="4" fill="currentColor" fill-opacity="0.06" stroke="currentColor" stroke-opacity="0.7"/>
<text x="416" y="114" text-anchor="middle" font-size="10.5">authenticator</text>
<text x="416" y="130" text-anchor="middle" font-size="9.5" fill-opacity="0.75">the switch</text>
<rect x="566" y="92" width="140" height="52" rx="4" fill="currentColor" fill-opacity="0.06" stroke="currentColor" stroke-opacity="0.7"/>
<text x="636" y="112" text-anchor="middle" font-size="10.5">auth server</text>
<text x="636" y="128" text-anchor="middle" font-size="9.5" fill-opacity="0.75">radius, decides</text>
<text x="250" y="66" text-anchor="middle" font-size="9.5">EAPOL: allowed</text>
<path d="M 154 78 H 346" stroke="currentColor" stroke-opacity="0.75" stroke-width="1.4" fill="none"/>
<path d="M 338 73 l 8 5 l -8 5" stroke="currentColor" stroke-opacity="0.75" stroke-width="1.4" fill="none"/>
<path d="M 154 118 H 236" stroke="var(--red)" stroke-width="1.6" fill="none"/>
<line x1="240" y1="112" x2="252" y2="124" stroke="var(--red)" stroke-width="2"/>
<line x1="252" y1="112" x2="240" y2="124" stroke="var(--red)" stroke-width="2"/>
<text x="246" y="100" text-anchor="middle" font-size="9.5" fill="var(--red)">the port</text>
<text x="250" y="142" text-anchor="middle" font-size="9.5" fill="var(--red)">all other traffic: blocked</text>
<text x="526" y="106" text-anchor="middle" font-size="9.5">RADIUS</text>
<path d="M 486 118 H 566" stroke="currentColor" stroke-opacity="0.75" stroke-width="1.4" fill="none"/>
<text x="14" y="196" font-size="10" fill-opacity="0.8">on success the server opens the port, and only then does ordinary traffic cross</text>
</g></svg>
<figcaption>The supplicant may send only the authentication exchange, EAPOL, through the port; everything else is blocked at the barrier. The authenticator relays that exchange to the RADIUS server over its own protocol and does not itself decide anything. The server checks the credential and, on success, tells the port to open, at which point ordinary traffic crosses for the first time. The device proved something it knows or holds, rather than presenting an address anyone could copy, which is the difference from the control above it.</figcaption>
</figure>

The lab runs the three roles on one link: a supplicant, an authenticator running
its own EAP server, and the exchange captured on the wire. The topology is
[`dot1x.sh`](https://github.com/rlwilliamson-dev/azure-resume/blob/main/blog/scripts/topologies/dot1x.sh).
It uses EAP-MD5, which needs no certificates and keeps the capture short; it is
also weak, and a real deployment uses a certificate-based method, but the frames on
the wire have the same shape.

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology dot1x
$ ip netns exec auth hostapd -B /etc/hostapd.conf >/tmp/hostapd.log 2>&1
$ sleep 1
$ (ip netns exec auth timeout 8 tcpdump -i auth0 -n -U -v -c10 ether proto 0x888e > /tmp/eapol.txt 2>/dev/null &)
$ sleep 0.5
$ ip netns exec sup wpa_supplicant -D wired -i sup0 -c /etc/wpa_supplicant.conf -B >/tmp/supp.log 2>&1
$ sleep 9
$ cat /tmp/eapol.txt
23:07:11.871402 EAPOL start (1) v2, len 0
23:07:11.871842 EAP packet (0) v2, len 5, Request (1), id 15, len 5
		 Type Identity (1)
23:07:11.872064 EAP packet (0) v2, len 10, Response (2), id 15, len 10
		 Type Identity (1), Identity: host1
23:07:11.873212 EAP packet (0) v2, len 22, Request (1), id 16, len 22
		 Type MD5-challenge (4)
23:07:11.873290 EAP packet (0) v2, len 22, Response (2), id 16, len 22
		 Type MD5-challenge (4)
23:07:11.873342 EAP packet (0) v2, len 4, Success (3), id 16, len 4
```

Read it top to bottom and it is the whole protocol in six frames. The supplicant
starts, the authenticator asks who it is, the supplicant answers with its identity,
the server sends a challenge, the supplicant answers it, and the server returns
success. The identity is in the clear; the answer to the challenge is what proves
the credential without sending it.

Now the same device with the wrong secret.

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology dot1x
$ ip netns exec auth hostapd -B /etc/hostapd.conf >/tmp/hostapd.log 2>&1
$ sleep 1
$ (ip netns exec auth timeout 8 tcpdump -i auth0 -n -U -v -c10 ether proto 0x888e > /tmp/bad.txt 2>/dev/null &)
$ sleep 0.5
$ ip netns exec sup wpa_supplicant -D wired -i sup0 -c /etc/wpa_supplicant-bad.conf -B >/tmp/supp.log 2>&1
$ sleep 9
$ cat /tmp/bad.txt
23:07:23.936398 EAPOL start (1) v2, len 0
23:07:23.936798 EAP packet (0) v2, len 5, Request (1), id 23, len 5
		 Type Identity (1)
23:07:23.937069 EAP packet (0) v2, len 10, Response (2), id 23, len 10
		 Type Identity (1), Identity: host1
23:07:23.938297 EAP packet (0) v2, len 22, Request (1), id 24, len 22
		 Type MD5-challenge (4)
23:07:23.938415 EAP packet (0) v2, len 22, Response (2), id 24, len 22
		 Type MD5-challenge (4)
23:07:23.938473 EAP packet (0) v2, len 4, Failure (4), id 24, len 4
```

Every frame is identical up to the last one. Same start, same identity, same
challenge, and then the answer computed from the wrong secret produces a failure
rather than a success. The port stays shut. That is the property MAC filtering did
not have: getting the identity right is not enough, because the identity is not the
thing being checked.

<details class="deeper">
<summary>If you already work on networks: the transport the exam names, and the device that cannot authenticate</summary>

Two details sit behind the capture that are worth having straight.

The first is a naming one the exam tests. The frames in the capture are EAPOL,
which is EAP over LAN: the Extensible Authentication Protocol carried directly in
Ethernet frames between the supplicant and the authenticator. EAP itself, from RFC
3748, is a framework rather than a method; the actual method plugs into it, which is
why the same exchange can be MD5 here and a certificate-based method in production
without the shape changing. The exam lists EAPOL as the transport and rarely does
anything with it beyond expecting you to know the acronym, so know that it is the
thing carrying the authentication across the wire and that RADIUS carries it the
rest of the way to the server.

The second is the device that cannot play. A printer, a camera or an old badge
controller may have no 802.1X supplicant at all, and a port that requires
authentication will refuse it. The usual answer is MAC Authentication Bypass, where
the switch, having heard no EAPOL, falls back to admitting the device by its MAC
address. That is a deliberate, logged exception, and it reopens exactly the weakness
from the port-security capture: a device admitted by its MAC can be impersonated by
copying it. The honest way to hold this is that MAB is a documented compromise for
devices that cannot authenticate, its risk is understood, and it is confined to the
ports that genuinely need it, rather than a control anyone would choose.

Key management runs underneath all of it. The RADIUS server and every switch share
a secret, and a certificate-based EAP method depends on the certificate
infrastructure from topic 34. A device authenticated is only as trustworthy as the
keys and certificates behind the decision, which is why key management is on the
objective next to the mechanism it secures.

</details>

## Prove it

The captures above are the whole of it, from
[`dot1x.sh`](https://github.com/rlwilliamson-dev/azure-resume/blob/main/blog/scripts/topologies/dot1x.sh)
and
[`port-security.sh`](https://github.com/rlwilliamson-dev/azure-resume/blob/main/blog/scripts/topologies/port-security.sh).
The pair is the point: one control checks something copyable and one checks
something proved, and the difference is visible in whether an attacker with the
right MAC or the wrong secret gets on.

**IEEE 802.1X.** The standard is paywalled, but its abstract and scope are free and
worth reading for the phrase port-based network access control, which is the exam's
own framing: the unit being controlled is the port, and its two states are before
and after authentication.

**RFC 3748.** The EAP framework, free, and the clearest statement that EAP is a
carrier for methods rather than a method itself. Read the introduction and note that
the choice of method, and therefore the strength, is separate from the protocol
doing the carrying.

## What trips people up

### 1. Leaving unused ports live

An enabled port with nothing plugged in is a way onto the network. Disabling unused
ports is the cheapest and highest-value control here, and its default is usually the
wrong way round.

### 2. Trusting MAC filtering as access control

A MAC address is public and changeable. Filtering by it stops the casual and is
stepped over in one command, as the capture shows. It is a speed bump, not a lock.

### 3. Confusing the three 802.1X roles

The supplicant asks, the authenticator is the port that holds the door, and the
server decides. The switch does not decide; it relays to the server and enforces the
answer.

### 4. Thinking the identity is what gets checked

The identity is in the clear and is not the secret. The challenge response is what
proves the credential, which is why the failure capture has the right identity and
still fails.

### 5. Forgetting the device that cannot authenticate

Printers and cameras may have no supplicant, and MAB admits them by MAC, which
reopens the impersonation weakness. It is a logged, confined compromise, not a
default to reach for.

### 6. Treating EAP as a single method

EAP is a framework. The method plugged into it decides the strength, so EAP-MD5 and
a certificate-based method are both EAP and are not equally strong.

## Work it through

The meeting room switch, and the order to secure it.

First, turn off the ports nobody is using, because that removes the anonymous
physical access which is the whole risk of a switch in a public room. Two ports are
in use; the other fourteen should be administratively down, and that one step does
more than everything below it.

Then change what the device ships with, because a switch under a table still has a
management interface and a default account, and the console-port lesson from topic
52 says physical access plus a default credential is total access. New credentials,
unused services off.

Then decide what the two live ports should require. If they are for staff devices
that can authenticate, 802.1X makes the port prove a credential before it passes
traffic, and the meeting room becomes a place where a cable achieves nothing without
one. If they must serve a device that cannot authenticate, that is a named exception
on a named port, not a reason to weaken every port.

Then resist the MAC allow list as the answer, because it looks like the control you
want and is the one the capture steps over. If the requirement is really to admit
one device, 802.1X with a certificate does it properly, and MAC filtering is what you
choose only when nothing better is available and you have written down that it is a
speed bump.

## Try it

**Run the port-security lab and change the attacker's MAC yourself.** In
[`port-security.sh`](https://github.com/rlwilliamson-dev/azure-resume/blob/main/blog/scripts/topologies/port-security.sh),
the one command that defeats the filter is `ip link set ... address`. Running it is
what makes "a MAC is not a secret" concrete.

**Break the 802.1X secret and watch the failure.** The bad-password supplicant
config is already in
[`dot1x.sh`](https://github.com/rlwilliamson-dev/azure-resume/blob/main/blog/scripts/topologies/dot1x.sh).
Capturing the exchange shows the identity going through fine and the challenge
response failing, which is the difference from a MAC check in one screen.

**Count the live unused ports on a switch you administer.** Then disable one and
confirm plugging into it does nothing. It is the least interesting control on this
page and the one that closes the most door.

## Check yourself

<details class="qa">
<summary>Why is disabling unused ports the highest-value control on this page?</summary>

Because the access it removes is the easiest kind to abuse: physical, anonymous, and
needing nothing but a cable. A live port with no device is a way onto the network for
anyone who can reach it, and in any room the public can enter that is a real exposure.

It also costs almost nothing, one command per port, which is why the gap between its
value and how often it is skipped is so wide. The default on most switches is every
port on, which is the wrong way round for security.

</details>

<details class="qa">
<summary>Why is filtering a port to a specific MAC address weak?</summary>

Because a MAC address is not a secret. It is sent in the clear in every frame, so an
attacker on the segment can read the permitted address, and changing an interface to
use it is a single command.

The lab shows both halves: the attacker is dropped with its own address and admitted
after cloning the allowed one, with nothing defeated in between. The control checks
something public and copyable, which is why it stops only the device that has not
bothered.

</details>

<details class="qa">
<summary>What does each of the three 802.1X roles do?</summary>

The supplicant is the device asking to join and initiating the authentication. The
authenticator is the switch port, which passes nothing but the authentication
exchange until it is told to open, and then enforces that decision. The
authentication server, usually RADIUS, holds the credentials and makes the decision.

The division matters: the switch does not decide who is allowed, it relays the
exchange to the server and acts on the answer, so one server can back every port in
the building from a single set of credentials.

</details>

<details class="qa">
<summary>In the failed 802.1X capture, the identity is correct. Why does it still fail?</summary>

Because the identity is not the secret being checked. It is sent in the clear so the
server knows which credential to test, and the actual proof is the response to the
server's challenge, computed from the password.

With the wrong password the challenge response is wrong, so the server returns a
failure and the port stays shut, even though every earlier frame, including the
identity, was identical to the successful exchange. That is exactly what MAC
filtering lacks: the right identity alone gets you nowhere.

</details>

<details class="qa">
<summary>A printer cannot do 802.1X. How is it admitted, and what does that cost?</summary>

Usually by MAC Authentication Bypass: the switch, hearing no EAPOL from the device,
falls back to admitting it by its MAC address.

The cost is that it reopens the port-security weakness for that port, because a device
admitted by its MAC can be impersonated by copying the MAC. MAB is a deliberate,
logged exception confined to the ports that need it, understood as a compromise for
devices that cannot authenticate, rather than a control anyone would choose on its
own.

</details>

## References

- [IEEE 802.1X-2020](https://standards.ieee.org/ieee/802.1X/7345/) - IEEE, port-based network access control. The standard is paywalled; its scope defines the exam's framing of a port with a before and after state. Accessed 2026-08-15.
- [RFC 3748](https://www.rfc-editor.org/rfc/rfc3748) - IETF, the EAP framework, and the source of the point that EAP carries a method rather than being one. Free. Accessed 2026-08-15.
- [NIST SP 800-53 Rev. 5](https://csrc.nist.gov/pubs/sp/800/53/r5/upd1/final) - NIST, the controls catalogue, for the hardening and access-control families this page draws on. Free. Accessed 2026-08-15.

**Where the numbers came from.** Every terminal block is from
[`port-security.sh`](https://github.com/rlwilliamson-dev/azure-resume/blob/main/blog/scripts/topologies/port-security.sh)
or
[`dot1x.sh`](https://github.com/rlwilliamson-dev/azure-resume/blob/main/blog/scripts/topologies/dot1x.sh)
run through `netlab.sh`, on the kernel named in each block's header. The MAC
addresses are the lab's own `02:00:00:00:00:xx` range. The 802.1X exchange uses
EAP-MD5, chosen because it needs no certificates and produces a short capture; the
identity `host1` and the account are the lab's, and a production method would be
certificate-based with the same frame sequence.

**If you also work on Linux.** The authenticator here is `hostapd` in wired mode and
the supplicant is `wpa_supplicant`, the same pair that does 802.1X on Linux for real,
and the port-security filter is `nft` in the bridge family. `wpa_cli status` reads
the supplicant's port state, `Authorized` or not, which is the same authorized and
unauthorized the standard defines.
