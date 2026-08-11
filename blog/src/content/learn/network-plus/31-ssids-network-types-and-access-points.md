---
title: "SSIDs, network types and access points"
description: "The same network name in every room and your laptop moving between them. What SSID, BSSID and ESSID each actually name, why roaming is the client's decision and not yours, the four network types, and what a controller changes."
deck: "The same network name in every room"
track: "network-plus"
level: "working"
order: 310
objectives:
  - "Distinguish SSID, BSSID and ESSID and say what each names"
  - "Explain why roaming is a decision the client makes"
  - "Describe infrastructure, mesh, ad hoc and point to point"
  - "Say what a guest network and a captive portal each provide"
  - "Tell an autonomous access point from a lightweight one and say where the controller sits"
prerequisites: ["wireless-channels-and-frequencies"]
tags: ["network-plus", "networking", "wireless"]
updated: 2026-08-11
draft: false
examObjectives:
  - exam: "n10-009"
    domain: "2.0"
    objective: "2.3"
sources:
  - title: "IEEE 802.11, Wireless LAN Medium Access Control and Physical Layer Specifications"
    url: "https://standards.ieee.org/ieee/802.11/7028/"
    publisher: "IEEE Standards Association"
    accessed: 2026-08-11
    tier: 1
  - title: "RFC 5415, Control And Provisioning of Wireless Access Points (CAPWAP) Protocol Specification"
    url: "https://www.rfc-editor.org/rfc/rfc5415"
    publisher: "IETF"
    accessed: 2026-08-11
    tier: 1
  - title: "IEEE 802.1Q, Bridges and Bridged Networks"
    url: "https://standards.ieee.org/ieee/802.1Q/10323/"
    publisher: "IEEE Standards Association"
    accessed: 2026-08-11
    tier: 1
symptoms:
  - symptom: "A laptop keeps a weak connection to a distant access point when a closer one is available"
    anchor: "why-roaming-is-not-your-decision"
  - symptom: "Guest devices can see each other on the network"
    anchor: "guest-networks-and-the-portal"
---

> **Before you read.** One network name across a whole building. You walk from
> one end to the other on a call and it holds, mostly, and then in one particular
> corridor it drops every time.
>
> Nothing in that corridor is broken. Coverage there is fine, measured from a
> phone standing still.
>
> **What is the laptop doing, and who told it to?**

The previous two topics were about the medium. This one is about the vocabulary
of what sits on it, and one uncomfortable fact: the decision that produces the
symptom above is made by a device you do not administer.

### Some words you will need

<dl class="terms">
<dt>SSID</dt>
<dd>Service set identifier. The network name, as text.</dd>
<dt>BSSID</dt>
<dd>Basic service set identifier. One radio's identity, and in practice a MAC address.</dd>
<dt>ESSID</dt>
<dd>Extended service set identifier. The name shared by several access points acting as one network.</dd>
<dt>association</dt>
<dd>A client having joined one specific radio. A client is never associated with a name.</dd>
<dt>roaming</dt>
<dd>A client leaving one BSSID for another with the same ESSID.</dd>
<dt>autonomous access point</dt>
<dd>One that holds its own configuration and is managed on its own.</dd>
<dt>lightweight access point</dt>
<dd>One that takes its configuration from a controller and cannot work without it.</dd>
</dl>

## What breaks without this

**A roaming fault gets blamed on coverage.** Standing still in a corridor and
seeing a good signal proves nothing about what happens when you walk through it,
and the two are measured differently.

**Guest wireless leaks.** A separate network name is not separation. Without
client isolation, devices on the guest network can reach each other, which is
usually not what anybody intended.

**A controller failure is a mystery.** Lightweight access points behave in a
specific way when they lose their controller, and it differs by product, so it is
worth knowing before it happens rather than during.

## Three names that are not synonyms

The three initialisms look like the same idea spelled three ways. They are not,
and the difference is the whole of this topic.

**SSID is the name**, as text. `OFFICE`, `Coffee Shop Guest`, whatever somebody
typed. It identifies a network to a human.

**BSSID is one radio**, and it is a MAC address. Every access point radio has its
own, which is how a client tells two access points apart when both are
advertising the same name.

**ESSID is the name shared across several radios** so that they behave as one
network. When people say a building has one wireless network, this is what they
mean.

