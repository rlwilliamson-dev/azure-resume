---
title: "Wireless channels and frequencies"
description: "Twelve access points in one office and everything is slow. The three bands and what each trades, why only three channels fit in 2.4 GHz, what channel width actually buys, and the regulatory limits that decide what you are allowed to transmit."
deck: "Twelve access points in one office, and everything is slow"
track: "network-plus"
level: "working"
order: 300
objectives:
  - "Name the three bands and say what each one trades"
  - "Explain why only three channels fit without overlapping in 2.4 GHz"
  - "Say what a wider channel buys and what it costs"
  - "Explain band steering and what problem it solves"
  - "Say who decides transmit limits and why that varies by country"
prerequisites: ["wireless-and-cellular-media"]
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
  - title: "ITU Radio Regulations"
    url: "https://www.itu.int/pub/R-REG-RR"
    publisher: "International Telecommunication Union"
    accessed: 2026-08-11
    tier: 1
  - title: "RFC 3819, Advice for Internet Subnetwork Designers"
    url: "https://www.rfc-editor.org/rfc/rfc3819"
    publisher: "IETF"
    accessed: 2026-08-11
    tier: 1
symptoms:
  - symptom: "Adding access points makes wireless slower rather than faster"
    anchor: "why-only-three-channels-fit"
  - symptom: "A wider channel is configured and throughput falls"
    anchor: "channel-width-and-what-it-buys"
---

> **Before you read.** An office covered the floor with access points to fix
> patchy wireless. Twelve of them, all on full power, all working, all showing
> clients connected.
>
> It is slower than it was with four.
>
> **How does adding capacity remove it?**

The previous topic established that the air is one shared medium. This one is
about how many separate mediums you can actually make out of it, which turns out
to be a much smaller number than people assume, and about the arithmetic that
makes covering a floor with radios counterproductive.

### Some words you will need

<dl class="terms">
<dt>band</dt>
<dd>A range of frequencies set aside for a purpose. Wireless LANs use three.</dd>
<dt>channel</dt>
<dd>A named slice of a band. Devices on the same channel share one medium.</dd>
<dt>channel width</dt>
<dd>How much spectrum one channel occupies, in megahertz. Wider carries more and tolerates less.</dd>
<dt>non-overlapping</dt>
<dd>Two channels far enough apart in frequency that neither is noise to the other.</dd>
<dt>co-channel interference</dt>
<dd>Two access points on the same channel, taking turns. Slow but orderly.</dd>
<dt>adjacent-channel interference</dt>
<dd>Two access points on partly overlapping channels, which is noise rather than turn taking, and is worse.</dd>
<dt>band steering</dt>
<dd>An access point encouraging a capable client onto the less crowded band.</dd>
</dl>

## What breaks without this

**More access points make things worse.** Coverage and capacity are different
problems with opposite fixes, and treating a capacity problem as a coverage
problem is the most common wireless mistake there is.

**A wider channel gets configured because wider sounds faster.** It sometimes is
and frequently is not, and knowing which requires knowing what it costs.

**A configuration that is legal in one country is not in another.** Transmit
limits and available channels are set by regulators, so a design that works in
one office may be unlawful in the same company's office abroad.

## The three bands

Three bands, and each is a trade between how far the signal goes and how much
room there is in it.

**2.4 GHz** travels furthest and penetrates walls best, and it is the most
crowded thing in the building. It is shared with Bluetooth, with microwave ovens,
with cordless phones and with every neighbouring network, and as the next section
shows it has room for three channels.

**5 GHz** does not travel as far and is stopped more easily by walls, and in
exchange it has far more channels. This is where most current traffic should be,
and getting clients onto it is what band steering exists for.

**6 GHz** is the newest and has the most spectrum of the three. Its range is the
shortest, and its real advantage is that it is empty: only recent equipment can
use it at all, so it carries none of the accumulated crowding of the other two.

The pattern is worth stating because it is the whole trade in one sentence:
**lower frequencies go further and carry less, higher frequencies go less far and
carry more.** Every choice in this topic is somewhere on that line.

