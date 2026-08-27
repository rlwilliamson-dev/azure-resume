---
title: "The nine indicators"
description: "Each of the nine indicators has an innocent explanation, and the job is to rule it out. With one login shown from three record keepers at once, and the one indicator that is an absence rather than an entry."
deck: "The account is locked. Nobody tried to log in"
track: "security-plus"
level: "working"
order: 240
objectives:
  - "Name the nine indicators and give the innocent explanation for each"
  - "Explain what ties records from different log sources into one incident"
  - "Say why missing logs is an indicator and what a gap actually proves"
  - "Explain why impossible travel produces false positives at scale"
  - "Distinguish out-of-cycle logging from unexpected content"
  - "Say what a log's own record of being cleared is worth"
prerequisites: ["password-attacks"]
tags: ["security-plus", "security", "monitoring", "incident-response"]
updated: 2026-08-26
draft: false
examObjectives:
  - exam: "sy0-701"
    domain: "2.0"
    objective: "2.4"
sources:
  - title: "SP 800-92, Guide to Computer Security Log Management"
    url: "https://csrc.nist.gov/pubs/sp/800/92/final"
    publisher: "NIST"
    accessed: 2026-08-26
    tier: 1
  - title: "RFC 5424, The Syslog Protocol"
    url: "https://www.rfc-editor.org/rfc/rfc5424.html"
    publisher: "IETF"
    accessed: 2026-08-26
    tier: 1
  - title: "T1070.001, Indicator Removal: Clear Windows Event Logs"
    url: "https://attack.mitre.org/techniques/T1070/001/"
    publisher: "MITRE"
    accessed: 2026-08-26
    tier: 1
symptoms:
  - symptom: "An account is locked and nobody admits to signing in"
    anchor: "nine-indicators-and-nine-innocent-explanations"
  - symptom: "A period of time has no log entries in it"
    anchor: "the-indicator-that-is-an-absence"
---

> **Before you read.** A user calls to say their account is locked. They have not
> tried to sign in today, they are certain of it, and the lockout policy is five
> failures.
>
> **What do you already know, before you look at anything?**

That five failed attempts happened, and that they came from somewhere the user is
not. Every part of that is useful. The lockout is not the incident; it is the
mechanism reporting that an incident-shaped thing occurred, and the innocent
explanation is sitting right next to the alarming one. A phone with a stale
password retries silently. A scheduled task runs under a person's account and was
never updated. Or somebody is guessing.

That structure repeats through all nine of the indicators in this objective. Each
one is a signal with at least one boring cause, and the work is ruling the boring
cause out rather than reacting to the signal.

### Some words you will need

<dl class="terms">
<dt>indicator</dt>
<dd>An observation consistent with compromise. Not proof of one.</dd>
<dt>impossible travel</dt>
<dd>Two sign-ins too far apart to be the same person in the time between them.</dd>
<dt>out-of-cycle logging</dt>
<dd>A source producing entries at a time it does not normally produce them.</dd>
<dt>concurrent session</dt>
<dd>One identity signed in from more than one place at once.</dd>
<dt>correlation</dt>
<dd>Deciding that records from different sources describe one event.</dd>
<dt>retention</dt>
<dd>How far back a log can answer for, which is usually shorter than people think.</dd>
<dt>rotation</dt>
<dd>Closing a log file and starting a new one, discarding the oldest when space runs out.</dd>
</dl>

## Nine indicators and nine innocent explanations

Learning these as a list of nine names is the wrong shape, because in practice you
meet one of them and have to decide what to do next. What makes that decision
possible is knowing what else produces the same signal.

**Account lockout.** Failures happened against a named account. Also produced by a
stale credential on a device, a service account with an old password in a
configuration file, and a colleague mistyping a shared username.

**Concurrent session usage.** One identity in two places. Also produced by a phone
and a laptop both holding a session, a background sync client, and anything that
keeps a token alive on the user's behalf.

**Blocked content.** Something a filter refused to fetch. Also produced by an
advertisement network on an ordinary page, an over-broad category rule, and
software checking for updates from a domain nobody classified.

