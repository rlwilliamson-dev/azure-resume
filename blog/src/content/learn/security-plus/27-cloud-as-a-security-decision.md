---
title: "Cloud as a security decision"
description: "Where the shared responsibility line sits on each service model and the two rows it never crosses, an eleven-line template with eleven findings before anything exists, and what serverless and microservices take off your plate and put back on it."
deck: "The provider patches the hypervisor. Nobody patched the operating system, because everybody assumed the provider did"
track: "security-plus"
level: "working"
order: 280
objectives:
  - "Draw the shared responsibility line for each service model and say which rows never move"
  - "Explain why the line moves with the service model rather than with the provider"
  - "Say what infrastructure as code changes about finding a misconfiguration"
  - "Describe what serverless takes away and what it does to your logging"
  - "Explain why microservices multiply the traffic nobody inspects"
  - "Say what hybrid arrangements and third-party vendors add to the boundary"
prerequisites: ["hardening-techniques"]
tags: ["security-plus", "security", "architecture", "cloud"]
updated: 2026-10-07
draft: false
examObjectives:
  - exam: "sy0-701"
    domain: "3.0"
    objective: "3.1"
sources:
  - title: "SP 800-145, The NIST Definition of Cloud Computing"
    url: "https://csrc.nist.gov/pubs/sp/800/145/final"
    publisher: "NIST"
    accessed: 2026-10-07
    tier: 1
  - title: "SP 800-204, Security Strategies for Microservices-based Application Systems"
    url: "https://csrc.nist.gov/pubs/sp/800/204/final"
    publisher: "NIST"
    accessed: 2026-10-07
    tier: 1
  - title: "Shared Responsibility Model"
    url: "https://aws.amazon.com/compliance/shared-responsibility-model/"
    publisher: "Amazon Web Services"
    accessed: 2026-10-07
    tier: 1
  - title: "Shared responsibility in the cloud"
    url: "https://learn.microsoft.com/en-us/azure/security/fundamentals/shared-responsibility"
    publisher: "Microsoft"
    accessed: 2026-10-07
    tier: 1
symptoms:
  - symptom: "Nobody knows whether a cloud server's operating system is being patched"
    anchor: "where-the-line-sits"
  - symptom: "A misconfigured cloud resource was found in production rather than in review"
    anchor: "infrastructure-written-down"
---

> **Before you read.** A virtual machine in a public cloud is compromised through
> a vulnerability that was patched upstream fourteen months ago. The provider's
> post-incident note is two sentences long and says the hypervisor was fully
> patched throughout.
>
> **Whose job was the operating system?**

Yours. On infrastructure as a service the provider runs the hardware and the
hypervisor and hands you a machine, and everything from the operating system up is
the same job it was in your own data centre. The provider was telling the truth.
The organisation had moved a server into the cloud and quietly moved its patching
duty into an assumption.

This topic treats cloud as what it is in the objective: an architecture model with
its own security consequences, chosen on purpose, rather than a place servers go.

### Some words you will need

<dl class="terms">
<dt>service model</dt>
<dd>How much of the stack the provider runs: infrastructure, platform or software as a service.</dd>
<dt>shared responsibility</dt>
<dd>The division of security duties between provider and customer. Written in a contract, assumed everywhere else.</dd>
<dt>responsibility matrix</dt>
<dd>That division laid out per layer and per service model, so a duty has exactly one owner.</dd>
<dt>infrastructure as code</dt>
<dd>Describing infrastructure in text files that a tool reads to build it.</dd>
<dt>serverless</dt>
<dd>Running functions without managing any server, operating system or runtime.</dd>
<dt>microservices</dt>
<dd>An application split into many small services that call each other over the network.</dd>
<dt>hybrid</dt>
<dd>Some of the estate in a provider's cloud and some on premises, connected.</dd>
<dt>east-west traffic</dt>
<dd>Traffic between systems inside an environment, as opposed to traffic in and out of it.</dd>
</dl>

## Where the line sits

Every cloud arrangement draws a line through the stack. Below it the provider is
responsible, above it you are, and the service models are mostly a statement of
where the line goes.

