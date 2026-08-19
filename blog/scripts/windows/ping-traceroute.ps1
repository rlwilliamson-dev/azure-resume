# Ping, tracert and a path-MTU probe as Windows spells them.
#
# One command per line, same shape as a netlab steps file.
#
# Objective 5.5 names tracert, not traceroute, and the difference is not only the
# spelling: tracert probes with ICMP echo by default where the Linux and macOS
# tools send UDP, so a host that filters one and not the other traces differently
# on different platforms. The don't-fragment flag is spelled differently again.

# Reachability and the round trip, the same idea as everywhere
ping -n 2 1.1.1.1

# The path to a host, hop by hop, not resolving names, capped so it stays short
tracert -d -h 8 1.1.1.1

# A large packet that refuses to be fragmented, to find the smallest link on the
# path. -f sets don't-fragment, -l sets the size
ping -f -l 1400 -n 1 1.1.1.1
