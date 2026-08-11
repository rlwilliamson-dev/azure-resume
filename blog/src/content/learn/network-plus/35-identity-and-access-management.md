---
title: "Identity and access management"
description: "The contractor left in March and the account still works. Authentication against authorisation as two separate questions, what multifactor actually requires, the four authentication services the exam names, and why RADIUS and TACACS+ are not interchangeable."
deck: "The contractor left in March and the account still works"
track: "network-plus"
level: "working"
order: 360
objectives:
  - "Separate authentication from authorisation and say which failure is which"
  - "Say what makes a second factor a factor rather than a second password"
  - "Name the authentication services the exam lists and what distinguishes them"
  - "Explain what RADIUS conceals and what TACACS+ conceals"
  - "Apply least privilege and role-based access control to a real request"
prerequisites: ["security-vocabulary-and-the-cia-triad"]
tags: ["network-plus", "networking", "security", "identity"]
updated: 2026-08-11
draft: false
examObjectives:
  - exam: "n10-009"
    domain: "4.0"
    objective: "4.1"
sources:
  - title: "RFC 2865, Remote Authentication Dial In User Service (RADIUS)"
    url: "https://www.rfc-editor.org/rfc/rfc2865"
    publisher: "IETF"
    accessed: 2026-08-11
    tier: 1
  - title: "RFC 8907, The Terminal Access Controller Access-Control System Plus (TACACS+) Protocol"
    url: "https://www.rfc-editor.org/rfc/rfc8907"
    publisher: "IETF"
    accessed: 2026-08-11
    tier: 1
  - title: "IEEE 802.1X, Port-Based Network Access Control"
    url: "https://standards.ieee.org/ieee/802.1X/7345/"
    publisher: "IEEE Standards Association"
    accessed: 2026-08-11
    tier: 1
  - title: "NIST SP 800-63B, Digital Identity Guidelines: Authentication and Lifecycle Management"
    url: "https://csrc.nist.gov/pubs/sp/800/63/b/upd2/final"
    publisher: "NIST"
    accessed: 2026-08-11
    tier: 1
symptoms:
  - symptom: "A departed employee's account still authenticates"
    anchor: "the-account-that-outlived-the-job"
  - symptom: "A login succeeds and the action is refused"
    anchor: "two-questions-not-one"
---

> **Before you read.** A contractor finished in March. In September somebody
> notices their account still logs in, and has done all year.
>
> Nobody did anything wrong. There was a leavers process, it was followed, and
> the account was on none of the lists it needed to be on.
>
> **Where does an account like that come from, and what would have caught it?**

Access management is where security stops being technical. Every mechanism in
this topic works. What fails is the join between the mechanism and the
organisation, and that join is a process rather than a protocol.

### Some words you will need

<dl class="terms">
<dt>authentication</dt>
<dd>Establishing who somebody is.</dd>
<dt>authorisation</dt>
<dd>Deciding what they may do, once you know who they are.</dd>
<dt>factor</dt>
<dd>A category of evidence: something you know, something you have, something you are.</dd>
<dt>single sign-on</dt>
<dd>Authenticating once and being accepted by several systems on the strength of it.</dd>
<dt>least privilege</dt>
<dd>Granting the access the job needs and no more.</dd>
<dt>role-based access control</dt>
<dd>Granting access to a role and putting people in roles, rather than granting to people.</dd>
<dt>geofencing</dt>
<dd>Allowing or refusing based on where the request appears to come from.</dd>
</dl>

## What breaks without this

**Accounts outlive the people.** Every organisation has some, and they are the
most useful thing an attacker can find, because they are legitimate.

**A refused action gets investigated as a break-in.** Authentication and
authorisation fail differently, and a log that conflates them sends people
looking for the wrong thing.

**Second factors get added that are not factors.** A second thing you know is not
a second factor, and a control that feels stronger without being stronger is
worse than none, because it stops the conversation.

## Two questions, not one

The two words get used together so often that they blur, and separating them is
the most useful thing on this page.

