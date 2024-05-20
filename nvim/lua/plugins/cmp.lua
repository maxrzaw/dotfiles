return {
    "hrsh7th/nvim-cmp",
    name = "nvim-cmp",
    cond = not vim.g.vscode,
    dependencies = {
        "doxnit/cmp-luasnip-choice",
        "hrsh7th/cmp-buffer",
        "hrsh7th/cmp-nvim-lsp",
        "hrsh7th/cmp-nvim-lsp-signature-help",
        "hrsh7th/cmp-nvim-lua",
        { "hrsh7th/cmp-path", dependencies = { "mzawisa/harpoon-relative-marks" } },
        "onsails/lspkind.nvim",
        "saadparwaiz1/cmp_luasnip",
        { "petertriho/cmp-git", dependencies = { "nvim-lua/plenary.nvim" } },
    },
    config = function()
        local cmp = require("cmp")
        local lspkind = require("lspkind")
        local luasnip = require("luasnip")
        local cmp_autopairs = require("nvim-autopairs.completion.cmp")

        vim.opt.completeopt = { "menu", "menuone", "noselect" }

        cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
        cmp.setup({
            snippet = {
                expand = function(args)
                    luasnip.lsp_expand(args.body)
                end,
            },
            window = {
                completion = cmp.config.window.bordered(),
                documentation = cmp.config.window.bordered(),
            },
            sources = cmp.config.sources({
                { name = "copilot" },
                { name = "nvim_lsp", max_item_count = 5 },
                { name = "nvim_lsp_signature_help", max_item_count = 5 },
                {
                    name = "path",
                    option = {
                        get_cwd = function(params)
                            if params.context.filetype == "harpoon" then
                                return require("harpoon-relative-marks")._current_dir
                            end
                            return vim.fn.expand("#%d:p:h"):format(params.context.bufnr)
                        end,
                    },
                },
                { name = "luasnip", max_item_count = 5 },
                { name = "buffer", keyword_length = 5, max_item_count = 5 },
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
                        Copilot = "[]",
                    },
                    -- show symbol then text annotations
                    mode = "symbol_text",
                    -- prevent the popup from showing more than provided characters
                    maxwidth = 50,
                    -- when popup menu exceed maxwidth, the truncated part would show ellipsis_char instead
                    ellipsis_char = "...",
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
    end,
}
