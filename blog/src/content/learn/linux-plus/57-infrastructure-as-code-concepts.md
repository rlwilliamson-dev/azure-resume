---
title: "Infrastructure as code concepts"
description: "Declarative against imperative, what idempotence actually buys you, and why drift is the problem every configuration tool exists to solve. The vocabulary that makes Ansible, Puppet, and OpenTofu comprehensible before you touch any of them."
deck: "Fifty servers configured by hand are fifty different servers"
track: "linux-plus"
level: "working"
order: 580
objectives:
  - "Distinguish declarative from imperative and say which a given tool is"
  - "Explain idempotence and test whether an operation has it"
  - "Describe configuration drift and how it is detected"
  - "Say what state is, why some tools keep it, and what breaks when it is wrong"
  - "Choose between configuring a machine and replacing it"
prerequisites: ["scripts-that-do-real-work", "git-the-basics"]
tags: ["linux", "linux-plus", "iac", "automation", "configuration-management"]
updated: 2026-08-08
draft: false
examObjectives:
  - exam: "xk0-006"
    domain: "4.0"
    objective: "4.1"
sources:
  - title: "Ignition specification"
    url: "https://coreos.github.io/ignition/specs/"
    publisher: "Fedora CoreOS project"
    accessed: 2026-08-08
    tier: 1
  - title: "cloud-init documentation"
    url: "https://cloudinit.readthedocs.io/en/latest/"
    publisher: "Canonical"
    accessed: 2026-08-08
    tier: 1
  - title: "Automated installation with Kickstart"
    url: "https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/10/html/automatically_installing_rhel/index"
    publisher: "Red Hat"
    accessed: 2026-08-08
    tier: 1
  - title: "Debian preseed"
    url: "https://www.debian.org/releases/stable/amd64/apbs02.en.html"
    publisher: "Debian Project"
    accessed: 2026-08-08
    tier: 1
  - title: "OpenTofu: State"
    url: "https://opentofu.org/docs/language/state/"
    publisher: "OpenTofu"
    accessed: 2026-08-08
    tier: 1
  - title: "systemd-firstboot(1)"
    url: "https://man7.org/linux/man-pages/man1/systemd-firstboot.1.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-08
    tier: 1
symptoms:
  - symptom: "Two servers built the same way behave differently"
    anchor: "drift-and-the-snowflake"
  - symptom: "Read-only file system when writing to /usr as root"
    anchor: "the-other-answer-stop-configuring-and-start-replacing"
---

> **Before you read.** You build a web server. Install the packages, edit four
> config files, set two `sysctl` values, add a user, enable three services. It
> takes ninety minutes and it works.
>
> Six months later you need a second one identical to it. You have the runbook.
> You follow it exactly.
>
> **The new machine behaves differently and nobody can say why.**

Because the runbook is not what built the first machine. It is what somebody
*wrote down* about building the first machine, and the gap between those two things
is every command that was typed and not recorded, every prompt answered from
memory, and every package that has changed version since.

Infrastructure as code closes that gap by making the description executable. If the
thing that builds the server *is* the documentation, they cannot disagree.

This lesson is the vocabulary. The next three are the tools, and none of them make
sense without these five ideas.

### Some words you will need

<dl class="terms">
<dt>declarative</dt>
<dd>You describe the end state. The tool works out the steps.</dd>
<dt>imperative</dt>
<dd>You describe the steps. The end state is whatever they produce.</dd>
<dt>idempotent</dt>
<dd>Safe to apply repeatedly. The second run changes nothing.</dd>
<dt>drift</dt>
<dd>A machine no longer matching the description of it.</dd>
<dt>state</dt>
<dd>A tool's record of what it built, kept so it knows what to change next time.</dd>
<dt>convergence</dt>
<dd>Repeatedly applying a description until reality matches it.</dd>
<dt>immutable</dt>
<dd>Never changed after it is built. Replaced instead.</dd>
</dl>

## What breaks without this

**Every machine is slightly different**, so a fix that works on one does not work on
the next, and no test environment genuinely represents production.

