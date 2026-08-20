---
title: "Network segmentation"
description: "A vending machine on the same network as the payment system. What segmentation actually enforces, which devices need a segment of their own, and why a guest network is a segmentation decision rather than a wireless one."
deck: "A vending machine on the same network as the payment system"
track: "network-plus"
level: "working"
order: 560
objectives:
  - "Say what segmentation enforces and where the enforcement lives"
  - "Name the device categories that need a segment of their own and say why"
  - "Explain what a guest network has to be isolated from"
  - "Describe how bring your own device changes what you can assume about a host"
  - "Say what blast radius means and how a segment limits it"
prerequisites: ["vlans", "acls-filtering-and-security-zones"]
tags: ["network-plus", "networking", "security", "segmentation"]
updated: 2026-08-15
draft: false
examObjectives:
  - exam: "n10-009"
    domain: "4.0"
    objective: "4.1"
sources:
  - title: "NIST SP 800-125B, Secure Virtual Network Configuration for Virtual Machine (VM) Protection"
    url: "https://csrc.nist.gov/pubs/sp/800/125/b/final"
    publisher: "NIST"
    accessed: 2026-08-15
    tier: 1
  - title: "NIST SP 800-41 Rev. 1, Guidelines on Firewalls and Firewall Policy"
    url: "https://csrc.nist.gov/pubs/sp/800/41/r1/final"
    publisher: "NIST"
    accessed: 2026-08-15
    tier: 1
  - title: "nft(8)"
    url: "https://www.netfilter.org/projects/nftables/manpage.html"
    publisher: "netfilter project"
    accessed: 2026-08-15
    tier: 1
symptoms:
  - symptom: "A device with no security updates is reachable from the whole network"
    anchor: "the-devices-that-need-a-segment-of-their-own"
  - symptom: "Guest wireless clients can reach internal systems"
    anchor: "guests-and-devices-you-do-not-control"
---

> **Before you read.** A retailer's card terminals, the corporate laptops and a
> vending machine with a network port are all on the same network. The vending
> machine runs software that stopped receiving updates four years ago, and it has
> a supplier support account whose password is printed in a manual.
>
> Nobody did anything wrong. The vending machine needed a network connection and
> there was one available.
>
> **What has the network handed to whoever compromises the vending machine?**

Segmentation is the answer to that question, and the reason it gets its own topic
rather than a paragraph in the VLAN one is that the mechanism and the purpose are
different subjects. Topic 16 built the mechanism. This is about what it is for.

### Some words you will need

<dl class="terms">
<dt>segment</dt>
<dd>A part of the network separated from the rest, so that reaching across the boundary is a decision somebody made rather than the default.</dd>
<dt>blast radius</dt>
<dd>How much of the network one compromised device gives an attacker access to.</dd>
<dt>east-west traffic</dt>
<dd>Traffic between systems inside the network, as opposed to traffic in and out of it.</dd>
<dt>guest network</dt>
<dd>A segment for visitors, which should reach the internet and nothing of yours.</dd>
<dt>BYOD</dt>
<dd>Bring your own device. Hardware on your network that you do not own, patch or control.</dd>
<dt>microsegmentation</dt>
<dd>Segmentation taken down to the individual workload, so policy is written per machine rather than per network.</dd>
</dl>

## What breaks without this

**One weak device is access to everything.** The vending machine is not the
target. It is the way in, and on a flat network the way in is also the way to
everything else.

**Traffic between internal systems is unexamined.** Most filtering effort goes on
the boundary with the internet, and most movement after a compromise is sideways,
between systems that were never expected to talk and were never stopped.

**Compliance scope covers the whole estate.** Topic 53's point, arriving from the
other direction: a flat network puts every device in the audit, because every
device can reach the regulated data.

## What segmentation actually enforces

The word makes it sound like tidiness, as though the point were a neat diagram
with the printers in one box and the servers in another. It is not about tidiness.
It is about turning reachability from a default into a decision.

On a flat network, any device can open a connection to any other. Nobody chose
that; it is just what a single broadcast domain with one address range does.
Segmentation breaks the network into parts and puts a filtering point between
them, so that a connection from one part to another happens only if a rule allows
it. The enforcement lives at that point, which is a router or a firewall, and the
rule is exactly the kind of access list topic 54 was about.

