# What an account carries, and what disabling it actually changes.
#
# One command per line, same shape as a netlab steps file.
#
# The Linux column shows group memberships accumulating across role changes and
# a password lock that changes none of them. Windows splits the same information
# across a local account object and a separate group membership query.

# An account created for this capture, with memberships added the way a mover accumulates them
New-LocalUser -Name 'zzsam' -Password (ConvertTo-SecureString 'Correct-Horse-Battery-9' -AsPlainText -Force) -Description 'joined as support' | Out-Null; 'Users','Backup Operators','Remote Desktop Users','Performance Log Users' | ForEach-Object { Add-LocalGroupMember -Group $_ -Member 'zzsam' -ErrorAction SilentlyContinue }; Get-LocalUser zzsam | Select-Object Name, Enabled, PasswordLastSet, LastLogon | Format-List

# What it can currently reach, which is the question the account object does not answer
Get-LocalGroup | ForEach-Object { $g = $_.Name; if (Get-LocalGroupMember -Group $g -ErrorAction SilentlyContinue | Where-Object { $_.Name -like '*zzsam' }) { $g } }

# The leaver step everybody runs
Disable-LocalUser -Name 'zzsam'; Get-LocalUser zzsam | Select-Object Name, Enabled | Format-List

# And what that changed about what the account is a member of
Get-LocalGroup | ForEach-Object { $g = $_.Name; if (Get-LocalGroupMember -Group $g -ErrorAction SilentlyContinue | Where-Object { $_.Name -like '*zzsam' }) { $g } }
