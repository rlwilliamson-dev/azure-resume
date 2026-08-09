---
title: "Nobody noticed until a customer called"
description: "Monitoring is the difference between finding out from a dashboard and finding out from a complaint. What to measure, what an SLO actually commits you to, how an agent reports, and why the alert nobody acts on is worse than no alert."
track: "linux-plus"
level: "working"
order: 650
objectives:
  - "Distinguish metrics, logs, events, and traces, and say what each is for"
  - "Define SLI, SLO, and SLA, and explain how they relate"
  - "Explain error budgets and what they are used to decide"
  - "Describe agent-based and agentless collection, and the trade"
  - "Read an SNMP query, and say what a MIB and an OID are"
  - "Say why an alert nobody acts on is worse than no alert"
prerequisites: ["reading-logs-to-find-a-cause", "common-network-services"]
tags: ["linux", "linux-plus", "monitoring", "observability", "snmp"]
updated: 2026-08-09
draft: false
examObjectives:
  - exam: "xk0-006"
    domain: "5.0"
    objective: "5.1"
sources:
  - title: "snmpd(8)"
    url: "https://net-snmp.sourceforge.io/docs/man/snmpd.html"
    publisher: "Net-SNMP"
    accessed: 2026-08-09
    tier: 1
  - title: "snmpwalk(1)"
    url: "https://net-snmp.sourceforge.io/docs/man/snmpwalk.html"
    publisher: "Net-SNMP"
    accessed: 2026-08-09
    tier: 1
  - title: "RFC 3411, SNMP management framework architecture"
    url: "https://www.rfc-editor.org/rfc/rfc3411"
    publisher: "IETF"
    accessed: 2026-08-09
    tier: 1
  - title: "Google SRE Book, chapter 4: Service Level Objectives"
    url: "https://sre.google/sre-book/service-level-objectives/"
    publisher: "Google"
    accessed: 2026-08-09
    tier: 1
symptoms:
  - symptom: "Outage discovered by a customer rather than by monitoring"
    anchor: "what-to-measure"
  - symptom: "Alerts fire constantly and are routinely ignored"
    anchor: "thresholds-alerts-and-the-human-at-the-end"
  - symptom: "Monitoring system itself is slow or expensive to query"
    anchor: "what-to-measure"
---

> **Before you read.** The database filled its disk at 02:14. Writes started
> failing at 02:15. At 09:40 a customer emailed to ask why their orders had not
> gone through overnight, and that email is how you found out.
>
> Seven and a half hours of a failure nobody saw. The disk had been at 94
> percent for a fortnight.

Monitoring exists so the machine tells you before a person does. That is the
whole justification, and everything else in this lesson is detail about how to
do it without generating so much noise that you stop listening.

The trap is that monitoring feels like a solved problem once a dashboard exists.
A dashboard nobody looks at during the 4,000 minutes a week nothing is wrong is
not monitoring, it is decoration.

### Some words you will need

<dl class="terms">
<dt>metric</dt>
<dd>A number sampled over time. CPU percent, requests per second, queue depth.</dd>
<dt>log</dt>
<dd>A timestamped record of something that happened, usually text.</dd>
<dt>event</dt>
<dd>A discrete occurrence worth noting: a deploy, a reboot, a failover.</dd>
<dt>trace</dt>
<dd>The path one request took through several services, with timing at each hop.</dd>
<dt>SLI</dt>
<dd>Service level indicator. The thing you measure.</dd>
<dt>SLO</dt>
<dd>Service level objective. The target you set yourself for that measurement.</dd>
<dt>SLA</dt>
<dd>Service level agreement. A contract with a customer, with consequences attached.</dd>
<dt>error budget</dt>
<dd>How much failure the SLO permits. Spending it is allowed; that is what it is for.</dd>
<dt>agent</dt>
<dd>Software on the monitored host that collects and reports.</dd>
<dt>OID</dt>
<dd>Object identifier. A dotted-number address for one value in SNMP.</dd>
<dt>MIB</dt>
<dd>Management information base. The dictionary mapping names to those numbers.</dd>
</dl>

