# An SNMP agent to point captures at, so the walks on the SNMP topic are real
# reads from a real agent rather than a hand-written approximation.
#
# Three things this has to do that are not obvious:
#
# Debian ships net-snmp without the standard MIB files. They live in
# snmp-mibs-downloader, which is in non-free because the IETF's licence on the
# MIB modules is not a free software licence, and the package fetches them at
# install time rather than shipping them. So the component has to be added and
# download-mibs has to run, and a walk before that step reports numeric OIDs.
# That is worth knowing rather than working around: it is the same reason a
# monitoring system shows you .1.3.6.1.4.1.9.9.13.1.3.1.3 until somebody loads
# the vendor's MIB.
#
# /etc/snmp/snmp.conf ships with `mibs :` which clears the MIB search list, so
# the files being present is not sufficient. That line has to go.
#
# The v3 user is created in snmpd.conf with createUser, which the agent consumes
# on first start and rewrites into its persistent state. SHA-512 and AES are
# chosen because they are what RFC 7860 and RFC 3826 define and what a current
# agent should be configured with; the passphrases here are obviously not
# secrets, and the community string is written to look like one so that seeing
# it in a packet capture lands properly.
sed -i 's/^Components: main$/Components: main non-free/' /etc/apt/sources.list.d/debian.sources
apt-get update -qq
apt-get install -y -qq snmpd snmp snmp-mibs-downloader tcpdump
download-mibs
sed -i 's/^mibs :/# mibs :/' /etc/snmp/snmp.conf

cat > /etc/snmp/snmpd.conf <<'CONF'
agentaddress udp:127.0.0.1:161
rocommunity s3cr3t-ro 127.0.0.1
createUser netops SHA-512 "authpassphrase" AES "privpassphrase"
rouser netops authpriv
sysLocation Comms room 2, rack 4
sysContact netops@example.com
CONF

# net-snmp creates /var/lib/snmp/cert_indexes on first use and announces it on
# stdout. Do it here so the line lands in the build rather than in a transcript.
snmptranslate -Td SNMPv2-MIB::sysUpTime >/dev/null 2>&1 || true
