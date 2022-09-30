require("tokyonight").setup({
    style = "moon",
    transparent = true,
    terminal_colors = true,
    italic_comments = false,
    styles = {
        floats = "dark",
        sidebars = "dark",
    },
    sidebars = { "terminal", "packer", "qf", "vista_kind" },
    colors = { hint = "orange", error = "#ff0000" },
})

vim.cmd [[colorscheme tokyonight]]
vim.cmd[[highlight ColorColumn guibg='DarkRed']]
