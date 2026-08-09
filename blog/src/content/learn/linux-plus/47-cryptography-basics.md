---
title: "The machine checks your password without ever having stored it"
description: "Hashing is not encryption and there is no way back. What is actually in the shadow file, what a salt is for, why MD5 is broken for one thing and not another, and what a signature proves that a checksum cannot."
track: "linux-plus"
level: "working"
order: 480
objectives:
  - "Explain why hashing and encryption are different operations rather than two strengths of one"
  - "Decode a shadow password field into its algorithm, salt, and hash"
  - "Say what a salt defends against and what it does not"
  - "Choose between symmetric, asymmetric, and key agreement for a given job"
  - "Verify a signature and state what it proves that a checksum does not"
prerequisites: ["account-files-and-attributes"]
tags: ["linux", "linux-plus", "cryptography", "hashing", "openssl", "security"]
updated: 2026-08-08
draft: false
examObjectives:
  - exam: "xk0-006"
    domain: "3.0"
    objective: "3.5"
sources:
  - title: "crypt(5)"
    url: "https://manpages.debian.org/trixie/libcrypt-dev/crypt.5.en.html"
    publisher: "Debian manpages, libxcrypt"
    accessed: 2026-08-08
    tier: 1
  - title: "shadow(5)"
    url: "https://man7.org/linux/man-pages/man5/shadow.5.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-08
    tier: 1
  - title: "sha256sum(1)"
    url: "https://man7.org/linux/man-pages/man1/sha256sum.1.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-08
    tier: 1
  - title: "openssl-dgst(1ssl)"
    url: "https://manpages.debian.org/trixie/openssl/openssl-dgst.1ssl.en.html"
    publisher: "Debian manpages, OpenSSL"
    accessed: 2026-08-08
    tier: 1
  - title: "openssl-pkeyutl(1ssl)"
    url: "https://manpages.debian.org/trixie/openssl/openssl-pkeyutl.1ssl.en.html"
    publisher: "Debian manpages, OpenSSL"
    accessed: 2026-08-08
    tier: 1
  - title: "openssl-enc(1ssl)"
    url: "https://manpages.debian.org/trixie/openssl/openssl-enc.1ssl.en.html"
    publisher: "Debian manpages, OpenSSL"
    accessed: 2026-08-08
    tier: 1
  - title: "login.defs(5)"
    url: "https://man7.org/linux/man-pages/man5/login.defs.5.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-08
    tier: 1
  - title: "cryptsetup(8)"
    url: "https://manpages.debian.org/trixie/cryptsetup-bin/cryptsetup.8.en.html"
    publisher: "Debian manpages, cryptsetup"
    accessed: 2026-08-08
    tier: 1
  - title: "FIPS 203: Module-Lattice-Based Key-Encapsulation Mechanism Standard"
    url: "https://csrc.nist.gov/pubs/fips/203/final"
    publisher: "NIST"
    accessed: 2026-08-08
    tier: 1
  - title: "mkpasswd(1)"
    url: "https://manpages.debian.org/trixie/whois/mkpasswd.1.en.html"
    publisher: "Debian manpages, whois"
    accessed: 2026-08-08
    tier: 1
  - title: "RFC 2104: HMAC, Keyed-Hashing for Message Authentication"
    url: "https://www.rfc-editor.org/rfc/rfc2104.html"
    publisher: "IETF"
    accessed: 2026-08-08
    tier: 1
  - title: "Security hardening"
    url: "https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/10/html/security_hardening/index"
    publisher: "Red Hat"
    accessed: 2026-08-08
    tier: 1
  - title: "SHAttered: the first collision for full SHA-1"
    url: "https://shattered.io/"
    publisher: "CWI Amsterdam and Google Research"
    accessed: 2026-08-08
    tier: 2
symptoms:
  - symptom: "bad decrypt"
    anchor: "encryption-which-does-go-backwards"
  - symptom: "Signature Verification Failure"
    anchor: "what-a-signature-proves-that-a-checksum-does-not"
  - symptom: "How do I decrypt an MD5 hash"
    anchor: "1-decrypting-a-hash"
  - symptom: "New passwords hash as $y$ but the runbook says $6$"
    anchor: "across-distributions"
---

> **Before you read.** You type a password. Something on the machine compares it
> against whatever is on file for your account and either lets you in or does not.
>
> But the machine is not supposed to have your password on file. That is the one
> rule everybody has heard. And yet the comparison plainly happens, thousands of
> times a second, on machines whose administrators genuinely cannot tell you what
> your password is.
>
> **So what is in that file, and how does comparing against it work?**

What is stored is not the password. It is the **result** of pushing the password
through a function that runs easily in one direction and cannot be run in the
other, stored alongside the recipe for repeating the calculation.

Checking a password is therefore not a lookup. It is a **re-computation**:
take the password that was offered, read the algorithm and the salt out of the
stored field, run the same calculation on the offered password, and compare
the two results. Equal results mean equal inputs. Nothing anywhere held the
password, and nothing can recover it, which is why every system you have ever
used offers to *reset* a forgotten password and never to *tell* you it.

That one-way operation is hashing, and half the confusion in this subject comes
from filing it under "encryption". They are different operations with different
purposes, and the difference is not strength.

### Some words you will need

<dl class="terms">
<dt>plaintext</dt>
<dd>The readable thing, before anything is done to it. The opposite is ciphertext.</dd>
<dt>digest</dt>
<dd>The output of a hash function. Fixed length, whatever the input was. Also called a hash, a checksum, or a fingerprint.</dd>
<dt>salt</dt>
<dd>Random bytes mixed into a password before hashing, stored in the clear beside the result. Not a secret.</dd>
<dt>work factor</dt>
<dd>A deliberate cost setting that makes a password hash slow. Higher costs the attacker more than it costs you.</dd>
<dt>HMAC</dt>
<dd>A hash with a key mixed in, so only a holder of the key can produce or check it.</dd>
<dt>key pair</dt>
<dd>Two mathematically linked keys. One is published, one never leaves the machine that made it.</dd>
<dt>signature</dt>
<dd>A value produced with a private key that anybody holding the matching public key can check. Proves integrity and origin together.</dd>
<dt>collision</dt>
<dd>Two different inputs with the same digest. A hash function is broken when somebody can produce one on purpose.</dd>
<dt>AEAD</dt>
<dd>An encryption mode that authenticates as well as encrypts, so tampering is detected rather than decrypted into garbage. AES-GCM and ChaCha20-Poly1305 are the two you will meet.</dd>
<dt>key agreement</dt>
<dd>Two parties each combine their own private key with the other's public key and arrive at the same shared secret without transmitting it. Diffie-Hellman is the name.</dd>
<dt>forward secrecy</dt>
<dd>The property that a private key stolen later cannot decrypt traffic recorded earlier, because the session key was ephemeral and was destroyed.</dd>
<dt>pepper</dt>
<dd>A secret value mixed into every password hash and stored outside the database. Not a salt: it is one value for everybody, and it is secret.</dd>
</dl>

## What breaks without this

**You store something you cannot afford to store.** A password database that can
be turned back into passwords is a breach waiting for somebody else's timetable,
and the difference between that and a safe one is a design decision made once,
early.

**You reach for the wrong operation.** "Encrypt the passwords so we can recover
them" and "hash the file so nobody can read it" are both wrong, in opposite
directions, and both get proposed in real meetings.

**You trust a checksum that proves nothing.** A SHA-256 line published beside a
download, on the same server, over the same connection, is checked by exactly the
same people who could change it. Knowing why a *signature* is different is the
whole point of the second half of this topic.

**You keep a dead algorithm alive.** MD5 and SHA-1 still work, still ship, and
still appear in scripts. Knowing precisely which property broke, and which one
did not, is what separates a defensible answer from a repeated slogan.

## Two operations that look alike and are not

