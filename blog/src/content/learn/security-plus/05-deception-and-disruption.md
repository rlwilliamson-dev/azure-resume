---
title: "Deception and disruption"
description: "Why an alert from a file nobody should open is worth a hundred from a content rule, what distinguishes the four deception artefacts the exam names, why three of them cost almost nothing, and what running a machine built to be attacked actually commits you to."
deck: "A file called passwords_final.csv that nobody has any reason to open"
track: "security-plus"
level: "working"
order: 60
objectives:
  - "Say why a deception control produces almost no false positives"
  - "Distinguish honeypot, honeynet, honeyfile and honeytoken by what each one is"
  - "Explain what a honeytoken does that the other three cannot"
  - "Name what running a honeypot commits you to"
  - "Choose a deception control for a stated problem and say what the rejected ones would have cost"
prerequisites: ["control-categories-and-control-types"]
tags: ["security-plus", "security", "detection", "deception"]
updated: 2026-08-25
draft: false
examObjectives:
  - exam: "sy0-701"
    domain: "1.0"
    objective: "1.2"
sources:
  - title: "NIST SP 800-53 Rev. 5, Security and Privacy Controls for Information Systems and Organizations"
    url: "https://csrc.nist.gov/pubs/sp/800/53/r5/upd1/final"
    publisher: "NIST"
    accessed: 2026-08-25
    tier: 1
  - title: "NIST SP 800-94, Guide to Intrusion Detection and Prevention Systems"
    url: "https://csrc.nist.gov/pubs/sp/800/94/final"
    publisher: "NIST"
    accessed: 2026-08-25
    tier: 1
  - title: "mount(8), and the atime, relatime and noatime options"
    url: "https://man7.org/linux/man-pages/man8/mount.8.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-25
    tier: 1
symptoms:
  - symptom: "An alert fires and nobody can tell whether it matters"
    anchor: "why-the-alert-is-worth-reading"
---

> **Before you read.** There is a file on the finance share called
> `passwords_final.csv`. It contains a server name, a username and a password.
> None of them work. Nobody in the company has been told it is there, except that
> everybody has been told not to open it.
>
> **What has that bought, and what did it cost?**

Every other detective control on this exam has to tell the difference between
normal activity and an attack. Deception and disruption technology does not, and
that one property is worth the whole topic.

### Some words you will need

<dl class="terms">
<dt>honeypot</dt>
<dd>A machine that exists to be attacked, so that attacking it tells you somebody is there.</dd>
<dt>honeynet</dt>
<dd>Several honeypots on a network of their own, so an intruder finds an environment rather than a box.</dd>
<dt>honeyfile</dt>
<dd>A file nobody has a legitimate reason to open, watched for being opened.</dd>
<dt>honeytoken</dt>
<dd>A record, credential or address that is not real, watched for being used.</dd>
<dt>false positive</dt>
<dd>An alert about something that was not an attack.</dd>
<dt>base rate</dt>
<dd>How common the thing you are looking for actually is, which decides what an alert is worth.</dd>
</dl>

## What breaks without this

**Alerts arrive that nobody can act on.** A detection with a high false positive
rate produces work rather than knowledge, and the work is done by somebody who
eventually stops doing it.

**A breach is found by somebody else.** The single most common way an
organisation learns it has been compromised is being told, and most of the
alternatives require noticing something subtle in a lot of normal traffic.

**A honeypot becomes a liability.** A machine built to be attacked, run without
isolation, is a machine somebody else is now using, and it has your address on it.

## Why the alert is worth reading

Take one week on a file share, and compare two ways of detecting the same
incident.

