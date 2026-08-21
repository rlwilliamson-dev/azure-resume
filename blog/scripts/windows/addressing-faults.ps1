# The address, the mask and the lease, as Windows reports them.
#
# One command per line, same shape as a netlab steps file.
#
# The comparison table claims the same mask reads as 255.255.255.0 here and as
# a prefix length on the other two. These two commands make that claim on one
# machine in one capture: ipconfig writes the dotted decimal and the cmdlet
# writes the prefix length, and they are describing the same interface.

# the mask in dotted decimal, which is the form the exam shows
ipconfig

# the same addresses as objects, where the mask is a prefix length
Get-NetIPAddress -AddressFamily IPv4 | Format-Table IPAddress, PrefixLength, PrefixOrigin, SuffixOrigin, InterfaceAlias -AutoSize

# where the address came from, which is the only place Windows prints the lease
ipconfig /all
