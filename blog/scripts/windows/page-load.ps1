# The traces one page load leaves behind on Windows.
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
Invoke-WebRequest -Uri "https://example.com/" -UseBasicParsing -OutFile $env:TEMP\page.html

# the name step, still in the client cache afterwards
Get-DnsClientCache -Entry example.com | Format-Table Entry, Type, TimeToLive, Data -AutoSize

# the address resolution step: the gateway, and the neighbour entry for it
Find-NetRoute -RemoteIPAddress 1.1.1.1 | Select-Object -First 1 -Property NextHop, InterfaceAlias | Format-Table -AutoSize

Get-NetNeighbor -AddressFamily IPv4 -State Reachable, Stale | Select-Object -First 3 IPAddress, LinkLayerAddress, State | Format-Table -AutoSize

# the connection step
Get-NetTCPConnection -RemotePort 443 | Select-Object -First 3 LocalAddress, LocalPort, RemoteAddress, State | Format-Table -AutoSize
