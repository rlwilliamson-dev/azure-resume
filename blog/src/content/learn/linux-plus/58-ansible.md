---
title: "Ansible"
description: "Ansible needs nothing installed on the machines it manages, which is most of why it won. Inventory, playbooks, modules, facts, and the changed count that tells you whether your automation is safe to run twice."
deck: "Run one command, change fifty machines"
track: "linux-plus"
level: "deep"
order: 590
objectives:
  - "Explain what agentless means and what Ansible requires on a managed host"
  - "Write an inventory and run an ad hoc command against it"
  - "Read a playbook and a PLAY RECAP, including the changed count"
  - "Use check mode and diff to find drift without changing anything"
  - "Explain facts and use one in a template"
prerequisites: ["infrastructure-as-code-concepts", "ssh-and-secure-remote-access"]
tags: ["linux", "linux-plus", "ansible", "automation", "configuration-management"]
updated: 2026-08-08
draft: false
examObjectives:
  - exam: "xk0-006"
    domain: "4.0"
    objective: "4.1"
sources:
  - title: "Ansible documentation"
    url: "https://docs.ansible.com/ansible/latest/index.html"
    publisher: "Red Hat"
    accessed: 2026-08-08
    tier: 1
  - title: "How to build your inventory"
    url: "https://docs.ansible.com/ansible/latest/inventory_guide/intro_inventory.html"
    publisher: "Red Hat"
    accessed: 2026-08-08
    tier: 1
  - title: "Ansible playbooks"
    url: "https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_intro.html"
    publisher: "Red Hat"
    accessed: 2026-08-08
    tier: 1
  - title: "Validating tasks: check mode and diff mode"
    url: "https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_checkmode.html"
    publisher: "Red Hat"
    accessed: 2026-08-08
    tier: 1
  - title: "Ansible vault"
    url: "https://docs.ansible.com/ansible/latest/vault_guide/index.html"
    publisher: "Red Hat"
    accessed: 2026-08-08
    tier: 1
  - title: "Roles"
    url: "https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_reuse_roles.html"
    publisher: "Red Hat"
    accessed: 2026-08-08
    tier: 1
symptoms:
  - symptom: "Playbook reports changed on every run"
    anchor: "the-number-that-tells-you-it-is-working"
  - symptom: "Need to know what a playbook would change before running it"
    anchor: "finding-drift-without-changing-anything"
---

> **Before you read.** A certificate needs replacing on fifty web servers. You have
> SSH access to all of them and a shell script that does it on one.
>
> A `for` loop over fifty hostnames will work, mostly. Three machines will be down.
> Two will have a slightly different path. One will half-succeed, and you will not
> know which one.
>
> **What you actually want is to run it, see a report of what changed where, and
> run it again tomorrow without doing any of it twice.**

That is Ansible, and the loop above is a fair description of what it replaces.
The difference is not that it connects over SSH, your loop does that too. The
difference is that each step describes a desired state rather than a command,
so running it again on the machines that already succeeded does nothing, and
the report tells you which of the fifty actually changed.

### Some words you will need

<dl class="terms">
<dt>inventory</dt>
<dd>The list of machines, optionally grouped. A file, or a script that generates one.</dd>
<dt>module</dt>
<dd>A unit of work that knows how to reach a desired state. <code>package</code>, <code>service</code>, <code>copy</code>.</dd>
<dt>task</dt>
<dd>One call to a module, with a name.</dd>
<dt>play</dt>
<dd>A set of tasks aimed at a set of hosts.</dd>
<dt>playbook</dt>
<dd>A YAML file containing one or more plays.</dd>
<dt>fact</dt>
<dd>Something Ansible discovered about a host, available as a variable.</dd>
<dt>handler</dt>
<dd>A task that runs only if something notified it, and only once.</dd>
<dt>idempotent</dt>
<dd>Reports <code>changed=0</code> on the second run. The property that makes all of this safe.</dd>
</dl>

## What breaks without this

**The `for` loop over hostnames fails partway** and leaves you with no record of
which machines it reached.

**You cannot safely re-run anything**, so a failed run means working out by hand
what happened and what did not.

**There is no way to ask what would change.** Every change is applied blind, on
production, with rollback consisting of remembering what it looked like before.

