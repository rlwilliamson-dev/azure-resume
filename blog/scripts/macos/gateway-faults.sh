# Which route wins, asked directly, on macOS.
#
# One command per line, same shape as a netlab steps file.
#
# BSD writes the default route as the word "default" rather than as a prefix of
# zeros, which hides the arithmetic that makes it work. The second command is
# the useful one and the direct equivalent of ip route get.

# the default route as BSD writes it
netstat -rn -f inet | grep -E "Destination|^default"

# the decision for one destination, which is ip route get in another spelling
route -n get 1.1.1.1

# the neighbour table, where a gateway that never answers leaves its mark
arp -an | head -6

# the path, probed with UDP by default rather than the ICMP echo Windows sends
traceroute -n -m 6 -q 1 1.1.1.1