<figure class="learn-figure">
<svg viewBox="0 0 720 298" role="img" aria-labelledby="br-title" style="width:100%;height:auto;">
<title id="br-title">One week on a file share compared two ways, with a content inspection rule producing a hundred alerts of which one is real, and a honeyfile producing one alert which is real</title>
<g fill="currentColor">
<text x="14" y="20" font-size="11">one week, one file share, ten thousand legitimate file opens</text>
<text x="14" y="52" font-size="9.5" fill-opacity="0.85">a rule that flags one percent as suspicious</text>
<rect x="290" y="40" width="380" height="18" rx="2" fill="currentColor" fill-opacity="0.16" stroke="currentColor" stroke-opacity="0.7" stroke-width="1.2"/>
<text x="300" y="53" font-size="8.5">99 alerts nobody needed to read</text>
<rect x="670" y="40" width="4" height="18" rx="1" fill="var(--accent)" fill-opacity="0.6" stroke="var(--accent)" stroke-width="1.2"/>
<text x="290" y="76" font-size="9" fill-opacity="0.8">100 alerts, 1 of them real. one in a hundred is worth acting on.</text>
<text x="14" y="126" font-size="9.5" fill-opacity="0.85">a file nobody has a reason to open</text>
<rect x="290" y="114" width="4" height="18" rx="1" fill="var(--accent)" fill-opacity="0.6" stroke="var(--accent)" stroke-width="1.2"/>
<text x="304" y="127" font-size="8.5">1 alert</text>
<text x="290" y="150" font-size="9" fill-opacity="0.8">1 alert, 1 of them real. every one is worth acting on.</text>
<path d="M 14 178 H 706" stroke="currentColor" stroke-opacity="0.3" stroke-width="1"/>
<text x="14" y="206" font-size="10" fill-opacity="0.85">both detectors saw the same incident, and one of them buried it in ninety-nine others</text>
<text x="14" y="228" font-size="10" fill-opacity="0.85">the difference is not sensitivity, it is that the second one has no legitimate traffic</text>
<text x="14" y="250" font-size="10" fill-opacity="0.85">a detector placed where nothing normal happens cannot produce a false positive</text>
<text x="14" y="272" font-size="10" fill-opacity="0.85">which is the cheapest good alert in security and almost nobody deploys it</text>
<text x="14" y="294" font-size="9" fill-opacity="0.7">the accented marks are the real incident, drawn to the same scale in both rows</text>
</g></svg>
<figcaption>The arithmetic is stated so it can be checked rather than taken. Ten thousand file opens in a week and a content inspection rule that flags one percent of them gives a hundred alerts, and if one incident happened that week then one alert in a hundred was worth reading. The honeyfile sees the same incident and produces one alert, because the other 9,999 opens were of files people had a reason to open and it was not one of them. Nothing about the second detector is more sophisticated. It is placed where there is no legitimate traffic, so it has no false positives to generate, and that is a property of the position rather than of the technology. It is also why the first thing anyone should ask about an alert is not how clever the detection was but how much normal activity looks like it.</figcaption>
</figure>

The arithmetic is deliberately simple so it can be checked. Ten thousand
legitimate file opens in a week. A content inspection rule that flags one percent
of activity as suspicious produces a hundred alerts. One real incident happened
that week, so one alert in a hundred was worth reading.

The honeyfile sees the same incident and produces one alert.

**Nothing about the second detector is cleverer.** It is placed where there is no
legitimate traffic, so it has no false positives available to generate. That is a
property of the position and not of the technology, and it is the whole reason
deception is worth the shelf space.

This is the base rate at work, and it is worth carrying past this topic. **The
first question about any alert is not how sophisticated the detection is. It is
how much normal activity looks like it.** A detection that is right ninety-nine
percent of the time, applied to something that happens once in ten thousand
events, still buries the real one.

<details class="deeper">
<summary>If you tune detections: the arithmetic that makes good rules useless</summary>

The figure understates the problem, because it assumed the rule flags one percent.
Run it the other way, with a rule that is genuinely accurate, and the result is
worse than people expect.

Suppose a detection catches ninety-nine percent of attacks and has a false
positive rate of one percent, which would be an extremely good rule. Apply it to
ten thousand events of which one is an attack. It catches the attack, and it also
flags one percent of the 9,999 normal events, which is about a hundred of them. So
a ninety-nine percent accurate detection produces a hundred and one alerts of
which one matters.

