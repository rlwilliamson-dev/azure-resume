---
title: "VPNs"
description: "Where the tunnel ends decides everything else. Site to site against client to site, clientless access, and why split tunnel is an argument about policy rather than a setting."
deck: "Somebody needs the finance system from a hotel"
track: "network-plus"
level: "working"
order: 510
objectives:
  - "Distinguish site to site from client to site"
  - "Say what clientless access is and what it cannot reach"
  - "Explain the trade between split tunnel and full tunnel"
  - "Say where a tunnel terminates and why that decides the rest"
  - "State what a VPN does not protect"
prerequisites: ["ip-protocols-and-tunnelling"]
tags: ["network-plus", "networking", "security"]
updated: 2026-08-13
draft: false
examObjectives:
  - exam: "n10-009"
    domain: "3.0"
    objective: "3.5"
sources:
  - title: "RFC 4301, Security Architecture for the Internet Protocol"
    url: "https://www.rfc-editor.org/rfc/rfc4301"
    publisher: "IETF"
    accessed: 2026-08-13
    tier: 1
  - title: "RFC 8446, The Transport Layer Security Protocol Version 1.3"
    url: "https://www.rfc-editor.org/rfc/rfc8446"
    publisher: "IETF"
    accessed: 2026-08-13
    tier: 1
  - title: "NIST SP 800-77 Rev. 1, Guide to IPsec VPNs"
    url: "https://csrc.nist.gov/pubs/sp/800/77/r1/final"
    publisher: "NIST"
    accessed: 2026-08-13
    tier: 1
  - title: "NIST SP 800-207, Zero Trust Architecture"
    url: "https://csrc.nist.gov/pubs/sp/800/207/final"
    publisher: "NIST"
    accessed: 2026-08-13
    tier: 1
symptoms:
  - symptom: "A video call is unusable only while connected to the VPN"
    anchor: "split-or-full"
  - symptom: "A remote user can reach one system and not another"
    anchor: "where-the-tunnel-ends"
  - symptom: "Everything on the network is reachable from one laptop in a hotel"
    anchor: "what-a-vpn-does-not-protect"
---

> **Before you read.** Somebody in a hotel needs the finance system. They connect
> to the VPN and it works.
>
> They also join a video call, which is unwatchable. They disconnect from the VPN
> and the call is fine.
>
> **What is happening, and is it a fault?**

A VPN is a tunnel with a policy attached, and almost every question about one
turns out to be a question about where it terminates and what is routed into it.

### Some words you will need

<dl class="terms">
<dt>site to site</dt>
<dd>A permanent tunnel between two networks, built by equipment, invisible to users.</dd>
<dt>client to site</dt>
<dd>A tunnel from one device into a network, brought up by a person.</dd>
<dt>clientless</dt>
<dd>Access through a browser, with no tunnel and no software installed.</dd>
<dt>concentrator</dt>
<dd>The device at the network end that terminates tunnels.</dd>
<dt>split tunnel</dt>
<dd>Only traffic for the far network goes through the tunnel.</dd>
<dt>full tunnel</dt>
<dd>Everything goes through the tunnel, including traffic for the internet.</dd>
</dl>

## What breaks without this

**A remote worker cannot reach half of what they need**, because the tunnel
terminates somewhere that can only see part of the estate.

**A video call becomes unusable** for people working remotely, and nobody
connects the two facts.

**One compromised laptop reaches everything**, because the tunnel was treated as
the security control rather than as transport.

## Where the tunnel ends

Two kinds of VPN, and the difference is who brings it up.

**Site to site** joins two networks permanently. Equipment at each end does the
work, users never know it exists, and the traffic is between the networks rather
than from any particular device. Topic 49's tunnel mode is what carries it, which
is why the private addresses of both sites sit inside.

**Client to site** joins one device to a network. Software on the laptop brings
up a tunnel to a concentrator, the laptop receives an address on the corporate
network or one reserved for remote users, and from the network's point of view it
is now a machine on the inside.

