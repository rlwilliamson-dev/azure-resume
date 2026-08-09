---
title: "The package you need is not in the default repository"
description: "Adding a software source means deciding to trust whoever runs it, for every package they will ever ship you. How signing actually works, how to add a repository properly, and how to ask which package a file came from."
track: "linux-plus"
level: "working"
order: 320
objectives:
  - "Explain what signing proves and what it does not"
  - "Add a third-party repository, including its key, on either family"
  - "Query the local package database for ownership and integrity"
  - "Pin or exclude a package, and say why that is a decision with a cost"
prerequisites: ["job-control-and-scheduling"]
tags: ["linux", "linux-plus", "packages", "repositories", "gpg"]
updated: 2026-08-07
draft: false
examObjectives:
  - exam: "xk0-006"
    domain: "2.0"
    objective: "2.4"
sources:
  - title: "rpm(8)"
    url: "https://man7.org/linux/man-pages/man8/rpm.8.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "dpkg(1)"
    url: "https://man7.org/linux/man-pages/man1/dpkg.1.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "sources.list(5)"
    url: "https://manpages.debian.org/stable/apt/sources.list.5.en.html"
    publisher: "Debian Project"
    accessed: 2026-08-07
    tier: 1
  - title: "apt-secure(8)"
    url: "https://manpages.debian.org/stable/apt/apt-secure.8.en.html"
    publisher: "Debian Project"
    accessed: 2026-08-07
    tier: 1
  - title: "dnf.conf(5)"
    url: "https://dnf5.readthedocs.io/en/latest/dnf5.conf.5.html"
    publisher: "DNF project"
    accessed: 2026-08-07
    tier: 1
  - title: "update-alternatives(1)"
    url: "https://manpages.debian.org/stable/dpkg/update-alternatives.1.en.html"
    publisher: "Debian Project"
    accessed: 2026-08-07
    tier: 1
symptoms:
  - symptom: "NO_PUBKEY or GPG check FAILED when installing"
    anchor: "1-gpg-check-failed"
  - symptom: "A package will not update and nobody knows why"
    anchor: "4-a-package-that-will-not-move"
---

> **Before you read.** Lesson 08 established that packages are signed and that the
> machine holds the key. That was a one-sentence answer to a question worth
> asking properly.
>
> A signature proves the package came from whoever holds the key and was not
> altered afterwards. It is the difference between trusting a network path and
> trusting a publisher.
>
> **So what does adding a third-party repository actually commit you to?**

Not one package. Every package that publisher will ever ship you, installed
automatically by `dnf upgrade` at 2am, running as root. That is a larger decision
than the two commands it takes suggest, and this lesson is mostly about making it
deliberately.

### Some words you will need

<dl class="terms">
<dt>repository</dt>
<dd>A server holding packages plus an index. The machine has a list of them.</dd>
<dt>GPG key</dt>
<dd>The publisher's public key. Used to verify signatures; holding it is the trust decision.</dd>
<dt>signature</dt>
<dd>Proof a package was produced by the key holder and has not changed since.</dd>
<dt>pin</dt>
<dd>A rule holding a package at a version, or preferring one repository over another.</dd>
<dt>alternatives</dt>
<dd>A mechanism letting several packages provide the same generic command.</dd>
</dl>

## What breaks without this

**You install unsigned software and do not notice.** Every family has a flag that
disables verification, and it appears in a great many internet instructions.

**A third-party repository quietly replaces system packages.** A badly-scoped repo
can supply a newer `glibc` or `systemd` than the distribution, and the machine
becomes unsupportable.

**You cannot answer "where did this file come from".** Which is the first question
in any incident involving an unexpected binary.

## What a signature proves

A package is downloaded and `rpm -K` is asked to check it. That command reports on
two independent things in one line.

<details class="predict">
<summary>An RPM carries checksums of its contents and a signature made by the vendor's key. Those answer two different questions. What are they, and which one would a corrupted download fail?</summary>

