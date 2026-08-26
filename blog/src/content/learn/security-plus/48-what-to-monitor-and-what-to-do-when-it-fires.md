---
title: "What to monitor, and what to do when it fires"
description: "Four places an alert can be silenced before anybody sees it, what one idle machine actually logs in a day, why alert fatigue is a design failure rather than a staffing one, and what a tuned-out rule costs when it was the only true positive."
deck: "The alert fired four hundred times last month. Somebody wrote a rule to hide it"
track: "security-plus"
level: "working"
order: 490
objectives:
  - "Name the stages between an event happening and a person acting on it"
  - "Say what each stage's failure mode silences, and why three of them are invisible"
  - "Read real log volume figures and say what they imply for a detection strategy"
  - "Describe the alert response steps and what validation and quarantine each mean"
  - "Explain why alert fatigue is a design problem"
  - "Decide what to archive and for how long, and say what drives the answer"
prerequisites: ["secure-baselines"]
tags: ["security-plus", "security", "operations", "monitoring"]
updated: 2026-08-25
draft: false
examObjectives:
  - exam: "sy0-701"
    domain: "4.0"
    objective: "4.4"
sources:
  - title: "SP 800-92, Guide to Computer Security Log Management"
    url: "https://csrc.nist.gov/pubs/sp/800/92/final"
    publisher: "NIST"
    accessed: 2026-08-25
    tier: 1
  - title: "SP 800-137, Information Security Continuous Monitoring for Federal Information Systems and Organizations"
    url: "https://csrc.nist.gov/pubs/sp/800/137/final"
    publisher: "NIST"
    accessed: 2026-08-25
    tier: 1
  - title: "journalctl manual page"
    url: "https://www.freedesktop.org/software/systemd/man/latest/journalctl.html"
    publisher: "systemd project"
    accessed: 2026-08-25
    tier: 1
  - title: "Get-WinEvent reference"
    url: "https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.diagnostics/get-winevent"
    publisher: "Microsoft"
    accessed: 2026-08-25
    tier: 1
  - title: "Viewing log messages, log command"
    url: "https://developer.apple.com/documentation/os/viewing-log-messages"
    publisher: "Apple"
    accessed: 2026-08-25
    tier: 1
symptoms:
  - symptom: "An incident happened and nothing alerted"
    anchor: "four-silences-and-only-one-of-them-leaves-a-record"
  - symptom: "The team stopped reading a category of alert"
    anchor: "alert-fatigue-is-a-design-failure"
---

> **Before you read.** An alert fired four hundred times last month. Every one was
> investigated and every one was nothing. Somebody wrote a suppression rule for
> it, and the noise stopped.
>
> **What did the organisation just lose, and how would anybody find out?**

Suppressing a rule with a four hundred to zero record is a defensible engineering
decision and it is also the last step of a process that has already failed
somewhere. The interesting question is where.

### Some words you will need

<dl class="terms">
<dt>log</dt>
<dd>A record something wrote about what it did. Written whether or not anybody collects it.</dd>
<dt>aggregation</dt>
<dd>Bringing logs from many sources into one place so they can be searched together.</dd>
<dt>alert</dt>
<dd>A rule matching, and a person being told. Two separate things, and the second one is the expensive half.</dd>
<dt>tuning</dt>
<dd>Changing a rule so it fires less. Sometimes removing noise, sometimes removing detection.</dd>
<dt>alert fatigue</dt>
<dd>What happens to a person who has been wrong four hundred times in a row.</dd>
<dt>quarantine</dt>
<dd>Isolating something suspected rather than removing it, so it can be examined.</dd>
<dt>validation</dt>
<dd>Confirming the alert described something real, before acting on it.</dd>
<dt>archiving</dt>
<dd>Keeping logs after they stop being useful for alerting, because an investigation may need them.</dd>
</dl>

## What breaks without this

**An incident happens and nothing fires.** The team concludes their detection is
good, because there were no alerts, which is the same output as having no
detection at all.

**Everything fires and nobody reads it.** The rules are correct, the volume is
unmanageable, and the practical detection rate is zero.

**A rule is tuned out along with the one true positive it would have caught.**
The suppression is invisible afterwards, because a suppressed alert leaves no
trace of what it would have said.

