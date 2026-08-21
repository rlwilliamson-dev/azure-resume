---
title: "The hour after it breaks"
description: "Topic 61 gives you a method for finding a fault. This is everything happening around you while you use it: who runs the incident, what to say when you do not know yet, when escalating is the right call, and why a postmortem that names a person has found nothing."
deck: "Nine messages, three people in the room, and you have not looked at an interface yet"
track: "network-plus"
level: "working"
order: 820
beyondExam: true
objectives:
  - "Separate running an incident from working on it, and say why one person cannot do both"
  - "Write an update that is useful before the cause is known"
  - "Set an escalation trigger in advance and act on it without treating it as failure"
  - "Say why changing several things at once turns one incident into two"
  - "Explain what blameless means and why human error is not a finding"
prerequisites: ["the-troubleshooting-methodology", "lifecycle-change-and-configuration-management"]
tags: ["network-plus", "networking", "operations", "beyond-the-exam"]
updated: 2026-08-20
draft: false
examObjectives: []
sources:
  - title: "Managing Incidents, Site Reliability Engineering"
    url: "https://sre.google/sre-book/managing-incidents/"
    publisher: "Google"
    accessed: 2026-08-20
    tier: 2
  - title: "Postmortem Culture: Learning from Failure, Site Reliability Engineering"
    url: "https://sre.google/sre-book/postmortem-culture/"
    publisher: "Google"
    accessed: 2026-08-20
    tier: 2
  - title: "NIST SP 800-61 Rev. 3, Incident Response Recommendations and Considerations for Cybersecurity Risk Management"
    url: "https://csrc.nist.gov/pubs/sp/800/61/r3/final"
    publisher: "NIST"
    accessed: 2026-08-20
    tier: 1
symptoms:
  - symptom: "An outage is being worked on and nobody outside the room knows anything"
    anchor: "what-to-say-before-you-know"
  - symptom: "A fix made things worse and nobody can say exactly what was changed"
    anchor: "how-one-incident-becomes-two"
---

> **Before you read.** It broke twelve minutes ago. Your phone has nine messages,
> two managers are standing behind you, somebody is asking whether to send an
> email to customers, and you have not looked at a single interface yet.
>
> **What is the first thing to do, and why is it not technical?**

Topic 61 gives you a method for finding a fault and topic 37 gives you the process
for changing something on purpose. Neither describes the hour this page is about,
which is the one where a fault is live, several people want to know things, and
the quality of your work depends mostly on decisions that have nothing to do with
networking.

### Some words you will need

<dl class="terms">
<dt>incident</dt>
<dd>An unplanned interruption or degradation. The word covers everything from one user to the whole site.</dd>
<dt>incident command</dt>
<dd>The person holding the overall picture and deciding what happens next. Not necessarily the most senior, and not the one typing.</dd>
<dt>cadence</dt>
<dd>How often updates go out, agreed in advance and kept to whether or not there is news.</dd>
<dt>escalation</dt>
<dd>Bringing in more people or more authority. A trigger, not a judgement.</dd>
<dt>blast radius</dt>
<dd>Who and what is affected. The first thing anybody outside the room wants to know.</dd>
<dt>postmortem</dt>
<dd>The written account afterwards: timeline, contributing factors, and what changes as a result.</dd>
</dl>

## What breaks without this

**The investigation never gets an uninterrupted run at the problem.** Every
interruption costs more than the minutes it takes, because the state you were
holding in your head has to be rebuilt.

**People invent their own answers.** In the absence of information, an
organisation fills the gap, and the version it invents is worse than the truth and
much harder to correct later.

**The fix causes the next incident.** Under pressure, several changes go in at
once, nobody writes them down, and the following morning nobody can say what the
network is running.

**Nothing is learned.** An incident that ends without a written account teaches
one person something and the organisation nothing, and the same fault arrives
again with a different name.

## The first job is not technical

The single most valuable thing to do in the first two minutes is to decide who is
doing what, even if the team is two people.

