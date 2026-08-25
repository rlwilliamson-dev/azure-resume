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

# A copy with one byte changed, to see what the signature is actually over
cp /bin/ls /tmp/tampered-ls; printf '\x00' | dd of=/tmp/tampered-ls bs=1 seek=40000 conv=notrunc 2>/dev/null; codesign --verify --verbose=2 /tmp/tampered-ls 2>&1 | head -3

# Whether the system would let it run, which is a separate question from whether it is signed
spctl --assess --type execute --verbose=2 /bin/ls 2>&1; spctl --assess --type execute --verbose=2 /tmp/tampered-ls 2>&1 | head -2
