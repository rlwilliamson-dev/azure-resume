---
title: "The rack that overheats every afternoon"
description: "Where cabling terminates and why the hierarchy exists, what a rack unit is, which way the air is supposed to travel and what happens when one switch disagrees, sizing power from the load, and the room conditions that decide whether any of it keeps running."
track: "network-plus"
level: "working"
order: 140
objectives:
  - "Say what an MDF and an IDF are and why the split exists"
  - "Size equipment and a rack in rack units, and account for depth and weight"
  - "Explain port-side intake and exhaust and why airflow direction matters"
  - "Distinguish a UPS from a PDU and size one from a load"
  - "State the environmental conditions equipment needs and why each one matters"
prerequisites: ["copper-cabling"]
tags: ["network-plus", "networking", "physical", "data-centre"]
updated: 2026-08-10
draft: false
examObjectives:
  - exam: "n10-009"
    domain: "2.0"
    objective: "2.4"
sources:
  - title: "Thermal Guidelines for Data Processing Environments, reference card"
    url: "https://xp20.ashrae.org/datacom1_4th/ReferenceCard.pdf"
    publisher: "ASHRAE Technical Committee 9.9"
    accessed: 2026-08-10
    tier: 1
  - title: "Best Practices Guide for Energy-Efficient Data Center Design"
    url: "https://www.energy.gov/sites/default/files/2024-07/best-practice-guide-data-center-design_0.pdf"
    publisher: "US Department of Energy, Federal Energy Management Program"
    accessed: 2026-08-10
    tier: 1
  - title: "NFPA 75, Standard for the Fire Protection of Information Technology Equipment"
    url: "https://www.nfpa.org/codes-and-standards/nfpa-75-standard-development/75"
    publisher: "National Fire Protection Association"
    accessed: 2026-08-10
    tier: 1
  - title: "NFPA 70, National Electrical Code"
    url: "https://www.nfpa.org/codes-and-standards/nfpa-70-standard-development/70"
    publisher: "National Fire Protection Association"
    accessed: 2026-08-10
    tier: 1
symptoms:
  - symptom: "Equipment in one rack runs hot or shuts down under load"
    anchor: "which-way-the-air-is-supposed-to-go"
  - symptom: "A circuit trips when equipment is added to a rack"
    anchor: "power-and-the-two-boxes-that-supply-it"
---

> **Before you read.** A rack of switches works perfectly every morning and
> starts logging thermal warnings around four in the afternoon. By six it has
> settled down again. Nothing was changed, and the air conditioning is working
> and set to the same temperature it has always been.
>
> The room is not too hot. One rack is.
>
> **What is different about the afternoon, and what would you look at first?**

This is the last topic in this stage and the one furthest from anything you can
run. It is also the one where mistakes are most expensive, because everything
here is bolted down, wired in, or built into a room.

### Some words you will need

<dl class="terms">
<dt>MDF</dt>
<dd>Main distribution frame. The one place in a building where the outside world arrives and everything internal converges.</dd>
<dt>IDF</dt>
<dd>Intermediate distribution frame. A local termination point serving one floor or area, linked back to the MDF.</dd>
<dt>rack unit</dt>
<dd>The vertical measure of rack-mounted equipment. One U is 1.75 inches, or 44.45 mm.</dd>
<dt>patch panel</dt>
<dd>A panel where fixed cabling terminates so it can be connected to equipment with short leads.</dd>
<dt>UPS</dt>
<dd>Uninterruptible power supply. Batteries that carry the load between the mains failing and either its return or a generator starting.</dd>
<dt>PDU</dt>
<dd>Power distribution unit. What the equipment actually plugs into inside the rack.</dd>
</dl>

## What breaks without this

**Equipment fails in ways that look like software.** A switch running hot drops
packets, reboots, or behaves oddly on some ports, and every one of those symptoms
sends people to the configuration first.

**A rack runs out of something nobody counted.** Space, power, weight or cooling,
and it is almost never the one you were watching. Discovering the limit during an
installation is expensive because everybody is already on site.

