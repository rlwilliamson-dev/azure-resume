# What this machine's account lockout policy is, and whether a failure is recorded.
#
# One command per line, same shape as a netlab steps file.
#
# The Linux capture on the topic page configures a threshold and watches the
# counter. macOS keeps both the policy and the counter in the user record, so
# the same two questions are asked of the directory rather than of a file.

# Whether a global password policy is set on this machine at all
out=$(pwpolicy -getglobalpolicy 2>&1); printf '%s\n' "${out:-nothing returned}"

# The account policy for this user, which is where a failed-attempt limit would appear
out=$(pwpolicy -u "$(id -un)" -getaccountpolicies 2>&1 | tail -n +2); printf '%s\n' "${out:-nothing returned}"

# Whether a per-account failure counter exists even when no policy is acting on it
dscl . -readpl "/Users/$(id -un)" accountPolicyData failedLoginCount 2>&1 | head -3

# When that counter last moved, which is the other half of any rate limit
dscl . -readpl "/Users/$(id -un)" accountPolicyData failedLoginTimestamp 2>&1 | head -3

# Whether any configuration profile is installed, since that is how a limit arrives on a managed Mac
sudo profiles show -type configuration 2>&1 | head -4
