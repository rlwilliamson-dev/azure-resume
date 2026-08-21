# The other registry every machine carries.
#
# One command per line, same shape as a netlab steps file.
#
# Topic 10 read /etc/services, which maps port numbers to names. Topic 49 is
# about the field one layer down: the protocol number in the IP header, which
# says what the payload is rather than which program should get it. Every
# machine ships that registry too, in a file nobody opens.

# The protocol numbers this topic is about, from the machine's own copy
grep -E "^(icmp|igmp|tcp|udp|gre|esp|ah|ipv6-icmp)[[:space:]]" /etc/protocols