<figure class="learn-figure">
<svg viewBox="0 0 720 300" role="img" aria-labelledby="ssid-title" style="width:100%;height:auto;">
<title id="ssid-title">Three access points advertising one network name, each with its own BSSID, and a client that has associated with the strongest of them</title>
<g fill="currentColor">
<text x="14" y="20" font-size="11">one network name, three radios, and the client decides which one it is on</text>
<rect x="66" y="46" width="168" height="56" rx="4" fill="var(--accent)" fill-opacity="0.22" stroke="var(--accent)" stroke-width="2"/>
<text x="150" y="66" text-anchor="middle" font-size="10.5" fill-opacity="0.75">SSID</text>
<text x="150" y="82" text-anchor="middle" font-size="12">OFFICE</text>
<text x="150" y="96" text-anchor="middle" font-size="9.5" fill-opacity="0.75">BSSID 02:1a:11:00:00:01</text>
<rect x="276" y="46" width="168" height="56" rx="4" fill="currentColor" fill-opacity="0.08" stroke="currentColor" stroke-width="1" stroke-opacity="0.5"/>
<text x="360" y="66" text-anchor="middle" font-size="10.5" fill-opacity="0.75">SSID</text>
<text x="360" y="82" text-anchor="middle" font-size="12">OFFICE</text>
<text x="360" y="96" text-anchor="middle" font-size="9.5" fill-opacity="0.75">BSSID 02:1a:11:00:00:02</text>
<rect x="486" y="46" width="168" height="56" rx="4" fill="currentColor" fill-opacity="0.08" stroke="currentColor" stroke-width="1" stroke-opacity="0.5"/>
<text x="570" y="66" text-anchor="middle" font-size="10.5" fill-opacity="0.75">SSID</text>
<text x="570" y="82" text-anchor="middle" font-size="12">OFFICE</text>
<text x="570" y="96" text-anchor="middle" font-size="9.5" fill-opacity="0.75">BSSID 02:1a:11:00:00:03</text>
<rect x="300" y="230" width="120" height="40" rx="4" fill="currentColor" fill-opacity="0.14" stroke="currentColor" stroke-opacity="0.6"/>
<text x="360" y="248" text-anchor="middle" font-size="11">one laptop</text>
<text x="360" y="263" text-anchor="middle" font-size="9.5" fill-opacity="0.75">hears all three</text>
<line x1="330" y1="230" x2="150" y2="106" stroke="var(--accent)" stroke-width="2.4"/>
<text x="144" y="176" text-anchor="end" font-size="10" fill="var(--accent)">-45 dBm</text>
<text x="144" y="191" text-anchor="end" font-size="10" fill="var(--accent)">associated</text>
<line x1="390" y1="230" x2="360" y2="106" stroke="currentColor" stroke-opacity="0.4" stroke-width="1.4" stroke-dasharray="5 4"/>
<text x="368" y="176" font-size="10" fill-opacity="0.7">-67 dBm</text>
<line x1="390" y1="230" x2="570" y2="106" stroke="currentColor" stroke-opacity="0.4" stroke-width="1.4" stroke-dasharray="5 4"/>
<text x="578" y="176" font-size="10" fill-opacity="0.7">-78 dBm</text>
<text x="14" y="292" font-size="10.5" fill-opacity="0.8">the same ESSID on all three. roaming means picking a different BSSID, and nothing above notices</text>
</g></svg>
<figcaption>One name, three radios. Every access point here advertises OFFICE, so a person sees one network and a client sees three candidates, each identified by its own BSSID. The laptop has associated with the strongest, and the two dashed links are the ones it can hear and is not using. Roaming is the solid line moving to a different box. Nothing above layer 2 is aware it happened, which is why a call survives it and also why a badly timed one is so hard to see from the network side.</figcaption>
</figure>

**A client is never associated with a name.** It is associated with exactly one
BSSID at a time. That distinction sounds pedantic until it explains the fault at
the top of this page.

## Why roaming is not your decision

When a client walks away from one access point and toward another, something has
to decide when to switch. That decision is made entirely by the client.

The access point does not hand a client over. It cannot: it has no way to compel
a client to leave, and the client is the only device that can measure what it
hears from each candidate. So the client watches signal strength, applies
whatever thresholds its driver was written with, and switches when it decides to.

Those thresholds are not standardised and they differ between operating systems,
between drivers, and between versions of the same driver. A phone and a laptop
walking the same corridor will roam at different points, and one of them may not
roam at all until the connection is unusable.