**And nothing is reviewable.** A change to fifty servers should be a diff somebody
approved, not a command somebody ran.

## Agentless, and why that is the whole pitch

Puppet, Chef, and Salt all install software on every managed machine that runs
continuously and talks to a server. Ansible does not.

**Ansible connects over SSH, copies a small Python program, runs it, collects the
output as JSON, and deletes it.** That is the entire transport.

What a managed machine needs:

| Requirement | Why |
| --- | --- |
| SSH access | The transport |
| Python 3 | The modules are Python |
| An account that can escalate | For anything privileged |

**Nothing else. No agent, no daemon, no port, no certificate.** Which means a
machine you were given SSH access to five minutes ago is manageable now, and
decommissioning a machine requires removing a line from a file rather than
uninstalling anything.

The trade-offs are real and worth knowing, because "agentless is better" is
not a complete thought:

It is push, not pull. Nothing happens unless somebody runs Ansible. A machine
that was off during the run stays unconfigured until the next one, where a
Puppet agent would catch up on its own. Continuous convergence is possible
with `ansible-pull` and is not the default mode.

It scales by forking. The control node opens a connection per host, in batches
of five by default. Puppet's agents each work independently, so its server
load grows much more slowly.

Latency is per task, per host. A playbook with forty tasks against a host on
another continent pays the round trip forty times, which is why `pipelining`
and `ControlPersist` exist.

Check the connection first, which is what the `ping` module is for, despite
the name, it is not ICMP:

```bash
# Debian 13 (trixie), x86_64
$ cd /root/play; ansible --version | head -3; echo "--- an ad hoc command ---"; ansible all -i inventory -m ansible.builtin.ping
ansible [core 2.19.4]
  config file = None
  configured module search path = ['/root/.ansible/plugins/modules', '/usr/share/ansible/plugins/modules']
--- an ad hoc command ---
[WARNING]: Host 'localhost' is using the discovered Python interpreter at '/usr/bin/python3.13', but future installation of another Python interpreter could cause a different interpreter to be discovered. See https://docs.ansible.com/ansible-core/2.19/reference_appendices/interpreter_discovery.html for more information.
localhost | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3.13"
    },
    "changed": false,
    "ping": "pong"
}
```

**`"changed": false` even here.** Every module reports whether it changed
anything, and `ping` never does, it connects, confirms Python works, and
returns. That is why it is the standard first test: a `SUCCESS` means SSH, the
account, and the interpreter are all working.

**The warning about interpreter discovery is worth reading rather than ignoring.**
Ansible had to guess which Python to use, and it is telling you that the guess could
change. On managed machines, `ansible_python_interpreter` in the inventory removes
the guesswork.

## Inventory and ad hoc commands

The inventory is the list of machines. At its simplest it is one host per line:

```ini
[web]
web01.example.com
web02.example.com

[db]
db01.example.com ansible_user=postgres

[production:children]
web
db
```

**Groups are the useful part.** `web` names two machines; `production` contains both
groups; `all` is built in. A play targets any of those names, so the same playbook
serves one machine or a hundred.

**Ad hoc commands are for things not worth a playbook:**

```
ansible all -i inventory -m ansible.builtin.ping
ansible web -i inventory -m ansible.builtin.service -a "name=nginx state=restarted" --become
ansible all -i inventory -a "uptime"
ansible all -i inventory -m ansible.builtin.package -a "name=curl state=present" --become
```

**`-a` passes arguments to the module**, and with no `-m` the default module runs a
command. `--become` escalates to root, which is `sudo` underneath and honours the
rules from lesson 42.

**Ad hoc is for questions, playbooks are for changes.** "What kernel is everything
running" is a fine ad hoc command; "install and configure nginx" belongs in a file
somebody can review.

## A playbook

```yaml
- name: Configure the web tier
  hosts: all
  gather_facts: true
  tasks:
    - name: A directory for the site exists
      ansible.builtin.file:
        path: /srv/site
        state: directory
        mode: "0755"

    - name: The index page is in place
      ansible.builtin.copy:
        dest: /srv/site/index.html
        content: "running on {{ ansible_distribution }} {{ ansible_distribution_version }}\n"
        mode: "0644"

    - name: A deploy user exists
      ansible.builtin.user:
        name: deploy
        shell: /usr/sbin/nologin
        state: present
```

