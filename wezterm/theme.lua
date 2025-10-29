local wezterm = require("wezterm")

local module = {}

function module.apply_to(config)
  config.color_scheme = "Panda (Gogh)"

  config.font = wezterm.font_with_fallback({
    {
      family = "CommitMono Nerd Font",
      weight = "Light",
      italic = false,
    },
    {
      family = "FiraCode Nerd Font",
      weight = "ExtraLight",
    },
    {
      family = "Symbols Nerd Font Mono",
      weight = "Regular",
    },
  })

  config.foreground_text_hsb = {
    hue = 1.0,
    saturation = 1.2,
    brightness = 1.5,
  }

  config.inactive_pane_hsb = {
    saturation = 0.9,
    brightness = 0.8,
  }

  config.font_size = 10
  config.line_height = 1.0
  config.harfbuzz_features = { "calt", "liga", "ss01", "ss02", "ss03", "ss04", "ss05", "ss06", "ss07", "ss08", "ss09", "zero", "onum" }

  config.freetype_load_flags = "NO_HINTING"
  config.freetype_load_target = "Light"
  config.freetype_render_target = "HorizontalLcd"

  config.cursor_blink_ease_in = "EaseIn"
  config.cursor_blink_ease_out = "EaseOut"
  config.animation_fps = 120
  config.cursor_blink_rate = 800
  config.cursor_thickness = 1.0
  config.default_cursor_style = "BlinkingBar"

  config.use_fancy_tab_bar = true
  config.hide_tab_bar_if_only_one_tab = false
  config.show_new_tab_button_in_tab_bar = true
  config.window_background_opacity = 0
  config.win32_system_backdrop = 'Mica'
  -- config.text_background_opacity = 0.85

  config.window_padding = {
    left = 5,
    right = 5,
    top = 20,
    bottom = 5,
  }

  config.window_decorations = "INTEGRATED_BUTTONS|RESIZE"
  config.enable_tab_bar = true
  config.tab_bar_at_bottom = false

  config.window_frame = {
    font = wezterm.font({ family = "CommitMono Nerd Font", weight = "Regular" }),
    font_size = 10,
    inactive_titlebar_bg = "#353535",
    active_titlebar_bg = "#2b2042",
    inactive_titlebar_fg = "#cccccc",
    active_titlebar_fg = "#ffffff",
    inactive_titlebar_border_bottom = "#2b2042",
    active_titlebar_border_bottom = "#2b2042",
    button_fg = "#cccccc",
    button_bg = "#2b2042",
    button_hover_fg = "#ffffff",
    button_hover_bg = "#3b3052",
    border_left_width = "0.5cell",
    border_right_width = "0.5cell",
    border_bottom_height = "0.25cell",
    border_top_height = "0.25cell",
    border_left_color = "purple",
    border_right_color = "purple",
    border_bottom_color = "purple",
    border_top_color = "purple",
  }

  config.colors = {
    tab_bar = {
      inactive_tab_edge = "#575757",
    },
  }

  config.integrated_title_button_style = "Windows"
  config.integrated_title_button_color = "Auto"

  config.tab_max_width = 32
  config.show_new_tab_button_in_tab_bar = false

  local function tab_title(tab_info)
    local title = tab_info.tab_title
    if title and #title > 0 then
      return title
    end
    return tab_info.active_pane.title
  end

  wezterm.on("format-tab-title", function(tab, tabs, panes, conf, hover, max_width)
    local background = "#2b2042"
    local foreground = "#cccccc"
    local edge_background = "#2b2042"
    if tab.is_active or hover then
      background = "#E5C07B"
      foreground = "#282C34"
    end
    local edge_foreground = background

    local title = tab_title(tab)

    local max = config.tab_max_width - 9
    if #title > max then
      title = wezterm.truncate_right(title, max) .. "…"
    end

    return {
      { Background = { Color = edge_background } },
      { Foreground = { Color = edge_foreground } },
      { Text = " " },
      { Background = { Color = background } },
      { Foreground = { Color = foreground } },
      { Attribute = { Intensity = tab.is_active and "Bold" or "Normal" } },
      { Text = " " .. (tab.tab_index + 1) .. ": " .. title .. " " },
      { Background = { Color = edge_background } },
      { Foreground = { Color = edge_foreground } },
      { Text = "" },
    }
  end)
end

return module
