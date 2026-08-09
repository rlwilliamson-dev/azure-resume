---
title: "The password changed on one machine and nowhere else"
description: "Local accounts stop working somewhere around the third server. LDAP as a directory you look things up in, Kerberos as tickets that never carry the password, and SSSD as the client that wires both into NSS and PAM."
track: "linux-plus"
level: "deep"
order: 390
objectives:
  - "Explain why local accounts fail as soon as there is more than a handful of machines"
  - "Read a distinguished name as a path up a directory tree, and find a base DN you were not told"
  - "Separate identity lookup from authentication, and say which protocol answers which"
  - "Describe the Kerberos ticket exchange and why a five-minute clock difference breaks it"
prerequisites: ["managing-users-and-groups", "authentication-and-pam"]
tags: ["linux", "linux-plus", "ldap", "kerberos", "sssd", "active-directory", "identity"]
updated: 2026-08-08
draft: false
examObjectives:
  - exam: "xk0-006"
    domain: "3.0"
    objective: "3.1"
sources:
  - title: "RFC 4511: Lightweight Directory Access Protocol (LDAP): The Protocol"
    url: "https://www.rfc-editor.org/rfc/rfc4511.html"
    publisher: "IETF"
    accessed: 2026-08-08
    tier: 1
  - title: "RFC 4120: The Kerberos Network Authentication Service (V5)"
    url: "https://www.rfc-editor.org/rfc/rfc4120.html"
    publisher: "IETF"
    accessed: 2026-08-08
    tier: 1
  - title: "ldapsearch(1)"
    url: "https://manpages.debian.org/trixie/ldap-utils/ldapsearch.1.en.html"
    publisher: "Debian"
    accessed: 2026-08-08
    tier: 1
  - title: "nsswitch.conf(5)"
    url: "https://man7.org/linux/man-pages/man5/nsswitch.conf.5.html"
    publisher: "Linux man-pages project"
    accessed: 2026-08-08
    tier: 1
  - title: "sssd.conf(5)"
    url: "https://manpages.debian.org/trixie/sssd-common/sssd.conf.5.en.html"
    publisher: "Debian"
    accessed: 2026-08-08
    tier: 1
  - title: "realm(8)"
    url: "https://manpages.debian.org/trixie/realmd/realm.8.en.html"
    publisher: "Debian"
    accessed: 2026-08-08
    tier: 1
  - title: "krb5.conf(5)"
    url: "https://web.mit.edu/kerberos/krb5-latest/doc/admin/conf_files/krb5_conf.html"
    publisher: "MIT Kerberos"
    accessed: 2026-08-08
    tier: 1
  - title: "smb.conf(5)"
    url: "https://www.samba.org/samba/docs/current/man-html/smb.conf.5.html"
    publisher: "Samba Team"
    accessed: 2026-08-08
    tier: 1
symptoms:
  - symptom: "ldap_bind: Invalid credentials (49)"
    anchor: "1-the-bind-dn-is-not-a-username"
  - symptom: "getent passwd returns nothing for a user that is in the directory"
    anchor: "2-ldapsearch-works-and-getent-does-not"
  - symptom: "Clock skew too great while getting initial credentials"
    anchor: "3-clock-skew-too-great"
  - symptom: "klist: No credentials cache found"
    anchor: "kerberos-tickets-instead-of-a-password"
---

> **Before you read.** A contractor finishes on Friday. Their account exists on two
> hundred servers, because two hundred times somebody ran `useradd`.
>
> You can write a loop. The loop will miss the eleven machines that were powered
> off, the four built last week from an image with the account already baked in, and
> the one nobody wrote down. A fortnight later the account still exists on some
> subset of the estate and you cannot say which subset.
>
> **If an account should not live in `/etc/passwd`, where should it live?**

It should live in one place, and every machine should ask that place. Everything in
this topic is a consequence of that: a directory holding the accounts, a protocol for
asking it questions, a separate protocol for proving who you are, and a daemon on
each machine wiring both into the two interfaces Linux already had.

Most of the confusion comes from **two different questions being treated as one**.
"What is Jane's user ID, home directory, and shell" is a lookup. "Is the person at
this keyboard really Jane" is an authentication. Local machines answered both from
files, which is why they feel like one question. Central identity usually answers
them with two different protocols, and almost every decision downstream follows from
keeping them apart.

### Some words you will need

<dl class="terms">
<dt>directory</dt>
<dd>A database optimised for being read, arranged as a tree, holding entries about people, groups, and machines. Read constantly, written rarely.</dd>
<dt>DN</dt>
<dd>Distinguished name. The unique name of one entry, written as a path from the entry up to the root of the tree: <code>uid=jsmith,ou=people,dc=example,dc=com</code>.</dd>
<dt>base DN</dt>
<dd>The entry a search starts from. Everything below it is in scope; everything above and beside it is not.</dd>
<dt>objectClass</dt>
<dd>What kind of thing an entry is. It decides which attributes the entry must have and which it may have. An entry can have several.</dd>
<dt>bind</dt>
<dd>The LDAP operation that says who you are for the rest of the connection. Anonymous, or a DN and a password.</dd>
<dt>realm</dt>
<dd>A Kerberos administrative domain, written in capitals by convention: <code>EXAMPLE.COM</code>. Usually the DNS domain, shouted.</dd>
<dt>KDC</dt>
<dd>Key distribution centre. The Kerberos server. It knows a key for every principal and it is the only thing that does.</dd>
<dt>TGT</dt>
<dd>Ticket-granting ticket. The first ticket you get, which you then exchange for tickets to individual services without typing your password again.</dd>
</dl>

## What breaks without this

**Offboarding becomes unprovable.** You can say you removed the account; you cannot
demonstrate it, because there is no single place to look. "Show me that this person
has no access" is a question the estate cannot answer.

**User IDs drift apart, and file ownership is a number.** `alice` is 1004 on one
machine and 1007 on another, where 1004 is `bob`. Put an NFS share between them and
Bob owns Alice's files, with nothing broken in a way any tool will report.

**One password change becomes two hundred password changes**, and the machines that
were down during the change are now the machines with the old password on them.

**Nobody can answer "who can log in to this host".** The answer is in a file on the
host, a different file on the next host, and the group memberships are in a third
place. That question is the first one asked in every incident and every audit.

## Two questions that look like one

<figure class="learn-figure">
<svg viewBox="0 0 720 400" role="img" aria-labelledby="ci-title ci-desc" style="width:100%;height:auto;">
  <title id="ci-title">Identity lookup and authentication are separate paths that meet at SSSD</title>
  <desc id="ci-desc">On the left, the identity question: commands such as getent passwd, id, and ls -l ask what a user's numeric ID, group, home directory, and shell are. That question goes through NSS, the name service switch in glibc, configured by /etc/nsswitch.conf. On the right, the authentication question: login, sshd, sudo, and su ask whether the person knows the secret. That question goes through PAM, the stack of modules in /etc/pam.d. Both paths reach SSSD, a single daemon on the machine that answers both and keeps a local cache. SSSD then answers the lookup with an LDAP search returning attributes such as uidNumber, gidNumber, homeDirectory, and loginShell, and answers the authentication with a Kerberos exchange or an LDAP bind, which returns only yes or no.</desc>
  <g font-family="ui-monospace, monospace">
    <rect x="26" y="20" width="288" height="70" rx="5" fill="currentColor" fill-opacity="0.12" stroke="currentColor" stroke-opacity="0.4"/>
    <text x="170" y="42" text-anchor="middle" font-size="12" fill="currentColor">the identity question</text>
    <text x="170" y="60" text-anchor="middle" font-size="9.5" fill="currentColor" fill-opacity="0.65">what is this user's uid, gid, home, shell?</text>
    <text x="170" y="78" text-anchor="middle" font-size="9.5" fill="currentColor" fill-opacity="0.8">getent passwd, id, ls -l</text>
    <rect x="406" y="20" width="288" height="70" rx="5" fill="currentColor" fill-opacity="0.12" stroke="currentColor" stroke-opacity="0.4"/>
    <text x="550" y="42" text-anchor="middle" font-size="12" fill="currentColor">the authentication question</text>
    <text x="550" y="60" text-anchor="middle" font-size="9.5" fill="currentColor" fill-opacity="0.65">does this person know the secret?</text>
    <text x="550" y="78" text-anchor="middle" font-size="9.5" fill="currentColor" fill-opacity="0.8">login, sshd, sudo, su</text>
    <rect x="26" y="126" width="288" height="58" rx="5" fill="currentColor" fill-opacity="0.07" stroke="currentColor" stroke-opacity="0.3"/>
    <text x="170" y="149" text-anchor="middle" font-size="12" fill="currentColor">NSS</text>
    <text x="170" y="168" text-anchor="middle" font-size="9.5" fill="currentColor" fill-opacity="0.65">glibc, told what to ask by /etc/nsswitch.conf</text>
    <rect x="406" y="126" width="288" height="58" rx="5" fill="currentColor" fill-opacity="0.07" stroke="currentColor" stroke-opacity="0.3"/>
    <text x="550" y="149" text-anchor="middle" font-size="12" fill="currentColor">PAM</text>
    <text x="550" y="168" text-anchor="middle" font-size="9.5" fill="currentColor" fill-opacity="0.65">the module stack in /etc/pam.d</text>
    <rect x="204" y="220" width="312" height="60" rx="5" fill="currentColor" fill-opacity="0.12" stroke="currentColor" stroke-opacity="0.4"/>
    <text x="360" y="244" text-anchor="middle" font-size="12" fill="currentColor">SSSD</text>
    <text x="360" y="264" text-anchor="middle" font-size="9.5" fill="currentColor" fill-opacity="0.65">one daemon answering both, with a local cache</text>
    <rect x="26" y="318" width="300" height="66" rx="5" fill="currentColor" fill-opacity="0.07" stroke="currentColor" stroke-opacity="0.3"/>
    <text x="176" y="340" text-anchor="middle" font-size="12" fill="currentColor">LDAP search</text>
    <text x="176" y="358" text-anchor="middle" font-size="9.5" fill="currentColor" fill-opacity="0.65">returns attributes: uidNumber, gidNumber,</text>
    <text x="176" y="373" text-anchor="middle" font-size="9.5" fill="currentColor" fill-opacity="0.65">homeDirectory, loginShell</text>
    <rect x="394" y="318" width="300" height="66" rx="5" fill="currentColor" fill-opacity="0.07" stroke="currentColor" stroke-opacity="0.3"/>
    <text x="544" y="340" text-anchor="middle" font-size="12" fill="currentColor">Kerberos exchange, or an LDAP bind</text>
    <text x="544" y="358" text-anchor="middle" font-size="9.5" fill="currentColor" fill-opacity="0.65">returns yes or no, and nothing else</text>
    <text x="544" y="373" text-anchor="middle" font-size="9.5" fill="currentColor" fill-opacity="0.65">no uid, no home directory, no shell</text>
  </g>
  <g stroke="currentColor" stroke-opacity="0.45" fill="none" stroke-width="1.2">
    <path d="M170 90 L170 122 M166 116 L170 123 L174 116"/>
    <path d="M550 90 L550 122 M546 116 L550 123 L554 116"/>
    <path d="M170 184 L170 202 L286 202 L286 216 M282 210 L286 217 L290 210"/>
    <path d="M550 184 L550 202 L434 202 L434 216 M430 210 L434 217 L438 210"/>
    <path d="M286 280 L286 296 L176 296 L176 314 M172 308 L176 315 L180 308"/>
    <path d="M434 280 L434 296 L544 296 L544 314 M540 308 L544 315 L548 308"/>
  </g>
