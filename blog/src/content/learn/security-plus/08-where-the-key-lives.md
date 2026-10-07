---
title: "Where the key lives"
description: "Why a disk encrypted with its key sitting next to it is not encrypted, what a trusted platform module actually refuses to do, the difference between a key you can copy and a key you can only use, and why escrow is an ordinary slot rather than a back door."
deck: "The disk is encrypted. The key is in a file on the same disk"
track: "security-plus"
level: "working"
order: 90
objectives:
  - "Say what each of the four named key stores protects against, and what none of them stops"
  - "Explain the difference between holding a key and being able to use one"
  - "Describe how a volume's master key relates to the passphrase somebody types"
  - "Explain what key escrow is, and why it is not a separate mechanism"
  - "Find out what key storage a machine in front of you actually has"
prerequisites: []
tags: ["security-plus", "security", "cryptography", "keys"]
updated: 2026-08-21
draft: false
examObjectives:
  - exam: "sy0-701"
    domain: "1.0"
    objective: "1.4"
sources:
  - title: "NIST SP 800-57 Part 1 Rev. 5, Recommendation for Key Management"
    url: "https://csrc.nist.gov/pubs/sp/800/57/pt1/r5/final"
    publisher: "NIST"
    accessed: 2026-08-21
    tier: 1
  - title: "FIPS 140-3, Security Requirements for Cryptographic Modules"
    url: "https://csrc.nist.gov/pubs/fips/140-3/final"
    publisher: "NIST"
    accessed: 2026-08-21
    tier: 1
  - title: "Trusted Platform Module Technology Overview"
    url: "https://learn.microsoft.com/en-us/windows/security/hardware-security/tpm/trusted-platform-module-overview"
    publisher: "Microsoft"
    accessed: 2026-08-21
    tier: 1
  - title: "cryptsetup(8) and the LUKS2 on-disk format"
    url: "https://man7.org/linux/man-pages/man8/cryptsetup.8.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-21
    tier: 1
  - title: "Get-Tpm"
    url: "https://learn.microsoft.com/en-us/powershell/module/trustedplatformmodule/get-tpm"
    publisher: "Microsoft"
    accessed: 2026-08-21
    tier: 1
symptoms:
  - symptom: "An encrypted volume unlocks at boot with nobody typing anything"
    anchor: "the-key-nobody-types"
  - symptom: "A departing employee's laptop cannot be opened by anybody"
    anchor: "escrow-is-a-slot"
---

> **Before you read.** A laptop is encrypted with full-disk encryption. It boots
> to a login prompt without anybody typing a passphrase, which everybody agrees is
> convenient.
>
> The laptop is stolen from a car.
>
> **Is the data protected? What would you need to know to answer?**

The cipher is not the interesting part of this. Where the key is, and what has to
happen before it can be used, decides almost everything about whether encryption
did anything.

### Some words you will need

<dl class="terms">
<dt>trusted platform module</dt>
<dd>A chip on the board that holds keys and performs operations with them without ever releasing them. Abbreviated TPM.</dd>
<dt>hardware security module</dt>
<dd>The same idea as a separate, usually much more expensive device, built to be tamper-evident and sometimes tamper-responding. Abbreviated HSM.</dd>
<dt>secure enclave</dt>
<dd>A processor's own isolated area for key material, on the same silicon as the main cores rather than a separate chip.</dd>
<dt>key management system</dt>
<dd>Software that issues, stores, rotates and retires keys across an estate, and records who has which.</dd>
<dt>root of trust</dt>
<dd>The component everything else is trusted because of. It is trusted because of where it is rather than because something vouched for it.</dd>
<dt>key escrow</dt>
<dd>A second copy of a key, or a second way to unlock, held by somebody other than the user.</dd>
<dt>master key</dt>
<dd>The key that actually encrypts the data, as distinct from the passphrase that unlocks it.</dd>
<dt>sealing</dt>
<dd>Binding a key so a module will only release or use it when the machine is in a particular state.</dd>
</dl>

## What breaks without this

**Encryption that protects nothing.** A volume whose key is readable by anybody
who has the disk is doing arithmetic and providing no security. The status page
says encrypted and the auditor's checkbox is ticked.

**A key that outlives the incident.** An attacker who copies a key file keeps it
after you evict them, and it works on their hardware, forever, with no way for you
to know they have it.

**A laptop nobody can open.** The employee left, the passphrase went with them,
and the data is genuinely and permanently gone, which is a availability failure
produced by a confidentiality control.

