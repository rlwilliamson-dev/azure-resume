---
title: "Attacks on services and people"
description: "The network is fine and the company has been compromised. Denial of service and the amplification that makes it cheap, the rogue services that answer before the real one does, the evil twin, and the human techniques that are on a network exam for a reason."
deck: "The network is fine and the company has been compromised"
track: "network-plus"
level: "working"
order: 580
objectives:
  - "Explain denial of service and the distributed form, and why amplification makes it cheap"
  - "Say what a rogue DHCP server and a rogue access point each achieve"
  - "Explain DNS poisoning and the evil twin as attacks that answer before the real service"
  - "Name the social engineering techniques the exam lists and say why they are here"
  - "Place malware as a category rather than a single thing"
prerequisites: ["how-dns-resolution-works", "wireless-security-and-authentication"]
tags: ["network-plus", "networking", "security", "attacks"]
updated: 2026-08-15
draft: false
examObjectives:
  - exam: "n10-009"
    domain: "4.0"
    objective: "4.2"
sources:
  - title: "RFC 4949, Internet Security Glossary, Version 2"
    url: "https://www.rfc-editor.org/rfc/rfc4949"
    publisher: "IETF"
    accessed: 2026-08-15
    tier: 1
  - title: "Understanding and Responding to Distributed Denial-of-Service Attacks"
    url: "https://www.cisa.gov/resources-tools/resources/understanding-and-responding-distributed-denial-service-attacks"
    publisher: "CISA"
    accessed: 2026-08-15
    tier: 1
  - title: "NIST SP 800-83 Rev. 1, Guide to Malware Incident Prevention and Handling"
    url: "https://csrc.nist.gov/pubs/sp/800/83/r1/final"
    publisher: "NIST"
    accessed: 2026-08-15
    tier: 1
symptoms:
  - symptom: "A service is unreachable under a flood of traffic from many sources"
    anchor: "denial-of-service-and-why-it-is-cheap"
  - symptom: "Clients get their network configuration from an unexpected server"
    anchor: "the-rogue-service-that-answers-first"
---

> **Before you read.** The network is healthy. Every link is up, every switch is
> forwarding, no filter has been touched, and monitoring is green across the
> board. The finance director has just approved a payment to an account that
> belongs to nobody the company has ever done business with.
>
> **Nothing on the network is broken. How was the company attacked through it?**

This topic is the counterweight to the last one. Topic 56 was attacks that abuse a
protocol from the local segment. This is a survey of attacks that come from
further away or from a different direction entirely, and the reason a network exam
includes the human ones is the scenario above: the most effective attack that uses
your network may not touch a single device on it.

### Some words you will need

<dl class="terms">
<dt>denial of service</dt>
<dd>Making a service unavailable, usually by overwhelming it. Distributed when the flood comes from many sources at once.</dd>
<dt>amplification</dt>
<dd>Sending a small request that provokes a large reply, so an attacker's effort is multiplied.</dd>
<dt>reflection</dt>
<dd>Bouncing traffic off a third party by forging the victim's address as the source, so the replies go to the victim.</dd>
<dt>rogue service</dt>
<dd>A DHCP server, DNS resolver or access point that an attacker runs, competing with the real one to answer first.</dd>
<dt>evil twin</dt>
<dd>A rogue access point impersonating a real network's name, so clients join it.</dd>
<dt>social engineering</dt>
<dd>Attacking the person rather than the machine: persuading somebody to do the attacker's work for them.</dd>
</dl>

## What breaks without this

**A service you did not harden is a weapon against someone else.** An open
resolver or any UDP service that answers more than it is asked is a reflector, and
somebody will use it to flood a third party.

**A client trusts the first answer it gets.** DHCP, DNS and wireless association
all take the first usable response, and an attacker who answers faster than the
real service gets to decide the client's gateway, its resolver, or which network
it joined.

**The best-defended network has a person on it.** No filter stops an employee who
was persuaded to act. The human attacks are on this exam because they are the ones
that work against networks that got everything else right.

## Denial of service, and why it is cheap

A denial of service attack makes something unavailable, most often by sending it
more than it can handle. The distributed form uses many sources at once, which
does two things: it supplies more traffic than one connection could, and it
removes the single address you would otherwise just block.

