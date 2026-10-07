# What this machine's account lockout policy is, and whether a failure is recorded.
#
# One command per line, same shape as a netlab steps file.
#
# The Linux capture on the topic page configures a threshold and watches the
# counter. Windows ships with a policy already in place, so the question here is
# what the defaults are and which number decides whether a slow spray trips
# anything.

# The lockout and password policy this machine is running under
net accounts

# The same settings as the security database records them, including the complexity switch
secedit /export /areas SECURITYPOLICY /cfg "$env:TEMP\pol.inf" > $null; Select-String -Path "$env:TEMP\pol.inf" -Pattern 'Lockout|PasswordComplexity|MinimumPasswordLength|PasswordHistorySize' | ForEach-Object { $_.Line.Trim() }

# Whether a failed sign-in is recorded at all, since a lockout nobody can see is one nobody investigates
auditpol /get /subcategory:"Logon" 2>&1 | Select-String 'Logon' | ForEach-Object { $_.Line.Trim() }
