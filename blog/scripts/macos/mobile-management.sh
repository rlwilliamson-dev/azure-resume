# What device management can address on a macOS machine, and whether this one is managed.
#
# One command per line, same shape as a netlab steps file.
#
# On Apple platforms the management surface is configuration profiles rather than
# a queryable namespace, so an unmanaged machine can say that it is unmanaged and
# very little else. That asymmetry is the point of capturing both.

# Whether this machine is enrolled in anything that could manage it
sudo /usr/bin/profiles status -type enrollment 2>&1

# Where a managed setting would land, and what is there now
ls -la /Library/Managed\ Preferences/ 2>&1 | head -4

# The profiles actually installed, in every domain the command will report
sudo /usr/bin/profiles -L 2>&1 | head -4

# The operating system version, which is the floor every enforcement rule sits on
sw_vers; /usr/bin/fdesetup status 2>&1
