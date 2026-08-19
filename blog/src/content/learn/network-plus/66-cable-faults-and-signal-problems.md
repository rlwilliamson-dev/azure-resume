---
title: "Cable faults and signal problems"
description: "The link works at 100 Mb and refuses to negotiate 1000. Which faults a continuity tester finds and which it cannot see, why attenuation, crosstalk and interference each leave a different fingerprint, and why the speed a link settles at is the cheapest diagnostic you own."
deck: "The link works at 100 Mb and refuses to negotiate 1000"
track: "network-plus"
level: "working"
order: 670
objectives:
  - "Read a negotiated speed as a count of the pairs that still work"
  - "Tell attenuation, crosstalk and outside interference apart by their symptoms"
  - "Say which termination faults a continuity tester finds and which it passes"
  - "Apply the 100 metre channel limit to a real run, patch leads included"
  - "Recognise the wrong cable type, category or shielding as a fault rather than a preference"
prerequisites: ["copper-cabling"]
tags: ["network-plus", "networking", "troubleshooting", "cabling"]
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
  - title: "TIA standards"
    url: "https://tiaonline.org/standards/"
    publisher: "Telecommunications Industry Association"
    accessed: 2026-08-19
    tier: 1
  - title: "Cat 6A: the fact file"
    url: "https://www.commscope.com/insights/the-enterprise-source/cat6a-the-fact-file/"
    publisher: "CommScope"
    accessed: 2026-08-19
    tier: 2
symptoms:
  - symptom: "A link that used to run at 1000 Mb now comes up at 100"
    anchor: "the-speed-a-link-settles-at-counts-the-pairs"
  - symptom: "A cable passes a tester and the link still errors under load"
    anchor: "termination-faults-and-the-ones-a-tester-misses"
  - symptom: "A link fails only when a nearby machine is running"
    anchor: "three-ways-a-signal-goes-wrong"
---

> **Before you read.** A desk that has always run at a gigabit is suddenly slow.
> The link light is on, the machine is on the network, everything works. The
> switch says the port negotiated 100 Mb, and forcing it to 1000 brings the link
> down entirely.
>
> Nobody changed the switch, the machine, or the configuration. Somebody did move
> the desk.
>
> **The cable is intact enough to carry traffic. What is wrong with it?**

Cable faults are the ones people guess at, because the cable is the part you
cannot see inside and the part everyone suspects last. That is backwards twice
over. Copper faults are common, and most of them announce themselves clearly
enough that you can name the fault before you touch anything, as long as you know
what each one does to the link.

This topic has nothing captured in it. There is no namespace that can be a damaged
cable, and a hand-written transcript of a cable tester would be an invention, so
the evidence here is arithmetic you can reproduce and clauses you can go and read.

### Some words you will need

<dl class="terms">
<dt>continuity</dt>
<dd>Whether a wire is connected end to end. A per-wire property, which is the reason a cheap tester can miss so much.</dd>
<dt>split pair</dt>
<dd>Every pin connected to the right pin at the other end, but using wires taken from two different twisted pairs. Continuity is perfect and the cancellation is gone.</dd>
<dt>transposed pair</dt>
<dd>Two pairs swapped end to end, so the signal arrives on the wrong pins.</dd>
<dt>marginal link</dt>
<dd>A link that works and is close to not working. It passes a quick test and fails under load, heat, or a bit more length.</dd>
<dt>channel</dt>
<dd>The whole path between two pieces of equipment, patch leads included. What the 100 metre limit applies to.</dd>
</dl>

## What breaks without this

**The wrong thing gets replaced, in the wrong order.** A switch is swapped, then
a network card, then the port is moved, and the patch lead that was the fault the
whole time is the last thing anybody touches because it costs three pounds and
looks fine.

**A failing link is signed off as good.** A tester that checks continuity says the
cable is fine, and it is telling the truth about the only thing it measured. The
link keeps dropping frames and nobody trusts the tester again, which is the wrong
lesson.

**A fault that comes and goes gets closed.** Intermittent faults get attributed to
the user, the application, or the weather, and every one of those is a way of
saying nobody found it.

## The speed a link settles at counts the pairs

