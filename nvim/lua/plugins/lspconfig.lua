local M = {}
M.inlay_hints_enabled = false
return {
    "neovim/nvim-lspconfig",
    cond = not vim.g.vscode,
    dependencies = {
        -- Mason
        {
            "williamboman/mason-lspconfig.nvim",
            dependencies = {
                "williamboman/mason.nvim",
            },
        },
        -- Null Language Server
        "nvimtools/none-ls.nvim",
        -- Completion
        "nvim-cmp",
        -- OmniSharp Extended
        "Hoffs/omnisharp-extended-lsp.nvim",
        -- Special LSP config for neovim development
        "folke/neodev.nvim",
    },
    config = function()
        local cmp = require("cmp")
        local lspconfig = require("lspconfig")
        local sonar_rules = require("mzawisa.custom.sonarlint_helper").rules
        local angular = require("mzawisa.custom.angular")

        -- Add nvim_cmp default capabilities to lspconfig default capabilities
        lspconfig.util.default_config.capabilities = vim.tbl_deep_extend(
            "force",
            lspconfig.util.default_config.capabilities,
            require("cmp_nvim_lsp").default_capabilities()
        )

        -- Helper function to disable formatting capabilities
        local disable_formatting_on_init = function(client)
            client.server_capabilities.documentFormattingProvider = false
            client.server_capabilities.documentFormattingRangeProvider = false
        end

        -- LSP Formatting
        local lsp_formatting = function(bufnr)
            local path = vim.api.nvim_buf_get_name(bufnr)
            if not require("mzawisa.custom.formatting-toggle").formatting_enabled(path) then
                return
            end

            vim.lsp.buf.format({ bufnr = bufnr })
        end

        local lspFormattingAugroup = vim.api.nvim_create_augroup("LspFormatting", { clear = true })
        local set_format_on_save = function(client, bufnr)
            if client.server_capabilities.documentFormattingProvider then
                vim.api.nvim_create_autocmd("BufWritePre", {
                    group = lspFormattingAugroup,
                    buffer = bufnr,
                    callback = function()
                        lsp_formatting(bufnr)
                    end,
                })
            end
        end

        -- LSP Keybindings
        local set_default_keybindings = function(client, bufnr)
            local opts = { buffer = bufnr, silent = true, noremap = true }

            vim.keymap.set(
                "n",
                "gt",
                "<cmd>Trouble lsp_type_definitions toggle<cr>",
                vim.tbl_extend("error", opts, { desc = "LSP: [G]o to [T]ype Definitions" })
            )
            vim.keymap.set(
                "n",
                "gr",
                "<cmd>Trouble lsp_references toggle<cr>",
                vim.tbl_extend("error", opts, { desc = "LSP: [G]o to [R]eferences" })
            )
            vim.keymap.set(
                "n",
                "gd",
                "<cmd>Trouble lsp_definitions toggle<cr>",
                vim.tbl_extend("error", opts, { desc = "LSP: [G]o to [D]efinitions" })
            )
            vim.keymap.set(
                "n",
                "gD",
                vim.lsp.buf.declaration,
                vim.tbl_extend("error", opts, { desc = "LSP: [G]o To [D]eclaration" })
            )
            vim.keymap.set(
                "n",
                "gi",
                vim.lsp.buf.implementation,
                vim.tbl_extend("error", opts, { desc = "LSP: [G]o To [I]mplementation" })
            )
            vim.keymap.set(
                "n",
                "<leader>vd",
                vim.diagnostic.open_float,
                vim.tbl_extend("error", opts, { desc = "LSP: [V]iew [D]iagnostics for current line" })
            )
            vim.keymap.set(
                { "n", "v" },
                "<leader>ca",
                vim.lsp.buf.code_action,
                vim.tbl_extend("error", opts, { desc = "LSP: [C]ode [A]ction" })
            )
            vim.keymap.set(
                "n",
                "<leader>dn",
                vim.diagnostic.goto_next,
                vim.tbl_extend("error", opts, { desc = "LSP: Go To [N]ext [D]iagnostic" })
            )
            vim.keymap.set(
                "n",
                "<leader>dN",
                vim.diagnostic.goto_prev,
                vim.tbl_extend("error", opts, { desc = "LSP: Go To Prev [D]iagnostic" })
            )
            vim.keymap.set(
                "n",
                "<leader>dl",
                "<cmd>Telescope diagnostics<CR>",
                vim.tbl_extend("error", opts, { desc = "LSP: [L]ist All [D]iagnostics" })
            )
            vim.keymap.set(
                "n",
                "<leader>r",
                vim.lsp.buf.rename,
                vim.tbl_extend("error", opts, { desc = "LSP: [R]ename Symbol" })
            )
            vim.keymap.set("i", "<C-h>", function()
                M.inlay_hints_enabled = not M.inlay_hints_enabled
                vim.lsp.inlay_hint.enable(M.inlay_hints_enabled)
            end, vim.tbl_extend("error", opts, { desc = "LSP: Toggle Inlay [H]ints" }))
            vim.keymap.set("n", "<C-h>", function()
                M.inlay_hints_enabled = not M.inlay_hints_enabled
                vim.lsp.inlay_hint.enable(M.inlay_hints_enabled)
            end, vim.tbl_extend("error", opts, { desc = "LSP: Toggle Inlay [H]ints" }))
            vim.keymap.set(
                "i",
                "<C-k>",
                vim.lsp.buf.signature_help,
                vim.tbl_extend("error", opts, { desc = "LSP: Signature Help" })
            )
            vim.keymap.set("n", "K", vim.lsp.buf.hover, vim.tbl_extend("error", opts, { desc = "LSP: Hover" }))

            if client.name == "angularls" then
                angular.set_quickswitch_keybindings()
            end
        end

        -- Use LspAttach autocommand to only map the following keys
        -- after the language server attaches to the current buffer
        -- I am using this for things I want to run for every language servers
        vim.api.nvim_create_autocmd("LspAttach", {
            group = vim.api.nvim_create_augroup("UserLspConfig", {}),
            callback = function(args)
                local bufnr = args.buf
                local client = vim.lsp.get_client_by_id(args.data.client_id)
                if client ~= nil and client.server_capabilities.inlayHintProvider then
                    vim.lsp.inlay_hint.enable(M.inlay_hints_enabled, {})
                end
                set_default_keybindings(client, bufnr)
                set_format_on_save(client, bufnr)
                if client ~= nil and client.name == "ts_ls" and angular.enabled then
                    client.server_capabilities.renameProvider = false
                end
            end,
        })

        if vim.g.windows ~= 1 then
            local runtime_path = vim.split(package.path, ";")
            table.insert(runtime_path, "lua/?.lua")
            table.insert(runtime_path, "lua/?/init.lua")
            lspconfig.lua_ls.setup({
                on_init = disable_formatting_on_init,
                settings = {
                    Lua = {
                        -- Disable Telemetry
                        telemetry = { enable = false },
                        diagnostics = {
                            globals = { "vim", "describe", "it", "before_each", "after_each" },
                        },
                        runtime = {
                            version = "LuaJIT",
                            path = runtime_path,
                        },
                        workspace = {
                            checkThirdParty = false,
                        },
                    },
                },
            })
        end

        if not os.getenv("NEOVIM_WORK") then
            lspconfig.omnisharp.setup({
                handlers = {
                    ["textDocument/definition"] = require("omnisharp_extended").handler,
                },
                cmd = { "/Users/max/.local/share/nvim/mason/bin/omnisharp" },
                organize_imports_on_format = true,
                enable_roslyn_analyzers = true,
            })
        end

        -- Set up Angular Language Server
        -- wierd things required for angular monorepo
        local function get_node_modules(root_dir)
            local root_node = root_dir .. "/node_modules"
            local stats = vim.loop.fs_stat(root_node)
            if stats == nil then
                return ""
            else
                return root_node
            end
        end

        local default_node_modules = get_node_modules(vim.fn.getcwd())
        local ngls_cmd = {
            "ngserver",
            "--stdio",
            "--tsProbeLocations",
            default_node_modules,
            "--ngProbeLocations",
            default_node_modules,
        }
        lspconfig.angularls.setup({
            autostart = false,
            filetypes = { "typescript", "angular.html", "html", "typescriptreact", "typescript.tsx" },
            cmd = ngls_cmd,
            root_dir = lspconfig.util.root_pattern(".git", "package.json"),
            on_new_config = function(new_config)
                new_config.cmd = ngls_cmd
            end,
        })

        local inlayHints = {
            includeInlayParameterNameHints = "all",
            includeInlayParameterNameHintsWhenArgumentMatchesName = false,
            includeInlayFunctionParameterTypeHints = true,
            includeInlayVariableTypeHints = false,
            includeInlayVariableTypeHintsWhenTypeMatchesName = false,
            includeInlayPropertyDeclarationTypeHints = false,
            includeInlayFunctionLikeReturnTypeHints = true,
            includeInlayEnumMemberValueHints = true,
        }

        lspconfig.ts_ls.setup({
            autostart = true,
            settings = {
                typescript = {
                    inlayHints = inlayHints,
                },
                javascript = {
                    inlayHints = inlayHints,
                },
            },
            init_options = {
                hostInfo = "neovim",
                init_options = {
                    -- Disable telemetry
                    telemetry = { enable = false },
                },
            },
            root_dir = lspconfig.util.root_pattern(".git", "package.json"),
            on_init = disable_formatting_on_init,
        })

        lspconfig.eslint.setup({
            on_init = disable_formatting_on_init,
            filetypes = {
                "javascript",
                "javascriptreact",
                "javascript.jsx",
                "typescript",
                "typescriptreact",
                "typescript.tsx",
                "vue",
                "svelte",
                "astro",
                "html",
                "angular.html",
            },
        })

        lspconfig.terraformls.setup({})

        -- Set up Sonarlint Language Server
        if vim.env.NEOVIM_WORK == "true" or vim.env.NEOVIM_WORK == "1" then
            require("sonarlint").setup({
                filetypes = {
                    -- Tested
                    "typescript",
                    "javascript",
                    "html",
                    "text",
                    "css",
                    "scss",
                    -- Not Tested
                    "docker",
                    "terraform",
                    "xml",
                    "cs",
                    -- 'cpp',
                    -- -- Requires nvim-jdtls, otherwise an error message will be printed
                    "java",
                },
                server = {
                    cmd = {
                        "sonarlint-language-server",
                        -- Ensure that sonarlint-language-server uses stdio channel
                        "-stdio",
                        "-analyzers",
                        -- paths to the analyzers you need, using those for python and java in this example
                        vim.fn.expand("$MASON/share/sonarlint-analyzers/sonarhtml.jar"),
                        vim.fn.expand("$MASON/share/sonarlint-analyzers/sonariac.jar"),
                        vim.fn.expand("$MASON/share/sonarlint-analyzers/sonarjs.jar"),
                        vim.fn.expand("$MASON/share/sonarlint-analyzers/sonartext.jar"),
                        vim.fn.expand("$MASON/share/sonarlint-analyzers/sonarxml.jar"),
                        vim.fn.expand("$MASON/share/sonarlint-analyzers/sonarjava.jar"),
                    },
                    window = {
                        border = "rounded",
                        title_pos = "center",
                    },
                    display_rule = "float",
                    settings = {
                        sonarlint = {
                            rules = sonar_rules,
                        },
                    },
                },
            })
        end

        lspconfig.dockerls.setup({})

        lspconfig.docker_compose_language_service.setup({
            root_dir = lspconfig.util.root_pattern("*compose.y*ml"),
            filetypes = { "yaml.docker-compose", "yml.docker-compose", "yaml.compose", "yml.compose" },
        })

        lspconfig.gopls.setup({})
        lspconfig.tailwindcss.setup({})
        lspconfig.cssls.setup({})

        cmp.setup.filetype("gitcommit", {
            sources = cmp.config.sources({
                { name = "cmp_git" }, -- You can specify the `cmp_git` source if you were installed it.
            }, {
                { name = "buffer" },
            }),
        })

        vim.diagnostic.config({
            severity_sort = true,
            virtual_text = { "if_many" },
            float = {
                source = "if_many",
                border = "rounded",
            },
        })
        -- Set some basic UI stuff
        vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, { border = "rounded" })
        vim.lsp.handlers["textDocument/signatureHelp"] =
            vim.lsp.with(vim.lsp.handlers.signature_help, { border = "rounded" })
        vim.diagnostic.config({ float = { border = "rounded" } })
        require("lspconfig.ui.windows").default_options.border = "rounded"
    end,
}
