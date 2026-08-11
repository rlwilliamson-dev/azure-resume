---
title: "Containers: the basics"
description: "A container is not a small virtual machine, and the difference is visible in one command. What an image is, what a container is, and the six commands that cover almost everything you will do with them."
deck: "Ship the application and everything it needs as one thing"
track: "linux-plus"
level: "working"
order: 360
objectives:
  - "State what a container shares with its host and what it does not"
  - "Distinguish an image from a container and explain why it matters"
  - "Run, inspect, enter, stop, and remove a container"
  - "Diagnose a container that exits immediately"
prerequisites: ["systemd-targets-timers-and-journal"]
tags: ["linux", "linux-plus", "containers", "podman", "docker"]
updated: 2026-08-07
draft: false
examObjectives:
  - exam: "xk0-006"
    domain: "2.0"
    objective: "2.6"
sources:
  - title: "podman(1)"
    url: "https://docs.podman.io/en/latest/markdown/podman.1.html"
    publisher: "Podman project"
    accessed: 2026-08-07
    tier: 1
  - title: "namespaces(7)"
    url: "https://man7.org/linux/man-pages/man7/namespaces.7.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "cgroups(7)"
    url: "https://man7.org/linux/man-pages/man7/cgroups.7.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-07
    tier: 1
  - title: "OCI Runtime Specification"
    url: "https://github.com/opencontainers/runtime-spec/blob/main/spec.md"
    publisher: "Open Container Initiative"
    accessed: 2026-08-07
    tier: 1
  - title: "Docker CLI reference"
    url: "https://docs.docker.com/reference/cli/docker/"
    publisher: "Docker"
    accessed: 2026-08-07
    tier: 2
symptoms:
  - symptom: "Container exits immediately after starting"
    anchor: "1-the-container-exits-immediately"
  - symptom: "Cannot connect to the port a container is serving"
    anchor: "3-the-port-is-not-published"
---

> **Before you read.** "It works on my machine" is the oldest complaint in
> software, and it is nearly always true. The machine that works has a different
> library version, a different Python, a config file somebody edited in 2023 and
> forgot.
>
> Containers solve it by shipping the application **with** its dependencies, as
> one artefact, so the thing tested is the thing deployed.
>
> Virtual machines also solve it, and have for longer. **So why is a container
> tens of megabytes and a virtual machine several gigabytes, when both claim to
> package an application with everything it needs?**

Because one of them is not packaging an operating system. Lesson 24 established
the difference in a sentence; this lesson is what follows from it in practice, and
nearly every container behaviour that seems arbitrary is a consequence of that one
fact.

### Some words you will need

<dl class="terms">
<dt>image</dt>
<dd>A read-only template: a filesystem plus metadata saying what to run. Does nothing on its own.</dd>
<dt>container</dt>
<dd>A running instance of an image, with a writable layer of its own.</dd>
<dt>registry</dt>
<dd>A server holding images. Docker Hub, Quay, a private one.</dd>
<dt>tag</dt>
<dd>A label on an image version. <code>nginx:alpine</code>, <code>nginx:1.26</code>.</dd>
<dt>runtime</dt>
<dd>The low-level program that actually creates the container. runc or crun.</dd>
</dl>

## What breaks without this

**You cannot read a modern deployment.** Most new server software ships as an
image first and a package second, if at all.

**You treat containers as small VMs** and are baffled by every difference: no init
system, no `systemctl`, one process, and everything gone when it stops.

**You cannot debug one.** A container that exits immediately gives no obvious
error, and the reason is almost always the same one.

## The one fact everything follows from

The capture below runs **inside a Debian container**. Every file in it comes from
Debian. The last command asks the kernel for its version.

<details class="predict">
<summary>A virtual machine running Debian would report a Debian kernel. What does a Debian container report, and what does that tell you about what a container is?</summary>

```bash
# Debian 13 (trixie), x86_64
$ echo "--- markers a container leaves for itself ---"; ls -l /run/.containerenv /.dockerenv 2>/dev/null || echo "(no marker file)"; echo "--- and PID 1 is not systemd ---"; cat /proc/1/comm; echo "--- the kernel is the hosts ---"; uname -r
--- markers a container leaves for itself ---
-rw-r--r--. 1 root root 0 Aug  8 02:37 /run/.containerenv
--- and PID 1 is not systemd ---
sh
--- the kernel is the hosts ---
7.1.3-200.fc44.aarch64
```