**Impossible travel.** Two sign-ins geographically inconsistent with the time
between them. Also produced by a virtual private network, a mobile device changing
carriers, and any service that acts for the user from its own datacentre.

**Resource consumption.** Something is using more than it should. Also produced by
a backup, a report somebody scheduled, a runaway loop and a badly written query.

**Resource inaccessibility.** Something that should respond does not. Also produced
by a full disk, an expired certificate, a change nobody announced, and the
encryption half of a ransomware event, which is why this one gets watched.

**Out-of-cycle logging.** A source producing entries at a time it usually does not.
Also produced by a maintenance window, a time zone confusion, and a batch job that
was rescheduled.

**Published or documented.** Somebody outside tells you, or your data appears
somewhere it should not. There is no innocent explanation for this one and it is
frequently how organisations find out.

**Missing logs.** A period with no entries. Also produced by rotation, a retention
limit, a collector that stopped, and a service that was not running. This is the
one people do not treat as an indicator at all, which is the second half of this
page.

**The pattern worth extracting** is that eight of the nine are ambiguous by
construction, and the ninth arrives from outside. So a monitoring practice built on
reacting to single indicators generates work and not much else. What makes an
indicator useful is a second one that agrees with it.

<details class="deeper">
<summary>Out-of-cycle against unexpected, which are not the same finding</summary>

These two get conflated because both are described as something unusual in the
logs, and they are found by different means and mean different things.

**Out-of-cycle is about timing and needs no understanding of the content.** A
source has a normal rhythm: a batch job that writes at 02:00, a backup that runs on
Sundays, an application that is busy in business hours. Entries appearing outside
that rhythm are out of cycle whether or not anything about them looks wrong.

That is cheap to detect, which is the point. Counting entries per source per hour
and comparing against the same source's own history is arithmetic on volume, and it
requires nobody to write a rule about what the entries say.

**Unexpected is about content and requires knowing what to expect.** A command that
this account has never run, a process spawning something no installation would, a
query returning a thousand times the usual rows. Detecting it means somebody
encoded an expectation, and the detection is only as good as the expectation.

**Where they meet is the useful place.** An administrative action at 03:00 on a
Sunday is out of cycle by timing and unremarkable by content. The same action at
14:00 on a Tuesday is invisible to the timing check and equally unremarkable. It is
the combination that carries information, which is why the systems worth having
score both rather than alerting on either.

**And out-of-cycle has a failure mode worth naming.** A source whose rhythm changes
for a legitimate reason, a rescheduled job or a new region coming online, produces
a wall of out-of-cycle findings until somebody updates the baseline. If nobody owns
that update, the detection is switched off within a fortnight and the reason is
recorded nowhere.

</details>

## What ties three records into one incident

Correlation sounds like a product feature and is really a question about
identifiers: which field appears in records from different sources, and can you
trust it to mean the same thing in each.

<details class="predict">
<summary>One login to one machine. Predict how many separate record keepers wrote something about it, and whether they agree on what to call it.</summary>

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ ses=$(cat /proc/self/sessionid); me=$(id -un)
j() { journalctl --since -15s -o cat --no-pager "$@" 2>/dev/null; }
row() { printf '%-22s %7s   %s\n' "$1" "$2" "$3"; }
printf 'this login: user %s, logind session %s, audit session id %s\n\n' \
  "$me" "$(grep -o 'session-[0-9]*' /proc/self/cgroup | tr -dc 0-9)" "$ses"
row 'record keeper' 'entries' 'a line it wrote about this login'
row 'wtmp, read by last' "$(last -n 40 | grep -c "^$me ")" "$(last -n 40 | grep -m1 "^$me ")"
row 'journal, sshd' "$(j _COMM=sshd-session | grep -c .)" "$(j _COMM=sshd-session | grep -m1 Accepted | cut -c1-38)"
row 'journal, logind' "$(j _COMM=systemd-logind | grep -c .)" "$(j _COMM=systemd-logind | grep -m1 -i 'new session' | cut -c1-38)"
row 'kernel audit' "$(j _TRANSPORT=audit | grep -c "ses=$ses")" "$(j _TRANSPORT=audit | grep -m1 -o "ses=$ses.\{0,30\}")"
this login: user core, logind session 212, audit session id 212