<figure class="learn-figure">
<svg viewBox="0 0 720 244" role="img" aria-labelledby="gates-title" style="width:100%;height:auto;">
<title id="gates-title">One person passing an authentication check and being refused by a separate authorisation check</title>
<g fill="currentColor">
<text x="14" y="20" font-size="11">two questions, asked in order, by different machinery</text>
<rect x="14" y="52" width="130" height="52" rx="4" fill="currentColor" fill-opacity="0.12" stroke="currentColor" stroke-opacity="0.6"/>
<text x="79" y="74" text-anchor="middle" font-size="11">a contractor</text>
<text x="79" y="90" text-anchor="middle" font-size="10" fill-opacity="0.8">correct password</text>
<rect x="212" y="40" width="176" height="76" rx="4" fill="var(--accent)" fill-opacity="0.2" stroke="var(--accent)" stroke-width="2"/>
<text x="300" y="64" text-anchor="middle" font-size="11" fill="var(--accent)">authentication</text>
<text x="300" y="82" text-anchor="middle" font-size="10" fill="var(--accent)">who are you?</text>
<text x="300" y="102" text-anchor="middle" font-size="11" fill="var(--accent)">passed</text>
<rect x="456" y="40" width="176" height="76" rx="4" fill="var(--red)" fill-opacity="0.16" stroke="var(--red)" stroke-width="2"/>
<text x="544" y="64" text-anchor="middle" font-size="11" fill="var(--red)">authorisation</text>
<text x="544" y="82" text-anchor="middle" font-size="10" fill="var(--red)">what may you do?</text>
<text x="544" y="102" text-anchor="middle" font-size="11" fill="var(--red)">refused</text>
<g stroke="currentColor" stroke-opacity="0.6" stroke-width="1.8" fill="none">
<path d="M 144 78 H 206"/><path d="M 199 73 l 8 5 l -8 5"/>
<path d="M 388 78 H 450"/><path d="M 443 73 l 8 5 l -8 5"/>
</g>
<text x="14" y="164" font-size="10.5">the account is real, the password is right, and the answer is still no. that is not a failed login,</text>
<text x="14" y="180" font-size="10.5" fill-opacity="0.85">and a log that records it as one will send somebody looking for a compromised credential.</text>
<text x="14" y="212" font-size="10.5">the contractor who left in March fails the first gate. the one who never had access to payroll</text>
<text x="14" y="228" font-size="10.5" fill-opacity="0.85">fails the second, and the two need completely different fixes.</text>
</g></svg>
<figcaption>The contractor in this drawing has a valid account and the correct password, and is refused anyway. That is not a failed login and it should not appear in a log as one. The two gates are asked by different machinery, they fail for different reasons, and they need different fixes: the first is about whether the account should still exist, and the second is about what it should be able to reach. Conflating them is why somebody spends an afternoon hunting a compromised credential that was never compromised.</figcaption>
</figure>

**Authentication** is who are you. It is answered once, at the start, and the
answer is a claim backed by evidence.

**Authorisation** is what may you do. It is answered continuously, for every
action, and the answer can be no for somebody perfectly legitimate.

The exam adds **accounting**, which is recording what they did. The three
together are the reason the servers in the last section are called AAA servers.

## Factors, and what makes one

Multifactor authentication means evidence from more than one **category**, and
the categories are what the word factor refers to.

Something you know is a password or a PIN. Something you have is a phone, a
token, a card. Something you are is a fingerprint or a face.

**Two things from the same category are not two factors.** A password and a
security question are both things you know, and somebody who has phished one has
usually phished the other. That is not a pedantic distinction; it is the entire
content of the word.

NIST SP 800-63B is the free document here and it is unusually opinionated for a
standard. It is worth knowing about because it says things the industry took a
decade to accept, including that forcing regular password changes makes passwords
worse rather than better.

**Time-based one-time passwords** are the common second factor: a code that
changes every thirty seconds, generated from a shared seed and the clock. Worth
noticing what that depends on, because it explains the failure. Both ends need
the same time, so a device whose clock has drifted produces codes that are
correct and rejected, and topic 48 is about the protocol that stops that
happening.

## The four services, and the one distinction worth memorising

The exam names four and they are easy to confuse because they overlap.

**RADIUS** authenticates users for network access. It is what the enterprise
wireless in topic 32 talks to, and what a switch running 802.1X talks to.

**TACACS+** does the same job for administrative access to devices, and separates
authentication from authorisation properly, so it can decide per command rather
than per session.

**LDAP** is a directory protocol. It is where the accounts live, and the others
frequently consult it rather than replacing it.