## What breaks without this

**Customers become your monitoring.** They are slower than a check and much more
expensive.

**Failures are found in the wrong order.** The consequence is noticed first, and
the cause is three layers down.

**Capacity arrives as a surprise.** A disk that filled had been filling for
weeks, visibly, to nobody.

**Nobody can say whether it is better.** Without a baseline, "it feels faster
since the change" is the only evidence available.

**Alerts get muted.** Once a pager fires for things that do not matter, it stops
being read for the things that do.

## What to measure

Four kinds of signal, and using the wrong one is why some questions are
impossible to answer.

| Signal | Answers | Cost | Watch out for |
| --- | --- | --- | --- |
| **Metric** | "How much, how often, how long?" | Cheap, aggregated | Cannot tell you *why* |
| **Log** | "What exactly happened, in what order?" | Expensive at volume | Useless unqueryable |
| **Event** | "What did we change, and when?" | Trivial | Almost always missing |
| **Trace** | "Where did the 3 seconds go?" | Moderate, needs instrumentation | Only useful across services |

Metrics are what you alert on, because they are cheap enough to keep at high
resolution and comparable over time. Logs are what you diagnose with, once an
alert has told you where to look. That division of labour is the practical core
of the whole subject.

Events are the cheapest signal and the most commonly missing. If your graphs
carry a vertical line every time something was deployed, "what changed" from
lesson 63 answers itself; without it, you correlate by memory.

**The golden signals** are a good default set when you do not know what to
measure. For any request-serving system: **latency**, **traffic**, **errors**,
and **saturation**. Four numbers, and between them they catch most of what goes
wrong.

For a machine rather than a service, the equivalent list is CPU, memory, disk
space, disk latency, network throughput and errors, and whether the processes
that should exist do. Lesson 75's USE method is the systematic version.

## SLI, SLO, SLA

Three terms that get used interchangeably and should not be, because only one of
them has lawyers attached.

An **SLI** is a measurement. "The proportion of HTTP requests that returned a
status below 500, measured at the load balancer." Note how specific that is:
measured where, over what, counting what. A vague SLI produces arguments later.

An **SLO** is the target you hold yourself to. "99.9 percent of requests succeed,
measured over 30 days." It is internal, you choose it, and you can change it.

An **SLA** is a contract with a customer that includes a remedy when you miss:
service credits, a refund, a right to terminate. It is a business document, and
it should always be looser than your SLO. If they are equal, missing your
internal target by a fraction costs money immediately.

The relationship worth remembering: SLI is measured, SLO is targeted, SLA is
promised, and SLA should be the loosest of the three.

**Error budget** is the useful idea that falls out of an SLO. If the target is
99.9 percent over 30 days, the budget is 0.1 percent, which is about 43 minutes
of failure a month.

That number is a decision-making tool rather than a scoreboard. Budget
remaining means you can afford a risky migration this week. Budget exhausted
means stop shipping features and spend the effort on reliability. It converts an
argument about whether to prioritise stability into a number both sides already
agreed to.

**Know what the nines cost**, because people commit to them casually:

| SLO | Downtime per month | Per year |
| --- | --- | --- |
| 99% | about 7 hours | about 3.7 days |
| 99.9% | about 43 minutes | about 8.8 hours |
| 99.95% | about 22 minutes | about 4.4 hours |
| 99.99% | about 4 minutes | about 53 minutes |
| 99.999% | about 26 seconds | about 5 minutes |

Four minutes a month does not permit a human to wake up, read a page, log in,
and diagnose anything. Past about 99.95 percent you are no longer buying
monitoring, you are buying automatic failover, and the cost goes up sharply at
each nine.

<details class="deeper">
<summary>If you already administer Linux: alert fatigue, and the alert that is worse than nothing</summary>

The failure mode of monitoring is not missing alerts. It is having so many that
nobody reads them, and the mechanism is worth understanding because every estate
drifts toward it.

