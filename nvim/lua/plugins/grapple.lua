return {
    "cbochs/grapple.nvim",
    lazy = false,
    dependencies = {
        "nvim-lua/plenary.nvim",
    },
    opts = {
        scope = "git",
        log_level = "warn",
        win_opts = {
            border = "rounded",
        },
    },
    config = function(_, opts)
        local grapple = require("grapple")
        grapple.setup(opts)

        -- Keybindings
        vim.keymap.set("n", "<leader>m", function()
            grapple.tag()
        end, { desc = "Grapple: Tag file" })

        vim.keymap.set("n", "<leader>h", function()
            grapple.open_tags()
        end, { desc = "Grapple: Open tags window" })

        -- Quick navigation to tags 1-9
        for i = 1, 9 do
            vim.keymap.set("n", "<leader>" .. i, function()
                grapple.select({ index = i })
            end, { desc = "Grapple: Select tag " .. i })
        end
    end,
    cond = not vim.g.vscode,
}
