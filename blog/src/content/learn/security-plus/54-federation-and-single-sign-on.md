---
title: "Federation and single sign-on"
description: "What is actually asserted when one system trusts another's word about who you are, why OAuth is not authentication, what a signed token contains and who can read it, and what the identity provider concentrates."
deck: "You log in to one system and get access to eleven. None of them ever saw your password"
track: "security-plus"
level: "working"
order: 550
objectives:
  - "Say what a federated system is trusting and who it is trusting"
  - "Distinguish LDAP, OAuth and SAML by the job each one does"
  - "Read a signed token and say which parts anybody can read"
  - "Explain why OAuth is authorisation and OpenID Connect is authentication"
  - "Name what the identity provider concentrates and what follows from that"
  - "Say what single sign-on changes about a leaver process"
prerequisites: ["accounts-from-joiner-to-leaver"]
tags: ["security-plus", "security", "operations", "identity"]
updated: 2026-08-25
draft: false
examObjectives:
  - exam: "sy0-701"
    domain: "4.0"
    objective: "4.6"
sources:
  - title: "RFC 6749, The OAuth 2.0 Authorization Framework"
    url: "https://www.rfc-editor.org/rfc/rfc6749.html"
    publisher: "IETF"
    accessed: 2026-08-25
    tier: 1
  - title: "RFC 7519, JSON Web Token (JWT)"
    url: "https://www.rfc-editor.org/rfc/rfc7519.html"
    publisher: "IETF"
    accessed: 2026-08-25
    tier: 1
  - title: "OpenID Connect Core 1.0"
    url: "https://openid.net/specs/openid-connect-core-1_0.html"
    publisher: "OpenID Foundation"
    accessed: 2026-08-25
    tier: 1
  - title: "RFC 4511, Lightweight Directory Access Protocol (LDAP): The Protocol"
    url: "https://www.rfc-editor.org/rfc/rfc4511.html"
    publisher: "IETF"
    accessed: 2026-08-25
    tier: 1
  - title: "SP 800-63C, Digital Identity Guidelines: Federation and Assertions"
    url: "https://csrc.nist.gov/pubs/sp/800/63/c/final"
    publisher: "NIST"
    accessed: 2026-08-25
    tier: 1
symptoms:
  - symptom: "An application shows information from a token that nobody thought was readable"
    anchor: "what-is-actually-in-the-token"
  - symptom: "An OAuth integration is treated as proof of who the user is"
    anchor: "oauth-authorises-and-does-not-authenticate"
---

> **Before you read.** You sign in once and eleven applications let you in. None
> of them has your password, none of them ever had it, and none of them asked the
> others.
>
> **What is each of those eleven actually trusting, and what would it take to make
> all eleven wrong at once?**

Each one is trusting a signature from a party it decided to trust in advance. What
makes them all wrong at once is that party being wrong, which is the property
federation buys and the one it concentrates.

### Some words you will need

<dl class="terms">
<dt>identity provider</dt>
<dd>The system that authenticates people and makes statements about them. Abbreviated IdP.</dd>
<dt>relying party</dt>
<dd>The application that accepts those statements. Also called a service provider.</dd>
<dt>assertion</dt>
<dd>A signed statement about somebody, made by the IdP and read by the relying party.</dd>
<dt>federation</dt>
<dd>An arrangement where one organisation's identity decisions are accepted by another's systems.</dd>
<dt>single sign-on</dt>
<dd>Signing in once and reaching many systems. A user-visible consequence of federation, not the same thing.</dd>
<dt>LDAP</dt>
<dd>A protocol for querying a directory. Not federation, and frequently confused with it.</dd>
<dt>OAuth 2.0</dt>
<dd>A framework for granting an application limited access to something on your behalf. Authorisation.</dd>
<dt>OpenID Connect</dt>
<dd>A layer on top of OAuth that adds a statement about who you are. Authentication.</dd>
<dt>SAML</dt>
<dd>An older standard doing the same job with signed XML instead of tokens.</dd>
</dl>

