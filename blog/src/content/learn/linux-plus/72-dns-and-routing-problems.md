---
title: "Half the names resolve and half do not"
description: "The tool you use to test DNS is not the one your application uses, and that single fact explains most name resolution mysteries. Where lookups actually go, why a cache can serve a wrong answer for hours, and how routing faults masquerade as DNS ones."
track: "linux-plus"
level: "deep"
order: 730
objectives:
  - "Explain why dig and the application can disagree about a name"
  - "Trace the order a lookup actually takes"
  - "Diagnose a stale cache and say why TTL decides the wait"
  - "Distinguish a name problem from a routing problem"
  - "Read a resolver configuration and say which server answers"
prerequisites: ["name-resolution-and-dns", "network-connectivity-troubleshooting"]
tags: ["linux", "linux-plus", "troubleshooting", "dns", "networking"]
updated: 2026-08-09
draft: false
examObjectives:
  - exam: "xk0-006"
    domain: "5.0"
    objective: "5.3"
sources:
  - title: "resolv.conf(5)"
    url: "https://man7.org/linux/man-pages/man5/resolv.conf.5.html"
    publisher: "man7.org"
    accessed: 2026-08-09
    tier: 1
  - title: "nsswitch.conf(5)"
    url: "https://man7.org/linux/man-pages/man5/nsswitch.conf.5.html"
    publisher: "man7.org"
    accessed: 2026-08-09
    tier: 1
  - title: "dig(1)"
    url: "https://bind9.readthedocs.io/en/latest/manpages.html#dig-dns-lookup-utility"
    publisher: "ISC BIND"
    accessed: 2026-08-09
    tier: 1
  - title: "systemd-resolved(8)"
    url: "https://www.freedesktop.org/software/systemd/man/latest/systemd-resolved.html"
    publisher: "freedesktop.org"
    accessed: 2026-08-09
    tier: 1
  - title: "systemd-resolved.service(8), the 127.0.0.53 stub listener and the resolv.conf modes"
    url: "https://manpages.ubuntu.com/manpages/noble/man8/systemd-resolved.service.8.html"
    publisher: "Ubuntu"
    accessed: 2026-08-09
    tier: 1
symptoms:
  - symptom: "dig resolves a name but the application cannot"
    anchor: "dig-is-not-what-your-application-uses"
  - symptom: "A DNS change has not taken effect after being made"
    anchor: "stale-answers-and-the-ttl"
  - symptom: "Short name resolves to the wrong host"
    anchor: "search-domains-and-the-short-name-trap"
---

> **Before you read.** The application cannot reach `reports.example.com`. You
> run `dig reports.example.com` and it answers immediately with the right
> address. You run it again to be sure. Still right.
>
> The application still cannot reach it, and both of you are looking at correct
> output.

`dig` and your application do not resolve names the same way. They do not read
the same files, they do not consult the same sources, and they do not
necessarily talk to the same server. Once you know that, the mystery becomes
ordinary.

### Some words you will need

<dl class="terms">
<dt>resolver</dt>
<dd>The client-side code that turns a name into an address.</dd>
<dt>NSS</dt>
<dd>Name Service Switch. The C library mechanism deciding which sources are consulted, and in what order.</dd>
<dt>stub resolver</dt>
<dd>A local service that receives queries and forwards them, often caching.</dd>
<dt>TTL</dt>
<dd>Time to live. How long an answer may be cached, in seconds.</dd>
<dt>authoritative</dt>
<dd>The server that holds the real record, rather than a copy.</dd>
<dt>NXDOMAIN</dt>
<dd>The name does not exist. Different from a server that did not answer.</dd>
<dt>search domain</dt>
<dd>A suffix appended to short names before looking them up.</dd>
<dt>split horizon</dt>
<dd>The same name answering differently depending on who asks.</dd>
</dl>

## What breaks without this

**A fix appears not to work.** The record was corrected an hour ago and half the
estate still has the old answer.

**The test contradicts the symptom.** `dig` says one thing, the application does
another, and the investigation stalls arguing about which is right.

