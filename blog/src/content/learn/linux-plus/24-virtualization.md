---
title: "Virtualization"
description: "Six servers on one box, each convinced it owns the hardware. What a hypervisor actually does, how a container differs from a virtual machine in one measurable way, and the four network modes that decide whether anyone can reach the thing."
deck: "One machine pretending to be six"
track: "linux-plus"
level: "working"
order: 250
objectives:
  - "Distinguish type 1 from type 2 hypervisors and say where KVM sits"
  - "State the one structural difference between a container and a virtual machine"
  - "Choose a disk image format and say what thin provisioning costs"
  - "Pick a VM network mode from a stated requirement"
prerequisites: ["backup-and-restore"]
tags: ["linux", "linux-plus", "virtualization", "kvm", "containers"]
updated: 2026-08-07
draft: false
examObjectives:
  - exam: "xk0-006"
    domain: "1.0"
    objective: "1.7"
sources:
  - title: "virsh(1)"
    url: "https://libvirt.org/manpages/virsh.html"
    publisher: "libvirt project"
    accessed: 2026-08-07
    tier: 1
  - title: "libvirt networking"
    url: "https://wiki.libvirt.org/VirtualNetworking.html"
    publisher: "libvirt project"
    accessed: 2026-08-07
    tier: 1
  - title: "qemu-img"
    url: "https://www.qemu.org/docs/master/tools/qemu-img.html"
    publisher: "QEMU project"
    accessed: 2026-08-07
    tier: 1
  - title: "systemd-detect-virt(1)"
    url: "https://man7.org/linux/man-pages/man1/systemd-detect-virt.1.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "KVM in the kernel documentation"
    url: "https://docs.kernel.org/virt/kvm/index.html"
    publisher: "The Linux Kernel documentation"
    accessed: 2026-08-07
    tier: 1
  - title: "namespaces(7)"
    url: "https://man7.org/linux/man-pages/man7/namespaces.7.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
symptoms:
  - symptom: "A VM has an address but nothing on the network can reach it"
    anchor: "2-the-vm-has-an-address-and-nobody-can-reach-it"
  - symptom: "Host disk full though the VM disks are mostly empty"
    anchor: "3-thin-provisioning-ran-out"
---

> **Before you read.** A rack used to hold six servers doing six jobs, each one
> idle most of the time because you had to size it for its busiest hour.
>
> Now it holds one server running six operating systems, each convinced it has a
> machine to itself. Each has its own kernel, its own disks, its own network card,
> its own reboot.
>
> **How can six operating systems each believe they own hardware that only one of
> them can be using at any instant?**

By being lied to, convincingly, by something underneath them. And the
interesting part is where that something lives, because on Linux it is not a
separate product sitting below the operating system. It is the kernel you
already have.

That fact is why virtualization on Linux looks the way it does, and it is what
the first half of this lesson is about. The second half is containers, which
solve a related problem in a completely different way, and the difference between
them is one you can measure in a single command.

### Some words you will need

<dl class="terms">
<dt>hypervisor</dt>
<dd>The layer that presents fake hardware to several operating systems and shares the real hardware between them.</dd>
<dt>host</dt>
<dd>The physical machine and the software running the hypervisor.</dd>
<dt>guest</dt>
<dd>An operating system running on it, believing it has a machine.</dd>
<dt>image</dt>
<dd>A file on the host that the guest sees as a disk.</dd>
<dt>namespace</dt>
<dd>A kernel feature giving a process its own private view of something, process IDs, mounts, the network. What containers are built from.</dd>
</dl>

## What breaks without this

**You cannot tell what you are on.** Diagnosing a "failed disk" differently
depending on whether it is a physical drive or a hypervisor volume is the
difference between an engineer visit and a console click.

**You size things wrong.** A guest sees the CPU count it was given, not the
host's, and thin-provisioned disks can promise more space than exists.

**You cannot reach the machine you built.** VM networking has four modes and three
of them produce a guest that works perfectly and cannot be reached from where you
are sitting.

## Type 1, type 2, and where KVM sits

| | Type 1, "bare metal" | Type 2, "hosted" |
| --- | --- | --- |
| Runs on | The hardware directly | On top of a normal operating system |
| Examples | VMware ESXi, Xen, Hyper-V | VirtualBox, VMware Workstation, QEMU alone |
| Overhead | Lower | Higher |
| Used for | Servers | Desktops, development |

**KVM does not fit either box cleanly, and that is the interesting part.** KVM is
a kernel module. Load it and the Linux kernel *becomes* a type 1 hypervisor,
while remaining an ordinary operating system you can log into and run things on.