```bash
# AlmaLinux 10.2, x86_64
$ cd /tmp; dnf download tree -q >/dev/null 2>&1 || dnf install -y -q dnf-plugins-core >/dev/null 2>&1 && dnf download tree -q >/dev/null 2>&1; ls *.rpm 2>/dev/null && rpm -K tree*.rpm && echo '--- and the full signature line ---' && rpm -qpi tree*.rpm 2>/dev/null | grep -i signature
tree-2.1.0-8.el10.x86_64.rpm
tree-2.1.0-8.el10.x86_64.rpm: digests signatures OK
--- and the full signature line ---
Signature   :
```

</details>

**`digests signatures OK` is the whole verification**, and it is two separate
checks. **Digests** confirm the file is intact, the contents match the
checksums recorded in the package. **Signatures** confirm the package was
signed by a key the machine trusts.

The keys the machine trusts are themselves stored as pseudo-packages:

```bash
# AlmaLinux 10.2, x86_64
$ dnf install -y -q tree >/dev/null 2>&1; echo '--- who signed this package ---'; rpm -qi tree | grep -E 'Signature|Name|Version'; echo '--- and the keys this machine trusts ---'; rpm -q gpg-pubkey --qf '%{SUMMARY}\n' | head -4
--- who signed this package ---
Name        : tree
Version     : 2.1.0
Signature   :
--- and the keys this machine trusts ---
AlmaLinux OS 10 <packager@almalinux.org> public key
```

**One key, one publisher.** That listing is the machine's complete trust set
for packages, and on a server that has accumulated third-party repositories
over the years it is worth reading, every entry is somebody who can install
software as root on that machine.

**What a signature does not prove** is worth being equally clear about. It says
nothing about whether the software is safe, well-written, or free of
vulnerabilities. It proves origin and integrity, and those are exactly two
properties. A signed package from a compromised publisher is a correctly signed
malicious package.

## Adding a repository, on each family

**RHEL family**, a `.repo` file in `/etc/yum.repos.d/`:

```ini
[example]
name=Example Software
baseurl=https://packages.example.com/el10/$basearch/
enabled=1
gpgcheck=1
gpgkey=https://packages.example.com/RPM-GPG-KEY-example
```

```
sudo rpm --import https://packages.example.com/RPM-GPG-KEY-example
sudo dnf repolist
```

**`gpgcheck=1` is the line that matters** and the one that instructions sometimes
tell you to set to 0. Never do that. If a repository's packages are unsigned, that
is information about the publisher, not an obstacle to route around.

**Debian family**, a source list plus a keyring:

```
curl -fsSL https://packages.example.com/gpg.key \
  | sudo gpg --dearmor -o /usr/share/keyrings/example.gpg

echo "deb [signed-by=/usr/share/keyrings/example.gpg] https://packages.example.com stable main" \
  | sudo tee /etc/apt/sources.list.d/example.list

sudo apt update
```

**`signed-by=` is the modern form and it matters.** The old `apt-key add` put
a key into a global keyring that was trusted for **every** repository, so a
third-party key could sign a replacement for any Debian package. `signed-by=`
scopes the key to one source, which is the whole point of adding a key at all.
`apt-key` is deprecated and removed on current releases.

**EPEL** is the exception worth knowing by name on the RHEL family: Extra Packages
for Enterprise Linux, maintained by the Fedora project, and the usual source for
things RHEL does not ship.

```
sudo dnf install epel-release
```

It is packaged, so the repository definition and the key arrive together and
verifiably, which is the pattern to prefer for any third party that offers it.

<details class="predict">
<summary>An installation guide says to run `dnf install --nogpgcheck ...` because "the repo key is not set up yet". What are you actually agreeing to?</summary>

**To install and run, as root, a package whose origin you cannot verify.**