**Clientless access** is the third and it is not a tunnel at all. A user visits a
portal, authenticates, and reaches specific applications through the browser. What
they get is those applications and nothing else: no address on the network, no
route, no access to anything that is not published through the portal. That is a
real limitation and it is also the reason it is chosen, because a contractor who
needs one system should not be given a network address.

**Where the tunnel terminates decides what a user can reach**, and it is the first
question worth asking about any remote access problem. A concentrator on a
perimeter network that is filtered from the internal estate produces exactly the
report at the top of a hundred tickets: some things work and some do not, with no
apparent pattern, and the pattern is the firewall rules between the concentrator
and everything else.


<details class="deeper">
<summary>If you already run these: where the concentrator sits, and why that decides what the tunnel is worth</summary>

The tunnel's value depends almost entirely on what is behind the device that
terminates it, and that is a placement decision rather than a protocol one.

A concentrator inside the trusted network hands every connected client a position
inside it, which is the arrangement zero trust exists to argue against. A
concentrator in its own segment, with a policy between it and everything else,
means a compromised laptop reaches only what that policy allows. The protocol,
the encryption and the authentication are identical in both cases. The blast radius
is not.

The second consequence is capacity. Every tunnelled byte crosses the concentrator,
including traffic that is merely passing through on its way to the internet under a
full tunnel design, so the box has to be sized for the traffic rather than for the
user count. That is the constraint people hit first, usually the week everybody
starts working from home at once, and it is why the split against full decision is a
capacity decision as much as a policy one.

Worth knowing as well: the point where the tunnel ends is the point where traffic
becomes readable to your own monitoring. Anything you want to inspect has to pass
that point, so a design that terminates tunnels close to the edge and routes onward
without inspection has bought encryption for the client and visibility for nobody.

</details>

## Split or full

Once a device has a tunnel, something has to decide which of its traffic goes
into it. There are two answers and neither is free.