</details>

**A Debian container, reporting a Fedora kernel.** `fc44` is Fedora 44. Every file
in that container is Debian; the kernel is not, because there is only one and it
belongs to the host.

**A container is a set of processes on the host's kernel**, given private views of
the filesystem, the process table, and the network by namespaces, and constrained
by cgroups. That is all it is. There is no container object in the kernel.

Everything else follows:

| Because there is no kernel | Therefore |
| --- | --- |
| Nothing to boot | Starts in milliseconds |
| No OS to package | Tens of megabytes, not gigabytes |
| Kernel is shared | Cannot run a different OS family |
| Modules and `sysctl` are the host's | `modprobe` inside is meaningless |
| Isolation is kernel-enforced | Weaker boundary than a VM |

**PID 1 is `sh`, not systemd.** A container's first process is whatever it was
told to run, and when that process exits, the container stops. That single
sentence explains most container confusion, and the whole of the prediction
below.

<details class="deeper">
<summary>If you already administer Linux: the namespaces and cgroups that make up that private view</summary>

"Private views of the filesystem, the process table, and the network" is seven
separate kernel features, and knowing which is which explains most container
behaviour that looks like magic.

| Namespace | Isolates | Visible effect |
| --- | --- | --- |
| `mnt` | Mount points | Its own filesystem tree |
| `pid` | Process IDs | Your process is PID 1 |
| `net` | Interfaces, routes, ports | Its own `lo` and its own port 80 |
| `uts` | Hostname and domain | `hostname` differs from the host's |
| `ipc` | Shared memory, queues | Cannot see the host's IPC |
| `user` | UID and GID mapping | Root inside, unprivileged outside |
| `cgroup` | The cgroup tree it sees | Cannot see the host's hierarchy |

You can see them directly, and they are just files:

```
ls -l /proc/self/ns/
sudo lsns -t net
```

Two processes in the same namespace show the same inode number there. That is
the entire mechanism: `nsenter` and `docker exec` work by opening those files
and calling `setns`.

**`user` is the one that makes rootless containers possible**, and it is worth
understanding because it explains a whole class of permission confusion. UID 0
inside the container maps to your unprivileged UID outside, via the ranges in
`/etc/subuid` and `/etc/subgid`. So a process that is genuinely root inside
(it can `chown`, install packages, bind port 80 in its own netns) is your
ordinary user to the host kernel. Files it creates on a bind mount appear
owned by some high UID like 100000, because that is what its "root" maps to.
That is not a bug and `podman unshare` is the way to manipulate those files
from outside.

**cgroups are the other half, and they are about amount rather than
visibility.** Namespaces decide what a process can *see*; cgroups decide how
much it can *use*, CPU shares, memory ceilings, I/O weight, PID counts.
`podman run --memory=512m` writes to `memory.max` in the container's cgroup,
which is the identical mechanism as `MemoryMax=` in a systemd unit from lesson
33. Containers and services are limited by the same kernel feature, configured
through two different front ends.

**Which is why "a container is a lightweight VM" is the wrong model.** There
is no guest kernel, no virtual hardware, and no hypervisor, so a kernel
vulnerability is shared with the host, a kernel module cannot be loaded from
inside, and anything needing a different kernel version genuinely needs a VM.

</details>

## Images and containers

