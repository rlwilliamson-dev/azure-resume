# Two senders, one router, and a link narrow enough to queue.
#
#   h1 ----------\
#   10.0.1.2/24   \
#                  r1 ------------- h2
#   h3 ----------/  .1        .1    10.0.2.2/24
#   10.0.3.2/24        10.0.2.0/24
#                       the narrow one
#
# Quality of service does nothing until there is more traffic than a link can
# carry, so a topology for it has to be able to produce that state on demand.
# Two independent senders reach one destination through r1, and everything they
# send leaves by r1eth1. Rate limit that one interface and the queue is real:
# packets wait, and which of them waits is a decision somebody configured.
#
# The limit is not applied here. A topic applies it in the captured command, so
# the reader sees the qdisc go on rather than being handed a network that is
# already slow and asked to believe why.
#
# MAC addresses encode the segment, as in one-router.sh: 02:00:0N:.. is the
# 10.0.N.0/24 segment and the last octet is the host part.
NETLAB_PACKAGES="iproute2 iputils-ping tcpdump"
NETLAB_SETTLE=0

for ns in h1 h3 r1 h2; do ip netns add $ns; ip -n $ns link set lo up; done

# h1 to r1
ip link add h1eth0 type veth peer name r1eth0
ip link set h1eth0 netns h1
ip link set r1eth0 netns r1
ip -n h1 link set h1eth0 address 02:00:01:00:00:02
ip -n r1 link set r1eth0 address 02:00:01:00:00:01

# h3 to r1
ip link add h3eth0 type veth peer name r1eth2
ip link set h3eth0 netns h3
ip link set r1eth2 netns r1
ip -n h3 link set h3eth0 address 02:00:03:00:00:02
ip -n r1 link set r1eth2 address 02:00:03:00:00:01

# r1 to h2, the link everything has to leave by
ip link add r1eth1 type veth peer name h2eth0
ip link set r1eth1 netns r1
ip link set h2eth0 netns h2
ip -n r1 link set r1eth1 address 02:00:02:00:00:01
ip -n h2 link set h2eth0 address 02:00:02:00:00:02

ip -n h1 addr add 10.0.1.2/24 dev h1eth0
ip -n h3 addr add 10.0.3.2/24 dev h3eth0
ip -n r1 addr add 10.0.1.1/24 dev r1eth0
ip -n r1 addr add 10.0.3.1/24 dev r1eth2
ip -n r1 addr add 10.0.2.1/24 dev r1eth1
ip -n h2 addr add 10.0.2.2/24 dev h2eth0

for l in "h1 h1eth0" "h3 h3eth0" "r1 r1eth0" "r1 r1eth1" "r1 r1eth2" "h2 h2eth0"; do
  set -- $l; ip -n $1 link set $2 up
done

ip -n h1 route add default via 10.0.1.1
ip -n h3 route add default via 10.0.3.1
ip -n h2 route add default via 10.0.2.1

ip netns exec r1 sh -c "echo 1 > /proc/sys/net/ipv4/ip_forward"
