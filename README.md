# dotfiles

Consolidated desktop configuration, dotfiles, and wallpapers — a one-stop restore for any machine
running this setup. Currently built around Omarchy (Hyprland-based Arch Linux); the layout keeps
Omarchy-specific pieces under `config/omarchy/` and `config/aether/` so the rest stays reusable if
that ever changes.

## Restoring on a new machine

1. Install Omarchy (or the target distro/desktop) first — this repo assumes the base system, not
   a replacement for it.
2. Clone this repo to `~/dotfiles`.
3. Run `./install.sh`. It's idempotent — safe to re-run any time after pulling changes.
4. Run `packages/install-packages.sh` — installs the curated set (`packages/pacman.txt`,
   `packages/aur.txt`) through Omarchy's own CLI (`omarchy install ...`, `omarchy-pkg-add`,
   `omarchy-pkg-aur-add`), not raw pacman/yay, so packages with dedicated Omarchy setup (browser
   policy, service enablement, font/theme integration) get it. Idempotent — safe to re-run.
5. Run `mise install` to fetch the language/tool versions from `config/mise/config.toml`, then
   `packages/install-go-tools.sh` for the `go install` targets in `packages/go-tools.txt`
   (`gopls`, `gonew`) that aren't mise-managed tools themselves.
6. Set up `~/.config/hypr/monitors.lua` by hand for the new machine's actual displays, and fill in
   `~/.config/hypr/envs.lua` (scaffolded empty by `install.sh`) with whatever this machine needs
   (see below).

## What's tracked here, and why

- `nvim/` — full Neovim config, imported via `git subtree` from the former
  `github.com/JaimeStill/nvim` repo, with its commit history intact.
- `config/hypr/{bindings.lua,hyprland.lua}` — custom keybindings and the
  `omarchy_preinstalled_bindings = false` toggle. `input.lua`, `looknfeel.lua`, `autostart.lua`,
  `hyprsunset.conf` aren't tracked — they're untouched Omarchy defaults.
- `config/{alacritty,kitty,ghostty,foot}` — font, padding, and keybinding customizations layered
  on top of each terminal's `import`/`include` of the active Omarchy theme (that import points at
  `~/.local/state/omarchy/current/theme/`, which is regenerated state, so these files are safe to
  track without fighting theme switches).
- `config/omarchy/shell.json` — bar clock format.
- `config/omarchy/hooks/post-update.d/keep-agents-native.hook` — the only custom Omarchy hook on
  this system. Keeps `claude` (and `codex`, unused today but may see use later) installed natively
  rather than mise-managed, undoing any re-adoption a migration causes. Omarchy's own
  `setup-agent.hook` in the same directory is stock and isn't tracked.
- `config/omarchy/backgrounds/catppuccin/` — wallpapers added to the stock catppuccin theme.
- `config/aether/{settings.json,favorites.json,wallhaven.json,blueprints/}` — the Aether theme
  engine's source config. `aether/theme/` (rendered per-app output) and the empty `themes/`,
  `custom/` directories aren't tracked — they're generated, not source.
- `config/mise/config.toml` — tracked language/tool versions.
- `gitconfig` — identity, aliases, credential helpers, and an `includeIf` for `~/s2va/` that swaps
  in a work email for repos under that directory.
- `bashrc.local` — sourced from `~/.bashrc`. Holds `PATH` additions and Azure CLI aliases.
  `LIBVA_DRIVER_NAME` stays directly in `~/.bashrc` on machines that need it — GPU-specific, not
  tracked here.
- `wallpapers/` — personal wallpaper collection. Canonical location; `~/Pictures/wallpapers`
  symlinks to it. Two Aether blueprints (Artemis-II, Monk's Journey) reference files here directly.
- `bin/omarchy-font-size-set` — sets font size across all four terminals. Omarchy's own
  `omarchy-font-set` handles font *family* globally but never size (the only trace is a hardcoded,
  buggy `:size=9` it forces into foot's config as a side effect); this applies the same
  sed-per-config-file approach to size instead.
- `packages/{pacman.txt,aur.txt}` — the curated set of software to install beyond stock Omarchy,
  hand-reviewed rather than a raw diff of everything explicitly installed on any one machine.
  `packages/install-packages.sh` installs them through Omarchy's own CLI. `packages/go-tools.txt`
  + `packages/install-go-tools.sh` cover `go install` targets that aren't mise-managed tools
  themselves (`gopls`, `gonew`). `packages/audit-installed.sh` prints what's explicitly installed
  on the current machine beyond stock Omarchy that isn't yet in the curated lists — a prompt to
  review, not something it writes anywhere.

## What's deliberately not tracked

- `~/.config/hypr/monitors.lua` — real hardware profile, specific to whichever machine set it up.
  Each machine keeps its own, set up by hand. Omarchy's own scaffolding always creates this file,
  so a fresh install has one even though this repo doesn't track it.
- `~/.config/hypr/envs.lua` — per-machine Hyprland environment variables (`hl.env(...)`), for
  whatever a given machine's hardware or setup needs. Omarchy doesn't scaffold this file itself,
  so `install.sh` creates an empty one if the machine doesn't have one yet, and never overwrites
  an existing one. Fill it in by hand per machine.
- `LIBVA_DRIVER_NAME` — GPU-specific, stays local to the machine that needs it.
- `~/.config/zed` — no longer used.
- `~/.local/bin`'s mise-generated wrapper stubs — regenerated by `mise install`, not user content.

