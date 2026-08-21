---
title: "Configuring networking"
description: "The address is right, the machine works, and after a restart it is gone. Three different systems own network configuration depending on the distribution, and knowing which one is in charge is most of the job."
deck: "Networking that survives a reboot"
track: "linux-plus"
level: "working"
order: 180
objectives:
  - "Say which system owns network configuration on a machine you have just met"
  - "Set an address temporarily and explain why it will not survive"
  - "Configure a static address permanently with nmcli, netplan, and Debian's own files"
  - "Choose between DHCP and static, and say what a reservation buys you"
prerequisites: ["network-basics-addresses-and-routes"]
tags: ["linux", "linux-plus", "networking", "nmcli", "netplan"]
updated: 2026-08-07
draft: false
examObjectives:
  - exam: "xk0-006"
    domain: "1.0"
    objective: "1.4"
sources:
  - title: "nmcli(1)"
    url: "https://manpages.debian.org/stable/network-manager/nmcli.1.en.html"
    publisher: "Debian Project"
    accessed: 2026-08-07
    tier: 1
  - title: "ip-link(8)"
    url: "https://man7.org/linux/man-pages/man8/ip-link.8.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "Netplan YAML configuration reference"
    url: "https://netplan.readthedocs.io/en/stable/netplan-yaml/"
    publisher: "Canonical"
    accessed: 2026-08-07
    tier: 2
  - title: "interfaces(5)"
    url: "https://manpages.debian.org/stable/ifupdown/interfaces.5.en.html"
    publisher: "Debian Project"
    accessed: 2026-08-07
    tier: 1
  - title: "systemd.network(5)"
    url: "https://man7.org/linux/man-pages/man5/systemd.network.5.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "systemd.link(5)"
    url: "https://man7.org/linux/man-pages/man5/systemd.link.5.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
symptoms:
  - symptom: "Network configuration lost after a reboot"
    anchor: "1-the-change-was-lost-at-reboot"
  - symptom: "Edited a config file and nothing changed"
    anchor: "2-you-edited-the-wrong-file"
---

> **Before you read.** Somebody sets a static address on a server. They test it,
> everything works, they close the ticket. The machine reboots six weeks later
> during patching and comes back with a completely different address, or none.
>
> Nothing was deleted. The change was made correctly and it worked.
>
> **Where did it go?**

It was never written anywhere. `ip addr add` changes what the kernel is doing
right now and touches no file, so the next boot starts from whatever the
configuration says, which is what it said before anyone touched it.

That distinction between **the running state** and **the configuration** runs
through this entire lesson. Getting it wrong is the single most common networking
mistake in this exam's scope, and it produces a failure delayed by weeks.

### Some words you will need

<dl class="terms">
<dt>running state</dt>
<dd>What the kernel is doing now. Changed with <code>ip</code>. Gone at reboot.</dd>
<dt>configuration</dt>
<dd>What a file says should happen. Applied at boot by whichever system is in charge.</dd>
<dt>connection profile</dt>
<dd>NetworkManager's unit of configuration: a named set of settings that can be applied to a device.</dd>
<dt>DHCP</dt>
<dd>Ask a server on the network for an address, mask, gateway, and DNS. The default nearly everywhere.</dd>
<dt>DHCP reservation</dt>
<dd>The DHCP server always giving one machine the same address, based on its MAC.</dd>
</dl>

## What breaks without this

**Changes that vanish.** Described above, and the delay between making the change
and discovering it did not persist is what makes it expensive.

You edit a file nothing reads. Three systems can own networking, and each
ignores the others' files. Editing the wrong one produces no error and no
effect.

You lock yourself out. Changing the address of the interface you are connected
over drops your session, and if the change was wrong you have no way back
except console access.

<details class="deeper">
<summary>If you already administer Linux: predictable interface names, and how to find out what a machine will call its NIC</summary>

`eth0` is gone on every current distribution, and the replacement is not arbitrary
even though `enp0s1` and `enx5a94efe40cee` look it.

**The problem it solves is real.** Kernel names were assigned in probe order, which
is a race: two identical cards could swap between boots, and a firewall rule or an
`ifcfg` file naming `eth0` would then apply to the wrong physical port. On a
machine with several NICs that is a security failure, not an inconvenience.

**The scheme encodes physical location**, so the name is a property of the slot
rather than of boot timing:

| Prefix | Means |
| --- | --- |
| `en` | Ethernet |
| `wl` | Wireless LAN |
| `ww` | Wireless WAN |

