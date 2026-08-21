---
title: "Wi-Fi generations and the number on the box"
description: "The exam names no 802.11 letter, so this track never did either. Which amendment each marketing generation maps to, what actually changed at each step, how to take apart the throughput figure on a datasheet, and why the generation that matters is the one your clients have."
deck: "Five wireless topics, and you still cannot read the box"
track: "network-plus"
level: "working"
order: 790
beyondExam: true
objectives:
  - "Map each Wi-Fi generation name to the IEEE amendment it stands for"
  - "Say what changed at each step, and which steps were about one client and which about many"
  - "Take apart an advertised throughput figure and say what a single client could actually see"
  - "Explain what the 6 GHz band gained and what it cost"
  - "Say why the client population decides the generation rather than the access point"
prerequisites: ["wireless-channels-and-frequencies", "wireless-performance-and-roaming"]
tags: ["network-plus", "networking", "wireless", "beyond-the-exam"]
updated: 2026-08-20
draft: false
examObjectives: []
sources:
  - title: "Wi-Fi Alliance introduces Wi-Fi 6"
    url: "https://www.wi-fi.org/news-events/newsroom/wi-fi-alliance-introduces-wi-fi-6"
    publisher: "Wi-Fi Alliance"
    accessed: 2026-08-20
    tier: 1
  - title: "Wi-Fi Alliance brings Wi-Fi 6 into 6 GHz"
    url: "https://www.wi-fi.org/news-events/newsroom/wi-fi-alliance-brings-wi-fi-6-into-6-ghz"
    publisher: "Wi-Fi Alliance"
    accessed: 2026-08-20
    tier: 1
  - title: "Wi-Fi Alliance introduces Wi-Fi CERTIFIED 7"
    url: "https://www.wi-fi.org/news-events/newsroom/wi-fi-alliance-introduces-wi-fi-certified-7"
    publisher: "Wi-Fi Alliance"
    accessed: 2026-08-20
    tier: 1
  - title: "IEEE 802.11 Timelines"
    url: "https://www.ieee802.org/11/Reports/802.11_Timelines.htm"
    publisher: "IEEE 802.11 Working Group"
    accessed: 2026-08-20
    tier: 1
  - title: "IEEE 802.11, Wireless LAN Medium Access Control and Physical Layer Specifications"
    url: "https://standards.ieee.org/ieee/802.11/7028/"
    publisher: "IEEE Standards Association"
    accessed: 2026-08-20
    tier: 1
  - title: "IEEE GET Program"
    url: "https://standards.ieee.org/products-programs/ieee-get-program/"
    publisher: "IEEE Standards Association"
    accessed: 2026-08-20
    tier: 1
  - title: "FCC Report and Order, Unlicensed Use of the 6 GHz Band"
    url: "https://docs.fcc.gov/public/attachments/FCC-20-51A1.pdf"
    publisher: "Federal Communications Commission"
    accessed: 2026-08-20
    tier: 1
symptoms:
  - symptom: "A datasheet advertises a speed no client on the network has ever reached"
    anchor: "the-number-on-the-box-is-a-sum"
  - symptom: "New access points were installed and nothing measurably improved"
    anchor: "the-generation-that-counts-is-the-one-your-clients-have"
---

> **Before you read.** A job advert asks for experience with Wi-Fi 6E. A quote
> from a supplier lists an AX3000 access point. A colleague says the site is
> "still on ac".
>
> **Three ways of naming the same axis, and none of them appears anywhere in the
> exam objectives. What is each one saying?**

The Network+ objectives name 802.11 as a category and never enumerate a single
letter, with one exception: 802.11h, called out for its regulatory behaviour. No
generation number appears either. So this track, which follows the objectives,
has taken you through five wireless topics without ever telling you what Wi-Fi 6
means, and every datasheet, job advert and supplier quote you meet will assume you
know.

### Some words you will need

