# What a code signature proves on macOS, and what it does not.
#
# One command per line, same shape as a netlab steps file.
#
# Linux verifies a package signature and Windows verifies one embedded in the
# executable. macOS does the second and adds a separate question on top of it,
# which is whether the system is willing to run the thing at all.

# A system binary, and what its signature says
codesign -dv --verbose=2 /bin/ls 2>&1 | grep -E "Identifier|Authority|TeamIdentifier|Signature|Format"

# Verification rather than description, which is the check that can fail
codesign --verify --verbose=2 /bin/ls 2>&1

# The binary holds more than one architecture, so where a change lands matters
lipo -archs /bin/ls; stat -f '%z bytes' /bin/ls

# A copy with one byte inverted rather than overwritten, so the change is certain
cp /bin/ls /tmp/tampered-ls; python3 -c "
import sys
p='/tmp/tampered-ls'
b=bytearray(open(p,'rb').read())
off=len(b)*3//5
b[off]^=0xFF
open(p,'wb').write(b)
print('flipped byte at offset', off)
"; cmp -l /bin/ls /tmp/tampered-ls | wc -l | tr -d ' '

# What the signature says about it now
codesign --verify --verbose=2 /tmp/tampered-ls 2>&1 | head -3

# Whether the system would let it run, which is a separate question from whether it is signed
spctl --assess --type execute --verbose=2 /bin/ls 2>&1; spctl --assess --type execute --verbose=2 /tmp/tampered-ls 2>&1 | head -2
