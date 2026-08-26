---
title: "Social engineering"
description: "Why urgency is the payload rather than the packaging, what makes a pretext work, how many near-misses of a well-known domain actually exist, and why awareness training keeps being funded and keeps not working."
deck: "The message is from your finance director, it uses their turn of phrase, and it is urgent"
track: "security-plus"
level: "intro"
order: 150
objectives:
  - "Name the techniques in this objective and say what distinguishes each"
  - "Explain why urgency is the payload"
  - "Say what makes a pretext credible and where the material comes from"
  - "Describe typosquatting and say when it is economically worthwhile"
  - "Say why technical controls are the wrong place to look for these"
  - "State what awareness training measures and what it does not"
prerequisites: ["how-a-message-becomes-a-vector"]
tags: ["security-plus", "security", "threats", "social-engineering"]
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
  - title: "MITRE ATT&CK, Phishing"
    url: "https://attack.mitre.org/techniques/T1566/"
    publisher: "MITRE"
    accessed: 2026-08-26
    tier: 1
  - title: "SP 800-50 Rev. 1, Building a Cybersecurity and Privacy Learning Program"
    url: "https://csrc.nist.gov/pubs/sp/800/50/r1/final"
    publisher: "NIST"
    accessed: 2026-08-26
    tier: 1
  - title: "BIND 9 utilities manual"
    url: "https://bind9.readthedocs.io/en/latest/manpages.html"
    publisher: "ISC"
    accessed: 2026-08-26
    tier: 1
symptoms:
  - symptom: "A payment was made on a request that looked entirely legitimate"
    anchor: "urgency-is-the-payload"
  - symptom: "Somebody typed a domain name slightly wrong and reached a real site"
    anchor: "how-many-near-misses-actually-exist"
---

> **Before you read.** A message arrives from your finance director. It uses their
> usual greeting, refers to a meeting that happened, and asks for something
> unusual, today, because they are about to get on a flight.
>
> **Which technical control is supposed to catch that?**

None of them, and that is not a failure of the controls. Every technique in this
objective is aimed at a person making a decision, and the decision is the target
rather than the machine. This topic is about how those messages are built and what
actually stops them.

### Some words you will need

<dl class="terms">
<dt>phishing</dt>
<dd>A message designed to make somebody act against their interest. Email, by convention.</dd>
<dt>vishing</dt>
<dd>The same, by voice.</dd>
<dt>smishing</dt>
<dd>The same, by text message.</dd>
<dt>pretext</dt>
<dd>The invented context that makes the request make sense.</dd>
<dt>business email compromise</dt>
<dd>The request arrives from a real account somebody controls. Nothing about it is forged.</dd>
<dt>impersonation</dt>
<dd>Claiming to be a specific person. Brand impersonation claims to be an organisation.</dd>
<dt>watering hole</dt>
<dd>Compromising a site the target population already visits, rather than approaching them.</dd>
<dt>typosquatting</dt>
<dd>Registering the near-misses of a name people type.</dd>
<dt>misinformation and disinformation</dt>
<dd>False information spread without and with intent respectively.</dd>
</dl>

## What breaks without this

**A payment leaves on a request that passed every check.** There was nothing
technically wrong with the message, because the attack was the request rather than
the message.

**Training measures the wrong thing.** People learn to spot the markers of a bulk
campaign, and the message that succeeds has none of them.

**Nobody verifies because verifying feels rude.** The culture makes checking a
senior person's request look like distrust, so it does not happen.

**A near-miss domain is registered and nobody notices.** Somebody mistypes,
arrives somewhere convincing, and the organisation finds out from a customer.

## Urgency is the payload

The message in the hook has three components and only one of them is doing the
work.

**The pretext** makes the request make sense. A flight, a supplier's deadline, an
acquisition nobody is supposed to know about. It answers the question of why this
is happening now and why by this route.

