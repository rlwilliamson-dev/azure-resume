---
title: "The systems you cannot patch"
description: "Industrial controllers, real-time and embedded systems, and IoT devices, why availability outranks confidentiality wherever a computer moves something physical, and what is left to do when the patch will never exist."
deck: "The controller runs the production line. Its last firmware update was in 2011 and the vendor is gone"
track: "security-plus"
level: "working"
order: 300
objectives:
  - "Describe industrial control systems, SCADA, real-time operating systems, embedded systems and IoT, and what they share"
  - "Explain why availability outranks confidentiality where a computer controls a physical process"
  - "Treat inability to patch as a permanent condition and plan for it"
  - "Say which responses to a vulnerability remain when patching, rebooting and replacing are all unavailable"
  - "Explain why discovery on a control network is passive by default"
  - "Say what a real-time constraint does to the choice of encryption"
prerequisites: ["on-premises-virtualised-and-air-gapped"]
tags: ["security-plus", "security", "architecture", "ics"]
updated: 2026-10-07
draft: false
examObjectives:
  - exam: "sy0-701"
    domain: "3.0"
    objective: "3.1"
sources:
  - title: "SP 800-82 Rev. 3, Guide to Operational Technology (OT) Security"
    url: "https://csrc.nist.gov/pubs/sp/800/82/r3/final"
    publisher: "NIST"
    accessed: 2026-10-07
    tier: 1
  - title: "NIST IR 8259, Foundational Cybersecurity Activities for IoT Device Manufacturers"
    url: "https://csrc.nist.gov/pubs/ir/8259/final"
    publisher: "NIST"
    accessed: 2026-10-07
    tier: 1
  - title: "SP 800-213, IoT Device Cybersecurity Guidance for the Federal Government"
    url: "https://csrc.nist.gov/pubs/sp/800/213/final"
    publisher: "NIST"
    accessed: 2026-10-07
    tier: 1
symptoms:
  - symptom: "A device has a published vulnerability and no fix will ever be released"
    anchor: "when-the-patch-will-never-come"
  - symptom: "Somebody wants to run a vulnerability scan against a control network"
    anchor: "availability-first"
---

> **Before you read.** A controller runs a production line that makes money every
> minute it moves. Its firmware was last updated in 2011. The company that made it
> was bought, the product line was discontinued, and a vulnerability affecting it
> was published last week.
>
> **What is the security team's first job?**

Not patching, because there is nothing to install and never will be. The first job
is accepting that this is a permanent condition rather than an item on a backlog,
and then deciding what can be done around a device that cannot be changed. Most of
security practice assumes the vulnerable thing can be fixed. This topic is about
the large and growing set of computers where that assumption is false.

### Some words you will need

<dl class="terms">
<dt>industrial control system</dt>
<dd>Computers that operate a physical process: valves, motors, presses, pumps. Abbreviated ICS.</dd>
<dt>SCADA</dt>
<dd>Supervisory control and data acquisition. The layer that monitors and directs controllers spread across a site or a region.</dd>
<dt>PLC</dt>
<dd>Programmable logic controller. A ruggedised computer that reads sensors and drives equipment in a fixed loop.</dd>
<dt>RTOS</dt>
<dd>Real-time operating system. One that guarantees a task completes within a deadline, every time.</dd>
<dt>embedded system</dt>
<dd>A computer built into a device to do one job, usually with no keyboard, no screen and no update mechanism anybody uses.</dd>
<dt>IoT</dt>
<dd>Internet of things. Network-connected devices that are not general-purpose computers.</dd>
<dt>operational technology</dt>
<dd>The collective name for the systems that control physical equipment, as opposed to information technology.</dd>
<dt>compensating control</dt>
<dd>A control that reduces a risk the intended control cannot, because the intended one is unavailable.</dd>
</dl>

## Four kinds of system with one problem

The objective lists industrial control systems, SCADA, real-time operating systems,
embedded systems and IoT as separate items. They differ in scale and purpose and
share one property that matters more than any of their differences: changing them
is expensive, risky, or impossible.

<figure class="learn-figure photo">

![An open grey steel cabinet mounted outdoors at an oil field site. Rows of terminal blocks run across the top and bottom, a programmable logic controller rack with several input and output modules sits in the middle row beside a small network switch with blue cables, and a laptop rests on a shelf near the bottom with its cable plugged into the cabinet.](./images/plc-field-cabinet.jpg)

