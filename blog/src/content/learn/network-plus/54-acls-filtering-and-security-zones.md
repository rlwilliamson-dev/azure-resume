---
title: "Access lists, filtering and security zones"
description: "The rule is in the list and traffic still gets through. How a list is evaluated, why order decides everything, what the implicit deny at the bottom is doing, and what a trusted zone actually means once you stop assuming it."
deck: "The rule is in the list and traffic still gets through"
track: "network-plus"
level: "working"
order: 550
objectives:
  - "Explain how an access list is evaluated and why order decides the outcome"
  - "Say what the implicit deny is and where it sits"
  - "Predict which rule a given packet will match"
  - "Distinguish filtering by address and port from filtering by content"
  - "Say what a trusted zone means and why the word is doing less work than it looks"
prerequisites: ["ports-and-the-protocols-that-use-them"]
tags: ["network-plus", "networking", "security", "filtering"]
updated: 2026-08-11
draft: false
examObjectives:
  - exam: "n10-009"
    domain: "4.0"
    objective: "4.3"
sources:
  - title: "RFC 4949, Internet Security Glossary, Version 2"
    url: "https://www.rfc-editor.org/rfc/rfc4949"
    publisher: "IETF"
    accessed: 2026-08-11
    tier: 1
  - title: "NIST SP 800-41 Rev. 1, Guidelines on Firewalls and Firewall Policy"
    url: "https://csrc.nist.gov/pubs/sp/800/41/r1/final"
    publisher: "NIST"
    accessed: 2026-08-11
    tier: 1
  - title: "nft(8)"
    url: "https://www.netfilter.org/projects/nftables/manpage.html"
    publisher: "netfilter project"
    accessed: 2026-08-11
    tier: 1
symptoms:
  - symptom: "A permit rule exists and the traffic it permits is still blocked"
    anchor: "first-match-wins"
  - symptom: "Traffic is blocked and no rule mentions it"
    anchor: "the-rule-nobody-wrote"
---

> **Before you read.** A change request adds a rule permitting one server to
> reach one service. The rule is applied, the engineer confirms it is in the
> list, and the ticket closes.
>
> The traffic is still blocked. Nothing in the log names the new rule.
>
> **The rule exists and does nothing. Why?**

Filtering is the one security mechanism in this track where the concept is
trivial and the failures are all in the arithmetic of ordering. Almost nobody
gets the idea wrong. Nearly everybody, eventually, writes a rule that cannot
fire.

### Some words you will need

<dl class="terms">
<dt>access control list</dt>
<dd>An ordered list of rules, each permitting or denying traffic that matches it.</dd>
<dt>first match wins</dt>
<dd>Evaluation stops at the first rule a packet matches. Everything below is not consulted.</dd>
<dt>implicit deny</dt>
<dd>The rule at the end that nobody writes, denying anything no rule matched.</dd>
<dt>stateful</dt>
<dd>A filter that remembers a connection, so the return traffic is allowed without a rule for it.</dd>
<dt>security zone</dt>
<dd>A named group of interfaces or networks that rules are written between, rather than between addresses.</dd>
<dt>content filtering</dt>
<dd>Deciding by what the traffic is or where it is going by name, rather than by address and port.</dd>
</dl>

## What breaks without this

**You write a rule that cannot fire.** It is in the list, it is syntactically
correct, and a broader rule above it already decided. This is the single most
common filtering fault and it produces no error.

**Traffic is blocked with no rule to point at.** The implicit deny does not
appear in the configuration, so somebody searching for what blocked it finds
nothing and concludes the filter is not the cause.

**A zone gets trusted because of its name.** The word is a label somebody chose,
and treating it as a property of the traffic inside it is how a compromised
laptop becomes a compromised network.

## First match wins

An access list is read from the top. Each rule is tested against the packet, and
the first one that matches decides what happens. Evaluation then stops.

Those last three words are the whole topic. A rule below the one that matched is
not consulted, not partially applied, and not consulted later. It might as well
not be there.

