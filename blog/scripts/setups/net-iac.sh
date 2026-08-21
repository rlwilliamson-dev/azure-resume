# Setup for the infrastructure-as-code topic. Builds a small git repository whose
# contents are a switch configuration expressed as a template plus a file of
# values, with a script to render it and a script to detect drift.
#
# The point the capture makes is not the toy config. It is that the network's
# state has one written source, that changes to it are commits with an author and
# a reason, and that a machine can tell you when a device has stopped matching the
# source. Nothing here needs privilege, because rendering a configuration and
# diffing it against what is deployed is exactly the part of IaC that is just files.
apt-get -qq update >/dev/null 2>&1
DEBIAN_FRONTEND=noninteractive apt-get -qq install -y --no-install-recommends git gettext-base >/dev/null 2>&1

git config --global user.name  "Dana Okafor"
git config --global user.email "dana@example.net"
git config --global init.defaultBranch main
git config --global advice.detachedHead false

mkdir -p /srv/net-iac
cd /srv/net-iac
git init -q

# The values. One file, one line per setting, the thing a change request edits.
# The first version has no guest VLAN; a later commit adds it.
cat > vars.env <<'ENV'
SITE=hq
USERS_VID=10
VOICE_VID=20
MGMT_VID=99
UPLINK=ge-0/0/48
ENV

# The template. Vendor-neutral on purpose: the shape is what matters, not one
# switch's syntax. Every value that varies between sites is a placeholder.
cat > switch.tmpl <<'TMPL'
# Managed by net-iac. Changes made on the device will be reverted.
hostname ${SITE}-access-01
vlan ${USERS_VID} name users
vlan ${VOICE_VID} name voice
vlan ${MGMT_VID} name mgmt
interface ${UPLINK}
  description uplink-to-core
  switchport mode trunk
  switchport trunk allowed vlan ${USERS_VID},${VOICE_VID},${MGMT_VID}
TMPL

# Render the template into a deployed configuration. Idempotent: the same source
# produces the same file every time, which is what lets drift mean something.
cat > render.sh <<'REN'
#!/bin/sh
set -e
cd "$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
set -a; . ./vars.env; set +a
mkdir -p running
envsubst < switch.tmpl > running/switch.cfg
echo "rendered running/switch.cfg from source at commit $(git rev-parse --short HEAD)"
REN
chmod +x render.sh

# Compare what is deployed against what the source says should be deployed.
cat > drift.sh <<'DRI'
#!/bin/sh
cd "$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
set -a; . ./vars.env; set +a
envsubst < switch.tmpl > /tmp/intended.cfg
if diff -u running/switch.cfg /tmp/intended.cfg > /tmp/drift.diff 2>&1; then
  echo "no drift: the deployed configuration matches source"
else
  echo "DRIFT: the deployed configuration does not match source"
  sed -n '1,40p' /tmp/drift.diff
  exit 1
fi
DRI
chmod +x drift.sh

# The deployed config is an artifact, not the source, so git tracks intent only.
echo "running/" > .gitignore

# Two commits, so the history is a small story rather than one lump: the network
# existed, then somebody added a guest VLAN through the source and said why.
git add vars.env switch.tmpl render.sh drift.sh .gitignore
GIT_AUTHOR_DATE="2026-07-02T09:14:00" GIT_COMMITTER_DATE="2026-07-02T09:14:00" \
  git commit -q -m "Access switch config as code: hq VLANs and uplink trunk"

# The guest VLAN, added the way every change is: to the source, with a reason.
sed -i '/^MGMT_VID=/i GUEST_VID=40' vars.env
sed -i 's/^vlan ${MGMT_VID} name mgmt/vlan ${GUEST_VID} name guest\nvlan ${MGMT_VID} name mgmt/' switch.tmpl
sed -i 's/allowed vlan ${USERS_VID},${VOICE_VID},${MGMT_VID}/allowed vlan ${USERS_VID},${VOICE_VID},${GUEST_VID},${MGMT_VID}/' switch.tmpl
GIT_AUTHOR_DATE="2026-07-29T15:40:00" GIT_COMMITTER_DATE="2026-07-29T15:40:00" \
  git commit -q -am "Add guest VLAN 40 to the access trunk for the lobby rollout"

# Deploy once, so there is a running configuration to drift from.
./render.sh >/dev/null
cd /srv/net-iac