Start with the fault in the hook, because it is the most useful single diagnostic
in copper and it costs nothing to read.

Twisted pair carries four pairs, eight conductors. **10BASE-T and 100BASE-TX use
two of those pairs**, one to transmit and one to receive, on pins 1 and 2 and pins
3 and 6. **1000BASE-T uses all four**, running a quarter of the traffic on each
pair in both directions at once. That is in IEEE 802.3, clause 25 for the hundred
and clause 40 for the gigabit, and it is the whole explanation for the hook.

<figure class="learn-figure">
<svg viewBox="0 0 720 268" role="img" aria-labelledby="pairs-title" style="width:100%;height:auto;">
<title id="pairs-title">Four twisted pairs drawn as four lanes, with the two pairs used by 100BASE-TX intact and the two extra pairs 1000BASE-T needs broken part way along, so the link negotiates down to 100 rather than failing</title>
<g fill="currentColor">
<text x="14" y="20" font-size="11">two pairs cut, and the link still comes up. it comes up at 100</text>
<text x="14" y="56" font-size="10" fill-opacity="0.85">pins 1, 2</text>
<text x="14" y="98" font-size="10" fill-opacity="0.85">pins 3, 6</text>
<text x="14" y="140" font-size="10" fill-opacity="0.85">pins 4, 5</text>
<text x="14" y="182" font-size="10" fill-opacity="0.85">pins 7, 8</text>
<g stroke="currentColor" stroke-opacity="0.75" stroke-width="1.3" fill="none">
<path d="M 92 50 H 470"/>
<path d="M 92 58 H 470"/>
<path d="M 92 92 H 470"/>
<path d="M 92 100 H 470"/>
</g>
<g stroke="currentColor" stroke-opacity="0.55" stroke-width="1.3" fill="none">
<path d="M 92 134 H 246"/>
<path d="M 92 142 H 246"/>
<path d="M 300 134 H 470"/>
<path d="M 300 142 H 470"/>
<path d="M 92 176 H 246"/>
<path d="M 92 184 H 246"/>
<path d="M 300 176 H 470"/>
<path d="M 300 184 H 470"/>
</g>
<g stroke="var(--red)" stroke-width="2" fill="none">
<path d="M 254 128 l 14 20 M 268 128 l -14 20"/>
<path d="M 254 170 l 14 20 M 268 170 l -14 20"/>
</g>
<text x="228" y="222" font-size="9.5" fill="var(--red)">broken here</text>
<g stroke="currentColor" stroke-opacity="0.7" stroke-width="1.2" fill="none">
<path d="M 486 46 H 496 V 104 H 486"/>
<path d="M 520 46 H 530 V 188 H 520"/>
</g>
<text x="504" y="78" font-size="10">100BASE-TX</text>
<text x="504" y="90" font-size="10" fill-opacity="0.8">needs two</text>
<text x="538" y="112" font-size="10">1000BASE-T</text>
<text x="538" y="124" font-size="10" fill-opacity="0.8">needs four</text>
<text x="14" y="250" font-size="10" fill-opacity="0.85">negotiation settles on the fastest thing both ends can actually run: 100</text>
</g></svg>
<figcaption>Auto-negotiation is not failing here, it is succeeding. Each end advertises what it can do, the link trains, and the two pairs that would have carried the other half of a gigabit are not there, so the highest speed that actually works is a hundred megabits. That is why forcing the port to 1000 takes the link down rather than fixing it: forcing removes the negotiation that was protecting you from a cable which cannot do it. The number on the port is a measurement, and what it measures is how many pairs survived.</figcaption>
</figure>

So a link that used to be gigabit and is now a hundred has almost certainly lost
two pairs somewhere. Three things do that, and all three are ordinary.

A conductor breaks. Copper work-hardens where it is flexed, so the pinch point at
the back of a desk that gets moved, or the bend where a lead leaves a wall socket,
is where it goes. The break needs no visible damage.

A termination only ever had two pairs in it. Plenty of older building cabling was
punched down on pins 1, 2, 3 and 6 only, sometimes so that one cable could carry
two services. It ran 100 Mb perfectly for fifteen years and it will never run a
gigabit.

