---
title: "Digital forensics"
description: "Why memory comes first and what the reboot destroyed, what a hash taken at acquisition is actually for, what chain of custody records and why gaps in it matter, and what a legal hold does to a retention schedule."
deck: "The server was rebooted to get it working again. It worked"
track: "security-plus"
level: "working"
order: 620
objectives:
  - "Order evidence by volatility and say what a power cycle destroys"
  - "Say what a hash taken at acquisition proves and what it does not"
  - "Describe chain of custody and what a gap in it costs"
  - "Explain what a legal hold does to a retention schedule"
  - "Distinguish evidence that is admissible from evidence that is merely useful"
  - "Say why the first response frequently destroys what an investigation needs"
prerequisites: ["what-to-monitor-and-what-to-do-when-it-fires"]
tags: ["security-plus", "security", "operations", "forensics", "incident-response"]
updated: 2026-08-25
draft: false
examObjectives:
  - exam: "sy0-701"
    domain: "4.0"
    objective: "4.8"
sources:
  - title: "RFC 3227, Guidelines for Evidence Collection and Archiving"
    url: "https://www.rfc-editor.org/rfc/rfc3227.html"
    publisher: "IETF"
    accessed: 2026-08-25
    tier: 1
  - title: "SP 800-86, Guide to Integrating Forensic Techniques into Incident Response"
    url: "https://csrc.nist.gov/pubs/sp/800/86/final"
    publisher: "NIST"
    accessed: 2026-08-25
    tier: 1
  - title: "SP 800-61 Rev. 3, Incident Response Recommendations and Considerations"
    url: "https://csrc.nist.gov/pubs/sp/800/61/r3/final"
    publisher: "NIST"
    accessed: 2026-08-25
    tier: 1
  - title: "proc filesystem manual page"
    url: "https://man7.org/linux/man-pages/man5/proc.5.html"
    publisher: "man7.org"
    accessed: 2026-08-25
    tier: 1
symptoms:
  - symptom: "The machine was rebooted before anybody looked at it"
    anchor: "what-the-reboot-destroyed"
  - symptom: "Evidence exists and cannot be used"
    anchor: "chain-of-custody-and-what-a-gap-costs"
---

> **Before you read.** A server was behaving oddly. Somebody rebooted it, which
> fixed the problem, and the service came back. Three days later it becomes clear
> the machine had been compromised.
>
> **What is still available, and what went at the moment of the reboot?**

Almost everything that would have identified what happened went, and everything
that will now have to be inferred from disk remains. The reboot was a reasonable
operational decision made by somebody whose priority was availability, and it is
the single most common way an investigation loses its evidence.

### Some words you will need

<dl class="terms">
<dt>order of volatility</dt>
<dd>The sequence in which evidence disappears, and therefore the order to collect it.</dd>
<dt>acquisition</dt>
<dd>Taking a copy of evidence in a way that does not alter the original.</dd>
<dt>write blocker</dt>
<dd>Hardware or software preventing any write to the source while it is being read.</dd>
<dt>chain of custody</dt>
<dd>The unbroken record of who held the evidence, when, and what they did with it.</dd>
<dt>legal hold</dt>
<dd>An instruction to preserve everything relevant, which suspends normal deletion.</dd>
<dt>e-discovery</dt>
<dd>The process of identifying and producing relevant material for a legal matter.</dd>
<dt>admissible</dt>
<dd>Evidence a court will accept. A higher bar than evidence that tells you what happened.</dd>
<dt>preservation</dt>
<dd>Keeping the original unchanged, so a copy can be shown to correspond to it.</dd>
</dl>

## What breaks without this

**The first response destroys the evidence.** Rebooting, reimaging or cleaning the
machine resolves the incident and removes the record of it.

**A copy cannot be shown to be a copy.** No hash was taken at acquisition, so
nothing distinguishes the image from an image that has been edited.

**The evidence is real and unusable.** It passed through four people, none of whom
recorded receiving it, and the gap is the thing an opposing party will point at.

**Relevant material is deleted on schedule.** Retention did what it was configured
to do, during a matter that required preservation, and the deletion is now itself
a problem.

## What the reboot destroyed

Evidence has a lifetime, and the shortest-lived is usually the most informative.

