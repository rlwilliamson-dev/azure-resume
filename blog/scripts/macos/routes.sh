# The routing table as macOS prints it.
#
# One command per line, same shape as a netlab steps file.
#
# BSD netstat rather than ip, and the default route is written as the word
# "default" rather than as a prefix of zeros, which hides the arithmetic that
# makes it work.

# the table
netstat -rn -f inet | head -12

# and the decision for one destination, which is the closest thing to ip route get
route -n get 1.1.1.1
