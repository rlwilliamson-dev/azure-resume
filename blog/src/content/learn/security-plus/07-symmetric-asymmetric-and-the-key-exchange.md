---
title: "Symmetric, asymmetric, and the key exchange"
description: "Why two people who have never met can agree a secret over a wire everybody can read, why the algorithm that solves that problem cannot carry your data, and why comparing a 3072-bit key with a 256-bit key by the number on the label gets it backwards."
deck: "Two strangers, one wire everybody can read, and a shared secret at the end of it"
track: "security-plus"
level: "working"
order: 80
objectives:
  - "Say what symmetric and asymmetric cryptography are each good at"
  - "Explain why every real system uses both, from what each one can carry"
  - "Describe what a key exchange solves"
  - "Read a key length, and say why the number does not compare across families"
  - "Use the same key pair for secrecy and for proof, in the right direction each time"
prerequisites: []
tags: ["security-plus", "security", "cryptography", "keys"]
updated: 2026-08-21
draft: false
examObjectives:
  - exam: "sy0-701"
    domain: "1.0"
    objective: "1.4"
sources:
  - title: "FIPS 197, Advanced Encryption Standard"
    url: "https://csrc.nist.gov/pubs/fips/197/final"
    publisher: "NIST"
    accessed: 2026-08-21
    tier: 1
  - title: "FIPS 186-5, Digital Signature Standard"
    url: "https://csrc.nist.gov/pubs/fips/186-5/final"
    publisher: "NIST"
    accessed: 2026-08-21
    tier: 1
  - title: "NIST SP 800-57 Part 1 Rev. 5, Recommendation for Key Management"
    url: "https://csrc.nist.gov/pubs/sp/800/57/pt1/r5/final"
    publisher: "NIST"
    accessed: 2026-08-21
    tier: 1
  - title: "FIPS 203, Module-Lattice-Based Key-Encapsulation Mechanism Standard"
    url: "https://csrc.nist.gov/pubs/fips/203/final"
    publisher: "NIST"
    accessed: 2026-08-21
    tier: 1
  - title: "RFC 8446, The Transport Layer Security (TLS) Protocol Version 1.3"
    url: "https://www.rfc-editor.org/rfc/rfc8446.html"
    publisher: "IETF"
    accessed: 2026-08-21
    tier: 1
symptoms:
  - symptom: "An encryption operation fails with data too large for key size"
    anchor: "what-an-asymmetric-key-will-actually-take"
---

> **Before you read.** Two machines that have never communicated need a shared
> secret. Everything they send each other is visible to anybody watching, and
> they have no way to meet, no courier, and no pre-arranged password.
>
> At the end of the conversation they both know the same number and the observer
> does not.
>
> **They sent everything in the clear. How is that possible?**

Symmetric cryptography is one key that both encrypts and decrypts. Asymmetric is
a pair, where what one half does the other half undoes. Almost everything about
how real systems are built follows from what each of those can and cannot do.

### Some words you will need

<dl class="terms">
<dt>symmetric encryption</dt>
<dd>One key, held by both parties, used to encrypt and to decrypt. Fast, and useless until both parties have it.</dd>
<dt>asymmetric encryption</dt>
<dd>A key pair. What the public half does, the private half undoes, and the reverse. Slow, and solves the problem symmetric cannot.</dd>
<dt>key exchange</dt>
<dd>The business of two parties agreeing a shared secret over a channel somebody is watching.</dd>
<dt>session key</dt>
<dd>A symmetric key generated for one conversation and thrown away afterwards.</dd>
<dt>key length</dt>
<dd>The size of the key in bits. Comparable within a family and not between families.</dd>
<dt>digital signature</dt>
<dd>A value produced with a private key that anybody can check with the matching public key.</dd>
<dt>elliptic curve</dt>
<dd>A family of asymmetric algorithms that reach comparable strength with far smaller keys than RSA.</dd>
<dt>forward secrecy</dt>
<dd>The property that stealing a long-term key later does not decrypt conversations recorded earlier.</dd>
</dl>

## What breaks without this

**The key is the problem, not the cipher.** Symmetric encryption is fast, strong
and freely available, and it is worth nothing until both parties hold the same
key. Getting it to them is the entire difficulty, and it is what asymmetric
cryptography exists to solve.

**You reach for the wrong half of a key pair.** Encrypting with your own private
key produces something anybody can read, because the matching public key is
published. The operation succeeds and the result looks like ciphertext.

**You compare key lengths across families.** A 256-bit elliptic curve key is not
weaker than a 3072-bit RSA key, and choosing on the number produces a decision
that is backwards.

**Recorded traffic becomes readable years later.** A design where the server's
long-term key can decrypt past conversations means a key compromise in 2030 opens
everything captured in 2026.

## Two kinds, and what each one is for

Symmetric encryption uses one key for both directions. AES is the one this exam
names, and it is what actually moves data: fast, hardware-accelerated, and
unbothered by size.

Asymmetric uses a pair. Anything the public half encrypts, only the private half
decrypts. Anything the private half signs, the public half verifies. RSA and the
elliptic curve algorithms are the ones named.