Or somebody used a lead with two pairs in it. Cheap patch leads with four
conductors exist, sold for phones or for exactly this kind of surprise.

**The diagnostic follows from the fact.** If a link is stuck at 100, swap the patch
lead first, because it is the cheapest half of the channel and the half that moves.
If the speed comes back, you were right. If not, the fault is in the fixed cable and
the next test is at the frame.

<details class="deeper">
<summary>If you already work on networks: why forcing the speed makes it worse, and what half a gigabit would even mean</summary>

Two things sit behind the number on the port.

The first is that forcing speed is not a fix and usually makes the diagnosis
harder. Auto-negotiation on twisted pair exchanges what each end can do and then
trains the link, and a two-pair cable simply cannot complete gigabit training. Set
both ends to 1000 and the link stays down, which at least tells you something. Set
one end to 1000 and leave the other on auto and you get topic 18's duplex mismatch
on top of the cable fault, which is two problems where you had one. The habit is
worth stating plainly: leave negotiation alone while diagnosing, because the
negotiated result is data.

The second is that there is no such thing as running a gigabit on two pairs and
getting half. 1000BASE-T is not four independent lanes that degrade gracefully. It
codes across all four pairs at once and uses echo cancellation to run both
directions on each of them simultaneously, so the link either trains on four pairs
or it does not train at all. The fallback to 100 is not degradation, it is a
different physical layer taking over, which is why the drop is a clean tenfold step
rather than a slide.

That is also why 1000BASE-T is fussier about the cable than 100BASE-TX in every
respect, not just the pair count. Four pairs active in both directions means every
pair is a crosstalk source for the other three at the same moment, and the receiver
is subtracting its own transmission out of what it hears. A cable that is merely
adequate has more to go wrong at a gigabit, which is the general form of the same
lesson: faults show up at the highest speed first.

</details>

## Three ways a signal goes wrong

Once the pair count is not the answer, the question becomes what is happening to
the signal on the pairs that are there. Three things degrade it, and each leaves a
different fingerprint, which is what makes them worth telling apart rather than
lumping together as noise.

**Attenuation** is the signal getting weaker as it travels. It is a property of
distance and it is predictable, which makes it the easiest of the three to reason
about: the fault tracks length. The far desk fails and the near one on the same
switch is fine. A run that was marginal at 90 metres stops working when somebody
adds a 10 metre lead. Temperature matters here too, because copper's resistance
rises as it warms, so an over-length run in a ceiling void can work in February and
fail in July, and TIA's cabling standards reduce the permitted length as temperature
rises for exactly that reason.

**Crosstalk** is the pairs interfering with each other inside the same cable. Its
fingerprint is that it scales with how many pairs are talking, which produces the
strangest-looking symptom in this topic: a link that is clean at 100 Mb and errors
at 1000. Nothing changed about the cable. Two pairs went from silent to busy, and
the noise they inject into their neighbours went with them. Topic 11 covered why
the twisting is what cancels crosstalk in the first place; when it fails, this is
what it looks like.

**Interference from outside** is everything else: motors, lighting ballasts, and
above all mains cable run parallel and close. Its fingerprint is correlation with
something that is not the network. Errors that start at seven in the morning, or
when the lift runs, or when a particular machine on the factory floor is switched
on, are not random, and the pattern is the diagnosis. Shielded cable exists for
this and topic 11 covered when it is worth it.

The reason to separate them is that the fix differs. Attenuation is answered by
shortening the run or accepting a lower speed. Crosstalk is answered by
re-terminating, or by a better cable. Outside interference is answered by moving
the cable away from the source or shielding it, and no amount of re-terminating
will help.

<details class="deeper">
<summary>If you already work on networks: reading the pattern rather than the counter, and the fault that only happens when somebody is at the desk</summary>

The three fingerprints above are worth more than they look, because a switch will
happily tell you a port has errors and will never tell you why.

Length-tracking errors are the easy case: compare the port against another port on
the same switch serving a nearer desk. If the near one is clean, you have already
separated the switch from the cabling without moving anything.