**The logs needed for an investigation expired last week.** The retention was set
by whoever sized the storage, and nobody asked how far back an investigation
typically has to look.

## Four silences, and only one of them leaves a record

Between something happening and a person doing something about it, there are five
stages, and each boundary can swallow the alert.

<figure class="learn-figure">
<svg viewBox="0 0 720 300" role="img" aria-labelledby="fun-title" style="width:100%;height:auto;">
<title id="fun-title">Five stages between an event happening and a person acting on it, with the specific way each stage can silence the alert and what that silence hides</title>
<g fill="currentColor">
<text x="14" y="20" font-size="11">five stages, and four separate ways an alert never reaches anybody</text>
<rect x="20" y="60" width="128" height="96" rx="4" fill="var(--accent)" fill-opacity="0.13" stroke="var(--accent)" stroke-width="1.4"/>
<text x="84" y="112" text-anchor="middle" font-size="8.5">the thing happens</text>
<path d="M 149 108 H 155" stroke="currentColor" stroke-opacity="0.5" stroke-width="1.2"/>
<path d="M 88 168 V 188" stroke="var(--red)" stroke-opacity="0.5" stroke-width="1.1" stroke-dasharray="3 3"/>
<rect x="18" y="192" width="140" height="42" rx="4" fill="var(--red)" fill-opacity="0.09" stroke="var(--red)" stroke-opacity="0.55" stroke-width="1.2" stroke-dasharray="4 3"/>
<text x="88" y="208" text-anchor="middle" font-size="7.5" fill-opacity="0.95">nothing records it</text>
<text x="88" y="221" text-anchor="middle" font-size="7" fill-opacity="0.8">auditing was never on</text>
<rect x="156" y="69" width="128" height="78" rx="4" fill="var(--accent)" fill-opacity="0.13" stroke="var(--accent)" stroke-width="1.4"/>
<text x="220" y="112" text-anchor="middle" font-size="8.5">it is logged</text>
<path d="M 285 108 H 291" stroke="currentColor" stroke-opacity="0.5" stroke-width="1.2"/>
<path d="M 224 168 V 188" stroke="var(--red)" stroke-opacity="0.5" stroke-width="1.1" stroke-dasharray="3 3"/>
<rect x="154" y="192" width="140" height="42" rx="4" fill="var(--red)" fill-opacity="0.09" stroke="var(--red)" stroke-opacity="0.55" stroke-width="1.2" stroke-dasharray="4 3"/>
<text x="224" y="208" text-anchor="middle" font-size="7.5" fill-opacity="0.95">the log rolls</text>
<text x="224" y="221" text-anchor="middle" font-size="7" fill-opacity="0.8">a 20 MB cap, 14,399 records</text>
<rect x="292" y="79" width="128" height="58" rx="4" fill="var(--accent)" fill-opacity="0.13" stroke="var(--accent)" stroke-width="1.4"/>
<text x="356" y="112" text-anchor="middle" font-size="8.5">it is collected</text>
<path d="M 421 108 H 427" stroke="currentColor" stroke-opacity="0.5" stroke-width="1.2"/>
<path d="M 360 168 V 188" stroke="var(--red)" stroke-opacity="0.5" stroke-width="1.1" stroke-dasharray="3 3"/>
<rect x="290" y="192" width="140" height="42" rx="4" fill="var(--red)" fill-opacity="0.09" stroke="var(--red)" stroke-opacity="0.55" stroke-width="1.2" stroke-dasharray="4 3"/>
<text x="360" y="208" text-anchor="middle" font-size="7.5" fill-opacity="0.95">nothing forwards it</text>
<text x="360" y="221" text-anchor="middle" font-size="7" fill-opacity="0.8">the source was not onboarded</text>
<rect x="428" y="90" width="128" height="36" rx="4" fill="var(--accent)" fill-opacity="0.13" stroke="var(--accent)" stroke-width="1.4"/>
<text x="492" y="112" text-anchor="middle" font-size="8.5">a rule matches it</text>
<path d="M 557 108 H 563" stroke="currentColor" stroke-opacity="0.5" stroke-width="1.2"/>
<path d="M 496 168 V 188" stroke="var(--red)" stroke-opacity="0.5" stroke-width="1.1" stroke-dasharray="3 3"/>
<rect x="426" y="192" width="140" height="42" rx="4" fill="var(--red)" fill-opacity="0.09" stroke="var(--red)" stroke-opacity="0.55" stroke-width="1.2" stroke-dasharray="4 3"/>
<text x="496" y="208" text-anchor="middle" font-size="7.5" fill-opacity="0.95">no rule exists</text>
<text x="496" y="221" text-anchor="middle" font-size="7" fill-opacity="0.8">nobody wrote a detection</text>
<rect x="564" y="99" width="128" height="18" rx="4" fill="var(--accent)" fill-opacity="0.13" stroke="var(--accent)" stroke-width="1.4"/>
<text x="628" y="112" text-anchor="middle" font-size="8.5">a person sees it</text>
<text x="14" y="262" font-size="10" fill-opacity="0.85">only the last one leaves a trace that somebody decided something</text>
<text x="14" y="282" font-size="10" fill-opacity="0.85">the first three are silent, and look identical to nothing having happened</text>
</g></svg>
<figcaption>Only the last of these four failures is visible afterwards. A suppression rule is a written artefact somebody can find and question. The other three leave the same evidence as an uneventful night: an audit subcategory that was never enabled records nothing, a log that rolled at its size cap discards its oldest entries without comment, and a source nobody onboarded is simply absent from the console. That asymmetry is why an empty alert queue is not information on its own, and why a detection programme is measured by what it can prove it would catch rather than by how quiet it is.</figcaption>
</figure>

