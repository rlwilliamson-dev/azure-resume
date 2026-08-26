---
title: "The six access control models"
description: "One request put to six models, the two that disagree about the same file, why the discretionary model's failure mode is everybody, where mandatory control is actually used, and what each model can express that the others cannot."
deck: "The same request, six schemes, and four different answers"
track: "security-plus"
level: "working"
order: 560
objectives:
  - "Name the six models and say what each one decides on"
  - "Say what makes a model discretionary and what its failure mode is"
  - "Explain where mandatory access control is genuinely used"
  - "Distinguish role-based from attribute-based by what each can express"
  - "Read a real permission set and say which model produced it"
  - "Say why least privilege is a principle rather than a model"
prerequisites: ["accounts-from-joiner-to-leaver"]
tags: ["security-plus", "security", "operations", "identity"]
updated: 2026-08-25
draft: false
examObjectives:
  - exam: "sy0-701"
    domain: "4.0"
    objective: "4.6"
sources:
  - title: "SP 800-162, Guide to Attribute Based Access Control (ABAC) Definition and Considerations"
    url: "https://csrc.nist.gov/pubs/sp/800/162/upd2/final"
    publisher: "NIST"
    accessed: 2026-08-25
    tier: 1
  - title: "SP 800-53 Rev. 5, Security and Privacy Controls"
    url: "https://csrc.nist.gov/pubs/sp/800/53/r5/upd1/final"
    publisher: "NIST"
    accessed: 2026-08-25
    tier: 1
  - title: "SELinux Project documentation"
    url: "https://github.com/SELinuxProject/selinux/wiki"
    publisher: "SELinux Project"
    accessed: 2026-08-25
    tier: 1
  - title: "FileSystemRights enumeration"
    url: "https://learn.microsoft.com/en-us/dotnet/api/system.security.accesscontrol.filesystemrights"
    publisher: "Microsoft"
    accessed: 2026-08-25
    tier: 1
  - title: "chmod manual page, macOS ACL syntax"
    url: "https://ss64.com/mac/chmod.html"
    publisher: "ss64"
    accessed: 2026-08-25
    tier: 2
symptoms:
  - symptom: "A file's permissions say one thing and the operation fails anyway"
    anchor: "two-layers-that-disagree"
  - symptom: "Everybody in the company can read a folder somebody shared once"
    anchor: "the-discretionary-failure-mode-is-everybody"
---

> **Before you read.** Sam wants to delete a file at two in the morning, from a
> laptop that is not managed, using an account that has legitimately held finance
> permissions since March.
>
> Six access control models are asked whether to allow it.
>
> **How many say yes, and does any two of them say no for the same reason?**

Two say yes and four say no, and every denial is for a reason none of the others
can express. That is the useful way to hold these six: not as a list of names but
as a list of what each one is able to consider.

### Some words you will need

<dl class="terms">
<dt>discretionary</dt>
<dd>The owner of a resource decides who may use it. Abbreviated DAC.</dd>
<dt>mandatory</dt>
<dd>A system-wide policy decides, and the owner cannot override it. Abbreviated MAC.</dd>
<dt>role-based</dt>
<dd>Permissions attach to roles and people are put in roles. Abbreviated RBAC.</dd>
<dt>rule-based</dt>
<dd>Conditions decide, independent of who is asking. Time of day is the usual example.</dd>
<dt>attribute-based</dt>
<dd>A policy evaluates attributes of the subject, the object, the action and the context. Abbreviated ABAC.</dd>
<dt>access control list</dt>
<dd>An ordered set of entries naming who may do what. The mechanism, not a model.</dd>
<dt>least privilege</dt>
<dd>Granting the minimum needed. A principle any of the models can implement or fail to.</dd>
<dt>time-of-day restriction</dt>
<dd>A rule that permits access only during stated hours.</dd>
</dl>

## What breaks without this

**A file's permissions look correct and the operation fails.** Two mechanisms are
in play, they disagree, and the one shown by an ordinary listing is not the one
that decided.

**A shared folder ends up readable by everybody.** Somebody with the authority to
share it did, once, for a good reason, and nothing ever narrowed it again.

**A role is created per person.** Four hundred roles for four hundred people is a
directory with extra steps, and none of the benefit.

**A policy cannot express the actual rule.** The requirement is about the device
and the time, the model available is about the person, and the rule gets written
down in a procedure instead.