**Read the task names.** They are written as statements of fact, "a deploy
user exists", rather than as commands, and that is the declarative habit made
visible. A task called "create the deploy user" is a small lie the second time
it runs.

**`state: present` and `state: directory` are what the module aims at.** Neither
says how. The `user` module works out whether that means running `useradd`, doing
nothing, or modifying an existing account.

**`{{ ansible_distribution }}` is a fact**, filled in per host, which is how one
playbook produces the right thing on a mixed estate.

## The number that tells you it is working

<details class="predict">
<summary>The playbook has three tasks and runs against a machine where none of them has been done. Then it runs a second time, unchanged. What does <code>changed=</code> say on each run?</summary>

```bash
# Debian 13 (trixie), x86_64
$ cd /root/play; ansible-playbook -i inventory site.yml 2>/dev/null | tail -14
ok: [localhost]

TASK [A directory for the site exists] *****************************************
changed: [localhost]

TASK [The index page is in place] **********************************************
changed: [localhost]

TASK [A deploy user exists] ****************************************************
changed: [localhost]

PLAY RECAP *********************************************************************
localhost                  : ok=4    changed=3    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
```

```bash
# Debian 13 (trixie), x86_64
$ cd /root/play; ansible-playbook -i inventory site.yml >/dev/null 2>&1; echo "=== SECOND RUN ==="; ansible-playbook -i inventory site.yml 2>/dev/null | tail -8
=== SECOND RUN ===
ok: [localhost]

TASK [A deploy user exists] ****************************************************
ok: [localhost]

PLAY RECAP *********************************************************************
localhost                  : ok=4    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
```

</details>

**`changed=3` then `changed=0`.** That is idempotence, demonstrated rather than
claimed, and it is the single most important output Ansible produces.

**Read the two words carefully, because they mean different things:**

| Word | Means |
| --- | --- |
| `changed` | The module **did something**. The machine is different now. |
| `ok` | The module checked and **the state was already correct** |
| `failed` | It could not reach the desired state |
| `skipped` | A `when:` condition was false |
| `unreachable` | Could not connect at all. Not the task's fault. |

**`ok=4` on both runs and `changed` dropping to zero is the shape you want.** The
fourth `ok` is the fact-gathering step, which always runs and never changes
anything.

**A task that reports `changed` on every run is a bug**, and it is the most
common defect in real playbooks. It usually means a `command` or `shell`
module was used where a proper module exists. Those cannot know whether they
need to run, so they always report changed. The fixes are a real module, or
`creates:` and `removes:` to tell `command` how to check.

**Why it matters beyond tidiness:** `changed` is what handlers trigger on. A task
that always reports changed restarts nginx on every run, forever, and nobody notices
until somebody asks why the graphs show a restart every thirty minutes.

## Finding drift without changing anything

Somebody edits a file by hand. The next run will fix it, but you want to know
first.

<details class="predict">
<summary><code>--check</code> runs without making changes and <code>--diff</code> shows the content difference. A file managed by the playbook has been edited by hand. What does Ansible print?</summary>

```bash
# Debian 13 (trixie), x86_64
$ cd /root/play; ansible-playbook -i inventory site.yml >/dev/null 2>&1; echo "somebody edited it by hand" > /srv/site/index.html; echo "--- check mode: what has drifted ---"; ansible-playbook -i inventory site.yml --check --diff 2>/dev/null | sed -n "/index page/,/^$/p" | head -12
--- check mode: what has drifted ---
TASK [The index page is in place] **********************************************
--- before: /srv/site/index.html
+++ after: /srv/site/index.html
@@ -1 +1 @@
-somebody edited it by hand
+running on Debian 13.6
```

</details>

**A unified diff, exactly like `git diff`**, showing what is there and what
would replace it. Nothing was changed: `--check` guarantees that.

`--check --diff` together are the most useful thing in this lesson after the
changed count. They answer "how far has this estate drifted" without touching
anything, which makes them safe to run against production at any time,
including on a schedule as a monitoring check.

The caveat that matters: check mode is a *simulation*, and some tasks cannot
be simulated. A `command` module cannot know what its command would do, so by
default it is skipped in check mode. And a task whose outcome depends on an
earlier task's change will report oddly, because the earlier change did not
actually happen. Check mode is excellent for configuration files and
misleading for long chains of dependent commands.

