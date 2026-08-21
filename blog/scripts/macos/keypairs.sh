# Generating a key pair on macOS, to compare with the other two platforms.
#
# One command per line, same shape as a netlab steps file.
#
# The point of comparison is that the bit count on the label does not compare
# across families. An RSA key and an elliptic-curve key with wildly different
# numbers on them are aiming at comparable strength, and the file sizes are the
# visible half of that.

# Which ssh-keygen this is, since a Mac often has more than one of everything
which -a ssh-keygen && ssh-keygen -V 2>&1 | head -1 || ssh -V 2>&1

# An RSA key pair
ssh-keygen -t rsa -b 3072 -N '' -f /tmp/rsa_id -q -C '' && wc -c < /tmp/rsa_id.pub

# An elliptic-curve key pair, aiming at comparable strength
ssh-keygen -t ed25519 -N '' -f /tmp/ed_id -q -C '' && wc -c < /tmp/ed_id.pub

# What the tool says each one is worth
ssh-keygen -l -f /tmp/rsa_id.pub; ssh-keygen -l -f /tmp/ed_id.pub

# The key types this build will actually generate
ssh -Q key 2>/dev/null | head -8
