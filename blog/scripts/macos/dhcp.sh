# What a Mac keeps from its DHCP lease.
#
# One command per line, same shape as a netlab steps file.
#
# Topic 42 reads a lease file on Linux. macOS has something better: it will hand
# back the entire DHCP packet it was given, option by option, which is the same
# thing a packet capture would show without needing one.

# The lease, as the packet that carried it
ipconfig getpacket en0 | head -24

# The same lease as a summary, including when it was taken
ipconfig getsummary en0 | grep -iE "lease|router|server_identifier|domain_name_server" | head -6
