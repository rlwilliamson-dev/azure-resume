# How you check a Windows machine against a published baseline.
#
# One command per line, same shape as a netlab steps file.
#
# The Linux column of this topic runs oscap against a datastream that ships with
# the distribution: the content and the scanner arrive together in two packages.
# Windows splits those. The enforcement and analysis engine is in the box and the
# content is not, so the question here is what the machine's policy currently is
# and what analysing it against a template actually reports.

# Whether anything resembling a SCAP scanner is present at all
Get-Command oscap, scap, Invoke-ScapScan -ErrorAction SilentlyContinue | Measure-Object | Select-Object -ExpandProperty Count

# The local security policy, exported as a template, which is the baseline format Windows uses
secedit /export /cfg $env:TEMP\current.inf /quiet; Select-String -Path $env:TEMP\current.inf -Pattern '^(MinimumPasswordLength|PasswordComplexity|LockoutBadCount|MaximumPasswordAge|ClearTextPassword) ' | ForEach-Object { $_.Line }

# Analysing the machine against a template, which is the closest in-box equivalent of a benchmark run
secedit /analyze /db $env:TEMP\analyze.sdb /cfg $env:TEMP\current.inf /log $env:TEMP\analyze.log /quiet; Select-String -Path $env:TEMP\analyze.log -Pattern 'Mismatch|not configured|completed' | Select-Object -First 6 | ForEach-Object { $_.Line.Trim() }

# How many settings the exported baseline actually carries
(Get-Content $env:TEMP\current.inf | Where-Object { $_ -match '^\S+\s*=' }).Count