**SAML** federates. It lets one organisation's identity be accepted by another's
application, which is what makes single sign-on work across companies. It is not
a login protocol in the sense the others are, and the exam's phrasing invites
that confusion.

<figure class="learn-figure">
<svg viewBox="0 0 720 236" role="img" aria-labelledby="aaa-title" style="width:100%;height:auto;">
<title id="aaa-title">A RADIUS packet with only the password field concealed, next to a TACACS plus packet with the whole body concealed</title>
<g fill="currentColor">
<text x="14" y="20" font-size="11">the same login, carried two ways, and what an observer on the wire can read</text>
<text x="14" y="40" font-size="11">RADIUS</text>
<rect x="14" y="48" width="150" height="40" rx="3" fill="currentColor" fill-opacity="0.06" stroke="currentColor" stroke-width="1" stroke-opacity="0.5"/>
<text x="89" y="72" text-anchor="middle" font-size="10" fill="currentColor" fill-opacity="0.85">username</text>
<rect x="170" y="48" width="190" height="40" rx="3" fill="currentColor" fill-opacity="0.06" stroke="currentColor" stroke-width="1" stroke-opacity="0.5"/>
<text x="265" y="72" text-anchor="middle" font-size="10" fill="currentColor" fill-opacity="0.85">the command</text>
<rect x="366" y="48" width="140" height="40" rx="3" fill="var(--accent)" fill-opacity="0.22" stroke="var(--accent)" stroke-width="1.8"/>
<text x="436" y="72" text-anchor="middle" font-size="10" fill="var(--accent)">password</text>
<text x="14" y="110" font-size="10.5" fill-opacity="0.85">an observer reads who logged in and what they did. only the password is concealed.</text>
<text x="14" y="142" font-size="11">TACACS+</text>
<rect x="14" y="150" width="486" height="40" rx="3" fill="var(--accent)" fill-opacity="0.22" stroke="var(--accent)" stroke-width="1.8"/>
<text x="257" y="174" text-anchor="middle" font-size="10" fill="var(--accent)">the whole body, concealed</text>
<text x="14" y="212" font-size="10.5" fill-opacity="0.85">an observer reads that a login happened, between which two addresses, and nothing else.</text>
</g></svg>
<figcaption>The distinction worth carrying out of this topic, because it decides which one belongs on a device somebody administers. RFC 2865 hides one attribute, the user password, and leaves the rest of the packet readable, so anybody watching the wire learns who logged in and what they typed. RFC 8907 encrypts the whole body. For network access that difference matters little, since the interesting content is a username. For administrative access it is the difference between an observer learning that somebody logged in and an observer reading every command they ran.</figcaption>
</figure>

## Least privilege, and why roles

**Least privilege** is granting what the job needs and nothing else. Everybody
agrees with it and almost nobody implements it, and the reason is that it is
easier to grant than to work out what is needed.

**Role-based access control** is the mechanism that makes it survivable. Instead
of granting access to Sam, you define a role, grant access to the role, and put
Sam in it. That sounds like an extra step and it buys three things.

Somebody joining gets a role rather than a copy of whoever sits nearest, which is
how privilege accumulates. Somebody changing jobs changes role, and the old access
goes with it rather than accreting. And the question what can this person do
becomes answerable by reading one role rather than auditing every system.

**Geofencing** is a coarser control: allowing or refusing based on where a request
appears to come from. It is genuinely useful as a signal and it is trivially
defeated by anybody who cares, so its place is raising suspicion rather than
making decisions.

## The account that outlived the job

Now the contractor.

Accounts like that come from the gap between the systems that know somebody left
and the systems that grant access. A leavers process starts in the system that
knows about employment, and a contractor is frequently not in that system: they
are in a purchase order, or in somebody's calendar, or in an email thread.

**So the account was never on the list because the person was never on the list.**
The process worked correctly on the population it knew about.

Three things catch this, and only one of them is technical.

**Accounts that expire by default.** A contractor account created with an end date
closes itself, and renewing it is a deliberate act by somebody who currently wants
it open. This is the single most effective control here and it costs nothing.

**Access review.** Somebody who knows the team reads the list of who has access
and says which names they do not recognise. It is dull, it is periodic, and it is
the only thing that catches accounts nobody has a record of.

