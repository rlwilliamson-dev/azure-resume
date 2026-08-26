# How much this machine logs, and how much of that is worth reading.
#
# One command per line, same shape as a netlab steps file.
#
# The Linux column counts journal lines by priority. Windows keeps separate
# event logs rather than one stream with a severity field, so the same question
# has to be asked per log, and the answer to "how much is there" depends on
# which of them you thought to ask.

# How many event logs exist, which is the first difference from a single journal
(Get-WinEvent -ListLog * -ErrorAction SilentlyContinue | Where-Object { $_.RecordCount -gt 0 } | Measure-Object).Count

# The four that matter, with how much each holds
Get-WinEvent -ListLog Security, System, Application, 'Microsoft-Windows-Windows Defender/Operational' -ErrorAction SilentlyContinue | Select-Object LogName, RecordCount, @{n='MaxMB';e={[int]($_.MaximumSizeInBytes/1MB)}} | Format-Table -AutoSize

# Everything in the last 24 hours, and how much of it is an error or worse
$since = (Get-Date).AddDays(-1); $all = Get-WinEvent -FilterHashtable @{LogName='System','Application'; StartTime=$since} -ErrorAction SilentlyContinue; "total: $($all.Count)"; $all | Group-Object LevelDisplayName | Sort-Object Count -Descending | Select-Object Count, Name | Format-Table -AutoSize

# Whether the log that records logons is even switched on
auditpol /get /subcategory:"Logon" 2>&1 | Select-String -Pattern 'Logon' | Select-Object -Last 1 | ForEach-Object { $_.Line.Trim() }