<details class="deeper">
<summary>If you already administer Linux: handlers, and the restart that happens once instead of nine times</summary>

Nine tasks change nginx configuration files. The service needs restarting. Putting a
restart in each task restarts it nine times; putting one at the end restarts it even
when nothing changed.

**A handler is a task that runs only when notified, and only once per play,
regardless of how many tasks notified it:**

```yaml
tasks:
  - name: The main config is in place
    ansible.builtin.template:
      src: nginx.conf.j2
      dest: /etc/nginx/nginx.conf
    notify: Reload nginx

  - name: The site config is in place
    ansible.builtin.template:
      src: site.conf.j2
      dest: /etc/nginx/conf.d/site.conf
    notify: Reload nginx

handlers:
  - name: Reload nginx
    ansible.builtin.service:
      name: nginx
      state: reloaded
```

`notify` fires only when the task reports `changed`. So a run where both files
are already correct reloads nothing, and a run where either changed reloads
exactly once. That is the behaviour you would have to write by hand in a shell
script, and it is why the changed count is load-bearing rather than cosmetic.

Four things about handlers that are not obvious:

They run at the end of the play, not immediately. So a later task cannot
depend on the handler having run. `meta: flush_handlers` forces them to run at
that point, which is occasionally necessary, for example when a service must
be restarted before a subsequent task can talk to it.

They do not run if the play fails first. A failure partway through means
configuration files are changed and the service was never reloaded, which is a
genuinely awkward state. `--force-handlers` runs them anyway.

Names are the identifier, so a typo in `notify` silently notifies nothing.
Ansible warns about this in recent versions and did not always.

`reloaded` versus `restarted` is the same distinction as lesson 33: reload
re-reads configuration without dropping connections, restart does not. Use
`reload` where the service supports it, and note that Ansible's `service`
module will not tell you if it does not. It will just restart.

The related mechanism worth knowing is `serial`, which controls how many hosts
a play runs against at once:

```yaml
- hosts: web
  serial: 2
  max_fail_percentage: 25
```

That is a rolling deployment in two lines: two machines at a time, aborting if more
than a quarter fail. Without it, a broken playbook reconfigures all fifty web
servers simultaneously.

</details>

<details class="deeper">
<summary>If you already administer Linux: roles, and the point at which a playbook stops being a file</summary>

A playbook works until it is four hundred lines and three teams need parts of it. A
**role** is the unit of reuse, and it is a directory layout rather than a syntax.

```
roles/nginx/
├── tasks/main.yml          # what to do
├── handlers/main.yml       # what to notify
├── templates/nginx.conf.j2 # files with variables in them
├── files/                  # files copied verbatim
├── vars/main.yml           # variables that should not be overridden
├── defaults/main.yml       # variables that should be
└── meta/main.yml           # dependencies on other roles
```

Using it collapses the playbook to almost nothing:

```yaml
- hosts: web
  roles:
    - nginx
    - { role: monitoring, monitoring_port: 9100 }
```

**`defaults/` against `vars/` is the distinction people get wrong**, and it is
about precedence rather than about meaning. `defaults/main.yml` is the lowest
priority of anything in Ansible. It is a suggestion, overridable by inventory,
by the play, by the command line. `vars/main.yml` is very high priority and
hard to override. So anything a user of your role might reasonably want to
change belongs in `defaults`, and putting it in `vars` is how you write a role
nobody can adapt.

**`ansible-galaxy` is the distribution mechanism**, and both a blessing and a risk:

```
ansible-galaxy role install geerlingguy.nginx
ansible-galaxy collection install community.general
```

A community role saves a day and is code you did not review running as root on
every server. Pin the version, read the tasks, and treat it exactly as you
would treat adding a third-party repository from lesson 31, because the trust
decision is the same one.

**Collections are the modern packaging**, and roles now usually live inside them.
`community.general.timezone` is a module inside the `community.general` collection;
`ansible.builtin` is the set that ships with the engine. Writing the fully qualified
name rather than the short one is worth the extra characters, because it makes it
obvious which of the thousands of modules you actually got.

**The organising principle for a real estate** is one role per service, plus
`group_vars/` for the per-environment differences. Production and staging then run
identical roles with different variables, which is the only arrangement where
staging genuinely tests anything.

