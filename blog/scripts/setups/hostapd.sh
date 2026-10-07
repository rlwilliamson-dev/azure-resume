#!/usr/bin/env sh
# hostapd, for the access point side of the vocabulary. No radio is involved and
# none is needed: the question is which key management and cipher names the
# current software actually implements, which is a property of the build.
set -e
dnf -q -y install hostapd wpa_supplicant >/dev/null 2>&1
