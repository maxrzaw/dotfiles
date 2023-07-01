local nnoremap = require("mzawisa.keymap").nnoremap
require("trouble").setup({
    auto_close = true,
    action_keys = {
        toggle_fold = { "<leader>z", "<leader>Z" },
    },
    height = 15,
    auto_jump = {
        "lsp_definitions",
        "lsp_type_definitions",
        "lsp_references",
    },
    -- your configuration comes here
    -- or leave it empty to use the default settings
    -- refer to the configuration section below
})
nnoremap("<leader>qq", "<cmd>Trouble<cr>", {})