<figure class="learn-figure">
<svg viewBox="0 0 720 300" role="img" aria-labelledby="acm-title" style="width:100%;height:auto;">
<title id="acm-title">One request to delete one file, put to six access control models, which return four denials and two permits for six different reasons</title>
<g fill="currentColor">
<text x="14" y="20" font-size="11">one request: sam wants to delete payroll.csv at 02:14 from an unmanaged laptop</text>
<text x="176" y="44" font-size="9" fill-opacity="0.7">what the model asks</text>
<text x="486" y="44" font-size="9" fill-opacity="0.7">answer</text>
<text x="556" y="44" font-size="9" fill-opacity="0.7">because</text>
<text x="14" y="71" font-size="8.5">discretionary</text>
<rect x="164" y="54" width="306" height="26" rx="3" fill="currentColor" fill-opacity="0.05" stroke="currentColor" stroke-opacity="0.5" stroke-width="1.1"/>
<text x="176" y="71" font-size="8">the owner set the bits</text>
<rect x="478" y="54" width="62" height="26" rx="3" fill="var(--accent)" fill-opacity="0.18" stroke="var(--accent)" stroke-opacity="0.75" stroke-width="1.3"/>
<text x="509" y="71" text-anchor="middle" font-size="8">allow</text>
<text x="552" y="71" font-size="7.5" fill-opacity="0.8">sam owns it</text>
<text x="14" y="105" font-size="8.5">access control list</text>
<rect x="164" y="88" width="306" height="26" rx="3" fill="currentColor" fill-opacity="0.05" stroke="currentColor" stroke-opacity="0.5" stroke-width="1.1"/>
<text x="176" y="105" font-size="8">an entry denies delete</text>
<rect x="478" y="88" width="62" height="26" rx="3" fill="var(--red)" fill-opacity="0.18" stroke="var(--red)" stroke-opacity="0.75" stroke-width="1.3"/>
<text x="509" y="105" text-anchor="middle" font-size="8">deny</text>
<text x="552" y="105" font-size="7.5" fill-opacity="0.8">the entry wins</text>
<text x="14" y="139" font-size="8.5">mandatory</text>
<rect x="164" y="122" width="306" height="26" rx="3" fill="currentColor" fill-opacity="0.05" stroke="currentColor" stroke-opacity="0.5" stroke-width="1.1"/>
<text x="176" y="139" font-size="8">the label is not permitted</text>
<rect x="478" y="122" width="62" height="26" rx="3" fill="var(--red)" fill-opacity="0.18" stroke="var(--red)" stroke-opacity="0.75" stroke-width="1.3"/>
<text x="509" y="139" text-anchor="middle" font-size="8">deny</text>
<text x="552" y="139" font-size="7.5" fill-opacity="0.8">root does not help</text>
<text x="14" y="173" font-size="8.5">role-based</text>
<rect x="164" y="156" width="306" height="26" rx="3" fill="currentColor" fill-opacity="0.05" stroke="currentColor" stroke-opacity="0.5" stroke-width="1.1"/>
<text x="176" y="173" font-size="8">is finance-writer a role sam has</text>
<rect x="478" y="156" width="62" height="26" rx="3" fill="var(--accent)" fill-opacity="0.18" stroke="var(--accent)" stroke-opacity="0.75" stroke-width="1.3"/>
<text x="509" y="173" text-anchor="middle" font-size="8">allow</text>
<text x="552" y="173" font-size="7.5" fill-opacity="0.8">yes, since March</text>
<text x="14" y="207" font-size="8.5">rule-based</text>
<rect x="164" y="190" width="306" height="26" rx="3" fill="currentColor" fill-opacity="0.05" stroke="currentColor" stroke-opacity="0.5" stroke-width="1.1"/>
<text x="176" y="207" font-size="8">is it inside business hours</text>
<rect x="478" y="190" width="62" height="26" rx="3" fill="var(--red)" fill-opacity="0.18" stroke="var(--red)" stroke-opacity="0.75" stroke-width="1.3"/>
<text x="509" y="207" text-anchor="middle" font-size="8">deny</text>
<text x="552" y="207" font-size="7.5" fill-opacity="0.8">the request is at 02:14</text>
<text x="14" y="241" font-size="8.5">attribute-based</text>
<rect x="164" y="224" width="306" height="26" rx="3" fill="currentColor" fill-opacity="0.05" stroke="currentColor" stroke-opacity="0.5" stroke-width="1.1"/>
<text x="176" y="241" font-size="8">device managed, location, role, time</text>
<rect x="478" y="224" width="62" height="26" rx="3" fill="var(--red)" fill-opacity="0.18" stroke="var(--red)" stroke-opacity="0.75" stroke-width="1.3"/>
<text x="509" y="241" text-anchor="middle" font-size="8">deny</text>
<text x="552" y="241" font-size="7.5" fill-opacity="0.8">the device is unmanaged</text>
<text x="14" y="272" font-size="10" fill-opacity="0.85">the first two disagree about the same file, and the second one wins</text>
<text x="14" y="292" font-size="10" fill-opacity="0.85">every denial below it is for a reason the one above it cannot express</text>
</g></svg>
<figcaption>The same request under six models. Discretionary control says yes, because the owner set permissions that allow it. An access control list on the same file says no, because an entry denies that specific operation, and where both are present the entry decides. Mandatory control says no on the basis of a label rather than an identity, which is why being root does not help. Role-based says yes, because the role is genuinely held. Rule-based says no for a reason that has nothing to do with who is asking. And attribute-based says no because it is the only one of the six that can consider the device at all. Four denials, four different reasons, and no two models are redundant with each other.</figcaption>
</figure>