`--nogpgcheck` disables the check that the package came from who it claims and
has not been altered. Without it you are trusting the network path, DNS, the
mirror, and everyone with access to any of them.

RPM packages run **scriptlets** as root at install time. A package is not data
being copied into place; it is code that executes with full privileges. So the
question is not "is this software trustworthy" but "did this file come from where
I think it did", and that is precisely the question the flag turns off.

**"The key is not set up yet" is not a reason, it is the missing step.** The
correct sequence is to import the key first (from the vendor over HTTPS,
ideally with a fingerprint you can check against their documentation) and then
install normally:

```
sudo rpm --import https://packages.example.com/RPM-GPG-KEY-example
rpm -qa gpg-pubkey --qf '%{SUMMARY} %{VERSION}\n'   # confirm what you imported
sudo dnf install thepackage
```

The `apt` equivalent is `--allow-unauthenticated`, and the same reasoning applies.

**Where it is legitimate:** installing a package you built yourself moments ago on
the same machine, or a genuinely air-gapped process with an out-of-band checksum.
Both are narrow, deliberate, and nothing like following a blog post.

The tell that you are being asked for something unreasonable: a vendor who ships
signed packages does not need you to skip the check, and a vendor who does not
sign has told you something about their release process.

</details>

<details class="deeper">
<summary>If you already administer Linux: what adding a third-party repository actually grants, and how to contain it</summary>

Adding a repository is usually described as "now you can install that package". What
it really does is **add a party whose signing key your machine trusts for every
package it offers**, and by default that party can offer any package name at all.

**The failure mode has a name: dependency confusion.** A third-party
repository can publish a package called `openssl` with a version higher than
the distribution's, and the resolver, which is looking for the newest version
of a name, takes it. Now a core library on your machine comes from somebody
else, is signed by their key, and updates on their schedule. Nobody chose
that; it followed from adding the repo.

**Priorities are the containment on the RPM side.** With `dnf-plugin-priorities`, a
numerically lower priority wins regardless of version:

```ini
[epel]
priority=99
```

The distribution's own repositories default to 99, so giving a third party a
higher number keeps it strictly subordinate. `excludepkgs=` on the third-party
repo, or `includepkgs=` naming only what you want from it, is the tighter
version, a whitelist rather than a preference.

**APT calls the same idea pinning**, and its rules are less intuitive because a
higher `Pin-Priority` wins:

```
Package: *
Pin: origin download.example.com
Pin-Priority: 100
```

Below 500 means "only install from here when nothing else provides it", which is
the third-party default you want. Above 1000 means "downgrade other packages to
satisfy this", which is almost never what anyone intends and is worth recognising
in somebody else's config.

**Check what you are actually getting before it matters:**

```
dnf repoquery --qf '%{name} %{repoid}' --installed | grep -v ' baseos\| appstream'
apt-cache policy
apt list --installed 2>/dev/null | grep -v Debian
```

Each answers "which packages on this machine did not come from the
distribution", which is a question worth asking on any host you inherit, and a
question an auditor will eventually ask you, since it is the practical version
of the software supply chain conversation in lesson 50.

**The key is the part people skip.** `rpm --import` and a keyring in
`/etc/apt/keyrings/` both mean "trust anything this key signs, forever". Fetching
that key over plain HTTP, or piping a vendor's install script straight into a
shell, hands over that trust without ever verifying who you got it from. Fetch keys
over HTTPS from the vendor's own domain and check the fingerprint against something
they published separately.

</details>

## Querying what is installed

The low-level tools answer questions about the local database. They do not talk
to repositories.

| Question | RHEL family | Debian family |
| --- | --- | --- |
| What owns this file? | `rpm -qf /path` | `dpkg -S /path` |
| What files did this install? | `rpm -ql name` | `dpkg -L name` |
| Is it installed, and which version? | `rpm -q name` | `dpkg -l name` |
| What does it need? | `rpm -qR name` | `dpkg -s name` |
| What changed since install? | `rpm -V name` | `debsums -c name` |
| Everything about it | `rpm -qi name` | `dpkg -s name` |