</svg>
<figcaption>Two questions, two interfaces, one daemon. Most SSSD configuration is deciding which source answers the left-hand side and which answers the right, and they are allowed to be different.</figcaption>
</figure>

Locally, lesson 28 covers both halves: `/etc/passwd` holds the identity (name,
number, home, shell) and `/etc/shadow` holds the hash that answers the
authentication. Two files, one machine.

| | Locally | Centrally |
| --- | --- | --- |
| Identity: uid, gid, home, shell, groups | `/etc/passwd`, `/etc/group` | An LDAP search |
| Authentication: is this the right secret | `/etc/shadow` | Kerberos, or an LDAP bind |
| Interface the program uses | NSS | NSS |
| Interface the login uses | PAM | PAM |

**The right-hand column changes; the two interfaces do not.** No program was
rewritten to understand LDAP. `ls -l` still calls `getpwuid()`, `sshd` still calls
PAM, and something behind those interfaces started answering differently. That is why
central identity can be added to an estate that already exists.

## LDAP is a directory, not a login service

A directory is a tree, and every entry is named by its full path back to the root.
That name is the DN.

```
dc=com
  dc=example                      <- the base DN, the top of what this server serves
    ou=people
      uid=jsmith                  <- an entry, dn: uid=jsmith,ou=people,dc=example,dc=com
      uid=asmith
    ou=groups
      cn=developers
```

**Read a DN right to left and it is a path down from the root**: `dc=com`,
then `dc=example` inside it, then `ou=people`, then `uid=jsmith`. LDAP writes
it the other way round, most specific part first. `dc` is a domain component,
`ou` an organisational unit, `cn` a common name, `uid` a user identifier,
attribute names being used to label a level of the tree.

```bash
# Debian 13 (trixie), x86_64
$ ldapsearch -x -H ldap://localhost -b dc=example,dc=com
# extended LDIF
#
# LDAPv3
# base <dc=example,dc=com> with scope subtree
# filter: (objectclass=*)
# requesting: ALL
#

# example.com
dn: dc=example,dc=com
objectClass: top
objectClass: dcObject
objectClass: organization
o: Example Inc
dc: example

# search result
search: 2
result: 0 Success

# numResponses: 2
# numEntries: 1
```

**The lines starting with `#` are comments from `ldapsearch`, not data**; the entry
is the five lines from `dn:` to `dc: example`, in LDIF. **Its objectClass values are
the schema in action**: `organization` is what requires `o: Example Inc`, `dcObject`
what requires `dc: example`. An entry that claims an objectClass and omits a required
attribute is rejected at write time, which is what stops a directory becoming a pile
of half-filled forms.

You will frequently be pointed at a directory and not told its base DN. There is a
defined way to ask.

<details class="predict">
<summary>Every LDAP server publishes a special entry, the root DSE, whose DN is the empty string, holding facts about the server itself rather than about people. Searching it means base `""` and scope `base`. What does that search return for a directory whose data lives under <code>dc=example,dc=com</code>?</summary>

```bash
# Debian 13 (trixie), x86_64
$ ldapsearch -x -H ldap://localhost -s base -b "" namingContexts supportedLDAPVersion
# extended LDIF
#
# LDAPv3
# base <> with scope baseObject
# filter: (objectclass=*)
# requesting: namingContexts supportedLDAPVersion 
#

#
dn:
namingContexts: dc=example,dc=com
supportedLDAPVersion: 3

# search result
search: 2
result: 0 Success

# numResponses: 2
# numEntries: 1
```

</details>

**`namingContexts` is the answer to "what is the base DN".** A server can
serve more than one, in which case you get more than one line. Note what `dn:`
is on that entry: nothing. The root DSE is the one entry whose DN is empty,
and `-s base -b ""` is the incantation for reaching it. Memorise it. It works
against Active Directory too, and it is the fastest way to confirm that a
directory is reachable, is answering, and is the one you think it is.

### Adding a user, in the format the directory speaks

LDIF is also the import format. A file of entries, blank line between them:

```bash
# Debian 13 (trixie), x86_64
$ cat /root/jsmith.ldif
dn: ou=people,dc=example,dc=com
objectClass: organizationalUnit
ou: people

dn: uid=jsmith,ou=people,dc=example,dc=com
objectClass: inetOrgPerson
objectClass: posixAccount
uid: jsmith
cn: Jane Smith
sn: Smith
uidNumber: 10001
gidNumber: 10001
homeDirectory: /home/jsmith
loginShell: /bin/bash
```

**Two entries in one file**, and the order matters: `ou=people` has to exist
before anything can be created inside it. Read the second entry as two things
stacked on one object. `inetOrgPerson` carries the human attributes: `cn`,
`sn`, optionally `mail`. `posixAccount` carries what a Linux machine needs:
`uidNumber`, `gidNumber`, `homeDirectory`, `loginShell`, which are the last
four fields of a line in `/etc/passwd`. **That is the whole trick**, and
something on the client turns one into the other.

```bash
# Debian 13 (trixie), x86_64
$ ldapadd -x -D cn=admin,dc=example,dc=com -w secret -f /root/jsmith.ldif
adding new entry "ou=people,dc=example,dc=com"

adding new entry "uid=jsmith,ou=people,dc=example,dc=com"
```

`-D` is the bind DN, who you are claiming to be, `-w` is that DN's password,
and `-x` selects simple authentication rather than SASL. Yes, the password is
on the command line where shell history and `ps` can see it; `-W` prompts
instead.

```bash
# Debian 13 (trixie), x86_64
$ ldapsearch -x -LLL -H ldap://localhost -b dc=example,dc=com "(objectClass=*)" dn
dn: dc=example,dc=com

dn: ou=people,dc=example,dc=com

dn: uid=jsmith,ou=people,dc=example,dc=com
```

**Three entries, and it is the default scope that returned all three.** Every
search has a base and a scope, and `ldapsearch` defaults to `-s sub`: the base
entry plus everything beneath it, however deep. The alternatives are `-s one`,
the immediate children of the base and not the base itself, and `-s base`, the
base entry alone, exactly what the root DSE query used. **Scope is the first
thing to suspect when a search that should match returns nothing**, closely
followed by a base DN pointing one level too deep, and neither produces an
error: both produce `numEntries: 0`, which reads like the entry does not
exist.

```bash
# Debian 13 (trixie), x86_64
$ ldapsearch -x -LLL -H ldap://localhost -b dc=example,dc=com "(uid=jsmith)"
dn: uid=jsmith,ou=people,dc=example,dc=com
objectClass: inetOrgPerson
objectClass: posixAccount
uid: jsmith
cn: Jane Smith
sn: Smith
uidNumber: 10001
gidNumber: 10001
homeDirectory: /home/jsmith
loginShell: /bin/bash
```

**Every field a login needs is there**, and it came from one server rather than from
this machine. `-LLL` drops the comment blocks, which is what you want once you are
reading output rather than learning the format.

Filters are the query language: prefix notation, parenthesised, strange for about a
day.

```bash
# Debian 13 (trixie), x86_64
$ ldapsearch -x -LLL -H ldap://localhost -b dc=example,dc=com "(&(objectClass=posixAccount)(uidNumber>=10000))" uid uidNumber homeDirectory
dn: uid=jsmith,ou=people,dc=example,dc=com
uid: jsmith
uidNumber: 10001
homeDirectory: /home/jsmith
```

