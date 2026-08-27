---
title: "Segmentation, isolation and access control"
description: "A vending machine with a route to the payment host and no way to use it, the difference between a jump host and a router with a login prompt, and why an allow list is harder to run and worth more than a block list."
deck: "The payment system and the vending machine are on the same network, and one of them is easier to reach"
track: "security-plus"
level: "working"
order: 250
objectives:
  - "Explain what a network segment stops and what it does not"
  - "Say why reachability is a policy decision rather than a property of the wiring"
  - "Distinguish segmentation from isolation"
  - "Explain what a jump host has to do to be a control rather than a bridge"
  - "Say why an allow list is harder to operate and better than a block list"
  - "State least privilege as a design position rather than a setting"
prerequisites: ["the-nine-indicators"]
tags: ["security-plus", "security", "mitigation", "network"]
updated: 2026-08-26
draft: false
examObjectives:
  - exam: "sy0-701"
    domain: "2.0"
    objective: "2.5"
sources:
  - title: "SP 800-41 Rev. 1, Guidelines on Firewalls and Firewall Policy"
    url: "https://csrc.nist.gov/pubs/sp/800/41/r1/final"
    publisher: "NIST"
    accessed: 2026-08-26
    tier: 1
  - title: "SP 800-207, Zero Trust Architecture"
    url: "https://csrc.nist.gov/pubs/sp/800/207/final"
    publisher: "NIST"
    accessed: 2026-08-26
    tier: 1
  - title: "M1030, Network Segmentation"
    url: "https://attack.mitre.org/mitigations/M1030/"
    publisher: "MITRE"
    accessed: 2026-08-26
    tier: 1
  - title: "M1038, Execution Prevention"
    url: "https://attack.mitre.org/mitigations/M1038/"
    publisher: "MITRE"
    accessed: 2026-08-26
    tier: 1
symptoms:
  - symptom: "A device is on the same network as something it has no business reaching"
    anchor: "what-a-segment-actually-stops"
  - symptom: "A management host has an interface on two networks"
    anchor: "the-jump-host-and-how-a-control-becomes-a-bridge"
---

> **Before you read.** A vending machine, a card payment terminal and a finance
> workstation all sit behind the same firewall on the same site. The vending
> machine takes updates over the network from a supplier who has never heard of
> your change process.
>
> **What does the vending machine need to be able to reach?**

Its supplier, and nothing else. That answer takes two seconds to give and is
almost never the configuration, because networks are built for reachability and
then trimmed afterwards, if anybody remembers. This topic is about the controls
that do the trimming, what each one costs, and which of them are enforced
somewhere a compromised device cannot get at.

### Some words you will need

<dl class="terms">
<dt>segmentation</dt>
<dd>Dividing a network so that reaching one part from another requires passing a control.</dd>
<dt>isolation</dt>
<dd>Removing a system's ability to reach anything, or anything's ability to reach it.</dd>
<dt>access control list</dt>
<dd>An ordered set of permit and deny rules evaluated against a request.</dd>
<dt>implicit deny</dt>
<dd>What happens to a request no rule permits. The default that does most of the work.</dd>
<dt>allow list</dt>
<dd>A list of what is permitted, with everything else refused.</dd>
<dt>block list</dt>
<dd>A list of what is refused, with everything else permitted.</dd>
<dt>least privilege</dt>
<dd>Giving each thing only what it needs, decided when the thing is designed rather than after.</dd>
<dt>jump host</dt>
<dd>A machine you must log in to before you can reach something else.</dd>
</dl>

## What a segment actually stops

Segmentation gets drawn as a wall on a diagram, which makes it look like a
physical property. It is a policy statement enforced at one device, and the
difference shows up the moment you ask a segmented host what it thinks it can
reach.

<details class="predict">
<summary>A vending machine on its own segment, and a payment host on another. Predict whether the vending machine has a route to it.</summary>

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology segmented-lan
# commands run on iot
$ echo "this host:"; ip -4 -br addr show | grep -v "^lo"; echo; echo "does a route to the payment host exist?"; ip route get 10.10.0.9 | head -1; echo; echo "can it reach the payment host?"; ping -c 2 -W 1 10.10.0.9 2>&1 | tail -2; echo; echo "can it reach the internet stand-in?"; ping -c 2 -W 1 203.0.113.9 2>&1 | tail -2
this host:
iot-swi@if5      UP             10.20.0.9/24 

