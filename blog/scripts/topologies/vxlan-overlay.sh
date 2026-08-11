# One layer 2 segment carried across a routed network.
#
#   h1 ......... overlay 10.200.0.0/24 ......... h2
#      \                                        /
#       +-- underlay 192.168.100.0/24 via r ---+
#          .1        .1  |  .2        .2
#
# h1 and h2 have overlay addresses on a vxlan interface and believe they are on
# one segment. They are not adjacent: everything between them is routed, and the
# router in the middle has no idea the overlay exists. It sees UDP.
#
# That is the whole point of an overlay, and it is also where the byte cost
# comes from, because every inner frame is carried inside an outer one.
#
# 192.168.100.0/24 and 10.200.0.0/24 are both private ranges, so nothing here
# names a real network.
NETLAB_PACKAGES="iproute2 iputils-ping tcpdump"
NETLAB_SETTLE=3

for ns in h1 h2 r; do
  ip netns add $ns
  ip -n $ns link set lo up
done
ip netns exec r sh -c "echo 1 > /proc/sys/net/ipv4/ip_forward"

# The underlay: two point to point links through a router, so the two hosts are
# genuinely not on the same segment and a broadcast from one cannot reach the
# other by any layer 2 path.
ip link add h1eth0 type veth peer name r-h1
ip link set h1eth0 netns h1
ip link set r-h1 netns r
ip -n h1 addr add 192.168.100.1/24 dev h1eth0
ip -n h1 link set h1eth0 up
ip -n r addr add 192.168.100.254/24 dev r-h1
ip -n r link set r-h1 up

ip link add h2eth0 type veth peer name r-h2
ip link set h2eth0 netns h2
ip link set r-h2 netns r
ip -n h2 addr add 192.168.200.2/24 dev h2eth0
ip -n h2 link set h2eth0 up
ip -n r addr add 192.168.200.254/24 dev r-h2
ip -n r link set r-h2 up

ip -n h1 route add 192.168.200.0/24 via 192.168.100.254
ip -n h2 route add 192.168.100.0/24 via 192.168.200.254

# The overlay: a vxlan interface at each end, addressed as though the two hosts
# shared a segment. dstport 4789 is the assigned VXLAN port; Linux defaults to
# its own historical choice unless told otherwise, so it is set explicitly.
ip -n h1 link add vx0 type vxlan id 100 remote 192.168.200.2 local 192.168.100.1 dstport 4789 dev h1eth0
ip -n h1 addr add 10.200.0.1/24 dev vx0
ip -n h1 link set vx0 address 02:00:00:00:aa:01
ip -n h1 link set vx0 up

ip -n h2 link add vx0 type vxlan id 100 remote 192.168.100.1 local 192.168.200.2 dstport 4789 dev h2eth0
ip -n h2 addr add 10.200.0.2/24 dev vx0
ip -n h2 link set vx0 address 02:00:00:00:aa:02
ip -n h2 link set vx0 up
