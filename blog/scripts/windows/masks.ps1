# How Windows writes a subnet mask.
#
# One command per line, same shape as a netlab steps file.
#
# Topic 05 teaches the mask as a prefix length. Windows prints dotted decimal
# instead, and a reader following the Linux output has to work out that /20 and
# 255.255.240.0 are the same statement. Capturing it is cheaper than saying so.

# ipconfig is the tool objective 5.5 names, and it prints the mask the old way
ipconfig | Select-String -Pattern "IPv4 Address|Subnet Mask"

# A prefix length does exist on Windows. This is where it lives
Get-NetIPAddress -AddressFamily IPv4 | Format-Table InterfaceAlias, IPAddress, PrefixLength, PrefixOrigin -AutoSize
