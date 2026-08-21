# A certificate signing request and a self-signed certificate for the same name,
# so a topic can show what each one contains without the generation commands
# filling the transcript.
#
# The name is a .internal domain, which cannot be registered and cannot resolve,
# because a worked example that uses a real name teaches somebody to point a
# request at somebody else's host.
dnf -q -y install openssl ca-certificates >/dev/null 2>&1
mkdir -p /root/pki && cd /root/pki
openssl req -new -newkey rsa:2048 -nodes -keyout svc.key -out svc.csr \
  -subj "/C=GB/O=Example Ltd/CN=payments.example.internal" \
  -addext "subjectAltName=DNS:payments.example.internal,DNS:pay.example.internal" >/dev/null 2>&1
openssl req -x509 -newkey rsa:2048 -nodes -keyout ss.key -out ss.crt -days 365 \
  -subj "/C=GB/O=Example Ltd/CN=payments.example.internal" >/dev/null 2>&1
