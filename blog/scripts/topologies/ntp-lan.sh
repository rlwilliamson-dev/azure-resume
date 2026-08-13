# A three level time hierarchy, so stratum is a number that gets counted rather
# than a definition to memorise.
#
#   ref 10.0.0.1 ---- mid 10.0.0.2 ---- leaf 10.0.0.3
#   stratum 5          stratum 6         stratum 7
#     |                   |                 |
#     +------------------ sw1 --------------+
#
# ref pretends to hold a reference clock. Its chrony is told `local stratum 5`,
# which means it will serve time claiming that stratum without having a real
# source, and that is the only fiction in the topology. Everything below it is
# genuine: mid synchronises to ref and ends up one stratum lower, leaf
# synchronises to mid and ends up one lower again, and the numbers in a capture
# are counted by the software rather than configured by hand.
#
# Stratum 5 rather than 1 for the top, so that the arithmetic is visibly
# relative. A reader who sees 5, 6, 7 is less likely to think the number means
# quality than one who sees 1, 2, 3.
NETLAB_PACKAGES="iproute2 iputils-ping tcpdump chrony openssl ca-certificates"
NETLAB_SETTLE=2

ip netns add sw1
ip -n sw1 link set lo up
ip netns exec sw1 sh -c "echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6"
ip -n sw1 link add br0 type bridge
ip -n sw1 link set br0 up

add_host() {
  name=$1; nn=$2
  ip netns add "$name"
  ip -n "$name" link set lo up
  ip netns exec "$name" sh -c "echo 1 > /proc/sys/net/ipv6/conf/default/disable_ipv6"
  ip netns exec "$name" sh -c "echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6"
  ip link add "${name}0" type veth peer name "sw1-${name}"
  ip link set "${name}0" netns "$name"
  ip link set "sw1-${name}" netns sw1
  ip -n "$name" link set "${name}0" address "02:00:00:00:00:$nn"
  ip -n "$name" addr add "10.0.0.$nn/24" dev "${name}0"
  ip -n "$name" link set "${name}0" up
  ip -n sw1 link set "sw1-${name}" master br0
  ip -n sw1 link set "sw1-${name}" up
}

add_host ref 01
add_host mid 02
add_host leaf 03

# chrony needs its own state directory per node, because every node here is one
# machine as far as the software is concerned and they share a filesystem.
setup_chrony() {
  node=$1; addr=$2; conf=$3
  ip netns exec "$node" sh -c "mkdir -p /var/lib/chrony-$node /run/chrony-$node && cat > /etc/chrony-$node.conf <<CONF
$conf
driftfile /var/lib/chrony-$node/drift
pidfile /run/chrony-$node/chronyd.pid
allow 10.0.0.0/24
bindcmdaddress $addr
cmdallow 10.0.0.0/24
CONF"
}

# The top of the hierarchy. `local stratum 5` makes it willing to serve time
# from its own clock rather than refusing until it has a source of its own.
setup_chrony ref 10.0.0.1 'local stratum 5'
setup_chrony mid 10.0.0.2 'server 10.0.0.1 iburst minpoll 0 maxpoll 2'
setup_chrony leaf 10.0.0.3 'server 10.0.0.2 iburst minpoll 0 maxpoll 2'

for node in ref mid leaf; do
  ip netns exec "$node" chronyd -u root -f "/etc/chrony-$node.conf" >/dev/null 2>&1
done

# Synchronisation is not instant. chrony needs several exchanges before it will
# claim to be synchronised, and minpoll 0 above is what makes that take seconds
# rather than minutes.
sleep 12