**The impersonation** supplies authority. It is easier to comply with a request
from somebody senior, and the message is constructed so the recipient does not
have to think about whether it is really them.

**The urgency is the payload.** Everything else exists to deliver it. Urgency
removes the time in which somebody would check, and checking is the only thing
that reliably defeats any of this. A message that says "when you get a chance"
gets checked. A message that says "before the end of the day, I am about to be
unreachable" does not.

That framing has a practical consequence worth carrying into any process design.
Every verification rule contains, somewhere, a provision for when there is no time,
and the message is built to reach that clause. The clause is the vulnerability.

<figure class="learn-figure">
<svg viewBox="0 0 720 292" role="img" aria-labelledby="se-title" style="width:100%;height:auto;">
<title id="se-title">Four named social engineering techniques shown as one request on four channels, converging on a single verification step that defeats all of them</title>
<g fill="currentColor">
<text x="14" y="20" font-size="11">four names in the objective, one request, and one thing that stops all of it</text>
<rect x="14" y="44" width="182" height="30" rx="4" fill="var(--red)" fill-opacity="0.12" stroke="var(--red)" stroke-opacity="0.65" stroke-width="1.2"/>
<text x="26" y="63" font-size="8.5">phishing</text>
<text x="212" y="63" font-size="8" fill-opacity="0.75">email</text>
<text x="316" y="63" font-size="8" fill-opacity="0.85">a link, an attachment, or a request</text>
<rect x="14" y="82" width="182" height="30" rx="4" fill="var(--red)" fill-opacity="0.12" stroke="var(--red)" stroke-opacity="0.65" stroke-width="1.2"/>
<text x="26" y="101" font-size="8.5">smishing</text>
<text x="212" y="101" font-size="8" fill-opacity="0.75">text message</text>
<text x="316" y="101" font-size="8" fill-opacity="0.85">the same request, no gateway in the path</text>
<rect x="14" y="120" width="182" height="30" rx="4" fill="var(--red)" fill-opacity="0.12" stroke="var(--red)" stroke-opacity="0.65" stroke-width="1.2"/>
<text x="26" y="139" font-size="8.5">vishing</text>
<text x="212" y="139" font-size="8" fill-opacity="0.75">a voice call</text>
<text x="316" y="139" font-size="8" fill-opacity="0.85">no artefact at all, and urgency lands harder</text>
<rect x="14" y="158" width="182" height="30" rx="4" fill="var(--red)" fill-opacity="0.12" stroke="var(--red)" stroke-opacity="0.65" stroke-width="1.2"/>
<text x="26" y="177" font-size="8.5">business email compromise</text>
<text x="212" y="177" font-size="8" fill-opacity="0.75">a real account</text>
<text x="316" y="177" font-size="8" fill-opacity="0.85">every authentication check passes</text>
<path d="M 105 198 V 216" stroke="var(--red)" stroke-opacity="0.45" stroke-width="1.3"/>
<path d="M 101 209 L 105 217 L 109 209" fill="none" stroke="var(--red)" stroke-opacity="0.45" stroke-width="1.3"/>
<rect x="14" y="222" width="420" height="34" rx="5" fill="var(--accent)" fill-opacity="0.16" stroke="var(--accent)" stroke-width="1.7"/>
<text x="224" y="243" text-anchor="middle" font-size="9.5">reply on a channel the request did not arrive on</text>
<text x="14" y="278" font-size="9" fill-opacity="0.7">the four differ in what a technical control can inspect. they do not differ in what defeats them</text>
</g></svg>
<figcaption>Four names from the objective, which are one technique on four channels. The differences down the left are about what a technical control can inspect: email has a gateway, a text message does not, a voice call leaves no artefact at all, and a request from a genuinely compromised account passes every sender check because the sender is real. None of those differences matters to the box at the bottom. The single habit that defeats all four is replying through a route the request did not arrive on, and its only failure mode is being skipped by somebody in a hurry, which is what the urgency in every one of them is for.</figcaption>
</figure>

