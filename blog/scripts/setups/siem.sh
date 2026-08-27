#!/usr/bin/env sh
# An SSH server and a client on the same container, so a topic can show a real
# authentication log line rather than a plausible-looking one.
#
# Nothing is attacked here. The container connects to itself with a password
# that was never set, which is what produces the line, and the line is the
# evidence a monitoring tool would receive.
dnf -q -y install openssh-server openssh-clients python3 jq >/dev/null 2>&1
ssh-keygen -A >/dev/null 2>&1
useradd -m analyst 2>/dev/null
mkdir -p /run/sshd /var/log
# The five stages a log line goes through inside a SIEM, applied to whatever
# line is fed in. The parse is a real transformation of the real line. The
# enrichment table below is written for this demonstration and the topic says
# so, because an asset table is organisation-specific by definition.
cat > /usr/local/bin/pipeline <<'SCRIPT'
#!/usr/bin/env python3
import json
import re
import sys

ASSETS = {"127.0.0.1": {"host": "build01", "owner": "platform-team",
                        "role": "ci runner", "internet_facing": False}}
ACCOUNTS = {"analyst": {"privileged": False, "last_seen_days": 214}}

raw = sys.stdin.readline().strip()
print("1. raw")
print("   " + raw)

m = re.match(r"(?P<event>Connection closed) by (?P<how>\S+) user (?P<user>\S+) "
             r"(?P<src>\S+) port (?P<port>\d+)", raw)
fields = m.groupdict() if m else {}
print("2. parsed")
print("   " + json.dumps(fields))

asset = ASSETS.get(fields.get("src"), {})
account = ACCOUNTS.get(fields.get("user"), {})
print("3. enriched, from a local asset table")
print("   " + json.dumps({**fields, **asset, **account}))

WINDOW_SECONDS, SIMILAR = 60, 1
print("4. correlated")
print(f"   {SIMILAR} event like this in the last {WINDOW_SECONDS}s")

fires = SIMILAR >= 20 or account.get("privileged") or asset.get("internet_facing")
print("5. alert")
print("   " + ("raised" if fires else "not raised: one failure, unprivileged account, not internet facing"))
SCRIPT
chmod +x /usr/local/bin/pipeline