The temptation is to read that as two options for the same job, with asymmetric
being the modern one. It is not, and the reason is measurable.

<details class="predict">
<summary>One megabyte of data, and an RSA-2048 public key. What do you expect to happen?</summary>

```bash
# AlmaLinux 10.2, x86_64
$ cd /root/keys
echo "one megabyte, encrypted symmetrically:"
time openssl enc -aes-256-cbc -pbkdf2 -pass pass:hunter2 -in payload.bin -out payload.enc
echo
echo "the same megabyte, offered to the RSA key:"
openssl pkeyutl -encrypt -pubin -inkey rsa.pub -in payload.bin -out payload.rsa 2>&1 | head -3
echo
echo "what the RSA key will take:"
head -c 190 payload.bin > small.bin
openssl pkeyutl -encrypt -pubin -inkey rsa.pub -in small.bin -out small.rsa && ls -l small.bin small.rsa | tr -s " " | cut -d" " -f5,9
one megabyte, encrypted symmetrically:

real	0m0.111s
user	0m0.108s
sys	0m0.003s

the same megabyte, offered to the RSA key:
Public Key operation error
405769B7FFFF0000:error:0200006E:rsa routines:ossl_rsa_padding_add_PKCS1_type_2_ex:data too large for key size:crypto/rsa/rsa_pk1.c:132:

what the RSA key will take:
190 small.bin
256 small.rsa
```

</details>

**The megabyte does not fit.** Not "takes too long": the operation returns an
error, because an RSA key encrypts a block no larger than the key, and 2048 bits
is 256 bytes, of which padding takes 66. The most an RSA-2048 key will accept is
190 bytes, and it produces 256 bytes from them.

Meanwhile AES took 0.111 seconds over the same megabyte and would have taken it
over a gigabyte.

<figure class="learn-figure">
<svg viewBox="0 0 720 296" role="img" aria-labelledby="hyb-title" style="width:100%;height:auto;">
<title id="hyb-title">A megabyte offered to an RSA-2048 key is refused because the key accepts at most 190 bytes, so a real system encrypts a 32-byte session key with RSA and the megabyte with AES</title>
<g fill="currentColor">
<text x="14" y="20" font-size="11">why every real system uses both, in two measurements</text>
<text x="14" y="52" font-size="10" fill-opacity="0.85">what an rsa-2048 key will accept</text>
<rect x="250" y="40" width="6" height="16" rx="1" fill="var(--accent)" fill-opacity="0.4" stroke="var(--accent)" stroke-width="1.4"/>
<text x="266" y="52" font-size="10">190 bytes</text>
<text x="14" y="84" font-size="10" fill-opacity="0.85">what was offered to it</text>
<rect x="250" y="72" width="420" height="16" rx="2" fill="none" stroke="var(--red)" stroke-opacity="0.9" stroke-width="1.6" stroke-dasharray="4 3"/>
<text x="266" y="84" font-size="10" fill="var(--red)" fill-opacity="0.95">1,048,576 bytes, refused: data too large for key size</text>
<path d="M 250 108 H 670" stroke="currentColor" stroke-opacity="0.3" stroke-width="1"/>
<text x="14" y="140" font-size="10" fill-opacity="0.85">so the arrangement that works</text>
<rect x="250" y="128" width="130" height="34" rx="4" fill="var(--accent)" fill-opacity="0.16" stroke="var(--accent)" stroke-width="1.6"/>
<text x="315" y="149" text-anchor="middle" font-size="10">rsa on 32 bytes</text>
<text x="250" y="180" font-size="9.5" fill-opacity="0.85">363 operations a second</text>
<rect x="396" y="128" width="274" height="34" rx="4" fill="currentColor" fill-opacity="0.12" stroke="currentColor" stroke-opacity="0.75" stroke-width="1.4"/>
<text x="533" y="149" text-anchor="middle" font-size="10">aes on the megabyte</text>
<text x="396" y="180" font-size="9.5" fill-opacity="0.85">344 megabytes a second, 0.111s for this one</text>
<text x="250" y="198" font-size="9.5" fill-opacity="0.85">and it carries the session key</text>
<text x="14" y="220" font-size="10" fill-opacity="0.85">the slow algorithm runs once, on a key, and the fast one runs on everything else</text>
<text x="14" y="242" font-size="10" fill-opacity="0.85">asymmetric solves getting the key across, and is not how the data travels</text>
<text x="14" y="264" font-size="10" fill-opacity="0.85">a system that used only rsa could not send this paragraph in one operation</text>
<text x="14" y="286" font-size="10" fill-opacity="0.85">a system that used only aes would have no way to agree the key first</text>
</g></svg>
<figcaption>Both numbers are measured on the same container. An RSA-2048 key produces 256 bytes of output and accepts at most 190 bytes of input, because the padding takes the rest, so a megabyte offered to it returns an error rather than a large ciphertext. That is not a performance problem to work around; it is what the algorithm does. The arrangement every real protocol uses instead runs the expensive operation once, on a symmetric key of 32 bytes, and moves the actual data with that key at 344 megabytes a second. Asymmetric cryptography is how two parties agree on a secret they can both use. It is not how the data travels, and reading it as a slower alternative to AES rather than as a solution to a different problem is what makes the hybrid design look like an optimisation instead of the only thing that works.</figcaption>
</figure>

