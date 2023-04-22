-- Set Indentation Options
vim.opt.expandtab = true
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.autoindent = true
vim.opt.smartindent = true
vim.opt.smarttab = true
vim.opt.list = true -- enable the below listchars
vim.opt.listchars = { tab = '▸ ', trail = '·' }

-- Search Options
vim.opt.hlsearch = false -- This highlights search results.
vim.opt.ignorecase = true -- This ignores case when searching.
vim.opt.incsearch = true -- Show incremental searches.
vim.opt.smartcase = true -- Switch to case sensitive when uppercase is present in search.

-- Line Wrapping
vim.opt.textwidth = 80
vim.opt.wrap = false -- Prevent automatic wrapping

-- Miscellaneous
vim.opt.errorbells = false
vim.opt.termguicolors = true
vim.opt.mouse = "a"
vim.opt.showmatch = true

-- Backup, history, and undo
vim.opt.backup = false
vim.opt.writebackup = false
vim.opt.backupdir = vim.fn.stdpath('config') .. '/backup'
vim.opt.directory = vim.fn.stdpath('config') .. '/swp'
vim.opt.history = 1000
vim.opt.undofile = true
vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"

vim.opt.updatetime = 300
vim.opt.timeoutlen = 500 -- how long to wait between key combinations
