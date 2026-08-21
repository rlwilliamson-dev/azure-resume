# A device that can only be reached by going through something else first.
#
#   admin 10.0.0.5 --- swa --- jump --- swb --- device 10.9.0.20
#                            .10  .10
#                        (forwarding off)
#
# The jump host has an interface on both segments and does not route between
# them. That is the whole idea and it is easy to miss: a jump box is not a
# router, and if it forwarded packets it would be a hole rather than a control.
# Nothing on the admin segment can send a packet to the device. A person on the
# admin segment can log in to the jump host and open a second connection from
# there, and the capture shows both facts in the same transcript.
#
# The device also gets sshd, because topic 51's other demonstration needs a
# session that can be used to break its own path.
#
# Keys rather than passwords, generated at build time and thrown away with the
# container. Nothing here is a credential that outlives the capture.
NETLAB_PACKAGES="iproute2 iputils-ping tcpdump openssh-server openssh-client"
NETLAB_SETTLE=3

for s in swa swb; do
  ip netns add $s
  ip -n $s link set lo up
  ip netns exec $s sh -c "echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6"
  ip -n $s link add br0 type bridge
  ip -n $s link set br0 up
done

add_link() {
  name=$1; s=$2; nn=$3; addr=$4
  ip netns add "$name" 2>/dev/null || true
  ip -n "$name" link set lo up
  ip netns exec "$name" sh -c "echo 1 > /proc/sys/net/ipv6/conf/default/disable_ipv6"
  ip netns exec "$name" sh -c "echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6"
  ip link add "${name}-${s}" type veth peer name "${s}-${name}"
  ip link set "${name}-${s}" netns "$name"
  ip link set "${s}-${name}" netns "$s"
  ip -n "$name" link set "${name}-${s}" address "02:00:00:00:00:$nn"
  ip -n "$name" addr add "$addr" dev "${name}-${s}"
  ip -n "$name" link set "${name}-${s}" up
  ip -n "$s" link set "${s}-${name}" master br0
  ip -n "$s" link set "${s}-${name}" up
}

add_link admin swa 05 10.0.0.5/24
add_link jump swa 10 10.0.0.10/24
add_link jump swb 11 10.9.0.10/24
add_link device swb 20 10.9.0.20/24

# The jump host does not route. Without this line it would be a router with a
# login prompt, which is a different thing entirely.
ip netns exec jump sh -c "echo 0 > /proc/sys/net/ipv4/ip_forward"

ip -n admin route add 10.9.0.0/24 via 10.0.0.10
ip -n device route add 10.0.0.0/24 via 10.9.0.10

# ------------------------------------------------------------------ ssh setup
#
# One key pair for the admin, trusted by both the jump host and the device. Host
# keys are generated per node and accepted without checking, which is the one
# thing here a real deployment must not do and which a lab that rebuilds itself
# every run has no way to avoid.
mkdir -p /root/.ssh
ssh-keygen -t ed25519 -N '' -f /root/.ssh/id_ed25519 -C lab >/dev/null 2>&1
ssh-keygen -A >/dev/null 2>&1

for node in jump device; do
  ip netns exec "$node" sh -c "
    mkdir -p /run/sshd /root/.ssh
    cp /root/.ssh/id_ed25519.pub /root/.ssh/authorized_keys
    chmod 600 /root/.ssh/authorized_keys
    cat > /etc/ssh-$node.conf <<CONF
Port 22
PermitRootLogin prohibit-password
PubkeyAuthentication yes
PasswordAuthentication no
AuthorizedKeysFile /root/.ssh/authorized_keys
HostKey /etc/ssh/ssh_host_ed25519_key
PidFile /run/sshd-$node.pid
CONF
    /usr/sbin/sshd -f /etc/ssh-$node.conf
  " >/dev/null 2>&1
done

cat > /root/.ssh/config <<CONF
Host *
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null
  LogLevel ERROR
  ConnectTimeout 5
CONF
chmod 600 /root/.ssh/config
