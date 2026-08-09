---
title: "One container is easy, forty are not"
description: "Orchestration is what you reach for when containers have to find each other, survive a crash without you, and be replaced without downtime. Compose, Swarm, and the Kubernetes vocabulary the exam expects, and the ideas underneath, demonstrated on a real machine."
track: "linux-plus"
level: "deep"
order: 620
objectives:
  - "Read a Compose file and say what it will create"
  - "Explain what a pod is and what its containers actually share"
  - "Describe how a restart policy differs from a health check"
  - "Name the Swarm objects (node, service, task) and how they relate"
  - "Define the core Kubernetes objects: Pod, Deployment, Service, Volume, ConfigMap, Secret"
  - "Explain why a Kubernetes Secret is not encryption"
  - "Say what desired state means when applied to running workloads"
prerequisites: ["containers-the-basics", "cicd-and-gitops"]
tags: ["linux", "linux-plus", "containers", "kubernetes", "orchestration", "compose", "swarm"]
updated: 2026-08-09
draft: false
examObjectives:
  - exam: "xk0-006"
    domain: "4.0"
    objective: "4.1"
sources:
  - title: "Compose file specification"
    url: "https://docs.docker.com/reference/compose-file/"
    publisher: "Docker"
    accessed: 2026-08-09
    tier: 1
  - title: "Swarm mode key concepts"
    url: "https://docs.docker.com/engine/swarm/key-concepts/"
    publisher: "Docker"
    accessed: 2026-08-09
    tier: 1
  - title: "Kubernetes concepts: Pods"
    url: "https://kubernetes.io/docs/concepts/workloads/pods/"
    publisher: "Kubernetes"
    accessed: 2026-08-09
    tier: 1
  - title: "Kubernetes concepts: Secrets"
    url: "https://kubernetes.io/docs/concepts/configuration/secret/"
    publisher: "Kubernetes"
    accessed: 2026-08-09
    tier: 1
  - title: "podman-pod(1)"
    url: "https://docs.podman.io/en/latest/markdown/podman-pod.1.html"
    publisher: "Podman"
    accessed: 2026-08-09
    tier: 1
  - title: "podman-kube-play(1)"
    url: "https://docs.podman.io/en/latest/markdown/podman-kube-play.1.html"
    publisher: "Podman"
    accessed: 2026-08-09
    tier: 1
symptoms:
  - symptom: "Container restarts endlessly and the orchestrator reports it as running"
    anchor: "self-healing-and-what-it-does-not-know"
  - symptom: "Two containers cannot reach each other by name"
    anchor: "compose-the-first-real-step-up"
  - symptom: "Kubernetes Secret readable in plain text after base64 decoding"
    anchor: "configmaps-and-secrets"
---

> **Before you read.** You have a container. It runs, you can reach it on a
> port, and lesson 35 covered how it works. Now the application needs a
> database, a cache, a reverse proxy, and a background worker. They have to find
> each other. They have to start in a sensible order. If one dies at 3am
> something should restart it. And when you deploy a new version, the site
> should not go down while it happens.
>
> **You could write all of that in shell.** People did, for about eighteen
> months, and then stopped.

Orchestration is the layer that answers those questions. This lesson is scoped
to the vocabulary and concepts the exam objective asks for, enough to read a
Compose file, hold a conversation about a Kubernetes cluster, and know what
the words mean. It is not a Kubernetes course, and it says so at the end.

The good news is that almost everything here is one idea repeated: **you declare
what should be running, and something else continuously makes it so.** That is
the same desired-state loop from lessons 57 and 60, pointed at workloads instead
of files.

### Some words you will need

<dl class="terms">
<dt>orchestration</dt>
<dd>Managing many containers as one system: placement, networking, scaling, recovery.</dd>
<dt>Compose</dt>
<dd>A file format and tool describing a multi-container application on one host.</dd>
<dt>service</dt>
<dd>A definition of a container to run, and how many copies. The unit of scaling.</dd>
<dt>replica</dt>
<dd>One running copy of a service.</dd>
<dt>pod</dt>
<dd>One or more containers that share a network identity and are scheduled together. The unit Kubernetes actually runs.</dd>
<dt>node</dt>
<dd>A machine in a cluster that can run workloads.</dd>
<dt>task</dt>
<dd>In Swarm, one container placed on one node as part of a service.</dd>
<dt>scheduler</dt>
<dd>The component that decides which node a workload runs on.</dd>
<dt>control plane</dt>
<dd>The cluster's brain: stores desired state, schedules, and reconciles.</dd>
<dt>manifest</dt>
<dd>A YAML file declaring a Kubernetes object.</dd>
<dt>overlay network</dt>
<dd>A virtual network spanning several hosts so containers on different machines share a subnet.</dd>
<dt>ingress</dt>
<dd>How outside traffic gets into the cluster.</dd>
</dl>

## What breaks without this

**Containers cannot find each other reliably.** IP addresses change every time a
container is recreated, so anything that hardcodes one breaks on the next
deploy.

**Startup order is manual and wrong.** The application starts before the
database is accepting connections, crashes, and stays crashed because nothing
retries it.

**A crash at 3am is an outage until somebody wakes up.** There is no reason a
human should be involved in restarting a process that died.

**Scaling is a manual copy-paste.** Running four copies means four
`podman run` commands with four different port numbers, and a load balancer
config you now maintain by hand.

