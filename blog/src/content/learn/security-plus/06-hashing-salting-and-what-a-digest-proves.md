---
title: "Hashing, salting, and what a digest proves"
description: "What a hash function promises and what it does not, why the same password can be stored two different ways, what a salt actually removes from an attacker, and why the defence against a stolen password file is a number somebody chooses."
deck: "The defence against a stolen password file is a number you set"
track: "security-plus"
level: "intro"
order: 70
objectives:
  - "Say what a digest proves and what it cannot tell you"
  - "Explain why a fast hash is right for a download and wrong for a password"
  - "Describe what a salt removes from an attacker, given that it is not secret"
  - "Explain key stretching, and read a work factor as a cost"
  - "Choose a hash for a stated job and say why the alternatives are wrong"
prerequisites: []
tags: ["security-plus", "security", "cryptography", "hashing"]
updated: 2026-08-21
draft: false
examObjectives:
  - exam: "sy0-701"
    domain: "1.0"
    objective: "1.4"
sources:
  - title: "FIPS 180-4, Secure Hash Standard"
    url: "https://csrc.nist.gov/pubs/fips/180-4/upd1/final"
    publisher: "NIST"
    accessed: 2026-08-21
    tier: 1
  - title: "FIPS 202, SHA-3 Standard"
    url: "https://csrc.nist.gov/pubs/fips/202/final"
    publisher: "NIST"
    accessed: 2026-08-21
    tier: 1
  - title: "NIST SP 800-63B, Digital Identity Guidelines: Authentication and Authenticator Management"
    url: "https://csrc.nist.gov/pubs/sp/800/63/b/upd2/final"
    publisher: "NIST"
    accessed: 2026-08-21
    tier: 1
  - title: "NIST SP 800-132, Recommendation for Password-Based Key Derivation"
    url: "https://csrc.nist.gov/pubs/sp/800/132/final"
    publisher: "NIST"
    accessed: 2026-08-21
    tier: 1
  - title: "RFC 8018, PKCS #5: Password-Based Cryptography Specification Version 2.1"
    url: "https://www.rfc-editor.org/rfc/rfc8018.html"
    publisher: "IETF"
    accessed: 2026-08-21
    tier: 1
symptoms:
  - symptom: "Two users have the same string in the password column"
    anchor: "what-a-salt-actually-removes"
---

> **Before you read.** A company stores its passwords as SHA-256 digests. No
> plain text anywhere, a modern algorithm, nothing obviously wrong.
>
> The database is stolen on a Friday. By Monday most of the passwords are known.
>
> **Nothing was broken and nothing was reversed. What happened?**

A hash function turns any input into a fixed-length number, and it is easy to run
in one direction and infeasible in the other. Everything useful about it follows
from that, and so does every mistake people make with it.

### Some words you will need

<dl class="terms">
<dt>hash function</dt>
<dd>A function that turns any input into a fixed-length output, quickly, and cannot be run backwards.</dd>
<dt>digest</dt>
<dd>The output. Also called a hash or a checksum, depending on who is talking.</dd>
<dt>collision</dt>
<dd>Two different inputs producing the same digest. Always possible, and the question is how hard it is to find one on purpose.</dd>
<dt>salt</dt>
<dd>A random value stored alongside a digest and hashed with the input. Not a secret.</dd>
<dt>key stretching</dt>
<dd>Making a hash deliberately slow by running it many times, so guessing costs the attacker real time.</dd>
<dt>work factor</dt>
<dd>The number that controls how slow. A parameter somebody chooses, and the thing being tuned.</dd>
<dt>rainbow table</dt>
<dd>Digests computed in advance for a large set of likely inputs, so an attacker looks up rather than computes.</dd>
</dl>

## What breaks without this

**A stolen password file becomes a list of passwords.** Not because anything was
decrypted, but because guessing is cheap and most people choose from a small set.

**Two users with the same password are visible as such.** Identical stored strings
mean an attacker who cracks one account has cracked every account that shares it,
across every site that stored it the same way.

**You use the wrong tool and it looks right.** The command runs, the digest looks
like a digest, and the difference between the correct choice and the wrong one is
invisible until somebody steals the file.

## What a digest promises

Three properties, and it is worth being precise because the exam distinguishes
them.

