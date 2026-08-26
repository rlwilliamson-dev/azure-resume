---
title: "Application and cryptographic attacks"
description: "Why the dots in a traversal request are ordinary path syntax, what actually stops one, and why an attack on cryptography usually goes after the negotiation rather than the algorithm, with the birthday bound measured instead of quoted."
deck: "The application logs show a request for a filename with a lot of dots in it"
track: "security-plus"
level: "working"
order: 220
objectives:
  - "Explain what a directory traversal request does and why the dots are ordinary path syntax"
  - "Name the application attacks in this objective and say what each one targets"
  - "Distinguish forgery from replay"
  - "Explain why a cryptographic attack usually goes after the negotiation rather than the algorithm"
  - "Say what the birthday bound is and why it is the square root of the digest size"
  - "Say where a traversal defence has to sit in the order of operations"
prerequisites: ["physical-and-network-attacks"]
tags: ["security-plus", "security", "threats", "cryptography"]
updated: 2026-08-26
draft: false
examObjectives:
  - exam: "sy0-701"
    domain: "2.0"
    objective: "2.4"
sources:
  - title: "CWE-22, Improper Limitation of a Pathname to a Restricted Directory"
    url: "https://cwe.mitre.org/data/definitions/22.html"
    publisher: "MITRE"
    accessed: 2026-08-26
    tier: 1
  - title: "CWE-352, Cross-Site Request Forgery"
    url: "https://cwe.mitre.org/data/definitions/352.html"
    publisher: "MITRE"
    accessed: 2026-08-26
    tier: 1
  - title: "RFC 8446, The Transport Layer Security Protocol Version 1.3"
    url: "https://www.rfc-editor.org/rfc/rfc8446.html"
    publisher: "IETF"
    accessed: 2026-08-26
    tier: 1
  - title: "RFC 7457, Summarizing Known Attacks on TLS and DTLS"
    url: "https://www.rfc-editor.org/rfc/rfc7457.html"
    publisher: "IETF"
    accessed: 2026-08-26
    tier: 1
  - title: "SP 800-107 Rev. 1, Recommendation for Applications Using Approved Hash Algorithms"
    url: "https://csrc.nist.gov/pubs/sp/800/107/r1/final"
    publisher: "NIST"
    accessed: 2026-08-26
    tier: 1
symptoms:
  - symptom: "A request arrives for a path that climbs out of the document root"
    anchor: "what-the-dots-actually-do"
  - symptom: "A connection negotiated a weaker cipher than the server supports"
    anchor: "the-cryptographic-half"
---

> **Before you read.** The web server log has one line in it that nobody can
> explain. A request came in for `/%2e%2e/%2e%2e/etc/passwd`, the server returned
> 200, and the file it served was eleven directories above the site.
>
> **Which component made the mistake?**

Possibly none of them, in the sense that every piece behaved as documented. The
application checked the requested path for `..` before opening anything, found
none, and handed the string to the operating system. The operating system decoded
nothing, because the decoding had already happened somewhere between those two
steps, and then resolved a perfectly ordinary relative path. Two correct components
in the wrong order produced a file disclosure.

That is the shape of most of this objective. The attacks here are rarely a matter
of breaking something. They are a matter of using a mechanism exactly as it was
built while the defender was looking at a different layer.

### Some words you will need

<dl class="terms">
<dt>injection</dt>
<dd>Supplying input that the receiving system parses as instructions rather than as data.</dd>
<dt>buffer overflow</dt>
<dd>Writing past the end of an allocation, into memory holding something else.</dd>
<dt>replay</dt>
<dd>Capturing a valid message and sending it again unchanged.</dd>
<dt>forgery</dt>
<dd>Producing a message the recipient accepts as coming from somebody else.</dd>
<dt>privilege escalation</dt>
<dd>Moving from the rights you were given to rights you were not.</dd>
<dt>directory traversal</dt>
<dd>Making a path escape the directory the application meant to confine it to.</dd>
<dt>canonicalisation</dt>
<dd>Reducing a name with many spellings to the one form the system will actually use.</dd>
<dt>downgrade</dt>
<dd>Causing two parties to agree on a weaker option than both support.</dd>
<dt>collision</dt>
<dd>Two different inputs with the same digest.</dd>
<dt>birthday attack</dt>
<dd>Searching for any collision rather than a collision with one chosen value.</dd>
</dl>

## What the dots actually do