<dl class="terms">
<dt>amendment</dt>
<dd>A document that changes the 802.11 standard. The letters after 802.11 name amendments, not products.</dd>
<dt>generation</dt>
<dd>A Wi-Fi Alliance marketing name, of which only a handful exist. It maps to an amendment.</dd>
<dt>spatial stream</dt>
<dd>One independent signal path between transmitter and receiver, carried by its own antenna chain.</dd>
<dt>MIMO</dt>
<dd>Multiple in, multiple out. Several spatial streams at once between the same pair of devices.</dd>
<dt>OFDMA</dt>
<dd>Splitting one channel into subchannels so several clients can be served in a single transmission.</dd>
<dt>multi-link operation</dt>
<dd>A client using two bands at the same time, rather than choosing one and associating to it.</dd>
<dt>airtime</dt>
<dd>The time a transmission occupies the channel. The scarce resource, more than bandwidth is.</dd>
</dl>

## What breaks without this

**You cannot read a quote.** A supplier proposes hardware by generation and by
throughput figure, and both are marketing names for engineering that has to be
looked up before the price means anything.

**You buy a generation your clients cannot use.** The access point is one device.
The value is decided by the several hundred devices that connect to it, and half
of them are three years old.

**You cannot tell an upgrade from a refresh.** Some steps changed what one client
could achieve, and some changed what happens when two hundred of them are in a
room. Those are different purchases and they solve different complaints.

## Two naming schemes, and only one of them is in the standard

The IEEE publishes amendments to 802.11 and gives each one letters. Those letters
are the real identifiers: they name a document, they have a publication date, and
what they contain can be read.

The Wi-Fi Alliance is a separate organisation which certifies products, and in
October 2018 it announced generation numbers as a plainer way to talk about the
same thing. It named exactly three: Wi-Fi 6 for 802.11ax, Wi-Fi 5 for 802.11ac,
Wi-Fi 4 for 802.11n.

<figure class="learn-figure">
<svg viewBox="0 0 720 218" role="img" aria-labelledby="wifigen-title" style="width:100%;height:auto;">
<title id="wifigen-title">Four IEEE amendments on a timeline with their publication years, and the Wi-Fi Alliance generation names above them, which begin at four because the first three were never assigned</title>
<g fill="currentColor">
<text x="14" y="24" font-size="11">the marketing names start at four, and there is no Wi-Fi 1, 2 or 3</text>
<line x1="60" y1="126" x2="690" y2="126" stroke="currentColor" stroke-opacity="0.35" stroke-width="1.4"/>
<text x="120" y="150" text-anchor="middle" font-size="10.5">802.11n</text>
<text x="120" y="166" text-anchor="middle" font-size="10" fill-opacity="0.7">2009</text>
<circle cx="120" cy="126" r="4" fill="currentColor" fill-opacity="0.75"/>
<text x="120" y="104" text-anchor="middle" font-size="10.5">Wi-Fi 4</text>
<text x="290" y="150" text-anchor="middle" font-size="10.5">802.11ac</text>
<text x="290" y="166" text-anchor="middle" font-size="10" fill-opacity="0.7">2013</text>
<circle cx="290" cy="126" r="4" fill="currentColor" fill-opacity="0.75"/>
<text x="290" y="104" text-anchor="middle" font-size="10.5">Wi-Fi 5</text>
<text x="460" y="150" text-anchor="middle" font-size="10.5">802.11ax</text>
<text x="460" y="166" text-anchor="middle" font-size="10" fill-opacity="0.7">2021</text>
<circle cx="460" cy="126" r="4" fill="var(--accent)"/>
<text x="460" y="104" text-anchor="middle" font-size="10.5" fill="var(--accent)">Wi-Fi 6</text>
<text x="460" y="86" text-anchor="middle" font-size="10" fill="var(--accent)">and 6E in 6 GHz</text>
<text x="630" y="150" text-anchor="middle" font-size="10.5">802.11be</text>
<text x="630" y="166" text-anchor="middle" font-size="10" fill-opacity="0.7">2025</text>
<circle cx="630" cy="126" r="4" fill="currentColor" fill-opacity="0.75"/>
<text x="630" y="104" text-anchor="middle" font-size="10.5">Wi-Fi 7</text>
<text x="14" y="200" font-size="10" fill-opacity="0.75">amendment dates from the IEEE 802.11 working group timelines, generation names from the Wi-Fi Alliance</text>
</g>
</svg>
<figcaption>Wi-Fi 6E is the odd one on this line and the odd one in conversation. It is not an amendment and there was no new engineering behind it: the Alliance introduced the name in January 2020 for Wi-Fi 6 equipment that could also work in the 6 GHz band, which regulators had just started opening. So a 6E device is an ax device with a third radio, and the E is about spectrum rather than about the protocol.</figcaption>
</figure>