<figcaption>A programmable logic controller in a field cabinet at an oil tank battery. The controller is the row of modules in the middle, each one wired to sensors and equipment through the terminal blocks above and below. Two other things in the frame matter more for security than the controller does. The small device to its left with blue cables is a network switch, which means this controller is reachable over a network rather than isolated. And the laptop on the shelf is plugged in, which is how programs and settings reach a controller like this: an engineer carries a machine to the cabinet and connects it. Photograph by sirdle, CC BY-SA 2.0.</figcaption>
</figure>

**Industrial control systems and SCADA run physical processes.** A controller reads
sensors and drives equipment in a loop that may run for years without stopping.
SCADA sits above, gathering readings from many controllers and letting operators
direct them from a control room. The equipment has a service life measured in
decades, and the computers in it are expected to last as long as the machinery.

**Real-time operating systems guarantee deadlines.** The point of an RTOS is not
speed but predictability: a brake controller, a medical pump or a flight system
must respond within a fixed time every time. Anything that adds unpredictable
delay, including some security features, is a defect in that context.

**Embedded systems do one job inside something else.** A badge reader, a printer, a
building management controller, a network appliance. They often run an operating
system nobody at the organisation knows is there, and updating them, where possible
at all, is a manual task nobody owns.

**IoT devices are embedded systems that were connected.** Cameras, sensors,
thermostats and smart displays, bought in quantity, often by facilities rather than
by technology, with update support that ends when the manufacturer moves to the
next model.

## Availability first

In most information systems confidentiality is the property people protect first.
Where a computer moves something physical, the order inverts.

**A stopped production line costs money every minute, and a stopped safety system
can cost more than money.** So the priority is that the process keeps running
correctly, then that its data is accurate, and only then that it is secret. Almost
every security decision in an industrial setting follows from that order.

**It changes how security work itself is done.** A patch that requires a reboot
waits for a planned shutdown, which may be annual. Endpoint software that scans
files is rejected if it might pause a process at the wrong moment. Even looking at
the network has to be done carefully.

<details class="predict">
<summary>A vulnerability scanner is pointed at a control network for the first time, with the settings used on the office network. Predict the most likely bad outcome.</summary>

**Disrupting the devices it is scanning, not missing anything.**

Older controllers and embedded devices were built for a quiet network carrying
predictable traffic. Their network stacks may be minimal and poorly tested against
unexpected input. A scanner that probes every port and sends malformed packets to
see what answers can make such a device stop responding, or restart, and on a
control network that is a process outage caused by the security team.

That is why discovery on a control network is passive by default. Instead of
probing devices, a passive approach listens to traffic already crossing the network
and builds an inventory from what devices say to each other. It is slower and it
misses devices that are quiet, and it never puts the process at risk.

Where active scanning is used at all, it is scheduled with the operations team,
during a maintenance window, against a test system first, with settings agreed for
each device type. The asset inventory is often built from documentation and
engineering records instead, which is less complete and does not interrupt
anything.

</details>

<details class="deeper">
<summary>Why a safety system cannot take a reboot, and what that does to the security plan</summary>

Many industrial processes have two layers of control. The control system runs the
process normally. A separate safety system watches for dangerous conditions,
pressures, temperatures or speeds outside safe limits, and takes the process to a
safe state if they occur.

**The safety system is protection that has to be present at all times.** If it is
restarted, reconfigured or interrupted, the process is running without its last
line of defence for that period. That is why changes to it are rare, planned and
heavily reviewed, and why the people responsible for it are reluctant to let
anybody near it, including security staff with good intentions.

**So the security plan works around it rather than through it.** Monitoring is
passive. Changes go through the same engineering change process as any other
modification to a safety function. The strongest available protection is keeping
it separate: its own network, no shared accounts with the control system, and no
path from the office network that does not cross several controls.

**And the organisational point matters as much as the technical one.** Security
teams that arrive with an information technology playbook, mandatory patch
deadlines and agent installs, tend to be excluded from operational environments
entirely, which leaves those environments with no security input at all. The ones
that succeed start by learning what must not stop, and propose controls that
respect it.

</details>

## When the patch will never come

Inability to patch is usually described as a temporary state: a backlog item, an
exception with a date. For a controller whose vendor no longer exists, it is
permanent, and treating it as temporary produces an exception that is renewed
forever without anything changing.

