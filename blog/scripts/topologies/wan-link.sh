# Two sites with one constrained link between them, and two hosts sharing it.
#
#   h1 10.0.1.2 --\
#                  r1 ==== the link everything crosses ==== r2 --- h2 10.0.2.2
#   h3 10.0.1.3 --/   10.0.12.1                   10.0.12.2
#
# One bottleneck, on purpose. Every performance fault in this block is a
# statement about one link somewhere being the narrowest thing on a path, so the
# topology gives that link a name and puts two hosts behind it, which is what
# makes contention observable rather than described.
#
# Nothing is impaired here. Rate limits, delay, jitter and loss are applied in
# the captured commands with tc, so the reader watches the constraint being
# created and can see exactly what produced the number underneath it. A topology
# that shipped pre-throttled would hide the one thing worth showing.
#
# iperf3 is installed because throughput, jitter and loss are measurements rather
# than opinions, and it reports all three. The server runs on h2 and is started
# per capture rather than here, so a transcript shows it starting.
#
# The link between the routers is a /30, which is what routers get between each
# other. The two LAN hosts are on one /24 behind r1 so they share the path.
NETLAB_PACKAGES="iproute2 iputils-ping traceroute tcpdump iperf3 procps"
NETLAB_SETTLE=1

for r in r1 r2; do
  ip netns add $r
  ip -n $r link set lo up
  ip netns exec $r sh -c "echo 1 > /proc/sys/net/ipv4/ip_forward"
done

# the link between the two routers, which is the one that gets constrained
ip link add r1-r2 type veth peer name r2-r1
ip link set r1-r2 netns r1
ip link set r2-r1 netns r2
ip -n r1 addr add 10.0.12.1/30 dev r1-r2
ip -n r2 addr add 10.0.12.2/30 dev r2-r1
ip -n r1 link set r1-r2 up
ip -n r2 link set r2-r1 up

# a lan behind each router. r1 gets a bridge because it has two hosts on it
ip netns add sw1
ip -n sw1 link set lo up
ip -n sw1 link add br0 type bridge
ip -n sw1 link set br0 up

ip link add r1-sw1 type veth peer name sw1-r1
ip link set r1-sw1 netns r1
ip link set sw1-r1 netns sw1
ip -n r1 addr add 10.0.1.1/24 dev r1-sw1
ip -n r1 link set r1-sw1 up
ip -n sw1 link set sw1-r1 master br0
ip -n sw1 link set sw1-r1 up

# name, last octet. the router already holds .1, so the hosts start at .2
lan_host() {
  h=$1; last=$2
  ip netns add $h
  ip -n $h link set lo up
  ip link add ${h}eth0 type veth peer name sw1-$h
  ip link set ${h}eth0 netns $h
  ip link set sw1-$h netns sw1
  ip -n $h link set ${h}eth0 address "02:00:00:00:00:0$last"
  ip -n $h addr add 10.0.1.$last/24 dev ${h}eth0
  ip -n $h link set ${h}eth0 up
  ip -n $h route add default via 10.0.1.1
  ip -n sw1 link set sw1-$h master br0
  ip -n sw1 link set sw1-$h up
}
lan_host h1 2
lan_host h3 3

ip netns add h2
ip -n h2 link set lo up
ip link add h2eth0 type veth peer name r2-h2
ip link set h2eth0 netns h2
ip link set r2-h2 netns r2
ip -n h2 link set h2eth0 address 02:00:00:00:00:22
ip -n h2 addr add 10.0.2.2/24 dev h2eth0
ip -n r2 addr add 10.0.2.1/24 dev r2-h2
ip -n h2 link set h2eth0 up
ip -n r2 link set r2-h2 up
ip -n h2 route add default via 10.0.2.1

ip -n r1 route add 10.0.2.0/24 via 10.0.12.2
ip -n r2 route add 10.0.1.0/24 via 10.0.12.1