## The discretionary failure mode is everybody

Here is discretionary control doing exactly what it is supposed to.

```bash
# AlmaLinux 10.2, x86_64
$ echo "one file, one question, asked of two people:"; ls -l /srv/finance/payroll.csv; echo; echo "alice, who is not in the group:"; su - alice -c "head -1 /srv/finance/payroll.csv" 2>&1 | head -1; echo "bob, who is:"; su - bob -c "head -1 /srv/finance/payroll.csv" 2>&1 | head -1; echo; echo "and who decided that, which is the whole of discretionary control:"; stat -c "owner=%U group=%G mode=%a" /srv/finance/payroll.csv
one file, one question, asked of two people:
-rw-rw----. 1 root finance 35 Aug 25 18:01 /srv/finance/payroll.csv

alice, who is not in the group:
head: cannot open '/srv/finance/payroll.csv' for reading: Permission denied
bob, who is:
staff,salary

and who decided that, which is the whole of discretionary control:
owner=root group=finance mode=660
```

**Mode 660, owned by root, group finance.** Bob is in the group and reads the file.
Alice is not and does not. The mechanism is working and it is entirely
uninteresting, which is the point: this is the model most systems use for most
things and it fails for a reason that has nothing to do with mechanism.

**It fails because the person who may change the permissions is not the person
accountable for the data.** Bob can share this file. He has a reason: somebody in
another team asked for it, urgently, on a Friday. He widens the group, or copies
it somewhere more convenient, and the sharing is legitimate, authorised by the
model, and permanent.

Repeat that across an organisation for five years and you have the folder
everybody can read. No single decision was wrong, nobody exceeded their authority,
and the accumulated state is one nobody would have approved as a proposal. It is
the same shape as the privilege creep in the account topic, arriving from the
resource's side instead of the identity's.

<details class="predict">
<summary>A file is owned by sam, with mode 644, and sam runs rm on it. Predict whether it can be deleted.</summary>

**Not necessarily, and the ordinary listing will not tell you why.**

The mode names three sets of three bits, and none of them is about deletion.
Deleting a file is a modification of the directory that contains it, so the
permission that matters is write on the directory rather than anything on the file
itself. That alone catches people out.

More interesting is the case in the platform captures below, where an access
control list carries an entry denying delete. The file's mode still reads
`rw-r--r--`, the owner is still sam, and `rm` returns Permission denied, because
the list is consulted and it says no.

The general point matters more than either mechanism. On every platform in this
topic, more than one thing decides, and the one an ordinary listing shows is not
necessarily the one that decided. A trailing `+` or `.` on a Unix listing is the
only hint that something else is present, and it is easy to read past.

The habit worth building: when a permission result surprises you, ask which
mechanisms are in play before changing any of them. Loosening the one you can see
is how a file ends up world-writable and still undeletable.

</details>
<details class="deeper">
<summary>If you audit shared folders: the question that finds the problem faster than reading permissions</summary>

Auditing discretionary permissions by reading them is slow and mostly
uninformative, because a permission set tells you the current state and not
whether anybody intended it.

