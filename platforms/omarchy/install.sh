#!/usr/bin/env bash
# Omarchy-only configs. Run by the top-level install.sh after the shared links; idempotent.
set -euo pipefail

platform_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo="$(cd "$platform_dir/../.." && pwd)"
source "$repo/lib/platform.sh"
source "$repo/lib/link.sh"
require_platform omarchy

config="$platform_dir/config"

mkdir -p "$HOME/.config"/{hypr,kitty,alacritty,ghostty,foot,omarchy/hooks/post-update.d,omarchy/backgrounds,aether} "$HOME/.local/bin" "$HOME/.local/state/dotfiles"

# The shared nvim and kitty configs load their theme from ~/.local/state/dotfiles/theme; on
# Omarchy that's the live theme, so theme switches and hot-reload keep working.
ln -sfn "$HOME/.local/state/omarchy/current/theme" "$HOME/.local/state/dotfiles/theme"

ln -sf "$config/hypr/bindings.lua" "$HOME/.config/hypr/bindings.lua"
ln -sf "$config/hypr/hyprland.lua" "$HOME/.config/hypr/hyprland.lua"
ln -sf "$config/hypr/looknfeel.lua" "$HOME/.config/hypr/looknfeel.lua"

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

ln -sf "$config/spotify-flags.conf" "$HOME/.config/spotify-flags.conf"

ln -sf "$config/kitty/platform.conf" "$HOME/.config/kitty/platform.conf"
ln -sf "$config/alacritty/alacritty.toml" "$HOME/.config/alacritty/alacritty.toml"
ln -sf "$config/ghostty/config" "$HOME/.config/ghostty/config"
ln -sf "$config/foot/foot.ini" "$HOME/.config/foot/foot.ini"

ln -sf "$config/omarchy/shell.json" "$HOME/.config/omarchy/shell.json"
ln -sf "$config/omarchy/hooks/post-update.d/keep-agents-native.hook" \
  "$HOME/.config/omarchy/hooks/post-update.d/keep-agents-native.hook"
link_dir "$config/omarchy/backgrounds/catppuccin" "$HOME/.config/omarchy/backgrounds/catppuccin"

ln -sf "$config/aether/settings.json" "$HOME/.config/aether/settings.json"
ln -sf "$config/aether/favorites.json" "$HOME/.config/aether/favorites.json"
ln -sf "$config/aether/wallhaven.json" "$HOME/.config/aether/wallhaven.json"
link_dir "$config/aether/blueprints" "$HOME/.config/aether/blueprints"

ln -sf "$platform_dir/bin/omarchy-font-size-set" "$HOME/.local/bin/omarchy-font-size-set"

echo "Omarchy dotfiles deployed."
echo
echo "Not automated by this script:"
echo "  - hypr/monitors.lua: set up per-machine, hardware differs"
echo "  - hypr/envs.lua: scaffolded empty if missing, fill in this machine's env vars by hand"
echo "  - platforms/omarchy/packages/install-packages.sh: installs the curated pacman/AUR package set"
echo "  - mise install, then packages/install-go-tools.sh: tool versions + go install targets"
