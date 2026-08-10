---
title: "Six networks, and why you build eight"
description: "Splitting a network is the other half of subnetting, and it works in the opposite direction from reading one. Borrowing bits, why a requirement for six networks gets you eight, how to turn a machine count into a prefix, and laying the ranges out with nothing overlapping."
track: "network-plus"
level: "working"
order: 70
objectives:
  - "Borrow host bits to create a required number of networks"
  - "Say how many networks a given number of borrowed bits produces"
  - "Choose a prefix from a machine count rather than from a network count"
  - "Lay out the resulting ranges in order, with no gaps and no overlaps"
  - "Recognise when a requirement will not fit in the address space you were given"
prerequisites: ["ipv4-addresses-and-the-mask"]
tags: ["network-plus", "networking", "subnetting"]
updated: 2026-08-10
draft: false
examObjectives:
  - exam: "n10-009"
    domain: "1.0"
    objective: "1.7"
sources:
  - title: "RFC 4632, Classless Inter-domain Routing (CIDR)"
    url: "https://www.rfc-editor.org/rfc/rfc4632"
    publisher: "IETF"
    accessed: 2026-08-10
    tier: 1
  - title: "RFC 1878, Variable Length Subnet Table For IPv4"
    url: "https://www.rfc-editor.org/rfc/rfc1878"
    publisher: "IETF"
    accessed: 2026-08-10
    tier: 1
  - title: "RFC 950, Internet Standard Subnetting Procedure"
    url: "https://www.rfc-editor.org/rfc/rfc950"
    publisher: "IETF"
    accessed: 2026-08-10
    tier: 1
  - title: "CompTIA Online-Proctored Exam Guidelines"
    url: "https://www.comptia.org/en-us/resources/test-policies/online-proctored-exam-guidelines/"
    publisher: "CompTIA"
    accessed: 2026-08-10
    tier: 1
  - title: "OnVUE online exam whiteboard"
    url: "https://home.pearsonvue.com/Standalone-pages/Whiteboard.aspx"
    publisher: "Pearson VUE"
    accessed: 2026-08-10
    tier: 1
  - title: "ipcalc"
    url: "https://jodies.de/ipcalc"
    publisher: "Krischan Jodies"
    accessed: 2026-08-10
    tier: 2
symptoms:
  - symptom: "Two networks were configured with overlapping address ranges"
    anchor: "laying-the-ranges-out"
  - symptom: "A subnet ran out of addresses shortly after it was built"
    anchor: "the-other-direction-from-a-machine-count"
---

> **Before you read.** You have been given `192.168.10.0/24` and told to build
> six separate networks out of it, one per department.
>
> Six is not a power of two, and the address space does not divide into six of
> anything.
>
> **What prefix do you use, and what happens to what is left over?**

The previous topic read prefixes that somebody else had chosen. This one chooses
them. It is the same boundary and the same arithmetic, run backwards, and it is
the half that shows up in design work and in the longer exam questions.

### Some words you will need

<dl class="terms">
<dt>subnet</dt>
<dd>Used as a verb here: to divide one network into smaller ones. Used as a noun, one of the results.</dd>
<dt>borrow</dt>
<dd>To take bits from the host part and give them to the network part, by moving the boundary right.</dd>
<dt>host requirement</dt>
<dd>How many machines a network has to hold. Usually the number you are actually given.</dd>
<dt>contiguous</dt>
<dd>Next to each other with nothing in between. Address ranges are laid out this way on purpose.</dd>
<dt>address plan</dt>
<dd>The written record of which range belongs to which network. The thing this topic produces.</dd>
</dl>

## What breaks without this

**You hand back a design that does not fit.** Six networks of 40 machines each
will not come out of a /24, and finding that out during the build is expensive in
a way that finding it out on paper is not.

**Two networks quietly claim the same addresses.** An overlap does not announce
itself. It shows up weeks later as one machine that cannot be reached from one
particular place, and nothing in the configuration looks wrong.

**A network is full within the year.** Sizing to the number of machines that
exist today is the single most common planning mistake, and the fix is
renumbering, which means touching every device on it.

## The only place to get more networks is the host part

An address has 32 bits and that is fixed. The boundary is the only thing you can
move, so creating networks means taking bits from the host part and giving them
to the network part. That is what borrowing means, and there is nowhere else for
the bits to come from.

