# The IPv6 addresses a Mac holds without being asked.
#
# One command per line, same shape as a netlab steps file.

# The link-local address, and the flag that says how it was generated
ifconfig en0 | grep -E "inet6 "

# Whether this machine can reach the IPv6 internet at all
netstat -rn -f inet6 | head -6