<figure class="learn-figure">
<svg viewBox="0 0 720 334" role="img" aria-labelledby="srm-title" style="width:100%;height:auto;">
<title id="srm-title">The shared responsibility line drawn across on-premises, IaaS, PaaS and SaaS, with eight layers and the operating system row outlined</title>
<g fill="currentColor">
<text x="14" y="20" font-size="11">who is responsible for each layer, on each service model</text>
<text x="14" y="42" font-size="9" fill-opacity="0.85">the line moves down the stack as the provider takes more, and two rows never move at all</text>
<text x="222" y="64" font-size="8.5" text-anchor="middle" fill-opacity="0.8">on-premises</text>
<text x="358" y="64" font-size="8.5" text-anchor="middle" fill-opacity="0.8">IaaS</text>
<text x="494" y="64" font-size="8.5" text-anchor="middle" fill-opacity="0.8">PaaS</text>
<text x="630" y="64" font-size="8.5" text-anchor="middle" fill-opacity="0.8">SaaS</text>
<text x="14" y="90" font-size="8.5">data and who may see it</text>
<rect x="160" y="74" width="124" height="24" rx="2" fill="var(--accent)" fill-opacity="0.35"/>
<text x="222" y="90" font-size="8" text-anchor="middle" fill-opacity="0.95">you</text>
<rect x="296" y="74" width="124" height="24" rx="2" fill="var(--accent)" fill-opacity="0.35"/>
<text x="358" y="90" font-size="8" text-anchor="middle" fill-opacity="0.95">you</text>
<rect x="432" y="74" width="124" height="24" rx="2" fill="var(--accent)" fill-opacity="0.35"/>
<text x="494" y="90" font-size="8" text-anchor="middle" fill-opacity="0.95">you</text>
<rect x="568" y="74" width="124" height="24" rx="2" fill="var(--accent)" fill-opacity="0.35"/>
<text x="630" y="90" font-size="8" text-anchor="middle" fill-opacity="0.95">you</text>
<text x="14" y="117" font-size="8.5">accounts and access</text>
<rect x="160" y="101" width="124" height="24" rx="2" fill="var(--accent)" fill-opacity="0.35"/>
<text x="222" y="117" font-size="8" text-anchor="middle" fill-opacity="0.95">you</text>
<rect x="296" y="101" width="124" height="24" rx="2" fill="var(--accent)" fill-opacity="0.35"/>
<text x="358" y="117" font-size="8" text-anchor="middle" fill-opacity="0.95">you</text>
<rect x="432" y="101" width="124" height="24" rx="2" fill="var(--accent)" fill-opacity="0.35"/>
<text x="494" y="117" font-size="8" text-anchor="middle" fill-opacity="0.95">you</text>
<rect x="568" y="101" width="124" height="24" rx="2" fill="var(--accent)" fill-opacity="0.35"/>
<text x="630" y="117" font-size="8" text-anchor="middle" fill-opacity="0.95">you</text>
<text x="14" y="144" font-size="8.5">application</text>
<rect x="160" y="128" width="124" height="24" rx="2" fill="var(--accent)" fill-opacity="0.35"/>
<text x="222" y="144" font-size="8" text-anchor="middle" fill-opacity="0.95">you</text>
<rect x="296" y="128" width="124" height="24" rx="2" fill="var(--accent)" fill-opacity="0.35"/>
<text x="358" y="144" font-size="8" text-anchor="middle" fill-opacity="0.95">you</text>
<rect x="432" y="128" width="124" height="24" rx="2" fill="var(--accent)" fill-opacity="0.35"/>
<text x="494" y="144" font-size="8" text-anchor="middle" fill-opacity="0.95">you</text>
<rect x="568" y="128" width="124" height="24" rx="2" fill="currentColor" fill-opacity="0.07"/>
<text x="630" y="144" font-size="8" text-anchor="middle" fill-opacity="0.6">provider</text>
<text x="14" y="171" font-size="8.5">runtime and middleware</text>
<rect x="160" y="155" width="124" height="24" rx="2" fill="var(--accent)" fill-opacity="0.35"/>
<text x="222" y="171" font-size="8" text-anchor="middle" fill-opacity="0.95">you</text>
<rect x="296" y="155" width="124" height="24" rx="2" fill="var(--accent)" fill-opacity="0.35"/>
<text x="358" y="171" font-size="8" text-anchor="middle" fill-opacity="0.95">you</text>
<rect x="432" y="155" width="124" height="24" rx="2" fill="currentColor" fill-opacity="0.07"/>
<text x="494" y="171" font-size="8" text-anchor="middle" fill-opacity="0.6">provider</text>
<rect x="568" y="155" width="124" height="24" rx="2" fill="currentColor" fill-opacity="0.07"/>
<text x="630" y="171" font-size="8" text-anchor="middle" fill-opacity="0.6">provider</text>
<text x="14" y="198" font-size="8.5">operating system</text>
<rect x="160" y="182" width="124" height="24" rx="2" fill="var(--accent)" fill-opacity="0.35"/>
<text x="222" y="198" font-size="8" text-anchor="middle" fill-opacity="0.95">you</text>
<rect x="296" y="182" width="124" height="24" rx="2" fill="var(--accent)" fill-opacity="0.35"/>
<text x="358" y="198" font-size="8" text-anchor="middle" fill-opacity="0.95">you</text>
<rect x="432" y="182" width="124" height="24" rx="2" fill="currentColor" fill-opacity="0.07"/>
<text x="494" y="198" font-size="8" text-anchor="middle" fill-opacity="0.6">provider</text>
<rect x="568" y="182" width="124" height="24" rx="2" fill="currentColor" fill-opacity="0.07"/>
<text x="630" y="198" font-size="8" text-anchor="middle" fill-opacity="0.6">provider</text>
<text x="14" y="225" font-size="8.5">virtualisation</text>
<rect x="160" y="209" width="124" height="24" rx="2" fill="var(--accent)" fill-opacity="0.35"/>
<text x="222" y="225" font-size="8" text-anchor="middle" fill-opacity="0.95">you</text>
<rect x="296" y="209" width="124" height="24" rx="2" fill="currentColor" fill-opacity="0.07"/>
<text x="358" y="225" font-size="8" text-anchor="middle" fill-opacity="0.6">provider</text>
<rect x="432" y="209" width="124" height="24" rx="2" fill="currentColor" fill-opacity="0.07"/>
<text x="494" y="225" font-size="8" text-anchor="middle" fill-opacity="0.6">provider</text>
<rect x="568" y="209" width="124" height="24" rx="2" fill="currentColor" fill-opacity="0.07"/>
<text x="630" y="225" font-size="8" text-anchor="middle" fill-opacity="0.6">provider</text>
<text x="14" y="252" font-size="8.5">hardware and network</text>
<rect x="160" y="236" width="124" height="24" rx="2" fill="var(--accent)" fill-opacity="0.35"/>
<text x="222" y="252" font-size="8" text-anchor="middle" fill-opacity="0.95">you</text>
<rect x="296" y="236" width="124" height="24" rx="2" fill="currentColor" fill-opacity="0.07"/>
<text x="358" y="252" font-size="8" text-anchor="middle" fill-opacity="0.6">provider</text>
<rect x="432" y="236" width="124" height="24" rx="2" fill="currentColor" fill-opacity="0.07"/>
<text x="494" y="252" font-size="8" text-anchor="middle" fill-opacity="0.6">provider</text>
<rect x="568" y="236" width="124" height="24" rx="2" fill="currentColor" fill-opacity="0.07"/>
<text x="630" y="252" font-size="8" text-anchor="middle" fill-opacity="0.6">provider</text>
<text x="14" y="279" font-size="8.5">facility and power</text>
<rect x="160" y="263" width="124" height="24" rx="2" fill="var(--accent)" fill-opacity="0.35"/>
<text x="222" y="279" font-size="8" text-anchor="middle" fill-opacity="0.95">you</text>
<rect x="296" y="263" width="124" height="24" rx="2" fill="currentColor" fill-opacity="0.07"/>
<text x="358" y="279" font-size="8" text-anchor="middle" fill-opacity="0.6">provider</text>
<rect x="432" y="263" width="124" height="24" rx="2" fill="currentColor" fill-opacity="0.07"/>
<text x="494" y="279" font-size="8" text-anchor="middle" fill-opacity="0.6">provider</text>
<rect x="568" y="263" width="124" height="24" rx="2" fill="currentColor" fill-opacity="0.07"/>
<text x="630" y="279" font-size="8" text-anchor="middle" fill-opacity="0.6">provider</text>
<rect x="154" y="179" width="550" height="30" rx="3" fill="none" stroke="var(--red)" stroke-width="1.6"/>
<text x="14" y="306" font-size="9.5">the top two rows never move: on every model the data and the accounts are yours</text>
<text x="14" y="324" font-size="9" fill-opacity="0.75">the outlined row is the cold open, and it is yours on IaaS, the model where people most often assume it is not</text>
</g></svg>
<figcaption>Eight layers and four service models. Reading down a column shows where the line sits for that model; reading across a row shows when a duty leaves you. The two rows at the top are the ones that matter most and move least: whoever holds your data and decides who may sign in is responsible for both on every model, including software as a service, where the provider runs everything else. The outlined operating system row is the one that produced the incident in the cold open. It is the customer's on infrastructure as a service and the provider's from platform upward, so moving a workload from one model to the other moves the duty with it, whether or not anybody updates the runbook.</figcaption>
</figure>