That is the base rate fallacy and the uncomfortable part is that the rule is not
bad. Improving it to 99.9 percent accuracy leaves ten false positives against one
real, which is still ten times more noise than signal, and getting there is
enormously harder than getting to ninety-nine.

Two things follow, and they are the whole of practical detection engineering.
Reducing the volume of normal activity a detection sees does more than improving
the detection, which is why scoping a rule to a segment or a set of accounts beats
tuning its logic. And a detector placed where the base rate of normal activity is
zero wins automatically, which is deception.

It is also the reason alert fatigue is a design failure rather than a staffing
one, which topic 48 picks up.

</details>

## Four artefacts, and only one of them is a machine

The exam lists four things that sound like sizes of the same idea. The division
that matters runs between the top two and the bottom two.

<figure class="learn-figure">
<svg viewBox="0 0 720 300" role="img" aria-labelledby="four-title" style="width:100%;height:auto;">
<title id="four-title">The four deception artefacts placed by what each one is, showing that only the honeypot is a machine and the other three are a network, a file and a record</title>
<g fill="currentColor">
<text x="14" y="20" font-size="11">three of the four are not machines, which is why three of them are nearly free</text>
<text x="150" y="46" font-size="9.5" fill-opacity="0.85">what it is</text>
<text x="400" y="46" font-size="9.5" fill-opacity="0.85">what it costs to run</text>
<text x="14" y="76" font-size="9.5">honeypot</text>
<rect x="140" y="60" width="240" height="24" rx="3" fill="var(--red)" fill-opacity="0.14" stroke="var(--red)" stroke-opacity="0.75" stroke-width="1.3"/>
<text x="152" y="76" font-size="8.5">a whole machine, deliberately reachable</text>
<rect x="396" y="60" width="310" height="24" rx="3" fill="var(--red)" fill-opacity="0.14" stroke="var(--red)" stroke-opacity="0.75" stroke-width="1.3"/>
<text x="408" y="76" font-size="8">patching, isolating, and the risk it gets used against you</text>
<text x="14" y="124" font-size="9.5">honeynet</text>
<rect x="140" y="108" width="240" height="24" rx="3" fill="var(--red)" fill-opacity="0.14" stroke="var(--red)" stroke-opacity="0.75" stroke-width="1.3"/>
<text x="152" y="124" font-size="8.5">several of those, on their own network</text>
<rect x="396" y="108" width="310" height="24" rx="3" fill="var(--red)" fill-opacity="0.14" stroke="var(--red)" stroke-opacity="0.75" stroke-width="1.3"/>
<text x="408" y="124" font-size="8.5">all of the above, several times over</text>
<text x="14" y="172" font-size="9.5">honeyfile</text>
<rect x="140" y="156" width="240" height="24" rx="3" fill="var(--accent)" fill-opacity="0.18" stroke="var(--accent)" stroke-width="1.4"/>
<text x="152" y="172" font-size="8.5">a file, on a share you already have</text>
<rect x="396" y="156" width="310" height="24" rx="3" fill="var(--accent)" fill-opacity="0.18" stroke="var(--accent)" stroke-width="1.4"/>
<text x="408" y="172" font-size="8.5">telling your own staff not to open it</text>
<text x="14" y="220" font-size="9.5">honeytoken</text>
<rect x="140" y="204" width="240" height="24" rx="3" fill="var(--accent)" fill-opacity="0.18" stroke="var(--accent)" stroke-width="1.4"/>
<text x="152" y="220" font-size="8.5">a record, a key, a row, an address</text>
<rect x="396" y="204" width="310" height="24" rx="3" fill="var(--accent)" fill-opacity="0.18" stroke="var(--accent)" stroke-width="1.4"/>
<text x="408" y="220" font-size="8.5">somewhere that notices it being used</text>
<text x="14" y="262" font-size="10" fill-opacity="0.85">the top two are systems to be run, and the bottom two are bait to be planted</text>
<text x="14" y="284" font-size="10" fill-opacity="0.85">a honeytoken travels, so it reports from wherever the data ended up</text>
</g></svg>
<figcaption>The four are usually listed as though they were sizes of the same thing, and the division that matters is between the top two and the bottom two. A honeypot is a machine, and a honeynet is several of them on a network of their own, which means both are systems somebody has to run, patch and isolate, and both carry the risk that a thing built to be attacked succeeds and is then used to attack something else. The bottom two are not machines at all. A honeyfile is a file on a share that already exists, and a honeytoken is a record: a fake customer row, a credential that works nowhere, an email address used for nothing. The cost of those two is almost entirely organisational, which is telling your own people not to touch them. A honeytoken also does something none of the others can, which is travel: plant one in a database and it reports from wherever a copy of that database ends up, including somewhere you have no access to at all.</figcaption>
</figure>