**Rebuilding takes as long as building did.** After a failure, the recovery is
ninety minutes of somebody following a runbook rather than one command.

**Nobody can review a change to a server**, because there is nothing to
review. The change is a person typing, and the record of it is their memory.

**And the knowledge leaves when the person does.** A runbook records what somebody
thought they did, which is reliably not what they did.

## Declarative and imperative

This is the distinction that separates the tools, and it is simpler than the words
suggest.

**Imperative says what to do:**

```
apt-get install -y nginx
systemctl enable --now nginx
sed -i 's/^worker_connections.*/worker_connections 4096;/' /etc/nginx/nginx.conf
```

**Declarative says what should be true:**

```yaml
- name: nginx is installed and running
  ansible.builtin.package:
    name: nginx
    state: present

- name: nginx is enabled at boot
  ansible.builtin.service:
    name: nginx
    state: started
    enabled: true
```

**The declarative version does not say "install".** It says nginx should be present,
and the tool decides whether that means installing it, doing nothing because it is
already there, or reporting that it cannot.

**Three consequences follow, and they are the entire argument:**

**It is safe to run twice.** The second run finds everything already true and
does nothing. The imperative version runs `apt-get install` again, runs `sed`
again, and the `sed` in particular does something different the second time,
because the line it was looking for no longer matches.

**It is readable as documentation.** The declarative file *is* the answer to "how is
this server configured", and it cannot go stale, because it is also what configures
it.

**It can report without changing.** A tool that knows the desired state can
compare reality to it and tell you the difference, which is drift detection,
and the imperative version has no way to offer it.

| | Imperative | Declarative |
| --- | --- | --- |
| You write | Steps | End state |
| Second run | Repeats the steps | Does nothing |
| Order | You decide | The tool works it out |
| Examples | Shell scripts, `docker run` | Ansible, Puppet, OpenTofu, Kubernetes |

**Almost nothing is purely one or the other.** Ansible is declarative in its
modules and imperative in its ordering, tasks run top to bottom. Puppet is
more strictly declarative and works out its own order from dependencies, which
people find disorienting the first time. The useful question is not which
label a tool wears but whether running it twice is safe.

## Idempotence, and why it is the whole game

An operation is idempotent if applying it twice has the same effect as applying it
once. It is the property that makes automation trustworthy, because it turns "has
this run?" into a question nobody needs to answer.

| Not idempotent | Idempotent |
| --- | --- |
| `echo "x" >> /etc/hosts` | `lineinfile` with the same content |
| `useradd deploy` | `user: name=deploy state=present` |
| `mkdir /srv/app` | `mkdir -p /srv/app` |
| `sed -i 's/80/8080/'` | Template the whole file |

**The test is mechanical: run it twice and compare.** Anything that differs
between the first and second run is not idempotent, and a configuration tool
makes this visible by reporting a change count, which should be zero on the
second run.

The `sed` row is the one worth dwelling on, because it looks harmless. A
substitution that changed a line the first time may match nothing the second
time, or, worse, may match something else it created. Templating the whole
file removes the question: the file's contents do not depend on what they were
before.

Idempotence is what makes convergence possible. If applying the description is
safe, you can apply it on a schedule (every thirty minutes, forever) and the
machine is continuously dragged back toward the description. A change somebody
makes by hand survives until the next run and then disappears, which is either
exactly what you want or a nasty surprise, depending on whether you knew the
tool was running.

## Drift, and the snowflake

**Drift is a machine no longer matching its description.** It happens because
somebody fixed something at 3am, because a package update changed a default, or
because the description was never complete in the first place.

**A snowflake is a machine so drifted that nobody dares rebuild it**, because
nobody knows what is on it that is not written down. Every organisation has at
least one, and it is always the most important machine.

The three approaches, in increasing order of strength:

**Detect it.** Run the tool in check mode and report differences without changing
anything. `ansible-playbook --check --diff`, `puppet agent --noop`, `tofu plan`.
This is the one to start with, because it is safe and immediately tells you how bad
things are.

