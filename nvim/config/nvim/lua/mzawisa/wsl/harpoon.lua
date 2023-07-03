-- Harpoon
local keymap = require("mzawisa.keymap")
local mark = require("harpoon.mark")
local ui = require("harpoon.ui")
require("harpoon").setup({
    menu = {
        -- width = vim.api.nvim_win_get_width(0) - 4,
        width = 80,
    },
})
keymap.nnoremap("<leader>m", mark.add_file, {})
keymap.nnoremap("<leader>h", ui.toggle_quick_menu, {})
