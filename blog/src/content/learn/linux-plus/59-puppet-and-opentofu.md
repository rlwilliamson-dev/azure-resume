---
title: "Puppet and OpenTofu"
description: "Puppet converges a machine toward a description and keeps it there. OpenTofu creates infrastructure that did not exist and remembers what it made. Neither competes with Ansible, and knowing which question each answers is most of the value."
deck: "Two other answers to the same problem"
track: "linux-plus"
level: "working"
order: 600
objectives:
  - "Say which question Puppet answers and which one OpenTofu answers"
  - "Read a Puppet manifest and explain how it decides its own ordering"
  - "Read a plan and say what will be created, changed, or destroyed"
  - "Explain what the state file is for and why locking it matters"
  - "Choose between the three tools for a given task"
prerequisites: ["ansible"]
tags: ["linux", "linux-plus", "puppet", "opentofu", "terraform", "automation"]
updated: 2026-08-08
draft: false
examObjectives:
  - exam: "xk0-006"
    domain: "4.0"
    objective: "4.1"
sources:
  - title: "Puppet documentation"
    url: "https://www.puppet.com/docs/puppet/8/puppet_index.html"
    publisher: "Puppet"
    accessed: 2026-08-08
    tier: 1
  - title: "Puppet resource types"
    url: "https://www.puppet.com/docs/puppet/8/cheatsheet_core_types.html"
    publisher: "Puppet"
    accessed: 2026-08-08
    tier: 1
  - title: "OpenTofu documentation"
    url: "https://opentofu.org/docs/"
    publisher: "OpenTofu"
    accessed: 2026-08-08
    tier: 1
  - title: "OpenTofu: State"
    url: "https://opentofu.org/docs/language/state/"
    publisher: "OpenTofu"
    accessed: 2026-08-08
    tier: 1
  - title: "OpenTofu: Providers"
    url: "https://opentofu.org/docs/language/providers/"
    publisher: "OpenTofu"
    accessed: 2026-08-08
    tier: 1
  - title: "puppet-apply(8)"
    url: "https://www.puppet.com/docs/puppet/8/man/apply.html"
    publisher: "Puppet"
    accessed: 2026-08-08
    tier: 1
symptoms:
  - symptom: "Resource deleted outside the tool and the plan wants to recreate it"
    anchor: "state-is-what-makes-that-possible"
  - symptom: "Puppet manifest runs resources in an unexpected order"
    anchor: "puppet-decides-its-own-order"
---

> **Before you read.** Ansible configured your fifty web servers beautifully. Then
> somebody asks two questions.
>
> "What stops these drifting between our Ansible runs?" And: "who creates the
> servers in the first place, the load balancer, the DNS records, the firewall
> rules?"
>
> **Ansible is a poor answer to both, and the reasons are different.**

Ansible is push-based, so nothing happens between runs; and it configures machines
that exist rather than bringing them into being. Those are two separate gaps, and
they have two separate tools.

**Puppet** runs continuously on each machine, dragging it back toward a description
every thirty minutes. **OpenTofu** creates infrastructure through APIs and keeps a
record of what it made, so it can change or destroy it later.

Neither replaces Ansible. All three are routinely used together, and the exam
expects you to know which answers which.

### Some words you will need

<dl class="terms">
<dt>manifest</dt>
<dd>A Puppet file describing resources. Extension <code>.pp</code>.</dd>
<dt>catalog</dt>
<dd>The compiled, host-specific result of the manifests. What actually gets applied.</dd>
<dt>resource</dt>
<dd>One thing being managed. A file, a package, a user, a cloud instance.</dd>
<dt>provider</dt>
<dd>An OpenTofu plugin that knows how to talk to one API. AWS, Azure, or <code>local</code>.</dd>
<dt>plan</dt>
<dd>OpenTofu's preview of what it would create, change, or destroy.</dd>
<dt>state</dt>
<dd>OpenTofu's record mapping your configuration to real objects it created.</dd>
<dt>facter</dt>
<dd>Puppet's fact-gathering tool. The equivalent of Ansible's facts.</dd>
</dl>

## What breaks without this

**Drift returns between runs.** A push tool leaves a window, and somebody always
uses it.

**Nothing creates the infrastructure.** Machines, networks, DNS records, and load
balancers get made by hand in a console, which is a runbook problem with a nicer
interface.