**It is deterministic.** The same input always gives the same digest, on any
machine, in any implementation. That is what makes it useful for checking whether
two things are the same.

**It is one-way.** Given a digest, you cannot compute the input. Not "it is hard";
the function throws information away, so the input is not in there to recover.

**It is collision-resistant.** Two different inputs can produce the same digest,
because there are infinitely many inputs and a fixed number of outputs. What a
good function promises is that finding such a pair on purpose is infeasible.

Here is the property people underestimate, measured.

<details class="predict">
<summary>Two inputs differing by one character. How much of the digest do you expect to change?</summary>

```bash
# AlmaLinux 10.2, x86_64
$ cmp -l /tmp/a /tmp/b | wc -l
sha256sum /tmp/a /tmp/b
python3 -c "
import hashlib
a=hashlib.sha256(open(\"/tmp/a\",\"rb\").read()).digest()
b=hashlib.sha256(open(\"/tmp/b\",\"rb\").read()).digest()
print(\"bits different in the two digests:\", sum(bin(x^y).count(\"1\") for x,y in zip(a,b)), \"of 256\")"
1
c4bbcb1fbec99d65bf59d85c8cb62ee2db963f0fe106f483d9afa73bd4e39a8a  /tmp/a
a87bf8a3fe15ac43d063fba9aeb6e57f7e51a14a6de32a9e6ee96dce7e98898a  /tmp/b
bits different in the two digests: 125 of 256
```

</details>

One byte different in the input, **125 of the 256 bits different in the digest**,
which is about as close to half as you would expect from flipping a coin 256
times. That is the avalanche effect, and its consequence is the useful part: a
digest tells you nothing about how close a guess was. There is no getting warmer.
Every wrong guess is equally wrong, which is why you cannot walk towards an
answer and have to try candidates one at a time.

<details class="deeper">
<summary>If you already use hashes: what collision resistance costs, and why the numbers halve</summary>

Two different attacks are named on this exam and they need different amounts of
work, which is why the distinction between them matters.

Finding an input that produces a specific digest is a preimage attack, and it
costs on the order of 2^n for an n-bit digest. For SHA-256 that is 2^256, which
is not happening.

Finding any two inputs that collide is a birthday attack, and it costs on the
order of 2^(n/2), because you are looking for any pair rather than a specific
match. For SHA-256 that is 2^128, still not happening. For MD5 at 128 bits it is
2^64, which was reachable years ago, and MD5 collisions can now be produced in
seconds.

So an algorithm's advertised strength against collisions is half its digest
length in bits, and that halving is the whole reason a 128-bit digest is not
"strong enough for now". It is 64-bit strength against the attack people actually
run.

The practical consequence is which uses survive a broken function. MD5 as an
integrity check against accidental corruption is still fine, because random
corruption does not construct a collision. MD5 anywhere an adversary chooses the
input is finished, because they can construct one.

</details>

## Back to the stolen file

Nothing was reversed on that Friday. The attacker guessed, and guessing was
cheap, and the reason it was cheap is in the next block.

<details class="predict">
<summary>How many plain SHA-256 hashes do you think one core computes in a second?</summary>

```bash
# AlmaLinux 10.2, x86_64
$ python3 - <<PY
import hashlib, time
pw=b"hunter2"; salt=b"a-salt-value"
t=time.perf_counter(); n=0
while time.perf_counter()-t < 2.0:
    hashlib.sha256(pw); n+=1
rate=n/(time.perf_counter()-t)
print(f"plain sha256: {rate:,.0f} per second on one core")
for iters in (1_000, 100_000, 600_000):
    t=time.perf_counter()
    hashlib.pbkdf2_hmac("sha256", pw, salt, iters)
    d=time.perf_counter()-t
    print(f"pbkdf2-sha256 at {iters:>7,} iterations: {d*1000:8.1f} ms per guess, {1/d:12,.0f} guesses per second")
PY
plain sha256: 380,985 per second on one core
pbkdf2-sha256 at   1,000 iterations:      3.7 ms per guess,          273 guesses per second
pbkdf2-sha256 at 100,000 iterations:    139.7 ms per guess,            7 guesses per second
pbkdf2-sha256 at 600,000 iterations:    846.0 ms per guess,            1 guesses per second
```

