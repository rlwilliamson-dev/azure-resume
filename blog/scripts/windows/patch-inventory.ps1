# What this machine can tell you about its own known vulnerabilities.
#
# One command per line, same shape as a netlab steps file.
#
# The Linux column asks the package manager for a list of security advisories
# and gets one CVE at a time. Windows ships fixes as cumulative updates, so the
# same question returns a much shorter list of much larger things, and the CVEs
# each one covers are not on the machine.

# The updates actually installed, which is what a credentialed scan reads
Get-HotFix | Select-Object -Last 4 HotFixID, Description, InstalledOn | Format-Table -AutoSize

# How many that is in total, against the per-package advisory count on the Linux side
(Get-HotFix | Measure-Object).Count

# The build number, which is what decides whether a given fix is present
[System.Environment]::OSVersion.Version.ToString(); (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').UBR

# Whether the machine can name a single CVE it is missing
Get-HotFix | Where-Object { $_.Description -match 'CVE' } | Measure-Object | Select-Object -ExpandProperty Count
