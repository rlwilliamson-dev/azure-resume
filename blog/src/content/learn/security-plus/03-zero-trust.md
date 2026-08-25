---
title: "Zero trust"
description: "What the phrase actually names, why the component that decides is deliberately not the component the traffic crosses, what an implicit trust zone is and why the goal is to shrink it rather than remove it, and which of the exam's terms appear nowhere in the document they come from."
deck: "The contractor's laptop can reach finance because of where the cable goes"
track: "security-plus"
level: "working"
order: 40
objectives:
  - "Say what zero trust replaces, in terms of what the old model trusted"
  - "Name the three core components and say which one the traffic crosses"
  - "Explain what an implicit trust zone is and why it never reaches zero"
  - "Say what the control plane and data plane split buys when one of them is compromised"
  - "Read the exam's Zero Trust vocabulary against the document it comes from"
prerequisites: ["what-security-actually-protects"]
tags: ["security-plus", "security", "zero-trust", "architecture"]
updated: 2026-08-25
draft: false
examObjectives:
  - exam: "sy0-701"
    domain: "1.0"
    objective: "1.2"
sources:
  - title: "NIST SP 800-207, Zero Trust Architecture"
    url: "https://csrc.nist.gov/pubs/sp/800/207/final"
    publisher: "NIST"
    accessed: 2026-08-25
    tier: 1
  - title: "NIST SP 1800-35, Implementing a Zero Trust Architecture"
    url: "https://csrc.nist.gov/pubs/sp/1800/35/final"
    publisher: "NIST"
    accessed: 2026-08-25
    tier: 1
  - title: "NIST SP 800-63B, Digital Identity Guidelines: Authentication and Authenticator Management"
    url: "https://csrc.nist.gov/pubs/sp/800/63/b/upd2/final"
    publisher: "NIST"
    accessed: 2026-08-25
    tier: 1
symptoms:
  - symptom: "A device can reach a system nobody decided it should reach"
    anchor: "what-the-old-model-actually-trusted"
---

> **Before you read.** A contractor's laptop is plugged into a socket in a meeting
> room. From there it can reach the finance server, because the meeting room and
> the finance server are on the same network.
>
> Nobody decided that. It followed from where the cable goes.
>
> **What would have to change for that access to be a decision rather than a
> consequence?**

Zero trust is a badly named idea with a precise definition underneath it. The
name suggests trusting nothing, which is impossible. What it actually names is
removing the assumption that being in a particular place implies permission.

### Some words you will need

<dl class="terms">
<dt>subject</dt>
<dd>Whoever or whatever is asking. A person, a service, a device.</dd>
<dt>resource</dt>
<dd>The thing being asked for. An application, a dataset, an API.</dd>
<dt>policy engine</dt>
<dd>The component that makes the decision. Abbreviated PE.</dd>
<dt>policy administrator</dt>
<dd>The component that opens and closes the path once the engine has decided. Abbreviated PA.</dd>
<dt>policy enforcement point</dt>
<dd>The component the traffic actually crosses. Abbreviated PEP.</dd>
<dt>control plane</dt>
<dd>Where the deciding happens. Not on the path the data takes.</dd>
<dt>data plane</dt>
<dd>Where the data goes. Carries no policy.</dd>
<dt>implicit trust zone</dt>
<dd>The region past a checkpoint, where everything is trusted because it got past.</dd>
</dl>

## What breaks without this

**Access follows topology.** Anything plugged into the right network reaches
anything on it, so the access control is a cable and a switch port.

**One compromised device reaches everything that device could reach**, which on a
flat network is the estate. The attacker's second step is free.

**Nobody can answer who may reach what.** The honest answer is a diagram of the
network rather than a list of decisions, and the two are not the same document.

## What the old model actually trusted

The model zero trust replaces is usually described as perimeter security, which
makes it sound like a wall. The more useful description is what it trusted, which
was **location**.