**Assuming a chip you do not have.** Most cloud machines have no hardware key
store at all, and a design that assumes one fails quietly by falling back to a
file.

## Four places, and what each one refuses

The four the objectives name are not four products at four price points. They
differ in one specific thing: whether the key can leave.

<figure class="learn-figure">
<svg viewBox="0 0 720 320" role="img" aria-labelledby="where-title" style="width:100%;height:auto;">
<title id="where-title">The same key held in four places, against what an attacker who has stolen the disk, has code running as a user, has administrator rights, or has physical access to the running machine can obtain in each case</title>
<g fill="currentColor">
<text x="14" y="20" font-size="11">what an attacker gets, by where the key is kept and what they have reached</text>
<text x="230" y="46" text-anchor="middle" font-size="9.5" fill-opacity="0.85">the disk</text>
<text x="350" y="46" text-anchor="middle" font-size="9.5" fill-opacity="0.85">code as a user</text>
<text x="470" y="46" text-anchor="middle" font-size="9.5" fill-opacity="0.85">administrator</text>
<text x="590" y="46" text-anchor="middle" font-size="9.5" fill-opacity="0.85">the running box</text>
<text x="14" y="76" font-size="9.5">file beside the data</text>
<rect x="180" y="62" width="100" height="20" rx="2" fill="var(--red)" fill-opacity="0.3" stroke="var(--red)" stroke-width="1.4"/>
<rect x="300" y="62" width="100" height="20" rx="2" fill="var(--red)" fill-opacity="0.3" stroke="var(--red)" stroke-width="1.4"/>
<rect x="420" y="62" width="100" height="20" rx="2" fill="var(--red)" fill-opacity="0.3" stroke="var(--red)" stroke-width="1.4"/>
<rect x="540" y="62" width="100" height="20" rx="2" fill="var(--red)" fill-opacity="0.3" stroke="var(--red)" stroke-width="1.4"/>
<text x="14" y="118" font-size="9.5">operating system store</text>
<rect x="180" y="104" width="100" height="20" rx="2" fill="none" stroke="currentColor" stroke-opacity="0.55" stroke-width="1.2" stroke-dasharray="3 3"/>
<rect x="300" y="104" width="100" height="20" rx="2" fill="var(--red)" fill-opacity="0.3" stroke="var(--red)" stroke-width="1.4"/>
<rect x="420" y="104" width="100" height="20" rx="2" fill="var(--red)" fill-opacity="0.3" stroke="var(--red)" stroke-width="1.4"/>
<rect x="540" y="104" width="100" height="20" rx="2" fill="var(--red)" fill-opacity="0.3" stroke="var(--red)" stroke-width="1.4"/>
<text x="14" y="160" font-size="9.5">tpm or secure enclave</text>
<rect x="180" y="146" width="100" height="20" rx="2" fill="none" stroke="currentColor" stroke-opacity="0.55" stroke-width="1.2" stroke-dasharray="3 3"/>
<rect x="300" y="146" width="100" height="20" rx="2" fill="none" stroke="currentColor" stroke-opacity="0.55" stroke-width="1.2" stroke-dasharray="3 3"/>
<rect x="420" y="146" width="100" height="20" rx="2" fill="var(--accent)" fill-opacity="0.28" stroke="var(--accent)" stroke-width="1.4"/>
<rect x="540" y="146" width="100" height="20" rx="2" fill="var(--accent)" fill-opacity="0.28" stroke="var(--accent)" stroke-width="1.4"/>
<text x="14" y="202" font-size="9.5">hardware security module</text>
<rect x="180" y="188" width="100" height="20" rx="2" fill="none" stroke="currentColor" stroke-opacity="0.55" stroke-width="1.2" stroke-dasharray="3 3"/>
<rect x="300" y="188" width="100" height="20" rx="2" fill="none" stroke="currentColor" stroke-opacity="0.55" stroke-width="1.2" stroke-dasharray="3 3"/>
<rect x="420" y="188" width="100" height="20" rx="2" fill="var(--accent)" fill-opacity="0.28" stroke="var(--accent)" stroke-width="1.4"/>
<rect x="540" y="188" width="100" height="20" rx="2" fill="var(--accent)" fill-opacity="0.28" stroke="var(--accent)" stroke-width="1.4"/>
<rect x="180" y="228" width="14" height="12" rx="2" fill="var(--red)" fill-opacity="0.3" stroke="var(--red)" stroke-width="1.4"/>
<text x="200" y="238" font-size="9.5" fill-opacity="0.85">the key itself</text>
<rect x="320" y="228" width="14" height="12" rx="2" fill="var(--accent)" fill-opacity="0.28" stroke="var(--accent)" stroke-width="1.4"/>
<text x="340" y="238" font-size="9.5" fill-opacity="0.85">use of it while they are there</text>
<rect x="560" y="228" width="14" height="12" rx="2" fill="none" stroke="currentColor" stroke-opacity="0.55" stroke-width="1.2" stroke-dasharray="3 3"/>
<text x="580" y="238" font-size="9.5" fill-opacity="0.85">nothing</text>
<text x="14" y="278" font-size="10" fill-opacity="0.85">hardware does not stop an administrator using the key, it stops them taking it</text>
<text x="14" y="300" font-size="10" fill-opacity="0.85">so the design question is what an attacker still holds after they are evicted</text>
</g></svg>
<figcaption>Four places to keep the same key, against four things an attacker might have reached. The distinction that matters runs down the two hardware rows: a trusted platform module or a hardware security module does not stop an administrator on the running machine from asking it to sign or decrypt, because that is what it is there for. What it stops is the key leaving, so the attack ends when the access ends. A key in a file ends the other way: once copied, it works forever, on the attacker's own hardware, and revoking their access to your machine does nothing at all. That is the whole argument for hardware key storage, and it is a statement about what happens after the incident rather than about preventing one.</figcaption>
</figure>

