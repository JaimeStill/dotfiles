# dotfiles

Consolidated desktop configuration, dotfiles, and wallpapers — a one-stop restore for any machine
running this setup. Two platforms today: Omarchy (Hyprland-based Arch Linux) and DGX OS (NVIDIA's
Ubuntu-based OS on the GB10 workstations).

## Layout

Shared, platform-neutral configs live at the top level. Anything that only makes sense on one
platform lives under `platforms/<platform>/` and is only ever applied there.

- `install.sh` — links the shared configs, detects the platform, then runs that platform's
  `install.sh`. Detection (`lib/platform.sh`): `$OMARCHY_PATH` (`/usr/share/omarchy`, or
  `~/.local/share/omarchy` on pre-Quattro installs) means Omarchy,
  `/etc/dgx-release` means DGX OS. Every platform script also refuses to run on the wrong one.
- `platforms/omarchy/` — Hyprland, Omarchy hooks/backgrounds, Aether, the other terminals, the
  pacman/AUR package set.
- `platforms/dgx/` — GNOME setup, root-level system setup, DGX-only mise tools, tmux and herdr
  configs, the stand-in theme.

**Themes.** The shared nvim and kitty configs load their theme from `~/.local/state/dotfiles/theme/`.
Each platform points that at its own source: Omarchy at its live theme
(`~/.local/state/omarchy/current/theme`, so theme switches and nvim hot-reload keep working), DGX OS
at the fixed theme in `platforms/dgx/theme/` (Noctis Obscuro in both kitty and Neovim). Keep shared files free of platform paths; route through an indirection like this one
instead.

**Platform overlays.** Where a shared config needs a per-platform setting, it includes a file that
each platform links into place. `config/kitty/kitty.conf` ends with `include platform.conf`, which
is `platforms/<platform>/config/kitty/platform.conf`: no title bar under Hyprland's tiling, a
title bar under GNOME for moving and resizing windows.

## Restoring on an Omarchy machine

1. Install Omarchy first — this repo assumes the base system, not a replacement for it.
2. Clone this repo to `~/dotfiles`.
3. Run `./install.sh`. It's idempotent — safe to re-run any time after pulling changes.
4. Run `platforms/omarchy/packages/install-packages.sh` — installs the curated set (`pacman.txt`,
   `aur.txt`) through Omarchy's own CLI (`omarchy install ...`, `omarchy-pkg-add`,
   `omarchy-pkg-aur-add`), not raw pacman/yay, so packages with dedicated Omarchy setup (browser
   policy, service enablement, font/theme integration) get it. Idempotent — safe to re-run.
5. Run `mise install` to fetch the language/tool versions from `config/mise/config.toml`, then
   `packages/install-go-tools.sh` for the `go install` targets in `packages/go-tools.txt`
   (`gopls`, `gonew`) that aren't mise-managed tools themselves.
6. Set up `~/.config/hypr/monitors.lua` by hand for the new machine's actual displays, and fill in
   `~/.config/hypr/envs.lua` (scaffolded empty by `install.sh`) with whatever this machine needs
   (see below).

## Restoring on a DGX OS machine (GB10)

Hostnames are `gb10-1`, `gb10-2`, ...; the number also picks the node's QSFP addresses. Both nodes
need the same username, and the QSFP cable in the same physical port on each.

1. Clone this repo to `~/dotfiles` (git ships with DGX OS).
2. From the GNOME desktop, run `./install.sh`. No sudo needed. Installs kitty, Claude Code, mise,
   herdr, the CaskaydiaMono Nerd Font, every mise tool (shared + `platforms/dgx/config/mise/dgx.toml`),
   and the GNOME settings and shortcuts.
3. Run `sudo platforms/dgx/system-setup.sh gb10-N`. Steps, in order (pass step names after the
   hostname to run just those):
   - `hostname` — sets the hostname and adds `gb10-N-qsfp` names for every node to `/etc/hosts`.
   - `apt` — `build-essential`, `curl`, `git`, `unzip`, `xclip`, `kitty-terminfo`. The clipboard tool is xclip, not
     Omarchy's wl-clipboard: DGX OS forces `nvidia-drm modeset=0`, so GNOME runs on X11.
   - `chrome` — Google's arm64 `.deb` (which adds Google's apt repo), set as default browser.
   - `tailscale` — official installer, then `tailscale up --ssh` if not yet connected.
   - `docker` — adds you to the `docker` group.
   - `network` — QSFP static addresses (`/etc/netplan/40-cx7.yaml`), and removes the default DHCP
     profiles NetworkManager put on the ConnectX-7 ports. Those fail every 45s with nothing to hand
     out addresses on a direct cable, which is the source of the "Connection failed" notifications.
   - `terminal` — kitty as `x-terminal-emulator`.
   - `cleanup` — removes the bundled apps (see below). Preview it first with
     `DRY_RUN=1 platforms/dgx/system-setup.sh gb10-N cleanup` (no root, changes nothing).
