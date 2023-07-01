local nnoremap = require("mzawisa.keymap").nnoremap

require("neogen").setup({
    snippet_engine = "luasnip",
    enabled = true,
})
nnoremap("<leader>dc", ":lua require('neogen').generate()<cr>", {})
