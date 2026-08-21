---
title: "Reading the standards"
description: "Every page of this track ends in a list of documents and one of its three forms of evidence is to go and read a named clause. Which document is current, what its status actually means, why MUST and SHOULD are the two most expensive words in networking, and how to get at the ones behind a paywall."
deck: "Go and read the clause. Which document, though?"
track: "network-plus"
level: "working"
order: 810
beyondExam: true
objectives:
  - "Find the current document for a protocol rather than the one everybody cites"
  - "Read an obsoletes and updates chain and say what it implies"
  - "Say what a maturity level means and why almost nothing reaches the top one"
  - "Tell a MUST from a SHOULD and explain where interoperability failures come from"
  - "Know what errata and drafts are, and why neither is the document"
  - "Get at an IEEE standard without paying for it"
prerequisites: ["tcp-udp-and-the-handshake"]
tags: ["network-plus", "networking", "standards", "beyond-the-exam"]
updated: 2026-08-20
draft: false
examObjectives: []
sources:
  - title: "RFC 2026, The Internet Standards Process, Revision 3"
    url: "https://www.rfc-editor.org/rfc/rfc2026"
    publisher: "IETF"
    accessed: 2026-08-20
    tier: 1
  - title: "RFC 6410, Reducing the Standards Track to Two Maturity Levels"
    url: "https://www.rfc-editor.org/rfc/rfc6410"
    publisher: "IETF"
    accessed: 2026-08-20
    tier: 1
  - title: "RFC 2119, Key words for use in RFCs to Indicate Requirement Levels"
    url: "https://www.rfc-editor.org/rfc/rfc2119"
    publisher: "IETF"
    accessed: 2026-08-20
    tier: 1
  - title: "RFC 8174, Ambiguity of Uppercase vs Lowercase in RFC 2119 Key Words"
    url: "https://www.rfc-editor.org/rfc/rfc8174"
    publisher: "IETF"
    accessed: 2026-08-20
    tier: 1
  - title: "RFC 9293, Transmission Control Protocol (TCP)"
    url: "https://www.rfc-editor.org/rfc/rfc9293"
    publisher: "IETF"
    accessed: 2026-08-20
    tier: 1
  - title: "RFC 9413, Maintaining Robust Protocols"
    url: "https://www.rfc-editor.org/rfc/rfc9413"
    publisher: "IETF"
    accessed: 2026-08-20
    tier: 1
  - title: "RFC Editor"
    url: "https://www.rfc-editor.org/"
    publisher: "RFC Editor"
    accessed: 2026-08-20
    tier: 1
  - title: "IEEE GET Program"
    url: "https://standards.ieee.org/products-programs/ieee-get-program/"
    publisher: "IEEE Standards Association"
    accessed: 2026-08-20
    tier: 1
symptoms:
  - symptom: "A quoted clause does not appear in the document it was attributed to"
    anchor: "an-rfc-is-never-edited"
  - symptom: "Two implementations disagree and both cite the specification"
    anchor: "the-two-most-expensive-words"
---

> **Before you read.** Somebody tells you the behaviour you are arguing about is
> in the TCP specification. You find RFC 793, published in 1981, and it says the
> opposite of what they claim.
>
> **Which of you is reading the wrong document?**

Nearly every topic in this track ends with a list of documents, and one of the
three ways a topic asks you to prove something is to go and read a named clause.
Nothing has told you how those documents work: how to find the current one, what
its status means, or which of its words are binding. That is what this page is
for, and none of it is examinable.

### Some words you will need

<dl class="terms">
<dt>RFC</dt>
<dd>A published document in the internet series. Permanent, numbered, and never edited after publication.</dd>
<dt>obsoletes</dt>
<dd>A relationship between documents. The new one replaces the old one entirely.</dd>
<dt>updates</dt>
<dd>A weaker relationship. The new one changes part of the old one, which remains in force otherwise.</dd>
<dt>maturity level</dt>
<dd>How far along the standards process a document has travelled. Not a measure of how widely it is used.</dd>
<dt>errata</dt>
<dd>Corrections recorded against a published document, since the document itself cannot change.</dd>
<dt>internet-draft</dt>
<dd>Work in progress. Expires after six months and is not a standard of any kind.</dd>
<dt>normative</dt>
<dd>The part of a document that states requirements, as opposed to the parts explaining or illustrating them.</dd>
</dl>

