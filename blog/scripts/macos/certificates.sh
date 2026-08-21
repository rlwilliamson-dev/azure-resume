# What a Mac trusts, and the cryptography library it ships that is not OpenSSL.
#
# One command per line, same shape as a netlab steps file.
#
# The finding worth having here is the first command. Every Linux instruction in
# this track says openssl, and a Mac answers that name with a different
# implementation: LibreSSL, forked from OpenSSL in 2014, with a different version
# number and a different set of subcommands. A reader following a Linux
# instruction on a Mac is not running the tool the instruction meant.

# Which library answers to the name openssl here
openssl version

# How many roots the system keychain holds, without anybody choosing them
security find-certificate -a /System/Library/Keychains/SystemRootCertificates.keychain -p | grep -c "BEGIN CERTIFICATE"

# The certificate a real server presents, read with the tool that is here
openssl s_client -connect rlwilliamson.dev:443 -servername rlwilliamson.dev </dev/null 2>/dev/null | openssl x509 -noout -subject -issuer -dates -serial

# The exact command the Linux column of this topic runs, on this openssl
openssl s_client -connect rlwilliamson.dev:443 -servername rlwilliamson.dev </dev/null 2>/dev/null | openssl x509 -noout -ext subjectAltName 2>&1 | head -3