**Correct it.** Run the tool on a schedule so drift is undone automatically.
Puppet was designed for this. A 30-minute agent run is the default. It
requires the description to be genuinely complete, or the tool will fight with
reality forever.

**Prevent it.** Do not allow changes to running machines at all, which is immutable
infrastructure, below.

**The honest difficulty with correction** is that it punishes incomplete
descriptions in a way detection does not. A tool that manages `nginx.conf` but not
the module directory will happily revert your change to the first while leaving the
second, producing a configuration that has never existed in any description.

## Getting a machine to exist in the first place

Configuration management assumes a machine that boots and accepts connections.
Getting to that point is a separate problem with its own tools.

| Tool | Used by | Runs |
| --- | --- | --- |
| **Kickstart** | RHEL family | During installation, answering the installer |
| **Preseed** | Debian family | The same, for `debian-installer` |
| **AutoYaST** | SUSE | The same |
| **cloud-init** | Everywhere, mostly cloud | On first boot of a prebuilt image |
| **Ignition** | Fedora CoreOS, RHCOS | In the initramfs, **before** the root filesystem is up |

**Kickstart and preseed answer the installer's questions from a file**, so an
installation that would take a person twenty minutes of clicking takes none. The
file is served over HTTP or put on the install media, and the machine is told about
it on the kernel command line.

**cloud-init is the cloud-native version** and does not install anything. The
image is already built, and cloud-init personalises it on first boot:
hostname, SSH keys, users, and often a script. It reads that configuration
from a *datasource*, which is metadata the hypervisor or cloud provider
exposes to the instance.

**Ignition is the strictest of them**, and this machine uses it. The journal below
is from a machine that has been running for over a day.

<details class="predict">
<summary>Ignition provisions the machine on first boot. Given that, what timestamps would you expect on its journal entries relative to the machine's uptime, recent, or from the very first boot?</summary>

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ sudo cat /proc/cmdline | tr " " "\n" | grep -i ignition; echo "--- and what it produced ---"; sudo ls /var/lib/ignition 2>/dev/null; sudo journalctl -u ignition-files.service --no-pager -n 4
ignition.platform.id=applehv
--- and what it produced ---
Aug 07 14:14:44 localhost ignition[938]: Ignition finished successfully
Aug 07 14:14:44 localhost systemd[1]: Finished ignition-files.service - Ignition (files).
Aug 07 14:14:44 localhost systemd[1]: ignition-files.service: Deactivated successfully.
Aug 07 14:14:44 localhost systemd[1]: Stopped ignition-files.service - Ignition (files).
```

</details>

**Every entry is from the first boot and there are no later ones.** The machine has
rebooted since; Ignition did not run again, and there is no mechanism by which it
could. That is the difference between it and cloud-init, which runs on every boot
and has stages for it.

**`ignition.platform.id=applehv` on the kernel command line** is how it knows
where to look for its configuration. The platform is Apple's hypervisor here,
and would be `aws`, `gcp`, or `metal` elsewhere.

**The design decision worth noticing is that Ignition runs once, in the initramfs,
and then never again.** It cannot be re-run against a live machine. That is
deliberate: it forces every change to be a rebuild rather than an edit, which is the
immutable model made mandatory rather than encouraged.

<details class="deeper">
<summary>If you already administer Linux: state, and the two ways tools know what they built</summary>

Some tools keep a file recording what they created; others work it out by looking.
The difference decides how they fail.

**Stateless tools inspect reality.** Ansible connecting to a server asks the package
manager whether nginx is installed, asks systemd whether it is enabled, reads the
file. Nothing is remembered between runs, so nothing can be out of date.

**Stateful tools keep a record.** OpenTofu and Terraform write a state file
mapping each resource in your configuration to the real object it created,
this `aws_instance.web` is that instance ID. Without it, the tool has no way
to know whether an instance it can see is one it made.

**Why the difference exists:** you can ask a Linux machine what packages it has. You
cannot easily ask a cloud provider "which of these two hundred instances did I
create from this configuration", and even where you can, the answer costs an API
call per resource per run.

**Three problems follow from keeping state, and all three have standard answers:**

**It contains secrets.** Database passwords, generated keys, and certificates end up
in the state file in plaintext, because the tool needs to know what it set. So state
is credential material: never in Git, always encrypted at rest.

**Two people running at once corrupt it.** Both read, both act, both write,
and the second overwrites the first, leaving records of resources nobody can
now find. The answer is **state locking**: a remote backend takes a lock for
the duration of a run and everybody else waits. S3 with DynamoDB, or a
Terraform or OpenTofu cloud backend. A team using local state files has this
problem and usually does not know yet.

**It drifts from reality.** Somebody deletes an instance in the console and
the state still lists it. `tofu refresh` reconciles, and `tofu import` adopts
a resource that exists but is not in state, which is how you bring an existing
estate under management without rebuilding it.

**The practical rule:** state is the most valuable and most dangerous file in
an infrastructure repository. Remote, locked, versioned, encrypted, and backed
up, because losing it does not destroy the infrastructure, it destroys your
ability to manage it, and the recovery is importing every resource by hand.

</details>

## The other answer: stop configuring and start replacing

Everything above assumes you change machines. The alternative is not changing them
at all.

**Immutable infrastructure means a running machine is never modified.** A change to
the configuration produces a new image, and new instances replace the old ones.
There is no drift, because there is nothing to drift.

This machine enforces it:

<details class="predict">
<summary>The command runs as root, and root normally ignores file permissions. What happens when it writes a file into <code>/usr</code> on an image-based system?</summary>

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ sudo touch /usr/bin/newfile; echo "rc=$?"; findmnt -no OPTIONS /usr | tr "," "\n" | head -3
touch: cannot touch '/usr/bin/newfile': Read-only file system
rc=1
ro
relatime
seclabel
```

