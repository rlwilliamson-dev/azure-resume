---
title: "What security actually protects"
description: "Why three incidents that look nothing alike are all security incidents, what the triad is for once you stop treating it as a slogan, why authentication and authorization are different questions with different answers, and what a gap analysis is."
deck: "Three things went wrong and only one of them looks like a break-in"
track: "security-plus"
level: "intro"
order: 20
objectives:
  - "Name the three properties of the triad and say how each one fails on its own"
  - "Say what a control buys, in terms of which property it covers"
  - "Tell authentication from authorization, and say why they disagree"
  - "Explain what accounting is for, given that it prevents nothing"
  - "Say what non-repudiation adds that integrity does not"
  - "Describe what a gap analysis compares"
prerequisites: []
tags: ["security-plus", "security", "fundamentals"]
updated: 2026-08-25
draft: false
examObjectives:
  - exam: "sy0-701"
    domain: "1.0"
    objective: "1.2"
sources:
  - title: "RFC 4949, Internet Security Glossary, Version 2"
    url: "https://www.rfc-editor.org/rfc/rfc4949.html"
    publisher: "IETF"
    accessed: 2026-08-25
    tier: 1
  - title: "NIST SP 800-12 Rev. 1, An Introduction to Information Security"
    url: "https://csrc.nist.gov/pubs/sp/800/12/r1/final"
    publisher: "NIST"
    accessed: 2026-08-25
    tier: 1
  - title: "NIST SP 800-53 Rev. 5, Security and Privacy Controls for Information Systems and Organizations"
    url: "https://csrc.nist.gov/pubs/sp/800/53/r5/upd1/final"
    publisher: "NIST"
    accessed: 2026-08-25
    tier: 1
  - title: "FIPS 199, Standards for Security Categorization of Federal Information and Information Systems"
    url: "https://csrc.nist.gov/pubs/fips/199/final"
    publisher: "NIST"
    accessed: 2026-08-25
    tier: 1
symptoms:
  - symptom: "A user logs in successfully and is then refused"
    anchor: "two-questions-that-are-allowed-to-disagree"
---

> **Before you read.** Three things went wrong last week. A laptop was stolen from
> a car. An invoice was altered by one digit before it was paid. The payroll
> system was unavailable for a day.
>
> One of those looks like a security incident and the other two look like bad
> luck and an outage.
>
> **All three are security incidents. What do they have in common?**

They have in common that somebody's data stopped doing what it was supposed to
do. That is what this exam is about, and the first useful thing to learn is that
it fails in three separate directions rather than one.

### Some words you will need

<dl class="terms">
<dt>confidentiality</dt>
<dd>Only the people who should see it can see it.</dd>
<dt>integrity</dt>
<dd>It says what it said when it was written, and you can tell if it does not.</dd>
<dt>availability</dt>
<dd>The people who need it can get it, at the moment they need it.</dd>
<dt>non-repudiation</dt>
<dd>The person who did it cannot credibly claim somebody else did.</dd>
<dt>authentication</dt>
<dd>Establishing who somebody is.</dd>
<dt>authorization</dt>
<dd>Deciding what that person is allowed to do. A separate question with its own answer.</dd>
<dt>accounting</dt>
<dd>Recording what happened, including the things that were refused.</dd>
<dt>gap analysis</dt>
<dd>Comparing where you actually are against where you are supposed to be, and writing down the difference.</dd>
</dl>

## What breaks without this

**You buy a control and cannot say what it bought you.** Encryption gets funded,
deployed and reported as a security improvement without anybody naming which of
the three properties it protects and which two it does not.

**An outage is treated as somebody else's problem.** If availability is not a
security property in your head, then the team that ransomwares your file server
has committed an availability attack you were not defending against.

**A login that works is mistaken for permission.** Systems get built where being
known is the same as being allowed, which works until the first person who is
known and should not be allowed.

**Nobody can say what happened.** Without accounting, an incident is reconstructed
from memory and guesswork, and the most important question, whether the attacker
succeeded, has no answer.

## Three properties, and they fail one at a time

Take the three incidents from the top of the page.