**A honeypot is a machine** that exists to be attacked. **A honeynet** is several
of them with a network of their own, so that an intruder finds an environment to
move around in rather than one suspicious box.

Both are systems somebody has to run. They need patching, monitoring and
isolating, and they carry a risk the other two do not: a machine built to be
attacked may be successfully attacked, and it is then a functioning host with your
addresses on it that somebody else controls.

**A honeyfile is a file** on a share that already exists.

**A honeytoken is a record**: a fake customer row, a credential that authenticates
nowhere, an email address used for nothing, an API key that is monitored and
grants nothing.

Those two cost almost nothing to deploy, and their real cost is organisational
rather than technical. Somebody has to tell the staff not to touch them, and
somebody has to remember they exist when a new person joins and starts tidying up
the share.

<details class="deeper">
<summary>If you are considering a honeypot: the two kinds, and the commitment each one is</summary>

The distinction that decides whether a honeypot is a reasonable idea is how much
of a real system it presents.

A **low-interaction** honeypot emulates enough of a service to record the attempt
and no more. It answers on a port, logs what was sent, and cannot be compromised
because there is nothing behind it. It tells you somebody is scanning and knocking,
which is a real signal on an internal network and close to meaningless on the
public internet, where everything is scanned constantly.

A **high-interaction** honeypot is a real system. It can be exploited, which is
the point: you learn what an attacker does after they get in, which is the
information nothing else gives you. You have also placed a genuinely vulnerable
machine on your network on purpose, and the commitment that comes with it is
containment, monitoring and somebody watching it, because an unwatched
high-interaction honeypot is simply a compromised host.

There is a legal dimension worth knowing about too. A machine of yours used to
attack a third party is a problem that is yours, whatever your intentions were,
which is why the containment is not optional and why this is not a weekend
project.

The practical answer for most organisations is that the top two are not worth it
and the bottom two are, which is roughly the opposite of the attention they get.
A honeypot is interesting and a honeytoken is useful.

</details>

## The cheapest one, and what makes it work

Here is a honeyfile doing its whole job.

<details class="predict">
<summary>The file is opened once. What do you expect the share to show afterwards?</summary>

```bash
# AlmaLinux 10.2, x86_64
$ mkdir -p /srv/share && cd /srv/share
printf "server,user,password\nbackup01,svc_backup,Wint3r2026!\n" > passwords_final.csv
touch -d "2026-03-14 09:12:00" passwords_final.csv
echo "the file, as it sits on the share:"
ls -l --time=atime passwords_final.csv
echo
echo "somebody opens it:"
cat passwords_final.csv > /dev/null
echo
echo "and the share looks like this now:"
ls -l --time=atime passwords_final.csv
echo
echo "mount options, which decide whether that worked:"
findmnt -no OPTIONS / 2>/dev/null | tr "," "\n" | grep -i atime || echo "(no atime option listed)"
the file, as it sits on the share:
-rw-r--r--. 1 root root 53 Mar 14 09:12 passwords_final.csv

somebody opens it:

and the share looks like this now:
-rw-r--r--. 1 root root 53 Aug 25 18:24 passwords_final.csv

mount options, which decide whether that worked:
relatime
```