An alert fires. It turns out not to matter. That happens twenty more times.
Now, when it fires and does matter, the engineer's first thought is "that thing
again" and they finish what they were doing. **The alert has become negative
information**, because it has trained a specific person not to act.

**The rule that fixes most of it:** every alert must name an action a human
should take now. If the answer to "what do I do about this" is "nothing, it
clears itself", it is not an alert, it is a graph.

Practical tests for whether something deserves to page:

- Is a person needed, right now? If it can wait until morning, it is a ticket.
- Is it a symptom customers experience, or a cause? Page on symptoms. A full
  disk that nothing is using yet is a ticket; failing checkouts is a page.
- Would you be glad to be woken for this? That question resolves most arguments.
- Has it fired more than twice this month without action? Fix it or delete it.

**Alerting on causes rather than symptoms is the commonest design error**,
because causes are easier to measure. You end up with forty alerts for the forty
ways a service can break, most of which fire during normal operation, instead of
one alert on the thing that actually matters: are requests succeeding?

**Techniques that reduce noise without reducing coverage:**

- **Alert on a duration, not an instant.** "Error rate above 5 percent for 10
  minutes" survives a blip; "above 5 percent" pages on one bad second.
- **Burn rate over threshold.** Instead of "errors above X", alert when the error
  budget is being consumed fast enough to exhaust the month. This ignores small
  blips and catches slow bleeds that never cross a static line.
- **Inhibition.** When a host is down, suppress the twenty service alerts on that
  host. Alertmanager and most platforms support this and few teams configure it.
- **Grouping.** One notification for fifty hosts failing the same check, not
  fifty.
- **Maintenance windows.** Otherwise every planned change trains people to ignore
  the pager.

**And monitor the monitoring.** A collector that has silently stopped looks
exactly like a healthy estate: no alerts, flat graphs. A dead-man's switch, an
alert that fires when a heartbeat *stops* arriving, is the standard answer, and
it is the one check most worth having.

</details>

## Thresholds, alerts, and the human at the end

A check produces a value. A threshold turns that value into a state. A
notification delivers that state to somebody. Those are three separable things
and confusing them causes most bad monitoring.

Thresholds are harder than they look. Static ones are simple and wrong at the
edges: 80 percent disk is fine on a 20 TB archive and an emergency on a 20 GB
root filesystem. The better forms:

- **Rate of change**, which catches the problem earlier. "Disk will be full in
  four hours at the current rate" is far more useful than "disk is at 85
  percent", and it is what would have caught the fortnight of 94 percent in the
  opening.
- **Relative to baseline.** "Traffic is 60 percent below the same hour last
  week" catches failures that no absolute number would.
- **Percentiles, not averages.** An average response time hides the tail
  completely. If 1 percent of requests take 30 seconds, the mean barely moves
  and 1 percent of your users are furious. Alert on p95 or p99.

That last point is worth dwelling on because averages are the default in most
tools. A service where 99 percent of requests take 50 ms and 1 percent take 30
seconds has a mean around 350 ms, which looks fine and is not.

**Health checks** are the simplest form of monitoring and the most direct. Ask
the service whether it is working, from outside:

```bash
curl -fsS -o /dev/null -w '%{http_code} %{time_total}s\n' https://example.com/healthz
```

`-f` makes curl exit non-zero on an HTTP error, which is what turns it into a
check rather than a fetch. A useful health endpoint reports on the service's
dependencies as well as itself, and lesson 61's distinction applies: a liveness
check that tests the database will restart your whole fleet when the database
blips.

## How the data gets there

Two models, and the choice is mostly about access and trust.

**Agent-based** means software runs on the host, collects locally, and reports
outward. It sees everything: per-process detail, filesystem internals, logs.
It also means installing, updating, and securing software on every machine, and
the agent itself consumes resources and can fail.

**Agentless** means something queries the host from outside, over SSH, SNMP, an
API, or a simple TCP check. Nothing to install and nothing to keep patched. It
sees much less, it needs credentials that reach in from elsewhere, and per-host
detail is limited.

