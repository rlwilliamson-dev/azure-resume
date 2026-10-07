# What is listening, and how much of it anybody asked for.
#
# One command per line, same shape as a netlab steps file.
#
# The Linux column counts listening sockets as services are installed. macOS
# starts from a very small number and the interesting question is different:
# what is bound to every address rather than only to this machine.

# Everything listening, counted
sudo lsof -nP -iTCP -sTCP:LISTEN 2>/dev/null | tail -n +2 | wc -l | tr -d ' '

# Which processes hold them, which on this platform is mostly one answer
sudo lsof -nP -iTCP -sTCP:LISTEN 2>/dev/null | tail -n +2 | awk '{print $1}' | sort | uniq -c | sort -rn | head -4

# How many are bound to every address rather than to loopback
sudo lsof -nP -iTCP -sTCP:LISTEN 2>/dev/null | awk '$9 ~ /^\*:/ {print $9}' | sort -u | wc -l | tr -d ' '

# And whether the packet filter would do anything about a connection to one
sudo pfctl -s info 2>&1 | head -3 | tail -1
