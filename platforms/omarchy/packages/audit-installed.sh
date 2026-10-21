#!/bin/bash
# Compare this machine's explicitly-installed packages against the curated
# packages/pacman.txt and packages/aur.txt. Prints candidates not yet in the
# curated list; doesn't write anything. pacman's explicit/dependency
# bookkeeping can drift, so treat this as a prompt to review, not a diff to
# blindly fold in.
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
stock="/tmp/omarchy-stock-packages.$$"
trap 'rm -f "$stock"' EXIT

cat /usr/share/omarchy/install/omarchy-base.packages \
    /usr/share/omarchy/install/omarchy-other.packages 2>/dev/null | sort -u >"$stock"

beyond_stock=$(comm -23 <(pacman -Qqe | sort) "$stock" | grep -vE '^omarchy(-keyring|-settings)?$')
curated=$(cat "$repo/packages/pacman.txt" "$repo/packages/aur.txt" | sort -u)

candidates=$(comm -23 <(echo "$beyond_stock" | sort) <(echo "$curated"))

if [[ -z $candidates ]]; then
  echo "Nothing installed beyond stock Omarchy that isn't already in the curated package list."
else
  echo "Installed beyond stock Omarchy but not in packages/pacman.txt or packages/aur.txt:"
  echo "$candidates"
fi