The traversal request looks like an exotic string and is nothing of the kind. It is
the relative path syntax every filesystem has had for fifty years, arriving from
outside instead of from a person at a keyboard.

<details class="predict">
<summary>Four request paths, one document root. Predict which of them stay inside it, and which a check for ".." would catch.</summary>

```bash
# AlmaLinux 10.2, x86_64
$ where-does-it-land
document root: /srv/www
request path                 .. in raw  resolves to            inside
/logo.png                    no         /srv/www/logo.png      yes
/../../etc/passwd            yes        /etc/passwd            no
/%2e%2e/%2e%2e/etc/passwd    no         /etc/passwd            no
/backup/passwd               no         /etc/passwd            no
```

**Three of the four escape, and a check for `..` in the raw request catches one of
them.**

Go through the failures rather than the arithmetic. The second row is the honest
version of the attack and the only one a naive filter sees. The third row is the
same request with the dots written in percent encoding, so the filter finds no dots
at all, and the decoder that runs later supplies them. The fourth row contains no
dots in any encoding: it is a symbolic link that happens to point out of the root,
which is a traversal that never involved traversal syntax.

So the pattern is not really about dots. It is about a gap between the name the
application inspected and the name the system opened, and any transformation
applied in that gap creates one. Percent decoding is a transformation. Symbolic
link resolution is a transformation. Unicode normalisation is a transformation on
some platforms, which the comparison further down this page shows.

Notice also what the last column is doing. `inside` is computed after resolution,
against the resolved path, which is the only comparison that means anything. The
filter got it wrong because it compared before the resolution rather than after.

</details>

**Which gives the rule.** Resolve the path first, then decide, and compare the
resolved path against the root. Everything else is a guess about what the string
will turn into.

<details class="deeper">
<summary>If you are writing the check: the three defences, and why two of them keep failing</summary>

Traversal is old enough that the failed defences are as well documented as the
attack, and they fail in ways worth recognising because the same mistakes appear
against injection.

**Rejecting bad input fails because the list is never finished.** A filter for `..`
misses `%2e%2e`, and adding that misses `%252e%252e` where a decoder runs twice,
and adding those misses the overlong UTF-8 forms that some parsers used to accept.
Every entry on the list is a spelling somebody thought of. The attacker only needs
one nobody did.

**Rejecting bad input at the wrong moment fails even when the list is right.** This
is the capture above. The check can be perfectly written and still be looking at a
string that has not finished becoming a path. Order matters more than content.

**Resolving and then comparing works, and is unglamorous.** Take the requested
path, join it to the root, resolve it fully, including symbolic links, then check
that the result is still under the root with a separator after it. That last detail
matters: comparing against the string `/srv/www` alone accepts `/srv/wwwroot`,
which is a different directory whose name begins the same way.

**Not putting it on the filesystem at all works better.** If the request selects
from a table of permitted identifiers and the application looks up the real path,
there is nothing to escape from, because the user's string never becomes a path.
That is more work to build and it removes the whole class rather than one instance
of it, which is the trade the exam wants you to be able to state.

The residual, worth being honest about: a resolution check has a race in it. The
path is resolved, then it is opened, and something can change in between. Opening
first and then verifying the descriptor closes it, and most applications never
bother, which is a defensible choice for a web root and not one for a system that
handles paths on behalf of other users.

</details>

## Six ways in, and what each one targets

The objective names a set of application attacks. They are easier to hold apart by
what each one takes advantage of than by what each one is called.

**Injection takes advantage of a parser.** Input arrives where a system expects
data, and that system passes it somewhere that reads it as instructions. SQL is the
familiar case and far from the only one: a shell, an LDAP filter, an XML parser and
a template engine all have the same structure. The defence is always the same
shape, which is to keep the data out of the instruction stream rather than to clean
the data, because cleaning is the losing list from the panel above.

**Cross-site scripting is injection into the browser.** Input from one user is
stored or reflected and then executed in another user's session, with that user's
rights on that site. It gets its own name in the objective and it belongs to the
same family.

**A buffer overflow takes advantage of an allocation.** A program writes more into a
region of memory than the region holds, and the write continues into whatever came
next, which may be another variable, a saved return address, or a pointer the
program will use later. The consequences run from a crash to arbitrary code
execution, and which one you get depends on what was next in memory.

**Privilege escalation takes advantage of a rights boundary.** Vertical means
moving to a higher level of rights than the account holds, usually by abusing
something that already runs with those rights. Horizontal means staying at the same
level and reaching another user's data, which sounds less serious and is often
worse, because the horizontal case is where the records are.

