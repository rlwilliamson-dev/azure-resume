---
title: "Mobile devices and who owns them"
description: "Three deployment models, what each one lets an organisation enforce, see and remove, why the wipe question has to be answered before enrolment rather than during an incident, and what cellular, Wi-Fi and Bluetooth each expose."
deck: "The phone has the company mail on it, and one wipe removes the owner's photographs too"
track: "security-plus"
level: "working"
order: 420
objectives:
  - "Name the three deployment models and say who owns the device in each"
  - "Say what an organisation can enforce, see and remove under each model"
  - "Explain why the wipe question is decided at enrolment rather than at incident time"
  - "Describe what cellular, Wi-Fi and Bluetooth each expose, and to whom"
  - "Say where mobile device management stops, and why the operating system version is the floor"
  - "Read the enrolment state of a Windows and a macOS machine and say what it means"
prerequisites: ["secure-baselines"]
tags: ["security-plus", "security", "operations", "mobile"]
updated: 2026-08-25
draft: false
examObjectives:
  - exam: "sy0-701"
    domain: "4.0"
    objective: "4.1"
sources:
  - title: "SP 800-124 Rev. 2, Guidelines for Managing the Security of Mobile Devices in the Enterprise"
    url: "https://csrc.nist.gov/pubs/sp/800/124/r2/final"
    publisher: "NIST"
    accessed: 2026-08-25
    tier: 1
  - title: "SP 800-121 Rev. 2, Guide to Bluetooth Security"
    url: "https://csrc.nist.gov/pubs/sp/800/121/r2/upd1/final"
    publisher: "NIST"
    accessed: 2026-08-25
    tier: 1
  - title: "Mobile device management configuration service provider reference"
    url: "https://learn.microsoft.com/en-us/windows/client-management/mdm/"
    publisher: "Microsoft"
    accessed: 2026-08-25
    tier: 1
  - title: "dsregcmd command reference"
    url: "https://learn.microsoft.com/en-us/entra/identity/devices/troubleshoot-device-dsregcmd"
    publisher: "Microsoft"
    accessed: 2026-08-25
    tier: 1
  - title: "Intro to mobile device management profiles"
    url: "https://support.apple.com/guide/deployment/intro-to-mdm-profiles-depc0aadd3fe/web"
    publisher: "Apple"
    accessed: 2026-08-25
    tier: 1
symptoms:
  - symptom: "A remote wipe removed somebody's personal photographs"
    anchor: "the-wipe-question-is-answered-at-enrolment"
  - symptom: "A policy will not apply to a device that is enrolled"
    anchor: "where-enforcement-stops"
---

> **Before you read.** A salesperson leaves. Their phone has the company mail
> account on it, a copy of the customer list in a spreadsheet, and eleven years of
> photographs of their children.
>
> The phone belongs to them. The mail account does not.
>
> **What can you remove, and when was that decided?**

The answer is not a technical one and it is not decided during the incident. It
was decided at enrolment, months earlier, by somebody choosing a deployment model,
and the three models differ in exactly this.

### Some words you will need

<dl class="terms">
<dt>mobile device management</dt>
<dd>A server that sends configuration to enrolled devices and reads state back from them. Abbreviated MDM.</dd>
<dt>enrolment</dt>
<dd>The act of a device accepting management. It is consensual, it is revocable by the owner on a personal device, and everything else follows from it.</dd>
<dt>BYOD</dt>
<dd>Bring your own device. The employee owns the hardware and chose it.</dd>
<dt>CYOD</dt>
<dd>Choose your own device. The organisation owns the hardware and the employee picked it from a list.</dd>
<dt>COPE</dt>
<dd>Corporate-owned, personally enabled. The organisation owns and chose the hardware, and permits personal use of it.</dd>
<dt>containerisation</dt>
<dd>Keeping managed data in a separate area of the device, so it can be removed without touching anything else.</dd>
<dt>full wipe</dt>
<dd>Returning the whole device to factory state. Removes everything, including what the organisation never owned.</dd>
<dt>selective wipe</dt>
<dd>Removing only the managed accounts, apps and data. Leaves the rest of the device alone.</dd>
</dl>