<figure class="learn-figure">
<svg viewBox="0 0 720 330" role="img" aria-labelledby="cr-title cr-desc" style="width:100%;height:auto;">
  <title id="cr-title">Hashing runs one way only; encryption runs both ways with a key</title>
  <desc id="cr-desc">The top row is hashing. An input of any size enters a hash function such as SHA-256 and a digest of fixed length comes out, sixty-four hexadecimal characters for SHA-256 regardless of whether the input was one byte or ten megabytes. The return path is drawn crossed out, because no operation exists that takes a digest back to its input. The bottom row is encryption. Plaintext enters a cipher such as AES together with a key and ciphertext comes out at roughly the same size, and running the same key in the other direction returns the original plaintext exactly. The difference between the two rows is not strength. Hashing has no reverse operation at all, while encryption is defined by having one.</desc>
  <g font-family="ui-monospace, monospace">
    <rect x="18" y="34" width="170" height="62" rx="5" fill="currentColor" fill-opacity="0.12" stroke="currentColor" stroke-opacity="0.4"/>
    <text x="103" y="60" text-anchor="middle" font-size="12" fill="currentColor">any input</text>
    <text x="103" y="80" text-anchor="middle" font-size="9.5" fill="currentColor" fill-opacity="0.65">one byte or ten megabytes</text>
    <rect x="252" y="34" width="150" height="62" rx="5" fill="currentColor" fill-opacity="0.07" stroke="currentColor" stroke-opacity="0.3"/>
    <text x="327" y="60" text-anchor="middle" font-size="12" fill="currentColor">SHA-256</text>
    <text x="327" y="80" text-anchor="middle" font-size="9.5" fill="currentColor" fill-opacity="0.65">a hash function</text>
    <rect x="466" y="34" width="236" height="62" rx="5" fill="currentColor" fill-opacity="0.12" stroke="currentColor" stroke-opacity="0.4"/>
    <text x="584" y="60" text-anchor="middle" font-size="12" fill="currentColor">64 hex characters</text>
    <text x="584" y="80" text-anchor="middle" font-size="9.5" fill="currentColor" fill-opacity="0.65">always, whatever went in</text>
    <text x="344" y="154" text-anchor="middle" font-size="10" fill="currentColor" fill-opacity="0.8">no operation computes this direction</text>
    <rect x="18" y="190" width="170" height="62" rx="5" fill="currentColor" fill-opacity="0.12" stroke="currentColor" stroke-opacity="0.4"/>
    <text x="103" y="216" text-anchor="middle" font-size="12" fill="currentColor">plaintext</text>
    <text x="103" y="236" text-anchor="middle" font-size="9.5" fill="currentColor" fill-opacity="0.65">the file you have</text>
    <rect x="252" y="190" width="150" height="62" rx="5" fill="currentColor" fill-opacity="0.07" stroke="currentColor" stroke-opacity="0.3"/>
    <text x="327" y="216" text-anchor="middle" font-size="12" fill="currentColor">AES-256</text>
    <text x="327" y="236" text-anchor="middle" font-size="9.5" fill="currentColor" fill-opacity="0.65">a cipher, plus a key</text>
    <rect x="466" y="190" width="236" height="62" rx="5" fill="currentColor" fill-opacity="0.12" stroke="currentColor" stroke-opacity="0.4"/>
    <text x="584" y="216" text-anchor="middle" font-size="12" fill="currentColor">ciphertext</text>
    <text x="584" y="236" text-anchor="middle" font-size="9.5" fill="currentColor" fill-opacity="0.65">roughly the same size</text>
    <text x="344" y="308" text-anchor="middle" font-size="10" fill="currentColor" fill-opacity="0.8">the same key, run the other way, returns it exactly</text>
  </g>
  <g stroke="currentColor" stroke-opacity="0.45" fill="none" stroke-width="1.2">
    <path d="M190 65 L248 65 M242 61 L249 65 L242 69"/>
    <path d="M404 65 L462 65 M456 61 L463 65 L456 69"/>
    <path d="M190 221 L248 221 M242 217 L249 221 L242 225"/>
    <path d="M404 221 L462 221 M456 217 L463 221 L456 225"/>
    <path d="M584 256 L584 288 L103 288 L103 258 M99 264 L103 257 L107 264"/>
  </g>
  <g stroke="currentColor" stroke-opacity="0.35" fill="none" stroke-width="1.2" stroke-dasharray="4 4">
    <path d="M584 100 L584 128 L103 128 L103 100"/>
  </g>
  <g stroke="currentColor" stroke-opacity="0.6" fill="none" stroke-width="1.4">
    <path d="M336 120 L352 136 M352 120 L336 136"/>
  </g>
</svg>
<figcaption>Hashing and encryption are not two strengths of one idea. One has no reverse operation at all; the other is defined by having one.</figcaption>
</figure>

Written out as a table, because the exam and most interviews want it that way:

| | Hashing | Encryption |
| --- | --- | --- |
| Reversible | **No.** No operation exists. | **Yes.** That is the point. |
| Needs a key | No | Yes |
| Output size | Fixed, whatever the input | Roughly the input size |
| Answers | "Is this the same thing as before?" | "Can I get the original back?" |
| Used for | Passwords, integrity, signatures | Files, disks, network traffic |
| Wrong tool when | You need the data back | You must never get the data back |

**"Decrypt this hash" is not a hard problem, it is not a problem at all.** There
is no operation with that signature. Sites offering to reverse an MD5 are running
a lookup table of things somebody already hashed; give them a digest of something
nobody has hashed before and they have nothing.

## What a hash actually promises

Four properties, and each of them is doing a specific job.

**Deterministic.** The same input gives the same digest, on any machine, in any
year, in any implementation. Without this a password could never be checked twice.

**Fixed length.** A digest is a fixed number of bits no matter how large the
input was.

**Avalanche.** A one-bit change to the input changes about half the output bits,
and the change is not localised, ordered, or predictable.

**Preimage resistance.** Given a digest, there is no practical way to find an
input that produces it, other than guessing inputs and hashing them.

The first and third are visible in one command, and they are worth predicting
before reading.

<details class="predict">
<summary>Two of these three inputs are byte-for-byte identical, and the third differs from them by exactly one letter near the end. Given determinism and avalanche, how many leading characters of the third digest will match the first?</summary>

```bash
# Debian 13 (trixie), x86_64
$ echo -n hello | sha256sum; echo -n hello | sha256sum; echo -n hellp | sha256sum
2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824  -
2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824  -
fdd7585e08c4e2afd71dcabdb4636c89d557a3f42db9e2040c8bbd1708aa4ce7  -
```

</details>

The first two lines are identical, which is determinism. The third shares
nothing with them (not a prefix, not a pattern, not a length difference) which
is avalanche. `hello` and `hellp` are neighbours; `2cf24dba...` and
`fdd7585e...` are not.

**This is why a digest is useless as an approximate comparison.** "The hashes are
nearly the same, so the files are nearly the same" is not a sentence anybody can
say. Digests are equal or they are unrelated, and there is no third case.

Fixed length is equally easy to see, and more surprising:

```bash
# Debian 13 (trixie), x86_64
$ ls -l /tmp/big; sha256sum /tmp/big; echo -n hi | sha256sum
-rw-r--r--. 1 root root 10000000 Aug  8 16:50 /tmp/big
b4de47e75c706647957e18540b96f94fa8c03847e801a882b5f1420cd35ecd04  /tmp/big
8f434346648f6b96df89dda901c5176b10a6d83961dd3c1ac88b59b2dc327aa4  -
```

**Ten million bytes and two bytes produce the same amount of output.** SHA-256
gives 256 bits, written as 64 hexadecimal characters, always. That is what makes
a digest a usable identifier: you can put one in a database column, print it on a
release page, or compare a million of them without knowing anything about what
was hashed.

It also tells you something that people find uncomfortable at first. There are
more possible ten-megabyte files than there are 256-bit digests, so collisions
must exist mathematically. The claim a hash function makes is not that they do
not exist; it is that nobody can find one.

The digest belongs to the input, not to the tool. Two different programs, same
answer:

```bash
# Debian 13 (trixie), x86_64
$ cat /tmp/file; sha256sum /tmp/file; openssl dgst -sha256 /tmp/file
the quick brown fox jumps over the lazy dog
1153a4080f1fcb04425aa0b841c2b14606fe6df25d9076d2a1face2d5af57129  /tmp/file
SHA2-256(/tmp/file)= 1153a4080f1fcb04425aa0b841c2b14606fe6df25d9076d2a1face2d5af57129
```

Note that OpenSSL 3 calls it `SHA2-256` rather than `SHA-256`, which is the
formally correct family name and occasionally makes people think they have
computed something different. They have not. And a third tool, formatting it
differently again:

```bash
# Debian 13 (trixie), x86_64
$ echo -n hello | gpg --print-md SHA256
2CF24DBA 5FB0A30E 26E83B2A C5B9E29E 1B161E5C 1FA7425E 73043362 938B9824
```

**Uppercase, split into eight groups, same 64 characters.** `gpg --print-md` is
formatting for humans reading a fingerprint aloud. Presentation differences like
this cause more "the checksums do not match" reports than actual mismatches do.

## The family, and the number in the name

The number is the digest length in bits, and that is nearly all it means:

```bash
# Debian 13 (trixie), x86_64
$ echo -n hello | md5sum; echo -n hello | sha256sum; echo -n hello | sha512sum
5d41402abc4b2a76b9719d911017c592  -
2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824  -
9b71d224bd62f3785d96d46ad3ea3d73319bfbc2890caadae2dff72519673ca72323c3d99ba5c11d7c7acc6e14b8c5da0c4663475c2e5c3adef46f73bcdec043  -
```

| Algorithm | Digest bits | Hex characters | Use it |
| --- | --- | --- | --- |
| MD5 | 128 | 32 | No |
| SHA-1 | 160 | 40 | No |
| SHA-224 | 224 | 56 | Rarely |
| **SHA-256** | 256 | 64 | Yes, the default choice |
| SHA-384 | 384 | 96 | Yes |
| **SHA-512** | 512 | 128 | Yes. Faster than SHA-256 in software, slower where the CPU accelerates SHA-256 |
| SHA3-256, SHA3-512 | 256, 512 | 64, 128 | Yes, a different internal design |
| BLAKE2 | up to 512 | varies | Yes, when speed matters |

**SHA-2 is the family, and SHA-256 and SHA-512 are members of it.** SHA-3 is not
a bigger SHA-2; it is a completely different construction, standardised in 2015
as insurance in case a structural weakness were ever found in SHA-2. None has
been. Both are current.

The counter-intuitive row is SHA-512. In pure software it is *faster* than
SHA-256 despite the longer output, because it works on 64-bit words and gets
through more input per round. That was the standing advice for years, and
hardware has since complicated it: the x86 SHA-NI instructions accelerate SHA-1
and SHA-256 and originally did not cover SHA-512 at all, so on most server CPUs
shipped since about 2017 the shorter digest is the quicker one. **Do not repeat
either version of the claim about a specific machine without measuring it**;
`openssl speed sha256 sha512` settles it in under a minute on the machine that
matters. If you need one digest for general use and have no other constraint,
either is defensible, and SHA-256 wins on how many other systems expect exactly
64 characters.

Nothing removed the old ones from the toolbox:

```bash
# Debian 13 (trixie), x86_64
$ openssl dgst -list | head -4
Supported digests:
-blake2b512                -blake2s256                -md4                      
-md5                       -md5-sha1                  -ripemd                   
-ripemd160                 -rmd160                    -sha1                     
```

`md4`, `md5`, and `sha1` are all still there and still work. **Availability is
not endorsement.** The library implements what the world's existing files and
protocols contain; deciding what this machine will *accept* is a policy question
handled somewhere above the library, which is the last section of this topic.

<details class="deeper">
<summary>If you already administer Linux: collision resistance and preimage resistance are different properties, and only one of them broke</summary>

"MD5 is broken" is true and almost always repeated imprecisely, in a way that
produces wrong answers on exams and worse ones in design reviews.

There are three separate claims a hash function makes, in increasing order of
difficulty for the attacker:

| Property | The attacker is given | And must find | Broken for MD5? | For SHA-1? |
| --- | --- | --- | --- | --- |
| Collision resistance | Nothing | Any two inputs with the same digest | **Yes** | **Yes** |
| Second-preimage resistance | One input | A different input with the same digest | No | No |
| Preimage resistance | A digest | Any input producing it | No | No |

**What broke is the easiest one.** Nobody can take an MD5 digest and recover the
input. What they can do is construct, in advance, two documents of their own
choosing that share a digest. MD5 collisions became practical in the mid-2000s.
SHA-1 followed in two steps worth keeping separate: the SHAttered work in
February 2017 produced the first *identical-prefix* collision, two PDFs that had
to share a common opening block, and in January 2020 the "SHA-1 is a Shambles"
work produced a *chosen-prefix* collision, where the two colliding documents can
begin with arbitrary attacker-selected content. Only the second one lets an
attacker collide two documents that a victim would plausibly have written, which
is why the certificate and PGP fallout landed in 2020 rather than 2017.

**That distinction decides which of your systems care.** Collision resistance
is what a signature depends on: if I can produce two documents with one
digest, I can get you to sign the harmless one and attach your signature to
the other, because the signature only ever covered the digest. So
certificates, package signatures, commit signatures, and code signing all
break. This is not theoretical, the Flame malware in 2012 used an MD5
chosen-prefix collision to forge a Microsoft code-signing certificate.

Now the case that surprises people. **A password hash does not depend on
collision resistance at all.** The attacker holding your `/etc/shadow` is not
trying to find two inputs that collide; they are trying to find the one input you
chose, which is a preimage problem, and MD5's preimage resistance is intact. So
`$1$` MD5-crypt hashes are not "reversible", and anybody who tells you they are
is wrong.

They are still terrible, for a completely different reason: MD5 is *fast*, and
speed is the enemy in a password hash. That is the next panel.

The practical fallout worth carrying: a checksum for detecting accidental
corruption can still use anything, because bit rot does not construct collisions.
A checksum standing in for a security decision cannot. ZFS defaulting to
`fletcher4`, which is not a cryptographic hash at all, is fine for the job it is
doing. A vendor publishing MD5 next to a download is not.

Note the third row of that table, because an exam question turns on it.
**Second-preimage resistance is a different and harder problem than collision
resistance**, and it is intact for both MD5 and SHA-1. An attacker cannot take
your existing signed document and manufacture a different one with the same
digest. They have to have controlled *both* documents from the start, which is
why the realistic attack is always "get the victim to sign something the
attacker prepared" rather than "forge a collision with something already
signed".

</details>

## Back to the password

Everything above now cashes out. Create a user, set a password, and look at what
landed on disk:

```bash
# Debian 13 (trixie), x86_64
$ useradd -m demo; echo 'demo:hunter2' | chpasswd; grep '^demo:' /etc/shadow
demo:$y$j9T$2z.ahBivOfVZwYyB/1NIL0$QPvE5jjyobfJpdMopFl4C9cBhwH66szvFai9D2jNan6:20673:0:99999:7:::
```

The second colon-separated field is the whole answer, and it has four parts of its
own, separated by more dollar signs:

```
$y$j9T$2z.ahBivOfVZwYyB/1NIL0$QPvE5jjyobfJpdMopFl4C9cBhwH66szvFai9D2jNan6
 |   |            |                             |
 |   |            |                             the hash itself
 |   |            the salt, stored in the clear
 |   the algorithm's cost parameters
 the algorithm: y is yescrypt
```

**Read that as a recipe, not as a secret.** Three of the four fields are
instructions for repeating the calculation, and they are deliberately readable.
Only the last field is the output. When `demo` types a password, the login stack
reads `y`, reads `j9T`, reads the salt, runs yescrypt over the offered password
with exactly those settings, and compares the result to the last field. Equal
means the same password was typed. Nothing was decrypted, because there was
nothing to decrypt.

The leading identifier is worth memorising, because it is the fastest audit you
can run on an inherited machine:

| Prefix | Algorithm | Verdict |
| --- | --- | --- |
| no `$`, 13 characters | DES crypt | Ancient. Silently truncates at 8 characters. |
| `$1$` | MD5-crypt | Retired. Fast, which is the problem. |
| `$2a$`, `$2b$`, `$2y$` | bcrypt | Fine. Cost in the next field. |
| `$5$` | SHA-256-crypt | Acceptable |
| `$6$` | SHA-512-crypt | Acceptable. The RHEL default through RHEL 9. |
| `$7$` | scrypt | Good |
| `$y$` | yescrypt | Current best default |
| `$gy$` | gost-yescrypt | Yescrypt with the Russian GOST hash |
| `!` or `*` at the front | Not an algorithm | The account cannot authenticate with a password |

That last row is the one that catches people, and it links straight back to
lesson 28: a `!` prefix is how `usermod -L` locks an account, and `*` is what a
system account with no password ever set looks like.

Now the salt, which is the part most explanations get wrong. Same password, two
salts chosen by hand so you can see what varies:

<details class="predict">
<summary>The rule: the salt is mixed with the password before hashing, and it is stored in the clear right next to the result. Both of these hash the identical password `hunter2` with SHA-512-crypt. How much of the two outputs will be the same?</summary>

```bash
# Debian 13 (trixie), x86_64
$ openssl passwd -6 -salt abcdefgh 'hunter2'; openssl passwd -6 -salt zyxwvuts 'hunter2'
$6$abcdefgh$M/eYsB4rVXAm3ZNc88J.UD9rCKAT6FB1rahiwJCHtEndQNORCub5qhjxn50qbqVVthkM.9HpEwtf0t.iV9uH0/
$6$zyxwvuts$zC.zWoufBLT293YNjAHSR04HNWS8v9KTM9kVGc6Nnw7v7GsNahLSG0Ye5Y909iT3BTAWFZuW2FAf4KpvjVjap.
```

</details>

**The same password, twice, and the two results have nothing in common.** The
salt you can see, `abcdefgh` and `zyxwvuts`, is right there in the output,
readable by anybody who can read the file.

And because the salt is part of the recipe rather than part of the secret, the
recipe travels. Here is the first of those two commands run on a completely
different distribution:

```bash
# AlmaLinux 10.2, x86_64
$ openssl passwd -6 -salt abcdefgh 'hunter2'
$6$abcdefgh$M/eYsB4rVXAm3ZNc88J.UD9rCKAT6FB1rahiwJCHtEndQNORCub5qhjxn50qbqVVthkM.9HpEwtf0t.iV9uH0/
```

**Character for character identical**, on a different distribution, a different
libcrypt build, and a different OpenSSL. That is determinism doing its job:
`$6$` plus that salt plus `hunter2` has exactly one answer everywhere, which is
what makes it possible to move an `/etc/shadow` between machines and have
everybody still able to log in.

That is not a mistake. **A salt is not a secret and was never intended to be
one.** Its job is narrow and specific:

- **It defeats precomputation.** An attacker cannot compute a table of hashes for
  the ten million most common passwords once and then use it against every
  account in the world, because every account salts differently. The table would
  have to be rebuilt per salt, which is the same work as attacking that one
  account directly.
- **It breaks cross-account comparison.** Without a salt, two users with the same
  password have the same stored hash, so a leaked database instantly reveals
  which accounts share a password, and cracking one cracks all of them.

And equally important, what a salt does **not** do:

- **It does not slow down an attack on one specific password.** The attacker has
  the salt. Guessing against a single account costs exactly the same salted or
  not. Only the *work factor* changes that, which is the next panel.
- **It does not need to be secret, long, or memorable.** It needs to be unique
  per password and unpredictable. Sixteen random characters is plenty.

Real tools do not let you choose the salt, and that is a feature:

```bash
# Debian 13 (trixie), x86_64
$ mkpasswd -m yescrypt 'hunter2'; mkpasswd -m yescrypt 'hunter2'
$y$j9T$Wc3qWDOFQwNl7amE7qiai1$WLDSZvBu3SkAZzCbBOzReQf/aENO1rAJXbKl8KAGeZ6
$y$j9T$rxoJ3uhaCDZXnmPqGz0hH.$NwT6CJPzPQUkO8CC8Derznsd6KouWRQqiLiyvGtD.a9
```

Same password, two runs, two completely different results, because a fresh random
salt was generated each time. **A useful consequence: you cannot compare two
password hashes to see whether two people chose the same password.** Even your
own hash from five minutes ago will not match the one you generate now.

What algorithms a machine actually offers is a property of its C library, not of
your imagination:

```bash
# Debian 13 (trixie), x86_64
$ mkpasswd -m help | head -12
Available methods:
yescrypt        Yescrypt
gost-yescrypt   GOST Yescrypt
scrypt          scrypt
bcrypt          bcrypt
bcrypt-a        bcrypt (obsolete $2a$ version)
sha512crypt     SHA-512
sha256crypt     SHA-256
sunmd5          SunMD5
md5crypt        MD5
bsdicrypt       BSDI extended DES-based crypt(3)
descrypt        standard 56 bit DES-based crypt(3)
```