**A short name reaches the wrong host.** Search domains silently completed it
into something that exists in a different environment.

**A routing fault is diagnosed as DNS.** The name resolved perfectly and the
address was unreachable, but the error said "could not resolve host".

## dig is not what your application uses

Here is the difference made concrete. A hosts file entry is added, and then the
same name is looked up two ways:

<details class="predict">
<summary>An entry is added to <code>/etc/hosts</code> for a name that does not exist in public DNS. What does <code>getent</code> return, and what does <code>dig</code> return?</summary>

```bash
# AlmaLinux 10.2, aarch64
$ echo "10.99.99.99 reports.example.com" >> /etc/hosts
echo "--- what the application will get, via the C library ---"; getent hosts reports.example.com
echo "--- what dig reports, because dig ignores /etc/hosts entirely ---"; dig +short reports.example.com @1.1.1.1 2>&1 | head -2; echo "dig found nothing above, because the name is not in public DNS"
--- what the application will get, via the C library ---
10.99.99.99     reports.example.com
--- what dig reports, because dig ignores /etc/hosts entirely ---
dig found nothing above, because the name is not in public DNS
```

</details>

Two tools, one name, opposite answers, and both are correct.

`getent hosts` goes through the C library's NSS machinery, which is exactly what
an application does when it calls `getaddrinfo()`. That path reads
`/etc/nsswitch.conf`, and on almost every system the `files` source comes before
`dns`, so `/etc/hosts` wins.

`dig` skips all of it. It is a DNS protocol tool: it builds a query, sends it to
a nameserver, and prints the reply. It never reads `/etc/hosts`, it does not
respect `nsswitch.conf`, and pointing it at `@1.1.1.1` bypasses your local
resolver as well.

**Which gives the rule.** When testing what an application will experience, use
`getent hosts` or `resolvectl query`. Use `dig` to ask what DNS itself contains.
When they disagree, the difference is the answer, and it is almost always
`/etc/hosts`, NSS ordering, or a local caching resolver.

**The order a lookup takes**, on a typical modern system:

1. The application calls `getaddrinfo()`.
2. NSS reads `/etc/nsswitch.conf` and works through the listed sources in order.
3. `files` reads `/etc/hosts`. A match ends it here.
4. `dns` sends a query to whatever `/etc/resolv.conf` names.
5. That may be a stub resolver on `127.0.0.53` or similar, which has its own
   cache and its own configuration.
6. The stub forwards to a real server, which may itself be a cache.
7. Eventually something authoritative answers.

Every one of those steps can cache or override, and `dig @somewhere` jumps
straight to step 7.

## Reading the configuration

Two files and one command tell you where a lookup will go.

```bash
# AlmaLinux 10.2, aarch64
$ echo "--- what the resolver is configured to use ---"; cat /etc/resolv.conf; echo "--- the order the C library tries sources in ---"; grep ^hosts /etc/nsswitch.conf
--- what the resolver is configured to use ---
search home.arpa
nameserver 169.254.1.1
nameserver 192.168.127.1
--- the order the C library tries sources in ---
grep: /etc/nsswitch.conf: No such file or directory
```

Two nameservers and a search domain. Note that `nsswitch.conf` does not exist in
this minimal container image, which is itself worth knowing: glibc falls back to
a built-in default of `files dns` when the file is absent, so the ordering still
applies even with nothing configured.

**Two things about multiple nameservers surprise people.** They are tried in
order, not load balanced, so the second is only consulted when the first fails to
answer at all. And a first server that answers **NXDOMAIN** has answered: the
resolver accepts that and never asks the second. A broken internal server that
confidently denies your internal names will not be rescued by a working
secondary.

**`/etc/resolv.conf` is frequently not what you think.** NetworkManager,
`systemd-resolved`, and DHCP clients all rewrite it, so an edit can vanish at the
next lease renewal. Check whether it is a symlink first:

```bash
ls -l /etc/resolv.conf
resolvectl status          # what systemd-resolved is actually doing, per link
```