You authenticated once, at the edge or at the login prompt, and after that your
position implied your permissions. Inside meant trusted. That is not stupid: it
was cheap, it worked when everything was in one building, and it is still how a
great many networks behave.

It fails on three things that all happened at once. People stopped being in the
building. Applications stopped being in the data centre. And attackers got good
at obtaining one credential and one foothold, at which point the model hands them
everything the foothold could reach.

SP 800-207 names the assumption directly: an implicit trust zone is an area where
all the entities are trusted to at least the level of the last enforcement point
they passed. That is the property being attacked.

## Three components, and only one is on the path

Here is the part that most descriptions lose, and it is the reason the
architecture is worth the trouble.

<figure class="learn-figure">
<svg viewBox="0 0 720 330" role="img" aria-labelledby="zt-title" style="width:100%;height:auto;">
<title id="zt-title">A subject's request reaching a resource through a policy enforcement point, with the policy engine and policy administrator sitting on a control plane above the data path and never carrying the data themselves</title>
<g fill="currentColor">
<text x="14" y="20" font-size="11">the thing that decides is not the thing the data goes through</text>
<rect x="150" y="38" width="440" height="86" rx="6" fill="currentColor" fill-opacity="0.04" stroke="currentColor" stroke-opacity="0.5" stroke-width="1.3" stroke-dasharray="6 4"/>
<text x="162" y="56" font-size="9.5" fill-opacity="0.8">control plane</text>
<rect x="196" y="66" width="150" height="42" rx="4" fill="var(--accent)" fill-opacity="0.14" stroke="var(--accent)" stroke-width="1.6"/>
<text x="271" y="83" text-anchor="middle" font-size="9.5">policy engine</text>
<text x="271" y="98" text-anchor="middle" font-size="8.5" fill-opacity="0.8">makes the decision</text>
<rect x="394" y="66" width="150" height="42" rx="4" fill="var(--accent)" fill-opacity="0.14" stroke="var(--accent)" stroke-width="1.6"/>
<text x="469" y="83" text-anchor="middle" font-size="9.5">policy administrator</text>
<text x="469" y="98" text-anchor="middle" font-size="8.5" fill-opacity="0.8">opens and closes the path</text>
<path d="M 354 87 H 386" stroke="var(--accent)" stroke-width="1.5"/>
<path d="M 378 82 L 388 87 L 378 92" fill="none" stroke="var(--accent)" stroke-width="1.5"/>
<path d="M 469 152 V 116" stroke="var(--accent)" stroke-width="1.5" stroke-dasharray="4 3"/>
<path d="M 464 144 L 469 154 L 474 144" fill="none" stroke="var(--accent)" stroke-width="1.5"/>
<text x="482" y="140" font-size="8.5" fill-opacity="0.8">commands the enforcement point</text>
<rect x="14" y="188" width="120" height="40" rx="4" fill="none" stroke="currentColor" stroke-opacity="0.7" stroke-width="1.4"/>
<text x="74" y="212" text-anchor="middle" font-size="9.5">subject</text>
<path d="M 142 208 H 400" stroke="currentColor" stroke-opacity="0.8" stroke-width="1.8"/>
<path d="M 392 203 L 402 208 L 392 213" fill="none" stroke="currentColor" stroke-opacity="0.8" stroke-width="1.8"/>
<rect x="408" y="188" width="122" height="40" rx="4" fill="currentColor" fill-opacity="0.1" stroke="currentColor" stroke-opacity="0.85" stroke-width="1.8"/>
<text x="469" y="205" text-anchor="middle" font-size="9.5">enforcement</text>
<text x="469" y="220" text-anchor="middle" font-size="9.5">point</text>
<path d="M 538 208 H 588" stroke="currentColor" stroke-opacity="0.8" stroke-width="1.8"/>
<path d="M 580 203 L 590 208 L 580 213" fill="none" stroke="currentColor" stroke-opacity="0.8" stroke-width="1.8"/>
<rect x="596" y="188" width="110" height="40" rx="4" fill="none" stroke="currentColor" stroke-opacity="0.7" stroke-width="1.4"/>
<text x="651" y="212" text-anchor="middle" font-size="9.5">resource</text>
<text x="14" y="252" font-size="9.5" fill-opacity="0.8">data plane</text>
<text x="14" y="284" font-size="10" fill-opacity="0.85">the request goes through one box, and two others decided whether it could</text>
<text x="14" y="306" font-size="10" fill-opacity="0.85">taking the engine offline stops new decisions and does not read anybody's traffic</text>
<text x="14" y="328" font-size="10" fill-opacity="0.85">the enforcement point can be an agent on the laptop, a gateway at the resource, or both</text>
</g></svg>
<figcaption>NIST SP 800-207 splits the job three ways and the split is the whole design. The policy engine is responsible for the ultimate decision to grant access. The policy administrator establishes or shuts down the communication path by issuing commands to enforcement points. The enforcement point is the only one of the three the traffic actually crosses, and its job is enabling, monitoring and eventually terminating the connection. Drawing them as one Zero Trust box loses the property that makes the architecture worth having: the components that hold the policy and the identity data are not on the data path, so compromising the path does not hand over the decision, and a compromised decision does not require the attacker to be anywhere near the traffic. The document also notes the enforcement point is one logical component that is often two real ones, an agent on the client and a gateway at the resource.</figcaption>
</figure>