**`rpm -V` is the one worth knowing and rarely used.** It compares every installed
file against the checksums, sizes, permissions, and ownership recorded at install
time, and reports what differs:

```
sudo rpm -Va | grep -v '^..5......  c '
```

The output is a column of flags per file (`5` a changed checksum, `S` size,
`M` mode, `U` owner) and the `c` marks config files, which are *supposed* to
change, hence filtering them out. A modified binary in `/usr/bin` with no
explanation is a genuine finding, and this is the only routine way to notice
one.

`debsums -c` is the Debian equivalent and needs installing.

## Holding a package back

Sometimes a package must not move: a database certified against one point release,
or a kernel a vendor driver was built against.

| | RHEL family | Debian family |
| --- | --- | --- |
| Hold | `dnf versionlock add name` | `apt-mark hold name` |
| Release | `dnf versionlock delete name` | `apt-mark unhold name` |
| List | `dnf versionlock list` | `apt-mark showhold` |
| Exclude in config | `exclude=` in `dnf.conf` | `/etc/apt/preferences.d/` |

**Every hold stops security updates for that package, silently, indefinitely.**
The person who set it will have moved on and the hold will not have. It is a
decision with an expiry date and no mechanism to enforce one.

Three things make it survivable: record it where the fleet's configuration
lives rather than only on the machine, scope it as narrowly as possible (one
package, never a repository) and put a review date on it somewhere a human
will see.

**Excluding kernels to protect an out-of-tree driver** is the specific case worth
refusing. It trades a driver problem for an unpatched kernel, which is
considerably worse. DKMS from lesson 10 solves it properly.

<details class="deeper">
<summary>If you already administer Linux: repository priorities, and stopping a third party eating your base</summary>

The failure mode of a third-party repository is not that it fails. It is that it
succeeds too broadly.

A repository offering a newer `curl`, `glibc`, or `systemd` than the distribution
will win the version comparison, and `dnf upgrade` will replace core system
packages with that publisher's builds. The machine still works and is no longer
the distribution you thought you were running, which makes it unsupportable and
frequently unbootable after the next base update.

**On the RHEL family**, `dnf-plugin-priorities` or the `priority=` key orders
repositories, lower wins, so the base repository can be made to outrank a
third party regardless of version. Better still, `includepkgs=` in the repo
file limits it to exactly the packages you added it for:

```ini
[example]
includepkgs=example-agent example-agent-plugins
priority=99
```

**On Debian**, `/etc/apt/preferences.d/` does the same with pin priorities: pin
the third-party origin at 100 and the distribution at 500, and apt will only take
packages from the third party that the distribution does not provide at all.

**`dnf repoquery --repo=example --available`** lists everything a repository is
offering before you enable it, which is the check to run *before* adding it rather
than after. A vendor agent repository offering four hundred packages including
`openssl` is telling you something.

**Modules on the RHEL family** are a related trap: `dnf module list` shows streams,
and a package that appears missing is frequently present in a stream nobody
enabled. `dnf module enable nodejs:20` pins the machine to that stream, and
switching later requires a reset and a reinstall.

</details>

<details class="deeper">
<summary>If you already administer Linux: alternatives, and how one command becomes several programs</summary>

Several packages can provide `java`, `python`, `editor`, or `iptables`. The
alternatives system decides which one a generic name resolves to, using the
symlink chain from lesson 25.

`/usr/bin/java` is a symlink to `/etc/alternatives/java`, which is a symlink to a
specific JDK. Two hops, and only the middle one moves:

```
sudo update-alternatives --config java     # Debian family
sudo alternatives --config java            # RHEL family
sudo update-alternatives --display java    # what is registered, and priorities
```

