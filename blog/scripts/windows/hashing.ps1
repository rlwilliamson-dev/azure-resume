# Hashing the same bytes on Windows, to compare with the other two platforms.
#
# One command per line, same shape as a netlab steps file.
#
# This is the one table in the track where all three columns should print the
# same answer, because a digest is arithmetic rather than a policy. The commands
# differ; the output must not.

# The same twenty-eight bytes the Linux and macOS captures hash
$b = [Text.Encoding]::UTF8.GetBytes('correct horse battery staple'); (([Security.Cryptography.SHA256]::Create().ComputeHash($b) | ForEach-Object { $_.ToString('x2') }) -join '')

# The cmdlet a reader would actually use, against a file holding those bytes
[IO.File]::WriteAllBytes("$env:TEMP\a", $b); (Get-FileHash "$env:TEMP\a" -Algorithm SHA256).Hash.ToLower()

# The other tool the exam names for this, which prints the same digest
certutil -hashfile "$env:TEMP\a" SHA256

# What the machine can hash with, since the algorithm is a choice
Get-Command Get-FileHash | ForEach-Object { $_.Parameters['Algorithm'].Attributes.ValidValues } | Sort-Object
