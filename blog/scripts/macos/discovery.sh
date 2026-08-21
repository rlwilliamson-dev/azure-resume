# Discovery without nmap, on macOS.
#
# One command per line, same shape as a netlab steps file.
#
# Same limitation as Windows and a different built-in. Netcat ships with the
# system and tests one port at a time, and there is no neighbour discovery
# client at all, so the neighbour table is addresses and hardware addresses and
# nothing that says what the device is.

# one host, one port, with a timeout so a filtered port does not hang
nc -vz -G 3 1.1.1.1 443

# the neighbour table, addresses and hardware addresses and no names
arp -an | head -8