So a Linux host with KVM is simultaneously a general-purpose OS and a bare-metal
hypervisor, which is why "type 1 or type 2" is a question the exam asks and
practitioners argue about. **The answer the exam wants is type 1**, because the
hypervisor is in the kernel with direct hardware access rather than a program
running on top of it.

Three names that always appear together and do different jobs:

| | Is | Does |
| --- | --- | --- |
| **KVM** | A kernel module | Gives the kernel hardware-accelerated virtualization |
| **QEMU** | A userspace program | Emulates the devices: disks, network cards, display |
| **libvirt** | A management layer | A stable API and tooling over both, plus `virsh` |

KVM makes the CPU fast; QEMU pretends to be the hardware around it; libvirt is
what you actually type at. Without KVM, QEMU still works by emulating the
processor too, which is dramatically slower, and is exactly what happens when
you run an x86 image on an ARM machine.

**Hardware virtualization must be enabled in firmware.** Intel VT-x or AMD-V,
frequently off by default on desktop boards. `grep -E 'vmx|svm' /proc/cpuinfo`
returns nothing when it is disabled, and the symptom is a VM that runs at roughly
a twentieth of the speed you expected.

## Telling where you are

`systemd-detect-virt` reports what is virtualising the machine. Note that the
command's **exit status** is also printed.

