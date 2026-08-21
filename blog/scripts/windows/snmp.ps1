# What Windows brings to SNMP without installing anything.
#
# One command per line, same shape as a netlab steps file.
#
# Two separate questions, and the answers differ. Can this machine be polled,
# which is the agent, and can it poll something else, which is the client. The
# first ships as an optional feature that has to be turned on. The second has no
# built-in answer at all.
#
# The runner is Windows Server, where optional components are features. On a
# Windows client the same agent is an optional capability with a different name,
# reached through Settings rather than through Server Manager.

# The agent, present and not installed
Get-WindowsFeature -Name SNMP* | Format-Table Name, InstallState -AutoSize

# Is there anything here that can poll another device
Get-Command snmpwalk, snmpget, snmpget.exe -ErrorAction SilentlyContinue | Measure-Object | Select-Object -ExpandProperty Count
