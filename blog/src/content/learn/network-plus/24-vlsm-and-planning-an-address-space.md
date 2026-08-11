---
title: "VLSM and planning an address space"
description: "Six subnets of wildly different sizes and one /22 to fit them in. Allocating largest first and why the order is not a preference, what summarisation buys and what it costs you if you allocate badly, and how to leave room to grow without wasting the space."
deck: "Six subnets, wildly different sizes, one /22"
track: "network-plus"
level: "working"
order: 250
objectives:
  - "Allocate subnets of different sizes from one block without gaps or overlaps"
  - "Say why largest first is required rather than merely tidy"
  - "Summarise a set of contiguous networks into one prefix"
  - "Recognise an allocation that cannot be summarised and say why"
  - "Read somebody else's address plan and find its problems"
prerequisites: ["subnetting-by-hand"]
tags: ["network-plus", "networking", "subnetting"]
updated: 2026-08-10
draft: false
examObjectives:
  - exam: "n10-009"
    domain: "1.0"
    objective: "1.7"
sources:
  - title: "RFC 1878, Variable Length Subnet Table For IPv4"
    url: "https://www.rfc-editor.org/rfc/rfc1878"
    publisher: "IETF"
    accessed: 2026-08-10
    tier: 1
  - title: "RFC 4632, Classless Inter-domain Routing (CIDR)"
    url: "https://www.rfc-editor.org/rfc/rfc4632"
    publisher: "IETF"
    accessed: 2026-08-10
    tier: 1
  - title: "ipcalc"
    url: "https://jodies.de/ipcalc"
    publisher: "Krischan Jodies"
    accessed: 2026-08-10
    tier: 2
symptoms:
  - symptom: "An address plan cannot be summarised and the routing table keeps growing"
    anchor: "summarisation-and-what-it-needs"
  - symptom: "A subnet ran out and there is no adjacent space to grow into"
    anchor: "leaving-room-without-wasting-it"
---

> **Before you read.** You have `172.16.0.0/22` and six networks to fit inside it:
> 500 machines, 250, 120, 60, 28 and 12.
>
> Equal-sized subnets would need every one to be as big as the largest, and six
> networks of 500 does not fit in a /22 twice over.
>
> **How do you fit them, and does the order you allocate in matter?**

Topic 06 divided a network into equal pieces, which is the version the exam
introduces first and the version that wastes the most space. Real requirements are
never equal, and fitting unequal ones into a fixed block is a different skill with
one rule that is not optional.

### Some words you will need

<dl class="terms">
<dt>VLSM</dt>
<dd>Variable length subnet masking. Different prefix lengths inside one address space, chosen per network.</dd>
<dt>summarisation</dt>
<dd>Advertising several contiguous networks as one shorter prefix. Also called aggregation.</dd>
<dt>contiguous</dt>
<dd>Adjacent, with nothing in between. What summarisation requires.</dd>
<dt>discontiguous</dt>
<dd>Split by something else, so no single prefix covers it without covering that too.</dd>
<dt>address plan</dt>
<dd>The written record of which range is which. The output of this topic.</dd>
</dl>

## What breaks without this

**The plan does not fit and you find out during the build.** Equal-sized subnets
sized for the largest requirement waste most of a block, and the arithmetic that
shows this before anybody orders anything takes ten minutes.

**The routing table never stops growing.** An allocation that cannot be
summarised means every site advertises every subnet individually, forever.

**A network fills up and has nowhere to go.** Growth needs adjacent free space,
and adjacency is decided when the plan is written rather than when the growth
happens.

## Largest first, and why it is a rule

The procedure is short. Sort the requirements largest to smallest, take each one
from the start of what remains, and keep going.

Sorting is not tidiness. Allocate a small network first and it lands at the start
of the block, and every larger network after it now has to start at a boundary
that is a multiple of its own size. A /23 must begin at a multiple of 512, and if
a /28 is sitting at the start then the first available /23 boundary is 512
addresses in, with almost all of the space between them unusable.

