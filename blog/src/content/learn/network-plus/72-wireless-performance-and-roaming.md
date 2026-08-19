---
title: "Wireless performance and roaming"
description: "Full signal strength, and the connection keeps dropping. Why airtime rather than bandwidth is what a cell shares, why one distant laptop slows a whole room, how a coverage gap and a capacity problem produce identical complaints with opposite fixes, and the channel change nobody made."
deck: "Full signal strength, and the connection keeps dropping"
track: "network-plus"
level: "deep"
order: 730
objectives:
  - "Measure a wireless fault where the complaint is rather than at the access point"
  - "Read data rate and retries rather than signal strength"
  - "Explain why one slow client costs everybody else airtime"
  - "Tell a coverage gap from a capacity problem, and give each the right fix"
  - "Recognise a channel change forced by radar detection"
prerequisites: ["ssids-network-types-and-access-points"]
tags: ["network-plus", "networking", "troubleshooting", "wireless"]
updated: 2026-08-19
draft: false
examObjectives:
  - exam: "n10-009"
    domain: "5.0"
    objective: "5.4"
sources:
  - title: "IEEE 802.11 Standard for Wireless LANs"
    url: "https://standards.ieee.org/ieee/802.11/7028/"
    publisher: "IEEE Standards Association"
    accessed: 2026-08-19
    tier: 1
  - title: "Ofcom, licence exempt radio use"
    url: "https://www.ofcom.org.uk/spectrum/information/licence-exempt-radio-use/"
    publisher: "Ofcom"
    accessed: 2026-08-19
    tier: 1
  - title: "iw(8)"
    url: "https://manpages.debian.org/unstable/iw/iw.8.en.html"
    publisher: "Debian"
    accessed: 2026-08-19
    tier: 2
symptoms:
  - symptom: "A client shows full signal strength and the connection is unusable"
    anchor: "the-numbers-worth-reading-and-the-one-everybody-reads"
  - symptom: "One room is slow whenever it is busy and fine when it is empty"
    anchor: "a-coverage-gap-and-a-capacity-problem-look-the-same"
  - symptom: "Every client on a band drops at the same moment for no reason"
    anchor: "the-channel-change-nobody-made"
---

> **Before you read.** A user reports that the wireless keeps dropping. You look
> at their laptop and it shows full bars. You stand next to them with your own
> machine and it also shows full bars, and it also drops.
>
> The access point is four metres away, on the ceiling, with a green light on it.
>
> **Both machines can hear the access point perfectly. Why is neither of them
> working?**

Wireless faults are the ones where every wired instinct fails. There is no cable
to swap, no port counter to read, no link light that means anything, and the
medium is shared with everybody in the building and with things that are not
networks at all. What replaces those instincts is a small set of measurements
taken in the right place.

Nothing on this page is captured. This track has no radio, and a namespace cannot
be an access point, so the evidence here is arithmetic you can reproduce and
documents you can go and read rather than transcripts.

### Some words you will need

<dl class="terms">
<dt>airtime</dt>
<dd>The thing a wireless cell actually shares. One radio transmits at a time, so what everybody is queueing for is time rather than capacity.</dd>
<dt>retry rate</dt>
<dd>The proportion of frames a client had to send more than once. The best single indicator of a struggling wireless link.</dd>
<dt>coverage gap</dt>
<dd>Somewhere with no usable signal. Fixed by putting a radio nearer, not by shouting louder.</dd>
<dt>capacity problem</dt>
<dd>Enough signal, too many clients or too much traffic for the airtime available. Fixed by more cells, each smaller.</dd>
<dt>dynamic frequency selection</dt>
<dd>The rule that an access point on certain 5 GHz channels must listen for radar and leave immediately if it hears any.</dd>
</dl>

## What breaks without this

**The measurement is taken in the wrong place.** Wireless quality is a property of
a position, so a reading taken at the access point, or at your desk, or at any time
other than when the complaint happens, describes a different problem.

**Bars get treated as a diagnosis.** Signal strength is one of four numbers a client
knows and it is the only one most people look at, which is why "full bars and it does
not work" is such a common sentence.

