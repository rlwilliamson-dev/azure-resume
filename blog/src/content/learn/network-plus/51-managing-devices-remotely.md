---
title: "Managing devices remotely"
description: "Four ways in, and the one that still works when the network does not. Plus a jump box that refuses to route, and a device locked out by a single command sent over the connection it broke."
deck: "The switch is in a locked room 200 miles away and its config is wrong"
track: "network-plus"
level: "working"
order: 520
objectives:
  - "Compare console, SSH, a graphical interface and an API as ways in"
  - "Say what a jump box is and why it must not route"
  - "Distinguish in band from out of band management"
  - "Explain why managing a device through itself is a trap"
  - "Say what an out of band path has to avoid depending on"
prerequisites: ["identity-and-access-management"]
tags: ["network-plus", "networking", "operations"]
updated: 2026-08-13
draft: false
examObjectives:
  - exam: "n10-009"
    domain: "3.0"
    objective: "3.5"
sources:
  - title: "RFC 4251, The Secure Shell (SSH) Protocol Architecture"
    url: "https://www.rfc-editor.org/rfc/rfc4251"
    publisher: "IETF"
    accessed: 2026-08-13
    tier: 1
  - title: "RFC 6241, Network Configuration Protocol (NETCONF)"
    url: "https://www.rfc-editor.org/rfc/rfc6241"
    publisher: "IETF"
    accessed: 2026-08-13
    tier: 1
  - title: "RFC 8040, RESTCONF Protocol"
    url: "https://www.rfc-editor.org/rfc/rfc8040"
    publisher: "IETF"
    accessed: 2026-08-13
    tier: 1
  - title: "NIST SP 800-53 Rev. 5, Security and Privacy Controls"
    url: "https://csrc.nist.gov/pubs/sp/800/53/r5/upd1/final"
    publisher: "NIST"
    accessed: 2026-08-13
    tier: 1
symptoms:
  - symptom: "A device stopped responding immediately after a configuration change"
    anchor: "the-trap"
  - symptom: "A management station can reach a device that users cannot"
    anchor: "in-band-and-out-of-band"
  - symptom: "Nobody can reach a device and it is not down"
    anchor: "the-trap"
---

> **Before you read.** A switch 200 miles away has a configuration mistake. You
> can log in to it and fix it, and the command that fixes it will briefly
> interrupt the network path you are logged in over.
>
> There is nobody at that site today.
>
> **What do you do, and what would have to be true for this not to be a
> decision?**

Every device you administer is somewhere else. This topic is about the ways in,
and about the one property that separates a bad afternoon from a van journey.

### Some words you will need

<dl class="terms">
<dt>console</dt>
<dd>A serial port on the device, reached with a cable rather than a network.</dd>
<dt>jump box</dt>
<dd>A machine you log in to first, because it is the only thing permitted to reach the rest.</dd>
<dt>in band</dt>
<dd>Management traffic sharing the network it manages.</dd>
<dt>out of band</dt>
<dd>Management traffic on a path that does not depend on the network it manages.</dd>
<dt>console server</dt>
<dd>A box with many serial ports, so console access does not require being in the room.</dd>
<dt>API</dt>
<dd>A programmatic interface, so configuration can be applied by software rather than typed.</dd>
</dl>

## What breaks without this

**A device becomes unreachable during a change** and stays that way until
somebody drives to it.

**Everything is reachable from everywhere**, because management was never
separated from ordinary traffic and any compromised machine can log in to a
switch.

**Configuration is applied by hand on forty devices** and three of them end up
different, which is topic 37's drift arriving by the front door.

## Four ways in

The exam names four and they are not interchangeable.

**Console** is a serial port on the device. It needs a cable and physical
presence, or something standing in for presence, and it is the only one that
works when the device has no working network configuration at all. It is what you
use to configure a device that has never been configured, and what you use when
everything else has failed.

**SSH** is the normal answer. An encrypted session, authenticated by key or
password, over the network. Telnet is the same idea without the encryption and is
named on this exam mainly so you can say why it should not be used, which topic
10's capture of a plaintext session shows better than any argument.

**A graphical interface** is a web console on the device or a management
application. Good for seeing state, poor for repeatability, and it is the one that
makes forty devices end up slightly different from each other.

**An API** is how a device is configured by software rather than by a person.
NETCONF over SSH and RESTCONF over HTTPS are the standardised ones, and this is
the route that makes a golden configuration enforceable rather than aspirational.
Topic 37's argument about drift is really an argument for this.

