# Two switches, a trunk between them, and two VLANs that must not mix.
#
#   h1 v10   h2 v20            h3 v10   h4 v20
#      |        |                 |        |
#      +-- sw1 -+---- trunk ------+- sw2 --+
#            10.0.10.0/24 on VLAN 10
#            10.0.20.0/24 on VLAN 20
#
# A Linux bridge with vlan_filtering on is a VLAN-capable switch. Access ports
# get a PVID and untag on the way out; the trunk carries both VLANs tagged. So
# 802.1Q tagging is observable in a capture rather than illustrated.
#
# h1 and h3 are on VLAN 10 and can reach each other across the trunk. h2 and h4
# are on VLAN 20 and can reach each other. Nothing on 10 can reach anything on
# 20, which is the point, and the addresses are in different subnets so a reader
# cannot mistake VLAN separation for subnet separation.
NETLAB_PACKAGES="iproute2 iputils-ping tcpdump"
NETLAB_SETTLE=1

for s in sw1 sw2; do
  ip netns add $s
  ip -n $s link set lo up
  ip netns exec $s sh -c "echo 1 > /proc/sys/net/ipv6/conf/default/disable_ipv6"
  ip netns exec $s sh -c "echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6"
  ip -n $s link add br0 type bridge vlan_filtering 1 vlan_default_pvid 0
  ip -n $s link set br0 up
done

# host N on switch S, in VLAN V, with address 10.0.V.N
add_host() {
  n=$1; s=$2; v=$3
  ip netns add h$n
  ip -n h$n link set lo up
  ip netns exec h$n sh -c "echo 1 > /proc/sys/net/ipv6/conf/default/disable_ipv6"
  ip netns exec h$n sh -c "echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6"

  ip link add h${n}eth0 type veth peer name ${s}-h$n
  ip link set h${n}eth0 netns h$n
  ip link set ${s}-h$n netns $s

  ip -n h$n link set h${n}eth0 address 02:00:00:00:00:0$n
  ip -n h$n addr add 10.0.$v.$n/24 dev h${n}eth0
  ip -n h$n link set h${n}eth0 up

  ip -n $s link set ${s}-h$n master br0
  ip -n $s link set ${s}-h$n up
  # an access port: untagged in, tagged into VLAN v, untagged back out
  ip netns exec $s bridge vlan del dev ${s}-h$n vid 1
  ip netns exec $s bridge vlan add dev ${s}-h$n vid $v pvid untagged
}

add_host 1 sw1 10
add_host 2 sw1 20
add_host 3 sw2 10
add_host 4 sw2 20

# h5 is the interesting one. It sits in VLAN 20 and carries an address in VLAN
# 10's subnet, so it is on the same network as h1 by every measure a host can
# see and still cannot reach it. That separates the two things a reader will
# otherwise conflate: a VLAN divides at layer 2, and it does not care what
# addresses anybody is using.
add_host 5 sw1 20
ip -n h5 addr del 10.0.20.5/24 dev h5eth0
ip -n h5 addr add 10.0.10.5/24 dev h5eth0

# the trunk, carrying both VLANs with their tags intact
ip link add sw1-trunk type veth peer name sw2-trunk
ip link set sw1-trunk netns sw1
ip link set sw2-trunk netns sw2
for s in sw1 sw2; do
  ip -n $s link set ${s}-trunk address 02:00:00:00:ff:0${s#sw}
  ip -n $s link set ${s}-trunk master br0
  ip -n $s link set ${s}-trunk up
  ip netns exec $s bridge vlan del dev ${s}-trunk vid 1
  ip netns exec $s bridge vlan add dev ${s}-trunk vid 10
  ip netns exec $s bridge vlan add dev ${s}-trunk vid 20
done
