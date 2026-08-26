---
title: "Accounts, from joiner to leaver"
description: "Why the mover is harder than the leaver, what locking a password actually changes about what an account can reach, what identity proofing verifies and what it does not, and how to tell a real attestation from a rubber-stamped one."
deck: "The contractor left in March. The account still works, and it has more access than it did on day one"
track: "security-plus"
level: "working"
order: 540
objectives:
  - "Describe the joiner, mover and leaver path and say which one causes the most trouble"
  - "Say what disabling an account changes and what it leaves untouched"
  - "Explain privilege creep in terms of decisions that were each individually correct"
  - "Say what identity proofing actually verifies"
  - "Describe attestation and tell a real one from a rubber-stamped one"
  - "Read an account's state and its memberships on three platforms"
prerequisites: ["secure-baselines"]
tags: ["security-plus", "security", "operations", "identity"]
updated: 2026-08-25
draft: false
examObjectives:
  - exam: "sy0-701"
    domain: "4.0"
    objective: "4.6"
sources:
  - title: "SP 800-63A, Digital Identity Guidelines: Enrollment and Identity Proofing"
    url: "https://csrc.nist.gov/pubs/sp/800/63/a/final"
    publisher: "NIST"
    accessed: 2026-08-25
    tier: 1
  - title: "SP 800-53 Rev. 5, Security and Privacy Controls, Access Control family"
    url: "https://csrc.nist.gov/pubs/sp/800/53/r5/upd1/final"
    publisher: "NIST"
    accessed: 2026-08-25
    tier: 1
  - title: "usermod manual page"
    url: "https://man7.org/linux/man-pages/man8/usermod.8.html"
    publisher: "man7.org"
    accessed: 2026-08-25
    tier: 1
  - title: "Get-LocalUser reference"
    url: "https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.localaccounts/get-localuser"
    publisher: "Microsoft"
    accessed: 2026-08-25
    tier: 1
  - title: "dscl manual page"
    url: "https://ss64.com/mac/dscl.html"
    publisher: "ss64"
    accessed: 2026-08-25
    tier: 2
symptoms:
  - symptom: "A disabled account still appears in every access group it ever had"
    anchor: "locking-the-password-changes-one-thing"
  - symptom: "Access reviews are approved without anybody reading them"
    anchor: "attestation-and-how-to-tell-a-real-one"
---

> **Before you read.** A contractor finished in March. Their account is still
> enabled, and comparing it against the day they joined shows more access rather
> than less.
>
> Nobody did anything wrong. Every change was requested by a manager and approved.
>
> **How did an account get more access after the work it was for ended?**

Because access accumulates by default and is removed only by an act that somebody
has to initiate. Nothing in the ordinary running of an organisation takes
permissions away, which is why the interesting part of this objective is the
middle of the path rather than either end.

### Some words you will need

<dl class="terms">
<dt>provisioning</dt>
<dd>Creating an account and giving it the access a role needs.</dd>
<dt>de-provisioning</dt>
<dd>Removing that access when the role ends. A separate act, and the one that gets skipped.</dd>
<dt>joiner, mover, leaver</dt>
<dd>The three transitions an identity goes through. Usually written JML.</dd>
<dt>privilege creep</dt>
<dd>Access accumulating across role changes because nothing removes the previous role's.</dd>
<dt>identity proofing</dt>
<dd>Establishing that a person is who they claim before an account exists at all.</dd>
<dt>attestation</dt>
<dd>Somebody with authority periodically confirming that an access grant is still justified.</dd>
<dt>entitlement</dt>
<dd>One specific thing an account is permitted to do. A group membership is usually a bundle of them.</dd>
<dt>orphaned account</dt>
<dd>An account with no owner: the person left, the system stayed, and nobody is accountable for it.</dd>
</dl>

## What breaks without this

**A leaver keeps working access.** The account was disabled in one directory and
the systems that authenticate locally never heard about it.

**An account accumulates until it is more privileged than anyone intended.** No
single grant was wrong and the total is a problem nobody decided to create.

**A review is signed without being read.** Four hundred entitlements arrive as a
spreadsheet, the manager approves the lot, and the process now produces evidence
of a control that is not operating.

**Nobody can say whose account this is.** The system is still running, the person
is gone, and the account has no owner to ask about it.

