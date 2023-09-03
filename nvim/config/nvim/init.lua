require("mzawisa")
-- Bootstrap Lazy
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
vim.g.is_work = os.getenv("NEOVIM_WORK")
vim.g.is_pi = os.getenv("NEOVIM_PI")

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
    { "lazy.nvim" },
    { import = "mzawisa.plugins.alpha" },
    {
        "catppuccin/nvim",
        name = "Catppuccin",
        lazy = false, -- make sure we load this during startup if it is your main colorscheme
        priority = 1000, -- make sure to load this before all the other start plugins
        opts = {
            transparent_background = true,
            integrations = {
                telescope = true,
                harpoon = true,
                mason = true,
                cmp = true,
                fidget = true,
                neogit = true,
                treesitter = true,
                lsp_trouble = true,
            },
        },
        config = function(_, opts)
            require("catppuccin").setup(opts)
            vim.cmd.colorscheme("catppuccin-mocha")
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
        "jose-elias-alvarez/null-ls.nvim",
        name = "null-ls",
        dependencies = {
            "MunifTanjim/prettier.nvim",
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
            "Mason",
            -- Null Language Server
            "null-ls",
            -- Completion
            "nvim-cmp",
        },
        config = function()
            require("mzawisa.plugins.lspconfig")
        end,
        cond = not vim.g.vscode,
    },
    {
        "https://gitlab.com/maxzawisa/sonarlint.nvim",
        name = "sonarlint.nvim",
        branch = "fix-show-rule-description",
        cond = vim.g.is_work and not vim.g.vscode,
        dependencies = { "mfussenegger/nvim-jdtls", cond = vim.g.is_work and not vim.g.vscode },
    },
    {
        "ckipp01/stylua-nvim",
        cond = not vim.g.vscode,
        ft = { "lua" },
    },
    {
        "williamboman/mason.nvim",
        name = "Mason",
        dependencies = {
            "williamboman/mason-lspconfig.nvim",
        },
        config = function()
            require("mzawisa.plugins.mason")
        end,
        cond = not vim.g.vscode,
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
        dependencies = { "nvim-treesitter", "LuaSnip" },
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
        name = "nvim-treesitter",
        build = function()
            require("nvim-treesitter.install").update({ with_sync = true })
        end,
        config = function()
            require("mzawisa.plugins.treesitter")
        end,
    },
    {
        "nvim-telescope/telescope.nvim",
        name = "Telescope",
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
        build = "cd app && npm install",
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
        "kdheepak/lazygit.nvim",
        name = "Lazy Git",
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
})