The stolen laptop is a **confidentiality** failure. The data is intact and it is
available on the backup. What changed is that somebody who should not have it,
has it.

The altered invoice is an **integrity** failure. Nothing was disclosed and nothing
went down. What changed is that the file no longer says what it said, and, worse,
nobody could tell.

The day of downtime is an **availability** failure. Nothing was read and nothing
was changed. The data was perfectly safe and completely useless.

Here are all three, against the same file.

<details class="predict">
<summary>One file, three failures. Which of them do you expect to leave visible evidence?</summary>

```bash
# AlmaLinux 10.2, x86_64
$ cp /srv/finance/payroll.csv /root/as-issued.csv
echo '1. confidentiality. one permission bit, and alice can read it:'
chmod 664 /srv/finance/payroll.csv
su - alice -c 'head -2 /srv/finance/payroll.csv'
chmod 660 /srv/finance/payroll.csv
echo
echo '2. integrity. bob may write to it, so bob can change what it says:'
su - bob -c 'sed s/44500/54500/ /srv/finance/payroll.csv > /tmp/edit; cat /tmp/edit > /srv/finance/payroll.csv'
diff /root/as-issued.csv /srv/finance/payroll.csv
echo
echo '3. availability. the file is unchanged and secret and nobody can have it:'
chmod 000 /srv/finance
su - bob -c 'head -1 /srv/finance/payroll.csv'
1. confidentiality. one permission bit, and alice can read it:
staff,salary
alice,41000

2. integrity. bob may write to it, so bob can change what it says:
3c3
< bob,44500
---
> bob,54500

3. availability. the file is unchanged and secret and nobody can have it:
head: cannot open '/srv/finance/payroll.csv' for reading: Permission denied
```

</details>

Read what each command actually did. **One permission bit** and alice, who is not
in the finance group, reads the payroll file. **One write** by bob, who is
entitled to write to it, and his own salary is ten thousand higher; the `diff` is
the only reason anybody knows. And **one directory permission** and the file is
untouched, unread and unreachable.

Three properties, three separate failures, no overlap between them.