**The thing happens and nothing records it.** Audit categories are individually
switchable on every platform, and the defaults are not chosen with your threat
model in mind. This is the deepest silence because no amount of downstream tooling
recovers it.

**It is logged and the log rolls.** Every log has a size or age cap. When the cap
is reached the oldest entries go, silently, and a burst of activity is exactly the
condition that accelerates it.

**It is collected nowhere.** A source that was never onboarded to the aggregator
is invisible to every rule ever written, and the usual reason is that nobody knew
the source existed, which is the asset inventory again.

**A rule fires and somebody silences it.** The visible one. It is a decision with
an author and a date, which makes it the only one of the four you can audit.

<details class="predict">
<summary>One virtual machine, idle, doing nothing anybody would call work. Predict how many log lines it writes in a day.</summary>

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ echo "how much this machine logged, and how much of it is worth reading:"; journalctl --no-pager -q --since "-24h" 2>/dev/null | wc -l; for p in 0 1 2 3 4 5 6; do printf "priority %s: %s\n" "$p" "$(journalctl --no-pager -q -p $p..$p --since "-24h" 2>/dev/null | wc -l)"; done
how much this machine logged, and how much of it is worth reading:
13113
priority 0: 0
priority 1: 0
priority 2: 0
priority 3: 41
priority 4: 36
priority 5: 83
priority 6: 7130
```

**Thirteen thousand lines**, on one machine, in a day, with nobody using it.

The priority breakdown is the part worth sitting with. Nothing at all in the top
three severities. Forty-one at error, thirty-six at warning, and seven thousand
one hundred and thirty at informational.

Multiply by an estate. Two hundred machines at this rate is two and a half million
lines a day, of which around eight thousand are errors. Nobody is reading eight
thousand of anything, so a detection strategy that consists of watching the error
lines has already failed on arithmetic before anybody writes a rule.

That is what makes this a design problem. The volume is not a consequence of
carelessness or of a badly behaved application. It is what a working machine does,
and any approach that assumes a human somewhere is looking at the output has to
survive that number.

</details>

And the forty-one error lines are worth looking at rather than assuming.

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ echo "authentication records in the last 24 hours:"; journalctl --no-pager -q --since "-24h" _COMM=sshd 2>/dev/null | wc -l; journalctl --no-pager -q --since "-24h" 2>/dev/null | grep -ciE "authentication failure|Failed password|invalid user"; echo; echo "what one machine at priority 3 or worse actually says:"; journalctl --no-pager -q -p 3 --since "-24h" -o cat 2>/dev/null | sed "s/[0-9a-f]\{8\}-[0-9a-f-]\{27\}/UUID/g" | sort | uniq -c | sort -rn | head -6
authentication records in the last 24 hours:
0
0

what one machine at priority 3 or worse actually says:
     25 
     12 EXT4-fs (loop0): VFS: Can't find ext4 filesystem
      5 head: cannot open '/srv/finance/payroll.csv' for reading: Permission denied
      4 umount: /mnt/d: not mounted.
      4 mount: /mnt/d: wrong fs type, bad option, bad superblock on /dev/loop0, missing codepage or helper program, or other error.
      4 FAT-fs (loop0): bogus number of reserved sectors
```

