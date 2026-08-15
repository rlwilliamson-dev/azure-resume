---
title: "Cloud concepts and connectivity"
description: "The server is in a building you will never visit. Service and deployment models without the marketing, what a virtual private cloud actually is, why a security group is not a firewall appliance, and the two ways to connect your network to a cloud."
deck: "The server is in a building you will never visit"
track: "network-plus"
level: "working"
order: 600
objectives:
  - "Distinguish the service models and the deployment models"
  - "Say what a virtual private cloud is and how a public subnet differs from a private one"
  - "Explain what a security group is and why it is not a firewall appliance"
  - "Describe the two ways to connect a network to a cloud and when each fits"
  - "Define scalability, elasticity and multitenancy without the marketing"
prerequisites: ["nat-and-pat"]
tags: ["network-plus", "networking", "cloud"]
updated: 2026-08-15
draft: false
examObjectives:
  - exam: "n10-009"
    domain: "1.0"
    objective: "1.3"
sources:
  - title: "NIST SP 800-145, The NIST Definition of Cloud Computing"
    url: "https://csrc.nist.gov/pubs/sp/800/145/final"
    publisher: "NIST"
    accessed: 2026-08-15
    tier: 1
  - title: "NIST SP 800-146, Cloud Computing Synopsis and Recommendations"
    url: "https://csrc.nist.gov/pubs/sp/800/146/final"
    publisher: "NIST"
    accessed: 2026-08-15
    tier: 1
  - title: "ETSI GS NFV 002, Network Functions Virtualisation (NFV); Architectural Framework"
    url: "https://www.etsi.org/standards"
    publisher: "ETSI"
    accessed: 2026-08-15
    tier: 1
symptoms:
  - symptom: "A private instance can reach the internet but is not reachable from it"
    anchor: "a-virtual-private-cloud-and-its-subnets"
  - symptom: "A rule allows traffic and it is a security group, not an appliance, deciding"
    anchor: "a-security-group-is-not-a-firewall-appliance"
---

> **Before you read.** A company's main application server is in a data centre it
> does not own, in a city none of its staff have visited, on hardware it will
> never see, shared with other companies it will never know the names of.
>
> None of that is a problem, and all of it changes what the network team is
> responsible for and what it can assume.
>
> **What is still the network team's job when the server is somebody else's
> building?**

Cloud is an objective that arrives buried in vocabulary, most of it marketing. The
useful move is to translate each term into what it actually is on a network, which
is usually something this track already covered wearing a new name.

### Some words you will need

<dl class="terms">
<dt>service model</dt>
<dd>How much of the stack the provider runs: infrastructure, platform or software. The line between their job and yours moves with it.</dd>
<dt>deployment model</dt>
<dd>Who the cloud is for: public, private, hybrid, or shared by a community.</dd>
<dt>virtual private cloud</dt>
<dd>Your own isolated network inside a provider's cloud, with subnets and routing you control.</dd>
<dt>security group</dt>
<dd>A stateful set of allow rules attached to an instance, filtering its traffic where it sits.</dd>
<dt>internet gateway</dt>
<dd>The thing that gives a subnet a route to the internet. A NAT gateway lets a private subnet reach out without being reachable.</dd>
<dt>multitenancy</dt>
<dd>Many customers sharing the same physical infrastructure, kept apart by software.</dd>
</dl>

## What breaks without this

**You assume a boundary the provider does not.** Believing the cloud is private
because it is yours, when it is multitenant hardware kept apart by software, leads
to decisions that were never true.

**A subnet is public when you did not mean it to be.** Public and private in a
cloud are defined by routing, and a subnet with a route to the internet gateway is
reachable from the internet whether or not you intended it.

**Nobody owns the part in the middle.** The provider secures the infrastructure and
you secure what you put on it, and the line between the two moves with the service
model. Assuming the provider covers your side is how data ends up exposed with
nobody having decided to expose it.

## Service models and deployment models, translated

The service models are three points on one line: how much of the stack somebody
else runs.