</details>

**380,985 per second, on one core, in an interpreted language.** A serious
attacker is not using one core or Python; they are using a graphics card and
counting in billions. Against a file of unsalted SHA-256 digests, every candidate
they try is tested against every account in the file at once, because identical
passwords produce identical digests.

The problem is not SHA-256. SHA-256 is doing exactly what it was designed to do,
which is to be fast. The problem is that speed is a feature for verifying a
download and a defect for storing a password, and the same function is being
asked to do both jobs.

<figure class="learn-figure">
<svg viewBox="0 0 720 296" role="img" aria-labelledby="wf-title" style="width:100%;height:auto;">
<title id="wf-title">Guesses per second on one core, measured, falling from 380,985 for a plain SHA-256 to about one per second at 600,000 PBKDF2 iterations, drawn on a logarithmic scale</title>
<g fill="currentColor">
<text x="14" y="20" font-size="11">guesses per second on one core, measured, on a log scale</text>
<text x="14" y="58" font-size="10">plain sha256</text>
<rect x="150" y="46" width="420" height="16" rx="2" fill="var(--red)" fill-opacity="0.32" stroke="var(--red)" stroke-width="1.6"/>
<text x="580" y="58" font-size="10">380,985</text>
<text x="14" y="98" font-size="10">pbkdf2 1,000</text>
<rect x="150" y="86" width="183" height="16" rx="2" fill="currentColor" fill-opacity="0.22" stroke="currentColor" stroke-opacity="0.7"/>
<text x="343" y="98" font-size="10">273</text>
<text x="14" y="138" font-size="10">pbkdf2 100,000</text>
<rect x="150" y="126" width="64" height="16" rx="2" fill="currentColor" fill-opacity="0.22" stroke="currentColor" stroke-opacity="0.7" stroke-dasharray="4 3"/>
<text x="224" y="138" font-size="10">7</text>
<text x="14" y="178" font-size="10">pbkdf2 600,000</text>
<rect x="150" y="166" width="6" height="16" rx="1" fill="var(--accent)" fill-opacity="0.5" stroke="var(--accent)" stroke-width="1.4"/>
<text x="166" y="178" font-size="10">1</text>
<path d="M 150 196 V 40" stroke="currentColor" stroke-opacity="0.3" stroke-width="1"/>
<text x="14" y="228" font-size="10" fill-opacity="0.85">the algorithm did not get stronger between the first row and the last</text>
<text x="14" y="250" font-size="10" fill-opacity="0.85">one number changed, and it is a number you set</text>
<text x="14" y="272" font-size="10" fill-opacity="0.85">the top bar is a defence an attacker with one laptop defeats in an afternoon</text>
</g></svg>
<figcaption>Measured on one core of an AlmaLinux container, so the absolute figures belong to that machine and the ratio is the point. Between the first row and the last the hash function is the same SHA-256; what changed is the iteration count, which is a parameter somebody chooses. A stolen password file hashed with a plain digest is 380,985 guesses per second per core against every account at once. The same file at 600,000 iterations is about one guess per second per core, which is a factor of roughly 380,000, and the attacker's hardware has to grow by that factor to stand still. That is the whole of key stretching: the defence is the cost, and unlike almost everything else on this exam it is a dial rather than a decision between products.</figcaption>
</figure>

**The bottom row is the same algorithm.** Nothing about SHA-256 changed between
380,985 guesses a second and one. What changed is that it was run 600,000 times
instead of once, and that number is a parameter somebody set. That is key
stretching, and the thing worth carrying is that the defence is a cost you choose
rather than a product you buy.

<details class="deeper">
<summary>If you set these numbers: how a work factor is chosen against hardware you do not own</summary>

The choice is a budget rather than a security level, and it runs in one
direction: how long are you willing to make your own login take.

Pick a target for the server, typically somewhere between 100 and 500
milliseconds per verification, and set the iteration count to hit it on your
hardware. That is the whole method. Everything else follows: your cost is fixed
by your own tolerance, and the attacker's cost is fixed by the same number
against much better hardware.

Two things make that harder than it sounds. Your login is not the only thing
using the CPU, so a work factor sized on an idle machine becomes a denial of
service under load, and a login storm after an outage is exactly when it bites.
And the attacker's hardware improves while your parameter does not, which means
the number needs revisiting rather than setting.

