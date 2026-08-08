# CompTIA Linux+ track: the full topic plan

Every topic in the track, in reading order, with what each one has to teach and
what it depends on. Written for the audience decided on 2026-08-07: somebody who
has never opened a terminal, with experienced administrators served by `DEEPER`
panels rather than by the main flow.

**77 topics.** That is not a target, it is what covering 29 objectives from zero
takes. There is no cap; a topic that turns out to need splitting gets split.

Companions: [linux-plus-xk0-006-research.md](linux-plus-xk0-006-research.md) for
what is on the exam, [linux-plus-teaching-design.md](linux-plus-teaching-design.md)
for how a topic is written, and
[linux-plus-question-authoring-standard.md](linux-plus-question-authoring-standard.md)
for the practice questions.

- [How to read this plan](#how-to-read-this-plan)
- [Balance check](#balance-check)
- [Block A: Foundations](#block-a-foundations)
- [Block B: System Management](#block-b-system-management)
- [Block C: Services and User Management](#block-c-services-and-user-management)
- [Block D: Security](#block-d-security)
- [Block E: Automation, Orchestration, Scripting](#block-e-automation-orchestration-scripting)
- [Block F: Troubleshooting](#block-f-troubleshooting)
- [Objective coverage check](#objective-coverage-check)
- [Capture feasibility](#capture-feasibility)
- [Diagrams worth building](#diagrams-worth-building)
- [Suggested authoring order](#suggested-authoring-order)

## How to read this plan

Numbers are reading order, not filenames; `order` in frontmatter is numbered in
tens and the displayed numbering is generated. `00` is the orientation page and
sits outside the lesson count.

**Zero hook** is the concrete thing the topic opens with, per the
concrete-before-abstract rule. A beginner should be able to picture it before any
terminology arrives. If a topic has no plausible zero hook, it is scoped wrong.

**Deeper** is what goes behind the collapsible panel for experienced admins. If a
topic has nothing there, the main flow is probably still pitched too high.

Status: `written` means it exists and has been recut for this audience.

## Balance check

| Block | Topics | Share of objective-bearing topics | Exam weight |
| --- | --- | --- | --- |
| A. Foundations | 9 | - | - |
| B. System Management | 16 | 24% | 23% |
| C. Services and User Management | 12 | 18% | 20% |
| D. Security | 14 | 21% | 18% |
| E. Automation | 12 | 18% | 17% |
| F. Troubleshooting | 14 | 21% | 22% |
| **Total** | **77** | | |

Security runs three points heavy because objective 3.3 is the largest single
objective on the exam and spans four unrelated subjects. Everything else lands
within two points.

## Block A: Foundations

Nine topics that exist because the reader is starting from zero. Most of the
content maps to objectives 1.5 and 2.1, but those are written for someone with a
year of experience and are not in teaching order.

| # | Slug | Level | Obj | Zero hook | Must teach | Deeper |
| --- | --- | --- | --- | --- | --- | --- |
| 00 | `start-here` | intro | - | - | Orientation, exam facts, Linux history, how to use the track. **written** | - |
| 01 | `the-terminal-and-how-a-command-works` | intro | 1.5 | A window where you type instructions instead of clicking them | What a shell is; the prompt and what its parts mean; command = name + options + arguments; why options are inconsistent (`-l`, `--long`, and commands that take neither); case sensitivity; tab completion; Ctrl+C to get out | Login vs non-login shells; `bash` vs `sh` vs `dash`; why `$` and `#` differ |
| 02 | `getting-help-on-any-command` | intro | 1.5 | You have been told to use a command nobody explained | `--help`; `man` and how to navigate and quit it; man sections and why `man 5 passwd` differs from `man passwd`; `apropos`; `info`; reading a synopsis line | `/usr/share/doc`; `tldr`; why the synopsis brackets mean what they mean |
| 03 | `moving-around-the-filesystem` | intro | 1.5, 2.1 | You are somewhere. Where? | `pwd`, `cd`, `ls` and its useful flags; absolute vs relative paths; `.`, `..`, `~`, `-`; no drive letters; hidden files | `cd` with `CDPATH`; `pushd`/`popd`; why `ls` output differs when piped |
| 04 | `linux-fundamentals-and-the-fhs` | intro | 1.1 | A web server's three files behave differently | FHS, the two axes, usr-merge, distribution families, architectures, GUI stack, licensing. **written** | Static/shareable in the standard's own words; `/run` as tmpfs |
| 05 | `reading-and-editing-files` | intro | 1.5, 2.1 | You need to change one line in a config file | `cat`, `less`, `head`, `tail`, `tail -f`; `nano` end to end; enough `vi` to open, edit, save, quit, and escape; `touch`, `cp`, `mv`, `rm` and that `rm` does not ask | `vi` modes properly; `less` search; why `rm -i` is not a safety net |
| 06 | `users-root-and-sudo` | intro | 2.2, 3.3 | Why did it say permission denied when you are the only person using this machine? | What a user account is; root and why you are not it; `whoami`, `id`; `sudo` basics and what it actually does; `su -` vs `sudo -i` | The wheel/sudo group; `sudo` logging; why `sudo su` is a smell |
| 07 | `reading-and-setting-permissions` | working | 2.1, 3.3 | `-rw-r--r--` appears the first time you run `ls -l` | Reading the mode string; user/group/other; `chmod` symbolic and octal; `chown`, `chgrp`; umask; execute on a directory means traverse | setuid, setgid, sticky bit; ACLs pointer forward |
| 08 | `installing-software` | intro | 2.4 | You want to install something and there is no download button | Package managers by family (`dnf`, `apt`, `zypper`); search, install, remove, update; what a repository is; why you should not download binaries from the web | Language managers (`pip`, `npm`, `cargo`) and why they conflict with the system |

## Block B: System Management

Objectives 1.1 through 1.7. Sixteen topics.

| # | Slug | Level | Obj | Zero hook | Must teach | Deeper |
| --- | --- | --- | --- | --- | --- | --- |
| 09 | `how-linux-boots` | working | 1.1 | You press the power button. What happens in the four seconds before the login prompt? | Firmware (BIOS/UEFI) to bootloader to kernel to initramfs to systemd to target; GRUB's role and config; kernel parameters; what initramfs is for | Secure Boot; `dracut` internals; UEFI boot entries with `efibootmgr` |
| 10 | `the-kernel-and-modules` | working | 1.2 | You plug in a device and it just works. Something loaded a driver | What a kernel module is; `lsmod`, `modinfo`, `modprobe`, `rmmod`, `depmod`; `/etc/modprobe.d`; kernel version with `uname -r` | Module signing; blacklisting; `initramfs` rebuild after module changes |
| 11 | `hardware-and-device-discovery` | working | 1.2 | You inherit a server and nobody knows what is in it | `lscpu`, `lsmem`, `lspci`, `lsusb`, `lsblk`, `lshw`, `dmidecode`, `dmesg`; `/dev` and device types; `lm_sensors`; GPU and `nvtop` | `/sys` as the modern interface; udev rules; `ipmitool` for out-of-band |
| 12 | `disks-partitions-and-filesystems` | working | 1.3 | A new disk is attached and the system ignores it | Disk vs partition vs filesystem as three separate steps; `lsblk`, `blkid`; MBR vs GPT; `fdisk`, `gdisk`, `parted`; `mkfs`; ext4, xfs, btrfs, tmpfs and when each | Filesystem internals; `xfs` cannot shrink; `blkid` vs `lsblk -f` |
| 13 | `mounting-and-fstab` | working | 1.3 | The disk is formatted and still not usable | Mounting as attaching a filesystem to a directory; `mount`, `umount`, `findmnt`; `/etc/fstab` field by field; mounting by UUID and why; mount options (`noexec`, `nosuid`, `nodev`, `noatime`, `ro`); `autofs`; NFS and SMB | `/proc/mounts` vs `/etc/mtab`; bind mounts; systemd mount units |
| 14 | `lvm` | deep | 1.3 | The disk is full and you cannot add space without downtime | Why LVM exists; PV, VG, LV as three layers; `pvcreate`/`vgcreate`/`lvcreate`; extending a volume and then the filesystem; `lvs`/`vgs`/`pvs`; the two-step resize people forget | Snapshots; thin provisioning; `pvmove`; the LVM devices file |
| 15 | `raid` | deep | 1.3 | One disk fails and the server keeps running. How? | RAID levels 0/1/5/6/10 and their trade-offs; `mdadm` create, inspect, fail, replace; `/proc/mdstat`; hardware vs software RAID; RAID is not backup | Rebuild windows and URE risk; write-intent bitmaps; RAID on top of LVM vs under |
| 16 | `network-basics-addresses-and-routes` | intro | 1.4 | Two machines on the same desk cannot talk to each other | IP address, subnet mask, CIDR, gateway, DNS as four separate things; IPv4 vs IPv6; what a NIC is; TCP vs UDP; ports; localhost | ICMP and what `ping` really tests; MTU; link negotiation |
| 17 | `configuring-networking` | working | 1.4 | The address is right and it still does not work after reboot | `ip addr`, `ip link`, `ip route` for inspection; NetworkManager and `nmcli` on the RHEL family; netplan on Ubuntu; Debian without netplan; static vs DHCP; making it persist | `systemd-networkd`; bonding and teaming; MAC spoofing |
| 18 | `name-resolution-and-dns` | working | 1.4 | `ping google.com` fails but `ping 8.8.8.8` works | What DNS does; `/etc/hosts`, `/etc/resolv.conf`, `/etc/nsswitch.conf` and their order; `dig`, `nslookup`, `host`; `systemd-resolved`; FQDN vs short name; TTL | Search domains; split-horizon; `resolvectl` and the stub resolver |
| 19 | `shell-redirection-and-pipes` | working | 1.5 | A command printed 4,000 lines and you needed six of them | stdin/stdout/stderr as three channels; `>`, `>>`, `<`, `2>`, `&>`; pipes; `tee`; here-docs and here-strings; exit codes and `$?` | File descriptors properly; `set -o pipefail`; process substitution |
| 20 | `text-processing` | working | 1.5 | A log file has one line you need out of a million | `grep` and basic regex; `cut`, `sort`, `uniq`, `wc`, `tr`, `head`, `tail`; `sed` for substitution; `awk` for fields; `xargs`; composing them | Extended vs basic regex; `awk` as a language; `sed` in place and why it is risky |
| 21 | `the-shell-environment` | working | 1.5 | A command works for you and not for the service account | Environment variables; `PATH` and how a command is found; `export`; `.bashrc` vs `.bash_profile` vs `/etc/profile`; aliases; `PS1`; `which`, `type`, `command -v` | Login vs interactive vs non-interactive; `env -i`; why cron has a different PATH |
| 22 | `archiving-and-compression` | working | 1.6 | You need to send a directory to someone as one file | `tar` create/list/extract and why the flags look the way they do; `gzip`, `bzip2`, `xz`, `zip`, 7-Zip; compression vs archiving as different jobs; `zcat`, `zgrep`, `zless` | Compression ratios and CPU cost; `tar` with `--exclude`; preserving ownership and SELinux context |
| 23 | `backup-and-restore` | working | 1.6 | The restore is the part nobody tests | Full vs incremental vs differential; `rsync` and its flags; `dd` and `ddrescue`; verifying a restore; 3-2-1 as a framing; what a backup is not (RAID, snapshots) | `rsync --link-dest`; bandwidth limiting; consistency for databases |
| 24 | `virtualization` | working | 1.7 | One physical server, six machines on it | Hypervisor types; KVM and QEMU; VM vs bare metal vs container; disk images and formats; `virsh`, `libvirt`, `virt-manager`; VM network types (NAT, bridged, host-only, routed); snapshots, cloning, templates | Paravirtualisation and VirtIO; nested virtualisation; live migration |

## Block C: Services and User Management

Objectives 2.1 through 2.6. Twelve topics.

| # | Slug | Level | Obj | Zero hook | Must teach | Deeper |
| --- | --- | --- | --- | --- | --- | --- |
| 25 | `links-hard-and-symbolic` | working | 2.1 | Two names, one file. Delete one and the other still works | Inodes as the thing a name points to; hard links vs symlinks; `ln`, `ln -s`; broken symlinks; why `/bin` is a symlink | Link counts; symlinks across filesystems; `realpath` |
| 26 | `finding-files` | working | 2.1 | Something is on this machine and you do not know where | `find` by name, type, size, time, permission; `-exec` and `-delete`; `locate` and why it is stale; `which`, `whereis`; `stat`; `file` | `find -printf`; `-prune`; combining with `xargs -0` |
| 27 | `managing-users-and-groups` | working | 2.2 | A new person starts on Monday | `useradd`/`adduser`, `usermod`, `userdel`; `groupadd`, `groupmod`, `gpasswd`; primary vs supplementary groups; `passwd`; `chage`; `/etc/skel`; UID and GID ranges | System vs service vs human accounts; `getent`; why group changes need a new session |
| 28 | `account-files-and-attributes` | working | 2.2 | Where is any of this actually stored? | `/etc/passwd`, `/etc/shadow`, `/etc/group`, `/etc/gshadow` field by field; UID, GID, EUID, EGID; `id`, `groups`, `last`, `lastlog`, `w`, `who`; locked vs disabled accounts | Shadow hashing formats; `pwck`/`grpck`; `nologin` vs `false` |
| 29 | `processes-and-signals` | working | 2.3 | An application is stuck and there is no window to close | What a process is; PID and PPID; `ps`, `top`, `htop`, `pstree`; process states including zombie; signals 1/9/15 and the difference; `kill`, `killall`, `pkill`; `nice` and `renice` | `/proc/<pid>`; `strace`; orphans and reparenting; OOM killer |
| 30 | `job-control-and-scheduling` | working | 2.3 | A job needs to run at 2am and you would like to be asleep | Foreground/background, `&`, `jobs`, `fg`, `bg`, Ctrl+Z; `nohup`; `cron` syntax field by field; `crontab -e`; `at`; `anacron`; systemd timers as the modern alternative | Cron environment differences; `@reboot`; timer accuracy and randomised delay |
| 31 | `packages-repositories-and-signing` | working | 2.4 | The package you need is not in the default repository | Repository configuration on both families; adding a third-party repo; EPEL; GPG signature verification; `rpm`/`dpkg` low-level queries; pinning and exclusions; `update-alternatives` | Building from source; `rpm -V`; repository priorities; why `dpkg -S` wants canonical paths |
| 32 | `common-network-services` | working | 2.4 | The machine is fine and the website still does not load | Installing and starting DNS, NTP/PTP, DHCP, HTTP (httpd and nginx), SMTP, IMAP4, CUPS printing; what each is for; config file locations by family; PHP in a web stack | Chrony vs ntpd; virtual hosts; why time drift breaks authentication |
| 33 | `systemd-units-and-services` | working | 2.5 | The service is installed and does not start on boot | What systemd is and what it replaced; unit files and where they live; `systemctl start/stop/restart/reload/enable/disable/status`; enable vs start; `daemon-reload`; reading `systemctl status` output | Drop-ins with `systemctl edit`; unit ordering and dependencies; `mask` vs `disable` |
| 34 | `systemd-targets-timers-and-journal` | working | 2.5 | You want the machine to boot without a graphical desktop | Targets and what replaced runlevels; `systemctl isolate`, `set-default`; timers as cron replacement; mount units; `journalctl` basics; `hostnamectl`, `timedatectl`, `resolvectl`, `sysctl`; `systemd-analyze` and `blame` | Persistent journal; unit file sections properly; socket activation |
| 35 | `containers-the-basics` | working | 2.6 | Ship the application and its dependencies as one thing | What a container is and is not; images vs containers; `podman`/`docker` run, ps, logs, exec, stop, rm; runtimes (runC, containerd); why containers are a Linux feature | Namespaces and cgroups; rootless containers; container vs VM boundaries |
| 36 | `container-images-volumes-and-networks` | working | 2.6 | The container restarts and the data is gone | Building an image; Dockerfile with FROM, USER, CMD, ENTRYPOINT; layers and caching; tags; pruning; volumes and bind mounts; SELinux context on volumes; container networks (bridge, host, macvlan, ipvlan, overlay, none); port mapping; privileged vs unprivileged | Multi-stage builds; image provenance; rootless networking |

## Block D: Security

Objectives 3.1 through 3.6. Fourteen topics.

| # | Slug | Level | Obj | Zero hook | Must teach | Deeper |
| --- | --- | --- | --- | --- | --- | --- |
| 37 | `authentication-and-pam` | deep | 3.1 | Who decides whether your password is good enough? | Authentication vs authorization vs accounting; how login works; PAM as a stack; `/etc/pam.d`; module types and control flags; polkit briefly | Writing a PAM stack safely; `pam_faillock`; the order trap |
| 38 | `central-identity` | deep | 3.1 | Two hundred servers and one password change | Why central identity exists; LDAP concepts; Kerberos concepts and tickets; SSSD and Winbind; `realm join`; Samba as a file service | Kerberos clock skew; SSSD caching; keytabs |
| 39 | `logging-and-auditing` | working | 3.1, 5.1 | Something happened at 3am and nobody saw it | `journalctl` in depth; `rsyslog` and `/var/log`; `logrotate`; facilities and severities; `auditd` and `audit.rules`; what accounting means | Structured journal fields; remote logging; audit rule performance |
| 40 | `firewall-concepts-and-netfilter` | working | 3.2 | A port is open and you did not open it | What a firewall does; stateful vs stateless; the netfilter hooks packets pass through; NAT, PAT, SNAT, DNAT; IP forwarding; ports vs services | Conntrack; the path of a forwarded packet; `net.ipv4.ip_forward` |
| 41 | `firewalld-ufw-and-nftables` | working | 3.2 | Three tools, one kernel feature | `firewall-cmd` with zones, services, ports, rich rules, runtime vs permanent; `ufw` on Ubuntu; `nftables` directly on Debian; `iptables` as legacy; `ipset` | nftables syntax properly; migrating iptables rules; ordering |
| 42 | `sudo-in-depth` | working | 3.3 | Give someone exactly one privileged command and nothing else | `/etc/sudoers` syntax; `visudo` and why; `sudoers.d`; NOPASSWD and NOEXEC implications; command aliases; the wheel/sudo group; logging | Escaping to a shell from a permitted command; `sudo -l`; timestamp timeout |
| 43 | `ssh-and-secure-remote-access` | working | 3.3 | You need a shell on a machine three thousand miles away | SSH client and server; key vs password authentication; generating and installing keys; `authorized_keys`; `sshd_config` hardening (PermitRootLogin, AllowUsers, AllowGroups, X forwarding); `ssh-agent`; SFTP and chroot; `fail2ban`; why Telnet and FTP are out | Tunnels and port forwarding; certificate authentication; `Match` blocks |
| 44 | `selinux` | deep | 3.3, 5.4 | The service is running, the permissions are right, and it still cannot read the file | What mandatory access control adds; contexts and labels; enforcing/permissive/disabled; `getenforce`, `setenforce`, `ls -Z`; booleans with `getsebool`/`setsebool`; `restorecon`, `chcon`, `semanage`; reading a denial with `audit2allow` and `sealert`; AppArmor named once as out of scope | Policy types; custom modules; why relabelling takes so long |
| 45 | `hardening-a-system` | working | 3.3 | Which of these forty running services do you actually need? | Removing unnecessary SUID; file attributes with `chattr`/`lsattr`; disabling unused filesystems and services; secure boot and UEFI; security banners (`/etc/issue`, `issue.net`, `motd`); avoiding insecure protocols | CIS benchmark mapping; immutable configs as a control; kernel hardening sysctls |
| 46 | `password-policy-and-mfa` | working | 3.4 | A password policy nobody can follow gets written on a sticky note | Complexity, length, expiration, reuse, history and where each is configured; `chage`; MFA and TOTP; breach-list checking; restricted shells (`nologin`, `rbash`); avoiding running as root | `pam_pwquality` tuning; modern guidance vs habit; `pam_faillock` |
| 47 | `cryptography-basics` | working | 3.5 | How does a password get checked without being stored? | Hashing vs encryption; SHA-256; HMAC; symmetric vs asymmetric; public and private keys; what a signature proves; removal of weak algorithms | Salting and work factors; why MD5 and SHA-1 are out; algorithm agility |
| 48 | `tls-certificates-and-acme` | deep | 3.5 | The browser says the site is not secure | TLS versions; what a certificate contains; CA and the chain of trust; trusted root stores; self-signed and why to avoid; CSR to issuance; ACME and automated renewal; OpenSSL and LibreSSL; inspecting a certificate | Cipher suite negotiation; OCSP; certificate pinning |
| 49 | `encrypting-data-at-rest` | working | 3.5 | The laptop is stolen. Now what? | Full-disk encryption with LUKS2 and Argon2; unlocking at boot; file encryption with GPG; WireGuard for data in transit; secure deletion (`shred`, `badblocks -w`, `dd if=/dev/urandom`), and why it differs on SSDs | Key slots and rotation; cryptographic erase; TPM-backed unlock |
| 50 | `compliance-auditing-and-integrity` | deep | 3.6 | How do you prove the control is working, not just present? | Why compliance exists; GDPR as the named example; CVE and CVSS; backporting patches; vulnerability scanning; OpenSCAP; CIS Benchmarks; file integrity with AIDE and rkhunter; signed package verification; software supply chain | Mapping findings to frameworks; scan cadence; false positives from backporting |

## Block E: Automation, Orchestration, Scripting

Objectives 4.1 through 4.5. Twelve topics.

| # | Slug | Level | Obj | Zero hook | Must teach | Deeper |
| --- | --- | --- | --- | --- | --- | --- |
| 51 | `your-first-shell-script` | intro | 4.2 | You have typed the same three commands every morning for a month | What a script is; the shebang; making it executable; running it; variables and quoting; arguments and `$1`; `echo` and `read`; exit codes | `set -euo pipefail`; why quoting matters more than it looks |
| 52 | `script-control-flow` | working | 4.2 | The script should only run the backup if the disk is there | `if`/`then`/`else`/`elif`; `test` and `[ ]`; numeric vs string comparison operators; `-f`, `-d`, `-z`, `-n`; `case`; `for`, `while`, `until`; `break` and `continue` | `[[ ]]` vs `[ ]`; arithmetic contexts; regex matching |
| 53 | `scripts-that-do-real-work` | working | 4.2 | The script works until it meets a filename with a space in it | Functions; parameter expansion; command substitution; subshells; IFS and OFS; argument parsing; error handling and traps; logging from a script | `getopts`; signal handling; idempotence |
| 54 | `python-for-sysadmins` | working | 4.3 | Bash stopped being the right tool three loops ago | Why Python instead of bash; running a script; indentation; data types and structures (bool, int, float, string, list, dictionary); modules and packages; virtual environments; installing dependencies; PEP 8 | `argparse`; `subprocess` safely; packaging |
| 55 | `git-the-basics` | intro | 4.4 | You changed a config, it broke, and the old version is gone | Why version control; `init`, `clone`, `config`; the three states; `add`, `commit`, `status`, `diff`, `log`; `.gitignore`; writing a message | The object model; `reflog` as a safety net |
| 56 | `git-branching-and-collaboration` | working | 4.4 | Two people, one file, at the same time | `branch`, `checkout`/`switch`, `merge`; conflicts and resolving them; `fetch`, `pull`, `push`; `tag`; `stash`; `reset` vs `revert`; `rebase` and `squash` | Rebase vs merge trade-offs; force-push safety; hooks |
| 57 | `infrastructure-as-code-concepts` | working | 4.1 | Fifty servers configured by hand are fifty different servers | Declarative vs imperative; idempotence; drift; state; unattended deployment with Kickstart and cloud-init; where IaC fits | Immutable infrastructure; state locking; secret management |
| 58 | `ansible` | deep | 4.1 | Run one command, change fifty machines | Agentless and why it matters; inventory; ad hoc commands; playbooks; modules; tasks and handlers; variables; facts; collections; idempotence in practice | Roles; Jinja templating; check mode and diff |
| 59 | `puppet-and-opentofu` | working | 4.1 | Two other answers to the same problem | Puppet: agent and agentless, manifests, classes, modules, facts, certificates. OpenTofu: providers, resources, state, plan and apply, API-driven provisioning. When each fits | Puppet catalog compilation; OpenTofu state backends and drift |
| 60 | `cicd-and-gitops` | working | 4.1 | The deploy happens because you merged, not because you remembered | Pipelines; stages; shift-left testing; DevSecOps; GitOps as the repository being the source of truth; version control as the trigger | Pipeline security; artefact signing; environment promotion |
| 61 | `orchestration` | deep | 4.1 | One container is easy. Forty that must find each other is not | Compose files with `up`/`down`/`logs`; Docker Swarm (service, nodes, tasks, networks, scale); Kubernetes vocabulary only: Pods, Deployments, Services, Volumes, ConfigMaps, Secrets, variables. **Scoped to objective 4.1 and no further** | Where a dedicated Kubernetes track would pick up |
| 62 | `ai-assisted-administration` | working | 4.5 | The generated command looked right and deleted the wrong directory | Sensible use cases (code, regex, IaC, docs, review, optimisation, linting); never paste without review; verify output; data governance and what leaves your network; local vs public models; corporate policy; prompt engineering basics | Prompt injection in tooling; review checklists; audit trails |

## Block F: Troubleshooting

Objectives 5.1 through 5.5. Fourteen topics, matching the 22 percent weight.

| # | Slug | Level | Obj | Zero hook | Must teach | Deeper |
| --- | --- | --- | --- | --- | --- | --- |
| 63 | `how-to-troubleshoot` | working | 5.2 | Everything is broken and you have to start somewhere | Symptom to hypothesis to discriminating test; changing one thing at a time; what changed recently; reading an error message properly; when to stop and escalate; writing down what you did | Forward vs backward reasoning; why experts skip steps you should not yet |
| 64 | `monitoring-concepts` | working | 5.1 | Nobody noticed until a customer called | Why monitor; SLA, SLI, SLO; metrics vs logs vs events; thresholds, alerts, notifications; health checks; agent vs agentless; SNMP with traps and MIBs; webhooks; log aggregation | Alert fatigue; cardinality; golden signals |
| 65 | `reading-logs-to-find-a-cause` | working | 5.1 | The answer is in a file you have never opened | `journalctl` filters by unit, time, priority, boot; `/var/log` layout by family; correlating timestamps across sources; what a stack trace is; grep patterns that work on logs | Structured fields; log-based alerting; time zone traps |
| 66 | `boot-failures-and-recovery` | deep | 5.2 | The machine powers on and never reaches a login prompt | Where boot can fail against the sequence from topic 09; GRUB misconfiguration and editing at boot; rescue and emergency targets; single user; kernel panic; missing or disabled drivers; recovering from a broken `/etc/fstab`; chroot from live media | Rebuilding initramfs; GRUB reinstall; UEFI entry recovery |
| 67 | `filesystem-and-mount-failures` | deep | 5.2 | It will not mount, and the error names a filesystem type you did not choose | `mount` errors decoded; wrong fs type and bad superblock; `fsck` and when it is unsafe; `xfs_repair`; read-only remount; corrupt filesystems; quota issues | Journal replay; superblock backups; ordering in fstab |
| 68 | `disk-space-and-inode-problems` | working | 5.2 | The disk says it is full and `du` disagrees with `df` | `df` vs `du` and why they differ; deleted-but-open files with `lsof`; inode exhaustion; finding large and numerous files; partition not writable; log growth | Sparse files; reserved blocks; `du --apparent-size` |
| 69 | `process-and-service-failures` | working | 5.2 | The service says active and the application is down | Reading `systemctl status` and a failed unit; unit failures; unresponsive processes; killed processes and why; segmentation faults; PATH misconfiguration; dependency failures; package dependency problems | Core dumps; `systemd-analyze` for slow boot; restart loops and backoff |
| 70 | `hardware-and-kernel-issues` | deep | 5.2 | The logs mention a device you have never heard of | Reading `dmesg` for hardware errors; device failure signs; SMART; missing or disabled drivers; kernel corruption; memory errors; data corruption; when to suspect hardware over software | Machine check exceptions; firmware updates; ECC |
| 71 | `network-connectivity-troubleshooting` | deep | 5.3 | It worked yesterday and nothing changed | The diagnostic ladder: link, address, route, gateway, DNS, service; `ip`, `ping`, `traceroute`/`tracepath`, `mtr`, `ss`, `nc`, `nmap`, `tcpdump`, `ethtool`; link down; IP conflicts; MTU mismatch; misconfigured firewalls as a cause | Packet capture reading; bonding failures; dual-stack surprises |
| 72 | `dns-and-routing-problems` | deep | 5.3 | Half the names resolve and half do not | DNS failure modes and where each shows up; resolution order traps; stale caches and TTL; routing and gateway issues; asymmetric routing; server unreachable vs port closed; DHCP failures | Split-horizon; `resolvectl` state; policy routing |
| 73 | `permission-and-access-troubleshooting` | deep | 5.4 | A world-readable file refuses to open | Path traversal, ACL masks, immutable attributes, stale group membership. **written**, needs recut for the beginner audience | Path resolution order in the kernel |
| 74 | `security-and-service-access-problems` | deep | 5.4 | Permissions are right, SELinux is enforcing, and it still fails | SELinux denials in practice; certificate expiry and chain errors; obsolete protocols and cipher negotiation failures; misconfigured repositories; exposed or misconfigured services; unpatched systems; account access failures | Correlating audit logs with denials; cipher negotiation traces |
| 75 | `cpu-and-memory-performance` | deep | 5.5 | Everything is slow and the CPU graph looks fine | Load average and what it actually means; `top`, `htop`, `mpstat`, `pidstat`, `vmstat`; run queue and context switching; memory vs cache vs buffers; swapping; OOM killer; memory leaks; high CPU vs high load | The USE method; NUMA; pressure stall information |
| 76 | `io-and-network-performance` | deep | 5.5 | The application is slow and it is not the application | I/O wait; `iostat`, `iotop`, `fio`; disk latency vs throughput; slow remote storage; blocked processes; network latency, jitter, packet drops, low throughput; random disconnects and timeouts; baselines and why exceeding one matters | Queue depth; `iperf3` methodology; buffer bloat |

## Objective coverage check

Every objective, and the topics that carry it. This is the table the generated
[coverage report](/learn/linux-plus/coverage) will reproduce from frontmatter
once the topics exist.

| Obj | Topics |
| --- | --- |
| 1.1 | 04, 09 |
| 1.2 | 10, 11 |
| 1.3 | 12, 13, 14, 15 |
| 1.4 | 16, 17, 18 |
| 1.5 | 01, 02, 03, 05, 19, 20, 21 |
| 1.6 | 22, 23 |
| 1.7 | 24 |
| 2.1 | 03, 05, 07, 25, 26 |
| 2.2 | 06, 27, 28 |
| 2.3 | 29, 30 |
| 2.4 | 08, 31, 32 |
| 2.5 | 33, 34 |
| 2.6 | 35, 36 |
| 3.1 | 37, 38, 39 |
| 3.2 | 40, 41 |
| 3.3 | 06, 07, 42, 43, 44, 45 |
| 3.4 | 46 |
| 3.5 | 47, 48, 49 |
| 3.6 | 50 |
| 4.1 | 57, 58, 59, 60, 61 |
| 4.2 | 51, 52, 53 |
| 4.3 | 54 |
| 4.4 | 55, 56 |
| 4.5 | 62 |
| 5.1 | 39, 64, 65 |
| 5.2 | 63, 66, 67, 68, 69, 70 |
| 5.3 | 71, 72 |
| 5.4 | 73, 74 |
| 5.5 | 75, 76 |

All 29 covered. No objective sits on a single topic except where the objective is
genuinely one subject (1.7, 3.4, 3.6, 4.3, 4.5).

## Capture feasibility

Which topics can use real captured output, per the tooling in `blog/scripts/`.

| Capture route | Topics |
| --- | --- |
| **Plain container** (`capture.sh <distro>`) | 01, 02, 03, 04, 05, 06, 07, 08, 19, 20, 21, 22, 25, 26, 27, 28, 29, 30, 31, 42, 47, 51, 52, 53, 54, 55, 56, 62, 68 |
| **Privileged with loop devices** (`--block N`) | 12, 13, 14, 15, 23, 67 |
| **Podman machine VM** (real kernel, systemd) | 10, 33, 34, 39, 65, 69, 75 |
| **Documented only** | 09, 11, 16, 17, 18, 24, 32, 35, 36, 37, 38, 40, 41, 43, 44, 45, 46, 48, 49, 50, 57, 58, 59, 60, 61, 63, 64, 66, 70, 71, 72, 74, 76 |

Roughly 45 of 77 can carry real captured output. The documented-only set is
dominated by anything needing real hardware, a live network, a running service on
a public port, or a second machine.

Worth revisiting: several in the documented-only column could move up if a second
VM were available, particularly the networking and service topics. That is a
tooling decision, not a content one.

## Diagrams worth building

Inline SVG, theme-aware, only where the concept is structural.

| Topic | Diagram |
| --- | --- |
| 01 | Anatomy of a command: name, options, arguments, with a real example labelled |
| 03 | The filesystem as a single tree from `/`, with no drive letters |
| 04 | The two axes, static/variable against shareable/local. **built** |
| 07 | Permission bit layout, including setuid, setgid, sticky |
| 09 | Firmware to bootloader to kernel to initramfs to systemd, with the UEFI and BIOS paths |
| 12 | Disk to partition to filesystem to mount point as four distinct layers |
| 14 | The LVM stack: physical volumes, volume group, logical volumes, with a resize |
| 15 | RAID 0, 1, 5, 10 laid out as blocks across disks |
| 16 | An IP packet's journey from host to gateway to internet |
| 19 | stdin, stdout, stderr as three pipes out of a process |
| 29 | Process lifecycle and states, with where each signal acts |
| 33 | systemd dependency graph for a target |
| 36 | Container image layers and the writable layer on top |
| 40 | Packet path through netfilter hooks, with firewalld and ufw above nftables |
| 44 | SELinux subject, object, context, and the policy decision point |
| 48 | Certificate chain of trust from root to leaf |
| 63 | The symptom-to-hypothesis-to-test loop |
| 71 | The network diagnostic ladder as a decision path |
| 75 | The USE method against CPU, memory, I/O, network |

## Suggested authoring order

Not the reading order. Dependencies and risk first.

1. **Foundations 01, 02, 03** - everything else assumes them, and they are the
   biggest test of whether the beginner voice works. Write these next.
2. **Recut 04 and 73** - both exist in the practitioner voice; 04 is partly done.
3. **05 through 08** - completes the block a reader needs before any domain topic.
4. **The highest-weight domain topics with the best capture story** - 33, 34, 29,
   30, 31, 12, 13, 14. Real output makes these strong quickly.
5. **Troubleshooting block** - 63 first, since it establishes the symptom-first
   pattern the other thirteen follow.
6. **Everything else**, by domain weight.

Practice banks follow topics, never lead them: the `learnRef` rule will not let a
question ship for material that does not exist, which is the behaviour that keeps
the coverage report honest.