The document splits the job three ways.

**The policy engine** is responsible for the ultimate decision to grant access to
a resource for a given subject. It runs what the document calls a trust algorithm,
which is simply the process the engine uses to reach that grant or deny.

**The policy administrator** establishes or shuts down the communication path
between a subject and a resource, by issuing commands to the relevant enforcement
points. It carries out the decision; it does not make it.

**The policy enforcement point** enables, monitors and eventually terminates the
connection. It is the only one of the three the traffic crosses.

**That separation is the design.** The components holding the policy and the
identity data are not on the data path. So an attacker sitting on the traffic has
not thereby obtained the ability to make decisions, and an attacker who
compromises the decision does not have to be anywhere near the traffic. Drawing
all three as one zero trust box, which is how most vendor diagrams do it, throws
that property away.

One detail worth carrying: the document says the enforcement point is a single
logical component that is often two real ones, an agent on the client and a
gateway at the resource. If you have ever wondered why a zero trust product wants
software on the laptop and an appliance in front of the application, that is why.

<details class="deeper">
<summary>If you are evaluating products: what the split means when the control plane is down</summary>

The question that separates a real implementation from a diagram is what happens
when the policy engine is unreachable.

There are two defensible answers and they are the fail-open and fail-closed
decision from the control types topic, applied to the most important component in
the architecture. Fail closed and an outage in the decision service is an outage
in everything, which is a large blast radius for one component. Fail open and an
attacker who can reach the engine's network path can disable the entire
architecture without touching a single resource.

What real implementations do is neither, mostly: existing sessions continue
because the enforcement point already has its instructions, and new decisions
stop. That is why the split matters operationally as well as architecturally. The
enforcement point holds enough state to keep going, so the failure degrades rather
than collapsing, and the window is bounded by however long those instructions
remain valid.

Which makes the interesting question about any product not "does it do zero
trust" but "how long does an enforcement point act on a decision before it has to
ask again". A long answer is an availability feature and a security problem,
because revoking access does nothing until the next check. A short answer inverts
both. That number is worth asking for and is rarely on the datasheet.

</details>

## The zone you are shrinking

A checkpoint creates a trusted region behind it. That region is the implicit trust
zone, and the document's own analogy is an airport: everyone passes one screening
checkpoint, and the boarding area behind it is the zone, where passengers, staff
and crew mill about all equally trusted.

