# Query certificate transparency for a domain this project owns.
#
# Every publicly trusted certificate has to be logged, and the logs are public,
# so this is the outside view of a name: every certificate ever issued for it,
# by whom, and when. That is the observable half of a mis-issuance, and it needs
# nothing but an HTTP client.
#
# Only rlwilliamson.dev is queried, which belongs to this project. The rule for
# this track is that nothing gets probed, scanned or enumerated that is not ours,
# and a transparency log is a lookup rather than a probe either way.
dnf -q -y install curl jq >/dev/null 2>&1