`mkpasswd -m help` is asking libcrypt what it supports. The obsolete entries are
listed because old `/etc/shadow` files still contain them and have to keep
verifying; that is a completely different question from what a new password
should be created with, which `/etc/login.defs` decides.

<details class="deeper">
<summary>If you already administer Linux: work factors, and why a password hash must be slow while a file hash must be fast</summary>

Every property in this topic so far has been about correctness. Password hashing
adds one that is about economics, and it is the only place in computing where
"deliberately slow" is the specification.

**The threat model is offline guessing.** Somebody has the hash file. Rate
limiting, lockout, and monitoring are all on the other side of a wall they are no
longer standing behind. Their only limit is how many candidate passwords per
second their hardware can test, so that number *is* your security margin.

Raw SHA-256 was designed to be fast, and hardware has obliged. A current
high-end GPU tests raw SHA-256 candidates at the order of tens of billions per
second. The same GPU against bcrypt at cost 12 manages something in the low
thousands. The exact numbers move every year; the ratio, roughly seven orders
of magnitude, does not. That is the entire argument for a purpose-built
password hash, and it is why `sha256sum` is the wrong tool for the job it
looks perfect for.

**How each algorithm buys slowness matters, because they buy different things:**

| Algorithm | Cost knob | Also expensive in | Notes |
| --- | --- | --- | --- |
| SHA-512-crypt (`$6$`) | `rounds=`, default 5000 | Nothing | CPU only, so GPUs still win big |
| bcrypt (`$2b$`) | cost, log2 of iterations | A little memory | Cost 12 means 4096 iterations |
| scrypt (`$7$`) | N, r, p | **Memory** | Memory-hard by design |
| yescrypt (`$y$`) | encoded in the parameter field | **Memory** | The default on current Debian, Fedora, and RHEL 10 |
| Argon2id | time, memory, parallelism | **Memory** | Password Hashing Competition winner, 2015 |

**Memory-hardness is the lever that actually hurts an attacker.** A GPU has
thousands of cores and comparatively little memory per core, and an ASIC is worse
still. An algorithm that insists on holding tens of megabytes per guess makes the
attacker's parallelism collapse, which is why every modern choice on that list is
memory-hard and SHA-512-crypt is not.

Three operational consequences people miss.

**bcrypt silently truncates the password at 72 bytes.** Everything past that is
discarded before hashing, so a 200-character passphrase is exactly as strong as
its first 72 characters, and two passphrases sharing a 72-byte prefix are the
same password as far as the check is concerned. It is the same class of mistake
as DES crypt's 8-character limit, three decades later and still shipping. The
usual fix is to pre-hash with SHA-256 and base64 the result before handing it to
bcrypt; the usual bug is doing that wrong. yescrypt and Argon2id have no such
limit, which is one more reason to prefer them.

Raising the cost does not re-hash existing passwords. Change
`SHA_CRYPT_MIN_ROUNDS` in `/etc/login.defs`, or move a web application from
bcrypt cost 10 to cost 12, and every stored hash keeps its old parameters
forever, because the parameters live in the stored string. Well-written login
code checks the parameters at verify time and silently re-hashes with the
current settings while it still has the plaintext in hand. That is the only
moment it ever will.

And you tune it against your own hardware, not a blog post. The number you
want is the largest cost your login path can absorb without users noticing.
Around 100 milliseconds is the conventional target for an interactive login;
higher for something logged into rarely. Lesson 49's LUKS2 does exactly this
automatically: `cryptsetup` benchmarks Argon2id on the machine at format time
and picks parameters that hit its `--iter-time`, which defaults to 2000
milliseconds, so a slow laptop and a fast server end up with equal *time* cost
rather than equal *iteration* cost. The consequence is that a LUKS header
formatted on a fast workstation and then moved to a small ARM board can take
an uncomfortably long time to unlock, because the cost baked into the header
was measured somewhere else.

</details>

## A hash with a key

A plain digest has one weakness that has nothing to do with the algorithm:
**anybody can compute it.** If an attacker changes a file, they can recompute the
digest and change that too. A digest proves the file has not changed by accident.
It proves nothing about deliberate change unless the digest itself is protected.

Mixing a secret key into the hash fixes that:

```bash
# Debian 13 (trixie), x86_64
$ openssl dgst -sha256 -hmac 'secretkey' /tmp/file; openssl dgst -sha256 -hmac 'secretkez' /tmp/file
HMAC-SHA2-256(/tmp/file)= da49116d0645e941f1bd30cbd6ba6004bc84accab5b615a1de3aab06525713c4
HMAC-SHA2-256(/tmp/file)= a11b23e3ee12b6a6b6e5e07c32430ec3ace4ab30e46730bbdeea7e46271960fc
```

**The same file, the same algorithm, two keys differing by one character, and
two unrelated results.** Anybody holding `secretkey` can produce or check that
value. Anybody who does not, cannot, not by trying, not by being clever about
the file.

That is HMAC, and it is everywhere once you know the name: AWS request signing,
a JWT with `alg: HS256`, the RADIUS `Message-Authenticator` attribute, IPsec
integrity, the record MAC in TLS 1.2's CBC suites, and HKDF, the key derivation
step inside TLS 1.3, which is built entirely out of HMAC. Whenever two parties
already share a secret and need to know a message was not altered in transit,
HMAC is the answer, and it is far cheaper than a signature.

**HMAC does not need a strong hash underneath it.** HMAC-MD5 has no practical
break even now, because HMAC's security rests on the key rather than on
collision resistance, and RADIUS still uses it. That is a genuinely surprising
result and the exam will not ask you to defend it; do not use it as an argument
for keeping MD5 anywhere else.

**HMAC is not the key glued onto the front of the message.** It hashes
twice, with the key mixed in differently each time. The reason is a real property
of the SHA-2 family called length extension: given `sha256(secret + message)` and
the length of `secret`, an attacker can compute `sha256(secret + message + extra)`
for content of their choosing, without ever knowing the secret. The naive
construction is therefore forgeable, the nested one is not, and this is a
mistake that has shipped in production APIs more than once. Use `-hmac`, or your
language's HMAC function, rather than concatenating anything yourself.

## Encryption, which does go backwards

Now the other operation. Encrypt a file with a password:

```bash
# Debian 13 (trixie), x86_64
$ openssl enc -aes-256-cbc -pbkdf2 -in /tmp/plain -out /tmp/cipher -pass pass:demo; ls -l /tmp/plain /tmp/cipher; xxd /tmp/cipher | head -3
-rw-r--r--. 1 root root 64 Aug  8 17:05 /tmp/cipher
-rw-r--r--. 1 root root 47 Aug  8 17:05 /tmp/plain
00000000: 5361 6c74 6564 5f5f 21c0 7425 d63e 483c  Salted__!.t%.>H<
00000010: 7ea0 a0c3 faf9 e3f6 e31e 3985 fffc f1f5  ~.........9.....
00000020: 62ae 7061 2c50 e34f e7ec 964a 0d61 4cad  b.pa,P.O...J.aL.
```

Three things to read there. The output is **binary**, not text: `xxd` is
showing bytes that are not characters. It begins with the literal string
`Salted__` followed by the random salt OpenSSL generated, which is that same
idea again: the salt is stored in the clear with the ciphertext because
decryption needs it. And 47 bytes of plaintext became 64 bytes of ciphertext:
8 bytes of magic plus the 8-byte salt for the header, then the plaintext
padded up from 47 to the next multiple of the 16-byte AES block, which is 48.

**`-pbkdf2` is not optional decoration.** A password is not a key, and something
has to turn one into the other. With `-pbkdf2` OpenSSL runs PBKDF2-HMAC-SHA256
over the password and salt, 10000 iterations by default and settable with
`-iter`. Leave the flag off and it silently falls back to `EVP_BytesToKey`, a
single-pass MD5 construction from the 1990s with no cost parameter at all, and
you get a warning-free file that a GPU chews through. This is the same work
factor argument as `/etc/shadow`, appearing in a completely different command,
and the flag is the whole difference.

The whole point is that it comes back:

```bash
# Debian 13 (trixie), x86_64
$ openssl enc -d -aes-256-cbc -pbkdf2 -in /tmp/cipher -out /tmp/back -pass pass:demo; diff /tmp/plain /tmp/back && echo 'round trip identical'
round trip identical
```

**`diff` says the files are identical.** That is the difference from hashing
stated as plainly as it can be: the original is recoverable, exactly, given the
key. With the wrong key it is not:

```bash
# Debian 13 (trixie), x86_64
$ openssl enc -d -aes-256-cbc -pbkdf2 -in /tmp/cipher -out /tmp/back -pass pass:wrongpw; echo "exit $?"
bad decrypt
40E7089AFFFF0000:error:1C800064:Provider routines:ossl_cipher_unpadblock:bad decrypt:../providers/implementations/ciphers/ciphercommon_block.c:107:
exit 1
```

`bad decrypt` and exit status 1. Worth being precise about **why** that error
appeared, because it is a trap: OpenSSL decrypted the data with the wrong key,
got garbage, and then noticed the padding at the end of the garbage was not
valid padding. It is a *coincidence detector*, not an integrity check. Roughly one
wrong key in 256 produces plausible padding and no error at all, handing you
garbage silently.

That is a property of AES-CBC, which encrypts and nothing more. **An AEAD mode
such as AES-GCM builds authentication in**, so a wrong key or a tampered
ciphertext fails loudly and always. When you get to choose, choose one of those;
when you inherit CBC, do not treat a successful decrypt as proof of anything.