`resolvectl status` matters on any system running `systemd-resolved`, because
`resolv.conf` may just point at a stub on `127.0.0.53` and tell you nothing about
the real servers. That command shows the per-interface configuration, which is
where a VPN adding its own DNS for one domain becomes visible.

<details class="deeper">
<summary>If you already administer Linux: search domains, and the short name that reaches the wrong host</summary>

The `search` line is a convenience that occasionally causes an outage, and the
mechanism is worth knowing exactly.

When you look up a name with fewer dots than `ndots` (default 1), the resolver
appends each search domain in turn and tries those first. So `ping db` on a host
with `search corp.example.com prod.example.com` asks for `db.corp.example.com`,
then `db.prod.example.com`, and only then `db` on its own.

**Which produces two distinct failures.**

The first is reaching the wrong host. `db` exists in both `corp` and `prod`, the
search order puts `corp` first, and a staging machine quietly talks to the
production database. Nothing errors. It just connects to the wrong thing, which
is far worse than failing.

The second is slowness. Each unsuccessful suffix is a full DNS round trip. With
four search domains and a slow server, resolving a short name takes noticeably
long, and in Kubernetes this is a well-known performance problem because the
default `ndots:5` means even names with several dots get the search treatment
first.

**The fix is to be explicit.** A trailing dot makes a name fully qualified and
skips search entirely:

```bash
getent hosts db.corp.example.com.     # the dot at the end means "exactly this"
```

Use fully qualified names in configuration files. Reserve short names for
interactive convenience where a wrong guess costs nothing.

**Diagnosing it:** `resolvectl query db` shows which name actually got answered,
and `dig +search db` makes `dig` honour the search list so you can reproduce what
the library did.

**One more source of the same shape of problem: split horizon.** The same name
answers differently depending on who asks, usually giving internal addresses
inside the network and public ones outside. It is a legitimate design and it
means "it resolves fine for me" from a laptop on a VPN proves nothing about a
server in a datacentre. When someone reports a name resolving to an unexpected
address, establish which view they were in before assuming a fault.

</details>

<details class="deeper">
<summary>If you already administer Linux: reading a dig answer, and what each record type is for</summary>

`dig` prints more than an address, and the extra parts are what turn a lookup
into a diagnosis.

**The status line is the first thing to read**, and `dig` hides it under
`+short`:

```bash
dig example.com | grep -E 'status|ANSWER:'
```

| Status | Means |
| --- | --- |
| `NOERROR` with answers | Normal |
| `NOERROR` with 0 answers | **The name exists, but not with that record type.** Very often a host with only AAAA when you asked for A |
| `NXDOMAIN` | The name does not exist at all |
| `SERVFAIL` | The server tried and failed. Often DNSSEC validation, or a broken upstream |
| `REFUSED` | The server declined to answer you. Access control |

**`NOERROR` with zero answers catches people repeatedly.** It is not a failure,
and it does not mean the name is wrong. It means you asked the wrong question,
and the record you want is a different type.

**The record types worth recognising:**

| Type | Holds |
| --- | --- |
| `A` / `AAAA` | IPv4 / IPv6 address |
| `CNAME` | An alias pointing at another name. Resolution continues from there |
| `MX` | Mail servers, with priorities |
| `TXT` | Arbitrary text. SPF, DKIM, and domain ownership proofs live here |
| `NS` | The authoritative nameservers for a zone |
| `SOA` | Zone metadata, including the serial number |
| `PTR` | Reverse lookup, address to name |

**CNAME chains are a common source of confusion.** A name that is a CNAME
resolves to another name, which may itself be a CNAME. `dig` shows every step,
and a chain that ends somewhere unexpected explains an address you did not
recognise. A CNAME cannot coexist with other records at the same name, which is
why you cannot put one at the apex of a zone.

**The SOA serial is how you check replication.** Query each authoritative server
for the zone's SOA and compare serials. A secondary lagging behind the primary
answers with old data, and it will do so consistently for whichever clients
happen to reach it, producing a fault that follows some users and not others:

```bash
for ns in $(dig +short NS example.com); do
  echo -n "$ns "; dig +short SOA example.com "@$ns" | awk '{print $3}'
done
```

