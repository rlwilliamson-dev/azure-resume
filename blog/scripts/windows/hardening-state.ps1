# What is already hardened on a machine nobody has hardened.
#
# One command per line, same shape as a netlab steps file.
#
# The objective lists endpoint protection, a host firewall, intrusion
# prevention, closing ports and removing software as separate techniques.
# Windows arrives with the first three switched on, which changes the job from
# installing them to knowing what they are set to.

# What the built-in firewall does on each profile with traffic no rule matches
Get-NetFirewallProfile | Select-Object Name, Enabled, DefaultInboundAction, DefaultOutboundAction | Format-Table -AutoSize

# How many rules are enabled, since the default only applies to what none of them match
'{0} of {1} firewall rules are enabled' -f (Get-NetFirewallRule | Where-Object Enabled -eq 'True' | Measure-Object).Count, (Get-NetFirewallRule | Measure-Object).Count

# Whether endpoint protection is running here, and whether its behavioural half is on
Get-MpComputerStatus | Select-Object AMServiceEnabled, RealTimeProtectionEnabled, BehaviorMonitorEnabled, IsTamperProtected | Format-List

# How much optional software is switched on, since every feature is surface somebody has to justify
$f = Get-WindowsOptionalFeature -Online; '{0} of {1} optional features are enabled' -f ($f | Where-Object State -eq 'Enabled').Count, $f.Count
