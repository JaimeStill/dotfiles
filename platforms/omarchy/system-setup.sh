#!/usr/bin/env bash
# System-level (root) setup for an Omarchy machine. Idempotent; re-run any time.
#
#   sudo platforms/omarchy/system-setup.sh
#
# Installs the udev rules in system/udev/ into /etc/udev/rules.d (copied, not symlinked: udev
# reads them before /home is guaranteed to be available) and reloads udev when any changed.
set -euo pipefail

platform_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo="$(cd "$platform_dir/../.." && pwd)"
source "$repo/lib/platform.sh"
require_platform omarchy

if [[ $EUID -ne 0 ]]; then
  echo "Run with sudo." >&2
  exit 1
fi

changed=0
for rule in "$platform_dir"/system/udev/*.rules; do
  dest="/etc/udev/rules.d/$(basename "$rule")"
  if ! cmp -s "$rule" "$dest"; then
    install -m 0644 "$rule" "$dest"
    echo "Installed $dest"
    changed=1
  fi
done

if ((changed)); then
  udevadm control --reload-rules
  udevadm trigger --subsystem-match=hidraw --subsystem-match=usb
  echo "udev rules reloaded. Replug affected devices if access doesn't change."
else
  echo "udev rules already up to date."
fi
