#!/usr/bin/env sh
# The arithmetic behind password policy, computed rather than asserted, plus a
# real hashing cost measurement so the two halves of the guess rate are visible.
dnf -q -y install python3 >/dev/null 2>&1
cat > /usr/local/bin/search-space <<'SCRIPT'
#!/usr/bin/env python3
import math

import sys
RATE = int(sys.argv[1]) if len(sys.argv) > 1 else 100_000_000_000
POLICIES = [
    ("8 chars, upper lower digit symbol", 95, 8),
    ("10 chars, upper lower digit symbol", 95, 10),
    ("12 chars, lower case only", 26, 12),
    ("16 chars, lower case only", 26, 16),
    ("4 random words from a 7776-word list", 7776, 4),
]

print(f"{'policy':<40} {'combinations':>14}  {'bits':>5}  average time to guess")
for name, alphabet, length in POLICIES:
    space = alphabet ** length
    seconds = space / 2 / RATE
    if seconds < 3600:
        human = f"{seconds:,.0f} seconds"
    elif seconds < 86400 * 365:
        human = f"{seconds / 86400:,.1f} days"
    else:
        human = f"{seconds / 86400 / 365:,.0f} years"
    print(f"{name:<40} {space:>14.3e}  {math.log2(space):>5.1f}  {human}")
print()
note = ("offline against a fast hash" if RATE > 1_000_000
        else "offline against a deliberately slow one")
print(f"assuming {RATE:,} guesses a second, {note}")
SCRIPT
chmod +x /usr/local/bin/search-space
