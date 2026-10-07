# Two users and one file nobody has agreed either of them may read, so a topic
# can show authentication and authorization giving different answers about the
# same person.
#
# The payroll file is owned by a group alice is not in and bob is. That is the
# whole setup: there is nothing special about it, which is the point. Bob has
# write as well as read, because a finance team that can only read its own
# payroll file is not a finance team.
dnf -q -y install shadow-utils util-linux diffutils >/dev/null 2>&1
groupadd finance
useradd -m -s /bin/bash alice
useradd -m -s /bin/bash bob -G finance
mkdir -p /srv/finance
printf 'staff,salary\nalice,41000\nbob,44500\n' > /srv/finance/payroll.csv
chgrp finance /srv/finance/payroll.csv
chmod 660 /srv/finance/payroll.csv
