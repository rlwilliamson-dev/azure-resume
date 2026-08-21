# The address, the mask and the lease, as macOS reports them.
#
# One command per line, same shape as a netlab steps file.
#
# The third notation for the same number. A prefix length is /24, a Windows mask
# is 255.255.255.0, and BSD prints hexadecimal, so a mask fault read at two ends
# of a link usually means converting one of them.

# the mask in the notation BSD chose
ifconfig en0 | grep -E "inet |status"

# the lease as the DHCP client received it, field by field
ipconfig getpacket en0

# the neighbour table
arp -an | head -6