**Nothing knows what it made.** Without state, a tool cannot tell an instance it
created from one somebody else did, so it cannot safely change or remove anything.

**And the estate cannot be destroyed.** A test environment nobody can tear down
reliably is a test environment that runs permanently and costs money.

## Puppet: convergence, continuously

A manifest describes resources. This one manages a directory, a file, and a user:

```puppet
file { '/srv/site':
  ensure => directory,
  mode   => '0755',
}

file { '/srv/site/index.html':
  ensure  => file,
  content => "Managed by Puppet\n",
  mode    => '0644',
  require => File['/srv/site'],
}

user { 'deploy':
  ensure => present,
  shell  => '/usr/sbin/nologin',
}
```

**The syntax is `type { 'title': attribute => value }`**, and it is declarative in a
stricter sense than Ansible: these are statements about what should be true, with no
implied order.

`puppet apply --noop` is the check mode, and reports without changing:

```bash
# Debian 13 (trixie), x86_64
$ cd /root/pp; puppet --version; echo "--- noop: what would change ---"; puppet apply --color=false --noop site.pp 2>&1 | tail -6
8.10.0
--- noop: what would change ---
Notice: /Stage[main]/Main/File[/srv/site]/ensure: created (noop)
Notice: /Stage[main]/Main/File[/srv/site/index.html]/ensure: defined content as '{sha256}d8a6473563979588d4c4bb2e1be20b5f956c7f10b7b4497c8b2cfa72fd242b9c' (noop)
Notice: /Stage[main]/Main/User[deploy]/ensure: created (noop)
Notice: Class[Main]: Would have triggered 'refresh' from 3 events
Notice: Stage[main]: Would have triggered 'refresh' from 1 event
Notice: Applied catalog in 0.03 seconds
```

**`(noop)` on each line means nothing happened.** The resource path
`/Stage[main]/Main/File[/srv/site]` is Puppet's identifier for a resource, and
it is what error messages will name, worth being able to read.

The content is reported as a SHA-256 rather than as text, which is how Puppet
compares file contents: it hashes rather than diffs by default. `--show_diff`
gives the actual difference.

<details class="predict">
<summary>The manifest is applied for real, then applied again immediately with nothing changed in between. What does the second run report?</summary>

```bash
# Debian 13 (trixie), x86_64
$ cd /root/pp; puppet apply --color=false site.pp >/dev/null 2>&1; echo "=== SECOND RUN ==="; puppet apply --color=false site.pp 2>&1 | tail -3
=== SECOND RUN ===
Notice: Compiled catalog for 3ef721a0f87e.home.arpa in environment production in 0.04 seconds
Notice: Applied catalog in 0.03 seconds
```

</details>

Two lines and no resources mentioned at all. Puppet reports only what it
changed, so silence is success, the same idempotence as Ansible's `changed=0`,
expressed by absence rather than by a count.

"Compiled catalog" is the step worth understanding. Puppet does not apply the
manifest directly. It compiles the manifests, the facts about this host, and
any data into a **catalog**, a host-specific list of resources with
dependencies resolved, and then applies that. In a client-server deployment
the compilation happens on the server and the catalog is sent to the agent.

## Puppet decides its own order

This is the genuine difference from Ansible and the thing that disorients people.

**Ansible runs tasks top to bottom.** Puppet does not. Resources in a manifest have
no implied order at all, and Puppet builds a dependency graph and chooses.

**You express order through relationships:**

| Metaparameter | Means |
| --- | --- |
| `require => File['/srv/site']` | Apply that one first |
| `before => Service['nginx']` | Apply this one first |
| `notify => Service['nginx']` | That one refreshes if this changes |
| `subscribe => File['/etc/nginx.conf']` | This refreshes if that changes |

In the manifest above, `require => File['/srv/site']` is why the directory is
created before the file in it. **Without that line, Puppet might do either
first**, and the manifest would work most of the time and fail unpredictably,
which is a much worse failure than failing every time.

**`notify` and `subscribe` are the same relationship from opposite ends**, and they
are Puppet's handlers: a service subscribing to a config file restarts when it
changes, once, at the right point in the graph.