<figure class="learn-figure">
<svg viewBox="0 0 720 300" role="img" aria-labelledby="acl-title" style="width:100%;height:auto;">
<title id="acl-title">One packet tested against a list of rules from the top, matching a broad deny before it ever reaches the specific permit written below it</title>
<g fill="currentColor">
<text x="14" y="20" font-size="11">one packet, tested against the list from the top, and it stops at the first match</text>
<rect x="14" y="40" width="150" height="52" rx="4" fill="currentColor" fill-opacity="0.12" stroke="currentColor" stroke-opacity="0.6"/>
<text x="89" y="60" text-anchor="middle" font-size="10.5">a packet</text>
<text x="89" y="76" text-anchor="middle" font-size="10" fill-opacity="0.85">10.1.0.9 to port 443</text>
<rect x="240" y="44" width="330" height="42" rx="3" fill="currentColor" fill-opacity="0.06" stroke="currentColor" stroke-width="1" stroke-opacity="0.5"/>
<text x="252" y="70" font-size="10.5" fill-opacity="0.7">1</text>
<text x="276" y="70" font-size="10.5" fill="currentColor" fill-opacity="0.9">permit 10.0.0.0/8 to port 80</text>
<rect x="240" y="98" width="330" height="42" rx="3" fill="var(--red)" fill-opacity="0.2" stroke="var(--red)" stroke-width="2"/>
<text x="252" y="124" font-size="10.5" fill-opacity="0.7">2</text>
<text x="276" y="124" font-size="10.5" fill="var(--red)">deny   10.0.0.0/8 to any</text>
<rect x="240" y="152" width="330" height="42" rx="3" fill="currentColor" fill-opacity="0.06" stroke="currentColor" stroke-width="1" stroke-opacity="0.5"/>
<text x="252" y="178" font-size="10.5" fill-opacity="0.7">3</text>
<text x="276" y="178" font-size="10.5" fill="currentColor" fill-opacity="0.9">permit 10.1.0.9  to port 443</text>
<rect x="240" y="206" width="330" height="42" rx="3" fill="currentColor" fill-opacity="0.03" stroke="currentColor" stroke-width="1" stroke-opacity="0.5" stroke-dasharray="5 4"/>
<text x="276" y="232" font-size="10.5" fill="currentColor" fill-opacity="0.9">implicit deny everything else</text>
<path d="M 170 66 H 232" stroke="currentColor" stroke-opacity="0.6" stroke-width="1.8" fill="none"/>
<path d="M 225 61 l 8 5 l -8 5" stroke="currentColor" stroke-opacity="0.6" stroke-width="1.8" fill="none"/>
<text x="200" y="58" text-anchor="middle" font-size="9.5" fill-opacity="0.7">tested</text>
<text x="580" y="70" font-size="10" fill-opacity="0.7">no match, carry on</text>
<text x="580" y="124" font-size="10" fill="var(--red)">match, and stop</text>
<text x="580" y="178" font-size="10" fill-opacity="0.55">never reached</text>
<text x="580" y="232" font-size="10" fill-opacity="0.55">never reached</text>
<text x="14" y="272" font-size="10.5">rule 3 permits exactly this packet and it is below a rule that already denied it,</text>
<text x="14" y="288" font-size="10.5" fill-opacity="0.85">so it will never be consulted. the rule is in the list and does nothing.</text>
</g></svg>
<figcaption>The scenario at the top of this page, drawn. Rule 3 permits exactly this packet: the right address, the right port, written by somebody who checked. It never fires, because rule 2 already denied the whole range this address sits in and evaluation stopped there. Nothing about this is a fault in the equipment or in the rule, and no log line will say the new rule was skipped, because from the filter's point of view nothing was skipped. It matched rule 2, which is what it is supposed to do.</figcaption>
</figure>

**So the fix for the ticket is not another rule, it is moving the one that
exists.** Specific rules go above general ones, always, and that is the ordering
principle worth carrying rather than any particular list.

<details class="deeper">
<summary>If you already maintain lists: why they only ever get longer, and what to do about it</summary>

First match wins has a consequence nobody plans for: the ordering makes editing risky, so
lists grow by accretion at the top and almost never shrink.

The safe way to add a permission is to insert it above whatever is denying it, so new
rules go near the front. The safe way to remove one is to check nothing depended on it,
which requires understanding rules written by people who left, so nothing gets removed.
After a few years the list is hundreds of lines, the first fifty are exceptions to the
next fifty, and nobody can say what would break if any of it went.

