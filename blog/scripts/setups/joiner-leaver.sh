#!/usr/bin/env sh
# One account taken through three role changes, so a topic can show what
# accumulates rather than describing it. Every group here is one somebody would
# have had a reason to add at the time.
dnf -q -y install shadow-utils util-linux >/dev/null 2>&1
for g in support finance-readonly finance deploy oncall dba archive-admin; do groupadd "$g" 2>/dev/null; done
useradd -m -c "joined as support" sam 2>/dev/null
usermod -aG support sam
usermod -aG finance-readonly,finance sam
usermod -aG deploy,oncall sam
usermod -aG dba,archive-admin sam
echo "sam:Correct-Horse-Battery" | chpasswd