does a route to the payment host exist?
10.10.0.9 via 10.20.0.1 dev iot-swi src 10.20.0.9 uid 0 

can it reach the payment host?
2 packets transmitted, 0 received, 100% packet loss, time 1033ms


can it reach the internet stand-in?
2 packets transmitted, 2 received, 0% packet loss, time 1040ms
rtt min/avg/max/mdev = 0.198/0.204/0.210/0.006 ms
```

**It has a route, it knows the next hop, and the packets go nowhere.**

The route lookup succeeds. Nothing about addressing, subnetting or the routing
table separates these two hosts, and a reader who expected the segment to work by
making the payment host unreachable in the routing sense has the wrong model. The
vending machine believes it can get there.

Then the two ping results are the finding. The payment host does not answer, and
the internet stand-in does, from the same host with the same routing table in the
same second. So the vending machine is not cut off. It has exactly the access
somebody decided it should have, and no more.

Which locates the control. Reachability here is a decision recorded on the router,
not a fact about the cabling, and it can be changed by editing a rule without
touching a cable, in either direction.

</details>

**The same probe from a host on the corporate segment answers differently.**

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology segmented-lan
# commands run on corp
$ echo "this host:"; ip -4 -br addr show | grep -v "^lo"; echo; echo "does a route to the payment host exist?"; ip route get 10.10.0.9 | head -1; echo; echo "can it reach the payment host?"; ping -c 2 -W 1 10.10.0.9 2>&1 | tail -2; echo; echo "can it reach the internet stand-in?"; ping -c 2 -W 1 203.0.113.9 2>&1 | tail -2
this host:
corp-swc@if9     UP             10.30.0.9/24 

does a route to the payment host exist?
10.10.0.9 via 10.30.0.1 dev corp-swc src 10.30.0.9 uid 0 

can it reach the payment host?
2 packets transmitted, 2 received, 0% packet loss, time 1032ms
rtt min/avg/max/mdev = 0.112/0.145/0.178/0.033 ms

can it reach the internet stand-in?
2 packets transmitted, 2 received, 0% packet loss, time 1017ms
rtt min/avg/max/mdev = 0.123/0.153/0.184/0.030 ms
```

Identical commands, identical route shape, opposite outcome. That is the point
worth carrying: the difference between these two hosts is not what they are or
where they are plugged in. It is which side of a rule they are on.