record keeper          entries   a line it wrote about this login
wtmp, read by last           0   
journal, sshd                7   Accepted publickey for core from 192.1
journal, logind              4   New session '211' of user 'core' with 
kernel audit                 8   ses=212 subj=system_u:system_r:sshd_s
```

**Four record keepers were asked. Three wrote something and one wrote nothing.**

The three that recorded it each did so from a different vantage point. The service
that accepted the connection recorded the authentication. The session tracker
recorded that a session began and who it belongs to. The kernel's audit stream
recorded the same login again with the security context attached.

The identifier is in the header line. This login's session number and its audit
session id are the same value, which is what lets a query on one of them collect
records written by the other two. That agreement is a property of how Linux
allocates session identifiers rather than a guarantee, so it is worth confirming on
a system rather than assuming, and the sample lines in the last column come from
whatever else was in the fifteen second window.

**Then the empty row.** `last` reads a file that only records sessions attached to
a terminal, and this login had none, so the file is correct and the login is
absent from it. If your investigation started with `last`, this session did not
happen.

</details>

<figure class="learn-figure">
<svg viewBox="0 0 720 305" role="img" aria-labelledby="lanes-title" style="width:100%;height:auto;">
<title id="lanes-title">One login drawn across four record keepers on a shared fifteen second axis, three of which recorded it and one of which holds nothing</title>
<g fill="currentColor">
<text x="14" y="20" font-size="11">one login, asked of four record keepers, on one time axis</text>
<text x="14" y="42" font-size="9" fill-opacity="0.85">each tick is an entry that record keeper wrote, counted from the capture above</text>
<rect x="200" y="68" width="92" height="130" rx="3" fill="var(--accent)" fill-opacity="0.10" stroke="var(--accent)" stroke-opacity="0.35" stroke-width="1"/>
<text x="246" y="62" font-size="8" text-anchor="middle" fill-opacity="0.75">one login</text>
<text x="14" y="87" font-size="9">journal, from sshd</text>
<rect x="210" y="78" width="3" height="12" fill="var(--accent)"/>
<rect x="220" y="78" width="3" height="12" fill="var(--accent)"/>
<rect x="228" y="78" width="3" height="12" fill="var(--accent)"/>
<rect x="239" y="78" width="3" height="12" fill="var(--accent)"/>
<rect x="248" y="78" width="3" height="12" fill="var(--accent)"/>
<rect x="259" y="78" width="3" height="12" fill="var(--accent)"/>
<rect x="270" y="78" width="3" height="12" fill="var(--accent)"/>
<text x="310" y="87" font-size="9" fill-opacity="0.85">7 entries</text>
<text x="14" y="121" font-size="9">journal, from logind</text>
<rect x="215" y="112" width="3" height="12" fill="var(--accent)"/>
<rect x="231" y="112" width="3" height="12" fill="var(--accent)"/>
<rect x="246" y="112" width="3" height="12" fill="var(--accent)"/>
<rect x="262" y="112" width="3" height="12" fill="var(--accent)"/>
<text x="310" y="121" font-size="9" fill-opacity="0.85">4 entries</text>
<text x="14" y="155" font-size="9">kernel audit stream</text>
<rect x="206" y="146" width="3" height="12" fill="var(--accent)"/>
<rect x="216" y="146" width="3" height="12" fill="var(--accent)"/>
<rect x="226" y="146" width="3" height="12" fill="var(--accent)"/>
<rect x="237" y="146" width="3" height="12" fill="var(--accent)"/>
<rect x="248" y="146" width="3" height="12" fill="var(--accent)"/>
<rect x="259" y="146" width="3" height="12" fill="var(--accent)"/>
<rect x="270" y="146" width="3" height="12" fill="var(--accent)"/>
<rect x="281" y="146" width="3" height="12" fill="var(--accent)"/>
<text x="310" y="155" font-size="9" fill-opacity="0.85">8 entries</text>
<text x="14" y="189" font-size="9">wtmp, read by last</text>
<text x="310" y="189" font-size="9" fill="var(--red)" fill-opacity="0.9">no entry at all</text>
<line x1="170" y1="212" x2="690" y2="212" stroke="currentColor" stroke-opacity="0.4" stroke-width="1"/>
<text x="170" y="228" font-size="8" text-anchor="middle" fill-opacity="0.7">0s</text>
<text x="343" y="228" font-size="8" text-anchor="middle" fill-opacity="0.7">5s</text>
<text x="516" y="228" font-size="8" text-anchor="middle" fill-opacity="0.7">10s</text>
<text x="686" y="228" font-size="8" text-anchor="middle" fill-opacity="0.7">15s</text>
<text x="14" y="256" font-size="10">every entry in the three occupied lanes carries the same session identifier</text>
<text x="14" y="276" font-size="9" fill-opacity="0.8">which is what makes them one incident rather than three unrelated bursts of logging</text>
<text x="14" y="298" font-size="9" fill-opacity="0.7">the empty lane is not evidence that nothing happened: it records only sessions that had a terminal</text>
</g></svg>
<figcaption>The counts come from the capture above, placed on the fifteen second window it queried. The useful part of the drawing is the fourth lane. It is empty, it is correct, and reading it as "no login occurred" would be wrong in a way no amount of care while reading the other three would catch. That is the shape of the missing logs indicator: an absence in one place is only interpretable against what the other places hold, which is also why an investigation that draws on a single source is fragile regardless of how good that source is.</figcaption>
</figure>

<details class="deeper">
<summary>Impossible travel at scale: why it fires constantly, and how to keep it worth having</summary>

Impossible travel is the indicator most likely to be switched on first and switched
off within a month, because the arithmetic that makes it appealing is also what
makes it noisy.

**The rule is simple and that is the problem.** Two sign-ins, a distance between
the addresses, a time between the events, and an implied speed. Anything faster
than a plausible journey is flagged. Nothing in that calculation knows what a
virtual private network is.

**The four ordinary causes** account for most of what it produces. A user connects
through a corporate egress in another country. A phone hands off between carriers
whose address ranges are registered in different places. A service acts for the
user from its own datacentre, so the user appears to be wherever that datacentre
is. And geolocation of an address is an estimate that is frequently wrong at
country granularity, particularly for mobile and satellite ranges.

**What keeps it useful is refusing to alert on it alone.** Treat it as one input
and require a second: a new device, an unusual authentication method, a token that
was issued somewhere else, a session that did something sensitive. Two weak
indicators that agree are worth more than either one escalated.

**Excluding your own egress addresses is the cheapest single improvement**, and it
is often left undone because nobody maintains the list. That list has to be a real
piece of operational data with an owner, or the rule degrades quietly as the estate
changes.

**And baseline per user rather than globally.** A person who travels weekly and a
person who has worked from the same room for three years should not be measured
against the same threshold. The version of this that works compares a user against
their own history, which is a different and more expensive calculation than the
distance-over-time rule, and it is what the products that keep this feature
switched on are actually doing.

</details>

## The indicator that is an absence

Missing logs is the odd one out because it is the only indicator you find by
looking for nothing. It is also the one where the innocent explanation is usually
correct, which is why it takes discipline to check.

<details class="predict">
<summary>A machine's journal with no retention configured. Predict how far back it can answer for, and whether the gaps in it mean anything.</summary>

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ echo "how far back this machine's record goes:"
journalctl --disk-usage
journalctl -o short-iso --no-pager | head -1 | cut -c1-58
echo
echo "what is set in journald.conf to bound it:"
set=$(grep -hE '^[^#]*(SystemMaxUse|MaxRetentionSec|Storage)=' \
  /etc/systemd/journald.conf /etc/systemd/journald.conf.d/*.conf 2>/dev/null)
printf '%s\n' "${set:-  no SystemMaxUse, MaxRetentionSec or Storage line is set}"
echo
echo "where the record stops and starts again:"
journalctl --list-boots
echo
echo "whether the journal detects alteration of its own files:"
journalctl --verify 2>&1 | tail -2 | cut -c1-64
how far back this machine's record goes:
Archived and active journals take up 1.3G in the file system.
2026-08-07T14:14:40-05:00 localhost kernel: Booting Linux 

what is set in journald.conf to bound it:
  no SystemMaxUse, MaxRetentionSec or Storage line is set

where the record stops and starts again:
IDX BOOT ID                          FIRST ENTRY                 LAST ENTRY
 -4 4deecf7538d74e608cdb644b4c853e72 Fri 2026-08-07 14:14:40 CDT Fri 2026-08-07 23:12:07 CDT
 -3 0c5a4845793041e4ae090aa26818a7f3 Sat 2026-08-08 11:40:59 CDT Sat 2026-08-08 13:20:25 CDT
 -2 07613d8ef7bb4c44aecf74ce263f383d Sat 2026-08-08 13:21:02 CDT Thu 2026-08-20 22:49:34 CDT
 -1 923756532f224677a34d9a5817ccf9be Fri 2026-08-21 10:10:22 CDT Wed 2026-08-26 15:24:27 CDT
  0 c312139d61d54883a1b0f4f1afb13eed Wed 2026-08-26 15:43:18 CDT Wed 2026-08-26 19:20:53 CDT

whether the journal detects alteration of its own files:
PASS: /var/log/journal/fbe3cf662cb64de7a1d91f9d0cad9413/system@1
PASS: /var/log/journal/fbe3cf662cb64de7a1d91f9d0cad9413/system@0
```