<figure class="learn-figure">
<svg viewBox="0 0 720 330" role="img" aria-labelledby="vol-title" style="width:100%;height:auto;">
<title id="vol-title">Seven layers of evidence ordered by how long each survives, with the five a power cycle clears and the two that do not depend on the machine staying up</title>
<g fill="currentColor">
<text x="14" y="20" font-size="11">collect in this order, because the top of the list is gone first</text>
<text x="300" y="44" font-size="9" fill-opacity="0.7">how long it lasts</text>
<text x="540" y="44" font-size="9" fill-opacity="0.7">survives a power cycle</text>
<rect x="14" y="54" width="272" height="26" rx="3" fill="var(--red)" fill-opacity="0.12" stroke="var(--red)" stroke-opacity="0.7" stroke-width="1.2"/>
<text x="26" y="71" font-size="8.5">CPU registers and cache</text>
<text x="300" y="71" font-size="8" fill-opacity="0.85">nanoseconds</text>
<text x="540" y="71" font-size="8" fill="var(--red)" fill-opacity="0.95">no</text>
<rect x="14" y="87" width="272" height="26" rx="3" fill="var(--red)" fill-opacity="0.12" stroke="var(--red)" stroke-opacity="0.7" stroke-width="1.2"/>
<text x="26" y="104" font-size="8.5">memory, and what is in it</text>
<text x="300" y="104" font-size="8" fill-opacity="0.85">until power is lost</text>
<text x="540" y="104" font-size="8" fill="var(--red)" fill-opacity="0.95">no</text>
<rect x="14" y="120" width="272" height="26" rx="3" fill="var(--red)" fill-opacity="0.12" stroke="var(--red)" stroke-opacity="0.7" stroke-width="1.2"/>
<text x="26" y="137" font-size="8.5">network connections and ARP</text>
<text x="300" y="137" font-size="8" fill-opacity="0.85">seconds to minutes</text>
<text x="540" y="137" font-size="8" fill="var(--red)" fill-opacity="0.95">no</text>
<rect x="14" y="153" width="272" height="26" rx="3" fill="var(--red)" fill-opacity="0.12" stroke="var(--red)" stroke-opacity="0.7" stroke-width="1.2"/>
<text x="26" y="170" font-size="8.5">running processes</text>
<text x="300" y="170" font-size="8" fill-opacity="0.85">until they exit or reboot</text>
<text x="540" y="170" font-size="8" fill="var(--red)" fill-opacity="0.95">no</text>
<rect x="14" y="186" width="272" height="26" rx="3" fill="var(--red)" fill-opacity="0.12" stroke="var(--red)" stroke-opacity="0.7" stroke-width="1.2"/>
<text x="26" y="203" font-size="8.5">temporary files and swap</text>
<text x="300" y="203" font-size="8" fill-opacity="0.85">until reboot, sometimes</text>
<text x="540" y="203" font-size="8" fill="var(--red)" fill-opacity="0.95">no</text>
<rect x="14" y="219" width="272" height="26" rx="3" fill="var(--accent)" fill-opacity="0.14" stroke="var(--accent)" stroke-opacity="0.7" stroke-width="1.2"/>
<text x="26" y="236" font-size="8.5">disk</text>
<text x="300" y="236" font-size="8" fill-opacity="0.85">until overwritten</text>
<text x="540" y="236" font-size="8" fill="var(--accent)" fill-opacity="0.95">yes</text>
<rect x="14" y="252" width="272" height="26" rx="3" fill="var(--accent)" fill-opacity="0.14" stroke="var(--accent)" stroke-opacity="0.7" stroke-width="1.2"/>
<text x="26" y="269" font-size="8.5">remote logs and backups</text>
<text x="300" y="269" font-size="8" fill-opacity="0.85">the retention period</text>
<text x="540" y="269" font-size="8" fill="var(--accent)" fill-opacity="0.95">yes</text>
<path d="M 700 58 V 226" stroke="var(--red)" stroke-opacity="0.5" stroke-width="1.2"/>
<path d="M 696 218 L 700 228 L 704 218" fill="none" stroke="var(--red)" stroke-opacity="0.5" stroke-width="1.2"/>
<text x="694" y="150" text-anchor="middle" font-size="8" fill="var(--red)" fill-opacity="0.9" transform="rotate(-90 694 150)">gone first</text>
<text x="14" y="302" font-size="10" fill-opacity="0.85">the reboot that fixed the server cleared the top five rows</text>
<text x="14" y="322" font-size="9" fill-opacity="0.7">and it is the most common first response, because the priority in the room is availability</text>
</g></svg>
<figcaption>The order in which evidence disappears, which is therefore the order to collect it. The top five rows do not survive a power cycle, and between them they hold what the machine was actually doing: which processes were running, what they had open, what they were connected to, and anything that existed only in memory. Disk survives, which is why disk is what most investigations end up working from, and it is the layer that says least about the moment. A reboot is not negligence. It is the correct operational instinct, applied by somebody whose job at that moment is to restore a service, and the way to prevent it is to decide in advance who has the authority to say wait.</figcaption>
</figure>

