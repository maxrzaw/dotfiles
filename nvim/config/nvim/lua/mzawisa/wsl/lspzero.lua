local keymap = require("mzawisa.keymap");
local nnoremap = keymap.nnoremap;
local inoremap = keymap.inoremap;
local lsp = require('lsp-zero');
local cmp = require('cmp');
local ls = require('luasnip');
local lspkind = require('lspkind');
local util = require('lspconfig.util');
local vim = vim;
local uv = vim.loop;
local null_ls = require('null-ls');

require('mason.settings').set({
    ui = {
        border = 'rounded'
    }
});

lsp.preset('recommended');

lsp.ensure_installed({
    'tsserver',
    'eslint',
    "lua_ls",
    'angularls',
    "dockerls",
    "html",
    "jsonls",
    "marksman",
});

-- sources for null_ls
local sources = {
    null_ls.builtins.formatting.prettierd,
}

local lsp_formatting = function(bufnr)
    vim.lsp.buf.format({
        filter = function(client)
            return client.name ~= "tsserver"
        end,
        bufnr = bufnr,
    })
end

local augroup = vim.api.nvim_create_augroup("LspFormatting", { clear = true })

-- lsp.set_server_config({
--     capabilities = require('cmp_nvim_lsp').default_capabilities()
-- })

lsp.on_attach(function(client, bufnr)
    lsp.default_keymaps({ buffer = bufnr });
    nnoremap("gt", "<cmd>Telescope lsp_type_definitions<cr>", { buffer = bufnr });
    nnoremap("gr", "<cmd>lua require('telescope.builtin').lsp_references({fname_width = 0.6})<CR>", { buffer = bufnr });
    nnoremap("gd", "<cmd>Telescope lsp_definitions<cr>", { buffer = bufnr });
    nnoremap("<leader>vd", vim.diagnostic.open_float, { buffer = bufnr });
    nnoremap("<leader>ca", vim.lsp.buf.code_action, { buffer = bufnr });
    nnoremap("<leader>dn", vim.diagnostic.goto_next, { buffer = bufnr });
    nnoremap("<leader>dN", vim.diagnostic.goto_prev, { buffer = bufnr });
    nnoremap("<leader>dl", "<cmd>Telescope diagnostics<CR>", { buffer = bufnr });
    nnoremap("<leader>r", vim.lsp.buf.rename, { buffer = bufnr });
    inoremap("<C-h>", vim.lsp.buf.signature_help, { buffer = bufnr });
    if client.server_capabilities.documentFormattingProvider then
        vim.api.nvim_create_autocmd("BufWritePre", {
            group = augroup,
            buffer = bufnr,
            callback = function()
                lsp_formatting(bufnr)
            end,
        })
    end
end);

lsp.configure('lua_ls', {
    settings = {
        Lua = {
            diagnostics = {
                globals = { 'vim' }
            }
        }
    }
});

-- wierd things required for angular monorepo
local function get_node_modules(root_dir)
    -- return util.find_node_modules_ancestor(root_dir) .. '/node_modules' or ''
    -- util.find_node_modules_ancestor()
    local root_node = root_dir .. "/node_modules"
    local stats = uv.fs_stat(root_node)
    if stats == nil then
        return ''
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

require('lspconfig').angularls.setup({
    cmd = ngls_cmd,
    root_dir = util.root_pattern '.git',
    on_new_config = function(new_config)
        new_config.cmd = ngls_cmd
    end
});

require('lspconfig').tsserver.setup({
    root_dir = util.root_pattern '.git'
});

require('lspconfig').eslint.setup({
    filetypes = { "javascript", "javascriptreact", "javascript.jsx", "typescript", "typescriptreact", "typescript.tsx",
        "vue", "svelte", "astro", "html" }
});

lsp.configure('omnisharp', {
    on_attach = function(client, bufnr)
        vim.keymap.set("n", "<leader>b", ":dotnet build", { buffer = bufnr })
        client.server_capabilities.semanticTokensProvider = {
            full = vim.empty_dict(),
            legend = {
                tokenModifiers = { "static_symbol" },
                tokenTypes = {
                    "comment",
                    "excluded_code",
                    "identifier",
                    "keyword",
                    "keyword_control",
                    "number",
                    "operator",
                    "operator_overloaded",
                    "preprocessor_keyword",
                    "string",
                    "whitespace",
                    "text",
                    "static_symbol",
                    "preprocessor_text",
                    "punctuation",
                    "string_verbatim",
                    "string_escape_character",
                    "class_name",
                    "delegate_name",
                    "enum_name",
                    "interface_name",
                    "module_name",
                    "struct_name",
                    "type_parameter_name",
                    "field_name",
                    "enum_member_name",
                    "constant_name",
                    "local_name",
                    "parameter_name",
                    "method_name",
                    "extension_method_name",
                    "property_name",
                    "event_name",
                    "namespace_name",
                    "label_name",
                    "xml_doc_comment_attribute_name",
                    "xml_doc_comment_attribute_quotes",
                    "xml_doc_comment_attribute_value",
                    "xml_doc_comment_cdata_section",
                    "xml_doc_comment_comment",
                    "xml_doc_comment_delimiter",
                    "xml_doc_comment_entity_reference",
                    "xml_doc_comment_name",
                    "xml_doc_comment_processing_instruction",
                    "xml_doc_comment_text",
                    "xml_literal_attribute_name",
                    "xml_literal_attribute_quotes",
                    "xml_literal_attribute_value",
                    "xml_literal_cdata_section",
                    "xml_literal_comment",
                    "xml_literal_delimiter",
                    "xml_literal_embedded_expression",
                    "xml_literal_entity_reference",
                    "xml_literal_name",
                    "xml_literal_processing_instruction",
                    "xml_literal_text",
                    "regex_comment",
                    "regex_character_class",
                    "regex_anchor",
                    "regex_quantifier",
                    "regex_grouping",
                    "regex_alternation",
                    "regex_text",
                    "regex_self_escaped_character",
                    "regex_other_escape",
                },
            },
            range = true,
        }
    end
});

lsp.nvim_workspace();

lsp.setup();

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
        { name = 'nvim_lsp' },
        { name = 'nvim_lsp_signature_help' },
        { name = 'path' },
        { name = 'luasnip' },
        { name = 'buffer',                 keyword_length = 5 },
        { name = 'luasnip_choice' },
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
            mode = 'symbol_text',  -- show symbol then text annotations
            maxwidth = 50,         -- prevent the popup from showing more than provided characters (e.g 50 will not show more than 50 characters)
            ellipsis_char = '...', -- when popup menu exceed maxwidth, the truncated part would show ellipsis_char instead (must define maxwidth first)
        })
    },
    mapping = cmp.mapping.preset.insert({
        ['<C-b>'] = cmp.mapping.scroll_docs(-4),
        ['<C-f>'] = cmp.mapping.scroll_docs(4),
        ['<C-Space>'] = cmp.mapping.complete(),
        ['<C-e>'] = cmp.mapping.abort(),
        ['<CR>'] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
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
        end
    }),
    experimental = {
        -- I like the new menu better! Nice work hrsh7th
        native_menu = false,
        -- Let's play with this for a day or two
        ghost_text = true,
    },
});

null_ls.setup({
    sources = sources,
})

require('lspconfig').lua_ls.setup(lsp.nvim_lua_ls());

cmp.setup.filetype('gitcommit', {
    sources = cmp.config.sources({
        { name = 'cmp_git' }, -- You can specify the `cmp_git` source if you were installed it.
    }, {
        { name = 'buffer' },
    })
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
});