**Every one of those errors has an ordinary explanation.** Somebody was
provisioning loop devices and formatting them, so the kernel complained about
filesystems that were not there yet. A command hit a permissions boundary on a
file it was not supposed to read, which is a permission check working. None of
this is an incident and all of it is at error priority.

There are also zero authentication records of any kind, which is the other half of
the lesson: the category a security team most wants is not necessarily present at
all on a given machine, and its absence looks exactly like a quiet day.

<details class="deeper">
<summary>If you tune rules: what tuning removes, and the question to ask before suppressing anything</summary>

Tuning is necessary and it is the operation with the worst ratio of visible effect
to invisible consequence in this whole discipline.

Start from what a suppression actually does. It does not make the events stop. It
makes them stop arriving in a queue somebody reads. The activity continues, the
logs still contain it, and the organisation's ability to notice it has gone from
poor to zero. That trade is often correct, and it should be made deliberately
rather than as an act of housekeeping.

The question worth asking before suppressing is narrow and answerable: what would
a true positive of this rule look like, and would this suppression hide it? Most
noisy rules are noisy because they match a broad condition, and most suppressions
are written against a property of the noise rather than a property of the
condition. Suppressing "alerts from this host" hides everything from that host.
Suppressing "this specific process doing this specific thing on this host" hides
the noise and keeps the rest.

The four hundred to zero record from the top of this page is worth reading
carefully too. Four hundred investigated and none real is evidence about the rule
and it is also four hundred occasions on which somebody practised the
investigation, and got progressively faster at concluding nothing. That is the
mechanism of alert fatigue: the skill being trained is dismissal.

Two habits that help. Give every suppression an expiry, for the same reason an
exception has one, so the estate is re-examined rather than permanently narrowed.
And record on the suppression what it would have taken for this alert to be real,
so the next person can tell whether the condition still holds.

</details>

## Alert fatigue is a design failure

The usual framing is that the team is overwhelmed and needs more people. The
arithmetic above says otherwise: no plausible number of people reads eight
thousand error lines a day, so the problem is not staffing, and hiring against it
produces a larger team dismissing alerts faster.

**What produces a workable queue is a smaller one, and the reduction has to happen
before the human.** Three mechanisms do that and they are worth separating,
because organisations usually try the last one first.

**Fewer sources, chosen deliberately.** Collecting everything is a storage
decision that gets treated as a detection decision. A rule can only match what is
collected, and a source with no rule against it is cost rather than coverage.

**Correlation before alerting.** One failed login is nothing. Forty failed logins
against forty different accounts from one source in a minute is one alert. The
rule that emits the second rather than the first is the difference between a
queue and a stream.

**Enrichment before the human.** An alert that arrives with the asset owner, the
machine's role, and whether the account is privileged can be triaged in seconds.
The same alert as a raw log line takes ten minutes of lookups, and the lookups are
what the analyst actually spends the day doing.

When an alert does reach somebody, the objective names what follows and the order
matters.

**Validate first.** Confirm the alert describes something real before acting,
because acting on a false positive has its own costs and the most common one is
taking a production system away from somebody.

**Quarantine rather than remove.** Isolating a machine preserves the evidence and
stops the spread. Wiping and rebuilding does the second and destroys the first,
which is a decision to prioritise recovery over understanding and should be made
knowingly.

**Then remediate**, which is the same set of choices as the vulnerability topic:
fix it, reduce what it can reach, or accept it with a record.
<details class="predict">
<summary>A team investigates an alert four hundred times in a month and none is real. Besides the wasted time, what has the organisation been training?</summary>

**Dismissal.** Four hundred repetitions of reaching the same conclusion, each one
slightly faster than the last, is deliberate practice at deciding an alert is
nothing.

