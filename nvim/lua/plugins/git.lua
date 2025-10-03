local get_opts = require("mzawisa.keymap").get_opts
return {
    {
        "tpope/vim-fugitive",
        init = function()
            vim.keymap.set("n", "<leader>gb", "<cmd>Git blame<cr>", get_opts("Git Blame"))
        end,
    },
    {
        "lewis6991/gitsigns.nvim",
        cond = not vim.g.vscode and vim.g.windows ~= 1,
        opts = {
            signcolumn = true,
            numhl = false,
            linehl = false,
            word_diff = false,
            current_line_blame = true,
            current_line_blame_opts = {
                virt_text = true,
                virt_text_pos = "eol",
                ignore_whitespace = true,
                delay = 2000,
            },
            preview_config = {
                border = "rounded",
            },
        },
        init = function()
            local gitsigns = require("gitsigns")
            vim.keymap.set("n", "<leader>gB", function()
                gitsigns.blame_line({ full = true })
            end, get_opts("Gitsigns Show Full Line Blame"))
        end,
    },
    {
        "kdheepak/lazygit.nvim",
        dependencies = {
            { "nvim-lua/plenary.nvim" },
        },
        cond = not vim.g.vscode and vim.g.windows ~= 1,
    },
}
