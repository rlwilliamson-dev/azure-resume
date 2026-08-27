---
title: "Filtering at the edge"
description: "Why rule order is the whole of a firewall on one platform and means nothing on another, what a shadowed rule looks like when you can see its counter, the difference between signature and anomaly detection, and the web filter that blocks the thing the business runs on."
deck: "The rule that allows it is on line four hundred. The rule that denies it is on line three"
track: "security-plus"
level: "working"
order: 510
objectives:
  - "Walk a packet down an ordered rule list and say which rule decides it"
  - "Recognise a shadowed rule and say what evidence proves it never fires"
  - "Explain what a screened subnet is for and what it assumes"
  - "Distinguish signature detection from anomaly detection by what each one misses"
  - "Say what a web filter categorises and where the categorisation goes wrong"
  - "Compare the ordered model with the models Windows and macOS actually use"
prerequisites: ["the-monitoring-tools"]
tags: ["security-plus", "security", "operations", "network-security"]
updated: 2026-08-25
draft: false
examObjectives:
  - exam: "sy0-701"
    domain: "4.0"
    objective: "4.5"
sources:
  - title: "SP 800-41 Rev. 1, Guidelines on Firewalls and Firewall Policy"
    url: "https://csrc.nist.gov/pubs/sp/800/41/r1/final"
    publisher: "NIST"
    accessed: 2026-08-25
    tier: 1
  - title: "SP 800-94, Guide to Intrusion Detection and Prevention Systems"
    url: "https://csrc.nist.gov/pubs/sp/800/94/final"
    publisher: "NIST"
    accessed: 2026-08-25
    tier: 1
  - title: "nft manual page"
    url: "https://www.netfilter.org/projects/nftables/manpage.html"
    publisher: "Netfilter project"
    accessed: 2026-08-25
    tier: 1
  - title: "Windows Firewall rule precedence"
    url: "https://learn.microsoft.com/en-us/windows/security/operating-system-security/network-security/windows-firewall/rules"
    publisher: "Microsoft"
    accessed: 2026-08-25
    tier: 1
  - title: "pf.conf manual page"
    url: "https://man.openbsd.org/pf.conf"
    publisher: "OpenBSD project"
    accessed: 2026-08-25
    tier: 2
symptoms:
  - symptom: "A firewall rule exists and has no effect"
    anchor: "the-rule-that-never-fires"
  - symptom: "A business site is blocked by the web filter and nobody can say why"
    anchor: "web-filters-and-the-category-that-is-wrong"
---

> **Before you read.** A firewall configuration has four hundred rules. Line three
> denies traffic to a subnet. Line four hundred allows it. Somebody is arguing
> about which one applies.
>
> **What do you need to know before you can answer, and what would settle it
> without arguing?**

You need to know whether this firewall evaluates in order, because two of the
three platforms in this topic do not. And what settles it is a counter, which is
the piece of evidence most firewall arguments are conducted without.

### Some words you will need

<dl class="terms">
<dt>rule</dt>
<dd>A condition and an action. Match this, do that.</dd>
<dt>ordered evaluation</dt>
<dd>Rules are checked top to bottom and the first match decides. The model on Linux and on most network appliances.</dd>
<dt>default policy</dt>
<dd>What happens to a packet no rule matched. Almost always the most consequential line in the configuration.</dd>
<dt>shadowed rule</dt>
<dd>A rule that can never match, because something above it always matches first.</dd>
<dt>stateful</dt>
<dd>The firewall remembers connections, so return traffic is permitted without a rule of its own.</dd>
<dt>screened subnet</dt>
<dd>A network between the outside and the inside, holding things that must be reachable from both. Once called a DMZ.</dd>
<dt>signature detection</dt>
<dd>Matching traffic against patterns of known-bad. Precise, and blind to anything new.</dd>
<dt>anomaly detection</dt>
<dd>Flagging traffic that differs from a learned normal. Catches new things, and disagrees about what normal is.</dd>
<dt>content categorisation</dt>
<dd>Somebody else's classification of what a site is, which your filter then acts on.</dd>
</dl>