Largest first avoids that because each allocation naturally lands on a boundary
the next, smaller one can follow.

<details class="predict">
<summary>Six requirements of 500, 250, 120, 60, 28 and 12 machines, into one /22. What prefix does each get, and what is left?</summary>

```bash
# Debian 13 (trixie), x86_64
$ apt-get update -qq >/dev/null 2>&1; apt-get install -y -qq ipcalc >/dev/null 2>&1; ipcalc -n -b 172.16.0.0/22 -s 500 250 120 60 28 12 | grep -E "^(Netmask|Network|Needed|Used|Unused)|^172\."
Netmask:   255.255.252.0 = 22   
Network:   172.16.0.0/22        
Netmask:   255.255.254.0 = 23   
Network:   172.16.0.0/23        
Netmask:   255.255.255.0 = 24   
Network:   172.16.2.0/24        
Netmask:   255.255.255.128 = 25 
Network:   172.16.3.0/25        
Netmask:   255.255.255.192 = 26 
Network:   172.16.3.128/26      
Netmask:   255.255.255.224 = 27 
Network:   172.16.3.192/27      
Netmask:   255.255.255.240 = 28 
Network:   172.16.3.224/28      
Needed size:  1008 addresses.
Used network: 172.16.0.0/22
Unused:
172.16.3.240/28
```

</details>

Six subnets, each sized to its requirement, and one /28 left over.

Read the prefixes against the requirements. 500 machines needs a /23, because a
/24 gives 254 usable and that is short. 250 needs a /24 at 254 usable, which is
tight. 120 gets a /25, 60 gets a /26, 28 gets a /27 and 12 gets a /28.

Then read the boundaries. The /23 starts at `172.16.0.0`, the /24 at `172.16.2.0`,
the /25 at `172.16.3.0`, and each one begins exactly where the last ended. No gaps
and no overlaps, and every network sits on a boundary that is a multiple of its
own size, which is what makes it valid.

`Needed size: 1008 addresses` against the /22's 1024 says how tight this is. The
same six requirements as equal subnets would each need to be a /23, and six /23s
is 3072 addresses, three times what is available.

**That is the argument for VLSM in one number.** The requirement fits with 16
addresses to spare, and the naive version misses by a factor of three.

<details class="deeper">
<summary>If you already work on networks: doing it by hand, and the check that catches every mistake</summary>

The tool agreed with the arithmetic, and the exam has no tool. Doing it by hand
is four steps and one check.

Convert each requirement to a prefix first, before allocating anything. Add two to
each requirement for the network and broadcast addresses, round up to a power of
two, and that gives the block size. 500 plus 2 is 502, rounds to 512, so a /23.
250 plus 2 is 252, rounds to 256, a /24. Doing this for all of them first tells
you whether the total even fits before you waste time laying it out.

Sort largest to smallest.

Then allocate in order, each starting where the last one ended.

The check that catches everything: **every network address must be a multiple of
its own block size.** A /25 has 128 addresses, so it can only start at .0 or .128
within an octet. A /26 has 64, so .0, .64, .128 or .192. If an allocation lands
somewhere else, something earlier was wrong, and you have found it before it
became a configuration.

The second check is the running total. Add the block sizes as you go and compare
against the parent. In the capture that is 512 plus 256 plus 128 plus 64 plus 32
plus 16, which is 1008 out of 1024.

The mistake worth naming because it is so easy to make under time pressure: using
the requirement rather than the block size when working out where the next network
starts. The 500 machine network occupies 512 addresses, not 500, and the next one
begins at 512.

</details>

## Summarisation, and what it needs

The reason to care about the order beyond making things fit is what a tidy
allocation lets you do afterwards.

