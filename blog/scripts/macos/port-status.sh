# Whether a port is up, and the error counters that say why it is not.
#
# One command per line, same shape as a netlab steps file.
#
# Topic 40 read the byte counters, which are for graphing. This is the other
# half: the link status of the interface, and the error and drop counters, which
# are the ones worth alerting on. BSD netstat prints errors in the same table as
# packets rather than in a separate one, so one command answers both questions.

# Packets, errors and collisions on the wired interface, cumulative since boot
netstat -i | awk 'NR==1 || $1 ~ /^en0$/'

# The link state of one interface, and what it negotiated
ifconfig en0 | grep -E "flags|status|media"

# Every interface, and which of them have a link. inactive is a port with
# nothing plugged into it, which is a different thing from a port that is down
ifconfig -a | grep -E "^[a-z0-9]+: flags|status:" | head -14