</details>

**Refused, and not by permissions.** `/usr` is mounted read-only, so the
question never reaches the permission check, which is why root cannot override
it. This is the usr-merge from lesson 04 paying off: everything the vendor
ships is in one subtree, so one subtree can be made read-only and verified.

What that buys, and what it costs:

| | Mutable | Immutable |
| --- | --- | --- |
| Change a config | Edit and reload | Build a new image, replace the instance |
| Drift | Possible, needs managing | **Impossible** |
| Rollback | Undo the change, hope | Redeploy the previous image |
| Emergency fix | Fast | **Slow.** Build, test, deploy. |
| Suits | Long-lived, stateful servers | Stateless, scaled, cloud |

The cost is real and worth stating plainly. An urgent fix that would be a
one-line edit becomes a build and a deployment, and on a bad day that is the
difference between five minutes and an hour. Systems that adopt this
successfully invest in making deployment fast, because the model is only
tolerable if it is.

And it does not fit everything. A database server with terabytes of local
state is not replaced casually. The usual arrangement is immutable for the
stateless tier and carefully managed configuration for the stateful one. The
containers lesson is the same argument at a smaller scale.

<details class="deeper">
<summary>If you already administer Linux: testing infrastructure code, and why "it applied cleanly" is not a test</summary>

A playbook that runs without error has demonstrated that it runs without error. That
is a much weaker claim than it feels like, and it is the claim most teams stop at.

**Four levels, each answering a different question:**

**Does it parse?** `ansible-playbook --syntax-check`, `puppet parser validate`,
`tofu validate`. Instant, catches typos, and says nothing about behaviour. Belongs
in a pre-commit hook.

**Is it idiomatic?** `ansible-lint`, `puppet-lint`, `tflint`. These catch the
things that work and should not, a `command` module where a proper module
exists, a resource with no explicit state, a hardcoded path. `ansible-lint` in
particular flags non-idempotent patterns, which is the property that actually
matters.

Does it produce the intended state? This needs a machine. Apply to a container
or a throwaway VM and then *assert* (with `testinfra`, `goss`, or Ansible's
own `assert` module) that the port is listening, the service is enabled, the
file has the right mode. **This is the level most teams skip**, and it is the
first one that tests the thing you care about.

