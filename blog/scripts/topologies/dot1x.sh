# The three roles of 802.1X, each in its own namespace, on one link.
#
#   sup --- auth              radius lives inside auth
#   supplicant  authenticator (hostapd is both the authenticator and,
#                              for this lab, the authentication server)
#
# A supplicant is the device asking to join. An authenticator is the switch port
# it plugs into, which will pass nothing but the authentication conversation
# until that conversation succeeds. An authentication server holds the credentials
# and makes the decision. In a real network the server is a separate RADIUS host
# and one server backs every switch; here hostapd runs its own EAP server so the
# whole exchange fits in one link and one capture.
#
# EAP-MD5 is used because it needs no certificates and keeps the capture short.
# It is also weak, and the page says so: a real deployment uses a certificate
# based method. The frames on the wire have the same shape either way, which is
# what the capture is for.
NETLAB_PACKAGES="iproute2 iputils-ping tcpdump hostapd wpasupplicant"
NETLAB_SETTLE=1

ip netns add sup
ip netns add auth
for n in sup auth; do
  ip -n $n link set lo up
  ip netns exec $n sh -c "echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6"
done

ip link add sup0 type veth peer name auth0
ip link set sup0 netns sup
ip link set auth0 netns auth
ip -n sup link set sup0 address 02:00:00:00:00:11
ip -n auth link set auth0 address 02:00:00:00:00:22
ip -n sup link set sup0 up
ip -n auth link set auth0 up

# The authenticator's configuration. It speaks 802.1X on the wired port and runs
# its own EAP server, with one account.
ip netns exec auth sh -c 'cat > /etc/hostapd.conf' <<'CONF'
interface=auth0
driver=wired
ieee8021x=1
eap_server=1
eap_user_file=/etc/hostapd.eap_user
eapol_version=2
CONF
ip netns exec auth sh -c 'printf "%s\n" "\"host1\"  MD5  \"g00d-secret\"" > /etc/hostapd.eap_user'

# The supplicant's configuration. One account, matching.
ip netns exec sup sh -c 'cat > /etc/wpa_supplicant.conf' <<'CONF'
ctrl_interface=/run/wpa_supplicant
eapol_version=2
ap_scan=0
fast_reauth=0
network={
  key_mgmt=IEEE8021X
  eap=MD5
  identity="host1"
  password="g00d-secret"
  eapol_flags=0
}
CONF

# A second supplicant config with the wrong password, so the failed exchange can
# be captured next to the successful one. Same identity, same method, one letter
# different in the secret.
ip netns exec sup sh -c 'cat > /etc/wpa_supplicant-bad.conf' <<'CONF'
ctrl_interface=/run/wpa_supplicant
eapol_version=2
ap_scan=0
fast_reauth=0
network={
  key_mgmt=IEEE8021X
  eap=MD5
  identity="host1"
  password="wrong-secret"
  eapol_flags=0
}
CONF
