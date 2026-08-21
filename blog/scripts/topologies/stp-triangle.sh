# Three switches wired in a loop, which is fatal without spanning tree.
#
#         sw1 ------- sw2
#          \           /
#           \         /
#            \-- sw3 /
#
#   h1 on sw1, h2 on sw2, both in 10.0.0.0/24
#
# Every switch is connected to both others, so a broadcast has a path back to
# where it started. Without spanning tree that frame circulates until the
# network stops, which is a genuinely fatal failure rather than a slow one.
#
# STP is on here, because a Linux bridge runs it when told to, elects a root,
# and puts one port into blocking. That means the exam's port roles and states
# are readable out of `bridge link show` rather than described.
#
# Bridge priorities are set explicitly and sw2 is given the lowest, so the root
# election has a predictable winner and the page can show why. Left to default,
# all three would tie on priority and the election would fall through to the MAC
# address, which differs on every run.
NETLAB_PACKAGES="iproute2 iputils-ping tcpdump"
NETLAB_SETTLE=40

for s in sw1 sw2 sw3; do
  ip netns add $s
  ip -n $s link set lo up
  ip netns exec $s sh -c "echo 1 > /proc/sys/net/ipv6/conf/default/disable_ipv6"
  ip netns exec $s sh -c "echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6"
  ip -n $s link add br0 type bridge stp_state 1
  ip -n $s link set br0 up
done

# A bridge id is a priority followed by a MAC address, and the kernel gives a
# bridge a random one. That would change the id printed on the page every run,
# so each bridge gets a fixed address as well as a fixed priority.
ip -n sw1 link set br0 address 02:00:00:00:01:00
ip -n sw2 link set br0 address 02:00:00:00:02:00
ip -n sw3 link set br0 address 02:00:00:00:03:00

# a predictable election: lower priority wins, so sw2 becomes root
ip -n sw1 link set br0 type bridge priority 32768
ip -n sw2 link set br0 type bridge priority 4096
ip -n sw3 link set br0 type bridge priority 40960

link() {
  a=$1; b=$2
  ip link add ${a}-${b} type veth peer name ${b}-${a}
  ip link set ${a}-${b} netns $a
  ip link set ${b}-${a} netns $b
  ip -n $a link set ${a}-${b} master br0
  ip -n $b link set ${b}-${a} master br0
  ip -n $a link set ${a}-${b} up
  ip -n $b link set ${b}-${a} up
}
link sw1 sw2
link sw2 sw3
link sw1 sw3

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