**A capacity problem gets more transmit power.** The two fixes are opposite. Turning
the power up on a busy cell makes it larger, which puts more clients in it, which is
the direction the problem was already going.

## The numbers worth reading, and the one everybody reads

Topic 29 made the point that signal strength is not throughput, and that the useful
fraction is how far the signal stands above the noise. This is the practical version:
which numbers a client can tell you, and what each one is for.

**Signal strength** is how loudly the client hears the access point, in dBm, always
negative, closer to zero being stronger. It answers exactly one question: is there
enough signal here at all. Above roughly minus sixty-five it is not the problem, and
almost every complaint that comes with full bars is a complaint about something else.

**Noise** is everything else on that frequency. It is the half of the fraction the
bars do not show, and it is why the same signal strength can be excellent in one
building and unusable in another.

**Data rate** is what the client and the access point negotiated, and it moves
constantly. A client that has fallen from a high rate to a low one has told you the
link is struggling, before any user notices, and it is a far more sensitive indicator
than signal strength.

**Retry rate** is the proportion of frames that had to be sent again. A wireless
frame is acknowledged, and an unacknowledged frame is resent, so a link with
interference on it retries rather than failing. A few percent is normal. Twenty
percent is a fault that no signal strength reading will show you.

The last two are worth more than the first two because of what a cell actually
shares.

<figure class="learn-figure">
<svg viewBox="0 0 720 195" role="img" aria-labelledby="air-title" style="width:100%;height:auto;">
<title id="air-title">One second of airtime shared by five clients, first with all five at a high data rate leaving most of the second free, then with one client at a twelfth of the rate consuming three quarters of the second on its own</title>
<g fill="currentColor">
<text x="14" y="20" font-size="11">one second of airtime, and the same amount of data from every client in both rows</text>
<text x="14" y="69" font-size="9.5" fill-opacity="0.85">all five near</text>
<text x="14" y="129" font-size="9.5" fill-opacity="0.85">one at the far wall</text>
<g fill="none" stroke="currentColor" stroke-opacity="0.45" stroke-width="1.1">
<rect x="140" y="52" width="540" height="24" rx="3"/>
<rect x="140" y="112" width="540" height="24" rx="3"/>
</g>
<g fill="currentColor" fill-opacity="0.3">
<rect x="140" y="52" width="33" height="24" rx="2"/>
<rect x="177" y="52" width="33" height="24" rx="2"/>
<rect x="214" y="52" width="33" height="24" rx="2"/>
<rect x="251" y="52" width="33" height="24" rx="2"/>
<rect x="288" y="52" width="33" height="24" rx="2"/>
<rect x="140" y="112" width="33" height="24" rx="2"/>
<rect x="177" y="112" width="33" height="24" rx="2"/>
<rect x="214" y="112" width="33" height="24" rx="2"/>
<rect x="251" y="112" width="33" height="24" rx="2"/>
</g>
<rect x="288" y="112" width="392" height="24" rx="2" fill="var(--accent)" fill-opacity="0.3" stroke="var(--accent)" stroke-opacity="0.9" stroke-width="1.6"/>
<text x="350" y="69" font-size="9.5" fill-opacity="0.85">the rest of the second is free</text>
<text x="484" y="129" text-anchor="middle" font-size="9.5" fill="var(--accent)">one client, twelve times the airtime</text>
<text x="14" y="172" font-size="9.5" fill-opacity="0.85">airtime is data divided by rate, so a client at a twelfth of the rate takes twelve times as long to say the same thing</text>
</g></svg>
<figcaption>A wireless cell shares time, not capacity, because one radio transmits at a time. So the cost of a client is not what it sends but how long it takes to send it, and that is its data divided by its rate. A laptop that has fallen from a high rate to a twelfth of it occupies twelve times the airtime for the same work, and the four clients sitting next to the access point, sending exactly what they sent yesterday, find there is almost nothing left. That is why one person at the far end of a floor can slow down a room they are not in, and why the number to go looking for is the client with the lowest rate rather than the one with the most traffic.</figcaption>
</figure>

