# A router advertising a prefix, and three hosts that build addresses from it
# in three different ways.
#
#   h1 (kernel default)   h2 (EUI-64)   h3 (privacy extension)
#    |                     |             |
#    +--------- sw1 -------+-------------+
#               |
#              r1  2001:db8:1::1/64, radvd advertising 2001:db8:1::/64
#
# Nobody configures a global address on any host here. That is the point: the
# router says what the prefix is, and each host decides for itself what the
# second half of its address will be. The three hosts differ only in that
# decision, which is what makes the difference visible in one capture.
#
#   h1  addr_gen_mode 2, stable privacy: an opaque interface identifier derived
#       from the prefix and a per-machine secret, which is what a desktop
#       distribution configures through its network manager
#   h2  addr_gen_mode 0, the EUI-64 scheme the exam describes, where the
#       interface identifier is the MAC with ff:fe inserted and one bit flipped
#   h3  EUI-64 plus use_tempaddr 2, which adds a second global address that is
#       regenerated periodically and preferred for outbound connections
#
# Both modes are set explicitly rather than left to the default, because the
# default varies: a bare kernel namespace generates EUI-64 and a desktop
# distribution usually does not. Setting both is what puts the two schemes side
# by side in one capture.
#
# 2001:db8::/32 is the documentation prefix from RFC 3849, so nothing here names
# a real network.
#
# The router advertises with the other-configuration flag set and the managed
# flag clear, which is the combination that says "addresses from me, everything
# else from DHCPv6". Reading those two bits off a capture is the examinable
# skill, and setting them here is what makes that possible.
NETLAB_PACKAGES="iproute2 iputils-ping tcpdump radvd ndisc6"
NETLAB_SETTLE=8

ip netns add sw1
ip -n sw1 link set lo up
ip -n sw1 link add br0 type bridge
ip -n sw1 link set br0 up

add_host() {
  name=$1; nn=$2
  ip netns add "$name"
  ip -n "$name" link set lo up

  ip link add "${name}0" type veth peer name "sw1-${name}"
  ip link set "${name}0" netns "$name"
  ip link set "sw1-${name}" netns sw1

  ip -n "$name" link set "${name}0" address "02:00:00:00:00:$nn"
  ip -n sw1 link set "sw1-${name}" master br0
  ip -n sw1 link set "sw1-${name}" up
}

add_host r1 01
add_host h1 11
add_host h2 12
add_host h3 13

# Interface settings have to be in place before the link comes up, because the
# link-local address is generated the moment it does and the mode cannot be
# applied retrospectively.
# Stable privacy needs a secret to derive from, and the kernel refuses the mode
# until one is set. A fixed secret here makes the resulting address the same on
# every run, which a real machine would not want and a transcript does.
ip netns exec h1 sh -c "echo fd00:0000:0000:0000:0000:0000:0000:1234 > /proc/sys/net/ipv6/conf/h10/stable_secret"
ip netns exec h1 sh -c "echo 2 > /proc/sys/net/ipv6/conf/h10/addr_gen_mode"
ip netns exec h2 sh -c "echo 0 > /proc/sys/net/ipv6/conf/h20/addr_gen_mode"
ip netns exec h3 sh -c "echo 0 > /proc/sys/net/ipv6/conf/h30/addr_gen_mode"

# h3 keeps a temporary address alongside the stable one and prefers it outbound
ip netns exec h3 sh -c "echo 2 > /proc/sys/net/ipv6/conf/h30/use_tempaddr"

for h in h1 h2 h3; do
  ip -n "$h" link set "${h}0" up
done

# The router. Its own address is configured by hand, because something has to
# know the prefix before anybody can be told it.
ip -n r1 addr add 2001:db8:1::1/64 dev r10
ip -n r1 link set r10 up
ip netns exec r1 sh -c "echo 1 > /proc/sys/net/ipv6/conf/all/forwarding"

ip netns exec r1 sh -c 'cat > /etc/radvd.conf <<CONF
interface r10 {
  AdvSendAdvert on;
  MinRtrAdvInterval 3;
  MaxRtrAdvInterval 5;
  AdvManagedFlag off;
  AdvOtherConfigFlag on;
  prefix 2001:db8:1::/64 {
    AdvOnLink on;
    AdvAutonomous on;
    AdvValidLifetime 86400;
    AdvPreferredLifetime 3600;
  };
  RDNSS 2001:db8:1::1 {
    AdvRDNSSLifetime 600;
  };
};
CONF'

ip netns exec r1 sh -c 'radvd -C /etc/radvd.conf -p /tmp/radvd.pid >/dev/null 2>&1'