That is the corridor. Coverage measured standing still is fine, because a
stationary client with a weak signal still works. A walking client that is
holding on to an access point behind it, at a low data rate, through a wall, is a
different measurement entirely. The industry name for it is sticky client
behaviour, and the fixes are all indirect: reduce transmit power so the old
access point becomes genuinely unattractive, or use the standards that give the
client better information to decide with. You never get to make the decision
yourself.

<details class="deeper">
<summary>If you already work on networks: what the roaming standards actually do, and why none of them takes the decision away</summary>

Three amendments come up whenever roaming is discussed, and it is worth being
precise about what each one contributes, because none of them does the thing
people assume.

One publishes a list of neighbours, so a client can be told which other access
points exist and on which channels, rather than having to scan every channel to
find out. That makes the client's search cheaper and faster. It does not tell the
client when to go.

One lets a client ask for measurements and report what it sees, which gives the
infrastructure visibility it otherwise lacks. Again, information rather than
control.

One shortens the reassociation itself, by allowing the security handshake to be
completed with the new access point ahead of time or in fewer exchanges. Topic 32
is about that handshake, and the reason this matters is that a full one takes long
enough to break a voice call. This is the amendment that makes roaming smooth once
the client has decided to do it.

So the pattern across all three: the infrastructure can make roaming cheaper,
better informed and faster, and the moment of decision stays with the client. A
device with a badly written driver will still cling, and no amount of
configuration on your side overrides it.

Which leads to the practical advice, and it is unglamorous. Design for the client
you cannot fix: smaller cells, lower power, and enough overlap that the next
access point is obviously better rather than marginally better. A client deciding
between -70 and -68 will dither. A client deciding between -75 and -50 will not.

</details>

## The four network types

The objective names four arrangements, and three of them are ordinary.

**Infrastructure** is everything above: clients associate with access points, and
the access points connect to a wired network. Essentially every network you will
work on is this.

**Mesh** connects the access points to each other by radio instead of by cable,
so only some of them need a wired uplink. It buys coverage where cabling is
impractical, and it costs capacity, because a mesh link consumes airtime that
would otherwise serve clients, and traffic crossing several hops consumes it
several times.

**Ad hoc** is clients talking directly to each other with no access point at all.
It appears in the objectives and rarely anywhere else.

**Point to point** is two radios aimed at each other to replace a cable between
two places, which is the dish in the previous topic. It is a link rather than a
network.

## Guest networks and the portal

A guest network is a separate SSID whose traffic is kept away from the internal
one, usually by putting it in its own VLAN and letting it reach the internet and
nothing else. Topic 16 is the mechanism; this is one of its most common uses.

**A separate name is not separation.** Two things have to be true beyond the name.
The guest SSID has to land in a network that cannot route to the internal one, and
client isolation has to be enabled so that guest devices cannot reach each other
either. The second is the one people forget, and without it a room full of guests
is a room full of devices on a shared segment with strangers.

**A captive portal** is the page that appears before a guest gets access, and it
works by intercepting the first web request and answering it with a redirect. Two
consequences follow from that mechanism. It only intercepts things that look like
web traffic, so a device that connects and tries something else simply fails with
no explanation. And it interacts badly with encrypted traffic, which is why
operating systems make a deliberate unencrypted request on joining a network,
purely to see whether something intercepts it.

## Autonomous and lightweight

Two ways to run access points, and the difference is where the configuration
lives.

**An autonomous access point** holds its own. You configure it directly, it works
on its own, and ten of them means ten configurations to keep consistent. Fine for
one or two, painful at scale, and the usual failure is drift between them.

**A lightweight access point** takes its configuration from a controller. One
place to configure, one place to see everything, and coordination between access
points becomes possible: channel and power assignment across the whole estate,
and a coherent view of the air.

The question worth asking about any controller is where it sits in the traffic
path, because there are two arrangements and they fail differently. In one, client
traffic is tunnelled back to the controller before going anywhere, which
centralises policy and makes the controller a bottleneck and a single point of
failure. In the other, the controller configures the access points and client
traffic goes straight onto the local network, so a controller failure leaves
existing service running while you lose management.

