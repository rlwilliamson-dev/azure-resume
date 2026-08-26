---
title: "Vulnerabilities in software"
description: "Why every class in this objective is one idea, where the bounds bug actually is against where the crash appears, the check-then-use gap measured in microseconds, and why the same defects survive fifty years of being written about."
deck: "A field accepts eighty characters. The developer allocated sixty-four"
track: "security-plus"
level: "working"
order: 160
objectives:
  - "Say what memory injection and buffer overflow have in common"
  - "Explain where a bounds bug is, against where it becomes visible"
  - "Describe a race condition and identify the check-then-use case"
  - "Say why injection flaws in web applications are the same idea"
  - "Explain what a malicious update is and why it is hard to detect"
  - "State the one property every class in this objective shares"
prerequisites: ["the-surfaces-you-did-not-mean-to-expose"]
tags: ["security-plus", "security", "threats", "vulnerabilities"]
updated: 2026-08-26
draft: false
examObjectives:
  - exam: "sy0-701"
    domain: "2.0"
    objective: "2.3"
sources:
  - title: "CWE-787, Out-of-bounds Write"
    url: "https://cwe.mitre.org/data/definitions/787.html"
    publisher: "MITRE"
    accessed: 2026-08-26
    tier: 1
  - title: "CWE-367, Time-of-check Time-of-use (TOCTOU) Race Condition"
    url: "https://cwe.mitre.org/data/definitions/367.html"
    publisher: "MITRE"
    accessed: 2026-08-26
    tier: 1
  - title: "CWE-89, Improper Neutralization of Special Elements used in an SQL Command"
    url: "https://cwe.mitre.org/data/definitions/89.html"
    publisher: "MITRE"
    accessed: 2026-08-26
    tier: 1
  - title: "SP 800-218, Secure Software Development Framework"
    url: "https://csrc.nist.gov/pubs/sp/800/218/final"
    publisher: "NIST"
    accessed: 2026-08-26
    tier: 1
symptoms:
  - symptom: "A crash happens in a function that contains no bug"
    anchor: "where-the-bug-is-and-where-the-crash-is"
  - symptom: "A check passed and the thing used was different"
    anchor: "the-gap-between-the-check-and-the-use"
---

> **Before you read.** A form field accepts as much text as somebody types. The
> code behind it allocated room for sixty-four characters, and the copy that puts
> the input there does not mention a length anywhere.
>
> **Which line is the vulnerability?**

The copy, and not the field. That distinction is the whole topic, because every
class the objective names is the same mistake in a different costume: something
outside the program decided how much, or what, and the program believed it.

### Some words you will need

<dl class="terms">
<dt>buffer</dt>
<dd>A region of memory of a fixed size, allocated for a purpose.</dd>
<dt>buffer overflow</dt>
<dd>Writing past the end of one, into memory holding something else.</dd>
<dt>memory injection</dt>
<dd>Getting your own data or code into another process's memory.</dd>
<dt>race condition</dt>
<dd>Two things happening whose order is not guaranteed, where the order matters.</dd>
<dt>time-of-check to time-of-use</dt>
<dd>The specific race where a program checks a condition and then acts on it, and the condition changes between.</dd>
<dt>injection</dt>
<dd>Input reaching an interpreter as instructions rather than as data.</dd>
<dt>malicious update</dt>
<dd>A legitimate update mechanism delivering something harmful.</dd>
<dt>stack canary</dt>
<dd>A value the compiler places to detect an overflow before a function returns.</dd>
</dl>

## What breaks without this

**The crash is investigated in the wrong place.** The program failed in a function
that is correct, because the damage was done earlier by one that is not.

**A check is trusted after the moment it was made.** The answer was true when
asked, the program acted later, and nothing held the thing in between.

**Input is escaped rather than separated.** Somebody filters characters that look
dangerous, the interpreter has more of them than anybody enumerated, and the flaw
stays.

**An update is trusted because it is an update.** The mechanism worked exactly as
designed, and what it delivered was chosen by somebody else.

## Where the bug is and where the crash is

The compiler will tell you a great deal about a program. Here is what it says
about the line from the hook.

