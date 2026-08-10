# Windows host identifiers and the tools the exam names for them.
#
# One command per line, in the same shape as a netlab steps file. Lines starting
# with # are printed as narration. Blank lines are kept for spacing.
#
# Objective 5.5 names ipconfig, arp, netstat, nslookup and tracert specifically,
# so those are the ones that earn their place here. The PowerShell equivalents
# are captured alongside because they are what a current Windows administrator
# actually reaches for, and a topic can then show both without guessing at
# either.

# What Windows calls an interface, and the two identifiers on it
ipconfig

# The same thing in full, which is where the MAC address lives
ipconfig /all

# The neighbour table. Linux calls this ip neigh; the exam names arp
arp -a

# The routing table
route print -4

# Listening sockets with the owning process id
netstat -ano -p TCP

# The modern equivalents, which report the same facts as objects
Get-NetIPConfiguration
Get-NetNeighbor -AddressFamily IPv4 -State Reachable
Get-NetTCPConnection -State Listen
