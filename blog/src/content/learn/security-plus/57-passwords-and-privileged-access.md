---
title: "Passwords and privileged access"
description: "What the arithmetic actually says about length against complexity, why forced expiry made passwords worse, what just-in-time elevation removes that a vault does not, and the break-glass account that has to exist."
deck: "The administrator account password is in a document called passwords.docx"
track: "security-plus"
level: "working"
order: 580
objectives:
  - "Compare length and complexity by the size of the search space each produces"
  - "Say why the stored hash decides whether any password policy is adequate"
  - "Explain why forced expiry was withdrawn from current guidance"
  - "Say what a password manager changes and what it concentrates"
  - "Describe what just-in-time elevation removes that vaulting does not"
  - "Design a break-glass account and say how it is controlled"
prerequisites: ["factors-and-multifactor-authentication"]
tags: ["security-plus", "security", "operations", "identity", "authentication"]
updated: 2026-08-25
draft: false
examObjectives:
  - exam: "sy0-701"
    domain: "4.0"
    objective: "4.6"
sources:
  - title: "SP 800-63B, Digital Identity Guidelines: Authentication and Lifecycle Management"
    url: "https://csrc.nist.gov/pubs/sp/800/63/b/upd2/final"
    publisher: "NIST"
    accessed: 2026-08-25
    tier: 1
  - title: "RFC 9106, Argon2 Memory-Hard Function for Password Hashing and Proofs of Work"
    url: "https://www.rfc-editor.org/rfc/rfc9106.html"
    publisher: "IETF"
    accessed: 2026-08-25
    tier: 1
  - title: "SP 800-53 Rev. 5, Security and Privacy Controls"
    url: "https://csrc.nist.gov/pubs/sp/800/53/r5/upd1/final"
    publisher: "NIST"
    accessed: 2026-08-25
    tier: 1
  - title: "chage manual page"
    url: "https://man7.org/linux/man-pages/man1/chage.1.html"
    publisher: "man7.org"
    accessed: 2026-08-25
    tier: 1
symptoms:
  - symptom: "A complex password policy is in force and accounts keep being compromised"
    anchor: "the-arithmetic-nobody-does"
  - symptom: "Administrators hold privileges they use twice a year"
    anchor: "standing-privilege-and-the-window-it-leaves"
---

> **Before you read.** The administrator password for a production system is
> twelve characters, contains an uppercase letter, a digit and a symbol, is
> changed every ninety days, and is written in a document called `passwords.docx`
> because four people need it.
>
> **Which of those five facts is the problem?**

The last one, by a wide margin, and the fourth is making it worse. Three of the
five are the policy working as designed, and the design is what produced the
document.

### Some words you will need

<dl class="terms">
<dt>search space</dt>
<dd>How many possible passwords a policy permits. The only thing that matters about a policy's strength.</dd>
<dt>entropy</dt>
<dd>The size of that space expressed in bits, so numbers of wildly different magnitudes can be compared.</dd>
<dt>slow hash</dt>
<dd>A password hashing function designed to be expensive, so guessing is expensive too.</dd>
<dt>maximum age</dt>
<dd>How long before a password must be changed. Withdrawn from current guidance as a routine measure.</dd>
<dt>minimum age</dt>
<dd>How soon it may be changed again, which exists to stop people cycling back.</dd>
<dt>vaulting</dt>
<dd>Storing a privileged credential centrally and releasing it under control.</dd>
<dt>just in time</dt>
<dd>Granting privilege for a stated period and removing it afterwards, rather than holding it.</dd>
<dt>ephemeral credential</dt>
<dd>One created for a session and never valid again.</dd>
<dt>break glass</dt>
<dd>The account that works when the identity system does not.</dd>
</dl>

## What breaks without this

**A complex policy is enforced and accounts still fall.** The policy governs one
attack and the successful one was a password reused from somewhere else, which no
composition rule addresses.

**Expiry produces predictable passwords.** People change one character, keep a
pattern, and the ninety-day cycle produces a sequence anybody can extrapolate.

**A shared administrative password ends up in a file.** Four people need it, no
mechanism exists for four people to have their own, and the document is the
rational response to the constraint.

**An administrator holds privilege permanently for work they do twice a year.**
The credential is worth taking on any day of the year rather than on two of them.

