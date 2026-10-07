---
title: "On-premises, virtualised and air-gapped"
description: "A container reporting the same kernel as the machine under it, a Windows host that can see one of two containers' processes, what an air gap costs to keep, and why software-defined networking moves the single point of failure rather than removing it."
deck: "The air-gapped network has a USB port"
track: "security-plus"
level: "working"
order: 290
objectives:
  - "Say what on-premises buys as a deliberate choice, and what centralised and decentralised designs trade"
  - "Explain why a container and a virtual machine are different isolation strengths"
  - "Say what has to fail for each of four boundaries to be crossed"
  - "Explain what software-defined networking centralises, and the risk that creates"
  - "Say what an air gap costs to maintain and how it usually fails"
  - "Distinguish physical isolation from logical segmentation"
prerequisites: ["cloud-as-a-security-decision"]
tags: ["security-plus", "security", "architecture", "virtualisation"]
updated: 2026-10-07
draft: false
examObjectives:
  - exam: "sy0-701"
    domain: "3.0"
    objective: "3.1"
sources:
  - title: "SP 800-190, Application Container Security Guide"
    url: "https://csrc.nist.gov/pubs/sp/800/190/final"
    publisher: "NIST"
    accessed: 2026-10-07
    tier: 1
  - title: "SP 800-125, Guide to Security for Full Virtualization Technologies"
    url: "https://csrc.nist.gov/pubs/sp/800/125/final"
    publisher: "NIST"
    accessed: 2026-10-07
    tier: 1
  - title: "RFC 7426, Software-Defined Networking (SDN): Layers and Architecture Terminology"
    url: "https://www.rfc-editor.org/rfc/rfc7426.html"
    publisher: "IETF"
    accessed: 2026-10-07
    tier: 1
  - title: "Isolation modes"
    url: "https://learn.microsoft.com/en-us/virtualization/windowscontainers/manage-containers/hyperv-container"
    publisher: "Microsoft"
    accessed: 2026-10-07
    tier: 1
symptoms:
  - symptom: "A team treats containers as if they were virtual machines"
    anchor: "containers-and-virtual-machines-are-different-strengths"
  - symptom: "An isolated network has been infected anyway"
    anchor: "air-gaps-and-the-person-carrying-the-stick"
---

> **Before you read.** A plant's control network has no connection to anything
> else. There is no cable, no wireless, no modem. It has been infected with the
> same malware that was circulating on the corporate network the previous month.
>
> **How did it cross a gap that contains nothing?**

On something somebody carried. A laptop brought in to update a controller, a USB
stick with a configuration file on it, a vendor engineer's diagnostic kit. An air
gap removes the network path and leaves every other path, and the other paths are
people. Each boundary in this topic can be crossed, and the useful way to compare
them is by what has to fail for that to happen.

### Some words you will need

<dl class="terms">
<dt>on-premises</dt>
<dd>Running on equipment you own, in a building you control.</dd>
<dt>centralised</dt>
<dd>One place makes the decisions and holds the data. Easier to secure and a single target.</dd>
<dt>decentralised</dt>
<dd>Many places each hold part. Harder to secure consistently and harder to take down at once.</dd>
<dt>virtualisation</dt>
<dd>Running whole operating systems as guests on a hypervisor, each with its own kernel.</dd>
<dt>containerisation</dt>
<dd>Running isolated processes that share the host's kernel.</dd>
<dt>namespace</dt>
<dd>A kernel feature that gives a process its own view of something: processes, network, filesystem.</dd>
<dt>software-defined networking</dt>
<dd>Separating the decisions about where traffic goes from the devices that forward it.</dd>
<dt>air gap</dt>
<dd>Physical isolation: no network path at all between two environments.</dd>
</dl>

## On-premises is a choice

After topic 27 it is easy to read on-premises as whatever has not moved yet. It is
better read as an architecture model picked for reasons, and the reasons are
specific.

**On-premises puts every row of the responsibility matrix on your side.** That is
more work and it is also more control: you decide when the hypervisor is patched,
where the data physically sits, and who can walk up to the hardware. Organisations
choose it for exactly those properties, under data residency rules, for systems
that cannot tolerate a provider's maintenance window, or because the equipment
already exists and runs a process that predates the internet.

