# TCP connection states as macOS reports them.
#
# One command per line, same shape as a netlab steps file.
#
# There is no ss here. BSD netstat takes different flags from the Linux one, so
# a reader on a Mac following a Linux page gets an error rather than output.

# BSD netstat, with the flags it actually wants
netstat -an -p tcp | head -12

# The lingering close state, spelled with an underscore here as on Windows
netstat -an -p tcp | grep TIME_WAIT | head -3
