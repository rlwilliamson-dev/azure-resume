# How a Mac checks whether a certificate has been withdrawn.
#
# One command per line, same shape as a netlab steps file.
#
# Like Windows, macOS evaluates revocation in the operating system rather than in
# each application, through the trust evaluation the security framework performs.
# The command-line surface for it is narrower than the Linux one, which is what a
# reader following a Linux instruction runs into.

# Fetch the certificate this site serves, so the checks below have something real
/usr/bin/openssl s_client -connect rlwilliamson.dev:443 -servername rlwilliamson.dev </dev/null 2>/dev/null | sed -n '/BEGIN CERT/,/END CERT/p' > /tmp/leaf.pem; /usr/bin/openssl x509 -in /tmp/leaf.pem -noout -subject

# Whether the openssl Apple ships has the subcommand the Linux column uses
/usr/bin/openssl ocsp -help 2>&1 | head -2

# The system's own trust evaluation, which is what an application gets
security verify-cert -c /tmp/leaf.pem -p ssl 2>&1 | sed $'s/\033\[[0-9;]*m//g' | head -4

# Whether the server offered a stapled status, asked with the tool that is here
/usr/bin/openssl s_client -connect rlwilliamson.dev:443 -servername rlwilliamson.dev -status </dev/null 2>&1 | grep -E "OCSP response|Cert Status" | head -3