<details class="deeper">
<summary>If you already plan channels: why a dual band design is not simply the sum of two bands</summary>

Running 2.4 and 5 GHz from the same access points looks like adding the two capacities
together and it does not work that way, for reasons that are all about the clients.

A client picks one band and stays on it, and which one it picks is the client's
decision made with its own thresholds, exactly as roaming is. Some devices prefer
2.4 GHz because the signal is stronger and will sit there while the 5 GHz radio beside
them is idle. Others have no 5 GHz radio at all. So the load does not divide evenly and
the band with more room is frequently the emptier one.

The response is to make the crowded band less attractive rather than to try to force
anything, since forcing is not available. Lower transmit power on 2.4 GHz shrinks its
cells so 5 GHz is the better choice more often. Some deployments go further and switch
2.4 GHz off on most access points, leaving enough for the devices that need it, which
is a decision about which clients exist rather than about radio.

Worth knowing as well: the two bands do not have to carry the same networks. Putting
the devices that can only do 2.4 GHz on their own network, on their own segment,
separates a population you cannot upgrade from one you can, which is the argument
topic 55 makes about segmentation applied to radio.

</details>

## Why only three channels fit

2.4 GHz has thirteen or fourteen numbered channels depending on the country, and
people reasonably assume thirteen channels means thirteen separate mediums. It
does not, and the reason is that the numbers describe centre frequencies while
the transmissions have width.

Channels are spaced 5 MHz apart. A transmission is 22 MHz wide. So a channel
occupies roughly two channel numbers either side of its own, and two access
points four numbers apart are not on separate mediums at all.

<figure class="learn-figure">
<svg viewBox="0 0 720 250" role="img" aria-labelledby="ch-title" style="width:100%;height:auto;">
<title id="ch-title">The 2.4 GHz band drawn to frequency, showing that a 22 MHz channel at 1, 6 and 11 fits three times without touching, and that any other choice overlaps two of them</title>
<g fill="currentColor">
<text x="14" y="20" font-size="11">the 2.4 GHz band, drawn to frequency. each channel is 22 MHz wide</text>
<rect x="66.4" y="52" width="164.0" height="96" rx="3" fill="var(--accent)" fill-opacity="0.2" stroke="var(--accent)" stroke-width="1.8"/>
<text x="148.4" y="86" text-anchor="middle" font-size="12" fill="var(--accent)">1</text>
<text x="148.4" y="102" text-anchor="middle" font-size="9.5" fill="var(--accent)" fill-opacity="0.85">22 MHz</text>
<rect x="252.7" y="52" width="164.0" height="96" rx="3" fill="var(--accent)" fill-opacity="0.2" stroke="var(--accent)" stroke-width="1.8"/>
<text x="334.7" y="86" text-anchor="middle" font-size="12" fill="var(--accent)">6</text>
<text x="334.7" y="102" text-anchor="middle" font-size="9.5" fill="var(--accent)" fill-opacity="0.85">22 MHz</text>
<rect x="439.1" y="52" width="164.0" height="96" rx="3" fill="var(--accent)" fill-opacity="0.2" stroke="var(--accent)" stroke-width="1.8"/>
<text x="521.1" y="86" text-anchor="middle" font-size="12" fill="var(--accent)">11</text>
<text x="521.1" y="102" text-anchor="middle" font-size="9.5" fill="var(--accent)" fill-opacity="0.85">22 MHz</text>
<rect x="140.9" y="118" width="164.0" height="60" rx="3" fill="currentColor" fill-opacity="0.12" stroke="currentColor" stroke-width="1.6" stroke-dasharray="5 4"/>
<text x="222.9" y="136" text-anchor="middle" font-size="11">3</text>
<text x="222.9" y="170" text-anchor="middle" font-size="9.5" fill-opacity="0.75">overlaps 1 and 6</text>
<line x1="44" y1="192" x2="700" y2="192" stroke="currentColor" stroke-opacity="0.55" stroke-width="1.4"/>
<g stroke="currentColor" stroke-opacity="0.45">
<line x1="148.4" y1="192" x2="148.4" y2="199"/>
<line x1="185.6" y1="192" x2="185.6" y2="199"/>
<line x1="222.9" y1="192" x2="222.9" y2="199"/>
<line x1="260.2" y1="192" x2="260.2" y2="199"/>
<line x1="297.5" y1="192" x2="297.5" y2="199"/>
<line x1="334.7" y1="192" x2="334.7" y2="199"/>
<line x1="372.0" y1="192" x2="372.0" y2="199"/>
<line x1="409.3" y1="192" x2="409.3" y2="199"/>
<line x1="446.5" y1="192" x2="446.5" y2="199"/>
<line x1="483.8" y1="192" x2="483.8" y2="199"/>
<line x1="521.1" y1="192" x2="521.1" y2="199"/>
<line x1="558.4" y1="192" x2="558.4" y2="199"/>
<line x1="595.6" y1="192" x2="595.6" y2="199"/>
</g>
<g font-size="9.5" fill-opacity="0.7" text-anchor="middle">
<text x="148.4" y="212">1</text>
<text x="185.6" y="212">2</text>
<text x="222.9" y="212">3</text>
<text x="260.2" y="212">4</text>
<text x="297.5" y="212">5</text>
<text x="334.7" y="212">6</text>
<text x="372.0" y="212">7</text>
<text x="409.3" y="212">8</text>
<text x="446.5" y="212">9</text>
<text x="483.8" y="212">10</text>
<text x="521.1" y="212">11</text>
<text x="558.4" y="212">12</text>
<text x="595.6" y="212">13</text>
</g>
<text x="14" y="196" font-size="9.5" fill-opacity="0.7">ch</text>
<g font-size="9.5" fill-opacity="0.6" text-anchor="middle">
<text x="133.5" y="234">2410</text>
<text x="282.5" y="234">2430</text>
<text x="431.6" y="234">2450</text>
<text x="580.7" y="234">2470</text>
</g>
<text x="700" y="234" text-anchor="end" font-size="9.5" fill-opacity="0.6">MHz</text>
</g></svg>
<figcaption>The band drawn to frequency rather than as a list of numbers. Each accented block is one 22 MHz transmission, and three of them fit across the band without touching, which is the entire reason for the 1, 6 and 11 convention. The dashed block is channel 3, four numbers away from channel 1 and five from channel 6, and it lands on both. That is what the numbering hides: the gaps between the numbers are 5 MHz and the transmissions are more than four times that wide.</figcaption>
</figure>