4. Log out and back in (PATH for desktop shortcuts, font, docker group).
5. `gh auth login`.
6. Once both nodes are set up, connect them (next section), then run
   `sudo platforms/dgx/system-setup.sh gb10-N ssh-harden` on each to disable SSH password logins.
   It's never part of the default run, since the key exchange needs passwords.

### Connecting the two GB10s

Follows NVIDIA's [Connect Two Sparks](https://build.nvidia.com/spark/connect-two-sparks/stacked-sparks)
playbook. Port 0 is used by default (`enp1s0f0np0` + `enP2p1s0f0np0` — two logical interfaces for
one physical port); for port 1, set `CX7_IFACES="enp1s0f1np1 enP2p1s0f1np1"` when running the
`network` step. After `network` has run on both nodes:

```bash
ibdev2netdev                  # the port's two interfaces show (Up)
ping -c3 gb10-2-qsfp          # from gb10-1

# Passwordless SSH both ways (prompts for each node's password once). Run as your user, not sudo.
curl -fsSLO https://raw.githubusercontent.com/NVIDIA/dgx-spark-playbooks/main/nvidia/connect-two-sparks/assets/discover-sparks
bash ./discover-sparks
ssh gb10-2-qsfp hostname

# RDMA bandwidth. Each logical interface is one PCIe half of the port and tops out near 100 Gb/s
# (~108 alone), so test both halves at once; together they should reach ~185 Gb/s. NCCL uses both.
ib_write_bw -d rocep1s0f0   -p 18515 -D 10 --report_gbits &                  # on gb10-2 (servers)
ib_write_bw -d roceP2p1s0f0 -p 18516 -D 10 --report_gbits &
ib_write_bw -d rocep1s0f0   -p 18515 -D 10 --report_gbits 192.168.100.11 &   # on gb10-1 (clients)
ib_write_bw -d roceP2p1s0f0 -p 18516 -D 10 --report_gbits 192.168.101.11 &
```

Keep both nodes on the same DGX OS version (driver/CUDA/NCCL mismatches break multi-node runs).

### What `cleanup` removes, and what it never touches

Removes LibreOffice, Rhythmbox, Shotwell, Cheese, Totem, Transmission, the GNOME games, GKrellm,
Thunderbird and Firefox (debs and snaps), Remmina, Simple Scan, Déjà Dup, and GNOME Terminal.