Most estates use both: agents on servers you own, agentless for network
equipment, appliances, and anything you cannot install software on.

**Push and pull** is a separate axis that gets confused with the first one. In a
push model the host sends data outward, which works through NAT and firewalls
and makes it hard to notice a host that stopped sending. In a pull model the
collector scrapes each host on a schedule, which gives you a free liveness
signal, because a target that cannot be scraped is visibly down. Prometheus
pulls; StatsD and most log shippers push.

<details class="deeper">
<summary>If you already administer Linux: what to actually put on a box, and the checks that earn their place</summary>

"Monitor the server" is not a task anybody can start. Here is a concrete set
that catches most of what genuinely goes wrong, in the order it pays to add
them.

**Tier one, the things that page:**

| Check | Why it earns a page |
| --- | --- |
| Host unreachable | Everything else is moot |
| Filesystem projected full within N hours | Rate, not percentage, per lesson 68 |
| A required service not running | `systemctl is-failed`, not `is-active`, per lesson 69 |
| The service's port not accepting connections | The only real proof it works |
| OOM kills in the kernel log | `journalctl -k --grep='Killed process'` |
| Certificate expiring within 14 days | The classic scheduled outage |

**Tier two, the things that open a ticket:** inode usage, disk latency, swap
traffic, RAID degraded, failed login spikes, package updates pending, NTP
unsynchronised, and a filesystem mounted read-only.

**That last one is worth calling out.** A filesystem that remounted read-only
after an I/O error is a machine that looks fine, serves reads, and fails every
write. It is easy to check and almost nobody does:

```bash
findmnt -t ext4,xfs -o TARGET,OPTIONS | grep -w ro
```

**Two general points about check design.** Check from the outside wherever you
can: an agent asking the local kernel whether nginx is running is much weaker
evidence than something on another host completing a request. And check the
thing users do, not a proxy for it. "Can I complete a login" beats "is the auth
service process alive", because the second is true during most outages of the
first.

**On synthetic versus real user monitoring**, since both have a place. Synthetic
checks run on a schedule from a fixed location and give you a clean, comparable
signal that works at 3am with no traffic. Real user monitoring reports what
people actually experienced, including the browser and network conditions you
cannot simulate, and it goes quiet exactly when nobody is using the site, which
might be because it is broken. Synthetic tells you the service is up; real user
data tells you it is good. Neither substitutes for the other.

**And measure the things nobody thinks of until they bite:** file descriptor
usage against the limit, PID count against `pids.max`, connection pool
saturation, queue depth, and certificate expiry. Every one of them is a hard
ceiling that produces a baffling failure at the moment it is reached, and every
one is trivial to graph in advance.

</details>

## SNMP

Simple Network Management Protocol is old, still ubiquitous, and the exam names
it. Every switch, router, printer, UPS, and appliance speaks it, which is why it
survives.

The model has three parts. An **agent** runs on the device. A **manager** queries
it. A **MIB** is the dictionary describing what can be asked for.

Every value has an **OID**, a dotted number identifying it in a global tree.
Names are a convenience the MIB provides on top:

<details class="predict">
<summary>An agent is asked for its location, its contact, and its uptime. Where do the first two values come from?</summary>

```bash
# AlmaLinux 10.2, aarch64
$ /usr/sbin/snmpd -Lf /dev/null 127.0.0.1:1161; sleep 3; echo "--- ask the agent who and where it is ---"; snmpget -v2c -c public 127.0.0.1:1161 SNMPv2-MIB::sysLocation.0 SNMPv2-MIB::sysContact.0 SNMPv2-MIB::sysUpTime.0
--- ask the agent who and where it is ---
SNMPv2-MIB::sysLocation.0 = STRING: Rack 4, London
SNMPv2-MIB::sysContact.0 = STRING: ops@example.com
DISMAN-EVENT-MIB::sysUpTimeInstance = Timeticks: (303) 0:00:03.03
```

</details>