So the design every real protocol uses is not a compromise between two options.
It is the only arrangement in which both algorithms do the job they can do:
asymmetric cryptography agrees a small symmetric key, and the symmetric key
carries everything else. TLS works this way, SSH works this way, and so does
every encrypted messaging application.

<details class="deeper">
<summary>If you already know this: why the modern answer does not encrypt the session key at all</summary>

The description above is RSA key transport: the client picks a session key,
encrypts it with the server's public key, and sends it. That was how TLS worked
for many years and TLS 1.3 removed it entirely.

The reason is forward secrecy. In key transport the session key is protected by
the server's long-term private key, so anybody who records the traffic and later
obtains that key can decrypt every recorded session. One key compromise opens
years of captured conversations retroactively, and recording traffic now to
decrypt later is a real posture rather than a hypothetical one.

What replaced it is ephemeral Diffie-Hellman, where both sides generate a fresh
key pair per connection, exchange public halves, and each derive the same shared
secret from their own private half and the other's public one. The observer sees
both public halves and cannot derive the secret from them. The ephemeral private
keys are discarded when the connection ends, so there is nothing left to steal,
and the long-term key is used only to sign the exchange rather than to protect it.

That is the distinction between the two acronyms people memorise without the
reason: the letter E is the whole point, and it is the difference between a
compromise costing you future conversations and costing you every conversation
you ever had.

</details>

## What an asymmetric key will actually take

Reading the error in that block is worth doing, because it is the shape of a real
support ticket. `data too large for key size` is not a configuration problem and
raising a limit will not fix it. It is the algorithm saying the input exceeds what
one operation can hold.

Two consequences follow, and both appear in real systems.

**Asymmetric encryption is used on keys and digests, not on documents.** When
something claims to encrypt a file with a public key, it is generating a symmetric
key, encrypting the file with that, and encrypting the key with the public key.
GPG does this and so does every S/MIME mail client.

**A signature is not computed over the document either.** It is computed over the
digest of the document, which is why the previous topic comes before this one.
That is also why a collision in the hash function breaks the signature scheme:
two documents with the same digest have the same valid signature.

<details class="deeper">
<summary>If you have hit this limit: the padding, and why removing it is not an option</summary>

The 66 bytes that padding takes out of an RSA-2048 operation look like overhead
worth reclaiming, and there is a mode that reclaims them. It is called textbook
RSA, it is what the mathematics does without any padding at all, and every
implementation that offers it puts a warning next to it.

Unpadded RSA is deterministic, so the same input always produces the same
ciphertext, and an attacker who can guess the input can confirm the guess by
encrypting it themselves with the public key everybody has. For a session key
that is fine because the input is random and unguessable. For anything from a
small set, a credit card number, a vote, a yes or no, it is a lookup table.

It is also multiplicative in a way that lets an attacker transform a ciphertext
into the ciphertext of a related message without knowing either, which is what
padding schemes are specifically constructed to break.

So the 66 bytes are not overhead. They are randomness and structure that make the
operation safe against attacks the raw mathematics permits, and the practical
rule is the same one as with HMAC in the previous topic: use the named padding
mode rather than the primitive, every time.

</details>

## One key pair, two directions

Here is the part that decides more exam questions than anything else in this
objective.