**Infrastructure as a service** gives you virtual machines, networks and storage,
and you run everything from the operating system up. It is the closest to a data
centre you rent by the hour. **Platform as a service** gives you a place to run
code without managing the machine under it, so the provider runs the operating
system and you bring the application. **Software as a service** is the finished
application, run entirely by the provider, where you are a user and not an operator.
The single idea worth carrying is that as you move along that line, the provider
takes on more and you take on less, and the security boundary moves with it.

The deployment models are about who the cloud is for. **Public** is shared
infrastructure any customer can rent. **Private** is a cloud dedicated to one
organisation, whether it runs it or a provider does. **Hybrid** connects the two, so
some workloads run in a private cloud and some in a public one, which is where most
real organisations actually are. **Community** is a private cloud shared by several
organisations with a common requirement, such as a regulatory one, and it is the
model the exam lists and you will meet least.

## A virtual private cloud and its subnets

A virtual private cloud is your own network inside the provider's, isolated from
every other customer's, with an address range you choose and subnets and routing you
control. It is the data-centre network from the rest of this track, built out of the
provider's software rather than your switches, and the concepts map across almost
unchanged.

The one that trips people is what makes a subnet public or private, because it is
not a setting called public. It is routing. A subnet is public when its route table
has a path to an internet gateway, which is a two-way door: instances in it can be
reached from the internet and can reach out. A subnet is private when it has no such
route, so nothing on the internet can reach it. A private subnet that still needs to
reach out, for updates or an external service, gets a NAT gateway, which is exactly
topic 25's NAT: a one-way door that lets instances start connections outward while
remaining unreachable from outside.

<figure class="learn-figure">
<svg viewBox="0 0 720 300" role="img" aria-labelledby="vpc-title" style="width:100%;height:auto;">
<title id="vpc-title">A virtual private cloud with a public subnet routed to an internet gateway and a private subnet reaching out only through a NAT gateway, unreachable from the internet</title>
<g fill="currentColor">
<text x="14" y="20" font-size="11">public and private are decided by routing, not by a setting called private</text>
<rect x="14" y="40" width="470" height="234" rx="6" fill="currentColor" fill-opacity="0.03" stroke="currentColor" stroke-opacity="0.6"/>
<text x="28" y="60" font-size="10.5">virtual private cloud, your address range</text>
<rect x="34" y="76" width="200" height="80" rx="4" fill="currentColor" fill-opacity="0.06" stroke="currentColor" stroke-opacity="0.7"/>
<text x="46" y="96" font-size="10.5">public subnet</text>
<rect x="52" y="106" width="164" height="34" rx="3" fill="currentColor" fill-opacity="0.12" stroke="currentColor" stroke-opacity="0.7"/>
<text x="134" y="127" text-anchor="middle" font-size="10">web server</text>
<text x="46" y="152" font-size="9" fill-opacity="0.7">route to internet gateway</text>
<rect x="34" y="176" width="200" height="86" rx="4" fill="var(--red)" fill-opacity="0.06" stroke="var(--red)" stroke-width="1.6"/>
<text x="46" y="196" font-size="10.5" fill="var(--red)">private subnet</text>
<rect x="52" y="206" width="164" height="34" rx="3" fill="currentColor" fill-opacity="0.12" stroke="currentColor" stroke-opacity="0.7"/>
<text x="134" y="227" text-anchor="middle" font-size="10">database</text>
<text x="46" y="256" font-size="9" fill="var(--red)" fill-opacity="0.95">no route in from the internet</text>
<rect x="300" y="92" width="164" height="30" rx="3" fill="currentColor" fill-opacity="0.08" stroke="currentColor" stroke-opacity="0.7"/>
<text x="382" y="111" text-anchor="middle" font-size="10">internet gateway</text>
<rect x="300" y="200" width="164" height="30" rx="3" fill="currentColor" fill-opacity="0.08" stroke="currentColor" stroke-opacity="0.7"/>
<text x="382" y="219" text-anchor="middle" font-size="10">NAT gateway</text>
<rect x="586" y="140" width="120" height="44" rx="4" fill="currentColor" fill-opacity="0.06" stroke="currentColor" stroke-opacity="0.7"/>
<text x="646" y="166" text-anchor="middle" font-size="10.5">the internet</text>
<path d="M 234 116 H 300" stroke="currentColor" stroke-opacity="0.7" stroke-width="1.4" fill="none"/>
<path d="M 464 107 C 520 107 560 150 586 158" stroke="currentColor" stroke-opacity="0.7" stroke-width="1.4" fill="none"/>
<path d="M 234 220 H 300" stroke="var(--red)" stroke-width="1.6" fill="none"/>
<path d="M 292 215 l 8 5 l -8 5" stroke="var(--red)" stroke-width="1.6" fill="none"/>
<path d="M 464 212 C 520 212 560 175 586 168" stroke="currentColor" stroke-opacity="0.7" stroke-width="1.4" fill="none"/>
<text x="300" y="284" font-size="9.5" fill="var(--red)">the database reaches out through NAT and is never reached from outside</text>
</g></svg>
<figcaption>Both subnets are inside one virtual private cloud, and what separates them is the route table. The public subnet has a route to the internet gateway, a two-way door, so the web server is reachable from the internet and can reach out. The private subnet has no route in; its database reaches the internet only by starting a connection outward through the NAT gateway, which is topic 25's translation doing the same one-way job it does on any network. Nothing here is a firewall yet. This is routing deciding reachability, and the filtering is a separate layer.</figcaption>
</figure>

