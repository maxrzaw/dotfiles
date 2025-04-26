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
        cond = not vim.g.vscode,
        dependencies = {
            "github/copilot.vim",
            "nvim-lua/plenary.nvim",
        },
        event = "VeryLazy",
        build = "make tiktoken",
        opts = {
            question_header = "#  User",
            answer_header = "#  AI",
            error_header = "#  ERROR",
            separator = "",
            highlight_headers = false,

            context = {
                "buffers",
            },

            model = "gpt-4o",
            agent = "copilot",

            window = {
                border = "rounded",
            },
            show_help = false,
            show_folds = false,

            selection = false,

            chat_autocomplete = false,

            mappings = {
                submit_prompt = {
                    normal = "<C-CR>",
                    insert = "<C-CR>",
                },
            },

            system_prompt = ([[
                    You are an advanced expert code-focused AI programming assistant helping with advanced topics.
                    You answer search-like questions, help with refactoring, optimizations and ideas.
                    You answer with succinctness and clarity. You do not include unnecessary explanations, comments and notes until user asks for them.

                    Your user is an expert programmer, using Python, Rust, Bash and Linux.
                ]]):gsub("%s+", " "),

            prompts = {
                ask = "I ask general question, not related to current project. I want generic answer with details and explanation",
                explain = "Explain what selected code is doing",
                opt = "Optimize selected code, if there is no guaranteed straightforward solution, try to give advices on optimization or guide on where to reseach. If there is guaranteed straightforward optimizations, explain them too",
                write = "Implement a new part of code I'll ask for. Make code complete, correct and clean like I would write myself. Write: ",
            },
        },
    },
}