That is the whole reason for the 1, 6, 11 convention. It is not superstition or
vendor preference, it is the only arrangement of three that fits.

**And the two kinds of interference are not equally bad**, which is the part that
makes the wrong answer tempting. Two access points on the same channel can hear
each other, so they take turns. That is co-channel interference and it halves
throughput in an orderly way. Two access points on channels 1 and 3 cannot decode
each other and cannot take turns, so each is simply noise to the other. That is
adjacent-channel interference, and it is worse than sharing.

So the counterintuitive rule: if you cannot avoid overlap, deliberately put the
access points on the *same* channel rather than on nearby ones.

<figure class="learn-figure photo">

![A screenshot from a wireless survey tool showing signal strength in dBm against channel number for the 2.4 GHz band. Two overlapping green and blue humps sit over channels 1 to 3 at about minus 80 dBm. A large red hump labelled CrowdedSky24 is centred on channel 6 and reaches minus 33 dBm, spreading from channel 4 to channel 8. A yellow hump with the same name is centred on channel 11 at about minus 68 dBm. A purple band along the bottom shows the noise floor rising across the whole band.](./images/24ghz-real-spectrum.png)

<figcaption>The same band, measured rather than drawn. Three networks, sitting on 1, 6 and 11 as they should, and the shape of each hump is the 22 MHz width from the diagram above showing up in real signal. Two things are worth staring at. The humps are not vertical: energy from the network on 6 is still present at channels 4 and 8, which is the overlap the numbering hides. And the purple band along the bottom is the noise floor, rising and falling across the band, which is everything that is not a network anybody named. That floor is the denominator in the ratio the previous topic said actually decides whether a link works, and it is the thing no client ever shows you. Screenshot by Andrew Crouthamel, <a href="https://creativecommons.org/licenses/by-sa/4.0/">CC BY-SA 4.0</a>.</figcaption>
</figure>

