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
        },
        cond = not vim.g.vscode,
        config = function()
            local telescope = require("telescope")
            local builtin = require("telescope.builtin")
            local keymap = require("mzawisa.keymap")
            local nnoremap = keymap.nnoremap

            telescope.setup({
                defaults = {
                    layout_config = { width = 0.95 },
                    path_display = { "smart" },
                    file_ignore_patterns = { "node_modules", ".git" },
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
            end, { noremap = true, silent = true })
            vim.keymap.set("n", "<leader>fgf", builtin.git_files, { noremap = true, silent = true })
            vim.keymap.set("n", "<leader>fr", builtin.oldfiles, { noremap = true, silent = true })
            vim.keymap.set("n", "<leader>fg", builtin.live_grep, { noremap = true, silent = true })
            vim.keymap.set("n", "<leader>fb", builtin.buffers, { noremap = true, silent = true })
            vim.keymap.set("n", "<leader>fh", builtin.help_tags, { noremap = true, silent = true })
            vim.keymap.set("n", "<leader>fgs", builtin.git_status, { noremap = true, silent = true })
            vim.keymap.set("n", "<leader>fgb", builtin.git_branches, { noremap = true, silent = true })
            vim.keymap.set("n", "<leader>fgc", builtin.git_commits, { noremap = true, silent = true })
            vim.keymap.set("n", "<leader>fq", builtin.quickfix, { noremap = true, silent = true })
            vim.keymap.set("n", "<leader>fj", builtin.jumplist, { noremap = true, silent = true })
            vim.keymap.set("n", "<leader>fk", builtin.keymaps, { noremap = true, silent = true })
        end,
    },
}