On DGX OS these come from NVIDIA's `nvidia-system-station-*` bundles, so removing any of them
removes the bundles too — and without care, a later `apt autoremove` would then take ~270 packages
(Wi-Fi supplicant included). `cleanup` first marks everything else the bundles provide as manually
installed, so only the removed apps' own dependencies are autoremoved. It refuses to run if apt
would remove anything NVIDIA/DGX, CUDA, Docker, snapd (NVIDIA's firmware-updater is a snap),
networking, SSH, the desktop itself, or the kernel/boot chain. `dgx-spark-ota-update-meta`, NVIDIA's
update channel, is unaffected.

Byobu stays installed (`ubuntu-server` depends on it); `install.sh` only hides its launcher.

### Keyboard shortcuts (GNOME)

Set by `platforms/dgx/gnome.sh`, modeled on Omarchy. The dock and desktop icons are turned off and a
workspace indicator added to the top bar. Workspaces are GNOME's native dynamic ones: only workspace
1 at login, plus one trailing empty workspace; empty workspaces are removed and the rest renumber.
Ctrl+Alt+arrows and Ctrl+Shift+Alt+arrows are left free for tmux and herdr panes. Focus follows the
mouse (sloppy, no auto-raise), like Hyprland.

| Keys | Action |
|---|---|
| Super+Space | App grid (type to search) |
| Super+Enter | kitty |
| Super+Alt+Enter | kitty attached to tmux session `Work` |
| Super+Ctrl+Enter | kitty running herdr |
| Super+Shift+B | Chrome |
| Super+Shift+F | Files |
| Super+Shift+N | nvim |
| Super+Shift+T | btop |
| Super+Shift+D | lazydocker |
| Super+W | Close window |
| Super+F | Fullscreen |
| Super+1–9, Super+0 | Switch to workspace 1–10 (existing ones only) |
| Super+Shift+1–9, Super+Shift+0 | Move window to workspace 1–10 |
| Super+Page_Down / Super+Alt+Right | Next workspace (from the last one, creates a new one) |
| Super+Shift+Page_Down / Super+Shift+Alt+Right | Move window to the next workspace |
| Super+Page_Up / Super+Alt+Left | Previous workspace |

GNOME has no directional window focus (Super+arrows tile instead); that would need a tiling
extension.

### GPU memory on the GB10

There's no VRAM reservation to configure: the CPU and GPU share one coherent memory pool, and CUDA
allocates from it on demand (`nvidia-smi` reports memory as N/A). What does bite:
`cudaMemGetInfo` counts reclaimable page cache as used, so after heavy file I/O, vLLM and similar
tools can underestimate free memory. Run `drop-caches` (from `platforms/dgx/bin/`) before loading a
large model, or lower vLLM's `--gpu-memory-utilization`.

## What's tracked here, and why

Shared:

- `nvim/` — full Neovim config, imported via `git subtree` from the former
  `github.com/JaimeStill/nvim` repo, with its commit history intact. `lua/plugins/theme.lua` links
  to the per-platform theme (see Layout). The clipboard always syncs (`unnamedplus`, overriding
  LazyVim's SSH exception), and `lua/config/remote_clipboard.lua` sends every copy over OSC 52 in
  SSH, tmux and herdr, so a plain `y` on a remote machine reaches the local clipboard. Paste there
  comes from tmux's buffer inside tmux, otherwise from Neovim's last yank (text from the local
  machine comes in through the terminal's own paste); local Wayland sessions use wl-copy/wl-paste.
- `config/kitty/kitty.conf` — font, padding, and keybinding customizations layered on top of an
  `include` of the per-platform theme, with `platform.conf` (see Layout) last.
- `config/starship.toml` — prompt.
- `config/mise/config.toml` — tracked language/tool versions. Tools a platform's package manager
  already provides stay out of it (on DGX OS they're in `platforms/dgx/config/mise/dgx.toml`).
- `config/claude/settings.json` — Claude Code preferences (model, permissions, plugins, enabled
  marketplaces). `~/claude-settings` only covers `CLAUDE.md` and its context-management pieces, not
  settings, so this lives here instead. `~/.claude/settings.local.json`, if a machine ever has one,
  stays untracked — that file's meant to be per-machine. The `SessionStart` hook is herdr's own
  Claude integration (`herdr integration install claude`); herdr rewrites that entry and its hook
  script on updates, so leave both as herdr writes them.
- `gitconfig` — identity, aliases, credential helpers (`gh`/`glab` resolved from `PATH`, so
  pacman and mise installs both work), and an `includeIf` for `~/s2va/` that swaps in a work email
  for repos under that directory.
- `bashrc.local` — sourced from `~/.bashrc`. Holds `PATH` additions and Azure CLI aliases.
  `LIBVA_DRIVER_NAME` stays directly in `~/.bashrc` on machines that need it — GPU-specific, not
  tracked here.
- `wallpapers/` — personal wallpaper collection. Canonical location; `~/Pictures/wallpapers`
  symlinks to it. Two Aether blueprints (Artemis-II, Monk's Journey) reference files here directly.
- `packages/{go-tools.txt,install-go-tools.sh}` — `go install` targets that aren't mise-managed
  tools themselves (`gopls`, `gonew`).

Omarchy (`platforms/omarchy/`):

- `config/hypr/{bindings.lua,hyprland.lua,looknfeel.lua}` — custom keybindings and the
  `omarchy_preinstalled_bindings = false` toggle. `input.lua`, `autostart.lua`, `hyprsunset.conf`
  aren't tracked — they're untouched Omarchy defaults.
- `config/{alacritty,ghostty,foot}` — font, padding, and keybinding customizations layered on top
  of each terminal's `import`/`include` of the active Omarchy theme.
- `config/kitty/platform.conf` — hides kitty's title bar (Hyprland tiles).
- `config/omarchy/shell.json` — bar clock format.
- `config/omarchy/hooks/post-update.d/keep-agents-native.hook` — the only custom Omarchy hook on
  this system. Keeps `claude` (and `codex`, unused today but may see use later) installed natively
  rather than mise-managed, undoing any re-adoption a migration causes. Omarchy's own
  `setup-agent.hook` in the same directory is stock and isn't tracked.
- `config/omarchy/backgrounds/catppuccin/` — wallpapers added to the stock catppuccin theme.
- `config/aether/{settings.json,favorites.json,wallhaven.json,blueprints/}` — the Aether theme
  engine's source config. `aether/theme/` (rendered per-app output) and the empty `themes/`,
  `custom/` directories aren't tracked — they're generated, not source.
- `config/spotify-flags.conf` — runs Spotify natively on Wayland instead of through Xwayland
  (read by the `/usr/bin/spotify` wrapper). Sharper under fractional scaling, and Spotify keeps
  launching even if the Xwayland socket in `/tmp/.X11-unix/` disappears, which otherwise makes it
  exit silently.
- `bin/omarchy-font-size-set` — sets font size across all four terminals. Omarchy's own
  `omarchy-font-set` handles font *family* globally but never size (the only trace is a hardcoded,
  buggy `:size=9` it forces into foot's config as a side effect); this applies the same
  sed-per-config-file approach to size instead.
- `packages/{pacman.txt,aur.txt}` — the curated set of software to install beyond stock Omarchy,
  hand-reviewed rather than a raw diff of everything explicitly installed on any one machine.
  `install-packages.sh` installs them through Omarchy's own CLI. `audit-installed.sh` prints what's
  explicitly installed on the current machine beyond stock Omarchy that isn't yet in the curated
  lists — a prompt to review, not something it writes anywhere.

DGX OS (`platforms/dgx/`):

- `install.sh`, `system-setup.sh`, `gnome.sh` — user-level setup, root-level setup, GNOME settings
  and shortcuts (see above).
- `env.sh` — `PATH` for mise shims and `~/.local/bin`, sourced from `~/.profile` (desktop session)
  and the top of `~/.bashrc` (ahead of Ubuntu's interactive-only guard, so `ssh host cmd` and
  `herdr --remote` find mise tools). `bashrc` — Omarchy's bash rc chain for DGX OS (Omarchy's own
  bashrc already does all of it).
- `bash/` — Omarchy's bash setup (`basecamp/omarchy` `default/bash`), copied with its source commit
  in each header: `envs` (`EDITOR=nvim`, bat man pager), `shell` (history, completion), `aliases`
  (`n`, `t`, `h`, `d`, eza `ls`/`lt`, `ff`, zoxide `cd`, git), `fns/` (tmux/herdr layouts,
  worktrees, rsync, ssh helpers), `init` (zoxide, fzf key bindings), `inputrc`. Omarchy-only
  pieces are dropped or swapped (`a`, `r`, `fns/drives`, `omarchy-launch-*`). Re-sync by hand when
  Omarchy changes them.
- `bin/launch-browser` — opens URLs detached from the terminal; set as `BROWSER` in interactive
  shells. gh waits for its browser launcher to exit, so a foreground browser hangs
  `gh auth login`. Shell-scoped, since a session-wide `BROWSER` stops `xdg-settings` changing the
  default browser.
- `config/mise/dgx.toml` — dev tools that Omarchy gets from pacman: neovim, tmux, lazygit,
  lazydocker, btop, gh, ripgrep, fd, fzf, tree-sitter, starship, eza, zoxide, bat, fastfetch. Ubuntu 24.04's apt versions are
  too old (neovim 0.9, tmux 3.4) or missing (lazygit).
- `config/tmux/tmux.conf`, `config/herdr/config.toml` — Omarchy's defaults, copied (Omarchy
  ships these itself, so they aren't tracked on that side).
- `config/fontconfig/fonts.conf` — CaskaydiaMono Nerd Font as the monospace default.
- `config/fastfetch/config.jsonc` — Omarchy's fastfetch layout, with DGX OS version, NVIDIA driver,
  and last package change in place of the Omarchy-only commands.
- `config/kitty/platform.conf` — keeps kitty's title bar (GNOME doesn't tile).
- `theme/{neovim.lua,kitty.conf}` — fixed theme. `kitty.conf` is the
  [Noctis Obscuro](https://terminalcolors.com/themes/noctis/obscuro/) palette; `neovim.lua` loads
  `noctis_obscuro` from [talha-akram/noctis.nvim](https://github.com/talha-akram/noctis.nvim), a
  port of the Noctis editor theme, with kitty's background showing through.
- `bin/drop-caches` — page cache flush (see GPU memory above).

## What's deliberately not tracked

- `~/.config/hypr/monitors.lua` — real hardware profile, specific to whichever machine set it up.
  Each machine keeps its own, set up by hand. Omarchy's own scaffolding always creates this file,
  so a fresh install has one even though this repo doesn't track it.
- `~/.config/hypr/envs.lua` — per-machine Hyprland environment variables (`hl.env(...)`), for
  whatever a given machine's hardware or setup needs. Omarchy doesn't scaffold this file itself,
  so `platforms/omarchy/install.sh` creates an empty one if the machine doesn't have one yet, and
  never overwrites an existing one. Fill it in by hand per machine.
- `LIBVA_DRIVER_NAME` — GPU-specific, stays local to the machine that needs it.
- `~/.config/zed` — no longer used.
- `~/.local/bin`'s mise-generated wrapper stubs — regenerated by `mise install`, not user content.