## What breaks without this

**An OAuth integration is treated as a login.** The application receives an access
token, concludes the user is who they claim, and has accepted something that was
never a statement about identity.

**A token's contents are assumed private.** Group memberships, email addresses and
internal identifiers are put in a token that anybody holding it can read, because
signed was read as encrypted.

**The leaver process reaches one system and eleven keep working.** Sessions
already issued outlive the account, and nobody knows how long.

**The identity provider is treated as infrastructure.** It authenticates everybody
to everything and is protected like a web server.

## Three protocols, three different jobs

These get listed together and they are not alternatives.

**LDAP is a query protocol for a directory.** An application asks the directory
whether this username and password are correct, or which groups this person is in.
The application sees the password, because it is the thing checking it. That is
the crucial difference from everything else on this page and it is why LDAP
authentication is not single sign-on: every application that uses it handles the
credential.

**OAuth 2.0 grants an application limited access to something on your behalf.**
You authorise an application to read your calendar. What comes back is a token
saying this application may read that calendar, for a while. Nothing in it says
who you are, and that is by design rather than an omission.

**SAML carries a signed statement about a person between organisations.** It is
XML, it predates the token-based approaches, and it is thoroughly deployed in
enterprise software. The assertion says who authenticated, when, how, and often
what groups they are in.

**OpenID Connect adds identity to OAuth.** It is the layer that turns "this
application may do that" into "and here is who authorised it", and the thing it
adds is a token specifically about the person.

<figure class="learn-figure">
<svg viewBox="0 0 720 316" role="img" aria-labelledby="fed-title" style="width:100%;height:auto;">
<title id="fed-title">The same browser sign-in under SAML and under OpenID Connect, showing that the sequence is the same shape and the artefact carried back differs</title>
<g fill="currentColor">
<text x="14" y="20" font-size="11">the same sign-in, twice, and the step where the two differ</text>
<text x="14" y="60" font-size="9.5">SAML 2.0</text>
<rect x="150" y="44" width="420" height="20" rx="3" fill="var(--accent)" fill-opacity="0.08" stroke="var(--accent)" stroke-opacity="0.65" stroke-width="1.1"/>
<text x="160" y="58" font-size="7.5">1. browser asks the app</text>
<rect x="150" y="67" width="420" height="20" rx="3" fill="var(--accent)" fill-opacity="0.08" stroke="var(--accent)" stroke-opacity="0.65" stroke-width="1.1"/>
<text x="160" y="81" font-size="7.5">2. app redirects to the IdP</text>
<rect x="150" y="90" width="420" height="20" rx="3" fill="var(--accent)" fill-opacity="0.08" stroke="var(--accent)" stroke-opacity="0.65" stroke-width="1.1"/>
<text x="160" y="104" font-size="7.5">3. IdP authenticates the person</text>
<rect x="150" y="113" width="420" height="20" rx="3" fill="var(--red)" fill-opacity="0.14" stroke="var(--red)" stroke-opacity="0.65" stroke-width="1.1"/>
<text x="160" y="127" font-size="7.5">4. IdP posts a signed XML assertion back</text>
<rect x="150" y="136" width="420" height="20" rx="3" fill="var(--red)" fill-opacity="0.14" stroke="var(--red)" stroke-opacity="0.65" stroke-width="1.1"/>
<text x="160" y="150" font-size="7.5">5. app validates the signature</text>
<text x="14" y="190" font-size="9.5">OpenID Connect</text>
<rect x="150" y="174" width="420" height="20" rx="3" fill="currentColor" fill-opacity="0.08" stroke="currentColor" stroke-opacity="0.65" stroke-width="1.1"/>
<text x="160" y="188" font-size="7.5">1. browser asks the app</text>
<rect x="150" y="197" width="420" height="20" rx="3" fill="currentColor" fill-opacity="0.08" stroke="currentColor" stroke-opacity="0.65" stroke-width="1.1"/>
<text x="160" y="211" font-size="7.5">2. app redirects to the IdP</text>
<rect x="150" y="220" width="420" height="20" rx="3" fill="currentColor" fill-opacity="0.08" stroke="currentColor" stroke-opacity="0.65" stroke-width="1.1"/>
<text x="160" y="234" font-size="7.5">3. IdP authenticates the person</text>
<rect x="150" y="243" width="420" height="20" rx="3" fill="var(--red)" fill-opacity="0.14" stroke="var(--red)" stroke-opacity="0.65" stroke-width="1.1"/>
<text x="160" y="257" font-size="7.5">4. IdP returns a code, app swaps it for a token</text>
<rect x="150" y="266" width="420" height="20" rx="3" fill="var(--red)" fill-opacity="0.14" stroke="var(--red)" stroke-opacity="0.65" stroke-width="1.1"/>
<text x="160" y="280" font-size="7.5">5. app validates the JWT signature</text>
<text x="580" y="130" font-size="8" fill="var(--red)" fill-opacity="0.9">the two</text>
<text x="580" y="142" font-size="8" fill="var(--red)" fill-opacity="0.9">shaded rows</text>
<text x="580" y="154" font-size="8" fill="var(--red)" fill-opacity="0.9">are the whole</text>
<text x="580" y="166" font-size="8" fill="var(--red)" fill-opacity="0.9">difference</text>
<text x="14" y="300" font-size="10" fill-opacity="0.85">both end with the app trusting a signature it checked against a key it fetched</text>
<text x="14" y="314" font-size="9" fill-opacity="0.7">the format differs, the trust anchor is the same shape, and so is the failure if the IdP is compromised</text>
</g></svg>
<figcaption>Both flows have the same shape and the same number of steps, which is why they are so often described interchangeably. The browser hits the application, gets redirected to the identity provider, authenticates there, and comes back with something the application checks. The shaded rows are the entire difference: one returns a signed XML document directly, the other returns a short-lived code the application exchanges for a token out of band, which keeps the token out of the browser's history and the referrer header. Both end at the same place, with the application trusting a signature validated against a key it fetched from the provider, and both fail the same way if the provider is compromised.</figcaption>
</figure>