**The room is the single point of failure and nobody wrote that down.** One
circuit, one air conditioner, one door lock. None of it appears in a network
diagram and all of it takes the network down.

## Where the cabling terminates

Buildings are cabled in a hierarchy, and the hierarchy is a direct consequence of
the distance limit from topic 11.

The **main distribution frame** is where the building's services arrive: the
provider's circuit, the core switching, and the point every internal run
ultimately traces back to. There is one.

An **intermediate distribution frame** is a smaller termination point serving an
area, typically a floor, connected back to the MDF by a small number of high
capacity links. There are several.

The reason for the split is the 100 metre channel. A single floor of an office
building can easily be more than 100 metres from one corner to a comms room at
the other end, so a design that runs every desk back to one place does not fit
inside the limit. Putting an IDF on each floor means the horizontal runs to desks
stay short, and the long distances are covered by a handful of fibre links
between IDFs and the MDF, which have no such constraint.

Inside either, the cabling terminates on a **patch panel**: fixed cable punched
down permanently on the back, ports on the front, and short patch leads from
those ports to switch ports. It looks like an unnecessary step and it is the
opposite. The cable in the walls gets terminated once and then never touched
again, and all the moving and changing happens with patch leads, which are cheap
and replaceable.

**Fibre distribution panels** do the same job for fibre, with the additional
requirement of somewhere for spare length to sit in a gentle curve, because fibre
has a minimum bend radius and a tight loop causes loss.

<details class="deeper">
<summary>If you already work on networks: why the hierarchy survived even though the distance argument weakened</summary>

Fibre to the desk has been technically possible for decades, and it would remove
the distance constraint that produced this layout. The hierarchy stayed anyway,
and the reasons are worth knowing because they are the reasons it will keep
staying.

Cost is the obvious one and not the largest. The interesting one is fault
domains. An IDF per floor means a failure is a floor: one switch stack, one
uplink pair, one set of users who know exactly who to call. Consolidating
everything into one room makes every failure a building failure, and it makes
maintenance windows apply to everybody at once.

The second is power and cooling density. Distributing the equipment distributes
the heat and the electrical load into spaces that were designed for a few
kilowatts each. Concentrating it means one room needs the power feed and the
cooling capacity of the whole building's network, which is a construction project
rather than a cabinet.

The third is the one that decides it in practice: the building already has the
cabling. Horizontal runs to desks are the most expensive part of a cabling
installation and they are in the walls. A design that requires replacing them is
competing with a design that requires nothing.

Where the hierarchy genuinely does change is in the data centre, where the
distances are short, the density is enormous, and top-of-rack switching puts the
first switch a metre from the servers. That is a different problem with a
different answer, and it is worth not carrying office building instincts into it.

</details>

## The rack, and the unit it is measured in

A rack is 19 inches wide between the mounting rails, and that has been true since
long before computers were put in them. Equipment height is measured in rack
units, where **one U is 1.75 inches, or 44.45 millimetres.**

A full height rack is commonly 42U, with 45U and 47U also usual. A switch is
typically 1U, a server 1U or 2U, and a chassis switch several.

Counting U is the easy part, and it is the part people do. Three other numbers
run out first.

**Depth.** The 19 inch figure is the width between rails and says nothing about
how deep the rack is or how deep the equipment is. A network cabinet sized for
switches will not take servers, and a rack that fits the equipment may not leave
room for the cables and power leads behind it.

**Weight.** Racks and floors have limits, and a full rack of equipment plus a UPS
is heavy enough that raised floors and older buildings genuinely need checking.
Batteries are the worst offender per unit of height.

**Power and heat**, which the next two sections are about, and which are the ones
that actually run out.

Two conventions worth adopting. Leave the top and bottom few U free, because
cable management and patch panels want space and something always has to be added
later. And mount the heaviest items at the bottom, which is a stability point
rather than a preference.

<details class="deeper">
<summary>If you already work on networks: the measurements that catch people, and rail depth in particular</summary>

Three specific traps, all of which are discovered with the equipment already
unboxed on site.

