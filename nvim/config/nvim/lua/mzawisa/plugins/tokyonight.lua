local M = {}
-- Additional setup that I sometimes need to rerun
function M.ColorMyPencils(color)
    color = color or "tokyonight"
    vim.cmd.colorscheme(color)

    -- vim.api.nvim_set_hl(0, "FloatBorder", { link = "TelescopeBorder" })
    -- vim.api.nvim_set_hl(0, "FloatTitle", { link = "TelescopeTitle" })
end

-- Set up Tokyonight
M.my_setup = function()
    require("tokyonight").setup({
        style = "moon",
        transparent = true,
        terminal_colors = true,
        styles = {
            comments = { italic = true },
            floats = "transparent",
            sidebars = "dark",
        },
        sidebars = { "none" },
        on_highlights = function(hl, c)
            hl.TelescopeBorder = {
                bold = true,
                fg = c.fg_dark,
            }
            hl.TroubleNormal = {
                link = "TelescopeNormal",
            }
        end,
    })
    M.ColorMyPencils()
end

return M