and the suffix says where it is:

| Form | From |
| --- | --- |
| `o1` | **On**board index from firmware |
| `s1` | Hotplug **s**lot index |
| `p0s1` | **P**CI bus 0, **s**lot 1 |
| `x5a94efe40cee` | The **MAC** address, when nothing else is stable |

So `enp0s1` is ethernet, PCI bus 0, slot 1. Move the card to another slot and
the name changes, which is the point, because the *cable* moved too.

**`udevadm` tells you every name a device could have had**, in the order the policy
tried them:

```
udevadm info /sys/class/net/enp0s1 | grep ID_NET_NAME
udevadm test-builtin net_id /sys/class/net/enp0s1 2>/dev/null
```

`ID_NET_NAME_ONBOARD`, `ID_NET_NAME_SLOT`, `ID_NET_NAME_PATH`, and
`ID_NET_NAME_MAC` are the candidates, and the first one present wins. That is how
you predict a name before the machine has booted with the card in it.

**Turning it off is a supported choice** and occasionally the right one for a
fleet with identical hardware and existing automation: `net.ifnames=0` on the
kernel command line restores `eth0`. Masking
`/etc/systemd/network/99-default.link` does the same more surgically.

**Pinning a name yourself is better than either**, using a `.link` file that
matches on MAC address:

```
# /etc/systemd/network/10-wan.link
[Match]
MACAddress=5a:94:ef:e4:0c:ee

[Link]
Name=wan0
```

That survives slot changes and gives interfaces names that mean something
(`wan0`, `lan0`, `storage0`) which is worth far more on a multi-homed box than
either scheme's defaults.

</details>

## Which system is in charge

<figure class="learn-figure">
<svg viewBox="0 0 720 220" role="img" aria-labelledby="nw-t nw-d" style="width:100%;height:auto;">
<title id="nw-t">Four configuration systems writing to one kernel</title>
<desc id="nw-d">The kernel holds one set of addresses and routes. Several different systems can be the thing that puts them there, and which one a given machine uses depends on the distribution and the image rather than on anything you can infer from the interface. Editing the file belonging to a system that is not running changes nothing, and the change survives exactly as long as nothing else rewrites it. Finding out which one is in charge is therefore the first question, before any file is opened.</desc>
<g>
<rect x="24" y="40" width="150" height="46" rx="4" fill="currentColor" fill-opacity="0.07" stroke="currentColor" stroke-opacity="0.32"/>
<text x="99" y="60" text-anchor="middle" font-size="10.5" fill="currentColor">NetworkManager</text>
<text x="99" y="76" text-anchor="middle" font-size="10" fill="currentColor" fill-opacity="0.65">RHEL, desktops</text>
<rect x="192" y="40" width="150" height="46" rx="4" fill="currentColor" fill-opacity="0.07" stroke="currentColor" stroke-opacity="0.32"/>
<text x="267" y="60" text-anchor="middle" font-size="10.5" fill="currentColor">netplan</text>
<text x="267" y="76" text-anchor="middle" font-size="10" fill="currentColor" fill-opacity="0.65">Ubuntu server</text>
<rect x="360" y="40" width="150" height="46" rx="4" fill="currentColor" fill-opacity="0.07" stroke="currentColor" stroke-opacity="0.32"/>
<text x="435" y="60" text-anchor="middle" font-size="10.5" fill="currentColor">ifupdown</text>
<text x="435" y="76" text-anchor="middle" font-size="10" fill="currentColor" fill-opacity="0.65">Debian, older Ubuntu</text>
<rect x="528" y="40" width="168" height="46" rx="4" fill="currentColor" fill-opacity="0.07" stroke="currentColor" stroke-opacity="0.32"/>
<text x="612" y="60" text-anchor="middle" font-size="10.5" fill="currentColor">systemd-networkd</text>
<text x="612" y="76" text-anchor="middle" font-size="10" fill="currentColor" fill-opacity="0.65">containers, minimal images</text>
<rect x="180" y="140" width="360" height="56" rx="5" fill="var(--accent)" fill-opacity="0.12" stroke="var(--accent)" stroke-opacity="0.9" stroke-width="1.8"/>
<text x="360" y="164" text-anchor="middle" font-size="11.5" fill="var(--accent)">one set of addresses and routes</text>
<text x="360" y="182" text-anchor="middle" font-size="10" fill="var(--accent)">held by the kernel</text>
<text x="24" y="212" font-size="10" fill="currentColor" fill-opacity="0.65">editing the file of a system that is not running changes nothing, silently</text>
</g>
<g stroke="currentColor" stroke-opacity="0.5" fill="none" stroke-width="1.3">
<path d="M99 90 L99 116 L340 116 L340 136 M336 130 L340 137 L344 130"/>
<path d="M267 90 L267 116"/>
<path d="M435 90 L435 116 L380 116 L380 136 M376 130 L380 137 L384 130"/>
<path d="M612 90 L612 116 L420 116"/>
</g>
</svg>
<figcaption>Four front ends, one kernel state, and no way to tell from the outside which one is driving. That is why the first move on an unfamiliar machine is finding out rather than opening a file: editing the config of a system that is not running produces no error, no warning, and no change.</figcaption>
</figure>

