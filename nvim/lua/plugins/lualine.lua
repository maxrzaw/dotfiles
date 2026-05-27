return {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons", lazy = true },
    config = function()
        local palette = require("catppuccin.palettes").get_palette()

        require("mzawisa.custom.codecompanion.status").setup()

        require("lualine").setup({
            options = {
                icons_enabled = true,
                theme = "catppuccin-nvim",
                component_separators = { left = "", right = "" },
                section_separators = { left = "", right = "" },
                disabled_filetypes = {
                    statusline = {},
                    winbar = {},
                },
                ignore_focus = {},
                always_divide_middle = true,
                globalstatus = false,
                refresh = {
                    statusline = 1000,
                    tabline = 1000,
                    winbar = 1000,
                },
            },
            sections = {
                lualine_a = { "mode" },
                lualine_b = { "branch", "diff", "diagnostics" },
                lualine_c = { "filename" },
                lualine_x = {
                    "fileformat",
                    "filetype",
                    {
                        function()
                            return require("mzawisa.custom.codecompanion.status").lualine()
                        end,
                        cond = function()
                            return vim.bo.filetype == "codecompanion"
                        end,
                        color = function()
                            local bg = palette.mauve
                            if require("mzawisa.custom.codecompanion.status").is_plan_mode() then
                                bg = palette.green
                            end

                            return { fg = palette.base, bg = bg, gui = "bold" }
                        end,
                        separator = { left = "", right = "" },
                        padding = { left = 0, right = 1 },
                    },
                },
                lualine_y = { "require'mzawisa.custom.formatting-toggle'.lualine(false)", "progress" },
                lualine_z = { "location" },
            },
            inactive_sections = {
                lualine_a = {},
                lualine_b = {},
                lualine_c = { "filename" },
                lualine_x = { "location" },
                lualine_y = {},
                lualine_z = {},
            },
            tabline = {},
            winbar = {},
            inactive_winbar = {},
            extensions = {},
        })
    end,
    cond = not vim.g.vscode,
}
