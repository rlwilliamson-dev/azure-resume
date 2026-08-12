# Capturing packets on a Mac, which needs nothing installed.
#
# One command per line, same shape as a netlab steps file.
#
# Topic 39 runs tcpdump on a Linux collector. macOS ships the same program, and
# adds a pseudo-device of its own that captures across every interface at once
# and carries the name of the process that sent each packet, which is metadata
# the kernel supplies and no wire capture can.

# The same program, from the same project
tcpdump --version 2>&1 | head -2

# The interfaces it can be pointed at
sudo tcpdump -D | head -3

# And the one that is not an interface, straight out of the shipped manual
man tcpdump 2>/dev/null | col -b | grep -i -m3 "pktap"
