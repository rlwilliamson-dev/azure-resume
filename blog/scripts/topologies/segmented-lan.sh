# Three segments off one router, so segmentation is a boundary you can watch a
# packet fail to cross rather than a diagram.
#
#   pay  10.10.0.9 --- swp --- rtr --- swi --- iot 10.20.0.9
#   payment segment       .1 | | .1       iot segment
#                            .1| |.1
#                         swc --- --- sww
#                          |           |
#                   corp 10.30.0.9   wan 203.0.113.9
#                   corp segment     the internet stand-in
#
# Each bridge is one segment, which is one broadcast domain and one subnet. The
# router carries a leg on each and forwards between them, and nftables on the
# router is the enforcement: the payment segment may be reached from corp and
# from nowhere else, every segment may reach the wan, and the default is drop.
#
# The vending machine in the zero hook is the iot host. It has a route to the
# payment host and the payment host has a route back, so nothing about addressing
# stops them talking. The segment boundary does, and that is the whole point:
# reachability is a policy on the router, not a property of the wiring.
#
# 203.0.113.0/24 is TEST-NET-3 from RFC 5737, standing in for the internet so a
# reader can see that a segmented device still has the access it is supposed to.
NETLAB_PACKAGES="iproute2 iputils-ping nftables tcpdump"
NETLAB_SETTLE=1

for s in swp swi swc sww; do
  ip netns add $s
  ip -n $s link set lo up
  ip netns exec $s sh -c "echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6"
  ip -n $s link add br0 type bridge
  ip -n $s link set br0 up
done

add_host() {
  name=$1; s=$2; nn=$3; addr=$4; gw=$5
  ip netns add "$name" 2>/dev/null || true
  ip -n "$name" link set lo up
  ip netns exec "$name" sh -c "echo 1 > /proc/sys/net/ipv6/conf/default/disable_ipv6"
  ip netns exec "$name" sh -c "echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6"
  # Answer directed broadcasts, so a broadcast ping shows who shares the segment.
  # Off by default on Linux, which would make the segment look empty.
  ip netns exec "$name" sh -c "echo 0 > /proc/sys/net/ipv4/icmp_echo_ignore_broadcasts"
  ip link add "${name}-${s}" type veth peer name "${s}-${name}"
  ip link set "${name}-${s}" netns "$name"
  ip link set "${s}-${name}" netns "$s"
  ip -n "$name" link set "${name}-${s}" address "02:00:00:00:00:$nn"
  ip -n "$name" addr add "$addr" dev "${name}-${s}"
  ip -n "$name" link set "${name}-${s}" up
  ip -n "$s" link set "${s}-${name}" master br0
  ip -n "$s" link set "${s}-${name}" up
  if [ -n "$gw" ]; then
    ip -n "$name" route add default via "$gw"
  fi
}

add_host pay  swp 09 10.10.0.9/24  10.10.0.1
add_host iot  swi 19 10.20.0.9/24  10.20.0.1
add_host iot2 swi 1a 10.20.0.99/24 10.20.0.1
add_host corp swc 29 10.30.0.9/24  10.30.0.1
add_host wan  sww 39 203.0.113.9/24 203.0.113.1

# The router. One leg on each segment, forwarding on, and no address translation,
# so a dropped packet is dropped by policy and nothing else.
ip netns add rtr
ip -n rtr link set lo up
ip netns exec rtr sh -c "echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6"
ip netns exec rtr sh -c "echo 1 > /proc/sys/net/ipv4/ip_forward"

add_host rtr swp 11 10.10.0.1/24  ""
add_host rtr swi 12 10.20.0.1/24  ""
add_host rtr swc 13 10.30.0.1/24  ""
add_host rtr sww 14 203.0.113.1/24 ""

# The enforcement, written as a filter a reader can print. The default on the
# forward path is drop, replies to allowed traffic come back, corp may open a
# connection to payment, and every segment may reach the wan. Nothing permits
# iot to reach payment, so the boundary holds without a rule naming it, which is
# the implicit deny from topic 54 doing the work.
ip netns exec rtr nft -f - <<'NFT'
table inet seg {
  chain forward {
    type filter hook forward priority 0; policy drop;
    ct state established,related accept
    ip saddr 10.30.0.0/24 ip daddr 10.10.0.0/24 accept comment "corp may reach payment"
    ip daddr 203.0.113.0/24 accept comment "any segment may reach the internet"
  }
}
NFT
