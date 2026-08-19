# Three switches, no spanning tree, and a third cable left unplugged.
#
#         sw1 ------- sw2
#          \           /
#           \         /            the sw1 to sw3 cable exists and is DOWN
#            \-- sw3 /
#
#   h1 on sw1, h2 on sw2, both in 10.0.0.0/24
#
# The same triangle as stp-triangle.sh with one difference that changes
# everything: no bridge here runs spanning tree. Two of the three cables are up,
# which is a working network with no loop in it, and the third is built and left
# down so that a capture can plug it in and the reader watches the loop being
# created rather than being handed one.
#
# That ordering matters. A topology that boots into a broadcast storm cannot
# show the before, and the before is half the point: these are three healthy
# switches until one more cable arrives.
#
# Why the port cannot simply be unblocked on stp-triangle.sh instead: the kernel
# keeps a port that spanning tree put into blocking in that state even after
# stp_state is set to 0, and `bridge link set state forwarding` does not move it.
# So a loop with nothing watching it needs a bridge that never ran the protocol.
#
# Fixed MAC addresses, last octet is the host number, for the same reason as the
# other switching topologies: a forwarding table full of random addresses is
# unreadable. IPv6 is off so the wire is silent until something is sent, which
# is what makes a single broadcast countable.
NETLAB_PACKAGES="iproute2 iputils-ping tcpdump"
NETLAB_SETTLE=1

for s in sw1 sw2 sw3; do
  ip netns add $s
  ip -n $s link set lo up
  ip netns exec $s sh -c "echo 1 > /proc/sys/net/ipv6/conf/default/disable_ipv6"
  ip netns exec $s sh -c "echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6"
  ip -n $s link add br0 type bridge stp_state 0
  ip -n $s link set br0 up
done

ip -n sw1 link set br0 address 02:00:00:00:01:00
ip -n sw2 link set br0 address 02:00:00:00:02:00
ip -n sw3 link set br0 address 02:00:00:00:03:00

# up=1 brings the cable up, up=0 builds it and leaves it down
link() {
  a=$1; b=$2; up=$3
  ip link add ${a}-${b} type veth peer name ${b}-${a}
  ip link set ${a}-${b} netns $a
  ip link set ${b}-${a} netns $b
  ip -n $a link set ${a}-${b} master br0
  ip -n $b link set ${b}-${a} master br0
  if [ "$up" = 1 ]; then
    ip -n $a link set ${a}-${b} up
    ip -n $b link set ${b}-${a} up
  fi
}
link sw1 sw2 1
link sw2 sw3 1
link sw1 sw3 0

n=1
for s in sw1 sw2; do
  ip netns add h$n
  ip -n h$n link set lo up
  ip netns exec h$n sh -c "echo 1 > /proc/sys/net/ipv6/conf/default/disable_ipv6"
  ip netns exec h$n sh -c "echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6"
  ip link add h${n}eth0 type veth peer name ${s}-h$n
  ip link set h${n}eth0 netns h$n
  ip link set ${s}-h$n netns $s
  ip -n h$n link set h${n}eth0 address 02:00:00:00:00:0$n
  ip -n h$n addr add 10.0.0.$n/24 dev h${n}eth0
  ip -n h$n link set h${n}eth0 up
  ip -n $s link set ${s}-h$n master br0
  ip -n $s link set ${s}-h$n up
  n=$((n+1))
done
