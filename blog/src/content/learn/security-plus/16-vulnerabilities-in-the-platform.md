---
title: "Vulnerabilities in the platform"
description: "What a guest actually shares with its neighbours, why resource reuse is a confidentiality problem rather than a performance one, what a kernel's own hardware vulnerability register says, and the one boundary a tenant controls."
deck: "The virtual machine is isolated. It shares a level two cache with every other processor it can see"
track: "security-plus"
level: "working"
order: 170
objectives:
  - "Name the layers of a virtualised platform and say who controls each"
  - "Say what a virtual machine escape crosses and why it matters more than a guest compromise"
  - "Explain resource reuse as a confidentiality problem"
  - "Read a kernel's hardware vulnerability register and say what it reports"
  - "Say what end of life does to a risk register overnight"
  - "Describe mobile platform vulnerabilities and what side loading changes"
prerequisites: ["vulnerabilities-in-software"]
tags: ["security-plus", "security", "threats", "vulnerabilities"]
updated: 2026-08-26
draft: false
examObjectives:
  - exam: "sy0-701"
    domain: "2.0"
    objective: "2.3"
sources:
  - title: "SP 800-125A Rev. 1, Security Recommendations for Server-based Hypervisor Platforms"
    url: "https://csrc.nist.gov/pubs/sp/800/125/a/rev-1/final"
    publisher: "NIST"
    accessed: 2026-08-26
    tier: 1
  - title: "SP 800-190, Application Container Security Guide"
    url: "https://csrc.nist.gov/pubs/sp/800/190/final"
    publisher: "NIST"
    accessed: 2026-08-26
    tier: 1
  - title: "Kernel documentation, hardware vulnerabilities"
    url: "https://docs.kernel.org/admin-guide/hw-vuln/index.html"
    publisher: "Linux kernel project"
    accessed: 2026-08-26
    tier: 1
  - title: "SP 800-124 Rev. 2, Managing the Security of Mobile Devices"
    url: "https://csrc.nist.gov/pubs/sp/800/124/r2/final"
    publisher: "NIST"
    accessed: 2026-08-26
    tier: 1
symptoms:
  - symptom: "A tenant asks what their virtual machine shares with anybody else's"
    anchor: "what-a-guest-actually-shares"
  - symptom: "A system becomes a risk register entry on a date nobody chose"
    anchor: "end-of-life-changes-the-register-overnight"
---

> **Before you read.** A virtual machine is described as isolated. It has its own
> kernel, its own filesystem, its own network interface, and no visibility of any
> other guest.
>
> **What does it share?**

More than the description implies, and the sharing is below the level anything in
the guest can see. This topic is about the layers underneath the operating system,
which is where the vulnerability classes in this objective live and where none of
your controls reach.

### Some words you will need

<dl class="terms">
<dt>hypervisor</dt>
<dd>The layer that presents virtual hardware to guests and keeps them apart.</dd>
<dt>virtual machine escape</dt>
<dd>Getting from inside a guest to the hypervisor or to another guest.</dd>
<dt>resource reuse</dt>
<dd>Memory, storage or another resource handed to somebody else without being cleared.</dd>
<dt>side channel</dt>
<dd>Learning something from a shared component's behaviour rather than from its contents.</dd>
<dt>firmware</dt>
<dd>Software on a device, below the operating system, updated rarely and inventoried less.</dd>
<dt>microcode</dt>
<dd>The processor's own updatable layer. Where several hardware mitigations actually live.</dd>
<dt>end of life</dt>
<dd>The date after which a vendor issues no further fixes.</dd>
<dt>side loading</dt>
<dd>Installing an application outside the platform's own distribution channel.</dd>
<dt>jailbreaking</dt>
<dd>Removing the platform's restrictions on what may run, including its own protections.</dd>
</dl>

## What breaks without this

**Isolation is assumed rather than described.** The guest cannot see its
neighbours, which is taken to mean it shares nothing with them.

