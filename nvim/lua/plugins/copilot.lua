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
}
