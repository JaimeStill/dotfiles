#!/bin/bash
# Regenerate packages/pacman.txt and packages/aur.txt from the live system.
# These are reference manifests for manual review, not an installer — pacman's
# explicit/dependency bookkeeping can drift, so read the output before ever
# installing from it.
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
stock="/tmp/omarchy-stock-packages.$$"
trap 'rm -f "$stock"' EXIT

cat /usr/share/omarchy/install/omarchy-base.packages \
    /usr/share/omarchy/install/omarchy-other.packages 2>/dev/null | sort -u >"$stock"

comm -23 <(pacman -Qqe | sort) "$stock" | grep -vE '^omarchy(-keyring|-settings)?$' \
  >"$repo/packages/pacman.txt"

pacman -Qqem | sort >"$repo/packages/aur.txt"

echo "Wrote $(wc -l <"$repo/packages/pacman.txt") pacman packages and $(wc -l <"$repo/packages/aur.txt") AUR packages."
echo "Review both files by hand before installing anything from them."