That is the mechanism of alert fatigue and it is worth stating this way because
the usual framing makes it sound like tiredness. It is not fatigue in the sense of
being worn out. It is a learned prior, built from evidence, and the evidence is
correct: for this rule, on this estate, the answer really has been nothing four
hundred times running.

What follows is that the four hundred and first is not evaluated the way the first
was. The analyst is not being careless; they are applying a base rate they have
personally measured. Any process that depends on somebody treating each instance
as novel is fighting arithmetic and will lose.

It also means the suppression that eventually gets written is the visible end of a
failure that started much earlier, when a rule with a two percent hit rate was put
in front of a person instead of in front of a correlation engine. Suppressing it
is the right decision at that point. The wrong decision was upstream and nobody
recorded making it.

The uncomfortable corollary, worth carrying into any conversation about analyst
performance: a queue that trains dismissal will produce analysts who dismiss, and
replacing the analysts does not change what the queue teaches.

</details>

<details class="deeper">
<summary>If you respond to alerts: why containment comes before understanding, and the case where it does not</summary>

The order in the objective is validate, then quarantine, then remediate, and the
middle step is the one with a real argument inside it.

Quarantine isolates a machine while leaving it running. Network access is cut or
narrowed, the machine stays powered, memory stays populated, and processes keep
their state. That preserves almost everything an investigation would want while
stopping the spread, which is why it is the default answer.

The alternative people reach for under pressure is to power the machine off, and
it is worth being precise about what that costs. Memory contents go, which
includes running processes, network connections, decryption keys held in RAM and
anything that existed only in memory. Malware that never touched disk leaves no
trace at all. A powered-off machine is safe and mostly mute.

So the case for pulling the plug has to be specific: active encryption of data in
progress, active exfiltration you cannot cut at the network, or a machine whose
continued operation is itself the harm. Those are real and they are narrower than
the instinct.

There is also a case where quarantine is the wrong first move, and it is worth
knowing because it inverts the advice. If the alert is one you have not validated
and the machine is doing something a business depends on, isolating it is an
outage you caused on the strength of a rule with a two percent hit rate.
Validation first is not bureaucratic ordering; it is what stops the response
becoming the incident.

The practical version: know in advance which machines you are permitted to isolate
without asking, and which need a phone call. Deciding that during the incident is
how thirty minutes gets spent finding out who owns a server.

</details>


## What to archive, and for how long

Archiving is a separate question from alerting and it gets answered by whoever
sized the disk.

The number that should drive it is how long an intrusion typically goes unnoticed
before something reveals it. If that period is longer than your retention, then at
the moment you most need to look back, the records of the beginning are gone.
Detection time is the input, storage is the constraint, and most organisations set
the second without measuring the first.

The practical shape most places land on is a hot tier of days to weeks, searchable
and expensive, and a cold tier of months to years, cheap and slow. What matters is
that the cold tier is actually retrievable, which is worth testing, because an
archive nobody has ever restored from is a belief rather than a control.
<details class="deeper">
<summary>If you own retention: how to work out the number, and why the archive is usually a belief</summary>

Retention gets set from disk size because that is the number somebody has. The
number you want is how long an intrusion sits undetected before something reveals
it, and while your own organisation probably has not measured it, published
incident reporting consistently puts it in weeks to months rather than days.

Work it from the other end and the arithmetic is uncomfortable. If a compromise
typically starts weeks before anybody notices, thirty days of searchable logs
means that at the moment an investigation opens, the records of the initial access
are already gone. You can describe what the attacker did last week and not how
they got in, which is precisely the question that decides whether it happens
again.

The usual answer is tiering: a hot tier that is searchable and expensive, and a
cold tier that is cheap and slow. That works, and it introduces the failure this
panel is really about, which is that the cold tier is frequently untested.

An archive nobody has restored from is a belief. The specific things that go wrong
are dull and complete: the retention policy on the object store expired the data
earlier than the documented period, the format needs a tool nobody has installed
any more, the encryption key was rotated and the old one was not kept, or the
restore works and takes eleven days. Every one of those is discovered during an
incident by somebody who assumed otherwise.

The cheap fix is a scheduled restore test, quarterly, of something older than the
hot tier, timed. It costs an hour and converts the archive from an assumption into
a measured capability with a known latency. Whether that latency is acceptable is
then a conversation somebody can actually have.