**The command name differs between families** (`update-alternatives` on
Debian, `alternatives` on RHEL) which is enough to break a provisioning
script.

Each candidate has a **priority**, and in automatic mode the highest wins. That is
why installing a newer JDK can silently change the default for the whole machine,
and why `--config` switching to manual mode is what you want when you have
deliberately chosen one.

**`--install` registers your own**, which is the tidy way to make a locally-built
tool available under a standard name without overwriting anything a package owns:

```
sudo update-alternatives --install /usr/local/bin/mytool mytool /opt/mytool/2.1/bin/mytool 100
```

Worth knowing because the alternative, a symlink you created by hand in
`/usr/bin`, is a file no package owns, which is exactly the finding lesson 08
warned about.

`iptables` and `nftables` coexist through this mechanism on both families, which
is why `iptables` on a modern machine may be `iptables-nft` in disguise, and why
`update-alternatives --display iptables` is a useful thing to check before
debugging firewall rules.

</details>

## Across distributions

| | RHEL family | Debian family |
| --- | --- | --- |
| Repo config | `/etc/yum.repos.d/*.repo` | `/etc/apt/sources.list.d/*` |
| Key store | `rpm --import`, `gpg-pubkey` packages | `/usr/share/keyrings/`, `signed-by=` |
| Verify a package file | `rpm -K file.rpm` | `dpkg-sig --verify`, or apt's own check |
| Verify installed files | `rpm -V` | `debsums -c` |
| Community extras | EPEL | already in `main`, `contrib`, `non-free` |
| Transaction rollback | `dnf history undo` | none |

The `deb822` format (the `.sources` files with `Types:`, `URIs:`, and
`Signed-By:` keys seen in lesson 08) is replacing the one-line `.list` format
on Debian and is clearer. Both work on current releases.

## Prove it

After adding a repository:

```bash
# Is it enabled, and what is it called
dnf repolist                        # RHEL family
apt policy                          # Debian family

# What is it actually offering
dnf repoquery --repo=example --available | head -20
apt list --all-versions -a thepackage

# Which repository will a package come from
dnf info thepackage | grep -i repo
apt policy thepackage

# Is verification actually on
grep -r gpgcheck /etc/yum.repos.d/
grep -r signed-by /etc/apt/sources.list.d/
```

**`apt policy thepackage` is the underrated one.** It shows every available
version, which repository each comes from, and which one apt would install,
answering "why am I getting this version" in a single command.

## What trips people up

### 1. GPG check failed

`NO_PUBKEY` on Debian or `GPG check FAILED` on RHEL means the key is missing or
does not match.

Import the key properly. Do **not** reach for `--nogpgcheck` or
`--allow-unauthenticated`; the message is the security control working.

A second cause worth knowing: the publisher rotated their key. Their documentation
will say so, and the fix is importing the new one, not disabling the check.

### 2. `apt-key` in an instruction

Deprecated and removed on current releases, because it trusted the key for every
repository rather than one.

`gpg --dearmor` into `/usr/share/keyrings/` and reference it with `signed-by=`.
Any guide still using `apt-key` is old enough to be worth double-checking
generally.

### 3. A third-party repo replacing system packages

The repository offers a newer `glibc` or `systemd` and wins the version
comparison, and the machine stops being the distribution it claims to be.

`includepkgs=` and `priority=` on RHEL, pin priorities on Debian. Check what a
repository offers before enabling it.

### 4. A package that will not move

Usually a hold or an exclude set months ago by somebody who has left.

`dnf versionlock list` or `apt-mark showhold`. Also check `exclude=` in
`/etc/dnf/dnf.conf` and anything in `/etc/apt/preferences.d/`.

### 5. Assuming a signature means "safe"

It proves origin and integrity only. A signed package from a compromised publisher
is a correctly signed malicious package, and supply-chain attacks work precisely
this way.

## Work it through

A vendor's installation guide for their monitoring agent reads:

```
curl -s https://packages.vendor.example/setup.sh | sudo bash
```

You are asked to install it on forty production servers. Reason it out before
reading on.

**What that command does**, spelled out: downloads a script whose contents nobody
has seen, over a connection whose only guarantee is that the hostname matched a
certificate, and executes it as root. It will almost certainly add a repository
and a key, and it may do anything else at all.

Once. On forty machines. With no record of what it did.

**What to do instead, in order.**

**Read it first.** `curl -s https://packages.vendor.example/setup.sh | less`. That
one change costs nothing and turns an unknown into a known. It will typically show
you the repository URL and the key URL, which are the two things you actually
need.

**Add the repository yourself**, with the key imported explicitly and the
fingerprint checked against the vendor's documentation on a different page:

```
sudo rpm --import https://packages.vendor.example/RPM-GPG-KEY
rpm -qa gpg-pubkey --qf '%{SUMMARY} %{VERSION}\n'
```

**Scope it.** `includepkgs=vendor-agent vendor-agent-*` and `priority=99` in the
`.repo` file, so this vendor can never supply anything except their agent. Check
what they are offering first:

```
sudo dnf repoquery --repo=vendor --available | wc -l
```

Four hundred packages including `openssl` is a different proposition from six
packages, and it is worth finding out which before rather than after.

**Then install normally**, with verification on, and let configuration management
place the repo file and the key on all forty rather than a curl-to-bash on each.

**Test on one machine, and record what changed:**

```
sudo dnf history          # what the transaction actually did
sudo dnf history info 42
```

Which also gives you `dnf history undo 42` if it goes wrong, something the
shell script cannot offer.

Now the point worth extracting. **The package manager already solves this problem
and the script asks you to opt out of it.** Signature verification, a record of
what was installed, a list of files owned, an upgrade path, and a rollback are all
things you get for free from `dnf install` and lose entirely from `curl | bash`.

The habit: **when a vendor offers a script and a repository, take the
repository.** And when they offer only a script, read it, because the
repository is in there, and using it directly is nearly always available to
you even when the documentation does not mention it.

## Try it

Optional, on any machine.

1. `rpm -qa gpg-pubkey --qf '%{SUMMARY}\n'` or
   `ls /usr/share/keyrings/ /etc/apt/trusted.gpg.d/`. Read your trust set.
2. `dnf repolist` or `apt policy`. Name every repository and why it is there.
3. `rpm -qf $(which ls)` or `dpkg -S $(which ls)`.
4. `rpm -ql coreutils | head` or `dpkg -L coreutils | head`.
5. `sudo rpm -Va | head -20` or `sudo debsums -c`. Read the flags.
6. `apt policy bash` or `dnf info bash | grep -i repo`.
7. `update-alternatives --display editor` if it exists, and follow the symlinks.

**Verification step.** You have it when you can add a third-party repository,
scoped to the packages you actually want, with its key verified, and explain
to somebody why `--nogpgcheck` was not part of it.

## Check yourself

<details class="qa">
<summary>What does a package signature prove, and what does it not?</summary>

**It proves two things: origin and integrity.** The package was produced by
whoever holds the signing key, and it has not been altered since.

`rpm -K` reports both separately: `digests signatures OK` means the contents
match the recorded checksums *and* the signature verifies against a trusted
key.

**It proves nothing about quality or safety.** Signed software can be badly
written, vulnerable, or malicious. A compromised publisher produces correctly
signed malicious packages, which is exactly how supply-chain attacks work.

The distinction matters when deciding what to trust: signing lets you stop
worrying about the network, the mirror, and DNS, and moves the entire question
to "do I trust this publisher", which is a decision you make once per
repository and inherit for every package they ever ship.

</details>

<details class="qa">
<summary>Why is `signed-by=` better than the old `apt-key add`?</summary>