Two consequences worth carrying. The names below four were never assigned, so
anybody saying Wi-Fi 3 has invented it, and the older amendments are still called
by their letters because that is all they ever had. And the certification
programme runs ahead of the document: the Alliance opened Wi-Fi CERTIFIED 7 in
January 2024, and the IEEE published 802.11be in July 2025, so devices were sold
and certified against a draft for a year and a half. That is normal in this
industry and it is worth knowing before somebody tells you a product predates its
own standard as though it were a scandal.

<details class="deeper">
<summary>If you already read standards: why an amendment is not a document you can read on its own</summary>

An amendment is a set of edits. 802.11ax does not describe how Wi-Fi works; it
describes the changes to make to 802.11 that add high efficiency operation,
in the form of clause numbers, replacement paragraphs and new subclauses. Reading
one on its own is like reading a patch file without the source.

Every few years the working group rolls the accumulated amendments into a new
revision, and that revision is the readable document. 802.11-2020 folded in the
amendments up to that point, 802.11-2024 folded in more, and each supersedes the
last. So the useful reference is almost always the current revision rather than
the amendment whose letter people quote.

There is a practical consequence for anybody who wants to check something rather
than take a vendor's word for it. IEEE 802 standards are available at no cost
through the IEEE GET program, which asks you to accept its terms and then hands
over the PDF. That makes 802.11 one of the very few standards in this whole track
that you can read in full without paying, which is worth doing once, if only to
see how much of it is not about radio at all.

</details>

## What actually changed at each step

The generations are not four steps of the same kind. Two of them made one client
faster and two of them made a crowded room work, which is a different purchase
solving a different complaint.

| Generation | Amendment | What it added | Whose problem it solved |
| --- | --- | --- | --- |
| Wi-Fi 4 | 802.11n | Several spatial streams at once, and channel bonding | One client, given clear air |
| Wi-Fi 5 | 802.11ac | Wider channels, denser modulation, 5 GHz only | One client, given clear air |
| Wi-Fi 6 | 802.11ax | Subdividing a channel between clients, scheduling, network colouring | Many clients in one room |
| Wi-Fi 7 | 802.11be | Wider channels again, denser modulation again, and using two bands at once | Both, and latency specifically |

The change at Wi-Fi 6 is the one worth understanding, because it is the one that
breaks the pattern. Everything before it made a single conversation carry more.
802.11ax went after the overhead instead: a channel can be divided so that several
small clients are served in one transmission rather than queueing for their own
turn, overlapping networks can be marked so a radio does not fall silent every
time it hears a neighbour, and battery devices can be told when to wake up so they
stop waking to hear nothing.

None of that shows up as a bigger number on a speed test with one laptop in an
empty office, which is exactly how it gets tested and exactly why the upgrade is
often reported as making no difference. Put two hundred devices in a lecture
theatre and it is a different machine.

<details class="deeper">
<summary>If you already run dense wireless: what subdividing a channel actually buys, and why the gain is largest for the smallest packets</summary>

Before 802.11ax, a transmission occupied the whole channel for its duration
whatever it was carrying. A client with a 200 byte acknowledgement to send took its
turn, used an entire 80 megahertz channel for the time it took, and handed it back.
The overhead of taking a turn is fixed, so the smaller the payload the worse the
ratio, and a room full of phones sending small things spends most of the airtime on
the ceremony rather than the content.