**A file is a key you can copy.** Steal the disk, or read the file, and you hold
the key. Nothing about the theft is detectable and nothing about your response
takes it back.

**An operating system store is a file with permissions on it.** It stops the
ordinary user and the ordinary process, which is a real improvement, and it stops
nothing that runs as administrator or that has the disk.

**A TPM or a secure enclave holds a key you can use and cannot take.** The key is
generated inside and the operations happen inside; what crosses the boundary is a
request and a result. An administrator on the running machine can ask it to
decrypt all day. What they cannot do is walk away with something that works
somewhere else.

**A hardware security module is the same property with a bigger boundary**,
usually a separate device shared by an estate, built to resist physical attack and
validated against a standard. FIPS 140-3 is the standard, it has levels, and the
level is the thing an auditor asks about.

**So the distinction is not prevention, it is what survives eviction.** All four
allow an attacker with administrator rights on a live machine to use the key. Only
the first two let them keep it.

<details class="deeper">
<summary>If you already deploy these: sealing, and what makes a TPM different from a locked drawer</summary>

Holding a key is the smaller half of what a TPM does. The larger half is that it
can refuse to use one unless the machine is in the state it was in when the key
was sealed.

The mechanism is a set of registers that accumulate measurements as the machine
boots: firmware measures the bootloader, the bootloader measures the kernel, and
each measurement is folded into a register in a way that cannot be rewound. A key
can be sealed to a set of those register values, and the module will only unseal
it when they match.

The consequence is the property people actually want from disk encryption on a
machine that boots unattended. The key is released when this machine boots this
software, and is not released when somebody moves the disk to another machine or
boots it from a USB stick. That is what makes unattended unlock defensible rather
than theatre.

It is also why an unexpected firmware update can lock you out of your own volume.
The measurements changed, the seal no longer matches, and the module correctly
refuses. That is not a bug and the recovery key is exactly the thing it exists
for, which brings this back to escrow.

</details>

## The key nobody types

Here is the mechanism underneath every full-disk encryption product, on a real
block device.

<details class="predict">
<summary>A second passphrase is added to an encrypted volume. How much of the disk has to be rewritten?</summary>

```bash
# AlmaLinux 10.2, aarch64
$ dnf -q -y install cryptsetup >/dev/null 2>&1
P="--batch-mode --pbkdf pbkdf2 --pbkdf-force-iterations 1000"
echo -n "the user passphrase" | cryptsetup luksFormat $P $DEV0 - 2>&1
echo "slots in use after formatting:"
cryptsetup luksDump $DEV0 | grep -c "luks2"
echo
echo "add a second key, held by the organisation:"
printf "the user passphrase" > /tmp/old; printf "the recovery key nobody types" > /tmp/new
cryptsetup luksAddKey $P --key-file /tmp/old $DEV0 /tmp/new 2>&1
cryptsetup luksDump $DEV0 | grep -E "^  [0-9]: luks2" 
echo
echo "either one opens it:"
cryptsetup open --test-passphrase --key-file /tmp/new $DEV0 && echo "  the recovery key works"
cryptsetup open --test-passphrase --key-file /tmp/old $DEV0 && echo "  the user passphrase works"
echo
echo "revoke the user, keep the volume:"
cryptsetup luksRemoveKey --key-file /tmp/old $DEV0 2>&1
cryptsetup open --test-passphrase --key-file /tmp/old $DEV0 2>&1 || echo "  the user passphrase no longer works"
cryptsetup open --test-passphrase --key-file /tmp/new $DEV0 && echo "  the recovery key still does"
slots in use after formatting:
1

add a second key, held by the organisation:
  0: luks2
  1: luks2

either one opens it:
  the recovery key works
  the user passphrase works

revoke the user, keep the volume:
No key available with this passphrase.
  the user passphrase no longer works
  the recovery key still does
```

