# What a Windows machine trusts, and what a certificate looks like when it reads one.
#
# One command per line, same shape as a netlab steps file.
#
# Linux keeps its roots in a bundle file and openssl reads them. Windows keeps
# them in a certificate store with a drive letter, which is the difference that
# matters: the trust decision is made by the operating system rather than by the
# library, so every application inherits it and no application has to be told.

# How many organisations this machine trusts as a root, without anybody choosing
(Get-ChildItem Cert:\LocalMachine\Root).Count

# Four of them, to show what a root actually is
Get-ChildItem Cert:\LocalMachine\Root | Sort-Object Subject | Select-Object -First 4 Subject, NotAfter | Format-Table -AutoSize

# The certificate a real server presents, read the way Windows reads it
$c = [Net.HttpWebRequest]::Create('https://rlwilliamson.dev'); $c.Timeout = 20000; $c.GetResponse() | Out-Null; $c.ServicePoint.Certificate | Format-List Subject, Issuer, @{n='NotBefore';e={$_.GetEffectiveDateString()}}, @{n='NotAfter';e={$_.GetExpirationDateString()}}, @{n='Serial';e={$_.GetSerialNumberString()}}

# A root is self-issued, which is the whole definition. Subject and issuer match.
Get-ChildItem Cert:\LocalMachine\Root | Where-Object { $_.Subject -eq $_.Issuer } | Measure-Object | Select-Object -ExpandProperty Count
