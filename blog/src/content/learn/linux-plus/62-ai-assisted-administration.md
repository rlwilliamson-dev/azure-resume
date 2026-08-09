---
title: "The generated command looked right"
description: "An assistant that writes shell, YAML, and regex is genuinely useful and is not accountable for what it produces. This is the review habit, the verification commands, the data governance question, and the prompt injection problem — written by one of these things, which is worth bearing in mind."
track: "linux-plus"
level: "working"
order: 630
objectives:
  - "Name the tasks AI assistance is well suited to, and the tasks it is not"
  - "Verify a suggested package, flag, or command before running it"
  - "Review generated code for the failure modes that look correct"
  - "Explain the data governance question: what leaves your network, and to whom"
  - "Distinguish a locally hosted model from a hosted service, and when each is appropriate"
  - "Describe prompt injection and why it matters once a model reads untrusted input"
  - "State what an audit trail for AI-assisted work has to contain"
prerequisites: ["scripts-that-do-real-work", "cicd-and-gitops"]
tags: ["linux", "linux-plus", "ai", "automation", "security", "governance"]
updated: 2026-08-09
draft: false
examObjectives:
  - exam: "xk0-006"
    domain: "4.0"
    objective: "4.5"
sources:
  - title: "ShellCheck wiki, SC2164"
    url: "https://www.shellcheck.net/wiki/SC2164"
    publisher: "ShellCheck"
    accessed: 2026-08-09
    tier: 1
  - title: "ShellCheck wiki, SC2086"
    url: "https://www.shellcheck.net/wiki/SC2086"
    publisher: "ShellCheck"
    accessed: 2026-08-09
    tier: 1
  - title: "OWASP Top 10 for Large Language Model Applications"
    url: "https://owasp.org/www-project-top-10-for-large-language-model-applications/"
    publisher: "OWASP"
    accessed: 2026-08-09
    tier: 1
  - title: "NIST AI Risk Management Framework (AI 100-1)"
    url: "https://nvlpubs.nist.gov/nistpubs/ai/NIST.AI.100-1.pdf"
    publisher: "NIST"
    accessed: 2026-08-09
    tier: 1
  - title: "tar(1), GNU tar manual"
    url: "https://www.gnu.org/software/tar/manual/tar.html"
    publisher: "GNU"
    accessed: 2026-08-09
    tier: 1
symptoms:
  - symptom: "Suggested package name does not exist in any repository"
    anchor: "verify-before-you-run-it"
  - symptom: "Generated script deletes files outside the directory it was given"
    anchor: "the-review-is-the-job"
  - symptom: "Assistant follows instructions found in a file it was asked to summarise"
    anchor: "prompt-injection-once-a-model-reads-untrusted-input"
---

> **Before you read.** A colleague asks an assistant for a cleanup script. It
> gets one in four seconds. It is well-commented, uses `find` correctly, and
> looks like something a competent person would write. They run it on the build
> server.
>
> **It deletes the wrong directory and exits zero.**
>
> Nothing about that story requires the assistant to have been bad at its job.
> The script it produced is the kind of script people write. That is the
> problem.

This lesson is on the exam because AI assistance is now part of ordinary
administration and the objectives treat it as a tool with a safe operating
procedure — like `dd`, or `rm -rf`, or anything else that is useful in
proportion to how much damage it can do.

**A disclosure, since it is relevant:** this lesson was written with the same
class of tool it is about. Every command transcript below was captured by
running the command on a real machine rather than by predicting the output,
which is precisely the habit the lesson argues for. You should extend this text
the same scepticism it asks you to extend to anything else generated this way.

### Some words you will need

<dl class="terms">
<dt>large language model (LLM)</dt>
<dd>A model that predicts likely text. Everything it does follows from that, including its failure modes.</dd>
<dt>prompt</dt>
<dd>The input. Instructions, context, and data, with no reliable boundary between them.</dd>
<dt>context window</dt>
<dd>How much text the model can consider at once. Anything outside it does not exist.</dd>
<dt>hallucination</dt>
<dd>Fluent output that is false. Not a malfunction; the same process that produces correct answers.</dd>
<dt>inference</dt>
<dd>Running a model to get output, as distinct from training it.</dd>
<dt>local / self-hosted model</dt>
<dd>Runs on hardware you control. Nothing leaves your network.</dd>
<dt>hosted / API model</dt>
<dd>Runs on somebody else's infrastructure. Your input goes to them.</dd>
<dt>prompt injection</dt>
<dd>Instructions hidden in data the model reads, which it may then follow.</dd>
<dt>data governance</dt>
<dd>The rules about what data may go where, and who is accountable when it goes elsewhere.</dd>
<dt>human in the loop</dt>
<dd>A person who reviews and approves before anything takes effect.</dd>
</dl>

