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

-- Folding
vim.opt.foldmethod = "indent"
vim.opt.foldlevelstart = 3
vim.opt.foldminlines=2
--vim.opt.foldmethod = "expr"

-- Search Options
vim.opt.hlsearch = false -- This highlights search results.
vim.opt.ignorecase = true -- This ignores case when searching.
vim.opt.incsearch = true -- Show incremental searches.
vim.opt.smartcase = true -- Switch to case sensitive when uppercase is present in search.

-- Interface options
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.colorcolumn = {80,120}

-- Line Wrapping
vim.opt.textwidth = 80
vim.opt.wrap = false -- Prevent automatic wrapping

-- Scrolloff
vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 8

-- Miscellaneous
vim.opt.errorbells = false
vim.opt.termguicolors = true
vim.opt.mouse = "a"
vim.opt.showmatch = true
vim.opt.cmdheight = 1
vim.opt.wildmenu = true
vim.opt.autoread = true
vim.opt.showcmd = true
--vim.opt.signcolumn = "yes"

-- Backup, history, and undo
vim.opt.backup = true
vim.opt.writebackup = true
vim.opt.backupdir = vim.fn.stdpath('config') .. '/backup'
vim.opt.directory = vim.fn.stdpath('config') .. '/swp'
vim.opt.history = 1000
vim.opt.undofile = true

vim.opt.updatetime = 300
vim.opt.timeoutlen = 500 -- how long to wait between key combinations

-- netrw
vim.g.netrw_bufsettings = "noma nomod nonu nobl nowrap ro rnu"
vim.g.netrw_preview = 1
vim.g.netrw_winsize = 40


-- needed for windows maybe?
if (vim.fn.has("win32") == 1) then
    vim.opt.shell = 'bash.exe'
    vim.opt.shellcmdflag='-c'
    --vim.g.coc_node_path = '/c/Program Files/nodejs/node'
end