Subdividing the channel lets the access point serve several of those in one
transmission, each on its own slice. The cost of taking a turn is paid once and
divided.

Which tells you where the benefit is and is not. Bulk transfers were already
efficient, because a large frame amortises the overhead by itself, so a file copy
sees almost nothing. Chatty, small, latency-sensitive traffic sees a great deal:
the acknowledgements, the keepalives, the sensor readings, the interactive
requests. In a warehouse full of handheld scanners the difference is not subtle,
and in an office where four people are copying files it is invisible.

That is also why the honest way to size the improvement is to count devices rather
than to measure throughput. The mechanism scales with how many clients are
competing, and any test with one client is measuring the case it was not built for.

</details>

## The number on the box is a sum

An access point advertised as AX3000 has two radios. Neither of them does 3000 of
anything.

<figure class="learn-figure">
<svg viewBox="0 0 720 208" role="img" aria-labelledby="ax3000-title" style="width:100%;height:auto;">
<title id="ax3000-title">The advertised figure of 3000 megabits shown as the sum of a 574 megabit 2.4 gigahertz radio and a 2402 megabit 5 gigahertz radio, against the 600 megabits a single ordinary client reaches</title>
<g fill="currentColor">
<text x="14" y="24" font-size="11">where AX3000 comes from, and what one phone gets</text>
<rect x="14" y="52" width="130" height="34" rx="3" fill="currentColor" fill-opacity="0.08" stroke="currentColor" stroke-opacity="0.45"/>
<text x="79" y="74" text-anchor="middle" font-size="10.5">574 in 2.4 GHz</text>
<text x="164" y="74" text-anchor="middle" font-size="12">+</text>
<rect x="184" y="52" width="180" height="34" rx="3" fill="currentColor" fill-opacity="0.08" stroke="currentColor" stroke-opacity="0.45"/>
<text x="274" y="74" text-anchor="middle" font-size="10.5">2402 in 5 GHz</text>
<text x="384" y="74" text-anchor="middle" font-size="12">=</text>
<text x="404" y="74" font-size="11">2976, printed on the box as 3000</text>
<text x="14" y="122" font-size="10.5" fill-opacity="0.8">both figures assume two spatial streams at the widest channel the band allows</text>
<rect x="14" y="140" width="96" height="34" rx="3" fill="var(--accent)" fill-opacity="0.18" stroke="var(--accent)" stroke-width="1.6"/>
<text x="62" y="162" text-anchor="middle" font-size="10.5" fill="var(--accent)">600</text>
<text x="126" y="162" font-size="10.5" fill="var(--accent)">one phone, one stream, 80 MHz, standing near it</text>
</g>
</svg>
<figcaption>Two radios, added together, on the reasonable-sounding basis that the box can do both at once. No client can. A device associates to one band at a time before Wi-Fi 7, so the largest figure any single client could ever see is the larger of the two, and only with two antennas, a 160 megahertz channel, the densest modulation, and almost no distance. A phone with one antenna on an 80 megahertz channel tops out at a fifth of the number on the carton, in perfect conditions, with nothing else transmitting.</figcaption>
</figure>

The arithmetic behind 2402 is worth doing once, because it demystifies every
figure of this kind. A 160 megahertz channel in 802.11ax carries 1960 data
subcarriers. The densest modulation puts 10 bits on each subcarrier, of which five
sixths are payload after coding, so one symbol carries 1960 by 10 by five sixths,
which is 16,333 bits. Symbols take 12.8 microseconds plus a 0.8 microsecond guard
interval. Divide and you get about 1201 megabits per second per spatial stream,
and two streams is 2402.

Every assumption in that sentence is optimistic. The densest modulation needs a
signal strong enough that the receiver can tell 1024 constellation points apart,
which in practice means the same room. The widest channel needs 160 megahertz to
be free of radar and of neighbours. The guard interval is the shortest one, which
needs low multipath. Nothing in it accounts for the time spent not transmitting,
which on a busy network is most of it.

