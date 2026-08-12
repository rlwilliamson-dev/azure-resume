# Where a Mac keeps its resolver settings, its cache and its hosts file.
#
# One command per line, same shape as a netlab steps file.
#
# Topic 44 traces a name from the root down. The other half of the question is
# what the machine in front of you does before any of that happens: which
# resolver it asks, what it already knows, and which file it checks first.

# The resolver configuration, which on macOS is not /etc/resolv.conf
scutil --dns | grep -E "resolver #1|nameserver|search domain" | head -6

# The file consulted before any of that, and the entries it always carries
grep -vE "^#|^$" /etc/hosts | head -5

# Resolving a name through the system rather than by talking to a server
dscacheutil -q host -a name example.com