<figure class="learn-figure">
<svg viewBox="0 0 720 338" role="img" aria-labelledby="dir-title" style="width:100%;height:auto;">
<title id="dir-title">One key pair used in two opposite directions: the public key encrypts and the private key decrypts to keep a secret, and the private key signs while the public key verifies to prove authorship</title>
<g fill="currentColor">
<text x="14" y="20" font-size="11">one key pair, two directions, and the direction decides which property you get</text>
<text x="14" y="52" font-size="10" fill-opacity="0.85">to keep a secret from everyone but bob</text>
<rect x="14" y="64" width="150" height="34" rx="4" fill="none" stroke="currentColor" stroke-opacity="0.7" stroke-width="1.4"/>
<text x="89" y="85" text-anchor="middle" font-size="10">anyone at all</text>
<path d="M 172 81 H 246" stroke="currentColor" stroke-opacity="0.75" stroke-width="1.6"/>
<path d="M 238 76 L 248 81 L 238 86" fill="none" stroke="currentColor" stroke-opacity="0.75" stroke-width="1.6"/>
<text x="209" y="118" text-anchor="middle" font-size="9.5" fill-opacity="0.85">bob's public key</text>
<rect x="252" y="64" width="150" height="34" rx="4" fill="currentColor" fill-opacity="0.08" stroke="currentColor" stroke-opacity="0.7" stroke-width="1.4" stroke-dasharray="4 3"/>
<text x="327" y="85" text-anchor="middle" font-size="10">unreadable</text>
<path d="M 410 81 H 484" stroke="var(--accent)" stroke-width="1.8"/>
<path d="M 476 76 L 486 81 L 476 86" fill="none" stroke="var(--accent)" stroke-width="1.8"/>
<text x="447" y="118" text-anchor="middle" font-size="9.5" fill-opacity="0.85">bob's private key</text>
<rect x="490" y="64" width="150" height="34" rx="4" fill="none" stroke="var(--accent)" stroke-width="1.6"/>
<text x="565" y="85" text-anchor="middle" font-size="10">bob alone</text>
<text x="14" y="152" font-size="10" fill-opacity="0.85">to prove alice wrote it</text>
<rect x="14" y="164" width="150" height="34" rx="4" fill="none" stroke="var(--accent)" stroke-width="1.6"/>
<text x="89" y="185" text-anchor="middle" font-size="10">alice alone</text>
<path d="M 172 181 H 246" stroke="var(--accent)" stroke-width="1.8"/>
<path d="M 238 176 L 248 181 L 238 186" fill="none" stroke="var(--accent)" stroke-width="1.8"/>
<text x="209" y="218" text-anchor="middle" font-size="9.5" fill-opacity="0.85">alice's private key</text>
<rect x="252" y="164" width="150" height="34" rx="4" fill="currentColor" fill-opacity="0.08" stroke="currentColor" stroke-opacity="0.7" stroke-width="1.4" stroke-dasharray="4 3"/>
<text x="327" y="185" text-anchor="middle" font-size="10">readable, and signed</text>
<path d="M 410 181 H 484" stroke="currentColor" stroke-opacity="0.75" stroke-width="1.6"/>
<path d="M 476 176 L 486 181 L 476 186" fill="none" stroke="currentColor" stroke-opacity="0.75" stroke-width="1.6"/>
<text x="447" y="218" text-anchor="middle" font-size="9.5" fill-opacity="0.85">alice's public key</text>
<rect x="490" y="164" width="150" height="34" rx="4" fill="none" stroke="currentColor" stroke-opacity="0.7" stroke-width="1.4"/>
<text x="565" y="185" text-anchor="middle" font-size="10">anyone at all</text>
<text x="14" y="252" font-size="10" fill-opacity="0.85">the accented boxes and arrows are the private half, and each row has exactly one</text>
<text x="14" y="274" font-size="10" fill-opacity="0.85">encrypting starts with a key everyone has and ends with one only the recipient has</text>
<text x="14" y="296" font-size="10" fill-opacity="0.85">signing starts with a key only the author has and ends with one everyone has</text>
<text x="14" y="318" font-size="10" fill-opacity="0.85">the private key is at the exclusive end of the row in both cases, and that is the rule</text>
</g></svg>
<figcaption>The same pair of keys, run in opposite directions, and the direction is what decides whether you get confidentiality or non-repudiation. Encrypting to somebody starts with a key that is published, so anybody can do it, and ends with a key only one person holds, so only that person can read the result. Signing starts with a key only one person holds, so only they can produce it, and ends with a key that is published, so anybody can check. The rule that survives the exam is that the private key sits at the exclusive end: the recipient's end when the property is secrecy, the author's end when it is proof of authorship. Reaching for the wrong one is the most common wrong answer on this objective, and it produces something that looks encrypted and can be read by anybody holding the published key.</figcaption>
</figure>

The pair is symmetric in its mathematics and completely asymmetric in who holds
what. One half is published to everybody and the other is held by one party, and
which of the two you start with decides what property you get.

Watch it work, and then watch it fail.

<details class="predict">
<summary>The order is signed, then one digit of the amount is changed. What does verification say?</summary>

```bash
# AlmaLinux 10.2, x86_64
$ cd /root/keys
printf "transfer 500 to account 12345" > order.txt
echo "signed with the private key:"
openssl pkeyutl -sign -inkey rsa.key -rawin -in order.txt -out order.sig && echo "signature is $(wc -c < order.sig) bytes"
echo
echo "verified with the public key:"
openssl pkeyutl -verify -pubin -inkey rsa.pub -rawin -in order.txt -sigfile order.sig
echo
echo "now change one character of the order and verify again:"
printf "transfer 900 to account 12345" > order2.txt
openssl pkeyutl -verify -pubin -inkey rsa.pub -rawin -in order2.txt -sigfile order.sig
signed with the private key:
signature is 256 bytes

verified with the public key:
Signature Verified Successfully

now change one character of the order and verify again:
40876AA3FFFF0000:error:02000068:rsa routines:ossl_rsa_verify:bad signature:crypto/rsa/rsa_sign.c:441:
40876AA3FFFF0000:error:1C880004:Provider routines:rsa_verify_directly:RSA lib:providers/implementations/signature/rsa_sig.c:1061:
Signature Verification Failure
```

</details>

**Signature Verified Successfully**, then `Signature Verification Failure` after a
single character changed. That is integrity and authorship in one operation:
the signature only verifies against the exact bytes it was made over, and only
against the public key matching the private key that made it.

