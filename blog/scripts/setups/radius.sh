#!/usr/bin/env sh
# A working RADIUS server with one test user, so a topic can show what an
# authentication exchange actually carries rather than describing it.
#
# freeradius-utils brings radtest and radclient. The server is started in the
# background because a container has no service manager to start it for us.
set -e
dnf -q -y install freeradius freeradius-utils >/dev/null 2>&1
printf 'wifi-user Cleartext-Password := "Correct-Horse-1"\n    Reply-Message := "welcome to the corporate SSID",\n    Tunnel-Type := VLAN,\n    Tunnel-Medium-Type := IEEE-802,\n    Tunnel-Private-Group-Id := "42"\n' >> /etc/raddb/mods-config/files/authorize
# The EAP module refuses to start without a server certificate, which is itself
# the enterprise-against-PSK distinction: enterprise needs a PKI and PSK does not.
# FreeRADIUS ships a bootstrap that generates a self-signed test set.
(cd /etc/raddb/certs && ./bootstrap >/tmp/bootstrap.log 2>&1)
# The server is NOT started here. capture.sh commits the setup to an image and
# runs the captured command in a fresh container, so a daemon started in setup
# would not survive. The topic's command starts it, which is honest anyway: the
# reader sees the server come up and the request go to it.
