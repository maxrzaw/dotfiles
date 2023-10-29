local helper = require("mzawisa.custom.neotree")
return {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
        "MunifTanjim/nui.nvim",
    },
    opts = {
        popup_border_style = "rounded",
        event_handlers = {
            {
                event = "neo_tree_window_after_close",
                handler = function(_)
                    helper.unpin()
                end,
            },
            {
                event = "file_opened",
                handler = function(_)
                    if not helper.pinned() then
                        require("neo-tree.command").execute({ action = "close" })
                    end
                end,
            },
        },
        window = {
            position = "current",
        },
        filesystem = {
            filtered_items = {
                visible = true,
            },
            hijack_netrw_behavior = "open_current",
            components = {
                harpoon_index = function(config, node, _)
                    local Marked = require("harpoon.mark")
                    local path = node:get_id()
                    local succuss, index = pcall(Marked.get_index_of, path)
                    if succuss and index and index > 0 then
                        return {
                            text = string.format("  %d", index), -- <-- Add your favorite harpoon like arrow here
                            highlight = config.highlight or "NeoTreeDirectoryIcon",
                        }
                    else
                        return {}
                    end
                end,
            },
            renderers = {
                file = {
                    { "icon" },
                    { "name", use_git_status_colors = true },
                    { "harpoon_index" }, --> This is what actually adds the component in where you want it
                    { "diagnostics" },
                    { "git_status", highlight = "NeoTreeDimText" },
                },
            },
        },
    },
    keys = {
        {
            "<leader>e",
            function()
                if helper.pinned() then
                    vim.cmd("Neotree left")
                else
                    vim.cmd("Neotree current %:p:h")
                end
            end,
            desc = "Neotree",
        },
        {
            "<leader>E",
            function()
                helper.pin()
                vim.cmd("Neotree left")
            end,
            desc = "Neotree left",
        },
    },
}