The idea that makes it cheap is amplification, and it is worth drawing because the
asymmetry is the whole point. Some services answer a small question with a large
reply. An attacker sends the small question but forges the source address so it is
the victim's, and the large reply goes to the victim. The attacker spends a little
and the victim receives a lot, multiplied by the amplification factor of whatever
service was used and by the number of reflectors.

<figure class="learn-figure">
<svg viewBox="0 0 720 260" role="img" aria-labelledby="ampl-title" style="width:100%;height:auto;">
<title id="ampl-title">A small forged query sent to many reflecting servers, each answering with a large reply directed at the victim whose address was forged as the source</title>
<g fill="currentColor">
<text x="14" y="20" font-size="11">a small forged question, a large answer, and it goes to the victim not the sender</text>
<rect x="14" y="92" width="120" height="44" rx="4" fill="currentColor" fill-opacity="0.1" stroke="currentColor" stroke-opacity="0.7"/>
<text x="74" y="112" text-anchor="middle" font-size="10.5">attacker</text>
<text x="74" y="128" text-anchor="middle" font-size="9.5" fill-opacity="0.75">source: victim</text>
<rect x="300" y="40" width="130" height="26" rx="3" fill="currentColor" fill-opacity="0.06" stroke="currentColor" stroke-opacity="0.7"/>
<text x="365" y="57" text-anchor="middle" font-size="10">open resolver</text>
<rect x="300" y="106" width="130" height="26" rx="3" fill="currentColor" fill-opacity="0.06" stroke="currentColor" stroke-opacity="0.7"/>
<text x="365" y="123" text-anchor="middle" font-size="10">open resolver</text>
<rect x="300" y="172" width="130" height="26" rx="3" fill="currentColor" fill-opacity="0.06" stroke="currentColor" stroke-opacity="0.7"/>
<text x="365" y="189" text-anchor="middle" font-size="10">open resolver</text>
<g stroke="currentColor" stroke-opacity="0.55" stroke-width="1.2" fill="none">
<path d="M 134 108 L 300 53"/>
<path d="M 134 114 L 300 119"/>
<path d="M 134 120 L 300 185"/>
</g>
<text x="150" y="146" font-size="9.5" fill-opacity="0.7">small queries</text>
<rect x="586" y="92" width="120" height="44" rx="4" fill="var(--red)" fill-opacity="0.18" stroke="var(--red)" stroke-width="2"/>
<text x="646" y="112" text-anchor="middle" font-size="10.5" fill="var(--red)">victim</text>
<text x="646" y="128" text-anchor="middle" font-size="9.5" fill="var(--red)">buried</text>
<g stroke="var(--red)" stroke-width="3" fill="none" stroke-opacity="0.85">
<path d="M 430 53 L 586 104"/>
<path d="M 430 119 L 586 114"/>
<path d="M 430 185 L 586 124"/>
</g>
<text x="470" y="235" font-size="9.5" fill="var(--red)">large replies, all to the forged source</text>
</g></svg>
<figcaption>The attacker sends each reflector a small query with the victim's address forged as the source. Each reflector answers the way it is designed to, sending a much larger reply to the address it was told to, which is the victim. The thin lines are what the attacker sends; the thick red lines are what the victim receives. One attacker with a modest connection becomes a flood, multiplied by the size of each answer and by how many reflectors are used, and every packet arriving at the victim comes from a legitimate server answering a legitimate-looking request.</figcaption>
</figure>

<details class="deeper">
<summary>If you already work on networks: why UDP services get abused and what the amplification factor really measures</summary>

Reflection needs a forged source address to work, and forging a source address is
only useful if the protocol answers without checking that the sender is really
there. That is the dividing line between the protocols that get abused and the ones
that do not, and it runs straight down the middle of the transport layer.

TCP's handshake, from topic 09, is a check that the sender is reachable at the
address it claims. The server's reply to a connection attempt goes to the source
address, and the connection does not proceed until that address answers. Forge the
source and the handshake never completes, so there is nothing to reflect. UDP has
no handshake. A UDP service receives a request and sends an answer to whatever
source address is on it, with no step that would notice the address is forged. So
the reflectors are all UDP services: DNS, NTP, and a handful of others that were
designed to answer a stranger quickly.

