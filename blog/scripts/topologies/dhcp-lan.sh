# A DHCP server, four clients that want addresses, and a pool too small for them.
#
#   h1  h2  h4  h5            r1                        h3
#    |   |   |   |     .254 -------- .254                |
#    +--- sw1 ---+------|  10.0.2.0/24  |--- sw2 --------+
#         |
#        srv 10.0.0.1     pool 10.0.0.100 to .101, two addresses
#                         reservation 10.0.0.50 for h2
#                         pool 10.0.2.100 to .110 for the far side
#
# Four things this has to show, which is why it is one topology rather than
# four. The four-message exchange on a segment where the server is present. A
# reservation, which is an address the pool never offers to anybody else. A pool
# with nothing left in it, so that a client asks and hears nothing back. And a
# client on a segment with no server at all, whose broadcast crosses a router
# because something on the router picked it up and forwarded it.
#
# The pool is deliberately two addresses wide. Exhaustion is normally a fault
# somebody has to wait for, and at this size it happens on the third client.
#
# r1 forwards between the two segments and runs the relay. Note that it needs
# both jobs: relaying is not routing, and a router with forwarding on and no
# relay agent leaves the far segment with no addresses at all.
NETLAB_PACKAGES="iproute2 iputils-ping tcpdump dnsmasq isc-dhcp-relay isc-dhcp-client"
NETLAB_SETTLE=3

for s in sw1 sw2; do
  ip netns add $s
  ip -n $s link set lo up
  ip netns exec $s sh -c "echo 1 > /proc/sys/net/ipv6/conf/default/disable_ipv6"
  ip netns exec $s sh -c "echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6"
  ip -n $s link add br0 type bridge
  ip -n $s link set br0 up
done

# host NAME on switch S with MAC ending NN, address optional. A client that is
# going to use DHCP gets no address here, because handing it one first would
# make the capture a lie.
add_host() {
  name=$1; s=$2; nn=$3; addr=${4:-}
  ip netns add "$name"
  ip -n "$name" link set lo up
  ip netns exec "$name" sh -c "echo 1 > /proc/sys/net/ipv6/conf/default/disable_ipv6"
  ip netns exec "$name" sh -c "echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6"

  ip link add "${name}0" type veth peer name "${s}-${name}"
  ip link set "${name}0" netns "$name"
  ip link set "${s}-${name}" netns "$s"

  ip -n "$name" link set "${name}0" address "02:00:00:00:00:$nn"
  [ -n "$addr" ] && ip -n "$name" addr add "$addr" dev "${name}0"
  ip -n "$name" link set "${name}0" up

  ip -n "$s" link set "${s}-${name}" master br0
  ip -n "$s" link set "${s}-${name}" up
}

add_host srv sw1 01 10.0.0.1/24
add_host h1 sw1 11
add_host h2 sw1 12
add_host h4 sw1 14
add_host h5 sw1 15
add_host h3 sw2 13

# r1 sits on both segments and forwards between them
ip netns add r1
ip -n r1 link set lo up
ip netns exec r1 sh -c "echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6"
ip netns exec r1 sh -c "echo 1 > /proc/sys/net/ipv4/ip_forward"
for s in sw1 sw2; do
  ip link add "r1-$s" type veth peer name "$s-r1"
  ip link set "r1-$s" netns r1
  ip link set "$s-r1" netns "$s"
  ip -n "$s" link set "$s-r1" master br0
  ip -n "$s" link set "$s-r1" up
  ip -n r1 link set "r1-$s" up
done
ip -n r1 link set r1-sw1 address 02:00:00:00:00:fe
ip -n r1 link set r1-sw2 address 02:00:00:00:00:ff
ip -n r1 addr add 10.0.0.254/24 dev r1-sw1
ip -n r1 addr add 10.0.2.254/24 dev r1-sw2

# The server has to be able to reach the far segment, or the relayed replies
# have nowhere to go. This is the step people forget, and its symptom is a
# client that sends and never hears anything.
ip -n srv route add 10.0.2.0/24 via 10.0.0.254

ip netns exec srv sh -c 'mkdir -p /etc/dnsmasq.d && cat > /etc/dnsmasq.conf <<CONF
port=0
interface=srv0
bind-interfaces
log-dhcp

# the near segment. two addresses, which is the whole pool
dhcp-range=set:near,10.0.0.100,10.0.0.101,255.255.255.0,12h
dhcp-option=tag:near,option:router,10.0.0.254
dhcp-option=tag:near,option:dns-server,10.0.0.1
dhcp-option=tag:near,option:domain-name,lab.example

# h2 always gets the same address, and it is outside the pool
dhcp-host=02:00:00:00:00:12,10.0.0.50,h2

# the far segment, reached through the relay on r1
dhcp-range=set:far,10.0.2.100,10.0.2.110,255.255.255.0,12h
dhcp-option=tag:far,option:router,10.0.2.254
dhcp-option=tag:far,option:dns-server,10.0.0.1
CONF'

ip netns exec srv sh -c 'mkdir -p /var/lib/misc && dnsmasq --conf-file=/etc/dnsmasq.conf --pid-file=/tmp/dnsmasq.pid --log-facility=/tmp/dnsmasq.log >/dev/null 2>&1'

# The relay agent. -id is the segment it listens to clients on, -iu is the way
# out towards the server, and the argument is the server's address. Naming one
# interface for both jobs is the mistake that produces a client which sends
# forever and hears nothing, because the relayed request leaves by the same
# interface it arrived on.
ip netns exec r1 dhcrelay -4 -id r1-sw2 -iu r1-sw1 -pf /tmp/dhcrelay.pid 10.0.0.1 >/dev/null 2>&1

mkdir -p /var/lib/dhcp
: > /var/lib/dhcp/dhclient.leases