**Why anybody would want this:** the graph means Puppet can apply independent
resources in parallel, and it means a module can declare its own internal ordering
without knowing where in a larger manifest it will be included. The cost is that
ordering bugs are invisible until they bite.

<details class="deeper">
<summary>If you already administer Linux: agent and agentless, and what the Puppet server is actually for</summary>

Puppet is usually described as agent-based, and the standalone `puppet apply` above
shows that is a deployment choice rather than a property of the tool.

**`puppet apply` is agentless.** It compiles and applies locally, needs no
server, and is exactly comparable to running Ansible against localhost. It is
a legitimate production model. The manifests are distributed by Git and
applied by a timer, and some large estates run this way deliberately.

**The agent-and-server model adds four things**, and they are the reason it exists:

**Continuous convergence.** The agent runs every 30 minutes by default, so drift is
corrected without anybody initiating anything. This is the gap Ansible leaves, and
it is Puppet's central claim.

**Centralised compilation.** The catalog is built on the server, so the manifests
and the data never leave it. A compromised node has its own catalog and not the
source for everybody else's.

**Certificate-based identity.** Every agent has an X.509 certificate signed by
the Puppet CA, and the server decides what catalog that identity receives.
This is the same chain-of-trust machinery as lesson 48, applied to
configuration management, and it means a node cannot request somebody else's
secrets by claiming their name.

**Reporting.** Every run sends a report, so the server knows which nodes converged,
which failed, and what changed. That is a fleet-wide drift dashboard for free, and
it is genuinely hard to replicate with a push tool.

**The costs are equally concrete.** An agent on every machine is software to
install, patch, and troubleshoot. The certificate infrastructure is another
thing that expires, an agent whose certificate has lapsed silently stops
converging, which is a failure mode with no symptom until you look. And the
server is a capacity concern at scale, because catalog compilation is
CPU-heavy.

**The practical split in the industry** is that Ansible won the "configure it now"
job on its zero-install story, and Puppet retains the "keep it that way forever"
job on estates large enough for continuous enforcement to be worth the agent. Many
organisations run both, and that is not indecision.

</details>

## OpenTofu: making things that do not exist

Puppet and Ansible configure machines. OpenTofu creates them (and networks,
databases, DNS records, and load balancers) by calling APIs.

**A provider is a plugin that knows one API.** There are thousands: AWS, Azure,
Google, Kubernetes, GitHub, Cloudflare. The `local` provider used here manages files
on the machine, which makes the mechanics visible without a cloud account.

```hcl
terraform {
  required_providers {
    local = {
      source  = "opentofu/local"
      version = "~> 2.5"
    }
  }
}

resource "local_file" "motd" {
  filename        = "/srv/motd"
  content         = "Managed by OpenTofu. Do not edit.\n"
  file_permission = "0644"
}
```

**`resource "type" "name"`** declares one thing. The name is yours and is how
you refer to it elsewhere, `local_file.motd.filename`, which is how resources
are wired together without hardcoding values.

**`tofu plan` shows what would happen, and it is the command that matters:**

```bash
# Debian 13 (trixie), aarch64
$ cd /root/infra; tofu version | head -2; echo "--- what it will do ---"; tofu init -no-color >/dev/null 2>&1; tofu plan -no-color 2>&1 | tail -14
OpenTofu v1.10.6
on linux_arm64
--- what it will do ---
      + content_sha256       = (known after apply)
      + content_sha512       = (known after apply)
      + directory_permission = "0777"
      + file_permission      = "0644"
      + filename             = "/srv/motd"
      + id                   = (known after apply)
    }

Plan: 1 to add, 0 to change, 0 to destroy.

─────────────────────────────────────────────────────────────────────────────

Note: You didn't use the -out option to save this plan, so OpenTofu can't
guarantee to take exactly these actions if you run "tofu apply" now.
```

**`Plan: 1 to add, 0 to change, 0 to destroy` is the line to read**, and on a real
estate it is the line that stops an outage. A plan reporting `0 to destroy` when you
expected zero is a change you can approve; one reporting `14 to destroy` when you
changed a tag is a provider forcing replacement, and finding that out before
`apply` is the entire point.

**`(known after apply)` marks values that do not exist yet**, an ID the API
will assign. That is why a plan cannot always be complete, and why `-out`
exists to save a plan so that `apply` executes exactly what was reviewed.