**Deploys are downtime.** Stop the old container, start the new one, and
whatever happened in between was an error page.

**Nothing is scheduled.** With more than one machine, deciding which host runs
what becomes a spreadsheet, and the spreadsheet is wrong within a week.

## Compose: the first real step up

Compose describes a multi-container application in one file. It solves the
single-host case, and it is where most people meet orchestration.

```yaml
services:
  web:
    image: nginx:alpine
    ports:
      - "8080:80"
    depends_on:
      - api
  api:
    image: myapp:1.4.2
    environment:
      DATABASE_URL: postgres://db:5432/app
    depends_on:
      - db
  db:
    image: postgres:16
    volumes:
      - dbdata:/var/lib/postgresql/data
    environment:
      POSTGRES_PASSWORD_FILE: /run/secrets/db_password

volumes:
  dbdata:
```

**The one line worth pausing on is `postgres://db:5432/app`.** The hostname is
`db`, the service name. Compose creates a network for the application and
registers each service in its DNS, so services address each other by name and
never need to know an IP. That single behaviour is most of what Compose is
for.

**The commands are few:**

| Command | Does |
| --- | --- |
| `docker compose up -d` | Create the network, volumes, and containers; start them |
| `docker compose down` | Stop and remove containers and the network. **Named volumes survive** |
| `docker compose down -v` | The same, and delete the volumes too. This deletes your data |
| `docker compose ps` | What is running, and on which ports |
| `docker compose logs -f api` | Follow one service's logs |
| `docker compose up -d --scale api=3` | Run three copies of `api` |
| `docker compose pull` | Fetch newer images without starting anything |
| `docker compose restart web` | Restart one service |
| `docker compose exec api sh` | A shell inside a running service |

**`down` versus `down -v` is worth memorising** in the direction that keeps your
data. The flag that looks like a tidy-up is the one that destroys the database.

<details class="deeper">
<summary>If you already administer Linux: what <code>depends_on</code> actually promises, and why your app still crashes on startup</summary>

`depends_on` is the single most misread key in the format.

**It controls start order, not readiness.** Compose starts `db` before `api`.
It does not wait for PostgreSQL to finish initialising, bind its socket, and
accept connections, it waits for the *container* to be started, which happens
in milliseconds while the database takes several seconds.

So the classic first experience of Compose is: `up -d`, the API crashes with
"connection refused", you restart it by hand and it works, and you conclude
Compose is flaky. It is doing exactly what it documented.

**There are two real fixes.**

**Declare a health check and depend on it.** The longer form of `depends_on`
takes a condition:

```yaml
  db:
    image: postgres:16
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 5s
      timeout: 3s
      retries: 10
      start_period: 30s
  api:
    depends_on:
      db:
        condition: service_healthy
```

Now `api` is not started until `pg_isready` succeeds. Note `start_period`:
failures during it do not count toward `retries`, which is what stops a
slow-starting service being declared unhealthy while it is legitimately booting.

**Or make the application retry**, which is the better answer and the one
production forces on you anyway. A database connection can drop at any moment
during normal operation, not only at startup. An application that cannot
reconnect has a bug that a start-order fix merely hides, and in a real cluster
nothing guarantees ordering at all, because a node can be rebooted at any
time.

**Three more things people trip over:**

**`docker-compose` and `docker compose` are different programs.** The
hyphenated one is the original Python v1 implementation, now end-of-life. The
space-separated one is the Go plugin, v2, and is what you should be using. The
file format was also renamed: `docker-compose.yml` still works, `compose.yaml`
is the current name, and the top-level `version:` key is obsolete and ignored.

**Podman speaks Compose but needs help.** `podman compose` delegates to an
external provider, `podman-compose` or `docker-compose`, and if neither is
installed it fails with "looking up compose provider failed". Podman's native
equivalents are `podman kube play` and Quadlet.

**`--scale` and published ports conflict.** You cannot run three replicas each
publishing `8080:80` on one host; the second collides. Either publish a range,
or put a proxy in front, which is the point at which a single host has stopped
being enough and you want a real orchestrator.

</details>

## The pod: several containers, one network identity

Kubernetes does not schedule containers. It schedules **pods**, and a pod is one
or more containers that share a network namespace and are always placed
together. Podman implements the same object, which means the concept can be
demonstrated on one machine.

Create a pod and put two containers in it:

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ podman pod create --name app --publish 8080:80 >/dev/null; podman run -d --pod app --name worker docker.io/library/almalinux:10 sleep 300 >/dev/null; podman run -d --pod app --name sidecar docker.io/library/almalinux:10 sleep 300 >/dev/null; podman pod ps --format "{{.Name}} {{.Status}} {{.NumberOfContainers}}"; echo "--- what is in it ---"; podman ps --pod --format "{{.Names}} {{.Pod}}"
app Running 3
--- what is in it ---
ddf75d92570b-infra ddf75d92570b
worker ddf75d92570b
sidecar ddf75d92570b
```

**Two containers were created and the pod reports three.** The extra one is the
**infra container**: it does nothing except exist, holding the namespaces open
so that the containers you care about can come and go without the pod losing its
network identity or its published port. Kubernetes has the same thing, called
the pause container.

Now the claim that the containers "share a network". A namespace has an inode
number, and two processes in the same namespace see the same one:

<details class="predict">
<summary>Each container prints <code>readlink /proc/self/ns/net</code> and then <code>/proc/self/ns/pid</code>. Which of those two match between the containers, and which do not?</summary>

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ echo "--- same network namespace? compare the inode ---"; podman exec worker readlink /proc/self/ns/net; podman exec sidecar readlink /proc/self/ns/net; echo "--- but separate pid namespaces, by default ---"; podman exec worker readlink /proc/self/ns/pid; podman exec sidecar readlink /proc/self/ns/pid
--- same network namespace? compare the inode ---
net:[4026532529]
net:[4026532529]
--- but separate pid namespaces, by default ---
pid:[4026532723]
pid:[4026532726]
```