<details class="deeper">
<summary>If you write the pretext defence: where the material comes from, and why removing it is not the answer</summary>

A convincing pretext needs specifics: a real project, a real supplier, a plausible
reason, somebody's turn of phrase. The material is public and gathering it is not
difficult.

Company announcements name suppliers and partners. Job advertisements describe the
technology in use and the team structure. Professional networking profiles give the
reporting line, tenure and who recently joined. Conference talks describe systems
in detail. An out-of-office reply confirms that somebody is genuinely travelling,
which is why the message in the hook mentions a flight.

The instinct is to reduce the exposure, and it is worth being honest about how far
that goes. Some of it is reasonable: an out-of-office reply naming a deputy and a
mobile number is more than the sender needs. Most of it is not, because the
information exists for good reasons. A company that stops naming its customers, its
staff and its technology has damaged its ability to sell, recruit and hire in
exchange for a marginal increase in the effort of writing a convincing message.

So the defence is not scarcity of information. It is that the request itself has to
survive a check regardless of how convincing its framing is, which returns to the
verification habit.

There is one exception worth acting on, because the ratio is different: information
that maps the payment process specifically. Who approves what, the finance team's
structure, which supplier is due to invoice. That is of narrow value to anybody
legitimate and high value to somebody constructing a business email compromise, and
keeping it off public pages costs nothing.

</details>

## How many near-misses actually exist

Typosquatting is the technique that sounds theoretical and is measurable in
seconds.

<details class="predict">
<summary>Generate the single-character near-misses of a well-known domain. Predict how many of them are registered and resolving today.</summary>

```bash
# AlmaLinux 10.2, x86_64
$ nearmiss microsoft.com; echo; nearmiss rlwilliamson.dev
32 near-misses generated for microsoft.com
25 of them resolve to an address today
  imcrosoft.com
  mcirosoft.com
  miceosoft.com
  micorsoft.com
  microaoft.com
  microdoft.com
  microoosoft.com
  microosft.com

38 near-misses generated for rlwilliamson.dev
0 of them resolve to an address today
```

**Twenty-five of thirty-two for the well-known name, and none of thirty-eight for
the small one.**

That contrast is the whole economics of the technique. Registering a near-miss is
worth doing when enough people type the name for the mistakes to be worth
something, and it is worth nothing when they do not. The threshold is traffic, and
a domain nobody types has no near-misses registered because there is no return.

Two things follow for practice.

The first is that the well-known case is not a gap somebody should have closed.
Thirty-two variants is one generator's output from three simple rules, and the real
space, including different top-level domains, homoglyphs and hyphenation, runs to
thousands. Defensive registration addresses the handful most likely to be typed and
cannot address the space.

The second is that the small case is not safety. Nobody has registered the
near-misses of a small domain speculatively, and somebody targeting that specific
organisation would register one the week they needed it. The absence measures
current commercial interest rather than difficulty.

What that leaves as the practical control is monitoring rather than registration:
watching for newly registered names close to your own, which is a service that
exists, and which turns the question from prevention into early notice.

</details>

**Brand impersonation is the same idea without the domain trick.** A message that
looks like it comes from a service the recipient uses, with correct styling and
plausible content, sent from a domain that has nothing to do with that service.
Recipients recognise the brand and not the sender.

**A watering hole inverts the approach entirely.** Rather than reaching the target,
compromise something the target population already visits: an industry forum, a
supplier's site, a widely used component. It is more work, it is harder to detect
because the visit is genuinely voluntary, and it reaches a population rather than a
person.

<details class="deeper">
<summary>If you run detection: what these leave in logs, and the one that leaves nothing</summary>

Each technique in this objective leaves a different amount for an investigation to
work with, and knowing which leaves nothing changes where you invest.

**Phishing by email** leaves the most. The message exists, with headers, a sending
address, authentication results and a delivery record. Even if it is not caught,
it can be found afterwards, and finding the other forty recipients is a search.