`(&(A)(B))` is A and B, `(|(A)(B))` is or, `(!(A))` is not. The trailing attribute
names limit what comes back, the way naming columns limits a `SELECT`.
`(objectClass=posixAccount)` is the filter every Linux client uses, because it is how
you find the entries that represent Unix accounts rather than printers, groups, or
people who have a mailbox and no shell.

## Binding, and why that is not the same as logging in

A search happens on a connection, and every connection has an identity, set by the
bind operation. If you do not bind as anybody, you are anonymous:

<details class="predict">
<summary>The rule: <code>-D</code> gives a bind DN and <code>-w</code> its password, and a connection with neither is anonymous. <code>ldapwhoami</code> asks the server who it thinks you are. What does it print with no <code>-D</code>, and then with the administrator's DN?</summary>

```bash
# Debian 13 (trixie), x86_64
$ ldapwhoami -x -H ldap://localhost; echo ---; ldapwhoami -x -H ldap://localhost -D cn=admin,dc=example,dc=com -w secret
anonymous
---
dn:cn=admin,dc=example,dc=com
```

</details>

**Anonymous is an identity**, not an error. This directory allows an anonymous
connection to read entries, which is how every search above worked without a
password. Whether that is acceptable is a policy decision, and it is usually the
wrong default; the panel below has the argument.

```bash
# Debian 13 (trixie), x86_64
$ ldapsearch -x -LLL -H ldap://localhost -D cn=admin,dc=example,dc=com -w wrongpass -b dc=example,dc=com; echo "exit=$?"
ldap_bind: Invalid credentials (49)
exit=49
```

**`Invalid credentials (49)`** is worth knowing by number, because it turns up in
application logs where the text has been thrown away. It means the bind failed:
either the DN does not exist or the password is wrong, and the server deliberately
does not say which, because that difference is a gift to somebody enumerating
accounts.

And here is the thing that makes the lookup-versus-authentication distinction
concrete. A bind *is* an authentication. Set a password on Jane's entry and she can
bind as herself:

```bash
# Debian 13 (trixie), x86_64
$ ldappasswd -x -H ldap://localhost -D cn=admin,dc=example,dc=com -w secret -s Passw0rd uid=jsmith,ou=people,dc=example,dc=com; ldapwhoami -x -H ldap://localhost -D uid=jsmith,ou=people,dc=example,dc=com -w Passw0rd
dn:uid=jsmith,ou=people,dc=example,dc=com
```

`ldappasswd` set the password, and `ldapwhoami` bound as `uid=jsmith,...` and
got back her own DN. **She authenticated to the directory**, with two
consequences. First, it works by **sending the password to the server**, on
every authentication, fine on a TLS connection and catastrophic without one.
Second, the client has to know Jane's DN before it can try, which means a
search before the bind, which means the client needs an identity of its own to
do that search. That two-step is why a client configured for LDAP
authentication has a bind DN in it that has nothing to do with the user
logging in.

Kerberos exists because there is a better answer to the same question.

<details class="deeper">
<summary>If you already administer Linux: StartTLS on 389, the ldaps-on-636 assumption, and why anonymous bind is the wrong default</summary>

The ports are in `/etc/services` and both are still there:

```bash
# Debian 13 (trixie), x86_64
$ grep -E "^ldap" /etc/services
ldap		389/tcp			# Lightweight Directory Access Protocol
ldap		389/udp
ldaps		636/tcp				# LDAP over SSL
ldaps		636/udp
```

**636 is the deprecated one, and it is the one everybody configures.** LDAPS
(implicit TLS, negotiated before any LDAP is spoken, on its own port) was
never standardised. What RFC 4511 standardises is the StartTLS extended
operation on the normal port 389: connect in the clear, immediately issue
StartTLS, and the connection is upgraded before any bind happens.

| | `ldaps://host:636` | `ldap://host:389` with StartTLS |
| --- | --- | --- |
| Standardised | No, de facto | Yes, RFC 4511 section 4.14 |
| TLS begins | Before any LDAP | After connect, before bind |
| Firewall rule | Second port | One port |
| Failure if TLS is unavailable | Connection fails | **Depends on the client** |

That last row is the one that bites. In SSSD, `ldap_id_use_start_tls` defaults to
`true` and fails the connection closed when StartTLS cannot be negotiated, which is
the behaviour you want; a client that merely *attempts* StartTLS and falls back will
happily continue in the clear, sending the user's password across the network in
plain text while every dashboard stays green. Verify it is mandatory rather than
opportunistic, and verify certificates are checked: `ldap_tls_reqcert` defaults to
`hard`, meaning a bad or missing certificate terminates the session, and
`ldap_tls_reqcert = never` is a deliberate downgrade from that default which turns
TLS into encryption with nothing authenticating the far end.

**How much protection a connection actually has is measurable, not inferred from the
URL.** When a SASL mechanism is in play, `ldapsearch` prints the security strength
factor the layer negotiated:

```bash
# Debian 13 (trixie), x86_64
$ ldapsearch -Y EXTERNAL -H ldapi:/// -b cn=config -LLL dn 2>&1 | head -20
SASL/EXTERNAL authentication started
SASL username: gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth
SASL SSF: 0
dn: cn=config

dn: cn=module{0},cn=config

dn: cn=schema,cn=config

dn: cn={0}core,cn=schema,cn=config

dn: cn={1}cosine,cn=schema,cn=config

dn: cn={2}nis,cn=schema,cn=config

dn: cn={3}inetorgperson,cn=schema,cn=config

dn: olcDatabase={-1}frontend,cn=config

dn: olcDatabase={0}config,cn=config
```

`SASL SSF: 0` means no encryption layer, which is correct here and alarming over TCP;
a TLS-protected connection reports 128 or 256. Read that number rather than trusting
the scheme in the URL.

Two other things in that transcript are worth taking away. **`-Y EXTERNAL`
over `ldapi:///` is authentication by Unix socket credentials**, the server
read the peer's uid and gid from the kernel and turned them into
`gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth`, so root on the
server needs no password and no bind DN, which is how you get back in when the
administrator password is lost. **And `cn=config` is the server's own
configuration, stored as directory entries** rather than as a file. The
`olcDatabase={N}mdb,cn=config` entry further down that tree is where the
suffix, the root DN, and the access control lists live on a modern OpenLDAP,
changed with `ldapmodify` against a running server rather than by editing
anything. The `slapd.conf` that older documentation tells you to edit is
superseded: still accepted if `slapd` is started with `-f`, and still the
reason a change made in a file has no effect on a server started from
`slapd.d`.

**On anonymous bind:** a lot of deployments permit anonymous read because it
makes everything work immediately. What it means is that anybody who can reach
port 389 can enumerate every user, group, mail address, phone number, and uid
number without a credential, a reconnaissance package handed over for free,
retrieved with one command that leaves no interesting trace. Disable anonymous
read for anything beyond the root DSE, give each client its own bind DN with
read access to the attributes it genuinely needs, and monitor binds. The root
DSE should stay readable, because `namingContexts` is how clients discover
where to look.

</details>

## Kerberos, tickets instead of a password

Kerberos answers the authentication question with a design goal LDAP binds do not
have: **the password never crosses the network, and no service you log in to ever
learns it.**

<figure class="learn-figure">
<svg viewBox="0 0 720 360" role="img" aria-labelledby="kb-title kb-desc" style="width:100%;height:auto;">
  <title id="kb-title">The Kerberos ticket exchange between client, KDC, and service</title>
  <desc id="kb-desc">Three parties in vertical lanes. The client is on the left, the key distribution centre in the middle holding the authentication service, the ticket-granting service, and the principal database, and an application service such as a file server on the right. Step one: the client sends an authentication service request naming itself, including a timestamp encrypted with a key derived locally from the user's password, which proves knowledge of the password without transmitting it. Step two: the KDC replies with a ticket-granting ticket and a session key, encrypted so that only the holder of the user's key can open it. Step three: the client presents the ticket-granting ticket back to the ticket-granting service and names the service it wants to reach. Step four: the ticket-granting service returns a service ticket for exactly that service. Step five: the client presents the service ticket to the service, which decrypts it using its own long-term key held in a keytab, and never contacts the KDC at all. Every ticket carries timestamps, which is why all three clocks must agree.</desc>
  <g font-family="ui-monospace, monospace">
    <rect x="18" y="14" width="150" height="46" rx="5" fill="currentColor" fill-opacity="0.12" stroke="currentColor" stroke-opacity="0.4"/>
    <text x="93" y="34" text-anchor="middle" font-size="12" fill="currentColor">client</text>
    <text x="93" y="51" text-anchor="middle" font-size="9.5" fill="currentColor" fill-opacity="0.65">jsmith@EXAMPLE.COM</text>
    <rect x="266" y="14" width="188" height="46" rx="5" fill="currentColor" fill-opacity="0.12" stroke="currentColor" stroke-opacity="0.4"/>
    <text x="360" y="34" text-anchor="middle" font-size="12" fill="currentColor">KDC</text>
    <text x="360" y="51" text-anchor="middle" font-size="9.5" fill="currentColor" fill-opacity="0.65">AS + TGS + the key database</text>
    <rect x="552" y="14" width="150" height="46" rx="5" fill="currentColor" fill-opacity="0.12" stroke="currentColor" stroke-opacity="0.4"/>
    <text x="627" y="34" text-anchor="middle" font-size="12" fill="currentColor">service</text>
    <text x="627" y="51" text-anchor="middle" font-size="9.5" fill="currentColor" fill-opacity="0.65">nfs/files.example.com</text>
    <text x="104" y="98" font-size="9.5" fill="currentColor" fill-opacity="0.8">1. AS-REQ: I am jsmith, and here is a timestamp encrypted with my key</text>
    <text x="104" y="146" font-size="9.5" fill="currentColor" fill-opacity="0.8">2. AS-REP: a TGT and a session key, encrypted so only my key opens it</text>
    <text x="104" y="206" font-size="9.5" fill="currentColor" fill-opacity="0.8">3. TGS-REQ: here is my TGT, I want a ticket for nfs/files</text>
    <text x="104" y="254" font-size="9.5" fill="currentColor" fill-opacity="0.8">4. TGS-REP: a service ticket for nfs/files, and nothing else</text>
    <text x="104" y="314" font-size="9.5" fill="currentColor" fill-opacity="0.8">5. AP-REQ: the service ticket, which the service opens with its own keytab</text>
    <text x="360" y="340" text-anchor="middle" font-size="9.5" fill="currentColor" fill-opacity="0.65">the service never contacts the KDC, and never sees the password</text>
  </g>
  <g stroke="currentColor" stroke-opacity="0.3" stroke-dasharray="3 4" stroke-width="1">
    <path d="M93 60 L93 322"/>
    <path d="M360 60 L360 268"/>
    <path d="M627 60 L627 322"/>
  </g>
  <g stroke="currentColor" stroke-opacity="0.5" fill="none" stroke-width="1.2">
    <path d="M93 108 L354 108 M348 104 L355 108 L348 112"/>
    <path d="M360 156 L99 156 M105 152 L98 156 L105 160"/>
    <path d="M93 216 L354 216 M348 212 L355 216 L348 220"/>
    <path d="M360 264 L99 264 M105 260 L98 264 L105 268"/>
    <path d="M93 324 L621 324 M615 320 L622 324 L615 328"/>
  </g>