**`tofu init` downloads the providers** and must run first in a new directory. It is
also what creates the lock file pinning provider versions, which belongs in Git.

## State is what makes that possible

<details class="predict">
<summary>The configuration is applied, creating the file. Then it is applied again with nothing changed. Then somebody deletes the file outside OpenTofu entirely. What does each <code>plan</code> say?</summary>

```bash
# Debian 13 (trixie), aarch64
$ cd /root/infra; tofu init -no-color >/dev/null 2>&1; tofu apply -no-color -auto-approve 2>&1 | tail -6; echo "=== PLAN AGAIN ==="; tofu plan -no-color 2>&1 | tail -3

Plan: 1 to add, 0 to change, 0 to destroy.
local_file.motd: Creating...
local_file.motd: Creation complete after 0s [id=e42fb7825ca4214eea1a62b832741f10b2904675]

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
=== PLAN AGAIN ===

OpenTofu has compared your real infrastructure against your configuration and
found no differences, so no changes are needed.
```

```bash
# Debian 13 (trixie), aarch64
$ cd /root/infra; tofu init -no-color >/dev/null 2>&1; tofu apply -no-color -auto-approve >/dev/null 2>&1; echo "--- somebody deletes it outside tofu ---"; rm -f /srv/motd; tofu plan -no-color 2>&1 | tail -6
--- somebody deletes it outside tofu ---
Plan: 1 to add, 0 to change, 0 to destroy.

─────────────────────────────────────────────────────────────────────────────

Note: You didn't use the -out option to save this plan, so OpenTofu can't
guarantee to take exactly these actions if you run "tofu apply" now.
```

</details>

**Three different answers, and the third is drift detection.** OpenTofu knew the
file should exist because its **state** said it created one, checked, found it gone,
and planned to recreate it.

**Read the phrasing of the second plan carefully:** "compared your real
infrastructure against your configuration". That comparison is only possible
because state records which real object corresponds to which resource block:
`local_file.motd` is the file with id `e42fb78...`. Without that mapping the
tool would have no idea whether a file it can see is one it made.

**`terraform.tfstate` is a JSON file**, and everything lesson 57 said about it
applies: it contains generated passwords and keys in plaintext, two concurrent runs
corrupt it, and losing it does not destroy your infrastructure but destroys your
ability to manage it.

| Command | Does |
| --- | --- |
| `tofu init` | Download providers, create the lock file |
| `tofu plan` | Show what would change. **Changes nothing.** |
| `tofu apply` | Make it so |
| `tofu destroy` | Remove everything in state |
| `tofu fmt` | Reformat to canonical style |
| `tofu validate` | Check syntax and internal consistency |
| `tofu import` | Adopt a resource that exists but is not in state |

**`tofu destroy` is a real command that really works**, which is a feature and a
hazard. It is how a test environment costs nothing overnight, and it is why nobody
should have credentials that can run it against production.

<details class="deeper">
<summary>If you already administer Linux: why OpenTofu exists at all, and what a fork of a licence means for you</summary>

OpenTofu is a fork of Terraform, and the reason is worth knowing because the same
thing keeps happening to infrastructure tools.

**In August 2023, HashiCorp relicensed Terraform** from the Mozilla Public License
to the Business Source License. BSL is not an open source licence: it forbids use
that competes with the vendor, and converts to an open licence only after a delay,
typically four years per version.

**For most administrators the direct effect was nil**, using Terraform to
manage your own infrastructure was never the prohibited use. The effect was on
the ecosystem: companies building products around Terraform, and anyone whose
policy requires OSI-approved licences, suddenly could not.

**OpenTofu forked from the last MPL version**, was donated to the Linux
Foundation, and is a drop-in replacement: `tofu` accepts the same `.tf` files,
the same state format, and the same providers. Migration is largely renaming
the binary.

**Three practical consequences:**

**The exam names OpenTofu**, which is a reasonable signal about where vendor-neutral
material is heading. Knowing both names and that they are the same thing is enough.

**Providers are a separate question.** The registry OpenTofu uses is its own, and
the major providers are permissively licensed and available to both. That was not
guaranteed at the time of the fork and is worth checking for anything niche.