This is the first question on any unfamiliar machine, and it decides everything
else.

| System | Configuration lives in | Typically on |
| --- | --- | --- |
| **NetworkManager** | `/etc/NetworkManager/system-connections/` | RHEL family, Fedora, desktops, Ubuntu desktop |
| **netplan** | `/etc/netplan/*.yaml` | Ubuntu server |
| **ifupdown** | `/etc/network/interfaces` | Debian, older Ubuntu |
| **systemd-networkd** | `/etc/systemd/network/*.network` | Containers, minimal images, some cloud |

Find out in one command:

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ command -v nmcli netplan resolvectl dig host nslookup ss; echo "--- NetworkManager? ---"; systemctl is-active NetworkManager systemd-networkd systemd-resolved 2>&1
/usr/bin/nmcli
/usr/bin/resolvectl
/usr/bin/dig
/usr/bin/host
/usr/bin/nslookup
/usr/bin/ss
--- NetworkManager? ---
active
inactive
inactive
```

`nmcli` exists, `netplan` does not, and `systemctl is-active` says NetworkManager
is running while `systemd-networkd` is not. So NetworkManager owns this machine
and its files are the ones that matter.

**Run that check before editing anything.** Two seconds, and it prevents the
entire category of "I edited a file and nothing happened".

**netplan is a special case worth understanding:** it is not a network system at
all. It is a translator that reads YAML and generates configuration for either
NetworkManager or systemd-networkd, which then does the work. So on Ubuntu server
you edit netplan's YAML and `systemd-networkd` is what actually applies it. That
is why `systemctl status systemd-networkd` on Ubuntu shows something running that
you never configured directly.

## Temporary changes, and why they do not last

An interface is created and given an address. No route is added, the command
list contains no `ip route add`.

<details class="predict">
<summary>Only an address was assigned. Will <code>ip route</code> show anything for 10.99.0.0/24, and if so, who created it?</summary>

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ sudo ip link add demo0 type dummy; sudo ip addr add 10.99.0.5/24 dev demo0; sudo ip link set demo0 up; ip addr show demo0; echo "--- and the route it created ---"; ip route | grep 10.99; sudo ip link del demo0
65: demo0: <BROADCAST,NOARP,UP,LOWER_UP> mtu 1500 qdisc noqueue state UNKNOWN group default qlen 1000
    link/ether ce:ef:97:9b:b3:be brd ff:ff:ff:ff:ff:ff
    inet 10.99.0.5/24 scope global demo0
       valid_lft forever preferred_lft forever
    inet6 fe80::ccef:97ff:fe9b:b3be/64 scope link proto kernel_ll 
       valid_lft forever preferred_lft forever
--- and the route it created ---
10.99.0.0/24 dev demo0 proto kernel scope link src 10.99.0.5 
```

</details>

A whole interface created, addressed, and brought up, on a dummy device, so
nothing real was disturbed. Note the route appeared **automatically** the
moment the address was assigned: `proto kernel` again, exactly as in the last
lesson.

| Command | Does |
| --- | --- |
| `ip addr add 10.0.0.5/24 dev eth0` | Add an address |
| `ip addr del 10.0.0.5/24 dev eth0` | Remove it |
| `ip link set eth0 up` / `down` | Enable or disable the interface |
| `ip route add default via 10.0.0.1` | Add a default gateway |

**Every one of these is forgotten at reboot.** No file was written. That is not a
flaw: it makes them ideal for *testing* a theory before committing to it, which is
exactly how the previous lesson's worked example ended.

The workflow worth adopting: **prove it with `ip`, then write it down with the
machine's own configuration system.**

