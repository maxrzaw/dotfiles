local utils = require("mzawisa.utils")

return {
    -- "ThePrimeagen/harpoon",
    -- branch = "harpoon2",
    "maxrzaw/harpoon",
    branch = "harpoon3",
    dev = true,
    lazy = false,
    dependencies = {
        "nvim-lua/plenary.nvim",
        {
            "maxrzaw/harpoon-relative-marks",
            dependencies = { "pysan3/pathlib.nvim" },
        },
    },
    config = function()
        local Harpoon = require("harpoon")
        local relative_marks = require("harpoon-relative-marks")

        Harpoon:setup({
            settings = {
                save_on_toggle = true,
                sync_on_ui_close = true,
                key = function()
                    -- return vim.uv.cwd() -- This is the default
                    return utils.find_project_root()
                end,
            },
            default = {
                display = relative_marks.display,
                create_list_item = relative_marks.create_list_item,
            },
        })

        relative_marks.setup({
            key = function()
                return utils.find_project_root()
            end,
        })

        vim.api.nvim_create_autocmd({ "QuitPre" }, {
            pattern = "*",
            callback = function()
                -- Do this for all the lists you have
                Harpoon:list():sync_cursor()
            end,
        })

        -- Harpoon
        vim.keymap.set("n", "<leader>m", function()
            Harpoon:list():add()
        end)
        vim.keymap.set("n", "<leader>h", function()
            local path =
                vim.api.nvim_buf_get_name(vim.api.nvim_get_current_buf())
            Harpoon.ui:toggle_quick_menu(Harpoon:list(), {
                border = "rounded",
                title_pos = "center",
                title = " >-> Harpoon <-< ",
                ui_max_width = 80,
                context = path,
            })
        end)
    end,
    cond = not vim.g.vscode,
}