**Scope.** `apt-key add` put the key into a global keyring trusted for **every**
repository, so a third-party key could sign a replacement for any Debian package
and apt would accept it.

`signed-by=/usr/share/keyrings/example.gpg` in the source entry binds that key to
that one repository. A key that can only vouch for its own source cannot be used
to substitute anything else.

That is the whole point of adding a key in the first place, and the old mechanism
undermined it.

`apt-key` is deprecated and removed on current releases. Any instructions still
using it are old enough to be worth checking generally.

</details>

<details class="qa">
<summary>What does `rpm -V` do, and why is it worth running?</summary>

**It compares every installed file against what was recorded at install time**
(checksum, size, mode, owner, group, and timestamp) and reports what differs.

The output is a flag column per file: `5` a changed checksum, `S` size, `M` mode,
`U` owner, and `c` marking config files.

Why it matters: config files are *supposed* to change, so filtering those out
leaves a list of files that changed and should not have. **A modified binary in
`/usr/bin` with no explanation is a genuine finding**, and this is the only
routine way to notice one on a running system.

```
sudo rpm -Va | grep -v ' c '
```

`debsums -c` is the Debian equivalent and needs installing separately.

</details>

<details class="qa">
<summary>Why is holding a package back a decision with a cost, and how do you make it survivable?</summary>

**A held package stops receiving security updates**, silently and indefinitely.
Nothing expires the hold and nothing reports it, so it outlives the reason it was
set and usually the person who set it.

Three things make it survivable:

**Record it where the fleet's configuration lives**, not only on the machine, so it
appears in review rather than being discovered during an incident.

**Scope it as narrowly as possible**, one package, never a whole repository,
and never `exclude=*`.

**Attach a review date** somewhere a human will actually see.

The case to refuse outright is excluding kernels to protect an out-of-tree driver:
that trades a driver problem for an unpatched kernel, and DKMS solves it properly.

`dnf versionlock list` and `apt-mark showhold` are the first things to check when
a package will not move.

</details>

<details class="qa">
<summary>A vendor's guide says `curl -s https://... | sudo bash`. What do you lose, and what do you do instead?</summary>

**You lose everything the package manager provides:** signature verification, a
record of what was installed, the list of files owned, an upgrade path, and a
rollback. You also execute unreviewed code as root, fetched at that moment, with
no record of what it contained.

**Instead:** read the script first. It costs nothing and it will show you the
repository and key URLs, which are what you actually need. Import the key
explicitly and check the fingerprint against the vendor's documentation. Add
the repository yourself, scoped with `includepkgs=` and `priority=` so that
vendor can only supply their own agent. Then install normally with
verification on.

`dnf repoquery --repo=vendor --available` before enabling it tells you whether
they are offering six packages or four hundred including `openssl`, which is
worth knowing beforehand.

The general point: the repository is nearly always available directly even when the
documentation only advertises the script.

</details>

## References

- [rpm(8)](https://man7.org/linux/man-pages/man8/rpm.8.html) - Linux man-pages project. Accessed 2026-08-07.
- [dpkg(1)](https://man7.org/linux/man-pages/man1/dpkg.1.html) - Linux man-pages project. Accessed 2026-08-07.
- [sources.list(5)](https://manpages.debian.org/stable/apt/sources.list.5.en.html) - Debian Project. Accessed 2026-08-07.
- [apt-secure(8)](https://manpages.debian.org/stable/apt/apt-secure.8.en.html) - Debian Project. Accessed 2026-08-07.
- [dnf.conf(5)](https://dnf5.readthedocs.io/en/latest/dnf5.conf.5.html) - DNF project. Accessed 2026-08-07.
- [update-alternatives(1)](https://manpages.debian.org/stable/dpkg/update-alternatives.1.en.html) - Debian Project. Accessed 2026-08-07.

Every block above with a distribution and architecture header was captured by running the command on an AlmaLinux 10.2 container. Blocks without one are illustrative.
