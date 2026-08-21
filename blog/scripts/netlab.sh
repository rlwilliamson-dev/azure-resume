#!/usr/bin/env bash
#
# Capture real network output for the network-plus notes.
#
# Sibling of capture.sh rather than a mode inside it, because the mental model
# is different. capture.sh runs a command on one machine. netlab.sh builds a
# network out of Linux network namespaces and runs a command on one node of it.
#
#   ./netlab.sh --topo topologies/two-hosts.sh --node h1 -- ping -c 3 10.0.0.2
#   ./netlab.sh --topo topologies/one-router.sh --node h1 -- traceroute -n 10.0.2.2
#   ./netlab.sh --topo topologies/stp-triangle.sh --node s3 -- bridge -d link show
#
# Prints a fenced block ready to paste into a topic, headed with the image, the
# kernel, and the topology it came from.
#
# WHY NAMESPACES
#
# A namespace is a host. A veth pair is the cable between two of them. A Linux
# bridge is a switch, and it is a real one: it learns MAC addresses, it filters
# VLANs, and it runs spanning tree. So the switching and routing behaviour the
# exam tests is reproducible in software, on a laptop, for free. What is not
# reproducible is anything physical, and topics covering those say so instead of
# dressing up a hand-written block as a transcript.
#
# WHY ROOTFUL
#
# Rootless privileged fails at `ip netns exec` with rc=255. The kernel says why
# on every attempt: "mount of /sys failed: Operation not permitted". Creating a
# network namespace needs real CAP_SYS_ADMIN in the initial user namespace, and
# a rootless container does not have it whatever --privileged suggests.
#
# So this routes through the podman machine's rootful connection, which already
# exists alongside the rootless one. Two roads not taken, both of which look
# like they would work:
#
#   podman machine ssh sudo podman run ...   puts every captured command through
#                                            another layer of shell quoting, and
#                                            a topic full of nested escaping is
#                                            a topic nobody can re-run.
#   podman machine set --rootful             flips the default connection, which
#                                            hides the linux-plus capture images
#                                            behind separate root storage.
#
# THE KERNEL IS THE THING BEING CAPTURED
#
# The container image supplies iproute2 and friends; the behaviour comes from
# the podman machine's kernel. So the provenance header names the kernel
# version, because pinning the image by digest does not pin that.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONNECTION=podman-machine-default-root

die() { printf 'netlab: %s\n' "$1" >&2; exit 1; }

command -v podman >/dev/null || die "podman not found. brew install podman && podman machine start"

topo=""
node=""
label=""
noCache=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --topo) topo="${2:-}"; shift 2 ;;
    --node) node="${2:-}"; shift 2 ;;
    --label) label="${2:-}"; shift 2 ;;
    --no-cache) noCache=1; shift ;;
    --) shift; break ;;
    *) die "unexpected argument '$1' before --" ;;
  esac
done

