-- Personal keybindings. Preinstalled app/webapp defaults are disabled via
-- omarchy_preinstalled_bindings = false in hyprland.lua; the ones in use are
-- re-added here.

-- Preinstalled bindings kept, stock behavior.
o.bind("SUPER + ALT + RETURN", "Tmux", { omarchy = "terminal-tmux" })
o.bind("SUPER + CTRL + RETURN", "Herdr", { omarchy = "terminal-herdr" })
o.bind("SUPER + SHIFT + M", "Music", { omarchy = "spotify" })
o.bind("SUPER + SHIFT + ALT + M", "Music TUI", { tui = "cliamp", focus = true })
o.bind("SUPER + SHIFT + D", "Docker", { tui = "lazydocker" })
o.bind("SUPER + SHIFT + G", "Signal", { omarchy = "signal" })

-- Replacements for stock preinstalled apps.
o.bind("SUPER + SHIFT + SLASH", "Passwords", { launch = "enteauth" })

-- Additions (verified unbound in Quattro defaults).
o.bind("SUPER + SHIFT + T", "Activity", { tui = "btop" })
o.bind("SUPER + ALT + H", "Move workspace to left monitor", hl.dsp.workspace.move({ monitor = "l" }))
o.bind("SUPER + ALT + L", "Move workspace to right monitor", hl.dsp.workspace.move({ monitor = "r" }))