**The general lesson is about dependency risk in infrastructure tooling.** A
tool that manages your entire estate is a dependency you cannot casually
replace, and its licence is a property of that dependency. The same pattern
has now played out with Redis, Elasticsearch, MongoDB, and Terraform,
commercial open source relicensing once the ecosystem is captive, followed by
a foundation-hosted fork.

**What that argues for practically** is preferring tools under a foundation or a
permissive licence for anything load-bearing, and knowing what your exit looks like
before you need it. For configuration management specifically, both Ansible and
Puppet remain open source, and Puppet's own commercial arm has been through two
ownership changes without a relicensing.

</details>

<details class="deeper">
<summary>If you already administer Linux: modules, variables, and the moment one configuration has to serve two environments</summary>

Both tools hit the same wall at the same point: production and staging need to be
the same shape and different sizes, and copying the configuration is how they drift
apart.

**OpenTofu's answer is modules and variables.** A module is a directory of `.tf`
files taking inputs and returning outputs:

```hcl
module "web_tier" {
  source        = "./modules/web-tier"
  instance_count = var.instance_count
  instance_type  = var.instance_type
  environment    = var.environment
}
```

Then one variable file per environment, and the same module produces both:

```
tofu apply -var-file=environments/production.tfvars
tofu apply -var-file=environments/staging.tfvars
```

**The state has to be separate too**, which is the part people get wrong. One state
file for both environments means a mistake in staging can plan a destroy in
production. **Workspaces** are the built-in answer and are widely considered the
weaker one, because they share a backend and it is easy to apply to the wrong
workspace. Separate directories with separate backend configurations are more
verbose and much harder to get wrong.

**Puppet's answer is Hiera**, which separates data from code entirely. The manifests
say *what* resources exist; Hiera says what values they take, looked up by a
hierarchy you define:

```yaml
# hiera.yaml
hierarchy:
  - name: "Per-node"
    path: "nodes/%{trusted.certname}.yaml"
  - name: "Per-environment"
    path: "environments/%{server_facts.environment}.yaml"
  - name: "Common"
    path: "common.yaml"
```

Most specific wins. A value in a node's own file overrides the environment's,
which overrides the default, and the manifest never mentions any of it, it
just asks for `nginx_worker_connections`.

**`%{trusted.certname}` rather than `%{fqdn}` is a security detail worth noticing.**
Facts come from the node and a compromised node can lie about them; `trusted.` values
come from its certificate, which it cannot forge. Looking up secrets by an untrusted
fact means a node can ask for another node's data by claiming its name.

**And both tools have an encrypted-data story that belongs here rather than
bolted on:** `hiera-eyaml` encrypts values inside the Hiera files, so the
hierarchy is readable and the secrets are not. The OpenTofu equivalent is
pulling from a secrets manager at plan time rather than putting values in
`.tfvars`, because `.tfvars` in Git is the same mistake as a password in a
playbook, and the values end up in state regardless.

**The shape both arrive at is the same:** code that is identical across
environments, data that differs, and secrets that live in neither. Any arrangement
where staging and production have separately maintained configurations will drift,
and then staging stops testing anything.

</details>

## Which one, for what

The distinction that matters, and the one interviews ask about:

| | Ansible | Puppet | OpenTofu |
| --- | --- | --- | --- |
| Answers | Configure it **now** | Keep it **that way** | Make it **exist** |
| Model | Push | Pull, continuous | Push, API-driven |
| Needs on the target | SSH, Python | An agent | Nothing. It calls APIs. |
| Keeps state | No | No | **Yes** |
| Ordering | Top to bottom | A dependency graph | A dependency graph |
| Language | YAML | Its own DSL | HCL |
| Natural scope | A machine's configuration | A machine's configuration | Infrastructure itself |

**They compose rather than compete**, and the usual arrangement is all three:

```
OpenTofu creates the VM, the network, the security group, and the DNS record
        ↓
cloud-init sets the hostname and the SSH keys on first boot
        ↓
Ansible installs and configures the application
        ↓
Puppet keeps it that way, or a scheduled Ansible run does
```

The common mistake is using one for another's job. OpenTofu with a long
`user_data` shell script is configuration management done badly, imperative,
not idempotent, and invisible to the plan. Ansible creating cloud resources
through modules works and has no state, so it cannot tell you what it made or
remove it later.

