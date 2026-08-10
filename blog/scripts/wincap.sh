#!/usr/bin/env bash
#
# Capture real Windows output for the network-plus notes.
#
#   ./wincap.sh host-identifiers
#
# Triggers the capture-windows workflow on a GitHub Actions windows-latest
# runner, waits for it, downloads the transcript, and prints a block ready to
# paste into a topic.
#
# WHY THIS EXISTS
#
# The exam names ipconfig, arp, netstat, nslookup and tracert, and the track's
# comparison tables carry a Windows column. There is no Windows machine in this
# project and none is reachable from an arm64 Mac without a licence question, so
# the alternative was to source the whole Windows column from documentation.
#
# A runner is a real Windows host, it is free on a public repository, and its
# image version is published, so a Windows transcript can be pinned and
# reproduced on the same terms as a Linux one. The commands live in a committed
# script under scripts/windows/ rather than being typed into a workflow, so a
# reader can see exactly what produced the output.
#
# WHAT IT CANNOT DO
#
# One machine, on GitHub's network, with no second host and no control over its
# own topology. It captures what a Windows host says about itself and about the
# internet. Anything needing two machines, a switch, or a chosen address plan
# stays on netlab.sh.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKFLOW=capture-windows.yml

die() { printf 'wincap: %s\n' "$1" >&2; exit 1; }

command -v gh >/dev/null || die "gh not found. brew install gh"

steps="${1:-}"
[[ -n $steps ]] || die "usage: wincap.sh <script-name>   (a file in scripts/windows/, without .ps1)"
[[ -f "$here/windows/$steps.ps1" ]] || die "no capture script at scripts/windows/$steps.ps1"

branch="$(git -C "$here" rev-parse --abbrev-ref HEAD)"

# The workflow reads the script from the checked-out ref, so an uncommitted edit
# to the steps file would silently capture the previous version. Say so rather
# than producing a transcript of the wrong commands.
if ! git -C "$here" diff --quiet -- "windows/$steps.ps1" 2>/dev/null; then
  die "scripts/windows/$steps.ps1 has uncommitted changes. The runner checks out the pushed version, so commit and push first."
fi

printf 'wincap: dispatching %s on %s\n' "$steps" "$branch" >&2
gh workflow run "$WORKFLOW" --ref "$branch" -f "steps=$steps" >/dev/null

# gh gives no run id back from a dispatch, so poll for the newest run of this
# workflow that started after the dispatch.
printf 'wincap: waiting for the run to appear\n' >&2
run=""
for _ in $(seq 1 30); do
  run="$(gh run list --workflow "$WORKFLOW" --branch "$branch" --limit 1 --json databaseId --jq '.[0].databaseId' 2>/dev/null || true)"
  [[ -n $run && $run != "null" ]] && break
  sleep 4
done
[[ -n $run && $run != "null" ]] || die "no workflow run appeared. Check: gh run list --workflow $WORKFLOW"

printf 'wincap: watching run %s\n' "$run" >&2
gh run watch "$run" --exit-status --interval 10 >/dev/null 2>&1 ||
  die "the capture run failed. gh run view $run --log-failed"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
gh run download "$run" --name "windows-capture-$steps" --dir "$tmp" >/dev/null ||
  die "could not download the transcript from run $run"

[[ -f "$tmp/$steps.md" ]] || die "the run produced no transcript for '$steps'"
cat "$tmp/$steps.md"