**Symmetric encryption means one key does both directions.** It is fast, AES
has had dedicated CPU instructions since 2010, which is why it does all the
bulk work: LUKS volumes in lesson 49, TLS session traffic in lesson 48,
encrypted backups, everything large.

The names worth recognising, because a question will list four of them and ask
which one you would not deploy:

| Cipher | Key sizes | Verdict |
| --- | --- | --- |
| **AES** | 128, 192, 256 | The default everywhere. `aes-256-xts` for disks, `aes-256-gcm` for traffic |
| **ChaCha20-Poly1305** | 256 | An AEAD stream cipher. Preferred where there is no AES hardware, notably phones and small routers |
| 3DES | 112 effective | Retired. 64-bit blocks make it fail on large transfers, not just slow |
| Blowfish | up to 448 | Superseded by AES. Its key schedule survives inside bcrypt, which is a different thing |
| DES, RC4 | 56, varies | Broken. If you meet either, you are reading a compliance finding |

Two words attached to those that the exam does test. A **block cipher** such
as AES transforms fixed-size blocks and therefore needs a **mode** to handle
anything longer (CBC, CTR, GCM, XTS) and the mode is where most of the real
security decisions live, which is why `aes-256-cbc` and `aes-256-gcm` behave
so differently a few paragraphs above. A **stream cipher** such as ChaCha20
produces a keystream and needs no padding at all.

Symmetric encryption's problem is not mathematical. It is that both parties must
already have the same key, and getting it to them is the hard part.

## Two keys instead of one

Asymmetric cryptography solves exactly that problem. Generate two mathematically
linked keys and publish one of them:

```bash
# Debian 13 (trixie), x86_64
$ openssl genpkey -algorithm ed25519 -out /tmp/priv.pem; openssl pkey -in /tmp/priv.pem -pubout -out /tmp/pub.pem; cat /tmp/pub.pem
-----BEGIN PUBLIC KEY-----
MCowBQYDK2VwAyEADUIppu4jzHsHQt4ek66Js7tdYaLzUbZgiuF5FzGLEfQ=
-----END PUBLIC KEY-----
```

The whole public key is that one line of base64 between two delimiters (a
32-byte Ed25519 key plus its algorithm identifier, wrapped in PEM) and it can
go anywhere: a web page, a DNS record, a certificate. **The private key stays
in `/tmp/priv.pem` and never leaves the machine.** Everything asymmetric rests
on that single asymmetry of *distribution*, not of mathematics.

One practical wrinkle, because it wastes an afternoon the first time. That PEM is
**not** what `~/.ssh/authorized_keys` wants. SSH carries the same 32 bytes in its
own single-line `ssh-ed25519 AAAAC3Nza...` encoding, and nothing converts between
the two implicitly. Two encodings, one key, two toolchains: generate SSH keys with
`ssh-keygen -t ed25519` and keep `openssl genpkey` for signing and certificate
work.

The keys do two different jobs, and the direction reverses between them. This is
the table people misremember, so read it twice:

| Operation | Done with | Undone with | Proves |
| --- | --- | --- | --- |
| Encrypt to somebody | Their **public** key | Their **private** key | Only they can read it |
| Sign something | Your **private** key | Your **public** key | Only you could have sent it |

**Both rows use both keys, in opposite orders**, and that inversion is the single
most common confusion in the subject. The way to keep it straight is to ask what
the property is protecting. Confidentiality means *anybody* may lock it and only
one person may open it, so the lock is the published key. Authenticity means only
one person may produce it and *anybody* may check it, so the production step is
the private one.

Asymmetric operations are slow and size-limited (an RSA-2048 key cannot
encrypt more than about 245 bytes in one operation, and Ed25519 cannot encrypt
at all) so nothing large is ever encrypted with them directly.

### The third operation, which is the one actually in use

There is a row missing from that table, and it is the row that runs every time
you open a web page. **Key agreement** takes two key pairs and produces a shared
secret that neither side transmitted:

| Operation | Each side uses | Result | Named |
| --- | --- | --- | --- |
| Agree a key | Their own private key and the other side's public key | The same shared secret on both sides, never sent over the wire | Diffie-Hellman; `ECDHE` in a TLS cipher suite |

Nobody encrypted the key and sent it. Both sides computed it, and an observer who
recorded every byte of the exchange cannot compute it. That secret then becomes
the AES key, and the connection switches to symmetric work for everything else.

The `E` on the end of `ECDHE` is **ephemeral**: a fresh key pair per
connection, discarded afterwards. That buys **forward secrecy**, the property
that stealing the server's long-term private key next year does not decrypt
the traffic you recorded this year, because the key that traffic actually used
was thrown away when the connection closed. It is the reason TLS 1.3 removed
the non-ephemeral key exchanges entirely rather than leaving them
configurable.

So a real protocol uses all three: key agreement to establish a session key,
signatures to prove who you are agreeing with, and symmetric encryption for the
data. That hybrid is what TLS is doing in lesson 48 and what `gpg --encrypt` does
to a file. The roster:

| Algorithm | Sign | Encrypt | Agree a key | Notes |
| --- | --- | --- | --- | --- |
| RSA | Yes | Yes | Key transport, dropped in TLS 1.3 | The only common one that also encrypts. 2048-bit floor |
| DSA | Yes | No | No | Obsolete. OpenSSH disabled it by default in 7.0 and dropped it entirely in 10.0 |
| ECDSA | Yes | No | No | Elliptic-curve; `nistp256` and friends |
| **Ed25519** | Yes | **No** | No | Current default for SSH keys and for signing |
| DH, ECDH | No | No | **Yes** | Key agreement only. `X25519` is the current curve |
| ML-KEM | No | No | **Yes** | Post-quantum key agreement, FIPS 203, 2024 |
| ML-DSA | **Yes** | No | No | Post-quantum signatures, FIPS 204, 2024 |

**That "No" against Ed25519 under Encrypt is the row people trip on.** It is not
a limitation of the tooling. The algorithm has no encryption operation, which is
why "the public key encrypts" is a description of RSA rather than a rule about
asymmetric cryptography.

## What a signature proves that a checksum does not

Take a message that matters and sign it with the private key:

```bash
# Debian 13 (trixie), x86_64
$ cat /tmp/msg; openssl pkeyutl -sign -inkey /tmp/priv.pem -rawin -in /tmp/msg -out /tmp/sig; ls -l /tmp/sig
transfer 500 to account 12345
-rw-r--r--. 1 root root 64 Aug  8 17:08 /tmp/sig
```

Two things worth noticing. **The message is not encrypted**: `cat` printed it
in the clear, and it stays readable. A signature is a separate value that sits
beside the data, not a transformation of it. And the signature is **64
bytes**, which is what an Ed25519 signature always is, regardless of whether
the message is one line or a gigabyte.

Anybody with the public key can now check it:

```bash
# Debian 13 (trixie), x86_64
$ openssl pkeyutl -verify -pubin -inkey /tmp/pub.pem -rawin -in /tmp/msg -sigfile /tmp/sig
Signature Verified Successfully
```

That single line is doing more work than it looks. It says the message has not
changed since it was signed, **and** that it was signed by the holder of the
private key matching this public key. A checksum gives you the first half. Only a
signature gives you both.

<details class="predict">
<summary>The signature verified a moment ago. Now one character of the message changes (the amount, not the account number) and the signature file is not touched at all. Given that a signature covers a digest of the message, what does verification print?</summary>

```bash
# Debian 13 (trixie), x86_64
$ sed -i 's/500/900/' /tmp/msg; cat /tmp/msg; openssl pkeyutl -verify -pubin -inkey /tmp/pub.pem -rawin -in /tmp/msg -sigfile /tmp/sig
transfer 900 to account 12345
407709B7FFFF0000:error:030000EA:digital envelope routines:EVP_DigestVerify:provider signature failure:../crypto/evp/m_sigver.c:779:ED25519 digest_verify:
Signature Verification Failure
```

</details>

**`Signature Verification Failure`, plus a library error naming the operation.**
Changing `500` to `900` changed the message, which changed its digest, which no
longer matches what the signature covers. There is no partial credit and no
tolerance: a signature verifies or it does not.

This is the mechanism behind package signing from lesson 31 and certificates in
lesson 48, and it is worth stating the practical consequence out loud.
**Publishing a SHA-256 checksum next to a download protects against a corrupted
transfer and nothing else.** Anybody who can replace the tarball on that server
can replace the checksum on that page. What distributions actually do is sign the
checksum *file*, so the chain is: the signature proves who wrote the checksum
list, and the checksum proves which bytes they meant.

<details class="deeper">
<summary>If you already administer Linux: signing does not encrypt anything, and what actually gets signed is the digest</summary>

Two pieces of received wisdom in this area are wrong in ways that matter.

**"Signing is encrypting with the private key."** This is a description of
textbook RSA and nothing else. It was never true of DSA, ECDSA, or the Ed25519
key used above, those algorithms have a signing operation and a verification
operation and no encryption operation at all. You cannot encrypt anything to
an Ed25519 key. The mental shortcut survives because RSA dominated for twenty
years and because the shortcut gets the *direction* right, which is the part
people actually need. It gets the mechanism wrong, and it produces the wrong
answer to "can this key also encrypt".

**"The signature covers the document."** It covers a *digest* of the document.
Every signature scheme in practical use hashes first and signs the fixed-size
result, which is why a 64-byte signature can cover a gigabyte and why signing is
fast regardless of file size.

