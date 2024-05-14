local wezterm = require("wezterm")
local tabs = require("mzawisa.tabs")
local keys = require("mzawisa.keys")
local workspaces = require("mzawisa.workspaces")
local act = wezterm.action

local status, private_workspaces = pcall(require, "private.workspaces")
if not status then
    private_workspaces = {}
end

local config = wezterm.config_builder()

workspaces.setup(private_workspaces)
tabs.setup(config)

config.default_prog = { "zsh" }
if wezterm.target_triple == "x86_64-pc-windows-msvc" then
    config.default_prog = { "C:/Users/MZawisa/AppData/Local/Programs/Git/bin/bash.exe", "--login", "-i" }
    config.launch_menu = {
        {
            label = "Git Bash",
            domain = { DomainName = "local" },
        },
        {
            label = "PowerShell",
            domain = { DomainName = "local" },
            args = { "powershell.exe" },
        },
        {
            label = "Command Prompt",
            domain = { DomainName = "local" },
            args = { "cmd.exe" },
        },
    }
end

config.audible_bell = "Disabled"

config.color_scheme = "Catppuccin Mocha"
config.window_background_opacity = 0.85

config.font = wezterm.font_with_fallback({ "Monaspace Neon", "FiraCode Nerd Font Mono" })
config.harfbuzz_features = {
    "calt", -- Contextual Alternates (texture healing)
    "clig", -- Contextual Ligatures
    "liga",
    "ss01",
    "ss02",
    "ss03",
    "ss04",
    "ss05", -- Functional Programming Ligatures (F#)
    "ss06",
    "ss07",
    "ss08",
    "ss09",
}
config.font_size = 14.0
local TIME_limit = false
if TIME_limit then
    config.font_size = 12.0
end
config.adjust_window_size_when_changing_font_size = false

keys.setup(config)

return config