The useful way to hold them apart is by what each one survives. An API and a
graphical interface need the device's network stack and its management service
working. SSH needs its network stack. **The console needs the device to be
powered on and nothing else.**

<details class="deeper">
<summary>If you already lock these down: the access method that is enabled and forgotten</summary>

Most devices offer all four routes at once, and hardening usually removes the obvious one
while leaving something else listening.

The pattern is that somebody disables the plaintext terminal protocol, which is correct
and is the one everybody knows about, and leaves the web interface enabled on plain HTTP
because it is how the device was set up. Or leaves an older management protocol enabled
because a monitoring system used it once. Or leaves a vendor's own discovery and
management service running, which frequently listens on something nobody has heard of.

Which is why hardening a device starts with asking what it is listening on rather than
with a checklist of things to turn off. The scan from topic 74 answers that in a few
seconds, against the device itself, and it reliably finds services nobody knew were
there. A checklist finds only the things its author thought of.

The second half is restricting where management can be reached from, which is worth more
than disabling individual services. A device that accepts management only from the
management network has closed every one of those doors at once, including the ones nobody
enumerated, and it does not depend on getting the list right.

</details>

## Not directly, but through something

Most estates do not let a workstation talk to network equipment at all.

<details class="predict">
<summary>An administrator tries to reach a device on the management network directly from their own machine. Does it answer?</summary>

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology jump-box
# the admin workstation cannot reach the device at all
$ ip netns exec admin ping -c 1 -W 2 -q 10.9.0.20 2>&1 | tail -2
1 packets transmitted, 0 received, 100% packet loss, time 0ms

# and cannot open a connection to it either
$ timeout 10 ip netns exec admin ssh -o BatchMode=yes root@10.9.0.20 hostname 2>&1 | tail -1
ssh: connect to host 10.9.0.20 port 22: Connection timed out
# but a login on the jump host, and a second one from there, works
$ timeout 20 ip netns exec admin ssh -o BatchMode=yes -J root@10.0.0.10 root@10.9.0.20 "hostname; ip -br addr show device-swb" 2>&1 | tail -2
7bf3b5e2689b
device-swb@if12  UP             10.9.0.20/24 
```

</details>

The workstation cannot ping the device and cannot open a connection to it. A login
on the jump host, and a second connection from there, reaches it immediately.

**The jump host is not a router**, and that is the part people get wrong when
building one. If it forwarded packets between the two segments it would be a hole
rather than a control: anything on the admin segment could reach the device
directly and the jump box would be decoration. It has an interface on both sides
and forwarding switched off, so the only thing that crosses is a session somebody
authenticated to open.

What that buys is a single place where administrative access happens, which means
one place to require multifactor authentication, one place to record what was
done, and one set of credentials to rotate. Topic 35's argument about
authentication and authorisation being separate gates is the shape of it: getting
onto the jump box is one gate and reaching a particular device is another.

<details class="deeper">
<summary>If you already run a jump host: why it becomes the most valuable machine you own</summary>

Concentrating administrative access at one point is the right design and it creates a
target with a property worth thinking about carefully.

Everything reachable from the jump host is reachable by whoever controls it, and by design
that is everything. Credentials pass through it, sessions originate from it, and the
network trusts it in a way it trusts nothing else. So it inherits the combined value of
every device behind it, which makes it more valuable than any of them individually.

Three things follow. It gets the strongest authentication available rather than the same
as everything else, because a phishable second factor on the jump host undoes the
protection for the whole estate. It gets the most attention in patching, since it is
exposed by definition. And it gets session recording, which is unusual to configure and
is the only way to answer what was done during an incident, since the devices behind it
will all report the same source.

The failure worth naming is the second jump host that appears because the first was
inconvenient. Somebody sets up a route that bypasses it for one team, temporarily, and
the control now covers most of the estate rather than all of it, which is a much weaker
statement. Auditing for connections to management addresses that did not come from the
jump host is the check that finds those, and it is worth running periodically rather than
trusting the policy.

</details>

## The trap

Managing a device over the network the device provides has one specific failure,
and it is worth seeing rather than being warned about.

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology jump-box
# log in to the device, then change the interface the login is arriving on
$ timeout 20 ip netns exec admin ssh -n -o BatchMode=yes -o ServerAliveInterval=2 -o ServerAliveCountMax=2 -J root@10.0.0.10 root@10.9.0.20 "echo connected; ip link set device-swb down; sleep 6; echo still connected" > /tmp/s1.txt 2>&1 </dev/null; echo "exit status $?"
exit status 255
$ cat /tmp/s1.txt
connected
# try to get back in
$ timeout 15 ip netns exec admin ssh -n -o BatchMode=yes -J root@10.0.0.10 root@10.9.0.20 hostname > /tmp/s2.txt 2>&1 </dev/null; echo "exit status $?"
exit status 255
$ tail -1 /tmp/s2.txt
Connection timed out during banner exchange
# meanwhile the device is running perfectly well
$ ip netns exec device ip -br link show device-swb
device-swb@if12  DOWN           02:00:00:00:00:20 <BROADCAST,MULTICAST> 
```