The second problem is what the memory-hard functions address. PBKDF2 costs an
attacker time, and time is the thing a graphics card is best at buying in
parallel. A function that also demands a large amount of memory per guess costs
them silicon rather than clock cycles, which is much harder to parallelise
cheaply. That is the argument for scrypt and Argon2 over PBKDF2, and it is an
argument about the attacker's hardware rather than about the mathematics.

The parameter also has to be stored with the digest, which is why the strings in
the next section carry their own settings. A file of digests you cannot verify
because you changed the setting is not a security improvement.

</details>

## What a salt actually removes

Two users pick the same password. Watch what gets stored.

```bash
# AlmaLinux 10.2, x86_64
$ echo "the same password, hashed twice, unsalted:"
printf "hunter2" | sha256sum
printf "hunter2" | sha256sum
echo
echo "the same password, hashed twice with a random salt each time:"
openssl passwd -6 hunter2
openssl passwd -6 hunter2
the same password, hashed twice, unsalted:
f52fbd32b2b3b86ff88ef6c490628285f482af15ddcb29541f94bcf526a3f6c7  -
f52fbd32b2b3b86ff88ef6c490628285f482af15ddcb29541f94bcf526a3f6c7  -

the same password, hashed twice with a random salt each time:
$6$G0QD8eCmwlyOc6QS$TRmkS5QOvXorjiqBvglQNy3WTKBfbLOboFl.Ftz8sjAS7m9X0hIczd6jtjvz6cAUD1vFehNlrsv3vqTHAV02i/
$6$3n.rQnFQIJz0jXMj$HIt0F9xo7PRY/lOfvUSxSxb7hbwH67S8g5LBdZA.td0UA62Z.n8fK.ItsOhyr6CVFWib0f9glq89IomXQzJOZ0
```

The first two lines are identical, which is the whole problem in two lines. The
second two share nothing, and neither user's stored string reveals that they
chose the same password as the other.

<figure class="learn-figure">
<svg viewBox="0 0 720 300" role="img" aria-labelledby="salt-title" style="width:100%;height:auto;">
<title id="salt-title">The same password stored for two users, unsalted it produces one identical digest that a precomputed table matches once for both, and salted it produces two unrelated strings that the same table matches neither of</title>
<g fill="currentColor">
<text x="14" y="20" font-size="11">two users, one password, and what a precomputed table gets in each case</text>
<text x="14" y="48" font-size="10" fill-opacity="0.85">unsalted</text>
<rect x="100" y="58" width="420" height="56" rx="4" fill="none" stroke="currentColor" stroke-opacity="0.7" stroke-width="1.4"/>
<text x="112" y="77" font-size="9.5">alice   f52fbd32b2b3b86ff88ef6c490628285f482af15</text>
<text x="112" y="97" font-size="9.5">bob     f52fbd32b2b3b86ff88ef6c490628285f482af15</text>
<path d="M 530 86 H 566" stroke="var(--red)" stroke-opacity="0.9" stroke-width="1.6"/>
<path d="M 558 81 L 568 86 L 558 91" fill="none" stroke="var(--red)" stroke-opacity="0.9" stroke-width="1.6"/>
<text x="574" y="82" font-size="10" fill="var(--red)" fill-opacity="0.95">table hits</text>
<text x="574" y="98" font-size="10" fill="var(--red)" fill-opacity="0.95">both at once</text>
<text x="14" y="152" font-size="10" fill-opacity="0.85">salted</text>
<rect x="100" y="162" width="420" height="56" rx="4" fill="none" stroke="var(--accent)" stroke-width="1.6"/>
<text x="112" y="181" font-size="9.5">alice   $6$G0QD8eCmwlyOc6QS$TRmkS5QOvXorjiqB</text>
<text x="112" y="201" font-size="9.5">bob     $6$3n.rQnFQIJz0jXMj$HIt0F9xo7PRY/lOf</text>
<path d="M 530 190 H 566" stroke="currentColor" stroke-opacity="0.6" stroke-width="1.6" stroke-dasharray="4 3"/>
<text x="574" y="186" font-size="10">same table</text>
<text x="574" y="202" font-size="10">hits neither</text>
<text x="14" y="248" font-size="10" fill-opacity="0.85">the salt is stored next to the digest and is not a secret</text>
<text x="14" y="270" font-size="10" fill-opacity="0.85">what it removes is the attacker's ability to attack every account at once</text>
<text x="14" y="292" font-size="10" fill-opacity="0.85">a table built for alice's salt is worthless against bob, and has to be built again</text>
</g></svg>
<figcaption>The digests are real, truncated to fit. Unsalted, two users who chose the same password store the same string, so a table computed once matches every account that uses that password anywhere in the world, and the attacker's cost is paid once for all of them. Salted, the two rows share nothing: the sixteen characters between the second and third dollar signs are a random value generated per user, and the stored digest is of the password and that value together. The salt is not a secret and is stored in plain sight beside the digest, which is what confuses people about it. It is not hiding anything. It is making the attacker do the work once per account instead of once per password.</figcaption>
</figure>

