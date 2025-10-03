vim.g.mapleader = " "
-- Set Indentation Options
vim.opt.expandtab = true
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.autoindent = true
vim.opt.smartindent = true
vim.opt.smarttab = true
vim.opt.list = true -- enable the below listchars
vim.opt.listchars = { tab = "▸ ", trail = "·" }

vim.g.windows = vim.fn.has("win32") or vim.fn.has("win64")

if not vim.g.vscode then
    -- Folding
    vim.opt.foldmethod = "indent"
    vim.opt.foldlevelstart = 6
    vim.opt.foldminlines = 4
    --vim.opt.foldmethod = "expr"
end

-- Search Options
vim.opt.hlsearch = false -- This highlights search results.
vim.opt.ignorecase = true -- This ignores case when searching.
vim.opt.incsearch = true -- Show incremental searches.
vim.opt.smartcase = true -- Switch to case sensitive when uppercase is present in search.

if not vim.g.vscode then
    -- Interface options
    vim.opt.number = true
    vim.opt.relativenumber = true
    vim.opt.colorcolumn = { 120 }
end

-- Line Wrapping
vim.opt.textwidth = 80
vim.opt.wrap = false -- Prevent automatic wrapping

if not vim.g.vscode then
    -- Scrolloff
    vim.opt.scrolloff = 8
    vim.opt.sidescrolloff = 8
end

-- Miscellaneous
vim.opt.errorbells = false
vim.opt.termguicolors = true
vim.opt.mouse = "a"
vim.opt.showmatch = true
vim.opt.showmode = false
vim.opt.cmdheight = 1
vim.opt.wildmenu = true
vim.opt.autoread = true
vim.opt.signcolumn = "yes"
vim.opt.shortmess:append({ W = true, I = true, c = true, C = true })
vim.opt.winborder = "rounded"

-- Backup, history, and undo
vim.opt.backup = false
vim.opt.writebackup = false
vim.opt.backupdir = vim.fn.stdpath("data") .. "/backup"
vim.opt.directory = vim.fn.stdpath("data") .. "/swp"
vim.opt.history = 1000
if vim.g.windows ~= 1 then
    vim.opt.undofile = true
    vim.opt.undodir = vim.fn.stdpath("data") .. "/undo"
end

vim.opt.updatetime = 300
vim.opt.timeout = true
vim.opt.timeoutlen = 500 -- how long to wait between key combinations

-- netrw
vim.g.netrw_bufsettings = "noma nomod nonu nobl nowrap ro rnu"
vim.g.netrw_preview = 1
vim.g.netrw_winsize = 40
vim.g.netrw_altfile = 1
vim.g.netrw_keepj = "keepj"

if vim.version().minor >= 10 then
    vim.opt.smoothscroll = true
end

-- Enable workspace config files
vim.opt.exrc = true

-- Windows shell configuration
if vim.g.windows == 1 then
    vim.opt.shell = "pwsh.exe"
    vim.opt.shellcmdflag = "-NoLogo -NoProfile -ExecutionPolicy RemoteSigned -Command"
    vim.opt.shellquote = ""
    vim.opt.shellxquote = ""
end