<details class="predict">
<summary>This is a script-friendly command, so its exit status has to mean something. Given it runs on a virtual machine here, what status would it return on bare metal?</summary>

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ systemd-detect-virt; echo "exit status $?"; echo "--- what does the firmware call this machine ---"; sudo dmidecode -s system-product-name
apple
exit status 0
--- what does the firmware call this machine ---
Apple Virtualization Generic Platform
```

</details>

**`systemd-detect-virt` is the one-word answer.** It names the hypervisor
(`kvm`, `vmware`, `microsoft`, `oracle`, `xen`, or here `apple`) and exits
non-zero on bare metal, which makes it the version to use in a script.

`dmidecode -s system-product-name` reads what the firmware claims, which is where
the same answer comes from in a more verbose form. On a physical machine it names
the model, and that is what a hardware vendor asks for.

`systemd-detect-virt -c` answers specifically "am I in a container", and `-v`
specifically "am I in a VM", which matters because you can be in both.

## Containers are not small virtual machines

This is the distinction the exam tests and the one worth being precise about.

<details class="predict">
<summary>These captures were taken inside a Debian container running on a Fedora host. What will <code>uname -r</code> report, Debian's kernel or Fedora's?</summary>

```bash
# Debian 13 (trixie), x86_64
$ echo "--- markers a container leaves for itself ---"; ls -l /run/.containerenv /.dockerenv 2>/dev/null || echo "(no marker file)"; echo "--- and PID 1 is not systemd ---"; cat /proc/1/comm; echo "--- the kernel is the hosts ---"; uname -r
--- markers a container leaves for itself ---
-rw-r--r--. 1 root root 0 Aug  8 02:37 /run/.containerenv
--- and PID 1 is not systemd ---
sh
--- the kernel is the hosts ---
7.1.3-200.fc44.aarch64
```

**Fedora's.** `7.1.3-200.fc44`, the `fc44` says Fedora 44, reported from
inside a container whose entire userland is Debian 13.

<figure class="learn-figure">
<svg viewBox="0 0 720 330" role="img" aria-labelledby="vc-title vc-desc" style="width:100%;height:auto;">
<title id="vc-title">A virtual machine and a container, stacked against each other on one host</title>
<desc id="vc-desc">Both stacks sit on the same hardware and the same host kernel, drawn here as boxes spanning the full width. A virtual machine adds a hypervisor, then a complete guest kernel of its own, then the guest userland. A container adds namespaces and cgroups, which are host kernel features rather than a layer of software, and then the container userland directly. The slot where a virtual machine keeps its guest kernel is empty for the container, which is why a Debian container on a Fedora host reports Fedora's kernel version.</desc>
<g>
<text x="40" y="34" font-size="11.5" fill="currentColor">virtual machine</text>
<text x="400" y="34" font-size="11.5" fill="currentColor">container</text>
<rect x="40" y="46" width="280" height="42" rx="4" fill="currentColor" fill-opacity="0.08" stroke="currentColor" stroke-opacity="0.35"/>
<text x="180" y="72" text-anchor="middle" font-size="11" fill="currentColor">guest userland, Debian 13</text>
<rect x="400" y="46" width="280" height="42" rx="4" fill="currentColor" fill-opacity="0.08" stroke="currentColor" stroke-opacity="0.35"/>
<text x="540" y="72" text-anchor="middle" font-size="11" fill="currentColor">userland, Debian 13</text>
<rect x="40" y="98" width="280" height="42" rx="4" fill="var(--accent)" fill-opacity="0.12" stroke="var(--accent)" stroke-opacity="0.9" stroke-width="1.8"/>
<text x="180" y="124" text-anchor="middle" font-size="11" fill="var(--accent)">guest kernel, its own</text>
<rect x="400" y="98" width="280" height="42" rx="4" fill="none" stroke="var(--accent)" stroke-opacity="0.75" stroke-width="1.8" stroke-dasharray="6 4"/>
<text x="540" y="124" text-anchor="middle" font-size="11" fill="var(--accent)">nothing here</text>
<rect x="40" y="150" width="280" height="42" rx="4" fill="currentColor" fill-opacity="0.06" stroke="currentColor" stroke-opacity="0.3"/>
<text x="180" y="176" text-anchor="middle" font-size="11" fill="currentColor" fill-opacity="0.8">hypervisor</text>
<rect x="400" y="150" width="280" height="42" rx="4" fill="currentColor" fill-opacity="0.06" stroke="currentColor" stroke-opacity="0.3"/>
<text x="540" y="176" text-anchor="middle" font-size="11" fill="currentColor" fill-opacity="0.8">namespaces and cgroups</text>
<rect x="40" y="212" width="640" height="46" rx="4" fill="currentColor" fill-opacity="0.1" stroke="currentColor" stroke-opacity="0.4"/>
<text x="360" y="232" text-anchor="middle" font-size="11.5" fill="currentColor">one host kernel</text>
<text x="360" y="249" text-anchor="middle" font-size="10" fill="currentColor" fill-opacity="0.75">7.1.3-200.fc44.aarch64</text>
<rect x="40" y="268" width="640" height="40" rx="4" fill="currentColor" fill-opacity="0.06" stroke="currentColor" stroke-opacity="0.3"/>
<text x="360" y="293" text-anchor="middle" font-size="11" fill="currentColor" fill-opacity="0.8">hardware</text>
</g>
</svg>
<figcaption>Namespaces and cgroups are drawn as a layer here for the shape of it, but they are features of the kernel below rather than software sitting on top. The empty slot is the entire difference and it is what the capture above reports: Debian userland, Fedora kernel, because there is only the one.</figcaption>
</figure>

That single line is the whole difference. **A container has no kernel of its
own.** It is a set of processes on the host's kernel, given private views of the
filesystem, the process table, and the network by namespaces, and limited by
cgroups. Everything else about it is Debian; the kernel is not, because there is
only one.

A virtual machine would report its own kernel version here, because it has
one, booted by its own bootloader, on emulated hardware, exactly as in lesson
09.

Two more tells in that output. **PID 1 is `sh`**, not systemd: a container's first
process is whatever it was told to run, and when that exits the container stops.
And `/run/.containerenv` is a marker Podman leaves for anything that wants to
know; Docker leaves `/.dockerenv`.

The consequences follow directly from having no kernel:

- **A container starts in milliseconds** because there is nothing to boot.
- **It cannot run a different operating system.** A Windows container needs a
  Windows kernel and therefore a Windows host. A "Linux container on a Mac" is
  running inside a Linux VM, which is precisely what these captures came from.
- **Kernel modules, `sysctl` settings, and the kernel version are the host's.**
  This is why the earlier lessons on booting and modules could not be captured in
  a container.
- **The isolation is weaker**, because a kernel bug is a shared kernel bug. A VM
  boundary is a hardware boundary; a container boundary is a software one.

</details>

| | Virtual machine | Container |
| --- | --- | --- |
| Kernel | Its own | The host's |
| Boots | Yes, seconds to minutes | No, milliseconds |
| Size | Gigabytes | Megabytes |
| Runs a different OS | Yes | Only the same kernel family |
| Isolation | Hardware-enforced | Kernel-enforced |
| Right for | Different OS, strong isolation, legacy | Many instances of one application |

**They are not competitors.** The normal arrangement is containers running inside
virtual machines: the VM gives a hard boundary between tenants and the containers
give density and fast deployment inside it. Every managed Kubernetes service is
built this way.

<details class="deeper">
<summary>If you already administer Linux: the namespaces and cgroups a container is actually made of</summary>

"Container" is not a kernel object. There is no container system call. It is a
convention built from two independent kernel features, and knowing that explains
most container behaviour that otherwise looks arbitrary.

**Namespaces give a private view.** `lsns` lists them; each is a separate
mechanism:

- **`pid`**, its own process table, which is why PID 1 inside is `sh` and the
  host sees the same process with a different number.
- **`mnt`**, its own mount table, which is why `findmnt` inside looks nothing
  like outside, and why a host filesystem mounted *after* the container
  started is invisible to it.
- **`net`**, its own interfaces and routing table. This is what makes port
  publishing necessary.
- **`uts`**, its own hostname.
- **`ipc`**, **`user`**, **`cgroup`**, **`time`**, the rest.

**Cgroups impose limits.** CPU shares, memory ceilings, I/O weight. A container
exceeding its memory limit is killed by the OOM killer, and the exit code 137
that people find mystifying is 128 + 9, meaning SIGKILL. `systemd-cgtop` shows
live usage per cgroup, on containers and on services alike, because systemd units
use the same mechanism.

**`nsenter`** joins an existing container's namespaces from the host, which is how
you debug a container that has no shell in it: `nsenter -t <pid> -n ip addr` runs
the host's `ip` inside the container's network namespace.

**Rootless containers** map a range of host UIDs into the container via the user
namespace, so root inside is an unprivileged user outside. It removes the
"container root is host root if the boundary breaks" problem and costs you some
capabilities. Podman defaults to rootless; Docker traditionally does not, which is
the substantive security difference between them.

</details>

<details class="deeper">
<summary>If you already administer Linux: the three network modes, and which one the VM you cannot reach is on</summary>

"The VM has no network" is nearly always the VM having exactly the network it was
configured for, and the configuration being the wrong one for what you wanted.

| Mode | The VM gets | Reachable from the LAN | Typical use |
| --- | --- | --- | --- |
| **NAT** | A private address, behind the host | **No**, unless you forward a port | Default. A desktop VM that needs outbound access. |
| **Bridged** | An address from the LAN's own DHCP | **Yes**, it is a peer | A server anybody else has to reach |
| **Host-only** | A private address, host only | No, and no internet either | Isolated test networks |
| **Routed** | A LAN-visible address, host routes for it | Yes, with a static route upstream | Uncommon; needs cooperation from the network |

**NAT is the default on every hypervisor**, and it is the answer to "why can I
ssh out of the VM but not into it". Outbound works because the host translates
the source address; inbound has nothing to translate *to* until you publish a
port, which is exactly the mechanism from the firewall lesson, DNAT at
prerouting.

Bridged is what a server wants, and it has two requirements people meet the
hard way. The physical interface must accept frames for a MAC address that is
not its own, which **wireless interfaces generally refuse**, bridging over
wifi usually just does not work, and the failure is silent. And the switch
port must allow multiple MAC addresses; port security limiting it to one drops
the VM's traffic and sometimes disables the port entirely.

The diagnostic order when a VM is unreachable:

```
virsh domiflist myvm            # which network is it actually on
ip -brief addr                  # did it get an address, and from where
bridge link                     # is the tap device enslaved to the bridge
ip route                        # does it have a default gateway
```

An address in `192.168.122.0/24` is libvirt's default NAT network, and that alone
answers the question. `10.0.2.15` is QEMU's user-mode networking, which is NAT
implemented entirely in userspace and cannot be reached inbound at all.

**And one that looks like a network fault and is not:** a VM cloned from a template
carries the template's MAC address and, on some distributions, a `.link` or
`70-persistent-net.rules` file pinning the old interface name. Two clones on one
LAN with one MAC produces intermittent, direction-dependent failures that look like
a switch problem. `virt-sysprep` exists to strip that state before cloning.

</details>

## Disk images

A guest's disk is a file on the host. Which format decides what you can do with
it.

| Format | Used by | Notable |
| --- | --- | --- |
| `raw` | anything | Fastest, simplest, no features |
| `qcow2` | QEMU/KVM | Thin provisioning, snapshots, compression |
| `vmdk` | VMware | |
| `vhd` / `vhdx` | Hyper-V, Azure | |
| `vdi` | VirtualBox | |

`qemu-img` creates and converts them, including between vendors:

```
qemu-img create -f qcow2 disk.qcow2 40G
qemu-img info disk.qcow2
qemu-img convert -f vmdk -O qcow2 old.vmdk new.qcow2
```

**`qemu-img convert` between formats is how a machine moves between
hypervisors**, and it is worth knowing exists before somebody tells you a VMware
guest cannot be migrated.

Thin provisioning is the qcow2 feature that matters and the one that bites. A
40 GB qcow2 occupies a few hundred kilobytes until the guest writes to it, and
grows on demand. So you can create six 40 GB disks on a 100 GB host, which is
convenient right up to the day the guests fill them.

The host running out of space pauses every guest at once. Guests do not see a
disk error and handle it gracefully; they see writes stop. `qemu-img info`
shows the difference between virtual size and actual size, and the sum of the
virtual sizes against the host's free space is a number worth monitoring.

## Networking, and why the VM is unreachable

Four modes. Choosing wrong is the most common reason a new VM works perfectly and
cannot be reached.

| Mode | Guest gets | Reachable from the LAN | Use for |
| --- | --- | --- | --- |
| **NAT** | A private address behind the host | **No**, not without port forwarding | Desktop VMs that only need outbound access |
| **Bridged** | An address on the real LAN, from its DHCP | **Yes**, like any other machine | Servers |
| **Host-only** | A private address, host only | No, and no internet either | Isolated testing |
| **Routed** | Its own subnet, host forwards | Yes, with routing configured | Segmented networks |

**NAT is the default nearly everywhere**, which is why this comes up so often.
The guest reaches the internet, updates work, everything looks healthy, and
nothing on the network can start a connection *to* it, because it is behind
the host's address on a private network that does not exist outside the host.

**Bridged is what a server wants.** The guest's virtual interface is attached to
the host's physical one, it gets an address from the same DHCP server as
everything else, and it is an ordinary machine on the LAN.

Two things that catch people with bridging: the host's physical interface must be
enslaved to a bridge, which briefly disconnects the host when you set it up; and
some wireless adapters cannot bridge at all, because 802.11 does not carry
arbitrary source MAC addresses. On a laptop, bridging over Wi-Fi fails for
reasons that have nothing to do with your configuration.

<details class="deeper">
<summary>If you already administer Linux: virsh, and what to reach for on a KVM host</summary>

`virsh` is libvirt's shell, and it is the same commands whether the host is local
or remote (`virsh -c qemu+ssh://host/system`).

