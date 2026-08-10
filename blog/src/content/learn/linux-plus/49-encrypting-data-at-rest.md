---
title: "Encrypting data at rest"
description: "LUKS turns a disk into 16 megabytes of header and a lot of noise. Building an encrypted volume from nothing, what the header holds, why losing it loses everything, and why shred stopped working on SSDs."
deck: "The laptop is stolen. What did they actually get?"
track: "linux-plus"
level: "working"
order: 500
objectives:
  - "Build, open, use, and close a LUKS2 volume"
  - "Read a LUKS header and say what is stored in it"
  - "Explain what full-disk encryption protects against and what it does not"
  - "Choose between block, filesystem, and file encryption for a given problem"
  - "Say why shred is unreliable on an SSD and what to do instead"
prerequisites: ["disks-partitions-and-filesystems", "cryptography-basics"]
tags: ["linux", "linux-plus", "encryption", "luks", "gpg", "security"]
updated: 2026-08-08
draft: false
examObjectives:
  - exam: "xk0-006"
    domain: "3.0"
    objective: "3.5"
sources:
  - title: "cryptsetup(8)"
    url: "https://man7.org/linux/man-pages/man8/cryptsetup.8.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-08
    tier: 1
  - title: "crypttab(5)"
    url: "https://man7.org/linux/man-pages/man5/crypttab.5.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-08
    tier: 1
  - title: "shred(1)"
    url: "https://man7.org/linux/man-pages/man1/shred.1.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-08
    tier: 1
  - title: "gpg(1)"
    url: "https://manpages.debian.org/trixie/gpg/gpg.1.en.html"
    publisher: "Debian manpages"
    accessed: 2026-08-08
    tier: 1
  - title: "RFC 9106: Argon2 Memory-Hard Function for Password Hashing and Proof-of-Work Applications"
    url: "https://www.rfc-editor.org/rfc/rfc9106.html"
    publisher: "IETF"
    accessed: 2026-08-08
    tier: 1
  - title: "cryptsetup Frequently Asked Questions"
    url: "https://gitlab.com/cryptsetup/cryptsetup/-/wikis/FrequentlyAskedQuestions"
    publisher: "cryptsetup project"
    accessed: 2026-08-08
    tier: 1
  - title: "WireGuard: fast, modern, secure VPN tunnel"
    url: "https://www.wireguard.com/"
    publisher: "WireGuard"
    accessed: 2026-08-08
    tier: 1
symptoms:
  - symptom: "unknown filesystem type crypto_LUKS"
    anchor: "closing-it-and-what-is-left-behind"
  - symptom: "No key available with this passphrase"
    anchor: "opening-it"
---

> **Before you read.** A laptop is stolen from a car. It had customer records on it.
> Your manager wants to know, today, whether that is a breach that has to be
> reported.
>
> The answer depends entirely on one thing, and it is not whether the machine had a
> login password.
>
> **What is actually on those platters when the machine is powered off?**

If the disk was encrypted, the answer is: sixteen megabytes of header and several
hundred gigabytes of material that is indistinguishable from noise. Most data
protection regimes treat that as no disclosure at all, and the incident becomes a
hardware loss.

If it was not, a login password bought you nothing. The thief does not log in. They
take the disk out, plug it into another machine, and read it, because file
permissions are enforced by *your* kernel and the thief brought their own.

This lesson is that difference, built from nothing on a real machine.

### Some words you will need

<dl class="terms">
<dt>at rest</dt>
<dd>Data sitting on a disk, as opposed to data crossing a network, which is "in transit".</dd>
<dt>LUKS</dt>
<dd>Linux Unified Key Setup. The standard format for an encrypted block device, and the header format that makes it portable.</dd>
<dt>dm-crypt</dt>
<dd>The kernel machinery that does the encrypting. LUKS is the on-disk format around it.</dd>
<dt>master key</dt>
<dd>The key the data is actually encrypted with. Random, generated once, never seen by you.</dd>
<dt>key slot</dt>
<dd>A copy of the master key, encrypted with one passphrase. Eight of them by default.</dd>
<dt>mapper device</dt>
<dd>The decrypted view of the volume, appearing under <code>/dev/mapper/</code> while it is open.</dd>
<dt>cryptographic erase</dt>
<dd>Destroying the key rather than the data, so the data becomes unrecoverable in one operation.</dd>
</dl>

## What breaks without this

**A lost device becomes a reportable breach**, with the regulatory timeline, the
customer notification, and the write-up that follows.

**A disk sent for RMA or disposal leaves with its contents.** Drives get returned
under warranty every day, and a failed drive is often readable enough.

**You encrypt the wrong layer.** File-level encryption of a database leaves the
indexes, the write-ahead log, and the temporary files in the clear, and everything
that matters is in those.

**You lose the header and the data is gone.** Not "difficult to recover",
gone, in the same sense as if you had shredded the platters, and no backup of
the *files* helps because they were never readable without it.

## Three places encryption can sit

The three are not alternatives so much as different answers to "what is the unit
being protected".

| Layer | Encrypts | Granularity | Cost |
| --- | --- | --- | --- |
| **Block** (LUKS, dm-crypt) | The whole device, below the filesystem | All or nothing | One passphrase at boot |
| **Filesystem** (fscrypt, eCryptfs) | Chosen directories, inside a filesystem | Per directory or user | Per-user keys to manage |
| **File** (GPG, age) | One file at a time | Per file | You must remember to do it |