**Read the top two rows first.** Data, and the accounts that may reach it, belong
to the customer on every model. A provider running a complete application for you
still cannot decide who in your organisation should see the payroll file, and it
will not stop an administrator you created from exporting it. Most cloud breaches
that make the news happen in those two rows, through a storage container left
readable or an identity with more permission than its job, and neither one is
something the provider could have patched.

**Then the row that moves most often in practice.** The operating system is yours
on infrastructure as a service and stops being yours on a platform. That single
change is what the cold open turned into an incident, and it is the line people
draw wrongly, because a cloud console makes a virtual machine look like a managed
service when it is a server somebody has to maintain.

<details class="predict">
<summary>A team moves an application from virtual machines to a managed platform. Predict which of four duties leave them: operating system patching, the instance firewall, the data, and who holds administrative accounts.</summary>

**Two leave and two stay.**

Operating system patching leaves, because on a platform there is no operating
system you can reach, so there is none you can patch. The instance firewall
largely leaves too, replaced by whatever network controls the platform exposes,
which are usually coarser and are now the only ones available.

The data stays, because it is still yours and still classified by you. The
administrative accounts stay, and they get more important rather than less: on a
virtual machine an attacker with a stolen key gets one server, and on a platform
an attacker with a stolen administrative identity gets the console that controls
all of it.

