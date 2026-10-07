#!/usr/bin/env sh
# Three measurements for the application and cryptographic attacks topic.
#
# None of them runs an attack. `where-does-it-land` resolves request paths and
# prints where each one points, which is the filesystem answering a question
# about its own naming rules. `negotiate` connects to a TLS server on the
# loopback address twice with different client constraints and reports what each
# handshake agreed on. `birthday` searches for collisions in truncated SHA-256
# and counts the attempts, which measures the square-root bound rather than
# asserting it.
dnf -q -y install python3 openssl >/dev/null 2>&1

mkdir -p /srv/www/images
: > /srv/www/logo.png
ln -sfn /etc /srv/www/backup

openssl req -x509 -newkey rsa:2048 -nodes -days 30 \
  -subj '/CN=localhost' -keyout /etc/pki/tls/private/lab.key \
  -out /etc/pki/tls/certs/lab.crt >/dev/null 2>&1

cat > /usr/local/bin/where-does-it-land <<'SCRIPT'
#!/usr/bin/env python3
# Take the path out of a request, resolve it the way the operating system
# would, and print where it points. Nothing is opened or served.
import os
import urllib.parse

ROOT = "/srv/www"
REQUESTS = [
    "/logo.png",
    "/../../etc/passwd",
    "/%2e%2e/%2e%2e/etc/passwd",
    "/backup/passwd",
]

print(f"document root: {ROOT}")
print(f"{'request path':<28} {'.. in raw':<10} {'resolves to':<22} inside")
for request in REQUESTS:
    raw_dots = "yes" if ".." in request else "no"
    decoded = urllib.parse.unquote(request)
    landing = os.path.realpath(ROOT + decoded)
    inside = "yes" if landing.startswith(ROOT + os.sep) else "no"
    print(f"{request:<28} {raw_dots:<10} {landing:<22} {inside}")
SCRIPT
chmod +x /usr/local/bin/where-does-it-land

cat > /usr/local/bin/negotiate <<'SCRIPT'
#!/usr/bin/env sh
# One server, one key, three clients. The server is told what it is willing to
# accept and never changes. Each client is told what it is willing to offer.
# Print what each handshake settled on, and ask openssl what the agreed suite
# uses for key exchange rather than asserting it.
SUITES='ECDHE-RSA-AES256-GCM-SHA384:AES128-SHA256'
openssl s_server -quiet -accept 4433 -naccept 3 \
  -cert /etc/pki/tls/certs/lab.crt -key /etc/pki/tls/private/lab.key \
  -cipher "$SUITES@SECLEVEL=0" -ciphersuites TLS_AES_256_GCM_SHA384 \
  >/dev/null 2>&1 &
server=$!
sleep 1

report() {
  label=$1
  shift
  new=$(printf 'x' | openssl s_client -connect 127.0.0.1:4433 \
    -CAfile /etc/pki/tls/certs/lab.crt "$@" 2>/dev/null |
    sed -n 's/^New, \(.*\), Cipher is \(.*\)$/\1 \2/p' | head -1)
  proto=${new%% *}
  suite=${new#* }
  kx=$(openssl ciphers -v 'ALL:COMPLEMENTOFALL:@SECLEVEL=0' 2>/dev/null |
    awk -v want="$suite" '$1 == want { for (i = 1; i <= NF; i++)
      if ($i ~ /^Kx=/) { sub(/Kx=/, "", $i); print $i; exit } }')
  printf '%-24s %-9s %-28s %s\n' "$label" "$proto" "$suite" "$kx"
}

echo "server accepts: $SUITES"
echo "                plus TLS_AES_256_GCM_SHA384"
echo
printf '%-24s %-9s %-28s %s\n' "client offered" "agreed" "agreed cipher" "key exchange"
report "everything"
report "1.2, full list" -tls1_2
report "1.2, AES128-SHA256" -tls1_2 -cipher 'AES128-SHA256@SECLEVEL=0'
wait $server 2>/dev/null
SCRIPT
chmod +x /usr/local/bin/negotiate

cat > /usr/local/bin/birthday <<'SCRIPT'
#!/usr/bin/env python3
# Search for two inputs whose SHA-256 digests agree in the first n bits, and
# count how many digests it took. Repeated so the number is an average rather
# than one lucky run.
import hashlib

TRIALS = 8


def first_collision(bits, salt):
    seen = set()
    tried = 0
    while True:
        digest = hashlib.sha256(f"{salt}:{tried}".encode()).digest()
        value = int.from_bytes(digest, "big") >> (256 - bits)
        tried += 1
        if value in seen:
            return tried
        seen.add(value)


print(f"{'digest bits':>11} {'digests tried':>14} {'2^(n/2)':>10} {'2^n':>14}")
for bits in (16, 24, 32, 40):
    trials = TRIALS if bits < 40 else 4
    mean = sum(first_collision(bits, s) for s in range(trials)) // trials
    print(f"{bits:>11} {mean:>14,} {2 ** (bits // 2):>10,} {2 ** bits:>14,}")
SCRIPT
chmod +x /usr/local/bin/birthday
