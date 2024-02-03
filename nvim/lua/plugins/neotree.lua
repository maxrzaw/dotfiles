local neotree_helper = require("mzawisa.custom.neotree")
return {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
        "MunifTanjim/nui.nvim",
    },
    opts = {
        close_if_last_window = true,
        popup_border_style = "rounded",
        event_handlers = {
            {
                event = "file_opened",
                handler = function(_)
                    if not neotree_helper.pinned() then
                        require("neo-tree.command").execute({ action = "close" })
                    end
                end,
            },
            {
                event = "neo_tree_buffer_enter",
                handler = function(_)
                    vim.opt_local.relativenumber = true
                end,
            },
        },
        window = {
            position = "left",
        },
        filesystem = {
            bind_to_cwd = false,
            filtered_items = {
                visible = true,
            },
            hijack_netrw_behavior = "open_current",
            components = {
                harpoon_index = function(config, node, _)
                    local harpoon_list = require("harpoon"):list()
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
                require("neo-tree.command").execute({ action = "focus", position = "left" })
            end,
            desc = "Neotree Open",
        },
        {
            "<leader>E",
            function()
                neotree_helper.pin()
                require("neo-tree.command").execute({ action = "focus", position = "left" })
            end,
            desc = "Neotree Open and Pin",
        },
        {
            "q",
            function()
                neotree_helper.unpin()
                require("neo-tree.command").execute({ action = "close" })
            end,
            ft = { "neo-tree" },
            desc = "Neotree Close",
        },
    },
}
