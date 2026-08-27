# Whether this machine restricts which programs may run, and by what mechanism.
#
# One command per line, same shape as a netlab steps file.
#
# An application allow list is the strictest form of least privilege on a host:
# nothing runs unless it is named. macOS approaches the same goal from the other
# direction, by assessing signatures and origin rather than by holding a list of
# permitted paths, so the questions and the answers both look different.

# Whether the platform's own assessment of executables is switched on
spctl --status 2>&1

# What that assessment says about a binary the operating system shipped
spctl --assess --type execute -vv /usr/bin/true 2>&1 | head -4

# What it says about an unsigned file this session just created
f=$(mktemp)/x 2>/dev/null; d=$(mktemp -d); f="$d/nothing.sh"; printf '#!/bin/sh\nexit 0\n' > "$f"; chmod +x "$f"; spctl --assess --type execute -vv "$f" 2>&1 | head -3; "$f"; echo "exit code $?"

# Whether the kernel is enforcing signature and filesystem protections underneath all of that
csrutil status 2>&1