## What 6 GHz changed, and what it cost

In April 2020 the FCC opened 1200 megahertz in the 6 gigahertz band for unlicensed
use, and other regulators followed with their own decisions and their own amounts.
That is more new spectrum than Wi-Fi had ever received at once, and it arrived
with a property that mattered more than the width: nothing old was on it.

That is the real gain, and it is easy to miss while looking at the megahertz. A
2.4 gigahertz channel has to remain usable by equipment designed in 1999, so every
transmission carries compatibility overhead for devices that may not be present.
The 6 gigahertz band has no such history, so a network there can assume every
device on it is modern.

The costs are physical and regulatory, and topic 30 has the underlying reasons.
Higher frequencies attenuate faster over distance and lose more crossing a wall,
so the same access point covers less. Regulators restrict indoor power and, for
higher power outdoors, require coordination with the licensed users who were there
first. And availability is a national question rather than a technical one, so a
design that works in one country may have half the spectrum in another.

<details class="deeper">
<summary>If you already plan spectrum: why the 6 gigahertz band came with a coordination requirement, and what that means for outdoor coverage</summary>

The band was not empty when it was opened. Fixed point to point microwave links,
which carry things like utility control traffic and broadcast backhaul, have
licensed use of parts of it and were there first. Opening it to unlicensed devices
meant accepting a shared band and finding a way for the newcomers not to interfere
with the incumbents.

The answer was to split the permissions by risk. Low power indoor operation is
allowed without asking anybody, on the reasoning that a building attenuates enough
to protect a link outside it, and the FCC's order defines indoor with a set of
physical requirements rather than with a promise: the device cannot be weather
resistant, must have an integrated antenna it is not possible to swap, and cannot
run on battery power. Read that list again and notice what it is doing. It is a
regulator writing a definition a manufacturer cannot argue its way around, because
every clause removes a way of using the thing outdoors.

Higher power, which the order calls standard power, is a different arrangement. A
standard power access point has to ask an automated frequency coordination system,
an AFC, which frequencies it may use at its location. The AFC knows where the
licensed microwave links are and returns the channels that will not interfere with
them.

For a network designer the consequence is concrete rather than legal. The 6
gigahertz coverage you can rely on indoors is smaller than the 5 gigahertz coverage
it sits alongside, by more than the frequency difference alone would suggest,
because the power ceiling is lower too. Outdoor 6 gigahertz coverage is a different
class of deployment with a dependency on a service that has to be available in your
country. Neither of those is a reason to avoid the band. Both are reasons the
channel plan and the mounting positions are a fresh piece of work rather than an
inheritance.

</details>

## The generation that counts is the one your clients have

An access point is one device. A network is that device and every laptop, phone,
badge reader, printer and handheld scanner that associates with it, and the
distribution of what those support is the thing that decides what the network can
do.

There is a physical reason this matters more than it sounds. The scarce resource
is airtime, not bandwidth. A client transmitting at a low rate takes longer to
send the same frame, and while it is transmitting nobody else can. One old
device at the far end of a warehouse, sending slowly because it is far away and
because it is old, can consume more channel time than a dozen modern clients
close by.

So the question to ask about any wireless upgrade is not what the access point
supports. It is what fraction of the devices that will connect to it can use the
new thing, and whether the ones that cannot are going to be replaced or are going
to be there for another five years holding the channel.

## Prove it

**Do the rate arithmetic yourself.** 980 data subcarriers on an 80 megahertz
channel, 10 bits each, five sixths of them payload, in a symbol lasting 13.6
microseconds including the guard interval. Work it out and you should land within
a megabit of 600, which is the figure a single-stream client on a good 80 megahertz
connection reaches. Then find any access point datasheet and check that its
headline number is the sum of its per band figures.

**Read the announcement rather than an article about it.** The Wi-Fi Alliance's
own release from October 2018 is short. Read it and count how many generation
names it defines. The answer explains why nobody can tell you what Wi-Fi 3 was.