**Replay takes advantage of a valid message.** Something legitimate is captured and
sent again. Nothing is modified and nothing is broken, which is why encryption does
not stop it.

**Forgery takes advantage of trust in an identifier.** A request is constructed so
the receiver treats it as coming from somebody who never sent it. In the web case,
the browser attaches the session cookie automatically because that is what browsers
do, so a request originating on another site arrives fully authenticated.

**Directory traversal takes advantage of path syntax**, which is the whole of the
section above.

<details class="deeper">
<summary>Forgery and replay look alike on the wire. Where the distinction actually bites</summary>

Both produce a request the server accepts and neither requires breaking any
cryptography, so the difference sounds academic until you have to choose a defence.

**Replay reuses a message that existed.** The attacker had to observe it, and every
byte of what they send was authored by somebody legitimate. What they gain is
whatever that one message did, repeated.

**Forgery composes a message that never existed.** The attacker chooses the
contents. They need no captured traffic, only a way to make the victim's client
send it, and what they gain is whatever they can express in a request.

That difference decides the fix. Replay is stopped by making a message usable once:
a nonce the server remembers, a sequence number, a timestamp with a short window.
None of that helps against forgery, because the forged request is fresh and its
nonce is whatever the attacker's page just fetched.

Forgery is stopped by binding the request to something the attacker cannot read
across an origin boundary: an anti-forgery token in the body rather than in an
automatically attached cookie, a cookie the browser refuses to send on cross-site
requests, or a check on where the request claims to have come from. All three work
because the browser will attach a cookie for anybody but will not read a value back
out for anybody.

**And a defence against one can weaken the other.** Widening the replay window to
be tolerant of clock skew gives a replayed message longer to be useful. Tightening
it produces support calls from a device with a drifting clock. That is a real
trade-off with no correct answer, only a chosen one, and topic 61 has the forensic
version of the same clock problem.

</details>

## The cryptographic half

The second group in this objective are attacks on cryptography, and the useful
generalisation is that almost none of them attack the mathematics. Modern
primitives are not where the weakness is. The negotiation that chooses them is.

<details class="predict">
<summary>One server with one key and a fixed list of what it will accept. Three clients connect. Predict how many different ciphers get agreed.</summary>

```bash
# AlmaLinux 10.2, x86_64
$ negotiate
server accepts: ECDHE-RSA-AES256-GCM-SHA384:AES128-SHA256
                plus TLS_AES_256_GCM_SHA384

client offered           agreed    agreed cipher                key exchange
everything               TLSv1.3   TLS_AES_256_GCM_SHA384       any
1.2, full list           TLSv1.2   ECDHE-RSA-AES256-GCM-SHA384  ECDH
1.2, AES128-SHA256       TLSv1.2   AES128-SHA256                RSA
```

**Three connections, three outcomes, and the server never changed.**

Everything on the server side was constant: the same certificate, the same private
key, the same list of what it was willing to accept. What varied was the first
message. A client that offered everything it supports got the strongest thing on
the list. A client that said it only spoke TLS 1.2 got the best of what remained.
A client that offered one specific weak suite got that suite, because the server
had agreed to accept it and the client asked for nothing else.

The last column is the part worth sitting with. `ECDH` means the two sides agreed a
key for this session and will discard it, so recording the traffic today and
stealing the server key next year yields nothing. `RSA` means the session key was
encrypted to the server's long-term key and travelled inside the connection, so
that same recording becomes readable the moment the key leaks. Same server, same
certificate, and the difference in what an attacker gets from a recording is total.

So the attacker's move is now obvious and it is not mathematical. Change the first
message.

</details>

