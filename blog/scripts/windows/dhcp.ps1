# What Windows keeps from its DHCP lease.
#
# One command per line, same shape as a netlab steps file.
#
# Topic 42 reads a lease file on Linux. Windows does not keep one a person can
# read, and puts the same facts in two places instead: the tool the exam names,
# and a cmdlet that returns them as objects.

# The tool the exam names, filtered to the lease
ipconfig /all | Select-String -Pattern "DHCP Enabled|DHCP Server|Lease Obtained|Lease Expires|IPv4 Address|Default Gateway"

# The same lease through the cmdlet, where the origin of each address is a field
Get-NetIPAddress -AddressFamily IPv4 | Format-Table InterfaceAlias, IPAddress, PrefixOrigin, SuffixOrigin, AddressState -AutoSize