**And the rule is short enough to read in full.**

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology segmented-lan
# commands run on rtr
$ nft list ruleset
table inet seg {
	chain forward {
		type filter hook forward priority filter; policy drop;
		ct state established,related accept
		ip saddr 10.30.0.0/24 ip daddr 10.10.0.0/24 accept comment "corp may reach payment"
		ip daddr 203.0.113.0/24 accept comment "any segment may reach the internet"
	}
}
```

Three lines of policy and a default. Replies to permitted traffic come back, the
corporate segment may open a connection to payment, everything may reach the
internet stand-in, and the policy for anything else is drop. Notice what is absent:
there is no rule mentioning the vending machine, its address, or its segment. It is
stopped by the absence of permission rather than by the presence of a prohibition,
which is the implicit deny doing all of the work.

**That is also the audit argument.** If the payment segment is reachable only from
one named place, the systems in scope for a payment audit are the ones in that
segment plus the one that may reach it. Widen the rule and you widen the audit.
Segmentation is one of the few controls where the security case and the cost case
point the same way, and it is usually the cost case that gets it funded.

<details class="deeper">
<summary>Where segmentation stops helping, which is sooner than the diagram suggests</summary>

A segment boundary is enforced by something in the path. Everything that does not
cross the boundary never meets the control, and three situations follow from that.

**Traffic inside a segment is unfiltered.** The capture above has a second host on
the vending machine segment, and nothing in that ruleset has any opinion about
whether those two talk. A compromised device reaches everything sharing its
segment at full speed with no record, which is why a segment containing four
hundred devices is a boundary drawn around a place where the boundary does not
apply.

**The segment that is too big is the common failure.** Splitting a flat network
into three is a real improvement and it is often where the work stops, because the
next split is harder and less visibly urgent. The question worth asking of any
segment is what an attacker gets by owning one thing in it, and if the answer is
everything in it, the segment is a label rather than a control.

**The management network touches everything by design.** Whatever monitors,
patches, backs up and administers the estate needs a path to all of it, and that
path crosses every boundary you drew. Segmentation moves the prize rather than
removing it: the thing worth compromising is now the management system, and the
usual reason that goes unnoticed is that its access was configured by the people
who were making the segments.

**Then the one that catches people out.** A boundary only filters what routes
through it. A device with a second connection, a modem, a cellular card, a cloud
tunnel that dials out and stays open, bypasses the boundary entirely without
breaking any rule on it. The next section is that failure in its most respectable
form.

</details>

## Four controls, and the one that held

The objective lists segmentation, access control, permissions, application allow
lists and isolation as separate mitigations, and it is easier to hold them together
by walking one intrusion through all of them.

<figure class="learn-figure">
<svg viewBox="0 0 720 250" role="img" aria-labelledby="controls-title" style="width:100%;height:auto;">
<title id="controls-title">One compromised device tested against four controls in sequence, with the first three crossed and the fourth stopping it</title>
<g fill="currentColor">
<text x="14" y="20" font-size="11">one compromised device, and the four controls between it and the payment host</text>
<text x="14" y="42" font-size="9" fill-opacity="0.85">each box is a control that could have stopped this, in the order the intrusion meets them</text>
<rect x="20" y="80" width="150" height="70" rx="3" fill="var(--red)" fill-opacity="0.10" stroke="var(--red)" stroke-opacity="0.5" stroke-width="1.2"/>
<text x="30" y="100" font-size="9">1. what may run</text>
<text x="30" y="116" font-size="8" fill-opacity="0.85">no allow list here</text>
<text x="30" y="130" font-size="8" fill-opacity="0.85">unsigned code runs</text>
<text x="30" y="146" font-size="8.5" fill="var(--red)" fill-opacity="0.95">crossed</text>
<path d="M 172 115 H 188" stroke="currentColor" stroke-opacity="0.45" stroke-width="1.2"/>
<rect x="190" y="80" width="150" height="70" rx="3" fill="var(--red)" fill-opacity="0.10" stroke="var(--red)" stroke-opacity="0.5" stroke-width="1.2"/>
<text x="200" y="100" font-size="9">2. what it may do</text>
<text x="200" y="116" font-size="8" fill-opacity="0.85">runs as the device</text>
<text x="200" y="130" font-size="8" fill-opacity="0.85">account, so it dials</text>
<text x="200" y="146" font-size="8.5" fill="var(--red)" fill-opacity="0.95">crossed</text>
<path d="M 342 115 H 358" stroke="currentColor" stroke-opacity="0.45" stroke-width="1.2"/>
<rect x="360" y="80" width="150" height="70" rx="3" fill="var(--red)" fill-opacity="0.10" stroke="var(--red)" stroke-opacity="0.5" stroke-width="1.2"/>
<text x="370" y="100" font-size="9">3. is there a route</text>
<text x="370" y="116" font-size="8" fill-opacity="0.85">yes, via 10.20.0.1</text>
<text x="370" y="130" font-size="8" fill-opacity="0.85">to 10.10.0.9</text>
<text x="370" y="146" font-size="8.5" fill="var(--red)" fill-opacity="0.95">crossed</text>
<path d="M 512 115 H 528" stroke="currentColor" stroke-opacity="0.45" stroke-width="1.2"/>
<rect x="530" y="80" width="150" height="70" rx="3" fill="var(--accent)" fill-opacity="0.14" stroke="var(--accent)" stroke-opacity="0.7" stroke-width="1.4"/>
<text x="540" y="100" font-size="9">4. the segment</text>
<text x="540" y="116" font-size="8" fill-opacity="0.85">policy drop, and no</text>
<text x="540" y="130" font-size="8" fill-opacity="0.85">rule names this host</text>
<text x="540" y="146" font-size="8.5" fill="var(--accent)" fill-opacity="0.95">stopped</text>
<text x="14" y="186" font-size="10">three controls did nothing, and the fourth needed no rule naming the attacker</text>
<text x="14" y="206" font-size="9" fill-opacity="0.8">the first three are enforced on the compromised host, which is the machine the attacker now owns</text>
<text x="14" y="232" font-size="9" fill-opacity="0.7">the fourth is enforced somewhere that host cannot reach, and that is the whole of the difference</text>
</g></svg>
<figcaption>The same intrusion measured against four controls in the order it meets them. Three of them are enforced on the device itself, which is exactly the machine that has already been taken, so their failure is not really a surprise and their presence would only have raised the cost. The fourth is a rule on a router the compromised device has no login to and no path to configure. That distinction, whether a control is enforced by the thing being constrained or by something else, is worth more than the taxonomy of control types, and it is the argument that runs underneath the whole zero trust position.</figcaption>
</figure>

**Access control lists are the general form of the fourth box.** An ordered set of
rules, evaluated in order, first match wins, and something at the end that decides
what happens to a request nothing matched. The last part is where most of the
security lives and the least attention goes.

**Permissions are the same idea applied to objects rather than packets**: who may
read this file, who may write it, who may change who else may. The evaluation is
identical in shape and the failure mode is the same, which is a rule granted for a
reason that expired years ago and was never revisited.

**Isolation is segmentation taken to its end.** A segment says reaching this
requires passing a control. Isolation says nothing reaches this and it reaches
nothing, which is what you do with a system that cannot be patched and cannot be
retired. It is expensive because it is inconvenient, and it is the correct answer
more often than it gets used.

<details class="deeper">
<summary>Least privilege as a design position rather than a setting you can go and enable</summary>

Least privilege appears in this objective next to a set of configurable controls,
and it is not one of them. Nothing anywhere has a least privilege switch.

**It is a claim about how a thing was designed.** A system built with least
privilege in mind was decomposed so that each part has a job small enough that its
necessary access is small. A system that was not cannot be retrofitted into one by
tightening permissions, because the parts genuinely need what they are asking for.
The service account with domain administrator rights usually has them because
somebody tried removing them and the application broke.

**Which makes the practical version subtractive and slow.** Take one account,
establish what it actually uses over a representative period, remove the rest, and
be ready to put things back. That is a real project per account, it produces no
visible outcome when it succeeds, and it is why the work does not get done.

**The version that does get done is temporal.** Rather than reducing what an
account may do, reduce when it may do it: rights granted on request, for a window,
with a record. The account still has too much power in principle and holds it for
minutes a month instead of permanently, which turns a standing target into a
narrow one. Topic 57 covers the mechanism.

**And there is a design smell worth naming.** If describing what a component needs
takes a paragraph, the component does too much, and the permissions are a symptom
rather than the problem. The fix is at the boundary between components, which is a
much larger conversation than an access review and the reason least privilege is
listed as a position rather than a control.

</details>

## The jump host, and how a control becomes a bridge

The respectable way to reconnect two segments is to put a machine on both of them
and call it a management host. Whether that is a control or a hole comes down to
one setting.

<details class="predict">
<summary>An administrator on one segment, a device on another, and a jump host with an interface on both. Predict whether the administrator can reach the device.</summary>

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology jump-box
# commands run on admin
$ echo "a route to the device exists here:"; ip route get 10.9.0.20 | head -1; echo; echo "reaching the device directly:"; ping -c 2 -W 1 10.9.0.20 2>&1 | tail -2; echo; echo "asking the jump host to do it instead:"; ssh root@10.0.0.10 "ping -c 2 -W 1 10.9.0.20 | tail -2"; echo; echo "and whether the jump host forwards packets for anyone:"; ssh root@10.0.0.10 "cat /proc/sys/net/ipv4/ip_forward"
a route to the device exists here:
10.9.0.20 via 10.0.0.10 dev admin-swa src 10.0.0.5 uid 0 

reaching the device directly:
2 packets transmitted, 0 received, 100% packet loss, time 1062ms


asking the jump host to do it instead:
2 packets transmitted, 2 received, 0% packet loss, time 1064ms
rtt min/avg/max/mdev = 0.044/0.090/0.136/0.046 ms

and whether the jump host forwards packets for anyone:
0
```

