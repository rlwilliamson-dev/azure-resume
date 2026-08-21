# A working DNS hierarchy and a web server, so a name can genuinely be resolved
# from the root down and then connected to.
#
#   root 10.0.0.1                                    203.0.113.0/24
#   tld  10.0.0.2   \                              /
#   auth 10.0.0.3    +-- sw1 -- r1 -------- sw2 --+-- web 203.0.113.10
#   resolver 10.0.0.4|      .254          .254
#   client 10.0.0.5 /
#
# Four name servers rather than one, because the thing worth showing is the walk
# down the tree. The root delegates `example.` to the TLD server, the TLD server
# delegates `lab.example.` to the authoritative server, and the resolver is
# pointed at our root instead of the real one, so `dig +trace` produces a genuine
# referral chain that fits on a page.
#
# The web server is on the far side of a router on purpose. A page load then has
# to resolve a name using a resolver on its own segment, ARP for its gateway to
# reach anything else, and open a connection across the router, which is the
# sequence topic 45 is about. With everything on one segment the gateway step
# would not happen and the capture would be missing the step people forget.
#
# 203.0.113.0/24 is TEST-NET-3 from RFC 5737 and 2001:db8::/32 is the
# documentation prefix from RFC 3849, so nothing here names a real network. The
# zone is `lab.example.`, under the `example.` name reserved by RFC 2606.
NETLAB_PACKAGES="iproute2 iputils-ping tcpdump bind9 bind9-utils bind9-dnsutils nginx openssl curl"
NETLAB_SETTLE=6

for s in sw1 sw2; do
  ip netns add $s
  ip -n $s link set lo up
  ip netns exec $s sh -c "echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6"
  ip -n $s link add br0 type bridge
  ip -n $s link set br0 up
done

add_host() {
  name=$1; s=$2; nn=$3; addr=$4
  ip netns add "$name"
  ip -n "$name" link set lo up
  ip netns exec "$name" sh -c "echo 1 > /proc/sys/net/ipv6/conf/default/disable_ipv6"
  ip netns exec "$name" sh -c "echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6"
  ip link add "${name}0" type veth peer name "${s}-${name}"
  ip link set "${name}0" netns "$name"
  ip link set "${s}-${name}" netns "$s"
  ip -n "$name" link set "${name}0" address "02:00:00:00:00:$nn"
  ip -n "$name" addr add "$addr" dev "${name}0"
  ip -n "$name" link set "${name}0" up
  ip -n "$s" link set "${s}-${name}" master br0
  ip -n "$s" link set "${s}-${name}" up
}

add_host root sw1 01 10.0.0.1/24
add_host tld sw1 02 10.0.0.2/24
add_host auth sw1 03 10.0.0.3/24
add_host resolver sw1 04 10.0.0.4/24
add_host client sw1 05 10.0.0.5/24
add_host web sw2 09 203.0.113.10/24

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
ip -n r1 addr add 203.0.113.254/24 dev r1-sw2

for h in root tld auth resolver client; do
  ip -n $h route add default via 10.0.0.254
done
ip -n web route add default via 203.0.113.254

# ---------------------------------------------------------------- the servers
#
# One named per role, each in its own namespace with its own config directory.
# Everything is written out here rather than shipped as files, so the zone data
# a capture reads is visible in the topology that produced it.

mkzone() {
  ns=$1; conf=$2
  ip netns exec "$ns" sh -c "mkdir -p /etc/bind-$ns /var/cache/bind-$ns && cat > /etc/bind-$ns/named.conf <<'CONF'
$conf
CONF"
}

# the root. knows nothing except who to send you to
ip netns exec root sh -c 'mkdir -p /etc/bind-root && cat > /etc/bind-root/root.zone <<ZONE
\$TTL 3600
@	IN	SOA	a.root-servers.lab. hostmaster.root-servers.lab. ( 1 3600 900 604800 900 )
@	IN	NS	a.root-servers.lab.
a.root-servers.lab.	IN	A	10.0.0.1
example.	IN	NS	ns.example.
ns.example.	IN	A	10.0.0.2
ZONE'
mkzone root 'options { directory "/var/cache/bind-root"; listen-on { 10.0.0.1; }; listen-on-v6 { none; }; recursion no; allow-query { any; }; pid-file "/run/named-root.pid"; };
zone "." { type primary; file "/etc/bind-root/root.zone"; };'

