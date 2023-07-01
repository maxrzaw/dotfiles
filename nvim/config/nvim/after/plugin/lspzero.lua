local keymap = require("mzawisa.keymap")
local nnoremap = keymap.nnoremap
local inoremap = keymap.inoremap
local lsp = require("lsp-zero")
local cmp = require("cmp")
local ls = require("luasnip")
local lspkind = require("lspkind")
local null_ls = require("null-ls")

require("mason.settings").set({
    ui = {
        border = "rounded",
    },
})

lsp.preset("recommended")

lsp.ensure_installed({
    "tsserver",
    "eslint",
    "lua_ls",
    -- "clangd",
    "cmake",
    "dockerls",
    "html",
    "jsonls",
    -- "marksman",
    -- "omnisharp",
    "rust_analyzer",
})

-- sources for null_ls
local sources = {
    null_ls.builtins.formatting.prettierd,
    null_ls.builtins.formatting.stylua,
}

local lsp_formatting = function(bufnr)
    vim.lsp.buf.format({
        filter = function(client)
            return client.name ~= "tsserver" and client.name ~= "eslint"
        end,
        bufnr = bufnr,
    })
end

local lspFormattingAugroup = vim.api.nvim_create_augroup("LspFormatting", { clear = true })

lsp.on_attach(function(client, bufnr)
    nnoremap("gt", "<cmd>Trouble lsp_type_definitions<cr>", { buffer = bufnr })
    nnoremap("gr", "<cmd>Trouble lsp_references<cr>", { buffer = bufnr })
    nnoremap("gd", "<cmd>Trouble lsp_definitions<cr>", { buffer = bufnr })
    nnoremap("<leader>vd", vim.diagnostic.open_float, { buffer = bufnr })
    nnoremap("<leader>ca", vim.lsp.buf.code_action, { buffer = bufnr })
    nnoremap("<leader>dn", vim.diagnostic.goto_next, { buffer = bufnr })
    nnoremap("<leader>dN", vim.diagnostic.goto_prev, { buffer = bufnr })
    nnoremap("<leader>dl", "<cmd>Telescope diagnostics<CR>", { buffer = bufnr })
    nnoremap("<leader>r", vim.lsp.buf.rename, { buffer = bufnr })
    inoremap("<C-h>", vim.lsp.buf.signature_help, { buffer = bufnr })
    if client.server_capabilities.documentFormattingProvider then
        vim.api.nvim_create_autocmd("BufWritePre", {
            group = lspFormattingAugroup,
            buffer = bufnr,
            callback = function()
                lsp_formatting(bufnr)
            end,
        })
    end
end)

lsp.configure("lua_ls", {
    settings = {
        Lua = {
            diagnostics = {
                globals = { "vim" },
            },
        },
    },
})

lsp.configure("omnisharp", {
    on_attach = function(client, bufnr)
        vim.keymap.set("n", "<leader>b", ":dotnet build", { buffer = bufnr })
    end,
})

vim.opt.completeopt = { "menu", "menuone", "noselect" }

require("lspconfig").eslint.setup({
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

lsp.nvim_workspace()

lsp.setup()

cmp.setup({
    snippet = {
        expand = function(args)
            ls.lsp_expand(args.body)
        end,
    },
    window = {
        completion = cmp.config.window.bordered(),
        documentation = cmp.config.window.bordered(),
    },
    sources = cmp.config.sources({
        { name = "nvim_lsp" },
        { name = "nvim_lsp_signature_help" },
        { name = "path" },
        { name = "luasnip" },
        { name = "buffer", keyword_length = 5 },
        { name = "luasnip_choice" },
    }),
    formatting = {
        format = lspkind.cmp_format({
            menu = {
                buffer = "[buf]",
                nvim_lsp = "[LSP]",
                nvim_lua = "[api]",
                path = "[path]",
                luasnip = "[snip]",
                gh_issues = "[issues]",
            },
            mode = "symbol_text", -- show symbol then text annotations
            maxwidth = 50, -- prevent the popup from showing more than provided characters (e.g 50 will not show more than 50 characters)
            ellipsis_char = "...", -- when popup menu exceed maxwidth, the truncated part would show ellipsis_char instead (must define maxwidth first)
        }),
    },
    mapping = cmp.mapping.preset.insert({
        ["<C-b>"] = cmp.mapping.scroll_docs(-4),
        ["<C-f>"] = cmp.mapping.scroll_docs(4),
        ["<C-Space>"] = cmp.mapping.complete(),
        ["<C-e>"] = cmp.mapping.abort(),
        ["<CR>"] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
        ["<C-n>"] = function(fallback)
            if cmp.visible() then
                cmp.select_next_item()
            else
                fallback()
            end
        end,
        ["<down>"] = function(fallback)
            if cmp.visible() then
                cmp.select_next_item()
            else
                fallback()
            end
        end,
        ["<C-p>"] = function(fallback)
            if cmp.visible() then
                cmp.select_prev_item()
            else
                fallback()
            end
        end,
        ["<up>"] = function(fallback)
            if cmp.visible() then
                cmp.select_prev_item()
            else
                fallback()
            end
        end,
    }),
    experimental = {
        -- I like the new menu better! Nice work hrsh7th
        native_menu = false,
        -- Let's play with this for a day or two
        ghost_text = true,
    },
})

null_ls.setup({
    sources = sources,
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
