local neotree_helper = require("mzawisa.custom.neotree")
return {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
        "MunifTanjim/nui.nvim",
    },
    config = function()
        require("neo-tree").setup({
            close_if_last_window = true,
            popup_border_style = "rounded",
            -- when opening files, do not use windows containing these filetypes or buftypes
            open_files_do_not_replace_types = { "terminal", "trouble", "qf", "grapple" },
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
                {
                    event = "neo_tree_window_after_close",
                    handler = function(_)
                        if neotree_helper.pinned() then
                            neotree_helper.unpin()
                        end
                    end,
                },
            },
            window = {
                position = "left",
            },
            filesystem = {
                follow_current_file = {
                    enabled = true,
                    leave_dirs_open = false,
                },
                bind_to_cwd = false,
                filtered_items = {
                    visible = true,
                },
                hijack_netrw_behavior = "open_current",
                components = {
                    grapple_index = function(config, node, _)
                        local ok, grapple = pcall(require, "grapple")
                        if not ok then
                            return {}
                        end

                        local path = node:get_id()
                        local tags = grapple.tags()

                        for i, tag in ipairs(tags) do
                            if tag.path == path then
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
                        ---@diagnostic disable-next-line: assign-type-mismatch
                        { "grapple_index" },
                        { "diagnostics" },
                        { "git_status", highlight = "NeoTreeDimText" },
                    },
                },
            },
        })
    end,
    keys = {
        {
            "<leader>e",
            function()
                require("neo-tree.command").execute({ action = "focus", position = "left" })
            end,
            desc = "Neotree: Open",
        },
        {
            "<leader>E",
            function()
                neotree_helper.pin()
                require("neo-tree.command").execute({ action = "focus", position = "left" })
            end,
            desc = "Neotree: Open and Pin",
        },
    },
}
