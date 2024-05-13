local wezterm = require("wezterm")
local M = {}
local catppuccin = require("mzawisa.colorscheme")
local utils = require("mzawisa.utils")
local tab_bar_colors = catppuccin.select(catppuccin.colors, "mocha", "mauve").tab_bar
local mocha = catppuccin.colors.mocha

local utf8 = require("utf8")
local TMUX_ICON = utf8.char(0xebc8)
local SOLID_LEFT_SLANT = utf8.char(0xe0ba)
local SOLID_RIGHT_SLANT = utf8.char(0xe0bc)
local LEFT_ARROW = utf8.char(0xe0b3)
local SOLID_LEFT_ARROW = utf8.char(0xe0b2)
local SOLID_LEFT_CIRCLE = utf8.char(0xe0b6)
local WSL_ICON = utf8.char(0xebc6)
local VIM_ICON = utf8.char(0xe6ae)
local SERVER_ICON = utf8.char(0xf01c5)
local TEST_ICON = utf8.char(0xea79)
local PLUS_ICON = utf8.char(0xf44d)
local WINDOWS_ICON = utf8.char(0xe62a)
local CMD_ICON = utf8.char(0xebc4)
local GIT_ICON = utf8.char(0xf02a2)

local TAB_BAR_BG = tab_bar_colors.background
local ACTIVE_TAB_BG = tab_bar_colors.active_tab.bg_color
local ACTIVE_TAB_FG = tab_bar_colors.active_tab.fg_color
local HOVER_TAB_BG = tab_bar_colors.new_tab.bg_color
local HOVER_TAB_FG = tab_bar_colors.new_tab.fg_color
local NORMAL_TAB_BG = tab_bar_colors.inactive_tab_hover.bg_color
local NORMAL_TAB_FG = tab_bar_colors.inactive_tab_hover.fg_color

local COLOR_WHEEL = {
    mocha.mauve,
    mocha.green,
    mocha.yellow,
    mocha.blue,
    mocha.teal,
    mocha.peach,
}

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
    title = tab_info.active_pane.title
    local basename = utils.basename(title)
    if basename:match(".exe") then
        return basename:gsub(".exe", "")
    end
    return title
end

local icon_title = function(title)
    local lower = string.lower(title)
    if lower:match("vim") then
        return VIM_ICON .. " " .. "Vim"
    elseif lower:match("serve") then
        return SERVER_ICON .. " " .. "Server"
    elseif lower:match("test") then
        return TEST_ICON .. " " .. "Tests"
    end
    return nil
end

local domain_icon_prefix = function(tab_id)
    local mux_tab = wezterm.mux.get_tab(tab_id)
    local mux_pane = mux_tab:active_pane()
    local domain_name = mux_pane:get_domain_name()
    if domain_name:match("WSL") then
        return " " .. WSL_ICON .. ": "
    elseif wezterm.target_triple == "x86_64-pc-windows-msvc" then
        return " " .. WINDOWS_ICON .. ": "
    else
        return " "
    end
end

wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
    wezterm.log_info("max_width: " .. max_width)
    local domain_icon = domain_icon_prefix(tab.tab_id)
    local process_name = tab.active_pane.foreground_process_name
    -- wezterm.log_info("Process Name: " .. process_name)

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
    local title = domain_icon .. (icon_title(t_title) or t_title)

    -- ensure that the titles fit in the available space,
    -- and that we have room for the right edge.
    title = wezterm.truncate_right(title, max_width - 1) .. " "

    return {
        { Attribute = { Intensity = "Bold" } },
        { Background = { Color = edge_background } },
        { Foreground = { Color = edge_foreground } },
        { Text = SOLID_LEFT_SLANT },
        { Background = { Color = background } },
        { Foreground = { Color = foreground } },
        { Text = title },
        { Background = { Color = edge_background } },
        { Foreground = { Color = edge_foreground } },
        { Text = SOLID_RIGHT_SLANT },
        { Attribute = { Intensity = "Normal" } },
    }
end)

