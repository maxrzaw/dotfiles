return {
    {
        "kawre/leetcode.nvim",
        cmd = "Leet",
        cond = not vim.g.vscode,
        dependencies = {
            "nvim-lua/plenary.nvim",
            "MunifTanjim/nui.nvim",
            "nvim-treesitter/nvim-treesitter",
            "nvim-telescope/telescope.nvim",
        },
        keys = {
            {
                "<leader>lc",
                "<cmd>Leet<cr>",
                desc = "LeetCode",
            },
        },
        opts = {
            lang = "typescript",
            picker = {
                provider = "telescope",
            },
            plugins = {
                non_standalone = true,
            },
            hooks = {
                enter = {
                    function()
                        vim.cmd("lsp enable basedpyright")
                        local ok, command = pcall(require, "copilot.command")
                        if ok then
                            command.disable()
                        end
                    end,
                },
                leave = {
                    function()
                        local ok, command = pcall(require, "copilot.command")
                        if ok then
                            command.enable()
                        end
                    end,
                },
            },
        },
    },
}