**Block encryption is the default answer and the one the exam is about.** It sits
below the filesystem, so it encrypts everything without exception: the files, the
metadata, the free space, the swap, the journal, and the temporary files nobody
thinks about. Nothing has to opt in and nothing can be forgotten.

Its limitation is the flip side of the same property: once the volume is open, it is
open to everything on the machine. It protects a powered-off disk and nothing else.

<details class="deeper">
<summary>If you already administer Linux: exactly what full-disk encryption does and does not defend against</summary>

It is worth being precise, because "the disk is encrypted" gets used to answer
questions it does not answer.

**Defends against:** a stolen or lost powered-off machine. A disk removed and
attached to another system. A drive returned under warranty. A disk sold, donated, or
thrown away. Forensic recovery from unallocated space, because there is no
unallocated plaintext.

Does not defend against: anything at all while the machine is running and the
volume is open. A compromised process reads the decrypted view like any other
file. An attacker with your login credentials sees plaintext. A malicious
administrator sees plaintext. Ransomware encrypts your already-encrypted files
perfectly happily.

The one people are surprised by is memory. The master key lives in kernel
memory while the volume is open, and a machine that is *suspended* rather than
powered off still has it there. This is why "suspend" and "hibernate" are
genuinely different security postures: hibernate writes memory to the swap
area and powers off, so with an encrypted swap the key is gone; suspend keeps
it in RAM with the machine nominally off. A stolen suspended laptop is much
closer to a stolen running one.

And the physical attack it does not stop: an "evil maid" who has the machine
briefly, unattended, and powered off. They cannot read the data, but they can
modify the *unencrypted* boot partition, which must be readable for the
machine to start, to capture your passphrase the next time you type it. Secure
Boot from lesson 45 plus a TPM-measured boot is the countermeasure, and it is
the reason those two features exist alongside disk encryption rather than
instead of it.

Being able to state that list is worth more than any command in this topic, because
the most common real failure is not a technical one: it is somebody treating "the
disks are encrypted" as an answer to a question about a running system.

</details>

## Building one

Encryption is applied to a block device, a disk, a partition, or a logical
volume from lesson 14. The captures below use a loop device, which behaves
identically; the `$DEV0` in the command is the path the capture harness
provisioned, and the real name appears in the output.

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ printf "correct horse battery staple" > /var/tmp/pass.txt; sudo cryptsetup luksFormat --type luks2 --batch-mode --pbkdf-memory 262144 --key-file /var/tmp/pass.txt $DEV0; echo "rc=$?"; sudo blkid $DEV0
rc=0
/dev/loop0: UUID="66b61d6a-a95f-482d-ab18-07e65ca3029a" TYPE="crypto_LUKS"
```

**`TYPE="crypto_LUKS"` is the whole result.** Whatever was on that device
before is now unreachable, and the device advertises only that it is a LUKS
container. Note it still has a UUID. The header is not hidden, and it is not
meant to be.

**`luksFormat` destroys everything on the device** and, without `--batch-mode`, asks
you to type `YES` in capitals first. Interactively it also asks for the passphrase
twice. The captures use a key file to keep the transcript reproducible; a person at a
terminal would be prompted.

What it actually wrote:

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ sudo cryptsetup luksDump $DEV0 | head -28
LUKS header information
Version:       	2
Epoch:         	3
Metadata area: 	16384 [bytes]
Keyslots area: 	16744448 [bytes]
UUID:          	f50a6543-c613-42b1-8800-3abaafd82eb1
Label:         	(no label)
Subsystem:     	(no subsystem)
Flags:       	(no flags)

Data segments:
  0: crypt
	offset: 16777216 [bytes]
	length: (whole device)
	cipher: aes-xts-plain64
	sector: 512 [bytes]

Keyslots:
  0: luks2
	Key:        512 bits
	Priority:   normal
	Cipher:     aes-xts-plain64
	Cipher key: 512 bits
	PBKDF:      argon2id
	Time cost:  57
	Memory:     262144
	Threads:    4
	Salt:       86 3b 3d c4 f0 a9 33 5b e8 91 81 04 2f f8 9b 16 
```

**Read `offset: 16777216`.** Sixteen megabytes at the front of the device are header;
everything after that is encrypted payload. That is the number to remember, because
it explains the size difference you are about to see, and it is what a header backup
has to cover.

`aes-xts-plain64` is the cipher, and XTS is the mode designed for storage
specifically: it is length-preserving, so a 512-byte sector encrypts to 512
bytes, which is what lets the encrypted device behave exactly like an
unencrypted one. `Cipher key: 512 bits` sounds like AES-512, which does not
exist, XTS uses two 256-bit keys, so 512 bits total is AES-256.

**And `PBKDF: argon2id`** is the LUKS2 improvement that matters. Your
passphrase does not encrypt the data; it unlocks a key slot holding a copy of
the master key, and Argon2id is the function that turns the passphrase into
the slot key deliberately slowly. `Memory: 262144` is 256 MiB and `Time cost:
57` iterations, every guess an attacker makes must spend that too.

<details class="deeper">
<summary>If you already administer Linux: why Argon2 replaced PBKDF2, and when to override the defaults</summary>

