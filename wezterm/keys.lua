local wezterm = require("wezterm")
local act = wezterm.action

local module = {}

function module.apply_to(config)
  config.leader = { key = "a", mods = "CTRL", timeout_milliseconds = 1000 }

  local function move_pane(key, direction)
    return {
      key = key,
      mods = "LEADER",
      action = wezterm.action.ActivatePaneDirection(direction),
    }
  end

  local function resize_pane(key, direction)
    return {
      key = key,
      action = wezterm.action.AdjustPaneSize({ direction, 3 }),
    }
  end

  config.keys = {
    {
      key = "LeftArrow",
      mods = "CTRL",
      action = wezterm.action.SendString("\x1bb"),
    },
    {
      key = "RightArrow",
      mods = "CTRL",
      action = wezterm.action.SendString("\x1bf"),
    },
    {
      key = ",",
      mods = "SUPER",
      action = wezterm.action.SpawnCommandInNewTab({
        cwd = wezterm.home_dir,
        args = { "code", wezterm.config_file },
      }),
    },
    {
      key = "v",
      mods = "LEADER",
      action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }),
    },
    {
      key = "b",
      mods = "LEADER",
      action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }),
    },
    {
      key = "w",
      mods = "LEADER",
      action = wezterm.action.CloseCurrentPane({ confirm = true }),
    },
    {
      key = "a",
      mods = "LEADER|CTRL",
      action = wezterm.action.SendKey({ key = "a", mods = "CTRL" }),
    },
    move_pane("j", "Down"),
    move_pane("k", "Up"),
    move_pane("h", "Left"),
    move_pane("l", "Right"),
    {
      key = "r",
      mods = "LEADER",
      action = wezterm.action.ActivateKeyTable({
        name = "resize_panes",
        one_shot = false,
        timeout_milliseconds = 1000,
      }),
    },
    {
      key = "f",
      mods = "LEADER",
      action = wezterm.action.ShowLauncherArgs({ flags = "FUZZY|WORKSPACES" }),
    },
    {
      key = "p",
      mods = "CTRL|ALT",
      action = wezterm.action.SpawnCommandInNewTab({
        args = { "pwsh.exe", "-Nologo" },
        domain = { DomainName = "local" },
      }),
    },
    {
      key = "b",
      mods = "CTRL|ALT",
      action = wezterm.action.SpawnCommandInNewTab({
        args = { "C:\\Program Files\\Git\\bin\\bash.exe", "-i", "-l" },
        domain = { DomainName = "local" },
      }),
    },
    {
      key = "t",
      mods = "CTRL|ALT",
      action = wezterm.action.SpawnCommandInNewTab({
        args = { "cmd.exe", "" },
        domain = { DomainName = "local" },
      }),
    },
    {
      key = "d",
      mods = "CTRL|ALT",
      action = wezterm.action.SpawnCommandInNewTab({
        domain = { DomainName = "WSL:Fedora" },
      }),
    },
    { key = "L", mods = "CTRL|ALT", action = wezterm.action.ShowDebugOverlay },
  }

  config.key_tables = {
    resize_panes = {
      resize_pane("j", "Down"),
      resize_pane("k", "Up"),
      resize_pane("h", "Left"),
      resize_pane("l", "Right"),
    },
  }
end

return module