**Rail depth and rail type.** Server rails adjust within a range, and a rack whose
front and rear rails are set too close or too far apart is outside it. Racks
ordered without specifying depth arrive at whatever the supplier defaults to.
Measuring the existing rack before ordering equipment takes two minutes and the
alternative is a server sitting on the floor of the rack overnight.

**The square hole standard.** Modern racks have square holes taking cage nuts,
older ones are threaded, and equipment ships with fixings for one of them. This
is a five pound part that stops an installation dead at eight in the evening.

**Cable radius behind the rack.** Copper and fibre both have minimum bend radii,
and a rack pushed against a wall with no rear clearance forces cables into tighter
curves than they should take. On copper this degrades the run in ways a certifier
would fail. On fibre it causes measurable loss immediately.

The general habit that prevents all three: the constraint on a rack is rarely the
number of free U. Before ordering, check depth, rail type, weight capacity,
available circuit capacity and rear clearance, and write the answers down.
Nobody who has done this once ever skips it again.

</details>

## Which way the air is supposed to go

Now the question at the top.

Equipment is designed to draw cool air in one side and push hot air out the
other, and a room full of equipment only works if every device agrees on which
direction that is. The arrangement that makes it work is hot aisle and cold
aisle: racks in rows, fronts facing fronts across one aisle and backs facing
backs across the next. Cold air is delivered to the aisle everything is facing,
and hot exhaust is collected from the aisle behind.

**Servers almost always take air in at the front and exhaust at the back**, so
they cooperate with this naturally.

Network switches are the problem. A switch's ports are usually on the front,
which is where the cabling has to be, so a switch drawing air in through its port
side is drawing from the cold aisle correctly, and one exhausting through its port
side is dumping hot air straight into the cold aisle everything else is breathing.
That is why vendors sell the same switch in two airflow versions, described as
**port-side intake** and **port-side exhaust**, and why choosing the wrong one is
a real ordering mistake rather than a detail.

One switch blowing the wrong way does not merely fail to help. It actively
recirculates its own exhaust into the intake of whatever is next to it, and the
symptom is a rack that is fine when lightly loaded and overheats when everything
is working hard.

Which is the afternoon. The room temperature has not changed; the load has. Warmer
afternoon ambient, more traffic, and every device drawing more power and producing
more heat, until recirculation that was survivable in the morning is not. So the
first thing to look at is not the air conditioning, it is the direction of airflow
in that rack and whether anything is exhausting where something else is inhaling.
The second is whether blanking panels are fitted, because an empty U with no panel
lets hot air from behind the rack come straight through to the front.

<details class="deeper">
<summary>If you already work on networks: containment, and why the cheap fixes come first</summary>

Hot aisle and cold aisle gets most of the benefit. Containment gets the rest, by
physically separating the two so the air cannot mix at all.

Cold aisle containment puts doors at the ends of the cold aisle and a roof over
it, so the cold air stays where the equipment is breathing. Hot aisle containment
does the same to the hot aisle and returns that air directly to the cooling
plant. Both work; which is better depends on the room, and the argument between
them is a data centre design argument rather than a networking one.

The reason it matters is efficiency rather than possibility. Without containment,
the supply air has to be colder than the equipment needs, because some of it will
mix with exhaust before arriving. With containment, the supply temperature can
rise, and the cooling plant does dramatically less work for the same result. The
Department of Energy's data centre design guide treats airflow management as the
first thing to fix for exactly this reason: it is cheaper than adding cooling
capacity and it frequently removes the need to.

Which is the practical point worth taking away. The interventions in this area
run in a clear order of cost, and people usually start at the wrong end.

Blanking panels in empty rack units cost a few pounds each and stop hot air
recirculating through the gaps. Sealing floor cutouts where cables pass through
stops cold air escaping where no equipment is. Correcting the airflow direction on
a mis-specified switch costs a replacement module or an airflow kit. All three of
those come before containment, and containment comes before more cooling capacity.

The failure mode is a room whose response to a hot rack is to lower the set point
for the whole room, which costs a great deal of energy continuously and does not
fix a recirculation problem at all.

