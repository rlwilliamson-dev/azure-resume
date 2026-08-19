# Name resolution tools as macOS provides them.
#
# One command per line, same shape as a netlab steps file.
#
# nslookup is here, the tool the exam names, and so is dig, which most people
# reach for because it shows the answer section, the flags and the authority in
# full. A forward lookup turns a name into an address; a reverse lookup turns an
# address back into a name.

# A forward lookup through the configured resolver, the tool the exam names
nslookup example.com

# The same question through dig, which shows the answer section and the flags
dig +noall +answer +comments example.com A

# Asking a specific server rather than the default one
dig @1.1.1.1 +noall +answer example.com A

# A reverse lookup, address back to a name
dig +noall +answer -x 8.8.8.8
