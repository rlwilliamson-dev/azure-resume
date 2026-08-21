---
title: "PoE and transceiver problems"
description: "Six cameras, one switch, and the sixth one keeps rebooting. Why a power budget is a total rather than a per-port limit, what happens when an injector and a device disagree about the standard, and how a switch tells you a fibre link is dim rather than broken."
deck: "Six cameras, one switch, and the sixth one keeps rebooting"
track: "network-plus"
level: "working"
order: 690
objectives:
  - "Add up a switch power budget and say which device fails when it is exceeded"
  - "Explain what detection and classification do before power is applied"
  - "Recognise an injector and device disagreeing about the standard"
  - "Tell a rejected transceiver from an accepted one receiving too little light"
  - "Say what each of these failures looks like from the switch"
prerequisites: ["fibre-and-transceivers"]
tags: ["network-plus", "networking", "troubleshooting", "poe"]
updated: 2026-08-19
draft: false
examObjectives:
  - exam: "n10-009"
    domain: "5.0"
    objective: "5.2"
sources:
  - title: "IEEE 802.3 Standard for Ethernet"
    url: "https://standards.ieee.org/ieee/802.3/10422/"
    publisher: "IEEE Standards Association"
    accessed: 2026-08-19
    tier: 1
  - title: "SFF specifications"
    url: "https://www.snia.org/technology-communities/sff/specifications"
    publisher: "SNIA"
    accessed: 2026-08-19
    tier: 1
symptoms:
  - symptom: "A powered device reboots repeatedly while others on the same switch are fine"
    anchor: "the-budget-is-a-total-not-a-per-port-limit"
  - symptom: "A device works on an injector and not on a switch, or the other way round"
    anchor: "what-happens-before-any-power-flows"
  - symptom: "A fibre port stays down with a transceiver seated in it"
    anchor: "two-ways-a-transceiver-fails"
---

> **Before you read.** Six identical cameras on one small switch, installed on the
> same day by the same person with the same cable. Five of them are perfect. The
> sixth reboots, comes back, works for a while, and reboots again.
>
> It only does it after dark. Swap it with camera three and the fault stays on
> port six.
>
> **The camera is fine and the cable is fine. What is happening on port six?**

Power over Ethernet is the one part of a network where the fault can be somewhere
you were not looking at all, because the thing that fails is not the thing that ran
out. Transceivers have the same quality: the module in your hand is rarely the
problem and the switch will usually tell you what is, if you ask it the right way.

Nothing here is captured. A namespace has no power supply and no optics, so the
evidence on this page is arithmetic you can reproduce and two specifications you can
go and read.

### Some words you will need

<dl class="terms">
<dt>power sourcing equipment</dt>
<dd>The thing supplying power: a switch with PoE ports, or an injector. Abbreviated PSE.</dd>
<dt>powered device</dt>
<dd>The thing being powered: a camera, a phone, an access point. Abbreviated PD.</dd>
<dt>power budget</dt>
<dd>The total watts a switch can supply across all its ports at once, set by its power supply. A separate limit from the per-port maximum.</dd>
<dt>injector</dt>
<dd>A box inserted into a link that adds power to a connection which did not have any. Also called a midspan.</dd>
<dt>receive power</dt>
<dd>How much light a transceiver is actually getting, in dBm. The number that says whether a fibre path is healthy.</dd>
</dl>

## What breaks without this

**The working device gets replaced.** A camera that reboots looks broken, so it gets
swapped for a new one, which also reboots, because the fault was never in the camera.

**Devices are added until something falls over.** A switch with free ports looks like
a switch with free capacity. Power is the resource that runs out first and it is the
one nobody counts.

**A fibre link that is nearly working is treated as a dead one.** A path with too
much loss in it and a path with a broken module produce the same red light on the
front panel and completely different fixes.

## The budget is a total, not a per-port limit

Start with the arithmetic, because the hook is arithmetic and once you have seen it
the symptom stops being mysterious.

A PoE switch has two separate limits. **Each port can supply up to some maximum**,
which depends on which tier of the standard the switch implements. And **the switch as
a whole can supply some total**, set by the size of its power supply, which is almost
always less than the number of ports multiplied by the per-port maximum. A switch
advertising a per-port maximum of 30 watts across 24 ports would need 720 watts to
deliver that everywhere at once, and it does not have 720 watts.

