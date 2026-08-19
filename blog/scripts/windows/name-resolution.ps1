# Name resolution tools as Windows spells them.
#
# One command per line, same shape as a netlab steps file.
#
# Objective 5.5 names nslookup. Windows also has Resolve-DnsName, which shows the
# same answer with the record type and TTL broken out. A forward lookup turns a
# name into an address; a reverse lookup turns an address back into a name, and
# the answer section says whether the server was authoritative for it.

# A forward lookup, name to address, through the machine's configured resolver
nslookup example.com

# The same, asking a specific server rather than the default one
nslookup example.com 1.1.1.1

# A reverse lookup, address back to a name
nslookup 8.8.8.8

# The cmdlet form, which breaks out the type and TTL the answer carries
Resolve-DnsName example.com -Type A | Format-Table Name, Type, TTL, IPAddress -AutoSize
