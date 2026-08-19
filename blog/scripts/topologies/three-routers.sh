# Three routers in a triangle, with a host behind two of them.
#
#     h1 --- r1 =============== r2 --- h2
#   10.0.1.2  \  10.0.12.0/30  /  10.0.2.2
#              \             /
#      10.0.13.0/30    10.0.23.0/30
#                \   /
#                 r3
#
# Two paths from r1 to r2: the direct link, and the long way round through r3.
# That is what makes route selection observable. A static route via r3 and a
# static route via r2 compete for the same destination, and the table shows
# which one won and why.
#
# The point to point links are /30s, which is what routers between each other
# get in the real world and what topic 06's arithmetic produces.
#
# IPv6 stays on here, unlike the switching topologies. Nothing on these pages
# depends on a silent wire, and the routing tables are the interesting output.
NETLAB_PACKAGES="iproute2 iputils-ping tcpdump traceroute nftables"
NETLAB_SETTLE=2

for r in r1 r2 r3; do
  ip netns add $r
  ip -n $r link set lo up
  ip netns exec $r sh -c "echo 1 > /proc/sys/net/ipv4/ip_forward"
done

# a point to point link between two routers, on 10.0.<ab>.0/30
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
plink r1 r3 13
plink r2 r3 23

# a host behind r1 and a host behind r2
n=1
for r in r1 r2; do
  ip netns add h$n
  ip -n h$n link set lo up
  ip link add h${n}eth0 type veth peer name ${r}-h$n
  ip link set h${n}eth0 netns h$n
  ip link set ${r}-h$n netns $r
  ip -n h$n link set h${n}eth0 address 02:00:00:00:0${n}:02
  ip -n h$n addr add 10.0.$n.2/24 dev h${n}eth0
  ip -n $r addr add 10.0.$n.1/24 dev ${r}-h$n
  ip -n h$n link set h${n}eth0 up
  ip -n $r link set ${r}-h$n up
  ip -n h$n route add default via 10.0.$n.1
  n=$((n+1))
done
