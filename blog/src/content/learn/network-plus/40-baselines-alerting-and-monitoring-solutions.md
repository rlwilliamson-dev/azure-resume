---
title: "Baselines, alerting and monitoring solutions"
description: "Why a number on its own is not evidence of anything, what a threshold does to a metric that has a daily shape, and the two ways a counter lies to the system reading it."
deck: "The alert fired at 2am and it was nothing"
track: "network-plus"
level: "working"
order: 410
objectives:
  - "Say why a metric means nothing without a baseline"
  - "Explain why a fixed threshold misfires on a cyclical metric"
  - "Describe alert fatigue as a mechanism rather than an attitude"
  - "Say what a 32-bit counter does at high speed and what to poll instead"
  - "Distinguish log aggregation, syslog collection and security event management"
prerequisites: ["snmp"]
tags: ["network-plus", "networking", "monitoring"]
updated: 2026-08-12
draft: false
examObjectives:
  - exam: "n10-009"
    domain: "3.0"
    objective: "3.2"
sources:
  - title: "RFC 2863, The Interfaces Group MIB"
    url: "https://www.rfc-editor.org/rfc/rfc2863"
    publisher: "IETF"
    accessed: 2026-08-12
    tier: 1
  - title: "RFC 5424, The Syslog Protocol"
    url: "https://www.rfc-editor.org/rfc/rfc5424"
    publisher: "IETF"
    accessed: 2026-08-12
    tier: 1
  - title: "RFC 3164, The BSD syslog Protocol"
    url: "https://www.rfc-editor.org/rfc/rfc3164"
    publisher: "IETF"
    accessed: 2026-08-12
    tier: 1
  - title: "NIST SP 800-92, Guide to Computer Security Log Management"
    url: "https://csrc.nist.gov/pubs/sp/800/92/final"
    publisher: "NIST"
    accessed: 2026-08-12
    tier: 1
symptoms:
  - symptom: "An alert fires every night and is never a real problem"
    anchor: "a-threshold-against-a-shape"
  - symptom: "A traffic graph reports a fraction of what the link is carrying"
    anchor: "two-ways-a-counter-lies"
  - symptom: "A metric looks bad and nobody can say whether it is unusual"
    anchor: "a-number-is-not-evidence"
---

> **Before you read.** A monitoring system alerts on link utilisation above 70
> per cent. It has fired at around two in the morning every night for four
> months, and every time somebody has looked, the answer has been the backup job.
>
> Last Thursday afternoon a link ran at 65 per cent for six hours during an
> incident nobody spotted until users called.
>
> **The threshold is doing exactly what it was configured to do. What is wrong
> with it?**

Monitoring is the part of this exam most easily reduced to a list of product
categories. The categories are worth knowing and they are not the difficult part.
The difficult part is that a metric is meaningless on its own, and every mistake
below follows from forgetting that.

### Some words you will need

<dl class="terms">
<dt>baseline</dt>
<dd>What normal looked like, recorded before you needed to know.</dd>
<dt>threshold</dt>
<dd>The value at which something is meant to get a human's attention.</dd>
<dt>anomaly</dt>
<dd>A departure from the baseline rather than from a fixed number.</dd>
<dt>alert fatigue</dt>
<dd>What happens to people who receive alerts that are usually nothing.</dd>
<dt>syslog</dt>
<dd>The protocol devices use to send log messages somewhere else.</dd>
<dt>SIEM</dt>
<dd>Security information and event management. Log aggregation with correlation and alerting on top.</dd>
</dl>

## What breaks without this

**An alert becomes noise.** It fires nightly, it is never anything, and after four
months nobody reads it. The mechanism that was supposed to protect you is now
training people to ignore it.

**A real problem sits under the threshold.** Because the threshold was set for the
peak rather than for the pattern.

**A graph is wrong and looks fine.** A counter wrapped, or the agent answered from
a cache, and the number that came back is plausible and false.

## A number is not evidence

Latency of 412 milliseconds is not good or bad. It is a number, and nothing about
it says which.

