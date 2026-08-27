# What a network view of a machine can learn, against what something running on
# the machine can learn about the same service.
#
# One command per line, same shape as a netlab steps file.
#
# The Linux column pairs ss with ps. Windows keeps the two halves in separate
# commands too, and joining them takes an explicit step, which is the practical
# reason agentless tooling stops at the first half.

# The agentless half: which ports answer, and nothing about why
Get-NetTCPConnection -State Listen | Sort-Object LocalPort | Select-Object -First 5 LocalAddress, LocalPort, OwningProcess | Format-Table -AutoSize

# The agent half: what is actually behind one of those ports
Get-NetTCPConnection -State Listen | Sort-Object LocalPort | Select-Object -First 1 | ForEach-Object { Get-Process -Id $_.OwningProcess | Select-Object Id, ProcessName, Path, StartTime } | Format-List

# What no network view could have told you: whether the binary is signed
Get-NetTCPConnection -State Listen | Sort-Object LocalPort | Select-Object -First 1 | ForEach-Object { $p = (Get-Process -Id $_.OwningProcess).Path; if ($p) { (Get-AuthenticodeSignature $p).Status } else { 'no path, protected process' } }

# How many listening ports there are in total, against how many you would guess
(Get-NetTCPConnection -State Listen | Measure-Object).Count