The second limit is the one that surprises people, because nothing about a free port
suggests there is no power left for it.

<figure class="learn-figure">
<svg viewBox="0 0 720 200" role="img" aria-labelledby="budget-title" style="width:100%;height:auto;">
<title id="budget-title">Six cameras drawn against a 65 watt switch budget, fitting easily at their daytime draw of 6 watts each and overflowing at night when each draws 12.95 watts, leaving the sixth outside the budget</title>
<g fill="currentColor">
<text x="14" y="20" font-size="11">the same six devices, twice. only one of these rows fits</text>
<text x="586" y="38" text-anchor="middle" font-size="10">65 W budget</text>
<text x="110" y="60" font-size="10" fill-opacity="0.85">by day, 6 W each</text>
<g fill="currentColor" fill-opacity="0.12" stroke="currentColor" stroke-opacity="0.7">
<rect x="110" y="68" width="42" height="24" rx="3"/>
<rect x="154.1" y="68" width="42" height="24" rx="3"/>
<rect x="198.2" y="68" width="42" height="24" rx="3"/>
<rect x="242.3" y="68" width="42" height="24" rx="3"/>
<rect x="286.4" y="68" width="42" height="24" rx="3"/>
<rect x="330.5" y="68" width="42" height="24" rx="3"/>
</g>
<text x="386" y="84" font-size="9.5" fill-opacity="0.85">36 W used, plenty spare</text>
<text x="110" y="118" font-size="10" fill-opacity="0.85">after dark the illuminators come on, 12.95 W each</text>
<g fill="currentColor" fill-opacity="0.12" stroke="currentColor" stroke-opacity="0.7">
<rect x="110" y="126" width="93" height="24" rx="3"/>
<rect x="205.2" y="126" width="93" height="24" rx="3"/>
<rect x="300.4" y="126" width="93" height="24" rx="3"/>
<rect x="395.6" y="126" width="93" height="24" rx="3"/>
<rect x="490.8" y="126" width="93" height="24" rx="3"/>
</g>
<rect x="586" y="126" width="93" height="24" rx="3" fill="var(--red)" fill-opacity="0.1" stroke="var(--red)" stroke-opacity="0.9" stroke-dasharray="4 3"/>
<g stroke="currentColor" stroke-opacity="0.75" stroke-width="1.3" fill="none" stroke-dasharray="5 4">
<path d="M 586 44 V 158"/>
</g>
<text x="132" y="142" font-size="9.5" fill-opacity="0.85">1</text>
<text x="227" y="142" font-size="9.5" fill-opacity="0.85">2</text>
<text x="322" y="142" font-size="9.5" fill-opacity="0.85">3</text>
<text x="417" y="142" font-size="9.5" fill-opacity="0.85">4</text>
<text x="512" y="142" font-size="9.5" fill-opacity="0.85">5</text>
<text x="608" y="142" font-size="9.5" fill="var(--red)">6</text>
<text x="110" y="180" font-size="9.5" fill-opacity="0.85">77.7 W wanted, 65 W available</text>
<text x="632" y="180" text-anchor="middle" font-size="9.5" fill="var(--red)">denied</text>
</g></svg>
<figcaption>Nothing about camera six is different from camera one. It is sixth in a queue for a resource that runs out between the fifth and the sixth, and only after dark, when every camera's infrared illuminator raises its draw from about six watts to nearly thirteen. The switch does what it is designed to do when the total is exceeded, which is refuse power rather than brown out everything, and the port it refuses is decided by a priority policy rather than by anything wrong with what is plugged into it. That is why swapping the camera changes nothing and swapping it to a different port moves the fault.</figcaption>
</figure>

Now the hook reads straightforwardly. Six cameras, each drawing a little under thirteen
watts once its illuminator is on, want 77.7 watts. The switch has 65. Five of them fit
with a quarter of a watt to spare and the sixth does not fit at all, so the switch
declines to power it. The camera dies, the load drops, the switch may then have room to
power it again, it boots, the illuminator comes on, and the cycle repeats. That is the
reboot loop, and it is a switch behaving correctly.

