# The routing table as Windows prints it.
#
# One command per line, same shape as a netlab steps file.
#
# Objective 5.5 names route, and topic 21 reads a table with ip route
# throughout. The columns carry the same facts in a different order and Windows
# writes the default route as a destination and mask of zeros, which is the
# clearest statement of what a default route is that any of the three produce.

# the tool the exam names
route print -4

# and the same table as objects, with the metric that decides between two routes
Get-NetRoute -AddressFamily IPv4 | Sort-Object -Property RouteMetric | Format-Table DestinationPrefix, NextHop, RouteMetric, InterfaceAlias -AutoSize
