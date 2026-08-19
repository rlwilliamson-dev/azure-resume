# Interfaces and the neighbour table as macOS reports them.
#
# One command per line, same shape as a netlab steps file.
#
# BSD ifconfig is the tool here, and it takes different flags from the Linux one
# and prints a different layout. There is no ip command. The neighbour table is
# arp, spelled as on the other two platforms but with BSD flags.

# The names of every interface on the machine
ifconfig -l

# The primary interface in full, the ifconfig the exam names
ifconfig en0

# The neighbour table, numeric, first entries only
arp -an | head -6
