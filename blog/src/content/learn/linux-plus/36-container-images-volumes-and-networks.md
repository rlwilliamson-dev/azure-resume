---
title: "Container images, volumes and networks"
description: "Where a container's writes actually go, why that layer is thrown away on purpose, and how to keep the data that should survive. Plus building an image, and the caching rule that decides whether a rebuild takes two seconds or four minutes."
deck: "The container restarts and the data is gone"
track: "linux-plus"
level: "working"
order: 370
objectives:
  - "Explain the layer model and where a container's writes land"
  - "Choose between a volume and a bind mount, and say why"
  - "Write a Containerfile that rebuilds quickly"
  - "Publish a port and connect two containers to each other"
prerequisites: ["containers-the-basics"]
tags: ["linux", "linux-plus", "containers", "volumes", "images"]
updated: 2026-08-07
draft: false
examObjectives:
  - exam: "xk0-006"
    domain: "2.0"
    objective: "2.6"
sources:
  - title: "Containerfile / Dockerfile reference"
    url: "https://docs.docker.com/reference/dockerfile/"
    publisher: "Docker"
    accessed: 2026-08-07
    tier: 1
  - title: "podman-run(1)"
    url: "https://docs.podman.io/en/latest/markdown/podman-run.1.html"
    publisher: "Podman project"
    accessed: 2026-08-07
    tier: 1
  - title: "podman-volume(1)"
    url: "https://docs.podman.io/en/latest/markdown/podman-volume.1.html"
    publisher: "Podman project"
    accessed: 2026-08-07
    tier: 1
  - title: "podman-network(1)"
    url: "https://docs.podman.io/en/latest/markdown/podman-network.1.html"
    publisher: "Podman project"
    accessed: 2026-08-07
    tier: 1
  - title: "OCI Image Format Specification"
    url: "https://github.com/opencontainers/image-spec/blob/main/spec.md"
    publisher: "Open Container Initiative"
    accessed: 2026-08-07
    tier: 1
  - title: "overlayfs"
    url: "https://docs.kernel.org/filesystems/overlayfs.html"
    publisher: "The Linux Kernel documentation"
    accessed: 2026-08-07
    tier: 1
symptoms:
  - symptom: "Database data lost when the container was recreated"
    anchor: "1-data-in-the-container"
  - symptom: "Permission denied on a bind-mounted directory"
    anchor: "3-permission-denied-on-a-bind-mount"
---

> **Before you read.** A database runs in a container for three weeks. The image
> gets an update, somebody recreates the container, and every row is gone.
>
> Nothing crashed. No disk failed. The command that removed the old container
> reported success.
>
> **If a container can write files, where do those files actually go?**

Somewhere that was designed to be thrown away, and the throwing away is the
point rather than a flaw. Understanding why requires one idea, layers, and
everything else in this lesson follows from it.

### Some words you will need

<dl class="terms">
<dt>layer</dt>
<dd>One read-only step in an image. Images are stacks of them.</dd>
<dt>writable layer</dt>
<dd>A thin layer on top, belonging to one container. Deleted with it.</dd>
<dt>volume</dt>
<dd>Storage managed by the container engine, outside any container's lifetime.</dd>
<dt>bind mount</dt>
<dd>A host directory mapped into a container. From lesson 13.</dd>
<dt>Containerfile</dt>
<dd>The recipe for building an image. Also called a Dockerfile.</dd>
</dl>

## What breaks without this

**You lose data**, which is the subject of the opening question and happens to
everybody once.

**Rebuilds take minutes instead of seconds**, because the caching rule was not
understood.

**Containers cannot reach each other**, or reach each other far too easily.

## Layers