**Centralised against decentralised is a separate axis.** A centralised design
keeps decisions and data in one place, which makes it easier to secure
consistently, monitor and patch, and makes that one place the target. A
decentralised design spreads both across many places, so no single compromise
reaches everything, at the cost of having many places to keep consistent. Neither
is safer in general. A centralised directory is the right answer for identity and
the wrong answer for a set of factories that must keep running when the head
office link fails.

## Containers and virtual machines are different strengths

Containers and virtual machines get drawn as two boxes on the same diagram, which
suggests they are two flavours of one thing. The machine underneath disagrees.

<details class="predict">
<summary>A container started on a Linux virtual machine. Predict which kernel it reports, and whether the machine can see what runs inside it.</summary>

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ img=docker.io/library/almalinux@sha256:04bb86375be46ad90b21d321fedc77507c98c26f63c652281d0412152ddd8f25
inside() { podman run --rm "$img" sh -c "$1" 2>/dev/null; }
printf '%-42s %s\n' "kernel this virtual machine runs:" "$(uname -r)"
printf '%-42s %s\n' "kernel a container on it reports:" "$(inside 'uname -r')"
printf '%-42s %s\n' "what sits beneath the virtual machine:" "$(systemd-detect-virt)"
echo
printf '%-42s %s\n' "pid namespace of a shell on the machine:" "$(readlink /proc/self/ns/pid)"
printf '%-42s %s\n' "pid namespace inside the container:" "$(inside 'readlink /proc/self/ns/pid')"
printf '%-42s %s\n' "processes the machine can see:" "$(ps -e --no-headers | wc -l)"
printf '%-42s %s\n' "processes the container can see:" "$(inside 'ls -d /proc/[0-9]* | wc -l')"
printf '%-42s %s\n' "syscall filtering inside the container:" "$(inside 'grep Seccomp: /proc/self/status' | awk '{print $2}')"
echo
podman run -d --rm --name iso "$img" sleep 120 >/dev/null 2>&1
echo "the container's sleep, seen from the machine it runs on:"
ps -eo pid,user,comm | awk 'NR == 1 || $3 == "sleep"'
podman stop -t 0 iso >/dev/null 2>&1
kernel this virtual machine runs:          7.1.3-200.fc44.aarch64
kernel a container on it reports:          7.1.3-200.fc44.aarch64
what sits beneath the virtual machine:     apple

pid namespace of a shell on the machine:   pid:[4026531836]
pid namespace inside the container:        pid:[4026532714]
processes the machine can see:             165
processes the container can see:           2
syscall filtering inside the container:    2

the container's sleep, seen from the machine it runs on:
    PID USER     COMMAND
   5187 core     sleep
