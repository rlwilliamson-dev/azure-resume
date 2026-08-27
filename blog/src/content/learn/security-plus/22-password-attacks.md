---
title: "Password attacks"
description: "Why spraying walks past a lockout that brute force trips, what a password is worth in bits, and a measured hash rate showing what key stretching costs an attacker."
deck: "Sixty accounts, one password attempt each, once an hour. No lockout fires"
track: "security-plus"
level: "working"
order: 230
objectives:
  - "Explain why password spraying defeats an account lockout that brute force trips"
  - "Say which lockout setting decides whether a slow spray is detected"
  - "Calculate the entropy of a password shape in bits and say what one more bit buys"
  - "Explain what key stretching does to an attacker's rate and what it does not do"
  - "Distinguish a policy that reduces guessing from a policy that only creates work"
  - "Say what a leaked-password list does to an entropy estimate"
prerequisites: ["application-and-cryptographic-attacks"]
tags: ["security-plus", "security", "threats", "authentication"]
updated: 2026-08-26
draft: false
examObjectives:
  - exam: "sy0-701"
    domain: "2.0"
    objective: "2.4"
sources:
  - title: "SP 800-63B, Digital Identity Guidelines: Authentication and Lifecycle Management"
    url: "https://pages.nist.gov/800-63-3/sp800-63b.html"
    publisher: "NIST"
    accessed: 2026-08-26
    tier: 1
  - title: "RFC 8018, PKCS #5: Password-Based Cryptography Specification Version 2.1"
    url: "https://www.rfc-editor.org/rfc/rfc8018.html"
    publisher: "IETF"
    accessed: 2026-08-26
    tier: 1
  - title: "RFC 7914, The scrypt Password-Based Key Derivation Function"
    url: "https://www.rfc-editor.org/rfc/rfc7914.html"
    publisher: "IETF"
    accessed: 2026-08-26
    tier: 1
  - title: "CWE-521, Weak Password Requirements"
    url: "https://cwe.mitre.org/data/definitions/521.html"
    publisher: "MITRE"
    accessed: 2026-08-26
    tier: 1
symptoms:
  - symptom: "Failed sign-ins across many accounts with no lockouts"
    anchor: "why-spraying-walks-past-a-lockout"
  - symptom: "A password policy nobody can comply with without writing it down"
    anchor: "policy-that-works-and-policy-that-is-theatre"
---

> **Before you read.** Sixty accounts each receive one wrong password, once an
> hour, for a week. The lockout policy is three failures. Nothing locks, nothing
> alerts, and by Friday one of the accounts has been signed into.
>
> **Which control failed?**

None of them. The lockout worked exactly as configured, and what it is configured
to do is count failures per account. Sixty accounts receiving one failure each is
sixty counts of one, and a count of one is not a lockout on any policy anybody
writes. The attacker did not defeat the control; they arranged not to meet it.

This topic is about that arrangement, and about the arithmetic underneath password
strength, which is the part most policies get wrong in a direction that feels
strict.

### Some words you will need

<dl class="terms">
<dt>brute force</dt>
<dd>Trying many passwords against one account until something works.</dd>
<dt>spraying</dt>
<dd>Trying one password against many accounts, slowly enough that no counter fills.</dd>
<dt>credential stuffing</dt>
<dd>Reusing username and password pairs from one breach against a different service.</dd>
<dt>entropy</dt>
<dd>How large the space of possibilities is, expressed as bits. Each bit doubles it.</dd>
<dt>key stretching</dt>
<dd>Deliberately making one password check slow, so many checks are expensive.</dd>
<dt>salt</dt>
<dd>A per-password random value, so identical passwords do not produce identical stored values.</dd>
<dt>lockout threshold</dt>
<dd>How many failures are allowed before an account is locked.</dd>
<dt>observation window</dt>
<dd>How long a failure stays on the counter before it is forgotten.</dd>
</dl>

## Why spraying walks past a lockout

The claim in the cold open is easy to state and worth watching a real
authentication stack demonstrate, because the counter is the whole mechanism.