<figure class="learn-figure">
<svg viewBox="0 0 720 340" role="img" aria-labelledby="layer-title layer-desc" style="width:100%;height:auto;">
  <title id="layer-title">How an image's layers stack, with the container's writable layer on top</title>
  <desc id="layer-desc">An image is a stack of read-only layers. At the bottom a base layer such as alpine, then a layer adding packages, then one adding the application, then one setting configuration. On top of the image sits a thin writable layer belonging to one running container, and everything the container writes goes there. That top layer is deleted when the container is removed, which is why data written inside a container does not survive. Several containers can share one image, each with its own writable layer. A volume attaches separately and lives outside the stack entirely.</desc>
  <g>
    <rect x="60" y="248" width="300" height="40" rx="3" fill="currentColor" fill-opacity="0.09" stroke="currentColor" stroke-opacity="0.3"/>
    <text x="210" y="273" text-anchor="middle" font-size="11.5" fill="currentColor">base image: alpine</text>
    <rect x="60" y="202" width="300" height="40" rx="3" fill="currentColor" fill-opacity="0.09" stroke="currentColor" stroke-opacity="0.3"/>
    <text x="210" y="227" text-anchor="middle" font-size="11.5" fill="currentColor">RUN apk add python3</text>
    <rect x="60" y="156" width="300" height="40" rx="3" fill="currentColor" fill-opacity="0.09" stroke="currentColor" stroke-opacity="0.3"/>
    <text x="210" y="181" text-anchor="middle" font-size="11.5" fill="currentColor">COPY app/</text>
    <rect x="60" y="110" width="300" height="40" rx="3" fill="currentColor" fill-opacity="0.09" stroke="currentColor" stroke-opacity="0.3"/>
    <text x="210" y="135" text-anchor="middle" font-size="11.5" fill="currentColor">CMD ["python3", "app.py"]</text>
    <rect x="60" y="56" width="300" height="44" rx="3" fill="none" stroke="currentColor" stroke-opacity="0.5" stroke-dasharray="5 3"/>
    <text x="210" y="76" text-anchor="middle" font-size="11.5" fill="currentColor">writable layer</text>
    <text x="210" y="92" text-anchor="middle" font-size="10" fill="currentColor" fill-opacity="0.65">one per container, deleted with it</text>
    <text x="372" y="80" font-size="10.5" fill="currentColor" fill-opacity="0.75">everything the container</text>
    <text x="372" y="94" font-size="10.5" fill="currentColor" fill-opacity="0.75">writes lands here</text>
    <text x="372" y="180" font-size="10.5" fill="currentColor" fill-opacity="0.6">read-only. shared by every</text>
    <text x="372" y="194" font-size="10.5" fill="currentColor" fill-opacity="0.6">container from this image.</text>
    <rect x="520" y="240" width="170" height="56" rx="4" fill="currentColor" fill-opacity="0.12" stroke="currentColor" stroke-opacity="0.45"/>
    <text x="605" y="263" text-anchor="middle" font-size="11.5" fill="currentColor">volume</text>
    <text x="605" y="280" text-anchor="middle" font-size="10" fill="currentColor" fill-opacity="0.65">outside the stack</text>
    <text x="605" y="292" text-anchor="middle" font-size="10" fill="currentColor" fill-opacity="0.65">and outside the lifetime</text>
    <text x="60" y="318" font-size="10.5" fill="currentColor" fill-opacity="0.6">the image: read-only, shared, cached per layer</text>
    <text x="210" y="36" text-anchor="middle" font-size="11" fill="currentColor" fill-opacity="0.8">the container</text>
  </g>
  <g stroke="currentColor" stroke-opacity="0.4" fill="none" stroke-width="1.2">
    <path d="M60 106 L360 106"/>
    <path d="M366 268 L514 268 M507 263 L515 268 L507 273"/>
  </g>
</svg>
<figcaption>The image is read-only and shared. Only the dashed layer belongs to the container, and only it is deleted.</figcaption>
</figure>

**An image is a stack of read-only layers**, one per build step. A container adds a
thin **writable layer** on top, and every file it creates or modifies goes there.

The layers below are shared. Ten containers from one image share one copy of the
image and have ten small writable layers, which is why containers are cheap to
start and cheap to have many of.

**Modifying an existing file uses copy-on-write:** the file is copied up into the
writable layer and changed there. The original is untouched, which is what lets
the lower layers stay shared.

And the writable layer is deleted with the container. Not corrupted, not lost,
deliberately removed, because the whole model assumes a container is
disposable and anything worth keeping lives elsewhere.