## What is actually in the token

An identity provider publishes what it is and what it can say about people, at a
path anybody can fetch.

```bash
# AlmaLinux 10.2, x86_64
$ dnf -q -y install curl jq >/dev/null 2>&1; echo "what an identity provider publishes about itself, at a fixed well-known path:"; curl -s https://accounts.google.com/.well-known/openid-configuration | jq -r "{issuer, authorization_endpoint, token_endpoint, jwks_uri} | to_entries[] | \"  \" + .key + \": \" + .value"; echo; echo "the claims it says it can assert:"; curl -s https://accounts.google.com/.well-known/openid-configuration | jq -r ".claims_supported | join(\", \")" | fold -w 68 | sed "s/^/  /"
what an identity provider publishes about itself, at a fixed well-known path:
  issuer: https://accounts.google.com
  authorization_endpoint: https://accounts.google.com/o/oauth2/v2/auth
  token_endpoint: https://oauth2.googleapis.com/token
  jwks_uri: https://www.googleapis.com/oauth2/v3/certs

the claims it says it can assert:
  aud, email, email_verified, exp, family_name, given_name, iat, iss, 
  name, picture, sub
```

**Eleven claims, and the provider says so publicly.** That list is the vocabulary
available to every application integrating with it, and reading it before an
integration saves an argument about whether a particular attribute is available.

The `jwks_uri` is the trust anchor. It is where the provider publishes the public
keys its tokens are signed with, and a relying party fetches it, caches it, and
uses it to check every token. Nothing else in the chain establishes trust: the
whole arrangement rests on that document being genuine and the key being the
provider's.

Now a token itself.

<details class="predict">
<summary>An identity token arrives at an application. Predict which parts of it the application, and anybody else who obtains it, can read.</summary>