</details>

**None of it.** A second key was added, both keys opened the volume, the first was
removed, and no block of data moved at any point.

<figure class="learn-figure">
<svg viewBox="0 0 720 300" role="img" aria-labelledby="slots-title" style="width:100%;height:auto;">
<title id="slots-title">One master key that encrypts the disk, held in the header encrypted separately by each of two key slots, so adding or removing a passphrase changes only a slot and never touches the data</title>
<g fill="currentColor">
<text x="14" y="20" font-size="11">the key that encrypts the disk is not a key anybody types</text>
<rect x="14" y="40" width="200" height="34" rx="4" fill="none" stroke="currentColor" stroke-opacity="0.7" stroke-width="1.4"/>
<text x="114" y="61" text-anchor="middle" font-size="10">the user's passphrase</text>
<rect x="14" y="98" width="200" height="34" rx="4" fill="none" stroke="currentColor" stroke-opacity="0.7" stroke-width="1.4" stroke-dasharray="4 3"/>
<text x="114" y="119" text-anchor="middle" font-size="10">the recovery key</text>
<path d="M 222 57 H 288" stroke="currentColor" stroke-opacity="0.75" stroke-width="1.5"/>
<path d="M 280 52 L 290 57 L 280 62" fill="none" stroke="currentColor" stroke-opacity="0.75" stroke-width="1.5"/>
<path d="M 222 115 H 288" stroke="currentColor" stroke-opacity="0.75" stroke-width="1.5" stroke-dasharray="4 3"/>
<path d="M 280 110 L 290 115 L 280 120" fill="none" stroke="currentColor" stroke-opacity="0.75" stroke-width="1.5"/>
<rect x="294" y="40" width="120" height="34" rx="4" fill="currentColor" fill-opacity="0.1" stroke="currentColor" stroke-opacity="0.7" stroke-width="1.4"/>
<text x="354" y="61" text-anchor="middle" font-size="10">slot 0</text>
<rect x="294" y="98" width="120" height="34" rx="4" fill="currentColor" fill-opacity="0.1" stroke="currentColor" stroke-opacity="0.7" stroke-width="1.4"/>
<text x="354" y="119" text-anchor="middle" font-size="10">slot 1</text>
<path d="M 422 57 H 488" stroke="var(--accent)" stroke-width="1.7"/>
<path d="M 480 52 L 490 57 L 480 62" fill="none" stroke="var(--accent)" stroke-width="1.7"/>
<path d="M 422 115 H 488" stroke="var(--accent)" stroke-width="1.7"/>
<path d="M 480 110 L 490 115 L 480 120" fill="none" stroke="var(--accent)" stroke-width="1.7"/>
<rect x="494" y="68" width="180" height="36" rx="4" fill="var(--accent)" fill-opacity="0.18" stroke="var(--accent)" stroke-width="1.8"/>
<text x="584" y="91" text-anchor="middle" font-size="10">the master key</text>
<text x="494" y="128" font-size="9.5" fill-opacity="0.85">generated once, never typed,</text>
<text x="494" y="146" font-size="9.5" fill-opacity="0.85">and never leaves the header</text>
<path d="M 584 168 V 152" stroke="var(--accent)" stroke-width="1.7"/>
<path d="M 579 160 L 584 170 L 589 160" fill="none" stroke="var(--accent)" stroke-width="1.7"/>
<rect x="494" y="172" width="180" height="30" rx="4" fill="none" stroke="var(--accent)" stroke-width="1.6"/>
<text x="584" y="192" text-anchor="middle" font-size="10">every block on the disk</text>
<text x="14" y="234" font-size="10" fill-opacity="0.85">removing slot 0 revokes the user and leaves every block exactly where it was</text>
<text x="14" y="256" font-size="10" fill-opacity="0.85">this is why changing a passphrase is instant and re-encrypting a disk is not</text>
<text x="14" y="278" font-size="10" fill-opacity="0.85">and why a copy of the master key taken while it was open is not revoked by either</text>
</g></svg>
<figcaption>The passphrase does not encrypt the disk. It unwraps a randomly generated master key stored in the volume header, and that key is what the block cipher uses. Each slot holds the same master key encrypted under a different passphrase, which is why the captured block above can add a second key, open the volume with either, and then delete the first without touching a single block of data. It also explains the two things people find surprising about disk encryption. Changing a passphrase takes a moment, because only a slot is rewritten. And escrow is not a back door bolted on: a recovery key is an ordinary slot, indistinguishable from the user's, which is exactly why the list of who holds a slot is a thing somebody has to keep.</figcaption>
</figure>