<figure class="learn-figure">
<svg viewBox="0 0 720 292" role="img" aria-labelledby="tunnel-title" style="width:100%;height:auto;">
<title id="tunnel-title">A laptop in a hotel with a split tunnel sending only company traffic through the office, against a full tunnel sending everything through it</title>
<g fill="currentColor">
<text x="14" y="22" font-size="11">which traffic goes through the office, and what that costs</text>
<text x="14" y="56" font-size="10.5" fill-opacity="0.85">split tunnel</text>
<rect x="20" y="66" width="104" height="40" rx="3" fill="currentColor" fill-opacity="0.12" stroke="currentColor" stroke-opacity="0.6"/>
<text x="72" y="91" text-anchor="middle" font-size="10.5">a laptop</text>
<rect x="300" y="66" width="110" height="40" rx="3" fill="currentColor" fill-opacity="0.12" stroke="currentColor" stroke-opacity="0.6"/>
<text x="355" y="91" text-anchor="middle" font-size="10.5">the office</text>
<line x1="124" y1="78" x2="292" y2="78" stroke="var(--accent)" stroke-width="2.2"/>
<path d="M 298 78 l -9 -5 l 0 10 z" fill="var(--accent)"/>
<text x="208" y="70" text-anchor="middle" font-size="9.5" fill="var(--accent)">company traffic</text>
<line x1="124" y1="98" x2="560" y2="98" stroke="currentColor" stroke-opacity="0.55" stroke-width="1.6"/>
<path d="M 566 98 l -9 -5 l 0 10 z" fill="currentColor" fill-opacity="0.7"/>
<text x="330" y="116" text-anchor="middle" font-size="9.5" fill-opacity="0.75">everything else, straight out of the hotel</text>
<rect x="570" y="78" width="120" height="40" rx="3" fill="currentColor" fill-opacity="0.08" stroke="currentColor" stroke-opacity="0.45"/>
<text x="630" y="103" text-anchor="middle" font-size="10.5">the internet</text>
<text x="14" y="176" font-size="10.5" fill-opacity="0.85">full tunnel</text>
<rect x="20" y="186" width="104" height="40" rx="3" fill="currentColor" fill-opacity="0.12" stroke="currentColor" stroke-opacity="0.6"/>
<text x="72" y="211" text-anchor="middle" font-size="10.5">a laptop</text>
<rect x="300" y="186" width="110" height="40" rx="3" fill="currentColor" fill-opacity="0.12" stroke="currentColor" stroke-opacity="0.6"/>
<text x="355" y="211" text-anchor="middle" font-size="10.5">the office</text>
<line x1="124" y1="206" x2="292" y2="206" stroke="var(--accent)" stroke-width="2.2"/>
<path d="M 298 206 l -9 -5 l 0 10 z" fill="var(--accent)"/>
<text x="208" y="198" text-anchor="middle" font-size="9.5" fill="var(--accent)">everything</text>
<line x1="410" y1="206" x2="560" y2="206" stroke="currentColor" stroke-opacity="0.55" stroke-width="1.6"/>
<path d="M 566 206 l -9 -5 l 0 10 z" fill="currentColor" fill-opacity="0.7"/>
<rect x="570" y="186" width="120" height="40" rx="3" fill="currentColor" fill-opacity="0.08" stroke="currentColor" stroke-opacity="0.45"/>
<text x="630" y="211" text-anchor="middle" font-size="10.5">the internet</text>
<text x="330" y="244" text-anchor="middle" font-size="9.5" fill-opacity="0.75">a video call now crosses the country twice</text>
<text x="330" y="262" text-anchor="middle" font-size="9.5" fill-opacity="0.75">and every byte is inspectable by the office</text>
</g></svg>
<figcaption>The two lines leaving the laptop are the whole decision. In a split tunnel only traffic destined for company addresses enters the tunnel and everything else takes the shortest path, which is what the hotel's own connection gives it. In a full tunnel everything goes to the office first and comes back out, so a video call between somebody in a hotel and somebody two streets away is routed through a building in another country and back, twice, which is what the report at the top of this page describes and is not a fault. What the full tunnel buys in exchange is that every byte the device sends is subject to the same filtering, inspection and logging as traffic from a desk in the office, which for a regulated organisation is not a preference. The reason this is a policy argument rather than a technical one is that both statements are true at once, and no configuration makes both of them go away.</figcaption>
</figure>

**The case for split tunnel** is performance and cost. The traffic that does not
need to go to the office does not go there, calls work, streaming works, and the
office internet connection is not carrying the personal traffic of everybody who
is out.

**The case for full tunnel** is visibility. Whatever monitoring, filtering and
logging applies inside the building also applies to the laptop in the hotel, and
there is no path from that device to the internet that the organisation cannot
see. In some industries that is a requirement rather than an argument.

**The compromise most organisations reach** is split tunnelling with an explicit
list of what must go through the tunnel, extended over time, which drifts towards
a full tunnel one exception at a time and is worth reviewing occasionally.


<details class="deeper">
<summary>If you already argue about this: the exception list, and how to keep it from becoming a full tunnel</summary>

The compromise described above drifts in one direction, and it drifts for good
reasons every time, which is what makes it hard to stop.

Each addition to the split tunnel's list is justified: an application that needs to
appear to come from the office, a supplier who filters by source address, a service
that logs access and expects internal addresses. None of them is unreasonable, and
after two years the list covers most of what anybody does, at which point the design
is a full tunnel with extra configuration and none of the visibility a full tunnel
was chosen for.

Two things keep it honest. The first is recording why each entry was added, in the
entry, so that a review can ask whether the reason still holds rather than guessing
what somebody meant. Entries added for a supplier who was replaced three years ago
are the easiest removals available and they are invisible without the note.

The second is deciding in advance what proportion of traffic would make a full
tunnel the simpler answer, and measuring against it rather than arguing about it.
When most traffic is already going through the tunnel, the split is costing
configuration and complexity while delivering little of the performance benefit that
justified it, and switching becomes a tidying exercise instead of a debate.