**Look up an amendment's status.** The IEEE 802.11 working group publishes a
timelines page giving every task group, its current draft, and its projected
completion. Find 802.11bn on it. It is the one that will be called Wi-Fi 8, and
the projected approval date tells you how much of what you read about it today is
a prediction.

## What trips people up

### 1. Treating the generation as a speed

It is a set of capabilities with a date on it. Two Wi-Fi 6 access points can
differ by a factor of four in throughput depending on how many antennas each has
and which bands it covers.

### 2. Reading the box number as achievable

It is the sum of every radio's theoretical maximum. No client uses more than one
radio at a time before Wi-Fi 7, and no client reaches a theoretical maximum
outside a shielded room.

### 3. Thinking 6E is a new protocol

It is Wi-Fi 6 with a 6 gigahertz radio. The engineering is 802.11ax either way, and
the difference is which spectrum the device is permitted and able to use.

### 4. Assuming the newest generation is available everywhere

Spectrum is a national decision. A 6 gigahertz design validated in one country can
arrive at a site in another with substantially less spectrum to work with, and the
channel plan has to be redone rather than copied.

### 5. Upgrading the access points and not the survey

A newer generation at 6 gigahertz covers less ground per access point than the
5 gigahertz network it replaced. Reusing the old mounting positions produces
coverage holes that the old hardware did not have, which reads as a fault in the
new equipment.

### 6. Testing the upgrade with one laptop

The gains from Wi-Fi 6 onward are mostly about serving many clients efficiently.
A speed test on an empty network measures the thing that did not change much.

## Work it through

A school replaces its access points with Wi-Fi 6E hardware, mounted where the old
ones were. Complaints go up. The IT lead reports that a speed test in the corridor
gives the same number as before, and that some rooms are now worse.

Take the two symptoms separately, because they have different causes.

The corridor speed test being unchanged is expected and is not evidence of
anything. One device on a quiet network was never the case 802.11ax improves. The
measurement that would show a difference is thirty devices in one classroom during
a lesson, and the number to read is not throughput but how long a page takes to
start loading.

The rooms that got worse are the interesting half. If the new radios are serving
6 gigahertz, they cover less than the 5 gigahertz radios they replaced, from the
same mounting points, through the same walls. That is physics rather than a fault,
and it means the estate needed a new survey rather than a like-for-like swap.

The check that settles it is to look at which band the complaining clients are
actually on and what signal they report. If the bad rooms are the far ones, and
the clients there are hanging on to a weak 6 gigahertz signal rather than falling
back, the fix is coverage: more access points, or a policy that steers distant
clients down to 5 gigahertz where the reach is longer.

Then the question nobody asked at purchase. How many of the school's devices can
use 6 gigahertz at all? If it is the newest third of them, the other two thirds
are on the same 5 gigahertz radios as before, sharing the same air, and the money
bought a better network for the tablets bought last year.

## Try it

**Find out what your own machine supports.** On macOS, hold Option and click the
Wi-Fi icon for the mode, channel and rate of the current connection. On Windows,
`netsh wlan show interfaces` prints the radio type and the receive and transmit
rates. Both will tell you which generation you are actually using, which is often
older than the one on the router.

**Read the rate your client negotiated, then walk away from the access point.**
Watch it drop as the modulation gets less dense. That single observation connects
the arithmetic above to a physical distance, and it is the fastest cure for
treating the headline figure as a property of the equipment.

**Look at a datasheet and take the number apart.** Any access point, any vendor.
Find the per band figures, add them, and confirm they make the name.

## Check yourself

<details class="qa">
<summary>Somebody says a site is running Wi-Fi 3. What have they got wrong?</summary>

There is no Wi-Fi 3. The Wi-Fi Alliance defined three generation names in 2018,
for 802.11n, 802.11ac and 802.11ax, and numbered them 4, 5 and 6. Everything older
is referred to by its amendment letter because it never received a number.