</details>

## Power, and the two boxes that supply it

Two devices, frequently confused, doing unrelated jobs.

A **UPS** provides power when the mains does not. Its battery carries the load
across a cut, and what it is sized for depends on the design: enough time for
equipment to shut down cleanly, or enough to cover the gap until a generator
starts and takes over.

A **PDU** distributes power inside the rack. It is what equipment plugs into, and
it ranges from a metal strip with sockets to a managed unit that reports current
per outlet and can switch individual outlets remotely.

Neither replaces the other. The UPS answers what happens when the power fails and
the PDU answers how it reaches the equipment.

Three numbers decide whether a design works.

**Load** is what the equipment actually draws, in watts or amps. Nameplate ratings
are worst case and usually well above real consumption, but sizing on measured
draw with no margin means the first addition trips a breaker.

**Voltage** varies by region and by circuit type, and higher voltage carries the
same power at lower current, which is why data centres often run equipment at 208
or 230 volts rather than 120. Equipment with a universal supply takes either;
equipment without it does not, and finding out is expensive.

**Circuit capacity** is what the building can deliver to that rack, and it is
frequently the real limit long before space runs out. A 16 amp circuit is a
ceiling regardless of how many free rack units are above it.

<details class="deeper">
<summary>If you already work on networks: sizing a UPS, and the two units that are not the same</summary>

UPS capacity is quoted in volt-amps and equipment consumption is quoted in watts,
and treating those as interchangeable is how a UPS ends up undersized on the day
it is needed.

Volt-amps are apparent power, voltage multiplied by current. Watts are real
power, the part actually doing work. The ratio between them is the power factor,
and for modern equipment with a corrected supply it is high, commonly around 0.9.
So a UPS rated 1000 VA delivers roughly 900 W, not 1000, and a load specified in
watts has to be divided by the power factor before it can be compared to a VA
rating.

Sizing runs in four steps, and only the first is arithmetic.

Add up the real load in watts, measured rather than from nameplates where you
can, because nameplate figures are worst case and frequently double the truth.
Convert to VA using the UPS's stated power factor. Add headroom, because equipment
gets added and a UPS running at its limit has no runtime margin. Then, separately,
work out the runtime you need, which is not a capacity question but a battery
question: the same UPS gives a different runtime at different loads, and vendors
publish that curve.

The step people miss is the last one, and it inverts the usual assumption. Runtime
falls off sharply as load rises, so a UPS at 80 percent of capacity may give you
minutes where the same unit at 40 percent gives half an hour. If the requirement
is to survive until a generator starts, minutes are fine. If it is to shut a
dozen systems down cleanly, minutes are not.

Two more things that are not about capacity at all. Batteries age, lose capacity
predictably, and need replacing on a schedule regardless of whether the UPS has
ever been used, and a UPS that has never been tested under load is an assumption
rather than a control. And a UPS protects against a mains failure, not against
somebody switching off the wrong circuit, which is the more common cause of an
unplanned outage in a comms room.

</details>

## The room itself

Four conditions, and the exam names all of them.

**Temperature.** ASHRAE's thermal guidelines give a recommended range of 18 to 27
degrees Celsius, which is 64.4 to 80.6 Fahrenheit, for the common equipment
class. The top of that range surprises people who expect a server room to be
cold. It is deliberate: running warmer within the recommended envelope uses
dramatically less cooling energy and equipment is designed for it.

**Humidity.** Both directions cause problems. Too dry and static discharge
becomes a risk to components during handling. Too damp and you get condensation
and corrosion over time. ASHRAE's recommended envelope for that class runs from 8
percent relative humidity, with a dew point floor beneath it, up to 70 percent.

**Fire suppression**, which is the next panel.

**Physical security.** Locking cabinets, controlled access to the room, and a
record of who went in. A network is only as secure as the ability to walk up to a
switch and plug into it, and everything in the security domain later in this
track assumes nobody can.

<details class="deeper">
<summary>If you already work on networks: why the wrong extinguisher ruins the room</summary>