</details>

**The network inodes are identical and the PID inodes are not.** That is the
pod, stated as precisely as it can be stated. The two containers are the same
host as far as the network is concerned (same IP, same port space, they reach
each other on `localhost`) while remaining separate as far as processes are
concerned.

**Which explains the constraint people find surprising:** two containers in one
pod cannot both listen on port 80, because there is only one port 80 between
them.

<details class="deeper">
<summary>If you already administer Linux: what a pod shares, and the sidecar pattern this exists for</summary>

The sharing is selective, and knowing exactly what is shared explains the whole
design.

| Namespace | Shared in a pod? | Consequence |
| --- | --- | --- |
| Network | **Yes** | One IP, one port space, `localhost` between containers |
| IPC | **Yes** | Shared memory and semaphores work between them |
| UTS (hostname) | **Yes** | Same hostname, visible in the capture above, both report `app` |
| PID | **No**, by default | Each container sees only its own processes |
| Mount | **No** | Each has its own filesystem; sharing needs an explicit volume |
| User | **No** | Separate UID mappings |

**Storage is shared by declaration, not by default.** A volume defined at the
pod level and mounted into two containers is how they exchange files, and it is
the other half of the pattern.

**The point of all this is the sidecar.** One container does the job; a second,
in the same pod, does something *for* it, and gets to behave as if it were on
the same machine:

- **Log shipper.** The app writes to a file on a shared volume; the sidecar
  tails it and forwards it. The app needs no logging library and no credentials
  for the log system.
- **Service mesh proxy.** Envoy or similar intercepts all traffic in and out.
  Because it shares the network namespace it can transparently add mutual TLS,
  retries, and telemetry to an application that knows nothing about any of it.
  This is the single biggest reason pods exist in the shape they do.
- **Credential refresher.** A sidecar renews a token or a certificate and writes
  it to the shared volume. The application only ever reads a file.
- **Adapter.** Translates the app's metrics format into the one your monitoring
  expects, without touching the app.

**Init containers** are the other variant: containers that run to completion
*before* the main containers start, in order, for setup, waiting on a
dependency, running a schema migration, fetching config. If an init container
fails, the pod restarts it and the app never starts, which is the readiness
guarantee `depends_on` could not give you.

**The rule for when to add a container to a pod rather than making it its own
pod:** they belong together if they must scale together, share a lifecycle, and
share storage or localhost. If you would ever want three of one and one of the
other, they are two pods.

**`shareProcessNamespace: true`** turns on PID sharing, which lets a sidecar
see and signal the app's processes, occasionally what you want for debugging,
and a meaningful reduction in isolation between the two containers.

</details>

## Self-healing, and what it does not know

The restart policy is the simplest form of self-healing. Run a container that
crashes two seconds in, and leave it alone:

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ podman rm -f flaky >/dev/null 2>&1; podman run -d --restart=on-failure --name flaky docker.io/library/almalinux:10 sh -c "sleep 2; exit 1" >/dev/null; sleep 12; podman inspect flaky --format "restarts: {{.RestartCount}}, exit code {{.State.ExitCode}}, state {{.State.Status}}"; echo "--- a stop you asked for is not a crash ---"; podman rm -f calm >/dev/null 2>&1; podman run -d --restart=always --name calm docker.io/library/almalinux:10 sleep 600 >/dev/null; podman stop -t 0 calm >/dev/null; sleep 3; podman inspect calm --format "restarts: {{.RestartCount}}, state {{.State.Status}}"
restarts: 5, exit code 0, state running
--- a stop you asked for is not a crash ---
restarts: 0, state exited
```

**Five restarts in twelve seconds, and the state is `running`.** Nobody
intervened. That is the loop doing its job, and it is also the failure mode
worth internalising, because a monitoring dashboard reading only `state` would
show this container as healthy while it has in fact never once succeeded.

**The second half is the part people get wrong.** `--restart=always` did *not*
restart the container that was deliberately stopped: zero restarts, state
`exited`. **An orchestrator distinguishes a crash from an instruction.** You
asked for it to stop, so it stayed stopped, otherwise you could never take
anything down.

| Policy | Restarts on crash | Restarts on `stop` | Restarts on daemon/host restart |
| --- | --- | --- | --- |
| `no` (default) | No | No | No |
| `on-failure[:N]` | Yes, non-zero exit only, up to N | No | No |
| `always` | Yes, any exit | No | **Yes** |
| `unless-stopped` | Yes, any exit | No | Only if it was running when you stopped the daemon |

<details class="deeper">
<summary>If you already administer Linux: restart policy, health check, and probe are three different things</summary>

These get used interchangeably in conversation and they answer different
questions. The distinction is regularly worth marks and always worth uptime.

**A restart policy watches the process.** It acts when the main process exits.
That is all it knows. A process that is running but wedged (deadlocked, out of
file descriptors, stuck on a lock, serving 500s to every request) has not
exited, so nothing happens. This is the most common form of "the container is
up and the service is down".

**A health check watches behaviour.** You supply a command; the runtime runs it
on an interval and marks the container healthy or unhealthy:

```dockerfile
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
  CMD curl -fsS http://localhost:8080/healthz || exit 1
