# What Windows brings to SNMP without installing anything.
#
# One command per line, same shape as a netlab steps file.
#
# Two separate questions, and the answers differ. Can this machine be polled,
# which is the agent, and can it poll something else, which is the client. The
# first is an optional feature that Microsoft documents as deprecated. The
# second has no built-in answer at all.

# The agent, shipped as an optional feature rather than installed
Get-WindowsCapability -Online -Name "SNMP*" | Select-Object Name, State | Format-Table -AutoSize

# Is there anything here that can poll another device
Get-Command snmpwalk, snmpget -ErrorAction SilentlyContinue | Measure-Object | Select-Object -ExpandProperty Count