## What breaks without this

**Somebody's personal data is destroyed by a routine action.** The leaver process
says wipe the device, the console offers one button, and nobody has written down
which button.

**Or the opposite, and the data walks.** The organisation cannot remove anything,
because the phone was never enrolled in a way that made removal possible, and the
customer list is still on it.

**A policy is bought and cannot be applied.** The management server offers a
setting, the fleet does not support it, and the reason is an operating system
version rather than a licence.

**The legal position is discovered late.** An employee objects to what the
organisation can see on a device they own, and the answer to whether they are
right was fixed by an agreement nobody kept a copy of.

## Three models, and one question separates them

The three deployment models are usually taught as three acronyms with a sentence
each, which makes them look like variations on a theme. They are not. They differ
on who owns the hardware, and every other difference follows from that one.

**BYOD.** The employee bought the phone. The organisation is a guest on it, and it
is a guest that can be asked to leave, because the owner can remove the management
profile whenever they like. Everything the organisation wants to enforce has to be
worth the friction of asking somebody to accept it on their own property.

**CYOD.** The organisation bought the phone and let the employee choose which one.
That is a retention decision rather than a security one, and it matters here only
because the fleet is now heterogeneous, so enforcement has to work across whatever
people chose.

**COPE.** The organisation bought the phone, chose the model, and permits personal
use. It is the model with the most enforcement available, and it is also the one
where the personal data problem is sharpest, because the organisation invited the
personal use.

<details class="predict">
<summary>Which of the three has the hardest personal-data problem when somebody leaves?</summary>

**COPE, and it is not close.** The intuitive answer is BYOD, because that is the
one where the device is personal property, and the intuition has it backwards.

On a BYOD phone the personal data problem is real and it is bounded, because the
organisation never had the ability to remove everything. The enrolment was
partial by necessity: nobody accepts full management on a phone they paid for, so
what got enrolled was a work profile or a set of managed apps, and what a wipe
removes is that. The boundary was drawn at enrolment because it had to be.

On a COPE phone the organisation owns the hardware outright and can factory reset
it. It also told the employee to use it personally, so there are eleven years of
photographs on a device the organisation can erase with one command and has the
legal standing to erase. The technical boundary that made BYOD safe is absent, and
the only thing standing between somebody's photographs and a routine leaver
process is a decision about which button to press.

CYOD sits in between and is closest to COPE, because the ownership is the same.

The general shape is worth carrying: the model with the most control is the model
where restraint has to be written down, because nothing about the technology will
impose it for you.

</details>