That is the whole mechanism, and the reason it matters is a word: containment. A
compromised device can reach what its segment can reach, and no more. The vending
machine on its own segment is still a weak device with a bad password, and when
somebody takes it over they get a vending machine and a path to the internet,
which is what it was allowed, and not the card database, which it never was.

<figure class="learn-figure">
<svg viewBox="0 0 720 300" role="img" aria-labelledby="seg-title" style="width:100%;height:auto;">
<title id="seg-title">A compromised device on the iot segment able to reach the internet through the filter but not the payment segment, its blast radius limited to its own segment plus what policy allows out</title>
<g fill="currentColor">
<text x="14" y="20" font-size="11">what a compromised device can reach is its segment, plus what the filter lets out</text>
<rect x="14" y="70" width="176" height="150" rx="5" fill="currentColor" fill-opacity="0.04" stroke="currentColor" stroke-opacity="0.6"/>
<text x="24" y="90" font-size="10.5">iot segment</text>
<rect x="28" y="104" width="148" height="30" rx="3" fill="var(--red)" fill-opacity="0.2" stroke="var(--red)" stroke-width="2"/>
<text x="102" y="123" text-anchor="middle" font-size="10" fill="var(--red)">vending machine</text>
<text x="102" y="150" text-anchor="middle" font-size="9.5" fill="var(--red)" fill-opacity="0.9">compromised</text>
<rect x="28" y="166" width="148" height="26" rx="3" fill="currentColor" fill-opacity="0.08" stroke="currentColor" stroke-opacity="0.7"/>
<text x="102" y="183" text-anchor="middle" font-size="10">another iot device</text>
<text x="24" y="212" font-size="9.5" fill-opacity="0.75">both reachable: same segment</text>
<circle cx="300" cy="150" r="34" fill="currentColor" fill-opacity="0.06" stroke="currentColor" stroke-opacity="0.7"/>
<path d="M 289 143 h 22 M 300 137 l 8 6 l -8 6 M 289 157 h 22 M 300 163 l -8 -6 l 8 -6" stroke="currentColor" stroke-opacity="0.8" stroke-width="1.4" fill="none"/>
<text x="300" y="205" text-anchor="middle" font-size="10">router and filter</text>
<rect x="470" y="52" width="176" height="74" rx="5" fill="currentColor" fill-opacity="0.04" stroke="currentColor" stroke-opacity="0.6"/>
<text x="480" y="72" font-size="10.5">payment segment</text>
<rect x="484" y="84" width="148" height="30" rx="3" fill="currentColor" fill-opacity="0.1" stroke="currentColor" stroke-opacity="0.7"/>
<text x="558" y="103" text-anchor="middle" font-size="10">card database</text>
<rect x="470" y="176" width="176" height="60" rx="5" fill="currentColor" fill-opacity="0.04" stroke="currentColor" stroke-opacity="0.6"/>
<text x="480" y="196" font-size="10.5">the internet</text>
<text x="480" y="220" font-size="10" fill-opacity="0.8">what it is there for</text>
<path d="M 176 119 C 240 119 250 150 266 150" stroke="var(--red)" stroke-width="2" fill="none"/>
<line x1="352" y1="120" x2="400" y2="100" stroke="var(--red)" stroke-width="2"/>
<line x1="378" y1="96" x2="396" y2="104" stroke="var(--red)" stroke-width="2"/>
<line x1="396" y1="96" x2="378" y2="104" stroke="var(--red)" stroke-width="2"/>
<text x="404" y="150" font-size="10" fill="var(--red)">blocked: not on its segment, no rule allows it</text>
<path d="M 334 158 C 380 175 420 200 466 205" stroke="currentColor" stroke-opacity="0.65" stroke-width="1.6" fill="none"/>
<path d="M 458 200 l 10 6 l -11 3" stroke="currentColor" stroke-opacity="0.65" stroke-width="1.6" fill="none"/>
<text x="352" y="250" font-size="10" fill-opacity="0.8">allowed: policy lets this segment reach the internet</text>
</g></svg>
<figcaption>The vending machine is compromised and the network decides what that is worth. It reaches the other device on its own segment, because a segment is a broadcast domain and nothing filters inside one. It reaches the internet, because that is the access the machine was given on purpose. It does not reach the payment segment, because that crosses the filter and no rule permits it. The blast radius is the segment plus whatever policy allows out of it, which is the number segmentation exists to make small.</figcaption>
</figure>

