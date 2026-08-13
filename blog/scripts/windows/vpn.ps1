# What a VPN looks like on Windows before anybody connects one.
#
# One command per line, same shape as a netlab steps file.
#
# Topic 50 is about where a tunnel terminates and what it carries. On the client
# the visible part is a virtual adapter, and Windows keeps a set of them
# permanently installed and hidden, one per tunnelling protocol it supports.

# Configured connections, if any
Get-VpnConnection -AllUserConnection -ErrorAction SilentlyContinue | Measure-Object | Select-Object -ExpandProperty Count

# The adapters that exist whether or not anything is configured
Get-NetAdapter -IncludeHidden | Where-Object { $_.InterfaceDescription -match "Miniport|Tunnel|Teredo|isatap" } | Select-Object -First 6 Name, InterfaceDescription | Format-Table -AutoSize
