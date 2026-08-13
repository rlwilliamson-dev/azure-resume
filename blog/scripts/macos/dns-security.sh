# Whether the tools a Mac ships can speak encrypted DNS.
#
# One command per line, same shape as a netlab steps file.
#
# Topic 47 queries a resolver over TLS from Linux. The question for a reader is
# whether the machine in front of them can do the same, and on macOS the answer
# depends on which piece you mean: the system resolver supports encrypted DNS
# through configuration profiles, and the dig that ships in the base system is
# old enough to predate the option entirely.

# The version, which is the whole answer to the next command
dig -v 2>&1 | head -1

# Ask it to use DNS over TLS and see whether it recognises the request
dig +tls example.com 2>&1 | head -2

# What the system resolver is configured to do, which is a separate question
scutil --dns | grep -iE "flags|reach" | head -3