**Not directly, and yes through the jump host, and the last line is why.**

The administrator's machine has a route to the device and cannot reach it, which is
the same shape as the segmented capture above. The jump host, sitting on both
segments, can reach it easily.

The difference between those two facts is the final answer: forwarding is off. The
jump host does not pass packets between its two interfaces, so its presence on both
segments does not join them. What it offers instead is a place to log in, from
which a second connection begins. The administrator's traffic never crosses the
boundary; it stops at the jump host, and new traffic starts there.

Turn that one setting on and the machine becomes a router with a login prompt. The
segments are joined, everything on one can reach everything on the other, and the
diagram still shows a jump host.

</details>

<details class="deeper">
<summary>What a jump host has to do to be worth having, and the four ways it stops being one</summary>

The pattern is old and the failures are predictable enough to list.

**Forwarding must be off**, which the capture above demonstrates, and it needs to
be verified rather than assumed. It is one kernel setting and it is enabled by
default on anything that was ever configured as a router.

**Its own authentication has to be stronger than what it protects**, because it is
now the single thing standing between an administrator and everything they
administer. A jump host reachable with a reusable password is a convenience feature
with a security story attached.

**Sessions through it should be recorded**, since it is the one place every
administrative action passes through, and that is a rare opportunity. It is also
the argument that convinces auditors, which is worth knowing when asking for the
budget.