## NetworkManager: nmcli

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ nmcli device status; echo; nmcli connection show
DEVICE  TYPE      STATE                   CONNECTION         
enp0s1  ethernet  connected               Wired connection 1 
lo      loopback  connected (externally)  lo                 

NAME                UUID                                  TYPE      DEVICE 
Wired connection 1  21725c5d-26b2-3063-92eb-636dec679a5e  ethernet  enp0s1 
lo                  c29d0687-8931-44b5-81d5-cada3828b494  loopback  lo     
```

**Devices and connections are different things**, and the distinction is the one
piece of NetworkManager vocabulary that matters.

A **device** is the hardware: `enp0s1`. A **connection** is a named profile of
settings: `Wired connection 1`. A device can have several profiles defined and
one active, which is how a laptop switches between office and home settings on
the same card.

`nmcli device status` answers "what hardware is there and is it connected".
`nmcli connection show` answers "what profiles exist".

Look inside a profile:

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ nmcli -f ipv4.method,ipv4.addresses,ipv4.gateway,ipv4.dns connection show "Wired connection 1" 2>/dev/null || nmcli connection show --active | tail -2
ipv4.method:                            auto
ipv4.addresses:                         --
ipv4.gateway:                           --
ipv4.dns:                               --
```

**`ipv4.method: auto` means DHCP**, and the other three are empty because the DHCP
server supplies them. `manual` would mean static, and then those fields would be
populated.

Switching this profile to a static address is four settings and an apply:

```
sudo nmcli connection modify "Wired connection 1" \
  ipv4.method manual \
  ipv4.addresses 192.168.1.50/24 \
  ipv4.gateway 192.168.1.1 \
  ipv4.dns "1.1.1.1 9.9.9.9"

sudo nmcli connection up "Wired connection 1"
```

**`ipv4.method manual` is the setting people forget.** Set the address without it
and NetworkManager keeps asking DHCP as well, so you end up with two addresses
and behaviour that depends on which the routing table prefers.

**`connection up` is what applies it.** `modify` writes the profile and changes
nothing that is running. Without the second command it works after a reboot and
not before, which is the reverse of the usual mistake and equally confusing.

Useful ones to have:

| Task | Command |
| --- | --- |
| What is this connection set to | `nmcli connection show "name"` |
| Back to DHCP | `nmcli connection modify "name" ipv4.method auto` |
| Add a second address | `nmcli connection modify "name" +ipv4.addresses 10.0.0.5/24` |
| Reload after editing files by hand | `nmcli connection reload` |
| Interactive editor | `nmtui` |

**`nmtui` is worth knowing about for the exam and for a bad day.** It is a
text-mode interface that walks you through the same settings, and it is far
harder to get subtly wrong at 2am than a long `nmcli modify`.


<details class="deeper">
<summary>If you already administer Linux: where NetworkManager keeps profiles, and the keyfile format</summary>

`nmcli` is the interface; the storage underneath is worth knowing because
configuration management has to write it.

**Profiles live in `/etc/NetworkManager/system-connections/` as INI-style
keyfiles**, one per connection, mode `0600` because they can hold wireless
keys and VPN secrets. Recent releases use this format exclusively; the older
`ifcfg-` files under `/etc/sysconfig/network-scripts/` are read for
compatibility on some releases and written by nothing. That transition is the
source of a current and genuinely common confusion, editing an `ifcfg-` file,
seeing no effect, and concluding NetworkManager is broken.

A minimal keyfile is short enough to write by hand:

```ini
[connection]
id=static-mgmt
type=ethernet
interface-name=enp0s1
autoconnect=true
autoconnect-priority=100

[ipv4]
method=manual
address1=192.168.1.50/24,192.168.1.1
dns=1.1.1.1;9.9.9.9;
```

**`nmcli connection reload` after writing one**, because NetworkManager does not
watch the directory. Then `nmcli connection up static-mgmt`.

**`autoconnect-priority` is the field that decides boot behaviour** when more
than one profile could claim a device, and leaving it unset is how a machine
comes back on the wrong address after a reboot. Higher wins; the default is 0.

`nmcli connection export` for a VPN and `nmcli --offline` for generating a
keyfile without touching the running system are both worth knowing for
templating.

</details>

## netplan: Ubuntu server

netplan is YAML in `/etc/netplan/`, and YAML means indentation is syntax:

```yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    enp0s1:
      dhcp4: false
      addresses:
        - 192.168.1.50/24
      routes:
        - to: default
          via: 192.168.1.1
      nameservers:
        addresses: [1.1.1.1, 9.9.9.9]
```

