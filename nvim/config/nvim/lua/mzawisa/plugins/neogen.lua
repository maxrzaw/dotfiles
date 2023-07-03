require("neogen").setup({
    snippet_engine = "luasnip",
    enabled = true,
})
vim.keymap.set("n", "<leader>dc", ":lua require('neogen').generate()<cr>", { silent = true, noremap = true })