**Nineteen days, bounded by size rather than by a policy, with four gaps that all
have the same explanation.**

Nothing in the configuration sets a retention period. What bounds the record is the
default cap on disk usage, so how far back this machine can answer for is a
consequence of how much it logs rather than of a decision anybody made. That is the
usual state of a machine, and it means the answer to "can we see last month" is
found by measuring rather than by reading a policy.

The boot list is where the gaps are, and they are the good kind. Each gap sits
between the last entry of one boot and the first of the next, which is a machine
that was switched off. The longest here is about eleven hours overnight. A gap that
sat inside a single boot would be a different conversation entirely, because a
running machine that logged nothing for eleven hours has something to explain.

The verification lines at the end are worth knowing about. The journal keeps
internal hashes, so it can tell you its own files have not been altered in place.
That is a much weaker statement than it sounds: it detects corruption and
modification of what is there, and says nothing about what was removed before it
was written or about a file deleted whole.

</details>

<details class="deeper">
<summary>What a gap in a log actually proves, and the four things that produce one</summary>

The temptation with a gap is to treat it as evidence of an attacker covering
tracks. It is evidence of an absence of records, which is a much smaller claim, and
four things produce one.

**Rotation and retention.** The oldest entries were discarded to make room. This is
the common case, it is detectable from the size of the store against its cap, and
the boundary is usually clean: everything before a moment is gone and everything
after it is intact.