LUKS1 used PBKDF2, which is only *time*-hard: it iterates a hash a lot. That was a
reasonable defence in 2004 and stopped being one when GPUs and ASICs arrived, because
those parallelise a pure-computation workload enormously. A password-cracking rig can
try PBKDF2 candidates thousands of times faster than the laptop that set them.

**Argon2 is memory-hard**, and that is the entire point. Each guess must
allocate the configured memory, 256 MiB above, and hold it. A GPU with 24 GB
of memory can run about ninety of those in parallel regardless of how many
cores it has, where the same GPU runs tens of thousands of PBKDF2 attempts.
The attacker's advantage collapses from several orders of magnitude to roughly
one.

`argon2id` is the hybrid variant and the one to use: `argon2d` resists GPU attack but
leaks timing information through data-dependent memory access, `argon2i` is the
reverse, and `id` runs one pass of each. RFC 9106 recommends it as the default.

**The defaults are benchmarked at format time on the machine doing the
formatting**, targeting about two seconds, which produces a problem people
meet in practice: formatting a volume on a fast workstation and then unlocking
it on a small VM or an embedded board takes far longer than two seconds,
sometimes fifteen, or fails outright because the memory cost exceeds what the
initramfs has available.

The knobs, and the reasons to touch them:

```
cryptsetup luksFormat --pbkdf argon2id --pbkdf-memory 1048576 --iter-time 5000 /dev/sdX
cryptsetup luksFormat --pbkdf pbkdf2 /dev/sdX
```

Raise `--pbkdf-memory` on a machine with plenty of RAM and a high-value disk.
Lower it, or fall back to `pbkdf2`, when the volume must unlock inside a
constrained initramfs, or on a device whose unlock is automated from a key
file anyway, where the slow derivation is protecting a key file rather than a
human-memorable passphrase and is buying much less.

The capture above used `--pbkdf-memory 262144` for exactly that reason: the machine
has 2 GiB of RAM, and the auto-benchmarked default would have been a poor fit.

`cryptsetup benchmark` prints what the machine can do, and is the right thing to run
before deciding.

</details>

## Opening it

The encrypted device is not usable directly. Opening it creates a second
device, the decrypted view, and you work with that.

The underlying device is 512 MiB, and the header dump above reported
`offset: 16777216 [bytes]`.

<details class="predict">
<summary>Opening the volume creates <code>/dev/mapper/vault</code>. What size will <code>lsblk</code> report for it, and why is that not 512M?</summary>

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ sudo cryptsetup open --key-file /var/tmp/pass.txt $DEV0 vault; ls -l /dev/mapper/vault; lsblk $DEV0
lrwxrwxrwx. 1 root root 7 Aug  8 12:15 /dev/mapper/vault -> ../dm-0
NAME    MAJ:MIN RM  SIZE RO TYPE  MOUNTPOINTS
loop0     7:0    0  512M  0 loop  
└─vault 252:0    0  496M  0 crypt 
```

</details>

**`512M` becomes `496M`, and the missing 16 MiB is the header.** The `TYPE` column
says `crypt`, stacked under the `loop` device exactly the way an LVM logical volume
stacks under a physical volume. This is the same layering idea as lesson 14, one
level lower.

`vault` is a name you chose. It appears at `/dev/mapper/vault` and everything from
here on treats it as an ordinary block device.

Get the passphrase wrong and it says so plainly:

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ echo "wrong passphrase" | sudo cryptsetup open $DEV0 vault -; echo "rc=$?"
No key available with this passphrase.
rc=2
```

**"No key available" is precise rather than polite.** It did not say the
passphrase was wrong; it said no key slot could be unlocked with it. That is
the same message whether you mistyped, or used the right passphrase for the
wrong disk, or the slot holding your passphrase was removed, and
distinguishing those is what `luksDump` is for.

Now put a filesystem on the decrypted view, which is the step that surprises people
the first time:

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ sudo mkfs.ext4 -q /dev/mapper/vault; sudo mkdir -p /var/tmp/vault; sudo mount /dev/mapper/vault /var/tmp/vault; echo "the salary spreadsheet" | sudo tee /var/tmp/vault/hr.txt; df -h /var/tmp/vault | tail -1; sudo umount /var/tmp/vault
the salary spreadsheet
/dev/mapper/vault  455M  139K  426M   1% /var/tmp/vault
```

**`mkfs` runs on `/dev/mapper/vault`, never on the underlying device.** Formatting the
underlying device destroys the LUKS header, which destroys the volume. This is the
single most expensive mistake available in this topic and it takes one absent-minded
`mkfs` on the wrong path.

The full stack is now four layers deep, and lesson 12's disk-partition-filesystem
sequence has grown one:

```
device  ->  LUKS container  ->  /dev/mapper/vault  ->  ext4  ->  /var/tmp/vault
```

`cryptsetup status` reports the middle of that:

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ sudo cryptsetup status vault
/dev/mapper/vault is active and is in use.
  type:    LUKS2
  cipher:  aes-xts-plain64
  keysize: 512 [bits]
  key location: keyring
  device:  /dev/loop0
  loop:    /var/tmp/capture-0.img (deleted)
  sector size:  512 [bytes]
  offset:  32768 [512-byte units] (16777216 [bytes])
  size:    1015808 [512-byte units] (520093696 [bytes])
  mode:    read/write
```