**And it must not accumulate.** The failure that actually happens is not somebody
turning on forwarding. It is the jump host slowly acquiring a file share, a
monitoring agent, a backup client and a browser, each with its own path out, until
the machine that was supposed to be a narrow door is the best-connected host in the
building. The control is not the machine; it is the machine's smallness.

**The version of this that scales** is a broker rather than a shell host: the
administrator authenticates to a service, the service opens the session, and no
long-lived credential or interactive shell sits on a box in the middle. That is the
same architecture as the privileged access material in topic 57, arriving from the
network side.

</details>

## Allow lists and block lists

Both are lists of names and they are not two flavours of the same control. The
difference is what happens to a name on neither list, and that decides everything
about how each one behaves as the world changes.

**A block list is permissive by default**, so anything new is allowed until
somebody adds it. It is easy to start, it never breaks anything, and it is
permanently behind, because the list can only contain things somebody already knew
were bad.

**An allow list is restrictive by default**, so anything new is refused until
somebody adds it. It is hard to start, it breaks things constantly at first, and
its coverage does not decay, because a technique nobody has seen is refused for the
same reason everything else unlisted is.

<details class="deeper">
<summary>Why an allow list is harder to run and better anyway, and how the ones that survive are built</summary>

The security argument for allow listing is not controversial. The operational
argument against it is what decides whether one is running a year later.

**The cost is entirely in maintenance and it is real.** Every update, every new
tool, every developer with a compiler generates a request, and the requests arrive
at whoever holds the list. Underestimating that is how allow lists end up in
audit-only mode forever, which is a block list with extra logging.

**The technique that makes it survivable is listing something other than files.**
A list of hashes is unmaintainable because every patch invalidates it. A list of
signing certificates is maintainable, because a vendor signs everything they ship
with the same key and a patch changes nothing about the rule. A list of paths that
ordinary users cannot write to is maintainable for a different reason: it says
anything installed by an administrator may run and nothing dropped into a
downloads folder may, which is most of the value for a fraction of the work.

**Then the boundaries matter more than the list.** An allow list on executables
that ignores scripts, interpreters and signed tools that can load arbitrary code is
a list with a documented way around it. Deciding what counts as running something
is most of the design, and the capture in the next section shows one platform where
the answer is narrower than it appears.

**Where each one is the right choice.** Allow list where the set of legitimate
things is small and changes slowly: servers, appliances, point of sale terminals,
industrial equipment. Block list where the set is unbounded and changing:
general-purpose web browsing on a general-purpose workstation. Most estates need
both in different places, and the mistake is picking one philosophy and applying it
everywhere.

