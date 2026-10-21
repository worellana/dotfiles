local wezterm = require("wezterm")
local config = wezterm.config_builder()
--local crt = dofile(wezterm.config_dir .. "/crt.lua")
-- local session_manager = require("wezterm-session-manager/session-manager")

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

config.win32_system_backdrop = "Acrylic"
config.window_background_opacity = 0.6

--crt.apply_to_config(config, { preset = "ibm_dos" })
--crt.apply_to_config(config, {
--	preset = "ibm_dos",
-- any field from the tables below
--	screen_curvature = 0.0,
--	bloom = 0.0,
--	burn_in = 0.0,
--	jitter = 0.0,
--	static_noise = 0.0,
--	ambient_light = 0.1,
--	flickering = 0.1,
--	frame_shininess = 0.1,
--})

-- wezterm.on("save_session", function(window)
-- 	session_manager.save_state(window)
-- end)
-- wezterm.on("load_session", function(window)
-- 	session_manager.load_state(window)
-- end)
-- wezterm.on("restore_session", function(window)
-- 	session_manager.restore_state(window)
-- end)

return config