**A hardware advisory arrives and nobody can act on it.** The fix is microcode or
a hypervisor change, both belonging to somebody else, and the guest owner has no
lever.

**Deleted storage is treated as gone.** The volume was released back to a pool,
and what happened next is the provider's design decision rather than yours.

**End of life is treated as a scheduling problem.** It is a date, it passes, the
system carries on working, and the risk register entry does not change.

## What a guest actually shares

<figure class="learn-figure">
<svg viewBox="0 0 720 306" role="img" aria-labelledby="plat-title" style="width:100%;height:auto;">
<title id="plat-title">Five layers of a virtualised platform with who controls each, and the boundary that each class of platform vulnerability crosses</title>
<g fill="currentColor">
<text x="14" y="20" font-size="11">five layers, and you are responsible for two of them</text>
<text x="14" y="44" font-size="9" fill-opacity="0.7">layer</text>
<text x="330" y="44" font-size="9" fill-opacity="0.7">controlled by</text>
<text x="474" y="44" font-size="9" fill-opacity="0.7">what crosses here</text>
<rect x="14" y="54" width="300" height="30" rx="4" fill="var(--accent)" fill-opacity="0.14" stroke="var(--accent)" stroke-opacity="0.7" stroke-width="1.3"/>
<text x="26" y="73" font-size="8.5">your application</text>
<text x="330" y="73" font-size="8" fill-opacity="0.8">yours</text>
<rect x="14" y="92" width="300" height="30" rx="4" fill="var(--accent)" fill-opacity="0.14" stroke="var(--accent)" stroke-opacity="0.7" stroke-width="1.3"/>
<text x="26" y="111" font-size="8.5">your guest operating system</text>
<text x="330" y="111" font-size="8" fill-opacity="0.8">yours</text>
<rect x="14" y="130" width="300" height="30" rx="4" fill="var(--red)" fill-opacity="0.09" stroke="var(--red)" stroke-opacity="0.7" stroke-width="1.3"/>
<text x="26" y="149" font-size="8.5">the hypervisor</text>
<text x="330" y="149" font-size="8" fill-opacity="0.8">the provider</text>
<rect x="14" y="168" width="300" height="30" rx="4" fill="var(--red)" fill-opacity="0.09" stroke="var(--red)" stroke-opacity="0.7" stroke-width="1.3"/>
<text x="26" y="187" font-size="8.5">firmware and microcode</text>
<text x="330" y="187" font-size="8" fill-opacity="0.8">the vendor</text>
<rect x="14" y="206" width="300" height="30" rx="4" fill="var(--red)" fill-opacity="0.09" stroke="var(--red)" stroke-opacity="0.7" stroke-width="1.3"/>
<text x="26" y="225" font-size="8.5">the silicon: caches, buffers, predictors</text>
<text x="330" y="225" font-size="8" fill-opacity="0.8">nobody, once made</text>
<rect x="466" y="94" width="238" height="26" rx="3" fill="var(--red)" fill-opacity="0.10" stroke="var(--red)" stroke-opacity="0.55" stroke-width="1.1" stroke-dasharray="4 3"/>
<text x="478" y="111" font-size="8" fill-opacity="0.9">a virtual machine escape</text>
<rect x="466" y="132" width="238" height="26" rx="3" fill="var(--red)" fill-opacity="0.10" stroke="var(--red)" stroke-opacity="0.55" stroke-width="1.1" stroke-dasharray="4 3"/>
<text x="478" y="149" font-size="8" fill-opacity="0.9">resource reuse between tenants</text>
<rect x="466" y="208" width="238" height="26" rx="3" fill="var(--red)" fill-opacity="0.10" stroke="var(--red)" stroke-opacity="0.55" stroke-width="1.1" stroke-dasharray="4 3"/>
<text x="478" y="225" font-size="8" fill-opacity="0.9">a hardware side channel</text>
<text x="14" y="272" font-size="10" fill-opacity="0.85">the tenant controls the top two boxes and every class below them is somebody else s</text>
<text x="14" y="292" font-size="9" fill-opacity="0.7">so the useful question is not how to fix them but what you would see if one were used</text>
</g></svg>
<figcaption>The layers under a guest, and who controls each. The accented pair at the top is what a tenant is responsible for and can change. Everything below is somebody else's, and the three dashed lines mark where each class in this objective crosses: an escape breaks out of the guest into the layer that was supposed to contain it, resource reuse passes something from one tenant to another through the layer that allocates it, and a hardware side channel does not cross a software boundary at all, because the component being observed is below every boundary the software model contains.</figcaption>
</figure>