**A collector or service that stopped.** The source was not writing. Something
usually recorded that, either the supervisor that noticed the process exit or the
other logs that kept running while this one did not.

**A machine that was not running.** The boot list in the capture above shows this
directly, and it is the only one of the four where the gap has a documented
beginning and end.

**Deliberate removal.** Which may leave a mark and may not, depending on how it was
done. The platform comparison below has a real example of a log whose oldest
surviving record is the event recording that everything before it was cleared.

**So the discriminating question is not what is missing, it is what else was
running.** Three sources with different retention periods and different storage
rarely lose the same window for the same reason. If two of them cover the gap in
the third, the gap is explained. If all three stop at the same instant, something
happened to the machine, and that is a finding regardless of what caused it.

**One practice that makes this tractable** is sending logs somewhere the machine
that produces them cannot reach to edit. It does not prevent removal locally, and
it means removal locally becomes a discrepancy between two copies rather than an
absence in the only one, which is a much easier thing to notice.

</details>

## Across platforms

How far back a machine can answer for, and whether erasing its record leaves a
mark, are answered differently on each platform.

**Windows keeps separate logs with separate sizes, and records its own clearing.**

```powershell
# Microsoft Windows Server 2025 Datacenter, version 10.0.26100.0
> Get-WinEvent -ListLog Security | Select-Object LogName, IsEnabled, LogMode, MaximumSizeInBytes, RecordCount | Format-List
LogName            : Security
IsEnabled          : True
LogMode            : Circular
MaximumSizeInBytes : 20971520
RecordCount        : 14816

# The oldest record still in it, which is the retention this machine actually has rather than the one configured
> Get-WinEvent -LogName Security -Oldest -MaxEvents 1 | ForEach-Object { '{0}  oldest record still held, id {1}' -f $_.TimeCreated, $_.Id }
8/18/2026 11:02:15 PM  oldest record still held, id 1102

# Whether clearing the security log is itself an event, and whether it has happened here
> $c = @(Get-WinEvent -FilterHashtable @{LogName='Security'; Id=1102} -MaxEvents 3 -ErrorAction SilentlyContinue); if ($c.Count) { $c | Select-Object TimeCreated, Id | Format-Table -AutoSize } else { 'no event 1102 present, so this log has not been cleared since it began' }
TimeCreated             Id
-----------             --
8/18/2026 11:02:15 PM 1102

# How many records the other logs hold, since a gap in one is only visible against the others
> Get-WinEvent -ListLog Application, System, 'Microsoft-Windows-PowerShell/Operational' | Select-Object LogName, RecordCount, LogMode, MaximumSizeInBytes | Format-Table -AutoSize
LogName                                  RecordCount  LogMode MaximumSizeInBytes
-------                                  -----------  ------- ------------------
Application                                      168 Circular           20971520
System                                          1124 Circular           20971520
Microsoft-Windows-PowerShell/Operational        1024 Circular           15728640
```

