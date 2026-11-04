local wezterm = require("wezterm")

local config = wezterm.config_builder()

config.default_domain = "WSL:NixOS"
config.default_cwd = os.getenv("HOME")

config.window_background_opacity = 0.9
config.font = wezterm.font("FiraCode Nerd Font")
config.font_size = 14.0

config.window_padding = {
	left = 0,
	right = 0,
	top = 0,
	bottom = 0,
}

config.hide_tab_bar_if_only_one_tab = true
config.use_fancy_tab_bar = false

config.window_decorations = "NONE | RESIZE"

config.color_scheme = "Catppuccin Mocha"

config.colors = {
	background = "#0c0b0f"
}

return config
