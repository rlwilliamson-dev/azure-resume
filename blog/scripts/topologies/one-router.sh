# Two hosts on different networks, with a router between them.
#
#   h1 ---------- r1 ---------- h2
#   10.0.1.2/24   .1      .1    10.0.2.2/24
#     10.0.1.0/24     10.0.2.0/24
#
# The smallest network with a routing decision in it. Two segments, so the
# frames on the left are a different conversation from the frames on the right,
# which is the point topic 02 is making: the IP addresses survive the trip and
# the MAC addresses do not.
#
# Fixed MAC addresses throughout, and they encode where they are. 02:00:01:..
# is the 10.0.1.0/24 segment, 02:00:02:.. is the 10.0.2.0/24 segment, and the
# last octet is the host part of the address. A reader comparing two captures
# can then tell at a glance which side of the router a frame came from, which a
# random kernel-generated MAC would make impossible.
NETLAB_PACKAGES="iproute2 iputils-ping tcpdump traceroute netcat-openbsd"
NETLAB_SETTLE=0

for ns in h1 r1 h2; do ip netns add $ns; ip -n $ns link set lo up; done

# left segment: h1 to r1
ip link add h1eth0 type veth peer name r1eth0
ip link set h1eth0 netns h1
ip link set r1eth0 netns r1
ip -n h1 link set h1eth0 address 02:00:01:00:00:02
ip -n r1 link set r1eth0 address 02:00:01:00:00:01

# right segment: r1 to h2
ip link add r1eth1 type veth peer name h2eth0
ip link set r1eth1 netns r1
ip link set h2eth0 netns h2
ip -n r1 link set r1eth1 address 02:00:02:00:00:01
ip -n h2 link set h2eth0 address 02:00:02:00:00:02

ip -n h1 addr add 10.0.1.2/24 dev h1eth0
ip -n r1 addr add 10.0.1.1/24 dev r1eth0
ip -n r1 addr add 10.0.2.1/24 dev r1eth1
ip -n h2 addr add 10.0.2.2/24 dev h2eth0

ip -n h1 link set h1eth0 up
ip -n r1 link set r1eth0 up
ip -n r1 link set r1eth1 up
ip -n h2 link set h2eth0 up

# Each host knows only its own segment, so anything else goes to the router.
ip -n h1 route add default via 10.0.1.1
ip -n h2 route add default via 10.0.2.1

# Without this the router has two interfaces and refuses to forward between
# them, which is the kernel being safe rather than the topology being wrong.
ip netns exec r1 sh -c "echo 1 > /proc/sys/net/ipv4/ip_forward"
