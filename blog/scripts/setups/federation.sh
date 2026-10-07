#!/usr/bin/env sh
# A signed token built locally, so a topic can take one apart without needing a
# real user's identity token. The claims are the ones an identity provider
# publishes that it can assert; the signature is over this key, not anybody's.
dnf -q -y install python3 python3-pip openssl jq >/dev/null 2>&1
openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -out /srv/idp.key 2>/dev/null
cat > /usr/local/bin/make-token <<'SCRIPT'
#!/usr/bin/env python3
import base64
import json
import subprocess

def b64(raw):
    return base64.urlsafe_b64encode(raw).rstrip(b"=").decode()

header = {"alg": "RS256", "typ": "JWT", "kid": "2026-08-a"}
payload = {
    "iss": "https://idp.example.internal",
    "sub": "8f14e45fceea167a",
    "aud": "expenses-app",
    "exp": 1787000000,
    "iat": 1786996400,
    "email": "sam@example.internal",
    "email_verified": True,
    "groups": ["finance", "expenses-approver"],
}
signing_input = f"{b64(json.dumps(header).encode())}.{b64(json.dumps(payload).encode())}"
sig = subprocess.run(["openssl", "dgst", "-sha256", "-sign", "/srv/idp.key"],
                     input=signing_input.encode(), capture_output=True).stdout
print(f"{signing_input}.{b64(sig)}")
SCRIPT
cat > /usr/local/bin/read-token <<'SCRIPT'
#!/usr/bin/env python3
import base64
import json
import sys

token = sys.stdin.read().strip()
parts = token.split(".")
print(f"the token is {len(token)} characters in {len(parts)} dot-separated parts")
for name, part in zip(("header", "payload"), parts[:2]):
    raw = base64.urlsafe_b64decode(part + "=" * (-len(part) % 4))
    print(f"{name}:")
    for k, v in json.loads(raw).items():
        print(f"    {k}: {v}")
print(f"signature: {len(parts[2])} characters, and it is the only part that is not readable")
SCRIPT
chmod +x /usr/local/bin/make-token /usr/local/bin/read-token