<figure class="learn-figure">
<svg viewBox="0 0 720 240" role="img" aria-labelledby="baseline-title" style="width:100%;height:auto;">
<title id="baseline-title">The same latency reading of 412 milliseconds plotted against two different histories: one where the link has always run near 400 milliseconds, and one where it has never exceeded 90</title>
<g fill="currentColor">
<text x="14" y="22" font-size="11">412 ms, on two different links</text>
<text x="18" y="44" font-size="10.5" fill-opacity="0.85">a link that has always been slow</text>
<line x1="48" y1="176" x2="314" y2="176" stroke="currentColor" stroke-opacity="0.45" stroke-width="1"/>
<line x1="48" y1="56" x2="48" y2="176" stroke="currentColor" stroke-opacity="0.45" stroke-width="1"/>
<text x="42" y="60" text-anchor="end" font-size="9.5" fill-opacity="0.7">500</text>
<text x="42" y="180" text-anchor="end" font-size="9.5" fill-opacity="0.7">0</text>
<path d="M 52.0 82.9 L 70.2 79.5 L 88.5 85.0 L 106.7 77.6 L 124.9 81.2 L 143.1 74.0 L 161.4 84.6 L 179.6 81.4 L 197.8 79.1 L 216.0 83.2 L 234.2 80.0 L 252.5 85.0 L 270.7 81.7 L 288.9 79.6" fill="none" stroke="currentColor" stroke-opacity="0.6" stroke-width="1.4"/>
<line x1="288.9" y1="79.6" x2="314.9" y2="77.1" stroke="currentColor" stroke-width="1.6"/>
<circle cx="314.9" cy="77.1" r="4" fill="currentColor"/>
<text x="306.9" y="65.1" text-anchor="middle" font-size="10.5" fill="currentColor">412</text>
<text x="48" y="206" font-size="10.5" fill="currentColor">a normal tuesday</text>
<text x="394" y="44" font-size="10.5" fill-opacity="0.85">a link that has never been slow</text>
<line x1="424" y1="176" x2="690" y2="176" stroke="currentColor" stroke-opacity="0.45" stroke-width="1"/>
<line x1="424" y1="56" x2="424" y2="176" stroke="currentColor" stroke-opacity="0.45" stroke-width="1"/>
<text x="418" y="60" text-anchor="end" font-size="9.5" fill-opacity="0.7">500</text>
<text x="418" y="180" text-anchor="end" font-size="9.5" fill-opacity="0.7">0</text>
<path d="M 428.0 161.1 L 446.2 162.1 L 464.5 158.9 L 482.7 162.8 L 500.9 160.2 L 519.1 161.6 L 537.4 158.2 L 555.6 161.8 L 573.8 160.9 L 592.0 162.3 L 610.2 159.7 L 628.5 161.4 L 646.7 159.2 L 664.9 160.6" fill="none" stroke="currentColor" stroke-opacity="0.6" stroke-width="1.4"/>
<line x1="664.9" y1="160.6" x2="690.9" y2="77.1" stroke="var(--red)" stroke-width="1.6"/>
<circle cx="690.9" cy="77.1" r="4" fill="var(--red)"/>
<text x="682.9" y="65.1" text-anchor="middle" font-size="10.5" fill="var(--red)">412</text>
<text x="424" y="206" font-size="10.5" fill="var(--red)">the worst reading in a fortnight</text>
<text x="48" y="228" font-size="9.5" fill-opacity="0.7">fourteen days of samples</text>
<text x="424" y="228" font-size="9.5" fill-opacity="0.7">fourteen days of samples</text>
</g></svg>
<figcaption>One reading, two links, opposite conclusions. Neither chart needs a threshold or a rule to be read: the point on the left continues a line, and the point on the right leaves one. That is what a baseline buys, and it is why the answer to "is 412 milliseconds bad" is always another question. The practical consequence is about timing rather than technique. A baseline is a record of the past, so it can only be collected before you need it, and the moment somebody most wants one is the moment it is too late to start.</figcaption>
</figure>

**A baseline is what normal looked like**, recorded over long enough to include
the variation that is ordinary. Time of day, day of week, and the month somebody
runs a quarter end job.

The consequence is worth stating plainly, because it is the reason monitoring gets
set up after the first bad week rather than before it. **You cannot measure the
past retrospectively.** Whatever you are not collecting today is a question you
will not be able to answer in three months.

## A threshold against a shape

Once you have a baseline, the obvious next step is to draw a line across it and
alert above the line. This works for metrics that are flat and misfires on every
metric that is not.