## Three transitions, and the middle one is the problem

**The joiner is the easy one.** It is visible, somebody is waiting for it, and it
fails loudly: a new starter without access complains on day one. Organisations are
generally good at provisioning for exactly that reason.

**The leaver is the one everybody has a process for.** It is a discrete event with
a date, HR knows about it, and the failure is well understood. It still goes
wrong, and when it does the reason is usually that the process covers the central
directory and not the six systems with their own local accounts.

**The mover is where the damage accumulates**, and it is hard for a structural
reason. A move is two operations, granting the new access and removing the old,
and only the first has anybody chasing it. The person needs their new permissions
to do their job today. Nobody is inconvenienced by the old ones remaining, so
nothing prompts the second half.

<figure class="learn-figure">
<svg viewBox="0 0 720 296" role="img" aria-labelledby="creep-title" style="width:100%;height:auto;">
<title id="creep-title">One account through four stages of a career, with the group added at each stage and the ones carried forward from every previous role</title>
<g fill="currentColor">
<text x="14" y="20" font-size="11">one account, four stages, and nothing ever taken away</text>
<text x="14" y="61" font-size="8.5">joins support</text>
<rect x="158" y="44" width="40" height="26" rx="3" fill="var(--accent)" fill-opacity="0.18" stroke="var(--accent)" stroke-opacity="0.7" stroke-width="1.2"/>
<text x="178" y="61" text-anchor="middle" font-size="7.5">support</text>
<text x="14" y="101" font-size="8.5">moves to finance</text>
<rect x="158" y="84" width="40" height="26" rx="3" fill="var(--red)" fill-opacity="0.10" stroke="var(--red)" stroke-opacity="0.7" stroke-width="1.2"/>
<text x="178" y="101" text-anchor="middle" font-size="7.5">support</text>
<rect x="203" y="84" width="82" height="26" rx="3" fill="var(--accent)" fill-opacity="0.18" stroke="var(--accent)" stroke-opacity="0.7" stroke-width="1.2"/>
<text x="244" y="101" text-anchor="middle" font-size="7.5">finance-readonly</text>
<rect x="290" y="84" width="40" height="26" rx="3" fill="var(--accent)" fill-opacity="0.18" stroke="var(--accent)" stroke-opacity="0.7" stroke-width="1.2"/>
<text x="310" y="101" text-anchor="middle" font-size="7.5">finance</text>
<text x="14" y="141" font-size="8.5">moves to platform</text>
<rect x="158" y="124" width="40" height="26" rx="3" fill="var(--red)" fill-opacity="0.10" stroke="var(--red)" stroke-opacity="0.7" stroke-width="1.2"/>
<text x="178" y="141" text-anchor="middle" font-size="7.5">support</text>
<rect x="203" y="124" width="82" height="26" rx="3" fill="var(--red)" fill-opacity="0.10" stroke="var(--red)" stroke-opacity="0.7" stroke-width="1.2"/>
<text x="244" y="141" text-anchor="middle" font-size="7.5">finance-readonly</text>
<rect x="290" y="124" width="40" height="26" rx="3" fill="var(--red)" fill-opacity="0.10" stroke="var(--red)" stroke-opacity="0.7" stroke-width="1.2"/>
<text x="310" y="141" text-anchor="middle" font-size="7.5">finance</text>
<rect x="335" y="124" width="36" height="26" rx="3" fill="var(--accent)" fill-opacity="0.18" stroke="var(--accent)" stroke-opacity="0.7" stroke-width="1.2"/>
<text x="353" y="141" text-anchor="middle" font-size="7.5">deploy</text>
<rect x="376" y="124" width="36" height="26" rx="3" fill="var(--accent)" fill-opacity="0.18" stroke="var(--accent)" stroke-opacity="0.7" stroke-width="1.2"/>
<text x="393" y="141" text-anchor="middle" font-size="7.5">oncall</text>
<text x="14" y="181" font-size="8.5">takes on databases</text>
<rect x="158" y="164" width="40" height="26" rx="3" fill="var(--red)" fill-opacity="0.10" stroke="var(--red)" stroke-opacity="0.7" stroke-width="1.2"/>
<text x="178" y="181" text-anchor="middle" font-size="7.5">support</text>
<rect x="203" y="164" width="82" height="26" rx="3" fill="var(--red)" fill-opacity="0.10" stroke="var(--red)" stroke-opacity="0.7" stroke-width="1.2"/>
<text x="244" y="181" text-anchor="middle" font-size="7.5">finance-readonly</text>
<rect x="290" y="164" width="40" height="26" rx="3" fill="var(--red)" fill-opacity="0.10" stroke="var(--red)" stroke-opacity="0.7" stroke-width="1.2"/>
<text x="310" y="181" text-anchor="middle" font-size="7.5">finance</text>
<rect x="335" y="164" width="36" height="26" rx="3" fill="var(--red)" fill-opacity="0.10" stroke="var(--red)" stroke-opacity="0.7" stroke-width="1.2"/>
<text x="353" y="181" text-anchor="middle" font-size="7.5">deploy</text>
<rect x="376" y="164" width="36" height="26" rx="3" fill="var(--red)" fill-opacity="0.10" stroke="var(--red)" stroke-opacity="0.7" stroke-width="1.2"/>
<text x="393" y="181" text-anchor="middle" font-size="7.5">oncall</text>
<rect x="416" y="164" width="22" height="26" rx="3" fill="var(--accent)" fill-opacity="0.18" stroke="var(--accent)" stroke-opacity="0.7" stroke-width="1.2"/>
<text x="427" y="181" text-anchor="middle" font-size="7.5">dba</text>
<rect x="443" y="164" width="68" height="26" rx="3" fill="var(--accent)" fill-opacity="0.18" stroke="var(--accent)" stroke-opacity="0.7" stroke-width="1.2"/>
<text x="477" y="181" text-anchor="middle" font-size="7.5">archive-admin</text>
<text x="158" y="222" font-size="9" fill="var(--accent)" fill-opacity="0.95">accented: added for the role being taken up, which is always justified</text>
<text x="158" y="238" font-size="9" fill="var(--red)" fill-opacity="0.9">the rest: carried from a job this person no longer does</text>
<text x="14" y="268" font-size="10" fill-opacity="0.85">no single step is wrong. every one of them was somebody solving a problem</text>
<text x="14" y="288" font-size="10" fill-opacity="0.85">and the leaver process locks the password, which changes none of the boxes</text>
</g></svg>
<figcaption>Four stages of one ordinary career. At each one, somebody requested access for the role being taken up, a manager approved it, and it was granted, which is the process working correctly. What no step includes is a removal, because the person moving does not need the old access removed in order to start the new job, and nobody else notices. After four stages the account holds seven memberships covering four different jobs, one of which is finance and one of which is database administration. The accented boxes are the justified grants. The others are a record of where this person used to work, and they carry exactly the same authority.</figcaption>
</figure>