The question that finds problems faster is about the delta: who has been able to
change these permissions, and when did they last change. Most systems record the
second, few people look at it, and a permission last modified four years ago by
somebody who left in 2022 is a finding without anybody having to understand what
the permissions say.

The second useful question is about breadth rather than correctness. Rather than
asking whether each grant is right, ask how many people can reach this resource at
all, and compare it with how many the owner thinks can. That comparison produces
an immediate reaction from the owner, which reading a permission table never does,
and it is a single number they can act on.

The mechanism worth understanding is inheritance, because it is how breadth
appears without anybody granting anything. A permission set on a parent folder
flows down, so a grant made high in a tree reaches everything below it forever,
including things created afterwards by people who never saw the grant. Most
overly-broad access in a file estate arrives this way rather than through a direct
grant, and looking only at the resource that leaked will show a permission set
nobody set.

The practical audit therefore runs top down rather than at the resource: find the
grants highest in the tree, because those are the ones with the largest blast
radius, and there are usually very few of them. That is an afternoon rather than a
programme, and it addresses the mechanism instead of the symptom.

</details>


## Two layers that disagree

Mandatory control decides on labels rather than on identities, and the labels are
attached to everything.

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ echo "the same file question, asked of the mandatory layer instead:"; ls -Z /etc/shadow /etc/passwd 2>/dev/null; echo; echo "every process carries a label too:"; ps -eZ 2>/dev/null | head -4; echo; echo "and the policy is a matrix over those labels, not over users:"; ls /sys/fs/selinux/class 2>/dev/null | wc -l; echo "object classes, each with its own set of permissions"
the same file question, asked of the mandatory layer instead:
system_u:object_r:passwd_file_t:s0 /etc/passwd
     system_u:object_r:shadow_t:s0 /etc/shadow

every process carries a label too:
LABEL                               PID TTY          TIME CMD
system_u:system_r:init_t:s0           1 ?        00:00:07 systemd
system_u:system_r:kernel_t:s0         2 ?        00:00:00 kthreadd
system_u:system_r:kernel_t:s0         3 ?        00:00:00 pool_workqueue_release

