# Where the clock comes from, on macOS.
#
# One command per line, same shape as a netlab steps file.
#
# Two questions and two tools. systemsetup reports the configuration, which is
# the server and whether the machine is using it at all, and sntp asks a server
# directly and prints the offset without changing anything.

# the server this machine is configured to use
sudo systemsetup -getnetworktimeserver

# and whether it is actually using it
sudo systemsetup -getusingnetworktime

# one query, printing the offset this machine would correct by
sntp time.apple.com
