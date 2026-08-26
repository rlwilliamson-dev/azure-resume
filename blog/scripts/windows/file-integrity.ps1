# Whether this machine can tell you its own files are unmodified.
#
# One command per line, same shape as a netlab steps file.
#
# The Linux column asks the package database, which holds a hash of every file
# it installed. Windows has a component store rather than a package database,
# so the same question is answered by a different subsystem with a much coarser
# report.

# The component store's own consistency, which is the nearest equivalent question
DISM /Online /Cleanup-Image /ScanHealth 2>&1 | Select-String -Pattern 'no component store corruption|corruption|completed' | ForEach-Object { $_.Line.Trim() }

# Whether a signed system binary still matches its signature, one file at a time
Get-AuthenticodeSignature C:\Windows\System32\cmd.exe | Select-Object Status | Format-List

# What a hash of one file looks like, since there is no per-file database to compare against
Get-FileHash C:\Windows\System32\cmd.exe -Algorithm SHA256 | Select-Object -ExpandProperty Hash

# Whether anything is watching for changes, which is a separate subsystem again
auditpol /get /subcategory:"File System" 2>&1 | Select-String -Pattern 'File System' | Select-Object -Last 1 | ForEach-Object { $_.Line.Trim() }