## Locking the password changes one thing

Here is that account, and the leaver step everybody runs.

<details class="predict">
<summary>The account is locked. Predict what that changes about the seven groups it belongs to.</summary>

```bash
# AlmaLinux 10.2, x86_64
$ echo "one account, three role changes, and nothing ever removed:"; id sam; echo; echo "what the account file says about its state:"; passwd -S sam; echo; echo "now run the leaver step everybody runs:"; usermod -L sam; passwd -S sam; echo; echo "and check what that changed about what the account can reach:"; id -Gn sam
one account, three role changes, and nothing ever removed:
uid=1000(sam) gid=1007(sam) groups=1007(sam),1000(support),1001(finance-readonly),1002(finance),1003(deploy),1004(oncall),1005(dba),1006(archive-admin)

what the account file says about its state:
sam P 2026-08-26 0 99999 7 -1

now run the leaver step everybody runs:
sam L 2026-08-26 0 99999 7 -1

and check what that changed about what the account can reach:
sam support finance-readonly finance deploy oncall dba archive-admin
```

**Nothing at all.** The password state moved from `P` to `L` and the group list is
identical before and after.

That is the correct behaviour and it is worth understanding rather than being
surprised by. Locking a password prevents authentication by password. It is not a
statement about authorisation, and the two are separate systems: authorisation is
carried by the memberships, and they belong to the account rather than to the
credential.

Three consequences follow and all of them turn up in real incidents.

Any other route in still works. An SSH key in the account's authorized keys file
authenticates without a password, so a locked account with a key is a working
account. Kerberos tickets already issued remain valid until they expire. A service
that authenticates against something other than the local password file is
unaffected.