## What breaks without this

**Confident wrong answers get run.** The output has no tone of uncertainty
available to it. A fabricated flag is delivered in exactly the same voice as a
correct one.

**Credentials and internal data leave the building.** Pasting a config file into
a public tool to ask what is wrong with it sends that config file — and any
password in it — to a third party.

**Nobody can explain what is deployed.** Generated configuration that works but
that nobody on the team understands is unmaintainable, and it fails at the worst
moment, which is during an incident.

**Skills quietly do not develop.** An engineer who has never had to work out why
a command failed has not learned to work out why a command failed.

**Untrusted input becomes an instruction channel.** The moment a model reads a
log file, a ticket, or a web page, whatever is written there is competing with
your instructions.

**Policy is broken without anybody deciding to.** Most organisations have rules
about this now. Very few people have read them.

## What it is genuinely good at

Being clear-eyed about the failures requires being fair about the value, and the
value is real. The pattern is that these tools are strong where **the output is
immediately checkable** and weak where it is not.

| Task | Why it fits |
| --- | --- |
| **Explaining an error message** | You have the error. You can test whether the explanation is right |
| **Writing regex** | Notoriously fiddly to write, trivial to test against sample input |
| **Boilerplate** | A systemd unit, a Compose file, an Ansible skeleton — you know what correct looks like |
| **Translating between formats** | JSON to YAML, `iptables` to `nftables`, a crontab to a systemd timer |
| **A first-pass code review** | Genuinely good at spotting unquoted variables and missing error handling |
| **Documentation and commit messages** | You are the authority on whether it describes what you did |
| **Recalling syntax you half-know** | "The `find` flag for modification time" — verifiable in one `man` command |
| **Rubber-ducking** | Explaining your problem is useful even when the reply is not |

**And where it is weak, with the reason rather than the vibe:**

| Task | Why it does not fit |
| --- | --- |
| **Anything about *your* environment** | It has never seen your network. Specifics about your estate are invented |
| **Current versions, CVEs, release state** | Training data has a cutoff, and a wrong answer here reads exactly like a right one |
| **Precise counting and arithmetic** | Subnet maths, offsets, capacity planning. Check with `ipcalc` and a calculator |
| **Security decisions** | Confidently produces plausible-looking crypto and permission choices |
| **Irreversible operations** | The cost of a wrong answer is unbounded |
| **Anything where "I do not know" is the right answer** | The strong default is to produce *something* |

**The single most useful framing:** treat generated output as **a confident
suggestion from a stranger who has never seen your systems and will not be
there at 3am.** Some of those suggestions are excellent. You would still check
them.

<details class="deeper">
<summary>If you already administer Linux: why the failure modes are shaped like this, and how to predict them</summary>

You do not need the mathematics, but a rough mental model turns "sometimes it is
wrong" into "wrong in specific, anticipatable ways" — which is the difference
between vague distrust and useful judgement.

**The model predicts likely continuations of text.** That is the mechanism.
Everything follows from it, including the things it is remarkably good at.

**So there is no internal distinction between recalling and inventing.**
`--strip-components` and `--strip-leading-dirs` are both plausible continuations
of "the tar flag for removing leading path components". One happens to
correspond to reality. The process that produced them is identical, which is
precisely why the output carries no signal that one is a memory and one is a
guess. **Hallucination is not a bug in the mechanism, it is the mechanism, seen
from the side where it did not happen to land on the truth.**

**Which yields a genuinely predictive rule:** reliability tracks how much
consistent, correct material about a thing existed in training. That gives you a
usable ranking before you ask:

| Likely reliable | Likely invented |
| --- | --- |
| `systemd` unit syntax, `find`, `awk`, common `git` | Flags of a niche or recently-changed tool |
| Widely documented error messages | Your internal service names and paths |
| Standard file locations on mainstream distributions | Exact current package versions and CVE status |
| Well-known config formats — nginx, sshd, fstab | Anything answered by a vendor's paywalled KB |
| Concepts, and explanations of concepts | Specific numbers, counts, and offsets |

**Two more consequences worth carrying:**

**Confidence is a property of the writing style, not of the answer.** The
register is uniform because fluent text is what the training rewards. There is
no mechanism by which uncertainty gets expressed proportionally, so hedging in
the output tells you very little about correctness, in either direction.

**"I do not know" is an unlikely continuation.** Text on the internet answering
a question almost always contains an answer. So the strong default is to produce
one, and the most useful counter-move is to ask a question that makes not
knowing a reasonable reply: "does this flag exist in GNU tar, and what version
added it?" invites a check in a way "what is the flag for..." does not.