<figure class="learn-figure">
<svg viewBox="0 0 720 268" role="img" aria-labelledby="threshold-title" style="width:100%;height:auto;">
<title id="threshold-title">A week of link utilisation with a nightly backup peak crossing a fixed 70 per cent threshold seven times, and a sustained daytime rise to 65 per cent that never crosses it</title>
<g fill="currentColor">
<text x="14" y="22" font-size="11">a flat threshold across a metric that has a shape of its own</text>
<line x1="52" y1="188" x2="606" y2="188" stroke="currentColor" stroke-opacity="0.45" stroke-width="1"/>
<line x1="52" y1="48" x2="52" y2="188" stroke="currentColor" stroke-opacity="0.45" stroke-width="1"/>
<text x="44" y="192.0" text-anchor="end" font-size="9.5" fill-opacity="0.7">0</text>
<text x="44" y="122.0" text-anchor="end" font-size="9.5" fill-opacity="0.7">50</text>
<text x="44" y="52.0" text-anchor="end" font-size="9.5" fill-opacity="0.7">100</text>
<path d="M 56.0 179.6 L 59.3 178.8 L 62.5 67.4 L 65.8 63.8 L 69.1 59.2 L 72.3 163.0 L 75.6 157.2 L 78.9 151.4 L 82.2 146.0 L 85.4 141.4 L 88.7 137.8 L 92.0 135.6 L 95.2 134.8 L 98.5 135.6 L 101.8 137.8 L 105.0 141.4 L 108.3 146.0 L 111.6 151.4 L 114.9 157.2 L 118.1 163.0 L 121.4 168.4 L 124.7 173.0 L 127.9 176.6 L 131.2 178.8 L 134.5 179.6 L 137.7 178.8 L 141.0 67.4 L 144.3 63.8 L 147.5 59.2 L 150.8 163.0 L 154.1 157.2 L 157.4 151.4 L 160.6 146.0 L 163.9 141.4 L 167.2 137.8 L 170.4 135.6 L 173.7 134.8 L 177.0 135.6 L 180.2 137.8 L 183.5 141.4 L 186.8 146.0 L 190.0 151.4 L 193.3 157.2 L 196.6 163.0 L 199.9 168.4 L 203.1 173.0 L 206.4 176.6 L 209.7 178.8 L 212.9 179.6 L 216.2 178.8 L 219.5 67.4 L 222.7 63.8 L 226.0 59.2 L 229.3 163.0 L 232.6 157.2 L 235.8 151.4 L 239.1 146.0 L 242.4 141.4 L 245.6 137.8 L 248.9 135.6 L 252.2 134.8 L 255.4 135.6 L 258.7 137.8 L 262.0 141.4 L 265.2 146.0 L 268.5 151.4 L 271.8 157.2 L 275.1 163.0 L 278.3 168.4 L 281.6 173.0 L 284.9 176.6 L 288.1 178.8 L 291.4 179.6 L 294.7 178.8 L 297.9 67.4 L 301.2 63.8 L 304.5 59.2 L 307.7 163.0 L 311.0 157.2 L 314.3 151.4 L 317.6 146.0 L 320.8 141.4 L 324.1 137.8 L 327.4 135.6 L 330.6 134.8 L 333.9 135.6 L 337.2 137.8 L 340.4 141.4 L 343.7 146.0 L 347.0 151.4 L 350.3 157.2 L 353.5 163.0 L 356.8 168.4 L 360.1 173.0 L 363.3 176.6 L 366.6 178.8 L 369.9 179.6 L 373.1 178.8 L 376.4 67.4 L 379.7 63.8 L 382.9 59.2 L 386.2 163.0 L 389.5 157.2 L 392.8 151.4 L 396.0 146.0 L 399.3 141.4 L 402.6 137.8 L 405.8 135.6 L 409.1 134.8 L 412.4 98.4 L 415.6 98.4 L 418.9 98.4 L 422.2 98.4 L 425.4 98.4 L 428.7 98.4 L 432.0 98.4 L 435.3 168.4 L 438.5 173.0 L 441.8 176.6 L 445.1 178.8 L 448.3 179.6 L 451.6 178.8 L 454.9 67.4 L 458.1 63.8 L 461.4 59.2 L 464.7 163.0 L 468.0 157.2 L 471.2 151.4 L 474.5 146.0 L 477.8 141.4 L 481.0 137.8 L 484.3 135.6 L 487.6 134.8 L 490.8 135.6 L 494.1 137.8 L 497.4 141.4 L 500.6 146.0 L 503.9 151.4 L 507.2 157.2 L 510.5 163.0 L 513.7 168.4 L 517.0 173.0 L 520.3 176.6 L 523.5 178.8 L 526.8 179.6 L 530.1 178.8 L 533.3 67.4 L 536.6 63.8 L 539.9 59.2 L 543.1 163.0 L 546.4 157.2 L 549.7 151.4 L 553.0 146.0 L 556.2 141.4 L 559.5 137.8 L 562.8 135.6 L 566.0 134.8 L 569.3 135.6 L 572.6 137.8 L 575.8 141.4 L 579.1 146.0 L 582.4 151.4 L 585.7 157.2 L 588.9 163.0 L 592.2 168.4 L 595.5 173.0 L 598.7 176.6 L 602.0 178.8" fill="none" stroke="currentColor" stroke-opacity="0.65" stroke-width="1.3"/>
<line x1="52" y1="90.0" x2="606" y2="90.0" stroke="var(--red)" stroke-width="1.6" stroke-dasharray="6 4"/>
<text x="618" y="94.0" font-size="10.5" fill="var(--red)">alert above 70%</text>
<circle cx="69.1" cy="59.2" r="3.5" fill="var(--red)" fill-opacity="0.85"/>
<circle cx="147.5" cy="59.2" r="3.5" fill="var(--red)" fill-opacity="0.85"/>
<circle cx="226.0" cy="59.2" r="3.5" fill="var(--red)" fill-opacity="0.85"/>
<circle cx="304.5" cy="59.2" r="3.5" fill="var(--red)" fill-opacity="0.85"/>
<circle cx="382.9" cy="59.2" r="3.5" fill="var(--red)" fill-opacity="0.85"/>
<circle cx="461.4" cy="59.2" r="3.5" fill="var(--red)" fill-opacity="0.85"/>
<circle cx="539.9" cy="59.2" r="3.5" fill="var(--red)" fill-opacity="0.85"/>
<rect x="409.4" y="91.4" width="25.6" height="14" rx="2" fill="none" stroke="var(--accent)" stroke-width="1.8"/>
<text x="95.2" y="204" text-anchor="middle" font-size="9.5" fill-opacity="0.7">day 1</text>
<text x="173.7" y="204" text-anchor="middle" font-size="9.5" fill-opacity="0.7">day 2</text>
<text x="252.2" y="204" text-anchor="middle" font-size="9.5" fill-opacity="0.7">day 3</text>
<text x="330.6" y="204" text-anchor="middle" font-size="9.5" fill-opacity="0.7">day 4</text>
<text x="409.1" y="204" text-anchor="middle" font-size="9.5" fill-opacity="0.7">day 5</text>
<text x="487.6" y="204" text-anchor="middle" font-size="9.5" fill-opacity="0.7">day 6</text>
<text x="566.0" y="204" text-anchor="middle" font-size="9.5" fill-opacity="0.7">day 7</text>
<text x="52" y="232" font-size="10.5" fill="var(--red)">7 alerts, every one of them the backup job</text>
<text x="52" y="252" font-size="10.5" fill="var(--accent)">1 sustained rise on day 5, six hours long, silent</text>
</g></svg>
<figcaption>The threshold is set correctly and behaves correctly. It fires seven times in a week, once per night, on a backup job that has run at that time for years, and it stays silent through a six hour departure from normal on day five because that departure peaked below the line. Raising the line stops the nightly alerts and widens the silence. Lowering it catches day five and adds daytime alerts on every ordinary afternoon. There is no value that fixes this, because the fault is not the number: it is that one line is being asked to describe a metric with two different normals in it.</figcaption>
</figure>

