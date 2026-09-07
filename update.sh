#!/usr/bin/env bash
# Update flake inputs, rebuild the system, and commit the new lock file.
#
# Usage:
#   ./update.sh              # update all inputs
#   ./update.sh claude-code  # update only the given input(s)
set -euo pipefail

cd "$(dirname "$(readlink -f "$0")")"

HOST="${HOST_OVERRIDE:-$(hostname)}"

if [[ -n "$(git status --porcelain --untracked-files=no)" ]]; then
  echo "error: uncommitted changes in $(pwd); commit or stash them first." >&2
  exit 1
fi

echo "==> Updating inputs: ${*:-all}"
nix flake update "$@"

if git diff --quiet flake.lock; then
  echo "==> flake.lock unchanged, nothing to do."
  exit 0
fi

echo "==> Rebuilding $HOST"
sudo nixos-rebuild switch --flake ".#$HOST"

echo "==> Committing flake.lock"
git add flake.lock
git commit -m "Update flake inputs: ${*:-all}"

echo "==> Done. Roll back with: git revert HEAD && sudo nixos-rebuild switch --flake .#$HOST"