## The arithmetic nobody does

Password policy arguments are conducted in adjectives. They can be conducted in
numbers instead, and the numbers change the conclusion.

<details class="predict">
<summary>Eight characters with every character class required, against sixteen lowercase letters. Predict which is harder to guess, and by roughly how much.</summary>

```bash
# AlmaLinux 10.2, x86_64
$ search-space 100000000000; echo; echo "the same policies, if the stored hash is a deliberately slow one:"; search-space 20000 | tail -4
policy                                     combinations   bits  average time to guess
8 chars, upper lower digit symbol             6.634e+15   52.6  0.4 days
10 chars, upper lower digit symbol            5.987e+19   65.7  9 years
12 chars, lower case only                     9.543e+16   56.4  5.5 days
16 chars, lower case only                     4.361e+22   75.2  6,914 years
4 random words from a 7776-word list          3.656e+15   51.7  0.2 days

assuming 100,000,000,000 guesses a second, offline against a fast hash

the same policies, if the stored hash is a deliberately slow one:
16 chars, lower case only                     4.361e+22   75.2  34,570,604,150 years
4 random words from a 7776-word list          3.656e+15   51.7  2,898 years

assuming 20,000 guesses a second, offline against a deliberately slow one
```

**Sixteen lowercase letters, by a factor of about six and a half million.** Fifty
two and a half bits against seventy five, which is four days against nearly seven
thousand years at the same guess rate.

That is the case for length over complexity and it is the easy half of this
output. The harder half is the last row.

Four random words from a large list is the recommendation everybody has heard, and
at this guess rate it falls in about five hours, because it is fifty one and a
half bits, which is slightly *less* than the eight-character complex password it
was supposed to replace. The advice was sound when it was written against a much
slower assumed rate, and repeating it without the rate attached has made it
folklore.

Now read the second table. The same five policies, unchanged, against a
deliberately slow hash, and every one of them is fine. The four-word passphrase
goes from five hours to nearly three thousand years, having changed by not one
character.

**So the policy question cannot be answered without the storage question.** A
composition rule governs the size of the space. The hashing function governs how
fast somebody can search it, and it moves the answer by seven orders of magnitude,
which is more than any policy change available to you.

The practical order that follows: fix the hash first, then set a length minimum,
then check against a list of known-breached passwords, and treat character class
requirements as the least useful of the four.

</details>
<details class="deeper">
<summary>If you set a length minimum: where the ceiling comes from, and the field nobody checks</summary>

Setting a minimum length is the highest-value password policy change available and
there are two adjacent settings that undo it quietly.

The first is the maximum. Systems that impose one are common, the value is
frequently low, and the reason is almost always a legacy field width or a hashing
implementation that truncates. Truncation is the dangerous case: a system that
silently uses the first eight characters accepts a forty-character passphrase,
reports success, and stores the strength of an eight-character password. Nothing
in the interface says so, and the only way to find out is to test it by
authenticating with a deliberately wrong tail.

That test is worth running against anything holding privileged credentials. Set a
long password, then try to log in with the first eight characters followed by
something else. If it works, the field is truncating.

The second is the permitted character set. A system that rejects spaces or
punctuation is not merely inconvenient; it is usually signalling that the password
is being interpolated somewhere it should not be, and the restriction exists to
avoid breaking something rather than to improve anything. Current guidance is
explicit that all printable characters including spaces should be accepted, and a
system that refuses is worth asking about.

The third thing worth checking, since it is in the same family, is what happens on
paste. A field that blocks pasting prevents the use of a password manager, which
means it enforces passwords that a human can retype, which means shorter and
reused ones. It is a usability decision with a direct and negative security
consequence, and it persists because whoever added it believed the opposite.

</details>


## Why expiry was withdrawn

Forced ninety-day expiry was standard advice for two decades and current guidance
recommends against it as a routine measure. The reasoning is worth knowing because
somebody will ask you to defend removing it.

**It was designed for a threat it no longer addresses.** Expiry limits how long a
compromised password remains useful. When compromise meant a slow offline attack
against a stolen hash, shortening the window helped. Today a compromised password
is typically used within hours, sometimes minutes, so a ninety-day limit expires
it long after it has been used.

