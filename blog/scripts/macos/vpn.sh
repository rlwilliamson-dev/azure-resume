# What a VPN looks like on a Mac before anybody connects one.
#
# One command per line, same shape as a netlab steps file.
#
# Topic 50 is about where a tunnel terminates and what it carries. On the client
# the visible part is an interface that appears from nowhere and a routing table
# that changes, and macOS names its tunnel interfaces distinctively enough that
# they are worth recognising.

# Configured connections, if any
scutil --nc list 2>&1 | head -4

# The tunnel interfaces macOS creates, which exist whether or not you configured them
ifconfig | grep -E "^utun" | head -5