</details>

<details class="qa">
<summary>What is the difference between a Wi-Fi 6 and a Wi-Fi 6E access point?</summary>

A radio for the 6 gigahertz band. The protocol is 802.11ax in both cases. 6E is a
Wi-Fi Alliance name for Wi-Fi 6 equipment that can also operate in the spectrum
regulators opened from 2020, not a separate amendment.

</details>

<details class="qa">
<summary>An AX3000 access point is installed and a laptop reports 1200 megabits. Is something wrong?</summary>

No. 3000 is the sum of the two radios' theoretical maxima. The laptop is on one
band, and 1200 is close to what two spatial streams on a 160 megahertz channel
reach, so it is doing well rather than badly.

</details>

<details class="qa">
<summary>Why can one distant old client hurt everyone else on the same access point?</summary>

Airtime. A client transmitting at a low rate occupies the channel for longer to
send the same frame, and nobody else can transmit while it does. Its cost to the
network is measured in time rather than in the bandwidth it consumed.

</details>

<details class="qa">
<summary>Why do the gains from Wi-Fi 6 rarely show up in a speed test?</summary>

Because a speed test is one client on a quiet network, and that is the case
802.11ax changed least. Its mechanisms reduce the overhead of serving many clients
at once, so the difference appears in a full room and not in an empty one.

</details>

## References

- [Wi-Fi Alliance introduces Wi-Fi 6](https://www.wi-fi.org/news-events/newsroom/wi-fi-alliance-introduces-wi-fi-6) - Wi-Fi Alliance, October 2018, the announcement that defines Wi-Fi 4, 5 and 6 and no others. Free. Accessed 2026-08-20.
- [Wi-Fi Alliance brings Wi-Fi 6 into 6 GHz](https://www.wi-fi.org/news-events/newsroom/wi-fi-alliance-brings-wi-fi-6-into-6-ghz) - Wi-Fi Alliance, January 2020, for what 6E names. Free. Accessed 2026-08-20.
- [Wi-Fi Alliance introduces Wi-Fi CERTIFIED 7](https://www.wi-fi.org/news-events/newsroom/wi-fi-alliance-introduces-wi-fi-certified-7) - Wi-Fi Alliance, January 2024, the certification programme that opened before the standard was published. Free. Accessed 2026-08-20.
- [IEEE 802.11 Timelines](https://www.ieee802.org/11/Reports/802.11_Timelines.htm) - IEEE 802.11 Working Group, publication dates for each amendment and the projected dates for the ones still in draft. Free. Accessed 2026-08-20.
- [IEEE 802.11](https://standards.ieee.org/ieee/802.11/7028/) - IEEE Standards Association, the standard itself, for the physical layer parameters the rate arithmetic uses. Accessed 2026-08-20.
- [IEEE GET Program](https://standards.ieee.org/products-programs/ieee-get-program/) - IEEE Standards Association, how to obtain an 802 standard at no cost. Free. Accessed 2026-08-20.
- [FCC Report and Order 20-51](https://docs.fcc.gov/public/attachments/FCC-20-51A1.pdf) - Federal Communications Commission, April 2020, the decision that opened 1200 megahertz at 6 gigahertz for unlicensed use in the United States. Free. Accessed 2026-08-20.

**Where the figures came from.** Nothing on this page is captured. The generation
names and their dates are from the Wi-Fi Alliance's own announcements, the
amendment publication dates are from the IEEE 802.11 working group's timelines
page, and the 6 gigahertz allocation is from the FCC's order. The throughput
arithmetic is worked from the physical layer parameters in 802.11 and can be
checked against any access point datasheet, which is the exercise in Prove it. No
wireless output in this track is captured, for the reason topic 29 gives: the lab
behind these notes has namespaces and no radios.

**Why this is not in the lesson count.** The objectives name no 802.11 letter
except 802.11h and no generation number at all, so none of this is examinable. It
is here because every datasheet, quote and job advert you meet outside the exam
uses these names and assumes you know them.