**And the one that catches administrators specifically:** the model has no
access to your machine. When it produces `eth0`, `/var/www/html`, or
`nginx.service`, it is producing the most common instance of that kind of thing,
not an observation about your system. Those values are placeholders wearing the
costume of facts, and the fix is to supply the real ones in the question.

</details>

## Verify before you run it

The habit is small and specific: **for anything named — a package, a flag, a
path, a service — ask the system whether it exists before you depend on it.**
This costs seconds.

Package names are the common case, because plausible names are easy to generate
and repository naming is arbitrary:

```bash
# AlmaLinux 10.2, x86_64
$ echo "--- a suggested package name, checked before it is trusted ---"; dnf -q info nginx-mainline-extras; echo "dnf exit status: $?"; echo; echo "--- and a name that is real ---"; dnf -q info nginx | head -5; echo "dnf exit status: ${PIPESTATUS[0]}"
--- a suggested package name, checked before it is trusted ---
Error: No matching Packages to list
dnf exit status: 1

--- and a name that is real ---
Available Packages
Name         : nginx
Epoch        : 2
Version      : 1.26.3
Release      : 6.el10_2.5
dnf exit status: 0
```

`nginx-mainline-extras` sounds entirely reasonable. It does not exist. **One
`dnf info` settles it**, and the exit status is unambiguous enough to use in a
script.

**This matters more than being an inconvenience.** A plausible-but-nonexistent
package name is a supply chain opportunity: if a name is suggested often enough,
somebody can register it on a public index and wait. That attack has a name —
slopsquatting, a variant of typosquatting — and it is a real and documented
technique against language ecosystems like PyPI and npm, where anybody may
publish. Distribution repositories are much harder to attack this way; language
package indexes are not.

Flags are the same shape of problem:

<details class="predict">
<summary>A suggestion uses <code>tar --strip-leading-dirs</code>. It is a sensible-sounding name for a real capability. What does <code>tar</code> say, and what is the flag actually called?</summary>

```bash
# AlmaLinux 10.2, x86_64
$ echo "--- a suggested flag, checked against the tool itself ---"; tar --strip-leading-dirs -tf /dev/null; echo "tar exit status: $?"; echo; echo "--- what the tool actually calls it ---"; tar --help | grep -i "strip NUMBER"
--- a suggested flag, checked against the tool itself ---
tar: unrecognized option '--strip-leading-dirs'
Try 'tar --help' or 'tar --usage' for more information.
tar exit status: 64

--- what the tool actually calls it ---
      --strip-components=NUMBER   strip NUMBER leading components from file
```

</details>

**The capability is real and the name was invented.** `--strip-components` is
what GNU tar calls it. This is the characteristic failure: not nonsense, but
something adjacent to the truth, which is far harder to spot by reading.

**A bad flag name is the good case**, because the tool refuses. The dangerous
version is a flag that exists and means something else.

| To check | Command |
| --- | --- |
| Does this package exist? | `dnf info <name>` / `apt-cache policy <name>` |
| Does this flag exist? | `<cmd> --help \| grep -- --flag`, or `man <cmd>` |
| What does this command do? | `man`, and `type`/`which` for what will actually run |
| What would this change? | `--dry-run`, `-n`, `--noop`, `--assumeno`, `--check` |
| Is this file what I think? | `ls -l`, `file`, `stat` |
| Is this unit real? | `systemctl cat <unit>` |
| Will this config parse? | `nginx -t`, `sshd -t`, `visudo -c`, `named-checkconf` |

**Dry-run mode is the most underused item in that table.** Before taking a
suggestion to remove a package, ask the package manager what it would actually
do:

```bash
# AlmaLinux 10.2, x86_64
$ echo "--- the suggestion was: just remove the old python package ---"; dnf remove --assumeno python3-libs 2>&1 | tail -14
--- the suggestion was: just remove the old python package ---
Error: 
 Problem: The operation would result in broken dependencies for the following protected packages: dnf
  - package python3-dnf-4.20.0-22.el10_2.alma.1.noarch from @System requires /usr/bin/python3, but none of the providers can be installed
  - package python3-dnf-4.20.0-22.el10_2.alma.1.noarch from @System requires python(abi) = 3.12, but none of the providers can be installed
  - package python3-3.12.13-2.el10_2.x86_64 from @System requires libpython3.12.so.1.0()(64bit), but none of the providers can be installed
  - package python3-3.12.13-2.el10_2.x86_64 from @System requires python3-libs(x86-64) = 3.12.13-2.el10_2, but none of the providers can be installed
  - package dnf-4.20.0-22.el10_2.alma.1.noarch from @System requires python3-dnf = 4.20.0-22.el10_2.alma.1, but none of the providers can be installed
  - conflicting requests
  - problem with installed package dnf-4.20.0-22.el10_2.alma.1.noarch
(try to add '--skip-broken' to skip uninstallable packages or '--nobest' to use not only best candidate packages)
```