<details class="predict">
<summary>A container writes <code>/data.txt</code>, then is removed and a new one started from the same image. Is the file there? And what changes if a volume is mounted at <code>/data</code>?</summary>

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ echo "--- write inside a container, then remove it ---"; sudo podman run --name tmp1 alpine sh -c "echo important > /data.txt; cat /data.txt"; sudo podman rm tmp1 >/dev/null; sudo podman run --rm alpine cat /data.txt 2>&1 | tail -1; echo "--- now with a volume ---"; sudo podman run --rm -v appdata:/data alpine sh -c "echo important > /data/file.txt"; sudo podman run --rm -v appdata:/data alpine cat /data/file.txt
--- write inside a container, then remove it ---
important
cat: can't open '/data.txt': No such file or directory
--- now with a volume ---
important
```

**Gone.** The file was written to the first container's writable layer, and
removing the container removed the layer. The image is unchanged (it was
read-only throughout) so the second container starts from exactly the same
filesystem the first one did, with no `/data.txt` in it.

With a volume, it survives. The second pair of commands writes and reads
across two entirely separate containers, and the data persists because it was
never in either container's writable layer. `appdata` is storage the engine
manages, mounted into whatever container asks for it.

This is not a bug being worked around. It is the model: the container is
disposable and its filesystem is part of what gets disposed. Anything durable
(database files, uploads, certificates) is explicitly attached from outside.

The failure mode in the opening question is exactly this. A database container
with no volume writes its data to the writable layer, works perfectly for
three weeks, and loses everything the first time somebody recreates it, which
they will, because updating the image *requires* recreating it.

**The check, before you need it:**

```
podman inspect thename --format '{{range .Mounts}}{{.Source}} -> {{.Destination}}
{{end}}'
```

An empty result on anything holding state is a problem waiting for the next
update.

</details>

## Volumes and bind mounts

Two ways to attach storage, and the choice matters.

| | Volume | Bind mount |
| --- | --- | --- |
| Syntax | `-v appdata:/data` | `-v /srv/data:/data` |
| Storage | Engine-managed, under `/var/lib/containers/` | A path you name |
| Portable | Yes | No, depends on the host layout |
| Backup | `podman volume export` | Ordinary host tools |
| Right for | Databases, application state | Config files, development, host logs |

**The syntax difference is one character.** A source with a `/` is a **path** and
therefore a bind mount; a source without one is a **name** and therefore a volume.
`-v data:/data` and `-v ./data:/data` do different things.

```
podman volume create appdata
podman volume ls
podman volume inspect appdata      # where it actually lives
podman run -d -v appdata:/var/lib/postgresql/data postgres:16
```

**Use a volume for state the container owns**, database files, uploaded
content. The engine manages the location, so nothing depends on the host's
directory layout.

**Use a bind mount when the host path matters**, a config file you edit,
source code during development, or writing logs somewhere the host's log
shipper already watches.

**`:ro` makes it read-only**, and configuration mounted into a container should
nearly always be read-only:

```
-v /srv/config/app.conf:/etc/app.conf:ro
```

## Building an image

A `Containerfile`, the same format as a `Dockerfile`:

```dockerfile
FROM alpine:3.20

RUN apk add --no-cache python3

WORKDIR /app
COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt

COPY . .

