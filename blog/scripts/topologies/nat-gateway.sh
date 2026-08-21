# Private hosts behind one public address.
#
#   h1 10.0.0.11 \
#                 +-- nat -------- srv 203.0.113.9
#   h2 10.0.0.12 /   .1      .1
#      10.0.0.0/24      203.0.113.0/24
#
# The nat namespace masquerades everything from 10.0.0.0/24 onto its outside
# address, which is what a home router does. The server sees one address for
# both hosts, and the translation table on the gateway is the thing that keeps
# the two conversations apart.
#
# 203.0.113.0/24 is TEST-NET-3 from RFC 5737, reserved for documentation, so
# nothing here names a real network.
NETLAB_PACKAGES="iproute2 iputils-ping tcpdump netcat-openbsd nftables conntrack"
NETLAB_SETTLE=2

for ns in nat srv h1 h2; do
  ip netns add $ns
  ip -n $ns link set lo up
done
ip netns exec nat sh -c "echo 1 > /proc/sys/net/ipv4/ip_forward"

# the inside: a bridge with two hosts and the gateway on it
ip -n nat link add br0 type bridge
ip -n nat link set br0 up
ip -n nat addr add 10.0.0.1/24 dev br0
for n in 1 2; do
  ip link add h${n}eth0 type veth peer name nat-h$n
  ip link set h${n}eth0 netns h$n
  ip link set nat-h$n netns nat
  ip -n h$n link set h${n}eth0 address 02:00:00:00:00:1$n
  ip -n h$n addr add 10.0.0.1$n/24 dev h${n}eth0
  ip -n h$n link set h${n}eth0 up
  ip -n h$n route add default via 10.0.0.1
  ip -n nat link set nat-h$n master br0
  ip -n nat link set nat-h$n up
done

# the outside
ip link add nat-out type veth peer name srv-in
ip link set nat-out netns nat
ip link set srv-in netns srv
ip -n nat addr add 203.0.113.1/24 dev nat-out
ip -n srv addr add 203.0.113.9/24 dev srv-in
ip -n nat link set nat-out up
ip -n srv link set srv-in up
ip -n srv route add 10.0.0.0/24 via 203.0.113.1

# masquerade: rewrite the source of anything leaving on the outside interface
ip netns exec nat nft add table ip nat
ip netns exec nat nft 'add chain ip nat postrouting { type nat hook postrouting priority 100 ; }'
ip netns exec nat nft add rule ip nat postrouting oifname nat-out masquerade