Somebody holds the overall picture and decides what happens next. Somebody
communicates outward. Somebody investigates and, importantly, is the only person
touching the equipment. The SRE literature that formalised this is blunt about the
last part: the operations role "should be the only group modifying the system
during an incident", because two people fixing the same thing independently is a
second fault arriving during the first.

Those are roles rather than people. In a team of two, one runs it and talks and
the other works, and the split is still worth naming out loud because the failure
it prevents is the one that happens by default.

<figure class="learn-figure">
<svg viewBox="0 0 720 226" role="img" aria-labelledby="incident-title" style="width:100%;height:auto;">
<title id="incident-title">One hour of an incident drawn twice, once as a single person's investigation broken into five fragments by interruptions and once as an uninterrupted hour alongside updates sent on a fixed cadence</title>
<g fill="currentColor">
<text x="14" y="24" font-size="11">the same hour, worked two ways</text>
<text x="60" y="58" font-size="10.5">one person, both jobs</text>
<rect x="60" y="68" width="73" height="24" rx="2" fill="currentColor" fill-opacity="0.12" stroke="currentColor" stroke-opacity="0.45"/>
<rect x="175" y="68" width="84" height="24" rx="2" fill="currentColor" fill-opacity="0.12" stroke="currentColor" stroke-opacity="0.45"/>
<rect x="312" y="68" width="94" height="24" rx="2" fill="currentColor" fill-opacity="0.12" stroke="currentColor" stroke-opacity="0.45"/>
<rect x="469" y="68" width="94" height="24" rx="2" fill="currentColor" fill-opacity="0.12" stroke="currentColor" stroke-opacity="0.45"/>
<rect x="627" y="68" width="63" height="24" rx="2" fill="currentColor" fill-opacity="0.12" stroke="currentColor" stroke-opacity="0.45"/>
<text x="60" y="112" font-size="10.5">39 minutes of investigation, and four interruptions</text>
<text x="60" y="148" font-size="10.5">two people, one job each</text>
<rect x="60" y="158" width="630" height="24" rx="2" fill="var(--accent)" fill-opacity="0.2" stroke="var(--accent)" stroke-width="1.5"/>
<line x1="165" y1="184" x2="165" y2="192" stroke="var(--accent)" stroke-width="1.6"/>
<line x1="270" y1="184" x2="270" y2="192" stroke="var(--accent)" stroke-width="1.6"/>
<line x1="375" y1="184" x2="375" y2="192" stroke="var(--accent)" stroke-width="1.6"/>
<line x1="480" y1="184" x2="480" y2="192" stroke="var(--accent)" stroke-width="1.6"/>
<line x1="585" y1="184" x2="585" y2="192" stroke="var(--accent)" stroke-width="1.6"/>
<line x1="690" y1="184" x2="690" y2="192" stroke="var(--accent)" stroke-width="1.6"/>
<text x="60" y="212" font-size="10.5" fill="var(--accent)">60 minutes of investigation, and an update every ten</text>
</g>
</svg>
<figcaption>The gaps in the top row are not the whole cost. An interruption ends a train of thought, and the minutes after it are spent rebuilding what was already known rather than finding out something new, so four interruptions cost considerably more than the twenty one minutes they occupied. The ticks under the second row are the updates, going out on a fixed cadence from somebody whose job that is. Nobody in the second row worked harder. The hour was simply spent on one thing each.</figcaption>
</figure>

<details class="deeper">
<summary>If you are usually the only person available: how to run this alone without pretending you have a team</summary>

Small teams get told to adopt incident roles and reasonably point out that there
is one of them. The roles still help, because what they really separate is two
modes of attention rather than two people, and the trick is to timebox rather than
interleave.

Announce the cadence first, before anything else, and make it long enough to be
survivable. "I will send an update every fifteen minutes" buys you fourteen
minutes of uninterrupted work and costs one, and the promise is what stops people
interrupting to ask, because they know when the answer is coming.

