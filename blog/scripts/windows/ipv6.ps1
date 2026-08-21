# The IPv6 addresses a Windows machine holds without being asked.
#
# One command per line, same shape as a netlab steps file.
#
# Topic 08 derives a link-local address from a MAC by hand and then says most
# real machines do not generate them that way any more. This is what a real
# machine reports instead.

# Every IPv6 address, where its interface identifier came from, and its state
Get-NetIPAddress -AddressFamily IPv6 | Format-Table InterfaceAlias, IPAddress, PrefixLength, SuffixOrigin, AddressState -AutoSize

# The same addresses through the tool the exam names, with the zone index
ipconfig | Select-String -Pattern "IPv6 Address"