## What breaks without this

**You cite a document that has been replaced.** RFC 793 is the single most cited
superseded document in networking, and quoting it in an argument means losing the
argument to anybody who checked.

**You read a recommendation as a requirement.** Half of interoperability failures
live in the gap between what a specification obliges an implementation to do and
what it merely advises, and the gap is marked by which word was used.

**You assume something is settled because it is published.** A document at the
first maturity level and a document that has been the standard for thirty years
look identical on the page.

## An RFC is never edited

The series has one rule that explains most of its behaviour: a published document
is permanent. It is never revised, never corrected, and never withdrawn. When
something needs to change, a new document is published which says it replaces the
old one, and both remain available forever.

That is why the metadata matters more than the text.

<details class="predict">
<summary>RFC 793 is what everybody means by the TCP specification. Ask the index about it and about RFC 9293. What does the pair of answers say about which one to read?</summary>

```bash
# Debian 13 (trixie), x86_64
$ for n in 793 9293; do curl -s https://www.rfc-editor.org/rfc/rfc$n.json | jq -c "{id:.doc_id, title, status, obsoleted_by, obsoletes}"; done
{"id":"RFC793","title":"Transmission Control Protocol","status":"INTERNET STANDARD","obsoleted_by":["RFC9293"],"obsoletes":["RFC761"]}
{"id":"RFC9293","title":"Transmission Control Protocol (TCP)","status":"INTERNET STANDARD","obsoletes":["RFC793","RFC879","RFC2873","RFC6093","RFC6429","RFC6528","RFC6691"]}
```

</details>

Read the first line carefully, because it contains the trap. RFC 793 still says
`INTERNET STANDARD`, which is exactly what you would expect the TCP specification
to say, and it has been obsoleted. The status field describes the maturity the
document reached, not whether it is still the one to read. Nothing in the text of
793 mentions 9293, because 793 was published forty years earlier and, being
permanent, could not be told.

<figure class="learn-figure">
<svg viewBox="0 0 720 268" role="img" aria-labelledby="obs-title" style="width:100%;height:auto;">
<title id="obs-title">Seven separate documents on the left, including RFC 793, all feeding into RFC 9293, which replaced all of them in one publication</title>
<g fill="currentColor">
<text x="14" y="24" font-size="11">what RFC 9293 replaced when it was published</text>
<rect x="20" y="44" width="96" height="22" rx="2" fill="var(--accent)" fill-opacity="0.18" stroke="var(--accent)" stroke-width="1.4"/>
<text x="68" y="59" text-anchor="middle" font-size="10" fill="var(--accent)">RFC 793</text>
<rect x="20" y="72" width="96" height="22" rx="2" fill="currentColor" fill-opacity="0.07" stroke="currentColor" stroke-opacity="0.4"/>
<text x="68" y="87" text-anchor="middle" font-size="10">RFC 879</text>
<rect x="20" y="100" width="96" height="22" rx="2" fill="currentColor" fill-opacity="0.07" stroke="currentColor" stroke-opacity="0.4"/>
<text x="68" y="115" text-anchor="middle" font-size="10">RFC 2873</text>
<rect x="20" y="128" width="96" height="22" rx="2" fill="currentColor" fill-opacity="0.07" stroke="currentColor" stroke-opacity="0.4"/>
<text x="68" y="143" text-anchor="middle" font-size="10">RFC 6093</text>
<rect x="20" y="156" width="96" height="22" rx="2" fill="currentColor" fill-opacity="0.07" stroke="currentColor" stroke-opacity="0.4"/>
<text x="68" y="171" text-anchor="middle" font-size="10">RFC 6429</text>
<rect x="20" y="184" width="96" height="22" rx="2" fill="currentColor" fill-opacity="0.07" stroke="currentColor" stroke-opacity="0.4"/>
<text x="68" y="199" text-anchor="middle" font-size="10">RFC 6528</text>
<rect x="20" y="212" width="96" height="22" rx="2" fill="currentColor" fill-opacity="0.07" stroke="currentColor" stroke-opacity="0.4"/>
<text x="68" y="227" text-anchor="middle" font-size="10">RFC 6691</text>
<line x1="116" y1="55" x2="470" y2="132" stroke="var(--accent)" stroke-opacity="0.55" stroke-width="1.3"/>
<line x1="116" y1="83" x2="470" y2="134" stroke="currentColor" stroke-opacity="0.3" stroke-width="1.1"/>
<line x1="116" y1="111" x2="470" y2="136" stroke="currentColor" stroke-opacity="0.3" stroke-width="1.1"/>
<line x1="116" y1="139" x2="470" y2="138" stroke="currentColor" stroke-opacity="0.3" stroke-width="1.1"/>
<line x1="116" y1="167" x2="470" y2="140" stroke="currentColor" stroke-opacity="0.3" stroke-width="1.1"/>
<line x1="116" y1="195" x2="470" y2="142" stroke="currentColor" stroke-opacity="0.3" stroke-width="1.1"/>
<line x1="116" y1="223" x2="470" y2="144" stroke="currentColor" stroke-opacity="0.3" stroke-width="1.1"/>
<rect x="474" y="112" width="214" height="52" rx="3" fill="currentColor" fill-opacity="0.1" stroke="currentColor" stroke-opacity="0.6" stroke-width="1.5"/>
<text x="581" y="134" text-anchor="middle" font-size="11">RFC 9293</text>
<text x="581" y="152" text-anchor="middle" font-size="10" fill-opacity="0.8">August 2022</text>
<text x="14" y="256" font-size="10" fill-opacity="0.75">793 was published in 1981 and itself obsoleted RFC 761</text>
</g>
</svg>
<figcaption>The document people mean when they say the TCP specification is the one at the top left, and it stopped being that in 2022. Six other documents had accumulated around it over forty years, each fixing or clarifying part of the protocol, and reading the specification meant reading all seven and knowing which parts of the oldest had been overruled. RFC 9293 is what happens when somebody does that work and publishes the result: one document, one place to look, and a list at the front of everything it swallowed.</figcaption>
</figure>

