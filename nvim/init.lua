require("mzawisa.set")
require("mzawisa.autocmds")
require("mzawisa.remaps")
local get_opts = require("mzawisa.keymap").get_opts

-- Bootstrap Lazy
vim.g.is_work = os.getenv("NEOVIM_WORK")
vim.g.is_pi = os.getenv("NEOVIM_PI")

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable", -- latest stable release
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

-- Set Up Plugins
require("lazy").setup({
    dev = {
        path = "~/dev",
        patterns = { "mzawisa", "maxrzaw", "https://gitlab.com/schrieveslaach" },
        fallback = true,
    },
    ui = {
        border = "rounded",
        title = " Lazy ",
    },
    spec = {
        { "lazy.nvim" },
        { import = "plugins" },
        {
            "folke/neodev.nvim",
            opts = {
                library = { plugins = { "neotest" }, types = true },
            },
        },
        {
            "catppuccin/nvim",
            name = "Catppuccin",
            lazy = false, -- make sure we load this during startup if it is your main colorscheme
            priority = 1000, -- make sure to load this before all the other start plugins
            config = function()
                require("catppuccin").setup({
                    flavour = "mocha",
                    transparent_background = true,
                    term_colors = true,
                    integrations = {
                        alpha = true,
                        cmp = true,
                        dap = {
                            enabled = true,
                            enable_ui = true,
                        },
                        fidget = true,
                        gitsigns = true,
                        harpoon = true,
                        lsp_trouble = true,
                        mason = true,
                        neogit = true,
                        neotree = true,
                        neotest = true,
                        telescope = true,
                        treesitter = true,
                    },
                    custom_highlights = function(mocha)
                        return {
                            LineNr = { fg = mocha.overlay1 },
                            NeoTreeDotfile = { fg = mocha.subtext0 },
                            NeoTreeFileStats = { fg = mocha.overlay2 },
                            NeoTreeMessage = { fg = mocha.overlay2 },
                        }
                    end,
                })
                vim.cmd.colorscheme("catppuccin")
            end,
            cond = not vim.g.vscode,
        },
        {
            "nvimtools/none-ls.nvim",
            build = "npm install -g markdownlint-cli @fsouza/prettierd && curl -sSfL https://raw.githubusercontent.com/dotenv-linter/dotenv-linter/master/install.sh | sh -s",
            config = function()
                local null_ls = require("null-ls")
                null_ls.setup({
                    sources = {
                        null_ls.builtins.code_actions.refactoring,
                        null_ls.builtins.formatting.prettier,
                        -- null_ls.builtins.formatting.trim_whitespace, -- Causing a problem for markdown
                        null_ls.builtins.diagnostics.commitlint,
                        null_ls.builtins.diagnostics.todo_comments,
                        null_ls.builtins.diagnostics.dotenv_linter,
                        null_ls.builtins.diagnostics.markdownlint,
                        null_ls.builtins.hover.printenv,
                        null_ls.builtins.hover.dictionary,
                    },
                })
            end,
            dependencies = {
                "nvim-lua/plenary.nvim",
            },
            cond = not vim.g.vscode,
        },
        "tpope/vim-surround",
        {
            "hrsh7th/nvim-cmp",
            name = "nvim-cmp",
            dependencies = {
                "doxnit/cmp-luasnip-choice",
                "hrsh7th/cmp-buffer",
                "hrsh7th/cmp-nvim-lsp",
                "hrsh7th/cmp-nvim-lsp-signature-help",
                "hrsh7th/cmp-nvim-lua",
                "hrsh7th/cmp-path",
                "onsails/lspkind.nvim",
                "saadparwaiz1/cmp_luasnip",
                { "petertriho/cmp-git", dependencies = { "nvim-lua/plenary.nvim" } },
            },
            config = function()
                require("mzawisa.plugins.cmp")
            end,
            cond = not vim.g.vscode,
        },
        {
            "https://gitlab.com/mzawisa/sonarlint.nvim",
            name = "sonarlint.nvim",
            branch = "show-rule-description-as-preview",
            dev = true,
            cond = vim.g.is_work and not vim.g.vscode,
            dependencies = {
                "mfussenegger/nvim-jdtls",
                cond = vim.g.is_work and not vim.g.vscode,
            },
        },
        -- Snippets
        {
            "L3MON4D3/LuaSnip",
            name = "LuaSnip",
            dependencies = {
                "rafamadriz/friendly-snippets",
            },
            config = function()
                require("mzawisa.plugins.luasnip")
            end,
            cond = not vim.g.vscode,
        },

        -- Useful status updates for LSP
        {
            "j-hui/fidget.nvim",
            name = "Fidget",
            tag = "legacy",
            opts = {
                window = {
                    border = "rounded",
                    blend = 0,
                },
            },
            cond = not vim.g.vscode,
        },
        {
            "folke/trouble.nvim",
            name = "Trouble",
            dependencies = { "nvim-tree/nvim-web-devicons" },
            config = function()
                require("trouble").setup({
                    auto_close = true,
                    action_keys = {
                        toggle_fold = { "<leader>z", "<leader>Z" },
                    },
                    height = 15,
                    auto_jump = {
                        "lsp_definitions",
                        "lsp_type_definitions",
                        -- "lsp_references", -- This appears to be broken
                    },
                })
                vim.keymap.set("n", "<leader>qq", "<cmd>TroubleToggle<cr>", get_opts("Toggle Trouble"))
            end,
            cond = not vim.g.vscode,
        },
        {
            "mbbill/undotree", -- ability to browse file history tree
            name = "Undo Tree",
            config = function()
                vim.keymap.set("n", "<leader>u", vim.cmd.UndotreeToggle, { silent = true, noremap = true })
            end,
            cond = not vim.g.vscode,
        },
        {
            "voldikss/vim-floaterm",
            name = "Floaterm",
            config = function()
                vim.g.floaterm_title = ""
                -- Terminal Mode
                vim.keymap.set({ "t", "n" }, "<C-T>", "<cmd>FloatermToggle<cr>", { noremap = true, silent = true })
                vim.g.floaterm_width = 0.9
                vim.g.floaterm_height = 0.9
            end,
            cond = not vim.g.vscode,
        },
        {
            "iamcco/markdown-preview.nvim",
            name = "Markdown Preview",
            build = "cd app && npm install && git restore .",
            init = function()
                vim.g.mkdp_filetypes = { "markdown" }
            end,
            ft = { "markdown" },
            config = function()
                require("mzawisa.plugins.markdown-preview")
            end,
            cond = not vim.g.vscode,
        },
        {
            dir = "~/dev/azdo.nvim",
            config = function()
                require("azdo").setup({})
            end,
            cond = not vim.g.is_pi,
        },
        {
            "2kabhishek/nerdy.nvim",
            dependencies = {
                "nvim-telescope/telescope.nvim",
                "stevearc/dressing.nvim",
            },
            cmd = "Nerdy",
        },
    },
})
