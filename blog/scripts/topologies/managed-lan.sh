# A small network with something watching it.
#
#      mon 10.0.0.10          agent 10.0.0.20        user 10.0.0.30
#            |                      |                      |
#            +--------------- sw1 (bridge) ----------------+
#                              |
#                        collector 10.0.0.40
#                        (mirror destination, no traffic of its own)
#
# Built for the monitoring topics, which need three things no earlier topology
# has: a device that answers SNMP, a station that polls it, and a spare port to
# hang a capture off.
#
# `mon` polls, `agent` answers, `user` generates the ordinary traffic that
# monitoring is supposed to notice, and `collector` sits on a port that receives
# nothing at all until a mirror is configured in the captured command. Leaving
# the mirror out of the topology is deliberate: the mirror is the thing being
# taught, so the reader watches it being set up rather than being handed a
# switch that already works.
#
# The agent runs snmpd with a v2c community and a v3 user, both configured here
# so the captured command is a poll rather than a page of daemon setup. Debian
# strips the standard MIB files into a non-free package, so a walk against this
# agent reports numeric OIDs. That is correct behaviour and the SNMP topic shows
# it alongside a walk that has the MIBs loaded, captured in a container where
# the download is a build step rather than something happening mid-transcript.
NETLAB_PACKAGES="iproute2 iputils-ping tcpdump snmp snmpd conntrack netcat-openbsd"
NETLAB_SETTLE=3

ip netns add sw1
ip -n sw1 link set lo up
ip netns exec sw1 sh -c "echo 1 > /proc/sys/net/ipv6/conf/default/disable_ipv6"
ip netns exec sw1 sh -c "echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6"
ip -n sw1 link add br0 type bridge
ip -n sw1 link set br0 up

# host NAME with last octet N. Fixed MACs, because a transcript that changes
# every run cannot be checked against the page.
add_host() {
  name=$1; n=$2
  ip netns add "$name"
  ip -n "$name" link set lo up
  ip netns exec "$name" sh -c "echo 1 > /proc/sys/net/ipv6/conf/default/disable_ipv6"
  ip netns exec "$name" sh -c "echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6"

  ip link add "${name}0" type veth peer name "sw1-${name}"
  ip link set "${name}0" netns "$name"
  ip link set "sw1-${name}" netns sw1

  ip -n "$name" link set "${name}0" address "02:00:00:00:00:$n"
  ip -n "$name" addr add "10.0.0.$n/24" dev "${name}0"
  ip -n "$name" link set "${name}0" up

  ip -n sw1 link set "sw1-${name}" master br0
  ip -n sw1 link set "sw1-${name}" up
}

add_host mon 10
add_host agent 20
add_host user 30
add_host collector 40

# The agent's SNMP configuration. v2c with a community string that looks like a
# secret, because the point of the wire capture is that it is not one. v3 with
# SHA-512 authentication and AES privacy, which is what RFC 7860 and RFC 3826
# define and what an agent should be configured with today.
ip netns exec agent sh -c 'mkdir -p /etc/snmp && cat > /etc/snmp/snmpd.conf <<CONF
agentaddress udp:10.0.0.20:161
rocommunity s3cr3t-ro 10.0.0.10
createUser netops SHA-512 "authpassphrase" AES "privpassphrase"
rouser netops authpriv
sysLocation Comms room 2, rack 4
sysContact netops@example.com
CONF'

# snmpd daemonises, so this returns and the agent keeps answering for the rest
# of the run. Logging goes to /dev/null rather than to syslog, which is not
# running here and would otherwise put a delay on every poll.
ip netns exec agent snmpd -Lf /dev/null
