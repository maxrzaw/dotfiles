-- Color Theme
vim.g.tokyonight_style = 'night'
vim.g.tokyonight_italic_comments = false
vim.g.tokyonight_transparent = true
vim.g.tokyonight_sidebars = { "terminal", "packer", "qf", "vista_kind" }
-- Change the "hint" color to the "orange" color, and make the "error" color bright red
vim.g.tokyonight_colors = { hint = "orange", error = "#ff0000" }

vim.opt.background = "dark"

vim.cmd [[colorscheme tokyonight]]
vim.cmd[[highlight ColorColumn guibg='DarkRed']]
