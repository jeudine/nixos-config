#!/usr/bin/env bash
# Set up a machine from this repo: check prerequisites, rebuild the system,
# then create the symlinks that point from the filesystem back into the repo.
# Safe to re-run: links that are already correct are left alone.
#
# Usage:
#   ./install.sh               # rebuild and link
#   ./install.sh --no-rebuild  # only (re)create the symlinks
set -euo pipefail

cd "$(dirname "$(readlink -f "$0")")"
REPO="$(pwd)"

HOST="${HOST_OVERRIDE:-$(hostname)}"
NFS_CLIENTS="$HOME/nixos-private/nfs-clients.nix"

# Symlinks to create, as "link:target" with the target relative to the repo.
LINKS=(
  "/workspace/CLAUDE.md:workspace/CLAUDE.md"
)

REBUILD=1
case "${1:-}" in
  "") ;;
  --no-rebuild) REBUILD=0 ;;
  *) echo "usage: $0 [--no-rebuild]" >&2; exit 2 ;;
esac

die() { echo "error: $*" >&2; exit 1; }

# Point $1 at $2. A file in the way is removed if identical to the target,
# otherwise moved aside.
link() {
  local link="$1" target="$2"
  if [[ -L "$link" && "$(readlink "$link")" == "$target" ]]; then
    echo "    ok       $link"
    return
  fi
  mkdir -p "$(dirname "$link")"
  if [[ -f "$link" && ! -L "$link" ]] && cmp -s "$link" "$target"; then
    rm "$link"
  elif [[ -e "$link" || -L "$link" ]]; then
    local backup="$link.bak.$(date +%Y%m%d%H%M%S)"
    mv "$link" "$backup"
    echo "    moved    $link -> $backup"
  fi
  ln -s "$target" "$link"
  echo "    linked   $link -> $target"
}

if (( REBUILD )); then
  echo "==> Checking prerequisites for $HOST"

  # The config reads this file, and evaluation fails without it.
  if [[ ! -f "$NFS_CLIENTS" ]]; then
    mkdir -p "$(dirname "$NFS_CLIENTS")"
    cp nfs-clients.example.nix "$NFS_CLIENTS"
    chmod 600 "$NFS_CLIENTS"
    die "created $NFS_CLIENTS from the example; fill in the real clients and re-run."
  fi

  # /data and /workspace are mounted without nofail, so switching to a config
  # whose filesystem does not exist would drop the next boot into emergency mode.
  [[ -e /dev/disk/by-label/tank ]] \
    || die "no btrfs filesystem labelled 'tank'; create it first (README, 'Storage (btrfs)')."

  grep -q "nixosConfigurations.$HOST " flake.nix \
    || die "flake.nix has no nixosConfigurations.$HOST; set HOST_OVERRIDE or add the host."

  # A fresh install does not have flakes enabled yet; the config turns them on.
  echo "==> Rebuilding $HOST"
  sudo env NIX_CONFIG="experimental-features = nix-command flakes" \
    nixos-rebuild switch --flake ".#$HOST" --impure
fi

echo "==> Linking"
for entry in "${LINKS[@]}"; do
  link "${entry%%:*}" "$REPO/${entry#*:}"
done

echo "==> Done."
