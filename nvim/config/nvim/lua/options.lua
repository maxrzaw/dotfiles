-- Set Indentation Options
vim.opt.expandtab = true
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.autoindent = true
vim.opt.smartindent = true
vim.opt.smarttab = true

-- Search Options
vim.opt.hlsearch = false -- This highlights search results.
vim.opt.ignorecase = true -- This ignores case when searching.
vim.opt.incsearch = true -- Show incremental searches.
vim.opt.smartcase = true -- Switch to case sensitive when uppercase is present in search.

-- Interface options
-- Color Column
vim.opt.colorcolumn = {80,120}

-- Sets the background
vim.opt.background = "dark"


-- Line Wrapping
vim.opt.textwidth = 80
-- Prevent automatic wrapping
vim.opt.wrap = false

-- Miscellaneous
vim.opt.errorbells = false
vim.opt.termguicolors = true
vim.opt.mouse = "a"
vim.opt.showmatch = true
vim.opt.number = true
vim.opt.history = 1000
vim.opt.cmdheight = 1
vim.opt.wildmenu = true
vim.opt.autoread = true
vim.opt.showcmd = true
vim.opt.backupdir = vim.fn.stdpath('config') .. '/backup'
vim.opt.directory = vim.fn.stdpath('config') .. '/swp'

-- COC
vim.opt.backup = true
vim.opt.writebackup = true
vim.opt.updatetime = 300
vim.opt.signcolumn = "yes"