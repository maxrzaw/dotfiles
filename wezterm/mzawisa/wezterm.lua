local wezterm = require("wezterm")
local tabs = require("mzawisa.tabs")
local workspaces = require("mzawisa.workspaces")
local private_workspaces = require("private.workspaces")
local act = wezterm.action

local config = wezterm.config_builder()

workspaces.setup(private_workspaces)
tabs.setup(config)

config.default_prog = { "zsh" }

config.audible_bell = "Disabled"

config.color_scheme = "Catppuccin Mocha"
config.window_background_opacity = 0.85
config.font = wezterm.font("FiraCode Nerd Font Mono")
config.font_size = 14.0

-- Disable default key bindings that interfere with my software keymap
config.keys = {
    { key = "!", mods = "CTRL", action = act.DisableDefaultAssignment },
    { key = "#", mods = "CTRL", action = act.DisableDefaultAssignment },
    { key = "$", mods = "CTRL", action = act.DisableDefaultAssignment },
    { key = "%", mods = "CTRL", action = act.DisableDefaultAssignment },
    { key = "&", mods = "CTRL", action = act.DisableDefaultAssignment },
    { key = "(", mods = "CTRL", action = act.DisableDefaultAssignment },
    { key = ")", mods = "CTRL", action = act.DisableDefaultAssignment },
    { key = "*", mods = "CTRL", action = act.DisableDefaultAssignment },
    { key = "@", mods = "CTRL", action = act.DisableDefaultAssignment },
    { key = "^", mods = "CTRL", action = act.DisableDefaultAssignment },
}

return config
