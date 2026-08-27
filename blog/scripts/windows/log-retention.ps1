# How much of its own record this machine keeps, and whether erasing it leaves a mark.
#
# One command per line, same shape as a netlab steps file.
#
# Missing logs is one of the nine indicators, and it is the only one whose
# innocent explanation is usually retention rather than an attacker. So the two
# questions worth asking a machine are how far back it can go, and whether the
# act of clearing the log is itself recorded.

# What the security log is configured to hold, and how it behaves when it fills
Get-WinEvent -ListLog Security | Select-Object LogName, IsEnabled, LogMode, MaximumSizeInBytes, RecordCount | Format-List

# The oldest record still in it, which is the retention this machine actually has rather than the one configured
Get-WinEvent -LogName Security -Oldest -MaxEvents 1 | ForEach-Object { '{0}  oldest record still held, id {1}' -f $_.TimeCreated, $_.Id }

# Whether clearing the security log is itself an event, and whether it has happened here
$c = @(Get-WinEvent -FilterHashtable @{LogName='Security'; Id=1102} -MaxEvents 3 -ErrorAction SilentlyContinue); if ($c.Count) { $c | Select-Object TimeCreated, Id | Format-Table -AutoSize } else { 'no event 1102 present, so this log has not been cleared since it began' }

# How many records the other logs hold, since a gap in one is only visible against the others
Get-WinEvent -ListLog Application, System, 'Microsoft-Windows-PowerShell/Operational' | Select-Object LogName, RecordCount, LogMode, MaximumSizeInBytes | Format-Table -AutoSize