Move it one place to the right and each old network becomes two. Move it three
places and each becomes eight. The networks get smaller by the same factor,
because the bits you took are the ones that were numbering machines.

<figure class="learn-figure">
<svg viewBox="0 0 720 232" role="img" aria-labelledby="borrow-title" style="width:100%;height:auto;">
  <title id="borrow-title">The mask boundary moving three bits to the right, turning one network into eight</title>
  <g font-family="ui-monospace, monospace">
    <text x="12" y="24" font-size="12" fill="currentColor" fill-opacity="0.75">192.168.10.0/24, before</text>
    <rect x="12" y="36" width="516" height="40" rx="3" fill="currentColor" fill-opacity="0.12" stroke="currentColor" stroke-opacity="0.55"/>
    <rect x="528" y="36" width="180" height="40" rx="3" fill="currentColor" fill-opacity="0.04" stroke="currentColor" stroke-opacity="0.55" stroke-dasharray="5 4"/>
    <text x="270" y="53" text-anchor="middle" font-size="12" fill="currentColor">24 bits: which network</text>
    <text x="270" y="68" text-anchor="middle" font-size="10.5" fill="currentColor" fill-opacity="0.7">1 network</text>
    <text x="618" y="53" text-anchor="middle" font-size="12" fill="currentColor">8 bits: which machine</text>
    <text x="618" y="68" text-anchor="middle" font-size="10.5" fill="currentColor" fill-opacity="0.7">254 usable</text>
  </g>
  <g font-family="ui-monospace, monospace">
    <text x="12" y="118" font-size="12" fill="currentColor" fill-opacity="0.75">192.168.10.0/27, after borrowing three</text>
    <rect x="12" y="130" width="516" height="40" rx="3" fill="currentColor" fill-opacity="0.12" stroke="currentColor" stroke-opacity="0.55"/>
    <rect x="528" y="130" width="68" height="40" rx="3" fill="currentColor" fill-opacity="0.22" stroke="currentColor" stroke-opacity="0.7" stroke-width="1.5"/>
    <rect x="596" y="130" width="112" height="40" rx="3" fill="currentColor" fill-opacity="0.04" stroke="currentColor" stroke-opacity="0.55" stroke-dasharray="5 4"/>
    <text x="270" y="147" text-anchor="middle" font-size="12" fill="currentColor">24 bits: unchanged</text>
    <text x="562" y="147" text-anchor="middle" font-size="11" fill="currentColor">3 borrowed</text>
    <text x="562" y="162" text-anchor="middle" font-size="10.5" fill="currentColor" fill-opacity="0.72">8 networks</text>
    <text x="652" y="147" text-anchor="middle" font-size="12" fill="currentColor">5 bits</text>
    <text x="652" y="162" text-anchor="middle" font-size="10.5" fill="currentColor" fill-opacity="0.7">30 usable</text>
  </g>
  <g stroke="currentColor" stroke-opacity="0.85" stroke-width="1.5" fill="none">
    <path d="M528 82 L528 94 L596 94 L596 124"/>
    <path d="M592 118 L596 124 L600 118"/>
  </g>
  <g font-family="ui-monospace, monospace">
    <text x="12" y="200" font-size="11" fill="currentColor" fill-opacity="0.75">the boundary moved right by three bits, and nothing else changed</text>
    <text x="12" y="218" font-size="11" fill="currentColor" fill-opacity="0.75">2 to the power 3 = 8 networks, each with 2 to the power 5 = 32 addresses</text>
  </g>
</svg>
<figcaption>The same 32 bits drawn twice. In the first row a /24 puts the boundary after 24 bits, leaving 8 bits to number machines: one network holding 254 usable addresses. In the second row the boundary has moved three bits to the right, marked by the solid-outlined block labelled "3 borrowed". Those three bits now number networks rather than machines, giving 2 to the power 3 = 8 networks. The 5 bits left to the right of the boundary give 32 addresses each, 30 of them usable. The arrow traces the boundary's move. Dashed outlines mark the host part in both rows and the labels carry the counts, so the shading is not the only signal.</figcaption>
</figure>

The count of networks is 2 raised to the number of bits you borrowed. One bit
gives two networks, two bits give four, three bits give eight.