The arithmetic in that figure is checkable and it is the whole argument. Airtime is
bytes divided by rate, so a client at one twelfth of the rate takes twelve times as
long. Four clients at a high rate and one at a twelfth share sixteen units of airtime
between them, and the slow one is using twelve of the sixteen, which is seventy-five
percent of the cell, for the same amount of data as each of the others.

Two things follow that are worth carrying.

**The client to investigate is the slow one, not the busy one.** A monitoring system
that ranks clients by traffic finds the wrong machine, in exactly the way topic 75's
capacity graph finds the wrong link.

**Removing one bad client can fix a whole room.** That is a genuinely strange
sentence on a wired network and it is routine here.

## Where to measure, and when

The other instinct that has to change is where you stand.

On a wired network the evidence is at the switch and it is the same evidence
whichever chair you are sitting in. On a wireless network **quality is a property of
a position and a moment**. Two metres changes it, because reflections from walls and
metal arrive slightly behind the direct signal and can cancel it. A room full of
people is a different radio environment from the same room empty, because a human
body is mostly water and water absorbs these frequencies. And the interference that
is causing the complaint may not be running when you visit.

So the rule is: **measure at the seat that complained, at the time it complained,
with a client rather than from the infrastructure.** Everything else describes a
different problem and describes it accurately, which is what makes it so convincing.

<details class="deeper">
<summary>If you already run wireless: the survey that measured an empty building, and the two things a client will not tell you</summary>

The commonest reason a wireless deployment underperforms from the first day is that
the survey that designed it was done at a weekend.

An empty building is a different radio environment in three separate ways. There are
no bodies absorbing signal, so coverage measures better than it will ever be again.
There are no client devices, so the noise floor is the building's own rather than the
one your users create for each other. And there is no traffic, so nothing about
airtime or capacity is being tested at all. A survey done under those conditions
produces a coverage map that is accurate, and a design that fails on Monday morning.

The correction is not complicated and it is frequently skipped for scheduling
reasons. Validate under load, at a time the building is being used, and treat the
empty-building survey as the design input rather than as the verification. Where a
full validation is impossible, the design hedge is to plan for smaller cells than the
coverage map suggests, because every error introduced by an empty building points the
same way.

The other thing worth knowing is what the client will not tell you, because it shapes
what you can conclude. A client reports what it hears from the access point, and it
has no way to report what the access point hears from it. Those two are not
symmetrical: an access point on a ceiling with a decent antenna and permission to
transmit at high power is easy for a phone to hear, and the phone, small, low-powered
and in a pocket, may be much harder to hear back. So a client showing a strong signal
is telling you about one direction only, which is a second reason full bars and a
broken connection is not a contradiction.

And a client will not tell you about the traffic it is not part of. Interference from
a neighbouring network, a video sender or a microwave shows up in the client's
symptoms and not in its statistics, which is why the instrument for that particular
question is a spectrum analyser rather than a laptop. Topic 30 has a real capture of
the 2.4 GHz band from one.

</details>

## A coverage gap and a capacity problem look the same

Two of the commonest wireless faults produce the same complaint and take opposite
fixes, so telling them apart is worth more than any amount of tuning.

**A coverage gap** is somewhere with not enough signal. The symptoms are worst at the
edge of a space, in a stairwell, in a corner office, behind a lift shaft, and they do
not depend on how busy the network is. A user in that spot has the same experience at
seven in the morning as at eleven. Signal strength genuinely is low, so for once the
bars are informative.

**A capacity problem** is enough signal and not enough airtime. The symptoms depend
entirely on how many people are present. The same seat is perfect at seven and
unusable at eleven, signal strength is excellent throughout, and the numbers that move
are the data rate and the retries.

The test that separates them costs nothing: **go back when the building is empty.** A
fault that disappears is capacity. A fault that persists is coverage. That single
observation is worth more than an afternoon of measurements, because it splits the
two cases before you decide what to buy.