<details class="deeper">
<summary>If you already lay out cells: why partial overlap is worse than sharing a channel</summary>

Three usable channels sounds like a severe constraint and the instinct is to use the
numbers in between to get more separation. That instinct makes things worse, and the
reason is worth understanding because it is counterintuitive.

Two access points on the same channel can hear each other. The access method is built
for exactly that: each waits for the medium to be free, and they take turns. Capacity
is shared and nothing is corrupted, which is a cost you can plan around.

Two access points four channels apart cannot properly hear each other and their
transmissions still overlap. Neither defers to the other, because neither can decode
what the other is sending well enough to know it is there, so they transmit
simultaneously into overlapping spectrum and both transmissions are damaged. The
result is retries at both, and retries are the most expensive thing a cell can spend
airtime on.

So the rule that comes out of it is to reuse the three non-overlapping channels
deliberately rather than to spread across all thirteen. Neighbouring cells get
different channels from the three, and cells far enough apart reuse the same one. A
plan that looks wasteful on paper performs better than one that uses every number
available, and this is the single most common mistake in a 2.4 GHz deployment.

</details>

## Channel width and what it buys

Channel width is how much spectrum one channel occupies, and wider channels carry
more data. In 5 GHz and 6 GHz, channels can be bonded together into 40, 80 or 160
MHz, and the throughput rises roughly in proportion.

Two costs come with it, and the second one is the interesting one.

**Fewer channels.** The band is a fixed size, so doubling the width halves the
number of separate channels available. Bond aggressively in an environment that
needs many access points and you have solved one access point's throughput by
making every access point contend with its neighbours.

**Less tolerance of noise.** A wider channel spreads the same transmit power
across more spectrum, so the power per unit of bandwidth falls, and the receiver
needs a better signal to noise ratio to decode it. In a quiet environment that is
free. In a noisy one, a wider channel can be measurably slower than a narrow one,
because it drops to a more robust encoding or fails more often.

**Which is why 2.4 GHz should essentially never be widened.** There is only room
for three channels at 22 MHz. Widening to 40 leaves room for one, and the band is
the noisy one.

<details class="deeper">
<summary>If you already work on networks: dynamic frequency selection, and the channels you are borrowing</summary>

A large part of the 5 GHz band is not primarily yours. It is shared with radar,
including weather radar and some military and aviation systems, and the
arrangement that allows wireless networks into it comes with an obligation.

Dynamic frequency selection is that obligation implemented. An access point using
one of the affected channels has to listen for radar before transmitting, for a
period, and has to keep listening while it operates. If it detects a radar
signature it must leave the channel, immediately, and not return for a defined
period.

Three practical consequences follow, and all three surprise people the first time.

Starting up on a DFS channel is not instant. The access point has to complete its
listening period before it can serve clients, which can be a minute or several,
and during that time the radio appears dead for no visible reason.

A radar event moves an access point mid-service. Clients are disconnected and
have to reassociate somewhere else, and the trigger is invisible from inside the
network. An access point that occasionally drops every client for no logged
reason, near an airport or a coast, is a DFS event until proven otherwise.

And false detections happen. Some equipment is more prone to it than others, and
the symptom is the same as a genuine event.

None of this is a fault. It is the condition on which those channels are
available at all, and the reason they are quieter than the non-DFS ones is
precisely that many deployments avoid them. That makes them a genuine opportunity
in a crowded building, as long as somebody knows why the radios take a minute to
start.

</details>

## Who decides what you may transmit

The exam names 802.11 for the regulatory question, and the honest answer has two
layers.

IEEE 802.11 defines how the radios behave. What power they may use and which
frequencies they may use at all is decided by a regulator in each country, and
those decisions differ. The ITU coordinates internationally, and national bodies
implement within that: the FCC in the United States, Ofcom in the United Kingdom,
and an equivalent everywhere else.

