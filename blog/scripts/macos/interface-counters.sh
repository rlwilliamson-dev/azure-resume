# The cumulative interface counters a Mac keeps, read twice.
#
# One command per line, same shape as a netlab steps file.
#
# Topic 40 polls an octet counter over SNMP and takes the difference. The same
# counters are on every machine, and reading them twice is the whole of what a
# monitoring system does. macOS prints them with netstat rather than in /proc.

# Bytes in and bytes out per interface, cumulative since boot
netstat -ib | awk 'NR==1 || $1 ~ /^en0$/' | head -3

# Two seconds later, and the difference between the two is the only useful number
sleep 2

netstat -ib | awk 'NR==1 || $1 ~ /^en0$/' | head -3

# Errors and drops, which are the counters worth alerting on rather than graphing
netstat -i | head -3