That is a different table from the one in the previous topic, and mixing the two
up is the most common error in this material. The powers of two you already
learned answer "how many addresses are in this block". This one answers "how many
blocks did I just create". Same arithmetic, different question, and an exam
answer can be wrong only because you read the wrong column.

<details class="deeper">
<summary>If you already work on networks: why some older material subtracts two from the subnet count as well</summary>

You will meet study guides, and occasionally colleagues, who work the subnet
count as 2 to the power of the borrowed bits minus 2. That was correct once. It
is not correct now, and knowing why keeps you from second-guessing yourself in an
exam.

The original subnetting procedure treated the all-zeros subnet and the all-ones
subnet as unusable, for the same reason the all-zeros and all-ones host addresses
are unusable: a subnet number of all zeros was ambiguous with the network itself,
and all ones was ambiguous with a broadcast to the whole thing. Borrow three bits
under that rule and you get six usable networks out of eight rather than eight,
which for the problem at the top of this page would have been a remarkable
coincidence.

RFC 1878 records the change. Its tables include the all-zeros and all-ones
subnets, and it labels the tables that exclude them as obsolete. Classless
routing carries the prefix length with every route, so there is no longer
anything ambiguous about `192.168.10.0/27`: the /27 says exactly which network is
meant, and the surrounding /24 is a different route entirely.

Two consequences worth carrying. Modern equipment uses all definable subnets by
default, and older Cisco gear had a configuration command to enable the behaviour
because the default was still the cautious one. And when a practice question's
answer key disagrees with you by exactly two networks, this is almost always what
happened, so check which convention the question is written to before assuming
you made an arithmetic mistake.

The host part is a separate matter and the minus 2 there is alive and well.
Subtract two from the address count in each subnet, and do not subtract anything
from the number of subnets.

</details>

## Six does not divide, so you build eight

Now the problem at the top. Six networks, and the only lever is a whole number of
borrowed bits.

Two bits give four networks, which is not enough. Three bits give eight, which is
more than enough. There is nothing in between, because you cannot borrow two and
a half bits, so the answer is three and the prefix is /27.

**You round up, always, and you accept the waste.** Six of the eight networks get
used and two sit spare. That is not a mistake in the working and it is not
something to optimise away. It is what happens when a requirement that is not a
power of two meets an address scheme built entirely out of powers of two.

The general rule is worth stating once. Find the smallest power of two that is at
least as large as the number of networks you need, and the exponent is how many
bits you borrow.

| Networks needed | Smallest power of two that covers it | Bits to borrow | Prefix from a /24 |
| --- | --- | --- | --- |
| 2 | 2 | 1 | /25 |
| 3 or 4 | 4 | 2 | /26 |
| 5, 6, 7 or 8 | 8 | 3 | /27 |
| 9 to 16 | 16 | 4 | /28 |
| 17 to 32 | 32 | 5 | /29 |

The middle column is the one to compute, and the ranges in the left column are
what makes the question feel harder than it is. Anything from five to eight
networks is the same answer.

<details class="deeper">
<summary>If you already work on networks: where to put the two spare networks, and why it matters later</summary>

The spares are free to place anywhere, and where you put them is a decision with
consequences that arrive about two years later.

Put the six departments in the first six blocks and leave `192.168.10.192/26`
whole at the end, which is what the capture further down does. The leftover is
then one contiguous range rather than two scattered ones, and a contiguous range
can be handed out as a single /26, or split again, or advertised as one route.

Scatter them instead, giving departments the first, third, fifth and so on, and
you still have exactly the same number of spare addresses. What you have lost is
the ability to describe them in one line. Two /27s that are not next to each
other are two routes, two firewall rules and two entries in every document,
forever.

This is the first appearance of a principle that runs through the rest of the
addressing material. Keeping related things adjacent lets one prefix stand for
many networks later, which is the whole basis of route summarisation in topic 23
and of readable access lists in topic 54. Allocating in order costs nothing at
the time and it is close to impossible to retrofit.

</details>

## The other direction, from a machine count

Six departments was a convenient way to state the problem, because it named the
thing you were solving for. Real requirements almost never do. What you get is a
machine count, and the network count falls out of it.

Turning a machine count into a prefix runs on the host side of the boundary. You
need enough host bits that the usable count covers the requirement, and usable is
two fewer than the addresses in the block.