Two things follow. **The device that fails is not the device that caused the problem.**
Every camera contributed equally and the one at the back of the queue paid for all of
them. And **the fault follows the port rather than the device**, which is the fastest
test available: swap two cameras and if the symptom stays on the port, stop looking at
the hardware.

<details class="deeper">
<summary>If you already install this kit: reading a budget before you buy, and why the last device on it fails first</summary>

The arithmetic above is worth doing before the order goes in rather than after the
cameras are on the wall, and doing it properly means three numbers rather than one.

The first is the switch's total PoE budget, which is on the datasheet and is not the
same as the sum of its ports. The second is what each device actually draws at its
worst, not typical, because the worst is what happens at dusk with every illuminator on
or at nine in the morning with every phone ringing. The third is headroom, because a
budget consumed to ninety-nine percent has no room for the access point somebody adds
next year, and the failure when it arrives will be blamed on the access point.

Then there is the difference between the two numbers every tier of the standard quotes.
The standard states what the switch supplies at the port and, separately, the lower
figure the device is guaranteed to receive, and the gap between them is loss in up to a
hundred metres of copper. So a device that needs 25 watts at its end is not satisfied by
a port rated at 25 watts, and a long run costs more of the gap than a short one. Budget
against the delivered figure, not the supplied one.

Which port loses when the total is exceeded is a policy rather than a law. Switches
commonly take a configured per-port priority and fall back to port order, so the highest
numbered port loses first by default and any port can be protected by saying so. That is
worth setting deliberately on anything that matters, because the default answer to
"which of these six cameras is least important" is "the one plugged in last", and nobody
chose that.

The most useful habit is a label. A sticker on the switch saying what the budget is and
what is currently committed turns next year's addition from a discovery into a
calculation, and it is the cheapest documentation on the rack.

</details>

## What happens before any power flows

A PoE port does not simply have voltage on it. If it did, plugging in a laptop would be
an event, and the whole system is designed so that it is not.

Before power is applied, the switch **detects** whether there is a valid powered device
on the other end by looking for a specific signature resistance across the pairs. No
signature, no power, which is why an ordinary computer plugged into a PoE port is
unharmed and unaware. Then the switch and the device **classify**: the device signals
roughly how much power it needs, so the switch can decide whether it has that much
before committing it. Detection and classification are both in IEEE 802.3, clause 33,
and together they are the reason a PoE network is safe to plug arbitrary things into.

That handshake is also what a cheap injector may not do.

<figure class="learn-figure photo">

![A small black power over Ethernet injector photographed close up. Two sockets sit side by side with transparent-bodied plugs inserted, the individual coloured conductors visible through the housings. The socket on the left is labelled Data In and the one on the right is labelled Data and Power Out.](./images/poe-injector.jpg)

<figcaption>The whole idea of a midspan is printed on the case. Data comes in from a switch that supplies no power, data and power go out to the device, and the box in the middle is where the watts join the link. That asymmetry is the thing to hold onto when one of these is in the path: the two sockets are not interchangeable, and a device wired into the wrong one gets a working data link and no power, which looks exactly like a device that is refusing to boot. The plugs here are the pass-through kind with the conductors visible, which is also a reminder that an injector adds two more terminations to a channel that was already the length it was. Photograph by deavmi, <a href="https://creativecommons.org/licenses/by-sa/4.0/">CC BY-SA 4.0</a>.</figcaption>
</figure>

**Passive injectors do exist and they skip all of it.** They put a fixed voltage on the
spare pairs and hope. A device expecting to negotiate gets a voltage it never agreed to,
which at best means it works by accident and at worst means it does not survive the
experience. They are common in small installations because they are cheap, and they are
the reason "it worked on the injector and not on the switch" and "it worked on the switch
and not on the injector" are both things people say.

**A standards mismatch is the other half of the same story.** An injector or a switch
built to an older, lower tier will detect the device correctly, classify it correctly, and
then supply less than it asked for. The failure that produces is the interesting one: the
device boots, because booting is cheap, and then fails when it does the thing it was
bought for. An access point comes up and drops its radios when clients arrive. A camera
runs all day and dies at dusk. A phone works until somebody makes a call. Anything that
works and then stops working when it gets busy is worth suspecting of a power supply that
is adequate at idle.

<details class="deeper">
<summary>If you already deploy powered devices: the negotiation that happens after the first one</summary>