**`is in use`** means something has it open (here, the mounted filesystem) and
`close` will refuse until that is unwound. **`key location: keyring`** is
where the master key lives while the volume is open: the kernel keyring, in
memory, which is the fact behind the suspend-versus-hibernate point above.

## Closing it, and what is left behind

<details class="predict">
<summary>The volume is closed. The device still has its LUKS header and its UUID, so <code>blkid</code> can identify it. What happens if you try to mount it directly?</summary>

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ sudo cryptsetup close vault; ls /dev/mapper/vault; sudo blkid $DEV0; sudo mount $DEV0 /var/tmp 2>&1
ls: cannot access '/dev/mapper/vault': No such file or directory
/dev/loop0: UUID="2d551ba2-620b-45e5-8b44-8f7f322e073c" TYPE="crypto_LUKS"
mount: /var/tmp: unknown filesystem type 'crypto_LUKS'.
       dmesg(1) may have more information after failed mount system call.
```

</details>

**`unknown filesystem type 'crypto_LUKS'` is the answer to the opening question**, and
it is what the thief sees. The kernel can tell there is a LUKS container there. It
cannot tell what filesystem is inside, how big it is, or what it holds, because none
of that is readable without the master key. The `ext4` superblock that `blkid` would
normally report is itself encrypted.

**The mapper device is gone**, which is the other half: `close` removed the decrypted
view and wiped the master key from the kernel keyring. There is now no copy of it
anywhere except inside the key slots, each locked with a passphrase.

## Key slots

A LUKS header has eight slots by default, each holding the same master key
encrypted under a different passphrase. That indirection is what makes
passphrase changes cheap. The data is never re-encrypted, only a slot is
rewritten.

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ sudo cryptsetup luksDump $DEV0 | grep -E "^  [0-9]: luks2"; printf "a second recovery phrase" > /var/tmp/pass2.txt; sudo cryptsetup luksAddKey --key-file /var/tmp/pass.txt $DEV0 /var/tmp/pass2.txt; echo "--- now ---"; sudo cryptsetup luksDump $DEV0 | grep -E "^  [0-9]: luks2"
  0: luks2
--- now ---
  0: luks2
  1: luks2
```

**Adding a key requires an existing one.** You have to prove you can already open the
volume, which is why `luksAddKey` takes the current passphrase and the new one.

The operations, and one of them has a trap:

| Command | Does |
| --- | --- |
| `luksAddKey` | Adds a passphrase to a free slot |
| `luksChangeKey` | Replaces one slot's passphrase in place |
| `luksRemoveKey` | Removes the slot matching a given passphrase |
| `luksKillSlot N` | Removes slot N by number |

**`luksKillSlot` will happily remove your last slot** and leave a volume nobody can
open, with the data intact and permanently unreachable. `luksDump` first, every time.

The reason to have two slots on any machine that matters: **an automation key and a
human key**. Slot 0 holds a key file used to unlock at boot; slot 1 holds a passphrase
a person can type when the key file is unavailable. Losing one is then an
inconvenience rather than a total loss.

<details class="deeper">
<summary>If you already administer Linux: back up the header, because losing it loses everything</summary>

The master key exists in exactly one place: the key slots in the header, in the first
16 MiB of the device. There is no copy anywhere else, by design.

**So corrupting the header destroys the data completely.** Not "makes recovery hard".
The payload is encrypted with a 512-bit random key that existed only there, and no
passphrase, no backup of the files, and no vendor can reconstruct it.

This is not hypothetical. A stray `dd` to the start of the wrong device, a
partition table rewrite that shifts the start offset, an installer that
"helpfully" initialises a disk, all of these have destroyed working LUKS
volumes.

```
sudo cryptsetup luksHeaderBackup /dev/sdX --header-backup-file luks-sdX.img
sudo cryptsetup luksHeaderRestore /dev/sdX --header-backup-file luks-sdX.img
```

**Treat the backup as being as sensitive as the disk itself**, because it is: it holds
every key slot, so anyone with the file and any one passphrase has the data. Store it
somewhere at least as protected as the volume, and never on the volume.

The subtle trap is that a header backup is a snapshot of the slots. Remove a
compromised passphrase from the live header, then restore an older backup, and
that passphrase works again. A header restore is a rollback of your key
management, so after restoring, immediately audit the slots and remove
anything that should not be there.

LUKS2 mitigates plain corruption on its own: it keeps a secondary copy of the
metadata within that 16 MiB and checksums both, so a single damaged region is
detected and repaired automatically. That was one of the main reasons for the
format change. It does not help when the whole first 16 MiB is overwritten,
which is the case that actually happens.

The related option for the paranoid is `--header` on a detached file: the
header lives elsewhere entirely (a USB key, say) and the disk is then
indistinguishable from random data with no LUKS signature at all. It also
means losing the USB key loses the disk, so it trades one risk for another
quite deliberately.

</details>

## Unlocking at boot

Typing a passphrase at every boot is fine for a laptop and impossible for a server in
a rack. `/etc/crypttab` is the mapping, read at boot, and it is `/etc/fstab`'s
counterpart one layer down:

```
# name      backing device                                  key file            options
vault       UUID=66b61d6a-a95f-482d-ab18-07e65ca3029a       /etc/luks/vault.key  luks
data        UUID=...                                        none                 luks,discard
```

Then `/etc/fstab` mounts `/dev/mapper/vault` as usual. **The order matters and it is
automatic**: systemd generates a unit from each `crypttab` line and makes the
corresponding mount depend on it.

`none` in the key column means prompt at boot, which works on a machine with a
console. A key file means unattended, and immediately raises the obvious
question of where the key file lives, since a key file on the encrypted volume
it unlocks is useless and a key file on an unencrypted root is protecting
nothing from someone holding the disk.

The three real answers:

**A TPM.** The key is sealed to the platform's measured boot state, so it is released
only if the firmware, bootloader, and kernel are unchanged. `systemd-cryptenroll
--tpm2-device=auto` does this in one command on a modern system. This is what makes
an unattended server defensible, and it is why lesson 45's Secure Boot section is
adjacent to this one.

A network key server, such as Tang with Clevis: the machine asks a server on
the internal network for its key at boot, so a disk removed from the building
cannot be unlocked at all.

A person, over the network. `dropbear-initramfs` runs a tiny SSH server in the
initramfs so somebody can log in and type the passphrase. Simple, and it does
not scale past a handful of machines.

## Encrypting one file

Block encryption is all-or-nothing. Sometimes the unit is a single file,
something being emailed, or archived, or handed to somebody. GPG does
symmetric encryption with a passphrase and no keys to manage:

```bash
# Debian 13 (trixie), x86_64
$ gpg --batch --passphrase "correct horse" --symmetric --cipher-algo AES256 report.txt; ls -l report.txt report.txt.gpg; file report.txt.gpg
-rw-r--r--. 1 root root  22 Aug  8 17:42 report.txt
-rw-r--r--. 1 root root 102 Aug  8 17:42 report.txt.gpg
report.txt.gpg: PGP symmetric key encrypted data - AES with 256-bit key salted & iterated - SHA512 .
```

**`file` reads the parameters straight out of the container**: AES-256, salted
and iterated, SHA-512. Note that 22 bytes became 102. The overhead is the
header, and it matters for a small file and disappears for a large one.

**The original is still there.** `--symmetric` writes a new file and does not remove
the input, which is the mistake to avoid: encrypting a file and leaving the plaintext
beside it protects nothing.

The wrong passphrase produces a specific error worth recognising:

```bash
# Debian 13 (trixie), x86_64
$ gpg --batch -q --pinentry-mode loopback --passphrase "correct horse" --symmetric report.txt; rm report.txt; timeout 20 gpg --batch --pinentry-mode loopback --passphrase "wrong one" --decrypt report.txt.gpg; echo "rc=$?"
gpg: AES256.CFB encrypted data
gpg: encrypted with 1 passphrase
gpg: decryption failed: Bad session key
rc=2
```

**"Bad session key" means the passphrase failed**, and it is worth knowing that
wording because it does not contain the word "passphrase". The two lines above it are
GPG reporting what it found in the container before it tried, which it can do without
any key at all.

For sending a file to somebody else, asymmetric is the right tool (encrypt to
their public key, and only their private key opens it) which is lesson 47's
material applied.

## Deleting data properly

