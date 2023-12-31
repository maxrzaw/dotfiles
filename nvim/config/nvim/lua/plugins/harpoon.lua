return {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dev = true,
    lazy = false,
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
        local harpoon = require("harpoon")

        harpoon:setup({
            settings = {
                save_on_toggle = true,
                sync_on_ui_close = false,
                key = function()
                    return vim.loop.cwd()
                end,
            },
        })

        -- Harpoon
        vim.keymap.set("n", "<leader>m", function()
            harpoon:list():append()
        end)
        vim.keymap.set("n", "<leader>h", function()
            harpoon.ui:toggle_quick_menu(harpoon:list(), {
                border = "rounded",
                title_pos = "left",
                title = " Harpoon ",
                ui_max_width = 80,
            })
        end)
    end,
    cond = not vim.g.vscode,
}