</details>


## Across platforms

The same question, asked of three machines, returns numbers three orders of
magnitude apart.

| Task | Linux | Windows | macOS |
| --- | --- | --- | --- |
| Read the log | `journalctl` | `Get-WinEvent` | `log show` |
| How it is organised | one journal, priority 0 to 7 | many separate logs, per level | one unified log, message types |
| Volume in 24 hours here | 13,113 lines | 382 events across System and Application | over 17 million, extrapolated from one hour |
| What limits retention | journal size cap | per-log size cap, 20 MB by default here | disk, and most of it is never written |

```powershell
# Microsoft Windows Server 2025 Datacenter, version 10.0.26100.0
> (Get-WinEvent -ListLog * -ErrorAction SilentlyContinue | Where-Object { $_.RecordCount -gt 0 } | Measure-Object).Count
122

# The four that matter, with how much each holds
> Get-WinEvent -ListLog Security, System, Application, 'Microsoft-Windows-Windows Defender/Operational' -ErrorAction SilentlyContinue | Select-Object LogName, RecordCount, @{n='MaxMB';e={[int]($_.MaximumSizeInBytes/1MB)}} | Format-Table -AutoSize
LogName                                        RecordCount MaxMB
-------                                        ----------- -----
Security                                             14399    20
System                                                1096    20
Application                                            154    20
Microsoft-Windows-Windows Defender/Operational         576    16

# Everything in the last 24 hours, and how much of it is an error or worse
> $since = (Get-Date).AddDays(-1); $all = Get-WinEvent -FilterHashtable @{LogName='System','Application'; StartTime=$since} -ErrorAction SilentlyContinue; "total: $($all.Count)"; $all | Group-Object LevelDisplayName | Sort-Object Count -Descending | Select-Object Count, Name | Format-Table -AutoSize
total: 382
Count Name
----- ----
  365 Information
   12 Error
    5 Warning

# Whether the log that records logons is even switched on
> auditpol /get /subcategory:"Logon" 2>&1 | Select-String -Pattern 'Logon' | Select-Object -Last 1 | ForEach-Object { $_.Line.Trim() }
Logon                                   Success and Failure
```

**One hundred and twenty-two separate logs with records in them, and the second
command names four.** That is the structural difference from a single journal and
it is a real operational hazard: a rule written against System and Application
does not see the other hundred and eighteen, and the one somebody forgot is
usually a product-specific operational log where the interesting thing was.

The Security log is the number to sit with. Fourteen thousand three hundred and
ninety-nine records, capped at twenty megabytes. That cap is a default, it is
small, and on a busy domain-joined machine it can hold hours rather than days. The
second silence from the figure above is not hypothetical here, it is the
out-of-the-box configuration.

```bash
# macOS 26.5.2, arm64
$ log show --last 1h --style compact 2>/dev/null | wc -l | tr -d ' '; log show --last 1h --predicate 'messageType == 16 OR messageType == 17' --style compact 2>/dev/null | wc -l | tr -d ' '
719753
62710

# What is actually kept on disk, which is a different question from what was emitted
$ sudo du -sh /var/db/diagnostics 2>/dev/null; sudo du -sh /private/var/log 2>/dev/null
178M	/var/db/diagnostics
 17M	/private/var/log

# The authentication records, which is the subset a security team wants
$ log show --last 24h --predicate 'process == "sshd" OR eventMessage CONTAINS "authentication"' --style compact 2>/dev/null | wc -l | tr -d ' '
171

# Whether anything is configured to send these somewhere else
$ ls /etc/newsyslog.d/ 2>/dev/null | head -4; grep -c . /etc/syslog.conf 2>/dev/null || echo "no syslog.conf"
com.apple.slapconfig.conf
com.apple.slapd.conf
com.apple.xscertd.conf
files.conf
2
```

**Seven hundred and nineteen thousand lines in one hour**, of which sixty-two
thousand are typed as error or fault. Extrapolated over a day that is roughly
seventeen million lines from a single idle machine, against thirteen thousand on
the Linux one and three hundred and eighty-two on Windows.