Three ways out, and they are worth knowing as a set because products present them
as features rather than as answers to this specific problem.

**Alert on the departure rather than the value.** Compare against what this metric
does at this hour on this day of the week, and alert when it differs. Products
call this anomaly detection or dynamic thresholds. Day five fires; the backup job
does not, because it is what Tuesday at two always looks like.

**Alert on duration rather than on a sample.** Sustained for six hours is a
different event from a peak lasting twenty minutes, and most alerting can require
a condition to persist. This alone fixes a great deal.

**Suppress by schedule.** Say that between two and four in the morning the
threshold is higher. Crude, entirely effective, and it goes stale silently when
the backup window moves, which is the argument for the first option.

**And alert fatigue is a mechanism rather than a failing.** An alert that is
usually nothing teaches the person receiving it that it is usually nothing, and
they are correct. Four months of nightly false alarms is training, and it works.
By the time a real one arrives the response time is measured against the previous
hundred, not against the severity of this one. That is worth saying to whoever
insists the alert stays as it is, because the choice is not between an alert and
no alert. It is between an alert somebody reads and one they do not.

## Two ways a counter lies

The metrics behind all of this arrive as counters, and counters are less
straightforward than they look.

**The first problem is that a counter is not a rate.** `ifInOctets` counts
upwards forever, so the useful number is the difference between two readings
divided by the time between them, and that arithmetic assumes both readings are
accurate as of the moment they were taken.

<details class="predict">
<summary>An interface octet counter, polled twice a few seconds apart. Which of the two numbers tells you anything, and what has to be done to it first?</summary>

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology managed-lan
# the octet counter on the agent, before anything happens
$ ip netns exec mon snmpget -v2c -c s3cr3t-ro -On 10.0.0.20 1.3.6.1.2.1.2.2.1.10.6
.1.3.6.1.2.1.2.2.1.10.6 = Counter32: 54
# twenty frames of 1400 bytes, which is about 28.8 kB on the wire
$ ip netns exec mon ping -c 20 -i 0.2 -s 1400 -q 10.0.0.20 | tail -1
rtt min/avg/max/mdev = 0.047/0.101/0.197/0.037 ms
# poll immediately. the agent answers, and the answer is already out of date
$ ip netns exec mon snmpget -v2c -c s3cr3t-ro -On 10.0.0.20 1.3.6.1.2.1.2.2.1.10.6
.1.3.6.1.2.1.2.2.1.10.6 = Counter32: 21816
$ sleep 6
# poll again. nothing has been sent in between
$ ip netns exec mon snmpget -v2c -c s3cr3t-ro -On 10.0.0.20 1.3.6.1.2.1.2.2.1.10.6
.1.3.6.1.2.1.2.2.1.10.6 = Counter32: 29158
# what the kernel on the agent had all along
$ ip netns exec agent grep agent0 /proc/net/dev
agent0:   29248      26    0    0    0     0          0         0    29199      25    0    0    0     0       0          0
```

</details>

The traffic finished before the second command returned. The poll immediately
afterwards reported 21 816 bytes. Six seconds later, with nothing else sent, the
same poll reported 29 158, and the kernel's own figure was 29 248 the whole time.

**The agent was answering from a cache.** That is a property of this particular
agent rather than of the protocol, and agents that cache are common, because
rebuilding an interface table for every request on a device with four hundred
ports is expensive. The consequence is general: a poll returns a value that was
true recently, and polling faster than the cache refreshes produces a graph that
alternates between zero and double, from an interface with perfectly steady
traffic.

**The second problem is the size of the counter.** The interfaces MIB defines
`ifInOctets` as a 32-bit counter, and 32 bits is not many at modern speeds.

```bash
# Debian 13 (trixie), x86_64
$ snmptranslate -Td IF-MIB::ifInOctets; echo; snmptranslate -Td IF-MIB::ifHCInOctets
IF-MIB::ifInOctets
ifInOctets OBJECT-TYPE
  -- FROM	IF-MIB
  SYNTAX	Counter32
  MAX-ACCESS	read-only
  STATUS	current
  DESCRIPTION	"The total number of octets received on the interface,
            including framing characters.

            Discontinuities in the value of this counter can occur at
            re-initialization of the management system, and at other
            times as indicated by the value of
            ifCounterDiscontinuityTime."
