# Whether the cheapest honeyfile implementation works on Windows at all.
#
# One command per line, same shape as a netlab steps file.
#
# The Linux column of this topic checks a mount option. Windows has no mount
# option for it: last access time is one machine-wide setting, and it has been
# off by default for long enough that the technique usually does not work here
# until somebody turns it on.

# What this volume's policy actually is, which is the whole question
fsutil behavior query disablelastaccess

# A honeyfile, with its recorded access time set months into the past
$f = "$env:TEMP\passwords_final.csv"; Set-Content -Path $f -Value "server,user,password" -NoNewline; (Get-Item $f).LastAccessTime = [datetime]'2026-03-14 09:12:00'; (Get-Item $f).LastAccessTime.ToString('yyyy-MM-dd HH:mm:ss')

# Somebody opens it, and this is what the share shows afterwards
Get-Content $f | Out-Null; Start-Sleep -Seconds 3; (Get-Item $f).LastAccessTime.ToString('yyyy-MM-dd HH:mm:ss')

# The route that does not depend on timestamps, and whether it is switched on
auditpol /get /subcategory:"File System"
