local get_opts = require("mzawisa.keymap").get_opts
return {
    "folke/trouble.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
        local ok, trouble = pcall(require, "trouble")
        if not ok then
            return
        end
        -- Override Trouble's warn to use a single-line notification
        local trouble_util = require("trouble.util")
        ---@diagnostic disable-next-line: duplicate-set-field, unused-local
        trouble_util.warn = function(msg, opts)
            if type(msg) == "table" then
                msg = msg[1]
            end
            require("fidget").notify(vim.trim(msg), vim.log.levels.WARN, { annote = "Trouble" })
        end

        trouble.setup({
            auto_close = true,
            keys = {
                ["<leader>z"] = "fold_toggle",
                ["<leader>Z"] = "fold_toggle_recursive",
                ["<cr>"] = "jump_close",
                o = "jump",
            },
            win = {
                size = 15,
            },
            focus = true,
            modes = {
                lsp_references = {
                    params = {
                        include_declaration = false,
                    },
                },
                lsp_base = {
                    params = {
                        include_current = false,
                    },
                    auto_jump = true,
                },
                diagnostics_buffer = {
                    mode = "diagnostics",
                    filter = { buf = 0 },
                },
            },
        })

        vim.keymap.set("n", "<leader>qx", function()
            trouble.toggle("diagnostics")
        end, get_opts("Trouble Toggle"))
        vim.keymap.set("n", "<leader>qq", function()
            trouble.open("diagnostics")
        end, get_opts("Trouble Open"))
        vim.keymap.set("n", "<leader>qw", function()
            trouble.open("diagnostics")
        end, get_opts("Trouble Open Workspace Diagnostics"))
        vim.keymap.set("n", "<leader>qd", function()
            trouble.open("diagnostics_buffer")
        end, get_opts("Trouble Open Document Diagnostics"))
        vim.keymap.set("n", "<leader>qf", function()
            trouble.open("quickfix")
        end, get_opts("Trouble Open Quickfix List"))
        vim.keymap.set("n", "<leader>ql", function()
            trouble.open("loclist")
        end, get_opts("Trouble Open Location List"))
    end,
    cond = not vim.g.vscode,
}
