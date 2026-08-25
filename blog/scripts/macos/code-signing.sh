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

# A copy with one byte changed near the front, inside the first slice
cp /bin/ls /tmp/tampered-early; printf '\x00' | dd of=/tmp/tampered-early bs=1 seek=40000 conv=notrunc 2>/dev/null; codesign --verify --verbose=2 /tmp/tampered-early 2>&1 | head -2

# The same change three fifths of the way through, inside the slice this machine runs
cp /bin/ls /tmp/tampered-late; printf '\x00' | dd of=/tmp/tampered-late bs=1 seek=$(( $(stat -f%z /bin/ls) * 3 / 5 )) conv=notrunc 2>/dev/null; codesign --verify --verbose=2 /tmp/tampered-late 2>&1 | head -2

# Whether the system would let it run, which is a separate question from whether it is signed
spctl --assess --type execute --verbose=2 /bin/ls 2>&1; spctl --assess --type execute --verbose=2 /tmp/tampered-late 2>&1 | head -2