**Memory is first because it holds what nothing else does.** Running processes and
their arguments, network connections in progress, decrypted data, credentials in
use, and any code that never touched disk. A technique that runs entirely in
memory leaves nothing on the disk to find, which is why an investigation of a
rebooted machine can conclude that nothing happened.

Here is the same idea at a smaller scale, and it is worth seeing because it
explains why process state is separate from disk state.

<details class="predict">
<summary>A process opens a file and the file is then deleted. Predict whether the contents are still reachable.</summary>

```bash
# AlmaLinux 10.2, x86_64
$ dnf -q -y install procps-ng lsof coreutils >/dev/null 2>&1; echo "a process writes a file, then the file is deleted while the process still holds it:"; printf "EVIDENCE-4c1f9a2b\n" > /tmp/notes.txt; (exec 9< /tmp/notes.txt; rm /tmp/notes.txt; echo "  ls says:"; ls /tmp/notes.txt 2>&1 | sed "s/^/    /"; echo "  the process still holds it:"; ls -l /proc/self/fd/9 2>/dev/null | sed "s/^/    /"; echo "  and the contents are still readable through the descriptor:"; cat /proc/self/fd/9 | sed "s/^/    /")
a process writes a file, then the file is deleted while the process still holds it:
  ls says:
    ls: cannot access '/tmp/notes.txt': No such file or directory
  the process still holds it:
    lr-x------. 1 root root 64 Aug 26 02:51 /proc/self/fd/9 -> /tmp/notes.txt (deleted)
  and the contents are still readable through the descriptor:
    EVIDENCE-4c1f9a2b
```

**Completely reachable, through the process.** `ls` reports that the file does not
exist. The process's file descriptor still points at it, the kernel marks it
`(deleted)`, and reading the descriptor returns the contents.

That is a small demonstration of a large principle. The filesystem's view and the
process's view are different things, and evidence can be present in one and absent
from the other. An investigator who examines only the disk sees a deleted file.
One who examines the running process reads it.

It also explains a technique investigators actively look for. Malicious code
frequently deletes itself immediately after starting, so that the filesystem shows
nothing while the process continues to run from the still-open image. Everything
about it is available while the process lives and nothing is available afterwards,
which is the volatility argument in its sharpest form.

The practical consequence for a first responder: before anything else, capture
what is running. On a live machine that means the process list with arguments, the
open file descriptors, and the network connections, and it costs about thirty
seconds. A reboot performed before those thirty seconds is the difference between
an investigation and a guess.

</details>
<details class="deeper">
<summary>If you are the first responder: what to capture in thirty seconds, and the order to do it in</summary>

The realistic scenario is not a forensic acquisition. It is one person, at an
awkward hour, with a service to restore and a suspicion that something is wrong.
Thirty seconds of the right commands is worth more than an hour of the wrong ones.

The order follows the volatility list and it matters, because each command takes
time and the machine keeps changing while you work.

**Connections first**, because they change fastest. A list of established
connections with the owning process is the shortest-lived thing you can practically
capture, and it is frequently the single most informative artefact.

**Then the process list with full arguments and parents.** Arguments matter more
than names: a process called `python3` tells you nothing and its command line
tells you what it is running. The parent tells you what started it, which is the
beginning of a sequence.

**Then open files per interesting process**, which is where the deleted-file case
above becomes visible, and which is worth doing only for the handful that looked
unusual in the previous step.

**Then the boot time and the current time**, which bound everything and take a
second.

Two practical constraints. Write the output somewhere off the machine, because
anything written locally alters the disk you may later want to image and may be
removed by whatever you are investigating. And do not start installing tools: a
package installation writes to the disk, changes timestamps across the filesystem
and reaches the network, and the commands above are all present already.

The thing to resist is investigating. The temptation once something looks wrong is
to start opening files and following the thread, and every minute spent doing that
is a minute the volatile state is decaying. Capture first, read afterwards, from
the copy.