Those three values came from the agent's own configuration, which is exactly how
an inventory system learns where a device physically is. `sysUpTime` in
Timeticks is hundredths of a second, and a device whose uptime has reset since
the last poll rebooted without telling anybody.

<details class="predict">
<summary>The same value is requested with <code>-On</code>. What comes back, and what does <code>snmpwalk</code> return for a whole subtree?</summary>

```bash
# AlmaLinux 10.2, aarch64
$ /usr/sbin/snmpd -Lf /dev/null 127.0.0.1:1161; sleep 3; echo "--- the same value, by number instead of by name ---"; snmpget -v2c -c public -On 127.0.0.1:1161 SNMPv2-MIB::sysLocation.0; echo "--- walk a subtree: every network interface the agent knows ---"; snmpwalk -v2c -c public 127.0.0.1:1161 IF-MIB::ifDescr
--- the same value, by number instead of by name ---
.1.3.6.1.2.1.1.6.0 = STRING: Rack 4, London
--- walk a subtree: every network interface the agent knows ---
IF-MIB::ifDescr.1 = STRING: lo
IF-MIB::ifDescr.2 = STRING: eth0
```

</details>

`SNMPv2-MIB::sysLocation.0` and `.1.3.6.1.2.1.1.6.0` are the same thing. The
number is what actually travels on the wire; the name only exists because a MIB
file on *your* machine translates it. That is why a device can answer perfectly
while your tool prints raw numbers: you are missing its vendor MIB, not talking
to a broken device.

`snmpwalk` retrieves an entire subtree rather than one value, which is how you
discover what a device offers without knowing its OIDs in advance. Here it found
two interfaces and their names.

**The other direction matters too.** A **trap** is the agent sending an
unsolicited message to the manager when something happens, rather than waiting
to be asked. Polling every five minutes means a five-minute worst case; a trap
arrives immediately. Traps are UDP and unacknowledged, so they can be lost,
which is why serious setups use both: traps for speed, polling for truth.
SNMPv2c has `INFORM`, an acknowledged trap, for exactly this reason.

**On versions, since this is a security question as much as a protocol one.**
v1 and v2c authenticate with a **community string**, which is a password sent in
clear text, and `public` is the default on far too many devices. v3 adds real
authentication and encryption. Use v3 where the device supports it, and where
you are stuck with v2c, restrict by source address and never expose UDP 161 to
anything untrusted. The capture above used `public` bound to loopback, which is
the only context where that is acceptable.

<details class="deeper">
<summary>If you already administer Linux: cardinality, and how a monitoring system becomes the outage</summary>

Metric systems fall over in a way that surprises people, and the cause is almost
always cardinality.

A time series is identified by its name plus its labels. `http_requests_total`
with labels `method="GET"` and `status="200"` is one series. Every distinct
combination of label values is a **separate** series, stored separately, indexed
separately.

So the count multiplies. Five methods times six statuses times twenty endpoints
is 600 series, which is fine. Add `user_id` as a label and it is 600 times your
user count, which is not.

**Labels that will destroy you**, and they are exactly the ones that feel
useful:

- User IDs, session IDs, request IDs, trace IDs
- Full URL paths with identifiers in them, `/orders/8837291`
- Timestamps or anything containing one
- Error messages as a label value
- Container IDs in an environment that restarts containers frequently
- IP addresses, in anything internet-facing

**The symptom is that the monitoring system becomes the incident.** Ingest slows,
queries time out, the collector runs out of memory, and you have lost visibility
at the moment you need it. Worse, the damage outlives the fix: those series stay
in the index until retention expires.

**The rules that keep it bounded:**

- Labels are for things with a small, stable set of values. Environment, region,
  service, status class.
- Template the high-cardinality part out. `/orders/:id`, not `/orders/8837291`.
- Anything genuinely high-cardinality belongs in **logs or traces**, which are
  designed for it. This is the practical reason the four signal types exist.
- Watch your own series count as a metric. Sudden growth is a bad deploy.