```bash
# AlmaLinux 10.2, x86_64
$ cd /srv/bugs; echo "the compiler will tell you about this line if you ask:"; gcc -O2 -Wall -Wextra -o safe overflow.c 2>&1 | head -4; echo "(nothing, because strcpy is a legal call)"; echo; echo "what the compiler emitted to defend it anyway:"; gcc -O2 -fstack-protector-strong -o guarded overflow.c 2>/dev/null; objdump -d guarded 2>/dev/null | grep -c "fs:0x28"; echo "references to the stack canary"; echo; echo "and with that defence switched off:"; gcc -O2 -fno-stack-protector -o bare overflow.c 2>/dev/null; objdump -d bare 2>/dev/null | grep -c "fs:0x28"; echo; echo "the bound the programmer wrote, and the input the function accepts:"; grep -n "char name\|strcpy" overflow.c
the compiler will tell you about this line if you ask:
(nothing, because strcpy is a legal call)

what the compiler emitted to defend it anyway:
2
references to the stack canary

and with that defence switched off:
0

the bound the programmer wrote, and the input the function accepts:
5:    char name[64];
6:    strcpy(name, input);          /* no bound anywhere in this line */
```

**Nothing at all, even with the warnings turned up.** `strcpy` is a legal call
that does exactly what it is documented to do: copy until it reaches a terminator.
It has no length parameter because the interface does not have one, and the
programmer's promise that the source fits is the entire safety argument.

The second and third commands are the interesting pair. With stack protection
enabled the compiler emits two references to a guard value, and with it disabled
there are none. That is a defence added by the toolchain to a program the
toolchain could not tell was wrong.

**And a guard value is a detector rather than a fix.** It sits between the buffer
and the saved return address, and it is checked when the function returns. So an
overflow that runs past the buffer corrupts the guard, the check fails, and the
program aborts. That converts arbitrary code execution into a crash, which is a
large improvement and is not correctness.

**Which is why the crash appears somewhere other than the bug.** The write happens
in the copying function. Nothing goes wrong there, because writing to memory
succeeds. What was overwritten belongs to a caller, or to another variable, or to
the bookkeeping the function returns through, and the failure surfaces when
somebody uses it, in a function containing no defect at all.

<details class="deeper">
<summary>If you have chased one of these: why the debugger points at innocent code, and how to find the real line</summary>

The frustrating property of a memory-safety bug is that the point of failure and
the point of damage are different places, frequently far apart in both code and
time.

The mechanism is straightforward once stated. A write past the end of a buffer
lands on whatever is next in memory. That might be another local variable, in
which case the program continues with a wrong value and misbehaves later in a way
that looks like a logic error. It might be heap metadata, in which case the crash
arrives at the next allocation, in code that has nothing to do with anything. Or
it might be the saved return address, in which case the program jumps somewhere
arbitrary when the function returns.

None of those points at the copy. A debugger stops where the program died, which
is a consumer of the corrupted thing rather than its producer.

What actually finds it is tooling that checks at the moment of the write rather
than at the moment of the consequence. An address sanitiser instruments every
memory access and reports the write that went out of bounds, with the allocation
it belonged to and the line that allocated it. A hardened allocator places guard
pages after allocations so an overrun faults immediately. Both slow the program
down, which is why they run in testing rather than in production, and both turn a
week of confusion into a stack trace.

The practical habit for anybody reading a crash in a language without memory
safety: distrust the location. Ask what wrote to memory near the thing that was
wrong, and reach for the sanitiser before the debugger. The stack trace is
evidence of where the corruption was noticed, not of where it happened.

</details>

## The gap between the check and the use

A race condition is two things whose order is not guaranteed, and the version this
objective names has a specific and measurable shape.

<details class="predict">
<summary>A program checks whether it may read a file, then opens it. Predict how much time passes between the two.</summary>

```bash
# AlmaLinux 10.2, x86_64
$ python3 /srv/bugs/toctou.py
runs: 2000
median gap between the check and the use: 52,500 ns
slowest one in this run:                  688,000 ns
that is 688.0 microseconds during which the name could point somewhere else
```

**A median of fifty-two microseconds and a worst case of six hundred and
eighty-eight**, on an idle machine doing nothing else, with the two operations
adjacent in the source.