**Reverse lookups fail far more often than forward ones**, and usually that is
fine. PTR records are configured separately, frequently by whoever owns the
address block rather than by you, so their absence is normal. It matters for
mail servers, which are judged on it, and for logs that resolve addresses to
names. It is rarely worth chasing otherwise.

**And `dig +short` is convenient and lossy.** It gives you the answer and hides
the status, the TTL, and whether you got a CNAME chain on the way. Use it when
you want a value for a script, and the full output when you are diagnosing.

</details>

## Stale answers and the TTL

A DNS change appearing not to work is usually a cache doing exactly what it was
told.

<details class="predict">
<summary>A name is looked up against a public resolver. What is the number between the name and the record type, and what does it govern?</summary>

```bash
# AlmaLinux 10.2, aarch64
$ echo "--- a real lookup, with the TTL that controls caching ---"; dig +noall +answer example.com @1.1.1.1
--- a real lookup, with the TTL that controls caching ---
example.com.		183	IN	A	104.20.23.154
example.com.		183	IN	A	172.66.147.243
```

</details>

The `183` is the TTL in seconds, and it is the number that governs everything
about propagation. Any cache holding this record may keep it for that long
before asking again.

**Watch it count down.** Run the same query twice a few seconds apart against a
caching resolver and the TTL decreases. That is the tell that you are being
served from cache rather than from the authoritative source, and it is how you
prove a stale answer rather than suspecting one.

**"DNS propagation" is a slightly misleading phrase**, because nothing is
pushed. Records do not travel outward; caches simply expire and ask again. A
change is therefore visible everywhere within one TTL of when caches last
fetched it, and not before.

**Which is why lowering the TTL before a planned change is the standard move.**
Drop it to 60 seconds a day ahead, make the change, then raise it afterwards. Do
that and a migration cuts over in a minute; skip it and a 24-hour TTL means a
day of split traffic.

**To see the truth rather than a cache**, query the authoritative server
directly:

```bash
dig +short NS example.com                        # who is authoritative
dig @<one-of-those> example.com                  # ask them, no cache in the way
dig +trace example.com                           # follow the delegation from the root
sudo resolvectl flush-caches                     # clear the local systemd cache
```

`+trace` is the one that finds delegation problems, because it walks from the
root servers down and shows exactly where the chain breaks.

**A caution about clearing caches.** You control yours. You do not control the
resolver at an ISP, in a browser, or inside a JVM, and Java in particular has
historically cached DNS answers for the life of the process regardless of TTL. A
name that resolves correctly from a shell and incorrectly inside a long-running
application is often that, and the fix is restarting the application.

<details class="deeper">
<summary>If you already administer Linux: telling a name problem from a routing one</summary>

The two get confused constantly, because an application error message rarely
distinguishes them. "Could not connect to host" covers both.

**Separate them in one step.** Resolve the name and connect to the address
independently:

```bash
getent hosts db.example.com          # does the name resolve, and to what
nc -vz 10.0.1.5 5432                 # does that address accept connections
```

If the name resolves and the address does not answer, this is not DNS. Go to
lesson 71's ladder. If the name does not resolve at all, it is DNS and the
address is irrelevant.

**The failure modes look different too, and the differences are reliable:**

| Symptom | Suggests |
| --- | --- |
| Instant "could not resolve host" | The resolver answered NXDOMAIN. The name genuinely is not there |
| Several seconds, then a resolution failure | The DNS server is not answering. Timeout, not denial |
| Resolves, then connection times out | Name is fine. Firewall or routing, per lesson 71 |
| Resolves to an address you do not recognise | Search domain, split horizon, or a stale cache |
| Works by address, fails by name | DNS, definitively |
| Works by name from one host, not another | Different resolvers, or split horizon |

**That second row is worth dwelling on.** A resolution failure that takes five
seconds is not the same as one that returns instantly. Instant means a server
replied "no such name". Slow means nothing replied, so you are looking at
reachability of the DNS server itself, and `nc -vzu <server> 53` tests that
directly.