</details>

## Facts

Before running tasks, Ansible interrogates each host and makes what it finds
available as variables.

```bash
# Debian 13 (trixie), x86_64
$ cd /root/play; ansible all -i inventory -m ansible.builtin.setup -a "filter=ansible_distribution*" 2>/dev/null | head -12
localhost | SUCCESS => {
    "ansible_facts": {
        "ansible_distribution": "Debian",
        "ansible_distribution_file_parsed": true,
        "ansible_distribution_file_path": "/etc/os-release",
        "ansible_distribution_file_variety": "Debian",
        "ansible_distribution_major_version": "13",
        "ansible_distribution_minor_version": "6",
        "ansible_distribution_release": "trixie",
        "ansible_distribution_version": "13.6",
        "discovered_interpreter_python": "/usr/bin/python3.13"
    },
```

**That is a filtered fraction of what is collected**. The full set runs to
hundreds of values covering interfaces, addresses, mounts, memory, CPU,
virtualisation, and the service manager.

Facts are how one playbook handles a mixed estate, which is the cross-family
problem this whole track keeps meeting:

```yaml
- name: Install the web server
  ansible.builtin.package:
    name: "{{ 'httpd' if ansible_os_family == 'RedHat' else 'apache2' }}"
    state: present
```

`ansible_os_family` is the fact to reach for, because it groups Debian with
Ubuntu and RHEL with AlmaLinux and Rocky, which is nearly always the
distinction that matters, rather than the specific distribution.

Fact gathering costs a round trip per host, so `gather_facts: false` is a real
optimisation on a large estate when the play does not need them.

<details class="deeper">
<summary>If you already administer Linux: templates, and why they beat editing files in place</summary>

The `copy` module puts a fixed file somewhere. The `template` module renders a
Jinja2 file first, and that difference is what lets one description serve an entire
estate.

```jinja
# {{ ansible_managed }}
worker_processes {{ ansible_processor_vcpus }};

events {
    worker_connections {{ nginx_worker_connections | default(1024) }};
}

http {
{% for site in nginx_sites %}
    server {
        listen {{ site.port }};
        server_name {{ site.name }};
    }
{% endfor %}
}
```

**`worker_processes` is set from a fact**, so every machine gets a value matching its
own CPU count without anybody maintaining a list.

`| default(1024)` is a filter, and the pattern to use for anything a role
exposes. It works with no configuration and can be overridden.

`{{ ansible_managed }}` expands to a warning comment naming the source file
and the template. It costs one line and it is the thing that stops somebody
editing the file by hand at 3am without realising it will be overwritten.

Why this beats `lineinfile` and `sed`-style editing, which is the real point:

A template does not care what the file contained before. Editing in place has
to find something to edit, so it breaks when the file is a slightly different
version, when a previous run already changed it, or when two tasks edit the
same line. A template writes the whole file, so the result depends only on the
variables, which is what makes it idempotent for free.

The diff is meaningful. `--check --diff` on a templated file shows exactly
what would change, because Ansible renders it and compares. On a `lineinfile`
task the diff is a single line with no context.

Three things worth knowing about the syntax:

`{{ }}` substitutes a value, `{% %}` is control flow, and `{# #}` is a comment that
does not appear in the output.

**Whitespace control**, `{%- for -%}`, strips the newline the tag would
otherwise leave. Without it, loops produce configuration files full of blank
lines, which is cosmetic until a format cares.

**`validate:` runs a syntax check before installing the file**, and it is the single
most valuable option on the module:

```yaml
- name: The nginx config is in place
  ansible.builtin.template:
    src: nginx.conf.j2
    dest: /etc/nginx/nginx.conf
    validate: nginx -t -c %s
  notify: Reload nginx
```

`%s` is the temporary path. If `nginx -t` fails, the real file is never
replaced, so a template with a typo produces a failed task rather than a web
server that will not start. `visudo -cf %s` and `sshd -t -f %s` do the same
job for the two files where getting it wrong locks you out.

</details>

## Across distributions

Ansible runs *from* one machine and *against* many, so there are two questions.