Then:

```
sudo netplan try      # applies it, and rolls back after 120s unless confirmed
sudo netplan apply    # applies it permanently
```

**`netplan try` is the best safety feature in any of these systems.** It applies
the configuration and, unless you press Enter to confirm, reverts after two
minutes. Which means a mistake that would have locked you out of a remote machine
undoes itself while you are still watching. Use it every time.

Two details that catch people:

- **`gateway4:` is deprecated** in favour of the `routes:` block shown above. Older
  documentation uses it, newer netplan warns about it, and eventually it goes.
- **Files are applied in lexical order** and later ones override earlier. A cloud
  image ships `50-cloud-init.yaml`, so a file named `99-mine.yaml` wins and one
  named `10-mine.yaml` does not.

The Ubuntu container image used for these captures has no netplan in it at all:

```bash
# Ubuntu 24.04 LTS, x86_64
$ command -v netplan; ls /etc/netplan/ 2>&1; cat /etc/os-release | head -2
ls: cannot access '/etc/netplan/': No such file or directory
PRETTY_NAME="Ubuntu 24.04.4 LTS"
NAME="Ubuntu"
```

Which is worth showing rather than hiding: **container images are not servers.**
A container gets its network from the container runtime, so nothing that
configures networking is installed. The netplan examples above come from
Canonical's documentation rather than from a capture, and the reference is in the
sources.

## Debian: /etc/network/interfaces

Debian without netplan uses the older ifupdown system:

```
auto enp0s1
iface enp0s1 inet static
    address 192.168.1.50/24
    gateway 192.168.1.1
    dns-nameservers 1.1.1.1 9.9.9.9
```

`auto` means bring it up at boot. `inet static` means IPv4, statically
configured; `inet dhcp` is the alternative and needs none of the other lines.

```
sudo ifdown enp0s1 && sudo ifup enp0s1
```

**Never run `ifdown` on the interface you are connected over** unless you have
console access. The `&&` will not save you: `ifdown` succeeds, your session
dies, and `ifup` never runs. Use `systemctl restart networking`, or better,
test the change with `ip` first.

## DHCP or static

| | DHCP | Static |
| --- | --- | --- |
| Set up | Nothing | Four settings |
| Changing the network later | Automatic | Visit every machine |
| Address is predictable | Only with a reservation | Yes |
| Fails if the DHCP server is down | Yes | No |
| Right for | Clients, workstations, most cloud instances | Servers, gateways, anything referenced by address |

**DHCP reservations are the answer most people should reach for.** The client uses
DHCP, and the DHCP server is told to always give that MAC address the same IP.
You get a predictable address *and* central control, so a network renumbering is
one change in one place instead of a visit to forty machines.

Static configuration on the host is right when the machine must work even when
the DHCP server does not, which includes, notably, the DHCP server.

<details class="predict">
<summary>You SSH into a server, run <code>nmcli connection modify</code> to set a static address different from its current one, then run <code>nmcli connection up</code>. What happens to your session?</summary>

**It dies immediately**, and you do not get an error message, because the
mechanism carrying the error is the thing that just went away.

`connection up` tears the interface down and brings it back with the new
settings. Your SSH session is a TCP connection to the *old* address; that address
no longer exists on the machine, so the connection is broken and the terminal
hangs, then times out.

If the new configuration is correct, you reconnect to the new address and all
is well. If it is wrong (a typo in the address, a mask that does not match the
network, a gateway on a different subnet) **the machine is now unreachable**
and you need console access to fix it.

Three ways to avoid finding out the hard way:

**Test with `ip` first.** Add the address temporarily and confirm you can reach
the machine on it from elsewhere before writing anything down. Nothing is
persisted, so a reboot undoes any mistake.

Use the tools that roll back. `netplan try` reverts after 120 seconds unless
confirmed. NetworkManager has no direct equivalent, which is a real gap.

Schedule your own escape. `echo 'nmcli connection up "old-profile"' | at now +
5 minutes` before you start, and cancel it once you have reconnected. Crude,
effective, and it has saved a great many long drives to data centres.

</details>

<details class="deeper">
<summary>If you already administer Linux: bonding, VLANs, systemd-networkd, and predictable names</summary>

**Bonding and teaming** combine interfaces for redundancy or throughput.
`nmcli connection add type bond ifname bond0 bond.options "mode=802.3ad,miimon=100"`,
then add each interface as a slave. Mode `active-backup` needs nothing from the
switch and gives you failover; `802.3ad` (LACP) gives you both and requires the
switch to be configured to match. Teaming was Red Hat's alternative and is now
deprecated in favour of bonding, so bonding is the answer for both the exam and
real work.