Processes already running as that user keep running. Locking is not a signal to
anything currently executing.

And if the account is ever unlocked, for a temporary return or by mistake, all
seven memberships are still attached to it. The exposure was never removed, it was
made temporarily unreachable by one route.

The complete leaver action is therefore three things rather than one: prevent
authentication, remove authorisation, and terminate existing sessions. Most
processes do the first, document the second, and forget the third.

</details>

<details class="deeper">
<summary>If you run the leaver process: the systems it does not reach, and how to find them</summary>

A leaver process usually acts on the central directory, and the gap is every
system that does not consult it.

The list is longer than people expect and it is consistent across organisations.
Systems with local accounts, which includes most appliances and a surprising
amount of infrastructure. Software as a service purchased by a department rather
than by the technology function. Anything with an application-level user list
inside its own database. Shared credentials in a password manager, where removing
the person's access to the manager does not change a password they have already
seen. And code repositories, deployment tooling and cloud consoles, which are
frequently joined to the directory for sign-in and hold their own authorisation.

Finding them is an inventory problem, and there are two routes that work. Ask
finance for the list of recurring software payments, which finds the departmental
purchases nobody told anybody about. And take one leaver who has already gone and
audit them properly: try every system you can name, and see how many still know
about them. That produces a real number rather than a policy, and it is usually
uncomfortable enough to fund the fix.

The structural answer is federation, so that one identity decision propagates
everywhere, and it is the subject of the next topic. It is also a multi-year
programme, so in the meantime the practical mitigation is a written list of
systems that the leaver process must touch by hand, kept with the process, and
reviewed whenever anything is purchased.

The shared credential deserves its own note. If a departing person knew a shared
password, disabling their account does nothing about it, and the only remedy is
rotation. An organisation that cannot rotate its shared credentials on a leaver has
a control gap that no identity system fixes, and the answer is to stop having
shared credentials rather than to improve the process around them.

</details>
<details class="deeper">
<summary>If you are fixing privilege creep: why a clean sweep fails, and the approach that works</summary>

The obvious remedy for the account in the figure is to strip it back to what the
current role needs. Applied across an estate, that is the clean sweep, and it
fails in a specific and predictable way.

It fails because nobody knows what the current role needs. The entitlement set was
never designed; it accumulated. Removing everything not obviously justified breaks
work that people were quietly doing, the breakages arrive as urgent tickets, the
tickets are resolved by granting the access back, and after three weeks the
estate is where it started with a reputation for security breaking things.

Two approaches work and they are both slower.

**Start with the accounts where the stakes justify the effort.** Administrative
and finance access, a small number of people, reviewed properly with somebody who
understands what each entitlement does. That is a week of work rather than a
programme, and it addresses most of the actual risk, because privilege creep on an
account with no privileges is untidy rather than dangerous.

**Then attack the flow rather than the stock.** Make the mover event produce a
removal task alongside the grant task, so new creep stops accumulating. That does
nothing about the existing mess and it stops it growing, which over two years of
ordinary turnover does more than any sweep.

The technique that makes a sweep survivable, where one is genuinely needed, is to
log rather than remove first. Turn the entitlement into one that records use, wait
a cycle, and remove the ones nothing exercised. It converts a guess into a
measurement, and it is the same move as counting firewall rules before deleting
them.

The uncomfortable observation to carry: creep is a symptom of role definitions
that do not exist. An organisation that can say what a role's access is can grant
and revoke it in one operation. One that cannot will accumulate, whatever process
sits on top, because every grant is a bespoke decision and bespoke decisions have
no natural end.

</details>


## Identity proofing, and what it establishes

Everything above assumes the account belongs to the person it says it does, and
identity proofing is the step that establishes it, before any account exists.

**It verifies a claim about a person against evidence.** Documents, a database
check, a video call, an in-person meeting, or a combination. What it produces is a
level of confidence rather than certainty, and the levels are defined: the
strength of the evidence and how it was validated determine how much weight the
resulting identity can carry.

**What it does not do is guarantee anything about the future.** Proofing happens
once, at enrolment, and it says the person who enrolled presented acceptable
evidence. It says nothing about who is using the account today, which is what
authentication is for, and nothing about whether they should be, which is
authorisation.