Load-tracking errors are the interesting case, and the useful move is to force the
link down to 100 deliberately, for ten minutes, as a test rather than as a fix. If
the errors stop, you have learned that the fault appears when the extra two pairs
go active, which points at crosstalk or at a marginal termination and away from
almost everything else. Then put it back, because leaving it at 100 is how a
diagnosis becomes a permanent workaround nobody remembers making.

Time-tracking errors are the case people give up on, and they are the reason the
hook in this topic is about somebody moving a desk. A cable that has been damaged
but not severed is a link that works in one position and not in another. The
symptom is that it fails when the user is there and passes every test after they
go home, which reads exactly like a user problem and is not one. Two things make it
findable. Ask what physically moves near it, because a chair, a drawer, or a desk on
castors is a machine for pinching a cable. And where you can, wiggle the lead at
each end while watching the link state, because a fault you can reproduce by hand is
a fault you have located.

</details>

## Termination faults, and the ones a tester misses

Most copper faults are not in the cable. They are in the eight places somebody put
a wire into a hole, which is where the hand work is.

**Wires in the wrong order** is the beginner's fault and the easy one. The two
wiring patterns, T568A and T568B, differ only in swapping two pairs, and either is
correct as long as both ends match. Mixing them makes a crossover, which modern
equipment usually works around by detecting and flipping the pins itself. Usually is
doing work in that sentence: the standard describes automatic MDI and MDI-X
configuration as optional, so equipment exists that will not do it, and on that
equipment the link simply never comes up.

**Excessive untwist** is the invisible one. Untwisting the pairs to get the
conductors into the connector is unavoidable, and the standards allow only a small
amount of it, on the order of half an inch. Fan the pairs out flat because it is
easier to see what you are doing and you have built a crosstalk generator into the
end of the cable. It will pass continuity and it will fail at speed.

**A split pair** is the one worth drawing, because it defeats the test everyone
runs.

<figure class="learn-figure">
<svg viewBox="0 0 720 300" role="img" aria-labelledby="split-title" style="width:100%;height:auto;">
<title id="split-title">A correct pairing where pins 3 and 6 are the two wires of one twisted pair, next to a split pair where pin 3 and pin 6 are connected end to end correctly but come from two different twisted pairs, so continuity passes and the twisting no longer cancels</title>
<g fill="currentColor">
<text x="14" y="20" font-size="11">both wire maps below pass a continuity test. only one of them cancels noise</text>
<text x="14" y="52" font-size="10">correct</text>
<g stroke="currentColor" stroke-opacity="0.75" stroke-width="1.4" fill="none">
<path d="M 96 72 C 180 60 260 84 344 72"/>
<path d="M 96 84 C 180 96 260 72 344 84"/>
</g>
<text x="352" y="72" font-size="9.5" fill-opacity="0.85">pin 3</text>
<text x="352" y="88" font-size="9.5" fill-opacity="0.85">pin 6</text>
<text x="14" y="82" font-size="9.5" fill-opacity="0.8">one pair,</text>
<text x="14" y="94" font-size="9.5" fill-opacity="0.8">twisted</text>
<text x="424" y="78" font-size="10" fill-opacity="0.85">noise hits both wires equally, the</text>
<text x="424" y="92" font-size="10" fill-opacity="0.85">receiver subtracts it, signal survives</text>
<text x="14" y="164" font-size="10">split pair</text>
<g stroke="var(--red)" stroke-opacity="0.85" stroke-width="1.4" fill="none">
<path d="M 96 184 C 180 172 260 196 344 184"/>
<path d="M 96 244 C 180 232 260 256 344 244"/>
</g>
<g stroke="currentColor" stroke-opacity="0.4" stroke-width="1.2" fill="none" stroke-dasharray="3 3">
<path d="M 96 196 C 180 208 260 184 344 196"/>
<path d="M 96 232 C 180 220 260 244 344 232"/>
</g>
<text x="352" y="184" font-size="9.5" fill-opacity="0.85">pin 3</text>
<text x="352" y="248" font-size="9.5" fill-opacity="0.85">pin 6</text>
<text x="14" y="200" font-size="9.5" fill-opacity="0.8">two pairs,</text>
<text x="14" y="212" font-size="9.5" fill-opacity="0.8">one wire</text>
<text x="14" y="224" font-size="9.5" fill-opacity="0.8">from each</text>
<text x="424" y="196" font-size="10" fill="var(--red)">the two signal wires are not twisted</text>
<text x="424" y="210" font-size="10" fill="var(--red)">together, so nothing cancels</text>
<text x="424" y="232" font-size="10" fill-opacity="0.85">every pin reaches the right pin, so</text>
<text x="424" y="246" font-size="10" fill-opacity="0.85">a continuity tester reports a pass</text>
<text x="14" y="286" font-size="10" fill-opacity="0.85">continuity is a fact about one wire. cancellation is a fact about two, and only one test asks</text>
</g></svg>
<figcaption>The lower map is wired correctly pin for pin and is wrong in the only way that matters. Pins 3 and 6 carry one signal as a difference between two wires, and the subtraction that removes noise at the far end only works if those two wires travelled twisted around each other, picking up the same interference. In the split pair they travelled in different twists, picked up different noise, and the subtraction leaves the difference behind. The dashed wires are the two conductors left over, each now paired with a stranger. A tester that lights a lamp per pin cannot see any of this, because every pin does reach the right pin.</figcaption>
</figure>

