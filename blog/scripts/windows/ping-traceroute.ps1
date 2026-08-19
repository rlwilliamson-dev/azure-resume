# Ping, tracert and a reachability test as Windows spells them.
#
# One command per line, same shape as a netlab steps file.
#
# Objective 5.5 names tracert, not traceroute, and the difference is not only the
# spelling: tracert probes with ICMP echo where the Linux and macOS tools send
# UDP. This runner's network filters ICMP, so ping and tracert time out on a host
# that is plainly up, which is the whole lesson of this topic caught by accident.
# Test-NetConnection asks the other question, whether a TCP service answers.

# Reachability as ping tests it, if the path allows ICMP through
ping -n 2 1.1.1.1

# The same host, asked whether its TCP service answers. Ping and the TCP test can
# disagree, and this is where you find out they are different questions
Test-NetConnection 1.1.1.1 -Port 443 | Format-List ComputerName, RemoteAddress, RemotePort, PingSucceeded, TcpTestSucceeded

# The path to a host, hop by hop, not resolving names, capped so it stays short
tracert -d -h 8 1.1.1.1