The place this matters most is remote enrolment, which is now the normal case.
Verifying a document over a video call is a genuine control and a weaker one than
seeing the person and the document together, and the difference should be recorded
rather than assumed away. It matters more for high-privilege accounts, and it is a
reasonable place to require a stronger process for a small number of people rather
than a uniform one for everybody.
<details class="deeper">
<summary>If you enrol people remotely: what a video call establishes, and the failure that is now routine</summary>

Remote identity proofing is the normal case and it is weaker than the in-person
equivalent in ways worth naming precisely, because the weaknesses are exploited
routinely rather than theoretically.

What a video call plus a document establishes is that somebody who could obtain
that document appeared on a call. That is a real check and it is a weaker claim
than a person handing you a passport across a desk, for two reasons. The document
is being assessed from an image, so the physical security features that make
forgery hard are mostly unavailable. And the person on the call may not be the
person who will use the account.

The failure that has become routine is exactly that second gap. Somebody passes
the interview and the identity check, an account is issued, and the person doing
the work afterwards is not the person who was checked. Nothing about the proofing
process detects it, because proofing happens once and the account is used for
years.

Three mitigations that are proportionate rather than paranoid. Bind the credential
to hardware at enrolment, so a security key or a device certificate ties the
account to something physical the enrolled person holds; that does not prove
identity and it does raise the cost of handing the account on. Re-verify at the
point of privilege escalation rather than only at enrolment, so an account being
granted administrative access gets a fresh check. And treat a high-privilege
starter differently from an ordinary one, because a uniform process is
necessarily calibrated for the ordinary case.

The general principle, which outlives the current techniques: proofing establishes
a claim at one moment, and any control depending on it decays from that moment
onward. Systems that need continuing confidence have to get it from authentication
and from behaviour, not from the strength of the original check.

</details>


## Attestation, and how to tell a real one

Attestation is somebody with authority periodically confirming that an access
grant is still justified. It is the control that would catch everything in the
figure above, and it is the control most reliably reduced to theatre.

**The failure has a recognisable shape.** A manager receives a list of four
hundred entitlements, has no idea what most of them mean, has no way to find out,
and has a deadline. Approving everything takes one click and produces exactly the
same evidence as a careful review, so the process generates a signed record with
no information in it.

Four things separate one that works.

**The reviewer can tell what the entitlement does.** "Member of FIN-GL-ADMIN"
means nothing. "Can post journal entries in the general ledger" means something,
and producing that translation is real work that has to happen before the review,
not during it.

**The list is short enough to read.** Which means reviewing by exception, high
privilege more often and low privilege rarely, rather than everything at once on
the same cadence.

**Doing nothing removes access rather than keeping it.** If silence means approval,
silence is what you get. If silence means removal, the reviewer engages, and the
process needs a way to restore access quickly for the ones that were removed
wrongly.

**The removals actually happen.** A review that produces a list of revocations
which nobody executes is worse than no review, because it creates a documented
record that the organisation knew.
<details class="deeper">
<summary>If you inherit an estate: finding the orphans, and what to do with one</summary>

An orphaned account has no owner. The person left, or the contract ended, or the
service it was created for was decommissioned and the account was not. It is the
most common finding in any first-time access review and the least dramatic.

Finding them is mostly joins rather than cleverness. Compare the directory against
the current employee list, which finds people who left. Compare service accounts
against a list of running services, which finds the ones whose reason has gone.
And look for accounts that have not authenticated in ninety days, which finds both
plus a category worth knowing about: the account nobody uses that still works.

What to do with one is where judgement is needed, because the two obvious options
are both wrong sometimes. Deleting it immediately is clean and occasionally
removes something a scheduled job authenticates as, which fails at three in the
morning at the end of the month. Leaving it is how the finding survives four
consecutive reviews.

The sequence that works: disable rather than delete, wait a full business cycle
including whatever the longest periodic job is, and delete afterwards if nothing
broke. Disabled is reversible in seconds and deleted usually is not, and the wait
converts a risky change into a safe one for the cost of a calendar entry.

Service accounts deserve a separate note because they are the majority of real
orphans. The fix is not only deletion; it is that every service account should have
a named human owner recorded when it is created, which is a one-line change to the
creation process and prevents the entire category. Retrofitting owners onto the
existing ones is tedious and finite, and it is the piece of work that stops this
being a finding at every future review.

