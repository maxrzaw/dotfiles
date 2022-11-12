-- Keybindings
local keymap = vim.api.nvim_set_keymap
local expr_opts = { noremap = true, silent = true, expr = true }
local opts = { noremap = true, silent = true }

-- Use the space key as the leader key
vim.g.mapleader = ' '
-- Map ; act like :
vim.keymap.set('', ';', ':')
-- I used to remap jk to <ESC> for speed. However, I remapped CAPS LOCK to ESC
-- Map jk to <ESC> when in insert and visual mode 
keymap('i', 'jk', '<ESC>', opts) -- keeping this for now
--keymap('v', 'jk', '<ESC>', opts) -- not sure if I like this one

-- Keep me centered
keymap("n", "<C-u>", "<C-u>zz", opts)
keymap("v", "<C-u>", "<C-u>zz", opts)
keymap("n", "<C-d>", "<C-d>zz", opts)
keymap("v", "<C-d>", "<C-d>zz", opts)
keymap("n", "n", "nzzzv", opts)
keymap("n", "N", "Nzzzv", opts)

-- Folding
keymap("n", "<leader>z", "za", opts)

-- Yank the rest of a line
keymap("n", "Y", "yg$", opts)

-- Paste without overwriting paste register
keymap("x", "<leader>p", "\"_dP", opts)

-- Delete without overwriting paste register
keymap("n", "<leader>d", "\"_d", opts)
keymap("v", "<leader>d", "\"_d", opts)

-- Yank to system clipboard
keymap("n", "<leader>y", "\"+y", opts)
keymap("v", "<leader>y", "\"+y", opts)
keymap("n", "<leader>Y", "\"+Y", {silent = true}) -- I want this to remap

-- Terminal Mode
keymap("t", "<ESC>", "<cmd>FloatermToggle<cr>", opts)
--keymap('t', 'jk', '<ESC>', {silent = true}) -- I don't think many words contain 'jk'
keymap("n", "<leader>t", "<cmd>FloatermToggle<cr>", opts)

-- Code Navigation
-- keymap("n", "gd", "<Plug>(coc-definition)zz", { silent = true })
-- keymap("n", "gs", ":call CocAction('jumpDefinition', 'vsplit') <CR>zz", { silent = true })
-- keymap("n", "gy", "<Plug>(coc-type-definition)zz", { silent = true })
-- keymap("n", "gi", "<Plug>(coc-implementation)zz", { silent = true })
-- keymap("n", "gr", "<Plug>(coc-references)zz", { silent = true })

-- Snippets
keymap(
    "i",
    "<Tab>",
    [[luasnip#expand_or_jumpable() ? "<Plug>luasnip-expand-or-jump" : "\<Tab>"]]
    ,
    expr_opts
)

keymap(
    "i",
    "<S-Tab>",
    "<cmd>lua require('luasnip').jump(-1)<cr>" ,
    opts
)

keymap(
    "s",
    "<Tab>",
    "<cmd>lua require('luasnip').jump(1)<cr>" ,
    opts
)

keymap(
    "s",
    "<S-Tab>",
    "<cmd>lua require('luasnip').jump(-1)<cr>" ,
    opts
)

--keymap(
--    "i",
--    "<Tab>",
--    "<cmd>lua require('luasnip').jump(1)<cr>" ,
--    expr_opts
--)
--
--keymap(
--    "i",
--    "<S-Tab>",
--    "<cmd>lua require('luasnip').jump(-1)<cr>" ,
--    expr_opts
--)

-- Moving lines
keymap("v", "J", ":m '>+1<CR>gv=gv", opts)
keymap("v", "K", ":m '<-2<CR>gv=gv", opts)

-- netrw
keymap("n", "<leader>e", "<cmd>Explore<CR>", opts)

-- Telescope
keymap("n", "<leader>ff", "<cmd>lua require('telescope.builtin').find_files()<cr>", opts)
keymap("n", "<leader>fg", "<cmd>lua require('telescope.builtin').live_grep()<cr>", opts)
keymap("n", "<leader>fb", "<cmd>lua require('telescope.builtin').buffers()<cr>", opts)
keymap("n", "<leader>fh", "<cmd>lua require('telescope.builtin').help_tags()<cr>", opts)
keymap("n", "<leader>fgs", "<cmd>lua require('telescope.builtin').git_status()<cr>", opts)
keymap("n", "<leader>fgb", "<cmd>lua require('telescope.builtin').git_branches()<cr>", opts)
keymap("n", "<leader>fgc", "<cmd>lua require('telescope.builtin').git_commits()<cr>", opts)

-- Harpoon
keymap("n", "<leader>m", "<cmd>lua require('harpoon.mark').add_file()<cr>", opts)
keymap("n", "<leader>h", "<cmd>lua require('harpoon.ui').toggle_quick_menu()<cr>", opts)


