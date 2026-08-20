---
title: "Zero trust, SASE and infrastructure as code"
description: "The old model trusted anything already inside the building. Zero trust checks every request wherever it comes from, SASE moves the controls to where the users are, and infrastructure as code makes the network a repository you can catch drifting from its source."
deck: "The old model trusted anything already inside the building"
track: "network-plus"
level: "working"
order: 610
objectives:
  - "Explain zero trust as trust moving from location to the request"
  - "Say what policy-based authentication, authorization and least privilege each contribute"
  - "Describe what SASE and SSE gather together and why"
  - "Explain infrastructure as code for networks: templates, source control and drift"
  - "Say how network infrastructure as code differs from the server kind"
prerequisites: ["identity-and-access-management", "network-segmentation"]
tags: ["network-plus", "networking", "security", "modern"]
updated: 2026-08-15
draft: false
examObjectives:
  - exam: "n10-009"
    domain: "1.0"
    objective: "1.8"
sources:
  - title: "NIST SP 800-207, Zero Trust Architecture"
    url: "https://csrc.nist.gov/pubs/sp/800/207/final"
    publisher: "NIST"
    accessed: 2026-08-15
    tier: 1
  - title: "git(1)"
    url: "https://git-scm.com/docs/git"
    publisher: "Git project"
    accessed: 2026-08-15
    tier: 1
  - title: "envsubst / gettext"
    url: "https://www.gnu.org/software/gettext/manual/gettext.html"
    publisher: "GNU project"
    accessed: 2026-08-15
    tier: 1
symptoms:
  - symptom: "A device inside the network is trusted to reach things it should not"
    anchor: "zero-trust-trust-moves-from-place-to-request"
  - symptom: "A device configuration has diverged from its written source"
    anchor: "infrastructure-as-code-and-the-drift-it-catches"
---

> **Before you read.** For twenty years the model was a hard perimeter and a soft
> inside: a firewall at the edge, and once you were past it you were trusted. Then
> the users left the building to work from home, the applications moved to a cloud
> in someone else's building, and the attacker who phished one laptop was suddenly
> inside the trusted network with everyone else.
>
> **When there is no inside anymore, what does the trust attach to instead?**

This topic is the modern-environment objective, and its three parts share one
thread: the assumptions the old network was built on, that there is an inside and
that a configuration is what you last typed, both stopped being safe, and each part
here is a response to one of them.

### Some words you will need

<dl class="terms">
<dt>zero trust</dt>
<dd>An approach where no request is trusted for being inside the network. Each one is authenticated and authorised on its own.</dd>
<dt>least privilege</dt>
<dd>Granting the minimum access a request needs, so a compromise reaches as little as possible.</dd>
<dt>SASE</dt>
<dd>Secure access service edge: networking and security delivered together from the provider's edge, near the user.</dd>
<dt>SSE</dt>
<dd>Security service edge: the security half of that, without the networking.</dd>
<dt>infrastructure as code</dt>
<dd>Defining the network in files that are the source of truth, applied by tools and kept under version control.</dd>
<dt>drift</dt>
<dd>The gap that opens when a running configuration is changed by hand and no longer matches its source.</dd>
</dl>

## What breaks without this

**A compromised laptop inside is trusted like everything inside.** The perimeter
model grants access by location, so an attacker who reaches the inside inherits the
inside's trust, which is topic 54's zone trap stated as a whole architecture.

**The controls are in the wrong building.** When users and applications are both
outside the old perimeter, routing everything back through it to be inspected is slow
and pointless, and not routing it back means it is not inspected at all.

**The configuration and its description drift apart.** A device changed by hand no
longer matches the document that claims to describe it, and topic 53's audit failure
follows: the policy is right and the device is not.

## Zero trust: trust moves from place to request

The perimeter model trusted by location. Inside the firewall was trusted, outside was
not, and the whole security posture rested on the boundary holding. Zero trust removes
the assumption that being inside means anything. Every request is authenticated and
authorised on its own merits, wherever it comes from, and a request from a machine on
the internal network is treated exactly like one from the internet.