</details>

## What a VPN does not protect

This is the part that gets skipped and it is the part that matters.

**A VPN protects data in transit between two points.** That is the whole of what
it does. It does not protect the device at either end, it does not check that the
device is healthy, and it does not limit what the device can do once it is
connected.

**A client to site tunnel puts a laptop on the network.** If that laptop is
compromised, the malware is now on the network too, and it arrived through an
encrypted tunnel that no inspection could see into. The tunnel worked perfectly
and the outcome is worse than if the laptop had never connected.

That single observation is the argument behind everything sold as zero trust: stop
treating a network location as a credential, authenticate and authorise each
request to each application, and check the state of the device each time rather
than once at connection. NIST SP 800-207 is the document, and topic 35's
distinction between authentication and authorisation is what it is built on.

The practical version for this exam is narrower and worth carrying: **a VPN is
transport, not access control.** What a user may reach after connecting is decided
by firewall rules, by application permissions and by identity, and a design where
connecting to the VPN grants access to everything has one control doing two jobs
badly.


<details class="deeper">
<summary>If you already explain this to people: the promise a VPN did not make, and the one it quietly does</summary>

Two misunderstandings arrive together and they pull in opposite directions.

The first is that a VPN makes the user anonymous or safe. It moves the point at
which traffic joins the internet and it authenticates the endpoint, and it does
nothing about what the user then does, what the far site logs, or what is already
running on the laptop. A compromised machine on a tunnel is a compromised machine
with a route into the network, which is worse than one without. The sentence worth
having ready is that a tunnel changes where traffic appears from, not what it is.

The second is subtler and it works the other way, because a VPN does make one
promise people forget to claim. Authenticating the tunnel authenticates the device
or the user to the network, which is an identity signal available to everything
behind it and is routinely thrown away. A design that treats tunnelled clients as
anonymous once they are inside has paid for authentication and spent none of it.

Both misunderstandings have the same root, which is treating the tunnel as a place
rather than as a relationship between two endpoints. Once it is a relationship, the
questions become which endpoint, authenticated how, granted what, and those are
answerable.

</details>

## Across platforms

Every platform creates a virtual adapter for a tunnel, and each names it
differently.

**On Linux**, a tunnel appears as an interface: `tun0`, `wg0`, or an `xfrm`
interface for IPSec, and `ip link` and `ip route` show it exactly as topic 21
described.

**On macOS**, the interfaces exist before anything is configured.

<details class="predict">
<summary>A Mac with no VPN configured at all. How many tunnel interfaces does it already have, and what are they for?</summary>

```bash
# macOS 26.5.2, arm64
$ scutil --nc list 2>&1 | head -4
Available network connection services in the current set (*=enabled):

# The tunnel interfaces macOS creates, which exist whether or not you configured them
$ ifconfig | grep -E "^utun" | head -5
utun0: flags=8051<UP,POINTOPOINT,RUNNING,MULTICAST> mtu 1380
utun1: flags=8051<UP,POINTOPOINT,RUNNING,MULTICAST> mtu 1500
utun2: flags=8051<UP,POINTOPOINT,RUNNING,MULTICAST> mtu 2000
utun3: flags=8051<UP,POINTOPOINT,RUNNING,MULTICAST> mtu 1000
```

</details>

Those `utun` interfaces are created by the system for tunnelling of various kinds,
which is why a Mac with no VPN configured still has several. Their differing MTUs
are the interesting detail: each is sized for whatever wrapper it was made for.

**On Windows**, the tunnel interfaces are listed alongside the real ones and
carry their own state.

