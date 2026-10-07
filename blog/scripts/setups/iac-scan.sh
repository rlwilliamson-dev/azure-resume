#!/usr/bin/env sh
# An infrastructure-as-code template with a storage bucket in it, and a scanner
# reading the template before anything exists. No cloud account is involved and
# no provider is called: the scanner reads text and reports what the text would
# build, which is the whole argument for writing infrastructure down.
dnf -q -y install python3 python3-pip >/dev/null 2>&1
pip3 -q install checkov >/dev/null 2>&1

mkdir -p /srv/iac
cat > /srv/iac/main.tf <<'TF'
resource "aws_s3_bucket" "reports" {
  bucket = "quarterly-reports"
}

resource "aws_s3_bucket_public_access_block" "reports" {
  bucket                  = aws_s3_bucket.reports.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}
TF

cat > /usr/local/bin/iac-scan <<'SCRIPT'
#!/usr/bin/env python3
# Scan the template and print one line per check: the verdict, the check's id,
# and its name in the scanner's own wording, with the "Ensure" prefix dropped and
# anything past sixty characters cut with an ellipsis rather than reworded.
import json
import subprocess

TEMPLATE = "/srv/iac/main.tf"
out = subprocess.run(["checkov", "-f", TEMPLATE, "-o", "json"],
                     capture_output=True, text=True).stdout
results = json.loads(out)["results"]
lines = sum(1 for _ in open(TEMPLATE))
passed, failed = results["passed_checks"], results["failed_checks"]
print(f"{len(passed)} passed, {len(failed)} failed, from {lines} lines of template")
print()
for verdict, checks in (("pass", passed), ("FAIL", failed)):
    for c in checks:
        name = c["check_name"].removeprefix("Ensure ").removeprefix("that ")
        name = name if len(name) <= 60 else name[:57] + "..."
        print(f"{verdict}  {c['check_id']:<12} {name}")
SCRIPT
chmod +x /usr/local/bin/iac-scan
