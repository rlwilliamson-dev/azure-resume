# Ping, traceroute and a path-MTU probe as macOS spells them.
#
# One command per line, same shape as a netlab steps file.
#
# BSD ping and traceroute take different flags from the Linux ones. traceroute
# sends UDP probes like Linux and unlike Windows tracert, so the same fault can
# look different depending on which tool asked. The count flag, the size flag and
# the don't-fragment flag all differ from both other platforms.

# Reachability and the round trip
ping -c 2 1.1.1.1

# The path to a host, hop by hop, not resolving names, capped so it stays short.
# traceroute sends UDP probes by default, unlike Windows tracert
traceroute -n -q 1 -m 8 1.1.1.1