The amplification factor is the ratio of the reply size to the request size, and it
is what turns reflection from a nuisance into an attack. A service that answers a
60-byte request with a 60-byte reply is a reflector with a factor of one, which
buys the attacker nothing but a disguise. A service that answers a small request
with a reply dozens of times larger is a weapon, because the attacker's own
bandwidth is multiplied by that factor before it ever reaches the victim. This is
the argument for two specific pieces of hygiene: do not run an open resolver, and
do not run any UDP service that answers the whole internet, because a service that
answers strangers generously is ammunition whether or not you are the target.

</details>

## The rogue service that answers first

Several of the services a client depends on have a property in common: the client
takes the first usable answer it gets. That is efficient and it is exploitable,
because an attacker who answers faster than the real service gets to decide what
the client believes.

A **rogue DHCP server** answers a client's request for configuration before the
real one does, and configuration is where the gateway and the resolver are set. A
client that took its settings from the rogue has an attacker for a gateway, which
is an on-path position handed over at boot without any of topic 56's effort.

**DNS poisoning and spoofing** put a false answer where a name is resolved, so a
correct-looking name leads to the attacker's address. It can happen at a resolver's
cache, which poisons the answer for everyone who uses it, or on the path to a
client that does not validate the answer, which is one of the things DNSSEC in topic
47 exists to prevent.

A **rogue access point** is an access point the organisation did not sanction,
offering a way onto the network that bypasses its controls. The **evil twin** is
the sharp version: a rogue access point using the name of a network people trust,
so their devices join it, sometimes automatically, and their traffic goes through
the attacker.

The thread through all of these is the on-path position. A rogue DHCP server, a
poisoned DNS answer and an evil twin are three routes to the same place, which is
between the client and the internet, reading and able to alter what passes. The
last topic's attacks reached that position from the local segment; these reach it
by answering a question faster than the legitimate service.

<details class="deeper">
<summary>If you already defend these: why the switch is the right place to stop it</summary>

Every service in this category shares a weakness that the client cannot fix, and that is
what decides where the defence goes.

The client is behaving correctly. It asked, something answered, and it has no way to know
whether the answer came from the machine it was supposed to. There is no credential to
check and no name to validate, because these exchanges happen before any of that exists.
So a defence on the client is not available.

The switch, on the other hand, knows something the client does not: which port the
legitimate server is on. A switch configured to accept server replies only from the ports
where servers actually live discards the rogue answers before any client sees them, and
the same idea covers the IPv6 equivalent from topic 43's panel, where rogue router
advertisements are the problem and the switch is again the only place with the context to
judge.

Which is a useful general shape. When a protocol has no way to authenticate an answer, the
defence goes to the device that knows the topology, because topology is the only thing
distinguishing the real server from the impostor. That is also why these protections are
per-port configuration rather than a rule somewhere central: the knowledge is about which
cable, and only the switch has it.

</details>

## Attacks on people

Now the scenario at the top, where the network did nothing wrong.

Social engineering attacks the person. The exam names a set of them and the useful
way to hold them is by the lever each one pulls. **Phishing** is the broad one: a
message that impersonates something trusted to get a click, a credential or a
payment, with **spear phishing** aimed at a named person and **whaling** aimed at
an executive whose approval moves money. **Vishing** and **smishing** are the same
by voice and by text message. **Pretexting** is inventing a scenario that makes the
request seem reasonable, which is the clipboard and high-visibility jacket from
topic 52 in written form. **Tailgating** and **piggybacking** are the physical
entry from that topic. **Dumpster diving** and **shoulder surfing** collect what
was not protected because nobody thought of paper and glances as part of the attack
surface.

These are on a network exam for the reason the scenario shows. The payment to the
unknown account did not require a single packet to be intercepted. Somebody was
persuaded, through a channel the network does not police, and the network was the
delivery mechanism and not the target. A control that stops this is a person who
verifies a payment change through a second channel, which is not something you
configure on a switch.

**Malware** is the last item and it is a category, not a technique. Viruses,
worms, trojans, ransomware and the rest differ by how they spread and what they do,
and for this exam the network-relevant distinction is that some of them move across
the network on their own. A worm scans and infects without anybody clicking, which
makes it a network event and ties it back to the segmentation topic: what a worm
can reach is its segment plus what policy allows out, which is the containment
argument arriving from yet another direction.

