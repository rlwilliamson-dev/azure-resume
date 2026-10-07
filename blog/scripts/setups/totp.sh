#!/usr/bin/env sh
# A time-based one-time password implementation, so a topic can show the codes a
# token produces rather than describing them. The secret below is the test value
# published in RFC 6238 for exactly this purpose and belongs to nobody.
dnf -q -y install python3 >/dev/null 2>&1
cat > /usr/local/bin/totp <<'SCRIPT'
#!/usr/bin/env python3
import hashlib
import hmac
import struct
import sys

SECRET = b"12345678901234567890"   # RFC 6238 test secret, ASCII
STEP = 30


def code(counter):
    digest = hmac.new(SECRET, struct.pack(">Q", counter), hashlib.sha1).digest()
    offset = digest[-1] & 0x0F
    value = struct.unpack(">I", digest[offset:offset + 4])[0] & 0x7FFFFFFF
    return f"{value % 10 ** 6:06d}"


base = int(sys.argv[1])
print(f"secret: the 20-byte RFC 6238 test value, shared by the token and the server")
print(f"step:   {STEP} seconds")
print()
print(f"{'unix time':>12}  {'counter':>10}  code")
for offset in (-60, -30, 0, 30, 60):
    t = base + offset
    counter = t // STEP
    marker = "  <- now" if offset == 0 else ""
    print(f"{t:>12}  {counter:>10}  {code(counter)}{marker}")
SCRIPT
chmod +x /usr/local/bin/totp
# The same implementation checked against the vectors printed in RFC 6238, so a
# reader does not have to take the codes above on trust.
cat > /usr/local/bin/totp-check <<'SCRIPT'
#!/usr/bin/env python3
import hashlib
import hmac
import struct

SECRET = b"12345678901234567890"
VECTORS = [(59, "94287082"), (1111111109, "07081804"), (1111111111, "14050471"),
           (1234567890, "89005924"), (2000000000, "69279037")]


def code(counter, digits=8):
    digest = hmac.new(SECRET, struct.pack(">Q", counter), hashlib.sha1).digest()
    offset = digest[-1] & 0x0F
    value = struct.unpack(">I", digest[offset:offset + 4])[0] & 0x7FFFFFFF
    return str(value % 10 ** digits).zfill(digits)


print(f"{'time':>12}  {'published':>10}  {'computed':>10}  match")
for t, expected in VECTORS:
    got = code(t // 30)
    print(f"{t:>12}  {expected:>10}  {got:>10}  {got == expected}")
SCRIPT
chmod +x /usr/local/bin/totp-check
