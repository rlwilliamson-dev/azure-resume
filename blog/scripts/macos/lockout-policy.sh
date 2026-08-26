# What this machine's account lockout policy is, and whether a failure is recorded.
#
# One command per line, same shape as a netlab steps file.
#
# The Linux capture on the topic page configures a threshold and watches the
# counter. macOS keeps both the policy and the counter in the user record, so
# the same two questions are asked of the directory rather than of a file.

# Whether a global password policy is set on this machine at all
pwpolicy -getglobalpolicy 2>&1 | head -3

# The account policy for this user, which is where a failed-attempt limit would appear
pwpolicy -u "$(id -un)" -getaccountpolicies 2>&1 | head -20

# Whether a per-account failure counter exists here, and what it currently holds
dscl . -readpl "/Users/$(id -un)" accountPolicyData failedLoginCount 2>&1 | head -3

# What the system's own password hint says the length floor is
sysadminctl -screenLock status 2>&1 | head -2
