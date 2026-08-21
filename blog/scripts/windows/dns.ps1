# Where Windows keeps its resolver settings, its cache and its hosts file.
#
# One command per line, same shape as a netlab steps file.
#
# Topic 44 traces a name from the root down. Windows adds a step the other two
# platforms mostly do not have: a client-side cache with its own countdown,
# which is why a record can be stale on one machine and current on the next.

# Which resolver this machine asks
Get-DnsClientServerAddress -AddressFamily IPv4 | Where-Object ServerAddresses | Format-Table InterfaceAlias, ServerAddresses -AutoSize

# The file consulted before any of that
Get-Content "$env:SystemRoot\System32\drivers\etc\hosts" | Select-String -NotMatch "^#|^$" | Select-Object -First 3

# What the machine already knows, with its own countdown per entry
Resolve-DnsName example.com -Type A | Format-Table Name, Type, TTL, IPAddress -AutoSize

Get-DnsClientCache -Entry example.com | Format-Table Entry, RecordName, TimeToLive, Data -AutoSize
