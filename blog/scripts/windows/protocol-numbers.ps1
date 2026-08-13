# The other registry every machine carries.
#
# One command per line, same shape as a netlab steps file.
#
# Topic 10 read the services file, which maps port numbers to names. Topic 49 is
# about the field one layer down: the protocol number in the IP header. Windows
# keeps that registry next to the services file, in the same directory nobody
# opens.

# Same registry, same numbers, next to the services file
Get-Content "$env:SystemRoot\System32\drivers\etc\protocol" | Select-String -Pattern "^(icmp|igmp|tcp|udp|gre|esp|ah|ipv6-icmp)\s"
