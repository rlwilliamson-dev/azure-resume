#!/usr/bin/env bash
#
# Capture real command output for the linux-plus notes.
#
# Every terminal block in that track should come from here rather than from
# memory. Running the command is how you find out that `dpkg -S /bin/ls` fails
# on Debian 13 because of usr-merge, which is the kind of thing a study guide
# written from documentation gets wrong.
#
#   ./capture.sh alma -- ls -ld /srv
#   ./capture.sh debian --arch amd64 -- dpkg --print-architecture
#   ./capture.sh ubuntu --script setup.sh -- id www-data
#   ./capture.sh alma --block 2 -- 'pvcreate $DEV0 $DEV1; pvs'
#   ./capture.sh vm -- 'lsmod | head'
#
# Prints a fenced block ready to paste into a topic, prefixed with the distro
# and architecture the output actually came from. Images are pinned by digest
# in distros.json.
#
# Architecture: defaults to amd64, because x86_64 is the context the exam
# assumes and because architecture leaks into output (uname -m, dpkg
# --print-architecture, lscpu). Pass --arch arm64 when you specifically want
# the aarch64 result.
#
# --block N: run privileged against N real loop devices, so LVM, mdadm, mkfs,
# fsck, and mount produce genuine output. This routes through the podman machine
# VM as root, because device-mapper is not reachable from a rootless container.
# Loop devices appear as /dev/loop0 upward and are torn down afterwards.
#
# --block forces the VM's architecture (aarch64 on Apple Silicon), because the
# devices belong to the VM's kernel. Block-layer output does not vary by
# architecture, but the label will say aarch64 and that is the honest answer.
#
# The `vm` target runs on the podman machine itself rather than in a container,
# which is the only way to capture anything about booting, kernel modules,
# firmware, or hardware: a container borrows the host's kernel and has none of
# its own. The label says "on a virtual machine" because that is what it is, and
# a topic using this output has to be straight about the consequences, notably
# that lspci reports virtio devices rather than real ones.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
manifest="$here/distros.json"

die() { printf 'capture: %s\n' "$1" >&2; exit 1; }

command -v podman >/dev/null || die "podman not found. brew install podman && podman machine start"
[[ -f $manifest ]] || die "missing $manifest"

arch=amd64
setup=""
blocks=0
blockSize=512M
archSet=0
key="${1:-}"
[[ -n $key ]] || die "usage: capture.sh <distro> [--arch amd64|arm64] [--script FILE] [--block N] -- <command...>"
shift

while [[ $# -gt 0 ]]; do
  case "$1" in
    --arch) arch="${2:-}"; archSet=1; shift 2 ;;
    --script) setup="${2:-}"; shift 2 ;;
    --block) blocks="${2:-}"; shift 2 ;;
    --block-size) blockSize="${2:-}"; shift 2 ;;
    --) shift; break ;;
    *) die "unexpected argument '$1' before --" ;;
  esac
done

[[ $# -gt 0 ]] || die "no command given after --"
[[ $arch == amd64 || $arch == arm64 ]] || die "--arch must be amd64 or arm64"
[[ $blocks =~ ^[0-9]+$ ]] || die "--block must be a count"

# --- loop devices -----------------------------------------------------------
#
# Loop devices have to be created by the VM's kernel; a container cannot make
# its own. The VM already uses low-numbered loop devices for podman storage, so
# never assume /dev/loop0: provision, then hand the real paths to the command as
# $DEV0, $DEV1, ... and $DEVS.
#
# Device-mapper state lives in the VM's kernel rather than in the container, so
# a volume group left behind stays visible to the next run through
# /dev/mapper/control. Reset first, using the backing-file name to find our own
# devices and nothing else. Removing a loop device does not remove the
# device-mapper node built on top of it, and an orphaned node is what makes a
# second capture report "volume group already exists" against devices that were
# just wiped.
#
# dmsetup remove_all is safe here specifically because this VM is disposable and
# uses plain partitions for its own root; the only device-mapper nodes on it are
# the ones these captures create.
reset_devices='
  mdadm --stop --scan >/dev/null 2>&1
  dmsetup remove_all >/dev/null 2>&1
  losetup -a 2>/dev/null | grep "/var/tmp/capture-" | cut -d: -f1 | while read -r d; do
    wipefs -a "$d" >/dev/null 2>&1
    losetup -d "$d" >/dev/null 2>&1
  done
  rm -f /var/tmp/capture-*.img'

devs=""
prelude=""

provision_loops() {
  cleanup() { podman machine ssh "sudo sh -c '$reset_devices'" >/dev/null 2>&1 || true; }
  cleanup
  trap cleanup EXIT

  # -P so the kernel scans the partition table and creates /dev/loopNpM. Those
  # nodes only reach a container if they existed when it started, which is why
  # the disk-to-partition-to-filesystem sequence is captured on the vm target.
  devs="$(
    podman machine ssh "sudo sh -c '
      for i in \$(seq 0 $((blocks - 1))); do
        truncate -s ${blockSize} /var/tmp/capture-\$i.img
        losetup -P -f --show /var/tmp/capture-\$i.img
      done'" 2>/dev/null | tr -d '\r' | tr '\n' ' '
  )"
  devs="${devs% }"
  [[ -n $devs ]] || die "loop device provisioning returned nothing"

  prelude="DEVS=\"$devs\""$'\n'
  local i=0
  for d in $devs; do
    prelude+="DEV$i=$d"$'\n'
    i=$((i + 1))
  done
}

# --- the vm target ----------------------------------------------------------
#
# The `vm` pseudo-distro runs straight on the podman machine rather than in a
# container, because a container has no kernel of its own. Anything about
# booting, kernel modules, firmware, or hardware has to come from here, as does
# anything needing partition device nodes to appear as they are created.
#
# The trade is honesty about what this machine is: a virtual one, on whatever
# architecture the host runs, on Fedora CoreOS. Topics using this output have to
# say so, because `lspci` reports virtio devices and `lscpu` reports the host
# CPU. That is a fair picture of a cloud instance and a poor picture of a server
# in a rack, and the prose has to be the one to say which.
#
# Root: write `sudo` into the command yourself. The transcript then shows what a
# reader would actually type, which is the point of capturing at all.
if [[ $key == vm ]]; then
  [[ $archSet -eq 0 ]] || die "--arch cannot be chosen for the vm target; it is the machine's own"
  # --script is only allowed alongside --block, where setup has disposable loop
  # devices to work on. Without them there is nothing to set up that would not
  # be a lasting change to a machine this script does not own.
  if [[ -n $setup && $blocks -eq 0 ]]; then
    die "--script needs --block on the vm target; the machine itself is not disposable"
  fi
  if [[ -n $setup ]]; then
    [[ -f $setup ]] || die "setup script '$setup' not found"
  fi

  vmInfo="$(
    podman machine ssh '. /etc/os-release; printf "%s\t%s\n" "$PRETTY_NAME" "$(uname -m)"' 2>/dev/null | tr -d '\r'
  )"
  [[ -n $vmInfo ]] || die "podman machine is not running. podman machine start"
  label="${vmInfo%%$'\t'*}"
  vmUname="${vmInfo##*$'\t'}"

  cmd="$*"
  [[ $blocks -gt 0 ]] && provision_loops

  vmPayload="$cmd"
  [[ -n $setup ]] && vmPayload="$(cat "$setup")"$'\n'"$cmd"

  encoded="$(printf '%s\n%s\n' "$prelude" "$vmPayload" | base64 | tr -d '\n')"
  out="$(podman machine ssh "echo $encoded | base64 -d | /bin/sh -s" 2>&1 | tr -d '\r')" || true

  printf '```bash\n'
  printf '# %s on a virtual machine, %s\n' "$label" "$vmUname"
  printf '$ %s\n' "$cmd"
  printf '%s\n' "$out"
  printf '```\n'
  exit 0