## A security group is not a firewall appliance

The filtering layer in a cloud is usually a security group, and the exam wants you
to know it is not the firewall box from topic 54, even though it does a filtering
job.

A firewall appliance is a device traffic passes through, sitting on the path between
two networks, deciding what crosses. A security group is not on a path at all. It is
a set of stateful allow rules attached to an instance, filtering that instance's own
traffic where the instance sits. Every instance can have its own, they are evaluated
at the instance rather than at a chokepoint, and there is no single box to route
through or to fail.

<details class="deeper">
<summary>If you already work on networks: why the distributed, allow-only model changes how you think about rules</summary>

Three differences from an appliance are worth having straight, because they change
how a policy is written rather than just where it runs.

The first is that a security group is allow-only. There is no deny rule and no
implicit-deny-you-write, because the default is deny and rules only add permission.
That removes the ordering problem from topic 54 entirely: with no denies, first-match
and rule order stop mattering, and a rule that cannot fire is not a failure mode
here. It also means you cannot express "everything except this", which is
occasionally what you want and is the job of a network access control list, the
cloud's other filter, which does have ordered allow and deny rules and sits on a
subnet rather than an instance.

The second is that it is stateful, in the sense topic 54's panel described: a reply
to an allowed outbound connection is allowed back without a rule for it. So a security
group is written in terms of the connections an instance should originate and accept,
not both directions of every conversation.

The third is that it is distributed. There is no appliance to become a bottleneck, a
single point of failure, or a thing every packet must be routed through, because the
enforcement happens at each instance. That is a real architectural advantage and it
has a cost: the policy is spread across many small rule sets rather than concentrated
in one place you can read top to bottom, which is why a cloud network needs the same
version control and drift detection topic 60 is about, applied to the security groups
themselves.

So the security group is not a smaller firewall. It is a different shape of the same
job: allow-only, stateful, and attached to the workload rather than to a chokepoint.

</details>

Alongside it, the exam names the **network security list**, which is the ordered,
subnet-level filter with allow and deny rules, closer to the access list from topic
54 and complementary to the per-instance security group. Between them, filtering in
a cloud happens at the instance and at the subnet, and neither is a box in the path.

## Connecting your network to a cloud

Two ways, and the choice is the familiar one between cheap-over-shared and
expensive-over-dedicated.

A **site-to-site VPN** connects your network to the cloud over the public internet,
encrypted, which is topic 50's VPN with a cloud at one end. It is quick to set up and
costs little, and it inherits the internet's variability in latency and throughput.