Then keep a running log as you go, in a text file or a chat channel nobody else
posts in. One line per thing you did or found, with the time. It costs seconds
during the incident and it produces the update, the handover, and the postmortem
timeline for nothing. Writing this after the fact is where people discover they
cannot remember the order things happened in.

And say out loud, to whoever is standing behind you, that you will not be
answering questions between updates. It feels rude the first time. It is the
single largest improvement available to somebody working alone, and everybody
senior enough to be standing there has been on the other side of it and will
recognise what you are doing.

</details>

## What to say before you know

The instinct is to wait until you have something worth saying. That instinct is
wrong, and understanding why is most of what this section is for.

An update has two jobs. The smaller one is to convey information. The larger one
is to establish that the problem is being worked on by somebody competent, which
is what everybody outside the room actually wants to know and which is
communicated by the update arriving on time rather than by its contents.

So an update sent to schedule saying "no new information, still investigating, next
update at ten past" is doing its job. An update that arrives late because you were
waiting for something better has already failed at the larger one, and by then the
organisation has started constructing its own account.

Four things belong in one, and it is worth having the shape memorised:

| Part | What it answers |
| --- | --- |
| What is broken, from the user's side | Whether this is the thing they are experiencing |
| What is known, and what is not | Whether the picture is forming or still blank |
| What is being done now | Whether anybody is on it |
| When the next update comes | Whether they need to keep asking |

**The one thing not to put in it is a restore time.** A guess made under pressure
becomes a commitment the moment it is written down, gets forwarded to a customer
within minutes, and the second guess is believed much less than the first one was.
Where a time is genuinely demanded, the honest form is to give a time by which you
will know more, which is a thing you control.

<details class="deeper">
<summary>If you talk to executives during outages: what they are actually asking, and the answer that ends the conversation</summary>

The question that arrives is usually "when will it be fixed", and it is almost
never the real question. What the person needs is a decision: whether to invoke a
contingency, whether to tell a customer, whether to cancel something, whether to
stay at their desk. Each of those has a deadline of its own and none of them
requires knowing when the fault will be repaired.

So the useful reply is not a better estimate. It is to find the decision. "What
are you deciding, and when do you need to have decided it?" turns an
unanswerable question into a scheduling problem, and frequently the answer is
that they need to know by half past, which is something you can commit to.

The second thing worth having ready is the impact in their vocabulary rather than
yours. Not that a distribution switch has lost an uplink, but that the second
floor cannot take orders and everything else is working. That sentence is what
they will repeat to somebody else, and if you do not supply it they will
construct it from what they overheard.

None of this is presentation skill and none of it is optional at any level of
seniority. It is the difference between being asked every four minutes and being
left to work.

</details>

## Escalation is a trigger, not a verdict

The reason people escalate late is that it feels like an admission, and the reason
it should not is that the decision was supposed to be made before the incident
started.

Set the trigger on something you cannot argue with when tired. Time is the usual
one: if this is not understood by a certain point, the next person is called
regardless of how close it feels. Scope is the other: if the number of affected
users passes some line, or a second site is involved, or data is at risk, that
alone escalates.

The value is in deciding it in advance. In the middle of an incident, every
assessment of whether you are nearly there is made by somebody who has been
staring at it for an hour and has a strong personal interest in the answer being
yes.

## How one incident becomes two

Under pressure the tempting move is to change several things at once, because the
alternative feels slower. It is slower. It is also the only version where you know
what happened.

Change one thing. Observe. Write it down. If it did not help, put it back before
the next one. That sequence is the discipline topic 61's method depends on, and
it is exactly the discipline that pressure removes.

The written record is the part that gets skipped and the part that matters most
the following day. Somebody will ask what the network is running, whether the
change made at 03:40 is still in place, and whether it was ever meant to be
permanent. A running log answers all three in seconds. Memory answers none of
them, and the temporary fix that nobody removed is one of the most common causes
of the next incident.

<details class="deeper">
<summary>If you have inherited somebody else's incident: what to establish before touching anything</summary>