And the honest note about scale: on a handful of machines, Ansible on a cron
timer gets you most of what Puppet offers, without an agent. The argument for
Puppet strengthens with fleet size, with the number of people making changes,
and with how much you need to *prove* that machines are compliant, which is
the audit argument from lesson 50 arriving again.

## Across distributions

| | RHEL family | Debian family |
| --- | --- | --- |
| Puppet package | `puppet-agent`, from Puppet's repo | `puppet-agent`, or `puppet` from Debian |
| Puppet config | `/etc/puppetlabs/puppet/` | The same, or `/etc/puppet/` for the Debian package |
| OpenTofu | Their own repo, or a release archive | The same |
| Facts | `facter` | `facter` |

**The Puppet packaging split catches people.** Debian ships an older `puppet`
package with its own paths; Puppet's own `puppet-agent` package uses
`/opt/puppetlabs` and `/etc/puppetlabs` on every distribution. Documentation
assumes the latter, so a Debian-packaged install has different paths from every
guide you will read.

**Neither OpenTofu nor Terraform is in the distribution repositories**, which
is deliberate on their part. The release cadence is faster than a
distribution's. That makes them the `/opt` case from lesson 08: a
self-contained third-party binary, version-pinned by you, invisible to the
package manager.

## Prove it

```
# Puppet: what would change, without changing it
puppet apply --noop --show_diff site.pp
puppet agent --test --noop

# What does Puppet think this machine is
facter os
puppet resource user deploy

# OpenTofu: the four commands in order
tofu init
tofu validate
tofu plan -out=tfplan
tofu apply tfplan

# What does state actually contain
tofu state list
tofu state show local_file.motd
```

**`puppet resource user deploy` is worth knowing**, because it works in reverse: it
inspects the machine and prints the manifest that would produce what is there. That
is the fastest way to learn the syntax and a genuine tool for capturing an existing
configuration.

**`tofu plan -out=tfplan` then `tofu apply tfplan`** is the production pattern.
Saving the plan means `apply` performs exactly what was reviewed, rather than
re-planning against an estate that may have moved in between.

## What trips people up

### 1. Expecting Puppet to run resources in order

It builds a dependency graph. Without `require`, `before`, `notify`, or
`subscribe`, the order is unspecified, so a manifest can work for months and
then fail.

### 2. `tofu apply` without reading the plan

The number that matters is `to destroy`. A provider that decides an attribute change
requires replacement will happily destroy and recreate a database.

### 3. State in Git

Plaintext secrets, and no locking. Remote backend, encrypted, locked.

### 4. Two people applying at once

Without a locking backend, the second write overwrites the first and leaves
resources that exist and are recorded nowhere.

### 5. `user_data` as configuration management

An imperative shell script inside a declarative tool. It is invisible to the plan,
not idempotent, and runs once.

### 6. Debian's `puppet` package against Puppet's `puppet-agent`

Different paths. Every guide assumes `/etc/puppetlabs`; the Debian package uses
`/etc/puppet`.

## Work it through

A team runs Ansible from a laptop to configure twelve servers. It works. They are
asked two things: prove to an auditor that the servers are compliant at any given
moment, and stand up an identical environment in a second region.

Reason it out before reading on. These are two different problems.

**The audit question is about continuous enforcement and evidence.** Ansible from a
laptop can prove what happened when somebody ran it, which is not the same as
proving the state now. Two proportionate answers:

Run Ansible on a schedule from a server, in check mode, and record the output.
`--check --diff` on a timer produces exactly the drift report the auditor
wants, and changes nothing. This is the small answer and it is often enough
for twelve servers.

**Or adopt Puppet** if the estate is growing and enforcement matters more than
reporting. The agent converges every thirty minutes and the server holds a
report per node, which is the compliance dashboard as a side effect. That is
real work (an agent everywhere, a CA to maintain) and twelve servers probably
do not justify it yet.

The second region is the OpenTofu question, and Ansible is the wrong tool for
it. Standing up an environment means creating VMs, networks, security groups,
and DNS, things that do not exist, through APIs. Ansible has cloud modules and
no state, so it can create them and cannot tell you afterwards what it made or
remove it.

The arrangement they end up with:

```
OpenTofu   defines the environment, once, applied per region with different variables
Ansible    configures the machines it created
A timer    runs Ansible in check mode nightly and reports drift
```

