#!/usr/bin/env bash
# Install the curated package set (packages/pacman.txt, packages/aur.txt) through
# Omarchy's own package-management CLI rather than raw pacman/yay. Idempotent —
# omarchy-pkg-add and omarchy-pkg-aur-add only install what's missing.
set -euo pipefail

# Packages with a dedicated omarchy install group get real setup beyond a bare
# install (theme/policy integration, service enablement, default-app wiring).
omarchy install browser chrome
omarchy install service signal
omarchy install service spotify
# Also sets kitty as the system default terminal (SUPER+Return, xdg-terminal-exec).
omarchy install terminal kitty
# Also switches the system font to it (terminal configs already hardcode this
# family; this additionally sets the fontconfig default for Qt/GTK/shell apps).
omarchy install font 'Cascadia Mono' ttf-cascadia-mono-nerd 'CaskaydiaMono Nerd Font'

# No dedicated install group; the omarchy CLI's generic AUR helper.
omarchy-pkg-aur-add proton-authenticator-bin

# No dedicated install group; official repo packages via the generic helper.
omarchy-pkg-add aws-cli-v2 azure-cli caligula github-cli glab pandoc-cli presenterm typst yazi

echo "Package install complete."
