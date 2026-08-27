#!/usr/bin/env sh
# Three public services, one identifier, so a topic can put the three numbers
# for a CVE next to each other rather than describing them one at a time.
#
# The helper exists so the captured command reads as the question being asked.
# Everything it prints comes from NVD, FIRST and CISA at the moment of capture.
dnf -q -y install curl jq >/dev/null 2>&1
cat > /usr/local/bin/three-numbers <<'SCRIPT'
#!/usr/bin/env sh
cve="$1"
nvd=$(curl -s "https://services.nvd.nist.gov/rest/json/cves/2.0?cveId=$cve")
epss=$(curl -s "https://api.first.org/data/v1/epss?cve=$cve")
kev=$(curl -s "https://www.cisa.gov/sites/default/files/feeds/known_exploited_vulnerabilities.json")
printf '%s\n' "$cve"
printf '%s\n' "$nvd" | jq -r '.vulnerabilities[0].cve.metrics.cvssMetricV31[0].cvssData |
  "  CVSS   " + (.baseScore|tostring) + " " + .baseSeverity + "   " + .vectorString'
printf '%s\n' "$epss" | jq -r '.data[0] |
  "  EPSS   " + (((.epss|tonumber)*100*1000|round)/1000|tostring) + "% chance in the next 30 days, " +
  (((.percentile|tonumber)*100*10|round)/10|tostring) + "th percentile"'
printf '%s\n' "$kev" | jq -r --arg c "$cve" '
  if any(.vulnerabilities[]; .cveID == $c)
  then (.vulnerabilities[] | select(.cveID==$c) |
    "  KEV    listed " + .dateAdded + ", ransomware use: " + .knownRansomwareCampaignUse)
  else "  KEV    not listed" end'
SCRIPT
chmod +x /usr/local/bin/three-numbers