**Retention and resolution are the other half of the cost.** Keeping every
sample at 10-second resolution for two years is enormous and nobody queries it.
Downsample: full resolution for a fortnight, five-minute averages for a quarter,
hourly for a year. Most systems do this natively and most teams never configure
it.

**And the boring point that matters most:** the monitoring stack needs to be more
reliable than the thing it watches, and it should not share its failure domain.
Monitoring hosted on the cluster it monitors tells you nothing at the exact
moment the cluster dies.

</details>

## Getting it out to a person

The last hop is delivery, and it is where good monitoring is often let down.

A **notification** is the message. A **channel** is how it travels: email, chat,
SMS, a push to a paging app. **On-call** is the rota deciding who receives it,
and **escalation** is what happens when they do not respond.

**Webhooks** are how monitoring systems talk to everything else. The system
makes an HTTP POST with a JSON body describing the alert, and the receiver
decides what to do: open a ticket, post to a channel, trigger an automated
remediation. It is the general-purpose integration, and it is why every
monitoring tool can talk to every chat tool without either knowing about the
other.

Two things worth getting right at this hop. Route by severity rather than
sending everything everywhere, so a page and a ticket travel differently. And
make sure the notification carries enough to act on: which host, which service,
what threshold, what the value is now, and a link to the runbook. An alert
saying "CheckDiskSpace CRITICAL" costs ten minutes before the work even starts.

## Across distributions

The concepts are vendor-neutral and the packaging is not. What changes is the
name of the package and where its configuration lands.

| | RHEL family | Debian family |
| --- | --- | --- |
| SNMP agent | `net-snmp`, service `snmpd` | `snmpd`, service `snmpd` |
| SNMP client tools | `net-snmp-utils` | `snmp` |
| MIB files | `net-snmp-libs`, some non-free ones absent | `snmp-mibs-downloader`, **disabled by default** |
| Agent configuration | `/etc/snmp/snmpd.conf` | `/etc/snmp/snmpd.conf` |
| Local resource metrics | `sysstat`, providing `sar` and `iostat` | `sysstat`, **not installed by default** |
| Firewall front end for UDP 161 | `firewall-cmd --add-service=snmp` | `ufw allow 161/udp` |

**The MIB row explains a specific confusing afternoon.** On Debian and Ubuntu the
bundled MIBs are commented out of `/etc/snmp/snmp.conf` for licensing reasons, so
`snmpwalk` returns dotted numbers on a freshly installed system and everything
looks broken. It is not: the agent is answering correctly and the local
dictionary is switched off. Comment out the `mibs :` line, or install
`snmp-mibs-downloader`.

`sysstat` is worth installing deliberately on both families. It is what records
history rather than a snapshot, and the moment you want it is always after the
incident rather than before.

## Prove it

Monitoring that is not itself monitored is a rumour. These are the checks that
tell you the pipeline works end to end, rather than that it is installed:

```bash
# Is the agent running, and listening where you think
systemctl is-active snmpd
ss -lunp | grep 161

# Does it answer, and does the name resolve to a number
snmpwalk -v3 -l authPriv -u monitor -a SHA -A '<pass>' -x AES -X '<pass>' host sysUpTime
snmpget -v3 ... host .1.3.6.1.2.1.1.3.0     # same value, raw OID

# Did the metric actually arrive at the far end
# (in the monitoring system: query the series for the last 5 minutes)

# Is the alert path live, rather than merely configured
# Fire a deliberate test alert and confirm a human device buzzed
```

**The last two are the ones people skip.** An agent that runs, a metric that is
collected, and an alert rule that evaluates all prove nothing about whether a
notification reaches a person at 3am. Test the delivery path on purpose,
periodically, and keep a dead man's switch running so silence is distinguishable
from health.

## What trips people up

### 1. Alerting on causes rather than symptoms

A disk at 85 percent is a cause, and it may never become a problem. Alert on what
a user experiences, then use the cause metrics to diagnose it. The test for
whether an alert should page: if it fires at 3am and the answer is "look at it in
the morning", it was never a page.