```

**In plain Docker or Podman, an unhealthy container is not restarted.** The
status changes and that is all. Acting on it requires an orchestrator; Swarm
does, and this is one of the concrete things Swarm adds over Compose.

**Kubernetes splits the health check into three probes**, and the split is the
part worth carrying away:

| Probe | Question | Failure action |
| --- | --- | --- |
| **Liveness** | Is this still working at all? | **Kill and restart the container** |
| **Readiness** | Can it take traffic *right now*? | **Remove it from the Service endpoints.** No restart |
| **Startup** | Has it finished booting? | Suppresses the other two until it passes |

**Readiness is the one that prevents user-visible errors**, and the one most
often left unconfigured. A pod that is briefly busy, warming a cache, or
waiting on a dependency should stop receiving requests without being killed.
Liveness would kill it, which turns a five-second blip into a full restart
cycle, and if the dependency it was waiting on is itself down, liveness probes
across the fleet will restart every pod repeatedly and turn a partial outage
into a total one.

**The standing advice, which is not obvious:** make liveness probes shallow and
readiness probes deep. Liveness should check only "is this process able to
respond", with no dependency calls at all. Readiness may check the database. If
you check the database in the liveness probe, a database blip restarts your
entire fleet.

**`CrashLoopBackOff`** is Kubernetes reporting the pattern from the capture.
The restart delay doubles (10s, 20s, 40s, up to five minutes) so a container
that cannot start does not consume the node. Seeing it means the container
exits repeatedly, and the answer is in `kubectl logs --previous`, which shows
the output of the instance that died rather than the one currently sleeping.

**And the counterpart in the capture worth naming:** `exit code 0` was reported
for a container that had crashed five times. The field reflects the *current*
instance, which was alive and had not exited. Read `RestartCount`, not the exit
code, when asking whether something is stable.

</details>

## Swarm: the same ideas across several machines

Docker Swarm is built into the Docker engine and is the gentlest introduction to
a real cluster. The exam names its objects, so know them.

| Object | Is |
| --- | --- |
| **Node** | A machine in the swarm. A **manager** holds the desired state and schedules; a **worker** runs tasks |
| **Service** | The declaration: this image, this many replicas, these ports, this network |
| **Task** | One container, placed on one node, as part of a service. The atomic unit of scheduling |
| **Stack** | A group of services deployed together, from a Compose file |

```bash
docker swarm init                                  # this node becomes a manager
docker swarm join --token <worker-token> <ip>:2377 # from each other machine
docker node ls                                     # nodes and their roles
docker service create --name web --replicas 3 -p 80:80 nginx:alpine
docker service ls                                  # services and replica counts
docker service ps web                              # the individual tasks, and where they run
docker service scale web=10
docker service update --image nginx:1.27 web       # rolling update
docker stack deploy -c compose.yaml myapp          # a Compose file, across the cluster
```

**The relationship is the thing to hold:** you declare a *service* with a
replica count; the manager creates that many *tasks*; the scheduler places each
task on a *node*. If a node dies, its tasks are gone and the manager notices the
gap between three desired and two running, so it schedules a replacement
elsewhere. **Nobody restarts anything. The count is simply made true again.**

**Two networking behaviours are named in the objectives:**

**The overlay network** spans hosts. Containers on different physical machines
get addresses on one virtual subnet and reach each other directly, with service
names resolving through the swarm's internal DNS. Underneath it is VXLAN
encapsulation, which is why an overlay needs UDP 4789 open between nodes.

**The routing mesh** means a published port is published on *every* node.
Connect to port 80 on any machine in the swarm, including one running no
replicas of that service, and the request is forwarded to a node that has one.
So an external load balancer can point at all nodes without knowing or caring
where anything is scheduled.

<details class="deeper">
<summary>If you already administer Linux: where Swarm sits now, and what a rolling update is actually doing</summary>

**On Swarm's status, stated plainly**, because you will meet the question:
Docker Swarm is not deprecated, still ships in the engine, and still works. It
also lost. Kubernetes is where the ecosystem, the tooling, the hiring pool and
the managed offerings went. Swarm remains genuinely reasonable for a small
estate where the whole point is not running a control plane, and it is a
excellent way to learn the concepts, because the same ideas appear with about a
tenth of the vocabulary.

Do not confuse it with *Docker Swarm classic*, a separate pre-1.12 product that
is dead. What ships today is "swarm mode".

**The rolling update is worth understanding in detail**, because the mechanism
is identical in Kubernetes with different words:

```bash
docker service update \
  --image myapp:1.5.0 \
  --update-parallelism 2 \
  --update-delay 30s \
  --update-failure-action rollback \
  --update-order start-first \
  myapp
