--local neogit = require('neogit')
--neogit.setup {}
local cmp_luasnip_choice = require('cmp_luasnip_choice')

-- LSP
-- This must come before the lspconfig setup
--require("mason").setup()
--require("mason-lspconfig").setup({
--    ensure_installed = {
--        "sumneko_lua",
--        "clangd",
--        "cmake",
--        "dockerls",
--        "html",
--        "jsonls",
--        "tsserver",
--        "marksman",
--        "omnisharp",
--        "rust_analyzer",
--        --"csharp-ls",
--    }
--})

--local capabilities = require('cmp_nvim_lsp').default_capabilities()
--local on_attach = function(client, bufnr)
--vim.keymap.set("n", "K", vim.lsp.buf.hover, { buffer = bufnr })
--vim.keymap.set("n", "gd", vim.lsp.buf.definition, { buffer = bufnr })
--vim.keymap.set("n", "gi", vim.lsp.buf.implementation, { buffer = bufnr })
--vim.keymap.set("n", "gr", vim.lsp.buf.references, { buffer = bufnr })
--    vim.keymap.set("n", "gt", vim.lsp.buf.type_definition, { buffer = bufnr })
--    vim.keymap.set("n", "<leader>dn", vim.diagnostic.goto_next, { buffer = bufnr })
--    vim.keymap.set("n", "<leader>dN", vim.diagnostic.goto_prev, { buffer = bufnr })
--    vim.keymap.set("n", "<leader>dl", "<cmd>Telescope diagnostics<CR>", { buffer = bufnr })
--    vim.keymap.set("n", "<leader>r", vim.lsp.buf.rename, { buffer = bufnr })
--    if client.server_capabilities.documentFormattingProvider then
--        vim.api.nvim_create_autocmd("BufWritePre", {
--            group = vim.api.nvim_create_augroup("Format", { clear = true }),
--            buffer = bufnr,
--            callback = function()
--                vim.lsp.buf.format()
--            end
--        })
--    end
--end

-- local on_attach_dotnet = function(client, bufnr)
--     vim.keymap.set("n", "<leader>b", ":dotnet build", { buffer = bufnr })
-- end

--require 'lspconfig'.sumneko_lua.setup {
--    on_attach = on_attach,
--    capabilities = capabilities,
--    settings = {
--        Lua = {
--            diagnostics = {
--                globals = { 'vim' }
--            }
--        }
--    }
--}

--require 'lspconfig'.clangd.setup {
--    on_attach = on_attach,
--    capabilities = capabilities
--}
--
--require 'lspconfig'.jsonls.setup {
--    on_attach = on_attach,
--    capabilities = capabilities
--}
--
--require 'lspconfig'.tsserver.setup {
--    on_attach = on_attach,
--    capabilities = capabilities
--}
--
--require 'lspconfig'.marksman.setup {
--    on_attach = on_attach,
--    capabilities = capabilities
--}
--
--require 'lspconfig'.omnisharp.setup {
--    on_attach = on_attach,
--    capabilities = capabilities
--}
--
--require 'lspconfig'.rust_analyzer.setup {
--    on_attach = on_attach,
--    capabilities = capabilities
--}


--require'lspconfig'.csharp_ls.setup{}

--vim.opt.completeopt = { 'menu', 'menuone', 'noselect' }
-- Set up nvim-cmp.
local cmp = require 'cmp'
local lspkind = require('lspkind')

-- cmp.setup({
    --snippet = {
    --    expand = function(args)
    --        require('luasnip').lsp_expand(args.body)
    --    end,
    --},
    --window = {
    --    completion = cmp.config.window.bordered(),
    --    documentation = cmp.config.window.bordered(),
    --},
    -- mapping = cmp.mapping.preset.insert({
    --     ['<C-b>'] = cmp.mapping.scroll_docs(-4),
    --     ['<C-f>'] = cmp.mapping.scroll_docs(4),
    --     ['<C-Space>'] = cmp.mapping.complete(),
    --     ['<C-e>'] = cmp.mapping.abort(),
    --     ['<CR>'] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
    --     ["<C-n>"] = function(fallback)
    --         if cmp.visible() then
    --             cmp.select_next_item()
    --         else
    --             fallback()
    --         end
    --     end,
    --     ["<down>"] = function(fallback)
    --         if cmp.visible() then
    --             cmp.select_next_item()
    --         else
    --             fallback()
    --         end
    --     end,
    --     ["<C-p>"] = function(fallback)
    --         if cmp.visible() then
    --             cmp.select_prev_item()
    --         else
    --             fallback()
    --         end
    --     end,
    --     ["<up>"] = function(fallback)
    --         if cmp.visible() then
    --             cmp.select_prev_item()
    --         else
    --             fallback()
    --         end
    --     end
    -- }),
    --sources = cmp.config.sources({
    --    { name = 'nvim_lsp' },
    --    { name = 'path' },
    --    { name = 'luasnip' },
    --    { name = 'buffer', kayword_length = 5 },
    --    { name = 'luasnip_choice' },
    --}),
    --formatting = {
    --    format = lspkind.cmp_format({
    --        menu = {
    --            buffer = "[buf]",
    --            nvim_lsp = "[LSP]",
    --            nvim_lua = "[api]",
    --            path = "[path]",
    --            luasnip = "[snip]",
    --            gh_issues = "[issues]",
    --        },
    --        mode = 'symbol_text', -- show symbol then text annotations
    --        maxwidth = 50, -- prevent the popup from showing more than provided characters (e.g 50 will not show more than 50 characters)
    --        ellipsis_char = '...', -- when popup menu exceed maxwidth, the truncated part would show ellipsis_char instead (must define maxwidth first)
    --    })
    --},
    --experimental = {
    --    -- I like the new menu better! Nice work hrsh7th
    --    native_menu = false,

    --    -- Let's play with this for a day or two
    --    ghost_text = false,
    --},
-- })

--cmp_luasnip_choice.setup({
--    auto_open = true,
--})

-- Set configuration for specific filetype.
cmp.setup.filetype('gitcommit', {
    sources = cmp.config.sources({
        { name = 'cmp_git' }, -- You can specify the `cmp_git` source if you were installed it.
    }, {
        { name = 'buffer' },
    })
})