</details>

<details class="predict">
<summary>An access review lands on a manager's desk: 400 entitlements, a fortnight to respond, silence treated as approval. Predict the outcome, and say what the evidence will look like afterwards.</summary>

**Everything is approved, and the evidence is indistinguishable from a careful
review.**

That second half is the part worth dwelling on. A signed record showing four
hundred approvals on a date, by a named manager, within the deadline, is exactly
what a working control produces. An auditor reading the artefact cannot tell the
difference, and neither can the person who designed the process.

The manager is not being negligent. Consider what they were actually asked. Most
of the four hundred rows name a group rather than a capability, so the honest
answer to most of them is that they do not know. Finding out means asking somebody
in the technology function about each one, four hundred times, alongside their
actual job. Approving is the only action that fits in the time available, and the
process offered it as the default.

Three design choices produced this and every one of them is fixable. Silence
meaning approval, which guarantees the outcome. A list arriving all at once rather
than by exception, which makes reading it impossible. And entitlements named after
groups rather than after what they permit, which makes reading it useless even if
somebody tried.

The measurement that tells you which kind of review you have is not in the
paperwork. Take twenty people who changed role and check whether their old access
is gone. That is the only evidence that distinguishes a control from a ceremony,
and it takes an afternoon.

</details>


## Across platforms

The same two questions, the account's state and what it can reach, are answered
by different subsystems on each platform, and on none of them is it one query.

| Task | Linux | Windows | macOS |
| --- | --- | --- | --- |
| The account's state | `passwd -S user` | `Get-LocalUser` | `dscl . -read /Users/name` |
| What it can reach | `id -Gn user` | per-group membership queries | `id -Gn`, `dsmemberutil` |
| Disable it | `usermod -L` | `Disable-LocalUser` | remove the authentication authority |
| Does disabling change access | no | no | no |

```powershell
# Microsoft Windows Server 2025 Datacenter, version 10.0.26100.0
> New-LocalUser -Name 'zzsam' -Password (ConvertTo-SecureString 'Correct-Horse-Battery-9' -AsPlainText -Force) -Description 'joined as support' | Out-Null; 'Users','Backup Operators','Remote Desktop Users','Performance Log Users' | ForEach-Object { Add-LocalGroupMember -Group $_ -Member 'zzsam' -ErrorAction SilentlyContinue }; Get-LocalUser zzsam | Select-Object Name, Enabled, PasswordLastSet, LastLogon | Format-List
Name            : zzsam
Enabled         : True
PasswordLastSet : 8/26/2026 1:56:48 AM
LastLogon       :

# What it can currently reach, which is the question the account object does not answer
> Get-LocalGroup | ForEach-Object { $g = $_.Name; if (Get-LocalGroupMember -Group $g -ErrorAction SilentlyContinue | Where-Object { $_.Name -like '*zzsam' }) { $g } }
Backup Operators
Performance Log Users
Remote Desktop Users
Users

# The leaver step everybody runs
> Disable-LocalUser -Name 'zzsam'; Get-LocalUser zzsam | Select-Object Name, Enabled | Format-List
Name    : zzsam
Enabled : False

# And what that changed about what the account is a member of
> Get-LocalGroup | ForEach-Object { $g = $_.Name; if (Get-LocalGroupMember -Group $g -ErrorAction SilentlyContinue | Where-Object { $_.Name -like '*zzsam' }) { $g } }
Backup Operators
Performance Log Users
Remote Desktop Users
Users
```


# provenance: Microsoft Windows Server 2025 Datacenter, version 10.0.26100.0, runner image 20260818.207.1

**Four groups before disabling and the same four after.** Windows behaves exactly
as Linux does here, and for the same reason: `Enabled` is a property of the account
and membership is a property of each group.

Notice how the second command had to be written. There is no single query that
asks what an account can reach; you enumerate the groups and ask each one whether
this account is in it. That is a small thing and it is why access reviews are hard
to produce: the data is stored by group rather than by person, so the report the
reviewer wants is the inverse of the way the directory is arranged.