So the move removed work that was being done, and concentrated the remaining risk
into the identity layer. Whether that is an improvement depends on whether anybody
noticed the second half.

</details>

<details class="deeper">
<summary>Why the line moves with the service model and not with the provider, and where the exceptions live</summary>

It is tempting to think of shared responsibility as something each provider
defines, and they do publish their own versions. They agree closely, because the
line follows from what the customer can physically reach.

**On infrastructure as a service you can reach the operating system**, so you are
responsible for it. You chose the image, you can log in, and the provider has no
access path that would let it patch your machine without breaking the isolation it
sells you.

**On a platform you cannot reach the operating system**, so you cannot be
responsible for it. The same logic, applied one layer up, runs all the way to
software as a service, where you cannot reach the application's code either.

**The exceptions are in the middle rows and in the contract.** Network controls
are split on every model: the provider runs the physical network and you configure
the virtual one. Configuration of a software service, its sharing settings and
retention and integrations, is yours even though the code is not. And anything the
provider offers as an optional feature, encryption with keys you manage, logging
you have to switch on, backups you have to schedule, sits on your side of the line
until you turn it on, whatever the marketing suggests.

**Which makes the useful document the responsibility matrix rather than the
diagram.** One row per control, one named owner per row, for the specific services
you use. Writing it is mostly an exercise in finding the rows nobody owns, and the
operating system row in the cold open would have been one of them.

