local get_opts = require("mzawisa.keymap").get_opts

return {
    {
        "olimorris/codecompanion.nvim",
        cmd = {
            "CodeCompanion",
            "CodeCompanionActions",
            "CodeCompanionChat",
        },
        keys = {
            { "<leader>ccc", "<cmd>CodeCompanionChat Toggle<cr>", mode = "n", desc = "CodeCompanion Chat Toggle" },
            { "<leader>ccn", "<cmd>CodeCompanionChat<cr>", mode = "n", desc = "CodeCompanion New Chat" },
            { "<leader>ccs", "<cmd>CodeCompanionChat Add<cr>", mode = "v", desc = "CodeCompanion Add to Chat" },
            {
                "<leader>cca",
                function()
                    require("codecompanion").actions({
                        provider = {
                            name = "telescope",
                            opts = {
                                initial_mode = "normal",
                                layout_strategy = "flex",
                                layout_config = { width = 0.5, height = 0.5 },
                            },
                        },
                    })
                end,
                mode = "n",
                desc = "CodeCompanion Actions",
            },
            {
                "<leader>ccm",
                function()
                    vim.ui.input({ prompt = "Message: " }, function(msg)
                        if not msg or msg == "" then
                            return
                        end
                        local escaped = vim.fn.escape(msg, '"')
                        vim.cmd([[silent '<,'>CodeCompanionChat ]] .. escaped)
                    end)
                end,
                mode = "v",
                desc = "CodeCompanion Send Selection with Message",
            },
        },
        dependencies = {
            "nvim-lua/plenary.nvim",
            "nvim-treesitter/nvim-treesitter",
            "MunifTanjim/nui.nvim",
        },
        opts = {
            adapters = {
                acp = {
                    opencode = function()
                        return require("codecompanion.adapters").extend("opencode", {
                            defaults = {
                                mcpServers = "inherit_from_config",
                            },
                        })
                    end,
                },
            },
            interactions = {
                cli = {
                    agent = "opencode",
                    agents = {
                        opencode = {
                            cmd = "opencode",
                            args = {},
                            description = "OpenCode CLI",
                            provider = "terminal",
                        },
                    },
                },
                background = {
                    chat = {
                        rules = {
                            autoload = true, -- reads CLAUDE.md/AGENTS.md from project root
                        },
                        callbacks = {
                            ["on_ready"] = {
                                actions = {
                                    "interactions.background.builtin.chat_make_title",
                                },
                                enabled = true,
                            },
                        },
                        opts = {
                            enabled = true,
                        },
                    },
                },
                chat = {
                    adapter = "opencode",
                },
                inline = {
                    adapter = "opencode",
                },
            },
            display = {
                chat = {
                    window = {
                        border = "rounded",
                    },
                    floating_window = {
                        border = "rounded",
                    },
                },
                diff = {
                    window = {
                        border = "rounded",
                    },
                },
                input = {
                    window = {
                        border = "rounded",
                    },
                },
            },
            opts = {
                log_level = "ERROR",
            },
        },
        config = function(_, opts)
            require("codecompanion").setup(opts)

            vim.keymap.set({ "n", "x" }, "<leader>aa", function()
                local mode = vim.fn.mode()
                local is_visual = mode == "v" or mode == "V" or mode == "\22"

                vim.ui.input({ prompt = "CodeCompanion: " }, function(prompt)
                    if not prompt or prompt == "" then
                        return
                    end

                    local escaped = vim.fn.escape(prompt, '"')
                    if is_visual then
                        vim.cmd([[silent '<,'>CodeCompanion ]] .. escaped)
                    else
                        vim.cmd("CodeCompanion " .. escaped)
                    end
                end)
            end, get_opts("CodeCompanion Prompt"))
        end,
        cond = not vim.g.vscode,
    },
}
