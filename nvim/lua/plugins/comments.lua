local get_opts = require("mzawisa.keymap").get_opts
return {
    {
        "numToStr/Comment.nvim",
        name = "Comment",
        lazy = false,
        opts = {},
    },
    {
        "danymat/neogen",
        name = "Neogen",
        dependencies = { "nvim-treesitter/nvim-treesitter", "LuaSnip" },
        ft = {
            "sh",
            "c",
            "cs",
            "cpp",
            "go",
            "java",
            "javascript",
            "javascriptreact",
            "kotlin",
            "lua",
            "php",
            "python",
            "ruby",
            "rust",
            "typescript",
            "typescriptreact",
            "vue",
        },
        opts = {
            snippet_engine = "luasnip",
            enabled = true,
        },
        init = function()
            vim.keymap.set("n", "<leader>dc", function()
                require("neogen").generate()
            end, get_opts("Neogen Generate"))
        end,
    },
}