**And it degrades the passwords themselves.** Somebody required to produce a new
password every quarter, twelve years running, does not generate forty-eight
unrelated strong passwords. They produce a pattern with a counter in it, and the
pattern is guessable from any one instance.

**What replaced it** is a set of conditions rather than a schedule. Change on
evidence of compromise. Check new passwords against lists of known-breached ones,
which addresses reuse, the actual dominant failure. Set a length minimum and stop
imposing composition rules. And add a second factor, which does far more than any
password policy can.

Minimum age is the field that survives and it is worth knowing why. It stops
somebody changing a password five times in an afternoon to cycle back to the one
they wanted, which is the direct response to a history requirement. It only exists
because expiry does, so an organisation removing routine expiry can usually remove
this too.

<details class="deeper">
<summary>If you have to defend removing expiry: the sentence that lands, and the case where it stays</summary>

The argument that lands with somebody who has enforced ninety-day expiry for a
decade is not about guessing rates. It is this: expiry assumes a compromised
password will be used slowly, and it is not.

Walk it through and it is difficult to dispute. Credentials harvested by phishing
are used within hours because the attacker knows the window is short. Credentials
from a breached third party are tested against your estate in bulk, quickly, as
soon as the list circulates. In both cases the password has done its damage long
before day ninety, and the expiry has cost every employee four password changes a
year and produced a predictable sequence.

The place expiry does still earn its place is shared credentials, and that is the
exception worth conceding immediately rather than arguing. If four people know a
password, rotation is the only thing that removes access from somebody who
leaves, because there is no account to disable. So a service account password, a
shared administrative credential or a wireless pre-shared key genuinely should
rotate, and the reason has nothing to do with guessing.

Notice what that concession implies. Expiry survives exactly where individual
accountability has failed, which turns the conversation into one about eliminating
shared credentials rather than about the rotation schedule. That is the more
useful conversation and the concession is what opens it.

The second case worth conceding: a password that has ever been transmitted or
stored somewhere it should not have been. That is change-on-evidence rather than
routine expiry, and current guidance is explicit about it.

</details>

## Password managers, and what they concentrate

A password manager fixes the thing composition rules never could, which is reuse.
Every site gets a different long random string, nobody remembers any of them, and
the credential-stuffing attack that causes most account compromises stops working.

**It concentrates the risk into one place**, which is the objection everybody
raises and it is worth answering precisely rather than dismissing. The
concentration is real. It is also a trade against a distributed failure that is
currently certain, because password reuse across dozens of sites is the actual
state of affairs, and one well-protected vault is a better position than forty
poorly-chosen passwords three of which are identical.

The properties that make the trade work are worth checking rather than assuming:
the vault is encrypted with a key derived from the master password using a slow
function, the provider cannot read it, and the vault itself is behind a second
factor.

**Passwordless is where this is going**, and it is worth being clear that it is not
a password with extra steps. A passkey is a private key held by a device and
unlocked locally, so there is no shared secret to steal, nothing to phish, and
nothing for a server breach to yield beyond public keys. The recovery problem from
the previous topic applies with full force, and it is the honest remaining
weakness.

## Standing privilege and the window it leaves

The other half of this objective is administrative access, and the question it
turns on is not who holds privilege but for how long.

