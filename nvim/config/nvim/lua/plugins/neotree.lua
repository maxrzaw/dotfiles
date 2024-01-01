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
            bind_to_cwd = false,
            filtered_items = {
                visible = true,
            },
            hijack_netrw_behavior = "open_current",
            components = {
                harpoon_index = function(config, node, _)
                    local harpoon_list = require("harpoon"):list("relative")
                    local path = node:get_id()

                    for i, item in ipairs(harpoon_list.items) do
                        local value = item.value

                        if value == path then
                            return {
                                text = string.format("->%d", i),
                                highlight = config.highlight or "NeoTreeDirectoryIcon",
                            }
                        end
                    end
                    return {}
                end,
            },
            renderers = {
                file = {
                    { "icon" },
                    { "name", use_git_status_colors = true },
                    { "harpoon_index" },
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