```

**The same kernel, a different view of it, and the machine can see straight in.**

The first two lines are the whole point. The container reports exactly the kernel
the virtual machine runs, because it is not running one of its own. A container is
a set of ordinary processes that the shared kernel has agreed to show a restricted
view of the world.

The namespace lines are that restricted view. The container has its own process
namespace, a different number from the machine's, so it sees only its own couple
of processes while the machine sees well over a hundred. Seccomp mode 2 means a
filter is narrowing which system calls the container may make, which reduces the
kernel surface it can reach without removing the kernel it shares.

Then the last block reverses the direction. The machine sees the container's
`sleep` as one more process in its own list, owned by an ordinary user. There is no
wall in that direction at all, and there is not supposed to be.

**So a flaw in that one shared kernel, reachable through the calls the filter
allows, is a flaw in every container on the machine at once.** That is the
difference in strength. A virtual machine's guest has its own kernel, and crossing
out of it means finding a flaw in the hypervisor, which is a smaller and more
heavily defended piece of software, as topic 16 described from the other side.

</details>

<figure class="learn-figure">
<svg viewBox="0 0 720 296" role="img" aria-labelledby="iso-title" style="width:100%;height:auto;">
<title id="iso-title">Four isolation boundaries ordered by strength, with what both sides still share and what has to fail for each to be crossed</title>
<g fill="currentColor">
<text x="14" y="20" font-size="11">four boundaries, ordered by what has to fail before they are crossed</text>
<text x="14" y="42" font-size="9" fill-opacity="0.85">the bar under each name is an ordering, not a measurement</text>
<text x="14" y="64" font-size="8.5" fill-opacity="0.7">boundary</text>
<text x="190" y="64" font-size="8.5" fill-opacity="0.7">what both sides still share</text>
<text x="440" y="64" font-size="8.5" fill-opacity="0.7">what has to fail to cross it</text>
<text x="14" y="92" font-size="10">logical segmentation</text>
<rect x="14" y="98" width="30" height="5" rx="1" fill="var(--accent)" fill-opacity="0.8"/>
<text x="190" y="92" font-size="8.5" fill-opacity="0.85">the same switches, routers and cabling</text>
<text x="440" y="92" font-size="8.5" fill-opacity="0.85">one rule, or one mistake in it</text>
<text x="14" y="136" font-size="10">container</text>
<rect x="14" y="142" width="60" height="5" rx="1" fill="var(--accent)" fill-opacity="0.8"/>
<text x="190" y="136" font-size="8.5" fill-opacity="0.85">the same kernel, 7.1.3 in this capture</text>
<text x="440" y="136" font-size="8.5" fill-opacity="0.85">a kernel flaw reachable from inside</text>
<text x="14" y="180" font-size="10">virtual machine</text>
<rect x="14" y="186" width="90" height="5" rx="1" fill="var(--accent)" fill-opacity="0.8"/>
<text x="190" y="180" font-size="8.5" fill-opacity="0.85">the hypervisor and the hardware</text>
<text x="440" y="180" font-size="8.5" fill-opacity="0.85">a flaw in the hypervisor, a smaller target</text>
<text x="14" y="224" font-size="10">air gap</text>
<rect x="14" y="230" width="120" height="5" rx="1" fill="var(--accent)" fill-opacity="0.8"/>
<text x="190" y="224" font-size="8.5" fill-opacity="0.85">the building, the people, their USB sticks</text>
<text x="440" y="224" font-size="8.5" fill-opacity="0.85" fill="var(--red)">somebody carrying something across</text>
<text x="14" y="262" font-size="10">each step down moves the shared layer further from the attacker</text>
<text x="14" y="282" font-size="9" fill-opacity="0.75">and the last step moves it into a person, which is why air gaps fail through removable media</text>
</g></svg>
<figcaption>Four boundaries, ordered by what an attacker has to defeat. Logical segmentation shares all the equipment and is crossed by a single permissive rule. A container shares the kernel, so one exploitable kernel flaw crosses every container on the host at once. A virtual machine shares only the hypervisor and the hardware beneath it. An air gap shares nothing technical at all, and the bottom row is coloured differently because its failure is not a technical event: somebody carries a file across on a stick or a laptop, and every control above it is irrelevant to that.</figcaption>
</figure>

<details class="deeper">
<summary>Container isolation against virtual machine isolation, honestly, and when the weaker one is the right answer</summary>

The comparison is usually made by people with a product to sell on one side of it,
so it is worth stating plainly.

**A virtual machine is the stronger boundary.** Its guest runs its own kernel, and
the interface between guest and hypervisor is small, specified and heavily
scrutinised. Escapes exist, and they are rare, valuable and patched quickly.

**A container is a weaker boundary with better defaults than it used to have.**
Namespaces hide things, control groups limit resources, the system call filter
narrows the kernel surface, and dropping capabilities and running as a non-root
user narrows it further. All of that is real, and all of it sits in front of one
shared kernel whose attack surface is far larger than a hypervisor's.

**The decision turns on who is on the other side of the boundary.** Containers
running components of your own application, built by your own pipeline, are
protecting you from bugs rather than from adversaries, and the weaker boundary is
appropriate. Containers running code from customers who do not trust each other
are a multi-tenant problem, and that is where you want a virtual machine per
tenant, or a sandbox that gives each container its own small kernel.

**The configuration mistakes matter more than the architecture.** A container run
privileged, or with the host's filesystem mounted inside it, or with the container
runtime's control socket exposed to it, is not weakly isolated. It is not isolated
at all, and that is how most real container escapes happen.

</details>

## Software-defined networking

Traditional network devices each make their own forwarding decisions from their
own configuration. Software-defined networking separates the two halves: devices
still forward packets, and a controller decides where packets should go and pushes
those decisions down.

**The security case is consistency.** One controller with one policy applied to
every device removes the drift between a hundred hand-edited configurations, and a
segmentation rule becomes one change rather than a hundred.

**The security cost is concentration.** Everything that used to be distributed
across many devices, and therefore hard to compromise all at once, is now decided
in one place. Whoever controls the controller controls the network.

<details class="deeper">
<summary>The control plane as a new single point of failure, and the three ways it fails</summary>

In a traditional network an attacker who takes one router has one router. In a
software-defined network an attacker who takes the controller has the forwarding
policy for every device it manages, and can rewrite it.

**It fails by compromise.** The controller's management interface, its API, and
the credentials of anybody allowed to use them are now the most valuable targets on
the network. They deserve the treatment a domain controller gets: separate
administration, strong authentication, and an audit trail somebody reads.

**It fails by unavailability.** If the devices lose contact with the controller,
what they do next is a design decision. Some keep forwarding with the last policy
they received, which is safe until something needs to change. Some stop accepting
new flows. Knowing which behaviour you bought before the controller goes down is
the whole of the preparation.

**It fails by a correct change applied everywhere.** The consistency that makes
the controller attractive also means a mistaken policy reaches every device at
once. Change control matters more, not less, and staged rollout to a subset of
devices first is what keeps one typo from being an outage across the estate.

**None of this is an argument against it.** It is the same trade as every
centralisation in this topic: easier to secure consistently, more damaging when the
centre is lost. The control plane needs to be protected as the centre it is.

</details>

## Air gaps and the person carrying the stick

Physical isolation and logical segmentation both separate environments, and they
are different promises.

**Logical segmentation shares the equipment.** Two networks on the same switches,
separated by configuration, are one rule away from being one network, which topic
24 showed with a ruleset short enough to read in full.

**Physical isolation shares nothing on the wire.** No cable, no shared switch, no
wireless. Crossing it requires something to be carried, and that is both its
strength and its weakness: there is no rule to get wrong, and there is a human
process that is wrong whenever anybody is in a hurry.

<details class="predict">
<summary>An air-gapped network must receive software updates and send production reports out every week. Predict where its security now depends.</summary>

**On the procedure for moving data across, and on nothing else.**

Updates have to arrive somehow. Reports have to leave somehow. The moment both are
required, the gap has a door in it, and the door is a person with removable media
or a dedicated transfer system. Every piece of malware that has reached an
air-gapped network did so through a door like that, because there is no other way
in.

So the controls that matter are all about the crossing. Media used only for that
purpose and nothing else. Scanning at a dedicated station on the way in. A
one-way transfer device for reports leaving, so the outbound route cannot be used
inbound. A record of every crossing. And the hardest one, keeping the procedure in
force when a vendor engineer arrives with their own laptop and a deadline.

The gap itself needs no maintenance. The door needs constant maintenance, and that
is the real cost.

</details>

<details class="deeper">
<summary>What an air gap actually costs to maintain, and how to tell whether you still have one</summary>

Air gaps are cheap to declare and expensive to keep, and most of the expense
arrives after the diagram is finished.

**Everything has to be carried.** Patches, signature updates, configuration
changes, logs going out for analysis: each is a manual crossing with a procedure,
which means each is slow, and slow processes get skipped. An air-gapped network is
frequently further behind on patches than a connected one, which is a real
security cost of the isolation.

**Monitoring is local or absent.** Logs cannot be forwarded to a central platform
in real time, so either there is a separate monitoring capability inside the gap,
staffed and maintained, or there is a periodic export that turns detection into
archaeology.

**The gap erodes quietly.** A wireless card in a replacement machine, a cellular
modem added by a vendor for remote support, a "temporary" cable for a migration
that nobody removed. None of these announces itself, which is why the check has to
be active: periodically looking for radios, unexpected interfaces and routes out,
from inside the isolated environment, rather than trusting the drawing.

**So the honest question is not whether the network is air-gapped.** It is when
somebody last verified that it was, and how many crossings the procedure handled
since then. If nobody can answer either, the gap is an assumption with a fence
around it.

</details>

## Across platforms

How strong a container boundary is depends on the platform, and two of the three
answer differently from Linux.

<details class="predict">
<summary>A Windows server runs two containers from the same image, one sharing the host kernel and one in its own small virtual machine. Predict how many of their processes the host can see.</summary>

```powershell
# Microsoft Windows Server 2025 Datacenter, version 10.0.26100.0
> docker info --format 'os type: {{.OSType}}   default isolation: {{.Isolation}}   kernel: {{.KernelVersion}}' 2>&1
os type: windows   default isolation: process   kernel: 10.0 26100 (26100.1.amd64fre.ge_release.240331-1435)