**VLANs** are `nmcli connection add type vlan dev enp0s1 id 100`, producing
`enp0s1.100`. The switch port has to be a trunk carrying that tag or nothing
arrives, and "the VLAN is configured on the host and the port is an access port"
is one of the more common ways to spend an afternoon.

**systemd-networkd** is the minimal option: `.network` files in
`/etc/systemd/network/`, no daemon beyond systemd, no DBus. It is what containers
and cloud images use and what netplan generates when `renderer: networkd`. Worth
being able to read even if you never choose it, because you will meet its files
on Ubuntu servers.

**Predictable interface names** come from `systemd-udevd` using firmware and
topology: `enp0s1` is ethernet, PCI bus 0, slot 1. The scheme is documented in
`systemd.net-naming-scheme(7)`, and it exists because `eth0` and `eth1` could
swap at boot depending on driver initialisation order, which quietly moved a
firewall's inside and outside interfaces. You can go back to `eth0` with
`net.ifnames=0` on the kernel command line, and you should not.

**MAC addresses** can be set with `ip link set dev enp0s1 address 00:11:22:33:44:55`
or `nmcli`'s `cloned-mac-address`. Legitimate uses: replacing a failed appliance
whose licence is MAC-bound, or matching a DHCP reservation without touching the
server. It is also how MAC-based access control is bypassed, which is worth
knowing when someone proposes MAC filtering as a security measure.

`nmcli device connect` versus `connection up`. The first tells NetworkManager
to manage a device it had left alone; the second activates a specific profile.
`nmcli device set enp0s1 managed no` hands an interface to something else,
which is how NetworkManager and another system coexist on one machine, and how
they fight, when nobody remembers doing it.

</details>

## Across distributions

| | RHEL family | Ubuntu server | Debian |
| --- | --- | --- | --- |
| Owns the config | NetworkManager | netplan, via systemd-networkd | ifupdown |
| Files | `/etc/NetworkManager/system-connections/` | `/etc/netplan/*.yaml` | `/etc/network/interfaces` |
| Apply | `nmcli connection up` | `netplan apply` | `systemctl restart networking` |
| Safe-apply option | none | `netplan try` | none |
| Interactive tool | `nmtui` | none | none |

**RHEL 9 and later dropped `/etc/sysconfig/network-scripts/`** as the source of
truth. Those `ifcfg-` files are still read for compatibility on some releases and
are not where NetworkManager writes any more, so editing one and finding it
ignored is a real and current confusion. `nmcli` is the answer on that family.


<details class="deeper">
<summary>If you already administer Linux: cloud images, cloud-init, and configuration that regenerates itself</summary>

On a cloud instance there is usually a **fourth** system with an opinion, and it
outranks the three above.

**cloud-init writes network configuration at first boot** from metadata the
platform supplies, generating either a netplan file (`/etc/netplan/50-cloud-init.yaml`)
or NetworkManager profiles. Edit the generated file and the next boot may
regenerate it, depending on how the image was built. The header of the file says
so, and it is worth reading before assuming an edit will hold.

To stop it, drop a file at
`/etc/cloud/cloud.cfg.d/99-disable-network-config.cfg` containing `network:
{config: disabled}`, and only then configure the machine normally. Do that
*before* making the change you want to keep, not after discovering it
reverted.

**Netplan applies files in lexical order, later winning.** So a cloud image
shipping `50-cloud-init.yaml` is overridden by `99-mine.yaml` and not by
`10-mine.yaml`. That numbering convention is doing real work and it is easy to
get backwards.

**The metadata service is at `169.254.169.254`** on every major platform, and it
is worth knowing for two reasons: it is how the instance learned its own
configuration, and a machine that cannot reach it will have booted with defaults
nobody chose. `curl -s http://169.254.169.254/latest/meta-data/` on AWS-style
platforms is the quick check.

And the general principle, since this is the third system in one lesson that
rewrites your files: **find out what owns the configuration before editing it.**
`ls -la` on the file and reading its first three lines answers it nearly every
time, because generators say so.

</details>

## Prove it

After any change, in this order:

```bash
# Is it live now
ip -brief addr
ip route | grep default

# Does the configuration agree with reality
nmcli connection show "name" | grep ipv4        # RHEL family
sudo netplan get                                 # Ubuntu
cat /etc/network/interfaces                      # Debian

# Does it still work end to end
ping -c 2 <gateway>
ping -c 2 1.1.1.1
```

