# The services file on macOS, which is where Linux keeps it.
#
# One command per line, same shape as a netlab steps file.

# Same file, same format, same path as Linux
grep -E "^(ssh|domain|http|https|submission|ldap)[[:space:]]" /etc/services