</details>

## Infrastructure written down

Infrastructure as code describes what should exist in text files that a tool reads
and builds. Its security consequence is not speed. It is that a misconfiguration
becomes something you can read before it exists.

<details class="predict">
<summary>An eleven-line template that creates one storage bucket. Predict how many problems a scanner finds in it before anything has been built.</summary>

```bash
# AlmaLinux 10.2, x86_64
$ iac-scan
4 passed, 11 failed, from 11 lines of template

pass  CKV_AWS_93   S3 bucket policy does not lockout all but root user. (Pre...
pass  CKV_AWS_19   all data stored in the S3 bucket is securely encrypted at...
pass  CKV_AWS_20   S3 Bucket has an ACL defined which allows public READ acc...
pass  CKV_AWS_57   S3 Bucket has an ACL defined which allows public WRITE ac...
FAIL  CKV_AWS_53   S3 bucket has block public ACLS enabled
FAIL  CKV_AWS_54   S3 bucket has block public policy enabled
FAIL  CKV_AWS_55   S3 bucket has ignore public ACLs enabled
FAIL  CKV_AWS_56   S3 bucket has 'restrict_public_buckets' enabled
FAIL  CKV2_AWS_62  S3 buckets should have event notifications enabled
FAIL  CKV2_AWS_61  an S3 bucket has a lifecycle configuration
FAIL  CKV_AWS_18   the S3 bucket has access logging enabled
FAIL  CKV_AWS_144  S3 bucket has cross-region replication enabled
FAIL  CKV_AWS_21   all data stored in the S3 bucket have versioning enabled
FAIL  CKV_AWS_145  S3 buckets are encrypted with KMS by default
FAIL  CKV2_AWS_6   S3 bucket has a Public Access block
```

**Eleven findings from eleven lines, and nothing had been created.**

The four public access findings at the top of the failures are the ones that
matter, and they are worth reading carefully. The template does contain a public
access block. Every setting in it is false, so it blocks nothing, and the last line
of the output is the scanner deciding that a block configured to permit everything
does not count as a block. A reviewer skimming the file would see the resource name
and assume it was protective.

The pass lines need equally careful reading, because of how the checks are named.
Two of them name a public read and a public write permission, and they passed,
which means the scanner found no such permission rather than that it approved of
one. A check's name describes what it looks at, not the good outcome.

The point of the capture is when it happened. The same eleven findings in a running
cloud account would come from an audit, after the bucket had been readable for
however long it took somebody to look. Here they come from reading a text file,
which can happen in a code review before the bucket is ever created.

</details>

**That is the argument for writing infrastructure down.** A console click is an
action that leaves, at best, a log entry. A template is a document that can be
reviewed, versioned, scanned and compared against what is actually running, and the
difference between the template and reality is the drift topic 25 described, now
measurable.

<details class="deeper">
<summary>A scanner's defaults are somebody else's policy, and one of them conflicts with a different objective</summary>

The capture failed the bucket on eleven checks, and treating all eleven as defects
would be a mistake that matters.

**Some of the checks protect against exposure.** The four public access settings
and the access logging check are close to universal: almost nobody wants a bucket
readable by the internet without a record of who read it.

**Some are operational preferences.** Lifecycle rules, event notifications and
versioning are good practice for many buckets and wrong for some. A bucket holding
build artefacts that are regenerated on demand does not need versioning, and paying
for it is a cost with no matching risk.

**And one is a policy decision that can point the wrong way.** The scanner failed
the bucket for not replicating to another region. Replication is a resilience
control, and it is also a copy of the data in a second location, possibly a second
country. For data under a residency requirement, the check the scanner wants passed
is the exact thing topic 37 is about preventing. The scanner's authors cannot know
which of your buckets that applies to.

**So a scanner's ruleset has to be adopted, not inherited.** Somebody decides which
checks are mandatory, which are advisory, and which are suppressed for which
resources, and records why. A pipeline that fails every build on every default
check gets its scanner switched off within a month, and one that suppresses
findings without recording a reason has replaced review with silence.

</details>