The session connects, runs the command, and dies before the next line. The
interface it was arriving over is now down, so the acknowledgement never comes
back and the sleep never finishes. The second attempt cannot even complete a
banner exchange.

**The device is entirely healthy.** It is powered, its software is running, its
other interfaces are up, and the only thing wrong with it is one setting that can
now be changed by exactly one method: somebody standing in front of it.

That is the fault the deck describes and the reason the topic exists. Every change
to a device you are managing over that device carries this risk, and the risky
changes are the ordinary ones: an interface setting, an address, a VLAN, a
firewall rule, a routing change.

**Three things reduce it and they are worth knowing as a set.**

Some equipment supports a confirmed commit: apply the change, and if nobody
confirms within a timeout the device rolls it back automatically. That turns a
lockout into a two minute outage.

A scheduled reload does the same thing crudely on equipment that has no such
feature: schedule a reboot in ten minutes, make the change, and cancel the reboot
if you are still connected. If you are not, the device reboots into the saved
configuration.

And out of band access removes the question entirely, which is the rest of this
page.

## In band and out of band

The distinction is one sentence and the consequences fill an incident report.

<figure class="learn-figure">
<svg viewBox="0 0 720 268" role="img" aria-labelledby="oob-title" style="width:100%;height:auto;">
<title id="oob-title">Management traffic sharing the production path against management traffic on a separate path, with the link that fails marked on both</title>
<g fill="currentColor">
<text x="14" y="22" font-size="11">what you have left when the thing you manage is the thing that broke</text>
<text x="14" y="56" font-size="10.5" fill-opacity="0.85">in band</text>
<rect x="90" y="66" width="104" height="38" rx="3" fill="currentColor" fill-opacity="0.12" stroke="currentColor" stroke-opacity="0.6"/>
<text x="142" y="90" text-anchor="middle" font-size="10.5">you</text>
<rect x="470" y="66" width="120" height="38" rx="3" fill="currentColor" fill-opacity="0.12" stroke="currentColor" stroke-opacity="0.6"/>
<text x="530" y="90" text-anchor="middle" font-size="10.5">the switch</text>
<line x1="194" y1="85" x2="464" y2="85" stroke="currentColor" stroke-opacity="0.6" stroke-width="2"/>
<text x="329" y="66" text-anchor="middle" font-size="9.5" fill-opacity="0.8">users and management, one path</text>
<line x1="320" y1="74" x2="340" y2="98" stroke="var(--red)" stroke-width="2.6"/>
<line x1="340" y1="74" x2="320" y2="98" stroke="var(--red)" stroke-width="2.6"/>
<text x="606" y="90" font-size="10" fill="var(--red)">unreachable</text>
<text x="14" y="164" font-size="10.5" fill-opacity="0.85">out of band</text>
<rect x="90" y="174" width="104" height="38" rx="3" fill="currentColor" fill-opacity="0.12" stroke="currentColor" stroke-opacity="0.6"/>
<text x="142" y="198" text-anchor="middle" font-size="10.5">you</text>
<rect x="470" y="174" width="120" height="38" rx="3" fill="currentColor" fill-opacity="0.12" stroke="currentColor" stroke-opacity="0.6"/>
<text x="530" y="198" text-anchor="middle" font-size="10.5">the switch</text>
<line x1="194" y1="184" x2="464" y2="184" stroke="currentColor" stroke-opacity="0.6" stroke-width="2"/>
<text x="329" y="166" text-anchor="middle" font-size="9.5" fill-opacity="0.8">users</text>
<line x1="320" y1="174" x2="340" y2="196" stroke="var(--red)" stroke-width="2.6"/>
<line x1="340" y1="174" x2="320" y2="196" stroke="var(--red)" stroke-width="2.6"/>
<line x1="194" y1="228" x2="464" y2="228" stroke="var(--accent)" stroke-width="2.2" stroke-dasharray="7 4"/>
<path d="M 470 228 l -9 -5 l 0 10 z" fill="var(--accent)"/>
<text x="329" y="248" text-anchor="middle" font-size="9.5" fill="var(--accent)">a console server on its own connection</text>
<text x="606" y="198" font-size="10" fill="var(--accent)">still reachable</text>
</g></svg>
<figcaption>The test for whether a management path is genuinely out of band is not whether it is a separate cable or a separate VLAN. It is whether it shares a dependency with the thing being managed, and the honest version of the question is: if this device stops forwarding, does the path to it still work? A dedicated management VLAN on the same switches fails that test, because a switch with a broken configuration breaks the management VLAN along with everything else. So does a management network that reaches the site over the same wide area link. The one drawn here passes it, and the reason is that the console server has a connection of its own, frequently a mobile one, and reaches each device by a serial cable that carries no IP at all.</figcaption>
</figure>