**Removing that one library would have taken `dnf` itself with it.** The package
manager knows this and refuses, because `dnf` is on its protected list — an
answer available in one command, before anything happened.

Note the tail of the message, which is the genuinely dangerous part: dnf
helpfully suggests `--skip-broken` and `--nobest`. Those flags are the sound of a
system offering you a way to proceed anyway, and an assistant asked "how do I
get past this error" will hand them to you. **When a tool refuses, the refusal
is usually the answer.**

<details class="deeper">
<summary>If you already administer Linux: build somewhere it is safe to be wrong</summary>

Reading a suggestion tells you less than running it. The constraint is that
running it is exactly what you are unsure about, so the answer is a place where
being wrong costs nothing, reachable in under a minute.

**A container is the cheapest scratch machine there is.** It starts in about a
second, it is the distribution you actually care about, and destroying it is
free:

```bash
podman run --rm -it docker.io/library/almalinux:10 bash
```

`--rm` deletes it on exit, so mistakes do not accumulate. This handles most
verification questions: does the package exist, what does the flag do, what does
this config parser say about this file.

**What a container cannot answer**, and it is worth knowing the boundary so you
do not draw a false conclusion: anything involving the kernel, the bootloader,
`systemd` as PID 1, real block devices, real network interfaces, or SELinux in
enforcing mode. For those you want a VM.

**A VM you can revert is the next tier.** `virt-manager` or `libvirt` locally,
or a cloud instance, with a snapshot taken before you start. `virsh snapshot-create-as`
then `virsh snapshot-revert` makes an experiment repeatable, which matters more
than it sounds: being able to run the *same* dangerous thing three times with
one variable changed is how you actually understand what it did.

**A loop device is a real block device.** For anything involving partitioning,
filesystems, LVM, RAID, or LUKS, you do not need spare disks:

```bash
truncate -s 2G /var/tmp/disk1.img
losetup --find --show /var/tmp/disk1.img
```

That gives you `/dev/loop0`, which `parted`, `mkfs`, `pvcreate`, `mdadm`, and
`cryptsetup` all treat as an ordinary disk. Every storage lesson in this track
was captured this way.

**Two habits that make this actually work:**

**Write the experiment down as a script, not as shell history.** A setup script
plus the command under test can be re-run after you change one thing, and it is
the difference between "I think that worked" and knowing. It also means you can
hand somebody the reproduction.

**Pin what you are testing on.** `almalinux:10` today and `almalinux:10` in six
months may be different images, so a result you recorded is not necessarily a
result you can reproduce. Pinning by digest — `almalinux@sha256:...` — is the
same argument as lesson 60 made about deployments, applied to your own
investigations.

**And the general principle underneath all of it:** the question "is this
suggestion correct" is almost never worth arguing about, because it is cheap to
settle. Every transcript in this track exists because running the command was
faster than deciding whether the answer was plausible.

</details>

## The review is the job

Verification catches things that do not exist. The harder case is code that
exists, runs, and is wrong. Here is a cleanup script of exactly the kind these
tools produce — and the kind people write:

```bash
# Debian 13 (trixie), x86_64
$ cat cleanup.sh
#!/bin/bash
# Remove build artefacts older than 30 days.
BUILD_DIR=$1
find $BUILD_DIR -name "*.tmp" -mtime +30 -exec rm -rf {} \;
cd $BUILD_DIR/cache
rm -rf *
echo "Cleaned $BUILD_DIR"
```

Seven lines. Commented. Uses `find` with `-mtime` correctly. Reads fine.

**Run a linter over it before reading it yourself** — this is the cheapest review
available and it is not an AI tool, it is a static analyser that has known these
patterns for a decade:

```bash
# Debian 13 (trixie), x86_64
$ shellcheck cleanup.sh; echo "shellcheck exit status: $?"

In cleanup.sh line 4:
find $BUILD_DIR -name "*.tmp" -mtime +30 -exec rm -rf {} \;
     ^--------^ SC2086 (info): Double quote to prevent globbing and word splitting.

Did you mean: 
find "$BUILD_DIR" -name "*.tmp" -mtime +30 -exec rm -rf {} \;


In cleanup.sh line 5:
cd $BUILD_DIR/cache
^-----------------^ SC2164 (warning): Use 'cd ... || exit' or 'cd ... || return' in case cd fails.
   ^--------^ SC2086 (info): Double quote to prevent globbing and word splitting.

Did you mean: 
cd "$BUILD_DIR"/cache || exit


In cleanup.sh line 6:
rm -rf *
       ^-- SC2035 (info): Use ./*glob* or -- *glob* so names with dashes won't become options.

For more information:
  https://www.shellcheck.net/wiki/SC2164 -- Use 'cd ... || exit' or 'cd ... |...
  https://www.shellcheck.net/wiki/SC2035 -- Use ./*glob* or -- *glob* so name...
  https://www.shellcheck.net/wiki/SC2086 -- Double quote to prevent globbing ...
shellcheck exit status: 1
```