```
virsh list --all                       # every guest and its state
virsh start web01 / shutdown / destroy # destroy is a power cut, not a delete
virsh undefine web01 --remove-all-storage   # this is the delete
virsh dumpxml web01                    # the guest's full definition
virsh edit web01                       # edit it, with validation
virsh console web01                    # serial console, when the network is gone
virsh net-list --all                   # the virtual networks
virsh snapshot-create-as web01 pre-upgrade
```

**`destroy` versus `undefine` is the trap.** `destroy` stops a running guest
abruptly, the equivalent of pulling the cord, and the guest still exists.
`undefine` removes the definition. The naming is unfortunate and the exam
likes it.

**`virsh console` is the one worth knowing before you need it.** When a
guest's networking is broken, the serial console still works, which turns "I
have to open the hypervisor GUI" into a command. It needs the guest configured
for a serial console: `console=ttyS0` on the kernel command line, which is
lesson 09 arriving again.

**Storage pools** (`virsh pool-list`, `vol-list`) are libvirt's abstraction over
where images live, so a guest definition does not hardcode a path. Worth using
from the start; retrofitting it is tedious.

**`virt-install`** creates guests from the command line and is what belongs in
automation. **`virt-manager`** is the GTK interface, and **Cockpit** gives you a
web console with VM management built in, which is the RHEL-family answer for
people who want a GUI on a headless server.

