#!/usr/bin/env sh
# Three measurements for the password attacks topic.
#
# `lockout` drives PAM directly against throwaway local accounts in this
# container to show how a failure counter is kept. `hashrate` times how many
# candidate passwords one CPU can test per second against several storage
# choices. `exhaust` turns that measured rate into a time for each of several
# password shapes. No remote system is involved and no password list is used.
dnf -q -y install epel-release >/dev/null 2>&1
dnf -q -y install pam pamtester python3 openssl >/dev/null 2>&1

for u in alice bob carol dave erin frank; do
  useradd -m "$u" 2>/dev/null
  echo "$u:correct-horse-$u" | chpasswd
done

cat > /etc/security/faillock.conf <<'CONF'
deny = 3
unlock_time = 600
CONF

cat > /etc/pam.d/lockdemo <<'PAMCONF'
auth     required                 pam_faillock.so preauth
auth     [success=1 default=bad]  pam_unix.so
auth     [default=die]            pam_faillock.so authfail
auth     sufficient               pam_faillock.so authsucc
auth     required                 pam_deny.so
account  required                 pam_unix.so
PAMCONF

cat > /usr/local/bin/lockout <<'SCRIPT'
#!/usr/bin/env sh
# The policy is three failures then a lock. Ask PAM what happens when the
# failures land on one account, and what happens when the same number of
# failures is spread across six. The last column is the answer to the only
# question that matters: after all this, does the right password still work?
PATH="$PATH:/usr/sbin"
wrong() { printf 'wrong\n' | pamtester lockdemo "$1" authenticate >/dev/null 2>&1 && echo ok || echo denied; }
right() { printf 'correct-horse-%s\n' "$1" | pamtester lockdemo "$1" authenticate >/dev/null 2>&1 && echo yes || echo no; }
failures() { faillock --user "$1" | tail -n +3 | grep -c . ; }

echo "policy: deny = 3, unlock_time = 600"
echo
echo "six wrong passwords, all aimed at one account"
for n in 1 2 3 4 5 6; do
  r=$(wrong alice)
  printf '  attempt %s  %-7s  failures on record: %s\n' "$n" "$r" "$(failures alice)"
done
printf '  right password now accepted for alice: %s\n' "$(right alice)"
echo
echo "six wrong passwords, one aimed at each of six accounts"
for u in bob carol dave erin frank; do wrong "$u" >/dev/null; done
wrong alice >/dev/null
printf '  %-8s %-20s %s\n' "account" "failures on record" "right password accepted"
for u in bob carol dave erin frank; do
  printf '  %-8s %-20s %s\n' "$u" "$(failures "$u")" "$(right "$u")"
done
SCRIPT
chmod +x /usr/local/bin/lockout

cat > /usr/local/bin/hashrate <<'SCRIPT'
#!/usr/bin/env sh
# How many candidate passwords one core of this container can test per second
# against each way of storing a password.
#
# The raw digest row comes from `openssl speed`, because timing a raw SHA-256
# from Python would measure Python's call overhead rather than the digest. The
# stretched rows are timed from Python, where one call takes milliseconds and
# the interpreter's overhead disappears into the noise. Each number is
# therefore a measurement of the thing named rather than of the harness.
raw=$(openssl speed -seconds 2 sha256 2>&1 |
  awk '/^sha256 / { v = $2; sub(/k$/, "", v); printf "%d", v * 1000 / 16 }')
python3 - "$raw" <<'PYEND'
import hashlib
import sys
import time

SALT = b"a fixed salt so the work is comparable"
CANDIDATE = b"candidate"
raw = int(sys.argv[1])


def rate(fn, budget=2.0):
    n = 0
    start = time.perf_counter()
    while time.perf_counter() - start < budget:
        fn()
        n += 1
    return n / (time.perf_counter() - start)


rows = [
    ("SHA-256, raw", raw),
    ("PBKDF2-SHA256, 10k rounds",
     rate(lambda: hashlib.pbkdf2_hmac("sha256", CANDIDATE, SALT, 10_000))),
    ("PBKDF2-SHA256, 600k rounds",
     rate(lambda: hashlib.pbkdf2_hmac("sha256", CANDIDATE, SALT, 600_000))),
    ("scrypt, n=16384 r=8 p=1",
     rate(lambda: hashlib.scrypt(CANDIDATE, salt=SALT, n=16384, r=8, p=1))),
]

print("one core of this container, timed now")
print()
print(f"{'how the password is stored':<28} {'guesses per second':>19} {'costs the attacker':>19}")
for label, r in rows:
    print(f"{label:<28} {round(r):>19,} {raw / r:>18,.0f}x")
PYEND
SCRIPT
chmod +x /usr/local/bin/hashrate

cat > /usr/local/bin/exhaust <<'SCRIPT'
#!/usr/bin/env sh
# Turn the two extreme rates from `hashrate` into a time to search half of each
# password space, which is what an exhaustive search takes on average.
raw=$(openssl speed -seconds 2 sha256 2>&1 |
  awk '/^sha256 / { v = $2; sub(/k$/, "", v); printf "%d", v * 1000 / 16 }')
python3 - "$raw" <<'PYEND'
import hashlib
import math
import sys
import time

SALT = b"a fixed salt so the work is comparable"
CANDIDATE = b"candidate"
fast = int(sys.argv[1])

n = 0
start = time.perf_counter()
while time.perf_counter() - start < 2.0:
    hashlib.pbkdf2_hmac("sha256", CANDIDATE, SALT, 600_000)
    n += 1
slow = n / (time.perf_counter() - start)

SHAPES = [
    ("8 chars, all four classes", 8 * math.log2(95)),
    ("10 chars, all four classes", 10 * math.log2(95)),
    ("12 chars, lower case only", 12 * math.log2(26)),
    ("16 chars, lower case only", 16 * math.log2(26)),
    ("4 words from a 7776 list", 4 * math.log2(7776)),
    ("6 words from a 7776 list", 6 * math.log2(7776)),
]


def duration(seconds):
    for unit, size in (("seconds", 1), ("hours", 3600), ("days", 86400)):
        if seconds < size * 1000:
            return f"{seconds / size:,.0f} {unit}"
    years = seconds / 31_557_600
    return f"{years:,.0f} years" if years < 1e6 else f"{years:.1g} years"


print(f"measured here: {fast:,}/s raw SHA-256, {slow:,.0f}/s PBKDF2 at 600k rounds")
print()
print(f"{'password shape':<27} {'bits':>5} {'raw digest':>16} {'stretched':>18}")
for label, bits in SHAPES:
    work = 2 ** (bits - 1)
    print(f"{label:<27} {bits:>5.1f} {duration(work / fast):>16} {duration(work / slow):>18}")
PYEND
SCRIPT
chmod +x /usr/local/bin/exhaust
