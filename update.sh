#!/usr/bin/env bash
# Update flake inputs, rebuild the system, and commit the new lock file. Then,
# if / is nearly full, delete old system generations and collect garbage.
#
# Usage:
#   ./update.sh              # update all inputs
#   ./update.sh claude-code  # update only the given input(s)
#
# Environment:
#   HOST_OVERRIDE     flake host attribute (default: hostname)
#   DISK_THRESHOLD    % of / in use at which old generations are deleted (default: 85)
#   KEEP_GENERATIONS  system generations kept when cleaning up (default: 5)
set -euo pipefail

cd "$(dirname "$(readlink -f "$0")")"

HOST="${HOST_OVERRIDE:-$(hostname)}"
DISK_THRESHOLD="${DISK_THRESHOLD:-85}"
# Matches boot.loader.systemd-boot.configurationLimit in configuration.nix, so
# cleaning up never removes a generation the boot menu still offers.
KEEP_GENERATIONS="${KEEP_GENERATIONS:-5}"

SYSTEM_PROFILE=/nix/var/nix/profiles/system

# Percentage of / in use, as a bare number.
root_usage() {
  df --output=pcent / | tail -n 1 | tr -dc '0-9'
}

# Delete all but the newest $KEEP_GENERATIONS system generations and collect
# garbage, but only once / is at least $DISK_THRESHOLD% full.
free_disk_if_full() {
  local used
  used="$(root_usage)"
  if (( used < DISK_THRESHOLD )); then
    echo "==> / is ${used}% full (cleanup at ${DISK_THRESHOLD}%), keeping old generations."
    return
  fi

  echo "==> / is ${used}% full (cleanup at ${DISK_THRESHOLD}%): keeping the last $KEEP_GENERATIONS system generations"
  sudo nix-env --profile "$SYSTEM_PROFILE" --delete-generations "+$KEEP_GENERATIONS"
  # Rewrite the boot entries so none points at a generation that is about to
  # be garbage-collected.
  sudo "$SYSTEM_PROFILE/bin/switch-to-configuration" boot
  echo "==> Collecting garbage"
  sudo nix-store --gc
  echo "==> / is now $(root_usage)% full."
}

if [[ -n "$(git status --porcelain --untracked-files=no)" ]]; then
  echo "error: uncommitted changes in $(pwd); commit or stash them first." >&2
  exit 1
fi

echo "==> Updating inputs: ${*:-all}"
nix flake update "$@"

if git diff --quiet flake.lock; then
  echo "==> flake.lock unchanged, nothing to rebuild."
  free_disk_if_full
  exit 0
fi

echo "==> Rebuilding $HOST"
sudo nixos-rebuild switch --flake ".#$HOST" --impure

echo "==> Committing flake.lock"
git add flake.lock
git commit -m "Update flake inputs: ${*:-all}"

free_disk_if_full

echo "==> Done. Roll back with: git revert HEAD && sudo nixos-rebuild switch --flake .#$HOST --impure"