That has a consequence worth carrying: **a broken hash breaks signatures even
when the signature algorithm is perfect.** If an attacker can produce two
documents sharing a digest, a signature over the digest of the harmless one is a
valid signature over the malicious one, and the RSA or ECDSA maths was never
involved in the failure. This is the whole reason certificate authorities were
forced off SHA-1: nothing was wrong with RSA.

**Three further things a signature does not give you**, each of which has caused
an incident somewhere:

- **Freshness.** A valid signature is valid forever. Capture a signed message and
  replay it later and it still verifies. Anything where replay matters needs a
  nonce, a timestamp, or a sequence number *inside* the signed content.
- **Authority.** It proves the private key was used. Whether that key belongs to
  who you think is the certificate and web-of-trust problem, and it is where all
  the real difficulty lives. A self-signed certificate is a perfectly valid
  signature that proves nothing you wanted to know.
- **Intent.** It proves the key signed those bytes, not that a human understood
  them. Automated signing systems sign whatever is put in front of them, which is
  why the interesting attacks on signing infrastructure target the build pipeline
  and not the algorithm.

On key choice: `openssl genpkey -algorithm ed25519` produces a 32-byte public key
and 64-byte signatures with no parameters to get wrong. RSA needs a size decision
(2048 is the current floor, 3072 or 4096 for anything long-lived) and a padding
decision, where PSS is the modern answer and PKCS#1 v1.5 is the one everything
still uses. When you get a free choice, Ed25519 removes an entire category of
configuration mistake.

</details>

## Where salts and keys come from

Everything above assumes unpredictable bytes, and getting those is one command:

```bash
# Debian 13 (trixie), x86_64
$ openssl rand -hex 16; openssl rand -base64 24
faa42aceb5ee897a250278bfabec515d
gzPw4eGoILCIz52VNOCgV53x+gR+7/LN
```

`openssl rand` draws from the kernel's random pool through the library's
generator. `-hex` gives you something you can paste into a config file; `-base64`
packs more entropy per character.

**Do not build these yourself.** `$RANDOM` in the shell, the current
timestamp, the process ID, and anything seeded from the clock are all
predictable enough to enumerate, and a salt or key that can be enumerated is
not one. Use `openssl rand`, `/dev/urandom`, or your language's cryptographic
random source, never its ordinary one.

`/dev/urandom` is the right device on any current kernel. The old advice to
prefer `/dev/random` for "real" randomness described behaviour that Linux
stopped exhibiting years ago: both draw from the same pool, and `/dev/urandom`
does not block once the pool has been seeded at boot. The one case that still
matters is a freshly booted machine with no entropy sources (a headless VM
starting from a fresh image, generating host keys) which is why virtual
machines are given a paravirtualised entropy device.

## Retiring an algorithm on a whole machine

Old algorithms do not vanish. They are still compiled in, because files and
protocols out in the world still contain them:

```bash
# Debian 13 (trixie), x86_64
$ openssl version; openssl list -digest-algorithms | head -12
OpenSSL 3.5.6 7 Apr 2026 (Library: OpenSSL 3.5.6 7 Apr 2026)
Legacy:
  RSA-MD4 => MD4
  RSA-MD5 => MD5
  RSA-RIPEMD160 => RIPEMD160
  RSA-SHA1 => SHA1
  RSA-SHA1-2 => RSA-SHA1
  RSA-SHA224 => SHA224
  RSA-SHA256 => SHA256
  RSA-SHA3-224 => SHA3-224
  RSA-SHA3-256 => SHA3-256
  RSA-SHA3-384 => SHA3-384
  RSA-SHA3-512 => SHA3-512
```

Reading that output honestly matters. **`Legacy:` here is OpenSSL's word for its
older algorithm-name table, not a security judgement**, and it is easy to
misquote as "OpenSSL has marked MD5 legacy". What the list actually tells you is
that MD5 and SHA-1 are present and functional in OpenSSL 3.5, as they will be for
years, because a program that cannot verify an old signature cannot tell you the
old signature is bad.

**Deciding what a machine will accept is therefore a layer above the library.**
It is a policy question, and the practical shapes it takes are:

- Refuse the algorithm in each application's configuration, one at a time:
  `sshd_config`, `openssl.cnf`, the web server's cipher list, the VPN's.
- Or set one system-wide policy that rewrites all of those at once, which is what
  the RHEL family provides and the next panel covers.

That second bullet has a name the exam uses: **algorithm agility**. A system
has it when the algorithm is a setting rather than an assumption, when it is
written down in one place, negotiated at run time, and carried inside the
stored data so old material stays verifiable while new material uses the new
choice. The `$y$` prefix in a shadow field is algorithm agility in miniature:
the format announces which function produced the hash, so a machine can change
its default without invalidating a single existing password. A protocol or
file format with no such field is stuck with whatever it was born with, which
is how MD5 outlived its usefulness by a decade.

The named retirements worth knowing, because they are the ones you will actually
trip over:

| Retired | Where you meet it |
| --- | --- |
| SHA-1 in certificates | Browsers rejected them from 2017 |
| SHA-1 for SSH signatures | OpenSSH 8.8 disabled `ssh-rsa` by default; old servers stop accepting your key |
| MD5 anywhere security-relevant | Still fine as `rsync --checksum`'s corruption check, never in a signature |
| TLS 1.0 and 1.1 | Deprecated by RFC 8996; off in current default policies |
| DES and 3DES | Gone from defaults, occasionally alive in ancient appliances |

<details class="deeper">
<summary>If you already administer Linux: crypto policies, and the one switch that changes SSH, TLS, and Kerberos together</summary>

Turning off SHA-1 across a machine by editing every application's configuration
is how it was done for twenty years, and the failure mode was always the same:
you got seven of the nine, and the two you missed were the two nobody could
name.

The RHEL family replaced that with a single system-wide setting, and on a stock
machine it is already answering:

```bash
# AlmaLinux 10.2, x86_64
$ openssl version; update-crypto-policies --show
OpenSSL 3.5.5 27 Jan 2026 (Library: OpenSSL 3.5.5 27 Jan 2026)
DEFAULT
```

One word. That is the whole cryptographic posture of the machine, and it is
the same OpenSSL 3.5 that listed MD4 and MD5 a moment ago. The library did not
change, the policy sitting above it did.

The policies are files on disk, not magic:

```bash
# AlmaLinux 10.2, x86_64
$ ls /usr/share/crypto-policies; ls /usr/share/crypto-policies/policies
DEFAULT
FIPS
FUTURE
LEGACY
back-ends
default-config
default-fips-config
policies
python
reload-cmds.sh
DEFAULT.pol
EMPTY.pol
FIPS.pol
FUTURE.pol
LEGACY.pol
modules
```

Four shipped policies plus `EMPTY`, in order of strictness:

| Policy | Roughly means |
| --- | --- |
| `LEGACY` | Re-enables TLS 1.0 and 1.1, SHA-1 signatures, and smaller keys. For talking to old equipment. |
| `DEFAULT` | Current sensible baseline: TLS 1.2 and 1.3, SHA-1 no longer accepted for signatures. |
| `FUTURE` | Raises minimum key sizes and removes more. A preview of the next `DEFAULT`. |
| `FIPS` | Only algorithms permitted by the relevant FIPS validation. |

Changing it is one command, and `--set` is the half people forget after reading
`--show`:

```
sudo update-crypto-policies --set FUTURE
```

**The mechanism is generation, not interception.** The `back-ends` directory
in that listing holds a configuration fragment per consumer (OpenSSL, GnuTLS,
NSS, OpenSSH client and server, Java, BIND, libreswan) and setting a policy
points `/etc/crypto-policies/back-ends/` at the set belonging to that policy.
Each application includes its own fragment. Two things follow. Applications
must be **restarted** to pick it up, and a full reboot is the honest way to be
sure. And an application that does not read its fragment, because somebody
pasted an explicit cipher list into its own config, is quietly exempt.
Checking that is worth doing after any policy change.

**Sub-policies are the escape hatch that keeps this usable.** Instead of dropping
the whole machine to `LEGACY` because one appliance needs SHA-1 signatures:

```
sudo update-crypto-policies --set DEFAULT:SHA1
```

That is `DEFAULT` with one modifier applied, which is a documented, greppable,
auditable exception rather than a blanket downgrade. `LEGACY` set once "to get
the migration working" and never removed is a genuinely common audit finding, and
a sub-policy avoids earning it.

**FIPS is not a policy you set this way.** `update-crypto-policies --set FIPS`
changes the userspace side only; the kernel needs its own switch, so the
supported route is `fips-mode-setup --enable` followed by a reboot. Setting the
policy alone gives you a machine that looks compliant to a config scanner and is
not.

**The Debian family has no single equivalent.** The nearest thing is the OpenSSL
security level in `/etc/ssl/openssl.cnf`, which constrains what OpenSSL-based
applications will negotiate and does nothing for OpenSSH, GnuTLS, or NSS. On a
Debian machine the enumeration is still per-application, which is worth knowing
before you promise an auditor a one-line answer.

The forward-looking reason to care: post-quantum migration is coming, and it is
the same problem at a larger scale. A machine where algorithm choice is one
setting can be moved; a machine where it is scattered across forty configuration
files cannot.

</details>

## Across distributions

| | RHEL family | Debian family |
| --- | --- | --- |
| Default `ENCRYPT_METHOD` | `YESCRYPT` on 10, `SHA512` on 9 and earlier | `YESCRYPT`, giving `$y$` |
| Where that is set | `/etc/login.defs` | `/etc/login.defs` |
| System-wide algorithm switch | `update-crypto-policies` | None; per-application |
| OpenSSL configuration | `/etc/pki/tls/openssl.cnf` | `/etc/ssl/openssl.cnf` |
| Hash a password by hand | `openssl passwd -6` | `mkpasswd -m yescrypt`, from `whois` |
| `mkpasswd` is | A different program, from `expect`, that *generates* passwords | The hashing tool |
| CA trust store refresh | `update-ca-trust` | `update-ca-certificates` |