**Is it idempotent?** Apply twice; the second run must report zero changes. Molecule
does this for Ansible roles as a standard step, and it catches a whole class of bug
that no amount of linting will.

The cheapest version that is genuinely useful:

```
ansible-playbook -i localhost, -c local site.yml
ansible-playbook -i localhost, -c local site.yml | grep -E 'changed=[1-9]' && echo "NOT IDEMPOTENT"
```

Two runs in a container, and a grep. That fits in any pipeline and catches more than
a syntax check ever will.

**Where testing infrastructure differs from testing software** is that the
environment is most of what you are testing. A role that works on a fresh
container and fails on a real server is not a broken role. It is a role that
was tested against the wrong starting state. Testing against a machine that
resembles production, including its existing drift, is the difference between
a green pipeline and a working deployment.

**And the failure worth naming:** a pipeline that lints and syntax-checks, goes
green on every commit, and has never once applied the code to anything. It is
extremely common, it feels like testing, and it would not catch a playbook that
installs the wrong package.

</details>

## Where the tools fit

The next three lessons cover these; this is the map.

| Layer | Question | Tools |
| --- | --- | --- |
| **Provisioning** | Does the machine exist? | OpenTofu, Terraform, cloud APIs |
| **Installation** | Is there an OS on it? | Kickstart, preseed, prebuilt images |
| **First boot** | Does it have a hostname and keys? | cloud-init, Ignition |
| **Configuration** | Is it set up correctly? | Ansible, Puppet, Chef, Salt |
| **Orchestration** | Are the applications running? | Kubernetes, Swarm, Compose |
| **Delivery** | How does a change get to production? | CI/CD, GitOps |

**The layers are frequently confused in interviews and in practice.** OpenTofu
creating a virtual machine and Ansible configuring it are not competitors; they
answer different questions and are routinely used together. "We use Terraform so we
do not need Ansible" usually means somebody is provisioning machines and configuring
them with a `user_data` shell script, which works and is the imperative approach
wearing a declarative hat.

**And all of it lives in Git**, which is why the two Git lessons come before this
one. A description that is not version controlled has all the problems of a runbook
plus the false confidence of looking like code.

<details class="deeper">
<summary>If you already administer Linux: secrets in infrastructure code, and the four places they leak</summary>

The moment configuration becomes code in a repository, every credential it needs has
a place it must not be. This is the most common serious mistake in infrastructure
work.

**Four places secrets leak, roughly in order of frequency:**

**The repository itself.** A password in a playbook, committed. As the Git lesson
covered, deleting it later does not remove it from history, and the credential must
be rotated rather than merely deleted.

**The state file.** OpenTofu records what it set, including generated passwords and
private keys, in plaintext. A state file in Git is worse than a password in Git,
because nobody thinks of it as a secret.

**CI logs.** A pipeline that echoes a variable, or a tool run with `-v`,
prints credentials into a log that is retained and widely readable. Most CI
systems mask registered secrets in output, but only the ones they know about.

**The process table and environment.** From the Python lesson: `/proc/PID/environ`
is readable by the process owner, and a credential passed as a command-line argument
is visible in `ps` to everyone on the machine, for as long as it runs.

**The approaches, weakest to strongest:**

**Encrypted in the repository.** `ansible-vault` or `sops` encrypt the values, so
the file is safe to commit and the key is not in it. Simple, works offline, and the
weakness is that the decryption key still has to reach every machine that needs it.

**A secrets manager.** HashiCorp Vault, AWS Secrets Manager, or the equivalent
issues short-lived credentials on request, with an audit log of who asked. The
infrastructure code contains a *reference* rather than a value.

**Identity-based, with no stored secret at all.** The machine proves what it
is (an instance role, a Kubernetes service account, an OIDC token from the CI
system) and receives a short-lived credential. Nothing long-lived exists to
leak, which is the only version of this that is robust to the repository being
read.

**The practical progression** for a team that currently has passwords in playbooks
is: rotate everything, move to `ansible-vault` or `sops` this week, and move to
identity-based issuance when the platform supports it. Skipping to the last step is
better and rarely available immediately.