wezterm.on("update-right-status", function(window, pane)
    -- Each element holds the text for a cell in a "powerline" style << fade
    local cells = {}

    -- Figure out the cwd and host of the current pane.
    -- This will pick up the hostname for the remote host if your
    -- shell is using OSC 7 on the remote host.
    local cwd_uri = pane:get_current_working_dir()
    if cwd_uri then
        local cwd = ""
        local hostname = ""

        if type(cwd_uri) == "userdata" then
            -- Running on a newer version of wezterm and we have
            -- a URL object here, making this simple!

            cwd = cwd_uri.file_path
            hostname = cwd_uri.host or wezterm.hostname()
        else
            -- an older version of wezterm, 20230712-072601-f4abf8fd or earlier,
            -- which doesn't have the Url object
            cwd_uri = cwd_uri:sub(8)
            local slash = cwd_uri:find("/")
            if slash then
                hostname = cwd_uri:sub(1, slash - 1)
                -- and extract the cwd from the uri, decoding %-encoding
                cwd = cwd_uri:sub(slash):gsub("%%(%x%x)", function(hex)
                    return string.char(tonumber(hex, 16))
                end)
            end
        end

        -- Remove the domain name portion of the hostname
        local dot = hostname:find("[.]")
        if dot then
            hostname = hostname:sub(1, dot - 1)
        end
        if hostname == "" then
            hostname = wezterm.hostname()
        end

        table.insert(cells, cwd)
        table.insert(cells, hostname)
    end

    -- I like my date/time in this style: "Wed Mar 3 08:14"
    local date = wezterm.strftime("%a %b %-d %H:%M")
    table.insert(cells, date)

    -- An entry for each battery (typically 0 or 1 battery)
    for _, b in ipairs(wezterm.battery_info()) do
        table.insert(cells, string.format("%.0f%%", b.state_of_charge * 100))
    end

    -- Color palette for the backgrounds of each cell
    local colors = {
        mocha.flamingo,
        mocha.blue,
        mocha.sky,
        mocha.pink,
        "#b491c8",
    }

    -- Foreground color for the text across the fade
    local text_fg = mocha.crust

    -- The elements to be formatted
    local elements = {}
    -- How many cells have been formatted
    local num_cells = 0

    -- Translate a cell into elements
    local function push(text, is_last, is_first)
        local cell_no = num_cells + 1
        if is_first then
            table.insert(elements, { Foreground = { Color = colors[cell_no] } })
            table.insert(elements, { Text = SOLID_LEFT_SLANT })
        end
        table.insert(elements, { Foreground = { Color = text_fg } })
        table.insert(elements, { Background = { Color = colors[cell_no] } })
        table.insert(elements, { Text = " " .. text .. " " })
        if not is_last then
            table.insert(elements, { Foreground = { Color = colors[cell_no + 1] } })
            table.insert(elements, { Text = SOLID_LEFT_SLANT })
        end
        num_cells = num_cells + 1
    end

    local is_first = true
    while #cells > 0 do
        local cell = table.remove(cells, 1)
        push(cell, #cells == 0, is_first)
        is_first = false
    end

    window:set_right_status(wezterm.format(elements))
end)

wezterm.on("update-status", function(window, pane)
    local workspace = " " .. TMUX_ICON .. " " .. window:active_workspace() .. " "
    window:set_left_status(wezterm.format({
        { Attribute = { Intensity = "Bold" } },
        { Background = { Color = mocha.blue } },
        { Foreground = { Color = mocha.crust } },
        { Text = workspace },
        { Background = { Color = mocha.crust } },
        { Foreground = { Color = mocha.blue } },
        { Text = SOLID_RIGHT_SLANT .. "  " },
        { Attribute = { Intensity = "Normal" } },
    }))
end)

M.setup = function(config)
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
    config.tab_max_width = 80
    config.tab_bar_style = {
        new_tab = wezterm.format({
            { Attribute = { Intensity = "Bold" } },
            { Background = { Color = TAB_BAR_BG } },
            { Foreground = { Color = NORMAL_TAB_BG } },
            { Text = SOLID_LEFT_SLANT },
            { Background = { Color = NORMAL_TAB_BG } },
            { Foreground = { Color = NORMAL_TAB_FG } },
            { Text = " " .. PLUS_ICON .. " " },
            { Background = { Color = TAB_BAR_BG } },
            { Foreground = { Color = NORMAL_TAB_BG } },
            { Text = SOLID_RIGHT_SLANT },
            { Attribute = { Intensity = "Normal" } },
        }),
        new_tab_hover = wezterm.format({
            { Attribute = { Intensity = "Bold" } },
            { Background = { Color = TAB_BAR_BG } },
            { Foreground = { Color = HOVER_TAB_BG } },
            { Text = SOLID_LEFT_SLANT },
            { Background = { Color = HOVER_TAB_BG } },
            { Foreground = { Color = HOVER_TAB_FG } },
            { Text = " " .. PLUS_ICON .. " " },
            { Background = { Color = TAB_BAR_BG } },
            { Foreground = { Color = HOVER_TAB_BG } },
            { Text = SOLID_RIGHT_SLANT },
            { Attribute = { Intensity = "Normal" } },
        }),
    }
end

return M