</details>


## What a hash at acquisition is for

Acquisition means taking a copy without altering the original, and the hash is
what makes the copy defensible.

```bash
# AlmaLinux 10.2, aarch64
$ printf "case-2026-0814 interview notes\n" | dd of=$DEV0 bs=512 seek=2048 conv=notrunc status=none; echo "hash the source before touching it, which is the first thing an acquisition does:"; sha256sum $DEV0 | cut -c1-64; echo; echo "take the image, then hash the image:"; dd if=$DEV0 of=/tmp/evidence.img bs=1M count=512 status=none; sha256sum /tmp/evidence.img | cut -c1-64; echo; echo "one byte of the copy is altered in transit:"; python3 -c "p=\"/tmp/evidence.img\"; b=bytearray(open(p,\"rb\").read()); b[100000]^=0xFF; open(p,\"wb\").write(b)"; sha256sum /tmp/evidence.img | cut -c1-64
hash the source before touching it, which is the first thing an acquisition does:
a9f86acdbc0f86238855043af0cb89616fcf08c22bc647dfe275d396e08a9783

take the image, then hash the image:
a9f86acdbc0f86238855043af0cb89616fcf08c22bc647dfe275d396e08a9783

one byte of the copy is altered in transit:
149612b76f9767747f798e6a7e2e155d7766e5fccd83230819c661b48cb6045a
```

**The same digest for the source and the image, and a completely different one
after a single byte changed.** That is the whole mechanism.

What it proves is narrow and worth stating precisely. It proves that the image
you are holding now is the same data that was hashed at acquisition. It says
nothing about whether the source was already tampered with before you arrived, and
nothing about whether the acquisition was performed correctly.

**What makes it work is the timing.** The hash has to be computed at the moment of
acquisition, recorded in the custody documentation, and computed again by anybody
who later receives the image. A hash calculated afterwards, from the copy, proves
that the copy matches itself.

**A write blocker is the other half.** Reading a disk can change it: mounting a
filesystem updates timestamps, and some operating systems write to any volume they
see. A write blocker sits between the source and the examining machine and refuses
every write, which is what allows the source to be hashed again later and match.
<details class="predict">
<summary>An investigator is handed a disk image and a hash written on the custody form. Predict what they can establish, and what they cannot.</summary>

**They can establish that the image matches the hash. They cannot establish that
either one describes the original machine.**

Compute the digest of the image, compare it with the form, and if the two agree
then nothing has altered this file since somebody wrote that number down. That is
a real and useful guarantee about a period of time.

What it does not cover is everything before the number was written. If the
acquisition was performed on a mounted volume, timestamps changed before the hash
was taken and the hash faithfully records the altered state. If the source was
compromised in a way that modified files, the hash records the compromised
version. If the person taking the image made a mistake and imaged the wrong
device, the hash proves that the wrong device has not changed since.

The general shape is worth carrying because it applies to every integrity control
in this track: a hash establishes that two things are identical, and it says
nothing at all about whether either of them is correct. The correctness comes from
the procedure, which is why acquisition procedure and chain of custody are
documented in as much detail as they are.

The follow-up question an investigator will ask, and the one worth being ready for
if you are the person who took the image: was a write blocker used, and can the
source still be hashed to the same value today. If both answers are yes, the
period the hash cannot cover shrinks to almost nothing.

</details>


<details class="deeper">
<summary>If you write the runbook: where the three commands go, and who is allowed to say wait</summary>

The reboot in the hook was not a mistake by the engineer. It was the runbook
working, executed by somebody doing exactly what the organisation asked of them,
and the fix is therefore a change to the runbook rather than to the person.

The change is small. Immediately before the first destructive or restorative
action, add the capture commands, with the output going somewhere off the machine,
and a note saying this takes thirty seconds and does not delay recovery
meaningfully. That framing matters: an instruction presented as a delay to
recovery will be skipped under pressure, and one presented as thirty seconds will
not.

The harder half is authority. Somebody has to be able to say do not touch that
machine, and there has to be an agreed answer to what happens when that
instruction conflicts with restoring a service. The answer is genuinely
situational, and the point is to have decided the process rather than the outcome:
who is called, how quickly they respond, and who decides if they cannot be
reached.

The failure to design for is the two in the morning one. If the process requires
reaching a security lead who is asleep, and the service is down, the engineer will
reboot, correctly, and the process will have achieved nothing except a delay.
Either the escalation genuinely answers at that hour or the runbook should say
that below a stated severity the engineer proceeds after capturing, which is an
honest position and better than a policy everybody knows will be ignored.

