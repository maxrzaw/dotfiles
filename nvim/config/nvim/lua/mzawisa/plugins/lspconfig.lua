local cmp = require("cmp")
local lspconfig = require("lspconfig")
local null_ls = require("null-ls")

-- Add nvim_cmp default capabilities to lspconfig default capabilities
lspconfig.util.default_config.capabilities = vim.tbl_deep_extend(
    "force",
    lspconfig.util.default_config.capabilities,
    require("cmp_nvim_lsp").default_capabilities()
)

-- LSP Formatting
local lsp_formatting = function(bufnr)
    vim.lsp.buf.format({
        filter = function(client)
            -- Don't use tsserver or eslint for formatting
            return client.name ~= "tsserver" and client.name ~= "eslint"
        end,
        bufnr = bufnr,
    })
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

lspconfig.omnisharp.setup({
    on_attach = function(client, bufnr)
        vim.keymap.set("n", "<leader>b", ":dotnet build", { buffer = bufnr })
    end,
})

lspconfig.eslint.setup({
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
        null_ls.builtins.formatting.stylua,
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
