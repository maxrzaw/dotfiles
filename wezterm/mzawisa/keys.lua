local act = require("wezterm").action
local M = {}

M.setup = function(config)
    config.leader = { key = "a", mods = "CTRL", timeout_milliseconds = 1000 }
    config.keys = {
        -- Disable default key bindings that interfere with my software keymap
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

        -- Tab Navigation
        { key = '!', mods = 'LEADER', action = act.ActivateTab(0) },
        { key = '1', mods = 'LEADER|SHIFT', action = act.ActivateTab(0) },
        { key = 'j', mods = 'LEADER', action = act.ActivateTab(0) },

        { key = '@', mods = 'LEADER', action = act.ActivateTab(1) },
        { key = '2', mods = 'LEADER|SHIFT', action = act.ActivateTab(1) },
        { key = 'k', mods = 'LEADER', action = act.ActivateTab(1) },

        { key = '#', mods = 'LEADER', action = act.ActivateTab(2) },
        { key = '3', mods = 'LEADER|SHIFT', action = act.ActivateTab(2) },
        { key = 'l', mods = 'LEADER', action = act.ActivateTab(2) },

        { key = '$', mods = 'LEADER', action = act.ActivateTab(3) },
        { key = '4', mods = 'LEADER|SHIFT', action = act.ActivateTab(3) },

        { key = '%', mods = 'LEADER', action = act.ActivateTab(4) },
        { key = '5', mods = 'LEADER|SHIFT', action = act.ActivateTab(4) },

        { key = '^', mods = 'LEADER', action = act.ActivateTab(5) },
        { key = '6', mods = 'LEADER|SHIFT', action = act.ActivateTab(5) },

        { key = '&', mods = 'LEADER', action = act.ActivateTab(6) },
        { key = '7', mods = 'LEADER|SHIFT', action = act.ActivateTab(6) },

        { key = '*', mods = 'LEADER', action = act.ActivateTab(7) },
        { key = '8', mods = 'LEADER|SHIFT', action = act.ActivateTab(7) },

        { key = '(', mods = 'LEADER', action = act.ActivateTab(8) },
        { key = '9', mods = 'LEADER|SHIFT', action = act.ActivateTab(8) },

        -- Workspace Navigation
        { key = 'n', mods = 'LEADER', action = act.SwitchToWorkspace { name = "nova" } },
        { key = 'd', mods = 'LEADER', action = act.SwitchToWorkspace { name = "default" } },
    }
end

return M