<figure class="learn-figure">
<svg viewBox="0 0 720 264" role="img" aria-labelledby="jit-title" style="width:100%;height:auto;">
<title id="jit-title">Standing administrative privilege against just-in-time privilege, with the window during which a stolen credential is useful drawn to the same scale across one year</title>
<g fill="currentColor">
<text x="14" y="20" font-size="11">one administrator, one year, and the time a stolen credential is worth having</text>
<text x="14" y="58" font-size="9.5">standing privilege</text>
<rect x="150" y="44" width="540" height="26" rx="3" fill="var(--red)" fill-opacity="0.30" stroke="var(--red)" stroke-opacity="0.8" stroke-width="1.4"/>
<text x="420" y="61" text-anchor="middle" font-size="8.5">privileged for all 8,760 hours of the year</text>
<text x="14" y="112" font-size="9.5">just in time</text>
<rect x="150" y="98" width="3" height="26" rx="1" fill="var(--accent)" fill-opacity="0.9" stroke="var(--accent)" stroke-width="0.8"/>
<rect x="172" y="98" width="3" height="26" rx="1" fill="var(--accent)" fill-opacity="0.9" stroke="var(--accent)" stroke-width="0.8"/>
<rect x="195" y="98" width="3" height="26" rx="1" fill="var(--accent)" fill-opacity="0.9" stroke="var(--accent)" stroke-width="0.8"/>
<rect x="218" y="98" width="3" height="26" rx="1" fill="var(--accent)" fill-opacity="0.9" stroke="var(--accent)" stroke-width="0.8"/>
<rect x="240" y="98" width="3" height="26" rx="1" fill="var(--accent)" fill-opacity="0.9" stroke="var(--accent)" stroke-width="0.8"/>
<rect x="262" y="98" width="3" height="26" rx="1" fill="var(--accent)" fill-opacity="0.9" stroke="var(--accent)" stroke-width="0.8"/>
<rect x="285" y="98" width="3" height="26" rx="1" fill="var(--accent)" fill-opacity="0.9" stroke="var(--accent)" stroke-width="0.8"/>
<rect x="308" y="98" width="3" height="26" rx="1" fill="var(--accent)" fill-opacity="0.9" stroke="var(--accent)" stroke-width="0.8"/>
<rect x="330" y="98" width="3" height="26" rx="1" fill="var(--accent)" fill-opacity="0.9" stroke="var(--accent)" stroke-width="0.8"/>
<rect x="352" y="98" width="3" height="26" rx="1" fill="var(--accent)" fill-opacity="0.9" stroke="var(--accent)" stroke-width="0.8"/>
<rect x="375" y="98" width="3" height="26" rx="1" fill="var(--accent)" fill-opacity="0.9" stroke="var(--accent)" stroke-width="0.8"/>
<rect x="398" y="98" width="3" height="26" rx="1" fill="var(--accent)" fill-opacity="0.9" stroke="var(--accent)" stroke-width="0.8"/>
<rect x="420" y="98" width="3" height="26" rx="1" fill="var(--accent)" fill-opacity="0.9" stroke="var(--accent)" stroke-width="0.8"/>
<rect x="442" y="98" width="3" height="26" rx="1" fill="var(--accent)" fill-opacity="0.9" stroke="var(--accent)" stroke-width="0.8"/>
<rect x="465" y="98" width="3" height="26" rx="1" fill="var(--accent)" fill-opacity="0.9" stroke="var(--accent)" stroke-width="0.8"/>
<rect x="488" y="98" width="3" height="26" rx="1" fill="var(--accent)" fill-opacity="0.9" stroke="var(--accent)" stroke-width="0.8"/>
<rect x="510" y="98" width="3" height="26" rx="1" fill="var(--accent)" fill-opacity="0.9" stroke="var(--accent)" stroke-width="0.8"/>
<rect x="532" y="98" width="3" height="26" rx="1" fill="var(--accent)" fill-opacity="0.9" stroke="var(--accent)" stroke-width="0.8"/>
<rect x="555" y="98" width="3" height="26" rx="1" fill="var(--accent)" fill-opacity="0.9" stroke="var(--accent)" stroke-width="0.8"/>
<rect x="578" y="98" width="3" height="26" rx="1" fill="var(--accent)" fill-opacity="0.9" stroke="var(--accent)" stroke-width="0.8"/>
<rect x="600" y="98" width="3" height="26" rx="1" fill="var(--accent)" fill-opacity="0.9" stroke="var(--accent)" stroke-width="0.8"/>
<rect x="622" y="98" width="3" height="26" rx="1" fill="var(--accent)" fill-opacity="0.9" stroke="var(--accent)" stroke-width="0.8"/>
<rect x="645" y="98" width="3" height="26" rx="1" fill="var(--accent)" fill-opacity="0.9" stroke="var(--accent)" stroke-width="0.8"/>
<rect x="668" y="98" width="3" height="26" rx="1" fill="var(--accent)" fill-opacity="0.9" stroke="var(--accent)" stroke-width="0.8"/>
<rect x="150" y="98" width="540" height="26" rx="3" fill="none" stroke="currentColor" stroke-opacity="0.3" stroke-width="1"/>
<text x="420" y="142" text-anchor="middle" font-size="8.5" fill-opacity="0.85">24 elevations of two hours each: 48 hours of 8,760</text>
<text x="14" y="184" font-size="10" fill-opacity="0.85">the same person does the same work. the difference is what a stolen</text>
<text x="14" y="204" font-size="10" fill-opacity="0.85">credential is worth if it is taken on an ordinary Tuesday, which is</text>
<text x="14" y="224" font-size="10" fill-opacity="0.85">about half a percent of the year rather than all of it</text>
<text x="14" y="252" font-size="9" fill-opacity="0.7">the accented marks are to scale: two hours out of a year is thinner than a line</text>
</g></svg>
<figcaption>The same administrator doing the same work, under two arrangements. Standing privilege means the account is privileged continuously, so a credential stolen on any ordinary day is immediately worth using. Just-in-time elevation grants the privilege for a stated period and removes it, so the same person doing the same twenty-four pieces of work is privileged for forty-eight hours out of eight thousand seven hundred and sixty. The accented marks are drawn to scale, which is why they are barely visible: two hours in a year is thinner than a line on this page. Nothing about the work changed, and the value of stealing that credential on a random Tuesday fell by a factor of about a hundred and eighty.</figcaption>
</figure>

