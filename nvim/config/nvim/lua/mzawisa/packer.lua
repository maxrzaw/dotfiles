local fn = vim.fn
local install_path = fn.stdpath("data") .. "/site/pack/packer/start/packer.nvim"
if fn.empty(fn.glob(install_path)) > 0 then
    PACKER_BOOTSTRAP =
        fn.system({ "git", "clone", "--depth", "1", "https://github.com/wbthomason/packer.nvim", install_path })
    vim.cmd([[packadd packer.nvim]])
end

return require("packer").startup(function(use)
    use("wbthomason/packer.nvim")
    -- LSP Support
    use({ "neovim/nvim-lspconfig" })
    use({ "williamboman/mason.nvim" })
    use({ "williamboman/mason-lspconfig.nvim" })

    -- Autocompletion
    use({ "hrsh7th/cmp-nvim-lsp" })
    use({ "hrsh7th/cmp-buffer" })
    use({ "hrsh7th/cmp-path" })
    use({ "hrsh7th/nvim-cmp" })
    use({ "saadparwaiz1/cmp_luasnip" })
    use({ "hrsh7th/cmp-nvim-lua" })
    use({ "hrsh7th/cmp-nvim-lsp-signature-help" })
    use({ "petertriho/cmp-git", requires = "nvim-lua/plenary.nvim" })

    -- Snippets
    use({ "L3MON4D3/LuaSnip" })
    use({ "rafamadriz/friendly-snippets" })
    use({ "onsails/lspkind.nvim" })
    use({ "doxnit/cmp-luasnip-choice" })

    -- Useful status updates for LSP
    use({ "j-hui/fidget.nvim", tag = "legacy" })
    use({
        "folke/trouble.nvim",
        requires = "nvim-tree/nvim-web-devicons",
    })

    -- Comments
    use("numToStr/Comment.nvim")
    -- LuaSnip is not strictly required, but I plan on using neogen through LuaSnip
    use({ "danymat/neogen", requires = { "nvim-treesitter/nvim-treesitter" }, { "L3MON4D3/LuaSnip" } })

    use("mbbill/undotree") -- ability to browse file history tree

    use("MunifTanjim/prettier.nvim")
    use("jose-elias-alvarez/null-ls.nvim")

    -- Theme
    use("folke/tokyonight.nvim")
    use("ckipp01/stylua-nvim")

    -- Theme
    use("folke/tokyonight.nvim")

    -- Status Line with Lualine
    use({
        "nvim-lualine/lualine.nvim",
        requires = { "nvim-tree/nvim-web-devicons", opt = true },
    })

    use({
        "nvim-treesitter/nvim-treesitter",
        run = function()
            require("nvim-treesitter.install").update({ with_sync = true })
        end,
    })
    use({ "elgiano/nvim-treesitter-angular", branch = "topic/jsx-fix" })

    use({
        "nvim-treesitter/nvim-treesitter",
        run = function()
            require("nvim-treesitter.install").update({ with_sync = true })
        end,
    })

    use({
        "nvim-telescope/telescope.nvim",
        tag = "0.1.x",
        requires = { { "nvim-lua/plenary.nvim" }, { "benfowler/telescope-luasnip.nvim" } },
    })

    -- Fuzzy Finder Algorithm which requires local dependencies to be built. Only load if `make` is available
    use({ "nvim-telescope/telescope-fzf-native.nvim", run = "make", cond = vim.fn.executable("make") == 1 })

    -- use {
    --     'ThePrimeagen/refactoring.nvim',
    --     requires = {
    --         { 'nvim-lua/plenary.nvim' },
    --         { 'nvim-treesitter/nvim-treesitter' }
    --     }
    -- }

    use({
        "ThePrimeagen/harpoon",
        requires = { { "nvim-lua/plenary.nvim" } },
    })

    use("voldikss/vim-floaterm")

    use({
        "iamcco/markdown-preview.nvim",
        run = "cd app && npm install",
        setup = function()
            vim.g.mkdp_filetypes = { "markdown" }
        end,
        ft = { "markdown" },
    })

    use("tpope/vim-surround")

    -- Git
    use("tpope/vim-fugitive")
    use({ "NeogitOrg/neogit", requires = "nvim-lua/plenary.nvim" })
    use({
        "kdheepak/lazygit.nvim",
        -- optional for floating window border decoration
        requires = {
            "nvim-lua/plenary.nvim",
        },
        config = function()
            require("telescope").load_extension("lazygit")
        end,
    })

    use("mattkubej/jest.nvim")
    use("ckipp01/stylua-nvim")

    -- sonarlint
    use({ "~/dev/sonarlint.nvim", requires = "mfussenegger/nvim-jdtls" })
    -- use({ "https://gitlab.com/maxzawisa/sonarlint.nvim", requires = "mfussenegger/nvim-jdtls" })
    -- use { 'https://gitlab.com/schrieveslaach/sonarlint.nvim', requires = 'mfussenegger/nvim-jdtls' }

    -- Automatically set up your configuration after cloning packer.nvim
    -- Put this at the end after all plugins
    if PACKER_BOOTSTRAP then
        require("packer").sync()
    end
end)
