# A straight line of three routers, so a hop is a number that counts up and a
# fault has a place to hide.
#
#   h1 10.0.1.2 --- r1 --- r2 --- r3 --- h2 10.0.4.2
#            .1   .12 .12  .23 .23  .34   .1
#
# Four hops from h1 to h2: r1, r2, r3, then h2. Full static routing in both
# directions, so the path works and traceroute prints every step of it. The
# faults this topic needs are not built in; each capture creates its own in the
# command, so the reader sees the break being made rather than being handed a
# broken network and told to trust it.
#
# The point-to-point links between routers are /30s, which is what routers get
# between each other and what topic 06's arithmetic produces. h2 runs a web
# server, so "the service works" can be shown rather than asserted while ping to
# the same host fails.
NETLAB_PACKAGES="iproute2 iputils-ping traceroute tcpdump iptables python3 curl"
NETLAB_SETTLE=1

for r in r1 r2 r3; do
  ip netns add $r
  ip -n $r link set lo up
  ip netns exec $r sh -c "echo 1 > /proc/sys/net/ipv4/ip_forward"
done

# a point-to-point link between two routers on 10.0.<ab>.0/30
plink() {
  a=$1; b=$2; net=$3
  ip link add ${a}-${b} type veth peer name ${b}-${a}
  ip link set ${a}-${b} netns $a
  ip link set ${b}-${a} netns $b
  ip -n $a addr add 10.0.$net.1/30 dev ${a}-${b}
  ip -n $b addr add 10.0.$net.2/30 dev ${b}-${a}
  ip -n $a link set ${a}-${b} up
  ip -n $b link set ${b}-${a} up
}
plink r1 r2 12
plink r2 r3 23

# a host on a /24 behind an end router
hlink() {
  h=$1; r=$2; net=$3; nn=$4
  ip netns add $h
  ip -n $h link set lo up
  ip link add ${h}-${r} type veth peer name ${r}-${h}
  ip link set ${h}-${r} netns $h
  ip link set ${r}-${h} netns $r
  ip -n $h link set ${h}-${r} address "02:00:00:00:0${nn}:02"
  ip -n $h addr add 10.0.$net.2/24 dev ${h}-${r}
  ip -n $r addr add 10.0.$net.1/24 dev ${r}-${h}
  ip -n $h link set ${h}-${r} up
  ip -n $r link set ${r}-${h} up
  ip -n $h route add default via 10.0.$net.1
}
hlink h1 r1 1 1
hlink h2 r3 4 2

# Static routes, written both ways so the path is symmetric and traceroute has
# something to count. Each router learns the far end through its neighbour.
ip -n r1 route add 10.0.23.0/30 via 10.0.12.2
ip -n r1 route add 10.0.4.0/24  via 10.0.12.2
ip -n r2 route add 10.0.1.0/24  via 10.0.12.1
ip -n r2 route add 10.0.4.0/24  via 10.0.23.2
ip -n r3 route add 10.0.12.0/30 via 10.0.23.1
ip -n r3 route add 10.0.1.0/24  via 10.0.23.1

# h2's web server, so a working service can be shown next to a failing ping.
ip netns exec h2 sh -c "cd /tmp && python3 -m http.server 8000 >/dev/null 2>&1 &"