## Serverless and microservices

Both of these move work off your plate. Both also move a security job somewhere
less visible, which is the part that gets missed.

**Serverless removes the server entirely.** You supply a function and the provider
runs it on demand, so there is no operating system to patch, no instance to
harden, and no long-running machine for an attacker to persist on. The remaining
risk concentrates in two places: the code, which is entirely yours, and the
permissions the function runs with, which are usually far broader than it needs
because broad permissions are what make the first deployment work.

**Microservices split one application into many small services** that call each
other over the network. Each one is simpler to reason about alone. Together they
turn what used to be function calls inside one process into network traffic
between dozens of components, each of which needs to know who is calling it.

<details class="deeper">
<summary>What serverless does to your logging, and the questions you can no longer answer</summary>

On a server, a lot of evidence accumulates without anybody deciding to collect
it: process lists, login records, the filesystem, the local logs. Serverless
removes the place that evidence would have accumulated.

**A function's lifetime may be milliseconds.** There is no machine to examine
afterwards, no disk image to take, and no memory to capture, because the
environment it ran in was discarded when it returned. The order of volatility from
topic 61 has collapsed to a single item, and it has already gone.

**So the only evidence is what you arranged to emit.** If the function did not log
its inputs, its caller and its decisions, and if the platform's own invocation
logging was not switched on and retained, the record of what happened is the
provider's billing line.

**The questions that become hard** are the ones an investigation always asks. What
did this code do on Tuesday at 14:02? Which version of it was running? What data
did it touch? Each of those is answerable only if the answer was written somewhere
durable at the time, which makes logging a design requirement of the function
rather than a property of the platform.

**And the permission point applies to the logs themselves.** A function allowed to
write to the log group can, in many default configurations, also delete from it.
Logging that the thing being logged can erase is a record of what it chose to
leave.

</details>

<details class="deeper">
<summary>Microservices and the east-west traffic nobody inspects</summary>

A monolith has one front door. Requests arrive, pass the perimeter controls, and
everything after that happens inside one process where nothing can intercept it.
Split that application into forty services and the inside becomes a network.

**East-west traffic now outnumbers north-south traffic**, often by a large factor,
because one user request fans out into many internal calls. Perimeter controls see
the one request and none of the fan-out.

**Which means the internal calls need their own authentication.** If service A
accepts any request that reaches it because it assumes only service B can reach
it, then anything that compromises any service on the same network can call A. The
assumption that inside means trusted is the one zero trust exists to remove, and
microservices are where it fails first.

**The usual answer is mutual authentication between services**, each presenting a
certificate that identifies it, with a policy saying which service may call which.
That is often delivered by infrastructure alongside the services rather than in
their code, so developers do not each implement it differently.

**And the cost is visibility.** Encrypting every internal call is correct and it
also blinds any network sensor that used to inspect that traffic. The inspection
has to move to the endpoints, or to the infrastructure doing the encryption, or it
stops happening, and that decision is worth making deliberately rather than
discovering after the first internal incident.

</details>

## Hybrid, and the third parties already inside

Few organisations are entirely in one place. Hybrid considerations are mostly
about the joins between places, and third-party vendors are mostly about the joins
between organisations.

**A hybrid arrangement has two security models and a connection between them.**
On-premises controls and cloud controls are configured in different tools, by
different people, with different defaults, and the connection between them, a
private link or a site-to-site tunnel, is trusted in both directions unless
somebody restricts it. An attacker in either environment is one routing decision
away from the other.

**Identity is usually the hardest join.** Directory synchronisation between an
on-premises directory and a cloud identity service means a compromise of either
can become a compromise of both, and the synchronisation account is one of the most
privileged identities in the estate while appearing in nobody's list of
administrators.

**Third-party vendors are inside the cloud boundary in a way they rarely are on
premises.** A monitoring tool, a backup service, a security product: each typically
asks for a role in your cloud account, and the permissions requested are usually
generous. That role is a standing path into your environment, held by a company
whose own security you assessed once, if at all. Topic 70 covers assessing them;
the architecture point is to count the roles.

## Try it