And the only test that really counts: **reboot the machine.** Everything above can
pass on a machine whose configuration is wrong, because you are looking at the
running state. If a reboot is genuinely impossible, `systemctl restart
NetworkManager` (or `networking`) is the nearest approximation and it is not the
same thing.

## What trips people up

### 1. The change was lost at reboot

`ip addr add` and `ip route add` modify the running kernel and write nothing.

Use them to test, then commit the change with `nmcli`, netplan, or
`/etc/network/interfaces`. The whole lesson, really.

### 2. You edited the wrong file

Three systems, three sets of files, and each ignores the others'. Editing
`/etc/network/interfaces` on a RHEL machine does nothing at all, and there is no
error to tell you.

`systemctl is-active NetworkManager systemd-networkd` first, every time.

### 3. Setting an address without setting the method

`nmcli connection modify ... ipv4.addresses 192.168.1.50/24` without
`ipv4.method manual` leaves the profile on DHCP. You get the static address *and*
a DHCP one, and which is used depends on route metrics.

Set the method. `nmcli connection show "name" | grep ipv4.method` confirms it.

### 4. Locking yourself out

Covered in the prediction. Test with `ip` first, use `netplan try` where you have
it, and arrange a scheduled rollback for anything remote and risky.

### 5. Two systems both managing one interface

NetworkManager and systemd-networkd both running and both interested in the same
device produces flapping: an address that appears, disappears, and changes.

Pick one. `nmcli device set enp0s1 managed no` hands the interface over, or
disable the service you are not using.

## Work it through

A monitoring server has a static address configured through NetworkManager. It
was patched and rebooted overnight. This morning it is reachable, but at a
different address, and half the systems that report to it have stopped.

`nmcli connection show` lists two profiles for the same device: `Wired connection
1` and `monitoring-static`.

Reason it out before reading on.

**Two profiles, one device.** That is legal and it is the whole story. A device can
have many profiles defined; exactly one is active at a time.

Which one is active? `nmcli device status` shows the `CONNECTION` column, the
profile currently applied. If it says `Wired connection 1`, the machine came
up on the auto-generated DHCP profile and the static one was never activated.

Why would the wrong one win? NetworkManager activates a profile at boot based
on `connection.autoconnect` and, when several are eligible,
`connection.autoconnect-priority`. The default profile is created
automatically with autoconnect on. If `monitoring-static` was created and
brought up manually but never had autoconnect set, it works until the next
boot and then loses to the one that does.

**Confirm it:**

```
nmcli -f connection.autoconnect,connection.autoconnect-priority connection show monitoring-static
nmcli -f connection.autoconnect,connection.autoconnect-priority connection show "Wired connection 1"
```

An `autoconnect: no` on the static profile is the finding.

**The fix:**

```
sudo nmcli connection modify monitoring-static connection.autoconnect yes
sudo nmcli connection modify monitoring-static connection.autoconnect-priority 100
sudo nmcli connection delete "Wired connection 1"
sudo nmcli connection up monitoring-static
```

Deleting the competing profile is the part worth doing. Leaving two profiles that
could both claim the device is leaving the same problem in place with a different
priority number in front of it.

**Why did it work for weeks?** Because `nmcli connection up` had been run by hand,
and nothing since had restarted networking. The configuration and the running
state disagreed for the entire time, and only a reboot could reveal it.

**The habit worth taking:** after any network change intended to be permanent,
**reboot the machine while you are still there.** Not restart the service,
reboot. It is the only test that exercises what actually happens at boot, and
the alternative is finding out during a patch window when you are asleep.

## Try it

Optional, on a virtual machine you can reach by console if you break it. Do not
practise this over SSH on anything you care about.

1. `systemctl is-active NetworkManager systemd-networkd` and `ls /etc/netplan`.
   Say which system owns the machine.
2. `nmcli device status` and `nmcli connection show`, and name the difference
   between the two lists.
3. `sudo ip link add demo0 type dummy`, give it an address, check `ip route`, then
   `sudo ip link del demo0`. Nothing real was touched.
4. `nmcli connection show "<your connection>" | grep ipv4` and read the method.
5. On Ubuntu: `sudo netplan get`, then `sudo netplan try` with no changes, and
   watch the countdown.
6. Change something harmless, reboot, and confirm it survived.