::= { iso(1) org(3) dod(6) internet(1) mgmt(2) mib-2(1) interfaces(2) ifTable(2) ifEntry(1) 10 }

IF-MIB::ifHCInOctets
ifHCInOctets OBJECT-TYPE
  -- FROM	IF-MIB
  SYNTAX	Counter64
  MAX-ACCESS	read-only
  STATUS	current
  DESCRIPTION	"The total number of octets received on the interface,
            including framing characters.  This object is a 64-bit
            version of ifInOctets.

            Discontinuities in the value of this counter can occur at
            re-initialization of the management system, and at other
            times as indicated by the value of
            ifCounterDiscontinuityTime."
::= { iso(1) org(3) dod(6) internet(1) mgmt(2) mib-2(1) ifMIB(31) ifMIBObjects(1) ifXTable(1) ifXEntry(1) 6 }
```

Two objects, the same description, one word different. `Counter32` holds
4 294 967 295 and then starts again at zero, and at a gigabit that takes about
thirty four seconds.

<figure class="learn-figure">
<svg viewBox="0 0 720 260" role="img" aria-labelledby="wrap-title" style="width:100%;height:auto;">
<title id="wrap-title">A 32-bit octet counter climbing at one gigabit per second, wrapping to zero every 34 seconds, so that two samples five minutes apart give a difference that bears no relation to the traffic</title>
<g fill="currentColor">
<text x="14" y="22" font-size="11">a Counter32 at 1 Gbit/s, and two polls 300 seconds apart</text>
<line x1="96" y1="168" x2="690" y2="168" stroke="currentColor" stroke-opacity="0.45" stroke-width="1"/>
<line x1="96" y1="52" x2="96" y2="168" stroke="currentColor" stroke-opacity="0.45" stroke-width="1"/>
<text x="88" y="56" text-anchor="end" font-size="9.5" fill-opacity="0.7">4 294 967 295</text>
<text x="88" y="172" text-anchor="end" font-size="9.5" fill-opacity="0.7">0</text>
<path d="M 96.0 87.0 L 116.5 52.0 L 116.5 168.0 L 184.5 52.0 L 184.5 168.0 L 252.5 52.0 L 252.5 168.0 L 320.6 52.0 L 320.6 168.0 L 388.6 52.0 L 388.6 168.0 L 456.6 52.0 L 456.6 168.0 L 524.7 52.0 L 524.7 168.0 L 592.7 52.0 L 592.7 168.0 L 660.7 52.0 L 660.7 168.0 L 690.0 118.1" fill="none" stroke="currentColor" stroke-opacity="0.6" stroke-width="1.4"/>
<line x1="96" y1="46" x2="96" y2="174" stroke="var(--red)" stroke-width="1.6"/>
<text x="100" y="38" font-size="10.5" fill="var(--red)">first poll</text>
<text x="100" y="190" font-size="10" fill="var(--red)">3 001 447 936</text>
<line x1="690" y1="46" x2="690" y2="174" stroke="var(--red)" stroke-width="1.6"/>
<text x="686" y="38" text-anchor="end" font-size="10.5" fill="var(--red)">second poll</text>
<text x="686" y="190" text-anchor="end" font-size="10" fill="var(--red)">1 846 742 272</text>
<text x="14" y="212" font-size="10.5">the second sample is smaller, so the poller adds one wrap and reports 84 Mbit/s</text>
<text x="14" y="232" font-size="10.5" fill-opacity="0.85">the counter wrapped eight times. the interface was running at 1000 Mbit/s</text>
</g></svg>
<figcaption>What a five minute poll of a 32-bit counter does to a saturated gigabit link. The second reading is lower than the first, so the monitoring system does the sensible thing and assumes a single wrap, adding 4 294 967 296 before subtracting. That gives a plausible answer of 84 Mbit/s from a link that was running flat out for the whole interval, and there is nothing in the data to say otherwise: the counter cannot record how many times it went round. This is what the 64-bit objects exist for, and it is why RFC 2863 says a 32-bit counter is only suitable below about 20 Mbit/s. A graph reading a tenth of the real traffic looks entirely believable, which is what makes it dangerous.</figcaption>
</figure>

The practical rule is short. **Poll the 64-bit objects on anything faster than a
few megabits**, which is everything. They live under `ifXTable`, the extension
table, which is a separate part of the MIB, and a monitoring system configured
years ago on slower equipment may still be reading the 32-bit ones.

## The rest of what a monitoring system does

Metrics are one of the two things being collected. The other is logs, and the
exam separates three ideas that get used interchangeably.

**Syslog is the protocol.** A device sends a message to a collector over the
network, traditionally on udp/514. Each message carries a facility and a severity,
which is what makes filtering possible. RFC 3164 describes what the original
implementations did and RFC 5424 is the standard that replaced it, which matters
because a lot of equipment still sends the older format.

**Log aggregation is putting them in one place.** The value is not sophisticated:
it is that a device which has crashed cannot be logged into, and its last words
are already somewhere else. It also means searching one system instead of forty.

**Security event management adds correlation.** A SIEM takes logs from many
sources, normalises them, and applies rules across them, so a failed login on one
device and a successful login from the same address on another can be a single
finding. That is the part that distinguishes it from a log server, and it is also
the part that generates most of its cost and most of its false positives.

Two more things belong in the same list, and both come up as exam vocabulary.

**API integration** is how a monitoring system reads things that do not speak
SNMP. Cloud platforms, virtualisation managers and modern equipment expose a REST
interface, and reading it is frequently the only way to see anything at all.

**Network discovery** is the system finding devices rather than being told about
them, by sweeping address ranges, reading neighbour tables and following what it
finds. It can run on a schedule or on demand, and the interesting output is not
the list. It is the difference between the list and the inventory topic 36
described, because everything on one and not the other is something nobody knew
about.

<details class="deeper">
<summary>If you already work on networks: what to alert on when you cannot alert on everything, and why availability monitoring lies about its own accuracy</summary>

The instinct with a new monitoring system is to alert on every metric it can
collect, and the result is a system nobody trusts within a month. A more useful
question is which small set of signals catches most real problems.

One widely used answer, from the practice of running large services, is to alert
on four things per service: how much traffic it is handling, how many of those
requests fail, how long they take, and how full the resource is. The names vary
between organisations. The reason it works is that almost every user-visible
problem shows up in at least one of them, and almost nothing else does without
also showing up there.

Applied to a network the four become traffic on the link, errors and discards on
the interface, latency across it, and utilisation against capacity. Note what is
absent: CPU on the switch is not on the list. It is a fine thing to graph and a
poor thing to page somebody about, because a busy CPU with no user impact is
common and a switch dropping packets with a quiet CPU is entirely possible.

**Availability monitoring deserves its own warning**, because it produces the
number that gets quoted in meetings. A system that pings a device every sixty
seconds and reports 99.98 per cent availability is reporting the fraction of its
own probes that succeeded, which is not the same statement as the fraction of
time the device was up. An outage lasting forty seconds between two successful
probes contributes nothing to the figure, and the device was still down.

The measurement is also as reliable as the path to it. A probe crossing the same
failed link as the users cannot distinguish a device that is down from a device it
cannot reach, and both are frequently reported as down. That is why availability
figures from a single monitoring station are worth reading as approximate, and why
anybody who needs a real number probes from more than one place.

**The last one is discards against errors**, which sit next to each other in the
interface table and mean different things. An error is a frame that arrived
damaged, which points at cabling, optics or a duplex mismatch. A discard is a
frame that arrived intact and was thrown away anyway, usually because a queue was
full, which points at congestion or at policy. Alerting on the sum of the two
hides which of those you have, and they lead to entirely different work.

</details>

<figure class="learn-figure photo">

![A monitoring system web interface showing a service status page. The top of the page has summary boxes: one host up, and seventeen services showing OK with zero in the warning, unknown, critical and pending columns. Below is a table of seventeen services on a single host, each with a green OK badge, the time of the last check, how long it has been in that state, an attempt counter reading one of four or one of three, and a status message.](./images/monitoring-service-status.png)

<figcaption>A monitoring system with nothing wrong, which is what one looks like almost all of the time and is the state worth thinking about. Two columns repay attention. Duration says how long each service has been in its current state, which is the closest thing on the page to a baseline: seventeen days in one state is context that a green badge alone does not carry. And the attempt counter, reading one of four, is the mechanism that stops a single failed check from waking somebody: the system will retry three more times before it decides anything is wrong. That is the same idea as alerting on duration rather than on a sample, built into the product rather than configured per check. Screenshot by Dr.Lorenzeti, <a href="https://creativecommons.org/licenses/by-sa/4.0/">CC BY-SA 4.0</a>.</figcaption>
</figure>

## Across platforms

Every machine keeps the same cumulative counters an agent would expose, and
reading them twice is the whole of what a poller does.

**On Linux** they are in `/proc/net/dev`, which is what the capture above compared
the agent's answer against.

**On macOS**, `netstat` prints them.

```bash
# macOS 26.5.2, arm64
$ netstat -ib | awk 'NR==1 || $1 ~ /^en0$/' | head -3
Name       Mtu   Network       Address            Ipkts Ierrs     Ibytes    Opkts Oerrs     Obytes  Coll
en0        1500  <Link#7>    c6:66:6c:d3:09:29    11259     0   14571601     4707     0    1052393     0
en0        1500  iad20-gt102 fe80:7::c9c:87f5:    11259     -   14571601     4707     -    1052393     -

