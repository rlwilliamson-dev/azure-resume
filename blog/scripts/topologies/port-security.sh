# A switch port that admits one MAC address, and an attacker who reads the one it
# wants off the wire and puts it on.
#
#   good 02:..:0d --- sw --- srv 10.0.0.1   (a protected server)
#   atk  02:..:66 ----+
#
# The switch is told to accept frames from the known-good address on the
# attacker's port and drop the rest. That is MAC filtering, and it is on the exam
# as a control worth naming and then not relying on. A MAC address is not a
# secret: it is in every frame the legitimate device sends, in clear, and an
# attacker on the segment reads it and sets its own interface to match. The filter
# then admits the attacker because, as far as the switch can tell, it is the
# device on the allow list.
#
# The filter is written with nftables in the bridge family, which is where a Linux
# host does this. A real managed switch calls the same idea port security and
# enforces it in hardware, but the mechanism and the weakness are identical.
NETLAB_PACKAGES="iproute2 iputils-ping nftables"
NETLAB_SETTLE=1

ip netns add sw
ip -n sw link set lo up
ip netns exec sw sh -c "echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6"
ip -n sw link add br0 type bridge
ip -n sw link set br0 up

add_host() {
  name=$1; nn=$2; addr=$3
  ip netns add "$name" 2>/dev/null || true
  ip -n "$name" link set lo up
  ip netns exec "$name" sh -c "echo 1 > /proc/sys/net/ipv6/conf/default/disable_ipv6"
  ip netns exec "$name" sh -c "echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6"
  ip link add "${name}0" type veth peer name "sw-${name}"
  ip link set "${name}0" netns "$name"
  ip link set "sw-${name}" netns sw
  ip -n "$name" link set "${name}0" address "02:00:00:00:00:$nn"
  ip -n "$name" addr add "$addr" dev "${name}0"
  ip -n "$name" link set "${name}0" up
  ip -n sw link set "sw-${name}" master br0
  ip -n sw link set "sw-${name}" up
}

add_host srv 01 10.0.0.1/24
add_host atk 66 10.0.0.66/24

# Port security on the attacker's port: only the known-good MAC may send through
# it. Everything else is dropped, which is the intended control working exactly
# as configured.
ip netns exec sw nft -f - <<'NFT'
table bridge portsec {
  chain guard {
    type filter hook forward priority -200; policy accept;
    iifname "sw-atk" ether saddr != 02:00:00:00:00:0d drop
  }
}
NFT