The consequences that reach a network engineer are concrete. A country code is
set on the equipment, and it determines which channels are selectable and how
much power is permitted. Channel 13 is usable in much of Europe and not in the
United States. Some 5 GHz channels are indoor only. And the same access point
model, configured identically, will behave differently in two offices because the
country code differs.

**So a wireless design is not portable across borders**, and copying a channel
plan from one country's site to another's is a real mistake rather than a
theoretical one.

## Prove it

Nothing here is captured, for the same reason as the previous topic: a veth pair
has no radio. There is a document to read and an instrument to use, and this time
the instrument is the more valuable of the two.

**IEEE 802.11.** Read the scope statement and answer one question: does the
standard itself specify transmit power limits, or does it defer them to
regulatory authorities? The answer explains why the same product behaves
differently in two countries.

**Then look at your own band.** Any wireless survey application on a phone or
laptop will draw the picture in this topic from the air around you. Look for three
things: how many networks you can see, whether they are on 1, 6 and 11 or
scattered across the numbers, and where the noise floor sits. In a block of flats
the answer to the second question is usually depressing, and it explains more
about your own wireless than any setting on your router.

## What trips people up

### 1. Reading thirteen channel numbers as thirteen channels

The numbers are centre frequencies spaced 5 MHz apart and the transmissions are
22 MHz wide. Three fit without overlapping, which is why 1, 6 and 11 is a
convention rather than a preference.

### 2. Fixing a capacity problem with more coverage

More access points on overlapping channels adds interference rather than
capacity. If throughput falls as people arrive, the answer is channel planning
and lower power, not more radios at full power.

### 3. Choosing nearby channels to avoid a busy one

Same channel means taking turns. Nearby channel means being noise to each other,
which is worse. Where overlap cannot be avoided, deliberate co-channel is the
better answer.

### 4. Widening a channel because wider sounds faster

Wider carries more and tolerates less, and it consumes channels you may need for
neighbouring access points. In 2.4 GHz it is close to always wrong.

### 5. Turning the power up to improve coverage

It enlarges the area over which everybody contends, keeps distant slow clients
associated instead of letting them roam, and creates an asymmetry where the
access point can be heard by clients that cannot be heard back.

### 6. Copying a channel plan between countries

Available channels and power limits are set nationally. The country code on the
equipment changes what is legal and what is selectable.

## Work it through

Twelve access points, all on full power, slower than four.

The first thing to establish is which problem this is. Coverage problems look
like dead spots and weak signal. Capacity problems look like a strong signal and
poor throughput that worsens with occupancy. The scenario says everything is
connected and slow, so this is capacity, and every instinct that says add more
radios is now pointing the wrong way.

Then the channel arithmetic, which is where twelve becomes the number that
matters. In 2.4 GHz there are three non-overlapping channels. Twelve access points
means at best four of them share each channel, and at worst somebody has spread
them across 1 to 11 evenly and created adjacent-channel interference between
nearly all of them. The second is common, because spreading things out looks like
the careful thing to do.

Then the power, which is the multiplier. Full power on every radio means every
access point can be heard across most of the floor, so the contention domain is
the whole floor rather than a room. Reducing power is counterintuitive and is
usually the single most effective change: it shrinks each cell, so fewer devices
contend, and it encourages clients to roam to the nearest access point instead of
clinging to a distant one at a slow rate.

Then the band. If most of this is happening in 2.4 GHz, the fix that costs
nothing is to move everything capable onto 5 GHz, which has enough channels to
give twelve access points genuinely separate mediums. That is what band steering
is for, and it is worth checking whether it is on before doing anything else.

So the order of operations is: measure the air rather than the clients, move what
can move to 5 GHz, reduce power, and only then adjust the channel plan. Adding
hardware does not appear on the list, and removing some of it might.

## Try it

**Survey your own home or office.** Any phone survey app draws the picture. Note
which channels the networks near you are using and whether they are on 1, 6 and
11.

**Look at your router's channel setting.** If it is on automatic, see what it
chose. If it is on something other than 1, 6 or 11 in 2.4 GHz, you now know
something about your neighbours' throughput as well as your own.

