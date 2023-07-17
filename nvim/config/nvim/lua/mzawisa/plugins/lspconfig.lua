local cmp = require("cmp")
local lspconfig = require("lspconfig")
local null_ls = require("null-ls")
local sonar_rules = require("mzawisa.plugins.sonarlint_helper").rules

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
    -- skip formatting if we are in Nova.UI and not in workspace
    if string.find(path, "Nova.UI") and not string.find(path, "Nova.UI/apps/workspace/") then
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
local set_default_keybindings = function(bufnr)
    local opts = { buffer = bufnr, silent = true, noremap = true }
    vim.keymap.set("n", "gt", "<cmd>TroubleToggle lsp_type_definitions<cr>", opts)
    vim.keymap.set("n", "gr", "<cmd>TroubleToggle lsp_references<cr>", opts)
    vim.keymap.set("n", "gd", "<cmd>TroubleToggle lsp_definitions<cr>", opts)
    vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
    vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
    vim.keymap.set("n", "<leader>vd", vim.diagnostic.open_float, opts)
    vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts)
    vim.keymap.set("n", "<leader>dn", vim.diagnostic.goto_next, opts)
    vim.keymap.set("n", "<leader>dN", vim.diagnostic.goto_prev, opts)
    vim.keymap.set("n", "<leader>dl", "<cmd>Telescope diagnostics<CR>", opts)
    vim.keymap.set("n", "<leader>r", vim.lsp.buf.rename, opts)
    vim.keymap.set("i", "<C-k>", vim.lsp.buf.signature_help, opts)
    vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
    vim.keymap.set("n", "<space>f", function()
        vim.lsp.buf.format({ async = true })
    end, opts)
end

-- Use LspAttach autocommand to only map the following keys
-- after the language server attaches to the current buffer
-- I am using this for things I want to run for every language servers
vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("UserLspConfig", {}),
    callback = function(args)
        local bufnr = args.buf
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        set_default_keybindings(bufnr)
        set_format_on_save(client, bufnr)
    end,
})

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
                globals = { "vim" },
            },
            runtime = {
                version = "LuaJIT",
                path = runtime_path,
            },
            workspace = {
                checkThirdParty = false,
                library = {
                    vim.fn.expand("$VIMRUNTIME/lua"),
                    vim.fn.stdpath("config") .. "/lua",
                },
            },
        },
    },
})

if not os.getenv("NEOVIM_WORK") then
    lspconfig.omnisharp.setup({
        on_attach = function(client, bufnr)
            vim.keymap.set("n", "<leader>b", ":dotnet build", { buffer = bufnr })
        end,
    })
end

if os.getenv("NEOVIM_WORK") then
    -- Set up Angular Language Server
    -- wierd things required for angular monorepo
    local function get_node_modules(root_dir)
        -- return util.find_node_modules_ancestor(root_dir) .. '/node_modules' or ''
        -- util.find_node_modules_ancestor()
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
        cmd = ngls_cmd,
        root_dir = lspconfig.util.root_pattern(".git"),
        on_new_config = function(new_config)
            new_config.cmd = ngls_cmd
        end,
    })

    lspconfig.tsserver.setup({
        root_dir = lspconfig.util.root_pattern(".git"),
        on_init = disable_formatting_on_init,
    })

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
                settings = {
                    sonarlint = {
                        rules = sonar_rules,
                    },
                },
            },
        })
    end
end

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
    },
})

null_ls.setup({
    sources = {
        null_ls.builtins.formatting.prettierd,
    },
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
    virtual_text = {
        source = "always",
    },
    float = {
        source = "always",
        border = "rounded",
    },
})
-- Set some basic UI stuff
vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, { border = "rounded" })
vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, { border = "rounded" })
vim.diagnostic.config({ float = { border = "rounded" } })