and the policy is a matrix over those labels, not over users:
134
object classes, each with its own set of permissions
```

**Two files in the same directory with different labels**, and every process
carrying one too. `passwd_file_t` and `shadow_t` are different types, so a policy
can permit a process to read one and not the other without either file's
permissions changing.

The 134 object classes are the scope. Files are one class. Sockets, processes,
capabilities, message queues, keys and directories are others, each with its own
set of permissions, which is why this is a different kind of thing from a
permission bit rather than a stricter version of one.

**Where mandatory control is genuinely used** is worth being concrete about,
because the exam presents it as exotic. It is on by default on the Red Hat family
and on Android, where it confines every application. It is what confines a
compromised web server to the things a web server does. And it is used in the
environments the model was designed for, where a classification level attaches to
data and the system enforces that a process handling secret data cannot write to
an unclassified destination.
<details class="deeper">
<summary>If somebody wants to disable the mandatory layer: what is actually being asked, and the smaller answer</summary>

The request arrives in a recognisable form. Something does not work, the error is
opaque, somebody has found a forum post saying to set enforcement to permissive,
and it does indeed fix the problem.

What is actually being proposed is removing every constraint on every confined
process on the machine, to resolve one denial. Stated that way it is obviously
disproportionate, and it is worth stating that way, because the person asking is
not weighing it: they are unblocked and moving on.

The smaller answer nearly always exists and takes about ten minutes. Read the
denial, which names the source domain, the target label and the permission that
was refused. Most denials fall into two categories. A file has the wrong label,
usually because it was created somewhere else and moved rather than copied, and
relabelling fixes it permanently. Or the policy has a switch for exactly this
case, because the policy authors anticipated it, and the machine on this page has
367 of those switches for that reason.

The third category is a genuinely new behaviour the policy does not describe, and
the answer there is a local policy module. That is more work and it is bounded
work, and it produces a machine that is confined except for the one thing you
deliberately permitted, with a record of what you permitted and why.

The argument that carries weight with whoever is asking is usually not about
security. It is that permissive mode is not a fix: the denials continue to be
logged, the underlying misconfiguration is still there, and the machine will
behave differently from every other machine in the estate in ways that surface
later during an unrelated change. Turning it off trades a diagnosable problem
today for an undiagnosable one in six months.

</details>


## Role-based, rule-based, attribute-based

These three get confused because two of the names are nearly identical.

**Role-based assigns permissions to roles and people to roles.** Its virtue is
that it scales with people: a new starter in finance gets the finance role and
inherits everything. Its failure mode is role explosion, where exceptions produce
a role per person and the model has become a directory with extra steps.

**Rule-based decides on a condition rather than on an identity.** Access permitted
between 08:00 and 18:00. Access permitted from these addresses. The same rule
applies to everybody, which is what distinguishes it, and time-of-day restrictions
are its most common form.

**Attribute-based evaluates a policy over attributes** of the subject, the object,
the action and the environment. Permit if the subject's department matches the
record's owning department, and the device is managed, and the request is inside
working hours, and the record is not marked restricted. It expresses rules the
other two cannot state at all.

The comparison worth remembering: **role-based scales and attribute-based
expresses.** Role-based handles a thousand people cheaply and cannot say anything
about the device. Attribute-based can encode almost any rule and requires
attributes that are accurate and available at the moment of the decision, which is
where real deployments run into trouble.

**Least privilege is not a model.** It is a principle about how much to grant, and
any of the six can implement it or fail to. A role-based system with one role
called Everything is role-based and not least privilege.
<details class="deeper">
<summary>If you write time restrictions: the three ways they are wrong, and where they belong</summary>

Time-of-day restrictions are the standard example of rule-based control and they
go wrong in three specific ways that are worth anticipating.

**The timezone.** A rule permitting access between 08:00 and 18:00 has to say
whose clock. The server's, the user's, or a fixed reference. An organisation with
people in three countries and a rule written in the server's timezone has locked
out one office and left another permitted overnight, and nobody notices until
somebody complains rather than until somebody audits.

**The exception nobody planned.** Month end, a major incident, a release weekend.
Every restriction meets one of these within a quarter, and the response is either
a break-glass route that has to exist in advance or a temporary suspension of the
rule that becomes permanent. The first is a design decision and the second is what
happens without one.

**The assumption that time correlates with legitimacy.** The rule exists because
an incident happened at three in the morning, and it addresses that incident
rather than the class it belongs to. An attacker with working credentials uses
them at three in the afternoon instead, and the control has cost every shift
worker in the organisation something while removing one hour of an attacker's
convenience.

Where the rule belongs is the practical part. A time restriction applies to
everybody equally, so it does not belong in the role model, where it produces a
daytime and an evening version of every role. It belongs at authentication, as a
condition on the sign-in, or at the network layer. Most identity providers express
it directly as a conditional policy, which is attribute-based control under a
product name, and putting it there keeps roles about jobs.

There is a version of this that is genuinely strong and worth distinguishing: a
restriction on a small number of high-privilege accounts, where out-of-hours use
is rare and genuinely suspicious, and where the break-glass route is designed. The
weak version is the blanket one applied to everybody because of a single incident.

</details>

<details class="deeper">
<summary>If you are designing with attributes: where the data has to come from, and the freshness problem</summary>

An attribute-based decision consumes facts, and every fact has an owner, a source
system and a staleness characteristic. The policy language is the easy part.

Walk through the request at the top of this page. The subject's department comes
from the directory, which is usually accurate because HR feeds it. The role comes
from the same place. Whether the device is managed comes from the endpoint
management server, which knows about devices that have checked in recently. The
location comes from the network or from a geolocation lookup on an address, both
of which are approximate. The time comes from the system clock, which is the only
one nobody worries about. And the object's classification comes from wherever the
data was labelled, which in most organisations is nowhere.

Two things follow. The first is that an attribute-based deployment is an
integration project rather than a policy project, and the timeline is set by the
number of source systems rather than by the complexity of the rules.

The second is the freshness problem, which is more dangerous than an outage
because it fails quietly. If the endpoint management server has not heard from a
laptop for a week, is that laptop unmanaged, or is it a laptop somebody took on
leave? The policy has to decide, and the two possible answers are to deny access
to people returning from holiday or to treat a stolen machine as managed for a
week. Most deployments pick a staleness window without discussing it and discover
which side they chose during an incident.

The design advice that helps: make the policy state its own staleness tolerance
per attribute rather than accepting whatever the integration provides, and log the
attribute values that produced each decision. Without the second, a denial cannot
be explained to the person who was denied, and unexplainable denials are how a
control gets switched off.

</details>

<details class="predict">
<summary>Four hundred people, and a role-based system with four hundred and twenty roles. Predict what has gone wrong.</summary>

**Roles have stopped describing jobs and started describing people.**

The arithmetic gives it away. A role model works because many people share a role,
so a change to the role's permissions reaches everybody who needs it and a new
starter inherits a complete set on day one. Four hundred and twenty roles for four
hundred people means the average role has fewer than one member, which is a
directory of individual permission sets wearing a role model's vocabulary.

The mechanism that produces it is always the same and always reasonable in the
moment. Somebody in finance needs one extra permission the finance role does not
carry. Adding it to the finance role would give it to forty people who do not need
it, which is correctly rejected as a violation of least privilege. So a new role is
created for this one case, and the cycle repeats.

What that costs is everything the model was for. Reviews now have four hundred and
twenty things to review instead of a dozen. A permission change has to be applied
to every role that contains it, and finding them is a query nobody has written.
And a new starter cannot be given a role, because there is no role for their job,
only one for the person who did it before them.

The fix is not tidying. It is deciding what the base roles are from the jobs
rather than from the exceptions, accepting that a small number of people will hold
a base role plus one or two additional grants, and reviewing those additions rather
than pretending they are roles. An exception recorded as an exception is
manageable. An exception disguised as a role is invisible.

</details>


## Across platforms

All three carry more than one mechanism at once, and on one of them you can watch
the two disagree.

| Task | Linux | Windows | macOS |
| --- | --- | --- | --- |
| The discretionary layer | nine mode bits, plus POSIX ACLs | an ordered access control list | nine mode bits and an ACL together |
| How many distinct rights | three, per class | 23 | three, plus the ACL's own set |
| The mandatory layer | SELinux labels | integrity levels | System Integrity Protection and TCC |
| Who may change the list | the owner | the owner | the owner |

```powershell
# Microsoft Windows Server 2025 Datacenter, version 10.0.26100.0
> New-Item -Path $env:TEMP\payroll.csv -ItemType File -Force | Out-Null; (Get-Acl $env:TEMP\payroll.csv).Access | Select-Object IdentityReference, FileSystemRights, AccessControlType, IsInherited | Format-Table -AutoSize
IdentityReference         FileSystemRights AccessControlType IsInherited
-----------------         ---------------- ----------------- -----------
NT AUTHORITY\SYSTEM            FullControl             Allow        True
BUILTIN\Administrators         FullControl             Allow        True
runnervm6iq3x\runneradmin      FullControl             Allow        True

