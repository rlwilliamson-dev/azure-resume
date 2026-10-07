# What this machine can tell you about its own known vulnerabilities.
#
# One command per line, same shape as a netlab steps file.
#
# Linux answers per package and names CVEs. macOS answers per system update and
# names none, so the mapping from an installed version to a fixed vulnerability
# has to come from Apple's published notes rather than from the machine.

# What the machine says is available, which is the closest thing to an advisory list
softwareupdate -l 2>&1 | head -6

# What has been installed and when, which is what a credentialed scan reads
system_profiler SPInstallHistoryDataType 2>/dev/null | grep -A2 -m3 "Software Update" | head -9

# The build, which is the identifier Apple's security notes are keyed on
sw_vers

# Whether anything on the machine names a CVE it is missing
softwareupdate -l 2>&1 | grep -c CVE
