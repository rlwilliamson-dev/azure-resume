# How Windows presents an address and its mask, and what it does with IPv6.
#
# One command per line, in the same shape as a netlab steps file. Lines starting
# with # are printed as narration.
#
# This exists because topic 05 teaches the mask as a prefix length and Windows
# does not print one. A reader following the Linux output on a Windows machine
# sees 255.255.255.0 where the page said /24 and has to work out that those are
# the same statement. Capturing it is cheaper than explaining it.

# ipconfig is the tool objective 5.5 names, and it prints the mask the old way
ipconfig | Select-String -Pattern "IPv4 Address|Subnet Mask|Default Gateway"

# A prefix length does exist on Windows. This is where it lives
Get-NetIPAddress -AddressFamily IPv4 | Format-Table InterfaceAlias, IPAddress, PrefixLength, PrefixOrigin -AutoSize

# The whole of 127.0.0.0/8 answers here too, not only the famous address
ping -n 2 127.9.9.9

# IPv6, including the addresses nobody configured, and where each came from
Get-NetIPAddress -AddressFamily IPv6 | Format-Table InterfaceAlias, IPAddress, PrefixLength, SuffixOrigin, AddressState -AutoSize
