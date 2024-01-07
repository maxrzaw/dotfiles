local get_opts = require("mzawisa.keymap").get_opts
return {
    {
        "numToStr/Comment.nvim",
        name = "Comment",
        config = function()
            require("Comment").setup()
        end,
    },
    {
        "danymat/neogen",
        name = "Neogen",
        dependencies = { "nvim-treesitter/nvim-treesitter", "LuaSnip" },
        config = function()
            require("neogen").setup({
                snippet_engine = "luasnip",
                enabled = true,
            })
            vim.keymap.set("n", "<leader>dc", ":lua require('neogen').generate()<cr>", get_opts("Neogen Generate"))
        end,
    },
}
