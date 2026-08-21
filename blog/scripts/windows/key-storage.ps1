# Where a Windows machine can put a key so the operating system cannot hand it over.
#
# One command per line, same shape as a netlab steps file.
#
# The question this answers is not whether the machine is encrypted. It is where
# the key lives, because a key in a file on the same disk is protected by nothing
# once somebody has the disk.

# Whether this machine has a trusted platform module, and what it says about itself
Get-Tpm | Format-List TpmPresent, TpmReady, TpmEnabled, ManufacturerIdTxt, ManufacturerVersion

# What the volume encryption thinks, which is a separate question from the TPM
Get-BitLockerVolume -ErrorAction SilentlyContinue | Format-List MountPoint, VolumeStatus, ProtectionStatus, KeyProtector

# The store where Windows keeps keys that never leave the machine
certutil -key -user 2>&1 | Select-Object -First 6

# Which cryptographic providers are available to hold a key, hardware included
certutil -csplist 2>&1 | Select-String "Provider Name" | Select-Object -First 8