That is why "the tester says it is fine" and "the link keeps erroring" are not a
contradiction. A two-piece continuity tester answers one question, per wire, and it
answers it honestly. The instrument that would catch a split pair is a certifier,
which measures near-end crosstalk and insertion loss against the category's limits,
and it costs thousands rather than tens. Topic 11 has a photograph of the cheap one
and says what it does not do.

## Wrong cable, wrong category, wrong shielding

Three faults where nothing is damaged and the cable is still the problem.

**The wrong category** drags the whole channel down to itself. A channel is only
what its weakest component is, so one Cat 5e patch lead in a run of Cat 6A cable
gives you a Cat 5e channel, and 10 gigabit will either fail to run or run with
errors. This is a filing problem more than a technical one: the leads all look
alike, the print on the jacket is the only difference, and the drawer is full of
both.

**The wrong shielding** goes both ways. Unshielded cable in a genuinely noisy
environment picks up interference the twisting cannot fully cancel. Shielded cable
is not a free upgrade in the other direction, because the shield has to be bonded
to ground properly at the terminations to carry anything away, and a shield that is
not landed at either end is metal sitting next to your signal wires doing nothing
useful. Shielded systems ask for shielded connectors, shielded patch panels and a
grounding path, and installing half of that is worse than not starting.

**The wrong construction** is the one nobody mentions. Solid conductor cable is for
fixed runs and is what punches down into a jack. Stranded conductor cable is for
patch leads, because it survives being bent, and it is slightly lossier per metre.
The connectors are made for one or the other, and the contacts in a plug meant for
stranded wire bite differently into a solid conductor. It usually works. It works
until it is warm, or until the lead is moved, which puts it back in the intermittent
category above.

## The 100 metre limit is a channel, not a cable

Topic 11 established what the limit is. This topic is about what exceeding it looks
like, and about the arithmetic that catches it before you go up a ladder.

The number is 100 metres end to end, and TIA's model splits it as **90 metres of
fixed horizontal cable plus 10 metres of patch leads at both ends together**. That
second half is what gets exceeded, because the fixed cable was measured once by an
installer and the leads get changed by anybody with a drawer.

Work one:

> A desk is 88 metres of horizontal cable from the frame, which the installer
> certified. There is a 3 metre lead in the frame and a 2 metre lead at the desk.
> Total 93 metres, and the horizontal is under 90, so it is a compliant channel.
>
> Somebody moves the desk across the room and swaps the 2 metre lead for a 15 metre
> one, because that was what was in the drawer. Now the channel is 106 metres and
> the horizontal cable has not changed at all.

Nothing about that is visible from the switch, and the symptom is the whole of this
topic: it might link at a gigabit and error, it might negotiate down, or it might
work today and fail when the ceiling void warms up. The arithmetic takes ten seconds
and the ladder takes an hour, so do the arithmetic first.

## Prove it

Nothing here is captured. The evidence is a clause you can read and a sum you can do.