<figure class="learn-figure">
<svg viewBox="0 0 720 306" role="img" aria-labelledby="own-title" style="width:100%;height:auto;">
<title id="own-title">Three deployment models compared on who owns the hardware, what a wipe can remove, what the organisation can see, and who can end the arrangement</title>
<g fill="currentColor">
<text x="14" y="20" font-size="11">who owns it decides everything else on this page</text>
<text x="229" y="48" text-anchor="middle" font-size="9.5">BYOD</text>
<text x="423" y="48" text-anchor="middle" font-size="9.5">CYOD</text>
<text x="617" y="48" text-anchor="middle" font-size="9.5">COPE</text>
<text x="14" y="76" font-size="9" fill-opacity="0.85">hardware owned by</text>
<rect x="140" y="60" width="178" height="24" rx="3" fill="var(--red)" fill-opacity="0.12" stroke="var(--red)" stroke-opacity="0.7" stroke-width="1.2"/>
<text x="229" y="76" text-anchor="middle" font-size="8.5">the employee</text>
<rect x="334" y="60" width="178" height="24" rx="3" fill="var(--accent)" fill-opacity="0.12" stroke="var(--accent)" stroke-opacity="0.7" stroke-width="1.2"/>
<text x="423" y="76" text-anchor="middle" font-size="8.5">the organisation</text>
<rect x="528" y="60" width="178" height="24" rx="3" fill="var(--accent)" fill-opacity="0.12" stroke="var(--accent)" stroke-opacity="0.7" stroke-width="1.2"/>
<text x="617" y="76" text-anchor="middle" font-size="8.5">the organisation</text>
<text x="14" y="112" font-size="9" fill-opacity="0.85">model chosen by</text>
<rect x="140" y="96" width="178" height="24" rx="3" fill="currentColor" fill-opacity="0.05" stroke="currentColor" stroke-opacity="0.55" stroke-width="1.1"/>
<text x="229" y="112" text-anchor="middle" font-size="8.5">the employee</text>
<rect x="334" y="96" width="178" height="24" rx="3" fill="currentColor" fill-opacity="0.05" stroke="currentColor" stroke-opacity="0.55" stroke-width="1.1"/>
<text x="423" y="112" text-anchor="middle" font-size="8.5">the employee, from a list</text>
<rect x="528" y="96" width="178" height="24" rx="3" fill="currentColor" fill-opacity="0.05" stroke="currentColor" stroke-opacity="0.55" stroke-width="1.1"/>
<text x="617" y="112" text-anchor="middle" font-size="8.5">the organisation</text>
<text x="14" y="148" font-size="9" fill-opacity="0.85">a wipe can remove</text>
<rect x="140" y="132" width="178" height="24" rx="3" fill="currentColor" fill-opacity="0.05" stroke="currentColor" stroke-opacity="0.55" stroke-width="1.1"/>
<text x="229" y="148" text-anchor="middle" font-size="8.5">the managed part only</text>
<rect x="334" y="132" width="178" height="24" rx="3" fill="currentColor" fill-opacity="0.05" stroke="currentColor" stroke-opacity="0.55" stroke-width="1.1"/>
<text x="423" y="148" text-anchor="middle" font-size="8.5">everything on it</text>
<rect x="528" y="132" width="178" height="24" rx="3" fill="currentColor" fill-opacity="0.05" stroke="currentColor" stroke-opacity="0.55" stroke-width="1.1"/>
<text x="617" y="148" text-anchor="middle" font-size="8.5">everything on it</text>
<text x="14" y="184" font-size="9" fill-opacity="0.85">personal data present</text>
<rect x="140" y="168" width="178" height="24" rx="3" fill="currentColor" fill-opacity="0.05" stroke="currentColor" stroke-opacity="0.55" stroke-width="1.1"/>
<text x="229" y="184" text-anchor="middle" font-size="8.5">all of it</text>
<rect x="334" y="168" width="178" height="24" rx="3" fill="currentColor" fill-opacity="0.05" stroke="currentColor" stroke-opacity="0.55" stroke-width="1.1"/>
<text x="423" y="184" text-anchor="middle" font-size="8.5">whatever policy allows</text>
<rect x="528" y="168" width="178" height="24" rx="3" fill="var(--red)" fill-opacity="0.14" stroke="var(--red)" stroke-opacity="0.75" stroke-width="1.4"/>
<text x="617" y="184" text-anchor="middle" font-size="8.5">invited, and erasable</text>
<text x="14" y="220" font-size="9" fill-opacity="0.85">can end it unilaterally</text>
<rect x="140" y="204" width="178" height="24" rx="3" fill="currentColor" fill-opacity="0.05" stroke="currentColor" stroke-opacity="0.55" stroke-width="1.1"/>
<text x="229" y="220" text-anchor="middle" font-size="8.5">the employee, any time</text>
<rect x="334" y="204" width="178" height="24" rx="3" fill="currentColor" fill-opacity="0.05" stroke="currentColor" stroke-opacity="0.55" stroke-width="1.1"/>
<text x="423" y="220" text-anchor="middle" font-size="8.5">the organisation</text>
<rect x="528" y="204" width="178" height="24" rx="3" fill="currentColor" fill-opacity="0.05" stroke="currentColor" stroke-opacity="0.55" stroke-width="1.1"/>
<text x="617" y="220" text-anchor="middle" font-size="8.5">the organisation</text>
<text x="14" y="258" font-size="10" fill-opacity="0.85">the row that surprises people is the fourth one, not the first</text>
<text x="14" y="280" font-size="10" fill-opacity="0.85">BYOD limits what you can destroy. COPE removes that limit and invites the data in</text>
</g></svg>
<figcaption>Read the columns downward rather than the rows across. Under BYOD the employee owns the hardware, so the organisation's reach was negotiated at enrolment and a wipe cannot exceed it; that constraint is also the protection. Under COPE the organisation owns everything, can erase everything, and has explicitly told the employee to keep personal things on it. The accented cell is where the two facts collide, and nothing in the technology resolves it. CYOD differs from COPE only in who picked the model, which is a retention decision that happens to leave you with a fleet of different devices to enforce across.</figcaption>
</figure>