# The build of Windows this machine runs
> cmd /c ver
Microsoft Windows [Version 10.0.26100.33438]

# The build a container reports, in process isolation, which shares this machine's kernel
> docker run --rm --isolation=process mcr.microsoft.com/windows/nanoserver:ltsc2025 cmd /c ver 2>&1 | Select-Object -Last 2
Microsoft Windows [Version 10.0.26100.33438]

# The same container asked for its own virtual machine instead
> docker run --rm --isolation=hyperv mcr.microsoft.com/windows/nanoserver:ltsc2025 cmd /c ver 2>&1 | Select-Object -Last 2
Microsoft Windows [Version 10.0.26100.33438]

# Start one container of each kind, both running the same long ping
> docker run -d --rm --name proc --isolation=process mcr.microsoft.com/windows/nanoserver:ltsc2025 ping -n 300 127.0.0.1 > $null; docker run -d --rm --name hyp --isolation=hyperv mcr.microsoft.com/windows/nanoserver:ltsc2025 ping -n 300 127.0.0.1 > $null; Start-Sleep -Seconds 8; docker ps --format '{{.Names}}  {{.Status}}'
hyp  Up 8 seconds
proc  Up 11 seconds

# How many ping processes the host can see, when each container is running one
> '{0} ping process visible to the host' -f @(Get-Process -Name PING -ErrorAction SilentlyContinue).Count
1 ping process visible to the host