**A salt is not a secret and it is not hiding anything.** It is sitting in plain
text in the same field, between the second and third dollar signs, and an
attacker who steals the file has it. That is the fact people find hardest to
accept about salting, and it is the point.

What the salt removes is the attacker's ability to attack every account at once.
Without it, one computation of a candidate password is tested against the entire
file, and a table computed once is reusable against every file in the world.
With it, each account needs its own computation of every candidate, so the
attacker's cost multiplies by the number of accounts rather than staying flat.

The `$6$` at the front is worth reading too. That field names the algorithm, so
the same file can hold entries written by different schemes, and a system can
verify an old entry while writing new ones a better way.

<details class="deeper">
<summary>If you have designed a store: pepper, and where the salt is not enough</summary>

A salt protects against precomputation and parallel attack. It does nothing about
the attacker having the file, because it was never meant to.

A pepper is the response to that: a secret value, the same for every account,
hashed in alongside the password but stored somewhere the database is not.
Usually that means the application's configuration, or better, a hardware
security module that computes the operation without releasing the value.

The property it buys is specific and worth being precise about. If the attacker
steals the database and not the pepper, every digest is useless to them,
because they cannot compute a candidate without it. If they steal both, the
pepper has bought nothing.

That makes it a real control with a narrow threat model: it protects against
database-only compromise, which is the shape of a SQL injection or a stolen
backup, and not against a full application compromise. Whether that is worth the
operational cost is a decision, and the cost is real, because rotating a pepper
means rehashing every stored digest and you cannot do that without the plain
text you deliberately do not have.

</details>

## Choosing one

Four questions decide it, and they decide it quickly.

**Is an adversary choosing the input?** If not, and you are checking for
accidental corruption, almost anything works and speed is what you want. If they
are, collision resistance matters and MD5 and SHA-1 are out.

**Is it a password?** Then no general-purpose hash is the answer, however modern.
You want a password hashing function with a work factor: PBKDF2, bcrypt, scrypt
or Argon2. This is the question people get wrong, and they get it wrong by
reasoning about the strength of the algorithm rather than about the speed of it.

**Does somebody need to prove they wrote it?** A digest proves nothing about who
computed it, because anybody can compute one. That needs a signature, which is
topic 07.

**Does it need a shared secret?** A message authentication code is a hash with a
key, and it proves the message came from somebody holding that key. Both parties
have the key, so it does not prove which of them, which is the difference between
a MAC and a signature and a favourite of exam writers.

<details class="deeper">
<summary>If you already choose these: why a MAC is not a hash of the key and the message</summary>

The obvious way to build a keyed hash is to concatenate the key and the message
and hash the result. That construction is broken against the hash functions this
exam names, and the reason is worth knowing because it explains why HMAC exists
and looks the way it does.

SHA-256 and its relatives process a message in blocks and carry state forward, so
the digest of a message is also the state the function was in when it finished.
An attacker who has that digest can continue from it, appending data of their
choosing and producing a valid digest for the longer message, without ever
knowing the key. That is a length extension attack, and it turns "hash the key
then the message" into a signature anybody can extend.

HMAC's answer is to hash twice with two derived keys, which breaks the chain: the
outer hash starts from a state the attacker does not have. That is the whole
reason for the nested structure, and it is why the correct instruction is always
to use HMAC rather than to build the obvious thing.