<figure class="learn-figure">
<svg viewBox="0 0 720 300" role="img" aria-labelledby="negotiate-title" style="width:100%;height:auto;">
<title id="negotiate-title">The same TLS server negotiating twice, agreeing a forward-secret cipher with one client and an RSA key transport cipher with another, decided entirely by the client's first message</title>
<g fill="currentColor">
<text x="14" y="20" font-size="11">the same server, the same key, two different first messages</text>
<text x="14" y="44" font-size="9">one: the client offers everything it supports</text>
<text x="370" y="44" font-size="9">two: the client offers one weak option only</text>
<rect x="14" y="54" width="336" height="32" rx="3" fill="var(--accent)" fill-opacity="0.14" stroke="var(--accent)" stroke-width="1.3"/>
<rect x="370" y="54" width="336" height="32" rx="3" fill="var(--red)" fill-opacity="0.14" stroke="var(--red)" stroke-width="1.3"/>
<text x="24" y="74" font-size="9">ClientHello: ECDHE-RSA-AES256-GCM, AES128-SHA256</text>
<text x="380" y="74" font-size="9">ClientHello: AES128-SHA256</text>
<path d="M 182 88 V 110" stroke="currentColor" stroke-opacity="0.45" stroke-width="1"/>
<path d="M 538 88 V 110" stroke="currentColor" stroke-opacity="0.45" stroke-width="1"/>
<rect x="14" y="112" width="336" height="32" rx="3" fill="var(--accent)" fill-opacity="0.14" stroke="var(--accent)" stroke-width="1.3"/>
<rect x="370" y="112" width="336" height="32" rx="3" fill="var(--red)" fill-opacity="0.14" stroke="var(--red)" stroke-width="1.3"/>
<text x="24" y="132" font-size="9">ServerHello: ECDHE-RSA-AES256-GCM-SHA384</text>
<text x="380" y="132" font-size="9">ServerHello: AES128-SHA256</text>
<text x="14" y="168" font-size="10">agreed: TLSv1.2, key exchange ECDH</text>
<text x="370" y="168" font-size="10">agreed: TLSv1.2, key exchange RSA</text>
<text x="14" y="188" font-size="9" fill-opacity="0.8">a key agreed for this session and thrown away after</text>
<text x="370" y="188" font-size="9" fill-opacity="0.8">the session key sent under the long-term key</text>
<text x="14" y="226" font-size="10">the server never changed. Same certificate, same key, same list of what it accepts</text>
<text x="14" y="246" font-size="10">what changed is the first message, sent before either side has authenticated anything</text>
<text x="14" y="274" font-size="9" fill-opacity="0.7">so an attacker in the path edits the offer rather than the cipher, and both sides then agree honestly</text>
</g></svg>
<figcaption>Two handshakes against one unchanged server, drawn from the measured capture above. The right-hand column is not a broken connection. It is a correct, successful, fully valid TLS session that happens to have no forward secrecy, agreed by two parties following the protocol exactly. The reason a downgrade works is visible in the vertical position of the first box: the client's offer is the opening message of the conversation, so there is nothing yet with which to authenticate it, and an attacker who can edit that one message chooses the outcome without touching a cipher. Every defence against downgrade is therefore a way of checking, later in the handshake, that the earlier messages arrived as sent.</figcaption>
</figure>

<details class="deeper">
<summary>Downgrade is a protocol design failure rather than an implementation bug, and the fix has a shape</summary>

It is tempting to file downgrade under "somebody left an old cipher enabled", and
disabling old ciphers does help, but that framing misses why the class exists.

**Backwards compatibility requires the parties to discuss capability.** Two
endpoints that may be a decade apart in age have to establish what they can both
do, which means an exchange about what each supports before either can protect
anything. That exchange is unprotected by construction: there is no shared key yet,
because agreeing one is the thing being negotiated.

**So the offer is attacker-editable in principle**, and the design question is what
you do about it. The answer that works is to authenticate the negotiation
retrospectively. Once both sides do have keys, they compute a value over the
transcript of everything that was said and check that they agree. If a message was
edited in flight, the two transcripts differ and the handshake fails. TLS 1.3
carries this further by putting a recognisable pattern into the server's random
value when it deliberately answers as an older version, so a real 1.3 client can
tell an honest legacy answer from an edited one.

**Which is why the operational advice is narrower than it sounds.** Turning off old
versions and weak suites is worth doing, and its real effect is to shrink what a
successful downgrade can reach. If the weakest thing on your list is still
acceptable, the negotiation being editable costs you nothing.

**And it generalises past TLS.** Any protocol with an upgrade step has this
problem. Mail that offers STARTTLS in a cleartext banner can have the offer
stripped, and the client that falls back to cleartext does so silently. The pattern
to recognise is an unprotected message that decides how protected everything after
it will be.

</details>

## Collision, and why the bound is a square root

The last cryptographic idea in the objective is the one people quote most and
compute least, so this section measures it.

A collision is two different inputs with the same digest. A birthday attack is the
search for any such pair rather than a pair involving one chosen document, and the
distinction is the entire reason the numbers are what they are.

