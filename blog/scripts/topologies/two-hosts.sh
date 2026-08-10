# Two hosts joined by one cable, and nothing else.
#
#   h1 ------------------- h2
#      veth pair, no switch
#
# The smallest network that is a network. Used by topic 01 to show that a cable
# between two machines is not enough on its own, and what the missing pieces
# are. Both interfaces come up with no addresses, which is the state the topic
# opens on.
#
# Addresses are deliberately left off here. A topic that wants them assigns them
# in the captured command, so the reader sees the assignment rather than being
# handed a working network and told to believe it.
NETLAB_PACKAGES="iproute2 iputils-ping tcpdump"
NETLAB_SETTLE=0

ip netns add h1
ip netns add h2

# A veth pair is two interfaces welded together. Whatever goes in one comes out
# the other, which is what a cable does.
ip link add h1eth0 type veth peer name h2eth0
ip link set h1eth0 netns h1
ip link set h2eth0 netns h2

# Fixed MAC addresses. The kernel generates random ones per run, and a
# transcript that changes every time it is produced cannot be checked against
# the page. The 02: prefix marks these as locally administered.
ip -n h1 link set h1eth0 address 02:00:00:00:01:01
ip -n h2 link set h2eth0 address 02:00:00:00:01:02

ip -n h1 link set h1eth0 up
ip -n h2 link set h2eth0 up
ip -n h1 link set lo up
ip -n h2 link set lo up
