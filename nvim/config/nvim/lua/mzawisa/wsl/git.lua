local neogit = require('neogit');
local nnoremap = require('mzawisa.keymap').nnoremap;

neogit.setup {}

nnoremap("<leader>gb", "<cmd>Git blame<cr>", {});