**Two rows deserve care.** `mkpasswd` existing on both families and doing
different things is a real trap: a script written on Debian that pipes
`mkpasswd` output into `chpasswd -e` produces a random password rather than a
hash when it runs on RHEL, and nothing errors.

The first row is the one to be careful repeating, because it changed recently and
most of the study material predates the change. "RHEL uses `$6$`" was true for
years and is not true on RHEL 10:

```bash
# AlmaLinux 10.2, x86_64
$ grep ^ENCRYPT_METHOD /etc/login.defs; useradd -m demo; echo demo:hunter2 | chpasswd; getent shadow demo | cut -d: -f2
ENCRYPT_METHOD YESCRYPT
$y$j9T$FkITuihiYppUguAhqPvDF1$TFKnyosfIPdvz4dRYi5MEhCOcqO6DnpsAsSnNQkjq21
```

**`YESCRYPT`, and a `$y$` hash to prove it took effect**, on the RHEL-family
container. Both major families now default to the same memory-hard algorithm;
the split you may have memorised is a RHEL 9 fact, not a RHEL fact. Note also
that `openssl passwd -6` still produces `$6$` on this same machine, because
that flag asks for SHA-512-crypt explicitly and has nothing to do with
`login.defs`, the default only governs what `useradd`, `passwd`, and
`chpasswd` create.

And do not trust any of that over the evidence in front of you. **Read the prefix
in the actual file.** A machine upgraded across several releases has hashes in
whatever format was default when each password was last changed, so a single
`/etc/shadow` can easily hold `$6$` and `$y$` side by side, and possibly a `$1$`
belonging to an account nobody has touched since 2014. That last one is the
finding.

## Prove it

```
# What algorithm is a given account's password actually stored under
sudo getent shadow alice | cut -d: -f2 | cut -d'$' -f2

# Every account still on a retired algorithm, which is the audit that matters
sudo cut -d: -f1,2 /etc/shadow | grep -E ':\$1\$|:[^$*!]{13}$'

# What this machine will create new hashes with
grep -E '^ENCRYPT_METHOD|^SHA_CRYPT' /etc/login.defs

# Determinism, in two commands you can run anywhere
printf 'hello' | sha256sum
printf 'hello' | sha256sum

# What the crypto library still implements, which is not what policy allows
openssl list -digest-algorithms

# And on the RHEL family, what policy allows
update-crypto-policies --show

# Verify a download properly: establish who wrote the list BEFORE trusting it
gpg --verify SHA256SUMS.asc SHA256SUMS
sha256sum -c SHA256SUMS
```

**The order of the last pair is the habit worth building, and it is the order
most people get backwards.** Running `sha256sum -c` first tells you the file
matches a list that anybody could have written; if the list was replaced along
with the tarball, the check passes and tells you nothing. Verify the signature
over the list first, so that by the time you compare digests you already know who
stood behind them. If `gpg --verify` fails, there is nothing to check the
checksum against and the second command should never run.

## What trips people up

### 1. Decrypting a hash

There is no such operation, at any key length, with any tool, at any budget.
Hashing has no inverse; that is its definition, not a limitation of current
software.

Services advertising MD5 or SHA-1 "decryption" are searching a table of digests
somebody has already computed. They succeed on `password123` and fail on anything
nobody has hashed before, which is exactly the behaviour of a lookup and not of a
reversal.

### 2. Treating the salt as a secret

The salt is stored in the clear beside the hash, in the same field, by design. Its
purpose is to make precomputed tables useless and to stop identical passwords
producing identical hashes.

It does **not** slow down an attack on one password, because the attacker has
it. Only the work factor does that. A "secret salt" shared across all accounts
is a different thing entirely, called a pepper, and it belongs outside the
password database, typically in an HSM or an application config, where a
database dump alone does not reveal it.

### 3. "MD5 is broken, so those passwords can be recovered"

Wrong property. What broke for MD5 and SHA-1 is **collision** resistance: an
attacker can construct two inputs sharing a digest. **Preimage** resistance, the
one that would let somebody work backwards from a stored hash to a password, is
intact for both.

`$1$` hashes are still bad, for the different reason that MD5 is fast and
guessing is therefore cheap. Getting this precise matters because the fix differs:
the collision break means stop using it for signatures immediately, and the speed
problem means change the password hashing scheme and force a reset.

### 4. Signing with the public key

You sign with the **private** key and verify with the **public** one, which is
the reverse of encryption, where you encrypt with the public key and decrypt with
the private one.

Anchor it to the property. Only one person should be able to *produce* a
signature, so production uses the key only they have. Anybody should be able to
*send* them a secret, so encryption uses the key everybody has.

### 5. Reading `bad decrypt` as an integrity check

It is a padding check on garbage, not authentication. With CBC, a wrong key
usually produces invalid padding and an error, but not always, and there is no
guarantee at all that a *tampered* ciphertext will be noticed.

Use an authenticated mode such as AES-GCM when you choose, and never treat a
clean CBC decrypt as evidence the data is genuine.

### 6. Hashing passwords with the fast hash you already know

`sha256sum` is the right tool for a file and the wrong one for a password. The
property you want in a file hash is speed; the property you want in a password
hash is slowness, and they are the same word pointing in opposite directions.

Use yescrypt, bcrypt, or Argon2id. If the platform offers only SHA-512-crypt,
raise `rounds` well above the 5000 default.

## Work it through

An application team tells you their user database stores passwords "hashed with
SHA-256, so we are fine". A copy of that database has turned up on a paste
site. Two hundred thousand rows.

Reason it out before reading on.

**First, what is not the problem.** Nobody is going to reverse those hashes.
SHA-256 has no known preimage weakness, and the phrase "decrypt the hashes" that
will appear in the incident channel within the hour describes an operation that
does not exist. Say so early, because the panic and the mitigation both go wrong
if that is the working theory.

**Second, the question that decides the severity: is there a salt?** Look at the
column. If every row is exactly 64 hexadecimal characters with nothing else in
it, there is no salt and no algorithm identifier, which means the passwords were
hashed raw.

That is the bad case, and it is bad in a specific way. **Identical passwords now
have identical hashes**, so the attacker sorts the column, finds that four
thousand rows share one value, hashes `Password1`, and has cracked four thousand
accounts with one operation. Then they run a precomputed table against the rest,
because with no salt one table works against every row at once.

**Third, the cost of the attack even where the table misses.** Raw SHA-256 on
commodity GPU hardware runs at the order of tens of billions of guesses per
second. Against a dictionary with mutations, most human-chosen passwords in that
file fall inside a day. The absence of a work factor, not the absence of a salt,
is what makes that number so large.

So the response is: every password in that file is compromised, force a reset on
all of them, and change the scheme to a memory-hard hash before reopening
sign-in.

**Now change one detail and watch the answer move.** Suppose the column had held
`$2b$12$` values instead. Still leaked, still needs a reset, but now the attacker
is testing a few thousand candidates per second per GPU rather than tens of
billions, every row needs its own attack because every row has its own salt, and
the strong passwords in that file are realistically safe. Same breach, completely
different week.

Change a different one. Suppose the hashes were salted but still raw SHA-256.
The precomputed tables are dead and identical passwords no longer show up as
identical, which is a real improvement, and the guessing rate has not changed
at all. Weak passwords still fall in minutes. That is the cleanest
demonstration that salt and work factor solve different problems and neither
substitutes for the other.

**And one more.** Suppose the team had "encrypted" the passwords with AES so
support staff could read them back. Now the incident is worse, not better,
because the question becomes where the key is, and if it is on the same
application server, which it always is, the attacker who took the database
took the key.

The point worth extracting: **hashing, salting, and work factor are three
independent decisions**, and the answer to "are we fine" needs all three. Hashing
stops recovery. Salting stops the attack from scaling across accounts. The work
factor sets the price per guess. A system with the first two and not the third is
the most common shape of a real breach, because it looks correct in code review.

## Try it

Optional, on any machine with `openssl` installed.

1. `printf 'hello' | sha256sum` twice, then `printf 'hellp' | sha256sum`. Compare
   character by character until you are satisfied nothing carries over.
2. `sha256sum` a one-byte file and a large one. Note the output lengths are equal.
3. `printf 'hello' | md5sum`, `sha1sum`, `sha256sum`, `sha512sum`. Count the hex
   characters and divide by two for bytes, then multiply by eight for the bits in
   the name.
4. `openssl passwd -6 -salt aaaaaaaa 'test'` and `openssl passwd -6 -salt bbbbbbbb 'test'`.
   Then run the first one again and confirm it reproduces exactly.
5. `sudo getent shadow "$USER" | cut -d: -f2` and identify the algorithm, the
   parameters, the salt, and the hash by their dollar signs.
6. `openssl dgst -sha256 -hmac 'k1' file` and the same with `k2`. Then with `k1`
   again, and confirm it reproduces.
7. Generate an Ed25519 key pair, sign a file, verify it, change one byte of the
   file, and verify again. Read both messages.
8. Try to encrypt to that Ed25519 public key with
   `openssl pkeyutl -encrypt -pubin -inkey /tmp/pub.pem -in /tmp/msg -out /tmp/x`.
   Read the error. The operation does not exist for this key type, which is the
   whole point of the roster table.
9. `openssl speed sha256 sha512` on the machine in front of you and see which one
   actually wins there, rather than trusting either version of the folklore.
