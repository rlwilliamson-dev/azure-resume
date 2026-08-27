# What is already hardened on a machine nobody has hardened.
#
# One command per line, same shape as a netlab steps file.
#
# The objective lists endpoint protection, a host firewall, intrusion
# prevention, closing ports and removing software as separate techniques. macOS
# arrives with some of them present and at least one of them switched off, and
# which is which is not visible without asking.

# Whether the application firewall is switched on, and whether it refuses everything inbound
/usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate 2>&1; /usr/libexec/ApplicationFirewall/socketfilterfw --getblockall 2>&1

# How many applications hold an exception to it
/usr/libexec/ApplicationFirewall/socketfilterfw --listapps 2>&1 | head -2

# Which malware definitions this machine holds, since that is the endpoint protection here
defaults read /Library/Apple/System/Library/CoreServices/XProtect.bundle/Contents/Info.plist CFBundleShortVersionString 2>&1

# How many launch items are loaded, which is the closest thing to a count of what runs unasked
launchctl list 2>/dev/null | grep -c .