Here is the sharing, on a real guest.

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ echo "how many processors this machine thinks it has:"; nproc; echo; echo "and which of them share each cache level:"; for c in /sys/devices/system/cpu/cpu0/cache/index*; do printf "  %s level %s, %s, shared with cpus: %s\n" "$(cat $c/type)" "$(cat $c/level)" "$(cat $c/size)" "$(cat $c/shared_cpu_list)"; done 2>/dev/null; echo; echo "what the hypervisor is:"; systemd-detect-virt 2>/dev/null; cat /sys/class/dmi/id/product_name 2>/dev/null || echo "(no dmi on this platform)"
how many processors this machine thinks it has:
5

and which of them share each cache level:
  Data level 1, , shared with cpus: 0
  Instruction level 1, , shared with cpus: 0
  Unified level 2, , shared with cpus: 0-4

what the hypervisor is:
apple
Apple Virtualization Generic Platform
```

**Five processors, and every one of them shares a level two cache.** The level one
caches are private, listed as shared with a single processor. The unified level two
is `0-4`, which is all of them.

That is what a guest shares before you consider other tenants: the cores it was
given are not independent. Extend the same picture upward and the host's physical
cores are shared between guests, which is the arrangement the whole economics of
virtualisation rests on.

**A shared cache is not a vulnerability by itself.** It is a performance
optimisation with an observable property: what one user of the cache does affects
how long the next one waits. That is the mechanism behind an entire family of
attacks, and it is why the useful question about isolation is not what the guest
can see but what the hardware underneath it shares.

The last two lines are worth noticing too. The guest can name its own hypervisor,
which is useful for an inventory and is also the first thing anything running
inside would check.

<details class="deeper">
<summary>If you buy capacity: what dedicated hardware actually buys, and when it is worth it</summary>

Every major provider sells some form of dedicated capacity, at a premium, and the
question of whether it is worth paying has a more precise answer than the
marketing suggests.

What it removes is co-tenancy on the physical machine. Nobody else's guest runs on
your cores, so the entire class of attacks that depends on a shared cache, a
shared branch predictor or a shared memory bus has no other tenant to observe. That
is a real removal of a real class rather than a mitigation of it.

What it does not remove is everything below. The hypervisor is still the
provider's, the firmware is still the vendor's, and an escape from your own guest
to the hypervisor is unaffected by whether anybody else is on the box. If your
concern is a compromised guest of your own reaching the layer beneath, dedicated
hardware buys nothing.

So the decision turns on which threat you are actually worried about. Multi-tenant
side channels are the case where dedication is the answer, and they are also the
case with the fewest documented real-world incidents relative to the attention they
receive, because they are difficult, noisy and slow compared with the alternatives
available to an attacker.

The honest ordering for most organisations: the money buys more risk reduction spent
on the account compromise, the misconfigured storage and the unpatched guest, all
of which have overwhelming base rates, than on removing a neighbour. The case
changes where a regulator requires it, where the data would justify a sustained
targeted effort, or where the organisation is itself a provider.

Worth knowing rather than assuming: several providers also offer memory encryption
at the hypervisor boundary, which addresses a different part of the same worry and
costs less than dedication.

</details>

## The register the kernel keeps

The operating system maintains a list of the hardware vulnerabilities it knows
about and what it has done about each, which is an unusually direct source.

<details class="predict">
<summary>A running kernel is asked which hardware vulnerabilities affect it. Predict how many entries there are and whether any says it is exposed.</summary>

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ echo "hardware vulnerabilities this kernel knows about, and what it is doing about each:"; for f in /sys/devices/system/cpu/vulnerabilities/*; do printf "  %-22s %s\n" "$(basename $f)" "$(cut -c1-58 < $f)"; done
hardware vulnerabilities this kernel knows about, and what it is doing about each:
  gather_data_sampling   Not affected
  ghostwrite             Not affected
  indirect_target_selection Not affected
  itlb_multihit          Not affected
  l1tf                   Not affected
  mds                    Not affected
  meltdown               Not affected
  mmio_stale_data        Not affected
  old_microcode          Not affected
  reg_file_data_sampling Not affected
  retbleed               Not affected
  spec_rstack_overflow   Not affected
  spec_store_bypass      Vulnerable
  spectre_v1             Mitigation: __user pointer sanitization
  spectre_v2             Mitigation: CSV2, but not BHB
  srbds                  Not affected
  tsa                    Not affected
  tsx_async_abort        Not affected
  vmscape                Not affected
```