<figure class="learn-figure photo">

![The front of a rack mounted console server photographed straight on. Two rows of RJ45 sockets fill most of the width, thirty two in total, with about a third of them patched with white, blue and green leads that trail out of frame. The manufacturer's name is printed to the right of the ports, beside a row of status lights, and at the far right are a nine pin serial connector, a single network socket and a power switch.](./images/console-server.jpg)

<figcaption>Thirty two serial ports and one network connection, which is the entire idea. Each of those sockets goes to the console port of one device, so somebody who can reach this box can reach the console of any of them without being in the building. Two details are worth reading. The ports are RJ45 rather than the nine pin connector you might expect, because serial over an RJ45 socket lets a rack be wired with ordinary structured cabling, and the odd one out at the right is a real serial port for managing the console server itself. And the single network socket is the thing the whole design turns on: if that connection runs over the network this box exists to rescue, it is an expensive way to be locked out of thirty two devices at once instead of one. Photograph by Crispmuncher, <a href="https://creativecommons.org/licenses/by/3.0/">CC BY 3.0</a>.</figcaption>
</figure>

<details class="deeper">
<summary>If you already work on networks: what out of band access has to avoid depending on, and why the list is longer than it looks</summary>

An out of band path is only out of band with respect to something. Writing down
what it must survive is more useful than the label, and the list catches most
designs.

**The device's own configuration.** If reaching it requires its routing or its
VLANs to be correct, a configuration mistake takes the path with it. Console
access passes; a management VLAN does not.

**The site's connectivity.** If the path arrives over the same wide area link as
everything else, a failure of that link removes both at once. This is the most
common gap, because a management VLAN carried over the same MPLS or internet
circuit looks separate on a diagram and is not.

**The organisation's authentication.** If logging in to the console server
requires a directory server that is reachable only through the network that is
down, the path exists and cannot be used. Local accounts on out of band equipment
are one of the few places where they are the right answer, and they need to be in
the recovery documentation topic 41 says nobody has read.

**Power.** Console access to a device with no power is nothing. Out of band power
control, a switched PDU on its own path, is the other half, and it is what turns
"somebody has to drive there" into a command.

**Name resolution.** Reaching the console server by name, when DNS is inside the
network that is down, has the same shape as the authentication problem and the
same answer: write the addresses down.

The pattern is one question asked repeatedly: what does this depend on, and is
that thing also broken in the scenario I am designing for? The failure mode is
never that somebody forgot to build an out of band path. It is that they built one
that quietly depended on the thing it was supposed to survive.

</details>

## Across platforms

The client side of three of the four ways in is now the same everywhere, which is
a recent change.

**On Linux**, `ssh` has always been there.

**On macOS**, so has it, along with the serial devices for a console cable.

```bash
# macOS 26.5.2, arm64
$ ssh -V 2>&1
OpenSSH_10.2p1, LibreSSL 3.3.6

# Whether this machine will also accept connections
$ sudo systemsetup -getremotelogin 2>&1 | head -2
Remote Login: On

# The serial side, which needs a driver and a cable rather than a network
$ ls /dev/cu.* 2>/dev/null | head -3
```

**On Windows**, OpenSSH is now installed by default, which for two decades it was
not.

```powershell
# Microsoft Windows Server 2025 Datacenter, version 10.0.26100.0
> ssh -V 2>&1
OpenSSH_for_Windows_9.5p2, LibreSSL 3.8.2

# Whether this machine will also accept connections
> Get-Service sshd -ErrorAction SilentlyContinue | Format-Table Name, Status, StartType -AutoSize
Name  Status StartType
----  ------ ---------
sshd Running Automatic

> Get-WindowsCapability -Online -Name "OpenSSH*" | Select-Object Name, State | Format-Table -AutoSize
Name                          State
----                          -----
OpenSSH.Client~~~~0.0.1.0 Installed
OpenSSH.Server~~~~0.0.1.0 Installed

# The serial side, which needs a cable rather than a network
> [System.IO.Ports.SerialPort]::GetPortNames() | Measure-Object | Select-Object -ExpandProperty Count
1
```

That is worth noting because a great deal of older material assumes a Windows
administrator needs third party software to reach a switch, and for anything
current they do not. The same client, the same key formats, and the same
`~/.ssh/config` behaviour as everywhere else.

The serial side is the part that still differs. A USB serial adapter appears as
`/dev/cu.*` on macOS, `/dev/ttyUSB*` on Linux and a `COM` port on Windows, and
each needs a terminal program that can open it.

## Prove it

**Find the console port on something.** Any managed switch or router you have
access to. Note which end you would need a cable for, and whether you own one.

**Check whether your management path is genuinely out of band.** Ask what it
depends on and whether those things are also broken in the scenario you are
protecting against.

**Look at how your changes are applied.** By hand, by a graphical interface, or by
something that could apply the same change to forty devices identically.

## What trips people up

### 1. Calling a management VLAN out of band

It usually runs on the same switches over the same links. A configuration mistake
that breaks the device breaks the management VLAN with it.

### 2. Building a jump box that routes

If it forwards packets between the two segments, everything on one side can reach
the other and the control is decoration. Forwarding must be off.

### 3. Making a change over the path the change affects

The command applies, the session dies, and the device is healthy and unreachable.
This is the most common way to need a van.

### 4. Assuming the console is a last resort worth skipping

It is the only method that works with no valid network configuration at all, which
is exactly the situation you will be in.

### 5. Putting the out of band network behind the same authentication

A console server that needs a directory server on the broken network is an out of
band path you cannot log in to.

### 6. Treating a graphical interface as equivalent to an API

One is repeatable across forty devices and one is not, and the difference shows up
as configuration drift six months later.

## Work it through

The switch 200 miles away, the change that will interrupt your own session, and
nobody on site.

The first thing to establish is whether this is a decision at all, because it only
is one if the sole way in is through the switch itself.

**So the first question is what other path exists.** If there is a console server
with a cable to that switch, the whole problem evaporates: connect over the
console, make the change, watch it come back, and the interruption to your own
network session is irrelevant because you are not using it. Ten minutes.

Assume there is not. Now you are choosing between three options and they have
different costs.

Make the change and hope. Sometimes correct, when the interruption is genuinely
brief and the change is one you have made before on identical equipment. It is
also how most lockouts happen.

Make it safe to be wrong. If the equipment supports a confirmed commit, use it:
the change applies, and if you do not confirm within the timeout it rolls back by
itself. If it does not, schedule a reload for ten minutes' time, make the change,
and cancel the reload if you are still connected. Both convert a van journey into
a short outage, and the second works on almost anything.

Wait for somebody to be on site. The right answer when the change is large, the
equipment is unfamiliar, or the site matters enough that a wrong guess is
expensive.

**Then there is the question that outlives this switch.** A device 200 miles away
with no out of band access is going to produce this decision again, and the cost
of the next one is not the change itself but the day somebody spends driving. The
argument for a console server is easiest to make while an incident is fresh, and
the design detail that matters is in the deeper panel: it has to reach the site by
a path that does not depend on the equipment it is there to rescue, and somebody
has to be able to log in to it when the directory server is unreachable.

Finally, the small thing that makes the difference on the day. Whatever you decide,
save the working configuration first and know how to get back to it. Topic 37's
point about a rollback plan written before the change rather than during it is the
same point, and this is the change where it is tested.

## Try it

**Lock yourself out of something on purpose.** In a lab, ssh to a machine and take
down the interface you arrived on. It takes thirty seconds and it is not a lesson
anybody forgets.

**Use a confirmed commit.** On any equipment that supports one, make a harmless
change and let the timer expire without confirming. Watching it revert is what
makes you trust it during a real change.

**Try a console cable.** Borrow one, find the port, and connect to something. The
first time is fiddly and the fiddliness is the point: it is worth doing before the
day you need it.

## Check yourself

<details class="qa">
<summary>Why is a dedicated management VLAN usually not out of band?</summary>

Because it normally runs on the same switches over the same links as everything
else. A configuration mistake or a failure that stops the device forwarding stops
the management VLAN too.

The test is not whether the path is separate on the diagram but whether it shares
a dependency with the thing being managed. If the device has to be working for you
to reach it, the path is in band whatever it is called.

</details>

<details class="qa">
<summary>What is the one thing a jump box must not do, and why?</summary>

Forward packets between its two segments. If it routes, then anything on the
administrative side can reach the managed side directly and the jump box is
decoration rather than a control.

With forwarding off, the only thing that crosses is a session somebody
authenticated to open, which gives one place to enforce multifactor
authentication, one place to record what was done, and one set of credentials to
manage.

</details>

<details class="qa">
<summary>You change an interface setting over an SSH session that arrives on that interface. What happens, and what is the state of the device?</summary>

The command applies, the session stops immediately, and no further connection can
be made. The device is entirely healthy: powered, running, other interfaces up,
with one setting that can now only be changed by somebody in front of it.

That is why confirmed commits and scheduled reloads exist. Both make the change
revert on its own if you do not confirm you are still connected, which turns a
lockout into a short outage.

</details>

<details class="qa">
<summary>Which of the four access methods works when a device has no valid network configuration at all?</summary>

The console. It is a serial port on the device reached by a cable, so it needs the
device powered and nothing else: no address, no route, no working switch port and
no management service.

SSH, a web interface and an API all need the device's network stack and its
management service working, which is precisely what is not true in the situation
where you most need to get in.

</details>

<details class="qa">
<summary>An out of band path exists and cannot be used during an outage. Name two likely reasons.</summary>

Authentication and connectivity. If logging in to the console server requires a
directory server reachable only through the network that is down, the path is
there and unusable, which is why local accounts on out of band equipment are one
of the few places they are correct.

And if the console server reaches the site over the same wide area link as
everything else, a failure of that link removes both at once. Name resolution and
power fail the same way: reaching it by a name served from inside the broken
network, or reaching a device with no power, are both paths that exist on paper.

</details>

## References

- [RFC 4251](https://www.rfc-editor.org/rfc/rfc4251) - IETF, the SSH architecture. Free. Accessed 2026-08-13.
- [RFC 6241](https://www.rfc-editor.org/rfc/rfc6241) - IETF, NETCONF, the configuration API that runs over SSH. Free. Accessed 2026-08-13.
- [RFC 8040](https://www.rfc-editor.org/rfc/rfc8040) - IETF, RESTCONF, the same idea over HTTPS. Free. Accessed 2026-08-13.
- [NIST SP 800-53 Rev. 5](https://csrc.nist.gov/pubs/sp/800/53/r5/upd1/final) - NIST, for the controls on separating management access from ordinary traffic. Free. Accessed 2026-08-13.

**Pictures.** A freely licensed file from Wikimedia Commons, downloaded and served
from this site rather than linked across to somebody else's server. Resized and
otherwise unaltered.

- [Lantronix ETS32PR console server](https://commons.wikimedia.org/wiki/File:ConsoleServer.jpeg) by Crispmuncher, [CC BY 3.0](https://creativecommons.org/licenses/by/3.0/).

**Where the output came from.** Both Linux blocks ran on the `jump-box` namespace
topology through `blog/scripts/netlab.sh`, with real sshd instances and key
authentication. The jump host has an interface on both segments and IP forwarding
switched off, which is what makes the first capture's ping failure and ssh success
a demonstration rather than an assertion. The lockout is genuine: the command runs,
the interface goes down, and the session ends without completing, which is why the
second line of output never appears. Host key checking is disabled in the lab
because the containers are rebuilt for every run and there is no way to have
verified a key that did not exist a minute ago; that is the one thing on this page
a real deployment must not copy. The Windows and macOS blocks came from GitHub
Actions runners through `blog/scripts/hostcap.sh`.

**If you also work on Linux.** [SSH and secure remote access](/learn/linux-plus/ssh-and-secure-remote-access)
on the Linux+ track covers the client and server configuration behind the sessions
on this page, including key management and the jump host syntax.
