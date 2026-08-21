# Asking for particular record types from Windows.
#
# One command per line, same shape as a netlab steps file.
#
# Topic 46 uses dig against a lab zone. Windows has no dig, and has two
# replacements: the old tool the exam names, and a cmdlet that returns objects.

# The tool the exam names, which is still here and still deprecated by Microsoft
nslookup -type=MX example.com 2>$null | Select-String -NotMatch "^$" | Select-Object -First 6

# The cmdlet, where each record is an object with typed fields
Resolve-DnsName example.com -Type MX | Format-Table Name, Type, TTL, NameExchange, Preference -AutoSize

Resolve-DnsName example.com -Type NS | Where-Object Type -eq "NS" | Format-Table Name, Type, NameHost -AutoSize

# Is there a dig
Get-Command dig -ErrorAction SilentlyContinue | Measure-Object | Select-Object -ExpandProperty Count