**One habit worth adopting regardless:** `git log -p | grep -iE 'password|secret|token|BEGIN.*PRIVATE KEY'` over a repository you have inherited. It is
uncomfortable and it is better to know.

</details>

## Across distributions

The concepts are universal. The installation-time tooling is not.

| | RHEL family | Debian family | SUSE |
| --- | --- | --- | --- |
| Unattended install | **Kickstart** | **Preseed** | **AutoYaST** |
| Config file | `ks.cfg` | `preseed.cfg` | `autoinst.xml` |
| Cloud first boot | cloud-init | cloud-init | cloud-init |
| Image-based variant | RHEL CoreOS, bootc | Ubuntu Core | MicroOS |
| Config management | Ansible, Puppet | Ansible, Puppet | Ansible, Salt |

**Kickstart and preseed are the exam-relevant pair**, and the thing worth
remembering is which belongs to which family. Both are handed to the installer
on the kernel command line: `inst.ks=` for Kickstart, `preseed/url=` for
preseed.

**cloud-init is the one that crosses families**, which is why it dominates in cloud
images regardless of distribution.

## Prove it

```
# Is this machine drifted from its description
ansible-playbook site.yml --check --diff
puppet agent --test --noop
tofu plan

# Is the operation idempotent
./configure.sh && ./configure.sh && echo "no change on the second run"

# What provisioned this machine
cloud-init status --long
journalctl -u ignition-files.service
ls /var/lib/cloud/instance/

# Is this machine mutable at all
findmnt -no OPTIONS /usr
```

**Check mode before apply mode, always.** `--check`, `--noop`, and `plan` all answer
"what would change" without changing it, and running one against a machine you have
inherited is the fastest possible inventory of how far reality has drifted from
whatever description exists.

## What trips people up

### 1. Treating a shell script as infrastructure as code

A script is imperative and usually not idempotent. Running it twice does something
different from running it once, which means nobody dares run it at all.

The test is whether the second run reports no changes.

### 2. Confusing the layers

Provisioning creates machines; configuration management sets them up. OpenTofu and
Ansible are not alternatives, and a `user_data` shell script is the imperative
approach in a declarative wrapper.

### 3. State files in Git

They contain generated passwords and keys in plaintext. Remote, encrypted,
locked, and versioned, never in the repository.

### 4. Correcting drift with an incomplete description

A tool that manages half the configuration will revert your change to that half and
leave the rest, producing a state that has never existed in any description.

Detect before you correct.

### 5. Expecting immutable to be free

An urgent fix becomes a build and a deploy. That is only tolerable if deployment is
fast, which is an investment rather than a consequence.

### 6. Kickstart and preseed the wrong way round

Kickstart is the RHEL family; preseed is Debian. AutoYaST is SUSE.

## Work it through

You inherit twelve web servers. There is a wiki page describing how to build one,
last edited fourteen months ago. Nobody is confident it is accurate. You are asked
to bring them under configuration management.

Reason it out before reading on. The tempting first move is the wrong one.

**Do not write the playbook from the wiki page.** It describes what somebody
believed in 2025, and the twelve machines have each drifted independently since.
Automating a description that matches none of them produces a tool that will
"correct" twelve machines into a state that has never worked.

**Find out what is actually there.** Diff the machines against each other
before comparing any of them to a description:

```
for h in web01 web02 ... ; do
    ssh "$h" 'rpm -qa | sort' > "/tmp/pkgs.$h"
done
diff /tmp/pkgs.web01 /tmp/pkgs.web02
```

The same for the config files that matter, `systemctl list-unit-files --state=enabled`,
and the `sysctl` values. **The differences are the interesting output**, and each one
is a question: was that deliberate?

**Write the description to match reality, not the wiki.** Start with what
all twelve agree on, since that is uncontroversial and gets you a working baseline.
Every disagreement is a decision somebody has to make, and making those decisions
explicitly is most of the value of this exercise.

Third, run it in check mode against every machine and read the differences.
This is the step people skip, and it is the one that catches the description
being incomplete, which it will be.