<figure class="learn-figure photo">

![The Cockpit web console overview page in a browser, dark themed. A left sidebar lists System with Overview, Logs, Storage, Networking, Podman containers, Accounts and Services, then a Tools group with Applications, Diagnostic reports, Kernel dump, SELinux, Software updates and Terminal. A yellow banner across the top reads that the web console is running in limited access mode, with a button offering to turn on administrative access. Below it the host name is shown running AlmaLinux 10.2, and four cards follow: Health noting two services have failed and security updates available, Usage showing 1 percent of 5 CPUs and 0.70 of 1.9 GiB memory, System information listing the model, machine ID and uptime, and Configuration listing hostname, system time, domain, performance profile, cryptographic policy and secure shell keys.](./images/cockpit-overview.png)

<figcaption>Cockpit on a running AlmaLinux 10.2 machine, reached in a browser on port 9090. Every item in that sidebar is a lesson in this track wearing a different face: Storage is lesson 12 onward, Networking is 16 and 17, Accounts is 27, Services is 33, SELinux is 44, and Terminal is the shell you have been using all along. The banner is the part worth noticing. The console opens in limited access mode because the account that logged in is an ordinary user, and turning on administrative access is <code>sudo</code> from lesson 06 with a button instead of a prompt. Captured on this machine.</figcaption>
</figure>