Two things keep it tractable. The first is counters, from topic 69: a rule that has
matched nothing in a year is a candidate for removal, and that is a measurement rather
than an argument. The second is a comment on every rule saying why it exists and who asked
for it, because the reason a rule cannot be removed is almost never technical. It is that
nobody knows what it was for.

The structural fix, where the platform allows it, is to express policy in terms of groups
rather than addresses, so that adding a server to a role is a membership change instead of
a new rule. That keeps the number of rules proportional to the number of policies rather
than to the number of machines, which is the difference between a list that stabilises and
one that grows forever.

</details>

## The rule nobody wrote

At the bottom of every list is a rule that denies everything, and on most
platforms it is not printed anywhere.

That is the right default. A filter whose unwritten behaviour was to permit
would fail open, and anything you forgot to consider would be allowed. Failing
closed means a forgotten case is a blocked case, which is a support call rather
than an incident.

It has one practical consequence worth knowing before you meet it. **Traffic
blocked by the implicit deny leaves nothing to search for.** Somebody grepping
the configuration for the address that is being blocked finds no rule mentioning
it, and reasonably concludes the filter is not responsible. The filter is
responsible. It just has nothing to say.

The habit that addresses this is writing the deny yourself at the end of the
list, with logging on it, so that traffic falling through the whole list appears
somewhere. It changes no behaviour and turns an invisible drop into a line you
can find.

<details class="deeper">
<summary>If you already work on networks: why the return traffic works without a rule, and what a stateless filter costs</summary>

Nothing in the list above mentions the reply, and the reply arrives. That is
statefulness, and it is worth understanding as a feature that was added rather
than as how filtering naturally works.

A stateless filter tests each packet on its own, with no memory. Under one of
those, permitting a client to reach a web server means also permitting the web
server to reach the client, on whatever port the client happened to choose, which
is an ephemeral high port picked at random. So the return rule has to permit a
range of tens of thousands of ports from that server, and the filter has genuinely
no way to tell a reply from an unsolicited connection arriving on the same port.

A stateful filter records the connection when the first packet is permitted, so
the reply is matched against that record rather than against the rules. Topic 25's
translation table is the same idea in a different job, and both have the same
consequence: the device is now holding state, that state is finite, and the
failure mode when it fills is not a dropped packet but a device that cannot accept
new connections for anybody.

Two things fall out that are worth knowing. Rules only need to describe the
direction a conversation starts in, which halves the list and removes most of the
opportunity to write something dangerous. And a filter that has been restarted has
forgotten every connection, so established sessions break while new ones are fine,
which is a distinctive symptom worth recognising.

</details>

## Filtering by address, and filtering by name

Everything above filters on what is in the headers: addresses, protocols, ports.
That is cheap, it happens at line rate, and it decides nothing about what the
traffic contains.

**URL filtering** decides by the address being requested, by name. **Content
filtering** decides by what is being carried. Both operate above the layer an
access list works at, and both need something the access list does not: they have
to see inside.

Which sets up the honest limitation. Topic 10 established that a port number
guarantees nothing, and topic 10's capture showed a plaintext password on port
443. The reverse is now the common case: nearly everything is encrypted, so a
device inspecting content sees an encrypted stream and can tell you the
destination name and very little else. Inspecting further means terminating the
encryption and re-encrypting on the far side, which works, is widely deployed,
and means the device is reading everything.

That is a decision with consequences beyond the network, and the useful thing to
carry into the conversation is that it is not a setting. It is a change in who can
read the traffic.

<details class="deeper">
<summary>If you already filter on names: what the device is actually matching on</summary>

Filtering by name is offered by most modern firewalls and the mechanism underneath varies
enough to change what the rule means.

One approach resolves the name periodically and filters on the resulting addresses, so the
rule is really an address rule that updates. It breaks when a service resolves differently
for different clients, which is how most large services are built, and it breaks when the
addresses change faster than the refresh.

Another reads the name out of the traffic itself, from the resolution query or from the
server name in the handshake, which topic 45's panel notes is visible even when everything
else is encrypted. That matches what the client asked for rather than where it went, which
is usually what the policy meant. It also fails when the client resolves elsewhere, or
encrypts its resolution, or uses a mechanism that conceals the name in the handshake.