That is the window, and its size is not the point. The point is that it exists at
all, and that it is not bounded: the numbers above are for a quiet machine, and a
loaded one, or one where the operating system decides to schedule something else
between the two lines, produces a longer one. There is no value you can make it
small enough to ignore.

What creates the window is that the check answered a question about a name. Names
are not objects: a path is a lookup performed fresh each time, and between the two
lookups anything with permission to alter the directory can make the name refer to
something else. The program then uses the second thing with the confidence it
earned from asking about the first.

The fix follows directly from that sentence and it is not to check faster. It is
to stop using the name twice. Open the file once, which resolves the name and
hands back a reference to the object, then ask your questions about the reference:
its permissions, its owner, its type. The window disappears because there is no
second lookup for anything to interpose on.

The general form is worth carrying beyond files. Any time a program validates
something identified by a name, then acts on that name, the two operations refer
to whatever the name meant at each moment, and those need not be the same thing.

</details>

<figure class="learn-figure">
<svg viewBox="0 0 720 268" role="img" aria-labelledby="toc-title" style="width:100%;height:auto;">
<title id="toc-title">Two processes on one time axis, with the interval between one process checking a file and using it, and the moment another process changes what the name points at</title>
<g fill="currentColor">
<text x="14" y="20" font-size="11">one program, two steps, and the gap between them measured in microseconds</text>
<text x="14" y="76" font-size="9">the program</text>
<path d="M 150 72 H 660" stroke="currentColor" stroke-opacity="0.6" stroke-width="1.6"/>
<text x="14" y="176" font-size="9">anything else</text>
<path d="M 150 172 H 660" stroke="currentColor" stroke-opacity="0.35" stroke-width="1.4" stroke-dasharray="5 4"/>
<circle cx="250" cy="72" r="5" fill="var(--accent)" stroke="var(--accent)" stroke-width="1.5"/>
<text x="250" y="56" text-anchor="middle" font-size="8.5">check: may I read it</text>
<text x="250" y="44" text-anchor="middle" font-size="8" fill-opacity="0.7">access() says yes</text>
<circle cx="470" cy="72" r="5" fill="var(--accent)" stroke="var(--accent)" stroke-width="1.5"/>
<text x="470" y="56" text-anchor="middle" font-size="8.5">use: open it</text>
<text x="470" y="44" text-anchor="middle" font-size="8" fill-opacity="0.7">open() reads whatever the name means now</text>
<rect x="250" y="60" width="220" height="126" fill="var(--red)" fill-opacity="0.09" stroke="var(--red)" stroke-opacity="0.5" stroke-width="1.2" stroke-dasharray="5 3"/>
<text x="360" y="130" text-anchor="middle" font-size="9" fill="var(--red)" fill-opacity="0.95">median 52,500 ns, slowest 688,000 ns</text>
<text x="360" y="145" text-anchor="middle" font-size="8" fill-opacity="0.8">the name is not held. only the answer was.</text>
<circle cx="360" cy="172" r="5" fill="var(--red)" stroke="var(--red)" stroke-width="1.5"/>
<text x="360" y="196" text-anchor="middle" font-size="8.5">the name is repointed here</text>
<text x="14" y="234" font-size="10" fill-opacity="0.85">the check was true when it was made and the program used a different thing</text>
<text x="14" y="254" font-size="9" fill-opacity="0.7">the fix is to hold the object rather than the name: open once, then ask about what you hold</text>
</g></svg>
<figcaption>The measured interval, drawn against a second timeline for anything else running on the machine. The program's check was correct: at the moment it asked, the answer was true. What it carried forward was the answer rather than the thing, and a path is resolved fresh on every use, so the second lookup can find something different. The shaded region is where the numbers from the capture live, and the reason to draw it rather than describe it is that it makes the fix obvious: hold the object, not the name, and the region has nothing to contain.</figcaption>
</figure>

## Injection is the same idea

Web vulnerabilities look like a separate subject and they are the same sentence
with different nouns.

**SQL injection** happens when input is concatenated into a query string. The
database receives one string and parses it, and it has no way to know which parts
of it came from a developer and which from a form field. Everything in it is
instructions, because that is what a query is.

**Cross-site scripting** happens when input is placed into a page. The browser
receives one document and parses it, and it has no way to know which parts came
from the application and which from a comment box.