```

- **`update-parallelism`**, how many tasks are replaced at once. `1` is safest
  and slowest.
- **`update-delay`**, the pause between batches, which is what gives a health
  check time to notice a broken release before it reaches every replica.
- **`update-failure-action rollback`**, if updated tasks fail their health
  check, return to the previous image automatically. This is the setting that
  turns a bad deploy from an incident into a thirty-second wobble, and it is
  not the default.
- **`update-order start-first`**, bring the new task up *before* removing the
  old one. The default, `stop-first`, briefly runs below your replica count,
  which for a two-replica service means half your capacity disappears
  mid-deploy.

**All of this depends on a health check existing.** Without one, "the
container started" is the only signal available, and a container that starts
and immediately serves errors will be rolled out to every replica in perfect
health. The rolling update is not safety machinery on its own. It is machinery
that *acts* on a health signal you have to provide.

**Kubernetes translation**, so the vocabulary transfers: `maxUnavailable` and
`maxSurge` on a Deployment's `RollingUpdate` strategy are `update-parallelism`
and `start-first`; `minReadySeconds` is `update-delay`; and `kubectl rollout
undo` is the manual form of `--update-failure-action rollback`.

</details>

## The Kubernetes vocabulary

The objective asks for vocabulary, so here is the vocabulary, what each object
is, and what problem it solves. Everything below is declared in YAML,
submitted to the control plane, and continuously reconciled.

| Object | What it is |
| --- | --- |
| **Pod** | One or more containers sharing a network identity. The smallest deployable unit. **Ephemeral**. You do not create these directly |
| **ReplicaSet** | Keeps N identical pods running. Recreates them when they die |
| **Deployment** | Manages ReplicaSets to give you versioned, rolling updates and rollback. **This is what you actually write** |
| **Service** | A stable name and virtual IP in front of a changing set of pods. Load balances across them |
| **Volume** | Storage attached to a pod. A **PersistentVolumeClaim** requests durable storage that outlives the pod |
| **ConfigMap** | Non-secret configuration, injected as environment variables or files |
| **Secret** | The same, for sensitive values, with different handling |
| **Namespace** | A partition of the cluster for grouping and access control |
| **DaemonSet** | One pod on *every* node. Log collectors, monitoring agents |
| **StatefulSet** | Pods with stable identities and their own storage. Databases |
| **Job / CronJob** | Run to completion, once or on a schedule |
| **Ingress** | HTTP routing from outside the cluster to Services, by hostname and path |

**The three-layer chain is the one to be able to recite:** you write a
**Deployment**; it creates a **ReplicaSet**; the ReplicaSet creates **Pods**.
A new image means a new ReplicaSet, pods shift from old to new gradually, and
the old ReplicaSet is kept at zero replicas, which is precisely what makes
`kubectl rollout undo` possible.

**Pods are cattle, and the Service is why that works.** Pods get new IPs every
time they are recreated, so nothing addresses a pod. Everything addresses a
Service, which has a stable virtual IP and DNS name and forwards to whichever
pods currently exist and are *ready*.

| Service type | Reachable from | Typical use |
| --- | --- | --- |
| `ClusterIP` (default) | Inside the cluster only | Everything internal |
| `NodePort` | A high port on every node | Development, or behind your own load balancer |
| `LoadBalancer` | The internet, via the cloud provider | Public services on a managed cluster |
| `ExternalName` |, | A CNAME to something outside the cluster |

<details class="deeper">
<summary>If you already administer Linux: what the control plane actually is, and where the loop runs</summary>

"The cluster keeps three replicas running" is true and unhelpfully magical. It
is five ordinary Linux processes, and knowing which one does what turns most
Kubernetes troubleshooting into ordinary troubleshooting.

**On the control plane nodes:**

- **`etcd`**, a distributed key-value store. It holds *everything*: every
  object, desired and observed. It is the only stateful component, it is the
  only thing that must be backed up, and if you lose it you have lost the
  cluster. It needs an odd number of members for quorum, and it is unusually
  sensitive to disk latency, the most common cause of a mysteriously
  unresponsive cluster is slow disks under etcd.
- **`kube-apiserver`**, the only component that talks to etcd. Everything
  else, including every other control plane component, goes through its REST
  API. This is where authentication, authorisation (RBAC), and admission
  control happen, which makes it the single enforcement point for the whole
  cluster. It is stateless, so it scales horizontally behind a load balancer.
- **`kube-scheduler`**, watches for pods with no node assigned, and picks one.
  It filters nodes that cannot run the pod (insufficient CPU or memory, a
  taint it does not tolerate, a node selector that does not match, a volume
  that cannot attach there) and then scores what remains. Its entire output is
  writing a node name into the pod object. It does not start anything.
- **`kube-controller-manager`**, a bundle of controllers, each running the
  same loop: watch desired state, observe actual state, act on the difference.
  The Deployment controller creates ReplicaSets; the ReplicaSet controller
  creates Pods; the node controller notices unreachable nodes and evicts their
  pods. **This is the reconciliation loop from lesson 60, and there are dozens
  of them running concurrently.**

**On every node, including control plane nodes:**

- **`kubelet`**, the agent that actually runs containers. It watches the API
  server for pods assigned to *its* node, tells the container runtime
  (containerd or CRI-O, through the CRI interface) to start them, runs the
  probes, and reports status back. It is the only component that touches
  containers.
- **`kube-proxy`**, programmes the node's networking so that a Service's
  virtual IP reaches the right pods. Historically iptables rules, increasingly
  eBPF or IPVS, and in some CNI plugins replaced entirely.

**The property that ties it together:** no component calls another. Each one
watches the API server and writes back to it. The scheduler does not tell the
kubelet anything, it writes a node name, and the kubelet on that node notices.
This is why the control plane can lose a component and the cluster keeps
serving traffic: **existing pods keep running when the entire control plane is
down.** Nothing new gets scheduled, nothing self-heals, and `kubectl` stops
working, but the workloads are unaffected because the kubelet already knows
what it is meant to be running.

**The troubleshooting order this implies**, which is worth internalising:

| Symptom | Look at |
| --- | --- |
| Pod stuck `Pending` | The **scheduler**: `kubectl describe pod` names the reason: no resources, a taint, an unbindable volume |
| Pod stuck `ContainerCreating` | The **kubelet** on that node, image pull failure, a missing Secret or ConfigMap, a volume that will not mount |
| Pod `CrashLoopBackOff` | Your **application**: `kubectl logs --previous` |
| Pod running but unreachable | The **Service**, its selector, and readiness: `kubectl get endpoints` empty means no *ready* pod matches |
| Whole cluster unresponsive | **etcd** and the API server. Check disk latency first |

`kubectl get endpoints` returning nothing is the one that catches people
repeatedly, and it has exactly two causes: the Service's label selector does not
match any pod, or the pods match and are not passing their readiness probe.

</details>

Podman can render a running pod as a Kubernetes manifest, which is a good way to
see the shape of one without a cluster:

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ cd /var/tmp && podman kube generate app 2>/dev/null | head -40
# Save the output of this file and use kubectl create -f to import
# it into Kubernetes.
#
# Created with podman-6.0.2
apiVersion: v1
kind: Pod
metadata:
  annotations:
    io.kubernetes.cri-o.SandboxID/sidecar: ce39b5a3d4aa243f0c03fb1f69a3ac770564baee328cd491e8bbc4147a22de97
    io.kubernetes.cri-o.SandboxID/worker: ce39b5a3d4aa243f0c03fb1f69a3ac770564baee328cd491e8bbc4147a22de97
  creationTimestamp: "2026-08-09T00:49:30Z"
  labels:
    app: app
  name: app
spec:
  containers:
  - command:
    - sleep
    - "300"
    image: docker.io/library/almalinux:10
    name: worker
    ports:
    - containerPort: 80
      hostPort: 8080
  - command:
    - sleep
    - "300"
    image: docker.io/library/almalinux:10
    name: sidecar
```

