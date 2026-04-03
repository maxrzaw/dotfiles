-- Not super happy with either of these, I was able to copy the dap config from jester though
return {
    {
        "nvim-neotest/neotest",
        cond = false,
        dependencies = {
            "nvim-lua/plenary.nvim",
            "nvim-neotest/nvim-nio",
            "nvim-treesitter",
            "antoinemadec/FixCursorHold.nvim",
            { "maxrzaw/neotest-jest", branch = "fakeAsync", dev = false },
        },
        config = function()
            ---@diagnostic disable-next-line: missing-fields
            require("neotest").setup({
                adapters = {
                    require("neotest-jest")({
                        jestCommand = "npx jest",
                        jestConfigFile = "jest.config.ts",
                        env = { CI = true },
                        cwd = function(_)
                            return vim.fn.getcwd()
                        end,
                    }),
                },
            })
            vim.api.nvim_create_user_command("NeotestRunFile", "lua require('neotest').run.run(vim.fn.expand('%'))", {})
            vim.api.nvim_create_user_command(
                "NeotestDebugNearest",
                "lua require('neotest').run.run({strategy = 'dap'})",
                {}
            )
        end,
    },
}
