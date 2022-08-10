local neogit = require('neogit')

neogit.setup {}

require'nvim-treesitter.configs'.setup {
    ensure_installed = "maintained", -- Only use parsers that are maintained
    highlight = {
        enable = true,
    },
    indent = {
        enable = true,
    },
}