```bash
# macOS 26.5.2, arm64
$ dscl . -read /Users/$(whoami) RecordName UniqueID PrimaryGroupID 2>/dev/null | head -6
PrimaryGroupID: 20
RecordName: runner
UniqueID: 501

# What it can reach, which is a separate query from the account record
$ id -Gn; echo "---"; dsmemberutil checkmembership -U "$(whoami)" -G admin 2>/dev/null
staff everyone localaccounts _appserverusr admin _appserveradm _webdeveloper com.apple.sharepoint.group.1 _appstore _lpadmin _lpoperator _developer _analyticsusers com.apple.access_ftp com.apple.access_screensharing com.apple.access_ssh com.apple.access_remote_ae
---
user is a member of the group

# Whether the password has an expiry policy attached to it at all
$ pwpolicy -u "$(whoami)" -getpolicy 2>&1 | head -2
Getting policy for runner


# The equivalent of a lock, asked rather than performed on a machine somebody else owns
$ dscl . -read /Users/$(whoami) AuthenticationAuthority 2>/dev/null | tr ' ' '\n' | grep -c . 
4
```

**Seventeen groups on a fresh account nobody has moved anywhere.** This is the
runner's own account on a machine provisioned minutes earlier, so none of that is
accumulation, and it makes a different point: the baseline is not zero. Four of
those memberships are `com.apple.access_` groups gating specific services, one is
`admin`, and a review of this account would have seventeen rows in it before
anybody had done anything.

The `AuthenticationAuthority` count at the end is the closest equivalent to
asking how many ways in an account has. It is four here, which is the honest shape
of the disabling problem on any platform: an account is not one credential, and
removing one of them leaves the others.

## Prove it

**Run it.** On any Linux machine, `id -Gn` for your own account and count the
groups. Then ask, for each one, what it lets you do and whether you are still
doing the job it was for.

**Work it out.** Take the seven memberships in the capture and split them into the
ones justified by the current role and the ones carried forward. Then say what
would have had to happen at each transition for the second list to be empty, and
who would have had to do it.

**Look it up.** Open SP 800-63A and find the identity assurance levels. Note what
distinguishes them, and decide which one your own organisation actually performs
for a new starter.

## What trips people up

### 1. Treating the leaver as the hard case

The leaver is a dated event that somebody owns. The mover is two operations where
only the first has anybody chasing it, and it is where the accumulation happens.

### 2. Reading a disabled account as access removed

Locking the password prevents one authentication route. The memberships are
untouched, keys and tickets still work, running processes continue, and re-enabling
restores everything at once.

### 3. Assuming the central directory is the whole estate

Local accounts on appliances, departmental software purchases, application-level
user lists and shared credentials are all outside it, and a leaver process that
covers only the directory covers less than it appears to.

### 4. Confusing proofing with authentication

Proofing establishes who enrolled, once. Authentication establishes who is using
the account now. A strong proofing process says nothing about today.

### 5. Reviewing everything on one cadence

Four hundred entitlements arrive at once, the reviewer approves them all, and the
evidence is identical to a careful review. Review by exception, translate the
entitlements into what they let somebody do, and make silence remove rather than
keep.

### 6. Producing revocation lists nobody executes

A review that identifies access to remove and then does not remove it is worse
than none, because it documents that the organisation knew.

## Work it through

Six hundred staff, one directory, and an access review that has been signed on
time every quarter for three years. An audit has asked you to demonstrate the
control is effective.

**The tempting move is to show the evidence.** Twelve quarters of signed reviews,
complete, on time, with approver names and dates. It satisfies the paperwork and
it demonstrates that the process ran rather than that the control worked.

**The move that works samples backwards.** Take twenty people who changed role in
the last year and compare their current entitlements against what their current
job needs. If the reviews were working, the old entitlements are gone. If most of
them are still there, you have a measurement rather than an opinion, and it is the
same measurement the auditor would eventually make.

**Then the finding is about the review's design.** The likely cause is not
negligent managers. It is entitlements named after groups rather than actions, a
list too long to read, and approval as the default outcome. Each of those is
fixable and none of them is fixed by asking people to be more careful.

**What this rejects is treating completion as effectiveness.** A control that runs
on schedule and changes nothing is a control that produces evidence, and the
distinction is the whole of what an audit is trying to establish. Presenting the
sample is more uncomfortable and much harder to argue with.

The residual worth naming: this fixes the reviewed population. Accounts in systems
outside the directory are not in any review, so the sample says nothing about
them, and finding those is the separate inventory exercise that nobody has budget
for until something happens.

