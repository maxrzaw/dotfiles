require("trouble").setup({
    auto_close = true,
    action_keys = {
        toggle_fold = { "<leader>z", "<leader>Z" },
    },
    height = 15,
    auto_jump = {
        "lsp_definitions",
        "lsp_type_definitions",
        -- "lsp_references", -- This appears to be broken
    },
})
vim.keymap.set("n", "<leader>qq", "<cmd>TroubleToggle<cr>", { silent = true, noremap = true, desc = "Toggle Trouble" })