**Command injection** is the same with a shell.

**In every case the mistake is identical**: data was combined with instructions
into a single stream, and the interpreter that reads the stream cannot tell them
apart afterwards.

**Which is why escaping is the weaker fix and separation is the stronger one.**
Escaping tries to neutralise the characters that would be read as instructions,
which requires enumerating them correctly for the interpreter, in every context
the value might land in, forever. Separation hands the interpreter the
instructions and the data through different channels: a parameterised query sends
the query once and the values separately, and no arrangement of characters in a
value can change what the query does.

<details class="deeper">
<summary>If you review code: why the filter approach keeps failing, and the question that finds these fast</summary>

Input filtering fails for a reason worth being precise about, because "escaping is
brittle" is true and unpersuasive on its own.

An interpreter's syntax is larger than anybody's list. SQL has comment syntax,
alternative quoting, numeric contexts where quotes are not required at all, and
dialect extensions per database. HTML is worse: a value can land in element text,
in an attribute, in a URL attribute, inside a script block, inside a style block,
or inside an event handler, and the correct escaping is different in every one.
A filter written for one context is wrong in another, and the same value moves
between contexts as an application is developed.

Character encoding adds another layer, since the same character can be expressed
several ways and a filter comparing bytes may not recognise the form the
interpreter will accept.

So filtering is a race between the person enumerating dangerous input and the
specification, and the specification is longer.

The question that finds these quickly in a review is narrow: for each place data
reaches an interpreter, is the data travelling in the same string as the
instructions? Not whether it is validated, escaped or sanitised, all of which are
answers about mitigation. Just whether the two are in one string.

If they are, the finding stands regardless of how good the filtering is, and the
remediation is a mechanism change rather than a better filter. If they are not,
the class is closed at that site by construction and no amount of input creativity
reopens it.

That question also survives across languages, frameworks and interpreters, which
makes it a better tool for a reviewer than a list of dangerous functions.

</details>
<details class="predict">
<summary>An application escapes single quotes in every value before building its SQL. Predict whether the injection class is closed.</summary>

**No, and the reason is that quotes are one of several ways into a query.**

Start with the case the filter misses most often: a numeric context. A query
comparing an identifier does not quote the value, so nothing in the input needs a
quote to be read as syntax. The escaping runs, changes nothing, and the value is
concatenated straight into a position where arithmetic and boolean operators are
legal.

Then comment syntax, which lets an attacker discard the remainder of a statement,
and alternative quoting forms that databases support and filters rarely enumerate.
Then dialect extensions, which differ per product and are documented in that
product's manual rather than in any general list.

Then encoding. The same character can be expressed several ways, and a filter
comparing bytes may not recognise a form the parser will happily accept, which is
a whole family of bypasses in itself.

None of that is exotic and none of it requires the attacker to be clever. It
requires the syntax to be larger than the list, and it always is, because the list
was written by one person and the syntax by a standards committee and a vendor.

The version of this worth carrying into a review: escaping is an attempt to make
data safe to place inside instructions. Parameterisation removes the need for the
data to be safe, because it never enters the instruction stream. The first is a
correctness argument that has to hold in every context forever, and the second is a
structural property that holds regardless of the value.

</details>


## The update mechanism, and the platform beneath

Two classes remain and they are grouped here because both are about trusting
something you did not write.

**A malicious update** arrives through a mechanism designed to be trusted. The
signature verifies, because it was signed by the party whose key you imported. The
transport is authenticated. The version number is higher. Everything the update
system was built to check passes, because the compromise is upstream of all of it,
which is the point the code signing section in block E made and this is where it
lands. Topic 17 takes the supply chain properly; what matters here is that an
update path is a vulnerability class in its own right rather than only a control.

**Operating system vulnerabilities** are the same defect classes in code that runs
with more authority. A bounds bug in a text editor is a bug in a text editor. The
same bug in a kernel driver is a route to the whole machine, because the code that
contains it is not confined by anything you have.

That difference in consequence rather than in kind is why privilege boundaries
matter so much: not because the code below them is better, but because the same
mistake costs more there.

<details class="deeper">
<summary>If you wonder why these persist: what fifty years of writing about buffer overflows has not fixed</summary>