</details>

## Across platforms

Whether a machine restricts which programs may run is a question every platform
answers differently, and two of them answer it with something narrower than the
name suggests.

**Windows has two mechanisms, and neither is on by default.**

```powershell
# Microsoft Windows Server 2025 Datacenter, version 10.0.26100.0
> try { $p = Get-AppLockerPolicy -Effective -ErrorAction Stop; 'rule collections: {0}, rules across all of them: {1}' -f $p.RuleCollections.Count, ($p.RuleCollections | Measure-Object -Property Count -Sum).Sum } catch { 'no effective AppLocker policy: ' + $_.Exception.Message }
rule collections: 0, rules across all of them:

# Whether the service that would enforce those rules is even running
> Get-Service AppIDSvc -ErrorAction SilentlyContinue | Select-Object Name, Status, StartType | Format-Table -AutoSize
Name      Status StartType
----      ------ ---------
AppIDSvc Stopped    Manual

# Whether the newer code integrity policy is active, which enforces in the kernel instead
> Get-CimInstance -ClassName Win32_DeviceGuard -Namespace root\Microsoft\Windows\DeviceGuard -ErrorAction SilentlyContinue | Select-Object CodeIntegrityPolicyEnforcementStatus, UsermodeCodeIntegrityPolicyEnforcementStatus | Format-List
CodeIntegrityPolicyEnforcementStatus         : 2
UsermodeCodeIntegrityPolicyEnforcementStatus : 0

# What happens by default when neither is configured, asked of an unsigned file this session creates
> $f = Join-Path $env:TEMP 'nothing.cmd'; Set-Content -LiteralPath $f -Value 'exit 0'; (Get-AuthenticodeSignature $f).Status; cmd /c "$f" ; "exit code $LASTEXITCODE"
UnknownError
D:\a\azure-resume\azure-resume>exit 0
exit code 0
```

No allow list rules exist, the service that would enforce them is stopped, and the
kernel code integrity status is enforcing while the user mode one is not. So this
machine restricts what the kernel loads and does not restrict what a user runs,
which the last block confirms: an unsigned file created seconds earlier ran to
completion. The signature status of `UnknownError` is what an unsigned file looks
like, and it changed nothing about whether it ran.

**macOS assesses rather than lists, and assessment is not enforcement.**

```bash
# macOS 26.5.2, arm64
$ spctl --status 2>&1
assessments enabled

# What that assessment says about a binary the operating system shipped
$ spctl --assess --type execute -vv /usr/bin/true 2>&1 | head -4
/usr/bin/true: rejected (the code is valid but does not seem to be an app)
origin=Software Signing

# What it says about an unsigned file this session just created
$ d=$(mktemp -d); f="$d/nothing.sh"; printf '#!/bin/sh\nexit 0\n' > "$f"; chmod +x "$f"; spctl --assess --type execute -vv "$f" 2>&1 | sed "s|$d/||" | head -3; "$f"; echo "it ran anyway, exit code $?"
nothing.sh: rejected
source=no usable signature
it ran anyway, exit code 0

# Whether the kernel is enforcing signature and filesystem protections underneath all of that
$ csrutil status 2>&1
System Integrity Protection status: disabled.
```

The finding here is worth reading twice. Assessments are enabled, the unsigned
script was assessed and rejected, and then it ran anyway with exit code zero. The
assessment applies to launching an application, not to executing a file from a
shell, so a control that reads as an allow list in a summary is not one for a large
class of what actually runs on the machine. Note also that the kernel integrity
protection is disabled here, which is a property of this continuous integration
image rather than of macOS.

**Linux has neither by default**, and the equivalent is a separate subsystem that
has to be installed and populated before it does anything, which is the same
starting position as the Windows mechanism with less of it pre-built.

**Which gives the sentence to remember.** On all three platforms, the default is
that anything the user can execute, executes. Every allow list in this section is
something somebody has to go and build, and on two of the three the built-in
mechanism covers less than its name implies.

## Try it

