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
    },
    config = function()
        -- Monkey Patch to remove duplicate locations
        local locations_to_items = vim.lsp.util.locations_to_items
        ---@diagnostic disable-next-line: duplicate-set-field
        vim.lsp.util.locations_to_items = function(locations, offset_encoding)
            local lines = {}
            local loc_i = 1
            for _, loc in ipairs(vim.deepcopy(locations)) do
                local uri = loc.uri or loc.targetUri
                local range = loc.range or loc.targetSelectionRange
                if lines[uri .. range.start.line] then -- already have a location on this line
                    table.remove(locations, loc_i) -- remove from the original list
                else
                    loc_i = loc_i + 1
                end
                lines[uri .. range.start.line] = true
            end

            return locations_to_items(locations, offset_encoding)
        end

        local cmp = require("cmp")
        local lspconfig = require("lspconfig")
        local sonar_rules = require("mzawisa.custom.sonarlint_helper").rules
        local angular = require("mzawisa.custom.angular")
        local lsp_keymaps = require("mzawisa.lsp_keymaps")

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

        -- LSP Keybindings
        local set_default_keybindings = function(client, bufnr)
            if client.name == "copilot" or client.name == "null-ls" then
                return
            end
            lsp_keymaps.set_default_lsp_keybindings()
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

                set_default_keybindings(client, bufnr)

                -- Enable Inlay Hints
                if client ~= nil and client.server_capabilities.inlayHintProvider then
                    vim.lsp.inlay_hint.enable(M.inlay_hints_enabled, {})
                end

                -- Disable tsserver from being a rename provider when working on Angular
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

        lspconfig.omnisharp.setup({
            cmd = { vim.fn.expand("$MASON/bin/omnisharp") },

            settings = {
                FormattingOptions = {
                    EnableEditorConfigSupport = true,
                },
            },
        })

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
        lspconfig.basedpyright.setup({})

        cmp.setup.filetype("gitcommit", {
            sources = cmp.config.sources({
                { name = "cmp_git" }, -- You can specify the `cmp_git` source if you were installed it.
            }, {
                { name = "buffer" },
            }),
        })

        vim.diagnostic.config({
            severity_sort = true,
            virtual_text = { source = "if_many" },
            virtual_lines = {
                current_line = true,
            },
            float = {
                source = "if_many",
                border = "rounded",
            },
        })
    end,
}
