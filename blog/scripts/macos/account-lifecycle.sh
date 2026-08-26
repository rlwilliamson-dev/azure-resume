# What an account carries, and what disabling it actually changes.
#
# One command per line, same shape as a netlab steps file.
#
# The Linux column reads /etc/shadow through passwd -S. macOS keeps accounts in
# a directory service rather than in a file, so the same questions go through
# dscl and the answers are structured differently.

# The account this runner uses, and where its record actually lives
dscl . -read /Users/$(whoami) RecordName UniqueID PrimaryGroupID 2>/dev/null | head -6

# What it can reach, which is a separate query from the account record
id -Gn; echo "---"; dsmemberutil checkmembership -U "$(whoami)" -G admin 2>/dev/null

# Whether the password has an expiry policy attached to it at all
pwpolicy -u "$(whoami)" -getpolicy 2>&1 | head -2

# The equivalent of a lock, asked rather than performed on a machine somebody else owns
dscl . -read /Users/$(whoami) AuthenticationAuthority 2>/dev/null | tr ' ' '\n' | grep -c . 
