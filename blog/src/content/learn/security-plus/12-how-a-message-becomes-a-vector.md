---
title: "How a message becomes a vector"
description: "Why the delivery mechanism and the payload are separate questions, what makes an image a vector, why a removable device still works, and the one habit that defeats every channel in this objective."
deck: "An invoice arrives as a PDF from a supplier you actually use, with the right reference number on it"
track: "security-plus"
level: "intro"
order: 130
objectives:
  - "Separate the delivery vector from the payload it carries"
  - "Name the message-based vectors and say what each one bypasses"
  - "Explain what makes an image or a file a vector"
  - "Say why removable devices still work"
  - "Identify the vector no technical control reaches"
  - "State the verification habit that defeats every channel"
prerequisites: ["threat-actors-and-what-they-want"]
tags: ["security-plus", "security", "threats"]
updated: 2026-08-26
draft: false
examObjectives:
  - exam: "sy0-701"
    domain: "2.0"
    objective: "2.2"
sources:
  - title: "SP 800-177 Rev. 1, Trustworthy Email"
    url: "https://csrc.nist.gov/pubs/sp/800/177/r1/final"
    publisher: "NIST"
    accessed: 2026-08-26
    tier: 1
  - title: "SP 800-83 Rev. 1, Guide to Malware Incident Prevention and Handling"
    url: "https://csrc.nist.gov/pubs/sp/800/83/r1/final"
    publisher: "NIST"
    accessed: 2026-08-26
    tier: 1
  - title: "RFC 2046, MIME Part Two: Media Types"
    url: "https://www.rfc-editor.org/rfc/rfc2046.html"
    publisher: "IETF"
    accessed: 2026-08-26
    tier: 1
  - title: "MITRE ATT&CK, Initial Access"
    url: "https://attack.mitre.org/tactics/TA0001/"
    publisher: "MITRE"
    accessed: 2026-08-26
    tier: 1
symptoms:
  - symptom: "The mail gateway is well configured and something arrived anyway"
    anchor: "one-payload-five-ways-in"
  - symptom: "A request was acted on because it named the right reference number"
    anchor: "the-habit-that-defeats-all-five"
---

> **Before you read.** An invoice arrives as a PDF. It is from a supplier you
> genuinely use, it quotes a real reference number from a real project, the amount
> is plausible, and the bank details are new.
>
> **Which part of that is the attack?**

The bank details. Everything else is true, which is why it works, and it is why
looking for something wrong in the message is the wrong instinct. This topic is
about the delivery, and the delivery and the payload are separate questions that
get answered as one.

### Some words you will need

<dl class="terms">
<dt>vector</dt>
<dd>How something reaches you. The route rather than the thing.</dd>
<dt>payload</dt>
<dd>What arrives. Malicious code, a link, or simply a request that costs you money.</dd>
<dt>message-based</dt>
<dd>Delivered as a message a person reads: email, text, chat.</dd>
<dt>file-based</dt>
<dd>The payload is inside a file's structure rather than in what the file appears to be.</dd>
<dt>image-based</dt>
<dd>The file happens to be an image, which is a file format with a parser like any other.</dd>
<dt>removable device</dt>
<dd>Something plugged in. A vector because it crosses the network boundary without using the network.</dd>
<dt>smishing</dt>
<dd>The same technique delivered by text message.</dd>
<dt>vishing</dt>
<dd>The same technique delivered by voice.</dd>
</dl>

## What breaks without this

**Defences are built for one channel.** The mail gateway is excellent, and the
request arrives by text message to a personal phone.

**A file type is trusted because of what it looks like.** An image is treated as
inert data, and the code that parses it is software with bugs like any other.

**Removable media is assumed to be a solved problem.** It is not blocked, nobody
has checked in years, and it remains the one route that touches no network control
at all.

**The payload is analysed and the delivery is not.** How it arrived tells you which
control was absent, and that is the thing that will be absent again next week.