### 2. Alerting on averages

An average hides the tail, which is where the complaints come from. One request
in a hundred taking thirty seconds barely moves the mean and ruins the day for
one percent of users. Alert on the 99th percentile.

### 3. High-cardinality labels

Attaching a user ID, a session ID, or a full URL path as a label creates one time
series per distinct value. That multiplies until the monitoring system becomes
the outage it was installed to report. High-cardinality data belongs in logs or
traces, which are built for it.

### 4. SNMP v2c on an untrusted network

The community string is a password sent in clear text, and `public` is still the
default in more places than anyone would like. Use v3, which adds authentication
and encryption, or restrict the agent by source address at minimum.

### 5. Treating silence as good news

A collector that died looks exactly like an estate with no problems. The
distinguishing mechanism is a heartbeat that alerts when it stops arriving, and
it needs to exist before the day it matters.

### 6. Believing a trap arrived

Traps are unacknowledged UDP, so they are lost quietly. Use traps for speed, use
polling for truth, and use `INFORM` when you need an acknowledged version.

## Work it through

An alert fires at 02:40: `HighMemoryUsage on app-07, WARNING`. It has fired
eleven times this month and nobody has ever acted on it. Tonight, users are
genuinely reporting timeouts.

Reason it out before reading on.

**The shape of the problem matters before the metric does.** An alert that has fired eleven times
with no action is not information, it is training: the on-call engineer has
learned to dismiss it, which is why tonight's real incident got the same
treatment. The monitoring fault and the service fault are two separate problems
and both need fixing.

**The alert may never have measured the right thing.** Memory
alerts written against the `free` column fire constantly on healthy Linux
machines, because the kernel spends free memory on page cache by design:

```bash
free -h                      # compare 'free' against 'available'
vmstat 1 5                   # si and so: is anything actually swapping
```

If `available` is comfortable and `si`/`so` are zero, the alert has been wrong
all eleven times and the timeouts have another cause entirely.

**Go to the symptom the users described.** They reported timeouts, so
measure latency rather than memory:

```bash
journalctl -u app -p warning --since -30min
ss -ti state established '( dport = :5432 )' | head    # RTT and retransmits
```

**The fix has two halves.** Rewrite the alert against `available` and against
sustained swap traffic, so it means something when it fires. Then chase the
timeouts against a latency signal, which is what should have been alerting all
along.

The general lesson: an alert nobody acts on is worse than no alert, because it
consumes attention and trains people to ignore the channel it arrives on. Every
alert that fires without action is either a bug in the alert or a missing
runbook, and both are fixable.

## Try it

Optional, and a container or VM is enough for all of it.

1. Install `snmpd` and query it from the same machine with `snmpwalk` against
   `sysUpTime`. Get it working with v3 rather than v2c, because the v3 argument
   list is the part worth having typed once.
2. Break the naming deliberately. Comment the MIB configuration out, re-run the
   same query, and watch readable names become dotted numbers while the value
   stays identical. Put it back.
3. Run `free -h` on an idle machine and write down the `free` and `available`
   figures. Then read a file larger than the remaining free memory with
   `cat bigfile > /dev/null` and read them again.

**Verification step.** Step 3 is right when `free` has dropped substantially,
`available` has barely moved, and you can say in one sentence why an alert
written against the first number would now be firing for no reason.

## For the exam

**Metrics for alerting, logs for diagnosis.** Events record changes; traces
follow one request across services.

**SLI is measured, SLO is your target, SLA is a contract with penalties.** The
SLA should be looser than the SLO.

**Error budget is the failure the SLO permits**, and it is used to decide
whether to ship or to stabilise.

**Golden signals: latency, traffic, errors, saturation.**

**Alert on symptoms, not causes**, and only when a human must act now.

**Agent-based sees more and must be maintained; agentless installs nothing and
sees less.**

**Pull gives you liveness for free; push traverses firewalls.**

**SNMP: agent on the device, manager queries it, MIB translates names to OIDs.**

