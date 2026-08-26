# Whether this machine can tell you its own files are unmodified.
#
# One command per line, same shape as a netlab steps file.
#
# Linux asks the package database. macOS answers with a cryptographic seal over
# the whole system volume rather than a per-file record, which is a stronger
# guarantee about the files it covers and says nothing about anything else.

# The seal over the system volume, which is the answer for everything Apple shipped
csrutil authenticated-root status 2>&1; diskutil apfs list 2>/dev/null | grep -m1 -i "sealed\|Snapshot"

# Whether one system binary still verifies, which is per-file and per-signature
codesign --verify --verbose=2 /bin/sh 2>&1 | head -2

# A hash of the same file, for comparison with the Linux and Windows columns
shasum -a 256 /bin/sh | awk '{print toupper($1)}'

# Whether anything on the machine is watching for changes to files you own
sudo fs_usage -w -f filesys 2>/dev/null | head -2 & sleep 2; kill %1 2>/dev/null; echo "fs_usage streams events live and stores none of them"