**Only then apply**, and to one machine first, out of the load balancer.

And the thing to resist: the desire to fix the drift while you are documenting
it. Those are two changes, and doing them together means that when something
breaks you cannot tell which caused it. Get the description matching reality,
apply it until it is a no-op everywhere, and *then* change the description to
what it should be.

The point worth extracting: **the description has to be true before it can be
useful.** A configuration tool is a machine for making reality match a
description, so a wrong description is not a partial improvement. It is an
efficient way to break twelve servers at once.

## Try it

Optional, and mostly reading rather than running.

1. `findmnt -no OPTIONS /usr` on any machine you have. Note whether it says `ro`.
2. `cloud-init status --long` on a cloud instance, or
   `journalctl -u ignition-files.service` on CoreOS.
3. Take any setup script you have written and run it twice. Record what differs.
4. Make it idempotent (`mkdir -p`, `grep -q || echo >>`, a check before
   `useradd`) and run it twice again.
5. On a machine you did not build, list what is enabled:
   `systemctl list-unit-files --state=enabled`. Ask how many you can explain.
6. Read one Kickstart or cloud-init file from your environment end to end.

**Verification step.** You have it when you can look at any automation and say
whether running it twice is safe, without running it.

## Check yourself

<details class="qa">
<summary>What is the practical difference between a declarative and an imperative description, and what does it buy you?</summary>

**Imperative says what to do; declarative says what should be true.**

`apt-get install nginx` is a step. `nginx should be present` is a state, and the
tool decides whether that means installing it or doing nothing.

**Three things follow, and they are the whole argument:**

Running it twice is safe. The declarative version finds everything already
true and does nothing. The imperative version repeats every step, and a `sed`
substitution in particular does something *different* the second time, because
the line it matched no longer exists.

It is documentation that cannot go stale, because the file that describes the
server is also the file that configures it. A runbook can be wrong; a playbook
that runs cannot be wrong about what it does.

It can report without acting. A tool that knows the desired state can compare
reality to it (`--check`, `--noop`, `plan`) which is drift detection. An
imperative script has no way to offer that, because it does not know what it
is aiming at.

Almost nothing is purely one or the other. Ansible is declarative in its
modules and imperative in its ordering; Puppet works out its own order from
dependencies. The useful question is not the label but whether a second run is
a no-op.

</details>

<details class="qa">
<summary>Define idempotence, and give an operation that is not idempotent along with its fix.</summary>

An operation is idempotent when applying it twice has the same effect as
applying it once.

The classic failure is appending:

```
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
```

Run nightly, that file gains a copy of the line every night. Nothing errors, and the
symptom appears months later as a file with three hundred identical lines.

**The fix is to check first, or to declare instead of append:**

```
grep -qxF "net.ipv4.ip_forward = 1" /etc/sysctl.conf || echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
```

or, declaratively, `lineinfile` in Ansible or a templated file, which removes
the question entirely, because the file's contents no longer depend on what
they were.

**The test is mechanical:** run it twice and diff the result. A configuration tool
makes this visible by reporting a change count, which should be zero on the second
run.

Why it matters beyond tidiness: idempotence is what makes convergence
possible. If applying the description is safe, you can apply it every thirty
minutes forever, and drift is corrected automatically. Without it, nobody
dares run the automation twice, so it is run once by hand and the whole point
is lost.

</details>

<details class="qa">
<summary>What is configuration drift, and why is detecting it a different problem from correcting it?</summary>

Drift is a machine no longer matching the description of it, because somebody
fixed something at 3am, a package update changed a default, or the description
was never complete.

Detection is safe and immediately useful. `ansible-playbook --check --diff`,
`puppet agent --noop`, and `tofu plan` all report what would change without
changing anything. Running one against an inherited estate is the fastest
inventory of how far reality has moved.

Correction is riskier, and the risk is specifically about incompleteness. A
tool run in enforcing mode reverts anything it manages to what the description
says. If the description covers `nginx.conf` but not the module directory, it
will revert your change to the first and leave the second, producing a
configuration that has never existed anywhere, and that nobody designed.