## What breaks without this

**A rule is written and has no effect.** It is below something broader that already
matched, nothing warns anybody, and it sits in the configuration being cited in
reviews.

**The default is never examined.** Four hundred rules get audited line by line and
the policy line at the end, which decides everything none of them matched, is
read as boilerplate.

**A detection is bought for the wrong failure.** Signature matching is deployed
against a threat that has never been seen before, or anomaly detection against an
environment with no stable normal.

**The web filter blocks the business.** A supplier's site is categorised as
something else, the block is invisible to the person who set the policy, and the
sales team works around it.

## A packet walks the list

Here is a real router with a real rule set, on a network built for the purpose.

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology segmented-lan
# commands run on rtr
$ nft -a list ruleset
table inet seg { # handle 1
	chain forward { # handle 1
		type filter hook forward priority filter; policy drop;
		ct state established,related accept # handle 2
		ip saddr 10.30.0.0/24 ip daddr 10.10.0.0/24 accept comment "corp may reach payment" # handle 3
		ip daddr 203.0.113.0/24 accept comment "any segment may reach the internet" # handle 4
	}
}
```

Four lines and every one of them matters. The policy is `drop`, so anything not
matched is discarded. Established connections are accepted first, which is what
makes the rest of the list about new connections only. Then two specific permits.

**Read that order carefully, because it is the configuration.** The same four
lines in a different sequence describe a different firewall, and on this model
there is no other place the behaviour comes from.

<figure class="learn-figure">
<svg viewBox="0 0 720 268" role="img" aria-labelledby="rule-title" style="width:100%;height:auto;">
<title id="rule-title">A packet walking down an ordered firewall rule list, matching at the second rule, with the more specific rule below it that therefore never fires</title>
<g fill="currentColor">
<text x="14" y="20" font-size="11">one packet, one ordered list, and the rule below the one that matched</text>
<path d="M 26 46 V 200" stroke="currentColor" stroke-opacity="0.35" stroke-width="1.2"/>
<text x="14" y="220" font-size="8" fill-opacity="0.6">order</text>
<rect x="42" y="46" width="382" height="30" rx="4" fill="currentColor" fill-opacity="0.05" stroke="currentColor" stroke-opacity="0.7" stroke-width="1.1"/>
<text x="54" y="65" font-size="8">ct state established,related</text>
<text x="414" y="65" text-anchor="end" font-size="8" fill-opacity="0.85">accept</text>
<text x="438" y="65" font-size="8" fill-opacity="0.8">the return packets</text>
<rect x="42" y="86" width="382" height="30" rx="4" fill="var(--accent)" fill-opacity="0.18" stroke="var(--accent)" stroke-opacity="0.7" stroke-width="1.8"/>
<text x="54" y="105" font-size="8">ip daddr 203.0.113.0/24</text>
<text x="414" y="105" text-anchor="end" font-size="8" fill-opacity="0.85">accept</text>
<text x="438" y="105" font-size="8" fill-opacity="0.8">the first packet, matched here</text>
<path d="M 26 101 H 40" stroke="var(--accent)" stroke-width="1.8"/>
<path d="M 34 97 L 41 101 L 34 105" fill="none" stroke="var(--accent)" stroke-width="1.8"/>
<text x="438" y="117" font-size="8" fill="var(--accent)" fill-opacity="0.95">evaluation stops here</text>
<rect x="42" y="126" width="382" height="30" rx="4" fill="currentColor" fill-opacity="0.05" stroke="currentColor" stroke-opacity="0.7" stroke-width="1.1"/>
<text x="54" y="145" font-size="8">ip saddr 10.20.0.0/24 ip daddr 203.0.113.0/24</text>
<text x="414" y="145" text-anchor="end" font-size="8" fill-opacity="0.85">drop</text>
<text x="438" y="145" font-size="8" fill-opacity="0.8">never reached, 0 packets</text>
<rect x="42" y="166" width="382" height="30" rx="4" fill="currentColor" fill-opacity="0.05" stroke="currentColor" stroke-opacity="0.7" stroke-width="1.1"/>
<text x="54" y="185" font-size="8">policy drop</text>
<text x="414" y="185" text-anchor="end" font-size="8" fill-opacity="0.85">drop</text>
<text x="438" y="185" font-size="8" fill-opacity="0.8">what happens if nothing matched</text>
<text x="14" y="240" font-size="10" fill-opacity="0.85">the third rule is more specific and says the opposite, and it is unreachable</text>
<text x="14" y="260" font-size="10" fill-opacity="0.85">nothing warns you. its counter stays at zero, which is the only evidence there is</text>
</g></svg>
<figcaption>A packet from the machine network heading for the outside. It fails the conntrack rule because it is a new connection, matches the destination rule, and is accepted. Evaluation stops there, which means the rule below it is unreachable for this traffic no matter what it says. The bottom line is the default policy, and on a well-built firewall it is the busiest decision in the file even though nothing counts against it in this drawing. The point of the accent is that a firewall does not consider your rules and weigh them; it takes the first one that matches and stops.</figcaption>
</figure>
<details class="predict">
<summary>A firewall configuration has 400 rules and a policy line at the end. Which single line would you read first, and what would it tell you?</summary>

**The policy line, and it can end the review.**

If the default policy is accept, the four hundred rules above it are a list of
exceptions to permitting everything, and the firewall is not a control in the
sense the word is usually meant. Every traffic pattern nobody thought of is
allowed, which by definition is the set an attacker is most interested in.

If the default is drop, the same four hundred rules describe the entire permitted
surface, and reviewing them is worth doing because the file is now an
enumeration of what is possible.

The reason to read it first is arithmetic. On a well-built firewall the policy
line decides more packets than every rule above it combined, because most traffic
arriving at a boundary is not traffic anybody intended. It also takes ten seconds
to check, against two days to read four hundred rules, which is an unusually good
ratio for a security review.

The related habit worth building applies to any deny-by-default system: find the
default before reading the exceptions. It is the same question as asking what a
permission system does with an unlisted user, or what a validation routine does
with an unrecognised field, and it is nearly always the line nobody has looked at.

</details>


## The rule that never fires

Adding a more specific rule below a broader one is the most common firewall
mistake, and the reason it survives is that nothing tells you.

<details class="predict">
<summary>A rule denying the machine network access to the internet is added below the rule that allows every segment to reach the internet. Predict what happens when that traffic is sent.</summary>

```bash
# Fedora CoreOS 44.20260707.3.1, kernel 7.1.3-200.fc44.aarch64
# linux network namespaces, topology segmented-lan
# commands run on rtr
$ nft replace rule inet seg forward handle 4 ip daddr 203.0.113.0/24 counter accept comment \"any segment may reach the internet\"; nft add rule inet seg forward ip saddr 10.20.0.0/24 ip daddr 203.0.113.0/24 counter drop comment \"deny iot to the internet, written after the accept above\"; ip netns exec iot ping -c3 -W1 203.0.113.9 >/dev/null 2>&1; echo "the iot host pinged the internet three times. which rule decided it:"; nft list chain inet seg forward | grep -E "counter|policy"
the iot host pinged the internet three times. which rule decided it:
		type filter hook forward priority filter; policy drop;
		ip daddr 203.0.113.0/24 counter packets 1 bytes 84 accept comment "any segment may reach the internet"
		ip saddr 10.20.0.0/24 ip daddr 203.0.113.0/24 counter packets 0 bytes 0 drop comment "deny iot to the internet, written after the accept above"
