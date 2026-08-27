# What is listening, and how much of it anybody asked for.
#
# One command per line, same shape as a netlab steps file.
#
# The Linux column counts listening sockets with ss and watches the number rise
# as services are installed. Windows starts from a much higher number, because
# the roles that produce it ship enabled, which changes what a baseline means.

# Everything listening, counted, on a machine nobody has configured
(Get-NetTCPConnection -State Listen | Select-Object -Unique LocalPort | Measure-Object).Count

# How many of those belong to a process somebody installed, against the system itself
Get-NetTCPConnection -State Listen | Select-Object -Unique LocalPort, OwningProcess | ForEach-Object { (Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue).ProcessName } | Group-Object | Sort-Object Count -Descending | Select-Object -First 5 Count, Name | Format-Table -AutoSize

# Whether any of them is reachable from anywhere rather than from this machine
Get-NetTCPConnection -State Listen | Where-Object { $_.LocalAddress -eq '0.0.0.0' } | Select-Object -Unique LocalPort | Measure-Object | Select-Object -ExpandProperty Count

# And what the firewall would do about a connection to one of them
(Get-NetFirewallProfile | Where-Object { $_.Name -eq 'Public' }).DefaultInboundAction
