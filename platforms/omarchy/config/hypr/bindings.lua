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
o.bind("SUPER + SHIFT + SLASH", "Passwords", { launch = "proton-authenticator" })

-- Additions. o.rebind only exists from Omarchy 4.5 on, so it tells the two
-- apart and the same file works on machines on either side of the update.
if o.rebind then
  -- 4.5+: tiling only, no dock.
  -- Super + L cycles tiling <-> scrolling and never floating (stock: also floating).
  o.rebind("SUPER + L", "Cycle tiling/scrolling layout", "omarchy-workspace-layout-tiling-toggle")
  -- Stock Super + Alt + L cycles the layout back; keep it for moving workspaces.
  o.rebind("SUPER + ALT + L", "Move workspace to right monitor", o.workspaces.move_to_monitor("r"))
  o.bind("SUPER + ALT + H", "Move workspace to left monitor", o.workspaces.move_to_monitor("l"))
  -- Stock opens the Apps grid from the dock, which is disabled in shell.json.
  o.rebind("SUPER + ALT + SPACE", "Apps menu", "omarchy-menu toggle apps")
  -- Minimize to the dock; does nothing without floating workspaces.
  hl.unbind("SUPER + M")
  -- Super + Shift + T (Activity, btop) is a stock binding from 4.5 on.
else
  -- 4.0.x (verified unbound in Quattro defaults).
  o.bind("SUPER + SHIFT + T", "Activity", { tui = "btop" })
  o.bind("SUPER + ALT + H", "Move workspace to left monitor", hl.dsp.workspace.move({ monitor = "l" }))
  o.bind("SUPER + ALT + L", "Move workspace to right monitor", hl.dsp.workspace.move({ monitor = "r" }))
end
