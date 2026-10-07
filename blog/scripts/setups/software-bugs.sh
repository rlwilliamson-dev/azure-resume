#!/usr/bin/env sh
# Two programs that contain the two bug classes this topic is about, and the
# tooling to look at them. Neither is exploited here: the first is measured and
# the second is inspected, because the block rule is evidence rather than attack.
dnf -q -y install gcc binutils python3 >/dev/null 2>&1
mkdir -p /srv/bugs
cat > /srv/bugs/toctou.py <<'PY'
#!/usr/bin/env python3
"""Measure the gap between checking a file and using it."""
import os
import statistics
import time

PATH = "/srv/bugs/config"
open(PATH, "w").write("setting=1\n")

gaps = []
for _ in range(2000):
    start = time.perf_counter_ns()
    if os.access(PATH, os.R_OK):          # the check
        fh = open(PATH)                    # the use
        fh.read()
        fh.close()
    gaps.append(time.perf_counter_ns() - start)

gaps.sort()
print(f"runs: {len(gaps)}")
print(f"median gap between the check and the use: {statistics.median(gaps):,.0f} ns")
print(f"slowest one in this run:                  {gaps[-1]:,.0f} ns")
print(f"that is {gaps[-1] / 1000:,.1f} microseconds during which the name could point somewhere else")
PY
cat > /srv/bugs/overflow.c <<'C'
#include <stdio.h>
#include <string.h>

void store_name(const char *input) {
    char name[64];
    strcpy(name, input);          /* no bound anywhere in this line */
    printf("stored: %s\n", name);
}

int main(int argc, char **argv) {
    if (argc > 1) store_name(argv[1]);
    return 0;
}
C