**A trap is unsolicited, sent by the agent.** Polling is the manager asking.

**SNMP v1 and v2c use a clear-text community string; v3 adds authentication and
encryption.**

**Alert on percentiles, not averages.**

<details class="qa">
<summary>Check yourself</summary>

**Difference between an SLO and an SLA?**
An SLO is an internal target you set and can change. An SLA is a contract with a
customer carrying a remedy when you miss it. Keep the SLA looser.

**Your SLO is 99.9 percent monthly. How much downtime is that, and what is the
budget for?**
About 43 minutes. It is the error budget, used to decide whether to take risks
this month or spend the effort on reliability.

**Why alert on p99 rather than the mean?**
An average hides the tail. If 1 percent of requests take 30 seconds the mean
barely moves, and those users are still having a terrible time.

**Name the four golden signals.**
Latency, traffic, errors, saturation.

**Why is an alert that fires often and needs no action worse than no alert?**
It trains people to ignore that alert, so it is negative information when it
finally matters.

**Should you page on a disk at 85 percent?**
Usually not. Page on symptoms customers feel. A projection like "full in four
hours" is more useful than a static percentage, and a disk nothing is filling is
a ticket.

**Agent-based versus agentless, one advantage each?**
An agent sees per-process and filesystem detail. Agentless installs nothing and
has nothing to patch on the host.

**Which of push and pull tells you a host has died, and why?**
Pull. A target that cannot be scraped is visibly down. With push, a silent host
looks the same as a quiet one.

**What is an OID, and what is a MIB?**
An OID is a dotted-number address for one value. A MIB is the dictionary that
maps readable names onto those numbers, and it lives on the querying machine.

**Your SNMP tool prints raw numbers instead of names. What is wrong?**
Nothing on the device. You are missing its MIB file locally.

**What is an SNMP trap, and what is its weakness?**
The agent sending a message unprompted when something happens. It is
unacknowledged UDP, so it can be lost. Use traps for speed and polling for
truth, or `INFORM` for an acknowledged version.

**Why avoid v2c on an untrusted network?**
The community string is a password in clear text. Use v3, or restrict by source
address.

**What is cardinality and why does it matter?**
The number of distinct label combinations, each stored as its own time series.
High-cardinality labels like user ID multiply series until the monitoring system
becomes the outage.

**Where does high-cardinality data belong instead?**
Logs or traces, which are built for it.

**Your monitoring has been silent for three days. Good news?**
Not necessarily. A dead collector looks identical to a healthy estate. A
dead-man's switch that alerts when the heartbeat stops is what distinguishes
them.

</details>

## Where this sits

Lesson 63 gave you a method for when something is already broken; this lesson is
about finding out before somebody phones. Lesson 65 is where the logs referred
to here are queried, and lessons 75 and 76 supply the metrics worth watching on
a single machine.

The next lesson starts the layer-by-layer walk through what actually fails,
beginning with a machine that never reaches a login prompt.


## References

- [snmpd(8)](https://net-snmp.sourceforge.io/docs/man/snmpd.html) - Net-SNMP. Accessed 2026-08-09.
- [snmpwalk(1)](https://net-snmp.sourceforge.io/docs/man/snmpwalk.html) - Net-SNMP. Accessed 2026-08-09.
- [RFC 3411, SNMP management framework architecture](https://www.rfc-editor.org/rfc/rfc3411) - IETF. Accessed 2026-08-09.
- [Google SRE Book, chapter 4: Service Level Objectives](https://sre.google/sre-book/service-level-objectives/) - Google. Accessed 2026-08-09.
> **The commands here were run on a real machine, not written from memory.** The
> SNMP transcripts come from AlmaLinux 10.2 on aarch64, with `snmpd` started on
> loopback port 1161 inside the container, which is why the agent had been up for
> three seconds when it was asked. `Rack 4, London` and the contact address are
> values from that agent's own configuration file, which is how a real inventory
> system learns where a device is. The community string `public` is bound to
> loopback here, and that is the only context in which it would be acceptable.