<figure class="learn-figure">
<svg viewBox="0 0 720 300" role="img" aria-labelledby="triad-title" style="width:100%;height:auto;">
<title id="triad-title">Three incidents against the three properties of the triad, each breaking exactly one, with a column showing that full-disk encryption helps with only the first</title>
<g fill="currentColor">
<text x="14" y="20" font-size="11">three incidents, three properties, and one control that covers one of them</text>
<text x="350" y="48" text-anchor="middle" font-size="9.5" fill-opacity="0.85">confidentiality</text>
<text x="470" y="48" text-anchor="middle" font-size="9.5" fill-opacity="0.85">integrity</text>
<text x="590" y="48" text-anchor="middle" font-size="9.5" fill-opacity="0.85">availability</text>
<text x="662" y="48" text-anchor="middle" font-size="9.5" fill-opacity="0.85">encryption</text>
<text x="14" y="77" font-size="9.5">a laptop is stolen from a car</text>
<rect x="300" y="62" width="100" height="22" rx="3" fill="var(--red)" fill-opacity="0.3" stroke="var(--red)" stroke-width="1.5"/>
<text x="350" y="77" text-anchor="middle" font-size="9.5">broken</text>
<rect x="420" y="62" width="100" height="22" rx="3" fill="none" stroke="currentColor" stroke-opacity="0.4" stroke-width="1.1" stroke-dasharray="3 3"/>
<rect x="540" y="62" width="100" height="22" rx="3" fill="none" stroke="currentColor" stroke-opacity="0.4" stroke-width="1.1" stroke-dasharray="3 3"/>
<rect x="618" y="62" width="88" height="22" rx="3" fill="var(--accent)" fill-opacity="0.3" stroke="var(--accent)" stroke-opacity="0.8" stroke-width="1.4"/>
<text x="662" y="77" text-anchor="middle" font-size="9.5">yes</text>
<text x="14" y="131" font-size="9.5">an invoice is altered by one digit</text>
<rect x="300" y="116" width="100" height="22" rx="3" fill="none" stroke="currentColor" stroke-opacity="0.4" stroke-width="1.1" stroke-dasharray="3 3"/>
<rect x="420" y="116" width="100" height="22" rx="3" fill="var(--red)" fill-opacity="0.3" stroke="var(--red)" stroke-width="1.5"/>
<text x="470" y="131" text-anchor="middle" font-size="9.5">broken</text>
<rect x="540" y="116" width="100" height="22" rx="3" fill="none" stroke="currentColor" stroke-opacity="0.4" stroke-width="1.1" stroke-dasharray="3 3"/>
<rect x="618" y="116" width="88" height="22" rx="3" fill="currentColor" fill-opacity="0.06" stroke="currentColor" stroke-opacity="0.8" stroke-width="1.4"/>
<text x="662" y="131" text-anchor="middle" font-size="9.5">no</text>
<text x="14" y="185" font-size="9.5">payroll is down for a day</text>
<rect x="300" y="170" width="100" height="22" rx="3" fill="none" stroke="currentColor" stroke-opacity="0.4" stroke-width="1.1" stroke-dasharray="3 3"/>
<rect x="420" y="170" width="100" height="22" rx="3" fill="none" stroke="currentColor" stroke-opacity="0.4" stroke-width="1.1" stroke-dasharray="3 3"/>
<rect x="540" y="170" width="100" height="22" rx="3" fill="var(--red)" fill-opacity="0.3" stroke="var(--red)" stroke-width="1.5"/>
<text x="590" y="185" text-anchor="middle" font-size="9.5">broken</text>
<rect x="618" y="170" width="88" height="22" rx="3" fill="currentColor" fill-opacity="0.06" stroke="currentColor" stroke-opacity="0.8" stroke-width="1.4"/>
<text x="662" y="185" text-anchor="middle" font-size="9.5">no</text>
<text x="14" y="244" font-size="10" fill-opacity="0.85">the properties are independent, so a control is bought for one of them at a time</text>
<text x="14" y="266" font-size="10" fill-opacity="0.85">encryption is the one people name first and it answers a third of the question</text>
<text x="14" y="288" font-size="10" fill-opacity="0.85">on the third row it makes the recovery harder rather than easier</text>
</g></svg>
<figcaption>The triad is not three words for secure. It is three properties that fail separately, and the last column is the reason that matters. Full-disk encryption is the control almost everybody names first, and it answers the stolen laptop completely: the thief has the disk and not the key. It does nothing at all about the altered invoice, because whoever changed it was authorised to open the file and the encryption obligingly decrypted it for them. And on the outage it is worse than neutral, because a volume that will not unlock is one more thing standing between you and a running payroll system. Choosing a control means naming which of the three columns you are buying, and noticing which two you are not.</figcaption>
</figure>

**The last column of that figure is the point of the whole topic.** Encryption is
the control people name first, and it answers the first row completely and the
other two not at all. On the middle row the attacker was authorised, so the
system decrypted the file for them on request. On the last row it is worse than
useless: a volume that will not unlock is one more thing between you and a working
payroll run.

<details class="deeper">
<summary>If you have argued about this in a meeting: where the triad runs out, and what people add to it</summary>

The triad is a checklist rather than a theory, and it is worth knowing where its
edges are, because you will meet people who have added to it.

The most common addition is non-repudiation, which is below and is genuinely not
covered by the three. Some frameworks add authenticity, distinguishing "this
message was not altered" from "this message is from who it claims". Others add
utility and possession, giving six, on the argument that data you hold in a
format nothing can read has failed in a way none of the three describes.

None of that is on this exam and it is worth knowing anyway, for a specific
reason: the triad's value is as a prompt, not as a taxonomy. Its job is to stop
you buying a confidentiality control and reporting it as security. It does that
well. If you find yourself arguing about whether a particular failure is really
integrity or really availability, the framework has stopped helping and the
argument is about words.

The place it genuinely misleads is where the three conflict, which they do
constantly. Every availability measure copies data and every copy is another
place confidentiality can fail. Every integrity control refuses something and
every refusal is a small availability cost. Treating the three as goals to
maximise gets you a system that does none of them, and the actual job is
choosing the trade for this data, which is what classification is for and is
covered later in the track.

</details>

## Two questions that are allowed to disagree