A **dedicated connection**, sold under names like direct connect or express route, is
a private circuit from your network to the provider, not touching the public internet.
It costs more and takes longer to provision, and it gives consistent latency, higher
throughput, and traffic that never traverses the public internet, which is sometimes a
compliance requirement rather than a performance one. The decision is the same one
topic 49 framed for any tunnel versus circuit: predictability and privacy against cost
and lead time.

## The words that describe why cloud is different

Three terms the objective lists, translated.

**Scalability** is being able to grow: to handle more load by adding capacity.
**Elasticity** is the sharper version, adding and removing capacity automatically as
load changes, so you run what you need now rather than what you might need at the
peak. **Multitenancy** is many customers on the same physical infrastructure, kept
apart by software, which is what makes the economics work and what the private and
community deployment models exist to opt out of.

And **network functions virtualisation**, which the objective names, is running the
network functions themselves as software instead of as boxes: a router, a firewall or
a load balancer as an instance rather than an appliance. It is the same idea as the
security group taken to its conclusion, and it is why a cloud network can be built
entirely without anyone racking hardware.

## Prove it

Nothing here is captured, because a real capture would be one provider's output and
the exam is deliberately vendor-neutral. The documents that define the vocabulary are
free and short.

**NIST SP 800-145.** Two pages of actual definition, and the source every vendor's
version derives from. Read it and answer one question: what are the three service
models and the four deployment models, in NIST's words? The exam's terms are these,
and reading the original is faster than reconciling three vendors' diagrams.

**NIST SP 800-146.** The synopsis and recommendations, longer, and the clearest free
statement of the shared-responsibility idea: which security obligations move to the
provider and which stay with you as you go from infrastructure to software. Read the
part on responsibilities and note that the line moves with the service model, which is
the whole point of the middle of this page.

## What trips people up

### 1. Thinking public and private subnets are a setting

They are routing. A subnet is public because it has a route to an internet gateway.
Remove that route and it is private, reachable from nothing outside.

### 2. Calling a security group a firewall

It filters, but it is not an appliance in the path. It is allow-only, stateful, and
attached to each instance, so rule order does not matter and there is no box to route
through or to fail.

### 3. Believing the provider secures your side

The provider secures the infrastructure. You secure what you run on it, and the line
between the two moves with the service model. Nobody covers the middle unless you
know where the middle is.

### 4. Assuming yours means private

Public cloud is multitenant: shared physical hardware kept apart by software. Your
virtual private cloud is isolated logically, not physically, and that is a real
distinction for some requirements.

### 5. Reaching for a dedicated connection by default

A VPN over the internet is quick and cheap and often enough. A dedicated circuit buys
consistency and privacy at higher cost and longer lead time, and is the answer to a
compliance or performance requirement, not the default.

### 6. Confusing scalability with elasticity

Scalability is being able to grow. Elasticity is growing and shrinking automatically
as load changes. The second is what lets you pay for now instead of for the peak.

## Work it through

The application server in the building nobody visits, and what remains the network
team's job.

First, place the workload on the service-model line, because that decides how much is
still yours. On infrastructure as a service the operating system, the patching and the
network configuration are all yours; on software as a service almost none of it is.
The building being somebody else's does not tell you where the boundary sits; the
service model does.

Then design the virtual private cloud the way you would a data-centre network, because
it is one. The public-facing parts go in a subnet routed to the internet gateway, the
data goes in a private subnet with no route in, and the private parts reach out through
NAT if they must. This is subnetting and routing from earlier in the track, and it is
still the network team's job.

Then write the filtering where the cloud puts it, which is the instance and the subnet,
not a box in the path. Security groups on the instances, allow-only and stateful, and
network security lists on the subnets where you need ordered deny rules. The policy is
distributed, so it needs the version control topic 60 argues for even more than an
appliance did.

Then choose how your own network reaches it, weighing a VPN over the internet against a
dedicated circuit on the same predictability-versus-cost axis every tunnel decision
uses. And keep owning the middle: the provider secures the infrastructure, you secure
what you put on it, and the exposure that hurts is the part each side assumed the other
had.

## Try it

**Read NIST SP 800-145 and write the models from memory.** Three service, four
deployment. If you can produce them without the marketing names a vendor wraps them
in, the objective's vocabulary is done.