<details class="deeper">
<summary>If you are writing the policy: why BYOD is a legal question before it is a technical one</summary>

The technical part of BYOD is straightforward and largely solved. The hard part is
that the organisation is asking to place software with elevated privileges on
property it does not own, belonging to somebody whose continued employment
depends on the answer.

That asymmetry is why the agreement matters more than the configuration. It has
to say what the organisation can see, what it can remove, what happens if the
employee refuses an update, and what happens on the last day. In several
jurisdictions it also has to say what happens to personal data that the
organisation processes incidentally, because location, installed applications and
network names are personal data when the device is a person's own.

The failure mode is not a dramatic one. It is that the agreement is a paragraph
in a handbook nobody read, the console offers a full wipe as the default action,
and somebody in a hurry uses it. The organisation then has a destruction of
personal property carried out by an employee who was following the process.

Two practical things follow. Make the destructive option harder to reach than the
correct one, because the correct one under BYOD is almost always selective. And
write the exit case down in the enrolment agreement in words the employee reads
at the time, because consent obtained at enrolment is the only consent you will
have when it matters.

There is a version of this that is worth saying plainly: an organisation that
cannot tolerate a partial wipe should not run BYOD. It should buy phones. The
model is a cost decision presented as a flexibility decision, and the cost it
moves is not only money.

</details>

## The wipe question is answered at enrolment

The console shows two options and they are not two ways of doing the same thing.

A **full wipe** returns the device to factory state. It is available whenever the
organisation controls enrolment deeply enough, which is to say on hardware it
owns.

A **selective wipe** removes the managed accounts, the managed applications and
the data inside them, and leaves the rest of the device untouched. It is available
only if the managed things were kept separable in the first place.

**That separation is created at enrolment and cannot be created afterwards.** If
mail was configured into the device's own mail application rather than a managed
one, there is no boundary to remove along. The organisation's only options at that
point are everything or nothing, and the choice between them is being made under
time pressure by somebody who did not design the enrolment.

<details class="deeper">
<summary>If you have deployed a work profile: what containerisation actually separates, and what leaks anyway</summary>

Containerisation on a phone is real separation with real limits, and knowing the
limits is what stops it being oversold.

What it does separate is storage and process identity. Managed applications run
under a different user or profile, write into storage the personal side cannot
read, and can be removed as a unit. Copy and paste between the two sides can be
blocked. Screenshots inside the container can be blocked. Backups of the
container can be excluded from the personal cloud backup.

What crosses the boundary anyway is more interesting. The keyboard is usually
shared, and a third-party keyboard sees everything typed on both sides. Photos
taken with the camera land in the personal library unless the managed app has its
own camera path. Notifications render on a lock screen owned by the personal side.
And the operating system itself is common to both, so a compromise below the
profile boundary has both.

The honest summary is that a container defends against the ordinary case, which
is data walking out through the user's own convenience, and does not defend
against a compromised device. That is enough to be worth deploying and it is not
the same claim as isolation.

The reason to be precise about this is that the container is usually sold as the
answer to the BYOD legal problem, and it mostly is. It just does not also solve
the compromise problem, and the two get conflated in procurement.

</details>

## What management can actually address

"The organisation can enforce policy on the device" is a sentence that hides the
interesting question, which is how many separate things that means. On Windows the
answer is enumerable, because the management surface is a namespace.