Authentication and authorization get said in one breath and abbreviated to the
same three letters, and they are separate questions asked in order.

<details class="predict">
<summary>Alice logs in successfully. What do you expect to happen when she opens the payroll file?</summary>

```bash
# AlmaLinux 10.2, x86_64
$ echo "who alice is, once she has authenticated:"
su - alice -c "id"
echo
echo "and what happens when she asks for the payroll file:"
su - alice -c "cat /srv/finance/payroll.csv"
echo
echo "the same question, asked by bob:"
su - bob -c "head -2 /srv/finance/payroll.csv"
who alice is, once she has authenticated:
uid=1000(alice) gid=1001(alice) groups=1001(alice)

and what happens when she asks for the payroll file:
cat: /srv/finance/payroll.csv: Permission denied

the same question, asked by bob:
staff,salary
alice,41000
```

</details>

Alice authenticated. `id` proves it: the machine knows exactly who she is, uid
1000, and it says so. Then she asked for the payroll file and was refused.

**Nothing went wrong there.** That is the system working. Being known and being
allowed are different, and a design that cannot express "I know exactly who you
are and you may not have this" is a design that has collapsed two questions into
one.

Bob is the control. He authenticates no better than alice does. He gets the file,
because the difference between them has nothing to do with how well either of
them proved who they were.

There is a detail in that capture worth pausing on. Alice cannot read her own
salary and bob can. Authorization attaches to the resource and the role, not to
whose data it happens to be, and if you want the other behaviour you have to
build it deliberately.

<figure class="learn-figure">
<svg viewBox="0 0 720 292" role="img" aria-labelledby="aaa-title" style="width:100%;height:auto;">
<title id="aaa-title">One request from one user passing through three separate questions, answered yes for authentication, no for authorization, and recorded either way by accounting</title>
<g fill="currentColor">
<text x="14" y="20" font-size="11">one person, one request, and three questions with three separate answers</text>
<rect x="14" y="40" width="120" height="30" rx="4" fill="none" stroke="currentColor" stroke-opacity="0.7" stroke-width="1.4"/>
<text x="74" y="59" text-anchor="middle" font-size="10">alice asks</text>
<path d="M 142 55 H 190" stroke="currentColor" stroke-opacity="0.75" stroke-width="1.5"/>
<path d="M 182 50 L 192 55 L 182 60" fill="none" stroke="currentColor" stroke-opacity="0.75" stroke-width="1.5"/>
<rect x="198" y="40" width="150" height="30" rx="4" fill="var(--accent)" fill-opacity="0.16" stroke="var(--accent)" stroke-width="1.6"/>
<text x="273" y="59" text-anchor="middle" font-size="10">are you who you say</text>
<text x="198" y="88" font-size="9.5" fill-opacity="0.85">yes, uid 1000, alice</text>
<path d="M 356 55 H 404" stroke="currentColor" stroke-opacity="0.75" stroke-width="1.5"/>
<path d="M 396 50 L 406 55 L 396 60" fill="none" stroke="currentColor" stroke-opacity="0.75" stroke-width="1.5"/>
<rect x="412" y="40" width="150" height="30" rx="4" fill="var(--red)" fill-opacity="0.22" stroke="var(--red)" stroke-width="1.6"/>
<text x="487" y="59" text-anchor="middle" font-size="10">may you have this</text>
<text x="412" y="88" font-size="9.5" fill="var(--red)" fill-opacity="0.95">no, permission denied</text>
<path d="M 487 116 V 100" stroke="currentColor" stroke-opacity="0.6" stroke-width="1.4" stroke-dasharray="4 3"/>
<path d="M 273 116 V 100" stroke="currentColor" stroke-opacity="0.6" stroke-width="1.4" stroke-dasharray="4 3"/>
<rect x="198" y="118" width="364" height="30" rx="4" fill="currentColor" fill-opacity="0.08" stroke="currentColor" stroke-opacity="0.7" stroke-width="1.4"/>
<text x="380" y="137" text-anchor="middle" font-size="10">write down that both of those happened</text>
<text x="14" y="182" font-size="10" fill-opacity="0.85">the first two answers disagree, which is the normal case rather than a fault</text>
<text x="14" y="204" font-size="10" fill-opacity="0.85">a system that treats them as one question cannot express "known, and not allowed"</text>
<text x="14" y="226" font-size="10" fill-opacity="0.85">the third is the one that gets switched off for disk space and missed afterwards</text>
<text x="14" y="248" font-size="10" fill-opacity="0.85">a denial is worth recording precisely because nothing went wrong</text>
<text x="14" y="270" font-size="10" fill-opacity="0.85">bob asks the same question and gets a different answer to the second one only</text>
</g></svg>
<figcaption>The three words get run together as one idea and they are three questions asked in order, with answers that need not agree. Alice authenticates perfectly and is refused, which is the capture above and is not a malfunction: identity established, access declined. Bob authenticates no better and is allowed, because the difference between them has nothing to do with who they are and everything to do with what the file is. Accounting is the one that gets dropped when a disk fills up, and it is the only one of the three that is any use after the event, because a denial nobody recorded is indistinguishable from a request nobody made.</figcaption>
</figure>