**Nineteen entries, and one of them says `Vulnerable`.**

The list itself is worth reading slowly. These are not software defects: they are
properties of processors, discovered after the silicon shipped, and each one
required a mitigation in the kernel, the microcode, or both. The reason there is a
file per entry is that the situation has been common enough to need a directory.

Three kinds of answer appear. `Not affected` means this processor does not have the
flaw, which for most entries here is because it is a different architecture from
the one the vulnerability was found in. `Mitigation:` names what the kernel is
doing, and the two present are worth reading: one sanitises user pointers, and the
other reports `CSV2, but not BHB`, which is a partial mitigation stating precisely
which part of the problem is covered and which is not.

And `Vulnerable` means what it says. The kernel knows about the flaw, has no
mitigation applied for it here, and reports that plainly. On a real estate that is
a finding you can act on, and the actions are a kernel option, a microcode update,
or accepting it.

The reason to show a machine rather than a table is that the answer is
machine-specific. Two servers of different generations, or a virtual machine
against a physical one, produce different lists, and the only way to know what
yours says is to ask it.

</details>

<details class="deeper">
<summary>If you own the microcode question: where these mitigations actually live, and why nobody has an inventory</summary>

A hardware vulnerability mitigation lives in one of three places and knowing which
determines who can act.

**In the kernel**, as a software workaround that avoids the flawed behaviour. These
arrive with an operating system update and are therefore inside your normal
patching, which is the comfortable case.

**In microcode**, which is the processor's own updatable layer. These arrive either
in a system firmware update from the machine vendor, or as a microcode package the
operating system loads at boot. Both are slower than a kernel patch and both
depend on a vendor still supporting that hardware generation, which is where an
older estate runs out of options entirely.

**In neither**, where the only answer is to disable the feature that permits the
flaw. Turning off simultaneous multithreading is the well-known example, and it
costs a substantial fraction of the machine's throughput, which is why it is
argued about.

Nobody has a firmware inventory, and the reason is structural rather than lazy.
Firmware versions are not in the package database, they differ per component
within one machine, and reading them frequently requires vendor tooling. So an
estate's firmware position is usually unknown, and the practical consequence is
that a firmware advisory cannot be scoped: nobody can say how many machines are
affected without going and looking.

The cheap first step, for anybody in this position, is not a project. It is to add
firmware and microcode versions to whatever the configuration management tool
already collects, so that the next advisory is a query rather than a survey. That
is an afternoon and it converts a recurring problem into a lookup.

</details>
<details class="predict">
<summary>A guest is compromised and an attacker has root inside it. Predict what changes if they then escape to the hypervisor.</summary>

**Everything about the blast radius, and nothing about their capability inside your
guest.**

