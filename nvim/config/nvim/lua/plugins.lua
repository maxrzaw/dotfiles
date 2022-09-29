local fn = vim.fn
local install_path = fn.stdpath('data')..'/site/pack/packer/start/packer.nvim'
if fn.empty(fn.glob(install_path)) > 0 then
    packer_bootstrap = fn.system({'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path})
    vim.cmd [[packadd packer.nvim]]
end

return require('packer').startup(function(use)
    use 'wbthomason/packer.nvim'

    -- Theme
    use 'folke/tokyonight.nvim'

    -- Intellisense
    use {'neoclide/coc.nvim', branch = 'release'}

    -- Status Line with Lualine
    use {
        'nvim-lualine/lualine.nvim',
        requires = { 'kyazdani42/nvim-web-devicons', opt = true }
    }

    -- Treesitter
    use {
        'nvim-treesitter/nvim-treesitter',
        run = function() require('nvim-treesitter.install').update({ with_sync = true }) end,
    }

    -- Telescope
    use {
        'nvim-telescope/telescope.nvim', tag = '0.1.x',
        requires = {{ 'nvim-lua/plenary.nvim'}}
    }

    -- Neogit
    use { 'TimUntersberger/neogit', requires = 'nvim-lua/plenary.nvim' }

    -- Harpoon
    use {
        'ThePrimeagen/harpoon',
        requires = {{ 'nvim-lua/plenary.nvim'}}
    }

    use 'voldikss/vim-floaterm'

    use 'gpanders/editorconfig.nvim'

    -- needed for windows maybe?
    if vim.fn.has("win32") then
        use 'OmniSharp/omnisharp-vim'
    end

    -- Automatically set up your configuration after cloning packer.nvim
    -- Put this at the end after all plugins
    if packer_bootstrap then
        require('packer').sync()
    end
end)