| | RHEL family | Debian family |
| --- | --- | --- |
| Control node package | `ansible-core`, or `ansible` for the full collection set | The same |
| Managed node needs | Python 3, SSH | The same |
| Web server package | `httpd` | `apache2` |
| `ansible_os_family` | `RedHat` | `Debian` |
| Escalation | `sudo`, `wheel` group | `sudo`, `sudo` group |

**`ansible-core` against `ansible` is worth understanding.** `ansible-core` is the
engine plus the `ansible.builtin` modules; the `ansible` package adds several
thousand community modules bundled as collections. Start with `ansible-core` and add
collections deliberately with `ansible-galaxy collection install`, because bundling
everything makes it very hard to know what version of anything you are running.

## Prove it

```
# Can I reach everything at all
ansible all -i inventory -m ansible.builtin.ping

# What would change, without changing it
ansible-playbook -i inventory site.yml --check --diff

# Is the playbook syntactically valid
ansible-playbook -i inventory site.yml --syntax-check

# Is it idiomatic and idempotent-looking
ansible-lint site.yml

# The real test: run it twice
ansible-playbook -i inventory site.yml
ansible-playbook -i inventory site.yml    # changed must be 0

# What does Ansible think this host is
ansible host -i inventory -m ansible.builtin.setup | less
```

**The two-run test is the one that matters** and it is the one people skip. A
playbook that reports `changed` on the second run is not doing what its author
thinks, and no amount of linting will tell you.

## What trips people up

### 1. `changed` on every run

Almost always a `command` or `shell` module where a real module exists. Those cannot
know whether they need to run.

Use the proper module, or give `command` a `creates:` or `removes:` so it can check.

The cost is not cosmetic: handlers fire on `changed`, so the service restarts every
run forever.

### 2. Forgetting `--become`

Ansible connects as an ordinary user. Anything privileged needs `--become` on the
command line or `become: true` in the play.

### 3. Expecting it to run on its own

Ansible is push-based. Nothing happens unless somebody runs it, so a machine that
was off during the run stays unconfigured.

### 4. A typo in `notify`

Handlers are matched by name. A misspelled `notify` silently notifies nothing, and
the service is never reloaded.

### 5. Trusting check mode on `command` tasks

Check mode is a simulation. `command` cannot be simulated, so it is skipped, and
anything depending on its result reports misleadingly.

### 6. Secrets in the playbook

`ansible-vault encrypt` for values in the repository, or a secrets manager. A
password in a task is a password in Git, with everything lesson 55 said about that.

## Work it through

A playbook that configures fifty web servers has started reporting
`changed=2` on every single run, on every host, forever. Nothing is broken. Nginx
restarts every thirty minutes because the pipeline runs the playbook on a schedule
and a handler is notified each time.

Reason it out before reading on.

**Find which two tasks**, which the output already tells you, the tasks
reporting `changed` are named in the run. Say they are:

```yaml
- name: Set the timezone
  ansible.builtin.command: timedatectl set-timezone Europe/London
  notify: Reload nginx

- name: Generate the config
  ansible.builtin.shell: cat /etc/app/*.fragment > /etc/nginx/conf.d/app.conf
  notify: Reload nginx
```

Both are `command` or `shell`, and that is the diagnosis. Neither module can
know whether the work is already done, so both report `changed`
unconditionally.

The first has a proper module:

```yaml
- name: The timezone is Europe/London
  community.general.timezone:
    name: Europe/London
```

Which checks the current timezone and does nothing if it matches.

**The second is more interesting**, because concatenating fragments has no module.
Two honest options:

```yaml
- name: The app config is assembled
  ansible.builtin.assemble:
    src: /etc/app/fragments
    dest: /etc/nginx/conf.d/app.conf
```

`assemble` exists for precisely this and compares the result before writing. Or, if
the shell really is necessary, make it checkable:

```yaml
- name: The app config is assembled
  ansible.builtin.shell: cat /etc/app/*.fragment > /tmp/app.conf.new
  changed_when: false

- name: The app config is in place
  ansible.builtin.copy:
    src: /tmp/app.conf.new
    remote_src: true
    dest: /etc/nginx/conf.d/app.conf
  notify: Reload nginx
```

**Splitting "produce it" from "install it"** lets the shell run every time reporting
no change, and lets `copy` decide whether anything is actually different. Only the
second notifies.