<figure class="learn-figure">
<svg viewBox="0 0 720 300" role="img" aria-labelledby="zt-title" style="width:100%;height:auto;">
<title id="zt-title">The perimeter model trusting a device for being inside the wall, next to zero trust checking identity and policy on every request regardless of where it comes from</title>
<g fill="currentColor">
<text x="14" y="20" font-size="11">the perimeter trusted where you were; zero trust checks who you are, every time</text>
<text x="24" y="48" font-size="10.5">the perimeter model</text>
<rect x="24" y="58" width="316" height="150" rx="6" fill="currentColor" fill-opacity="0.03" stroke="currentColor" stroke-opacity="0.7"/>
<text x="36" y="76" font-size="9.5" fill-opacity="0.75">inside the wall: trusted</text>
<rect x="44" y="92" width="120" height="34" rx="3" fill="var(--red)" fill-opacity="0.18" stroke="var(--red)" stroke-width="1.8"/>
<text x="104" y="113" text-anchor="middle" font-size="10" fill="var(--red)">phished laptop</text>
<rect x="200" y="92" width="120" height="34" rx="3" fill="currentColor" fill-opacity="0.1" stroke="currentColor" stroke-opacity="0.7"/>
<text x="260" y="113" text-anchor="middle" font-size="10">server</text>
<path d="M 164 109 H 200" stroke="var(--red)" stroke-width="2" fill="none"/>
<path d="M 192 104 l 8 5 l -8 5" stroke="var(--red)" stroke-width="2" fill="none"/>
<text x="36" y="180" font-size="9.5" fill="var(--red)">once inside, it reaches the server freely</text>
<text x="404" y="48" font-size="10.5">zero trust</text>
<rect x="380" y="92" width="120" height="34" rx="3" fill="currentColor" fill-opacity="0.12" stroke="currentColor" stroke-opacity="0.7"/>
<text x="440" y="113" text-anchor="middle" font-size="10">any device</text>
<rect x="586" y="92" width="120" height="34" rx="3" fill="currentColor" fill-opacity="0.1" stroke="currentColor" stroke-opacity="0.7"/>
<text x="646" y="113" text-anchor="middle" font-size="10">server</text>
<circle cx="543" cy="109" r="22" fill="var(--accent)" fill-opacity="0.16" stroke="var(--accent)" stroke-width="2"/>
<path d="M 535 109 l 5 5 l 11 -12" stroke="var(--accent)" stroke-width="2" fill="none"/>
<text x="543" y="150" text-anchor="middle" font-size="9.5" fill="var(--accent)">verify identity,</text>
<text x="543" y="163" text-anchor="middle" font-size="9.5" fill="var(--accent)">apply policy</text>
<path d="M 500 109 H 519" stroke="currentColor" stroke-opacity="0.7" stroke-width="1.4" fill="none"/>
<path d="M 567 109 H 586" stroke="currentColor" stroke-opacity="0.7" stroke-width="1.4" fill="none"/>
<text x="380" y="196" font-size="9.5" fill-opacity="0.8">location grants nothing; every request is checked</text>
</g></svg>
<figcaption>On the left the trust is in the wall: the phished laptop is inside it, so it reaches the server freely, and the boundary that was supposed to protect the server is on the wrong side of the attacker. On the right there is no inside to be on. Every request from any device is authenticated and checked against policy at the resource, so a compromised machine on the internal network has gained nothing from its location, because location is not what grants access. The check is per request, which is the cost and the point.</figcaption>
</figure>

Three ideas make it work, and the exam names them. **Policy-based authentication and
authorisation** means access is decided per request against a policy, using the
identity, the device's state, and the sensitivity of what is asked for, rather than
against a position on the network. **Authorisation** is kept separate from
authentication, because proving who you are is not the same as being allowed to do a
particular thing, and zero trust checks both every time. And **least privilege** is the
principle underneath: each request is granted the minimum it needs, so that a
compromised identity, when it comes, reaches as little as possible.

