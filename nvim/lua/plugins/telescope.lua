local get_opts = require("mzawisa.keymap").get_opts
return {
    {
        "nvim-telescope/telescope.nvim",
        version = "0.1.x",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "benfowler/telescope-luasnip.nvim",
            -- Fuzzy Finder Algorithm which requires local dependencies to be built. Only load if `make` is available
            { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
            { "nvim-telescope/telescope-ui-select.nvim" },
            { "folke/trouble.nvim" },
        },
        cond = not vim.g.vscode,
        config = function()
            local builtin = require("telescope.builtin")
            local actions = require("telescope.actions")
            local transform_mod = require("telescope.actions.mt").transform_mod
            local trouble = require("trouble.providers.telescope")

            local open_quickfix_with_trouble = transform_mod({
                x = function(_)
                    print("open quickfix with trouble called")
                    require("trouble").open("quickfix")
                end,
            })

            local telescope = require("telescope")
            telescope.setup({
                defaults = {
                    layout_config = { width = 0.95 },
                    path_display = { "smart" },
                    file_ignore_patterns = { "node_modules", ".git" },
                    mappings = {
                        i = {
                            ["<C-t>"] = trouble.open_with_trouble,
                            ["<C-q>"] = function(prompt_bufnr)
                                actions.send_to_qflist(prompt_bufnr)
                                print("open quickfix with trouble called")
                                require("trouble").open("quickfix")
                            end,
                        },
                        n = {
                            ["<C-t>"] = trouble.open_with_trouble,
                            ["<C-q>"] = function(prompt_bufnr)
                                actions.send_to_qflist(prompt_bufnr)
                                print("open quickfix with trouble called")
                                require("trouble").open("quickfix")
                            end,
                        },
                    },
                },
                pickers = {
                    diagnostics = {
                        theme = "ivy",
                        path_display = "hidden",
                    },
                    lsp_definitions = {
                        theme = "ivy",
                    },
                    lsp_type_definitions = {
                        theme = "ivy",
                    },
                    lsp_references = {
                        theme = "ivy",
                        -- shorten_path = false,
                    },
                },
            })

            telescope.load_extension("luasnip")
            telescope.load_extension("lazygit")
            telescope.load_extension("ui-select")

            vim.keymap.set("n", "<leader>ff", function()
                builtin.find_files({ hidden = true })
            end, get_opts("Telescope Find Files"))
            vim.keymap.set("n", "<leader>fgf", builtin.git_files, get_opts("Telescope Git Files"))
            vim.keymap.set("n", "<leader>fr", builtin.oldfiles, get_opts("Telescope Old Files"))
            vim.keymap.set("n", "<leader>fg", builtin.live_grep, get_opts("Telescope Live Grep"))
            vim.keymap.set("n", "<leader>fb", builtin.buffers, get_opts("Telescope Buffers"))
            vim.keymap.set("n", "<leader>fh", builtin.help_tags, get_opts("Telescope Help Tags"))
            vim.keymap.set("n", "<leader>fgs", builtin.git_status, get_opts("Telescope Git Status"))
            vim.keymap.set("n", "<leader>fgb", builtin.git_branches, get_opts("Telescope Git Branches"))
            vim.keymap.set("n", "<leader>fgc", builtin.git_commits, get_opts("Telescope Git Commits"))
            vim.keymap.set("n", "<leader>fq", builtin.quickfix, get_opts("Telescope Quickfix"))
            vim.keymap.set("n", "<leader>fj", builtin.jumplist, get_opts("Telescope Jumplist"))
            vim.keymap.set("n", "<leader>fk", builtin.keymaps, get_opts("Telescope Keymaps"))
        end,
    },
}