And the thing to warn them about: the second region will expose every
assumption their Ansible has about the first. Hardcoded IP addresses,
hostnames, and region names all surface at once. That is not a failure of the
tooling. It is the value of the exercise, because those assumptions were
always there and nobody could see them.

The point worth extracting: **"which tool" is nearly always the wrong first
question.** The right one is which of the three gaps you have (something does
not exist, something is not configured, or something does not stay configured)
and each has an obvious answer once it is named.

## Try it

Optional. Both parts run locally with no cloud account.

1. `apt install puppet` or `dnf install puppet-agent`.
2. Write the three-resource manifest from this lesson.
3. `puppet apply --noop site.pp`, then for real, then again. Watch the third run go
   quiet.
4. Delete the `require` line and read the manifest again. Convince yourself the
   order is now unspecified.
5. `puppet resource user root` and compare the output to the manifest syntax.
6. Download OpenTofu and write the `local_file` example.
7. `tofu init`, `tofu plan`, `tofu apply`, `tofu plan` again.
8. `cat terraform.tfstate` and find the id.
9. `rm` the managed file and run `tofu plan`. Then `tofu destroy`.

**Verification step.** You have it when you can say, for any given task, which
of the three gaps it falls into, and therefore which tool.

## Check yourself

<details class="qa">
<summary>Ansible, Puppet, and OpenTofu all do "infrastructure as code". What question does each one actually answer?</summary>

**Ansible: configure it now.** Push-based over SSH, nothing installed on the target,
runs when somebody runs it. Excellent for a change you want applied to fifty
machines today.

Puppet: keep it that way. An agent on each machine converges toward the
description every thirty minutes without anybody initiating it, and reports
back. That closes the window Ansible leaves between runs, which is where drift
lives.

OpenTofu: make it exist. It calls APIs to create infrastructure that is not
there (VMs, networks, DNS records, load balancers) and keeps state so it can
change or destroy what it made.

They compose rather than compete, and the normal arrangement uses all three:
OpenTofu creates the machine, cloud-init gives it a hostname and keys, Ansible
configures it, and Puppet or a scheduled Ansible run keeps it configured.

The common mistake is using one for another's job. OpenTofu with a long
`user_data` shell script is configuration management done imperatively and
invisibly to the plan. Ansible creating cloud resources works and keeps no
state, so it cannot tell you what it made or clean it up.

The right first question is not "which tool" but "which of the three gaps do I
have", and each gap has an obvious answer once named.

</details>

<details class="qa">
<summary>A Puppet manifest declares a file inside a directory it also declares. Without a <code>require</code>, what happens?</summary>

**The order is unspecified, so it may work or may fail, unpredictably.**

Puppet does not run resources top to bottom. It compiles the manifests into a
catalog with a dependency graph and applies that, choosing its own order for
resources with no declared relationship, and it can apply independent
resources in parallel.

So a file resource and the directory it lives in are, as far as Puppet is
concerned, unrelated. It might create the directory first and succeed, or attempt
the file first and fail with a missing path.

**That is worse than failing consistently**, because a manifest that works for
months and then fails after an unrelated change is very hard to diagnose.

**The fix is to state the relationship:**

```puppet
file { '/srv/site/index.html':
  ensure  => file,
  require => File['/srv/site'],
}
```

`before` is the same relationship from the other end, and `notify`/`subscribe`
add refresh semantics, a service subscribing to a config file restarts when it
changes, which is Puppet's version of a handler.

**Why the graph exists at all:** it lets Puppet parallelise independent work, and it
lets a module declare its own internal ordering without knowing where it will be
included. The cost is that a missing relationship is invisible until it bites.

</details>

<details class="qa">
<summary>Somebody deletes a resource outside OpenTofu. How does the next <code>plan</code> know, and what would happen without state?</summary>

State records the mapping. When OpenTofu created the resource it wrote down
that `local_file.motd` corresponds to the object with id `e42fb78...`. On the
next plan it reads state, checks each recorded object against reality, finds
this one gone, and reports `1 to add`.

Without state it could not do this. Configuration says a file should exist;
the real world contains files. Nothing connects a particular resource block to
a particular object, so the tool cannot tell "the one I made was deleted" from
"one exists that somebody else made". It would either recreate things that
already exist or refuse to touch anything.