The functions that do not have this property, including SHA-3, were designed with
a different internal construction. The safe habit is to reach for the named
primitive rather than to compose one, which is a general rule in this subject and
one of the few places it is genuinely absolute.

</details>

## Across platforms

This is the one comparison table in the track where all three columns print the
same answer, because a digest is arithmetic rather than a policy. The commands
differ and the output must not.

| Task | Linux | Windows | macOS |
| --- | --- | --- | --- |
| Hash a file | `sha256sum file` | `Get-FileHash file -Algorithm SHA256` | `shasum -a 256 file` |
| The other named tool | `openssl dgst -sha256` | `certutil -hashfile file SHA256` | `/usr/bin/openssl dgst -sha256` |
| Hash a string | `printf '...' \| sha256sum` | `[Security.Cryptography.SHA256]` on the bytes | `printf '...' \| shasum -a 256` |
| Salted password hash | `openssl passwd -6` | not a base tool | not a base tool |

```powershell
# Microsoft Windows Server 2025 Datacenter, version 10.0.26100.0
> $b = [Text.Encoding]::UTF8.GetBytes('correct horse battery staple'); (([Security.Cryptography.SHA256]::Create().ComputeHash($b) | ForEach-Object { $_.ToString('x2') }) -join '')
c4bbcb1fbec99d65bf59d85c8cb62ee2db963f0fe106f483d9afa73bd4e39a8a

# The cmdlet a reader would actually use, against a file holding those bytes
> [IO.File]::WriteAllBytes("$env:TEMP\a", $b); (Get-FileHash "$env:TEMP\a" -Algorithm SHA256).Hash.ToLower()
c4bbcb1fbec99d65bf59d85c8cb62ee2db963f0fe106f483d9afa73bd4e39a8a

# The other tool the exam names for this, which prints the same digest
> certutil -hashfile "$env:TEMP\a" SHA256
SHA256 hash of C:\Users\RUNNER~1\AppData\Local\Temp\a:
c4bbcb1fbec99d65bf59d85c8cb62ee2db963f0fe106f483d9afa73bd4e39a8a
CertUtil: -hashfile command completed successfully.

# What the machine can hash with, since the algorithm is a choice
> Get-Command Get-FileHash | ForEach-Object { $_.Parameters['Algorithm'].Attributes.ValidValues } | Sort-Object
MD5
SHA1
SHA256
SHA384
SHA512
```

```bash
# macOS 26.5.2, arm64
$ which sha256sum shasum
/sbin/sha256sum
/opt/homebrew/bin/shasum

# What the sha256sum on this machine actually is
$ ls -l "$(which sha256sum)"
-rwxr-xr-x  6 root  wheel  136576 Jun 25 02:29 /sbin/sha256sum

# The same twenty-eight bytes the Linux and Windows captures hash
$ printf 'correct horse battery staple' | shasum -a 256
c4bbcb1fbec99d65bf59d85c8cb62ee2db963f0fe106f483d9afa73bd4e39a8a  -

# And through the openssl Apple ships, since a reader may reach for it
$ printf 'correct horse battery staple' | /usr/bin/openssl dgst -sha256
c4bbcb1fbec99d65bf59d85c8cb62ee2db963f0fe106f483d9afa73bd4e39a8a

# Which algorithms the shipped tool offers, since the algorithm is a choice
$ shasum --help 2>&1 | grep -iE "^  -a|--algorithm"
  -a, --algorithm   1 (default), 224, 256, 384, 512, 512224, 512256
```

**Every digest in those two blocks matches the Linux one**, character for
character, and matches the one at the top of this page. That is not a small
observation. Almost everything else in this track has a different answer
depending on where you type it, and this is the case where a Linux instruction, a
PowerShell cmdlet and a BSD tool are all computing the same function over the same
twenty-eight bytes.

Two platform details are worth having. **Windows names five algorithms** on
`Get-FileHash`, including MD5 and SHA-1, which are still there because integrity
checking against accidental corruption is a legitimate use and removing them
would break it. And **macOS does ship `sha256sum`**, at `/sbin/sha256sum`, which
is a surprise if you have been told to expect only `shasum`. Note where `shasum`
resolved on that machine, though: `/opt/homebrew/bin/shasum` rather than the
system one, which is the same PATH question that decides which `openssl` you get.