USER 1000
EXPOSE 8000
CMD ["python3", "app.py"]
```

```
podman build -t myapp:1.0 .
```

| Instruction | Does |
| --- | --- |
| `FROM` | The base image. Always the first line. |
| `RUN` | Run a command **at build time**, creating a layer |
| `COPY` | Copy files in from the build context |
| `WORKDIR` | Set the directory for what follows |
| `ENV` | Set an environment variable |
| `USER` | Run as this user from here on |
| `EXPOSE` | **Documentation only.** Does not publish anything. |
| `CMD` | The default command. Overridable at run time. |
| `ENTRYPOINT` | The command that always runs; `CMD` becomes its arguments |

**`EXPOSE` publishes nothing.** It records the port the image expects to serve on,
for humans and for tooling. Only `-p` at run time actually forwards anything, and
believing otherwise is a common half-hour.

**`CMD` versus `ENTRYPOINT`:** `CMD` is a default that any argument replaces;
`ENTRYPOINT` always runs and `CMD` supplies its default arguments. For a container
that behaves like a command, use `ENTRYPOINT`. For one that behaves like a server
you might want a shell in, use `CMD`.

`USER` matters and is skipped constantly. Without it the container runs as
root, and root in a container is a smaller problem than root on a host but is
not nothing. Set it to a non-root UID once the build steps that need privilege
are done.

### The caching rule

**Each instruction is a layer, and layers are cached.** On rebuild, the engine
reuses cached layers until it reaches one whose inputs changed, and from that
point everything below is rebuilt.

That single rule decides whether a rebuild takes two seconds or four minutes, and
it dictates the order of the file:

```dockerfile
COPY requirements.txt .
RUN pip3 install -r requirements.txt    # cached unless requirements.txt changed
COPY . .                                # invalidated by any source change
```

**Dependencies before source code.** Source changes on every commit; dependencies
change rarely. Copying everything first and then installing means every one-line
code change reinstalls every dependency.

Two more habits from that same file:

**`--no-cache` on package managers**, because a package index cached inside a
layer is dead weight shipped to every user of the image.

**Combine related `RUN` steps.** `RUN apt-get update && apt-get install -y foo
&& rm -rf /var/lib/apt/lists/*` in one instruction, because deleting a file in
a *later* layer does not reclaim the space, the earlier layer still contains
it. A secret written and then removed in a later step is still in the image,
which is worth remembering.

<details class="deeper">
<summary>If you already administer Linux: overlayfs, and image size that will not go down</summary>

The layer stack is **overlayfs**, an ordinary kernel filesystem. Lower layers are
read-only, an upper layer is writable, and the kernel presents the union.

Two behaviours explain most surprises.

**Copy-up.** Modifying a file in a lower layer copies the whole file into the
upper layer first. Changing one byte of a 2 GB file writes 2 GB, which is why
containers are a poor host for large mutable files and why databases belong on
volumes rather than in the layer stack.

**Whiteouts.** Deleting a file from a lower layer does not remove it; it creates a
whiteout marker in the upper layer that hides it. The bytes are still in the image
and still shipped.

That is why `RUN rm -rf /tmp/build` in a later instruction does not shrink the
image, and why a secret copied in and deleted later is still extractable:
`podman history` and `podman save` both expose it, and this is a real and
common leak.

**Fixes, in order of preference:** delete within the *same* `RUN` that created the
files; use a **multi-stage build**, where a build stage compiles and a final stage
copies only the artefact:

```dockerfile
FROM golang:1.23 AS build
WORKDIR /src
COPY . .
RUN go build -o /app

FROM alpine:3.20
COPY --from=build /app /app
CMD ["/app"]
```

That is the standard answer for compiled languages and routinely turns a 900 MB
image into 15 MB. Or `--squash` to flatten, which loses layer sharing and is a
blunter instrument.

**`podman system df`** shows what storage is going where (images, containers,
volumes, build cache) and `podman system prune -a` reclaims it. **`--volumes`
is not included by default**, which is deliberate and merciful, and means a
prune will not silently destroy your database.

</details>

## Networking

The container below was started with `--name web`. The command runs `hostname`
inside it.

<details class="predict">
<summary>The container has a name you chose. Does <code>hostname</code> inside it report that name, and if not, what does it report?</summary>

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

</details>

**The container ID, not the name.** `--name web` is a label the *runtime*
keeps so you can say `podman exec web`; the UTS namespace inside gets the
short container ID as its hostname unless you pass `--hostname` explicitly.
That trips up anything inside the container that identifies itself by
hostname, application logs, metrics, and clustering software all report an ID
that changes every time the container is recreated.

It also means the name is not resolvable by DNS on the default bridge, which is
what the rest of this section is about.

| Mode | Means |
| --- | --- |
| `bridge` | The default. A private network; reachable via `-p`. |
| `host` | Shares the host's network stack directly. No isolation, no `-p`. |
| `none` | No network at all |
| A user-defined network | A bridge with **DNS between its members** |

**A user-defined network is the one worth knowing**, because it changes how
containers find each other:

```
podman network create appnet
podman run -d --name db --network appnet postgres:16
podman run -d --name web --network appnet -p 8080:80 myapp:1.0
```

On a user-defined network, containers resolve each other by name. The
application connects to `db:5432` and the engine's DNS resolves it, no IP
addresses, no link flags, and it survives containers being recreated with
different addresses.

On the default bridge there is no such DNS, which is why "connect by container
name" advice sometimes works and sometimes does not.

`--network host` removes the isolation entirely: the container uses the host's
interfaces and ports, `-p` becomes meaningless, and a service binding port 80
binds the host's port 80. Occasionally necessary for performance or for
software that needs to see real interfaces; a significant loss of isolation
otherwise.

The database in that example has no `-p`, and that is correct. It is reachable
from `web` over `appnet` and from nowhere else. Publishing a database port to
the host is a common and unnecessary exposure.

<details class="deeper">
<summary>If you already administer Linux: SELinux on bind mounts, and rootless UID mapping</summary>

Two things make bind mounts fail with permission errors that look wrong.

**SELinux, on the RHEL family.** A host directory does not carry a label the
container is allowed to access, so every read is denied while `ls -l` looks
perfect. The `:z` and `:Z` suffixes relabel it:

```
-v /srv/data:/data:Z     # private label, this container only
-v /srv/data:/data:z     # shared label, several containers
```

Use `:Z` with care. It **relabels the host directory in place**, recursively.
Pointing it at `/home` or a system directory relabels that directory for real,
and undoing it means `restorecon -R`. `ausearch -m AVC -ts recent` confirms
SELinux is the cause before you reach for either.

**Rootless UID mapping** is the other one. In a rootless container, root inside is
your unprivileged UID outside, and other UIDs map into a subordinate range from
`/etc/subuid`. So a file the container creates as UID 1000 appears on the host
as something like 101000, and a host file you own appears inside as `nobody`.

`podman unshare` runs a command inside that user namespace, which is how you fix
ownership so both sides agree:

```
podman unshare chown -R 1000:1000 /srv/data
```

`--userns=keep-id` maps your host UID to the same UID inside, which is usually
what you want for development bind mounts and removes the problem entirely.

**The general rule:** a permission error on a bind mount is one of three
things, ordinary Unix permissions, SELinux labelling, or rootless UID mapping.
Check them in that order, and `ausearch` distinguishes the second from the
other two immediately.

</details>

<details class="deeper">
<summary>If you already administer Linux: tags, digests, and what supply chain means here</summary>

A tag is a mutable pointer. `nginx:latest` today and in a month are different
images, and nothing records which one a machine pulled. That reintroduces
exactly the reproducibility problem containers were meant to solve.

A digest is immutable. `nginx@sha256:abc123...` names one specific image
forever. Production deployments should pin digests, and `podman inspect
--format '{{.Digest}}'` gets one, which is how the captured output in this
track stays reproducible: every image it was run on is pinned by digest rather
than by tag.

The pragmatic middle: pin a real version tag (`nginx:1.26.3`) in development,
pin digests in production.

**Image signing** is the packaging lesson arriving again. `cosign` and
podman's `policy.json` verify that an image came from who it claims, the same
origin and integrity properties, and the same limits: it says nothing about
whether the software is safe.

**Scanning** (`trivy`, `grype`) reports known vulnerabilities in an image's
packages. Worth running in CI, and worth understanding: it finds *known*
issues in *packaged* components, so a vulnerability in your own code is
invisible to it.

Base image choice is most of your attack surface. `alpine` is 8 MB;
`debian:slim` is 30; a full distribution image is 200 or more, most of it
software you will never run and all of it needing patching. **Distroless**
images go further and contain only the application and its runtime (no shell,
no package manager) which is excellent for security and means `podman exec`
gives you nothing to debug with. `nsenter` from the previous lesson is the
answer there.

And images need rebuilding, not just applications. A container built six
months ago has six months of unpatched base packages, however current your
code is. Rebuilding on a schedule is a patching obligation that people
frequently do not realise they have taken on.

</details>

## Across distributions

The image format is OCI and interchangeable everywhere. What differs is where
things are stored and which extra restriction applies:

| | RHEL family | Debian family |
| --- | --- | --- |
| Storage, rootful | `/var/lib/containers/storage/` | `/var/lib/docker/` |
| Storage, rootless | `~/.local/share/containers/` |, |
| Mandatory access control | **SELinux**, needs `:z`/`:Z` | AppArmor, more permissive |
| Volume location | `/var/lib/containers/storage/volumes/` | `/var/lib/docker/volumes/` |

**The `:Z` requirement is the practical difference.** A bind mount that works on
Ubuntu fails on RHEL with a permission error and identical file permissions, and
that is SELinux.

## Prove it

```bash
# What is attached to this container
podman inspect thename --format '{{range .Mounts}}{{.Type}} {{.Source}} -> {{.Destination}}
{{end}}'

# Where does this volume actually live
podman volume inspect appdata

# What is using disk
podman system df

# What layers does this image have, and how big
podman history myapp:1.0

# Can these two containers see each other
podman exec web getent hosts db
```

**That first command is the one to run before removing any container.** An empty
mount list on something holding state means its data is in the writable layer and
about to be deleted.

## What trips people up

### 1. Data in the container

The writable layer is deleted with the container, and updating an image *requires*
recreating the container.

A volume for anything durable. Check with `podman inspect` before removing
anything.

### 2. `EXPOSE` does not publish

It is documentation in the image. Only `-p` at run time forwards a port.

### 3. Permission denied on a bind mount

Three candidates, in order: ordinary permissions, SELinux labelling on the RHEL
family, and rootless UID mapping.

`ausearch -m AVC -ts recent` identifies the second. `:Z` fixes it, and
relabels the host directory for real, so never point it at a system path.

### 4. Slow rebuilds

`COPY . .` early in the file invalidates the cache for everything after it on any
source change.

Dependencies first, source last.

### 5. `latest` in production

A moving pointer. Two machines pulling it a month apart run different software.

Pin a version tag, or a digest.

## Work it through

A team's PostgreSQL container lost three weeks of data during a routine image
update. You are asked to make sure it cannot happen again.

Reason it out before reading on.

**What happened is now unambiguous.** The container had no volume, so
PostgreSQL wrote its data into the writable layer. Updating the image means
`podman rm` and `podman run` with the new tag, and `rm` deleted the layer with
everything in it.

Nothing failed. Every command reported success, and the data was destroyed by the
documented behaviour of the model.

**The fix, and each part earns its place:**

```
podman volume create pgdata

podman run -d --name db \
  --network appnet \
  -v pgdata:/var/lib/postgresql/data \
  -e POSTGRES_PASSWORD_FILE=/run/secrets/pgpw \
  --secret pgpw \
  --restart=always \
  postgres:16.4
```

A volume at the data directory, so the state lives outside any container's
lifetime. **No `-p`**, because the database is reached over `appnet` by the
application and should not be on the host's network at all. **A pinned version
tag**, not `latest`. And **the password from a secret** rather than an
environment variable, because `podman inspect` shows environment variables to
anyone who can run it.

Then verify it before trusting it, which is the step that would have caught
the original problem:

```
podman exec db psql -U postgres -c 'create table t (i int); insert into t values (1);'
podman rm -f db
podman run -d --name db --network appnet -v pgdata:/var/lib/postgresql/data ... postgres:16.4
podman exec db psql -U postgres -c 'select * from t;'
```

Deliberately destroy the container and confirm the data comes back. That is
five minutes and it is the only evidence that matters.

And the wider point for the team, because "add a volume" fixes one container:

A volume is not a backup. It lives on the same host and is removed by
`podman volume rm` or by `podman system prune --volumes`. The backup lesson still
applies: `podman exec db pg_dump` to something offsite, on a schedule, tested by
restoring.

Now the point worth extracting. **The container is the disposable part and the
data is not, and the model requires you to say which is which.** Nothing
infers it. A container with no volume is a statement that it holds nothing
worth keeping, and if that is not true, the failure arrives at the next update
rather than at the next crash, which is why it catches people who have been
running it successfully for weeks.

The habit: **`podman inspect --format '{{.Mounts}}'` before removing any
container**, and treat an empty result on anything stateful as a stop.

## Try it

Optional, on a machine with podman or docker.

1. `podman run --name t1 alpine sh -c 'echo hi > /f.txt'`, then `podman rm t1`,
   then `podman run --rm alpine cat /f.txt`. Watch it fail.
2. `podman volume create v1`, then write and read across two containers with
   `-v v1:/data`.
3. `podman volume inspect v1` and go and look at the directory on the host.
4. `podman history nginx:alpine` and find the largest layer.
5. `podman system df`, then `podman system prune` and compare.
6. `podman network create n1`, run two containers on it, and
   `podman exec one getent hosts two`.
7. Write a two-line Containerfile, build it twice, and watch the second build use
   the cache.

**Verification step.** You have it when you can look at a `podman run` command and
say whether removing that container would lose anything.

## Check yourself

<details class="qa">
<summary>Where do a container's writes go, and why are they lost when it is removed?</summary>

**Into the container's writable layer**, a thin layer stacked on top of the
image's read-only layers by overlayfs.

The image below is read-only and shared by every container started from it.
Modifying an existing file copies it up into the writable layer first,
copy-on-write, so the lower layers are never touched.

**Removing the container removes that layer**, deliberately. The model treats a
container as disposable, and its filesystem is part of what gets disposed.

That is not a flaw to work around: it is what makes containers cheap to start,
cheap to have many of, and identical every time. Anything durable is attached from
outside with a volume or a bind mount.

</details>

<details class="qa">
<summary>When would you use a volume rather than a bind mount?</summary>

**A volume for state the container owns**, database files, uploaded content,
application data. The engine manages where it lives, so nothing depends on the
host's directory layout and the same command works on any machine.

**A bind mount when the host path matters**, a config file you want to edit,
source code during development, or writing logs into a directory the host's
log shipper already watches.

The syntax difference is one character: a source containing `/` is a path and
therefore a bind mount; a source without one is a name and therefore a volume.
`-v data:/data` and `-v ./data:/data` do different things.

Bind mounts also carry two extra failure modes that volumes do not: SELinux
labelling on the RHEL family, needing `:z` or `:Z`, and UID mapping under rootless
containers.

</details>

<details class="qa">
<summary>Why does <code>COPY . .</code> early in a Containerfile make rebuilds slow?</summary>

**Because each instruction is a cached layer, and a changed instruction
invalidates every layer after it.**

`COPY . .` brings in the whole source tree, so its inputs change on every
commit. Everything below it, typically the dependency installation, is rebuilt
each time, however unrelated the change was.

**Put dependencies before source:**

```dockerfile
COPY requirements.txt .
RUN pip3 install -r requirements.txt
COPY . .
```

Now a code change only invalidates the final `COPY`, and the dependency layer is
reused. That is frequently the difference between a two-second rebuild and a
four-minute one.

The general rule: **order instructions from least to most frequently changed.**

</details>

<details class="qa">
<summary>What does <code>EXPOSE 8000</code> do, and what actually publishes a port?</summary>

**`EXPOSE` is documentation.** It records in the image's metadata that the
application expects to serve on that port, for the benefit of humans reading it
and tooling that inspects images. It opens nothing and forwards nothing.

**`-p 8080:8000` at run time is what publishes**, mapping host port 8080 to
container port 8000.

Believing otherwise is a common half-hour, because everything looks correct:
the image says `EXPOSE 8000`, the application is listening, and nothing outside
can reach it.

`podman port thename` shows what was actually published, and `ss -tlnp` on the
host confirms the other end.

</details>

<details class="qa">
<summary>Two containers are on the default bridge network and cannot reach each other by name. Why, and what fixes it?</summary>

**The default bridge has no DNS between its members.** Containers get addresses on
a shared private network and there is no name resolution, so `db` resolves to
nothing.

**A user-defined network provides DNS:**

```
podman network create appnet
podman run -d --name db --network appnet postgres:16
podman run -d --name web --network appnet myapp:1.0
```

Now `web` connects to `db:5432` and the engine's DNS resolves the name, which
also survives containers being recreated with different addresses, where a
hardcoded IP would not.

This is why "connect by container name" advice sometimes works and sometimes does
not: it depends entirely on whether the containers are on a user-defined network.

A bonus worth noticing: the database in that example needs no `-p`. It is
reachable from `web` and from nowhere else, which is the right exposure for a
database.

</details>

## References

- [Containerfile / Dockerfile reference](https://docs.docker.com/reference/dockerfile/) - Docker. Accessed 2026-08-07.
- [podman-run(1)](https://docs.podman.io/en/latest/markdown/podman-run.1.html) - Podman project. Accessed 2026-08-07.
- [podman-volume(1)](https://docs.podman.io/en/latest/markdown/podman-volume.1.html) - Podman project. Accessed 2026-08-07.
- [podman-network(1)](https://docs.podman.io/en/latest/markdown/podman-network.1.html) - Podman project. Accessed 2026-08-07.
- [OCI Image Format Specification](https://github.com/opencontainers/image-spec/blob/main/spec.md) - Open Container Initiative. Accessed 2026-08-07.
- [overlayfs](https://docs.kernel.org/filesystems/overlayfs.html) - The Linux Kernel documentation. Accessed 2026-08-07.

Every block above with a distribution and architecture header was captured by running the command on a Fedora CoreOS 44.20260707.3.1 virtual machine. Blocks without one are illustrative.