<details class="predict">
<summary>A stock Windows Server, enrolled in nothing. How many separately addressable management areas do you think its MDM namespace exposes?</summary>

```powershell
# Microsoft Windows Server 2025 Datacenter, version 10.0.26100.0
> dsregcmd /status | Select-String -Pattern 'AzureAdJoined|EnterpriseJoined|DomainJoined|MDMUrl' | ForEach-Object { $_.Line.Trim() }
AzureAdJoined : NO
EnterpriseJoined : NO
DomainJoined : NO

# How many separate areas a management server can address through the MDM namespace
> (Get-CimClass -Namespace root\cimv2\mdm\dmmap -ErrorAction SilentlyContinue | Measure-Object).Count
465

# A sample of them, which is what "the organisation can enforce this" means in practice
> Get-CimClass -Namespace root\cimv2\mdm\dmmap -ErrorAction SilentlyContinue | Select-Object -ExpandProperty CimClassName | Where-Object { $_ -match 'Policy|Wipe|Password|Encryption|Firewall|Application' } | Sort-Object | Select-Object -First 10
MDM_ApplicationControl
MDM_ApplicationControl_Policies01_01
MDM_ApplicationControl_PolicyIDs03
MDM_ApplicationControl_PolicyInfo03
MDM_ApplicationControl_Token03
MDM_ApplicationControl_TokenInfo03
MDM_ApplicationControl_Tokens01_01
MDM_AppLocker_ApplicationLaunchRestrictions01_EXE03
MDM_AppLocker_ApplicationLaunchRestrictions01_StoreApps03
MDM_DeviceStatus_Firewall01
```

**Four hundred and sixty-five, on a machine enrolled in nothing.** The surface
exists whether or not anybody is using it, which is the first thing worth
noticing: enrolment does not install the ability to manage the device, it
authorises somebody to use an ability that shipped with it.

The class names are the second thing. Application launch restrictions, firewall
status, encryption, password policy. Each of those is a thing a management server
can set or read, individually, and "we manage the fleet" usually means somebody
selected perhaps thirty of these and left the rest at default.

That is not a criticism. It is the reason two organisations both saying they have
MDM can mean wildly different things, and the reason the useful question in an
audit is which policies are set rather than whether a product is deployed.

</details>

And one of the four hundred and sixty-five is worth naming on its own.

```powershell
# Microsoft Windows Server 2025 Datacenter, version 10.0.26100.0
> Get-CimClass -Namespace root\cimv2\mdm\dmmap -ErrorAction SilentlyContinue | Select-Object -ExpandProperty CimClassName | Where-Object { $_ -match 'Wipe' }
MDM_RemoteWipe
```

A single class, present on an unmanaged machine, waiting for somebody with the
authority to call it. The capability is in the operating system. What enrolment
adds is a party permitted to use it, and what the deployment model decides is
whether that party is allowed to point it at hardware somebody else paid for.

## Where enforcement stops

Three connection methods appear in this objective and they are worth separating by
what each one exposes rather than by how each one works.

**Cellular** is the one the organisation does not control at all. The carrier
handles it, the traffic leaves the device without touching your network, and a
device on cellular is reachable and reaching without any of your inspection in the
path. That is a feature for the user and it is the reason a device-level control
matters more than a network-level one on mobile.

**Wi-Fi** is where the organisation can put controls in the path, on its own
networks, and cannot on anybody else's. A phone on a home network or a café
network has your data on it and none of your inspection around it. This is the
argument for the control living on the device rather than at the boundary, and it
is the same argument zero trust makes in general.

**Bluetooth** is the short-range one and the one with the most surprising history.
It is a pairing relationship rather than a network, its range is longer than
people expect, and the risks are dominated by what pairing grants: a paired
device may read contacts, may act as an input device, and may do so from further
away than the phrase "short range" suggests.

Under all three, the thing that actually enforces is on the device. Which brings
the objective's real limit into view.

**Enforcement stops at what the operating system version supports.** A management
server can offer a setting the fleet cannot apply, and the resulting report says
the policy is assigned and not applied, which reads like a fault and is a version
mismatch.