```bash
# AlmaLinux 10.2, x86_64
$ make-token | read-token
the token is 715 characters in 3 dot-separated parts
header:
    alg: RS256
    typ: JWT
    kid: 2026-08-a
payload:
    iss: https://idp.example.internal
    sub: 8f14e45fceea167a
    aud: expenses-app
    exp: 1787000000
    iat: 1786996400
    email: sam@example.internal
    email_verified: True
    groups: ['finance', 'expenses-approver']
signature: 342 characters, and it is the only part that is not readable
```

**Everything except the signature.** The header and the payload are base64, not
encryption, so any party holding the token reads the issuer, the subject, the
audience, the expiry, the email address and the group memberships without a key.

This is the single most common misunderstanding about tokens and it has a
practical consequence in every integration. A signed token guarantees that the
contents have not been altered and that the issuer produced them. It guarantees
nothing about who can see them.

So the rule for what goes in a token is the same as the rule for a postcard.
Anything a user must not learn about themselves does not belong there, and neither
does anything an application must not learn about the user. Internal identifiers,
role names that reveal organisational structure, and group memberships are all
common and all readable, and putting a sensitive attribute in one is a disclosure
rather than a configuration choice.

Two more details worth carrying from the output. The `kid` in the header names
which key signed it, which is how a provider rotates keys without breaking
everything at once. And the `aud` claim names which application the token is for:
an application that skips checking it will accept a token issued for somebody
else's application, which is a real and recurring implementation flaw.

</details>

<details class="deeper">
<summary>If you are integrating: why OAuth is not authentication, and the mistake that keeps being made</summary>

OAuth answers a question about permission. You authorised this application to
access that resource. It was designed for exactly that, and RFC 6749 is careful
about it.

The mistake is to treat possession of a valid access token as proof of who the
user is. It reads as reasonable: the token came from the provider, the provider
authenticates people, therefore the holder is authenticated. Every step of that
is wrong in a specific way.

An access token is a bearer token, which means whoever holds it can use it.
Nothing in it identifies who obtained it, and an application that receives one has
learned that somebody authorised something, not who. If the application then calls
an API to fetch profile information and treats the answer as identity, it has
accepted a token that could have been obtained elsewhere for another application
entirely and used it to log somebody in.

OpenID Connect exists because of this. It adds an ID token, which is specifically a
statement about the authentication event: this subject authenticated with this
provider at this time, for this audience. The audience claim is what stops a token
minted for one application being replayed at another, and validating it is not
optional.

The practical checklist for anybody implementing: use the ID token for identity
and the access token for access, validate the signature against the published
keys, check the issuer, check the audience, check the expiry, and check the nonce
you sent. Every one of those has been the subject of a real vulnerability in a
real product, usually because it was the one check somebody assumed the library
was doing.

</details>
<details class="predict">
<summary>An attacker obtains a valid ID token issued for a different application. Predict whether your application will accept it.</summary>

**If it does not check the audience claim, yes, and this is a real class of
vulnerability rather than a hypothetical one.**

Work through what the application can verify. The signature is valid, because the
identity provider really did issue this token. The issuer is correct, because it
came from the provider your application trusts. The expiry is in the future,
because it was minted recently. The subject names a real person. Every check most
implementations perform passes.

The one thing that distinguishes it is `aud`, which names the application the
token was issued for. A token minted for a small internal tool and presented to
your payroll system is signed, unexpired, from the right issuer, and about a real
person, and the only field saying it does not belong here is the one nobody
checked.

Two ways this happens in practice. An organisation runs several applications
against the same provider, and a compromise of the least important one yields
tokens usable at the most important one. Or a public provider is used, an attacker
registers their own application with it, obtains tokens legitimately for users who
sign into their application, and replays them at yours.

The defence is one comparison and it is frequently skipped because the library
made everything else easy. Validate the audience, validate the issuer, validate
the nonce you sent, and treat any library that does not make those mandatory as
requiring the check to be written by hand.

</details>


## OAuth authorises, and does not authenticate

