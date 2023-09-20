return {
    "mfussenegger/nvim-dap",
    dependencies = {
        {
            -- fancy UI for the debugger
            "rcarriga/nvim-dap-ui",
            keys = {
                {
                    "<leader>du",
                    function()
                        require("dapui").toggle({})
                    end,
                    desc = "Dap UI",
                },
                {
                    "<leader>de",
                    function()
                        require("dapui").eval()
                    end,
                    desc = "Eval",
                    mode = { "n", "v" },
                },
            },
            opts = {},
            config = function(_, opts)
                local dap = require("dap")
                local dapui = require("dapui")
                dapui.setup(opts)
                dap.listeners.after.event_initialized["dapui_config"] = function()
                    dapui.open({})
                end
                dap.listeners.before.event_terminated["dapui_config"] = function()
                    dapui.close({})
                end
                dap.listeners.before.event_exited["dapui_config"] = function()
                    dapui.close({})
                end
            end,
        },
        {
            -- virtual text for the debugger
            "theHamsta/nvim-dap-virtual-text",
            opts = {},
        },
        {
            "mxsdev/nvim-dap-vscode-js",
            config = function()
                require("dap-vscode-js").setup({
                    adapters = {
                        "pwa-node",
                        "pwa-chrome",
                    },
                })
            end,
        },
        {
            "microsoft/vscode-js-debug",
            build = {
                "npm install --legacy-peer-deps && npx gulp vsDebugServerBundle && mv dist out",
            },
        },
    },
    config = function()
        local dap = require("dap")
        dap.adapters["pwa-node"] = {
            type = "server",
            host = "localhost",
            port = "42069",
            executable = {
                command = "node",
                args = { "/Users/max/.local/share/nvim/lazy/vscode-js-debug/out/src/vsDebugServer.js" },
            },
        }
        dap.adapters["pwa-chrome"] = {
            type = "executable",
            host = "localhost",
            port = "42069",
            command = "node",
            args = { "/Users/max/.local/share/nvim/lazy/vscode-js-debug/out/src/vsDebugServer.js" },
        }
        for _, language in ipairs({ "typescript", "javascript" }) do
            dap.configurations[language] = {
                {
                    type = "pwa-chrome",
                    request = "attach",
                    name = "Attach Chrome",
                    -- trace = true, -- include debugger info
                    rootPath = "${workspaceFolder}",
                    cwd = "${workspaceFolder}",
                    console = "integratedTerminal",
                    internalConsoleOptions = "neverOpen",
                },
                {
                    type = "pwa-chrome",
                    request = "launch",
                    name = "Launch Chrome",
                    -- trace = true, -- include debugger info
                    rootPath = "${workspaceFolder}",
                    cwd = "${workspaceFolder}",
                    console = "integratedTerminal",
                    internalConsoleOptions = "neverOpen",
                },
                {
                    type = "pwa-node",
                    request = "launch",
                    name = "Debug Jest Tests",
                    -- trace = true, -- include debugger info
                    runtimeExecutable = "node",
                    runtimeArgs = {
                        "./node_modules/jest/bin/jest.js",
                        "--runInBand",
                    },
                    rootPath = "${workspaceFolder}",
                    cwd = "${workspaceFolder}",
                    console = "integratedTerminal",
                    internalConsoleOptions = "neverOpen",
                },
            }
        end
    end,
    keys = {
        {
            "<leader>dB",
            function()
                require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))
            end,
            desc = "Breakpoint Condition",
        },
        {
            "<leader>db",
            function()
                require("dap").toggle_breakpoint()
            end,
            desc = "Toggle Breakpoint",
        },
        {
            "<leader>dc",
            function()
                require("dap").continue()
            end,
            desc = "Continue",
        },
        {
            "<leader>dC",
            function()
                require("dap").run_to_cursor()
            end,
            desc = "Run to Cursor",
        },
        {
            "<leader>dg",
            function()
                require("dap").goto_()
            end,
            desc = "Go to line (no execute)",
        },
        {
            "<leader>di",
            function()
                require("dap").step_into()
            end,
            desc = "Step Into",
        },
        {
            "<leader>dj",
            function()
                require("dap").down()
            end,
            desc = "Down",
        },
        {
            "<leader>dk",
            function()
                require("dap").up()
            end,
            desc = "Up",
        },
        {
            "<leader>dla",
            function()
                require("dap").run_last()
            end,
            desc = "Run Last",
        },
        {
            "<leader>do",
            function()
                require("dap").step_out()
            end,
            desc = "Step Out",
        },
        {
            "<leader>dO",
            function()
                require("dap").step_over()
            end,
            desc = "Step Over",
        },
        {
            "<leader>dp",
            function()
                require("dap").pause()
            end,
            desc = "Pause",
        },
        {
            "<leader>dr",
            function()
                require("dap").repl.toggle()
            end,
            desc = "Toggle REPL",
        },
        {
            "<leader>ds",
            function()
                require("dap").session()
            end,
            desc = "Session",
        },
        {
            "<leader>dt",
            function()
                require("dap").terminate()
            end,
            desc = "Terminate",
        },
        {
            "<leader>dw",
            function()
                require("dap.ui.widgets").hover()
            end,
            desc = "Widgets",
        },
    },
}