<details class="deeper">
<summary>If you have chased a policy that would not apply: what the version floor actually is, and why it gets worse over time</summary>

Every management setting is implemented by code on the device. If the version
running does not contain that code, the server can send the instruction, the
device can acknowledge receipt, and nothing happens. The console shows the policy
as assigned, and separately shows it as not applied, and those two lines together
are the whole diagnosis.

What makes this an ongoing problem rather than a one-time cleanup is who controls
the version. On a phone the answer is rarely you. The manufacturer decides how
long a model receives updates, the carrier sometimes sits between the
manufacturer and the device, and the user decides whether to press install. An
organisation can require a minimum version and block access below it, which is
the correct control and is also a decision to stop some employees working until
they update.

The consequence for the three models is direct and it is the strongest security
argument any of them has. Under COPE and CYOD the organisation owns the hardware
and can refresh it, so the version floor is a budget line. Under BYOD the fleet
ages at whatever rate people replace their own phones, which is slower, and the
oldest devices belong to the people least able to replace them.

That is worth saying out loud when somebody proposes BYOD as the cheap option.
The cost does not disappear. It moves onto the employees, and it lands unevenly.

The practical measure is not a policy document. It is a report of the fleet by
operating system version, refreshed monthly, with the count below your floor on
it. Most organisations running mobile management can produce that report and very
few look at it until something fails to apply.

</details>

## Across platforms

Both platforms answer the enrolment question directly, and both answer it here
with a no, which is what makes the pair worth reading together: the shape of the
answer differs even when the answer is the same.

| Task | Linux | Windows | macOS |
| --- | --- | --- | --- |
| Is this machine managed | no single answer; depends on the agent | `dsregcmd /status` | `profiles status -type enrollment` |
| What management can address | agent-specific | `root\cimv2\mdm\dmmap`, an enumerable namespace | configuration profile payloads, not enumerable locally |
| Where a managed setting lands | agent-specific | the registry, under policy keys | `/Library/Managed Preferences/` |
| Remote wipe | not a platform feature | `MDM_RemoteWipe` | an MDM command, no local class |

```bash
# macOS 26.5.2, arm64
$ sudo /usr/bin/profiles status -type enrollment 2>&1
Enrolled via DEP: No
MDM enrollment: No

# Where a managed setting would land, and what is there now
$ ls -la /Library/Managed\ Preferences/ 2>&1 | head -4
total 0
drwxr-xr-x   2 root  wheel    64 Aug 25 20:17 .
drwxr-xr-x  67 root  wheel  2144 Jul 28 06:39 ..

# The profiles actually installed, in every domain the command will report
$ sudo /usr/bin/profiles -L 2>&1 | head -4
There are no configuration profiles installed in the system domain

# The operating system version, which is the floor every enforcement rule sits on
$ sw_vers; /usr/bin/fdesetup status 2>&1
ProductName:		macOS
ProductVersion:		26.5.2
BuildVersion:		25F84
FileVault is Off.
```

**The empty directory is the clearest thing on this page.**
`/Library/Managed Preferences/` exists on every Mac, owned by root, and it is
where settings sent by a management server are written. On this machine it
contains nothing at all, because nothing has ever sent it anything.

Compare the two enrolment answers side by side. Windows reports three separate
negatives, because there are three different things it could be joined to and
they are not the same relationship: Entra ID, an on-premises directory, and an
MDM service. macOS reports two, and the first of them is about how the device was
purchased rather than how it was configured. Enrolment via DEP means the hardware
was registered to the organisation at the point of sale, which is a stronger
claim than an enrolment somebody performed afterwards, because it survives a
factory reset.

That difference is directly the topic's subject. On the Apple side there is a
purchase-time answer to the ownership question, and it is visible in the output of
a single command. On the Windows side ownership is not a field, and the three
negatives describe relationships rather than property.

Neither platform has a command that answers "may I wipe this". That question is
answered by the agreement, and the machine has never heard of it.

## Prove it

