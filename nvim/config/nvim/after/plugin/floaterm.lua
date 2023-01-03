local nnoremap = require("mzawisa.keymap").nnoremap;

vim.g.floaterm_title = "";
-- Terminal Mode
vim.keymap.set("t", "<C-T>", "<cmd>FloatermToggle<cr>", { noremap = true, silent = true });
nnoremap("<C-T>", "<cmd>FloatermToggle<cr>", {});
vim.g.floaterm_width = 0.9;
vim.g.floaterm_height = 0.9;
