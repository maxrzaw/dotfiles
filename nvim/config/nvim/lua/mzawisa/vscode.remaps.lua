local keymap = require("mzawisa.keymap");
local nnoremap = keymap.nnoremap;
local vnoremap = keymap.vnoremap;
local xnoremap = keymap.xnoremap;
local inoremap = keymap.inoremap;
local nmap = keymap.nmap;
local xmap = keymap.xmap;
local omap = keymap.omap;

vim.g.mapleader = " ";

if vim.g.vscode then
    -- Commenting
    print("hello from remaps.lua");
    xmap("gc", "<Plug>VSCodeCommentary", {});
    nmap("gc", "<Plug>VSCodeCommentary", {});
    omap("gc", "<Plug>VSCodeCommentary", {});
    nmap("gcc", "<Plug>VSCodeCommentaryLine", {});
    -- Navigation
    nnoremap("gr", "<cmd>call VSCodeNotify('editor.action.goToReferences')<CR>");
    nnoremap("gd", "<cmd>call VSCodeNotify('editor.action.goToDefinition')<CR>");
    nnoremap("gi", "<cmd>call VSCodeNotify('editor.action.goToImplementation')<CR>");

    -- Move lines. This works, but is a bit jarring visually
    xnoremap("J", ":m '>+1<CR>gv", {});
    xnoremap("K", ":m '<-2<CR>gv", {});

    -- Folding
    nnoremap("za", "<cmd>call VSCodeNotify('editor.toggleFold')<CR>");
    nnoremap("zR", "<cmd>call VSCodeNotify('editor.unfoldAll')<CR>");
    nnoremap("zM", "<cmd>call VSCodeNotify('editor.foldAll')<CR>");


    -- Open explorer with <leader>e
    nnoremap("<leader>e", "<cmd>call VSCodeNotify('workbench.view.explorer')<CR>", {});
    nnoremap("<leader>ff", "<cmd>Ex<CR>", {});
    nnoremap("<leader>fg", "<cmd>call VSCodeNotify('workbench.action.findInFiles')<CR>", {});
else
    -- Do not work in vscode-neovim :(
    vnoremap("J", ":m '>+1<CR>gv=gv", {});
    vnoremap("K", ":m '<-2<CR>gv=gv", {});

    -- Map jk to <ESC> when in insert mode
    inoremap('jk', '<ESC>', {});

    -- Keep me centered
    nnoremap("<C-u>", "<C-u>zz", {});
    nnoremap("<C-d>", "<C-d>zz", {});
    nnoremap("n", "nzzzv", {});
    nnoremap("N", "Nzzzv", {});
    vnoremap("<C-d>", "<C-d>zz", {});
    vnoremap("<C-u>", "<C-u>zz", {});

    -- Folding
    nnoremap("<leader>z", "za", {});

    -- Open explorer with <leader>e
    nnoremap("<leader>e", ":Explore<CR>", {});
end


-- Map ; act like :
vim.keymap.set('', ';', ':');


-- who knows if the below work
-- Yank the rest of a line
nnoremap("Y", "yg$", {});

-- Paste without overwriting paste register
xnoremap("<leader>p", "\"_dP", {})

-- Delete without overwriting paste register
nnoremap("<leader>d", "\"_d", {});
vnoremap("<leader>d", "\"_d", {})

-- Yank to system clipboard
nnoremap("<leader>y", "\"+y", {});
vnoremap("<leader>y", "\"+y", {});
nmap("<leader>Y", "\"+Y", { silent = true }); -- I want this to remap