</svg>
<figcaption>Five messages. The password is used as an encryption key on the client and is never transmitted; the service authenticates the ticket without ever talking to the KDC.</figcaption>
</figure>

**Step one is the one that surprises people.** `kinit` does not send the password. It
derives a key from it locally, encrypts the current time with that key, and sends
that. The KDC has the same key in its database, decrypts the timestamp, and if the
result is a sensible time then the client must hold the right key. This is
pre-authentication, and the timestamp is why: a static proof could be recorded and
replayed for ever, and a timestamp cannot, because it is only accepted inside a narrow
window.

Step two returns a ticket you cannot read, plus a copy of the session key that
you can. The TGT is encrypted with the KDC's own key, so it is opaque to you;
you hold it and hand it back. Everything after this uses the session key
rather than your password, which is why you type a password once and then
reach a dozen services without typing it again. Single sign-on is a
consequence of the design rather than a feature bolted on.

Step five is where the value lands. The file server decrypts your service
ticket with its own long-term key, from a keytab on its disk. It does not ask
the KDC anything, has never seen your password, and cannot replay your ticket
against another service, because a service ticket names exactly one service. A
compromised file server does not become a compromised password.

The vocabulary, once, because it is the part that gets examined:

| Term | Is |
| --- | --- |
| principal | A named identity: `jsmith@EXAMPLE.COM` for a user, `host/web1.example.com@EXAMPLE.COM` for a machine |
| realm | The administrative domain, capitalised: `EXAMPLE.COM` |
| KDC | The server: the authentication service, the ticket-granting service, and the database |
| TGT | The ticket you get first, and exchange for the others |
| service ticket | A ticket for one named service, obtained using the TGT |
| keytab | A file holding a principal's long-term key, so a service can authenticate with no human present |
| credential cache | Where your tickets live on the client while they are valid |

The client-side commands are three: `kinit` to get a TGT, `klist` to list what you
hold, `kdestroy` to throw it away. Run `klist` on a machine holding no tickets and it
does not go quiet:

```bash
# openSUSE Leap 16.0, x86_64
$ klist; echo "exit=$?"
klist: Invalid UID in persistent keyring name while resolving ccache
exit=1
```

That is not the message most people expect, and it is the more instructive one,
because it is complaining about *where* the cache would be rather than about what is
in it. The configuration explains why:

```bash
# openSUSE Leap 16.0, x86_64
$ grep -vE "^\s*(#|$)" /etc/krb5.conf; echo ---; ls /etc/krb5.conf.d
includedir  /etc/krb5.conf.d
[libdefaults]
    dns_canonicalize_hostname = false
    rdns = false
	default_ccache_name = KEYRING:persistent:%{uid}
[realms]
[logging]
    kdc = FILE:/var/log/krb5/krb5kdc.log
    admin_server = FILE:/var/log/krb5/kadmind.log
    default = SYSLOG:NOTICE:DAEMON
---
crypto-policies
enable_sssd_conf_dir
```

`default_ccache_name = KEYRING:persistent:%{uid}` is the answer. Tickets go
into the kernel keyring, keyed by uid, and this container has no persistent
keyring for uid 0 to attach to, so the library cannot even name the cache.
**MIT's own compiled-in default is a file, `FILE:/tmp/krb5cc_%{uid}`**, and
every distribution in this topic overrides it, which is why documentation
telling you to look in `/tmp` is describing a machine you probably do not
have. Name a file cache explicitly and the message becomes the one worth
memorising:

```bash
# openSUSE Leap 16.0, x86_64
$ export KRB5CCNAME=FILE:/tmp/krb5cc_0; klist; echo "exit=$?"
klist: No credentials cache found (filename: /tmp/krb5cc_0)
exit=1
```

**That is what "not logged in to Kerberos" looks like**, no credential cache,
exit status 1. Two failures, two different messages, and neither means a
password was rejected. `KRB5CCNAME` overrides the configured default for one
process and its children, which makes it the fastest way to test without
disturbing anything. The keyring has an operational tail, too: because the
cache is keyed by uid, `sudo` to another user and your tickets do not come
with you, and a daemon running under its own account cannot borrow yours. That
is deliberate, and it is why services get keytabs instead of ticket caches.

`[realms]` is empty here, because nothing has joined this machine to anything. Ask for
a ticket anyway and the client says precisely what it failed to find:

```bash
# openSUSE Leap 16.0, x86_64
$ export KRB5CCNAME=FILE:/tmp/krb5cc_0; kinit jsmith@EXAMPLE.COM; echo "exit=$?"
kinit: Cannot find KDC for realm "EXAMPLE.COM" while getting initial credentials
exit=1
```

**`Cannot find KDC for realm` is a discovery failure, not an authentication
failure.** It never reached the point of asking for a password. On a
configured client the `[realms]` section names the realm's KDCs, or is left
empty on purpose so the client finds them from DNS SRV records:
`_kerberos._udp.EXAMPLE.COM` and friends, looked up because `dns_lookup_kdc`
defaults to true. That is what Active Directory relies on, and it is why a
client with the wrong DNS server presents as Kerberos being broken rather than
as DNS being broken.

<details class="deeper">
<summary>If you already administer Linux: clock skew, and why NTP is a hard dependency rather than a nice-to-have</summary>

Every Kerberos message carries a timestamp, and every recipient checks it against its
own clock. The tolerance is **five minutes**, set by `clockskew` in `krb5.conf` and
documented as 300 seconds. Outside that window the message is rejected:

```
kinit: Clock skew too great while getting initial credentials
```

**The timestamps are not incidental, they are the anti-replay mechanism.** An
authenticator is a small structure encrypted with the session key, holding the
client's name and the current time. A service checks that the time is inside
the window and that it has not already seen that exact authenticator, the
replay cache. Widen the window and you widen the period in which a captured
authenticator can be replayed. The tolerance therefore cannot be made large,
which is why Kerberos genuinely does not work on a machine with a wrong clock.

Three things this changes about how you run these machines:

- `chronyd` or `systemd-timesyncd` is a *dependency* of authentication. A machine that
  cannot reach an NTP server authenticates fine until its clock drifts five minutes,
  which on a virtual machine after a suspend or a migration can take seconds rather
  than months.
- The KDC, the client, and the service must all agree. Two of the three being right is
  not enough, and the error surfaces on whichever pair is talking, which is why the
  report arrives as "user X cannot reach server Y" rather than "server Y has a bad
  clock".
- Time zones are irrelevant and people waste hours on them. Everything is UTC
  internally. A machine showing the wrong local time has a `timedatectl` problem; a
  machine failing Kerberos has a clock problem, and `timedatectl` reports
  `System clock synchronized: no` in that case.

The diagnosis is two commands, on both ends:

```
timedatectl
chronyc tracking
```

An offset in milliseconds is healthy; anything in whole seconds is drifting
toward a failure you will be paged for. On a virtual machine, check that the
hypervisor is not also setting the clock, two things adjusting one clock in
different directions produces intermittent authentication failures that
correlate with nothing.

The related error worth separating, because it looks similar and is not, is
`Preauthentication failed`. That is a wrong password. `Clock skew too great` is a
right password on a machine that disagrees about what time it is.

</details>

## SSSD, the client that glues it all to NSS and PAM

Nothing described so far knows how to make `ls -l` print a username. SSSD is
the piece that does. It runs as a daemon, it is configured per domain, and
each domain names an identity provider and an authentication provider,
**separately**, which is the same distinction the whole topic is built on.

```bash
# openSUSE Leap 16.0, x86_64
$ sssd --version; echo ---; klist -V
2.10.2
---
Kerberos 5 version 1.21.3
```

Worth checking on a machine you have inherited, because SSSD option names and defaults
have moved between the 1.x that shipped with RHEL 7 and the 2.x everything ships now.

Here is a working configuration for a machine that gets its users from LDAP:

```bash
# openSUSE Leap 16.0, x86_64
$ cat /etc/sssd/sssd.conf
[sssd]
domains = example.com
services = nss

[domain/example.com]
id_provider = ldap
ldap_uri = ldap://localhost
ldap_search_base = dc=example,dc=com
ldap_id_use_start_tls = false
cache_credentials = true
```

Every line is load-bearing. `domains = example.com` names this stanza and is
not a DNS lookup. It has to match the text after `domain/` in the section
header and nothing else. `services = nss` says which of SSSD's interfaces to
answer on. `id_provider = ldap` sets where identity comes from and
`ldap_search_base` is the base DN from earlier.

The last two lines are the interesting ones, and one is a lie of omission.
**`ldap_id_use_start_tls` defaults to `true`**, so setting it to `false` is an
explicit downgrade, honest about what this is: a demonstration directory
reached over `localhost`, where there is no network to eavesdrop on. On
anything real that one line decides whether every identity lookup crosses the
network in the clear. And `cache_credentials = true`, off by default, stores a
hash of a successful authentication locally, for the panel below. In *this*
file it does nothing at all, because nothing here authenticates, which is a
good illustration of how a setting can be present, correct, and inert.

**Notice what is missing: there is no `auth_provider`, and `services` does not list
`pam`.** This machine can look users up and cannot log them in. That is not a broken
configuration, it is the split from the top of the topic made visible in six lines.
Adding `auth_provider = krb5` with a KDC, or `auth_provider = ldap` to bind against
the directory, is what turns lookups into logins. With `auth_provider` absent, SSSD
falls back to the identity provider where that provider can authenticate, which is why
`id_provider = ad` on its own gets you both halves and `id_provider = ldap` on its own
quietly gets you authentication by bind.

Then NSS has to be told to ask SSSD at all, in `/etc/nsswitch.conf`, a file
which, on this particular distribution, had to be created first, for reasons
the distributions section covers.

<details class="predict">
<summary>The rule: NSS consults each source on the line in order until one answers. <code>jsmith</code> is not in this machine's <code>/etc/passwd</code>; the entry exists only in the LDAP directory, with <code>uidNumber: 10001</code>. Given the <code>passwd</code> line below, what does <code>getent passwd jsmith</code> print, and what does <code>id jsmith</code> say about groups?</summary>

```bash
# openSUSE Leap 16.0, x86_64
$ grep -E "^(passwd|group)" /etc/nsswitch.conf; echo ---; getent passwd jsmith; echo ---; id jsmith
passwd:  compat sss
group:   compat sss
---
jsmith:*:10001:10001:Jane Smith:/home/jsmith:/bin/bash
---
uid=10001(jsmith) gid=10001 groups=10001
```

</details>

**That is a `/etc/passwd` line for a user who is not in `/etc/passwd`.** The
fields came from the directory: `uidNumber` became the third field,
`gidNumber` the fourth, `cn` the GECOS field, `homeDirectory` and `loginShell`
the last two. The `*` in the password field is NSS declining to expose a hash,
which is correct. That is authentication's business, not identity's.

`id jsmith` is the more revealing of the two. `uid=10001(jsmith)` carries a
name in brackets and `gid=10001` does not, because there is a user entry for
10001 in the directory and no group entry for it anywhere. **A bare number
with no name beside it means the lookup for that object failed, not that it
has no name**, the same tell appears in `ls -l`, which prints numbers instead
of names for exactly this reason.

The supplementary list is empty because group membership is a separate set of entries
with their own objectClass, and this directory has none. In the older RFC 2307 schema
a `posixGroup` lists its members as `memberUid: jsmith`, plain usernames; in RFC
2307bis, which FreeIPA uses, a group lists `member:` with full DNs, and Active
Directory's own schema works the same way. SSSD is told which by `ldap_schema`, which
defaults to `rfc2307`, and pointing it at a 2307bis directory without changing that
produces users who log in perfectly and belong to nothing. "Their groups are missing"
is the most common real complaint about a new SSSD deployment, and this is usually why.

`getent` is the right tool because **it asks the same question the operating system
asks**, through the same NSS path, rather than asking LDAP directly:

```bash
# openSUSE Leap 16.0, x86_64
$ getent passwd root; echo ---; getent passwd nosuchuser; echo "exit=$?"
root:x:0:0:root:/root:/bin/bash
---
exit=2
```

Two useful facts in one transcript. `root` comes from `/etc/passwd`: `compat`
is first on the line and it answered, so SSSD was never consulted, which is
exactly what you want for the account that has to work when the network is
down. And a user who exists nowhere produces **no output and exit status 2**,
which is what you test in a script rather than grepping for an empty string.

`sssctl config-check` is the first command to run on a non-working daemon, which is
unforgiving about its configuration file and vaguer than this in the journal:

```bash
# openSUSE Leap 16.0, x86_64
$ sssctl config-check
Issues identified by validators: 0

Messages generated during configuration merging: 0

Used configuration snippet files: 0
```

Then the cache, which is where the surprises live:

```bash
# openSUSE Leap 16.0, x86_64
$ getent passwd jsmith >/dev/null; sssctl user-show jsmith
Name: jsmith
Cache entry creation date: 08/08/26 17:51:25
Cache entry last update time: 08/08/26 17:51:25
Cache entry expiration time: 08/08/26 19:21:25
Initgroups expiration time: Initgroups were not yet performed
Cached in InfoPipe: No
```

Every entry has a creation time and an **expiration time**, ninety minutes apart here,
which is the default `entry_cache_timeout` of 5400 seconds. Until it expires, changes
made in the directory are invisible on this machine: a user renamed centrally, a shell
changed, a group membership added. "I changed it in the directory and the server has
not noticed" is very often exactly this.

`Initgroups expiration time: Initgroups were not yet performed` is the other
line worth reading. **Identity and group membership are fetched separately**:
looking a user up caches the user, and only an `initgroups` call, which is
what `id` and a real login do, goes back for the list of groups they are in. A
`getent passwd` that succeeds therefore proves nothing about whether groups
will resolve.

The cache itself is a few files, and the mode on them is not decoration:

```bash
# openSUSE Leap 16.0, x86_64
$ ls -l /var/lib/sss/db
total 3768
-rw-------. 1 root root 1286144 Aug  8 17:52 cache_example.com.ldb
-rw-------. 1 root root 1286144 Aug  8 17:52 config.ldb
-rw-------. 1 root root 1286144 Aug  8 17:52 timestamps_example.com.ldb
```

`0600`, owned by root, one `cache_<domain>.ldb` per configured domain. It holds the
identity data of everybody who has logged in to this machine and, with
`cache_credentials` on, hashes of their passwords. **A backup that sweeps up
`/var/lib/sss/db` is a backup carrying credentials**, and so is a disk image of a
decommissioned machine.

<details class="deeper">
<summary>If you already administer Linux: what the cache does when the directory is unreachable, and how to invalidate it without breaking everybody</summary>

The cache is the reason SSSD replaced the older `nss_ldap` and `pam_ldap` modules, and
it does two distinct jobs that get conflated.

**Job one: identity caching, which is on and unavoidable.** Every lookup answered from
the directory is stored with an expiry. Without it, `ls -l` on a directory of a
thousand files could become a thousand LDAP searches; the old libraries could take a
directory server down by themselves. The knobs are `entry_cache_timeout` (5400 seconds
by default) and per-type overrides like `entry_cache_user_timeout`.

Job two: credential caching, which is off by default and is a decision.
`cache_credentials = true` stores a hash of the password after a successful
authentication so the user can log in while the directory is unreachable. That
is what makes laptops usable and a datacentre outage survivable. It also puts
a password hash on every machine the user has ever logged in to, and means
disabling an account centrally does not immediately lock them out of those
machines. `offline_credentials_expiration` in the `[pam]` section caps how
many days offline logins remain possible; it defaults to 0, meaning no limit,
and setting it is the difference between a considered risk and an accident.

Watch the two failure modes, because they look identical from a terminal:

| Symptom | Identity cache | Credential cache |
| --- | --- | --- |
| `getent passwd` works, login fails | Entry still cached | `cache_credentials` off, or never logged in here |
| Both work, but the account was disabled yesterday | Entry not yet expired | Offline login still permitted |
| Nothing works for a user who has never used this host | Never cached | Never cached |

That third row is the operationally important one: **the cache only helps people it has
seen before.** A directory outage looks like nothing is wrong on the machines where
everybody has logged in recently, and like a total failure on the machine built
yesterday. Testing an outage on a machine you have been using all week proves nothing.

**Invalidating it properly.** The wrong instinct is to stop SSSD and delete
`/var/lib/sss/db/*.ldb`, which works and throws away every cached credential on the
machine, so an offline user is now locked out. The right tools are surgical:

```
sudo sss_cache -u jsmith        # one user
sudo sss_cache -g developers    # one group
sudo sss_cache -E               # everything, but only marks it expired
```

`sss_cache -E` marks entries expired rather than deleting them, so the next
lookup refreshes from the directory and nothing is lost if the directory is
unavailable. `sssctl cache-expire` takes the same options and is the same
implementation, it even prints `Usage: sss_cache` in its own help, so do not
go looking for a difference in behaviour. Keep `rm -rf` for a genuinely
corrupt cache, and expect a support call from whoever is on a train at the
time.

**There is a second cache**, the fast memory cache under `/var/lib/sss/mc`, which
serves repeated lookups out of a shared mapping without waking the daemon at all. Its
lifetime is `memcache_timeout`, defaulting to 300 seconds rather than 5400, which is
why a change can appear within five minutes on one machine and take ninety on another
depending on which cache answered.

