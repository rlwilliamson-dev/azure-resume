# What a Mac does with router advertisements, and what it does about privacy.
#
# One command per line, same shape as a netlab steps file.
#
# Topic 08 covers what addresses a machine holds. This is the other question:
# what has this host learned from advertisements, and what interface identifier
# does it choose. Temporary addresses are on by default here, which is not true
# everywhere, and the setting is readable rather than a matter of belief.

# Prefixes learned from advertisements, and the routers that sent them
ndp -p 2>&1 | head -6

ndp -r 2>&1 | head -4

# Whether this machine generates temporary addresses at all
sysctl net.inet6.ip6.use_tempaddr net.inet6.ip6.temppltime net.inet6.ip6.tempvltime

# The interface identifier scheme in use, which the secured flag names
ifconfig en0 inet6 | head -4
