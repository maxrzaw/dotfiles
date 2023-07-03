local keymap = require("mzawisa.keymap")
local nnoremap = keymap.nnoremap
local inoremap = keymap.inoremap
local lsp = require("lsp-zero")
local cmp = require("cmp")
local ls = require("luasnip")
local lspkind = require("lspkind")
local util = require("lspconfig.util")
local vim = vim
local uv = vim.loop
local null_ls = require("null-ls")
local sonar_rules = require("mzawisa.wsl.sonarlint_helper").rules

-- set the border for :LspInfo
require("lspconfig.ui.windows").default_options.border = "single"

require("stylua-nvim").setup()

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
    "angularls",
    "dockerls",
    "html",
    "jsonls",
    "marksman",
})

local disable_formatting_on_init = function(client)
    client.server_capabilities.documentFormattingProvider = false
    client.server_capabilities.documentFormattingRangeProvider = false
end

-- sources for null_ls
local sources = {
    null_ls.builtins.formatting.prettierd,
    null_ls.builtins.formatting.stylua,
}

local lsp_formatting = function(bufnr)
    local path = vim.api.nvim_buf_get_name(bufnr)
    -- skip formatting if we are in Nova.UI and not in workspace
    if string.find(path, "Nova.UI") and not string.find(path, "Nova.UI/apps/workspace/") then
        return
    end
    vim.lsp.buf.format({
        filter = function(client)
            return client.name ~= "tsserver" and client.name ~= "eslint"
        end,
        bufnr = bufnr,
    })
end

local lspFormattingAugroup = vim.api.nvim_create_augroup("LspFormatting", { clear = true })

-- lsp.set_server_config({
--     capabilities = require('cmp_nvim_lsp').default_capabilities()
-- })

lsp.on_attach(function(client, bufnr)
    lsp.default_keymaps({ buffer = bufnr })
    nnoremap("gt", "<cmd>Telescope lsp_type_definitions<cr>", { buffer = bufnr })
    nnoremap("gr", "<cmd>lua require('telescope.builtin').lsp_references({fname_width = 0.6})<CR>", { buffer = bufnr })
    nnoremap("gd", "<cmd>Telescope lsp_definitions<cr>", { buffer = bufnr })
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

-- wierd things required for angular monorepo
local function get_node_modules(root_dir)
    -- return util.find_node_modules_ancestor(root_dir) .. '/node_modules' or ''
    -- util.find_node_modules_ancestor()
    local root_node = root_dir .. "/node_modules"
    local stats = uv.fs_stat(root_node)
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

require("lspconfig").angularls.setup({
    autostart = false,
    cmd = ngls_cmd,
    root_dir = util.root_pattern(".git"),
    on_new_config = function(new_config)
        new_config.cmd = ngls_cmd
    end,
})

require("lspconfig").tsserver.setup({
    root_dir = util.root_pattern(".git"),
    on_init = disable_formatting_on_init,
})

require("lspconfig").eslint.setup({
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

            -- vim.fn.expand("$MASON/share/sonarlint-analyzers/sonarcfamily.jar"),
            -- vim.fn.expand("$MASON/share/sonarlint-analyzers/sonargo.jar"),
            -- vim.fn.expand("$MASON/share/sonarlint-analyzers/sonarphp.jar"),
            -- vim.fn.expand("$MASON/share/sonarlint-analyzers/sonarpython.jar"),
        },
        window = {
            -- border = "rounded",
            -- title_pos = "center",
        },
        settings = {
            sonarlint = {
                rules = sonar_rules,
            },
        },
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

require("lspconfig").lua_ls.setup(lsp.nvim_lua_ls({
    on_init = disable_formatting_on_init,
}))

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
