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
  -- 4.5+: stock Super + L (tiling -> scrolling -> floating), stock Super + M
  -- (minimize to the dock) and stock Super + Alt + Space (Apps grid, served by
  -- the dock plugin, so omarchy.dock must stay enabled in shell.json).
  -- Moving a workspace to another monitor is stock Super + Shift + Alt + arrows,
  -- so Super + Alt + L is left to its stock "cycle layout back".
  -- Super + Shift + T (Activity, btop) is a stock binding from 4.5 on.

  -- Super + Ctrl + Alt + N moves every window of the current workspace into
  -- workspace N of this monitor (4.5 numbers workspaces per monitor) and
  -- follows. To land on another monitor, move the workspace there first.
  local function merge_workspace_into(slot)
    return function()
      local from = hl.get_active_workspace()
      local monitor = hl.get_active_monitor()
      if not from or from.special or from.id < 1 or not monitor then
        return
      end

      local target = o.workspaces.workspace_id(monitor, slot)
      if target == from.id then
        return
      end

      local windows = hl.get_workspace_windows(tostring(from.id))
      -- Brings the target back if an unplug left it on another monitor.
      o.workspaces.focus(slot)()
      for _, window in ipairs(windows) do
        hl.dispatch(hl.dsp.window.move({
          workspace = tostring(target),
          follow = false,
          window = "address:" .. window.address,
        }))
      end
    end
  end

  for slot = 1, 10 do
    o.bind("SUPER + CTRL + ALT + " .. (slot % 10), "Move all windows to workspace " .. slot, merge_workspace_into(slot))
  end
else
  -- 4.0.x (verified unbound in Quattro defaults).
  o.bind("SUPER + SHIFT + T", "Activity", { tui = "btop" })
  o.bind("SUPER + ALT + H", "Move workspace to left monitor", hl.dsp.workspace.move({ monitor = "l" }))
  o.bind("SUPER + ALT + L", "Move workspace to right monitor", hl.dsp.workspace.move({ monitor = "r" }))
end