The distinction is worth one more paragraph in plain terms, because exam items
turn on it and so do integrations.

**Authorisation is about permission.** May this application read that calendar.
The subject of the sentence is the application.

**Authentication is about identity.** Who is this person. The subject of the
sentence is the person.

OAuth's tokens are the first kind. OpenID Connect's ID token is the second kind.
An arrangement using OAuth alone can tell an application that it has been granted
access to something, and the application that concludes it knows who is sitting at
the browser has made an inference the protocol does not support.
<details class="deeper">
<summary>If you are migrating: what interoperability actually costs, and the attribute nobody agrees on</summary>

Federation standards interoperate in the sense that two conforming
implementations will complete a sign-in. What they do not standardise is the part
that takes the time.

The attribute nobody agrees on is the identifier. An assertion names a subject,
and which value goes in that field is a decision each pairing makes separately:
an email address, an internal identifier, an employee number, a directory
identifier, or a value the provider generates per relying party specifically so
that two relying parties cannot correlate the same person. All of those are valid
and they are not interchangeable.

The consequence is a migration hazard with a specific shape. An application that
was keyed on email addresses and now receives an opaque identifier does not
recognise anybody, so every user appears to be a new user, and whether that
produces a helpful error or a silently duplicated account depends on the
application. The opposite direction is worse: an application keyed on an
identifier that turns out to be reusable, because somebody left and their email
address was later reassigned, will hand the new person the old person's account.

Two rules that avoid most of it. Key on something the provider guarantees is
stable and never reused, which for OpenID Connect means the pairing of issuer and
subject rather than either alone, and never on an email address, because email
addresses change when people marry and get reassigned when people leave.

The other cost is attribute mapping. Each relying party wants group memberships or
roles in its own vocabulary, and the translation between the directory's naming
and the application's has to be built and maintained per application. That is the
work in a federation programme, it is not interesting, and it is where the
timeline goes.

</details>


## What the identity provider concentrates

Federation moves every authentication decision into one place, and the security
argument for it is strong: one system to protect properly, one place to enforce
multifactor authentication, one place to disable an account, one audit trail.
Every one of those is a real improvement over eleven applications each doing it
badly.

**The cost is that the same properties concentrate.** Somebody who controls the
identity provider can issue an assertion for anybody, to any relying party, and
every application will accept it because accepting it is the arrangement. There is
no second opinion anywhere in the design.

That changes what the identity provider is. It is not an application, it is the
thing every other application's security rests on, and it deserves treatment to
match: the strongest authentication for its administrators, separate
administrative accounts, the signing keys in hardware, change control on trust
relationships, and monitoring specifically of assertions issued rather than of the
service being up.

**Session lifetime is the other consequence and it is the one that surprises
people.** Disabling an account in the provider stops new sign-ins. Sessions
already established at the eleven applications continue until each application's
own session expires, and those lifetimes were configured by eleven different
teams. A leaver process that ends at the directory has stopped the front door and
left whatever was already inside.

The question worth being able to answer is therefore not whether accounts can be
disabled centrally, but how long after disabling an account somebody could still
be using it, and the honest answer usually requires asking each application.
<details class="deeper">
<summary>If you operate the provider: what to monitor, and the alert nobody has</summary>

Monitoring an identity provider like a service means watching whether it is up and
how fast it responds. Both matter and neither would notice the thing you would
most want to know.

What is worth watching is assertions. Specifically: assertions issued for
administrative accounts, assertions issued to relying parties that rarely see any,
assertions issued outside the hours a person plausibly works, and any change to
the set of relying parties or to the signing keys.

That last one deserves its own alert and almost nobody has it. Adding a trust
relationship is a legitimate administrative action, it is how new applications get
onboarded, and it is also how somebody who has compromised the provider gives
themselves a destination for assertions they mint. The same is true of adding a
signing key: a new key in the published key set is normal during rotation and is
also exactly what an attacker would add. Neither shows up in an availability
dashboard.

