#!/usr/bin/env bash
# Deploy dotfiles by symlink into their live config locations. Idempotent; re-run any time.
# Shared, platform-neutral configs are linked here; everything platform-specific lives under
# platforms/<platform>/ and is only applied by that platform's install.sh.
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$repo/lib/platform.sh"
source "$repo/lib/link.sh"

platform="$(detect_platform)"
if [[ -z $platform ]]; then
  echo "Unrecognized platform: no Omarchy install and no /etc/dgx-release." >&2
  exit 1
fi
echo "Detected platform: $platform"

mkdir -p "$HOME/.config"/{kitty,mise} "$HOME/.local/bin" "$HOME/.local/state/dotfiles" "$HOME/Pictures" "$HOME/.claude"

link_dir "$repo/nvim" "$HOME/.config/nvim"

ln -sf "$repo/config/starship.toml" "$HOME/.config/starship.toml"
ln -sf "$repo/config/kitty/kitty.conf" "$HOME/.config/kitty/kitty.conf"
ln -sf "$repo/config/mise/config.toml" "$HOME/.config/mise/config.toml"
ln -sf "$repo/config/claude/settings.json" "$HOME/.claude/settings.json"

ln -sf "$repo/gitconfig" "$HOME/.gitconfig"
ln -sf "$repo/bashrc.local" "$HOME/.bashrc.local"
grep -qF '.bashrc.local' "$HOME/.bashrc" 2>/dev/null ||
  printf '\n[ -f ~/.bashrc.local ] && source ~/.bashrc.local\n' >>"$HOME/.bashrc"

link_dir "$repo/wallpapers" "$HOME/Pictures/wallpapers"

echo "Shared dotfiles deployed."
echo

"$repo/platforms/$platform/install.sh"