Fire suppression in a room full of electronics has a requirement most fire
protection does not: the equipment should ideally survive the suppression.

**Water** works and is destructive. Standard sprinklers protect the building and
the people in it, which is their job and is not negotiable, but a discharge over
live equipment ends that equipment. Pre-action systems are the compromise: the
pipes are kept dry and only fill when a detector triggers, so a damaged sprinkler
head does not flood a room, and a fire still gets water.

**Clean agents** are the equipment-friendly answer. Gaseous agents flood the room
and interrupt combustion without leaving residue, so equipment that was not
burning is generally recoverable. They are expensive, need a sealed room to hold
concentration, and the room needs the seals maintained, which is the part that
gets forgotten.

**Inert gas systems** reduce oxygen below what combustion needs. They work, leave
nothing behind, and require careful design because people may be in the room.

Now the ones that ruin the room, which is the actual point.

**Dry chemical and dry powder extinguishers** are extremely effective on fire and
disastrous for electronics. The powder is finely divided, conductive or corrosive
depending on type, and it gets into everything: every fan intake, every card
edge, every connector. Equipment that was nowhere near the fire is written off,
and the cleanup is a specialist job. A dry powder extinguisher mounted in a comms
room is a mistake waiting for somebody to do the right thing with the wrong tool.

**Foam** is the same story with liquid.

So the extinguishers in the room should be clean agent or carbon dioxide, and this
is worth checking the next time you are in one, because it is common to find
whatever the building standard extinguisher is. NFPA 75 is the standard covering
fire protection for information technology equipment and is the document to point
at when raising it.

The framing that makes this land with people who control the budget: the fire is
one risk and the suppression is another, and the second one is the more likely of
the two to happen to your equipment.

</details>

## Prove it

No commands again, so the evidence is a document, a question, and one measurement
you can take yourself.

**The ASHRAE thermal guidelines reference card.** ASHRAE publish a free summary
card of the thermal guidelines for data processing environments. Open it and find
the recommended envelope, then answer: what is the top of the recommended
temperature range, and is that higher or lower than the temperature the server
room you have seen was actually kept at? Most people are surprised in the same
direction.

**The Department of Energy's data centre design guide.** Free, and unusually
readable for a government document. Find what it says about airflow management
and answer: does it recommend adding cooling capacity or fixing air mixing first,
and why?

**NFPA 75.** The standard for fire protection of information technology
equipment. Free read-only access after registration, like NFPA 70 in topic 11.
Worth knowing exists so that a conversation about extinguishers has a document
behind it rather than an opinion.

Then take one measurement. If you have access to any room with equipment in it,
stand behind the rack and then in front of it. You will feel the difference
immediately, and you will be able to tell whether every device in that rack is
pointing the same way. That is the whole of the airflow section, verifiable in
about thirty seconds without a tool.

## What trips people up

### 1. Counting rack units and nothing else

Space is rarely the constraint that runs out. Circuit capacity, depth, weight and
cooling all reach their limits sooner, and all of them are cheaper to check before
ordering than after delivery.

### 2. Assuming every device is front to back

Servers usually are. Switches are sold in two airflow directions because their
ports are on the front, and installing a port-side exhaust switch in a
front-facing rack blows hot air into the cold aisle.

### 3. Treating VA and watts as the same number

A UPS is rated in volt-amps and equipment draws watts, and the ratio between them
is the power factor. A 1000 VA unit does not deliver 1000 W, and sizing that
ignores the difference produces a UPS that is undersized exactly when it is
needed.

### 4. Sizing a UPS for capacity and forgetting runtime

They are different questions. The same unit gives very different runtimes at
different loads, and a design that needs enough time for a clean shutdown of a
dozen systems needs a runtime figure, not just a capacity figure.

### 5. Believing a server room should be cold

The recommended range goes up to 27 degrees Celsius. Running colder costs energy
continuously and buys nothing the equipment needed, and it is often a response to
a hot spot that airflow management would have fixed for a fraction of the cost.

### 6. Leaving whatever extinguisher the building supplied