<details class="deeper">
<summary>If you already segment: why the boundary has to be somewhere traffic cannot avoid</summary>

Turning reachability into a decision only works if every path passes the thing making the
decision, and that is easier to state than to arrange.

The common failure is a second path nobody counted. Two segments separated by a firewall
and also connected by a switch that trunks both VLANs. A server with an interface in each
segment because somebody needed it to reach both. A management network that touches
everything by design. A wireless network bridged to the wrong VLAN. Each of these is a way
around the boundary, and each was added by somebody solving a real problem.

Which is why a segmentation design needs to be verifiable rather than declared. The check
is to test reachability from inside each segment to the things it should not reach, which
topic 55's own captures do, and to repeat it after changes rather than once at build time.
A boundary that was correct when it was built and has three bypasses now is common, and
nothing about the firewall's configuration reveals them.

The related discipline is to keep the number of boundaries small enough to test. Segmenting
into forty zones sounds thorough and produces a policy nobody can verify, which is weaker
in practice than six zones somebody checks quarterly.

</details>

## Prove it

The lab builds three segments off one router: payment, iot and corporate, each on
its own subnet and broadcast domain, with an nftables policy on the router whose
default is to drop. The topology is
[`segmented-lan.sh`](https://github.com/rlwilliamson-dev/azure-resume/blob/main/blog/scripts/topologies/segmented-lan.sh).

Start on the iot segment, as the compromised vending machine, and try to reach
the things around it.

<details class="predict">
<summary>A vending machine on the IoT segment tries three destinations: the payment host, the internet, and the corporate segment. Which of the three does it reach?</summary>

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology segmented-lan
# commands run on iot
# the vending machine is on the iot segment. can it reach the payment host?
$ ping -c1 -W1 10.10.0.9
PING 10.10.0.9 (10.10.0.9) 56(84) bytes of data.

--- 10.10.0.9 ping statistics ---
1 packets transmitted, 0 received, 100% packet loss, time 0ms

$ echo "reaching payment: exit status $?"
reaching payment: exit status 1

# and the internet, which is what it is there to do?
$ ping -c1 -W1 203.0.113.9
PING 203.0.113.9 (203.0.113.9) 56(84) bytes of data.
64 bytes from 203.0.113.9: icmp_seq=1 ttl=63 time=0.152 ms

--- 203.0.113.9 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 0.152/0.152/0.152/0.000 ms
$ echo "reaching the internet: exit status $?"
reaching the internet: exit status 0

# and the corporate segment?
$ ping -c1 -W1 10.30.0.9
PING 10.30.0.9 (10.30.0.9) 56(84) bytes of data.

--- 10.30.0.9 ping statistics ---
1 packets transmitted, 0 received, 100% packet loss, time 0ms

$ echo "reaching corp: exit status $?"
reaching corp: exit status 1
```

</details>

The payment segment is unreachable and the internet is not, from the same host,
in the same second, with nothing changed between the attempts. The exit statuses
are the whole story: the machine has exactly the access it was given and none it
was not.

Now the same payment host, approached from the corporate segment, where a rule
does permit it.

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology segmented-lan
# commands run on corp
# the same payment host, from the corporate segment
$ ping -c1 -W1 10.10.0.9
PING 10.10.0.9 (10.10.0.9) 56(84) bytes of data.
64 bytes from 10.10.0.9: icmp_seq=1 ttl=63 time=0.090 ms

--- 10.10.0.9 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 0.090/0.090/0.090/0.000 ms
$ echo "reaching payment: exit status $?"
reaching payment: exit status 0
```

So the boundary is not a wall, it is a policy. Corporate reaches payment because
somebody wrote that rule; iot does not because nobody did. The filter that decides
both is one short list.

<details class="predict">
<summary>The policy that produced those three results, printed in full. How many rules does it take to say what may reach the payment segment?</summary>

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology segmented-lan
# commands run on rtr
$ nft list ruleset
table inet seg {
	chain forward {
		type filter hook forward priority filter; policy drop;
		ct state established,related accept
		ip saddr 10.30.0.0/24 ip daddr 10.10.0.0/24 accept comment "corp may reach payment"
		ip daddr 203.0.113.0/24 accept comment "any segment may reach the internet"
	}
}
```

</details>

Three lines and a default. The default is the implicit deny from topic 54, and it
is doing most of the work here: iot cannot reach payment not because a rule
forbids it but because no rule allows it, which is the safer way for a boundary to
fail.

<details class="deeper">
<summary>If you already work on networks: the broadcast domain is a segment boundary the filter never sees</summary>

The router policy is the segmentation a reader thinks of first, and there is a
second boundary underneath it that the policy has nothing to do with. A segment is
a broadcast domain, and a broadcast does not cross a router, so the reach of
anything that works by broadcasting is the segment and stops there.

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology segmented-lan
# commands run on iot
# a broadcast on the iot segment, every reply for a second. no router forwards a
# broadcast, so the payment and corporate segments cannot appear here
$ ping -b -w1 10.20.0.255
WARNING: pinging broadcast address
PING 10.20.0.255 (10.20.0.255) 56(84) bytes of data.
64 bytes from 10.20.0.9: icmp_seq=1 ttl=64 time=0.017 ms
64 bytes from 10.20.0.1: icmp_seq=1 ttl=64 time=0.116 ms
64 bytes from 10.20.0.99: icmp_seq=1 ttl=64 time=0.116 ms

--- 10.20.0.255 ping statistics ---
1 packets transmitted, 1 received, +2 duplicates, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 0.017/0.083/0.116/0.046 ms
```

Three replies, from the three devices on the iot segment, to a broadcast the
attacker sent. The payment host cannot appear in that list at any policy, because
the broadcast never reaches the router's far side. That matters for a specific
class of attack: address resolution poisoning, the discovery scans a worm uses to
find its next host, and the rogue services that answer broadcast requests all work
at layer two and are confined to the broadcast domain they are launched in.

Topic 56 is the detail on those attacks, and this is the containment that decides
their reach in advance. A segment is not only a filtered boundary at layer three.
It is a smaller layer-two neighbourhood, and the second property is the one that
limits attacks the filter never examines.

</details>

## The devices that need a segment of their own

The exam expects you to know which categories earn their own segment, and the
useful way to hold it is by a single question: what can you assume about this
device, and what happens to everything near it if the assumption is wrong.

**Systems that handle regulated data**, such as card payment, get a segment
because the alternative is putting the whole network in scope, which is topic 53's
argument.

**Operational technology and industrial control**, the systems that run physical
machinery, get a segment because they are frequently old, rarely patched, and
attached to something that moves in the real world. A compromise there is not a
data breach, it is a physical event.

**Devices in the internet of things category**, the cameras, sensors, badge
readers and vending machines, get a segment because they are numerous, weak, and
bought for a function rather than for security. The one in the scenario is the
whole point: it needed a connection and it should have got one that reaches
nothing of value.

**Guest and untrusted devices** get a segment because you do not control them,
which is the next section.

**Management interfaces**, the ports you configure the switches and routers from,
get a segment because a device that can reach the management plane can reconfigure
the network, and that access should be the hardest to obtain rather than the
easiest.

<details class="deeper">
<summary>If you already run these devices: why outbound matters more than inbound here</summary>

The instinct with an untrustworthy device is to stop things reaching it, and for this
category the more valuable half is the other direction.

A camera or a controller that has been compromised is a machine inside the network with a
route to everything the segment permits. Blocking inbound access protects it from being
compromised remotely and does nothing once it has been, and these are exactly the devices
most likely to be compromised by their own firmware, their own vendor's cloud service, or
somebody with physical access to them.

So the rule that earns its place is the outbound one: this segment may reach its
management server and nothing else, or may reach the internet on these ports and nothing
else. That converts a compromised camera from a foothold into a nuisance, and it is
usually easy to write because these devices genuinely do talk to very few things.

It also produces useful signal. A segment with a tight outbound policy generates denials
when something inside it starts behaving unexpectedly, and denials from a device class
that never varies are worth alerting on. That is a far better detection than anything
watching the device itself, which is a box you cannot install anything on and cannot fully
trust the logs of.

</details>

## Guests and devices you do not control

A guest network and a bring-your-own-device network are the same problem stated at
two temperatures: hosts on your network that you cannot make any assumption about.

A guest network exists so a visitor can reach the internet. That is the entire
requirement, and the entire security model follows from it: guests reach the
internet and nothing internal, and ideally guests do not reach each other either,
because a guest network is a room full of strangers and there is no reason for two
of them to talk. The failure that keeps happening is a guest network that can
reach the internal one, usually because it was built as a wireless convenience
rather than as a segment, and the wireless and the segmentation were treated as
one job when they are two.

Bring your own device is the same untrusted host with a harder edge, because it is
carrying company data and sitting on the desk of somebody who works there. You
cannot patch it, you cannot know what else it has connected to, and you cannot
assume it is not already compromised. The segment it belongs on is one that treats
it as what it is: a device that needs specific access to specific things and
should be granted exactly that and no general run of the internal network.

<details class="deeper">
<summary>If you already run a guest network: the leak that is not on the network at all</summary>

Isolating guests at layer 2 and layer 3 is the well-known part. Two paths get missed
because neither is traffic between guests.

The first is name resolution. A guest network handing out the internal resolver gives
every visitor the ability to enumerate internal names, and to see which internal services
exist, without reaching any of them. Guests want a resolver, and it should be an external
one, or an internal one configured to answer for nothing internal.

The second is everything the guests can see about each other and about the building. A
guest network without client isolation lets visitors browse each other's devices, which is
a problem you have created for them rather than for yourself and is still yours. And a
network name that reveals the organisation, on a network reachable from the car park,
is an invitation that costs nothing to remove.

The broader point is that the guest network is the one segment where the users are outside
any policy you can enforce, so every control has to be technical. There is no acceptable
use policy for somebody who is not your employee, no managed device, and no way to ask.
Anything that depends on the person behaving is not a control on a guest network.

</details>

## Prove it, again

**NIST SP 800-41.** The firewall policy guideline, and the clearest free
statement of the default-deny reasoning that makes the router policy above safe.
Read the section on policy and note that it argues for the same default the lab
uses, which is that a boundary should fail closed.

**Then read your own guest network from the wrong side.** Join it and try to
reach one internal address you know. If it answers, the guest network is a
convenience and not a segment, and the difference is the whole topic.

## What trips people up

### 1. Thinking segmentation is about tidiness

It is about containment. The neat diagram is a side effect; the point is that a
compromised device reaches only its segment and what policy allows out of it.

### 2. Filtering the boundary and ignoring the inside

Most effort goes on traffic in and out of the network, and most movement after a
compromise is sideways between internal systems. Segmentation is where you filter
the inside.

### 3. Building a guest network as a wireless feature

A guest network is a segment that happens to be wireless. If it can reach the
internal network, it was built as a convenience and the isolation was never there.

### 4. Trusting a device because it belongs to an employee

A bring-your-own device is an untrusted host you cannot patch or inspect. Being on
somebody's desk does not make it safe, and the segment it sits on should assume it
is not.

### 5. Leaving the management plane reachable

The interfaces you configure the network from are the highest-value target on it.
They belong on their own segment, reachable from the fewest places, not on the
same network as the users.

### 6. Assuming a subnet is a segment

A subnet is an address range. It becomes a segment only when something enforces the
boundary. Two subnets on a router with no policy between them are fully reachable
to each other.

## Work it through

The vending machine, and the order the thinking goes in.

First, name what the device is worth as a target, which is almost nothing, and
what it is worth as a path, which on a flat network is everything. That reframing
is the whole point: the risk is not the machine, it is what the machine can reach.

Then decide what access the machine actually needs, which is the internet and a
management server for the supplier, and nothing else. Everything it does not need
is access to remove, and on a flat network there is a great deal of it.

Then put it where that access is all it has, which is a segment with a filter whose
default is deny and whose two or three permits describe exactly what it is for. The
lab's iot segment is this: it reaches the internet because a rule says so and
reaches the payment systems not at all because no rule says so.

Then check the thing that is easy to forget, which is the layer-two neighbourhood.
The machine shares a broadcast domain with whatever else is on its segment, so put
nothing there that matters, because segmentation contains the filtered paths and
the broadcast ones both, and the second is the one people leave to chance.

## Try it

**Run the lab with the corporate permit removed.** Delete the `10.30.0.0/24` rule
from
[`segmented-lan.sh`](https://github.com/rlwilliamson-dev/azure-resume/blob/main/blog/scripts/topologies/segmented-lan.sh)
and watch corporate lose the payment access it had. It is one line, and removing it
shows that every path across a segment boundary is a rule somebody chose to write.

**Draw your own network's segments and mark the weakest device.** Then ask what it
can reach. If the answer is more than it needs, you have found the work this topic
is about.

**Join a guest network and try one internal address.** The result tells you whether
it is a segment or a convenience, and it takes a minute.

## Check yourself

<details class="qa">
<summary>The vending machine has nothing worth stealing on it. Why does it need its own segment?</summary>

Because its value to an attacker is not what is on it, it is what it can reach.
It is a weak, unpatched device with a known password, which makes it an easy way
in, and on a flat network the way in is also the way to everything else.

A segment does not make the machine any less weak. It makes the compromise worth
less, because the attacker gets the machine and the access the machine was granted,
which is the internet, and not the rest of the network.

</details>

<details class="qa">
<summary>What is blast radius, and how does a segment change it?</summary>

Blast radius is how much of the network one compromised device gives an attacker.
On a flat network it is everything, because any device can reach any other.

A segment limits it to the segment plus whatever policy allows out of that segment.
The lab shows both halves: the compromised host reaches the other device on its own
segment freely, reaches the internet because a rule permits it, and reaches the
payment segment not at all because no rule does.

</details>

<details class="qa">
<summary>Why is a guest network a segmentation problem rather than a wireless one?</summary>

Because the wireless part just gets the visitor connected. What makes it a guest
network is that it reaches the internet and nothing internal, and that isolation is
enforced by a segment boundary, not by anything about the radio.

The common failure is building the wireless and treating the job as done, leaving a
guest network that can reach internal systems. The wireless and the segmentation are
two separate pieces of work, and only the second one contains the guests.

</details>

<details class="qa">
<summary>Two internal subnets are configured on a router with no filtering between them. Are they segmented?</summary>

No. They are two address ranges that can fully reach each other. A subnet becomes a
segment only when something enforces the boundary, which here would be a policy on
the router deciding what may cross.

Segmentation is the enforcement, not the addressing. Splitting the address space
without a filter between the parts gives you a tidier diagram and none of the
containment.

</details>

<details class="qa">
<summary>The router policy has no rule mentioning the iot-to-payment path, yet that path is blocked. Why?</summary>

Because the default is deny. The policy permits established replies, corporate to
payment, and any segment to the internet, and then drops everything else. The
iot-to-payment path matches none of the permits, so it falls through to the default
and is dropped.

This is the implicit deny from topic 54, and it is the safer way for a boundary to
work: a path is blocked unless somebody deliberately opened it, so a forgotten rule
leaves something closed rather than open.

</details>

## References

- [NIST SP 800-125B](https://csrc.nist.gov/pubs/sp/800/125/b/final) - NIST, on isolating workloads in virtual networks, which is segmentation applied at the level microsegmentation names. Free. Accessed 2026-08-15.
- [NIST SP 800-41 Rev. 1](https://csrc.nist.gov/pubs/sp/800/41/r1/final) - NIST, firewall policy guidance and the default-deny reasoning the lab's router policy relies on. Free. Accessed 2026-08-15.
- [nft(8)](https://www.netfilter.org/projects/nftables/manpage.html) - netfilter project, the manual for the tool that enforces the boundary in the lab. Accessed 2026-08-15.

**Where the numbers came from.** Every terminal block on this page is from
[`segmented-lan.sh`](https://github.com/rlwilliamson-dev/azure-resume/blob/main/blog/scripts/topologies/segmented-lan.sh)
run through `netlab.sh`, on the kernel named in each block's header. The addresses
are documentation ranges: 10.10.0.0/24, 10.20.0.0/24 and 10.30.0.0/24 for the three
segments, and 203.0.113.0/24 from RFC 5737 standing in for the internet. The figure
is drawn from the same topology and the reachability it shows is the reachability the
captures produce.

**If you also work on Linux.** The router here is a Linux host with `ip_forward`
on and an `nft` policy, which is a real segmentation gateway rather than a model of
one. `nft list ruleset` is the view of the whole boundary, and `policy drop` on the
forward chain is the default-deny made explicit where an audit can read it.