<details class="deeper">
<summary>If you already run awareness training: why the technical controls matter more than the training</summary>

Training reduces the click rate and it does not get it to zero, and designs that depend on
it getting to zero fail.

The arithmetic is unforgiving. A convincing message sent to a thousand people needs one
person having a bad morning, and across a year of attempts that person exists. Training
moves the rate rather than the outcome, which means the useful question is not how to stop
everybody clicking but what happens when somebody does.

That reframes the spend. A phishable second factor means a click leads to a compromised
account, and a factor bound to the site, from topic 35's panel, means the same click leads
to nothing. Least privilege means the compromised account reaches what one person needed
rather than what the department has accumulated. Segmentation means the machine that ran
the attachment reaches a fraction of the estate. None of those depend on anybody behaving
well under pressure.

Where training genuinely earns its place is in reporting rather than in prevention. An
organisation where people report a suspicious message quickly, without fear of looking
foolish, finds out about a campaign while it is running. That is a cultural outcome rather
than a knowledge one, and it is undermined immediately by any programme that punishes
people who click.

</details>

## Prove it

Nothing here is a lab, because demonstrating these attacks means attacking
somebody, and the useful skill is recognising them and knowing which control
answers each. All three documents below are free.

**CISA on distributed denial of service.** Read the guidance and answer one
question: what does it recommend you do about services that can be used for
reflection, whether or not you are a target? The answer is the open-resolver
hygiene from the panel above, argued by an incident-response body rather than
asserted here.

**RFC 4949.** Look up denial of service, on-path attack, and social engineering.
The glossary definitions are tighter than the ones in circulation, and the exam's
vocabulary is closer to these than to any vendor's.

**NIST SP 800-83.** The malware guide, and the clearest free statement of why
malware is a category with different propagation methods rather than one thing. Read
the section on how malware spreads and note which methods are network-borne, because
those are the ones segmentation contains.

## What trips people up

### 1. Thinking distributed denial of service is just more traffic

The distribution also removes the single source you would block, and amplification
means the traffic is far larger than what the attacker sent. It is not one hose
turned up, it is many legitimate servers turned against a victim.

### 2. Believing you are safe from reflection because you are not a target

An open resolver or a chatty UDP service on your network is ammunition against
somebody else. The hygiene is to not answer strangers generously, target or not.

### 3. Treating a rogue DHCP server as a configuration mishap

It is an on-path attack. Whoever sets the client's gateway and resolver decides
where its traffic goes, and a rogue server that answers first sets both.

### 4. Assuming an evil twin needs a weak password to work

It needs a trusted name. Devices join a network they recognise, sometimes without
asking, and the attacker's access point is now between the user and everything.

### 5. Thinking social engineering is off-topic on a network exam

It is the attack that beats a well-run network, because it does not touch the
network's controls. The exam includes it because ignoring it leaves the most
effective attacks unexamined.

### 6. Treating malware as one thing

It is a category. The network-relevant question is how a given piece spreads, and
the ones that move on their own are the reason segmentation limits blast radius.

## Work it through

The fraudulent payment, reasoned out.

First, separate the network from the incident. Every device is healthy and no
control was bypassed, which is not a contradiction, because this attack did not
target a device. Ruling the network out is progress, not a dead end: it tells you
the delivery was through a person.

Then find the channel. A payment to a new account almost always traces to a
message that impersonated a trusted party, by email, voice or text, persuading
somebody that the change was legitimate. That is phishing, and its more targeted
forms, and the network carried it without any way to know it was hostile, because
nothing about the message was technically wrong.

Then name the control that would have stopped it, which is a human process rather
than a device setting: verifying a change to payment details through a separate
channel, out of band, before acting. The network's job here is limited, and
pretending a filter could have caught it is how the actual defence gets left
unbuilt.

Then check the network for the attacks that do use it, because a social attack is
often the way in and a technical one is the way onward. A rogue DHCP server, a
poisoned resolver or an evil twin would each leave a trace, and the segmentation
that contains a worm is the thing that limits how far the intrusion spread once it
had a foothold.

## Try it

**Check whether anything on your network is an open reflector.** Ask whether any
resolver you run answers queries from outside your network, and whether any UDP
service is reachable from the internet that has no reason to be. Each one is
ammunition, and finding it is the hygiene the panel argues for.