Thirty machines needs five host bits, because five bits give 32 addresses and 30
usable, which is exactly enough. Thirty one machines needs six, because five bits
give you 30 and you are one short. The requirement grew by one and the network
doubled.

**That cliff is where the marks are.** A question asking for the smallest prefix
that holds a given number of machines is testing whether you noticed the minus 2,
and the wrong answer is always plausible.

| Machines needed | Host bits | Addresses | Usable | Prefix |
| --- | --- | --- | --- | --- |
| up to 2 | 2 | 4 | 2 | /30 |
| 3 to 6 | 3 | 8 | 6 | /29 |
| 7 to 14 | 4 | 16 | 14 | /28 |
| 15 to 30 | 5 | 32 | 30 | /27 |
| 31 to 62 | 6 | 64 | 62 | /26 |
| 63 to 126 | 7 | 128 | 126 | /25 |

Both directions can be given to you at once, and then they have to be reconciled.
Six networks of 40 machines is the version of the opening problem that does not
work: 40 machines needs a /26, six /26s is more than a /24 contains, and no
amount of arithmetic rescues it. The useful skill is seeing that in about ten
seconds and asking for a second /24 rather than producing a plan that cannot be
built.

<details class="deeper">
<summary>If you already work on networks: sizing with headroom, and which direction to be wrong in</summary>

The tables above give the smallest prefix that fits. Deploying the smallest
prefix that fits is usually a mistake.

The asymmetry is the reason. A network sized too large wastes addresses, and in
private space addresses are effectively free. A network sized too small has to be
renumbered, and renumbering means changing the address on every device, every
static entry that pointed at one of them, every firewall rule that named the
range, and every piece of documentation. One of those is an afternoon of
annoyance and the other is a project.

So the ordinary practice is to size for what a network will hold in a few years
and then take the next prefix up. A department of 30 people whose machine count
you sized exactly is full the day somebody brings a second laptop, and printers,
phones, access points and cameras all take addresses that nobody counted.

Two places where the cheap direction is not cheap. Very large broadcast domains
get slow and hard to reason about, so a /16 for a 40 person office is not
generosity, it is a different mistake. And in public address space, or anywhere
an allocation is being justified to somebody else, waste has a real price.

The exam asks for the smallest prefix that fits, and design asks for the one you
will not have to change. Give each of them the answer it wants.

</details>

## Laying the ranges out

With the prefix chosen, the rest is bookkeeping, and it is where overlaps get
created.

Write the networks in order. The first starts at the network address you were
given. Each one after it starts immediately after the previous one's broadcast
address, with no gap. Six /27s out of `192.168.10.0/24` come out like this.

| Department | Network | Usable range | Broadcast |
| --- | --- | --- | --- |
| 1 | 192.168.10.0/27 | .1 to .30 | .31 |
| 2 | 192.168.10.32/27 | .33 to .62 | .63 |
| 3 | 192.168.10.64/27 | .65 to .94 | .95 |
| 4 | 192.168.10.96/27 | .97 to .126 | .127 |
| 5 | 192.168.10.128/27 | .129 to .158 | .159 |
| 6 | 192.168.10.160/27 | .161 to .190 | .191 |

Two things to check every time. Every network address is a multiple of the block
size, so a /27 can only start at .0, .32, .64 and so on, and a plan with a
network starting at .40 is wrong before you look at anything else. And the last
address of one range is one below the first address of the next, with nothing
skipped and nothing shared.

The remaining `192.168.10.192` through `.255` is untouched. It is two more /27s
if you want them that way, or one /26 kept whole.

You do not have to take my word for the layout.

<details class="predict">
<summary>ipcalc asked for six networks of 30 machines out of the same /24. Which prefix does it choose, where does the sixth network start, and how does it describe what is left over?</summary>

```bash
# Debian 13 (trixie), x86_64
$ apt-get update -qq >/dev/null 2>&1; apt-get install -y -qq ipcalc >/dev/null 2>&1; ipcalc -n -b 192.168.10.0/24 -s 30 30 30 30 30 30 | grep -E "^(Network|Needed|Used|Unused)|^192\."
Network:   192.168.10.0/24      
Network:   192.168.10.0/27      
Network:   192.168.10.32/27     
Network:   192.168.10.64/27     
Network:   192.168.10.96/27     
Network:   192.168.10.128/27    
Network:   192.168.10.160/27    
Needed size:  192 addresses.
Used network: 192.168.10.0/24
Unused:
192.168.10.192/26
```