<details class="deeper">
<summary>If you already work with specifications: why permanence rather than versioning, and what it costs</summary>

The alternative is obvious and everybody who meets the series wonders why it was
not chosen. Give each document a version number, edit in place, and let readers
fetch the current one.

The reason not to is that a specification is cited by things that cannot be
updated. Contracts, court filings, conformance test suites, certification
programmes, the comments in twenty year old source code, and other
specifications. If a document can change under a citation, then a citation
establishes nothing, and the sentence somebody relied on in 2009 may not be there
when a dispute arrives in 2031. Permanence means a reference to RFC 793 section
3.4 is the same text forever.

The cost is that currency has to be tracked separately from content, which is
exactly the failure mode at the top of this page. You cannot tell by reading a
document whether it is the one to read. You have to ask the index.

There is a smaller cost that catches people out. Because errors cannot be fixed
in place either, corrections live in a separate errata system, and a verified
erratum can change what a clause means without changing a byte of the clause. So
the complete answer to "what does this document require" is the document, plus
its errata, plus anything that updates it, and only the first of those three is
in the file you downloaded.

</details>

## Status does not mean what it looks like

Every RFC carries a status, and the words are ordinary English arranged to look
like a ranking. They are, but not the ranking most people assume.

<details class="predict">
<summary>Six documents, including the one securing every web request you make today. Which of them do you expect has reached the top of the standards track?</summary>

```bash
# Debian 13 (trixie), x86_64
$ for n in 1035 9110 4271 8446 2119 8174; do curl -s https://www.rfc-editor.org/rfc/rfc$n.json | jq -r "\"\(.doc_id)  \(.status)  \(.title)\""; done
RFC1035  INTERNET STANDARD  Domain names - implementation and specification
RFC9110  INTERNET STANDARD  HTTP Semantics
RFC4271  DRAFT STANDARD  A Border Gateway Protocol 4 (BGP-4)
RFC8446  PROPOSED STANDARD  The Transport Layer Security (TLS) Protocol Version 1.3
RFC2119  BEST CURRENT PRACTICE  Key words for use in RFCs to Indicate Requirement Levels
RFC8174  BEST CURRENT PRACTICE  Ambiguity of Uppercase vs Lowercase in RFC 2119 Key Words
```

</details>

Three things in that output are worth stopping on.

