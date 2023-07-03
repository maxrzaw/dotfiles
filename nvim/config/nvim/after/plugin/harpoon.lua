local mark = require("harpoon.mark")
local ui = require("harpoon.ui")
-- Harpoon
vim.keymap.set("n", "<leader>m", mark.add_file, { silent = true, noremap = true })
vim.keymap.set("n", "<leader>h", ui.toggle_quick_menu, {silent = true, noremap = true })