<details class="predict">
<summary>Searching SHA-256 truncated to 32 bits. Predict roughly how many digests it takes to find two that match.</summary>

```bash
# AlmaLinux 10.2, x86_64
$ birthday
digest bits  digests tried    2^(n/2)            2^n
         16            259        256         65,536
         24          3,904      4,096     16,777,216
         32         88,799     65,536  4,294,967,296
         40      1,602,759  1,048,576 1,099,511,627,776
```

**Around sixty-five thousand rather than four billion.**

The measured column sits close to the third column and nowhere near the fourth,
which is the whole finding. Finding a collision took a number of attempts near the
square root of the number of possible digests, not near the number itself.

The reason is combinatorial rather than cryptographic. Every new digest you compute
is compared against every digest you already have, so after n attempts you have
made roughly n squared over two comparisons rather than n. The comparisons are
where the collisions come from, and they grow as the square of the work.

The measured numbers run a little above the square root, which is expected: the
constant works out near 1.25 and the runs here are averages over a handful of
searches, so they wobble. What does not wobble is the gap between column two and
column four. At 40 bits the difference between the search that ran and the search
nobody would attempt is a factor of about seven hundred thousand.

</details>

**The exam consequence is the halving.** A digest of n bits offers about n over two
bits of collision resistance, so SHA-256 gives you 128 bits against collision and
256 bits against somebody trying to match one specific digest you already hold.
Those are different problems with different costs, and a question that says
"collision" is asking about the smaller number.

<details class="deeper">
<summary>What the square root actually costs, and why a collision is worth anything at all</summary>

**The memory is the part people forget.** The search above kept every digest it had
seen, so finding a collision at 40 bits meant holding roughly a million values. At
128 bits the same naive method needs 2 to the 64th stored values, which is not a
budget problem, it is a physics problem. There are cycle-finding methods that trade
that memory away for more computation and parallelise well, and they are why a
128-bit collision bound is treated as a real bound rather than an unreachable one.

**And the second question is why anybody cares.** A random pair of colliding inputs
is worthless. What made collision attacks matter historically was the ability to
construct two meaningful documents that collide: a certificate request the
authority will sign and a second certificate that shares its digest, or two
executables with the same signature. That takes a construction, not a search, and
it is the reason a hash function is retired when the first practical collision
appears rather than when the first exploited one does.

**Which explains the retirement pattern.** A digest with a known collision method
stays perfectly good for the jobs where a second input is not attacker-chosen, such
as detecting accidental corruption, and it becomes unusable for signatures and
certificates on the same day. Those two facts sit awkwardly together and are both
true, which is why you still find older digests in checksum files long after they
left the signing path.

**One more distinction the objective expects.** Preimage resistance is about being
given a digest and finding any input that produces it, and it costs the full n
bits. Second preimage resistance is about being given an input and finding a
different one with the same digest, also the full n bits. Collision resistance is
the only one of the three where you get to choose both inputs, and it is the only
one that halves.

</details>

## Across platforms

A traversal defence is a question about how many spellings of a filename reach one
file, and that is answered by the operating system rather than by the application.
The answers differ enough to change what a defence has to do.

**Linux resolves the dots and the symbolic links and is otherwise literal about
bytes**, which the capture at the top of this page shows. Two names that differ by
one byte are two files, so a comparison after resolution is reliable.

**Windows accepts several spellings of one name.**

```powershell
# Microsoft Windows Server 2025 Datacenter, version 10.0.26100.0
> [System.IO.Path]::GetFullPath('C:\inetpub\wwwroot\..\..\Windows\win.ini')
C:\Windows\win.ini

# Whether a forward slash separates here too, since a check written for URLs may only look for one of them
> [System.IO.Path]::GetFullPath('C:/inetpub/wwwroot/../../Windows/win.ini')
C:\Windows\win.ini

# Set up one file with known contents to ask the rest of the questions against
> $p = Join-Path $env:TEMP 'pathrules'; New-Item -ItemType Directory -Force -Path $p > $null; Set-Content -Path (Join-Path $p 'secret.txt') -Value 'contents' -NoNewline; $p
C:\Users\RUNNER~1\AppData\Local\Temp\pathrules

# Which spellings of that one filename the operating system accepts as the same file
> foreach ($n in 'secret.txt', 'SECRET.TXT', 'secret.txt.', 'secret.txt ', 'secret.txt::$DATA') { $v = 'refused'; try { $v = Get-Content -LiteralPath (Join-Path $p $n) -ErrorAction Stop } catch { }; '{0,-22} {1}' -f $n, $v }
secret.txt             contents
SECRET.TXT             contents
secret.txt.            contents
secret.txt             contents
secret.txt::$DATA      contents

# Whether the file has a second, shorter name nobody asked for
> cmd /c dir /x $p 2>&1 | Select-String 'secret'
08/26/2026  11:24 PM                 8              secret.txt
```

