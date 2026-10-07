#!/usr/bin/env sh
# Filesystem tools, so a topic can put a known string on a real block device,
# delete the file that held it, and then look at the device again.
dnf -q -y install e2fsprogs util-linux coreutils >/dev/null 2>&1 || true