<figure class="learn-figure">
<svg viewBox="0 0 720 310" role="img" aria-labelledby="unpatch-title" style="width:100%;height:auto;">
<title id="unpatch-title">The same vulnerability on an office server and on an industrial controller, with seven possible responses, three of which are unavailable for the controller</title>
<g fill="currentColor">
<text x="14" y="20" font-size="11">one vulnerability, two machines, and the responses each one allows</text>
<text x="14" y="42" font-size="9" fill-opacity="0.85">the controller loses the three responses that fix the flaw, and keeps the four that work around it</text>
<text x="380" y="66" font-size="8.5" text-anchor="middle" fill-opacity="0.8">office server</text>
<text x="560" y="66" font-size="8.5" text-anchor="middle" fill-opacity="0.8">controller</text>
<text x="14" y="92" font-size="9.5">install the patch</text>
<rect x="300" y="76" width="160" height="24" rx="2" fill="var(--accent)" fill-opacity="0.3"/>
<text x="380" y="92" font-size="8.5" text-anchor="middle">available</text>
<rect x="480" y="76" width="160" height="24" rx="2" fill="var(--red)" fill-opacity="0.14" stroke="var(--red)" stroke-opacity="0.5" stroke-width="1"/>
<text x="560" y="92" font-size="8.5" text-anchor="middle" fill="var(--red)">unavailable</text>
<text x="14" y="120" font-size="9.5">restart the machine to apply it</text>
<rect x="300" y="104" width="160" height="24" rx="2" fill="var(--accent)" fill-opacity="0.3"/>
<text x="380" y="120" font-size="8.5" text-anchor="middle">available</text>
<rect x="480" y="104" width="160" height="24" rx="2" fill="var(--red)" fill-opacity="0.14" stroke="var(--red)" stroke-opacity="0.5" stroke-width="1"/>
<text x="560" y="120" font-size="8.5" text-anchor="middle" fill="var(--red)">unavailable</text>
<text x="14" y="148" font-size="9.5">replace the machine</text>
<rect x="300" y="132" width="160" height="24" rx="2" fill="var(--accent)" fill-opacity="0.3"/>
<text x="380" y="148" font-size="8.5" text-anchor="middle">available</text>
<rect x="480" y="132" width="160" height="24" rx="2" fill="var(--red)" fill-opacity="0.14" stroke="var(--red)" stroke-opacity="0.5" stroke-width="1"/>
<text x="560" y="148" font-size="8.5" text-anchor="middle" fill="var(--red)">unavailable</text>
<text x="14" y="176" font-size="9.5">restrict who can reach it</text>
<rect x="300" y="160" width="160" height="24" rx="2" fill="var(--accent)" fill-opacity="0.3"/>
<text x="380" y="176" font-size="8.5" text-anchor="middle">available</text>
<rect x="480" y="160" width="160" height="24" rx="2" fill="var(--accent)" fill-opacity="0.3"/>
<text x="560" y="176" font-size="8.5" text-anchor="middle">available</text>
<text x="14" y="204" font-size="9.5">monitor what reaches it</text>
<rect x="300" y="188" width="160" height="24" rx="2" fill="var(--accent)" fill-opacity="0.3"/>
<text x="380" y="204" font-size="8.5" text-anchor="middle">available</text>
<rect x="480" y="188" width="160" height="24" rx="2" fill="var(--accent)" fill-opacity="0.3"/>
<text x="560" y="204" font-size="8.5" text-anchor="middle">available</text>
<text x="14" y="232" font-size="9.5">control what is carried to it</text>
<rect x="300" y="216" width="160" height="24" rx="2" fill="var(--accent)" fill-opacity="0.3"/>
<text x="380" y="232" font-size="8.5" text-anchor="middle">available</text>
<rect x="480" y="216" width="160" height="24" rx="2" fill="var(--accent)" fill-opacity="0.3"/>
<text x="560" y="232" font-size="8.5" text-anchor="middle">available</text>
<text x="14" y="260" font-size="9.5">accept, with a named owner</text>
<rect x="300" y="244" width="160" height="24" rx="2" fill="var(--accent)" fill-opacity="0.3"/>
<text x="380" y="260" font-size="8.5" text-anchor="middle">available</text>
<rect x="480" y="244" width="160" height="24" rx="2" fill="var(--accent)" fill-opacity="0.3"/>
<text x="560" y="260" font-size="8.5" text-anchor="middle">available</text>
<text x="14" y="282" font-size="10">what is left is reducing who can reach it, watching it, and deciding who owns the risk</text>
<text x="14" y="300" font-size="9" fill-opacity="0.75">which is why the controller's risk depends on its network far more than on its software</text>
</g></svg>
<figcaption>Seven responses to one vulnerability. On the office server all seven are available and patching is the obvious first choice. On the controller the top three are gone: there is no patch, the process cannot be stopped to restart the device, and replacing it means replacing part of the production line, which takes a capital project and years. Everything that remains works on the controller's surroundings rather than on the controller. That is the general pattern for systems that cannot be patched: their security lives in the network around them, in the monitoring of what reaches them, and in an explicit decision by a named owner that the remaining risk is accepted.</figcaption>
</figure>