</details>

The access time moved from March to today, and nothing else about the file changed.
That is the entire mechanism: a file with a name somebody will want, contents that
work nowhere, and a timestamp that says whether anybody has looked.

**The last command is the caveat and it is a real one.** The filesystem is mounted
`relatime`, which updates the access time only when the previous one is older than
the modification time or more than a day old. It worked here because the recorded
time was months stale. On a file read twice in one afternoon, the second read
leaves no trace, and on a filesystem mounted `noatime`, which is common because it
is faster, nothing is recorded at all.

So the honest version of this control is that access time is the cheapest possible
implementation and the least reliable one, and on Windows it does not work at all
without a setting being changed first, which the next section demonstrates. A real
deployment watches the file with something that reports every open rather than
depending on a timestamp, and the value of the technique is in where the file is,
not in how the opening is noticed.

## What a honeytoken does that nothing else can

A honeypot tells you somebody is on your network. A honeyfile tells you somebody
opened something on your share. Both of those require the attacker to be somewhere
you can see.

**A honeytoken travels with the data.** Put a fake customer record in a database,
with an address or a phone number that belongs to nobody and is monitored, and it
reports from wherever a copy of that database ends up. Including a place you have
no access to, no visibility into, and no relationship with.

That is a genuinely different capability. It is how organisations find out their
data has been sold, how mailing lists detect being copied, and how a leak gets
attributed to one of several parties who all received slightly different copies.

The same idea with a credential is the version most useful day to day. A key that
grants nothing, placed in a configuration file or a repository, is silent forever
and produces one unambiguous alert the moment somebody who should not have it
tries to use it. There is no legitimate use, so there is no false positive
available.

<details class="deeper">
<summary>If you are seeding these: what makes a token believable, and the two ways they get burned</summary>

A honeytoken only works while nobody can tell it apart from the real thing, and
the ways that fails are boringly practical rather than clever.

The first is that the fake record does not look like the real ones. Real customer
data has a distribution: names that occur at plausible rates, addresses that
resolve, identifiers issued in the ranges the system actually issues. A row where
every field is obviously synthetic is skipped by anybody paying attention, and
the ones who are paying attention are the ones you most wanted to catch. The fix
is to generate them from the shape of the real data rather than from imagination.

The second is that your own systems find them. A fabricated customer gets a
marketing email, fails a validation job, appears in a reconciliation report, or
turns up in a monthly total that no longer balances. Somebody investigates, files
a data quality ticket, and the token is deleted by a colleague doing their job
well. That is the more common death and it is why the register of which tokens
exist has to be held somewhere the data quality team can consult without it being
public.

The tension between those two is the whole design problem: believable enough to
fool an attacker and known well enough internally not to be cleaned up. It is also
why the seeding is usually done by a small number of people and documented
carefully, which is a governance answer to a technical-sounding question.

</details>

## Across platforms

The Linux capture above reads an access time and a mount option. Both of those
are different questions on the other two platforms, and the answers are not
variations on a theme: the technique works better on one and does not work at
all on the other.

| Task | Linux | Windows | macOS |
| --- | --- | --- | --- |
| Read a file's access time | `ls -l --time=atime file` | `(Get-Item file).LastAccessTime` | `stat -f '%Sa' file` |
| Does the filesystem record it | `findmnt -no OPTIONS /` | `fsutil behavior query disablelastaccess` | `mount`, which names an atime option only when it is off |
| Watch every open instead | `auditctl -w file -p r` | a SACL on the file plus `auditpol` | Endpoint Security, and no one-line equivalent |

<details class="predict">
<summary>A honeyfile is planted on a Windows share and its access time is set to March. Somebody opens it in August. What does the access time say afterwards?</summary>

