local get_opts = require("mzawisa.keymap").get_opts
return {
    { "github/copilot.vim", enabled = false, cond = not vim.g.vscode },
    {
        "zbirenbaum/copilot.lua",
        opts = {
            suggestion = {
                enabled = true,
                auto_trigger = true,
                debounce = 75,
            },
            panel = {
                enabled = true,
            },
        },
        cond = not vim.g.vscode,
    },
    {
        "zbirenbaum/copilot-cmp",
        enabled = false,
        config = function()
            require("copilot_cmp").setup({})
        end,
        cond = not vim.g.vscode,
    },
    {
        "CopilotC-Nvim/CopilotChat.nvim",
        enabled = false,
        cond = not vim.g.vscode,
        dependencies = {
            "github/copilot.vim",
            "nvim-lua/plenary.nvim",
        },
        event = "VeryLazy",
        build = "make tiktoken",
        keys = {
            { "<M-CR>", "<cmd>CopilotChatToggle<cr>", mode = { "n", "i" }, desc = "Copilot Chat Open" },
        },
        opts = function()
            require("CopilotChat").setup({
                question_header = "#  User",
                answer_header = "#  AI",
                error_header = "#  ERROR",
                separator = "-----",
                highlight_headers = false,

                context = {
                    "buffers",
                },

                agent = "copilot",

                window = {
                    border = "rounded",
                },
                show_help = false,
                show_folds = false,

                selection = nil,

                chat_autocomplete = false,
            })
        end,
    },
}