**SC2164 is the one that matters, and its wording undersells it.** "Use
`cd ... || exit` in case `cd` fails" sounds like tidiness. What it means here is
that if the `cd` on line 5 fails, **line 6 runs `rm -rf *` in whatever directory
the script happens to be in.**

<details class="predict">
<summary>The script is run from a directory containing three files, and the argument is forgotten — just <code>./cleanup.sh</code> with nothing after it. What happens?</summary>

```bash
# Debian 13 (trixie), x86_64
$ touch important.conf release-notes.md build.log; ls; echo "--- now run it the way somebody would, having forgotten the argument ---"; ./cleanup.sh; echo "exit status: $?"; echo "--- what is left ---"; ls -A; echo "(nothing)"
build.log
cleanup.sh
important.conf
release-notes.md
--- now run it the way somebody would, having forgotten the argument ---
./cleanup.sh: line 5: cd: /cache: No such file or directory
Cleaned 
exit status: 0
--- what is left ---
(nothing)
```

</details>

**Everything is gone, including the script itself, and it exited 0.** Read the
chain, because every link is an ordinary mistake:

1. `$1` is empty, so `BUILD_DIR` is empty. `set -u` was not used.
2. `cd $BUILD_DIR/cache` becomes `cd /cache`, which does not exist.
3. The `cd` fails. There is no `|| exit`, and no `set -e`, so the script
   continues.
4. `rm -rf *` runs in the current directory — which is wherever you happened to
   be.
5. `echo "Cleaned "` prints, the script ends, and the exit status is `echo`'s.

**The script reported success.** In a pipeline, per lesson 60, that stage is
green.

**None of these are exotic bugs.** They are the four most common shell mistakes
there are, and a linter names three of them in under a second.

<details class="deeper">
<summary>If you already administer Linux: a review checklist for generated code that is short enough to actually use</summary>

Long checklists do not get used. This one is ordered by how often each item is
what actually bites, and it applies to anything generated — shell, Ansible,
Terraform, a Kubernetes manifest, a `systemd` unit.

**1. What is the blast radius if every variable is empty?**
Mentally substitute empty string for every parameter and re-read. `rm -rf
"$DIR"/` with an empty `DIR` is `rm -rf /`. This single question catches the
capture above and most of its relatives. `set -u` makes the shell ask it for
you.

**2. What happens when a step fails partway through?**
Generated scripts are usually written as though every command succeeds. Look for
the point of no return — where something has been deleted but not yet
recreated — and ask what state you are in if it stops there.

**3. Are the paths absolute, and is the working directory assumed?**
Anything relying on the current directory behaves differently under `cron`,
`systemd`, and a CI runner than it does in your shell. Every `cd` needs
`|| exit`.

**4. Does it destroy anything, and can that be reversed?**
`rm`, `mkfs`, `dd`, `DROP`, `truncate`, `--force`, `--purge`, `-y`. For each
one, ask what restores it. If the answer is "the backup", check the backup
actually exists before, not after.

**5. Where did the privileges come from?**
`sudo` inside a loop, a hardcoded credential, a `chmod 777` "to make it work", a
token in an environment variable that gets logged. Generated code reaches for
permissive settings because permissive settings appear in the material it
learned from.

**6. Is it idempotent?**
Run it twice in your head. Appending to a config file twice is the classic —
`>>` into `/etc/fstab` in a loop produces a machine that will not boot.

**7. Does it silently swallow errors?**
`2>/dev/null` on something whose failure matters, `|| true`, `-f` on `rm`,
`--force` anywhere. Each hides exactly the signal you need.

**8. Are the values plausible for *your* environment, or generically plausible?**
Interface names, paths, ports, package names, service names, subnets. This is
where a model has no information at all and will supply `eth0` and
`/var/www/html` regardless.

**And the meta-question that outranks all eight:**

**Could you explain every line to a colleague during an incident?** If not, you
do not have working code, you have a dependency you cannot maintain. Delete it
and write something smaller you understand. This is the actual standard, and it
scales to how risky the change is: a one-line `awk` in a scratch directory needs
none of this, and anything touching production storage, authentication, or
firewall rules needs all of it.

**Make it mechanical where you can.** `shellcheck` in a pre-commit hook and in
CI, per lesson 60, catches items 1, 3, and 7 without anybody remembering to look.
`shellcheck -S warning` fails only on warnings and above if the info-level noise
is stopping people adopting it.