Dry powder is excellent on fire and destroys electronics that were nowhere near
it. A comms room wants a clean agent or carbon dioxide, and this is a five minute
check that almost nobody performs.

## Work it through

A company is converting a storeroom on the second floor into an IDF. It will hold
one 24U cabinet with two switches, a patch panel, a small UPS and a fibre panel
back to the MDF in the basement. Somebody has confirmed the cabinet fits through
the door and considers the planning done.

Work the constraints in order of how expensive they are to discover late, which
is roughly the reverse of how obvious they are.

Power first, because it is the one with a lead time. What circuit serves that
room? A storeroom is likely to be on a lighting or general socket circuit shared
with other things, which is not what a rack of equipment and a UPS should be on.
A dedicated circuit means an electrician and a schedule, and finding that out now
costs an email rather than a delay.

Cooling second. A storeroom has no cooling, and a sealed room with two switches
and a UPS in it will reach a temperature the equipment does not like, especially
in the afternoon. The options run from a vent to a small dedicated unit, and all
of them involve somebody who is not in IT. This is also the point to ask whether
the ceiling void is a plenum, because that decides the cable rating from topic 11.

Distance third, and this is the one that is cheap to check and awkward to fix.
Every desk this IDF will serve has to be within the 100 metre channel budget from
this room. On a large floor plate a storeroom in a corner may not reach the far
corner, and the fix is a second IDF or a different room.

Then the ordinary things. Cabinet depth against the equipment, weight against the
floor, a lock on the cabinet and controlled access to the room, and blanking
panels in the empty U so the airflow works as intended in a cabinet that will be
mostly empty for a year.

The pattern worth extracting: the network parts of this are the easy parts. What
decides whether the room works is power, cooling, distance and access, and none of
those is answered by anyone on the network team.

## Try it

**Stand behind a rack.** Anywhere you have access to equipment, feel the front and
then the back. Check whether every device is pointing the same way, and look for
empty rack units with no blanking panel. Both take seconds and both are real
findings.

**Read the ASHRAE card.** It is free, it is one page, and knowing the recommended
range is one of the few numbers in this topic worth carrying exactly.

**Find the extinguisher.** Next time you are in a room with equipment in it, read
the label on the extinguisher by the door. If it is dry powder, you have found
something worth raising, and NFPA 75 is the document to raise it with.

## Check yourself

<details class="qa">
<summary>A rack overheats in the afternoon and is fine in the morning. The room temperature is unchanged. What is the likely cause and what would you check first?</summary>

Heat recirculating inside the rack, becoming survivable and unsurvivable
depending on load.

Room temperature being unchanged rules out the cooling plant as the primary
cause. What changes during the day is load, which raises both the heat produced
and the air each device needs, until an airflow problem that was tolerable at
lower load is not.

Check the direction of airflow on every device in the rack, looking for anything
exhausting into the aisle other equipment is drawing from, which is usually a
port-side exhaust switch in a rack of front-to-back equipment. Then check for
empty rack units without blanking panels, which let hot air pass from the back of
the rack to the front.

Lowering the room set point would mask it, cost energy continuously, and leave
the recirculation in place.

</details>

<details class="qa">
<summary>Why do buildings have an MDF and several IDFs rather than one room everything runs back to?</summary>

Originally because of the 100 metre channel limit. A floor can easily be more than
100 metres from a single comms room, so horizontal runs to desks have to start
somewhere closer.

The arrangement survives for reasons beyond distance. It keeps failures local to a
floor rather than making every fault a building fault. It distributes power and
cooling load into spaces sized for it, instead of concentrating the whole
building's requirement into one room. And the horizontal cabling already exists,
which makes any design requiring its replacement expensive by comparison.

</details>

<details class="qa">
<summary>A UPS is rated at 1500 VA. Equipment in the rack draws 1200 W. Is that enough?</summary>

Not necessarily, and the numbers cannot be compared directly.

VA is apparent power and watts are real power, related by the power factor. At a
typical corrected power factor around 0.9, a 1500 VA unit delivers roughly 1350 W,
so 1200 W fits with very little headroom.