<details class="deeper">
<summary>If you already work on networks: why the perimeter model failed rather than was abandoned</summary>

The perimeter model was not a mistake that got corrected. It was a reasonable design
for a network whose users and servers were all in one building, and it stopped fitting
because that stopped being true, in three specific ways.

The users left. Remote and mobile work put the people outside the perimeter, so the
firewall they were meant to sit behind was now between them and their own applications.
The workaround was to VPN everyone back inside, which reintroduces the flat trusted
inside at scale and routes all traffic through one chokepoint for inspection.

The applications left. When the servers moved to cloud, the thing the perimeter
protected was outside the perimeter too, so there was nothing left in the middle for the
wall to enclose. Backhauling cloud-bound traffic through a corporate firewall to inspect
it adds latency to reach a destination that was never inside.

And the inside turned out to be reachable. Phishing, from topic 57, and the lateral
movement segmentation limits, from topic 55, both showed that an attacker gets inside
routinely, and once the inside is assumed hostile, trusting it by location is the one
thing you cannot do. NIST SP 800-207 is the standing description of the alternative, and
its core assertion is exactly this: the network is always assumed hostile, so trust is
never granted by network position.

Zero trust is the design for the network that actually exists, where the users are
outside, the applications are outside, and the inside cannot be assumed clean. The
perimeter did not fail as an idea; the network it described went away.

</details>

## SASE: the controls move to the user

If the users and the applications are both outside the old perimeter, the controls
should be too, and that is what SASE is. It gathers the networking and the security
functions together and delivers them from the provider's edge, close to where the user
actually is, so traffic is inspected and policy is applied near the user rather than
after a detour back to a corporate building.

The exam spells the acronym out, and it is worth getting right because the objectives
text and the industry disagree. The industry term, and the one to learn, is **secure
access service edge**. CompTIA's objective 1.8 writes it as "secure access secure edge",
so a question may use either wording; the expansion to know is the first. The related
term the exam also lists is **security service edge**, SSE, which is the security half of
SASE without the networking part, for organisations that want the security functions
delivered from the edge but keep their own networking.

The thread back to zero trust is direct: SASE is a common way to deliver zero trust,
because checking every request against policy is far easier when the checkpoint is a
service near the user that all traffic already flows through, rather than a box in a
building the user no longer visits.

<details class="deeper">
<summary>If you already evaluate this: what moving the controls to a provider actually changes</summary>

Delivering the controls from a provider's edge solves a real problem and it moves several
things at once, which is worth separating before signing anything.

What genuinely improves is the path. A user in another country reaching a service in a
third no longer takes a detour through your data centre to be inspected, which removes
latency that was pure overhead and removes the concentrator capacity problem from topic
50's panel.

What changes rather than improves is where the trust sits. The provider now terminates and
inspects traffic that used to be inspected by equipment you owned, which means their
availability is your availability and their handling of your data is your exposure. That is
a reasonable trade and it is a trade, and the questions that follow are ordinary supplier
questions: what happens when their edge is down, where is the traffic decrypted, and what
do they retain.

What does not change at all is the identity work. The model depends on knowing who the user
is and what they are entitled to, which comes from your directory and your access policies,
and a provider cannot supply either. Organisations that buy this expecting it to deliver
zero trust discover that they have bought the enforcement point and still owe the policy,
which is the larger half of the job.

</details>

## Infrastructure as code, and the drift it catches

The last part answers the second broken assumption: that a configuration is whatever
you last typed on the device. Infrastructure as code makes the source of truth a set of
files, applied by tools, kept under version control, so the network's state is
described in one place with a history rather than living only on the devices.