**Run it.** On a Windows machine, `dsregcmd /status` prints the join state in a few
seconds and needs no privileges. On a Mac,
`sudo /usr/bin/profiles status -type enrollment` does the same. Run whichever you
have and read what it says about a machine you thought you knew.

**Work it out.** Take the leaver scenario from the top of the page under each of
the three models in turn. For each one, write down what the organisation removes,
what it leaves behind, and who would be entitled to complain. You should find that
the model with the most technical options has the fewest defensible ones.

**Look it up.** Open SP 800-124 Rev. 2 and find what it says about the
organisation's ability to remove data from devices it does not own. The section is
short and the constraint it describes is the whole of this topic.

## What trips people up

### 1. Treating BYOD as the risky one and COPE as the safe one

BYOD limits what the organisation can destroy, which is a real protection. COPE
removes that limit and then invites personal data onto the device. The technical
risk and the human risk point in opposite directions here.

### 2. Believing a selective wipe is always available

It is available only if the managed data was kept separable at enrolment. Mail
configured into the device's own mail application has no boundary to remove along,
and the choice at incident time is everything or nothing.

### 3. Thinking enrolment grants the ability to manage

The management surface ships with the operating system. On the Windows machine
above, 465 addressable classes exist on a device enrolled in nothing. Enrolment
authorises a party to use them.

### 4. Reading "policy not applied" as a failure

A management server can assign a setting an older operating system version does
not implement. The report says assigned and not applied, which looks like a fault
and is a version floor.

### 5. Assuming the organisation sees traffic from a managed phone

On cellular it sees nothing, because the traffic never touches its network. On
someone else's Wi-Fi, the same. Whatever the control is, on mobile it has to live
on the device.

### 6. Calling CYOD a security model

It is a procurement and retention decision. Its only security consequence is that
the fleet is heterogeneous, so enforcement has to work across whatever people
chose.

## Work it through

Two hundred staff, all on personal phones, all reading company mail through the
phone's built-in mail application because that is what the setup guide said in
2019. Somebody has now asked for the ability to remove company data when people
leave.

**The tempting move is to enrol the fleet and turn on wipe.** It is one project,
it produces a console with a button, and it appears to answer the question. What
it actually produces is two hundred personal phones where the only available
removal action destroys the owner's data, and a leaver process that now contains
a decision nobody wants to be the one to make.

**The move that works changes where the mail lives before it changes what you can
remove.** Move company mail into a managed application, so there is something
separable to remove. That is a migration with a helpdesk cost and no visible
security benefit on the day it lands, which is why it is the part that gets cut.

**Then enrolment is a smaller ask.** Asking somebody to accept management that can
remove one application's data is a different conversation from asking them to
accept management that can erase their phone, and the difference shows up in how
many people agree without escalating.

**What this rejects is speed.** The wipe button exists on day one under the first
plan and month four under the second. The cost of the first plan is not paid on
day one either; it is paid the first time somebody leaves on bad terms and the
process says press the button.

The residual is worth naming. Under the second plan, company data that was already
on those phones outside the managed application stays there. Migrating the mail
does not retrieve the spreadsheet somebody saved in 2021, and no enrolment model
retrieves it either.

## Try it

**Ask your own machine whether it is managed.** `dsregcmd /status` on Windows or
`sudo /usr/bin/profiles status -type enrollment` on a Mac. If it is managed, the
next question is by whom, and the output says.

**Count the management surface.** On Windows,
`Get-CimClass -Namespace root\cimv2\mdm\dmmap | Measure-Object` returns the number
of addressable classes. Compare it with how many settings you believe your
organisation actually sets.

**Look in the empty directory.** On a Mac, `ls /Library/Managed\ Preferences/`.
On an unmanaged machine it is empty. On a managed one, every file in it is a
setting somebody else decided, and the filenames say which application each one
governs.

**Read a phone's work profile boundary.** If you have a work profile on a personal
phone, try copying text from a managed application into a personal one. Whether
it works tells you which side of the boundary your organisation chose.

## Check yourself

<details class="qa">
<summary>Name the three deployment models and say who owns the hardware in each.</summary>

