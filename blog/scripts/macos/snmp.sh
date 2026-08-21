# What a Mac brings to SNMP without installing anything.
#
# One command per line, same shape as a netlab steps file.
#
# Topic 38 polls an agent from a Linux station. The question a reader will have
# is whether they can do the same thing from the machine in front of them, and
# on macOS the answer is yes, which surprises people.

# The client tools ship in the base system
snmpwalk -V 2>&1

# All of them, so the reader can see what else arrived
ls /usr/bin/snmp* | sed "s|/usr/bin/||" | tr "\n" " "

# The MIB files that came with them
ls /usr/share/snmp/mibs | wc -l