## One payload, five ways in

The same request can arrive by any channel, and the channel decides which control
had a chance.

<figure class="learn-figure">
<svg viewBox="0 0 720 292" role="img" aria-labelledby="vec-title" style="width:100%;height:auto;">
<title id="vec-title">One request delivered by five vectors, with the control that stops each and the two that no technical control reaches</title>
<g fill="currentColor">
<text x="14" y="20" font-size="11">the same request, five ways in, and what stops each one</text>
<text x="248" y="44" font-size="9" fill-opacity="0.7">the control that would stop it</text>
<text x="470" y="44" font-size="9" fill-opacity="0.7">why</text>
<rect x="14" y="54" width="216" height="28" rx="4" fill="currentColor" fill-opacity="0.05" stroke="currentColor" stroke-opacity="0.5" stroke-width="1.1"/>
<text x="26" y="72" font-size="8.5">email attachment</text>
<rect x="242" y="54" width="212" height="28" rx="4" fill="var(--accent)" fill-opacity="0.14" stroke="var(--accent)" stroke-opacity="0.7" stroke-width="1.3"/>
<text x="254" y="72" font-size="8">the mail gateway</text>
<text x="470" y="72" font-size="8" fill-opacity="0.8">strong, and the route most people expect</text>
<rect x="14" y="90" width="216" height="28" rx="4" fill="currentColor" fill-opacity="0.05" stroke="currentColor" stroke-opacity="0.5" stroke-width="1.1"/>
<text x="26" y="108" font-size="8.5">a link in a text message</text>
<rect x="242" y="90" width="212" height="28" rx="4" fill="var(--red)" fill-opacity="0.14" stroke="var(--red)" stroke-opacity="0.7" stroke-width="1.3"/>
<text x="254" y="108" font-size="8">nothing you run</text>
<text x="470" y="108" font-size="8" fill-opacity="0.8">the phone is not on your network</text>
<rect x="14" y="126" width="216" height="28" rx="4" fill="currentColor" fill-opacity="0.05" stroke="currentColor" stroke-opacity="0.5" stroke-width="1.1"/>
<text x="26" y="144" font-size="8.5">an image on a page</text>
<rect x="242" y="126" width="212" height="28" rx="4" fill="var(--accent)" fill-opacity="0.14" stroke="var(--accent)" stroke-opacity="0.7" stroke-width="1.3"/>
<text x="254" y="144" font-size="8">the web filter, if categorised</text>
<text x="470" y="144" font-size="8" fill-opacity="0.8">the payload is in the file format</text>
<rect x="14" y="162" width="216" height="28" rx="4" fill="currentColor" fill-opacity="0.05" stroke="currentColor" stroke-opacity="0.5" stroke-width="1.1"/>
<text x="26" y="180" font-size="8.5">a voice call</text>
<rect x="242" y="162" width="212" height="28" rx="4" fill="var(--red)" fill-opacity="0.14" stroke="var(--red)" stroke-opacity="0.7" stroke-width="1.3"/>
<text x="254" y="180" font-size="8">nothing technical at all</text>
<text x="470" y="180" font-size="8" fill-opacity="0.8">there is no file and no link</text>
<rect x="14" y="198" width="216" height="28" rx="4" fill="currentColor" fill-opacity="0.05" stroke="currentColor" stroke-opacity="0.5" stroke-width="1.1"/>
<text x="26" y="216" font-size="8.5">a USB stick</text>
<rect x="242" y="198" width="212" height="28" rx="4" fill="var(--accent)" fill-opacity="0.14" stroke="var(--accent)" stroke-opacity="0.7" stroke-width="1.3"/>
<text x="254" y="216" font-size="8">device policy on the endpoint</text>
<text x="470" y="216" font-size="8" fill-opacity="0.8">no network control sees it</text>
<text x="14" y="256" font-size="10" fill-opacity="0.85">one verification habit defeats all five, and it is not a product</text>
<text x="14" y="278" font-size="9" fill-opacity="0.7">contact the person through a channel you already had, rather than the one the request arrived on</text>
</g></svg>
<figcaption>One request delivered five ways. The mail gateway is a genuinely strong control and it only sees the first row. The second row arrives on a device that is not on your network, sent through a carrier you have no relationship with, to a number the person gave out years ago. The fourth row involves no file, no link and no attachment, so there is nothing to inspect. The fifth crosses the boundary physically. Two of the five are accented because no control you operate is in their path at all, and the reason to draw this is that a defence built on the first row will be described as comprehensive by whoever built it.</figcaption>
</figure>

