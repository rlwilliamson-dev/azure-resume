# TCP connection states as Windows reports them.
#
# One command per line, same shape as a netlab steps file.
#
# Objective 5.5 names netstat and does not name ss, which is the reverse of what
# a Linux habit suggests. Topic 09 uses ss throughout because that is what the
# capture environment has, so the Windows spelling of the same states needs to
# be on the page beside it.

# The tool the exam names, and the states it reports
netstat -ano -p TCP | Select-Object -First 12

# Windows writes the lingering close state with an underscore. Linux uses a dash
netstat -ano -p TCP | Select-String "TIME_WAIT" | Select-Object -First 3

# Every connection on the machine, counted by state
Get-NetTCPConnection | Group-Object State | Format-Table Name, Count -AutoSize
