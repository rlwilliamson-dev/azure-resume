# Finding the network behind an address, on Windows.
#
# One command per line, same shape as a netlab steps file.
#
# The lookups in this topic are dig and curl piped into jq, and Windows ships
# none of the three. PowerShell answers both questions natively: a typed DNS
# query for the Team Cymru mapping, and a REST call for the RIPE validation,
# which comes back as an object so there is nothing to parse.

# which organisation holds AS15169, from the Team Cymru DNS service
Resolve-DnsName -Type TXT -Name AS15169.asn.cymru.com | Select-Object -ExpandProperty Strings

# which prefix an address belongs to, and which AS announces it
Resolve-DnsName -Type TXT -Name 8.8.8.8.origin.asn.cymru.com | Select-Object -ExpandProperty Strings

# whether that announcement is authorised, from the RIPE data API
(Invoke-RestMethod "https://stat.ripe.net/data/rpki-validation/data.json?resource=AS15169&prefix=8.8.8.0/24").data.status