<details class="predict">
<summary>A policy of three failures then a lock. Six wrong passwords are sent. Predict what happens when they all hit one account, and when they are spread across six.</summary>

```bash
# AlmaLinux 10.2, x86_64
$ lockout
policy: deny = 3, unlock_time = 600

six wrong passwords, all aimed at one account
  attempt 1  denied   failures on record: 1
  attempt 2  denied   failures on record: 2
  attempt 3  denied   failures on record: 3
  attempt 4  denied   failures on record: 3
  attempt 5  denied   failures on record: 3
  attempt 6  denied   failures on record: 3
  right password now accepted for alice: no

six wrong passwords, one aimed at each of six accounts
  account  failures on record   right password accepted
  bob      1                    yes
  carol    1                    yes
  dave     1                    yes
  erin     1                    yes
  frank    1                    yes
```

**Six failures locked one account. The same six failures locked nothing.**

The first block is the ordinary case. Three failures fill the counter, the fourth
through sixth are refused without being counted, and the account is now unusable
even by the person who owns it, which is the last line of that block.

The second block is the attack. Every account has one failure on record, every
account still authenticates, and the total number of wrong passwords sent was
identical. Nothing in the policy was violated and nothing needs to be bypassed,
because a per-account counter has no opinion about a pattern across accounts.

Which tells you where detection has to live. The lockout is a per-account control
and the behaviour is not a per-account behaviour, so it will never be visible from
inside the mechanism. Somebody has to be looking at failures across the estate,
counted by source rather than by target, and that is a monitoring job rather than
an authentication setting.

</details>

**And the second consequence is the account owner's.** A lockout that fires is a
denial of service you configured against yourself. Anybody who can produce failed
attempts against a named account can lock that account, which is why an aggressive
threshold on a public-facing service is a weapon somebody hands the attacker.

<details class="deeper">
<summary>Choosing the two numbers: the threshold, the window, and why the second one is the one that matters</summary>

A lockout policy has two settings and people argue about the wrong one.

**The threshold is how many failures are allowed.** Lowering it feels like
tightening security and mostly generates helpdesk calls, because ordinary users
mistype passwords, phones retry stale credentials in the background, and a service
account with an old password in a configuration file will fill any counter you set.

**The observation window is how long a failure is remembered**, and it sets the
sustainable guessing rate. If the threshold is five and the window is thirty
minutes, an attacker who sends four guesses every thirty minutes never trips
anything, and that is 192 guesses per account per day, forever. The Windows capture
further down this page shows a machine running a threshold of ten with a window of
ten minutes, which permits nine guesses every ten minutes: 1,296 per account per
day, against every account, without a single lockout event.

**So the honest reading is that a lockout is not a rate limit.** It stops the
fastest kind of guessing and it sets a floor on how slow the attacker has to be. If
your threat model includes somebody patient, the lockout has bought you patience
rather than safety.

**What actually addresses the slow case** is a second factor, which makes the
password insufficient regardless of how many guesses are permitted, and detection
counted by source address and by the ratio of failures to successes across the
estate. Neither is a setting on the account.

**And there is a third setting worth naming**, which is what happens on unlock.
Automatic unlock after the duration expires keeps the helpdesk out of it and gives
the attacker their guesses back on a schedule. Manual unlock does the reverse and
costs a person's time every occurrence. That is a real trade with no free option,
and the usual resolution is automatic unlock plus alerting on the pattern.

</details>

## What a password is worth, in bits

Password strength is arithmetic, and the arithmetic has two halves that people
routinely conflate: how large the space of possibilities is, and how fast an
attacker can search it. The second half is not a property of the password at all.

<details class="predict">
<summary>The same candidate password, checked against five ways of storing it. Predict how much the storage choice changes an attacker's rate.</summary>