# the top level. knows the zone below it and nothing inside it
ip netns exec tld sh -c 'mkdir -p /etc/bind-tld && cat > /etc/bind-tld/example.zone <<ZONE
\$TTL 3600
@	IN	SOA	ns.example. hostmaster.example. ( 1 3600 900 604800 900 )
@	IN	NS	ns.example.
ns	IN	A	10.0.0.2
lab	IN	NS	ns.lab.example.
ns.lab.example.	IN	A	10.0.0.3
ZONE'
mkzone tld 'options { directory "/var/cache/bind-tld"; listen-on { 10.0.0.2; }; listen-on-v6 { none; }; recursion no; allow-query { any; }; pid-file "/run/named-tld.pid"; };
zone "example" { type primary; file "/etc/bind-tld/example.zone"; };'

# the authoritative server for the zone the records live in, forward and reverse
ip netns exec auth sh -c 'mkdir -p /etc/bind-auth && cat > /etc/bind-auth/lab.example.zone <<ZONE
\$TTL 3600
@	IN	SOA	ns.lab.example. hostmaster.lab.example. ( 2026081201 7200 3600 1209600 900 )
@	IN	NS	ns.lab.example.
@	IN	MX	10 mail.lab.example.
@	IN	TXT	"v=spf1 mx -all"
ns	IN	A	10.0.0.3
www	IN	A	203.0.113.10
www	IN	AAAA	2001:db8:113::10
mail	IN	A	203.0.113.25
shop	IN	CNAME	www.lab.example.
ZONE
cat > /etc/bind-auth/113.0.203.zone <<ZONE
\$TTL 3600
@	IN	SOA	ns.lab.example. hostmaster.lab.example. ( 2026081201 7200 3600 1209600 900 )
@	IN	NS	ns.lab.example.
10	IN	PTR	www.lab.example.
25	IN	PTR	mail.lab.example.
ZONE'
mkzone auth 'options { directory "/var/cache/bind-auth"; listen-on { 10.0.0.3; }; listen-on-v6 { none; }; recursion no; allow-query { any; }; allow-transfer { 10.0.0.5; }; pid-file "/run/named-auth.pid"; };
zone "lab.example" { type primary; file "/etc/bind-auth/lab.example.zone"; };
zone "113.0.203.in-addr.arpa" { type primary; file "/etc/bind-auth/113.0.203.zone"; };'

# the recursive resolver, pointed at our root rather than the real one
ip netns exec resolver sh -c 'mkdir -p /etc/bind-resolver && cat > /etc/bind-resolver/root.hints <<HINTS
.	3600000	IN	NS	a.root-servers.lab.
a.root-servers.lab.	3600000	IN	A	10.0.0.1
HINTS'
mkzone resolver 'options { directory "/var/cache/bind-resolver"; listen-on { 10.0.0.4; }; listen-on-v6 { none; }; recursion yes; allow-query { any; }; dnssec-validation no; pid-file "/run/named-resolver.pid"; };
zone "." { type hint; file "/etc/bind-resolver/root.hints"; };'

for ns in root tld auth resolver; do
  ip netns exec "$ns" named -c "/etc/bind-$ns/named.conf" >/dev/null 2>&1
done

# the client points at the resolver, the way any machine does
ip netns exec client sh -c 'printf "nameserver 10.0.0.4\noptions timeout:2\n" > /etc/resolv.conf'

# ------------------------------------------------------------- the web server
#
# A self-signed certificate for www.lab.example, so a page load involves a real
# TLS handshake rather than a plaintext stand-in. The client trusts it through
# --cacert, which is what makes the capture a genuine handshake and not one that
# fails halfway.
ip netns exec web sh -c 'mkdir -p /etc/nginx-lab /var/www-lab &&
  openssl req -x509 -newkey rsa:2048 -nodes -days 3650 \
    -subj "/CN=www.lab.example" -addext "subjectAltName=DNS:www.lab.example" \
    -keyout /etc/nginx-lab/key.pem -out /etc/nginx-lab/cert.pem >/dev/null 2>&1 &&
  printf "<!doctype html>\n<title>lab</title>\n<h1>it worked</h1>\n" > /var/www-lab/index.html &&
  cat > /etc/nginx-lab/nginx.conf <<CONF
daemon on;
error_log /tmp/nginx-error.log crit;
pid /run/nginx-lab.pid;
events { worker_connections 64; }
http {
  access_log off;
  server {
    listen 80;
    listen 443 ssl;
    server_name www.lab.example;
    ssl_certificate /etc/nginx-lab/cert.pem;
    ssl_certificate_key /etc/nginx-lab/key.pem;
    root /var/www-lab;
  }
}
CONF
  nginx -c /etc/nginx-lab/nginx.conf >/dev/null 2>&1'

# the certificate has to reach the client for it to be trusted
ip netns exec web cat /etc/nginx-lab/cert.pem > /tmp/lab-ca.pem 2>/dev/null