**Write the matrix for one service.** Pick one cloud service you use and list
every control that applies to it, with a named owner for each. The rows with no
owner are the finding.

**Scan a template.** Run any infrastructure-as-code scanner over a template you
have, and sort its findings into exposure, operational preference and policy
decision. Count how many of the third kind it got wrong for your situation.

**Count the third-party roles.** In a cloud account you administer, list every
role that a vendor's service can assume. Then find out who approved each one.

**Find one serverless function's permissions.** Compare what it is allowed to do
with what its code actually does. The difference is the blast radius of a bug in
that function.

## Check yourself

<details class="qa">
<summary>On infrastructure as a service, who patches the guest operating system?</summary>

The customer. The provider runs the hardware and the hypervisor and hands over a
machine, and everything from the operating system upward is the customer's, exactly
as it was on premises. The provider has no access path to patch a customer's
machine without breaking the isolation it sells.

On a platform the operating system becomes the provider's, because the customer
can no longer reach it, so moving a workload between the two models moves the duty.

</details>

<details class="qa">
<summary>Which responsibilities stay with the customer on every service model?</summary>

The data and the accounts that may reach it. Even on software as a service, where
the provider runs everything else, the provider cannot decide who in the customer's
organisation should see a file, and will not stop an administrator the customer
created from exporting it.

Configuration of a service, and any optional security feature the provider offers
but does not enable by default, also stays with the customer until it is switched
on.

</details>

<details class="qa">
<summary>What does infrastructure as code change about finding a misconfiguration?</summary>

When it can be found. The capture on this page scans an eleven-line template and
reports eleven findings, including a public access block whose every setting is
false, before anything has been created.

Without the template the same findings come from auditing a running account, after
the resource has been exposed for however long it took somebody to look. With it,
they can come from a code review.

</details>

<details class="qa">
<summary>What does serverless take away, and what does it do to investigation?</summary>

It takes away the server: no operating system to patch, no instance to harden, and
no long-running machine to persist on. The risk concentrates in the code and in the
permissions the function runs with.

It also takes away the place evidence accumulates. A function may live for
milliseconds and leave no disk or memory to examine, so the only record is what the
function and the platform were configured to log, and retain, at the time.

</details>

<details class="qa">
<summary>Why do microservices need authentication between services?</summary>

Because splitting an application turns internal function calls into network
traffic, and east-west traffic between services outnumbers the requests that cross
the perimeter. A service that accepts any request because it assumes only a trusted
neighbour can reach it will accept requests from anything that compromises any
service on the same network.

Mutual authentication between services, with a policy saying which may call which,
removes that assumption, at the cost of blinding network sensors that used to
inspect the traffic.

</details>

## References

- [SP 800-145](https://csrc.nist.gov/pubs/sp/800/145/final) - NIST, the definition of cloud computing, including the service and deployment models. Free. Accessed 2026-10-07.
- [SP 800-204](https://csrc.nist.gov/pubs/sp/800/204/final) - NIST, security strategies for microservices, for service-to-service authentication and the east-west problem. Free. Accessed 2026-10-07.
- [Shared Responsibility Model](https://aws.amazon.com/compliance/shared-responsibility-model/) - Amazon Web Services, one provider's statement of where the line sits. Free. Accessed 2026-10-07.
- [Shared responsibility in the cloud](https://learn.microsoft.com/en-us/azure/security/fundamentals/shared-responsibility) - Microsoft, a second provider's version, which places the line in the same places. Free. Accessed 2026-10-07.

**Where the content came from.** The template scan is captured from an AlmaLinux
10.2 container running an open-source infrastructure-as-code scanner against a
template written for the purpose. No cloud account exists and no provider is
contacted: the scanner reads a text file and reports what that file would build.
The table is the scanner's own JSON output reduced to one line per check, with its
"Ensure" prefix dropped and long check names cut with an ellipsis rather than
reworded. There is no platform comparison, because nothing on this page depends on
the operating system the reader uses.

**If you also work on networks.** The Network+ track's
[cloud concepts and connectivity](/learn/network-plus/cloud-concepts-and-connectivity)
covers the network side of the same models.
