# What sanitizing storage means on Windows, and what decides which method applies.
#
# One command per line, same shape as a netlab steps file.
#
# The Linux column of this topic overwrites a whole device and greps it. Windows
# has an overwrite tool too, and on a machine with full-disk encryption the
# interesting answer is a different one: destroy the key and the ciphertext is
# already unreadable.

# What kind of media this is, which decides whether overwriting is even the right method
Get-PhysicalDisk | Select-Object FriendlyName, MediaType, @{n='SizeGB';e={[int]($_.Size/1GB)}} | Format-Table -AutoSize

# Whether the volume is encrypted, because that changes sanitization into a key problem
manage-bde -status C: 2>&1 | Select-String -Pattern 'Conversion Status|Percentage Encrypted|Protection Status' | ForEach-Object { $_.Line.Trim() }

# The built-in tool for overwriting the free space a deleted file left behind
cipher /? | Select-String -Pattern '/W' -Context 0,3 | Select-Object -First 1 | ForEach-Object { $_.Line.Trim(); $_.Context.PostContext | ForEach-Object { $_.Trim() } }

# Whether a quick format and a full format differ in what they leave on the disk
Get-Help Format-Volume -Parameter Full 2>&1 | Select-String -Pattern 'zero|overwrit|full' | Select-Object -First 3 | ForEach-Object { $_.Line.Trim() }
