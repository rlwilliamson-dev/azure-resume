#!/usr/bin/env sh
# The listening surface of a machine, before and after three different ways of
# closing a port.
#
# `surface` starts a handful of ordinary services, counts what is listening,
# then applies a firewall rule to one, stops a second, and removes the package
# behind a third. The point is that all three close the port and they leave very
# different things behind.
dnf -q -y install openssh-server httpd vsftpd rpcbind chrony nftables \
  iproute procps-ng >/dev/null 2>&1
ssh-keygen -A >/dev/null 2>&1

cat > /usr/local/bin/surface <<'SCRIPT'
#!/usr/bin/env sh
listeners() {
  ss -tulpnH 2>/dev/null |
    awk '{ split($7, a, "\""); n = split($5, b, ":"); printf "  %-6s %-4s %-20s %s\n", b[n], $1, $5, a[2] }' |
    sort -n
}
count() { ss -tulnH 2>/dev/null | grep -c .; }

/usr/sbin/sshd >/dev/null 2>&1
/usr/sbin/httpd >/dev/null 2>&1
/usr/sbin/vsftpd >/dev/null 2>&1 &
/usr/bin/rpcbind >/dev/null 2>&1
/usr/sbin/chronyd >/dev/null 2>&1
sleep 2

echo "a machine with five ordinary services running:"
listeners
printf '  %s listening sockets\n' "$(count)"
echo
echo "closing three of them, three different ways:"
echo "  1. a firewall rule against the ftp port"
nft add table inet h 2>/dev/null
nft add chain inet h input '{ type filter hook input priority 0; policy accept; }' 2>/dev/null
nft add rule inet h input tcp dport 21 drop 2>/dev/null
echo "  2. stopping the web server"
pkill -x httpd 2>/dev/null
echo "  3. removing the package behind the portmapper"
pkill -x rpcbind 2>/dev/null
dnf -q -y remove rpcbind >/dev/null 2>&1
sleep 1
echo
echo "what is listening now:"
listeners
printf '  %s listening sockets\n' "$(count)"
echo
echo "and what is left behind by each:"
printf '  ftp    socket still listening: %s   binary still present: %s\n' \
  "$(ss -tlnH 'sport = :21' 2>/dev/null | grep -c .)" \
  "$([ -x /usr/sbin/vsftpd ] && echo yes || echo no)"
printf '  http   socket still listening: %s   binary still present: %s\n' \
  "$(ss -tlnH 'sport = :80' 2>/dev/null | grep -c .)" \
  "$([ -x /usr/sbin/httpd ] && echo yes || echo no)"
printf '  rpc    socket still listening: %s   binary still present: %s\n' \
  "$(ss -tlnH 'sport = :111' 2>/dev/null | grep -c .)" \
  "$([ -x /usr/bin/rpcbind ] && echo yes || echo no)"
SCRIPT
chmod +x /usr/local/bin/surface