The third question is **accounting**: writing down that both of those happened. It
prevents nothing, which is why it is the one switched off when a disk fills up,
and it is the only one of the three that is any use the day after an incident. A
refusal nobody recorded is indistinguishable from a request nobody made.

<details class="deeper">
<summary>If you already build access control: authenticating systems, which is the half people skip</summary>

Everything above is about authenticating people, and a large share of the
authentication happening on any network is machines proving identity to each
other with no human involved.

Your web server proves who it is to a browser with a certificate. A monitoring
agent proves who it is to its collector with a key. A machine joining a network
proves who it is before it gets an address. In each case the credential is not a
password, because nobody is present to type one, and the whole design problem
moves from "how do we check a human" to "where does the machine keep its secret
and what happens when it is copied".

That is a genuinely different problem and the exam names it separately for that
reason. It is also where most of the interesting failures are: a human credential
gets rotated when somebody leaves, and a machine credential sits in a
configuration file being copied into every clone of that server for four years.

The rule worth carrying is that any statement about authentication should say
which kind it is. "We require multifactor authentication" is a statement about
people and says nothing about the twelve service accounts with static keys.

Authorization models are the other half of that sentence and they have the same
problem. A model that describes what a person in a role may do frequently has
nothing to say about what a service account may do, and the service account
usually ends up with more. Topic 55 takes the six models the exam names one at a
time; the thing to notice now is that choosing one is a decision somebody makes
rather than a property of the system.

</details>

## What a signature adds

Integrity says the invoice was altered. It does not say who altered it, and for
the invoice that is the question that matters.

**Non-repudiation** is the property that the person who did something cannot
credibly deny it. It needs a credential that exactly one party holds, because a
secret two parties share proves only that one of them did it, and neither can
demonstrate which to anybody else.

That is the whole distinction, and it is a favourite of exam writers: a shared
secret gives you integrity and authenticity between two parties who already trust
each other. A signature made with a private key adds the ability to prove it to a
third party who trusts neither of you.

The mechanics are topic 07's, and what to carry from here is the shape of the
question. If the answer has to convince somebody who was not in the room, a shared
secret is not enough.

## Gap analysis, which is where the work starts

The last term in this topic is the least glamorous and it is the one that decides
what you do on Monday.

A gap analysis compares two things: what is supposed to be true, and what is
actually true. The first comes from a standard, a policy, a benchmark or a
contract. The second comes from looking. The output is a list of differences, and
each difference is either work or an accepted risk.

It sounds like paperwork and it is the step that everything else in this track
depends on, because **every control decision later in the exam assumes somebody
has established what is currently the case.** Choosing a treatment for a risk you
have not measured is guessing with more vocabulary.

Two failure modes worth naming now, because both recur. A gap analysis against no
named standard produces a list of things somebody dislikes. And one that never
produces a decision produces a document, which is worse than nothing, because it
records that you knew.

<details class="deeper">
<summary>If you have run one: what you measure against, and why the answer changes the result</summary>

The half nobody argues about is the looking. The half that decides the outcome is
what you chose to compare against, and there are three kinds of answer with very
different properties.

