# Interfaces and the neighbour table as Windows reports them.
#
# One command per line, same shape as a netlab steps file.
#
# Objective 5.5 names ipconfig and arp. Windows also has newer cmdlets that give
# the same answers in a form you can filter, so both go on the page: the command
# the exam asks about, and the one an administrator actually reaches for.

# The interfaces this machine has, with the names the other commands use
Get-NetAdapter | Format-Table Name, InterfaceDescription, Status, LinkSpeed -AutoSize

# Their IPv4 addresses, which is the ipconfig question asked precisely
Get-NetIPAddress -AddressFamily IPv4 | Format-Table InterfaceAlias, IPAddress, PrefixLength -AutoSize

# The neighbour table the exam calls arp
arp -a

# The same table from the modern cmdlet, which names a state per entry
Get-NetNeighbor -AddressFamily IPv4 | Where-Object State -in 'Reachable','Stale' | Format-Table IPAddress, LinkLayerAddress, State -AutoSize