The second thing to watch is the authentication method recorded in each assertion.
An estate that requires a phishing-resistant factor will still contain accounts
that can fall back to something weaker, and the assertion says which was used. An
administrative sign-in that succeeded with a weaker method than policy requires is
a finding available in the data everybody already collects and almost nobody
queries.

The third is impossible sequences, which is the behavioural analytics idea applied
to one high-value system rather than an estate: the same subject authenticating
from two places that cannot both be true. It is noisy in general and much less so
when scoped to administrators of the provider itself.

None of that needs a product. It needs somebody to decide that the assertion log
is the interesting log, which is a different instinct from treating the provider
as infrastructure.

</details>


## Prove it

**Run it.** Fetch any provider's `.well-known/openid-configuration` with `curl`
and read the `claims_supported` list. It takes seconds and it is the definitive
answer to what attributes an integration can rely on.

**Work it out.** Take the token in this topic and list which claims would be a
disclosure if the token were logged by an intermediate proxy. Then decide which of
them you would remove and what the application would use instead.

**Look it up.** Open SP 800-63C and find what it says about assertion lifetime and
about the relationship between the identity provider's session and the relying
party's. The distinction it draws is the one the leaver problem turns on.

## What trips people up

### 1. Treating LDAP authentication as single sign-on

Every application using LDAP handles the password itself, which is the opposite of
what federation provides. It is a directory query protocol that happens to be able
to check a credential.

### 2. Reading a signed token as a private one

The header and payload are base64, so anybody holding the token reads the email
address, the groups and the identifiers. Signed means unaltered, not unreadable.

### 3. Using an access token as proof of identity

It is a bearer token about permission. OpenID Connect's ID token is the statement
about the authentication event, and the audience claim is what stops one
application's token working at another.

### 4. Skipping the audience check

An application that validates the signature and not the audience will accept a
correctly signed token issued for somebody else entirely. This is a real and
recurring implementation flaw.

### 5. Protecting the identity provider like an application

It is the thing every other application's security rests on. Compromise of it
produces valid assertions for anybody at everything, with no second opinion
anywhere in the design.

### 6. Assuming disabling an account ends access

It stops new sign-ins. Sessions already established at each relying party run
until that application's own timeout, which eleven different teams configured
without talking to each other.

## Work it through

An organisation is moving eleven applications behind one identity provider.
Someone asks whether this is more secure than what they have now, which is eleven
separate password databases.

**The tempting answer is yes, unambiguously.** One place to enforce multifactor,
one place to disable an account, one audit trail, and eleven fewer password
databases to breach. All of that is true and it is most of the case.

**The answer that survives scrutiny names what is being traded.** The organisation
is exchanging eleven independent failures for one shared one. Before, compromising
an application's password database exposed that application. After, compromising
the provider exposes everything, and there is no application anywhere in the
estate that would decline the resulting assertion.

**Then the recommendation is the move plus the conditions.** Do it, because eleven
poorly protected databases is a worse position than one well protected provider.
And treat the provider as the highest-value system in the estate from day one:
hardware-backed signing keys, separate administrative identities with the
strongest authentication available, change control on trust relationships, and
alerting on assertions issued rather than on uptime.

**What this rejects is the framing of the question.** More secure is not a single
axis here. The estate becomes much harder to attack in the ordinary case and much
worse off in one specific case, and a decision recorded without that sentence will
be revisited unhappily.

The residual to write down explicitly: session lifetime. Until every relying party
has a session policy somebody has looked at, the time between disabling an account
and access actually stopping is unknown, and unknown is the wrong answer to that
question for an organisation that has just centralised its identity.

## Try it

**Fetch a discovery document.** `curl -s https://accounts.google.com/.well-known/openid-configuration | jq .`
and read what a provider publishes about itself. Every OpenID Connect provider has
one at the same path.

**Decode a token.** If you have any JWT, split it at the dots and base64-decode the
first two parts. No key required, which is the point.