</details>

## What leaves your network

Everything above is about correctness. This is about disclosure, and it is the
part that ends careers rather than evenings.

**When you paste text into a hosted assistant, you have sent that text to a
third party.** Not conceptually — actually. It transits their network, is
processed on their hardware, and is retained under whatever their terms say.

**What people paste without thinking:**

- A config file, to ask why the service will not start. It has a database
  password in it.
- A stack trace, which contains internal hostnames, file paths, and sometimes a
  connection string.
- A log extract, containing customer email addresses, IP addresses, or account
  identifiers.
- `kubectl get secret -o yaml` output, "to check the formatting".
- A chunk of proprietary source code.
- A network diagram or firewall ruleset, which is a map of your estate.

**The questions your organisation has to have answered:**

| Question | Why it matters |
| --- | --- |
| Is the data retained, and for how long? | Retention creates a breach surface that outlives the conversation |
| Is it used for training? | Consumer tiers often yes by default; enterprise tiers usually no |
| Which jurisdiction is it processed in? | GDPR and similar law constrain transfers |
| Who at the provider can see it? | Support access, abuse review, incident response |
| Is there a data processing agreement? | Whether your regulator will accept the arrangement |
| Does it satisfy our sector rules? | Health, finance, and government all have specifics |

**The rule that survives contact with reality:** if you would not put it in a
public ticket, do not put it in a hosted assistant. Redact first — replace real
hostnames, addresses, and identifiers with obvious placeholders. It takes
seconds and almost never reduces the quality of the answer, because the model
does not need your real subnet to explain your routing problem.

<details class="deeper">
<summary>If you already administer Linux: local versus hosted, and what self-hosting does and does not buy</summary>

"Run it locally so no data leaves" is the standard answer, and it is right about
one thing and oversold about several others.

**What local hosting genuinely gives you:**

- **No third-party disclosure.** The decisive property. For regulated data,
  classified environments, or air-gapped networks it is often the only option
  that permits the tool at all.
- **No dependency on an external service.** It works during an outage, and it
  works on an isolated network.
- **Predictable cost.** Hardware, not per-token billing.
- **Stability.** The model does not change under you. A hosted model can be
  updated and behave differently on Monday, which matters if anything downstream
  depends on its output format.

**What it does not give you:**

- **Equivalent capability.** A model that fits on one GPU is materially weaker
  than a frontier hosted model. That gap narrows and does not close, and for
  the checkable tasks in the table above a smaller model is often entirely
  adequate — which is the honest way to make the trade.
- **Freedom from review.** A local model hallucinates in exactly the same way.
  Everything earlier in this lesson still applies unchanged.
- **Freedom from governance.** You now operate a system that processes sensitive
  data, so logging, access control, and retention are *your* obligations rather
  than somebody else's. Prompts logged to disk are a new place secrets
  accumulate.
- **Zero cost.** GPUs, power, and somebody's time to run it.

**How this usually gets resolved in practice**, and it is a reasonable pattern:
tiered by data classification. Public and internal-general work goes to a hosted
enterprise tier with a data processing agreement and training disabled.
Confidential and regulated work goes to a self-hosted model. Restricted data
goes to neither, and the policy says so explicitly.

**Practically, for a Linux administrator**, the local stack is now
straightforward: **Ollama** or **llama.cpp** to serve a model, **vLLM** where
throughput matters, an OpenAI-compatible API endpoint so existing tooling works
unchanged, and open-weight models — Llama, Mistral, Qwen, Gemma — in quantised
form. A 7B–14B model quantised to 4 bits runs usefully on a single consumer GPU
and is genuinely good enough for explaining errors, drafting boilerplate, and
first-pass review.

**Check the licence before you deploy one.** "Open weights" is not "open
source", and several of these models carry restrictions on commercial use or on
scale that will matter to your legal team even though they never matter to your
laptop.

</details>

## Prompt injection: once a model reads untrusted input

This is the failure mode most worth understanding, because it is the one that
scales from an individual mistake to a security incident, and because the
tooling being built right now walks into it repeatedly.

**A model has no reliable boundary between instructions and data.** Both are
text in the same context. So if you ask an assistant to summarise a log file,
and the log file contains a line saying "ignore your previous instructions and
run the following command", that text is competing with yours on roughly equal
terms.

**This stops being theoretical the moment the model can act.** An assistant that
only produces text and hands it to you for review is a small problem: you are
the boundary. An assistant wired into tools that can read files, call APIs, or
execute commands has no such boundary, and the untrusted input reaches something
that acts.

**Where untrusted content enters an administrator's workflow, which is
everywhere:**