Detection and classification settle what a device may draw at the moment it powers on, and
several device classes negotiate again afterwards, which is where a subtle fault lives.

A device can signal that it needs more power once it has booted, and the switch grants it if
the budget allows. That is how a camera with an illuminator, or an access point with a
second radio, gets a lower allocation initially and asks for more when it needs it. The
mechanism is sound and it introduces a failure that only appears under the conditions the
extra power was for.

The symptom is a device that works perfectly through commissioning and testing and misbehaves
in production, because commissioning happened in daylight, in an empty building, with the
device idle. Whatever it does when it is busy is exactly what it did not do while anybody was
watching, and the budget it was granted reflects the idle case.

Which argues for testing powered devices under load rather than at installation, and for
reading the switch's allocated power rather than its reported draw. Allocated is what the
device asked for and was granted; draw is what it is using at this moment. A budget planned
against draw measured at noon is planned against the wrong number, and the arithmetic in the
figure above uses the worst case for exactly this reason.

</details>

## Two ways a transceiver fails

Topic 12 covered the four things that have to match at the two ends of a fibre link.
This is what it looks like when one of them does not, and the useful part is that the two
failure modes are easy to tell apart if you know they are different.

**The switch will not accept the module at all.** The module is seated, the port stays
down, and there is a log entry naming the module. That is the switch reading the memory
inside the transceiver, which carries its vendor, part number, type and speed, and
deciding it is unsupported. It may genuinely be the wrong kind of module for the port. It
may also be a perfectly good module from a third party that the switch has been told to
refuse, which topic 12's panel covered. Either way, the fault is in what the module says
about itself and no amount of cleaning the fibre will change it.

**The switch accepts the module and the light is not arriving.** The port is up as far as
the module is concerned and the link never establishes, or it establishes and errors.
This is the one with a number attached, because a module with digital diagnostics reports
its transmit power and its receive power live, and the switch will show you both. A
receive power reading below the module's sensitivity floor is not an ambiguous symptom.
It says the light left the far end and did not arrive, and the amount missing tells you
roughly how bad the path is.

Insufficient receive power has a short list of causes and they are worth knowing in order
of likelihood: a dirty or damaged connector, which is by far the most common and is fixed
with the correct cleaner rather than a sleeve; a path longer or lossier than the module
was chosen for, counting every splice and patch panel along it; a bend tighter than the
fibre's minimum radius, usually where somebody tidied a cabinet; the wrong fibre type,
which topic 12 covered; and a transmitter at the far end that is dying, which the far
switch's transmit power reading will show.

| From the switch you see | What it means | Where to go |
| --- | --- | --- |
| Module rejected, port never comes up | The switch read the module and refused it | The module's type, speed, or vendor |
| Link down, receive power below the floor | Light is leaving and not arriving | Connectors first, then the path, then the far transmitter |
| Link up with errors, receive power near the floor | The path works and has no margin | The same list, but you have time |
| Link down, no receive power reading at all | The module is not reporting, or is not seated | Reseat it, then suspect the module |

<details class="deeper">
<summary>If you already work with optics: why margin is the number that matters, and the fault a clean link develops in three years</summary>

The single reading worth building a habit around is not whether the link is up, it is how
far the receive power sits above the module's sensitivity floor. That gap is the margin,
and a link with a decibel of margin and a link with eight decibels of margin are both
described as working by every dashboard on the network.

They are not equally healthy. Every connector is a small loss, every splice is a smaller
one, and both get worse with handling, dust and time. A path installed with a decibel to
spare has already spent its future: the next time somebody unplugs and replugs that
connector, or the cabinet gets tidied and a bend gets tighter, the link goes from working
to not working with nothing in between and no warning. A path with eight decibels of
margin absorbs all of that.

Which is why the receive power reading belongs in the record when a link is commissioned,
not just when it breaks. A number taken on the day it was installed makes every later
reading a comparison rather than a guess. Without one you are left asking whether minus
seventeen is bad, and the honest answer is that it depends entirely on what it was in
2023.

Digital diagnostics are specified in the SFF documents published through SNIA, so what
the module reports and how it is laid out in the module's memory are readable for free.
The practical value is knowing that transmit power and receive power are both there, at
both ends, which turns "the link is down" into a four-number problem with an obvious
answer: if the far end is transmitting and this end is not receiving, the loss is in the
path between them, and you have just eliminated both switches.