One more thing worth putting in the runbook, because it is free: record the time
you did each thing. An investigator receiving a machine that was captured at 02:14
and rebooted at 02:16 can reason about the gap. One receiving a machine with no
times has to treat everything as uncertain.

</details>

## Chain of custody, and what a gap costs

The chain of custody is a record: who had the evidence, from when to when, what
they did with it, and who they gave it to. Every transfer is signed by both
parties.

**A gap does not prove tampering and it does not need to.** It creates a period
during which nobody can say what happened to the evidence, and the argument then
becomes about whether the evidence can be relied on rather than about what it
shows. That is a much worse position to be in and it is entirely avoidable.

Three failures produce most gaps and none is dramatic. Evidence handed to somebody
informally, because they were the right person and everybody was busy. A period in
a drawer, an unlocked office or a car boot, unrecorded. And a copy made for
convenience, so there are now two artefacts and the record covers one.

**Admissible and useful are different standards**, which is the distinction the
objective is really testing. Evidence that tells you exactly what happened may be
useless in a proceeding if it was collected in a way nobody can attest to.
Evidence collected impeccably may be uninformative. An investigation frequently
needs both kinds, and knowing which one you are producing changes how much care
each artefact deserves.

The practical version for somebody who is not a forensic examiner: if there is any
possibility of a matter becoming legal, stop and get somebody who does this
professionally, because the decisions that ruin admissibility are made in the
first hour by people acting reasonably.
<details class="deeper">
<summary>If a matter might become legal: what changes about how you work, and when to stop</summary>

Most incidents are handled internally and never involve anybody outside the
organisation. A minority become employment matters, insurance claims, regulatory
proceedings or litigation, and the difference in how evidence must be handled is
substantial. The problem is that you cannot tell which kind you have in the first
hour.

What changes when a matter is legal is the standard the evidence has to meet.
Internally, evidence has to convince colleagues, and a screenshot in a ticket is
frequently enough. Externally, it has to survive somebody whose job is to argue
that it should not be relied on, and every step from collection onward is
available for that argument.

The practical guidance is a threshold rather than a procedure. Handle the first
thirty seconds as described above regardless, because that is investigative work
any responder should do. Then stop, before touching the disk, and ask whether this
could involve anybody outside the team. If the answer is a genuine maybe, the next
person to touch that machine should be somebody who does this professionally, and
the machine should be isolated rather than examined.

Three things to avoid in the meantime, all of which are natural and all of which
damage a case. Do not log in and browse the filesystem, because every access
changes metadata. Do not copy files off with ordinary tools, because a copy is not
an image and the record of where it came from lives only in your memory. And do
not discuss preliminary conclusions in writing, because early theories are usually
wrong and they are discoverable.

The judgement worth internalising: the cost of treating an ordinary incident as
though it might be legal is a few hours of inconvenience. The cost of treating a
legal matter as an ordinary incident is that the evidence exists and cannot be
used, which is the worst of the available outcomes because the organisation both
knows what happened and cannot demonstrate it.

</details>


## Legal hold, e-discovery, and the retention schedule

A legal hold is an instruction to preserve everything potentially relevant, and it
overrides the ordinary lifecycle of information.

**It suspends deletion**, which means the retention schedule from the asset
management topic stops applying to the material in scope. Backups that would have
expired do not. Mailboxes that would have been purged are not. Automated cleanup
that runs nightly has to be exempted, and that exemption has to be implemented
rather than announced.

**This is where holds fail**, and the failure is mechanical rather than deliberate.
The hold is issued as a notice to people. The deletion is performed by a system on
a schedule. Nobody connects the two, the system deletes on time, and the
organisation has destroyed material it was required to preserve, which is a more
serious problem than whatever the original matter was.

**E-discovery is the process of finding and producing what is in scope**, and the
thing that makes it feasible or ruinous is the inventory again: knowing what
systems hold what kinds of information, and being able to search them. An
organisation that cannot say where a category of data lives will produce either
far too much or far too little, and both are expensive.
<details class="deeper">
<summary>If you receive a hold notice: the three places material hides, and the one that catches organisations out</summary>

A hold requires preserving everything potentially relevant, and the difficulty is
never the obvious repository. It is the copies.

