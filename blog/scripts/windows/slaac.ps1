# What Windows does with router advertisements, and what it does about privacy.
#
# One command per line, same shape as a netlab steps file.
#
# Topic 08 covers what addresses a machine holds. This is the other question:
# is this host listening for advertisements, and what interface identifier does
# it choose. Windows has had randomised identifiers on by default since Vista,
# which is why an address on a Windows machine has never looked like its MAC.

# Router discovery, per interface, and whether advertisements are accepted
netsh interface ipv6 show interfaces | Select-Object -First 6

# The two settings that decide what the second half of the address looks like
Get-NetIPv6Protocol | Format-List RandomizeIdentifiers, UseTemporaryAddresses, MaxTemporaryPreferredLifetime, MaxTemporaryValidLifetime

# Anything learned from an advertisement appears here with RouterAdvertisement as its origin
Get-NetIPAddress -AddressFamily IPv6 | Format-Table InterfaceAlias, IPAddress, PrefixOrigin, SuffixOrigin -AutoSize
