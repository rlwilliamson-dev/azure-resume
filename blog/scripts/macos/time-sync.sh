# Where the clock comes from, on macOS.
#
# One command per line, same shape as a netlab steps file.
#
# systemsetup answers both halves of the question: which server the machine is
# configured to use, and whether it is using it at all. Those are separate
# settings and a machine can hold a perfectly good server address while
# synchronising to nothing.
#
# sntp is the third command worth knowing and it is not run here. It queries a
# server directly and prints the offset, and on a network that blocks outbound
# NTP it fails with roughly a hundred lines of protocol dump per attempt, which
# is a bad trade for a page. It is named in the prose instead.

# the server this machine is configured to use
sudo systemsetup -getnetworktimeserver

# and whether it is actually using it
sudo systemsetup -getusingnetworktime
