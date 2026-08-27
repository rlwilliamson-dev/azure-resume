# What sanitizing storage means on macOS, and the method it will not perform.
#
# One command per line, same shape as a netlab steps file.
#
# The Linux column overwrites a device and greps it. macOS has an overwrite
# command and refuses to run it on the filesystem every current Mac uses, which
# is the finding rather than a limitation of this capture.

# What the boot volume actually is, because that decides what the tools will do
diskutil info / | grep -E "File System Personality|Volume Name|Device Node|Encrypted"

# The levels the overwrite tool offers, read from its own usage text
diskutil secureErase 2>&1 | head -12

# A small disk image to try it on, so nothing real is touched
hdiutil create -size 12m -fs "HFS+" -volname sanitest /tmp/sanitest.dmg >/dev/null 2>&1; hdiutil attach /tmp/sanitest.dmg 2>&1 | tail -1

# The same overwrite, on a filesystem that accepts it and on the boot volume that does not
diskutil secureErase freespace 0 /Volumes/sanitest 2>&1 | tail -3; echo "--- and on the boot volume:"; diskutil secureErase freespace 0 / 2>&1 | tail -2

# Whether the key-destruction route is available instead
fdesetup status; diskutil apfs list 2>/dev/null | grep -E "FileVault|Encrypted" | head -3
