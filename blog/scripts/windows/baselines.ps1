# How you check a Windows machine against a published baseline.
#
# One command per line, same shape as a netlab steps file.
#
# The Linux column of this topic runs oscap against a datastream that ships with
# the distribution: content and scanner arrive together in two packages, and the
# scanner reports pass, fail or notapplicable per rule. Windows has the policy
# engine in the box and neither the content nor the per-rule report, so this
# builds a baseline by hand and does the comparison itself, which is the finding.

# Whether anything resembling a SCAP scanner is present at all
Get-Command oscap, scap, Invoke-ScapScan -ErrorAction SilentlyContinue | Measure-Object | Select-Object -ExpandProperty Count

# The local security policy exported as a template, which is the baseline format Windows uses
secedit /export /cfg $env:TEMP\current.inf /quiet; Select-String -Path $env:TEMP\current.inf -Pattern '^(MinimumPasswordLength|MaximumPasswordAge|LockoutBadCount) ' | ForEach-Object { $_.Line }

# How many settings that export carries, against the 323 rules the Linux profile evaluated
(Select-String -Path $env:TEMP\current.inf -Pattern '^\S+\s*=' | Measure-Object).Count

# The comparison, which nothing in the box will do for you
$want = @{ MinimumPasswordLength = 14; MaximumPasswordAge = 30; LockoutBadCount = 5 }; $have = @{}; Select-String -Path $env:TEMP\current.inf -Pattern '^(\S+) = (\S+)' | ForEach-Object { $have[$_.Matches[0].Groups[1].Value] = $_.Matches[0].Groups[2].Value }; $want.Keys | Sort-Object | ForEach-Object { "{0,-22} want {1,-4} have {2,-4} {3}" -f $_, $want[$_], $have[$_], $(if ([int]$have[$_] -eq $want[$_]) { 'pass' } else { 'fail' }) }