<figure class="learn-figure">
<svg viewBox="0 0 720 302" role="img" aria-labelledby="zone-title" style="width:100%;height:auto;">
<title id="zone-title">One checkpoint with a large implicit trust zone behind it, against a checkpoint at each resource with almost no trust zone at all, which is what reducing the threat scope means</title>
<g fill="currentColor">
<text x="14" y="20" font-size="11">what gets trusted once somebody is past the checkpoint</text>
<text x="14" y="48" font-size="9.5" fill-opacity="0.85">one checkpoint at the edge</text>
<rect x="30" y="60" width="26" height="60" rx="3" fill="currentColor" fill-opacity="0.14" stroke="currentColor" stroke-opacity="0.85" stroke-width="1.6"/>
<text x="18" y="136" font-size="8.5" fill-opacity="0.8">checkpoint</text>
<rect x="80" y="60" width="600" height="60" rx="5" fill="var(--red)" fill-opacity="0.12" stroke="var(--red)" stroke-opacity="0.8" stroke-width="1.5" stroke-dasharray="6 4"/>
<text x="96" y="84" font-size="9.5">finance, payroll, source control, the wiki, the build servers, the printers</text>
<text x="96" y="106" font-size="9" fill="var(--red)" fill-opacity="0.95">everything in here is reachable once you are in here</text>
<text x="14" y="176" font-size="9.5" fill-opacity="0.85">a checkpoint at each resource</text>
<rect x="30" y="188" width="16" height="42" rx="2" fill="currentColor" fill-opacity="0.14" stroke="currentColor" stroke-opacity="0.85" stroke-width="1.4"/>
<rect x="52" y="188" width="90" height="42" rx="4" fill="var(--accent)" fill-opacity="0.1" stroke="var(--accent)" stroke-opacity="0.8" stroke-width="1.3"/>
<text x="97" y="213" text-anchor="middle" font-size="8.5">finance</text>
<rect x="168" y="188" width="16" height="42" rx="2" fill="currentColor" fill-opacity="0.14" stroke="currentColor" stroke-opacity="0.85" stroke-width="1.4"/>
<rect x="190" y="188" width="90" height="42" rx="4" fill="var(--accent)" fill-opacity="0.1" stroke="var(--accent)" stroke-opacity="0.8" stroke-width="1.3"/>
<text x="235" y="213" text-anchor="middle" font-size="8.5">payroll</text>
<rect x="306" y="188" width="16" height="42" rx="2" fill="currentColor" fill-opacity="0.14" stroke="currentColor" stroke-opacity="0.85" stroke-width="1.4"/>
<rect x="328" y="188" width="90" height="42" rx="4" fill="var(--accent)" fill-opacity="0.1" stroke="var(--accent)" stroke-opacity="0.8" stroke-width="1.3"/>
<text x="373" y="213" text-anchor="middle" font-size="8.5">source control</text>
<rect x="444" y="188" width="16" height="42" rx="2" fill="currentColor" fill-opacity="0.14" stroke="currentColor" stroke-opacity="0.85" stroke-width="1.4"/>
<rect x="466" y="188" width="90" height="42" rx="4" fill="var(--accent)" fill-opacity="0.1" stroke="var(--accent)" stroke-opacity="0.8" stroke-width="1.3"/>
<text x="511" y="213" text-anchor="middle" font-size="8.5">the wiki</text>
<rect x="582" y="188" width="16" height="42" rx="2" fill="currentColor" fill-opacity="0.14" stroke="currentColor" stroke-opacity="0.85" stroke-width="1.4"/>
<rect x="604" y="188" width="90" height="42" rx="4" fill="var(--accent)" fill-opacity="0.1" stroke="var(--accent)" stroke-opacity="0.8" stroke-width="1.3"/>
<text x="649" y="213" text-anchor="middle" font-size="8.5">build servers</text>
<text x="14" y="262" font-size="10" fill-opacity="0.85">the trusted region is the thing being shrunk, and it never reaches zero</text>
<text x="14" y="284" font-size="10" fill-opacity="0.85">a stolen credential still works, against one resource instead of against all of them</text>
</g></svg>
<figcaption>SP 800-207 defines the implicit trust zone as an area where all the entities are trusted to at least the level of the last enforcement point, and uses an airport for it: everyone passes one screening checkpoint, and the boarding area behind it is the zone. The analogy is good and it has a limit worth stating, which is that an airport genuinely cannot screen at every gate and a network can. That is the whole of the second row. Put an enforcement point in front of each resource and the trusted region behind each one contains one thing, so a credential taken from a laptop opens the resource that credential was for rather than everything the laptop could reach. It never reaches zero, because the region past the last check is always trusted by definition, and reducing it is the goal rather than eliminating it.</figcaption>
</figure>