**The systems everybody names.** Mail, the file share, the case management system,
the ticketing tool. These are in every hold notice, they are the easy part, and
suspending deletion on them is usually a supported feature.

**The systems nobody names.** Chat, which frequently has its own retention set to
something short and cheerful. Personal drives on the corporate storage. The
analytics warehouse holding a derived copy of the same records. Exports somebody
made for a report in 2024. Third-party services a department bought, which is the
same list that defeats the leaver process.

**Backups**, which are the ones that catch organisations out, and for a specific
structural reason: they are usually designed to be immutable and to expire on a
schedule, and those two properties are in direct tension with a hold. You cannot
selectively delete from an immutable backup, which is good, and you cannot
selectively preserve either, so preserving one item means preserving the whole
set past its expiry, and that has cost and capacity consequences somebody has to
approve quickly.

The mechanism that prevents most failures is unglamorous. Maintain a list of every
system that deletes anything on a schedule, with the owner of each and the
technical means of suspending it. That list is short, it is stable, and building
it takes an afternoon when nothing is happening. Reconstructing it while a hold is
live, under a deadline, with legal counsel waiting, is a different experience.

The second mechanism is verification. A hold that was issued and a hold that took
effect are different states, and the difference is discovered when somebody checks
that the nightly job actually skipped the mailbox. Nobody checks unless the process
says to.

</details>


## Across platforms

The first thirty seconds asks the same three questions everywhere and none of the
commands transfers.

| Task | Linux | Windows | macOS |
| --- | --- | --- | --- |
| What is running, with its parent | `ps -eo pid,ppid,args` | `Get-CimInstance Win32_Process` | `ps -eo pid,ppid,lstart,comm` |
| What a process has open | `/proc/PID/fd` | handle enumeration, no built-in listing | `lsof -p PID` |
| Connections in progress | `ss -tanp` | `Get-NetTCPConnection` | `lsof -nP -iTCP` |
| Hash a file | `sha256sum` | `Get-FileHash -Algorithm SHA256` | `shasum -a 256` |

```powershell
# Microsoft Windows Server 2025 Datacenter, version 10.0.26100.0
> Get-CimInstance Win32_Process | Select-Object -First 4 ProcessId, ParentProcessId, Name, CreationDate | Format-Table -AutoSize
ProcessId ParentProcessId Name                CreationDate
--------- --------------- ----                ------------
        0               0 System Idle Process 8/26/2026 2:39:28 AM
        4               0 System              8/26/2026 2:39:28 AM
       92               4 Secure System       8/26/2026 2:39:26 AM
      132               4 Registry            8/26/2026 2:39:26 AM

# What each of those has open on the network, which is gone the moment the machine restarts
> Get-NetTCPConnection -State Established, Listen | Select-Object -First 4 LocalPort, RemoteAddress, State, OwningProcess | Format-Table -AutoSize
LocalPort RemoteAddress  State OwningProcess
--------- -------------  ----- -------------
    49686 ::            Listen           984
    49671 ::            Listen          3908
    49670 ::            Listen          3352
    49668 ::            Listen          2532

# How long the machine has been up, which bounds everything above
> (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
Wednesday, August 26, 2026 2:39:26 AM

# And the hash command, since the Linux column's does not exist here
> Get-FileHash C:\Windows\System32\drivers\etc\hosts -Algorithm SHA256 | Select-Object -ExpandProperty Hash
87015F8C03335B852F2A0A5A0E88211F5A7CFE8B298B0DFBB848FA647972E3C2
```


# provenance: Microsoft Windows Server 2025 Datacenter, version 10.0.26100.0, runner image 20260818.207.1

**The last command is the one that matters for the acquisition argument.** The
digest is the same construction as the Linux column's and the command is spelled
differently, so a response runbook written on one platform produces a syntax error
on another at the moment nobody wants one.

The boot time on the third command is the piece a first responder should record
before anything else, because everything volatile on the machine is bounded by it.
A process that started before the last boot does not exist, and a connection
established four days ago on a machine up for nine minutes is somebody's mistaken
note rather than evidence.

