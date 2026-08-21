# The traces one page load leaves behind on a Mac.
#
# One command per line, same shape as a netlab steps file.
#
# Topic 45 captures the whole sequence on the wire. This is the same sequence
# read afterwards from the machine's own tables, which is what you actually have
# when somebody says a page was slow an hour ago.
#
# example.com is used because IANA operates it for exactly this purpose under
# RFC 2606, so nothing here points at somebody's real site.

# do the load
curl -s -o /dev/null https://example.com/

# the name step: what the resolver returned
dscacheutil -q host -a name example.com | head -4

# the address resolution step: the gateway this machine had to find first
netstat -rn -f inet | awk '$1 == "default" { print; exit }'

arp -a | grep -c .

# the connection step: what the load opened, and what state it is in now
netstat -an -p tcp | grep -E "\.443 " | head -3