**TLS 1.3 is a Proposed Standard.** The protocol securing essentially every web
request made today sits at the first rung of the standards track, and that is
completely normal. Advancing a document costs effort that nobody is paid for and
that changes nothing about deployment, so most documents stop where they were
published and are implemented by everybody anyway.

**BGP-4 is a Draft Standard, and that level no longer exists.** RFC 6410 reduced
the standards track from three levels to two, and documents already sitting at the
middle one kept their label. So a status can be an artefact of when a document was
classified rather than a description of anything current.

**Best Current Practice is a separate track.** It is not a lower or higher rung. It
is what the community does, published so it can be cited, and the two documents
defining what MUST means are on it.

<details class="deeper">
<summary>If you sit in standards meetings: why almost nothing advances, and what that says about the process</summary>

Advancement was designed as evidence gathering. To move up, a specification needed
independent implementations that interoperated, and the requirement existed
because a specification only one person has implemented has not been tested as a
specification: any ambiguity in it is resolved consistently by accident.

In practice the incentive is missing. By the time two implementations interoperate,
the people who would do the paperwork have moved on to the next problem, and
nothing about being a Proposed Standard prevents anybody deploying the protocol
worldwide. So the evidence that advancement was meant to collect gets collected in
the field instead, in the form of bug reports and interoperability events, and the
document sits at level one forever.

This is worth knowing for a reason beyond trivia. When somebody dismisses a
specification as "only a proposed standard", they have misread the process rather
than found a weakness. And when somebody treats Internet Standard as a mark of
quality, they have mostly found a document old enough that somebody once cared
about the paperwork.

</details>

## The two most expensive words

A specification is mostly prose, and a small part of it is binding. The convention
that separates them is RFC 2119, which assigns special meaning to a short list of
words when written in capitals, and RFC 8174, which exists because people kept
using the lowercase forms and arguing about whether they counted.

```bash
# Debian 13 (trixie), x86_64
$ T=$(curl -s https://www.rfc-editor.org/rfc/rfc9293.txt); for k in "MUST NOT" "SHOULD NOT" "MUST" "SHOULD" "MAY"; do printf "%-11s %s\n" "$k" "$(printf "%s" "$T" | grep -oE "\b$k\b" | wc -l)"; done
MUST NOT    7
SHOULD NOT  8
MUST        228
SHOULD      40
MAY         58
```

The word boundaries mean the 228 includes the seven negative forms and the 40
includes the eight, which is a thing to watch when counting anything with `grep`.
The proportions survive it. TCP is specified with roughly five times as many
absolute requirements as recommendations, which is what a protocol looks like when
the consequences of divergence are severe.

The distinction that costs money is the second one. MUST is a requirement:
implementations that do otherwise are wrong, and that is a defect somebody will
accept as a defect. SHOULD is defined by RFC 2119 as meaning there may be valid
reasons in particular circumstances to ignore the item, but that the full
implications have to be understood first.

Which is where interoperability failures live. Two implementations can both
conform, one having taken the recommendation and one having decided it had a valid
reason, and the resulting behaviours can be incompatible without either being a
bug. When you are debugging a disagreement between two products and both vendors
insist they follow the specification, look for a SHOULD.

<details class="deeper">
<summary>If you have argued with a vendor: the principle that made this worse, and the document that revisited it</summary>

The early series carried an instruction that shaped decades of implementation
practice: be conservative in what you send, and liberal in what you accept. It
sounds like generosity and it was written when the network was small and the
priority was getting things to work at all.

The trouble is what happens over time. If every receiver accepts input that the
specification did not permit, then senders producing that input never find out
they are wrong, and the accepted-in-practice set drifts away from the
specified set. A later implementer reads the document, implements it correctly,
and fails to interoperate with a deployed base that has been accepting sloppiness
for twenty years. The specification has been overtaken by the tolerance of its
implementations.

RFC 9413 revisits the principle and works through the failure mode in detail. Its
argument is not that tolerance is wrong but that it has to be paired with
something that surfaces the divergence: logging what was accepted but should not
have been, testing against the specification rather than against the incumbent,
and treating a growing set of accepted variations as a maintenance problem rather
than as a feature.

The practical version for anybody operating a network rather than writing one is
shorter. When a new device fails to talk to an old one, the new device is not
automatically at fault, and "it works with everything else" is evidence about the
deployed base rather than about the specification.

</details>

## What is not the document