```bash
# AlmaLinux 10.2, aarch64
$ hashrate
one core of this container, timed now

how the password is stored    guesses per second  costs the attacker
SHA-256, raw                          14,175,860                  1x
PBKDF2-SHA256, 10k rounds                  1,090             13,002x
PBKDF2-SHA256, 600k rounds                    18            777,004x
scrypt, n=16384 r=8 p=1                       43            331,370x
```

**Nearly six orders of magnitude, from one storage decision.**

Raw SHA-256 is fast because it was designed to be fast, which is the correct
property for a digest and the wrong one for a password. Fourteen million candidates
a second on a single core of a container is a floor rather than an estimate:
purpose-built hardware and many cores go further, and nothing about the ratios in
the third column changes when they do.

The stretched rows are the same digest with a deliberate cost attached. PBKDF2 at
600,000 rounds is the same SHA-256 repeated, which is why the attacker's cost lands
near the round count. scrypt asks for memory as well as time, which is why it sits
where it does here and why it behaves differently against hardware designed to
parallelise.

The part worth holding on to: the defender pays this cost once per sign-in, where
a few tens of milliseconds is invisible. The attacker pays it once per guess.

</details>

<details class="predict">
<summary>An eight character password using every character class against twelve lower case letters. Predict which one takes longer to exhaust.</summary>

```bash
# AlmaLinux 10.2, aarch64
$ exhaust
measured here: 14,027,033/s raw SHA-256, 18/s PBKDF2 at 600k rounds

password shape               bits       raw digest          stretched
8 chars, all four classes    52.6          7 years        6e+06 years
10 chars, all four classes   65.7     67,630 years        5e+10 years
12 chars, lower case only    56.4        108 years        8e+07 years
16 chars, lower case only    75.2      5e+07 years        4e+13 years
4 words from a 7776 list     51.7          4 years        3e+06 years
6 words from a 7776 list     77.5      2e+08 years        2e+14 years
```

**The twelve lower case letters, by a factor of about fifteen.**

The eight character password with all four classes is the one every policy asks
for, and it comes to 52.6 bits. Twelve lower case letters, which no policy would
accept, comes to 56.4. Four bits is not a rounding difference: each bit doubles the
work, so four bits is sixteen times the search.

The reason is in the multiplication. Adding a character class widens the alphabet,
and the alphabet is inside the logarithm. Adding a character multiplies the whole
space, and appears outside it. Ninety-five possibilities per position against
twenty-six is worth 6.57 bits per character against 4.70, but the second password
has four more characters to spend that on.

Then look at the last two rows, which are the passphrase case. Four words chosen at
random from a list of 7,776 is 51.7 bits, near enough the same as the eight
character mixed password and considerably easier to type and remember. Six words is
77.5 bits, past the point where either column means anything.

**One caution about the numbers themselves.** These times assume the password was
chosen uniformly at random from the stated space. Nothing chosen by a person is,
which is what the panel below this one is about, so read the table as an upper
bound on strength rather than a promise.

</details>

