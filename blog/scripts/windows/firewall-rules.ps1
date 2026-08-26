# How the host firewall decides, and whether order means anything here.
#
# One command per line, same shape as a netlab steps file.
#
# The Linux column walks a packet down an ordered list until a rule matches.
# Windows does not evaluate in list order at all: it evaluates by rule type, so
# the question "which rule is first" has no answer and a different question
# decides the outcome.

# How many rules there are, which is the first surprise
(Get-NetFirewallRule | Measure-Object).Count; (Get-NetFirewallRule -Enabled True | Measure-Object).Count

# The default for each profile, which is what applies when nothing matches
Get-NetFirewallProfile | Select-Object Name, Enabled, DefaultInboundAction, DefaultOutboundAction | Format-Table -AutoSize

# Two rules for the same port, one allowing and one blocking, to see which wins
New-NetFirewallRule -DisplayName 'zz-allow-9999' -Direction Inbound -LocalPort 9999 -Protocol TCP -Action Allow | Out-Null; New-NetFirewallRule -DisplayName 'zz-block-9999' -Direction Inbound -LocalPort 9999 -Protocol TCP -Action Block | Out-Null; Get-NetFirewallRule -DisplayName 'zz-*' | Select-Object DisplayName, Action, Enabled | Format-Table -AutoSize

# Whether a rule has any notion of position, which is the question the Linux side turns on
Get-NetFirewallRule -DisplayName 'zz-allow-9999' | Get-Member -MemberType Property | Where-Object { $_.Name -match 'Order|Priority|Index|Position|Sequence' } | Measure-Object | Select-Object -ExpandProperty Count
