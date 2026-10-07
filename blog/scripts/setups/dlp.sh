#!/usr/bin/env sh
# A document containing things that look like card numbers, and a detector that
# does what data loss prevention actually does: match a shape, then check it.
#
# The numbers are the published test values every payment processor documents
# for exactly this purpose. None of them belongs to anybody.
dnf -q -y install python3 >/dev/null 2>&1
mkdir -p /srv/docs
cat > /srv/docs/notes.txt <<'DOC'
Meeting notes, 14 March
Test card for the sandbox: 4111 1111 1111 1111
Our support line is 0800 4111 1111 1111 2222
Reference number 1234 5678 9012 3456 on the invoice
Employee id 4111111111111112
DOC
cat > /usr/local/bin/dlp-scan <<'SCRIPT'
#!/usr/bin/env python3
import re
import sys

def luhn(number):
    digits = [int(d) for d in number][::-1]
    total = 0
    for i, d in enumerate(digits):
        if i % 2:
            d *= 2
            if d > 9:
                d -= 9
        total += d
    return total % 10 == 0

text = open(sys.argv[1]).read()
candidates = re.findall(r"\b(?:\d[ -]?){13,19}\b", text)
print(f"{len(candidates)} strings match the shape of a card number")
for c in candidates:
    digits = re.sub(r"\D", "", c)
    verdict = "passes the checksum" if luhn(digits) else "fails the checksum"
    print(f"  {c.strip():<26} {len(digits)} digits, {verdict}")
SCRIPT
chmod +x /usr/local/bin/dlp-scan
