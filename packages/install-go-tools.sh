#!/usr/bin/env bash
# Install the go install targets in packages/go-tools.txt with mise's go. Run
# `mise install` first so go is actually on PATH.
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

while read -r target; do
  [[ -z $target || $target == \#* ]] && continue
  go install "$target"
done <"$repo/packages/go-tools.txt"

echo "Go tool install complete."