Handover is where most of the damage in long incidents happens, because the
incoming person has the energy and the outgoing person has the context, and those
are exactly the wrong way round for a safe transfer.

Four questions, before anything else. What is the current state, as opposed to
what it was at the start? What has been changed since it began, and which of those
changes are still in place? What has been ruled out, and on what evidence? And
what has already been said to whom, so the next update does not contradict the
last one.

The third is the one people skip and the most expensive to lose. An incident that
has run for six hours has usually eliminated several plausible causes, and if that
knowledge is not transferred the new person re-examines them, which is both a
waste of an hour and a source of contradictory conclusions when they get a
different result for an unrelated reason.

The fourth is the one that causes visible damage. A new person arriving and saying
something that contradicts the previous update destroys the credibility of every
update since the start, and it is entirely avoidable by reading them.

</details>

## The postmortem, and the word blameless

Afterwards there is a written account. Its purpose is to change something, and
almost every way of writing one badly comes from forgetting that.

The convention it is written under is blamelessness, and the term is precise
rather than polite. A blameless account, in the words of the SRE literature that
made the practice common, focuses on "identifying the contributing causes of the
incident without indicting any individual or team". The reasoning is practical:
you cannot fix people, and you can fix the systems and processes that let a
reasonable person make the wrong call with the information they had.

Which is why **human error is not a finding**. If somebody typed the wrong
interface number, the questions are why that was possible, why nothing checked it,
why the blast radius was the whole building, and why it took forty minutes to
notice. Every one of those has an action attached to it. "Be more careful" has
none, and an organisation that stops at it has bought nothing with the outage it
just paid for.

Three parts do the work. A timeline, in plain times, of what happened and what was
known when. Contributing factors, plural, because outages of any size have
several and picking one to call the root cause is usually a decision about who to
blame. And actions with an owner and a date, which is the only part anybody will
read in six months.

It is also worth deciding in advance which incidents get one, because the decision
is impossible to make fairly afterwards. Any user-visible outage past some
duration, any data loss, any incident where the recovery involved something
unplanned, any incident nobody noticed until a customer reported it. Written down
beforehand, the criteria protect the people involved from an argument about
whether this one was serious enough.

## Prove it

**Write the first update for something that has just broken.** Take a fault you
have actually seen, set a stopwatch for three minutes, and write the update you
would send twelve minutes in, knowing nothing. Four parts, no restore time. It is
harder than it sounds and it is much harder for the first time to be during a real
incident.

**Read a chapter rather than a summary.** The two SRE chapters on managing
incidents and on postmortem culture are free, short, and specific. Read the
managed and unmanaged versions of the same incident in the first one, which makes
the argument better than any description of it does.

**Look up what your own organisation says.** There is a procedure somewhere,
probably unread, that names who declares an incident and who is allowed to talk to
customers. Find out what it says before the night you need it, because the two
worst times to discover a policy are during an incident and in the review
afterwards.

## What trips people up

### 1. Investigating and communicating at once

Both jobs get done badly. The investigation is fragmented by interruptions and the
updates are late, which produces more interruptions.

### 2. Waiting for something worth saying

The schedule is the message. An update on time with nothing in it is better than a
detailed one that arrives after people have started guessing.

### 3. Giving a restore time

It becomes a commitment immediately and it is usually wrong. Commit to when you
will next say something instead.

### 4. Changing three things because one of them might work

Then nothing is attributable, and the change that helped cannot be told from the
two that did not. One at a time, put back what did not work.

### 5. Escalating on feel

The trigger should have been set before the incident, on time or on scope, by
somebody who was not tired and invested.

### 6. Writing a postmortem that names somebody

It ends the investigation at the point where the useful questions start, and it
teaches everybody watching to be less forthcoming next time.

## Work it through

At 14:20 a site loses connectivity to head office. You are the only network person
available. Within four minutes you have three messages from the site manager, a
call from your own manager, and an email asking whether to tell the customer whose
order was in progress.