<figure class="learn-figure">
<svg viewBox="0 0 720 320" role="img" aria-labelledby="entropy-title" style="width:100%;height:auto;">
<title id="entropy-title">Six password shapes plotted by how long an exhaustive search takes at the two rates measured on this page, showing where extra length stops buying anything usable</title>
<g fill="currentColor">
<text x="14" y="20" font-size="11">how long an exhaustive search takes, at the two rates measured on this page</text>
<text x="14" y="42" font-size="9" fill-opacity="0.85">each row is one password shape, plotted twice: once stored as a raw digest and once stretched</text>
<line x1="238" y1="66" x2="238" y2="218" stroke="currentColor" stroke-opacity="0.2" stroke-width="1"/>
<line x1="302" y1="66" x2="302" y2="218" stroke="currentColor" stroke-opacity="0.2" stroke-width="1"/>
<line x1="365" y1="66" x2="365" y2="218" stroke="currentColor" stroke-opacity="0.2" stroke-width="1"/>
<text x="238" y="60" font-size="8" text-anchor="middle" fill-opacity="0.7">1 year</text>
<text x="302" y="60" font-size="8" text-anchor="middle" fill-opacity="0.7">100 years</text>
<text x="365" y="60" font-size="8" text-anchor="middle" fill-opacity="0.7">10,000 years</text>
<text x="14" y="79" font-size="9">4 words, 7776 list, 52 bits</text>
<circle cx="257" cy="76" r="4" fill="var(--red)" fill-opacity="0.85"/>
<circle cx="445" cy="76" r="4" fill="var(--accent)" fill-opacity="0.85"/>
<text x="14" y="105" font-size="9">8 chars, all classes, 53 bits</text>
<circle cx="266" cy="102" r="4" fill="var(--red)" fill-opacity="0.85"/>
<circle cx="454" cy="102" r="4" fill="var(--accent)" fill-opacity="0.85"/>
<text x="14" y="131" font-size="9">12 chars, lower case, 56 bits</text>
<circle cx="303" cy="128" r="4" fill="var(--red)" fill-opacity="0.85"/>
<circle cx="491" cy="128" r="4" fill="var(--accent)" fill-opacity="0.85"/>
<text x="14" y="157" font-size="9">10 chars, all classes, 66 bits</text>
<circle cx="392" cy="154" r="4" fill="var(--red)" fill-opacity="0.85"/>
<circle cx="580" cy="154" r="4" fill="var(--accent)" fill-opacity="0.85"/>
<text x="14" y="183" font-size="9">16 chars, lower case, 75 bits</text>
<circle cx="483" cy="180" r="4" fill="var(--red)" fill-opacity="0.85"/>
<circle cx="671" cy="180" r="4" fill="var(--accent)" fill-opacity="0.85"/>
<text x="14" y="209" font-size="9">6 words, 7776 list, 78 bits</text>
<circle cx="506" cy="206" r="4" fill="var(--red)" fill-opacity="0.85"/>
<circle cx="694" cy="206" r="4" fill="var(--accent)" fill-opacity="0.85"/>
<circle cx="152" cy="229" r="4" fill="var(--red)" fill-opacity="0.85"/>
<text x="162" y="232" font-size="8.5" fill-opacity="0.85">raw digest</text>
<circle cx="246" cy="229" r="4" fill="var(--accent)" fill-opacity="0.85"/>
<text x="256" y="232" font-size="8.5" fill-opacity="0.85">stretched</text>
<text x="14" y="262" font-size="10">past about sixty-five bits both columns exceed any horizon, and more length buys nothing</text>
<text x="14" y="282" font-size="9" fill-opacity="0.8">the gap between the two dots is identical on every row, because it is the storage choice rather than the password</text>
<text x="14" y="304" font-size="9" fill-opacity="0.7">which is why the storage decision is worth more than the policy: it moves every password at once</text>
</g></svg>
<figcaption>The six shapes from the capture above, placed on a logarithmic time axis. Two things are visible here that the table makes you calculate. The rows are ordered by entropy, and the ordering is not the ordering a password policy would produce: twelve lower case letters outrank the eight character password with every character class in it. And the distance between each pair of dots never changes, because it is not a fact about the password at all. It is the difference between storing a raw digest and stretching, applied identically to every account you have. Somewhere around the fourth row both dots have passed any horizon a human being can act on, and past that point additional entropy is real but no longer purchasable in outcomes.</figcaption>
</figure>

<details class="deeper">
<summary>Where the arithmetic stops describing reality, and what a leaked-password list does to it</summary>

Every number in that table assumes the password was drawn uniformly at random from
the space, and human beings do not do that.

**A person picks from a much smaller space and the formula cannot see it.** Capital
letter first, digits at the end, one substituted character, a word that means
something to them. The formula scores the result on its shape, so a ten character
mixed password scores 65.7 bits by the table above, and if the same string appears
in a published list of previously breached passwords its real cost to an attacker
is a lookup.

**Which is what a list does to the estimate.** A list of a billion entries is about
thirty bits of search, so any password on it is worth at most thirty bits no matter
what its shape suggests, and usually far less because the list is ordered by
frequency and the common ones are tried first. That single fact explains the
guidance to check new passwords against known-breached lists, which is a much
larger improvement than any composition rule.

