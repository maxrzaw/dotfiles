local wezterm = require("wezterm")
local M = {}
local catppuccin = require("mzawisa.colorscheme")
local mocha = catppuccin.select(catppuccin.colors, "mocha", "mauve").tab_bar

local utf8 = require("utf8")
local SOLID_LEFT_ARROW = utf8.char(0xe0ba)
local SOLID_LEFT_MOST = utf8.char(0x2588)
local SOLID_RIGHT_ARROW = utf8.char(0xe0bc)
local WSL_ICON = utf8.char(0xebc6)
local VIM_ICON = utf8.char(0xe62b)
local SERVER_ICON = utf8.char(0xf01c5)
local TEST_ICON = utf8.char(0xea79)
local PLUS_ICON = utf8.char(0xf44d)

local TAB_BAR_BG = mocha.background
local ACTIVE_TAB_BG = mocha.active_tab.bg_color
local ACTIVE_TAB_FG = mocha.active_tab.fg_color
local HOVER_TAB_BG = mocha.new_tab.bg_color
local HOVER_TAB_FG = mocha.new_tab.fg_color
local NORMAL_TAB_BG = mocha.inactive_tab_hover.bg_color
local NORMAL_TAB_FG = mocha.inactive_tab_hover.fg_color

-- This function returns the suggested title for a tab.
-- It prefers the title that was set via `tab:set_title()`
-- or `wezterm cli set-tab-title`, but falls back to the
-- title of the active pane in that tab.
local tab_title = function(tab_info)
    local title = tab_info.tab_title
    -- if the tab title is explicitly set, take that
    if title and #title > 0 then
        return title
    end
    -- Otherwise, use the title from the active pane
    -- in that tab
    return tab_info.active_pane.title
end

local icon_title = function(title)
    local lower = string.lower(title)
    if lower:match("vim") then
        return VIM_ICON .. " " .. "Vim"
    elseif lower:match("serve") then
        return SERVER_ICON .. " " .. "Server"
    elseif lower:match("test") then
        return TEST_ICON .. " " .. "Tests"
    elseif lower:match("wsl") then
        return WSL_ICON .. " " .. title
    end
    return nil
end

wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
    local edge_background = TAB_BAR_BG
    local background = NORMAL_TAB_BG
    local foreground = NORMAL_TAB_FG

    if tab.is_active then
        background = ACTIVE_TAB_BG
        foreground = ACTIVE_TAB_FG
    elseif hover then
        background = HOVER_TAB_BG
        foreground = HOVER_TAB_FG
    end

    local edge_foreground = background

    local t_title = tab_title(tab)
    local i_title = icon_title(t_title)
    local title = i_title or t_title

    -- ensure that the titles fit in the available space,
    -- and that we have room for the edges.
    title = " " .. wezterm.truncate_right(title, max_width - 2) .. " "

    local is_first = tab.tab_id == tabs[1].tab_id
    local left_edge = is_first and SOLID_LEFT_MOST or SOLID_LEFT_ARROW
    return {
        { Attribute = { Intensity = "Bold" } },
        { Background = { Color = edge_background } },
        { Foreground = { Color = edge_foreground } },
        { Text = left_edge },
        { Background = { Color = background } },
        { Foreground = { Color = foreground } },
        { Text = title },
        { Background = { Color = edge_background } },
        { Foreground = { Color = edge_foreground } },
        { Text = SOLID_RIGHT_ARROW },
        { Attribute = { Intensity = "Normal" } },
    }
end)

M.setup = function(config)
    wezterm.log_info(wezterm.color.get_builtin_schemes()["Catppuccin Mocha"])
    -- Tab Bar
    config.use_fancy_tab_bar = false
    config.tab_bar_at_bottom = false
    config.enable_scroll_bar = true
    config.window_padding = {
        left = 0,
        right = "0.5cell",
        top = 0,
        bottom = 0,
    }
    config.window_decorations = "RESIZE"
    config.tab_max_width = 52
    config.tab_bar_style = {
        new_tab = wezterm.format({
            { Attribute = { Intensity = "Bold" } },
            { Background = { Color = TAB_BAR_BG } },
            { Foreground = { Color = NORMAL_TAB_BG } },
            { Text = SOLID_LEFT_ARROW },
            { Background = { Color = NORMAL_TAB_BG } },
            { Foreground = { Color = NORMAL_TAB_FG } },
            { Text = " " .. PLUS_ICON .. " " },
            { Background = { Color = TAB_BAR_BG } },
            { Foreground = { Color = NORMAL_TAB_BG } },
            { Text = SOLID_RIGHT_ARROW },
            { Attribute = { Intensity = "Normal" } },
        }),
        new_tab_hover = wezterm.format({
            { Attribute = { Intensity = "Bold" } },
            { Background = { Color = TAB_BAR_BG } },
            { Foreground = { Color = HOVER_TAB_BG } },
            { Text = SOLID_LEFT_ARROW },
            { Background = { Color = HOVER_TAB_BG } },
            { Foreground = { Color = HOVER_TAB_FG } },
            { Text = " " .. PLUS_ICON .. " " },
            { Background = { Color = TAB_BAR_BG } },
            { Foreground = { Color = HOVER_TAB_BG } },
            { Text = SOLID_RIGHT_ARROW },
            { Attribute = { Intensity = "Normal" } },
        }),
    }
end

return M