## Prove it

**Run it.** Hash the same short string on every machine you have access to, with
the command for each platform from the table above. Confirm the digests match.
Then change one character and confirm that essentially none of the digest
survives.

**Work it out.** A password is chosen from lowercase letters and digits, 36
characters, and is eight long. That is 36^8 possibilities, which is about 2.8
trillion. At the plain SHA-256 rate measured above, 380,985 per second on one
core, how long does an exhaustive search take? Now do it at one guess per second.
Then ask what a hundred cores does to each answer, and which of the two is still
safe.

**Look it up.** NIST SP 800-63B covers memorised secret verifiers. Read what it
says about how a verifier should store them and answer one question: does it
require a salt, and does it name a minimum iteration count? The answer to the
second is the more interesting one, because it tells you what kind of requirement
this is.

## What trips people up

### 1. Storing passwords with a general-purpose hash

SHA-256 is a good hash function and the wrong tool here. It is fast on purpose,
and fast is what you are trying to prevent. The fix is a password hashing
function with a work factor, not a longer digest.

### 2. Thinking a salt is a secret

It is stored in plain text next to the digest and the attacker has it. It defeats
precomputed tables and forces per-account work. It does not hide anything and was
never meant to.

### 3. Reading a digest as a similarity measure

One character of input changes about half the digest. Two digests being "close"
means nothing at all, and there is no partial credit on a guess.

### 4. Assuming a digest proves who produced it

Anybody can compute a digest of anything. It proves the content has not changed
since somebody wrote the digest down, provided you trust where you got the digest
from. Authorship needs a key.

### 5. Treating MD5 as uniformly broken

It is broken for anything where an adversary chooses the input, because
collisions can be constructed in seconds. As a check against accidental
corruption it still works, which is why it is still in every tool.

### 6. Comparing digests with a string comparison

An equality check that returns as soon as it finds a difference leaks how much of
the digest matched, through how long it took. Verification code uses a
constant-time comparison, and this is a real class of bug rather than a
theoretical one.

## Work it through

Back to the company whose database went on Friday.

**First, what was stored.** SHA-256 digests, no salt, one round. Nothing about
that is broken, and nothing had to be. The attacker did not attack the
algorithm.

**Then what it cost the attacker.** They took a list of the few hundred million
passwords that have appeared in previous breaches, hashed each one once, and
compared the results against the whole file. Every account that used any of those
passwords fell out in a single pass, because identical passwords produce
identical digests and the work is done once for the file rather than once per
account. At the rate measured on this page, a few hundred million candidates is
minutes.

**What a salt would have changed.** The work would have become per account. The
same candidate list against ten thousand salted accounts is ten thousand times
the computation, and no precomputed table helps at all. That is a large multiplier
and it is not sufficient on its own, because a determined attacker will still
spend it on the accounts they care about.

**What the work factor would have changed.** At 600,000 iterations, one guess
costs about a second of a core instead of about three microseconds. That is the
factor of 380,000 in the figure, and it is the one that turns "most passwords by
Monday" into "the handful of genuinely terrible ones, eventually".

The decision, written the way it should be written down: store with a password
hashing function at a work factor tuned to about 250 milliseconds on the
production hardware, with a per-account salt. The rejected option is a
general-purpose digest with a salt, and the cost of rejecting it is nothing,
because the salted-but-fast option still loses the common passwords in the first
pass.

Notice which half did the work. The salt stops the attack scaling. The work factor
stops the attack being cheap. You need both, and most of the failures in public
have been files that had neither.

## Try it

**Hash something on your own machine and check the avalanche.** One command, then
change a character, then compare. You do not need a lab and it takes a minute.

**Time a stretched hash on your own hardware.** Most languages have PBKDF2 in the
standard library. Time it at a few iteration counts and find the number that
takes about a quarter of a second on your machine. That is what choosing a work
factor actually is, and doing it once removes all the mystery.

**Look at a password file you are entitled to look at.** On a Linux machine you
control, the second field of `/etc/shadow` carries the algorithm identifier, the
salt and the digest, separated by dollar signs. Read one and identify the three
parts. Do not do this on a machine that is not yours.

## Check yourself