Summarisation is advertising several contiguous networks as one shorter prefix.
Instead of a site announcing six routes, it announces `172.16.0.0/22` and every
router elsewhere carries one entry. The traffic still reaches the right place,
because the site knows its own internal detail and nobody else needs it.

That works only when the networks are contiguous and aligned. Six subnets filling
one /22 summarise to that /22 exactly. The same six scattered across a /16 with
other people's networks in between cannot be summarised at all, because any prefix
covering all of them also covers things that are somewhere else entirely.

Three things summarisation buys, and they compound at scale.

Smaller routing tables everywhere, which is memory and lookup time on every
router in the network.

Stability. A subnet inside a summarised block going up and down does not cause
routing updates elsewhere, because the summary is still valid. Without
summarisation, every flap propagates.

Faster convergence, because there is less to recalculate.

**The cost is that it has to be designed in.** Summarisation is a consequence of
how addresses were allocated, and the allocation happened years before anybody
wanted to summarise. This is the same argument topic 06's panel made about keeping
spare space contiguous, arriving with numbers attached.

<details class="deeper">
<summary>If you already work on networks: discontiguous networks, and the fault they produce</summary>

A discontiguous network is one address block split by another, so no single prefix
covers your parts without also covering somebody else's.

The classic version is a company that grew by acquisition. Site A has
`10.1.0.0/16`, site B has `10.3.0.0/16`, and `10.2.0.0/16` belongs to a business
unit that was sold. Nothing covering A and B avoids covering the middle.

Two consequences.

Summarisation is off the table for that pair, so both sites advertise everything
individually and the table stays large. That is a cost rather than a fault.

The fault arrives if somebody summarises anyway. Advertising `10.0.0.0/14` from
site A to make the table smaller claims `10.2.0.0/16` as well, and traffic for the
sold business unit starts arriving at site A, which drops it. Everything looks
fine from the routing table's point of view, because the route is valid and being
used, and one third party becomes unreachable for reasons nobody at either end can
see.

The version that catches people internally is subtler. Summarising at a boundary
that includes space you have not allocated yet is harmless right up until somebody
allocates that space somewhere else, at which point the summary is quietly wrong
and the traffic goes to the older site.

Two habits follow. Summarise only at boundaries where you own everything inside,
including the parts you are not using yet. And write down which blocks are
reserved for future use at each site, because a reservation nobody recorded is
indistinguishable from free space.

</details>

## Leaving room without wasting it

The last part of a plan is the part that decides how long it lasts, and it is a
judgement rather than arithmetic.

Sizing every network to its exact current requirement produces the tightest
possible plan and the shortest lived one. Topic 06's panel covered why: a network
that fits today has no room for the printers, the access points and the second
laptop, and growing it means renumbering.

The reflex is to round every network up a size, and on a private /8 that is
usually right, since addresses cost nothing. On a constrained block like the /22
above it does not fit, and the plan has to choose where the headroom goes.

Two things to do instead of rounding everything up.

**Leave the spare space contiguous and at the end**, as the capture does with its
/28. A single free block adjacent to the allocations can be given to whichever
network outgrows its allocation first, and it can be split if two of them need a
little each.

**Give headroom to the networks that will actually grow.** A point to point link
between two routers will never need more than two addresses. A user network will.
Spending the spare capacity where growth is plausible is better than spreading it
evenly, and it costs nothing but thought at planning time.

The other decision worth making deliberately is whether the plan encodes meaning.
Allocating so that the third octet is the site number and the fourth is the VLAN
makes an address readable at a glance and makes summarisation obvious. It also
wastes space when sites differ wildly in size. Most organisations do some of this,
and the ones that do it consistently spend much less time reading documentation.

## Prove it

You have this when you can produce a plan by hand and have a tool agree with it.

Take `10.20.0.0/22` and these requirements: 400 machines, 200, 100, 50, 20 and 6.
Work out each prefix, sort, allocate, and write down the six network addresses and
ranges.

Then check:

```bash
# needs Debian or Ubuntu: apt-get install ipcalc
ipcalc -n -b 10.20.0.0/22 -s 400 200 100 50 20 6
```

Compare three things: the prefix it chose for each, the address each network
starts at, and what it reports as unused. If your prefixes match and your
boundaries do not, you allocated in the wrong order.

Then answer one more question the tool will not: can the whole allocation be
summarised as a single prefix, and if so which one?

## What trips people up

### 1. Allocating smallest first

A small network at the start of the block forces every larger one after it to
skip to its own alignment boundary, wasting most of the space in between. Largest
first is a requirement rather than a convention.

### 2. Using the requirement instead of the block size

A network for 500 machines occupies 512 addresses. The next allocation starts at
512, not at 500, and getting this wrong produces overlapping ranges.

### 3. Forgetting the plus two

500 machines needs 502 addresses once the network and broadcast addresses are
counted, which rounds to 512 rather than to 512 by luck. At 254 the difference
matters: 254 machines needs 256, and 255 machines needs 512.

### 4. Summarising a block you do not entirely own

A summary advertises everything inside the prefix, including space allocated
elsewhere or not yet allocated. Traffic for those addresses arrives and is
dropped, and the routing table looks perfectly healthy.

### 5. Scattering allocations and expecting to summarise later

Summarisation needs contiguous, aligned blocks. It is a consequence of how
addresses were handed out, and retrofitting it means renumbering.

### 6. Spending the headroom evenly

A point to point link will never grow and a user network will. Rounding
everything up wastes the space where it cannot help and leaves too little where it
could.

## Work it through

A company is given `10.50.0.0/20` for a new site and asked for a plan. The
requirements are 300 desks, 150 phones, 40 printers, 20 cameras, a dozen wireless
access points, and eight point to point links to other sites.

Convert everything first, because that says whether it fits. 300 needs a /23, 150
a /24, 40 a /26, 20 a /27, 12 a /28, and each point to point link needs a /30, so
eight of those. Total: 512 plus 256 plus 64 plus 32 plus 16 plus 8 times 4, which
is 912 out of the /20's 4096. It fits with room to spare, which is the useful
thing to know before doing any layout.

Allocate largest first from the start. The /23 at `10.50.0.0`, the /24 at
`10.50.2.0`, the /26 at `10.50.3.0`, the /27 at `10.50.3.64`, the /28 at
`10.50.3.96`, and then the eight /30s from `10.50.3.112` upward.

Now the decisions the arithmetic does not make.

The point to point links are the case for grouping rather than scattering. Eight
/30s taken from one small block, say a /27, keeps them together and lets the whole
lot be summarised or filtered as a unit. Spread through the space they are eight
separate things forever.

The spare is over three thousand addresses, all contiguous from `10.50.4.0`
onward, and the temptation is to allocate it now because it is there. Better to
record it as reserved and leave it. The desks and the phones are the networks that
will grow, and both are adjacent to free space, so both can be widened without
renumbering.

The last thing is to write it down, including the reserved range and why. A plan
that exists only in the router configurations is a plan that the next person has
to reverse engineer, and the reserved space will be the first thing they allocate
for something else.

## Try it

**Do one by hand and check it.** The **Prove it** exercise takes about ten
minutes and the checking takes ten seconds. The value is in the cases where you
disagree with the tool.

**Try it in the wrong order.** Run the same requirements smallest first and see
how much space you lose. Doing it wrong once makes the rule stick better than
being told.

**Look at a plan you already have.** If you have access to a network's addressing,
check whether each site's subnets are contiguous. If they are, one prefix
summarises each site. If they are not, that is a decision somebody made years ago
that is still being paid for.

## Check yourself

<details class="qa">
<summary>Why must you allocate largest first?</summary>

Because every network has to start on a boundary that is a multiple of its own
size.

