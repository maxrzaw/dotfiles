local get_opts = require("mzawisa.keymap").get_opts
return {
    "folke/trouble.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
        local ok, trouble = pcall(require, "trouble")
        if not ok then
            return
        end
        trouble.setup({
            auto_close = true,
            action_keys = {
                toggle_fold = { "<leader>z", "<leader>Z" },
            },
            height = 15,
            auto_jump = {
                "lsp_definitions",
                "lsp_type_definitions",
                -- "lsp_references", -- This appears to be broken
            },
        })
        -- Lua
        vim.keymap.set("n", "<leader>qx", function()
            trouble.toggle()
        end, get_opts("Trouble Toggle"))
        vim.keymap.set("n", "<leader>qq", function()
            trouble.open()
        end, get_opts("Trouble Open"))
        vim.keymap.set("n", "<leader>qw", function()
            trouble.open("workspace_diagnostics")
        end, get_opts("Trouble Open Workspace Diagnostics"))
        vim.keymap.set("n", "<leader>qd", function()
            trouble.open("document_diagnostics")
        end, get_opts("Trouble Open Document Diagnostics"))
        vim.keymap.set("n", "<leader>qf", function()
            trouble.open("quickfix")
        end, get_opts("Trouble Open Quickfix List"))
        vim.keymap.set("n", "<leader>ql", function()
            trouble.open("loclist")
        end, get_opts("Trouble Open Location List"))

        function ToggleTroubleAuto()
            vim.defer_fn(function()
                vim.cmd("cclose")
                trouble.open("quickfix")
            end, 0)
        end
        -- vim.api.nvim_create_autocmd({ "BufWinEnter" }, {
        --     pattern = "quickfix",
        --     callback = function()
        --         ToggleTroubleAuto()
        --     end,
        -- })
    end,
    cond = not vim.g.vscode,
}