`sss_cache` does invalidate it, and the mechanism has a consequence worth knowing. The
file is mapped into every process that has done a lookup, so it cannot simply be
truncated: SSSD sets an invalid flag in its header, unlinks it, and creates a new one,
and each process notices the flag on its next lookup and maps the replacement. **A
long-running process that looked a user up once at startup and never again keeps the
old file mapped for ever**, so the disk space is not returned. Invalidating the cache
in a loop on a machine running such a daemon makes disk usage go up, not down, and the
files are invisible to `ls` because they have already been unlinked. `lsof` on
`/var/lib/sss/mc` is how you find them, and restarting the offending process is the
only way to release them.

</details>

## Active Directory, realm join, and where Winbind fits

Active Directory is an LDAP directory and a Kerberos KDC in one product, plus DNS and
a proprietary replication mechanism. Everything above applies: the tree, the DNs, the
base DN, the tickets. Two things differ enough to matter.

**Its schema is not the POSIX one.** An AD user has `sAMAccountName` where a
`posixAccount` has `uid`, and by default has no `uidNumber` at all. Something has to
produce a numeric uid, and there are two answers: store POSIX attributes in AD and read
them, or have the client derive uids algorithmically from the user's security
identifier.

`ldap_id_mapping` is the switch, and **its default depends on which provider you are
using**, which is exactly the sort of thing that gets assumed rather than checked. The
AD provider sets it to true and maps from `objectSID`; under the generic
`id_provider = ldap` it is false and SSSD expects real `uidNumber` attributes. Turning
it off on an AD domain is how you say "we populated POSIX attributes, use those".

The algorithm is deterministic rather than random (it hashes the domain SID to
pick a slice, then derives the uid from the relative identifier within it) but
determinism only holds if every client agrees on the arithmetic. The inputs
are `ldap_idmap_range_min` (200000), `ldap_idmap_range_max` (2000200000), and
`ldap_idmap_range_size` (200000). **Change the range size on one machine and
every uid on that machine changes**, so files written before the change are
owned by nobody after it. Mixing algorithmic mapping with POSIX attributes
across an estate, or mixing range settings, reproduces the NFS ownership
problem from the top of this topic on purpose. The check is one command on two
hosts: `id someuser` should return the same number on both, and if it does
not, nothing else about the deployment is worth debugging yet.

**Joining is a real operation, not a configuration file.** A domain member has
an identity of its own, a computer account with a password, and joining
creates it:

```
realm discover ad.example.com
sudo realm join --user=Administrator ad.example.com
realm list
```

`realm discover` is a DNS SRV lookup plus a root DSE query, and it is worth
the ten seconds: it reports the realm name, the server software, and which
client packages are needed, before you have changed anything. `realm join`
then gets a Kerberos ticket as the administrator you named, creates the
computer object, writes `/etc/krb5.keytab`, generates `/etc/sssd/sssd.conf`,
and rewires PAM and NSS through whichever tool the family uses: `authselect`
on RHEL, `pam-auth-update` on Debian.

The two client stacks, which the exam does ask you to distinguish:

| | SSSD | Winbind |
| --- | --- | --- |
| Comes from | The SSSD project | The Samba project |
| Handles | LDAP, AD, IPA, Kerberos, and more | AD and NT domains |
| Identity mapping | Algorithmic or POSIX attributes | Algorithmic or `idmap` backends |
| Offline logins | Yes, cached credentials | Yes, cached credentials |
| Needed for | The general case | Samba serving files to domain users |
| NSS module | `sss` | `winbind` |

**SSSD is the default and Winbind is the exception.** Use SSSD unless this machine is
a Samba file server presenting shares to domain users, in which case `smbd` needs
Winbind's mapping of Windows security identifiers to Unix uids, because that mapping
has to be the same one the file server uses when it writes ownership onto the disk.
Running both at once is possible and is a well-known way to end up with two different
uids for one person.

<details class="deeper">
<summary>If you already administer Linux: what is actually in a keytab, and why it is as sensitive as a password file</summary>

A keytab is a file of principals and their long-term keys. `/etc/krb5.keytab` on a
joined machine holds the host's own keys, and it is what allows `sshd` to accept a
Kerberos ticket, or a cron job to `kinit -k` with no human present.

**A keytab is a password in a form that needs no typing.** Anybody who can
read it can authenticate as that principal for as long as the key is valid. It
should be `0600` and owned by root, it should never be in a git repository,
and copying one between machines is copying a credential, a keytab for
`host/web1` on `web2` means `web2` can impersonate `web1` to anything in the
realm. Inspect one without needing the KDC:

```
sudo klist -k /etc/krb5.keytab
sudo klist -Kte /etc/krb5.keytab
```

The columns are the **key version number** (KVNO), the principal, and with `-e` the
encryption type. `-K` prints the key itself, which is the fastest way to convince
somebody that a keytab deserves the same handling as a private key.

**KVNO is the field that causes the outages.** Every time a principal's key
changes (a computer account password rotation, an `adcli update`, somebody
re-joining a machine that was already joined) the KVNO increments in the
directory. Tickets are issued against the current KVNO, and a service whose
keytab still holds the previous one cannot decrypt them. The error is `Key
version number for principal in key table is incorrect`, and it arrives on a
machine nobody touched.

The clock behind it is `ad_maximum_machine_account_password_age`, which
defaults to **30 days**: SSSD checks once a day and renews the computer
account password when it is older than that, updating `/etc/krb5.keytab` as it
goes. Setting it to 0 disables renewal, which is how an estate quietly
accumulates machines whose keys the domain will eventually stop honouring. The
two ways this bites are a machine powered off through its renewal window, and
a keytab copied somewhere else that is now stale while the original is fine.
Either way the fix is `adcli update --domain=ad.example.com` to refresh the
keytab in place, not another join, a second join creates a second computer
object or resets the first, and takes every other keytab derived from it out
with it.

A keytab can legitimately hold several KVNOs for one principal, which is how rotation
happens without a gap: the new key is added before the old is retired, so in-flight
tickets keep working. That is why `klist -k` output is longer than people expect and
why deleting "duplicate" entries breaks things.

**And the service principal name has to match how clients reach the machine.** A ticket
is requested for `host/web1.example.com`; if the keytab holds only `host/web1`, or the
client reaches it through a CNAME with a different name, the service ticket cannot be
decrypted and you get a Kerberos error that looks like an authentication failure and is
really a naming failure. The two `krb5.conf` settings in the capture above are the
client's half of that, and they are not equals. **`dns_canonicalize_hostname = false`
is the one doing the work**: it stops the client rewriting the hostname you typed into
whatever DNS resolves it to before building the service principal name. `rdns` only
adds a reverse lookup on top of that canonicalisation, and MIT's documentation is
explicit that with `dns_canonicalize_hostname` set to false, `rdns` has no effect at
all. Both default to true, so a machine with a stock `krb5.conf` does canonicalise.

</details>

## Samba is two different jobs with one name

This trips people up in conversation as much as in configuration, so state it plainly:
**Samba the file service and Samba the domain member are separate things, and either
can exist without the other.**

| Role | What it means | Needs a domain |
| --- | --- | --- |
| File and print server | `smbd` serving SMB shares defined in `/etc/samba/smb.conf` | No |
| Domain member | The machine is joined, and authenticates users against the domain | Not to serve files |
| Domain controller | Samba **is** the AD directory and KDC, provisioned with `samba-tool` | It is the domain |

A standalone Samba server with `security = user` keeps its own account database with
`smbpasswd`, shares a directory, and knows nothing about LDAP or Kerberos. That is what
most people mean by "a Samba server". Change one line to `security = ads` and the same
daemon is a domain member: users authenticate with domain credentials, their tickets
are Kerberos tickets, and `smbd` needs a way to turn a Windows security identifier into
a Unix uid so it can set ownership on the files it writes. That is the Winbind job from
the table above, and it is the one case where Winbind rather than SSSD is the answer.

**The third row is the one people forget exists.** `samba-tool domain provision` stands
up an AD-compatible directory, KDC, and DNS, and Windows clients join it as they would
join a Microsoft one. That makes Samba a peer of Active Directory rather than a client
of it, and it is why "Samba" is an unhelpfully broad answer to "how are you doing
identity".

## Across distributions

The protocols are identical everywhere. The package names, the file locations, and the
tool that rewires PAM are not.

| | RHEL family | Debian family |
| --- | --- | --- |
| LDAP client tools | `openldap-clients` | `ldap-utils` |
| LDAP server | none since RHEL 8; `389-ds-base` instead | `slapd` |
| SSSD | `sssd`, `sssd-ldap`, `sssd-ad` | `sssd`, `sssd-ldap`, `sssd-ad` |
| Join tooling | `realmd`, `adcli` | `realmd`, `adcli` |
| Home directory on first login | `oddjob-mkhomedir`, or `pam_mkhomedir` from `pam` | `pam_mkhomedir` from `libpam-modules` |
| Rewires PAM and NSS | `authselect select sssd --force` | `pam-auth-update` |
| Kerberos client | `krb5-workstation` | `krb5-user` |
| Samba domain member | `samba-winbind`, `samba-winbind-clients` | `winbind`, `libnss-winbind` |

**Two rows in that table are traps.** The first is the LDAP server: Red Hat
deprecated `openldap-servers` in RHEL 7.4 and dropped it in RHEL 8, so on
RHEL, AlmaLinux, and Rocky the client tools are present and the server package
simply is not there, 389 Directory Server is the supported one. The `slapd`
behind the Debian captures in this topic has no RHEL-family equivalent to
install.