**Joining the sources.** If accounts can only be created from a system of record
that includes contractors, the gap closes at the origin. That is a bigger change
and it is the one that actually fixes it.

<details class="deeper">
<summary>If you already work on networks: why single sign-on makes this better and worse at the same time</summary>

Single sign-on is usually sold on convenience, and its real value is the one in
this topic: it collapses many accounts into one, so disabling that one disables
access to everything joined to it.

An organisation with forty separate systems has forty leavers problems. One with
single sign-on has one. That is a genuine and large improvement in exactly the
failure this page is about.

The cost is that it collapses the blast radius the same way. One credential now
opens forty systems, which raises the value of stealing it by a factor of forty,
and this is precisely why the second factor moves from a nice idea to a
requirement. An organisation that deploys single sign-on without multifactor has
concentrated its risk and not defended it.

Two more consequences that turn up in practice.

Something has to remain that is not behind the single sign-on, because when the
identity provider is unreachable, somebody has to be able to fix it. That account
is by definition outside the mechanism protecting everything else, and it needs
its own protection and its own audit. Organisations either forget it exists or
protect it properly, and the second is rare.

And a joined system does not necessarily stop trusting an existing session when
the account is disabled. Disabling somebody centrally stops new logins
immediately, and an application holding a session token may keep working until it
expires. The gap is usually minutes and occasionally hours, and it is worth
knowing before somebody assumes the disable was instantaneous.

</details>

## Prove it

There is no capture on this page and the reason is worth being straight about.
Demonstrating the RADIUS and TACACS+ difference properly needs a working server of
each and a capture between them, which is a day of setup for a picture the RFCs
state in one sentence. The other content is process, and a transcript cannot show
a process.

**RFC 2865, section 5.2.** Free. Read the description of how the user password
attribute is hidden and answer one question: does the mechanism protect any other
attribute in the packet? That is the whole of the figure above, from the source.

**RFC 8907.** Read the introduction and answer the matching question: what portion
of the packet does it obfuscate? The two answers next to each other are the
distinction the exam wants.

**NIST SP 800-63B.** Read what it says about password expiry. It is short and it
contradicts a policy your organisation probably still has, which makes it worth
reading before the next time somebody defends that policy in a meeting.

**Then ask for a list.** Whoever administers accounts where you work can produce a
list of accounts that have not logged in for ninety days. It takes them a minute
and it is the most interesting document in the building.

## What trips people up

### 1. Treating a refused action as a failed login

Authentication succeeded. Authorisation refused. Those are different failures with
different fixes, and a log that records the second as the first sends somebody
hunting a compromise that did not happen.

### 2. Counting two things you know as two factors

A password and a security question are the same category. Multifactor means
evidence from different categories, and anyone who phished one has usually
phished the other.

### 3. Assuming RADIUS protects the session

It conceals the password attribute and nothing else. On the wire, the username and
the rest of the exchange are readable, which is why it is the wrong choice for
administrative access to devices.

### 4. Calling SAML a login protocol

It federates identity so one organisation's users are accepted by another's
application. It is not doing the same job as RADIUS or LDAP, and the exam's list
invites the confusion.

### 5. Granting access to people instead of roles

It works until somebody changes jobs, and then the old access stays because
nobody remembers it was granted. Roles make the question what can this person do
answerable.

### 6. Relying on geofencing as a control

It is a useful signal and it is defeated by anybody who cares. Use it to raise
suspicion, not to make a decision.

## Work it through

The contractor's account, and what to do in what order.

Start by establishing what it is rather than who it belongs to. Is it an interactive
account somebody logs into, a service account something else uses, or a shared
account with the credentials in a document. The three need different handling and
the third is the one that becomes an argument.

Then find out what it can reach, which is a harder question than it should be if
access was granted per person. That difficulty is itself the finding, and it is the
argument for roles that the section above makes.

Then check whether it has been used since March. If it has not, disable it and move
on. If it has, that is an incident rather than a housekeeping task, and the next
question is from where and to do what, which is the accounting half of AAA earning
its place.

Then fix the class rather than the instance, because there will be others. Ask how
the account was created, and whether the source it came from is one the leavers
process reads. For contractors the answer is usually no, and that gap is the actual
defect.

And put an expiry on it if it has to stay. An account that closes itself unless
somebody deliberately renews it converts this from a thing you have to remember into
a thing that happens by default, which is the only version that survives a busy
year.