**Draw a two-subnet virtual private cloud.** One public, one private, an internet
gateway, a NAT gateway. Mark which arrows are two-way and which are one-way. That
drawing is most of what the objective asks about connectivity.

**Find the shared-responsibility line for one service you use.** Pick a cloud service
and work out what the provider secures and what you do. It is the single idea that
prevents the exposure nobody decided to create.

## Check yourself

<details class="qa">
<summary>What actually makes a cloud subnet public rather than private?</summary>

Its route table. A public subnet has a route to an internet gateway, which is a
two-way door: its instances can be reached from the internet and can reach out. A
private subnet has no such route, so nothing on the internet can reach it.

There is no setting called public. If a private instance needs to reach out for
updates or an external service, it does so through a NAT gateway, which lets it start
connections outward while staying unreachable from outside, exactly as NAT does on any
network.

</details>

<details class="qa">
<summary>Why is a security group not a firewall appliance?</summary>

Because it is not a device in the path. A firewall appliance sits between networks and
every packet crossing passes through it. A security group is a set of stateful allow
rules attached to an instance, filtering that instance's own traffic where it sits.

It is allow-only, so there are no deny rules and rule order does not matter, and it is
distributed across instances rather than concentrated in one box, so there is no
chokepoint to route through or to fail. It does a filtering job in a different shape.

</details>

<details class="qa">
<summary>Where does the security boundary between you and the provider sit?</summary>

It moves with the service model. On infrastructure as a service you own everything from
the operating system up, including patching and network configuration. On platform as a
service the provider runs the operating system and you own the application. On software
as a service the provider runs almost all of it and you are a user.

The exposure that hurts is the part each side assumed the other covered, which is why
knowing where the line sits for a given service is the practical skill, not the model
names on their own.

</details>

<details class="qa">
<summary>When would you choose a dedicated connection over a site-to-site VPN?</summary>

When you need consistent latency, higher throughput, or traffic that never touches the
public internet, and you can accept the higher cost and longer provisioning. A dedicated
circuit gives predictability and privacy; a VPN gives quick, cheap connectivity over the
internet with the internet's variability.

Often the requirement is compliance rather than performance: some data is not allowed to
transit the public internet at all, and only a private circuit satisfies that. It is the
same predictability-versus-cost decision every tunnel-or-circuit choice comes down to.

</details>

<details class="qa">
<summary>What is the difference between scalability and elasticity?</summary>

Scalability is the ability to grow, handling more load by adding capacity. Elasticity is
adding and removing capacity automatically as load changes.

The distinction matters for cost. A scalable system can be made bigger; an elastic one
sizes itself to current demand, so you pay for what you are using now rather than
provisioning for the peak and paying for it around the clock.

</details>

## References

- [NIST SP 800-145](https://csrc.nist.gov/pubs/sp/800/145/final) - NIST, the two-page definition of cloud computing and the source of the service and deployment models the exam uses. Free. Accessed 2026-08-15.
- [NIST SP 800-146](https://csrc.nist.gov/pubs/sp/800/146/final) - NIST, the synopsis and recommendations, and the clearest free statement of shared responsibility moving with the service model. Free. Accessed 2026-08-15.
- [ETSI NFV](https://www.etsi.org/standards) - ETSI, the standards body behind network functions virtualisation, for running network functions as software rather than appliances. Free. Accessed 2026-08-15.

**Where the numbers came from.** There are no measured numbers on this page.
Nothing here is captured, because a real capture would be one cloud provider's output
and the objective is deliberately vendor-neutral; the figure is illustrative, showing a
two-subnet virtual private cloud chosen to make the routing distinction between public
and private visible.

**If you also work on Linux.** The whole of this maps onto tools this track already
used. A virtual private cloud is subnets and routing, which is `ip route`. A NAT gateway
is `nft` doing masquerade, the same translation from topic 25. And network functions
virtualisation is why a router or firewall can be a Linux instance running `frr` or `nft`
rather than an appliance, which is exactly what the labs in this track have been all
along.