Digital signatures are what that operation produces, and the property a message
authentication code cannot give you is in there too.
Alice signed with a key only Alice holds, so Alice cannot later claim somebody
else produced it. With a shared key, both parties could have produced the tag, so
neither can prove anything to a third party. That is non-repudiation, and it needs
a key that exactly one party holds.

<details class="deeper">
<summary>If you already sign things: what the numbers say about which algorithm to pick</summary>

RSA and ECDSA are asymmetric in a second way that most material never mentions,
and the machine will say so if you ask it.

```bash
# AlmaLinux 10.2, x86_64
$ openssl speed -seconds 1 rsa2048 ecdsap256 2>/dev/null | tail -6
echo
openssl speed -seconds 1 -evp aes-256-cbc 2>/dev/null | tail -3
                              sign    verify    sign/s verify/s
 256 bits ecdsa (nistp256)   0.0001s   0.0004s   7569.0   2585.0
                               keygen    encaps    decaps keygens/s  encaps/s  decaps/s
                    rsa2048 0.274000s 0.000087s 0.002732s       3.6   11526.0     366.0
                               keygen     signs    verify keygens/s    sign/s  verify/s
                    rsa2048 0.200000s 0.002755s 0.000067s       5.0     363.0   15026.0

The 'numbers' are in 1000s of bytes per second processed.
type             16 bytes     64 bytes    256 bytes   1024 bytes   8192 bytes  16384 bytes
AES-256-CBC      97499.14k   208488.58k   298711.92k   331860.99k   346836.04k   344162.30k
```

RSA signs slowly and verifies fast. ECDSA signs fast and verifies more slowly.
That is not a small difference: RSA verifies about six times faster and signs
about twenty times slower.

Which matters depends on the direction of your traffic. A certificate is signed
once by an authority and verified by every client that ever connects, millions of
times, which is a workload RSA's asymmetry suits. A device signing every telemetry
message it emits and sending them to one collector is the opposite, and a curve
algorithm suits it.

The other consideration is size, and it is the one that bites in constrained
places. The captures below show an RSA-3072 SSH public key at 554 bytes and an
Ed25519 one at 82. On a protocol that exchanges keys and certificates in a
handshake, that difference is paid on every connection.

</details>

## Key length, and why the number does not compare

Two key pairs, generated on the same machine, aiming at comparable strength.

```bash
# AlmaLinux 10.2, x86_64
$ cd /root/keys
echo "an RSA public key, at 2048 bits:"
openssl pkey -pubin -in rsa.pub -text -noout | head -3
echo
echo "an elliptic-curve public key, at 256 bits:"
openssl pkey -pubin -in ec.pub -text -noout | head -3
echo
echo "on disk:"
ls -l rsa.pub ec.pub | tr -s " " | cut -d" " -f5,9
an RSA public key, at 2048 bits:
Public-Key: (2048 bit)
Modulus:
    00:c8:b4:1d:fb:53:4e:5d:b7:cd:6e:74:d7:24:7e:

an elliptic-curve public key, at 256 bits:
Public-Key: (256 bit)
pub:
    04:bf:1b:c1:a2:c0:81:41:5f:dc:d8:07:76:e7:49:

on disk:
178 ec.pub
451 rsa.pub
```

One says 2048 bits and the other says 256, and the smaller one is not eight times
weaker. They are aiming at roughly the same security level against the best known
attacks, and they get there differently because the underlying problems are
different: factoring a large number for RSA, and the discrete logarithm on a curve
for the elliptic curve family.

**Comparing the two numbers directly is the mistake**, and it is a comfortable
mistake because bigger normally means stronger. Within a family it does: RSA-3072
is stronger than RSA-2048. Across families the number means something different
and cannot be read across.

The size difference is visible on disk. The RSA public key above is 451 bytes and
the elliptic curve one is 178.

<details class="deeper">
<summary>If you choose key lengths: what the number buys, and the date on the other side of it</summary>

NIST SP 800-57 Part 1 is the document that maps algorithm and key size to a
security strength in bits and gives dates for how long each is expected to
remain acceptable. It is the reference for this decision, and reading the tables
in it is a better use of an hour than any summary of them.

Two things in it change how people choose. Security strength is expressed in bits
of work for an attacker, so an algorithm at 128-bit security means about 2^128
operations to break, whatever key size it took to get there. And the
recommendations carry time horizons, because the question is not whether a key is
strong today but whether it is strong for as long as the data needs protecting.

That second point is the one that gets skipped, and it is the one that matters
for anything with a long confidentiality requirement. Medical records, sealed
legal material and state secrets have to stay secret for decades, so the key
protecting them has to survive decades of hardware improvement, and the sizing
question is a lifetime question rather than a today question.

It is also why the post-quantum standards exist and why they arrived before there
is a machine to defend against. FIPS 203 specifies a key encapsulation mechanism
built on a problem a quantum computer is not known to solve efficiently, and the
argument for adopting it now is the recording posture from the panel above: data
encrypted today and captured today is decryptable whenever the machine arrives.

</details>

