#!/usr/bin/env bash
#
# Capture real Windows or macOS output for the network-plus notes.
#
#   ./hostcap.sh windows host-identifiers
#   ./hostcap.sh macos host-identifiers
#
# Triggers the capture-hosts workflow on a GitHub Actions runner, waits for it,
# downloads the transcript, and prints a block ready to paste into a topic.
#
# WHY THIS EXISTS
#
# The exam names ipconfig, ifconfig, arp, netstat, nslookup and tracert, and the
# track's comparison tables answer the same question on more than one platform.
# The namespace tooling produces Linux and nothing else.
#
# WHY NOT JUST RUN IT ON THIS MAC
#
# Because the output would be published. A capture from a personal machine puts
# its hostname, private addresses, DNS servers, wifi network and MAC addresses on
# a public website, and the alternative is editing the transcript by hand, which
# breaks the one rule this toolchain exists to enforce. A disposable runner has
# nothing on it belonging to anybody, and its image version is published, so the
# transcript is pinned as well as safe.
#
# WHAT IT CANNOT DO
#
# One machine per platform, with no second host and no control over its own
# topology. It captures what a host says about itself. Anything needing two
# machines, a switch, or a chosen address plan stays on netlab.sh.
#
# Transcripts from a runner are not byte-reproducible the way the namespace ones
# are: hostname, addresses and MAC differ per run. Do not build a teaching point
# on a value that varies.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKFLOW=capture-hosts.yml

die() { printf 'hostcap: %s\n' "$1" >&2; exit 1; }

command -v gh >/dev/null || die "gh not found. brew install gh"

platform="${1:-}"
steps="${2:-}"
[[ -n $platform && -n $steps ]] || die "usage: hostcap.sh <windows|macos> <script-name>"
[[ $platform == windows || $platform == macos ]] || die "platform must be windows or macos"

ext=ps1
[[ $platform == macos ]] && ext=sh
script="$here/$platform/$steps.$ext"
[[ -f $script ]] || die "no capture script at scripts/$platform/$steps.$ext"

branch="$(git -C "$here" rev-parse --abbrev-ref HEAD)"

# The runner checks out the pushed ref, so an uncommitted edit would silently
# capture the previous version of the commands. Say so rather than producing a
# transcript of something other than what is on disk.
if ! git -C "$here" diff --quiet -- "$platform/$steps.$ext" 2>/dev/null; then
  die "scripts/$platform/$steps.$ext has uncommitted changes. The runner checks out the pushed version, so commit and push first."
fi

printf 'hostcap: dispatching %s/%s on %s\n' "$platform" "$steps" "$branch" >&2
gh workflow run "$WORKFLOW" --ref "$branch" -f "platform=$platform" -f "steps=$steps" >/dev/null 2>&1 ||
  die "dispatch failed. workflow_dispatch only works once the workflow is on the default branch; until then push a change under scripts/$platform/ to trigger it."

printf 'hostcap: waiting for the run to appear\n' >&2
run=""
for _ in $(seq 1 30); do
  run="$(gh run list --workflow "$WORKFLOW" --branch "$branch" --limit 1 --json databaseId --jq '.[0].databaseId' 2>/dev/null || true)"
  [[ -n $run && $run != "null" ]] && break
  sleep 4
done
[[ -n $run && $run != "null" ]] || die "no workflow run appeared. Check: gh run list --workflow $WORKFLOW"

printf 'hostcap: watching run %s\n' "$run" >&2
gh run watch "$run" --exit-status --interval 10 >/dev/null 2>&1 ||
  die "the capture run failed. gh run view $run --log-failed"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
gh run download "$run" --name "capture-$platform-$steps" --dir "$tmp" >/dev/null 2>&1 ||
  gh run download "$run" --name "capture-$platform" --dir "$tmp" >/dev/null 2>&1 ||
  die "could not download the transcript from run $run"

[[ -f "$tmp/$steps.md" ]] || die "the run produced no transcript for '$steps'"
cat "$tmp/$steps.md"
[[ -f "$tmp/PROVENANCE.txt" ]] && printf '\n# provenance: %s\n' "$(cat "$tmp/PROVENANCE.txt")" >&2
