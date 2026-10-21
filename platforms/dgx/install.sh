#!/usr/bin/env bash
# DGX OS-only configs and user-level installs (no sudo). Run by the top-level install.sh after
# the shared links; idempotent. Root-level setup is platforms/dgx/system-setup.sh.
set -euo pipefail

platform_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo="$(cd "$platform_dir/../.." && pwd)"
source "$repo/lib/platform.sh"
source "$repo/lib/link.sh"
require_platform dgx

config="$platform_dir/config"

mkdir -p "$HOME/.config"/{kitty,tmux,herdr,fastfetch,mise/conf.d,fontconfig} "$HOME/.local/bin" \
  "$HOME/.local/state/dotfiles" "$HOME/.local/share/applications" "$HOME/.local/share/fonts"

echo "==> Configs"
# DGX OS has no live theme system; a fixed theme (Noctis Obscuro) stands in for
# Omarchy's current theme.
ln -sfn "$platform_dir/theme" "$HOME/.local/state/dotfiles/theme"

ln -sf "$config/kitty/platform.conf" "$HOME/.config/kitty/platform.conf"
ln -sf "$config/tmux/tmux.conf" "$HOME/.config/tmux/tmux.conf"
ln -sf "$config/herdr/config.toml" "$HOME/.config/herdr/config.toml"
ln -sf "$config/fastfetch/config.jsonc" "$HOME/.config/fastfetch/config.jsonc"
ln -sf "$config/mise/dgx.toml" "$HOME/.config/mise/conf.d/dgx.toml"
ln -sf "$config/fontconfig/fonts.conf" "$HOME/.config/fontconfig/fonts.conf"
ln -sf "$platform_dir/bin/drop-caches" "$HOME/.local/bin/drop-caches"
ln -sf "$platform_dir/bin/launch-browser" "$HOME/.local/bin/launch-browser"

# PATH for desktop sessions (~/.profile) and for every bash, including `ssh host cmd`, which
# never gets past Ubuntu's interactive-only guard at the top of ~/.bashrc.
env_line="[ -f ~/dotfiles/platforms/dgx/env.sh ] && . ~/dotfiles/platforms/dgx/env.sh"
grep -qF "$env_line" "$HOME/.profile" 2>/dev/null || printf '\n%s\n' "$env_line" >>"$HOME/.profile"
grep -qF "$env_line" "$HOME/.bashrc" || sed -i "1i $env_line" "$HOME/.bashrc"
grep -qF 'platforms/dgx/bashrc' "$HOME/.bashrc" ||
  printf '\n[ -f ~/dotfiles/platforms/dgx/bashrc ] && source ~/dotfiles/platforms/dgx/bashrc\n' >>"$HOME/.bashrc"
source "$platform_dir/env.sh"

# Byobu stays installed (ubuntu-server depends on it) but out of the app grid.
printf '[Desktop Entry]\nType=Application\nName=Byobu Terminal\nNoDisplay=true\n' \
  >"$HOME/.local/share/applications/byobu.desktop"

echo "==> Apps"
# kitty, per https://sw.kovidgoyal.net/kitty/binary/
if [[ ! -x $HOME/.local/kitty.app/bin/kitty ]]; then
  curl -fsSL https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin launch=n
fi
ln -sf "$HOME/.local/kitty.app/bin/kitty" "$HOME/.local/kitty.app/bin/kitten" "$HOME/.local/bin/"
cp "$HOME/.local/kitty.app/share/applications/kitty.desktop" \
  "$HOME/.local/kitty.app/share/applications/kitty-open.desktop" "$HOME/.local/share/applications/"
sed -i -e "s|Icon=kitty|Icon=$HOME/.local/kitty.app/share/icons/hicolor/256x256/apps/kitty.png|g" \
  -e "s|Exec=kitty|Exec=$HOME/.local/kitty.app/bin/kitty|g" "$HOME/.local/share/applications/kitty"*.desktop
echo 'kitty.desktop' >"$HOME/.config/xdg-terminals.list"

# kitty only points its own local windows at its terminfo (TERMINFO). SSH sessions from a kitty
# elsewhere arrive as TERM=xterm-kitty without it, so programs like clear fail; link it where
# ncurses looks for your user. Root's copy comes from kitty-terminfo (system-setup.sh apt).
mkdir -p "$HOME/.terminfo/x"
ln -sf "$HOME/.local/kitty.app/lib/kitty/terminfo/x/xterm-kitty" "$HOME/.terminfo/x/xterm-kitty"

command -v claude >/dev/null || curl -fsSL https://claude.ai/install.sh | bash
command -v mise >/dev/null || curl -fsSL https://mise.run | sh
command -v herdr >/dev/null || curl -fsSL https://herdr.dev/install.sh | sh

echo "==> mise tools"
mise install || echo "Some mise tools failed to install; see above, then re-run: mise install"

# Claude Code's session restore inside herdr. herdr owns both the hook script and its entry in
# the shared Claude settings, and rewrites them on updates, so neither is edited by hand.
if [[ ! -f $HOME/.claude/hooks/herdr-agent-state.sh ]]; then
  herdr integration install claude || echo "herdr's Claude integration failed; re-run: herdr integration install claude"
fi

echo "==> Font: CaskaydiaMono Nerd Font"
font_dir="$HOME/.local/share/fonts/CaskaydiaMono"
if [[ ! -d $font_dir ]]; then
  tmp="$(mktemp -d)"
  curl -fsSL -o "$tmp/font.tar.xz" https://github.com/ryanoasis/nerd-fonts/releases/latest/download/CascadiaMono.tar.xz
  mkdir -p "$font_dir"
  tar -xJf "$tmp/font.tar.xz" -C "$font_dir" --wildcards '*.ttf'
  rm -rf "$tmp"
  fc-cache -f "$font_dir"
fi

echo "==> GNOME"
if [[ -n ${DBUS_SESSION_BUS_ADDRESS:-} ]] || [[ -S /run/user/$(id -u)/bus ]]; then
  export DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=/run/user/$(id -u)/bus}"
  "$platform_dir/gnome.sh"
  if command -v google-chrome >/dev/null; then
    xdg-settings set default-web-browser google-chrome.desktop
  fi
else
  echo "No desktop session; skipped. Run platforms/dgx/gnome.sh once logged in to GNOME."
fi

echo
echo "DGX dotfiles deployed."
echo
echo "Next:"
echo "  - sudo platforms/dgx/system-setup.sh gb10-N   (hostname, Chrome, QSFP link, cleanup, ...)"
echo "  - Log out and back in, so GNOME picks up the PATH, font and docker group changes"
echo "  - gh auth login"
