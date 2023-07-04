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

require("lazy").setup({
    {
        "folke/tokyonight.nvim",
        lazy = false, -- make sure we load this during startup if it is your main colorscheme
        priority = 1000, -- make sure to load this before all the other start plugins
        config = function()
            -- load the colorscheme here
            require("mzawisa.plugins.tokyonight")
        end,
    },
    {
        "neovim/nvim-lspconfig",
        dependencies = {
            "williamboman/mason.nvim",
            "williamboman/mason-lspconfig.nvim",
            "jose-elias-alvarez/null-ls.nvim",
            "MunifTanjim/prettier.nvim",
            "ckipp01/stylua-nvim",
            {
                "hrsh7th/nvim-cmp",
                dependencies = {
                    "hrsh7th/cmp-nvim-lsp",
                    "hrsh7th/cmp-buffer",
                    "hrsh7th/cmp-path",
                    "saadparwaiz1/cmp_luasnip",
                    "hrsh7th/cmp-nvim-lua",
                    "hrsh7th/cmp-nvim-lsp-signature-help",
                    { "petertriho/cmp-git", dependencies = { "nvim-lua/plenary.nvim" } },
                    "onsails/lspkind.nvim",
                    "doxnit/cmp-luasnip-choice",
                },
                config = function()
                    require("mzawisa.plugins.cmp")
                end,
            },
        },
        config = function()
            require("mzawisa.plugins.lspconfig")
        end,
    },
    {
        "williamboman/mason.nvim",
        dependencies = {
            "williamboman/mason-lspconfig.nvim",
        },
        config = function()
            require("mzawisa.plugins.mason")
        end,
    },

    -- Snippets
    "L3MON4D3/LuaSnip",
    "rafamadriz/friendly-snippets",

    -- Useful status updates for LSP
    { "j-hui/fidget.nvim", version = "legacy" },
    {
        "folke/trouble.nvim",
        dependencies = { "kyazdani42/nvim-web-devicons" },
    },

    -- Comments
    {
        "numToStr/Comment.nvim",
        config = function()
            require("mzawisa.plugins.comment")
        end,
    },
    -- LuaSnip is not strictly required, but I plan on using neogen through LuaSnip
    {
        "danymat/neogen",
        dependencies = { "nvim-treesitter/nvim-treesitter", "L3MON4D3/LuaSnip" },
        config = function()
            require("mzawisa.plugins.neogen")
        end,
    },
    {
        "mbbill/undotree", -- ability to browse file history tree
        config = function()
            require("mzawisa.plugins.neogen")
        end,
    },

    -- Status Line with Lualine
    {
        "nvim-lualine/lualine.nvim",
        dependencies = { "kyazdani42/nvim-web-devicons", lazy = true },
        config = function()
            require("mzawisa.plugins.lualine")
        end,
    },

    {
        "nvim-treesitter/nvim-treesitter",
        build = function()
            require("nvim-treesitter.install").update({ with_sync = true })
        end,
    },

    {
        "nvim-telescope/telescope.nvim",
        version = "0.1.x",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "benfowler/telescope-luasnip.nvim",
            -- Fuzzy Finder Algorithm which requires local dependencies to be built. Only load if `make` is available
            { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
            {
                "ThePrimeagen/harpoon",
                dependencies = { "nvim-lua/plenary.nvim" },
                config = function()
                    require("mzawisa.plugins.harpoon")
                end,
            },
        },
        config = function()
            require("mzawisa.plugins.telescope")
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

    "tpope/vim-surround",

    -- Git
    "tpope/vim-fugitive",
    { "NeogitOrg/neogit", dependencies = { "nvim-lua/plenary.nvim" } },
    {
        "kdheepak/lazygit.nvim",
        -- optional for floating window border decoration
        dependencies = {
            { "nvim-lua/plenary.nvim" },
        },
    },
})