**Email** is the most defended channel and remains the most used one, which tells
you something about volume rather than about effectiveness. Everything from block
E applies: authentication records, a gateway, link rewriting, attachment
inspection.

**Text messages and instant messaging** bypass all of it. The message arrives on a
personal device, through a carrier, into an application your organisation does not
control. There is no gateway. The mitigation is the person.

**Voice** removes every technical artefact. No file, no link, no header to
examine, no record unless somebody makes one. It is also the channel where
urgency and authority work best, because a voice conveys both in a way text does
not, and where a synthesised voice is now a practical concern rather than a
theoretical one.

**Removable devices** cross the boundary without touching the network. That is the
whole of why they persist as a vector: every control in a network diagram is
irrelevant to a USB stick, and the only things in its path are on the endpoint.

<details class="predict">
<summary>An organisation blocks executable attachments, rewrites links, and filters web categories. Predict which of the five vectors it has addressed.</summary>

**One and a half.** Email attachments, mostly, and the link half of the web
vector.

Work through what each control actually inspects. Attachment blocking sees files
arriving by mail, which is the first row and nothing else. Link rewriting sees
links in mail, and follows them at click time, which is genuinely valuable and
still confined to the mail channel. Web category filtering sees requests that go
through the proxy, which excludes anything on a phone, on a home network, or
addressed to an address rather than a name.

What is untouched: a text message to a personal phone, a voice call, a file
arriving through a chat application the organisation permits, and anything on a
USB stick.

That is not an argument against the controls, all three of which are worth having.
It is an argument against describing the result as coverage, because the word
implies a proportion of a whole and the whole here is five channels rather than
one.

The useful reframing when somebody asks whether phishing is handled: ask which
channel. The answer for email is usually reassuring and the answer for the rest is
usually that nothing technical is in the path, which is a true statement that
changes where the next investment goes.

</details>

<details class="deeper">
<summary>If you defend the mail channel: what a gateway sees, and the three things that arrive anyway</summary>

A mail gateway is one of the better-value controls in security and it is worth
being precise about its edges, because it is usually the control people mean when
they say phishing is covered.

What it does well: known-bad attachments, executable content, links to known-bad
destinations, messages failing authentication checks, and bulk campaigns whose
volume gives them away. That is a large share of what arrives and it is why the
control is universal.

Three things arrive anyway.

**The message with no payload.** An invoice with changed bank details contains no
malicious file, no link, and nothing technically wrong. Every check passes because
there is nothing to fail. The gateway is not malfunctioning; the message is a
business request and deciding whether a business request is legitimate is not a
thing a gateway can do.

**The message from a real compromised account.** Authentication passes because the
sender genuinely is who they say. The account belongs to a supplier who was
compromised last week, the thread is a real thread, and the reply is in context.
This is the hardest case and it defeats every sender-based check by design.

**The delayed payload.** A link that resolves to something harmless at delivery
and something else an hour later. Link rewriting addresses this specifically, by
moving the check to click time, which is the reason that feature exists and the
reason it is worth the privacy consideration it carries.

The pattern across all three is the same: gateways check properties of the
message, and the attacks that persist are the ones whose properties are all
correct. That is not a gap to be closed by a better gateway, which is why the
answer keeps turning out to be a verification habit rather than a product.

</details>

