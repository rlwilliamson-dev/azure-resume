# Capturing packets on Windows without installing anything.
#
# One command per line, same shape as a netlab steps file.
#
# Topic 39 uses tcpdump on Linux. Windows has shipped its own capture engine
# since Windows 10 1809 and Windows Server 2019, and most people who need a
# capture on Windows still go and download something first.

# It is already here
Get-Command pktmon | Select-Object Name, Version | Format-Table -AutoSize

# What it can do, which is more than record packets
pktmon --help 2>&1 | Select-Object -Skip 2 -First 12

# Every component it can attach to, counted, and the first few
(pktmon list | Measure-Object -Line).Lines