```powershell
# Microsoft Windows Server 2025 Datacenter, version 10.0.26100.0
> fsutil behavior query disablelastaccess
DisableLastAccess = 3  (System Managed, Last Access Time Updates DISABLED)

# A honeyfile, with its recorded access time set months into the past
> $f = "$env:TEMP\passwords_final.csv"; Set-Content -Path $f -Value "server,user,password" -NoNewline; (Get-Item $f).LastAccessTime = [datetime]'2026-03-14 09:12:00'; (Get-Item $f).LastAccessTime.ToString('yyyy-MM-dd HH:mm:ss')
2026-03-14 09:12:00

# Somebody opens it, and this is what the share shows afterwards
> Get-Content $f | Out-Null; Start-Sleep -Seconds 3; (Get-Item $f).LastAccessTime.ToString('yyyy-MM-dd HH:mm:ss')
2026-03-14 09:12:00

# The route that does not depend on timestamps, and whether it is switched on
> auditpol /get /subcategory:"File System"
System audit policy
Category/Subcategory                      Setting
Object Access
  File System                             No Auditing
```

</details>

**Read the third and fourth commands together, because that is the finding.** The
access time was set to March, the file was then read, and the recorded time is
still March. On Windows the technique does not work. It is not a mount option
there but one machine-wide setting, reported as `DisableLastAccess = 3`, which is
System Managed and disabled, and it has shipped that way for years.

The last command matters as much. File System auditing reports `No Auditing`, so
the route that does not depend on timestamps is also off until somebody turns it
on. A honeyfile on a Windows share, with nothing configured, is a file that
records nothing when it is opened.