**`virt-v2v`** converts a VMware or Hyper-V guest to KVM, including installing the
right drivers, which is a great deal more than `qemu-img convert` does on its own.

</details>

<details class="deeper">
<summary>If you already administer Linux: guest agents, overcommit, and the tuning that actually matters</summary>

**Install the guest agent.** `qemu-guest-agent` in a KVM guest,
`open-vm-tools` under VMware. Without it the hypervisor cannot request a clean
shutdown, cannot freeze the filesystem for a consistent snapshot, and cannot
report the guest's IP address. "Shut down" without an agent is a power button
press, and a snapshot without one is a crash-consistent image, which is the
backup consistency problem from lesson 23 in a new costume.

**CPU overcommit is fine; memory overcommit is not.** Guests are idle most of the
time, so allocating more vCPUs than the host has cores is normal and works. Memory
is different: a guest that has been given 8 GB will eventually use 8 GB, and when
the host cannot supply it something is killed or swapped, which is catastrophic
for latency across every guest. Ballooning and KSM reclaim some of it and neither
is a licence to promise memory you do not have.

**Do not give a guest more vCPUs than it needs.** A four-vCPU guest has to be
scheduled onto four physical cores at once for some operations, so on a busy host
an over-provisioned guest waits *longer* than a smaller one. This is
counter-intuitive and it is one of the more common performance mistakes.

**Use virtio drivers for disk and network.** Emulated IDE and e1000 exist for
compatibility and are much slower. A Linux guest has them built in; a Windows
guest needs the driver disk at install time, and a Windows VM that is
inexplicably slow is very often running on emulated hardware.

**Nested virtualization**, running a hypervisor inside a guest, needs enabling
on the host module (`kvm_intel nested=1`) and is slow. It is why the podman
machine these captures came from cannot itself host VMs, and why this topic
has fewer captures than the others.

**Snapshots are not backups**, and the reasoning from lesson 23 applies without
change: they live on the same storage. A qcow2 snapshot chain also degrades read
performance the longer it gets, and a forgotten snapshot from six months ago is a
performance problem as well as a space one.

</details>

## Across distributions

| | RHEL family | Debian family |
| --- | --- | --- |
| Packages | `qemu-kvm`, `libvirt`, `virt-install` | `qemu-kvm`, `libvirt-daemon-system`, `virtinst` |
| Group for unprivileged use | `libvirt` | `libvirt`, sometimes `kvm` |
| Images default to | `/var/lib/libvirt/images/` | same |
| Web management | Cockpit, with the VM plugin | Cockpit, packaged separately |
| Container tooling | Podman, default | Docker or Podman |

**Podman is the RHEL family's default and is daemonless and rootless by
default**, which is a genuine security difference from Docker rather than a
branding one: there is no privileged daemon owning every container, and container
root is an unprivileged host user.

## Prove it

On a machine you have just been given:

```bash
# Am I on hardware, in a VM, or in a container
systemd-detect-virt
systemd-detect-virt -c && echo "in a container"

# If it is a VM, what is the hypervisor
sudo dmidecode -s system-product-name

# Can this machine host VMs at all
grep -c -E 'vmx|svm' /proc/cpuinfo
lsmod | grep kvm

# What is running
virsh list --all
qemu-img info /var/lib/libvirt/images/web01.qcow2
```

**`grep -c -E 'vmx|svm' /proc/cpuinfo` returning 0 is the answer to "why is this
VM so slow".** Hardware virtualization is disabled in firmware and QEMU is
emulating the processor.

## What trips people up

### 1. "Type 1 or type 2" for KVM

**Type 1.** It is a kernel module, so the hypervisor has direct hardware access,
even though the same kernel is also running an ordinary operating system. The
ambiguity is real and the exam's answer is type 1.

### 2. The VM has an address and nobody can reach it

NAT. The guest is behind the host on a private network, so outbound works and
inbound does not.

Switch to bridged for anything that must be reachable, or add port forwarding for
a single service. `virsh domiflist <guest>` shows which network a guest is
attached to.

### 3. Thin provisioning ran out

Six 40 GB qcow2 images on a 100 GB host is legal and works until the guests
actually write. When the host fills, every guest pauses at once.

`qemu-img info` shows virtual against actual size. Monitor host free space,
not guest free space. The guests will all report plenty.

### 4. `virsh destroy` when you meant to shut down

`destroy` is an abrupt power-off, not a deletion. It risks filesystem damage in
the guest exactly as pulling the cord would.