<details class="qa">
<summary>A file of unsalted SHA-256 password digests is stolen. Nothing is decrypted, and most passwords are known within days. How?</summary>

By guessing, cheaply and in parallel across the whole file. Candidate passwords
are hashed once each and compared against every row, because identical passwords
produce identical digests without a salt.

The algorithm was not attacked and nothing was reversed. SHA-256 is fast by
design, so a few hundred million candidates from previous breaches costs minutes,
and the work is done once for the file rather than once per account.

</details>

<details class="qa">
<summary>A salt is stored in plain text next to the digest, where an attacker who steals the file can read it. What is it for?</summary>

To make the attacker's work per account instead of per password. It defeats
precomputed tables entirely, because a table is built for one salt and is useless
against any other, and it stops one computed candidate being tested against every
row at once.

It hides nothing and is not meant to. Two users with the same password store
completely different strings, so the fact that they share one is no longer
visible either.

</details>

<details class="qa">
<summary>One character of the input changes and about half the digest changes. Why does that matter to an attacker?</summary>

Because there is no signal of getting closer. A wrong guess produces a digest
unrelated to the right one, so an attacker cannot walk towards the answer and has
to test candidates one at a time.

That is why the only defences that work against guessing are making each guess
expensive, which is key stretching, and making the number of plausible guesses
large, which is password length.

</details>

<details class="qa">
<summary>What is the difference between a message authentication code and a digital signature, given that both prove a message was not altered?</summary>

The key. A MAC uses a secret shared by both parties, so either of them could have
produced the tag and neither can prove the other did. A signature uses the
sender's private key, which only the sender holds.

So a MAC gives integrity and authenticity between two parties who already trust
each other, and a signature adds non-repudiation, which is the ability to
demonstrate to a third party who produced it.

</details>

<details class="qa">
<summary>MD5 collisions can be produced in seconds. Why is MD5 still present in every hashing tool?</summary>

Because collision resistance is only one of its properties and only some uses
need it. Checking whether a file was corrupted in transit or on disk is a check
against accidents, and random corruption does not construct a collision.

It is finished anywhere an adversary chooses the input, which includes
signatures, certificates and integrity checks on anything downloaded from
somewhere you do not control. The distinction is the threat model rather than the
algorithm.

</details>

## References

- [FIPS 180-4](https://csrc.nist.gov/pubs/fips/180-4/upd1/final) - NIST, the Secure Hash Standard, which specifies SHA-1 and the SHA-2 family including SHA-256. Free. Accessed 2026-08-21.
- [FIPS 202](https://csrc.nist.gov/pubs/fips/202/final) - NIST, the SHA-3 standard, which is a different construction rather than a longer SHA-2. Free. Accessed 2026-08-21.
- [NIST SP 800-63B](https://csrc.nist.gov/pubs/sp/800/63/b/upd2/final) - NIST, digital identity guidelines, and the source to read on how a verifier should store a memorised secret. Free. Accessed 2026-08-21.
- [NIST SP 800-132](https://csrc.nist.gov/pubs/sp/800/132/final) - NIST, the recommendation for password-based key derivation, which is where the iteration count and salt requirements are set out. Free. Accessed 2026-08-21.
- [RFC 8018](https://www.rfc-editor.org/rfc/rfc8018.html) - IETF, PKCS #5, which specifies PBKDF2 itself. Free. Accessed 2026-08-21.

**Where the numbers came from.** Every block on this page is captured. The Linux
blocks ran in AlmaLinux 10.2 on x86_64, pinned by digest; the Windows block on
Windows Server 2025, runner image 20260818.207.1; the macOS block on macOS 26.5.2
arm64, runner image 20260728.0273.1. The rate of 380,985 hashes a second and the
PBKDF2 timings are one core of that container measured in Python, so the absolute
figures belong to that machine and the ratio between them is the point. The 125
differing bits are computed from the two digests printed above them.

**If you also work on Linux.** The Linux+ track's
[cryptography basics](/learn/linux-plus/cryptography-basics) topic covers the same
functions from the point of view of running them on a machine, including
retiring an algorithm across a whole system, and
[password policy and MFA](/learn/linux-plus/password-policy-and-mfa) covers
configuring the stored form on RHEL and Debian.
