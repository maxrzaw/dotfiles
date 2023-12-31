require("mzawisa")
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
            "folke/tokyonight.nvim",
            name = "Tokyo Night",
            lazy = false, -- make sure we load this during startup if it is your main colorscheme
            priority = 1000, -- make sure to load this before all the other start plugins
            config = function()
                -- load the colorscheme here
                require("mzawisa.plugins.tokyonight").my_setup()
            end,
            cond = false and not vim.g.vscode,
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
        "tpope/vim-fugitive",
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
            "neovim/nvim-lspconfig",
            dependencies = {
                -- Mason
                {
                    "williamboman/mason-lspconfig.nvim",
                    dependencies = {
                        "williamboman/mason.nvim",
                    },
                },
                -- Null Language Server
                "nvimtools/none-ls.nvim",
                -- Completion
                "nvim-cmp",
                -- OmniSharp Extended
                "Hoffs/omnisharp-extended-lsp.nvim",
            },
            build = "npm install -g @tailwindcss/language-server",
            config = function()
                require("mzawisa.plugins.lspconfig")
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
            config = function()
                require("mzawisa.plugins.fidget")
            end,
            cond = not vim.g.vscode,
        },
        {
            "folke/trouble.nvim",
            name = "Trouble",
            dependencies = { "nvim-tree/nvim-web-devicons" },
            config = function()
                require("mzawisa.plugins.trouble")
            end,
            cond = not vim.g.vscode,
        },

        -- Comments
        {
            "numToStr/Comment.nvim",
            name = "Comment",
            config = function()
                require("mzawisa.plugins.comment")
            end,
        },
        {
            "danymat/neogen",
            name = "Neogen",
            dependencies = { "nvim-treesitter/nvim-treesitter", "LuaSnip" },
            config = function()
                require("mzawisa.plugins.neogen")
            end,
            -- cond = not vanilla,
        },
        {
            "mbbill/undotree", -- ability to browse file history tree
            name = "Undo Tree",
            config = function()
                require("mzawisa.plugins.undotree")
            end,
            cond = not vim.g.vscode,
        },
        {
            "nvim-lualine/lualine.nvim",
            name = "Lualine",
            dependencies = { "nvim-tree/nvim-web-devicons", lazy = true },
            config = function()
                require("mzawisa.plugins.lualine")
            end,
            cond = not vim.g.vscode,
        },
        {
            "nvim-treesitter/nvim-treesitter",
            dependencies = {
                { "elgiano/nvim-treesitter-angular", branch = "topic/jsx-fix" },
                { "windwp/nvim-ts-autotag" },
            },
            build = function()
                require("nvim-treesitter.install").update({ with_sync = true })
            end,
            config = function()
                require("mzawisa.plugins.treesitter")
            end,
        },
        {
            "nvim-telescope/telescope.nvim",
            version = "0.1.x",
            dependencies = {
                "nvim-lua/plenary.nvim",
                "Harpoon",
                "benfowler/telescope-luasnip.nvim",
                -- Fuzzy Finder Algorithm which requires local dependencies to be built. Only load if `make` is available
                { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
                { "nvim-telescope/telescope-ui-select.nvim" },
            },
            config = function()
                require("mzawisa.plugins.telescope")
            end,
            cond = not vim.g.vscode,
        },
        {
            "nvim-telescope/telescope-file-browser.nvim",
            dependencies = { "nvim-telescope/telescope.nvim", "nvim-lua/plenary.nvim" },
            config = function()
                require("telescope").load_extension("file_browser")
            end,
            cond = not vim.g.vscode,
        },
        {
            "ThePrimeagen/harpoon",
            name = "Harpoon",
            dependencies = { "nvim-lua/plenary.nvim" },
            config = function()
                require("mzawisa.plugins.harpoon")
            end,
            cond = not vim.g.vscode,
        },
        {
            "voldikss/vim-floaterm",
            name = "Floaterm",
            config = function()
                require("mzawisa.plugins.floaterm")
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
            "NeogitOrg/neogit",
            name = "Neogit",
            dependencies = { "nvim-lua/plenary.nvim" },
            config = function()
                require("mzawisa.plugins.git")
            end,
            cond = not vim.g.vscode,
        },
        {
            "lewis6991/gitsigns.nvim",
            opts = {
                signcolumn = true,
                numhl = false,
                linehl = false,
                word_diff = false,
                current_line_blame = true,
                current_line_blame_opts = {
                    virt_text = true,
                    virt_text_pos = "eol",
                    ignore_whitespace = true,
                    delay = 2000,
                },
            },
            init = function()
                vim.api.nvim_set_keymap(
                    "n",
                    "<leader>gB",
                    "<cmd>lua require('gitsigns').blame_line({full = true})<cr>",
                    { noremap = true, silent = true, desc = "Gitsigns Show Full Line Blame" }
                )
            end,
        },
        {
            "kdheepak/lazygit.nvim",
            -- optional for floating window border decoration
            dependencies = {
                { "nvim-lua/plenary.nvim" },
            },
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
            "christoomey/vim-tmux-navigator",
            config = function()
                -- Turn off default tmux navigator mappings
                vim.g.tmux_navigator_no_mappings = 1
            end,
            keys = {
                { "<c-w><c-h>", "<cmd>TmuxNavigateLeft<cr>", mode = "n" },
                { "<c-w><c-j>", "<cmd>TmuxNavigateDown<cr>", mode = "n" },
                { "<c-w><c-k>", "<cmd>TmuxNavigateUp<cr>", mode = "n" },
                { "<c-w><c-l>", "<cmd>TmuxNavigateRight<cr>", mode = "n" },
            },
        },
        {
            "tmux-plugins/vim-tmux",
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