## What makes an image a vector

An image feels like inert data, and the intuition is wrong for a specific and
generalisable reason.

**An image is a file format, and a file format is parsed by code.** That code
reads a header, allocates buffers based on values in the file, decodes compressed
data, and handles dozens of variants and edge cases. It is software, it has bugs
like all software, and the input it processes comes from outside.

So an image-based vector is not usually about hiding something in the picture. It
is about the picture being malformed in a way that makes the decoder do something
its author did not intend, which is the same idea as everything in the software
vulnerabilities topic later in this block.

Two related points worth carrying.

**The file type is not what the extension says.** A file's contents determine what
parses it, and a control that decides by extension is deciding on a label the
sender chose. This is why file inspection looks at content rather than at names.

**Documents are programs more often than people think.** A spreadsheet with macros
is executable content wearing a document's clothes, and the reason macro execution
is disabled by default everywhere is that this was learned expensively.

<details class="deeper">
<summary>If you are deciding what to block: why blocking file types is harder than it looks</summary>

Blocking dangerous file types is the obvious control and it degrades in a
predictable way, which is worth understanding before implementing it.

The first problem is that the dangerous set is large and open-ended. Executables
are obvious. Scripts are obvious once you think about it. Then shortcut files,
installer packages, disk images, help files, and every archive format, because an
archive is a container for anything. The list grows every time somebody finds a
new type the operating system will execute, and it grows faster than the blocklist
is updated.

The second problem is that archives nest. A blocked type inside a zip inside a
password-protected zip is a common pattern precisely because inspection stops
somewhere, and where it stops is a configuration nobody revisits.

The third is business impact, and it is the one that decides the outcome. Blocking
a type that a supplier uses to send you something legitimate produces a complaint
within days, an exception within a week, and an exception list that grows into the
policy.

What works better is inverting it. An allow list of the types the business
actually exchanges, which is a short list somebody can enumerate, with everything
else quarantined for review rather than blocked outright. That is more work to run
and it fails in the safe direction, and it does not grow stale in the way a
blocklist does.

The related discipline is to decide on content rather than on extension, since an
extension is a label chosen by the sender, and to treat an archive that cannot be
inspected as an unknown type rather than as an acceptable one.

</details>

## The habit that defeats all five

The figure has one line at the bottom that does more than any row above it.

**Verify through a channel the request did not arrive on.** The invoice arrived by
email, so telephone the supplier on the number you already had, not the one in the
message. The urgent request came from the finance director, so walk to their desk
or call the number in the directory. The text message says it is from the bank, so
use the number on the card.

That single habit defeats all five rows, because every one of them depends on the
recipient answering in the channel the attacker controls. It costs a minute, it
requires no product, and it fails only when somebody is in enough of a hurry to
skip it, which is why urgency appears in every one of these messages.

**The organisational version is a rule rather than a habit.** Bank detail changes
are verified by an outbound call to a stored number, always, by policy, with no
exception for urgency. That converts an individual judgement made under pressure
into a process step, which is the whole of what makes it reliable.

<details class="deeper">
<summary>If you own the process: why the exception for urgency is the vulnerability</summary>

Every verification policy contains, somewhere, a provision for when there is no
time. It is written by reasonable people anticipating a real situation, and it is
the thing the attack is designed to invoke.

Read any of these messages and count the urgency markers. The payment is late. The
supplier will stop delivery. The director is in a meeting and cannot take calls.
It has to be today. None of that is incidental colour; it is the payload, and its
function is to reach the clause in your process that says the check may be skipped.

The design principle that follows is uncomfortable and short: the verification
step should have no urgency exception, and the process should instead be fast
enough that urgency does not create pressure to skip it. A callback to a stored
number takes ninety seconds. If ninety seconds is genuinely unaffordable, the
problem is a business process with no slack in it, and that is worth fixing for
reasons beyond fraud.

