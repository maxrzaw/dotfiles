require("mzawisa")
-- Bootstrap Lazy
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
local is_work = os.getenv("NEOVIM_WORK")
local not_vscode = not vim.g.vscode

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
    {
        "folke/tokyonight.nvim",
        name = "Tokyo Night",
        lazy = false, -- make sure we load this during startup if it is your main colorscheme
        priority = 1000, -- make sure to load this before all the other start plugins
        config = function()
            -- load the colorscheme here
            require("mzawisa.plugins.tokyonight").setup()
        end,
        cond = not_vscode,
    },
    {
        "jose-elias-alvarez/null-ls.nvim",
        name = "null-ls",
        dependencies = {
            "MunifTanjim/prettier.nvim",
        },
        cond = not_vscode,
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
        cond = not_vscode,
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
        cond = not_vscode,
    },
    {
        "ckipp01/stylua-nvim",
        cond = not_vscode,
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
        cond = not_vscode,
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
        cond = not_vscode,
    },

    -- Useful status updates for LSP
    {
        "j-hui/fidget.nvim",
        name = "Fidget",
        version = "legacy",
        config = function()
            require("mzawisa.plugins.fidget")
        end,
        cond = not_vscode,
    },
    {
        "folke/trouble.nvim",
        name = "Trouble",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        config = function()
            require("mzawisa.plugins.trouble")
        end,
        cond = not_vscode,
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
        cond = not_vscode,
    },
    {
        "nvim-lualine/lualine.nvim",
        name = "Lualine",
        dependencies = { "nvim-tree/nvim-web-devicons", lazy = true },
        config = function()
            require("mzawisa.plugins.lualine")
        end,
        cond = not_vscode,
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
        },
        config = function()
            require("mzawisa.plugins.telescope")
        end,
        cond = not_vscode,
    },
    {
        "ThePrimeagen/harpoon",
        name = "Harpoon",
        dependencies = { "nvim-lua/plenary.nvim" },
        config = function()
            require("mzawisa.plugins.harpoon")
        end,
        cond = not_vscode,
    },
    {
        "voldikss/vim-floaterm",
        name = "Floaterm",
        config = function()
            require("mzawisa.plugins.floaterm")
        end,
        cond = not_vscode,
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
        cond = not_vscode,
    },
    {
        "NeogitOrg/neogit",
        name = "Neogit",
        dependencies = { "nvim-lua/plenary.nvim" },
        config = function()
            require("mzawisa.plugins.git")
        end,
        cond = not_vscode,
    },
    {
        "kdheepak/lazygit.nvim",
        name = "Lazy Git",
        -- optional for floating window border decoration
        dependencies = {
            { "nvim-lua/plenary.nvim" },
        },
        cond = not_vscode,
    },
})