**Routing problems that present as name problems** are usually one of these:

- **The resolver is unreachable.** Every lookup times out, so everything looks
  like a DNS outage when the actual fault is a route or a firewall on port 53.
- **Asymmetric routing to the DNS server**, so queries arrive and replies do
  not.
- **A VPN changing the default route** and taking DNS with it, so internal names
  work and external ones stop, or the reverse when it disconnects untidily.
- **IPv6 preferred and broken.** `getaddrinfo()` returns AAAA records first, the
  application tries IPv6, and the network has no working IPv6 path. It presents
  as a slow, intermittent connection failure that goes away when you use an IPv4
  literal. `getent ahostsv4` tests the IPv4-only path.

That last one is the most under-diagnosed item in this lesson. A dual-stack host
with broken IPv6 connectivity produces delays and failures that look like DNS,
and confirming it takes one comparison between `getent ahostsv4` and
`getent ahostsv6`.

</details>

## Across distributions

Resolution is the corner of Linux where the same question genuinely has different
answers on different machines, because what owns `/etc/resolv.conf` varies and
that file is what everything reads.

| | RHEL family | Debian family |
| --- | --- | --- |
| Who writes `/etc/resolv.conf` | NetworkManager | `systemd-resolved` on Ubuntu, `resolvconf` or nothing on Debian |
| Is it a symlink | Usually a real file | Ubuntu: symlink to `../run/systemd/resolve/stub-resolv.conf` |
| Stub resolver on 127.0.0.53 | Not by default | Ubuntu, by default |
| Query what applications get | `getent hosts` | `getent hosts`, or `resolvectl query` |
| Inspect the resolver's own view | `nmcli dev show \| grep DNS` | `resolvectl status` |
| `dig` installed | `bind-utils` package | `dnsutils` or `bind9-dnsutils` package |
| Flush the cache | Usually none to flush | `resolvectl flush-caches` |

**The stub resolver row explains a genuinely confusing hour on Ubuntu.**
`/etc/resolv.conf` says `nameserver 127.0.0.53`, which is not a real DNS server
anywhere, so reading that file tells you nothing about where queries actually
go. `resolvectl status` is the command that does, and it can show different
servers per interface, which is how a VPN gives you internal names on one link
and not on another.

The caching row matters because it changes what a stale answer means. On a
machine with no local cache, a wrong answer came from upstream. On Ubuntu it may
be sitting in `systemd-resolved`, and `resolvectl flush-caches` settles which.

## Prove it

The point of this list is that the first two commands ask different questions,
and confusing them is most of the topic:

```bash
# What DNS says, going straight to a nameserver
dig +short theserver.example.com

# What the application gets, through nsswitch and /etc/hosts
getent hosts theserver.example.com

# Where the queries are actually going
cat /etc/resolv.conf; ls -l /etc/resolv.conf
resolvectl status 2>/dev/null | head -20

# Which source is consulted first
grep ^hosts: /etc/nsswitch.conf

# Is the answer cached, and how long is left
dig theserver.example.com | grep -A1 "ANSWER SECTION"   # run twice, watch the TTL

# Where the delegation breaks, from the root down
dig +trace theserver.example.com
```

**`dig` and `getent` disagreeing is the single most useful result on this page.**
It means the name resolves correctly in DNS and something local is overriding it,
which points at `/etc/hosts` or at `nsswitch.conf`, and it takes the DNS servers
entirely out of the investigation.

## What trips people up

### 1. Testing with `dig` and concluding the application is fine

`dig` speaks DNS directly and ignores `/etc/hosts`, `nsswitch.conf`, and any
caching the C library does. An application calls `getaddrinfo`, which uses all
three. They can and do return different answers.

### 2. Expecting a second nameserver to rescue an NXDOMAIN

Servers in `resolv.conf` are a failover list for servers that fail to answer.
NXDOMAIN is an answer, so the resolver stops there. A split-horizon setup with a
public resolver listed first therefore never reaches the internal one, and it
looks like the internal zone is broken.

### 3. Editing `/etc/resolv.conf` by hand