```bash
# macOS 26.5.2, arm64
$ ps -eo pid,ppid,lstart,comm | head -4
  PID  PPID STARTED                      COMM
    1     0 Wed Aug 26 02:46:32 2026     /sbin/launchd
   86     1 Wed Aug 26 02:46:35 2026     /usr/libexec/logd
   87     1 Wed Aug 26 02:46:35 2026     /usr/libexec/smd
ps: stdout: Broken pipe

# What is open on the network right now, which the reboot clears
$ sudo lsof -nP -iTCP 2>/dev/null | head -4
COMMAND    PID   USER   FD   TYPE             DEVICE SIZE/OFF NODE NAME
launchd      1   root    7u  IPv6 0x3b7fd195b3df2cbf      0t0  TCP *:22 (LISTEN)
launchd      1   root    8u  IPv4 0x4fe558fc815438f6      0t0  TCP *:22 (LISTEN)
launchd      1   root   11u  IPv6 0x3b7fd195b3df2cbf      0t0  TCP *:22 (LISTEN)

# How long the machine has been up, which bounds everything above
$ uptime; sysctl -n kern.boottime
 2:55  up 9 mins, 1 user, load averages: 1.28 5.21 5.23
{ sec = 1787712392, usec = 0 } Wed Aug 26 02:46:32 2026

# And the hash command, since the Linux column's does not exist here
$ shasum -a 256 /etc/hosts | awk '{print $1}'
83a3c5bbeebf10feabd8e61c178f90b5f1abe7c0c7a54f591a06795a4187716e
```

**No `/proc` on either of these two**, which is the structural difference. On Linux
a process's open files are a directory you can list, which is what made the
deleted-file demonstration above a one-line command. On the other two, the same
information comes from a separate tool and a separate subsystem, and the deleted
file case is correspondingly harder to observe.

The macOS uptime line is worth reading as an investigator would: nine minutes,
with the boot time given twice in two formats. That single value is what tells you
the machine cannot hold anything older, and it is the first thing to write down
because it constrains every subsequent claim about the volatile layers.

## Prove it

**Run it.** Open a file with `exec 9< file`, delete it, and read `/proc/self/fd/9`.
It takes ten seconds and permanently fixes the intuition that deleting a file
removes access to it.

**Work it out.** Take the rebooted server in the hook. List what an investigator
could still establish and what is now unavailable, then decide what a first
responder would have needed to capture, and how long it would have taken.

**Look it up.** Open RFC 3227 and find its order of volatility list. It is older
than most of the tooling in use today and the ordering has not needed to change,
which is worth noticing.

## What trips people up

### 1. Rebooting to restore the service

It is the correct operational instinct and it clears the top five rows of the
figure. Preventing it is an authority question decided in advance rather than a
technical one.

### 2. Examining only the disk

The capture on this page shows a file that does not exist to `ls` and is readable
through a process. Filesystem state and process state are different views, and
evidence can be in one and not the other.

### 3. Hashing the copy rather than the source

A hash computed after acquisition, from the image, proves the image matches
itself. The hash has to be taken at acquisition and recorded, so anybody receiving
the image later can compute it again.

### 4. Mounting the source to look at it

Mounting updates timestamps and some systems write to any volume they see. That is
why a write blocker exists, and it is why the source will no longer match its
acquisition hash if you skip one.

### 5. Treating a custody gap as harmless because nothing happened

It does not have to prove tampering. It shifts the argument from what the evidence
shows to whether it can be relied on, which is a much worse conversation.

### 6. Issuing a legal hold as a notice to people

The deletion is performed by systems on a schedule. A hold that does not suspend
those schedules results in the organisation destroying material it was required to
keep.

## Work it through

An alert fires at two in the morning on a production database server. The
on-call engineer sees unusual processes, the service is degraded, and their
runbook says restore service.

**The tempting move is to reboot.** It will probably work, it is what the runbook
says, and the person is alone at two in the morning with a degraded service and a
business that starts in five hours.

**The move that works costs thirty seconds first.** Capture the process list with
full arguments, the open file descriptors, and the network connections, to a file
somewhere off the machine. Then reboot. That is not a forensic acquisition and it
is not intended to be: it is the thirty seconds of volatile state that would
otherwise be gone forever, taken by somebody whose actual job right now is the
service.

**Then the decision about a real acquisition is made by somebody awake.** If it
turns out to matter, the memory is gone but the process list is not, and the
investigation starts from something rather than nothing.

**What this rejects is the idea that preservation and availability are opposed.**
They are opposed if preservation means waiting for a forensic examiner. They are
not opposed if the runbook contains three commands before the reboot, and putting
them there is the entire intervention.