</details>

Six /27s at exactly the addresses in the table, and the leftover described as
`192.168.10.192/26`, which is the whole spare range in one line rather than two.
`Needed size: 192 addresses` is the six networks of 32 added up, out of the 256
the /24 holds.

The tool agreeing with you is worth something, and it is worth less than being
able to produce the table without it, because the exam has no tool in it.

<details class="deeper">
<summary>If you already work on networks: subnetting a subnet, and the point where this becomes VLSM</summary>

Everything above divides a network into equal pieces, which is the version the
exam introduces first and the version that wastes the most space.

Nothing stops you subnetting one of the results. Take the sixth /27 above,
`192.168.10.160/27`, and borrow three more bits from it, and you get eight /30
networks: `.160`, `.164`, `.168` and so on up to `.188`. Each holds two usable
addresses, which is exactly what a link between two routers needs and no more.

That is variable length subnet masking, and the name is doing less work than it
sounds like. It means different networks inside the same address space have
different prefix lengths, chosen to fit what each one is for. A department of 30
gets a /27, a point to point link between two routers gets a /30, and neither is
sized for the other's requirement.

The reason it works at all is the same reason the subnet zero argument went away.
Every route carries its own prefix length, so a /30 sitting inside a range that
was carved as /27s is unambiguous. Under the classful scheme it would not have
been.

There is an order to doing it that saves grief. Allocate the largest requirement
first, working down to the smallest, and take each block from the start of what
remains. Allocate a /30 first and you will find the /27 it fragmented has nowhere
to go. Topic 24 does this properly, with a worked plan and the arithmetic for
checking it.

</details>

## Prove it

You have this when you can produce the plan and then check it, in that order.
Doing it the other way round teaches you to operate a calculator.

The problem: you have `172.16.40.0/23`. You need eleven networks, each holding at
least 25 machines. Work out the prefix, the number of networks it gives you, the
first four network addresses, and whether the requirement fits at all.

Do that on paper or on a whiteboard, then run this to check yourself.

```bash
# needs Debian or Ubuntu: apt-get install ipcalc
ipcalc -n -b 172.16.40.0/23 -s 25 25 25 25 25 25 25 25 25 25 25
```

Three things in the output to compare against your working: the netmask it chose,
the address the eleventh network starts at, and what it reports as unused. If
your prefix disagrees with its netmask, one of you rounded the wrong way, and it
is worth finding out which before reading on.

There is no **Across platforms** section on this page because there is nothing to
compare. The arithmetic is the same everywhere and none of it is a command.
`ipcalc` is a Debian and Ubuntu package with no Windows equivalent shipped, and
on a Mac it comes from Homebrew, so a reader on either can use one of the web
calculators linked from the previous topic instead. Checking your working matters;
which tool checks it does not.

## What trips people up

### 1. Using the host table to count networks

Both tables are powers of two and they answer different questions. Asked how many
networks three borrowed bits give, the answer is 8. Asked how many machines fit
in three host bits, the answer is 6. The numbers 8 and 6 are both in the room,
which is exactly why this goes wrong.

The check: if the question says networks, do not subtract two. If it says
machines, hosts, devices or users, subtract two.

### 2. Subtracting two from the number of subnets

Covered in the panel above, and it survives because old material is still in
circulation. Three borrowed bits give eight networks. Not six.

### 3. Rounding down

Six networks needs three borrowed bits. Working out that six is between four and
eight and taking the four is the mistake, and it is a natural one, because two
bits look closer to the requirement than three do. The rule is that the power of
two has to be at least the requirement, never less.

### 4. Starting the next network in the wrong place

A /27 has 32 addresses, so the second one starts at `.32`, not at `.31` and not
at `.33`. The number `.31` is the first network's broadcast and it belongs to the
first network. Off by one here produces two ranges that overlap by exactly one
address, which is a fault you will look at for a long time.

### 5. Answering with the block size instead of the usable count

A /27 has 32 addresses and 30 usable. A question asking how many machines it
holds wants 30. This one is easy to get right slowly and easy to get wrong at
speed, which is the condition the exam tests you in.

