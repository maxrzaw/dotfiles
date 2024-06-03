return {
    "mfussenegger/nvim-dap",
    dependencies = {
        -- Creates a beautiful debugger UI
        {
            "rcarriga/nvim-dap-ui",
            dependencies = { "nvim-neotest/nvim-nio" },
        },

        -- Virtual Text
        {
            "theHamsta/nvim-dap-virtual-text",
            opts = {
                virt_text_pos = "eol",
                only_first_definition = false,
                highlight_new_as_changed = true,
                all_references = true,
                all_frames = true,
            },
        },

        -- Persistent Breakpoints
        {
            "Weissle/persistent-breakpoints.nvim",
            opts = {
                load_breakpoints_event = "BufReadPost",
            },
        },

        -- Add your own debuggers here
        {
            "mxsdev/nvim-dap-vscode-js",
            opts = {
                debugger_path = vim.fn.stdpath("data") .. "/lazy/vscode-js-debug",
                adapters = { "pwa-node" },
            },
            dependencies = {
                {
                    "microsoft/vscode-js-debug",
                    version = "1.x",
                    build = { "npm i && npm run compile vsDebugServerBundle && rm -rf out && mv dist out" },
                },
            },
        },
    },
    config = function()
        local dap = require("dap")
        local dapui = require("dapui")

        local pb = require("persistent-breakpoints.api")

        -- Basic debugging keymaps, feel free to change to your liking!
        vim.keymap.set("n", "<F5>", dap.continue, { desc = "Debug: Start/Continue" })
        vim.keymap.set("n", "<F1>", dap.step_into, { desc = "Debug: Step Into" })
        vim.keymap.set("n", "<F2>", dap.step_over, { desc = "Debug: Step Over" })
        vim.keymap.set("n", "<F3>", dap.step_out, { desc = "Debug: Step Out" })
        vim.keymap.set("n", "<leader>b", pb.toggle_breakpoint, { desc = "Debug: Toggle [B]reakpoint" })
        vim.keymap.set("n", "<leader>B", pb.set_conditional_breakpoint, { desc = "Debug: Set [B]reakpoint" })
        vim.keymap.set(
            { "n", "v" },
            "<leader>dk",
            "<cmd>lua require('dapui').eval()<cr>",
            { desc = "Debug: Evaluate under cursor" }
        )
        vim.keymap.set({ "n", "v" }, "<Leader>dh", function()
            require("dap.ui.widgets").hover()
        end, { desc = "Debug: [D]ap [H]over" })
        vim.keymap.set({ "n", "v" }, "<Leader>dp", function()
            require("dap.ui.widgets").preview()
        end, { desc = "Debug: [D]ap [P]review" })
        vim.keymap.set("n", "<Leader>df", function()
            local widgets = require("dap.ui.widgets")
            widgets.centered_float(widgets.frames)
        end, { desc = "Debug: [D]ap [F]rames" })
        vim.keymap.set("n", "<Leader>ds", function()
            local widgets = require("dap.ui.widgets")
            widgets.centered_float(widgets.scopes)
        end, { desc = "Debug: [D]ap [S]copes" })

        -- Dap UI setup
        -- For more information, see |:help nvim-dap-ui|
        dapui.setup({
            layouts = {
                {
                    elements = {
                        "console",
                        "scopes",
                    },
                    size = 0.33,
                    position = "bottom", -- Can be "bottom" or "top"
                },
                {
                    -- You can change the order of elements in the sidebar
                    elements = {
                        -- Provide IDs as strings or tables with "id" and "size" keys
                        { id = "repl", size = 0.25 },
                        { id = "stacks", size = 0.45 },
                        { id = "watches", size = 0.15 },
                        { id = "breakpoints", size = 0.15 },
                    },
                    size = 0.33,
                    position = "left", -- Can be "left" or "right"
                },
            },
            icons = { expanded = "▾", collapsed = "▸", current_frame = "*" },
            controls = {
                icons = {
                    pause = "",
                    play = "",
                    step_into = "",
                    step_over = "",
                    step_out = "",
                    step_back = "",
                    run_last = "",
                    terminate = "󰓛",
                    disconnect = "⏏",
                },
            },
        })

        -- Showing the UI with keymap and when debugging starts
        vim.keymap.set("n", "<F6>", dapui.toggle, { desc = "Debug: Toggle UI" })
        dap.listeners.after.event_initialized["dapui_config"] = dapui.open

        -- Install language specific config
        dap.configurations.typescript = {
            {
                type = "pwa-node",
                request = "launch",
                name = "Debug Jest Tests",
                -- trace = true, -- include debugger info
                runtimeExecutable = "node",
                runtimeArgs = {
                    "--inspect-brk",
                    "./node_modules/jest/bin/jest.js",
                    "--runInBand",
                },
                rootPath = "${workspaceFolder}",
                cwd = "${workspaceFolder}",
                console = "integratedTerminal",
                internalConsoleOptions = "neverOpen",
                sourceMaps = true,
                resolveSourceMapLocations = {
                    "${workspaceFolder}/**",
                    "!**/node_modules/**",
                },
                skipFiles = { "${workspaceFolder}/node_modules/**" },
            },
        }
    end,
}