Root in the guest is already complete authority over that machine: every file, every
process, every credential it holds, and every network path it has. Escalating
further gains nothing there, which is worth stating because it explains why an
escape is not the attacker's usual next move.

What an escape changes is the population. From the hypervisor, the reachable set is
every guest on that host, including guests belonging to organisations with no
relationship to yours. That is the reason this class attracts the attention it
does, and it is also why it is rare: hypervisor interfaces are small, heavily
scrutinised, and the exploits that exist are valuable enough to be used sparingly
rather than broadly.

Two practical consequences for a tenant.

The first is that an escape is not something you detect from inside, because the
compromised layer is beneath your visibility. Anything you would notice happens
before it, in the guest, which is the ordinary intrusion detection problem and the
place your effort belongs.

The second is what to ask a provider. Not whether their hypervisor has ever had a
vulnerability, which every hypervisor has, but how quickly they patch one and
whether the patch requires your guest to move. The second half is the part that
shows up in your change calendar, and it is the part nobody asks about until it
happens.

</details>


## Resource reuse is a confidentiality problem

Resource reuse sounds like a capacity concept and it belongs in this objective for
a different reason.

**When a guest is destroyed, its memory and storage are returned to a pool.** The
next tenant to request capacity may be handed the same physical pages or the same
blocks. If nothing cleared them in between, the second tenant receives whatever the
first left.

That is the whole mechanism, and it applies to memory, to block storage, to
allocated buffers inside a shared service, and in a different form to identifiers
and addresses that get reassigned.

**Every serious platform clears on allocation**, which is the correct design: rather
than trusting the releasing party to wipe, the platform zeroes before handing on.
That is worth knowing because it tells you what to ask a provider, and the question
is specific: is memory zeroed on allocation or on release, and what about storage.

**The tenant-side version is the same idea.** Storage attached to a machine you
built, released back to the provider, holds what you wrote unless you did something
about it, and the answer is the sanitisation material from block E: encrypt from
first use so that releasing the volume without the key discloses nothing.

That last sentence is the practical outcome of this whole topic. You cannot audit
the provider's clearing behaviour and you can make it irrelevant, and that is
usually the right engineering response to a control somebody else operates.

## End of life changes the register overnight

Firmware, hardware and legacy systems appear in this objective together, and end of
life is what connects them.

**On the day support ends, nothing about the system changes** and its risk
acquires a slope, which is the argument topic 13 made about software. What is
different here is the second-order effect, which people miss.

**A hardware generation that goes out of support takes its microcode with it.** So
the next hardware vulnerability published affects that machine permanently, and
unlike an unsupported application it cannot be isolated behind something else,
because the flaw is in the thing doing the computing.

**And the replacement is capital rather than effort.** Unsupported software can be
rewritten, contained or replaced by a team. Unsupported hardware is a purchase,
which puts it on a different budget with a different approval path and a much
longer lead time, and that is why hardware end-of-life dates need to be on a
register years in advance rather than noticed.

<details class="deeper">
<summary>If you assess mobile platforms: what side loading and jailbreaking actually change</summary>

Mobile platform vulnerabilities are in this objective and the two terms attached to
them get used loosely, so it is worth separating what each one removes.

**Side loading** installs an application from outside the platform's own store.
What that bypasses is review and revocation: the store's checks on the application,
and the platform's ability to remove it from every device if it turns out to be
harmful. The application still runs inside the platform's sandbox, still asks for
permissions, and is still constrained by the operating system. So side loading
removes a curation layer rather than a technical boundary, and the risk is
proportional to how much you trust the source.

**Jailbreaking** removes the platform's own restrictions on what may run, which
means removing the code signing enforcement and frequently the sandbox with it.
That is a different order of change: the protections the platform's security model
depends on are switched off, and every application on the device, including the
ones that were fine, now runs with fewer constraints than their authors assumed.

