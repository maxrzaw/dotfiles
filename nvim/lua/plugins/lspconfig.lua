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
    },
    config = function()
        local cmp = require("cmp")
        local sonar_rules = require("mzawisa.custom.sonarlint_helper").rules
        local angular = require("mzawisa.custom.angular")
        local lsp_keymaps = require("mzawisa.lsp_keymaps")
        local is_work = vim.g.is_work

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

                -- Disable vtsls from being a rename provider when working on Angular
                if client ~= nil and client.name == "vtsls" and angular.enabled then
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
                            library = {
                                vim.env.VIMRUNTIME,
                                "${3rd}/luv/library",
                            },
                        },
                    },
                },
            })
        end

        vim.lsp.config("arduino_language_server", {
            cmd = (function()
                return {
                    "arduino-language-server",
                    "-cli-config",
                    "/Users/max/Library/Arduino15/arduino-cli.yaml",
                    "-fqbn",
                    "esp8266:esp8266:nodemcuv2",
                    "-cli",
                    "arduino-cli",
                    "-clangd",
                    "clangd",
                }
            end)(),
            filetypes = { "arduino", "c", "cpp" },
            root_dir = function(bufnr, on_dir)
                local fname = vim.api.nvim_buf_get_name(bufnr)
                local sketch_root = vim.fs.root(fname, { "sketch.yaml", ".git" })
                if not sketch_root then
                    return
                end

                local ino_files = vim.fs.find(function(name)
                    return name:match("%.ino$") ~= nil
                end, { path = sketch_root, type = "file", limit = 1 })
                if #ino_files == 0 then
                    return
                end

                on_dir(sketch_root)
            end,
            capabilities = {
                textDocument = {
                    semanticTokens = vim.NIL,
                },
                workspace = {
                    semanticTokens = vim.NIL,
                },
            },
        })

        -- Set up Angular Language Server
        -- wierd things required for angular monorepo
        local function get_node_modules(root_dir)
            local root_node = root_dir .. "/node_modules"
            local stats = vim.uv.fs_stat(root_node)
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

        vim.lsp.config("vtsls", {
            cmd = { "vtsls", "--stdio" },
            root_markers = { "package.json", ".git" },
            filetypes = {
                "javascript",
                "javascriptreact",
                "typescript",
                "typescriptreact",
            },
            settings = {
                vtsls = {
                    enableMoveToFileCodeAction = true,
                    autoUseWorkspaceTsdk = true,
                    experimental = {
                        maxInlayHintLength = 30,
                        completion = {
                            enableServerSideFuzzyMatch = true,
                        },
                    },
                    tsserver = {
                        globalPlugins = {
                            {
                                name = "@angular/language-server",
                                location = vim.fn.expand(
                                    "$MASON/packages/angular-language-server/node_modules/@angular/language-server"
                                ),
                                enableForWorkspaceTypeScriptVersions = false,
                            },
                        },
                    },
                },
                -- Temporary: enable tsserver logging for debugging
                ["typescript.tsserver.log"] = "verbose",
                typescript = {
                    updateImportsOnFileMove = { enabled = "always" },
                    suggest = {
                        completeFunctionCalls = true,
                    },
                    inlayHints = inlayHints,
                },
                javascript = {
                    inlayHints = inlayHints,
                },
            },
        })

        -- Disabled: using vtsls instead for better monorepo/multi-project support
        vim.lsp.config("ts_ls", {
            cmd = { "typescript-language-server", "--stdio" },
            root_markers = { ".git", "package.json" },
            filetypes = {
                "javascript",
                "javascriptreact",
                "typescript",
                "typescriptreact",
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
                preferences = {
                    disableSuggestions = false,
                },
                tsserver = {
                    logDirectory = "/tmp/tsserver-logs",
                    logVerbosity = "verbose",
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
                "typescript",
                "typescriptreact",
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
        })

        -- Set up Sonarlint Language Server
        if is_work then
            -- Detect Java installation for SonarLint (requires Java 17+)
            local java_home = vim.env.JAVA_HOME
            if vim.g.windows == 1 then
                -- On Windows, search for compatible Java version if default is too old
                local possible_java_paths = {
                    vim.env.JAVA_HOME, -- Try system JAVA_HOME first
                    "C:\\Program Files\\Microsoft\\jdk-25.0.2.10-hotspot",
                    "C:\\Program Files\\Java\\jdk-25",
                    "C:\\Program Files\\Java\\jdk-21",
                    "C:\\Program Files\\Java\\jdk-17",
                }
                for _, path in ipairs(possible_java_paths) do
                    if path and vim.fn.isdirectory(path) == 1 then
                        java_home = path
                        break
                    end
                end
            end

            local sonarlint_cmd = { "sonarlint-language-server" }

            -- On Windows with incompatible Java, call java directly
            if vim.g.windows == 1 and java_home then
                sonarlint_cmd = {
                    java_home .. "\\bin\\java.exe",
                    "-jar",
                    vim.fn.expand("$MASON/packages/sonarlint-language-server/extension/server/sonarlint-ls.jar"),
                }
            end

            local sonarlint_config = {
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
                    cmd = vim.list_extend(sonarlint_cmd, {
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
                    }),
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
            }

            require("sonarlint").setup(sonarlint_config)
        end

        vim.lsp.config("dockerls", {
            cmd = { "docker-langserver", "--stdio" },
            root_markers = { "Dockerfile" },
            filetypes = { "dockerfile" },
        })

        vim.lsp.config("docker_compose_language_service", {
            cmd = { "docker-compose-langserver", "--stdio" },
            root_markers = { "docker-compose.yaml", "docker-compose.yml", "compose.yaml", "compose.yml" },
        })

        vim.lsp.config("gopls", {
            cmd = { "gopls" },
            root_markers = { "go.mod", ".git", "go.work" },
        })

        if not is_work then
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
        end

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
        -- basedpyright: manual start only. Use :LspStart basedpyright if needed.
        local servers_to_enable = {
            "lua_ls",
            "vtsls",
            -- "ts_ls",
            "eslint",
            "terraformls",
            "dockerls",
            "docker_compose_language_service",
            "gopls",
            "cssls",
        }

        if not is_work then
            table.insert(servers_to_enable, 1, "arduino_language_server")
        end

        vim.lsp.enable(servers_to_enable)

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