**The analogy has a limit and the limit is the point.** An airport genuinely
cannot screen at every gate, so it accepts one large zone. A network can put an
enforcement point in front of each resource, and then the trusted region behind
each check contains one thing.

That is what the exam means by threat scope reduction, and it is worth stating
carefully: **a stolen credential still works.** What changes is what it opens. In
the first row of the figure it opens everything on the network. In the second it
opens the resource that credential was for.

The zone never reaches zero, because whatever is past the last check is trusted by
definition. Anybody promising zero trust in the literal sense is selling something.

<details class="deeper">
<summary>If you have drawn one of these: where the enforcement point actually goes, and the three models</summary>

SP 800-207 sets out several deployment models and the difference between them is
where the enforcement point physically sits, which turns out to decide most of
what the architecture can and cannot protect.

In the **device agent and gateway** model the enforcement point is split, with
software on the client and a gateway in front of the resource. It gives the
strongest position, because the client half can report device state, and it
requires you to be able to install software on every device that will ever
connect. That last clause is what rules it out for contractors, personal devices
and anything embedded.

In the **enclave gateway** model the gateway sits in front of a group of resources
rather than one. It is much easier to deploy in front of systems that cannot be
individually fronted, including the legacy application nobody can modify, and it
brings back an implicit trust zone the size of the enclave.

In the **resource portal** model the subject reaches everything through a portal.
Nothing is installed on the client at all, which is why it is the model that gets
used for third parties, and the cost is that visibility into device state largely
disappears.

The pattern across the three is a trade between how much you can see about the
client and how many clients you can support. Most real estates end up running all
three at once against different populations, which is fine and is worth being
deliberate about, because the weakest of the three sets the standard for anybody
who can choose which route to come in by.

</details>

## Reading the exam's vocabulary against the document

The objectives list Zero Trust terms under two headings, control plane and data
plane. Most of them come straight out of SP 800-207: policy engine, policy
administrator, policy enforcement point, implicit trust zones, subject.

Three do not. **Adaptive identity, threat scope reduction and policy-driven access
control appear nowhere in SP 800-207**, which is checkable in a few seconds with a
search across the document. That is not a criticism of either the exam or the
document, and it is worth knowing for a practical reason: looking those three up
in NIST's text and finding nothing is confusing if you assumed the list came from
there.

What they map onto is straightforward enough.

**Adaptive identity** is the idea that the decision uses more than a credential:
the device, its state, the location, the time, the behaviour compared with the
usual. In NIST's model that is inputs to the trust algorithm.

**Policy-driven access control** is that the decision comes from a stated policy
rather than from a network position, which is the whole architecture restated.

**Threat scope reduction** is shrinking the implicit trust zone, which is the
previous section.

The habit worth building here is the general one: when a certification's list and
a standard's text disagree, learn the list for the exam and read the standard for
the understanding, and notice which is which.

<details class="deeper">
<summary>If you are asked to implement it: the part that is not technology</summary>

The hardest part of any zero trust programme is not choosing an enforcement point.
It is that the architecture requires somebody to state, per resource, who may
reach it and under what conditions.

Most organisations have never written that down. Access is what accumulated:
somebody needed it once, a group was created, people joined the group, the project
ended. Replacing location-implies-permission with a stated policy means producing
the policy, and the production of it is the work.

That is why these programmes stall in the same place. The technology gets bought,
a pilot covers three applications, and the fourth application belongs to a team
that cannot say who should have access, and neither can anybody else. There is no
product answer to that. It is an inventory problem and an ownership problem, which
is where asset management and data classification earn their place on the exam
rather than being administrative filler.

