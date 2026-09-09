#!/usr/bin/env bash
# Deploy dotfiles by symlink into their live config locations. Idempotent; re-run any time.
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ln -sfn silently drops the symlink *inside* an existing real (non-symlink)
# directory instead of replacing it, so directory targets need the real
# directory removed first.
link_dir() {
  if [[ -d $2 && ! -L $2 ]]; then
    rm -rf "$2"
  fi
  ln -sfn "$1" "$2"
}

mkdir -p "$HOME/.config"/{hypr,alacritty,kitty,ghostty,foot,omarchy/hooks/post-update.d,omarchy/backgrounds,aether,mise} "$HOME/.local/bin" "$HOME/Pictures"

link_dir "$repo/nvim" "$HOME/.config/nvim"

ln -sf "$repo/config/hypr/bindings.lua" "$HOME/.config/hypr/bindings.lua"
ln -sf "$repo/config/hypr/hyprland.lua" "$HOME/.config/hypr/hyprland.lua"

# hyprland.lua requires hypr.envs for per-machine env vars (GPU driver, cursor
# theme, etc.) — not tracked here since it doesn't travel between machines.
# Scaffold an empty one if this machine doesn't have one yet, so the require
# always resolves; never overwrite one that already exists.
if [[ ! -f "$HOME/.config/hypr/envs.lua" ]]; then
  cat >"$HOME/.config/hypr/envs.lua" <<'LUA'
-- Machine-specific Hyprland env vars. Not tracked in dotfiles.
-- hl.env("LIBVA_DRIVER_NAME", "iHD")
LUA
fi

ln -sf "$repo/config/alacritty/alacritty.toml" "$HOME/.config/alacritty/alacritty.toml"
ln -sf "$repo/config/kitty/kitty.conf" "$HOME/.config/kitty/kitty.conf"
ln -sf "$repo/config/ghostty/config" "$HOME/.config/ghostty/config"
ln -sf "$repo/config/foot/foot.ini" "$HOME/.config/foot/foot.ini"

ln -sf "$repo/config/omarchy/shell.json" "$HOME/.config/omarchy/shell.json"
ln -sf "$repo/config/omarchy/hooks/post-update.d/keep-agents-native.hook" \
  "$HOME/.config/omarchy/hooks/post-update.d/keep-agents-native.hook"
link_dir "$repo/config/omarchy/backgrounds/catppuccin" "$HOME/.config/omarchy/backgrounds/catppuccin"

ln -sf "$repo/config/aether/settings.json" "$HOME/.config/aether/settings.json"
ln -sf "$repo/config/aether/favorites.json" "$HOME/.config/aether/favorites.json"
ln -sf "$repo/config/aether/wallhaven.json" "$HOME/.config/aether/wallhaven.json"
link_dir "$repo/config/aether/blueprints" "$HOME/.config/aether/blueprints"

ln -sf "$repo/config/mise/config.toml" "$HOME/.config/mise/config.toml"

ln -sf "$repo/gitconfig" "$HOME/.gitconfig"
ln -sf "$repo/bashrc.local" "$HOME/.bashrc.local"
grep -qF '.bashrc.local' "$HOME/.bashrc" 2>/dev/null || \
  printf '\n[ -f ~/.bashrc.local ] && source ~/.bashrc.local\n' >>"$HOME/.bashrc"

ln -sf "$repo/bin/omarchy-font-size-set" "$HOME/.local/bin/omarchy-font-size-set"

link_dir "$repo/wallpapers" "$HOME/Pictures/wallpapers"

echo "dotfiles deployed."
echo
echo "Not automated by this script:"
echo "  - hypr/monitors.lua: set up per-machine, hardware differs"
echo "  - hypr/envs.lua: scaffolded empty if missing, fill in this machine's env vars by hand"
echo "  - packages/{pacman,aur}.txt: review, then install by hand (see README)"
echo "  - mise install: run it to fetch the tool versions from config/mise/config.toml"
