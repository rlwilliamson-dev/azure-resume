# Whether this machine can tell you its configuration has drifted, and put it back.
#
# One command per line, same shape as a netlab steps file.
#
# Detecting drift and correcting it are separate capabilities and most systems
# have the first without the second. macOS has no local comparison tool at all:
# the answer to both questions is a configuration profile, which arrives from
# management and is reapplied by it, so an unmanaged Mac has neither half.

# Whether any declarative configuration is installed that would be reapplied
out=$(sudo profiles list -all 2>&1); printf '%s\n' "${out:-nothing returned}" | head -4

# Whether this machine is enrolled in management at all, which is what would push one
profiles status -type enrollment 2>&1

# Whether the managed preference store holds anything, which is where a profile's settings land
out=$(sudo ls -1 "/Library/Managed Preferences" 2>&1); printf '%s\n' "${out:-nothing in the managed preference store}" | head -4

# What one setting reads as locally, with nothing managing it
defaults read /Library/Preferences/com.apple.SoftwareUpdate 2>&1 | head -5