**Every manifest has the same four top-level keys.** `apiVersion` and `kind` say
what sort of object this is; `metadata` names and labels it; `spec` describes
the desired state. Once you can see that pattern, an unfamiliar manifest becomes
readable even when the `spec` is not.

And because the manifest is the complete description, it round-trips:

<details class="predict">
<summary>The YAML is written to a file, the pod is destroyed entirely, and then <code>podman kube play</code> is given the file. What comes back?</summary>

```bash
# Fedora CoreOS 44.20260707.3.1 on a virtual machine, aarch64
$ podman pod rm -f app >/dev/null 2>&1; podman pod create --name app --publish 8080:80 >/dev/null; podman run -d --pod app --name worker docker.io/library/almalinux:10 sleep 600 >/dev/null; podman kube generate app > /var/tmp/app.yaml; echo "wrote $(wc -l < /var/tmp/app.yaml) lines of YAML"; podman pod rm -f app >/dev/null 2>&1; echo "--- pod destroyed, now replay the file ---"; podman kube play /var/tmp/app.yaml 2>&1 | tail -4; podman pod ps --format "{{.Name}} {{.Status}} {{.NumberOfContainers}}"
wrote 24 lines of YAML
--- pod destroyed, now replay the file ---
284990462e5609c17b1e0d169bacf7190b089f8917ebde364062465359c2c659
Container:
2d21ce93def04b235b09e74ca373f5ac4bfb155509ee02252cf732c20f06d2bf

app Running 2
```

</details>

**Twenty-four lines of text recreated the whole thing.** That is the entire
promise of declarative orchestration in one command: the running system is
disposable and the description is what you keep. It is the same claim lesson 57
made about infrastructure, applied to workloads.

## ConfigMaps and Secrets

Both inject configuration into a pod. The difference is smaller than the names
suggest, and the gap between what people assume and what is true matters.

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  LOG_LEVEL: "warn"
  MAX_CONNECTIONS: "200"
---
apiVersion: v1
kind: Secret
metadata:
  name: app-secret
type: Opaque
data:
  DB_PASSWORD: c3VwZXJzZWNyZXQ=
```

Consumed either as environment variables or as files:

```yaml
    envFrom:
      - configMapRef:
          name: app-config
    env:
      - name: DB_PASSWORD
        valueFrom:
          secretKeyRef:
            name: app-secret
            key: DB_PASSWORD
