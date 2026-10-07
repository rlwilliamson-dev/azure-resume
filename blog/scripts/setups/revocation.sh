# Fetch the certificate a real server presents, its issuer, and the revocation
# list its own extensions point at, so a topic can read all three without the
# fetching filling the transcript.
#
# Everything here is a public endpoint published by the certificate authority for
# exactly this purpose, and the certificate belongs to a domain this project owns.
dnf -q -y install openssl curl >/dev/null 2>&1
mkdir -p /root/rev && cd /root/rev
openssl s_client -connect rlwilliamson.dev:443 -servername rlwilliamson.dev -showcerts </dev/null 2>/dev/null > chain.txt
awk '/BEGIN CERT/{n++} n==1' chain.txt > leaf.pem
awk '/BEGIN CERT/{n++} n==2' chain.txt > issuer.pem
curl -sS -o ca.crl http://cdp.geotrust.com/GeoTrustTLSRSACAG1.crl