Memory-safety bugs have been documented, taught and tooled against for decades and
they remain among the most common serious vulnerability classes. That is worth
explaining rather than treating as a failure of diligence.

Three reasons, in increasing order of how uncomfortable they are.

**The unsafe operations are the ergonomic ones.** In C, copying a string with
`strcpy` is one call with two arguments. Doing it safely requires knowing the
destination size, choosing a bounded variant, checking the return, and handling
truncation. The safe path is longer, and it is longer at every single site, which
over a large codebase is a substantial tax paid by people under deadline.

**The existing code is enormous and works.** Operating system kernels, network
stacks, media decoders, cryptographic libraries and device drivers represent
decades of accumulated correctness in languages without memory safety. Rewriting
them is not a matter of will; it is a scale problem where the rewrite introduces
new defects while removing old ones.

**And the incentive lands on somebody else.** The cost of writing the unsafe
version is zero today. The cost of the bug is paid later, by a different team,
possibly a different company, which is the same structure as every other deferred
risk on this exam.

What has actually reduced the impact is not better discipline. It is the layers
that assume the bug exists: stack guards, non-executable memory, address
randomisation, hardened allocators, and increasingly memory-safe languages for new
code. Every one of those accepts that the defect will be written and makes it
harder to turn into control of the machine.

That is defence in depth stated precisely, and it is a more honest position than
expecting the class to be eliminated by care.

</details>

## Prove it

**Run it.** Compile a small program containing a fixed buffer and an unbounded
copy, with and without stack protection, and count the guard references in the
output. It takes two commands and it makes the difference between a detector and a
fix concrete.

**Work it out.** Take the check-then-use numbers. If a window has a median of
fifty-two microseconds, how many opportunities does a loop running continuously
get per second, and what does that say about the value of making the window
smaller?

**Look it up.** Open CWE-367 and read its description of the race. Then open
CWE-787 and notice that the two entries describe completely different mechanisms
and the same underlying error, which is trusting something that was not held.

## What trips people up

### 1. Blaming the input rather than the copy

The field accepting eighty characters is not the defect. The copy that writes them
into sixty-four bytes without a length is, and it is the line that has to change.

### 2. Debugging where the crash appeared

The write happened in the copying function and succeeded. The failure surfaces
wherever the corrupted thing is next used, which is frequently code containing no
defect at all.

### 3. Reading a stack canary as a fix

It detects an overrun before a function returns and aborts. That converts possible
code execution into a crash, which is worth having and is not correctness.

### 4. Trying to make a race window smaller

The window in the capture is fifty-two microseconds on an idle machine and
unbounded on a busy one. The fix is to hold the object rather than the name, which
removes the second lookup entirely.

### 5. Filtering dangerous characters

The interpreter's syntax is larger than anybody's list, and the correct escaping
differs by context. Separating data from instructions closes the class by
construction.

### 6. Trusting an update because the signature verified

The signature says the artefact came from the signer unchanged. If the signer was
compromised, everything the update mechanism checks still passes.

## Work it through

A crash report arrives from production. The stack trace points at a logging
function that has not changed in three years and contains no obvious defect.

**The tempting move is to fix the logging function.** It is where the program
died, it is a small function, and adding a null check there makes the crash stop.
It also makes the corruption invisible rather than absent, and the next symptom
will be a wrong value somewhere rather than a crash.

**The move that works treats the trace as the place the damage was noticed.** Run
the same workload under an address sanitiser, which checks every access at the
moment it happens rather than when the result is used. That reports the write that
went out of bounds, the allocation it belonged to, and the line that made it.

**Then the fix is at the write.** Usually a copy with no length, or a length
computed from the wrong thing, in a function that appears nowhere in the original
trace.

**What this rejects is the local fix.** Silencing a crash at the point of failure
is fast, satisfying and leaves the corruption in place, and it removes the only
signal you had.

The residual worth naming: the sanitiser runs in testing, not production, so it
finds the bug if the workload reproduces it. A crash that only happens under real
traffic may need the hardened allocator in a canary environment instead, and that
is a slower path with a real chance of not reproducing at all.

## Try it