# What the host sees for the container that asked for its own virtual machine
> Get-Process -Name vmmem*, vmwp -ErrorAction SilentlyContinue | Select-Object Name, Id | Format-Table -AutoSize
Name    Id
----    --
vmmem 1544
vmmem 2344
vmmem 2500
vmwp  1392
vmwp  1564

# Remove both containers
> docker rm -f proc hyp 2>&1 | Out-Null; 'both removed'
both removed
```

**One of two.** Both containers are running the same `ping` and the host's process
list contains exactly one. The process-isolated container's `ping` is an ordinary
host process, exactly as the Linux `sleep` was above. The other container's `ping`
is inside a virtual machine, and from the host all that is visible is the
virtual machine worker and memory processes that contain it.

The version lines earlier in the block are worth noticing for the opposite reason.
All three report the identical build, so the version string cannot tell you which
mode a container is running in. The process list can.

Windows therefore offers both strengths from one runtime, chosen per container
with a flag. The default on this server is process isolation, the weaker one, and
choosing the stronger one is a deliberate act.

</details>

**macOS has no Linux kernel to share.**

```bash
# macOS 26.6.2, arm64
$ uname -sr
Darwin 25.6.0

# Whether the hypervisor framework is available here, which is what a container runtime would use to start its virtual machine
$ sysctl -n kern.hv_support 2>&1
0