```

**`c3VwZXJzZWNyZXQ=` is base64.** Decode it and it says `supersecret`. **Base64
is an encoding, not encryption**, and anybody who can read the Secret object can
read the value with one command. The `data` field is base64 solely so that
binary values survive YAML.

**What a Secret actually gives you over a ConfigMap** is worth stating precisely,
because it is not nothing:

- It is a distinct object kind, so **RBAC can grant access to ConfigMaps and
  deny it for Secrets**. This is the real control.
- It is not written to the node's disk, Secrets are mounted in `tmpfs`, in
  memory.
- It is only sent to nodes running a pod that uses it.
- `kubectl describe` redacts the values, where `get -o yaml` does not.
- It can be encrypted at rest in etcd, **but only if the cluster administrator
  configured an `EncryptionConfiguration`.** Unencrypted is the historical
  default, and on an unmanaged cluster it is the likely state.

<details class="deeper">
<summary>If you already administer Linux: how secrets are actually handled, and the environment variable problem</summary>

Given that a Kubernetes Secret is a modest improvement over a ConfigMap, real
estates add something. Worth knowing the options and the failure modes.

**The options, roughly in order of how common they are:**

- **An external secret manager**, Vault, or the cloud provider's. The
  authoritative copy lives there, and either the **External Secrets Operator**
  syncs it into a Kubernetes Secret, or the **Secrets Store CSI driver**
  mounts it into the pod as a file without a Kubernetes Secret existing at
  all. The CSI route is stronger; the operator route is more common because it
  is easier.
- **Sealed Secrets**, you encrypt a value to a public key whose private half
  only the cluster holds, and commit the ciphertext. This is what makes
  secrets compatible with GitOps from lesson 60, since the repository can be
  public and the sealed value is useless without the cluster.
- **SOPS**, encrypting parts of a YAML file with a KMS key. Flux supports it
  directly.
- **Workload identity**, and the one worth reaching for when you can: the pod
  proves what it is to the cloud provider and receives a short-lived token, so
  there is no long-lived secret anywhere to steal. If the thing you need a
  password for is a cloud service, this usually removes the secret entirely.

**Prefer files over environment variables**, for four concrete reasons:

- **Environment variables leak into crash dumps and logs.** A stack trace that
  prints the environment is common and prints your database password with it.
- **Every child process inherits them.** If your application shells out to
  anything, the credential goes along.
- **`/proc/<pid>/environ` is readable** by anything running with sufficient
  privilege in the same context.
- **They cannot be rotated in place.** A Secret mounted as a volume is updated
  by the kubelet within about a minute when the Secret changes; an environment
  variable is fixed at process start and only changes when the pod is recreated.

The counterweight is that many applications only read configuration from the
environment, and rewriting them is not always available to you. Where it is,
mount the file.

**Two operational details that bite:**

**A ConfigMap change does not restart anything.** Mounted files update; env
vars do not; and either way the process has already read its config at
startup. The standard trick is to put a hash of the config into the pod
template's annotations, so changing the ConfigMap changes the pod spec and
triggers a rolling update, which is why you see `checksum/config` annotations
in Helm charts.

**`kubectl get secret -o yaml` prints the base64 to your terminal**, into your
shell history, and into any recording of your session. `kubectl describe`
redacts. Reach for `describe` by default.

</details>

<details class="deeper">
<summary>If you already administer Linux: storage, and why a Deployment is the wrong home for a database</summary>

Everything so far assumed workloads that keep nothing. Storage is where the
"cattle not pets" model meets its limit, and the objects reflect that.

**A `Volume` is scoped to the pod.** An `emptyDir` is scratch space that
exists as long as the pod does and is deleted with it, useful for a cache, or
for handing files between containers in a pod. It is not durable in any sense.

**Durable storage is a two-object dance**, and the split is deliberate:

- A **PersistentVolume (PV)** is the actual storage, an EBS volume, an NFS
  export, a Ceph RBD image. Cluster-scoped, and usually created automatically.
- A **PersistentVolumeClaim (PVC)** is a request: "I need 20Gi, read-write-once".
  Namespaced, written by the application author.
- A **StorageClass** describes a *kind* of storage the cluster can provision on
  demand, so a PVC gets a PV created for it without an administrator involved.

The point of the indirection is that the application declares what it needs and
stays ignorant of what actually provides it, so the same manifest works on a
laptop cluster and on three different clouds.

**Access modes constrain more than people expect.** `ReadWriteOnce` (the
common case, and what every cloud block volume gives you) means one *node* may
mount it. Not one pod: one node. `ReadWriteMany` needs a filesystem that
supports it, such as NFS or CephFS, and most block storage simply cannot do
it. Discovering this at the point where you scale a Deployment from one
replica to two is a rite of passage.

**Which leads to why a database does not belong in a Deployment.** A Deployment
treats its pods as interchangeable: same PVC, same name pattern, any order,
replaced freely. A database needs the opposite of all of that.

**A StatefulSet gives each pod:**

- **A stable ordinal name** (`db-0`, `db-1`, `db-2`) that survives
  rescheduling. A replica can be told to follow `db-0` by name.
- **Its own PVC**, created from a template, that follows that ordinal. `db-1`
  reattaches to `db-1`'s data, always.
- **Ordered, one-at-a-time operations.** `db-0` is ready before `db-1` starts,
  and scale-down goes in reverse. Clustered databases need exactly this.
- **A stable network identity** through a headless Service, so `db-0` has a
  predictable DNS name.

**And the honest caveat**, because the exam will not ask it but your job
might: a StatefulSet gives a database the primitives it needs and none of the
operational knowledge. It will not manage failover, promote a replica, take a
backup, or run a restore. That knowledge lives in an **operator**, or in a
managed database service. "We put PostgreSQL in a StatefulSet" is the
beginning of a project, not the end of one, and for a great many teams the
correct answer remains a managed database with the cluster running only
stateless workloads.

</details>

## Where this stops

The objective is scoped to vocabulary, and this lesson honours that.
Everything beyond it (writing real manifests, `kubectl` in anger, RBAC,
network policy, Helm, operators, cluster upgrades, etcd backups, autoscaling,
admission control) is a subject of its own and is not on this exam.

**What is fair to expect of you here:** read a Compose file and say what it
creates; explain what a pod is; name the Kubernetes objects and what each is
for; and describe desired-state reconciliation without hand-waving.

If you want to go further afterwards, the path most people find works is to
run a single-node cluster locally (`kind`, `k3s`, or `minikube`) and deploy
something you wrote yourself. The concepts in this lesson are the ones that
make that possible; the rest is practice.

## For the exam

**Compose is one host. Swarm and Kubernetes are many.** If a question involves
several machines, Compose is not the answer.

**`docker compose down -v` deletes volumes.** Without `-v`, named volumes
survive.

**Services find each other by service name**, resolved by the orchestrator's
internal DNS. Never by IP.

**A pod is the smallest deployable unit in Kubernetes**, and may hold more than
one container sharing a network namespace.

**You deploy a Deployment, not a Pod.** The chain is Deployment, then
ReplicaSet, then Pods.

**A Service gives a stable address in front of ephemeral pods.** ClusterIP is
internal, NodePort exposes a port on each node, LoadBalancer asks the cloud for
one.

**A Secret is base64-encoded, not encrypted.** Expect to be asked.

**ConfigMap for non-sensitive configuration, Secret for sensitive.**

**Swarm objects: node, service, task.** A service is the declaration; a task is
one container of it on one node.

**Restart policies act on exit, health checks act on behaviour**, and a
deliberate stop is not a crash.

<details class="qa">
<summary>Check yourself</summary>

**In a Compose file, what hostname does the `api` service use to reach the
`db` service?** `db`, the service name. Compose registers services in the
application network's DNS.

**Your API container crashes on `up -d` with "connection refused" to the
database, and works when restarted. Why?**
`depends_on` controls start order, not readiness. The database container had
started but was not yet accepting connections. Use a health check with
`condition: service_healthy`, or make the app retry.

**A pod has two containers. How many IP addresses does it have?** One. They
share a network namespace, demonstrated above by both reporting the same
`net:` inode.

**Why can two containers in the same pod not both listen on port 80?**
Because they share one port space. There is only one port 80 in that namespace.

**What is the extra container in a three-container pod you only put two
containers into?** The infra container, the pause container in Kubernetes. It
holds the shared namespaces open so the pod keeps its identity as containers
come and go.

**A container has restarted five times in twelve seconds. What does its state
field say?**
`running`. Which is why `RestartCount` matters and the state alone can mislead
you. Kubernetes names this `CrashLoopBackOff`.

**You `docker stop` a container with `--restart=always`. Does it come back?**
No. A deliberate stop is not a crash. It would come back after a *daemon*
restart, which is what distinguishes `always` from `on-failure`.

**Liveness probe fails. Readiness probe fails. What happens in each case?**
Liveness failure restarts the container. Readiness failure removes it from the
Service endpoints without restarting it.

**Why should a liveness probe not check the database?**
Because a database outage would then restart every pod in the fleet, turning a
partial failure into a total one. Liveness shallow, readiness deep.

**In Swarm, what is the relationship between a service and a task?**
A service is the declaration including a replica count; a task is one container
of that service placed on one node. The manager creates tasks to satisfy the
count.

**What does the routing mesh do?** Publishes a service's port on every node in
the swarm, forwarding to a node that has a replica, so an external load
balancer need not know where anything is scheduled.

**Deployment, ReplicaSet, Pod: what creates what?**
The Deployment creates ReplicaSets; a ReplicaSet creates Pods. New image, new
ReplicaSet, which is what makes rollback possible.

**Is a Kubernetes Secret encrypted?**
Not by default. The value is base64-encoded. Encryption at rest in etcd is a
cluster configuration the administrator must enable, and the real protection a
Secret offers is that RBAC can control it separately from ConfigMaps.

**Why prefer mounting a secret as a file over an environment variable?**
Environment variables leak into crash dumps and logs, are inherited by every
child process, are readable via `/proc/<pid>/environ`, and cannot be rotated
without recreating the pod. A mounted secret is updated in place.

**Why would a database go in a StatefulSet rather than a Deployment?** Stable
ordinal names, a per-pod PersistentVolumeClaim that follows the pod, and
ordered start-up and shut-down, none of which a Deployment provides.

**What is a DaemonSet for?**
Running exactly one pod on every node. Log shippers and monitoring agents.

</details>

## Where this sits

Lesson 35 gave you a container. This lesson is what happens when there are
forty. Lesson 60's reconciliation loop is the same loop the control plane
runs, pointed at pods rather than files, and Argo CD and Flux exist precisely
to connect the two.

The last lesson in this block is about a tool that will happily write all of
this YAML for you, and what you owe your colleagues before you run it.

> **The commands here were run on a real machine, not written from memory.**
> The pod, namespace, restart, and manifest transcripts come from Fedora
> CoreOS 44.20260707.3.1 on aarch64, a virtual machine, with Podman 6.0.2
> running the pods natively. Podman implements the same pod object as
> Kubernetes, which is why the namespace inodes can be compared directly. The
> Swarm and Kubernetes command listings are from the vendor documentation in
> the sources rather than from a running cluster, and are shown without
> captured output for that reason.
