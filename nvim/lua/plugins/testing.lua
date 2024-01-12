-- Not super happy with either of these, I was able to copy the dap config from jester though
return {
    {
        "David-Kunz/jester",
        cond = not vim.g.windows,
        opts = {
            cmd = "npx jest -t '$result' -- $file",
            dap = {
                sourceMaps = true,
            },
        },
        config = function(opts)
            require("jester").setup(opts)
            vim.api.nvim_create_user_command("JesterDebugFile", "lua require('jester').debug_file()", {})
            vim.api.nvim_create_user_command("JesterDebugLast", "lua require('jester').debug_last()", {})
            vim.api.nvim_create_user_command("JesterDebugNearest", "lua require('jester').debug()", {})
            vim.api.nvim_create_user_command("JesterRunFile", "lua require('jester').run_file()", {})
            vim.api.nvim_create_user_command("JesterRunNearest", "lua require('jester').run()", {})
            vim.api.nvim_create_user_command("JesterRunLast", "lua require('jester').run_last()", {})
        end,
    },
    {
        "nvim-neotest/neotest",
        cond = not vim.g.windows,
        dependencies = {
            "nvim-lua/plenary.nvim",
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