The practical consequence is that a name-based rule is a best-effort control rather than an
enforcement boundary. It is genuinely useful for steering ordinary traffic and for
producing sensible logs, and it is the wrong thing to rely on for stopping somebody who
does not want to be stopped. Anything that has to hold gets an address-based rule, and the
name-based rule sits alongside it doing the convenient part.

</details>

## Zones, and the word doing less work than it looks

A security zone is a named group of interfaces or networks, and rules are written
between zones rather than between addresses. Inside becomes trusted, outside
becomes untrusted, the part serving the public becomes something in between, and
the rules say what may cross which boundary.

The value is real and it is about maintenance. A rule written between zones keeps
meaning the same thing when a network is renumbered or a site is added, and a list
of a hundred address-based rules does not.

**The trap is in the vocabulary.** Trusted is a label somebody typed. It describes
where traffic came from and makes no claim at all about what it is, and the whole
of the zero trust argument in topic 60 is a response to organisations that forgot
that. A laptop on the trusted network belonging to somebody who opened the wrong
attachment is inside the boundary, and every rule that says the inside may reach
things is now working for the attacker.

So the sentence worth keeping is that a zone describes a location, not a
property.

## Prove it

Nothing here is captured. The lab behind this track can build a filter easily
enough, and a transcript of a rule blocking a packet would demonstrate that
filters filter, which nobody doubts. The interesting content is the ordering, and
that is better read than watched.

**NIST SP 800-41.** Free, and it is the document most firewall policy vocabulary
comes from. Read the section on policy and answer one question: does it recommend
a default of permit or of deny, and what reasoning does it give? The answer is the
implicit deny, argued rather than asserted.

**RFC 4949.** Look up the entries for the terms this page uses. It is worth doing
for the same reason as last topic: the definitions in circulation are looser than
the ones in the glossary.

**Then read a real list, top to bottom, as the device does.** Take any access list
you have access to, pick a packet, and work down the rules until one matches.
Doing that once by hand is what makes first match wins stop being a slogan.

## What trips people up

### 1. Adding a rule instead of moving one

If a broader rule above already matched, a new rule below it changes nothing. The
fix is position, and the principle is that specific goes above general.

### 2. Searching the configuration for what blocked something

The implicit deny is not written down, so nothing mentions the traffic it dropped.
Writing your own deny at the end, with logging, turns that silence into a line.

### 3. Expecting a return rule to be necessary

On a stateful filter the reply is matched against the connection record rather
than against the list, so rules describe the direction a conversation starts in.
On a stateless one you would need a rule permitting tens of thousands of ports.

### 4. Believing content filtering sees content

Nearly everything is encrypted. Without terminating the encryption a device sees a
destination name and a volume of bytes. Terminating it means the device reads
everything, which is a decision rather than a setting.

### 5. Treating a zone name as a property of the traffic

Trusted describes where something came from. A compromised machine on the inside
is inside, and every rule permitting the inside to reach things now works for
whoever compromised it.

### 6. Assuming an access list is stateful because it usually is

Router access lists and firewall policies behave differently in this respect, and
on some platforms both exist. It is worth establishing which you are editing
before writing the rule rather than after.

## Work it through

The ticket, and the order to take it in.

First, stop looking for a fault. The rule is in the list, the syntax is accepted,
the device is healthy. Nothing here is broken, which is why nothing is reporting
anything, and that observation should redirect the whole investigation from what
is wrong towards what is happening.

Then read the list as the device reads it, from the top, with the actual packet in
hand: source address, destination address, protocol, destination port. Work down
until a rule matches. That is the answer, and in this scenario it is a rule two
positions above the new one, denying a range that contains the source.

Then check the position rather than the wording of the new rule. If the matching
rule is above it, the new rule is unreachable, and nothing about editing its
contents will help. Move it above the deny and the ticket closes properly.

Then the thing worth doing while you are in there, which is asking why the broad
deny exists and what else it is silently catching. A rule denying a whole /8 will
have made other rules unreachable too, and this ticket is the only one anybody
noticed. Reading the rules below it as a set frequently turns up two or three
others in the same condition.

