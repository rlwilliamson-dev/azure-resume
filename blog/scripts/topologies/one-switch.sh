# Three hosts on one switch.
#
#         h1        h2        h3
#      .1 |      .2 |      .3 |
#         +----- br0 in sw ---+
#              10.0.0.0/24
#
# A Linux bridge is a switch and not a simulation of one. It learns source MAC
# addresses into a forwarding database, floods a frame whose destination it has
# not learned, ages entries out, and can run spanning tree and filter VLANs. So
# the switching behaviour the exam tests is observable here rather than drawn.
#
# The bridge lives in its own namespace so that `bridge fdb show` is something
# you run on the switch, the way you would on real equipment, rather than on a
# host that happens to be bridging.
#
# Fixed MAC addresses, and the last octet is the host number. A forwarding table
# is a list of MAC addresses, so a table full of kernel-generated random ones
# would be unreadable on the page and different on every run.
# IPv6 is switched off on every node here, which is the one unusual thing about
# this topology. A switch learns from any frame it sees, and IPv6 brings up an
# interface talking: duplicate address detection and multicast listener reports
# go out before anything has been asked to send anything. The forwarding table
# was fully populated before the first ping, which makes learning impossible to
# observe. A silent wire is what lets the reader watch an empty table fill.
NETLAB_PACKAGES="iproute2 iputils-ping tcpdump"
NETLAB_SETTLE=1

ip netns add sw
ip -n sw link set lo up
ip netns exec sw sh -c "echo 1 > /proc/sys/net/ipv6/conf/default/disable_ipv6"
ip netns exec sw sh -c "echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6"
ip -n sw link add br0 type bridge
ip -n sw link set br0 up

for n in 1 2 3; do
  ip netns add h$n
  ip -n h$n link set lo up
  ip netns exec h$n sh -c "echo 1 > /proc/sys/net/ipv6/conf/default/disable_ipv6"
  ip netns exec h$n sh -c "echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6"

  ip link add h${n}eth0 type veth peer name sw-h$n
  ip link set h${n}eth0 netns h$n
  ip link set sw-h$n netns sw

  ip -n h$n link set h${n}eth0 address 02:00:00:00:00:0$n
  ip -n h$n addr add 10.0.0.$n/24 dev h${n}eth0
  ip -n h$n link set h${n}eth0 up

  ip -n sw link set sw-h$n master br0
  ip -n sw link set sw-h$n up
done