The second design principle is about who can invoke the exception. Where an
override genuinely must exist, it should require somebody other than the person
under pressure, because the person being rushed is precisely the person whose
judgement the attack has already engaged.

And the third, which costs nothing: make it safe to be wrong. A culture where
telephoning the finance director to check an email is seen as wasting their time
produces people who do not telephone. Saying out loud, from the top, that checking
is always correct even when the answer is yes, is the cheapest control in this
entire topic and the one most organisations never explicitly do.

</details>
<details class="predict">
<summary>A finance team is trained annually on phishing and the pass rate is high. Predict what the next successful attack looks like.</summary>

**Nothing like the training.** The exercises teach people to spot the markers of a
bad message, and the message that succeeds will not have them.

Training is built around what a bad message looks like: misspellings, an odd
sender address, a generic greeting, a link that does not go where it claims.
Those markers are real and they characterise bulk campaigns, which is the volume
case and the easy case.

The one that succeeds arrives from a real supplier's real compromised account, on
a thread that already existed, referring to a project that is real, written by
somebody who read the previous messages. There is no misspelling. The address is
correct because it is the correct address. The only thing wrong is one field, and
it is a field that changes legitimately from time to time.

So the training tested the ability to detect anomalies in a message, and the
attack that works contains none. That is not an argument against the training,
which raises the floor against the common case. It is an argument against reading
a high pass rate as protection against the targeted case, because the two are
measuring different things.

What actually addresses the targeted case is the verification step below, applied
by process rather than by judgement, precisely because judgement is what the
message is designed to satisfy.

</details>


## Prove it

**Work it out.** Take the invoice from the top of this page. List every check a
technical control could perform on it, and mark which would fail. You should find
that none of them would, because nothing in the message is technically wrong.

**Look it up.** Open the ATT&CK initial access tactic and count the techniques
that involve a person doing something. The proportion is the argument for why this
objective is about delivery rather than about code.

**Ask about the second channel.** For your own organisation, find out what the
process is when a supplier's bank details change. If the answer is that somebody
checks the email looks right, that is the finding.

## What trips people up

### 1. Treating the payload and the vector as one question

The payload tells you what would have happened. The vector tells you which control
was absent, and that is the one that will be absent again.

### 2. Describing email defences as phishing coverage

They address one channel of five. Text, voice, chat and removable media have no
gateway in their path at all.

### 3. Assuming an image is inert

It is a file format parsed by code, and the code has bugs. The vector is usually a
malformed file rather than something hidden in the picture.

### 4. Deciding on the extension

The extension is a label the sender chose. What parses a file is determined by its
contents, which is why inspection has to look at those.

### 5. Believing removable media is solved

It crosses the boundary without touching the network, so every network control is
irrelevant to it, and the only things in its path are on the endpoint.

### 6. Writing an urgency exception into the verification rule

Urgency is the payload. A clause permitting the check to be skipped when there is
no time is the clause the message is written to invoke.

## Work it through

Finance receives an invoice from a real supplier, on a real thread, with correct
details and new bank information. The mail gateway passed it, authentication
passed, and there is no attachment.

**The tempting response is to improve the gateway.** Something got through, so
tune the filter, add a rule, buy an additional inspection layer. None of it would
have helped: the message was genuine mail from a genuinely compromised account,
containing no malicious content, making a business request.

**The response that works is a process rule.** Any change to payment details is
verified by an outbound call to the number already on file, before the change is
made, with no exception. That addresses the actual mechanism, it costs ninety
seconds per occurrence, and it works regardless of which of the five channels the
request arrives on.

**Then the second question is the supplier.** Their account is compromised and
they may not know. Telling them is the thing that stops the next twelve
organisations receiving the same message, and it is the step people skip because
it is somebody else's problem.

**What this rejects is a technical answer to a business-process failure.** The
gateway did its job. The gap was that a payment detail could change on the
strength of a message, and no filter closes that.

