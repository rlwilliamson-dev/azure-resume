# Whether this machine can tell you its configuration has drifted, and put it back.
#
# One command per line, same shape as a netlab steps file.
#
# Detecting drift and correcting it are separate capabilities and most systems
# have the first without the second. Windows ships both, in two subsystems that
# know nothing about each other, and neither does anything until configured.

# Whether a declarative configuration engine is present and what it is set to do about drift
Get-DscLocalConfigurationManager -ErrorAction SilentlyContinue | Select-Object ConfigurationMode, ConfigurationModeFrequencyMins, RefreshMode, RebootNodeIfNeeded | Format-List

# Whether it has ever applied a configuration to this machine
$s = @(Get-DscConfigurationStatus -All -ErrorAction SilentlyContinue); if ($s.Count) { $s | Select-Object -First 3 Status, StartDate, Type | Format-Table -AutoSize } else { 'no configuration has ever been applied by it' }

# Whether the security settings here match a stored template, asked by the tool built for that comparison
secedit /export /cfg "$env:TEMP\base.inf" > $null; (Get-Content "$env:TEMP\base.inf" | Measure-Object -Line).Lines.ToString() + ' lines exported as the current baseline'; secedit /analyze /db "$env:TEMP\drift.sdb" /cfg "$env:TEMP\base.inf" /log "$env:TEMP\drift.log" /quiet 2>&1 | Out-Null; (Select-String -Path "$env:TEMP\drift.log" -Pattern 'Mismatch' -ErrorAction SilentlyContinue).Count.ToString() + ' settings differ from it'

# Which group policies applied here, since an effective setting can arrive from somewhere other than this machine
gpresult /r /scope:computer 2>&1 | Select-String -Pattern 'Applied Group Policy Objects' -Context 0,2 | ForEach-Object { $_.ToString().Trim() }
