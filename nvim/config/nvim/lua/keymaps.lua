-- Keybindings
local keymap = vim.api.nvim_set_keymap
local expr_opts = { noremap = true, silent = true, expr = true }
local opts = { noremap = true, silent = true }

-- Use the space key as the leader key
vim.g.mapleader = ' '
-- Map ; act like :
vim.keymap.set('', ';', ':')
-- Map jk to <ESC> when in insert mode
vim.keymap.set('i', 'jk', '<ESC>')

-- COC
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
    [[coc#pum#visible() ? coc#pum#next(1) : "\<c-j>"]]
    ,
    expr_opts
)
-- Use SHIFT+TAB to move up when in auto completion
keymap(
    "i",
    "<S-TAB>",
    [[coc#pum#visible() ? coc#pum#prev(1) : "\<c-k>"]]
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

-- netrw
keymap("n", "<leader>f", "<cmd>Explore<CR>", opts)