local wezterm = require("wezterm")
local mux = wezterm.mux
local M = {}

M.setup = function(custom_workspaces)
    -- Allow for custom workspaces to be passed in
    custom_workspaces = custom_workspaces or {}

    local workspaces = {
        ["dotfiles"] = function()
            local dotfiles_tab, _, _ = mux.spawn_window({
                workspace = "dotfiles",
                cwd = wezterm.home_dir .. "/dotfiles",
                args = {},
            })
            dotfiles_tab:set_title("dotfiles")
        end,
        ["dev"] = function()
            local project_dir = wezterm.home_dir .. "/dev"

            local dev_tab, dev_pane, dev_window = mux.spawn_window({
                workspace = "dev",
                cwd = project_dir,
                args = {},
            })
            dev_tab:set_title("Vim")
            dev_pane:send_text("vim\n")

            local test_tab, test_pane, _ = dev_window:spawn_tab({
                cwd = project_dir,
                args = {},
            })
            test_tab:set_title("Tests")
            test_pane:send_text("echo 'testing...'\n")

            local server_tab, server_pane, _ = dev_window:spawn_tab({
                cwd = project_dir,
                args = {},
            })
            server_tab:set_title("Server")
            server_pane:send_text("echo 'Server...'\n")
        end,
    }

    for name, workspace in pairs(custom_workspaces) do
        workspaces[name] = workspace
    end

    wezterm.on("user-var-changed", function(_, _, name, value)
        if name == "user-workspace-command" then
            local workspace_name = value
            if workspace_name == "" then
                workspace_name = "default"
            end
            wezterm.log_info("Switching to workspace: '" .. workspace_name .. "'")

            local workspace_names = mux.get_workspace_names()
            local workspace_already_exists = false

            for _, w in pairs(workspace_names) do
                if w == workspace_name then
                    workspace_already_exists = true
                    break
                end
            end

            if workspace_already_exists then
                mux.set_active_workspace(workspace_name)
                return
            end

            if workspaces[workspace_name] ~= nil then
                workspaces[workspace_name]()
            else
                wezterm.log_warn("No config exists for workspace: '" .. workspace_name .. "'")
                mux.spawn_window({
                    workspace = workspace_name,
                    cwd = wezterm.home_dir,
                    args = {},
                })
            end

            workspace_names = mux.get_workspace_names()
            local workspace_exists = false

            for _, w in pairs(workspace_names) do
                if w == workspace_name then
                    workspace_exists = true
                    break
                end
            end

            if workspace_exists then
                mux.set_active_workspace(workspace_name)
            else
                wezterm.log_error("Failed to create workspace: '" .. workspace_name .. "'")
            end
        end
    end)
end

return M
