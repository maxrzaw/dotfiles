local keymap = require("mzawisa.keymap")
local nnoremap = keymap.nnoremap
local vnoremap = keymap.vnoremap
local xnoremap = keymap.xnoremap
local inoremap = keymap.inoremap
local nmap = keymap.nmap

vim.g.mapleader = " "

nnoremap("<leader>e", "<cmd>Explore<CR>", {})
vnoremap("J", ":m '>+1<CR>gv=gv", {})
vnoremap("K", ":m '<-2<CR>gv=gv", {})
--
-- Map ; act like :
vim.keymap.set("", ";", ":")

-- Map jk to <ESC> when in insert mode
inoremap("jk", "<ESC>", {})

-- Keep me centered
nnoremap("<C-u>", "<C-u>zz", {})
nnoremap("<C-d>", "<C-d>zz", {})
nnoremap("n", "nzzzv", {})
nnoremap("N", "Nzzzv", {})
vnoremap("<C-d>", "<C-d>zz", {})
vnoremap("<C-u>", "<C-u>zz", {})

-- Folding
nnoremap("<leader>z", "za", {})

-- Yank the rest of a line
nnoremap("Y", "yg$", {})

-- Paste without overwriting paste register
xnoremap("<leader>p", '"_dP', {})

-- Delete without overwriting paste register
nnoremap("<leader>d", '"_d', {})
vnoremap("<leader>d", '"_d', {})

-- Yank to system clipboard
nnoremap("<leader>y", '"+y', {})
vnoremap("<leader>y", '"+y', {})
nmap("<leader>Y", '"+Y', { silent = true }) -- I want this to remap

vim.keymap.set(
    "n",
    "<leader>sp",
    "<cmd>lua require('mzawisa.custom.angular').toggle_between_spec_and_file()<cr>",
    { desc = "Toggle between spec and file" }
)

nnoremap("<leader>lg", "<cmd>LazyGit<cr>", {})
nnoremap("<leader>gb", "<cmd>Git blame<cr>", {})
