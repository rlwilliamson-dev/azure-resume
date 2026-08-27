#!/usr/bin/env sh
# Three measurements for the configuration drift topic.
#
# `policy-drift` changes a system-wide cryptographic policy and shows what
# happens to a configuration file that nobody edited. `package-drift` edits a
# file the package manager owns, asks the package manager whether it noticed,
# and asks it to put things back. `in-the-clear` runs a TLS handshake against a
# server on this container's loopback address and looks for the destination name
# in the captured bytes. Nothing leaves the container.
dnf -q -y install openssh-server crypto-policies chrony rpm openssl tcpdump >/dev/null 2>&1
ssh-keygen -A >/dev/null 2>&1

cat > /usr/local/bin/policy-drift <<'SCRIPT'
#!/usr/bin/env sh
# The file is not edited at any point in this script. Only a system-wide policy
# setting changes, and the question is what that does to the effective
# configuration of a service whose own file is untouched.
ciphers() { sshd -T 2>/dev/null | sed -n 's/^ciphers //p' | tr ',' '\n' | sort; }
show() {
  echo "$1"
  printf '  sha256 of /etc/ssh/sshd_config  %s\n' "$(sha256sum /etc/ssh/sshd_config | cut -c1-16)"
  printf '  mtime of the same file          %s\n' "$(stat -c %y /etc/ssh/sshd_config | cut -c1-19)"
  printf '  ciphers the service will offer  %s\n' "$(ciphers | grep -c .)"
  printf '  system-wide policy in force     %s\n' "$(update-crypto-policies --show)"
}
ciphers > /tmp/before
show "in January"
echo
echo "somebody sets the system-wide policy, on a different day, for a different reason:"
update-crypto-policies --set LEGACY >/dev/null 2>&1
echo
show "in March"
echo
echo "the ciphers the service now offers that it did not offer before:"
ciphers > /tmp/after
comm -13 /tmp/before /tmp/after | sed 's/^/  /'
SCRIPT
chmod +x /usr/local/bin/policy-drift

cat > /usr/local/bin/package-drift <<'SCRIPT'
#!/usr/bin/env sh
# Edit a file the package manager installed, then ask the package manager two
# questions: did you notice, and will you put it back.
echo "before anybody touches it:"
rpm -V chrony && echo "  rpm -V reports nothing"
echo
echo "one line is appended to /etc/chrony.conf by hand:"
echo "# added at some point by somebody" >> /etc/chrony.conf
rpm -V chrony | sed 's/^/  /'
echo
echo "asking the package manager to reinstall the package:"
dnf -q -y reinstall chrony >/dev/null 2>&1
rpm -V chrony | sed 's/^/  /'
echo
echo "what it left on disk instead:"
ls -1 /etc/chrony.conf* | sed 's/^/  /'
tail -1 /etc/chrony.conf | sed 's/^/  last line of the live file: /'
SCRIPT
chmod +x /usr/local/bin/package-drift

cat > /usr/local/bin/in-the-clear <<'SCRIPT'
#!/usr/bin/env sh
# One TLS handshake to a server on this container's own loopback address, with
# the packets recorded. The question is what an observer who cannot decrypt any
# of it still learns.
openssl req -x509 -newkey rsa:2048 -nodes -days 1 -subj '/CN=localhost' \
  -keyout /tmp/k.pem -out /tmp/c.pem >/dev/null 2>&1
openssl s_server -quiet -accept 4433 -naccept 1 -cert /tmp/c.pem -key /tmp/k.pem >/dev/null 2>&1 &
server=$!
tcpdump -i lo -w /tmp/tls.pcap -s 0 'port 4433' >/dev/null 2>&1 &
sniffer=$!
sleep 2
printf 'the body of this request is encrypted\n' |
  openssl s_client -connect 127.0.0.1:4433 -servername finance-reporting.internal.example \
    -CAfile /tmp/c.pem >/dev/null 2>&1
sleep 1
kill "$sniffer" "$server" 2>/dev/null
wait "$sniffer" 2>/dev/null
echo "bytes captured: $(stat -c %s /tmp/tls.pcap)"
echo
echo "searching the captured packets for the name the client asked for:"
strings /tmp/tls.pcap | grep -c 'finance-reporting.internal.example' |
  sed 's/^/  occurrences of the hostname in the clear: /'
strings /tmp/tls.pcap | grep -m1 'finance-reporting' | sed 's/^/  found: /'
echo
echo "and for the body of the request, which was sent after the handshake:"
strings /tmp/tls.pcap | grep -c 'the body of this request' |
  sed 's/^/  occurrences of the message text in the clear: /'
SCRIPT
chmod +x /usr/local/bin/in-the-clear
