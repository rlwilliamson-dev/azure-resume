# How you check a Windows machine against a published baseline.
#
# One command per line, same shape as a netlab steps file.
#
# The Linux column of this topic runs oscap against a datastream that ships with
# the distribution: the content and the scanner arrive together in two packages.
# Windows splits those. The analysis engine is in the box and the content is not,
# so the run below has to build its own baseline first, which is the finding.

# Whether anything resembling a SCAP scanner is present at all
Get-Command oscap, scap, Invoke-ScapScan -ErrorAction SilentlyContinue | Measure-Object | Select-Object -ExpandProperty Count

# The local security policy exported as a template, which is the baseline format Windows uses
secedit /export /cfg $env:TEMP\current.inf /quiet; Select-String -Path $env:TEMP\current.inf -Pattern '^(MinimumPasswordLength|MaximumPasswordAge|LockoutBadCount) ' | ForEach-Object { $_.Line }

# A stricter baseline, written by hand because nothing shipped one
(Get-Content $env:TEMP\current.inf) -replace '^MinimumPasswordLength = .*','MinimumPasswordLength = 14' -replace '^MaximumPasswordAge = .*','MaximumPasswordAge = 30' -replace '^LockoutBadCount = .*','LockoutBadCount = 5' | Set-Content -Encoding Unicode $env:TEMP\wanted.inf; Select-String -Path $env:TEMP\wanted.inf -Pattern '^(MinimumPasswordLength|MaximumPasswordAge|LockoutBadCount) ' | ForEach-Object { $_.Line }

# The machine measured against it, which is the closest in-box equivalent of a benchmark run
secedit /analyze /db $env:TEMP\analyze.sdb /cfg $env:TEMP\wanted.inf /log $env:TEMP\analyze.log /quiet; Select-String -Path $env:TEMP\analyze.log -Pattern 'Mismatch' | ForEach-Object { $_.Line.Trim() }

# How many settings that baseline carries, against the 323 rules the Linux profile evaluated
(Select-String -Path $env:TEMP\wanted.inf -Pattern '^\S+\s*=' | Measure-Object).Count
