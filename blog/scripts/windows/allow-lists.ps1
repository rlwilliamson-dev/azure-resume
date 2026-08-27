# Whether this machine restricts which programs may run, and by what mechanism.
#
# One command per line, same shape as a netlab steps file.
#
# An application allow list is the strictest form of least privilege on a host:
# nothing runs unless it is named. Windows has two separate implementations of
# the idea, which is worth seeing, because a machine can have one, both or
# neither and the answer is not visible from the desktop.

# Whether the older allow list has any rules, and whether it is enforcing or only watching
$p = Get-AppLockerPolicy -Effective -ErrorAction SilentlyContinue; if ($p) { $p.RuleCollections | Select-Object RuleCollectionType, EnforcementMode, Count | Format-Table -AutoSize } else { 'no effective AppLocker policy on this machine' }

# Whether the service that would enforce those rules is even running
Get-Service AppIDSvc -ErrorAction SilentlyContinue | Select-Object Name, Status, StartType | Format-Table -AutoSize

# Whether the newer code integrity policy is active, which enforces in the kernel instead
Get-CimInstance -ClassName Win32_DeviceGuard -Namespace root\Microsoft\Windows\DeviceGuard -ErrorAction SilentlyContinue | Select-Object CodeIntegrityPolicyEnforcementStatus, UsermodeCodeIntegrityPolicyEnforcementStatus | Format-List

# What happens by default when neither is configured, asked of an unsigned file this session creates
$f = Join-Path $env:TEMP 'nothing.cmd'; Set-Content -LiteralPath $f -Value 'exit 0'; (Get-AuthenticodeSignature $f).Status; cmd /c "$f" ; "exit code $LASTEXITCODE"
