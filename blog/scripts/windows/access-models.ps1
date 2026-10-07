# Which access control model this platform actually implements, read off a file.
#
# One command per line, same shape as a netlab steps file.
#
# The Linux column shows nine permission bits and an owner. Windows stores an
# ordered list of entries instead, which is a richer model and answers the same
# question with a great deal more detail.

# A file, and the full list of who may do what to it
New-Item -Path $env:TEMP\payroll.csv -ItemType File -Force | Out-Null; (Get-Acl $env:TEMP\payroll.csv).Access | Select-Object IdentityReference, FileSystemRights, AccessControlType, IsInherited | Format-Table -AutoSize

# How many distinct rights the model can express, against the three Linux offers
[Enum]::GetNames([System.Security.AccessControl.FileSystemRights]).Count

# Who is permitted to change that list, which is what makes the model discretionary
(Get-Acl $env:TEMP\payroll.csv).Owner

# And the mandatory layer that sits above all of it
(Get-Acl $env:TEMP\payroll.csv).Sddl -replace '.*(S:.*)','$1'; whoami /groups | Select-String 'Mandatory Label' | ForEach-Object { $_.Line.Trim() }
