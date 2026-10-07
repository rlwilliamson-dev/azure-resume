#!/usr/bin/env sh
# Availability arithmetic: what each target allows in downtime, and what
# happens when two components are combined in series or in parallel.
dnf -q -y install python3 >/dev/null 2>&1
cat > /usr/local/bin/availability <<'SCRIPT'
#!/usr/bin/env python3
YEAR = 365.25 * 24 * 3600


def span(seconds):
    parts = []
    for unit, size in (("d", 86400), ("h", 3600), ("m", 60), ("s", 1)):
        if seconds >= size or (unit == "s" and not parts):
            n = int(seconds // size)
            seconds -= n * size
            parts.append(f"{n}{unit}")
        if len(parts) == 2:
            break
    return " ".join(parts)


print(f"{'target':<10} {'downtime a year':>16} {'a month':>10}")
for label in ("99", "99.9", "99.95", "99.99", "99.999"):
    down = (1 - float(label) / 100) * YEAR
    print(f"{label + '%':<10} {span(down):>16} {span(down / 12):>10}")

part = 0.999
series = part * part
parallel = 1 - (1 - part) ** 2
print()
print(f"two components, each {part * 100:g}% available")
print(f"  in series, both needed:     {series * 100:.4f}%  {span((1 - series) * YEAR):>8} a year")
print(f"  in parallel, either works:  {parallel * 100:.4f}%  {span((1 - parallel) * YEAR):>8} a year")
SCRIPT
chmod +x /usr/local/bin/availability
