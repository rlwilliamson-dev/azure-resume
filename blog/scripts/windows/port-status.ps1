# Whether a port is up, and the error counters that say why it is not.
#
# One command per line, same shape as a netlab steps file.
#
# Topic 40 read the byte counters, which are for graphing. This is the other
# half: the status of the adapter, and the error and discard counters, which are
# the ones worth alerting on. The exam names netstat, and netstat -e is where
# Windows puts the same numbers in the classic two-column form.

# Which adapters exist, whether each is up, and at what speed
Get-NetAdapter | Format-Table Name, Status, LinkSpeed, MediaConnectionState -AutoSize

# Including the ones Windows hides, so a disconnected or disabled adapter is
# visible next to a working one
Get-NetAdapter -IncludeHidden | Select-Object -First 10 | Format-Table Name, Status, MediaConnectionState -AutoSize

# The error and discard counters, which are separate numbers from the byte ones
Get-NetAdapterStatistics | Format-List Name, ReceivedPacketErrors, ReceivedDiscardedPackets, OutboundPacketErrors, OutboundDiscardedPackets

# The same counters through the tool the exam names, in its own layout
netstat -e