**A typosquatted domain** leaves a resolution and a connection. If your resolver
logs queries, the visit is visible, and it is visible for everybody who made it,
which is how one person's mistake surfaces as an organisational finding.

**Business email compromise** leaves a message that looks correct in every
respect. What it leaves that is useful is on the other end: the compromised
account's own logs show an unusual sign-in, and those belong to the supplier
rather than to you, which is why telling them matters.

**Smishing leaves nothing you hold.** The message went to a personal device through
a carrier, and the first record you have is whatever the person did next.

**Vishing leaves less than that.** No message, no artefact, and frequently no
record that the call happened at all unless the person reports it.

The practical consequence is that the last two are detectable only through
reporting, which makes the reporting route the control. That means a channel
people can use quickly, an assurance that reporting a false alarm is welcome, and
somebody who responds. Organisations that treat reports as noise train people to
stop sending them, and then the only two techniques with no technical detection
have no detection at all.

</details>

## Why the technical controls are the wrong place

Every control in block E is aimed at a machine doing something. These techniques
are aimed at a person deciding something, and the gap between those is not closed
by better filtering.

**The message with no payload passes everything.** No attachment, no link, correct
authentication, a real thread. There is nothing for a filter to object to because
the message is a business request, and deciding whether a business request is
legitimate is not a thing a filter does.

**Misinformation and disinformation are in this objective for the same reason.**
They are not attacks on systems at all. They are attacks on what people believe,
and the distinction between the two is intent: misinformation is wrong,
disinformation is wrong on purpose. Neither has a technical control and both can
produce action against the organisation's interest.

**What does work is process.** Not judgement, which is what the message is designed
to satisfy, but a rule applied regardless: payment detail changes verified by
outbound call to a stored number, always. Requests for credentials never actioned
in the channel they arrived on. Unusual requests from senior people confirmed
through the directory. Each of those converts a decision made under pressure into a
step somebody follows.

<details class="deeper">
<summary>If you fund awareness training: what it measures, and why the click rate is the wrong number</summary>

Awareness training keeps being funded because the alternative is doing nothing, and
it keeps disappointing because of what gets measured.

The usual measure is the click rate on simulated phishing. It falls after training,
which looks like success, and it is measuring something narrower than it appears.
Simulations are generated from templates, they carry the markers of a bulk
campaign, and a population trained to spot those markers gets better at spotting
those markers. That is a real improvement against bulk campaigns and it says very
little about the targeted case, which is built from your own public information and
has none of the markers.

The number worth measuring instead is the report rate, and it is better for three
reasons. It is a behaviour rather than an avoidance, so it can be practised. It
scales: one person reporting a message means the other forty recipients can be
found and warned, which is a detection capability the click rate does not produce.
And it is the only signal available for the two channels that leave no technical
trace.

That change has consequences for how the programme runs. Reporting has to be one
action rather than a form. Reports have to be answered, including the false alarms,
because a person who reports something and hears nothing does not report the next
one. And the messaging has to say explicitly that reporting a legitimate message is
a good outcome, because otherwise the fear of looking foolish suppresses exactly
the reports you want.

The uncomfortable part worth saying to whoever owns the budget: a programme
measured on click rate will optimise for easier simulations over time, because that
is what makes the number improve, and nobody involved will have intended it.

</details>
<details class="predict">
<summary>An organisation runs quarterly phishing simulations. The click rate falls from 18 percent to 4 percent over two years. Predict what has improved.</summary>

**The ability to recognise simulated phishing**, which overlaps with real bulk
phishing and barely at all with the targeted case.

Simulations are built from templates. A template has to be generated at scale,
approved, and made safe to send to thousands of people, which means it carries the
properties that make a message identifiable: a generic pretext, a sender that is
not quite right, a link to a tracking domain. Training against those teaches people
to spot exactly those, and the number falls.