<details class="predict">
<summary>A published vulnerability affects the controller in the cold open, and no fix will ever exist. Predict what the response plan contains.</summary>

**Four things, all about the controller's surroundings, and one long-term item.**

Reduce who can reach it. The controller should accept connections only from the
engineering workstations and supervisory systems that need it, through a boundary
that enforces that list. Most published vulnerabilities in devices like this need
network access to the device, so narrowing that access is the strongest control
available.

Watch what does reach it. Traffic to a controller is regular and predictable, which
makes anomalies easy to see. A new source, a programming command outside a planned
change, or traffic at an unusual hour is worth an alert.

Control what is carried to it. The laptop in the photograph is the other path in,
so the engineering machines that connect to controllers need to be dedicated,
maintained and checked, rather than whatever laptop is to hand.

Record the decision. A named owner accepts the remaining risk in writing, with the
controls above listed as the reason it is acceptable, and a date to review it.

The long-term item is replacement planning. Not as an exception that renews
indefinitely, but as a line in the capital plan with a target year, because the
condition is permanent and the only thing that ends it is new equipment.

</details>

<details class="deeper">
<summary>Compensating controls as the only available answer, and how to tell a real one from a label</summary>

When the intended control, a patch, is unavailable, everything else is a
compensating control. The term is used loosely enough that it is worth having a
test.

**A real compensating control addresses the same risk by a different route.** If
the vulnerability requires network access to the device, restricting network access
to a short list of known systems compensates, because it removes most of the paths
the vulnerability needs. If the vulnerability requires a user to open a file on the
device, network restriction does not compensate at all, however strict it is.

**So the first step is reading what the vulnerability actually requires.** Network
reachability, an authenticated session, physical access, or a file delivered by a
person. Each requirement points at a different compensating control, and a control
that does not touch the requirement is decoration.

**A real compensating control is verified, not declared.** The restriction exists
on the boundary device, it is tested by trying to reach the controller from
somewhere that should not be able to, and the test is repeated after any network
change. A compensating control that was configured once and never checked tends to
erode, the same drift topic 25 described.

**And it has an owner and a review date.** Compensating controls are justified by
the absence of a fix. If a fix becomes available, or the device is replaced, the
compensation should be revisited rather than left in place forever.

</details>

## Real time, and what it does to encryption

The usual answer to an insecure protocol is to encrypt it. On a real-time system
that answer has a cost that can rule it out.

**Encryption adds work and it can add delay.** On a general-purpose server the
delay is too small to notice. On a controller with a slow processor and a strict
deadline, the time spent encrypting and decrypting each message, and the
variation in that time, can push a response past its deadline. For a system whose
correctness depends on timing, a late answer is a wrong answer.

**Many industrial protocols were designed without authentication.** They assumed
a closed network where anything that could send a command was entitled to. That
assumption is why network separation is the main protection for these systems:
the protocol itself does not check who is speaking.

<details class="deeper">
<summary>What a real-time constraint does to the choice of encryption, and the options that remain</summary>

When encrypting at the device is not possible, there are still choices, and they
trade different things.

**Authenticate rather than encrypt.** For most control traffic, confidentiality is
not the main concern; the value of a temperature reading is rarely secret. What
matters is that commands come from a legitimate source and are not altered. A
message authentication code is usually cheaper than full encryption and protects
integrity, which is the property that matters here.

**Protect the link rather than the device.** Where traffic crosses an untrusted
network, between sites for example, encryption can be done by network equipment at
each end of that link, leaving the controllers and their deadlines untouched. The
traffic is protected in transit and in clear inside each site, which is acceptable
if each site's network is itself controlled.

**Choose newer equipment that does both.** Recent controllers and protocol versions
increasingly support authentication and encryption with hardware assistance. That
does not help the controller in the cold open, and it belongs in the replacement
plan as a requirement.