Start with the announcement rather than the fault, because it is the thing that
buys time to work on the fault. One message to everybody who has asked: the site
cannot reach head office, local systems are unaffected, it is being worked on now,
next update at 14:35. That sentence costs ninety seconds and removes most of the
interruptions for the next quarter of an hour.

Then set the escalation trigger while you are still calm enough to set it
sensibly. If you do not understand it by 15:00, the provider gets called and your
manager gets told it is going longer than an hour. Writing that down now means the
decision at 15:00 is a reading rather than a judgement.

Then work it, one change at a time, with a running log. Two lines per action, the
time and what you did, in whatever is to hand.

The email about the customer is not yours to answer and it is worth saying so
explicitly rather than leaving it. What you owe that person is the impact in their
terms: the site cannot reach head office, orders taken there are not reaching the
system, everything else works. What they do with that is their decision, and it is
a decision they can only make with a sentence you have not yet given them.

And when it is over, before going home, spend ten minutes turning the log into a
timeline while it is fresh. That is the part that gets skipped, and it is the only
version of the incident that will exist in a year.

## Try it

**Agree the roles before the next incident, not during one.** Two names and what
each does. It takes one conversation and it is the highest return item on this
page.

**Write the update template down where it will be found at 3am.** Four headings.
Somebody woken up does not compose, they fill in.

**Set your criteria for who gets a postmortem.** Before an incident makes the
decision political.

## Check yourself

<details class="qa">
<summary>Why should the person investigating not also be the person sending updates?</summary>

Because every interruption costs more than the time it takes: the state being held
in mind has to be rebuilt afterwards. Splitting the roles gives the investigation
an uninterrupted run and gets the updates out on time, which is what stops the
interruptions in the first place.

</details>

<details class="qa">
<summary>Twelve minutes in you know nothing. What goes in the update?</summary>

What is broken from the user's point of view, that the cause is not yet known,
what is being done right now, and when the next update will arrive. Not a restore
time. The update's main job at this stage is to establish that somebody competent
is on it.

</details>

<details class="qa">
<summary>Why set an escalation trigger before the incident rather than during it?</summary>

Because during it the assessment of whether you are nearly there is made by
somebody who has been staring at the problem for an hour and wants the answer to
be yes. A trigger on elapsed time or on scope is a reading rather than a
judgement.

</details>

<details class="qa">
<summary>What is wrong with a postmortem finding of human error?</summary>

It stops at the point where the useful questions begin. Why was the mistake
possible, what failed to catch it, why did it affect that much, and why did
detection take as long as it did. Each of those has an action attached and the
finding of human error has none.

</details>

<details class="qa">
<summary>Why is contributing factors better than root cause?</summary>

Because an outage of any size has several, and choosing one to elevate is usually
a decision about which part of the organisation to point at. Listing them all
produces more actions and fewer arguments.

</details>

## References

- [Managing Incidents](https://sre.google/sre-book/managing-incidents/) - Google, Site Reliability Engineering, for the separation of roles and the worked comparison of a managed and an unmanaged incident. Free. Accessed 2026-08-20.
- [Postmortem Culture: Learning from Failure](https://sre.google/sre-book/postmortem-culture/) - Google, Site Reliability Engineering, for what blameless means and for the criteria that decide which incidents get a written account. Free. Accessed 2026-08-20.
- [NIST SP 800-61 Rev. 3](https://csrc.nist.gov/pubs/sp/800/61/r3/final) - NIST, April 2025, incident response recommendations, for the preparation and lessons-learned halves of the same argument in a security context. Free. Accessed 2026-08-20.

**Where this came from.** Nothing on this page is captured, because none of it is
a command. The role separation and the postmortem convention are from the two SRE
chapters cited above, quoted where quoted. The figure is drawn to argue the cost
of interruption rather than to report a measurement, and the numbers in it are an
illustration rather than data from anywhere.

**Why this is not in the lesson count.** The objectives cover the troubleshooting
methodology and change management, both of which have their own topics here.
Nothing in them asks about incident roles, communication, or postmortems, and
every survey of what employers find missing in new engineers names this half of
the work.
