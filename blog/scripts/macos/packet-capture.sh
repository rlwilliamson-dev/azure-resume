# Capturing packets on a Mac, which needs nothing installed.
#
# One command per line, same shape as a netlab steps file.
#
# Topic 39 runs tcpdump on a Linux collector. macOS ships the same program, plus
# two interfaces that do not exist on Linux: pktap and iptap, pseudo-devices
# that capture across every interface at once. tcpdump(1) on macOS documents the
# -k flag for printing the process that sent each packet, which is metadata the
# kernel adds and no wire capture can supply.

# The same program, from the same project
tcpdump --version 2>&1 | head -2

# What it can capture on. The last two are the macOS additions
sudo tcpdump -D | tail -4