BYOD, bring your own device: the employee owns it and chose it. CYOD, choose your
own device: the organisation owns it and the employee picked it from a list.
COPE, corporate-owned personally enabled: the organisation owns it, chose it, and
permits personal use.

Ownership is the axis. Everything else, what a wipe can remove, who can end the
arrangement, and what personal data is present, follows from it.

</details>

<details class="qa">
<summary>An employee leaves. Their BYOD phone has company mail configured in the phone's own mail application. What can you remove?</summary>

Either everything or nothing, and the reason is a decision taken at enrolment
rather than a limitation of the tooling.

A selective wipe removes managed accounts, managed applications and the data
inside them. If the mail was configured into the device's own application, there
is no boundary along which to remove it, so the only technical action that removes
company data also removes the owner's.

The right answer is usually nothing, followed by fixing the enrolment for
everybody else.

</details>

<details class="qa">
<summary>A management console offers 465 addressable policy areas on Windows. What does that number tell you about a fleet described as "managed"?</summary>

That the description is not informative on its own. The surface exists on every
machine, enrolled or not, so enrolment authorises a party to use it rather than
creating it.

An organisation running MDM has typically selected a few dozen of those areas and
left the rest at default. Two organisations both saying they manage their fleet
can therefore mean very different things, which is why the useful audit question
is which policies are set rather than whether a product is deployed.

</details>

<details class="qa">
<summary>Why does a control on a mobile device have to live on the device rather than at the network boundary?</summary>

Because most of the time the device is not behind your boundary. On cellular the
traffic goes through the carrier and never touches your network. On someone
else's Wi-Fi, the same.

A control at the edge protects the device while it is at the office, which for a
phone is a minority of its life. That is the same argument zero trust makes about
location, met here in a form where the device physically leaves.

</details>

<details class="qa">
<summary>A policy shows as assigned and not applied on part of the fleet. What is the first thing to check?</summary>

The operating system version on the devices that did not apply it.

Management servers offer settings that older versions do not implement, and the
resulting state is exactly this: assigned, acknowledged, not applied. It reads
like a fault in enrolment and it is a version floor, which is why fleet
heterogeneity under CYOD has a real operational cost.

</details>

## References

- [SP 800-124 Rev. 2](https://csrc.nist.gov/pubs/sp/800/124/r2/final) - NIST, Guidelines for Managing the Security of Mobile Devices in the Enterprise, for deployment models and what an organisation may do to a device it does not own. Free. Accessed 2026-08-25.
- [SP 800-121 Rev. 2](https://csrc.nist.gov/pubs/sp/800/121/r2/upd1/final) - NIST, Guide to Bluetooth Security, for pairing, range and what a paired device is granted. Free. Accessed 2026-08-25.
- [MDM configuration service provider reference](https://learn.microsoft.com/en-us/windows/client-management/mdm/) - Microsoft, the documented list of what a management server can address on Windows. Free. Accessed 2026-08-25.
- [dsregcmd](https://learn.microsoft.com/en-us/entra/identity/devices/troubleshoot-device-dsregcmd) - Microsoft, for reading the three join states the capture on this page prints. Free. Accessed 2026-08-25.
- [Intro to MDM profiles](https://support.apple.com/guide/deployment/intro-to-mdm-profiles-depc0aadd3fe/web) - Apple, for enrolment, configuration profiles and where managed settings land. Free. Accessed 2026-08-25.

**Where the content came from.** Both captures are from disposable runners, one
Windows and one macOS, neither enrolled in anything. That is deliberate: the
interesting evidence on this topic is what an unmanaged machine says about the
management it does not have, including the 465 addressable classes that exist
regardless and the empty directory where managed settings would land. Nothing on
this page describes a phone that was wiped, because that is not something to
demonstrate on a machine belonging to somebody else.

**If you also work on networks.** The Network+ track's
[wireless security and authentication](/learn/network-plus/wireless-security-and-authentication)
covers the Wi-Fi half from the network's side, and
[cloud concepts and connectivity](/learn/network-plus/cloud-concepts-and-connectivity)
covers what happens to traffic that never comes back to your boundary.
