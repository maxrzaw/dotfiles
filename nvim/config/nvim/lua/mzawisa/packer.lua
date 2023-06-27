local fn = vim.fn
local install_path = fn.stdpath('data') .. '/site/pack/packer/start/packer.nvim'
if fn.empty(fn.glob(install_path)) > 0 then
    PACKER_BOOTSTRAP = fn.system({ 'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim',
        install_path })
    vim.cmd [[packadd packer.nvim]]
end

return require('packer').startup(function(use)
    use 'wbthomason/packer.nvim'
    use {
        'VonHeikemen/lsp-zero.nvim',
        requires = {
            -- LSP Support
            { 'neovim/nvim-lspconfig' },
            { 'williamboman/mason.nvim' },
            { 'williamboman/mason-lspconfig.nvim' },

            -- Autocompletion
            { 'hrsh7th/cmp-nvim-lsp' },
            { 'hrsh7th/cmp-buffer' },
            { 'hrsh7th/cmp-path' },
            { 'hrsh7th/nvim-cmp' },
            { 'saadparwaiz1/cmp_luasnip' },
            { 'hrsh7th/cmp-nvim-lua' },
            { 'hrsh7th/cmp-nvim-lsp-signature-help' },
            { "petertriho/cmp-git",                 requires = "nvim-lua/plenary.nvim" },

            -- Snippets
            { 'L3MON4D3/LuaSnip' },
            { 'rafamadriz/friendly-snippets' },
            { 'onsails/lspkind.nvim' },
            { 'doxnit/cmp-luasnip-choice' },

            -- Useful status updates for LSP
            { 'j-hui/fidget.nvim' },
            {
                "folke/trouble.nvim",
                requires = "kyazdani42/nvim-web-devicons",
            },
        }
    }

    -- Comments
    use 'numToStr/Comment.nvim'
    -- LuaSnip is not strictly required, but I plan on using neogen through LuaSnip
    use { "danymat/neogen", requires = { "nvim-treesitter/nvim-treesitter" }, { "L3MON4D3/LuaSnip" } }

    use 'mbbill/undotree' -- ability to browse file history tree


    use 'MunifTanjim/prettier.nvim'
    use 'jose-elias-alvarez/null-ls.nvim'

    -- Theme
    use 'folke/tokyonight.nvim'

    -- Status Line with Lualine
    use {
        'nvim-lualine/lualine.nvim',
        requires = { 'kyazdani42/nvim-web-devicons', opt = true }
    }

    use {
        'nvim-treesitter/nvim-treesitter',
        run = function() require('nvim-treesitter.install').update({ with_sync = true }) end,
    }

    use {
        'nvim-telescope/telescope.nvim', tag = '0.1.x',
        requires = { { 'nvim-lua/plenary.nvim' } }
    }

    -- Fuzzy Finder Algorithm which requires local dependencies to be built. Only load if `make` is available
    use { 'nvim-telescope/telescope-fzf-native.nvim', run = 'make', cond = vim.fn.executable 'make' == 1 }

    use {
        'ThePrimeagen/harpoon',
        requires = { { 'nvim-lua/plenary.nvim' } }
    }

    use {
        "benfowler/telescope-luasnip.nvim",
        module = "telescope._extensions.luasnip", -- if you wish to lazy-load
        requires = { { 'nvim-telescope/telescope.nvim' }, { 'L3MON4D3/LuaSnip' } }
    }

    -- use {
    --     'ThePrimeagen/refactoring.nvim',
    --     requires = {
    --         { 'nvim-lua/plenary.nvim' },
    --         { 'nvim-treesitter/nvim-treesitter' }
    --     }
    -- }

    use 'voldikss/vim-floaterm'

    use 'gpanders/editorconfig.nvim'

    use({
        "iamcco/markdown-preview.nvim",
        run = "cd app && npm install",
        setup = function() vim.g.mkdp_filetypes = { "markdown" } end,
        ft = { "markdown" },
    })

    use 'yamatsum/nvim-cursorline'
    use 'tpope/vim-surround'

    -- Git
    use 'tpope/vim-fugitive'
    use { 'TimUntersberger/neogit', requires = 'nvim-lua/plenary.nvim' }

    -- Automatically set up your configuration after cloning packer.nvim
    -- Put this at the end after all plugins
    if PACKER_BOOTSTRAP then
        require('packer').sync()
    end
end)