```

**The accept counted one packet and the deny counted none.** The deny is more
specific, it says the opposite, it is syntactically perfect, and it is
unreachable.

Two details in that output are worth a second look.

The first is that zero. It is the only evidence that anything is wrong, and it
exists only because the rule was written with a counter on it. A rule without one
looks identical to a working rule, and a configuration review that reads the text
will find nothing to object to. Reviewing firewall rules without counters is
reading a program without running it.

The second is that the accept counted one packet rather than three. Three pings
were sent. The first packet created a connection, and every packet after it
matched the established rule at the top of the list, which is what stateful means
and is why that rule sits first. The counters therefore do not tell you how much
traffic a rule permits, they tell you how many new connections it decided, and
those are different numbers.

The general habit: when a rule appears to have no effect, check its counter before
changing anything. Zero means it is shadowed or the traffic is not happening at
all, and those need opposite responses.

</details>

<details class="deeper">
<summary>If you review firewall configurations: what to look for in a long rule set, in order</summary>

Four hundred rules is too many to read carefully, so the useful review is not a
line-by-line one. Four passes, cheapest first, find most of what matters.

**Read the default policy and the last rule.** If the policy is accept, nothing
else in the file is a security control, it is a list of exceptions to permitting
everything. This takes ten seconds and occasionally ends the review.

**Find rules with zero counters.** They are shadowed, or they are for traffic that
stopped happening, or they were written for a system that was decommissioned in
2019. All three are worth knowing and all three are invisible without the counter.

**Find the broadest rules and read what is below them.** Anything with `any` in a
source or destination is a candidate for shadowing everything beneath it, and the
rules beneath a broad accept are where the intent that is not being enforced
lives.

**Look for rules nobody can explain.** Every long rule set has entries added for a
migration that finished, a vendor who visited once, or an incident in 2021. The
test is whether anybody can name what breaks if it is removed, and the honest
process for the ones nobody can name is to log them, wait, and remove the ones
that never match.

What this deliberately does not include is checking each rule against a policy
document, which is what a compliance review does and what takes weeks. It is
worth doing and it is a different activity, and it finds a different class of
problem: the rule that works exactly as written and should never have been
written.

</details>

## Screened subnets, and what they assume

A screened subnet holds the things that have to be reachable from outside: the
web server, the mail gateway, the thing partners connect to. It sits between two
filtering points, so traffic from the internet reaches it and traffic from it to
the internal network is filtered again.

**The assumption it encodes is that the exposed things will eventually be
compromised**, and the design's value is entirely in what happens next. A web
server on a screened subnet that can reach the database on any port has a
screened subnet in the diagram and a flat network in practice.

The question worth asking of any such design is a specific one: if the most
exposed machine in this subnet were fully controlled by somebody hostile, what
could they reach, and would anybody know? That is answerable from the rule set,
and answering it is a better use of an afternoon than most architecture reviews.

## Signatures, anomalies, and what each one cannot see

Intrusion detection splits the same way, and the two halves fail in opposite
directions.

**Signature detection** matches traffic against patterns of things already known
to be bad. It is precise, its findings are explainable, and it is blind by
construction to anything nobody has written a signature for. A new technique is
invisible until somebody publishes, and a small change to an old one can be enough.

**Anomaly detection** learns what normal looks like and flags departures. It can
notice something never seen before, which is the whole appeal, and it depends
entirely on the quality of that learned normal. In an environment where traffic
changes weekly, the baseline is always wrong and the output is noise. In a stable
one, an industrial network for instance, it is unusually effective, because normal
really is normal.

The detection and prevention distinction sits across both. **Detection** watches a
copy of the traffic and tells you. **Prevention** sits in the path and stops
things, which means a false positive is now an outage and the tuning conversation
has a different tone.

Trends belong here too and they are the underrated third option. A count of
outbound connections per host, plotted over weeks, catches a slow change that no
signature describes and no anomaly threshold trips, and it costs a graph.
<details class="deeper">
<summary>If you deploy prevention rather than detection: what changes when the box is in the path</summary>

Moving from watching a copy of the traffic to sitting in it changes three things,
and only one of them is about security.

The first is that a false positive is now an outage. In detection mode a wrong
signature produces an alert somebody dismisses. In prevention mode it drops
somebody's traffic, and the person affected is a colleague with a deadline. That
inverts the tuning incentive: teams running prevention tune towards permitting,
which over a year quietly converts the device back into a detector with extra
latency.

The second is that the device is now a dependency. It has to be sized for peak
traffic, it needs a failure mode somebody has chosen deliberately, and that choice
is the fail-open against fail-closed decision met again. Fail open and an attacker
who can exhaust the device has removed the control. Fail closed and a hardware
fault is a full outage. Most deployments choose open and do not write it down,
which means nobody knows the control is conditional.

The third is scheduling. Signature updates now change the behaviour of something
in the traffic path, so they become changes rather than maintenance, and an
organisation with a change process discovers that its detection is a week behind
its threat intelligence.

None of that argues against prevention. It argues for deciding which traffic goes
through it, and the usual answer that survives is a narrow one: prevention in
front of a small number of things where a wrong block is tolerable and a
successful attack is not, and detection everywhere else.

</details>


## Web filters and the category that is wrong

A web filter decides using a category supplied by somebody else, and that
outsourcing is the source of most of its problems.

The mechanisms are worth separating. **URL scanning** checks the address against
lists. **Content categorisation** assigns each site a category, and the
categorisation is done at scale by a vendor. **Reputation** scores a site or an
address by its history. **Block rules** are your policy applied to all of that.

The deployment choice is between an agent on the device and a centralised proxy.
The agent follows the laptop home, which is where most browsing happens, and it
is software on every endpoint that has to keep working. The proxy is one place to
manage and one place to break, and it protects nothing when the laptop is not
behind it.

**The failure everybody meets is a wrong category.** A supplier's site is
classified as file sharing, a customer's portal as unrated, and a niche technical
site as hacking, because a vendor classified millions of domains without looking
at yours. The block is correct according to policy and wrong according to the
business, and the person who set the policy never finds out, because the person
who hit the block asked a colleague to send the file instead.

Two things reduce it. Watch the block log for volume by category, because a
business site being blocked shows up as many blocks from many people rather than
one complaint. And make the block page name a route to get it reviewed, since
without one the route people choose is a personal device.
<details class="deeper">
<summary>If you own the web filter: the categories that cause every argument, and the one setting worth changing</summary>

Three categories generate most of the complaints, and they generate them for
different reasons.

**Uncategorised** is the largest problem and the least discussed. New domains and
small sites have no classification, so the policy has to decide what to do with
the unknown. Blocking it is defensible and blocks a great deal of ordinary
business. Allowing it permits exactly the domains an attacker registered last
week. Neither answer is right and the decision is usually made by whoever accepted
the default.

**File sharing** catches every service anybody uses to send a document, which
includes the one your supplier uses. Blocking it is a real control against data
leaving and it is the category most likely to be routed around by somebody
emailing a file to their personal address, which is worse.

**Hacking and security** blocks the sites your own security team reads. This is
routine, it is embarrassing, and it is usually discovered when somebody cannot
open an advisory during an incident.

The setting worth changing is not a category. It is the block page. A default
block page says access is denied and gives a policy reference nobody can act on. A
useful one names the category the site was placed in, says who can review it, and
gives a link that opens a request. That single change converts silent
work-arounds into a queue somebody can read, and the queue is the only honest data
you will ever get about whether the categorisation fits your business.

The second thing worth doing is reviewing block volume by category monthly. A
miscategorised business site does not arrive as a complaint, because people are
resourceful and busy. It arrives as a hundred blocks from forty people, and it is
invisible unless somebody looks at the shape of the log rather than at individual
entries.

</details>


## Across platforms

The ordered model that the whole first half of this page depends on is not
universal. Two of these three platforms use something else.

| Task | Linux | Windows | macOS |
| --- | --- | --- | --- |
| List the rules | `nft list ruleset` | `Get-NetFirewallRule` | `pfctl -s rules` |
| Evaluation model | ordered, first match wins | not positional, block wins over allow | ordered, and last match wins by default |
| The default when nothing matches | the chain `policy` | per profile default action | `pass` unless a rule says otherwise |
| Evidence a rule fired | per-rule counters | not exposed per rule | `pfctl -s rules -v` |

```powershell
# Microsoft Windows Server 2025 Datacenter, version 10.0.26100.0
> (Get-NetFirewallRule | Measure-Object).Count; (Get-NetFirewallRule -Enabled True | Measure-Object).Count
348
183

