# What a Mac trusts, and which of the two openssl binaries on it you are running.
#
# One command per line, same shape as a netlab steps file.
#
# The finding worth having here is the first two commands. Every Linux
# instruction in this track says openssl. A Mac with Homebrew on it has two
# programs by that name, the name resolves to whichever comes first on PATH, and
# the one Apple ships is not OpenSSL at all. So the answer to "what does openssl
# do here" depends on a PATH the reader has probably never looked at.

# Both programs called openssl, in the order the shell will find them
which -a openssl

# The one Apple ships, which is a fork rather than a version
/usr/bin/openssl version

# How many roots the system keychain holds, without anybody choosing them
security find-certificate -a -p /System/Library/Keychains/SystemRootCertificates.keychain | grep -c "BEGIN CERTIFICATE"

# The certificate a real server presents, read with the tool Apple ships
/usr/bin/openssl s_client -connect rlwilliamson.dev:443 -servername rlwilliamson.dev </dev/null 2>/dev/null | /usr/bin/openssl x509 -noout -subject -issuer -dates -serial

# The extension flag the Linux column uses, on the tool Apple ships
/usr/bin/openssl s_client -connect rlwilliamson.dev:443 -servername rlwilliamson.dev </dev/null 2>/dev/null | /usr/bin/openssl x509 -noout -ext subjectAltName 2>&1 | head -3