The second is `pam_mkhomedir`. **There is no `libpam-mkhomedir` package**, on Debian or
anywhere else; the module ships inside `libpam-modules` and is switched on with
`pam-auth-update --enable mkhomedir`. On the RHEL family the same job is usually done
by `oddjob-mkhomedir`, which creates the directory through a privileged helper rather
than inside the PAM stack, and is turned on as an authselect feature:
`authselect select sssd with-mkhomedir`. Either way, a central user logging in to a
machine with neither enabled lands in a home directory that does not exist, gets
dropped into `/` with a shell that cannot write its history, and reports it as "the
account is broken".

**`authselect` is the row worth knowing for the exam and for your fingers.** It manages
`/etc/pam.d` and `/etc/nsswitch.conf` as a versioned profile rather than as files you
edit, so `authselect select sssd` writes a known-good stack and `authselect current`
tells you what is in force. Editing `/etc/pam.d/system-auth` by hand on such a system
produces a warning and a change the next `authselect` run discards. It replaced
`authconfig`, the name in older documentation. What it writes carries three decisions:

```
passwd:     files sss systemd
shadow:     files systemd
group:      files [SUCCESS=merge] sss [SUCCESS=merge] systemd
```

`files` comes before `sss`, so root and the other local accounts still resolve
when the directory is unreachable. `shadow` names no `sss` because there is
nothing to name: `libnss_sss` exports `getpwnam`, `getgrnam`, `gethostbyname`
and their relatives and no shadow entry points at all, so `sss` on a `shadow`
line is inert wherever it appears, and it does appear, because Debian's
`sssd-common` package writes it in.

**`[SUCCESS=merge]` on the `group` line is the third decision, and the one to
recognise.** NSS normally stops at the first source that answers, so a group defined
both in `/etc/group` and in the directory would return only its local members: a user's
central membership of `wheel` or `docker` vanishes silently, with no error anywhere.
`[SUCCESS=merge]` means "having found a match, carry on and combine the member lists".
The authselect `sssd` profile ships it; Debian's `nsswitch.conf` after installing SSSD
does not, and a hand-written line will not have it unless you put it there. If a group
is defined in exactly one place you will never notice; the moment somebody adds a local
group with a name the directory already uses, you will.

SUSE adds a wrinkle that will confuse anybody arriving from the other two families, and
it is why the SSSD captures earlier could grep a file this section says does not exist:

```bash
# openSUSE Leap 16.0, x86_64
$ ls -l /etc/nsswitch.conf /usr/etc/nsswitch.conf 2>&1; grep -E "^(passwd|group)" /usr/etc/nsswitch.conf
ls: cannot access '/etc/nsswitch.conf': No such file or directory
-rw-r--r--. 1 root root 2222 Aug 26  2025 /usr/etc/nsswitch.conf
passwd:		compat systemd
group:		compat [SUCCESS=merge] systemd
```

**There is no `/etc/nsswitch.conf` at all** until something creates one. The
distribution's default lives in `/usr/etc`, and `/etc` is reserved for local
changes, you copy the file down and edit the copy, which is exactly what
happened to the machine behind the SSSD captures above. Note what the shipped
default says: `compat systemd`, with no `sss` anywhere. **Nothing on this
distribution adds it for you**, and until it is added, SSSD can be installed,
configured, running, and answering nothing. The failure mode is silent in both
directions: `grep` in `/etc` finds no file and tells you nothing about what
the machine is doing, and editing `/usr/etc` instead is real until the next
package update overwrites it. `getent passwd` is the question that does not
care which file won.

## Prove it

```
# Is the directory reachable, and what is its base DN
ldapsearch -x -H ldap://dc1.example.com -s base -b "" namingContexts

# Can I read the entry for a user, and does it have POSIX attributes
ldapsearch -x -LLL -H ldap://dc1.example.com -b dc=example,dc=com "(uid=jsmith)"

# Does the operating system agree, which is a different question
getent passwd jsmith
id jsmith

# Is SSSD's configuration valid, and what is cached
sudo sssctl config-check
sudo sssctl user-show jsmith
sudo sssctl domain-status example.com

# Do I hold a Kerberos ticket, and until when
klist

# Do the clocks agree, which Kerberos requires
timedatectl
```

**`ldapsearch` working and `getent` not working is the single most informative result
in that list.** It says the directory, the network, and the credentials are fine, and
that the problem is on this machine between NSS and SSSD. Running both before forming a
theory takes ten seconds and eliminates half the possible causes.

## What trips people up

### 1. The bind DN is not a username

`-D jsmith` fails. The bind DN is a full distinguished name,
`uid=jsmith,ou=people,dc=example,dc=com`. Active Directory additionally accepts
`jsmith@example.com` and `EXAMPLE\jsmith`, which is convenient and teaches the wrong
lesson to anybody who then tries it against OpenLDAP. The error is
`ldap_bind: Invalid credentials (49)` either way and the server will not say whether it
was the name or the password, so check the DN with a search first.

### 2. `ldapsearch` works and `getent` does not

They ask different things through different code. `ldapsearch` speaks to the server;
`getent` goes through NSS, which reads `/etc/nsswitch.conf`, which has to name `sss`,
and then SSSD has to be running with a valid configuration. So: `sss` missing, SSSD not
running, a filter in `sssd.conf` that excludes the entry, or a search base that does not
contain it. `sssctl config-check` plus `systemctl status sssd` narrows four candidates
in two commands.

### 3. Clock skew too great

Kerberos rejects messages whose timestamps differ from the receiver's clock by more
than five minutes, because those timestamps are what stop a captured authenticator
being replayed. Check the clock on the client, the KDC, **and** the service, since any
pair can be the offending one. `System clock synchronized: no` from `timedatectl` is
the finding, and the fix is NTP rather than anything in `krb5.conf`.

### 4. Everything works until the cache expires

Change something in the directory, watch the machine ignore it for ninety minutes,
conclude the change did not save. `sssctl user-show` prints the expiration time and
`sss_cache -u <user>` marks the entry stale. The inverse trips people harder: an account
disabled centrally still works on the machines where it is cached, and with
`cache_credentials` on it works offline too. Offboarding is not complete when the
directory entry changes.

### 5. `ldaps://` on 636 versus StartTLS on 389

636 with implicit TLS was never standardised; StartTLS on 389 is the specified
mechanism. Both work in practice, and the trap is a client that *attempts* StartTLS and
silently continues in the clear when it fails. Make it mandatory, and check certificates
rather than setting `ldap_tls_reqcert = never`.

### 6. Assuming LDAP is doing the authentication

It may be, by bind, and that sends the password to the server. On an Active Directory or
FreeIPA deployment the password is checked by Kerberos and the directory is only
answering identity questions. Which one is in play decides whether your TLS
configuration is a serious matter or a merely important one, and it is written in
`sssd.conf` as `auth_provider`.

## Work it through

A new machine was joined to the domain this morning. `id jsmith` prints her uid, gid,
home directory, and shell correctly. `ssh jsmith@newhost` rejects the password. Her
password is definitely right, because she is logged in to an older server with it right
now. Reason it out before reading on.

**First, name which of the two questions is failing.** `id` works, so identity lookup is
fine: NSS is finding `sss`, SSSD is running, the search base is right, and the machine
can reach the directory. The whole left-hand side of the diagram is healthy and the
failure is on the right, which is a completely different set of causes.

**Second, ask what is answering the authentication question.**

```
grep -E 'id_provider|auth_provider' /etc/sssd/sssd.conf
```

If `auth_provider` is missing, SSSD uses the identity provider, which for
`id_provider = ldap` means a bind, so the client needs to reach port 389 or
636 and needs TLS configured. If it says `krb5` or the domain is `ad`,
Kerberos is answering and the causes are Kerberos causes.

**Third, test that path directly, as her:**

```
kinit jsmith@EXAMPLE.COM
klist
```

This is the sharpest test available, because it removes SSSD, PAM, and `sshd` from the
picture entirely. Three outcomes and three different lessons:

- **`Clock skew too great`**, the new machine's clock. `timedatectl` on it and
  on a working server. This is the classic new-machine failure, and virtual
  machines cloned from a template are especially prone to it.
- **`Preauthentication failed`**. The password really is wrong for this realm,
  or she is in a different realm than the one the machine defaults to.
- **`kinit` succeeds and `ssh` still fails**, Kerberos is fine and PAM is not
  wired up. On the RHEL family, `authselect current`; a profile without SSSD
  means the join wrote `sssd.conf` and nothing rewired PAM.

**Now change one detail.** Suppose `id jsmith` had *also* failed, on a machine where
`ldapsearch` against the same server returns her entry. Then nothing on either side is
reaching SSSD, and the candidates collapse to `nsswitch.conf` missing `sss` or the
daemon not running. Same symptom class, entirely different half of the system. **And one
more:** suppose everything works for her and fails for a colleague who has never logged
in to any machine. That is the cache, and it means the directory is unreachable and you
have been reading cached answers for everybody who used the host recently.

The point worth extracting: **identity and authentication fail separately, and the first
command should be the one that tells you which.** `id` answers the identity question
without touching authentication; `kinit` answers the authentication question without
touching NSS, PAM, or the service you were actually trying to use. Two commands, thirty
seconds, and the search space is halved before you have read a log file.

## Try it

Optional, and it needs no directory server of your own. A container is enough.

1. Start a container and install a directory: on Debian, `apt-get install slapd
   ldap-utils`, answering the prompts with a domain of `example.com`.
2. `ldapsearch -x -H ldap://localhost -s base -b "" namingContexts`. Confirm the base DN
   it reports matches the domain you gave.