Those numbers are not measuring the same thing and the difference is the lesson.
The unified log records events at a granularity closer to tracing than to logging,
most of it is held in memory and never written to disk, and `messageType` 16 and
17 mean error and fault in a sense far broader than a security team means them.
Sixty-two thousand errors an hour on a machine with nothing wrong with it is a
definitional statement rather than an alarming one.

The practical consequence is that a detection strategy cannot be ported between
these platforms by translating commands. A rule that alerts on error-level events
is workable on Windows, questionable on Linux, and meaningless on macOS. What
transfers is the question, which is which specific events you have decided matter,
and that has to be answered per platform against what each one actually emits.

The last two commands make the third silence concrete. There are 171
authentication-related records in a day, which is the subset anybody would
actually want, and `/etc/syslog.conf` has two non-empty lines, meaning nothing on
this machine is shipping any of it anywhere. Everything above is local, and local
logs are lost with the machine.

## Prove it

**Run it.** `journalctl --since "-24h" | wc -l` on any Linux machine you have.
Then the same by priority. The number will be larger than you expect and the
distribution will be more lopsided.

**Work it out.** Take your own estate's machine count and multiply by the line
count you just measured. Then decide how many of those a person could read in a
day, and what that implies about where filtering has to happen.

**Look it up.** Open SP 800-92 and find what it says about log retention periods
and how to choose one. The input it names is not storage capacity, and the
difference between its answer and how retention actually gets set is worth
noticing.

## What trips people up

### 1. Reading a quiet queue as good detection

Three of the four silences look identical to nothing having happened. An empty
queue is only meaningful if you can show what the system would catch.

### 2. Treating alert fatigue as a staffing problem

Eight thousand error lines a day across two hundred machines is not readable by
any number of people. The reduction has to happen before the human, which makes
it a design decision.

### 3. Suppressing on a property of the noise

"All alerts from this host" hides everything from that host, including the real
one. Suppress the specific process doing the specific thing, and give the
suppression an expiry.

### 4. Assuming the interesting log is being written

Audit categories are individually switchable and the defaults are not chosen for
you. The Linux machine above recorded zero authentication events of any kind in a
day.

### 5. Comparing log volumes across platforms

Thirteen thousand, three hundred and eighty-two, and seventeen million are not
three measurements of the same thing. Each platform's idea of an event is
different, and a rule that works on one is not portable by translation.

### 6. Setting retention from storage

The number that should drive it is how long an intrusion goes unnoticed. Setting
it from disk size means the records of the beginning are gone at the moment you
need them.

## Work it through

A team of three watches alerts for four hundred machines. The queue runs at about
two hundred a day, roughly two percent are real, and two of the three analysts
have started closing whole categories in bulk.

**The tempting move is to hire.** Two hundred alerts a day across three people is
sixty-six each, and the arithmetic seems to say a fourth analyst fixes it. It does
not, because the ratio does not change: a fourth person dismisses fifty alerts a
day instead of sixty-six, and the two percent that are real are found by the same
process that is currently failing.

**The move that works measures the queue before changing it.** Group last month's
alerts by rule. In almost every queue like this, a small number of rules produce
most of the volume and none of the true positives, and until you have that table
you are guessing about which ones.

**Then act on the table rather than on the queue.** The high-volume, zero-true
rules get correlated instead of suppressed where possible, so forty related events
become one alert rather than forty suppressed ones. The ones that cannot be
correlated get a narrow, dated suppression with the condition written down. What
survives is a queue small enough to be read properly.

**What this rejects is triaging harder.** The current process is not slow, it is
correct and unsurvivable, and the two analysts closing categories in bulk have
already worked that out and are doing the only thing available to them. Treating
that as a discipline problem rather than a design signal is the most common way
this situation gets worse.

The residual is the part to write down. Correlation introduces delay, because the
rule has to wait to see whether more related events arrive. A queue tuned this way
detects a burst well and a slow, patient intrusion less well, and that trade should
be named rather than discovered.

## Try it

**Count your own noise.** `journalctl -p 3 --since "-7d" | wc -l` on one server,
then look at what the lines actually say. The proportion that describe a problem
somebody would act on is the useful number.

**Find out whether logons are recorded.** `auditpol /get /subcategory:"Logon"` on
Windows, or check whether `sshd` records appear in the journal on Linux. Absence
is a configuration state, not a quiet day.