**Ask a host what it can reach.** Pick a device on a segment you administer and try
to reach something it should not. Then check whether a route exists to it. Those
two answers together tell you whether you have a segment or a diagram.

**Read the last line of an access list.** Find the implicit deny, or the explicit
rule standing in for it, on any filter you run. If you cannot find it, the list is
permitting things you have not thought about.

**Check the forwarding setting on your jump host.** One value, one command, and it
is the difference between a control and a router.

**Count what one compromise gets.** Take any segment and list what an attacker
owning one device in it could reach without crossing a boundary. That number is the
segment's real size.

## Check yourself

<details class="qa">
<summary>Why does a segmented host still have a route to something it cannot reach?</summary>

Because segmentation is enforced by a filter in the path, not by the routing table.
The capture on this page shows a vending machine resolving a route to the payment
host via its own gateway, then losing every packet sent there while reaching the
internet stand-in in the same second.

So reachability is a rule on a device somewhere else, editable in either direction
without touching a cable, and a host has no way to know what the rule says other
than by trying.

</details>

<details class="qa">
<summary>What stopped the vending machine, given no rule mentions it?</summary>

The default. The ruleset permits replies to established connections, permits the
corporate segment to open connections to payment, and permits everything to reach
the internet stand-in. The policy for anything not matched is drop.

That is the implicit deny doing the work, and it is why the last line of an access
list matters more than any rule in it. A list whose default is permit is a block
list regardless of how many deny rules it contains.

</details>

<details class="qa">
<summary>Three controls failed and one held. What separates them?</summary>

Where they are enforced. The application allow list, the account's permissions and
the routing table all live on the compromised device, which is the machine the
attacker already owns, so their failure follows from the compromise rather than
being a surprise.

The segment boundary is a rule on a router with no login for that device and no
path from it. A control enforced by the thing being constrained can be removed by
whoever takes that thing.

</details>

<details class="qa">
<summary>What makes a jump host a control rather than a router with a login prompt?</summary>

Forwarding being off. The capture shows an administrator unable to reach a device
directly, the jump host reaching it easily, and the forwarding setting reading
zero. Traffic stops at the jump host and a new connection begins there.

The failure in practice is rarely somebody turning forwarding on. It is the machine
accumulating a file share, an agent, a backup client and a browser until the
narrow door is the best-connected host on the site.

</details>

<details class="qa">
<summary>Why is an allow list better than a block list, and why is it harder?</summary>

Better because a technique nobody has seen yet is refused for the same reason
everything unlisted is refused, so coverage does not decay. Harder because every
update and every new tool generates a request, and the requests arrive at whoever
maintains the list.

The ones that survive list signing certificates or writable-path rules rather than
file hashes, because a hash list is invalidated by every patch and the other two
are not.

</details>

## References

- [SP 800-41 Rev. 1](https://csrc.nist.gov/pubs/sp/800/41/r1/final) - NIST, firewall policy, for rule ordering and the default that ends a list. Free. Accessed 2026-08-26.
- [SP 800-207](https://csrc.nist.gov/pubs/sp/800/207/final) - NIST, zero trust architecture, for the argument about where a control is enforced. Free. Accessed 2026-08-26.
- [M1030](https://attack.mitre.org/mitigations/M1030/) - MITRE, network segmentation as a mitigation, with the techniques it addresses listed against it. Free. Accessed 2026-08-26.
- [M1038](https://attack.mitre.org/mitigations/M1038/) - MITRE, execution prevention, which is the allow list half of this objective. Free. Accessed 2026-08-26.

**Where the content came from.** The segmentation and jump host blocks are captured
from Linux network namespaces on the Fedora CoreOS virtual machine, using two
committed topologies: three segments off one router with a filter on it, and an
administrator, a jump host and a device across two segments. Nothing in either is
an attack. The vending machine sends two pings and reads its own routing table, and
the administrator opens an ordinary session to a host it is permitted to reach. The
Windows and macOS blocks come from disposable runners and create one unsigned file
each in a temporary directory, which is removed with the runner.

**If you also work on networks.** The Network+ track's
[access lists, filtering and security zones](/learn/network-plus/acls-filtering-and-security-zones)
covers rule evaluation and zone design in more depth than this page needs.
