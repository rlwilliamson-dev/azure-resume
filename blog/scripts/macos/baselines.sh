# How you check a macOS machine against a published baseline.
#
# One command per line, same shape as a netlab steps file.
#
# Linux ships the content and the scanner in two packages. macOS ships neither.
# The baseline is expressed as configuration profiles, the published benchmark
# content lives in a separate project you generate scripts from, and what the
# machine can tell you unaided is which profiles are currently applied.

# Whether anything resembling a SCAP scanner is present at all
command -v oscap scap-workbench 2>/dev/null | wc -l | tr -d ' '

# Which configuration profiles are installed, which is where a macOS baseline lands
sudo /usr/bin/profiles show 2>&1 | head -6

# The same question through the reporting interface, which is what an MDM console reads
system_profiler SPConfigurationProfileDataType 2>/dev/null | head -8

# Two settings a benchmark would check, asked directly because there is no scanner to ask for you
/usr/bin/sudo /usr/sbin/systemsetup -getremotelogin 2>&1; /usr/bin/pwpolicy getaccountpolicies 2>&1 | head -3
