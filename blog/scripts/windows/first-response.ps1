# The first thirty seconds on a machine somebody is about to reboot.
#
# One command per line, same shape as a netlab steps file.
#
# The Linux column reads process state through /proc and hashes with sha256sum.
# Windows has no /proc, so the same three questions go to three different
# subsystems, and the hash has its own command.

# What is running, with the parent that started it, which is the sequence an investigation wants
Get-CimInstance Win32_Process | Select-Object -First 4 ProcessId, ParentProcessId, Name, CreationDate | Format-Table -AutoSize

# What each of those has open on the network, which is gone the moment the machine restarts
Get-NetTCPConnection -State Established, Listen | Select-Object -First 4 LocalPort, RemoteAddress, State, OwningProcess | Format-Table -AutoSize

# How long the machine has been up, which bounds everything above
(Get-CimInstance Win32_OperatingSystem).LastBootUpTime

# And the hash command, since the Linux column's does not exist here
Get-FileHash C:\Windows\System32\drivers\etc\hosts -Algorithm SHA256 | Select-Object -ExpandProperty Hash
