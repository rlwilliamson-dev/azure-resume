# How the host firewall decides, and which of the two firewalls answers.
#
# One command per line, same shape as a netlab steps file.
#
# The Linux column walks an ordered nftables list. macOS ships two separate
# firewalls with different models, and the one most people mean is not the one
# that filters packets.

# The packet filter, which is ordered and is off by default on a Mac
sudo pfctl -s info 2>&1 | head -3

# Its rules, if any are loaded
sudo pfctl -s rules 2>&1 | head -5

# The other firewall, which filters by application rather than by port
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate 2>&1; sudo /usr/libexec/ApplicationFirewall/socketfilterfw --getblockall 2>&1

# What it is holding, which is a list of programs rather than a list of ports
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --listapps 2>&1 | head -4