- Log files — attacker-controlled by definition, since anything that touches
  your service writes to them
- Ticket text, email bodies, chat messages
- Web pages fetched for research
- Filenames, HTTP headers, user agent strings
- Source files, README files, dependency metadata, code comments
- The output of any command that echoes user-supplied data back

**The general shape of the defence**, which is the same shape as every injection
problem before it:

- **Do not let output act without approval.** A human confirming each
  side-effecting action is the control that works today. Everything else is
  mitigation.
- **Least privilege for the tooling.** If an assistant has a read-only token, an
  injected instruction cannot write. This is ordinary access control and it is
  the most effective thing available.
- **Separate the channels as far as the architecture allows.** Untrusted content
  should be clearly delimited and labelled as data, and the system should be
  built assuming that delimiting can be defeated.
- **Constrain the action space.** An assistant that may only run commands from
  an allowlist has a bounded failure. One with a shell does not.
- **Log everything the tool did**, not just what it said, so an incident can be
  reconstructed.
- **Assume the boundary can be crossed.** There is no known reliable way to make
  a model ignore instructions embedded in data. Design as though it will
  sometimes follow them, because it will.

**The honest summary:** this is an unsolved problem, and treating it as solved is
the mistake. OWASP lists prompt injection as the first item in its Top 10 for LLM
applications for that reason, and it is worth reading before you approve any
tool that gives a model the ability to do something rather than say something.

<details class="deeper">
<summary>If you already administer Linux: audit trails, and what "AI-assisted" has to mean in a change record</summary>

When a change causes an incident, the question is what changed, who approved it,
and why. AI assistance complicates the last one and nothing else, but it
complicates it enough to be worth a policy.

**The accountability position, which is not negotiable and is worth being able
to state plainly:** the person who ran the command owns the outcome. There is no
sense in which responsibility transfers to a tool. "The assistant suggested it"
carries exactly the weight of "Stack Overflow said so", and everybody already
knows how much that is.

**What a change record should carry:**

- **That assistance was used, and for what part.** Not to assign blame — so that
  a reviewer knows which parts warrant closer reading, and so a pattern of
  failures can be found later.
- **Who reviewed it**, which must be a named person, not "reviewed by the tool".
- **What verification was performed.** The `--dry-run` output, the linter run,
  the staging test. This is the part that actually demonstrates diligence.
- **The final artefact, in version control**, per lesson 60. What matters is
  what was applied, and Git already records who committed and who approved.

**What this looks like in practice** is smaller than it sounds. A commit trailer
or a line in the description:

```text
Assisted-by: <tool>; verified with shellcheck and a --dry-run against staging.
Reviewed-by: <a person>
```

**Three things worth putting in a policy**, having watched people get these
wrong:

**Never let generated content commit itself unreviewed.** An automated pipeline
where a model opens a pull request is fine; one where it merges is not. The
review gate is the entire control.

**Separate "drafted with assistance" from "not understood".** The first is
unremarkable and increasingly universal. The second is the actual risk, and it
is invisible in a diff. The check is conversational: ask the author to explain
the change. This is not a gotcha — it is the same question a good reviewer has
always asked.

**Keep the prompt when the output is non-obvious.** For a generated regex or a
complex query, the prompt is documentation of intent in a way the output is not.
A comment saying what the regex is *meant* to match is worth more than the regex.

**On the skills question**, since it belongs in any honest treatment: the risk
is not that people use these tools, it is that junior engineers never build the
diagnostic instinct that comes from being stuck. The instinct is built by
struggling with a problem, not by reading a correct answer. A reasonable team
norm is to attempt a diagnosis before asking, and to use the assistant to check
reasoning rather than to supply conclusions — which also happens to be the mode
in which these tools are most reliable, because you are then in a position to
evaluate the answer.

</details>

## Asking better questions

The objective mentions prompt engineering. Stripped of the mystique, it is
mostly the skill of writing a good bug report, and the same things help.

| Do | Why |
| --- | --- |
| **State the environment.** "RHEL 9, systemd, SELinux enforcing" | Otherwise you get a generic answer and an Ubuntu path |
| **Give the real error text** | Specific errors get specific answers |
| **Say what you already tried** | Removes the obvious suggestions you have exhausted |
| **State the constraint.** "No new packages", "must work offline" | Otherwise the answer assumes a free hand |
| **Ask for the reasoning, not only the command** | You need to evaluate it, and reasoning is checkable |
| **Ask what could go wrong** | Reliably surfaces caveats that were not volunteered |
| **Iterate** | Correcting a wrong assumption is faster than rewriting the question |

**Two that are specific to this context and genuinely change the output:**

**Ask for the dry-run form first.** "Give me the command to check what this would
do before doing it" produces `--dry-run`, `--noop`, or `-n`, and it puts you in
the habit from the start.