And the fixes genuinely are opposite. A coverage gap wants a radio nearer the gap.
A capacity problem wants **more cells, each covering less**, which usually means
turning the transmit power down rather than up so that clients divide themselves
between access points instead of all crowding onto the loudest one. Turning power up
on a congested cell makes it bigger, attracts more clients into it, and makes the
problem worse in the direction it was already going. That is the single most common
wrong fix in wireless and it feels right every time.

## Why a client gives up

The third fault in the hook is the drop itself, and it is worth knowing that a client
leaving a network is not usually an error.

A client disassociates for ordinary reasons: it decided another access point was
better, it is going to sleep, or it is roaming. It can also be told to leave by the
infrastructure, which happens when it fails to authenticate, when it has been idle,
or when a controller is balancing load between radios. And it can simply lose the
connection without any of that, if the signal drops below what it needs and no other
access point is heard.

Which means the useful information is not that a client disassociated but **which of
those it was**, and that is in the access point or controller log rather than on the
client. A log that records a reason for each disassociation turns a vague "it keeps
dropping" into a specific one, and the specific ones point in different directions: a
client leaving because it roamed is topic 31's problem, one leaving after repeated
authentication failures is topic 32's, and one that simply vanished is a coverage
question.

The pattern across a whole site matters more than any single event. Many clients
leaving at once points at the infrastructure or at the radio environment. One client
leaving repeatedly while its neighbours stay points at that client, and usually at its
driver.

## The channel change nobody made

The last fault is one nothing else in this track covers, and it produces the most
alarming symptom in wireless: every client on a band drops at the same moment, and
everything is configured correctly.

Parts of the 5 GHz band are shared with radar, and the condition for using them is
that the network gets out of the way. An access point on one of those channels must
listen for radar before transmitting, and if it detects radar while operating, it must
stop using that channel immediately and move. That mechanism is dynamic frequency
selection, and 802.11h is the amendment that specifies the behaviour, which is
notable because it is the one 802.11 letter that the exam objectives name directly.

The consequences are entirely practical.

**The move is not optional and not gradual.** The access point leaves the channel,
which drops every client on it, and they reconnect on the new channel. To a user this
is the whole wireless network failing for thirty seconds, simultaneously, for no
reason anybody can find afterwards.

**The trigger need not be a radar you have heard of.** Airport and weather radar are
the obvious ones, and so is a marine radar on a boat, which is why sites near a
coastline or a flight path see this and sites in the middle of a city often do not.

**It leaves a trace in exactly one place.** The access point or controller logs the
detection and the channel change. Nothing on the client says anything except that the
connection went away, so a fault that is completely explicable looks like a mystery to
anybody investigating from a laptop.

If a site sees repeated unexplained simultaneous drops, checking whether its channel
plan uses the affected part of the band is a five-minute question with a clean answer,
and the fix is to prefer channels that are not subject to the rule.

## Prove it

Nothing here is captured, and this is the section where that matters most, because a
wireless measurement taken in the wrong place is worse than none.

**Work it out: the airtime arithmetic.** Take five clients each sending the same
amount of data. Four are at a high rate and one has fallen to a twelfth of it. Airtime
is data divided by rate, so the four cost one unit each and the fifth costs twelve.
Twelve of sixteen units is seventy-five percent of the cell, spent on one client doing
the same work as each of the others. That number is why the slowest client matters
more than the busiest one, and you can redo it with any ratio you like.

**Look it up: the 5 GHz channels subject to radar detection.** Your national
regulator publishes which parts of the band require dynamic frequency selection and
which do not, and the answer differs by country. The question only that document
answers is whether the channels in your own channel plan can be taken away from you
without warning. Ofcom publishes it for the United Kingdom and the equivalent body
does for everywhere else.

**Look it up: what your access points log on a disassociation.** Vendor
documentation lists the reason codes. The question that answers is whether "it keeps
dropping" means roaming, authentication failure, idle timeout, or a client that lost
the signal, and those four go to four different places.

## Across platforms

