# Discovery without nmap, on Windows.
#
# One command per line, same shape as a netlab steps file.
#
# Nmap is not installed by default on any of the three platforms, so on a
# machine you did not build the answer is the built-in connection tester. It
# answers one host and one port at a time, which is the whole difference: a
# sweep becomes a loop somebody has to write.

# one host, one port, with the name resolution and the route it took
Test-NetConnection -ComputerName 1.1.1.1 -Port 443 -InformationLevel Detailed

# the neighbour table, which carries addresses and no device names at all
Get-NetNeighbor -AddressFamily IPv4 | Where-Object State -ne Unreachable | Format-Table IPAddress, LinkLayerAddress, State, InterfaceAlias -AutoSize