Two things make that uncomfortable. There is almost no margin for equipment being
added, which always happens. And runtime falls sharply as load rises, so at 90
percent of capacity the battery time may be a few minutes, which is fine if a
generator is starting and not fine if the requirement is a clean shutdown.

The answer is that it fits arithmetically and is the wrong size for most real
requirements.

</details>

<details class="qa">
<summary>What is port-side intake, and why is it something you have to specify when ordering?</summary>

It describes which way a switch moves air relative to the side its ports are on.
Port-side intake draws cool air in through the port face and exhausts out the
back.

It has to be specified because switches are sold in both directions, and the right
one depends on which way the rack faces. In a hot aisle and cold aisle layout
every device must draw from the cold aisle and exhaust to the hot one. A switch
with the wrong airflow does not merely fail to cooperate, it pushes its exhaust
into the air its neighbours are breathing.

Servers rarely raise this because they are almost always front to back. Switches
raise it because their cabling has to be accessible, which puts the ports where
the airflow decision becomes a choice.

</details>

<details class="qa">
<summary>Why is a dry powder extinguisher a bad idea in a room full of network equipment?</summary>

Because it destroys equipment the fire never reached.

The powder is finely divided and gets drawn into everything with an air intake:
fans, card edges, connectors, across the whole room. Depending on the type it is
conductive or corrosive. Equipment that was working normally a metre away is
written off, and the cleanup is a specialist job.

The suitable options are clean agent systems, which interrupt combustion without
residue, inert gas systems, or carbon dioxide extinguishers. Pre-action sprinklers
are the compromise where water is required: the pipes stay dry until a detector
triggers, so a broken head does not flood the room.

NFPA 75 covers fire protection for information technology equipment and is the
reference for the conversation.

</details>

<details class="qa">
<summary>What is the recommended temperature range for equipment, and why does it surprise people?</summary>

ASHRAE's recommended envelope is 18 to 27 degrees Celsius, 64.4 to 80.6
Fahrenheit, for the common equipment class.

It surprises people because the top of the range is much warmer than the
uncomfortably cold server room they have stood in. Running at the warm end of the
recommended envelope uses considerably less cooling energy, and equipment is
designed for it.

The usual reason a room is kept colder than it needs to be is a hot spot
somewhere in it, and lowering the whole room's set point is the expensive way to
address a problem that airflow management would fix.

</details>

## References

- [Thermal Guidelines for Data Processing Environments, reference card](https://xp20.ashrae.org/datacom1_4th/ReferenceCard.pdf) - ASHRAE Technical Committee 9.9, the recommended temperature and humidity envelopes. Free. Accessed 2026-08-10.
- [Best Practices Guide for Energy-Efficient Data Center Design](https://www.energy.gov/sites/default/files/2024-07/best-practice-guide-data-center-design_0.pdf) - US Department of Energy, on airflow management before cooling capacity. Free. Accessed 2026-08-10.
- [NFPA 75, Fire Protection of Information Technology Equipment](https://www.nfpa.org/codes-and-standards/nfpa-75-standard-development/75) - National Fire Protection Association. Free read-only access after registration. Accessed 2026-08-10.
- [NFPA 70, National Electrical Code](https://www.nfpa.org/codes-and-standards/nfpa-70-standard-development/70) - National Fire Protection Association, for the circuit and cable questions this topic touches. Accessed 2026-08-10.

**Where the numbers came from.** Nothing on this page is captured. The
temperature and humidity envelopes are ASHRAE's own published figures, and the
airflow guidance is from the Department of Energy's design guide, both of which
are free to read, so this topic is better sourced than the copper one before it.
The rack dimensions are long-standing conventions rather than figures taken from
a standard this page has read: the 19 inch width and the 1.75 inch rack unit
predate the equipment in them and are defined in standards that are not free.
Power factor figures are typical values rather than a specification, which is why
the panel says to use the figure the UPS itself states.

**If you also work on Linux.** Nothing here has a Linux counterpart. A machine
can report its own temperature sensors and knows nothing about the room, the
rack, the airflow or the circuit it is on.