The practical distinction for a policy: a side-loaded application from a source you
have assessed is a decision with a knowable risk, and it is how most enterprise
internal applications are distributed. A jailbroken device cannot be assessed at
all, because the assumptions every other control on it rests on no longer hold, and
that is why management platforms detect and refuse them rather than trying to
compensate.

The detection is itself worth understanding as an arms race rather than a fact.
Checks look for the artefacts of the modification, and modifications hide their
artefacts, so a device reporting clean is a weaker statement than it appears.
Attestation backed by hardware is the stronger version, because the claim comes
from a component the modification cannot reach, and it is the direction the
platforms have moved.

</details>

## Prove it

**Run it.** `cat /sys/devices/system/cpu/vulnerabilities/*` on any Linux machine.
It takes a second, the list is machine-specific, and most people have never looked
at it.

**Work it out.** Take the cache output. If the level two cache is shared by every
processor a guest can see, what does that imply about a workload measuring its own
timing? Then decide whether it implies anything you would act on.

**Look it up.** Open SP 800-125A and find what it says about the hypervisor's
responsibility for clearing memory between guests. The wording tells you what to
ask a provider.

## What trips people up

### 1. Reading isolation as no sharing

A guest cannot see its neighbours and shares caches, memory bandwidth and
predictors with them. The capture on this page shows a level two cache shared by
every processor the guest has.

### 2. Treating a shared cache as a vulnerability

It is a performance design with an observable property. What one user does affects
what the next one measures, which is a mechanism rather than a flaw.

### 3. Expecting to patch a hardware vulnerability

The mitigation lives in the kernel, in microcode, or in a feature you turn off. Two
of those three belong to somebody else, and the third costs throughput.

### 4. Assuming released storage is cleared

Serious platforms clear on allocation rather than trusting release. The tenant-side
answer that does not depend on the provider is to encrypt from first use.

### 5. Putting hardware end of life on the same footing as software

Unsupported software can be contained or rewritten by a team. Unsupported hardware
is a purchase, on a different budget, with a longer lead time, and it takes its
microcode supply with it.

### 6. Treating side loading and jailbreaking as the same risk

Side loading bypasses curation and leaves the sandbox intact. Jailbreaking removes
the enforcement every other control on the device assumes, which is why management
platforms refuse rather than compensate.

## Work it through

A hardware vulnerability is published affecting a processor family you run. The
mitigation requires microcode from the machine vendor, and one generation of your
estate is out of vendor support.

**The tempting move is to wait for the vendor.** They may publish something. For the
supported generations they will, and for the unsupported one they will not, and
waiting is a decision to do nothing dressed as a decision to be patient.

**The move that works splits the estate on the day the advisory lands.** Supported
machines go into the normal patch cycle. Unsupported ones need a different answer,
and there are only three: disable the feature the flaw depends on and accept the
throughput cost, move the workload to supported hardware, or accept the exposure
with an owner and a date.

**Then the question that decides between them is what runs there.** A hardware side
channel needs an attacker with code executing on the same machine, so the exposure
depends entirely on whether anything untrusted runs there. A machine running one
application with no other tenants and no untrusted code is a very different case
from a shared build server.

**What this rejects is a uniform response.** Treating every affected machine the
same way either over-mitigates the isolated ones at a real performance cost or
under-mitigates the shared ones, and the split takes an hour to work out.

The residual is worth writing down: the unsupported generation will be affected by
the next one of these too, and by the one after that, with no supply of fixes. The
acceptance being signed is not for this advisory, it is for the class, and saying
so is what eventually funds the replacement.

## Try it

**Read your own register.** The vulnerabilities directory exists on every modern
Linux machine. Compare a virtual machine with a physical one and note that the
answers differ.

**Find the shared level.** Look at the cache topology and identify which level is
private and which is shared. On most machines the last level is shared by
everything.

**Ask your provider one question.** Is memory zeroed on allocation or on release,
and what about block storage. The answer is usually documented and rarely read.