## Try it

**Ask for the stale account list.** Ninety days without a login. Every
organisation can produce it and almost none look at it.

**Check whether your own second factor is a second category.** If both things are
things you know, it is one factor wearing two hats.

**Read section 5.2 of RFC 2865.** Two minutes, and it settles the RADIUS question
permanently.

## Check yourself

<details class="qa">
<summary>Somebody logs in successfully and is refused when they try to do something. Which control refused them, and is it a security incident?</summary>

Authorisation refused, and no.

Authentication answered who are you and got a good answer: real account, correct
credential. Authorisation answered what may you do and said no, which is the
correct outcome for somebody legitimate who should not have that access.

It only becomes interesting if the person should have had it, which is a
provisioning problem, or if they are attempting things repeatedly, which is worth
looking at. A log that records this as a failed login sends somebody hunting a
compromised credential that does not exist.

</details>

<details class="qa">
<summary>Is a password plus a security question multifactor?</summary>

No. Both are things you know, so it is one category twice.

The word factor refers to the category: something you know, something you have,
something you are. The value of a second factor comes from it failing differently
from the first, and two things you know fail the same way. Somebody who phished a
password has usually phished the answer to the question on the same page.

</details>

<details class="qa">
<summary>Why is TACACS+ the better choice for administrative access to network devices?</summary>

Because of what each protocol conceals.

RADIUS hides the user password attribute and leaves the rest of the packet
readable, so an observer on the wire learns the username and the content of the
exchange. TACACS+ encrypts the whole body, so an observer learns that a login
happened and between which addresses.

For network access, where the readable content is mostly a username, that matters
little. For somebody administering a device, the readable content is the commands
they ran, which is a considerable difference. TACACS+ also separates
authentication from authorisation properly, so it can decide per command.

</details>

<details class="qa">
<summary>How does an account for somebody who left in March survive a leavers process that was followed correctly?</summary>

Because the person was not in the system the process reads.

A leavers process usually starts from employment records, and contractors
frequently are not in them. They exist in a purchase order or an email thread, so
they never appear on the list and the process runs correctly over a population
that does not include them.

The cheap fix is an expiry date on the account, so it closes unless somebody
renews it deliberately. The real fix is creating accounts only from a source of
record that includes contractors.

</details>

<details class="qa">
<summary>Single sign-on makes the leavers problem better. What does it make worse?</summary>

The value of one stolen credential.

Forty separate systems is forty leavers problems, and single sign-on collapses
that to one, which is a genuine improvement in exactly this failure. It collapses
the blast radius identically: one credential now opens forty systems.

Which is why multifactor stops being optional alongside it. It also leaves at
least one account outside the mechanism, because somebody has to be able to fix
the identity provider when it is unreachable, and that account needs its own
protection.

</details>

## References

- [RFC 2865](https://www.rfc-editor.org/rfc/rfc2865) - IETF, RADIUS, whose section 5.2 describes hiding the user password attribute and no other. Free. Accessed 2026-08-11.
- [RFC 8907](https://www.rfc-editor.org/rfc/rfc8907) - IETF, TACACS+, which obfuscates the whole body. Free. Accessed 2026-08-11.
- [IEEE 802.1X](https://standards.ieee.org/ieee/802.1X/7345/) - IEEE Standards Association, the port-based access control these servers sit behind. Scope readable without purchase. Accessed 2026-08-11.
- [NIST SP 800-63B](https://csrc.nist.gov/pubs/sp/800/63/b/upd2/final) - NIST, digital identity guidelines, including what it says about password expiry. Free. Accessed 2026-08-11.

**Where the numbers came from.** Nothing on this page is captured. The RADIUS and
TACACS+ difference is stated by RFC 2865 and RFC 8907 respectively, and
demonstrating it properly would need a working server of each, which is a day of
setup for a picture the documents give in a sentence. The ninety day figure in the
stale account exercise is a common review interval rather than a standard. The
thirty second interval for time-based codes is the usual configuration and not a
requirement.

**If you also work on Linux.** [Central identity](/learn/linux-plus/central-identity)
covers joining a machine to a directory, and [authentication and
PAM](/learn/linux-plus/authentication-and-pam) covers the stack that decides
whether a login succeeds. Both are the implementation underneath this page's
vocabulary.