## Try it

**Count your own groups.** `id -Gn` on Linux or a Mac, or the group membership of
your own account on Windows. Then find one you cannot explain.

**Check what disabling does.** On a machine you own, create a test account, add it
to a group, disable it, and check the membership. Watching it not change is more
convincing than reading that it does not.

**Find an account with no owner.** Look at any system's user list for a name that
does not match a current employee. Most estates have several, and the first one is
usually found within ten minutes.

**Read one entitlement name.** Pick a group in your own directory and try to write
one sentence saying what a member of it can do. If you cannot, neither can the
manager approving it every quarter.

## Check yourself

<details class="qa">
<summary>Why is the mover harder than the leaver?</summary>

Because it is two operations and only one of them has anybody chasing it. The
person needs their new access to work today, so the grant happens promptly. Nobody
is inconvenienced by the old access remaining, so nothing prompts the removal.

A leaver, by contrast, is a dated event with an owner and a process. It fails for
a different reason, which is that the process usually reaches the central
directory and not the systems with their own accounts.

</details>

<details class="qa">
<summary>An account is disabled. What has changed and what has not?</summary>

Authentication by password is prevented. Nothing about authorisation changes: the
group memberships are identical before and after on all three platforms in this
topic.

Other routes in still work, including keys and tickets already issued. Processes
already running as that user continue. And re-enabling the account restores every
membership at once, because the exposure was never removed.

</details>

<details class="qa">
<summary>What does identity proofing establish, and what does it not?</summary>

That the person who enrolled presented acceptable evidence for a claimed identity,
at a level of confidence determined by the strength of that evidence and how it was
validated. It happens once.

It says nothing about who is using the account today, which is authentication, and
nothing about whether they should have the access they have, which is
authorisation. A strong proofing process and a stale entitlement set are entirely
compatible.

</details>

<details class="qa">
<summary>Name three things that separate a real attestation from a rubber-stamped one.</summary>

The reviewer can tell what each entitlement actually permits, which requires
translating group names into actions before the review starts. The list is short
enough to read, which means reviewing by exception rather than everything at once.
And doing nothing removes access rather than keeping it, so silence is not
approval.

There is a fourth that decides whether any of it matters: the revocations
identified have to be executed. A review that produces a list nobody acts on
documents that the organisation knew.

</details>

<details class="qa">
<summary>A leaver process disables the directory account. What is likely still working?</summary>

Anything that does not consult that directory. Local accounts on appliances and
infrastructure, departmental software purchased outside the technology function,
applications with their own internal user lists, and any cloud console with its
own authorisation.

Shared credentials are the worst case, because disabling an account does nothing
about a password the person has already seen. The only remedy there is rotation,
and an organisation that cannot rotate them has a gap no identity system closes.

</details>

## References

- [SP 800-63A](https://csrc.nist.gov/pubs/sp/800/63/a/final) - NIST, enrollment and identity proofing, for what evidence establishes and the assurance levels. Free. Accessed 2026-08-25.
- [SP 800-53 Rev. 5](https://csrc.nist.gov/pubs/sp/800/53/r5/upd1/final) - NIST, the access control family, for account management and review as stated controls. Free. Accessed 2026-08-25.
- [usermod(8)](https://man7.org/linux/man-pages/man8/usermod.8.html) - what `-L` does and, by omission, what it does not. Free. Accessed 2026-08-25.
- [Get-LocalUser](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.localaccounts/get-localuser) - Microsoft, for the account object and what `Enabled` covers. Free. Accessed 2026-08-25.
- [dscl](https://ss64.com/mac/dscl.html) - the directory service command line the macOS capture uses. Free. Accessed 2026-08-25.

**Where the content came from.** The Linux block is captured from an AlmaLinux
10.2 container where the account was created and moved through four sets of group
memberships during setup, so the accumulation on the page is a real sequence of
`usermod` calls rather than an illustration. The Windows block creates, populates
and disables a local account during the capture. The macOS block reads the
runner's own account, which is a fresh machine rather than a career, and the topic
says so, because the seventeen memberships there make a point about baselines
rather than about creep.

**If you also work on Linux.** The Linux+ track's
[account files and attributes](/learn/linux-plus/account-files-and-attributes)
covers what `passwd -S` is reading and what each field means.