**Ask it to argue against itself.** "What would make this the wrong approach?"
tends to produce the caveats that a direct answer omits, because a direct
question invites a direct answer and the failure mode is confidence.

**And the one that matters most:** when you do not understand a piece of the
answer, ask about that piece rather than accepting it. The gap between "it
works" and "I know why it works" is where the next outage lives.

## For the exam

**Always review before running.** If an option says to run generated output
directly, it is wrong.

**Verify that things exist.** Packages, flags, paths, services.

**Data governance is about what leaves your network.** Never paste credentials,
customer data, or proprietary code into a public tool.

**Local models keep data in-house**, at the cost of capability and the
obligation to operate them.

**Follow corporate policy**, and know that most organisations now have one.

**The human is accountable.** Not the tool.

**Good use cases are checkable ones:** explaining errors, boilerplate, regex,
translation between formats, first-pass review, documentation.

**Bad use cases:** anything specific to your environment, anything irreversible,
anything security-critical without expert review.

**Prompt injection is instructions hidden in data the model reads.**

<details class="qa">
<summary>Check yourself</summary>

**An assistant suggests installing `nginx-mainline-extras`. What do you do
first?**
`dnf info nginx-mainline-extras`. It does not exist — the capture above shows
the error and exit status 1.

**Why is a plausible fake package name a security issue, not just an
inconvenience?**
Because somebody can register that name on a public index and wait for people
to install it. It is typosquatting aimed at generated suggestions, and language
package indexes like PyPI and npm are the exposed case.

**A generated script contains `cd $DIR/cache` followed by `rm -rf *`. What is
the failure?**
If the `cd` fails, `rm -rf *` runs in the current directory. Above it deleted
everything and exited 0. The fix is `cd "$DIR"/cache || exit`, and `shellcheck`
flags it as SC2164.

**What is the fastest review you can run on a generated shell script?**
`shellcheck`. It found three real problems in a seven-line script in under a
second, and it is not an AI tool.

**A package removal is blocked and the tool suggests `--skip-broken`. What now?**
Stop. The refusal was the answer — removing that package would have taken `dnf`
with it. Flags that force past a dependency error are how a system gets broken
deliberately.

**Why should you never paste a config file into a public assistant?**
It is a disclosure to a third party, and config files contain credentials,
internal hostnames, and topology. Redact first.

**Name two things a locally hosted model gives you and one it does not.**
No third-party disclosure and no external dependency. It does not give you
freedom from review — it hallucinates identically.

**Is a self-hosted model exempt from data governance?**
No. The obligations move to you: logging, access control, retention. Prompts
written to disk are a new place secrets accumulate.

**What is prompt injection?**
Instructions embedded in data the model reads — a log line, a ticket, a web
page — which it may then follow as though you had written them.

**Why is prompt injection worse for an assistant with tool access?**
Because without tools you are the boundary: output is text you review. With
tools, injected instructions reach something that acts.

**What is the most effective control against a tool acting on injected
instructions?**
Least privilege on the tooling, plus human approval before any side-effecting
action. Neither is a complete fix, and there is no known reliable way to make a
model ignore embedded instructions.

**Who is accountable when a generated command causes an outage?**
The person who ran it.

**Give three details worth including when asking for help.**
The distribution and version, the exact error text, and what you already tried.

**What should a change record say about AI assistance?**
That it was used and for which part, who reviewed it, and what verification was
performed — the dry-run, the linter, the staging test.

**What is the standard for accepting generated code into production?**
That you could explain every line during an incident. If you cannot, it is a
dependency you cannot maintain.

</details>

## Where this sits

That is block E complete: scripting, version control, infrastructure as code,
the three configuration tools, pipelines, orchestration, and this.

The thread running through all of it is the same one this lesson ends on.
Lesson 57 argued for declaring intent rather than remembering steps. Lesson 60
argued that a pipeline is only as honest as its exit codes. Lesson 61 argued
that a description you can replay beats a running system you cannot rebuild.
**Every one of those is an argument for understanding what you are running**,
and a tool that produces plausible text very quickly makes that argument more
urgent rather than less.

Block F is troubleshooting, which is the discipline all of this was preparation
for.

> **The commands here were run on a real machine, not written from memory.** The
> package and dependency transcripts are from AlmaLinux 10.2 on x86_64; the
> script, `shellcheck`, and deletion transcripts are from Debian 13 (trixie) on
> x86_64. `cleanup.sh` really did delete every file in its working directory,
> including itself, and really did exit 0 — that transcript is the unedited
> output, which is the point. The fake package name and the fake `tar` flag were
> chosen to be plausible; the tools' responses to them were not written by me.