# The default for each profile, which is what applies when nothing matches
> Get-NetFirewallProfile | Select-Object Name, Enabled, DefaultInboundAction, DefaultOutboundAction | Format-Table -AutoSize
Name    Enabled DefaultInboundAction DefaultOutboundAction
----    ------- -------------------- ---------------------
Domain     True        NotConfigured         NotConfigured
Private    True        NotConfigured         NotConfigured
Public     True        NotConfigured         NotConfigured

# Two rules for the same port, one allowing and one blocking, to see which wins
> New-NetFirewallRule -DisplayName 'zz-allow-9999' -Direction Inbound -LocalPort 9999 -Protocol TCP -Action Allow | Out-Null; New-NetFirewallRule -DisplayName 'zz-block-9999' -Direction Inbound -LocalPort 9999 -Protocol TCP -Action Block | Out-Null; Get-NetFirewallRule -DisplayName 'zz-*' | Select-Object DisplayName, Action, Enabled | Format-Table -AutoSize
DisplayName   Action Enabled
-----------   ------ -------
zz-allow-9999  Allow    True
zz-block-9999  Block    True

# Whether a rule has any notion of position, which is the question the Linux side turns on
> Get-NetFirewallRule -DisplayName 'zz-allow-9999' | Get-Member -MemberType Property | Where-Object { $_.Name -match 'Order|Priority|Index|Position|Sequence' } | Select-Object -ExpandProperty Name; Get-NetFirewallRule -DisplayName 'zz-*' | Select-Object DisplayName, EnforcementStatus, PolicyStoreSourceType | Format-Table -AutoSize
Priority
SequencedActions
DisplayName   EnforcementStatus PolicyStoreSourceType
-----------   ----------------- ---------------------
zz-allow-9999 NotApplicable                     Local
zz-block-9999 NotApplicable                     Local
```


# provenance: Microsoft Windows Server 2025 Datacenter, version 10.0.26100.0, runner image 20260818.207.1

**Three hundred and forty-eight rules on a machine nobody configured, and 183 of
them enabled.** That is the out-of-the-box state, and it is the first reason the
ordered mental model does not transfer: nobody wrote those in an order, they
arrived with features.

The interesting result is the last command. Two properties with ordering-sounding
names exist on a rule object, `Priority` and `SequencedActions`, and neither
governs whether an allow beats a block. Microsoft documents the precedence
directly: a block rule takes precedence over an allow rule, regardless of when
either was created. So the question that decides the Linux case, which rule is
higher, has no bearing here at all, and the two rules created for port 9999 above
resolve by type rather than by position.

That difference is a genuine hazard when a policy is written once and applied to a
mixed estate. "Put the deny above the permit" is correct on the router and
meaningless on the servers.

```bash
# macOS 26.5.2, arm64
$ sudo pfctl -s info 2>&1 | head -3
No ALTQ support in kernel
ALTQ related functions disabled
Status: Disabled                              Debug: Urgent

