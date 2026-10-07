# How you check a macOS machine against a published baseline.
#
# One command per line, same shape as a netlab steps file.
#
# Linux ships the content and the scanner together. Windows ships the policy
# engine and leaves you to write the content. macOS ships neither: the baseline
# is a configuration profile that arrives from management, and an unmanaged
# machine has nothing to be measured against.

# Whether anything resembling a SCAP scanner is present at all
command -v oscap scap-workbench 2>/dev/null | wc -l | tr -d ' '

# Which configuration profiles are installed, which is where a macOS baseline lands
sudo /usr/bin/profiles show 2>&1 | head -4

# Whether the machine is enrolled in anything that could send one
sudo /usr/bin/profiles status -type enrollment 2>&1

# Two settings a benchmark would check, asked one at a time because nothing will ask for you
sudo /usr/sbin/systemsetup -getremotelogin 2>&1; /usr/bin/fdesetup status 2>&1; /usr/bin/sudo /usr/bin/pwpolicy getaccountpolicies 2>&1 | head -3
