local M = {}
-- Additional setup that I sometimes need to rerun
function M.ColorMyPencils(color)
    color = color or "tokyonight"
    vim.cmd.colorscheme(color)

    vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
    vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
    vim.api.nvim_set_hl(0, "FloatBorder", { bg = "none" })
    vim.api.nvim_set_hl(0, "ColorColumn", { bg = "DarkRed" })
    vim.api.nvim_set_hl(0, "TelescopeNormal", { bg = "none" })
    vim.api.nvim_set_hl(0, "TelescopeBorder", { bg = "none" })
end

-- Set up Tokyonight
M.setup = function()
    require("tokyonight").setup({
        style = "moon",
        transparent = true,
        terminal_colors = true,
        italic_comments = false,
        styles = {
            floats = "dark",
            sidebars = "dark",
        },
        sidebars = { "qf", "vista_kind" },
        --colors = { hint = "orange", error = "#ff0000" },
    })
    M.ColorMyPencils()
end
return M