# How many distinct rights the model can express, against the three Linux offers
> [Enum]::GetNames([System.Security.AccessControl.FileSystemRights]).Count
23

# Who is permitted to change that list, which is what makes the model discretionary
> (Get-Acl $env:TEMP\payroll.csv).Owner
BUILTIN\Administrators

# And the mandatory layer that sits above all of it
> (Get-Acl $env:TEMP\payroll.csv).Sddl -replace '.*(S:.*)','$1'; whoami /groups | Select-String 'Mandatory Label' | ForEach-Object { $_.Line.Trim() }
O:BAG:S-1-5-21-1765882305-833847025-4098194446-513D:(A;ID;FA;;;SY)(A;ID;FA;;;BA)(A;ID;FA;;;LA)
Mandatory Label\High Mandatory Level                          Label            S-1-16-12288
```


# provenance: Microsoft Windows Server 2025 Datacenter, version 10.0.26100.0, runner image 20260818.207.1

**Twenty-three distinct rights against the three a mode offers.** That is the
substantive difference, and it is why a Windows permission conversation is longer:
the model distinguishes appending from writing, deleting a file from deleting a
subfolder, and reading data from reading attributes from reading permissions.

The `SDDL` on the last line is the same information in the form the system
actually stores, and the `A` at the start of each entry marks it as an allow. The
model supports deny entries too, and where both exist a deny is evaluated first,
which is the opposite of the ordered-list-first-match model from the firewall
topic and catches people who assume all ordered lists work alike.

```bash
# macOS 26.5.2, arm64
$ touch /tmp/payroll.csv; ls -l /tmp/payroll.csv
-rw-r--r--  1 runner  wheel  0 Aug 26 02:19 /tmp/payroll.csv