# Its rules, if any are loaded
$ sudo pfctl -s rules 2>&1 | head -5
No ALTQ support in kernel
ALTQ related functions disabled
scrub-anchor "com.apple/*" all fragment reassemble
anchor "com.apple/*" all

# The other firewall, which filters by application rather than by port
$ sudo /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate 2>&1; sudo /usr/libexec/ApplicationFirewall/socketfilterfw --getblockall 2>&1
Firewall is disabled. (State = 0)
Firewall has block all state set to disabled.

# What it is holding, which is a list of programs rather than a list of ports
$ sudo /usr/libexec/ApplicationFirewall/socketfilterfw --listapps 2>&1 | head -4
Total number of apps = 8 
1 : /usr/local/libexec/remotepairingdeviced 
             (Allow incoming connections)
2 : /usr/libexec/remoted 
```

**macOS ships two firewalls and the one people mean is not the one that filters
packets.** The packet filter is `pf`, it is ordered, and its status here is
`Disabled`. The application firewall is a separate thing entirely, it is also
disabled on this machine, and when it is on it decides by program rather than by
port: the last command lists eight applications, each with a decision about
incoming connections attached to it.

That is a third model again. Linux asks which rule matches this packet first.
Windows asks whether any block rule applies. macOS, in the firewall most users
ever see, asks which program is trying to listen. A rule set is not portable
between those three, and neither is the reasoning.

One detail worth carrying from the `pf` output: the rules that are loaded are
anchors belonging to Apple rather than a policy anybody wrote. An empty-looking
firewall on a Mac is not empty, it is disabled with vendor scaffolding in place.

## Prove it

**Run it.** On any Linux machine with nftables, add a counter to a rule you
believe is in use and watch it. `nft list ruleset` shows the counters, and the
first thing most people learn is that a rule they were sure about has never
matched.

**Work it out.** Take the four hundred rule scenario from the top of this page.
Assuming ordered evaluation, which rule wins? Then assume Windows semantics, and
answer again. Then say what you would need to see to be certain on a firewall you
did not configure.

**Look it up.** Open SP 800-41 and find what it says about default policies. The
recommendation is unambiguous and the reason given is worth reading, because it is
about what you cannot enumerate rather than about what you can.

## What trips people up

### 1. Assuming rules are evaluated in order

They are on Linux and on most network appliances. They are not on Windows, where a
block rule beats an allow rule regardless of position, and macOS's packet filter
takes the last match rather than the first.

### 2. Reviewing rules without counters

A shadowed rule and a working rule are textually identical. The only evidence is a
counter sitting at zero, and a rule written without one cannot be reviewed
properly at all.

### 3. Reading a counter as traffic volume

The capture above shows one packet counted for three pings, because the rest
matched the established-connections rule. Counters record decisions about new
connections, not bytes permitted.

### 4. Skipping the default policy

It decides every packet no rule matched, which on a well-built firewall is most of
them. If it is accept, the rest of the file is a list of exceptions to permitting
everything.

### 5. Deploying anomaly detection into an unstable environment

It learns a normal and flags departures. Where normal changes weekly, everything
is a departure. Where it genuinely does not change, the same technique is
unusually good.

### 6. Trusting the web filter's category

The classification is a vendor's, applied to millions of domains without seeing
your business. A blocked supplier shows up as many blocks from many people rather
than as a complaint, so watch the block log by category.

## Work it through

A firewall with four hundred rules, no counters on any of them, no comments, and
nobody left who wrote it. You have been asked to tidy it up.

**The tempting move is to read it and remove what looks redundant.** Four hundred
rules is two days of reading and it produces a list of rules that appear
unnecessary. Removing any of them is a guess, because appearance is exactly what
shadowing defeats, and the first outage will end the project.

**The move that works adds counters and changes nothing else.** Counters are a
non-functional change: they alter no decision and every rule keeps doing what it
did. Then wait a full business cycle, which for most organisations means a month,
because the rule that only matters at quarter end is the one that will get you.

**Then the file sorts itself.** Rules with traffic stay. Rules at zero split into
shadowed ones, which the position tells you, and unused ones, which need somebody
to say whether the system still exists. That is a conversation with an owner
rather than a guess, and the inventory decides who to ask.

**What this rejects is speed.** The reading approach produces a proposal in two
days and the measurement approach produces one in a month, and the second one is
defensible. If somebody needs a result sooner, the honest answer is that the
default policy can be checked today and everything else needs data.

The residual worth stating: a month of counters covers a month. A rule that fires
once a year is still at zero at the end of it, and removing rules on the basis of
this data carries that risk explicitly. The mitigation is to log rather than
remove for the first cycle, which costs nothing and converts a deletion into a
reversible test.

## Try it

**Add a counter to something.** On a Linux firewall, put a counter on a rule you
are confident about and check it in a week. Confidence and counters agree less
often than you would expect.

**Find your default.** `nft list ruleset | grep policy` on Linux,
`Get-NetFirewallProfile` on Windows. It is one line and it decides more than the
rest of the configuration.

**Count the rules you did not write.** `Get-NetFirewallRule | Measure-Object` on
any Windows machine. The number will be in the hundreds, and none of it was your
decision.

**Check which firewall is on.** On a Mac, `sudo pfctl -s info` and
`socketfilterfw --getglobalstate` answer different questions, and it is common for
both answers to be disabled on a machine somebody believes is protected.

## Check yourself

<details class="qa">
<summary>A deny rule sits below an allow rule that matches the same traffic. What happens, and how would you prove it?</summary>

On an ordered firewall, the allow matches first and evaluation stops, so the deny
never runs. It is syntactically valid, more specific, and unreachable.

The proof is the counter. In the capture on this page the accept shows one packet
and the deny shows zero, and that zero is the only difference between a shadowed
rule and a working one. A review that reads the text finds nothing wrong.

</details>

<details class="qa">
<summary>Three pings are sent and the permitting rule counts one packet. Why?</summary>

Because the firewall is stateful. The first packet was a new connection and
matched that rule. Everything after it, including the replies, matched the
established and related rule at the top of the chain.

So a counter records how many new connections a rule decided, not how much traffic
it permitted. Reading it as a volume figure will mislead you by roughly the number
of packets in an average connection.

</details>

<details class="qa">
<summary>How does Windows resolve an allow rule and a block rule for the same port?</summary>

The block wins, and position is not involved. Microsoft documents block rules as
taking precedence over allow rules, so creating the allow later does not help.

The rule object does carry `Priority` and `SequencedActions` properties, which is
worth knowing because they look like an answer and are not the mechanism that
resolves this case. A policy that says to put the deny above the permit is
meaningful on a router and has no effect here.

</details>

<details class="qa">
<summary>What does a screened subnet assume, and what question tests whether yours works?</summary>

It assumes the exposed machines will eventually be compromised, and its value is
entirely in what an attacker can do next.

The test: if the most exposed machine in the subnet were fully controlled by
somebody hostile, what could they reach and would anybody notice? That is
answerable from the rule set. A web server that can reach the database on any port
has a screened subnet in the diagram and a flat network in practice.

</details>

<details class="qa">
<summary>When is anomaly detection the better choice, and when is it noise?</summary>

It is at its best where normal genuinely does not change, an industrial or
building control network being the standard example, because a learned baseline
stays accurate and any departure is meaningful.

It is noise where traffic changes weekly, because the baseline is always out of
date and everything looks like a departure. Signature detection is the opposite
trade: precise and explainable, blind to anything nobody has written a signature
for yet.

</details>

## References

- [SP 800-41 Rev. 1](https://csrc.nist.gov/pubs/sp/800/41/r1/final) - NIST, firewalls and firewall policy, for default policies, rule sets and screened subnets. Free. Accessed 2026-08-25.
- [SP 800-94](https://csrc.nist.gov/pubs/sp/800/94/final) - NIST, intrusion detection and prevention, for the signature and anomaly comparison and the detection against prevention trade. Free. Accessed 2026-08-25.
- [nft manual](https://www.netfilter.org/projects/nftables/manpage.html) - Netfilter project, for chains, policies, counters and evaluation order. Free. Accessed 2026-08-25.
- [Windows Firewall rules](https://learn.microsoft.com/en-us/windows/security/operating-system-security/network-security/windows-firewall/rules) - Microsoft, and the source for block taking precedence over allow. Free. Accessed 2026-08-25.
- [pf.conf](https://man.openbsd.org/pf.conf) - OpenBSD project, for the last-match-wins behaviour of the packet filter macOS inherits. Free. Accessed 2026-08-25.

**Where the content came from.** The two firewall blocks are captured from a
router built out of Linux network namespaces, with three segments and an internet
stand-in, and the counters are the real result of pinging across it. The shadowed
rule was added deliberately to produce the zero, and the topic says so rather than
presenting it as something found in a configuration. The Windows and macOS blocks
are captured from disposable runners. The statement that Windows resolves an allow
against a block by type rather than position is read from Microsoft's
documentation, because demonstrating it would need a connection test the runner
cannot perform against itself.

**If you also work on networks.** The Network+ track's
[access lists, filtering and security zones](/learn/network-plus/acls-filtering-and-security-zones)
covers the same rule model from the network's side, and
[network segmentation](/learn/network-plus/network-segmentation) covers the
boundary this topic filters at.