# Two seconds later, and the difference between the two is the only useful number
$ sleep 2

$ netstat -ib | awk 'NR==1 || $1 ~ /^en0$/' | head -3
Name       Mtu   Network       Address            Ipkts Ierrs     Ibytes    Opkts Oerrs     Obytes  Coll
en0        1500  <Link#7>    c6:66:6c:d3:09:29    11309     0   14583501     4781     0    1118512     0
en0        1500  iad20-gt102 fe80:7::c9c:87f5:    11309     -   14583501     4781     -    1118512     -

# Errors and drops, which are the counters worth alerting on rather than graphing
$ netstat -i | head -3
Name       Mtu   Network       Address            Ipkts Ierrs    Opkts Oerrs  Coll
lo0        16384 <Link#1>                           327     0      327     0     0
lo0        16384 127           localhost            327     -      327     -     -
```

**On Windows** there are two routes, and the difference between them is the
difference between reading a counter and sampling it.

```powershell
# Microsoft Windows Server 2025 Datacenter, version 10.0.26100.0
> Get-NetAdapterStatistics | Format-Table Name, ReceivedBytes, SentBytes -AutoSize
Name            ReceivedBytes SentBytes
----            ------------- ---------
Ethernet 3           18328437   2704363
vEthernet (nat)             0      3636
Ethernet 4           15983896   2753574