Removing a file unlinks a name. The blocks stay on the disk until something else
uses them, which is why undelete tools work. `shred` overwrites first:

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ cd /var/tmp; head -c 4096 /dev/urandom > secret.bin; ls -l secret.bin; shred -v -n 2 -z -u secret.bin; ls -l secret.bin 2>&1
-rw-r--r--. 1 core core 4096 Aug  8 12:18 secret.bin
shred: secret.bin: pass 1/3 (random)...
shred: secret.bin: pass 2/3 (random)...
shred: secret.bin: pass 3/3 (000000)...
shred: secret.bin: removing
shred: secret.bin: renamed to 0000000000
shred: 0000000000: renamed to 000000000
shred: 000000000: renamed to 00000000
shred: 00000000: renamed to 0000000
shred: 0000000: renamed to 000000
shred: 000000: renamed to 00000
shred: 00000: renamed to 0000
shred: 0000: renamed to 000
shred: 000: renamed to 00
shred: 00: renamed to 0
shred: secret.bin: removed
ls: cannot access 'secret.bin': No such file or directory
```

**Read the rename chain.** `-u` removes the file, and before doing so it
renames it repeatedly to shorter names of zeros, because the *filename* is
also data. It lives in the directory entry and can survive in the filesystem's
metadata. `-n 2` asked for two random passes and `-z` added a final pass of
zeros, which is why it reports three.

**And now the part that matters more than the command:** on modern storage this is
frequently theatre.

| Storage | Does `shred` work | Why |
| --- | --- | --- |
| Spinning disk, ext4 without a journal | Yes | Overwrites land on the same physical sectors |
| Any SSD or NVMe | **No** | Wear levelling writes elsewhere; the original blocks are still there |
| Copy-on-write, btrfs or ZFS | **No** | A write never overwrites in place, by design |
| Anything with snapshots | **No** | Old blocks are held deliberately |
| Network or virtual storage | **No** | You are not addressing physical media at all |

`shred`'s own manual page has said this for years. The assumption it depends
on, that writing to a file's blocks overwrites those physical blocks, stopped
being true for almost everything.

<details class="deeper">
<summary>If you already administer Linux: cryptographic erase, and what to actually do with a disk you are disposing of</summary>

Since overwriting is unreliable, the practical answer is to make the data
unrecoverable by destroying the key instead. Encrypt the disk from the day it is
deployed, and disposal becomes a metadata operation.

**On a LUKS volume the entire process is one command:**

```
sudo cryptsetup luksErase /dev/sdX
```

That wipes every key slot. The payload is untouched and now permanently unreadable,
because the only copies of the master key were in those slots. It takes about a
second on a 20 TB drive, where overwriting would take a day and still not be
trustworthy.

**The vendor route for a drive that was never encrypted** is the drive's own
secure erase, which tells the controller to reset its internal encryption key
or reset every cell, the one operation that can reach the blocks wear
levelling hid from you:

```
sudo nvme format /dev/nvme0n1 --ses=1
sudo hdparm --user-master u --security-erase PASSWORD /dev/sdX
```

Both are firmware operations. Both have a history of being implemented incorrectly by
some vendors, which is why standards bodies stopped treating "the drive says it did
it" as sufficient evidence on its own.

**Which is why the guidance splits three ways:** *clear* for a disk being
reused inside the organisation, *purge*, cryptographic erase or a verified
firmware erase, for one leaving it, and *destroy*, physical shredding or
degaussing, for anything whose disclosure would be serious. The relevant
standard is NIST SP 800-88, and the decision is about where the disk goes next
rather than about what it holds.

**The operationally useful conclusion is the one at the top:** a disk that was
encrypted from first use is a disk you never have to think about at disposal. That is
a much better reason to enable full-disk encryption on everything than the laptop
theft scenario, because disposal happens to every disk and theft happens to a few.

</details>

## And one sentence on data in transit

Objective 3.5 pairs encryption at rest with encryption in transit, and the
named tool is **WireGuard**: a VPN built into the kernel, configured with a
handful of lines, and notable for having no cipher negotiation at all. The
algorithms are fixed, so there is no downgrade attack and no cipher suite to
misconfigure. TLS from lesson 48 covers the same ground for a single service;
WireGuard covers a whole network path.

## Across distributions

The tooling is the same everywhere. The packaging and boot integration differ.

| | RHEL family | Debian family |
| --- | --- | --- |
| Package | `cryptsetup` | `cryptsetup` |
| Installer option | "Encrypt my data" | "Guided, use entire disk and set up encrypted LVM" |
| Boot mapping | `/etc/crypttab` | `/etc/crypttab` |
| Network unlock | Clevis and Tang | Clevis and Tang, or `dropbear-initramfs` |
| TPM enrolment | `systemd-cryptenroll` | `systemd-cryptenroll` |

**Both installers default to LUKS on top of LVM**, which is the arrangement worth
knowing: one encrypted container holding a volume group, so there is one passphrase
rather than one per logical volume.

## Prove it

```
# Is this device encrypted at all
sudo blkid /dev/sdX
lsblk -f

# What is in the header, and how many slots are in use
sudo cryptsetup luksDump /dev/sdX

# What is open right now
ls /dev/mapper/
sudo cryptsetup status vault

# Back it up before you touch anything
sudo cryptsetup luksHeaderBackup /dev/sdX --header-backup-file luks-sdX.img