Three things get quoted as though they were a specification and none of them is.

**An internet-draft.** Drafts are working documents with a six month expiry
stamped into them. Some become RFCs, most do not, and a draft that expired in 2014
is still on the internet and still turns up in search results. The filename is the
giveaway: anything beginning `draft-` is a proposal.

**An errata report.** Anybody can submit one. The useful ones are marked verified,
which means an appointed editor agreed it was an error, and those genuinely change
what the document means. Reported-but-unverified errata sit alongside them and
carry no weight at all, so the status on the report is the thing to read.

**A vendor's documentation of a standard.** It describes what that vendor
implemented, which is a fact about a product. It is often clearer than the
specification and it is not evidence about what anybody else does, which matters
precisely when you are trying to work out why two products disagree.

## Everything that is not an RFC

The internet series is unusually open. Most of the other bodies this track cites
are not, and each has a different way in.

| Body | What you get free | What costs |
| --- | --- | --- |
| IETF | Everything, forever, at rfc-editor.org | Nothing |
| IEEE | 802 standards through the GET program, after accepting the terms | Other families |
| ISO and IEC | The scope and the table of contents on the catalogue page | The document |
| ITU-T | Many recommendations in full, some only in summary | Varies by recommendation |

The IEEE one is worth acting on rather than reading about. Every 802 standard this
track cites, including the whole of 802.11 and 802.3, can be downloaded at no cost
through the GET program. That is several thousand pages of primary source about
Ethernet and wireless that most people assume is behind a paywall, and it is the
answer whenever a claim about frame formats or radio behaviour needs settling.

For the ones that genuinely are paid, the scope statement on the catalogue page is
free and is often enough. It tells you what the document covers, which is usually
the question you actually had, and it settles arguments about whether a standard
says anything about a subject at all.

## Prove it

**Check whether a document you cite is current.** Take any RFC number you have
used in an argument and fetch its JSON metadata. If `obsoleted_by` is not empty,
you have been quoting a superseded document, and the replacement is named.

**Read the definition of SHOULD.** RFC 2119 is one page. Read the SHOULD entry and
notice that it does not say optional. It says there may be valid reasons to ignore
it and that the implications have to be understood first, which is a much higher
bar than the way the word is usually treated.

**Download an 802 standard.** Go to the GET program, accept the terms, and get
802.11 or 802.3. Then look up something this track asserted, of your own choosing,
and check it. Doing that once changes how you read every claim afterwards,
including the ones on these pages.

## What trips people up

### 1. Citing RFC 793

It has been superseded since 2022 and its status still reads Internet Standard.
The current document is RFC 9293, and it absorbed six other documents at the same
time.

### 2. Reading status as importance

The maturity level says how far a document travelled through a process that most
documents never bother to finish. TLS 1.3 is a Proposed Standard and runs
essentially all secure web traffic.

### 3. Treating SHOULD as optional

It means a deviation needs a reason you can defend and whose consequences you have
worked out. An implementation that ignores a SHOULD casually is not conformant in
any useful sense.

### 4. Quoting a draft

A `draft-` document is a proposal that expires after six months. Some have been
expired for a decade and are still the first search result for their subject.

### 5. Assuming the document is the whole answer

Errata that have been verified change what a clause means, and an updating
document changes part of it without replacing it. Both are listed on the index
page and neither is in the file.

### 6. Paying for an 802 standard

They are available at no cost through the GET program. This one is worth checking
before any procurement conversation about conformance.

## Work it through

Two vendors' equipment will not form a link aggregation with each other. Each
support desk says its product follows the standard, and each has sent a document
extract that appears to support it.

Start by establishing which document. Link aggregation moved between IEEE
standards over the years, so the first question is whether the two extracts even
come from the same one, and the second is whether either is current. Both are
answerable from the catalogue pages without opening anything.

Then get the actual text rather than the extracts. This is an 802 standard, so it
is free through the GET program, and the extracts each vendor sent are their own
paraphrases of it. Two paraphrases that disagree tell you nothing about which
behaviour the standard requires.

Then read the clause for its verbs. If the behaviour in dispute is a MUST, one
vendor has a defect and the conversation becomes a bug report with a citation. If
it is a SHOULD, both may be conformant, and the question changes from who is wrong
to which of the two can be configured to match the other, which is a different and
much more productive conversation to have.