</details>

## Prove it

Nothing here is captured. Two things are checkable and both are worth doing.

**Work out a budget.** Take the switch in the hook: 65 watts total, six devices drawing
12.95 watts each once they are busy. Six times 12.95 is 77.7, so the switch is 12.7 watts
short and five devices is the most it can carry. Now do it with a real datasheet: find a
PoE switch's total budget, find the worst-case draw of the device you want to hang off
it, and divide. The number you get is the number of ports you actually have, and it is
usually smaller than the number of sockets.

**Read clause 33 of IEEE 802.3.** The clause on supplying power over the media dependent
interface, for detection and classification. The question only that clause answers is why
plugging a laptop into a PoE port does nothing at all, and the answer is the reason the
whole scheme is safe. It also states, for each tier, both the power supplied at the port
and the lower figure guaranteed at the device, and the gap between those two numbers is
the one people budget wrongly.

**Read what a transceiver reports about itself.** The SFF specifications published through
SNIA describe the module's memory and its diagnostic monitoring. The question they answer
is what a switch is actually reading when it names a module it will not accept, and where
the receive power figure comes from.

## What trips people up

### 1. Counting ports instead of watts

A free socket is not free capacity. The switch's total budget is set by its power supply
and is almost always well under the per-port maximum times the port count.

### 2. Replacing the device that failed

When a budget is exceeded the switch denies power to a port chosen by policy, not to the
device that is faulty. Swapping that device changes nothing, and swapping it to another
port moves the symptom, which is the test worth running first.

### 3. Budgeting against the supplied figure

The standard quotes what the port supplies and what the device is guaranteed to receive,
and the gap is cable loss. A device needing 25 watts at its end is not satisfied by a port
rated 25 watts, especially at the end of a long run.

### 4. Assuming a device that boots has enough power

Booting is cheap. An access point with too little power comes up and then drops its radios
when clients arrive, and a camera runs all day and dies when its illuminator starts.
Anything that works until it gets busy is a power suspect.

### 5. Treating a passive injector as a small PoE switch

A passive injector applies a fixed voltage without detection or classification. It does
not negotiate, it cannot know what it is powering, and a device expecting to negotiate may
not survive it.

### 6. Reading a fibre link as up or down

A link with a decibel of margin and one with eight are both up. The receive power reading
against the module's floor is the difference between a link that is working and a link
that is about to stop.

## Work it through

Camera six, reasoned out.

Start with the observation that costs nothing: the fault follows the port and not the
camera. That single fact eliminates the camera, its lens, its firmware, and its patch
lead, all of which travelled to port three and behaved perfectly. Whatever is wrong is a
property of port six or of the switch as a whole.

Then notice when it happens. After dark is not a coincidence and it is not a temperature
problem. It is the one moment when every camera on the switch simultaneously increases its
draw, because that is what an infrared illuminator does. A fault that appears when
everything gets busy at once is a shared resource running out, and on a PoE switch there is
exactly one shared resource.

Then do the arithmetic, which takes a minute. Total budget from the datasheet, worst-case
draw per camera from its datasheet, multiply, compare. If the number is over, you have
finished, and you did it without leaving your desk or touching anything.

The fix is then a choice rather than a repair, and it is worth presenting as one. A switch
with a larger budget carries all six. An injector on camera six takes it off the budget
entirely and is the cheap answer. Moving two cameras to a different switch works and
spreads the problem out. Setting a port priority does not fix anything, it just chooses
which camera fails, which is occasionally the right answer if one of the six is watching
something that matters more than the others.

## Try it

**Add up a real switch.** Find any PoE switch datasheet and its total budget, then find
the worst-case draw of an access point or a camera and divide. The gap between the number
of ports and the number of devices it can actually power is the whole of this topic.

**Read clause 33 for the two numbers.** For any tier, the power at the port and the power
at the device. Once you have seen that they differ, budgeting against the wrong one stops
being a mistake you can make.

**Find a receive power reading.** On any switch with fibre in it, look at what the module
reports and at the module's sensitivity floor, and work out the margin. If you can only
find one, find out what it was when the link was installed. Doing that once makes the case
for writing it down at commissioning better than any argument.