<figure class="learn-figure">
<svg viewBox="0 0 720 230" role="img" aria-labelledby="ic-t ic-d" style="width:100%;height:auto;">
<title id="ic-t">One image on disk, several containers running from it</title>
<desc id="ic-d">An image is a read only template stored once. Running it does not copy it. Each container gets its own writable layer stacked on top of the shared image, so three containers from one 63 megabyte image cost 63 megabytes plus whatever the three have written, not three times 63. Nothing a container writes reaches the image, which is why deleting a container discards only its own layer and why the image is byte for byte the same afterwards.</desc>
<g>
<rect x="30" y="86" width="200" height="76" rx="5" fill="var(--accent)" fill-opacity="0.12" stroke="var(--accent)" stroke-opacity="0.9" stroke-width="1.8"/>
<text x="130" y="114" text-anchor="middle" font-size="11.5" fill="var(--accent)">nginx:alpine</text>
<text x="130" y="134" text-anchor="middle" font-size="10" fill="var(--accent)">read only, 63.1 MB</text>
<text x="130" y="152" text-anchor="middle" font-size="10" fill="currentColor" fill-opacity="0.65">stored once</text>
<rect x="400" y="34" width="180" height="48" rx="4" fill="currentColor" fill-opacity="0.07" stroke="currentColor" stroke-opacity="0.32" stroke-dasharray="5 3"/>
<text x="490" y="54" text-anchor="middle" font-size="11" fill="currentColor">web1</text>
<text x="490" y="70" text-anchor="middle" font-size="10" fill="currentColor" fill-opacity="0.65">its own writable layer</text>
<rect x="400" y="100" width="180" height="48" rx="4" fill="currentColor" fill-opacity="0.07" stroke="currentColor" stroke-opacity="0.32" stroke-dasharray="5 3"/>
<text x="490" y="120" text-anchor="middle" font-size="11" fill="currentColor">web2</text>
<text x="490" y="136" text-anchor="middle" font-size="10" fill="currentColor" fill-opacity="0.65">its own writable layer</text>
<rect x="400" y="166" width="180" height="48" rx="4" fill="currentColor" fill-opacity="0.07" stroke="currentColor" stroke-opacity="0.32" stroke-dasharray="5 3"/>
<text x="490" y="186" text-anchor="middle" font-size="11" fill="currentColor">web3</text>
<text x="490" y="202" text-anchor="middle" font-size="10" fill="currentColor" fill-opacity="0.65">its own writable layer</text>
<text x="30" y="196" font-size="10" fill="currentColor" fill-opacity="0.65">nothing a container writes reaches the image</text>
<text x="606" y="120" font-size="10" fill="currentColor" fill-opacity="0.65">delete one and</text>
<text x="606" y="136" font-size="10" fill="currentColor" fill-opacity="0.65">only its layer goes</text>
</g>
<g stroke="currentColor" stroke-opacity="0.5" fill="none" stroke-width="1.3">
<path d="M232 110 L320 110 L320 58 L396 58 M390 54 L397 58 L390 62"/>
<path d="M320 110 L396 124 M390 118 L397 124 L389 128"/>
<path d="M320 110 L320 190 L396 190 M390 186 L397 190 L390 194"/>
</g>
</svg>
<figcaption>Three containers from one image cost 63.1 MB plus three small layers, not three copies. The dashed boxes are the only part that belongs to a container, and they are the only part <code>podman rm</code> throws away, which is why a container is cheap to destroy and why anything you wanted to keep had to be on a volume.</figcaption>
</figure>

**An image is a template. A container is a running instance.** The relationship is
a program on disk to a process: one image, many containers, and the image is never
modified by running it.

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ echo "--- images on this machine ---"; sudo podman images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}" | head -5; echo "--- the layers an image is made of ---"; sudo podman history docker.io/library/nginx:alpine --format "table {{.Size}}\t{{.CreatedBy}}" 2>/dev/null | head -6
--- images on this machine ---
REPOSITORY                   TAG         SIZE
docker.io/library/nginx      alpine      63.1 MB
docker.io/library/alpine     latest      8.95 MB
docker.io/library/almalinux  10          207 MB
--- the layers an image is made of ---
SIZE        CREATED BY
49.2MB      RUN /bin/sh -c set -x     && apkArch="$(ca...
0B          ENV ACME_VERSION=0.4.1
0B          ENV NJS_RELEASE=1
0B          ENV NJS_VERSION=1.0.0
0B          CMD ["nginx" "-g" "daemon off;"]
```

**Alpine is 8.95 MB and AlmaLinux is 207 MB**, and both are complete
userlands. The difference is what each distribution considers minimal, Alpine
uses musl and BusyBox, the RHEL family ships glibc and a fuller set of tools.
Neither is wrong, and the size difference is why so many images are
Alpine-based.

**The layer detail belongs to the next lesson.** What matters here: an image is
built in layers, most of them zero bytes because they only set metadata.

## The commands

Six cover nearly everything.

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ sudo podman run -d --name web -p 8080:80 docker.io/library/nginx:alpine >/dev/null 2>&1; sleep 3; echo "--- what is running ---"; sudo podman ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"; echo "--- its logs ---"; sudo podman logs web 2>&1 | tail -3
--- what is running ---
NAMES       IMAGE                           STATUS        PORTS
web         docker.io/library/nginx:alpine  Up 3 seconds  0.0.0.0:8080->80/tcp
--- its logs ---
2026/08/08 03:26:14 [notice] 1#1: start worker process 27
2026/08/08 03:26:14 [notice] 1#1: start worker process 28
2026/08/08 03:26:14 [notice] 1#1: start worker process 29
```

