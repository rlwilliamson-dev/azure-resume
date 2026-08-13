# What Windows knows about encrypted DNS.
#
# One command per line, same shape as a netlab steps file.
#
# Topic 47 queries a resolver over TLS from Linux. Windows takes a different
# route: it carries a list of well-known resolvers it already knows how to reach
# over DNS over HTTPS, so enabling encrypted DNS is a matter of choosing one
# rather than of configuring a URL.

# The resolvers this machine already knows how to reach over HTTPS
Get-DnsClientDohServerAddress | Format-Table ServerAddress, DohTemplate, AutoUpgrade -AutoSize

# Whether encrypted DNS is currently switched on for any interface
Get-DnsClientDohServerAddress | Measure-Object | Select-Object -ExpandProperty Count