# Two seconds later. The difference is the only number that means anything
> Start-Sleep -Seconds 2

> Get-NetAdapterStatistics | Format-Table Name, ReceivedBytes, SentBytes -AutoSize
Name            ReceivedBytes SentBytes
----            ------------- ---------
Ethernet 3           18331995   2716827
vEthernet (nat)             0      3636
Ethernet 4           15984976   2766056

# The same values as a rate, sampled rather than differenced by hand
> Get-Counter -Counter "\Network Interface(*)\Bytes Total/sec" -MaxSamples 1 | Select-Object -ExpandProperty CounterSamples | Select-Object -First 2 InstanceName, CookedValue | Format-Table -AutoSize
InstanceName                                    CookedValue
------------                                    -----------
mellanox connectx-4 lx virtual ethernet adapter        0.00
microsoft hyper-v network adapter _3                   0.00
```

The last command is the one worth noticing. Performance counters do the
differencing for you and hand back a rate, which is convenient and hides the
subtraction that everything on this page has been about.

## Prove it

**Read a counter twice.** On any machine, using any of the commands above. Work
out the rate by hand, then check it against whatever graph you have for the same
interface over the same period.

**Find the oldest alert rule you have access to.** Ask who set it, when, and what
it has fired on in the last three months. If the answer is that it fires regularly
and is never anything, you have found a live example of the figure on this page.

**Check what your monitoring polls for interface traffic.** If it is the 32-bit
objects on a gigabit link, the graphs have been wrong at every busy moment and
right the rest of the time, which is the worst way for a graph to be wrong.

## What trips people up

### 1. Reading a metric without a baseline

A number on its own carries no verdict. The same latency figure is a normal
Tuesday on one link and the worst reading of the fortnight on another.

### 2. Setting one fixed threshold on a cyclical metric

A backup window and a working afternoon are two different normals, and one line
across both either fires nightly or misses the daytime problem.

### 3. Treating alert fatigue as a discipline problem

An alert that is usually nothing teaches people it is usually nothing. That is
learning working correctly, and the fix is to the alert.

### 4. Polling 32-bit counters on fast links

`ifInOctets` wraps in about thirty four seconds at a gigabit. The 64-bit objects
in the extension table are what to poll, and a monitoring system set up years ago
may still be reading the old ones.

### 5. Believing a poll returns the value at the instant it is asked

Agents cache interface tables, and polling faster than the cache refreshes
produces a graph that alternates between nothing and double.

### 6. Confusing a log server with a SIEM

Aggregation puts logs in one place, which is worth doing on its own. Correlating
across sources and alerting on the combination is the part that makes it a SIEM.

## Work it through

The 70 per cent threshold that fires nightly and missed a six hour incident.

The first thing to do is resist changing the number, because both directions are
worse. Raise it and the daytime blind spot widens. Lower it and every ordinary
afternoon starts alerting, which produces the same fatigue faster.

**The number is not the problem. The shape is.** This link has two normals: a
quiet daytime pattern and a loud nightly one, and a single line cannot describe
both. So the fix is to change what the alert is comparing against.

The lowest effort version is duration. Requiring the condition to hold for, say,
thirty minutes removes most short peaks and keeps the six hour event, and most
alerting systems support it with one setting. It does not fix the backup, which
lasts longer than thirty minutes, but it halves the noise for very little work.

The version that actually fixes it is comparing against this hour on this day.
Two in the morning on a weekday has a baseline of its own, the backup fits it, and
day five's afternoon does not fit the afternoon baseline at 65 per cent. That is
the same fault the figure showed, now expressed as something a system can decide.

The schedule based suppression is worth mentioning because somebody will propose
it and it is not wrong. Raising the threshold between two and four in the morning
takes five minutes and works until the backup window moves, at which point it
fails silently and nobody finds out for months. Take it as an interim measure and
write down when to revisit it.

**And then there is the question the ticket does not ask.** Nobody noticed a six
hour incident until users called, on a link that was being monitored the whole
time. The alerting failed, and so did everything else: no dashboard was being
watched, no anomaly was flagged, and the four months of nightly false alarms had
already established that alerts from this system do not mean much. Fixing the
threshold fixes the first of those. The other two are about what people do with
the output, and no configuration change reaches them.

## Try it

**Plot one week of one metric.** Anything, from any system you have. Look at the
shape before deciding where a line would go, because the shape is usually the
argument against a line.

**Wrap a counter on paper.** Take a link speed, divide 4 294 967 296 by the bytes
per second, and find the wrap time. Doing it once for the speeds you actually run
makes the 64-bit rule stop being arbitrary.

**Audit one alert.** Pick one that fires often and ask what action it is supposed
to prompt. Alerts that prompt no action are the ones to delete, and deleting them
is what makes the rest readable.

## Check yourself

<details class="qa">
<summary>A link is at 412 milliseconds of latency. Is that a problem?</summary>

There is no answer without a baseline. On a satellite link or a long haul path
that has always run near 400 milliseconds, it is an ordinary reading. On a link
that has not exceeded 90 milliseconds in a fortnight, it is the worst reading in
the record.

That is the whole argument for collecting a baseline before you need it. The
figure only becomes evidence once there is something to compare it against, and
the comparison cannot be collected retrospectively.

</details>

<details class="qa">
<summary>An alert at 70 per cent utilisation fires nightly on a backup job and missed a six hour incident that peaked at 65. What do you change?</summary>

Not the number. Raising it widens the daytime blind spot and lowering it alerts on
every ordinary afternoon.

The metric has two normals, one for the backup window and one for the working day,
so the alert has to compare against the pattern rather than against a constant.
Alerting on a departure from this hour on this day catches the incident and
ignores the backup. Requiring the condition to persist is a cheaper partial fix
that removes short peaks without touching the backup.

</details>

<details class="qa">
<summary>Why is polling ifInOctets on a gigabit interface every five minutes unreliable?</summary>

Because it is a 32-bit counter. It holds 4 294 967 295 and starts again, which at
a gigabit takes about thirty four seconds, so a five minute interval can contain
eight wraps.

Nothing in the counter records how many times it went round. The monitoring system
sees a smaller second sample, assumes one wrap, and reports a rate roughly a tenth
of the real one, which looks entirely plausible. The 64-bit objects in the
extension table exist for exactly this, and RFC 2863 recommends them above about
20 Mbit/s.

</details>

<details class="qa">
<summary>Two polls a few seconds apart return very different counter values from an interface with steady traffic. What is happening?</summary>

The agent is answering from a cache. Rebuilding the interface table for every
request is expensive on a device with many ports, so many agents refresh it on an
interval and answer from what they last built.

Polling faster than that interval gives one sample containing several seconds of
traffic and the next containing none, so a steady link produces a graph
alternating between zero and double. The fix is to poll no faster than the agent
refreshes.

</details>

<details class="qa">
<summary>What does a SIEM do that a syslog server does not?</summary>

Correlation. A syslog server receives and stores messages from many devices, which
is worth doing on its own, because a device that has crashed cannot be logged into
and its last messages are already elsewhere.

A SIEM normalises messages from different sources into a common shape and applies
rules across them, so events on separate devices can combine into one finding. A
failed login here and a successful one there become a single item rather than two
lines in two files.

</details>

## References

- [RFC 2863](https://www.rfc-editor.org/rfc/rfc2863) - IETF, the interfaces group MIB, which defines both the 32-bit and 64-bit octet counters and states where each is appropriate. Free. Accessed 2026-08-12.
- [RFC 5424](https://www.rfc-editor.org/rfc/rfc5424) - IETF, the syslog protocol, including the facility and severity fields. Free. Accessed 2026-08-12.
- [RFC 3164](https://www.rfc-editor.org/rfc/rfc3164) - IETF, describing what the original BSD syslog implementations sent, which is still what a lot of equipment sends. Free. Accessed 2026-08-12.
- [NIST SP 800-92](https://csrc.nist.gov/pubs/sp/800/92/final) - NIST, on log management, including aggregation and retention. Free. Accessed 2026-08-12.
- [Get-NetAdapterStatistics](https://learn.microsoft.com/powershell/module/netadapter/get-netadapterstatistics) - Microsoft, for the Windows counters. Accessed 2026-08-12.

**Pictures.** A freely licensed file from Wikimedia Commons, downloaded and served
from this site rather than linked across to somebody else's server. Cropped to the
status table and otherwise unaltered.

- [Nagios Core, current network status](https://commons.wikimedia.org/wiki/File:Nagios_Core_-_Current_Network_Status.png) by Dr.Lorenzeti, [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/).

**Where the output came from.** The counter polls ran on the `managed-lan`
namespace topology through `blog/scripts/netlab.sh`, with a real manager polling a
real agent, which is why the stale answer is a genuine one rather than a
constructed example. The two object definitions came from a Debian 13 container
through `blog/scripts/capture.sh` with the setup script
`blog/scripts/setups/snmp-agent.sh`, and they are the MIB module's own text rather
than a paraphrase. The wrap figure is arithmetic rather than a capture: 4 294 967
296 bytes at 125 000 000 bytes per second is 34.36 seconds, and the two poll
values in it are computed from that rate, because reproducing the effect would
need a saturated gigabit interface for five minutes.

**If you also work on Linux.** [Monitoring concepts](/learn/linux-plus/monitoring-concepts)
on the Linux+ track covers the same ideas from the host's point of view, where the
metrics are processes and memory rather than interfaces, and the argument about
baselines and thresholds is identical.