And record what you found. The next person to hit this will be somebody in your
own organisation in two years, and the useful artefact is not the resolution but
the clause number and the sentence that decided it.

## Try it

**Fetch the metadata for three RFCs you have cited.** The JSON at
`rfc-editor.org/rfc/rfcNNNN.json` gives the title, the status, and both obsoletes
relationships in one line each. It takes a minute and occasionally it is
embarrassing.

**Open the errata for a protocol you rely on.** Every RFC has an errata page. Look
at one for a protocol you operate and read the verified entries, which are the
places where the published text is wrong and everybody has agreed it is.

**Take one claim from this track and check it against a primary source.** Every
topic lists its sources with the date each was read. Pick one, follow it, and find
the sentence. That is the habit the whole reference apparatus exists to make
possible, and it is worth exercising at least once.

## Check yourself

<details class="qa">
<summary>An RFC's status says INTERNET STANDARD. Does that mean it is the document to read?</summary>

No. The status records the maturity level the document reached and says nothing
about whether it has since been replaced. RFC 793 says Internet Standard and was
obsoleted by RFC 9293 in 2022. The field to check is obsoleted_by.

</details>

<details class="qa">
<summary>What is the difference between one document obsoleting another and updating it?</summary>

Obsoleting replaces it entirely, so the old document is history and the new one is
what you read. Updating changes part of it, so both remain in force and the
complete requirement is the original text as modified by the updating document.

</details>

<details class="qa">
<summary>Two products disagree and both claim conformance. What is the first thing to look for in the specification?</summary>

A SHOULD. A requirement written as MUST makes one of them wrong. A recommendation
allows both to conform while behaving differently, provided each had a reason,
which is exactly the situation that produces this argument.

</details>

<details class="qa">
<summary>Why can a published RFC not simply be corrected when an error is found?</summary>

Because it is cited by things that cannot be updated, and a citation to a document
that can change establishes nothing. Corrections are recorded as errata against
the unchanged text, and substantive changes require a new document.

</details>

<details class="qa">
<summary>How do you read IEEE 802.3 without paying for it?</summary>

Through the IEEE GET program, which makes the 802 family available at no charge
once you accept its terms. It covers the whole family, so 802.11 and 802.1Q are
available the same way.

</details>

## References

- [RFC 2026](https://www.rfc-editor.org/rfc/rfc2026) - IETF, the standards process itself, for what the maturity levels were meant to establish. Free. Accessed 2026-08-20.
- [RFC 6410](https://www.rfc-editor.org/rfc/rfc6410) - IETF, which reduced the track to two levels and left existing Draft Standards where they were. Free. Accessed 2026-08-20.
- [RFC 2119](https://www.rfc-editor.org/rfc/rfc2119) - IETF, the requirement keywords, and the definition of SHOULD quoted above. Free. Accessed 2026-08-20.
- [RFC 8174](https://www.rfc-editor.org/rfc/rfc8174) - IETF, which settles that only the uppercase forms carry the special meaning. Free. Accessed 2026-08-20.
- [RFC 9293](https://www.rfc-editor.org/rfc/rfc9293) - IETF, the current TCP specification and the list of what it replaced. Free. Accessed 2026-08-20.
- [RFC 9413](https://www.rfc-editor.org/rfc/rfc9413) - IETF, on the robustness principle and what tolerating non-conformance costs over time. Free. Accessed 2026-08-20.
- [RFC Editor](https://www.rfc-editor.org/) - the index, the errata system, and the metadata used in the captures. Free. Accessed 2026-08-20.
- [IEEE GET Program](https://standards.ieee.org/products-programs/ieee-get-program/) - IEEE Standards Association, how to obtain any 802 standard at no cost. Free. Accessed 2026-08-20.

**Where the output came from.** Three captured blocks through `capture.sh` on the
image named in each header, each one a live query to the RFC Editor's own metadata
and text. The keyword counts are `grep` on the published text of RFC 9293 and are
reproducible against it. The statements about what the maturity levels mean come
from RFC 2026 and RFC 6410 rather than from the captures, which only show what the
status fields currently say.

**Why this is not in the lesson count.** No part of the exam asks about the
standards process. It is here because this track asks a reader to look up a named
clause as one of its three forms of evidence, and had never said how.
