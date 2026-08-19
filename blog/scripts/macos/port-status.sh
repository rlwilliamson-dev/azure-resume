# Whether a port is up, and the error counters that say why it is not.
#
# One command per line, same shape as a netlab steps file.
#
# Topic 40 read the byte counters, which are for graphing. This is the other
# half: the link status of the interface, and the error and drop counters, which
# are the ones worth alerting on. BSD netstat prints errors in the same table as
# packets rather than in a separate one, so one command answers both questions.

# Packets, errors and drops per interface, cumulative since boot
netstat -i | head -6

# The link state of one interface, and what it negotiated
ifconfig en0 | grep -E "flags|status|media"