| Command | Does |
| --- | --- |
| `podman run` | Create and start from an image |
| `podman ps` | Running containers. `-a` for stopped ones too. |
| `podman logs` | Its output |
| `podman exec` | Run something inside a running container |
| `podman stop` / `rm` | Stop it; remove it |
| `podman images` / `rmi` | List images; remove one |

**`podman logs` reads what PID 1 wrote to stdout and stderr.** That is why
containerised applications are expected to log to the terminal rather than to
files, the container's logs *are* its standard output, and an application
writing to `/var/log/app.log` inside a container is writing into a filesystem
that disappears.

Note `1#1` in the nginx output: nginx is PID 1 inside the container.

**The `run` flags worth knowing:**

| Flag | Does |
| --- | --- |
| `-d` | Detached, in the background |
| `--name web` | A name, rather than a generated one |
| `-p 8080:80` | Publish **host** port 8080 to **container** port 80 |
| `-e KEY=value` | An environment variable |
| `-v name:/path` | A volume. Next lesson. |
| `--rm` | Delete it when it exits |
| `-it` | Interactive with a terminal |

**`-p 8080:80` is host-first, and getting it backwards is a common error.**
The container has its own network namespace, so its port 80 is not the host's port
80 until you say so.

Reading `0.0.0.0:8080->80/tcp` in `ps` output: the host is listening on 8080 on
every interface and forwarding to 80 inside.