So the order matters: detect, understand every difference, fold the legitimate ones
into the description, and only then enforce.

**A snowflake is the end state of unmanaged drift**, a machine nobody dares
rebuild because nobody knows what is on it that is not written down. It is
always the most important machine, and it is always the one nobody wants to
touch.

Prevention is the third option, and it is immutable infrastructure: do not
permit changes to running machines at all, so there is nothing to drift.

</details>

<details class="qa">
<summary>Why do OpenTofu and Terraform keep a state file when Ansible does not, and what are the two things that make state dangerous?</summary>

Because you can ask a Linux machine what it has, and you cannot easily ask a
cloud provider which resources are yours.

Ansible connecting to a server asks the package manager whether nginx is
installed and reads the file. Nothing needs remembering. OpenTofu creating a
cloud instance has no equivalent question: "which of these two hundred
instances did I create from this configuration" is not answerable by
inspection, so it records the mapping.

**The two dangers:**

State contains secrets in plaintext. Generated passwords, private keys, and
certificates are all recorded, because the tool needs to know what it set. A
state file committed to Git is worse than a password committed to Git, because
nobody thinks of it as a credential.

Concurrent runs corrupt it. Two people apply at once, both read the old state,
both act, and the second write overwrites the first, leaving resources that
exist and are recorded nowhere. **State locking** is the fix: a remote backend
holds a lock for the run's duration. A team using local state files has this
problem already.

And it can disagree with reality, when somebody deletes something in the
console. `tofu refresh` reconciles; `tofu import` adopts an existing resource,
which is how you bring an estate under management without rebuilding it.

Losing state does not destroy your infrastructure, it destroys your ability to
manage it, and recovery means importing every resource by hand.

</details>

<details class="qa">
<summary>What does immutable infrastructure prevent, what does it cost, and where does it not fit?</summary>

It prevents drift entirely, by never modifying a running machine. A
configuration change produces a new image and new instances replace the old.
There is nothing to drift because there is nothing to change, enforced
technically on image-based systems, where `/usr` is mounted read-only and even
root gets `Read-only file system`.

The cost is the emergency fix. What would be a one-line edit and a reload
becomes build, test, deploy. On a bad day that is five minutes against an
hour, and the model is only tolerable if deployment is genuinely fast, which
is an investment teams make deliberately, not a property they get for free.

Rollback is the compensating gain, and it is a large one: redeploying the
previous image is an operation with a known outcome, where undoing a hand edit
is somebody's memory of what they changed.

Where it does not fit is state. A database with terabytes of local data is not
replaced casually, and neither is anything whose identity is tied to the
machine. The usual arrangement is immutable for the stateless tier and
carefully managed configuration for the stateful one.

That split is the same argument as containers: the thing you replace freely and the
thing you protect are different things, and pretending otherwise is how people end
up with a container that cannot be restarted.

</details>

## References

- [Ignition specification](https://coreos.github.io/ignition/specs/) - Fedora CoreOS project. Accessed 2026-08-08.
- [cloud-init documentation](https://cloudinit.readthedocs.io/en/latest/) - Canonical. Accessed 2026-08-08.
- [Automated installation with Kickstart](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/10/html/automatically_installing_rhel/index) - Red Hat. Accessed 2026-08-08.
- [Debian preseed](https://www.debian.org/releases/stable/amd64/apbs02.en.html) - Debian Project. Accessed 2026-08-08.
- [OpenTofu: State](https://opentofu.org/docs/language/state/) - OpenTofu. Accessed 2026-08-08.
- [systemd-firstboot(1)](https://man7.org/linux/man-pages/man1/systemd-firstboot.1.html) - Linux man-pages project. Accessed 2026-08-08.

Every block above with a distribution and architecture header was captured by
running the command on a Fedora CoreOS 44.20260707.3.1 virtual machine, which
is an image-based system provisioned by Ignition, so the read-only `/usr` and
the Ignition journal entries are that machine's own, not a demonstration set
up for the lesson. Blocks without a header are illustrative.
