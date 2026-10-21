#!/usr/bin/env bash
# GNOME settings for an Omarchy-like, keyboard-driven desktop on DGX OS. Idempotent; run by
# platforms/dgx/install.sh, or on its own after changing anything here.
set -euo pipefail

FONT="CaskaydiaMono Nerd Font"
FONT_SIZE=11

kitty="$HOME/.local/bin/kitty"

# Custom shortcuts: name, binding, command. GNOME runs these without a shell, so anything
# needing one goes through bash -c. Commands find mise tools through PATH from ~/.profile.
CUSTOM_KEYBINDINGS=(
  "Terminal|<Super>Return|$kitty"
  "Tmux|<Super><Alt>Return|$kitty bash -c \"tmux attach || tmux new -s Work\""
  "Herdr|<Super><Control>Return|$kitty herdr"
  "Browser|<Super><Shift>b|google-chrome"
  "File manager|<Super><Shift>f|nautilus --new-window"
  "Editor|<Super><Shift>n|$kitty nvim"
  "Activity|<Super><Shift>t|$kitty btop"
  "Docker|<Super><Shift>d|$kitty lazydocker"
)

shell_ext() {
  # Ubuntu's session enables its own extensions (dock, desktop icons) unless they're listed in
  # disabled-extensions, so both lists are managed.
  local action=$1 uuid=$2 key=enabled-extensions other=disabled-extensions
  [[ $action == disable ]] && key=disabled-extensions other=enabled-extensions
  python3 -I - "$key" "$other" "$uuid" <<'PY'
import ast, subprocess, sys
key, other, uuid = sys.argv[1:]
def get(k):
    out = subprocess.check_output(["gsettings", "get", "org.gnome.shell", k], text=True).strip()
    return ast.literal_eval(out.removeprefix("@as ")) if out != "@as []" else []
def put(k, v):
    subprocess.check_call(["gsettings", "set", "org.gnome.shell", k, str(v)])
add, rem = get(key), get(other)
if uuid not in add:
    put(key, add + [uuid])
if uuid in rem:
    put(other, [u for u in rem if u != uuid])
PY
}

echo "Dock and desktop icons off, workspace indicator on"
shell_ext disable ubuntu-dock@ubuntu.com
shell_ext disable ding@rastersoft.com
shell_ext enable workspace-indicator@gnome-shell-extensions.gcampax.github.com

echo "Fonts: $FONT"
gsettings set org.gnome.desktop.interface font-name "$FONT $FONT_SIZE"
gsettings set org.gnome.desktop.interface document-font-name "$FONT $FONT_SIZE"
gsettings set org.gnome.desktop.interface monospace-font-name "$FONT $FONT_SIZE"
gsettings set org.gnome.desktop.wm.preferences titlebar-font "$FONT Bold $FONT_SIZE"
gsettings set org.gnome.desktop.interface color-scheme prefer-dark

echo "Focus follows the mouse"
# Sloppy focus, like Hyprland's follow_mouse: the window under the pointer gets focus, and keeps it
# over the empty desktop. No auto-raise, so a partly covered window can be typed into in place.
gsettings set org.gnome.desktop.wm.preferences focus-mode sloppy
gsettings set org.gnome.desktop.wm.preferences auto-raise false

echo "Workspaces: dynamic"
# GNOME's own model: only workspace 1 at login, plus one trailing empty workspace. Super+Page_Down
# (or Super+Alt+Right) moves to the next one, creating it; add Shift to take the window along.
gsettings set org.gnome.mutter dynamic-workspaces true

echo "Window and workspace shortcuts"
# Super+Space opens the app grid (type to search), like Omarchy's launcher. It was switching
# keyboard layouts; that keeps its dedicated key only.
gsettings set org.gnome.desktop.wm.keybindings switch-input-source "['XF86Keyboard']"
gsettings set org.gnome.desktop.wm.keybindings switch-input-source-backward "['<Shift>XF86Keyboard']"
gsettings set org.gnome.shell.keybindings toggle-application-view "['<Super>space']"

gsettings set org.gnome.desktop.wm.keybindings close "['<Super>w', '<Alt>F4']"
gsettings set org.gnome.desktop.wm.keybindings toggle-fullscreen "['<Super>f']"

# Super+N belonged to the dock's "launch app N"; it switches workspaces instead, with Super+0 as
# workspace 10. These reach only workspaces that exist (dynamic workspaces renumber as they empty).
for n in {1..10}; do
  key=$((n % 10))
  [[ $n -le 9 ]] && gsettings set org.gnome.shell.keybindings "switch-to-application-$n" "[]"
  gsettings set org.gnome.desktop.wm.keybindings "switch-to-workspace-$n" "['<Super>$key']"
  gsettings set org.gnome.desktop.wm.keybindings "move-to-workspace-$n" "['<Super><Shift>$key']"
done

# Ctrl+Alt+arrows and Ctrl+Shift+Alt+arrows belong to tmux and herdr (pane focus and resize);
# GNOME's Super-based equivalents stay.
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-left "['<Super>Page_Up', '<Super><Alt>Left']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-right "['<Super>Page_Down', '<Super><Alt>Right']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-up "[]"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-down "[]"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-left "['<Super><Shift>Page_Up', '<Super><Shift><Alt>Left']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-right "['<Super><Shift>Page_Down', '<Super><Shift><Alt>Right']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-up "[]"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-down "[]"

echo "App shortcuts"
base=/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings
paths=()
for i in "${!CUSTOM_KEYBINDINGS[@]}"; do
  IFS='|' read -r name binding command <<<"${CUSTOM_KEYBINDINGS[$i]}"
  path="$base/dotfiles$i/"
  schema="org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$path"
  gsettings set "$schema" name "$name"
  gsettings set "$schema" binding "$binding"
  gsettings set "$schema" command "$command"
  paths+=("'$path'")
done
gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "[$(IFS=,; echo "${paths[*]}")]"

echo "GNOME configured."