**Find the country code on a piece of wireless equipment.** It is usually in the
web interface and occasionally on the label. Then check which channels that
setting makes available.

## Check yourself

<details class="qa">
<summary>Why do thirteen numbered channels give only three usable ones in 2.4 GHz?</summary>

Because the numbers are centre frequencies 5 MHz apart while each transmission is
22 MHz wide. A channel therefore spreads over roughly two numbers either side of
its own.

Three channels at 22 MHz fit inside the band without touching, and the
arrangement that achieves it is 1, 6 and 11. Any other choice of three overlaps
at least two of them.

</details>

<details class="qa">
<summary>Two access points must overlap. Is it better to put them on the same channel or on nearby ones?</summary>

The same channel, which surprises everybody.

On the same channel they can hear each other, so the medium access rules work:
they take turns. Throughput is shared but the sharing is orderly.

On nearby overlapping channels they cannot decode each other, so they cannot take
turns. Each is simply noise raising the other's floor, and both suffer more than
if they had shared.

</details>

<details class="qa">
<summary>What does a wider channel buy, and what are the two things it costs?</summary>

It carries more data, roughly in proportion to the extra width.

It costs channel count, because the band is a fixed size and doubling the width
halves the number of separate channels available. And it costs noise tolerance,
because the same transmit power is spread across more spectrum, so the receiver
needs a better signal to noise ratio.

In a quiet band with few access points, widening is close to free. In 2.4 GHz,
where there is room for three channels and the noise is worst, it is close to
always wrong.

</details>

<details class="qa">
<summary>An office added access points to fix slow wireless and it got slower. What happened?</summary>

A capacity problem was treated as a coverage problem.

More radios on overlapping channels do not add capacity, they add interference.
With only three non-overlapping channels in 2.4 GHz, twelve access points at full
power means every device contends with most of the floor rather than with its own
room.

The fixes run the other way: move capable clients to 5 GHz, reduce transmit power
so each cell is smaller, and plan channels deliberately. Adding hardware is not on
the list and removing some may be.

</details>

<details class="qa">
<summary>Why does the same access point model behave differently in two countries?</summary>

Because the country code changes which channels are selectable and how much power
is permitted, and those limits are set by national regulators rather than by the
802.11 standard.

The standard defines how the radios behave. The ITU coordinates internationally
and national bodies decide locally, so channel 13 is usable across much of Europe
and not in the United States, and some 5 GHz channels are indoor only.

The practical consequence is that a channel plan is not portable between a
company's offices in different countries.

</details>

## References

- [IEEE 802.11](https://standards.ieee.org/ieee/802.11/7028/) - IEEE Standards Association, which defines the radio behaviour and defers power limits to regulators. Scope readable without purchase. Accessed 2026-08-11.
- [ITU Radio Regulations](https://www.itu.int/pub/R-REG-RR) - International Telecommunication Union, the international framework national regulators work within. Accessed 2026-08-11.
- [RFC 3819](https://www.rfc-editor.org/rfc/rfc3819) - IETF, on link characteristics and why lossy links are difficult for the layers above. Free. Accessed 2026-08-11.

**Pictures.** A freely licensed file from Wikimedia Commons, downloaded and served
from this site rather than linked across to somebody else's server.

- [2.4 GHz Wi-Fi Interference](https://commons.wikimedia.org/wiki/File:2.4_GHz_Wi-Fi_Interference.png) by Andrew Crouthamel, [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/).

**Where the numbers came from.** The channel spacing of 5 MHz and the 22 MHz
transmission width are properties of the 2.4 GHz plan and are what the diagram is
drawn from, so the diagram is to scale rather than schematic. Which channels are
available in which country, and at what power, comes from national regulators
rather than from any figure quoted here, which is why this page names the bodies
instead of listing limits that would be wrong somewhere. Nothing is captured: the
lab behind this track has no radio.

**If you also work on Linux.** `iw dev wlan0 scan` lists what the radio can hear,
including the channel and signal of every network in range, which is the closest
a host gets to the survey picture on this page. `iw reg get` prints the regulatory
domain the kernel believes it is in, which is the setting the last section is
about.
