-- Pull in the wezterm API
local wezterm = require("wezterm")

-- This will hold the configuration.
local config = wezterm.config_builder()

-- -- my coolnight colorscheme
-- config.colors = {
--         foreground = "#CDD6F4",
--         background = "#0E0D16",
--         cursor_bg = "#F5E0DC",
--         cursor_border = "#F5E0DC",
--         cursor_fg = "#1E1E2E",
--         selection_bg = "#F5E0DC",
--         selection_fg = "#1E1E2E",
--         ansi = { "#121212", "#a52aff", "#7129ff", "#3d2aff", "#2b4fff", "#2883ff", "#28b9ff", "#f1f1f1" },
--         brights = { "#666666", "#ba5aff", "#905aff", "#8f00ff", "#5c78ff", "#5ea2ff", "#5ac8ff", "#ffffff" },
-- }

config.color_scheme = "Catppuccin Mocha"

-- config.font = wezterm.font("JetBrainsMonoNL Nerd Font")
config.font = wezterm.font_with_fallback({
	"JetBrainsMonoNL Nerd Font",
	"Symbols Nerd Font Mono",
	"Noto Sans Symbols",
})

config.font_size = 15

config.enable_tab_bar = false

-- config.window_decorations = "RESIZE"
config.window_background_opacity = 0.9
config.macos_window_background_blur = 10

config.window_padding = {
	left = 3,
	right = 3,
	top = 1,
	-- bottom = "0.3cell",
	bottom = 0,
}

-- and finally, return the configuration to wezterm
return config