**Vaulting and just-in-time are different controls** and the objective lists both,
so the distinction is worth holding.

**A vault stores the credential and releases it under control.** Somebody requests
it, the release is recorded, and the password is rotated afterwards. What it fixes
is the document with four people's shared password in it: there is now one place,
an audit trail, and a rotation. What it does not fix is that the account is
privileged all the time, so a credential obtained by any other route works.

**Just-in-time removes the privilege between uses.** The account exists, it is
ordinary, and it becomes privileged for a bounded period when somebody with
authority approves it. That is the thing the figure measures, and it addresses a
class of attack vaulting does not, because there is nothing to steal outside the
window.

**Ephemeral credentials go further**, issuing a credential valid for one session
and never again, which removes the rotation problem by removing the thing that
would be rotated.
<details class="deeper">
<summary>If you are introducing just-in-time: the approval question, and what to do about the two in the morning case</summary>

Just-in-time elevation raises one design question that decides whether it is
adopted or resented: who approves an elevation, and how long does approval take.

Three models exist and they suit different work.

**Self-service with justification.** The person elevates themselves, states a
reason, and the elevation is recorded and reviewed afterwards. It costs nothing in
delay, it is the only model that survives contact with on-call work, and its
control value is entirely in the review actually happening.

**Peer approval.** Another engineer approves. Fast enough for working hours,
provides a second pair of eyes, and degrades to self-service at three in the
morning when there is no peer awake, which has to be designed for rather than
discovered.

**Manager approval.** Slowest, strongest on paper, and the model most likely to
produce a standing exemption for the people who need to work at night, which
returns those accounts to standing privilege while the report says otherwise.

The two in the morning case is the one that decides the design. An incident is
running, something needs fixing, and any approval step that requires a second
human is a delay measured in the length of the outage. The arrangement that works
is usually self-service elevation with a short duration, unconditional alerting,
and review the next working day, on the reasoning that an incident is exactly when
you want the friction lowest and the visibility highest.

The measure worth watching afterwards is not how many elevations happened. It is
how many accounts still hold standing privilege because somebody carved out an
exception, because that number tends to grow quietly and it is the number that
determines whether the figure on this page describes your estate or your intention.

</details>

<details class="predict">
<summary>Four people share an administrative password. It is vaulted, rotated after every use, and every release is logged. Predict what is still missing.</summary>

**Attribution.** The log records that the credential was released to somebody. It
does not record who performed any particular action, because every action arrives
at the target system as the same account.

Work through an investigation. Something was changed at 02:14 on a Tuesday. The
vault says the credential was released to one of the four at 01:50. That narrows
it usefully, and it is not the same as knowing, because the release does not end
when the person stops working: anybody who obtained the credential during that
window is indistinguishable from the person who requested it, and so is anybody
with an existing session.

The vault has genuinely fixed three things. The password is no longer in a
document. It rotates, so a departing person's knowledge expires. And there is a
record where there was none. Those are real and they are why vaulting is the first
thing organisations buy.

What no amount of vaulting recovers is the property destroyed by sharing an
account in the first place. Attribution has to be built into the identity rather
than reconstructed from a release log, which means each of the four having their
own privileged account and the shared one ceasing to exist.