Allocate a /28 at the start of a block and the next /23 cannot begin until the
first multiple of 512, so almost everything between them is unusable. Largest
first means each allocation lands on a boundary the next smaller one can follow
immediately.

It is a requirement of the arithmetic rather than a tidiness preference.

</details>

<details class="qa">
<summary>Six networks of 500, 250, 120, 60, 28 and 12 machines. Why does VLSM fit them in a /22 when equal subnets cannot?</summary>

Because equal subnets must all be as large as the largest requirement.

The 500 machine network needs a /23, so six equal subnets would be six /23s, which
is 3072 addresses. A /22 holds 1024.

Sized individually the total is 512 plus 256 plus 128 plus 64 plus 32 plus 16,
which is 1008, and it fits with a /28 left over. The same requirement, a factor of
three difference.

</details>

<details class="qa">
<summary>What does summarisation require, and what does it buy?</summary>

It requires the networks to be contiguous and aligned, so that one prefix covers
all of them and nothing else.

It buys three things. Smaller routing tables on every router, since one entry
replaces many. Stability, because a subnet inside the summary flapping does not
generate updates elsewhere. And faster convergence, because there is less to
recalculate.

The catch is that it is a consequence of how addresses were allocated, so it has
to be designed in rather than added later.

</details>

<details class="qa">
<summary>A company has 10.1.0.0/16 at one site and 10.3.0.0/16 at another, with 10.2.0.0/16 belonging to somebody else. What is the problem?</summary>

The two sites are discontiguous, so no prefix covers both without also covering
the block in between.

That means neither site can summarise with the other, and both advertise their
networks individually. That is a cost rather than a fault.

The fault appears if somebody summarises anyway. Advertising `10.0.0.0/14` claims
`10.2.0.0/16` as well, so traffic for the third party arrives at the wrong site
and is dropped, while the routing table looks entirely healthy.

</details>

<details class="qa">
<summary>Where should the spare space in a plan go, and why?</summary>

Contiguous, at the end, and recorded as reserved.

A single free block adjacent to the allocations can be given to whichever network
outgrows its allocation first, or split between two that each need a little. The
same amount of space scattered between allocations helps nobody, because growth
needs adjacency.

Recording it matters as much as placing it, since reserved space nobody documented
is indistinguishable from free space and will be allocated for something else.

</details>

<details class="qa">
<summary>Why is rounding every network up a size the wrong reflex on a constrained block?</summary>

Because it spends the headroom where it cannot be used.

A point to point link between two routers will never need more than two
addresses, so rounding it up wastes space permanently. A user network is where
growth actually happens.

On a private /8 rounding everything up is usually fine, since addresses cost
nothing. On a fixed block the plan has to choose, and choosing means giving the
room to the networks that will plausibly need it.

</details>

## References

- [RFC 1878, Variable Length Subnet Table For IPv4](https://www.rfc-editor.org/rfc/rfc1878) - IETF, the prefix and host count table this page's arithmetic uses. Accessed 2026-08-10.
- [RFC 4632, Classless Inter-domain Routing (CIDR)](https://www.rfc-editor.org/rfc/rfc4632) - IETF, on aggregation and why it needs contiguous blocks. Accessed 2026-08-10.
- [ipcalc](https://jodies.de/ipcalc) - Krischan Jodies, the calculator used to check the allocation. Accessed 2026-08-10.

**Where the output came from.** The captured block was produced in a Debian 13
container by `blog/scripts/capture.sh`, running Debian's own `ipcalc` package. The
command includes the install step and the `grep` that trims the tool's per-subnet
detail down to the prefixes and the leftover, so what appears is the whole command
rather than an edited result.

Everything else on this page is arithmetic rather than capture, and the allocation
the tool produced is the same one the hand method produces, which is the point of
checking against it.

**If you also work on Linux.** Nothing here has a Linux+ counterpart. Designing an
address space is a network planning task rather than a system administration one,
and the Linux+ track deliberately does not cover it.