The residual is worth stating: the rule protects payments. The same compromised
account can send a request that is not about payment at all, and the general
version of the control is the verification habit rather than the specific policy.
Writing one rule for bank details and none for anything else is a common and
partial outcome.

## Try it

**Find your own second channel.** For the three people most likely to be
impersonated in your organisation, check whether you have a phone number for them
that did not come from an email signature.

**Look at a file's actual type.** Take any document and inspect its first few
bytes. Compare what they say with what the extension claims.

**Count the channels you defend.** List the five vectors and, for each, name the
control in its path. Two of them will have none, and knowing which two is the
point of the exercise.

**Ask what happens with no time.** Read your organisation's verification process
and find the urgency clause. It is nearly always there.

## Check yourself

<details class="qa">
<summary>Why are the vector and the payload separate questions?</summary>

Because they tell you different things. The payload describes what would have
happened if it had run. The vector describes how it arrived, and therefore which
control was absent from that path.

The second is the more actionable, because the same gap will be there next week.
An organisation that analyses payloads and never asks about delivery keeps fixing
the thing that already happened.

</details>

<details class="qa">
<summary>An organisation blocks executable attachments and rewrites links. Which vectors remain untouched?</summary>

Text and instant messages to personal devices, voice calls, files arriving through
permitted chat applications, and removable media. Web filtering also misses
anything on a phone, on a home network, or addressed by IP rather than by name.

All three controls are worth having. What they do not support is the word
coverage, because the whole is five channels rather than one.

</details>

<details class="qa">
<summary>What makes an image a vector?</summary>

That it is a file format parsed by code. The decoder reads a header, allocates
buffers from values in the file, and handles many variants, and it has bugs like
any other software.

So the vector is usually a malformed file that makes the decoder misbehave rather
than something concealed in the picture, which is the same idea as the software
vulnerabilities later in this block.

</details>

<details class="qa">
<summary>Why do removable devices remain effective as a vector?</summary>

Because they cross the boundary without using the network. Every control in a
network diagram, the firewall, the proxy, the mail gateway, the flow collector, is
irrelevant to a device somebody plugs in.

The only controls in its path are on the endpoint: device policy, media
restrictions, and whatever the operating system does about executing from removable
storage.

</details>

<details class="qa">
<summary>What single habit defeats all five vectors, and why does it work?</summary>

Verifying through a channel the request did not arrive on: telephoning the number
you already had rather than the one in the message.

It works because every one of these attacks depends on the recipient replying in
the channel the attacker controls. Its only failure mode is being skipped under
time pressure, which is why urgency appears in every message and why the
organisational version of the rule should have no exception for it.

</details>

## References

- [SP 800-177 Rev. 1](https://csrc.nist.gov/pubs/sp/800/177/r1/final) - NIST, trustworthy email, for what the mail channel's controls can and cannot establish. Free. Accessed 2026-08-26.
- [SP 800-83 Rev. 1](https://csrc.nist.gov/pubs/sp/800/83/r1/final) - NIST, malware incident prevention, for delivery mechanisms and removable media. Free. Accessed 2026-08-26.
- [RFC 2046](https://www.rfc-editor.org/rfc/rfc2046.html) - IETF, MIME media types, for why the declared type and the actual content are different things. Free. Accessed 2026-08-26.
- [ATT&CK Initial Access](https://attack.mitre.org/tactics/TA0001/) - MITRE, the documented techniques for getting in, most of which involve a person. Free. Accessed 2026-08-26.

**Where the content came from.** Nothing on this page is captured, and the reason
is the rule this block runs on: demonstrating a delivery vector means delivering
something, which is performing the attack rather than showing its evidence. The
channels, the controls in each path and the file format argument are read from the
sources cited. The verification habit is not a novel recommendation; it is the
control every one of those documents arrives at.

**If you also work on networks.** The Network+ track's
[attacks on services and people](/learn/network-plus/attacks-on-services-and-people)
covers the same delivery mechanisms with the network's view of each.