The passphrase does not encrypt the disk. A master key is generated at random when
the volume is created, that key encrypts the blocks, and each slot in the header
holds a copy of the master key encrypted under one passphrase. Unlocking means
using your passphrase to unwrap the master key.

Three things follow, and all three surprise people.

**Changing a passphrase is instantaneous** because only a slot is rewritten.
Re-encrypting a volume is a completely different operation that reads and writes
every block, and the fact that one is fast is a hint about what the other involves.

**Escrow is a slot.** The recovery key in that capture is not a special mechanism
or a back door. It is a second, ordinary slot, indistinguishable from the user's,
which is precisely why somebody has to keep a list of who holds one.

**Revoking a passphrase does not revoke a copied master key.** Removing slot 0
stops that passphrase working. If somebody extracted the master key while the
volume was open, they still have it, and the only fix is re-encryption with a new
master key.

<details class="deeper">
<summary>If you run encrypted estates: why the slot count matters, and the recovery key nobody can produce</summary>

The number of slots is small and finite, which is a design constraint people meet
by accident.

A machine that unlocks with a TPM, a user passphrase, an organisation recovery
key and a service account has four slots in use before anybody has thought about
it. Rotating one means adding the new before removing the old, so the peak is one
higher than the steady state, and a volume at its limit fails a rotation in a way
that reads as a permissions error.

The failure that actually costs money is the other one. An organisation escrows a
recovery key by generating it during provisioning and storing it centrally. Two
years later somebody needs it and discovers the store holds a key for a volume
that was rebuilt, or a key for the wrong machine, or nothing at all because the
provisioning path changed and the escrow step was in the old one.

That is not a cryptography problem and no better algorithm fixes it. It is an
inventory problem, which is why key management systems exist and why the boring
half of them, knowing which key belongs to which thing and who holds it, is the
half that earns their cost.

The test worth running once a quarter is to pick a machine at random and restore
it from escrow. Not to check the cryptography, which works, but to check that the
record is real.

</details>

## Escrow is a slot

The word escrow makes people uneasy, because it sounds like a deliberate weakness,
and sometimes it is one. The distinction worth holding is who it protects.

**Organisational escrow** is a recovery key held by the company that owns the
machine, and it protects against the departure, the forgotten passphrase and the
firmware update that broke the seal. Without it, a confidentiality control has
created an availability risk, and the data is gone in a way no backup of the
encrypted volume can help with.

**Escrow imposed by somebody else** is a copy of the key held by a party whose
interests are not yours, and it is a weakness by definition, because the security
of the data is now the security of their store as well as yours.

Both are the same mechanism, and the difference is entirely in whose hands the
second copy sits and what they can do with it. The question to ask about any
escrow arrangement is not whether one exists. It is who holds it, how it is
protected, what process releases it, and whether anybody has tested that process
this year.

<details class="deeper">
<summary>If you sign off on escrow: the split that removes the single holder</summary>

The uncomfortable property of a recovery key is that whoever holds it can open
every machine it covers, on their own, without anybody knowing. That is a lot of
authority to place in one administrator and one store.

The standard answer is to split it, so that no single holder can use it. The
crude version is to divide the key in half and give the halves to two people,
which works and has a defect: half a key is a real reduction in the work an
attacker faces, and losing one half loses the key entirely.

The better construction splits a secret into n shares such that any k of them
reconstruct it and any k minus one reveal nothing at all, not even partially.
Five shares with a threshold of three tolerates two people being unavailable and
two people being compromised, and each individual share is genuinely useless.
That is what a key ceremony at a certificate authority is doing when it hands
sealed envelopes to several officers.

Whether an ordinary organisation needs it is a judgement about what the key
opens. For laptop recovery keys it is usually overkill and a well-run store with
audited access is proportionate. For a certificate authority's root key, or a key
that decrypts an entire customer database, one person with sole access is a risk
somebody should have to defend in writing.