## Across platforms

Generating a key pair is the one operation here that all three platforms do with
the same tool, because OpenSSH ships on all of them.

| Task | Linux | Windows | macOS |
| --- | --- | --- | --- |
| Generate an RSA pair | `ssh-keygen -t rsa -b 3072` | same command, `C:\Windows\System32\OpenSSH` | same command, `/usr/bin/ssh-keygen` |
| Generate a curve pair | `ssh-keygen -t ed25519` | same command | same command |
| Read a key's strength | `ssh-keygen -l -f key.pub` | same command | same command |
| Generate outside a file | `openssl genpkey` | `[Security.Cryptography.RSA]::Create()` | `/usr/bin/openssl genpkey` |

```bash
# AlmaLinux 10.2, x86_64
$ dnf -q -y install openssh >/dev/null 2>&1
cd /tmp
ssh-keygen -t rsa -b 3072 -N "" -f rsa_id -q -C ""
ssh-keygen -t ed25519 -N "" -f ed_id -q -C ""
echo "the public halves, as a client would send them:"
cut -c1-72 rsa_id.pub; echo "  ... $(wc -c < rsa_id.pub) bytes total"
cat ed_id.pub; echo "  ... $(wc -c < ed_id.pub) bytes total"
echo
echo "what ssh-keygen says each one is worth:"
ssh-keygen -l -f rsa_id.pub
ssh-keygen -l -f ed_id.pub
the public halves, as a client would send them:
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCZXf6HZyzrsQbFs1pn/TiDIdwaSJRIiXnx
  ... 554 bytes total
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKzOP7wzVhRPQJ5JKGGOpb3D+Z1xzbhYSYUT3DSNkeEB 
  ... 82 bytes total

what ssh-keygen says each one is worth:
3072 SHA256:09Ktqcj8KS4emJMbwbK0yAG/Tbd9opAqMqquIxD3Gdc no comment (RSA)
256 SHA256:sB24k1xOi1gnhSeAuCcw80Jk5SUD5bbL2Y2K8Bq46kk no comment (ED25519)
```

```powershell
# Microsoft Windows Server 2025 Datacenter, version 10.0.26100.0
> (Get-Command ssh-keygen).Source
C:\Windows\System32\OpenSSH\ssh-keygen.exe

# An RSA key pair
> ssh-keygen -t rsa -b 3072 -N '""' -f "$env:TEMP\rsa_id" -q -C '""'; (Get-Item "$env:TEMP\rsa_id.pub").Length
557

# An elliptic-curve key pair, aiming at comparable strength
> ssh-keygen -t ed25519 -N '""' -f "$env:TEMP\ed_id" -q -C '""'; (Get-Item "$env:TEMP\ed_id.pub").Length
85

# What the tool says each one is worth
> ssh-keygen -l -f "$env:TEMP\rsa_id.pub"; ssh-keygen -l -f "$env:TEMP\ed_id.pub"
3072 SHA256:usquhpgq2oVO5Q3argux6XlDv2plhgIOFlt+a2HBj5A "" (RSA)
256 SHA256:fXp8/qy9+k9zvkFmsMIEwFRn6ON/GYTjDepNhRVDpSM "" (ED25519)

# The other route Windows offers, which does not go through a file
> $rsa = [Security.Cryptography.RSA]::Create(3072); "$($rsa.KeySize) bit RSA, $($rsa.ExportRSAPublicKey().Length) byte public key"
3072 bit RSA, 398 byte public key
```

```bash
# macOS 26.5.2, arm64
$ which -a ssh-keygen && ssh-keygen -V 2>&1 | head -1 || ssh -V 2>&1
/usr/bin/ssh-keygen
ssh-keygen: option requires an argument -- V
OpenSSH_10.2p1, LibreSSL 3.3.6

# An RSA key pair
$ ssh-keygen -t rsa -b 3072 -N '' -f /tmp/rsa_id -q -C '' && wc -c < /tmp/rsa_id.pub
     554

# An elliptic-curve key pair, aiming at comparable strength
$ ssh-keygen -t ed25519 -N '' -f /tmp/ed_id -q -C '' && wc -c < /tmp/ed_id.pub
      82

# What the tool says each one is worth
$ ssh-keygen -l -f /tmp/rsa_id.pub; ssh-keygen -l -f /tmp/ed_id.pub
3072 SHA256:gkDskZ/I8HFmSo/XYInqO/Bn+kkaJ7Qwna7MVLbvPWM no comment (RSA)
256 SHA256:K0IykYpmYa2nTiPbE9iXBZ04am4UIagp6gn0C6wXVq8 no comment (ED25519)

# The key types this build will actually generate
$ ssh -Q key 2>/dev/null | head -8
ssh-ed25519
ssh-ed25519-cert-v01@openssh.com
sk-ssh-ed25519@openssh.com
sk-ssh-ed25519-cert-v01@openssh.com
ecdsa-sha2-nistp256
ecdsa-sha2-nistp256-cert-v01@openssh.com
ecdsa-sha2-nistp384
ecdsa-sha2-nistp384-cert-v01@openssh.com
```