### 6. Sizing to today's machine count

Thirty machines in a /27 leaves no room at all. The first printer takes the last
address and the next arrival needs a renumber. This does not cost a mark on the
exam and it costs a weekend in the job.

## Work it through

A small office is moving into one floor of a building and you have been handed
`10.20.30.0/24` and nothing else.

The requirement, as delivered by somebody who does not think in prefixes: four
departments of about twenty people each, a guest wireless network, and a separate
network for the switches and access points to be managed on. Departments are
expected to grow but nobody will say by how much.

Start by counting networks rather than machines. Four departments plus guest plus
management is six, which is the problem at the top of this page, so three
borrowed bits and a /27.

Now check the /27 against the machine counts, because a network count that fits
is not the same as a plan that works. A /27 holds 30 usable addresses. Twenty
people is under that, but twenty people is not twenty devices: laptops, phones,
a printer and a couple of access points push a department of twenty toward
thirty, and thirty is the ceiling rather than a comfortable number. Guest
wireless is the one that will not stay small, because every visitor's phone takes
an address.

So the /27 fits arithmetically and it is tight. Two options, and this is a
judgement rather than a calculation. Take the /27 for everything and accept that
guest will be the first to hurt. Or give guest a /26 and take the departments
down to /28, which is 14 usable and too small, so that option dies on inspection.

The one that survives: /27 across the board, departments in the first four
blocks, guest fifth, management sixth, and the spare /26 at the end kept whole
and unallocated. When guest fills up, it is next to a free /26 and can be widened
into it. That is what the earlier panel was buying.

Write the plan down before touching anything.

| Network | Range | For |
| --- | --- | --- |
| 10.20.30.0/27 | .1 to .30 | Department 1 |
| 10.20.30.32/27 | .33 to .62 | Department 2 |
| 10.20.30.64/27 | .65 to .94 | Department 3 |
| 10.20.30.96/27 | .97 to .126 | Department 4 |
| 10.20.30.128/27 | .129 to .158 | Guest wireless |
| 10.20.30.160/27 | .161 to .190 | Management |
| 10.20.30.192/26 | .193 to .254 | Held for growth |

The last row is the part people leave out, and it is the row that stops somebody
else allocating the same range next year.

## Try it

Two exercises, and the second one is more useful than it sounds.

**The arithmetic.** Take `192.168.100.0/24` and produce plans for each of these
in turn, without a calculator: three networks, nine networks, and a set of
networks holding 100, 50, 25 and 10 machines respectively.

Checking the first two takes a small extra step, because `ipcalc -s` is asked for
machine counts rather than network counts. Work out your prefix first, then work
out how many machines that prefix holds, then ask for that many of them. Three
networks out of a /24 is a /26, a /26 holds 62, so `-s 62 62 62` is the check. If
the netmask it prints is not the one you chose, the disagreement is the useful
part.

The third one is variable length subnetting, and `-s 100 50 25 10` does it in a
single pass. Work it out before you look, because the tool sorts the requirements
for you and doing that yourself is the skill.

**The whiteboard.** If you are taking this exam online, you cannot bring paper,
pens or an erasable board to it. CompTIA's guidelines are explicit: remove all
scrap paper, pens and pencils from the desk, clear any whiteboard in the room,
and use the built-in digital one instead. Pearson VUE publish that whiteboard as
a standalone page you can open right now.

Open it and work through a subnetting problem on it before exam day. Drawing a
table with a mouse is slower than writing one, the tool has its own quirks, and
the exam is not the moment to discover them. A test centre is the other case:
there you are given an erasable noteboard and pen, and you may not bring your
own.

## Check yourself

<details class="qa">
<summary>You borrow four bits. How many networks do you get, and how many usable addresses does each hold if you started from a /24?</summary>

Sixteen networks. Four borrowed bits give 2 to the power 4, which is 16, and
nothing is subtracted from that count.

Starting from a /24 you had 8 host bits and borrowed 4, leaving 4. Four host bits
give 16 addresses, so 14 usable after the network and broadcast addresses are
taken out. The prefix is /28.

</details>

<details class="qa">
<summary>A requirement asks for seven networks. Somebody proposes borrowing three bits and says two will be spare. Are they right?</summary>

They have the arithmetic right and the count of spares wrong.

