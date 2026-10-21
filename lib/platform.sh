# Platform detection shared by install.sh and the per-platform scripts.

# Prints the platform name matching a directory under platforms/, or nothing if unrecognized.
detect_platform() {
  # Omarchy installs to $OMARCHY_PATH (/usr/share/omarchy since Quattro; ~/.local/share/omarchy before).
  if [[ -d ${OMARCHY_PATH:-/usr/share/omarchy} || -d $HOME/.local/share/omarchy ]]; then
    echo omarchy
  elif [[ -f /etc/dgx-release ]]; then
    echo dgx
  fi
}

# Exit unless running on the given platform, so a platform script can't be applied to the wrong system.
require_platform() {
  local actual
  actual="$(detect_platform)"
  if [[ $actual != "$1" ]]; then
    echo "This script is for the '$1' platform; this system is '${actual:-unrecognized}'." >&2
    exit 1
  fi
}
