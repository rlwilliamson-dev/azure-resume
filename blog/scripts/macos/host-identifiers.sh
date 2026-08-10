# macOS host identifiers, using the tools macOS actually ships.
#
# One command per line, same shape as a netlab steps file. Lines starting with #
# are printed as narration.
#
# macOS is worth capturing separately rather than being lumped in with Linux.
# It is BSD underneath, so several of the exam's named tools behave differently
# here than they do on Linux, and one of them is the reverse of what a Linux
# habit would suggest: `ifconfig` is deprecated on Linux and is still the primary
# tool on macOS. A reader on a Mac following Linux instructions hits that
# immediately.

# The interface and its two identifiers. ifconfig is current here, not legacy
ifconfig en0

# Which interface actually carries traffic, and via which gateway
route -n get default

# The routing table. Linux says ip route; BSD says netstat -rn
netstat -rn -f inet

# The neighbour table
arp -a

# Listening sockets. There is no ss here
netstat -an -p tcp | head -12

# The resolver, which does not live in /etc/resolv.conf on macOS
scutil --dns | head -12