**Check where the log stops.** Look at the maximum size of the Windows Security
log, or `journalctl --disk-usage` on Linux. Divide by the daily rate you just
measured to get the number of days you can actually look back.

**Test the archive.** Restore something from your cold storage that is older than
your hot retention. If nobody has ever done this, the result is worth knowing
before an investigation depends on it.

## Check yourself

<details class="qa">
<summary>Name the four ways an alert can be silenced, and say which one is auditable.</summary>

The event is never recorded, because the audit category was not enabled. It is
recorded and the log rolls before anybody collects it. It is collected nowhere,
because the source was never onboarded. Or a rule fires and somebody suppresses
it.

Only the last is auditable, because a suppression is a written artefact with an
author and a date. The other three produce exactly the same evidence as an
uneventful night, which is why an empty queue proves nothing on its own.

</details>

<details class="qa">
<summary>One idle machine writes 13,113 log lines a day, 41 of them at error priority. What does that imply for a detection strategy?</summary>

That watching error lines does not scale. Two hundred machines at that rate is
around eight thousand errors a day, which no number of analysts reads.

The reduction has to happen before a person sees anything: collect fewer sources
deliberately, correlate related events into single alerts, and enrich alerts with
the context that triage would otherwise require. Adding people leaves the ratio
unchanged.

</details>

<details class="qa">
<summary>Why is suppressing "all alerts from this host" worse than it looks?</summary>

Because it is written against a property of the noise rather than of the
condition. Everything from that host is now invisible, including a genuine
detection.

The narrow form suppresses the specific process doing the specific thing on that
host, which removes the noise and keeps the rest. Either way the suppression
should carry an expiry and a note saying what a true positive would have looked
like.

</details>

<details class="qa">
<summary>macOS logs 719,753 lines an hour and Windows logs 382 events a day. Is macOS worse instrumented?</summary>

No. The two numbers are not measuring the same thing. The unified log records at a
granularity closer to tracing than logging, most of it is never written to disk,
and its error and fault message types are much broader than what a security team
calls an error.

What follows is that a detection strategy does not port between platforms by
translating commands. The question that transfers is which specific events you
decided matter, answered separately against what each platform emits.

</details>

<details class="qa">
<summary>What should drive log retention?</summary>

How long an intrusion typically goes unnoticed before something reveals it. If
retention is shorter than that, the records of the beginning are gone at the exact
moment an investigation needs them.

Storage capacity is the constraint rather than the input, and most organisations
set retention from the constraint without ever measuring the input.

</details>

## References

- [SP 800-92](https://csrc.nist.gov/pubs/sp/800/92/final) - NIST, Guide to Computer Security Log Management, for what to collect, how long to keep it, and what drives that answer. Free. Accessed 2026-08-25.
- [SP 800-137](https://csrc.nist.gov/pubs/sp/800/137/final) - NIST, continuous monitoring, for the programme this topic's mechanics sit inside. Free. Accessed 2026-08-25.
- [journalctl](https://www.freedesktop.org/software/systemd/man/latest/journalctl.html) - systemd project, for the priority levels the first capture counts. Free. Accessed 2026-08-25.
- [Get-WinEvent](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.diagnostics/get-winevent) - Microsoft, for the log structure the Windows capture enumerates. Free. Accessed 2026-08-25.
- [Viewing log messages](https://developer.apple.com/documentation/os/viewing-log-messages) - Apple, for the unified log and what its message types mean. Free. Accessed 2026-08-25.

**Where the content came from.** The two Linux blocks are captured from the
virtual machine this project uses for kernel-level work, which is why the error
lines describe loop devices and filesystem experiments: those are the traces of
ordinary work on that machine, and leaving them in is more honest than choosing a
quieter host. The Windows and macOS blocks are captured from disposable runners.
The seventeen million figure for macOS is an extrapolation from one measured hour
and is described as such rather than presented as a measurement.

**If you also work on Linux.** The Linux+ track's
[logging and auditing](/learn/linux-plus/logging-and-auditing) covers the
mechanics of what writes to the journal and how to query it, and
[reading logs to find a cause](/learn/linux-plus/reading-logs-to-find-a-cause)
covers the investigation this topic's alerts lead into.