`virsh shutdown` asks the guest to shut down cleanly, and needs the guest agent
installed to work reliably. `undefine` is the one that deletes.

### 5. Expecting a container to behave like a VM

No init system, so no `systemctl`. No separate kernel, so no `modprobe` and no
`sysctl` that survives. One foreground process, and when it exits the container
stops.

A container that "will not stay running" is nearly always a process that
daemonised itself into the background, leaving PID 1 with nothing to do.

## Work it through

You are asked to run a legacy application on a new server. It needs CentOS 7,
kernel 3.10, and a specific out-of-tree storage driver. The new host runs a
current RHEL-family release. Somebody suggests "just containerise it".

Reason it out before reading on.

**Containers cannot do this, and the reason is specific.** A container shares the
host's kernel. The application needs kernel 3.10; the host is running something
far newer. There is no configuration that changes this, because the container has
no kernel of its own to configure.

The `uname -r` capture earlier is the proof: a Debian container on a Fedora host
reports Fedora's kernel. A CentOS 7 container on this host would report the host's
kernel, and the application would be running on exactly the kernel it cannot run
on.

**The out-of-tree driver settles it twice over.** Kernel modules are loaded
into the host kernel and are global. A container cannot load one, and if the
host loaded it, it would have to be built for the *host's* kernel, which is
lesson 10's `vermagic` rule, and which defeats the purpose.

So it needs a virtual machine. Its own kernel, its own module, its own boot.

```
virt-install --name legacy-app --memory 8192 --vcpus 4 \
  --disk path=/var/lib/libvirt/images/legacy.qcow2,size=100,format=qcow2 \
  --network bridge=br0 \
  --os-variant centos7.0 \
  --location /iso/CentOS-7.iso
```

**Bridged**, because it is a server other things must reach. **qcow2**, for
snapshots before you touch anything. **`--os-variant`** because it makes libvirt
choose sensible virtual hardware for that guest, and getting it wrong is a common
cause of poor performance.

Then the things that are easy to skip. Install the guest agent so the host can
shut it down cleanly and snapshot it consistently. Snapshot before installing
the driver. And write down that this guest exists and why, because a CentOS 7
machine is now an unpatched machine and that is a decision somebody should
have made deliberately.

Now the point worth extracting. **"Containerise it" is a good instinct and the
wrong tool here, and the reason is one question:** does this workload need its
own kernel?

If yes (a different OS, a different kernel version, a kernel module, a real
isolation boundary between tenants) it is a virtual machine, and no amount of
container tooling changes that.

If no (it is an application that runs on this kernel and you want many of
them, started quickly, packaged with their dependencies) it is a container,
and a VM is wasteful.

That one question answers it nearly every time, and it is why the `uname -r`
capture is the most useful thing in this lesson.

## Try it

Optional. Most of this needs a machine that can host VMs, which a virtual machine
usually cannot.

1. `systemd-detect-virt` on everything you have access to. Note which report bare
   metal.
2. `grep -c -E 'vmx|svm' /proc/cpuinfo`. Zero means hardware virtualization is
   off in firmware.
3. `sudo dmidecode -s system-product-name` and compare with what you expected.
4. In a container, `podman run --rm -it debian bash`, run `uname -r` and
   compare it with the host's. Then `cat /proc/1/comm`.
5. `lsns` on a host running containers, and find the extra namespaces.
6. If you have a KVM host: `virsh list --all`, then `qemu-img info` on an image
   and compare virtual size with actual size.

**Verification step.** You have it when you can be handed a workload and decide
between a container and a VM by answering one question, and say what the question
is.

## Check yourself

<details class="qa">
<summary>What is the single structural difference between a container and a virtual machine, and name two consequences?</summary>

**A container shares the host's kernel; a virtual machine has its own.** That is
the whole of it, and everything else follows.

Consequences, any two:

**Startup time.** A container has nothing to boot, so it starts in
milliseconds. A VM boots (firmware, bootloader, kernel, initramfs, init)
exactly as lesson 09 describes.

**Operating system.** A container can only run something that works on the host's
kernel. A Windows container needs a Windows host. A VM can run anything.

Kernel modules and `sysctl`. Both are the host's. A container cannot load a
module or set a kernel parameter that persists.

**Isolation strength.** A VM boundary is enforced by hardware; a container
boundary is enforced by the kernel, so a kernel vulnerability is a shared
vulnerability.

`uname -r` inside a container proves it: it reports the host's kernel, not the
container image's distribution.

</details>

<details class="qa">
<summary>Is KVM a type 1 or type 2 hypervisor, and why is the question awkward?</summary>