**`changed_when: false` is the blunt instrument** and worth naming as such. It
tells Ansible a task never changes anything, which is right for a genuinely
read-only command and a lie for anything else, and a lie that will hide a real
change later.

The point worth extracting: **the changed count is not reporting, it is the
mechanism.** Handlers, `--check`, and the whole idea of re-running safely all
rest on modules reporting honestly. A task that always says `changed` breaks
all three at once, and the visible symptom, a service restarting on a timer,
is several steps away from the cause.

## Try it

Optional. Everything here works against `localhost` with no remote machines.

1. `pip install --user ansible-core`, or install it from your package manager.
2. Create an inventory containing `localhost ansible_connection=local`.
3. `ansible all -i inventory -m ansible.builtin.ping`.
4. Write the three-task playbook from this lesson and run it. Note `changed=3`.
5. Run it again. Note `changed=0`.
6. Edit one of the managed files by hand, then run with `--check --diff`.
7. Confirm the file was not repaired, then run without `--check`.
8. Add a task using `ansible.builtin.command: date` and run twice. Watch it report
   `changed` both times.
9. `ansible all -i inventory -m ansible.builtin.setup | less` and look for three
   facts you could use.

**Verification step.** You have it when a second run of your playbook reports
`changed=0` and you can explain every task that does not.

## Check yourself

<details class="qa">
<summary>What does "agentless" mean in practice, what does a managed machine actually need, and what is the trade-off?</summary>

**Ansible installs nothing on the machines it manages.** It connects over SSH,
copies a small Python program, runs it, collects JSON, and deletes it.

A managed host needs three things: SSH access, Python 3, and an account that
can escalate for privileged tasks. No agent, no daemon, no listening port, no
certificate.

Which means onboarding is immediate, a machine you were given access to five
minutes ago is manageable now, and offboarding is deleting a line from a file
rather than uninstalling software.

Three trade-offs, and they are real:

**Push, not pull.** Nothing happens unless somebody runs it. A machine that was
powered off during the run stays unconfigured, where a Puppet agent would catch up
on its own next cycle.

Scaling is by forking connections from the control node, five at a time by
default. Puppet's agents work independently, so its server load grows far more
slowly with fleet size.

**Latency multiplies.** Each task is a round trip per host, so forty tasks against a
distant machine pay the round trip forty times. `pipelining` and SSH
`ControlPersist` exist to reduce it.

`ansible-pull` inverts the model, each machine fetches the repository and
applies it locally, which recovers continuous convergence at the cost of the
simplicity that made agentless attractive.

</details>

<details class="qa">
<summary>A playbook reports <code>changed</code> on every run. Why is that a bug rather than cosmetic, and what usually causes it?</summary>

**Because `changed` is a mechanism, not a report.** Handlers fire on it, so a
task that always claims to have changed something restarts the service on
every run, forever, and on a scheduled pipeline that means a restart every
thirty minutes that nobody connects to the playbook.

It also destroys the signal. `changed=0` on a second run is how you know the
automation is safe to re-run; a playbook that never reaches zero cannot tell you
whether anything real happened.

**The usual cause is `command` or `shell` where a proper module exists.**
Those modules run something and have no way to know whether it needed running,
so they report changed unconditionally. `ansible.builtin.command: useradd
deploy` will say changed every time, and fail every time after the first.

Three fixes, best first:

Use the real module. `user:`, `package:`, `service:`, `timezone:`, `assemble:`
all check current state before acting.

Give `command` a guard. `creates: /path/that/appears` or `removes:
/path/that/goes` lets it skip when the work is already done.

**`changed_when:`** to define what counts as a change, for example
`changed_when: result.stdout != ''`. `changed_when: false` is the blunt
version and is honest only for genuinely read-only commands.

</details>

<details class="qa">
<summary>What do <code>--check</code> and <code>--diff</code> do together, and where is check mode misleading?</summary>

`--check` runs the playbook without making any changes, and `--diff` shows the
content difference for anything that would change. Together they answer "how
far has this estate drifted from its description" without touching anything,
which makes them safe against production at any time.

The output is a unified diff, the same format as `git diff`:

```
--- before: /srv/site/index.html
+++ after: /srv/site/index.html
@@ -1 +1 @@
-somebody edited it by hand
+running on Debian 13.6
```

