-- debug.lua

return {
    -- NOTE: Yes, you can install new plugins here!
    "mfussenegger/nvim-dap",
    -- NOTE: And you can specify dependencies as well
    dependencies = {
        -- Creates a beautiful debugger UI
        "rcarriga/nvim-dap-ui",

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

        -- Installs the debug adapters for you
        "williamboman/mason.nvim",
        "jay-babu/mason-nvim-dap.nvim",

        -- Add your own debuggers here
        {
            "mxsdev/nvim-dap-vscode-js",
            opts = {
                -- node_path = "node", -- Path of node executable. Defaults to $NODE_PATH, and then "node"
                debugger_path = vim.fn.stdpath("data") .. "/mason/packages/js-debug-adapter", -- Path to vscode-js-debug installation.
                -- debugger_cmd = { "js-debug-adapter" }, -- Command to use to launch the debug server. Takes precedence over `node_path` and `debugger_path`.
                adapters = { "pwa-node", "pwa-chrome", "node-terminal" }, -- which adapters to register in nvim-dap
                -- log_file_path = "(stdpath cache)/dap_vscode_js.log" -- Path for file logging
                -- log_file_level = false -- Logging level for output to file. Set to false to disable file logging.
                -- log_console_level = vim.log.levels.ERROR -- Logging level for output to console. Set to false to disable console output.
            },
            -- Commenting out until I get this figured out I am using mason
            -- dependencies = {
            --     {
            --         "microsoft/vscode-js-debug",
            --         build = { "npm install --legacy-peer-deps && npx gulp vsDebugServerBundle && mv dist out" },
            --     },
            -- },
        },
        {
            "microsoft/vscode-node-debug2",
            build = { "npm install && NODE_OPTIONS=--no-experimental-fetch npm run build" },
        },
    },
    config = function()
        local dap = require("dap")
        local dapui = require("dapui")

        require("mason-nvim-dap").setup({
            -- Makes a best effort to setup the various debuggers with
            -- reasonable debug configurations
            automatic_setup = true,

            -- You can provide additional configuration to the handlers,
            -- see mason-nvim-dap README for more information
            handlers = {},

            -- You'll need to check that you have the required things installed
            -- online, please don't ask me how to install them :)
            ensure_installed = {
                -- Update this to ensure that you have the debuggers for the langs you want
            },
        })

        local pb = require("persistent-breakpoints.api")

        -- Basic debugging keymaps, feel free to change to your liking!
        vim.keymap.set("n", "<F5>", dap.continue, { desc = "Debug: Start/Continue" })
        vim.keymap.set("n", "<F1>", dap.step_into, { desc = "Debug: Step Into" })
        vim.keymap.set("n", "<F2>", dap.step_over, { desc = "Debug: Step Over" })
        vim.keymap.set("n", "<F3>", dap.step_out, { desc = "Debug: Step Out" })
        vim.keymap.set("n", "<leader>b", pb.toggle_breakpoint, { desc = "Debug: Toggle Breakpoint" })
        vim.keymap.set("n", "<leader>B", pb.set_conditional_breakpoint, { desc = "Debug: Set Breakpoint" })
        vim.keymap.set(
            { "n", "v" },
            "<leader>dk",
            "<cmd>lua require('dapui').eval()<cr>",
            { desc = "Debug: Evaluate under cursor" }
        )
        vim.keymap.set({ "n", "v" }, "<Leader>dh", function()
            require("dap.ui.widgets").hover()
        end, { desc = "Debug: Dap Hover" })
        vim.keymap.set({ "n", "v" }, "<Leader>dp", function()
            require("dap.ui.widgets").preview()
        end, { desc = "Debug: Dap Preview" })
        vim.keymap.set("n", "<Leader>df", function()
            local widgets = require("dap.ui.widgets")
            widgets.centered_float(widgets.frames)
        end, { desc = "Debug: Dap Frames" })
        vim.keymap.set("n", "<Leader>ds", function()
            local widgets = require("dap.ui.widgets")
            widgets.centered_float(widgets.scopes)
        end, { desc = "Debug: Dap Scopes" })

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

        -- Toggle to see last session result. Without this, you can't see session output in case of unhandled exception.
        vim.keymap.set("n", "<F6>", dapui.toggle, { desc = "Debug: Toggle UI" })
        dap.listeners.after.event_initialized["dapui_config"] = dapui.open
        dap.listeners.before.event_terminated["dapui_config"] = dapui.close
        dap.listeners.before.event_exited["dapui_config"] = dapui.close

        dap.adapters.node2 = {
            type = "executable",
            command = "node",
            args = { os.getenv("HOME") .. "/.local/share/nvim/lazy/vscode-node-debug2/out/src/nodeDebug.js" },
        }

        -- Install language specific config
        -- I wasn't able to get this working with pwa-node, but neotest-jest does some magic and gets pwa-node working
        dap.configurations.typescript = {
            {
                name = "Debug Current Directory Tests",
                type = "node2",
                request = "launch",
                cwd = vim.fn.getcwd(),
                -- trace = true, -- include debugger info
                runtimeArgs = {
                    "--inspect-brk",
                    "./node_modules/jest/bin/jest.js",
                    "--",
                    function()
                        return vim.fn.expand("%:p:h")
                    end,
                },
                args = { "--no-cache" },
                sourceMaps = true,
                protocol = "inspector",
                skipFiles = { "<node_internals>/**/*.js" },
                console = "integratedTerminal",
                port = 9229,
                disableOptimisticBPs = true,
            },
            {
                name = "Debug Matching Name Tests",
                type = "node2",
                request = "launch",
                cwd = vim.fn.getcwd(),
                -- trace = true, -- include debugger info
                runtimeArgs = {
                    "--inspect-brk",
                    "./node_modules/jest/bin/jest.js",
                    function()
                        return '--testNamePattern="' .. vim.fn.input("Test Name Pattern: ") .. '"'
                    end,
                    "--",
                    function()
                        return vim.fn.expand("%:p:h")
                    end,
                },
                args = { "--no-cache" },
                sourceMaps = true,
                protocol = "inspector",
                skipFiles = { "<node_internals>/**/*.js" },
                console = "integratedTerminal",
                port = 9229,
                disableOptimisticBPs = true,
            },
        }
    end,
}