**IEEE 802.3, clause 25 against clause 40.** Count the pairs each one uses. That
single comparison answers the question this topic opened with, and it is the reason
the negotiated speed is worth reading before anything else: a link at 100 has two
working pairs, a link at 1000 has four. The standard's scope is readable without
buying it, and the pair counts are stated in every summary of both clauses.

**Automatic MDI and MDI-X, in clause 40.** Read that it is described as optional.
That one word is why a crossover cable still exists as a concept, and why "modern
kit sorts it out" is a habit rather than a guarantee.

**TIA's channel model.** The document costs several hundred dollars, so what is
checkable for free is the model itself, which every cabling vendor reproduces: 90
metres fixed, 10 metres of leads, 100 metres total. Take a run you can measure and
add it up including both patch leads. The question only that sum answers is whether
the channel you are about to blame the switch for is legal.

## What trips people up

### 1. Replacing the switch before the patch lead

The switch is expensive, visible, and almost never the fault. The patch lead is
cheap, invisible, and is the half of the channel that gets moved, bent, and swapped.
Test in cost order and you will be right more often and faster.

### 2. Reading "the link is up" as "the cable is fine"

A link comes up on two working pairs and stays up through a great deal of crosstalk.
Up is a very low bar, and the negotiated speed and the error counters are the parts
that carry information.

### 3. Trusting a continuity tester on a link failing at speed

It checks one thing per wire and reports it honestly. A split pair, excessive
untwist and a marginal cable all pass. If the link errors and the tester passes, the
tester is not wrong and neither are you.

### 4. Measuring the cable instead of the channel

The 100 metres includes both patch leads. A compliant fixed run plus a long lead
from the drawer is an over-length channel, and nothing in the room shows it.

### 5. Forcing the speed to prove a point

Forcing 1000 on a two-pair cable takes the link down. Forcing one end and leaving
the other on auto adds topic 18's duplex mismatch to the fault you already had.
Negotiation is producing evidence, so read it rather than overriding it.

### 6. Calling an intermittent fault a user problem

A cable that is damaged and not severed works in one position and not another, so it
fails while somebody is at the desk and passes every test after they leave. That
pattern is a physical fault with a very specific shape, not a person imagining
things.

## Work it through

The desk that dropped to 100 Mb, reasoned out.

Start with what the port is telling you, because it is free. A negotiated 100 on
equipment that has always done 1000 says two pairs are not working, and that alone
rules out most of the things you might otherwise suspect. It is not the switch
configuration, because the switch would report what it was configured to. It is not
the driver. Something in the copper between the two ends has lost half its pairs.

Then split the channel, cheapest half first. The patch lead at the desk moves, gets
trodden on, and gets caught in castors, and it costs almost nothing to swap. If the
gigabit comes back, you are finished, and the old lead goes in the bin rather than
back in the drawer.

If it does not, the fault is in the part of the channel that does not move, which is
suspicious in itself, because fixed cable does not spontaneously break. Ask what
happened near it. A desk moved across the room means the lead may now be longer than
the drawer's contents suggest, so add the channel up. Building work above the ceiling
means somebody may have crushed a bundle. The answer to what changed is usually the
answer.

And if the run turns out to be original two-pair work, terminated on pins 1, 2, 3 and
6 fifteen years ago, then nothing is broken and nothing will fix it short of
re-terminating both ends onto all four pairs. That is a satisfying outcome to reach in
twenty minutes and an expensive one to reach after replacing a switch.

## Try it

**Read the two clauses and count.** IEEE 802.3 clause 25 and clause 40, for the pair
counts. Once you have seen that the hundred uses two and the gigabit uses four, the
negotiated speed stops being a status and becomes a measurement.

**Add up a real channel.** Take any link you can physically follow, measure or
estimate the fixed run, and add both patch leads. Most office links come out well
under 100 metres and the exercise is worth doing precisely for the one that does not.

**Watch a link renegotiate.** Swap a patch lead on a machine you are allowed to
disturb and watch the speed the port reports. It is the fastest way to make the point
concrete that the number is produced by the cable rather than by the configuration.

## Check yourself

<details class="qa">
<summary>A link that always ran at 1000 Mb now negotiates 100. What does that tell you?</summary>