Every spelling reached the file. The trailing dot and the trailing space are
stripped by the filesystem API, so a deny list holding `secret.txt` does not match
`secret.txt.` while the open call reaches the same bytes. The stream suffix is the
NTFS syntax for naming the default data stream explicitly, which is another name
for the same content. Case is folded, so a list written in lower case does not
recognise a request in upper. The short-name column of the last line is empty,
which is worth noting because 8.3 name generation used to supply another alias
again and is disabled on modern volumes.

**macOS folds case as well, and also folds Unicode.**

```bash
# macOS 26.5.2, arm64
$ python3 -c 'import os; print(os.path.realpath("/Library/WebServer/Documents/../../../etc/passwd"))'
/private/etc/passwd

# What the boot volume's format is, since APFS names case sensitivity when it has it
$ diskutil info / | grep -i 'personality'
   File System Personality:   APFS

# Which spellings of one filename reach the same file
$ d=$(mktemp -d); printf 'contents' > "$d/secret.txt"; for n in secret.txt SECRET.TXT Secret.Txt 'secret.txt ' './secret.txt'; do printf '%-16s %s\n' "$n" "$(cat "$d/$n" 2>/dev/null || echo refused)"; done
secret.txt       contents
SECRET.TXT       contents
Secret.Txt       contents
secret.txt       refused
./secret.txt     contents

# Whether a name typed as one accented character and a name typed as two reach one file
$ d=$(mktemp -d); printf 'contents' > "$d/$(printf 'caf\xc3\xa9')"; printf 'two code points: %s\n' "$(cat "$d/$(printf 'cafe\xcc\x81')" 2>/dev/null || echo refused)"; ls "$d" | od -c | head -2
two code points: contents
0000000    c   a   f   é  **  \n                                        
0000006

# Whether paths that look unrelated reach the same directory
$ ls -ld /etc /var /tmp
lrwxr-xr-x@ 1 root  wheel  11 Jun 25 02:29 /etc -> private/etc
lrwxr-xr-x@ 1 root  wheel  11 Jun 25 02:29 /tmp -> private/tmp
lrwxr-xr-x@ 1 root  wheel  11 Jun 25 02:29 /var -> private/var
```

The case rows behave as Windows does, and the trailing space does not, which is a
small reminder that these are per-platform rules rather than a general
"case-insensitive" category. The accent row is the one with no Linux equivalent:
the file was created with the single code point for an accented character and
opened with the two code point sequence that renders identically, and the same file
came back. A deny list comparing bytes sees two different names. A user sees one.

The last line makes the symbolic link point again at a level people forget. `/etc`
is not a directory on macOS; it is a link into `/private`, so a resolved path
arrives somewhere with a different spelling than the one requested. Any comparison
against a root has to be made after resolution on every platform, and the reason
differs on each.

**The practical consequence for all three.** Do not compare names. Resolve to the
real path the system will open, then compare that against the root you intended.
Every alias described here disappears at resolution, which is what makes resolution
the only comparison worth making.

## Try it

**Resolve a path and see where it lands.** Take any document root on a machine you
own and ask the system to resolve a relative path from it. Try the percent-encoded
form through a decoder first, and notice which stage supplies the dots.

**Watch a negotiation change.** Connect to a server you run with a client
constrained to one older suite, and to the same server with no constraint at all.
Compare what was agreed. This is a client-side setting, so nothing on the server
needs changing to see the effect.

**Count the collision.** Truncate a digest to twenty bits and search for a
collision. Then truncate to twenty-four and do it again. The ratio between the two
answers is the thing worth seeing.

**Look for one order-of-operations bug.** In any application you work on, find the
place where user input is validated and the place where it is used, and count the
transformations in between. Any of them can be the gap.

## Check yourself

<details class="qa">
<summary>Why does a filter that rejects ".." fail to stop directory traversal?</summary>