# And the one that proves it end to end
sudo cryptsetup close vault && sudo mount /dev/sdX /mnt
```

**That last pair is the real proof.** Close the volume and try to mount the raw
device. `unknown filesystem type 'crypto_LUKS'` is the encryption working, and it is
the answer you would give your manager about the stolen laptop.

## What trips people up

### 1. `mkfs` on the wrong device

The filesystem goes on `/dev/mapper/name`, never on the underlying device.
Formatting the underlying device destroys the header, and the header is the only
place the master key exists.

### 2. No header backup

Sixteen megabytes at the front of the disk are all that stand between you and
permanent, complete data loss. `luksHeaderBackup`, stored somewhere as protected as
the volume itself.

### 3. Believing `shred` works

It does not, on SSDs, on copy-on-write filesystems, on anything with snapshots, or on
network storage. Encrypt from day one and use `cryptsetup luksErase` at disposal.

### 4. One key slot

`luksKillSlot` on your only slot leaves data nobody can ever read. Keep an automation
key and a human key, and run `luksDump` before removing anything.

### 5. Expecting encryption to protect a running machine

Once the volume is open it is open to everything on the machine. Full-disk encryption
protects a powered-off disk. It does nothing about a compromised process, and it does
nothing about ransomware.

### 6. A key file on the unencrypted root

If the disk is stolen, so is the key file. Use a TPM, a network key server, or a
person.

## Work it through

A departing employee's laptop comes back. It has full-disk encryption and you do not
have the passphrase. The security team wants to know whether the data is recoverable,
and whether the machine can be reissued.

Reason it out before reading on.

**What is actually there:**

```
sudo lsblk -f
sudo cryptsetup luksDump /dev/nvme0n1p3
```

`TYPE="crypto_LUKS"` and a header with occupied slots confirms it is genuinely
encrypted. Now the answer splits on one question, and it is a policy question
rather than a technical one: **was a recovery key escrowed when the machine
was built?**

**If yes** (a slot holding an organisation-held key, enrolled at deployment)
you open it with that, take what you need, and reissue. This is the reason
enterprise deployments enrol a second slot on every machine, and the reason to
do it at build time rather than when you need it.

**If no**, the data is gone. Not "needs a specialist". The master key is a 512-bit
random value stored only in slots that need a passphrase you do not have, protected
by Argon2id with a memory cost that makes guessing impractical. There is no vendor
back door and no support ticket that recovers it. That is a correct answer to give,
and the honest follow-up is that the same property is exactly why the laptop was
encrypted.

Either way, reissuing the machine is easy:

```
sudo cryptsetup luksErase /dev/nvme0n1p3
```

One command wipes every slot, the payload becomes permanently unreadable, and
the disk can be repartitioned. Notice this is the *same* operation as secure
disposal. The data was made unrecoverable without overwriting a single byte of
it.

**And one variation worth reasoning through.** Suppose the laptop was not powered off
but suspended, and it arrives with the lid closed and the battery alive. Now the
master key is still in the kernel keyring, and anyone who can reach a shell has the
plaintext. That is a completely different situation from the same machine powered off,
and it is why "the disks are encrypted" is an incomplete answer to any question about
a device's state.

The point worth extracting: **encryption at rest is a statement about a
powered-off disk, and its strength is exactly what makes it unforgiving.** The
same property that defeats the thief defeats you when the key management is
wrong, so the interesting engineering is nearly all in key management: escrow,
slots, header backups, and where the unlock key lives.

## Try it

Optional, and use a spare device or a file-backed loop device, never a disk with data.

1. `truncate -s 512M /tmp/disk.img; sudo losetup -fP --show /tmp/disk.img`
2. `sudo cryptsetup luksFormat --type luks2 /dev/loopN`, and read the warning it
   gives you before typing `YES`.
3. `sudo cryptsetup luksDump /dev/loopN`. Find the offset, the cipher, and the PBKDF.
4. `sudo cryptsetup open /dev/loopN vault`, then `lsblk` and note the size difference.
5. `sudo mkfs.ext4 /dev/mapper/vault`, mount it, write a file.
6. Unmount, `sudo cryptsetup close vault`, and try to mount `/dev/loopN` directly.
   Read the error.
7. `sudo cryptsetup luksAddKey /dev/loopN`, then `luksDump` and count the slots.
8. `sudo cryptsetup luksHeaderBackup /dev/loopN --header-backup-file /tmp/hdr.img`,
   then `ls -l` it and note it is 16 MiB.
9. `sudo cryptsetup luksErase /dev/loopN`, then try to open it.
10. `sudo losetup -d /dev/loopN; rm /tmp/disk.img`

**Verification step.** You have it when you can say, without checking, which device
`mkfs` belongs on and why the other one would be a catastrophe.

## Check yourself

<details class="qa">
<summary>A laptop with an encrypted disk is stolen while powered off. A second one is stolen while suspended. Are these the same incident?</summary>

**No, and the difference is where the master key is.**

**Powered off**: the master key exists only inside the LUKS key slots,
encrypted under passphrases and protected by Argon2id. The disk presents a
header and material indistinguishable from noise: `mount` on it fails with
`unknown filesystem type 'crypto_LUKS'`. Most data protection regimes treat
this as no disclosure.

**Suspended**: the machine is nominally off and the volume is still open. The
master key is in the kernel keyring, `cryptsetup status` reports `key
location: keyring`, and the decrypted view still exists at `/dev/mapper/`.
Anybody who can get to a shell, by any means, reads plaintext. This is much
closer to a stolen *running* machine.

Hibernate is the third case and it behaves like powered off, provided swap is
encrypted: memory is written to swap and the machine genuinely powers down, so
the key leaves RAM.

The tempting wrong answer is that both are fine because both disks are encrypted. The
encryption is identical; the *state* is not, and the state is what decides.

The practical consequence: policy should be to hibernate or shut down rather than
suspend on machines carrying sensitive data, and that is a setting, not a technology.

</details>

<details class="qa">
<summary>Why does formatting the underlying device instead of <code>/dev/mapper/name</code> destroy the data permanently, when a backup of the files exists?</summary>

**Because it overwrites the LUKS header, and the header is the only place the master
key exists.**

The data is encrypted with a 512-bit random master key generated at `luksFormat` time.
That key is never shown to you and is stored only in the key slots, in the first
16 MiB of the device. Your passphrase does not encrypt the data; it unlocks a slot
containing a copy of that key.

Overwrite those 16 MiB and every copy of the master key is gone. The payload is still
there, unchanged, and permanently unreadable. No passphrase helps, because there is no
longer a slot to unlock.

**A backup of the files does help** (that is what backups are for) but the
question people actually mean is whether the *volume* is recoverable, and it
is not. The correct answer is to restore from backup onto a freshly created
volume.

**The preventive measure is `luksHeaderBackup`**, and it should be part of building any
encrypted volume rather than something you think about afterwards. Store it as
carefully as the disk: it contains every key slot, so the file plus any one passphrase
is equivalent to the disk.

The mistake itself is usually mundane, a `mkfs` or `dd` aimed at `/dev/sdb`
instead of `/dev/mapper/vault`, or an installer initialising what it thought
was a blank disk.

</details>

<details class="qa">
<summary>You need to securely delete a sensitive file from an SSD. Why is <code>shred</code> the wrong tool, and what is the right approach?</summary>

**Because `shred` assumes that writing to a file overwrites the physical blocks that
file occupied, and on an SSD that assumption is false.**

Wear levelling means the controller writes each new version to a *different*
physical cell and remaps the logical address. The original cells still hold
the original data and are simply no longer addressable from the operating
system, so `shred` writes three passes of noise somewhere else entirely and
reports success.

The same is true of any copy-on-write filesystem such as btrfs or ZFS, where not
overwriting in place is the whole design, of anything with snapshots holding old
blocks deliberately, and of network or virtual storage where you are not addressing
physical media at all.

**The right approach is cryptographic erase: destroy the key instead of the data.** On
a LUKS volume:

```
sudo cryptsetup luksErase /dev/sdX
```

Every key slot is wiped, the payload becomes permanently unreadable, and it takes about
a second regardless of disk size.

**Which means the real answer is earlier than the question.** Encrypt the disk
from the day it is deployed, and secure deletion is a metadata operation
forever after. For a disk that was never encrypted, the drive's own secure
erase, `nvme format --ses=1` or `hdparm --security-erase`, is a firmware
operation that can reach the cells wear levelling hid, with the caveat that
some vendors have implemented it badly.

</details>

<details class="qa">
<summary>A server must unlock its encrypted volume at boot with nobody present. Where does the key go, and what is wrong with the obvious answer?</summary>

**The obvious answer is a key file referenced from `/etc/crypttab`, and the problem is
where that file lives.**

On an unencrypted root filesystem, the key file is on the same disk as the
volume it unlocks, so a thief who takes the disk takes the key with it, and
the encryption has achieved nothing against the exact threat it exists for.

**The three real answers:**

**A TPM.** `systemd-cryptenroll --tpm2-device=auto` seals the key to the platform's
measured boot state. The chip releases it only if the firmware, bootloader, and kernel
match what was measured at enrolment, so the disk is unusable in another machine and a
tampered boot chain fails to unlock. This is why Secure Boot and disk encryption are
adjacent controls rather than alternatives.

A network key server. Clevis and Tang: the machine asks a server on the
internal network for its key at boot. A disk removed from the building cannot
be unlocked at all, and there is no secret stored on the client.

A person, over the network. `dropbear-initramfs` runs a small SSH server in
the initramfs so somebody can type the passphrase remotely. Simple and honest,
and it does not scale.

Whichever you choose, **enrol a second slot with a human-typeable passphrase**. A TPM
that fails after a firmware update, with no other slot, is an unbootable machine
holding unreachable data.

</details>

<details class="qa">
<summary>What is a key slot, and why does changing your passphrase not require re-encrypting the disk?</summary>

**A key slot holds a copy of the master key, encrypted with one passphrase.** LUKS
provides eight of them.

The data is encrypted with the master key, a 512-bit random value generated
once at format time. Your passphrase never touches the data. It is fed through
Argon2id to derive a key that decrypts one slot, yielding the master key,
which then decrypts the volume.

**So changing a passphrase rewrites one slot, a few kilobytes, in about a second.** The
master key is unchanged and the payload is never touched. Re-encrypting a 20 TB disk
would take a day; this is the indirection that avoids it.

It is also what allows several passphrases to open the same volume without any of them
knowing about the others, which is what makes escrow and automation keys possible.

**The cost of that design** is that the slots are the single point of failure: lose the
header and every copy of the master key goes with it. And `luksKillSlot` will remove
your last slot without complaint, leaving data nobody can read.

`luksDump` before removing anything, and keep two slots on anything that
matters, one for automation, one for a person.

</details>

## References

- [cryptsetup(8)](https://man7.org/linux/man-pages/man8/cryptsetup.8.html) - Linux man-pages project. Accessed 2026-08-08.
- [crypttab(5)](https://man7.org/linux/man-pages/man5/crypttab.5.html) - Linux man-pages project. Accessed 2026-08-08.
- [shred(1)](https://man7.org/linux/man-pages/man1/shred.1.html) - Linux man-pages project. Accessed 2026-08-08.
- [gpg(1)](https://manpages.debian.org/trixie/gpg/gpg.1.en.html) - Debian manpages. Accessed 2026-08-08.
- [RFC 9106: Argon2 Memory-Hard Function for Password Hashing and Proof-of-Work Applications](https://www.rfc-editor.org/rfc/rfc9106.html) - IETF. Accessed 2026-08-08.
- [cryptsetup Frequently Asked Questions](https://gitlab.com/cryptsetup/cryptsetup/-/wikis/FrequentlyAskedQuestions) - cryptsetup project. Accessed 2026-08-08.
- [WireGuard: fast, modern, secure VPN tunnel](https://www.wireguard.com/) - WireGuard. Accessed 2026-08-08.

The LUKS volume was created, opened, written to, closed, and erased on a real kernel
using a loop device, which behaves identically to a disk for this purpose. `$DEV0` in
those commands is the device path the capture harness provisioned; the real path
appears in the output. The Argon2 memory cost was set explicitly rather than
benchmarked, because the machine has 2 GiB of RAM. Blocks without a distribution and
architecture header are illustrative.