Three bits give eight networks, which covers seven, and rounding up to eight is
correct. But seven of the eight are used, so one is spare rather than two.

Worth noticing that borrowing two bits would give four networks, which does not
cover seven, so three really is the answer rather than a cautious choice.

</details>

<details class="qa">
<summary>What is the smallest prefix that will hold 62 machines? What about 63?</summary>

Sixty two machines fit in a /26. Six host bits give 64 addresses and 62 usable,
which is exactly the requirement.

Sixty three machines need a /25. There is nothing between /26 and /25, and 62 is
one short, so the network doubles to 128 addresses and 126 usable for the sake of
one extra machine.

This is the cliff, and a question that picks the number 63 deliberately is
picking it for this reason.

</details>

<details class="qa">
<summary>You are subnetting 192.168.5.0/24 into /28s. What is the network address of the fourth one, and what is its broadcast address?</summary>

A /28 has 16 addresses, so the networks start at .0, .16, .32, .48 and so on.

The fourth is `192.168.5.48/28`. Its usable range is .49 to .62 and its broadcast
address is `192.168.5.63`.

Check the arithmetic by noticing that .48 plus 16 is .64, which is where the
fifth network starts, so the fourth one ends one below at .63.

</details>

<details class="qa">
<summary>You need six networks of 40 machines each and you have been given one /24. What do you tell the person who asked?</summary>

That it does not fit, and why, with a number attached.

Forty machines needs a /26, because a /27 gives 30 usable and that is short. Six
/26s would be 6 times 64, which is 384 addresses, and a /24 has 256.

The useful answer names the shortfall and the options: a second /24, a larger
block such as a /23, or a conversation about whether all six networks really need
40 addresses. Producing a plan that does not fit, and letting somebody discover
it during the build, is the answer to avoid.

</details>

<details class="qa">
<summary>Why does laying networks out in order, with the spare space contiguous at the end, matter more than it appears to?</summary>

Because adjacent networks can be described by one prefix and scattered ones
cannot.

Six /27s in order leave a whole /26 at the end, which is one route, one firewall
rule, one line in the plan, and one block that can be handed to whichever network
outgrows its allocation first.

The same six /27s allocated at random leave the same number of addresses free in
pieces that have to be named separately forever. Nothing breaks. It just gets
more expensive to describe, and route summarisation in topic 23 depends on the
tidy version.

</details>

## References

- [RFC 4632, Classless Inter-domain Routing (CIDR)](https://www.rfc-editor.org/rfc/rfc4632) - IETF, on prefixes carrying their own length. Accessed 2026-08-10.
- [RFC 1878, Variable Length Subnet Table For IPv4](https://www.rfc-editor.org/rfc/rfc1878) - IETF, which includes the all-zeros and all-ones subnets and marks the tables excluding them obsolete. Accessed 2026-08-10.
- [RFC 950, Internet Standard Subnetting Procedure](https://www.rfc-editor.org/rfc/rfc950) - IETF, the original procedure. Accessed 2026-08-10.
- [CompTIA Online-Proctored Exam Guidelines](https://www.comptia.org/en-us/resources/test-policies/online-proctored-exam-guidelines/) - CompTIA, on writing materials and the digital whiteboard. Accessed 2026-08-10.
- [OnVUE online exam whiteboard](https://home.pearsonvue.com/Standalone-pages/Whiteboard.aspx) - Pearson VUE, the whiteboard as a standalone page. Accessed 2026-08-10.
- [ipcalc](https://jodies.de/ipcalc) - Krischan Jodies, the calculator used to check the split. Accessed 2026-08-10.

**Where the output came from.** The one captured block was produced in a Debian
13 container by `blog/scripts/capture.sh`, running the `ipcalc` package from
Debian's own repository. The command in the block includes the install step and
the `grep` that trims the tool's per-subnet detail down to the network addresses,
so what you see is the whole command rather than an edited result. Every table on
this page is arithmetic rather than capture, and the six /27 layout is the one
the tool independently produced.

**If you also work on Linux.** The Linux+ track does not cover subnet planning,
because designing an address space is not a system administration task. The mask
arithmetic it does cover is in [Addresses, masks, and who counts as a
neighbour](/learn/linux-plus/16-network-basics-addresses-and-routes), and the
previous topic here is the closer match.
