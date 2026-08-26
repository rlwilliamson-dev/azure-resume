# How much this machine logs, and how much of that is worth reading.
#
# One command per line, same shape as a netlab steps file.
#
# The Linux column counts journal lines by priority. macOS keeps a unified log
# that is far larger and mostly not retained on disk, so the interesting number
# here is how much arrives per hour rather than how much is kept.

# One hour of the unified log, and how much of it is an error or a fault
log show --last 1h --style compact 2>/dev/null | wc -l | tr -d ' '; log show --last 1h --predicate 'messageType == 16 OR messageType == 17' --style compact 2>/dev/null | wc -l | tr -d ' '

# What is actually kept on disk, which is a different question from what was emitted
sudo du -sh /var/db/diagnostics 2>/dev/null; sudo du -sh /private/var/log 2>/dev/null

# The authentication records, which is the subset a security team wants
log show --last 24h --predicate 'process == "sshd" OR eventMessage CONTAINS "authentication"' --style compact 2>/dev/null | wc -l | tr -d ' '

# Whether anything is configured to send these somewhere else
ls /etc/newsyslog.d/ 2>/dev/null | head -4; grep -c . /etc/syslog.conf 2>/dev/null || echo "no syslog.conf"