RFC 5415 is the free document here. It specifies CAPWAP, the protocol for
controlling and provisioning access points, and its architecture sections describe
exactly this split between the control path and the data path. Whether a given
vendor uses CAPWAP or something proprietary, the distinction it draws is the one
to ask about.

<figure class="learn-figure photo">

![Three access points opened up and laid out on a glass table. Each white plastic housing sits behind its circuit board. On the board of the largest, a flat metal antenna element is visible, shaped and mounted directly on the board. The smallest unit's board is barely larger than a matchbox.](./images/access-points-opened.jpg)

<figcaption>Three access points with the covers off, and the thing to look at is the metal on the boards. Those shapes are the antennas. A ceiling access point has no aerials sticking out of it because they are printed and mounted inside the housing, which is why the plastic dome is not merely cosmetic and why mounting one on its side or inside a metal enclosure changes its coverage in ways nothing in the configuration will tell you. It also explains the shape of the coverage: these are omnidirectional in the horizontal plane and much weaker directly above and below, so an access point on a ceiling covers the floor beneath it and serves the floor above it poorly. Photograph by Uhernandez, <a href="https://creativecommons.org/licenses/by/3.0/">CC BY 3.0</a>.</figcaption>
</figure>

## Prove it

Nothing is captured here, for the reason the last two topics gave: the lab has no
radio. There is a document and there is the device in your pocket.

**RFC 5415.** Free from the RFC editor. Read the architecture overview and answer
one question: does CAPWAP describe client data as always passing through the
controller, or does it allow for the data path and the control path to be
separated? The answer is the distinction the last section is about.

**Then look at the BSSIDs around you.** Any wireless survey app will show the
network names it can hear and the BSSID of each radio advertising them. Find a
name that appears more than once. The number of BSSIDs under one name is the
number of radios covering you, and if you can find a name with three or more you
are looking at exactly the picture in the diagram above.

## What trips people up

### 1. Using SSID, BSSID and ESSID interchangeably

The name, one radio, and the name shared across radios. A client associates with
a BSSID and never with a name, which is what makes roaming a thing that happens
at all.

### 2. Expecting the network to hand a client over

It cannot. The client measures, the client decides, and the thresholds live in a
driver you do not control. Everything the infrastructure can do is indirect.

### 3. Measuring coverage standing still

A stationary client with a weak signal works. A walking client holding on to an
access point behind it is the fault, and it only appears while moving.

### 4. Treating a guest SSID as isolation

The name separates nothing. The traffic has to land somewhere that cannot reach
the internal network, and client isolation has to be on, or guests share a segment
with each other.

### 5. Assuming a captive portal catches everything

It intercepts web requests. A device doing anything else on joining simply fails,
with no page and no error that explains why.

### 6. Adding a controller without asking where the traffic goes

Tunnelled through it, or straight onto the local network. The two fail
differently, and the answer decides what happens to existing clients when the
controller stops.

## Work it through

The corridor, taken apart.

First separate the two measurements, because they are not the same test. Standing
in the corridor with a phone shows coverage: signal is fine. Walking through it
with a call up shows roaming, and the reported symptom is that it drops while
moving. Those are different faults and only the second one is happening.

So the question becomes which access point the laptop is on as it walks. If it
associated at one end and is still holding that association halfway down the
corridor, it is transmitting at a low rate through whatever is between them, and
the call has a loss and latency problem long before the association actually
breaks. The signal reading standing still never reveals this because a stationary
client is not trying to leave.

Then the awkward part: the decision to move is the laptop's, and nothing you
configure changes that directly. What you can change is how attractive the old
access point remains. Lower transmit power shrinks each cell, so the difference
between the one behind and the one ahead becomes large rather than marginal, and
a client choosing between clearly different options behaves much better than one
choosing between similar ones.

Then check whether it is only some devices. If the phone roams cleanly through the
same corridor and one laptop model does not, that narrows it to a driver, and the
fix is a driver update or an accepted limitation rather than a network change. It
is worth establishing early, because it stops a design conversation about a device
problem.

And the thing to check before any of that: whether the corridor is covered by two
access points at all, or whether it is the seam where one cell ends and the next
begins with no overlap. Roaming needs somewhere to roam to, and a corridor with a
gap in the middle produces exactly this symptom for a completely different reason.

## Try it

**Find one network name with several BSSIDs.** A survey app on a phone shows this
in seconds, and it makes the diagram on this page real.

**Watch your own device roam.** In a building with more than one access point,
walk from one end to the other with a survey app open and watch the BSSID change.
Note where it changes and whether it waited longer than you would have.

**Check whether your guest network isolates clients.** Connect two devices to it
and try to reach one from the other. Most people have never tested this and a fair
number are surprised.

## Check yourself

<details class="qa">
<summary>What is the difference between an SSID and a BSSID, and which one does a client associate with?</summary>

The SSID is the network name as text. The BSSID identifies one radio and in
practice is a MAC address.

A client associates with a BSSID, always, and never with a name. Several access
points advertising the same name is what makes a building feel like one network,
and the shared name is the ESSID.

That distinction is what makes roaming meaningful: moving between access points
means changing BSSID while the name stays the same, and nothing above layer 2
notices.

</details>

<details class="qa">
<summary>A laptop clings to a distant access point while a closer one is available. What can you actually do about it?</summary>

Nothing directly, because the decision belongs to the client. The access point
cannot force a client to leave, and roaming thresholds live in the client's driver.

What you can change is how attractive the distant access point remains. Reducing
transmit power shrinks each cell, so the choice facing the client becomes obvious
rather than marginal, and a client deciding between a strong and a weak signal
behaves far better than one deciding between two mediocre ones.

The standards that help make roaming faster and better informed. None of them
moves the decision.

</details>

<details class="qa">
<summary>Why is a separate guest SSID not the same as separating guests?</summary>

Because the name is only a label. Two other things have to be true.

The guest traffic has to land in a network that cannot reach the internal one,
which is normally a separate VLAN with its own route to the internet and nothing
else.

And client isolation has to be enabled, or guests can reach each other. That
second one is the commonly missed half, and without it a public network is a
shared segment full of strangers' devices.

</details>

<details class="qa">
<summary>Where can a wireless controller sit in the traffic path, and why does the answer matter?</summary>

Either client traffic is tunnelled back to it before going anywhere, or it
configures the access points and client traffic goes straight onto the local
network.

It matters because the two fail differently. In the tunnelled arrangement the
controller is in the path of every packet, so it is both a bottleneck and a single
point of failure. In the other, losing the controller costs you management and
coordination while existing service keeps running.

RFC 5415 describes the split between the control path and the data path, and
asking which arrangement a given product uses is the useful question when
somebody proposes one.

</details>

<details class="qa">
<summary>A device joins a guest network and never sees the login page. What is a likely reason?</summary>

A captive portal works by intercepting a web request and answering with a
redirect. If the device does not make one, nothing is intercepted and nothing
appears.

That covers anything joining the network to do something other than browse, and
it is why operating systems make a deliberate plain request on joining, purely to
find out whether something answers it with a redirect instead of what was asked
for.

</details>

## References

- [IEEE 802.11](https://standards.ieee.org/ieee/802.11/7028/) - IEEE Standards Association, which defines the service set concepts these three initialisms come from. Scope readable without purchase. Accessed 2026-08-11.
- [RFC 5415](https://www.rfc-editor.org/rfc/rfc5415) - IETF, the CAPWAP specification, whose architecture sections describe the split between the control path and the data path. Free. Accessed 2026-08-11.
- [IEEE 802.1Q](https://standards.ieee.org/ieee/802.1Q/10323/) - IEEE Standards Association, for the VLAN separation a guest network depends on. Accessed 2026-08-11.

**Pictures.** A freely licensed file from Wikimedia Commons, downloaded and served
from this site rather than linked across to somebody else's server.

- [Comparación Access Point](https://commons.wikimedia.org/wiki/File:Comparaci%C3%B3n_Acess_Point.jpg) by Uhernandez, [CC BY 3.0](https://creativecommons.org/licenses/by/3.0/).

**Where the numbers came from.** The signal readings in the diagram are
illustrative rather than measured, which is why they are round numbers on a scale
rather than a capture. Nothing on this page is captured: the lab behind this track
is Linux network namespaces and has no radio. The roaming amendments are described
by what they contribute rather than by their letters, because no letter amendment
appears anywhere in the objectives.

**If you also work on Linux.** `iw dev wlan0 link` prints the BSSID you are
currently associated with, not just the network name, so watching it while you
walk shows a roam happening. `iw dev wlan0 scan | grep -E "SSID|BSS "` lists every
radio in range with its BSSID, which is the diagram on this page drawn from your
own surroundings.
