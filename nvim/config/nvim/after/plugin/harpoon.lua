local keymap = require("mzawisa.keymap");
local mark = require('harpoon.mark');
local ui = require('harpoon.ui');
-- Harpoon
keymap.nnoremap("<leader>m", mark.add_file, {})
keymap.nnoremap("<leader>h", ui.toggle_quick_menu, {})