Read the second and third blocks together, because they are the same event. The
oldest record still held in the security log is event 1102, which is the event that
records the log being cleared. Everything before that moment is gone and the only
survivor is the note saying so. Twenty megabytes and fourteen thousand records is
also worth internalising: on a busy machine that is not a long time, and the log
mode is circular, so it discards silently once it is full.

**macOS keeps one unified store bounded by size.**

```bash
# macOS 26.5.2, arm64
$ sudo du -sh /var/db/diagnostics 2>/dev/null
133M	/var/db/diagnostics

# The newest and oldest persisted chunks, which bracket the window this machine can answer for
$ ls -lt /var/db/diagnostics/Persist 2>/dev/null | sed -n '2p'; ls -ltr /var/db/diagnostics/Persist 2>/dev/null | sed -n '2p'
-rw-r--r--@ 1 root  admin   4417192 Aug 27 00:15 0000000000000014.tracev3
-rw-r--r--@ 1 root  admin  10487856 Jul 28 05:25 0000000000000006.tracev3

# What the logging system is configured to keep and at what level
$ sudo log config --status 2>&1 | head -3
System mode = INFO

# Whether a separate login record exists here as well, and how far it goes back
$ last | tail -3
reboot time                                Mon Jul 27 05:13

wtmp begins Mon Jul 27 05:13:31 UTC 2026
```

Two hundred megabytes of persisted log, with chunks running from late July to the
day of the capture, so this machine can answer for about a month. Nothing is
configured; the window is a consequence of the size cap and how much this machine
logs, which is the same situation as the Linux capture above. The last block shows
the separate login record beginning on the same July date, which is when the image
was built.

**Which gives the comparison in one line.** All three platforms bound their logs by
size rather than by time unless somebody says otherwise, so every one of them
answers "how far back can we see" with a number that changes as the machine gets
busier, and none of them will tell you it has started discarding.

## Try it

**Find your own retention.** On any machine you administer, find the oldest record
in its security log and work out how many days that is. Then ask whether it covers
the time it would take you to notice an incident.

