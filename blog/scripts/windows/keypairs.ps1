# Generating a key pair on Windows, to compare with the other two platforms.
#
# One command per line, same shape as a netlab steps file.
#
# The point of comparison is that the bit count on the label does not compare
# across families. An RSA key and an elliptic-curve key with wildly different
# numbers on them are aiming at comparable strength, and the file sizes are the
# visible half of that.

# Which OpenSSH tooling this machine has, since it is a Windows feature
(Get-Command ssh-keygen).Source

# An RSA key pair
ssh-keygen -t rsa -b 3072 -N '""' -f "$env:TEMP\rsa_id" -q -C '""'; (Get-Item "$env:TEMP\rsa_id.pub").Length

# An elliptic-curve key pair, aiming at comparable strength
ssh-keygen -t ed25519 -N '""' -f "$env:TEMP\ed_id" -q -C '""'; (Get-Item "$env:TEMP\ed_id.pub").Length

# What the tool says each one is worth
ssh-keygen -l -f "$env:TEMP\rsa_id.pub"; ssh-keygen -l -f "$env:TEMP\ed_id.pub"

# The other route Windows offers, which does not go through a file
$rsa = [Security.Cryptography.RSA]::Create(3072); "$($rsa.KeySize) bit RSA, $($rsa.ExportRSAPublicKey().Length) byte public key"