Three things in those blocks are worth more than the commands.

**The sizes agree across platforms.** 554 bytes for the RSA public key on Linux
and macOS, 557 on Windows because of a three-byte comment, and 82 against 85 for
Ed25519. The key material is the same size everywhere because the algorithm
decides it.

**The label reports the family's own number.** `ssh-keygen -l` says 3072 for the
RSA key and 256 for the Ed25519 one, which is exactly the comparison this topic
says not to make. The tool is reporting each family's own measure and it is on
the reader to know they are not the same scale.

**macOS builds its SSH against LibreSSL.** `OpenSSH_10.2p1, LibreSSL 3.3.6` is the
same fork that answers to `/usr/bin/openssl` there. That is consistent rather than
surprising once you have seen it, and it is why a Mac occasionally supports a
different set of algorithms from a Linux machine running the same OpenSSH version.

## Prove it

**Run it.** Generate an RSA key and an Ed25519 key with `ssh-keygen` on any
machine you have. Compare the file sizes of the two public halves and then run
`ssh-keygen -l` on each. Explain to yourself why the smaller file reports the
smaller number and is not the weaker key.

**Work it out.** An RSA-2048 key produces 256 bytes of output. Padding consumes
66 of the input, leaving 190. How many separate RSA operations would it take to
encrypt one megabyte directly, at 363 operations a second on the machine measured
above? Compare that with 0.111 seconds. The ratio is the reason the hybrid design
is not optional.

**Look it up.** NIST SP 800-57 Part 1 Revision 5 maps algorithms and key sizes to
a security strength in bits. Find the table and answer one question: which RSA key
size is listed as comparable to a 256-bit elliptic curve key, and what security
strength are both credited with? The answer is the number this topic says you
cannot read off the label.

## What trips people up

### 1. Treating asymmetric as a slower AES

They solve different problems. AES moves data and cannot get its key to the other
end. RSA and the curve algorithms get a key to the other end and cannot move data.
A system with only one of them does not work.

### 2. Encrypting with the private key to keep something secret

The matching public key is published, so anybody can undo it. The operation
succeeds and produces something that looks encrypted. Secrecy starts with the
recipient's public key; proof of authorship starts with your own private key.

### 3. Reading key lengths across families

3072 and 256 can describe comparable strength. The numbers measure different
things, and choosing the larger number across families gets the decision
backwards while feeling careful.

### 4. Expecting a large file to encrypt with a public key

`data too large for key size` is the algorithm, not a limit somebody set. Tools
that appear to do it are generating a symmetric key underneath.

### 5. Thinking a signature is computed over the document

It is computed over the document's digest. That is why a broken hash function
breaks signatures, and why the hashing topic comes before this one.

### 6. Assuming any key exchange gives forward secrecy

Key transport with the server's long-term key does not: recorded traffic becomes
readable when that key is compromised, however long afterwards. Ephemeral
exchange does, because the keys involved no longer exist.

## Work it through

Back to the two machines that have never met.

**First, name what they actually need.** Not encryption. They need a shared
secret, and once they have one, the encryption part is solved and cheap.

**Then rule out sending it.** Anything either machine transmits, the observer
sees. Encrypting the secret with a symmetric key requires a symmetric key, which
is the problem restated.

**Then the move that works.** Each machine generates a key pair and sends the
public half. Both halves cross the wire in the clear and the observer has both.
Each machine then combines its own private half with the other's public half, and
the mathematics is arranged so that both arrive at the same value while the
observer, holding only the two public halves, cannot compute it. That is a key
exchange, and the observer's disadvantage is that they never see either private
half.

**Then the part everybody skips.** Both machines now share a secret with
somebody. Nothing so far says with whom. An observer able to modify traffic rather
than only watch it can run the exchange twice, once with each machine, and sit in
the middle holding two perfectly good shared secrets. The exchange gives
confidentiality against a passive observer and nothing at all against an active
one.

**So the exchange is signed, and that is where the previous topic's certificate
comes in.** The server signs its side of the exchange with the private key
matching the certificate the client just validated. Now the client knows the
public half it received came from the party named in the certificate. The
exchange gives secrecy, the signature gives identity, and neither is sufficient
without the other.

The decision, written the way it should be written down: ephemeral key exchange
for the secret, signed with the long-term key, and a symmetric cipher for the
data. The rejected option is key transport with the long-term key, and the cost of
rejecting it is a little more computation per connection. The cost of choosing it
would have been every recorded conversation, on the day that key is compromised.

## Try it

**Generate both kinds of key and look at them.** Two commands. Then open the
public halves in a text editor and see how much smaller the curve key is, which is
the abstract point made concrete in about thirty seconds.

**Sign something and then break it.** Sign a short file, verify it, change one
character of the file, and verify again. The failure is the interesting half, and
it takes a minute.

**Find out what your own SSH client will negotiate.** `ssh -Q key` lists the key
types the build supports and `ssh -Q kex` lists the key exchange methods. Look for
which of the exchange methods have an `e` in them for ephemeral, and check whether
anything on the list would give away your recorded traffic.

