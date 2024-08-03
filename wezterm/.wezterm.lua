-- Pull in the wezterm API
local wezterm = require("wezterm")

-- This will hold the configuration.
local config = wezterm.config_builder()

-- my coolnight colorscheme
config.colors = {
        foreground = "#CDD6F4",
        background = "#0E0D16",
        cursor_bg = "#F5E0DC",
        cursor_border = "#F5E0DC",
        cursor_fg = "#1E1E2E",
        selection_bg = "#F5E0DC",
        selection_fg = "#1E1E2E",
        ansi = { "#121212", "#a52aff", "#7129ff", "#3d2aff", "#2b4fff", "#2883ff", "#28b9ff", "#f1f1f1" },
        brights = { "#666666", "#ba5aff", "#905aff", "#8f00ff", "#5c78ff", "#5ea2ff", "#5ac8ff", "#ffffff" },
}

config.font = wezterm.font("jetbrains mono nerd font")
config.font_size = 17

config.enable_tab_bar = false

config.window_decorations = "RESIZE"
config.window_background_opacity = 0.9
config.macos_window_background_blur = 10

config.window_padding = {
  left = 5,
  right = 5,
  top = 1,
  bottom = "0.3cell"
}

-- and finally, return the configuration to wezterm
return config