```bash
# macOS 26.5.2, arm64
$ mount | grep -E "on / \(|/System/Volumes/Data \("
/dev/disk3s1s1 on / (apfs, sealed, local, read-only, journaled)
/dev/disk3s5 on /System/Volumes/Data (apfs, local, journaled, nobrowse, root data)

# A honeyfile, with its recorded access time set months into the past
$ printf 'server,user,password\nbackup01,svc_backup,Wint3r2026!\n' > /tmp/passwords_final.csv; touch -a -t 202603140912 /tmp/passwords_final.csv; stat -f '%Sa %N' /tmp/passwords_final.csv
Mar 14 09:12:00 2026 /tmp/passwords_final.csv

# Somebody opens it, and this is what the share shows afterwards
$ cat /tmp/passwords_final.csv > /dev/null; sleep 3; stat -f '%Sa %N' /tmp/passwords_final.csv
Aug 25 18:53:08 2026 /tmp/passwords_final.csv

# The GNU form the Linux column of this topic uses, on this machine
$ ls -l --time=atime /tmp/passwords_final.csv 2>&1 | head -2
ls: unrecognized option `--time=atime'
usage: ls [-@ABCFGHILOPRSTUWXabcdefghiklmnopqrstuvwxy1%,] [--color=when] [-D format] [file ...]
```

macOS is the opposite case. The access time moved from March to the moment the
file was read, and `mount` lists no atime option at all, because APFS names one
only when it is switched off. **The technique is more reliable here than on
Linux**, since there is no `relatime` behaviour discarding the second read of the
day.

What does not survive the trip is every command. The last line is the exact
instruction the Linux column gives, and it returns `ls: unrecognized option
'--time=atime'`, because these are BSD tools rather than GNU ones. `stat -c`,
`touch -d` and `findmnt` fail the same way, which is the same shape as the
LibreSSL finding in topic 09: the concept transfers and the syntax does not.

**So the honest summary is that the cheapest implementation is cheapest on
exactly one of the three platforms, unavailable on another, and best on the
third.** That is worth knowing before deploying a honeyfile on a share that
Windows clients write to, because the control would be sitting there recording
nothing and nobody would find out until it failed to alert.

## Prove it

**Work it out.** Take the figure's numbers and change one. If the share sees a
hundred thousand file opens a week instead of ten thousand, and the rule still
flags one percent, how many alerts arrive and how many are worth reading? Then ask
what happens to the honeyfile's number. One of the two scales with the size of the
organisation and the other does not, and that is the argument.

**Work it out again.** A detection is ninety-nine percent accurate and there is one
attack in ten thousand events. How many alerts does it produce and what proportion
are real? Then try it at 99.9 percent. The second number is the one that changes
how you think about tuning.

**Look it up.** NIST SP 800-53 Rev. 5 contains a control for deception, and one
for a decoy environment. Find them and answer one question: what does the
catalogue say about what an organisation has to do alongside deploying them? The
answer is the commitment the deeper panel above describes, stated by somebody
other than me.

## What trips people up

### 1. Judging a detection by its accuracy alone

A ninety-nine percent accurate rule against a rare event produces mostly false
positives. What decides an alert's worth is how much normal activity resembles it,
not how good the logic is.

### 2. Treating the four as sizes of one thing

Two of them are machines to run and two are bait to plant. The cost, the risk and
the deployment effort differ by orders of magnitude across that line.

### 3. Putting a honeypot on the internet and calling it detection

Everything on the public internet is scanned constantly, so the signal is close to
meaningless there. The same honeypot inside the network, where nothing should be
touching it, is a strong signal.

### 4. Running a high-interaction honeypot without containment

It is a deliberately vulnerable machine on your network. Unwatched and
uncontained, it is a compromised host you built on purpose, and a machine of
yours attacking somebody else is your problem regardless of intent.

### 5. Depending on access times

`relatime` records only the first read in a day and `noatime` records nothing.
The technique is sound and the cheapest implementation of it is not reliable.

### 6. Forgetting to tell your own people

Every one of these produces its value from having no legitimate traffic. A
colleague who opens the honeyfile out of curiosity has generated the false
positive the control existed to avoid.

## Work it through

A company suspects that data from its customer database is being copied, and has
no idea by whom or how.

**First, notice what the ordinary detections cannot do here.** A content
inspection rule on the network sees data leaving and cannot distinguish a copy
from any of the legitimate exports that happen daily. Access logging on the
database says who queried it, which is everybody with a job. Neither answers the
question, because the base rate of normal activity is enormous.

**Then reject the honeypot.** A decoy database would tell them if somebody was
poking around the network looking for one. The suspicion is that a person with
legitimate access is copying real data, and that person has no reason to go near a
decoy. Wrong control for the direction of the threat.

**Then reach for the honeytoken, because the data is what is moving.** Add
fabricated customer records, each with a contact address that belongs to the
company and is used for nothing else. If a copy of the database leaves, the
address goes with it, and anybody who contacts it has a copy.

**Then use the property that makes it powerful.** Give each department, or each
third party who receives an extract, a different set of fabricated records. Now the
alert does not only say the data left. It says which copy it came from, which is
attribution, and no other control on this exam provides it.

**Then say what it does not cover.** It reports when somebody uses the data, which
may be months later or never. It is not prevention, it is not fast, and if the
copy is taken and never used the token stays silent. That is a real limitation and
it is not a reason to skip it, because the alternative on offer was nothing.

The decision, written the way it should be written down: seeded honeytokens with
per-recipient variation, accepted as a slow detective control with no preventive
value. The rejected options are content inspection, whose base rate makes it
useless here, and a decoy database, which faces the wrong direction. The residual
is that a copy nobody ever uses is never detected.

## Try it

**Plant one honeytoken you can watch.** An email address at a domain you control,
used for exactly one purpose and nothing else. Anything that arrives at it later
tells you where that address travelled. This is a five-minute version of the
technique and it works.

**Check whether access times would work where you are.** One command tells you,
and it is a different command on each platform: `findmnt -no OPTIONS /` on Linux,
`fsutil behavior query disablelastaccess` on Windows, `mount` on macOS. The answer
decides whether the cheapest honeyfile implementation is available to you at all,
and on a Windows machine it usually is not.

**Count the alerts somebody near you actually reads.** Ask what proportion of the
alerts arriving in a week get investigated. The answer is the base rate problem
measured in your own organisation, and it is usually the thing that makes this
topic land.

## Check yourself

<details class="qa">
<summary>Why does an alert from a honeyfile carry more weight than an alert from a content inspection rule?</summary>

Because there is no legitimate traffic where it sits. A content rule has to
distinguish an attack from thousands of normal file opens and will flag some of
them; a file nobody has any reason to open produces no alerts at all until
somebody opens it.

The advantage is the position rather than the technology. A detector placed where
the base rate of normal activity is zero cannot generate a false positive, and that
is not something a better rule can achieve.

</details>

<details class="qa">
<summary>A detection is ninety-nine percent accurate with a one percent false positive rate, applied to ten thousand events containing one attack. How many alerts, and how many matter?</summary>

About a hundred and one alerts, of which one matters. The rule correctly flags the
attack, and one percent of the 9,999 normal events is roughly a hundred more.

That is the base rate fallacy, and the uncomfortable part is that the rule is
genuinely good. Improving it to 99.9 percent leaves ten false positives against
the one real, which is still ten times more noise than signal. Reducing how much
normal activity the rule sees does more than improving the rule.

</details>

<details class="qa">
<summary>What separates a honeypot and a honeynet from a honeyfile and a honeytoken?</summary>

The first two are machines and the second two are not. A honeypot is a host that
exists to be attacked and a honeynet is several of them with their own network,
so both have to be patched, monitored and isolated, and both carry the risk that
something built to be attacked is successfully attacked and then used against
somebody else.

A honeyfile is a file on a share that already exists and a honeytoken is a record.
Their cost is almost entirely organisational: telling your own staff to leave them
alone, and remembering they exist.

</details>

<details class="qa">
<summary>What can a honeytoken tell you that a honeypot cannot?</summary>

Where the data went after it left. A honeypot detects somebody on your network,
which requires them to be somewhere you can observe. A honeytoken is part of the
data, so it reports from wherever a copy ends up, including systems you have no
access to.

Giving each recipient a different set of fabricated records adds attribution: the
alert says not only that the data leaked but which copy it came from, and nothing
else on this exam provides that.

</details>

<details class="qa">
<summary>Why is a honeypot on the public internet a weaker signal than the same honeypot inside the network?</summary>

Because everything on the public internet is scanned continuously, so being probed
there is the normal state and carries almost no information.

Inside the network nothing has a legitimate reason to touch it, so the base rate
of normal activity returns to zero and the same box becomes a strong signal. It is
the same principle as the honeyfile: the value comes from where it is placed
rather than from what it is.

</details>

## References

- [NIST SP 800-53 Rev. 5](https://csrc.nist.gov/pubs/sp/800/53/r5/upd1/final) - NIST, the control catalogue, which includes controls for deception and for decoy environments and states what deploying them commits an organisation to. Free. Accessed 2026-08-25.
- [NIST SP 800-94](https://csrc.nist.gov/pubs/sp/800/94/final) - NIST, intrusion detection and prevention, for the false positive and false negative trade this topic's arithmetic rests on. Free. Accessed 2026-08-25.
- [mount(8)](https://man7.org/linux/man-pages/man8/mount.8.html) - Linux man-pages project, and the definition of `relatime` that decides whether the captured technique records anything. Free. Accessed 2026-08-25.

**Where the numbers came from.** The capture is real, on AlmaLinux 10.2 x86_64
pinned by digest, and the access time and the `relatime` mount option are what
that container reported. The credentials in the file are fabricated and
authenticate nothing. The arithmetic in the figure is a worked example with its
inputs stated rather than a measurement of any organisation: ten thousand file
opens, a rule flagging one percent, and one real incident. Change the inputs and
the conclusion moves, which is the point of showing them.

**If you also work on Linux.** The Linux+ track's
[logging and auditing](/learn/linux-plus/logging-and-auditing) topic covers the
tooling that watches a file properly rather than depending on a timestamp, and
[monitoring concepts](/learn/linux-plus/monitoring-concepts) covers alert
thresholds and the fatigue this topic's arithmetic produces.
