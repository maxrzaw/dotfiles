require("mzawisa")
-- Bootstrap Lazy
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
    {
        "folke/tokyonight.nvim",
        lazy = false, -- make sure we load this during startup if it is your main colorscheme
        priority = 1000, -- make sure to load this before all the other start plugins
        config = function()
            -- load the colorscheme here
            require("mzawisa.plugins.tokyonight").setup()
        end,
    },
    {
        "jose-elias-alvarez/null-ls.nvim",
        name = "null-ls",
        dependencies = {
            "MunifTanjim/prettier.nvim",
            "ckipp01/stylua-nvim",
        },
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
    },

    -- Useful status updates for LSP
    {
        "j-hui/fidget.nvim",
        name = "Fidget",
        version = "legacy",
        config = function()
            require("mzawisa.plugins.fidget")
        end,
    },
    {
        "folke/trouble.nvim",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        config = function()
            require("mzawisa.plugins.trouble")
        end,
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
    },
    {
        "mbbill/undotree", -- ability to browse file history tree
        name = "Undo Tree",
        config = function()
            require("mzawisa.plugins.undotree")
        end,
    },
    {
        "nvim-lualine/lualine.nvim",
        name = "Lualine",
        dependencies = { "nvim-tree/nvim-web-devicons", lazy = true },
        config = function()
            require("mzawisa.plugins.lualine")
        end,
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
    },
    {
        "ThePrimeagen/harpoon",
        name = "Harpoon",
        dependencies = { "nvim-lua/plenary.nvim" },
        config = function()
            require("mzawisa.plugins.harpoon")
        end,
    },
    {
        "voldikss/vim-floaterm",
        config = function()
            require("mzawisa.plugins.floaterm")
        end,
    },
    {
        "iamcco/markdown-preview.nvim",
        build = "cd app && npm install",
        init = function()
            vim.g.mkdp_filetypes = { "markdown" }
        end,
        ft = { "markdown" },
        config = function()
            require("mzawisa.plugins.markdown-preview")
        end,
    },
    {
        "NeogitOrg/neogit",
        dependencies = { "nvim-lua/plenary.nvim" },
        config = function()
            require("mzawisa.plugins.git")
        end,
    },
    {
        "kdheepak/lazygit.nvim",
        -- optional for floating window border decoration
        dependencies = {
            { "nvim-lua/plenary.nvim" },
        },
    },
})