**Check a firmware version.** Pick one server and find out what firmware it is
running and when it was last updated. Then consider how you would answer that for
the whole estate.

## Check yourself

<details class="qa">
<summary>A guest cannot see any other guest. What does it share with them?</summary>

The physical substrate. Caches, memory bandwidth, branch predictors and the buses
underneath. The capture on this page shows a guest whose level one caches are
private per processor and whose level two is shared across all five processors it
can see, and the same picture extends upward to sharing between guests on a host.

None of that is visible from inside, which is why isolation described from the
guest's point of view is a statement about visibility rather than about sharing.

</details>

<details class="qa">
<summary>Where do hardware vulnerability mitigations live, and why does that matter?</summary>

In the kernel as a software workaround, in microcode from the processor or machine
vendor, or in a feature you disable. It matters because two of the three belong to
somebody else and the third costs throughput.

It also explains why an unsupported hardware generation is a harder problem than
unsupported software: the supply of microcode ends with support, and the flaw is in
the thing doing the computing rather than in something you can put a boundary
around.

</details>

<details class="qa">
<summary>Why is resource reuse a confidentiality problem?</summary>

Because memory and storage released by one tenant are handed to the next, and if
nothing cleared them in between the second party receives what the first left.

Serious platforms clear on allocation rather than trusting the releasing party,
which is the right design and the specific question to ask a provider. The
tenant-side answer that does not depend on their behaviour is to encrypt from
first use, so a volume released without the key discloses nothing.

</details>

<details class="qa">
<summary>What does a kernel's hardware vulnerability register tell you?</summary>

Which flaws it knows about and what it is doing about each: not affected, a named
mitigation, or vulnerable. The machine on this page reports nineteen entries, two
with mitigations applied, and one that says vulnerable outright.

The list is machine-specific, so a table in a document cannot substitute for asking
the machine. One of the mitigations there is also partial, naming exactly which
part of the problem it covers.

</details>

<details class="qa">
<summary>What is the difference between side loading and jailbreaking?</summary>

Side loading installs from outside the platform's store, which bypasses curation
and revocation. The application still runs inside the sandbox with the same
permission model, so the risk is proportional to trust in the source, and it is how
most internal enterprise applications are distributed.

Jailbreaking removes the platform's own enforcement, including code signing and
frequently the sandbox. Every other control on the device assumed those, so a
jailbroken device cannot be meaningfully assessed, which is why management
platforms refuse rather than compensate.

</details>

## References

- [SP 800-125A Rev. 1](https://csrc.nist.gov/pubs/sp/800/125/a/rev-1/final) - NIST, hypervisor platform security, including isolation and memory handling between guests. Free. Accessed 2026-08-26.
- [SP 800-190](https://csrc.nist.gov/pubs/sp/800/190/final) - NIST, container security, for the shared-kernel case of the same argument. Free. Accessed 2026-08-26.
- [Kernel hardware vulnerabilities](https://docs.kernel.org/admin-guide/hw-vuln/index.html) - Linux kernel project, the documentation behind every entry the capture prints. Free. Accessed 2026-08-26.
- [SP 800-124 Rev. 2](https://csrc.nist.gov/pubs/sp/800/124/r2/final) - NIST, mobile device security, for side loading, jailbreaking and what each removes. Free. Accessed 2026-08-26.

**Where the content came from.** Both blocks are captured from the virtual machine
this project uses for kernel-level work, running on Apple Virtualization, which is
why the hardware vulnerability list is mostly not affected: the entries were found
on a different processor architecture and the file reports that honestly. Nothing
is exploited and no side channel is demonstrated, because the block rule is
evidence rather than attack and the evidence here is what the machine says about
itself.

**If you also work on Linux.** The Linux+ track's
[virtualization](/learn/linux-plus/virtualization) covers what a hypervisor
presents to a guest, and
[the kernel and modules](/learn/linux-plus/the-kernel-and-modules) covers where
the mitigations in this topic are applied.
