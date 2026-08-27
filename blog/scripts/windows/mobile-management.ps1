# What device management can address on a Windows machine, and whether this one is managed.
#
# One command per line, same shape as a netlab steps file.
#
# The topic is about ownership models, and the question underneath all three is
# what the organisation can see, set and remove. On Windows that surface is a WMI
# namespace, so it can be enumerated rather than described.

# Whether this machine is joined or enrolled in anything at all
dsregcmd /status | Select-String -Pattern 'AzureAdJoined|EnterpriseJoined|DomainJoined|MDMUrl' | ForEach-Object { $_.Line.Trim() }

# How many separate areas a management server can address through the MDM namespace
(Get-CimClass -Namespace root\cimv2\mdm\dmmap -ErrorAction SilentlyContinue | Measure-Object).Count

# A sample of them, which is what "the organisation can enforce this" means in practice
Get-CimClass -Namespace root\cimv2\mdm\dmmap -ErrorAction SilentlyContinue | Select-Object -ExpandProperty CimClassName | Where-Object { $_ -match 'Policy|Wipe|Password|Encryption|Firewall|Application' } | Sort-Object | Select-Object -First 10

# Whether a remote wipe is one of them, and what it is called
Get-CimClass -Namespace root\cimv2\mdm\dmmap -ErrorAction SilentlyContinue | Select-Object -ExpandProperty CimClassName | Where-Object { $_ -match 'Wipe' }