The lab builds the smallest honest version of this: a switch configuration expressed as
a template plus a file of values, in a git repository, with a script to apply it and a
script to detect drift. The setup is
[`net-iac.sh`](https://github.com/rlwilliamson-dev/azure-resume/blob/main/blog/scripts/setups/net-iac.sh).
Start with the source of truth being a repository, where every change is a commit with
an author and a reason.

```bash
# Debian 13 (trixie), x86_64
$ git -C /srv/net-iac log --oneline
e04b1d2 Add guest VLAN 40 to the access trunk for the lobby rollout
58d35cf Access switch config as code: hq VLANs and uplink trunk
```

Two commits, and each is a network change somebody made on purpose and explained. The
configuration itself is a template, with a placeholder for every value that varies, so
the same template renders a different site by changing the file of values rather than by
editing the configuration.

```bash
# Debian 13 (trixie), x86_64
$ cat /srv/net-iac/switch.tmpl
# Managed by net-iac. Changes made on the device will be reverted.
hostname ${SITE}-access-01
vlan ${USERS_VID} name users
vlan ${VOICE_VID} name voice
vlan ${GUEST_VID} name guest
vlan ${MGMT_VID} name mgmt
interface ${UPLINK}
  description uplink-to-core
  switchport mode trunk
  switchport trunk allowed vlan ${USERS_VID},${VOICE_VID},${GUEST_VID},${MGMT_VID}
```

Now the property that makes it worth the trouble. The deployed configuration can be
compared against what the source says it should be, and when somebody changes a device
by hand, the difference is found rather than forgotten.

<details class="predict">
<summary>Somebody logs into a switch and widens a trunk by hand, telling nobody. What does the next drift check say, and what does it take to put it back?</summary>

```bash
# Debian 13 (trixie), x86_64
$ cd /srv/net-iac
# the deployed configuration matches source
./drift.sh
echo
# someone logs into the switch and widens the trunk by hand, off the record
sed -i "s/allowed vlan .*/allowed vlan 1-4094/" running/switch.cfg
# the next drift check finds it
./drift.sh
echo "drift check exit status: $?"
echo
# re-applying from source puts it back, and nobody had to remember what changed
./render.sh
./drift.sh
no drift: the deployed configuration matches source

DRIFT: the deployed configuration does not match source
--- running/switch.cfg	2026-08-15 23:14:41.814973221 +0000
+++ /tmp/intended.cfg	2026-08-15 23:14:41.867973225 +0000
@@ -7,4 +7,4 @@
 interface ge-0/0/48
   description uplink-to-core
   switchport mode trunk
-  switchport trunk allowed vlan 1-4094
+  switchport trunk allowed vlan 10,20,40,99
drift check exit status: 1

rendered running/switch.cfg from source at commit e04b1d2
no drift: the deployed configuration matches source
```

</details>

Read the middle of that in order. The deployed configuration matched source. Somebody
logged into the switch and widened the trunk to carry every VLAN, which is a real
security regression made by hand and off the record. The drift check found it, showed
exactly the line that changed, and returned a non-zero status that a pipeline would fail
on. Re-applying from source put it back, and at no point did anyone have to remember what
the manual change was, because the source already knew what the answer should be.

That is topic 53's policy-versus-configuration gap, closed. The written source and the
running device are reconciled by a command that reads the device, so drift is a thing you
detect on a schedule rather than a thing an auditor finds for you.

<details class="deeper">
<summary>If you already work on networks: how network infrastructure as code differs from the server kind</summary>

The idea is borrowed from server automation, and two differences matter when it is
applied to networks rather than to hosts.

The first is that you usually cannot run an agent on the thing being configured. A server
can run a configuration-management agent that converges it to the desired state from the
inside. A switch, a router or a cloud security group frequently cannot, so network
infrastructure as code tends to push configuration in over a management protocol or an
API from outside, and to detect drift by reading the device back and comparing, which is
exactly what the lab's drift check does. The convergence is external, which makes the
read-and-compare step more central than it is on a server.

The second is that the blast radius of an apply is different. A bad change pushed to a
fleet of servers degrades those servers. A bad change pushed to the network can remove
the path you are pushing over, locking you out of every device at once, which is the
network equivalent of sawing off the branch you are sitting on. That is why network
automation leans harder on staged rollouts, on validating a change before applying it,
and on a way back that does not depend on the network the change might break.

Both differences point the same way. Network infrastructure as code puts more weight on
reading the current state and comparing it to the intended one, and on applying changes
carefully, than the server version does, because the device is less able to fix itself
and more able to cut you off.

</details>

## Prove it

The three captures are the whole of it, from
[`net-iac.sh`](https://github.com/rlwilliamson-dev/azure-resume/blob/main/blog/scripts/setups/net-iac.sh).
The point is not the toy configuration; it is that the state has one written source with
a history, that changes are commits, and that a machine can tell you when a device has
stopped matching the source.

**NIST SP 800-207.** The zero trust architecture document, free, and the standing
definition rather than any vendor's product. Read the core tenets and answer one
question: does it say the internal network should be trusted? The answer, that the network
is always assumed hostile, is the whole argument on this page stated by the body that
defined the term.

## What trips people up

### 1. Thinking zero trust is a product

It is an approach: trust nothing for its location, check every request. Products help
deliver it, and none of them is zero trust on its own, which is why the standing
definition is a NIST document rather than a datasheet.

### 2. Confusing authentication with authorisation

Authentication proves who is asking; authorisation decides whether they may do this
particular thing. Zero trust checks both, every request, because proving identity is not
permission.

### 3. Getting the SASE expansion wrong

The term is secure access service edge. CompTIA's objective writes it as secure access
secure edge, so either wording may appear, but the industry expansion is the one to know,
and SSE is the security half without the networking.

### 4. Treating infrastructure as code as automation only

The automation is half of it. The other half is that the files are the source of truth
under version control, which is what makes drift detectable and changes attributable. A
script that pushes config without a source of truth is automation without the code part.

### 5. Assuming an apply is the risky operation

On a network, reading and comparing is where the value is, and an apply can cut off the
path you are managing over. Network infrastructure as code weights drift detection and
careful rollout more heavily than the server kind for that reason.

### 6. Believing zero trust removes the need for segmentation

It does not. Least privilege and per-request checking sit on top of segmentation, which
still limits what a granted request can reach. The two compose; neither replaces the
other.

## Work it through

The network with no inside, and where each part fits.

First, stop trusting location, because the scenario at the top removed the thing that
made location meaningful. The users and applications are outside the old perimeter and the
inside cannot be assumed clean, so access has to attach to the request: authenticated,
authorised, and least-privileged, every time. That is zero trust, and it is the response
to the perimeter going away rather than a product to buy.

Then move the controls to where the traffic is, which for a distributed workforce means a
service at the edge near the users rather than a box in a building they no longer enter.
That is what SASE gathers together, and it is the practical way most organisations deliver
the per-request checking zero trust asks for.

Then make the network's state something you can reason about, because a per-request policy
spread across many devices and cloud security groups is exactly the kind of configuration
that drifts. Put it under version control as templates and values, apply it from source,
and check for drift on a schedule, so the gap between the policy and the devices is found
by you rather than by an auditor.

Then keep the earlier controls, because none of this replaces them. Segmentation still
limits blast radius, filtering still applies, and hardening still closes the easy doors.
Zero trust, SASE and infrastructure as code are the layer the modern network adds on top of
the one this block already built, not a substitute for it.

## Try it

**Run the drift lab and change the device by hand.** Edit `running/switch.cfg` in the
container built by
[`net-iac.sh`](https://github.com/rlwilliamson-dev/azure-resume/blob/main/blog/scripts/setups/net-iac.sh)
and run `./drift.sh`. Watching it name the exact line that changed is what makes drift
detection concrete.

**Add a value and render a second site.** Change the values file, run `./render.sh`, and
watch the same template produce a different configuration. That is the templating half of
infrastructure as code in one command.

**Read NIST SP 800-207's tenets.** They are a short list, and reading them is the fastest
way to see that zero trust is a set of principles about not trusting the network, not a
box you install.

## Check yourself

<details class="qa">
<summary>What does zero trust change about how access is granted?</summary>

It moves trust from location to the request. The perimeter model granted access by
position: inside the firewall was trusted. Zero trust grants nothing for being inside and
authenticates and authorises every request on its own, using identity, device state and
what is being asked for, wherever the request comes from.

A request from the internal network is treated exactly like one from the internet, so a
compromised machine gains nothing from its location, because location is no longer what
grants access.

</details>

<details class="qa">
<summary>Why did the perimeter model stop fitting?</summary>

Because the network it described went away. The users left the building to work remotely,
the applications moved to cloud, and the inside turned out to be reachable through
phishing and lateral movement. The wall was left with the users outside it, the
applications outside it, and an inside that could not be assumed clean.

Zero trust is the design for that network: it assumes the network is always hostile, which
NIST SP 800-207 states directly, so trust is never granted by network position. The
perimeter was a reasonable design for a network that no longer exists.

</details>

<details class="qa">
<summary>What is the difference between SASE and SSE?</summary>

SASE, secure access service edge, delivers networking and security together from the
provider's edge, near the user. SSE, security service edge, is the security half of that
without the networking, for organisations that want edge-delivered security but keep their
own networking.

The expansion to know is secure access service edge; CompTIA's objective text writes it as
secure access secure edge, so a question may use either wording.

</details>

<details class="qa">
<summary>What makes something infrastructure as code rather than just a script?</summary>

That the files are the source of truth, under version control, and the running state is
kept reconciled with them. A script that pushes configuration is automation; it becomes
infrastructure as code when the configuration lives in versioned files that are the
authority, so changes are commits with an author and a reason and drift from them is
detectable.

The lab shows the difference: the git history makes every change attributable, and the
drift check compares the device against the source and fails when they disagree.

</details>

<details class="qa">
<summary>Why does network infrastructure as code lean on drift detection more than the server kind?</summary>

Because a network device usually cannot run an agent that converges it from the inside, so
the configuration is pushed from outside and the only way to know it still matches is to
read the device back and compare. The read-and-compare step is more central than on a
server that can fix itself.

The risk profile reinforces it: a bad apply can remove the path you manage the device over
and lock you out of the whole fleet, so network automation weights careful, staged rollout
and drift detection more heavily than server automation does.

</details>

## References

- [NIST SP 800-207](https://csrc.nist.gov/pubs/sp/800/207/final) - NIST, the zero trust architecture document and the standing, vendor-neutral definition the page relies on. Free. Accessed 2026-08-15.
- [git(1)](https://git-scm.com/docs/git) - Git project, the version control that makes the network's changes attributable in the lab. Free. Accessed 2026-08-15.
- [GNU gettext](https://www.gnu.org/software/gettext/manual/gettext.html) - GNU project, the manual for `envsubst`, the template renderer the lab uses. Free. Accessed 2026-08-15.

**Where the numbers came from.** Every terminal block is from
[`net-iac.sh`](https://github.com/rlwilliamson-dev/azure-resume/blob/main/blog/scripts/setups/net-iac.sh)
run through `capture.sh` in a Debian container, named in each block's header. The
configuration is a deliberately vendor-neutral template rather than one switch's syntax,
the two commits and their dates are the lab's own, and the manual change that produces the
drift is a trunk widened to every VLAN, chosen because it is exactly the kind of quiet,
dangerous change drift detection exists to catch. Zero trust and SASE carry no capture,
because both are approaches rather than commands.

**If you also work on Linux.** The whole lab is ordinary Linux tools: `git` for the source
of truth, `envsubst` from gettext for the templating, and `diff` for the drift check. The
same pattern applied to a real device swaps the rendered file for a push over an API and the
`diff` for a read-back, but the shape, source in version control reconciled against running
state, is identical.