**Compile both ways.** Take any C program with a fixed buffer, build it with and
without `-fstack-protector-strong`, and disassemble. The guard references are
visible in the output.

**Measure your own window.** Write the check-then-use loop in any language and
time it. The number will be small and it will not be zero.

**Find one concatenation.** In any codebase you can read, search for a query built
by joining strings. If the values come from outside, that is the finding, and the
remediation is parameterisation rather than a filter.

**Read a real advisory.** Pick any memory-safety CVE and read where the bug was
against where it manifested. They are rarely the same function.

## Check yourself

<details class="qa">
<summary>A field accepts eighty characters into a sixty-four byte buffer. Which line is the vulnerability?</summary>

The copy. The field's length is a property of the input, and inputs are outside
your control by definition. The defect is the operation that writes the input into
the buffer without reference to the buffer's size.

In the capture on this page, the compiler with warnings turned up says nothing
about that line, because the call is legal and does what it is documented to do.
The safety argument was the programmer's promise that the source would fit.

</details>

<details class="qa">
<summary>What does a stack canary do, and what does it not do?</summary>

It places a guard value between the buffer and the saved return address, and
checks it when the function returns. An overrun that reaches the return address
must pass through the guard, so the check fails and the program aborts.

It does not fix the bug. It converts a possible route to code execution into a
crash, which is a large improvement and leaves the out-of-bounds write happening.
The capture shows two guard references with the protection on and none with it
off.

</details>

<details class="qa">
<summary>Why can a check-then-use race not be fixed by narrowing the window?</summary>

Because the window is not bounded. The measurement on this page is fifty-two
microseconds median on an idle machine, and a loaded one, or one that schedules
something else between the two lines, gives a longer one.

The cause is that the check answered a question about a name, and a path is
resolved fresh on every use. The fix is to hold the object: open once, then ask
about the reference you hold, so there is no second lookup to interpose on.

</details>

<details class="qa">
<summary>What do SQL injection, cross-site scripting and command injection have in common?</summary>

Data and instructions were combined into one string, and the interpreter that
parses it cannot tell which parts came from where. That is true of a database
receiving a query, a browser receiving a document, and a shell receiving a command
line.

It is also why separation beats escaping. A parameterised query sends the
instructions and the values through different channels, so no arrangement of
characters in a value can change what the query does.

</details>

<details class="qa">
<summary>Why do memory-safety bugs persist after decades of being documented?</summary>

Three reasons. The unsafe operations are the shorter ones to write, at every site,
which is a real tax across a large codebase. The existing body of code in
languages without memory safety is enormous and works, so rewriting is a scale
problem that introduces new defects. And the cost of writing the unsafe version
falls later and on somebody else.

What reduced the impact was not discipline but layers that assume the bug exists:
guards, non-executable memory, randomisation, hardened allocators, and memory-safe
languages for new code.

</details>

## References

- [CWE-787](https://cwe.mitre.org/data/definitions/787.html) - MITRE, out-of-bounds write, for the mechanism and its consequences. Free. Accessed 2026-08-26.
- [CWE-367](https://cwe.mitre.org/data/definitions/367.html) - MITRE, the check-then-use race, including why the fix is to hold the object. Free. Accessed 2026-08-26.
- [CWE-89](https://cwe.mitre.org/data/definitions/89.html) - MITRE, SQL injection, and the separation argument stated in the mitigations. Free. Accessed 2026-08-26.
- [SP 800-218](https://csrc.nist.gov/pubs/sp/800/218/final) - NIST, secure software development, for where in a lifecycle each of these is caught. Free. Accessed 2026-08-26.

**Where the content came from.** Both blocks are captured from an AlmaLinux 10.2
container. The race measurement times two adjacent operations two thousand times
and reports the distribution; nothing races against it and no file is swapped,
because the evidence being shown is that the interval exists rather than what
could be done with it. The overflow block compiles a program written for this
topic and inspects what the compiler emitted, and the program is never run with an
oversized input. There is no platform comparison on this page, because these
defect classes are properties of how programs are written rather than of an
operating system.

**If you also work on Linux.** The Linux+ track's
[your first shell script](/learn/linux-plus/your-first-shell-script) covers
argument handling, which is where the same trusting-the-input mistake appears in
a language most people meet earlier.