The order matters and it is the trap. Vaulting is easier, visible, and makes the
problem stop looking urgent, so an organisation that vaults first frequently never
reaches individual accountability. Removing the shared account first is harder and
it is the change that makes everything after it worth having.

</details>


## The account that has to exist

Every one of those arrangements depends on the system that grants privilege being
available. When it is not, somebody still has to be able to get in, and that is
the break-glass account.

**It cannot be protected by the thing it exists to survive.** An emergency account
that requires the identity provider to authenticate is useless during an identity
provider outage, which is precisely when it is needed.

What controls it instead is procedure rather than technology. The credential is
long, random, and held somewhere physical or in a vault with independent
availability. It is split between two people so that no individual can use it
alone. Its use raises an alert to people who will notice, immediately and
unconditionally. It is tested periodically, because an emergency account nobody has
ever used is an assumption rather than a control. And it is rotated after every use
and after every test.

The failure mode is not that somebody misuses it. It is that it does not work when
needed, because the password was rotated by a policy nobody exempted, or the
person holding half of it left, or nobody ever tried it.

## Prove it

**Run it.** Compute the search space for your own organisation's password policy
and for a longer, simpler alternative. Two lines of arithmetic, and the comparison
is more persuasive than any argument about character classes.

**Work it out.** Take the two tables in the capture. If your stored hashes are
fast, what is the shortest policy that still gives you a decade at that guess
rate? Then answer the same question for a slow hash and notice which change was
larger.

**Look it up.** Open SP 800-63B and find what it says about memorised secret
composition rules and about periodic change. Both recommendations are stated
plainly and both surprise people who learned the older guidance.

## What trips people up

### 1. Arguing about complexity instead of computing the space

Sixteen lowercase characters beat eight mixed ones by six and a half million
times. Both statements are about the same thing and only one of them is a number.

### 2. Quoting passphrase advice without the guess rate

Four random words is fifty one and a half bits, which is less than an
eight-character complex password. The advice was written against a slower assumed
rate and repeating it without one has made it folklore.

### 3. Treating policy as separable from storage

Changing the hashing function moved every row in the capture by seven orders of
magnitude, which is more than any composition rule available to you.

### 4. Keeping ninety-day expiry as a routine control

It assumes a compromised password is used slowly, and it is not. It also produces
patterns with counters in them, because nobody generates forty-eight unrelated
passwords over twelve years.

### 5. Reading vaulting as the same thing as just-in-time

A vault controls release of a credential for an account that is privileged all the
time. Just-in-time removes the privilege between uses, which is a different
property and the one the figure measures.

### 6. Protecting break glass with the system it exists to survive

An emergency account behind the identity provider is unavailable during an
identity provider outage, which is the scenario it was created for.

## Work it through

An estate has four shared administrative accounts, each known to between three and
six people, each password in a document. You have been asked to fix it and there
is no budget for a privileged access management product.

**The tempting move is to buy the product anyway.** It is the correct answer in
general, it does vaulting and just-in-time and session recording, and the business
case will take two quarters to write and approve, during which nothing changes.

**The move that works removes the shared accounts first**, which needs no product.
Give each of the people their own named administrative account, separate from
their ordinary one, and make the shared account's password random, unknown to
anybody, and stored in whatever secure store already exists. That converts four
credentials known to eighteen people into eighteen credentials known to one person
each, and it makes every subsequent control possible.

**Then the audit trail becomes real.** Actions performed by a named account can be
attributed, which is the thing a shared account destroys and the thing no amount
of vaulting recovers if the account is still shared at the end.

**What this rejects is sequencing the product first.** Vaulting a shared
credential is an improvement and it preserves the shared account, and an
organisation that vaults first frequently never gets to individual accountability
because the visible problem has gone away.

The residual is the elevation window. Every one of those eighteen accounts is now
privileged all the time, which is the figure's top row, and just-in-time is the
next piece of work rather than this one. Writing that down as the accepted
position, with a date, is what stops the improvement being mistaken for
completion.

## Try it

**Compute your own policy.** Take your organisation's minimum length and permitted
character set and work out the search space. Then do it for four more characters
and no complexity requirement.

