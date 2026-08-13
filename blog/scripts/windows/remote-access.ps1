# What Windows brings to managing something else remotely.
#
# One command per line, same shape as a netlab steps file.
#
# Topic 51 compares four ways in. The one that changed most recently is SSH:
# Windows shipped no client at all for two decades and now installs OpenSSH by
# default, which means the commands on that page work here unchanged.

# The client, which is the same OpenSSH as everywhere else
ssh -V 2>&1

# Whether this machine will also accept connections
Get-Service sshd -ErrorAction SilentlyContinue | Format-Table Name, Status, StartType -AutoSize

Get-WindowsCapability -Online -Name "OpenSSH*" | Select-Object Name, State | Format-Table -AutoSize

# The serial side, which needs a cable rather than a network
[System.IO.Ports.SerialPort]::GetPortNames() | Measure-Object | Select-Object -ExpandProperty Count
