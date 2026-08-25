# Whether the cheapest honeyfile implementation works on macOS at all.
#
# One command per line, same shape as a netlab steps file.
#
# macOS keeps access times and does not use relatime, so the technique is more
# reliable here than on Linux. The commands are all different, because these are
# BSD tools rather than GNU ones, which is the thing a reader following the Linux
# column runs into.

# What the boot volume was mounted with, which names an atime option only when it is off
mount | grep -E "on / \(|/System/Volumes/Data \("

# A honeyfile, with its recorded access time set months into the past
printf 'server,user,password\nbackup01,svc_backup,Wint3r2026!\n' > /tmp/passwords_final.csv; touch -a -t 202603140912 /tmp/passwords_final.csv; stat -f '%Sa %N' /tmp/passwords_final.csv

# Somebody opens it, and this is what the share shows afterwards
cat /tmp/passwords_final.csv > /dev/null; sleep 3; stat -f '%Sa %N' /tmp/passwords_final.csv

# The GNU form the Linux column of this topic uses, on this machine
ls -l --time=atime /tmp/passwords_final.csv 2>&1 | head -2