</details>

## Finding out what a machine actually has

Three machines, and the answer is the same on all three, which is more useful
than a contrived contrast.

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ ls /dev/tpm* 2>&1 | head -3
echo "--- kernel modules ---"
lsmod | grep -i tpm | head -5 || echo "no tpm modules"
echo "--- what the firmware exposes ---"
ls /sys/class/tpm/ 2>&1
echo "--- cpu security features ---"
grep -o "sev\|sme\|tdx" /proc/cpuinfo 2>/dev/null | sort -u | head -3 || echo "none"
ls: cannot access '/dev/tpm*': No such file or directory
--- kernel modules ---
--- what the firmware exposes ---
--- cpu security features ---
sme
```

No `/dev/tpm` device, no modules, nothing in `/sys/class/tpm`. The CPU reports one
memory-encryption feature and that is all.

<details class="predict">
<summary>A Windows Server on a cloud provider's hardware. How many key protectors do you expect BitLocker to report?</summary>

```powershell
# Microsoft Windows Server 2025 Datacenter, version 10.0.26100.0
> Get-Tpm | Format-List TpmPresent, TpmReady, TpmEnabled, ManufacturerIdTxt, ManufacturerVersion
TpmPresent          : False
TpmReady            : False
TpmEnabled          : False
ManufacturerIdTxt   :
ManufacturerVersion :

# What the volume encryption thinks, which is a separate question from the TPM
> Get-BitLockerVolume -ErrorAction SilentlyContinue | Format-List MountPoint, VolumeStatus, ProtectionStatus, KeyProtector
MountPoint       : C:
VolumeStatus     : FullyDecrypted
ProtectionStatus : Off
KeyProtector     : {}
MountPoint       : D:
VolumeStatus     : FullyDecrypted
ProtectionStatus : Off
KeyProtector     : {}

# The store where Windows keeps keys that never leave the machine
> certutil -key -user 2>&1 | Select-Object -First 6
CertUtil: -key command completed successfully.

# Which cryptographic providers are available to hold a key, hardware included
> certutil -csplist 2>&1 | Select-String "Provider Name" | Select-Object -First 8
Provider Name: Microsoft Base Cryptographic Provider v1.0
Provider Name: Microsoft Base DSS and Diffie-Hellman Cryptographic Provider
Provider Name: Microsoft Base DSS Cryptographic Provider
Provider Name: Microsoft Base Smart Card Crypto Provider
Provider Name: Microsoft DH SChannel Cryptographic Provider
Provider Name: Microsoft Enhanced Cryptographic Provider v1.0
Provider Name: Microsoft Enhanced DSS and Diffie-Hellman Cryptographic Provider
Provider Name: Microsoft Enhanced RSA and AES Cryptographic Provider
```

</details>

`TpmPresent: False`, and BitLocker reporting `FullyDecrypted` with no key
protectors at all.

```bash
# macOS 26.5.2, arm64
$ fdesetup status
FileVault is Off.

# What this machine is, since the answer to the next question depends on it
$ sysctl -n machdep.cpu.brand_string hw.model
Apple M1 (Virtual)
VirtualMac2,1

# Whether there is a secure enclave, and what the platform says about it
$ system_profiler SPHardwareDataType 2>/dev/null | grep -iE "chip|model name|activation lock|secure"
      Model Name: Apple Virtual Machine 1
      Chip: Apple M1 (Virtual)
      Activation Lock Status: Disabled

# Whether the keychain can hold a key the software never sees
$ security list-keychains
    "/Users/runner/Library/Keychains/login.keychain-db"
    "/Library/Keychains/System.keychain"
