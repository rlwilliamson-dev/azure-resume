# The same triangle as three-routers, with OSPF actually running on it.
#
# FRRouting is a real routing stack. zebra owns the kernel routing table and
# ospfd speaks the protocol, so the adjacencies, the link state database and the
# routes on this topology are produced by an implementation rather than written
# out by hand.
#
# Each router advertises its own connected networks and learns the rest. Nothing
# has a static route, which is the point: pull a link and the others reconverge
# without anybody typing anything.
NETLAB_PACKAGES="iproute2 iputils-ping tcpdump traceroute frr"
NETLAB_SETTLE=25

for r in r1 r2 r3; do
  ip netns add $r
  ip -n $r link set lo up
  ip netns exec $r sh -c "echo 1 > /proc/sys/net/ipv4/ip_forward"
done

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

n=1
for r in r1 r2; do
  ip netns add h$n
  ip -n h$n link set lo up
  ip link add h${n}eth0 type veth peer name ${r}-h$n
  ip link set h${n}eth0 netns h$n
  ip link set ${r}-h$n netns $r
  ip -n h$n addr add 10.0.$n.2/24 dev h${n}eth0
  ip -n $r addr add 10.0.$n.1/24 dev ${r}-h$n
  ip -n h$n link set h${n}eth0 up
  ip -n $r link set ${r}-h$n up
  ip -n h$n route add default via 10.0.$n.1
  n=$((n+1))
done

# a router id each, so the output names routers predictably rather than by
# whichever address the daemon happened to pick
i=1
for r in r1 r2 r3; do
  mkdir -p /etc/frr-$r /var/run/frr-$r
  chown frr:frr /var/run/frr-$r 2>/dev/null || true
  # The links between routers are /30s with exactly two devices on them, so
  # they are told to run OSPF as point to point. Left as the default broadcast
  # type, every router elects itself DROther, adjacencies stop at 2-Way and no
  # routes are ever exchanged.
  cat > /etc/frr-$r/frr.conf <<CONF
frr defaults traditional
hostname $r
interface ${r}-r1
 ip ospf network point-to-point
interface ${r}-r2
 ip ospf network point-to-point
interface ${r}-r3
 ip ospf network point-to-point
router ospf
 ospf router-id 10.10.10.$i
 network 10.0.0.0/8 area 0
CONF
  chown -R frr:frr /etc/frr-$r 2>/dev/null || true
  ip netns exec $r /usr/lib/frr/zebra -d -f /etc/frr-$r/frr.conf -i /var/run/frr-$r/zebra.pid -z /var/run/frr-$r/zserv.api --vty_socket /var/run/frr-$r > /dev/null 2>&1
  ip netns exec $r /usr/lib/frr/ospfd -d -f /etc/frr-$r/frr.conf -i /var/run/frr-$r/ospfd.pid -z /var/run/frr-$r/zserv.api --vty_socket /var/run/frr-$r > /dev/null 2>&1
  i=$((i+1))
done