```powershell
# Microsoft Windows Server 2025 Datacenter, version 10.0.26100.0
> Get-VpnConnection -AllUserConnection -ErrorAction SilentlyContinue | Measure-Object | Select-Object -ExpandProperty Count
0

# Every adapter this machine has, hidden ones included. A client install keeps a
# set of WAN Miniport adapters permanently installed, one per tunnelling
# protocol; a server install without the remote access role does not.
> Get-NetAdapter -IncludeHidden | Select-Object -First 6 Name, InterfaceDescription, Status | Format-Table -AutoSize
Name                                  InterfaceDescription                            Status
----                                  --------------------                            ------
vEthernet (nat)                       Hyper-V Virtual Ethernet Adapter                Up
Ethernet 3                            Microsoft Hyper-V Network Adapter #3            Up
Ethernet 4                            Mellanox ConnectX-4 Lx Virtual Ethernet Adapter Up
Teredo Tunneling Pseudo-Interface                                                     Not Present
vSwitch (nat)                         Hyper-V Virtual Switch Extension Adapter        Up
Microsoft IP-HTTPS Platform Interface                                                 Not Present
```

The last two rows of that listing are tunnel pseudo-interfaces reading `Not
Present`, which is the state of a tunnelling mechanism the machine understands and
is not currently using. macOS reaches the same place differently, by keeping four
`utun` interfaces up with different MTUs, each sized for whatever wrapper it was
made for.

The practical consequence on every platform is the same, and it is the thing to
check when a VPN behaves oddly: connecting changes the routing table, and the
question of whether it is a split or full tunnel is answered by whether a default
route now points at the tunnel interface.

## Prove it

**Look at your routing table before and after connecting.** That single diff is
the split tunnel question, answered for your own organisation, in about ten
seconds.

**Find where your tunnel terminates.** Not the address you connect to, but what is
on the other side of it and what filtering sits between that and the systems you
use.

**Ask what happens if a connected laptop is compromised.** The answer describes
your actual security model rather than the one on the diagram.

## What trips people up

### 1. Treating a VPN as a security control rather than transport

It protects data between two points. It says nothing about the health of either
end, and a compromised laptop connects perfectly.

### 2. Expecting clientless access to reach everything

It publishes specific applications through a browser. There is no tunnel, no
address on the network and no route, which is a limitation and is also why it is
chosen for people who should not have one.

### 3. Reading a slow call on a full tunnel as a fault

The traffic is going to the office and back by design. That is the cost of the
visibility the full tunnel was chosen for.

### 4. Forgetting that split tunnelling drifts

Exceptions accumulate. A split tunnel with forty destinations added over three
years is worth re-examining as a design rather than extending again.

### 5. Assuming the address the user gets is on the internal network

It frequently is not. Where the concentrator sits and what filtering is between it
and the estate decides what a remote user can reach, which is why some things work
and some do not.

### 6. Confusing site to site with client to site

One is permanent, built by equipment, and invisible to users. The other is brought
up by a person and puts one device on the network.

## Work it through

The hotel, the finance system and the unwatchable video call.

Nothing is broken. The organisation runs a full tunnel, so every packet the laptop
sends goes to the office first, including the video and audio of a call whose
other participants may be nowhere near it. A call that would have taken twenty
milliseconds each way is taking several hundred, twice, and real time media is the
one workload with no tolerance for that.

**The evidence is in the routing table**, and it takes one command to confirm.
With the tunnel up, if the default route points at the tunnel interface, it is a
full tunnel and the explanation is complete.

So the question is not how to fix the call. It is which of three things the
organisation wants, and that is a decision for whoever owns the policy rather than
for whoever owns the network.

Keep the full tunnel and accept that calls are poor when people are remote, which
is a real cost and is sometimes the right answer in a regulated environment.

Split the tunnel entirely, which fixes calls and gives up visibility of everything
those laptops do that is not company traffic.

Or make an exception for the specific real time services, which is what most
organisations do, and accept that the exception list is now a thing somebody has
to maintain and that it will grow.

**One thing worth raising while the conversation is open.** If the full tunnel is
there for visibility, it is worth asking what is being done with what it sees,
because the cost is being paid by every remote user every day and the benefit is
only real if somebody is looking. Topic 40's argument about alerts that nobody
reads applies here in a different form.

## Try it

**Compare your routing table with the tunnel up and down.** The difference is the
policy, expressed in the only place it is unambiguous.