Every client can report the numbers above and none of them is called the same thing
twice. No output is shown here because this track has no radio to produce it.

| Task | Linux | Windows | macOS |
| --- | --- | --- | --- |
| Signal, noise and rate of the current link | `iw dev <if> link` | `netsh wlan show interfaces` | `wdutil info` |
| Retries and per-station counters | `iw dev <if> station dump` | `netsh wlan show interfaces` | `wdutil info` |
| What else is on the air nearby | `iw dev <if> scan` | `netsh wlan show networks mode=bssid` | `wdutil info` |

Two things about that table are worth carrying. The Linux tooling separates the
questions and the other two answer several at once, so on Windows and macOS you read
one report and pick the fields out. And the retry count is the field most likely to be
missing or buried, which is unfortunate given it is the most useful of them.

## What trips people up

### 1. Reading bars and stopping

Signal strength answers one question, which is whether there is enough signal here at
all. Above roughly minus sixty-five it is not the fault, and the complaint is about
noise, airtime or retries.

### 2. Measuring at the access point

Wireless quality belongs to a position. A reading taken anywhere other than the seat
that complained describes a different problem accurately.

### 3. Measuring at the wrong time

An empty building has no bodies absorbing signal, no clients making noise for each
other, and no traffic. A survey done then measures a building nobody will ever use.

### 4. Turning the power up on a busy cell

More power makes the cell larger, which puts more clients in it. A capacity problem
wants more cells covering less each, which usually means turning power down.

### 5. Chasing the busiest client

Airtime is data divided by rate, so the client costing the cell most is the slow one,
not the loud one. A traffic ranking finds the wrong machine.

### 6. Treating a disassociation as an error

Clients leave for ordinary reasons. The useful information is the reason code in the
access point log, and it points at four different investigations.

## Work it through

Two machines, full bars, both dropping, four metres from the access point.

Start by taking signal strength off the table, because it has already answered its
question. Both clients hear the access point well, so there is enough signal and this
is not a coverage problem. That eliminates the entire category of fixes that involve
moving or adding an access point for reach, which is where the conversation usually
goes first.

Then ask what else is using the air, because that is the remaining possibility with a
strong signal. Read the data rate and the retry count on one of the clients while it
is misbehaving. A high rate with low retries means the radio link is healthy and the
fault is above it, somewhere in the wired network, which is a completely different
investigation. A rate that has collapsed, or retries in the tens of percent, means the
air is the problem, and the two candidates are other networks on the same channel and
interference that is not a network at all.

Then split capacity from environment with the cheapest possible test. Go back when the
building is empty. If it works then, the fault is capacity and the fix is more cells
at lower power. If it fails then as well, with no clients present, the interference is
not coming from your users and a spectrum measurement is the next instrument.

And if the drops are simultaneous across every client rather than one at a time, stop
looking at clients entirely and read the access point log. Everything on a band losing
its connection at the same instant is either the access point restarting or a channel
change, and if the channel plan includes the part of the band that has to yield to
radar, that is the first thing to check and the fastest to rule out.

## Try it

**Read all four numbers on your own machine.** Signal, noise, rate and retries. Then
walk to the far side of the building and read them again. Watching the rate collapse
while the bars barely move is what makes the case that the bars were never the useful
number.

**Do the airtime sum for your own worst client.** Take its data rate, divide it into
the rate a nearby client gets, and that ratio is how many times more airtime it uses
for the same work. It is usually a bigger number than people expect.

**Find out whether your channels can be taken away.** Look up which 5 GHz channels in
your country require radar detection, then look at the channels your access points are
actually using. If they overlap, you have an explanation waiting for the next
unexplained simultaneous drop.

## Check yourself

<details class="qa">
<summary>A client shows full signal strength and the connection is unusable. What has that already told you?</summary>

That it is not a coverage problem. Signal strength answers one question, which is
whether there is enough signal at this position, and full bars answer it yes.

What remains is everything the bars do not measure: the noise on that frequency, the
data rate the link settled on, and the proportion of frames being retried. A strong
signal in a noisy environment performs worse than a moderate signal in a quiet one, so
the useful next reading is the rate and the retry count, not another look at the
strength.