**And it explains why credential stuffing is a different attack.** Stuffing does
not guess. It replays a username and password that were genuinely correct
somewhere, betting on reuse, and the entropy of the password is irrelevant to it. A
sixteen character passphrase reused across two services offers the second service
no protection at all once the first is breached.

**The practical consequence for a policy.** Composition rules push people toward
predictable transformations, so the measured strength gained is smaller than the
formula suggests and the usability cost is real. Length floors, a breached-password
check, and no forced rotation without evidence of compromise are the guidance that
follows from taking the arithmetic seriously rather than from being relaxed about
it.

</details>

## Policy that works and policy that is theatre

Sorting a password policy into the parts that reduce guessing and the parts that
only produce work is a short exercise once the arithmetic is in front of you.

**A length floor works**, because length is the term that multiplies the space and
it is the only requirement a person can satisfy without inventing a pattern.

**A breached-password check works**, because it removes the passwords whose real
cost is a lookup, and those are the ones actually being tried.

**Stretched storage works and is not a policy at all.** It is a decision made once
by whoever runs the authentication system, it applies to every existing password
without asking anybody to change anything, and the measurement above shows what it
buys. No user-facing rule available to you comes close to a factor of seven hundred
thousand.

**A second factor works**, by making the password insufficient rather than stronger.

**Composition rules mostly produce patterns.** Requiring an upper case letter
produces a capital at the front. Requiring a digit produces a one or a year at the
end. The space widens on paper and the part of it people use does not.

**Scheduled rotation without evidence produces worse passwords**, because a person
asked to invent a new one every sixty days will iterate the old one, and the
iteration is guessable from the previous value if that value ever leaks.

**And a maximum length is a defect**, worth naming because it is common and it
signals something else. A cap on password length usually means the value is being
stored somewhere with a column width, which means it may not be being hashed the
way you would hope.

<details class="deeper">
<summary>Salt, pepper, and why a rainbow table stopped being the thing to worry about</summary>

Two values get added to a password before it is stored and only one of them is a
secret, which is most of the confusion.

**A rainbow table is precomputation.** Someone hashes an enormous number of
candidate passwords once, stores the results in a form that trades storage against
lookup time, and then any stolen database of unsalted digests is answered by
lookup rather than by search. The economics are what make it work: the table is
built once and serves every system using that algorithm, forever.

**A salt destroys that economics.** It is a per-password random value, stored
alongside the digest and not secret, and its only job is to make every stored value
unique. Two accounts with the identical password now store different digests, so a
precomputed table matches nothing and an attacker has to search each password
separately.

**What a salt does not do is slow anything down.** One guess against one salted
digest costs the same as one guess against an unsalted one, which is why the
measurement above needs only a single raw digest row. Salting changes how many
times the attacker has to run the search, not how fast each run goes. Stretching is
the control that changes the rate, and the two are complementary rather than
alternatives.

**A pepper is the secret one.** It is a value applied to every password and stored
somewhere other than the database, in a key management service or a hardware
module, so a stolen database alone is not enough to test candidates offline at all.
It is real protection with a real operational cost: rotating it means rehashing
every password, and losing it means every account has to reset.

**And the exam distinction is the one sentence version.** Salt is per password and
public and defeats precomputation. Pepper is global and secret and defeats offline
guessing with the database alone. Stretching is neither and defeats speed.

</details>

## Across platforms

Where the failure counter lives, and whether anything is watching it, is an
operating system question with three different answers.

**Linux has nothing until you configure it.** The capture at the top of this page
had to install a counting module, write a threshold into its configuration and
stack it into an authentication service before any of it existed. A default
installation counts nothing, which is worth knowing before assuming a lockout is
protecting a Linux host.

**Windows ships with a policy already running.**

