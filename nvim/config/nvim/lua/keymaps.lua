-- Keybindings
local keymap = vim.api.nvim_set_keymap
local expr_opts = { noremap = true, silent = true, expr = true }
local opts = { noremap = true, silent = true }

-- Use the space key as the leader key
vim.g.mapleader = ' '
-- Map ; act like :
vim.keymap.set('', ';', ':')
-- Map jk to <ESC> when in insert and visual mode 
vim.keymap.set('i', 'jk', '<ESC>')
vim.keymap.set('v', 'jk', '<ESC>')

-- Terminal Mode
keymap("t", "<ESC>", "<cmd>FloatermToggle<cr>", opts)
keymap("n", "<leader>t", "<cmd>FloatermToggle<cr>", opts)

-- Use CTRL-J to move down when in auto completion
keymap(
    "i",
    "<c-j>",
    [[coc#pum#visible() ? coc#pum#next(1) : "\<c-j>"]]
    ,
    expr_opts
)
-- Use CTRL-K to move up when in auto completion
keymap(
    "i",
    "<c-k>",
    [[coc#pum#visible() ? coc#pum#prev(1) : "\<c-k>"]]
    ,
    expr_opts
)

-- Use TAB to move down when in auto completion
keymap(
    "i",
    "<TAB>",
    [[coc#pum#visible() ? coc#pum#next(1) : "\<TAB>"]]
    ,
    expr_opts
)
-- Use SHIFT+TAB to move up when in auto completion
keymap(
    "i",
    "<S-TAB>",
    [[coc#pum#visible() ? coc#pum#prev(1) : "\<S-TAB>"]]
    ,
    expr_opts
)

keymap(
    "i",
    "<CR>",
    [[coc#pum#visible() ? coc#pum#confirm() : "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"]],
    expr_opts
)

keymap("i", "<c-space>", [[coc#refresh()]], expr_opts)

-- Code Navigation
keymap("n", "gd", "<Plug>(coc-definition)", { silent = true })
keymap("n", "gs", ":call CocAction('jumpDefinition', 'vsplit') <CR>", { silent = true })
keymap("n", "gy", "<Plug>(coc-type-definition)", { silent = true })
keymap("n", "gi", "<Plug>(coc-implementation)", { silent = true })
keymap("n", "gr", "<Plug>(coc-references)", { silent = true })

-- Moving lines
keymap("v", "J", ":m '>+1<CR>gv=gv", opts)
keymap("v", "K", ":m '<-2<CR>gv=gv", opts)

-- netrw
keymap("n", "<leader>rw", "<cmd>Explore<CR>", opts)

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