## Check yourself

<details class="qa">
<summary>Why does every real encrypted protocol use both symmetric and asymmetric cryptography rather than picking the better one?</summary>

Because they solve different problems and neither can do the other's job. A
symmetric cipher moves data quickly and has no way to get its key to the other
end. An asymmetric key pair gets a small secret to the other end and cannot carry
data: an RSA-2048 key accepts at most 190 bytes per operation and returns an
error on anything larger.

So the asymmetric half agrees a symmetric session key, once, and the symmetric
half carries everything after that. The design is not an optimisation, it is the
only arrangement in which both algorithms do something they can actually do.

</details>

<details class="qa">
<summary>You want to send a file that only Bob can read. Which key do you use, and what happens if you use the other one?</summary>

Bob's public key. Only Bob holds the matching private key, so only Bob can undo
it.

Using your own private key produces something anybody can read, because your
public key is published for exactly that purpose. The operation succeeds and the
output looks like ciphertext, which is what makes this mistake survive review.
That direction is for signing, where the point is that only you could have
produced it.

</details>

<details class="qa">
<summary>An Ed25519 key reports 256 bits and an RSA key reports 3072. Is the RSA key twelve times stronger?</summary>

No, and the two numbers are not on the same scale. They measure different
underlying problems, factoring for RSA and the discrete logarithm on a curve for
Ed25519, and both sizes are aiming at roughly comparable strength against the best
known attacks.

Within a family the number does compare: RSA-3072 is stronger than RSA-2048.
Across families it does not, and reading it across produces a decision that feels
careful and is backwards. NIST SP 800-57 gives the mapping, expressed as a
security strength in bits.

</details>

<details class="qa">
<summary>A key exchange gives two strangers a shared secret over a wire everybody can read. What does it not give them, and what fixes that?</summary>

It does not tell either party who they are sharing the secret with. An attacker
who can modify traffic rather than only observe it can run the exchange twice,
once with each side, and hold two perfectly good shared secrets while relaying
between them.

The fix is to sign the exchange with a key bound to an identity, which is what
the certificate from the previous topic is for. The exchange provides secrecy
against a passive observer, the signature provides identity, and neither is
sufficient alone.

</details>

<details class="qa">
<summary>Why did TLS 1.3 remove the option of encrypting the session key with the server's long-term key?</summary>

Because it left recorded traffic decryptable in the future. If the session key is
protected by a key that persists for years, anybody who captures the traffic and
later obtains that key can read every session they recorded, retroactively.

Ephemeral key exchange replaces it: both sides generate a fresh pair per
connection and discard the private halves afterwards, so there is nothing left to
steal. The long-term key is used only to sign the exchange rather than to protect
it, which is what forward secrecy means and why the letter for ephemeral in those
acronyms is the load-bearing one.

</details>

## References

- [FIPS 197](https://csrc.nist.gov/pubs/fips/197/final) - NIST, the Advanced Encryption Standard, which is the symmetric cipher this exam names. Free. Accessed 2026-08-21.
- [FIPS 186-5](https://csrc.nist.gov/pubs/fips/186-5/final) - NIST, the Digital Signature Standard, covering RSA, ECDSA and EdDSA signatures. Free. Accessed 2026-08-21.
- [NIST SP 800-57 Part 1 Rev. 5](https://csrc.nist.gov/pubs/sp/800/57/pt1/r5/final) - NIST, key management, and the source for comparing key sizes across algorithm families by security strength. Free. Accessed 2026-08-21.
- [FIPS 203](https://csrc.nist.gov/pubs/fips/203/final) - NIST, the module-lattice key encapsulation standard, for what replaces the key exchange when the threat model includes a quantum computer. Free. Accessed 2026-08-21.
- [RFC 8446](https://www.rfc-editor.org/rfc/rfc8446.html) - IETF, TLS 1.3, which removed RSA key transport and is the reference for why. Free. Accessed 2026-08-21.

**Where the numbers came from.** Every block on this page is captured. The Linux
blocks ran in AlmaLinux 10.2 on x86_64, pinned by digest; the Windows block on
Windows Server 2025, runner image 20260818.207.1; the macOS block on macOS 26.5.2
arm64, runner image 20260728.0273.1. The rates of 363 RSA signatures, 15,026 RSA
verifications, 7,569 ECDSA signatures and 344 megabytes a second of AES are
`openssl speed` on one core of that container, so the absolute figures belong to
that machine and the ratios between them are the point. The 190-byte input limit
is the error the library returned rather than a figure quoted from documentation.

**If you also work on Linux.** The Linux+ track's
[cryptography basics](/learn/linux-plus/cryptography-basics) topic covers these
operations as things you run on a machine, including how a distribution retires an
algorithm, and
[SSH and secure remote access](/learn/linux-plus/ssh-and-secure-remote-access)
covers what happens to these keys in practice. The Network+ treatment of
[encryption, certificates and PKI](/learn/network-plus/encryption-certificates-and-pki)
covers the handshake these keys are used inside.