This is exactly why Ansible does not need state and OpenTofu does. You can ask
a Linux machine whether nginx is installed and get a definitive answer. You
cannot ask a cloud provider which of two hundred instances belongs to this
configuration (there is no such question) so the mapping has to be recorded.

And it is why state is the most dangerous file in the repository. It contains
generated passwords and keys in plaintext, two concurrent runs corrupt it, and
losing it does not destroy the infrastructure but destroys your ability to
manage it. Remote, locked, versioned, encrypted.

`tofu refresh` reconciles state with reality, and `tofu import` adopts an
existing resource, which is how an estate built by hand comes under management
without being rebuilt.

</details>

<details class="qa">
<summary>Why should you always read a plan before applying, and which line matters most?</summary>

**`Plan: N to add, N to change, N to destroy`**, and the number that matters is
**destroy**.

Some attribute changes cannot be applied in place, so the provider decides the
resource must be replaced, destroyed and recreated. On a virtual machine that
is an outage; on a database it is data loss. The plan is where you find that
out, and it marks such resources explicitly as requiring replacement.

**The failure mode is specific and common:** somebody changes what looks like
a harmless attribute (a name, a tag, an availability zone) and the plan
reports `1 to add, 0 to change, 1 to destroy`. Applied without reading, that
is a rebuilt production database.

`(known after apply)` in the output marks values the API has not assigned yet,
which is why a plan is a prediction rather than a guarantee.

Which is what `-out` is for:

```
tofu plan -out=tfplan
tofu apply tfplan
```

Saving the plan means `apply` executes exactly what was reviewed, rather than
re-planning against an estate that may have changed between the review and the
approval. That is the production pattern, and it is what makes a pipeline's approval
step meaningful.

</details>

<details class="qa">
<summary>Puppet is described as agent-based, yet <code>puppet apply</code> needs no server. What does the agent-and-server model actually add?</summary>

**Four things, and they are why it exists:**

**Continuous convergence.** The agent runs every 30 minutes by default, so drift is
corrected without anybody initiating anything. That is the gap a push tool leaves and
Puppet's central claim.

**Centralised compilation.** The catalog is built on the server from the manifests
and the node's facts, so the source never leaves it. A compromised node has its own
catalog and not everybody else's configuration.

**Certificate-based identity.** Each agent holds an X.509 certificate signed
by the Puppet CA, and the server decides what that identity receives, the same
chain-of-trust machinery as TLS, which means a node cannot request another
node's secrets by claiming its name.

**Reporting.** Every run reports back, so the server knows which nodes converged,
which failed, and what changed. That is a fleet-wide compliance view as a side
effect, and it is genuinely hard to build with a push tool.

The costs are real: an agent to install and patch everywhere, a CA that
expires (an agent with a lapsed certificate silently stops converging, which
has no symptom until you look) and catalog compilation is CPU-heavy at scale.

So `puppet apply` is a legitimate production model, with manifests distributed
by Git and applied on a timer, and it is directly comparable to running
Ansible against localhost. On a small estate it gets most of the benefit
without the infrastructure.

</details>

## References

- [Puppet documentation](https://www.puppet.com/docs/puppet/8/puppet_index.html) - Puppet. Accessed 2026-08-08.
- [Puppet resource types](https://www.puppet.com/docs/puppet/8/cheatsheet_core_types.html) - Puppet. Accessed 2026-08-08.
- [OpenTofu documentation](https://opentofu.org/docs/) - OpenTofu. Accessed 2026-08-08.
- [OpenTofu: State](https://opentofu.org/docs/language/state/) - OpenTofu. Accessed 2026-08-08.
- [OpenTofu: Providers](https://opentofu.org/docs/language/providers/) - OpenTofu. Accessed 2026-08-08.
- [puppet-apply(8)](https://www.puppet.com/docs/puppet/8/man/apply.html) - Puppet. Accessed 2026-08-08.

Every block above with a distribution and architecture header was captured by
running the command on a Debian 13 (trixie) container. The OpenTofu blocks say
`aarch64` because its release binary crashes under emulation on this host with
a Go runtime error, so those captures were run natively on arm64. The
behaviour shown does not vary by architecture. Blocks without a header are
illustrative.
