# A certificate with a fixed validity window, so that the same file can be
# verified at several different times and the answers are reproducible.
#
# The dates are written out rather than taken from the clock, because a
# transcript whose output depends on the day it was produced is not a transcript
# anybody can check. OpenSSL 3.5 added -not_before and -not_after to req, which
# is what makes that possible without editing a configuration file.
apt-get update -qq
apt-get install -y -qq --no-install-recommends openssl ca-certificates
mkdir -p /root/pki
cd /root/pki
openssl req -x509 -newkey rsa:2048 -nodes -subj "/CN=Lab CA" \
  -not_before 20260101000000Z -not_after 20260630000000Z \
  -keyout ca.key -out ca.pem >/dev/null 2>&1
