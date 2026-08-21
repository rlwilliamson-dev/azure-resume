# Asking for particular record types from a Mac.
#
# One command per line, same shape as a netlab steps file.
#
# Topic 46 uses dig against a lab zone. macOS ships dig, so the commands on that
# page work unchanged, which is worth saying plainly because Windows does not.

# The same tool, already installed
dig -v 2>&1 | head -1

dig example.com MX +noall +answer +comments | grep -E "status:|^example"

dig example.com NS +short
