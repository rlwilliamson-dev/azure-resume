# What Windows does with the loopback block.
#
# One command per line, same shape as a netlab steps file.
#
# Topic 07 says the whole of 127.0.0.0/8 is the machine itself. That is true on
# Linux and on Windows and not on macOS, so all three need capturing rather than
# one being generalised into a claim about every platform.

# Not only the famous address
ping -n 2 127.9.9.9

# The interface it lives on, and the mask that covers the whole block
Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias "Loopback*" | Format-Table IPAddress, PrefixLength, PrefixOrigin, SuffixOrigin -AutoSize