The residual is honest and worth stating: thirty seconds of output is not
admissible evidence and will not survive scrutiny in a proceeding. It is
investigative material, gathered by an operator, and if the matter becomes legal
the proper acquisition happens on the disk afterwards with somebody qualified. The
purpose of the thirty seconds is to know what happened, which is a different goal
from proving it.

## Try it

**Read a deleted file.** `exec 9< /etc/hostname; rm` is not advisable on a real
file, so use a copy in `/tmp`. Delete it and read `/proc/self/fd/9`.

**Hash something twice.** Take any file, hash it, copy it, hash the copy, change
one byte and hash again. Watching the digest change completely is what makes the
acquisition argument concrete.

**Find your retention automation.** For one system, find what deletes data on a
schedule and ask who would suspend it during a legal hold. If the answer is a
person receiving an email, the hold is a notice rather than a control.

**Read your own runbook.** Find the first destructive action in it and ask whether
anything is captured before that point.

## Check yourself

<details class="qa">
<summary>Why does memory come first in the order of volatility?</summary>

Because it holds what nothing else does and it does not survive a power cycle:
running processes and their arguments, connections in progress, decrypted data,
credentials in use, and any code that never touched disk.

A technique that runs entirely in memory leaves nothing on disk, so an
investigation of a rebooted machine can reasonably conclude nothing happened. Disk
survives and says least about the moment.

</details>

<details class="qa">
<summary>A file is deleted while a process has it open. What can an investigator recover?</summary>

The contents, through the process. `ls` reports the file does not exist, the
kernel marks the descriptor `(deleted)`, and reading it returns the data.

Investigators look for this specifically, because malicious code frequently
deletes itself after starting and continues running from the still-open image.
Everything is available while the process lives and nothing afterwards.

</details>

<details class="qa">
<summary>What does a hash taken at acquisition prove, and what does it not?</summary>

That the image being examined now is the same data that was hashed at the moment
of acquisition. In the capture, source and image match, and altering one byte of
the image produces a completely different digest.

It says nothing about whether the source had already been tampered with before
acquisition, and nothing about whether the acquisition was performed correctly. It
also has to be taken at acquisition: a hash computed later from the copy proves
the copy matches itself.

</details>

<details class="qa">
<summary>What does a gap in the chain of custody cost?</summary>

It changes the argument. A gap does not prove tampering and does not need to: it
creates a period nobody can account for, so the question becomes whether the
evidence can be relied on rather than what it shows.

The usual causes are mundane. Evidence handed over informally, an unrecorded
period in a drawer or a car, and a copy made for convenience so two artefacts
exist while the record covers one.

</details>

<details class="qa">
<summary>Why do legal holds fail, and what would prevent it?</summary>

Because the hold is issued as a notice to people while deletion is performed by
systems on a schedule, and nobody connects the two. The system deletes on time and
the organisation destroys material it was required to preserve.

Preventing it means implementing the suspension rather than announcing it:
identifying which automated processes would delete in-scope material, exempting
them explicitly, and verifying that the exemption took effect.

</details>

## References

- [RFC 3227](https://www.rfc-editor.org/rfc/rfc3227.html) - IETF, evidence collection and archiving, and the source of the order of volatility. Free. Accessed 2026-08-25.
- [SP 800-86](https://csrc.nist.gov/pubs/sp/800/86/final) - NIST, integrating forensic techniques into incident response, for acquisition, preservation and examination. Free. Accessed 2026-08-25.
- [SP 800-61 Rev. 3](https://csrc.nist.gov/pubs/sp/800/61/r3/final) - NIST, incident response, for where evidence handling sits inside the wider process. Free. Accessed 2026-08-25.
- [proc(5)](https://man7.org/linux/man-pages/man5/proc.5.html) - the file descriptor entries the deleted-file capture reads. Free. Accessed 2026-08-25.

**Where the content came from.** Both blocks are captured from an AlmaLinux 10.2
container, the second against a real 512 MB loop device provisioned for the
capture and destroyed afterwards. The deleted-file demonstration opens, deletes
and reads a file created seconds earlier by the same command. Nothing on this page
examines anybody's data: the evidence in the acquisition block is a line of text
this topic wrote onto a blank device. There is no platform comparison here,
because the order of volatility is a property of how computers work rather than of
an operating system, and the tooling differences belong to a forensic practitioner
rather than to this exam.

**If you also work on Linux.** The Linux+ track's
[processes and signals](/learn/linux-plus/processes-and-signals) covers what a
process holds open and how to look at it, which is the first thirty seconds this
topic argues for.