A **benchmark** is a published list of settings with expected values, and it is
the easiest to run because a tool can do it. Its weakness is that it was written
for a machine, not for yours, and a large share of what it flags is inapplicable
to the way you actually run things. A benchmark score treated as a grade produces
a lot of work that buys nothing.

A **control framework** is a list of outcomes rather than settings: this data is
protected in transit, access is reviewed periodically. It travels much better
between organisations and it cannot be run by a tool, because deciding whether an
outcome has been achieved is a judgement.

A **policy of your own** is the one that should sit above both and usually does
not exist in a form anybody can measure. It is also the only one that can say
what this organisation has decided to care about.

The practical shape that works is to measure against the framework, use the
benchmark as the instrument for the parts a tool can see, and treat a gap against
your own policy as the most serious of the three, because that one you wrote
down and agreed to.

The trap in all of it is scope. A gap analysis over a scope somebody chose to
make the result look good is not wrong in any individual line and is useless, and
the question to ask of any clean report is what it covered rather than what it
found.

</details>

## Prove it

**Run it.** On any machine you control, create a file, deny yourself access to it,
and read the error. Then get access back. That is thirty seconds of work and it is
the difference between knowing that permissions exist and having watched one stop
you.

**Work it out.** Take the three incidents from the top of this page and, for each
one, name a control that would have prevented it. Then check each control against
the other two incidents and write down whether it helps, does nothing, or makes
things worse. You should find that no single entry on your list covers more than
one row, which is the argument the figure makes.

**Look it up.** FIPS 199 categorises information systems by the impact of a
failure, and it does it separately for confidentiality, integrity and
availability. Read the three definitions of a potential impact and answer one
question: can the same system be high for one property and low for another, and
what does the standard say you do with the three ratings? The answer is why the
triad has three columns rather than one score.

## What trips people up

### 1. Treating the triad as one idea called security

It is three properties that fail independently and trade against each other. A
control is bought for one of them, and the useful habit is naming which.

### 2. Leaving availability out

An outage is a security incident when somebody caused it, and ransomware is an
availability attack before it is anything else. A team that does not count
availability is not defending against the most common serious incident there is.

### 3. Reading a successful login as permission

Authentication answers who. Authorization answers whether. They are allowed to
disagree, and a system that cannot say "known and refused" has merged two
questions that need separate answers.

### 4. Expecting authorization to follow ownership

Alice cannot read her own salary in the capture above. Access attaches to the
resource and the role, and any other behaviour is something you build on purpose.

### 5. Switching off accounting because it prevents nothing

That is true and it is the wrong test. It is the only one of the three that is
worth anything after the event, and the records you want are the ones nobody
thought to keep.

### 6. Confusing integrity with non-repudiation

Integrity says the file changed. Non-repudiation says who changed it, and cannot
be provided by a secret more than one party holds.

## Work it through

Somebody proposes encrypting the payroll file, and asks you to approve it.

**First, ask which of the three it is for.** If the answer is the stolen laptop,
it is a good control and it works. If the answer is "security", the conversation
has not started yet.

**Then check it against the other two.** Bob altering his own salary is not
prevented by encryption, because bob is authorised and the system will decrypt the
file for him. The day of downtime is not prevented either, and if the key handling
is poor, encryption has added a new way for payroll to be unavailable.

**Then ask what would cover the middle row.** Something that makes a change
visible: a record of who wrote to the file and when, a comparison against an
issued copy, an approval step before a payroll run. All three are integrity
controls and none of them is encryption.

**Then ask who has to be convinced.** If the answer is "us, internally", a record
of the change is enough. If the answer is a court or an auditor, you need a
credential only one person holds, and that is a different piece of work.

The decision, written the way it should be written down: approve the encryption
for the laptop case, name that it covers confidentiality only, and open a separate
piece of work on write logging for the integrity case. The rejected option is
treating the encryption as closing the payroll risk, and the cost of that rejection
is that somebody has to be told the project is not finished.

## Try it

**Look at how your own machine answers the two questions.** Log in, then try to
open something you know you are not allowed to. Notice that the machine never
doubted who you were.