**Where it misleads is anything that cannot be simulated.**

`command` and `shell` cannot be run in check mode, Ansible has no way to know
what an arbitrary command would do, so they are skipped by default. That means
a playbook whose real work happens in `command` tasks reports almost nothing
in check mode and looks reassuring.

**And dependent tasks report wrongly.** If task 3 only changes something because
task 1 changed something, then in check mode task 1 did not actually change
anything, so task 3's prediction is based on a state that does not exist. Long
chains of dependent tasks give unreliable check output.

So check mode is excellent for configuration files and templates, which is
most of what it is used for, and should be read sceptically for procedural
playbooks. `check_mode: false` on a specific read-only task lets it run for
real so later tasks can depend on its result.

</details>

<details class="qa">
<summary>What is a handler, and name two things about when it runs that are not obvious.</summary>

A handler is a task that runs only when notified, and only once per play no
matter how many tasks notified it. It is how nine configuration file changes
produce one service reload rather than nine.

`notify` fires only when the notifying task reports `changed`, which is why the
changed count has to be honest for any of this to work.

**Two non-obvious things:**

Handlers run at the end of the play, not at the point of notification. So a
later task cannot assume the handler has already run. If a subsequent task
needs to talk to the restarted service, `meta: flush_handlers` forces them to
run at that point.

Handlers do not run if the play fails first. A failure partway through leaves
the configuration files changed and the service never reloaded, a genuinely
awkward state, because the machine now has new config and old behaviour.
`--force-handlers` runs them regardless.

A third worth knowing: handlers are matched by name, so a typo in `notify`
silently notifies nothing. Recent Ansible warns; older versions did not, and
the symptom is a service that quietly never picks up its new configuration.

And `state: reloaded` against `restarted` is the same distinction as in the
systemd lesson, reload re-reads configuration without dropping connections.
The module will not tell you whether the service actually supports reload; it
will just restart.

</details>

<details class="qa">
<summary>What are facts, what do they cost, and which one should you usually branch on?</summary>

**Facts are what Ansible discovers about each host before running tasks**
(distribution, version, interfaces, addresses, memory, CPU, mounts,
virtualisation, service manager) exposed as variables like
`ansible_distribution` and `ansible_default_ipv4.address`.

They are what lets one playbook serve a mixed estate:

```yaml
name: "{{ 'httpd' if ansible_os_family == 'RedHat' else 'apache2' }}"
```

**Branch on `ansible_os_family`, not `ansible_distribution`.** The family
groups Debian with Ubuntu and RHEL with AlmaLinux, Rocky, and CentOS Stream,
which is almost always the distinction that actually matters, since it is the
one that decides package names, service names, and file locations. Branching
on the specific distribution means adding a case every time somebody uses a
new rebuild.

The cost is a round trip per host, which is why `gather_facts: false` is a
real optimisation on a large estate for plays that do not need them. Fact
caching in `ansible.cfg` is the other answer when they are needed but not
fresh.

`ansible -m setup` prints them all, and `-a "filter=ansible_distribution*"`
narrows it, which is the fastest way to find the exact name of a fact you half
remember.

Custom facts are possible too, a file in `/etc/ansible/facts.d/` on the
managed host appears under `ansible_local`, which is how you expose something
site-specific that no module knows about.

</details>

## References

- [Ansible documentation](https://docs.ansible.com/ansible/latest/index.html) - Red Hat. Accessed 2026-08-08.
- [How to build your inventory](https://docs.ansible.com/ansible/latest/inventory_guide/intro_inventory.html) - Red Hat. Accessed 2026-08-08.
- [Ansible playbooks](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_intro.html) - Red Hat. Accessed 2026-08-08.
- [Validating tasks: check mode and diff mode](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_checkmode.html) - Red Hat. Accessed 2026-08-08.
- [Ansible vault](https://docs.ansible.com/ansible/latest/vault_guide/index.html) - Red Hat. Accessed 2026-08-08.
- [Roles](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_reuse_roles.html) - Red Hat. Accessed 2026-08-08.

Every block above with a distribution and architecture header was captured by
running the command on a Debian 13 (trixie) container managing itself over a local
connection, so the playbook runs, the changed counts, and the drift diff are all
real rather than illustrative. Blocks without a header are illustrative.
