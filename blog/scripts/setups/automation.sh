#!/usr/bin/env sh
# A provisioning script and a manifest of new starters, so a topic can run the
# same automation twice and then run it with one field wrong.
dnf -q -y install shadow-utils python3 >/dev/null 2>&1
for g in staff engineering finance sales support; do groupadd "$g" 2>/dev/null; done
cat > /srv/starters.csv <<'CSV'
name,team,shell
avery,engineering,/bin/bash
blake,finance,/bin/bash
casey,sales,/sbin/nologin
devon,support,/bin/bash
ellis,engineering,/bin/bash
CSV
cat > /usr/local/bin/provision <<'SCRIPT'
#!/usr/bin/env python3
import csv
import subprocess
import sys

override = sys.argv[1] if len(sys.argv) > 1 else None
created, skipped = 0, 0
for row in csv.DictReader(open("/srv/starters.csv")):
    team = override or row["team"]
    exists = subprocess.run(["id", row["name"]], capture_output=True).returncode == 0
    if exists:
        skipped += 1
        continue
    subprocess.run(["useradd", "-m", "-s", row["shell"], "-G", f"staff,{team}", row["name"]],
                   capture_output=True)
    created += 1
print(f"created {created}, already present {skipped}")
SCRIPT
chmod +x /usr/local/bin/provision
