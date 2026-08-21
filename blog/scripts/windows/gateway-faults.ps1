# Which route wins, asked directly, on Windows.
#
# One command per line, same shape as a netlab steps file.
#
# Topic 21 reads the whole table. This is the other question and the one that
# settles a gateway fault: given one destination, which line does the stack
# actually pick, and out of which interface. Linux spells it ip route get.
# Windows spells it Find-NetRoute, which is the row of the comparison table
# most people have never met on their own platform.

# the default route this machine is using, and the metric that chose it
Get-NetRoute -DestinationPrefix 0.0.0.0/0 | Format-Table DestinationPrefix, NextHop, RouteMetric, InterfaceAlias -AutoSize

# the decision for one destination, which is ip route get in another spelling
Find-NetRoute -RemoteIPAddress 1.1.1.1

# the neighbour table, where a gateway that never answers leaves its mark
arp -a

# the path, probed with ICMP echo rather than the UDP the other two send
tracert -d -h 6 1.1.1.1