The pragmatic order that works is to start where the policy already exists in some
form, usually the systems under a compliance regime, and to use the migration to
force the question everywhere else. The organisations that succeed treat "nobody
knows who should have this" as the finding rather than as an obstacle.

</details>

## Prove it

**Work it out.** Take the contractor's laptop from the top of this page. List
everything it can currently reach, not from a policy but from the network: what is
on that subnet, what routes exist, what has no authentication of its own. Then
list what it should be able to reach. The difference is the implicit trust zone,
measured.

**Work it out again.** Take one resource you care about and write the sentence a
policy engine would need: which subjects, in what device state, from where, at
what times, for how long before rechecking. If you cannot write it, that is the
finding, and it is the same finding most zero trust programmes hit at their fourth
application.

**Look it up.** NIST SP 800-207 section 2 lists the tenets of zero trust. Read
them and answer one question: how many of them are about the network, and how
many are about identity, device state and per-request decisions? The ratio is the
argument that this is not a networking project.

## What trips people up

### 1. Reading the name literally

Nothing trusts nothing. The thing being removed is the assumption that location
implies permission, and there is always a trusted region past the last check.

### 2. Drawing it as one box

The engine decides, the administrator carries out the decision, and only the
enforcement point is on the data path. Collapsing the three loses the property
that compromising the traffic does not hand over the decision.

### 3. Thinking a stolen credential stops working

It does not. It opens one resource instead of everything on the network, which is
a large improvement and is not the same as prevention.

### 4. Treating it as a network project

The tenets are mostly about identity, device state and deciding per request.
Segmentation helps and does not by itself make anything zero trust.

### 5. Looking for adaptive identity in the standard

It is not in SP 800-207. Nor is threat scope reduction or policy-driven access
control. Learn them for the exam and read the standard's own words for the
mechanism.

### 6. Ignoring how long a decision lasts

An enforcement point acting on an old decision is an enforcement point not
enforcing the current policy. Revocation takes effect at the next check, and how
often that is decides whether revocation means anything.

## Work it through

Back to the contractor's laptop in the meeting room.

**First, name what is granting the access.** It is not a policy and it is not a
credential. It is a switch port on a subnet that routes to the finance server.
The access exists because nothing is stopping it, which is a different thing from
somebody having allowed it.

**Then reject the fix everybody proposes first.** Putting the meeting room on its
own network segment is real work and it helps, and it moves the problem rather
than solving it: now the question is what that segment can reach, and the answer
is still a routing decision rather than a policy. Segmentation reduces the zone
and does not change what kind of thing is granting access.

**Then say what would actually change it.** The finance server sits behind an
enforcement point. A request from that laptop is a request from a subject, with a
device in a known state, and the engine decides. The decision has nothing to do
with the socket in the wall, and the same laptop in the same room gets a different
answer if the contractor's engagement has ended.

**Then notice the cost, which is the part that gets skipped.** Somebody has to
state the policy for the finance server. Who may reach it, from what kind of
device, and how long a grant lasts. If nobody can answer that, no product will
help, and the honest first task is finding out who owns the answer.

The decision, written the way it should be written down: put an enforcement point
in front of finance and write its access policy, with segmentation as an interim
measure while that happens rather than as the answer. The rejected option is
segmentation alone, and the cost of rejecting it is that the interim state lasts
longer than anybody plans for and has to be treated as a control in its own right
until the policy exists.

## Try it

**Find your own implicit trust zone.** From whatever network you are on, list the
things you can reach that you have never been granted access to. A printer, a
management interface, another person's machine. That set is the zone, and it is
usually larger than expected.

**Ask one system how long a decision lasts.** Log in to something, then have the
account disabled or the session revoked centrally, and time how long the existing
session keeps working. This is a genuinely surprising number in most environments
and it is the practical meaning of a per-request architecture.