**Find something on your own system that fails only one of the three.** A file
with permissions too wide is confidentiality. A backup that has never been
restored is availability. A shared account is all three at once and also removes
non-repudiation, which is why they are worth arguing about.

**Do a gap analysis on one thing.** Pick one sentence from any policy you are
subject to, at work or from a service you use. Check whether it is actually true.
One sentence, ten minutes, and it is the whole method at small scale.

## Check yourself

<details class="qa">
<summary>A laptop is stolen, an invoice is altered by one digit, and payroll is down for a day. What makes all three security incidents?</summary>

Each one breaks a different property of the triad. The theft is confidentiality,
the altered invoice is integrity, and the outage is availability.

The reason it is worth naming which is that controls are bought one property at a
time. Full-disk encryption answers the theft completely, does nothing about the
altered invoice because whoever changed it was authorised, and on the outage it
adds one more thing that can prevent payroll running.

</details>

<details class="qa">
<summary>Alice authenticates successfully and is then refused a file. Has something gone wrong?</summary>

No. Those are two different questions and they are allowed to disagree.
Authentication established that she is alice, which the system is certain about.
Authorization decided she may not read that file.

A design that cannot express "known and not allowed" has collapsed the two
questions into one, and it works right up until the first person who is legitimate
and should not have access to something.

</details>

<details class="qa">
<summary>Accounting prevents no attack. Why keep it?</summary>

Because it is the only one of the three A's worth anything after the event.
Prevention that worked leaves nothing behind, and an incident reconstructed
without records is reconstructed from memory.

The records that matter most are usually the refusals. A denial nobody wrote down
is indistinguishable from a request nobody made, so the difference between an
attacker who tried and failed and an attacker who never came is a log entry.

</details>

<details class="qa">
<summary>Two systems share a secret key and use it to authenticate messages between them. What can they prove, and to whom?</summary>

They can prove to each other that a message was not altered and came from a holder
of the key. They cannot prove to anybody else which of them sent it, because both
hold the same secret and either could have produced the tag.

That is the gap non-repudiation fills, and it needs a credential exactly one party
holds. If the answer has to convince a third party who trusts neither of them, a
shared secret is not enough.

</details>

<details class="qa">
<summary>What does a gap analysis compare, and what makes one useless?</summary>

What is supposed to be true against what is actually true, with the first coming
from a named standard, policy, benchmark or contract, and the second from
looking.

Two things make one useless. Without a named standard the output is a list of
things somebody dislikes rather than a list of gaps. And one that produces no
decision produces a document, which is worse than not doing it, because it records
that you knew.

</details>

## References

- [RFC 4949](https://www.rfc-editor.org/rfc/rfc4949.html) - IETF, the Internet Security Glossary, which defines every term in this topic and is the reference for arguing about what one means. Free. Accessed 2026-08-25.
- [NIST SP 800-12 Rev. 1](https://csrc.nist.gov/pubs/sp/800/12/r1/final) - NIST, an introduction to information security, and the plainest statement of the triad and of why controls are chosen per property. Free. Accessed 2026-08-25.
- [NIST SP 800-53 Rev. 5](https://csrc.nist.gov/pubs/sp/800/53/r5/upd1/final) - NIST, the control catalogue the next topic's categories map onto. Free. Accessed 2026-08-25.
- [FIPS 199](https://csrc.nist.gov/pubs/fips/199/final) - NIST, which rates a system separately for each of the three properties and is the source for the Prove it question. Free. Accessed 2026-08-25.

**Where the output came from.** Both blocks are captured, on AlmaLinux 10.2
x86_64 pinned by digest, using two ordinary accounts and one file. Nothing on the
page is a lab of any size, deliberately: everything shown here is available on any
machine a reader already has, which is the point of putting it first.

**If you also work on Linux.** The Linux+ track's
[reading and setting permissions](/learn/linux-plus/reading-and-setting-permissions)
topic covers the mechanism behind the denials on this page, and
[users, root and sudo](/learn/linux-plus/users-root-and-sudo) covers the accounts.
The Network+ treatment of
[security vocabulary and the CIA triad](/learn/network-plus/security-vocabulary-and-the-cia-triad)
covers the same three properties from a network's point of view.
