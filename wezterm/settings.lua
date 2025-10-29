local wezterm = require("wezterm")
local mux = wezterm.mux

local module = {}

function module.apply_to(config)
  config.font = wezterm.font_with_fallback({
    "CommitMono Nerd Font",
    "Noto Sans",
  })

  config.font_rules = {
    {
      italic = true,
      font = wezterm.font_with_fallback({
        { family = "CommitMono Nerd Font", italic = true },
        { family = "Noto Sans", italic = true },
      }),
    },
    {
      intensity = "Bold",
      font = wezterm.font_with_fallback({
        { family = "CommitMono Nerd Font", weight = "Bold" },
        { family = "Noto Sans", weight = "Bold" },
      }),
    },
  }

  config.font_size = 10.0
  --config.line_height = 1.01
  --config.cell_width = 1.01
  config.freetype_load_target = "Normal"
  config.freetype_render_target = "Normal"

  config.launch_menu = {
    { label = "PowerShell Core", args = { "pwsh", "-NoLogo" } },
    { label = "PowerShell Desktop", args = { "powershell" } },
    { label = "Command Prompt", args = { "cmd" } },
    {
      label = "Git Bash",
      args = { "C:\\Program Files\\Git\\bin\\bash.exe", "-i", "-l" },
    },
  }

  config.default_prog = { "pwsh.exe", "-NoLogo" }

  config.wsl_domains = {
    {
      name = "WSL:Fedora",
      distribution = "FedoraLinux-42",
      username = "worellana",
      default_cwd = "/home/worellana",
    },
  }

  config.automatically_reload_config = true
  config.exit_behavior_messaging = "Verbose"
  config.status_update_interval = 1000
  config.scrollback_lines = 20000

  config.hyperlink_rules = {
    {
      regex = "\\((\\w+://\\S+)\\)",
      format = "$1",
      highlight = 1,
    },
    {
      regex = "\\[(\\w+://\\S+)\\]",
      format = "$1",
      highlight = 1,
    },
    {
      regex = "\\{(\\w+://\\S+)\\}",
      format = "$1",
      highlight = 1,
    },
    {
      regex = "<(\\w+://\\S+)>",
      format = "$1",
      highlight = 1,
    },
    {
      regex = "\\b\\w+://\\S+[)/a-zA-Z0-9-]+",
      format = "$0",
    },
    {
      regex = "\\b\\w+@[\\w-]+(\\.[\\w-]+)+\\b",
      format = "mailto:$0",
    },
  }

  config.front_end = "OpenGL"
  config.webgpu_power_preference = "HighPerformance"
  -- Set to false as your preferred adapter is already specified.
  -- This might slightly improve startup time. Revert to true if you face rendering issues.
  config.webgpu_force_fallback_adapter = false
  config.webgpu_preferred_adapter = {
    backend = "Vulkan",
    device_type = "DiscreteGpu",
    name = "NVIDIA GeForce RTX 3050 Ti Laptop GPU",
    device = 9696,
    vendor = 4318,
    driver = "NVIDIA",
    driver_info = "576.80",
  }

  config.adjust_window_size_when_changing_font_size = false
  config.use_dead_keys = false

  config.initial_cols = 140
  config.initial_rows = 30

  config.hide_mouse_cursor_when_typing = true

  config.exit_behavior = "Close"
  config.window_close_confirmation = "NeverPrompt"

  local function segments_for_right_status(window)
    return {
--      window:active_workspace(),
--      wezterm.nerdfonts.fa_clock_o .. "  " .. wezterm.strftime("%a %b %-d %H:%M"),
--      wezterm.hostname(),
    }
  end

  wezterm.on("gui-startup", function()
    local tab, pane, window = mux.spawn_window({})
    --window:gui_window():maximize()
  end)

  wezterm.on("update-status", function(window, pane)
    local SOLID_LEFT_ARROW = utf8.char(0xe0b2)
    local segments = segments_for_right_status(window)
    local color_scheme = window:effective_config().resolved_palette
    local bg = wezterm.color.parse(color_scheme.background)
    local fg = color_scheme.foreground
    local gradient_to, gradient_from = bg
    gradient_from = gradient_to:lighten(0.2)
    local gradient = wezterm.color.gradient(
      {
        orientation = "Horizontal",
        colors = { gradient_from, gradient_to },
      },
      #segments
    )
    local elements = {}
    for i, seg in ipairs(segments) do
      local is_first = i == 1
      if is_first then
        table.insert(elements, { Background = { Color = "none" } })
      end
      table.insert(elements, { Foreground = { Color = gradient[i] } })
      table.insert(elements, { Text = SOLID_LEFT_ARROW })
      table.insert(elements, { Foreground = { Color = fg } })
      table.insert(elements, { Background = { Color = gradient[i] } })
      table.insert(elements, { Text = " " .. seg .. " " })
    end
    window:set_right_status(wezterm.format(elements))
  end)
end

return module