**Watch a network for a second DHCP server.** On a network you administer, a rogue
DHCP server shows up as clients getting a gateway or resolver you did not
configure. Knowing what your real one hands out is what lets you notice a second
one.

**Read one real phishing email as an attacker wrote it.** Note that nothing in it
is technically malformed. That is why the network passed it, and why the defence is
a person and a process rather than a rule.

## Check yourself

<details class="qa">
<summary>Why does amplification make a denial of service attack so much more effective?</summary>

Because it multiplies the attacker's traffic before it reaches the victim. The
attacker sends a small request to a service that answers with a much larger reply,
and forges the victim's address as the source so the large reply goes to the victim.

The attacker spends a little bandwidth and the victim receives a lot, scaled by the
ratio of reply size to request size and by the number of reflectors used. Every
packet the victim receives comes from a legitimate server answering what looks like
a legitimate request, which is also why it is hard to filter.

</details>

<details class="qa">
<summary>Why are the services abused for reflection almost always UDP?</summary>

Because reflection needs a forged source address, and forging one only works
against a protocol that answers without checking the sender is really there. TCP's
handshake is exactly that check: the reply goes to the claimed source and the
connection stalls if that address does not answer, so a forged source has nothing
to reflect.

UDP has no handshake. It answers whatever source address is on the request, with no
step that would notice a forgery, so a UDP service that answers strangers is a
reflector. DNS and NTP are the common examples.

</details>

<details class="qa">
<summary>How does a rogue DHCP server become an on-path attack?</summary>

DHCP hands a client its gateway and its resolver. A client takes the first usable
answer to its request, so a rogue server that replies before the real one sets
both, and now the client sends its traffic to an address the attacker chose and
resolves names using a resolver the attacker controls.

That is the same on-path position topic 56's attacks worked to reach, obtained here
at boot by answering first, without touching the switch or the address resolution
cache.

</details>

<details class="qa">
<summary>What distinguishes an evil twin from an ordinary rogue access point?</summary>

A rogue access point is any unsanctioned one offering a way onto or around the
network. An evil twin is a rogue access point that uses the name of a network people
already trust, so their devices join it, sometimes automatically, believing it is
the real one.

The impersonated name is the whole trick. It does not need to break any encryption;
it needs a client to choose it, and a device configured to reconnect to a known
network name will often do that without asking.

</details>

<details class="qa">
<summary>Why is social engineering on a network exam when it does not attack the network?</summary>

Because it is the attack that succeeds against a network which has everything else
right. No filter, segment or encryption stops a person who was persuaded to act, and
the network is only the channel the message travelled through.

The exam includes it so that the most effective category of attack is not left out
of a security domain, and so that the answer to it is understood to be a human
process, such as verifying a request through a second channel, rather than a device
control.

</details>

## References

- [RFC 4949](https://www.rfc-editor.org/rfc/rfc4949) - IETF, the internet security glossary, for denial of service, on-path attack, social engineering and the rest of this page's vocabulary. Free. Accessed 2026-08-15.
- [CISA, understanding and responding to DDoS](https://www.cisa.gov/resources-tools/resources/understanding-and-responding-distributed-denial-service-attacks) - CISA, on the distributed form and on the reflector hygiene the panel relies on. Free. Accessed 2026-08-15.
- [NIST SP 800-83 Rev. 1](https://csrc.nist.gov/pubs/sp/800/83/r1/final) - NIST, the malware guide and the source of the propagation-method distinction. Free. Accessed 2026-08-15.

**Where the numbers came from.** There are no measured numbers on this page.
Nothing here is captured, because every attack on it is one you would have to
commit against somebody to demonstrate, and the useful skill is recognition. The
figure is illustrative: it shows the reflection asymmetry with three reflectors and
one victim, chosen to make the direction of the large replies clear rather than to
represent a particular attack's scale.

**If you also work on Linux.** The reflector hygiene has a concrete Linux form:
a resolver such as BIND or Unbound should have its `allow-query` or `access-control`
limited to your own networks rather than left open, and a UDP service exposed to the
internet should be behind the same default-deny filter as everything else. Neither
is a special anti-DDoS feature; both are the ordinary rule that a service should
answer only who it is meant to.
