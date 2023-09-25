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

if not vim.g.vscode then
    -- Folding
    vim.opt.foldmethod = "indent"
    vim.opt.foldlevelstart = 3
    vim.opt.foldminlines = 2
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
    -- Relativenumber for current buffer only
    vim.cmd([[
        autocmd BufLeave * : setlocal norelativenumber
        autocmd BufEnter * : setlocal relativenumber
]])
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
-- These might need to be off in vscode
vim.opt.cmdheight = 1
vim.opt.wildmenu = true
vim.opt.autoread = true
vim.opt.showcmd = true
vim.opt.signcolumn = "yes"

-- Backup, history, and undo
vim.opt.backup = false
vim.opt.writebackup = false
vim.opt.backupdir = vim.fn.stdpath("config") .. "/backup"
vim.opt.directory = vim.fn.stdpath("config") .. "/swp"
vim.opt.history = 1000
vim.opt.undofile = true
vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"

vim.opt.updatetime = 300
vim.opt.timeoutlen = 500 -- how long to wait between key combinations

-- netrw
vim.g.netrw_bufsettings = "noma nomod nonu nobl nowrap ro rnu"
vim.g.netrw_preview = 1
vim.g.netrw_winsize = 40
vim.g.netrw_altfile = 1
vim.g.netrw_keepj = "keepj"

-- Enable workspace config files
vim.opt.exrc = true