The message that actually costs an organisation money has none of them. It comes
from a supplier's real account, on a thread that exists, about a project that
exists, and it asks for something that happens legitimately from time to time.
Nothing about the simulation prepared anybody for it, and the improved click rate
did not measure readiness for it.

Two further effects worth knowing, because they push in the wrong direction. A
programme measured on a falling number has an incentive to keep it falling, and the
easiest way is gentler simulations, which nobody decides and everybody drifts
toward. And a punitive framing, where clicking has consequences, suppresses
reporting as well as clicking, because a person who is unsure now has a reason not
to draw attention to themselves.

The number that would tell you something is how many people reported it, and how
quickly, because that is the signal that lets you find the other recipients of a
real campaign.

</details>


## Prove it

**Run it.** Generate the near-misses of your own domain and check which resolve. It
takes a script and a resolver, and it answers a question most organisations have
never asked about themselves.

**Work it out.** Take the message from the top of this page and list every check a
technical control could perform. Then decide which one would have failed, and
notice that the answer is none.

**Look it up.** Open SP 800-50 and find what it says about measuring a learning
programme. The measures it suggests are behavioural rather than avoidance-based,
which is the argument this topic makes about report rate.

## What trips people up

### 1. Treating urgency as packaging

It is the payload. Everything else in the message exists to deliver it, because it
removes the time in which somebody would check, and checking is what defeats all of
this.

### 2. Expecting a filter to catch a business request

A message with no attachment, no link and correct authentication has nothing for a
filter to object to. Deciding whether a request is legitimate is not what a filter
does.

### 3. Believing defensive registration solves typosquatting

Three simple rules produced thirty-two variants for one name, and the real space
including other top-level domains and homoglyphs runs to thousands. Monitoring for
new registrations is the achievable version.

### 4. Reading a small domain's clean result as safety

Nobody registers near-misses speculatively for a name nobody types. Somebody
targeting that organisation would register one the week they needed it.

### 5. Measuring awareness by click rate

It measures the ability to spot bulk-campaign markers, which the targeted case does
not have. Report rate is a behaviour, it scales to warning the other recipients,
and it is the only signal for voice and text.

### 6. Treating a false-alarm report as a waste

The person who reports something and hears nothing stops reporting, and voice and
text have no other detection route at all.

## Work it through

An employee receives a call from somebody claiming to be from the service desk,
asking them to read out a code that has just arrived on their phone. They comply.
The account is used within minutes.

**The tempting response is more training.** Somebody was deceived, so teach people
not to be. It addresses the visible failure and it will produce a slide about never
sharing codes, which people already know and which did not help.

**The response that works removes the possibility rather than the mistake.** A code
that can be read out is a code that can be phished, and the fix is a factor that
cannot be: a security key binds the credential to the origin, so there is nothing
to read out and nothing to relay. That is the phishing resistance argument from
block E, arriving here as the answer to a specific incident.

**Then the second question is why the call was plausible.** The service desk had a
habit of ringing people, so a call from the service desk was unremarkable. Changing
that habit, so that the service desk never asks for a code and says so in advance,
removes the pretext rather than the message.

**What this rejects is training as the primary response.** It has a place and it is
the weakest of the three, because it asks a person under pressure to behave
correctly, and the whole design of the attack is to make that hard.

The residual worth naming: not everybody will have a security key, and the people
who do not remain phishable by exactly this call. That is a deliberate acceptance
if the keys were issued to a subset, and it should be recorded rather than assumed
away.

## Try it

**Check your own near-misses.** Generate single-character variants of your domain
and query them. Whatever the number, it is worth knowing.

**Read a real one.** Find a phishing message in your own quarantine and identify
the pretext, the impersonation and the urgency separately. They are always all
three.

**Test the reporting route.** Report something harmless through your organisation's
phishing button and see how long it takes to hear back. That latency is what
determines whether people keep reporting.

