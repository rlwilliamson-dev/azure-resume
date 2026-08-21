# Two private networks with a public one between them, and no tunnel yet.
#
#   lana 10.1.0.2 --- ra --------- 198.51.100.0/24 --------- rb --- lanb 10.2.0.2
#                  .1    .1                            .2    .1
#
# Deliberately incomplete. The routers can reach each other across the middle
# and neither private network can reach the other, which is the situation every
# tunnel exists to fix. Each capture on topic 49 builds its own tunnel in the
# command, so the configuration and the result appear together and a reader can
# see exactly what was done.
#
# 198.51.100.0/24 is TEST-NET-2 from RFC 5737 and stands in for the public
# internet. 10.1.0.0/24 and 10.2.0.0/24 are the two sites.
NETLAB_PACKAGES="iproute2 iputils-ping tcpdump"
NETLAB_SETTLE=1

for s in swa swb swm; do
  ip netns add $s
  ip -n $s link set lo up
  ip netns exec $s sh -c "echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6"
  ip -n $s link add br0 type bridge
  ip -n $s link set br0 up
done

add_host() {
  name=$1; s=$2; nn=$3; addr=$4
  ip netns add "$name" 2>/dev/null || true
  ip -n "$name" link set lo up
  ip netns exec "$name" sh -c "echo 1 > /proc/sys/net/ipv6/conf/default/disable_ipv6"
  ip netns exec "$name" sh -c "echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6"
  ip link add "${name}-${s}" type veth peer name "${s}-${name}"
  ip link set "${name}-${s}" netns "$name"
  ip link set "${s}-${name}" netns "$s"
  ip -n "$name" link set "${name}-${s}" address "02:00:00:00:00:$nn"
  ip -n "$name" addr add "$addr" dev "${name}-${s}"
  ip -n "$name" link set "${name}-${s}" up
  ip -n "$s" link set "${s}-${name}" master br0
  ip -n "$s" link set "${s}-${name}" up
}

add_host lana swa 11 10.1.0.2/24
add_host lanb swb 12 10.2.0.2/24

for r in ra rb; do
  ip netns add $r
  ip -n $r link set lo up
  ip netns exec $r sh -c "echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6"
  ip netns exec $r sh -c "echo 1 > /proc/sys/net/ipv4/ip_forward"
done

add_host ra swa 21 10.1.0.1/24
add_host ra swm 22 198.51.100.1/24
add_host rb swb 31 10.2.0.1/24
add_host rb swm 32 198.51.100.2/24

ip -n lana route add default via 10.1.0.1
ip -n lanb route add default via 10.2.0.1