## Getting inside

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ echo "--- a shell inside a running container ---"; sudo podman exec web sh -c "hostname; ls /etc/nginx/conf.d"; echo "--- and the container networks ---"; sudo podman network ls
--- a shell inside a running container ---
d75162c037d0
default.conf
--- and the container networks ---
NETWORK ID    NAME        DRIVER
2f259bab93aa  podman      bridge
```

**The hostname is the container ID**, which is the default and is why container
hostnames look like that.

`podman exec -it web sh` gives an interactive shell. Two things to expect:
**the container may have no shell at all**, a distroless or scratch image
contains only the application, and **anything you change is lost when the
container is removed**, because you are writing to the temporary layer.

`exec` is for looking, not for fixing. A change made with `exec` is gone at the
next deployment, which is a feature: it stops the configuration drift that made
"works on my machine" a problem in the first place.

## When it exits immediately

<details class="predict">
<summary><code>podman run -d --name app myimage</code> returns an ID, and <code>podman ps</code> shows nothing. <code>podman ps -a</code> shows the container as <code>Exited (0)</code>. What happened?</summary>

**The main process finished, so the container stopped.** Exit code 0 means it
finished *successfully*. This is not an error, it is the container doing
exactly what it was told.

A container lives exactly as long as its PID 1. When that process returns, there
is nothing left to contain.

Three usual causes, and the first is by far the most common:

**The application daemonised itself.** Most server software has a "go into the
background" mode, and inside a container that is exactly wrong: the foreground
process forks, the parent exits, PID 1 returns, and the container stops, while
the daemon it started is killed along with the namespace. This is why the
nginx image runs `nginx -g "daemon off;"`, visible in the `CMD` line of the
layer output earlier. Apache needs `-DFOREGROUND`; most databases have an
equivalent.

The command was a one-shot. `podman run alpine ls` prints a listing and exits,
correctly. Nothing is wrong.

No long-running command was specified, so the image's default `CMD` ran and
finished.

How to find out:

```
podman ps -a                    # exit code
podman logs app                 # what it said before exiting
podman inspect app --format '{{.Config.Cmd}} {{.Config.Entrypoint}}'
```

The exit code narrows it immediately. `0` means it finished on purpose, look
for a daemonising flag. Non-zero means it failed, and `logs` will say why.
**`137`** is 128 + 9, SIGKILL, and inside a container that nearly always means
the memory limit was hit; `podman inspect` reports `OOMKilled`.

To debug interactively, override the command and get a shell instead:

```
podman run -it --entrypoint sh myimage
```

which starts the image without running its normal command, so you can look around
in the environment the application would have had.

</details>

<details class="deeper">
<summary>If you already administer Linux: what a container is made of, and how to look at it from the host</summary>

There is no container system call. It is a convention built from two independent
kernel features, and knowing that explains behaviour that otherwise looks
arbitrary.

**Namespaces give a private view.** `lsns` lists them:

`pid`, its own process table, so PID 1 inside is a different number outside.
`mnt`, its own mount table, which is why a filesystem mounted on the host
**after** the container started is invisible inside it. `net`, its own
interfaces and routing table, which is why port publishing is necessary at
all. `uts`, its own hostname. Plus `ipc`, `user`, `cgroup`, and `time`.

**Cgroups impose limits**: CPU shares, memory ceilings, I/O weight.
`systemd-cgtop` shows live usage per cgroup, for containers and ordinary services
alike, because systemd units use the same mechanism.

From the host, a container is just processes. `podman top web` or plain `ps
-ef | grep nginx` finds them, with the host's PID numbering. `podman inspect
web --format '{{.State.Pid}}'` gives PID 1's host PID, and from there
`/proc/<pid>/` works normally: `cmdline`, `environ`, `fd/`, `root/`, which is
the container's filesystem viewable from outside.

`nsenter` joins an existing container's namespaces, which is how you debug one
that has no shell in it:

```
nsenter -t $(podman inspect web --format '{{.State.Pid}}') -n ss -tlnp
```

That runs the **host's** `ss` inside the **container's** network namespace, which
is genuinely the only way to inspect networking in a distroless image.

`podman unshare` does the reverse for rootless containers, entering the user
namespace so file ownership under `~/.local/share/containers` makes sense.

</details>

<details class="deeper">
<summary>If you already administer Linux: podman and docker, and the differences that matter</summary>

The command-line interfaces are close enough that `alias docker=podman` works for
most everyday use. Three architectural differences do matter.

**Daemonless.** Docker has a long-running root daemon that owns every
container; podman forks them directly. So a podman container is an ordinary
process tree, visible to `ps` and manageable by systemd, and there is no
daemon whose restart takes every container with it. It is also why podman has
no equivalent of "the Docker socket", which is worth knowing because
**mounting the Docker socket into a container is equivalent to giving it root
on the host**, a widespread and underappreciated risk.

**Rootless by default.** Podman maps a range of host UIDs into the container via
the user namespace, so root inside is an unprivileged user outside. It removes the
"container escape means host root" problem at the cost of some capabilities and
some networking complexity. Docker can do rootless and does not by default.

**systemd integration.** `podman generate systemd` produces a unit file, and
newer versions use **Quadlet**: a `.container` file in
`/etc/containers/systemd/` that systemd turns into a service. That gives a
container `Restart=`, dependencies, resource limits, and journal logging, all
the things lesson 33 covered, without a separate orchestrator. On a single
server this is frequently the right answer instead of reaching for Kubernetes.

**Pods** are podman's other borrowing from Kubernetes: several containers sharing
a network namespace, so they reach each other on `localhost`. `podman play kube`
even runs a Kubernetes YAML file directly, which is useful for local testing.

The specification underneath is **OCI**, so images are interchangeable: an image
built with Docker runs under podman and the other way round. The runtime is
`runc` or `crun`, and `containerd` is the layer Docker and Kubernetes both use to
manage them.

</details>

## Across distributions

| | RHEL family | Debian family |
| --- | --- | --- |
| Default tooling | **Podman**, in the base repositories | Docker, from Docker's own repo |
| Rootless default | Yes | No |
| Image storage, rootful | `/var/lib/containers/` | `/var/lib/docker/` |
| Image storage, rootless | `~/.local/share/containers/` |, |
| Compose | `podman-compose`, or Quadlet | `docker compose` |

**Podman is the RHEL family's answer and Docker is not packaged there**, which is
worth knowing before following instructions that assume it. The commands are
near-identical; the storage locations and the daemon are not.

## Prove it

```bash
# What is running, and what has exited
podman ps
podman ps -a

