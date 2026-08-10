# What macOS does with the loopback block.
#
# One command per line, same shape as a netlab steps file.
#
# This is the one that breaks the pattern. Linux and Windows answer on any
# address in 127.0.0.0/8. macOS assigns 127.0.0.1 and answers on that alone,
# even though the mask on the interface covers the whole block.

# The mask says the whole block. The address list says one address
ifconfig lo0 | grep -E "inet "

# So this one works
ping -c 2 127.0.0.1

# And this one does not
ping -c 2 -t 3 127.9.9.9
