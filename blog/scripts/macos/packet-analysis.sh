# Reading a handshake off the wire, on a Mac.
#
# One command per line, same shape as a netlab steps file.
#
# The namespace captures for the packet analysis topic run tcpdump inside a
# built network. macOS ships the same tool, so the point of this transcript is
# that the reading is identical and only the interface name changes.
#
# Traffic is generated on purpose in the background, because a runner is idle and
# a capture of an idle machine shows nothing. The capture stops itself after a
# fixed number of packets rather than after a time, so this cannot hang.

# Some traffic for the capture to see, made in the background
(for i in 1 2 3 4 5 6 7 8; do curl -s -o /dev/null -m 4 https://1.1.1.1 >/dev/null 2>&1; sleep 1; done) &

# Handshake and reset packets only, which is the filter that answers "did the
# connection open". Eight of them and it stops
sudo tcpdump -n -i en0 -c 8 "tcp[tcpflags] & (tcp-syn|tcp-rst) != 0" 2>/dev/null

# The same filter written by name rather than by flag bits, which is what most
# people type and what the manual documents
sudo tcpdump -n -i en0 -c 4 "tcp[tcpflags] & tcp-syn != 0 and port 443" 2>/dev/null