**Correlate one action.** Do something ordinary on a machine you own, then find the
records it produced in three different places and identify the field common to all
three. The exercise is finding the field, not the records.

**Look for a gap and explain it.** Take any log with a few weeks in it, find a
period with no entries, and account for it. Most gaps are boring and finding out
which kind is the skill.

**Check whether clearing is recorded.** On a test machine, clear a log and see what
survives. Then ask what would be left if the file had been deleted from underneath
the logging system instead.

## Check yourself

<details class="qa">
<summary>An account is locked and the owner did not try to sign in. What do you already know?</summary>

That the threshold's worth of failed attempts occurred, and that they came from
somewhere the owner is not. The lockout is the mechanism reporting, not the
incident.

The innocent explanations sit next to the alarming one: a device holding a stale
password and retrying, a scheduled task running under the account with an old
credential, or a colleague mistyping a shared username. Ruling those out is the
work.

</details>

<details class="qa">
<summary>What makes records from different sources into one incident?</summary>

A field that appears in all of them and means the same thing in each. The capture
on this page shows one login recorded by three subsystems, tied by a session
identifier that the session tracker and the kernel audit stream both allocated to
the same value.

That agreement is worth confirming rather than assuming, because different
subsystems number things independently and a coincidence of numbering on one
platform is not a guarantee on another.

</details>

<details class="qa">
<summary>Why is impossible travel so noisy, and what makes it useful?</summary>

Because the calculation is a distance over a time and knows nothing about virtual
private networks, mobile carriers whose ranges are registered elsewhere, services
acting for the user from a datacentre, or the ordinary inaccuracy of address
geolocation.

It becomes useful when it is one input rather than an alert: require a second
indicator to agree, maintain a real list of your own egress addresses, and compare
each user against their own history instead of a single global threshold.

</details>

<details class="qa">
<summary>What does a gap in a log prove?</summary>

That records are absent, which is a smaller claim than that events are absent. Four
things produce a gap: rotation or a retention limit, a collector that stopped, a
machine that was not running, and deliberate removal.

The discriminating question is what else was running. Sources with different
retention and different storage rarely lose the same window for the same reason, so
a gap covered by two other sources is explained, and a gap in all three at the same
instant is a finding on its own.

</details>

<details class="qa">
<summary>What is the difference between out-of-cycle logging and unexpected content?</summary>

Out-of-cycle is a timing observation and needs no understanding of what the entries
say: a source producing entries outside its own normal rhythm, which is arithmetic
on volume per hour against that source's history.

Unexpected is a content observation and requires somebody to have encoded an
expectation, so it is only as good as the expectation. The combination carries more
than either, since an ordinary action at an odd hour is invisible to a content rule
and unremarkable to a timing rule.

</details>

## References

- [SP 800-92](https://csrc.nist.gov/pubs/sp/800/92/final) - NIST, log management, for retention, rotation and the operational side of keeping records worth reading. Free. Accessed 2026-08-26.
- [RFC 5424](https://www.rfc-editor.org/rfc/rfc5424.html) - IETF, the syslog protocol, for the structured fields correlation depends on. Free. Accessed 2026-08-26.
- [T1070.001](https://attack.mitre.org/techniques/T1070/001/) - MITRE, clearing event logs as a documented technique, with the detection notes that follow from it. Free. Accessed 2026-08-26.

**Where the content came from.** Both Linux blocks are captured from the Fedora
CoreOS virtual machine this repository's container tooling runs on, which is a full
systemd installation with a real journal and a real audit stream rather than a
container borrowing the host's kernel. The login they describe is the capture
tooling's own connection, so the incident being correlated is the act of capturing
it. Nothing was altered on that machine: every command reads. The Windows and macOS
blocks come from disposable runners, and the cleared security log in the Windows
block is an artefact of how that image is built rather than anything that happened
during the capture.

**If you also work on networks.** The Network+ track's
[baselines, alerting and monitoring solutions](/learn/network-plus/baselines-alerting-and-monitoring-solutions)
covers the collection side, including what a baseline has to be measured against.
