# One RSA key pair and one elliptic-curve key pair, plus a megabyte of data, so
# that a topic can compare what each kind of cryptography is for without the
# generation commands filling the transcript.
#
# The data is zeros rather than random, because the point is the time taken and
# a reproducible input makes the digests in the same block checkable.
dnf -q -y install openssl >/dev/null 2>&1
mkdir -p /root/keys && cd /root/keys
openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -out rsa.key >/dev/null 2>&1
openssl pkey -in rsa.key -pubout -out rsa.pub >/dev/null 2>&1
openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:P-256 -out ec.key >/dev/null 2>&1
openssl pkey -in ec.key -pubout -out ec.pub >/dev/null 2>&1
head -c 1048576 /dev/zero > payload.bin