```powershell
# Microsoft Windows Server 2025 Datacenter, version 10.0.26100.0
> net accounts
Force user logoff how long after time expires?:       Never
Minimum password age (days):                          0
Maximum password age (days):                          42
Minimum password length:                              0
Length of password history maintained:                None
Lockout threshold:                                    10
Lockout duration (minutes):                           10
Lockout observation window (minutes):                 10
Computer role:                                        SERVER
The command completed successfully.

# The same settings as the security database records them, including the complexity switch
> secedit /export /areas SECURITYPOLICY /cfg "$env:TEMP\pol.inf" > $null; Select-String -Path "$env:TEMP\pol.inf" -Pattern 'Lockout|PasswordComplexity|MinimumPasswordLength|PasswordHistorySize' | ForEach-Object { $_.Line.Trim() }
MinimumPasswordLength = 0
PasswordComplexity = 1
PasswordHistorySize = 0
LockoutBadCount = 10
ResetLockoutCount = 10
LockoutDuration = 10
AllowAdministratorLockout = 1

# Whether a failed sign-in is recorded at all, since a lockout nobody can see is one nobody investigates
> auditpol /get /subcategory:"Logon" 2>&1 | Select-String 'Logon' | ForEach-Object { $_.Line.Trim() }
Logon/Logoff
Logon                                   Success and Failure
```

The two numbers that matter are on the same screen. A threshold of ten with an
observation window of ten minutes permits nine wrong passwords every ten minutes
against any account indefinitely, which is 1,296 a day, and the machine will never
report a lockout. Note also that the minimum password length here is zero while
complexity is switched on, which is the composition rule arriving without the
length floor that would have done more.

The last block is the one people forget to check. Logon auditing is recording both
successes and failures, and without that there is nothing for detection to count
even if somebody is looking.

**macOS keeps the counter whether or not anything is using it.**

```bash
# macOS 26.5.2, arm64
$ out=$(pwpolicy -getglobalpolicy 2>&1); printf '%s\n' "${out:-nothing returned}"
nothing returned

# The account policy for this user, which is where a failed-attempt limit would appear
$ out=$(pwpolicy -u "$(id -un)" -getaccountpolicies 2>&1 | tail -n +2); printf '%s\n' "${out:-nothing returned}"
nothing returned

# Whether a per-account failure counter exists even when no policy is acting on it
$ dscl . -readpl "/Users/$(id -un)" accountPolicyData failedLoginCount 2>&1 | head -3
failedLoginCount: 0

# When that counter last moved, which is the other half of any rate limit
$ dscl . -readpl "/Users/$(id -un)" accountPolicyData failedLoginTimestamp 2>&1 | head -3
failedLoginTimestamp: 0

# Whether any configuration profile is installed, since that is how a limit arrives on a managed Mac
$ sudo profiles show -type configuration 2>&1 | head -4
There are no configuration profiles installed in the system domain
```

No global policy and no account policy are set, so nothing is enforcing a
threshold. The counter exists anyway and reads zero, along with the timestamp that
would let a window be applied to it. The last line names how the policy usually
arrives on a managed Mac: as a configuration profile pushed by whatever manages the
fleet, which is the same mechanism the mobile device topic describes, and on this
machine there is none.

**Which gives the comparison one sentence.** All three platforms can count
failures per account, none of them counts anything across accounts, and the spray
in the first capture works identically on all three for that reason.

## Try it

**Configure a threshold and spread the failures.** On a machine you own, set a low
lockout threshold and then send the threshold's worth of failures spread across
several accounts. Confirm that nothing locks.

**Read your own observation window.** Find the two lockout numbers on a system you
administer and multiply out the permitted guesses per account per day. The answer
is usually larger than people expect.

**Time a hash.** Measure how long one password verification takes on your
authentication system. If it is under a millisecond, the storage is not stretched,
and that is a fixable decision that improves every account at once.

**Score two passwords.** Take an eight character password with every character
class and a passphrase of four random words, and compute the bits for each. Then
ask which one the policy would accept.

## Check yourself