And the change that stops the next one, which costs nothing: an explicit deny at
the end of the list with logging on it, so traffic falling all the way through is
visible. That does not fix the ordering problem, but it converts the class of
fault from invisible to searchable.

## Try it

**Take a list and trace one packet by hand.** Top to bottom, first match wins.
Ten minutes, and it makes the ordering rule concrete.

**Look for unreachable rules in something you own.** A specific permit below a
broader deny is the pattern. In a list that has been edited by several people over
years, there is usually at least one.

**Check whether your last deny is written or implicit.** If it is implicit, adding
it explicitly with logging changes no behaviour and makes a whole class of fault
findable.

## Check yourself

<details class="qa">
<summary>A permit rule exists for exactly the traffic being blocked, and the traffic is still blocked. What is happening?</summary>

A rule above it already matched, and evaluation stopped there.

Lists are read from the top and the first match decides. A rule below the one that
matched is not consulted at all, so a specific permit written underneath a broader
deny can never fire. It is in the configuration and it is unreachable.

Nothing reports this, because from the filter's point of view nothing went wrong.
The fix is to move the rule above the one catching it, not to change what it says.

</details>

<details class="qa">
<summary>Why does traffic blocked by the implicit deny leave nothing to find in the configuration?</summary>

Because the rule is not written down. It is the behaviour at the end of the list
rather than an entry in it, so searching for the address that is being dropped
returns nothing and the filter looks innocent.

Writing an explicit deny at the end, with logging, changes no behaviour and turns
that silence into a log line. It is the cheapest change on this page.

</details>

<details class="qa">
<summary>Why does a stateful filter need fewer rules than a stateless one, and what does it cost?</summary>

Because the reply is matched against a record of the connection rather than
against the rules, so you only describe the direction a conversation starts in.

A stateless filter would need a rule permitting the server to reach the client on
whatever ephemeral port the client chose, which in practice means permitting tens
of thousands of ports and being unable to tell a reply from an unsolicited
connection arriving on one of them.

The cost is state. It is finite, and when it fills the device stops accepting new
connections for everybody. A restarted filter has also forgotten every connection,
so established sessions break while new ones work, which is a distinctive symptom.

</details>

<details class="qa">
<summary>What can a content filter actually see on an encrypted connection?</summary>

The destination name, the volume of traffic, and the timing. Not the content.

Seeing further requires terminating the encryption at the filter and re-encrypting
towards the destination, which is deployed widely and works. It also means the
device is reading everything, which is a change in who can read the traffic rather
than a configuration option, and it belongs in a conversation with people outside
the network team.

</details>

<details class="qa">
<summary>What does calling a zone trusted actually assert?</summary>

Where the traffic came from. Nothing about what it is.

The name is a label somebody chose, and it describes a location. A compromised
machine inside the boundary is inside it, and every rule granting the inside
access is now granting that access to whoever compromised the machine.

That gap is what the zero trust argument is a response to, and the sentence worth
keeping is that a zone describes a location rather than a property.

</details>

## References

- [NIST SP 800-41 Rev. 1](https://csrc.nist.gov/pubs/sp/800/41/r1/final) - NIST, guidelines on firewalls and firewall policy, and the source of the default-deny reasoning rather than the assertion. Free. Accessed 2026-08-11.
- [RFC 4949](https://www.rfc-editor.org/rfc/rfc4949) - IETF, the internet security glossary. Free. Accessed 2026-08-11.
- [nft(8)](https://www.netfilter.org/projects/nftables/manpage.html) - netfilter project, for the Linux implementation of everything on this page. Accessed 2026-08-11.

**Where the numbers came from.** There are no measured numbers on this page. The
rules in the figure are illustrative and chosen to show the ordering fault, which
is why they are round and short rather than taken from a device. Nothing is
captured: the lab could build a filter in a minute, and a transcript of a rule
blocking a packet would demonstrate only that filters filter.

**If you also work on Linux.** `nft list ruleset` prints the whole thing in order,
which is the view this page is about, and the policy on a chain is the implicit
deny made explicit: `policy drop` is the behaviour at the end of the list, written
down where you can see it.