Because it inspects a string that has not finished becoming a path. The capture on
this page shows a request written as `%2e%2e` containing no dots at the moment of
inspection, decoded afterwards, and resolving to a file two levels above the
document root. A fourth request contained no dots in any encoding and escaped
through a symbolic link.

The defence that works is to resolve the path fully and then compare the resolved
result against the root, with a separator, so that a directory whose name merely
begins the same way is not accepted.

</details>

<details class="qa">
<summary>What is the difference between forgery and replay?</summary>

Replay resends a message that genuinely existed, so the contents were authored by
somebody legitimate and the attacker had to observe it. Forgery constructs a
message that never existed, so the attacker chooses the contents and needs no
captured traffic.

The defences do not overlap. Replay is stopped by making a message usable once,
with a nonce, a sequence number or a short window. Forgery is stopped by binding
the request to something an attacker cannot read across an origin, such as a token
in the body rather than in an automatically attached cookie.

</details>

<details class="qa">
<summary>Why does a downgrade attack work against a correctly implemented protocol?</summary>

Because the message that decides which cipher is used is the opening one, sent
before either party has anything to authenticate it with. Backwards compatibility
requires the parties to discuss capability, and that discussion cannot be protected
by a key that has not been agreed yet.

The fix is retrospective: once both sides hold keys, they check a value computed
over the transcript of everything already said, so an edited message makes the
handshake fail. Removing weak options is still worth doing, and what it achieves is
limiting how far a successful downgrade can reach.

</details>

<details class="qa">
<summary>How much collision resistance does a 256-bit digest give, and why?</summary>

About 128 bits. Each new digest computed is compared against every digest already
held, so the number of comparisons grows as the square of the work and a collision
appears near the square root of the number of possible digests.

The measurement on this page finds a 32-bit collision in about 89,000 attempts
against a space of 4.3 billion. Preimage and second preimage resistance do not
halve, because those require matching one specific digest rather than finding any
matching pair.

</details>

<details class="qa">
<summary>Name three spellings of one filename that a byte comparison would treat as different files.</summary>

From the captures on this page: `secret.txt.` and `secret.txt ` on Windows, where a
trailing dot or space is stripped before the file is opened; `secret.txt::$DATA`,
the NTFS syntax for the default data stream; `SECRET.TXT` on both Windows and
macOS, where case is folded; and an accented name written as one code point or as
two on macOS, which render identically and reach one file.

All of them disappear if the path is resolved before it is compared, which is why
resolution rather than string matching is the defence.

</details>

## References

- [CWE-22](https://cwe.mitre.org/data/definitions/22.html) - MITRE, path traversal, with the encoding and symbolic link variants named separately. Free. Accessed 2026-08-26.
- [CWE-352](https://cwe.mitre.org/data/definitions/352.html) - MITRE, cross-site request forgery, for the forgery half of the forgery against replay distinction. Free. Accessed 2026-08-26.
- [RFC 8446](https://www.rfc-editor.org/rfc/rfc8446.html) - IETF, TLS 1.3, including the transcript check and the downgrade-detection pattern in the server random. Free. Accessed 2026-08-26.
- [RFC 7457](https://www.rfc-editor.org/rfc/rfc7457.html) - IETF, a catalogue of known attacks on TLS, which is the fastest way to see how many of them are negotiation attacks. Free. Accessed 2026-08-26.
- [SP 800-107 Rev. 1](https://csrc.nist.gov/pubs/sp/800/107/r1/final) - NIST, hash algorithm security strengths, where the collision figure of half the digest length is stated alongside the preimage figures. Free. Accessed 2026-08-26.

**Where the content came from.** The path resolution, the negotiation and the
collision search are captured from an AlmaLinux 10.2 container. The negotiation
runs a TLS server and three clients on the loopback address inside that container,
so nothing leaves it and no third party is involved; the clients differ only in
what they are configured to offer. The collision search hashes counters and counts
attempts, which measures the bound rather than attacking anything. The Windows and
macOS blocks come from disposable runners. No attack in this topic is demonstrated:
the traversal section resolves paths and prints where they point without opening
anything, and the buffer overflow, injection and forgery material stays described,
because showing those means performing them.

**If you also work on networks.** The Network+ track's
[encryption, certificates and PKI](/learn/network-plus/encryption-certificates-and-pki)
covers the negotiation from the operator's position, and
[access lists, filtering and security zones](/learn/network-plus/acls-filtering-and-security-zones)
covers what a filter can and cannot inspect.