# The same file with any access control list shown, which is a separate mechanism
$ chmod +a "everyone deny delete" /tmp/payroll.csv 2>/dev/null; ls -le /tmp/payroll.csv
-rw-r--r--+ 1 runner  wheel  0 Aug 26 02:19 /tmp/payroll.csv
 0: group:everyone deny delete

# What the two layers disagree about, which the ordinary listing does not show
$ stat -f 'mode=%Sp owner=%Su group=%Sg' /tmp/payroll.csv; rm -f /tmp/payroll.csv 2>&1 | head -1
mode=-rw-r--r-- owner=runner group=wheel
rm: /tmp/payroll.csv: Permission denied

# The mandatory layer, which is per application rather than per user
$ sudo ls -l /Library/Application\ Support/com.apple.TCC/TCC.db 2>&1 | awk '{print $1, $3, $4, $NF}'
-rw-r--r-- root wheel Support/com.apple.TCC/TCC.db
```

**The mode says `rw-r--r--`, the owner is `runner`, and `rm` returns Permission
denied.** That is the two layers disagreeing, captured in one block, and the
access control list wins.

Notice what an ordinary `ls -l` shows: a `+` at the end of the mode string. That
single character is the only indication that a second mechanism is present, and
`ls -le` is needed to see what it says. Anybody diagnosing this from the first
listing alone will conclude the permissions are fine and go looking somewhere
else.

macOS is the clearest of the three for this lesson because both layers are visible
in four commands, and it is not a peculiarity of macOS. Windows has the same
property with integrity levels above the list, and Linux has it with SELinux above
the mode bits. On every platform in this topic, the answer to "may I" comes from
more than one place.

## Prove it

**Run it.** Create a file, set its mode, and then add a deny entry with the ACL
tooling on your platform. Watch an operation the mode permits fail, and note what
the ordinary listing shows.

**Work it out.** Take the request at the top of this page and write down, for each
of the six models, the one piece of information it needs to reach its answer. Then
say which of those your own systems could actually supply at the moment of a
request.

**Look it up.** Open SP 800-162 and find the diagram of an attribute-based
decision. Count the inputs, then count how many of them your directory currently
holds accurately.

## What trips people up

### 1. Reading the mode and stopping

A `+` or a `.` at the end of a Unix listing means something else is present. The
capture on this page shows a file the owner cannot delete despite a mode that
looks permissive.

### 2. Thinking mandatory control is exotic

It is on by default across the Red Hat family and on Android, where it confines
every application on the device.

### 3. Confusing rule-based with role-based

Rule-based decides on a condition and applies the same rule to everybody.
Role-based decides on what role somebody holds. The names are one letter apart and
the models have nothing in common.

### 4. Creating a role per person

That is role explosion, and it produces the maintenance cost of role-based access
with none of the benefit. If roles outnumber job titles by much, the model has
stopped working.

### 5. Expecting attribute-based control to work without attributes

It can express almost any rule and it needs each attribute to be accurate and
available at the moment of the decision. Most deployments fail on the attributes
rather than on the policy language.

### 6. Calling least privilege a model

It is a principle about how much to grant. Any of the six can implement it, and a
role-based system with one all-encompassing role is neither.

## Work it through

A team asks for access to a reporting system to be restricted to office hours,
because an incident involved credentials used at three in the morning. The system
implements role-based access control and nothing else.

**The tempting move is to build the time restriction into roles.** Create a
daytime role and a full-access role, and move people between them. It works for
about a month, until somebody needs evening access for a month-end close, and then
the movement between roles becomes a request queue nobody staffs.

**The move that works puts the rule where rules go.** A time restriction is
rule-based, it applies to everybody equally, and it belongs at the point of
authentication or at the network layer rather than inside the role model. Most
identity providers can express it directly as a conditional policy, which is
attribute-based control in the product's own vocabulary.

**Then the roles stay about the job.** A role describes what somebody does. A
condition describes when and from where. Mixing them produces a role model that
encodes circumstances, which is exactly how role explosion starts.

**What this rejects is solving it with the model you have.** The available tool
can be made to approximate the requirement and the approximation carries an
ongoing administrative cost that will be paid by somebody every month, invisibly,
until the restriction is quietly removed.

The residual is worth naming: a time restriction stops a credential being used at
three in the morning and does nothing about the same credential being used at
three in the afternoon by the same attacker. It addresses the specific incident
rather than the class, and if the class is the concern then the answer is about
authentication strength rather than about hours.

## Try it

**Find a file with a hidden ACL.** `ls -l` on any directory and look for a `+` or
a `.` at the end of a mode string. Then look at what the extra mechanism actually
says.

**Count your own rights.** On Windows, look at the full permission list for one
file and count the distinct rights available. Compare with the three a Unix mode
offers.

**Read a label.** `ls -Z` on a Red Hat family machine shows the mandatory label on
every file. Pick two files in the same directory and see whether they differ.

**Count your roles.** Get the list of roles in one system and compare it with the
list of job titles. If the first number is much larger, you are looking at role
explosion.

## Check yourself

<details class="qa">
<summary>What makes a model discretionary, and what is its failure mode?</summary>

The owner of a resource decides who may use it, and can change that decision.

The failure mode is accumulation. Every widening is legitimate, authorised and
individually reasonable, usually to solve somebody's immediate problem, and
nothing ever narrows the permissions again. After a few years the result is a
resource everybody can read that nobody would have approved as a proposal.

</details>

<details class="qa">
<summary>A file's mode is rw-r--r-- and its owner cannot delete it. What is happening?</summary>

A second mechanism is deciding. In the capture on this page an access control list
carries an entry denying delete, and where a list is present it is consulted
alongside the mode.

The only hint in an ordinary listing is a `+` at the end of the mode string.
Diagnosing this by loosening the mode does nothing except make the file more
permissive in a way that was never the constraint.

</details>

<details class="qa">
<summary>Where is mandatory access control actually used?</summary>

More widely than its reputation suggests. It is enabled by default across the Red
Hat family, and on Android, where it confines every application. It is what limits
a compromised service to the things that service is permitted to do, regardless of
the account it runs as.

The classification-based use it was designed for still exists in environments that
handle labelled data, but it is no longer the main deployment by volume.

</details>

<details class="qa">
<summary>What can attribute-based control express that role-based cannot, and what does it cost?</summary>

Anything about the object, the action or the context: the device's management
state, the time, the location, whether the record's owning department matches the
requester's. Role-based control knows only what role somebody holds.

The cost is the attributes. Each one has to be accurate and available at the
moment of the decision, which means integrations with the systems that hold them
and a freshness problem for each. Deployments usually fail on the attributes
rather than on the policy language.

</details>

<details class="qa">
<summary>Why is least privilege not one of the models?</summary>

Because it is a statement about how much access to grant rather than a mechanism
for deciding. Every one of the six can be used to implement it, and every one can
be used to grant far more than necessary.

A role-based system with a single role that permits everything is a correctly
functioning role-based system and a complete failure of least privilege.

</details>

## References

- [SP 800-162](https://csrc.nist.gov/pubs/sp/800/162/upd2/final) - NIST, attribute-based access control, for what an ABAC decision consumes and the architecture around it. Free. Accessed 2026-08-25.
- [SP 800-53 Rev. 5](https://csrc.nist.gov/pubs/sp/800/53/r5/upd1/final) - NIST, the access control family, for least privilege stated as a control rather than a slogan. Free. Accessed 2026-08-25.
- [SELinux Project](https://github.com/SELinuxProject/selinux/wiki) - the label model and the object classes the capture counts. Free. Accessed 2026-08-25.
- [FileSystemRights](https://learn.microsoft.com/en-us/dotnet/api/system.security.accesscontrol.filesystemrights) - Microsoft, the enumeration the Windows capture counts. Free. Accessed 2026-08-25.
- [chmod on macOS](https://ss64.com/mac/chmod.html) - the ACL syntax the macOS capture uses to add a deny entry. Free. Accessed 2026-08-25.

**Where the content came from.** The discretionary block is captured from an
AlmaLinux 10.2 container with two accounts and one group created during setup. The
label block is from the virtual machine, where SELinux is enforcing. The Windows
and macOS blocks are from disposable runners, and the macOS one creates the file,
adds the deny entry, attempts the delete and removes it again inside the capture,
so the disagreement between the two layers is a real result rather than an
illustration.

**If you also work on Linux.** The Linux+ track's
[reading and setting permissions](/learn/linux-plus/reading-and-setting-permissions)
covers the mode bits in detail, and [SELinux](/learn/linux-plus/selinux) covers
the label model this topic summarises.
