return {
    { "github/copilot.vim", enabled = false },
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
    },
    {
        "zbirenbaum/copilot-cmp",
        enabled = false,
        config = function()
            require("copilot_cmp").setup({})
        end,
    },
}