On most machines something regenerates it: NetworkManager, `systemd-resolved`, a
DHCP client. The edit works until the next lease renewal or reboot, then
disappears, and the fault looks intermittent. Check whether it is a symlink
before touching it, and configure whatever owns it instead.

### 4. Expecting a DNS change to take effect at once

TTL is how long a cache may keep an answer, and every resolver between you and
the record has its own copy. Lower the TTL before a planned change, not
afterwards, because the old TTL governs how long the old answer survives.

### 5. Reading a timeout as a DNS fault

A name that resolves and then will not connect is not a DNS problem. `getent
hosts` returning an address means resolution succeeded, and everything after that
belongs to the previous topic.

### 6. Short names reaching the wrong environment

Search domains complete an unqualified name against each suffix in turn, so
`db` can become `db.staging.example.com` on one host and `db.prod.example.com`
on another. A trailing dot forces the name to be treated as fully qualified,
which is how you test what you meant.

## Work it through

A deployment changed a service's address two hours ago. Half the application
servers reach the new address and half still reach the old one. The TTL on the
record is 300 seconds.

Reason it out before reading on.

**Confirm the record itself is correct**, because everything downstream
assumes it:

```bash
dig +short api.example.com @<the authoritative server>
```

Say that returns the new address. The zone is right, so this is a caching or a
local-override problem rather than a DNS change that failed.

**Ask a broken host what it thinks, the way the application would:**

```bash
getent hosts api.example.com
dig +short api.example.com
```

Two outcomes, two different faults. If `getent` gives the old address and `dig`
gives the new one, something local is overriding DNS, so read `/etc/hosts` and
`nsswitch.conf`. If both give the old address, it is a cache.

**If it is a cache, find out whose.** Query twice a few seconds apart and
watch the TTL:

```bash
dig api.example.com | grep -E "^api"
sleep 5
dig api.example.com | grep -E "^api"
```

A TTL counting down proves you are reading a cached copy rather than the zone.
Two hours against a 300 second TTL means something is ignoring the TTL or the
old answer was cached with a much longer one, which is worth knowing because it
changes the fix.

**Half working and half not is the part still unexplained.** It usually means
the two halves use different resolvers:

```bash
resolvectl status 2>/dev/null | grep -A2 "Current DNS"
cat /etc/resolv.conf
```

The reasoning underneath: "DNS is broken" was never the problem. The record was
correct within seconds. What differed was what each host consulted and what each
host had remembered, and those are two different mechanisms with two different
fixes.

## Try it

Optional, and one machine is enough.

1. Add a line to `/etc/hosts` pointing a real hostname at `192.0.2.1`. Run
   `dig +short` and `getent hosts` on it and compare. Remove the line afterwards.
2. Query any public name twice, five seconds apart, and watch the TTL fall. Then
   query the authoritative server directly with `dig @` and note that its TTL
   does not move.
3. Run `dig +trace` on a name and read the referrals from the root down. Find
   the point where it stops asking the root servers and starts asking the zone's
   own nameservers.
4. Look at `/etc/resolv.conf` and work out what wrote it. Check whether it is a
   symlink, and if `systemd-resolved` is running, compare it against
   `resolvectl status`.

**Verification step.** Step 1 is right when `dig` and `getent` disagree and you
can say which one the application would believe, and why.

## For the exam

**`dig` bypasses `/etc/hosts` and NSS.** Use `getent hosts` or
`resolvectl query` to see what an application will get.

**`/etc/nsswitch.conf` sets the source order**, and `files` usually precedes
`dns`.

**Nameservers in `resolv.conf` are tried in order**, not balanced. NXDOMAIN from
the first is an answer, so the second is never asked.

**`/etc/resolv.conf` is often generated.** Check for a symlink, and use
`resolvectl status` on systemd-resolved systems.

**TTL controls how long a cached answer survives.** Lower it before a planned
change.

**A counting-down TTL on repeat queries proves you are reading a cache.**

**`dig +trace` follows delegation from the root** and finds where the chain
breaks.

