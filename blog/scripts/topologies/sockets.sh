# A host that is listening on a couple of ports, so the tools that ask "what is
# listening, and who is connected" have something to show.
#
#   h1 10.0.0.1 --- sw --- h2 10.0.0.2
#                     |
#                   h3 10.0.0.3
#
# h1 runs two services. One binds every interface, so it is reachable from the
# network; the other binds only the loopback, so it is reachable only from h1
# itself. Reading which is which off a listen address is half of topic 63, and it
# is the half that decides whether "something is listening" is a problem or not.
#
# The connections are made in the capture command rather than here, so the reader
# sees the connection open before it appears in the socket list.
NETLAB_PACKAGES="iproute2 iputils-ping iproute2 python3"
NETLAB_SETTLE=1

ip netns add sw
ip -n sw link set lo up
ip netns exec sw sh -c "echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6"
ip -n sw link add br0 type bridge
ip -n sw link set br0 up

add_host() {
  name=$1; nn=$2
  ip netns add "$name"
  ip -n "$name" link set lo up
  ip netns exec "$name" sh -c "echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6"
  ip link add "${name}0" type veth peer name "sw-${name}"
  ip link set "${name}0" netns "$name"
  ip link set "sw-${name}" netns sw
  ip -n "$name" link set "${name}0" address "02:00:00:00:00:0$nn"
  ip -n "$name" addr add "10.0.0.$nn/24" dev "${name}0"
  ip -n "$name" link set "${name}0" up
  ip -n sw link set "sw-${name}" master br0
  ip -n sw link set "sw-${name}" up
}

add_host h1 1
add_host h2 2
add_host h3 3

# Two services on h1. http.server binds 0.0.0.0 by default, so it answers the
# network; the second is bound to 127.0.0.1, so it answers only h1.
ip netns exec h1 sh -c "cd /tmp && python3 -m http.server 8000 >/dev/null 2>&1 &"
ip netns exec h1 sh -c "cd /tmp && python3 -m http.server 9000 --bind 127.0.0.1 >/dev/null 2>&1 &"

# A client on h2 that opens a connection to h1 and holds it, so an established
# connection is there to be read. Written to a file so the capture command that
# runs it stays legible.
ip netns exec h2 sh -c 'cat > /root/hold.py' <<'PY'
import socket, time
s = socket.create_connection(("10.0.0.1", 8000))
time.sleep(30)
PY
