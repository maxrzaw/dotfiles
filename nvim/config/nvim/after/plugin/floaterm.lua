local nnoremap = require("mzawisa.keymap").nnoremap;

vim.g.floaterm_title = "";
-- Terminal Mode
vim.keymap.set("t", "<ESC>", "<cmd>FloatermToggle<cr>", { noremap = true, silent = true });
nnoremap("<leader>t", "<cmd>FloatermToggle<cr>", {});