That two of the four pairs are not working. 1000BASE-T uses all four pairs and
100BASE-TX uses two, so a cable with two good pairs will train at 100 and cannot train
at a gigabit.

Auto-negotiation is doing its job: it settled on the fastest speed both ends can
actually run. That is why forcing the port to 1000 brings the link down rather than
fixing it. The likely causes are a broken conductor, a termination that only ever had
two pairs in it, or a lead with four conductors instead of eight.

</details>

<details class="qa">
<summary>A cable passes a continuity tester and the link still errors under load. Is the tester broken?</summary>

No. It answered the question it was asked, which is whether each wire reaches the
right pin at the other end, and every wire does.

A split pair passes that test and fails in use, because the two wires carrying one
signal came from different twisted pairs, so they picked up different noise and the
receiver's subtraction no longer cancels it. Excessive untwist at the termination
passes too. Both are failures of pairing rather than of continuity, and the instrument
that measures them is a certifier that tests crosstalk and insertion loss against the
category limits.

</details>

<details class="qa">
<summary>A link is clean at 100 Mb and errors at 1000. What does that pattern point at?</summary>

Crosstalk, or a marginal termination. Going from 100 to 1000 takes two extra pairs from
silent to busy, so the noise each pair injects into its neighbours arrives at the same
moment the receiver's job gets harder.

The pattern is worth naming because it separates crosstalk from the other two ways a
signal degrades. Attenuation tracks distance, so it shows up as the far desk failing
while the near one is fine. Outside interference tracks something that is not the
network, like a motor or a lift, so its errors correlate with time of day rather than
with load.

</details>

<details class="qa">
<summary>A run is 88 metres of certified horizontal cable. Is a 15 metre patch lead at the desk acceptable?</summary>

No. The limit is a channel, not a cable: 100 metres end to end, modelled as 90 metres
of fixed horizontal cable plus 10 metres of patch leads at both ends combined.

88 plus 15 plus whatever is in the frame is comfortably over 100, and nothing in the
room shows it. The horizontal cable is still compliant and still certified, which is
what makes this fault survive so long: the part somebody measured is fine and the part
nobody measured is what broke it.

</details>

<details class="qa">
<summary>Why is a shielded cable not simply a safer choice than an unshielded one?</summary>

Because the shield only does anything if it is bonded to ground at the terminations,
and that means shielded connectors, shielded panels and a grounding path, not just
shielded cable.

A shielded cable installed into unshielded hardware, or with the drain wire not landed,
is metal running alongside the signal pairs with no path for anything it collects.
Shielding is a system rather than a component, and installing half of it is worse than
choosing unshielded and keeping the cable away from the interference instead.

</details>

## References

- [IEEE 802.3 Standard for Ethernet](https://standards.ieee.org/ieee/802.3/10422/) - IEEE Standards Association. Clause 25 for 100BASE-TX and clause 40 for 1000BASE-T, which is where the pair counts and the optional automatic MDI and MDI-X come from. The scope is readable without purchase; the standard is not. Accessed 2026-08-19.
- [TIA standards](https://tiaonline.org/standards/) - Telecommunications Industry Association, publisher of ANSI/TIA-568, which defines the channel model, the 100 metre limit and the temperature derating. Paid, so the derating figures are named here rather than quoted. Accessed 2026-08-19.
- [Cat 6A: the fact file](https://www.commscope.com/insights/the-enterprise-source/cat6a-the-fact-file/) - CommScope, for the channel model and the alien crosstalk that makes a category a property of the whole path. Free. Accessed 2026-08-19.

**Where the numbers came from.** Nothing on this page is captured, and there is no
honest way to capture it: a Linux namespace has no cable to damage. The pair counts are
from IEEE 802.3, the channel model and its 90 plus 10 split are TIA's, and the two
figures are drawn from those two facts rather than from any measurement. Topic 11
carries the photographs of the cable and the tester this topic reasons about.

**If you also work on Linux systems.** [Hardware and kernel issues](/learn/linux-plus/hardware-and-kernel-issues)
reaches the same place from the other side, where a link that will not come up is
approached through what the driver and the kernel log say about it. The physical fault is
identical and the evidence available to you differs by platform, which is why this topic
stops at the port's reported speed and that one carries on into the log.