**Ask about the service desk.** Find out whether your service desk ever telephones
people and asks them to do something. If it does, that habit is a pretext somebody
can borrow.

## Check yourself

<details class="qa">
<summary>Why is urgency described as the payload rather than as tone?</summary>

Because it is the component doing the work. The pretext makes the request make
sense and the impersonation supplies authority, and both exist to deliver the
urgency, which removes the time in which somebody would verify.

Verification is the only thing that reliably defeats these techniques, so anything
that prevents it is the attack. That is also why an urgency exception in a
verification policy is the clause the message is written to reach.

</details>

<details class="qa">
<summary>Twenty-five of thirty-two near-misses of a well-known domain resolve, and none of a small one. What does that mean?</summary>

That the technique is economic. Registering a near-miss pays when enough people
type the name for the mistakes to be worth something, and pays nothing when they do
not.

Neither result is a security posture. The large number is not a failure to defend,
because the real variant space runs to thousands. The zero is not safety, because
somebody targeting that organisation would register one when they needed it.
Monitoring for new registrations is the achievable control.

</details>

<details class="qa">
<summary>Which of these techniques leaves nothing for an investigation, and what follows?</summary>

Voice and text. The message goes to a personal device through a carrier, or there
is no message at all, and the first record the organisation holds is whatever the
person did afterwards.

What follows is that reporting is the detection mechanism for those two, which
makes the reporting route a control: one action to use, an answer to every report
including false alarms, and an explicit statement that reporting a legitimate
message is a good outcome.

</details>

<details class="qa">
<summary>Why is business email compromise harder to detect than ordinary phishing?</summary>

Because nothing about it is forged. The message comes from a real account the
attacker controls, usually a supplier's, so authentication passes, the domain is
correct, and the thread is a genuine thread with real history.

Every sender-based check is satisfied by design. The useful evidence is on the
other end, in the compromised account's own sign-in records, which belong to the
supplier rather than to you, and that is why telling them is part of the response.

</details>

<details class="qa">
<summary>What should an awareness programme measure, and why not the click rate?</summary>

The report rate. Click rate measures the ability to spot the markers of a bulk
campaign, which is what simulations contain, and the targeted case is built from
your own public information and has none of them.

Reporting is a behaviour that can be practised, it scales because one report lets
you find and warn the other recipients, and it is the only detection signal for
voice and text. A programme measured on click rate also drifts toward easier
simulations over time, because that is what improves the number.

</details>

## References

- [SP 800-177 Rev. 1](https://csrc.nist.gov/pubs/sp/800/177/r1/final) - NIST, trustworthy email, for what sender checks establish and what a correct message still permits. Free. Accessed 2026-08-26.
- [ATT&CK T1566](https://attack.mitre.org/techniques/T1566/) - MITRE, phishing and its sub-techniques, for the delivery variants documented in the wild. Free. Accessed 2026-08-26.
- [SP 800-50 Rev. 1](https://csrc.nist.gov/pubs/sp/800/50/r1/final) - NIST, building a learning programme, for what to measure and how. Free. Accessed 2026-08-26.
- [BIND 9 utilities](https://bind9.readthedocs.io/en/latest/manpages.html) - ISC, the resolver query the typosquatting capture uses. Free. Accessed 2026-08-26.

**Where the content came from.** The near-miss block is captured on an AlmaLinux
10.2 container. It generates name variants locally and asks a public resolver
whether each one has an address, which is a DNS query and not a probe of anybody's
host: nothing is connected to, nothing is fetched, and no registered name is
contacted. The two domains are a well-known one and this site's own. Nothing else
on this page is captured, because every remaining technique here is a message sent
to a person, and sending one is performing the attack rather than showing evidence
of it.

**If you also work on networks.** The Network+ track's
[attacks on services and people](/learn/network-plus/attacks-on-services-and-people)
covers the same techniques with the network evidence each one leaves.
