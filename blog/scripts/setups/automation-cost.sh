#!/usr/bin/env sh
# The arithmetic behind "automate it", computed rather than asserted, so a topic
# can show where the payback is and where the maintenance line crosses back.
dnf -q -y install python3 >/dev/null 2>&1
cat > /usr/local/bin/payback <<'SCRIPT'
#!/usr/bin/env python3
import sys

RUNS_PER_MONTH = 40
MANUAL_MINUTES = 25
BUILD_HOURS = float(sys.argv[1]) if len(sys.argv) > 1 else 80
MAINT_HOURS_PER_MONTH = float(sys.argv[2]) if len(sys.argv) > 2 else 4

print(f"{RUNS_PER_MONTH} runs a month at {MANUAL_MINUTES} minutes each")
print(f"build cost {BUILD_HOURS:g} hours, maintenance {MAINT_HOURS_PER_MONTH:g} hours a month")
print()
print(f"{'month':>6}  {'manual':>9}  {'automated':>10}  {'saved so far':>13}")
manual = automated = 0.0
crossed = None
for month in range(1, 37):
    manual += RUNS_PER_MONTH * MANUAL_MINUTES / 60
    automated += BUILD_HOURS if month == 1 else 0
    automated += MAINT_HOURS_PER_MONTH
    if crossed is None and automated < manual:
        crossed = month
    if month in (1, 6, 12, 24, 36):
        print(f"{month:>6}  {manual:>8.0f}h  {automated:>9.0f}h  {manual - automated:>12.0f}h")
print()
if crossed:
    print(f"the automated line drops below the manual one in month {crossed}")
else:
    print("the automated line never drops below the manual one in three years")
SCRIPT
chmod +x /usr/local/bin/payback