```

FileVault off, and the hardware identifying itself as `Apple Virtual Machine 1`
rather than as a physical Mac.

**All three of these are ordinary cloud machines and none of them has a hardware
key store.** That is not an unlucky sample. It is the normal state of a virtual
machine unless somebody deliberately attached a virtual TPM, and it is why a
design that assumes hardware key storage has to check rather than assume. The
laptop in front of you almost certainly has one; the server your application runs
on very likely does not.

The useful habit is that all three of those questions are one command, and asking
them is the first step of any conversation about where a key should live.

## Across platforms

| Task | Linux | Windows | macOS |
| --- | --- | --- | --- |
| Is there a TPM | `ls /sys/class/tpm/` | `Get-Tpm` | integrated, reported by `system_profiler` |
| Full-disk encryption state | `cryptsetup status name` | `Get-BitLockerVolume` | `fdesetup status` |
| What unlocks the volume | `cryptsetup luksDump dev` | the `KeyProtector` list | `fdesetup list` |
| Where the OS keeps keys | files with permissions | the certificate store and providers | the keychain |

## Prove it

**Run it.** Ask the machine in front of you all three questions with the commands
in the table above. Whether it has a module, whether the disk is encrypted, and
what unlocks it. Those are three separate answers and people routinely assume the
first implies the other two.

**Work it out.** A volume has four key slots in use: a TPM, a user passphrase, an
organisation recovery key and a service account. The maximum is eight. You need to
rotate the recovery key across the estate without any window in which a machine
has no recovery path. How many slots does a machine hold at the peak of that
operation, and what happens on a machine that already has seven in use?

**Look it up.** FIPS 140-3 defines security levels for cryptographic modules.
Find what distinguishes the levels and answer one question: at which level does
the standard start requiring a response to physical tampering rather than only
evidence of it? That difference is what an HSM is sold on and it is the reason for
the price.

## What trips people up

### 1. Reading "the disk is encrypted" as an answer

It is half an answer. The other half is what unlocks it, and a volume that unlocks
with no input from anybody is protected by whatever guards the key, which may be
nothing.

### 2. Believing a TPM stops an administrator

It does not, and it is not meant to. An administrator on the running machine can
ask it to use the key. What they cannot do is take the key somewhere else, which
is a statement about after the incident rather than during it.

### 3. Expecting a passphrase change to re-encrypt anything

It rewrites one slot. The master key is unchanged, and anybody who copied it while
the volume was open still holds a working key.

### 4. Treating escrow as a back door

It is a second slot, and whether it is a weakness depends entirely on who holds it
and how. Without one, a forgotten passphrase is permanent data loss, which is a
security failure of a different kind.

### 5. Assuming the server has the hardware the laptop has

Most virtual machines have no TPM unless somebody attached one. Check rather than
assume, because the failure mode is a silent fallback to a key in a file.

### 6. Confusing the key management system with the key store

A key management system knows which keys exist, who holds them and when they
expire. It is an inventory, and it can be perfectly maintained while every key it
lists sits in a file. The two questions are independent.

## Work it through

Back to the laptop stolen from the car.

**First, what "it boots without a passphrase" tells you.** The key was available
to the machine without a human. So something on the machine released it, and the
question is what that something was and what conditions it applied.

**If the key is in a file on the same disk, the data is gone.** The thief has the
disk and the disk has the key. The encryption performed correctly and protected
nothing, and the honest description of that machine is unencrypted with extra
steps.

**If a TPM released it, sealed to the boot state, the data is probably fine.** The
thief has a machine that will boot to a login prompt, and the module will release
the key only for this machine booting this software. Moving the disk to another
machine changes the measurements and the key is not released. What they can attack
is the login prompt, so the account's password is now the control that matters,
which is a very different conversation from the one about ciphers.

**If a TPM released it and nothing was sealed, you are back to the first case
slowly.** A module holding a key it will hand over on request to whatever boots is
a locked drawer with the key taped to it.

**And then the question nobody asked.** Is there a recovery key, does anybody know
where it is, and has anybody used it this year? Because the company now wants to
prove to a regulator that the data was protected, and the evidence for that is the
configuration and the escrow record rather than the fact that a product was
purchased.

The decision, written the way it should be written down: full-disk encryption with
the key sealed to the boot state in the module, a recovery key escrowed centrally
and tested quarterly, and a login credential strong enough to be the last line,
because with unattended unlock it is. The rejected option is a passphrase typed at
boot, and the cost of rejecting it is that the login password now carries weight it
would not otherwise have.

## Try it

**Ask your own machine the three questions.** Module, encryption state, and what
unlocks it. Two of them take a second and the third is the interesting one.

**Look at a LUKS header if you have a Linux machine.** `cryptsetup luksDump` on an
encrypted volume shows the slots, the cipher and the key derivation parameters. You
are looking at the structure in the figure above with real numbers in it. Reading
is safe; do not add or remove anything on a volume you need.

**Find out where your organisation's recovery keys are.** Not to use one. To find
out whether the answer is a system, a spreadsheet or a person, and whether anybody
has restored from it recently. This question has a surprisingly poor answer in most
places and asking it is genuinely useful work.

## Check yourself

<details class="qa">
<summary>A server's disk is encrypted and it boots unattended. What single fact decides whether the data is protected against disk theft?</summary>

What released the key, and under what conditions. If it came from a file on the
same disk, the thief has both and the encryption protected nothing. If a trusted
platform module released it, sealed to the boot state, the key is not available on
any other machine and the disk is protected.

Unattended unlock is not automatically wrong. It is wrong when the thing that
unlocks it travels with the thing it unlocks.

</details>

<details class="qa">
<summary>An attacker has administrator rights on a machine whose key is in a TPM. What can they do, and what have they gained once you evict them?</summary>

While they are there, everything the key can do: they can ask the module to sign
or decrypt as often as they like, because that is what it is for. A TPM does not
stop an administrator using a key.

Once evicted, nothing. The key never left the module, so there is no copy on their
hardware and the attack ends with the access. A key in a file ends the other way
round: they keep it, it works forever, and revoking their access does nothing.

</details>

<details class="qa">
<summary>Changing the passphrase on an encrypted volume takes a second. Re-encrypting it takes hours. Why?</summary>

Because the passphrase does not encrypt the data. A randomly generated master key
encrypts the blocks, and each key slot holds that master key encrypted under one
passphrase, so changing a passphrase rewrites one slot in the header.

Re-encryption generates a new master key and rewrites every block with it. The
distinction matters after a compromise: if somebody may have extracted the master
key while the volume was open, changing the passphrase achieves nothing and only
re-encryption does.

</details>

<details class="qa">
<summary>Is key escrow a weakness?</summary>

It depends entirely on who holds the second copy and what releases it. It is the
same mechanism either way: an ordinary key slot, indistinguishable from the user's.

An organisation holding a recovery key for machines it owns is preventing a
confidentiality control from becoming permanent data loss, which is a real risk
and the more likely one. A copy held by a party whose interests are not yours adds
their store's security to your threat model. The question is never whether escrow
exists, it is who, how, and whether the release process has been tested.

</details>

<details class="qa">
<summary>A design assumes keys will be held in a TPM. What should be checked before it ships?</summary>

Whether the machines it will run on have one. Three ordinary cloud machines
checked for this topic, on Linux, Windows and macOS, had no hardware key store
between them, which is the normal state of a virtual machine unless somebody
attached a virtual module deliberately.

The failure mode is the dangerous kind: the software falls back to a key in a
file, everything works, the status page says encrypted, and nobody finds out until
the disk image is copied.

</details>

## References

- [NIST SP 800-57 Part 1 Rev. 5](https://csrc.nist.gov/pubs/sp/800/57/pt1/r5/final) - NIST, key management, including the protection requirements for a key by type and the lifecycle a key management system implements. Free. Accessed 2026-08-21.
- [FIPS 140-3](https://csrc.nist.gov/pubs/fips/140-3/final) - NIST, the security requirements for cryptographic modules and the source for what the levels mean. Free. Accessed 2026-08-21.
- [Trusted Platform Module Technology Overview](https://learn.microsoft.com/en-us/windows/security/hardware-security/tpm/trusted-platform-module-overview) - Microsoft, what a module does and what the platform configuration registers are for. The specification itself is published by the Trusted Computing Group, whose site refuses automated requests, so it is named rather than linked. Free. Accessed 2026-08-21.
- [cryptsetup(8)](https://man7.org/linux/man-pages/man8/cryptsetup.8.html) - Linux man-pages project, the tool that produced the key slot capture, and the reference for the on-disk format. Free. Accessed 2026-08-21.
- [Get-Tpm](https://learn.microsoft.com/en-us/powershell/module/trustedplatformmodule/get-tpm) - Microsoft, the cmdlet the Windows block uses and what each field it reports means. Free. Accessed 2026-08-21.

**Where the output came from.** Every block on this page is captured. The key slot
block ran on AlmaLinux 10.2 aarch64 against a real loop device, so the volume, the
slots and the passphrase failure are genuine rather than illustrated; the key
derivation was deliberately weakened to a thousand iterations so the capture
completes, which is not a setting to copy. The probe blocks ran on Fedora CoreOS
44 on a virtual machine, Windows Server 2025 runner image 20260818.207.1, and
macOS 26.5.2 arm64 runner image 20260728.0273.1. All three report no hardware key
store, which is a fact about those three machines on 21 August 2026 and is also
the usual answer for a virtual machine.

**If you also work on Linux.** The Linux+ track's
[encrypting data at rest](/learn/linux-plus/encrypting-data-at-rest) topic covers
LUKS as an administrative task, including unlocking at boot and what is left behind
after a volume is closed.