3. `ldapsearch -x -H ldap://localhost -b dc=example,dc=com`. Read the objectClass lines
   and say which attribute each one is requiring.
4. Write an LDIF file with an `ou=people` container and one user carrying both
   `inetOrgPerson` and `posixAccount`, then load it with `ldapadd -x -D
   cn=admin,dc=example,dc=com -W -f yourfile.ldif`.
5. Find your user with a filter: `"(uid=yourname)"`, then
   `"(&(objectClass=posixAccount)(uidNumber>=10000))"`.
6. `ldapwhoami -x -H ldap://localhost` with no `-D`, then with `-D` and the admin DN.
   Then deliberately get the password wrong and read the result code.
7. `klist` on any machine. Read the message and say precisely what it is telling you
   about your Kerberos state.
8. On a machine with SSSD, `sssctl config-check`, then `getent passwd <a central user>`,
   then `sssctl user-show` that user and find the cache expiry.

**Verification step.** You have it when you can be handed a hostname and a
domain and say, without looking anything up, which command tells you the base
DN, which tells you whether the machine's identity lookups work, and which
tells you whether authentication works, and why those are three different
commands.

## Check yourself

<details class="qa">
<summary>A colleague says "we use LDAP for authentication". What are they probably describing, what is the more precise statement, and why does the distinction change anything?</summary>

**They are probably describing a deployment where LDAP answers identity
lookups and something else answers authentication**, most often Kerberos, if
there is an Active Directory or FreeIPA behind it. LDAP is a directory access
protocol whose normal job is to answer questions: this user's `uidNumber`,
`homeDirectory`, `loginShell`, which groups list them. It *can* authenticate,
using the bind operation, and plenty of small deployments do exactly that.

**The distinction changes your threat model and your configuration.** If authentication
is a bind, the user's password is transmitted to the directory server on every login, so
TLS is a requirement rather than a hardening measure, and the client needs a service
account to search for the user's DN before it can attempt the bind. If authentication is
Kerberos, the password never leaves the client, the directory server never sees it, and
a compromised application server cannot harvest passwords because it only ever receives
tickets.

The tempting wrong answer is that this is loose language and does not matter. It matters
in one place you will have to touch: `auth_provider` in `sssd.conf`.

The thing you will need next: `id_provider` and `auth_provider` are allowed to differ,
and commonly do. `id_provider = ldap` with `auth_provider = krb5` is a normal
configuration, and it is the diagram at the top of this topic written as two lines of a
file.

</details>

<details class="qa">
<summary>You are pointed at an LDAP server and told nothing else. Write the command that discovers where its data lives, and explain the two odd-looking arguments.</summary>

```
ldapsearch -x -H ldap://dc1.example.com -s base -b "" namingContexts
```

**`-b ""` is an empty base DN and `-s base` restricts the search to that one entry.**
Together they read the root DSE, the special entry every LDAP v3 server publishes about
itself. Its DN really is the empty string, which is why the base looks like a mistake.
`namingContexts` lists the base DNs this server holds data for; a server can publish
several, and one that publishes none is either not holding data or not letting you see
that it does.

**The tempting wrong move is to guess the base DN from the DNS name.** It is
often `dc=example,dc=com` for `example.com`, and it is often not, plenty of
directories use `o=Company` or a base with nothing to do with DNS, and
guessing produces `No such object (32)`, which reads like a permissions
problem and is not.

The thing you will need next: `supportedSASLMechanisms` comes from the same
entry and tells you whether GSSAPI is offered, which is how you learn that
this directory expects Kerberos rather than simple binds. And this query
normally works anonymously even where nothing else does, because clients must
discover the base DN before they can bind, so a failure here means unreachable
or wrong port, learned in one command rather than three.

</details>

<details class="qa">
<summary>Explain how Kerberos authenticates a user without the password crossing the network, and name the single environmental dependency that most often breaks it.</summary>

**The password is used as an encryption key on the client, and only the result is
transmitted.** `kinit` derives a key from the password locally, encrypts the current
timestamp with it, and sends that to the KDC as pre-authentication. The KDC holds the
same key, decrypts the timestamp, and concludes that the sender holds the key. It
returns a ticket-granting ticket and a session key, encrypted so only that key opens
them. The password is never in any message, and a service the user later reaches
receives only a service ticket, which it decrypts with its own key from its keytab.

**The dependency is time.** Every message carries a timestamp and the default
tolerance is five minutes. That is not an accident: the timestamp is what
prevents a captured authenticator being replayed, and a wide window would
weaken the protection. So a machine whose clock has drifted cannot
authenticate, and the error says so: `Clock skew too great while getting
initial credentials`. NTP is a hard dependency of Kerberos, not a tidiness
measure.

The tempting wrong answer is that the password is hashed and the hash is sent. That is a
different protocol and a much weaker one: a transmitted hash is itself a credential,
replayable by anybody who captures it.

The related error worth separating: `Preauthentication failed` is a wrong password, not
a clock problem. Both appear at `kinit` and they have nothing to do with each other.

</details>

<details class="qa">
<summary><code>ldapsearch</code> returns the user's entry with all its POSIX attributes, but <code>getent passwd</code> on the same machine returns nothing. Where is the fault, and what do you check?</summary>

**On this machine, between NSS and SSSD**, not in the directory, the network,
or the credentials, all of which the successful `ldapsearch` has already
proved. `ldapsearch` talks to the server directly; `getent` goes through the
name service switch in glibc, which consults `/etc/nsswitch.conf` and calls
whatever modules the `passwd` line names. So:

- **`sss` is missing from the `passwd` and `group` lines.** On SUSE, note that the file
  may not exist in `/etc` at all, with the distribution default in
  `/usr/etc/nsswitch.conf`.
- **SSSD is not running**, or failed to start because of its configuration.
  `systemctl status sssd` and `sssctl config-check`.
- **The search base or a filter in `sssd.conf` excludes the entry**, which is the subtle
  one: `ldap_search_base` pointing one level too deep finds nothing and reports nothing.

The tempting wrong move is to go back to the directory and search again with different
filters. The directory has already answered; repeating the question that worked cannot
tell you anything about the question that did not.

The thing you will need next: once `getent passwd` works, `getent group` may still not,
because group membership is a separate set of entries with a separate objectClass. A
user who logs in successfully and then cannot read a group-owned directory is this, not
a permissions problem.

</details>

<details class="qa">
<summary>Central identity is deployed and the directory server goes down for three hours. Who can still log in, who cannot, and what determines the answer?</summary>

**Users who have logged in to that specific machine before, if `cache_credentials` is
enabled, for as long as `offline_credentials_expiration` allows.** Everybody else is
locked out of that machine. Two separate caches decide it. The identity cache holds
`uidNumber`, `homeDirectory`, group membership and so on, with a default lifetime of
5400 seconds. The credential cache holds a hash of a successful authentication, and only
exists if `cache_credentials = true`, which is not the default.

**The determining factor is per machine, not per user.** A cache is local, so an
administrator who has used server A all week gets in during the outage and concludes the
estate is fine, while the same person cannot reach server B, last touched in March. That
asymmetry is why such an outage gets reported as intermittent when it is nothing of the
sort.

The tempting wrong answer is that root can always get in and therefore it does
not matter. Root can, because `files` comes before `sss` on the `passwd` line,
and that is exactly why the local root password must be known and stored
somewhere retrievable. An estate with central identity and no working local
break-glass account is one directory outage away from having no administrative
access at all.

The thing you will need next: cached credentials cut the other way at offboarding. A
disabled directory account still logs in to every machine holding its cached credentials
until they expire, so revocation is not complete when the directory entry changes.
`sss_cache -u <user>` on the machines that matter, or a short
`offline_credentials_expiration`, is the part of the runbook people leave out.

</details>

## References

- [RFC 4511: Lightweight Directory Access Protocol (LDAP): The Protocol](https://www.rfc-editor.org/rfc/rfc4511.html) - IETF. Accessed 2026-08-08.
- [RFC 4120: The Kerberos Network Authentication Service (V5)](https://www.rfc-editor.org/rfc/rfc4120.html) - IETF. Accessed 2026-08-08.
- [ldapsearch(1)](https://manpages.debian.org/trixie/ldap-utils/ldapsearch.1.en.html) - Debian. Accessed 2026-08-08.
- [nsswitch.conf(5)](https://man7.org/linux/man-pages/man5/nsswitch.conf.5.html) - Linux man-pages project. Accessed 2026-08-08.
- [sssd.conf(5)](https://manpages.debian.org/trixie/sssd-common/sssd.conf.5.en.html) - Debian. Accessed 2026-08-08.
- [realm(8)](https://manpages.debian.org/trixie/realmd/realm.8.en.html) - Debian. Accessed 2026-08-08.
- [krb5.conf(5)](https://web.mit.edu/kerberos/krb5-latest/doc/admin/conf_files/krb5_conf.html) - MIT Kerberos. Accessed 2026-08-08.
- [smb.conf(5)](https://www.samba.org/samba/docs/current/man-html/smb.conf.5.html) - Samba Team. Accessed 2026-08-08.

Captured output came from two containers. The LDAP transcripts are a real OpenLDAP
server installed in a Debian 13 container, with the directory built by the LDIF shown in
the topic. The SSSD and Kerberos transcripts came from an openSUSE Leap 16 container
running its own directory with SSSD pointed at it, which is why `klist` reports no
credential cache: there is no KDC in these captures, and the Kerberos exchange itself is
described from RFC 4120 and the MIT documentation rather than shown. Blocks without a
distribution and architecture header are illustrative or quoted from documentation.
