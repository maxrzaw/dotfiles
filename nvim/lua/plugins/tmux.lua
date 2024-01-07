return {
    {
        "christoomey/vim-tmux-navigator",
        config = function()
            -- Turn off default tmux navigator mappings
            vim.g.tmux_navigator_no_mappings = 1
        end,
        keys = {
            { "<c-w><c-h>", "<cmd>TmuxNavigateLeft<cr>", mode = "n" },
            { "<c-w><c-j>", "<cmd>TmuxNavigateDown<cr>", mode = "n" },
            { "<c-w><c-k>", "<cmd>TmuxNavigateUp<cr>", mode = "n" },
            { "<c-w><c-l>", "<cmd>TmuxNavigateRight<cr>", mode = "n" },
        },
    },
    {
        "tmux-plugins/vim-tmux",
    },
}
