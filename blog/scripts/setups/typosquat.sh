#!/usr/bin/env sh
# Generate the near-misses of a domain name and ask public DNS which of them
# exist. Nothing is contacted except a resolver, and a resolver answering is not
# a probe of anybody's host.
dnf -q -y install bind-utils python3 >/dev/null 2>&1
cat > /usr/local/bin/nearmiss <<'SCRIPT'
#!/usr/bin/env python3
import subprocess
import sys

name = sys.argv[1]
label, _, tld = name.partition(".")
KEYS = {"a": "sq", "e": "wr", "i": "ou", "o": "ip", "u": "yi",
        "l": "k", "m": "n", "n": "m", "r": "et", "s": "ad", "t": "ry", "c": "xv"}

variants = set()
for i, ch in enumerate(label):                       # one character swapped
    for alt in KEYS.get(ch, ""):
        variants.add(label[:i] + alt + label[i + 1:] + "." + tld)
for i in range(len(label) - 1):                       # two characters transposed
    variants.add(label[:i] + label[i + 1] + label[i] + label[i + 2:] + "." + tld)
for i, ch in enumerate(label):                        # one character doubled
    variants.add(label[:i] + ch + ch + label[i:] + "." + tld)

variants.discard(name)   # transposing a doubled letter reproduces the original
found = []
for v in sorted(variants):
    out = subprocess.run(["dig", "+short", "+time=2", "+tries=1", v, "A"],
                         capture_output=True, text=True).stdout.strip()
    if out:
        found.append(v)
print(f"{len(variants)} near-misses generated for {name}")
print(f"{len(found)} of them resolve to an address today")
for v in found[:8]:
    print(f"  {v}")
SCRIPT
chmod +x /usr/local/bin/nearmiss