# Whether any container runtime is installed on this machine
$ for c in docker podman colima container; do printf '%-8s %s\n' "$c" "$(command -v $c || echo 'not installed')"; done
docker   not installed
podman   not installed
colima   not installed
container not installed
```

The kernel is Darwin, which cannot run a Linux container's processes, so every
Linux container on a Mac runs inside a Linux virtual machine. That is how the
capture toolchain for this track works: the VM block at the top of this page came
from exactly such a machine. On a Mac, the container boundary sits on top of a
virtual machine boundary whether anybody chose that or not. This runner shows the
other half of the arrangement too: it is itself a virtual machine, its hypervisor
support reads zero, and no container runtime is installed, so no container could
run here at all.

**Which makes the comparison one sentence.** On Linux a container always shares
the host kernel, on Windows it does unless you ask otherwise, and on macOS it never
does, because there was never a compatible kernel to share.

## Try it

**Ask a container which kernel it runs.** Start any container and compare its
kernel version with the host's. Then find the container's processes in the host's
process list.

**List what each boundary shares.** For one system you run, write down every
boundary between it and the nearest untrusted thing, and what each boundary shares
with the other side.

**Audit one air gap.** If you have an isolated network, find the procedure for
moving data across it and count how many crossings happened last month. Then look
for a radio inside it.

**Find your network's controller.** If any of your network is software-defined,
find out who can change the controller's policy and how that change is reviewed.

## Check yourself

<details class="qa">
<summary>Why is a container a weaker boundary than a virtual machine?</summary>

Because it shares the host's kernel. The capture on this page shows a container
reporting exactly the kernel version of the machine it runs on, with its own
process namespace and a system call filter, and the machine seeing its process as
one more entry in its own list.

A flaw in that shared kernel, reachable through the calls the filter allows,
crosses every container on the host at once. A virtual machine has its own kernel,
so crossing out of it means finding a flaw in the much smaller hypervisor.

</details>

<details class="qa">
<summary>What does software-defined networking centralise, and what risk follows?</summary>

The decisions about where traffic goes, which move from each device's own
configuration to a controller that pushes policy to all of them. That brings
consistency and removes drift between hand-edited configurations.

It also makes the controller a single point of failure in three ways: compromise of
it rewrites the whole network, loss of it leaves devices with whatever behaviour
they were designed to fall back to, and a mistaken change reaches every device at
once.

</details>

<details class="qa">
<summary>How does an air gap usually fail?</summary>

Through something carried across it. The network path is gone, so the remaining
paths are removable media, laptops brought in for maintenance, and vendor
equipment. Any isolated network that needs updates in and reports out has a door
in its gap, and its security is the procedure for using that door.

The gap also erodes quietly through added radios, modems and temporary cables,
which is why it has to be verified from inside rather than trusted from the
diagram.

</details>

<details class="qa">
<summary>What is the difference between physical isolation and logical segmentation?</summary>

Logical segmentation separates environments by configuration on shared equipment,
so a single permissive rule or mistake joins them. Physical isolation shares no
network equipment at all, so crossing it requires something to be carried.

The first fails technically and can be audited by reading the rules. The second
fails procedurally, through people, and can only be audited by checking the
crossings and looking for paths that should not exist.

</details>

<details class="qa">
<summary>Does a container on Windows share the host's kernel?</summary>

By default, in process isolation, yes, the same way a Linux container does. The
capture shows a process-isolated container's process appearing in the host's
process list. Windows can also run a container in Hyper-V isolation, where each
container gets its own small virtual machine and the host sees only the virtual
machine's worker processes.

The version string inside the container is identical in both modes, so it cannot
tell you which one you have.

</details>

## References

- [SP 800-190](https://csrc.nist.gov/pubs/sp/800/190/final) - NIST, application container security, for the shared kernel risk and the configuration mistakes that remove isolation entirely. Free. Accessed 2026-10-07.
- [SP 800-125](https://csrc.nist.gov/pubs/sp/800/125/final) - NIST, security for full virtualisation, for the hypervisor as a boundary. Free. Accessed 2026-10-07.
- [RFC 7426](https://www.rfc-editor.org/rfc/rfc7426.html) - IETF, software-defined networking terminology, including the separation of control and forwarding planes. Free. Accessed 2026-10-07.
- [Isolation modes](https://learn.microsoft.com/en-us/virtualization/windowscontainers/manage-containers/hyperv-container) - Microsoft, process and Hyper-V isolation for Windows containers. Free. Accessed 2026-10-07.

**Where the content came from.** The Linux block is captured on the Fedora CoreOS
virtual machine that runs this repository's containers, starting short-lived
containers from the same pinned AlmaLinux image the rest of the track uses and
comparing what they report with what the machine reports. Nothing on that machine
is changed. The Windows block comes from a disposable runner that pulled a Windows
container image and ran two containers for a few seconds before removing them. The
macOS block comes from a disposable runner and only reads.

**If you also work on networks.** The Network+ track's
[cloud concepts and connectivity](/learn/network-plus/cloud-concepts-and-connectivity)
covers the network virtualisation side of the same ideas.