**And accept that some links will stay unprotected.** Where none of the above is
possible, the remaining protection is the boundary around the network and the
monitoring of what crosses it. Writing that down plainly, rather than implying the
traffic is protected, is part of an honest risk record.

</details>

## Try it

**Find one embedded system on your network.** A printer, a badge controller, a
building management panel. Find out what operating system it runs, when it was
last updated, and who is responsible for updating it.

**Read what a vulnerability requires.** Take any published vulnerability in an
industrial or embedded product and identify what an attacker needs: network
access, an account, physical presence, or a file opened by a person. Then name the
compensating control that addresses that requirement.

**Find the oldest device that cannot be replaced.** In any environment you know,
identify the equipment with the longest remaining service life and the least update
support. That is where the replacement planning should start.

**Ask how controllers are programmed.** Find out which machines are used to connect
to the controllers in an operational environment, who maintains them, and whether
they are used for anything else.

## Check yourself

<details class="qa">
<summary>Why does availability outrank confidentiality on an industrial control system?</summary>

Because the system controls a physical process, and stopping it costs money every
minute and, for safety functions, can create danger. The priority is that the
process keeps running correctly, then that its data is accurate, and only then that
it is secret.

That order explains why patches wait for planned shutdowns, why endpoint software
that might pause a process is rejected, and why discovery on a control network is
passive by default.

</details>

<details class="qa">
<summary>Why is discovery on a control network passive by default?</summary>

Because active scanning can disrupt the devices being scanned. Older controllers
and embedded devices may have minimal network stacks that stop responding or
restart when probed with unexpected traffic, and on a control network that is an
outage caused by the security team.

Passive discovery builds an inventory by listening to traffic already on the
network. Where active scanning is used, it is planned with operations, run in a
maintenance window, and tested first.

</details>

<details class="qa">
<summary>A controller has a vulnerability and no patch will ever exist. What responses remain?</summary>

Restricting which systems can reach it, monitoring what does reach it, controlling
the engineering machines that connect to it, and a written risk acceptance by a
named owner with a review date. Patching, restarting at will and quick replacement
are all unavailable.

Replacement belongs in the capital plan with a target year, because the condition
is permanent and only new equipment ends it.

</details>

<details class="qa">
<summary>What makes a compensating control real rather than a label?</summary>

It addresses the same requirement the vulnerability depends on. If the
vulnerability needs network access to the device, restricting that access
compensates. If it needs a person to open a file, network restriction does not,
however strict.

A real compensating control is also verified by testing it, re-tested after
changes, and owned, with a review date in case a fix or a replacement arrives.

</details>

<details class="qa">
<summary>Why might a real-time system not be able to use encryption, and what are the alternatives?</summary>

Encryption adds processing time and variation in that time, and on a slow
controller with a strict deadline that can make responses late. On a real-time
system a late answer is a wrong answer.

The alternatives are authenticating messages rather than encrypting them, which
protects integrity more cheaply; encrypting the link between sites with network
equipment at each end; and requiring authentication and encryption support when
the equipment is replaced.

</details>

## References

- [SP 800-82 Rev. 3](https://csrc.nist.gov/pubs/sp/800/82/r3/final) - NIST, operational technology security, for the inverted priorities, passive discovery and compensating controls. Free. Accessed 2026-10-07.
- [NIST IR 8259](https://csrc.nist.gov/pubs/ir/8259/final) - NIST, cybersecurity activities for IoT device manufacturers, including update support as a device property. Free. Accessed 2026-10-07.
- [SP 800-213](https://csrc.nist.gov/pubs/sp/800/213/final) - NIST, IoT device cybersecurity guidance for organisations buying devices. Free. Accessed 2026-10-07.

**Photograph credit.** Downloaded and committed to this repository rather than
hotlinked.

- Programmable logic controller in a field cabinet by sirdle, [CC BY-SA 2.0](https://creativecommons.org/licenses/by-sa/2.0), from [Wikimedia Commons](https://commons.wikimedia.org/wiki/File:PLC_Control_Panel.jpg).

**Where the content came from.** Nothing on this page is captured. The systems it
describes are the ones where running tools against real equipment carries
operational risk, which is the topic's own argument, and a simulated controller
would show the software without the constraint that makes these systems hard.
There is no platform comparison either: these devices are administered through
vendor tools and engineering software rather than the operating system commands
this track compares.
