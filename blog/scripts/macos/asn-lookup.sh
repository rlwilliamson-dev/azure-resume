# Finding the network behind an address, on macOS.
#
# One command per line, same shape as a netlab steps file.
#
# dig and curl both ship with the system, so the first two commands are the
# Linux ones unchanged. jq does not ship, which is the only difference worth a
# line: either install it, or read the JSON with the python3 that is already
# there.

# which organisation holds AS15169, from the Team Cymru DNS service
dig +short AS15169.asn.cymru.com TXT

# which prefix an address belongs to, and which AS announces it
dig +short 8.8.8.8.origin.asn.cymru.com TXT

# whether that announcement is authorised, read without jq
curl -s "https://stat.ripe.net/data/rpki-validation/data.json?resource=AS15169&prefix=8.8.8.0/24" | python3 -c "import json,sys; print(json.load(sys.stdin)['data']['status'])"
