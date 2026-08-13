# What a Mac brings to managing something else remotely.
#
# One command per line, same shape as a netlab steps file.
#
# Topic 51 compares four ways in. Two of them need software on the machine you
# are sitting at, and on macOS both have shipped in the base system for years.

# The client, from the same project as everywhere else
ssh -V 2>&1

# Whether this machine will also accept connections
sudo systemsetup -getremotelogin 2>&1 | head -2

# The serial side, which needs a driver and a cable rather than a network
ls /dev/cu.* 2>/dev/null | head -3
