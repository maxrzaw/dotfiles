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
        local sonar_rules = require("mzawisa.custom.sonarlint_helper").rules
        local angular = require("mzawisa.custom.angular")
        local lsp_keymaps = require("mzawisa.lsp_keymaps")

        -- Enable LSP debug logging
        -- vim.lsp.set_log_level("debug")

        -- Get default capabilities from nvim_cmp
        vim.lsp.config("*", {
            capabilities = require("cmp_nvim_lsp").default_capabilities(),
        })

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

            vim.lsp.config("lua_ls", {
                cmd = { "lua-language-server" },
                root_markers = { ".git", ".luarc.json", ".luarc.jsonc", ".luacheckrc", "stylua.toml", "selene.toml" },
                filetypes = { "lua" },
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

        -- OmniSharp: Build config using lspconfig's logic, then use with vim.lsp.config
        local omnisharp_lspconfig = require("lspconfig.configs.omnisharp").default_config
        local omnisharp_config = vim.deepcopy(omnisharp_lspconfig)
        omnisharp_config.cmd = { vim.fn.expand("$MASON/bin/OmniSharp") }

        -- Setup capabilities with workspace field for on_new_config
        local base_capabilities = require("cmp_nvim_lsp").default_capabilities()
        base_capabilities.workspace = base_capabilities.workspace or {}
        omnisharp_config.capabilities =
            vim.tbl_deep_extend("force", base_capabilities, omnisharp_config.capabilities or {})

        -- Manually call lspconfig's on_new_config to build the full command
        if omnisharp_lspconfig.on_new_config then
            omnisharp_lspconfig.on_new_config(omnisharp_config, vim.fn.getcwd())
        end

        vim.lsp.config("omnisharp", {
            cmd = { vim.fn.expand("$MASON/bin/OmniSharp") },
            root_markers = { ".git", "*.sln", "*.csproj" },
            filetypes = { "cs", "vb" },
            settings = {
                FormattingOptions = {
                    EnableEditorConfigSupport = true,
                },
                RoslynExtensionsOptions = {
                    EnableAnalyzersSupport = true,
                },
                Sdk = {
                    IncludePrereleases = true,
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
        vim.lsp.config("angularls", {
            cmd = ngls_cmd,
            root_markers = { ".git", "package.json" },
            filetypes = {
                "typescript",
                "html",
                "htmlangular",
                "typescriptreact",
                "typescript.tsx",
            },
        })

        -- Note: autostart is false by default in vim.lsp.config
        -- You'll need to manually start Angular LS with :LspStart angularls

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

        vim.lsp.config("ts_ls", {
            cmd = { "typescript-language-server", "--stdio" },
            root_markers = { ".git", "package.json" },
            filetypes = {
                "javascript",
                "javascriptreact",
                "javascript.jsx",
                "typescript",
                "typescriptreact",
                "typescript.tsx",
            },
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
                -- Disable telemetry
                preferences = {
                    disableSuggestions = false,
                },
            },
        })

        vim.lsp.config("eslint", {
            cmd = { "vscode-eslint-language-server", "--stdio" },
            root_markers = {
                ".eslintrc",
                ".eslintrc.js",
                ".eslintrc.cjs",
                ".eslintrc.yaml",
                ".eslintrc.yml",
                ".eslintrc.json",
                "eslint.config.js",
                "package.json",
                ".git",
            },
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
                "htmlangular",
            },
            on_init = disable_formatting_on_init,
            on_new_config = function(config, root_dir)
                -- Ensure root_dir is always set
                config.root_dir = root_dir or vim.fn.getcwd()
            end,
            settings = {
                workingDirectory = { mode = "auto" },
                format = false,
            },
        })

        vim.lsp.config("terraformls", {
            cmd = { "terraform-ls", "serve" },
            root_markers = { ".terraform", ".git" },
            filetypes = { "terraform", "terraform-vars" },
        })

        -- Set up Sonarlint Language Server
        if vim.env.NEOVIM_WORK == "true" or vim.env.NEOVIM_WORK == "1" then
            require("sonarlint").setup({
                filetypes = {
                    -- Tested
                    "typescript",
                    "javascript",
                    "html",
                    "htmlangular",
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

        vim.lsp.config("dockerls", {
            cmd = { "docker-langserver", "--stdio" },
            root_markers = { "Dockerfile" },
            filetypes = { "dockerfile" },
        })

        vim.lsp.config("docker_compose_language_service", {
            cmd = { "docker-compose-langserver", "--stdio" },
            root_markers = { "docker-compose.yaml", "docker-compose.yml", "compose.yaml", "compose.yml" },
            filetypes = { "yaml.docker-compose", "yml.docker-compose", "yaml.compose", "yml.compose" },
        })

        vim.lsp.config("gopls", {
            cmd = { "gopls" },
            root_markers = { "go.mod", ".git", "go.work" },
            filetypes = { "go", "gomod", "gowork", "gotmpl" },
        })

        vim.lsp.config("tailwindcss", {
            cmd = { "tailwindcss-language-server", "--stdio" },
            root_markers = {
                "tailwind.config.js",
                "tailwind.config.cjs",
                "tailwind.config.mjs",
                "tailwind.config.ts",
                "postcss.config.js",
                "postcss.config.cjs",
                "postcss.config.mjs",
                "postcss.config.ts",
                "package.json",
            },
            filetypes = {
                "aspnetcorerazor",
                "astro",
                "astro-markdown",
                "blade",
                "clojure",
                "django-html",
                "htmldjango",
                "edge",
                "eelixir",
                "elixir",
                "ejs",
                "erb",
                "eruby",
                "gohtml",
                "gohtmltmpl",
                "haml",
                "handlebars",
                "hbs",
                "html",
                "htmlangular",
                "html-eex",
                "heex",
                "jade",
                "leaf",
                "liquid",
                "markdown",
                "mdx",
                "mustache",
                "njk",
                "nunjucks",
                "php",
                "razor",
                "slim",
                "twig",
                "css",
                "less",
                "postcss",
                "sass",
                "scss",
                "stylus",
                "sugarss",
                "javascript",
                "javascriptreact",
                "reason",
                "rescript",
                "typescript",
                "typescriptreact",
                "vue",
                "svelte",
            },
        })

        vim.lsp.config("cssls", {
            cmd = { "vscode-css-language-server", "--stdio" },
            root_markers = { "package.json", ".git" },
            filetypes = { "css", "scss", "less" },
        })

        vim.lsp.config("basedpyright", {
            cmd = { "basedpyright-langserver", "--stdio" },
            root_markers = {
                "pyproject.toml",
                "setup.py",
                "setup.cfg",
                "requirements.txt",
                "Pipfile",
                "pyrightconfig.json",
                ".git",
            },
            filetypes = { "python" },
        })

        -- Enable all configured LSP servers
        -- angularls: manually controlled via angular.setup()
        -- tailwindcss: disabled, causes multi-second freeze on first file open. Use :LspStart tailwindcss if needed.
        vim.lsp.enable({
            "lua_ls",
            "omnisharp",
            "ts_ls",
            "eslint",
            "terraformls",
            "dockerls",
            "docker_compose_language_service",
            "gopls",
            "cssls",
            "basedpyright",
        })

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
            signs = {
                text = {
                    [vim.diagnostic.severity.ERROR] = "",
                    [vim.diagnostic.severity.WARN] = "",
                    [vim.diagnostic.severity.INFO] = "",
                    [vim.diagnostic.severity.HINT] = "󰌵",
                },
            },
        })
    end,
}