<details class="qa">
<summary>Why does spraying defeat a lockout that brute force trips?</summary>

Because the counter is kept per account. Six wrong passwords against one account
fill a threshold of three and lock it, and the same six spread across six accounts
leave one failure on each, which locks nothing. The capture on this page shows both
outcomes from the identical number of attempts.

The behaviour is only visible from outside the mechanism, by counting failures
across the estate by source rather than by target, which is a monitoring job rather
than an authentication setting.

</details>

<details class="qa">
<summary>Which lockout setting decides the sustainable guessing rate?</summary>

The observation window, because it sets how long a failure is remembered. A
threshold of ten with a ten minute window permits nine guesses every ten minutes
indefinitely, which is 1,296 per account per day with no lockout ever recorded.

The threshold on its own only decides how fast the fastest attempt can be. Lowering
it tends to generate helpdesk calls and hands anybody who can produce failures a
way to lock a named account deliberately.

</details>

<details class="qa">
<summary>Why does twelve lower case letters beat eight characters using all four classes?</summary>

Because length multiplies the space and the alphabet only widens it. Ninety-five
possibilities per position is 6.57 bits against 4.70 for twenty-six, but the longer
password has four more positions to spend, which comes to 56.4 bits against 52.6.

Four bits is sixteen times the search, since each bit doubles it. The capture on
this page puts the two at 108 years and 7 years against a raw digest at the rate
measured there.

</details>

<details class="qa">
<summary>What does key stretching change, and what does it not?</summary>

It changes the attacker's rate, by a factor near the work parameter. The
measurement on this page shows PBKDF2 at 600,000 rounds costing an attacker roughly
777,000 times what a raw digest costs, on the same hardware with the same password.

It does not change the size of the password space, so a password on a breached list
is still found quickly. It also does not help if the attacker can bypass the check
entirely, which is what stolen session tokens and credential stuffing do.

</details>

<details class="qa">
<summary>What does a published list of breached passwords do to an entropy estimate?</summary>

It caps it. A list of a billion entries is about thirty bits of search, so any
password on it is worth at most thirty bits regardless of what its shape scores,
and usually less because such lists are ordered by frequency.

That is why checking new passwords against known-breached lists is a larger
improvement than any composition rule, which mostly moves people toward predictable
transformations rather than into the wider space it appears to open.

</details>

## References

- [SP 800-63B](https://pages.nist.gov/800-63-3/sp800-63b.html) - NIST, authentication guidance, including the position on composition rules, rotation and breached-password checks. Free. Accessed 2026-08-26.
- [RFC 8018](https://www.rfc-editor.org/rfc/rfc8018.html) - IETF, PKCS #5, which defines PBKDF2 and the iteration count that appears in the measurement. Free. Accessed 2026-08-26.
- [RFC 7914](https://www.rfc-editor.org/rfc/rfc7914.html) - IETF, scrypt, for why a memory cost behaves differently from a time cost. Free. Accessed 2026-08-26.
- [CWE-521](https://cwe.mitre.org/data/definitions/521.html) - MITRE, weak password requirements, for the defect framing of a maximum length. Free. Accessed 2026-08-26.

**Where the content came from.** The lockout block drives PAM directly against six
throwaway accounts created inside an AlmaLinux 10.2 container, with a threshold
configured for the purpose. No remote system is contacted and the only passwords
used are the ones the container was given. The timing blocks are captured on
aarch64 rather than amd64, because the amd64 container runs under emulation on this
machine and its timings would measure the emulator rather than the hash. The raw
digest rate comes from `openssl speed`, because timing a raw SHA-256 from Python
would measure Python's call overhead instead; the stretched rates are timed from
Python, where a single call takes milliseconds and the interpreter disappears into
the noise. No password list is used anywhere in this topic and nothing is cracked:
the same candidate is hashed repeatedly and the clock is read.

**If you also work on networks.** The Network+ track's
[device hardening and network access control](/learn/network-plus/device-hardening-and-network-access-control)
covers the account side of hardening a device you administer.