fi

if [[ $blocks -gt 0 ]]; then
  vmArch="$(podman machine ssh 'uname -m' 2>/dev/null | tr -d '\r')" ||
    die "podman machine is not running. podman machine start"
  case "$vmArch" in
    aarch64) vmArch=arm64 ;;
    x86_64) vmArch=amd64 ;;
    *) die "unexpected podman machine architecture '$vmArch'" ;;
  esac
  if [[ $archSet -eq 1 && $arch != "$vmArch" ]]; then
    die "--block runs on the podman machine kernel ($vmArch); --arch $arch cannot be honoured"
  fi
  arch="$vmArch"
fi

read -r image digest label < <(
  node -e '
    const m = require(process.argv[1]).distros;
    const d = m[process.argv[2]];
    if (!d) {
      console.error("unknown distro. known: " + Object.keys(m).join(", "));
      process.exit(1);
    }
    const digest = d.digest[process.argv[3]];
    if (!digest) {
      console.error(`no ${process.argv[3]} digest pinned for ${process.argv[2]}`);
      process.exit(1);
    }
    console.log([d.image, digest, d.label].join(" "));
  ' "$manifest" "$key" "$arch"
) || die "could not resolve distro '$key' for $arch"

ref="${image%:*}@${digest}"
cmd="$*"

# Pull ahead of the run so registry progress never lands in a transcript.
podman pull -q --platform "linux/$arch" "$ref" >/dev/null 2>&1 ||
  die "could not pull $ref for linux/$arch"

# Run setup separately from the captured command so setup noise stays out of
# the transcript. Both run in one container so state carries over.
if [[ -n $setup ]]; then
  [[ -f $setup ]] || die "setup script '$setup' not found"
  payload="$(cat "$setup")"$'\n'"$cmd"
else
  payload="$cmd"
fi

if [[ $blocks -gt 0 ]]; then
  provision_loops

  # Pass only the devices this capture needs, plus device-mapper's control node.
  # Sharing the whole /dev instead lets the container create /dev/<vg> entries
  # in the VM that outlive it and poison the next run.
  deviceArgs="--device /dev/mapper/control"
  for d in $devs; do deviceArgs+=" --device $d"; done

  encoded="$(printf '%s\n%s\n' "$prelude" "$payload" | base64 | tr -d '\n')"
  out="$(
    podman machine ssh "sudo podman run --rm --privileged $deviceArgs '$ref' \
      /bin/sh -c 'echo $encoded | base64 -d | /bin/sh -s' 2>&1"
  )" || true
  # Strip registry chatter from the first pull inside the VM.
  out="$(printf '%s\n' "$out" | sed -E '/^(Trying to pull|Getting image source|Copying |Writing manifest)/d')"
else
  out="$(
    printf '%s\n' "$payload" | podman run --rm -i --platform "linux/$arch" "$ref" \
      /bin/sh -s 2>&1
  )" || true
fi

uname_m=$([[ $arch == amd64 ]] && echo x86_64 || echo aarch64)

printf '```bash\n'
printf '# %s, %s\n' "$label" "$uname_m"
printf '$ %s\n' "$cmd"
printf '%s\n' "$out"
printf '```\n'