**Time a round trip both ways.** `ping` something on the internet with the tunnel
up and with it down. The difference is what a full tunnel costs, in milliseconds,
for your organisation.

**Read your own concentrator's rules.** What can a connected client reach, and is
the answer "the whole network"?

## Check yourself

<details class="qa">
<summary>A user reports that video calls are poor only while connected to the VPN. Is that a fault?</summary>

Almost certainly not. It is a full tunnel doing what it was configured to do: all
traffic goes to the office and comes back out, so a call is routed through the
corporate network in both directions regardless of where the other party is.

Real time media is the workload least tolerant of that extra distance. The
routing table confirms it in one command: with the tunnel up, the default route
points at the tunnel interface.

</details>

<details class="qa">
<summary>What is the trade between split tunnel and full tunnel?</summary>

Split tunnel sends only traffic for company addresses through the tunnel, so
everything else takes the shortest path. Calls and streaming work normally and the
office connection is not carrying anybody's personal traffic.

Full tunnel sends everything, so the same filtering, inspection and logging that
applies inside the building applies to the remote device. What it costs is
latency for everything not destined for the office, and no setting removes either
side of the trade.

</details>

<details class="qa">
<summary>What can clientless remote access reach, and why is that limitation sometimes the reason to choose it?</summary>

Only the applications published through the portal. There is no tunnel, so the
device receives no address on the network and no route to anything else.

That is the point when the user should not have general access: a contractor who
needs one system gets that system rather than a position on the network, which
means the boundary is enforced by what is published rather than by firewall rules
applied afterwards.

</details>

<details class="qa">
<summary>What does a VPN not protect against?</summary>

Anything at either end. It secures data in transit between two points, and it
makes no statement about the health of the device connecting, what software is
running on it, or what the user does once connected.

A compromised laptop with a working client to site tunnel is a compromised machine
on the network, and it arrived inside encryption that no inspection could see
into. That is the observation the whole zero trust argument is built on.

</details>

<details class="qa">
<summary>A remote user can reach some internal systems and not others, with no obvious pattern. Where would you look?</summary>

At where the tunnel terminates and what sits between that point and the systems.
A concentrator on a perimeter network is not on the internal network, and the
firewall rules between the two decide what remote users can reach.

The pattern usually turns out to be exactly those rules, written at different
times for different reasons. Checking what address a connected client receives,
and what is permitted from that range, answers it faster than testing systems one
at a time.

</details>

## References

- [RFC 4301](https://www.rfc-editor.org/rfc/rfc4301) - IETF, the IPSec architecture underneath most site to site deployments. Free. Accessed 2026-08-13.
- [RFC 8446](https://www.rfc-editor.org/rfc/rfc8446) - IETF, TLS 1.3, which is what the browser based and many client to site products use instead. Free. Accessed 2026-08-13.
- [NIST SP 800-77 Rev. 1](https://csrc.nist.gov/pubs/sp/800/77/r1/final) - NIST, a guide to IPsec VPNs, including the split and full tunnel decision. Free. Accessed 2026-08-13.
- [NIST SP 800-207](https://csrc.nist.gov/pubs/sp/800/207/final) - NIST, zero trust architecture, and the argument against treating network position as a credential. Free. Accessed 2026-08-13.

**Where the output came from.** Nothing on this page is captured from a lab,
because a VPN is a tunnel with a policy attached and topic 49 already captured the
tunnel. What would be added here is somebody's policy, and a transcript of a
policy is a screenshot of a document. The Windows and macOS blocks came from
GitHub Actions runners through `blog/scripts/hostcap.sh`, and both are honest
about what they show: neither machine has a VPN configured, and the interfaces
listed are the ones each platform keeps ready in case one is.

**If you also work on Linux.** [SSH and secure remote access](/learn/linux-plus/ssh-and-secure-remote-access)
on the Linux+ track covers the other way people reach things they are not sitting
next to, and the comparison is useful: one gives you a network position and the
other gives you a session.
