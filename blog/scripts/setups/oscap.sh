#!/usr/bin/env sh
# Install the OpenSCAP scanner and the SCAP Security Guide content for topic 40.
#
# The guide ships one datastream per product. AlmaLinux 10 carries the RHEL 10
# content, which is the point of the topic: a benchmark written for one product
# and evaluated against a machine it was not written for.
set -e
dnf -q -y install openscap-scanner scap-security-guide >/dev/null 2>&1
