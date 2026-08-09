# CompTIA Linux+ XK0-006: phase 1 research

Research and planning for the `linux-plus` learn track. No content was written in
this phase. Everything below is either confirmed against a CompTIA-published
source or explicitly labeled as unconfirmed.

Every objective, sub-bullet, and acronym here comes from CompTIA's released
XK0-006 V8 objectives document, not from a secondary summary.

Research date: 2026-08-07. Every URL in the [source table](#source-table) was
accessed on that date.

Companion document: [linux-plus-teaching-design.md](linux-plus-teaching-design.md),
which covers how this gets presented as teaching material rather than what is on
the exam.

- [Bottom line](#bottom-line)
- [Sources used](#sources-used)
- [Draft-to-release reconciliation](#draft-to-release-reconciliation)
- [Your assumptions, checked](#your-assumptions-checked)
- [The 29 objectives](#the-29-objectives)
- [Tools named explicitly](#tools-named-explicitly)
- [Distribution coverage required](#distribution-coverage-required)
- [Where objectives overlap](#where-objectives-overlap)
- [Proposed topic list](#proposed-topic-list) (superseded)
- [The beginner-first recut](#the-beginner-first-recut)
- [Objective-to-topic mapping](#objective-to-topic-mapping)
- [Source table](#source-table)
- [Repo drift found while verifying](#repo-drift-found-while-verifying)
- [Copyright constraint on the objectives document](#copyright-constraint-on-the-objectives-document)
- [What I need from you](#what-i-need-from-you)

## Bottom line

Your secondary sources were unusually good. Every headline number you gave me is
correct: 29 objectives, five domains, 23/20/18/17/22, 90 questions, 90 minutes,
720 on 100-900, Pearson VUE, three-year validity with CE renewal. I found two
claims I could not confirm and several material omissions, all listed below.

The structural finding that changes your plan most: **AppArmor does not appear
anywhere in XK0-006.** SELinux is named repeatedly, in two separate objectives.
Your hypothesized "SELinux and AppArmor" topic should be a SELinux topic.

The second: **Kubernetes is a named objective sub-topic** (ConfigMaps, Secrets,
Pods, Deployments, Volumes, Services), as are Docker Swarm and Compose. You did
not list orchestration at all in your topic hypothesis, and it is a meaningful
share of the 17 percent automation domain.

The third: **OpenTofu is named; Terraform is not.**

The fourth only became visible once the released PDF was in hand: **the acronym
list carries 22 terms that appear nowhere in the objectives text**, and CompTIA
states that listed acronyms appear on the exam. Four of them change topic scope
outright - CUPS, ACME, EPEL, and GDPR. Printing is on this exam, and no objective
bullet says so.

## Sources used

Three CompTIA-published artifacts, in descending authority:

1. **The released objectives document.** `CompTIA Linux+ Certification Exam
   Objectives, EXAM NUMBER: XK0-006 V8`, copyright 2024 CompTIA, print code
   `11409-Aug2024`. Twenty pages. This is the gated download from the V8 page;
   Ryan supplied it. Everything in the objective tables below now traces here.

2. **The live V8 certification page.** Ungated. Exam logistics, the five domains
   with weightings, and one-line summaries of all 29 objectives in order.

3. **The CompTIA CDN copy of the same document at DRAFT version 1.2**
   (`11409-Aug24`, August 2024), retained only as a diff target so the
   [reconciliation](#draft-to-release-reconciliation) below could be done.

The gated PDF carries no visible version number on any page I could extract;
"XK0-006 V8" is the only identifier on it. Secondary sources refer to released
versions 4.0 and 5.0, so if CompTIA revises again, the tell will be the print
code rather than a version string.

## Draft-to-release reconciliation

I diffed the released document against the draft to see what moved. **The answer
is almost nothing, and that is worth knowing.**

- **All 29 objective statements are verbatim identical**, in the same order,
  under the same numbers. Every entry in the objective tables below is now
  first-hand.
- **Domain weightings identical**: 23/20/18/17/22.
- **Sub-bullets substantively unchanged.** I probed roughly thirty terms across
  both documents; the objectives body matches. AppArmor is still absent.
  Terraform is still absent. Kubernetes, OpenTofu, Ansible, and Puppet are still
  present exactly where the draft had them.

Three corrections CompTIA made:

| Draft 1.2 | Released | Comment |
| --- | --- | --- |
| "Solid-state hybrid drive (SSHD)" under 3.3 secure remote access | "Secure Shell daemon (SSHD)" | The draft had the wrong expansion entirely, in both the objective and the acronym list. Fixed in both places. |
| "Open Tofu" | "OpenTofu" | Correct product name. |
| "virt-man" | "virt-manager" | Truncation fixed. |

One they did not: 1.1 still reads "Debian **packet** manager (dpkg)-based".

### The real change is the acronym list

CompTIA states that the listed acronyms "appear on the CompTIA Linux+ exam" and
that candidates should "attain a working knowledge of all listed acronyms". The
released list added 22 entries **that appear nowhere in the objectives body**.
That is the one place the released document tells you something the draft, and
every objective summary, does not:

| Acronym | Expansion | Nearest objective, and what it implies |
| --- | --- | --- |
| ACME | Automated Certificate Management Environment | 3.5. Certificate *issuance and renewal*, not just trust stores. Implies Let's Encrypt and `certbot`. |
| CA | Certificate Authority | 3.5. Reinforces the above. |
| CUPS | Common UNIX Printing System | 2.4. **Printing is not mentioned anywhere in the objectives text.** |
| EPEL | Extra Packages for Enterprise Linux | 2.4. Third-party repositories, concretely, on the RHEL side. |
| TOTP | Time-based One-time Password | 3.4. MFA is named in 3.4; TOTP says which kind. |
| GDPR | General Data Protection Regulation | 3.6. The only named regulation in the whole document. |
| ICMP | Internet Control Message Protocol | 5.3. What `ping` and `traceroute` actually ride on. |
| TTL | Time to Live | 5.3. Both DNS caching and IP hop limit senses. |
| TCP, UDP | Transmission Control / User Datagram Protocol | 1.4, 5.3. |
| FEC | Forward Error Correction | 5.3. Link-quality territory; pairs with the "link negotiation issues" bullet. |
| FQDN | Fully Qualified Domain Name | 1.4, 5.3. |
| NIC | Network Interface Card | 1.4, 5.3. |
| LAN, WAN | Local / Wide Area Network | 1.4. |
| UUID | Universally Unique Identifier | 1.3. `blkid` and `/etc/fstab` by UUID rather than device name. |
| PV | Physical Volume | 1.3. Already covered by LVM. |
| PHP | PHP: Hypertext Preprocessor | 2.4. Implies a real web stack, not just starting httpd. |
| CMS | Content Management System | 2.4 or 2.6. Ambiguous; most likely the thing you deploy. |
| CSV | Comma-separated Value | 1.5, 4.3. Text processing and Python. |
| XML | Extensible Markup Language | 4.3. Config and data formats. |
| IaC | Infrastructure as Code | 4.1. Already covered. |
| GPG2 | GNU Privacy Guard 2 | 2.4, 3.5. Package signing and file encryption. |

Four of these change topic scope rather than just vocabulary: **CUPS** (printing,
otherwise entirely unmentioned), **ACME** (certificate lifecycle, not just trust),
**EPEL** (a specific third-party repo), and **GDPR** (a named regulation in a
compliance objective that otherwise names only OpenSCAP and CIS). I have folded
all four into the topic plan.

CompTIA's own typos survive into the released list: "Comma-**seperated** Value",
"**Univerally** Unique Identifier", "Extensible Markup **Langage**". Worth
noting only because it is a reminder that this document is not carefully
proofread, and a sub-bullet that reads oddly may be an error rather than a
subtlety.

## Your assumptions, checked

| Your claim | Verdict | What CompTIA says |
| --- | --- | --- |
| XK0-006 is current, sometimes labeled Linux+ V8 | Correct | "Exam version: V8", "Exam series code: XK0-006". V8 is the primary label, not the informal one. |
| 29 objectives across 5 domains | Correct | 7 + 6 + 6 + 5 + 5 = 29. |
| 1.0 System Management 23% | Correct | 23% |
| 2.0 Services and User Management 20% | Correct | 20% |
| 3.0 Security 18% | Correct | 18% |
| 4.0 Automation, Orchestration, and Scripting 17% | Correct | 17% |
| 5.0 Troubleshooting 22% | Correct | 22% |
| Up to 90 questions in 90 minutes | Correct | "Maximum of 90", "Duration: 90 minutes" |
| Passing score 720 on 100 to 900 | Correct | "Passing score: 720 (on a scale of 100-900)" |
| Multiple-choice plus performance-based | Correct | "Maximum of 90 (multiple-choice and performance-based)" |
| PBQs weighted more heavily than XK0-005 | **Unconfirmed** | CompTIA publishes no per-question-type weighting for either exam. I found no CompTIA statement supporting this. Treat as vendor marketing until shown otherwise, and do not repeat it in content. |
| Pearson VUE, testing center or online proctored | Correct | Scheduled through "Pearson VUE's website, our trusted testing service provider", in person at a test center or online "through OnVUE". |
| Valid 3 years, renewable through CompTIA CE | Correct | "Certifications expire three years from the certification date." Linux+ is explicitly listed as CE-eligible. Renewal is 50 CEUs. |
| XK0-005 retired January 13, 2026 | **Consistent, not primary-confirmed** | Multiple secondary sources agree on January 13, 2026 for English. CompTIA removes retired exams from its site, so there is no live CompTIA page left to confirm it against. Low stakes: it does not reach content. |

### Things you did not have that matter

| Fact | Source | Why it matters |
| --- | --- | --- |
| Launch date July 15, 2025; retirement estimated 2028 | V8 page | Gives the track a shelf life. Worth stating on the track index. |
| English only | V8 page | XK0-005 had Japanese, Portuguese, Spanish. V8 does not, yet. |
| ANSI/ANAB accredited to ISO 17024 | V8 page and objectives doc | Explains why objectives get revised mid-cycle, which is why the sub-bullet caveat above is real rather than pedantic. |
| Recommended: 12 months hands-on; A+, Network+, or Server+ | V8 page | Sets the floor for how much I explain. This is not a beginner audience. |
| No exam price on any CompTIA page I could reach | - | Partner vouchers run roughly 365-399 USD. Not citable to a primary source, so it should not appear in content. |

## The 29 objectives

Objective titles and ordering: confirmed against the live V8 page. Statement
wording: from the CompTIA draft v1.2. Sub-bullet summaries: from the draft,
condensed, pending reconciliation with the released document.

### 1.0 System Management (23%)

| # | Objective | Principal subject matter |
| --- | --- | --- |
| 1.1 | Explain basic Linux concepts | Boot process (bootloader and config, kernel and parameters, initrd, PXE); Filesystem Hierarchy Standard; server architectures (AArch64, RISC-V, x86, x86_64); RPM-based vs dpkg-based distributions; GUI stack (display managers, window managers, X Server, Wayland); software licensing (open source, free, proprietary, copyleft) |
| 1.2 | Summarize Linux device management concepts and tools | Kernel modules (`depmod`, `insmod`, `lsmod`, `modinfo`, `modprobe`, `rmmod`); device tooling (`dmesg`, `dmidecode`, `ipmitool`, `lm_sensors`, `lscpu`, `lshw`, `lsmem`, `lspci`, `lsusb`); initrd management (`dracut`, `mkinitrd`); embedded systems and GPU use cases |
| 1.3 | Given a scenario, manage storage in a Linux system | LVM at all three layers (pv*, vg*, lv*); partitioning (`blkid`, `fdisk`/`gdisk`, `growpart`, `lsblk`, `parted`); filesystems (xfs, ext4, btrfs, tmpfs) and utilities (`df`, `du`, `fio`, `fsck`, `mkfs`, `resize2fs`, `xfs_growfs`, `xfs_repair`); RAID (`/proc/mdstat`, `mdadm`); mounting (`/etc/fstab`, `/etc/mtab`, `/proc/mounts`, `autofs`, mount options); NFS and SMB/Samba; inodes |
| 1.4 | Given a scenario, manage network services and configurations on a Linux server | `/etc/hosts`, `/etc/resolv.conf`, `/etc/nsswitch.conf`; NetworkManager (`nmcli`); Netplan (`netplan apply`/`status`/`try`, `/etc/netplan`); diagnostic tooling (`arp`, `curl`, `dig`, `ethtool`, `hostname`, `ip` addr/link/route, `iperf3`, `mtr`, `nc`, `nmap`, `nslookup`, `ping`/`ping6`, `ss`, `tcpdump`, `tracepath`, `traceroute`) |
| 1.5 | Given a scenario, manage a Linux system using common shell operations | Environment variables (DISPLAY, HOME, PATH, PS1, SHELL, USER); absolute and relative paths; shell config (`.bashrc`, `.bash_profile`, `.profile`); channel redirection and here-docs; text utilities (`awk`, `sed`, `grep`, `cut`, `sort`, `uniq`, `tr`, `tee`, `wc`, `xargs`, `head`, `tail`, `less`, `more`, `printf`, `history`, `alias`, `source`); `vi`/`vim` and `nano` |
| 1.6 | Given a scenario, perform backup and restore operations for a Linux server | Archiving (`cpio`, `tar`); compression (7-Zip, `bzip2`, `gzip`, `unzip`, `xz`); `dd`, `ddrescue`, `rsync`, `zcat`, `zgrep`, `zless` |
| 1.7 | Summarize virtualization on Linux systems | QEMU and KVM; paravirtualized drivers and VirtIO; disk image operations (convert, resize, properties); VM states, nested virtualization, snapshots, cloning, migration, baseline templates; network types (bridged, NAT, host-only/isolated, routed, open); `libvirt`, `virsh`, `virt-man` |

### 2.0 Services and User Management (20%)

| # | Objective | Principal subject matter |
| --- | --- | --- |
| 2.1 | Given a scenario, manage files and directories on a Linux system | `cd`, `cp`, `diff`, `file`, `find`, `ln`, `locate`, `ls`, `lsof`, `mkdir`, `mv`, `pwd`, `rm`, `rmdir`, `sdiff`, `stat`, `touch`; symbolic vs hard links; block, character, and special character devices in `/dev` |
| 2.2 | Given a scenario, perform local account management in a Linux environment | Add/delete/modify/lock (`useradd`, `adduser`, `groupadd`, `userdel`, `deluser`, `groupdel`, `usermod`, `groupmod`, `chsh`, `passwd`, `chage`); listing (`getent passwd`, `groups`, `id`, `last`, `lastlog`, `w`, `who`, `whoami`); `/etc/passwd`, `/etc/group`, `/etc/shadow`, `/etc/skel`, `/etc/profile`; UID, GID, EUID, EGID; user vs system vs service accounts and UID ranges |
| 2.3 | Given a scenario, manage processes and jobs in a Linux environment | Inspection (`/proc/<PID>`, `atop`, `htop`, `lsof`, `mpstat`, `pidstat`, `ps`, `pstree`, `strace`, `top`); PID and PPID; process states including zombie; `nice`/`renice`; job control (`&`, `bg`, `fg`, `jobs`, Ctrl+C/D/Z, `exec`, `nohup`); signals (1 HUP, 9 KILL, 15 TERM), `kill`, `killall`, `pkill`; scheduling (`anacron`, `at`, `crontab`) |
| 2.4 | Given a scenario, configure and manage software in a Linux environment | Install/update/remove from repository or source; dependencies and conflicts; package managers; language-specific managers (`pip`, `cargo`, `npm`); repository management, third-party repos, GPG signatures; exclusions; update alternatives; sandboxed applications; basic configuration of DNS, NTP/PTP, DHCP, HTTP (httpd, Nginx), SMTP, IMAP4 |
| 2.5 | Given a scenario, manage Linux using systemd | Unit types (services, timers, mounts, targets); `hostnamectl`, `resolvectl`, `sysctl`, `systemctl`, `systemd-analyze`, `systemd-blame`, `systemd-resolved`, `timedatectl`; unit state management (`daemon-reload`, `enable`, `disable`, `mask`, `unmask`, `edit`, `reload`, `restart`, `start`, `status`, `stop`) |
| 2.6 | Given a scenario, manage applications in a container on a Linux server | Runtimes (runC, Podman, containerd, Docker); image operations (pull, build via Dockerfile with ENTRYPOINT/CMD/USER/FROM, prune, tags, layers); container operations (logs, volume mapping, start/stop, inspect, delete, run, exec, env vars); volume operations including SELinux context and overlay; container networks (macvlan, ipvlan, host, bridge, overlay, none; port mapping); privileged vs unprivileged |

### 3.0 Security (18%)

| # | Objective | Principal subject matter |
| --- | --- | --- |
| 3.1 | Summarize authorization, authentication, and accounting methods | Polkit; PAM; SSSD/Winbind; `realm`; LDAP; Kerberos; Samba; logging (`journalctl`, `rsyslog`, `logrotate`, `/var/log`); system audit (`auditd`, `audit.rules`) |
| 3.2 | Given a scenario, configure and implement firewalls on a Linux system | firewalld (`firewall-cmd`, runtime vs permanent, rich rules, zones, ports vs services); ufw; nftables; iptables; ipset; Netfilter; NAT, PAT, DNAT, SNAT; stateful vs stateless; IP forwarding (`net.ipv4.ip_forward`) |
| 3.3 | Given a scenario, apply OS hardening techniques on a Linux system | sudo (`/etc/sudoers`, `sudoers.d`, `visudo`, NOPASSWD and NOEXEC implications, wheel/sudo group, `sudo -i`, `su -`); file attributes (`chattr`, `lsattr`, immutable, append-only); permissions (`chmod` octal and symbolic, `chown`, `chgrp`, sticky bit, setuid, setgid, umask); ACLs (`setfacl`, `getfacl`); SELinux (`getenforce`, `setenforce`, `semanage`, `chcon`, `restorecon`, `ls -Z`, booleans, `audit2allow`, `sealert`, enforcing/permissive/disabled); SSH hardening (key vs password, tunneling, PermitRootLogin, X forwarding, AllowUsers/AllowGroups, agent, SFTP, chroot, fail2ban); avoiding Telnet/FTP/TFTP; disabling unused filesystems; removing unnecessary SUID; secure boot and UEFI |
| 3.4 | Explain account hardening techniques and best practices | Password complexity, length, expiration, reuse, history; MFA; breach-list checking; restricted shells (`/sbin/nologin`, `/bin/rbash`, `pam_tally2`); avoiding running as root |
| 3.5 | Explain cryptographic concepts and technologies in a Linux environment | Data at rest (GPG file encryption; LUKS2 and Argon2 filesystem encryption); data in transit (OpenSSL, LibreSSL, WireGuard, TLS versions); hashing (SHA-256, HMAC); removal of weak algorithms; certificate management and trusted roots; avoiding self-signed certificates |
| 3.6 | Explain the importance of compliance and audit procedures | Detection and response (anti-malware, IOCs); vulnerability scanning (CVE, CVSS, backporting patches, service misconfiguration, port scanners, protocol analyzers); standards and audit (OpenSCAP, CIS Benchmarks); file integrity (AIDE, rkhunter, signed package verification, installed file verification); secure data destruction (`shred`, `badblocks -w`, `dd if=/dev/urandom`, cryptographic destruction); software supply chain; security banners (`/etc/issue`, `/etc/issue.net`, `/etc/motd`) |

### 4.0 Automation, Orchestration, and Scripting (17%)

| # | Objective | Principal subject matter |
| --- | --- | --- |
| 4.1 | Summarize the use cases and techniques of automation and orchestration in a Linux environment | Ansible (playbooks, inventory, modules, ad hoc, collections, facts, agentless); Puppet (classes, certificates, modules, facts, agent/agentless); OpenTofu (provider, resource, state, API); unattended deployment (Kickstart, cloud-init); CI/CD (version control, shift-left testing, GitOps, pipelines, DevSecOps); orchestration with Kubernetes (ConfigMaps, Secrets, Pods, Deployments, Volumes, Services, variables), Docker Swarm (service, nodes, tasks, networks, scale), and Docker/Podman Compose (compose file, up/down, logs) |
| 4.2 | Given a scenario, perform automated tasks using shell scripting | Parameter expansion, command substitution, subshells; functions; IFS/OFS; conditionals (`if`, `case`); loops (`for`, `while`, `until`); shebang; numeric and string comparison operators; regular expressions with `[[ $foo =~ regex ]]`; test operators (`-d`, `-f`, `-n`, `-z`, `!`); variables, arguments, `export`/`local`/`set`/`unset`; return codes (`$?`) |
| 4.3 | Summarize Python basics used for Linux system administration | Virtual environments; built-in modules; installing dependencies; indentation; current versions; data types and structures (boolean, dictionary, float, integer, list, string); modules and packages; PEP 8 |
| 4.4 | Given a scenario, implement version control using Git | `.gitignore`, `add`, `branch`, `checkout`, `clone`, `commit`, `config`, `diff`, `fetch`, `init`, `log`, `merge`, `squash`, `pull`, `push`, `rebase`, `reset`, `stash`, `tag` |
| 4.5 | Summarize best practices and responsible uses of artificial intelligence (AI) | Use cases (code generation, regex generation, IaC generation, documentation, compliance recommendations, security review, code optimization, linting); best practices (do not copy/paste without review, verify output, data governance including LLM training exposure and human review, local vs public models, corporate policy adherence); prompt engineering |

### 5.0 Troubleshooting (22%)

| # | Objective | Principal subject matter |
| --- | --- | --- |
| 5.1 | Summarize monitoring concepts and configurations in a Linux system | SLA, SLI, SLO; data acquisition (SNMP with traps and MIBs, agent vs agentless, webhooks, health checks, log aggregation); thresholds, alerts, events, notifications, logging |
| 5.2 | Given a scenario, analyze and troubleshoot hardware, storage, and Linux OS issues | Kernel panic; data and kernel corruption; package dependency failures; filesystem will not mount; server will not power on; full OS filesystem; inaccessible server; device failure; inode exhaustion; non-writable partition; segmentation fault; GRUB misconfiguration; killed processes; PATH misconfiguration; systemd unit failures; missing or disabled drivers; unresponsive process; quota issues; memory leaks |
| 5.3 | Given a scenario, analyze and troubleshoot networking issues on a Linux system | Misconfigured firewalls; DHCP and DNS issues; interface misconfiguration (MTU mismatch, bonding, MAC spoofing, subnet, cannot ping); routing and gateway issues; unreachable server; IP conflicts; dual-stack IPv4/IPv6 issues; link down; link negotiation |
| 5.4 | Given a scenario, analyze and troubleshoot security issues on a Linux system | SELinux policy, context, and boolean issues; file and directory permission issues including ACLs and attributes; account access; unpatched systems; exposed or misconfigured services; remote access issues; certificate issues; misconfigured package repository; obsolete or insecure protocols and ciphers; cipher negotiation |
| 5.5 | Given a scenario, analyze and troubleshoot performance issues | Swapping; out of memory; slow application response; unresponsiveness; high CPU, load average, and context switching; failed login attempts; slow startup; high I/O wait; packet drops; jitter; random disconnects and timeouts; high latency; high disk latency; low throughput; blocked processes; hardware errors; sluggish terminal; exceeding baselines; slow remote storage; CPU bottleneck |

## Tools named explicitly

You asked me to confirm which tools the objectives name. Confirmed present, with
the objective that names them:

| Tool | Objective | Notes |
| --- | --- | --- |
| Ansible | 4.1 | Named with sub-bullets: playbooks, inventory, modules, ad hoc, collections, facts, agentless. Also in the equipment list. |
| Puppet | 4.1 | Named with sub-bullets: classes, certificates, modules, facts, agent/agentless. Also in the equipment list. |
| Docker | 2.6, 4.1 | Runtime in 2.6; Swarm and Compose in 4.1. |
| Podman | 2.6, 4.1 | Runtime in 2.6; Podman Compose in 4.1. |
| containerd, runC | 2.6 | Named as runtimes alongside Docker and Podman. |
| Kubernetes | 4.1 | **Not in your list.** ConfigMaps, Secrets, Pods, Deployments, Volumes, Services, variables. Minikube appears in the equipment list. |
| OpenTofu | 4.1 | **Not in your list.** Provider, resource, state, API. |
| Git | 4.4 | A full objective to itself, with about eighteen named subcommands. |
| Python | 4.3 | A full objective to itself. Python 3 in the equipment list. |
| AI | 4.5 | A full objective to itself, plus "LLM access" in the equipment list. |
| Kickstart, cloud-init | 4.1 | Unattended deployment. |
| fail2ban | 3.3 | Under secure remote access. |
| OpenSCAP, CIS Benchmarks | 3.6 | Compliance standards. |
| AIDE, rkhunter | 3.6 | File integrity. |
| WireGuard, OpenSSL, LibreSSL | 3.5 | Data in transit. |
| Samba | 1.3, 3.1 | SMB mounts in 1.3; identity in 3.1. |
| Nginx, Apache httpd | 2.4 | Named HTTP servers. |

Confirmed **absent**, which is as useful:

| Not named | Consequence |
| --- | --- |
| **AppArmor** | Zero occurrences. SELinux is the only MAC framework tested. Do not write an AppArmor topic. Mentioning it in one paragraph as "what Debian and SUSE use instead, not on this exam" is defensible; a topic is not. |
| **Terraform** | OpenTofu is named instead. Write OpenTofu, note the fork relationship in one line. |
| SysVinit, Upstart, OpenRC | systemd is the only init system. XK0-005 carried some SysV baggage; V8 appears not to. |
| `dnf`, `yum`, `apt`, `apt-get`, `zypper` | The objectives say "RPM-based" and "dpkg-based" and "package managers" without naming commands. The concrete commands are still obviously required to answer a scenario question; they are just not enumerated. Cover both families. |
| Prometheus, Nagios, Grafana, Zabbix | 5.1 is vendor-neutral: SLI/SLO, SNMP, webhooks, health checks, log aggregation. Do not build a topic around a specific monitoring product. |
| Wireshark | `tcpdump` and "protocol analyzer" appear; Wireshark by name does not. |
| chrony | NTP/PTP appear as protocols in 2.4; no implementation is named. |
| Cockpit | Not present. |

## Distribution coverage required

The exam is vendor-neutral, and the draft's recommended distribution list makes
the intended spread explicit: **AlmaLinux, Debian, Fedora, openSUSE/SLES, Red
Hat Enterprise Linux, Rocky Linux, Ubuntu.**

That means content has to carry both families throughout, not pick one:

| Axis | What is tested | Practical split |
| --- | --- | --- |
| Package management | RPM-based and dpkg-based, both named in 1.1 | `rpm`/`dnf` on RHEL-family, `dpkg`/`apt` on Debian-family. `zypper` for SUSE is defensible as a third column since SLES is on the distro list. |
| Init | systemd only | No split needed. This simplifies a lot. |
| Network configuration | NetworkManager and Netplan both named in 1.4 | `nmcli` on RHEL-family, `netplan` on Ubuntu. Debian without Netplan is a third case worth one line. |
| Firewall | firewalld, ufw, nftables, iptables all named in 3.2 | firewalld on RHEL-family, ufw on Ubuntu, nftables underneath both. This is the single most distro-split objective. |
| MAC | SELinux only | RHEL-family default. State plainly that Debian and Ubuntu ship AppArmor and that it is out of scope. |
| Filesystem | xfs, ext4, btrfs, tmpfs | xfs default on RHEL, ext4 default on Debian/Ubuntu, btrfs default on openSUSE and Fedora. |
| initrd | `dracut` and `mkinitrd` both named | `dracut` is now used by both families; `mkinitrd` is legacy SUSE. Worth being precise about. |

Your instinct that "the RPM/dpkg split is frequently what gets tested" is
supported: 1.1 names both families as a first-class concept.

Content rule this implies, which I would put in `CONTRIBUTING-learn.md` in phase
2: every command sample states the distribution and version it was verified on,
and any command whose behavior differs across families shows both.

## Where objectives overlap

Writing each concept once, and linking rather than repeating, matters most here.

| Concept | Objectives | Where it gets written | Where it gets linked |
| --- | --- | --- | --- |
| SELinux | 3.3 (configure), 5.4 (troubleshoot) | Own topic under Security: model, contexts, booleans, tooling | Troubleshooting topic covers denial diagnosis and `audit2allow` only, linking back for the model |
| Permissions and ACLs | 2.1 (files), 3.3 (hardening), 5.4 (troubleshoot) | Own topic: bits, special bits, umask, ACLs, attributes | 2.1 file topic and 5.4 link in |
| Storage | 1.3 (manage), 5.2 (troubleshoot) | Two build topics (filesystems/mounts, LVM/RAID) | Troubleshooting topic covers failure modes only |
| Networking | 1.4 (configure), 5.3 (troubleshoot) | Configuration topic owns NetworkManager/Netplan/resolution | Troubleshooting topic owns the diagnostic ladder |
| Firewalls | 3.2 (configure), 5.3 (misconfigured firewalls) | Firewall topic owns all four stacks | Network troubleshooting links in |
| Logging | 3.1 (accounting), 5.1 (monitoring), 2.5 (journald) | Own topic: journald, rsyslog, logrotate, auditd | systemd, AAA, and every troubleshooting topic link in |
| Boot process | 1.1 (explain), 1.2 (initrd), 5.2 (GRUB, kernel panic) | Fundamentals topic owns the sequence and the diagram | Recovery topic owns the failure modes |
| Processes | 2.3 (manage), 5.5 (performance) | Process topic owns states, signals, scheduling | Performance topic owns saturation analysis |
| Containers | 2.6 (manage), 4.1 (orchestrate) | Container topic owns images, volumes, networks | Orchestration topic owns Compose, Swarm, Kubernetes |
| Version control | 4.4 (Git), 4.1 (CI/CD, GitOps) | Git topic owns the commands | Automation topic references workflow only |
| Certificates | 3.5 (manage), 5.4 (cert issues) | Cryptography topic owns PKI and trust stores | Security troubleshooting owns expiry and chain errors |

## Proposed topic list

> **Superseded, 2026-08-07.** This section planned the track for a practitioner.
> The audience is now a complete beginner, which adds a foundations block ahead
> of the exam objectives and pushes the count past 40. The current plan is
> [below](#the-beginner-first-recut). The reasoning here is kept because the
> per-objective analysis of which objectives split and why still holds.

**This comes out at 40 topics, not the "roughly twenty" in your hypothesis.**
You should see that number before committing to phases 2 and 3, because your
per-topic requirements are heavy: real transcribed output, a diagram where the
concept is structural, cross-distribution differences, three or four failure
modes with real error text, an exercise with a verification step, and a cited
references section. Forty of those is a large body of work.

The count is driven by six objectives that are too large for one topic each:

| Objective | Why it splits |
| --- | --- |
| 1.1 | Explains the boot process *and* the FHS *and* architectures *and* distro families *and* licensing |
| 1.3 | Partitions, filesystems, and mounts are one subject; LVM and RAID are another |
| 2.4 | Package management and "basic configurations of common services" share an objective but nothing else |
| 3.3 | The largest single objective on the exam: sudo, permissions and ACLs, SELinux, SSH, secure boot |
| 4.1 | Config management (Ansible, Puppet, OpenTofu) and orchestration (Kubernetes, Swarm, Compose) |
| 5.2 | Nineteen named failure modes spanning hardware, storage, and the OS |

Proportionality check against exam weight:

| Domain | Exam weight | Topics | Topic share |
| --- | --- | --- | --- |
| 1.0 System Management | 23% | 9 | 23% |
| 2.0 Services and User Management | 20% | 8 | 20% |
| 3.0 Security | 18% | 9 | 23% |
| 4.0 Automation, Orchestration, Scripting | 17% | 6 | 15% |
| 5.0 Troubleshooting | 22% | 8 | 20% |
| **Total** | **100%** | **40** | **100%** |

Security runs five points heavy because objective 3.3 alone needs four topics.
Automation runs two points light because 4.2 through 4.5 are each a single
coherent subject with nothing to split. Troubleshooting at 20 percent against a
22 percent weight is close, and its topics will be among the longest, which is
what you actually asked for.

If you want to compress, the merge candidates in order of least damage:

1. `common-network-services` into `package-management` (both 2.4) - saves 1
2. `device-management-and-hardware-discovery` into `the-boot-process-and-the-kernel` (both 1.2) - saves 1
3. `git-for-linux-administration` into `bash-scripting` - saves 1
4. `files-directories-and-links` into `permissions-acls-and-attributes` - saves 1
5. `account-hardening-and-password-policy` into `users-groups-and-local-accounts` - saves 1
6. The two 5.5 performance topics back into one - saves 1
7. The three 5.2 topics down to two - saves 1

Taking all seven gets you to 33. I would not go below that without dropping
objective coverage, which is precisely what the coverage report exists to make
visible.

Track metadata for `blog/src/config/tracks.ts`:

```ts
'linux-plus': {
  name: 'CompTIA Linux+',
  description:
    'XK0-006 study notes built objective by objective, with cited sources, cross-distribution differences, and practice questions that link back to the material.',
  position: 40,
},
```

Position 40 puts it after `security-plus` at 30, which keeps the two
certification tracks adjacent and after the platform tracks.

## Objective-to-topic mapping

Every objective maps to at least one topic. Filenames use the `NN-slug.md`
convention with `order` in tens, per `CONTRIBUTING-learn.md`.

| NN | Slug | Level | Order | Objectives |
| --- | --- | --- | --- | --- |
| 01 | `linux-fundamentals-and-the-fhs` | intro | 10 | 1.1 |
| 02 | `the-boot-process-and-the-kernel` | working | 20 | 1.1, 1.2 |
| 03 | `device-management-and-hardware-discovery` | working | 30 | 1.2 |
| 04 | `shell-operations-and-text-processing` | intro | 40 | 1.5 |
| 05 | `partitions-filesystems-and-mounts` | working | 50 | 1.3 |
| 06 | `lvm-and-raid` | deep | 60 | 1.3 |
| 07 | `network-configuration` | working | 70 | 1.4 |
| 08 | `backup-restore-and-archiving` | working | 80 | 1.6 |
| 09 | `virtualization-with-qemu-and-kvm` | working | 90 | 1.7 |
| 10 | `files-directories-and-links` | intro | 100 | 2.1 |
| 11 | `permissions-acls-and-attributes` | working | 110 | 2.1, 3.3 |
| 12 | `users-groups-and-local-accounts` | working | 120 | 2.2 |
| 13 | `processes-jobs-and-scheduling` | working | 130 | 2.3 |
| 14 | `package-management-across-rpm-and-dpkg` | working | 140 | 2.4 |
| 15 | `common-network-services` | working | 150 | 2.4 |
| 16 | `systemd-units-timers-and-targets` | working | 160 | 2.5 |
| 17 | `containers-with-podman-and-docker` | working | 170 | 2.6 |
| 18 | `authentication-authorization-and-accounting` | deep | 180 | 3.1 |
| 19 | `logging-journald-rsyslog-and-auditd` | working | 190 | 3.1, 5.1 |
| 20 | `sudo-and-privilege-escalation` | working | 200 | 3.3 |
| 21 | `ssh-and-secure-remote-access` | working | 210 | 3.3 |
| 22 | `selinux` | deep | 220 | 3.3, 5.4 |
| 23 | `firewalls-firewalld-ufw-and-nftables` | working | 230 | 3.2 |
| 24 | `account-hardening-and-password-policy` | working | 240 | 3.4 |
| 25 | `cryptography-tls-and-disk-encryption` | deep | 250 | 3.5 |
| 26 | `compliance-auditing-and-file-integrity` | deep | 260 | 3.6 |
| 27 | `bash-scripting` | working | 270 | 4.2 |
| 28 | `python-for-linux-administration` | working | 280 | 4.3 |
| 29 | `git-for-linux-administration` | working | 290 | 4.4 |
| 30 | `ansible-puppet-and-infrastructure-as-code` | deep | 300 | 4.1 |
| 31 | `orchestration-kubernetes-swarm-and-compose` | deep | 310 | 4.1 |
| 32 | `ai-assisted-administration` | working | 320 | 4.5 |
| 33 | `troubleshooting-methodology-and-monitoring` | working | 330 | 5.1 |
| 34 | `boot-and-kernel-failure-recovery` | deep | 340 | 5.2 |
| 35 | `storage-and-filesystem-troubleshooting` | deep | 350 | 5.2 |
| 36 | `os-and-process-failures` | deep | 360 | 5.2 |
| 37 | `network-troubleshooting` | deep | 370 | 5.3 |
| 38 | `security-troubleshooting` | deep | 380 | 5.4 |
| 39 | `cpu-and-memory-performance` | deep | 390 | 5.5 |
| 40 | `io-and-network-performance` | deep | 400 | 5.5 |

Reading order is deliberate rather than domain order: the shell (04) comes early
because every later topic uses it, and permissions (11) sits with files rather
than with Security because that is where a reader meets it first. Domain order
is recovered by the coverage page, not by the sidebar.

## The beginner-first recut

> **Superseded by the full sweep, 2026-08-07.** This section estimated 44 topics
> before every objective had been worked through individually. The actual sweep
> came out at **77**, and lives in
> [linux-plus-topic-plan.md](linux-plus-topic-plan.md), which is now the
> authoritative plan. The reasoning below still holds; the number was low
> because it assumed one topic per objective outside the foundations block, and
> most objectives need two or three when taught from zero.


Writing for somebody who has never opened a terminal changes the plan in two
ways, and neither is cosmetic.

**A foundations block has to come first.** The old plan opened with the
filesystem hierarchy, which assumes the reader can already run a command, read
its output, and move between directories. None of that is safe to assume now.
Most of this material does map to exam objectives, mainly 1.5 and 2.1, but the
objectives are written for someone with twelve months of experience and are not
in teaching order. So the same content gets split smaller and moved earlier.

**Sequencing beats objective order everywhere.** Permissions is objective 3.3,
in the Security domain, but a beginner meets `rwxr-xr-x` the first time they run
`ls -l`, which is on day one. It gets taught where it is first encountered and
revisited in Security, not deferred.

### The foundations block

Eight topics that exist because the reader is starting from zero. Numbered here
in reading order; the numbering that ships is generated.

| # | Slug | Objectives | Why a beginner needs it before anything else |
| --- | --- | --- | --- |
| 00 | `start-here` | none | Orientation. Already written. |
| 01 | `the-terminal-and-how-a-command-works` | 1.5 | What a shell is, what a prompt is, and how a command is built from a name, options, and arguments. The single most common early confusion is that options are inconsistent: `-l`, `--long`, and commands that take neither. Say it out loud once. |
| 02 | `getting-help-on-any-command` | 1.5 | `man`, `--help`, and `info`. Taught early because it converts every later topic into something the reader can extend on their own. |
| 03 | `moving-around-the-filesystem` | 1.5, 2.1 | `pwd`, `cd`, `ls`, and absolute versus relative paths. Nothing else can be demonstrated until this is solid. |
| 04 | `linux-fundamentals-and-the-fhs` | 1.1 | Where things live and why. Already written, already recut for this audience. |
| 05 | `reading-and-editing-files` | 1.5, 2.1 | `cat`, `less`, `head`, `tail`, and enough `nano` and `vi` to change a config file and get out again. |
| 06 | `users-root-and-sudo` | 2.2, 3.3 | Who you are, why you are not root, and what `sudo` actually does. Needed before any topic whose commands require privilege, which is most of them. |
| 07 | `reading-and-setting-permissions` | 2.1, 3.3 | The mode string, octal, and ownership. Moved here from the Security domain because it is met on day one. |
| 08 | `installing-software` | 2.4 | Package managers across both families. Beginners want to install something almost immediately, and it is the cleanest first demonstration of the RPM and dpkg split. |

That is eight topics before the track reaches what the old plan called topic 01.

### What this does to the count

| Block | Topics |
| --- | --- |
| Foundations | 9, including orientation |
| Domain 1.0 System Management, remaining | 7 |
| Domain 2.0 Services and User Management, remaining | 6 |
| Domain 3.0 Security, remaining | 8 |
| Domain 4.0 Automation, Orchestration, Scripting | 6 |
| Domain 5.0 Troubleshooting | 8 |
| **Total** | **44** |

Forty-four rather than forty, and that is a floor rather than an estimate. Some
of the later topics will split once written from zero, because explaining LVM to
somebody who has just learned what a directory is takes more room than
explaining it to an administrator. Expect the high forties.

The objective coverage does not change: all 29 are still covered, several now by
more topics than before. The [coverage report](/learn/linux-plus/coverage) is
generated, so it will show the truth as topics land rather than needing this
table kept current.

### What does not change

- Troubleshooting still gets eight topics, proportional to its 22 percent.
- Kubernetes still gets exactly as much as objective 4.1 needs and no more.
- The four acronym-only findings below still land where they landed.

### Where the acronym-only findings land

The four acronyms that expand scope beyond the objective bullets get explicit
homes, so they do not fall through the gap between "not in the objectives" and
"CompTIA says it appears on the exam":

| Finding | Topic | What gets added |
| --- | --- | --- |
| CUPS | 15 `common-network-services` | A printing section. Nothing in the objectives text mentions printing, so without this it would have been omitted entirely. |
| EPEL | 14 `package-management-across-rpm-and-dpkg` | The worked third-party repository example on the RHEL side, rather than a generic one. |
| ACME | 25 `cryptography-tls-and-disk-encryption` | Certificate issuance and renewal, not only trust stores. Implies `certbot` and the renewal timer. |
| GDPR | 26 `compliance-auditing-and-file-integrity` | The one named regulation in the document. Sits alongside OpenSCAP and CIS as the "why" behind the tooling. |

### Reverse check: every objective is covered

| Objective | Topics |
| --- | --- |
| 1.1 | 01, 02 |
| 1.2 | 02, 03 |
| 1.3 | 05, 06 |
| 1.4 | 07 |
| 1.5 | 04 |
| 1.6 | 08 |
| 1.7 | 09 |
| 2.1 | 10, 11 |
| 2.2 | 12 |
| 2.3 | 13 |
| 2.4 | 14, 15 |
| 2.5 | 16 |
| 2.6 | 17 |
| 3.1 | 18, 19 |
| 3.2 | 23 |
| 3.3 | 11, 20, 21, 22 |
| 3.4 | 24 |
| 3.5 | 25 |
| 3.6 | 26 |
| 4.1 | 30, 31 |
| 4.2 | 27 |
| 4.3 | 28 |
| 4.4 | 29 |
| 4.5 | 32 |
| 5.1 | 19, 33 |
| 5.2 | 34, 35, 36 |
| 5.3 | 37 |
| 5.4 | 22, 38 |
| 5.5 | 39, 40 |

No gaps. This table is what the `/learn/linux-plus/coverage` page should be
generated from at build time, derived from frontmatter rather than restated by
hand.

### Diagrams worth building

Per your requirement that structural concepts get a diagram, and SVG only:

| Topic | Diagram |
| --- | --- |
| 01 | FHS tree with the purpose of each top-level directory |
| 02 | Firmware to systemd boot sequence, UEFI and BIOS paths |
| 05 | Block device to partition to filesystem to mount point stack |
| 06 | LVM three-layer stack (PV, VG, LV) with a resize walkthrough |
| 11 | Permission bit layout including setuid, setgid, sticky |
| 16 | systemd dependency graph for a target |
| 17 | Container image layers and the copy-on-write writable layer |
| 22 | SELinux subject-object-context decision path |
| 23 | Packet path through Netfilter hooks with firewalld/ufw sitting above nftables |
| 37 | Diagnostic ladder from link to route to DNS to service |
| 39 | Memory hierarchy showing page cache, swap, and the OOM killer's decision point |
| 40 | USE method laid out against CPU, memory, I/O, and network |

## Source table

| Source | Publisher | Tier | URL | Accessed |
| --- | --- | --- | --- | --- |
| **CompTIA Linux+ Certification Exam Objectives, XK0-006 V8** (released, 2024, print code 11409-Aug2024) | CompTIA | 1 | Gated download from the V8 page; supplied by Ryan 2026-08-07 | 2026-08-07 |
| CompTIA Linux+ certification page | CompTIA | 1 | https://www.comptia.org/en-us/certifications/linux/ | 2026-08-07 |
| CompTIA Linux+ (V8) exam details and objectives summary | CompTIA | 1 | https://www.comptia.org/en-us/certifications/linux/v8/ | 2026-08-07 |
| DRAFT CompTIA Linux+ XK0-006 Certification Exam Objectives, version 1.2, Aug 2024 | CompTIA | 1 (draft) | https://comptiacdn.azureedge.net/webcontent/docs/default-source/exam-objectives/under-development/draft-linux-xk0-006-exam-objectives-(1-0).pdf | 2026-08-07 |
| Certification Renewal Policy | CompTIA | 1 | https://www.comptia.org/en-us/resources/test-policies/continuing-education-policies/certification-renewal-policy/ | 2026-08-07 |
| Linux+ CEU requirement (50 CEUs) | CompTIA | 1 | https://www.comptia.org/continuing-education/renewothers/renewing-linux-multiple | 2026-08-07 |
| Schedule Exam (Pearson VUE and OnVUE) | CompTIA | 1 | https://www.comptia.org/en-us/resources/schedule-exam/ | 2026-08-07 |

Sources deliberately **not** used, despite appearing in every search: Scribd,
Course Hero, StudyLib, CliffsNotes, exam-vendor blogs, and "practice question"
sites. Several host copies of the objectives PDF. Using a scrape would have
reproduced exactly the problem this phase existed to fix, and several of those
sites are the kind CompTIA's own authorized-materials policy targets.

The retirement date for XK0-005 (January 13, 2026) rests on vendor blogs only.
It does not reach content, so I left it unconfirmed rather than citing a tier 3
source.

Upstream documentation for phase 2 content (kernel.org, systemd, SELinux,
firewalld, nftables, Ansible, Podman, Docker, Red Hat, Debian, Ubuntu, SUSE) has
not been catalogued yet. That belongs with the topics that cite it, since the
`sources` frontmatter array is per-topic.

## Repo drift found while verifying

You asked me to check the structure rather than trust it. Nearly everything held.
Four things did not:

1. **`CONTRIBUTING-learn.md` lists a build failure that does not exist.** The
   "What fails the build" table has a row for "A quiz bank sits in a directory
   that is not a track". There is no such check. `getQuizSets()` in
   [quiz.ts](blog/src/lib/quiz.ts:100) only validates the path *shape*
   (`quizzes/<track>/<set>.json`) and that the `track` field matches the
   directory. A bank in a directory with no content silently *creates* a track,
   because [learn.ts](blog/src/lib/learn.ts:180) derives track slugs from quiz
   sets as well as topics. That is deliberate and documented elsewhere in the
   same file, but the failure-table row is wrong. Worth fixing in phase 2 while
   I am editing that document anyway.

2. **The Security+ track has no content, only a quiz bank.** There is no
   `src/content/learn/security-plus/` directory. The track exists solely because
   `fundamentals.json` creates it. Your brief refers to "the Bicep and Security+
   tracks" as if both have notes. Only Bicep does, with exactly one topic.

3. **Databricks is in `TRACK_META` but has no content or bank**, so it does not
   appear on `/learn` at all. Harmless, but the config implies a track that does
   not exist.

4. **No `images/` directory exists under any track yet.** The pipeline is real
   and the route tests enforce it, but it has never actually run against a learn
   image. First raster image in the Linux+ track will be the first real exercise
   of `integrations/learn-images.mjs`. Since I plan SVG for all the diagrams,
   that may stay untested; worth knowing rather than assuming it is proven.

Everything else in your brief checked out exactly: Astro 7.1.6, `base: '/'`,
both sections under `src/pages`, `order` controls sequence with the `NN-` prefix
stripped from URLs, unique-order and slug-collision and prerequisite-resolution
failures all present in `learn.ts`, quiz schema and per-bank duplicate-id check
present in `quiz.ts`, Pagefind with track filtering, and the ASCII and
image-pipeline enforcement in `test/routes.test.mjs`.

One thing to note for phase 3: the existing duplicate-`id` check is **per bank**,
not per track. Your requirement for "duplicate question `id` across banks in the
same track" is genuinely new work, not a tightening of an existing check.

## Copyright constraint on the objectives document

The objectives PDF carries an explicit notice: copyright CompTIA, "Reproduction
or dissemination prohibited without the written consent of CompTIA, Inc."

That has two consequences worth deciding now:

1. **This research document summarizes rather than mirrors.** The tables above
   condense subject matter into tool and concept lists. They are not a
   reproduction of the objectives document and should not become one.

2. **Topic content must not quote objective text at length.** Citing "objective
   1.3" by number and title is fine and is normal practice. Pasting CompTIA's
   bulleted sub-lists into a public page is not. The `examObjectives` frontmatter
   field you specified stores numbers only, which is exactly right; the coverage
   page should render numbers and your own topic titles, not CompTIA's bullet
   text.

This also affects the practice-question rule you already wrote. Your instruction
to write every item from the objectives and documentation, never from an existing
bank, is consistent with CompTIA's authorized-materials policy, which the
objectives document restates and points at `examsecurity@comptia.org`.

## What I need from you

1. **A topic count decision.** 40 as proposed, or 33 if you take all seven
   merges. This sets the size of phases 2 and 3 more than anything else does,
   and it is the one decision I would rather not guess at.

2. **A ruling on AppArmor.** My recommendation is one paragraph in the SELinux
   topic explaining it is what Debian and SUSE use and that it is out of scope,
   and no topic of its own.

3. **A ruling on Kubernetes depth.** It is named in 4.1 with seven sub-bullets,
   which is more than a mention but far less than a Kubernetes track. I have it
   as one topic shared with Swarm and Compose. Given you already have a
   Kubernetes-shaped gap in the track list, you may want it broken out later as
   its own track, in which case the Linux+ topic should stay deliberately thin
   and link across.