</details>

<details class="qa">
<summary>Why can one distant laptop slow down a room it is not in?</summary>

Because a wireless cell shares airtime rather than bandwidth. One radio transmits at a
time, so what everybody queues for is time, and the time a client costs is its data
divided by its rate.

A client that has fallen to a twelfth of the rate takes twelve times as long to send
the same amount. With four fast clients and one at a twelfth, the slow one uses twelve
of the sixteen units of airtime, which is three quarters of the cell, for the same work
as each of the others. That is why the client worth investigating is the slowest rather
than the busiest.

</details>

<details class="qa">
<summary>A seat is perfect at seven in the morning and unusable at eleven. Coverage or capacity?</summary>

Capacity. A coverage gap does not care what time it is, because the signal at a
position is the same whether or not anybody else is present. A fault that appears only
when the building fills up is about airtime and contention rather than reach.

The test is exactly that observation, which is why it is worth making before measuring
anything: come back when the building is empty. The fix is more cells covering less
each, usually with the transmit power turned down so clients spread themselves between
access points, rather than more power, which makes the busy cell bigger.

</details>

<details class="qa">
<summary>Every client on the 5 GHz network drops at the same instant and everything is configured correctly. What would you check?</summary>

Whether the access point changed channel because it detected radar. Parts of the 5 GHz
band are shared with radar, and the condition of using them is that the network leaves
immediately when radar is heard. That is dynamic frequency selection, specified in
802.11h.

The move is instant and not optional, so every client on that channel loses its
connection at once and reconnects wherever the access point went. Nothing on any client
records a reason. The only trace is in the access point or controller log, and the
long-term fix is a channel plan that prefers channels not subject to the rule.

</details>

<details class="qa">
<summary>Why is a site survey done at a weekend a poor basis for a design?</summary>

Because an empty building is a different radio environment in three ways. No bodies are
absorbing signal, so coverage reads better than it ever will again. No client devices are
present, so the noise floor is the building's rather than the one users create for each
other. And there is no traffic, so nothing about airtime or capacity has been tested.

Every error introduced by an empty building points the same way, towards optimism, which
is why a design based on one tends to fail on the first busy morning. The correction is
to validate under load and treat the empty survey as the design input rather than the
verification.

</details>

## References

- [IEEE 802.11](https://standards.ieee.org/ieee/802.11/7028/) - IEEE Standards Association, which defines acknowledgement and retry behaviour, and in the 802.11h amendment the radar detection and channel change described above. Accessed 2026-08-19.
- [Ofcom licence exempt radio use](https://www.ofcom.org.uk/spectrum/information/licence-exempt-radio-use/) - Ofcom, for which parts of the 5 GHz band require radar detection in the United Kingdom. Every country publishes its own and they differ. Free to read, and the site refuses automated requests, so the link checker reports it as forbidden rather than broken. Accessed 2026-08-19.
- [iw(8)](https://manpages.debian.org/unstable/iw/iw.8.en.html) - Debian manpages, for the fields a wireless client can report, which is where the four numbers in this topic come from. Free. Accessed 2026-08-19.

**Where the numbers came from.** Nothing on this page is captured. This track has no
radio and a network namespace cannot be an access point, so there is no honest way to
produce a wireless transcript here. The airtime figure is arithmetic on the definition of
airtime as data divided by rate, stated in the figure so it can be rechecked with any
ratio. The radar behaviour is from IEEE 802.11 and the channels it applies to are from
national regulators, which differ. No photograph is added here because the objects this
topic reasons about, antennas, access points and a real spectrum measurement, are already
photographed in topics 29 to 31, and a stock picture of somebody holding a laptop would
prove nothing.

**If you also work on Linux systems.** The client-side readings above are `iw` output on
Linux, and the same four numbers exist on every platform under different names. What does
not transfer is the instinct to read a counter on a device: on wireless the authoritative
reading is taken at the position that complained, with a client, at the time it
complained.
