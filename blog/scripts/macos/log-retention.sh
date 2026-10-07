# How much of its own record this machine keeps, and whether erasing it leaves a mark.
#
# One command per line, same shape as a netlab steps file.
#
# Missing logs is one of the nine indicators, and it is the only one whose
# innocent explanation is usually retention rather than an attacker. macOS keeps
# a single unified log in a binary store rather than a set of text files, so the
# retention question is answered by looking at the store.

# How large the persisted log store is, which is what bounds how far back it reaches
sudo du -sh /var/db/diagnostics 2>/dev/null

# The newest and oldest persisted chunks, which bracket the window this machine can answer for
ls -lt /var/db/diagnostics/Persist 2>/dev/null | sed -n '2p'; ls -ltr /var/db/diagnostics/Persist 2>/dev/null | sed -n '2p'

# What the logging system is configured to keep and at what level
sudo log config --status 2>&1 | head -3

# Whether a separate login record exists here as well, and how far it goes back
last | tail -3