**Read the tenets and score one system against them.** Section 2 of SP 800-207 is
two pages. Pick a system you know and mark each tenet as met, partly met or not
met. The exercise takes twenty minutes and produces a more honest picture than any
vendor assessment.

## Check yourself

<details class="qa">
<summary>Zero trust is described as trusting nothing. Why is that not what it means?</summary>

Because there is always a trusted region: whatever sits past the last enforcement
point is trusted by definition, which SP 800-207 calls the implicit trust zone.
The goal is to shrink it, not to remove it.

What is actually being removed is the assumption that location implies permission.
In the older model, being on the right network meant you were allowed, so access
followed topology. Zero trust replaces that with a decision made per request.

</details>

<details class="qa">
<summary>Name the three core components and say which one the traffic crosses.</summary>

The policy engine makes the decision. The policy administrator establishes or
shuts down the path by commanding enforcement points. The policy enforcement point
enables, monitors and terminates the connection, and it is the only one the
traffic goes through.

That separation is the design rather than an implementation detail. An attacker on
the data path has not obtained the ability to make decisions, and an attacker who
subverts the decision does not need to be near the traffic.

</details>

<details class="qa">
<summary>An attacker steals a valid credential from a laptop in a zero trust environment. What changes compared with a flat network?</summary>

What the credential opens. It still works, because it is valid, and it opens the
resource it was issued for rather than everything the laptop's network position
could reach.

That is threat scope reduction: the implicit trust zone behind each enforcement
point contains one resource instead of the estate. It is a large improvement and
it is not prevention, and describing it as prevention is how these architectures
get oversold.

</details>

<details class="qa">
<summary>You search SP 800-207 for "adaptive identity" and find nothing. Has the exam invented it?</summary>

The term does not appear in that document, along with threat scope reduction and
policy-driven access control. The underlying ideas do: what adaptive identity
describes is the range of inputs the policy engine's trust algorithm considers,
including device state, location and behaviour rather than a credential alone.

The useful habit is to learn the exam's list as the exam prints it and to read the
standard for the mechanism, while knowing which words came from which. Looking up
a term in the source and finding nothing is only confusing if you assumed the list
came from there.

</details>

<details class="qa">
<summary>Why is putting the meeting room on its own network segment not a zero trust implementation?</summary>

Because it changes the size of the trusted region without changing what grants
access. After segmentation, what the meeting room can reach is still decided by
routing and firewall rules rather than by a policy about subjects and resources.

Segmentation is worth doing and it reduces the implicit trust zone. It is an
interim measure rather than the answer, and treating it as the answer is the most
common way these programmes stop halfway.

</details>

## References

- [NIST SP 800-207](https://csrc.nist.gov/pubs/sp/800/207/final) - NIST, Zero Trust Architecture, and the source of every component definition, the tenets, and the implicit trust zone including the airport analogy. Free. Accessed 2026-08-25.
- [NIST SP 1800-35](https://csrc.nist.gov/pubs/sp/1800/35/final) - NIST, the practice guide, for what implementations of the above actually look like. Free. Accessed 2026-08-25.
- [NIST SP 800-63B](https://csrc.nist.gov/pubs/sp/800/63/b/upd2/final) - NIST, authentication guidance, for the identity half the architecture depends on. Free. Accessed 2026-08-25.

**Where the content came from.** Nothing on this page is captured, because zero
trust is an architecture rather than a state a machine reports, and there is no
command that returns one. Every component definition, the tenets and the airport
analogy are read from SP 800-207 itself rather than from a summary of it, and the
observation that three of the exam's terms appear nowhere in that document is a
search across its text, which anybody can repeat.

**If you also work on networks.** The Network+ track's
[zero trust, SASE and infrastructure as code](/learn/network-plus/zero-trust-sase-and-infrastructure-as-code)
topic covers the same architecture from the point of view of the network it
replaces, and
[network segmentation](/learn/network-plus/network-segmentation) covers the
interim measure this topic argues is not the answer.
