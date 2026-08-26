# The first thirty seconds on a machine somebody is about to reboot.
#
# One command per line, same shape as a netlab steps file.
#
# macOS has no /proc either. Process state comes from ps and lsof, and the
# hashing command is spelled differently again, which is the practical reason a
# response runbook cannot be written once and used everywhere.

# What is running, with the parent that started it
ps -eo pid,ppid,lstart,comm | head -4

# What is open on the network right now, which the reboot clears
sudo lsof -nP -iTCP 2>/dev/null | head -4

# How long the machine has been up, which bounds everything above
uptime; sysctl -n kern.boottime

# And the hash command, since the Linux column's does not exist here
shasum -a 256 /etc/hosts | awk '{print $1}'