## Check yourself

<details class="qa">
<summary>Six identical cameras on one switch. The sixth reboots after dark and the others are fine. Why?</summary>

The switch's total power budget is exceeded once every camera's infrared illuminator comes
on. Each camera goes from about six watts to nearly thirteen, six of those is 77.7 watts,
and the switch has 65, so it can carry five.

When the total is exceeded the switch denies power to a port chosen by priority rather than
by fault, so the device at the back of the queue fails. It loses power, the load drops, it
boots, its illuminator comes on, and the cycle repeats. Nothing is wrong with camera six,
which is why swapping it changes nothing and moving it to another port moves the symptom.

</details>

<details class="qa">
<summary>What does a PoE switch do before it applies power, and why does it matter?</summary>

It detects, then classifies. Detection looks for a signature resistance across the pairs
that says a valid powered device is present, and without it no power is applied at all.
Classification is the device signalling roughly how much power it needs, so the switch can
decide whether it has that much to give.

It matters because it is why a laptop plugged into a PoE port is unharmed and unaware, and
it is what a cheap passive injector does not do. A passive injector applies a fixed voltage
with no handshake, which is why a device can work on a switch and not on an injector.

</details>

<details class="qa">
<summary>An access point comes up, works, and drops its radios once clients connect. What would you suspect?</summary>

Power. Booting is cheap and radios are not, so a device given less power than it needs
comes up perfectly and fails at the moment it starts doing its job.

The usual cause is a standards mismatch: the switch or injector implements a lower tier
than the device expects, detects and classifies correctly, and then supplies less than was
asked for. The other candidate is the same budget problem as the cameras, arriving at the
busiest moment. Both are found by comparing what the device needs at its worst against what
the port can deliver at the end of that cable run.

</details>

<details class="qa">
<summary>A fibre port is down with a module seated in it. What two very different faults look like that?</summary>

The switch refusing the module, and the module receiving too little light.

If the switch has read the module's memory and rejected it as unsupported or as the wrong
type, the port never comes up and there is a log entry naming the module. Cleaning fibre
will not help, because the fault is in what the module says about itself.

If the switch accepted the module, it will report a receive power figure. Below the
module's sensitivity floor means light left the far end and did not arrive, which points at
a dirty connector first, then the length and loss of the path, then a bend, then the
transmitter at the far end. The reading tells you which of the two situations you are in
before you touch anything.

</details>

<details class="qa">
<summary>Two fibre links are up. One has a decibel of margin and one has eight. Are they equally healthy?</summary>

No, and every dashboard on the network will tell you they are. Margin is the gap between the
receive power and the module's sensitivity floor, and it is what a link has left to spend.

Connectors get dusty, cabinets get tidied, bends get tighter, and every one of those costs a
fraction of a decibel. The link with eight decibels absorbs all of it. The link with one goes
from working to down with no intermediate state and no warning, usually while somebody is
doing something unrelated nearby. That is why the reading belongs in the record on the day
the link is commissioned, so later readings are a comparison rather than a guess.

</details>

## References

- [IEEE 802.3 Standard for Ethernet](https://standards.ieee.org/ieee/802.3/10422/) - IEEE Standards Association, clause 33 for supplying power over the media dependent interface: detection, classification, and the power figures at the port and at the device. Accessed 2026-08-19.
- [SFF specifications](https://www.snia.org/technology-communities/sff/specifications) - SNIA, the transceiver form factor and diagnostic monitoring specifications, which is where a module's reported transmit and receive power comes from. Free to read. Accessed 2026-08-19.
- Photograph of the power over Ethernet injector by deavmi, [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/), from [Wikimedia Commons](https://commons.wikimedia.org/wiki/File:Power_over_Ethernet_injector.jpg). Resized and recompressed.

**Where the numbers came from.** Nothing on this page is captured. A network namespace has
no power supply and no optics, so there is no honest way to show either failure happening.
The power figures are IEEE 802.3's, which states for each tier both what the port supplies
and what the device is guaranteed to receive. The six camera arithmetic is worked from those
figures against a stated 65 watt budget, so it is reproducible rather than reported. The
objectives for this exam name power budget and an incorrect standard as failure modes and do
not name any of the standard numbers, so the tiers here come from IEEE 802.3 rather than from
the objectives.