**Type 1**, and that is the exam's answer.

It is awkward because KVM does not look like the type 1 examples. It is a
kernel module rather than a dedicated product, and the machine running it is
also an ordinary Linux system you can log into, run a web server on, and use
as a desktop, which sounds exactly like type 2.

The reason it is type 1 anyway: **the hypervisor is in the kernel**, with direct
hardware access, not a userspace program mediated by an operating system beneath
it. Loading `kvm` turns the kernel itself into the hypervisor.

Worth keeping the three parts straight: KVM is the kernel module providing
acceleration, QEMU is the userspace program emulating the devices, libvirt is the
management layer you type at.

</details>

<details class="qa">
<summary>A new VM can browse the internet and nothing on the LAN can connect to it. What is the likely cause and the fix?</summary>

**NAT networking**, which is the default in most hypervisors.

The guest sits on a private network behind the host and shares the host's
address for outbound traffic. So outbound works (updates install, DNS
resolves, everything looks healthy) and there is no route for anything on the
LAN to reach the guest, because its address does not exist outside the host.

**The fix is bridged networking**, which attaches the guest's virtual interface to
the host's physical one. The guest then gets an address from the same DHCP server
as everything else and behaves like an ordinary machine on the network.

For a single service, port forwarding from the host is a lighter alternative.

Two caveats on bridging: setting up the bridge briefly disconnects the host, so do
it with console access; and many wireless adapters cannot bridge at all, so a
laptop over Wi-Fi will fail for reasons unrelated to your configuration.

</details>

<details class="qa">
<summary>Six 40 GB qcow2 disks on a 100 GB host. What happens, and how do you monitor for it?</summary>

**It works, until the guests actually write.** qcow2 is thin-provisioned: an image
occupies only what has been written, so 240 GB of promised disk fits on 100 GB of
real disk as long as the guests stay mostly empty.

When the host fills, **every guest pauses at once.** They do not receive a
graceful disk-full error; writes simply stop, and recovering means freeing host
space before anything can resume.

Monitor the **host's** free space, not the guests'. Every guest will report plenty
of room, right up to the moment none of them can write, because each one believes
it has 40 GB.

`qemu-img info` shows virtual size against actual size per image. The number worth
alerting on is host free space against the sum of what is still unwritten.

</details>

<details class="qa">
<summary>What is the difference between <code>virsh destroy</code> and <code>virsh undefine</code>?</summary>

**`destroy` stops a running guest immediately**, the equivalent of pulling the
power cord. The guest still exists and can be started again, and it risks
filesystem damage inside it exactly as a real power cut would.

**`undefine` removes the guest's definition** from libvirt. That is the delete,
and `--remove-all-storage` takes the disk images with it.

The naming is genuinely poor and the exam likes asking about it.

`virsh shutdown` is the polite version of `destroy`: it asks the guest to shut
down cleanly. It needs the guest agent installed to work reliably, which is one
more reason `qemu-guest-agent` belongs in every guest.

</details>

## References

**Pictures.** The Cockpit screenshot was taken on a machine of mine rather than
copied from anywhere. Cockpit is free software from the Cockpit project,
published at [cockpit-project.org](https://cockpit-project.org) under
[LGPL v2.1 or later](https://www.gnu.org/licenses/old-licenses/lgpl-2.1.html),
and a screenshot of it carries that licence. The browser chrome is cropped off
and it is resized; nothing else is altered.


- [virsh(1)](https://libvirt.org/manpages/virsh.html) - libvirt project. Accessed 2026-08-07.
- [libvirt networking](https://wiki.libvirt.org/VirtualNetworking.html) - libvirt project. Accessed 2026-08-07.
- [qemu-img](https://www.qemu.org/docs/master/tools/qemu-img.html) - QEMU project. Accessed 2026-08-07.
- [systemd-detect-virt(1)](https://man7.org/linux/man-pages/man1/systemd-detect-virt.1.html) - Linux man-pages project. Accessed 2026-08-07.
- [KVM in the kernel documentation](https://docs.kernel.org/virt/kvm/index.html) - The Linux Kernel documentation. Accessed 2026-08-07.
- [namespaces(7)](https://man7.org/linux/man-pages/man7/namespaces.7.html) - Linux man-pages project. Accessed 2026-08-07.

The `virsh`, `qemu-img`, and `virt-install` commands here are from libvirt's
and QEMU's own documentation rather than captured, because the podman machine
cannot host virtual machines of its own, nested virtualization is exactly what
this topic explains is unavailable. The detection captures are real. Blocks
without a distribution and architecture header are illustrative.
