# What a code signature proves on Windows, and what it does not.
#
# One command per line, same shape as a netlab steps file.
#
# The Linux column of this topic verifies a package signature with rpm -K. The
# Windows equivalent verifies a signature embedded in the executable itself,
# which is a different granularity: the unit signed is the file rather than the
# package, so there is no signature at all on anything the vendor did not build.

# A system binary, and who signed it
Get-AuthenticodeSignature C:\Windows\System32\notepad.exe | Select-Object Status, @{n='Signer';e={$_.SignerCertificate.Subject -replace ',.*',''}} | Format-List

# The same check on a file nobody signed, which is most of what runs on a machine
Set-Content -Path $env:TEMP\helper.ps1 -Value 'Write-Output "hello"'; Get-AuthenticodeSignature $env:TEMP\helper.ps1 | Select-Object Status, StatusMessage | Format-List

# A signed binary with one byte changed, to see what the signature is actually over
Copy-Item C:\Windows\System32\notepad.exe $env:TEMP\tampered.exe -Force; $b = [IO.File]::ReadAllBytes("$env:TEMP\tampered.exe"); $b[40000] = $b[40000] -bxor 0xFF; [IO.File]::WriteAllBytes("$env:TEMP\tampered.exe", $b); (Get-AuthenticodeSignature $env:TEMP\tampered.exe).Status

# Whether the machine would refuse to run the unsigned one
Get-ExecutionPolicy -List | Format-Table -AutoSize