[[ -n $topo ]] || die "usage: netlab.sh --topo FILE [--node NAME] [--label TEXT] [--no-cache] -- <command...>"
[[ $# -gt 0 ]] || die "no command given after --"

# Topology paths are resolved relative to the script, so a topic can cite
# "topologies/one-router.sh" and mean one thing from anywhere.
[[ -f $topo ]] || topo="$here/$topo"
[[ -f $topo ]] || die "topology '$topo' not found"

topoName="$(basename "$topo" .sh)"
cmd="$*"

# --- what the topology declares ------------------------------------------
#
# A topology file is a shell script that creates namespaces, links, addresses
# and routes. It may also set two variables, read here before it runs:
#
#   NETLAB_PACKAGES   apt packages the topology needs. Part of the image cache
#                     key, so changing them rebuilds and nothing goes stale.
#   NETLAB_SETTLE     seconds to wait after the topology is built, before the
#                     captured command runs. Spanning tree takes about 30 to
#                     converge and OSPF about 40, so this is a per-topology
#                     declaration rather than one constant that is wrong twice.
packages="$(sed -n 's/^NETLAB_PACKAGES=["'"'"']\{0,1\}\([^"'"'"']*\).*/\1/p' "$topo" | head -1)"
settle="$(sed -n 's/^NETLAB_SETTLE=["'"'"']\{0,1\}\([0-9]*\).*/\1/p' "$topo" | head -1)"
packages="${packages:-iproute2 iputils-ping}"
settle="${settle:-0}"

base="docker.io/library/debian:13"

machine="$(
  podman machine ssh '. /etc/os-release; printf "%s\t%s\n" "$PRETTY_NAME" "$(uname -r)"' 2>/dev/null | tr -d '\r'
)"
[[ -n $machine ]] || die "podman machine is not running. podman machine start"
machineName="${machine%%$'\t'*}"
kernel="${machine##*$'\t'}"

# --- the image cache -----------------------------------------------------
#
# Same reasoning as capture.sh --script. Installing frr and bind9 takes tens of
# seconds, a topic needs a dozen captures, and running several at once thrashes
# the machine. Commit the installed packages to a local image keyed on the base
# image and the package list. Any edit to the list changes the key and rebuilds.
image="$base"
if [[ $noCache -eq 0 ]]; then
  key="$(printf '%s\n%s\n' "$base" "$packages" | shasum -a 256 | cut -c1-16)"
  image="localhost/netlab:$key"
  if ! podman --connection "$CONNECTION" image exists "$image" 2>/dev/null; then
    build="netlab-build-$key"
    podman --connection "$CONNECTION" rm -f "$build" >/dev/null 2>&1 || true
    podman --connection "$CONNECTION" run --name "$build" --privileged "$base" /bin/sh -c "
      apt-get -qq update >/dev/null 2>&1
      DEBIAN_FRONTEND=noninteractive apt-get -qq install -y --no-install-recommends $packages >/dev/null 2>&1
    " >/dev/null 2>&1 || true
    podman --connection "$CONNECTION" commit -q "$build" "$image" >/dev/null 2>&1 ||
      die "could not build the netlab image for packages: $packages"
    podman --connection "$CONNECTION" rm -f "$build" >/dev/null 2>&1 || true
  fi
fi

# --- the runner ----------------------------------------------------------
#
# `ip netns exec` already unshares the mount namespace and remounts /sys for the
# target namespace. What it does not do is give each node its own /run, so two
# daemons in two namespaces collide on one control socket. lldpd is the case
# that surfaces it. Per-node bind mounts fix it and cost nothing.
runner=$(cat <<'RUNNER'
set -e

# Per-node /run, so daemons in different namespaces do not share sockets.
netlab_node_run() {
  mkdir -p "/run/netlab/$1"
  mount --bind "/run/netlab/$1" /run 2>/dev/null || true
}

# Run a command inside a node, with that node's own /run.
nsx() {
  local n="$1"; shift
  ip netns exec "$n" unshare --mount sh -c "
    mkdir -p /run/netlab/$n
    mount --bind /run/netlab/$n /run 2>/dev/null || true
    $*
  "
}
RUNNER
)

# --- one command, or a session ------------------------------------------
#
# A capture that needs six commands used to be written as one line with
# semicolons between them, which is what capture.sh does. On a topic page that
# renders as a single command wrapping over four lines, and a reader cannot see
# where one command ends and the next begins, let alone which output belongs to
# which.
#
# So a command containing newlines is treated as a session: each line is echoed
# with its own prompt and then run, and its output appears directly underneath.
# That is what a terminal actually looks like. Blank lines are kept for spacing
# and lines starting with # are passed through as comments, which lets a capture
# carry its own narration.
multiline=0
[[ $cmd == *$'\n'* ]] && multiline=1

# The step runner, as a single-quoted bash string so nothing here is expanded
# before it reaches the container. It uses double quotes throughout and no
# single quotes at all, which is what lets it survive being wrapped this way.
# In POSIX sh a dollar followed by a space is literal, so `printf "$ %s\n"`
# prints a shell prompt rather than trying to expand anything.
# The `|| [ -n "$__l" ]` is load-bearing. A steps file whose last line has no
# trailing newline makes `read` return non-zero on that line, and the loop would
# exit having silently dropped the final command of every capture.
#
# `$?` is restored before each step. Without that, a step reading `$?` sees the
# status of the loop own printf rather than of the previous captured command,
# so `ping ...; echo "exit status $?"` reports 0 for a ping that failed. That is
# a transcript that lies, which is the one thing this tooling exists to prevent.
STEP_RUNNER='#!/bin/sh
__rc=0
while IFS= read -r __l || [ -n "$__l" ]; do
  case "$__l" in
    "") printf "\n"; continue ;;
    \#*) printf "%s\n" "$__l"; continue ;;
  esac
  printf "$ %s\n" "$__l"
  (exit $__rc)
  eval "$__l"
  __rc=$?
done < /tmp/netlab-steps'

payload="$(
  printf '%s\n' "$runner"
  cat "$topo"
  [[ ${settle:-0} -gt 0 ]] && printf 'sleep %s\n' "$settle"
  # The topology build runs under `set -e`, because a half-built network
  # produces a transcript that looks real and is not. The captured command must
  # not, because showing a failure is frequently the whole point of the capture:
  # a ping that cannot leave the host, a port that refuses a connection. Under
  # `set -e` the first non-zero exit would silently truncate everything after it.
  printf 'set +e\n'
  if [[ $multiline -eq 1 ]]; then
    # Both blobs go in base64 so neither the steps nor the runner can be
    # mangled by a quote, a backtick, or a dollar sign on their way in.
    printf 'echo %s | base64 -d > /tmp/netlab-steps\n' "$(printf '%s' "$cmd" | base64 | tr -d '\n')"
    printf 'echo %s | base64 -d > /tmp/netlab-run\n' "$(printf '%s' "$STEP_RUNNER" | base64 | tr -d '\n')"
    printf 'chmod +x /tmp/netlab-run\n'
    if [[ -n $node ]]; then
      printf 'ip netns exec %q /tmp/netlab-run\n' "$node"
    else
      printf '/tmp/netlab-run\n'
    fi
  elif [[ -n $node ]]; then
    printf 'ip netns exec %q sh -c %q\n' "$node" "$cmd"
  else
    printf '%s\n' "$cmd"
  fi
)"

encoded="$(printf '%s' "$payload" | base64 | tr -d '\n')"

out="$(
  podman --connection "$CONNECTION" run --rm --privileged "$image" \
    /bin/sh -c "echo $encoded | base64 -d | /bin/sh -s" 2>&1
)" || true

out="$(printf '%s' "$out" | tr -d '\r')"

printf '```bash\n'
if [[ -n $label ]]; then
  printf '# %s\n' "$label"
fi
printf '# %s, kernel %s\n' "$machineName" "$kernel"
printf '# linux network namespaces, topology %s\n' "$topoName"
if [[ -n $node ]]; then
  printf '# commands run on %s\n' "$node"
fi
# In session mode every line prints its own prompt, so printing the command
# here as well would duplicate the whole thing above its own transcript.
if [[ $multiline -eq 0 ]]; then
  printf '$ %s\n' "$cmd"
fi
printf '%s\n' "$out"
printf '```\n'