# Why did it exit
podman logs thename
podman inspect thename --format '{{.State.ExitCode}} {{.State.OOMKilled}}'

# What is it actually running
podman inspect thename --format '{{.Config.Entrypoint}} {{.Config.Cmd}}'

# Is the port published where you think
podman port thename
ss -tlnp | grep 8080
```

**`podman ps -a` rather than `podman ps`** when something is wrong. The default
hides exactly the containers you need to look at.

## What trips people up

### 1. The container exits immediately

Its main process finished. Usually the application daemonised itself, which inside
a container means PID 1 returns and everything stops.

Run it in the foreground: `nginx -g "daemon off;"`, `httpd -DFOREGROUND`.
`podman ps -a` for the exit code and `podman logs` for the reason.

### 2. Treating it like a VM

No init system, so no `systemctl`. One process, not many. No persistent state.
Changes made with `exec` vanish at the next deployment.

Rebuild the image instead. That is the intended workflow, not a limitation.

### 3. The port is not published

The container has its own network namespace, so its port 80 is not the host's
until `-p` says so.

`-p host:container`, host first. `podman port thename` shows what was published.

### 4. Data disappears

The writable layer belongs to the container and is deleted with it. The next
lesson is entirely about this.

### 5. `latest` is not a version

`nginx:latest` is a moving tag. Two machines pulling it a month apart get
different software, which reintroduces exactly the problem containers were meant
to solve.

Pin a real tag, or a digest.

## Work it through

An application container restarts every few minutes. `podman ps` shows it up, then
gone, then up again.

Reason it out before reading on.

**Get the exit code**, because it splits the problem in two:

```
podman ps -a
podman inspect app --format '{{.State.ExitCode}} {{.State.OOMKilled}}'
```

`OOMKilled: true`, or exit code 137, means the memory limit was hit. 137 is
128 + 9, SIGKILL, and inside a container that is nearly always the cgroup
limit rather than the host running out. Either the limit is too low or the
application leaks; `podman stats` while it runs shows the trajectory and tells
you which.

**Exit code 0** means it finished on purpose, which with a restart policy produces
exactly this loop: run, finish, restart, finish. The daemonising problem from the
prediction, and the fix is running the application in the foreground.

A non-zero code that is not 137 means the application failed, and its own
output is the answer:

```
podman logs --since 10m app
```

Then check what the restart policy is, because it decides whether you are
seeing a loop or a series:

```
podman inspect app --format '{{.HostConfig.RestartPolicy.Name}}'
```

And the thing worth checking that nobody does: if this container is managed by
systemd, a Quadlet unit or `podman generate systemd`, then `systemctl status`
and `journalctl -u` have the history, including how many times it has
restarted and whether systemd has given up. `podman logs` shows only the
current instance, so a container that has restarted forty times shows you the
last few seconds and none of the pattern.

Now the point worth extracting. **A container's exit code is the first
diagnostic**, and it partitions the problem before you read a single log line: 0
means the process finished, 137 means it was killed for memory, and anything else
means the application had an opinion. Three different investigations, and the code
is free.

The habit: **`podman ps -a` and the exit code before `podman logs`.** Logs are
verbose and the code is one number, and reading them in the other order means
reading a lot of output before knowing what you are looking for.

## Try it

Optional, on a machine with podman or docker.

1. `podman run --rm alpine uname -r` and compare it with `uname -r` on the host.
   They will match.
2. `podman run --rm alpine cat /etc/os-release | head -2`. Alpine, on your host's
   kernel.
3. `podman run -d --name web -p 8080:80 nginx:alpine`, then `curl localhost:8080`.
4. `podman ps`, `podman logs web`, `podman port web`.
5. `podman exec -it web sh`, look around, `exit`.
6. `podman run --rm alpine ls /` and notice it exits immediately and correctly.
7. `podman stop web && podman rm web`, then `podman ps -a` to confirm.

**Verification step.** You have it when you can explain, without looking anything
up, why a container running a daemonising web server exits immediately with status
0.

## Check yourself

<details class="qa">
<summary>What does a container share with its host, and give three consequences.</summary>

**The kernel.** A container is processes on the host's kernel with private views
of the filesystem, process table, and network, provided by namespaces, and limits
imposed by cgroups.

Consequences, any three:

**It starts in milliseconds**, because there is nothing to boot.

It is tens of megabytes, because it packages a userland and not an operating
system.

It cannot run a different OS family. A Windows container needs a Windows
kernel and therefore a Windows host.

`modprobe` and `sysctl` inside are meaningless. Those are the host's kernel,
shared by every container.

Isolation is weaker than a VM's, because a kernel vulnerability is shared
rather than confined by a hardware boundary.

`uname -r` inside a container proves it: it reports the host's kernel version, not
the container image's distribution.

</details>

<details class="qa">
<summary>What is the difference between an image and a container?</summary>

**An image is a read-only template**: a filesystem plus metadata saying what to
run. It does nothing on its own.

**A container is a running instance of one**, with a thin writable layer of its
own for anything it changes.

The relationship is a program on disk to a process: one image can back many
containers, and running one never modifies the image.

The practical consequence is where changes go. Anything written inside a
container lands in that container's writable layer and is deleted with it,
which is why `podman exec` is for looking rather than fixing, and why
persistent data needs a volume.

`podman images` lists templates; `podman ps -a` lists instances.

</details>

<details class="qa">
<summary>A container exits immediately with status 0. What is the most likely cause and the fix?</summary>

**The application daemonised itself.** A container lives exactly as long as
its PID 1, and a server that forks into the background causes the foreground
process to return, so PID 1 exits, the container stops, and the daemon goes
with the namespace.

Status **0** is the tell: it finished *successfully*. The container did exactly
what it was told.

**The fix is to run the application in the foreground.** `nginx -g "daemon off;"`,
`httpd -DFOREGROUND`, and most databases have an equivalent flag. Official images
already do this, which is why the nginx image's `CMD` is what it is.

Two other causes of an immediate clean exit: the command was a one-shot such as
`ls`, or no long-running command was given and the image's default finished.

`podman ps -a` for the code, `podman logs` for anything it said.

</details>

<details class="qa">
<summary>Why is <code>-p 8080:80</code> necessary, and which number is which?</summary>

**Because the container has its own network namespace.** Its interfaces, its
addresses, and its ports are separate from the host's, so a service listening
on port 80 inside is not reachable on the host's port 80, or at all from
outside, until something forwards it.

**Host first, container second.** `-p 8080:80` means "listen on 8080 on the host
and forward to 80 in the container".

Getting it backwards is a common error and produces a confusing result rather than
an obvious one: the host listens on 80 and forwards to 8080 inside, where nothing
is listening, so connections are accepted and then fail.

`podman port thename` shows what was actually published, and `ss -tlnp | grep
8080` confirms the host end.

</details>

<details class="qa">
<summary>Why should an application in a container log to stdout rather than to a file?</summary>

**Because the container's logs are its standard output.** `podman logs` and
`docker logs` read what PID 1 wrote to stdout and stderr, and that is the
interface every orchestrator, log shipper, and monitoring system expects.

An application writing to `/var/log/app.log` inside a container is writing into
the writable layer, which is deleted with the container. The logs exist right up
until the moment you need them, which is after it crashed and was replaced.

It also means no log rotation inside the container, no permissions to get wrong,
and one place to look for every container on the machine.

The same reasoning as configuration by environment variable: **the container
should be stateless, and everything durable (data, logs, config) comes from
outside it.**

</details>

## References

- [podman(1)](https://docs.podman.io/en/latest/markdown/podman.1.html) - Podman project. Accessed 2026-08-07.
- [namespaces(7)](https://man7.org/linux/man-pages/man7/namespaces.7.html) - Linux man-pages project. Accessed 2026-08-07.
- [cgroups(7)](https://man7.org/linux/man-pages/man7/cgroups.7.html) - Linux man-pages project. Accessed 2026-08-07.
- [OCI Runtime Specification](https://github.com/opencontainers/runtime-spec/blob/main/spec.md) - Open Container Initiative. Accessed 2026-08-07.
- [Docker CLI reference](https://docs.docker.com/reference/cli/docker/) - Docker. Accessed 2026-08-07.

Command output was captured on the podman machine, running real containers, and
inside one of the pinned container images. The test containers and images were
removed afterwards. Blocks without a distribution and architecture header are
illustrative.