**Find your own session lifetimes.** Pick three applications behind your single
sign-on and find out how long a session lasts after the identity provider stops
issuing new ones. Three different answers is the normal result.

**Check one integration's audience handling.** Ask whoever built it whether the
`aud` claim is validated. The answer is informative regardless of what it is.

## Check yourself

<details class="qa">
<summary>Why is LDAP authentication not single sign-on?</summary>

Because every application doing it handles the password itself. The application
takes the credential, binds to the directory with it, and learns whether it was
correct.

Federation's defining property is the opposite: the relying party never sees the
credential and instead receives a signed statement from a party that did. LDAP is
a directory query protocol that can check a password, which is a useful thing and
a different thing.

</details>

<details class="qa">
<summary>Which parts of a signed token can be read without a key?</summary>

The header and the payload, both of which are base64 rather than encrypted. That
includes the issuer, subject, audience, expiry and every claim, which in the
example on this page means an email address and two group memberships.

The signature is the only part that requires a key, and it proves the contents
have not been altered. Anything sensitive in the payload is disclosed to every
party that handles the token.

</details>

<details class="qa">
<summary>What is the difference between OAuth and OpenID Connect?</summary>

OAuth grants an application limited access to a resource on your behalf, and its
tokens say what may be done rather than who did the authorising. OpenID Connect
adds an ID token, which is a statement about the authentication event itself.

Treating an OAuth access token as proof of identity is the recurring mistake. It
is a bearer token, so holding it says nothing about who obtained it or which
application it was issued for.

</details>

<details class="qa">
<summary>What does federation concentrate, and what should follow?</summary>

Every authentication decision. Somebody who controls the identity provider can
issue a valid assertion for anybody to any relying party, and every application
will accept it, because accepting it is the arrangement. There is no second
opinion in the design.

What follows is that the provider is not an application. It needs the strongest
available authentication for its administrators, separate administrative
identities, signing keys in hardware, change control on trust relationships, and
monitoring of assertions issued rather than of uptime.

</details>

<details class="qa">
<summary>An account is disabled in the identity provider. When does access stop?</summary>

New sign-ins stop immediately. Existing sessions at each relying party continue
until that application's own session expires, and those lifetimes were set by
different teams at different times.

So the useful question during a leaver process is not whether the account can be
disabled centrally but how long afterwards somebody could still be working, and
answering it usually means asking each application.

</details>

## References

- [RFC 6749](https://www.rfc-editor.org/rfc/rfc6749.html) - IETF, OAuth 2.0, for what an access token is and what it is not. Free. Accessed 2026-08-25.
- [RFC 7519](https://www.rfc-editor.org/rfc/rfc7519.html) - IETF, JSON Web Token, for the three-part structure the capture takes apart. Free. Accessed 2026-08-25.
- [OpenID Connect Core](https://openid.net/specs/openid-connect-core-1_0.html) - OpenID Foundation, for the ID token, the claims and the audience check. Free. Accessed 2026-08-25.
- [RFC 4511](https://www.rfc-editor.org/rfc/rfc4511.html) - IETF, LDAP, for what a bind actually does and why the application sees the credential. Free. Accessed 2026-08-25.
- [SP 800-63C](https://csrc.nist.gov/pubs/sp/800/63/c/final) - NIST, federation and assertions, for assertion lifetime and the relationship between provider and relying party sessions. Free. Accessed 2026-08-25.

**Where the content came from.** The discovery document is fetched live from a
public endpoint published for exactly that purpose, with no account and no
credentials. The token is generated on an AlmaLinux 10.2 container during the
capture, signed with a key created seconds earlier, and taken apart by a reader
that does no verification: every claim in it was written for this topic and none
of it belongs to anybody. There is no platform comparison on this page, because
nothing here runs against a host: a relying party validates a token the same way
on every operating system.

**If you also work on networks.** The Network+ track's
[identity and access management](/learn/network-plus/identity-and-access-management)
covers the same arrangement from the network's side, including where the
authentication traffic actually goes.
