# How this machine enforces policy on itself, and how much of it there is.
#
# One command per line, same shape as a netlab steps file.
#
# The Linux column asks SELinux what it is enforcing and gets a mode and a
# policy name. Windows has no equivalent mandatory access control layer in the
# same sense: what it has is Group Policy, which is settings applied to the
# configuration rather than a label on every object.

# Whether any policy is applied at all, and from where
gpresult /r /scope:computer 2>&1 | Select-String -Pattern 'Applied Group Policy Objects|The following GPOs|N/A|None' | Select-Object -First 4 | ForEach-Object { $_.Line.Trim() }

# The nearest thing to a mandatory model, which is integrity levels on processes
whoami /groups 2>&1 | Select-String -Pattern 'Mandatory Label' | ForEach-Object { $_.Line.Trim() }

# How many audit subcategories exist and how many are actually switched on
$a = auditpol /get /category:* 2>&1; ($a | Select-String -Pattern '^\s{2}\S' | Measure-Object).Count; ($a | Select-String -Pattern 'Success|Failure' | Measure-Object).Count

# Which secure and insecure protocol pairs this machine currently offers
Get-NetTCPConnection -State Listen | Where-Object { $_.LocalPort -in 21,22,23,25,80,443,445,3389,5985,5986 } | Select-Object LocalPort -Unique | Sort-Object LocalPort | ForEach-Object { $_.LocalPort }
