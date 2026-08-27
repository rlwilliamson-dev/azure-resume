# How this machine enforces policy on itself, and how much of it there is.
#
# One command per line, same shape as a netlab steps file.
#
# The Linux column asks SELinux for a mode and a policy. macOS has two separate
# mandatory layers with different jobs: one protects the system from root, and
# one gates access to user data per application.

# The layer that constrains root itself, which has no Linux equivalent enabled by default
csrutil status 2>&1

# Whether the boot chain is verified, which is the other half of the same idea
csrutil authenticated-root status 2>&1; sudo nvram -p 2>/dev/null | grep -c boot-args

# The per-application consent database, which is the layer users actually meet
sudo ls -l /Library/Application\ Support/com.apple.TCC/TCC.db 2>&1 | head -2

# Which secure and insecure protocol pairs this machine currently offers
sudo lsof -nP -iTCP -sTCP:LISTEN 2>/dev/null | awk '{print $9}' | grep -oE ':[0-9]+$' | tr -d ':' | sort -n -u | tr '\n' ' '; echo
