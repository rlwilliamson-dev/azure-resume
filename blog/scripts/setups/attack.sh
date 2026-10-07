#!/usr/bin/env sh
# Query the published ATT&CK bundle for what one malware family is documented as
# doing, so a topic can show the category overlap rather than asserting it.
dnf -q -y install curl python3 >/dev/null 2>&1
cat > /usr/local/bin/attack-software <<'SCRIPT'
#!/usr/bin/env python3
import json
import subprocess
import sys

URL = ("https://raw.githubusercontent.com/mitre/cti/master/"
       "enterprise-attack/enterprise-attack.json")
raw = subprocess.run(["curl", "-sL", URL], capture_output=True).stdout
bundle = json.loads(raw)
objs = bundle["objects"]

names = [a.lower() for a in sys.argv[1:]]
software = {o["id"]: o for o in objs
            if o.get("type") in ("malware", "tool") and o.get("name", "").lower() in names}
techniques = {o["id"]: o for o in objs if o.get("type") == "attack-pattern"}
rels = [o for o in objs if o.get("type") == "relationship"
        and o.get("relationship_type") == "uses" and o.get("source_ref") in software]

print(f"objects in the published bundle: {len(objs):,}")
for sid, s in software.items():
    used = [techniques[r["target_ref"]] for r in rels if r["target_ref"] in techniques]
    tactics = sorted({p["phase_name"] for t in used for p in t.get("kill_chain_phases", [])})
    labels = ", ".join(s.get("labels", [])) or s["type"]
    print()
    print(f"{s['name']}  ({labels})")
    print(f"  documented techniques: {len(used)}")
    print(f"  stages it appears in:  {len(tactics)}")
    for t in tactics:
        print(f"    {t}")
SCRIPT
chmod +x /usr/local/bin/attack-software
