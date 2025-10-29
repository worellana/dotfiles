local wezterm = require("wezterm")
local config = wezterm.config_builder()

-- Tell lua where to find our modules.
-- package.path is a search path that lua uses to find modules.
-- We are adding the user's home directory to the search path.
package.path = wezterm.home_dir .. "/?.lua;" .. package.path

-- Load modules
local theme = require("theme")
local keys = require("keys")
local settings = require("settings")

-- Apply the configurations from the modules
theme.apply_to(config)
keys.apply_to(config)
settings.apply_to(config)

-- You can add any local overrides here if needed, for example:
-- config.color_scheme = "Dracula"

config.win32_system_backdrop = 'Acrylic'
config.window_background_opacity = 0.55

return config