**Verification step.** You have it when you can set a static address on an
unfamiliar machine, using the right tool for that machine, and be confident it
will still be there next month.

## Check yourself

<details class="qa">
<summary>Why does <code>ip addr add 192.168.1.50/24 dev eth0</code> stop working after a reboot?</summary>

**Because it changes the running kernel state and writes nothing to disk.** The
address exists until the interface goes down or the machine restarts.

At boot, whichever system owns networking reads its own configuration files and
applies those. Nothing in them mentions the address you added, so it does not
come back.

That is not a limitation to work around. It is what makes `ip` the right tool
for *testing*. Prove the address and route are correct while nothing is
persisted, then commit the change with `nmcli`, netplan, or
`/etc/network/interfaces`.

</details>

<details class="qa">
<summary>What is the difference between a device and a connection in NetworkManager?</summary>

A **device** is the hardware: `enp0s1`, a physical or virtual interface.

A **connection** is a named profile of settings (address, method, gateway,
DNS) that can be applied to a device.

The relationship is many-to-one: a device can have several profiles defined and
exactly one active. That is how a laptop keeps separate office and home settings
for the same card, and it is also how a server ends up coming back on the wrong
address after a reboot, because a second profile with autoconnect enabled won the
race.

`nmcli device status` lists devices and which profile is active on each. `nmcli
connection show` lists profiles.

</details>

<details class="qa">
<summary>You set <code>ipv4.addresses</code> on a NetworkManager profile but not <code>ipv4.method</code>. What happens?</summary>

**The profile stays on DHCP**, so the interface gets the static address *and*
requests one from the DHCP server. Two addresses on one interface, and which is
used for outgoing traffic depends on route metrics.

It usually appears to work, which is what makes it a problem: the machine
responds on the address you set, so the change looks successful, and the second
address causes trouble later in ways that are hard to attribute.

`ipv4.method manual` is the missing setting. Confirm with `nmcli connection show
"name" | grep ipv4.method`, which should read `manual` and not `auto`.

</details>

<details class="qa">
<summary>What does <code>netplan try</code> do that <code>netplan apply</code> does not, and why does it matter?</summary>

**It rolls back automatically.** `try` applies the configuration and starts a
120-second timer; unless you press Enter to confirm, it reverts to the previous
configuration.

It matters because network changes can remove the very connection you are
making them over. A wrong address, mask, or gateway on a remote machine means
no way back except console access, which for a machine in a data centre may be
a drive or a support ticket.

With `try`, a mistake undoes itself while you are still sitting there.

NetworkManager has no equivalent, which is a genuine gap. The nearest thing is
to schedule your own rollback, `echo 'nmcli connection up old-profile' | at
now + 5 minutes`, and cancel it once you have reconnected.

</details>

<details class="qa">
<summary>A machine needs a predictable address and the network may be renumbered next year. DHCP or static, and why?</summary>

**DHCP with a reservation.** The client is configured for DHCP, and the DHCP
server is told to always give that MAC address the same IP.

You get the predictability of a static address, because the machine always
receives the same one. You also keep central control: renumbering the network is
a change on the DHCP server rather than a visit to every host.

Pure static on the host gets you predictability and loses the central control,
so a renumbering means touching every machine, and missing one.

The exception is any machine that must work when DHCP does not: the DHCP server
itself, the gateway, and generally anything that has to come up first. Those are
statically configured, and they are a small list.

</details>

## References

- [nmcli(1)](https://manpages.debian.org/stable/network-manager/nmcli.1.en.html) - Debian Project. Accessed 2026-08-07.
- [ip-link(8)](https://man7.org/linux/man-pages/man8/ip-link.8.html) - Linux man-pages project. Accessed 2026-08-07.
- [Netplan YAML configuration reference](https://netplan.readthedocs.io/en/stable/netplan-yaml/) - Canonical. Accessed 2026-08-07.
- [interfaces(5)](https://manpages.debian.org/stable/ifupdown/interfaces.5.en.html) - Debian Project. Accessed 2026-08-07.
- [systemd.network(5)](https://man7.org/linux/man-pages/man5/systemd.network.5.html) - Linux man-pages project. Accessed 2026-08-07.
- [systemd.link(5)](https://man7.org/linux/man-pages/man5/systemd.link.5.html) - Linux man-pages project. Accessed 2026-08-07.

Command output was captured on the podman machine and on the pinned container
images. The netplan configuration is from Canonical's reference, because a
container has no network configuration system in it to capture from. Blocks
without a distribution and architecture header are illustrative.