**Search domains complete short names**, which can silently reach the wrong
environment. A trailing dot forces a fully qualified lookup.

**Resolves but will not connect is not a DNS problem.**

**Instant failure is NXDOMAIN; slow failure is an unreachable server.**

<details class="qa">
<summary>Check yourself</summary>

**`dig` resolves the name and the application cannot. Why?**
They use different paths. `dig` speaks DNS directly; the application goes
through NSS, which reads `/etc/hosts` first and may use a local caching stub.
Compare with `getent hosts`.

**Which command shows what the application will actually get?**
`getent hosts <name>`, or `resolvectl query <name>` on a systemd-resolved
system.

**Does `dig` read `/etc/hosts`?**
No, never.

**Your `resolv.conf` has two nameservers and internal names fail. Will the
second server save you?**
Not if the first answers NXDOMAIN. That counts as an answer, so the second is
never consulted. The second only helps when the first does not reply at all.

**Your edit to `/etc/resolv.conf` disappeared. Why?**
It is generated by NetworkManager, systemd-resolved, or a DHCP client. Check
whether it is a symlink and configure the thing that writes it.

**A record was changed 20 minutes ago and half the users see the old address.
What decides when that stops?**
The TTL on the old record. Caches keep it until it expires, then ask again.
Nothing is pushed.

**How do you prove an answer came from a cache?**
Query twice a few seconds apart. A TTL counting down means it is cached; the
authoritative server returns the full value each time.

**Which command follows the delegation chain from the root?**
`dig +trace`.

**`ping db` reaches the wrong machine. What is the likely cause?**
A search domain completed the short name into a host in a different
environment. Use the fully qualified name, with a trailing dot to be certain.

**What does a trailing dot on a name do?**
Marks it absolute, so no search domains are appended.

**A name resolves instantly to a failure. Different from taking five seconds?**
Yes. Instant means a server replied NXDOMAIN. Slow means nothing replied, so
suspect reachability of the DNS server itself.

**The name resolves and the connection times out. Is this DNS?**
No. Go to the connectivity ladder in lesson 71.

**Connections are slow and intermittent, and using the IPv4 address directly
fixes it. What would you check?**
Broken IPv6 on a dual-stack host. Compare `getent ahostsv4` with
`getent ahostsv6`.

**A name resolves correctly in a shell and wrongly inside a long-running Java
process. Why?**
The JVM has historically cached DNS answers for the process lifetime regardless
of TTL. Restart it.

</details>

## Where this sits

Lesson 18 explained how name resolution works. This lesson is what to do when it
appears not to, and most of that turns out to be about which resolver answered
rather than about DNS being broken. Lesson 71 owns the rungs below it, and the
first job here is usually deciding which of the two lessons you are actually in.


## References

- [resolv.conf(5)](https://man7.org/linux/man-pages/man5/resolv.conf.5.html) - man7.org. Accessed 2026-08-09.
- [nsswitch.conf(5)](https://man7.org/linux/man-pages/man5/nsswitch.conf.5.html) - man7.org. Accessed 2026-08-09.
- [dig(1)](https://bind9.readthedocs.io/en/latest/manpages.html#dig-dns-lookup-utility) - ISC BIND. Accessed 2026-08-09.
- [systemd-resolved(8)](https://www.freedesktop.org/software/systemd/man/latest/systemd-resolved.html) - freedesktop.org. Accessed 2026-08-09.
- [systemd-resolved.service(8), the 127.0.0.53 stub listener and the resolv.conf modes](https://manpages.ubuntu.com/manpages/noble/man8/systemd-resolved.service.8.html) - Ubuntu. Accessed 2026-08-09.
> **The commands here were run on a real machine, not written from memory.** The
> transcripts come from AlmaLinux 10.2 on aarch64. The `/etc/hosts` entry really
> was added during that capture, which is why `getent` and `dig` disagree in the
> way they do. The missing `nsswitch.conf` is genuine and worth the note in the
> text: that image does not ship one, and glibc falls back to `files dns` anyway.
> The TTL of 183 is whatever the cache happened to be holding at that moment.