**Find out what hashes your passwords.** For any system you own, find out which
function is used. If the answer is a fast general-purpose hash, that is a bigger
finding than any policy setting.

**Count your shared credentials.** List the accounts more than one person can
authenticate as. The number is usually higher than expected and every one is a
place individual accountability has failed.

**Test the break-glass account.** If one exists, try it. If nobody has ever tried
it, it is an assumption.

## Check yourself

<details class="qa">
<summary>Which is stronger, eight characters with all character classes or sixteen lowercase letters?</summary>

Sixteen lowercase, by about six and a half million times. Fifty two and a half
bits against seventy five, or roughly four days against seven thousand years at
the same guess rate.

That is the argument for length over complexity, and it is only half the picture:
the guess rate itself depends on the hashing function, and changing that moves
every answer by far more than the policy does.

</details>

<details class="qa">
<summary>Why was routine password expiry withdrawn from current guidance?</summary>

Because it assumes a compromised password will be used slowly, and it is not.
Phished credentials are used within hours and breached lists are tested in bulk
quickly, so a ninety-day limit expires a password long after it has done its
damage.

It also degrades the passwords. Somebody required to change quarterly for years
produces a pattern with a counter, which is extrapolable from any single instance.
What replaced it is change on evidence of compromise, a length minimum, and
checking against known-breached lists.

</details>

<details class="qa">
<summary>What does a password manager fix and what does it concentrate?</summary>

It fixes reuse, which composition rules never addressed and which is the dominant
cause of account compromise. Every site gets a different long random string.

It concentrates everything into one vault, which is a real trade rather than a
non-issue. It is a good trade because the distributed alternative is not forty
strong passwords but forty poorly chosen ones with repeats, and the properties
that make it hold are a slow key derivation from the master password, a provider
that cannot read the vault, and a second factor on it.

</details>

<details class="qa">
<summary>How does just-in-time elevation differ from vaulting?</summary>

A vault controls release of a credential for an account that is privileged
continuously. It fixes the shared document and the missing audit trail, and the
account remains worth attacking on any day.

Just-in-time removes the privilege between uses, so the same person doing the same
work is privileged for a small fraction of the year and there is nothing worth
stealing outside those windows. Ephemeral credentials extend that by making each
session's credential valid once.

</details>

<details class="qa">
<summary>What controls a break-glass account, and what is its real failure mode?</summary>

Procedure rather than technology, because it cannot depend on the system it exists
to survive. A long random credential held physically or in an independently
available store, split so no one person can use it alone, alerting unconditionally
on use, tested periodically, and rotated after every use and every test.

The real failure mode is not misuse. It is that it does not work when needed:
rotated by a policy nobody exempted, half of it held by somebody who left, or
never tested.

</details>

## References

- [SP 800-63B](https://csrc.nist.gov/pubs/sp/800/63/b/upd2/final) - NIST, for what current guidance says about composition rules, length and periodic change. Free. Accessed 2026-08-25.
- [RFC 9106](https://www.rfc-editor.org/rfc/rfc9106.html) - IETF, Argon2, for what a deliberately slow hash is doing and why the guess rate is a design parameter. Free. Accessed 2026-08-25.
- [SP 800-53 Rev. 5](https://csrc.nist.gov/pubs/sp/800/53/r5/upd1/final) - NIST, for privileged access as a stated control family. Free. Accessed 2026-08-25.
- [chage(1)](https://man7.org/linux/man-pages/man1/chage.1.html) - the fields that implement maximum and minimum age on a Unix system. Free. Accessed 2026-08-25.

**Where the content came from.** Both tables are computed on an AlmaLinux 10.2
container by a short program that takes the guess rate as an argument, so the two
halves of the capture differ only in that number and every other input is
identical. The rates chosen are round figures for a fast hash and a deliberately
slow one rather than measurements of specific hardware, which the output states.
There is no platform comparison on this page: password policy is a property of the
system storing the credential rather than of an operating system, and the
privileged access arrangements are products rather than platform features.

**If you also work on Linux.** The Linux+ track's
[account files and attributes](/learn/linux-plus/account-files-and-attributes)
covers the age fields this topic argues about, and
[users, root and sudo](/learn/linux-plus/users-root-and-sudo) covers the
elevation mechanism just-in-time systems wrap.