10. `openssl enc -aes-256-cbc -in f -out f.enc -pass pass:x` with and without
    `-pbkdf2`, then `xxd` the first 16 bytes of each. The header looks identical;
    the key derivation behind it is not.
11. On a RHEL-family machine, `update-crypto-policies --show`, then
    `ls -l /etc/crypto-policies/back-ends/` and note that the entries are symlinks
    into `/usr/share/crypto-policies/`. That is the whole mechanism.

**Verification step.** You have it when you can look at a `/etc/shadow` field and
say aloud which part is the algorithm, which is the salt, which is the hash, and
what happens to each of them the next time that user logs in.

## Check yourself

<details class="qa">
<summary>Explain how a password is checked when the password itself is not stored anywhere.</summary>

**The system stores the output of a one-way function, together with the recipe
for repeating it.** In `/etc/shadow` the second field holds an algorithm
identifier, cost parameters, a salt, and the resulting hash, separated by dollar
signs.

At login the stack takes the offered password, reads the algorithm, the
parameters, and the salt out of the stored field, runs exactly that calculation
on the offered password, and compares the result to the stored hash. Matching
outputs mean matching inputs. The password is discarded immediately and was never
written down.

**The tempting wrong answer is that the stored value is "encrypted" and gets
decrypted for comparison.** It is not, and there is no decryption step, and
there could not be, if the machine could recover the password it would be
storing the password, which is the exact thing the design avoids. The
historical function being called `crypt()` keeps this misconception alive.

The thing you will need next: this is also why a password *reset* is the only
possible recovery, and why a service that emails you your existing password on
request has told you something serious about how it stores them.

</details>

<details class="qa">
<summary>Is a salt secret? What does it defend against, and what does it not help with at all?</summary>

No, and it was never meant to be. It is stored in the clear in the same field
as the hash, because verification needs it.

It defends against scale. Without a salt, an attacker computes one table of
hashes for common passwords and uses it against every account everywhere;
identical passwords also produce identical stored hashes, so cracking one
account cracks everyone who chose the same thing. A unique salt per password
destroys both: every account has to be attacked separately, and no
precomputation carries over.

It does nothing about the cost of attacking one password. The attacker has the
salt, so guessing against a single account is exactly as fast salted or
unsalted. That is the **work factor**'s job (bcrypt's cost, yescrypt's
parameters, Argon2's memory and time) and confusing the two is the most common
error in this area.

The tempting wrong answer is "the salt makes the hash harder to reverse". Nothing
makes a hash reversible or irreversible; that is a property of the function.

**Next thing you will need**: a per-password random salt means the same password
hashed twice gives different results, so you can never compare two stored hashes
to test whether two people chose the same password. A secret value shared across
all accounts is a different construct called a pepper, and it lives outside the
password database.

</details>

<details class="qa">
<summary>MD5 is broken. Broken for what, exactly, and what does that mean for an old `$1$` hash sitting in `/etc/shadow`?</summary>

Broken for collision resistance. An attacker can construct two different
inputs that share a digest. SHA-1 is in the same position: a first collision
in 2017, and a chosen-prefix collision in January 2020.

Preimage resistance is intact for both. Nobody can take a digest and find an
input that produces it. So that `$1$` hash cannot be turned back into the
password by any known attack on MD5 itself.

Which means the two failures need different responses. The collision break
matters wherever somebody signs a digest (certificates, package signatures,
code signing, commit signing) because a signature over the digest of a
harmless document is a valid signature over a malicious one with the same
digest. Stop immediately.

The `$1$` hash in the shadow file is bad for a completely separate reason: MD5 is
**fast**, so offline guessing against it is cheap, and MD5-crypt has no useful
work factor to raise. The fix is not "MD5 is reversible" but "every password
stored this way should be assumed guessable and reset onto a modern scheme".

**The tempting wrong answer** is that a broken hash means recoverable passwords.
Saying that in a review will get the wrong mitigation funded.

Next thing you will need: non-security uses of MD5 are still fine. Accidental
corruption does not construct collisions, so a filesystem or a sync tool using
a fast non-cryptographic hash internally is not a finding.

</details>

<details class="qa">
<summary>Which key makes a signature and which key checks it, and what does a signature prove that a published SHA-256 checksum does not?</summary>

The private key signs. The public key verifies. That is the reverse of
encryption, where the public key encrypts and the private key decrypts, and
both keys appear in both operations, which is why the inversion catches
everybody once.

Anchor it to the property being bought. Only one person should be able to
*produce* a signature, so production uses the key only they hold. Anybody should
be able to *send* a secret, so encryption uses the key everybody holds.

**A checksum proves integrity against accident. A signature proves integrity and
origin against intent.** Anybody can compute a SHA-256, so anybody who can
replace the file on a server can replace the checksum on the page beside it. A
signature can only be produced by the holder of the private key, so verification
tells you both that the bytes have not changed and who stood behind them.

The tempting wrong answer is that a checksum from HTTPS is good enough. TLS
protects the transfer; it says nothing about whether the file on the origin
server was the right one, which is exactly the case where signing helps.

**Next thing you will need**: what actually gets signed is a *digest* of the
message, not the message. That is why a 64-byte signature covers a gigabyte, and
why a broken hash function breaks signatures even when the signature algorithm
is sound.

</details>

<details class="qa">
<summary>Why should a password hash be deliberately slow when a file checksum should be as fast as possible? Name the algorithms for each.</summary>

**Because the two are defending against different things.**

A file checksum is verifying data you already have, so every millisecond is pure
cost to you and no cost to an attacker, who is not guessing anything. Fast is
correct: SHA-256, SHA-512, or BLAKE2.

A password hash is defending against **offline guessing**. Once somebody has the
hash file, rate limiting and lockout are gone and their only constraint is
guesses per second. That number is therefore the security margin, and making the
function slow lowers it directly. The right choices are yescrypt (`$y$`), bcrypt
(`$2b$`), or Argon2id, all of which take a tunable cost parameter.

**The lever that matters most is memory, not time.** A GPU has thousands of cores
and little memory each, so an algorithm insisting on tens of megabytes per guess
collapses the attacker's parallelism in a way that extra CPU rounds do not.
SHA-512-crypt is CPU-only, which is why it is acceptable rather than good.

The tempting wrong answer is that a stronger algorithm solves it, so SHA-512 must
beat SHA-256 for passwords. Digest length is not the axis; SHA-512 is also fast,
and speed is the problem.

**Next thing you will need**: raising a cost parameter does not touch existing
hashes, because the parameters are stored inside each hash string. They only
improve when each user next logs in and the code re-hashes with current settings.
Lesson 49's `cryptsetup` does the same calculation automatically, benchmarking
Argon2id at format time so the cost is measured in seconds on that machine rather
than in a fixed iteration count.

</details>

## References

- [crypt(5)](https://manpages.debian.org/trixie/libcrypt-dev/crypt.5.en.html) - Debian manpages, libxcrypt. Accessed 2026-08-08.
- [shadow(5)](https://man7.org/linux/man-pages/man5/shadow.5.html) - Linux man-pages project. Accessed 2026-08-08.
- [sha256sum(1)](https://man7.org/linux/man-pages/man1/sha256sum.1.html) - Linux man-pages project. Accessed 2026-08-08.
- [openssl-dgst(1ssl)](https://manpages.debian.org/trixie/openssl/openssl-dgst.1ssl.en.html) - Debian manpages, OpenSSL. Accessed 2026-08-08.
- [openssl-pkeyutl(1ssl)](https://manpages.debian.org/trixie/openssl/openssl-pkeyutl.1ssl.en.html) - Debian manpages, OpenSSL. Accessed 2026-08-08.
- [openssl-enc(1ssl)](https://manpages.debian.org/trixie/openssl/openssl-enc.1ssl.en.html) - Debian manpages, OpenSSL. Accessed 2026-08-08.
- [login.defs(5)](https://man7.org/linux/man-pages/man5/login.defs.5.html) - Linux man-pages project. Accessed 2026-08-08.
- [cryptsetup(8)](https://manpages.debian.org/trixie/cryptsetup-bin/cryptsetup.8.en.html) - Debian manpages, cryptsetup. Accessed 2026-08-08.
- [FIPS 203: Module-Lattice-Based Key-Encapsulation Mechanism Standard](https://csrc.nist.gov/pubs/fips/203/final) - NIST. Accessed 2026-08-08.
- [mkpasswd(1)](https://manpages.debian.org/trixie/whois/mkpasswd.1.en.html) - Debian manpages, whois. Accessed 2026-08-08.
- [RFC 2104: HMAC, Keyed-Hashing for Message Authentication](https://www.rfc-editor.org/rfc/rfc2104.html) - IETF. Accessed 2026-08-08.
- [Security hardening](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/10/html/security_hardening/index) - Red Hat. Accessed 2026-08-08.
- [SHAttered: the first collision for full SHA-1](https://shattered.io/) - CWI Amsterdam and Google Research. Accessed 2026-08-08.

Captured output came from two containers on x86_64: Debian 13 (trixie) running
OpenSSL 3.5.6 and its shipped libxcrypt, and AlmaLinux 10.2 running OpenSSL
3.5.5, which is where the `update-crypto-policies` output came from because
that tooling does not exist on Debian. The shadow field, the signature
verification, and the signature failure after tampering are all real runs
against real keys generated on that machine; the key pair was discarded
afterwards. Blocks without a distribution and architecture header are
illustrative, the `update-crypto-policies --set` and `fips-mode-setup`
invocations in particular are shown without output rather than with invented
output, because applying them changes a machine rather than reporting on one.
